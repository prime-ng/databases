# Billing Cycle — Test Case List & Business Conditions (`prm_BillingCycleTcList_Require.md`)

- **Module:** Billing (code `BIL`)
- **Feature / Screen:** BillingCycle (`billing-cycles.md`)
- **Primary table:** `prm_billing_cycles` (prefix **`prm_`**, verified at `Billing_DDL_v1.sql:105`)
- **DB scope:** PRIME / CENTRAL (`prime_db`) — NOT tenant. Runs on `http://127.0.0.1:8000`.
- **Controller:** `Modules\Billing\Http\Controllers\BillingCycleController`
- **Request:** `Modules\Billing\Http\Requests\BillingCycleRequest`
- **Model:** `Modules\Billing\Models\BillingCycle` (`SoftDeletes`, `HasFactory`)
- **Policy:** `Modules\Billing\Policies\BillingCyclePolicy`
- **Test file:** `prm_BillingCycle_TestCas.php` (single comprehensive suite, 53 methods)
- **Activity-log events (verbatim from source):** `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`

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
| BC-DB-08 | **DDL has NO `deleted_at`/`created_at`/`updated_at`** — model declares SoftDeletes+timestamps → **MIG-BIL-001** | Audit-MIG-BIL-001 |

### BC-VAL — Validation (Source: `BillingCycleRequest`)

| ID | Rule | Default message fragment | Source |
|----|------|--------------------------|--------|
| BC-VAL-01 | `short_name` required\|string\|max:50 | "The short name field is required." | Screen-VR-1 |
| BC-VAL-02 | `short_name` unique on `prm_billing_cycles`, ignore self on update | "The short name has already been taken." | Screen-BR (Unique Short Name) |
| BC-VAL-03 | `name` required\|string\|max:50 | "The name field is required." | Screen-VR-2 |
| BC-VAL-04 | `months_count` required\|integer\|min:1\|max:255 | "The months count field is required." | Screen-VR-3 |
| BC-VAL-05 | `description` nullable\|string\|max:255 | max 255 characters | Screen-VR-4 |
| BC-VAL-06 | `is_active` required\|boolean (checkbox `on`→bool via `prepareForValidation`) | — | Screen-VR-5 |
| BC-VAL-07 | `is_recurring` sometimes\|boolean (checkbox `on`→bool) | — | Screen-VR-6 |

### BC-AUTH — Permissions (Source: `BillingCyclePolicy` + controller `Gate::authorize`)

| ID | Operation | Permission key | Controller gate | Source |
|----|-----------|----------------|-----------------|--------|
| BC-AUTH-01 | View list | `prime.billing-cycle.viewAny` | `index` | Screen-PM-1 |
| BC-AUTH-02 | View details | `prime.billing-cycle.view` | `show` | Screen-PM-2 |
| BC-AUTH-03 | Create | `prime.billing-cycle.create` | `create`,`store` | Screen-PM-3 |
| BC-AUTH-04 | Update / toggle | `prime.billing-cycle.update` | `edit`,`update`,`toggleStatus` | Screen-PM-4 |
| BC-AUTH-05 | Delete (soft) | `prime.billing-cycle.delete` | `destroy` | Screen-PM-5 |
| BC-AUTH-06 | Restore | `prime.billing-cycle.restore` | `restore`,`trashed` | Screen-PM-6 |
| BC-AUTH-07 | Force delete (intended) | `prime.billing-cycle.forceDelete` | Policy only — **controller uses `.delete`** → **DEV-BIL-020** | Screen-PM-7 / Audit |

