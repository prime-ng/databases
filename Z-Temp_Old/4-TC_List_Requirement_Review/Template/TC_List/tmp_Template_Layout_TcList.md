# tmp_Template_Layout_TcList

## Module: Template → Template Management → Template CRUD

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Template (TMP) |
| Tab Group | Template Dashboard (Tabbed Interface) |
| Features | Template List, Create/Edit/View/Delete/Restore/Force-Delete, Toggle Status, Variable Picker Schema (AJAX), Multi-Tab Dashboard (All Templates, Drafts, Active, Trashed, Variable Picker) |
| URL(s) | `/template`, `/template/create`, `/template/{template}/edit`, `/template/{template}`, `/templates-trash`, `/templates/{id}/restore`, `/templates/{id}/force-delete`, `/templates/{id}/toggle-status`, `/template/{id}/schema` |
| Controller | `Modules\Template\Http\Controllers\TemplateController` |
| Model(s) | `Template`, `TemplateType`, `TemplateVariable` |
| Validation | `StoreTemplateRequest`, `UpdateTemplateRequest` |
| Permission Gates | `tenant.template.viewAny`, `tenant.template.view`, `tenant.template.create`, `tenant.template.update`, `tenant.template.delete`, `tenant.template.restore`, `tenant.template.forceDelete` |
| Soft Deletes | Yes — Template model uses `SoftDeletes` trait |
| Events | Activity logging via `activityLog()` on store, update, destroy, restore, forceDelete, toggleStatus |

---

## 2. Pre-conditions

- Required permissions: `tenant.template.viewAny`, `tenant.template.create`, `tenant.template.update`, `tenant.template.view`, `tenant.template.delete`, `tenant.template.restore`, `tenant.template.forceDelete`
- At least one active Template Type must exist in `tmp_templates_type` (referenced by `type_id`)
- For variable mapping tests: at least one Template Variable must exist in `tmp_template_variables`
- For search/filter tests: at least one template record with populated fields (name, code, description, type)
- For tab-view tests: templates in various states (draft, active, trashed) must exist
- For toggle-status tests: at least one draft (is_active=0) and one active (is_active=1) template record with mapped variables
- For trash/restore tests: at least one soft-deleted template record
- For getSchema tests: at least one template with mapped variables and display_order values

---

## 3. Default Data Load

### 3.1 Unified Tab View (tabView)

The `tabView()` method (not `index()`) serves as the main dashboard. `index()` simply redirects to `route('template.tabs')`. The tab view loads data conditionally based on the `tab` query parameter:

| Tab Key | Query Method | Data Returned |
|---------|-------------|---------------|
| `template_list` | `templatesQuery()` | Paginated templates with search/status/type_id filters |
| `type_list` | `templateTypesQuery()` | Paginated template types with search filter |
| `purpose_list` | `purposesQuery()` | Paginated purposes with search/scope_type_id/status filters |
| `assignment_list` | `assignmentsQuery()` | Paginated assignments with template/purpose/session/scope/status filters |
| `variable_list` | `templateVariablesQuery()` | Paginated variables with type_id filter |

### 3.2 Filter Data for Templates Tab

The `templatesQuery()` method returns:
- `templates` — Paginated template records with search support (name, code, description, type.name)
- Search/filter parameters:
  - `search` — Text search on name, code, description, type.name (nested relation)
  - `status` — is_active filter (converted to boolean)

### 3.3 Filter Data for Template Types Tab

The `templateTypesQuery()` method returns:
- `templateTypes` — Paginated TemplateType records with search on name

### 3.4 Filter Data for Purposes Tab

The `purposesQuery()` method returns:
- `purposes` — Paginated TemplatePurpose records with search/scope_type_id/status filters

### 3.5 Filter Data for Assignments Tab

The `assignmentsQuery()` method returns:
- `assignments` — Paginated TemplateAssignment records with search/template/purpose/session/scope/status filters

### 3.6 Filter Data for Variables Tab

The `templateVariablesQuery()` method returns:
- `variables` — Paginated TemplateVariable records with type_id filter

---

## 4. BC-DB — Database Schema

### 4.1 `tmp_templates` — Primary Template Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| code | VARCHAR(50) | NOT NULL | — | Unique template code |
| name | VARCHAR(100) | NOT NULL | — | Template display name |
| type_id | INT UNSIGNED | YES | NULL | FK → tmp_templates_type(id) ON DELETE SET NULL |
| description | TEXT | YES | NULL | Template description |
| canvas_json | JSON | YES | NULL | JSON canvas layout data |
| html_content | LONGTEXT | NOT NULL | — | HTML content (sanitized via SanitizesRichText) |
| background_image | VARCHAR(255) | YES | NULL | Background image file path |
| is_active | TINYINT(1) | YES | 0 | Active flag (draft=0, active=1) |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uq_tmp_template_code` (`code`)
- KEY `idx_tmp_template_type` (`type_id`)
- KEY `idx_tmp_template_active` (`is_active`, `deleted_at`)

### 4.2 `tmp_templates_variables_jnt` — Template-Variable Junction Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| template_id | INT UNSIGNED | NOT NULL | — | FK → tmp_templates(id) ON DELETE CASCADE |
| variable_id | INT UNSIGNED | NOT NULL | — | FK → tmp_template_variables(id) ON DELETE CASCADE |
| display_order | SMALLINT UNSIGNED | YES | 0 | Variable display ordering |
| default_value | VARCHAR(255) | YES | NULL | Default variable value |
| is_active | TINYINT(1) | YES | 1 | Active flag for junction record |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uq_tmp_template_variable` (`template_id`, `variable_id`)
- KEY `idx_jnt_variable` (`variable_id`)

---

## 5. BC-VAL — Validation Rules

### 5.1 StoreTemplateRequest Validation

| Field | Rules | Error Message |
|-------|-------|---------------|
| code | required, string, max:50, unique:tmp_templates,code | "The code has already been taken." (unique) |
| name | required, string, max:255 | "The name field is required." |
| type_id | required, integer, exists:tmp_templates_type,id | "The type id field is required." |
| description | nullable, string | — |
| canvas_json | nullable, json | "The canvas json must be a valid JSON string." |
| html_content | required, string | "The html content field is required." |
| background_image | nullable, string | — |
| variable_ids | nullable, array | — |
| variable_ids.* | integer, exists:tmp_template_variables,id | "Invalid variable selected." |
| is_active | boolean | "The is active field must be true or false." |

**withValidator — Activation Gate:**
- If `is_active = true` AND `variable_ids` is empty/null → Validation error: "A template cannot be activated unless at least one variable is mapped."
- This prevents publishing a template with zero variable bindings

### 5.2 UpdateTemplateRequest Validation

| Field | Rules | Error Message |
|-------|-------|---------------|
| name | required, string, max:255 | "The name field is required." |
| type_id | required, integer, exists:tmp_templates_type,id | "The type id field is required." |
| description | nullable, string | — |
| canvas_json | nullable, json | "The canvas json must be a valid JSON string." |
| html_content | required, string | "The html content field is required." |
| background_image | nullable, string | — |
| variable_ids | nullable, array | — |
| variable_ids.* | integer, exists:tmp_template_variables,id | "Invalid variable selected." |
| is_active | boolean | "The is active field must be true or false." |

**Key Difference from StoreTemplateRequest:** `code` is NOT in the rules — the template code is not editable after creation.

**Authorization:** `authorize()` method returns `true` (no Gate check in FormRequest — defence delegated to controller)

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method(s) | Model Policy |
|----------------|---------------------|-------------|
| tenant.template.viewAny | index() (via `Gate::any()` with 6 other permissions) | TemplatePolicy@viewAny |
| tenant.template.view | show(), getSchema() | TemplatePolicy@view |
| tenant.template.create | create(), store() | TemplatePolicy@create |
| tenant.template.update | edit(), update(), toggleStatus() | TemplatePolicy@update |
| tenant.template.delete | destroy() | TemplatePolicy@delete |
| tenant.template.restore | trashed(), restore() | TemplatePolicy@restore |
| tenant.template.forceDelete | forceDelete() | TemplatePolicy@forceDelete |

**index() Gate Behaviour:** Uses `Gate::any([...7 permissions...]) || abort(403)` — any one of 7 template-related permissions grants access to the dashboard tab view

**Policy status() Method:** Defined in TemplatePolicy as `$user->can('tenant.template.view')` — uses the same permission as view

