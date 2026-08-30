-- JUFINALLIES: realign existing active-loan schedules to their application dates.
-- The first installment becomes application_date + 7 days. Existing amounts and
-- payments are preserved. Restructured loans are deliberately excluded.

begin;

create table if not exists public.jufinallies_schedule_date_fix_audit (
  schedule_id uuid primary key,
  business_id text not null,
  loan_id uuid not null,
  installment_no integer not null,
  old_due_date date not null,
  new_due_date date not null,
  old_status text,
  total_due numeric(14,2),
  total_paid numeric(14,2),
  fixed_at timestamptz not null default now()
);

alter table public.jufinallies_schedule_date_fix_audit enable row level security;

with target_loans as (
  select l.id loan_id,l.business_id,a.application_date
  from public.loans l
  join public.loan_applications a
    on a.id=l.application_id and a.business_id=l.business_id
  where l.status='active'
    and a.application_date is not null
    and not exists (
      select 1 from public.loan_schedules old_s
      where old_s.loan_id=l.id and old_s.status='restructured'
    )
    and not exists (
      select 1 from public.loan_audit_log al
      where al.business_id=l.business_id
        and al.record_id=l.id::text
        and lower(al.action) like '%restructur%'
    )
), ranked as (
  select s.id schedule_id,s.business_id,s.loan_id,s.installment_no,s.due_date old_due_date,
    s.status old_status,s.total_due,s.total_paid,
    (t.application_date + (row_number() over (
      partition by s.loan_id order by s.installment_no,s.due_date,s.id
    )::integer * 7))::date new_due_date
  from public.loan_schedules s
  join target_loans t on t.loan_id=s.loan_id
  where s.status<>'restructured'
)
insert into public.jufinallies_schedule_date_fix_audit (
  schedule_id,business_id,loan_id,installment_no,old_due_date,new_due_date,
  old_status,total_due,total_paid
)
select schedule_id,business_id,loan_id,installment_no,old_due_date,new_due_date,
  old_status,total_due,total_paid
from ranked
where old_due_date is distinct from new_due_date
on conflict (schedule_id) do nothing;

with target_loans as (
  select l.id loan_id,a.application_date
  from public.loans l
  join public.loan_applications a
    on a.id=l.application_id and a.business_id=l.business_id
  where l.status='active'
    and a.application_date is not null
    and not exists (
      select 1 from public.loan_schedules old_s
      where old_s.loan_id=l.id and old_s.status='restructured'
    )
    and not exists (
      select 1 from public.loan_audit_log al
      where al.business_id=l.business_id
        and al.record_id=l.id::text
        and lower(al.action) like '%restructur%'
    )
), ranked as (
  select s.id schedule_id,
    (t.application_date + (row_number() over (
      partition by s.loan_id order by s.installment_no,s.due_date,s.id
    )::integer * 7))::date new_due_date
  from public.loan_schedules s
  join target_loans t on t.loan_id=s.loan_id
  where s.status<>'restructured'
)
update public.loan_schedules s
set due_date=r.new_due_date,
    status=case
      when s.total_paid>=s.total_due then 'paid'
      when s.total_paid>0 then 'partial'
      when r.new_due_date<current_date then 'overdue'
      else 'pending'
    end,
    updated_at=now()
from ranked r
where s.id=r.schedule_id;

with target_loans as (
  select l.id loan_id,l.business_id,a.application_date
  from public.loans l
  join public.loan_applications a
    on a.id=l.application_id and a.business_id=l.business_id
  where l.status='active'
    and a.application_date is not null
    and not exists (
      select 1 from public.loan_schedules old_s
      where old_s.loan_id=l.id and old_s.status='restructured'
    )
    and not exists (
      select 1 from public.loan_audit_log al
      where al.business_id=l.business_id
        and al.record_id=l.id::text
        and lower(al.action) like '%restructur%'
    )
), schedule_totals as (
  select t.loan_id,t.business_id,t.application_date,max(s.due_date) maturity_date,
    coalesce(sum(greatest(s.total_due-s.total_paid,0)) filter (where s.due_date<current_date),0) arrears_amount,
    min(s.due_date) filter (where s.due_date<current_date and s.total_paid<s.total_due) oldest_overdue
  from target_loans t
  join public.loan_schedules s on s.loan_id=t.loan_id and s.status<>'restructured'
  group by t.loan_id,t.business_id,t.application_date
)
update public.loans l
set first_repayment_date=st.application_date+7,
    maturity_date=st.maturity_date,
    arrears_amount=round(st.arrears_amount,2),
    overdue_days=case when st.oldest_overdue is null then 0 else current_date-st.oldest_overdue end,
    updated_at=now()
from schedule_totals st
where l.id=st.loan_id;

insert into public.loan_audit_log (
  business_id,user_id,action,table_name,record_id,new_value
)
select distinct a.business_id,null::uuid,'historical_schedule_dates_realigned','loans',a.loan_id::text,
  jsonb_build_object('basis','application_date','first_due_offset_days',7,'fixed_at',now())
from public.jufinallies_schedule_date_fix_audit a
where not exists (
  select 1 from public.loan_audit_log existing
  where existing.business_id=a.business_id
    and existing.record_id=a.loan_id::text
    and existing.action='historical_schedule_dates_realigned'
);

commit;

select l.loan_no,c.full_name client,a.application_date,l.first_repayment_date,
  l.maturity_date,l.arrears_amount,l.overdue_days,
  count(s.id) current_installments
from public.loans l
join public.loan_applications a on a.id=l.application_id
join public.loan_clients c on c.id=l.client_id
join public.loan_schedules s on s.loan_id=l.id and s.status<>'restructured'
where l.status='active'
group by l.loan_no,c.full_name,a.application_date,l.first_repayment_date,
  l.maturity_date,l.arrears_amount,l.overdue_days
order by c.full_name,l.loan_no;
