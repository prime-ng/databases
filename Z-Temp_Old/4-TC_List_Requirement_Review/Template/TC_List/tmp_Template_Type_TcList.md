# tmp_Template_Type_TcList

## Module: Template → Template Type → Template Type CRUD

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Template (TMP) |
| Tab Group | Template Dashboard (Tabbed Interface — tab: type_list) |
| Features | Template Type List, Create/Edit/View/Delete/Restore/Force-Delete, Toggle Status (AJAX), Activity Logging |
| URL(s) | `/template` (index → redirects to template.tabs with tab=type_list), `/template-types/create`, `/template-types/{templateType}/edit`, `/template-types/{templateType}`, `/template-types/trash/view`, `/template-types/{id}/restore`, `/template-types/{id}/force-delete`, `/template-types/{id}/toggle-status` |
| Controller | `TemplateTypeController` |
| Model(s) | `TemplateType` (table: `tmp_templates_type`) |
| Validation | `StoreTemplateTypeRequest` (4 rules), `UpdateTemplateTypeRequest` (same + ignore current ID) |
| Permission Gates | `tenant.template-types.viewAny`, `tenant.template-types.view`, `tenant.template-types.create`, `tenant.template-types.update`, `tenant.template-types.delete`, `tenant.template-types.restore`, `tenant.template-types.forceDelete` |
| Soft Deletes | Yes — TemplateType model uses `SoftDeletes` trait |
| Events | `activityLog()` on store, update, destroy, restore, forceDelete, toggleStatus |

---

## 2. Pre-conditions

- Required permissions: `tenant.template-types.viewAny`, `tenant.template-types.create`, `tenant.template-types.update`, `tenant.template-types.view`, `tenant.template-types.delete`, `tenant.template-types.restore`, `tenant.template-types.forceDelete`
- At least one Template Type record must exist in `tmp_templates_type` for list/edit/view tests
- For toggle-status tests: at least one active and one inactive template type record
- For trash/restore tests: at least one soft-deleted template type record
- For delete-with-templates tests: at least one template type with associated template records
- For unique-name tests: at least one existing template type record

---

## 3. Default Data Load

### 3.1 Template Type List Data

The `index()` method redirects to `template.tabs` with `tab=type_list`. The tab view loads:
- `templateTypes` — Paginated TemplateType records (10 per page) with search support on name
- Search/filter parameters: `search` — text search on name

### 3.2 No Additional Tabs

Template Type is a simple CRUD feature (not a multi-tab dashboard). The index redirects to the Template dashboard with `tab=type_list` selected.

---

## 4. BC-DB — Database Schema

