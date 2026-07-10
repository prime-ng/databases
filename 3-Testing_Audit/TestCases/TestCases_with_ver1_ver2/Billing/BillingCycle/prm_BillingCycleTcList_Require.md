# Billing Cycle — Test Case List & Business Conditions (`prm_BillingCycleTcList_Require`)

- **Module:** Billing (central / prime_db SaaS admin)
- **Feature / Screen:** BillingCycle (`billing-cycles.md`)
- **Primary table:** `prm_billing_cycles` (prefix `prm_`, verified against `Billing_DDL_v1.sql` line 105)
- **DB scope:** `prime_db` central — **no tenancy scaffolding** (mirrors committed sibling `prm_BillingCycle_TestCas` → `BillingDuskTestCase` → `PrimeDuskTestCase`)
- **Controller:** `Modules\Billing\Http\Controllers\BillingCycleController`
- **FormRequest:** `Modules\Billing\Http\Requests\BillingCycleRequest`
- **Model:** `Modules\Billing\Models\BillingCycle` (SoftDeletes + HasFactory)
- **Policy:** `Modules\Billing\Policies\BillingCyclePolicy` (permissions `prime.billing-cycle.*`)
- **Test style:** browser Dusk (central `http://127.0.0.1:8000`)

---

## 1. Business Conditions

### BC-DB — Schema (Source: `DDL-prm_billing_cycles`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `id` SMALLINT UNSIGNED PK auto-increment | DDL-prm_billing_cycles |
| BC-DB-02 | `short_name` VARCHAR(50) NOT NULL, UNIQUE (`uq_billingCycles_code`) | DDL-prm_billing_cycles |
| BC-DB-03 | `name` VARCHAR(50) NOT NULL | DDL-prm_billing_cycles |
| BC-DB-04 | `months_count` TINYINT UNSIGNED NOT NULL (1–255) | DDL-prm_billing_cycles |
| BC-DB-05 | `description` VARCHAR(255) NULL | DDL-prm_billing_cycles |
| BC-DB-06 | `is_recurring` TINYINT(1) NOT NULL DEFAULT 1 | DDL-prm_billing_cycles |
| BC-DB-07 | `is_active` TINYINT(1) NOT NULL DEFAULT 1 | DDL-prm_billing_cycles |
| BC-DB-08 | Model uses `SoftDeletes` + default timestamps (`deleted_at`/`created_at`/`updated_at`) — **DDL has none → MIG-BIL-001 (P0)** | Model + Audit-MIG-BIL-001 |

### BC-VAL — Validation (Source: `BillingCycleRequest::rules()`)

| ID | Rule | Message behaviour | Source |
|----|------|-------------------|--------|
| BC-VAL-01 | `short_name` required, string, max:50, unique(ignore self) | validation alert `.alert.alert-danger`, stays on page | Screen-VR-1 / Request |
| BC-VAL-02 | `name` required, string, max:50 | validation alert | Screen-VR-2 / Request |
| BC-VAL-03 | `months_count` required, integer, min:1, max:255 | validation alert | Screen-VR-3 / Request |
| BC-VAL-04 | `description` nullable, string, max:255 | validation alert on overflow | Screen-VR-4 / Request |
| BC-VAL-05 | `is_active` required boolean (checkbox → bool via `prepareForValidation`) | coerced `'on'`→true | Request |
| BC-VAL-06 | `is_recurring` sometimes boolean (checkbox → bool) | coerced | Request |
| BC-VAL-07 | toggle-status endpoint: `is_active` required boolean | 422 when absent | Controller::toggleStatus |

### BC-AUTH — Permissions (Source: `Screen-PM` + Policy + `Gate::authorize`)

| ID | Operation | Permission | Source |
|----|-----------|------------|--------|
| BC-AUTH-01 | index (viewAny) | `prime.billing-cycle.viewAny` | Screen-PM-1 |
| BC-AUTH-02 | show (view) | `prime.billing-cycle.view` | Screen-PM-2 |
| BC-AUTH-03 | create/store | `prime.billing-cycle.create` | Screen-PM-3 |
| BC-AUTH-04 | edit/update + toggleStatus | `prime.billing-cycle.update` | Screen-PM-4 |
| BC-AUTH-05 | destroy + forceDelete | `prime.billing-cycle.delete` | Screen-PM-5 |
| BC-AUTH-06 | restore + trashed | `prime.billing-cycle.restore` | Screen-PM-6 |
| BC-AUTH-07 | Policy declares `forceDelete` → `prime.billing-cycle.forceDelete`, but controller `forceDelete()` gates on `.delete` — **DEV-BIL-201 (permission-key drift)** | Policy vs Controller |
| BC-AUTH-08 | Guest → redirect `/login` (`auth` + `verified` middleware) | Routes web.php |

