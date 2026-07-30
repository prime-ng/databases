# SYS — sys_DropdownNeeds — Test Case List & Business Conditions

**Module:** SystemConfig (SYS) · **Feature:** Dropdown Needs Registry
**Code:** SYS · **Prefix:** `sys_` · **DB scope:** Central (`sys_dropdown_needs` in prime_db)
**Primary table:** `sys_dropdown_needs` · **Junction table:** `sys_dropdown_need_dropdowns_jnt`
**Test style:** HTTP Feature Tests (PHPUnit/Pest) · **Controller:** `TenantDropdownNeedController` (988 lines)

**Routes (prefix `system-config.`):**

CRUD:
- `GET|POST /system-config/dropdown-need` — index (GET), store (POST)
- `GET /system-config/dropdown-need/create` — create form
- `GET /system-config/dropdown-need/filter-options` — AJAX filter
- `GET /system-config/dropdown-need/{id}` — show
- `GET|PUT /system-config/dropdown-need/{id}/edit` — edit (GET), update (PUT)
- `DELETE /system-config/dropdown-need/{id}` — destroy
- `GET /system-config/dropdown-need/trash/view` — trashed list
- `GET /system-config/dropdown-need/{id}/restore` — restore
- `DELETE /system-config/dropdown-need/{id}/force-delete` — force delete
- `POST /system-config/dropdown-need/{id}/toggle-status` — toggle status

AJAX / Bulk / Mapping:
- `GET /system-config/dropdown-need-api/menu-data` — menu hierarchy
- `GET /system-config/dropdown-need-api/main-menus/{category}` — main menus drill-down
- `GET /system-config/dropdown-need-api/sub-menus/{main}` — sub menus drill-down
- `GET /system-config/dropdown-need-api/tables` — tenant tables
- `GET /system-config/dropdown-need-api/filter-options` — filter options (API)
- `GET /system-config/dropdown-need-api/search` — search
- `POST /system-config/dropdowns/save-option` — transactional create+map
- `POST /system-config/dropdowns/update-bulk` — bulk update
- `POST /system-config/dropdowns/delete-bulk` — bulk delete
- `POST /system-config/dropdowns/map-to-need` — map values to need
- `POST /system-config/dropdowns/remove-mapping` — unmap values from need

Master index (`/system-config/dropdown`):
- `GET /system-config/dropdown` — 4-tab master view (also serves Dropdown Value Management)

---

## 1. Business Conditions

### BC-SCHEMA — Schema & Model

| ID          | Condition | Source |
|-------------|-----------|--------|
| BC-SCHEMA-01 | Table `sys_dropdown_needs` exists with columns: `id` (INT PK AI), `db_type` (VARCHAR 20), `table_name` (VARCHAR 150), `column_name` (VARCHAR 150), `menu_category` (VARCHAR 150 NULL), `main_menu` (VARCHAR 150 NULL), `sub_menu` (VARCHAR 150 NULL), `tab_name` (VARCHAR 100 NULL), `field_name` (VARCHAR 100 NULL), `is_system` (TINYINT), `tenant_creation_allowed` (TINYINT), `compulsory` (TINYINT), `dropdown_tabel_record_exist` (TINYINT DEFAULT 0), `is_active` (TINYINT DEFAULT 1), `created_at`, `updated_at`, `deleted_at` | DDL: prime_db_v3.sql:176-196 |
| BC-SCHEMA-02 | Model `DropdownNeed`: table `sys_dropdown_needs`, uses `SoftDeletes` + `BaseModel` | DropdownNeed.php:8-12 |
| BC-SCHEMA-03 | Fillable: `db_type`, `table_name`, `column_name`, `menu_category`, `main_menu`, `sub_menu`, `tab_name`, `field_name`, `is_system`, `tenant_creation_allowed`, `compulsory`, `dropdown_table_record_exist`, `is_active` | DropdownNeed.php:14-28 |
| BC-SCHEMA-04 | Casts: all boolean fields → `boolean`, `deleted_at` → `datetime` | DropdownNeed.php:30-37 |
| BC-SCHEMA-05 | Relationship `dropdowns()`: belongsToMany via `sys_dropdown_need_dropdowns_jnt`, `dropdown_needs_id`, `dropdown_table_id`, with pivot `is_active` | DropdownNeed.php:39-48 |
| BC-SCHEMA-06 | Relationship `activeDropdowns()`: filtered by active pivot + active dropdown | DropdownNeed.php:50-56 |
| BC-SCHEMA-07 | 8 filter scopes: `filterByDbType`, `filterByTableName`, `filterByColumnName`, `filterByMenuCategory`, `filterByMainMenu`, `filterBySubMenu`, `filterByTabName`, `filterByFieldName` | DropdownNeed.php:58-120 |
| BC-SCHEMA-08 | Static helper: `getDistinctValues($column)` returns distinct non-null active values | DropdownNeed.php:122-130 |
| BC-SCHEMA-09 | Scopes: `withDropdownCount()`, `withActiveDropdownCount()` | DropdownNeed.php:132-145 |
| BC-SCHEMA-10 | Junction table `sys_dropdown_need_dropdowns_jnt` exists with `id`, `dropdown_needs_id`, `dropdown_table_id`, `is_active`, `created_at`, `updated_at` | DDL: prime_db_v3.sql:258-270 |
| BC-SCHEMA-11 | Junction model `DropdownNeedDropdown`: table `sys_dropdown_need_dropdowns_jnt`, fillable `dropdown_needs_id`, `dropdown_table_id`, `is_active` | DropdownNeedDropdown.php:8-17 |
| BC-SCHEMA-12 | UNIQUE KEY `uq_DDNeeds_dbType_tableName_columnName` on (`db_type`, `table_name`, `column_name`) — BR-SYS-014 | DDL: prime_db_v3.sql:194 |
| BC-SCHEMA-13 | UNIQUE KEY `uq_DDNeeds_category_mainMenu_subMenu_tabName_fieldName` on (`menu_category`, `main_menu`, `sub_menu`, `tab_name`, `field_name`) | DDL: prime_db_v3.sql:195 |

