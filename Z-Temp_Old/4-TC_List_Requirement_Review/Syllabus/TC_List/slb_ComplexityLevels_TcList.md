# slb_complexity_level_TcList

## Module: Syllabus → Syllabus Master → Complexity Levels

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Syllabus Master |
| Feature | Complexity Levels |
| URL(s) | `/syllabus/bloom` (index via tab), `/syllabus/complexity-levels/create` (create), `/syllabus/complexity-levels` (store), `/syllabus/complexity-levels/{id}` (show), `/syllabus/complexity-levels/{id}/edit` (edit), `/syllabus/complexity-levels/{id}` (update), `/syllabus/complexity-levels/trash/view` (trash), `/syllabus/complexity-levels/{id}/restore` (restore), `/syllabus/complexity-levels/{id}/force-delete` (forceDelete), `/syllabus/complexity-levels/{id}/toggle-status` (toggleStatus) |
| Controller | `Modules\Syllabus\Http\Controllers\ComplexityLevelController` |
| Model(s) | `Modules\Syllabus\Models\ComplexityLevel` |
| Validation (Create) | `Modules\Syllabus\Http\Requests\ComplexityLevelRequest` |
| Validation (Update) | `Modules\Syllabus\Http\Requests\ComplexityLevelRequest` (ignores current ID for unique) |
| Permissions | `tenant.complexity-level.viewAny`, `tenant.complexity-level.view`, `tenant.complexity-level.create`, `tenant.complexity-level.update`, `tenant.complexity-level.delete`, `tenant.complexity-level.restore`, `tenant.complexity-level.forceDelete`, `tenant.complexity-level.status` |
| Soft Deletes | Yes (`ComplexityLevel` uses `SoftDeletes` trait) |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |
| Import | Not supported |

---

## 2. Pre-conditions

- Required permissions: `tenant.complexity-level.viewAny`, `tenant.complexity-level.view`, `tenant.complexity-level.create`, `tenant.complexity-level.update`, `tenant.complexity-level.delete`, `tenant.complexity-level.restore`, `tenant.complexity-level.forceDelete`, `tenant.complexity-level.status`
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
- **Complexity level code**: Uppercase alphanumeric, max 20 chars, globally unique
- **Complexity level value**: Nullable integer between 1 and 3 (1=Easy, 2=Medium, 3=Difficult)
- **Pre-test cleanup**: Delete created records by code before/after tests to avoid collisions
- **JSON fields**: None

---

## 5. Business Conditions