**Blade @can directives (expected in views):**
- `@can('tenant.template.viewAny')` — Dashboard access
- `@can('tenant.template.create')` — Create button
- `@can('tenant.template.update')` — Edit and Toggle Status actions
- `@can('tenant.template.view')` — View action button / Schema preview
- `@can('tenant.template.delete')` — Delete action button

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | Tabbed Dashboard View | tabView() returns unified tab view with 5 independent query methods (templates, drafts, active, trashed, variable picker) each paginated |
| BC-BIZ-02 | Multi-Permission Index Gate | tabView() uses `Gate::any()` with 7 permissions OR abort(403) — any one grants dashboard access |
| BC-BIZ-03 | Search Across Template Fields | templatesQuery searches name, code, description, type.name via `like` with wildcards |
| BC-BIZ-04 | Tab-Specific Filtering | Each query method only applies filters when `$request->input('tab')` matches its tab key |
| BC-BIZ-05 | Variable Syncing on Store | store() accepts `variable_ids` array and syncs via `$template->variables()->sync($variableIds)` |
| BC-BIZ-06 | Variable Syncing on Update | update() captures original variable_ids, calls `sync()` with new array, logs changes |
| BC-BIZ-07 | Activation Gate in Validator | StoreTemplateRequest withValidator prevents activation (is_active=true) unless at least one variable_id is provided |
| BC-BIZ-08 | Draft→Active with Variables | toggleStatus() checks if activating (is_active=true) and validates variables exist; returns JSON response |
| BC-BIZ-09 | Canvas JSON Cast | canvas_json stored as JSON in DB, cast to array on Eloquent access via `$casts` |
| BC-BIZ-10 | HTML Sanitization | html_content sanitized via `SanitizesRichText` trait with full_math configuration before save |
| BC-BIZ-11 | getSchema AJAX Endpoint | getSchema($id) returns template with mapped variables (id, name, display_order, default_value) as JSON for variable picker |
| BC-BIZ-12 | Soft Delete with Deactivation | destroy() sets is_active=false before calling delete() |
| BC-BIZ-13 | Restore with Save | restore() calls `restore()` then `save()` on the restored model |
| BC-BIZ-14 | Force Delete with SoftDeletes | forceDelete() uses `withTrashed()->findOrFail()` to bypass SoftDeletes and permanently delete |
| BC-BIZ-15 | Toggle Status via AJAX | toggleStatus() validates is_active as required|boolean, returns JSON success/error response |
| BC-BIZ-16 | Unique Template Code | code column has UNIQUE constraint at DB level; StoreTemplateRequest enforces unique validation |
| BC-BIZ-17 | Junction Display Order | Variables mapped via junction store display_order for rendering order in variable picker |
| BC-BIZ-18 | Background Image as Path | background_image stored as string file path (not media library) |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_tmp_template_type | tmp_templates.type_id | tmp_templates_type.id | SET NULL |
| fk_jnt_template | tmp_templates_variables_jnt.template_id | tmp_templates.id | CASCADE |
| fk_jnt_variable | tmp_templates_variables_jnt.variable_id | tmp_template_variables.id | CASCADE |

**Integrity Notes:**
- Deleting a Template Type sets type_id=NULL on all associated templates (preserves template records)
- Deleting a Template cascades to remove all junction records (no orphaned variable mappings)
- Deleting a Template Variable cascades to remove all junction records referencing it
- code column has DB-level UNIQUE constraint — enforced at both application and database layers

---

## 9. Test Case Summary

### 9.1 Template CRUD — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-TMP-P01 | Template CRUD | Positive | tabView loads with all 5 tabs (All Templates, Drafts, Active, Trashed, Variable Picker) | 6 |
| TC-TMP-P02 | Template CRUD | Positive | Create template — minimal required fields only (code, name, type_id, html_content) | 6 |
| TC-TMP-P03 | Template CRUD | Positive | Create template — with all variables mapped + HTML content | 8 |
| TC-TMP-P04 | Template CRUD | Positive | Create template — with canvas_json layout data | 6 |
| TC-TMP-P05 | Template CRUD | Positive | Create template — with background_image path | 6 |
| TC-TMP-P06 | Template CRUD | Positive | Edit template — change name and type_id | 5 |
| TC-TMP-P07 | Template CRUD | Positive | Edit template — sync variables (add new, remove existing) | 6 |
| TC-TMP-P08 | Template CRUD | Positive | Toggle status — draft (is_active=0) to active (is_active=1) with variables | 5 |
| TC-TMP-P09 | Template CRUD | Positive | Toggle status — active (is_active=1) to draft (is_active=0) | 4 |
| TC-TMP-P10 | Template CRUD | Positive | Preview template — getSchema AJAX returns variable picker data | 5 |
| TC-TMP-P11 | Template CRUD | Positive | Soft-delete template | 4 |
| TC-TMP-P12 | Template CRUD | Positive | View trashed templates | 3 |
| TC-TMP-P13 | Template CRUD | Positive | Restore template from trash | 4 |
| TC-TMP-P14 | Template CRUD | Positive | Force-delete template (no assignments) | 4 |
| TC-TMP-P15 | Template CRUD | Positive | Search templates — by name | 3 |
| TC-TMP-P16 | Template CRUD | Positive | Search templates — by code | 3 |
| TC-TMP-P17 | Template CRUD | Positive | Search templates — by description | 3 |
| TC-TMP-P18 | Template CRUD | Positive | Search templates — by type name (nested relation) | 3 |
| TC-TMP-P19 | Template CRUD | Positive | Filter templates — by status (active/inactive) | 3 |
| TC-TMP-P20 | Template CRUD | Positive | View single template detail (show) | 3 |
| TC-TMP-P21 | Template CRUD | Positive | Drafts tab loads with only inactive templates | 4 |
| TC-TMP-P22 | Template CRUD | Positive | Active tab loads with only active templates (scope active()) | 4 |
| TC-TMP-P23 | Template CRUD | Positive | Trashed tab loads with only soft-deleted templates | 4 |
| TC-TMP-P24 | Template CRUD | Positive | Variable Picker tab loads with type_id filter and ordered variables | 5 |
| TC-TMP-P25 | Template CRUD | Positive | Activity log created on template store | 3 |
| TC-TMP-P26 | Template CRUD | Positive | Activity log created on template update with variable sync changes | 3 |
| TC-TMP-P27 | Template CRUD | Positive | Activity log created on template soft-delete | 3 |
| TC-TMP-P28 | Template CRUD | Positive | Activity log created on template restore | 3 |
| TC-TMP-P29 | Template CRUD | Positive | Activity log created on template force-delete | 3 |
| TC-TMP-P30 | Template CRUD | Positive | Activity log created on template toggle-status | 3 |
| TC-TMP-P31 | Template CRUD | Positive | Junction table — display_order respected in variable picker ordering | 4 |
| TC-TMP-P32 | Template CRUD | Positive | Junction table — default_value stored and retrievable per mapping | 4 |
| TC-TMP-P33 | Template CRUD | Positive | Create template with is_active=false (draft) — no variable_ids required | 5 |
| TC-TMP-P34 | Template CRUD | Positive | Upload background image — valid JPEG under 2MB → success JSON with url and path | 4 |
| TC-TMP-P35 | Template CRUD | Positive | Upload background image — valid PNG under 2MB → success | 4 |
| TC-TMP-P36 | Template CRUD | Positive | Preview sample — template with registered provider → renders with sample data | 5 |
| TC-TMP-P37 | Template CRUD | Positive | Soft-delete template cascades to deactivate all linked assignments | 3 |
| TC-TMP-P38 | Template CRUD | Positive | Create template — html_content sanitized via SanitizesRichText (full_math mode) | 4 |

