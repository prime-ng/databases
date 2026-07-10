# sys_DropdownMgmt — Test Case List & Business Conditions

- **Module:** Prime (PRM) — **CENTRAL** (`prime_db`), no tenant init, host `http://127.0.0.1:8000`
- **Feature/Screen:** DropdownMgmt (composite management screen)
- **Primary tables:** `sys_dropdown_needs`, `sys_dropdown_table` (runtime VALUES — constraint #27), `sys_dropdown_need_table_jnt`
- **Prefix (DDL-verified):** `sys_`
- **Controller:** `Modules\Prime\Http\Controllers\DropdownMgmtController`
- **Models:** `DropdownNeed`, `Dropdown`, `DropdownNeedTableJnt`, `DropdownNeedDropdown`, `DropdownMgmtModel` (scaffold)
- **Route group:** `Route::domain(...)->name('central.')` → `prefix('global-master')->name('global-master.')` ⇒ names `central.global-master.dropdown-mgmt.*`
- **Index URL:** `/global-master/dropdown-mgmt`
- **Activity sink:** central `sys_central_activity_logs` via `Modules\Prime\Models\ActivityLog` (constraint #25)
- **Requirement source:** No `Prime_v1` screen file exists (Prime is central infra). BCs derived from DDL `_prime_db_v4.sql`, the controller, models, routes, and the composite view `prime::index` / `prime::dropdown-need-mgmt.index`.

> This is a **composite** screen: dropdown "needs" (definitions) + dropdown "values" (options) + a junction. Several sub-flows are **thin/stub** in source (documented as gaps/defects below, not invented coverage).

---

## 1. Business Conditions

### BC-DB (DDL — `_prime_db_v4.sql`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `sys_dropdown_needs` columns: id, db_type ENUM(Prime,Tenant,Global), table_name/column_name varchar(150), menu_category/main_menu/sub_menu varchar(150) NULL, tab_name/field_name varchar(100) NULL, is_system/tenant_creation_allowed/compulsory/dropdown_tabel_record_exist/is_active TINYINT(1), timestamps | DDL-sys_dropdown_needs |
| BC-DB-02 | `sys_dropdown_needs` UNIQUE(db_type, table_name, column_name) | DDL-sys_dropdown_needs |
| BC-DB-03 | `sys_dropdown_needs` UNIQUE(menu_category, main_menu, sub_menu, tab_name, field_name) | DDL-sys_dropdown_needs |
| BC-DB-04 | `sys_dropdown_table` columns: id, ordinal TINYINT UNSIGNED, key varchar(160), value varchar(100), type ENUM(String,Integer,Decimal,Date,Datetime,Time,Boolean) default String, additional_info JSON, is_active | DDL-sys_dropdown_table |
| BC-DB-05 | `sys_dropdown_table` UNIQUE(key, ordinal) and UNIQUE(key, value) | DDL-sys_dropdown_table |
| BC-DB-06 | `sys_dropdown_need_table_jnt` FK dropdown_needs_id → sys_dropdown_needs.id; FK dropdown_table_id → sys_dropdown_table.id | DDL-sys_dropdown_need_table_jnt |
| BC-DB-07 | `DropdownNeed` & `Dropdown` use `SoftDeletes`; `Dropdown::$table = 'sys_dropdown_table'` (constraint #27) | Models |

### BC-VAL (controller inline validation)
| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | store/update `db_type` required, `in:Prime,Tenant,Global` | Controller-store/update |
| BC-VAL-02 | `table_name`, `column_name` required string max:150 | Controller |
| BC-VAL-03 | `tenant_creation_allowed`, `is_system`, `compulsory`, `is_active` required boolean | Controller |
| BC-VAL-04 | `menu_category`/`main_menu`/`sub_menu` nullable max:150; `tab_name`/`field_name` nullable max:100 | Controller |
| BC-VAL-05 | storeDropdownOption `dropdown_needs_id` required `exists:sys_dropdown_needs,id` | Controller-storeDropdownOption |
| BC-VAL-06 | storeDropdownOption `ordinal` required integer; `value` required string max:255; `additional_info` nullable string | Controller-storeDropdownOption |

### BC-AUTH (gates — exact strings)
| ID | Gate | Method | Source |
|----|------|--------|--------|
| BC-AUTH-01 | `prime.dropdown-need-mgmt.viewAny` | index | Controller |
| BC-AUTH-02 | `prime.dropdown-need-mgmt.create` | create, store | Controller |
| BC-AUTH-03 | `prime.dropdown-need-mgmt.view` | show | Controller |
| BC-AUTH-04 | `prime.dropdown-need-mgmt.update` | edit, update | Controller |
| BC-AUTH-05 | `prime.dropdown-need-mgmt.delete` | deleteBulk (unreachable) | Controller |
| BC-AUTH-06 | `prime.dropdown.create` | storeDropdownOption | Controller |
| BC-AUTH-07 | storeDropdownOption in-code matrix: `is_super_admin` OR `user_type=='PRIME'` OR (`user_type` in TEACHER/EMPLOYEE AND `tenant_creation_allowed`); else 403 "Unauthorized: You do not have permission…" | Controller |

### BC-BIZ (business logic / activity)
| ID | Behaviour | Source |
|----|-----------|--------|
| BC-BIZ-01 | store() creates a `DropdownNeed`, then `activityLog($need, 'Created', …)` → **central** `sys_central_activity_logs` | Controller + constraint #25 |
| BC-BIZ-02 | storeDropdownOption() builds `key = table_name . '.' . column_name` | Controller |
| BC-BIZ-03 | storeDropdownOption() forces `type='String'` and stores `additional_info` as `json_encode(['info'=>…])` | Controller |
| BC-BIZ-04 | update() persists changes but writes **no** activity log (only store logs) | Controller |
| BC-BIZ-05 | Cascading menu endpoints (byCategory/byMain/bySub/byTab/meta) pluck distinct menu values | Controller |
| BC-BIZ-06 | index() lists needs, search LIKE on table_name/column_name, `paginate(10)`, view `prime::dropdown-need-mgmt.index` | Controller |
| BC-BIZ-07 | filter() renders composite `prime::index` with groupedDropdowns/dropdownNeeds/dropdowns/categories/… | Controller |

### BC-REF / BC-INT
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | Junction FKs reference needs + values tables (no explicit ON DELETE in DDL) | DDL |
| BC-INT-01 | Active relationship `DropdownNeed::dropdowns()` uses pivot `sys_dropdown_need_dropdowns_jnt` (model `DropdownNeedDropdown`), NOT the DDL junction | Models |

### BC-EDG (edge / defects)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `destroy()` is an empty method → DELETE is a no-op (record persists) | Controller (DEV-DDM-001) |
| BC-EDG-02 | `edit()`→`view('prime::edit')` and non-JSON `show()`→`view('prime::show')` reference templates absent at module root | Controller/Views (DEV-DDM-002) |
| BC-EDG-03 | Two junction tables mixed: `dropdowns()` pivot vs `scopeWithActiveDropdownCount()` reference | Models (DEV-DDM-003) |
| BC-EDG-04 | `DropdownMgmtController::deleteBulk` is unreachable (route → DropdownController) | Routes (DEV-DDM-004) |
| BC-EDG-05 | storeDropdownOption has no app-level guard for UNIQUE(key,ordinal)/(key,value) → raw DB 500 on duplicate | Controller+DDL (DEV-DDM-005) |
| BC-EDG-06 | `DropdownMgmtModel` is an unused scaffold (empty `$fillable`, no `$table`) | Model (DEV-DDM-006) |
| BC-EDG-07 | `DropdownNeed::$fillable` has `dropdown_table_record_exist`; DDL column is misspelled `dropdown_tabel_record_exist` | Model vs DDL (DEV-DDM-007) |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-*/VAL/AUTH/BIZ | DDL/Ctrl | Schema+model+controller config truth | All asserts pass | `test_dropdownmgmt_01_*` | Automated |
| TC-P10 | BC-BIZ-01 | Ctrl | store persists need + logs 'Created' | Row + central log | `test_dropdownmgmt_10_*` | Automated |
| TC-P11 | BC-BIZ-02 | Ctrl | store-option builds key | key=table.column | `test_dropdownmgmt_11_*` | Automated |
| TC-P12 | BC-BIZ-03 | Ctrl | type=String, JSON info | Persisted correctly | `test_dropdownmgmt_12_*` | Automated |
| TC-P13 | BC-BIZ-04 | Ctrl | update persists changes | menu_category updated | `test_dropdownmgmt_13_*` | Automated |
| TC-P14 | BC-BIZ-05 | Ctrl | cascading menu endpoint | 200 distinct list | `test_dropdownmgmt_14_*` | Automated |
| TC-P15 | BC-BIZ-06 | Ctrl | index paginate(10) | source truth | `test_dropdownmgmt_15_*` | Automated |
| TC-P16 | BC-BIZ-07 | Ctrl | filter composite view | datasets passed | `test_dropdownmgmt_16_*` | Automated |
| TC-P60 | BC-BIZ-06 | View | index loads for admin | no 403/404/login | `test_dropdownmgmt_60_*` | Automated |
| TC-P61 | BC-BIZ-07 | View | filter tabbed view renders | Dropdown content | `test_dropdownmgmt_61_*` | Automated |
| TC-P62 | BC-BIZ-06 | Ctrl | search LIKE table/column | source truth | `test_dropdownmgmt_62_*` | Automated |
| TC-P90 | Routes | web.php | all route names registered | Route::has all | `test_dropdownmgmt_90_*` | Automated |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N30 | BC-VAL-01/02 | Ctrl | store missing core fields | 302/422 errors | `test_dropdownmgmt_30_*` | Automated |
| TC-N31 | BC-VAL-01 | Ctrl | store invalid db_type enum | error db_type | `test_dropdownmgmt_31_*` | Automated |
| TC-N32 | BC-VAL-03 | Ctrl | store missing boolean flags | errors | `test_dropdownmgmt_32_*` | Automated |
| TC-N33 | BC-VAL-02 | Ctrl | table_name > 150 | error | `test_dropdownmgmt_33_*` | Automated |
| TC-N34 | BC-VAL-05/06 | Ctrl | store-option missing fields | 422 errors | `test_dropdownmgmt_34_*` | Automated |
| TC-N35 | BC-VAL-05 | Ctrl | store-option unknown need id | 422 exists | `test_dropdownmgmt_35_*` | Automated |
| TC-N36 | BC-VAL-06 | Ctrl | value > 255 | 422 | `test_dropdownmgmt_36_*` | Automated |
| TC-N37 | BC-VAL-06 | Ctrl | ordinal non-integer | 422 | `test_dropdownmgmt_37_*` | Automated |
| TC-N50 | BC-AUTH-01 | Ctrl | guest → login | redirect | `test_dropdownmgmt_50_*` | Automated |
| TC-N53 | BC-AUTH-02 | Ctrl | unauth POST no create | count unchanged | `test_dropdownmgmt_53_*` | Automated |

### Dependency / Integrity (TC-D)
| TC ID | Sub | BC | Description | Expected | Method | Status |
|-------|-----|----|-------------|----------|--------|--------|
| TC-D40 | C/G | BC-DB-02 | UNIQUE(db_type,table,column) | integrity exception | `test_dropdownmgmt_40_*` | Automated |
| TC-D41 | G | BC-DB-05/EDG-05 | UNIQUE(key,ordinal) DB-only, no app guard | index present, no unique rule | `test_dropdownmgmt_41_*` | Automated |
| TC-D42 | G | BC-DB-05 | UNIQUE(key,value) | index present | `test_dropdownmgmt_42_*` | Automated |
| TC-D43 | — | BC-REF-01 | junction FK targets | columns present | `test_dropdownmgmt_43_*` | Automated |
| TC-D44 | E | BC-INT-01/EDG-03 | mixed junction tables | both referenced | `test_dropdownmgmt_44_*` | Automated |
| TC-D70 | B | BC-EDG-01 | destroy stub no-op | record persists | `test_dropdownmgmt_70_*` | Automated |

### Permissions (TC-AUTH)
| TC ID | BC | Description | Method |
|-------|----|-------------|--------|
| TC-AUTH-51 | BC-AUTH-01..06 | gate strings exact | `test_dropdownmgmt_51_*` |
| TC-AUTH-52 | BC-AUTH-07 | store-option matrix | `test_dropdownmgmt_52_*` |

### Edge / Defect (TC-EDG)
| TC ID | DEV | Description | Method |
|-------|-----|-------------|--------|
| TC-N71 | DEV-DDM-002 | prime::edit/show missing | `test_dropdownmgmt_71_*` |
| TC-EDG-72 | DEV-DDM-006 | scaffold model unused | `test_dropdownmgmt_72_*` |
| TC-EDG-73 | DEV-DDM-007 | fillable/DDL typo mismatch | `test_dropdownmgmt_73_*` |
| TC-EDG-74 | DEV-DDM-004 | deleteBulk unreachable | `test_dropdownmgmt_74_*` |
| TC-EDG-75 | BC-BIZ-04 | update writes no log | `test_dropdownmgmt_75_*` |

### Security / Tenancy (TC-S / TC-T)
| TC ID | BC | Description | Method |
|-------|----|-------------|--------|
| TC-S91 | BC-BIZ-02 | XSS value stored raw | `test_dropdownmgmt_91_*` |
| TC-T92 | Constraint #25 | central scope, no tenant init | `test_dropdownmgmt_92_*` |

---

## 3. Test Method Index (bands)

| # | Method | TC Map | Band |
|---|--------|--------|------|
| 1 | test_dropdownmgmt_01_schema_model_and_controller_configuration_are_correct | TC-P01 | 01-09 config |
| 2 | test_dropdownmgmt_10_store_dropdown_need_persists_and_logs_created_activity | TC-P10 | 10-19 biz |
| 3 | test_dropdownmgmt_11_store_option_builds_key_from_table_and_column | TC-P11 | 10-19 |
| 4 | test_dropdownmgmt_12_store_option_sets_type_string_and_json_additional_info | TC-P12 | 10-19 |
| 5 | test_dropdownmgmt_13_update_dropdown_need_persists_changes | TC-P13 | 10-19 |
| 6 | test_dropdownmgmt_14_cascading_menu_endpoints_return_distinct_values | TC-P14 | 10-19 |
| 7 | test_dropdownmgmt_15_index_paginates_dropdown_needs | TC-P15 | 10-19 |
| 8 | test_dropdownmgmt_16_filter_returns_composite_view_data | TC-P16 | 10-19 |
| 9 | test_dropdownmgmt_30_store_requires_core_fields | TC-N30 | 30-39 val |
| 10 | test_dropdownmgmt_31_store_rejects_invalid_db_type_enum | TC-N31 | 30-39 |
| 11 | test_dropdownmgmt_32_store_requires_boolean_flags | TC-N32 | 30-39 |
| 12 | test_dropdownmgmt_33_store_respects_max_length_150 | TC-N33 | 30-39 |
| 13 | test_dropdownmgmt_34_store_option_requires_core_fields | TC-N34 | 30-39 |
| 14 | test_dropdownmgmt_35_store_option_rejects_unknown_need_reference | TC-N35 | 30-39 |
| 15 | test_dropdownmgmt_36_store_option_value_max_255 | TC-N36 | 30-39 |
| 16 | test_dropdownmgmt_37_store_option_ordinal_must_be_integer | TC-N37 | 30-39 |
| 17 | test_dropdownmgmt_40_unique_dbtype_table_column_enforced | TC-D40 | 40-49 int |
| 18 | test_dropdownmgmt_41_dropdown_value_unique_key_ordinal_is_db_only | TC-D41 | 40-49 |
| 19 | test_dropdownmgmt_42_dropdown_value_unique_key_value_enforced | TC-D42 | 40-49 |
| 20 | test_dropdownmgmt_43_junction_fk_targets_are_correct | TC-D43 | 40-49 |
| 21 | test_dropdownmgmt_44_relationship_and_scope_mix_two_junction_tables | TC-D44 | 40-49 |
| 22 | test_dropdownmgmt_50_guest_redirected_to_login | TC-N50 | 50-59 auth |
| 23 | test_dropdownmgmt_51_controller_gates_match_expected_strings | TC-AUTH-51 | 50-59 |
| 24 | test_dropdownmgmt_52_store_option_authorization_matrix | TC-AUTH-52 | 50-59 |
| 25 | test_dropdownmgmt_53_unauthenticated_post_does_not_create | TC-N53 | 50-59 |
| 26 | test_dropdownmgmt_60_index_page_loads_for_admin | TC-P60 | 60-69 ui |
| 27 | test_dropdownmgmt_61_composite_filter_view_renders_tabs | TC-P61 | 60-69 |
| 28 | test_dropdownmgmt_62_index_search_filters_by_table_or_column | TC-P62 | 60-69 |
| 29 | test_dropdownmgmt_70_destroy_is_empty_stub_record_persists | TC-D70 | 70-79 edge |
| 30 | test_dropdownmgmt_71_edit_view_prime_edit_is_missing | TC-N71 | 70-79 |
| 31 | test_dropdownmgmt_72_dropdownmgmtmodel_is_unused_scaffold | TC-EDG-72 | 70-79 |
| 32 | test_dropdownmgmt_73_fillable_record_exist_column_typo_mismatch | TC-EDG-73 | 70-79 |
| 33 | test_dropdownmgmt_74_deletebulk_method_is_unreachable | TC-EDG-74 | 70-79 |
| 34 | test_dropdownmgmt_75_update_writes_no_activity_log | TC-EDG-75 | 70-79 |
| 35 | test_dropdownmgmt_90_all_routes_registered | TC-P90 | 90-99 wiring |
| 36 | test_dropdownmgmt_91_store_option_persists_xss_payload_raw | TC-S91 | 90-99 sec |
| 37 | test_dropdownmgmt_92_central_scope_has_no_tenant_initialization | TC-T92 | 90-99 tenancy |

## Known Source Defects (DEV-###)
| DEV | Severity | Summary | Proving test |
|-----|----------|---------|--------------|
| DEV-DDM-001 | High | `destroy()` empty → resource DELETE is a no-op | `test_dropdownmgmt_70_*` |
| DEV-DDM-002 | High | `edit()`/`show()` return non-existent `prime::edit`/`prime::show` views | `test_dropdownmgmt_71_*` |
| DEV-DDM-003 | Medium | Mixed junction tables (`sys_dropdown_need_dropdowns_jnt` vs `sys_dropdown_need_table_jnt`) | `test_dropdownmgmt_44_*` |
| DEV-DDM-004 | Low | `DropdownMgmtController::deleteBulk` unreachable dead code | `test_dropdownmgmt_74_*` |
| DEV-DDM-005 | Medium | No app-level guard on UNIQUE(key,ordinal)/(key,value) → raw 500 | `test_dropdownmgmt_41_*` |
| DEV-DDM-006 | Low | `DropdownMgmtModel` unused scaffold | `test_dropdownmgmt_72_*` |
| DEV-DDM-007 | Medium | `fillable` `dropdown_table_record_exist` vs DDL `dropdown_tabel_record_exist` | `test_dropdownmgmt_73_*` |

> All DEV items are reported "verify in source" — each is traced to the exact controller/model/DDL/route location cited above.
