# tmp_Template_Purpose_TcList

## Module: Template → Template Purpose Management → CRUD

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Template (TMP) |
| Tab Group | Template Purpose Management |
| Features | Template Purpose List (with scope type filter), Create/Edit/View/Delete/Restore/Force-Delete/Trash, Toggle Status |
| URL(s) | `/purposes`, `/purposes/create`, `/purposes/{template_purpose}/edit`, `/purposes/{template_purpose}`, `/purposes/trash`, `/purposes/{id}/restore`, `/purposes/{id}/force-delete`, `/purposes/{id}/toggle-status` |
| Controller | `TemplatePurposeController` |
| Model(s) | `TemplatePurpose` (table `tmp_template_purposes`) |
| Validation | `StoreTemplatePurposeRequest` (6 field rules) |
| Permission Gates | `tenant.template.purpose.viewAny`, `tenant.template.purpose.view`, `tenant.template.purpose.create`, `tenant.template.purpose.update`, `tenant.template.purpose.delete`, `tenant.template.purpose.restore`, `tenant.template.purpose.forceDelete` |
| Soft Deletes | Yes — `TemplatePurpose` model uses `SoftDeletes` trait |
| Activity Log | Yes — `activityLog()` called on store (created), update (updated), destroy (deleted), toggleStatus (status_updated), restore (restored), forceDelete (permanently_deleted) |

---

## 2. Pre-conditions

- Required permissions: `tenant.template.purpose.viewAny`, `tenant.template.purpose.create`, `tenant.template.purpose.update`, `tenant.template.purpose.view`, `tenant.template.purpose.delete`, `tenant.template.purpose.restore`, `tenant.template.purpose.forceDelete`
- At least one active scope type must exist in `sys_dropdown_table` with key=`tmp_template_purposes.scope_type_id` AND `is_active=1`
- For search/filter tests: at least one `tmp_template_purposes` record with populated fields
- For scope-type filter tests: records with at least two different `scope_type_id` values
- For toggle-status tests: at least one active (`is_active=1`) and one inactive (`is_active=0`) purpose
- For trash/restore tests: at least one soft-deleted purpose record
- For `is_system` guard tests: at least one system-defined purpose (`is_system=true`) and one custom purpose (`is_system=false`)

---

## 3. Default Data Load

### 3.1 Purpose List via Tab View

The `index()` method redirects to `route('template.tabs', ['tab' => 'purpose_list'])`. The actual list is rendered by `TemplateController::purposesQuery()` which returns:
- `purposes` — Paginated `TemplatePurpose` records with search support (code, name, description)
- `scopeTypes` — Active scope type dropdown data

Search/filter parameters:
- `search` — Text search on `code`, `name`, `description`
- `scope_type_id` — Filter by scope type (FK to `sys_dropdown_table`)
- `status` — `is_active` filter (converted to boolean)

### 3.2 Scope Types for Create Form

The `create()` method returns:
- `scopeTypes` — Collection of `Dropdown` records where key=`tmp_template_purposes.scope_type_id` AND `is_active=1`, used to populate the scope type select dropdown

---

## 4. BC-DB — Database Schema

