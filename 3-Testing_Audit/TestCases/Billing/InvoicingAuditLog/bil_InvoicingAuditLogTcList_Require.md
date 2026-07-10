# Invoice Audit Log — Test Case List & Business Conditions (`bil_InvoicingAuditLog`)

- **Module:** Billing (BIL) — **DB scope: PRIME / CENTRAL** (`prime_db`, central domain `127.0.0.1:8000`)
- **Feature / screen:** InvoicingAuditLog (`Billing_v1/audit-log.md`)
- **Primary table:** `bil_tenant_invoicing_audit_logs` (prefix `bil_`, verified against `Billing_DDL_v1.sql` line 82 `CREATE TABLE`)
- **Controllers:** `InvoicingAuditLogController` (note add/edit, event-info, PDF) + `BillingManagementController::AuditLog` / `buildAuditLogQuery`
- **Model:** `Modules\Billing\Models\InvoicingAuditLog` (uses `Modules\Prime\Models\User`)
- **Policy:** `InvoicingAuditLogPolicy` (`prime.invoicing-audit-log.*`)
- **Test style:** browser Dusk, `extends BillingDuskTestCase` (central), + deterministic source/DDL/model truth asserts
- **Test file:** `bil_InvoicingAuditLog_TestCas.php` (single comprehensive suite — 42 methods)

> **Why source-truth-heavy:** the audit table is P0-broken against a schema-correct `prime_db` (DATA-BIL-001 + MIG-BIL-001), so audit rows cannot be reliably inserted to drive the UI. Behaviour is proven via schema/DDL/model/source assertions plus browser render + permission checks. This is honest proving, not padding.

---

## 1. Business Conditions