### BC-VALIDATION — Validation Rules

| ID               | Condition | Source |
|------------------|-----------|--------|
| BC-VALIDATION-01 | `db_type`: required, in:Prime,Tenant,Global | Ctrl:391 |
| BC-VALIDATION-02 | `table_name`: required, string, max:150 | Ctrl:392 |
| BC-VALIDATION-03 | `column_name`: required, string, max:150 | Ctrl:393 |
| BC-VALIDATION-04 | `tenant_creation_allowed`: required, boolean | Ctrl:394 |
| BC-VALIDATION-05 | `menu_category`: nullable, string, max:150 (conditional required) | Ctrl:395 |
| BC-VALIDATION-06 | `main_menu`: nullable, string, max:150 (conditional required) | Ctrl:396 |
| BC-VALIDATION-07 | `sub_menu`: nullable, string, max:150 (conditional required) | Ctrl:397 |
| BC-VALIDATION-08 | `tab_name`: nullable, string, max:100 (conditional required) | Ctrl:398 |
| BC-VALIDATION-09 | `field_name`: nullable, string, max:100 (conditional required) | Ctrl:399 |
| BC-VALIDATION-10 | `is_system`: required, boolean | Ctrl:400 |
| BC-VALIDATION-11 | `compulsory`: required, boolean | Ctrl:401 |
| BC-VALIDATION-12 | `dropdown_table_record_exist`: nullable, boolean | Ctrl:402 |
| BC-VALIDATION-13 | `is_active`: nullable, boolean (defaults true on store) | Ctrl:403,422 |
| BC-VALIDATION-14 | When `tenant_creation_allowed=false` → all 5 menu fields forced to null before save | Ctrl:414-420 |
| BC-VALIDATION-15 | Store validates same fields; `is_active` uses `$request->boolean('is_active')` | Ctrl:472-496 |
| BC-VALIDATION-16 | `saveDropdownOption` validates: `dropdown_need_id` exists, `key` required max:160, `value` required max:255, `additional_info` nullable string, `type` nullable in:String/Integer/Decimal/Date/Boolean | Ctrl:733-739 |
| BC-VALIDATION-17 | `updateBulk` validates: `rows` required array; each row: `id` required exists, `ordinal` nullable integer, `value` required max:255, `type` nullable, `additional_info` nullable max:1000 | Ctrl:781-788 |
| BC-VALIDATION-18 | `mapDropdownsToNeed` validates: `dropdown_needs_id` required exists, `dropdown_ids` required array each exists | Ctrl:850-854 |
| BC-VALIDATION-19 | `removeMapping` validates: same as mapDropdownsToNeed | Ctrl:898-902 |
| BC-VALIDATION-20 | `toggleStatus` validates: `is_active` required boolean | Ctrl:591-593 |

### BC-AUTH — Authorization

| ID       | Condition | Source |
|----------|-----------|--------|
| BC-AUTH-01 | `index()` gate `tenant.dropdown.viewAny` | Ctrl:19 |
| BC-AUTH-02 | `create()`/`store()` gate `tenant.dropdown.create` | Ctrl:381,387 |
| BC-AUTH-03 | `show()` gate `tenant.dropdown.view` | Ctrl:437 |
| BC-AUTH-04 | `edit()`/`update()` gate `tenant.dropdown.update` | Ctrl:448,460 |
| BC-AUTH-05 | `destroy()` gate `tenant.dropdown.delete` | Ctrl:508 |
| BC-AUTH-06 | `trashed()`/`restore()` gate `tenant.dropdown.restore` | Ctrl:537,546 |
| BC-AUTH-07 | `forceDelete()` gate `tenant.dropdown.forceDelete` | Ctrl:567 |
| BC-AUTH-08 | `toggleStatus()` gate `tenant.dropdown.update` | Ctrl:589 |
| BC-AUTH-09 | `saveDropdownOption()` gate `tenant.dropdown.create` | Ctrl:731 |
| BC-AUTH-10 | `updateBulk()` gate `tenant.dropdown.update` | Ctrl:778 |
| BC-AUTH-11 | `deleteBulk()` gate `tenant.dropdown.delete` | Ctrl:819 |
| BC-AUTH-12 | `mapDropdownsToNeed()` gate `tenant.dropdown.update` | Ctrl:848 |
| BC-AUTH-13 | `removeMapping()` gate `tenant.dropdown.update` | Ctrl:896 |
| BC-AUTH-14 | **NO Gate on:** `filterOptions`, `getMenuData`, `getMainMenus`, `getSubMenus`, `getTenantTables`, `getFilterOptions`, `search` | Ctrl |

### BC-BIZ — Business Logic