### 4.1 `tmp_template_purposes` — Primary Template Purpose Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| code | VARCHAR(30) | NOT NULL | — | Unique purpose code |
| name | VARCHAR(100) | NOT NULL | — | Purpose name |
| description | VARCHAR(255) | YES | NULL | Purpose description |
| scope_type_id | INT UNSIGNED | NOT NULL | — | FK → sys_dropdown_table(id) RESTRICT |
| display_order | SMALLINT UNSIGNED | YES | 1 | Display sort order |
| is_system | TINYINT(1) | YES | 0 | System-defined flag (non-editable) |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uq_tmp_template_purposes_code` (`code`)
- KEY `idx_tmp_purpose_scope_type` (`scope_type_id`)

---

## 5. BC-VAL — Validation Rules

### 5.1 StoreTemplatePurposeRequest Validation

| Field | Rules | Error Message |
|-------|-------|---------------|
| code | required, string, max:30, unique:tmp_template_purposes,code (ignore $templatePurpose->id on update, whereNull deleted_at) | "The code has already been taken." (unique) |
| name | required, string, max:100 | "The name field is required." |
| description | nullable, string, max:255 | — |
| scope_type_id | required, integer | "The scope type id field is required." |
| display_order | nullable, integer, min:1 | "The display order must be at least 1." |
| is_system | boolean | "The is system field must be true or false." |

**Unique Rule On Create:** Uses `Rule::unique('tmp_template_purposes', 'code')->whereNull('deleted_at')` to exclude soft-deleted records.

**Unique Rule On Update:** Uses `Rule::unique('tmp_template_purposes', 'code')->ignore($templatePurpose->id)->whereNull('deleted_at')` to exclude the current record and soft-deleted records.

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method(s) | Model Policy |
|----------------|---------------------|-------------|
| tenant.template.purpose.viewAny | index() | TemplatePurposePolicy@viewAny |
| tenant.template.purpose.view | show() | TemplatePurposePolicy@view |
| tenant.template.purpose.create | create(), store() | TemplatePurposePolicy@create |
| tenant.template.purpose.update | edit(), update(), toggleStatus() | TemplatePurposePolicy@update |
| tenant.template.purpose.delete | destroy() | TemplatePurposePolicy@delete |
| tenant.template.purpose.restore | trashed(), restore() | TemplatePurposePolicy@restore |
| tenant.template.purpose.forceDelete | forceDelete() | TemplatePurposePolicy@forceDelete |

**Policy Gates in Controller (7):**
- `index()` → `Gate::authorize('tenant.template.purpose.viewAny')`
- `create()` / `store()` → `Gate::authorize('tenant.template.purpose.create')`
- `edit()` / `update()` → `Gate::authorize('tenant.template.purpose.update')`
- `show()` → `Gate::authorize('tenant.template.purpose.view')`
- `destroy()` → `Gate::authorize('tenant.template.purpose.delete')`
- `trashed()` / `restore()` → `Gate::authorize('tenant.template.purpose.restore')`
- `forceDelete()` → `Gate::authorize('tenant.template.purpose.forceDelete')`

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | Scope Type Filter | index() filters purposes by `scope_type_id` if provided via request |
| BC-BIZ-02 | Search Across Fields | index() searches code, name, description via `like` with wildcards |
| BC-BIZ-03 | System Purpose Guard — Update | update() checks `$purpose->is_system` and blocks edit with "Cannot modify a system-defined template purpose." error |
| BC-BIZ-04 | System Purpose Guard — Delete | destroy() checks `$purpose->is_system` and blocks delete with error |
| BC-BIZ-05 | System Purpose Guard — Force Delete | forceDelete() checks `$purpose->is_system` and blocks permanent delete with error |
| BC-BIZ-06 | Cascade Deactivation on Delete | destroy() calls `$purpose->assignments()->update(['is_active' => false])` before soft-deleting the purpose |
| BC-BIZ-07 | Soft Delete | destroy() calls `$purpose->delete()` which sets `deleted_at` timestamp |
| BC-BIZ-08 | Restore | restore() uses `onlyTrashed()->findOrFail($id)` then `$purpose->restore()` |
| BC-BIZ-09 | Force Delete (Permanent) | forceDelete() uses `withTrashed()->findOrFail($id)` to bypass SoftDeletes and permanently delete |
| BC-BIZ-10 | Toggle Status | toggleStatus() validates `is_active` as required|boolean, returns JSON success/error response |
| BC-BIZ-11 | Unique Code (Soft-Delete Aware) | Validation ignores soft-deleted records via `whereNull('deleted_at')` |
| BC-BIZ-12 | Display Order Default | display_order defaults to 1 when not provided |
| BC-BIZ-13 | Scope Type Dropdown for Create | create() loads scope types from Dropdown where key matches scope_type_id and is_active=1 |
| BC-BIZ-14 | Scope Type FK Restrict | scope_type_id FK → sys_dropdown_table(id) with RESTRICT — cannot delete referenced dropdown if purposes exist |
| BC-BIZ-15 | Model Scopes | `active()` → `where('is_active', true)`, `classScoped()` → scope type filter, `schoolWide()` → school-wide scope type filter |
| BC-BIZ-16 | Code Immutability for System Purposes | System purposes (`is_system=true`) block code changes in update() |
| BC-BIZ-17 | Activity Log All Operations | activityLog() called on store (created), update (updated), destroy (deleted), toggleStatus (status_updated), restore (restored), forceDelete (permanently_deleted) — tracks who performed each action |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_tmp_purpose_scope_type | tmp_template_purposes.scope_type_id | sys_dropdown_table.id | RESTRICT |
| fk_tmp_assignment_purpose | tmp_template_assignments.purpose_id (implied by model) | tmp_template_purposes.id | CASCADE (implied by model relationships) |

**TemplateAssignment Dependency:**
- `TemplatePurpose` has `assignments()` HasMany → `TemplateAssignment`
- When a purpose is soft-deleted, its assignments are deactivated via `$purpose->assignments()->update(['is_active' => false])`
- The `scope_type_id` FK uses `ON DELETE RESTRICT` — preventing deletion of a scope type dropdown value that is referenced by any purpose

---

## 9. Test Case Summary

### 9.1 Template Purpose CRUD — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-TMP-P01 | Template Purpose | Positive | Index loads with search, scope type filter, and pagination | 5 |
| TC-TMP-P02 | Template Purpose | Positive | Create custom purpose — all required fields (code, name, scope_type_id) | 6 |
| TC-TMP-P03 | Template Purpose | Positive | Create custom purpose — all optional fields (description, display_order) | 5 |
| TC-TMP-P04 | Template Purpose | Positive | View purpose detail | 3 |
| TC-TMP-P05 | Template Purpose | Positive | Edit custom purpose — update name, description, display_order | 5 |
| TC-TMP-P06 | Template Purpose | Positive | Edit custom purpose — change scope_type_id | 5 |
| TC-TMP-P07 | Template Purpose | Positive | Toggle status — active to inactive | 4 |
| TC-TMP-P08 | Template Purpose | Positive | Toggle status — inactive to active | 4 |
| TC-TMP-P09 | Template Purpose | Positive | Soft-delete custom purpose | 4 |
| TC-TMP-P10 | Template Purpose | Positive | View trashed purposes | 3 |
| TC-TMP-P11 | Template Purpose | Positive | Restore custom purpose from trash | 4 |
| TC-TMP-P12 | Template Purpose | Positive | Force-delete custom purpose | 4 |
| TC-TMP-P13 | Template Purpose | Positive | Search purposes — by code | 3 |
| TC-TMP-P14 | Template Purpose | Positive | Search purposes — by name | 3 |
| TC-TMP-P15 | Template Purpose | Positive | Search purposes — by description | 3 |
| TC-TMP-P16 | Template Purpose | Positive | Filter purposes — by scope_type_id | 3 |
| TC-TMP-P17 | Template Purpose | Positive | Filter purposes — by status (active/inactive) | 3 |
| TC-TMP-P18 | Template Purpose | Positive | Create custom purpose with display_order=99 | 5 |
| TC-TMP-P19 | Template Purpose | Positive | Duplicate code allowed if existing record is soft-deleted | 3 |
| TC-TMP-P20 | Template Purpose | Positive | Soft-delete custom purpose cascades to deactivate all linked assignments | 4 |
| TC-TMP-P21 | Template Purpose | Positive | Activity log created on purpose store | 3 |
| TC-TMP-P22 | Template Purpose | Positive | Activity log created on purpose update | 3 |
| TC-TMP-P23 | Template Purpose | Positive | Activity log created on purpose soft-delete | 2 |
| TC-TMP-P24 | Template Purpose | Positive | Activity log created on purpose restore | 2 |
| TC-TMP-P25 | Template Purpose | Positive | Activity log created on purpose force-delete | 2 |
| TC-TMP-P26 | Template Purpose | Positive | Activity log created on purpose toggle-status | 3 |

### 9.2 Template Purpose CRUD — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-TMP-N01 | Template Purpose | Negative | Create — missing code | 2 |
| TC-TMP-N02 | Template Purpose | Negative | Create — code exceeds 30 chars | 2 |
| TC-TMP-N03 | Template Purpose | Negative | Create — duplicate code (existing active) | 2 |
| TC-TMP-N04 | Template Purpose | Negative | Create — missing name | 2 |
| TC-TMP-N05 | Template Purpose | Negative | Create — name exceeds 100 chars | 2 |
| TC-TMP-N06 | Template Purpose | Negative | Create — missing scope_type_id | 2 |
| TC-TMP-N07 | Template Purpose | Negative | Create — invalid scope_type_id (non-integer) | 2 |
| TC-TMP-N08 | Template Purpose | Negative | Create — display_order = 0 (min:1 violation) | 2 |
| TC-TMP-N09 | Template Purpose | Negative | Create — display_order = negative value | 2 |
| TC-TMP-N10 | Template Purpose | Negative | Create — description exceeds 255 chars | 2 |
| TC-TMP-N11 | Template Purpose | Negative | Edit system purpose — blocked with error message | 3 |
| TC-TMP-N12 | Template Purpose | Negative | Delete system purpose — blocked with error message | 3 |
| TC-TMP-N13 | Template Purpose | Negative | Force-delete system purpose — blocked with error message | 3 |
| TC-TMP-N14 | Template Purpose | Negative | Edit system purpose — change code blocked | 3 |
| TC-TMP-N15 | Template Purpose | Negative | Update — duplicate code (existing active different purpose) | 3 |
| TC-TMP-N16 | Template Purpose | Negative | Toggle status — missing is_active parameter | 2 |
| TC-TMP-N17 | Template Purpose | Negative | Toggle status — non-boolean is_active value | 2 |
| TC-TMP-N18 | Template Purpose | Negative | Toggle status — non-existent purpose ID | 2 |
| TC-TMP-N19 | Template Purpose | Negative | Force delete — non-existent purpose ID | 2 |
| TC-TMP-N20 | Template Purpose | Negative | Restore — non-existent purpose ID | 2 |
| TC-TMP-N21 | Template Purpose | Negative | Permission — index without tenant.template.purpose.viewAny | 2 |
| TC-TMP-N22 | Template Purpose | Negative | Permission — create without tenant.template.purpose.create | 2 |
| TC-TMP-N23 | Template Purpose | Negative | Permission — store without tenant.template.purpose.create | 2 |
| TC-TMP-N24 | Template Purpose | Negative | Permission — edit without tenant.template.purpose.update | 2 |
| TC-TMP-N25 | Template Purpose | Negative | Permission — update without tenant.template.purpose.update | 2 |
| TC-TMP-N26 | Template Purpose | Negative | Permission — show without tenant.template.purpose.view | 2 |
| TC-TMP-N27 | Template Purpose | Negative | Permission — destroy without tenant.template.purpose.delete | 2 |
| TC-TMP-N28 | Template Purpose | Negative | Permission — trashed without tenant.template.purpose.restore | 2 |
| TC-TMP-N29 | Template Purpose | Negative | Permission — restore without tenant.template.purpose.restore | 2 |
| TC-TMP-N30 | Template Purpose | Negative | Permission — forceDelete without tenant.template.purpose.forceDelete | 2 |
| TC-TMP-N31 | Template Purpose | Negative | Permission — toggleStatus without tenant.template.purpose.update | 2 |
| TC-TMP-N32 | Template Purpose | Negative | Edit custom purpose — name whitespace-only (nullable gap) | 3 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR01 | Code Review | Review | index() — gate, search, scope type filter, pagination | 5 |
| TC-CR02 | Code Review | Review | create() — scope type dropdown load logic | 3 |
| TC-CR03 | Code Review | Review | store() — gate + validation + creation logic | 4 |
| TC-CR04 | Code Review | Review | update() — is_system guard and update logic | 5 |
| TC-CR05 | Code Review | Review | destroy() — is_system guard + cascade deactivation + soft delete | 5 |
| TC-CR06 | Code Review | Review | restore() — onlyTrashed()->findOrFail + restore | 3 |
| TC-CR07 | Code Review | Review | forceDelete() — is_system guard + withTrashed()->findOrFail + forceDelete | 4 |
| TC-CR08 | Code Review | Review | toggleStatus() — gate + validation + JSON response | 4 |
| TC-CR09 | Code Review | Review | StoreTemplatePurposeRequest — all field rules and unique ignore logic | 6 |
| TC-CR10 | Code Review | Review | StoreTemplatePurposeRequest — unique with whereNull deleted_at on create vs update | 4 |
| TC-CR11 | Code Review | Review | TemplatePurposePolicy — all 7 gate methods | 4 |
| TC-CR12 | Code Review | Review | TemplatePurpose Model — fillable, casts, scopes | 5 |
| TC-CR13 | Code Review | Review | TemplatePurpose Model — relationships (scopeType, assignments) | 3 |
| TC-CR14 | Code Review | Review | TemplatePurpose Model — scope definitions (active, classScoped, schoolWide) | 3 |
| TC-CR15 | Code Review | Review | Cascade deactivation — assignments()->update is_active before delete | 3 |
| TC-CR16 | Code Review | Review | is_system guard — consistent checks in update, destroy, forceDelete | 4 |
| TC-CR17 | Code Review | Review | destroy() — assignments()->update(['is_active'=>false]) before soft-delete | 3 |
| TC-CR18 | Code Review | Review | store() — activityLog call with 'created' event | 3 |
| TC-CR19 | Code Review | Review | update() — activityLog call with 'updated' event | 3 |
| TC-CR20 | Code Review | Review | destroy() — activityLog call with 'deleted' event | 3 |
| TC-CR21 | Code Review | Review | restore() — activityLog call with 'restored' event | 3 |
| TC-CR22 | Code Review | Review | forceDelete() — activityLog call with 'permanently_deleted' event | 3 |
| TC-CR23 | Code Review | Review | toggleStatus() — activityLog call with 'status_updated' event | 3 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-D01 | Dependency | Dependency | scope_type_id FK → sys_dropdown_table — RESTRICT on delete | 3 |
| TC-D02 | Dependency | Dependency | SoftDelete — deleted purposes excluded from unique code validation | 3 |
| TC-D03 | Dependency | Dependency | TemplateAssignment cascade — assignments deactivated when purpose soft-deleted | 3 |
| TC-D04 | Dependency | Dependency | Scope type dropdown — only active scope types (is_active=1) loaded in create form | 3 |
| TC-D05 | Dependency | Dependency | Purpose soft-delete cascades is_active=false to assignments | 3 |
| TC-D06 | Dependency | Dependency | Activity log entry created on every CRUD operation | 6 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Template Purpose CRUD

#### TC-TMP-P01: Index loads with search, scope type filter, and pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.purpose.viewAny` permission navigates to `/purposes` | Index page loads |
| 2 | Verify search input, scope type filter dropdown, and status filter dropdown are present | Filters visible |
| 3 | Verify paginated purpose list with columns: code, name, description, scope_type, display_order, is_active toggle, is_system badge, Actions | All columns present |
| 4 | Verify pagination links (default per page count) | Paginated |
| 5 | Verify scope type filter dropdown populated with active scope types from sys_dropdown_table | Dropdown populated |

