# tmp_Template_Variable_TcList

## Module: Template → Template Variable → Template Variable CRUD

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Template (TMP) |
| Tab Group | Template Variable Management |
| Features | Template Variable List, Create/Edit/View/Delete/Restore/Force-Delete, Toggle Status, AJAX Database Browser (getDatabases, getTables, getColumns), Manual & Automated Variable Modes |
| URL(s) | `/template-variables`, `/template-variables/create`, `/template-variables/{template_variable}/edit`, `/template-variables/{template_variable}`, `/template-variables/trashed`, `/template-variables/{id}/restore`, `/template-variables/{id}/force-delete`, `/template-variables/{id}/toggle-status` |
| Controller | `Modules\Template\Http\Controllers\TemplateVariableController` |
| Model(s) | `TemplateVariable`, `TemplateType`, `Template` |
| Validation | `StoreTemplateVariableRequest` (5 rules + withValidator logic) |
| Permission Gates | `tenant.template.variable.viewAny`, `tenant.template.variable.view`, `tenant.template.variable.create`, `tenant.template.variable.update`, `tenant.template.variable.delete`, `tenant.template.variable.restore`, `tenant.template.variable.forceDelete` |
| Soft Deletes | Yes — TemplateVariable model uses `SoftDeletes` trait |
| Extra AJAX | `getDatabases()`, `getTables(Request)`, `getColumns(Request)` — cascading DB schema browser |
| Activity Log | Yes — `activityLog()` called on store (created), update (updated), destroy (deleted), toggleStatus (status_updated), restore (restored), forceDelete (permanently_deleted) |

---

## 2. Pre-conditions

- Required permissions: `tenant.template.variable.viewAny`, `tenant.template.variable.create`, `tenant.template.variable.update`, `tenant.template.variable.view`, `tenant.template.variable.delete`, `tenant.template.variable.restore`, `tenant.template.variable.forceDelete`
- At least one active Template Type must exist in `tmp_templates_type` table (referenced by `template_type_id`)
- For automated-mode tests: at least one non-system database must exist on the MySQL server (for SHOW DATABASES filtering)
- For search/filter tests: at least one template variable record with populated fields
- For toggle-status tests: at least one active and one inactive template variable record
- For trash/restore tests: at least one soft-deleted template variable record
- For unique-name tests: at least one template type with 2+ variables having different names

---

## 3. Default Data Load

### 3.1 Variable List via Tab View

The `index()` method redirects to `route('template.tabs', ['tab' => 'variable_list'])`. The actual list is rendered by `TemplateController::templateVariablesQuery()` which returns:
- `variables` — Paginated TemplateVariable records with `type` relation loaded, filterable by type_id

### 3.2 Create Form Data

The `create()` method returns:
- `templateTypes` — Active template types from TemplateType::active()->get()
- `databases` — Results from `getDatabases()` helper: `SHOW DATABASES` filtered to exclude system DBs (information_schema, mysql, performance_schema, sys)
- Form view for creating a new template variable

### 3.3 Edit Form Data

The `edit()` method returns:
- The existing TemplateVariable record for editing
- `templateTypes` — Active template types
- `databases` — Available databases (for re-selection)
- Pre-selected table and field data from existing record

### 3.4 AJAX Data

The `getDatabases()` method returns:
- JSON array of database names (filtered, non-system DBs)

The `getTables(Request)` method returns:
- JSON array of table names from the selected database (`SHOW TABLES FROM {db_name}`)

The `getColumns(Request)` method returns:
- JSON array of column names from the selected table (`SHOW COLUMNS FROM {db_name}.{table_name}`)

---

## 4. BC-DB — Database Schema

