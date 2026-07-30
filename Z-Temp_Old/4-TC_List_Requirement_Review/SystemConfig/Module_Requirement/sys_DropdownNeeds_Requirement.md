# SYS — Dropdown Needs Registry — Requirement Specification

**Module:** SystemConfig (SYS) · **Feature:** Dropdown Needs Registry
**Code:** SYS · **Prefix:** `sys_` · **Type:** Central (prime_db)
**Module Path:** `Modules/SystemConfig/`
**Controller:** `TenantDropdownNeedController` (988 lines)
**Models:** `DropdownNeed` (`sys_dropdown_needs`) · `DropdownNeedDropdown` (`sys_dropdown_need_dropdowns_jnt`)
**FRD Refs:** REQ-SYS-004 · BR-SYS-014 · BR-SYS-015 · BR-SYS-012

---

## Table of Contents

1. [Module / Feature Overview](#1-module--feature-overview)
2. [Scope and Boundaries](#2-scope-and-boundaries)
3. [Actors and User Roles](#3-actors-and-user-roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [Controller and Route Inventory](#6-controller-and-route-inventory)
7. [Form Request / Validation Rules](#7-form-request--validation-rules)
8. [Business Rules](#8-business-rules)
9. [Permission and Authorization Model](#9-permission-and-authorization-model)
10. [Error Handling and Edge Cases](#10-error-handling-and-edge-cases)
11. [Non-Functional Requirements](#11-non-functional-requirements)
12. [Dependencies and Integration Points](#12-dependencies-and-integration-points)
13. [Known Issues and Technical Debt](#13-known-issues-and-technical-debt)
14. [User Stories and Acceptance Criteria](#14-user-stories-and-acceptance-criteria)
15. [Traceability Matrix](#15-traceability-matrix)
16. [V1/V2 Status and Priority](#16-v1v2-status-and-priority)

---

## 1. Module / Feature Overview

### 1.1 Purpose

The Dropdown Needs Registry is the **authoritative definition hub** for the entire dynamic dropdown system in Prime-AI. Each "need" record defines a database table and column that requires a configurable dropdown selection, along with the menu context where it appears. This registry determines which fields across all modules can have dynamic dropdown values — no dropdown value can be created without a corresponding Need record.

This is a **foundational prerequisite** for all dropdown values across every module. Without a properly configured Need, the system cannot determine which fields require dropdown options, what type of database they belong to, or where they appear in the menu hierarchy.

### 1.2 Feature Position in the Platform

```
Platform Layer          Feature                       Database             Notes
───────────────────────────────────────────────────────────────────────────────────
Central (Super-Admin)   Dropdown Needs Registry       prime_db             sys_dropdown_needs
                                                    junction:             sys_dropdown_need_dropdowns_jnt
                                                    global_db (read):     glb_menus (menu hierarchy)
Tenant (All Schools)    All Modules (consumers)       Reads Needs          Dropdown values resolved via registry
```

### 1.3 Feature Characteristics

| Attribute             | Value                                                                          |
|-----------------------|--------------------------------------------------------------------------------|
| Controller            | `TenantDropdownNeedController` — 988 lines, one of the most complex in system |
| Models                | 2: `DropdownNeed` (sys_dropdown_needs), `DropdownNeedDropdown` (junction)     |
| DB Tables             | `sys_dropdown_needs`, `sys_dropdown_need_dropdowns_jnt`                       |
| Domain Scope          | Central only (tenant-scoped routes registered in `routes/tenant.php`)          |
| Route Group           | `system-config.` prefix in tenant.php                                          |
| Total Routes          | 22+ (CRUD + AJAX + bulk + mapping)                                             |
| Views                 | Multi-tab single-page: dropdown-need, dropdown-list, dropdown, create-dropdown-jnt |
| View Engine           | Blade (Bootstrap 5 + AdminLTE 4)                                               |
| Completion Status     | PARTIAL (~75%) — controller + views exist post-V2; no feature tests            |

---

## 2. Scope and Boundaries

### 2.1 In Scope

- Full CRUD for Dropdown Need records (`sys_dropdown_needs`)
- Soft delete with restore and force-delete lifecycle
- Multi-tab index view (4 tabs: Needs List, Mapped Dropdowns, Dropdown List, Mapping)
- Cascading filter system (8 independent filters)
- AJAX menu data loading from `glb_menus` (global_master_mysql connection)
- AJAX tenant table listing (`SHOW TABLES`)
- AJAX cascading filter options
- AJAX search (table_name/column_name/field_name LIKE)
- Bulk update and bulk delete of associated dropdown values
- Dropdown-value-to-Need mapping (map/unmap with junction table)
- Combined create-dropdown-and-map in a single transaction
- Status toggle with junction cascade
- System record protection (is_system=true → immutable)
- Activity logging for all mutations

### 2.2 Out of Scope

- Dropdown value CRUD (see **sys_DropdownValues_Requirement.md**)
- Platform settings management (REQ-SYS-001)
- Navigation menu management (REQ-SYS-002)
- Menu translation (REQ-SYS-003)
- Activity log viewer (REQ-SYS-006)
- School-admin path for dropdown creation (BR-SYS-019 — frontend concern)
- Migration-based table/column discovery (not in this controller — that's the prime-domain DropdownNeedController)

---

## 3. Actors and User Roles

| Role              | Permission Scope                                | Access Level                                                      |
|-------------------|-------------------------------------------------|-------------------------------------------------------------------|
| Super Admin       | `tenant.dropdown.*` (all 7 permissions)         | Full CRUD + restore + forceDelete + toggle + mapping + bulk ops   |
| Platform Manager  | `tenant.dropdown.*` (all 7 permissions)         | Full CRUD + restore + forceDelete + toggle + mapping + bulk ops   |
| Platform Support  | `tenant.dropdown.viewAny`, `tenant.dropdown.view` | Read-only (view needs and dropdowns, no mutations)              |
| School Admin      | `tenant.dropdown.viewAny` (read only)           | Read-only (Needs are system-level registry)                       |

---

## 4. Functional Requirements

### FR-01: Multi-Tab Index View
The system MUST render a 4-tab single-page index at `GET /system-config/dropdown`:
- **Tab 1 — Dropdown Needs** (`dropdown-need`): Paginated list of needs with cascading filters
- **Tab 2 — Mapped Dropdowns** (`dropdown`): Dropdown values mapped to the selected Need
- **Tab 3 — Dropdown List** (`dropdown-list`): All dropdown values grouped by key (accordion)
- **Tab 4 — Dropdown-for-Mapping** (`create-dropdown-jnt`): Unmapped dropdowns for mapping to selected Need

The active tab is driven by the `tab` or `active_tab` query parameter; default is `dropdown-need`.

### FR-02: Cascading Filter System
The system MUST provide 8 filters on the Dropdown Needs tab:
- `db_type`, `table_name`, `column_name` — direct DB field filters
- `menu_category`, `main_menu`, `sub_menu`, `tab_name`, `field_name` — menu hierarchy filters

Filters MUST cascade: selecting a `menu_category` narrows the `main_menu` dropdown, which narrows `sub_menu`, which narrows `tab_name`, which narrows `field_name`.

### FR-03: Create Dropdown Need
`GET /system-config/dropdown-need/create` — Renders creation form.
`POST /system-config/dropdown-need` — Validates and stores a new need.

Validation fields: `db_type` (in:Prime/Tenant/Global), `table_name` (string, max:150), `column_name` (string, max:150), `tenant_creation_allowed` (boolean), `menu_category` (nullable, max:150), `main_menu` (nullable, max:150), `sub_menu` (nullable, max:150), `tab_name` (nullable, max:100), `field_name` (nullable, max:100), `is_system` (boolean), `compulsory` (boolean), `dropdown_table_record_exist` (nullable boolean), `is_active` (nullable boolean, defaults true).

Conditional rule: When `tenant_creation_allowed=true`, menu fields become required. When `false`, they are forced to null.

### FR-04: Show Dropdown Need
`GET /system-config/dropdown-need/{id}` — Displays a single need's details.

### FR-05: Edit Dropdown Need
`GET /system-config/dropdown-need/{id}/edit` — Renders edit form (blocked if `is_system=true`).
`PUT /system-config/dropdown-need/{id}` — Updates the need (blocked if `is_system=true`).

### FR-06: Soft-Delete (Destroy)
`DELETE /system-config/dropdown-need/{id}` — Soft-deletes the need:
1. Sets `is_active=false` on all junction entries (`sys_dropdown_need_dropdowns_jnt`)
2. Sets `is_active=false` on the need record
3. Calls `$need->delete()` (SoftDeletes)
4. Logs "Trashed" activity

Blocked if `is_system=true` — redirects with error "System records cannot be deleted."

### FR-07: Trash View
`GET /system-config/dropdown-need/trash/view` — Lists soft-deleted needs (paginated, 10/page).

### FR-08: Restore
`GET /system-config/dropdown-need/{id}/restore` — Restores a trashed need:
1. Calls `$need->restore()`
2. Sets `is_active=true` on the need
3. Sets `is_active=true` on all junction entries
4. Logs "Restored" activity

### FR-09: Force Delete
`DELETE /system-config/dropdown-need/{id}/force-delete` — Permanently deletes:
1. Force-deletes all junction entries (`sys_dropdown_need_dropdowns_jnt`)
2. Force-deletes the need record
3. Logs "Deleted" activity

### FR-10: Toggle Status
`POST /system-config/dropdown-need/{id}/toggle-status` — Flips `is_active`:
1. Accepts `{is_active: boolean}` in request
2. Updates need's `is_active`
3. Cascades to all junction entries (`is_active` updated)
4. Returns JSON `{success, is_active, message}`

### FR-11: Save Dropdown Option (Transactional)
`POST /system-config/dropdowns/save-option` — Creates a dropdown value AND maps it to a need in a single transaction:
1. Validates: `dropdown_need_id` (exists), `key` (string, max:160), `value` (string, max:255), `additional_info` (nullable string), `type` (nullable, in:String/Integer/Decimal/Date/Boolean)
2. Calculates ordinal as MAX+1 within key group
3. Creates Dropdown record
4. Inserts/updates junction record linking dropdown to need
5. Returns JSON `{status, message}`

### FR-12: Bulk Update Dropdown Values
`POST /system-config/dropdowns/update-bulk` — Updates multiple dropdown values:
- Accepts `{rows: [{id, ordinal, value, type, additional_info}]}`
- Updates each in a transaction
- Returns JSON `{success, message}`

### FR-13: Bulk Delete Dropdown Values
`POST /system-config/dropdowns/delete-bulk` — Soft-deletes multiple dropdown values:
1. Deactivates junction entries (`is_active=false`)
2. Soft-deletes each dropdown
3. Returns JSON `{status, message}`

### FR-14: Map Dropdowns to Need
`POST /system-config/dropdowns/map-to-need` — Maps one or more dropdown values to a Need:
- Validates: `dropdown_needs_id`, `dropdown_ids` (array of existing IDs)
- For each ID: if junction exists but inactive — reactivates; if no junction — inserts new
- Returns JSON `{success, message}` with count

### FR-15: Remove Mapping
`POST /system-config/dropdowns/remove-mapping` — Unmaps dropdowns from a Need:
- Sets `is_active=false` on matching junction entries
- Returns JSON `{success, message}` with count

### FR-16: AJAX Menu Data
`GET /system-config/dropdown-need-api/menu-data` — Returns menus from `glb_menus` (global_master_mysql):
- Categorizes by `is_category=1` (categories), parent_id in category IDs (main menus), remaining (sub menus)
- Returns JSON `{categories, main_menus, sub_menus}`
- db_type param determines `menu_for` filter ('tenant' or 'prime')

### FR-17: AJAX Main/Sub Menu Drill-Down
`GET /system-config/dropdown-need-api/main-menus/{category}` — Returns main menus for a category title.
`GET /system-config/dropdown-need-api/sub-menus/{main}` — Returns sub menus for a main menu title.

### FR-18: AJAX Filter Options
`GET /system-config/dropdown-need-api/filter-options` — Accepts filter params, returns distinct values for all filterable fields: `mainMenus`, `subMenus`, `tabs`, `fields`, `tables`, `columns`, `dbTypes`.

### FR-19: AJAX Search
`GET /system-config/dropdown-need-api/search?search=keyword` — Returns top 10 needs matching by `table_name`, `column_name`, or `field_name` LIKE.

### FR-20: AJAX Tenant Tables
`GET /system-config/dropdown-need-api/tables` — Returns list of tables in the tenant database via `SHOW TABLES`.

### FR-21: Activity Logging
Every mutation MUST produce an activity log entry via `activityLog()` helper with: entity type, entity ID, user, event, IP. Events: Created, Updated, Trashed, Restored, Deleted, Toggled.

---

## 5. Data Model

### 5.1 Table: `sys_dropdown_needs`

| Column                       | Type              | Required | Default | Description                                       |
|------------------------------|-------------------|----------|---------|---------------------------------------------------|
| `id`                         | INT UNSIGNED (PK) | Auto     | —       | Primary key                                       |
| `db_type`                    | VARCHAR(20)       | Yes      | —       | 'Prime', 'Tenant', or 'Global'                    |
| `table_name`                 | VARCHAR(150)      | Yes      | —       | Database table name                               |
| `column_name`                | VARCHAR(150)      | Yes      | —       | Column requiring dropdown                         |
| `menu_category`              | VARCHAR(150)      | No       | NULL    | Menu category breadcrumb                          |
| `main_menu`                  | VARCHAR(150)      | No       | NULL    | Main menu breadcrumb                              |
| `sub_menu`                   | VARCHAR(150)      | No       | NULL    | Sub-menu breadcrumb                               |
| `tab_name`                   | VARCHAR(100)      | No       | NULL    | Tab name breadcrumb                               |
| `field_name`                 | VARCHAR(100)      | No       | NULL    | Field label                                       |
| `is_system`                  | TINYINT(1)        | Yes      | 1       | System-protected flag                             |
| `tenant_creation_allowed`    | TINYINT(1)        | Yes      | 0       | Tenants can add values for this need              |
| `compulsory`                 | TINYINT(1)        | Yes      | 1       | Mandatory for application functioning             |
| `dropdown_tabel_record_exist`| TINYINT(1)        | Auto     | 0       | Has dropdown values (note: typo "tabel")          |
| `is_active`                  | TINYINT(1)        | Yes      | 1       | Soft status flag                                  |
| `created_at`                 | TIMESTAMP         | Auto     | —       | Laravel timestamp                                 |
| `updated_at`                 | TIMESTAMP         | Auto     | —       | Laravel timestamp                                 |
| `deleted_at`                 | TIMESTAMP         | No       | NULL    | SoftDeletes timestamp                             |

**Unique Constraints:**
- `uq_DDNeeds_dbType_tableName_columnName` — (`db_type`, `table_name`, `column_name`) — BR-SYS-014
- `uq_DDNeeds_category_mainMenu_subMenu_tabName_fieldName` — (`menu_category`, `main_menu`, `sub_menu`, `tab_name`, `field_name`)

### 5.2 Table: `sys_dropdown_need_dropdowns_jnt`

| Column               | Type              | Required | Description                          |
|----------------------|-------------------|----------|--------------------------------------|
| `id`                 | INT UNSIGNED (PK) | Auto     | Primary key                          |
| `dropdown_needs_id`  | INT UNSIGNED      | Yes      | FK → `sys_dropdown_needs.id`         |
| `dropdown_table_id`  | INT UNSIGNED      | Yes      | FK → `sys_dropdown_table.id`         |
| `is_active`          | TINYINT(1)        | Yes      | Status flag (default 1)              |
| `created_at`         | TIMESTAMP         | Auto     | Laravel timestamp                    |
| `updated_at`         | TIMESTAMP         | Auto     | Laravel timestamp                    |

**Foreign Keys:**
- `fk_dropdownNeedTableJnt_dropdownNeedsId` → `sys_dropdown_needs.id`
- `fk_dropdownNeedTableJnt_dropdownTableId` → `sys_dropdown_table.id`

### 5.3 Model: `DropdownNeed`

| Property     | Value                                       |
|--------------|---------------------------------------------|
| Table        | `sys_dropdown_needs`                        |
| Traits       | `SoftDeletes`, `BaseModel`                  |
| Fillable     | All 14 data columns                         |
| Casts        | `is_system`(bool), `tenant_creation_allowed`(bool), `compulsory`(bool), `dropdown_tabel_record_exist`(bool), `is_active`(bool), `deleted_at`(datetime) |
| Relationships| `dropdowns()` — belongsToMany via junction with pivot `is_active` |
| Scopes       | `filterByDbType`, `filterByTableName`, `filterByColumnName`, `filterByMenuCategory`, `filterByMainMenu`, `filterBySubMenu`, `filterByTabName`, `filterByFieldName` |

### 5.4 Model: `DropdownNeedDropdown` (Junction)

| Property     | Value                                              |
|--------------|----------------------------------------------------|
| Table        | `sys_dropdown_need_dropdowns_jnt`                  |
| Traits       | `BaseModel`                                        |
| Fillable     | `dropdown_needs_id`, `dropdown_table_id`, `is_active` |
| Casts        | `is_active`(bool)                                  |
| Relationships| `dropdownNeed()` — BelongsTo, `dropdown()` — BelongsTo |

---

## 6. Controller and Route Inventory

### 6.1 Controller: `TenantDropdownNeedController`

| Method            | Route                                               | HTTP   | Auth Gate                     | Purpose                     |
|-------------------|-----------------------------------------------------|--------|-------------------------------|-----------------------------|
| `index`           | `system-config.dropdown.index`                      | GET    | `tenant.dropdown.viewAny`     | Multi-tab index view        |
| `index` (tab)     | `system-config.dropdown-need.index`                 | GET    | `tenant.dropdown.viewAny`     | Needs list tab              |
| `create`          | `system-config.dropdown-need.create`                | GET    | `tenant.dropdown.create`      | Create form                 |
| `store`           | `system-config.dropdown-need.store`                 | POST   | `tenant.dropdown.create`      | Store need                  |
| `show`            | `system-config.dropdown-need.show`                  | GET    | `tenant.dropdown.view`        | Show need                   |
| `edit`            | `system-config.dropdown-need.edit`                  | GET    | `tenant.dropdown.update`      | Edit form                   |
| `update`          | `system-config.dropdown-need.update`                | PUT    | `tenant.dropdown.update`      | Update need                 |
| `destroy`         | `system-config.dropdown-need.destroy`               | DELETE | `tenant.dropdown.delete`      | Soft-delete need            |
| `trashed`         | `system-config.dropdown-need.trashed`               | GET    | `tenant.dropdown.restore`     | Trash view                  |
| `restore`         | `system-config.dropdown-need.restore`               | GET    | `tenant.dropdown.restore`     | Restore need                |
| `forceDelete`     | `system-config.dropdown-need.forceDelete`           | DELETE | `tenant.dropdown.forceDelete` | Permanent delete            |
| `toggleStatus`    | `system-config.dropdown-need.toggleStatus`          | POST   | `tenant.dropdown.update`      | Toggle is_active            |
| `filterOptions`   | `system-config.dropdown-need.filterOptions`         | GET    | `tenant.dropdown.viewAny`     | AJAX filter options         |
| `getMenuData`     | `system-config.dropdown-need.menu-data`             | GET    | (none)                        | AJAX menu hierarchy         |
| `getMainMenus`    | `system-config.dropdown-need.main-menus`            | GET    | (none)                        | AJAX main menus drill-down  |
| `getSubMenus`     | `system-config.dropdown-need.sub-menus`             | GET    | (none)                        | AJAX sub menus drill-down   |
| `getTenantTables` | `system-config.dropdown-need.tables`                | GET    | (none)                        | AJAX tenant SHOW TABLES     |
| `getFilterOptions`| `system-config.dropdown-need.filter-options`        | GET    | (none)                        | AJAX filter options (API)   |
| `search`          | `system-config.dropdown-need.search`                | GET    | (none)                        | AJAX search                 |
| `saveDropdownOption`| `system-config.dropdowns.saveOption`              | POST   | `tenant.dropdown.create`      | Transactional create+map    |
| `updateBulk`      | `system-config.dropdowns.update.bulk`               | POST   | `tenant.dropdown.update`      | Bulk update values          |
| `deleteBulk`      | `system-config.dropdowns.delete.bulk`               | POST   | `tenant.dropdown.delete`      | Bulk soft-delete values     |
| `mapDropdownsToNeed`| `system-config.dropdowns.mapToNeed`               | POST   | `tenant.dropdown.update`      | Map values to need          |
| `removeMapping`   | `system-config.dropdowns.removeMapping`             | POST   | `tenant.dropdown.update`      | Unmap values from need      |

### 6.2 Route Registration

All routes registered in `routes/tenant.php` under the `system-config.` prefix group with `auth` + `verified` middleware.

Note: Some AJAX endpoints (`getMenuData`, `getMainMenus`, `getSubMenus`, `getTenantTables`, `getFilterOptions`, `search`) have NO explicit `Gate::authorize()` call in the controller — they rely on route middleware for authentication but may not enforce specific permission gates.

---

## 7. Form Request / Validation Rules

### 7.1 Store Validation

| Field                     | Rules                                            | Note                                    |
|---------------------------|--------------------------------------------------|-----------------------------------------|
| `db_type`                 | `required`, `in:Prime,Tenant,Global`             | Enum restriction                        |
| `table_name`              | `required`, `string`, `max:150`                  | Free text                               |
| `column_name`             | `required`, `string`, `max:150`                  | Free text                               |
| `tenant_creation_allowed` | `required`, `boolean`                            | Affects menu field requirement          |
| `menu_category`           | `nullable`, `string`, `max:150`                  | Required if tenant_creation_allowed=true |
| `main_menu`               | `nullable`, `string`, `max:150`                  | Required if tenant_creation_allowed=true |
| `sub_menu`                | `nullable`, `string`, `max:150`                  | Required if tenant_creation_allowed=true |
| `tab_name`                | `nullable`, `string`, `max:100`                  | Required if tenant_creation_allowed=true |
| `field_name`              | `nullable`, `string`, `max:100`                  | Required if tenant_creation_allowed=true |
| `is_system`               | `required`, `boolean`                            | System protection flag                  |
| `compulsory`              | `required`, `boolean`                            | Mandatory indicator                     |
| `dropdown_table_record_exist` | `nullable`, `boolean`                        | Auto-managed                            |
| `is_active`               | `nullable`, `boolean`                            | Defaults to true                        |

**Conditional Logic:** When `tenant_creation_allowed=false`, all 5 menu fields (`menu_category`, `main_menu`, `sub_menu`, `tab_name`, `field_name`) are forcibly set to `null` before save, regardless of submitted values.

**Missing Constraint:** BR-SYS-014 (unique combo of db_type+table_name+column_name) is enforced at the DB level via a UNIQUE KEY but is NOT validated explicitly in the controller — relies on DB unique violation.

### 7.2 Update Validation

Same rules as Store except:
- `is_active` uses `$request->boolean('is_active')` instead of nullable default
- `dropdown_table_record_exist` is not required in update

---

## 8. Business Rules

| BR-ID       | Rule                                                                 | Type       | Enforcement Point                  |
|-------------|----------------------------------------------------------------------|------------|------------------------------------|
| BR-SYS-012  | Every mutation produces an audit log entry with entity type, ID, user, event, IP | Workflow   | `activityLog()` at every write method |
| BR-SYS-014  | (db_type, table_name, column_name) combination MUST be unique        | Validation | DB UNIQUE constraint `uq_DDNeeds_dbType_tableName_columnName` |
| BR-SYS-015  | System-protected Needs (`is_system=true`) CANNOT be edited or deleted | Permission | Controller edit/update/destroy — check `is_system` flag before action |
| BR-SYS-019  | School admin cannot create Needs; only values where `tenant_creation_allowed=true` | Permission | Frontend-gated (filtered UI) |
| DDL-SYS-21  | `is_system` column DDL comment is misleading — `is_system=1` means platform-owned, NOT tenant-creatable | Schema | Documentation note |
| DDL-SYS-20  | `sys_dropdown_needs` may lack `deleted_at` in some DDL versions      | Schema     | Confirmed present in current model |

---

## 9. Permission and Authorization Model

### 9.1 Permission Gates

| Gate                           | Method(s)                                     |
|--------------------------------|-----------------------------------------------|
| `tenant.dropdown.viewAny`      | `index`, `filterOptions`                      |
| `tenant.dropdown.create`       | `create`, `store`, `saveDropdownOption`       |
| `tenant.dropdown.view`         | `show`                                        |
| `tenant.dropdown.update`       | `edit`, `update`, `toggleStatus`, `updateBulk`, `mapDropdownsToNeed`, `removeMapping` |
| `tenant.dropdown.delete`       | `destroy`, `deleteBulk`                       |
| `tenant.dropdown.restore`      | `trashed`, `restore`                          |
| `tenant.dropdown.forceDelete`  | `forceDelete`                                 |

### 9.2 Permission Gap

The following AJAX endpoints have **NO explicit Gate::authorize()** call:
- `getMenuData`, `getMainMenus`, `getSubMenus` — public within auth session
- `getTenantTables`, `getFilterOptions`, `search` — data-disclosure risk if unauthenticated access is possible

These are behind `auth` + `verified` middleware via route registration, but no fine-grained permission check exists.

---

## 10. Error Handling and Edge Cases

### 10.1 Error Responses

| Scenario                                       | Response                                    | HTTP Status |
|------------------------------------------------|---------------------------------------------|-------------|
| `db_type` invalid                              | Validation error "The selected db type is invalid." | 422   |
| `table_name` empty                             | Validation error "The table name field is required." | 422 |
| `column_name` exceeds 150 chars                | Validation error "The column name must not be greater than 150 characters." | 422 |
| `tenant_creation_allowed=true` + menu fields missing | Validation errors for each missing field   | 422        |
| Edit/update on `is_system=true` need           | Redirect with "System records cannot be edited." | 302 + error flash |
| Destroy on `is_system=true` need               | Redirect with "System records cannot be deleted." | 302 + error flash |
| Non-existing ID on show/edit/update/destroy    | 404 Not Found (`findOrFail`)                | 404         |
| Restore/forceDelete on non-trashed ID          | 404 Not Found (`withTrashed()->findOrFail()`) | 404        |
| Unauthorized access (missing permission)       | 403 "This action is unauthorized."          | 403         |
| DB unique constraint violation (duplicate combo)| 500 Server Error (not gracefully handled)   | 500         |
| AJAX endpoint exception (menu data, etc.)      | Returns empty JSON arrays gracefully         | 200         |
| `saveDropdownOption` transaction failure        | JSON `{status: false, message: "Error saving dropdown: ..."}` | 500 |
| `mapDropdownsToNeed` / `removeMapping` exception | JSON `{success: false, message: "..."}`     | 500         |

### 10.2 Edge Cases

| Edge Case                                      | Expected Behaviour                                                       |
|------------------------------------------------|--------------------------------------------------------------------------|
| No `selectedDropdownNeed` in index             | Mapped and unmapped dropdowns return empty paginators                    |
| Empty `filterOptions` response                 | Returns empty arrays for all fields (graceful)                           |
| `getMenuData` with invalid `db_type`           | Defaults to 'prime' `menu_for` filter if not 'Tenant'                    |
| `getMainMenus` / `getSubMenus` category not found | Returns empty JSON array                                              |
| Bulk delete with empty IDs array               | Transaction succeeds but no rows affected                                |
| `saveDropdownOption` with already-mapped value | `updateOrInsert` reactivates existing junction                           |
| `mapDropdownsToNeed` with already-active mapping | Skips without error — counts only newly mapped                          |
| `toggleStatus` on non-existent need            | `findOrFail` returns 404                                                 |
| System record can still be toggled             | `toggleStatus` has NO `is_system` check — system records CAN be toggled  |

---

## 11. Non-Functional Requirements

| NFR-ID       | Category      | Requirement                                                 | Threshold            |
|--------------|---------------|-------------------------------------------------------------|----------------------|
| NFR-SYS-005  | Performance   | Dropdown Needs list response time (paginated, 10/page)      | < 300 ms at P95      |
| NFR-SYS-016  | Usability     | Cascading selectors use progressive AJAX loading             | Each selector narrows next |
| NFR-SYS-008  | Security      | Zero unauthorised access to any SYS route                   | 403 for missing permission |
| NFR-SYS-011  | Security      | All controller mutations use validated data only            | No `$request->all()` on models |
| NFR-SYS-012  | Security      | CSRF protection on all write routes                         | POST/PUT/DELETE on `web` middleware |
| NFR-SYS-018  | Compliance    | Activity log entries are immutable (no edit/delete UI)      | Append-only audit trail |

---

## 12. Dependencies and Integration Points

| Dependency         | Type       | Details                                                        |
|--------------------|------------|----------------------------------------------------------------|
| `sys_dropdown_needs` | Table    | Primary data table                                             |
| `sys_dropdown_need_dropdowns_jnt` | Junction | Many-to-many link to `sys_dropdown_table`             |
| `sys_dropdown_table` | Table     | Dropdown values (downstream consumer)                          |
| `glb_menus`          | Table     | Menu hierarchy from `global_master_mysql` connection           |
| `Auth / Spatie RBAC` | Module   | All permission checks resolve through Spatie roles/permissions |
| `Dropdown` model     | Model     | `Modules\SystemConfig\Models\Dropdown` for value operations    |
| `activityLog()`      | Helper    | Shared helper for audit trail logging                          |
| `DropdownNeedsSeeder`| Seeder    | Seeds initial system Dropdown Need records                     |

---

## 13. Known Issues and Technical Debt

| Issue ID   | Description                                                              | Severity | Status   |
|------------|--------------------------------------------------------------------------|----------|----------|
| SYS-TD-01  | BR-SYS-014 unique combo NOT validated in controller — relies solely on DB UNIQUE constraint which throws raw 500 on violation | High | Unresolved |
| SYS-TD-02  | AJAX endpoints (`getMenuData`, `getMainMenus`, etc.) lack explicit Gate authorization | Medium | Unresolved |
| SYS-TD-03  | `toggleStatus` has no `is_system` check — system records can be deactivated | Medium | Unresolved |
| SYS-TD-04  | Column name `dropdown_tabel_record_exist` has a typo ("tabel" instead of "table") | Low | Cosmetic |
| SYS-TD-05  | No feature tests exist — 0 HTTP/feature test coverage                    | High | Unresolved |
| SYS-TD-06  | Some AJAX endpoints return raw Exception messages in error responses (security concern) | Medium | Unresolved |
| SYS-TD-07  | Controller naming "Tenant" prefix is misleading — serves central admin, not tenant users | Low | Cosmetic |

---

## 14. User Stories and Acceptance Criteria

### US-SYS-004: Dropdown Needs Registry (P0)

**As a Super Admin,** I want to register Dropdown Needs so that platform administrators and, where permitted, school administrators can add configurable pick-list values to any form field.

**Acceptance Criteria:**

```
Scenario: Create a Dropdown Need
  Given I am authenticated as Super Admin
  When I create a need with db_type=Tenant, table=std_students, column=blood_group_id
  Then the need is saved with a unique (db_type, table, column) entry in the registry

Scenario: Duplicate need rejected
  Given a need for (Tenant, std_students, blood_group_id) already exists
  When I try to create another need for the same table and column
  Then I receive a validation error: "A dropdown requirement for this table and column already exists."

Scenario: System-protected need cannot be edited
  Given a need with is_system=true
  When I attempt to edit it
  Then I receive: "This dropdown requirement is system-protected and cannot be changed."

Scenario: Platform Manager cannot create Needs
  Given I am authenticated as Platform Manager
  When I attempt to access the Need creation form
  Then I receive a 403 response

Scenario: Soft-delete with junction cascade
  Given a need has 5 mapped dropdown values
  When I delete the need
  Then all 5 junction entries have is_active=false
  And the need is soft-deleted with deleted_at set
  And an audit log "Trashed" is created

Scenario: Restore reactivates junction entries
  Given a need was soft-deleted with mapped values
  When I restore the need
  Then the need's is_active=true
  And all junction entries are reactivated (is_active=true)
  And an audit log "Restored" is created

Scenario: Tenant Creation Allowed requires menu breadcrumb
  When I set tenant_creation_allowed=true
  Then I must fill all 5 menu fields: category, main menu, sub menu, tab name, field name
  If any is missing, validation rejects with a field-specific error
```

---

## 15. Traceability Matrix

| FR-ID   | REQ/BR Ref      | Controller Method(s)            | Test Coverage |
|---------|-----------------|----------------------------------|---------------|
| FR-01   | REQ-SYS-004     | `index`                          | ⬜            |
| FR-02   | REQ-SYS-004     | `index`                          | ⬜            |
| FR-03   | REQ-SYS-004     | `create`, `store`                | ⬜            |
| FR-04   | REQ-SYS-004     | `show`                           | ⬜            |
| FR-05   | REQ-SYS-004, BR-SYS-015 | `edit`, `update`        | ⬜            |
| FR-06   | REQ-SYS-004     | `destroy`                        | ⬜            |
| FR-07   | REQ-SYS-004     | `trashed`                        | ⬜            |
| FR-08   | REQ-SYS-004     | `restore`                        | ⬜            |
| FR-09   | REQ-SYS-004     | `forceDelete`                    | ⬜            |
| FR-10   | REQ-SYS-004     | `toggleStatus`                   | ⬜            |
| FR-11   | REQ-SYS-004     | `saveDropdownOption`             | ⬜            |
| FR-12   | REQ-SYS-004     | `updateBulk`                     | ⬜            |
| FR-13   | REQ-SYS-004     | `deleteBulk`                     | ⬜            |
| FR-14   | REQ-SYS-004     | `mapDropdownsToNeed`             | ⬜            |
| FR-15   | REQ-SYS-004     | `removeMapping`                  | ⬜            |
| FR-16   | REQ-SYS-004     | `getMenuData`                    | ⬜            |
| FR-17   | REQ-SYS-004     | `getMainMenus`, `getSubMenus`    | ⬜            |
| FR-18   | REQ-SYS-004     | `filterOptions` / `getFilterOptions` | ⬜         |
| FR-19   | REQ-SYS-004     | `search`                         | ⬜            |
| FR-20   | REQ-SYS-004     | `getTenantTables`                | ⬜            |
| FR-21   | BR-SYS-012      | All write methods                | ⬜            |
|         | BR-SYS-014      | `store` (DB constraint)          | ⬜            |
|         | BR-SYS-015      | `edit`, `update`, `destroy`      | ⬜            |

---

## 16. V1/V2 Status and Priority

| Component               | V1   | V2   | Status    | Priority |
|-------------------------|------|------|-----------|----------|
| Controller & Views      | —    | ✅   | Complete  | P0       |
| Auth (Gate checks)      | —    | ✅   | Present   | P0       |
| DB Unique Constraint    | —    | ✅   | Present   | P0       |
| BR-SYS-014 (UI validation) | — | ❌ | Missing   | P0       |
| BR-SYS-015 (system protection) | — | ✅ | Present | P1    |
| BR-SYS-012 (activity log) | —  | ✅   | Present   | P0       |
| Feature Tests           | —    | ❌   | Missing   | P1       |
| AJAX Endpoint Auth      | —    | ❌   | Missing   | P1       |
| toggleStatus is_system check | — | ❌ | Missing | P2      |
| Error Handling (DB exception) | — | ❌ | Missing | P2   |

**Overall Completion:** ~75%

**Next Actions:**
1. Add explicit BR-SYS-014 unique-combo validation in controller before DB insert
2. Add Gate::authorize() to AJAX endpoints (`getMenuData`, `getMainMenus`, `getSubMenus`, `getTenantTables`, `getFilterOptions`, `search`)
3. Add `is_system` guard to `toggleStatus()`
4. Write feature tests covering all routes, permissions, and business rules
5. Add graceful DB unique violation handling