#### TC-TMP-P02: Create custom purpose — all required fields (code, name, scope_type_id)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.purpose.create` permission clicks "Add Template Purpose" | Create form loads |
| 2 | Verify scope_type_id dropdown shows only active scope types | Scope types visible |
| 3 | Enter code="CUSTOM_PURPOSE_01", name="Custom Purpose 1", select a valid scope_type_id | Fields populated |
| 4 | Leave description and display_order blank | Optional fields empty |
| 5 | Click Submit | Redirected to purpose index |
| 6 | Verify success flash message appears and new purpose appears in the list with is_system=false | Purpose created |

#### TC-TMP-P03: Create custom purpose — all optional fields (description, display_order)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter code="FULL_PURPOSE", name="Full Purpose", select scope_type_id | Required fields set |
| 3 | Enter description="This is a full purpose for testing", display_order=5 | Optional fields populated |
| 4 | Submit form | Success |
| 5 | Verify DB record has all 6 fillable fields populated correctly | DB verified |

#### TC-TMP-P04: View purpose detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.purpose.view` permission clicks "View" on a purpose row | Show page loads |
| 2 | Verify all fields displayed: code, name, description, scope_type, display_order, is_system, is_active | All fields visible |
| 3 | Verify is_system badge is shown (System / Custom) | Badge displayed |