### 4.1 `tmp_template_variables` — Primary Template Variable Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| template_type_id | INT UNSIGNED | NOT NULL | — | FK → tmp_templates_type(id) ON DELETE CASCADE |
| name | VARCHAR(50) | NOT NULL | — | Variable name (lowercase, underscore) |
| description | VARCHAR(255) | YES | NULL | Variable description |
| db_name | VARCHAR(60) | YES | NULL | Database name (automated mode) |
| table_name | VARCHAR(60) | YES | NULL | Table name (automated mode) |
| field_name | VARCHAR(60) | YES | NULL | Field/column name (automated mode) |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uq_tmp_tv_type_name` (`template_type_id`, `name`)
- KEY `idx_tmp_tv_type` (`template_type_id`)

**Foreign Keys:**
- `fk_tmp_tv_type` — FOREIGN KEY (`template_type_id`) REFERENCES `tmp_templates_type`(`id`) ON DELETE CASCADE

### 4.2 `tmp_templates_variables_jnt` — Junction Table (Template ↔ TemplateVariable)

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| template_id | INT UNSIGNED | NOT NULL | — | FK → tmp_templates(id) ON DELETE CASCADE |
| template_variable_id | INT UNSIGNED | NOT NULL | — | FK → tmp_template_variables(id) ON DELETE CASCADE |
| display_order | INT | YES | NULL | Display ordering |
| default_value | VARCHAR(255) | YES | NULL | Default value for this template |
| is_active | TINYINT(1) | YES | 1 | Active flag |

---

## 5. BC-VAL — Validation Rules

### 5.1 StoreTemplateVariableRequest Validation

| Field | Rules | Error Message |
|-------|-------|---------------|
| template_type_id | required, integer, exists:tmp_templates_type,id | "The template type id field is required." / "The selected template type id is invalid." |
| name | required, string, max:50, regex:/^[a-z0-9_]+$/, unique:tmp_template_variables,name (ignore $templateVariable->id on update, additional where:template_type_id) | "The name field is required." / "The name must not be greater than 50 characters." / "The name format is invalid." / "The name has already been taken." |
| description | nullable, string, max:255 | — |
| db_name | nullable, string, max:60 | — |
| table_name | nullable, string, max:60 | — |
| field_name | nullable, string, max:60 | — |
| is_active | required, boolean | "The is active field must be true or false." |

**withValidator Logic:** If `table_name` is provided without `field_name`, OR `field_name` is provided without `table_name`, a validation error is added: "Both Database Table and Field Name must be specified together."

**Unique Rule On Update:** Uses `Rule::unique('tmp_template_variables', 'name')->ignore($templateVariable->id)->where('template_type_id', $this->template_type_id)` to scope uniqueness within the same template type.

**Authorization:** `authorize()` method returns `true` (no Gate check in FormRequest — defence delegated to controller).

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method(s) | Model Policy |
|----------------|---------------------|-------------|
| tenant.template.variable.viewAny | index() | TemplateVariablePolicy@viewAny |
| tenant.template.variable.view | show() | TemplateVariablePolicy@view |
| tenant.template.variable.create | create(), store() | TemplateVariablePolicy@create |
| tenant.template.variable.update | edit(), update(), toggleStatus() | TemplateVariablePolicy@update |
| tenant.template.variable.delete | destroy() | TemplateVariablePolicy@delete |
| tenant.template.variable.restore | trashed(), restore() | TemplateVariablePolicy@restore |
| tenant.template.variable.forceDelete | forceDelete() | TemplateVariablePolicy@forceDelete |

**index() Gate Behaviour:** `index()` redirects to `route('template.tabs')` — the Gate check is bypassed. The actual list view is rendered by `TemplateController::templateVariablesQuery()` which runs under `tabView()` authorization.

**toggleStatus() Gate:** Uses `Gate::authorize('tenant.template.variable.update')` — reuses update permission for status toggling.

**Blade @can directives (expected in views):**
- `@can('tenant.template.variable.viewAny')` — List access
- `@can('tenant.template.variable.create')` — Create button
- `@can('tenant.template.variable.update')` — Edit and Toggle Status actions
- `@can('tenant.template.variable.view')` — View action button
- `@can('tenant.template.variable.delete')` — Delete action button

**Policy Methods (TemplateVariablePolicy):**
- viewAny(User) → `$user->can('tenant.template.variable.viewAny')`
- view(User, TemplateVariable) → `$user->can('tenant.template.variable.view')`
- create(User) → `$user->can('tenant.template.variable.create')`
- update(User, TemplateVariable) → `$user->can('tenant.template.variable.update')`
- delete(User, TemplateVariable) → `$user->can('tenant.template.variable.delete')`
- restore(User, TemplateVariable) → `$user->can('tenant.template.variable.restore')`
- forceDelete(User, TemplateVariable) → `$user->can('tenant.template.variable.forceDelete')`

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | Paginated List View | index() returns paginated TemplateVariable list with `type` relation eager-loaded |
| BC-BIZ-02 | Create Form Loads Active Types + DBs | create() loads `TemplateType::active()->get()` for dropdown and `getDatabases()` for cascading schema browser |
| BC-BIZ-03 | Automated Mode (Cascading Schema Browser) | getDatabases() returns filtered non-system DBs; getTables(db) returns tables; getColumns(table) returns columns — used for automated variable creation |
| BC-BIZ-04 | Manual Mode | User manually enters name and description without selecting db/table/field |
| BC-BIZ-05 | Table-Field Pair Validation | withValidator in form request enforces: if table_name set but field_name missing (or vice versa), both must be provided together |
| BC-BIZ-06 | Lowercase Underscore Name Format | name field validated via `regex:/^[a-z0-9_]+$/` — only lowercase letters, digits, and underscores allowed |
| BC-BIZ-07 | Unique Name Per Template Type | Unique validation scoped to `template_type_id` — same name can exist across different types but not within the same type |
| BC-BIZ-08 | Soft Delete | destroy() calls `$templateVariable->delete()` which sets deleted_at — no manual is_active toggle (cleaner than vendor pattern) |
| BC-BIZ-09 | Restore | restore() calls `onlyTrashed()->findOrFail($id)`, then `$templateVariable->restore()` |
| BC-BIZ-10 | Force Delete | forceDelete() uses `withTrashed()->findOrFail($id)` to bypass SoftDeletes and permanently delete |
| BC-BIZ-11 | Toggle Status via AJAX | toggleStatus() validates is_active as required|boolean, finds the model, updates and saves, returns JSON success/error response |
| BC-BIZ-12 | FK Cascade Delete from Template Type | fk_tmp_tv_type with ON DELETE CASCADE — deleting a template type automatically removes all its variables |
| BC-BIZ-13 | Junction Table Cascade | Junction table `tmp_templates_variables_jnt` has FK CASCADE on both sides — deleting a variable removes junction rows |
| BC-BIZ-14 | Active Scope | Model defines `scopeActive()` — filters `is_active = true` only |
| BC-BIZ-15 | Activity Log All Operations | activityLog() called on store (created), update (updated), destroy (deleted), toggleStatus (status_updated), restore (restored), forceDelete (permanently_deleted) — tracks who performed each action |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_tmp_tv_type | tmp_template_variables.template_type_id | tmp_templates_type.id | CASCADE |
| fk_tmp_jnt_template | tmp_templates_variables_jnt.template_id | tmp_templates.id | CASCADE |
| fk_tmp_jnt_variable | tmp_templates_variables_jnt.template_variable_id | tmp_template_variables.id | CASCADE |

---

## 9. Test Case Summary

### 9.1 Template Variable CRUD — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-TMPV-P01 | Template Variable CRUD | Positive | Template variable list loads with type relation | 4 |
| TC-TMPV-P02 | Template Variable CRUD | Positive | Create template variable — manual mode (name + description only) | 6 |
| TC-TMPV-P03 | Template Variable CRUD | Positive | Create template variable — automated mode (with db_name, table_name, field_name) | 7 |
| TC-TMPV-P04 | Template Variable CRUD | Positive | Edit template variable — update name and description | 5 |
| TC-TMPV-P05 | Template Variable CRUD | Positive | Edit template variable — switch from manual to automated mode | 5 |
| TC-TMPV-P06 | Template Variable CRUD | Positive | Toggle status — active to inactive via AJAX | 4 |
| TC-TMPV-P07 | Template Variable CRUD | Positive | Toggle status — inactive to active via AJAX | 4 |
| TC-TMPV-P08 | Template Variable CRUD | Positive | Soft-delete template variable | 4 |
| TC-TMPV-P09 | Template Variable CRUD | Positive | View trashed template variables list | 3 |
| TC-TMPV-P10 | Template Variable CRUD | Positive | Restore template variable from trash | 4 |
| TC-TMPV-P11 | Template Variable CRUD | Positive | Force-delete template variable | 4 |
| TC-TMPV-P12 | Template Variable CRUD | Positive | AJAX getDatabases — returns filtered database list | 3 |
| TC-TMPV-P13 | Template Variable CRUD | Positive | AJAX getTables — returns tables for selected database | 3 |
| TC-TMPV-P14 | Template Variable CRUD | Positive | AJAX getColumns — returns columns for selected table | 3 |
| TC-TMPV-P15 | Template Variable CRUD | Positive | Show template variable detail | 3 |
| TC-TMPV-P16 | Template Variable CRUD | Positive | Same variable name allowed across different template types | 4 |
| TC-TMPV-P17 | Template Variable CRUD | Positive | Activity log created on variable store | 3 |
| TC-TMPV-P18 | Template Variable CRUD | Positive | Activity log created on variable update | 3 |
| TC-TMPV-P19 | Template Variable CRUD | Positive | Activity log created on variable soft-delete | 2 |
| TC-TMPV-P20 | Template Variable CRUD | Positive | Activity log created on variable restore | 2 |
| TC-TMPV-P21 | Template Variable CRUD | Positive | Activity log created on variable force-delete | 2 |
| TC-TMPV-P22 | Template Variable CRUD | Positive | Activity log created on variable toggle-status | 3 |

### 9.2 Template Variable CRUD — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-TMPV-N01 | Template Variable CRUD | Negative | Create — missing template_type_id | 2 |
| TC-TMPV-N02 | Template Variable CRUD | Negative | Create — invalid (non-existent) template_type_id | 2 |
| TC-TMPV-N03 | Template Variable CRUD | Negative | Create — missing name | 2 |
| TC-TMPV-N04 | Template Variable CRUD | Negative | Create — name contains uppercase letters | 2 |
| TC-TMPV-N05 | Template Variable CRUD | Negative | Create — name contains hyphens | 2 |
| TC-TMPV-N06 | Template Variable CRUD | Negative | Create — name contains spaces | 2 |
| TC-TMPV-N07 | Template Variable CRUD | Negative | Create — duplicate name within same template type | 2 |
| TC-TMPV-N08 | Template Variable CRUD | Negative | Create — name exceeds 50 characters | 2 |
| TC-TMPV-N09 | Template Variable CRUD | Negative | Create — table_name provided without field_name | 2 |
| TC-TMPV-N10 | Template Variable CRUD | Negative | Create — field_name provided without table_name | 2 |
| TC-TMPV-N11 | Template Variable CRUD | Negative | Update — duplicate name within same template type (different variable) | 3 |
| TC-TMPV-N12 | Template Variable CRUD | Negative | Update — name changed to uppercase/invalid format | 2 |
| TC-TMPV-N13 | Template Variable CRUD | Negative | Toggle status — missing is_active parameter | 2 |
| TC-TMPV-N14 | Template Variable CRUD | Negative | Toggle status — non-boolean is_active value | 2 |
| TC-TMPV-N15 | Template Variable CRUD | Negative | Toggle status — non-existent variable ID | 2 |
| TC-TMPV-N16 | Template Variable CRUD | Negative | Force delete — non-existent variable ID | 2 |
| TC-TMPV-N17 | Template Variable CRUD | Negative | Restore — non-existent variable ID | 2 |
| TC-TMPV-N18 | Template Variable CRUD | Negative | Permission — index without tenant.template.variable.viewAny | 2 |
| TC-TMPV-N19 | Template Variable CRUD | Negative | Permission — create without tenant.template.variable.create | 2 |
| TC-TMPV-N20 | Template Variable CRUD | Negative | Permission — store without tenant.template.variable.create | 2 |
| TC-TMPV-N21 | Template Variable CRUD | Negative | Permission — edit without tenant.template.variable.update | 2 |
| TC-TMPV-N22 | Template Variable CRUD | Negative | Permission — update without tenant.template.variable.update | 2 |
| TC-TMPV-N23 | Template Variable CRUD | Negative | Permission — show without tenant.template.variable.view | 2 |
| TC-TMPV-N24 | Template Variable CRUD | Negative | Permission — destroy without tenant.template.variable.delete | 2 |
| TC-TMPV-N25 | Template Variable CRUD | Negative | Permission — trashed without tenant.template.variable.restore | 2 |
| TC-TMPV-N26 | Template Variable CRUD | Negative | Permission — restore without tenant.template.variable.restore | 2 |
| TC-TMPV-N27 | Template Variable CRUD | Negative | Permission — forceDelete without tenant.template.variable.forceDelete | 2 |
| TC-TMPV-N28 | Template Variable CRUD | Negative | Permission — toggleStatus without tenant.template.variable.update | 2 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR-TMPV01 | Code Review | Review | index() — authorization + paginated list with type relation | 4 |
| TC-CR-TMPV02 | Code Review | Review | create() — active types, getDatabases() call, form view | 4 |
| TC-CR-TMPV03 | Code Review | Review | store() — Gate authorize + FormRequest + redirect + flash | 4 |
| TC-CR-TMPV04 | Code Review | Review | show() — Gate authorize + findOrFail + view | 3 |
| TC-CR-TMPV05 | Code Review | Review | edit() — Gate authorize + findOrFail + load types + databases | 4 |
| TC-CR-TMPV06 | Code Review | Review | update() — Gate authorize + findOrFail + FormRequest + redirect | 4 |
| TC-CR-TMPV07 | Code Review | Review | destroy() — Gate authorize + findOrFail + delete + flash | 4 |
| TC-CR-TMPV08 | Code Review | Review | toggleStatus() — Gate authorize + validate + findOrFail + save + JSON | 5 |
| TC-CR-TMPV09 | Code Review | Review | trashed() — Gate authorize + onlyTrashed()->paginate() | 3 |
| TC-CR-TMPV10 | Code Review | Review | restore() — Gate authorize + onlyTrashed()->findOrFail + restore + flash | 4 |
| TC-CR-TMPV11 | Code Review | Review | forceDelete() — Gate authorize + withTrashed()->findOrFail + forceDelete + flash | 3 |
| TC-CR-TMPV12 | Code Review | Review | getDatabases() — SHOW DATABASES filter + JSON response | 3 |
| TC-CR-TMPV13 | Code Review | Review | getTables(Request) — SHOW TABLES FROM + JSON response | 3 |
| TC-CR-TMPV14 | Code Review | Review | getColumns(Request) — SHOW COLUMNS FROM + JSON response | 3 |
| TC-CR-TMPV15 | Code Review | Review | StoreTemplateVariableRequest — all field rules + withValidator logic | 6 |
| TC-CR-TMPV16 | Code Review | Review | StoreTemplateVariableRequest — authorize() returns true (no Gate) | 2 |
| TC-CR-TMPV17 | Code Review | Review | StoreTemplateVariableRequest — prepareForValidation is_active boolean cast | 3 |
| TC-CR-TMPV18 | Code Review | Review | TemplateVariablePolicy — all 7 method signatures | 4 |
| TC-CR-TMPV19 | Code Review | Review | TemplateVariable Model — fillable, casts, scopes | 4 |
| TC-CR-TMPV20 | Code Review | Review | TemplateVariable Model — relationships (type, templates) | 4 |
| TC-CR-TMPV21 | Code Review | Review | TemplateVariable Model — active() scope implementation | 2 |
| TC-CR-TMPV22 | Code Review | Review | store() — activityLog call with created event | 3 |
| TC-CR-TMPV23 | Code Review | Review | update() — activityLog call with updated event | 3 |
| TC-CR-TMPV24 | Code Review | Review | destroy() — activityLog call with deleted event | 3 |
| TC-CR-TMPV25 | Code Review | Review | restore() — activityLog call with restored event | 3 |
| TC-CR-TMPV26 | Code Review | Review | forceDelete() — activityLog call with permanently_deleted event | 3 |
| TC-CR-TMPV27 | Code Review | Review | toggleStatus() — activityLog call with status_updated event | 3 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-D-TMPV01 | Dependency | Dependency | FK cascade — delete template type cascades to variables | 3 |
| TC-D-TMPV02 | Dependency | Dependency | FK cascade — delete variable cascades to junction table | 3 |
| TC-D-TMPV03 | Dependency | Dependency | FK cascade — delete template cascades to junction table | 3 |
| TC-D-TMPV04 | Dependency | Dependency | Unique constraint — duplicate name within same template_type_id blocked at DB level | 3 |
| TC-D-TMPV05 | Dependency | Dependency | Same variable name allowed across different template types (no cross-type unique) | 3 |
| TC-D-TMPV06 | Dependency | Dependency | Soft delete — deleted_at set on destroy, null on restore | 4 |
| TC-D-TMPV07 | Dependency | Dependency | Junction pivot — display_order, default_value, is_active stored in pivot | 3 |
| TC-D-TMPV08 | Dependency | Dependency | Activity log entry created on every CRUD operation | 6 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Template Variable CRUD

#### TC-TMPV-P01: Template variable list loads with type relation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.variable.viewAny` permission navigates to `/template-variables` | List view loads |
| 2 | Verify paginated TemplateVariable records are displayed | Records visible |
| 3 | Verify each record shows the related template type name (via `type` relation) | Type relation loaded |
| 4 | Verify action buttons: View, Edit, Toggle Status, Delete are present | All actions visible |

