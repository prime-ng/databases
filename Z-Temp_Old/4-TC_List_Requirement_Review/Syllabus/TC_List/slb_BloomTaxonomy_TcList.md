# slb_bloom_taxonomy_TcList

## Module: Syllabus → Syllabus Master → Bloom Taxonomy

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Syllabus Master |
| Feature | Bloom Taxonomy |
| URL(s) | `/syllabus/bloom` (index via tab), `/syllabus/bloom-taxonomy/create` (create), `/syllabus/bloom-taxonomy` (store), `/syllabus/bloom-taxonomy/{id}` (show), `/syllabus/bloom-taxonomy/{id}/edit` (edit), `/syllabus/bloom-taxonomy/{id}` (update), `/syllabus/bloom-taxonomy/trash/view` (trash), `/syllabus/bloom-taxonomy/{id}/restore` (restore), `/syllabus/bloom-taxonomy/{id}/force-delete` (forceDelete), `/syllabus/bloom-taxonomy/{id}/toggle-status` (toggleStatus) |
| Controller | `Modules\Syllabus\Http\Controllers\BloomTaxonomyController` |
| Model(s) | `Modules\Syllabus\Models\BloomTaxonomy` |
| Validation (Create) | `Modules\Syllabus\Http\Requests\BloomTaxonomyRequest` |
| Validation (Update) | `Modules\Syllabus\Http\Requests\BloomTaxonomyRequest` (ignores current ID for unique) |
| Permissions | `tenant.bloom-taxonomy.viewAny`, `tenant.bloom-taxonomy.view`, `tenant.bloom-taxonomy.create`, `tenant.bloom-taxonomy.update`, `tenant.bloom-taxonomy.delete`, `tenant.bloom-taxonomy.restore`, `tenant.bloom-taxonomy.forceDelete`, `tenant.bloom-taxonomy.status` |
| Soft Deletes | Yes (`BloomTaxonomy` uses `SoftDeletes` trait) |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |
| Import | Not supported |

---

## 2. Pre-conditions

- Required permissions: `tenant.bloom-taxonomy.viewAny`, `tenant.bloom-taxonomy.view`, `tenant.bloom-taxonomy.create`, `tenant.bloom-taxonomy.update`, `tenant.bloom-taxonomy.delete`, `tenant.bloom-taxonomy.restore`, `tenant.bloom-taxonomy.forceDelete`, `tenant.bloom-taxonomy.status`
- Required seed data: None (standalone master table)
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
- **Bloom taxonomy code**: Uppercase alpha letters only, max 20 chars, globally unique
- **Bloom level**: Integer between 1 and 6, ordered ascending
- **Pre-test cleanup**: Delete created records by code before/after tests to avoid collisions
- **JSON fields**: None

---

## 5. Business Conditions