| ID     | Condition | Source |
|--------|-----------|--------|
| BC-BIZ-01 | Master index `system-config.dropdown` is entry for all 4 tabs; `tab`/`active_tab` param switches current tab; default tab is `dropdown-need` | Ctrl:21 |
| BC-BIZ-02 | Index loads: categories, dbTypes, tables, columns (distinct from DropdownNeed); mainMenus/subMenus/tabs/fields filtered by parent selections | Ctrl:40-106 |
| BC-BIZ-03 | First active need matching filters is the `selectedDropdownNeed` — drives mapped/unmapped data | Ctrl:136 |
| BC-BIZ-04 | `is_system=true` records CANNOT be edited — redirects with "System records cannot be edited." | Ctrl:451-455 |
| BC-BIZ-05 | `is_system=true` records CANNOT be deleted — redirects with "System records cannot be deleted." | Ctrl:513-517 |
| BC-BIZ-06 | `is_system=true` records CAN be toggled — NO guard in `toggleStatus()` | Ctrl:595-615 |
| BC-BIZ-07 | `destroy()` deactivates junction entries, sets `is_active=false`, soft-deletes, logs 'Trashed' | Ctrl:519-533 |
| BC-BIZ-08 | `restore()` restores need, sets `is_active=true`, reactivates junction entries, logs 'Restored' | Ctrl:544-563 |
| BC-BIZ-09 | `forceDelete()` force-deletes junction entries first, then force-deletes need, logs 'Deleted' | Ctrl:567-584 |
| BC-BIZ-10 | `toggleStatus()` flips `is_active`, cascades to all junction entries, logs 'Toggled', returns JSON | Ctrl:587-615 |
| BC-BIZ-11 | `saveDropdownOption()` creates dropdown + junction in transaction; ordinal = MAX+1; returns JSON | Ctrl:729-773 |
| BC-BIZ-12 | `updateBulk()` updates rows in transaction; preserves `additional_info` if not provided | Ctrl:776-814 |
| BC-BIZ-13 | `deleteBulk()` deactivates junctions, soft-deletes dropdowns, returns JSON | Ctrl:817-843 |
| BC-BIZ-14 | `mapDropdownsToNeed()` maps dropdowns: reactivates existing OR inserts new junction; counts only new/activated | Ctrl:846-891 |
| BC-BIZ-15 | `removeMapping()` sets junction `is_active=false`; returns count of removed | Ctrl:894-919 |
| BC-BIZ-16 | `getMenuData()` fetches `glb_menus` from `global_master_mysql`; returns categories, main_menus, sub_menus based on `is_category`/`parent_id` | Ctrl:617-662 |
| BC-BIZ-17 | `getMainMenus($category)` returns menus where `parent_id` matches category ID from `glb_menus` | Ctrl:665-695 |
| BC-BIZ-18 | `getSubMenus($mainMenu)` returns menus where `parent_id` matches main menu ID | Ctrl:698-726 |
| BC-BIZ-19 | `getFilterOptions()` / `filterOptions()` return distinct related values based on applied filters (7 field types) | Ctrl:338-377, 922-961 |
| BC-BIZ-20 | `search()` returns top 10 needs by table_name/column_name/field_name LIKE | Ctrl:964-975 |
| BC-BIZ-21 | `getTenantTables()` runs `SHOW TABLES` on tenant connection and returns array | Ctrl:977-987 |
| BC-BIZ-22 | All write methods call `activityLog()` for audit trail (BR-SYS-012) | Ctrl:427, 498, 526, 557, 579, 602 |
| BC-BIZ-23 | Index receives 28+ view variables: filters, paginated needs, mapped/unmapped dropdowns, grouped dropdowns, menu hierarchy | Ctrl:300-335 |

### BC-EDGE — Edge Cases

| ID       | Condition | Source |
|----------|-----------|--------|
| BC-EDGE-01 | Non-existing ID → 404 (findOrFail) | Ctrl |
| BC-EDGE-02 | `withTrashed()->findOrFail()` for restore/forceDelete → 404 if not in trash | Ctrl:548,570 |
| BC-EDGE-03 | Edit/update/destroy on `is_system=true` → blocked with error flash | Ctrl:451,466,513 |
| BC-EDGE-04 | DB unique constraint violation (duplicate combo) → 500 Server Error (no graceful handling) | DDL:194 |
| BC-EDGE-05 | `getMenuData` exception → returns empty arrays | Ctrl:656-662 |
| BC-EDGE-06 | `getMainMenus`/`getSubMenus` category not found → returns empty array | Ctrl:678,710 |
| BC-EDGE-07 | `getTenantTables` exception → returns error JSON with message | Ctrl:984-986 |
| BC-EDGE-08 | No `selectedDropdownNeed` in index → mapped/unmapped return id=0 empty paginator | Ctrl:153-154, 201-203 |
| BC-EDGE-09 | `db_type` param not 'Tenant' in AJAX menu methods → defaults to 'prime' menu_for | Ctrl:620, 669, 702 |
| BC-EDGE-10 | `saveDropdownOption` transaction failure → JSON error response | Ctrl:768-773 |
| BC-EDGE-11 | `updateBulk` with empty `rows` array → validation error | Ctrl:782 |
| BC-EDGE-12 | `deleteBulk` with non-existent IDs → skipped silently, others proceed | Ctrl:822-832 |
| BC-EDGE-13 | `mapDropdownsToNeed` with all already-mapped IDs → returns 0 count but no error | Ctrl:856-879 |
| BC-EDGE-14 | `toggleStatus` on non-existent ID → 404 (findOrFail) | Ctrl:595 |

---

## 2. Test Case List

