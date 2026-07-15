# Dropdown (PRM / Prime) — Test Case List & Business Conditions

- **Module:** Prime (PRM) — **CENTRAL / prime_db** (no tenant init)
- **Feature / Screen:** Dropdown (central dropdown option store)
- **Primary table:** `sys_dropdown_table` (constraint #27 — the "rename to sys_dropdowns" migration is a **no-op**; runtime table stays `sys_dropdown_table`, confirmed by `Dropdown::$table`, FormRequest `unique:sys_dropdown_table,key`, and the junction FK)
- **Prefix:** `sys_` (DDL-verified; registry lists module prefix `prm_`, but the primary-table prefix rule wins → **`sys_`**)
- **Controller:** `Modules\Prime\Http\Controllers\DropdownController`
- **FormRequest:** `Modules\Prime\Http\Requests\DropdownRequest`
- **Model:** `Modules\Prime\Models\Dropdown` (SoftDeletes)
- **Activity sink:** `sys_central_activity_logs` via `Modules\Prime\Models\ActivityLog` (constraint #25)
- **Routes:** `central.global-master.dropdown.*` (URL prefix `/global-master`), host `http://127.0.0.1:8000`
- **Test file:** `sys_Dropdown_TestCas.php` (41 methods, single comprehensive suite)

---

## 1. Business Conditions

### BC-DB (schema / DDL — `DDL-sys_dropdown_table`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `sys_dropdown_table` exists with columns id, ordinal, key, value, type, additional_info, is_active, created_at, updated_at, deleted_at | DDL-sys_dropdown_table + migration |
| BC-DB-02 | `id` INT unsigned AUTO_INCREMENT PK | DDL |
| BC-DB-03 | `ordinal` TINYINT UNSIGNED NOT NULL | DDL |
| BC-DB-04 | `key` VARCHAR(160) NOT NULL | DDL |
| BC-DB-05 | `value` VARCHAR(100) NOT NULL | DDL |
| BC-DB-06 | `type` ENUM('String','Integer','Decimal','Date','Datetime','Time','Boolean') DEFAULT 'String' | DDL |
| BC-DB-07 | `additional_info` JSON NULL | DDL |
| BC-DB-08 | `is_active` TINYINT(1) DEFAULT 1 | DDL |
| BC-DB-09 | UNIQUE `uq_dropdownTable_key_value` (key,value) | DDL |
| BC-DB-10 | UNIQUE `uq_dropdownTable_key_ordinal` (key,ordinal) | DDL |
| BC-DB-11 | `deleted_at` exists (migration `softDeletes()`) though the consolidated DDL omits it → **DEV-DROPDOWN-001** | migration vs DDL |

### BC-VAL (validation — FormRequest + inline store, `Screen-VR`)
| ID | Condition | Message | Source |
|----|-----------|---------|--------|
| BC-VAL-01 | `key` required, string, max:160, unique (ignore self on update) | `This key already exists.` | DropdownRequest / store |
| BC-VAL-02 | `value` required, string, max:100 | default | DropdownRequest / store |
| BC-VAL-03 | `type` required, in the 7 enum values | default | DropdownRequest / store |
| BC-VAL-04 | `ordinal` nullable, integer, min:1 | default | DropdownRequest / store |
| BC-VAL-05 | `additional_info` nullable, string | default | DropdownRequest / store |
| BC-VAL-06 | `is_active` nullable, boolean | default | DropdownRequest / store |
| BC-VAL-07 | toggleStatus: `is_active` required, boolean | default | Controller::toggleStatus |
| BC-VAL-08 | saveDropdownOption `type` enum only 5 values (Datetime/Time missing) → **DEV-DROPDOWN-005** | — | Controller::saveDropdownOption |

### BC-AUTH (permission gate ↔ method, `Screen-PM`)
| ID | Method(s) | Gate | Source |
|----|-----------|------|--------|
| BC-AUTH-01 | index | `prime.dropdown.viewAny` | Controller |
| BC-AUTH-02 | show | `prime.dropdown.view` | Controller |
| BC-AUTH-03 | create/store/saveDropdownOption/addBySelection/quickSave | `prime.dropdown.create` | Controller |
| BC-AUTH-04 | edit/update/updateBulk/toggleStatus | `prime.dropdown.update` | Controller |
| BC-AUTH-05 | destroy/deleteBulk | `prime.dropdown.delete` | Controller |
| BC-AUTH-06 | trashedDropdown/restore/restoreBulk | `prime.dropdown.restore` | Controller |
| BC-AUTH-07 | forceDelete/forceDeleteBulk | `prime.dropdown.forceDelete` | Controller |
| BC-AUTH-08 | mapDropdownsToNeed/removeMapping | `prime.dropdown-need.update` | Controller |
| BC-AUTH-09 | DropdownRequest::authorize maps store→create, update→update, default→viewAny | Request |
| BC-AUTH-10 | Guest → redirect `/login`; non-privileged user denied gates | routes middleware `auth,verified` |

### BC-BIZ (business logic / activity, `Screen-BR`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Model default attributes: type=String, is_active=true | Model $attributes |
| BC-BIZ-02 | `additional_info` cast to array; controller wraps free text as `json_encode(['info'=>...])` | Model + Controller |
| BC-BIZ-03 | store auto-assigns ordinal = max(ordinal)+1 when not supplied; requires a dropdown_need_id + creates junction | Controller::store |
| BC-BIZ-04 | destroy: set is_active=false, soft delete, deactivate junction; log event `Trashed` | Controller::destroy |
| BC-BIZ-05 | restore: restore + is_active=true, reactivate junction; log event `Restored` | Controller::restore |
| BC-BIZ-06 | toggleStatus: update is_active + junction; log event `Toggled` | Controller::toggleStatus |
| BC-BIZ-07 | store/update emit **no** activity log → **DEV-DROPDOWN-007** | Controller |
| BC-BIZ-08 | destroy calls `activityLog($dropdown,'Trashed')` with `$dropdown` scoped inside the closure → null subject → **DEV-DROPDOWN-002** | Controller::destroy |
| BC-BIZ-09 | destroy/forceDelete mutate `DropdownNeedDropdown` (sys_dropdown_need_dropdowns_jnt) while restore/toggle/store mutate `DropdownNeedTableJnt` (sys_dropdown_need_table_jnt) → **DEV-DROPDOWN-003** | Controller |
| BC-BIZ-10 | addBySelection/quickSave call removed `str_slug()` helper (Laravel 11) → fatal → **DEV-DROPDOWN-008** | Controller |

### BC-SM (lifecycle transitions)
| ID | State → Trigger → Next | Source |
|----|------------------------|--------|
| BC-SM-01 | Active → toggle → Inactive | Model/Controller |
| BC-SM-02 | Present → delete → Trashed (deleted_at set) | SoftDeletes |
| BC-SM-03 | Trashed → restore → Present (deleted_at null) | SoftDeletes |
| BC-SM-04 | Trashed → forceDelete → Gone | SoftDeletes |

### BC-REF / BC-INT (FK integrity)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | Junction FK `dropdown_table_id` → `sys_dropdown_table(id)` (NOT `sys_dropdowns`) | DDL / constraint #27 |
| BC-INT-01 | `dropdownNeeds()` belongsToMany via `sys_dropdown_need_dropdowns_jnt` | Model |

### BC-EDG (edge / boundary)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | ordinal is tinyint unsigned (0–255) | DDL |
| BC-EDG-02 | key ≤160, value ≤100 declared lengths | DDL |
| BC-EDG-03 | unique(key,value) lacks deleted_at → recreating a soft-deleted key+value collides → **DEV-DROPDOWN-006** | DDL + SoftDeletes |
| BC-EDG-04 | store global `unique:key` contradicts composite (key,value)/(key,ordinal) design → **DEV-DROPDOWN-004** | Controller vs DDL |

### Known Source Defects (verify in source)
| DEV ID | Description | Proving test |
|--------|-------------|--------------|
| DEV-DROPDOWN-001 | Consolidated DDL omits `deleted_at`/softDeletes though migration+model use it | test_dropdown_04 |
| DEV-DROPDOWN-002 | `destroy()` logs `Trashed` with out-of-scope `$dropdown` → null subject | test_dropdown_13 |
| DEV-DROPDOWN-003 | destroy/restore mutate two different junction tables | test_dropdown_14 |
| DEV-DROPDOWN-004 | store global key-uniqueness conflicts with composite unique design | test_dropdown_73 |
| DEV-DROPDOWN-005 | saveDropdownOption `type` enum narrower than DDL (5 of 7) | test_dropdown_34 |
| DEV-DROPDOWN-006 | unique(key,value) without deleted_at blocks recreating a trashed key+value | test_dropdown_72 |
| DEV-DROPDOWN-007 | store/update emit no activity log | test_dropdown_12 |
| DEV-DROPDOWN-008 | addBySelection/quickSave call removed `str_slug()` → runtime fatal | test_dropdown_15 |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01..10 | DDL | Schema+model+request config truth | All asserts pass | test_dropdown_01 | Automated |
| TC-P02 | BC-DB-09/10 | DDL | Composite unique indexes exist | Both present | test_dropdown_02 | Automated |
| TC-P03 | BC-DB-06 | DDL | type ENUM = 7 values | All present | test_dropdown_03 | Automated |
| TC-P05 | BC-BIZ | #25 | Central activity sink configured | table+model ok | test_dropdown_05 | Automated |
| TC-P10 | BC-BIZ-01 | Model | Default attrs String/active | ok | test_dropdown_10 | Automated |
| TC-P11 | BC-BIZ-02 | Model | additional_info array cast | round-trips | test_dropdown_11 | Automated |
| TC-P60 | BC-AUTH-01 | UI | Index loads for admin | accessible | test_dropdown_60 | Automated |
| TC-P61 | UI | View | List pane renders | present | test_dropdown_61 | Automated |
| TC-P62 | UI | View | List filter inputs present | present | test_dropdown_62 | Automated |
| TC-P63 | UI | View | Trash view columns render | Key/Value/Action | test_dropdown_63 | Automated |
| TC-P64 | UI | View | Breadcrumb title | "Dropdown" visible | test_dropdown_64 | Automated |
| TC-P65 | BC-AUTH-03 | routes | create/store routes registered | ok | test_dropdown_65 | Automated |
| TC-P93 | routes | routes | AJAX/bulk routes registered | ok | test_dropdown_93 | Automated |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N04 | BC-DB-11 | migration | deleted_at present despite DDL gap | column exists | test_dropdown_04 | Automated (DEV-001) |
| TC-N12 | BC-BIZ-07 | Controller | store/update no activity log | none | test_dropdown_12 | Automated (DEV-007) |
| TC-N13 | BC-BIZ-08 | Controller | destroy out-of-scope $dropdown | structure proven | test_dropdown_13 | Automated (DEV-002) |
| TC-N14 | BC-BIZ-09 | Controller | inconsistent junctions | proven | test_dropdown_14 | Automated (DEV-003) |
| TC-N15 | BC-BIZ-10 | Controller | str_slug removed helper | used + undefined | test_dropdown_15 | Automated (DEV-008) |
| TC-N30 | BC-VAL-01..04 | Request | rules() strings | correct | test_dropdown_30 | Automated |
| TC-N31 | BC-VAL-01 | Request | custom unique message | matches | test_dropdown_31 | Automated |
| TC-N32 | BC-VAL-01..04 | Controller | store inline rules | present | test_dropdown_32 | Automated |
| TC-N33 | BC-VAL-07 | Controller | toggleStatus boolean rule | present | test_dropdown_33 | Automated |
| TC-N34 | BC-VAL-08 | Controller | saveDropdownOption narrow enum | proven | test_dropdown_34 | Automated (DEV-005) |
| TC-N50 | BC-AUTH-01..07 | Controller | gate string per method | all present | test_dropdown_50 | Automated |
| TC-N51 | BC-AUTH-09 | Request | authorize action→gate | mapped | test_dropdown_51 | Automated |
| TC-N52 | BC-AUTH-10 | routes | guest→login (index) | redirect | test_dropdown_52 | Automated |
| TC-N53 | BC-AUTH-10 | routes | guest→login (trash) | redirect | test_dropdown_53 | Automated |
| TC-N54 | BC-AUTH-10 | Gate | limited user denied | denies | test_dropdown_54 | Automated |

### Dependency / Lifecycle (TC-D) & State (BC-SM)
| TC ID | Sub | BC | Description | Expected | Method | Status |
|-------|-----|----|-------------|----------|--------|--------|
| TC-D20 | F | BC-SM-01..04 | Full lifecycle at model layer | passes | test_dropdown_20 | Automated |
| TC-D21 | B | BC-SM-02 | Soft delete keeps row + deleted_at | ok | test_dropdown_21 | Automated |
| TC-D22 | F | BC-SM-03 | Restore clears deleted_at | ok | test_dropdown_22 | Automated |
| TC-D40 | — | BC-REF-01 | Junction table(s) exist | ok | test_dropdown_40 | Automated |
| TC-D41 | — | BC-INT-01 | belongsToMany pivot table | correct | test_dropdown_41 | Automated |
| TC-D42 | — | BC-REF-01 | DDL FK → sys_dropdown_table | ok | test_dropdown_42 | Automated |

### Edge / Security / Tenancy (TC-EDG / TC-S / TC-T)
| TC ID | BC | Description | Expected | Method | Status |
|-------|----|-------------|----------|--------|--------|
| TC-EDG70 | BC-EDG-01 | ordinal tinyint unsigned | ok | test_dropdown_70 | Automated |
| TC-EDG71 | BC-EDG-02 | key/value lengths | 160/100 | test_dropdown_71 | Automated |
| TC-EDG72 | BC-EDG-03 | trashed key+value recreation collides | collision | test_dropdown_72 | Automated (DEV-006) |
| TC-EDG73 | BC-EDG-04 | store global key uniqueness | proven | test_dropdown_73 | Automated (DEV-004) |
| TC-T90 | routes | central.global-master routes | all registered | test_dropdown_90 | Automated |
| TC-S91 | security | invalid edit id not valid | 404/login | test_dropdown_91 | Automated |
| TC-S92 | security | search parameterized | no SQL error | test_dropdown_92 | Automated |

---

## 3. Test Method Index (semantic bands)
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_dropdown_01_migration_model_and_request_configuration_are_correct | TC-P01 | Config truth | 01–09 |
| 2 | test_dropdown_02_unique_indexes_exist_on_key_value_and_key_ordinal | TC-P02 | Schema | 01–09 |
| 3 | test_dropdown_03_type_enum_matches_ddl_and_formrequest_seven_values | TC-P03 | Schema | 01–09 |
| 4 | test_dropdown_04_soft_delete_column_present_despite_consolidated_ddl_gap | TC-N04 | Schema/DEV | 01–09 |
| 5 | test_dropdown_05_central_activity_log_sink_table_and_model_configured | TC-P05 | Config | 01–09 |
| 6 | test_dropdown_10_model_default_attributes_are_string_and_active | TC-P10 | BC-BIZ | 10–19 |
| 7 | test_dropdown_11_additional_info_is_cast_to_array | TC-P11 | BC-BIZ | 10–19 |
| 8 | test_dropdown_12_store_and_update_do_not_emit_activity_log | TC-N12 | BC-BIZ/DEV | 10–19 |
| 9 | test_dropdown_13_destroy_uses_out_of_scope_dropdown_variable_for_activity_log | TC-N13 | BC-BIZ/DEV | 10–19 |
| 10 | test_dropdown_14_destroy_and_restore_target_inconsistent_junction_models | TC-N14 | BC-BIZ/DEV | 10–19 |
| 11 | test_dropdown_15_addbyselection_and_quicksave_use_removed_str_slug_helper | TC-N15 | BC-BIZ/DEV | 10–19 |
| 12 | test_dropdown_20_lifecycle_create_toggle_softdelete_restore_forcedelete | TC-D20 | BC-SM | 20–29 |
| 13 | test_dropdown_21_soft_delete_sets_deleted_at_and_keeps_row | TC-D21 | BC-SM | 20–29 |
| 14 | test_dropdown_22_restore_clears_deleted_at | TC-D22 | BC-SM | 20–29 |
| 15 | test_dropdown_30_request_rules_contain_expected_strings | TC-N30 | BC-VAL | 30–39 |
| 16 | test_dropdown_31_key_unique_message_is_custom | TC-N31 | BC-VAL | 30–39 |
| 17 | test_dropdown_32_store_inline_rules_present_in_controller | TC-N32 | BC-VAL | 30–39 |
| 18 | test_dropdown_33_togglestatus_requires_boolean_is_active | TC-N33 | BC-VAL | 30–39 |
| 19 | test_dropdown_34_savedropdownoption_type_enum_is_narrower_than_ddl | TC-N34 | BC-VAL/DEV | 30–39 |
| 20 | test_dropdown_40_junction_tables_exist_and_reference_dropdown_table | TC-D40 | BC-REF | 40–49 |
| 21 | test_dropdown_41_model_relationship_dropdownNeeds_configured | TC-D41 | BC-INT | 40–49 |
| 22 | test_dropdown_42_ddl_fk_targets_sys_dropdown_table_not_sys_dropdowns | TC-D42 | BC-REF | 40–49 |
| 23 | test_dropdown_50_controller_methods_enforce_expected_gates | TC-N50 | BC-AUTH | 50–59 |
| 24 | test_dropdown_51_request_authorize_maps_actions_to_gates | TC-N51 | BC-AUTH | 50–59 |
| 25 | test_dropdown_52_guest_is_redirected_to_login_from_index | TC-N52 | BC-AUTH | 50–59 |
| 26 | test_dropdown_53_guest_cannot_reach_trash_view | TC-N53 | BC-AUTH | 50–59 |
| 27 | test_dropdown_54_limited_user_is_denied_dropdown_gates | TC-N54 | BC-AUTH | 50–59 |
| 28 | test_dropdown_60_index_page_loads_for_admin | TC-P60 | UI | 60–69 |
| 29 | test_dropdown_61_index_shows_dropdown_list_pane | TC-P61 | UI | 60–69 |
| 30 | test_dropdown_62_index_list_filter_inputs_present | TC-P62 | UI | 60–69 |
| 31 | test_dropdown_63_trash_view_loads_with_expected_columns | TC-P63 | UI | 60–69 |
| 32 | test_dropdown_64_index_breadcrumb_title_is_dropdown_management | TC-P64 | UI | 60–69 |
| 33 | test_dropdown_65_create_route_is_registered_and_named | TC-P65 | UI | 60–69 |
| 34 | test_dropdown_70_ordinal_column_is_tinyint_unsigned | TC-EDG70 | Edge | 70–79 |
| 35 | test_dropdown_71_key_and_value_declared_lengths | TC-EDG71 | Edge | 70–79 |
| 36 | test_dropdown_72_soft_deleted_key_value_blocks_recreation | TC-EDG72 | Edge/DEV | 70–79 |
| 37 | test_dropdown_73_store_global_key_uniqueness_conflicts_with_composite_design | TC-EDG73 | Edge/DEV | 70–79 |
| 38 | test_dropdown_90_prime_routes_are_registered_under_central_global_master | TC-T90 | Tenancy/route | 90–99 |
| 39 | test_dropdown_91_edit_invalid_id_is_not_a_valid_record | TC-S91 | Security | 90–99 |
| 40 | test_dropdown_92_search_endpoint_is_parameterized | TC-S92 | Security | 90–99 |
| 41 | test_dropdown_93_ajax_and_bulk_routes_are_registered | TC-P93 | Route | 90–99 |

**Total: 41 methods.**
