# dd_DropdownNeed — Test Case List & Business Conditions

**Module:** DropDown (CODE `DD`, prefix `dd_`) · **Feature:** Dropdown Needs (CRUD + Trash + Toggle Status + AJAX filter/cascading)
**DB scope:** CENTRAL-side (`sys_dropdown_needs` → central DB) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary table:** `sys_dropdown_needs` · **Module URL prefix:** `/global-master/dropdown?tab=dropdown-need`
**Test file:** `dd_DropdownNeed_TestCas.php`
**Tabs:** Dropdown Needs (first tab of the Global Master Dropdown module)

Controllers:
- `DropdownNeedController` — CRUD + trash + toggle + AJAX (migration tables, columns, menu data, cascading)
- `DropdownController::index` — master index acting as entry point for all 4 tabs

Routes (grouped under `global-master.` prefix):
- `GET/POST /global-master/dropdown-need` — index (GET), store (POST)
- `GET /global-master/dropdown-need/create` — create
- `GET /global-master/dropdown-need/{id}` — show
- `GET/PUT /global-master/dropdown-need/{id}/edit` — edit (GET), update (PUT)
- `DELETE /global-master/dropdown-need/{id}` — destroy
- `GET /global-master/dropdown-need/trash/view` — trashed list
- `GET /global-master/dropdown-need/{id}/restore` — restore
- `DELETE /global-master/dropdown-need/{id}/force-delete` — force delete
- `POST /global-master/dropdown-need/{id}/toggle-status` — toggle status
- `GET /global-master/dropdown-need/search` — search (JSON)
- `GET /global-master/dropdown-need-api/migration-tables/{dbType}` — AJAX migration tables
- `GET /global-master/dropdown-need-api/migration-content/{dbType}/{migrationName}` — AJAX migration content
- `GET /global-master/dropdown-need-api/table-columns` — AJAX table columns
- `GET /global-master/dropdown-need-api/menu-data` — AJAX menu data
- `GET /global-master/dropdown-need/main-menus/{category}` — AJAX main menus
- `GET /global-master/dropdown-need/sub-menus/{main}` — AJAX sub menus

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `sys_dropdown_needs` exists with columns: id (INT PK AI), db_type (VARCHAR 50), table_name (VARCHAR 150), column_name (VARCHAR 150), menu_category (VARCHAR 150 NULLABLE), main_menu (VARCHAR 150 NULLABLE), sub_menu (VARCHAR 150 NULLABLE), tab_name (VARCHAR 100 NULLABLE), field_name (VARCHAR 100 NULLABLE), is_system (BOOLEAN), tenant_creation_allowed (BOOLEAN), compulsory (BOOLEAN), dropdown_table_record_exist (BOOLEAN DEFAULT false), is_active (BOOLEAN DEFAULT true), created_at, updated_at, deleted_at | DDL |
| BC-DB-02 | Model `DropdownNeed`: table `sys_dropdown_needs`, SoftDeletes, fillable: all 14 columns | DropdownNeed.php:13-28 |
| BC-DB-03 | Casts: is_system, tenant_creation_allowed, compulsory, dropdown_table_record_exist, is_active → boolean; deleted_at → datetime | DropdownNeed.php:30-37 |
| BC-DB-04 | Relationship: dropdowns() belongsToMany via `sys_dropdown_need_dropdowns_jnt` with pivot is_active | DropdownNeed.php:54-63 |
| BC-DB-05 | Scopes: filterByDbType, filterByTableName, filterByColumnName, filterByMenuCategory, filterByMainMenu, filterBySubMenu, filterByTabName, filterByFieldName | DropdownNeed.php:79-141 |
| BC-DB-06 | getDistinctValues() static method returns distinct non-null active values for a column | DropdownNeed.php:146-154 |

