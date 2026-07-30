# dd_DropdownList — Test Case List & Business Conditions

**Module:** DropDown (CODE `DD`, prefix `dd_`) · **Feature:** Dropdown List (grouped accordion view of `sys_dropdown_table` entries)
**DB scope:** CENTRAL-side (`sys_dropdown_table` → central DB) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary table:** `sys_dropdown_table` · **Module URL prefix:** `/global-master/dropdown?tab=dropdown-list`
**Test file:** `dd_DropdownList_TestCas.php`
**Tabs:** Dropdown List

Controller:
- `DropdownController::index` — master index; dropdown-list tab via `tab=dropdown-list`

Routes:
- `GET /global-master/dropdown` — DropdownController@index (with `tab=dropdown-list`)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `sys_dropdown_table` exists with columns: id (INT PK AI), ordinal (INT), key (VARCHAR 160), value (VARCHAR 255), type (VARCHAR 50 DEFAULT 'String'), additional_info (JSON/TEXT NULLABLE), is_active (BOOLEAN DEFAULT true), created_at, updated_at, deleted_at | DDL |
| BC-DB-02 | Model `Dropdown`: table `sys_dropdown_table`, SoftDeletes, fillable: [ordinal, key, value, type, additional_info, is_active] | Dropdown.php:18-25 |
| BC-DB-03 | Casts: ordinal → integer, is_active → boolean, additional_info → array; deleted_at → datetime | Dropdown.php:31-35 |
| BC-DB-04 | Default attribute values: type='String', is_active=true | Dropdown.php:37-40 |
| BC-DB-05 | Relationship: dropdownNeeds() belongsToMany via `sys_dropdown_need_dropdowns_jnt` with pivot is_active | Dropdown.php:56-65 |
| BC-DB-06 | Junction table `sys_dropdown_need_dropdowns_jnt`: columns id, dropdown_needs_id, dropdown_table_id, is_active | DDL |

### BC-VAL — Validation (applied on store/update, not on list view)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `key` required string max:160 unique:sys_dropdown_table | DropdownCtrl:518 |
| BC-VAL-02 | `ordinal` nullable integer min:1 | DropdownCtrl:519 |
| BC-VAL-03 | `value` required string max:100 (create) / max:255 (update bulk) | DropdownCtrl:520, DropdownCtrl:649 |
| BC-VAL-04 | `type` required in:String,Integer,Decimal,Date,Datetime,Time,Boolean | DropdownCtrl:521 |
| BC-VAL-05 | `additional_info` nullable string | DropdownCtrl:522 |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index() gate `prime.dropdown.viewAny` | DropdownCtrl:23 |
| BC-AUTH-02 | trashedDropdown() gate `prime.dropdown.restore` | DropdownCtrl:725 |
| BC-AUTH-03 | restore()/forceDelete() gate `prime.dropdown.restore` / `prime.dropdown.forceDelete` | DropdownCtrl:736,760 |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Dropdown List tab displays `sys_dropdown_table` entries grouped by `key` in accordion format | DropdownCtrl:376-382 |
| BC-BIZ-02 | Grouped dropdowns: for each distinct key, all rows with that key are fetched, ordered by ordinal | DropdownCtrl:376-382 |
| BC-BIZ-03 | Filters: list_key (exact), list_value (LIKE), list_status ('all'=no deleted, '0'=inactive, '1'=active, default=active) | DropdownCtrl:206-232 |
| BC-BIZ-04 | Status toggle per row (inline) via POST /global-master/dropdown/{id}/toggle-status | DropdownCtrl:784-819 |
| BC-BIZ-05 | Inline edit via bulk update: POST /global-master/dropdown/update-bulk (validates rows array) | DropdownCtrl:640-682 |
| BC-BIZ-06 | Bulk delete via POST /global-master/dropdown/delete-bulk | DropdownCtrl:843-872 |
| BC-BIZ-07 | Accordion view: distinct keys used as accordion headers; values listed under each key | DropdownCtrl:376-382 |
| BC-BIZ-08 | Link to create new dropdown at `/global-master/dropdown/create` | DropdownCtrl:480-496 |
| BC-BIZ-09 | Trash link to `/global-master/dropdown/trash/view` | DropdownCtrl:723-729 |
| BC-BIZ-10 | Pagination: `list_page` parameter, 10 per page | DropdownCtrl:231 |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | No dropdowns exist → empty accordion with "Not Data Found" | View |
| BC-EDG-02 | list_status filter edge cases: 'all' shows trashed too, '0'/'1' filter by is_active | DropdownCtrl:206-212 |
| BC-EDG-03 | Multiple dropdowns with same key but different ordinal → correctly ordered | DropdownCtrl:380 |

---

## 2. Test Case List