### BC-BIZ — Business logic / activity log (Source: Controller + Screen-BR)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | store creates record + `activityLog($cycle,'Stored',...)` + redirect to `sales-plan-mgmt#billing` with `flash('created.billing_cycle')` → "Billing Cycle was created successfully." | Controller::store |
| BC-BIZ-02 | update persists + `activityLog(...,'Updated',...)` + `flash('updated.billing_cycle')` "…updated successfully." | Controller::update |
| BC-BIZ-03 | destroy sets `is_active=false` **then** soft-deletes + `activityLog(...,'Trashed',...)` + `flash('trashed.billing_cycle')` "…was moved to trash." | Controller::destroy / Screen-BR "Soft Delete" |
| BC-BIZ-04 | restore un-deletes + `activityLog(...,'Restored',...)` + `flash('restored.billing_cycle')` | Controller::restore |
| BC-BIZ-05 | forceDelete permanently removes + `activityLog(...,'Deleted',...)` + `flash('force_deleted.billing_cycle')`; FK violation caught → `flash('operation_failed.billing_cycle')` error | Controller::forceDelete |
| BC-BIZ-06 | toggleStatus AJAX returns JSON `{success:true, is_active:bool, message:"Billing Cycle status was successfully changed."}`; **writes no activity log** | Controller::toggleStatus |
| BC-BIZ-07 | `is_recurring` default checked (`old('is_recurring', true)`) on create form | create.blade |

> **Activity-log event strings (verbatim):** `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`. Written to `sys_activity_logs` (`Modules\GlobalMaster\Models\ActivityLog`, fillable subject_type/subject_id/user_id/event/properties/…). `toggleStatus` logs nothing.

### BC-SM — State machine: `is_active` (Source: Screen-BR "Status Toggle")

| ID | State | Trigger | Next State | Source |
|----|-------|---------|-----------|--------|
| BC-SM-01 | active | toggle switch / endpoint (`is_active=false`) | inactive | Screen-BR / Controller::toggleStatus |
| BC-SM-02 | inactive | toggle switch / endpoint (`is_active=true`) | active | Screen-BR / Controller::toggleStatus |
| BC-SM-03 | active | destroy | inactive + soft-deleted | Controller::destroy |

### BC-REF / BC-INT — FK dependency (Source: `DDL` + Screen "Cross-Module Reference")

| ID | Referencing table.column → `prm_billing_cycles.id` | onDelete | Source |
|----|-----------------------------------------------------|----------|--------|
| BC-REF-01 | `prm_plans.billing_cycle_id` | RESTRICT | DDL line 160 |
| BC-REF-02 | `prm_tenant_plan_rates.billing_cycle_id` | RESTRICT | DDL line 226 |
| BC-REF-03 | `prm_tenant_plan_billing_schedule.billing_cycle_id` | RESTRICT | DDL line 259 |
| BC-REF-04 | `bil_tenant_invoices.billing_cycle_id` | RESTRICT | DDL line 50 |
| BC-INT-01 | Model relations `tenantPlanRates`/`billingSchedules`/`invoices`/`plans` hasMany | Model |

### BC-EDG — Edge cases

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `months_count` boundary 1 accepted; 255 accepted; 0 and 256 rejected | DDL + Request |
| BC-EDG-02 | Soft-deleted `short_name` remains reserved (unique rule not scoped to `deleted_at`) | Request unique rule |
| BC-EDG-03 | XSS payload in `name` stored raw; Blade `{{ }}` escapes on render | index.blade |

### Known Source Defects (audit / discovered)

| ID | Severity | Description | Proving artifact |
|----|----------|-------------|------------------|
| **MIG-BIL-001** | P0 | Model declares SoftDeletes + timestamps; DDL `prm_billing_cycles` has no `deleted_at`/`created_at`/`updated_at` → CRUD breaks on a schema-correct DB | V1 `test_02`, V2 `test_05` (schema guards) |
| **DEV-BIL-201** | P3 | `forceDelete()` gates on `prime.billing-cycle.delete` while `BillingCyclePolicy::forceDelete` uses `prime.billing-cycle.forceDelete` (key drift) | Gap Analysis Cross-Ref #10 |
| **DEV-BIL-202** | P3 | store/update redirect to `central.prime.sales-plan-mgmt.index#billing` (not the billing-cycle index) — success not shown on this screen | Manual TC (documented) |

---

## 2. Test Case List

### Positive

| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-P01 | Config | BC-DB-01..08 | DDL | Schema/columns/unique index + model config | table+cols+unique+SoftDeletes+relations present | `test_01` | `test_01`,`test_02` | Automated |
| TC-P02 | Config | BC-DB-08 | Model | SoftDeletes column guard (MIG-BIL-001) | `deleted_at` present or fail | `test_02` | `test_05` | Automated |
| TC-P03 | Render | BC-AUTH-01 | Screen | Index loads, lists table | "Billing Cycles" + table | `test_03` | `test_60` | Automated |
| TC-P04 | Render | BC-AUTH-03 | Screen | Create page loads with fields | form fields present | `test_04` | `test_62` | Automated |
| TC-P05 | CRUD | BC-BIZ-01 | Controller | Create persists all fields | row created, values match | `test_10` | `test_10` | Automated |
| TC-P06 | CRUD | BC-BIZ-02 | Controller | Update persists all fields | row updated | `test_11` | `test_11` | Automated |
| TC-P07 | CRUD | BC-SM-03 | Controller | Soft delete deactivates + trashes | `deleted_at` set, `is_active`=0 | `test_40` | `test_12` | Automated |
| TC-P08 | Log | BC-BIZ-01 | Controller | Store writes "Stored" activity log | log row exists | — | `test_13` | Automated (defensive) |
| TC-P09 | CRUD | BC-VAL-01 | Request | Update keeps same short_name (ignore-self) | update succeeds | — | `test_39` | Automated |
| TC-P10 | UI | Screen | index columns present | headers rendered | — | `test_60` | Automated |
| TC-P11 | UI | Screen | Created record listed | short_name visible | — | `test_61` | Automated |
| TC-P12 | UI | create.blade | Breadcrumb on create | breadcrumb text present | — | `test_62` | Automated |

### State Machine

| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-SM01 | SM | BC-SM-01 | Screen-BR | Toggle active→inactive (switch) | `is_active`=0 | `test_20` | `test_20` | Automated |
| TC-SM02 | SM | BC-SM-02 | Screen-BR | Toggle inactive→active (switch) | `is_active`=1 | — | `test_21` | Automated |
| TC-SM03 | SM/API | BC-BIZ-06 | Controller | toggle-status JSON contract | 200 `{success,is_active}` | — | `test_22` | Automated (defensive) |

### Negative

| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-N01 | Val | BC-VAL-01 | Request | short_name required | alert, stays | `test_30` | `test_30` | Automated |
| TC-N02 | Val | BC-VAL-02 | Request | name required | alert, stays | — | `test_31` | Automated |
| TC-N03 | Val | BC-VAL-03 | Request | months_count required | alert, stays | — | `test_32` | Automated |
| TC-N04 | Val | BC-VAL-01 | Request | duplicate short_name rejected | alert, count stays 1 | `test_31` | `test_33` | Automated |
| TC-N05 | Val | BC-VAL-03 | Request | months_count = 0 (min) rejected | alert, no row | `test_32` | `test_34` | Automated |
| TC-N06 | Val | BC-VAL-03 | Request | months_count = 256 (max) rejected | alert, no row | — | `test_35` | Automated |
| TC-N07 | Val | BC-VAL-01 | Request | short_name > 50 chars rejected | alert | — | `test_36` | Automated |
| TC-N08 | Val | BC-VAL-02 | Request | name > 50 chars rejected | alert | — | `test_37` | Automated |
| TC-N09 | Val | BC-VAL-04 | Request | description > 255 chars rejected | alert | — | `test_38` | Automated |
| TC-N10 | Auth | BC-AUTH-08 | Routes | Guest → /login (index) | redirect | `test_50` | `test_50` | Automated |
| TC-N11 | Auth | BC-AUTH-08 | Routes | Guest → /login (create) | redirect | — | `test_51` | Automated |
| TC-N12 | Auth | BC-AUTH-01 | Policy | Non super-admin forbidden | 403/redirect | — | `test_52` | Automated (defensive) |
| TC-N13 | Val/API | BC-VAL-07 | Controller | toggle-status missing is_active → 422 | 422 | — | `test_23` | Automated (defensive) |

### Dependency

| TC ID | Sub | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-D01 | F | BC-SM/BC-BIZ | Controller | Full lifecycle create→toggle→delete→restore→force | ends removed | `test_40` | `test_40` | Automated |
| TC-D02 | C | BC-REF-01..04 | DDL | FK RESTRICT referencing prm_billing_cycles | ≥1 RESTRICT FK | — | `test_41` | Automated |
| TC-D03 | E | BC-INT-01 | DDL | Cross-module reference tables carry `billing_cycle_id` | columns present | — | `test_42` | Automated (defensive) |
| TC-D04 | B | BC-EDG-02 | Request | Soft-deleted short_name stays reserved | duplicate blocked | — | `test_72` | Automated |
| TC-D05 | G | BC-EDG-01 | DDL | months_count boundaries 1 & 255 accepted | rows persist | — | `test_70`,`test_71` | Automated |