### BC-VAL — Validation (Source: `DropdownNeedController::store`, `DropdownNeedController::update`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `db_type` required in:Prime,Tenant,Global | Ctrl:967 |
| BC-VAL-02 | `table_name` required string max:150 | Ctrl:968 |
| BC-VAL-03 | `column_name` required string max:150 | Ctrl:969 |
| BC-VAL-04 | `tenant_creation_allowed` required boolean | Ctrl:970 |
| BC-VAL-05 | `menu_category` nullable string max:150 (required if tenant_creation_allowed=true) | Ctrl:972,985 |
| BC-VAL-06 | `main_menu` nullable string max:150 (required if tenant_creation_allowed=true) | Ctrl:973,986 |
| BC-VAL-07 | `sub_menu` nullable string max:150 (required if tenant_creation_allowed=true) | Ctrl:974,987 |
| BC-VAL-08 | `tab_name` nullable string max:100 (required if tenant_creation_allowed=true) | Ctrl:975,988 |
| BC-VAL-09 | `field_name` nullable string max:100 (required if tenant_creation_allowed=true) | Ctrl:976,989 |
| BC-VAL-10 | `is_system` required boolean | Ctrl:978 |
| BC-VAL-11 | `compulsory` required boolean | Ctrl:979 |
| BC-VAL-12 | `dropdown_table_record_exist` nullable boolean | Ctrl:980 |
| BC-VAL-13 | `is_active` nullable boolean (defaults to true) | Ctrl:981,1002 |
| BC-VAL-14 | Update: same rules as store except is_active uses `$request->boolean()` | Ctrl:1051-1064,1074 |
| BC-VAL-15 | When tenant_creation_allowed=false, all 5 menu fields are forced to null before save | Ctrl:994-1000 |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index() gate `prime.dropdown.viewAny` | DropdownNeedCtrl:19 |
| BC-AUTH-02 | create()/store() gate `prime.dropdown-need.create` | DropdownNeedCtrl:429,960 |
| BC-AUTH-03 | show() gate `prime.dropdown-need.view` | DropdownNeedCtrl:951 |
| BC-AUTH-04 | edit()/update() gate `prime.dropdown-need.update` | DropdownNeedCtrl:1030,1043 |
| BC-AUTH-05 | destroy() gate `prime.dropdown-need.delete` | DropdownNeedCtrl:1088 |
| BC-AUTH-06 | trashed()/restore() gate `prime.dropdown-need.restore` | DropdownNeedCtrl:1121,1130 |
| BC-AUTH-07 | forceDelete() gate `prime.dropdown-need.forceDelete` | DropdownNeedCtrl:1157 |
| BC-AUTH-08 | toggleStatus() gate `prime.dropdown-need.update` | DropdownNeedCtrl:1180 |
| BC-AUTH-09 | filterOptions() gate `prime.dropdown.viewAny` | DropdownNeedCtrl:362 |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Master index is entry for all 4 tabs; `active_tab` parameter switches current tab; dropdown-need is default tab for authorized users | DropdownCtrl:28-33 |
| BC-BIZ-02 | `is_system=true` records CANNOT be edited (redirect with error) | DropdownNeedCtrl:1032-1036 |
| BC-BIZ-03 | `is_system=true` records CANNOT be deleted (redirect with error) | DropdownNeedCtrl:1092-1096 |
| BC-BIZ-04 | destroy() deactivates all related junction entries (`DropdownNeedTableJnt`), sets is_active=false, soft-deletes, logs 'Trashed' | DropdownNeedCtrl:1098-1117 |
| BC-BIZ-05 | restore() restores record, sets is_active=true, reactivates junction entries, logs 'Restored', redirects to trash view | DropdownNeedCtrl:1132-1153 |
| BC-BIZ-06 | forceDelete() force-deletes junction entries first, then force-deletes need, logs 'Deleted', redirects to trash view | DropdownNeedCtrl:1159-1176 |
| BC-BIZ-07 | toggleStatus() flips is_active, updates all related junction entries, logs 'Toggled', returns JSON {success, is_active, message} | DropdownNeedCtrl:1186-1211 |
| BC-BIZ-08 | store() redirects to `central.global-master.dropdown.index` with success flash | DropdownNeedCtrl:1011-1013 |
| BC-BIZ-09 | update() same redirect pattern | DropdownNeedCtrl:1081-1083 |
| BC-BIZ-10 | getMigrationTables() fetches migration file names per DB type (Prime/Global/Tenant) with caching (except Tenant); returns JSON array | DropdownNeedCtrl:473-500 |
| BC-BIZ-11 | getMigrationContent() reads migration file to extract original table name and columns; returns JSON | DropdownNeedCtrl:503-557 |
| BC-BIZ-12 | getTableColumns() uses SHOW COLUMNS to return actual column list for resolved table; with caching (except Tenant) | DropdownNeedCtrl:593-627 |
| BC-BIZ-13 | getMenuData() fetches glb_menus from global_master_mysql, returns categories/main_menus/sub_menus based on is_category/parent_id | DropdownNeedCtrl:834-881 |
| BC-BIZ-14 | getMainMenus() returns main_menus for a category from glb_menus | DropdownNeedCtrl:883-915 |
| BC-BIZ-15 | getSubMenus() returns sub_menus for a main menu from glb_menus | DropdownNeedCtrl:917-947 |
| BC-BIZ-16 | filterOptions() AJAX cascading filter: filters by category/main menu/sub menu/tab, returns all distinct related values | DropdownNeedCtrl:360-425 |
| BC-BIZ-17 | search() returns top 10 matching needs by table_name/column_name/field_name LIKE | DropdownNeedCtrl:1213-1224 |
| BC-BIZ-18 | index() view receives: dropdownNeeds (paginated), categories, dbTypes, tables, columns, mainMenus, subMenus, tabs, fields, selectedDropdownNeed, groupedDropdowns, mappedDropdowns, unmappedDropdowns, dropdownsForMapping | DropdownNeedCtrl:314-354 |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Non-existing id for show/edit/update/destroy → 404 (findOrFail) | Ctrl |
| BC-EDG-02 | WithTrashed for restore/forceDelete → 404 if not in trash | Ctrl:1132,1159 |
| BC-EDG-03 | Edit/update/destroy on is_system=true → blocked with error flash | Ctrl:1032,1045,1092 |
| BC-EDG-04 | db_type invalid (not Prime/Global/Tenant) → validation rejects | BC-VAL-01 |
| BC-EDG-05 | Empty db_type/table_name/column_name → validation rejects | BC-VAL-01/02/03 |
| BC-EDG-06 | tenant_creation_allowed=true but menu fields empty → validation rejects | BC-VAL-05-09 |
| BC-EDG-07 | getMigrationTables with invalid dbType → returns empty JSON array | Ctrl:487-488 |
| BC-EDG-08 | getMigrationContent for non-existent migration → returns error JSON | Ctrl:531-533 |
| BC-EDG-09 | getTableColumns with no tenant for Tenant type → returns error JSON | Ctrl:610-612 |
| BC-EDG-10 | Tenancy initialization in fetchMigrationTables/fetchTableColumns → end() always called in finally block | Ctrl:793-795,828-830 |
| BC-EDG-11 | Cache for Prime/Global tables/columns expires after 1 hour | Ctrl:496,623 |
| BC-EDG-12 | filterOptions exception → returns empty arrays for all fields | Ctrl:414-424 |
| BC-EDG-13 | getMenuData exception → returns empty arrays | Ctrl:875-879 |
| BC-EDG-14 | index() with no selectedDropdownNeed → mapped/unmapped return empty paginator | Ctrl:186-188,215-217 |

