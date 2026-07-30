# slb_ques_type_specificity_TcList

## Module: Syllabus → Syllabus Master → Question Type Specificity

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Syllabus Master |
| Feature | Question Type Specificity |
| URL(s) | `/syllabus/bloom` (index via tab), `/syllabus/ques-type-specificity/create` (create), `/syllabus/ques-type-specificity` (store), `/syllabus/ques-type-specificity/{id}` (show), `/syllabus/ques-type-specificity/{id}/edit` (edit), `/syllabus/ques-type-specificity/{id}` (update), `/syllabus/ques-type-specificity/trash/view` (trash), `/syllabus/ques-type-specificity/{id}/restore` (restore), `/syllabus/ques-type-specificity/{id}/force-delete` (forceDelete), `/syllabus/ques-type-specificity/{id}/toggle-status` (toggleStatus) |
| Controller | `Modules\Syllabus\Http\Controllers\QuestionTypeSpecificityController` |
| Model(s) | `Modules\Syllabus\Models\QueTypeSpecifity` |
| Validation (Create) | `Modules\Syllabus\Http\Requests\QuesTypeSpecificityRequest` |
| Validation (Update) | `Modules\Syllabus\Http\Requests\QuesTypeSpecificityRequest` (ignores current ID for unique) |
| Permissions | `tenant.ques-type-specificity.viewAny`, `tenant.ques-type-specificity.view`, `tenant.ques-type-specificity.create`, `tenant.ques-type-specificity.update`, `tenant.ques-type-specificity.delete`, `tenant.ques-type-specificity.restore`, `tenant.ques-type-specificity.forceDelete`, `tenant.ques-type-specificity.status` |
| Soft Deletes | Yes (`QueTypeSpecifity` uses `SoftDeletes` trait) |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |
| Import | Not supported |

---

## 2. Pre-conditions

- Required permissions: `tenant.ques-type-specificity.viewAny`, `tenant.ques-type-specificity.view`, `tenant.ques-type-specificity.create`, `tenant.ques-type-specificity.update`, `tenant.ques-type-specificity.delete`, `tenant.ques-type-specificity.restore`, `tenant.ques-type-specificity.forceDelete`, `tenant.ques-type-specificity.status`
- Required seed data: At least one active `CognitiveSkill` record for parent linkage
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
| Question Type Specificities Grid | getQueTypeSpecificities() | QueTypeSpecifity::with(cognitiveSkill) | search(name,code), filter(cognitive_skill_id,status) | 10/page (question_type_specificities_page) |

For other bloom grids (BloomTaxonomy, CognitiveSkills, QuestionTypes, ComplexityLevels), same 5 grids are loaded simultaneously — each independently paginated to 10/page.
## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Specificity code**: Uppercase alphanumeric, max 20 chars, globally unique
- **Parent cognitive_skill_id**: Nullable FK to slb_cognitive_skill.id
- **Pre-test cleanup**: Delete created records by code before/after tests to avoid collisions
- **JSON fields**: None

---

## 5. Business Conditions

