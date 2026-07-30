# dd_Mapping — Test Case List & Business Conditions

**Module:** DropDown (CODE `DD`, prefix `dd_`) · **Feature:** Dropdown Need & Table Mapping (two-step map/unmap flow)
**DB scope:** CENTRAL-side (`sys_dropdown_needs`, `sys_dropdown_table`, `sys_dropdown_need_dropdowns_jnt`) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary junction table:** `sys_dropdown_need_dropdowns_jnt` · **Module URL prefix:** `/global-master/dropdown?tab=create-dropdown-jnt`
**Test file:** `dd_Mapping_TestCas.php`
**Tabs:** Dropdown Need & Table Mapping (fourth tab of the Global Master Dropdown module)

Controller:
- `DropdownController::index` — master index (renders create-dropdown-jnt tab content)
- `DropdownController::mapDropdownsToNeed` — AJAX bulk map
- `DropdownController::removeMapping` — AJAX bulk unmap
- `DropdownController::mapExistingOptions` — AJAX map existing options
- `DropdownController::saveDropdownOption` — AJAX create dropdown (with optional auto-map)
- `DropdownController::getByDropdownNeed` — AJAX get dropdowns by need

Routes:
- `GET /global-master/dropdown?tab=create-dropdown-jnt` — DropdownController@index (mapping tab)
- `POST /global-master/dropdowns/map-to-need` — DropdownController@mapDropdownsToNeed
- `POST /global-master/dropdowns/remove-mapping` — DropdownController@removeMapping
- `POST /global-master/dropdowns/map-existing-options` — DropdownController@mapExistingOptions
- `POST /global-master/dropdowns/save-option` — DropdownController@saveDropdownOption
- `GET /global-master/dropdown/{id}` — DropdownController@show
- `GET /global-master/dropdown/{id}/edit` — DropdownController@edit
- `PUT /global-master/dropdown/{id}` — DropdownController@update

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Junction table `sys_dropdown_need_dropdowns_jnt`: columns id (PK AI), dropdown_needs_id (FK), dropdown_table_id (FK), is_active (BOOLEAN), created_at, updated_at | DropdownNeedDropdown.php:10-16 |
| BC-DB-02 | Model `DropdownNeedDropdown`: SoftDeletes NOT used, casts is_active → boolean | DropdownNeedDropdown.php:18-20 |

### BC-VAL — Validation
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | mapDropdownsToNeed: `dropdown_needs_id` required exists, `dropdown_ids` required array each exists:sys_dropdown_table | DropdownCtrl:1072-1076 |
| BC-VAL-02 | removeMapping: `dropdown_needs_id` required exists, `dropdown_ids` required array each exists | DropdownCtrl:1120-1124 |
| BC-VAL-03 | mapExistingOptions: `dropdown_need_id` required exists, `option_ids` required array, `key` required string | DropdownCtrl:1255-1260 |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | mapDropdownsToNeed/removeMapping gate `prime.dropdown-need.update` | DropdownCtrl:1070,1118 |
| BC-AUTH-02 | mapExistingOptions implicitly requires `prime.dropdown.create` or `prime.dropdown-need.update` | DropdownCtrl:1256 |
| BC-AUTH-03 | User access: Super Admin / PRIME = all; TEACHER/EMPLOYEE = only if need.tenant_creation_allowed=true | DropdownCtrl:1362-1375 |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Mapping tab has two-step flow: Step 1 filters to select a need, Step 2 shows all dropdowns with map/unmap checkboxes | View |
| BC-BIZ-02 | Step 1 filters: db_type, table_name, column_name, category, main_menu, sub_menu, tab_name, field_name (super admin sees all) | View |
| BC-BIZ-03 | Step 2 shows all dropdowns from `sys_dropdown_table` with `is_mapped` flag indicating if linked to selected need | DropdownCtrl:259-275 |
| BC-BIZ-04 | Second filter set: dropdown_db_type, dropdown_table_name, dropdown_column_name, dropdown_category, dropdown_main_menu, dropdown_sub_menu, dropdown_tab_name, dropdown_field_name (filters by need attributes) | DropdownCtrl:278-335 |
| BC-BIZ-05 | Direct dropdown filters: search_key (LIKE), search_value (LIKE), search_type (exact) | DropdownCtrl:338-348 |
| BC-BIZ-06 | Mapping status filter: 'mapped' shows only mapped dropdowns, 'unmapped' shows only unmapped | DropdownCtrl:350-369 |
| BC-BIZ-07 | mapDropdownsToNeed: for each dropdown_id, checks existing mapping; updates is_active=true if exists, creates new if not | DropdownCtrl:1081-1099 |
| BC-BIZ-08 | removeMapping: bulk updates is_active=false for all matching junction entries | DropdownCtrl:1127-1129 |
| BC-BIZ-09 | mapExistingOptions: similar to mapDropdownsToNeed but also accepts key filter | DropdownCtrl:1265-1286 |
| BC-BIZ-10 | saveDropdownOption: creates dropdown + optionally maps to need; checks for existing mapping first | DropdownCtrl:896-938 |
| BC-BIZ-11 | Pagination: `mapping_page` parameter, 10 per page | DropdownCtrl:373 |
| BC-BIZ-12 | Modal form to create new dropdown directly from mapping tab (with auto-generated key if not provided) | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | No need selected in Step 1 → empty dropdown list with "Please select a dropdown need" | DropdownCtrl:203-204 |
| BC-EDG-02 | mapDropdownsToNeed with already-mapped dropdown → reactivates if inactive | DropdownCtrl:1087-1090 |
| BC-EDG-03 | removeMapping on non-existent mapping → 0 count, still returns success | DropdownCtrl:1127-1129 |
| BC-EDG-04 | mapExistingOptions with already-active mapping → skipped (count not incremented) | DropdownCtrl:1272-1276 |
| BC-EDG-05 | All dropdowns already mapped → no unmapped items; all items show "is_mapped" flag | View |
| BC-EDG-06 | saveDropdownOption exception → 500 JSON error | DropdownCtrl:933-938 |

