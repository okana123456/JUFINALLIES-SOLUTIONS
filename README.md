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

Platform subscription billing begins on 1 October 2026. Its STK payment flow uses these additional secrets:

```text
SERVICE_BILLING_AMOUNT=3000
SERVICE_BILLING_START_DATE=2026-10-01
SERVICE_CONSUMER_KEY
SERVICE_CONSUMER_SECRET
SERVICE_PASSKEY
SERVICE_SHORTCODE
SERVICE_TRANSACTION_TYPE=CustomerPayBillOnline
SERVICE_DARAJA_ENVIRONMENT=production
SERVICE_CALLBACK_URL=https://iemucoenarynzybowciu.supabase.co/functions/v1/service-payment-callback
```

Unique Daraja callbacks:

```text
https://iemucoenarynzybowciu.supabase.co/functions/v1/jufinallies-c2b-validation-v1
https://iemucoenarynzybowciu.supabase.co/functions/v1/jufinallies-c2b-confirmation-v1
```

For customer loan repayments, the business administrator enters the business PayBill shortcode, Consumer Key, Consumer Secret and environment in Settings. These are stored in the backend-only `jufinallies_daraja_credentials` table and use the unique C2B callbacks above. The `SERVICE_*` secrets are separate platform-owner credentials used only to collect Jufinallies monthly subscriptions through STK Push.

## Local Preview

Serve the repository over HTTP and open `index.html`. The application is also installable as a PWA after deployment.