### Screen 1: Dropdown List Tab (GET /global-master/dropdown?tab=dropdown-list)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDLIST-P10 | Positive | Ctrl | Dropdown List tab renders with key, value, status filters and grouped accordion | Page rendered | test_ddlist_10 | Automated |
| TC-DDLIST-P11 | Positive | Ctrl | Filter by key (exact match) narrows results | Filtered | test_ddlist_11 | Automated |
| TC-DDLIST-P12 | Positive | Ctrl | Filter by value (LIKE) narrows results | Filtered | test_ddlist_12 | Automated |
| TC-DDLIST-P13 | Positive | Ctrl | Filter by status (active=1/inactive=0/all) narrows results correctly | Filtered | test_ddlist_13 | Automated |
| TC-DDLIST-P14 | Positive | Ctrl | Combined filters (key + value + status) work together | Filtered | test_ddlist_14 | Automated |
| TC-DDLIST-P15 | Positive | View | Grouped accordion: each distinct key is an accordion header | Accordion headers | test_ddlist_15 | Automated |
| TC-DDLIST-P16 | Positive | View | Under each accordion header, all values with that key are listed with ordinal, type, status, action buttons | Values listed | test_ddlist_16 | Automated |
| TC-DDLIST-P17 | Positive | View | Inline status toggle present on every row | Toggle present | test_ddlist_17 | Automated |
| TC-DDLIST-P18 | Positive | View | Inline edit fields (ordinal, value, type) available per row for bulk update | Inline edit | test_ddlist_18 | Planned |
| TC-DDLIST-P19 | Positive | View | Add new dropdown button present | Button present | test_ddlist_19 | Automated |
| TC-DDLIST-P20 | Positive | View | Trash link visible (permission-gated) | Link visible | test_ddlist_20 | Automated |
| TC-DDLIST-P21 | Positive | View | Pagination: results paginated 10 per page | Paginated | test_ddlist_21 | Automated |
| TC-DDLIST-P22 | Positive | View | Empty state when no records match filters | "Not Data Found" | test_ddlist_22 | Automated |
| TC-DDLIST-P23 | Positive | View | Bulk delete checkbox per row for mass operations | Checkboxes | test_ddlist_23 | Planned |

### Screen 2: Trash (GET /global-master/dropdown/trash/view)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDLIST-P30 | Positive | View | Trash page lists soft-deleted dropdowns | Listed | test_ddlist_30 | Automated |
| TC-DDLIST-P31 | Positive | View | Each trashed row has Restore and Force Delete action buttons | 2 buttons | test_ddlist_31 | Automated |
| TC-DDLIST-P32 | Positive | View | Trash page is paginated (10 per page) | Paginated | test_ddlist_32 | Planned |

### Screen 3: Bulk Update (POST /global-master/dropdown/update-bulk)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDLIST-P40 | Positive | Ctrl | Bulk update modifies ordinal, value, type for multiple rows | Rows updated | test_ddlist_40 | Automated |
| TC-DDLIST-N41 | Negative | Ctrl | Bulk update with invalid row id → 422 | 422 | test_ddlist_41 | Automated |
| TC-DDLIST-N42 | Negative | Ctrl | Bulk update with empty rows array → 422 | 422 | test_ddlist_42 | Automated |

### Screen 4: Bulk Delete (POST /global-master/dropdown/delete-bulk)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDLIST-P50 | Positive | Ctrl | Bulk delete soft-deletes selected dropdowns and deactivates junction entries | Soft-deleted | test_ddlist_50 | Automated |
| TC-DDLIST-P51 | Positive | Ctrl | Bulk delete returns JSON success | JSON | test_ddlist_51 | Automated |

### Screen 5: Toggle Status (POST /global-master/dropdown/{id}/toggle-status)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDLIST-P60 | Positive | Ctrl | Toggle active → inactive (flips is_active, updates junction) | is_active=false | test_ddlist_60 | Automated |
| TC-DDLIST-P61 | Positive | Ctrl | Toggle inactive → active (flips is_active, updates junction) | is_active=true | test_ddlist_61 | Automated |
| TC-DDLIST-P62 | Positive | Ctrl | Toggle returns JSON {success, is_active, message} | JSON response | test_ddlist_62 | Automated |

### Screen 6: Bulk Restore (POST /global-master/dropdowns/restore-bulk)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDLIST-P70 | Positive | Ctrl | Bulk restore recovers trashed dropdowns, reactivates junction | Restored | test_ddlist_70 | Automated |
| TC-DDLIST-P71 | Positive | Ctrl | Bulk restore returns JSON success | JSON | test_ddlist_71 | Automated |

### Screen 7: Bulk Force Delete (POST /global-master/dropdowns/force-delete-bulk)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDLIST-P80 | Positive | Ctrl | Bulk force delete permanently removes dropdowns and junction entries | Permanently deleted | test_ddlist_80 | Automated |
| TC-DDLIST-P81 | Positive | Ctrl | Bulk force delete returns JSON success | JSON | test_ddlist_81 | Automated |

