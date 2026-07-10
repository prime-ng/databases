# Email Schedule — Manual Test Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Billing |
| Feature | EmailSchedule |
| Base URL | `http://127.0.0.1:8000/billing/email-schedule` (central, Super-Admin) |
| Controller | `Modules\Billing\Http\Controllers\EmailScheduleController` (index/show/destroy) |
| Send/Schedule | `Modules\Billing\Http\Controllers\BillingManagementController::sendEmail/scheduleEmail` |
| Queue Job | `Modules\Billing\Jobs\SendInvoiceEmailJob` (`ShouldQueue`; `$tries=3`, `$backoff=[60,300,900]`, `$timeout=120`, `failed()`) |
| Mailable | `Modules\Billing\Mail\InvoiceMail` (subject `Invoice - {invoice_no}`, PDF attachment) |
| Model | `BillTenantEmailSchedule` — fillable `invoice_id, schedule_time, status`; **no SoftDeletes**; `invoice()` belongsTo `BilTenantInvoice` |
| Validation | **None** (no FormRequest on send/schedule) — DEV-EMS-002 |
| Migration | `Modules/Prime/database/migrations/2025_12_03_094529_create_bil_tenant_email_schedules_table.php` |
| DDL | **Not present** in `Billing_DDL_v1.sql` — DEV-EMS-003 (schema drift) |
| CRUD type | List / Show / Cancel (status update) + queued email dispatch |
| Soft delete | No |
| Pagination | 15 per page, `schedule_time DESC` |
| Activity log | `sys_activity_logs` (events: `Store` on schedule create, `Cancelled` on cancel) |
| Audit log | `bil_tenant_invoicing_audit_logs` (`action_type`: `Email Scheduled`, `Notice Sent`, `EMAIL_FAILED`) |
| Permissions | `prime.email-schedule.{viewAny,view,delete}`; send/schedule `prime.billing-management.email-schedule` |

**Prerequisites:** Billing module enabled in `prime_testing/modules_statuses.json`; Prime tests run on `http://127.0.0.1:8000`; `APP_ENV=testing`; Super Admin creds `DUSK_ADMIN_EMAIL`/`DUSK_ADMIN_PASSWORD`.

## 2. Business Conditions (detail)

**Immediate send flow** — `POST /billing/billing-management/send-email` with `ids[]`. For each id: `SendInvoiceEmailJob::dispatch($id, auth()->id())`. Response `{status:true, message:'Emails queued successfully!'}`. Worker `handle()`: load invoice → `activityLog($invoice,'Store',...)` → `InvoicingAuditLog action_type='Notice Sent'` → DomPDF A4 → `Mail::to($invoice->tenant->email)->send(InvoiceMail)`.

**Scheduled flow** — `POST /billing/billing-management/schedule-email` with `id` + `schedule_time`. Writes `InvoicingAuditLog action_type='Email Scheduled'`, creates `BillTenantEmailSchedule{status:'pending'}`, `activityLog($schedule,'Store',...)`, then `SendInvoiceEmailJob::dispatch($id, auth()->id())->delay($scheduleAt)`. Response `{status:true, message:'Email scheduled successfully for {d M Y h:i A}'}`.

**Cancel flow** — `DELETE /billing/email-schedule/{emailSchedule}`. Native `confirm('Cancel this scheduled email?')` → `status='cancelled'` → `activityLog($schedule,'Cancelled',...)` → redirect index with flash `Email schedule cancelled successfully.` Only `pending` rows show the cancel action.

**Status lifecycle:** `pending` → (cancel) `cancelled`; `pending` → (delivered) `sent`; `pending` → (failed) `failed`.

## 3. Test Cases (step / action / expected)

### MT-01 — Index render
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as Super Admin; visit `/billing/email-schedule` | 200; heading "Email Schedules"; breadcrumb "Email Schedule Management" |
| 2 | Inspect table head | Columns: Invoice No., Tenant, Scheduled Time, Status, Action |
| 3 | Inspect filter bar | `input[name=search]` + `select[name=status]` (All Status/Pending/Sent/Failed/Cancelled) |
| 4 | If no rows | tbody shows "No Email Schedules Found" |
| 5 | DB check | `SELECT COUNT(*) FROM bil_tenant_email_schedules` matches paginated rows (≤15/page) |

### MT-02 — Schedule an email
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/billing/billing-management/schedule-email` `{id, schedule_time}` (future) | `{status:true, message:'Email scheduled successfully for ...'}` |
| 2 | DB check | `SELECT status FROM bil_tenant_email_schedules WHERE invoice_id=? ORDER BY id DESC` → `pending` |
| 3 | Audit check | `SELECT action_type FROM bil_tenant_invoicing_audit_logs WHERE tenant_invoice_id=?` includes `Email Scheduled` |
| 4 | Activity check | `sys_activity_logs` has `event='Store'`, `subject_type=...BillTenantEmailSchedule` |
| 5 | Queue check | `SendInvoiceEmailJob` dispatched with a delay (use `Bus::fake`) |

### MT-03 — Immediate send
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/billing/billing-management/send-email` `{ids:[id]}` | `{status:true, message:'Emails queued successfully!'}` |
| 2 | Queue check | `SendInvoiceEmailJob` dispatched; `performedById == auth id` |

### MT-04 — Cancel (destroy)
| Step | Action | Expected |
|------|--------|----------|
| 1 | On a `pending` row, click cancel; accept `confirm()` | Redirect to index; flash "Email schedule cancelled successfully." |
| 2 | DB check | `SELECT status FROM bil_tenant_email_schedules WHERE id=?` → `cancelled` (row still exists) |
| 3 | Activity check | `sys_activity_logs` has `event='Cancelled'` for the schedule |
| 4 | Non-pending row | No cancel action rendered (sent/failed/cancelled) |

### MT-05 — Show details
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/billing/email-schedule/{id}` | 200; "Email Schedule Details"; "Schedule Information" + "Related Invoice" cards |
| 2 | Pending row | "Cancel Schedule" button present |
| 3 | Cancelled row | No "Cancel Schedule" button |
| 4 | Back button | "Back to Email Schedules" present |

### MT-06 — Filters & search
| Step | Action | Expected |
|------|--------|----------|
| 1 | `?status=pending` | Only pending rows; page reachable |
| 2 | `?search={invoice_no}` | Matches via `invoice.invoice_no LIKE` |
| 3 | `?search={tenant name}` | Matches via `invoice.tenant.name LIKE` (OR branch) |
| 4 | `?search=<script>alert(1)</script>` | Escaped; no raw script in page source |

### MT-07 — Negative / auth
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/billing/email-schedule/999999999` | 404 |
| 2 | DELETE `/billing/email-schedule/999999999` | 404 |
| 3 | Guest visits index/show | Redirect `/login` |
| 4 | Non-super-admin without permission | 403 |
| 5 | GET (not DELETE) on show id | Shows details; status stays `pending` |

### MT-08 — Job reliability (code inspection — JOB-BIL-001)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect `SendInvoiceEmailJob` | `$tries=3`, `$backoff=[60,300,900]`, `$timeout=120`, `failed()` present |
| 2 | Inspect constructor | `performedById` captured (not resolved inside worker) |
| 3 | Inspect `handle()`/`failed()` | audit `action_type` = `Notice Sent` / `EMAIL_FAILED` |

### MT-09 — Integrity (DATA-BIL-003)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Insert schedule with non-existent `invoice_id` | Insert succeeds (no FK) — documents DATA-BIL-003 |
| 2 | Open index/show for that row | Renders `—` placeholders; no 500 |
