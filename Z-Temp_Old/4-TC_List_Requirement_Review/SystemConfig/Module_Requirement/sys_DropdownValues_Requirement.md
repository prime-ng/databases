# SYS — Dropdown Value Management — Requirement Specification

**Module:** SystemConfig (SYS) · **Feature:** Dropdown Value Management
**Code:** SYS · **Prefix:** `sys_` · **Type:** Central (prime_db)
**Module Path:** `Modules/SystemConfig/`
**Controller:** `TenantDropdownController` (258 lines)
**FormRequest:** `TenantDropdownRequest`
**Model:** `Dropdown` (`sys_dropdown_table`)
**FRD Refs:** REQ-SYS-005 · BR-SYS-007 · BR-SYS-008 · BR-SYS-009 · BR-SYS-016 · BR-SYS-019 · BR-SYS-012

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

The Dropdown Value Management feature provides CRUD operations for individual dropdown option entries stored in `sys_dropdown_table`. These values represent the actual selectable options that appear in form fields across every module in the platform — everything from blood group choices to activity categories to fee structure types.

This feature is the **value repository** that populates every dynamic dropdown across all tenant applications. Each value belongs to a key group (typically `tablename.columnname`), and the key group must correspond to a registered Dropdown Need entry.

### 1.2 Feature Position in the Platform

```
Platform Layer          Feature                          Database         Notes
───────────────────────────────────────────────────────────────────────────────────
Central (Super-Admin)   Dropdown Value Management        prime_db          sys_dropdown_table
                                                  junction:               sys_dropdown_need_dropdowns_jnt
Tenant (All Schools)    All Modules (consumers)          Reads values      Every dropdown form field
Seeder                  DropdownsSeeder                  Seeds values      Idempotent, platform-critical
```

### 1.3 Feature Characteristics

| Attribute             | Value                                                                  |
|-----------------------|------------------------------------------------------------------------|
| Controller            | `TenantDropdownController` — 258 lines                                 |
| FormRequest           | `TenantDropdownRequest`                                                |
| Model                 | `Dropdown` (`sys_dropdown_table`)                                      |
| DB Table              | `sys_dropdown_table`                                                   |
| Domain Scope          | Central only (tenant-scoped routes in `routes/tenant.php`)             |
| Route Group           | `system-config.` prefix in tenant.php                                  |
| Total Routes          | 10 (CRUD + trash + toggle + getColumns)                                |
| View Engine           | Blade (Bootstrap 5 + AdminLTE 4)                                       |
| Completion Status     | PARTIAL (~75%) — controller + views exist post-V2; no feature tests    |

---

## 2. Scope and Boundaries

### 2.1 In Scope

- Full CRUD for Dropdown Value records (`sys_dropdown_table`)
- Grouped listing (key → values accordion format)
- Comma-separated value creation (store multiple values at once)
- Server-side key derivation via `Str::slug($key, '_')`
- Auto-assignment of ordinal (MAX+1 within key group)
- Soft delete with is_active cascade
- Restore (recovery from trash with is_active=true)
- Force delete (permanent removal with junction cleanup)
- Status toggle via AJAX
- AJAX getColumns (whitelisted: sys_dropdown_table, sys_settings, sys_users)
- Activity logging for all mutations

### 2.2 Out of Scope

- Dropdown Need CRUD (see **sys_DropdownNeeds_Requirement.md**)
- Dropdown-Need mapping UI (handled in TenantDropdownNeedController)
- Bulk update / bulk delete / saveDropdownOption (handled in TenantDropdownNeedController)
- Reference check on deletion BR-SYS-016 (not implemented in current code)
- School-admin path gating BR-SYS-019 (frontend concern)
- BR-SYS-007 enforcement (matching Need check — gap in current implementation)

---

## 3. Actors and User Roles

| Role              | Permission Scope                                     | Access Level                                                    |
|-------------------|------------------------------------------------------|-----------------------------------------------------------------|
| Super Admin       | `system-config.dropdown.*` (all 6 permissions)       | Full CRUD + restore + forceDelete + toggle                      |
| Platform Manager  | `system-config.dropdown.*` (all 6 permissions)       | Full CRUD + restore + forceDelete + toggle                      |
| Platform Support  | `system-config.dropdown.viewAny` + `system-config.dropdown.update` | View + edit + toggle (no create/delete/restore) |

---

## 4. Functional Requirements