### 4.1 `tmp_templates_type` — Template Type Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| name | VARCHAR(30) | NOT NULL | — | Unique template type name |
| description | VARCHAR(255) | YES | NULL | Description of template type |
| is_active | TINYINT(1) | YES | 0 | Active flag (default 0) |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uq_tmp_templates_type_name` (`name`)

---

## 5. BC-VAL — Validation Rules

### 5.1 StoreTemplateTypeRequest Validation

| Field | Rules | Error Message |
|-------|-------|---------------|
| name | required, string, max:30, unique:tmp_templates_type (whereNull deleted_at) | "The name has already been taken." (unique) |
| description | nullable, string, max:255 | — |
| is_active | boolean | — |

### 5.2 UpdateTemplateTypeRequest Validation

| Field | Rules | Error Message |
|-------|-------|---------------|
| name | required, string, max:30, unique:tmp_templates_type (ignore current ID, whereNull deleted_at) | "The name has already been taken." (unique) |
| description | nullable, string, max:255 | — |
| is_active | boolean | — |

**Authorization:** `authorize()` method returns `true` (no Gate check in FormRequest — defence delegated to controller)

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method(s) | Model Policy |
|----------------|---------------------|-------------|
| tenant.template-types.viewAny | index() | TemplateTypePolicy@viewAny |
| tenant.template-types.view | show() | TemplateTypePolicy@view |
| tenant.template-types.create | create(), store() | TemplateTypePolicy@create |
| tenant.template-types.update | edit(), update(), toggleStatus() | TemplateTypePolicy@update |
| tenant.template-types.delete | destroy() | TemplateTypePolicy@delete |
| tenant.template-types.restore | trashed(), restore() | TemplateTypePolicy@restore |
| tenant.template-types.forceDelete | forceDelete() | TemplateTypePolicy@forceDelete |

**index() Gate Behaviour:** index() redirects to `template.tabs` with `tab=type_list` — the tab view handles its own gate check.

**Policy status() Method:** Defined in TemplateTypePolicy as `$user->can('tenant.template-types.view')` — reuses the same permission as view.

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | Index Redirect | index() redirects to `template.tabs` with `tab=type_list` — no direct list view |
| BC-BIZ-02 | Gate in Controller (not FormRequest) | create() gates `tenant.template-types.create` in controller; StoreTemplateTypeRequest authorize() returns true |
| BC-BIZ-03 | Unique Name (Soft-Delete Aware) | Validation ignores soft-deleted records and the current record on update |
| BC-BIZ-04 | Delete Guard — Templates Exist | destroy() checks `$templateType->templates()->withTrashed()->exists()` before allowing delete |
| BC-BIZ-05 | Force Delete Guard — Templates Exist | forceDelete() also checks `$templateType->templates()->withTrashed()->exists()` before force delete |
| BC-BIZ-06 | Toggle Status via AJAX | toggleStatus() validates is_active as required|boolean via inline $request->validate(), returns JSON success/error response |
| BC-BIZ-07 | Activity Log All Operations | activityLog() called on store, update, destroy, restore, forceDelete, toggleStatus |
| BC-BIZ-08 | Soft Delete with Restore | destroy() calls `$templateType->delete()` (SoftDeletes); restore() calls `$templateType->restore()` |
| BC-BIZ-09 | Force Delete with SoftDeletes | forceDelete() uses `withTrashed()->findOrFail()` to bypass SoftDeletes and permanently delete |
| BC-BIZ-10 | Index Redirect to Tab | index() redirects to `template.tabs` with `tab=type_list` — no direct list view |
| BC-BIZ-11 | Gate in Controller for create() | create() gates `tenant.template-types.create` in controller (not in FormRequest) |
| BC-BIZ-12 | Delete Guard — Templates Check | destroy() checks `$templateType->templates()->withTrashed()->exists()` before allowing delete |
| BC-BIZ-13 | Force Delete Guard — Templates Check | forceDelete() also checks `$templateType->templates()->withTrashed()->exists()` before force delete |
| BC-BIZ-14 | Toggle Status Inline Validation | toggleStatus() uses `$request->validate(['is_active' => 'required|boolean'])` inline (not FormRequest) |
| BC-BIZ-15 | Soft Delete with Restore | destroy() calls `$templateType->delete()`; restore() calls `$templateType->restore()` |
| BC-BIZ-16 | Force Delete Bypasses SoftDeletes | forceDelete() uses `withTrashed()->findOrFail()` to permanently delete |
| BC-BIZ-17 | Activity Log All Operations | activityLog() called on store, update, destroy, restore, forceDelete, toggleStatus |
| BC-BIZ-18 | Default is_active = 0 | DDL default is 0 (inactive); create sets is_active based on request input |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_tmp_template_type_template | tmp_templates.template_type_id | tmp_templates_type.id | CASCADE (implied by model relationships) |
| fk_tmp_template_type_variable | tmp_templates_variables.template_type_id | tmp_templates_type.id | CASCADE (implied by model relationships) |

---

## 9. Test Case Summary

### 9.1 Template Type CRUD — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-TMPT-P01 | Template Type CRUD | Positive | Index redirects to template tabs with type_list tab | 3 |
| TC-TMPT-P02 | Template Type CRUD | Positive | Create template type — all required fields | 5 |
| TC-TMPT-P03 | Template Type CRUD | Positive | Create template type — null description | 4 |
| TC-TMPT-P04 | Template Type CRUD | Positive | Edit template type — update name and description | 5 |
| TC-TMPT-P05 | Template Type CRUD | Positive | Toggle status — active to inactive (AJAX) | 4 |
| TC-TMPT-P06 | Template Type CRUD | Positive | Toggle status — inactive to active (AJAX) | 4 |
| TC-TMPT-P07 | Template Type CRUD | Positive | Delete template type — no associated templates | 4 |
| TC-TMPT-P08 | Template Type CRUD | Positive | View trashed template types | 3 |
| TC-TMPT-P09 | Template Type CRUD | Positive | Restore template type from trash | 4 |
| TC-TMPT-P10 | Template Type CRUD | Positive | Force-delete template type | 4 |
| TC-TMPT-P11 | Template Type CRUD | Positive | Activity log created on template type store | 3 |
| TC-TMPT-P12 | Template Type CRUD | Positive | Activity log created on template type update | 3 |
| TC-TMPT-P13 | Template Type CRUD | Positive | Activity log created on template type destroy | 3 |
| TC-TMPT-P14 | Template Type CRUD | Positive | Activity log created on template type restore | 3 |
| TC-TMPT-P15 | Template Type CRUD | Positive | Activity log created on template type forceDelete | 3 |
| TC-TMPT-P16 | Template Type CRUD | Positive | Activity log created on template type toggleStatus | 3 |
| TC-TMPT-P17 | Template Type CRUD | Positive | Scope active() — filters is_active = true only | 3 |

### 9.2 Template Type CRUD — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-TMPT-N01 | Template Type CRUD | Negative | Create — missing name | 2 |
| TC-TMPT-N02 | Template Type CRUD | Negative | Create — name exceeds 30 chars | 2 |
| TC-TMPT-N03 | Template Type CRUD | Negative | Create — duplicate name (existing active) | 2 |
| TC-TMPT-N04 | Template Type CRUD | Negative | Create — missing required fields via API (raw POST) | 2 |
| TC-TMPT-N05 | Template Type CRUD | Negative | Delete — template type with associated templates | 3 |
| TC-TMPT-N06 | Template Type CRUD | Negative | ForceDelete — template type with associated templates | 3 |
| TC-TMPT-N07 | Template Type CRUD | Negative | Permission — index without tenant.template-types.viewAny | 2 |
| TC-TMPT-N08 | Template Type CRUD | Negative | Permission — create without tenant.template-types.create | 2 |
| TC-TMPT-N09 | Template Type CRUD | Negative | Permission — store without tenant.template-types.create | 2 |
| TC-TMPT-N10 | Template Type CRUD | Negative | Permission — edit without tenant.template-types.update | 2 |
| TC-TMPT-N11 | Template Type CRUD | Negative | Permission — update without tenant.template-types.update | 2 |
| TC-TMPT-N12 | Template Type CRUD | Negative | Permission — show without tenant.template-types.view | 2 |
| TC-TMPT-N13 | Template Type CRUD | Negative | Permission — destroy without tenant.template-types.delete | 2 |
| TC-TMPT-N14 | Template Type CRUD | Negative | Permission — trashed without tenant.template-types.restore | 2 |
| TC-TMPT-N15 | Template Type CRUD | Negative | Permission — restore without tenant.template-types.restore | 2 |
| TC-TMPT-N16 | Template Type CRUD | Negative | Permission — forceDelete without tenant.template-types.forceDelete | 2 |
| TC-TMPT-N17 | Template Type CRUD | Negative | Permission — toggleStatus without tenant.template-types.update | 2 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR01 | Code Review | Review | index() — redirect to template.tabs with tab=type_list | 3 |
| TC-CR02 | Code Review | Review | create() — Gate authorize + view return | 3 |
| TC-CR03 | Code Review | Review | store() — Gate + validated create + activityLog + flash | 5 |
| TC-CR04 | Code Review | Review | show() — Gate + findOrFail + view | 3 |
| TC-CR05 | Code Review | Review | edit() — Gate + findOrFail + view | 3 |
| TC-CR06 | Code Review | Review | update() — Gate + validated update + activityLog + flash | 5 |
| TC-CR07 | Code Review | Review | destroy() — Gate + templates check + delete + activityLog + flash | 5 |
| TC-CR08 | Code Review | Review | toggleStatus() — Gate + inline validation + AJAX JSON response | 5 |
| TC-CR09 | Code Review | Review | trashed() — Gate + onlyTrashed paginated + view | 3 |
| TC-CR10 | Code Review | Review | restore() — Gate + onlyTrashed findOrFail + restore + activityLog + flash | 4 |
| TC-CR11 | Code Review | Review | forceDelete() — Gate + templates check + withTrashed findOrFail + forceDelete + activityLog + flash | 5 |
| TC-CR12 | Code Review | Review | StoreTemplateTypeRequest — all field rules and unique logic | 4 |
| TC-CR13 | Code Review | Review | UpdateTemplateTypeRequest — unique ignore current ID | 3 |
| TC-CR14 | Code Review | Review | TemplateTypePolicy — all 8 method signatures (incl. status) | 4 |
| TC-CR15 | Code Review | Review | TemplateTypePolicy — status() reuses view permission | 2 |
| TC-CR16 | Code Review | Review | TemplateType Model — fillable, casts, scopes | 4 |
| TC-CR17 | Code Review | Review | TemplateType Model — relationships (templates, variables) | 3 |
| TC-CR18 | Code Review | Review | store() — activityLog call with 'created' event | 3 |
| TC-CR19 | Code Review | Review | update() — activityLog call with 'updated' event | 3 |
| TC-CR20 | Code Review | Review | destroy() — activityLog call with 'deleted' event | 3 |
| TC-CR21 | Code Review | Review | restore() — activityLog call with 'restored' event | 3 |
| TC-CR22 | Code Review | Review | forceDelete() — activityLog call with 'permanently_deleted' event | 3 |
| TC-CR23 | Code Review | Review | toggleStatus() — activityLog call with 'status_updated' event | 3 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-D01 | Dependency | Dependency | FK cascade — template type deleted/force-deleted cascades to templates | 3 |
| TC-D02 | Dependency | Dependency | Unique constraint — duplicate name rejected at DB level | 3 |
| TC-D03 | Dependency | Dependency | SoftDelete — deleted types excluded from unique name validation | 3 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Template Type CRUD

#### TC-TMPT-P01: Index redirects to template tabs with type_list tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template-types.viewAny` permission navigates to `/template` | Request reaches index() |
| 2 | Verify controller redirects to `template.tabs` route with `tab=type_list` parameter | Redirected to tabbed view |
| 3 | Verify the type_list tab is active and shows paginated TemplateType records | Type list tab visible |