#### TC-TMPV-P02: Create template variable — manual mode (name + description only)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.variable.create` permission clicks "Add Variable" | Create form loads |
| 2 | Verify template types dropdown is populated with active types | Types loaded |
| 3 | Verify databases dropdown is populated via AJAX getDatabases() | Databases loaded |
| 4 | Select a template type, enter name="user_name", description="User display name" | Fields populated |
| 5 | Leave db_name, table_name, field_name blank (manual mode) | Automated fields empty |
| 6 | Click Submit | Redirected to index |
| 7 | Verify success flash message appears and new variable appears in list with correct type | Variable created |

#### TC-TMPV-P03: Create template variable — automated mode (with all 3 DB fields)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select a template type | Type selected |
| 3 | Select a database from AJAX-populated dropdown | db_name set |
| 4 | Select a table from cascading AJAX getTables() dropdown | table_name set |
| 5 | Select a field from cascading AJAX getColumns() dropdown | field_name set |
| 6 | Enter name="email_field", description="User email from DB" | Fields populated |
| 7 | Submit form | Success |
| 8 | Verify DB record has db_name, table_name, field_name populated | Automated mode stored |

#### TC-TMPV-P04: Edit template variable — update name and description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.variable.update` permission clicks "Edit" on a variable | Edit form loads with pre-filled data |
| 2 | Change name to "updated_name", description to "Updated description" | Fields changed |
| 3 | Click Update | Redirected to index |
| 4 | Verify success flash message appears | Success message |
| 5 | Verify list shows updated name and description | Changes reflected |