### FR-01: Grouped Index View
`GET /system-config/dropdown` — Displays dropdown values grouped by `key` in an accordion format:
- Distinct keys are fetched from `sys_dropdown_table`, paginated at 10/page
- Each key expands to show all values ordered by `ordinal`
- Filters: `search` (key/value LIKE), `type` (exact), `status` (is_active)

### FR-02: Create Dropdown Values
`GET /system-config/dropdown/create` — Renders creation form with tenant table listing (SHOW TABLES).
`POST /system-config/dropdown` — Stores one or more comma-separated values:
1. Validates via `TenantDropdownRequest`: `key` (required, max:160), `value` (required, max:255), `type` (nullable, in whitelist), `additional_info` (nullable), `is_active` (boolean)
2. Key is derived server-side as `Str::slug($data['key'], '_')`
3. Values are split by comma, trimmed, de-duplicated
4. Ordinal starts at MAX+1 within key group, increments for each value
5. Creates individual Dropdown records with activity log per value

### FR-03: Edit Dropdown Value
`GET /system-config/dropdown/{id}/edit` — Renders edit form for a single value.
`PUT /system-config/dropdown/{id}` — Updates the dropdown value:
- Validates via `TenantDropdownRequest`
- Preserves `additional_info` if not provided in update
- Logs before/after changes in activity log

### FR-04: Show Dropdown Value
(No dedicated show route — uses edit view for display.)

### FR-05: Soft-Delete (Destroy)
`DELETE /system-config/dropdown/{id}` — Soft-deletes a dropdown value:
1. Sets `is_active=false` on the record
2. Calls `$dropdown->delete()` (SoftDeletes)
3. Logs "Trashed" activity
4. Redirects to index with success flash

### FR-06: Trash View
`GET /system-config/dropdown/trash` — Lists soft-deleted dropdown values, ordered by key, paginated at 15/page.

### FR-07: Restore
`GET /system-config/dropdown/{id}/restore` — Restores a trashed dropdown value:
1. Calls `$dropdown->restore()`
2. Sets `is_active=true`
3. Logs "Restored" activity
4. Redirects to trash view with success flash

### FR-08: Force Delete
`DELETE /system-config/dropdown/{id}/force-delete` — Permanently deletes:
1. Removes all junction entries (`sys_dropdown_need_dropdowns_jnt`) referencing this dropdown
2. Force-deletes the dropdown record
3. Logs "Deleted" activity
4. Redirects to trash view with success flash

### FR-09: Toggle Status
`POST /system-config/dropdown/{id}/toggle-status` — Toggles `is_active`:
- Flips the value (true→false or false→true)
- Returns JSON `{success, is_active, message}`

### FR-10: AJAX Get Columns
`GET /system-config/dropdown/columns?table_name=X` — Returns column listing for a whitelisted table:
- Allowed tables: `sys_dropdown_table`, `sys_settings`, `sys_users`
- Returns JSON array of column names from `Schema::getColumnListing()`
- Returns 422 error for invalid table

### FR-11: Activity Logging
Every mutation MUST produce an activity log entry via `activityLog()` helper: Stored, Updated, Trashed, Restored, Deleted, Toggled.

---

## 5. Data Model

### 5.1 Table: `sys_dropdown_table`

| Column           | Type                    | Required | Default  | Description                                               |
|------------------|-------------------------|----------|----------|-----------------------------------------------------------|
| `id`             | INT UNSIGNED (PK)       | Auto     | —        | Primary key                                               |
| `ordinal`        | TINYINT UNSIGNED        | Auto     | —        | Display order (MAX+1 auto-assigned)                       |
| `key`            | VARCHAR(160)            | Auto     | —        | Group key (derived server-side as `tablename.columnname`) |
| `value`          | VARCHAR(100)            | Yes      | —        | Display text                                              |
| `type`           | ENUM('String','Integer','Decimal','Date','Datetime','Time','Boolean') | Yes | 'String' | Data type                                      |
| `additional_info`| JSON                    | No       | NULL     | Extra information                                          |
| `is_active`      | TINYINT(1)              | Yes      | 1        | Soft status flag                                           |
| `created_at`     | TIMESTAMP               | Auto     | —        | Laravel timestamp                                          |
| `updated_at`     | TIMESTAMP               | Auto     | —        | Laravel timestamp                                          |
| `deleted_at`     | TIMESTAMP               | No       | NULL     | SoftDeletes timestamp (may be missing in some DDLs)        |

**Unique Constraints:**
- `uq_dropdownTable_key_ordinal` — (`key`, `ordinal`) — ordinal unique within key group
- `uq_dropdownTable_key_value` — (`key`, `value`) — value unique within key group