#### TC-TMPT-P02: Create template type — all required fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template-types.create` permission clicks "Add Template Type" | Create form loads |
| 2 | Enter name="Email Template" | Name field populated |
| 3 | Enter description="Templates used for email notifications" | Description populated |
| 4 | Set is_active=true (checkbox checked) | Active |
| 5 | Click Submit | Redirected to template tabs with type_list tab |
| 6 | Verify success flash message appears and new type appears in type list | Template type created |

#### TC-TMPT-P03: Create template type — null description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter name="SMS Template" | Name populated |
| 3 | Leave description field blank | Description is null |
| 4 | Set is_active=true and submit | Created successfully |
| 5 | Verify DB: description is NULL for the record | Null stored |

#### TC-TMPT-P04: Edit template type — update name and description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template-types.update` permission clicks "Edit" on a template type | Edit form loads with pre-filled data |
| 2 | Change name to "Updated Email Template" | Name changed |
| 3 | Change description to "Updated description for email templates" | Description changed |
| 4 | Click Update | Redirected to template tabs with type_list tab |
| 5 | Verify success flash message appears and type list shows updated name and description | Changes reflected |

#### TC-TMPT-P05: Toggle status — active to inactive (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an active template type (is_active=true) in the list | Active type visible |
| 2 | Click status toggle to deactivate | AJAX call made to `/template-types/{id}/toggle-status` |
| 3 | Verify JSON response: `{"success": true, "is_active": false, "message": "..."}` | AJAX success |
| 4 | Verify DB: is_active = 0 for the type and activity log entry created | Deactivated |

