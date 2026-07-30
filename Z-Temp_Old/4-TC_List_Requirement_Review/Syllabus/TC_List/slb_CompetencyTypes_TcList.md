# slb_competency_types_TcList

## Module: Syllabus → Syllabus Master → Competency Types

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Syllabus Master |
| Feature | Competency Types |
| URL(s) | `/syllabus/master` (index via tab), `/syllabus/competency-types/create` (create), `/syllabus/competency-types` (store), `/syllabus/competency-types/{id}` (show), `/syllabus/competency-types/{id}/edit` (edit), `/syllabus/competency-types/{id}` (update), `/syllabus/competency-types/trash/view` (trash), `/syllabus/competency-types/{id}/restore` (restore), `/syllabus/competency-types/{id}/force-delete` (forceDelete), `/syllabus/competency-types/{id}/toggle-status` (toggleStatus) |
| Controller | `Modules\Syllabus\Http\Controllers\CompetencyTypeController` |
| Model(s) | `Modules\Syllabus\Models\CompetencyType` |
| Validation (Create) | `Modules\Syllabus\Http\Requests\CompetencyTypeRequest` |
| Validation (Update) | `Modules\Syllabus\Http\Requests\CompetencyTypeRequest` (ignores current ID for unique) |
| Permissions | `tenant.competency-type.viewAny`, `tenant.competency-type.view`, `tenant.competency-type.create`, `tenant.competency-type.update`, `tenant.competency-type.delete`, `tenant.competency-type.restore`, `tenant.competency-type.forceDelete`, `tenant.competency-type.status` |
| Soft Deletes | Yes (`CompetencyType` uses `SoftDeletes` trait) |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |
| Import | Not supported |

---

## 2. Pre-conditions

- Required permissions: `tenant.competency-type.viewAny`, `tenant.competency-type.view`, `tenant.competency-type.create`, `tenant.competency-type.update`, `tenant.competency-type.delete`, `tenant.competency-type.restore`, `tenant.competency-type.forceDelete`, `tenant.competency-type.status`
- Required seed data: None (standalone master table)
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

---

## 3. Default Data Load

When the page loads via SyllabusController@master() (GET /syllabus/master), the following data is fetched and passed to the view:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: Classes | SyllabusController@master() | SchoolClass::where('is_active',1)->orderBy('ordinal') | is_active=1 | None |
| Shared: Sections | SyllabusController@master() | Section::where('is_active',1)->orderBy('name') | is_active=1 | None |
| Shared: Subjects | SyllabusController@master() | Subject::where('is_active',1)->orderBy('name') | is_active=1 | None |
| Shared: Academic Sessions | SyllabusController@master() | OrganizationAcademicSession::orderBy('name') | None | None |
| Shared: Books | SyllabusController@master() | BokBook::where('is_active',1)->orderBy('title') | is_active=1 | None |
| Shared: All Lessons | SyllabusController@master() | Lesson::with(class,subject)->orderBy('name') | None | None |
| Shared: Topic Level Types | SyllabusController@master() | TopicLevelType::where('is_active',1)->orderBy('level') | is_active=1 | None |
| Shared: Competency Types | SyllabusController@master() | CompetencyType::where('is_active',1) | is_active=1 | None |
| Shared: All Competencies | SyllabusController@master() | Competencie::all() | None | None |
| Shared: All Topics | SyllabusController@master() | Topic::all() | None | None |
| Competency Types Grid | getCompetencyTypes() | CompetencyType | search(name,code), filter(search_status) | 10/page (competency_types_page) |
## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Competency type code**: Uppercase alphanumeric with dashes/underscores, max 20 chars, globally unique
- **Pre-test cleanup**: Delete created records by code before/after tests to avoid collisions
- **JSON fields**: None

---

## 5. Business Conditions

