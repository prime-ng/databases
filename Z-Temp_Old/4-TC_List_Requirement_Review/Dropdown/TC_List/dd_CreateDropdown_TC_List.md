# dd_CreateDropdown — Test Case List & Business Conditions

**Module:** DropDown (CODE `DD`, prefix `dd_`) · **Feature:** Create Dropdown (inline management of dropdown values for a selected need)
**DB scope:** CENTRAL-side (`sys_dropdown_table`, `sys_dropdown_needs`, `sys_dropdown_need_dropdowns_jnt`) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary tables:** `sys_dropdown_table`, `sys_dropdown_need_dropdowns_jnt` · **Module URL prefix:** `/global-master/dropdown?tab=dropdown-need-mgmt`
**Test file:** `dd_CreateDropdown_TestCas.php`
**Tabs:** Create Dropdown (third tab of the Global Master Dropdown module)

Controller:
- `DropdownMgmtController::index` — listing for Create Dropdown tab
- `DropdownMgmtController::storeDropdownOption` — AJAX save new dropdown option
- `DropdownController::store` — create dropdown record
- `DropdownController::quickSave` — AJAX inline quick-save
- `DropdownController::addBySelection` — AJAX add by selection

Routes:
- `GET /global-master/dropdown?tab=dropdown-need-mgmt` — DropdownController@index (shows dropdown-need-mgmt tab content)
- `POST /global-master/dropdown/store-option` — DropdownMgmtController@storeDropdownOption
- `POST /global-master/dropdown/add-by-selection` — DropdownController@addBySelection
- `POST /global-master/dropdowns/save-option` — DropdownController@saveDropdownOption
- `GET /global-master/dropdown/get-dropdown-need-details/{id}` — DropdownController@getDropdownNeedDetails
- `GET /global-master/dropdown/get-mapped-options/{needId}/{key}` — DropdownController@getMappedOptions
- `GET /global-master/dropdown/check-key-mapped/{needId}/{key}` — DropdownController@checkKeyMapped

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Tables: `sys_dropdown_table`, `sys_dropdown_needs`, `sys_dropdown_need_dropdowns_jnt` with SoftDeletes | DDL |
| BC-DB-02 | Junction table `sys_dropdown_need_dropdowns_jnt`: dropdown_needs_id FK, dropdown_table_id FK, is_active BOOLEAN | DropdownNeedDropdown.php:10 |
| BC-DB-03 | Model `DropdownNeedDropdown`: table `sys_dropdown_need_dropdowns_jnt`, fillable: [dropdown_needs_id, dropdown_table_id, is_active] | DropdownNeedDropdown.php:12-16 |