#### TC-TMP-P05: Edit custom purpose — update name, description, display_order

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.purpose.update` permission clicks "Edit" on a custom purpose | Edit form loads with pre-filled data |
| 2 | Change name to "Updated Purpose", description to "Updated description", display_order to 10 | Fields changed |
| 3 | Click Update | Redirected to purpose index |
| 4 | Verify success flash message appears | Success message |
| 5 | Verify purpose list shows updated values | Changes reflected |

#### TC-TMP-P06: Edit custom purpose — change scope_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate a custom purpose with scope_type_id = 1 | Existing scoped purpose |
| 2 | Edit purpose, change scope_type_id to a different active scope type (e.g., 2) | Scope type changed |
| 3 | Submit | Success |
| 4 | Verify DB: scope_type_id updated to new value | Scope type updated |
| 5 | Verify purpose list reflects new scope type name | List updated |

#### TC-TMP-P07: Toggle status — active to inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an active purpose (is_active=true) in the list | Active purpose visible |
| 2 | Click status toggle to deactivate | AJAX call made |
| 3 | Verify JSON response: `{"success": true, "is_active": false, "message": "..."}` | AJAX success |
| 4 | Verify DB: is_active = 0 for the purpose | Deactivated |

#### TC-TMP-P08: Toggle status — inactive to active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an inactive purpose (is_active=false) in the list | Inactive purpose visible |
| 2 | Click status toggle to activate | AJAX call made |
| 3 | Verify JSON response: `{"success": true, "is_active": true, "message": "..."}` | AJAX success |
| 4 | Verify DB: is_active = 1 for the purpose | Activated |

#### TC-TMP-P09: Soft-delete custom purpose

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.purpose.delete` permission clicks "Delete" on a custom purpose | Confirmation prompt |
| 2 | Confirm deletion | Purpose soft-deleted |
| 3 | Verify purpose no longer appears in active purpose list | Removed from active |
| 4 | Verify DB: deleted_at is not NULL | Soft-deleted |

#### TC-TMP-P10: View trashed purposes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.purpose.restore` permission navigates to `/purposes/trash` | Trash list loads |
| 2 | Verify trashed purposes list shows soft-deleted records with code, name, deleted_at | Trash list visible |
| 3 | Verify Restore and Force Delete action buttons are available for each trashed purpose | Actions present |

#### TC-TMP-P11: Restore custom purpose from trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view | Trash list loads |
| 2 | Locate a soft-deleted custom purpose and click "Restore" | Purpose restored |
| 3 | Verify purpose appears in active list, deleted_at is NULL | Restored |
| 4 | Verify success flash message appears | Success message |

#### TC-TMP-P12: Force-delete custom purpose

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view | Trash list loads |
| 2 | Locate a soft-deleted custom purpose and click "Force Delete" | Confirmation prompt |
| 3 | Confirm permanent deletion | Purpose permanently deleted |
| 4 | Verify DB record no longer exists (including withTrashed) | Permanently deleted |

#### TC-TMP-P13: Search purposes — by code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In index, enter search term matching part of a purpose code | Filter applied |
| 2 | Verify result list contains only purposes with matching code | Filtered results |
| 3 | Verify search is case-insensitive and uses LIKE %term% | Wildcard search |

#### TC-TMP-P14: Search purposes — by name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In index, enter search term matching a purpose name | Filter applied |
| 2 | Verify result list contains purposes with matching name | Filtered results |
| 3 | Verify search is case-insensitive LIKE %term% | Wildcard search |

#### TC-TMP-P15: Search purposes — by description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In index, enter search term matching a purpose description | Filter applied |
| 2 | Verify result list contains purposes with matching description | Filtered results |
| 3 | Verify search is case-insensitive LIKE %term% | Wildcard search |

#### TC-TMP-P16: Filter purposes — by scope_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In index, select a scope type from the filter dropdown | Filter applied |
| 2 | Verify only purposes with matching scope_type_id are shown | Filtered results |
| 3 | Select a different scope type and verify corresponding results | Scope type changed |

