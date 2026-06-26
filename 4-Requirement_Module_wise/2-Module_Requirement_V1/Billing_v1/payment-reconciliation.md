# Payment Reconciliation — Requirements

## What It Does
Provides a manual toggle mechanism for reconciling recorded payments against bank or gateway confirmations. Accountants can mark individual payment records as reconciled or unreconciled to track which payments have been confirmed. Includes PDF and print views for reconciliation reporting.

## Database Fields

Reconciliation operates on the `bil_tenant_invoicing_payments` table's existing `payment_reconciled` field:

| Field | Type | Conditions |
|---|---|---|
| `payment_reconciled` | BOOLEAN | Required. Default 0. Toggled between 0 (unreconciled) and 1 (reconciled). |

## Business Rules

**Manual Toggle Only**
- Reconciliation is purely manual — no automated matching with bank statements or gateway responses
- The toggle flips `payment_reconciled` between 0 and 1
- No validation or precondition check before toggling

**Audit Trail**
- Every toggle action is logged via `activityLog()` helper to `sys_activity_logs`
- Log includes: model ID, previous state, new state, timestamp, performing user

**Current Gap**
- No automated reconciliation matching (RBS task ST.V3.2.2.1)
- No mismatch flagging (RBS task ST.V3.2.2.2)
- `payment_reconciled = 0` shows in UI as "unreconciled" but no automated detection of mismatches

## Filter System

The Payment Reconciliation tab uses `buildPaymentReconciliationQuery()` with:

| Parameter | Behavior |
|---|---|
| `date_range` | Filters by invoice's `invoice_date BETWEEN start AND end` via `whereHas('invoice')` |
| `payment_reconcilation_status` | Three-way filter: empty = all, `"Reconciled Transactions Only"` = `payment_reconciled = 1`, `"Non-Reconciled Trans. Only"` = `payment_reconciled = 0` |

Default query: `InvoicingPayment::with('invoice')` — eager loads the invoice relationship for tenant and invoice number display.

## CRUD Operations

**Toggle Reconciliation Status**
- Route: `POST /billing/billing-management/{session}/toggle-status`
- Preconditions: `prime.billing-management.status` permission
- Processing: Find InvoicingPayment by ID → toggle `payment_reconciled` (0→1 or 1→0) → save → activityLog
- Output: JSON `{success: true, data: {payment_reconciled: bool}}`

**List Payments for Reconciliation**
- Route: `GET /billing/billing-management?type=payment-reconcilation`
- Shows table with columns: invoice_no, tenant, payment_date, amount, mode, transaction_id, reconciled status, toggle button
- Filter by date range and tenant
- Each row has a toggle button that triggers the AJAX endpoint

**Reconciliation PDF**
- Route: `POST /billing/download-selected-pdf` with `ids[]`
- Generates DomPDF for selected InvoicingPayment records
- Shows: payment details, invoice reference, reconciliation status

**Reconciliation Print View**
- Route: `GET /billing/billing-management/print/data?type=payment-reconcilation`
- Browser-printable view of payment reconciliation data

## Permissions

| Operation | Permission Key |
|---|---|
| View reconciliation tab | `prime.billing-management.viewAny` |
| Toggle reconciliation | `prime.billing-management.status` |
| Download reconciliation PDF | `prime.billing-management.pdf` |