### 5.2 Model: `Dropdown`

| Property     | Value                                       |
|--------------|---------------------------------------------|
| Table        | `sys_dropdown_table`                        |
| Traits       | `SoftDeletes`, `BaseModel`                  |
| Fillable     | `ordinal`, `key`, `value`, `type`, `additional_info`, `is_active` |
| Casts        | `ordinal`(integer), `is_active`(boolean), `deleted_at`(datetime) |
| Defaults     | `type`='String', `is_active`=true           |
| Relationships| `dropdownNeeds()` — belongsToMany via junction with pivot `is_active` |
|              | `junction()` — hasOne `DropdownNeedDropdown` |

### 5.3 Junction Table: `sys_dropdown_need_dropdowns_jnt`

(See **sys_DropdownNeeds_Requirement.md** §5.2 for full schema.)

---

## 6. Controller and Route Inventory

### 6.1 Controller: `TenantDropdownController`

| Method       | Route                                    | HTTP   | Auth Gate                            | Purpose                  |
|--------------|------------------------------------------|--------|--------------------------------------|--------------------------|
| `index`      | `system-config.dropdown.index`           | GET    | `system-config.dropdown.viewAny`     | Grouped listing          |
| `create`     | `system-config.dropdown.create`          | GET    | `system-config.dropdown.create`      | Create form              |
| `store`      | `system-config.dropdown.store`           | POST   | `system-config.dropdown.create`      | Store values             |
| `edit`       | `system-config.dropdown.edit`            | GET    | `system-config.dropdown.update`      | Edit form                |
| `update`     | `system-config.dropdown.update`          | PUT    | `system-config.dropdown.update`      | Update value             |
| `destroy`    | `system-config.dropdown.destroy`         | DELETE | `system-config.dropdown.delete`      | Soft-delete              |
| `trashed`    | `system-config.dropdown.trashed`         | GET    | `system-config.dropdown.restore`     | Trash view               |
| `restore`    | `system-config.dropdown.restore`         | GET    | `system-config.dropdown.restore`     | Restore                  |
| `forceDelete`| `system-config.dropdown.forceDelete`     | DELETE | `system-config.dropdown.forceDelete` | Permanent delete         |
| `toggleStatus`| `system-config.dropdown.toggleStatus`   | POST   | `system-config.dropdown.update`      | Toggle is_active         |
| `getColumns` | `system-config.dropdown.columns`         | GET    | `system-config.dropdown.viewAny`     | AJAX table columns       |

### 6.2 Route Registration

All routes registered in `routes/tenant.php` under the `system-config.` prefix group with `auth` + `verified` middleware.

Note: There is a potential route conflict between `GET /system-config/dropdown` (master index handled by `TenantDropdownNeedController::index()`) and the implicit resource listing. The master 4-tab route is registered BEFORE the individual CRUD routes to take precedence.

---

## 7. Form Request / Validation Rules

### 7.1 `TenantDropdownRequest` — Store & Update

| Field             | Rules                                    | Note                             |
|-------------------|------------------------------------------|----------------------------------|
| `key`             | `required`, `string`, `max:160`          | User-provided, slugified server-side |
| `value`           | `required`, `string`, `max:255`          | Comma-separated list parsed in controller |
| `type`            | `nullable`, `in:String,Integer,Decimal,Date,Datetime,Time,Boolean` | Default 'String' |
| `additional_info` | `nullable`, `string`                     | Preserved on update if omitted   |
| `is_active`       | `boolean`                                | Prepared from 'on' checkbox      |

**Authorization:** FormRequest `authorize()` checks `system-config.dropdown.create` for POST, `system-config.dropdown.update` for PUT.

### 7.2 Controller-Level Validation (store)

- Values split by comma, `array_unique`, `array_filter`, `trim` applied
- Key slugified via `Str::slug($data['key'], '_')` (underscore separator)
- Ordinal calculated as `Dropdown::where('key', $slug)->max('ordinal') + 1` (0 if none)
- Each value becomes a separate record with incrementing ordinal

### 7.3 Controller-Level Validation (destroy)

- `$dropdown->is_active = false` set before `$dropdown->delete()`
- No reference check before deletion (BR-SYS-016 gap)

### 7.4 getColumns Validation

- `table_name` required via `$request->table_name`
- Only 3 tables allowed: `sys_dropdown_table`, `sys_settings`, `sys_users`
- Returns `{error: "Invalid table"}` with 422 for disallowed tables