### Cross-Cutting — Schema, Model, Auth

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P01 | Schema | DDL/Model | Migration, model, table (`sys_dropdown_needs`), fillable (13 fields), casts, SoftDeletes | All pass | — | ⬜ |
| TC-DDN-P02 | Schema | DDL/Model | Junction model `DropdownNeedDropdown` exists, table `sys_dropdown_need_dropdowns_jnt`, fillable, BelongsTo relationships | All present | — | ⬜ |
| TC-DDN-P03 | Schema | Routes | All CRUD + AJAX + bulk + mapping routes registered in `routes/tenant.php` | 22+ routes present | — | ⬜ |
| TC-DDN-P04 | Schema | Model | All 8 filter scopes defined and functional | 8 scopes | — | ⬜ |
| TC-DDN-P05 | Schema | Model | Relationship `dropdowns()` works with pivot `is_active` | Correct relation | — | ⬜ |
| TC-DDN-P06 | Schema | DDL | UNIQUE KEY `uq_DDNeeds_dbType_tableName_columnName` exists | Constraint present | — | ⬜ |
| TC-DDN-P07 | Schema | DDL | UNIQUE KEY `uq_DDNeeds_category_mainMenu_subMenu_tabName_fieldName` exists | Constraint present | — | ⬜ |
| TC-DDN-P10 | Auth | Middleware | Guest user redirected to login for all routes | /login | — | ⬜ |
| TC-DDN-P11 | Auth | Ctrl | Gate authorization present on all 13 protected methods | Gates present | — | ⬜ |
| TC-DDN-N12 | Auth | Ctrl | User without `tenant.dropdown.viewAny` → 403 on index | 403 | — | ⬜ |
| TC-DDN-N13 | Auth | Ctrl | User without `tenant.dropdown.create` → 403 on create/store/saveDropdownOption | 403 | — | ⬜ |
| TC-DDN-N14 | Auth | Ctrl | User without `tenant.dropdown.view` → 403 on show | 403 | — | ⬜ |
| TC-DDN-N15 | Auth | Ctrl | User without `tenant.dropdown.update` → 403 on edit/update/toggleStatus/updateBulk/mapDropdownsToNeed/removeMapping | 403 | — | ⬜ |
| TC-DDN-N16 | Auth | Ctrl | User without `tenant.dropdown.delete` → 403 on destroy/deleteBulk | 403 | — | ⬜ |
| TC-DDN-N17 | Auth | Ctrl | User without `tenant.dropdown.restore` → 403 on trashed/restore | 403 | — | ⬜ |
| TC-DDN-N18 | Auth | Ctrl | User without `tenant.dropdown.forceDelete` → 403 on forceDelete | 403 | — | ⬜ |

### Screen 1: Index — Dropdown Needs Tab (GET /system-config/dropdown-need)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P30 | Positive | Ctrl | Dropdown Needs tab renders with cascading filters and results table | Page rendered | — | ⬜ |
| TC-DDN-P31 | Positive | Ctrl | Filter by `db_type` narrows results | Filtered | — | ⬜ |
| TC-DDN-P32 | Positive | Ctrl | Filter by `table_name` narrows results | Filtered | — | ⬜ |
| TC-DDN-P33 | Positive | Ctrl | Filter by `column_name` narrows results | Filtered | — | ⬜ |
| TC-DDN-P34 | Positive | Ctrl | Filter by `menu_category` narrows results | Filtered | — | ⬜ |
| TC-DDN-P35 | Positive | Ctrl | Filter by `main_menu` respects category selection | Filtered | — | ⬜ |
| TC-DDN-P36 | Positive | Ctrl | Filter by `sub_menu` respects category + main menu | Filtered | — | ⬜ |
| TC-DDN-P37 | Positive | Ctrl | Filter by `tab_name` respects previous selections | Filtered | — | ⬜ |
| TC-DDN-P38 | Positive | Ctrl | Filter by `field_name` respects previous selections | Filtered | — | ⬜ |
| TC-DDN-P39 | Positive | Ctrl | Combined filters work together | Filtered | — | ⬜ |
| TC-DDN-P40 | Positive | Ctrl | Result set paginated (10 per page, `needs_page` param) | Paginated | — | ⬜ |
| TC-DDN-P41 | Positive | View | Each row displays DB Type, Table, Column, Menu Category, Main Menu, Sub Menu, Tab, Field, Status toggle, Actions | All columns | — | ⬜ |
| TC-DDN-P42 | Positive | View | Action buttons: View, Edit, Delete (system rows: View only) | Gated | — | ⬜ |
| TC-DDN-P43 | Positive | View | Status toggle switch present on every row | Toggle present | — | ⬜ |
| TC-DDN-P44 | Positive | View | Empty state when no records match filters | "Not Data Found" | — | ⬜ |
| TC-DDN-P45 | Positive | View | "Add New" button links to create page | Link works | — | ⬜ |
| TC-DDN-P46 | Positive | View | Trash link visible and links to trash view | Link works | — | ⬜ |

### Screen 2: Create Form (GET /system-config/dropdown-need/create)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P50 | Positive | View | Create page renders all 13 form fields | All fields rendered | — | ⬜ |
| TC-DDN-P51 | Positive | View | `tenant_creation_allowed=Yes` → menu fields enabled; `No` → disabled/cleared | Toggle behavior | — | ⬜ |