#### TC-TMP-P17: Filter purposes — by status (active/inactive)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In index, set status filter to "Active" (1) | Filter applied |
| 2 | Verify only active purposes (is_active=1) are shown | Active-only list |
| 3 | Set status filter to "Inactive" (0) and verify only inactive purposes shown | Inactive-only list |

#### TC-TMP-P18: Create custom purpose with display_order=99

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter code="ORDER_99", name="Order 99 Purpose", select scope_type_id | Required fields set |
| 3 | Set display_order=99 | High display order |
| 4 | Submit form | Success |
| 5 | Verify DB: display_order = 99 for the new purpose | Order persisted |

#### TC-TMP-P19: Duplicate code allowed if existing record is soft-deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a purpose with code="UNIQUE_CODE" | Trashed purpose exists |
| 2 | Create a new purpose with code="UNIQUE_CODE" | Validation passes (ignores soft-deleted) |
| 3 | Verify new purpose created successfully with same code | Created |

#### TC-TMP-P20: Soft-delete custom purpose cascades to deactivate all linked assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a custom purpose and assign 2–3 TemplateAssignment records linked to it with is_active=true | Purpose with active assignments exists |
| 2 | Click "Delete" on the custom purpose and confirm deletion | Purpose soft-deleted |
| 3 | Query the assignments table: verify all linked assignments now have is_active=false | Assignments deactivated |
| 4 | Query the purposes table: verify deleted_at is set for the purpose | Purpose soft-deleted |

#### TC-TMP-P21: Activity log created on purpose store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with create permission creates a new purpose | Purpose created successfully |
| 2 | Navigate to activity log section or query activity_log table | Log entries visible |
| 3 | Verify activity log contains entry: event='created', subject_type=TemplatePurpose, subject_id=purpose ID, properties containing name | Log entry recorded |

#### TC-TMP-P22: Activity log created on purpose update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with update permission edits an existing custom purpose and saves changes | Purpose updated successfully |
| 2 | Navigate to activity log or query activity_log table | Log entries visible |
| 3 | Verify activity log contains entry: event='updated', subject_type=TemplatePurpose, properties containing name | Log entry recorded |

#### TC-TMP-P23: Activity log created on purpose soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with delete permission soft-deletes a custom purpose | Purpose soft-deleted |
| 2 | Verify activity log contains entry: event='deleted', subject_type=TemplatePurpose, properties containing name | Log entry recorded |

#### TC-TMP-P24: Activity log created on purpose restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with restore permission restores a soft-deleted purpose | Purpose restored |
| 2 | Verify activity log contains entry: event='restored', subject_type=TemplatePurpose, properties containing name | Log entry recorded |

#### TC-TMP-P25: Activity log created on purpose force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with forceDelete permission force-deletes a soft-deleted custom purpose | Purpose permanently deleted |
| 2 | Verify activity log contains entry: event='permanently_deleted', subject_type=TemplatePurpose, properties containing name | Log entry recorded |

#### TC-TMP-P26: Activity log created on purpose toggle-status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with update permission toggles status on a purpose | Status updated successfully |
| 2 | Navigate to activity log or query activity_log table | Log entries visible |
| 3 | Verify activity log contains entry: event='status_updated', subject_type=TemplatePurpose, properties containing name | Log entry recorded |

### 10.2 Negative TC Steps — Template Purpose CRUD

#### TC-TMP-N01: Create — missing code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without code | Validation error |
| 2 | Verify error: "The code field is required." | Error shown |

#### TC-TMP-N02: Create — code exceeds 30 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set code to a 31-character string | Exceeds max |
| 2 | Submit | Validation error: "The code must not be greater than 30 characters." |

#### TC-TMP-N03: Create — duplicate code (existing active)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Purpose with code="DUPLICATE" already exists (active) | Existing record |
| 2 | Submit create with code="DUPLICATE" | Validation error: "The code has already been taken." |

#### TC-TMP-N04: Create — missing name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without name | Validation error |
| 2 | Verify error: "The name field is required." | Error shown |

#### TC-TMP-N05: Create — name exceeds 100 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set name to a 101-character string | Exceeds max |
| 2 | Submit | Validation error: "The name must not be greater than 100 characters." |

#### TC-TMP-N06: Create — missing scope_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without scope_type_id | Validation error |
| 2 | Verify error: "The scope type id field is required." | Error shown |

#### TC-TMP-N07: Create — invalid scope_type_id (non-integer)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set scope_type_id = "abc" (non-integer string) | Invalid type |
| 2 | Submit | Validation error: "The scope type id must be an integer." |

#### TC-TMP-N08: Create — display_order = 0 (min:1 violation)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set display_order = 0 | Below minimum |
| 2 | Submit | Validation error: "The display order must be at least 1." |

#### TC-TMP-N09: Create — display_order = negative value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set display_order = -5 | Negative value |
| 2 | Submit | Validation error: "The display order must be at least 1." |

#### TC-TMP-N10: Create — description exceeds 255 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set description to a 256-character string | Exceeds max |
| 2 | Submit | Validation error: "The description must not be greater than 255 characters." |

#### TC-TMP-N11: Edit system purpose — blocked with error message

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate a system purpose (is_system=true) | System purpose exists |
| 2 | Attempt to edit — submit modified name/description | Update blocked |
| 3 | Verify error: "Cannot modify a system-defined template purpose." | Blocked |

#### TC-TMP-N12: Delete system purpose — blocked with error message

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate a system purpose (is_system=true) | System purpose exists |
| 2 | Attempt to delete the system purpose | Delete blocked |
| 3 | Verify error: "Cannot modify a system-defined template purpose." (or equivalent) | Blocked |

#### TC-TMP-N13: Force-delete system purpose — blocked with error message

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate a system purpose (is_system=true) that is soft-deleted | Trashed system purpose |
| 2 | Attempt to force-delete the system purpose | Force delete blocked |
| 3 | Verify error: "Cannot modify a system-defined template purpose." | Blocked |

#### TC-TMP-N14: Edit system purpose — change code blocked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate a system purpose with code="SYSTEM_CODE" | System purpose exists |
| 2 | Attempt to edit the system purpose's code to "NEW_CODE" | Update blocked by is_system guard |
| 3 | Verify error: "Cannot modify a system-defined template purpose." | Blocked |

