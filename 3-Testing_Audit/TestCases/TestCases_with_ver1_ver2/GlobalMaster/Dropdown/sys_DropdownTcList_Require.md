# Dropdown — Test Case List & Business Conditions (`sys_DropdownTcList_Require.md`)

- **Module:** GlobalMaster
- **Feature / Screen:** Dropdown (central dropdown value registry)
- **Primary table:** `sys_dropdown_table` (prime_db — **central / prime-side**, NO tenant init)
- **File prefix:** `sys_` (verified against DDL `CREATE TABLE sys_dropdown_table` in `_prime_db_v4.sql`)
- **Controller:** `Modules/GlobalMaster/app/Http/Controllers/DropdownController.php`
- **Model:** `Modules/GlobalMaster/Models/Dropdown` (`HasFactory`, `SoftDeletes`)
- **Request:** `Modules/GlobalMaster/Http/Requests/DropdownRequest`
- **Policy:** `DropdownPolicy` — gates `prime.dropdown.{viewAny|view|create|update|delete|restore|forceDelete}`
- **Routes (name family `central.global-master.dropdown.*`, URL `/global-master/dropdown`):** resource `dropdown` + `dropdown.search` (GET) + `dropdown.trashed` (GET `/trash/view`) + `dropdown.restore` (GET `/{id}/restore`) + `dropdown.forceDelete` (DELETE `/{id}/force-delete`) + `dropdown.toggleStatus` (POST `/{dropdown}/toggle-status`)
- **Activity log:** central `Modules\Prime\Models\ActivityLog` → table `sys_central_activity_logs` (routed by `activityLog()` helper when tenancy not initialized)
- **Test style:** browser Dusk central pattern; `extends BillingDuskTestCase`; host `http://127.0.0.1:8000`
- **Scope note:** cross-tenant isolation **N/A** (single central table).

---

## 1. Business Conditions

### BC-DB (schema — Source: `DDL-sys_dropdown_table`, migration `2025_11_16_114618_create_sys_dropdown_table.php`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `sys_dropdown_table` exists | DDL-sys_dropdown_table |
| BC-DB-02 | `id` INT UNSIGNED PK auto-increment | DDL-sys_dropdown_table |
| BC-DB-03 | `ordinal` TINYINT UNSIGNED NOT NULL (≤255) | DDL-sys_dropdown_table |
| BC-DB-04 | `key` VARCHAR(160) NOT NULL | DDL-sys_dropdown_table |
| BC-DB-05 | `value` VARCHAR(100) NOT NULL | DDL-sys_dropdown_table |
| BC-DB-06 | `type` ENUM('String','Integer','Decimal','Date','Datetime','Time','Boolean') DEFAULT 'String' | DDL-sys_dropdown_table |
| BC-DB-07 | `additional_info` JSON NULLABLE | DDL-sys_dropdown_table |
| BC-DB-08 | `is_active` TINYINT(1) DEFAULT 1 | DDL-sys_dropdown_table |
| BC-DB-09 | `deleted_at` present (SoftDeletes) | DDL-sys_dropdown_table |
| BC-DB-10 | UNIQUE `uq_dropdownTable_key_value` (`key`,`value`) | DDL-sys_dropdown_table |
| BC-DB-11 | UNIQUE `uq_dropdownTable_key_ordinal` (`key`,`ordinal`) | DDL-sys_dropdown_table |
| BC-DB-12 | **No `org_id` column** (controller references it — defect) | DDL-sys_dropdown_table / Audit-BUG-GLB-009 |

### BC-VAL (validation — Source: `DropdownRequest::rules()`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `value` required, string, max:255 | Screen-VR-1 / DropdownRequest |
| BC-VAL-02 | `value` unique scoped to `key` (`Rule::unique(...)->where(key = table_name.column_name)`) | DropdownRequest |
| BC-VAL-03 | `is_active` required, boolean | DropdownRequest |
| BC-VAL-04 | `prepareForValidation` coerces checkbox `'on'` → boolean | DropdownRequest |
| BC-VAL-05 | **`key` NOT validated** (strict rule commented out) — defect | Audit-VAL-GLB-001 |
| BC-VAL-06 | **`type` NOT validated** — defect | Audit-VAL-GLB-001 |
| BC-VAL-07 | toggleStatus validates `is_active` required, boolean | DropdownController::toggleStatus |