### BC-VAL — Validation
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | store: `key` required string max:160 unique:sys_dropdown_table | DropdownCtrl:518 |
| BC-VAL-02 | store: `ordinal` nullable integer min:1 | DropdownCtrl:519 |
| BC-VAL-03 | store: `value` required string max:100 | DropdownCtrl:520 |
| BC-VAL-04 | store: `type` required in:String,Integer,Decimal,Date,Datetime,Time,Boolean | DropdownCtrl:521 |
| BC-VAL-05 | store: `additional_info` nullable string | DropdownCtrl:522 |
| BC-VAL-06 | storeDropdownOption: `dropdown_needs_id` required exists, `ordinal` required integer, `value` required max:255, `additional_info` nullable string | DropdownMgmtCtrl:265-270 |
| BC-VAL-07 | addBySelection: `parent_id` required exists:sys_dropdown_needs, `ordinal` required integer, `value` required max:255, `key` nullable | DropdownCtrl:949-953 |
| BC-VAL-08 | quickSave: `dropdown_need_id` required, `ordinal` required integer, `value` required max:255 | DropdownCtrl:1152-1156 |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | store() gate `prime.dropdown.create` | DropdownCtrl:503 |
| BC-AUTH-02 | storeDropdownOption gate `prime.dropdown.create` | DropdownMgmtCtrl:263 |
| BC-AUTH-03 | addBySelection/quickSave gate `prime.dropdown.create` | DropdownCtrl:946,1149 |
| BC-AUTH-04 | Permissions check via `canManageDropdownNeed()`: Super Admin/PRIME = full access; TEACHER/EMPLOYEE = only if need.tenant_creation_allowed=true | DropdownCtrl:1362-1375 |
| BC-AUTH-05 | Permissions check via `canUserManageDropdown()`: same rules but checks all linked needs | DropdownCtrl:1377-1398 |
| BC-AUTH-06 | storeDropdownOption inline check: same logic as canManageDropdownNeed | DropdownMgmtCtrl:282-292 |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Create Dropdown tab shows cascading menu filters (Category → Main Menu → Sub Menu → Tab → Field) to select a need | View |
| BC-BIZ-02 | After selecting a need via filters, mapped and unmapped dropdowns for that need are shown | DropdownNeedCtrl:169-217 |
| BC-BIZ-03 | Inline Add form allows entering new key+value+type+ordinal for the selected need | View |
| BC-BIZ-04 | store() auto-generates ordinal if not provided (max ordinal + 1) | DropdownCtrl:537-545 |
| BC-BIZ-05 | store() creates dropdown and junction entry in a transaction | DropdownCtrl:536-563 |
| BC-BIZ-06 | storeDropdownOption auto-generates key from `table_name.column_name`, sets type='String', saves via AJAX | DropdownMgmtCtrl:294-301 |
| BC-BIZ-07 | addBySelection auto-generates key if not provided (slug + timestamp), creates dropdown + junction | DropdownCtrl:962-983 |
| BC-BIZ-08 | quickSave auto-generates key (slug + timestamp), creates dropdown + junction | DropdownCtrl:1158-1183 |
| BC-BIZ-09 | saveDropdownOption does NOT auto-map; creates dropdown and optionally maps if dropdown_need_id provided | DropdownCtrl:896-938 |
| BC-BIZ-10 | getDropdownNeedDetails returns table_name, column_name, db_type, suggested_key for a need | DropdownCtrl:1055-1065 |
| BC-BIZ-11 | getMappedOptions returns options already mapped to a need+key | DropdownCtrl:1238-1249 |
| BC-BIZ-12 | checkKeyMapped returns whether a key is already mapped to a need | DropdownCtrl:1223-1233 |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | store() without dropdown_need_id → error "Please select a dropdown need first!" | DropdownCtrl:530-531 |
| BC-EDG-02 | TEACHER/EMPLOYEE trying to manage need with tenant_creation_allowed=false → 403 | DropdownCtrl:1369-1371 |
| BC-EDG-03 | Duplicate key on store → validation error (unique:sys_dropdown_table) | DropdownCtrl:518 |
| BC-EDG-04 | storeDropdownOption with non-existent dropdown_needs_id → 404 | DropdownMgmtCtrl:274-279 |
| BC-EDG-05 | addBySelection with non-existent parent_id → 422 | DropdownCtrl:949 |
| BC-EDG-06 | AJAX exception → 500 JSON error response | DropdownCtrl:933-938 |

---

## 2. Test Case List

### Screen 1: Create Dropdown Tab (GET /global-master/dropdown?tab=dropdown-need-mgmt)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDCR-P10 | Positive | View | Create Dropdown tab renders with cascading menu filters and inline add form | Page rendered | test_ddcr_10 | Automated |
| TC-DDCR-P11 | Positive | View | Category dropdown populated from existing needs | Populated | test_ddcr_11 | Automated |
| TC-DDCR-P12 | Positive | View | Main Menu loads via AJAX when Category selected | Populated | test_ddcr_12 | Automated |
| TC-DDCR-P13 | Positive | View | Sub Menu loads via AJAX when Main Menu selected | Populated | test_ddcr_13 | Automated |
| TC-DDCR-P14 | Positive | View | Tab Name loads via AJAX when Sub Menu selected | Populated | test_ddcr_14 | Automated |
| TC-DDCR-P15 | Positive | View | Field Name loads via AJAX when Tab Name selected | Populated | test_ddcr_15 | Automated |
| TC-DDCR-P16 | Positive | View | Selecting a field name identifies the dropdown need and shows inline management panel | Panel shown | test_ddcr_16 | Automated |
| TC-DDCR-P17 | Positive | View | Mapped dropdowns listed for selected need | Listed | test_ddcr_17 | Automated |
| TC-DDCR-P18 | Positive | View | Unmapped dropdowns listed for selected need | Listed | test_ddcr_18 | Automated |
| TC-DDCR-P19 | Positive | View | Inline Add form with key, ordinal, value, type fields | Form rendered | test_ddcr_19 | Automated |