### 9.2 Template CRUD — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-TMP-N01 | Template CRUD | Negative | Create — missing code | 2 |
| TC-TMP-N02 | Template CRUD | Negative | Create — duplicate code | 2 |
| TC-TMP-N03 | Template CRUD | Negative | Create — code exceeds 50 chars | 2 |
| TC-TMP-N04 | Template CRUD | Negative | Create — missing name | 2 |
| TC-TMP-N05 | Template CRUD | Negative | Create — name exceeds 255 chars | 2 |
| TC-TMP-N06 | Template CRUD | Negative | Create — missing type_id | 2 |
| TC-TMP-N07 | Template CRUD | Negative | Create — invalid type_id (non-existent) | 2 |
| TC-TMP-N08 | Template CRUD | Negative | Create — invalid JSON in canvas_json | 2 |
| TC-TMP-N09 | Template CRUD | Negative | Create — missing html_content | 2 |
| TC-TMP-N10 | Template CRUD | Negative | Create — is_active=true with zero variable_ids (activation gate) | 2 |
| TC-TMP-N11 | Template CRUD | Negative | Create — invalid variable_ids (non-existent variable) | 2 |
| TC-TMP-N12 | Template CRUD | Negative | Create — variable_ids not an array | 2 |
| TC-TMP-N13 | Template CRUD | Negative | Toggle status — activate (is_active=true) template with no mapped variables | 3 |
| TC-TMP-N14 | Template CRUD | Negative | Toggle status — missing is_active parameter | 2 |
| TC-TMP-N15 | Template CRUD | Negative | Toggle status — non-boolean is_active value | 2 |
| TC-TMP-N16 | Template CRUD | Negative | Toggle status — non-existent template ID | 2 |
| TC-TMP-N17 | Template CRUD | Negative | Force delete — non-existent template ID | 2 |
| TC-TMP-N18 | Template CRUD | Negative | Restore — non-existent template ID | 2 |
| TC-TMP-N19 | Template CRUD | Negative | Permission — index without any tenant.template.* permission | 2 |
| TC-TMP-N20 | Template CRUD | Negative | Permission — create without tenant.template.create | 2 |
| TC-TMP-N21 | Template CRUD | Negative | Permission — store without tenant.template.create | 2 |
| TC-TMP-N22 | Template CRUD | Negative | Permission — edit without tenant.template.update | 2 |
| TC-TMP-N23 | Template CRUD | Negative | Permission — update without tenant.template.update | 2 |
| TC-TMP-N24 | Template CRUD | Negative | Permission — view show without tenant.template.view | 2 |
| TC-TMP-N25 | Template CRUD | Negative | Permission — view schema (getSchema) without tenant.template.view | 2 |
| TC-TMP-N26 | Template CRUD | Negative | Permission — destroy without tenant.template.delete | 2 |
| TC-TMP-N27 | Template CRUD | Negative | Permission — trashed without tenant.template.restore | 2 |
| TC-TMP-N28 | Template CRUD | Negative | Permission — restore without tenant.template.restore | 2 |
| TC-TMP-N29 | Template CRUD | Negative | Permission — forceDelete without tenant.template.forceDelete | 2 |
| TC-TMP-N30 | Template CRUD | Negative | Permission — toggleStatus without tenant.template.update | 2 |
| TC-TMP-N31 | Template CRUD | Negative | Force delete — template with existing assignments (blocked with error — IS implemented) | 2 |
| TC-TMP-N32 | Template CRUD | Negative | Update — name exceeds 255 chars | 2 |
| TC-TMP-N33 | Template CRUD | Negative | Update — invalid type_id (non-existent) | 2 |
| TC-TMP-N34 | Template CRUD | Negative | Update — missing html_content | 2 |
| TC-TMP-N35 | Template CRUD | Negative | getSchema — non-existent template ID | 2 |
| TC-TMP-N36 | Template CRUD | Negative | Upload background image — non-image file (PDF) → validation error | 2 |
| TC-TMP-N37 | Template CRUD | Negative | Upload background image — image exceeds 2MB → validation error | 2 |
| TC-TMP-N38 | Template CRUD | Negative | Upload background image — no file in request → 400 error | 2 |
| TC-TMP-N39 | Template CRUD | Negative | Upload background image — upload without create or update permission → 403 | 2 |
| TC-TMP-N40 | Template CRUD | Negative | Preview sample — template with no registered provider → shows unresolved placeholders | 3 |
| TC-TMP-N41 | Template CRUD | Negative | Preview sample — permission denied without tenant.template.view → 403 | 2 |
| TC-TMP-N42 | Template CRUD | Negative | Toggle status — DB save failure returns 500 error JSON | 3 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR01 | Code Review | Review | tabView() — Gate::any() with 7 permissions + 5 tab routing | 5 |
| TC-CR02 | Code Review | Review | templatesQuery() — search (name, code, description, type.name) and status filter | 4 |
| TC-CR03 | Code Review | Review | draftsQuery() — scoped to is_active=false with search | 3 |
| TC-CR04 | Code Review | Review | activeTemplatesQuery() — uses active() scope with search | 3 |
| TC-CR05 | Code Review | Review | trashedTemplatesQuery() — onlyTrashed() with search | 3 |
| TC-CR06 | Code Review | Review | variablePickerQuery() — with type_id filter and eager loading with ordered variables | 4 |
| TC-CR07 | Code Review | Review | store() — Gate + validated + variable sync + activityLog | 5 |
| TC-CR08 | Code Review | Review | update() — variable sync detection + activityLog with changes | 5 |
| TC-CR09 | Code Review | Review | destroy() — is_active=false before delete + activityLog | 4 |
| TC-CR10 | Code Review | Review | restore() — onlyTrashed()->findOrFail + restore + save | 4 |
| TC-CR11 | Code Review | Review | forceDelete() — withTrashed()->findOrFail + forceDelete | 3 |
| TC-CR12 | Code Review | Review | toggleStatus() — Gate + inline validation + AJAX JSON response | 5 |
| TC-CR13 | Code Review | Review | getSchema() — Gate + with() variables ordered by display_order + JSON response | 4 |
| TC-CR14 | Code Review | Review | StoreTemplateRequest — all field rules including unique code | 5 |
| TC-CR15 | Code Review | Review | StoreTemplateRequest — withValidator activation gate (is_active + variable_ids check) | 3 |
| TC-CR16 | Code Review | Review | UpdateTemplateRequest — code NOT in rules (immutable code) | 3 |
| TC-CR17 | Code Review | Review | TemplatePolicy — all 7 method signatures | 4 |
| TC-CR18 | Code Review | Review | Template Model — fillable, casts (canvas_json→array, is_active→boolean, type_id→integer) | 4 |
| TC-CR19 | Code Review | Review | Template Model — SanitizesRichText trait applied to html_content with full_math | 3 |
| TC-CR20 | Code Review | Review | Template Model — relationships (type BelongsTo, variables BelongsToMany via junction) | 4 |
| TC-CR21 | Code Review | Review | Template Model — active() scope (is_active=true) | 2 |
| TC-CR22 | Code Review | Review | Variable syncing — sync() usage in store() and update() | 4 |
| TC-CR23 | Code Review | Review | SoftDeletes — deleted_at handling in all query scopes | 3 |
| TC-CR24 | Code Review | Review | uploadImage() — Gate::allows with create OR update | 3 |
| TC-CR25 | Code Review | Review | uploadImage() — validation rules (image, max:2048, mimes) | 3 |
| TC-CR26 | Code Review | Review | uploadImage() — storage path and filename generation | 3 |
| TC-CR27 | Code Review | Review | uploadImage() — JSON response structure (success, url, path) | 3 |
| TC-CR28 | Code Review | Review | previewSample() — inferPurposeCode + schema + buildSampleData + renderById pipeline | 4 |
| TC-CR29 | Code Review | Review | inferPurposeCode() — active assignment returns correct purpose code | 3 |
| TC-CR30 | Code Review | Review | inferPurposeCode() — no assignment, type name fallback (Marksheet → MARKSHEET_PRINT) | 3 |
| TC-CR31 | Code Review | Review | inferPurposeCode() — no assignment, unknown type → empty string | 2 |
| TC-CR32 | Code Review | Review | buildSampleData() — builds fake data array from schema variables + loops | 4 |
| TC-CR33 | Code Review | Review | defaultSample() — image type returns placeholder path, text returns 'Sample' | 3 |
| TC-CR34 | Code Review | Review | forceDelete() — background_image file deletion from storage | 3 |
| TC-CR35 | Code Review | Review | Template Model — SanitizesRichText trait with full_math mode on html_content | 3 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-D01 | Dependency | Dependency | type_id FK → tmp_templates_type(id) — SET NULL on type delete | 3 |
| TC-D02 | Dependency | Dependency | Junction FK → tmp_templates(id) — CASCADE on template delete | 3 |
| TC-D03 | Dependency | Dependency | Junction FK → tmp_template_variables(id) — CASCADE on variable delete | 3 |
| TC-D04 | Dependency | Dependency | code column — UNIQUE constraint at DB level | 3 |
| TC-D05 | Dependency | Dependency | canvas_json — JSON column cast to array on Eloquent access | 3 |
| TC-D06 | Dependency | Dependency | is_active — boolean cast in model | 2 |
| TC-D07 | Dependency | Dependency | Junction UNIQUE(template_id, variable_id) — prevents duplicate variable mappings | 3 |
| TC-D08 | Dependency | Dependency | SoftDeletes — trashed templates excluded from active() scope | 3 |
| TC-D09 | Dependency | Dependency | API route — apiResource('templates') with auth:sanctum middleware | 3 |
| TC-D10 | Dependency | Dependency | API route — tenancy + module middleware present | 3 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Template CRUD

#### TC-TMP-P01: tabView loads with all 5 tabs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with any one of 7 template permissions navigates to `/template` | Dashboard tab view loads |
| 2 | Verify "All Templates" tab is active by default with paginated template list | All Templates tab selected |
| 3 | Verify "Drafts" tab shows only templates with is_active=0 | Drafts tab shows draft records |
| 4 | Verify "Active" tab shows only templates with is_active=1 (via active() scope) | Active tab shows active records |
| 5 | Verify "Trashed" tab shows only soft-deleted templates (via onlyTrashed()) | Trashed tab shows deleted records |
| 6 | Verify "Variable Picker" tab loads with type_id filter dropdown and variable list | Variable Picker tab loads |