### BC-AUTH (authorization — Source: `DropdownPolicy` + `Gate::authorize()` in controller)

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index → `prime.dropdown.viewAny` | Screen-PM-1 / Controller |
| BC-AUTH-02 | create/store → `prime.dropdown.create` | Controller |
| BC-AUTH-03 | show → `prime.dropdown.view` | Controller |
| BC-AUTH-04 | edit/update/toggleStatus → `prime.dropdown.update` | Controller |
| BC-AUTH-05 | destroy → `prime.dropdown.delete` | Controller |
| BC-AUTH-06 | restore → `prime.dropdown.restore` | Controller |
| BC-AUTH-07 | forceDelete → `prime.dropdown.forceDelete` | Controller |
| BC-AUTH-08 | Guest → redirected to `/login` (`auth` middleware) | Routes |
| BC-AUTH-09 | Blade uses `tenant.dropdown.*` on shared components (UI-only prefix mismatch vs `prime.dropdown.*`) | index.blade.php |

### BC-BIZ (business logic / activity log — Source: Controller + `activityLog()` helper)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | index paginates DISTINCT `key` (10/page) ordered by `key`, then groups values per key | Controller::index |
| BC-BIZ-02 | store splits `value` on comma, trims, de-dupes → one row per value | Controller::store |
| BC-BIZ-03 | store slugifies `key` with `_` (`Str::slug($key,'_')`) | Controller::store |
| BC-BIZ-04 | store computes ordinal via `max('ordinal')` filtered by `org_id` (**not scoped to key**) | Controller::store / Audit-BUG-GLB-009 |
| BC-BIZ-05 | destroy sets `is_active=false`, saves, then soft-deletes | Controller::destroy |
| BC-BIZ-06 | destroy logs event **`Trashed`**, message `A new module was deactivated and deleted.` | Controller::destroy |
| BC-BIZ-07 | restore logs event **`Restored`**, message `A new module was restored.` | Controller::restore |
| BC-BIZ-08 | forceDelete logs event **`Deleted`**, message `A new module was permanently deleted.` | Controller::forceDelete |
| BC-BIZ-09 | toggleStatus logs event **`Toggled`**, message `Module toggle was updated.` | Controller::toggleStatus |
| BC-BIZ-10 | toggleStatus returns JSON `{success, is_active, message}` | Controller::toggleStatus |
| BC-BIZ-11 | store/update do **NOT** write an activity log | Controller |
| BC-BIZ-12 | flash keys mislabeled `.module` on a dropdown feature (`trashed.module`, `restored.module`, `force_deleted.module`) | Controller / Audit-BUG-GLB-009 |

### BC-REF / BC-INT (relationships — Source: Model + DDL)

| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `dropdownNeeds()` belongsToMany via `sys_dropdown_need_table_jnt` | Model |
| BC-REF-02 | `junction()` hasOne `DropdownNeedTableJnt` on `dropdown_table_id` | Model |
| BC-INT-01 | Junction table `sys_dropdown_need_table_jnt` FKs → `sys_dropdown_needs`, `sys_dropdown_table` | DDL |
| BC-INT-02 | Complaint module consumes Dropdown ids (severity/priority/status) | Model relationships |

### BC-EDG (edge — Source: DDL limits + Controller)

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `ordinal` bounded to TINYINT (≤255) | DDL |
| BC-EDG-02 | `key` up to 160 chars | DDL |
| BC-EDG-03 | Request `max:255` on `value` vs DDL `VARCHAR(100)` (length mismatch) | DropdownRequest vs DDL |
| BC-EDG-04 | Same `ordinal` allowed across different `key`s; duplicate `(key,ordinal)` rejected | DDL uq |
| BC-EDG-05 | Empty state renders "No Data Found" | index.blade.php |