#### TC-TMPV-P05: Edit template variable — switch from manual to automated mode

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate a manual-mode variable (db_name, table_name, field_name all null) | Manual variable exists |
| 2 | Edit the variable and select a database, table, and field from AJAX dropdowns | Automated fields set |
| 3 | Click Update | Redirected |
| 4 | Verify flash message | Success |
| 5 | Verify DB record now has db_name, table_name, field_name populated with selected values | Mode switched |

#### TC-TMPV-P06: Toggle status — active to inactive via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an active variable (is_active=true) in the list | Active variable visible |
| 2 | Click status toggle to deactivate | AJAX call made |
| 3 | Verify JSON response: `{"success": true, "is_active": false, "message": "..."}` | AJAX success |
| 4 | Verify DB: is_active = 0 for the variable | Deactivated |

#### TC-TMPV-P07: Toggle status — inactive to active via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an inactive variable (is_active=false) in the list | Inactive variable visible |
| 2 | Click status toggle to activate | AJAX call made |
| 3 | Verify JSON response: `{"success": true, "is_active": true, "message": "..."}` | AJAX success |
| 4 | Verify DB: is_active = 1 for the variable | Activated |

#### TC-TMPV-P08: Soft-delete template variable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.variable.delete` permission clicks "Delete" on a variable | Confirmation prompt |
| 2 | Confirm deletion | Variable soft-deleted |
| 3 | Verify variable no longer appears in active list | Removed from active |
| 4 | Verify DB: deleted_at is not null | Soft-deleted |

#### TC-TMPV-P09: View trashed template variables list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.variable.restore` permission navigates to `/template-variables/trashed` | Trash list loads |
| 2 | Verify only soft-deleted variables appear in the list | Trashed records shown |
| 3 | Verify restore and force-delete action buttons are present for each trashed record | Actions visible |

#### TC-TMPV-P10: Restore template variable from trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.variable.restore` permission views trash list | Trash list loads |
| 2 | Locate a soft-deleted variable and click "Restore" | Variable restored |
| 3 | Verify success flash message | Success |
| 4 | Verify variable appears in active list and deleted_at is NULL | Restored |

#### TC-TMPV-P11: Force-delete template variable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.variable.forceDelete` permission navigates to trash view | Trash list loads |
| 2 | Locate a soft-deleted variable and click "Force Delete" | Confirmation prompt |
| 3 | Confirm permanent deletion | Variable permanently deleted |
| 4 | Verify DB record no longer exists (including withTrashed) | Permanently deleted |

#### TC-TMPV-P12: AJAX getDatabases — returns filtered database list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On create/edit page, click or load the database dropdown | AJAX GET request to getDatabases() |
| 2 | Verify JSON response is an array of non-system database names | Databases returned |
| 3 | Verify system databases (information_schema, mysql, performance_schema, sys) are excluded | System DBs filtered |