### Screen 3: Store (POST /system-config/dropdown-need)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P60 | Positive | Ctrl | Valid store creates dropdown need with all required fields | Row created | — | ⬜ |
| TC-DDN-P61 | Positive | Ctrl | Store with tenant_creation_allowed=true AND all 5 menu fields → success | Created | — | ⬜ |
| TC-DDN-P62 | Positive | Ctrl | Store with tenant_creation_allowed=false → menu fields forced to null | Menu fields NULL | — | ⬜ |
| TC-DDN-P63 | Positive | Ctrl | `is_active` defaults to true when not provided | is_active=1 | — | ⬜ |
| TC-DDN-P64 | Positive | Ctrl | Store logs 'Created' activity | Log entry | — | ⬜ |
| TC-DDN-P65 | Positive | Ctrl | Store redirects to `system-config.dropdown-need.index` with success flash | Redirect + flash | — | ⬜ |
| TC-DDN-N70 | Negative | Ctrl | `db_type` empty → rejected | 422 | — | ⬜ |
| TC-DDN-N71 | Negative | Ctrl | `db_type` invalid → rejected | 422 | — | ⬜ |
| TC-DDN-N72 | Negative | Ctrl | `table_name` empty → rejected | 422 | — | ⬜ |
| TC-DDN-N73 | Negative | Ctrl | `column_name` empty → rejected | 422 | — | ⬜ |
| TC-DDN-N74 | Negative | Ctrl | `tenant_creation_allowed=true` + menu_category empty → rejected | 422 | — | ⬜ |
| TC-DDN-N75 | Negative | Ctrl | `tenant_creation_allowed=true` + main_menu empty → rejected | 422 | — | ⬜ |
| TC-DDN-N76 | Negative | Ctrl | `tenant_creation_allowed=true` + sub_menu empty → rejected | 422 | — | ⬜ |
| TC-DDN-N77 | Negative | Ctrl | `tenant_creation_allowed=true` + tab_name empty → rejected | 422 | — | ⬜ |
| TC-DDN-N78 | Negative | Ctrl | `tenant_creation_allowed=true` + field_name empty → rejected | 422 | — | ⬜ |
| TC-DDN-N79 | Negative | Ctrl | Duplicate (db_type, table_name, column_name) → DB constraint violation (500 — not graceful) | 500 | — | ⬜ |
| TC-DDN-N80 | Negative | Ctrl | `table_name` exceeds 150 chars → rejected | 422 | — | ⬜ |
| TC-DDN-N81 | Negative | Ctrl | `column_name` exceeds 150 chars → rejected | 422 | — | ⬜ |

### Screen 4: Show (GET /system-config/dropdown-need/{id})

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P90 | Positive | View | Show page displays all fields: db_type, table_name, column_name, is_system, etc. | All fields displayed | — | ⬜ |
| TC-DDN-P91 | Positive | View | Show page shows dash/placeholder for null menu fields | Dash shown | — | ⬜ |
| TC-DDN-N92 | Negative | Ctrl | Invalid ID → 404 | 404 | — | ⬜ |
| TC-DDN-N93 | Negative | Ctrl | Soft-deleted ID → 404 | 404 | — | ⬜ |

### Screen 5: Edit (GET /system-config/dropdown-need/{id}/edit)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P100 | Positive | View | Edit page pre-fills with existing values for all fields | Pre-filled | — | ⬜ |
| TC-DDN-N101 | Negative | Ctrl | `is_system=true` → redirects to index with "System records cannot be edited." | Redirect + error | — | ⬜ |
| TC-DDN-N102 | Negative | Ctrl | Invalid ID → 404 | 404 | — | ⬜ |

### Screen 6: Update (PUT /system-config/dropdown-need/{id})

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P110 | Positive | Ctrl | Update modifies record and logs 'Updated' activity | Updated + log | — | ⬜ |
| TC-DDN-P111 | Positive | Ctrl | Update changes `is_active` from 1 to 0 | Inactivated | — | ⬜ |
| TC-DDN-P112 | Positive | Ctrl | Update changes `tenant_creation_allowed` from 1 to 0 → menu fields cleared to null | Cleared | — | ⬜ |
| TC-DDN-P113 | Positive | Ctrl | Update redirects with success flash | Redirect + flash | — | ⬜ |
| TC-DDN-N114 | Negative | Ctrl | Update on `is_system=true` → blocked with error | Blocked | — | ⬜ |
| TC-DDN-N115 | Negative | Ctrl | Update with invalid `db_type` → 422 | 422 | — | ⬜ |

### Screen 7: Destroy (DELETE /system-config/dropdown-need/{id})

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P120 | Positive | Ctrl | Destroy soft-deletes need, sets is_active=false, deactivates junctions, logs 'Trashed' | Soft-deleted | — | ⬜ |
| TC-DDN-P121 | Positive | Ctrl | Destroy redirects with success flash | Redirect + flash | — | ⬜ |
| TC-DDN-N122 | Negative | Ctrl | Destroy on `is_system=true` → blocked with error | Blocked | — | ⬜ |
| TC-DDN-N123 | Negative | Ctrl | Destroy on non-existing ID → 404 | 404 | — | ⬜ |

### Screen 8: Trash (GET /system-config/dropdown-need/trash/view)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P130 | Positive | View | Trash page lists soft-deleted needs only | Trashed listed | — | ⬜ |
| TC-DDN-P131 | Positive | View | Each trashed row has Restore and Force Delete buttons | 2 buttons | — | ⬜ |
| TC-DDN-P132 | Positive | View | Trash page paginated (10/page) | Paginated | — | ⬜ |

### Screen 9: Restore (GET /system-config/dropdown-need/{id}/restore)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P140 | Positive | Ctrl | Restore recovers record, sets is_active=true, reactivates junctions, logs 'Restored' | Restored | — | ⬜ |
| TC-DDN-P141 | Positive | Ctrl | Restore redirects to trash view with success flash | Redirect + flash | — | ⬜ |
| TC-DDN-N142 | Negative | Ctrl | Restore on non-trashed/non-existing ID → 404 | 404 | — | ⬜ |

### Screen 10: Force Delete (DELETE /system-config/dropdown-need/{id}/force-delete)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P150 | Positive | Ctrl | Force delete permanently removes need + junctions, logs 'Deleted' | Deleted | — | ⬜ |
| TC-DDN-P151 | Positive | Ctrl | Force delete redirects to trash view with success flash | Redirect + flash | — | ⬜ |
| TC-DDN-N152 | Negative | Ctrl | Force delete on non-trashed ID → 404 | 404 | — | ⬜ |