#### TC-TMPT-P06: Toggle status — inactive to active (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an inactive template type (is_active=false) in the list | Inactive type visible |
| 2 | Click status toggle to activate | AJAX call made |
| 3 | Verify JSON response: `{"success": true, "is_active": true, "message": "..."}` | AJAX success |
| 4 | Verify DB: is_active = 1 for the type and activity log entry created | Activated |

#### TC-TMPT-P07: Delete template type — no associated templates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template-types.delete` permission clicks "Delete" on a template type with no associated templates | Confirmation prompt |
| 2 | Confirm deletion | Template type soft-deleted |
| 3 | Verify type no longer appears in active type list | Removed from active |
| 4 | Verify DB: deleted_at is not null and activity log entry created | Soft-deleted |

#### TC-TMPT-P08: View trashed template types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template-types.restore` permission navigates to `/template-types/trash/view` | Trash list loads |
| 2 | Verify paginated list of soft-deleted template types | Trashed types visible |
| 3 | Verify each trashed type shows Restore and Force Delete action buttons | Actions visible |

#### TC-TMPT-P09: Restore template type from trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template-types.restore` permission navigates to trash view | Trash list loads |
| 2 | Locate a soft-deleted template type | Type visible in trash |
| 3 | Click Restore | Type restored |
| 4 | Verify type appears in active list, deleted_at is NULL, and activity log entry created | Restored |

#### TC-TMPT-P10: Force-delete template type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template-types.forceDelete` permission navigates to trash view | Trash list loads |
| 2 | Locate a soft-deleted template type with no associated templates and click "Force Delete" | Confirmation prompt |
| 3 | Confirm permanent deletion | Type permanently deleted |
| 4 | Verify DB record no longer exists (including withTrashed) and activity log entry created | Permanently deleted |

#### TC-TMPT-P11: Activity log created on template type store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new template type via store() | Success |
| 2 | Verify `activityLog()` was called with the TemplateType model, action='Stored', and message='A new template type was created.' | Logged |
| 3 | Verify performed_by = authenticated user's name | Performer tracked |