---

## 2. Test Case List

### Screen 1: Mapping Tab (GET /global-master/dropdown?tab=create-dropdown-jnt)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDMAP-P10 | Positive | View | Mapping tab renders with Step 1 filters (need selection) and Step 2 (dropdowns with checkboxes) | Page rendered | test_ddmap_10 | Automated |
| TC-DDMAP-P11 | Positive | Ctrl | Step 1 filters (db_type, table_name, column_name, category, main_menu, sub_menu, tab_name, field_name) narrow dropdown needs | Filtered | test_ddmap_11 | Automated |
| TC-DDMAP-P12 | Positive | Ctrl | Selecting a need in Step 1 loads corresponding dropdowns in Step 2 | Loaded | test_ddmap_12 | Automated |
| TC-DDMAP-P13 | Positive | View | Each dropdown row shows key, value, type, ordinal, and is_mapped checkbox | All visible | test_ddmap_13 | Automated |
| TC-DDMAP-P14 | Positive | View | Mapped dropdowns have checked checkbox; unmapped have unchecked | Checkboxes correct | test_ddmap_14 | Automated |
| TC-DDMAP-P15 | Positive | View | Second filter set (dropdown_db_type, dropdown_table_name, etc.) filters by need attributes | Filtered | test_ddmap_15 | Automated |
| TC-DDMAP-P16 | Positive | View | Direct dropdown filters (search_key, search_value, search_type) work | Filtered | test_ddmap_16 | Automated |
| TC-DDMAP-P17 | Positive | View | Mapping status filter: 'mapped', 'unmapped', 'all' | Filtered | test_ddmap_17 | Automated |
| TC-DDMAP-P18 | Positive | View | Bulk Map and Bulk Unmap buttons available | Buttons present | test_ddmap_18 | Automated |
| TC-DDMAP-P19 | Positive | View | Modal for creating new dropdown from mapping tab | Modal present | test_ddmap_19 | Automated |
| TC-DDMAP-P20 | Positive | View | Pagination: results paginated 10 per page | Paginated | test_ddmap_20 | Automated |
| TC-DDMAP-P21 | Positive | View | Empty state when no dropdowns match filters | "Not Data Found" | test_ddmap_21 | Automated |

### Screen 2: Map To Need — AJAX (POST /global-master/dropdowns/map-to-need)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDMAP-P30 | Positive | Ctrl | mapDropdownsToNeed maps selected dropdowns to need, returns JSON with mapped count | Mapped + JSON | test_ddmap_30 | Automated |
| TC-DDMAP-P31 | Positive | Ctrl | Already-mapped dropdown → reactivates if was inactive | Reactivated | test_ddmap_31 | Automated |
| TC-DDMAP-N32 | Negative | Ctrl | mapDropdownsToNeed with invalid need id → 422 | 422 | test_ddmap_32 | Automated |
| TC-DDMAP-N33 | Negative | Ctrl | mapDropdownsToNeed with empty dropdown_ids → 422 | 422 | test_ddmap_33 | Automated |

### Screen 3: Remove Mapping — AJAX (POST /global-master/dropdowns/remove-mapping)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDMAP-P40 | Positive | Ctrl | removeMapping un-maps dropdowns, returns JSON with removed count | Unmapped + JSON | test_ddmap_40 | Automated |
| TC-DDMAP-N41 | Negative | Ctrl | removeMapping with invalid need id → 422 | 422 | test_ddmap_41 | Automated |
| TC-DDMAP-N42 | Negative | Ctrl | removeMapping with non-mapped dropdowns → 0 count (soft success) | 0 count | test_ddmap_42 | Automated |

### Screen 4: Map Existing Options — AJAX (POST /global-master/dropdowns/map-existing-options)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDMAP-P50 | Positive | Ctrl | mapExistingOptions maps selected options to need by key, returns JSON | Mapped + JSON | test_ddmap_50 | Automated |
| TC-DDMAP-P51 | Positive | Ctrl | Already-mapped option → skipped in count but still success | Count correct | test_ddmap_51 | Automated |