---

## 2. Test Case List

### Screen 1: Index — Dropdown Needs Tab (GET /global-master/dropdown?tab=dropdown-need)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P10 | Positive | Ctrl | Dropdown Needs tab renders with DB type, table, column, category, main menu, sub menu, tab, field filters and results table | Page rendered | test_ddneed_10 | Automated |
| TC-DDNEED-P11 | Positive | Ctrl | Filter by db_type narrows results | Filtered | test_ddneed_11 | Automated |
| TC-DDNEED-P12 | Positive | Ctrl | Filter by table_name narrows results | Filtered | test_ddneed_12 | Automated |
| TC-DDNEED-P13 | Positive | Ctrl | Filter by column_name narrows results | Filtered | test_ddneed_13 | Automated |
| TC-DDNEED-P14 | Positive | Ctrl | Filter by menu_category narrows results | Filtered | test_ddneed_14 | Automated |
| TC-DDNEED-P15 | Positive | Ctrl | Filter by main_menu narrows results (respects category selection) | Filtered | test_ddneed_15 | Automated |
| TC-DDNEED-P16 | Positive | Ctrl | Filter by sub_menu narrows results (respects category + main menu) | Filtered | test_ddneed_16 | Automated |
| TC-DDNEED-P17 | Positive | Ctrl | Filter by tab_name narrows results (respects previous selections) | Filtered | test_ddneed_17 | Automated |
| TC-DDNEED-P18 | Positive | Ctrl | Filter by field_name narrows results (respects previous selections) | Filtered | test_ddneed_18 | Automated |
| TC-DDNEED-P19 | Positive | Ctrl | Cascading filters: selecting category updates main_menu/sub_menu/tab/field dropdowns dynamically via AJAX | Updated lists | test_ddneed_19 | Automated |
| TC-DDNEED-P20 | Positive | Ctrl | Combined filters work together | Filtered | test_ddneed_20 | Automated |
| TC-DDNEED-P21 | Positive | Ctrl | Result set is paginated (default 10, `needs_page` param) | Paginated | test_ddneed_21 | Automated |
| TC-DDNEED-P22 | Positive | View | Each row displays: DB Type, Table, Column, Menu Category, Main Menu, Sub Menu, Tab, Field, Status toggle, Action buttons | All columns visible | test_ddneed_22 | Automated |
| TC-DDNEED-P23 | Positive | View | Action buttons per row: View, Edit, Delete (permission-gated; system rows: View only) | Buttons gated | test_ddneed_23 | Automated |
| TC-DDNEED-P24 | Positive | View | Status toggle switch present on every non-system row | Toggle present | test_ddneed_24 | Automated |
| TC-DDNEED-P25 | Positive | View | Empty data state when no records match filters | "Not Data Found" | test_ddneed_25 | Automated |
| TC-DDNEED-P26 | Positive | View | Create New button links to create page | Link works | test_ddneed_26 | Automated |
| TC-DDNEED-P27 | Positive | View | Trash link visible (permission-gated) | Link visible | test_ddneed_27 | Automated |

### Screen 2: Create Form (GET /global-master/dropdown-need/create)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P30 | Positive | View | Create page renders all form fields: db_type, table_name, column_name, tenant_creation_allowed, menu_category, main_menu, sub_menu, tab_name, field_name, is_system, compulsory, status switch | All fields rendered | test_ddneed_30 | Automated |
| TC-DDNEED-P31 | Positive | View | Table Name dropdown loads via AJAX when DB Type is selected | Populated | test_ddneed_31 | Automated |
| TC-DDNEED-P32 | Positive | View | Column Name dropdown loads via AJAX when Table Name is selected | Populated | test_ddneed_32 | Automated |
| TC-DDNEED-P33 | Positive | View | Menu Category loads via AJAX from glb_menus | Populated | test_ddneed_33 | Automated |
| TC-DDNEED-P34 | Positive | View | Main Menu loads via AJAX when Category is selected (disabled otherwise) | Populated | test_ddneed_34 | Automated |
| TC-DDNEED-P35 | Positive | View | Sub Menu loads via AJAX when Main Menu is selected (disabled otherwise) | Populated | test_ddneed_35 | Automated |
| TC-DDNEED-P36 | Positive | View | tenant_creation_allowed=Yes → menu fields are enabled; tenant_creation_allowed=No → menu fields are disabled and cleared | Toggled | test_ddneed_36 | Automated |