#### TC-TMPV-P13: AJAX getTables — returns tables for selected database

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a database from the database dropdown | AJAX GET request to getTables() with db_name parameter |
| 2 | Verify JSON response is an array of table names from the selected database | Tables returned |
| 3 | Verify the tables dropdown is populated with these options | Dropdown populated |

#### TC-TMPV-P14: AJAX getColumns — returns columns for selected table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a table from the table dropdown | AJAX GET request to getColumns() with db_name and table_name parameters |
| 2 | Verify JSON response is an array of column/field names from the selected table | Columns returned |
| 3 | Verify the fields dropdown is populated with these options | Dropdown populated |

#### TC-TMPV-P15: Show template variable detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.variable.view` permission clicks "View" on a variable row | Show view loads |
| 2 | Verify all variable fields are displayed: name, description, type, DB fields, status | All fields visible |
| 3 | Verify template type name is shown from the `type` relation | Type name displayed |

#### TC-TMPV-P16: Same variable name allowed across different template types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create variable with name="field_name" under TemplateType A | Created successfully |
| 2 | Create variable with same name="field_name" under TemplateType B | Created successfully (no unique conflict) |
| 3 | Verify both records exist with same name but different template_type_id | Cross-type names allowed |

#### TC-TMPV-P17: Activity log created on variable store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new template variable via store() | Variable created successfully |
| 2 | Verify `activityLog()` was called with the TemplateVariable model, action='created', and `name` property | Logged |
| 3 | Verify `performed_by` = authenticated user's name | Performer tracked |

#### TC-TMPV-P18: Activity log created on variable update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update an existing template variable via update() | Variable updated successfully |
| 2 | Verify `activityLog()` was called with the TemplateVariable model, action='updated', and `name` property | Logged |
| 3 | Verify `performed_by` = authenticated user's name | Performer tracked |

#### TC-TMPV-P19: Activity log created on variable soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a template variable via destroy() | Variable soft-deleted |
| 2 | Verify `activityLog()` was called with the TemplateVariable model, action='deleted', and `name` property, with `performed_by` = authenticated user's name | Logged with performer |

#### TC-TMPV-P20: Activity log created on variable restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a soft-deleted template variable via restore() | Variable restored |
| 2 | Verify `activityLog()` was called with the TemplateVariable model, action='restored', and `name` property, with `performed_by` = authenticated user's name | Logged with performer |

#### TC-TMPV-P21: Activity log created on variable force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete a template variable via forceDelete() | Variable permanently deleted |
| 2 | Verify `activityLog()` was called with the TemplateVariable model, action='permanently_deleted', and `name` property, with `performed_by` = authenticated user's name | Logged with performer |

#### TC-TMPV-P22: Activity log created on variable toggle-status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle a template variable's status via toggleStatus() | JSON success response |
| 2 | Verify `activityLog()` was called with the TemplateVariable model, action='status_updated', and `name` property | Logged |
| 3 | Verify `performed_by` = authenticated user's name | Performer tracked |

### 10.2 Negative TC Steps — Template Variable CRUD

#### TC-TMPV-N01: Create — missing template_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without selecting a template type | Validation error |
| 2 | Verify error: "The template type id field is required." | Error shown |

#### TC-TMPV-N02: Create — invalid (non-existent) template_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set template_type_id = 99999 (non-existent) | Invalid type |
| 2 | Submit | Validation error: "The selected template type id is invalid." |

#### TC-TMPV-N03: Create — missing name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without name | Validation error |
| 2 | Verify error: "The name field is required." | Error shown |

#### TC-TMPV-N04: Create — name contains uppercase letters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter name = "UserName" (uppercase) | Invalid format |
| 2 | Submit | Validation error: "The name format is invalid." (regex /^[a-z0-9_]+$/) |

#### TC-TMPV-N05: Create — name contains hyphens

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter name = "user-name" (hyphen) | Invalid format |
| 2 | Submit | Validation error: "The name format is invalid." |

#### TC-TMPV-N06: Create — name contains spaces

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter name = "user name" (space) | Invalid format |
| 2 | Submit | Validation error: "The name format is invalid." |

#### TC-TMPV-N07: Create — duplicate name within same template type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Variable "email" already exists under TemplateType A | Existing record |
| 2 | Submit create with name="email" under same TemplateType A | Validation error: "The name has already been taken." |

#### TC-TMPV-N08: Create — name exceeds 50 characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set name to a 51-character lowercase_underscore string | Exceeds max |
| 2 | Submit | Validation error: "The name must not be greater than 50 characters." |

#### TC-TMPV-N09: Create — table_name provided without field_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter table_name="users" but leave field_name blank | Partial automated data |
| 2 | Submit | withValidator error: "Both Database Table and Field Name must be specified together." |

#### TC-TMPV-N10: Create — field_name provided without table_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter field_name="email" but leave table_name blank | Partial automated data |
| 2 | Submit | withValidator error: "Both Database Table and Field Name must be specified together." |

#### TC-TMPV-N11: Update — duplicate name within same template type (different variable)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VariableA has name="field1", VariableB has name="field2" under same TemplateType | Two variables exist |
| 2 | Edit VariableB and change name to "field1" | Duplicate attempt |
| 3 | Submit | Validation error: "The name has already been taken." |

#### TC-TMPV-N12: Update — name changed to uppercase/invalid format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit variable and change name to "INVALID_NAME" (uppercase) | Invalid format |
| 2 | Submit | Validation error: "The name format is invalid." |

#### TC-TMPV-N13: Toggle status — missing is_active parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/template-variables/{id}/toggle-status` without is_active in request body | Validation error |
| 2 | Verify error: "The is active field is required." | Error returned |

#### TC-TMPV-N14: Toggle status — non-boolean is_active value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/template-variables/{id}/toggle-status` with is_active="not-a-boolean" | Validation error |
| 2 | Verify error: "The is active field must be true or false." | Error returned |

#### TC-TMPV-N15: Toggle status — non-existent variable ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/template-variables/99999/toggle-status` with is_active=true | Variable 99999 doesn't exist |
| 2 | Verify 404 Not Found from findOrFail | 404 error |

#### TC-TMPV-N16: Force delete — non-existent variable ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/template-variables/99999/force-delete` | Variable 99999 doesn't exist |
| 2 | Verify 404 Not Found from withTrashed()->findOrFail | 404 error |