### Screen 5: Save Dropdown Option — AJAX (POST /global-master/dropdowns/save-option)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDMAP-P60 | Positive | Ctrl | saveDropdownOption creates dropdown, optionally maps to need if dropdown_need_id provided | Created + mapped | test_ddmap_60 | Automated |
| TC-DDMAP-N61 | Negative | Ctrl | saveDropdownOption with duplicate key → DB exception caught, 500 JSON | 500 JSON | test_ddmap_61 | Automated |

### Cross-Cutting

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDMAP-P01 | Schema | DDL/Model | Junction table and model exist | All pass | test_ddmap_01 | Automated |
| TC-DDMAP-P02 | Route | Routes | All mapping routes registered | Present | test_ddmap_02 | Automated |
| TC-DDMAP-P05 | Auth | Ctrl | Guest redirected to /login | /login | test_ddmap_05 | Automated |
| TC-DDMAP-N07 | Auth | Ctrl | User without prime.dropdown-need.update → 403 on map/unmap | 403 | test_ddmap_07 | Automated |
| TC-DDMAP-N08 | Auth | Ctrl | TEACHER without tenant_creation_allowed on selected need → 403 | 403 | test_ddmap_08 | Automated |

---

## 3. Test Method Index

### File: `dd_Mapping_TestCas.php` (estimated XX methods)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_ddmap_01_junction_table_and_model | TC-DDMAP-P01 | Schema | 01-04 |
| 2 | test_ddmap_02_mapping_routes_registered | TC-DDMAP-P02 | Schema | 01-04 |
| 3 | test_ddmap_05_guest_redirected_to_login | TC-DDMAP-P05 | Auth | 05-09 |
| 4 | test_ddmap_07_user_without_update_permission_403 | TC-DDMAP-N07 | Auth | 05-09 |
| 5 | test_ddmap_08_teacher_without_tenant_creation_403 | TC-DDMAP-N08 | Auth | 05-09 |
| 6 | test_ddmap_10_mapping_tab_renders | TC-DDMAP-P10 | List | 10-29 |
| 7 | test_ddmap_11_step1_filters_narrow_needs | TC-DDMAP-P11 | List | 10-29 |
| 8 | test_ddmap_12_selecting_need_loads_dropdowns | TC-DDMAP-P12 | List | 10-29 |
| 9 | test_ddmap_13_dropdown_row_columns_visible | TC-DDMAP-P13 | List | 10-29 |
| 10 | test_ddmap_14_checkboxes_show_mapping_status | TC-DDMAP-P14 | List | 10-29 |
| 11 | test_ddmap_15_second_filters_by_need_attributes | TC-DDMAP-P15 | List | 10-29 |
| 12 | test_ddmap_16_direct_dropdown_filters | TC-DDMAP-P16 | List | 10-29 |
| 13 | test_ddmap_17_mapping_status_filter | TC-DDMAP-P17 | List | 10-29 |
| 14 | test_ddmap_18_bulk_map_unmap_buttons | TC-DDMAP-P18 | List | 10-29 |
| 15 | test_ddmap_19_create_modal_present | TC-DDMAP-P19 | List | 10-29 |
| 16 | test_ddmap_20_pagination | TC-DDMAP-P20 | List | 10-29 |
| 17 | test_ddmap_21_empty_state | TC-DDMAP-P21 | List | 10-29 |
| 18 | test_ddmap_30_map_to_need_success | TC-DDMAP-P30 | Map | 30-39 |
| 19 | test_ddmap_31_map_reactivates_inactive | TC-DDMAP-P31 | Map | 30-39 |
| 20 | test_ddmap_32_map_invalid_need | TC-DDMAP-N32 | Map | 30-39 |
| 21 | test_ddmap_33_map_empty_ids | TC-DDMAP-N33 | Map | 30-39 |
| 22 | test_ddmap_40_remove_mapping_success | TC-DDMAP-P40 | Unmap | 40-49 |
| 23 | test_ddmap_41_remove_mapping_invalid_need | TC-DDMAP-N41 | Unmap | 40-49 |
| 24 | test_ddmap_42_remove_mapping_non_mapped | TC-DDMAP-N42 | Unmap | 40-49 |
| 25 | test_ddmap_50_map_existing_options_success | TC-DDMAP-P50 | Map | 50-59 |
| 26 | test_ddmap_51_map_existing_skip_already_mapped | TC-DDMAP-P51 | Map | 50-59 |
| 27 | test_ddmap_60_save_option_creates_and_maps | TC-DDMAP-P60 | AJAX | 60-69 |
| 28 | test_ddmap_61_save_option_duplicate_key | TC-DDMAP-N61 | AJAX | 60-69 |

**Total: 28 methods (28 Automated, 0 Planned).**