### 4.1 Database Schema — `slb_bloom_taxonomy`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | code | VARCHAR(20) | NOT NULL, UNIQUE |
| BC-DB-03 | name | VARCHAR(100) | NOT NULL |
| BC-DB-04 | description | VARCHAR(255) | DEFAULT NULL |
| BC-DB-05 | bloom_level | TINYINT | NOT NULL, CHECK(1–6) |
| BC-DB-06 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 (cast to boolean) |
| BC-DB-07 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-08 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-09 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules — `BloomTaxonomyRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | code | required, string, alpha, max:20, unique:slb_bloom_taxonomy,code | "Bloom taxonomy code is required." |
| BC-VAL-02 | code | alpha | "Code must contain only letters." |
| BC-VAL-03 | code | unique | "This bloom taxonomy code already exists." |
| BC-VAL-04 | name | required, string, max:100 | "Bloom taxonomy name is required." |
| BC-VAL-05 | name | max:100 | "Name must not exceed 100 characters." |
| BC-VAL-06 | description | nullable, string, max:255 | — |
| BC-VAL-07 | bloom_level | required, integer, between:1,6 | "Bloom level is required." |
| BC-VAL-08 | bloom_level | between:1,6 | "Bloom level must be between 1 and 6." |
| BC-VAL-09 | is_active | nullable, boolean | — |

### 4.3 Validation Rules — `BloomTaxonomyRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | code | required, string, alpha, max:20, unique:slb_bloom_taxonomy,code + ignore($id) | "Bloom taxonomy code is required." |
| BC-VAL-U02 | code | alpha | "Code must contain only letters." |
| BC-VAL-U03 | code | unique + ignore | "This bloom taxonomy code already exists." |
| BC-VAL-U04 | name | required, string, max:100 | "Bloom taxonomy name is required." |
| BC-VAL-U05 | name | max:100 | "Name must not exceed 100 characters." |
| BC-VAL-U06 | description | nullable, string, max:255 | — |
| BC-VAL-U07 | bloom_level | required, integer, between:1,6 | "Bloom level is required." |
| BC-VAL-U08 | bloom_level | between:1,6 | "Bloom level must be between 1 and 6." |
| BC-VAL-U09 | is_active | nullable, boolean | — |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.bloom-taxonomy.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.bloom-taxonomy.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.bloom-taxonomy.create | store(), create() | Without → 403 |
| BC-AUTH-04 | tenant.bloom-taxonomy.update | update(), edit(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.bloom-taxonomy.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.bloom-taxonomy.restore | restore(), trashed() | Without → 403 |
| BC-AUTH-07 | tenant.bloom-taxonomy.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.bloom-taxonomy.status | toggleStatus() (via update gate) | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-02 | Default is_active on create | Defaults to true (model default 1) |
| BC-BIZ-03 | Code auto-uppercase | `strtoupper(trim($code))` applied in `prepareForValidation()` |
| BC-BIZ-04 | Name trimming | `trim()` applied in both store and update |
| BC-BIZ-05 | Delete sets is_active false | `destroy()` sets `is_active = false` before calling `delete()` |
| BC-BIZ-06 | Restore sets is_active true | `restore()` sets `is_active = true` |
| BC-BIZ-07 | Status toggle | `is_active` flips via `$record->is_active = !$record->is_active`; returns JSON `{success, is_active, message}` |
| BC-BIZ-08 | Force delete cascades cognitive skills | On force delete, `slb_cognitive_skill.bloom_id` → NULL (ON DELETE SET NULL) |
| BC-BIZ-09 | Show uses withTrashed | `show()` calls `withTrashed()->findOrFail($id)` to display both active and trashed |
| BC-BIZ-10 | Record ordering | Records ordered by `bloom_level` ascending |
| BC-BIZ-11 | Pagination | Index paginated at 10 per page |
| BC-BIZ-12 | Activity log — Stored | On create |
| BC-BIZ-13 | Activity log — Updated | On update |
| BC-BIZ-14 | Activity log — Trashed | On soft delete |
| BC-BIZ-15 | Activity log — Restored | On restore |
| BC-BIZ-16 | Activity log — Deleted | On force delete |
| BC-BIZ-17 | Activity log — Toggled | On status toggle |
| BC-BIZ-18 | Redirect after CRUD | Redirect to `syllabus.bloom.index` with tab `bloom_taxonomy` |
| BC-BIZ-19 | Screen loads via SyllabusController@bloom() at GET /syllabus/bloom with bloom tab group | Navigating to GET /syllabus/bloom with appropriate permissions loads the Bloom tab group; this screen's grid data is fetched and displayed |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | bloom_id (in slb_cognitive_skill) | slb_bloom_taxonomy (id) | SET NULL |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Bloom Taxonomy List Page Loads With All UI Elements | Page loads with Add New button, Trash button, search, table columns: Code, Name, Description, Bloom Level, Status, Actions | — | — | ⬜ |
| TC-P02 | Search Bloom Taxonomy By Name Or Code | Table filters to show only matching records by name or code | — | — | ⬜ |
| TC-P03 | Filter By Active/Inactive Status | Active filter shows only active records; Inactive shows only inactive | — | — | ⬜ |
| TC-P04 | Create Bloom Taxonomy With All Required Fields | Record created with correct values in DB — code, name, bloom_level | — | — | ⬜ |
| TC-P05 | Create Bloom Taxonomy With All Optional Fields | Description saved correctly | — | — | ⬜ |
| TC-P06 | Create Bloom Taxonomy With Code Auto-Uppercase | Code `remembering` stored as `REMEMBERING` | — | — | ⬜ |
| TC-P07 | Create Bloom Taxonomy With Bloom Level 1 (Min) | Level 1 saved successfully | — | — | ⬜ |
| TC-P08 | Create Bloom Taxonomy With Bloom Level 6 (Max) | Level 6 saved successfully | — | — | ⬜ |
| TC-P09 | Edit Bloom Taxonomy Loads Pre-Filled Data | Edit page shows existing record data in form fields | — | — | ⬜ |
| TC-P10 | Update Bloom Taxonomy All Fields | Code, name, description, bloom_level, is_active all updated | — | — | ⬜ |
| TC-P11 | View Bloom Taxonomy Details Page | Record details shown with code, name, description, bloom_level, status | — | — | ⬜ |
| TC-P12 | Soft Delete Bloom Taxonomy | `deleted_at` set; record no longer visible on main list | — | — | ⬜ |
| TC-P13 | Trash Page Shows Deleted Records | `/syllabus/bloom-taxonomy/trash/view` lists only soft-deleted records with restore + force delete buttons | — | — | ⬜ |
| TC-P14 | Restore Bloom Taxonomy From Trash | `deleted_at` set to NULL; record visible on main list again; activity log "Restored" | — | — | ⬜ |
| TC-P15 | Force Delete Bloom Taxonomy (No Dependencies) | Record permanently removed; related cognitive skills bloom_id set to NULL | — | — | ⬜ |
| TC-P16 | Toggle Status Active ↔ Inactive | `is_active` flips value; AJAX 200 with success message | — | — | ⬜ |
| TC-P17 | Records Ordered By Bloom Level Ascending | Index page shows records ordered by bloom_level (1 → 6) | — | — | ⬜ |
| TC-P18 | Pagination Works (10 Per Page) | With 11+ records, pagination links appear; page 2 shows remaining records | — | — | ⬜ |
| TC-P19 | Full Lifecycle: Create → Edit → Toggle → Delete → Trash → Restore → Force Delete | All transitions successful; activity logged at each step | — | — | ⬜ |
| TC-P20 | Empty State — No Records Yet | Table shows "No records found" message; Add New button visible | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing Code | Validation error: "Bloom taxonomy code is required." | — | — | ⬜ |
| TC-N02 | Required — Missing Name | Validation error: "Bloom taxonomy name is required." | — | — | ⬜ |
| TC-N03 | Required — Missing Bloom Level | Validation error: "Bloom level is required." | — | — | ⬜ |
| TC-N04 | Invalid Code — Non-Alpha Characters | Validation error: "Code must contain only letters." | — | — | ⬜ |
| TC-N05 | Invalid Code — Exceeds 20 Characters | Validation error on code.max (21+ chars) | — | — | ⬜ |
| TC-N06 | Duplicate Code (Global Unique) | "This bloom taxonomy code already exists." | — | — | ⬜ |
| TC-N07 | Max Length — Name > 100 Characters | Validation fails on name.max | — | — | ⬜ |
| TC-N08 | Invalid Bloom Level — Not An Integer | Validation error: "Bloom level must be an integer." | — | — | ⬜ |
| TC-N09 | Invalid Bloom Level — Below 1 (Zero) | Validation error: "Bloom level must be between 1 and 6." | — | — | ⬜ |
| TC-N10 | Invalid Bloom Level — Above 6 (e.g. 7) | Validation error: "Bloom level must be between 1 and 6." | — | — | ⬜ |
| TC-N11 | Max Length — Description > 255 Characters | Validation fails on description.max | — | — | ⬜ |
| TC-N12 | View Record With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N13 | Edit/Update Record With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N14 | Delete Record With Invalid ID (404) | 404 error: "Bloom taxonomy not found" | — | — | ⬜ |
| TC-N15 | Toggle Status With Invalid ID (404) | JSON 404: `{success: false, message: "Bloom taxonomy not found"}` | — | — | ⬜ |
| TC-N16 | Restore Non-Deleted Record (Already Active) | `onlyTrashed()->find()` returns null → 404 | — | — | ⬜ |
| TC-N17 | Force Delete Non-Trashed Record | `onlyTrashed()->find()` returns null → 404 | — | — | ⬜ |
| TC-N18 | Permission 403 — No Bloom Taxonomy Permissions | 403 Forbidden on all CRUD endpoints for user without `tenant.bloom-taxonomy.*` gates | — | — | ⬜ |
| TC-N19 | Guest Access Redirect | Redirected to /login for all bloom taxonomy routes | — | — | ⬜ |
| TC-N20 | XSS Injection In Name/Code | Stored as literal string; Blade `{{ }}` escapes output; no script execution | — | — | ⬜ |
| TC-N21 | Whitespace-Only Name/Code | Required validation catches empty/whitespace-only strings after trim | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Force Delete Bloom Taxonomy — Cognitive Skills bloom_id Set NULL | `slb_cognitive_skill.bloom_id` = NULL for all related skills | — | — | ⬜ |
| TC-D02 | B | Soft-Delete Record Hidden From Dropdowns | Inactive/deleted bloom taxonomy excluded from cognitive skill parent dropdown | — | — | ⬜ |
| TC-D03 | C | Cannot Force Delete If Cognitive Skills Exist (Business Rule) | Check if force delete succeeds and sets FK to NULL (ON DELETE SET NULL) | — | — | ⬜ |
| TC-D04 | D | Toggle Status — Inactive Record Hidden From Dropdowns | Inactive bloom taxonomy excluded from cognitive skills bloom_id dropdown | — | — | ⬜ |
| TC-D05 | E | UI/API | P1 | Bloom taxonomy create form — Uppercase Code Conversion — strtoupper() in prepareForValidation | Submitting lowercase code `remember` is stored as `REMEMBER` in database | — | — | ⬜ |
| TC-D06 | F | UI/API | P1 | Bloom taxonomy create form — Alpha Only Validation — code Field | Code field accepts only letters; rejects numbers, dashes, underscores, or special characters | — | — | ⬜ |
| TC-D07 | G | UI/API | P1 | Bloom taxonomy create form — bloom_level Range — between:1,6 | bloom_level values 1-6 are accepted; values 0, 7, or negative numbers are rejected with `between` validation message | — | — | ⬜ |
| TC-D08 | H | UI/API | P1 | Bloom taxonomy create form — Level Text Mapping — getLevelTextAttribute() | Display shows `Remembering` for bloom_level=1, `Understanding` for 2, `Applying` for 3, `Analyzing` for 4, `Evaluating` for 5, `Creating` for 6 | — | — | ⬜ |
| TC-D09 | I | UI | P1 | Bloom taxonomy edit form — existing record — is_active Default Update — prepareForValidation behavior | Updating bloom taxonomy without checking is_active checkbox sets is_active to false (PUT defaults to false from `$this->boolean('is_active')`) | — | — | ⬜ |
| TC-D10 | J | UI | P1 | Bloom taxonomy list with existing active record — AJAX Toggle — toggleStatus route | Clicking toggle flips is_active between true/false via AJAX; no page reload; response returns JSON with success and new is_active value | — | — | ⬜ |
| TC-D11 | K | UI/API | P1 | Bloom taxonomy create form open | Uppercase Code Conversion — strtoupper() in prepareForValidation | Submitting lowercase code "remember" is stored as "REMEMBER" | — | — | ⬜ |
| TC-D12 | L | UI/API | P1 | Bloom taxonomy create form open | Alpha Only Validation — code Field uses `alpha` rule | Code accepts only letters; rejects numbers, dashes, underscores | — | — | ⬜ |
| TC-D13 | M | UI/API | P1 | Bloom taxonomy create form open | bloom_level Range — between:1,6 | Values 1-6 accepted; 0, 7, negatives rejected | — | — | ⬜ |
| TC-D14 | N | UI | P1 | Bloom taxonomy with existing record | Level Text Mapping — getLevelTextAttribute() | bloom_level=1 shows "Remembering", 2→"Understanding", etc. | — | — | ⬜ |
| TC-D15 | O | UI/API | P1 | Bloom taxonomy edit form open | is_active Default Update — boolean() handles unchecked checkbox | Updating without is_active checked sets is_active to false | — | — | ⬜ |
| TC-D16 | P | UI | P1 | Bloom taxonomy list with active record | AJAX Toggle — toggleStatus route | Toggle flips is_active via AJAX; returns JSON with new is_active | — | — | ⬜ |
| TC-R01 | CR | Static Analysis | P1 | Model Table — `slb_bloom_taxonomy` exists with all expected columns | `Schema::hasTable('slb_bloom_taxonomy')` returns true; migration contains `id`, `code`, `name`, `description`, `bloom_level`, `is_active`, `created_at`, `updated_at`, `deleted_at` | — | — | ⬜ |
| TC-R02 | CR | Static Analysis | P1 | Model Fillable — `$fillable` array permits mass-assignment on `code`, `name`, `description`, `bloom_level`, `is_active` | `BloomTaxonomy::create([...])` assigns all listed attributes; unguarded attributes raise mass-assignment exception | — | — | ⬜ |
| TC-R03 | CR | Static Analysis | P1 | Model SoftDeletes — `SoftDeletes` trait imported; `deleted_at` populated on `delete()` | `$model->delete()` sets `deleted_at` timestamp; `$model->trashed()` returns true; record excluded from default queries | — | — | ⬜ |
| TC-R04 | CR | Static Analysis | P1 | Model Relationships — `hasMany('cognitiveSkills')` defined on `BloomTaxonomy` | `BloomTaxonomy::with('cognitiveSkills')->find($id)` returns related `CognitiveSkill` collection; FK `bloom_id` references `slb_bloom_taxonomy.id` | — | — | ⬜ |
| TC-R05 | CR | Static Analysis | P1 | Model Casts — `$casts` array declares `is_active => 'boolean'` and `bloom_level => 'integer'` | `$model->is_active` returns `true`/`false` (not int 0/1); `$model->bloom_level` returns integer type | — | — | ⬜ |
| TC-R06 | CR | Static Analysis | P1 | Controller `findOrFail` — Show/Edit/Update/Destroy/Toggle use `findOrFail($id)` or `withTrashed()->findOrFail($id)` | Invalid ID throws `ModelNotFoundException` → HTTP 404; no raw `->find($id)` without null check | — | — | ⬜ |
| TC-R07 | CR | Static Analysis | P1 | Controller Gate Authorization — `Gate::authorize('tenant.bloom-taxonomy.*')` called in all CRUD methods | Every controller method (index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus) includes `Gate::authorize()` call before business logic | — | — | ⬜ |
| TC-R08 | CR | Static Analysis | P1 | Activity Log Integration — All lifecycle events logged via `activityLog` helper | Events `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` each recorded with correct subject/model reference; log entries have `causer_id`, `event`, `subject_type` filled | — | — | ⬜ |
| TC-R09 | CR | Static Analysis | P1 | `is_active` Toggle Before Delete — `destroy()` sets `is_active=false` before calling `delete()` | `$record->is_active = false; $record->save(); $record->delete();` executed in sequence; trashed records have `is_active=0` | — | — | ⬜ |
| TC-R10 | CR | Static Analysis | P1 | Unique Code Validation — `unique:slb_bloom_taxonomy,code` rule (with `ignore($id)` on update) prevents duplicate codes | Creating same code twice fails 500 with "already exists"; update with unchanged code passes (ignores own ID) | — | — | ⬜ |
| TC-R11 | CR | Static Analysis | P1 | Required Field Validation — `code`, `name`, `bloom_level` marked `required` in `BloomTaxonomyRequest` | Omitting any of these fields returns 500 with respective "required" validation message; nullable fields (description, is_active) allowed empty | — | — | ⬜ |
| TC-R12 | CR | Static Analysis | P1 | Max Length Constraints — `code:max:20`, `name:max:100`, `description:max:255` enforced in request | Inputs exceeding limits return 500; boundary values (exactly 20/100/255 chars) accepted | — | — | ⬜ |
| TC-R13 | CR | Static Analysis | P1 | Boolean Cast for `is_active` — Column is `TINYINT(1)` in DB with boolean cast in model | `$model->is_active` returns PHP boolean; DB stores as 0/1; `$this->boolean('is_active')` in request returns `true`/`false` | — | — | ⬜ |
| TC-R14 | CR | Static Analysis | P1 | Policy Gates — `BloomTaxonomyPolicy` defines `viewAny`/`view`/`create`/`update`/`delete`/`restore`/`forceDelete`/`status` gates | All CRUD methods in controller map to correct policy method; routes with missing permission return 403; policy uses `Gate::authorize()` consistently | — | — | ⬜ |
| TC-R15 | CR | Static Analysis | P1 | Route Registration — Resourceful route `bloom-taxonomy` + custom routes for `trashed`, `restore`, `forceDelete`, `toggleStatus` | `Route::resource('bloom-taxonomy', ...)` registers 7 resource routes; additional `GET trashed`, `GET {id}/restore`, `DELETE {id}/force-delete`, `POST {id}/toggle-status` registered; all pass through auth + tenant middleware | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.bloom-taxonomy.create'), @can('tenant.bloom-taxonomy.edit'), @can('tenant.bloom-taxonomy.delete'), @can('tenant.bloom-taxonomy.status'), @can('tenant.bloom-taxonomy.view'), @canany(['tenant.bloom-taxonomy.restore', 'tenant.bloom-taxonomy.forceDelete']) for access control on all CRUD buttons and actions | — | — | ◌ |
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
| 1 | Inspect index.blade.php for add/create button | @can('tenant.bloom-taxonomy.create') wraps the Add New button; user without create permission does not see it
| 2 | Inspect row-level action buttons (view, edit, delete, status toggle) | @can('tenant.bloom-taxonomy.view'), @can('tenant.bloom-taxonomy.edit'), @can('tenant.bloom-taxonomy.delete'), @can('tenant.bloom-taxonomy.status') used appropriately; expired permissions hide corresponding buttons
| 3 | Inspect trash.blade.php for restore/forceDelete buttons | @canany(['tenant.bloom-taxonomy.restore', 'tenant.bloom-taxonomy.forceDelete']) wraps action buttons in trash view
| 4 | Inspect view.blade.php for edit button | @can('tenant.bloom-taxonomy.edit') wraps the Edit button on show/details page
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

#### TC-P01: Bloom Taxonomy List Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Expand "Syllabus" from left sidebar | Menu options appear |
| 3 | Click "Syllabus Master" and select "Bloom Taxonomy" tab | Page loads with bloom taxonomy content |
| 4 | Check the search input | Search text field with placeholder present |
| 5 | Check the status filter | Dropdown with options: "All", "Active", "Inactive" |
| 6 | Check the "Add New" button | Green/blue button visible (if create permission) |
| 7 | Check the "Trash" button | Trash button visible (if restore permission) |
| 8 | Check the bloom taxonomy table | Columns: Code, Name, Description, Bloom Level, Status, Actions |
| 9 | Check pagination | If 10+ records exist, pagination links appear |

---

#### TC-P02: Search Bloom Taxonomy By Name Or Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create records: "Remembering" (code="REMEMBERING"), "Understanding" (code="UNDERSTAND"), "Applying" (code="APPLYING") | 3 records exist |
| 2 | Type "Remember" in search box and press Enter | Page reloads with `?search=Remember` |
| 3 | Verify table shows only "Remembering" | Other 2 records not visible |
| 4 | Clear search, type "APPLYING" | Only "Applying" shown (matched by code) |
| 5 | Clear search | All 3 records visible again |

---

#### TC-P03: Filter By Active/Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active record "ActiveOne" (is_active=1) and inactive "InactiveOne" (is_active=0) | Both exist |
| 2 | Select "Active" from status filter | Only "ActiveOne" visible |
| 3 | Select "Inactive" from filter | Only "InactiveOne" visible |
| 4 | Select "All" | Both records visible |

---

#### TC-P04: Create Bloom Taxonomy With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Syllabus Master → Bloom Taxonomy tab | Page loads |
| 2 | Click "Add New" button | Create form opens |
| 3 | Enter code: "REMEMBERING" | Field filled |
| 4 | Enter name: "Remembering" | Field filled |
| 5 | Enter bloom_level: 1 | Field filled |
| 6 | Click "Save" / "Submit" | POST to `/syllabus/bloom-taxonomy` |
| 7 | Check response | Success: "Bloom taxonomy created successfully." |
| 8 | Redirect to bloom taxonomy tab with tab=bloom_taxonomy | Page reloads, record visible in table |
| 9 | DB check: `SELECT * FROM slb_bloom_taxonomy WHERE code='REMEMBERING'` | Record exists with all required fields, `is_active=1` |

---

#### TC-P05: Create Bloom Taxonomy With All Optional Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "CREATING", name: "Creating", bloom_level: 6 | Required fields set |
| 3 | Enter description: "Putting elements together to form a coherent whole" | Description filled |
| 4 | Set is_active ON | Toggle ON |
| 5 | Click "Save" | Record created |
| 6 | DB check: `SELECT * FROM slb_bloom_taxonomy WHERE code='CREATING'` | Description and is_active saved correctly |

---

#### TC-P06: Create Bloom Taxonomy With Code Auto-Uppercase

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "remembering" (lowercase), name: "Remembering", bloom_level: 1 | Code is lowercase |
| 3 | Click "Save" | Record created |
| 4 | DB check: `SELECT code FROM slb_bloom_taxonomy WHERE name='Remembering'` | code = "REMEMBERING" (uppercased) |

---

#### TC-P07: Create Bloom Taxonomy With Bloom Level 1 (Min)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "LEVEL1", name: "Level One", bloom_level: 1 | Minimum level |
| 3 | Click "Save" | Record created successfully |

---

#### TC-P08: Create Bloom Taxonomy With Bloom Level 6 (Max)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "LEVEL6", name: "Level Six", bloom_level: 6 | Maximum level |
| 3 | Click "Save" | Record created successfully |

---

#### TC-P09: Edit Bloom Taxonomy Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="EDITTEST", name="Edit Test", bloom_level=3 | Record exists with ID=X |
| 2 | Click "Edit" button (pencil icon) on that row | Navigates to `/syllabus/bloom-taxonomy/{X}/edit` |
| 3 | Verify form pre-filled | code="EDITTEST", name="Edit Test", bloom_level=3 |

---

#### TC-P10: Update Bloom Taxonomy All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="OLD", name="Old Name", bloom_level=2 | Record exists with ID=X |
| 2 | Navigate to edit page for record X | Form pre-filled |
| 3 | Change code to "NEW", name to "New Name", bloom_level to 5 | Fields updated |
| 4 | Change description to "Updated description" | Updated |
| 5 | Change is_active to OFF | Toggle OFF |
| 6 | Click "Save" | PUT request to `/syllabus/bloom-taxonomy/{X}` |
| 7 | Check response | "Bloom taxonomy updated successfully." |
| 8 | DB check: `SELECT * FROM slb_bloom_taxonomy WHERE id={X}` | All fields updated; `updated_at` changed |
| 9 | Verify code is uppercased: "NEW" | `strtoupper()` applied |

---

#### TC-P11: View Bloom Taxonomy Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="VIEWTEST", name="View Test", bloom_level=4 | Record exists |
| 2 | Click "View" button (eye icon) on that row | Navigates to `/syllabus/bloom-taxonomy/{id}` |
| 3 | Check page heading | Record name displayed: "View Test" |
| 4 | Check code displayed | "VIEWTEST" |
| 5 | Check bloom_level displayed | Correct level shown |
| 6 | Check status badge | Green "Active" or red "Inactive" badge |
| 7 | Check description displayed | Description shown |

---

#### TC-P12: Soft Delete Bloom Taxonomy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="DELTEST", name="Delete Test", bloom_level=2 | Record exists with ID=X |
| 2 | Click delete button (trash icon) on that row | SweetAlert "Are you sure?" with "Move to Trash: The item can be restored later!" |
| 3 | Click "Cancel" | Alert closes, record not deleted |
| 4 | Click delete again, then click "Yes, delete it!" | AJAX DELETE sent |
| 5 | Check toast | Green toast: "Bloom taxonomy deleted successfully" |
| 6 | DB check: `SELECT deleted_at FROM slb_bloom_taxonomy WHERE id={X}` | `deleted_at` NOT NULL (soft deleted) |
| 7 | DB check: `SELECT is_active FROM slb_bloom_taxonomy WHERE id={X}` | `is_active` = 0 (set false before delete) |
| 8 | Verify record no longer visible in main list | Disappeared from list |
| 9 | Activity log: `SELECT * FROM glb_activity_logs WHERE event='Trashed' ORDER BY id DESC LIMIT 1` | "Trashed" event logged |

---

#### TC-P13: Trash Page Shows Deleted Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a record (code="TRASHTEST") | Record is trashed |
| 2 | Click "Trash" button on bloom taxonomy page | Navigates to `/syllabus/bloom-taxonomy/trash/view` |
| 3 | Check trash page loads | Heading: "Trashed Bloom Taxonomies" |
| 4 | Check table shows deleted record | "TRASHTEST" row visible |
| 5 | Check "Restore" button | Button/link present on each row |
| 6 | Check "Force Delete" button | Force delete button present |

---

#### TC-P14: Restore Bloom Taxonomy From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash page (record "TRASHTEST" is soft-deleted) | Trash page shows the record |
| 2 | Click "Restore" on that row | SweetAlert "Sure to restore?" |
| 3 | Click confirm | Restore succeeds |
| 4 | Check toast | Success message: "Bloom taxonomy restored successfully" |
| 5 | DB check: `SELECT deleted_at FROM slb_bloom_taxonomy WHERE id={X}` | `deleted_at` = NULL (restored) |
| 6 | DB check: `SELECT is_active FROM slb_bloom_taxonomy WHERE id={X}` | `is_active` = 1 (set true on restore) |
| 7 | Navigate back to main bloom taxonomy tab | Record visible again |
| 8 | Activity log: `SELECT * FROM glb_activity_logs WHERE event='Restored'` | "Restored" event logged |

---

#### TC-P15: Force Delete Bloom Taxonomy (No Dependencies)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record (code="FORCETEST", name="Force Test", bloom_level=3) then soft-delete it | Record is in trash |
| 2 | Navigate to trash page | Trash page shows "FORCETEST" |
| 3 | Click "Force Delete" on that row | SweetAlert "Delete Permanently ?" with warning text |
| 4 | Click confirm | Force delete succeeds |
| 5 | Check toast | "Bloom taxonomy deleted permanently" |
| 6 | DB check: `SELECT * FROM slb_bloom_taxonomy WHERE code='FORCETEST'` WITH trashed | Record permanently gone |
| 7 | Activity log: "Deleted" event logged | Event exists |

---

#### TC-P16: Toggle Status Active ↔ Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with is_active=ON (code="TOGGLETEST") | Record is active |
| 2 | Click the status toggle switch on that row | AJAX POST to `/syllabus/bloom-taxonomy/{id}/toggle-status` |
| 3 | Check response | JSON `{success: true, is_active: false, message: "Status updated successfully"}` |
| 4 | DB check: `SELECT is_active FROM slb_bloom_taxonomy WHERE id={id}` | is_active=0 (false) |
| 5 | Status badge in table changes to "Inactive" | Badge updated |
| 6 | Click the toggle switch again | AJAX POST sent again |
| 7 | DB check: `SELECT is_active FROM slb_bloom_taxonomy WHERE id={id}` | is_active=1 (true) — toggled back |
| 8 | Activity log: 2 entries with event="Toggled" | Both toggles logged |

---

#### TC-P17: Records Ordered By Bloom Level Ascending

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create records with bloom_level=6, bloom_level=1, bloom_level=3 | 3 records exist |
| 2 | Navigate to bloom taxonomy list | Records displayed in order: level 1, level 3, level 6 |

---

#### TC-P18: Pagination Works (10 Per Page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 11+ bloom taxonomy records | Records exist |
| 2 | Navigate to bloom taxonomy list | Page 1 shows first 10 records |
| 3 | Check pagination links | Pagination bar visible with page 2 |
| 4 | Click page 2 | Remaining records displayed |

---

#### TC-P19: Full Lifecycle: Create → Edit → Toggle → Delete → Trash → Restore → Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="LIFECYCLE", name="Lifecycle", bloom_level=4 | Record created successfully |
| 2 | Edit record: change name to "Lifecycle Updated" | Update succeeds |
| 3 | Toggle status OFF then ON | Both toggles succeed, is_active flips each time |
| 4 | Soft delete record | `deleted_at` set |
| 5 | Navigate to trash page | Record visible in trash |
| 6 | Restore record | `deleted_at` = NULL |
| 7 | Navigate to main list | Record visible again |
| 8 | Soft delete again | `deleted_at` set |
| 9 | Navigate to trash, force delete | Record permanently removed |
| 10 | Verify activity logs for: Trashed, Restored, Deleted, Toggled | All events logged |

---

#### TC-P20: Empty State — No Records Yet

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to bloom taxonomy tab (no records exist) | Page loads |
| 2 | Observe the table area | Table shows "No records found" message |
| 3 | Check Add New button | Visible and enabled |

---

### 6.2 Negative TC Steps

#### TC-N01: Required — Missing Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter name: "Test", bloom_level: 1 | Code left empty |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Bloom taxonomy code is required." | Error returned |

---

#### TC-N02: Required — Missing Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "TEST", bloom_level: 1 | Name left empty |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Bloom taxonomy name is required." | Error returned |

---

#### TC-N03: Required — Missing Bloom Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "TEST", name: "Test" | bloom_level left empty |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Bloom level is required." | Error returned |

---

#### TC-N04: Invalid Code — Non-Alpha Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "REMEMBERING_1" (contains underscore and number) | Code has non-alpha characters |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Code must contain only letters." | Error returned |

---

#### TC-N05: Invalid Code — Exceeds 20 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code of 21 characters: "ABCDEFGHIJKLMNOPQRSTU" | Exceeds max |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Code must not exceed 20 characters." | Error returned |

---

#### TC-N06: Duplicate Code (Global Unique)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pre-requisite: Create record with code="UNIQUE01" | Code taken |
| 2 | Open Add New, enter code="UNIQUE01" | Same code |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "This bloom taxonomy code already exists." | Error returned |

---

#### TC-N07: Max Length — Name > 100 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter name of 101 characters | Exceeds max |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Name must not exceed 100 characters." | Error returned |

---

#### TC-N08: Invalid Bloom Level — Not An Integer

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter bloom_level: "abc" (string) | Not an integer |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Bloom level must be an integer." | Error returned |

---

#### TC-N09: Invalid Bloom Level — Below 1 (Zero)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter bloom_level: 0 | Below minimum |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Bloom level must be between 1 and 6." | Error returned |

---

#### TC-N10: Invalid Bloom Level — Above 6 (e.g. 7)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter bloom_level: 7 | Above maximum |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Bloom level must be between 1 and 6." | Error returned |

---

#### TC-N11: Max Length — Description > 255 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter description of 256 characters | Exceeds max |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Description must not exceed 255 characters." | Error returned |

---

#### TC-N12: View Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open URL: `/syllabus/bloom-taxonomy/99999` (non-existent) | HTTP 404 or redirect with "Bloom taxonomy not found" |

---

#### TC-N13: Edit/Update Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open URL: `/syllabus/bloom-taxonomy/99999/edit` | HTTP 404 (Model not found) |
| 2 | Send PUT to `/syllabus/bloom-taxonomy/99999` with valid payload | HTTP 404 |

---

#### TC-N14: Delete Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send DELETE to `/syllabus/bloom-taxonomy/99999` | Redirect with "Bloom taxonomy not found" error |

---

#### TC-N15: Toggle Status With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `/syllabus/bloom-taxonomy/99999/toggle-status` | JSON 404: `{success: false, message: "Bloom taxonomy not found"}` |

---

#### TC-N16: Restore Non-Deleted Record (Already Active)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record that is active (not deleted) | Record exists with deleted_at=NULL |
| 2 | Send GET to `/syllabus/bloom-taxonomy/{id}/restore` | `onlyTrashed()->find($id)` returns null → 404 error |

---

#### TC-N17: Force Delete Non-Trashed Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record that is active (not deleted) | Record exists with deleted_at=NULL |
| 2 | Send DELETE to `/syllabus/bloom-taxonomy/{id}/force-delete` | `onlyTrashed()->find($id)` returns null → 404 error |

---

#### TC-N18: Permission 403 — No Bloom Taxonomy Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without any `tenant.bloom-taxonomy.*` permissions | Dashboard loads |
| 2 | Navigate to bloom taxonomy tab (index) | 403 Forbidden (missing viewAny) |
| 3 | POST to `/syllabus/bloom-taxonomy` (store) without create permission | 403 Forbidden |
| 4 | PUT to `/syllabus/bloom-taxonomy/{id}` without update permission | 403 Forbidden |
| 5 | DELETE to `/syllabus/bloom-taxonomy/{id}` without delete permission | 403 Forbidden |
| 6 | POST to `/syllabus/bloom-taxonomy/{id}/toggle-status` without update permission | 403 Forbidden |
| 7 | GET to `/syllabus/bloom-taxonomy/trash/view` without restore permission | 403 Forbidden |
| 8 | GET to `/syllabus/bloom-taxonomy/{id}/restore` without restore permission | 403 Forbidden |
| 9 | DELETE to `/syllabus/bloom-taxonomy/{id}/force-delete` without forceDelete permission | 403 Forbidden |

---

#### TC-N19: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout completely | — |
| 2 | Navigate to bloom taxonomy tab | Redirected to login page |
| 3 | Try POST to `/syllabus/bloom-taxonomy` | Redirected to login or 401 Unauthorized |
| 4 | Try any other bloom taxonomy route | Redirected to login |

---

#### TC-N20: XSS Injection In Name/Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with name=`<script>alert('xss')</script>`, code="XSS01" | Record created (server accepts string) |
| 2 | DB check: `SELECT name FROM slb_bloom_taxonomy WHERE code='XSS01'` | Stored as-is `<script>alert('xss')</script>` |
| 3 | View the record on the list page | Script does NOT execute — Blade `{{ }}` auto-escapes HTML |
| 4 | Clean up: force delete the XSS record | Record removed |

---

#### TC-N21: Whitespace-Only Name/Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code="   " (spaces only), name="   " (spaces only) | Empty strings after trim |
| 3 | Click "Save" | Validation fails: "Bloom taxonomy code is required", "Bloom taxonomy name is required" |

---


| 2 | Verify the screen only loads when accessed via the Syllabus page tab | Tab integration works correctly |

---

### 6.3 Dependency TC Steps

#### TC-D01: Force Delete Bloom Taxonomy — Cognitive Skills bloom_id Set NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create bloom taxonomy record B1 and a cognitive skill linked to B1 | Skill has bloom_id = B1.id |
| 2 | Soft delete B1 | B1 in trash |
| 3 | Force delete B1 | B1 permanently removed |
| 4 | DB check: `SELECT bloom_id FROM slb_cognitive_skill WHERE id={skillId}` | bloom_id = NULL (ON DELETE SET NULL) |

---

#### TC-D02: Soft-Delete Record Hidden From Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active bloom taxonomy record | Record is active |
| 2 | Soft delete the record | Record is trashed |
| 3 | Navigate to cognitive skills create form (parent bloom dropdown) | Deleted record NOT in dropdown options |
| 4 | Restore the record | Record appears in dropdowns again |

---

#### TC-D03: Cannot Force Delete If Cognitive Skills Exist (Business Rule)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create bloom taxonomy record B1 and a cognitive skill linked to B1 | Skill references B1 |
| 2 | Soft delete B1 | B1 in trash |
| 3 | Force delete B1 | Force delete succeeds (ON DELETE SET NULL handles FK) |
| 4 | DB check: cognitive skill still exists with bloom_id = NULL | Record preserved, FK set to null |

---

#### TC-D04: Toggle Status — Inactive Record Hidden From Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active bloom taxonomy record | Record is active |
| 2 | Toggle status to inactive | is_active = 0 |
| 3 | Navigate to cognitive skills create form | Inactive record NOT in bloom_id dropdown |
| 4 | Toggle status back to active | Record appears in dropdowns again |

---

#### TC-D11: Uppercase Code Conversion — strtoupper() in prepareForValidation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "remember" (lowercase), name: "Remembering", bloom_level: 1 | Code is lowercase |
| 3 | Click "Save" | Record created |
| 4 | DB check: `SELECT code FROM slb_bloom_taxonomy WHERE name='Remembering'` | code = "REMEMBER" (uppercased via strtoupper()) |

---

#### TC-D12: Alpha Only Validation — code Field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "TEST_123" (contains underscore and digits) | Code has non-alpha characters |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Code must contain only letters." | Error returned |
| 5 | Enter code: "TEST-CODE" (contains dash) | Code has non-alpha characters |
| 6 | Click "Save" | HTTP 500 |
| 7 | Validation error: "Code must contain only letters." | Error returned |

---

#### TC-D13: bloom_level Range — between:1,6

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter bloom_level: 0 (below minimum) | Invalid value |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Bloom level must be between 1 and 6." | Error returned |
| 5 | Enter bloom_level: 7 (above maximum) | Invalid value |
| 6 | Click "Save" | HTTP 500 |
| 7 | Validation error: "Bloom level must be between 1 and 6." | Error returned |
| 8 | Enter bloom_level: -1 (negative) | Invalid value |
| 9 | Click "Save" | HTTP 500 |
| 10 | Validation error: "Bloom level must be between 1 and 6." | Error returned |
| 11 | Enter bloom_level: 1 (valid minimum) | Valid value |
| 12 | Click "Save" | Record created successfully |
| 13 | Enter bloom_level: 6 (valid maximum) | Valid value |
| 14 | Click "Save" | Record created successfully |

---

#### TC-D14: Level Text Mapping — getLevelTextAttribute()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with bloom_level=1, code="LVL01", name="Remembering" | Record exists |
| 2 | View the record or list page | Level text shows "Remembering" |
| 3 | Create record with bloom_level=2, code="LVL02", name="Understanding" | Record exists |
| 4 | View the record or list page | Level text shows "Understanding" |
| 5 | Create record with bloom_level=3, code="LVL03", name="Applying" | Record exists |
| 6 | View the record or list page | Level text shows "Applying" |
| 7 | Create record with bloom_level=4, code="LVL04", name="Analyzing" | Record exists |
| 8 | View the record or list page | Level text shows "Analyzing" |
| 9 | Create record with bloom_level=5, code="LVL05", name="Evaluating" | Record exists |
| 10 | View the record or list page | Level text shows "Evaluating" |
| 11 | Create record with bloom_level=6, code="LVL06", name="Creating" | Record exists |
| 12 | View the record or list page | Level text shows "Creating" |

---

#### TC-D15: is_active Default Update — boolean() handles unchecked checkbox

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with is_active=ON (code="ACTIVE01") | Record is active |
| 2 | Navigate to edit page | Form pre-filled |
| 3 | Uncheck is_active checkbox (or leave unchecked) | is_active unchecked |
| 4 | Click "Save" | PUT request sent |
| 5 | DB check: `SELECT is_active FROM slb_bloom_taxonomy WHERE code='ACTIVE01'` | is_active = 0 (false) — unchecked checkbox defaults to false |

---

#### TC-D16: AJAX Toggle — toggleStatus route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with is_active=ON (code="TOGGLE02") | Record is active |
| 2 | Click the status toggle switch on that row | AJAX POST to `/syllabus/bloom-taxonomy/{id}/toggle-status` |
| 3 | Check response | JSON `{success: true, is_active: false, message: "Status updated successfully"}` |
| 4 | Status badge changes to "Inactive" without page reload | UI updated via AJAX |
| 5 | Click toggle again | AJAX POST sent |
| 6 | Check response | JSON `{success: true, is_active: true, message: "Status updated successfully"}` |

---

#### TC-R01: Model Table — `slb_bloom_taxonomy` exists with all expected columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open migration file for `slb_bloom_taxonomy` table | Migration exists with `Schema::create('slb_bloom_taxonomy', ...)` |
| 2 | Check columns list | Contains: `id` (PK, auto-increment), `code` (VARCHAR(20), UNIQUE, NOT NULL), `name` (VARCHAR(100), NOT NULL), `description` (VARCHAR(255), NULLABLE), `bloom_level` (TINYINT, NOT NULL), `is_active` (TINYINT(1), NOT NULL DEFAULT 1), `created_at`, `updated_at`, `deleted_at` |
| 3 | Verify `Schema::hasTable('slb_bloom_taxonomy')` | Run artisan migration; table is created successfully |
| 4 | Verify model maps to correct table via `protected $table = 'slb_bloom_taxonomy'` or convention | `BloomTaxonomy` model reads from `slb_bloom_taxonomy` |

---

#### TC-R02: Model Fillable — `$fillable` array permits mass-assignment on fillable attributes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `BloomTaxonomy` model file | Model located at `Modules/Syllabus/Models/BloomTaxonomy.php` |
| 2 | Inspect `$fillable` property | Array contains: `code`, `name`, `description`, `bloom_level`, `is_active` |
| 3 | Ensure `$guarded` is not set or is empty | Model uses `$fillable` whitelist; no unguarded mass-assignment |
| 4 | Verify `$fillable` does NOT include `id`, `created_at`, `updated_at`, `deleted_at` | System-managed columns are protected from mass-assignment |

---

#### TC-R03: Model SoftDeletes — `SoftDeletes` trait imported and `deleted_at` populated on delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `BloomTaxonomy` model | File uses `SoftDeletes` inside class definition |
| 2 | Verify `$dates` or `$casts` includes `deleted_at` as datetime | `deleted_at` is a `\Illuminate\Support\Carbon` instance |
| 3 | Send DELETE to a bloom taxonomy record | `destroy()` calls `delete()` on model |
| 4 | DB check: `SELECT deleted_at FROM slb_bloom_taxonomy WHERE id={id}` | `deleted_at` NOT NULL (timestamp set) |
| 5 | Run `BloomTaxonomy::withTrashed()->find($id)` | Record returned (visible with trashed scope) |
| 6 | Run `BloomTaxonomy::find($id)` | Returns null (excluded by default global scope) |

---

#### TC-R04: Model Relationships — `hasMany('cognitiveSkills')` defined and returns related collection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `BloomTaxonomy` model | Method `cognitiveSkills()` defined returning `$this->hasMany(CognitiveSkill::class, 'bloom_id')` |
| 2 | Verify related model `CognitiveSkill` exists | File exists at `Modules/Syllabus/Models/CognitiveSkill.php` |
| 3 | Create a bloom taxonomy and 2 cognitive skills referencing it | Skills linked via `bloom_id` FK |
| 4 | Run `BloomTaxonomy::with('cognitiveSkills')->find($bloomId)` | Returns bloom taxonomy with `cognitiveSkills` collection of 2 items |
| 5 | Create a bloom taxonomy with zero skills | `cognitiveSkills` returns empty collection (not null) |

---

#### TC-R05: Model Casts — `$casts` array declares `is_active => boolean` and `bloom_level => integer`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `BloomTaxonomy` model `$casts` property | Array contains `is_active => 'boolean'` and `bloom_level => 'integer'` |
| 2 | Fetch record with `is_active=1` from DB | `$record->is_active` returns `true` (boolean, not int 1) |
| 3 | Fetch record with `is_active=0` from DB | `$record->is_active` returns `false` (boolean, not int 0) |
| 4 | Fetch record with `bloom_level=3` from DB | `$record->bloom_level` returns `3` (integer, not string) |
| 5 | Use `var_dump($record->is_active)` | Type is `bool` |
| 6 | Use `var_dump($record->bloom_level)` | Type is `int` |

---

#### TC-R06: Controller `findOrFail` — Invalid ID returns 404 `ModelNotFoundException`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller `show()` method | Contains `$record = BloomTaxonomy::withTrashed()->findOrFail($id)` |
| 2 | Open controller `edit()` method | Contains `findOrFail($id)` |
| 3 | Open controller `update()` method | Contains `findOrFail($id)` |
| 4 | Open controller `destroy()` method | Contains `findOrFail($id)` before gate + logic |
| 5 | Open controller `toggleStatus()` method | Contains `findOrFail($id)` before gate + logic |
| 6 | Open controller `restore()` method | Contains `onlyTrashed()->findOrFail($id)` |
| 7 | Open controller `forceDelete()` method | Contains `onlyTrashed()->findOrFail($id)` |
| 8 | Verify no method uses raw `->find($id)` without null check | All lookups wrap with `findOrFail` for 404 consistency |

---

#### TC-R07: Controller Gate Authorization — `Gate::authorize()` called in all CRUD methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller `index()` | Contains `Gate::authorize('tenant.bloom-taxonomy.viewAny')` at method start |
| 2 | Open controller `create()` | Contains `Gate::authorize('tenant.bloom-taxonomy.create')` |
| 3 | Open controller `store()` | Contains `Gate::authorize('tenant.bloom-taxonomy.create')` |
| 4 | Open controller `show()` | Contains `Gate::authorize('tenant.bloom-taxonomy.view')` |
| 5 | Open controller `edit()` | Contains `Gate::authorize('tenant.bloom-taxonomy.update')` |
| 6 | Open controller `update()` | Contains `Gate::authorize('tenant.bloom-taxonomy.update')` |
| 7 | Open controller `destroy()` | Contains `Gate::authorize('tenant.bloom-taxonomy.delete')` |
| 8 | Open controller `trashed()` | Contains `Gate::authorize('tenant.bloom-taxonomy.restore')` |
| 9 | Open controller `restore()` | Contains `Gate::authorize('tenant.bloom-taxonomy.restore')` |
| 10 | Open controller `forceDelete()` | Contains `Gate::authorize('tenant.bloom-taxonomy.forceDelete')` |
| 11 | Open controller `toggleStatus()` | Contains `Gate::authorize('tenant.bloom-taxonomy.status')` |

---

#### TC-R08: Activity Log Integration — All lifecycle events logged

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller `store()` | After save, calls `activityLog(...)` with event `Stored` and subject model |
| 2 | Open controller `update()` | After save, calls `activityLog(...)` with event `Updated` |
| 3 | Open controller `destroy()` | After delete, calls `activityLog(...)` with event `Trashed` |
| 4 | Open controller `restore()` | After restore, calls `activityLog(...)` with event `Restored` |
| 5 | Open controller `forceDelete()` | After force delete, calls `activityLog(...)` with event `Deleted` |
| 6 | Open controller `toggleStatus()` | After toggle, calls `activityLog(...)` with event `Toggled` |
| 7 | Verify `glb_activity_logs` table has entries | Column `subject_type` = `BloomTaxonomy::class`, `causer_id` = auth user, `event` matches action |

---

#### TC-R09: `is_active` Toggle Before Delete — destroy() sets is_active=false before delete()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller `destroy()` method | `$record->is_active = false; $record->save();` executed before `$record->delete()` |
| 2 | Create record with `is_active=1` | Record is active |
| 3 | Soft delete the record via UI/API | DELETE request sent |
| 4 | DB check: `SELECT is_active, deleted_at FROM slb_bloom_taxonomy WHERE id={id}` | `is_active = 0` (false) and `deleted_at` NOT NULL |
| 5 | Restore the record | `restore()` sets `is_active = true` |
| 6 | DB check after restore | `is_active = 1` (true) and `deleted_at = NULL` |

---

#### TC-R10: Unique Code Validation — No duplicate codes allowed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `BloomTaxonomyRequest` | Create rules contain `unique:slb_bloom_taxonomy,code` |
| 2 | Open `BloomTaxonomyRequest` update rules | Contains `unique:slb_bloom_taxonomy,code,` + `$this->route('bloom_taxonomy')` (ignore current ID) |
| 3 | Create record with code="UNIQUE01" | Record created |
| 4 | Create another record with code="UNIQUE01" | HTTP 500: "This bloom taxonomy code already exists." |
| 5 | Update the first record without changing code | PUT succeeds (ignores own ID) |
| 6 | Update code to another existing code | HTTP 500: duplicate violation |
| 7 | Verify soft-deleted records can be reused or rejected | Unique check includes soft-deleted records (global scope applies) |

---

#### TC-R11: Required Field Validation — code/name/bloom_level are required

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `BloomTaxonomyRequest` rules array | `code` has `required`, `name` has `required`, `bloom_level` has `required` |
| 2 | Submit create request with empty code | HTTP 500: "Bloom taxonomy code is required." |
| 3 | Submit create request with empty name | HTTP 500: "Bloom taxonomy name is required." |
| 4 | Submit create request with empty bloom_level | HTTP 500: "Bloom level is required." |
| 5 | Submit create request with only code/name/bloom_level (description and is_active omitted) | HTTP 201: record created (nullable fields not required) |
| 6 | Open update rules in same request | Required rules also present on update |

---

#### TC-R12: Max Length Constraints — code:max:20, name:max:100, description:max:255

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `BloomTaxonomyRequest` create rules | `code` has `max:20`, `name` has `max:100`, `description` has `max:255` |
| 2 | Submit code with exactly 20 alpha chars | HTTP 201: accepted (boundary) |
| 3 | Submit code with 21 alpha chars | HTTP 500: "Code must not exceed 20 characters." |
| 4 | Submit name with exactly 100 chars | HTTP 201: accepted (boundary) |
| 5 | Submit name with 101 chars | HTTP 500: "Name must not exceed 100 characters." |
| 6 | Submit description with exactly 255 chars | HTTP 201: accepted (boundary) |
| 7 | Submit description with 256 chars | HTTP 500: "Description must not exceed 255 characters." |

---

#### TC-R13: Boolean Cast for `is_active` — DB stores TINYINT(1), model returns boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `BloomTaxonomy` model `$casts` | Confirms `is_active => 'boolean'` |
| 2 | Open migration for `slb_bloom_taxonomy` | `is_active` column is `tinyInteger('is_active')->default(1)` or `boolean('is_active')->default(true)` |
| 3 | Create record with `is_active=true` | DB stores `1` (TINYINT) |
| 4 | Fetch record and check `$record->is_active` | Returns `true` (PHP boolean) |
| 5 | Create record with `is_active=false` | DB stores `0` (TINYINT) |
| 6 | Fetch record and check `$record->is_active` | Returns `false` (PHP boolean) |
| 7 | Update record with `$request->boolean('is_active')` | Request helper returns boolean; model cast handles correctly |

---

#### TC-R14: Policy Gates — `BloomTaxonomyPolicy` defines all required gates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `BloomTaxonomyPolicy` file | File exists at `Modules/Syllabus/Policies/BloomTaxonomyPolicy.php` |
| 2 | Verify `viewAny()` method | Returns `$user->hasPermissionTo('tenant.bloom-taxonomy.viewAny')` |
| 3 | Verify `view()` method | Returns `$user->hasPermissionTo('tenant.bloom-taxonomy.view')` |
| 4 | Verify `create()` method | Returns `$user->hasPermissionTo('tenant.bloom-taxonomy.create')` |
| 5 | Verify `update()` method | Returns `$user->hasPermissionTo('tenant.bloom-taxonomy.update')` |
| 6 | Verify `delete()` method | Returns `$user->hasPermissionTo('tenant.bloom-taxonomy.delete')` |
| 7 | Verify `restore()` method | Returns `$user->hasPermissionTo('tenant.bloom-taxonomy.restore')` |
| 8 | Verify `forceDelete()` method | Returns `$user->hasPermissionTo('tenant.bloom-taxonomy.forceDelete')` |
| 9 | Verify `status()` or check that toggle uses update gate | Controller `toggleStatus()` uses `Gate::authorize('tenant.bloom-taxonomy.status')` or `'tenant.bloom-taxonomy.update'` |
| 10 | Ensure `$gate->before()` or `$gate->after()` does not bypass all checks | Policy methods are individually enforced |

---

#### TC-R15: Route Registration — Resourceful route + custom action routes registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/api.php` or `routes/web.php` for syllabus module | `Route::resource('bloom-taxonomy', BloomTaxonomyController::class)` present |
| 2 | Run `php artisan route:list --path=bloom-taxonomy` | All 7 resource routes listed: GET index, GET create, POST store, GET show, GET edit, PUT update, DELETE destroy |
| 3 | Verify custom `trash/view` route | `GET /syllabus/bloom-taxonomy/trash/view` -> `trashed()` |
| 4 | Verify custom `restore` route | `GET /syllabus/bloom-taxonomy/{id}/restore` -> `restore()` |
| 5 | Verify custom `force-delete` route | `DELETE /syllabus/bloom-taxonomy/{id}/force-delete` -> `forceDelete()` |
| 6 | Verify custom `toggle-status` route | `POST /syllabus/bloom-taxonomy/{id}/toggle-status` -> `toggleStatus()` |
| 7 | Verify all routes pass through `auth` and `tenant` middleware | Route group middleware includes `auth:sanctum` or `web` and tenancy initialization |
