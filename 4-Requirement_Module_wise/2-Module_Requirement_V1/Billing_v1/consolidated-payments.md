# Consolidated Payments — Requirements

## What It Does
Allows recording a single payment transaction distributed across multiple outstanding invoices. Supports scenarios where a school tenant submits one bank transfer or cheque covering several invoices. Records the total consolidated amount and per-invoice allocations with full audit trail. Operates on `prime_db` for central Super Admin use.

## Database Fields

Same `bil_tenant_invoicing_payments` table as individual payments with these additional rules:

| Field | Type | Conditions |
|---|---|---|
| `consolidated_amount` | DECIMAL(14,2) | Nullable. Total cheque/bank transfer amount across all invoices. Set only for consolidated payments. |
| `amount_paid` | DECIMAL(14,2) | Required. Per-invoice allocation. Sum of all allocations should match `consolidated_amount`. |

## Business Rules

**Consolidated vs Individual**
- `consolidated_amount` is NULL for individual payments, non-NULL for consolidated
- Per-invoice `amount_paid` is stored separately for each invoice in the consolidation

**Zero-Allocation Skip**
- If `new_payment[invoice_id]` = 0, the invoice is skipped entirely
- Only invoices with a positive allocation value are processed

**Atomic Multi-Invoice Update**
- All invoice updates happen within a single `DB::beginTransaction()` / `DB::commit()`
- Each invoice in the consolidation: create InvoicingPayment (with consolidated_amount) → update invoice.paid_amount → create PAYMENT_UPDATED audit log
- NOTE: Current implementation lacks try/catch — any exception leaves transaction open

**Validation Gaps**
- `ConsolidatedPaymentRequest` is missing validation rules for `invoice_ids[]`, `new_payment[]`, and `payment_status[]` arrays
- Array inputs are accessed directly from `$request->input()` without validation

## Filter System

The Consolidated Payment tab uses `buildConsolidatedPaymentQuery()` with:

| Parameter | Behavior |
|---|---|
| `tenat_id` | Filters by `BilTenantInvoice.tenant_id` (NOTE: typo in parameter name) |
| `date_range` | Filters by `payment_due_date BETWEEN start AND end` |

**Built-in Hard Filter:**
- Only invoices where `paid_amount < net_payable_amount` (outstanding balance) are shown
- Uses `whereColumn('paid_amount', '<', 'net_payable_amount')` — note: this uses `<` not `!=`, so overpaid invoices (paid_amount > net_payable) are excluded
- Ordered by `payment_due_date ASC` (oldest due first)
- Includes `payments_sum_amount_paid` via `withSum('payments', 'amount_paid')` for display

## CRUD Operations

**Record Consolidated Payment**
- Route: `POST /billing/consolidated-store`
- Preconditions: `prime.billing-management.create` permission
- Input: payment_dates, payment_mode, transaction_id, amount_paid (total), invoice_ids[], new_payment[invoice_id], payment_status[invoice_id]
- Processing: validate → DB::transaction → loop invoice_ids → skip zero allocations → create per-invoice InvoicingPayment → update paid_amount → create per-invoice PAYMENT_UPDATED audit log → commit
- Output: JSON `{status: true, message: string}`

**List Outstanding Invoices**
- Route: `GET /billing/billing-management?type=consolidated-payment`
- Shows invoices where `paid_amount < net_payable_amount`
- Each row has an input field for allocation amount
- Checkboxes allow selecting which invoices to include

**Consolidated Payment PDF**
- Route: `GET /billing/download-consolidated-pdf`
- Filter: invoices where paid_amount < net_payable_amount
- DomPDF-generated statement showing all outstanding invoices with their allocations
- Print view available at `GET /billing/billing-management/print/data?type=consolidated-payment`

**Selected Payments PDF**
- Route: `POST /billing/download-selected-pdf` with `ids[]`
- Generates PDF for selected InvoicingPayment records with invoice details

## Permissions

| Operation | Permission Key |
|---|---|
| View consolidated payment tab | `prime.billing-management.viewAny` |
| Record consolidated payment | `prime.billing-management.create` |
| Download consolidated PDF | `prime.billing-management.pdf` |
