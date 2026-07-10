# Invoice Audit Log — Manual Testing Specification (`bil_InvoicingAuditLog`)

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Billing (BIL) |
| Feature / screen | InvoicingAuditLog (`Billing_v1/audit-log.md`) |
| **DB scope** | **PRIME / CENTRAL** — `prime_db`, central domain `http://127.0.0.1:8000` |
| Primary table | `bil_tenant_invoicing_audit_logs` |
| URL | `/billing/billing-management` → **Invoicing Audit** tab (`#invoicing-audit-tab` / `#invoicing-audit-pane`) |
| Controllers | `InvoicingAuditLogController` (note add/edit, event-info, PDF); `BillingManagementController::AuditLog`, `buildAuditLogQuery` |
| Models | `Modules\Billing\Models\InvoicingAuditLog` (relations: `invoice`→`BilTenantInvoice`, `user`→`Prime\User`) |
| Policy / permissions | `prime.invoicing-audit-log.{viewAny,view,create,update,delete,restore,forceDelete,print,pdf}` |
| Validation | No FormRequest — controllers `findOrFail($request->id)`; DB-level limits (`notes` 500, `action_type` 20) |
| Migrations | **None** (0 migrations; schema from `Billing_DDL_v1.sql`) |
| CRUD type | Append-only audit trail (create at event sites); only `notes` mutable |
| Soft delete | **Declared in model, NOT in DDL** (deleted_at missing) — see DEV-BIL-A02 |
| Pagination | Yes (`->links()`) |
| Activity log | `activityLog($log, 'Store', ['message'=>'Audit Log Note Add'])` (event string **`Store`** verbatim) |

### Route reference (central.* — from `routes/web.php`)

| Name | Verb / Path | Controller |
|------|-------------|------------|
| `central.billing.billing-management.audit.log` | GET `billing/audit-log?id=` | `BillingManagementController@AuditLog` |
| `central.billing.audit.add.note` | GET `audit/add-note?id=` | `InvoicingAuditLogController@auditAddNote` |
| `central.billing.audit.add.note.update` | POST `audit/add-note/update` | `InvoicingAuditLogController@auditAddNoteUpdate` |
| `central.billing.audit.event.info` | GET `audit/event-info?id=` | `InvoicingAuditLogController@auditEventInfo` |
| `central.billing.audit-note.download.pdf` | GET `audit-note.download.pdf` | `InvoicingAuditLogController@downloadAuditNotePdf` |
| `central.billing.invoicing-audit-log.*` | resource | `InvoicingAuditLogController` (index/create/store/show/edit/update/destroy — all stubs) |

### Environment prerequisites
1. `Billing` module **enabled** in `prime_testing/modules_statuses.json` (else 404 on all routes — E19).
2. Run on **`http://127.0.0.1:8000`** (`PrimeDuskTestCase` fails otherwise — E21). `APP_ENV=testing` (bypass CSRF — E20).
3. `MAIN_PROJECT_PATH` → `prime_ai` absolute path (for source-truth asserts).
4. `DUSK_BILLING_DDL_PATH` optionally overrides the DDL location (defaults to `2-DDL_Tenant_Consolidated/Billing_DDL_v1.sql`).

---

## 2. Business Conditions (detailed)

### Append-Only Trail (BC-BIZ-01)
- Entries created by `InvoicingAuditLog::create([...])` at 6+ event sites (invoice PDF, email schedule, remark update, payment received/updated).
- The **only** mutation is `notes` via `auditAddNoteUpdate`; `action_type`/`action_date`/`event_info` are never re-written.
- **Flow:** event fires → `create()` writes row → tab lists rows (`created_at DESC`) → admin may Add Note (patch `notes`) → activity `Store` logged.

### event_info whitelist (BC-VAL / DEV-BIL-A03)
- **Documented whitelist:** `amount_paid`, `payment_mode`, `payment_status`, `transaction_id`, `currency`, `payment_date`.
- **Current reality:** literal `$request->all()` is gone, but `InvoicingPaymentController` still writes `remarks`, `gateway_resp`, `payment_reconciled` (raw request keys) into `event_info` → residual over-capture.

### Authorization anomalies
- **DEV-BIL-A04:** action buttons use `@can('audit.invoicing-audit-log.remakr')` / `@canany(['audit.invoicing-audit-log.remakr','audit.invoicing-audit-log.viewAny'])` — backend grants `prime.invoicing-audit-log.*`, so those buttons never render (note-edit UI hidden).
- **DEV-BIL-A05:** `AuditLog` read authorizes `prime.billing-management.view`, not `prime.invoicing-audit-log.view`.