#### TC-TMP-P02: Create template — minimal required fields only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.create` permission clicks "Add Template" | Create form loads |
| 2 | Enter code="TMPL-001", name="Minimal Template", select valid type_id | Fields populated |
| 3 | Enter html_content="<p>Hello World</p>" | HTML content filled |
| 4 | Leave canvas_json, background_image, variable_ids, description blank | Optional fields empty |
| 5 | Do NOT check is_active (leave as draft/false) | Draft mode |
| 6 | Click Submit | Redirected to template index |
| 7 | Verify success flash message appears and new template appears in All Templates tab | Template created |

#### TC-TMP-P03: Create template — with all variables mapped + HTML content

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter code="TMPL-002", name="Full Template", select valid type_id | Required fields set |
| 3 | Enter description="A template with all features" | Description set |
| 4 | Enter html_content="<html><body>{{variable1}} {{variable2}}</body></html>" | HTML with placeholders |
| 5 | Select variable_ids = [1, 2, 3] (variables that exist in tmp_template_variables) | Variables selected |
| 6 | Check is_active = true | Active requested |
| 7 | Click Submit | Success |
| 8 | Verify template created, variables synced in junction table with display_order=0 (default) | Variables mapped correctly |

#### TC-TMP-P04: Create template — with canvas_json layout data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter code="TMPL-003", name="Canvas Template", type_id=valid | Fields set |
| 3 | Enter html_content="<div>Canvas Content</div>" | HTML set |
| 4 | Enter canvas_json='{"components":[{"type":"text","x":10,"y":20,"width":200}]}' | Canvas JSON set |
| 5 | Set is_active=false | Draft |
| 6 | Submit | Success |
| 7 | Verify DB: canvas_json stores the JSON string, Eloquent returns as array | JSON stored + cast to array |

#### TC-TMP-P05: Create template — with background_image path

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter code="TMPL-004", name="Bg Image Template", type_id=valid | Fields set |
| 3 | Enter html_content="<div>With Background</div>" | HTML set |
| 4 | Set background_image = "uploads/templates/bg-header.jpg" | Image path set |
| 5 | Submit with is_active=false | Success |
| 6 | Verify DB: background_image = "uploads/templates/bg-header.jpg" | Path stored |

#### TC-TMP-P06: Edit template — change name and type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.update` permission clicks "Edit" on a template | Edit form loads with pre-filled data |
| 2 | Change name to "Updated Template Name", select a different type_id | Fields changed |
| 3 | Click Update | Redirected to template index |
| 4 | Verify success flash message appears | Success message |
| 5 | Verify template list shows updated name and type | Changes reflected |

#### TC-TMP-P07: Edit template — sync variables (add new, remove existing)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template initially has variable_ids = [1, 2] mapped via junction | Existing mappings |
| 2 | Edit template and change variable_ids = [2, 3, 4] | Add 3,4 — remove 1 |
| 3 | Submit update | Success |
| 4 | Verify junction table: variable_id=1 removed, variable_id=2 remains, variable_id=3,4 added | Sync correct |
| 5 | Verify old mapping for variable_id=1 is deleted from junction (CASCADE on detach) | Old mapping removed |
| 6 | Verify activity log captures variable change (old vs new variable_ids) | Change tracked |

#### TC-TMP-P08: Toggle status — draft to active (with variables)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate a draft template (is_active=0) that has at least one variable mapped | Draft template visible |
| 2 | Click status toggle to activate | AJAX call made |
| 3 | Verify JSON response: `{"success": true, "is_active": true, "message": "..."}` | AJAX success |
| 4 | Verify DB: is_active = 1 for the template | Activated |
| 5 | Verify template now appears in Active tab instead of Drafts tab | Tab moved |

#### TC-TMP-P09: Toggle status — active to draft

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an active template (is_active=1) | Active template visible |
| 2 | Click status toggle to deactivate | AJAX call made |
| 3 | Verify JSON response: `{"success": true, "is_active": false, "message": "..."}` | AJAX success |
| 4 | Verify DB: is_active = 0 for the template and activity log entry created | Deactivated |

#### TC-TMP-P10: Preview template — getSchema AJAX returns variable picker data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template has variables mapped with display_order and default_value | Mapped template exists |
| 2 | User with `tenant.template.view` permission calls GET `/template/{id}/schema` | AJAX endpoint hit |
| 3 | Verify JSON response contains template data with nested variables array | Schema returned |
| 4 | Verify each variable in response includes: id, name, display_order, default_value, is_active | Full variable data |
| 5 | Verify variables are ordered by display_order ascending | Correct ordering |

#### TC-TMP-P11: Soft-delete template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.delete` permission clicks "Delete" on an active template | Confirmation prompt |
| 2 | Confirm deletion | Template soft-deleted |
| 3 | Verify template no longer appears in All Templates tab | Removed from active list |
| 4 | Verify DB: deleted_at is not NULL AND is_active = 0 | Soft-deleted |

#### TC-TMP-P12: View trashed templates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trashed tab in template dashboard | Trashed tab shows |
| 2 | Verify only soft-deleted templates are visible | Trashed list |
| 3 | Verify Restore and Force Delete action buttons are present for each trashed item | Actions available |

#### TC-TMP-P13: Restore template from trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.restore` permission navigates to Trashed tab | Trash list loads |
| 2 | Locate a soft-deleted template and click "Restore" | Restore triggered |
| 3 | Verify template appears in All Templates tab, deleted_at is NULL | Restored |
| 4 | Verify activity log entry created with action='Restored' | Activity logged |

#### TC-TMP-P14: Force-delete template (no assignments)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.forceDelete` permission navigates to Trashed tab | Trash list loads |
| 2 | Locate a soft-deleted template with no dependent assignments and click "Force Delete" | Confirmation prompt |
| 3 | Confirm permanent deletion | Template permanently deleted |
| 4 | Verify DB record no longer exists (including withTrashed) and activity log entry created | Permanently deleted |

#### TC-TMP-P15: Search templates — by name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In All Templates tab, enter search term matching part of a template name | Filter applied |
| 2 | Verify result list contains only templates with matching name | Filtered results |
| 3 | Verify search is case-insensitive and uses LIKE %term% | Wildcard search |

#### TC-TMP-P16: Search templates — by code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In All Templates tab, enter search term matching part of a template code | Filter applied |
| 2 | Verify result list contains only templates with matching code | Filtered results |
| 3 | Verify partial match works (e.g. "TMPL" matches "TMPL-001") | Wildcard search |

#### TC-TMP-P17: Search templates — by description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In All Templates tab, enter search term from a template description | Filter applied |
| 2 | Verify result list contains templates with matching description | Filtered results |
| 3 | Verify search is case-insensitive LIKE %term% | Wildcard search |

#### TC-TMP-P18: Search templates — by type name (nested relation)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In All Templates tab, enter search term matching a TemplateType name | Filter applied |
| 2 | Verify result list contains templates whose type.name matches the term | Filtered results via relation |
| 3 | Verify search traverses the belongsTo relationship correctly | Nested relation search works |

#### TC-TMP-P19: Filter templates — by status (active/inactive)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In All Templates tab, set status filter to "Active" (1) | Filter applied |
| 2 | Verify only active templates (is_active=1) are shown | Active-only list |
| 3 | Set status filter to "Inactive" (0) and verify only inactive templates shown | Inactive-only list |

#### TC-TMP-P20: View single template detail (show)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.view` permission clicks "View" on a template row | Show page loads |
| 2 | Verify all template fields displayed: code, name, type, description, html_content, background_image, is_active status | All fields visible |
| 3 | Verify canvas_json rendered appropriately (if present) and variables list shown | Variables shown |

#### TC-TMP-P21: Drafts tab loads with only inactive templates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In template dashboard, click "Drafts" tab | Tab switches to drafts |
| 2 | Verify search input visible | Filters present |
| 3 | Verify all records have is_active=0 | Only drafts shown |
| 4 | Verify no active (is_active=1) or trashed (deleted_at NOT NULL) records appear | Properly scoped |

#### TC-TMP-P22: Active tab loads with only active templates (scope active())

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In template dashboard, click "Active" tab | Tab switches to active |
| 2 | Verify search input visible | Filters present |
| 3 | Verify all records have is_active=1 | Only active shown |
| 4 | Verify active() scope correctly filters is_active=true | Scope working |

#### TC-TMP-P23: Trashed tab loads with only soft-deleted templates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In template dashboard, click "Trashed" tab | Tab switches to trashed |
| 2 | Verify search input visible | Filters present |
| 3 | Verify all records have deleted_at NOT NULL | Only trashed shown |
| 4 | Verify pagination and Restore/ForceDelete actions available | Actions present |

