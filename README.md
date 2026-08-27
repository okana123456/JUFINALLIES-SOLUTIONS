# Jufinallies Solutions

Professional loan operations system with fixed product pricing, client management, approvals, bulk disbursement, repayments, arrears, charge wallets, accounting, staff access controls, reports, PWA installation and Safaricom Daraja C2B support.

## Product Rules

The approved pricing matrix is defined once in `index.html` and is used by applications, disbursement, schedules and the calculator.

- CHEMSHA: KES 3,000-5,000
- INUKA: KES 6,000-10,000
- JIFUNGIE: KES 11,000-15,000
- JITEGEMEE: KES 16,000-20,000
- NAWIRI: KES 21,000-30,000
- Every loan requires KES 200 loan form fee and KES 250 credit report fee, plus its matrix processing fee.

Only approved amount and term combinations can be selected. Loan totals and schedules remain balanced to the approved total payable.

## Supabase

Project ref: `iemucoenarynzybowciu`

Apply migrations in `supabase/migrations` in filename order. Never commit database passwords, service-role keys, Daraja credentials or personal access tokens.

Required Edge Function secrets:

```text
JUFINALLIES_PROJECT_URL
JUFINALLIES_ANON_KEY
JUFINALLIES_SERVICE_ROLE_KEY
JUFINALLIES_REGISTRATION_KEY
```

Unique Daraja callbacks:

```text
https://iemucoenarynzybowciu.supabase.co/functions/v1/jufinallies-c2b-validation-v1
https://iemucoenarynzybowciu.supabase.co/functions/v1/jufinallies-c2b-confirmation-v1
```

The Consumer Key and Consumer Secret are entered by the business administrator in Settings and are stored in the backend-only `jufinallies_daraja_credentials` table.

## Local Preview

Serve the repository over HTTP and open `index.html`. The application is also installable as a PWA after deployment.