### Screen 11: Toggle Status (POST /system-config/dropdown-need/{id}/toggle-status)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P160 | Positive | Ctrl | Toggle active→inactive: is_active flips to false, junctions updated | is_active=false | — | ⬜ |
| TC-DDN-P161 | Positive | Ctrl | Toggle inactive→active: is_active flips to true, junctions updated | is_active=true | — | ⬜ |
| TC-DDN-P162 | Positive | Ctrl | Toggle returns JSON `{success: true, is_active, message}` | JSON response | — | ⬜ |
| TC-DDN-P163 | Positive | Ctrl | Toggle logs 'Toggled' activity | Log entry | — | ⬜ |

### Screen 12: AJAX — Menu Data (GET /system-config/dropdown-need-api/menu-data)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P170 | Positive | Ctrl | getMenuData returns categories, main_menus, sub_menus from glb_menus | JSON with 3 arrays | — | ⬜ |
| TC-DDN-P171 | Positive | Ctrl | getMainMenus(category) returns main menus for the category | Array | — | ⬜ |
| TC-DDN-P172 | Positive | Ctrl | getSubMenus(mainMenu) returns sub menus for the main menu | Array | — | ⬜ |
| TC-DDN-N173 | Negative | Ctrl | getMainMenus with non-existent category → empty JSON array | [] | — | ⬜ |
| TC-DDN-N174 | Negative | Ctrl | getSubMenus with non-existent main menu → empty JSON array | [] | — | ⬜ |

### Screen 13: AJAX — Filter Options & Search

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P180 | Positive | Ctrl | filterOptions returns distinct values for all 7 filter fields | JSON with 7 arrays | — | ⬜ |
| TC-DDN-P181 | Positive | Ctrl | getFilterOptions returns same shape — API variant | JSON with 7 arrays | — | ⬜ |
| TC-DDN-P182 | Positive | Ctrl | search() with keyword returns top 10 LIKE matches | Array ≤10 | — | ⬜ |
| TC-DDN-N183 | Negative | Ctrl | search() without keyword returns empty array | [] | — | ⬜ |

### Screen 14: AJAX — Tenant Tables (GET /system-config/dropdown-need-api/tables)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P190 | Positive | Ctrl | getTenantTables returns array of table names from tenant DB | String array | — | ⬜ |
| TC-DDN-N191 | Negative | Ctrl | getTenantTables when DB error → returns error JSON with message | Error JSON | — | ⬜ |

### Screen 15: Save Dropdown Option (POST /system-config/dropdowns/save-option)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P200 | Positive | Ctrl | saveOption creates dropdown value AND junction in transaction | Created + mapped | — | ⬜ |
| TC-DDN-P201 | Positive | Ctrl | Ordinal auto-assigned as MAX+1 within key group | Correct ordinal | — | ⬜ |
| TC-DDN-P202 | Positive | Ctrl | Returns JSON `{status: true, message}` | JSON success | — | ⬜ |
| TC-DDN-N203 | Negative | Ctrl | Invalid dropdown_need_id → validation error | 422 | — | ⬜ |
| TC-DDN-N204 | Negative | Ctrl | Missing key/value → validation error | 422 | — | ⬜ |
| TC-DDN-N205 | Negative | Ctrl | Invalid type (not in whitelist) → validation error | 422 | — | ⬜ |
| TC-DDN-N206 | Negative | Ctrl | DB error during transaction → JSON error response | 500 JSON | — | ⬜ |

### Screen 16: Bulk Update (POST /system-config/dropdowns/update-bulk)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P210 | Positive | Ctrl | Bulk update multiple rows in single transaction | All updated | — | ⬜ |
| TC-DDN-P211 | Positive | Ctrl | Returns JSON `{success: true, message}` | JSON success | — | ⬜ |
| TC-DDN-N212 | Negative | Ctrl | Empty rows array → validation error | 422 | — | ⬜ |
| TC-DDN-N213 | Negative | Ctrl | Non-existent row ID → validation error (exists rule) | 422 | — | ⬜ |

### Screen 17: Bulk Delete (POST /system-config/dropdowns/delete-bulk)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P220 | Positive | Ctrl | Bulk delete soft-deletes dropdowns + deactivates junctions | Deactivated | — | ⬜ |
| TC-DDN-P221 | Positive | Ctrl | Returns JSON `{status: true, message}` | JSON success | — | ⬜ |
| TC-DDN-N222 | Negative | Ctrl | Non-existent IDs → silently skipped | Others deleted | — | ⬜ |

### Screen 18: Map / Unmap Dropdowns (POST /system-config/dropdowns/map-to-need, remove-mapping)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P230 | Positive | Ctrl | mapDropdownsToNeed creates junctions for all valid dropdown IDs | Mapped | — | ⬜ |
| TC-DDN-P231 | Positive | Ctrl | mapDropdownsToNeed reactivates existing inactive junction | Reactivated | — | ⬜ |
| TC-DDN-P232 | Positive | Ctrl | mapDropdownsToNeed returns JSON with count | JSON {success, message} | — | ⬜ |
| TC-DDN-P233 | Positive | Ctrl | removeMapping sets is_active=false on matching junctions | Unmapped | — | ⬜ |
| TC-DDN-P234 | Positive | Ctrl | removeMapping returns JSON with count of removed | JSON {success, message} | — | ⬜ |
| TC-DDN-N235 | Negative | Ctrl | Invalid dropdown_needs_id → validation error | 422 | — | ⬜ |
| TC-DDN-N236 | Negative | Ctrl | Empty dropdown_ids array → validation error | 422 | — | ⬜ |
| TC-DDN-N237 | Negative | Ctrl | Non-existent dropdown ID → validation error | 422 | — | ⬜ |