### BC-BIZ — Business logic (Source: Controller / Screen)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `store()` creates record, logs `Stored`, redirects to `central.prime.sales-plan-mgmt.index#billing` with success flash | Screen-CRUD Create |
| BC-BIZ-02 | `update()` updates, logs `Updated`, redirects to sales-plan-mgmt#billing | Screen-CRUD Edit |
| BC-BIZ-03 | `destroy()` sets `is_active=false` **then** soft-deletes, logs `Trashed` | Screen-BR (Soft Delete) |
| BC-BIZ-04 | `restore()` restores trashed record, logs `Restored` | Screen-CRUD Restore |
| BC-BIZ-05 | `forceDelete()` permanently deletes inside try/catch; FK RESTRICT → error flash `operation_failed.billing_cycle`, logs `Deleted` on success | Screen-CRUD Force Delete |
| BC-BIZ-06 | `toggleStatus()` AJAX validates `is_active` boolean, saves, returns JSON `{success,is_active,message}` | Screen-BR (Status Toggle) |
| BC-BIZ-07 | Index paginates 20/page (`latest()->paginate(20)`) | Controller |

### BC-SM — State machine (Source: Screen-SM / Controller)

| ID | State → Trigger → Next | Source |
|----|-----------------------|--------|
| BC-SM-01 | Active → toggle → Inactive (and back) | Screen-SM |
| BC-SM-02 | Active → destroy → Trashed (is_active forced false) | Screen-SM |
| BC-SM-03 | Trashed → restore → Active(restored, deleted_at null) | Screen-SM |
| BC-SM-04 | Trashed → forceDelete → Permanently removed | Screen-SM |
| BC-SM-05 | Trashed (referenced) → forceDelete → **blocked** by FK RESTRICT (error flash) | Screen-SM / DDL FKs |

### BC-INT / BC-REF — Integration (Source: DDL FKs)

| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `prm_plans.billing_cycle_id` → `prm_billing_cycles.id` ON DELETE RESTRICT | DDL |
| BC-REF-02 | `prm_tenant_plan_rates.billing_cycle_id` → RESTRICT | DDL |
| BC-REF-03 | `bil_tenant_invoices.billing_cycle_id` → RESTRICT | DDL |
| BC-REF-04 | `prm_tenant_plan_billing_schedule.billing_cycle_id` → RESTRICT | DDL |
| BC-INT-01 | Model relationships: `plans`, `tenantPlanRates`, `billingSchedules`, `invoices` | Model |

### BC-EDG — Edge cases

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `months_count` = 1 (min) accepted | Screen-BR |
| BC-EDG-02 | `months_count` = 255 (max) accepted | Screen-BR / DDL |
| BC-EDG-03 | `short_name` exactly 50 chars accepted | DDL limit |
| BC-EDG-04 | Non-existent id on show/edit → 404 | Route-model binding |

---

## Known Source Defects (audit / discovered)

| ID | Severity | Description | Proving test |
|----|----------|-------------|--------------|
| **MIG-BIL-001** | P0 | Model uses `SoftDeletes` + default timestamps, but DDL `prm_billing_cycles` has no `deleted_at`/`created_at`/`updated_at`; on a schema-correct DB every CRUD/withTrashed call throws SQLSTATE 42S22 | `test_billing_cycle_02_*`, guarded by `assertBillingCycleSoftDeletesAvailable()` |
| **DEV-BIL-020** | P2 | `forceDelete()` authorizes `prime.billing-cycle.delete` instead of `prime.billing-cycle.forceDelete` (Policy + requirement matrix define `forceDelete`) | `test_billing_cycle_53_*` |

---

## 2. Test Case List

