# Invoice Payments — Requirements

## What It Does
Records individual payments made against a single invoice. Tracks payment details including mode (Online, Bank Transfer, Cash, Cheque), transaction references, amounts, and gateway responses. Updates the invoice's cumulative `paid_amount` and status automatically. Operates on `prime_db` for central Super Admin billing management.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment |
| `tenant_invoice_id` | INT UNSIGNED FK → `bil_tenant_invoices` | Required. CASCADE on delete. |
| `payment_date` | DATE | Required. Date payment was recorded. |
| `transaction_id` | VARCHAR(100) | Nullable. Gateway or bank reference number. |
| `mode` | VARCHAR(20) | Required. Dropdown key: `bil_tenant_invoicing_payments.mode`. Values: ONLINE, BANK_TRANSFER, CASH, CHEQUE. |
| `mode_other` | VARCHAR(20) | Nullable. Custom mode description. |
| `amount_paid` | DECIMAL(14,2) | Required. Per-invoice allocation amount. |
| `consolidated_amount` | DECIMAL(14,2) | Nullable. Total amount if part of consolidated payment. |
| `currency` | CHAR(3) | Required. Default 'INR'. ISO 4217. |
| `payment_status` | VARCHAR(20) | Required. Default 'SUCCESS'. Dropdown: INITIATED, SUCCESS, FAILED. |
| `gateway_response` | JSON | Nullable. Raw gateway response stored for reconciliation. |
| `payment_reconciled` | BOOLEAN | Required. Default 0. Whether payment is confirmed. |
| `remarks` | VARCHAR(255) | Nullable. Additional notes. |
| `is_active` | BOOLEAN | Required. Default 1. Missing from current DDL. |
| `created_by` | INT UNSIGNED FK → `sys_users` | Nullable. Missing from current DDL. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. Missing from current DDL. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Cumulative Paid Amount**
- `paid_amount` on the invoice is always incremented: `new_paid = old_paid + amount_paid`
- `paid_amount` is never decremented — corrections must use a new payment with negative amount or a credit note

**Status Auto-Calculation**
- After payment recorded: if `paid_amount >= net_payable_amount` → invoice status = PAID
- If `paid_amount > 0` but `< net_payable_amount` → invoice status = PARTIALLY_PAID
- Comparison uses `whereColumn('paid_amount', '<', 'net_payable_amount')`

**Overpayment Handling**
- `paid_amount` can exceed `net_payable_amount` (overpayment allowed)
- Overpaid invoices still show as PAID

**Transaction Atomicity**
- Payment recording is wrapped in `DB::beginTransaction()` / `DB::commit()`
- Creates: `InvoicingPayment` record
- Updates: invoice `paid_amount` and `status`
- Creates: audit log entry with event type PAYMENT_UPDATED or Partially Paid
- NOTE: Current implementation lacks try/catch — any exception leaves transaction open

**Audit Log Safety**
- Audit `event_info` must NOT store `$request->all()` which includes sensitive fields
- Whitelisted fields only: `amount_paid`, `payment_mode`, `payment_status`, `transaction_id`, `currency`, `payment_date`
- Current implementation logs `$request->all()` — this is a security gap (sensitive data leak risk)

**Payment Mode**
- Selected from system dropdown: ONLINE, BANK_TRANSFER, CASH, CHEQUE
- If "Other" is selected, `mode_other` stores the custom value

## Filter System

The Invoice Payment tab uses `buildInvoicePaymentQuery()` with:

| Parameter | Behavior |
|---|---|
| `date_range` | Filters `BilTenantInvoice.invoice_date BETWEEN start AND end` |
| `payment_status` | Exact match on `BilTenantInvoice.status` column |

Default query: `BilTenantInvoice::query()` with no initial filters — all invoices are shown if no filters provided.

## CRUD Operations

**Record Payment**
- Route: `POST /billing/invoicing-payment`
- Preconditions: `prime.invoicing-payment.create` permission; invoice must exist
- Input: tenant_invoice_id, date, amount_paid, currency, payment_mode, pay_mode_other, transaction_id, payment_status, payment_reconciled, gateway_resp, remarks
- Validation: via `StoreInvoicePaymentRequest` (NOTE: controller bypasses `$request->validated()` and uses `$request->date` directly — gap)
- Processing: validate → create InvoicingPayment → update invoice paid_amount → update invoice status → create audit log
- Output: JSON `{status: true, message: 'Payment saved successfully!'}`

**Add Payment Form (AJAX)**
- Route: `GET /billing/invoicing-payment/create?id={invoice_id}`
- Returns JSON `{html: string}` with the add-payment form partial
- Pre-filled with invoice ID, current paid_amount, net_payable

**Payment Details Panel (AJAX)**
- Route: `GET /billing/payment-details?id={invoice_id}`
- Returns JSON `{html: string}` listing all InvoicingPayment records for the invoice
- Shows: payment_date, mode, amount, transaction_id, reconciled status

## Permissions

| Operation | Permission Key |
|---|---|
| View invoice payment tab | `prime.invoicing-payment.viewAny` |
| View payment details | `prime.invoicing-payment.view` |
| Record payment | `prime.invoicing-payment.create` |
| Update payment | `prime.invoicing-payment.update` |
| Delete payment | `prime.invoicing-payment.delete` |