### 4.1 Database Schema — `slb_ques_type_specificity`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT PK | Auto-increment |
| BC-DB-02 | cognitive_skill_id | BIGINT FK NULL | FK → `slb_cognitive_skill.id`, ON DELETE SET NULL |
| BC-DB-03 | code | VARCHAR(20) | NOT NULL, UNIQUE |
| BC-DB-04 | name | VARCHAR(100) | NOT NULL |
| BC-DB-05 | description | VARCHAR(255) | DEFAULT NULL |
| BC-DB-06 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 (cast to boolean) |
| BC-DB-07 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-08 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-09 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules — `QuesTypeSpecificityRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | code | required, string, max:20, unique:slb_ques_type_specificity,code | "Question type specificity code is required." |
| BC-VAL-02 | code | unique | "This question type specificity code already exists." |
| BC-VAL-03 | name | required, string, max:100 | "Question type specificity name is required." |
| BC-VAL-04 | name | max:100 | "Name must not exceed 100 characters." |
| BC-VAL-05 | cognitive_skill_id | nullable, integer, exists:slb_cognitive_skill,id | "Selected cognitive skill does not exist." |
| BC-VAL-06 | description | nullable, string, max:255 | "Description must not exceed 255 characters." |
| BC-VAL-07 | is_active | nullable, boolean | — |

### 4.3 Validation Rules — `QuesTypeSpecificityRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | code | required, string, max:20, unique:slb_ques_type_specificity,code + ignore($id) | "Question type specificity code is required." |
| BC-VAL-U02 | code | unique + ignore | "This question type specificity code already exists." |
| BC-VAL-U03 | name | required, string, max:100 | "Question type specificity name is required." |
| BC-VAL-U04 | name | max:100 | "Name must not exceed 100 characters." |
| BC-VAL-U05 | cognitive_skill_id | nullable, integer, exists:slb_cognitive_skill,id | "Selected cognitive skill does not exist." |
| BC-VAL-U06 | description | nullable, string, max:255 | "Description must not exceed 255 characters." |
| BC-VAL-U07 | is_active | nullable, boolean | — |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.ques-type-specificity.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.ques-type-specificity.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.ques-type-specificity.create | store(), create() | Without → 403 |
| BC-AUTH-04 | tenant.ques-type-specificity.update | update(), edit(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.ques-type-specificity.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.ques-type-specificity.restore | restore(), trashed() | Without → 403 |
| BC-AUTH-07 | tenant.ques-type-specificity.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.ques-type-specificity.status | toggleStatus() (via update gate) | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-02 | Default is_active on create | Defaults to true |
| BC-BIZ-03 | Code auto-uppercase | `strtoupper(trim($code))` applied in `prepareForValidation()` |
| BC-BIZ-04 | Delete sets is_active false | `destroy()` sets `is_active = false` before `delete()` |
| BC-BIZ-05 | Restore sets is_active true | `restore()` sets `is_active = true` |
| BC-BIZ-06 | Status toggle | `is_active` flips; returns JSON `{success, is_active, message}` |
| BC-BIZ-07 | Force delete — cognitive_skill_id set NULL | `slb_cognitive_skill.id` ON DELETE SET NULL |
| BC-BIZ-08 | Show uses withTrashed | `show()` calls `withTrashed()->findOrFail($id)` |
| BC-BIZ-09 | Eager load cognitiveSkill relation | Index and show eager-load `cognitiveSkill` for parent name |
| BC-BIZ-10 | Pagination on trash | `trashed()` paginated at 10 per page |
| BC-BIZ-11 | Activity log — Stored | On create |
| BC-BIZ-12 | Activity log — Updated | On update (uses array_diff_assoc to log changed fields) |
| BC-BIZ-13 | Activity log — Trashed | On soft delete |
| BC-BIZ-14 | Activity log — Restored | On restore |
| BC-BIZ-15 | Activity log — Deleted | On force delete |
| BC-BIZ-16 | Activity log — Toggled | On status toggle |
| BC-BIZ-17 | Redirect after CRUD | Redirect to `syllabus.bloom.index` with tab `ques_type_specificity` |
| BC-BIZ-18 | cognitive_skill_id nullable | Specificity can be created without linking to a cognitive skill |
| BC-BIZ-19 | Screen loads via SyllabusController@bloom() at GET /syllabus/bloom with bloom tab group | Navigating to GET /syllabus/bloom with appropriate permissions loads the Bloom tab group; this screen's grid data is fetched and displayed |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | cognitive_skill_id | slb_cognitive_skill (id) | SET NULL |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Specificity List Page Loads With All UI Elements | Page loads with Add New, Trash, search, table: Code, Name, Cognitive Skill, Status, Actions | — | — | ⬜ |
| TC-P02 | Search By Name Or Code | Table filters correctly | — | — | ⬜ |
| TC-P03 | Filter By Active/Inactive Status | Filter works correctly | — | — | ⬜ |
| TC-P04 | Create Specificity With All Required Fields | Record created with code, name | — | — | ⬜ |
| TC-P05 | Create Specificity With Parent Cognitive Skill | cognitive_skill_id linked correctly | — | — | ⬜ |
| TC-P06 | Create Specificity Without Parent (cognitive_skill_id = NULL) | Record created with null parent | — | — | ⬜ |
| TC-P07 | Create Specificity With All Optional Fields | Description, is_active saved correctly | — | — | ⬜ |
| TC-P08 | Create With Code Auto-Uppercase | Code `label_diag` stored as `LABEL_DIAG` | — | — | ⬜ |
| TC-P09 | Edit Specificity Loads Pre-Filled Data | Edit form shows existing data with cognitive skill dropdown | — | — | ⬜ |
| TC-P10 | Update Specificity All Fields | All fields updated | — | — | ⬜ |
| TC-P11 | Update Specificity — Change Cognitive Skill Parent | cognitive_skill_id changed to different valid skill | — | — | ⬜ |
| TC-P12 | View Specificity Details Page | Details shown with cognitive skill parent name | — | — | ⬜ |
| TC-P13 | Soft Delete Specificity | `deleted_at` set | — | — | ⬜ |
| TC-P14 | Trash Page Shows Deleted Records | Trash page lists only soft-deleted records | — | — | ⬜ |
| TC-P15 | Restore Specificity From Trash | `deleted_at` = NULL; activity log "Restored" | — | — | ⬜ |
| TC-P16 | Force Delete Specificity (No Dependencies) | Record permanently removed | — | — | ⬜ |
| TC-P17 | Toggle Status Active ↔ Inactive | `is_active` flips; AJAX 200 | — | — | ⬜ |
| TC-P18 | Full Lifecycle: Create → Edit → Toggle → Delete → Trash → Restore → Force Delete | All transitions successful | — | — | ⬜ |
| TC-P19 | Cognitive Skill Parent Name Displayed In List | Index shows cognitive skill name from relationship | — | — | ⬜ |
| TC-P20 | Empty State — No Records Yet | "No records found" message | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing Code | "Question type specificity code is required." | — | — | ⬜ |
| TC-N02 | Required — Missing Name | "Question type specificity name is required." | — | — | ⬜ |
| TC-N03 | Invalid Code — Exceeds 20 Characters | code.max validation fails | — | — | ⬜ |
| TC-N04 | Duplicate Code (Global Unique) | "This question type specificity code already exists." | — | — | ⬜ |
| TC-N05 | Max Length — Name > 100 Characters | name.max validation fails | — | — | ⬜ |
| TC-N06 | Max Length — Description > 255 Characters | description.max validation fails | — | — | ⬜ |
| TC-N07 | Invalid cognitive_skill_id — Non-Existent Skill | "Selected cognitive skill does not exist." | — | — | ⬜ |
| TC-N08 | View Record With Invalid ID (404) | HTTP 404 | — | — | ⬜ |
| TC-N09 | Edit/Update Record With Invalid ID (404) | HTTP 404 | — | — | ⬜ |
| TC-N10 | Delete Record With Invalid ID (404) | Redirect with error | — | — | ⬜ |
| TC-N11 | Toggle Status With Invalid ID (404) | JSON 404 | — | — | ⬜ |
| TC-N12 | Restore Non-Deleted Record (Already Active) | 404 error | — | — | ⬜ |
| TC-N13 | Force Delete Non-Trashed Record | 404 error | — | — | ⬜ |
| TC-N14 | Permission 403 — No Specificity Permissions | 403 on all CRUD | — | — | ⬜ |
| TC-N15 | Guest Access Redirect | Redirected to /login | — | — | ⬜ |
| TC-N16 | XSS Injection In Name/Code | Stored as literal; Blade escapes | — | — | ⬜ |
| TC-N17 | Whitespace-Only Name/Code | Required validation catches | — | — | ⬜ |
| TC-N18 | Invalid cognitive_skill_id — Non-Integer Value | QuesTypeSpecificityRequest integer rule rejects string input | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Force Delete Specificity — No Cascade Effect | Record removed; no child tables affected (leaf table) | — | — | ⬜ |
| TC-D02 | B | Delete Cognitive Skill — Specificity cognitive_skill_id Set NULL | Force deleting cognitive skill sets specificity FK to NULL | — | — | ⬜ |
| TC-D03 | C | Toggle Status — Inactive Record Hidden From Dropdowns | Inactive specificity excluded from question bank dropdowns | — | — | ⬜ |
| TC-D04 | D | Uppercase Code Conversion — strtoupper() | Lowercase code "inclass" stored as "INCLASS" | — | — | ⬜ |
| TC-D05 | E | cognitive_skill_id Exists Validation — exists:slb_cognitive_skill,id | Non-existent cognitive_skill_id rejected with "Selected cognitive skill does not exist"; valid IDs accepted | — | — | ⬜ |
| TC-D06 | F | Missing code Max Validation — varchar(20) DDL without max rule | Code accepts input up to 20 chars (DDL limit); no max validation at FormRequest — this is a gap | — | — | ⬜ |
| TC-D07 | G | FK SET NULL — cognitive_skill_id on CognitiveSkill Deletion | Deleting referenced cognitive_skill sets cognitive_skill_id to NULL | — | — | ⬜ |
| TC-D08 | H | Active Cognitive Skill Filter — scopeActive() | Only is_active=1 cognitive skills shown in dropdown | — | — | ⬜ |
| TC-D09 | I | Max Length Validation — name max:100, description max:255 | Input exceeding limits rejected; within limits accepted | — | — | ⬜ |
| TC-D10 | J | AJAX Toggle — toggleStatus route | Toggle flips is_active via AJAX; returns JSON with success and new is_active | — | — | ⬜ |
| TC-D11 | K | Model Fillable Protection — Mass Assignment | Only fillable fields (cognitive_skill_id, code, name, description, is_active) are mass-assignable; guarded/id fields rejected | — | — | ⬜ |
| TC-D12 | L | Model $casts — integer/boolean Casting | cognitive_skill_id cast to integer; is_active cast to boolean | — | — | ⬜ |
| TC-D13 | M | SoftDeletes — deleted_at Timestamp | deleted_at set on soft delete; withTrashed() includes deleted records | — | — | ⬜ |
| TC-D14 | N | belongsTo cognitiveSkill Relationship | ->cognitiveSkill returns correct QueTypeSpecifity model instance; null when cognitive_skill_id is NULL | — | — | ⬜ |
| TC-D15 | O | Scope active() — Filters Inactive | active() scope excludes is_active=0 records | — | — | ⬜ |
| TC-D16 | P | Scope byCode() — Filter by Code | byCode('LABEL_DIAG') returns only matching records | — | — | ⬜ |
| TC-D17 | Q | Scope forCognitiveSkill() — Filter by Skill | forCognitiveSkill($id) returns records with matching cognitive_skill_id | — | — | ⬜ |
| TC-D18 | R | Policy — All Permission Gates | viewAny/view/create/update/delete/restore/forceDelete/status all return boolean; authenticated user with permission passes | — | — | ⬜ |
| TC-D19 | S | Route Resource Naming | All named routes resolve (ques-type-specificity.index, .create, .store, .show, .edit, .update, .destroy, .trash, .restore, .force-delete, .toggle-status) | — | — | ⬜ |
| TC-D20 | T | Controller CRUD — All Methods | index/create/store/show/edit/update/destroy/toggleStatus/trashed/restore/forceDelete all return expected response types | — | — | ⬜ |
| TC-D21 | U | Activity Log — All Events | Stored/Updated/Trashed/Restored/Deleted/Toggled events logged with correct properties | — | — | ⬜ |
| TC-D22 | V | Update Validation — Unique Code Ignores Current ID | Update with same code succeeds; another record with same code fails unique check | — | — | ⬜ |
| TC-D23 | W | Trash Pagination — 10 Per Page | trashed() returns max 10 records per page with pagination links | — | — | ⬜ |
| TC-D24 | X | Eager Load cognitiveSkill on Index/Show | Index and show queries include ->with('cognitiveSkill'); N+1 prevented | — | — | ⬜ |
| TC-D25 | Y | is_active=false Before Soft Delete | destroy() sets is_active=0 before delete(); restored record has is_active=1 | — | — | ⬜ |
| TC-D26 | Z | Index Ordered by code ASC — getQueTypeSpecificities() | Grid sorted alphabetically by code ascending via QueTypeSpecifity::orderBy('code') | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.ques-type-specificity.create'), @can('tenant.ques-type-specificity.edit'), @can('tenant.ques-type-specificity.delete'), @can('tenant.ques-type-specificity.status'), @can('tenant.ques-type-specificity.view'), @canany(['tenant.ques-type-specificity.restore', 'tenant.ques-type-specificity.forceDelete']) for access control on all CRUD buttons and actions | — | — | ◌ |
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
| 1 | Inspect index.blade.php for add/create button | @can('tenant.ques-type-specificity.create') wraps the Add New button; user without create permission does not see it
| 2 | Inspect row-level action buttons (view, edit, delete, status toggle) | @can('tenant.ques-type-specificity.view'), @can('tenant.ques-type-specificity.edit'), @can('tenant.ques-type-specificity.delete'), @can('tenant.ques-type-specificity.status') used appropriately; expired permissions hide corresponding buttons
| 3 | Inspect trash.blade.php for restore/forceDelete buttons | @canany(['tenant.ques-type-specificity.restore', 'tenant.ques-type-specificity.forceDelete']) wraps action buttons in trash view
| 4 | Inspect view.blade.php for edit button | @can('tenant.ques-type-specificity.edit') wraps the Edit button on show/details page
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

#### TC-P01: Specificity List Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login, navigate to Syllabus → Syllabus Master → Ques Type Specificity tab | Page loads |
| 2 | Check search, status filter, Add New, Trash, table columns | All UI elements present |

---

#### TC-P02: Search By Name Or Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create "Label Diagram" (code="LABEL_DIAG"), "Calculate" (code="CALCULATE") | 2 records |
| 2 | Search "Label" | Only "Label Diagram" visible |
| 3 | Search "CALCULATE" | Only "Calculate" visible |

---

#### TC-P03: Filter By Active/Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active and inactive records | Both exist |
| 2 | Filter "Active" | Only active |
| 3 | Filter "Inactive" | Only inactive |

---

#### TC-P04: Create Specificity With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add New", enter code="LABEL_DIAG", name="Label Diagram" | Fields set |
| 2 | Click "Save" | POST to store |
| 3 | Check response | Success message |
| 4 | DB check: record exists | is_active=1 |

---

#### TC-P05: Create Specificity With Parent Cognitive Skill

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pre-requisite: cognitive skill exists (e.g., "Recalling", id=X) | Parent exists |
| 2 | Open Add New, enter code="LABEL_DIAG_WP", name="Label Diagram With Parent" | Fields set |
| 3 | Select "Recalling" from cognitive_skill_id dropdown | Parent selected |
| 4 | Click "Save" | Record created |
| 5 | DB check: cognitive_skill_id = X | Linked correctly |

---

#### TC-P06: Create Specificity Without Parent (cognitive_skill_id = NULL)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code="NO_SKILL", name="No Skill Specificity" | Fields set |
| 2 | Leave cognitive_skill_id unselected | NULL |
| 3 | Click "Save" | Record created |
| 4 | DB check: cognitive_skill_id = NULL | Saved as null |

---

#### TC-P07: Create Specificity With All Optional Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code="FULL_SPEC", name="Full Specificity", select cognitive skill | Required set |
| 2 | Enter description: "This specificity requires students to label parts" | Description filled |
| 3 | Click "Save" | Record created |
| 4 | DB check: all fields saved | Correct |

---

#### TC-P08: Create With Code Auto-Uppercase

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code: "label_diag" (lowercase) | Lowercase |
| 2 | Click "Save" | Record created |
| 3 | DB check: code = "LABEL_DIAG" | Uppercased |

---

#### TC-P09: Edit Specificity Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record "EDITTEST" with cognitive skill parent | Exists |
| 2 | Click "Edit" | Form pre-filled, cognitive skill dropdown shows correct parent |

---

#### TC-P10: Update Specificity All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record, edit | Form loaded |
| 2 | Change code, name, cognitive_skill_id, description, is_active | All updated |
| 3 | Click "Save" | Update succeeds |

---

#### TC-P11: Update Specificity — Change Cognitive Skill Parent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create specificity with cognitive skill CS1 | Linked |
| 2 | Edit, select different cognitive skill CS2 | Changed |
| 3 | Click "Save" | Update succeeds |
| 4 | DB check: cognitive_skill_id = CS2 | Updated |

---

#### TC-P12: View Specificity Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record, click "View" | Code, name, cognitive skill, description, status shown |

---

#### TC-P13: Soft Delete Specificity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record, click delete, confirm | Soft deleted |
| 2 | DB check: deleted_at NOT NULL | Trashed |

---

#### TC-P14: Trash Page Shows Deleted Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete | In trash |
| 2 | Click "Trash" | Trash page shows record |

---

#### TC-P15: Restore Specificity From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate trash, click "Restore", confirm | Restored |
| 2 | Activity log "Restored" | Logged |

---

#### TC-P16: Force Delete Specificity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete → force delete | Permanently removed |
| 2 | Activity log "Deleted" | Logged |

---

#### TC-P17: Toggle Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active record, toggle | is_active flips |
| 2 | Toggle again | Flips back |

---

#### TC-P18: Full Lifecycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create → Edit → Toggle → Soft Delete → Trash → Restore → Soft Delete → Force Delete | All successful, activities logged |

---

#### TC-P19: Cognitive Skill Parent Name Displayed In List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create specificity linked to cognitive skill "Recalling" | Linked |
| 2 | Navigate to list | "Recalling" shown in Cognitive Skill column |

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
| 2 | Click "Save" | HTTP 500: "Question type specificity code is required." |

---

#### TC-N02: Required — Missing Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, leave name empty | Name missing |
| 2 | Click "Save" | HTTP 500: "Question type specificity name is required." |

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
| 2 | Create another with same code | HTTP 500: "This question type specificity code already exists." |

---

#### TC-N05: Max Length — Name > 100 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter name of 101 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500 |

---

#### TC-N06: Max Length — Description > 255 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter description of 256 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500: "Description must not exceed 255 characters." |

---

#### TC-N07: Invalid cognitive_skill_id — Non-Existent Skill

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set cognitive_skill_id = 99999 | Non-existent |
| 2 | Click "Save" | HTTP 500: "Selected cognitive skill does not exist." |

---

#### TC-N08: View Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open with invalid ID | HTTP 404 |

---

#### TC-N09: Edit/Update Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit with invalid ID | HTTP 404 |
| 2 | PUT to invalid ID | HTTP 404 |

---

#### TC-N10: Delete Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE to invalid ID | Redirect with error |

---

#### TC-N11: Toggle Status With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST toggle-status invalid ID | JSON 404 |

---

#### TC-N12: Restore Non-Deleted Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active record, try restore | 404 |

---

#### TC-N13: Force Delete Non-Trashed Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active record, try force delete | 404 |

---

#### TC-N14: Permission 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without permissions | 403 on all CRUD |

---

#### TC-N15: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate | Redirected to login |

---

#### TC-N16: XSS Injection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with XSS payload | Stored literal, not executed |

---

#### TC-N17: Whitespace-Only Name/Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Whitespace-only values | Validation fails |

---

#### TC-N18: Invalid cognitive_skill_id — Non-Integer Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, set cognitive_skill_id = "abc" (non-integer string) | String input entered |
| 2 | Click "Save" | HTTP 500: validation error for integer rule on cognitive_skill_id |
| 3 | Open Add New, set cognitive_skill_id = 1.5 (non-integer float) | Float input entered |
| 4 | Click "Save" | HTTP 500: validation error for integer rule on cognitive_skill_id |
| 5 | Open Add New, set cognitive_skill_id = 1 (valid integer) | Valid integer entered |
| 6 | Click "Save" | Record created successfully |

---

### 6.3 Dependency TC Steps

#### TC-D01: Force Delete Specificity — No Cascade Effect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create specificity, soft delete, force delete | Record removed |
| 2 | Verify no child records affected | Leaf table, no dependents |

---

#### TC-D02: Delete Cognitive Skill — Specificity cognitive_skill_id Set NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create cognitive skill CS1 and specificity linked to CS1 | Specificity.cognitive_skill_id = CS1.id |
| 2 | Force delete CS1 | CS1 removed |
| 3 | DB check: specificity cognitive_skill_id = NULL | SET NULL applied |

---

#### TC-D03: Toggle Status — Inactive Record Hidden From Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active specificity | Active |
| 2 | Toggle to inactive | is_active = 0 |
| 3 | Navigate to question bank form | Inactive specificity NOT in dropdown |
| 4 | Toggle back to active | Appears again |

---

#### TC-D04: Uppercase Code Conversion — strtoupper()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, enter code "inclass" (lowercase) | Lowercase input accepted |
| 2 | Click "Save" | Record created |
| 3 | DB check: code stored as "INCLASS" | Auto-uppercased by prepareForValidation() |

---

#### TC-D05: cognitive_skill_id Exists Validation — exists:slb_cognitive_skill,id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, set cognitive_skill_id = 99999 (non-existent) | Invalid ID |
| 2 | Click "Save" | HTTP 500: "Selected cognitive skill does not exist." |
| 3 | Open Add New, set cognitive_skill_id = valid existing cognitive skill ID | Valid ID |
| 4 | Click "Save" | Record created successfully with linked cognitive skill |

---

#### TC-D06: Missing code Max Validation — varchar(20) DDL without max rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, enter code of exactly 20 characters | 20 chars accepted by DDL |
| 2 | Click "Save" | Record created (no max rule at FormRequest to enforce <20; only DDL constraint) |
| 3 | Note: FormRequest has no max rule for code — gap identified | DDL limit is varchar(20) but validation layer does not enforce it |

---

#### TC-D07: FK SET NULL — cognitive_skill_id on CognitiveSkill Deletion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create cognitive skill CS1 and a specificity linked to CS1 | cognitive_skill_id = CS1.id |
| 2 | Force delete CS1 | CS1 permanently removed |
| 3 | DB check: specificity cognitive_skill_id = NULL | ON DELETE SET NULL applied |

---

#### TC-D08: Active Cognitive Skill Filter — scopeActive()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure at least one active (is_active=1) and one inactive (is_active=0) cognitive skill exist | Both states present |
| 2 | Open Add New / Edit form | Dropdown lists only active cognitive skills |
| 3 | Verify inactive cognitive skill NOT present in dropdown options | scopeActive() applied |

---

#### TC-D09: Max Length Validation — name max:100, description max:255

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter name of 101 characters, description of 256 characters | Exceeds limits |
| 2 | Click "Save" | HTTP 500: name and description validation errors |
| 3 | Enter name of 100 characters, description of 255 characters | Within limits |
| 4 | Click "Save" | Record created successfully |

---

#### TC-D10: AJAX Toggle — toggleStatus route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active specificity | is_active = 1 |
| 2 | Click toggle status button | AJAX POST to toggle-status route |
| 3 | Check response | JSON: {success: true, is_active: false, message: "..."} |
| 4 | DB check: is_active = 0 | Toggled to inactive |
| 5 | Click toggle again | JSON: {success: true, is_active: true, message: "..."} |
| 6 | DB check: is_active = 1 | Toggled back to active |

---

#### TC-D11: Model Fillable Protection — Mass Assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt mass assignment on guarded field `id` via `create()` | Throws MassAssignmentException or `id` is silently ignored |
| 2 | Mass assign via `fillable` fields: `cognitive_skill_id`, `code`, `name`, `description`, `is_active` | Only fillable fields populated; guarded fields unchanged |

---

#### TC-D12: Model $casts — integer/boolean Casting

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with cognitive_skill_id = "1" (string), is_active = 1 | Get attribute: cognitive_skill_id is int(1), is_active is true (boolean) |
| 2 | Set is_active = 0, save, retrieve | is_active casts to false (boolean, not 0) |

---

#### TC-D13: SoftDeletes — deleted_at Timestamp

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record, soft delete | deleted_at set to current timestamp |
| 2 | Query via Model::all() | Excluded from default queries |
| 3 | Query via Model::withTrashed()->find($id) | Record returned with deleted_at |

---

#### TC-D14: belongsTo cognitiveSkill Relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create specificity linked to cognitive skill CS1 | `$specificity->cognitiveSkill->id` equals CS1.id |
| 2 | Create specificity with cognitive_skill_id = NULL | `$specificity->cognitiveSkill` is null |

---

#### TC-D15: Scope active() — Filters Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active (is_active=1) and inactive (is_active=0) records | Both exist in DB |
| 2 | Query via `Model::active()->get()` | Only active records returned |

---

#### TC-D16: Scope byCode() — Filter by Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with code="LABEL_DIAG" and another with code="CALCULATE" | Both exist |
| 2 | Query via `Model::byCode('LABEL_DIAG')->first()` | Returns only "LABEL_DIAG" record |

---

#### TC-D17: Scope forCognitiveSkill() — Filter by Skill

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create specificity with cognitive_skill_id=1 and another with cognitive_skill_id=2 | Both exist |
| 2 | Query via `Model::forCognitiveSkill(1)->get()` | Returns only records with cognitive_skill_id=1 |

---

#### TC-D18: Policy — All Permission Gates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Auth user with full permissions | viewAny/view/create/update/delete/restore/forceDelete/status — all pass (true) |
| 2 | Auth user without any ques-type-specificity permissions | All gates deny (false/403) |
| 3 | Check each Gate::authorize call individually | Gate name matches permission exactly |

---

#### TC-D19: Route Resource Naming

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect routes via `php artisan route:list --name=ques-type-specificity` | All 11 named routes registered |
| 2 | Resolve each route name to URI | `.index` → GET, `.create` → GET/create, `.store` → POST, `.show` → GET/{id}, `.edit` → GET/{id}/edit, `.update` → PUT/{id}, `.destroy` → DELETE/{id}, `.trash` → GET/trash/view, `.restore` → POST/{id}/restore, `.force-delete` → DELETE/{id}/force-delete, `.toggle-status` → POST/{id}/toggle-status |

---

#### TC-D20: Controller CRUD — All Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call index() → returns view with paginated records | View rendered; records collection |
| 2 | Call create() → returns create view | View with cognitive skill dropdown |
| 3 | Call store() with valid data → redirect | Redirect to index with tab param |
| 4 | Call show($id) → returns detail view | View with record; cognitiveSkill eager loaded |
| 5 | Call edit($id) → returns edit view | View with pre-filled data and cognitive skill dropdown |
| 6 | Call update($id) → redirect | Record updated; activity logged |
| 7 | Call destroy($id) → redirect with is_active=false | Soft deleted; is_active=0 before delete |
| 8 | Call toggleStatus($id) → JSON response | JSON {success, is_active, message} |
| 9 | Call trashed() → view with paginated trashed records | Paginated at 10 per page |
| 10 | Call restore($id) → redirect | Restored; is_active=1; activity logged |
| 11 | Call forceDelete($id) → redirect | Permanently removed; activity logged |

---

#### TC-D21: Activity Log — All Events

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record → check activity log | "Stored" event logged with properties |
| 2 | Update record → check activity log | "Updated" event logged with changed fields diff |
| 3 | Soft delete record → check activity log | "Trashed" event logged |
| 4 | Restore record → check activity log | "Restored" event logged |
| 5 | Force delete record → check activity log | "Deleted" event logged |
| 6 | Toggle status → check activity log | "Toggled" event logged with new is_active value |

---

#### TC-D22: Update Validation — Unique Code Ignores Current ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with code="UNIQUE01" | Record exists |
| 2 | Update same record — keep code="UNIQUE01" | Update succeeds (ignores own ID for unique check) |
| 3 | Create another record, try to set code="UNIQUE01" | HTTP 500: "This question type specificity code already exists." |

---

#### TC-D23: Trash Pagination — 10 Per Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete 15 records | 15 trashed records exist |
| 2 | Navigate to trash page | Page 1 shows max 10 records; pagination links visible |
| 3 | Click page 2 | Remaining 5 records displayed |

---

#### TC-D24: Eager Load cognitiveSkill on Index/Show

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DB query log on index page | Query includes `->with('cognitiveSkill')` — single additional query |
| 2 | Verify N+1 prevention | Only 2 queries total (1 for specificities, 1 for cognitive skills); no N+1 |
| 3 | Check show page | Same eager loading — cognitive skill name displayed without lazy load |

---

#### TC-D25: is_active=false Before Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active record (is_active=1) | Record active |
| 2 | Soft delete | DB: is_active=0, deleted_at=timestamp |
| 3 | Restore record | DB: is_active=1, deleted_at=NULL |
| 4 | Toggle to inactive, then soft delete | DB: is_active=0, deleted_at=timestamp (already 0, stays 0) |

---

#### TC-D26: Index Ordered by code ASC — getQueTypeSpecificities()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open QuestionTypeSpecificityController.php and inspect getQueTypeSpecificities() | Method uses QueTypeSpecifity::orderBy('code') |
| 2 | Create specificities with codes: "BETA", "ALPHA", "CHARLIE" | Records created |
| 3 | Navigate to the Question Type Specificities grid | Grid loads |
| 4 | Verify records sorted alphabetically by code | Order: ALPHA, BETA, CHARLIE (ascending) |
| 5 | Add another specificity with code "DELTA" | Record created |
| 6 | Verify grid order maintained | ALPHA, BETA, CHARLIE, DELTA |
