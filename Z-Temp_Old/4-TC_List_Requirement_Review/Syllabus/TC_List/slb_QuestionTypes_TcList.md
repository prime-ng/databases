# slb_question_types_TcList

## Module: Syllabus → Syllabus Master → Question Types

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Syllabus Master |
| Feature | Question Types |
| URL(s) | `/syllabus/bloom` (index via tab), `/syllabus/question-types/create` (create), `/syllabus/question-types` (store), `/syllabus/question-types/{id}` (show), `/syllabus/question-types/{id}/edit` (edit), `/syllabus/question-types/{id}` (update), `/syllabus/question-types/trash/view` (trash), `/syllabus/question-types/{id}/restore` (restore), `/syllabus/question-types/{id}/force-delete` (forceDelete), `/syllabus/question-types/{id}/toggle-status` (toggleStatus) |
| Controller | `Modules\Syllabus\Http\Controllers\QuestionTypeController` |
| Model(s) | `Modules\Syllabus\Models\QuestionType` |
| Validation (Create) | `Modules\Syllabus\Http\Requests\QuestionTypeRequest` |
| Validation (Update) | `Modules\Syllabus\Http\Requests\QuestionTypeRequest` (ignores current ID for unique) |
| Permissions | `tenant.question-type.viewAny`, `tenant.question-type.view`, `tenant.question-type.create`, `tenant.question-type.update`, `tenant.question-type.delete`, `tenant.question-type.restore`, `tenant.question-type.forceDelete`, `tenant.question-type.status` |
| Soft Deletes | Yes (`QuestionType` uses `SoftDeletes` trait) |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |
| Import | Not supported |
| **SPECIAL** | `is_system` guard — system-defined records cannot be modified, deleted, force-deleted, or toggled |

---

## 2. Pre-conditions

- Required permissions: `tenant.question-type.viewAny`, `tenant.question-type.view`, `tenant.question-type.create`, `tenant.question-type.update`, `tenant.question-type.delete`, `tenant.question-type.restore`, `tenant.question-type.forceDelete`, `tenant.question-type.status`
- Required seed data: At least one system-defined record (`is_system = true`) for guard testing
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

---

## 3. Default Data Load

When the page loads via SyllabusController@bloom() (GET /syllabus/bloom), the following data is fetched and passed to the view:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: Cognitive Skills (dropdown) | SyllabusController@bloom() | CognitiveSkill::where(is_active,1) | is_active=1 | None |
| Bloom Taxonomies Grid | getBloomTaxonomies() | BloomTaxonomy | search(name,code), filter(level,status) | 10/page (bloom_taxonomies_page)
| Cognitive Skills Grid | getCognitiveSkills() | CognitiveSkill::with(bloomTaxonomy) | search(name,code), filter(bloom_id,status) | 10/page (cognitive_skills_page)
| Question Type Specificities Grid | getQueTypeSpecificities() | QueTypeSpecifity::with(cognitiveSkill) | search(name,code), filter(cognitive_skill_id,status) | 10/page (question_type_specificities_page)
| Question Types Grid | getQuestionTypes() | QuestionType | search(name,code), filter(status) | 10/page (question_types_page)
| Complexity Levels Grid | getComplexityLevels() | ComplexityLevel | search(name,code), filter(level,status) | 10/page (complexity_levels_page)
## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Question type code**: Uppercase alphanumeric, max 20 chars, globally unique
- **System guard**: Records with `is_system = true` are protected from modify/delete/toggle
- **Pre-test cleanup**: Delete created non-system records by code before/after tests to avoid collisions
- **JSON fields**: None

---

## 5. Business Conditions