### Screen 3: Store (POST /global-master/dropdown-need)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P40 | Positive | Ctrl | Valid store creates dropdown need with all required fields | Row created | test_ddneed_40 | Automated |
| TC-DDNEED-P41 | Positive | Ctrl | Store with tenant_creation_allowed=true AND all 5 menu fields provided → success | Created | test_ddneed_41 | Automated |
| TC-DDNEED-P42 | Positive | Ctrl | Store with tenant_creation_allowed=false → menu fields forced to null | menu_fields=NULL | test_ddneed_42 | Automated |
| TC-DDNEED-P43 | Positive | Ctrl | is_active defaults to true when not provided | is_active=1 | test_ddneed_43 | Automated |
| TC-DDNEED-P44 | Positive | Ctrl | dropdown_table_record_exist defaults to false | Default false | test_ddneed_44 | Automated |
| TC-DDNEED-P45 | Positive | Ctrl | Store logs 'Created' activity | Log entry | test_ddneed_45 | Automated |
| TC-DDNEED-P46 | Positive | Ctrl | Store redirects to global-master.dropdown.index with success flash | Redirect + flash | test_ddneed_46 | Automated |
| TC-DDNEED-N50 | Negative | Ctrl | db_type empty → rejected | 422 | test_ddneed_50 | Automated |
| TC-DDNEED-N51 | Negative | Ctrl | db_type invalid (not Prime/Global/Tenant) → rejected | 422 | test_ddneed_51 | Automated |
| TC-DDNEED-N52 | Negative | Ctrl | table_name empty → rejected | 422 | test_ddneed_52 | Automated |
| TC-DDNEED-N53 | Negative | Ctrl | column_name empty → rejected | 422 | test_ddneed_53 | Automated |
| TC-DDNEED-N54 | Negative | Ctrl | tenant_creation_allowed=true + menu_category empty → rejected | 422 | test_ddneed_54 | Automated |
| TC-DDNEED-N55 | Negative | Ctrl | tenant_creation_allowed=true + main_menu empty → rejected | 422 | test_ddneed_55 | Automated |
| TC-DDNEED-N56 | Negative | Ctrl | tenant_creation_allowed=true + sub_menu empty → rejected | 422 | test_ddneed_56 | Automated |
| TC-DDNEED-N57 | Negative | Ctrl | tenant_creation_allowed=true + tab_name empty → rejected | 422 | test_ddneed_57 | Automated |
| TC-DDNEED-N58 | Negative | Ctrl | tenant_creation_allowed=true + field_name empty → rejected | 422 | test_ddneed_58 | Automated |
| TC-DDNEED-N59 | Negative | Ctrl | table_name exceeds 150 chars → rejected | 422 | test_ddneed_59 | Automated |
| TC-DDNEED-N60 | Negative | Ctrl | column_name exceeds 150 chars → rejected | 422 | test_ddneed_60 | Automated |

### Screen 4: Show (GET /global-master/dropdown-need/{id})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P70 | Positive | View | Show page displays all fields: db_type, table_name, column_name, is_system, tenant_creation_allowed, compulsory, menu category chain, status | All fields displayed | test_ddneed_70 | Automated |
| TC-DDNEED-P71 | Positive | View | Show page shows dash for null menu fields | Dash shown | test_ddneed_71 | Automated |
| TC-DDNEED-N72 | Negative | Ctrl | Invalid id → 404 | 404 | test_ddneed_72 | Automated |
| TC-DDNEED-N73 | Negative | Ctrl | Soft-deleted id → 404 (no withTrashed) | 404 | test_ddneed_73 | Automated |

### Screen 5: Edit (GET /global-master/dropdown-need/{id}/edit)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P80 | Positive | View | Edit page pre-fills with existing values for all fields | Pre-filled | test_ddneed_80 | Automated |
| TC-DDNEED-P81 | Positive | View | is_system=1 row → redirects to index with error "System records cannot be edited" | Redirect + error | test_ddneed_81 | Automated |
| TC-DDNEED-N82 | Negative | Ctrl | Invalid id → 404 | 404 | test_ddneed_82 | Automated |
| TC-DDNEED-N83 | Negative | Ctrl | System record edit → blocked with error | Blocked | test_ddneed_83 | Automated |

### Screen 6: Update (PUT /global-master/dropdown-need/{id})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P90 | Positive | Ctrl | Update modifies record and logs 'Updated' activity | Updated + log | test_ddneed_90 | Automated |
| TC-DDNEED-P91 | Positive | Ctrl | Update changes is_active from 1 to 0 | Inactivated | test_ddneed_91 | Automated |
| TC-DDNEED-P92 | Positive | Ctrl | Update changes tenant_creation_allowed=0 → menu fields cleared to null | Cleared to null | test_ddneed_92 | Automated |
| TC-DDNEED-P93 | Positive | Ctrl | Update redirects to global-master.dropdown.index with success flash | Redirect + flash | test_ddneed_93 | Automated |
| TC-DDNEED-N94 | Negative | Ctrl | Update on is_system=1 record → blocked with error | Blocked | test_ddneed_94 | Automated |
| TC-DDNEED-N95 | Negative | Ctrl | Update with invalid db_type → rejected | 422 | test_ddneed_95 | Automated |