### Screen 2: Store — Full Create (POST /global-master/dropdown)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDCR-P30 | Positive | Ctrl | Store creates dropdown with all fields | Row created | test_ddcr_30 | Automated |
| TC-DDCR-P31 | Positive | Ctrl | Store auto-generates ordinal (max+1) when not provided | Ordinal auto | test_ddcr_31 | Automated |
| TC-DDCR-P32 | Positive | Ctrl | Store creates junction entry linking to dropdown need | Junction created | test_ddcr_32 | Automated |
| TC-DDCR-P33 | Positive | Ctrl | Store redirects to global-master.dropdown.index with success flash | Redirect + flash | test_ddcr_33 | Automated |
| TC-DDCR-N34 | Negative | Ctrl | Store without dropdown_need_id → error | Error | test_ddcr_34 | Automated |
| TC-DDCR-N35 | Negative | Ctrl | Store with duplicate key → 422 | 422 | test_ddcr_35 | Automated |
| TC-DDCR-N36 | Negative | Ctrl | Store with empty value → 422 | 422 | test_ddcr_36 | Automated |
| TC-DDCR-N37 | Negative | Ctrl | Store with invalid type → 422 | 422 | test_ddcr_37 | Automated |

### Screen 3: Store Dropdown Option — AJAX (POST /global-master/dropdown/store-option)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDCR-P40 | Positive | Ctrl | storeDropdownOption creates dropdown via AJAX, auto-generates key, returns JSON success | Created | test_ddcr_40 | Automated |
| TC-DDCR-N41 | Negative | Ctrl | storeDropdownOption with invalid need id → 404 | 404 | test_ddcr_41 | Automated |
| TC-DDCR-N42 | Negative | Ctrl | storeDropdownOption with empty value → 422 | 422 | test_ddcr_42 | Automated |
| TC-DDCR-N43 | Negative | Ctrl | TEACHER with tenant_creation_allowed=false → 403 | 403 | test_ddcr_43 | Automated |

### Screen 4: Add By Selection — AJAX (POST /global-master/dropdown/add-by-selection)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDCR-P50 | Positive | Ctrl | addBySelection creates dropdown + junction via AJAX, returns JSON success | Created + JSON | test_ddcr_50 | Automated |
| TC-DDCR-P51 | Positive | Ctrl | addBySelection auto-generates key when not provided | Key auto | test_ddcr_51 | Automated |
| TC-DDCR-N52 | Negative | Ctrl | addBySelection with non-existent parent_id → 422 | 422 | test_ddcr_52 | Automated |

### Screen 5: Quick Save — AJAX (POST /global-master/dropdowns/save-option)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDCR-P60 | Positive | Ctrl | quickSave creates dropdown + junction via AJAX, returns JSON success | Created + JSON | test_ddcr_60 | Automated |
| TC-DDCR-N61 | Negative | Ctrl | quickSave with missing required fields → 422 | 422 | test_ddcr_61 | Automated |

### Cross-Cutting

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDCR-P01 | Schema | DDL/Model | All CRUD tables and models exist | All pass | test_ddcr_01 | Automated |
| TC-DDCR-P02 | Route | Routes | All create dropdown routes registered | Present | test_ddcr_02 | Automated |
| TC-DDCR-P05 | Auth | Ctrl | Guest redirected to /login | /login | test_ddcr_05 | Automated |
| TC-DDCR-N07 | Auth | Ctrl | User without prime.dropdown.create → 403 on store | 403 | test_ddcr_07 | Automated |
| TC-DDCR-N08 | Auth | Ctrl | User without prime.dropdown-need-mgmt.viewAny → 403 on index | 403 | test_ddcr_08 | Automated |