#### TC-TMP-N15: Update — duplicate code (existing active different purpose)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Purpose A has code="CODE_A", Purpose B has code="CODE_B" | Two purposes exist |
| 2 | Edit Purpose B and change code to "CODE_A" | Duplicate attempt |
| 3 | Submit | Validation error: "The code has already been taken." |

#### TC-TMP-N16: Toggle status — missing is_active parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/purposes/{id}/toggle-status` without is_active in request body | Validation error |
| 2 | Verify error: "The is active field is required." | Error returned |

#### TC-TMP-N17: Toggle status — non-boolean is_active value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/purposes/{id}/toggle-status` with is_active="not-a-boolean" | Validation error |
| 2 | Verify error: "The is active field must be true or false." | Error returned |

#### TC-TMP-N18: Toggle status — non-existent purpose ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/purposes/99999/toggle-status` with is_active=true | Purpose 99999 doesn't exist |
| 2 | Verify 404 Not Found from findOrFail | 404 error |

#### TC-TMP-N19: Force delete — non-existent purpose ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/purposes/99999/force-delete` | Purpose 99999 doesn't exist |
| 2 | Verify 404 Not Found from withTrashed()->findOrFail | 404 error |

#### TC-TMP-N20: Restore — non-existent purpose ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/purposes/99999/restore` | Purpose 99999 doesn't exist |
| 2 | Verify 404 Not Found from onlyTrashed()->findOrFail | 404 error |

#### TC-TMP-N21: Permission — index without tenant.template.purpose.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.purpose.viewAny` accesses `/purposes` | 403 Forbidden |
| 2 | Verify Gate::authorize fails and abort(403) is triggered | Aborted |

#### TC-TMP-N22: Permission — create without tenant.template.purpose.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.purpose.create` accesses `/purposes/create` | 403 Forbidden |

#### TC-TMP-N23: Permission — store without tenant.template.purpose.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.purpose.create` POSTs to `/purposes` | 403 Forbidden |

#### TC-TMP-N24: Permission — edit without tenant.template.purpose.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.purpose.update` accesses `/purposes/{id}/edit` | 403 Forbidden |

#### TC-TMP-N25: Permission — update without tenant.template.purpose.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.purpose.update` PUTs to `/purposes/{id}` | 403 Forbidden |

#### TC-TMP-N26: Permission — show without tenant.template.purpose.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.purpose.view` accesses `/purposes/{id}` | 403 Forbidden |

#### TC-TMP-N27: Permission — destroy without tenant.template.purpose.delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.purpose.delete` DELETEs `/purposes/{id}` | 403 Forbidden |

#### TC-TMP-N28: Permission — trashed without tenant.template.purpose.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.purpose.restore` accesses `/purposes/trash` | 403 Forbidden |

#### TC-TMP-N29: Permission — restore without tenant.template.purpose.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.purpose.restore` POSTs to `/purposes/{id}/restore` | 403 Forbidden |

#### TC-TMP-N30: Permission — forceDelete without tenant.template.purpose.forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.purpose.forceDelete` DELETEs `/purposes/{id}/force-delete` | 403 Forbidden |

#### TC-TMP-N31: Permission — toggleStatus without tenant.template.purpose.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.purpose.update` POSTs to `/purposes/{id}/toggle-status` | 403 Forbidden |

#### TC-TMP-N32: Edit custom purpose — name whitespace-only (nullable gap)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit a custom purpose, set name = "   " (whitespace-only) | Passes required + string validation |
| 2 | Submit | May succeed (required only checks non-empty, but whitespace may pass) |
| 3 | Verify DB storage — depending on implementation, may store whitespace string instead of meaningful value | Potential data quality issue |

### 10.3 Code Review TC Steps

#### TC-CR01: index() — gate, search, scope type filter, pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.purpose.viewAny')` at method start | Gate present |
| 2 | Review search logic: where like %term% on code, name, description with nested OR | Search logic |
| 3 | Review scope_type_id filter: `where('scope_type_id', $request->scope_type_id)` | Scope type filter |
| 4 | Review status filter: `where('is_active', (bool) $request->status)` | Status filter |
| 5 | Review paginate() call with default per-page count | Pagination |

#### TC-CR02: create() — scope type dropdown load logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.purpose.create')` | Gate present |
| 2 | Review scope type query: `Dropdown::where('key', 'tmp_template_purposes.scope_type_id')->where('is_active', 1)->get()` | Scope type query |
| 3 | Review that scopeTypes variable is passed to create view | Data passed to view |

#### TC-CR03: store() — gate + validation + creation logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.purpose.create')` | Gate present |
| 2 | Review `StoreTemplatePurposeRequest` injection for validation | Form request validation |
| 3 | Review `TemplatePurpose::create($request->validated())` | Creation via validated data |
| 4 | Review redirect with success flash message | Flash success |

#### TC-CR04: update() — is_system guard and update logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.purpose.update')` | Gate present |
| 2 | Review `$purpose->is_system` check: if true → redirect back with error "Cannot modify a system-defined template purpose." | is_system guard |
| 3 | Review `StoreTemplatePurposeRequest` injection with $purpose for unique ignore | Form request validation |
| 4 | Review `$purpose->update($request->validated())` | Update via validated data |
| 5 | Review redirect with success flash message | Flash success |

#### TC-CR05: destroy() — is_system guard + cascade deactivation + soft delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.purpose.delete')` | Gate present |
| 2 | Review `$purpose->is_system` check: if true → redirect back with error | is_system guard |
| 3 | Review cascade: `$purpose->assignments()->update(['is_active' => false])` before delete | Cascade deactivation |
| 4 | Review `$purpose->delete()` — triggers SoftDeletes | Soft delete |
| 5 | Review redirect with success flash message | Flash success |

#### TC-CR06: restore() — onlyTrashed()->findOrFail + restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.purpose.restore')` | Gate present |
| 2 | Review `TemplatePurpose::onlyTrashed()->findOrFail($id)` | Scoped to trashed only |
| 3 | Review `$purpose->restore()` and redirect with flash | Restore logic |