### 4.1 Database Schema — `slb_question_types`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | code | VARCHAR(20) | NOT NULL, UNIQUE |
| BC-DB-03 | name | VARCHAR(100) | NOT NULL |
| BC-DB-04 | has_options | TINYINT(1) | DEFAULT NULL (cast to boolean) |
| BC-DB-05 | auto_gradable | TINYINT(1) | DEFAULT NULL (cast to boolean) |
| BC-DB-06 | description | TEXT | DEFAULT NULL |
| BC-DB-07 | is_system | TINYINT(1) | DEFAULT NULL (cast to boolean) |
| BC-DB-08 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 (cast to boolean) |
| BC-DB-09 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-10 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-11 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules — `QuestionTypeRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | code | required, string, max:20, unique:slb_question_types,code | "Question type code is required." |
| BC-VAL-02 | code | unique | "This question type code already exists." |
| BC-VAL-03 | name | required, string, max:100 | "Question type name is required." |
| BC-VAL-04 | name | max:100 | "Name must not exceed 100 characters." |
| BC-VAL-05 | has_options | nullable, boolean | — |
| BC-VAL-06 | auto_gradable | nullable, boolean | — |
| BC-VAL-07 | description | nullable, string | — |
| BC-VAL-08 | is_system | nullable, boolean | — |
| BC-VAL-09 | is_active | nullable, boolean | — |

### 4.3 Validation Rules — `QuestionTypeRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | code | required, string, max:20, unique:slb_question_types,code + ignore($id) | "Question type code is required." |
| BC-VAL-U02 | code | unique + ignore | "This question type code already exists." |
| BC-VAL-U03 | name | required, string, max:100 | "Question type name is required." |
| BC-VAL-U04 | name | max:100 | "Name must not exceed 100 characters." |
| BC-VAL-U05 | has_options | nullable, boolean | — |
| BC-VAL-U06 | auto_gradable | nullable, boolean | — |
| BC-VAL-U07 | description | nullable, string | — |
| BC-VAL-U08 | is_system | nullable, boolean | — |
| BC-VAL-U09 | is_active | nullable, boolean | — |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.question-type.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.question-type.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.question-type.create | store(), create() | Without → 403 |
| BC-AUTH-04 | tenant.question-type.update | update(), edit(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.question-type.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.question-type.restore | restore(), trashed() | Without → 403 |
| BC-AUTH-07 | tenant.question-type.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.question-type.status | toggleStatus() (via update gate) | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-02 | Default is_active on create | Defaults to true |
| BC-BIZ-03 | Code auto-uppercase | `strtoupper(trim($code))` applied in `prepareForValidation()` |
| BC-BIZ-04 | Delete sets is_active false | `destroy()` sets `is_active = false` before `delete()` |
| BC-BIZ-05 | Restore sets is_active true | `restore()` sets `is_active = true` |
| BC-BIZ-06 | Status toggle (non-system) | `is_active` flips; returns JSON `{success, is_active, message}` |
| BC-BIZ-07 | System guard — Update | If `is_system` is true, `update()` redirects with error "System-defined question types cannot be modified." |
| BC-BIZ-08 | System guard — Delete (soft) | If `is_system` is true, `destroy()` redirects with error "System-defined question types cannot be deleted." |
| BC-BIZ-09 | System guard — Force Delete | If `is_system` is true, `forceDelete()` redirects with error "System-defined question types cannot be permanently deleted." |
| BC-BIZ-10 | System guard — Toggle Status | If `is_system` is true, `toggleStatus()` returns JSON 403 `{success: false, message: "System-defined question types status cannot be changed."}` |
| BC-BIZ-11 | Show uses withTrashed | `show()` calls `withTrashed()->findOrFail($id)` |
| BC-BIZ-12 | Pagination | Index paginated at 10 per page |
| BC-BIZ-13 | Activity log — Stored | On create |
| BC-BIZ-14 | Activity log — Updated | On update |
| BC-BIZ-15 | Activity log — Trashed | On soft delete |
| BC-BIZ-16 | Activity log — Restored | On restore |
| BC-BIZ-17 | Activity log — Deleted | On force delete |
| BC-BIZ-18 | Activity log — Toggled | On status toggle |
| BC-BIZ-19 | Redirect after CRUD | Redirect to `syllabus.bloom.index` with tab `question_types` |
| BC-BIZ-20 | Screen loads via SyllabusController@bloom() at GET /syllabus/bloom with bloom tab group | Navigating to GET /syllabus/bloom with appropriate permissions loads the Bloom tab group; this screen's grid data is fetched and displayed |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| — | question_type_id (in slb_question_bank) | slb_question_types (id) | Not declared in DDL (validated in request) |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Question Types List Page Loads With All UI Elements | Page loads with Add New, Trash, search, table columns: Code, Name, Has Options, Auto Gradable, System, Status, Actions | — | — | ⬜ |
| TC-P02 | Search By Name Or Code | Table filters correctly | — | — | ⬜ |
| TC-P03 | Filter By Active/Inactive Status | Filter works correctly | — | — | ⬜ |
| TC-P04 | Create Question Type With All Required Fields | Record created with code, name | — | — | ⬜ |
| TC-P05 | Create Question Type With Has Options = True | has_options = 1 saved | — | — | ⬜ |
| TC-P06 | Create Question Type With Auto Gradable = True | auto_gradable = 1 saved | — | — | ⬜ |
| TC-P07 | Create Question Type As Non-System (is_system = false) | is_system = 0; record can be modified/deleted | — | — | ⬜ |
| TC-P08 | Create Question Type With All Boolean Flags | has_options, auto_gradable, is_system, is_active all set | — | — | ⬜ |
| TC-P09 | Create With Code Auto-Uppercase | Code `mcq` stored as `MCQ` | — | — | ⬜ |
| TC-P10 | Edit Non-System Question Type Loads Pre-Filled Data | Edit form shows existing data | — | — | ⬜ |
| TC-P11 | Update Non-System Question Type All Fields | All fields updated successfully | — | — | ⬜ |
| TC-P12 | View Question Type Details Page | Details shown with all field values | — | — | ⬜ |
| TC-P13 | Soft Delete Non-System Question Type | `deleted_at` set | — | — | ⬜ |
| TC-P14 | Trash Page Shows Deleted Non-System Records | Trash page lists only soft-deleted records | — | — | ⬜ |
| TC-P15 | Restore Non-System Question Type From Trash | `deleted_at` = NULL; activity log "Restored" | — | — | ⬜ |
| TC-P16 | Force Delete Non-System Question Type (No Dependencies) | Record permanently removed | — | — | ⬜ |
| TC-P17 | Toggle Status Non-System Record Active ↔ Inactive | `is_active` flips; AJAX 200 | — | — | ⬜ |
| TC-P18 | Pagination Works (10 Per Page) | Pagination links with 11+ records | — | — | ⬜ |
| TC-P19 | Full Lifecycle (Non-System): Create → Edit → Toggle → Delete → Trash → Restore → Force Delete | All transitions successful | — | — | ⬜ |
| TC-P20 | Empty State — No Records Yet | "No records found" message; Add New visible | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing Code | "Question type code is required." | — | — | ⬜ |
| TC-N02 | Required — Missing Name | "Question type name is required." | — | — | ⬜ |
| TC-N03 | Invalid Code — Exceeds 20 Characters | code.max validation fails | — | — | ⬜ |
| TC-N04 | Duplicate Code (Global Unique) | "This question type code already exists." | — | — | ⬜ |
| TC-N05 | Max Length — Name > 100 Characters | name.max validation fails | — | — | ⬜ |
| TC-N06 | View Record With Invalid ID (404) | HTTP 404 | — | — | ⬜ |
| TC-N07 | Edit/Update Record With Invalid ID (404) | HTTP 404 | — | — | ⬜ |
| TC-N08 | Delete Record With Invalid ID (404) | Redirect with error | — | — | ⬜ |
| TC-N09 | Toggle Status With Invalid ID (404) | JSON 404 | — | — | ⬜ |
| TC-N10 | Restore Non-Deleted Record (Already Active) | 404 error | — | — | ⬜ |
| TC-N11 | Force Delete Non-Trashed Record | 404 error | — | — | ⬜ |
| TC-N12 | Permission 403 — No Question Type Permissions | 403 on all CRUD | — | — | ⬜ |
| TC-N13 | Guest Access Redirect | Redirected to /login | — | — | ⬜ |
| TC-N14 | XSS Injection In Name/Code | Stored as literal; Blade escapes | — | — | ⬜ |
| TC-N15 | Whitespace-Only Name/Code | Required validation catches | — | — | ⬜ |
| TC-N16 | Max Length — description > 255 Characters | description.max validation fails (max:255 in QuestionTypeRequest) | — | — | ⬜ |
| TC-N17 | System Guard — Update System-Defined Record | "System-defined question types cannot be modified." | — | — | ⬜ |
| TC-N18 | System Guard — Delete System-Defined Record | "System-defined question types cannot be deleted." | — | — | ⬜ |
| TC-N19 | System Guard — Force Delete System-Defined Record | "System-defined question types cannot be permanently deleted." | — | — | ⬜ |
| TC-N20 | System Guard — Toggle Status On System-Defined Record | JSON 403: "System-defined question types status cannot be changed." | — | — | ⬜ |
| TC-N21 | Update System Record Via API Bypass | Controller guard still blocks with error message | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | System Records Persist After Soft Delete Attempt | System record cannot be soft-deleted; remains active | — | — | ⬜ |
| TC-D02 | B | Non-System Only Records Appear In Trash | System records never appear in trash (cannot be deleted) | — | — | ⬜ |
| TC-D03 | C | Toggle Status — Inactive Non-System Record Hidden From Question Bank Dropdown | Inactive type hidden from question creation | — | — | ⬜ |
| TC-D04 | D | UI/API — P1 — slb_question_types with is_system=1 — System-Protected Record — is_system Restriction | System-defined question types (is_system=1) cannot be edited or deleted by school users; only viewable; is_system=0 records are editable | — | — | ⬜ |
| TC-D05 | E | DB — P1 — slb_question_types with existing record — Boolean Field Validation — has_options, auto_gradable, is_system, is_active | Boolean fields accept only 0/1 values; invalid values are rejected at DB level (TINYINT(1)) | — | — | ⬜ |
| TC-D06 | Model | Model: $table Property Set to 'slb_question_types' | $table property correctly maps to the database table name | — | — | ⬜ |
| TC-D07 | Model | Model: $fillable Contains All Editable Columns | $fillable includes code, name, description, has_options, auto_gradable, is_default, is_system, is_active | — | — | ⬜ |
| TC-D08 | Model | Model: $casts Defined for Boolean Fields | Boolean cast on has_options, auto_gradable, is_system, is_active | — | — | ⬜ |
| TC-D09 | Model | Model: SoftDeletes Trait Imported and Used | SoftDeletes trait manages deleted_at column for soft deletes | — | — | ⬜ |
| TC-D10 | Model | Model: No Relationships Defined | No relationship methods exist (master/reference data pattern) | — | — | ⬜ |
| TC-D11 | Controller | Controller: index() Paginates at 10 Per Page | Pagination logic set to 10 records per page | — | — | ⬜ |
| TC-D12 | Controller | Controller: store() — Create, Log Activity, Redirect | Creates question type, logs Stored event, redirects to bloom index | — | — | ⬜ |
| TC-D13 | Controller | Controller: update() — Guard, Update, Log, Redirect | Checks is_system guard, updates record, logs Updated, redirects | — | — | ⬜ |
| TC-D14 | Controller | Controller: destroy() — Set is_active=false Before Soft Delete | Sets is_active=0, logs Trashed, soft deletes, redirects | — | — | ⬜ |
| TC-D15 | Controller | Controller: restore() — Restore, Set is_active=true, Log | Restores record, sets is_active=1, logs Restored, redirects | — | — | ⬜ |
| TC-D16 | Controller | Controller: toggleStatus() — Flip is_active, Return JSON | Flips is_active, logs Toggled, returns JSON {success, is_active, message} | — | — | ⬜ |
| TC-D17 | Controller | Controller: System Guard on All Protected Operations | All guarded methods check is_system before update/delete/toggle/forceDelete | — | — | ⬜ |
| TC-D18 | Request | Request: prepareForValidation() Uppercases Code | strtoupper(trim($code)) applied before validation rules run | — | — | ⬜ |
| TC-D19 | Request | Request: Update Unique Rule Ignores Current ID | unique:slb_question_types,code ignores current record ID on update | — | — | ⬜ |
| TC-D20 | Policy | Policy: All Authorization Gates Defined | viewAny/view/create/update/delete/restore/forceDelete/status gates implemented | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.question-type.create'), @can('tenant.question-type.edit'), @can('tenant.question-type.delete'), @can('tenant.question-type.status'), @can('tenant.question-type.view'), @canany(['tenant.question-type.restore', 'tenant.question-type.forceDelete']) for access control on all CRUD buttons and actions | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | `syllabus.bloom` key → `'syllabus/bloom'` defined in `config/breadcrumb.php`; breadcrumb visible and links correctly to parent screen | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Relationship expressions in Blade use isset($var->relation) / optional($var?->relation) / null-safe operator; no undefined index/property errors when relation is null | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | View — Success Flash Messages After Create/Update/Delete | After CRUD actions, controller redirects with success flash; Blade displays success alert with correct action-specific message | — | — | ◌ |


---



## 7. Detailed Test Steps



#### TC-CR05: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open index.blade.php for this screen | View file found in lesson-management/partials/
| 2 | Scan for relationship access patterns (e.g. $record->relation->field) | All such expressions use isset() or optional() or ?-> null-safe operator
| 3 | Scan for foreach loops over relationships | Loop target checked with isset() or !empty() before iterating
| 4 | Create a record with null relationship | View renders without undefined index/property error
| 5 | Load index page with records that have missing relations | No 500 errors; null values displayed gracefully (dash or empty string)


#### TC-CR06: View — Success Flash Messages After Create/Update/Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new record | POST to store(); redirects with session flash
| 2 | Verify success message after create | Page shows success alert: ‘Complexity level created successfully’ (or equivalent for this screen)
| 3 | Update the record | PUT/PATCH to update(); redirects with flash
| 4 | Verify success message after update | ‘Complexity level updated successfully’ (or equivalent)
| 5 | Soft delete the record | DELETE to destroy(); redirects with flash
| 6 | Verify success message after delete | ‘Complexity level trashed successfully’ (or equivalent)
| 7 | Restore from trash | POST to restore(); redirects with flash
| 8 | Verify success message after restore | ‘Complexity level restored successfully’ (or equivalent)
| 9 | Force delete from trash | DELETE to forceDelete(); redirects with flash
| 10 | Verify success message after force delete | ‘Complexity level force deleted successfully’ (or equivalent)


#### TC-CR01: Blade @can Directives — Permission-based Visibility for All Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php for add/create button | @can('tenant.question-type.create') wraps the Add New button; user without create permission does not see it
| 2 | Inspect row-level action buttons (view, edit, delete, status toggle) | @can('tenant.question-type.view'), @can('tenant.question-type.edit'), @can('tenant.question-type.delete'), @can('tenant.question-type.status') used appropriately; expired permissions hide corresponding buttons
| 3 | Inspect trash.blade.php for restore/forceDelete buttons | @canany(['tenant.question-type.restore', 'tenant.question-type.forceDelete']) wraps action buttons in trash view
| 4 | Inspect view.blade.php for edit button | @can('tenant.question-type.edit') wraps the Edit button on show/details page
| 5 | Log in as user with all permissions | All buttons visible and functional |
| 6 | Log in as user with viewAny only (no create/edit/delete) | Add New button hidden; action columns show view icon only or no actions |

#### TC-CR02: Breadcrumb Config — Route Registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File contains routing configuration for the syllabus module |
| 2 | Verify the 'syllabus.bloom' key exists | Config has 'syllabus.bloom' => 'syllabus/bloom' entry
| 3 | Verify its value points to the correct parent screen URL | Value 'syllabus/bloom' correctly references Bloom tab view
| 4 | Load the screen via the Bloom tab tab | Breadcrumb trail shows correct hierarchy and highlights current screen |
| 5 | Click the breadcrumb parent link | Navigates correctly to Bloom tab page without errors |
### 6.1 Positive TC Steps

#### TC-P01: Question Types List Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login, navigate to Syllabus → Syllabus Master → Question Types tab | Page loads |
| 2 | Check search, status filter, Add New, Trash, table columns | All UI elements present |

---

#### TC-P02: Search By Name Or Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create "MCQ" (code="MCQ_SINGLE"), "Essay" (code="ESSAY") | Records exist |
| 2 | Search "MCQ" | Only MCQ visible |
| 3 | Search "ESSAY" | Only Essay visible |

---

#### TC-P03: Filter By Active/Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active and inactive records | Both exist |
| 2 | Filter "Active" | Only active |
| 3 | Filter "Inactive" | Only inactive |

---

#### TC-P04: Create Question Type With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add New", enter code="MCQ_SINGLE", name="Multiple Choice" | Fields filled |
| 2 | Click "Save" | POST to store |
| 3 | Check response | Success message |
| 4 | DB check: record exists | is_active=1, is_system=0 |

---

#### TC-P05: Create Question Type With Has Options = True

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, enter code="MCQ_OPT", name="MCQ With Options" | Fields set |
| 2 | Set has_options = true | Toggle ON |
| 3 | Click "Save" | Record created |
| 4 | DB check: has_options = 1 | Saved correctly |

---

#### TC-P06: Create Question Type With Auto Gradable = True

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code="AUTO_GRADE", name="Auto Gradable Type" | Fields set |
| 2 | Set auto_gradable = true | Toggle ON |
| 3 | Click "Save" | Record created |
| 4 | DB check: auto_gradable = 1 | Saved correctly |

---

#### TC-P07: Create Question Type As Non-System (is_system = false)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code="CUSTOM_TYPE", name="Custom Type", is_system = false | Non-system |
| 2 | Click "Save" | Record created |
| 3 | DB check: is_system = 0 | Can be modified/deleted later |

---

#### TC-P08: Create Question Type With All Boolean Flags

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code="FULL_FLAGS", name="Full Flags Type" | Fields set |
| 2 | Set has_options=true, auto_gradable=true, is_system=false, is_active=true | All toggles ON |
| 3 | Click "Save" | Record created |
| 4 | DB check: all boolean fields = 1 | Saved correctly |

---

#### TC-P09: Create With Code Auto-Uppercase

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code: "mcq_single" (lowercase) | Lowercase |
| 2 | Click "Save" | Record created |
| 3 | DB check: code = "MCQ_SINGLE" | Uppercased |

---

#### TC-P10: Edit Non-System Question Type Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create non-system record "EDITTEST" | Exists |
| 2 | Click "Edit" | Form pre-filled with all field values |

---

#### TC-P11: Update Non-System Question Type All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create non-system record, edit it | Form loaded |
| 2 | Change code, name, has_options, auto_gradable, description, is_active | All updated |
| 3 | Click "Save" | Update succeeds |

---

#### TC-P12: View Question Type Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record, click "View" | All fields displayed |

---

#### TC-P13: Soft Delete Non-System Question Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Non-system record, click delete, confirm | Soft deleted |
| 2 | DB check: deleted_at NOT NULL | Trashed |

---

#### TC-P14: Trash Page Shows Deleted Non-System Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete non-system record | In trash |
| 2 | Click "Trash" | Shows deleted record |

---

#### TC-P15: Restore Non-System Question Type From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate trash, click "Restore", confirm | Restored |
| 2 | Activity log "Restored" | Logged |

---

#### TC-P16: Force Delete Non-System Question Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete → force delete | Permanently removed |

---

#### TC-P17: Toggle Status Non-System Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Non-system active record, toggle | is_active flips |
| 2 | Toggle again | Flips back |

---

#### TC-P18: Pagination Works (10 Per Page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 11+ records | Exist |
| 2 | Check pagination | Page 1: 10 records |

---

#### TC-P19: Full Lifecycle (Non-System)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create → Edit → Toggle → Soft Delete → Trash → Restore → Soft Delete → Force Delete | All successful |

---

#### TC-P20: Empty State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate with no records | "No records found" |

---

### 6.2 Negative TC Steps

#### TC-N01: Required — Missing Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, leave code empty | Code missing |
| 2 | Click "Save" | HTTP 500: "Question type code is required." |

---

#### TC-N02: Required — Missing Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, leave name empty | Name missing |
| 2 | Click "Save" | HTTP 500: "Question type name is required." |

---

#### TC-N03: Invalid Code — Exceeds 20 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code of 21 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500 |

---

#### TC-N04: Duplicate Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with code="DUPTEST" | Exists |
| 2 | Create another with same code | HTTP 500: "This question type code already exists." |

---

#### TC-N05: Max Length — Name > 100 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter name of 101 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500 |

---

#### TC-N06: View Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `/syllabus/question-types/99999` | HTTP 404 |

---

#### TC-N07: Edit/Update Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit with invalid ID | HTTP 404 |
| 2 | PUT to invalid ID | HTTP 404 |

---

#### TC-N08: Delete Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE to invalid ID | Redirect with error |

---

#### TC-N09: Toggle Status With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST toggle-status invalid ID | JSON 404 |

---

#### TC-N10: Restore Non-Deleted Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active record, try restore | 404 |

---

#### TC-N11: Force Delete Non-Trashed Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active record, try force delete | 404 |

---

#### TC-N12: Permission 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without permissions | 403 on all CRUD |

---

#### TC-N13: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate | Redirected to login |

---

#### TC-N14: XSS Injection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with XSS payload | Stored literal, not executed |

---

#### TC-N15: Whitespace-Only Name/Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter whitespace-only values | Validation fails |

---



---

#### TC-N17: System Guard — Update System-Defined Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate a system-defined record (is_system = true) | Record exists |
| 2 | Navigate to edit page | Edit page loads (read-only or guarded) |
| 3 | Attempt to update | Redirect with error: "System-defined question types cannot be modified." |
| 4 | DB check: record unchanged | No modification applied |

---

#### TC-N18: System Guard — Delete System-Defined Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate a system-defined record | Record exists |
| 2 | Click delete button, confirm | Redirect with error: "System-defined question types cannot be deleted." |
| 3 | DB check: deleted_at still NULL | Record not soft-deleted |

---

#### TC-N19: System Guard — Force Delete System-Defined Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Try to soft delete system record (blocked), can't get to trash | Guard prevents all deletion paths |
| 2 | Direct POST to force-delete URL for system record | Redirect with error: "System-defined question types cannot be permanently deleted." |

---

#### TC-N20: System Guard — Toggle Status On System-Defined Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate a system-defined record | Record exists |
| 2 | Click toggle switch | AJAX POST to toggle-status |
| 3 | Check response | JSON 403: `{success: false, message: "System-defined question types status cannot be changed."}` |
| 4 | DB check: is_active unchanged | Status not flipped |

---

#### TC-N21: Update System Record Via API Bypass

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send direct PUT request to update system record | Controller guard blocks with error message |

---

#### TC-N16: Max Length — description > 255 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, enter a description of 256 characters | Exceeds max length |
| 2 | Click "Save" | HTTP 500: validation error for description.max (max:255) |
| 3 | Open Add New, enter a description of exactly 255 characters | Boundary value (exactly max) |
| 4 | Click "Save" | Record created successfully |

---

### 6.3 Dependency TC Steps

#### TC-D01: System Records Persist After Soft Delete Attempt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | System record (is_system = true) | Exists |
| 2 | Attempt to delete | Blocked with error |
| 3 | Verify record still active and visible | Not deleted |

---

#### TC-D02: Non-System Only Records Appear In Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete non-system record | In trash |
| 2 | Verify system records never appear in trash (cannot be deleted) | Only non-system in trash |

---

#### TC-D03: Toggle Status — Inactive Non-System Record Hidden From Question Bank Dropdown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active non-system question type | Active |
| 2 | Toggle to inactive | is_active = 0 |
| 3 | Navigate to question bank create form | Inactive type NOT in question type dropdown |
| 4 | Toggle back to active | Appears again |

---

#### TC-D04: System-Protected Record — is_system Restriction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate a system-defined question type where is_system = 1 | Record exists |
| 2 | Attempt to edit the system-defined record via UI | Edit blocked; error message displayed |
| 3 | Attempt to delete the system-defined record via UI | Delete blocked; error message displayed |
| 4 | Attempt to toggle status on system-defined record | Toggle blocked; error returned |
| 5 | Locate a non-system record where is_system = 0 | Record exists |
| 6 | Verify non-system record can be edited and deleted | Operations succeed |

---

#### TC-D05: Boolean Field Validation — has_options, auto_gradable, is_system, is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Connect to the application database | DB connection established |
| 2 | Attempt to INSERT a record with has_options = 2 (invalid boolean) | DB rejects with TINYINT out-of-range error |
| 3 | Attempt to INSERT a record with auto_gradable = -1 (invalid boolean) | DB rejects with TINYINT out-of-range error |
| 4 | Attempt to INSERT a record with is_system = 'abc' (invalid type) | DB rejects with type mismatch error |
| 5 | Attempt to INSERT a record with is_active = 3 (invalid boolean) | DB rejects with TINYINT out-of-range error |
| 6 | INSERT a record with all boolean fields set to 0 | Insert succeeds |
| 7 | INSERT a record with all boolean fields set to 1 | Insert succeeds |

---

#### TC-D06: Model: $table Property Set to 'slb_question_types'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open the QuestionType model file | Model file loads |
| 2 | Check `protected $table = 'slb_question_types'` | Table name matches database convention |

---

#### TC-D07: Model: $fillable Contains All Editable Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open QuestionType model file | Model file loaded |
| 2 | Check `protected $fillable` array | Contains: code, name, description, has_options, auto_gradable, is_default, is_system, is_active |

---

#### TC-D08: Model: $casts Defined for Boolean Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open QuestionType model file | Model file loaded |
| 2 | Check `protected $casts` array | `has_options => 'boolean'`, `auto_gradable => 'boolean'`, `is_system => 'boolean'`, `is_active => 'boolean'` are defined |

---

#### TC-D09: Model: SoftDeletes Trait Imported and Used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open QuestionType model file | Model file loaded |
| 2 | Check `use SoftDeletes;` in class body | SoftDeletes trait is imported and used, managing deleted_at column |

---

#### TC-D10: Model: No Relationships Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open QuestionType model file | Model file loaded |
| 2 | Scan class for relationship methods (belongsTo, hasMany, hasOne, belongsToMany) | No relationship methods defined (master/reference data pattern) |

---

#### TC-D11: Controller: index() Paginates at 10 Per Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open QuestionTypeController | Controller file loaded |
| 2 | Check `index()` method implementation | Calls `QuestionType::paginate(10)` or equivalent pagination logic with 10 per page |

---

#### TC-D12: Controller: store() — Create, Log Activity, Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open QuestionTypeController, locate `store()` method | Method found |
| 2 | Check it calls `QuestionType::create($validated)` | Record created from validated data |
| 3 | Check it logs activity with event `Stored` | Activity log entry created for store event |
| 4 | Check redirect to `syllabus.bloom.index` with `question_types` tab | Correct redirect target |

---

#### TC-D13: Controller: update() — Guard, Update, Log, Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `update()` method | Method found |
| 2 | Check `is_system` guard before update | Returns error if is_system is true |
| 3 | Check it calls `$questionType->update($validated)` | Record updated |
| 4 | Check it logs activity with event `Updated` | Activity log entry created |
| 5 | Check redirect to `syllabus.bloom.index` with `question_types` tab | Correct redirect |

---

#### TC-D14: Controller: destroy() — Set is_active=false Before Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroy()` method | Method found |
| 2 | Check `is_system` guard present | Blocked if system record |
| 3 | Check `$questionType->is_active = false` before delete | is_active set to false |
| 4 | Check `$questionType->delete()` called | Soft delete executed |
| 5 | Check activity log with event `Trashed` | Activity logged |
| 6 | Check redirect | Correct redirect to bloom index |

---

#### TC-D15: Controller: restore() — Restore, Set is_active=true, Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `restore()` method | Method found |
| 2 | Check `$questionType->restore()` called | Record restored from soft delete |
| 3 | Check `$questionType->is_active = true` after restore | is_active set to true |
| 4 | Check activity log with event `Restored` | Activity logged |
| 5 | Check redirect | Correct redirect to bloom index |

---

#### TC-D16: Controller: toggleStatus() — Flip is_active, Return JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `toggleStatus()` method | Method found |
| 2 | Check `is_system` guard | Returns JSON 403 if system record |
| 3 | Check `$questionType->is_active = !$questionType->is_active` | is_active flipped to opposite value |
| 4 | Check `$questionType->save()` called | Change persisted to database |
| 5 | Check activity log with event `Toggled` | Activity logged |
| 6 | Check JSON response structure | Returns `{success: true, is_active: bool, message: string}` |

---

#### TC-D17: Controller: System Guard on All Protected Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `update()` method — check `is_system` guard | Guard present before update logic |
| 2 | Open `destroy()` method — check `is_system` guard | Guard present before delete logic |
| 3 | Open `forceDelete()` method — check `is_system` guard | Guard present before force delete logic |
| 4 | Open `toggleStatus()` method — check `is_system` guard | Guard present before toggle logic |

---

#### TC-D18: Request: prepareForValidation() Uppercases Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open QuestionTypeRequest file | Request file loaded |
| 2 | Check `prepareForValidation()` method exists | Method defined in request class |
| 3 | Check implementation: `$this->merge(['code' => strtoupper(trim($this->code))])` | Code is uppercased and trimmed before validation rules run |

---

#### TC-D19: Request: Update Unique Rule Ignores Current ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open QuestionTypeRequest `rules()` method | Rules method loaded |
| 2 | Check code rule for update context | Rule includes `unique:slb_question_types,code,{$this->question_type}` to ignore current record ID during update |

---

#### TC-D20: Policy: All Authorization Gates Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open QuestionTypePolicy file | Policy file loaded |
| 2 | Check `viewAny()` method | Method defined |
| 3 | Check `view()` method | Method defined |
| 4 | Check `create()` method | Method defined |
| 5 | Check `update()` method | Method defined |
| 6 | Check `delete()` method | Method defined |
| 7 | Check `restore()` method | Method defined |
| 8 | Check `forceDelete()` method | Method defined |
| 9 | Check `status()` method | Method defined |
