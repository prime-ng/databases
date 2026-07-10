# Email Schedule — Manual Testing Spec (`bil_EmailScheduleMANUALTESTING_Require`)

## 1. Feature Information

| Attribute | Value |
|-----------|-------|
| Module | Billing (BIL) — **central / prime_db** |
| Feature | Email Schedule |
| URL | `http://127.0.0.1:8000/billing/email-schedule` |
| Controller | `EmailScheduleController` (`index`, `show`, `destroy`) |
| Model | `BillTenantEmailSchedule` (`bil_tenant_email_schedules`) |
| Related | `SendInvoiceEmailJob` (queue), `InvoiceMail` (mailable), `InvoicingAuditLog` |
| Validation | None (no FormRequest; read + cancel only) |
| Migrations | **0 module migrations** — table absent from `Billing_DDL_v1.sql`; authority = master `prime_db_v4.sql` |
| CRUD type | Read-only list + detail + **cancel** (no create/edit/store/update routes) |
| Soft delete | **No** (model has no `SoftDeletes`; cancel = status flip to `cancelled`) |
| Pagination | 15 per page |
| Activity log | Central `sys_central_activity_logs`, event **`Cancelled`** on cancel |
| Permissions | `prime.email-schedule.viewAny` / `.view` / `.delete` |

### Environment prerequisites
- **Billing module ENABLED** in `prime_testing/modules_statuses.json` (disabled → 404 on all routes).
- Dusk run on **`127.0.0.1:8000`** (`APP_ENV=testing`), central Super-Admin credentials.
- `bil_tenant_email_schedules` present in the live prime_db (hand-patched; not in module DDL).

---

## 2. Business Conditions (detailed)

### Cancel flow (`destroy`)
```
DELETE /billing/email-schedule/{emailSchedule}
  Gate::authorize('prime.email-schedule.delete')
  $emailSchedule->update(['status' => 'cancelled'])
  activityLog($emailSchedule, 'Cancelled', ['message' => 'Email schedule was cancelled.'])
  redirect central.billing.email-schedule.index with success 'Email schedule cancelled successfully.'
```
- UI shows the cancel control **only** when `status === 'pending'` (index.blade / show.blade).
- **DEV-BIL-ES-003:** the controller applies no `pending` guard — a direct DELETE of a non-pending row would still set `cancelled`.

### Scheduled-email lifecycle (context — creation lives in BillingManagement, not this screen)
```
pending ──cancel(destroy)──▶ cancelled     (implemented)
pending ──job success─────▶ sent           (NOT implemented — DEV-BIL-ES-001)
pending ──job failure─────▶ failed         (NOT implemented — DEV-BIL-ES-001)
```

### Filter chain (index)
| Param | Behaviour |
|-------|-----------|
| `search` | `whereHas('invoice', invoice_no LIKE %s%)` OR `orWhereHas('invoice.tenant', name LIKE %s%)` |
| `status` | exact match, applied only when non-null & non-empty |
| order | `schedule_time DESC`, `paginate(15)` |

---

## 3. Manual Test Cases

### MT-01 — Index loads
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as central Super Admin | Dashboard |
| 2 | Visit `/billing/email-schedule` | HTTP 200, heading "Email Schedules" |
| 3 | Inspect table header | Columns: Invoice No., Tenant, Scheduled Time, Status, Action |
| 4 | DB check | `SELECT count(*) FROM bil_tenant_email_schedules` ≥ rows shown (≤15/page) |

### MT-02 — View schedule detail
| Step | Action | Expected |
|------|--------|----------|
| 1 | Click the eye (View) on a row | `/billing/email-schedule/{id}` |
| 2 | Inspect | "Schedule Information" card: ID, Scheduled Time, Status badge, Created/Updated At |
| 3 | Inspect right card | "Related Invoice" — Invoice No, Date, Tenant, Billing Cycle, Net Payable |

### MT-03 — Cancel a pending schedule
| Step | Action | Expected |
|------|--------|----------|
| 1 | On a `pending` row, click the ban/Cancel button | Native confirm "Cancel this scheduled email?" |
| 2 | Accept the confirm | Redirect to index, green flash "Email schedule cancelled successfully." |
| 3 | DB check | `SELECT status FROM bil_tenant_email_schedules WHERE id={id}` → `cancelled` |
| 4 | Activity check | `sys_central_activity_logs` row: event=`Cancelled`, subject_id={id} |

### MT-04 — Cancel control visibility
| Step | Action | Expected |
|------|--------|----------|
| 1 | Filter `?status=pending` | Cancel button present on rows |
| 2 | Filter `?status=sent` | **No** cancel button (view guards on pending) |

### MT-05 — Search & filter
| Step | Action | Expected |
|------|--------|----------|
| 1 | Search an invoice number | Only matching invoice rows |
| 2 | Search a tenant name | Only that tenant's rows |
| 3 | Search `ZZ-NO-SUCH-INVOICE` | "No Email Schedules Found" |
| 4 | Status = Failed (none exist) | Empty / no matching rows |

### MT-06 — Not found / auth
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/billing/email-schedule/99999999` | 404 |
| 2 | Logout, visit index | Redirect `/login` |
| 3 | Login as user without `prime.email-schedule.*` | 403 Forbidden on index and show |

### MT-07 — State-machine defects (document current behaviour)
| Step | Action | Expected (current) | Defect |
|------|--------|--------------------|--------|
| 1 | Queue `SendInvoiceEmailJob`, let it succeed | schedule stays `pending` (no `sent` write) | DEV-BIL-ES-001 |
| 2 | Force the job to fail | schedule stays `pending` (only audit-log `EMAIL_FAILED`) | DEV-BIL-ES-001 |
| 3 | DELETE a `sent` schedule directly (API) | status becomes `cancelled` (no guard) | DEV-BIL-ES-003 |

### MT-08 — Integrity / security
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open a schedule whose `invoice_id` no longer exists | "No linked invoice found." (no error — no FK, DEV-BIL-ES-002) |
| 2 | Search `<script>alert(1)</script>` | Value escaped in the input; no script executes |
| 3 | Attempt to mass-assign `id` when creating a schedule | `id` ignored (fillable = invoice_id/schedule_time/status) |