#### TC-CR07: forceDelete() — is_system guard + withTrashed()->findOrFail + forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.purpose.forceDelete')` | Gate present |
| 2 | Review `$purpose->is_system` check: if true → redirect back with error | is_system guard |
| 3 | Review `TemplatePurpose::withTrashed()->findOrFail($id)` | Bypasses soft-delete scope |
| 4 | Review `$purpose->forceDelete()` and redirect with flash | Permanent delete |

#### TC-CR08: toggleStatus() — gate + validation + JSON response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.purpose.update')` | Gate uses update permission |
| 2 | Review inline validation: `$request->validate(['is_active' => 'required|boolean'])` | Validation |
| 3 | Review `TemplatePurpose::findOrFail($id)` | Model binding |
| 4 | Review JSON success/error response based on `$purpose->save()` | AJAX JSON response |

#### TC-CR09: StoreTemplatePurposeRequest — all field rules and unique ignore logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review code: required|string|max:30|unique with ignore $templatePurpose->id and whereNull deleted_at | Unique logic |
| 2 | Review name: required|string|max:100 | Name rule |
| 3 | Review description: nullable|string|max:255 | Description rule |
| 4 | Review scope_type_id: required|integer (no exists validation — potential gap) | FK validation |
| 5 | Review display_order: nullable|integer|min:1 | Display order rule |
| 6 | Review is_system: boolean | Boolean rule |

#### TC-CR10: StoreTemplatePurposeRequest — unique with whereNull deleted_at on create vs update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review create path: `Rule::unique('tmp_template_purposes', 'code')->whereNull('deleted_at')` | Create unique |
| 2 | Review update path: `Rule::unique('tmp_template_purposes', 'code')->ignore($templatePurpose->id)->whereNull('deleted_at')` | Update unique |
| 3 | Verify that on update, the current record's code is excluded from uniqueness check | Self-ignore |
| 4 | Verify that soft-deleted records are excluded from uniqueness check on both create and update | Soft-delete exclusion |

#### TC-CR11: TemplatePurposePolicy — all 7 gate methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review viewAny(User): returns $user->can('tenant.template.purpose.viewAny') | viewAny gate |
| 2 | Review view(User, TemplatePurpose): returns $user->can('tenant.template.purpose.view') | view gate |
| 3 | Review create(User): returns $user->can('tenant.template.purpose.create') | create gate |
| 4 | Review update(User, TemplatePurpose): returns $user->can('tenant.template.purpose.update') | update gate |

#### TC-CR12: TemplatePurpose Model — fillable, casts, scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$fillable` array: code, name, description, scope_type_id, display_order, is_system, is_active | All fillable fields |
| 2 | Review `$casts` — scope_type_id=>integer, display_order=>integer, is_system=>boolean, is_active=>boolean | Casts configured |
| 3 | Review `SoftDeletes` trait usage | SoftDeletes trait |
| 4 | Review `scopeActive()` — where is_active = true | Active scope |
| 5 | Review `scopeClassScoped()` — scope type filter for class scoped | Class scoped scope |

#### TC-CR13: TemplatePurpose Model — relationships (scopeType, assignments)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `scopeType()` — belongsTo Dropdown::class, foreign key scope_type_id | BelongsTo relationship |
| 2 | Review `assignments()` — hasMany TemplateAssignment::class, foreign key purpose_id | HasMany relationship |
| 3 | Verify foreign keys match actual DB schema | FK consistency |

#### TC-CR14: TemplatePurpose Model — scope definitions (active, classScoped, schoolWide)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `scopeActive($query)` — `$query->where('is_active', true)` | Active scope |
| 2 | Review `scopeClassScoped($query)` — scope type filter for class-level scoping | Class scoped |
| 3 | Review `scopeSchoolWide($query)` — scope type filter for school-wide scoping | School wide |

#### TC-CR15: Cascade deactivation — assignments()->update is_active before delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review destroy() method for `$purpose->assignments()->update(['is_active' => false])` call | Cascade present |
| 2 | Verify this runs BEFORE `$purpose->delete()` | Order correct |
| 3 | Verify that assignments remain in DB (not deleted) but are deactivated | Soft deactivation |

#### TC-CR16: is_system guard — consistent checks in update, destroy, forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review update() — is_system check before allowing edit | Guard in update |
| 2 | Review destroy() — is_system check before allowing soft delete | Guard in destroy |
| 3 | Review forceDelete() — is_system check before allowing permanent delete | Guard in forceDelete |
| 4 | Verify consistent error message across all three guards ("Cannot modify a system-defined template purpose.") | Consistent messaging |

#### TC-CR17: destroy() — assignments()->update(['is_active'=>false]) before soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate the destroy() method in TemplatePurposeController | Method found |
| 2 | Review the line `$purpose->assignments()->update(['is_active' => false])` — verify it is called BEFORE `$purpose->delete()` | Cascade runs before soft-delete |
| 3 | Verify that the assignments are only deactivated, not deleted (no delete call on assignments) | Assignments preserved in DB |

#### TC-CR18: store() — activityLog call with 'created' event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate `activityLog($purpose, 'created', ['name' => $purpose->name])` after `TemplatePurpose::create()` in store() | activityLog call present |
| 2 | Verify activityLog is called after successful creation, not before | Order correct |
| 3 | Verify properties array contains 'name' key with purpose name | Properties correct |

#### TC-CR19: update() — activityLog call with 'updated' event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate `activityLog($purpose, 'updated', ['name' => $purpose->name])` after `$purpose->update()` in update() | activityLog call present |
| 2 | Verify activityLog is called after successful update | Order correct |
| 3 | Verify properties array contains 'name' key | Properties correct |

#### TC-CR20: destroy() — activityLog call with 'deleted' event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate `activityLog($purpose, 'deleted', ['name' => $purpose->name])` in destroy() | activityLog call present |
| 2 | Verify activityLog is called after `$purpose->delete()` | Order correct |
| 3 | Verify properties array contains 'name' key with purpose name | Properties correct |

#### TC-CR21: restore() — activityLog call with 'restored' event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate `activityLog($purpose, 'restored', ['name' => $purpose->name])` in restore() | activityLog call present |
| 2 | Verify activityLog is called after `$purpose->restore()` | Order correct |
| 3 | Verify properties array contains 'name' key | Properties correct |