#### TC-TMPT-P12: Activity log created on template type update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update a template type via update() | Success |
| 2 | Verify `activityLog()` called with action='Updated' and changes array | Logged |
| 3 | Verify changes contains old/new values for modified fields | Change tracking |

#### TC-TMPT-P13: Activity log created on template type destroy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a template type via destroy() | Success |
| 2 | Verify `activityLog()` called with action='Trashed' and message='Template type was deactivated and trashed.' | Logged |

#### TC-TMPT-P14: Activity log created on template type restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a trashed template type via restore() | Success |
| 2 | Verify `activityLog()` called with action='Restored' and message='Template type was restored.' | Logged |

#### TC-TMPT-P15: Activity log created on template type forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete a trashed template type via forceDelete() | Success |
| 2 | Verify `activityLog()` called with action='Deleted' and message='Template type was permanently deleted.' | Logged |

#### TC-TMPT-P16: Activity log created on template type toggleStatus

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle template type status via toggleStatus() | AJAX success |
| 2 | Verify `activityLog()` called with action='Toggled' and message='Template type status was updated.' | Logged |
| 3 | Verify performed_by = authenticated user's name | Performer tracked |

#### TC-TMPT-P17: Scope active() — filters is_active = true only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active type (is_active=true) and inactive type (is_active=false) | Both types exist in DB |
| 2 | Execute `TemplateType::active()->get()` | Returns collection containing only the active type |
| 3 | Verify the inactive type is excluded from the result set | Scope filters correctly |

### 10.2 Negative TC Steps — Template Type CRUD

#### TC-TMPT-N01: Create — missing name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without name field | Validation error |
| 2 | Verify error: "The name field is required." | Error shown |

#### TC-TMPT-N02: Create — name exceeds 30 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set name to a 31-character string (e.g. "ThisIsAVeryLongTemplateTypeNameExceeds") | Exceeds max |
| 2 | Submit | Validation error: "The name must not be greater than 30 characters." |

#### TC-TMPT-N03: Create — duplicate name (existing active)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template Type "Invoice" already exists (active) | Existing record |
| 2 | Submit create with name="Invoice" | Validation error: "The name has already been taken." |

#### TC-TMPT-N04: Create — missing required fields via API (raw POST)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `/template/type` with empty JSON body `{}` | Validation error |
| 2 | Verify error: "The name field is required." | Error returned |

#### TC-TMPT-N05: Delete — template type with associated templates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template type "Invoice" has 2 associated templates in `tmp_templates` | Templates exist |
| 2 | User with `tenant.template-types.delete` permission clicks "Delete" on this type | Confirmation prompt |
| 3 | Confirm deletion | Delete blocked — controller checks `$templateType->templates()->withTrashed()->exists()` and returns error flash message |

#### TC-TMPT-N06: ForceDelete — template type with associated templates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template type "Invoice" is soft-deleted and has 2 associated templates (withTrashed) | Trashed type with templates |
| 2 | User with `tenant.template-types.forceDelete` permission clicks "Force Delete" | Confirmation prompt |
| 3 | Confirm permanent deletion | Force delete blocked — controller checks `$templateType->templates()->withTrashed()->exists()` and returns error flash message |

#### TC-TMPT-N07: Permission — index without tenant.template-types.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template-types.viewAny` permission accesses `/template` | 403 Forbidden |

#### TC-TMPT-N08: Permission — create without tenant.template-types.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template-types.create` accesses `/template-types/create` | 403 Forbidden |

#### TC-TMPT-N09: Permission — store without tenant.template-types.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template-types.create` POSTs to `/template/type` | 403 Forbidden |

#### TC-TMPT-N10: Permission — edit without tenant.template-types.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template-types.update` accesses `/template-types/{id}/edit` | 403 Forbidden |

#### TC-TMPT-N11: Permission — update without tenant.template-types.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template-types.update` PUTs to `/template-types/{id}` | 403 Forbidden |

#### TC-TMPT-N12: Permission — show without tenant.template-types.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template-types.view` accesses `/template-types/{id}` | 403 Forbidden |

#### TC-TMPT-N13: Permission — destroy without tenant.template-types.delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template-types.delete` DELETEs `/template-types/{id}` | 403 Forbidden |

#### TC-TMPT-N14: Permission — trashed without tenant.template-types.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template-types.restore` accesses `/template-types/trash/view` | 403 Forbidden |

#### TC-TMPT-N15: Permission — restore without tenant.template-types.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template-types.restore` POSTs to `/template-types/{id}/restore` | 403 Forbidden |

#### TC-TMPT-N16: Permission — forceDelete without tenant.template-types.forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template-types.forceDelete` DELETEs `/template-types/{id}/force-delete` | 403 Forbidden |