### Screen 19: Activity Logging (Cross-Cutting)

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-P240 | Positive | Ctrl | Store logs 'Created' activity with entity type, ID, user | Log entry | — | ⬜ |
| TC-DDN-P241 | Positive | Ctrl | Update logs 'Updated' activity | Log entry | — | ⬜ |
| TC-DDN-P242 | Positive | Ctrl | Destroy logs 'Trashed' activity | Log entry | — | ⬜ |
| TC-DDN-P243 | Positive | Ctrl | Restore logs 'Restored' activity | Log entry | — | ⬜ |
| TC-DDN-P244 | Positive | Ctrl | Force delete logs 'Deleted' activity | Log entry | — | ⬜ |
| TC-DDN-P245 | Positive | Ctrl | ToggleStatus logs 'Toggled' activity | Log entry | — | ⬜ |
| TC-DDN-P246 | Positive | Ctrl | saveDropdownOption logs 'Stored' activity (for the dropdown) | Log entry | — | ⬜ |
| TC-DDN-P247 | Positive | Ctrl | updateBulk logs per-row 'Updated' activity | Log entries | — | ⬜ |
| TC-DDN-P248 | Positive | Ctrl | deleteBulk logs per-dropdown 'Trashed' activity | Log entries | — | ⬜ |

### Screen 20: Edge Cases & Security

| TC ID | Type | Source | Description | Expected | V1/V2 | Status |
|-------|------|--------|-------------|----------|-------|--------|
| TC-DDN-N270 | Negative | Security | XSS attempt in table_name/column_name/field_name stored values is escaped on render | Escaped | — | ⬜ |
| TC-DDN-N271 | Negative | Security | SQL injection attempt in filter parameters is sanitized (parameterized queries) | Safe | — | ⬜ |
| TC-DDN-N272 | Negative | Security | Large payload in bulk update/delete rejected (size limits) | 413/422 | — | ⬜ |
| TC-DDN-N273 | Negative | Edge | Concurrent store with same combo → one succeeds, one fails (DB unique) | 201 + 500 | — | ⬜ |
| TC-DDN-N274 | Negative | Edge | Concurrent bulk update same row → last write wins | Updated | — | ⬜ |
| TC-DDN-N275 | Negative | Edge | `is_system=true` record attempted toggle | Toggle succeeds (no guard) | — | ⬜ |

---

## 3. Test Method Index

