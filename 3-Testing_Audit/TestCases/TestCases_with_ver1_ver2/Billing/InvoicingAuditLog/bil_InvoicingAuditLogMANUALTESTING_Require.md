# Invoicing Audit Log — Manual Testing Specification

## 1. Feature Information

| Attribute | Value |
|-----------|-------|
| **Module** | Billing (BIL) |
| **Feature** | Invoicing Audit Log (append-only invoice event trail) |
| **DB scope** | `prime_db` **central** (Super-Admin) — **no tenant init** |
| **Tab URL** | `GET /billing/billing-management?type=audit-note` (tab `#invoicing-audit-tab` / pane `#invoicing-audit-pane`) |
| **Controllers** | `InvoicingAuditLogController` (auditAddNote / auditAddNoteUpdate / auditEventInfo / downloadAuditNotePdf + resource stubs); `BillingManagementController` (index tab, `buildAuditLogQuery`, `AuditLog` ajax) |
| **Model** | `Modules\Billing\Models\InvoicingAuditLog` → `bil_tenant_invoicing_audit_logs`; `casts: action_date=datetime`; `fillable: tenant_invoice_id, action_type, action_date, performed_by, notes, event_info`; `HasFactory, SoftDeletes`; `invoice()`→BilTenantInvoice(`tenant_invoice_id`), `user()`→Prime\User(`performed_by`) |
| **Policy** | `InvoicingAuditLogPolicy` → `prime.invoicing-audit-log.*` |
| **Validation** | **None** on note update (base `Request`, no FormRequest, no `max:500`) — VAL-BIL-002 |
| **Migrations** | **0** (`database/migrations` empty — schema from consolidated DDL) |
| **CRUD type** | Read/report + single note-update write (append-only) |
| **Soft Delete** | Model declares SoftDeletes; **DDL table has no `deleted_at`** (MIG-BIL-001) |
| **Pagination** | 10/page (`buildAuditLogQuery()->paginate(10)`) |
| **Activity Log** | `sys_activity_logs`, event **`Store`**, `user_id = Auth::id()` (on note update) |

### Endpoints (routes prefix `billing`, name `billing.`, middleware `auth,verified`)

| Method | URI | Name | Gate |
|--------|-----|------|------|
| GET | `/billing/billing-management?type=audit-note` | `billing.billing-management.index` | `Gate::any([...,'prime.invoicing-audit-log.viewAny'])` |
| GET | `/billing/billing/audit-log?id=` | `billing.billing-management.audit.log` | `prime.billing-management.view` |
| GET | `/billing/audit/add-note?id=` | `billing.audit.add.note` | `prime.invoicing-audit-log.view` |
| POST | `/billing/audit/add-note/update` | `billing.audit.add.note.update` | `prime.invoicing-audit-log.update` |
| GET | `/billing/audit/event-info?id=` | `billing.audit.event.info` | `prime.invoicing-audit-log.view` |
| GET | `/billing/audit-note.download.pdf` | `billing.audit-note.download.pdf` | `prime.invoicing-audit-log.view` |

---

## 2. Business Conditions (detailed)

### Append-Only Invariant (BC-BIZ-01/02)
- Audit rows are inserted via `create()` only (in Invoicing/Payment/Email flows). The audit-log feature never edits `action_type`, `action_date`, `performed_by` or `event_info`.
- The **only** mutation is `auditAddNoteUpdate`: `$log->notes = $request->notes; $log->save();` then `activityLog($log, 'Store', ['message' => 'Audit Log Note Add'])`.
- Expected success JSON: `{ "status": true, "message": "Audit note updated successfully!" }`.

### Filter System (BC-BIZ-09..12)
| Param | Behaviour |
|-------|-----------|
| `date_range` | `whereBetween('action_date', [start, end])` |
| `tenat_id` (intentional typo) | `whereHas('invoice', fn => where('tenant_id', tenat_id))` |
| `performed_by` | `where('performed_by', id)` |
| `audit_status` | `where('action_type', value)` |
Default: `InvoicingAuditLog::with(['invoice','user'])` ordered `action_date DESC`, paginated 10.

### Defect flow diagrams

```
DATA-BIL-001 (P0)  — read path on a schema-correct DB (Billing_DDL_v1: column = tenant_invoicing_id)
  buildAuditLogQuery(): InvoicingAuditLog::with(['invoice'])   ── eager loads on tenant_invoice_id
  AuditLog(): where('tenant_invoice_id', $invoiceId)           ── filters on tenant_invoice_id
  downloadAuditNotePdf(): with(['invoice.tenant'])             ── eager loads on tenant_invoice_id
        │
        ▼   column tenant_invoice_id does NOT exist on the table
  SQLSTATE[42S22] Unknown column 'tenant_invoice_id'  →  audit tab / PDF / details 500

MIG-BIL-001 (P0)
  auditAddNoteUpdate(): $log->save()  →  writes updated_at  →  Unknown column 'updated_at'
  any withTrashed()/soft-delete       →  reads deleted_at  →  Unknown column 'deleted_at'

AUTH-BIL-002 (P2)
  Blade @canany(['audit.invoicing-audit-log.remakr','audit.invoicing-audit-log.viewAny'])
        │  (no Policy ability named audit.* exists)
        ▼
  Action column (Add Note / Event Info) NEVER renders for prime.* permission holders
```