#### TC-TMP-P24: Variable Picker tab loads with type_id filter and ordered variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In template dashboard, click "Variable Picker" tab | Tab switches to variable_picker |
| 2 | Verify type_id dropdown is present with all template types | Filter present |
| 3 | Select a type_id from dropdown | Templates of that type shown |
| 4 | Verify each template row shows associated variables ordered by display_order | Ordered variables |
| 5 | Verify pagination works correctly | Paginated |

#### TC-TMP-P25: Activity log created on template store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new template via store() | Success |
| 2 | Verify `activityLog()` was called with the Template model, action='Stored', and message='A new template was created.' | Logged |
| 3 | Verify performed_by = authenticated user's name | Performer tracked |

#### TC-TMP-P26: Activity log created on template update with variable sync changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update a template via update() including variable_ids change | Success |
| 2 | Verify `activityLog()` called with action='Updated' and changes array includes variable sync info | Logged |
| 3 | Verify changes contains old/new values for modified fields | Change tracking |

#### TC-TMP-P27: Activity log created on template soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a template via destroy() | Success |
| 2 | Verify `activityLog()` called with action='Trashed' and message='Template was deactivated and trashed.' | Logged |

#### TC-TMP-P28: Activity log created on template restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a trashed template via restore() | Success |
| 2 | Verify `activityLog()` called with action='Restored' and message='Template was restored.' | Logged |

#### TC-TMP-P29: Activity log created on template force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete a trashed template via forceDelete() | Success |
| 2 | Verify `activityLog()` called with action='Deleted' and message='Template was permanently deleted.' | Logged |

#### TC-TMP-P30: Activity log created on template toggle-status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle template status via toggleStatus() | AJAX success |
| 2 | Verify `activityLog()` called with action='Toggled' and message='Template status was updated.' | Logged |
| 3 | Verify performed_by = authenticated user's name | Performer tracked |

#### TC-TMP-P31: Junction table — display_order respected in variable picker ordering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template has 3 variables mapped: varA (display_order=2), varB (display_order=0), varC (display_order=1) | Variables mapped with different orders |
| 2 | Access getSchema($id) or variable picker tab for the template | Schema endpoint returns variables |
| 3 | Verify variables are returned in order: varB (0), varC (1), varA (2) | Order preserved |
| 4 | Verify junction table records have correct display_order values in DB | DB values match |

#### TC-TMP-P32: Junction table — default_value stored and retrievable per mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Map variable_id=5 to template with default_value="Default Text" | Junction record created |
| 2 | Map variable_id=6 to same template with default_value=NULL (no default) | Junction record created |
| 3 | Access getSchema endpoint | Schema returned |
| 4 | Verify variable_id=5 shows default_value="Default Text", variable_id=6 shows default_value=NULL | Correct defaults |

#### TC-TMP-P33: Create template with is_active=false (draft) — no variable_ids required

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter code="TMPL-DRAFT", name="Draft Template", type_id=valid, html_content="<p>Draft</p>" | Required fields set |
| 3 | Do NOT provide variable_ids array | No variables |
| 4 | Ensure is_active is NOT checked (defaults to false) | Draft mode |
| 5 | Submit | Success (activation gate only fires when is_active=true) |
| 6 | Verify template created with is_active=0 and zero junction records | Draft saved correctly |

#### TC-TMP-P34: Upload background image — valid JPEG under 2MB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with create or update permission POSTs to `POST template/upload-image` with a valid JPEG file (size < 2MB) | File sent |
| 2 | Gate::allows('create') OR Gate::allows('update') passes | Authorization OK |
| 3 | Validate file passes rules: `image|max:2048|mimes:jpg,jpeg,png` | Validation OK |
| 4 | Verify JSON response: `{"success": true, "url": "...", "path": "template-backgrounds/..."}` | File uploaded to public disk, response returned |

#### TC-TMP-P35: Upload background image — valid PNG under 2MB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `template/upload-image` with valid PNG file (size < 2MB) | File sent |
| 2 | File passes image / mimes:png validation | Validation OK |
| 3 | File stored in `template-backgrounds/` directory on public disk | Stored |
| 4 | Verify JSON response: `{"success": true, "url": "storage/template-backgrounds/...", "path": "template-backgrounds/..."}` | Response with url and path |

#### TC-TMP-P36: Preview sample — template with registered provider

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.view` permission calls GET `/template/{id}/preview-sample` | Endpoint called |
| 2 | Controller calls inferPurposeCode() on the template to determine purpose code | Purpose code inferred |
| 3 | Provider schema is resolved from the purpose code; buildSampleData() generates fake data | Schema and sample data built |
| 4 | renderById() renders the template HTML with the fake sample data | Rendered HTML |
| 5 | Verify view is returned with rendered HTML containing resolved placeholder values | Sample preview displayed |

#### TC-TMP-P37: Soft-delete template cascades to deactivate all linked assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template has one or more active records in `tmp_template_assignments` where `template_id` matches and `is_active = true` | Active assignments exist |
| 2 | Soft-delete the template via DELETE `/template/{id}` | Destroy called |
| 3 | Verify `tmp_template_assignments` records for the template have `is_active = false` (updated by controller before delete) | Assignments deactivated |

#### TC-TMP-P38: Create template — html_content sanitized via SanitizesRichText (full_math mode)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a template with html_content containing disallowed HTML tags (e.g. `<script>`, `onclick`) | HTML with potentially dangerous content |
| 2 | Submit create form with the html_content | Store called |
| 3 | Verify the Template model's SanitizesRichText trait strips/cleans the dangerous tags via full_math mode | Sanitized HTML stored |
| 4 | Retrieve the template from DB and verify html_content is clean (no `<script>` tags, no event handlers) | HTML sanitized |

### 10.2 Negative TC Steps — Template CRUD

#### TC-TMP-N01: Create — missing code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without code field | Validation error |
| 2 | Verify error: "The code field is required." | Error shown |

#### TC-TMP-N02: Create — duplicate code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template with code="DUP-CODE" already exists | Existing record |
| 2 | Submit create with code="DUP-CODE" | Validation error: "The code has already been taken." |

#### TC-TMP-N03: Create — code exceeds 50 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set code to a 51-character string | Exceeds max |
| 2 | Submit | Validation error: "The code must not be greater than 50 characters." |

#### TC-TMP-N04: Create — missing name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without name field | Validation error |
| 2 | Verify error: "The name field is required." | Error shown |

#### TC-TMP-N05: Create — name exceeds 255 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set name to a 256-character string | Exceeds max |
| 2 | Submit | Validation error: "The name must not be greater than 255 characters." |

#### TC-TMP-N06: Create — missing type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without type_id | Validation error |
| 2 | Verify error: "The type id field is required." | Error shown |

#### TC-TMP-N07: Create — invalid type_id (non-existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set type_id = 99999 (does not exist in tmp_templates_type) | Invalid FK |
| 2 | Submit | Validation error: "The selected type id is invalid." (exists rule) |

#### TC-TMP-N08: Create — invalid JSON in canvas_json

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set canvas_json = "{invalid-json-content}" | Malformed JSON |
| 2 | Submit | Validation error: "The canvas json must be a valid JSON string." |

#### TC-TMP-N09: Create — missing html_content

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without html_content | Validation error |
| 2 | Verify error: "The html content field is required." | Error shown |

#### TC-TMP-N10: Create — is_active=true with zero variable_ids (activation gate)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set is_active = true, do NOT provide variable_ids | Activation attempt without variables |
| 2 | Submit | withValidator fires: "A template cannot be activated unless at least one variable is mapped." |
| 3 | Verify validation error returned — template NOT created | Activation blocked |

#### TC-TMP-N11: Create — invalid variable_ids (non-existent variable)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set variable_ids = [99999] (variable does not exist in tmp_template_variables) | Invalid variable |
| 2 | Submit | Validation error: "Invalid variable selected." |

#### TC-TMP-N12: Create — variable_ids not an array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set variable_ids = "not-an-array" (string instead of array) | Wrong type |
| 2 | Submit | Validation error: "The variable ids must be an array." |

#### TC-TMP-N13: Toggle status — activate template with no mapped variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate a draft template (is_active=0) that has ZERO variables mapped | Draft with no variables |
| 2 | Attempt to toggle to active via AJAX | Request may succeed or be blocked depending on implementation |
| 3 | Verify controller logic — ideally toggleStatus should check variables count before activating | Activation gate parity |

#### TC-TMP-N14: Toggle status — missing is_active parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/templates/{id}/toggle-status` without is_active in request body | Validation error |
| 2 | Verify error: "The is active field is required." | Error returned |