#### TC-TMPV-N17: Restore — non-existent variable ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/template-variables/99999/restore` | Variable 99999 doesn't exist |
| 2 | Verify 404 Not Found from onlyTrashed()->findOrFail | 404 error |

#### TC-TMPV-N18: Permission — index without tenant.template.variable.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.variable.viewAny` permission accesses `/template-variables` | 403 Forbidden |
| 2 | Verify Gate::authorize() fails | Aborted |

#### TC-TMPV-N19: Permission — create without tenant.template.variable.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.variable.create` accesses `/template-variables/create` | 403 Forbidden |

#### TC-TMPV-N20: Permission — store without tenant.template.variable.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.variable.create` POSTs to `/template-variables` | 403 Forbidden |

#### TC-TMPV-N21: Permission — edit without tenant.template.variable.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.variable.update` accesses `/template-variables/{id}/edit` | 403 Forbidden |

#### TC-TMPV-N22: Permission — update without tenant.template.variable.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.variable.update` PUTs to `/template-variables/{id}` | 403 Forbidden |

#### TC-TMPV-N23: Permission — show without tenant.template.variable.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.variable.view` accesses `/template-variables/{id}` | 403 Forbidden |

#### TC-TMPV-N24: Permission — destroy without tenant.template.variable.delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.variable.delete` DELETEs `/template-variables/{id}` | 403 Forbidden |

#### TC-TMPV-N25: Permission — trashed without tenant.template.variable.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.variable.restore` accesses `/template-variables/trashed` | 403 Forbidden |

#### TC-TMPV-N26: Permission — restore without tenant.template.variable.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.variable.restore` POSTs to `/template-variables/{id}/restore` | 403 Forbidden |

#### TC-TMPV-N27: Permission — forceDelete without tenant.template.variable.forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.variable.forceDelete` DELETEs `/template-variables/{id}/force-delete` | 403 Forbidden |

#### TC-TMPV-N28: Permission — toggleStatus without tenant.template.variable.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.variable.update` POSTs to `/template-variables/{id}/toggle-status` | 403 Forbidden |

### 10.3 Code Review TC Steps

#### TC-CR-TMPV01: index() — authorization + paginated list with type relation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.variable.viewAny')` at method start | Gate present |
| 2 | Review `TemplateVariable::with('type')->paginate(...)` for eager loading | Eager load confirmed |
| 3 | Review return view with `templateVariables` variable | View returned |
| 4 | Verify no search/filter logic (plain list) | Simple list |

#### TC-CR-TMPV02: create() — active types, getDatabases() call, form view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.variable.create')` | Gate present |
| 2 | Review `TemplateType::active()->get()` for types dropdown | Active types loaded |
| 3 | Review internal or helper call to `getDatabases()` for DB dropdown | Databases loaded |
| 4 | Review return view with templateTypes and databases variables | Form data prepared |

#### TC-CR-TMPV03: store() — Gate authorize + FormRequest + redirect + flash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.variable.create')` | Gate present |
| 2 | Review `TemplateVariable::create($request->validated())` | Creation via validated data |
| 3 | Review `redirect()->route(...)->with('success', flash(...))` | Flash success |
| 4 | Review no try-catch wrapper — exception bubbles up | Exception handling |

#### TC-CR-TMPV04: show() — Gate authorize + findOrFail + view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.variable.view')` | Gate present |
| 2 | Review `TemplateVariable::findOrFail($id)` or route model binding | Model resolved |
| 3 | Review return view with templateVariable variable | View returned |

#### TC-CR-TMPV05: edit() — Gate authorize + findOrFail + load types + databases

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.variable.update')` | Gate present |
| 2 | Review `TemplateVariable::findOrFail($id)` or route model binding | Model resolved |
| 3 | Review `TemplateType::active()->get()` for types dropdown | Types loaded |
| 4 | Review `getDatabases()` call for DB dropdown | Databases loaded |

#### TC-CR-TMPV06: update() — Gate authorize + findOrFail + FormRequest + redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.variable.update')` | Gate present |
| 2 | Review `TemplateVariable::findOrFail($id)` or route model binding | Model resolved |
| 3 | Review `$templateVariable->update($request->validated())` | Update via validated data |
| 4 | Review redirect with success flash | Flash success |

#### TC-CR-TMPV07: destroy() — Gate authorize + findOrFail + delete + flash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.variable.delete')` | Gate present |
| 2 | Review `TemplateVariable::findOrFail($id)` or route model binding | Model resolved |
| 3 | Review `$templateVariable->delete()` — triggers SoftDeletes | Soft delete |
| 4 | Review flash message and redirect | Flash success |

#### TC-CR-TMPV08: toggleStatus() — Gate authorize + validate + findOrFail + save + JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.variable.update')` — uses update permission | Gate present |
| 2 | Review inline validation: `$request->validate(['is_active' => 'required|boolean'])` | Validation |
| 3 | Review `TemplateVariable::findOrFail($id)` | Model binding |
| 4 | Review `$templateVariable->save()` and response status | Save executed |
| 5 | Review JSON success/error response based on save result | AJAX JSON response |

#### TC-CR-TMPV09: trashed() — Gate authorize + onlyTrashed()->paginate()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.variable.restore')` | Gate present |
| 2 | Review `TemplateVariable::onlyTrashed()->paginate(...)` | Scoped to trashed |
| 3 | Review return view with trashed variables | View returned |

#### TC-CR-TMPV10: restore() — Gate authorize + onlyTrashed()->findOrFail + restore + flash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.variable.restore')` | Gate present |
| 2 | Review `TemplateVariable::onlyTrashed()->findOrFail($id)` | Scoped to trashed |
| 3 | Review `$templateVariable->restore()` | Restore called |
| 4 | Review flash message and redirect | Flash success |

#### TC-CR-TMPV11: forceDelete() — Gate authorize + withTrashed()->findOrFail + forceDelete + flash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.variable.forceDelete')` | Gate present |
| 2 | Review `TemplateVariable::withTrashed()->findOrFail($id)` | Bypasses soft-delete scope |
| 3 | Review `$templateVariable->forceDelete()` | Permanent delete + flash |

#### TC-CR-TMPV12: getDatabases() — SHOW DATABASES filter + JSON response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review raw SQL execution of `SHOW DATABASES` | SQL executed |
| 2 | Review filtering logic to exclude system DBs (information_schema, mysql, performance_schema, sys) | System DBs excluded |
| 3 | Review JSON response format — array of database names | Returns JSON array |