---

## 8. Business Rules

| BR-ID       | Rule                                                                   | Type       | Enforcement Point                    |
|-------------|------------------------------------------------------------------------|------------|--------------------------------------|
| BR-SYS-007  | No Dropdown Value can be created without a matching Dropdown Need      | Validation | **NOT ENFORCED** — gap in controller |
| BR-SYS-008  | Group key derived server-side as `tablename.columnname`; never from request | Validation | **PARTIAL** — key slugified but accepted from request, NOT derived from Need |
| BR-SYS-009  | Ordinal auto-assigned as MAX+1 within key group; unique within group   | Calculation| Controller store — MAX+1 query; DB UNIQUE constraint |
| BR-SYS-012  | Every mutation produces an audit log entry                             | Workflow   | `activityLog()` at every write method |
| BR-SYS-016  | Dropdown Value deletion blocked if referenced by school data           | Validation | **NOT ENFORCED** — no reference check |
| BR-SYS-019  | School-admin path: key read-only; Need creation hidden                 | Permission | Frontend-gated (filtered UI)         |

### BR-SYS-007 Gap Analysis

The FRD explicitly states: "No Dropdown Value can be created without a matching Dropdown Need registered for that table-column pair." However, the current `TenantDropdownController::store()` implementation:

1. Accepts any `key` from the user (slugified)
2. Does NOT query `sys_dropdown_needs` to verify a Need exists for this key's (table, column)
3. BR-SYS-007 violation scenario: A user could create values for an unregistered key, which would then appear in the Dropdown List tab but have no corresponding Need for mapping

### BR-SYS-008 Gap Analysis

The FRD states: "Group key is always derived server-side as `tablename.columnname`; never accepted from request body." However:
- The current implementation accepts `key` from the user via TenantDropdownRequest
- The key is slugified but is NOT derived from a Dropdown Need
- There is no mechanism in the store flow to look up a Need and derive `tablename.columnname`

### BR-SYS-016 Gap Analysis

The FRD states: "Dropdown Value deletion blocked if school data references it; deactivation always permitted."
- The current `destroy()` method has NO reference check
- It simply sets `is_active=false` and soft-deletes
- Any school data referencing this dropdown value would break silently

---

## 9. Permission and Authorization Model

### 9.1 Permission Gates

| Gate                               | Method(s)                             |
|------------------------------------|---------------------------------------|
| `system-config.dropdown.viewAny`   | `index`, `getColumns`                 |
| `system-config.dropdown.create`    | `create`, `store`                     |
| `system-config.dropdown.update`    | `edit`, `update`, `toggleStatus`      |
| `system-config.dropdown.delete`    | `destroy`                             |
| `system-config.dropdown.restore`   | `trashed`, `restore`                  |
| `system-config.dropdown.forceDelete`| `forceDelete`                        |

### 9.2 FormRequest Auth

The `TenantDropdownRequest` also performs authorization:
- POST: checks `system-config.dropdown.create`
- PUT: checks `system-config.dropdown.update`

### 9.3 Permission Naming Note

The permissions use the prefix `system-config.dropdown.*` (hyphenated) rather than `tenant.dropdown.*` used by the Dropdown Needs controller. This is a source of potential confusion and inconsistency.

---

## 10. Error Handling and Edge Cases

### 10.1 Error Responses

| Scenario                                       | Response                                           | HTTP Status |
|------------------------------------------------|----------------------------------------------------|-------------|
| `key` empty on store                           | Validation error "The key field is required."      | 422         |
| `value` empty on store                         | Validation error "The value field is required."    | 422         |
| `key` exceeds 160 chars                        | Validation error "The key must not be greater than 160 characters." | 422 |
| `value` exceeds 255 chars                      | Validation error "The value must not be greater than 255 characters." | 422 |
| `type` invalid                                 | Validation error "The selected type is invalid."   | 422         |
| Duplicate (key, value) on store                | DB UNIQUE violation → 500 (not graceful)           | 500         |
| Duplicate (key, ordinal) on store              | DB UNIQUE violation → 500 (not graceful)           | 500         |
| Non-existing ID on edit/update/destroy         | 404 Not Found (`findOrFail`)                       | 404         |
| Non-existing ID on restore/forceDelete         | 404 Not Found (`withTrashed()->findOrFail()`)      | 404         |
| Invalid table name on getColumns               | JSON `{error: "Invalid table"}`                   | 422         |
| Unauthorized (missing permission)              | 403 "This action is unauthorized."                 | 403         |
| Toggle status on non-existing dropdown         | 404 Not Found (implicit model binding)             | 404         |