#### TC-TMPT-N17: Permission — toggleStatus without tenant.template-types.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template-types.update` POSTs to `/template-types/{id}/toggle-status` | 403 Forbidden |

### 10.3 Code Review TC Steps

#### TC-CR01: index() — redirect to template.tabs with tab=type_list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review index() method signature | Returns redirect |
| 2 | Review `redirect()->route('template.tabs', ['tab' => 'type_list'])` | Redirect to tabbed view |
| 3 | Note: No Gate check in index() — redirects to tab view which handles its own authorization | Gate delegated |

#### TC-CR02: create() — Gate authorize + view return

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template-types.create')` at method start | Gate present |
| 2 | Review return view with no additional data | View returned |
| 3 | Note: Gate is in controller, NOT in StoreTemplateTypeRequest authorize() | Gate in controller |

#### TC-CR03: store() — Gate + validated create + activityLog + flash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template-types.create')` | Gate present |
| 2 | Review `TemplateType::create($request->validated())` | Creation via validated data |
| 3 | Review `activityLog($templateType, 'Stored', [...])` | Activity logged |
| 4 | Review `redirect()->route('template.tabs', ['tab' => 'type_list'])->with('success', flash('created.template_type'))` | Flash success |
| 5 | Review no try-catch wrapper — exception bubbles up | Exception handling |

#### TC-CR04: show() — Gate + findOrFail + view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template-types.view')` | Gate present |
| 2 | Review `TemplateType::findOrFail($id)` | Model binding |
| 3 | Review view return with template type data | View returned |

#### TC-CR05: edit() — Gate + findOrFail + view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template-types.update')` | Gate present |
| 2 | Review `TemplateType::findOrFail($id)` | Model binding |
| 3 | Review view return with template type data for form pre-fill | View returned |

#### TC-CR06: update() — Gate + validated update + activityLog + flash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template-types.update')` | Gate present |
| 2 | Review `$templateType->update($request->validated())` | Update via validated data |
| 3 | Review `activityLog($templateType, 'Updated', [...])` | Activity logged |
| 4 | Review `redirect()->route('template.tabs', ['tab' => 'type_list'])->with('success', flash('updated.template_type'))` | Flash success |
| 5 | Review no try-catch wrapper — exception bubbles up | Exception handling |

#### TC-CR07: destroy() — Gate + templates check + delete + activityLog + flash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template-types.delete')` | Gate present |
| 2 | Review `$templateType->templates()->withTrashed()->exists()` check before delete | Templates guard present |
| 3 | Review `$templateType->delete()` — triggers SoftDeletes | Soft delete |
| 4 | Review activityLog with action='Trashed' | Activity logged |
| 5 | Review flash message on success and error redirect | Flash messages |

#### TC-CR08: toggleStatus() — Gate + inline validation + AJAX JSON response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template-types.update')` — uses update permission, not dedicated status permission | Gate uses update |
| 2 | Review inline validation: `$request->validate(['is_active' => 'required|boolean'])` | Validation |
| 3 | Review `TemplateType::findOrFail($id)` | Model binding |
| 4 | Review activityLog call before save | Activity before save |
| 5 | Review JSON success/error response based on `$templateType->save()` | AJAX JSON response |

#### TC-CR08: trashed() — Gate + onlyTrashed paginated + view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template-types.restore')` | Gate present |
| 2 | Review `TemplateType::onlyTrashed()->paginate(10)` | Paginated trashed records |
| 3 | Review view return with trashed types data | View returned |

#### TC-CR09: restore() — Gate + onlyTrashed findOrFail + restore + activityLog + flash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template-types.restore')` | Gate present |
| 2 | Review `TemplateType::onlyTrashed()->findOrFail($id)` | Scoped to trashed only |
| 3 | Review `$templateType->restore()` | Restore called |
| 4 | Review activityLog and flash redirect | Activity + flash |

#### TC-CR10: forceDelete() — Gate + templates check + withTrashed findOrFail + forceDelete + activityLog + flash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template-types.forceDelete')` | Gate present |
| 2 | Review `$templateType->templates()->withTrashed()->exists()` check before force delete | Templates guard present |
| 3 | Review `TemplateType::withTrashed()->findOrFail($id)` | Bypasses soft-delete scope |
| 4 | Review `$templateType->forceDelete()` and activityLog | Permanent delete + log |
| 5 | Review flash message on success and error redirect | Flash messages |