### BC-DB — Schema (Source: `DDL-bil_tenant_invoicing_audit_logs`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `id` INT UNSIGNED PK auto-increment | DDL |
| BC-DB-02 | `tenant_invoicing_id` INT UNSIGNED NOT NULL — FK → `bil_tenant_invoicing(id)` **ON DELETE CASCADE** | DDL |
| BC-DB-03 | `action_date` TIMESTAMP NOT NULL (no default; explicitly set) | DDL |
| BC-DB-04 | `action_type` VARCHAR(20) NOT NULL DEFAULT `'PENDING'` | DDL |
| BC-DB-05 | `performed_by` INT UNSIGNED DEFAULT NULL — FK → `users(id)` **ON DELETE SET NULL** | DDL |
| BC-DB-06 | `event_info` JSON DEFAULT NULL | DDL |
| BC-DB-07 | `notes` VARCHAR(500) DEFAULT NULL | DDL |
| BC-DB-08 | `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP; **no `updated_at`, no `deleted_at`, no `is_active`, no `created_by`** | DDL |

### BC-VAL — Validation (Source: Controller / DDL — no FormRequest exists)

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `auditAddNote(id)` → 404 when id missing/invalid (`findOrFail`) | Controller:81 |
| BC-VAL-02 | `auditAddNoteUpdate(id)` → 404 when id invalid (`findOrFail`) | Controller:92 |
| BC-VAL-03 | `auditEventInfo(id)` → 404 when id invalid (`findOrFail`) | Controller:106 |
| BC-VAL-04 | `notes` bounded to 500 chars | DDL / Screen-BR |
| BC-VAL-05 | `action_type` bounded to 20 chars | DDL |
| BC-VAL-06 | `notes` rendered escaped (Blade `{{ }}`) — stored-XSS mitigated | View |

### BC-AUTH — Authorization (Source: Policy + Controller + blade; `Screen-PM`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab render gated `prime.invoicing-audit-log.viewAny` | index.blade:47 |
| BC-AUTH-02 | Add-note read gated `prime.invoicing-audit-log.view` | Controller:80 |
| BC-AUTH-03 | Add-note **write** gated `prime.invoicing-audit-log.update` (currently present) | Controller:90 |
| BC-AUTH-04 | Event-info gated `prime.invoicing-audit-log.view` | Controller:105 |
| BC-AUTH-05 | PDF gated `prime.invoicing-audit-log.view`; print/pdf buttons `prime.invoicing-audit-log.print`/`.pdf` | Controller:118 / view:102,114 |
| BC-AUTH-06 | **DEFECT** — action buttons gate on `audit.invoicing-audit-log.remakr`/`.viewAny` (never match backend `prime.*`) | index.blade:142,165,173 |
| BC-AUTH-07 | **DEFECT** — `AuditLog` read route gated `prime.billing-management.view`, not the audit permission | BillingMgmt:792 |
| BC-AUTH-08 | Guest → redirect `/login` | middleware `auth,verified` |

### BC-BIZ — Business logic (Source: Controller / Screen-BR)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Append-only: entries created via `create()`; only `notes` mutable via `auditAddNoteUpdate` | Screen-BR / Controller |
| BC-BIZ-02 | Note update writes activity `activityLog($log, 'Store', ['message'=>'Audit Log Note Add'])` (event string **`Store`**, verbatim) | Controller:95 |
| BC-BIZ-03 | Audit-log read ordered newest-first (`created_at DESC`); report query `action_date DESC` | BillingMgmt:796 / :375 |
| BC-BIZ-04 | Filters: `date_range` (BETWEEN action_date), `tenat_id` (whereHas invoice; **param typo**), `performed_by`, `audit_status` (=action_type) | BillingMgmt:349 |
| BC-BIZ-05 | Default query eager-loads `['invoice','user']` | BillingMgmt:351 |
| BC-BIZ-06 | `performed_by` = `auth()->id() ?? null` for system/queue events | Controller/BillingMgmt |
| BC-BIZ-07 | **DEFECT** — action_type mislabels emitted by non-audit methods (`'PDF Downloaded'`,`'Email Scheduled'`,`'Remark Updated'`) | BillingMgmt |

### BC-INT / BC-REF — Integration & FK

| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `tenant_invoicing_id` → `bil_tenant_invoicing(id)` CASCADE | DDL |
| BC-REF-02 | `performed_by` → `users(id)` SET NULL | DDL |
| BC-INT-01 | Model `invoice()` → `BilTenantInvoice` on `tenant_invoice_id`; `user()` → `Prime\User` on `performed_by` | Model |

### BC-EDG — Edge cases

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `PAYMENT_UPDATED` (15) fits VARCHAR(20); longer literals truncate/throw | DDL |
| BC-EDG-02 | `performed_by` NULL for queued jobs; requirement flags `Auth::id()` null-in-queue risk | Screen-BR |

### BC-SM / BC-CFG
Not applicable — audit trail is append-only (no status workflow) and has no config table.

### Known Source Defects (audit-equivalent — proving tests attached)

| ID | Sev | Description | Proving test |
|----|-----|-------------|--------------|
| DEV-BIL-A01 (DATA-BIL-001) | P0 | Model/insert FK column `tenant_invoice_id` ≠ DDL column `tenant_invoicing_id` → every insert fails on a correct DB | `test_03` |
| DEV-BIL-A02 (MIG-BIL-001) | P0 | `SoftDeletes` + default timestamps, but DDL has no `deleted_at`/`updated_at` → CRUD throws | `test_04` |
| DEV-BIL-A03 (SEC-BIL-011/BR-BIL-022) | P1 | `event_info` over-persists raw request keys (`remarks`, `gateway_resp`, `payment_reconciled`) beyond documented whitelist (literal `$request->all()` remediated) | `test_91` |
| DEV-BIL-A04 | P2 | Blade action buttons gate `audit.invoicing-audit-log.*` — never match backend `prime.*`; note-edit UI silently hidden | `test_52` |
| DEV-BIL-A05 | P3 | Audit-log read route gated `prime.billing-management.view`, not the audit permission | `test_53` |
| DEV-BIL-A06 | P3 | `event_info` not array-cast in model despite requirement | `test_05` |
| DEV-BIL-A07 | P3 | action_type mislabels from non-audit methods | `test_14` |

---

## 2. Test Case List

### Positive (`TC-P`)

| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-P01 | Config | BC-DB-* | DDL | Model table/fillable/casts correct | Match source | `test_01` | Auto |
| TC-P02 | Config | BC-DB-* | DDL | DDL declares audit columns + FKs | Present | `test_02` | Auto |
| TC-P03 | Schema | BC-DB-* | DB | Live schema column present when reachable | Present/skip | `test_07` | Auto |
| TC-P04 | Biz | BC-BIZ-01 | Screen-BR | Note update mutates only notes | Confirmed | `test_10` | Auto |
| TC-P05 | Biz | BC-BIZ-02 | Controller | Activity `Store` logged on note update | Verbatim | `test_11` | Auto |
| TC-P06 | Biz | BC-BIZ-03 | Controller | Read/report ordered DESC | Confirmed | `test_12` | Auto |
| TC-P07 | Biz | BC-BIZ-01 | Controller | Rows appended via create() | ≥2 sites | `test_13` | Auto |
| TC-P08 | Ref | BC-REF-01 | DDL | Invoice FK CASCADE | Present | `test_40` | Auto |
| TC-P09 | Ref | BC-REF-02 | DDL | performed_by FK SET NULL | Present | `test_41` | Auto |
| TC-P10 | Int | BC-INT-01 | Model | invoice()/user() relations correct | Confirmed | `test_42`,`test_43` | Auto |
| TC-P11 | UI | BC-BIZ-04 | View | Tab loads with all filters | Present | `test_60` | Auto |
| TC-P12 | UI | BC-AUTH-05 | View | Export/print controls for admin | Present | `test_61` | Auto |
| TC-P13 | UI | BC-BIZ-04 | View | audit_status dropdown values | Listed | `test_62` | Auto |
| TC-P14 | UI | — | View | Pagination rendered | Present | `test_64` | Auto |
| TC-P15 | UI | BC-AUTH-01 | Route | Billing Mgmt page reachable | 200 | `test_65` | Auto |
| TC-P16 | Edge | BC-BIZ-06 | Controller | performed_by nullable | Confirmed | `test_71`,`test_72` | Auto |

### Negative (`TC-N`)

| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-N01 | Val | BC-VAL-01 | Controller | add-note invalid id | 404 (findOrFail) | `test_30` | Auto |
| TC-N02 | Val | BC-VAL-02 | Controller | add-note-update invalid id | 404 | `test_31` | Auto |
| TC-N03 | Val | BC-VAL-03 | Controller | event-info invalid id | 404 | `test_32` | Auto |
| TC-N04 | Val | BC-VAL-04 | DDL | notes > 500 chars | Bounded | `test_33` | Auto |
| TC-N05 | Val | BC-VAL-05 | DDL | action_type > 20 chars | Bounded | `test_70` | Auto |
| TC-N06 | Auth | BC-AUTH-08 | Middleware | Guest access | Redirect `/login` | `test_34` | Auto |
| TC-N07 | Sec | BC-VAL-06 | View | Stored XSS in notes | Escaped | `test_35` | Auto |
| TC-N08 | Sec | BC-VAL-06 | View | Stored XSS in event_info | Escaped | `test_92` | Auto |
| TC-N09 | Sec | — | Controller | IDOR on audit id | 404 not leak | `test_93` | Auto |

### Dependency / Auth / Security / Tenancy (`TC-D`/`TC-S`/`TC-T`)

| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 (C) | FK | BC-REF-01 | DDL | Invoice delete cascades audit | CASCADE | `test_40` | Auto |
| TC-D02 (D) | FK | BC-REF-02 | DDL | User delete nulls performed_by | SET NULL | `test_41` | Auto |
| TC-S01 | Auth | BC-AUTH-01 | Policy | Policy prime.* namespace | Confirmed | `test_50` | Auto |
| TC-S02 | Auth | BC-AUTH-03 | Controller | Note-write gated | Present | `test_51` | Auto |
| TC-S03 | Auth | BC-AUTH-06 | Blade | **DEV-BIL-A04** key mismatch | Proven | `test_52` | Auto |
| TC-S04 | Auth | BC-AUTH-07 | Controller | **DEV-BIL-A05** wrong perm on read | Proven | `test_53` | Auto |
| TC-S05 | Auth | BC-AUTH-01 | Browser | Admin sees tab (viewAny) | Visible | `test_54` | Auto |
| TC-S06 | Route | BC-AUTH-* | Route | Audit routes registered | Registered | `test_55` | Auto |
| TC-T01 | Tenancy | A4 | Base | Central/prime scope (127.0.0.1) | Confirmed | `test_90` | Auto |
| TC-DEV01 | Defect | DEV-BIL-A01 | DDL/Model | FK column mismatch | Proven | `test_03` | Auto |
| TC-DEV02 | Defect | DEV-BIL-A02 | DDL/Model | SoftDeletes w/o columns | Proven | `test_04` | Auto |
| TC-DEV03 | Defect | DEV-BIL-A06 | Model | event_info not array-cast | Proven | `test_05` | Auto |
| TC-DEV04 | Defect | DEV-BIL-A03 | Controller | event_info over-persist | Proven | `test_91` | Auto |
| TC-DEV05 | Defect | DEV-BIL-A07 | Controller | action_type mislabels | Proven | `test_14` | Auto |
| TC-D03 (F) | Edge | BC-EDG-02 | Job | Queue performed_by gap | Documented | `test_73` | Auto |
| TC-P17 | Config | BC-DB-08 | DDL | Missing audit-columns absent | Confirmed | `test_06` | Auto |

---

## 3. Test Method Index (bands per WP-G)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_..._01_model_configuration_is_correct` | TC-P01 | Config | 01–09 |
| 2 | `test_..._02_ddl_defines_audit_columns_and_foreign_keys` | TC-P02 | Config | 01–09 |
| 3 | `test_..._03_model_fk_column_mismatches_ddl_proves_DATA_BIL_001` | TC-DEV01 | Defect | 01–09 |
| 4 | `test_..._04_softdeletes_without_columns_proves_MIG_BIL_001` | TC-DEV02 | Defect | 01–09 |
| 5 | `test_..._05_event_info_is_not_array_cast_in_model` | TC-DEV03 | Defect | 01–09 |
| 6 | `test_..._06_ddl_lacks_is_active_created_by_deleted_at_updated_at` | TC-P17 | Config | 01–09 |
| 7 | `test_..._07_live_schema_columns_when_reachable` | TC-P03 | Config | 01–09 |
| 8 | `test_..._10_note_update_endpoint_mutates_only_notes` | TC-P04 | Biz | 10–19 |
| 9 | `test_..._11_note_update_writes_store_activity_log` | TC-P05 | Biz | 10–19 |
| 10 | `test_..._12_audit_log_read_orders_desc` | TC-P06 | Biz | 10–19 |
| 11 | `test_..._13_audit_rows_are_created_never_bulk_updated` | TC-P07 | Biz | 10–19 |
| 12 | `test_..._14_action_type_mislabels_are_documented` | TC-DEV05 | Defect | 10–19 |
| 13 | `test_..._30_add_note_uses_findorfail_for_missing_id` | TC-N01 | Val | 30–39 |
| 14 | `test_..._31_add_note_update_uses_findorfail` | TC-N02 | Val | 30–39 |
| 15 | `test_..._32_event_info_uses_findorfail` | TC-N03 | Val | 30–39 |
| 16 | `test_..._33_notes_max_length_500_declared_in_ddl` | TC-N04 | Val | 30–39 |
| 17 | `test_..._34_guest_is_redirected_to_login` | TC-N06 | Auth | 30–39 |
| 18 | `test_..._35_notes_are_html_escaped_in_views` | TC-N07 | Sec | 30–39 |
| 19 | `test_..._40_invoice_fk_is_cascade_on_delete` | TC-D01 | FK | 40–49 |
| 20 | `test_..._41_performed_by_fk_is_set_null` | TC-D02 | FK | 40–49 |
| 21 | `test_..._42_invoice_relationship_targets_invoice_model` | TC-P10 | Int | 40–49 |
| 22 | `test_..._43_user_relationship_uses_prime_user_model` | TC-P10 | Int | 40–49 |
| 23 | `test_..._50_policy_uses_prime_permission_namespace` | TC-S01 | Auth | 50–59 |
| 24 | `test_..._51_note_update_write_is_gated` | TC-S02 | Auth | 50–59 |
| 25 | `test_..._52_blade_action_gates_never_match_backend_keys` | TC-S03 | Defect | 50–59 |
| 26 | `test_..._53_audit_read_route_uses_billing_management_permission` | TC-S04 | Defect | 50–59 |
| 27 | `test_..._54_audit_tab_requires_viewany_to_render` | TC-S05 | Auth | 50–59 |
| 28 | `test_..._55_audit_routes_are_registered` | TC-S06 | Route | 50–59 |
| 29 | `test_..._60_audit_tab_loads_with_filters` | TC-P11 | UI | 60–69 |
| 30 | `test_..._61_export_and_print_controls_present_for_admin` | TC-P12 | UI | 60–69 |
| 31 | `test_..._62_audit_status_dropdown_lists_expected_values` | TC-P13 | UI | 60–69 |
| 32 | `test_..._63_empty_state_message_is_defined` | TC-P11 | UI | 60–69 |
| 33 | `test_..._64_pagination_is_rendered` | TC-P14 | UI | 60–69 |
| 34 | `test_..._65_billing_management_page_is_reachable` | TC-P15 | UI | 60–69 |
| 35 | `test_..._70_action_type_is_varchar20_boundary` | TC-N05 | Edge | 70–79 |
| 36 | `test_..._71_performed_by_is_nullable_for_system_events` | TC-P16 | Edge | 70–79 |
| 37 | `test_..._72_insert_sites_default_performed_by_to_null` | TC-P16 | Edge | 70–79 |
| 38 | `test_..._73_queue_job_performed_by_gap_is_documented` | TC-D03 | Edge | 70–79 |
| 39 | `test_..._90_feature_is_central_prime_scoped` | TC-T01 | Tenancy | 90–99 |
| 40 | `test_..._91_event_info_over_persists_beyond_whitelist_proves_SEC_BIL_011` | TC-DEV04 | Defect | 90–99 |
| 41 | `test_..._92_event_info_view_escapes_values` | TC-N08 | Sec | 90–99 |
| 42 | `test_..._93_add_note_rejects_unknown_id_as_idor_guard` | TC-N09 | Sec | 90–99 |