### Known Source Defects (audit-equivalent)

| ID | Sev | Description | Proving test(s) |
|----|-----|-------------|-----------------|
| VAL-GLB-001 | P1 | `DropdownRequest` validates only `value` + `is_active`; `key`/`type`/`org_id` unvalidated → store can proceed with missing/invalid required fields | V1-05, V2-30, V2-36 |
| BUG-GLB-005 | P1 | Route `dropdown.search` registered but `DropdownController::search()` does not exist → 500 | V1-15, V2-48, V2-49, V2-94 |
| BUG-GLB-009 | P2 | `org_id` used in store (filter + insert) is neither a column nor fillable; ordinal `max()` not key-scoped; log/flash strings mislabeled `module` | V1-04, V2-45, V2-46, V2-19, V2-92 |
| PERF-GLB-001 | P2 | `index()` N+1 (loop issues one query per key) — documented; soft-timing probe only | V2-69 |

---

## 2. Test Case List

Columns: **TC ID | Category | BC | Source | Description | Expected | V1 | V2 | Status**

### Positive (TC-P)

| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-P01 | BC-DB-01..11 | DDL | Schema/model/request config correct | All asserts pass | 01,02,03 | 01,02,03,05 | Automated |
| TC-P02 | BC-BIZ-01 | Controller | Index lists/groups keys, paginates 10 | Table renders, 10/page | 06 | 10,60,61,62 | Automated |
| TC-P03 | BC-AUTH-01 | Controller | Create page loads with fields | key/value present | 07 | 63 | Automated |
| TC-P04 | BC-BIZ-01 | Controller | Seeded record visible on index | value shown | 08 | 60 | Automated |
| TC-P05 | BC-BIZ-09/10 | Controller | Toggle updates is_active + JSON | is_active flips; JSON shape | 09,10 | 13,96 | Automated |
| TC-P06 | BC-BIZ-05 | Controller | Soft delete → trash | deleted_at set, hidden | 11 | 12,42 | Automated |
| TC-P07 | BC-BIZ-07 | Controller | Restore from trash | deleted_at cleared | 12 | 15 | Automated |
| TC-P08 | BC-BIZ-08 | Controller | Force delete removes row | row gone | 13 | 16,43 | Automated |
| TC-P09 | BC-BIZ-06 | Controller | destroy logs `Trashed` | activity row present | 14 | 14 | Automated |
| TC-P10 | BC-VAL-04 | Request | Checkbox coercion contract | `'on'`→bool | — | 35 | Automated |
| TC-P11 | BC-BIZ-02 | Controller | Comma-value parsing contract | de-duped array | — | 79 | Automated |
| TC-P12 | BC-EDG-05 | Blade | Empty state message | "No Data Found" | — | 65 | Automated |
| TC-P13 | BC-REF-01/02 | Model | Relationships defined | correct rel types | — | 06,07,44 | Automated |

### Negative (TC-N)

| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-N01 | BC-VAL-05 | VAL-GLB-001 | Missing `key` not rejected | no key validation error | 05 | 30,36 | Automated |
| TC-N02 | BC-VAL-06 | VAL-GLB-001 | Missing `type` not rejected | no type validation error | 05 | 30,36 | Automated |
| TC-N03 | BC-VAL-01 | Request | `value` required | required rule present | — | 31 | Automated |
| TC-N04 | BC-VAL-01 | Request | `value` max:255 boundary | max rule present | — | 32,38 | Automated |
| TC-N05 | BC-VAL-02 | Request | `value` unique scoped to key | scoped unique rule | — | 34 | Automated |
| TC-N06 | BC-DB-10 | DDL | Duplicate `(key,value)` rejected | insert throws | 18 | (46 sibling) | Automated |
| TC-N07 | BC-DB-11 | DDL | Duplicate `(key,ordinal)` rejected | insert throws | — | 46 | Automated |
| TC-N08 | BC-VAL-07 | Controller | Non-boolean toggle `is_active` | 422 | — | 39 | Automated |
| TC-N09 | BC-EDG-03 | Request/DDL | value length mismatch documented | max:255 vs VARCHAR(100) | — | 72 | Automated |
| TC-N10 | BC-AUTH-08 | Routes | Guest → /login | redirect | 16 | 50,95 | Automated |
| TC-N11 | BUG-GLB-005 | Route | Dead search route | {404,405,500} | 15 | 48,49,94 | Automated |
| TC-N12 | BC-EDG | Controller | Invalid id edit/toggle/restore | 404 | — | 76,77,78,93 | Automated |