### Positive (TC-P)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01..07 | DDL | Table + columns exist | All 7 columns present | `test_01` | Ready |
| TC-P02 | BC-VAL-02 | Screen-BR | short_name unique index enforced at DB | Duplicate insert throws | `test_03` | Ready |
| TC-P03 | BC-INT-01 | Model | Fillable/casts/SoftDeletes/relationships | Match source | `test_04`,`test_05` | Ready |
| TC-P04 | BC-BIZ-01 | Screen | Create flow persists record | Row created, values match | `test_12` | Ready |
| TC-P05 | BC-BIZ-01 | Screen | Non-recurring create | `is_recurring=false` persists | `test_13` | Ready |
| TC-P06 | BC-BIZ-02 | Screen | Update flow persists changes | Values updated | `test_14` | Ready |
| TC-P07 | BC-VAL-02 | Screen-BR | Update keeps same short_name (ignore self) | Update succeeds | `test_15` | Ready |
| TC-P08 | BC-BIZ | Screen | Show displays details | short_name/name shown | `test_16` | Ready |
| TC-P09 | BC-SM-01 | Screen-SM | Toggle status via UI | `is_active` flips | `test_21` | Ready |
| TC-P10 | BC-SM-03 | Screen-SM | Restore from trash | `deleted_at` null | `test_23` | Ready |
| TC-P11 | BC-SM-04 | Screen-SM | Force delete permanent | Row gone | `test_24` | Ready |
| TC-P12 | BC-SM-02..04 | Screen-SM | Full lifecycle | End state removed | `test_25` | Ready |
| TC-P13 | BC-EDG-01/02/03 | DDL | Boundary values accepted | Created | `test_70`,`test_71`,`test_72` | Ready |
| TC-P14 | BC-BIZ-07 | Controller | Index loads / headers / breadcrumb / pagination | Rendered | `test_10`,`test_60`,`test_61` | Ready |

### Negative (TC-N)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-VAL-01/03/04 | Screen-VR | All required fields empty | `.alert-danger` with list | `test_30` | Ready |
| TC-N02 | BC-VAL-01 | Screen-VR | short_name required | "short name … required" | `test_31` | Ready |
| TC-N03 | BC-VAL-03 | Screen-VR | name required | "name … required" | `test_32` | Ready |
| TC-N04 | BC-VAL-04 | Screen-VR | months_count required | "months count … required" | `test_33` | Ready |
| TC-N05 | BC-VAL-01 | Screen-VR | short_name > 50 | max error | `test_34` | Ready |
| TC-N06 | BC-VAL-03 | Screen-VR | name > 50 | max error | `test_35` | Ready |
| TC-N07 | BC-VAL-05 | Screen-VR | description > 255 | max error | `test_36` | Ready |
| TC-N08 | BC-VAL-04 | Screen-VR | months_count = 0 (below min) | min error | `test_37` | Ready |
| TC-N09 | BC-VAL-04 | Screen-VR | months_count = 256 (above max) | max error | `test_38` | Ready |
| TC-N10 | BC-VAL-02 | Screen-BR | Duplicate short_name on create | rejected, no new row | `test_39` | Ready |
| TC-N11 | BC-EDG-04 | Route | Invalid id on edit/show | 404 | `test_73`,`test_74` | Ready |
| TC-N12 | BC-AUTH | Screen-PM | Guest → login redirect | `/login` | `test_50` | Ready |
| TC-N13 | TC-S | Security | Stored XSS name/description escaped | No raw `<script>`/`<img>` | `test_91`,`test_92` | Ready |

### Dependency (TC-D)

| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | C | BC-REF-01..04 | DDL | Referencing tables exist (FK RESTRICT) | Present | `test_40` | Ready |
| TC-D02 | C | BC-SM-05 | Controller | forceDelete try/catch wraps FK violation | error flash path | `test_41` | Ready |
| TC-D03 | C | BC-SM-05 | DDL | Force delete blocked while referenced by prm_plans | Blocked / row remains | `test_42` | Ready (defensive) |
| TC-D04 | B | BC-BIZ-03 | Screen-BR | Soft delete sets is_active false + trashes | deleted_at set, is_active false | `test_22` | Ready |
| TC-D05 | F | BC-SM | Screen-SM | Full lifecycle multi-step | End removed | `test_25` | Ready |

### Auth / Config / State (TC-A/SM proofs)