### Screen 7: Destroy (DELETE /global-master/dropdown-need/{id})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P100 | Positive | Ctrl | Destroy soft-deletes need, sets is_active=false, deactivates junction entries, logs 'Trashed' | Soft-deleted + junction deactivated | test_ddneed_100 | Automated |
| TC-DDNEED-P101 | Positive | Ctrl | Destroy redirects to global-master.dropdown.index with success flash | Redirect + flash | test_ddneed_101 | Automated |
| TC-DDNEED-N102 | Negative | Ctrl | Destroy on is_system=1 record → blocked with error | Blocked | test_ddneed_102 | Automated |
| TC-DDNEED-N103 | Negative | Ctrl | Destroy on non-existing id → 404 | 404 | test_ddneed_103 | Automated |

### Screen 8: Trash (GET /global-master/dropdown-need/trash/view)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P110 | Positive | View | Trash page lists soft-deleted needs | Listed | test_ddneed_110 | Automated |
| TC-DDNEED-P111 | Positive | View | Each trashed row has Restore and Force Delete action buttons | 2 buttons | test_ddneed_111 | Automated |
| TC-DDNEED-P112 | Positive | View | Trash page is paginated (10 per page) | Paginated | test_ddneed_112 | Planned |

### Screen 9: Restore (GET /global-master/dropdown-need/{id}/restore)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P120 | Positive | Ctrl | Restore recovers record (deleted_at=NULL), is_active=true, reactivates junction entries, logs 'Restored' | Restored + junction reactivated | test_ddneed_120 | Automated |
| TC-DDNEED-P121 | Positive | Ctrl | Restore redirects to trash view with success flash | Redirect + flash | test_ddneed_121 | Automated |
| TC-DDNEED-N122 | Negative | Ctrl | Restore on non-trashed/non-existing id → 404 | 404 | test_ddneed_122 | Automated |

### Screen 10: Force Delete (DELETE /global-master/dropdown-need/{id}/force-delete)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P130 | Positive | Ctrl | Force delete permanently removes need and junction entries, logs 'Deleted' | Deleted + log | test_ddneed_130 | Automated |
| TC-DDNEED-P131 | Positive | Ctrl | Force delete redirects to trash view with success flash | Redirect + flash | test_ddneed_131 | Automated |
| TC-DDNEED-N132 | Negative | Ctrl | Force delete on non-trashed id → 404 (withTrashed findOrFail) | 404 | test_ddneed_132 | Automated |

### Screen 11: Toggle Status (POST /global-master/dropdown-need/{id}/toggle-status)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P140 | Positive | Ctrl | Toggle active → inactive (is_active flips to false) and junction entries updated | is_active=false | test_ddneed_140 | Automated |
| TC-DDNEED-P141 | Positive | Ctrl | Toggle inactive → active (is_active flips to true) and junction entries updated | is_active=true | test_ddneed_141 | Automated |
| TC-DDNEED-P142 | Positive | Ctrl | Toggle returns JSON response {success: true, is_active, message} | JSON response | test_ddneed_142 | Automated |
| TC-DDNEED-P143 | Positive | Ctrl | Toggle logs 'Toggled' activity | Log entry | test_ddneed_143 | Automated |

### Screen 12: AJAX — Migration Tables (GET /global-master/dropdown-need-api/migration-tables/{dbType})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P150 | Positive | Ctrl | getMigrationTables('Prime') returns JSON array of migration table names | Array | test_ddneed_150 | Automated |
| TC-DDNEED-P151 | Positive | Ctrl | getMigrationTables('Global') returns JSON array | Array | test_ddneed_151 | Automated |
| TC-DDNEED-P152 | Positive | Ctrl | getMigrationTables('Tenant') returns JSON array (initializes tenancy) | Array | test_ddneed_152 | Automated |
| TC-DDNEED-N153 | Negative | Ctrl | getMigrationTables('Invalid') returns empty JSON array | [] | test_ddneed_153 | Automated |

### Screen 13: AJAX — Migration Content (GET /global-master/dropdown-need-api/migration-content/{dbType}/{migrationName})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P160 | Positive | Ctrl | getMigrationContent returns migration_file, original_table_name, columns_from_migration, file_path | Correct response | test_ddneed_160 | Automated |
| TC-DDNEED-N161 | Negative | Ctrl | Non-existent migration → error JSON | Error | test_ddneed_161 | Automated |

### Screen 14: AJAX — Table Columns (GET /global-master/dropdown-need-api/table-columns)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P170 | Positive | Ctrl | getTableColumns for valid db_type+table_name returns JSON array of column names | Array | test_ddneed_170 | Automated |
| TC-DDNEED-N171 | Negative | Ctrl | Empty db_type or table_name → empty array | [] | test_ddneed_171 | Automated |
| TC-DDNEED-N172 | Negative | Ctrl | Invalid db_type → empty array | [] | test_ddneed_172 | Automated |