### 10.2 Edge Cases

| Edge Case                                      | Expected Behaviour                                                     |
|------------------------------------------------|------------------------------------------------------------------------|
| Store with empty comma-separated value         | Empty values filtered out by `array_filter`                            |
| Store with duplicate values in comma list      | `array_unique` removes duplicates before insert                        |
| Store with all-empty list                      | No records created, redirect with success flash (no error)             |
| Store with concurrent MAX+1 collision          | DB UNIQUE constraint catches the second insert → 500                   |
| Update with `additional_info` omitted          | Preserves existing `additional_info` from DB                           |
| Update of a soft-deleted record (without withTrashed) | 404 (implicit model binding excludes soft-deleted)               |
| Toggle status with invalid JSON request        | Returns `{success: false, message: ...}`                               |
| getColumns with empty table_name               | Returns empty JSON array `[]`                                          |
| getColumns with valid but empty table          | Returns empty JSON array (no columns)                                  |
| forceDelete on non-deleted record              | 404 (withTrashed ensures only trashed records can be force-deleted)    |

---

## 11. Non-Functional Requirements

| NFR-ID       | Category      | Requirement                                                        | Threshold            |
|--------------|---------------|--------------------------------------------------------------------|----------------------|
| NFR-SYS-005  | Performance   | Dropdown Values list (grouped, paginated, 10/page)                 | < 300 ms at P95      |
| NFR-SYS-008  | Security      | Zero unauthorised access to any route                              | 403 for missing permission |
| NFR-SYS-011  | Security      | All controller mutations use validated data only                   | No `$request->all()` on models |
| NFR-SYS-012  | Security      | CSRF protection on all write routes                                | POST/PUT/DELETE on `web` middleware |
| NFR-SYS-017  | Availability  | DropdownsSeeder must be idempotent and included in setup sequence  | Platform-critical    |

---

## 12. Dependencies and Integration Points

| Dependency                    | Type       | Details                                                             |
|-------------------------------|------------|---------------------------------------------------------------------|
| `sys_dropdown_table`          | Table      | Primary data table                                                  |
| `sys_dropdown_need_dropdowns_jnt` | Junction | Many-to-many link to `sys_dropdown_needs`                          |
| `sys_dropdown_needs`          | Table      | Dropdown Needs registry (prerequisite)                             |
| `DropdownNeed` model          | Model      | `Modules\SystemConfig\Models\DropdownNeed`                          |
| `Auth / Spatie RBAC`          | Module     | All permission checks resolve through Spatie roles/permissions      |
| `activityLog()`               | Helper     | Shared helper for audit trail logging                               |
| `DropdownsSeeder`             | Seeder     | Seeds initial dropdown values — platform-critical                   |

---

## 13. Known Issues and Technical Debt

| Issue ID    | Description                                                               | Severity | Status     |
|-------------|---------------------------------------------------------------------------|----------|------------|
| SYS-TD-10   | BR-SYS-007 NOT enforced — values can be created without a matching Need    | Critical | Unresolved |
| SYS-TD-11   | BR-SYS-008 NOT followed — key accepted from request, not derived from Need | Critical | Unresolved |
| SYS-TD-12   | BR-SYS-016 NOT enforced — no reference check before deletion               | High     | Unresolved |
| SYS-TD-13   | Concurrent ordinal collision not handled — DB unique violation throws 500  | Medium   | Unresolved |
| SYS-TD-14   | Permission naming inconsistency: `system-config.dropdown.*` vs `tenant.dropdown.*` | Low | Unresolved |
| SYS-TD-15   | Controller naming "Tenant" prefix misleading — serves central admin, not tenant | Low | Cosmetic |
| SYS-TD-16   | No feature tests exist — 0 HTTP/feature test coverage                      | High     | Unresolved |
| SYS-TD-17   | `sys_dropdown_table` may lack `deleted_at` column in some DDL versions     | Low      | Verify     |

---

## 14. User Stories and Acceptance Criteria

### US-SYS-005: Dropdown Value Management (P0)

**As a Platform Manager,** I want to add Dropdown Values to a registered Dropdown Need so that school administrators see the correct options when filling in forms.

**Acceptance Criteria:**