| TC ID | BC | Source | Description | Method | Status |
|-------|----|--------|-------------|--------|--------|
| TC-C01 | BC-VAL | Screen-VR | FormRequest rules present in source | `test_06` | Ready |
| TC-C02 | BC-BIZ | Routes | Named routes registered | `test_07` | Ready |
| TC-C03 | BC-BIZ | Controller | Controller methods exist | `test_08` | Ready |
| TC-C04 | BC-BIZ-01/02 | Controller | Redirect target sales-plan-mgmt#billing | `test_17` | Ready |
| TC-C05 | BC-BIZ-03 | Controller | destroy deactivates before delete (source) | `test_18` | Ready |
| TC-C06 | BC-BIZ | Controller | Activity-log events verbatim | `test_19` | Ready |
| TC-C07 | BC-BIZ-06 | Controller | toggleStatus JSON contract (source) | `test_20` | Ready |
| TC-AUTH01 | BC-AUTH-01..06 | Controller | Gate strings present | `test_51` | Ready |
| TC-AUTH02 | BC-AUTH | Policy | Policy declares all abilities | `test_52` | Ready |
| TC-AUTH03 | BC-AUTH-07 | Audit | DEV-BIL-020 permission mismatch | `test_53` | Ready |
| TC-T01 | — | Scope | Central scope, no tenant init | `test_90` | Ready |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_billing_cycle_01_schema_table_and_columns_are_correct | TC-P01 | Config | 01-09 |
| 2 | test_billing_cycle_02_ddl_has_no_timestamp_or_softdelete_columns_mig_bil_001 | MIG-BIL-001 | Config/Defect | 01-09 |
| 3 | test_billing_cycle_03_short_name_unique_index_exists | TC-P02 | Config | 01-09 |
| 4 | test_billing_cycle_04_model_configuration_matches_source | TC-P03 | Config | 01-09 |
| 5 | test_billing_cycle_05_model_relationships_are_defined | TC-P03/BC-INT-01 | Config | 01-09 |
| 6 | test_billing_cycle_06_form_request_rules_present_in_source | TC-C01 | Config | 01-09 |
| 7 | test_billing_cycle_07_named_routes_are_registered | TC-C02 | Config | 01-09 |
| 8 | test_billing_cycle_08_controller_methods_exist | TC-C03 | Config | 01-09 |
| 9 | test_billing_cycle_10_index_loads | TC-P14 | Business | 10-19 |
| 10 | test_billing_cycle_11_create_page_loads | TC-P14 | Business | 10-19 |
| 11 | test_billing_cycle_12_create_flow_persists_record | TC-P04 | Business | 10-19 |
| 12 | test_billing_cycle_13_create_respects_unchecked_recurring | TC-P05 | Business | 10-19 |
| 13 | test_billing_cycle_14_update_flow_persists_changes | TC-P06 | Business | 10-19 |
| 14 | test_billing_cycle_15_update_allows_same_short_name_unique_ignores_self | TC-P07 | Business | 10-19 |
| 15 | test_billing_cycle_16_show_page_displays_details | TC-P08 | Business | 10-19 |
| 16 | test_billing_cycle_17_store_source_redirects_to_sales_plan_mgmt_billing_anchor | TC-C04 | Business | 10-19 |
| 17 | test_billing_cycle_18_destroy_deactivates_before_soft_delete_in_source | TC-C05 | Business | 10-19 |
| 18 | test_billing_cycle_19_activity_log_events_are_verbatim_in_source | TC-C06 | Business | 10-19 |
| 19 | test_billing_cycle_20_status_toggle_endpoint_returns_json_in_source | TC-C07 | State | 20-29 |
| 20 | test_billing_cycle_21_status_toggle_ui_updates_is_active | TC-P09/BC-SM-01 | State | 20-29 |
| 21 | test_billing_cycle_22_soft_delete_moves_record_to_trash | TC-D04/BC-SM-02 | State | 20-29 |
| 22 | test_billing_cycle_23_restore_from_trash | TC-P10/BC-SM-03 | State | 20-29 |
| 23 | test_billing_cycle_24_force_delete_removes_permanently | TC-P11/BC-SM-04 | State | 20-29 |
| 24 | test_billing_cycle_25_full_lifecycle_flow | TC-P12/TC-D05 | State | 20-29 |
| 25 | test_billing_cycle_30_create_requires_required_fields | TC-N01 | Validation | 30-39 |
| 26 | test_billing_cycle_31_short_name_required_message | TC-N02 | Validation | 30-39 |
| 27 | test_billing_cycle_32_name_required_message | TC-N03 | Validation | 30-39 |
| 28 | test_billing_cycle_33_months_count_required_message | TC-N04 | Validation | 30-39 |
| 29 | test_billing_cycle_34_short_name_max_50_rejected | TC-N05 | Validation | 30-39 |
| 30 | test_billing_cycle_35_name_max_50_rejected | TC-N06 | Validation | 30-39 |
| 31 | test_billing_cycle_36_description_max_255_rejected | TC-N07 | Validation | 30-39 |
| 32 | test_billing_cycle_37_months_count_below_min_rejected | TC-N08 | Validation | 30-39 |
| 33 | test_billing_cycle_38_months_count_above_max_rejected | TC-N09 | Validation | 30-39 |
| 34 | test_billing_cycle_39_duplicate_short_name_rejected | TC-N10 | Validation | 30-39 |
| 35 | test_billing_cycle_40_referencing_tables_use_restrict_on_delete | TC-D01 | Dependency | 40-49 |
| 36 | test_billing_cycle_41_force_delete_wraps_fk_violation_in_try_catch | TC-D02 | Dependency | 40-49 |
| 37 | test_billing_cycle_42_force_delete_blocked_while_referenced_defensive | TC-D03 | Dependency | 40-49 |
| 38 | test_billing_cycle_50_guest_is_redirected_to_login | TC-N12 | Auth | 50-59 |
| 39 | test_billing_cycle_51_controller_gates_use_prime_billing_cycle_permissions | TC-AUTH01 | Auth | 50-59 |
| 40 | test_billing_cycle_52_policy_declares_all_abilities | TC-AUTH02 | Auth | 50-59 |
| 41 | test_billing_cycle_53_force_delete_permission_mismatch_dev_bil_020 | TC-AUTH03/DEV-BIL-020 | Auth/Defect | 50-59 |
| 42 | test_billing_cycle_60_index_breadcrumb_present | TC-P14 | UI/UX | 60-69 |
| 43 | test_billing_cycle_61_index_table_headers_present | TC-P14 | UI/UX | 60-69 |
| 44 | test_billing_cycle_62_recurring_badge_renders | TC-P14 | UI/UX | 60-69 |
| 45 | test_billing_cycle_63_trash_page_reachable | TC-P10 | UI/UX | 60-69 |
| 46 | test_billing_cycle_70_months_count_boundary_min_accepted | TC-P13 | Edge | 70-79 |
| 47 | test_billing_cycle_71_months_count_boundary_max_accepted | TC-P13 | Edge | 70-79 |
| 48 | test_billing_cycle_72_short_name_exactly_50_chars_accepted | TC-P13 | Edge | 70-79 |
| 49 | test_billing_cycle_73_invalid_id_edit_returns_not_found | TC-N11 | Edge | 70-79 |
| 50 | test_billing_cycle_74_invalid_id_show_returns_not_found | TC-N11 | Edge | 70-79 |
| 51 | test_billing_cycle_90_central_scope_table_resolves_on_default_connection | TC-T01 | Tenancy | 90-99 |
| 52 | test_billing_cycle_91_stored_xss_in_name_is_escaped_on_render | TC-N13 | Security | 90-99 |
| 53 | test_billing_cycle_92_stored_xss_in_description_is_escaped_on_render | TC-N13 | Security | 90-99 |

**Total: 53 test methods.**