### Screen 15: AJAX — Menu Data / Cascading (GET /global-master/dropdown-need-api/menu-data, main-menus, sub-menus)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P180 | Positive | Ctrl | getMenuData returns categories, main_menus, sub_menus from glb_menus | JSON with 3 arrays | test_ddneed_180 | Automated |
| TC-DDNEED-P181 | Positive | Ctrl | getMainMenus(category) returns main menus for the given category | Array | test_ddneed_181 | Automated |
| TC-DDNEED-P182 | Positive | Ctrl | getSubMenus(mainMenu) returns sub menus for the given main menu | Array | test_ddneed_182 | Automated |

### Screen 16: AJAX — Search (GET /global-master/dropdown-need/search)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P190 | Positive | Ctrl | search() with keyword returns top 10 matching needs by table_name/column_name/field_name LIKE | JSON array | test_ddneed_190 | Automated |
| TC-DDNEED-N191 | Negative | Ctrl | search() without keyword returns empty array | [] | test_ddneed_191 | Automated |

### Cross-Cutting — Schema, Auth, Tenancy, Security

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-DDNEED-P01 | Schema | DDL/Model | Migration, model, table, fillable, casts, SoftDeletes | All pass | test_ddneed_01 | Automated |
| TC-DDNEED-P02 | Schema | Routes | All resource + extra routes registered | All present | test_ddneed_02 | Automated |
| TC-DDNEED-P03 | Schema | Model | All scopes defined, getDistinctValues static method | Defined | test_ddneed_03 | Automated |
| TC-DDNEED-P05 | Auth | Middleware | Guest redirected to /login | /login | test_ddneed_05 | Automated |
| TC-DDNEED-P06 | Auth | Ctrl | Controller gate authorization present on all methods | Gates present | test_ddneed_06 | Automated |
| TC-DDNEED-N07 | Auth | Ctrl | User without prime.dropdown.viewAny → 403 on index | 403 | test_ddneed_07 | Automated |
| TC-DDNEED-N08 | Auth | Ctrl | User without prime.dropdown-need.create → 403 on create/store | 403 | test_ddneed_08 | Automated |
| TC-DDNEED-N09 | Auth | Ctrl | User without prime.dropdown-need.view → 403 on show | 403 | test_ddneed_09 | Automated |
| TC-DDNEED-N10 | Auth | Ctrl | User without prime.dropdown-need.update → 403 on edit/update/toggleStatus | 403 | test_ddneed_10 | Automated |
| TC-DDNEED-N11 | Auth | Ctrl | User without prime.dropdown-need.delete → 403 on destroy | 403 | test_ddneed_11 | Automated |
| TC-DDNEED-N12 | Auth | Ctrl | User without prime.dropdown-need.restore → 403 on trashed/restore | 403 | test_ddneed_12 | Automated |
| TC-DDNEED-N13 | Auth | Ctrl | User without prime.dropdown-need.forceDelete → 403 on forceDelete | 403 | test_ddneed_13 | Automated |
| TC-DDNEED-P20 | Security | View | All user-input table/column/field names are XSS-escaped on render | Escaped | test_ddneed_20 | Automated |

---

## 3. Test Method Index