### Cross-Cutting

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDLIST-P01 | Schema | DDL/Model | Migration, model, table, fillable, casts, SoftDeletes | All pass | test_ddlist_01 | Automated |
| TC-DDLIST-P02 | Route | Routes | All dropdown list routes registered | Present | test_ddlist_02 | Automated |
| TC-DDLIST-P05 | Auth | Middleware | Guest redirected to /login | /login | test_ddlist_05 | Automated |
| TC-DDLIST-N06 | Auth | Ctrl | User without prime.dropdown.viewAny → 403 | 403 | test_ddlist_06 | Automated |

---

## 3. Test Method Index

### File: `dd_DropdownList_TestCas.php` (estimated XX methods)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_ddlist_01_migration_model_and_schema | TC-DDLIST-P01 | Schema | 01-04 |
| 2 | test_ddlist_02_routes_are_registered | TC-DDLIST-P02 | Schema | 01-04 |
| 3 | test_ddlist_05_guest_redirected_to_login | TC-DDLIST-P05 | Auth | 05-09 |
| 4 | test_ddlist_06_user_without_viewAny_permission_gets_403 | TC-DDLIST-N06 | Auth | 05-09 |
| 5 | test_ddlist_10_dropdown_list_tab_renders | TC-DDLIST-P10 | List | 10-29 |
| 6 | test_ddlist_11_filter_by_key | TC-DDLIST-P11 | List | 10-29 |
| 7 | test_ddlist_12_filter_by_value | TC-DDLIST-P12 | List | 10-29 |
| 8 | test_ddlist_13_filter_by_status | TC-DDLIST-P13 | List | 10-29 |
| 9 | test_ddlist_14_combined_filters | TC-DDLIST-P14 | List | 10-29 |
| 10 | test_ddlist_15_grouped_accordion_display | TC-DDLIST-P15 | List | 10-29 |
| 11 | test_ddlist_16_values_listed_under_key | TC-DDLIST-P16 | List | 10-29 |
| 12 | test_ddlist_17_inline_status_toggle | TC-DDLIST-P17 | List | 10-29 |
| 13 | test_ddlist_18_inline_edit_fields | TC-DDLIST-P18 | List | 10-29 |
| 14 | test_ddlist_19_add_new_dropdown_button | TC-DDLIST-P19 | List | 10-29 |
| 15 | test_ddlist_20_trash_link_visible | TC-DDLIST-P20 | List | 10-29 |
| 16 | test_ddlist_21_pagination | TC-DDLIST-P21 | List | 10-29 |
| 17 | test_ddlist_22_empty_state | TC-DDLIST-P22 | List | 10-29 |
| 18 | test_ddlist_23_bulk_delete_checkboxes | TC-DDLIST-P23 | List | 10-29 |
| 19 | test_ddlist_30_trash_lists_soft_deleted | TC-DDLIST-P30 | Trash | 30-39 |
| 20 | test_ddlist_31_trash_has_restore_and_force_delete_buttons | TC-DDLIST-P31 | Trash | 30-39 |
| 21 | test_ddlist_32_trash_paginated | TC-DDLIST-P32 | Trash | 30-39 |
| 22 | test_ddlist_40_bulk_update_modifies_rows | TC-DDLIST-P40 | BulkUpd | 40-49 |
| 23 | test_ddlist_41_bulk_update_invalid_id | TC-DDLIST-N41 | BulkUpd | 40-49 |
| 24 | test_ddlist_42_bulk_update_empty_rows | TC-DDLIST-N42 | BulkUpd | 40-49 |
| 25 | test_ddlist_50_bulk_delete_soft_deletes | TC-DDLIST-P50 | BulkDel | 50-59 |
| 26 | test_ddlist_51_bulk_delete_returns_json | TC-DDLIST-P51 | BulkDel | 50-59 |
| 27 | test_ddlist_60_toggle_active_to_inactive | TC-DDLIST-P60 | Toggle | 60-69 |
| 28 | test_ddlist_61_toggle_inactive_to_active | TC-DDLIST-P61 | Toggle | 60-69 |
| 29 | test_ddlist_62_toggle_returns_json | TC-DDLIST-P62 | Toggle | 60-69 |
| 30 | test_ddlist_70_bulk_restore_recovers | TC-DDLIST-P70 | Restore | 70-79 |
| 31 | test_ddlist_71_bulk_restore_returns_json | TC-DDLIST-P71 | Restore | 70-79 |
| 32 | test_ddlist_80_bulk_force_delete_removes | TC-DDLIST-P80 | ForceDel | 80-89 |
| 33 | test_ddlist_81_bulk_force_delete_returns_json | TC-DDLIST-P81 | ForceDel | 80-89 |

**Total: 33 methods (30 Automated, 3 Planned).**