### Dependency (TC-D, sub-cat A–G)

| TC ID | Sub | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-D01 | B | BC-BIZ-05 | Controller | Soft delete preserves row/junction | withTrashed finds it | 11 | 42 | Automated |
| TC-D02 | B | BC-BIZ-08 | Controller | Restore cannot recover force-deleted | null | — | 43 | Automated |
| TC-D03 | E | BC-INT-02 | Model | Complaint cross-module rel (defensive) | HasMany or skip | — | 44 | Automated |
| TC-D04 | C | BC-INT-01 | DDL | Junction FK columns present | columns exist | — | 40,41 | Automated |
| TC-D05 | F | BC-BIZ-05..08 | Controller | Full lifecycle delete→restore→forceDelete | states correct | 11,12,13 | 12,15,16,43 | Automated |
| TC-D06 | G | BC-DB-11 | DDL | Concurrent ordinal uniqueness by key | duplicate rejected | — | 46,47 | Automated |
| TC-D07 | B | BUG-GLB-009 | Controller | `org_id` query on missing column fails | throws / column absent | 04 | 45 | Automated |

### Security (TC-S)

| TC ID | BC | Source | Description | Expected | V2 | Status |
|-------|----|--------|-------------|----------|----|--------|
| TC-S01 | BC-BIZ-01 | Blade | Stored XSS in `value` escaped on index | no raw `<script>` | 91 | Automated |
| TC-S02 | Model | Mass-assignment guard (id/org_id ignored) | id not overwritten | 92 | Automated |
| TC-S03 | Controller | IDOR / unknown id toggle | 404/403 | 76,93 | Automated |
| TC-S04 | Route | Injection-shaped search input | non-200 | 94 | Automated |
| TC-S05 | Routes | Guest cannot reach create | /login | 95 | Automated |

---