#### TC-CR11: toggleStatus() — Gate + inline validation + AJAX JSON response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template-types.update')` | Gate present |
| 2 | Review inline validation: `$request->validate(['is_active' => 'required|boolean'])` | Validation |
| 3 | Review `TemplateType::findOrFail($id)` | Model binding |
| 4 | Review activityLog call before save | Activity before save |
| 5 | Review JSON success/error response based on `$templateType->save()` | AJAX JSON response |

#### TC-CR12: StoreTemplateTypeRequest — all field rules and unique logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review name: required|string|max:30|unique:tmp_templates_type (whereNull deleted_at) | Unique logic |
| 2 | Review description: nullable|string|max:255 | Nullable field |
| 3 | Review is_active: boolean (no required — defaults to false if missing) | Boolean field |
| 4 | Review authorize() returns true (no Gate in FormRequest) | No Gate |

#### TC-CR13: UpdateTemplateTypeRequest — unique ignore current ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review name: required|string|max:30|unique with ignore $templateType->id and whereNull deleted_at | Unique ignore logic |
| 2 | Review description: nullable|string|max:255 | Nullable field |
| 3 | Review is_active: boolean | Boolean field |

#### TC-CR14: TemplateTypePolicy — all 7 method signatures

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review viewAny(User) | Returns $user->can('tenant.template-types.viewAny') |
| 2 | Review view(User, TemplateType) | Returns $user->can('tenant.template-types.view') |
| 3 | Review create(User) | Returns $user->can('tenant.template-types.create') |
| 4 | Review update(User, TemplateType) | Returns $user->can('tenant.template-types.update') |
| 5 | Review delete(User, TemplateType) | Returns $user->can('tenant.template-types.delete') |
| 6 | Review restore(User, TemplateType) | Returns $user->can('tenant.template-types.restore') |
| 7 | Review forceDelete(User, TemplateType) | Returns $user->can('tenant.template-types.forceDelete') |

#### TC-CR15: TemplateTypePolicy — status() reuses view permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `status(User, TemplateType)` method | Returns `$user->can('tenant.template-types.view')` |
| 2 | Note: No dedicated `tenant.template-types.status` permission exists — status toggle uses update permission in controller | Permission reuse |

#### TC-CR16: TemplateType Model — fillable, casts, scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$fillable` array — name, description, is_active | 3 fillable fields |
| 2 | Review `$casts` — is_active→boolean | Casts configured |
| 3 | Review `SoftDeletes` trait is used | SoftDeletes present |
| 4 | Review `scopeActive()` — where is_active = true | Active scope |

#### TC-CR17: TemplateType Model — relationships (templates, variables)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `templates()` — hasMany Template::class | HasMany relationship |
| 2 | Review `variables()` — hasMany TemplateVariable::class | HasMany relationship |
| 3 | Note: Both relationships use foreign key `template_type_id` on their respective tables | FK convention |

#### TC-CR18: store() — activityLog call with 'created' event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate `activityLog($templateType, 'created', ['name' => $templateType->name])` after `TemplateType::create()` in store() | activityLog call present |
| 2 | Verify activityLog is called after successful creation, not before | Order correct |
| 3 | Verify properties array contains 'name' key with template type name | Properties correct |

#### TC-CR19: update() — activityLog call with 'updated' event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate `activityLog($templateType, 'updated', ['name' => $templateType->name])` after `$templateType->update()` in update() | activityLog call present |
| 2 | Verify activityLog is called after successful update | Order correct |
| 3 | Verify properties array contains 'name' key | Properties correct |

#### TC-CR20: destroy() — activityLog call with 'deleted' event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate `activityLog($templateType, 'deleted', ['name' => $templateType->name])` in destroy() | activityLog call present |
| 2 | Verify activityLog is called BEFORE `$templateType->delete()` (model still exists in DB for logging) | Order correct |
| 3 | Verify properties array contains 'name' key with template type name | Properties correct |

#### TC-CR21: restore() — activityLog call with 'restored' event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate `activityLog($templateType, 'restored', ['name' => $templateType->name])` after `$templateType->restore()` in restore() | activityLog call present |
| 2 | Verify activityLog is called after successful restore | Order correct |
| 3 | Verify properties array contains 'name' key | Properties correct |

#### TC-CR22: forceDelete() — activityLog call with 'permanently_deleted' event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate `activityLog($templateType, 'permanently_deleted', ['name' => $templateType->name])` after `$templateType->forceDelete()` in forceDelete() | activityLog call present |
| 2 | Verify activityLog is called after forceDelete (model object still exists in memory for logging) | Order correct |
| 3 | Verify properties array contains 'name' key | Properties correct |

