# Email Schedule — Requirements

## What It Does
Manages delivery of invoice PDFs to tenant school administrators via email. Supports immediate send and future-dated scheduled dispatch. Uses Laravel queues for asynchronous processing. DomPDF generates the invoice PDF attachment within the queue job. Operates on `prime_db` and serves central Super Admins.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment |
| `invoice_id` | INT UNSIGNED FK → `bil_tenant_invoices` | Required. NOTE: No FK constraint in current DDL — must be added. |
| `schedule_time` | TIMESTAMP | Required. Scheduled dispatch time. For immediate send, set to current time. |
| `status` | VARCHAR(255) | Required. Default 'pending'. Values: pending, sent, failed. |
| `is_active` | BOOLEAN | Required. Default 1. Missing from current DDL. |
| `created_by` | INT UNSIGNED FK → `sys_users` | Nullable. Missing from current DDL. |
| `deleted_at` | TIMESTAMP | Nullable. Missing from current DDL. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Immediate Email Flow**
1. Admin selects invoices and clicks "Send Email"
2. POST `/billing/billing-management/send-email` with `ids[]` array
3. For each invoice ID: `SendInvoiceEmailJob::dispatch($id)` is called
4. Queue worker picks up the job:
   - Load `BilTenantInvoice` with tenant relationship
   - Generate DomPDF invoice (A4 portrait)
   - Create `InvoicingAuditLog` entry with action_type = 'Notice Sent'
   - Send `InvoiceMail` to tenant's email with PDF attachment
5. Response: JSON `{status: true, message: 'Emails queued successfully!'}`

**Scheduled Email Flow**
1. Admin selects an invoice and sets a future date/time
2. POST `/billing/billing-management/schedule-email` with `id` and `schedule_time`
3. Create `BillTenantEmailSchedule` record with status='pending'
4. Create `InvoicingAuditLog` entry with action_type = 'Notice Sent'
5. `SendInvoiceEmailJob::dispatch($id)->delay($scheduleTime)` — job dispatched with delay
6. Response: JSON `{status: true, message: "Email scheduled for DD Mon YYYY HH:MM AM/PM"}`

**Queue Context Safety**
- `auth()->id()` is null inside queue jobs (no authenticated user)
- `performed_by` must be captured in the controller and passed to the job constructor
- Current implementation has this gap — Auth::id() is called inside handle() where it returns null

**Email Content**
- Subject: "Invoice - {invoice_no}"
- Body: Rendered from `invoicing/email.blade.php` view
- Attachment: DomPDF-generated invoice PDF attached to the email
- Recipient: Tenant school's email address from `prm_tenant`

**Schedule Cancellation**
- Admin can cancel a pending scheduled email
- Route: `DELETE /email-schedule/{emailSchedule}`
- Sets status to 'cancelled' or soft-deletes the record
- Only pending schedules can be cancelled

## Filter System

The Email Schedule tab uses a `when()` based filter chain in `EmailScheduleController::index()`:

| Parameter | Type | Behavior |
|---|---|---|
| `search` | Text input | Searches via `whereHas('invoice')` on `invoice_no LIKE %search%` AND `orWhereHas('invoice.tenant')` on `name LIKE %search%`. Cross-table OR search across invoice number and tenant name. |
| `status` | Select dropdown | Exact match on `BillTenatEmailSchedule.status` column. Only applied when value is non-null and non-empty string. |

Default query: `BillTenatEmailSchedule::with(['invoice.tenant'])` — eager loads 2-level relationship. Ordered by `schedule_time DESC` (newest scheduled first). Paginated at 15 per page.

## CRUD Operations

**List Scheduled Emails**
- Route: `GET /email-schedule`
- Shows table with columns: invoice_no, tenant, schedule_time, status, created_at, Actions
- Search by invoice_no or tenant name
- Filter by status (pending, sent, failed, cancelled)
- Paginated with standard Laravel pagination

**View Schedule Details**
- Route: `GET /email-schedule/{emailSchedule}`
- Shows full schedule details with invoice information

**Cancel Schedule**
- Route: `DELETE /email-schedule/{emailSchedule}`
- Triggered via SweetAlert2 confirmation
- Only applies to schedules with status='pending'
- Soft deletes the record

## Email Queue Job — SendInvoiceEmailJob

**Properties**
- Implements `ShouldQueue` for async dispatch
- `$tries`: Default Laravel retry (customize to 3)
- `$backoff`: Define exponential backoff (e.g., [60, 300])

**handle() Method Flow**
1. Load `BilTenantInvoice` with `tenant` relationship
2. Generate PDF via `Pdf::loadView('billing-management.partials.invoicing.pdf', ...)`
3. Create audit log: `InvoicingAuditLog::create([...])` with performed_by from constructor
4. Send email: `Mail::to($invoice->tenant->email)->send(new InvoiceMail($invoice, $pdf))`
5. Update email schedule status to 'sent' (if scheduled)

**Failed Job Handling**
- Update `BillTenantEmailSchedule.status = 'failed'` on failure
- Log failure reason for debugging

## Permissions

| Operation | Permission Key |
|---|---|
| View email schedule tab | `prime.billing-management.viewAny` |
| Send immediate email | `prime.billing-management.create` |
| Schedule email | `prime.billing-management.create` |
| Cancel scheduled email | N/A (not in permissions list) |
