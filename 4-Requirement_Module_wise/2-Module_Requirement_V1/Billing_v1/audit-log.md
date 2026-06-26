# Invoice Audit Log — Requirements

## What It Does
Immutable event-level audit trail for every action in the invoice lifecycle. Each invoice event (generation, payment, email, status change) creates an audit log entry with the event type, timestamp, performing user, and structured JSON metadata. Supports manual audit notes for administrative annotations. Operates on `prime_db`.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment |
| `tenant_invoice_id` | INT UNSIGNED FK → `bil_tenant_invoices` | Required. CASCADE on delete. NOTE: Current model uses wrong column name `tenant_invoicing_id` — must align with DDL. |
| `action_date` | TIMESTAMP | Required. When the event occurred. No default — must be explicitly set. |
| `action_type` | VARCHAR(20) | Required. Dropdown key: invoice_status. Values: GENERATED, Partially Paid, Notice Sent, PAYMENT_UPDATED, Not Billed, PENDING. |
| `performed_by` | INT UNSIGNED FK → `sys_users` | Nullable. Who performed the action. NULL for system-generated events (queue jobs). |
| `event_info` | JSON | Nullable. Structured metadata about the event. Should be array-cast. Missing from current DDL. |
| `notes` | VARCHAR(500) | Nullable. Updatable field for manual annotations. |
| `is_active` | BOOLEAN | Required. Default 1. Missing from current DDL. |
| `created_by` | INT UNSIGNED FK → `sys_users` | Nullable. Missing from current DDL. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. Missing from current DDL. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. `updated_at` missing from current DDL. |

## Business Rules

**Append-Only (Except Notes)**
- Audit log entries are created via `create()` — never updated except for the `notes` field
- The `auditAddNoteUpdate` endpoint is the only update operation
- This ensures the audit trail remains tamper-evident

**Action Types and Their Triggers**

| Action Type | Trigger Event | Payload |
|---|---|---|
| GENERATED | Invoice successfully created | Invoice ID, amount, period, student count |
| Partially Paid | Payment recorded with partial amount | Payment ID, amount, mode |
| PAYMENT_UPDATED | Consolidated payment per-invoice allocation | Payment ID, allocated amount |
| Notice Sent | Email sent or scheduled for invoice | Email schedule ID, recipient |
| Not Billed | Invoice marked as not billed | Manual toggle |
| PENDING | Default/initial state | N/A |

**Sensitive Data Protection**
- `event_info` JSON must NOT store raw `$request->all()` data
- Whitelisted fields only: `amount_paid`, `payment_mode`, `payment_status`, `transaction_id`, `currency`, `payment_date`
- Current implementation stores `$request->all()` — this is a security gap

**Event Info JSON Structure**
- Should contain structured metadata relevant to the event type
- Example for payment: `{amount_paid: 50000, payment_mode: "BANK_TRANSFER", transaction_id: "NEFT123"}`
- Example for GENERATED: `{invoice_no: "INV-20260326-001", net_payable: 125000, billing_qty: 250}`

**Queue Job Context**
- When audit logs are created inside a queued job (SendInvoiceEmailJob), `auth()->id()` returns null
- `performed_by` must be explicitly passed to the job constructor, not read from Auth in the handle() method
- Current implementation has this gap — Auth::id() in queue context returns null

## Filter System

The Audit Log tab uses `buildAuditLogQuery()` with:

| Parameter | Behavior |
|---|---|
| `date_range` | Filters `InvoicingAuditLog.action_date BETWEEN start AND end` |
| `tenat_id` | Filters by invoice's `tenant_id` via `whereHas('invoice')` (NOTE: typo in parameter name) |
| `performed_by` | Exact match on `InvoicingAuditLog.performed_by` (user ID) |
| `audit_status` | Exact match on `InvoicingAuditLog.action_type` (GENERATED, Partially Paid, Notice Sent, etc.) |

Default query: `InvoicingAuditLog::with(['invoice', 'user'])` — eager loads relationships. Ordered by `action_date DESC` (newest first).

## CRUD Operations

**View Audit Log (AJAX)**
- Route: `GET /billing/billing/audit-log?id={invoice_id}`
- Returns JSON `{html: string}` with all audit entries for the invoice
- Ordered DESC by `created_at`
- Shows: action_type, action_date, performed_by, event_info summary

**Add Audit Note**
- Route: `GET /billing/audit/add-note?id=`
- Returns JSON `{html: string}` with the add-note form

**Update Audit Note**
- Route: `POST /billing/audit/add-note/update`
- Updates the `notes` field on an existing audit log entry
- Only the notes field is mutable

**View Event Info Detail**
- Route: `GET /billing/audit/event-info?id=`
- Returns JSON `{html: string}` showing the full event_info JSON contents

**Download Audit Report (PDF)**
- Route: `GET /billing/audit/download-pdf`
- Filterable by: date_range, tenant_id, performed_by, audit_status
- DomPDF-generated report of audit log entries

**Audit Log Print View**
- Route: `GET /billing/billing-management/print/data?type=audit-note`
- Browser-printable format

## Permissions

| Operation | Permission Key |
|---|---|
| View audit log tab | `prime.invoicing-audit-log.viewAny` |
| View audit log details | `prime.invoicing-audit-log.view` |
| Add audit note | `prime.invoicing-audit-log.create` |
| Update audit note | `prime.invoicing-audit-log.update` |
| Delete audit note | `prime.invoicing-audit-log.delete` |
| Restore audit note | `prime.invoicing-audit-log.restore` |
| Force delete audit note | `prime.invoicing-audit-log.forceDelete` |
