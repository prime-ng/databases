# slb_cognitive_skill_TcList

## Module: Syllabus → Syllabus Master → Cognitive Skills

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Syllabus Master |
| Feature | Cognitive Skills |
| URL(s) | `/syllabus/bloom` (index via tab), `/syllabus/cognitive-skills/create` (create), `/syllabus/cognitive-skills` (store), `/syllabus/cognitive-skills/{id}` (show), `/syllabus/cognitive-skills/{id}/edit` (edit), `/syllabus/cognitive-skills/{id}` (update), `/syllabus/cognitive-skills/trash/view` (trash), `/syllabus/cognitive-skills/{id}/restore` (restore), `/syllabus/cognitive-skills/{id}/force-delete` (forceDelete), `/syllabus/cognitive-skills/{id}/toggle-status` (toggleStatus) |
| Controller | `Modules\Syllabus\Http\Controllers\CognitiveSkillController` |
| Model(s) | `Modules\Syllabus\Models\CognitiveSkill` |
| Validation (Create) | `Modules\Syllabus\Http\Requests\CognitiveSkillRequest` |
| Validation (Update) | `Modules\Syllabus\Http\Requests\CognitiveSkillRequest` (ignores current ID for unique) |
| Permissions | `tenant.cognitive-skill.viewAny`, `tenant.cognitive-skill.view`, `tenant.cognitive-skill.create`, `tenant.cognitive-skill.update`, `tenant.cognitive-skill.delete`, `tenant.cognitive-skill.restore`, `tenant.cognitive-skill.forceDelete`, `tenant.cognitive-skill.status` |
| Soft Deletes | Yes (`CognitiveSkill` uses `SoftDeletes` trait) |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |
| Import | Not supported |

---

## 2. Pre-conditions

- Required permissions: `tenant.cognitive-skill.viewAny`, `tenant.cognitive-skill.view`, `tenant.cognitive-skill.create`, `tenant.cognitive-skill.update`, `tenant.cognitive-skill.delete`, `tenant.cognitive-skill.restore`, `tenant.cognitive-skill.forceDelete`, `tenant.cognitive-skill.status`
- Required seed data: At least one active `BloomTaxonomy` record for parent linkage
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
- **Cognitive skill code**: Uppercase alpha letters only, max 20 chars, globally unique
- **Parent bloom_id**: Nullable FK to slb_bloom_taxonomy.id
- **Pre-test cleanup**: Delete created records by code before/after tests to avoid collisions
- **JSON fields**: None

---

## 5. Business Conditions