### File: `dd_DropdownNeed_TestCas.php` (estimated XX methods)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_ddneed_01_migration_model_and_schema | TC-DDNEED-P01 | Schema | 01-04 |
| 2 | test_ddneed_02_routes_are_registered | TC-DDNEED-P02 | Schema | 01-04 |
| 3 | test_ddneed_03_model_scopes_and_helpers | TC-DDNEED-P03 | Schema | 01-04 |
| 4 | test_ddneed_05_guest_redirected_to_login | TC-DDNEED-P05 | Auth | 05-09 |
| 5 | test_ddneed_06_controller_gate_authorization_is_present | TC-DDNEED-P06 | Auth | 05-09 |
| 6 | test_ddneed_07_user_without_viewAny_permission_gets_403 | TC-DDNEED-N07 | Auth | 05-09 |
| 7 | test_ddneed_08_user_without_create_permission_gets_403 | TC-DDNEED-N08 | Auth | 05-09 |
| 8 | test_ddneed_09_user_without_view_permission_gets_403 | TC-DDNEED-N09 | Auth | 05-09 |
| 9 | test_ddneed_10_user_without_update_permission_gets_403 | TC-DDNEED-N10 | Auth | 05-09 |
| 10 | test_ddneed_11_user_without_delete_permission_gets_403 | TC-DDNEED-N11 | Auth | 05-09 |
| 11 | test_ddneed_12_user_without_restore_permission_gets_403 | TC-DDNEED-N12 | Auth | 05-09 |
| 12 | test_ddneed_13_user_without_forceDelete_permission_gets_403 | TC-DDNEED-N13 | Auth | 05-09 |
| 13 | test_ddneed_10_dropdown_need_tab_renders_with_filters | TC-DDNEED-P10 | List | 10-29 |
| 14 | test_ddneed_11_filter_by_db_type | TC-DDNEED-P11 | List | 10-29 |
| 15 | test_ddneed_12_filter_by_table_name | TC-DDNEED-P12 | List | 10-29 |
| 16 | test_ddneed_13_filter_by_column_name | TC-DDNEED-P13 | List | 10-29 |
| 17 | test_ddneed_14_filter_by_menu_category | TC-DDNEED-P14 | List | 10-29 |
| 18 | test_ddneed_15_filter_by_main_menu | TC-DDNEED-P15 | List | 10-29 |
| 19 | test_ddneed_16_filter_by_sub_menu | TC-DDNEED-P16 | List | 10-29 |
| 20 | test_ddneed_17_filter_by_tab_name | TC-DDNEED-P17 | List | 10-29 |
| 21 | test_ddneed_18_filter_by_field_name | TC-DDNEED-P18 | List | 10-29 |
| 22 | test_ddneed_19_cascading_filters_update_dropdowns | TC-DDNEED-P19 | List | 10-29 |
| 23 | test_ddneed_20_combined_filters_work_together | TC-DDNEED-P20 | List | 10-29 |
| 24 | test_ddneed_21_results_are_paginated | TC-DDNEED-P21 | List | 10-29 |
| 25 | test_ddneed_22_table_displays_all_columns | TC-DDNEED-P22 | List | 10-29 |
| 26 | test_ddneed_23_action_buttons_per_row | TC-DDNEED-P23 | List | 10-29 |
| 27 | test_ddneed_24_status_toggle_on_every_row | TC-DDNEED-P24 | List | 10-29 |
| 28 | test_ddneed_25_empty_state_when_no_records | TC-DDNEED-P25 | List | 10-29 |
| 29 | test_ddneed_26_create_button_links_to_form | TC-DDNEED-P26 | List | 10-29 |
| 30 | test_ddneed_27_trash_link_visible | TC-DDNEED-P27 | List | 10-29 |
| 31 | test_ddneed_30_create_page_renders_fields | TC-DDNEED-P30 | Create | 30-39 |
| 32 | test_ddneed_31_table_dropdown_loads_via_ajax | TC-DDNEED-P31 | Create | 30-39 |
| 33 | test_ddneed_32_column_dropdown_loads_via_ajax | TC-DDNEED-P32 | Create | 30-39 |
| 34 | test_ddneed_33_menu_category_loads_via_ajax | TC-DDNEED-P33 | Create | 30-39 |
| 35 | test_ddneed_34_main_menu_loads_via_ajax | TC-DDNEED-P34 | Create | 30-39 |
| 36 | test_ddneed_35_sub_menu_loads_via_ajax | TC-DDNEED-P35 | Create | 30-39 |
| 37 | test_ddneed_36_menu_fields_toggle_with_tenant_creation | TC-DDNEED-P36 | Create | 30-39 |
| 38 | test_ddneed_40_store_creates_dropdown_need | TC-DDNEED-P40 | Store | 40-49 |
| 39 | test_ddneed_41_store_with_tenant_creation_allowed | TC-DDNEED-P41 | Store | 40-49 |
| 40 | test_ddneed_42_store_without_tenant_creation_menu_nulled | TC-DDNEED-P42 | Store | 40-49 |
| 41 | test_ddneed_43_is_active_defaults_to_true | TC-DDNEED-P43 | Store | 40-49 |
| 42 | test_ddneed_44_dropdown_table_record_exist_defaults | TC-DDNEED-P44 | Store | 40-49 |
| 43 | test_ddneed_45_store_logs_created_activity | TC-DDNEED-P45 | Store | 40-49 |
| 44 | test_ddneed_46_store_redirects_with_success | TC-DDNEED-P46 | Store | 40-49 |
| 45 | test_ddneed_50_db_type_required_rejected | TC-DDNEED-N50 | Val | 50-69 |
| 46 | test_ddneed_51_db_type_invalid_rejected | TC-DDNEED-N51 | Val | 50-69 |
| 47 | test_ddneed_52_table_name_required_rejected | TC-DDNEED-N52 | Val | 50-69 |
| 48 | test_ddneed_53_column_name_required_rejected | TC-DDNEED-N53 | Val | 50-69 |
| 49 | test_ddneed_54_tenant_creation_menu_category_required | TC-DDNEED-N54 | Val | 50-69 |
| 50 | test_ddneed_55_tenant_creation_main_menu_required | TC-DDNEED-N55 | Val | 50-69 |
| 51 | test_ddneed_56_tenant_creation_sub_menu_required | TC-DDNEED-N56 | Val | 50-69 |
| 52 | test_ddneed_57_tenant_creation_tab_name_required | TC-DDNEED-N57 | Val | 50-69 |
| 53 | test_ddneed_58_tenant_creation_field_name_required | TC-DDNEED-N58 | Val | 50-69 |
| 54 | test_ddneed_59_table_name_max_length | TC-DDNEED-N59 | Val | 50-69 |
| 55 | test_ddneed_60_column_name_max_length | TC-DDNEED-N60 | Val | 50-69 |
| 56 | test_ddneed_70_show_page_displays_all_fields | TC-DDNEED-P70 | Show | 70-79 |
| 57 | test_ddneed_71_show_shows_dash_for_null_fields | TC-DDNEED-P71 | Show | 70-79 |
| 58 | test_ddneed_72_show_invalid_id_returns_404 | TC-DDNEED-N72 | Show | 70-79 |
| 59 | test_ddneed_73_show_soft_deleted_id_returns_404 | TC-DDNEED-N73 | Show | 70-79 |
| 60 | test_ddneed_80_edit_page_prefills_values | TC-DDNEED-P80 | Edit | 80-89 |
| 61 | test_ddneed_81_edit_system_record_blocked | TC-DDNEED-P81 | Edit | 80-89 |
| 62 | test_ddneed_82_edit_invalid_id_returns_404 | TC-DDNEED-N82 | Edit | 80-89 |
| 63 | test_ddneed_83_edit_system_record_rejected | TC-DDNEED-N83 | Edit | 80-89 |
| 64 | test_ddneed_90_update_modifies_and_logs | TC-DDNEED-P90 | Update | 90-99 |
| 65 | test_ddneed_91_update_changes_is_active | TC-DDNEED-P91 | Update | 90-99 |
| 66 | test_ddneed_92_update_clears_menu_when_tenant_disabled | TC-DDNEED-P92 | Update | 90-99 |
| 67 | test_ddneed_93_update_redirects_with_success | TC-DDNEED-P93 | Update | 90-99 |
| 68 | test_ddneed_94_update_system_record_blocked | TC-DDNEED-N94 | Update | 90-99 |
| 69 | test_ddneed_95_update_invalid_db_type_rejected | TC-DDNEED-N95 | Update | 90-99 |
| 70 | test_ddneed_100_destroy_soft_deletes_and_deactivates | TC-DDNEED-P100 | Destroy | 100-109 |
| 71 | test_ddneed_101_destroy_redirects_with_success | TC-DDNEED-P101 | Destroy | 100-109 |
| 72 | test_ddneed_102_destroy_system_record_blocked | TC-DDNEED-N102 | Destroy | 100-109 |
| 73 | test_ddneed_103_destroy_non_existing_404 | TC-DDNEED-N103 | Destroy | 100-109 |
| 74 | test_ddneed_110_trash_lists_soft_deleted | TC-DDNEED-P110 | Trash | 110-119 |
| 75 | test_ddneed_111_trash_has_restore_and_force_delete_buttons | TC-DDNEED-P111 | Trash | 110-119 |
| 76 | test_ddneed_112_trash_paginated | TC-DDNEED-P112 | Trash | 110-119 |
| 77 | test_ddneed_120_restore_recovers_and_logs | TC-DDNEED-P120 | Restore | 120-129 |
| 78 | test_ddneed_121_restore_redirects_with_success | TC-DDNEED-P121 | Restore | 120-129 |
| 79 | test_ddneed_122_restore_non_trashed_404 | TC-DDNEED-N122 | Restore | 120-129 |
| 80 | test_ddneed_130_force_delete_permanently_removes | TC-DDNEED-P130 | ForceDel | 130-139 |
| 81 | test_ddneed_131_force_delete_redirects_with_success | TC-DDNEED-P131 | ForceDel | 130-139 |
| 82 | test_ddneed_132_force_delete_non_trashed_404 | TC-DDNEED-N132 | ForceDel | 130-139 |
| 83 | test_ddneed_140_toggle_active_to_inactive | TC-DDNEED-P140 | Toggle | 140-149 |
| 84 | test_ddneed_141_toggle_inactive_to_active | TC-DDNEED-P141 | Toggle | 140-149 |
| 85 | test_ddneed_142_toggle_returns_json_response | TC-DDNEED-P142 | Toggle | 140-149 |
| 86 | test_ddneed_143_toggle_logs_activity | TC-DDNEED-P143 | Toggle | 140-149 |
| 87 | test_ddneed_150_get_migration_tables_prime | TC-DDNEED-P150 | AJAX | 150-159 |
| 88 | test_ddneed_151_get_migration_tables_global | TC-DDNEED-P151 | AJAX | 150-159 |
| 89 | test_ddneed_152_get_migration_tables_tenant | TC-DDNEED-P152 | AJAX | 150-159 |
| 90 | test_ddneed_153_get_migration_tables_invalid | TC-DDNEED-N153 | AJAX | 150-159 |
| 91 | test_ddneed_160_get_migration_content_valid | TC-DDNEED-P160 | AJAX | 160-169 |
| 92 | test_ddneed_161_get_migration_content_invalid | TC-DDNEED-N161 | AJAX | 160-169 |
| 93 | test_ddneed_170_get_table_columns_valid | TC-DDNEED-P170 | AJAX | 170-179 |
| 94 | test_ddneed_171_get_table_columns_empty_params | TC-DDNEED-N171 | AJAX | 170-179 |
| 95 | test_ddneed_172_get_table_columns_invalid_db_type | TC-DDNEED-N172 | AJAX | 170-179 |
| 96 | test_ddneed_180_get_menu_data | TC-DDNEED-P180 | AJAX | 180-189 |
| 97 | test_ddneed_181_get_main_menus | TC-DDNEED-P181 | AJAX | 180-189 |
| 98 | test_ddneed_182_get_sub_menus | TC-DDNEED-P182 | AJAX | 180-189 |
| 99 | test_ddneed_190_search_with_keyword | TC-DDNEED-P190 | AJAX | 190-199 |
| 100 | test_ddneed_191_search_without_keyword | TC-DDNEED-N191 | AJAX | 190-199 |
| 101 | test_ddneed_20_stored_xss_is_escaped_on_render | TC-DDNEED-P20 | Security | 20 |

**Total: 101 methods (98 Automated, 3 Planned).**