```
Scenario: Create a dropdown value
  Given a Dropdown Need exists for (Tenant, std_students, blood_group_id)
  When I submit key="std_students.blood_group_id" and value="A+"
  Then a Dropdown Value is created with key="std_students_blood_group_id", value="A+"
  And the ordinal is auto-assigned as MAX+1 within the key group

Scenario: Create multiple comma-separated values
  When I submit key="std_students.blood_group_id" and value="A+,B+,AB+,O+"
  Then 4 separate Dropdown Values are created
  And ordinals are sequential starting from MAX+1

Scenario: Group key is derived server-side
  When I submit key="anything injected" (with spaces/uppercase)
  Then the saved key is slugified to "anything_injected"

Scenario: Update preserves additional_info when not provided
  Given a dropdown value has additional_info='{"color":"red"}'
  When I update only the value field
  Then additional_info is preserved as '{"color":"red"}'

Scenario: Soft-delete sets is_active=false before delete
  When I delete a dropdown value
  Then is_active is set to false
  And the record is soft-deleted (deleted_at is set)

Scenario: Restore reactivates
  When I restore a soft-deleted dropdown
  Then is_active is set to true
  And deleted_at is set to null

Scenario: Force delete removes junction records
  Given a dropdown is mapped to 2 needs
  When I force-delete the dropdown
  Then all junction entries for that dropdown are permanently removed
  And the dropdown is permanently deleted
```

**Definition of Done:** Group key derived server-side; ordinal auto-assigned; DB unique constraints enforced; audit logged; feature tests cover all scenarios.

---

## 15. Traceability Matrix

| FR-ID   | REQ/BR Ref           | Controller Method(s)  | Test Coverage |
|---------|----------------------|------------------------|---------------|
| FR-01   | REQ-SYS-005          | `index`                | ⬜            |
| FR-02   | REQ-SYS-005          | `create`, `store`      | ⬜            |
| FR-03   | REQ-SYS-005          | `edit`, `update`       | ⬜            |
| FR-05   | REQ-SYS-005          | `destroy`              | ⬜            |
| FR-06   | REQ-SYS-005          | `trashed`              | ⬜            |
| FR-07   | REQ-SYS-005          | `restore`              | ⬜            |
| FR-08   | REQ-SYS-005          | `forceDelete`          | ⬜            |
| FR-09   | REQ-SYS-005          | `toggleStatus`         | ⬜            |
| FR-10   | REQ-SYS-005          | `getColumns`           | ⬜            |
| FR-11   | BR-SYS-012           | All write methods      | ⬜            |
|         | BR-SYS-007           | `store` — **MISSING**  | ❌            |
|         | BR-SYS-008           | `store` — **PARTIAL**  | ❌            |
|         | BR-SYS-009           | `store`, DB constraints | ⬜            |
|         | BR-SYS-016           | `destroy` — **MISSING** | ❌            |

---

## 16. V1/V2 Status and Priority

| Component                      | V1   | V2   | Status    | Priority |
|--------------------------------|------|------|-----------|----------|
| Controller & Views             | —    | ✅   | Complete  | P0       |
| Auth (Gate checks)             | —    | ✅   | Present   | P0       |
| Comma-separated store          | —    | ✅   | Complete  | P0       |
| Ordinal auto-assignment        | —    | ✅   | Complete  | P1       |
| Key slugification              | —    | ✅   | Complete  | P1       |
| SoftDelete lifecycle           | —    | ✅   | Complete  | P0       |
| forceDelete junction cleanup   | —    | ✅   | Complete  | P1       |
| getColumns whitelist           | —    | ✅   | Complete  | P1       |
| activityLog() integration      | —    | ✅   | Present   | P0       |
| BR-SYS-007 (Need check)        | —    | ❌   | Missing   | P0       |
| BR-SYS-008 (key derivation)    | —    | ❌   | Gap       | P0       |
| BR-SYS-016 (reference check)   | —    | ❌   | Missing   | P1       |
| Feature Tests                  | —    | ❌   | Missing   | P1       |
| Concurrent ordinal handling    | —    | ❌   | Missing   | P2       |

**Overall Completion:** ~75%

**Critical Gaps (P0):**
1. BR-SYS-007: Controller must verify a matching DropdownNeed exists before creating values
2. BR-SYS-008: Key derivation should happen from the Need record, not from user input

**Next Actions:**
1. Implement Need existence check in `store()` before value creation
2. Derive key from DropdownNeed's (table_name.column_name) instead of user input
3. Add reference count check in `destroy()` before allowing deletion
4. Handle concurrent ordinal collision gracefully
5. Write feature tests covering all routes and permissions