### 4.1 Database Schema — `slb_complexity_level`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | code | VARCHAR(20) | NOT NULL, UNIQUE |
| BC-DB-03 | name | VARCHAR(50) | NOT NULL |
| BC-DB-04 | complexity_level | TINYINT | DEFAULT NULL (1=Easy, 2=Medium, 3=Difficult) |
| BC-DB-05 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 (cast to boolean) |
| BC-DB-06 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-07 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-08 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules — `ComplexityLevelRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | code | required, string, max:20, unique:slb_complexity_level,code | "Complexity level code is required." |
| BC-VAL-02 | code | unique | "This complexity level code already exists." |
| BC-VAL-03 | name | required, string, max:50 | "Complexity level name is required." |
| BC-VAL-04 | name | max:50 | "Name must not exceed 50 characters." |
| BC-VAL-05 | complexity_level | nullable, integer, between:1,3 | "Complexity level must be Easy, Medium, or Difficult." |
| BC-VAL-06 | is_active | nullable, boolean | — |

### 4.3 Validation Rules — `ComplexityLevelRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | code | required, string, max:20, unique:slb_complexity_level,code + ignore($id) | "Complexity level code is required." |
| BC-VAL-U02 | code | unique + ignore | "This complexity level code already exists." |
| BC-VAL-U03 | name | required, string, max:50 | "Complexity level name is required." |
| BC-VAL-U04 | name | max:50 | "Name must not exceed 50 characters." |
| BC-VAL-U05 | complexity_level | nullable, integer, between:1,3 | "Complexity level must be Easy, Medium, or Difficult." |
| BC-VAL-U06 | is_active | nullable, boolean | — |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.complexity-level.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.complexity-level.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.complexity-level.create | store(), create() | Without → 403 |
| BC-AUTH-04 | tenant.complexity-level.update | update(), edit(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.complexity-level.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.complexity-level.restore | restore(), trashed() | Without → 403 |
| BC-AUTH-07 | tenant.complexity-level.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.complexity-level.status | toggleStatus() (via update gate) | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-02 | Default is_active on create | Defaults to true |
| BC-BIZ-03 | Code auto-uppercase | `strtoupper(trim($code))` applied in `prepareForValidation()` |
| BC-BIZ-04 | Delete sets is_active false | `destroy()` sets `is_active = false` before `delete()` |
| BC-BIZ-05 | Restore sets is_active true | `restore()` sets `is_active = true` |
| BC-BIZ-06 | Status toggle | `is_active` flips; returns JSON `{success, is_active, message}` |
| BC-BIZ-07 | Show uses withTrashed | `show()` calls `withTrashed()->findOrFail($id)` |
| BC-BIZ-08 | Pagination | Index paginated at 10 per page |
| BC-BIZ-09 | Activity log — Stored | On create |
| BC-BIZ-10 | Activity log — Updated | On update |
| BC-BIZ-11 | Activity log — Trashed | On soft delete |
| BC-BIZ-12 | Activity log — Restored | On restore |
| BC-BIZ-13 | Activity log — Deleted | On force delete |
| BC-BIZ-14 | Activity log — Toggled | On status toggle |
| BC-BIZ-15 | Redirect after CRUD | Redirect to `syllabus.bloom.index` with tab `complexity_levels` |
| BC-BIZ-16 | Complexity level nullable | Can create record without setting a numeric complexity level |
| BC-BIZ-17 | Screen loads via SyllabusController@bloom() at GET /syllabus/bloom with bloom tab group | Navigating to GET /syllabus/bloom with appropriate permissions loads the Bloom tab group; this screen's grid data is fetched and displayed |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| — | None | — | No FK references to this table |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Complexity Levels List Page Loads With All UI Elements | Page loads with Add New, Trash, search, table columns: Code, Name, Level, Status, Actions | — | — | ⬜ |
| TC-P02 | Search By Name Or Code | Table filters correctly | — | — | ⬜ |
| TC-P03 | Filter By Active/Inactive Status | Filter works correctly | — | — | ⬜ |
| TC-P04 | Create Complexity Level With All Required Fields | Record created with code, name | — | — | ⬜ |
| TC-P05 | Create Complexity Level With Complexity Level 1 (Easy) | complexity_level = 1 saved | — | — | ⬜ |
| TC-P06 | Create Complexity Level With Complexity Level 2 (Medium) | complexity_level = 2 saved | — | — | ⬜ |
| TC-P07 | Create Complexity Level With Complexity Level 3 (Difficult) | complexity_level = 3 saved | — | — | ⬜ |
| TC-P08 | Create Complexity Level Without Complexity Level (NULL) | complexity_level = NULL allowed | — | — | ⬜ |
| TC-P09 | Create With Code Auto-Uppercase | Code `easy` stored as `EASY` | — | — | ⬜ |
| TC-P10 | Edit Complexity Level Loads Pre-Filled Data | Edit form shows existing data | — | — | ⬜ |
| TC-P11 | Update Complexity Level All Fields | Code, name, complexity_level, is_active all updated | — | — | ⬜ |
| TC-P12 | View Complexity Level Details Page | Details shown with code, name, level, status | — | — | ⬜ |
| TC-P13 | Soft Delete Complexity Level | `deleted_at` set | — | — | ⬜ |
| TC-P14 | Trash Page Shows Deleted Records | Trash page lists only soft-deleted records | — | — | ⬜ |
| TC-P15 | Restore Complexity Level From Trash | `deleted_at` = NULL; activity log "Restored" | — | — | ⬜ |
| TC-P16 | Force Delete Complexity Level (No Dependencies) | Record permanently removed | — | — | ⬜ |
| TC-P17 | Toggle Status Active ↔ Inactive | `is_active` flips; AJAX 200 | — | — | ⬜ |
| TC-P18 | Pagination Works (10 Per Page) | Pagination links with 11+ records | — | — | ⬜ |
| TC-P19 | Full Lifecycle: Create → Edit → Toggle → Delete → Trash → Restore → Force Delete | All transitions successful | — | — | ⬜ |
| TC-P20 | Empty State — No Records Yet | "No records found" message; Add New visible | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing Code | "Complexity level code is required." | — | — | ⬜ |
| TC-N02 | Required — Missing Name | "Complexity level name is required." | — | — | ⬜ |
| TC-N03 | Invalid Code — Exceeds 20 Characters | code.max validation fails | — | — | ⬜ |
| TC-N04 | Duplicate Code (Global Unique) | "This complexity level code already exists." | — | — | ⬜ |
| TC-N05 | Max Length — Name > 50 Characters | name.max (51 chars) validation fails | — | — | ⬜ |
| TC-N06 | Invalid Complexity Level — Below 1 (Zero) | between validation fails | — | — | ⬜ |
| TC-N07 | Invalid Complexity Level — Above 3 (e.g. 4) | "Complexity level must be Easy, Medium, or Difficult." | — | — | ⬜ |
| TC-N08 | Invalid Complexity Level — Non-Integer (String) | integer validation fails | — | — | ⬜ |
| TC-N09 | View Record With Invalid ID (404) | HTTP 404 | — | — | ⬜ |
| TC-N10 | Edit/Update Record With Invalid ID (404) | HTTP 404 | — | — | ⬜ |
| TC-N11 | Delete Record With Invalid ID (404) | Redirect with error | — | — | ⬜ |
| TC-N12 | Toggle Status With Invalid ID (404) | JSON 404 | — | — | ⬜ |
| TC-N13 | Restore Non-Deleted Record (Already Active) | 404 error | — | — | ⬜ |
| TC-N14 | Force Delete Non-Trashed Record | 404 error | — | — | ⬜ |
| TC-N15 | Permission 403 — No Complexity Level Permissions | 403 on all CRUD | — | — | ⬜ |
| TC-N16 | Guest Access Redirect | Redirected to /login | — | — | ⬜ |
| TC-N17 | XSS Injection In Name/Code | Stored as literal; Blade escapes | — | — | ⬜ |
| TC-N18 | Whitespace-Only Name/Code | Required validation catches | — | — | ⬜ |
| TC-N20 | Code Duplicate On Update (Different Record) | Unique + ignore self correctly | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Toggle Status — Inactive Record Hidden From Dropdowns | Inactive complexity level excluded from question tagging dropdowns | — | — | ⬜ |
| TC-D02 | B | Complexity level create — Uppercase Code Conversion — strtoupper() | Lowercase code "easy" stored as "EASY" | — | — | ⬜ |
| TC-D03 | C | Complexity level create — complexity_level Range — between:1,3 | Values 1,2,3 accepted; 0,4, negatives rejected | — | — | ⬜ |
| TC-D04 | D | Complexity level create — Nullable complexity_level — optional field | Creating without complexity_level succeeds; stores NULL | — | — | ⬜ |
| TC-D05 | E | Complexity level create — Name Max Length — max:50 validation | Input exceeding 50 chars rejected; within 50 accepted | — | — | ⬜ |
| TC-D06 | F | Complexity level list — AJAX Toggle — toggleStatus route | Toggle flips is_active via AJAX; returns JSON with success and new is_active | — | — | ⬜ |
| TC-D07 | G | DB unique constraint — uq_complex_code — duplicate code insert | Inserting duplicate code at DB level throws integrity constraint violation | — | — | ⬜ |
| TC-D08 | H | Model uses SoftDeletes trait | `ComplexityLevel` model imports `SoftDeletes`; `deleted_at` column managed automatically | — | — | ⬜ |
| TC-D09 | I | Model $casts — is_active boolean, complexity_level integer | `$casts` array in model casts `is_active` as `boolean` and `complexity_level` as `integer` | — | — | ⬜ |
| TC-D10 | J | Model $fillable matches schema columns | `$fillable` contains `code`, `name`, `complexity_level`, `is_active`; no extra/missing fields | — | — | ⬜ |
| TC-D11 | K | Model scopeActive returns only active records | `scopeActive()` query scope filters `is_active = true` | — | — | ⬜ |
| TC-D12 | L | Controller destroy() sets is_active=false before soft delete | `destroy()` sets `is_active = false`, calls `delete()`, logs activity "Trashed" | — | — | ⬜ |
| TC-D13 | M | Controller restore() sets is_active=true | `restore()` sets `is_active = true`, calls `restore()`, logs activity "Restored" | — | — | ⬜ |
| TC-D14 | N | Controller show() uses withTrashed() | `show()` calls `withTrashed()->findOrFail($id)` so soft-deleted records are viewable | — | — | ⬜ |
| TC-D15 | O | Controller paginates index at 10 per page | `index()` returns paginated result with `->paginate(10)` | — | — | ⬜ |
| TC-D16 | P | Redirect after CRUD uses correct route + tab parameter | After store/update/destroy/restore, redirects to `syllabus.bloom.index` with `?tab=complexity_levels` | — | — | ⬜ |
| TC-D17 | Q | Request prepareForValidation uppercases code | `prepareForValidation()` applies `strtoupper(trim($this->code))` before validation runs | — | — | ⬜ |
| TC-D18 | R | Update request ignores current ID for unique code rule | `unique:slb_complexity_level,code,$this->route('complexity_level')` on update | — | — | ⬜ |
| TC-D19 | S | Policy has all required methods | `ComplexityLevelPolicy` defines `viewAny/view/create/update/delete/restore/forceDelete/status` | — | — | ⬜ |
| TC-D20 | T | Routes follow resourceful convention with extra actions | `Route::resource('complexity-level')` plus explicit routes for trashed/restore/forceDelete/toggleStatus | — | — | ⬜ |
| TC-D21 | U | Gate::authorize called before each controller action | Each controller method calls `Gate::authorize('tenant.complexity-level.*')` with correct permission string | — | — | ⬜ |
| TC-D22 | V | Activity log event naming consistency | Events use consistent past-tense naming: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` | — | — | ⬜ |
| TC-D23 | W | Cross-Module \| P1 \| Question Bank — Complexity Level Referenced by Questions | ComplexityLevel may be referenced by Question Bank entries; deleting a level that is tagged to existing questions should be restricted (toggle to inactive instead of delete) | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.complexity-level.create'), @can('tenant.complexity-level.edit'), @can('tenant.complexity-level.delete'), @can('tenant.complexity-level.status'), @can('tenant.complexity-level.view'), @canany(['tenant.complexity-level.restore', 'tenant.complexity-level.forceDelete']) for access control on all CRUD buttons and actions | — | — | ◌ |
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
| 1 | Inspect index.blade.php for add/create button | @can('tenant.complexity-level.create') wraps the Add New button; user without create permission does not see it
| 2 | Inspect row-level action buttons (view, edit, delete, status toggle) | @can('tenant.complexity-level.view'), @can('tenant.complexity-level.edit'), @can('tenant.complexity-level.delete'), @can('tenant.complexity-level.status') used appropriately; expired permissions hide corresponding buttons
| 3 | Inspect trash.blade.php for restore/forceDelete buttons | @canany(['tenant.complexity-level.restore', 'tenant.complexity-level.forceDelete']) wraps action buttons in trash view
| 4 | Inspect view.blade.php for edit button | @can('tenant.complexity-level.edit') wraps the Edit button on show/details page
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

#### TC-P01: Complexity Levels List Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Expand "Syllabus" → "Syllabus Master" → "Complexity Levels" tab | Page loads |
| 3 | Check search input | Present |
| 4 | Check status filter | "All", "Active", "Inactive" |
| 5 | Check "Add New" button | Visible |
| 6 | Check "Trash" button | Visible |
| 7 | Check table columns | Code, Name, Level, Status, Actions |

---

#### TC-P02: Search By Name Or Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create "Easy" (code="EASY"), "Medium" (code="MEDIUM") | 2 records |
| 2 | Type "Easy" in search | Only "Easy" visible |
| 3 | Type "MEDIUM" in search | Only "Medium" visible |

---

#### TC-P03: Filter By Active/Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active and inactive records | Both exist |
| 2 | Select "Active" | Only active visible |
| 3 | Select "Inactive" | Only inactive visible |

---

#### TC-P04: Create Complexity Level With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add New" | Form opens |
| 2 | Enter code: "EASY" | Code filled |
| 3 | Enter name: "Easy" | Name filled |
| 4 | Click "Save" | POST to store |
| 5 | Check response | Success message |
| 6 | DB check: record exists | Created with is_active=1 |

---

#### TC-P05: Create Complexity Level With Complexity Level 1 (Easy)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New | Form visible |
| 2 | Enter code: "EASY01", name: "Easy Level", complexity_level: 1 | Level 1 |
| 3 | Click "Save" | Record created |
| 4 | DB check: complexity_level = 1 | Saved correctly |

---

#### TC-P06: Create Complexity Level With Complexity Level 2 (Medium)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code: "MEDIUM01", name: "Medium Level", complexity_level: 2 | Level 2 |
| 2 | Click "Save" | Record created |
| 3 | DB check: complexity_level = 2 | Saved correctly |

---

#### TC-P07: Create Complexity Level With Complexity Level 3 (Difficult)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code: "HARD01", name: "Hard Level", complexity_level: 3 | Level 3 |
| 2 | Click "Save" | Record created |
| 3 | DB check: complexity_level = 3 | Saved correctly |

---

#### TC-P08: Create Complexity Level Without Complexity Level (NULL)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code: "NULLTEST", name: "Null Level Test", leave complexity_level empty | NULL |
| 2 | Click "Save" | Record created |
| 3 | DB check: complexity_level = NULL | Saved as null |

---

#### TC-P09: Create With Code Auto-Uppercase

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code: "easy" (lowercase) | Lowercase |
| 2 | Click "Save" | Record created |
| 3 | DB check: code = "EASY" | Uppercased |

---

#### TC-P10: Edit Complexity Level Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record "EDITTEST" | Exists |
| 2 | Click "Edit" | Form pre-filled |

---

#### TC-P11: Update Complexity Level All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record, then edit | Form loaded |
| 2 | Change code, name, complexity_level, is_active | All updated |
| 3 | Click "Save" | Update succeeds |

---

#### TC-P12: View Complexity Level Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record "VIEWTEST" | Exists |
| 2 | Click "View" | Details shown |

---

#### TC-P13: Soft Delete Complexity Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record, click delete, confirm | Soft deleted |
| 2 | DB check: deleted_at NOT NULL | Trashed |

---

#### TC-P14: Trash Page Shows Deleted Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete a record | In trash |
| 2 | Click "Trash" | Trash page shows it |

---

#### TC-P15: Restore Complexity Level From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate trash, click "Restore", confirm | Restored |
| 2 | DB check: deleted_at = NULL | Back |
| 3 | Activity log "Restored" | Logged |

---

#### TC-P16: Force Delete Complexity Level (No Dependencies)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete, then force delete | Record removed |
| 2 | Activity log "Deleted" | Logged |

---

#### TC-P17: Toggle Status Active ↔ Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active record | Active |
| 2 | Toggle switch | is_active flips |
| 3 | Toggle again | Flips back |

---

#### TC-P18: Pagination Works (10 Per Page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 11+ records | Exist |
| 2 | Check pagination | Page 1: 10 records |

---

#### TC-P19: Full Lifecycle: Create → Edit → Toggle → Delete → Trash → Restore → Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create → Edit → Toggle OFF/ON → Soft Delete → Trash → Restore → Soft Delete → Force Delete | All successful, activity logged |

---

#### TC-P20: Empty State — No Records Yet

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate with no records | "No records found" |

---

### 6.2 Negative TC Steps

#### TC-N01: Required — Missing Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, leave code empty, fill name | Code missing |
| 2 | Click "Save" | HTTP 500: "Complexity level code is required." |

---

#### TC-N02: Required — Missing Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, fill code, leave name empty | Name missing |
| 2 | Click "Save" | HTTP 500: "Complexity level name is required." |

---

#### TC-N03: Invalid Code — Exceeds 20 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code of 21 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500: "Code must not exceed 20 characters." |

---

#### TC-N04: Duplicate Code (Global Unique)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with code="DUPTEST" | Exists |
| 2 | Create another with same code | HTTP 500: "This complexity level code already exists." |

---

#### TC-N05: Max Length — Name > 50 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter name of 51 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500 |

---

#### TC-N06: Invalid Complexity Level — Below 1 (Zero)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter complexity_level: 0 | Below min |
| 2 | Click "Save" | HTTP 500: "Complexity level must be Easy, Medium, or Difficult." |

---

#### TC-N07: Invalid Complexity Level — Above 3 (e.g. 4)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter complexity_level: 4 | Above max |
| 2 | Click "Save" | HTTP 500 |

---

#### TC-N08: Invalid Complexity Level — Non-Integer (String)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter complexity_level: "abc" | Not integer |
| 2 | Click "Save" | HTTP 500 |

---

#### TC-N09: View Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `/syllabus/complexity-levels/99999` | HTTP 404 |

---

#### TC-N10: Edit/Update Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit with invalid ID | HTTP 404 |
| 2 | PUT to invalid ID | HTTP 404 |

---

#### TC-N11: Delete Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE to invalid ID | Redirect with error |

---

#### TC-N12: Toggle Status With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST toggle-status invalid ID | JSON 404 |

---

#### TC-N13: Restore Non-Deleted Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active record, try restore | 404 |

---

#### TC-N14: Force Delete Non-Trashed Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active record, try force delete | 404 |

---

#### TC-N15: Permission 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without permissions | 403 on all CRUD |

---

#### TC-N16: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate | Redirected to login |

---

#### TC-N17: XSS Injection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with XSS payload | Stored literal, not executed |

---

#### TC-N18: Whitespace-Only Name/Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter whitespace-only values | Validation fails |

---



---

#### TC-N20: Code Duplicate On Update (Different Record)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record A (code="TESTA"), record B (code="TESTB") | Both exist |
| 2 | Edit record B, change code to "TESTA" (already taken) | HTTP 500: duplicate |
| 3 | Change record B code to "TESTB_NEW" (available, ignoring self) | Update succeeds |

---

### 6.3 Dependency TC Steps

#### TC-D01: Toggle Status — Inactive Record Hidden From Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active complexity level | Active |
| 2 | Toggle status to inactive | is_active = 0 |
| 3 | Navigate to question creation or topic tagging | Inactive level NOT in dropdown |
| 4 | Toggle back to active | Appears in dropdown again |

---

#### TC-D02: Complexity Level Create — Uppercase Code Conversion — strtoupper()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New complexity level | Form loads |
| 2 | Enter code: "easy" (all lowercase) | Lowercase input |
| 3 | Enter name: "Easy" | Name filled |
| 4 | Click "Save" | POST to store |
| 5 | DB check: code column | Stored as "EASY" (uppercased) |

---

#### TC-D03: Complexity Level Create — complexity_level Range — between:1,3

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, enter code "RNG01", name "Range Test 1", complexity_level = 1 | Level 1 |
| 2 | Click "Save" | Accepted (HTTP 201/302) |
| 3 | Open Add New, enter code "RNG02", name "Range Test 2", complexity_level = 2 | Level 2 |
| 4 | Click "Save" | Accepted |
| 5 | Open Add New, enter code "RNG03", name "Range Test 3", complexity_level = 3 | Level 3 |
| 6 | Click "Save" | Accepted |
| 7 | Open Add New, enter code "RNG00", name "Range Test 0", complexity_level = 0 | Below min |
| 8 | Click "Save" | HTTP 500 rejected |
| 9 | Open Add New, enter code "RNG04", name "Range Test 4", complexity_level = 4 | Above max |
| 10 | Click "Save" | HTTP 500 rejected |
| 11 | Open Add New, enter code "RNGNG", name "Range Test Neg", complexity_level = -1 | Negative |
| 12 | Click "Save" | HTTP 500 rejected |

---

#### TC-D04: Complexity Level Create — Nullable complexity_level — optional field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, enter code "NULLOPT", name "Optional Level Test" | Leave complexity_level empty |
| 2 | Click "Save" | Record created successfully |
| 3 | DB check: complexity_level column | NULL |

---

#### TC-D05: Complexity Level Create — Name Max Length — max:50 validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, enter code "MAX50OK", name with exactly 50 characters | Within limit |
| 2 | Click "Save" | Accepted (HTTP 201/302) |
| 3 | Open Add New, enter code "MAX50NO", name with 51 characters | Exceeds 50 |
| 4 | Click "Save" | HTTP 500: "Name must not exceed 50 characters." |

---

#### TC-D06: Complexity Level List — AJAX Toggle — toggleStatus route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active complexity level (is_active = 1) | Record active |
| 2 | Navigate to complexity levels list | List shows record |
| 3 | Click toggle switch for the record | AJAX POST to toggle-status route |
| 4 | Check JSON response | `{success: true, is_active: false, message: "..."}` |
| 5 | Verify UI: status badge updates to Inactive | Visual confirmation |
| 6 | Click toggle switch again | AJAX POST again |
| 7 | Check JSON response | `{success: true, is_active: true, message: "..."}` |
| 8 | Verify UI: status badge updates to Active | Visual confirmation |

---

#### TC-D07: DB Unique Constraint — uq_complex_code — duplicate code insert

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create complexity level with code "UNIQTEST" | Record created |
| 2 | Attempt direct DB insert with same code "UNIQTEST" using raw SQL or DB facade | Integrity constraint violation (SQLSTATE[23000]) |
| 3 | Verify error message | "Duplicate entry 'UNIQTEST' for key 'slb_complexity_level.uq_complex_code'" |

---

#### TC-D08: Model Uses SoftDeletes Trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules\Syllabus\Models\ComplexityLevel.php` | File loads |
| 2 | Check `use SoftDeletes;` import statement | Present in class definition |
| 3 | Check `$dates` or `$casts` for `deleted_at` | Managed by SoftDeletes trait |
| 4 | Create a record then soft-delete it via controller | `deleted_at` populated with timestamp |

---

#### TC-D09: Model $casts — is_active boolean, complexity_level integer

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ComplexityLevel.php` model file | File loads |
| 2 | Locate `$casts` property array | Present |
| 3 | Verify `is_active => 'boolean'` entry | Cast defined |
| 4 | Verify `complexity_level => 'integer'` entry | Cast defined |
| 5 | Retrieve a record and assert `is_bool($record->is_active)` | Returns boolean true |
| 6 | Retrieve a record and assert `is_int($record->complexity_level)` | Returns integer when non-null |

---

#### TC-D10: Model $fillable Matches Schema Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ComplexityLevel.php` model | File loads |
| 2 | Locate `$fillable` array | Present |
| 3 | Verify `code`, `name`, `complexity_level`, `is_active` are all present | All four columns listed |
| 4 | Verify no extra columns not in schema | Only schema columns present |
| 5 | Create record with all fillable fields via `create()` | Mass assignment succeeds |

---

#### TC-D11: Model scopeActive Returns Only Active Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ComplexityLevel.php` model | File loads |
| 2 | Locate `scopeActive()` method or confirm via `active()` local scope | Present |
| 3 | Create one active record and one inactive record | Both exist |
| 4 | Call `ComplexityLevel::active()->get()` | Only the active record returned |
| 5 | Verify inactive record is excluded | Absent from collection |

---

#### TC-D12: Controller destroy() Sets is_active=false Before Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ComplexityLevelController.php` | File loads |
| 2 | Locate `destroy()` method | Present |
| 3 | Verify `$complexityLevel->is_active = false;` is called before `$complexityLevel->delete()` | `is_active` set to false |
| 4 | Verify `activityLog('Trashed')` is logged | Activity record created |
| 5 | Create a record, delete it via UI, then check DB | `is_active` = 0, `deleted_at` NOT NULL |

---

#### TC-D13: Controller restore() Sets is_active=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ComplexityLevelController.php` | File loads |
| 2 | Locate `restore()` method | Present |
| 3 | Verify `$complexityLevel->is_active = true;` is called before `$complexityLevel->restore()` | `is_active` set to true |
| 4 | Verify `activityLog('Restored')` is logged | Activity record created |
| 5 | Soft-delete a record then restore via UI | `is_active` = 1, `deleted_at` = NULL |

---

#### TC-D14: Controller show() Uses withTrashed()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ComplexityLevelController.php` | File loads |
| 2 | Locate `show()` method | Present |
| 3 | Verify query uses `withTrashed()->findOrFail($id)` | Soft-deleted records are findable |
| 4 | Soft-delete a record, then navigate to its show page | Details page renders successfully |

---

#### TC-D15: Controller Paginates Index at 10 Per Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ComplexityLevelController.php` | File loads |
| 2 | Locate `index()` method | Present |
| 3 | Verify `->paginate(10)` call | Pagination set to 10 |
| 4 | Create 15 records, visit index page | Page 1 shows 10 records, page 2 shows 5 |

---

#### TC-D16: Redirect After CRUD Uses Correct Route + Tab Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ComplexityLevelController.php` | File loads |
| 2 | Locate `store()`, `update()`, `destroy()`, `restore()` methods | All present |
| 3 | Verify each returns `redirect()->route('syllabus.bloom.index', ['tab' => 'complexity_levels'])` | Consistent redirect |
| 4 | Create a new record via form | Redirected to bloom index with `?tab=complexity_levels` |
| 5 | Update a record | Same redirect pattern |
| 6 | Delete a record | Same redirect pattern |

---

#### TC-D17: Request prepareForValidation Uppercases Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ComplexityLevelRequest.php` | File loads |
| 2 | Locate `prepareForValidation()` method | Present |
| 3 | Verify `$this->merge(['code' => strtoupper(trim($this->code))]);` | Code transformed before validation |
| 4 | Submit form with code "test123" | Stored as "TEST123" |

---

#### TC-D18: Update Request Ignores Current ID for Unique Code Rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ComplexityLevelRequest.php` | File loads |
| 2 | Locate rules for `code` field on update | Present |
| 3 | Verify `Rule::unique('slb_complexity_level', 'code')->ignore($this->route('complexity_level'))` | Current ID excluded from unique check |
| 4 | Create record with code "SELFOK" | Record created |
| 5 | Edit the same record without changing code | Update succeeds (unique ignores self) |
| 6 | Change code to another existing record's code | Duplicate error thrown |

---

#### TC-D19: Policy Has All Required Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ComplexityLevelPolicy.php` | File loads |
| 2 | Verify `viewAny()` method | Present, returns Gate::any |
| 3 | Verify `view()` method | Present |
| 4 | Verify `create()` method | Present |
| 5 | Verify `update()` method | Present |
| 6 | Verify `delete()` method | Present |
| 7 | Verify `restore()` method | Present |
| 8 | Verify `forceDelete()` method | Present |
| 9 | Verify `status()` method | Present |

---

#### TC-D20: Routes Follow Resourceful Convention With Extra Actions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/` files for syllabus module | Route definitions loaded |
| 2 | Locate complexity-level routes | Present |
| 3 | Verify `Route::resource('complexity-level', ComplexityLevelController::class)` | Resourceful routes registered |
| 4 | Verify explicit route for `trash/view` | GET `/complexity-levels/trash/view` → `trashed()` |
| 5 | Verify explicit route for `{complexity_level}/restore` | PUT/PATCH `/complexity-levels/{id}/restore` → `restore()` |
| 6 | Verify explicit route for `{complexity_level}/force-delete` | DELETE `/complexity-levels/{id}/force-delete` → `forceDelete()` |
| 7 | Verify explicit route for `{complexity_level}/toggle-status` | POST `/complexity-levels/{id}/toggle-status` → `toggleStatus()` |

---

#### TC-D21: Gate::authorize Called Before Each Controller Action

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ComplexityLevelController.php` | File loads |
| 2 | Check `index()` — `Gate::authorize('tenant.complexity-level.viewAny')` | Present at method start |
| 3 | Check `show()` — `Gate::authorize('tenant.complexity-level.view')` | Present |
| 4 | Check `create()` / `store()` — `Gate::authorize('tenant.complexity-level.create')` | Present |
| 5 | Check `edit()` / `update()` / `toggleStatus()` — `Gate::authorize('tenant.complexity-level.update')` | Present |
| 6 | Check `destroy()` — `Gate::authorize('tenant.complexity-level.delete')` | Present |
| 7 | Check `trashed()` / `restore()` — `Gate::authorize('tenant.complexity-level.restore')` | Present |
| 8 | Check `forceDelete()` — `Gate::authorize('tenant.complexity-level.forceDelete')` | Present |

---

#### TC-D22: Activity Log Event Naming Consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ComplexityLevelController.php` | File loads |
| 2 | Find all `activityLog(...)` / `logActivity(...)` calls | All six events present |
| 3 | Verify `activityLog('Stored')` on create | Past tense, matches convention |
| 4 | Verify `activityLog('Updated')` on update | Past tense |
| 5 | Verify `activityLog('Trashed')` on soft delete | Past tense |
| 6 | Verify `activityLog('Restored')` on restore | Past tense |
| 7 | Verify `activityLog('Deleted')` on force delete | Past tense |
| 8 | Verify `activityLog('Toggled')` on toggle status | Past tense |

#### TC-D23: Question Bank — Complexity Level Referenced by Questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a complexity level (e.g., "Hard") | Level created |
| 2 | Create a Question Bank question tagged with this complexity level | Question references complexity_level_id |
| 3 | Try to forceDelete the complexity level | Deletion blocked — toggle to inactive instead, or FK constraint prevents |
| 4 | Toggle the complexity level to inactive | is_active=0; level hidden from new question creation |
| 5 | Verify existing questions still reference the level | Historical data preserved |