### 4.1 Database Schema — `slb_cognitive_skill`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | bloom_id | INT UNSIGNED | FK → `slb_bloom_taxonomy.id`, ON DELETE SET NULL, DEFAULT NULL |
| BC-DB-03 | code | VARCHAR(20) | NOT NULL, UNIQUE |
| BC-DB-04 | name | VARCHAR(100) | NOT NULL |
| BC-DB-05 | description | VARCHAR(255) | DEFAULT NULL |
| BC-DB-06 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 (cast to boolean) |
| BC-DB-07 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-08 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-09 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules — `CognitiveSkillRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | code | required, string, alpha, max:20, unique:slb_cognitive_skill,code | "Cognitive skill code is required." |
| BC-VAL-02 | code | alpha | "Code must contain only letters." |
| BC-VAL-03 | code | unique | "This cognitive skill code already exists." |
| BC-VAL-04 | name | required, string, max:100 | "Cognitive skill name is required." |
| BC-VAL-05 | name | max:100 | "Name must not exceed 100 characters." |
| BC-VAL-06 | bloom_id | nullable, integer | — |
| BC-VAL-07 | description | nullable, string, max:255 | — |
| BC-VAL-08 | is_active | nullable, boolean | — |

### 4.3 Validation Rules — `CognitiveSkillRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | code | required, string, alpha, max:20, unique:slb_cognitive_skill,code + ignore($id) | "Cognitive skill code is required." |
| BC-VAL-U02 | code | alpha | "Code must contain only letters." |
| BC-VAL-U03 | code | unique + ignore | "This cognitive skill code already exists." |
| BC-VAL-U04 | name | required, string, max:100 | "Cognitive skill name is required." |
| BC-VAL-U05 | name | max:100 | "Name must not exceed 100 characters." |
| BC-VAL-U06 | bloom_id | nullable, integer | — |
| BC-VAL-U07 | description | nullable, string, max:255 | — |
| BC-VAL-U08 | is_active | nullable, boolean | — |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.cognitive-skill.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.cognitive-skill.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.cognitive-skill.create | store(), create() | Without → 403 |
| BC-AUTH-04 | tenant.cognitive-skill.update | update(), edit(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.cognitive-skill.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.cognitive-skill.restore | restore(), trashed() | Without → 403 |
| BC-AUTH-07 | tenant.cognitive-skill.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.cognitive-skill.status | toggleStatus() (via update gate) | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-02 | Default is_active on create | Defaults to true (model default 1) |
| BC-BIZ-03 | Code auto-uppercase | `strtoupper(trim($code))` applied in `prepareForValidation()` |
| BC-BIZ-04 | Name trimming | `trim()` applied in both store and update |
| BC-BIZ-05 | Delete sets is_active false | `destroy()` sets `is_active = false` before calling `delete()` |
| BC-BIZ-06 | Restore sets is_active true | `restore()` sets `is_active = true` |
| BC-BIZ-07 | Status toggle | `is_active` flips via `$record->is_active = !$record->is_active`; returns JSON `{success, is_active, message}` |
| BC-BIZ-08 | Force delete cascades question type specificity | On force delete, `slb_ques_type_specificity.cognitive_skill_id` → NULL (ON DELETE SET NULL) |
| BC-BIZ-09 | Show uses withTrashed | `show()` calls `withTrashed()->findOrFail($id)` to display both active and trashed |
| BC-BIZ-10 | Pagination | Index paginated at 10 per page |
| BC-BIZ-11 | Activity log — Stored | On create |
| BC-BIZ-12 | Activity log — Updated | On update |
| BC-BIZ-13 | Activity log — Trashed | On soft delete |
| BC-BIZ-14 | Activity log — Restored | On restore |
| BC-BIZ-15 | Activity log — Deleted | On force delete |
| BC-BIZ-16 | Activity log — Toggled | On status toggle |
| BC-BIZ-17 | Redirect after CRUD | Redirect to `syllabus.bloom.index` with tab `cognitive_skills` |
| BC-BIZ-18 | Eager load bloom relation | Index and show eager-load `bloom` relation for parent name display |
| BC-BIZ-19 | Bloom_id nullable | Cognitive skill can be created without linking to a Bloom taxonomy |
| BC-BIZ-20 | Screen loads via SyllabusController@bloom() at GET /syllabus/bloom with bloom tab group | Navigating to GET /syllabus/bloom with appropriate permissions loads the Bloom tab group; this screen's grid data is fetched and displayed |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | bloom_id | slb_bloom_taxonomy (id) | SET NULL |
| BC-REF-02 | cognitive_skill_id (in slb_ques_type_specificity) | slb_cognitive_skill (id) | SET NULL |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Cognitive Skills List Page Loads With All UI Elements | Page loads with Add New button, Trash button, search, table columns: Code, Name, Bloom Level, Description, Status, Actions | — | — | ⬜ |
| TC-P02 | Search Cognitive Skills By Name Or Code | Table filters to show only matching records | — | — | ⬜ |
| TC-P03 | Filter By Active/Inactive Status | Active filter shows only active; Inactive shows only inactive | — | — | ⬜ |
| TC-P04 | Create Cognitive Skill With All Required Fields | Record created with correct values (code, name) | — | — | ⬜ |
| TC-P05 | Create Cognitive Skill With Parent Bloom Taxonomy | bloom_id linked correctly to a valid Bloom Taxonomy record | — | — | ⬜ |
| TC-P06 | Create Cognitive Skill Without Parent (bloom_id = NULL) | Skill created with bloom_id = NULL | — | — | ⬜ |
| TC-P07 | Create Cognitive Skill With All Optional Fields | Description, is_active saved correctly | — | — | ⬜ |
| TC-P08 | Create Cognitive Skill With Code Auto-Uppercase | Code `critiquing` stored as `CRITIQUING` | — | — | ⬜ |
| TC-P09 | Edit Cognitive Skill Loads Pre-Filled Data | Edit page shows existing record data with bloom parent dropdown | — | — | ⬜ |
| TC-P10 | Update Cognitive Skill All Fields | Code, name, description, bloom_id, is_active all updated | — | — | ⬜ |
| TC-P11 | Update Cognitive Skill — Change Bloom Parent | bloom_id updated to a different valid Bloom Taxonomy | — | — | ⬜ |
| TC-P12 | View Cognitive Skill Details Page | Record details shown with code, name, bloom parent, description, status | — | — | ⬜ |
| TC-P13 | Soft Delete Cognitive Skill | `deleted_at` set; record no longer visible on main list | — | — | ⬜ |
| TC-P14 | Trash Page Shows Deleted Records | `/syllabus/cognitive-skills/trash/view` lists only soft-deleted records | — | — | ⬜ |
| TC-P15 | Restore Cognitive Skill From Trash | `deleted_at` set to NULL; record visible again; activity log "Restored" | — | — | ⬜ |
| TC-P16 | Force Delete Cognitive Skill (No Dependencies) | Record permanently removed; related question type specificity FK set to NULL | — | — | ⬜ |
| TC-P17 | Toggle Status Active ↔ Inactive | `is_active` flips value; AJAX 200 with success message | — | — | ⬜ |
| TC-P18 | Pagination Works (10 Per Page) | With 11+ records, pagination links appear | — | — | ⬜ |
| TC-P19 | Full Lifecycle: Create → Edit → Toggle → Delete → Trash → Restore → Force Delete | All 7 transitions successful; activity logged at each step | — | — | ⬜ |
| TC-P20 | Bloom Parent Name Displayed In List | Index page shows bloom taxonomy name from relationship | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing Code | Validation error: "Cognitive skill code is required." | — | — | ⬜ |
| TC-N02 | Required — Missing Name | Validation error: "Cognitive skill name is required." | — | — | ⬜ |
| TC-N03 | Invalid Code — Non-Alpha Characters | Validation error: "Code must contain only letters." | — | — | ⬜ |
| TC-N04 | Invalid Code — Exceeds 20 Characters | Validation fails on code.max | — | — | ⬜ |
| TC-N05 | Duplicate Code (Global Unique) | "This cognitive skill code already exists." | — | — | ⬜ |
| TC-N06 | Max Length — Name > 100 Characters | Validation fails on name.max | — | — | ⬜ |
| TC-N07 | Max Length — Description > 255 Characters | Validation fails on description.max | — | — | ⬜ |
| TC-N08 | Invalid bloom_id — Non-Existent Bloom Taxonomy | FK constraint error or validation error | — | — | ⬜ |
| TC-N09 | View Record With Invalid ID (404) | HTTP 404 | — | — | ⬜ |
| TC-N10 | Edit/Update Record With Invalid ID (404) | HTTP 404 | — | — | ⬜ |
| TC-N11 | Delete Record With Invalid ID (404) | Redirect with "Cognitive skill not found" | — | — | ⬜ |
| TC-N12 | Toggle Status With Invalid ID (404) | JSON 404 | — | — | ⬜ |
| TC-N13 | Restore Non-Deleted Record (Already Active) | `onlyTrashed()` returns null → 404 | — | — | ⬜ |
| TC-N14 | Force Delete Non-Trashed Record | `onlyTrashed()` returns null → 404 | — | — | ⬜ |
| TC-N15 | Permission 403 — No Cognitive Skill Permissions | 403 Forbidden on all CRUD endpoints | — | — | ⬜ |
| TC-N16 | Guest Access Redirect | Redirected to /login | — | — | ⬜ |
| TC-N17 | XSS Injection In Name/Code | Stored as literal string; Blade `{{ }}` escapes output | — | — | ⬜ |
| TC-N18 | Whitespace-Only Name/Code | Required validation catches empty/whitespace-only strings | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Force Delete Cognitive Skill — Question Type Specificity FK Set NULL | `slb_ques_type_specificity.cognitive_skill_id` = NULL for related records | — | — | ⬜ |
| TC-D02 | B | Soft-Delete Record Hidden From Dropdowns | Deleted cognitive skill excluded from question type specificity parent dropdown | — | — | ⬜ |
| TC-D03 | C | Toggle Status — Inactive Record Hidden From Dropdowns | Inactive cognitive skill excluded from specificity dropdown | — | — | ⬜ |
| TC-D04 | D | Create Skill With Bloom Taxonomy — Verify Parent Name Displayed | Bloom taxonomy name shown on index and show pages | — | — | ⬜ |
| TC-D05 | E | Delete Bloom Taxonomy — Cognitive Skill bloom_id Set NULL | Force deleting Bloom taxonomy sets cognitive skill bloom_id to NULL | — | — | ⬜ |
| TC-D06 | F | UI/API — P1 — Cognitive skill create form open — Missing bloom_id Exists Validation — validation gap in FormRequest | Submitting non-existent bloom_id is accepted (no exists rule — this is a bug) | — | — | ⬜ |
| TC-D07 | G | UI/API — P1 — Cognitive skill create form open — Uppercase Code Conversion — strtoupper() | Lowercase code "analyze" stored as "ANALYZE" | — | — | ⬜ |
| TC-D08 | H | UI/API — P1 — Cognitive skill create form open — Alpha Only Validation — `alpha` rule on code | Code accepts only letters; rejects numbers/dashes/underscores | — | — | ⬜ |
| TC-D09 | I | UI — P1 — Cognitive skill create form open — Active Bloom Taxonomy Filter — scopeActive() on bloom_id dropdown | Only is_active=1 bloom taxonomy records shown in dropdown | — | — | ⬜ |
| TC-D10 | J | DB — P1 — slb_cognitive_skill with existing bloom taxonomy — FK SET NULL — bloom_id on Bloom Deletion | Deleting referenced bloom_taxonomy sets bloom_id to NULL in cognitive_skill records | — | — | ⬜ |
| TC-D11 | K | UI/API — P1 — Cognitive skill create form open — Nullable bloom_id — optional FK | Creating without bloom_id succeeds; stores NULL in DB | — | — | ⬜ |
| TC-D12 | L | UI/API — P1 — Cognitive skill create form open — Max Length Validation — name max:100, description max:255 | Input exceeding 100/255 chars rejected; within limits accepted | — | — | ⬜ |
| TC-D13 | M | Code Review — Model — fillable property protects mass assignment | Only `bloom_id`, `code`, `name`, `description`, `is_active` are fillable; any other field passed is silently ignored | — | — | ⬜ |
| TC-D14 | N | Code Review — Model — $casts type correctness | `bloom_id` cast to integer, `is_active` cast to boolean; DB values match declared types | — | — | ⬜ |
| TC-D15 | O | Code Review — Model — SoftDeletes trait works correctly | `deleted_at` populated on delete; model excluded from queries; `withTrashed()` includes it | — | — | ⬜ |
| TC-D16 | P | Code Review — Model — belongsTo bloomTaxonomy relation loads parent | `$skill->bloom` returns `BloomTaxonomy` model instance or null; eager-loadable via `with('bloom')` | — | — | ⬜ |
| TC-D17 | Q | Code Review — Model — scopeActive returns only is_active=1 records | Scope filters `is_active = 1`; inactive records excluded from default query | — | — | ⬜ |
| TC-D18 | R | Code Review — Model — scopeByCode filters by code column | `scopeByCode($query, 'CRITIQUE')` returns records with code='CRITIQUE' | — | — | ⬜ |
| TC-D19 | S | Code Review — Model — scopeForBloom filters by bloom_id | `scopeForBloom($query, $bloomId)` returns only skills linked to given bloom taxonomy | — | — | ⬜ |
| TC-D20 | T | Code Review — Controller — Gate authorization enforced on every method | Each CRUD/action method calls `Gate::authorize('tenant.cognitive-skill.*')`; unauthenticated user receives 403 | — | — | ⬜ |
| TC-D21 | U | Code Review — Controller — Activity logged on all state transitions | `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` events recorded in activity log | — | — | ⬜ |
| TC-D22 | V | Code Review — Controller — is_active set false before soft delete | `destroy()` sets `is_active = false` then calls `delete()`; trashed record has `is_active = 0` | — | — | ⬜ |
| TC-D23 | W | Code Review — Request — code unique rule ignores soft-deleted records | Soft-deleted record with same code does not trigger unique validation error on new create | — | — | ⬜ |
| TC-D24 | X | Code Review — Request — prepareForValidation strtoupper applied before validation | Lowercase code "critique" is uppercased before unique check; validation passes against uppercase DB value | — | — | ⬜ |
| TC-D25 | Y | Code Review — Policy — All policy methods defined and return correct boolean | `viewAny/view/create/update/delete/restore/forceDelete/status` each check correct permission string | — | — | ⬜ |
| TC-D26 | Z | Code Review — Routes — All expected routes registered and named | Resourceful routes + `trash/view`, `{id}/restore`, `{id}/force-delete`, `{id}/toggle-status` resolve to correct controller actions | — | — | ⬜ |
| TC-D27 | AA | Code Review — Controller — Pagination and redirect consistency | `index()` paginates 10 per page; all store/update redirect to `syllabus.bloom.index` with `cognitive_skills` tab | — | — | ⬜ |
| TC-D28 | BB | Show soft-deleted cognitive skill via withTrashed() | `show()` calls `withTrashed()->findOrFail($id)` to display both active and trashed records | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.cognitive-skill.create'), @can('tenant.cognitive-skill.edit'), @can('tenant.cognitive-skill.delete'), @can('tenant.cognitive-skill.status'), @can('tenant.cognitive-skill.view'), @canany(['tenant.cognitive-skill.restore', 'tenant.cognitive-skill.forceDelete']) for access control on all CRUD buttons and actions | — | — | ◌ |
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
| 1 | Inspect index.blade.php for add/create button | @can('tenant.cognitive-skill.create') wraps the Add New button; user without create permission does not see it
| 2 | Inspect row-level action buttons (view, edit, delete, status toggle) | @can('tenant.cognitive-skill.view'), @can('tenant.cognitive-skill.edit'), @can('tenant.cognitive-skill.delete'), @can('tenant.cognitive-skill.status') used appropriately; expired permissions hide corresponding buttons
| 3 | Inspect trash.blade.php for restore/forceDelete buttons | @canany(['tenant.cognitive-skill.restore', 'tenant.cognitive-skill.forceDelete']) wraps action buttons in trash view
| 4 | Inspect view.blade.php for edit button | @can('tenant.cognitive-skill.edit') wraps the Edit button on show/details page
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

#### TC-P01: Cognitive Skills List Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Expand "Syllabus" from left sidebar | Menu options appear |
| 3 | Click "Syllabus Master" and select "Cognitive Skills" tab | Page loads with cognitive skills content |
| 4 | Check the search input | Search text field with placeholder present |
| 5 | Check the status filter | Dropdown with options: "All", "Active", "Inactive" |
| 6 | Check the "Add New" button | Button visible (if create permission) |
| 7 | Check the "Trash" button | Trash button visible (if restore permission) |
| 8 | Check the cognitive skills table | Columns: Code, Name, Bloom Level, Description, Status, Actions |
| 9 | Check pagination | If 10+ records exist, pagination links appear |

---

#### TC-P02: Search Cognitive Skills By Name Or Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create records: "Critiquing" (code="CRITIQUE"), "Recalling" (code="RECALL"), "Organizing" (code="ORGANIZE") | 3 records exist |
| 2 | Type "Crit" in search box and press Enter | Page reloads with `?search=Crit` |
| 3 | Verify table shows only "Critiquing" | Other 2 records not visible |
| 4 | Clear search, type "RECALL" | Only "Recalling" shown (matched by code) |
| 5 | Clear search | All 3 records visible again |

---

#### TC-P03: Filter By Active/Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active and inactive cognitive skill records | Both exist |
| 2 | Select "Active" from status filter | Only active records visible |
| 3 | Select "Inactive" from filter | Only inactive records visible |
| 4 | Select "All" | Both records visible |

---

#### TC-P04: Create Cognitive Skill With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Syllabus Master → Cognitive Skills tab | Page loads |
| 2 | Click "Add New" button | Create form opens |
| 3 | Enter code: "CRITIQUE" | Field filled |
| 4 | Enter name: "Critiquing" | Field filled |
| 5 | Click "Save" | POST to `/syllabus/cognitive-skills` |
| 6 | Check response | Success: "Cognitive skill created successfully." |
| 7 | Redirect to cognitive skills tab | Page reloads, record visible in table |
| 8 | DB check: `SELECT * FROM slb_cognitive_skill WHERE code='CRITIQUE'` | Record exists with all required fields, `is_active=1` |

---

#### TC-P05: Create Cognitive Skill With Parent Bloom Taxonomy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pre-requisite: Ensure a Bloom Taxonomy record exists (e.g., "Evaluating", id=X) | Bloom record exists |
| 2 | Open Add New form | Form visible |
| 3 | Enter code: "CRITIQUE_WP", name: "Critiquing With Parent" | Fields set |
| 4 | Select "Evaluating" from bloom_id dropdown | Parent selected |
| 5 | Click "Save" | Record created |
| 6 | DB check: `SELECT bloom_id FROM slb_cognitive_skill WHERE code='CRITIQUE_WP'` | bloom_id = X |

---

#### TC-P06: Create Cognitive Skill Without Parent (bloom_id = NULL)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "NOSKILL", name: "No Parent Skill" | Fields set |
| 3 | Leave bloom_id dropdown unselected (null) | No parent |
| 4 | Click "Save" | Record created |
| 5 | DB check: `SELECT bloom_id FROM slb_cognitive_skill WHERE code='NOSKILL'` | bloom_id = NULL |

---

#### TC-P07: Create Cognitive Skill With All Optional Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "FULLSKILL", name: "Full Skill", select a bloom parent | Required fields set |
| 3 | Enter description: "This skill involves critiquing arguments" | Description filled |
| 4 | Set is_active ON | Toggle ON |
| 5 | Click "Save" | Record created |
| 6 | DB check: `SELECT * FROM slb_cognitive_skill WHERE code='FULLSKILL'` | All fields saved correctly |

---

#### TC-P08: Create Cognitive Skill With Code Auto-Uppercase

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "critiquing" (lowercase), name: "Critiquing" | Code is lowercase |
| 3 | Click "Save" | Record created |
| 4 | DB check: `SELECT code FROM slb_cognitive_skill WHERE name='Critiquing'` | code = "CRITIQUING" (uppercased) |

---

#### TC-P09: Edit Cognitive Skill Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="EDITTEST", name="Edit Test", bloom_id=X | Record exists with ID=Y |
| 2 | Click "Edit" button on that row | Navigates to `/syllabus/cognitive-skills/{Y}/edit` |
| 3 | Verify form pre-filled | code="EDITTEST", name="Edit Test" |
| 4 | Verify bloom parent dropdown shows correct parent X | Bloom taxonomy pre-selected |

---

#### TC-P10: Update Cognitive Skill All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="OLD", name="Old Name", bloom_id=X | Record exists with ID=Y |
| 2 | Navigate to edit page | Form pre-filled |
| 3 | Change code to "NEW", name to "New Name", change bloom parent | Fields updated |
| 4 | Change description to "Updated description" | Updated |
| 5 | Change is_active to OFF | Toggle OFF |
| 6 | Click "Save" | PUT request to `/syllabus/cognitive-skills/{Y}` |
| 7 | Check response | "Cognitive skill updated successfully." |
| 8 | DB check: `SELECT * FROM slb_cognitive_skill WHERE id={Y}` | All fields updated; `updated_at` changed |

---

#### TC-P11: Update Cognitive Skill — Change Bloom Parent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create skill with bloom_id=B1 | Skill linked to bloom B1 |
| 2 | Edit skill, select a different bloom taxonomy B2 | Parent changed |
| 3 | Click "Save" | Update succeeds |
| 4 | DB check: `SELECT bloom_id FROM slb_cognitive_skill WHERE id={id}` | bloom_id = B2 |

---

#### TC-P12: View Cognitive Skill Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="VIEWTEST", name="View Test" | Record exists |
| 2 | Click "View" button on that row | Navigates to `/syllabus/cognitive-skills/{id}` |
| 3 | Check page heading | "View Test" displayed |
| 4 | Check code displayed | "VIEWTEST" |
| 5 | Check bloom parent name displayed | Correct bloom taxonomy name shown |
| 6 | Check status badge | Green "Active" or red "Inactive" badge |
| 7 | Check description displayed | Description shown |

---

#### TC-P13: Soft Delete Cognitive Skill

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="DELTEST", name="Delete Test" | Record exists with ID=X |
| 2 | Click delete button on that row | SweetAlert "Are you sure?" |
| 3 | Click "Cancel" | Alert closes, record not deleted |
| 4 | Click delete again, then click "Yes, delete it!" | AJAX DELETE sent |
| 5 | Check toast | Green toast: "Cognitive skill deleted successfully" |
| 6 | DB check: `SELECT deleted_at FROM slb_cognitive_skill WHERE id={X}` | `deleted_at` NOT NULL |
| 7 | DB check: `SELECT is_active FROM slb_cognitive_skill WHERE id={X}` | `is_active` = 0 |
| 8 | Activity log: "Trashed" event logged | Event exists |

---

#### TC-P14: Trash Page Shows Deleted Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a cognitive skill | Record is trashed |
| 2 | Click "Trash" button | Navigates to `/syllabus/cognitive-skills/trash/view` |
| 3 | Check trash page loads | Heading: "Trashed Cognitive Skills" |
| 4 | Check table shows deleted record | Record row visible |
| 5 | Check "Restore" button | Button present |
| 6 | Check "Force Delete" button | Force delete button present |

---

#### TC-P15: Restore Cognitive Skill From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash page (record is soft-deleted) | Trash page shows the record |
| 2 | Click "Restore" on that row | SweetAlert confirmation |
| 3 | Click confirm | Restore succeeds |
| 4 | DB check: `SELECT deleted_at FROM slb_cognitive_skill WHERE id={X}` | `deleted_at` = NULL |
| 5 | DB check: `SELECT is_active FROM slb_cognitive_skill WHERE id={X}` | `is_active` = 1 |
| 6 | Navigate back to main list | Record visible again |
| 7 | Activity log: "Restored" event logged | Event exists |

---

#### TC-P16: Force Delete Cognitive Skill (No Dependencies)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record then soft-delete it | Record is in trash |
| 2 | Navigate to trash page | Trash page shows record |
| 3 | Click "Force Delete" on that row | SweetAlert confirmation |
| 4 | Click confirm | Force delete succeeds |
| 5 | Check toast | "Cognitive skill deleted permanently" |
| 6 | DB check: Record permanently gone | Record removed |
| 7 | Activity log: "Deleted" event logged | Event exists |

---

#### TC-P17: Toggle Status Active ↔ Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with is_active=ON | Record is active |
| 2 | Click the status toggle switch | AJAX POST to toggle-status |
| 3 | Check response | JSON `{success: true, is_active: false, message: "..."}` |
| 4 | DB check: `SELECT is_active` | is_active=0 |
| 5 | Click toggle again | is_active=1 (back) |
| 6 | Activity log: 2 entries with event="Toggled" | Both toggles logged |

---

#### TC-P18: Pagination Works (10 Per Page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 11+ cognitive skill records | Records exist |
| 2 | Navigate to cognitive skills list | Page 1 shows first 10 records |
| 3 | Check pagination links | Pagination bar visible |
| 4 | Click page 2 | Remaining records displayed |

---

#### TC-P19: Full Lifecycle: Create → Edit → Toggle → Delete → Trash → Restore → Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="LIFECYCLE", name="Lifecycle Skill" | Record created |
| 2 | Edit: change name to "Lifecycle Updated" | Update succeeds |
| 3 | Toggle status OFF then ON | Both toggles succeed |
| 4 | Soft delete | `deleted_at` set |
| 5 | View trash | Record visible |
| 6 | Restore | `deleted_at` = NULL |
| 7 | Soft delete again | Back to trash |
| 8 | Force delete | Record permanently removed |
| 9 | Activity logs for all events | All events logged |

---

#### TC-P20: Bloom Parent Name Displayed In List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create skill with bloom parent "Evaluating" | Skill linked |
| 2 | Navigate to cognitive skills list | "Evaluating" displayed in "Bloom Level" column |

---

### 6.2 Negative TC Steps

#### TC-N01: Required — Missing Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter name: "Test", leave code empty | Code missing |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Cognitive skill code is required." | Error returned |

---

#### TC-N02: Required — Missing Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "TEST", leave name empty | Name missing |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Cognitive skill name is required." | Error returned |

---

#### TC-N03: Invalid Code — Non-Alpha Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "CRITIQUE_1" (contains underscore and number) | Non-alpha |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Code must contain only letters." | Error returned |

---

#### TC-N04: Invalid Code — Exceeds 20 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code of 21 characters | Exceeds max |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Code must not exceed 20 characters." | Error returned |

---

#### TC-N05: Duplicate Code (Global Unique)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pre-requisite: Create skill with code="UNIQUE01" | Code taken |
| 2 | Open Add New, enter code="UNIQUE01" | Same code |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "This cognitive skill code already exists." | Error returned |

---

#### TC-N06: Max Length — Name > 100 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter name of 101 characters | Exceeds max |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Name must not exceed 100 characters." | Error returned |

---

#### TC-N07: Max Length — Description > 255 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter description of 256 characters | Exceeds max |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Description must not exceed 255 characters." | Error returned |

---

#### TC-N08: Invalid bloom_id — Non-Existent Bloom Taxonomy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Set bloom_id=99999 (non-existent) | Invalid FK |
| 3 | Fill all other fields | Valid data |
| 4 | Click "Save" | HTTP 500 or DB constraint error |

---

#### TC-N09: View Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open URL: `/syllabus/cognitive-skills/99999` (non-existent) | HTTP 404 |

---

#### TC-N10: Edit/Update Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open URL: `/syllabus/cognitive-skills/99999/edit` | HTTP 404 |
| 2 | Send PUT to `/syllabus/cognitive-skills/99999` | HTTP 404 |

---

#### TC-N11: Delete Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send DELETE to `/syllabus/cognitive-skills/99999` | Redirect with error |

---

#### TC-N12: Toggle Status With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `/syllabus/cognitive-skills/99999/toggle-status` | JSON 404: `{success: false, message: "..."}` |

---

#### TC-N13: Restore Non-Deleted Record (Already Active)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active record (deleted_at=NULL) | Active |
| 2 | Send GET to restore URL | `onlyTrashed()->find($id)` returns null → 404 |

---

#### TC-N14: Force Delete Non-Trashed Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active record (deleted_at=NULL) | Active |
| 2 | Send DELETE to force-delete URL | `onlyTrashed()->find($id)` returns null → 404 |

---

#### TC-N15: Permission 403 — No Cognitive Skill Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without any `tenant.cognitive-skill.*` permissions | Dashboard loads |
| 2 | Navigate to cognitive skills tab | 403 Forbidden |
| 3 | POST to store without create permission | 403 Forbidden |
| 4 | PUT to update without update permission | 403 Forbidden |
| 5 | DELETE without delete permission | 403 Forbidden |
| 6 | POST toggle-status without update permission | 403 Forbidden |
| 7 | GET trash/view without restore permission | 403 Forbidden |
| 8 | GET restore without restore permission | 403 Forbidden |
| 9 | DELETE force-delete without forceDelete permission | 403 Forbidden |

---

#### TC-N16: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout completely | — |
| 2 | Navigate to cognitive skills tab | Redirected to login |
| 3 | Try any cognitive skill route | Redirected to login |

---

#### TC-N17: XSS Injection In Name/Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with name=`<script>alert('xss')</script>`, code="XSS01" | Record created |
| 2 | DB check: stored as-is | Literal string |
| 3 | View on list page | Script does NOT execute |
| 4 | Clean up: force delete | Record removed |

---

#### TC-N18: Whitespace-Only Name/Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code="   " (spaces only), name="   " (spaces only) | Empty after trim |
| 2 | Click "Save" | Validation fails |

---



---

### 6.3 Dependency TC Steps

#### TC-D01: Force Delete Cognitive Skill — Question Type Specificity FK Set NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create cognitive skill C1 and a question type specificity linked to C1 | Specificity has cognitive_skill_id = C1.id |
| 2 | Soft delete C1 | C1 in trash |
| 3 | Force delete C1 | C1 permanently removed |
| 4 | DB check: `SELECT cognitive_skill_id FROM slb_ques_type_specificity WHERE id={specId}` | cognitive_skill_id = NULL |

---

#### TC-D02: Soft-Delete Record Hidden From Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active cognitive skill | Active |
| 2 | Soft delete the skill | Trashed |
| 3 | Navigate to question type specificity create form (parent dropdown) | Deleted skill NOT in dropdown |
| 4 | Restore the skill | Appears in dropdown again |

---

#### TC-D03: Toggle Status — Inactive Record Hidden From Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active cognitive skill | Active |
| 2 | Toggle status to inactive | is_active = 0 |
| 3 | Navigate to question type specificity create form | Inactive skill NOT in dropdown |
| 4 | Toggle back to active | Appears in dropdown again |

---

#### TC-D04: Create Skill With Bloom Taxonomy — Verify Parent Name Displayed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create bloom taxonomy "Evaluating" | Bloom record exists |
| 2 | Create cognitive skill linked to "Evaluating" | Skill created |
| 3 | View index page | "Evaluating" shown in Bloom Level column |
| 4 | View show page | "Evaluating" shown as parent |

---

#### TC-D05: Delete Bloom Taxonomy — Cognitive Skill bloom_id Set NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create bloom taxonomy B1 and cognitive skill C1 linked to B1 | C1.bloom_id = B1.id |
| 2 | Force delete B1 | B1 removed |
| 3 | DB check: `SELECT bloom_id FROM slb_cognitive_skill WHERE id=C1` | bloom_id = NULL (SET NULL) |

---

#### TC-D06: Missing bloom_id Exists Validation — validation gap in FormRequest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Set bloom_id=99999 (non-existent ID) | Field set |
| 3 | Enter code "TESTMISS", name "Test Missing" | Fields filled |
| 4 | Click "Save" | POST to store; validation rule `exists:slb_bloom_taxonomy,id` is NOT present (bug) |
| 5 | Check response | HTTP 500 NOT returned; request accepted despite invalid bloom_id |
| 6 | DB check: `SELECT bloom_id FROM slb_cognitive_skill WHERE code='TESTMISS'` | bloom_id = 99999 (invalid external ID accepted) |

---

#### TC-D07: Uppercase Code Conversion — strtoupper()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "analyze" (lowercase), name: "Analyze Skill" | Code is lowercase |
| 3 | Click "Save" | Record created |
| 4 | DB check: `SELECT code FROM slb_cognitive_skill WHERE name='Analyze Skill'` | code = "ANALYZE" (uppercased by prepareForValidation) |

---

#### TC-D08: Alpha Only Validation — `alpha` rule on code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "SKILL_1" (contains underscore and number) | Non-alpha characters |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Code must contain only letters." | Error returned |

---

#### TC-D09: Active Bloom Taxonomy Filter — scopeActive() on bloom_id dropdown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pre-requisite: Ensure at least one active and one inactive Bloom Taxonomy record exists | Both record types exist |
| 2 | Open Add New form | Form visible |
| 3 | Click bloom_id dropdown | Dropdown opens |
| 4 | Verify dropdown lists only is_active=1 Bloom Taxonomy records | Inactive bloom records NOT shown |

---

#### TC-D10: FK SET NULL — bloom_id on Bloom Deletion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create bloom taxonomy B1 and cognitive skill C1 linked to B1 | C1.bloom_id = B1.id |
| 2 | Force delete B1 | B1 removed |
| 3 | DB check: `SELECT bloom_id FROM slb_cognitive_skill WHERE id=C1` | bloom_id = NULL (FK SET NULL trigger) |

---

#### TC-D11: Nullable bloom_id — optional FK

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter code: "NULLBLOOM", name: "No Bloom Skill" | Fields set |
| 3 | Leave bloom_id dropdown unselected | bloom_id = NULL |
| 4 | Click "Save" | Record created |
| 5 | DB check: `SELECT bloom_id FROM slb_cognitive_skill WHERE code='NULLBLOOM'` | bloom_id = NULL |

---

#### TC-D12: Max Length Validation — name max:100, description max:255

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Enter name of 101 characters, code "MAXLEN01" | Name exceeds 100 limit |
| 3 | Click "Save" | HTTP 500 |
| 4 | Validation error: "Name must not exceed 100 characters." | Error returned |
| 5 | Enter name within 100 chars, description of 256 characters | Description exceeds 255 limit |
| 6 | Click "Save" | HTTP 500 |
| 7 | Validation error: "Description must not exceed 255 characters." | Error returned |
| 8 | Enter name (50 chars) and description (200 chars) within limits | Both fields valid |
| 9 | Click "Save" | Record created successfully |

---

#### TC-D13: Code Review — Model — fillable property protects mass assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `CognitiveSkill` model `$fillable` property | Array contains `bloom_id`, `code`, `name`, `description`, `is_active` only |
| 2 | POST to store with extra field: `extra_field=malicious` | Record created; `SELECT * FROM slb_cognitive_skill WHERE code=...` shows no `extra_field` column (silently ignored) |
| 3 | POST to update with extra field: `is_admin=1` | Update succeeds; only fillable columns changed |

---

#### TC-D14: Code Review — Model — $casts type correctness

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `CognitiveSkill` model `$casts` property | `bloom_id` => `integer`, `is_active` => `boolean` declared |
| 2 | Create record with bloom_id=5, is_active=1 | Record created |
| 3 | DB check: `SELECT bloom_id, is_active FROM slb_cognitive_skill WHERE id={id}` | bloom_id = 5 (int), is_active = 1 (tinyint) |
| 4 | Read model via `CognitiveSkill::find($id)` | `$skill->bloom_id` is int(5), `$skill->is_active` is bool(true) |

---

#### TC-D15: Code Review — Model — SoftDeletes trait works correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify `CognitiveSkill` model uses `SoftDeletes` trait | `use SoftDeletes;` present in model |
| 2 | Create & soft-delete record: code="SOFTTEST" | deleted_at set |
| 3 | `CognitiveSkill::where('code', 'SOFTTEST')->first()` | Returns null (excluded by default) |
| 4 | `CognitiveSkill::withTrashed()->where('code', 'SOFTTEST')->first()` | Returns record with deleted_at NOT NULL |
| 5 | Restore record | deleted_at = NULL |
| 6 | `CognitiveSkill::onlyTrashed()->where('code', 'SOFTTEST')->first()` | Returns null (not trashed anymore) |

---

#### TC-D16: Code Review — Model — belongsTo bloomTaxonomy relation loads parent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect model relationship method `bloomTaxonomy()` | Returns `$this->belongsTo(BloomTaxonomy::class, 'bloom_id')` |
| 2 | Create bloom taxonomy "Evaluating" with id=X | Bloom exists |
| 3 | Create cognitive skill with bloom_id=X | Skill linked |
| 4 | Access `$skill->bloom` | Returns `BloomTaxonomy` instance with name="Evaluating" |
| 5 | Create skill with bloom_id=NULL | No parent |
| 6 | Access `$skill->bloom` | Returns null (nullable FK) |
| 7 | Check index uses `->with('bloom')` eager load | N+1 query prevented |

---

#### TC-D17: Code Review — Model — scopeActive returns only is_active=1 records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create skill A (is_active=1) and skill B (is_active=0) | Both exist |
| 2 | `CognitiveSkill::active()->get()` | Returns only skill A |
| 3 | `CognitiveSkill::active()->count()` | Count = 1 (only active records) |
| 4 | Verify scope is used in controller list query | Index query applies `->active()` or equivalent filter |

---

#### TC-D18: Code Review — Model — scopeByCode filters by code column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create skills: code="ALPHA", code="BETA", code="ALPHA2" | 3 records |
| 2 | `CognitiveSkill::byCode('ALPHA')->get()` | Returns 1 record with code="ALPHA" |
| 3 | `CognitiveSkill::byCode('GAMMA')->get()` | Returns empty collection |
| 4 | Scope chains correctly: `CognitiveSkill::active()->byCode('ALPHA')->get()` | Returns only active record with code ALPHA |

---

#### TC-D19: Code Review — Model — scopeForBloom filters by bloom_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create bloom taxonomies B1 and B2 | Both exist |
| 2 | Create skill S1 (bloom_id=B1), skill S2 (bloom_id=B1), skill S3 (bloom_id=B2) | 3 skills |
| 3 | `CognitiveSkill::forBloom(B1)->get()` | Returns S1, S2 only |
| 4 | `CognitiveSkill::forBloom(B2)->get()` | Returns S3 only |
| 5 | `CognitiveSkill::forBloom(99999)->get()` | Returns empty collection |

---

#### TC-D20: Code Review — Controller — Gate authorization enforced on every method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `index()` — `Gate::authorize('tenant.cognitive-skill.viewAny')` | Gate check present |
| 2 | Inspect `show()` — `Gate::authorize('tenant.cognitive-skill.view')` | Gate check present |
| 3 | Inspect `create()`/`store()` — `Gate::authorize('tenant.cognitive-skill.create')` | Gate check present |
| 4 | Inspect `edit()`/`update()` — `Gate::authorize('tenant.cognitive-skill.update')` | Gate check present |
| 5 | Inspect `destroy()` — `Gate::authorize('tenant.cognitive-skill.delete')` | Gate check present |
| 6 | Inspect `trashed()`/`restore()` — `Gate::authorize('tenant.cognitive-skill.restore')` | Gate check present |
| 7 | Inspect `forceDelete()` — `Gate::authorize('tenant.cognitive-skill.forceDelete')` | Gate check present |
| 8 | Inspect `toggleStatus()` — `Gate::authorize('tenant.cognitive-skill.update')` | Gate check present |
| 9 | Functional: request as user without permission → each endpoint | 403 Forbidden returned |

---

#### TC-D21: Code Review — Controller — Activity logged on all state transitions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record | Activity log entry with event "Stored" |
| 2 | Update record | Activity log entry with event "Updated" |
| 3 | Soft delete record | Activity log entry with event "Trashed" |
| 4 | Restore record from trash | Activity log entry with event "Restored" |
| 5 | Force delete record | Activity log entry with event "Deleted" |
| 6 | Toggle status | Activity log entry with event "Toggled" |
| 7 | Verify all log entries have correct `subject_type`, `subject_id`, `causer_id` | Each entry correctly references the CognitiveSkill model and authenticated user |

---

#### TC-D22: Code Review — Controller — is_active set false before soft delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with is_active=1 | Active record |
| 2 | Inspect `destroy()` controller method | `$record->is_active = false; $record->save(); $record->delete()` sequence present |
| 3 | Click delete button → confirm | AJAX DELETE succeeds |
| 4 | DB check: `SELECT is_active, deleted_at FROM slb_cognitive_skill WHERE id={id}` | `is_active` = 0, `deleted_at` IS NOT NULL |
| 5 | Restore record | `is_active` = 1 (restore sets back to true) |

---

#### TC-D23: Code Review — Request — code unique rule ignores soft-deleted records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with code="UNIQUESD" | Active record |
| 2 | Soft delete the record | Record trashed |
| 3 | Open Add New form, enter code="UNIQUESD" | Same code as trashed record |
| 4 | Click "Save" | Create succeeds (unique rule ignores soft-deleted records via `->whereNull('deleted_at')` or model scope) |
| 5 | DB check: both records exist; active one has code="UNIQUESD", trashed one retains its code | No unique constraint violation |

---

#### TC-D24: Code Review — Request — prepareForValidation strtoupper applied before validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `CognitiveSkillRequest::prepareForValidation()` | `$this->merge(['code' => strtoupper($this->code)])` or similar present |
| 2 | Open Add New form, enter code="critique" (lowercase) | Lowercase input |
| 3 | Click "Save" | Validation runs against uppercased "CRITIQUE" |
| 4 | DB check: `SELECT code FROM slb_cognitive_skill` | Stored as "CRITIQUE" |
| 5 | Try creating another with code="CRITIQUE" (already uppercase) | Unique validation fails: "This cognitive skill code already exists." |

---

#### TC-D25: Code Review — Policy — All policy methods defined and return correct boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `CognitiveSkillPolicy` methods | Methods: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`, `status` |
| 2 | Check `viewAny($user)` | `$user->hasPermissionTo('tenant.cognitive-skill.viewAny')` |
| 3 | Check `view($user, $skill)` | `$user->hasPermissionTo('tenant.cognitive-skill.view')` |
| 4 | Check `create($user)` | `$user->hasPermissionTo('tenant.cognitive-skill.create')` |
| 5 | Check `update($user, $skill)` | `$user->hasPermissionTo('tenant.cognitive-skill.update')` |
| 6 | Check `delete($user, $skill)` | `$user->hasPermissionTo('tenant.cognitive-skill.delete')` |
| 7 | Check `restore($user, $skill)` | `$user->hasPermissionTo('tenant.cognitive-skill.restore')` |
| 8 | Check `forceDelete($user, $skill)` | `$user->hasPermissionTo('tenant.cognitive-skill.forceDelete')` |
| 9 | Check `status($user, $skill)` | `$user->hasPermissionTo('tenant.cognitive-skill.status')` |
| 10 | Verify `status()` is not mapped to `update` gate; uses separate permission | Independent permission check |

---

#### TC-D26: Code Review — Routes — All expected routes registered and named

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `php artisan route:list --path=syllabus/cognitive-skills` | All routes listed |
| 2 | Check `GET /syllabus/cognitive-skills` → `index` | Route registered |
| 3 | Check `GET /syllabus/cognitive-skills/create` → `create` | Route registered |
| 4 | Check `POST /syllabus/cognitive-skills` → `store` | Route registered |
| 5 | Check `GET /syllabus/cognitive-skills/{id}` → `show` | Route registered |
| 6 | Check `GET /syllabus/cognitive-skills/{id}/edit` → `edit` | Route registered |
| 7 | Check `PUT/PATCH /syllabus/cognitive-skills/{id}` → `update` | Route registered |
| 8 | Check `DELETE /syllabus/cognitive-skills/{id}` → `destroy` | Route registered |
| 9 | Check `GET /syllabus/cognitive-skills/trash/view` → `trashed` | Route registered |
| 10 | Check `GET /syllabus/cognitive-skills/{id}/restore` → `restore` | Route registered |
| 11 | Check `DELETE /syllabus/cognitive-skills/{id}/force-delete` → `forceDelete` | Route registered |
| 12 | Check `POST /syllabus/cognitive-skills/{id}/toggle-status` → `toggleStatus` | Route registered |

---

#### TC-D27: Code Review — Controller — Pagination and redirect consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `index()` — pagination call | `CognitiveSkill::...->paginate(10)` — exactly 10 per page |
| 2 | Create 11 active records, navigate to index | Page 1 shows 10 records; pagination links visible |
| 3 | Click page 2 | Remaining record(s) shown |
| 4 | Inspect `store()` redirect | `return redirect()->route('syllabus.bloom.index', ['tab' => 'cognitive_skills'])` |
| 5 | Inspect `update()` redirect | Same redirect as store |
| 6 | Inspect `destroy()` redirect | Same redirect |
| 7 | Inspect `restore()` redirect | Same redirect |
| 8 | Verify redirect consistency across all CRUD methods | All CRUD methods redirect to `syllabus.bloom.index` with `cognitive_skills` tab |

---

#### TC-D28: Show soft-deleted cognitive skill via withTrashed()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `show($id)` method in CognitiveSkillController | Calls `CognitiveSkill::withTrashed()->findOrFail($id)` to fetch record |
| 2 | Create a cognitive skill record with code="SHOWSD01", name="Show SoftDeleted Skill" | Record exists and is active |
| 3 | Soft delete the record via destroy() | `deleted_at` set; `is_active=0` |
| 4 | Navigate to show URL `/syllabus/cognitive-skills/{id}` for the deleted record | Page loads successfully (not 404) |
| 5 | Verify record details displayed | Code, name, bloom parent, description, status all shown |
| 6 | Verify the page indicates the record is trashed or shows deleted_at info | User can see soft-deleted status |
| 7 | Compare with active record: navigate to show for active record | Active record show page loads without withTrashed() context |