#### TC-TMP-N15: Toggle status — non-boolean is_active value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/templates/{id}/toggle-status` with is_active="not-a-boolean" | Validation error |
| 2 | Verify error: "The is active field must be true or false." | Error returned |

#### TC-TMP-N16: Toggle status — non-existent template ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/template/99999/toggle-status` with is_active=true | Template 99999 doesn't exist |
| 2 | Verify 404 Not Found from findOrFail | 404 error |

#### TC-TMP-N17: Force delete — non-existent template ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/template/99999/force-delete` | Template 99999 doesn't exist |
| 2 | Verify 404 Not Found from withTrashed()->findOrFail | 404 error |

#### TC-TMP-N18: Restore — non-existent template ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/template/99999/restore` | Template 99999 doesn't exist |
| 2 | Verify 404 Not Found from onlyTrashed()->findOrFail | 404 error |

#### TC-TMP-N19: Permission — index without any tenant.template.* permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without any of the 7 template-related permissions accesses `/template` | 403 Forbidden |
| 2 | Verify Gate::any() fails and abort(403) is triggered | Aborted |

#### TC-TMP-N20: Permission — create without tenant.template.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.create` accesses `/template/create` | 403 Forbidden |

#### TC-TMP-N21: Permission — store without tenant.template.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.create` POSTs to `/template` | 403 Forbidden |

#### TC-TMP-N22: Permission — edit without tenant.template.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.update` accesses `/template/{id}/edit` | 403 Forbidden |

#### TC-TMP-N23: Permission — update without tenant.template.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.update` PUTs to `/template/{id}` | 403 Forbidden |

#### TC-TMP-N24: Permission — view show without tenant.template.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.view` accesses `/template/{id}` | 403 Forbidden |

#### TC-TMP-N25: Permission — view schema (getSchema) without tenant.template.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.view` GETs `/template/{id}/schema` | 403 Forbidden |

#### TC-TMP-N26: Permission — destroy without tenant.template.delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.delete` DELETEs `/template/{id}` | 403 Forbidden |

#### TC-TMP-N27: Permission — trashed without tenant.template.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.restore` accesses `/templates-trash` | 403 Forbidden |

#### TC-TMP-N28: Permission — restore without tenant.template.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.restore` POSTs to `/templates/{id}/restore` | 403 Forbidden |

#### TC-TMP-N29: Permission — forceDelete without tenant.template.forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.forceDelete` DELETEs `/templates/{id}/force-delete` | 403 Forbidden |

#### TC-TMP-N30: Permission — toggleStatus without tenant.template.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.update` POSTs to `/templates/{id}/toggle-status` | 403 Forbidden |

#### TC-TMP-N31: Force delete — template with existing assignments (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template has active assignments in `tmp_template_assignments` | Dependent records exist |
| 2 | Attempt forceDelete on that template via `/templates/{id}/force-delete` | Controller checks  `TemplateAssignment::withTrashed()->where('template_id', $id)->exists()` — blocks deletion |
| 3 | Verify error message: template has existing assignments, deletion denied | forceDelete fails; record remains |

#### TC-TMP-N32: Update — name exceeds 255 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit template, set name to 256-character string | Exceeds max |
| 2 | Submit update | Validation error: "The name must not be greater than 255 characters." |

#### TC-TMP-N33: Update — invalid type_id (non-existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit template, set type_id=99999 (does not exist) | Invalid FK |
| 2 | Submit update | Validation error: "The selected type id is invalid." |

#### TC-TMP-N34: Update — missing html_content

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit template, clear html_content field | Field empty |
| 2 | Submit update | Validation error: "The html content field is required." |

#### TC-TMP-N35: getSchema — non-existent template ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/template/99999/schema` | Template 99999 doesn't exist |
| 2 | Verify 404 Not Found from findOrFail | 404 error |

#### TC-TMP-N36: Upload background image — non-image file (PDF)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `template/upload-image` with a PDF file under 2MB | Non-image file sent |
| 2 | Verify validation error: the file fails `image` and `mimes:jpg,jpeg,png` rules | 422 validation error returned |

#### TC-TMP-N37: Upload background image — image exceeds 2MB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `template/upload-image` with a JPEG file > 2MB | Oversized image sent |
| 2 | Verify validation error: file fails `max:2048` rule (max 2MB = 2048KB) | 422 validation error returned |

#### TC-TMP-N38: Upload background image — no file in request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `template/upload-image` with no `image` file in the request | Empty request |
| 2 | Verify 400 error returned (or validation error that image is required) | 400 / 422 error |

#### TC-TMP-N39: Upload background image — upload without create or update permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.create` or `tenant.template.update` permission POSTs `template/upload-image` with a valid image | Unauthorized user |
| 2 | Verify 403 Forbidden returned — Gate::allows('create') and Gate::allows('update') both fail | 403 Forbidden |

#### TC-TMP-N40: Preview sample — template with no registered provider

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/template/{id}/preview-sample` for a template whose type has no registered provider | Template with no provider |
| 2 | inferPurposeCode() returns the purpose code but no provider schema is found | Schema resolution fails |
| 3 | Verify rendered HTML shows unresolved placeholders (raw `{{variable}}` syntax) or fallback content | Placeholders not resolved |

#### TC-TMP-N41: Preview sample — permission denied without tenant.template.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.view` permission calls GET `/template/{id}/preview-sample` | Unauthorized user |
| 2 | Verify 403 Forbidden returned | 403 Forbidden |

#### TC-TMP-N42: Toggle status — DB save failure returns 500 error JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate DB failure during toggleStatus() (e.g. disconnect DB, lock table) | Save failure condition |
| 2 | POST `/templates/{id}/toggle-status` with is_active=true | AJAX call made |
| 3 | Verify JSON error response: `{"success": false, "message": "..."}` with HTTP 500 status | 500 error JSON |

### 10.3 Code Review TC Steps

#### TC-CR01: tabView() — Gate::any() with 7 permissions + 5 tab routing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::any([...7 permissions...]) || abort(403)` at method start | Gate present |
| 2 | Review $filters extracted from $request->only(['search','status','type_id','tab']) | Filters extracted |
| 3 | Review 5 private query methods called with paginate() each with distinct page name | 5 query methods |
| 4 | Review each method gated by `$request->input('tab')` matching its key | Tab-gated execution |
| 5 | Review compact() return includes all 5 paginated datasets | All data passed to view |

#### TC-CR02: templatesQuery() — search and filter logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review tab check: `$request->input('tab') === 'all_templates'` (or equivalent) | Tab-gated |
| 2 | Review search: where like %term% on name, code, description, type.name with nested OR | Search logic across 4 fields |
| 3 | Review status filter: `where('is_active', $request->status)` | Status filter |
| 4 | Review default return: `$query->latest()` | Default ordering |

#### TC-CR03: draftsQuery() — scoped to is_active=false with search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review tab check: tab matches 'drafts' key | Tab-gated |
| 2 | Review `where('is_active', false)` or equivalent scope | Scoped to drafts |
| 3 | Review search applied on name, code, description | Search support |

#### TC-CR04: activeTemplatesQuery() — uses active() scope with search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review tab check: tab matches 'active' key | Tab-gated |
| 2 | Review `$query->active()` scope usage | Scope applied |
| 3 | Review search applied on name, code, description | Search support |

#### TC-CR05: trashedTemplatesQuery() — onlyTrashed() with search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review tab check: tab matches 'trashed' key | Tab-gated |
| 2 | Review `$query->onlyTrashed()` | Soft-delete scope |
| 3 | Review search applied on name, code, description | Search support |

#### TC-CR06: variablePickerQuery() — type_id filter and eager loading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review tab check: tab matches 'variable_picker' key | Tab-gated |
| 2 | Review `with(['variables' => fn($q) => $q->orderBy('display_order')])` | Eager loading with ordering |
| 3 | Review type_id filter: `when($request->type_id, fn($q) => $q->where('type_id', $request->type_id))` | Type filter |
| 4 | Review paginate() on the templates with their variables | Paginated |

#### TC-CR07: store() — Gate + validated + variable sync + activityLog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.create')` | Gate present |
| 2 | Review `Template::create($request->validated())` | Creation via validated data |
| 3 | Review `$template->variables()->sync($request->variable_ids ?? [])` | Variable sync |
| 4 | Review `activityLog($template, 'Stored', [...])` | Activity logged |
| 5 | Review `redirect()->route(...)->with('success', flash('created.template'))` | Flash success |

#### TC-CR08: update() — variable sync detection + activityLog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.update')` | Gate present |
| 2 | Review variable_ids extraction: `$variableIds = $request->variable_ids ?? []` | Variable extraction |
| 3 | Review `$template->variables()->sync($variableIds)` | Sync called |
| 4 | Review change detection — getChanges() for non-variable fields | Field change tracking |
| 5 | Review activityLog with variable sync information included | Variable change logged |