### Error / message strings (verbatim)
- Note update success: `Audit note updated successfully!`
- Empty list state: `No records found.`
- Invalid id (any endpoint): HTTP 404 (`findOrFail`).

---

## 3. Test Cases (step-by-step)

### TC-P01 — Audit tab renders with filters
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as Super-Admin at `http://127.0.0.1:8000/login` | Dashboard |
| 2 | Visit `/billing/billing-management` and click `#invoicing-audit-tab` | `#invoicing-audit-pane` becomes visible |
| 3 | Inspect the pane | `input[name="date_range"]`, `select[name="performed_by"]`, `select[name="audit_status"]`, and a `table` are present |
| 4 | DB check | `SELECT COUNT(*) FROM bil_tenant_invoicing_audit_logs;` — value matches paginated count basis |

### TC-P08 — Add audit note (write path)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On an audit row, open the **Add Note** action (requires the `audit.*` blade key — see AUTH-BIL-002) | Add-note modal loads (`#auditLogId`, `#auditNoteText`, `#saveAuditNoteBtn`) |
| 2 | Enter `Reviewed by finance` and press Save (POST `/billing/audit/add-note/update` with `id`,`notes`) | JSON `{status:true, message:"Audit note updated successfully!"}` |
| 3 | DB check | `SELECT notes FROM bil_tenant_invoicing_audit_logs WHERE id = :id;` → `Reviewed by finance` |
| 4 | Activity-log check | `SELECT event,user_id FROM sys_activity_logs WHERE subject_type LIKE '%InvoicingAuditLog' ORDER BY id DESC LIMIT 1;` → `event = 'Store'`, `user_id = <admin id>` |
| 5 | **MIG-BIL-001 note** | On a DB built strictly from Billing_DDL_v1, step 2 raises `Unknown column 'updated_at'` (save writes updated_at that the table lacks) |

### TC-P09 — Download audit PDF
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | With `prime.invoicing-audit-log.view`, GET `/billing/audit-note.download.pdf` | 200 + `audit-note-report.pdf` download — OR 500 (DATA-BIL-001 broken relation) on a schema-correct DB |
| 2 | Without the gate | 403 |

### TC-N01 — Guest redirect
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Clear cookies; visit `/billing/billing-management?type=audit-note` | Redirect to `/login` |

### TC-N03/04/05 — Invalid id → 404
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET `/billing/audit/add-note?id=99999999` | 404 (`findOrFail`) |
| 2 | GET `/billing/audit/event-info?id=99999999` | 404 |
| 3 | POST `/billing/audit/add-note/update` `{id:99999999,notes:x}` | 404 |

### TC-N06 — Note has no validation (VAL-BIL-002)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `auditAddNoteUpdate(Request $request)` | Base Request; no FormRequest, no `max:500`, no `required`, no sanitization |
| 2 | POST a 600-char `notes` | Controller accepts it; DB truncates/errors at VARCHAR(500) boundary |

### TC-N07 — Blade permission-prefix mismatch (AUTH-BIL-002)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Grant a user only the documented `prime.invoicing-audit-log.*` set | Action column (`Add Note`/`Event Info`) does NOT render (blade requires `audit.invoicing-audit-log.remakr` / `.viewAny`) |
| 2 | Inspect Policy | No `audit.*` ability defined → the workflow is unreachable via UI |

### TC-D04 — Relation column mismatch (DATA-BIL-001)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On a DB built from Billing_DDL_v1 (column `tenant_invoicing_id`), load `?type=audit-note` | `buildAuditLogQuery` `with(['invoice'])` → `Unknown column 'tenant_invoice_id'` 500 |
| 2 | Schema probe | `SHOW COLUMNS FROM bil_tenant_invoicing_audit_logs LIKE 'tenant_invoice%';` reveals which name is live |

### TC-S03 — IDOR event-info
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | As a user without `.view`, GET `/billing/audit/event-info?id=<any>` | 403 (gate enforced regardless of ownership) |

### TC-A02 — Note WRITE gate present (SEC-BIL-010 remediation)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | As a user WITHOUT `prime.invoicing-audit-log.update`, POST note update | 403 |
| 2 | As a user WITH `.update` | 200 success |