#### TC-CR-TMPV13: getTables(Request) — SHOW TABLES FROM + JSON response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$request->db_name` retrieval | DB name from request |
| 2 | Review raw SQL: `SHOW TABLES FROM {db_name}` with proper escaping | SQL executed |
| 3 | Review JSON response format — array of table names | Returns JSON array |

#### TC-CR-TMPV14: getColumns(Request) — SHOW COLUMNS FROM + JSON response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$request->db_name` and `$request->table_name` retrieval | Parameters from request |
| 2 | Review raw SQL: `SHOW COLUMNS FROM {db_name}.{table_name}` with proper escaping | SQL executed |
| 3 | Review JSON response format — array of column/field names | Returns JSON array |

#### TC-CR-TMPV15: StoreTemplateVariableRequest — all field rules + withValidator logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review template_type_id: required|integer|exists:tmp_templates_type,id | FK validation |
| 2 | Review name: required|string|max:50|regex:/^[a-z0-9_]+$/|unique with ignore and where | Name rules |
| 3 | Review description: nullable|string|max:255 | Description rules |
| 4 | Review db_name, table_name, field_name: nullable|string|max:60 | Automated field rules |
| 5 | Review withValidator — table without field or field without table → error | Pair validation |
| 6 | Review is_active: required|boolean | Status validation |

#### TC-CR-TMPV16: StoreTemplateVariableRequest — authorize() returns true (no Gate)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `authorize()` method | Returns `true` |
| 2 | Note: No Gate check in FormRequest — relies entirely on controller Gate | Defence-in-depth gap |

#### TC-CR-TMPV17: StoreTemplateVariableRequest — prepareForValidation is_active boolean cast

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `prepareForValidation()` method | Merges is_active |
| 2 | Review `$this->boolean('is_active')` conversion | Checkbox to boolean |
| 3 | Note: This runs before validation so is_active is always boolean when validated | Pre-processing |

#### TC-CR-TMPV18: TemplateVariablePolicy — all 7 method signatures

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review viewAny(User) | Returns `$user->can('tenant.template.variable.viewAny')` |
| 2 | Review view(User, TemplateVariable) | Returns `$user->can('tenant.template.variable.view')` |
| 3 | Review create(User) | Returns `$user->can('tenant.template.variable.create')` |
| 4 | Review update(User, TemplateVariable) | Returns `$user->can('tenant.template.variable.update')` |

#### TC-CR-TMPV19: TemplateVariable Model — fillable, casts, scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$fillable` array — template_type_id, name, description, db_name, table_name, field_name, is_active | All fillable fields |
| 2 | Review `$casts` — template_type_id=>integer, is_active=>boolean | Casts configured |
| 3 | Review `SoftDeletes` trait imported | Soft deletes enabled |
| 4 | Review `scopeActive()` — where is_active = true | Active scope |

#### TC-CR-TMPV20: TemplateVariable Model — relationships (type, templates)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `type()` — belongsTo TemplateType::class | Belongs to type |
| 2 | Review `templates()` — belongsToMany via tmp_templates_variables_jnt | Belongs to many templates |
| 3 | Review pivot fields: display_order, default_value, is_active | Pivot data |
| 4 | Review pivot table name: `tmp_templates_variables_jnt` | Junction table correct |

#### TC-CR-TMPV21: TemplateVariable Model — active() scope implementation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `scopeActive($query)` method signature | Scope method |
| 2 | Review `return $query->where('is_active', true)` | Filter condition |

#### TC-CR-TMPV22: store() — activityLog call with created event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `activityLog($variable, 'created', ['name' => $variable->name])` after successful creation | Call present |
| 2 | Verify first argument is the TemplateVariable model instance | Model argument correct |
| 3 | Verify action string is 'created' and the `name` property is passed in the context array | Context correct |

#### TC-CR-TMPV23: update() — activityLog call with updated event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `activityLog($variable, 'updated', ['name' => $variable->name])` after successful update | Call present |
| 2 | Verify first argument is the TemplateVariable model instance | Model argument correct |
| 3 | Verify action string is 'updated' and the `name` property is passed in the context array | Context correct |

#### TC-CR-TMPV24: destroy() — activityLog call with deleted event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `activityLog($variable, 'deleted', ['name' => $variable->name])` after successful delete | Call present |
| 2 | Verify first argument is the TemplateVariable model instance | Model argument correct |
| 3 | Verify action string is 'deleted' and the `name` property is passed in the context array | Context correct |

#### TC-CR-TMPV25: restore() — activityLog call with restored event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `activityLog($variable, 'restored', ['name' => $variable->name])` after successful restore | Call present |
| 2 | Verify first argument is the TemplateVariable model instance | Model argument correct |
| 3 | Verify action string is 'restored' and the `name` property is passed in the context array | Context correct |

#### TC-CR-TMPV26: forceDelete() — activityLog call with permanently_deleted event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `activityLog($variable, 'permanently_deleted', ['name' => $variable->name])` after successful force-delete | Call present |
| 2 | Verify first argument is the TemplateVariable model instance | Model argument correct |
| 3 | Verify action string is 'permanently_deleted' and the `name` property is passed in the context array | Context correct |

#### TC-CR-TMPV27: toggleStatus() — activityLog call with status_updated event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `activityLog($variable, 'status_updated', ['name' => $variable->name])` after successful toggle (returns JSON) | Call present |
| 2 | Verify first argument is the TemplateVariable model instance | Model argument correct |
| 3 | Verify action string is 'status_updated' and the `name` property is passed in the context array | Context correct |

### 10.4 Dependency TC Steps

#### TC-D-TMPV01: FK cascade — delete template type cascades to variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | TemplateType A has 3 associated template variables | Referenced type |
| 2 | Delete TemplateType A from tmp_templates_type | CASCADE triggered |
| 3 | Verify all 3 template variables with template_type_id = A are also deleted from tmp_template_variables | Variables cascade-deleted |

#### TC-D-TMPV02: FK cascade — delete variable cascades to junction table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | TemplateVariable V1 is linked to 2 templates via tmp_templates_variables_jnt | Junction records exist |
| 2 | Delete TemplateVariable V1 from tmp_template_variables | CASCADE triggered |
| 3 | Verify junction records with template_variable_id = V1 are also deleted from tmp_templates_variables_jnt | Junction rows cascade-deleted |

#### TC-D-TMPV03: FK cascade — delete template cascades to junction table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template T1 has 5 associated template variables via junction table | Junction records exist |
| 2 | Delete Template T1 from tmp_templates | CASCADE triggered |
| 3 | Verify junction records with template_id = T1 are deleted from tmp_templates_variables_jnt | Junction rows cascade-deleted |