### Schema fatal defects
- **DEV-BIL-A01 (P0):** DDL column `tenant_invoicing_id`; model/inserts use `tenant_invoice_id` → insert `SQLSTATE 42S22 Unknown column`.
- **DEV-BIL-A02 (P0):** `SoftDeletes` + default timestamps but DDL has only `created_at` (no `updated_at`/`deleted_at`) → any `save()`/`forceDelete()`/trash query throws on a schema-correct DB.

---

## 3. Manual Test Cases (Step / Action / Expected)

### MTC-01 — View audit tab with filters (TC-P11)
| # | Action | Expected |
|---|--------|----------|
| 1 | Log in at `http://127.0.0.1:8000/login` as super-admin | Dashboard loads |
| 2 | Visit `/billing/billing-management` | Page 200; not `/login` |
| 3 | Click **Invoicing Audit** tab (`#invoicing-audit-tab`) | `#invoicing-audit-pane` shown |
| 4 | Inspect filter row | `date_range`, tenant select, `performed_by`, `audit_status` present; audit table present |
| 5 | DB check | `SELECT * FROM bil_tenant_invoicing_audit_logs` (may be empty; NOTE inserts fail per DEV-BIL-A01) |

### MTC-02 — Add / update audit note (TC-P04, TC-P05)
| # | Action | Expected |
|---|--------|----------|
| 1 | On an audit row, click **Add Note** (`.audit-add-note`) | AJAX `GET central.billing.audit.add.note?id=`; modal shows textarea `#auditNoteText` + `#saveAuditNoteBtn` |
| 2 | Type a note, click Save | `POST central.billing.audit.add.note.update` `{id,notes,_token}`; toast `Audit note updated successfully!` |
| 3 | DB check | `SELECT notes FROM bil_tenant_invoicing_audit_logs WHERE id=?` → new note; `action_type`/`action_date` unchanged |
| 4 | Activity-log check | `sys_activity_logs` row event `Store`, message `Audit Log Note Add`, issued_by = admin |
| 5 | Blocked reality | On a schema-correct DB `save()` throws (no `updated_at`) — DEV-BIL-A02 |

### MTC-03 — Event info detail (TC-N08)
| # | Action | Expected |
|---|--------|----------|
| 1 | Click **Event Info** (`.audit-event-info`) | `GET central.billing.audit.event.info?id=`; modal lists key/value from `event_info` JSON |
| 2 | Inspect a payment event | Keys include over-captured `remarks`/`gateway_response` (DEV-BIL-A03) |
| 3 | XSS check | Values printed via `{{ $value }}` (escaped) |

### MTC-04 — Invalid id (TC-N01/02/03)
| # | Action | Expected |
|---|--------|----------|
| 1 | `GET audit/add-note?id=999999` | HTTP 404 (`findOrFail`) |
| 2 | `POST audit/add-note/update {id:999999}` | HTTP 404 |
| 3 | `GET audit/event-info?id=999999` | HTTP 404 |

### MTC-05 — Guest redirect (TC-N06)
| # | Action | Expected |
|---|--------|----------|
| 1 | Clear cookies; visit `/billing/billing-management` | Redirect to `/login` |

### MTC-06 — Permission mismatch (DEV-BIL-A04)
| # | Action | Expected |
|---|--------|----------|
| 1 | Grant only `prime.invoicing-audit-log.*`; open tab | Rows list, but **Add Note / Event Info action buttons do not appear** (gated on non-existent `audit.*`) |
| 2 | Source check | `grep 'audit.invoicing-audit-log.remakr' invoice-audit/index.blade.php` matches; `prime.invoicing-audit-log.remark` absent |

### MTC-07 — PDF export (TC-P12)
| # | Action | Expected |
|---|--------|----------|
| 1 | Apply filters; click **PDF** (`#downloadData`) | `GET central.billing.audit-note.download.pdf` streams `audit-note-report.pdf` |
| 2 | Permission | Requires `prime.invoicing-audit-log.pdf` for button, `prime.invoicing-audit-log.view` for endpoint |

### MTC-08 — Schema truth (TC-DEV01/02)
| # | Action | Expected |
|---|--------|----------|
| 1 | `DESCRIBE bil_tenant_invoicing_audit_logs` | Column `tenant_invoicing_id` present; `tenant_invoice_id` absent; no `updated_at`/`deleted_at` |
| 2 | Compare to model | `$fillable`/relation use `tenant_invoice_id` → mismatch confirmed (DEV-BIL-A01) |
| 3 | Insert attempt | `INSERT ... (tenant_invoice_id) ...` → `Unknown column 'tenant_invoice_id'` |
