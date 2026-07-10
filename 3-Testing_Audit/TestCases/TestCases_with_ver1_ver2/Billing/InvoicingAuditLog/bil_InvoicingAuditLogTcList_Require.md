# Invoicing Audit Log — Test Case List & Business Conditions

- **Module:** Billing (BIL)
- **Feature / Screen:** Invoicing Audit Log (`audit-log.md`)
- **DB scope:** `prime_db` **central** (Super-Admin SaaS billing) — **NO tenant init**
- **Prefix:** `bil_` — primary table `bil_tenant_invoicing_audit_logs` (Billing_DDL_v1.sql line 82)
- **Style:** Browser Dusk, central chain (mirrors committed sibling `Prime/Billing/InvoicingAudit/prm_InvoicingAuditTab_TestCas.php`, base `BillingDuskTestCase`)
- **Screen type:** Append-only audit trail + single note-update write — **read/report-heavy**
- **Feature nature:** Rows are created via `create()` only; `notes` is the ONLY mutable column (via `auditAddNoteUpdate`)

---

## 1. Business Conditions

### BC-DB (columns / constraints — `bil_tenant_invoicing_audit_logs`, DDL line 82)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `id` INT UNSIGNED PK auto-increment | DDL-bil_tenant_invoicing_audit_logs |
| BC-DB-02 | `tenant_invoicing_id` INT UNSIGNED NOT NULL (DDL name); **model uses `tenant_invoice_id`** | DDL / DATA-BIL-001 |
| BC-DB-03 | `action_date` TIMESTAMP NOT NULL (no default — must be set explicitly) | DDL |
| BC-DB-04 | `action_type` VARCHAR(20) NOT NULL DEFAULT `'PENDING'` | DDL |
| BC-DB-05 | `performed_by` INT UNSIGNED NULL, FK → users ON DELETE SET NULL (null for queue events) | DDL / Screen-BR |
| BC-DB-06 | `event_info` JSON NULL (not array-cast in model) | DDL / Model |
| BC-DB-07 | `notes` VARCHAR(500) NULL (only mutable field) | DDL / Screen-BR |
| BC-DB-08 | `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP; **no `updated_at`, no `deleted_at`** | DDL / MIG-BIL-001 |

### BC-VAL (validation)

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `auditAddNoteUpdate` uses the base `Request` — **no FormRequest, no `max:500`, no sanitization** on `notes` | Controller:88 / VAL-BIL-002 |
| BC-VAL-02 | Missing/invalid `id` on any endpoint → `findOrFail` 404 | Controller:81,92,106 |

### BC-AUTH (permission gate ↔ method)

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab list `index()` (`type=audit-note`) requires `Gate::any([...,'prime.invoicing-audit-log.viewAny'])` or 403 | BM Controller:60 |
| BC-AUTH-02 | `auditAddNoteUpdate` (WRITE) gated on `prime.invoicing-audit-log.update` | Controller:90 / Audit-SEC-BIL-010 |
| BC-AUTH-03 | `auditAddNote` / `auditEventInfo` / `downloadAuditNotePdf` each gated on `prime.invoicing-audit-log.view` | Controller:80,105,118 |
| BC-AUTH-04 | AJAX `AuditLog()` gated on `prime.billing-management.view` | BM Controller:950 |
| BC-AUTH-05 | Policy maps `prime.invoicing-audit-log.{viewAny,view,create,update,delete,restore,forceDelete,print,pdf,remark}` | Policy |
| BC-AUTH-06 | **Blade action column gates on `audit.invoicing-audit-log.remakr` / `audit.invoicing-audit-log.viewAny` (prefix + typo) — no Policy ability backs these** | index.blade:142,165,173 / AUTH-BIL-002 |

### BC-BIZ (business logic / auto-behaviour)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | **Append-only:** entries created via `create()` only; never updated except `notes` | Screen-BR-1 |
| BC-BIZ-02 | Note update mutates ONLY `$log->notes`; returns `Audit note updated successfully!` | Controller:93-100 |
| BC-BIZ-03 | `performed_by` NULL for system/queue events (`SendInvoiceEmailJob`) | Screen-BR / Audit |
| BC-BIZ-04 | `event_info` should whitelist fields — current impl stores raw `$request->all()` in Invoicing/Payment write paths (not here) | Screen-BR / SEC-BIL-011 |
| BC-BIZ-05 | Audit tab paginates at 10/page | BM Controller:111 |
| BC-BIZ-06 | Default query eager loads `['invoice','user']` | BM Controller:345 |
| BC-BIZ-07 | Ordered `action_date DESC` (newest first) | BM Controller:368 |
| BC-BIZ-08 | AJAX `AuditLog()` ordered `created_at DESC` | BM Controller:954 |
| BC-BIZ-09 | Filter `date_range` → `whereBetween('action_date', …)` | BM Controller:348 |
| BC-BIZ-10 | Filter `tenat_id` (intentional typo) → `whereHas('invoice', tenant_id)` | BM Controller:353 |
| BC-BIZ-11 | Filter `performed_by` → `where('performed_by', …)` | BM Controller:361 |
| BC-BIZ-12 | Filter `audit_status` → `where('action_type', …)` | BM Controller:366 |
| BC-BIZ-13 | PDF `downloadAuditNotePdf` filters date_range/tenat_id/performed_by/audit_status → `audit-note-report.pdf` | Controller:116-148 |

### BC-SM (action_type taxonomy — NOT an enforced state machine)

| ID | Condition | Source |
|----|-----------|--------|
| BC-SM-01 | `action_type` is a free VARCHAR(20) event-type LABEL — **no transition validation exists**; any label may be written to any row | Screen / Controller (no guard) |
| BC-SM-02 | Live filter labels: `Not Billed`, `GENERATED`, `Overdue`, `Notice Sent`, `Partially Paid`, `Fully Paid` (drifts from DDL comment + requirement doc — documented) | index.blade:48-55 |

### BC-REF / BC-INT (FKs / relations)

| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | DDL FK `fk_audit_billing` → `bil_tenant_invoicing(id)` ON DELETE CASCADE — **references a non-existent table** (real: `bil_tenant_invoices`) | DDL:91 / DATA-BIL-003 |
| BC-REF-02 | DDL FK `fk_audit_user` → `users(id)` ON DELETE SET NULL — central user table is `sys_users` | DDL:92 / DATA-BIL-003 |
| BC-INT-01 | `invoice()` belongsTo `BilTenantInvoice` on `tenant_invoice_id`; `user()` belongsTo `Modules\Prime\Models\User` on `performed_by` | Model:34-43 |
| BC-INT-02 | Reverse `BilTenantInvoice::auditLogs()` hasMany on `tenant_invoice_id` (DATA-BIL-001 second site) | BilTenantInvoice:110 |

### BC-EDG / BC-AUTO

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `action_date` cast `datetime`; `event_info` NOT array-cast → `auditEventInfo` must `json_decode()` manually | Model:16 / Controller:109 |
| BC-EDG-02 | Null `event_info` → `json_decode(...) ?? []` (empty-metadata safe) | Controller:109 |
| BC-EDG-03 | Note >500 chars accepted by controller (no `max:500`) → DB truncation/error | VAL-BIL-002 |
| BC-AUTO-01 | Note update writes `activityLog($log, 'Store', ['message' => 'Audit Log Note Add'])` → `sys_activity_logs`, `event = 'Store'`, `user_id = Auth::id()` | Controller:95 / activityLog helper |

### Known Source Defects (carried + newly discovered)

| ID | Sev | Description | Status |
|----|-----|-------------|--------|
| **DATA-BIL-001** | P0 | Model `$fillable` + `invoice()` + `BilTenantInvoice::auditLogs()` + `AuditLog::where()` + `buildAuditLogQuery` `with(['invoice'])` + PDF `with(['invoice.tenant'])` all use `tenant_invoice_id`; consolidated Billing DDL column is `tenant_invoicing_id`. On a DB built from Billing_DDL_v1, every audit read via the relation/where targets a non-existent column → SQLSTATE 42S22. (The two DDL sources `prime_db_v4.sql`/`Billing_DDL_v1.sql` themselves disagree.) | Carried — proved (test 02/70) |
| **MIG-BIL-001** | P0 | Model uses `SoftDeletes` + default timestamps; DDL table has `created_at` only (no `updated_at`/`deleted_at`) → `save()`/soft-delete queries throw on a schema-correct DB | Carried — proved (test 01/02) |
| **SEC-BIL-010** | P1 | Note-edit WRITE `auditAddNoteUpdate` (and 3 read endpoints) previously had no gate; **now gated** (`.update` / `.view` present) | Carried — **remediation verified** (test 11/51/52) |
| **SEC-BIL-011** | P1 | Raw `$request->all()` persisted into `event_info` — **write path lives in Invoicing/Payment, not this controller**; this feature only READS `event_info` | Carried — write path elsewhere (test 95 asserts absence here) |
| **AUTH-BIL-002** | P2 | Blade action column + Add-Note/Event-Info links gate on `audit.invoicing-audit-log.remakr` / `audit.invoicing-audit-log.viewAny` (wrong prefix + typo), unbacked by any Policy ability → note-edit workflow unreachable via UI for `prime.*` holders | **NEW** (test 15/55) |
| **VAL-BIL-002** | P2 | `auditAddNoteUpdate` has no FormRequest / no `max:500` / no sanitization on `notes` (VARCHAR(500)) → oversize truncation + stored-XSS risk | **NEW** (test 16/30-32/91) |
| **DATA-BIL-003** | P3 | DDL FKs reference non-existent objects: `bil_tenant_invoicing` (real `bil_tenant_invoices`) and `users` (real `sys_users`) | **NEW** (test 43) |

---

## 2. Test Case List

### Positive (TC-P)

| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-P01 | Positive | BC-BIZ-06/07 | Screen | Audit tab renders in Billing Management with filters | Pane + date_range/performed_by/audit_status + table present | 06 | 60 | Ready |
| TC-P02 | Positive | BC-BIZ-05 | Screen | Table headers render | Organization/Invoice No/Audit Date/Entry Type/Performed By | 07 | 61 | Ready |
| TC-P03 | Positive | BC-BIZ-09 | Screen-IP | `date_range` → whereBetween action_date | Filter applied | 10 | 14 | Ready |
| TC-P04 | Positive | BC-BIZ-10 | Screen-IP | `tenat_id` typo key → whereHas invoice.tenant_id | Filter applied | 10 | 15 | Ready |
| TC-P05 | Positive | BC-BIZ-11 | Screen-IP | `performed_by` → where performed_by | Filter applied | 10 | 16 | Ready |
| TC-P06 | Positive | BC-BIZ-12 | Screen-IP | `audit_status` → where action_type | Filter applied | 10 | 17 | Ready |
| TC-P07 | Positive | BC-BIZ-05/07 | Screen | Query orders desc + eager loads + paginate(10) | Confirmed in source | 09 | 11-13 | Ready |
| TC-P08 | Positive | BC-AUTO-01 | Controller | Note update logs `Store` event + exact success message | activity + message | 11 | 19 | Ready |
| TC-P09 | Positive | BC-BIZ-13 | Screen | PDF endpoint returns pdf/gate | 200/403/500 (DATA-BIL-001) | — | 18/66 | Ready |
| TC-P10 | Positive | BC-BIZ-08 | Controller | AJAX AuditLog orders created_at DESC on model column | Confirmed | 13 | 44/45 | Ready |
| TC-P11 | Positive | BC-DB-07 | Blade | Add-Note form fields render (auditLogId/auditNoteText/save) | Present | — | 65 | Ready |
| TC-P12 | Positive | BC-SM-02 | Blade | Filter status options present | 6 labels | — | 21 | Ready |
| TC-P13 | Positive | BC-BIZ-05 | Blade | Pagination container present | links() rendered | — | 63 | Ready |
| TC-P14 | Positive | BC-EDG-02 | Controller | event_info null → decode to [] | No crash | — | 71 | Ready |

### Negative (TC-N)

| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-N01 | Negative | BC-AUTH-01 | Screen-PM | Guest visits tab → redirect `/login` | 302 → login | 14 | — | Ready |
| TC-N02 | Negative | BC-AUTH-02 | Audit | Guest note-update → not 200 (auth middleware) | 401/302/419/403 | — | 57/90 | Ready |
| TC-N03 | Negative | BC-VAL-02 | Controller | add-note invalid id → 404 | findOrFail 404 | — | 33 | Ready |
| TC-N04 | Negative | BC-VAL-02 | Controller | event-info invalid id → 404 | findOrFail 404 | — | 34 | Ready |
| TC-N05 | Negative | BC-VAL-02 | Controller | note-update invalid id → 404 | findOrFail 404 | — | 35 | Ready |
| TC-N06 | Negative | BC-VAL-01 | VAL-BIL-002 | No FormRequest / no max:500 / no required on notes | Rules absent in source | 16 | 30-32 | Ready |
| TC-N07 | Negative | BC-AUTH-06 | AUTH-BIL-002 | Blade gates on `audit.*` keys unbacked by Policy | Mismatch confirmed | 15 | 55 | Ready |

### Dependency (TC-D)

| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-D01 (B) | Dependency | BC-DB-08 | MIG-BIL-001 | SoftDeletes without deleted_at/updated_at | Columns absent; trait present | 01/03 | 02 | Ready |
| TC-D02 (C) | Dependency | BC-REF-01 | DATA-BIL-003 | Invoice FK CASCADE references wrong table | Real table exists; FK invalid (doc) | — | 43 | Ready |
| TC-D03 (D) | Dependency | BC-DB-05 | Screen-BR | performed_by nullable / SET NULL for queue events | Column nullable | — | 42 | Ready |
| TC-D04 (E) | Dependency | BC-INT-01/02 | DATA-BIL-001 | invoice()/auditLogs() relation column mismatch breaks eager read | QueryException on correct DB | 02/04 | 03/40/70 | Ready |
| TC-D05 (F) | Dependency | BC-BIZ-01/02 | Screen-BR | Append-only: only notes mutated; store() is a stub | Confirmed | — | 10/73 | Ready |
| TC-D06 (G) | Dependency | BC-EDG-03 | VAL-BIL-002 | Note >500 chars accepted (no bound) | Truncation risk | — | 72 | Ready |

### Security (TC-S)

| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-S01 | Security | BC-VAL-01 | VAL-BIL-002 | Stored XSS in notes not sanitized on write | Unsanitized (documented) | — | 91 | Ready |
| TC-S02 | Security | BC-DB-07 | Blade | Existing note rendered Blade-escaped in textarea | `{{ }}` escape | — | 92 | Ready |
| TC-S03 | Security | BC-AUTH-03 | Screen-PM | IDOR event-info direct id gated by `.view` | Gate enforced | — | 94 | Ready |
| TC-S04 | Security | BC-BIZ-04 | SEC-BIL-011 | Raw `$request->all()` NOT written into event_info here | Absent in this controller | — | 95 | Ready |
| TC-S05 | Security | BC-DB-01 | — | Mass-assignment guard (id/created_at not fillable) | Guarded | — | 93 | Ready |

### Authorization (TC-A)

| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-A01 | Auth | BC-AUTH-01 | BM Controller | index Gate::any includes audit viewAny | Present | — | 50 | Ready |
| TC-A02 | Auth | BC-AUTH-02 | Audit | Note WRITE gated `.update` (SEC-BIL-010 remediated) | Gate present | 11 | 51 | Ready |
| TC-A03 | Auth | BC-AUTH-03 | Controller | 3 read endpoints gated `.view` | 3 gates present | 12 | 52 | Ready |
| TC-A04 | Auth | BC-AUTH-04 | BM Controller | AJAX AuditLog gated billing-management.view | Present | 13 | 53 | Ready |
| TC-A05 | Auth | BC-AUTH-05 | Policy | Policy maps prime abilities | 7 abilities | — | 54 | Ready |
| TC-A06 | Auth | BC-BIZ-13 | Blade | Print/PDF buttons gated `.print`/`.pdf` | Present | — | 56 | Ready |

---

## 3. V2 Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `..._01_table_exists_with_ddl_columns` | TC-D01 | Schema | 01-09 |
| 2 | `..._02_mig_bil_001_no_updated_at_or_deleted_at` | TC-D01 | Schema/Defect | 01-09 |
| 3 | `..._03_data_bil_001_model_column_vs_ddl` | TC-D04 | Schema/Defect | 01-09 |
| 4 | `..._04_model_table_and_fillable` | TC-P07 | Model | 01-09 |
| 5 | `..._05_event_info_not_array_cast` | TC-P14 | Model/Edge | 01-09 |
| 6 | `..._06_action_date_cast_datetime` | BC-EDG-01 | Model | 01-09 |
| 7 | `..._07_action_type_default_pending_in_ddl` | BC-DB-04 | Schema | 01-09 |
| 8 | `..._08_activity_log_model_table` | BC-AUTO-01 | Model | 01-09 |
| 9 | `..._09_reverse_relation_column` | TC-D04 | Integration | 01-09 |
| 10 | `..._10_append_only_only_notes_mutated` | TC-D05 | Business | 10-19 |
| 11 | `..._11_query_eager_loads_invoice_and_user` | TC-P07 | Business | 10-19 |
| 12 | `..._12_query_orders_action_date_desc` | TC-P07 | Business | 10-19 |
| 13 | `..._13_tab_paginates_ten_per_page` | TC-P13 | Business | 10-19 |
| 14 | `..._14_date_range_filter` | TC-P03 | Business | 10-19 |
| 15 | `..._15_tenant_filter_uses_typo_key` | TC-P04 | Business | 10-19 |
| 16 | `..._16_performed_by_filter` | TC-P05 | Business | 10-19 |
| 17 | `..._17_audit_status_maps_to_action_type` | TC-P06 | Business | 10-19 |
| 18 | `..._18_pdf_filters_and_download_name` | TC-P09 | Business | 10-19 |
| 19 | `..._19_note_update_success_message_exact` | TC-P08 | Business | 10-19 |
| 20 | `..._20_action_type_labels_are_unguarded` | BC-SM-01 | State-taxonomy | 20-29 |
| 21 | `..._21_blade_status_options_present` | TC-P12 | State-taxonomy | 20-29 |
| 22 | `..._22_status_labels_fit_varchar_20` | BC-DB-04 | State-taxonomy | 20-29 |
| 23 | `..._30_note_update_no_form_request` | TC-N06 | Validation | 30-39 |
| 24 | `..._31_note_has_no_max_500_rule` | TC-N06 | Validation | 30-39 |
| 25 | `..._32_note_not_required_or_sanitized` | TC-N06 | Validation | 30-39 |
| 26 | `..._33_invalid_id_note_form_returns_404` | TC-N03 | Validation | 30-39 |
| 27 | `..._34_invalid_id_event_info_returns_404` | TC-N04 | Validation | 30-39 |
| 28 | `..._35_note_update_invalid_id_returns_404` | TC-N05 | Validation | 30-39 |
| 29 | `..._40_invoice_relation_source` | TC-D04 | Integration | 40-49 |
| 30 | `..._41_user_relation_is_central_user` | BC-INT-01 | Integration | 40-49 |
| 31 | `..._42_performed_by_nullable_for_queue_events` | TC-D03 | Integration | 40-49 |
| 32 | `..._43_invoice_fk_cascade_documented` | TC-D02 | Integration | 40-49 |
| 33 | `..._44_ajax_audit_log_filters_by_model_column` | TC-P10 | Integration | 40-49 |
| 34 | `..._45_ajax_audit_log_orders_created_at_desc` | TC-P10 | Integration | 40-49 |
| 35 | `..._50_index_gate_any_includes_audit_viewany` | TC-A01 | Auth | 50-59 |
| 36 | `..._51_note_update_gate_is_update` | TC-A02 | Auth | 50-59 |
| 37 | `..._52_read_endpoints_gate_on_view` | TC-A03 | Auth | 50-59 |
| 38 | `..._53_ajax_audit_log_gate` | TC-A04 | Auth | 50-59 |
| 39 | `..._54_policy_maps_prime_abilities` | TC-A05 | Auth | 50-59 |
| 40 | `..._55_auth_bil_002_blade_prefix_mismatch` | TC-N07 | Auth/Defect | 50-59 |
| 41 | `..._56_print_and_pdf_buttons_gated` | TC-A06 | Auth | 50-59 |
| 42 | `..._57_guest_note_update_rejected` | TC-N02 | Auth | 50-59 |
| 43 | `..._60_tab_pane_and_filters_render` | TC-P01 | UI | 60-69 |
| 44 | `..._61_table_headers` | TC-P02 | UI | 60-69 |
| 45 | `..._62_empty_state_or_rows` | TC-P01 | UI | 60-69 |
| 46 | `..._63_pagination_container_present` | TC-P13 | UI | 60-69 |
| 47 | `..._64_filter_submit_preserves_type` | TC-P01 | UI | 60-69 |
| 48 | `..._65_add_note_form_fields_exist_in_blade` | TC-P11 | UI | 60-69 |
| 49 | `..._66_download_pdf_endpoint_returns_pdf_or_gate` | TC-P09 | UI | 60-69 |
| 50 | `..._67_responsive_smoke_mobile` | TC-P01 | UI | 60-69 |
| 51 | `..._70_data_bil_001_breaks_relation_read` | TC-D04 | Edge/Defect | 70-79 |
| 52 | `..._71_event_info_null_decodes_to_empty` | TC-P14 | Edge | 70-79 |
| 53 | `..._72_note_over_500_chars_unbounded` | TC-D06 | Edge | 70-79 |
| 54 | `..._73_store_and_resource_methods_are_stubs` | TC-D05 | Edge | 70-79 |
| 55 | `..._74_routes_registered` | BC-BIZ | Edge | 70-79 |
| 56 | `..._90_note_update_requires_authentication` | TC-N02 | Security | 90-99 |
| 57 | `..._91_stored_xss_in_notes_not_sanitized_source` | TC-S01 | Security | 90-99 |
| 58 | `..._92_note_form_escapes_existing_notes` | TC-S02 | Security | 90-99 |
| 59 | `..._93_mass_assignment_guarded_by_fillable` | TC-S05 | Security | 90-99 |
| 60 | `..._94_idor_event_info_is_gated` | TC-S03 | Security | 90-99 |
| 61 | `..._95_sec_bil_011_event_info_write_path_not_here` | TC-S04 | Security | 90-99 |

**Counts:** V1 = 16 methods · V2 = 61 methods · Ratio = **3.8×** (gate ≥ 2× satisfied).