**File:** `sys_DropdownNeeds_Test.php` (estimated ~85 methods)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_schema_model_and_table | TC-DDN-P01 | Schema | 01-09 |
| 2 | test_schema_junction_model | TC-DDN-P02 | Schema | 01-09 |
| 3 | test_schema_routes_registered | TC-DDN-P03 | Schema | 01-09 |
| 4 | test_schema_model_scopes | TC-DDN-P04 | Schema | 01-09 |
| 5 | test_schema_model_relationship | TC-DDN-P05 | Schema | 01-09 |
| 6 | test_schema_db_unique_constraints | TC-DDN-P06, P07 | Schema | 01-09 |
| 7 | test_auth_guest_redirected | TC-DDN-P10 | Auth | 10-19 |
| 8 | test_auth_gates_present | TC-DDN-P11 | Auth | 10-19 |
| 9 | test_auth_without_viewAny_gets_403 | TC-DDN-N12 | Auth | 10-19 |
| 10 | test_auth_without_create_gets_403 | TC-DDN-N13 | Auth | 10-19 |
| 11 | test_auth_without_view_gets_403 | TC-DDN-N14 | Auth | 10-19 |
| 12 | test_auth_without_update_gets_403 | TC-DDN-N15 | Auth | 10-19 |
| 13 | test_auth_without_delete_gets_403 | TC-DDN-N16 | Auth | 10-19 |
| 14 | test_auth_without_restore_gets_403 | TC-DDN-N17 | Auth | 10-19 |
| 15 | test_auth_without_forceDelete_gets_403 | TC-DDN-N18 | Auth | 10-19 |
| 16 | test_index_page_renders | TC-DDN-P30 | Index | 30-46 |
| 17 | test_index_filter_by_db_type | TC-DDN-P31 | Index | 30-46 |
| 18 | test_index_filter_by_table_name | TC-DDN-P32 | Index | 30-46 |
| 19 | test_index_filter_by_column_name | TC-DDN-P33 | Index | 30-46 |
| 20 | test_index_filter_by_category | TC-DDN-P34 | Index | 30-46 |
| 21 | test_index_filter_by_main_menu | TC-DDN-P35 | Index | 30-46 |
| 22 | test_index_filter_by_sub_menu | TC-DDN-P36 | Index | 30-46 |
| 23 | test_index_filter_by_tab | TC-DDN-P37 | Index | 30-46 |
| 24 | test_index_filter_by_field | TC-DDN-P38 | Index | 30-46 |
| 25 | test_index_combined_filters | TC-DDN-P39 | Index | 30-46 |
| 26 | test_index_pagination | TC-DDN-P40 | Index | 30-46 |
| 27 | test_index_empty_state | TC-DDN-P44 | Index | 30-46 |
| 28 | test_create_page_renders | TC-DDN-P50 | Create | 50-51 |
| 29 | test_create_menu_fields_toggle | TC-DDN-P51 | Create | 50-51 |
| 30 | test_store_success | TC-DDN-P60 | Store | 60-65 |
| 31 | test_store_with_tenant_creation_allowed | TC-DDN-P61 | Store | 60-65 |
| 32 | test_store_menu_fields_nulled | TC-DDN-P62 | Store | 60-65 |
| 33 | test_store_defaults | TC-DDN-P63 | Store | 60-65 |
| 34 | test_store_logs_activity | TC-DDN-P64 | Store | 60-65 |
| 35 | test_store_redirect | TC-DDN-P65 | Store | 60-65 |
| 36 | test_validation_db_type_required | TC-DDN-N70 | Val | 70-81 |
| 37 | test_validation_db_type_invalid | TC-DDN-N71 | Val | 70-81 |
| 38 | test_validation_table_name_required | TC-DDN-N72 | Val | 70-81 |
| 39 | test_validation_column_name_required | TC-DDN-N73 | Val | 70-81 |
| 40 | test_validation_menu_category_required | TC-DDN-N74 | Val | 70-81 |
| 41 | test_validation_main_menu_required | TC-DDN-N75 | Val | 70-81 |
| 42 | test_validation_sub_menu_required | TC-DDN-N76 | Val | 70-81 |
| 43 | test_validation_tab_name_required | TC-DDN-N77 | Val | 70-81 |
| 44 | test_validation_field_name_required | TC-DDN-N78 | Val | 70-81 |
| 45 | test_validation_duplicate_combo | TC-DDN-N79 | Val | 70-81 |
| 46 | test_validation_max_length | TC-DDN-N80, N81 | Val | 70-81 |
| 47 | test_show_page | TC-DDN-P90, P91 | Show | 90-93 |
| 48 | test_show_invalid_id | TC-DDN-N92, N93 | Show | 90-93 |
| 49 | test_edit_page | TC-DDN-P100 | Edit | 100-102 |
| 50 | test_edit_system_record_blocked | TC-DDN-N101 | Edit | 100-102 |
| 51 | test_edit_invalid_id | TC-DDN-N102 | Edit | 100-102 |
| 52 | test_update_success | TC-DDN-P110 | Update | 110-115 |
| 53 | test_update_is_active | TC-DDN-P111 | Update | 110-115 |
| 54 | test_update_menu_fields_cleared | TC-DDN-P112 | Update | 110-115 |
| 55 | test_update_system_record_blocked | TC-DDN-N114 | Update | 110-115 |
| 56 | test_update_invalid_db_type | TC-DDN-N115 | Update | 110-115 |
| 57 | test_destroy_soft_delete | TC-DDN-P120 | Destroy | 120-123 |
| 58 | test_destroy_system_record_blocked | TC-DDN-N122 | Destroy | 120-123 |
| 59 | test_trash_view | TC-DDN-P130-P132 | Trash | 130-132 |
| 60 | test_restore_success | TC-DDN-P140 | Restore | 140-142 |
| 61 | test_restore_non_trashed | TC-DDN-N142 | Restore | 140-142 |
| 62 | test_force_delete | TC-DDN-P150 | ForceDel | 150-152 |
| 63 | test_force_delete_non_trashed | TC-DDN-N152 | ForceDel | 150-152 |
| 64 | test_toggle_active_to_inactive | TC-DDN-P160 | Toggle | 160-163 |
| 65 | test_toggle_inactive_to_active | TC-DDN-P161 | Toggle | 160-163 |
| 66 | test_toggle_returns_json | TC-DDN-P162 | Toggle | 160-163 |
| 67 | test_ajax_menu_data | TC-DDN-P170 | AJAX | 170-174 |
| 68 | test_ajax_main_menus | TC-DDN-P171 | AJAX | 170-174 |
| 69 | test_ajax_sub_menus | TC-DDN-P172 | AJAX | 170-174 |
| 70 | test_ajax_menu_not_found | TC-DDN-N173, N174 | AJAX | 170-174 |
| 71 | test_ajax_filter_options | TC-DDN-P180, P181 | AJAX | 180-183 |
| 72 | test_ajax_search | TC-DDN-P182, N183 | AJAX | 180-183 |
| 73 | test_ajax_tenant_tables | TC-DDN-P190, N191 | AJAX | 190-191 |
| 74 | test_save_option_success | TC-DDN-P200-P202 | Create+Map | 200-206 |
| 75 | test_save_option_validation | TC-DDN-N203-N205 | Create+Map | 200-206 |
| 76 | test_bulk_update | TC-DDN-P210, P211 | Bulk | 210-213 |
| 77 | test_bulk_update_validation | TC-DDN-N212, N213 | Bulk | 210-213 |
| 78 | test_bulk_delete | TC-DDN-P220, P221 | Bulk | 220-222 |
| 79 | test_map_to_need | TC-DDN-P230-P232 | Mapping | 230-237 |
| 80 | test_remove_mapping | TC-DDN-P233, P234 | Mapping | 230-237 |
| 81 | test_mapping_validation | TC-DDN-N235-N237 | Mapping | 230-237 |
| 82 | test_activity_log_mutations | TC-DDN-P240-P248 | Audit | 240-248 |
| 83 | test_xss_escaping | TC-DDN-N270 | Security | 270-275 |
| 84 | test_sql_injection_safe | TC-DDN-N271 | Security | 270-275 |
| 85 | test_system_record_can_be_toggled | TC-DDN-N275 | Edge | 270-275 |

**Total: 85 methods (82 Automated, 3 Planned).**

---

## 4. Notes

- **BR-SYS-014 Gap:** The unique combo (db_type, table_name, column_name) is enforced only at DB level. A duplicate attempt throws a raw 500 error instead of a graceful validation error. TC-DDN-N79 documents this gap. The controller should pre-check existence before insert.
- **AJAX Auth Gap:** `getMenuData`, `getMainMenus`, `getSubMenus`, `getTenantTables`, `getFilterOptions`, `search` have no explicit Gate authorization. They rely on route middleware (auth + verified) but lack fine-grained permission checks.
- **toggleStatus Gap:** System records (`is_system=true`) CAN be toggled — no guard exists unlike edit/update/destroy. TC-DDN-N275 documents this.
- **Test Status:** All TCs currently marked `⬜` (not yet implemented).