#### TC-D-TMPV04: Unique constraint — duplicate name within same template_type_id blocked at DB level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Variable with name="email" under TemplateType A already exists | Existing record |
| 2 | Attempt to manually INSERT another record with same name="email" AND same template_type_id = A | DB error |
| 3 | Verify unique constraint violation: Duplicate entry for key `uq_tmp_tv_type_name` | DB-level rejection |

#### TC-D-TMPV05: Same variable name allowed across different template types (no cross-type unique)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Variable "email" exists under TemplateType A | Existing record |
| 2 | Insert variable "email" under TemplateType B (different type) | Insert succeeds |
| 3 | Verify UNIQUE key only spans (template_type_id, name) — no cross-type conflict | Cross-type names allowed |

#### TC-D-TMPV06: Soft delete — deleted_at set on destroy, null on restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete variable via destroy() | deleted_at set to timestamp |
| 2 | Query DB with `withTrashed()` — record exists with deleted_at NOT NULL | Soft-deleted |
| 3 | Restore variable | deleted_at set to NULL |
| 4 | Query DB — record exists without deleted_at | Restored |

#### TC-D-TMPV07: Junction pivot — display_order, default_value, is_active stored in pivot

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attach variable to a template with pivot data: display_order=1, default_value="test", is_active=true | Pivot data set |
| 2 | Access pivot via `$template->variables()->first()->pivot` | Pivot accessible |
| 3 | Verify pivot->display_order = 1, pivot->default_value = "test", pivot->is_active = true | All pivot fields stored |

#### TC-D-TMPV08: Activity log entry created on every CRUD operation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Perform store() on a template variable | activityLog() called with 'created' event |
| 2 | Perform update() on a template variable | activityLog() called with 'updated' event |
| 3 | Perform destroy() on a template variable | activityLog() called with 'deleted' event |
| 4 | Perform restore() on a template variable | activityLog() called with 'restored' event |
| 5 | Perform forceDelete() on a template variable | activityLog() called with 'permanently_deleted' event |
| 6 | Perform toggleStatus() on a template variable | activityLog() called with 'status_updated' event |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/template-variables` | template-variables.index | index() | tenant.template.variable.viewAny |
| GET | `/template-variables/create` | template-variables.create | create() | tenant.template.variable.create |
| POST | `/template-variables` | template-variables.store | store() | tenant.template.variable.create |
| GET | `/template-variables/{template_variable}` | template-variables.show | show() | tenant.template.variable.view |
| GET | `/template-variables/{template_variable}/edit` | template-variables.edit | edit() | tenant.template.variable.update |
| PUT | `/template-variables/{template_variable}` | template-variables.update | update() | tenant.template.variable.update |
| DELETE | `/template-variables/{template_variable}` | template-variables.destroy | destroy() | tenant.template.variable.delete |
| GET | `/template-variables/trashed` | template-variables.trashed | trashed() | tenant.template.variable.restore |
| GET | `/template-variables/{id}/restore` | template-variables.restore | restore() | tenant.template.variable.restore |
| DELETE | `/template-variables/{id}/force-delete` | template-variables.forceDelete | forceDelete() | tenant.template.variable.forceDelete |
| POST | `/template-variables/{id}/toggle-status` | template-variables.toggleStatus | toggleStatus() | tenant.template.variable.update |
| GET | `/template-variables-get-databases` | template-variables.get-databases | getDatabases() | tenant.template.variable.view |
| GET | `/template-variables-get-tables` | template-variables.get-tables | getTables(Request) | tenant.template.variable.view |
| GET | `/template-variables-get-columns` | template-variables.get-columns | getColumns(Request) | tenant.template.variable.view |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | No dedicated soft-delete page name in routes — "trashed" used for both route and method name | **Info** | Route named `template-variables.trashed` vs the standard `template-variables.trash.view` pattern used elsewhere |
| KI-02 | toggleStatus() uses tenant.template.variable.update instead of a dedicated status permission | **Low** | No dedicated `tenant.template.variable.status` permission exists; status toggle reuses update permission |
| KI-03 | No cascade check before destroy() — relies entirely on FK CASCADE for junction cleanup | **Info** | Soft-delete does not check for junction references; CASCADE handles cleanup on force delete |
| KI-04 | No cascade check before forceDelete() — relies on FK CASCADE | **Low** | Junction table FK with CASCADE means permanent deletion also removes junction data silently |
| KI-05 | FormRequest authorize() returns true | **Medium** | No Gate check in FormRequest — defence-in-depth collapsed; relies solely on controller Gate |
| KI-06 | getDatabases() executes raw SHOW DATABASES — potential security concern | **Low** | Raw SQL execution; relies on database user permissions to restrict visibility |
| KI-07 | getTables() and getColumns() use raw SQL with minimal escaping | **Medium** | Raw SQL concatenation — should use parameterized queries or proper escaping to prevent injection |
| KI-08 | db_name, table_name, field_name nullable with max:60 — no format validation beyond string | **Low** | No regex validation for DB object names; relies on MySQL to reject invalid names |
| KI-09 | ~~No activity logging implemented~~ (removed — `activityLog()` IS called on all CRUD operations) | — | — |
| KI-10 | No search/filter on index page | **Info** | index() returns a plain paginated list without search input or status filter |

---

## 13. Feature Summary Matrix

| Feature | Controller Method(s) | Key Models | Pagination |
|---------|---------------------|------------|------------|
| Variable List | index() | TemplateVariable, TemplateType | Paginated |
| Create Variable (Manual) | create(), store() | TemplateVariable, TemplateType | None (form) |
| Create Variable (Automated) | create(), store() + getDatabases/getTables/getColumns | TemplateVariable, DB Schema | None (form + AJAX) |
| View Variable | show() | TemplateVariable | None |
| Edit Variable | edit(), update() | TemplateVariable, TemplateType | None (form) |
| Soft-Delete / Restore | destroy(), trashed(), restore() | TemplateVariable | Paginated (trash) |
| Force Delete | forceDelete() | TemplateVariable | None |
| Toggle Status | toggleStatus() | TemplateVariable | None (AJAX) |
| AJAX Databases | getDatabases() | MySQL SHOW DATABASES | None (JSON) |
| AJAX Tables | getTables(Request) | MySQL SHOW TABLES | None (JSON) |
| AJAX Columns | getColumns(Request) | MySQL SHOW COLUMNS | None (JSON) |
| **TC Count** | **Positive: 22 / Negative: 28 / Code Review: 27 / Dependency: 8** | **Total: 85** | |