### Security

| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-S01 | XSS | BC-EDG-03 | index.blade | XSS in name escaped on render | no raw `<script>` in DOM | — | `test_90` | Automated |
| TC-S02 | IDOR | BC-AUTH-08 | Routes | Direct edit URL requires auth | redirect /login | — | `test_91` | Automated |

---

## 3. V2 Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_billing_cycle_01_schema_columns_and_unique_index_exist | TC-P01 | Config | 01-09 |
| 2 | test_billing_cycle_02_model_fillable_casts_softdeletes_and_relationships | TC-P01 | Config | 01-09 |
| 3 | test_billing_cycle_03_routes_are_registered_with_expected_names | TC-P01/BC-AUTH | Config | 01-09 |
| 4 | test_billing_cycle_05_softdeletes_column_present_mig_bil_001_guard | TC-P02 / MIG-BIL-001 | Config | 01-09 |
| 5 | test_billing_cycle_10_create_persists_all_fields | TC-P05 | Business | 10-19 |
| 6 | test_billing_cycle_11_update_persists_all_fields | TC-P06 | Business | 10-19 |
| 7 | test_billing_cycle_12_soft_delete_deactivates_before_deleting | TC-P07 | Business | 10-19 |
| 8 | test_billing_cycle_13_store_writes_stored_activity_log | TC-P08 | Business | 10-19 |
| 9 | test_billing_cycle_20_status_switch_active_to_inactive | TC-SM01 | State machine | 20-29 |
| 10 | test_billing_cycle_21_status_switch_inactive_to_active | TC-SM02 | State machine | 20-29 |
| 11 | test_billing_cycle_22_toggle_status_endpoint_json_contract | TC-SM03 | State machine/API | 20-29 |
| 12 | test_billing_cycle_23_toggle_status_requires_is_active | TC-N13 | Validation/API | 20-29 |
| 13 | test_billing_cycle_30_short_name_required | TC-N01 | Validation | 30-39 |
| 14 | test_billing_cycle_31_name_required | TC-N02 | Validation | 30-39 |
| 15 | test_billing_cycle_32_months_count_required | TC-N03 | Validation | 30-39 |
| 16 | test_billing_cycle_33_duplicate_short_name_rejected | TC-N04 | Validation | 30-39 |
| 17 | test_billing_cycle_34_months_count_zero_rejected | TC-N05 | Validation | 30-39 |
| 18 | test_billing_cycle_35_months_count_above_255_rejected | TC-N06 | Validation | 30-39 |
| 19 | test_billing_cycle_36_short_name_over_50_rejected | TC-N07 | Validation | 30-39 |
| 20 | test_billing_cycle_37_name_over_50_rejected | TC-N08 | Validation | 30-39 |
| 21 | test_billing_cycle_38_description_over_255_rejected | TC-N09 | Validation | 30-39 |
| 22 | test_billing_cycle_39_update_keeps_same_short_name_on_self | TC-P09 | Validation | 30-39 |
| 23 | test_billing_cycle_40_full_lifecycle_flow | TC-D01 | Dependency | 40-49 |
| 24 | test_billing_cycle_41_referencing_fk_uses_restrict | TC-D02 | Dependency | 40-49 |
| 25 | test_billing_cycle_42_cross_module_reference_tables_exist | TC-D03 | Dependency | 40-49 |
| 26 | test_billing_cycle_50_guest_redirected_to_login | TC-N10 | Permissions | 50-59 |
| 27 | test_billing_cycle_51_guest_redirected_from_create | TC-N11 | Permissions | 50-59 |
| 28 | test_billing_cycle_52_non_super_admin_forbidden | TC-N12 | Permissions | 50-59 |
| 29 | test_billing_cycle_60_index_columns_present | TC-P10 | UI/UX | 60-69 |
| 30 | test_billing_cycle_61_index_lists_created_record | TC-P11 | UI/UX | 60-69 |
| 31 | test_billing_cycle_62_breadcrumb_present_on_create | TC-P12 | UI/UX | 60-69 |
| 32 | test_billing_cycle_70_months_count_boundary_one_accepted | TC-D05 | Edge | 70-79 |
| 33 | test_billing_cycle_71_months_count_boundary_255_accepted | TC-D05 | Edge | 70-79 |
| 34 | test_billing_cycle_72_soft_deleted_short_name_still_reserved | TC-D04 | Edge | 70-79 |
| 35 | test_billing_cycle_90_xss_in_name_is_escaped_on_index | TC-S01 | Security | 90-99 |
| 36 | test_billing_cycle_91_direct_edit_url_requires_auth | TC-S02 | Security | 90-99 |

**Counts:** V1 = 13 methods · V2 = 36 methods · V2 ≥ 2×V1 (26) ✅