### 4.1 Database Schema — `slb_competency_types`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | code | VARCHAR(20) | NOT NULL, UNIQUE |
| BC-DB-03 | name | VARCHAR(100) | NOT NULL |
| BC-DB-04 | description | VARCHAR(255) | DEFAULT NULL |
| BC-DB-05 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 (cast to boolean) |
| BC-DB-06 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-07 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-08 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules — `CompetencyTypeRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | code | required, string, alpha_dash, max:20, unique:slb_competency_types,code | "Competency type code is required." |
| BC-VAL-02 | code | alpha_dash | "Code may only contain letters, numbers, dashes and underscores." |
| BC-VAL-03 | code | unique | "This competency type code already exists." |
| BC-VAL-04 | name | required, string, max:100 | "Competency type name is required." |
| BC-VAL-05 | name | max:100 | "Name must not exceed 100 characters." |
| BC-VAL-06 | description | nullable, string, max:255 | — |
| BC-VAL-07 | is_active | nullable, boolean (default TRUE) | — |

### 4.3 Validation Rules — `CompetencyTypeRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | code | required, string, alpha_dash, max:20, unique:slb_competency_types,code + ignore($id) | "Competency type code is required." |
| BC-VAL-U02 | code | alpha_dash | "Code may only contain letters, numbers, dashes and underscores." |
| BC-VAL-U03 | code | unique + ignore | "This competency type code already exists." |
| BC-VAL-U04 | name | required, string, max:100 | "Competency type name is required." |
| BC-VAL-U05 | name | max:100 | "Name must not exceed 100 characters." |
| BC-VAL-U06 | description | nullable, string, max:255 | — |
| BC-VAL-U07 | is_active | nullable, boolean (default FALSE on update if unchecked) | — |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.competency-type.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.competency-type.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.competency-type.create | store(), create() | Without → 403 |
| BC-AUTH-04 | tenant.competency-type.update | update(), edit(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.competency-type.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.competency-type.restore | restore(), trashed() | Without → 403 |
| BC-AUTH-07 | tenant.competency-type.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.competency-type.status | toggleStatus() (via update gate) | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-02 | Default is_active on create | Defaults to true |
| BC-BIZ-03 | Code auto-uppercase | `strtoupper(trim($code))` applied in `prepareForValidation()` |
| BC-BIZ-04 | Delete sets is_active false | `destroy()` sets `is_active = false` before calling `delete()` |
| BC-BIZ-05 | Restore sets is_active true | `restore()` sets `is_active = true` |
| BC-BIZ-06 | Status toggle | `is_active` flips; returns JSON `{success, is_active, message}` |
| BC-BIZ-07 | Force delete cascades to competencies | `slb_competencies.competency_type_id` ON DELETE CASCADE |
| BC-BIZ-08 | Show uses withTrashed | `show()` calls `withTrashed()->findOrFail($id)` |
| BC-BIZ-09 | Pagination | Index paginated at 10 per page |
| BC-BIZ-10 | Activity log — Stored | On create |
| BC-BIZ-11 | Activity log — Updated | On update |
| BC-BIZ-12 | Activity log — Trashed | On soft delete |
| BC-BIZ-13 | Activity log — Restored | On restore |
| BC-BIZ-14 | Activity log — Deleted | On force delete |
| BC-BIZ-15 | Activity log — Toggled | On status toggle |
| BC-BIZ-16 | Redirect after CRUD | Redirect to `syllabus.master.index` with tab `competency_types` |
| BC-BIZ-17 | Screen loads via SyllabusController@master() at GET /syllabus/master with master tab group | Navigating to GET /syllabus/master with appropriate permissions loads the Master tab group; this screen's grid data is fetched and displayed |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | competency_type_id (in slb_competencies) | slb_competency_types (id) | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Competency Types List Page Loads With All UI Elements | Page loads with Add New, Trash, search, table columns: Code, Name, Description, Status, Actions | — | — | ⬜ |
| TC-P02 | Search Competency Types By Name Or Code | Table filters to show only matching records | — | — | ⬜ |
| TC-P03 | Filter By Active/Inactive Status | Active/Inactive filter works correctly | — | — | ⬜ |
| TC-P04 | Create Competency Type With All Required Fields | Record created with code, name | — | — | ⬜ |
| TC-P05 | Create Competency Type With All Optional Fields | Description saved correctly | — | — | ⬜ |
| TC-P06 | Create With Code Using AlphaDash Characters | Code "KNOWLEDGE_DOMAIN" (with underscore) accepted | — | — | ⬜ |
| TC-P07 | Create With Code Auto-Uppercase | Code `knowledge` stored as `KNOWLEDGE` | — | — | ⬜ |
| TC-P08 | Edit Competency Type Loads Pre-Filled Data | Edit form shows existing data | — | — | ⬜ |
| TC-P09 | Update Competency Type All Fields | Code, name, description, is_active all updated | — | — | ⬜ |
| TC-P10 | View Competency Type Details Page | Details shown with code, name, description, status | — | — | ⬜ |
| TC-P11 | Soft Delete Competency Type | `deleted_at` set; record hidden from main list | — | — | ⬜ |
| TC-P12 | Trash Page Shows Deleted Records | Trash page lists only soft-deleted records | — | — | ⬜ |
| TC-P13 | Restore Competency Type From Trash | `deleted_at` = NULL; activity log "Restored" | — | — | ⬜ |
| TC-P14 | Force Delete Competency Type (No Dependencies) | Record permanently removed | — | — | ⬜ |
| TC-P15 | Toggle Status Active ↔ Inactive | `is_active` flips; AJAX 200 | — | — | ⬜ |
| TC-P16 | Pagination Works (10 Per Page) | Pagination links appear with 11+ records | — | — | ⬜ |
| TC-P17 | Full Lifecycle: Create → Edit → Toggle → Delete → Trash → Restore → Force Delete | All transitions successful | — | — | ⬜ |
| TC-P18 | Empty State — No Records Yet | "No records found" message; Add New button visible | — | — | ⬜ |
| TC-P19 | Default is_active = TRUE On Create | New record has is_active = 1 by default | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing Code | "Competency type code is required." | — | — | ⬜ |
| TC-N02 | Required — Missing Name | "Competency type name is required." | — | — | ⬜ |
| TC-N03 | Invalid Code — Space Character | "Code may only contain letters, numbers, dashes and underscores." | — | — | ⬜ |
| TC-N04 | Invalid Code — Special Characters (@, #, $) | alpha_dash validation fails | — | — | ⬜ |
| TC-N05 | Invalid Code — Exceeds 20 Characters | code.max validation fails | — | — | ⬜ |
| TC-N06 | Duplicate Code (Global Unique) | "This competency type code already exists." | — | — | ⬜ |
| TC-N07 | Max Length — Name > 100 Characters | name.max validation fails | — | — | ⬜ |
| TC-N08 | Max Length — Description > 255 Characters | description.max validation fails | — | — | ⬜ |
| TC-N09 | View Record With Invalid ID (404) | HTTP 404 | — | — | ⬜ |
| TC-N10 | Edit/Update Record With Invalid ID (404) | HTTP 404 | — | — | ⬜ |
| TC-N11 | Delete Record With Invalid ID (404) | Redirect with error | — | — | ⬜ |
| TC-N12 | Toggle Status With Invalid ID (404) | JSON 404 | — | — | ⬜ |
| TC-N13 | Restore Non-Deleted Record (Already Active) | 404 error | — | — | ⬜ |
| TC-N14 | Force Delete Non-Trashed Record | 404 error | — | — | ⬜ |
| TC-N15 | Permission 403 — No Competency Type Permissions | 403 Forbidden on all CRUD endpoints | — | — | ⬜ |
| TC-N16 | Guest Access Redirect | Redirected to /login | — | — | ⬜ |
| TC-N17 | XSS Injection In Name/Code | Stored as literal; Blade `{{ }}` escapes | — | — | ⬜ |
| TC-N18 | Whitespace-Only Name/Code | Required validation catches empty after trim | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Force Delete Competency Type — Child Competencies Cascade Deleted | All `slb_competencies` with matching competency_type_id deleted via CASCADE | — | — | ⬜ |
| TC-D02 | B | Soft-Delete Record Hidden From Dropdowns | Deleted type excluded from competency parent dropdown | — | — | ⬜ |
| TC-D03 | C | Toggle Status — Inactive Record Hidden From Dropdowns | Inactive type hidden from dropdowns | — | — | ⬜ |
| TC-D04 | D | Restore Does Not Restore Child Competencies | After restore, child competencies remain deleted (no cascading restore) | — | — | ⬜ |
| TC-D05 | E | UI/API | P1 | Competency type create form — Uppercase Code Conversion | strtoupper() in prepareForValidation — submitting lowercase code "skill" is stored as "SKILL" in database | — | — | ⬜ |
| TC-D06 | F | UI/API | P1 | Competency type create form — Alpha Dash Validation — code Field | Code field accepts letters, numbers, dashes, underscores; rejects special characters like spaces or @ | — | — | ⬜ |
| TC-D07 | G | UI/API | P1 | Competency type create form — is_active Default Create — unchecked checkbox | Creating without is_active checked defaults to true (active) because POST defaults to true in prepareForValidation | — | — | ⬜ |
| TC-D08 | H | UI/API | P1 | Competency type edit form — is_active Default Update — unchecked checkbox on update | Updating without is_active checked sets is_active to false because PUT/PATCH defaults to false | — | — | ⬜ |
| TC-D09 | I | UI | P1 | Competency type list with existing active record — AJAX Toggle — toggleStatus route | Clicking toggle flips is_active from true to false (or vice versa) via AJAX without page reload | — | — | ⬜ |
| TC-D10 | J | Permission | P1 | Competency type list as user without delete permission — Policy Gate — destroy action without tenant.competency-type.delete | User lacking delete permission receives 403 when attempting to delete | — | — | ⬜ |
| TC-D11 | K | Model | P1 | Mass Assignment Protection — Only Fillable Fields (`code`, `name`, `description`, `is_active`) Can Be Mass-Assigned | Attempting to mass-assign non-fillable fields like `id` or `created_at` is silently ignored | — | — | ⬜ |
| TC-D12 | L | Model | P1 | `$casts` — `is_active` Cast to Boolean — DB `TINYINT(1)` Returned as `bool` | `$competencyType->is_active` is `true`/`false` (boolean), not `1`/`0` (integer) | — | — | ⬜ |
| TC-D13 | M | Model | P1 | `SoftDeletes` — `trashed()` Returns `true` for Soft-Deleted Records | After soft delete, `$competencyType->trashed()` = `true`; before delete = `false` | — | — | ⬜ |
| TC-D14 | N | Model | P1 | `hasMany` Relationship — `$competencyType->competencies` Returns Collection of `Competency` Models | Relationship query returns only non-deleted competencies (unless `withTrashed` on child) | — | — | ⬜ |
| TC-D15 | O | Controller | P1 | `findOrFail` in `edit()` / `update()` / `show()` / `destroy()` — Invalid ID Throws `ModelNotFoundException` (404) | Accessing any action with non-existent ID returns HTTP 404 | — | — | ⬜ |
| TC-D16 | P | Validation | P1 | Unique Rule on Update Ignores Current ID — Same Code Allowed for Own Record | PUT `code=EXISTING` on the record with that code succeeds (no "already exists" error) | — | — | ⬜ |
| TC-D17 | Q | Validation | P1 | `prepareForValidation()` — Code Trimmed and `strtoupper()` Applied Before Validation | Submitting `"  code_xyz  "` is trimmed to `"CODE_XYZ"` and passes unique check with uppercased value | — | — | ⬜ |
| TC-D18 | R | Activity Log | P1 | Activity Log — `Stored` Event Contains Correct Properties After `store()` | `activity_log` table has entry with event=`Stored`, subject_type=CompetencyType, causer=current user | — | — | ⬜ |
| TC-D19 | S | Controller | P1 | `index()` Uses `paginate(10)` — Response Is `LengthAwarePaginator` with `per_page=10` | JSON/page shows 10 records per page, `total`, `last_page`, `next_page_url` present | — | — | ⬜ |
| TC-D20 | T | Controller | P1 | Redirect After `store()` / `update()` — Redirects to `syllabus.master.index` with `tab=competency_types` | After successful create/update, user redirected to `/syllabus/master?tab=competency_types` | — | — | ⬜ |
| TC-D21 | U | Business Logic | P1 | `destroy()` Sets `is_active=false` Before Calling `delete()` | DB check after soft delete: `is_active = 0`, `deleted_at` is NOT NULL | — | — | ⬜ |
| TC-D22 | V | Business Logic | P1 | `restore()` Sets `is_active=true` After Restoring | DB check after restore: `is_active = 1`, `deleted_at = NULL` | — | — | ⬜ |
| TC-D23 | W | Business Logic | P1 | `toggleStatus()` Flips `is_active` and Returns JSON `{success, is_active, message}` | Toggling active→inactive returns `{success: true, is_active: false, message: "Status updated successfully"}` | — | — | ⬜ |
| TC-D24 | X | Controller | P1 | `show()` Uses `withTrashed()->findOrFail($id)` to Display Soft-Deleted Records | Soft-deleted record is accessible via show route; `deleted_at` visible in response | — | — | ⬜ |
| TC-D25 | Y | Authorization | P1 | `Gate::authorize()` — Each Policy Gate Method Maps to Correct Permission String | `viewAny`→`viewAny`, `view`→`view`, `create`→`create`, `update`→`update`, `delete`→`delete`, `restore`→`restore`, `forceDelete`→`forceDelete`, `status`→`status` — each maps to `tenant.competency-type.{ability}` | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.competency-type.create'), @can('tenant.competency-type.edit'), @can('tenant.competency-type.delete'), @can('tenant.competency-type.status'), @can('tenant.competency-type.view'), @canany(['tenant.competency-type.restore', 'tenant.competency-type.forceDelete']) for access control on all CRUD buttons and actions | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | `syllabus.master` key → `'syllabus/master'` defined in `config/breadcrumb.php`; breadcrumb visible and links correctly to parent screen | — | — | ◌ |
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
| 1 | Inspect index.blade.php for add/create button | @can('tenant.competency-type.create') wraps the Add New button; user without create permission does not see it
| 2 | Inspect row-level action buttons (view, edit, delete, status toggle) | @can('tenant.competency-type.view'), @can('tenant.competency-type.edit'), @can('tenant.competency-type.delete'), @can('tenant.competency-type.status') used appropriately; expired permissions hide corresponding buttons
| 3 | Inspect trash.blade.php for restore/forceDelete buttons | @canany(['tenant.competency-type.restore', 'tenant.competency-type.forceDelete']) wraps action buttons in trash view
| 4 | Inspect view.blade.php for edit button | @can('tenant.competency-type.edit') wraps the Edit button on show/details page
| 5 | Log in as user with all permissions | All buttons visible and functional |
| 6 | Log in as user with viewAny only (no create/edit/delete) | Add New button hidden; action columns show view icon only or no actions |

#### TC-CR02: Breadcrumb Config — Route Registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File contains routing configuration for the syllabus module |
| 2 | Verify the 'syllabus.master' key exists | Config has 'syllabus.master' => 'syllabus/master' entry
| 3 | Verify its value points to the correct parent screen URL | Value 'syllabus/master' correctly references Master tab view
| 4 | Load the screen via the Master tab tab | Breadcrumb trail shows correct hierarchy and highlights current screen |
| 5 | Click the breadcrumb parent link | Navigates correctly to Master tab page without errors |
### 6.1 Positive TC Steps

#### TC-P01: Competency Types List Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Expand "Syllabus" from left sidebar | Menu options appear |
| 3 | Click "Syllabus Master" and select "Competency Types" tab | Page loads |
| 4 | Check search input | Search field present |
| 5 | Check status filter | Dropdown: "All", "Active", "Inactive" |
| 6 | Check "Add New" button | Visible |
| 7 | Check "Trash" button | Visible |
| 8 | Check table columns | Code, Name, Description, Status, Actions |

---

#### TC-P02: Search Competency Types By Name Or Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create "Knowledge" (code="KNOWLEDGE"), "Skill" (code="SKILL") | 2 records |
| 2 | Type "Knowledge" in search | Only "Knowledge" visible |
| 3 | Type "SKILL" in search | Only "Skill" visible |
| 4 | Clear search | Both visible |

---

#### TC-P03: Filter By Active/Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active and inactive records | Both exist |
| 2 | Filter "Active" | Only active visible |
| 3 | Filter "Inactive" | Only inactive visible |
| 4 | Filter "All" | Both visible |

---

#### TC-P04: Create Competency Type With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add New" | Form opens |
| 2 | Enter code: "KNOWLEDGE" | Code filled |
| 3 | Enter name: "Cognitive Knowledge" | Name filled |
| 4 | Click "Save" | POST to store |
| 5 | Check response | Success message |
| 6 | DB check: `SELECT * FROM slb_competency_types WHERE code='KNOWLEDGE'` | Record exists, `is_active=1` |

---

#### TC-P05: Create Competency Type With All Optional Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, fill code and name | Required fields set |
| 2 | Enter description: "Broad category for cognitive knowledge" | Description filled |
| 3 | Click "Save" | Record created |
| 4 | DB check: description saved correctly | Matches input |

---

#### TC-P06: Create With Code Using AlphaDash Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New | Form visible |
| 2 | Enter code: "KNOWLEDGE_DOMAIN" (with underscore) | Valid alpha_dash |
| 3 | Enter name: "Knowledge Domain" | Name filled |
| 4 | Click "Save" | Record created successfully |

---

#### TC-P07: Create With Code Auto-Uppercase

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code: "knowledge" (lowercase) | Lowercase |
| 2 | Click "Save" | Record created |
| 3 | DB check: `SELECT code FROM slb_competency_types WHERE name LIKE '%Knowledge%'` | code = "KNOWLEDGE" |

---

#### TC-P08: Edit Competency Type Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="EDITTEST", name="Edit Test" | Record exists |
| 2 | Click "Edit" | Edit form with pre-filled data |
| 3 | Verify code, name, description match | All pre-filled correctly |

---

#### TC-P09: Update Competency Type All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="OLD", name="Old Name" | Record exists |
| 2 | Edit: change code to "NEW", name to "New Name" | Fields updated |
| 3 | Toggle is_active OFF | OFF |
| 4 | Click "Save" | Update succeeds |
| 5 | DB check: all fields updated | Matches input |

---

#### TC-P10: View Competency Type Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="VIEWTEST" | Record exists |
| 2 | Click "View" | Detail page shows code, name, description, status |

---

#### TC-P11: Soft Delete Competency Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record | Exists |
| 2 | Click delete, confirm | Soft deleted |
| 3 | DB check: `deleted_at` NOT NULL | Trashed |

---

#### TC-P12: Trash Page Shows Deleted Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete a record | In trash |
| 2 | Click "Trash" button | Trash page shows deleted record |
| 3 | Check Restore and Force Delete buttons | Both visible |

---

#### TC-P13: Restore Competency Type From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash, click "Restore" | Confirmation |
| 2 | Confirm | Restored, `deleted_at` = NULL |
| 3 | Activity log "Restored" | Event logged |

---

#### TC-P14: Force Delete Competency Type (No Dependencies)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete, then force delete | Record permanently removed |
| 2 | Activity log "Deleted" | Event logged |

---

#### TC-P15: Toggle Status Active ↔ Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active record | Active |
| 2 | Toggle switch | AJAX POST, is_active flips |
| 3 | Toggle again | Flips back |

---

#### TC-P16: Pagination Works (10 Per Page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 11+ records | Records exist |
| 2 | Check pagination | Page 1 shows 10 records |
| 3 | Click page 2 | Remaining displayed |

---

#### TC-P17: Full Lifecycle: Create → Edit → Toggle → Delete → Trash → Restore → Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create → Edit → Toggle OFF/ON → Soft Delete → Trash → Restore → Soft Delete → Force Delete | All successful, activity logged |

---

#### TC-P18: Empty State — No Records Yet

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate with no records | "No records found" message |
| 2 | Check Add New button | Visible and enabled |

---

#### TC-P19: Default is_active = TRUE On Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record without setting is_active | Record created |
| 2 | DB check: `SELECT is_active` | is_active = 1 |

---

### 6.2 Negative TC Steps

#### TC-N01: Required — Missing Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, leave code empty, fill name | Code missing |
| 2 | Click "Save" | HTTP 500: "Competency type code is required." |

---

#### TC-N02: Required — Missing Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, fill code, leave name empty | Name missing |
| 2 | Click "Save" | HTTP 500: "Competency type name is required." |

---

#### TC-N03: Invalid Code — Space Character

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code: "KNOWLEDGE DOMAIN" (with space) | Invalid alpha_dash |
| 2 | Click "Save" | HTTP 500: "Code may only contain letters, numbers, dashes and underscores." |

---

#### TC-N04: Invalid Code — Special Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code: "KNOWLEDGE@DOMAIN" | Invalid |
| 2 | Click "Save" | HTTP 500: alpha_dash validation fails |

---

#### TC-N05: Invalid Code — Exceeds 20 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code of 21 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500 |

---

#### TC-N06: Duplicate Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with code="DUPTEST" | Exists |
| 2 | Create another with same code | HTTP 500: "This competency type code already exists." |

---

#### TC-N07: Max Length — Name > 100 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter name of 101 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500 |

---

#### TC-N08: Max Length — Description > 255 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter description of 256 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500 |

---

#### TC-N09: View Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `/syllabus/competency-types/99999` | HTTP 404 |

---

#### TC-N10: Edit/Update Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `/syllabus/competency-types/99999/edit` | HTTP 404 |
| 2 | PUT to invalid ID | HTTP 404 |

---

#### TC-N11: Delete Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE to `/syllabus/competency-types/99999` | Redirect with error |

---

#### TC-N12: Toggle Status With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggle-status with invalid ID | JSON 404 |

---

#### TC-N13: Restore Non-Deleted Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active record, try restore | 404 error |

---

#### TC-N14: Force Delete Non-Trashed Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active record, try force delete | 404 error |

---

#### TC-N15: Permission 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without permissions | 403 on all CRUD |

---

#### TC-N16: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate to competency types | Redirected to login |

---

#### TC-N17: XSS Injection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with `<script>alert('xss')</script>` | Stored as literal |
| 2 | View on page | Script not executed |

---

#### TC-N18: Whitespace-Only Name/Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code="   ", name="   " | Empty after trim |
| 2 | Click "Save" | Validation fails |

---



---

### 6.3 Dependency TC Steps

#### TC-D01: Force Delete Competency Type — Child Competencies Cascade Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency type T1 and a competency linked to T1 | Competency has competency_type_id = T1.id |
| 2 | Soft delete T1 | T1 in trash |
| 3 | Force delete T1 | T1 permanently removed |
| 4 | DB check: child competency | Permanently deleted (ON DELETE CASCADE) |

---

#### TC-D02: Soft-Delete Record Hidden From Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active competency type | Active |
| 2 | Soft delete | Trashed |
| 3 | Navigate to competencies create form | Deleted type NOT in dropdown |
| 4 | Restore | Appears again |

---

#### TC-D03: Toggle Status — Inactive Record Hidden From Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active type | Active |
| 2 | Toggle inactive | is_active = 0 |
| 3 | Check competency form dropdown | Inactive type hidden |

---

#### TC-D04: Restore Does Not Restore Child Competencies

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency type with child competency | Both exist |
| 2 | Soft delete type (child deleted via cascade) | Both soft deleted |
| 3 | Restore type | Type restored, child remains deleted |

---

#### TC-D05: Uppercase Code Conversion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New competency type form | Form visible |
| 2 | Enter code: "skill" (all lowercase) | Code filled |
| 3 | Enter name: "Skill Competency" | Name filled |
| 4 | Click "Save" | POST to store |
| 5 | DB check: `SELECT code FROM slb_competency_types WHERE name='Skill Competency'` | code = "SKILL" (uppercased) |

---

#### TC-D06: Alpha Dash Validation — code Field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New competency type form | Form visible |
| 2 | Enter code: "MY-SKILL_01" (dashes and underscores) | Valid alpha_dash |
| 3 | Enter name: "My Skill 01" | Name filled |
| 4 | Click "Save" | Record created successfully |
| 5 | Open another new form | Form visible |
| 6 | Enter code: "invalid code" (with space) | Invalid |
| 7 | Click "Save" | HTTP 500: "Code may only contain letters, numbers, dashes and underscores." |
| 8 | Enter code: "bad@code" (special char) | Invalid |
| 9 | Click "Save" | HTTP 500: alpha_dash validation fails |

---

#### TC-D07: is_active Default Create — Unchecked Checkbox

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New competency type form | Form visible |
| 2 | Enter code: "DEFAULTACTIVE", name: "Default Active Test" | Fields filled |
| 3 | Leave is_active checkbox unchecked | Unchecked (not submitted) |
| 4 | Click "Save" | Record created |
| 5 | DB check: `SELECT is_active FROM slb_competency_types WHERE code='DEFAULTACTIVE'` | is_active = 1 (defaults to true on POST) |

---

#### TC-D08: is_active Default Update — Unchecked Checkbox on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active record: code="UPDATESTAT", name="Update Status Test", is_active=1 | Record exists and active |
| 2 | Open edit form for this record | Edit form with pre-filled data, is_active checked |
| 3 | Uncheck is_active checkbox | Unchecked |
| 4 | Click "Save" | PUT/PATCH request |
| 5 | DB check: `SELECT is_active FROM slb_competency_types WHERE code='UPDATESTAT'` | is_active = 0 (defaults to false on PUT/PATCH when unchecked) |

---

#### TC-D09: AJAX Toggle — toggleStatus Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active record: code="TOGGLETEST", name="Toggle Test" | Record exists, is_active=1 |
| 2 | Navigate to competency types list | Record visible with toggle switch ON |
| 3 | Click toggle switch | AJAX POST to `/syllabus/competency-types/{id}/toggle-status` |
| 4 | Verify page not reloaded | No full page load |
| 5 | Check response | JSON `{success: true, is_active: false, message: "..."}` |
| 6 | Verify toggle switch now shows OFF | UI updated to inactive state |
| 7 | Click toggle again | AJAX POST again |
| 8 | Check response | JSON `{success: true, is_active: true, message: "..."}` |
| 9 | DB check: is_active flips back to 1 | Correct final state |

---

#### TC-D10: Policy Gate — destroy Action Without Delete Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with all permissions except `tenant.competency-type.delete` | User session active |
| 2 | Create a competency type record to delete | Record exists |
| 3 | Navigate to competency types list | Record visible |
| 4 | Click delete button | Confirmation prompt |
| 5 | Confirm deletion | POST to destroy |
| 6 | Check response | HTTP 403 Forbidden (policy denies) |
| 7 | DB check: record still exists | Not deleted |

---

#### TC-D11: Mass Assignment Protection — Only Fillable Fields Mass-Assignable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Instantiate `CompetencyType::create(['code'=>'MA', 'name'=>'Mass Assign', 'id'=>99999, 'created_at'=>'2020-01-01'])` | Record created with auto-incremented `id` and real `created_at`; `id=99999` and `created_at='2020-01-01'` ignored |
| 2 | DB check: `SELECT id, code, created_at FROM slb_competency_types WHERE code='MA'` | `id ≠ 99999`, `created_at` is current timestamp |

---

#### TC-D12: `$casts` — `is_active` Boolean Cast

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with `is_active=1` | Record created |
| 2 | Retrieve via `CompetencyType::first()` | `$type->is_active` is `true` (boolean) not `1` (integer) |
| 3 | `var_dump($type->is_active)` | `bool(true)` |
| 4 | Create record with `is_active=0` | Record created |
| 5 | `var_dump($type->is_active)` | `bool(false)` |

---

#### TC-D13: `SoftDeletes` — `trashed()` Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active record: code="SOFTTST" | Record exists |
| 2 | Call `$type->trashed()` on active record | Returns `false` |
| 3 | Soft delete the record | `deleted_at` set |
| 4 | Call `$type->trashed()` on deleted record | Returns `true` |

---

#### TC-D14: `hasMany` Relationship — `$competencyType->competencies`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency type: code="RELATION" | Type exists |
| 2 | Create 2 competencies linked to this type via `competency_type_id` | Competencies exist |
| 3 | Call `$competencyType->competencies` | Returns `Collection` with 2 `Competency` models |
| 4 | Check relationship `getRelated()` | Related model is `Modules\Syllabus\Models\Competency` |

---

#### TC-D15: `findOrFail` — Invalid ID Throws 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/syllabus/competency-types/99999` | HTTP 404 |
| 2 | GET `/syllabus/competency-types/99999/edit` | HTTP 404 |
| 3 | PUT `/syllabus/competency-types/99999` with valid data | HTTP 404 |
| 4 | DELETE `/syllabus/competency-types/99999` | HTTP 404 |
| 5 | POST `/syllabus/competency-types/99999/toggle-status` | JSON 404 |

---

#### TC-D16: Unique Validation on Update Ignores Current ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="UNIQUE01", name="Unique Test 1" | Record 1 exists |
| 2 | Create another: code="UNIQUE02", name="Unique Test 2" | Record 2 exists |
| 3 | PUT `/syllabus/competency-types/{id1}` with code="UNIQUE01" (same code) | HTTP 200 — validation passes (ignores own ID) |
| 4 | PUT `/syllabus/competency-types/{id2}` with code="UNIQUE01" (taken code) | HTTP 500 — "This competency type code already exists." |

---

#### TC-D17: `prepareForValidation()` — Code Trim and `strtoupper`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, enter code: `"  abc_def  "` (with surrounding spaces) | Code filled |
| 2 | Enter name: "Trim Upper Test" | Name filled |
| 3 | Click "Save" | Record created |
| 4 | DB check: `SELECT code FROM slb_competency_types WHERE name='Trim Upper Test'` | code = `"ABC_DEF"` (trimmed and uppercased) |

---

#### TC-D18: Activity Log — `Stored` Event on Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="ACTLOG", name="Activity Log Test" | Record created |
| 2 | Query `activity_log` table: `SELECT * FROM activity_log WHERE subject_type LIKE '%CompetencyType%'` | Entry exists |
| 3 | Check `event` column | `"Stored"` |
| 4 | Check `causer_id` | Equals current authenticated user's ID |
| 5 | Check `properties` JSON | Contains `code`, `name`, `is_active` attributes |

---

#### TC-D19: `index()` Uses `paginate(10)` — 10 Per Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 12 competency type records | 12 records exist |
| 2 | Navigate to competency types list (page 1) | 10 records displayed |
| 3 | Check pagination controls | "Showing 1 to 10 of 12 entries", page 2 link visible |
| 4 | Click page 2 | 2 records displayed |

---

#### TC-D20: Redirect After `store()` / `update()`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with code="REDIRECT", name="Redirect Test" | POST succeeded |
| 2 | Check redirect URL | Redirected to `/syllabus/master?tab=competency_types` |
| 3 | Update same record with name="Redirect Updated" | PUT succeeded |
| 4 | Check redirect URL | Redirected to `/syllabus/master?tab=competency_types` |

---

#### TC-D21: `destroy()` Sets `is_active=false` Before Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active record: code="DELBIZ", name="Delete Biz Logic", is_active=1 | Record exists, active |
| 2 | Soft delete the record | Delete succeeds |
| 3 | DB check: `SELECT is_active, deleted_at FROM slb_competency_types WHERE code='DELBIZ'` | `is_active = 0`, `deleted_at` is NOT NULL |

---

#### TC-D22: `restore()` Sets `is_active=true` After Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete active record (code="RESTBIZ") | Trashed, is_active=0 |
| 2 | Navigate to trash, restore record | Restore succeeds |
| 3 | DB check: `SELECT is_active, deleted_at FROM slb_competency_types WHERE code='RESTBIZ'` | `is_active = 1`, `deleted_at = NULL` |

---

#### TC-D23: `toggleStatus()` Returns JSON `{success, is_active, message}`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active record: code="TOGJSON", name="Toggle JSON Test", is_active=1 | Record exists, active |
| 2 | POST to `/syllabus/competency-types/{id}/toggle-status` | AJAX call |
| 3 | Verify response Content-Type | `application/json` |
| 4 | Parse response JSON | `{success: true, is_active: false, message: "Status updated successfully"}` |
| 5 | POST again (toggle back) | Response: `{success: true, is_active: true, message: "Status updated successfully"}` |

---

#### TC-D24: `show()` Uses `withTrashed()` — Soft-Deleted Record Visible

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="WITHTRSH", name="With Trashed Show" | Record exists |
| 2 | Soft delete the record | Trashed |
| 3 | GET `/syllabus/competency-types/{id}` | HTTP 200 — record displayed |
| 4 | Check response includes `deleted_at` | `deleted_at` is NOT NULL in output |

---

#### TC-D25: `Gate::authorize()` — Policy Maps Correct Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with only `tenant.competency-type.viewAny` | User session active |
| 2 | Access index page | HTTP 200 (viewAny allowed) |
| 3 | Access show for a record | HTTP 403 (view denied) |
| 4 | Access create form | HTTP 403 (create denied) |
| 5 | Login as user with only `tenant.competency-type.create` | User session active |
| 6 | Access create form | HTTP 200 (create allowed) |
| 7 | Access edit form | HTTP 403 (update denied) |
| 8 | Login as user with only `tenant.competency-type.update` | User session active |
| 9 | Access edit form | HTTP 200 (update allowed) |
| 10 | Attempt soft delete | HTTP 403 (delete denied) |
| 11 | Login as user with all permissions | User session active |
| 12 | Perform toggle status | HTTP 200 (status allowed) |