#### TC-CR22: forceDelete() — activityLog call with 'permanently_deleted' event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate `activityLog($purpose, 'permanently_deleted', ['name' => $purpose->name])` in forceDelete() | activityLog call present |
| 2 | Verify activityLog is called after `$purpose->forceDelete()` | Order correct |
| 3 | Verify properties array contains 'name' key | Properties correct |

#### TC-CR23: toggleStatus() — activityLog call with 'status_updated' event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate `activityLog($purpose, 'status_updated', ['name' => $purpose->name])` in toggleStatus() | activityLog call present |
| 2 | Verify activityLog is called before JSON response is returned | Order correct |
| 3 | Verify properties array contains 'name' key | Properties correct |

### 10.4 Dependency TC Steps

#### TC-D01: scope_type_id FK → sys_dropdown_table — RESTRICT on delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Scope type D1 has 2 associated purposes in tmp_template_purposes | Referenced dropdown |
| 2 | Attempt to delete D1 from sys_dropdown_table | RESTRICT violation |
| 3 | Verify DB error: Cannot delete or update a parent row — FK constraint fails | Delete blocked |

#### TC-D02: SoftDelete — deleted purposes excluded from unique code validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Purpose "DELETED_PURPOSE" is soft-deleted (deleted_at NOT NULL) | Trashed purpose |
| 2 | Create new purpose with code="DELETED_PURPOSE" | Unique validation ignores soft-deleted record |
| 3 | Verify purpose created successfully despite code matching soft-deleted record | Created |

#### TC-D03: TemplateAssignment cascade — assignments deactivated when purpose soft-deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Purpose has 3 associated TemplateAssignment records with is_active=true | Active assignments exist |
| 2 | Soft-delete the purpose via destroy() | Purpose deleted |
| 3 | Verify all 3 assignments now have is_active=false in DB | Cascade deactivated |

#### TC-D04: Scope type dropdown — only active scope types (is_active=1) loaded in create form

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | sys_dropdown_table has 3 scope type records for key tmp_template_purposes.scope_type_id: 2 active, 1 inactive | Mixed records |
| 2 | Open create form for template purpose | Form loads |
| 3 | Verify scope type dropdown shows only the 2 active records, the inactive record is excluded | Active-only filter |

#### TC-D05: Purpose soft-delete cascades is_active=false to assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Purpose P1 has 3 active TemplateAssignment records (is_active=true) | Active assignments exist |
| 2 | Trigger soft-delete on P1 via destroy() endpoint | Purpose deleted |
| 3 | Verify all assignments linked to P1 now have is_active=false in DB, and no assignment records were physically deleted | Cascade without data loss |

#### TC-D06: Activity log entry created on every CRUD operation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new purpose and verify activity_log has 'created' event for TemplatePurpose | Created logged |
| 2 | Update the purpose and verify activity_log has 'updated' event | Updated logged |
| 3 | Toggle status and verify activity_log has 'status_updated' event | Status change logged |
| 4 | Soft-delete the purpose and verify activity_log has 'deleted' event | Deleted logged |
| 5 | Restore the purpose and verify activity_log has 'restored' event | Restored logged |
| 6 | Force-delete the purpose and verify activity_log has 'permanently_deleted' event | Force deleted logged |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/purposes` | purposes.index | index() | tenant.template.purpose.viewAny |
| GET | `/purposes/create` | purposes.create | create() | tenant.template.purpose.create |
| POST | `/purposes` | purposes.store | store() | tenant.template.purpose.create |
| GET | `/purposes/{template_purpose}` | purposes.show | show() | tenant.template.purpose.view |
| GET | `/purposes/{template_purpose}/edit` | purposes.edit | edit() | tenant.template.purpose.update |
| PUT | `/purposes/{template_purpose}` | purposes.update | update() | tenant.template.purpose.update |
| DELETE | `/purposes/{template_purpose}` | purposes.destroy | destroy() | tenant.template.purpose.delete |
| GET | `/purposes/trash` | purposes.trashed | trashed() | tenant.template.purpose.restore |
| GET | `/purposes/{id}/restore` | purposes.restore | restore() | tenant.template.purpose.restore |
| DELETE | `/purposes/{id}/force-delete` | purposes.forceDelete | forceDelete() | tenant.template.purpose.forceDelete |
| POST | `/purposes/{id}/toggle-status` | purposes.toggleStatus | toggleStatus() | tenant.template.purpose.update |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | scope_type_id validation lacks `exists:sys_dropdown_table,id` rule | **Medium** | Foreign key is validated only as `required|integer`; no exists check for referential integrity |
| KI-02 | No DB-level UNIQUE KEY on name or description | **Low** | Uniqueness only enforced on `code` via UNIQUE KEY; duplicate names allowed |
| KI-03 | destroy() cascade deactivates assignments but does not delete them | **Info** | Design decision — assignments remain in DB with is_active=false to preserve audit trail |
| KI-04 | Toggle status uses tenant.template.purpose.update instead of dedicated status permission | **Low** | No dedicated `tenant.template.purpose.status` permission exists; status toggle reuses update permission |
| KI-05 | FormRequest authorize() returns true implicitly | **Medium** | No explicit Gate check in FormRequest — relies entirely on controller Gate for authorization |
| KI-06 | ~~No activity/audit logging for mutations~~ (removed — `activityLog()` IS called on all CRUD ops) | — | — |
| KI-07 | is_system guard only in controller, not in FormRequest | **Info** | Blocking system purpose edits is handled at controller level; FormRequest unique validation could still run |

---

## 13. Feature Summary Matrix

| Feature | Controller Method(s) | Key Models | Pagination |
|---------|---------------------|------------|------------|
| Purpose List (Index) | index() | TemplatePurpose | Default per page |
| Create Purpose | create(), store() | TemplatePurpose | None (form) |
| View Purpose | show() | TemplatePurpose | None |
| Edit Purpose | edit(), update() | TemplatePurpose | None (form) |
| Soft-Delete / Restore | destroy(), trashed(), restore() | TemplatePurpose | Default per page (trash) |
| Force Delete | forceDelete() | TemplatePurpose | None |
| Toggle Status | toggleStatus() | TemplatePurpose | None (AJAX) |
| **TC Count** | **Positive: 26 / Negative: 32 / Code Review: 23 / Dependency: 6** | **Total: 87** | |