#### TC-CR09: destroy() — is_active=false before delete + activityLog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.delete')` | Gate present |
| 2 | Review `$template->is_active = false; $template->save();` before delete | Manual deactivation |
| 3 | Review `$template->delete()` — triggers SoftDeletes | Soft delete |
| 4 | Review activityLog with action='Trashed' and flash message | Activity + flash |

#### TC-CR10: restore() — onlyTrashed()->findOrFail + restore + save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.restore')` | Gate present |
| 2 | Review `Template::onlyTrashed()->findOrFail($id)` | Scoped to trashed only |
| 3 | Review `$template->restore(); $template->save();` | Restore then save |
| 4 | Review activityLog and flash redirect | Activity + flash |

#### TC-CR11: forceDelete() — withTrashed()->findOrFail + forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.forceDelete')` | Gate present |
| 2 | Review `Template::withTrashed()->findOrFail($id)` | Bypasses soft-delete scope |
| 3 | Review `$template->forceDelete()` and activityLog | Permanent delete + log |

#### TC-CR12: toggleStatus() — Gate + inline validation + AJAX JSON response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.update')` | Gate present |
| 2 | Review inline validation: `$request->validate(['is_active' => 'required|boolean'])` | Validation |
| 3 | Review `Template::findOrFail($id)` | Model binding |
| 4 | Review activityLog call before/after save | Activity logged |
| 5 | Review JSON success/error response based on `$template->save()` | AJAX JSON response |

#### TC-CR13: getSchema() — Gate + with() variables ordered + JSON response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.view')` | Gate present |
| 2 | Review `Template::with(['variables' => fn($q) => $q->orderBy('display_order')])->findOrFail($id)` | Eager load ordered variables |
| 3 | Review response: `response()->json($template)` or formatted array | JSON response |
| 4 | Review response structure includes template fields + nested variables array with pivot data | Schema format |

#### TC-CR14: StoreTemplateRequest — all field rules including unique code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review code: required|string|max:50|unique:tmp_templates,code | Unique code rule |
| 2 | Review name: required|string|max:255 | Name rule |
| 3 | Review type_id: required|integer|exists:tmp_templates_type,id | FK exists validation |
| 4 | Review canvas_json: nullable|json | JSON validation |
| 5 | Review variable_ids.*: integer|exists:tmp_template_variables,id | Variable FK validation |

#### TC-CR15: StoreTemplateRequest — withValidator activation gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `withValidator()` method override | withValidator present |
| 2 | Review conditional: if is_active=true AND (empty variable_ids) → add validation error | Activation gate logic |
| 3 | Review error message: "A template cannot be activated unless at least one variable is mapped." | Error message |

#### TC-CR16: UpdateTemplateRequest — code NOT in rules (immutable code)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review rules() method — code field is absent | Code not editable |
| 2 | Review name: required|string|max:255 still present | Name still required |
| 3 | Review type_id, html_content, variable_ids rules same as StoreTemplateRequest | Same other rules |

#### TC-CR17: TemplatePolicy — all 7 method signatures

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review viewAny(User) | Returns $user->can('tenant.template.viewAny') |
| 2 | Review view(User, Template) | Returns $user->can('tenant.template.view') |
| 3 | Review create(User) | Returns $user->can('tenant.template.create') |
| 4 | Review update(User, Template) | Returns $user->can('tenant.template.update') |
| 5 | Review delete(User, Template) | Returns $user->can('tenant.template.delete') |
| 6 | Review restore(User, Template) | Returns $user->can('tenant.template.restore') |
| 7 | Review forceDelete(User, Template) | Returns $user->can('tenant.template.forceDelete') |

#### TC-CR18: Template Model — fillable, casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$fillable` array — code, name, type_id, description, canvas_json, html_content, background_image, is_active | All 8 fillable fields |
| 2 | Review `$casts` — canvas_json⇒array | JSON cast to array |
| 3 | Review `$casts` — is_active⇒boolean | Boolean cast |
| 4 | Review `$casts` — type_id⇒integer | Integer cast |

#### TC-CR19: Template Model — SanitizesRichText trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `use SanitizesRichText` trait import | Trait present |
| 2 | Review trait configuration: full_math sanitization mode | full_math mode |
| 3 | Review html_content field is sanitized before save (via trait lifecycle hook) | Sanitization applied |

#### TC-CR20: Template Model — relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `type()` — belongsTo TemplateType::class | BelongsTo relationship |
| 2 | Review `variables()` — belongsToMany TemplateVariable::class with pivot table tmp_templates_variables_jnt | BelongsToMany with custom pivot |
| 3 | Review pivot fields: display_order, default_value, is_active | Pivot columns |
| 4 | Review `active()` scope — where('is_active', true) | Scope defined |

#### TC-CR21: Template Model — active() scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `scopeActive($query)` method | Method defined |
| 2 | Review `$query->where('is_active', true)` | Scope filters correctly |

#### TC-CR22: Variable syncing — sync() usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review store() calls `$template->variables()->sync($request->variable_ids ?? [])` | Sync in store |
| 2 | Review update() calls same sync pattern | Sync in update |
| 3 | Review that sync() detaches removed IDs and attaches new ones | Correct sync behaviour |
| 4 | Review that empty array `[]` detaches all variables | Empty sync works |

#### TC-CR23: SoftDeletes — deleted_at handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review Template model uses `SoftDeletes` trait | Trait present |
| 2 | Review deleted_at column in $casts or dates | Date casting |
| 3 | Review all query scopes respect SoftDeletes (trashed tab uses onlyTrashed, forceDelete uses withTrashed) | Scope awareness |

#### TC-CR24: uploadImage() — Gate::allows with create OR update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::allows('create') || Gate::allows('update')` | Gate check uses OR logic |
| 2 | Review that `abort(403)` is called when both gates deny | Forbidden on denial |
| 3 | Review that the Gate check happens before validation and storage | Early authorization |

#### TC-CR25: uploadImage() — validation rules (image, max:2048, mimes)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$request->validate(['image' => 'image|max:2048|mimes:jpg,jpeg,png'])` | Validation rules present |
| 2 | Review that `image` rule ensures uploaded file is an image | Image type check |
| 3 | Review that `max:2048` sets 2MB (2048KB) limit | Size limit |

#### TC-CR26: uploadImage() — storage path and filename generation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$request->file('image')->store('template-backgrounds', 'public')` | Store on public disk |
| 2 | Review that the returned path is used for the JSON response | Path used in response |
| 3 | Review that `url()` or `Storage::url()` generates the accessible URL | URL generated |

#### TC-CR27: uploadImage() — JSON response structure (success, url, path)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review JSON response: `return response()->json(['success' => true, 'url' => $url, 'path' => $path])` | JSON fields present |
| 2 | Review that `success` is boolean true | Success indicator |
| 3 | Review that `url` contains the full accessible URL and `path` contains the storage relative path | URL and path |

#### TC-CR28: previewSample() — inferPurposeCode + schema + buildSampleData + renderById pipeline

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review call to `inferPurposeCode()` on the template | Purpose code inferred |
| 2 | Review provider schema retrieval using the purpose code | Schema fetched |
| 3 | Review call to `buildSampleData()` with the schema to generate fake data | Sample data built |
| 4 | Review call to `renderById()` with the template ID and sample data, returning a view with rendered HTML | Render pipeline complete |

#### TC-CR29: inferPurposeCode() — active assignment returns correct purpose code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review that the method checks for an active assignment via `tmp_template_assignments` where `is_active = true` | Active assignment lookup |
| 2 | Review that when found, the assignment's `purpose_code` is returned directly | Purpose code returned |
| 3 | Review that the relationship query is efficient (no N+1) | Efficient query |

#### TC-CR30: inferPurposeCode() — no assignment, type name fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review the fallback logic: when no active assignment exists, derive purpose code from template type name | Fallback logic |
| 2 | Review that "Marksheet" type name maps to "MARKSHEET_PRINT" constant | Known mapping |
| 3 | Review that the mapping is handled via strtoupper / snake_case or a lookup array | Mapping mechanism |

#### TC-CR31: inferPurposeCode() — no assignment, unknown type → empty string

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review that when no assignment exists AND the type name does not match any known mapping | Unknown type |
| 2 | Review that the method returns an empty string `''` as fallback | Empty string returned |

#### TC-CR32: buildSampleData() — builds fake data array from schema variables + loops

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review that the method accepts a provider schema and iterates over its variables | Schema iteration |
| 2 | Review that for each variable, fake/placeholder data is generated based on variable type | Fake data generation |
| 3 | Review that loop variables (e.g. `{{#students}}...{{/students}}`) generate multiple sample rows | Loop expansion |
| 4 | Review that the returned array matches the structure expected by the renderer | Correct structure |