#### TC-CR23: toggleStatus() — activityLog call with 'status_updated' event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate `activityLog($templateType, 'status_updated', ['name' => $templateType->name, 'is_active' => $templateType->is_active])` after `$templateType->update()` in toggleStatus() | activityLog call present |
| 2 | Verify activityLog is called before JSON response is returned | Order correct |
| 3 | Verify properties array contains 'name' and 'is_active' keys with correct values | Properties correct |

### 10.4 Dependency TC Steps

#### TC-D01: FK cascade — template type deleted cascades to templates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template type "Invoice" has 2 associated templates in `tmp_templates` (template_type_id = X) | Referenced templates exist |
| 2 | Soft-delete the template type (destroy) | Type soft-deleted, templates remain (no cascade on soft-delete) |
| 3 | Force-delete the template type (after ensuring no templates guard passes) | Type permanently deleted; verify templates behaviour depends on FK ON DELETE CASCADE definition |

#### TC-D02: Unique constraint — duplicate name rejected at DB level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template type "Invoice" exists with name="Invoice" | Existing record |
| 2 | Attempt to insert another record with name="Invoice" via raw DB query (bypassing validation) | DB constraint violation: Duplicate entry 'Invoice' for key 'uq_tmp_templates_type_name' |
| 3 | Verify application-level validation also catches this before DB | Validation error at app level |

#### TC-D03: SoftDelete — deleted types excluded from unique name validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template type "ArchivedType" is soft-deleted (deleted_at NOT NULL) | Trashed type |
| 2 | Create new template type with name="ArchivedType" | Unique validation ignores soft-deleted record |
| 3 | Verify type created successfully despite name matching soft-deleted record | Created |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/template` | template.index | index() | tenant.template-types.viewAny |
| GET | `/template-types/create` | template-types.create | create() | tenant.template-types.create |
| POST | `/template/type` | template-types.store | store() | tenant.template-types.create |
| GET | `/template-types/{templateType}` | template-types.show | show() | tenant.template-types.view |
| GET | `/template-types/{templateType}/edit` | template-types.edit | edit() | tenant.template-types.update |
| PUT | `/template-types/{templateType}` | template-types.update | update() | tenant.template-types.update |
| DELETE | `/template-types/{templateType}` | template-types.destroy | destroy() | tenant.template-types.delete |
| GET | `/template-types/trash/view` | template-types.trashed | trashed() | tenant.template-types.restore |
| GET | `/template-types/{id}/restore` | template-types.restore | restore() | tenant.template-types.restore |
| DELETE | `/template-types/{id}/force-delete` | template-types.forceDelete | forceDelete() | tenant.template-types.forceDelete |
| POST | `/template-types/{id}/toggle-status` | template-types.toggleStatus | toggleStatus() | tenant.template-types.update |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | index() redirects to tab view — no direct list page | **Info** | index() does not render a list; it redirects to template.tabs with tab=type_list |
| KI-02 | destroy() checks templates()->withTrashed()->exists() before delete | **Info** | Guard prevents deletion when templates exist; no cascade on soft-delete |
| KI-03 | forceDelete() also checks templates()->withTrashed()->exists() | **Info** | Same guard applies to force delete — prevents orphaned template records |
| KI-04 | toggleStatus() uses tenant.template-types.update instead of a dedicated status permission | **Low** | No dedicated `tenant.template-types.status` permission exists; status toggle reuses update permission |
| KI-05 | StoreTemplateTypeRequest authorize() returns true | **Medium** | No Gate check in FormRequest — defence-in-depth collapsed; relies solely on controller Gate |
| KI-06 | is_active has no `required` rule in FormRequest — defaults to false if missing | **Low** | Boolean cast handles missing field gracefully, but no explicit required rule |
| KI-07 | No DB-level FK constraint defined in DDL for template_type_id references | **Medium** | tmp_templates_type.id referenced by tmp_templates.template_type_id and tmp_templates_variables.template_type_id but no explicit FK in DDL shown |

---

## 13. Feature Summary Matrix

| Feature | Controller Method(s) | Key Models | Pagination |
|---------|---------------------|------------|------------|
| Template Type List (Tab) | index() (redirect) | TemplateType | 10 per page (via tab view) |
| Create Template Type | create(), store() | TemplateType | None (form) |
| View Template Type | show() | TemplateType | None |
| Edit Template Type | edit(), update() | TemplateType | None (form) |
| Soft-Delete / Restore | destroy(), trashed(), restore() | TemplateType | 10 per page (trash) |
| Force Delete | forceDelete() | TemplateType | None |
| Toggle Status | toggleStatus() | TemplateType | None (AJAX) |
| **TC Count** | **Positive: 17 / Negative: 17 / Code Review: 23 / Dependency: 3** | **Total: 60** | |