---

## 3. Test Method Index

### File: `dd_CreateDropdown_TestCas.php` (estimated XX methods)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_ddcr_01_crud_tables_and_models | TC-DDCR-P01 | Schema | 01-04 |
| 2 | test_ddcr_02_routes_registered | TC-DDCR-P02 | Schema | 01-04 |
| 3 | test_ddcr_05_guest_redirected_to_login | TC-DDCR-P05 | Auth | 05-09 |
| 4 | test_ddcr_07_user_without_create_permission_403 | TC-DDCR-N07 | Auth | 05-09 |
| 5 | test_ddcr_08_user_without_mgmt_viewAny_403 | TC-DDCR-N08 | Auth | 05-09 |
| 6 | test_ddcr_10_create_dropdown_tab_renders | TC-DDCR-P10 | List | 10-29 |
| 7 | test_ddcr_11_category_dropdown_populated | TC-DDCR-P11 | List | 10-29 |
| 8 | test_ddcr_12_main_menu_loads_via_ajax | TC-DDCR-P12 | List | 10-29 |
| 9 | test_ddcr_13_sub_menu_loads_via_ajax | TC-DDCR-P13 | List | 10-29 |
| 10 | test_ddcr_14_tab_name_loads_via_ajax | TC-DDCR-P14 | List | 10-29 |
| 11 | test_ddcr_15_field_name_loads_via_ajax | TC-DDCR-P15 | List | 10-29 |
| 12 | test_ddcr_16_field_selection_shows_mgmt_panel | TC-DDCR-P16 | List | 10-29 |
| 13 | test_ddcr_17_mapped_dropdowns_listed | TC-DDCR-P17 | List | 10-29 |
| 14 | test_ddcr_18_unmapped_dropdowns_listed | TC-DDCR-P18 | List | 10-29 |
| 15 | test_ddcr_19_inline_add_form_rendered | TC-DDCR-P19 | List | 10-29 |
| 16 | test_ddcr_30_store_creates_dropdown | TC-DDCR-P30 | Store | 30-39 |
| 17 | test_ddcr_31_store_auto_generates_ordinal | TC-DDCR-P31 | Store | 30-39 |
| 18 | test_ddcr_32_store_creates_junction | TC-DDCR-P32 | Store | 30-39 |
| 19 | test_ddcr_33_store_redirects_with_success | TC-DDCR-P33 | Store | 30-39 |
| 20 | test_ddcr_34_store_without_need_id | TC-DDCR-N34 | Store | 30-39 |
| 21 | test_ddcr_35_store_duplicate_key | TC-DDCR-N35 | Store | 30-39 |
| 22 | test_ddcr_36_store_empty_value | TC-DDCR-N36 | Store | 30-39 |
| 23 | test_ddcr_37_store_invalid_type | TC-DDCR-N37 | Store | 30-39 |
| 24 | test_ddcr_40_store_option_ajax | TC-DDCR-P40 | AJAX | 40-49 |
| 25 | test_ddcr_41_store_option_invalid_need | TC-DDCR-N41 | AJAX | 40-49 |
| 26 | test_ddcr_42_store_option_empty_value | TC-DDCR-N42 | AJAX | 40-49 |
| 27 | test_ddcr_43_store_option_unauthorized_teacher | TC-DDCR-N43 | AJAX | 40-49 |
| 28 | test_ddcr_50_add_by_selection_ajax | TC-DDCR-P50 | AJAX | 50-59 |
| 29 | test_ddcr_51_add_by_selection_auto_key | TC-DDCR-P51 | AJAX | 50-59 |
| 30 | test_ddcr_52_add_by_selection_invalid_parent | TC-DDCR-N52 | AJAX | 50-59 |
| 31 | test_ddcr_60_quick_save_ajax | TC-DDCR-P60 | AJAX | 60-69 |
| 32 | test_ddcr_61_quick_save_missing_fields | TC-DDCR-N61 | AJAX | 60-69 |

**Total: 32 methods (32 Automated, 0 Planned).**