#### TC-CR33: defaultSample() — image type returns placeholder path, text returns 'Sample'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review that when variable type is `image`, a placeholder image URL/path is returned | Image placeholder |
| 2 | Review that when variable type is `text` (or string), the string `'Sample'` is returned | Text placeholder |
| 3 | Review that other types have sensible defaults (number → 0, date → today, etc.) | Other types handled |

#### TC-CR34: forceDelete() — background_image file deletion from storage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review that forceDelete() checks if the template has a `background_image` before deleting | Existence check |
| 2 | Review that `Storage::disk('public')->delete($template->background_image)` is called | File deleted from storage |
| 3 | Review that the file deletion happens before or after the `forceDelete()` call | Correct order |

#### TC-CR35: Template Model — SanitizesRichText trait with full_math mode on html_content

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `use SanitizesRichText` trait import in Template model | Trait imported |
| 2 | Review the trait configuration array specifying `full_math` sanitization mode for `html_content` | full_math mode configured |
| 3 | Review that the trait hooks into the model's `saving` or `saved` event to sanitize before persist | Lifecycle hook |

### 10.4 Dependency TC Steps

#### TC-D01: type_id FK → tmp_templates_type(id) — SET NULL on type delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template Type T1 has 3 template records referencing it | Referenced type |
| 2 | Delete T1 from tmp_templates_type | Deletion succeeds (SET NULL) |
| 3 | Verify all 3 templates now have type_id = NULL | FK set to null |

#### TC-D02: Junction FK → tmp_templates(id) — CASCADE on template delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template TMP-A has 5 variable mappings in tmp_templates_variables_jnt | Junction records exist |
| 2 | Force-delete TMP-A from tmp_templates | Template deleted |
| 3 | Verify all 5 junction records for template_id=TMP-A are also deleted | Cascade works |

#### TC-D03: Junction FK → tmp_template_variables(id) — CASCADE on variable delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Variable V1 is referenced by 2 template junction records | Referenced variable |
| 2 | Delete V1 from tmp_template_variables | Variable deleted |
| 3 | Verify both junction records with variable_id=V1 are also deleted | Cascade works |

#### TC-D04: code column — UNIQUE constraint at DB level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert template with code="UNIQUE-TEST" via direct DB query | Insert succeeds |
| 2 | Attempt to insert another template with code="UNIQUE-TEST" via direct DB query | DB error: Duplicate entry for key 'uq_tmp_template_code' |
| 3 | Verify application-level unique validation also catches this | Dual enforcement |

#### TC-D05: canvas_json — JSON column cast to array on Eloquent access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template has canvas_json = '{"key":"value"}' stored in DB | JSON stored |
| 2 | Access `$template->canvas_json` via Eloquent | Returns array ['key' => 'value'] (not string) |
| 3 | Verify `getCasts()` includes 'canvas_json' => 'array' | Cast defined |

#### TC-D06: is_active — boolean cast in model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template has is_active = 1 in DB (TINYINT) | Stored as integer |
| 2 | Access `$template->is_active` via Eloquent | Returns boolean true (not integer 1) |
| 3 | Verify `getCasts()` includes 'is_active' => 'boolean' | Cast defined |

#### TC-D07: Junction UNIQUE(template_id, variable_id) — prevents duplicates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template TMP-A has variable V1 mapped | Existing mapping |
| 2 | Attempt to insert another junction row with same template_id=TMP-A and variable_id=V1 via direct DB | DB error: Duplicate entry for UNIQUE constraint |
| 3 | Verify sync() does not attempt to create duplicates (sync is idempotent) | App-level safety |

#### TC-D08: SoftDeletes — trashed templates excluded from active() scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template is active (is_active=1) and NOT deleted (deleted_at=NULL) | Active, not trashed |
| 2 | Soft-delete the template (deleted_at=now, is_active=0) | Trashed |
| 3 | Run `Template::active()->get()` | Trashed template NOT included (deleted_at filter also applied via SoftDeletes global scope) |

#### TC-D09: API route — apiResource('templates') with auth:sanctum middleware

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review API route file for `Route::apiResource('templates', TemplateController::class)` | apiResource defined |
| 2 | Review that the route group applies `auth:sanctum` middleware | Sanctum auth enforced |
| 3 | Review that all 5 API actions (index, store, show, update, destroy) are registered | Full resource registered |

#### TC-D10: API route — tenancy + module middleware present

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review route group for tenancy middleware (e.g. `tenancy` or `InitializeTenancy`) | Tenancy middleware present |
| 2 | Review route group for module middleware (e.g. `module` or `web`/`api` module scope) | Module middleware present |
| 3 | Review middleware ordering — tenancy initialized before module routing | Correct order |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/template` | template.index | tabView() | Any of 7 template permissions |
| GET | `/template/create` | template.create | create() | tenant.template.create |
| POST | `/template` | template.store | store() | tenant.template.create |
| GET | `/template/{template}` | template.show | show() | tenant.template.view |
| GET | `/template/{template}/edit` | template.edit | edit() | tenant.template.update |
| PUT | `/template/{template}` | template.update | update() | tenant.template.update |
| DELETE | `/template/{template}` | template.destroy | destroy() | tenant.template.delete |
| GET | `/templates-trash` | template.trashed | trashed() | tenant.template.restore |
| GET | `/templates/{id}/restore` | template.restore | restore() | tenant.template.restore |
| DELETE | `/templates/{id}/force-delete` | template.forceDelete | forceDelete() | tenant.template.forceDelete |
| POST | `/templates/{id}/toggle-status` | template.toggleStatus | toggleStatus() | tenant.template.update |
| GET | `/template/{id}/schema` | template.schema | getSchema() | tenant.template.view |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | tabView() Gate uses Gate::any() with 7 permissions OR abort(403) | **Medium** | Comment in code notes this pattern is a workaround; any single permission grants full dashboard access |
| KI-02 | destroy() manually sets is_active=false before delete — redundant with SoftDeletes | **Low** | SoftDeletes already marks deleted_at; manual is_active=false is unnecessary |
| KI-03 | toggleStatus() uses tenant.template.update instead of a dedicated status permission | **Low** | No dedicated `tenant.template.status` permission exists; status toggle reuses update permission |
| KI-04 | ~~No pre-deletion check for dependent assignments before forceDelete~~ (removed — forceDelete DOES check: `TemplateAssignment::withTrashed()->where('template_id', $id)->exists()` and blocks with error) | — | — |
| KI-05 | ~~toggleStatus() does not replicate withValidator activation gate~~ (removed — toggleStatus DOES check: `if ($request->is_active && $template->variables()->count() === 0)` returns 422) | — | — |
| KI-06 | UpdateTemplateRequest authorize() returns true | **Medium** | No Gate check in FormRequest — defence-in-depth collapsed; relies solely on controller Gate |
| KI-07 | tabView() returns a unified dashboard, not a dedicated template list page | **Info** | Single page handles 5 data types (all templates, drafts, active, trashed, variable picker) |
| KI-08 | SanitizesRichText full_math config may strip certain HTML tags | **Low** | full_math sanitization mode may remove or transform HTML elements that are valid for template rendering |
| KI-09 | canvas_json validated as JSON string but not schema-validated | **Low** | Any valid JSON passes validation — no structural schema validation for canvas component structure |
| KI-10 | background_image stored as plain string path — no file existence validation | **Low** | Validation only checks string type; does not verify the file actually exists at the given path |

---

## 13. Feature Summary Matrix

| Feature | Controller Method(s) | Key Models | Pagination |
|---------|---------------------|------------|------------|
| Template List (All Tab) | tabView() + templatesQuery() | Template | Paginated |
| Drafts Tab | tabView() + draftsQuery() | Template (is_active=0) | Paginated |
| Active Tab | tabView() + activeTemplatesQuery() | Template (is_active=1 via active()) | Paginated |
| Trashed Tab | tabView() + trashedTemplatesQuery() | Template (onlyTrashed) | Paginated |
| Variable Picker Tab | tabView() + variablePickerQuery() | Template, TemplateVariable | Paginated |
| Create Template | create(), store() | Template, TemplateVariable (junction) | None (form) |
| View Template | show() | Template | None |
| Edit Template | edit(), update() | Template, TemplateVariable (junction) | None (form) |
| Soft-Delete / Restore | destroy(), trashed(), restore() | Template | Paginated (trash) |
| Force Delete | forceDelete() | Template | None |
| Toggle Status | toggleStatus() | Template | None (AJAX) |
| Schema Preview | getSchema() | Template, TemplateVariable | None (JSON) |
| **TC Count** | **Positive: 38 / Negative: 42 / Code Review: 35 / Dependency: 10** | **Total: 125** | |
