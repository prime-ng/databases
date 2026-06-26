# Payment Gateway Integration — Requirements

## What It Does
Planned integration with Razorpay payment gateway for online payment processing. Currently the Razorpay PHP SDK (`razorpay/razorpay` v2.9) is installed via Composer but not yet connected. The `bil_tenant_invoicing_payments` table has a `gateway_response` JSON column ready to store webhook responses. This feature is in the planning stage with zero implementation.

## Current State

| Component | Status |
|---|---|
| Razorpay SDK in composer.json | ✅ Installed (v2.9) |
| Gateway response column in DB | ✅ `gateway_response` JSON column exists |
| API keys configuration | ❌ Not configured |
| Webhook endpoint | ❌ Not created |
| Payment initiation UI | ❌ Not built |
| Webhook signature verification | ❌ Not implemented |
| Tenant-facing payment page | ❌ Not built |
| Multi-currency support | ❌ Not configured |

## Database Fields

The `gateway_response` JSON column on `bil_tenant_invoicing_payments` is pre-provisioned:

| Field | Type | Conditions |
|---|---|---|
| `gateway_response` | JSON | Nullable. Stores raw Razorpay webhook response. Currently unused. |

## Business Rules

**Webhook Security (Critical)**
- Razorpay webhook endpoint MUST NOT be behind `auth` middleware
- Webhooks are server-to-server calls without a user session
- Must use HMAC signature verification using `X-Razorpay-Signature` header and `razorpay.webhook_secret` config
- On signature verification failure: return HTTP 400 (not 401/403 which leaks auth info)

**Webhook Event Handling**
- `payment.captured` event: find matching invoice by `payment_id` in gateway_response → create InvoicingPayment → update invoice.paid_amount → create audit log entry → set payment_reconciled = 1
- Other events (payment.failed, order.paid): logged but no invoice mutation

**API Route Registration**
- Webhook route must be in `routes/api.php` (not behind `auth` middleware)
- All other Razorpay-related routes (initiate payment, check status) are behind auth

## Future CRUD Operations (Planned)

**Initiate Online Payment**
- Route: `POST /api/v1/billing/payment/initiate`
- Creates Razorpay order, returns order_id to frontend
- Frontend uses Razorpay checkout.js to collect payment

**Verify Payment**
- Route: `POST /api/v1/billing/payment/verify`
- Verifies Razorpay payment signature
- Updates invoice and payment records

**Webhook Receiver**
- Route: `POST /api/v1/billing/webhook/razorpay`
- NO auth middleware — uses HMAC signature verification
- Processes payment.captured, payment.failed events

## Permissions

| Operation | Permission Key |
|---|---|
| Initiate online payment | `prime.invoicing-payment.create` |
| View webhook logs | `prime.invoicing-audit-log.viewAny` |