## 3. V2 Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 01 | test_dropdown_01_table_exists_with_all_columns | TC-P01 | Schema | 01–09 |
| 02 | test_dropdown_02_model_table_fillable_and_casts | TC-P01 | Schema | 01–09 |
| 03 | test_dropdown_03_model_uses_softdeletes | TC-P01 | Schema | 01–09 |
| 04 | test_dropdown_04_type_enum_matches_ddl | BC-DB-06 | Schema | 01–09 |
| 05 | test_dropdown_05_unique_indexes_present | BC-DB-10/11 | Schema | 01–09 |
| 06 | test_dropdown_06_belongsto_many_dropdown_needs_relationship | TC-P13 | Schema | 01–09 |
| 07 | test_dropdown_07_junction_hasone_relationship | TC-P13 | Schema | 01–09 |
| 08 | test_dropdown_08_policy_maps_all_prime_dropdown_gates | BC-AUTH-* | Schema | 01–09 |
| 09 | test_dropdown_09_controller_declares_expected_actions | BC-BIZ-* | Schema | 01–09 |
| 10 | test_dropdown_10_index_groups_records_by_distinct_key | TC-P02 | Business | 10–19 |
| 11 | test_dropdown_11_store_slugifies_key_with_underscore | BC-BIZ-03 | Business | 10–19 |
| 12 | test_dropdown_12_destroy_sets_inactive_then_soft_deletes | TC-P06 | Business | 10–19 |
| 13 | test_dropdown_13_toggle_updates_is_active_via_http | TC-P05 | Business | 10–19 |
| 14 | test_dropdown_14_destroy_logs_trashed_event_and_message | TC-P09 | Business | 10–19 |
| 15 | test_dropdown_15_restore_logs_restored_event_and_message | TC-P07 | Business | 10–19 |
| 16 | test_dropdown_16_force_delete_logs_deleted_event_and_message | TC-P08 | Business | 10–19 |
| 17 | test_dropdown_17_toggle_logs_toggled_event_and_message | BC-BIZ-09 | Business | 10–19 |
| 18 | test_dropdown_18_store_and_update_do_not_write_activity_log | BC-BIZ-11 | Business | 10–19 |
| 19 | test_dropdown_19_activity_flash_messages_are_mislabeled_module | BUG-GLB-009 | Business | 10–19 |
| 30 | test_dropdown_30_request_rules_only_value_and_is_active | TC-N01/N02 | Validation | 30–39 |
| 31 | test_dropdown_31_value_is_required | TC-N03 | Validation | 30–39 |
| 32 | test_dropdown_32_value_has_max_255 | TC-N04 | Validation | 30–39 |
| 33 | test_dropdown_33_is_active_required_boolean | BC-VAL-03 | Validation | 30–39 |
| 34 | test_dropdown_34_value_uniqueness_scoped_to_key | TC-N05 | Validation | 30–39 |
| 35 | test_dropdown_35_prepare_for_validation_coerces_is_active | TC-P10 | Validation | 30–39 |
| 36 | test_dropdown_36_missing_key_and_type_are_not_rejected | TC-N01/N02 | Validation | 30–39 |
| 37 | test_dropdown_37_whitespace_only_value_is_invalid | BC-VAL-01 | Validation | 30–39 |
| 38 | test_dropdown_38_value_exceeding_255_would_fail_string_max | TC-N04 | Validation | 30–39 |
| 39 | test_dropdown_39_toggle_requires_boolean_is_active | TC-N08 | Validation | 30–39 |
| 40 | test_dropdown_40_junction_table_exists | TC-D04 | Integration | 40–49 |
| 41 | test_dropdown_41_junction_has_fk_columns | TC-D04 | Integration | 40–49 |
| 42 | test_dropdown_42_soft_delete_preserves_junction_rows | TC-D01 | Integration | 40–49 |
| 43 | test_dropdown_43_restore_does_not_recover_force_deleted | TC-D02 | Integration | 40–49 |
| 44 | test_dropdown_44_complaint_severity_relationship_defined | TC-D03 | Integration | 40–49 |
| 45 | test_dropdown_45_org_id_query_targets_nonexistent_column | TC-D07 | Integration | 40–49 |
| 46 | test_dropdown_46_ordinal_uniqueness_scoped_to_key | TC-N07/D06 | Integration | 40–49 |
| 47 | test_dropdown_47_same_ordinal_allowed_across_different_keys | TC-D06 | Integration | 40–49 |
| 48 | test_dropdown_48_search_route_registered_but_method_absent | TC-N11 | Integration | 40–49 |
| 49 | test_dropdown_49_search_route_returns_error_status | TC-N11 | Integration | 40–49 |
| 50 | test_dropdown_50_guest_redirected_to_login | TC-N10 | Permissions | 50–59 |
| 51 | test_dropdown_51_index_uses_viewany_gate | BC-AUTH-01 | Permissions | 50–59 |
| 52 | test_dropdown_52_store_uses_create_gate | BC-AUTH-02 | Permissions | 50–59 |
| 53 | test_dropdown_53_update_uses_update_gate | BC-AUTH-04 | Permissions | 50–59 |
| 54 | test_dropdown_54_destroy_uses_delete_gate | BC-AUTH-05 | Permissions | 50–59 |
| 55 | test_dropdown_55_restore_and_force_delete_gates | BC-AUTH-06/07 | Permissions | 50–59 |
| 56 | test_dropdown_56_toggle_uses_update_gate | BC-AUTH-04 | Permissions | 50–59 |
| 57 | test_dropdown_57_blade_permission_prefix_mismatch_documented | BC-AUTH-09 | Permissions | 50–59 |
| 58 | test_dropdown_58_unauthenticated_toggle_is_rejected | TC-N10 | Permissions | 50–59 |
| 59 | test_dropdown_59_policy_class_bound_to_dropdown_model | BC-AUTH | Permissions | 50–59 |
| 60 | test_dropdown_60_index_renders_table | TC-P02 | UI/UX | 60–69 |
| 61 | test_dropdown_61_index_paginates_ten_per_page | BC-BIZ-01 | UI/UX | 60–69 |
| 62 | test_dropdown_62_index_orders_keys_ascending | BC-BIZ-01 | UI/UX | 60–69 |
| 63 | test_dropdown_63_create_page_has_key_value_type_fields | TC-P03 | UI/UX | 60–69 |
| 64 | test_dropdown_64_trash_page_loads | TC-P06 | UI/UX | 60–69 |
| 65 | test_dropdown_65_empty_state_message_present_when_no_rows | TC-P12 | UI/UX | 60–69 |
| 66 | test_dropdown_66_index_has_search_form | BC-BIZ-01 | UI/UX | 60–69 |
| 67 | test_dropdown_67_status_switch_component_used | BC-BIZ-10 | UI/UX | 60–69 |
| 68 | test_dropdown_68_breadcrumb_points_to_dropdown_index | BC-BIZ | UI/UX | 60–69 |
| 69 | test_dropdown_69_index_load_soft_timing | PERF-GLB-001 | UI/UX | 60–69 |
| 70 | test_dropdown_70_ordinal_is_tinyint_bounded | BC-EDG-01 | Edge | 70–79 |
| 71 | test_dropdown_71_key_max_160_chars | BC-EDG-02 | Edge | 70–79 |
| 72 | test_dropdown_72_value_max_100_chars_at_db | TC-N09 | Edge | 70–79 |
| 73 | test_dropdown_73_additional_info_accepts_json | BC-DB-07 | Edge | 70–79 |
| 74 | test_dropdown_74_default_type_is_string | BC-DB-06 | Edge | 70–79 |
| 75 | test_dropdown_75_default_is_active_true | BC-DB-08 | Edge | 70–79 |
| 76 | test_dropdown_76_invalid_id_toggle_returns_404 | TC-N12/S03 | Edge | 70–79 |
| 77 | test_dropdown_77_invalid_id_edit_returns_404 | TC-N12 | Edge | 70–79 |
| 78 | test_dropdown_78_restore_unknown_id_returns_404 | TC-N12 | Edge | 70–79 |
| 79 | test_dropdown_79_comma_values_produce_multiple_rows_contract | TC-P11 | Edge | 70–79 |
| 90 | test_dropdown_90_cross_tenant_isolation_not_applicable | Scope note | Tenancy N/A | 90–99 |
| 91 | test_dropdown_91_stored_xss_value_is_escaped_on_index | TC-S01 | Security | 90–99 |
| 92 | test_dropdown_92_mass_assignment_guard_ignores_unlisted_columns | TC-S02 | Security | 90–99 |
| 93 | test_dropdown_93_idor_direct_toggle_of_foreign_id_guarded | TC-S03 | Security | 90–99 |
| 94 | test_dropdown_94_search_injection_shaped_input_is_safe | TC-S04 | Security | 90–99 |
| 95 | test_dropdown_95_guest_cannot_reach_create | TC-S05 | Security | 90–99 |
| 96 | test_dropdown_96_toggle_endpoint_json_contract_keys | TC-P05 | Security/API | 90–99 |
| 97 | test_dropdown_97_route_name_family_is_central_global_master | Routes | Security/API | 90–99 |
| 98 | test_dropdown_98_module_enabled_prerequisite_probe | Env E19 | Security/API | 90–99 |
| 99 | test_dropdown_99_toggle_route_is_registered_post | Routes | Security/API | 90–99 |

**V1 methods:** 18 · **V2 methods:** 79 · **Ratio:** 4.39× (gate ≥ 2× met).
