# slb_grade_division_master_TcList

## Module: Syllabus → Syllabus Master → Grade Divisions

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Syllabus Master |
| Feature | Grade Divisions |
| URL(s) | `/syllabus/master` (index via tab), `/syllabus/grade-division/create` (create), `/syllabus/grade-division/store` (store), `/syllabus/grade-division/{id}` (show), `/syllabus/grade-division/{id}/edit` (edit), `/syllabus/grade-division/{id}/update` (update), `/syllabus/grade-division/{id}/destroy` (destroy), `/syllabus/grade-division/{id}/restore` (restore), `/syllabus/grade-division/{id}/force-delete` (forceDelete), `/syllabus/grade-division/trash/view` (trash), `/syllabus/grade-division/toggle-lock/{id}` (toggleLock), `/syllabus/grade-division/toggle-status/{id}` (toggleStatus) |
| Controller | `Modules\Syllabus\Http\Controllers\GradeDivisionController` |
| Model(s) | `Modules\Syllabus\Models\GradeDivisionMaster` |
| Validation (Create) | `Modules\Syllabus\Http\Requests\GradeDivisionRequest` |
| Validation (Update) | `Modules\Syllabus\Http\Requests\GradeDivisionRequest` |
| Permissions | `tenant.grade-division.viewAny`, `tenant.grade-division.view`, `tenant.grade-division.create`, `tenant.grade-division.update`, `tenant.grade-division.delete`, `tenant.grade-division.restore`, `tenant.grade-division.forceDelete` |
| Soft Deletes | Yes (`GradeDivisionMaster` uses `SoftDeletes` trait) |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled`, `Lock Toggled` |
| Pagination | 10 per page |
| Lock Guard | `is_locked` prevents edit/delete when true |
| Range Overlap Check | Custom `withValidator()` detects overlapping percentage ranges |

---

## 2. Pre-conditions

- Required permissions: `tenant.grade-division.viewAny`, `tenant.grade-division.view`, `tenant.grade-division.create`, `tenant.grade-division.update`, `tenant.grade-division.delete`, `tenant.grade-division.restore`, `tenant.grade-division.forceDelete`
- Required seed data: At least one active `SchoolClass`, one active `OrganizationAcademicSession`
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For overlap tests: At least one existing grade division with defined percentage range
- For lock tests: At least one locked and one unlocked record
- For scope fallback tests: Records at SCHOOL, BOARD, and CLASS levels

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
| Grade Divisions Grid | getGradeDivisions() | GradeDivisionMaster::with(class) | search(name,code), filters(grading_type,scope,status) | 10/page (grade_divisions_page) |
## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Code**: Uppercase via `strtoupper(trim())` in `prepareForValidation()`, unique scoped to `(grading_type, scope, class_id)`
- **Grading type**: ENUM `GRADE` or `DIVISION`
- **Percentage range**: `min_percentage` 0-100, `max_percentage` 0-100, `gt:min_percentage`
- **Scope**: ENUM `SCHOOL`, `BOARD`, `CLASS`
- **Pre-test cleanup**: Delete created grade divisions by code before/after tests
- **Range overlap**: `withValidator()` checks same `grading_type`, `scope`, `class_id`; range intersects
- **Lock guard**: `is_locked` = true prevents any modification

---

## 5. Business Conditions

### 4.1 Database Schema -- `slb_grade_division_master`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT PK | Auto-increment |
| BC-DB-02 | code | VARCHAR(20) | NOT NULL, UNIQUE scoped `(grading_type, scope, class_id)` |
| BC-DB-03 | name | VARCHAR(100) | NOT NULL |
| BC-DB-04 | description | VARCHAR(255) | DEFAULT NULL |
| BC-DB-05 | grading_type | ENUM('GRADE','DIVISION') | NOT NULL |
| BC-DB-06 | min_percentage | DECIMAL(5,2) | NOT NULL |
| BC-DB-07 | max_percentage | DECIMAL(5,2) | NOT NULL |
| BC-DB-08 | board_code | VARCHAR(50) | DEFAULT NULL |
| BC-DB-09 | academic_session_id | BIGINT FK NULL | FK → `sch_org_academic_sessions_jnt.id` |
| BC-DB-10 | display_order | INT | DEFAULT NULL |
| BC-DB-11 | color_code | VARCHAR(10) | DEFAULT NULL |
| BC-DB-12 | scope | ENUM('SCHOOL','BOARD','CLASS') | NOT NULL |
| BC-DB-13 | class_id | BIGINT FK NULL | FK → `sch_classes.id` |
| BC-DB-14 | is_locked | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-15 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-16 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-17 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-18 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules -- `GradeDivisionRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | code | required, string, max:20, unique scoped `(grading_type, scope, class_id)` | "This grade/division code already exists for selected class and scope." |
| BC-VAL-02 | name | required, string, max:100 | -- |
| BC-VAL-03 | description | nullable, string, max:255 | -- |
| BC-VAL-04 | grading_type | required, in:GRADE,DIVISION | "Grading type is required." |
| BC-VAL-05 | min_percentage | required, numeric, min:0, max:100 | "Minimum percentage is required." / "Minimum percentage must be a valid number." |
| BC-VAL-06 | max_percentage | required, numeric, min:0, max:100, gt:min_percentage | "Maximum percentage is required." / "Maximum percentage must be greater than minimum percentage." |
| BC-VAL-07 | board_code | nullable, string, max:50 | -- |
| BC-VAL-08 | academic_session_id | nullable, integer, exists:sch_org_academic_sessions_jnt,id | -- |
| BC-VAL-09 | scope | required, in:SCHOOL,BOARD,CLASS | "Scope is required." |
| BC-VAL-10 | class_id | nullable, integer, exists:sch_classes,id | "Selected class is invalid." |
| BC-VAL-11 | display_order | nullable, integer, min:1 | -- |
| BC-VAL-12 | color_code | nullable, string, max:10, regex:/^#?[0-9A-Fa-f]{6}$/ | "Color code must be a valid hex value (e.g. #FF5733)." |
| BC-VAL-13 | is_locked | nullable, boolean | -- |
| BC-VAL-14 | is_active | nullable, boolean | -- |
| BC-VAL-15 | **Overlap (custom)** | `withValidator()`: same grading_type, scope, class_id; range intersects | "The percentage range overlaps with an existing active grade/division." |

### 4.3 Validation Rules -- `GradeDivisionRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | code | unique scoped + ignore given ID | "This grade/division code already exists for selected class and scope." |
| BC-VAL-U02 | max_percentage | gt:min_percentage, unique scoped | "Maximum percentage must be greater than minimum percentage." |
| BC-VAL-U03 | Overlap (custom) | Same scope overlap check | "The percentage range overlaps with an existing active grade/division." |
| BC-VAL-U04 | **Lock guard (controller)** | `is_locked` check | "Cannot update locked grade/division." |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.grade-division.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.grade-division.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.grade-division.create | create(), store() | Without → 403 |
| BC-AUTH-04 | tenant.grade-division.update | edit(), update(), toggleLock(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.grade-division.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.grade-division.restore | restore(), trashed() | Without → 403 |
| BC-AUTH-07 | tenant.grade-division.forceDelete | forceDelete() | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Code uppercase | `strtoupper(trim())` in `prepareForValidation()` |
| BC-BIZ-02 | Board code uppercase | Also uppercased via `strtoupper()` |
| BC-BIZ-03 | Range overlap prevention | `withValidator()` checks `min <= existing_max AND max >= existing_min` |
| BC-BIZ-04 | Lock guard -- update | `is_locked = true` → update blocked with error message |
| BC-BIZ-05 | Lock guard -- delete | `is_locked = true` → delete blocked with error message |
| BC-BIZ-06 | Lock guard -- toggleStatus | `is_locked = true` → toggle status blocked |
| BC-BIZ-07 | toggleLock() | Toggles `is_locked` boolean; no lock-guard on this method itself |
| BC-BIZ-08 | Soft delete | `destroy()` sets `is_active = false`, `save()`, then `delete()` |
| BC-BIZ-09 | Scope fallback hierarchy | CLASS > BOARD > SCHOOL when resolving student grade |
| BC-BIZ-10 | Academic session linking | nullable FK to academic sessions for historical preservation |
| BC-BIZ-11 | Activity logging | Stored, Updated, Trashed, Restored, Deleted, Toggled, Lock Toggled all logged |
| BC-BIZ-12 | Display order sorting | Records ordered by `display_order` ASC, then `created_at` DESC |
| BC-BIZ-13 | Screen loads via SyllabusController@master() at GET /syllabus/master with master tab group | Navigating to GET /syllabus/master with appropriate permissions loads the Master tab group; this screen's grid data is fetched and displayed |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | academic_session_id | sch_org_academic_sessions_jnt (id) | Not declared (nullable FK) |
| BC-REF-02 | class_id | sch_classes (id) | Not declared (nullable FK) |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Grade Divisions Page Loads | Page loads with filter/search, Add New button, paginated table | -- | -- | ⬜ |
| TC-P02 | Create Grade Rule With Type=GRADE | Grade record with grading_type='GRADE' created | -- | -- | ⬜ |
| TC-P03 | Create Division Rule With Type=DIVISION | Division record with grading_type='DIVISION' created | -- | -- | ⬜ |
| TC-P04 | Create Rule With Scope=SCHOOL | School-wide rule; no class_id required | -- | -- | ⬜ |
| TC-P05 | Create Rule With Scope=BOARD | Board-specific rule with board_code | -- | -- | ⬜ |
| TC-P06 | Create Rule With Scope=CLASS (With Class) | Class-specific rule with class_id | -- | -- | ⬜ |
| TC-P07 | Create Rule With All Optional Fields | Description, board_code, academic_session_id, display_order, color_code all saved | -- | -- | ⬜ |
| TC-P08 | Create Rule With Academic Session Link | academic_session_id set for historical preservation | -- | -- | ⬜ |
| TC-P09 | Create Rule With Color Code (Hex) | color_code valid hex (#FF5733) saved | -- | -- | ⬜ |
| TC-P10 | Edit Grade Division Loads Pre-Filled Data | Edit form shows existing data | -- | -- | ⬜ |
| TC-P11 | Update Rule Name, Code, Range | Name, code, min/max percentage updated; overlap check passes | -- | -- | ⬜ |
| TC-P12 | Update Rule -- Change Scope | Scope changed from SCHOOL to CLASS | -- | -- | ⬜ |
| TC-P13 | View Rule Details Page | Details shown with all field values | -- | -- | ⬜ |
| TC-P14 | Toggle Lock (Lock → Unlock) | `is_locked` flips; JSON `{success, is_locked}` returned | -- | -- | ⬜ |
| TC-P15 | Toggle Lock (Unlock → Lock) | Lock enabled; edit/delete blocked after lock | -- | -- | ⬜ |
| TC-P16 | Soft Delete Rule (Unlocked) | `deleted_at` set; is_active=false; rule hidden | -- | -- | ⬜ |
| TC-P17 | Trash Page Shows Deleted Rules | Trash list with restore + force delete | -- | -- | ⬜ |
| TC-P18 | Restore Rule From Trash | `deleted_at` = NULL; visible again; activity "Restored" | -- | -- | ⬜ |
| TC-P19 | Force Delete Rule (Permanent) | Record permanently removed; activity "Deleted" | -- | -- | ⬜ |
| TC-P20 | Toggle Status Active ↔ Inactive | `is_active` flips; JSON 200 | -- | -- | ⬜ |
| TC-P21 | Empty State -- No Rules | Table shows "No grade divisions found" | -- | -- | ⬜ |
| TC-P22 | Multiple Rules At Different Scopes (No Overlap) | SCHOOL + BOARD + CLASS rules for different scopes all created | -- | -- | ⬜ |
| TC-P23 | Same Code Allowed For Different Grading Types | Code "A1" can exist for GRADE and DIVISION separately | -- | -- | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required -- Missing `code` | "The code field is required." | -- | -- | ⬜ |
| TC-N02 | Required -- Missing `name` | "The name field is required." | -- | -- | ⬜ |
| TC-N03 | Required -- Missing `grading_type` | "Grading type is required." | -- | -- | ⬜ |
| TC-N04 | Required -- Missing `min_percentage` | "Minimum percentage is required." | -- | -- | ⬜ |
| TC-N05 | Required -- Missing `max_percentage` | "Maximum percentage is required." | -- | -- | ⬜ |
| TC-N06 | Required -- Missing `scope` | "Scope is required." | -- | -- | ⬜ |
| TC-N07 | Invalid Grading Type (Not GRADE/DIVISION) | Validation fails on grading_type.in | -- | -- | ⬜ |
| TC-N08 | Invalid Scope (Not SCHOOL/BOARD/CLASS) | Validation fails on scope.in | -- | -- | ⬜ |
| TC-N09 | Duplicate Code Within Same Scope+Type+Class | "This grade/division code already exists for selected class and scope." | -- | -- | ⬜ |
| TC-N10 | Max Length -- Code > 20 Characters | Validation fails on code.max | -- | -- | ⬜ |
| TC-N11 | Max Length -- Name > 100 Characters | Validation fails on name.max | -- | -- | ⬜ |
| TC-N12 | Invalid `min_percentage` -- Negative | Numeric min validation (must be >= 0) | -- | -- | ⬜ |
| TC-N13 | Invalid `max_percentage` -- > 100 | Numeric max validation (must be <= 100) | -- | -- | ⬜ |
| TC-N14 | Max Percentage <= Min Percentage | "Maximum percentage must be greater than minimum percentage." | -- | -- | ⬜ |
| TC-N15 | Range Overlap -- Same Scope+Type+Class | "The percentage range overlaps with an existing active grade/division." | -- | -- | ⬜ |
| TC-N16 | Invalid Color Code Format | "Color code must be a valid hex value (e.g. #FF5733)." | -- | -- | ⬜ |
| TC-N17 | Update Locked Rule (403) | "Cannot update locked grade/division." | -- | -- | ⬜ |
| TC-N18 | Delete Locked Rule (403) | "Cannot delete locked grade/division." | -- | -- | ⬜ |
| TC-N19 | Toggle Status On Locked Rule (403) | Locked rule cannot be toggled | -- | -- | ⬜ |
| TC-N20 | View Rule With Invalid ID (404) | 404 error: Model not found | -- | -- | ⬜ |
| TC-N21 | Edit/Update With Invalid ID (404) | 404 error: Model not found | -- | -- | ⬜ |
| TC-N22 | Permission 403 -- No Grade Division Permissions | 403 Forbidden on all endpoints | -- | -- | ⬜ |
| TC-N23 | Guest Access Redirect | Redirected to /login | -- | -- | ⬜ |
| TC-N24 | Force Delete Non-Trashed Rule | `onlyTrashed()->find()` returns null → 404 | -- | -- | ⬜ |
| TC-N25 | Restore Non-Deleted Rule | `onlyTrashed()->find()` returns null → 404 | -- | -- | ⬜ |
| TC-N26 | Invalid Academic Session FK | "The selected academic session id is invalid." | -- | -- | ⬜ |
| TC-N27 | Invalid Class ID FK | "Selected class is invalid." | -- | -- | ⬜ |
| TC-N28 | Display Order Negative or Zero | Validation fails on display_order.min | -- | -- | ⬜ |
| TC-N29 | Max Length — description > 255 Characters | Submit 256 chars → validation error on description.max | -- | -- | ⬜ |
| TC-N30 | Max Length — board_code > 50 Characters | Submit 51 chars → validation error on board_code.max | -- | -- | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Range Overlap -- Exact Match Rejected | Same range in same scope+type+class → overlap error | -- | -- | ⬜ |
| TC-D02 | A | Range Overlap -- Partial Overlap Rejected | Overlapping ranges → overlap error | -- | -- | ⬜ |
| TC-D03 | B | Range Non-Overlap -- Adjacent Ranges Allowed | 0-49.99 and 50-100 → allowed (adjacent) | -- | -- | ⬜ |
| TC-D04 | B | Range Overlap Only Within Same Grading Type | Overlap only checked within same GRADE vs DIVISION | -- | -- | ⬜ |
| TC-D05 | C | Lock Toggle -- Lock Then Edit Blocked | Lock enabled → subsequent edit fails | -- | -- | ⬜ |
| TC-D06 | C | Lock Toggle -- Unlock Then Edit Allowed | Unlocked → edit succeeds | -- | -- | ⬜ |
| TC-D07 | D | Scope Fallback -- CLASS Takes Priority | CLASS rule used over BOARD/SCHOOL for matching student | -- | -- | ⬜ |
| TC-D08 | D | Scope Fallback -- BOARD When No CLASS Rule | BOARD rule used when no CLASS-specific rule exists | -- | -- | ⬜ |
| TC-D09 | D | Scope Fallback -- SCHOOL Default | SCHOOL rule used as default when no CLASS/BOARD rule | -- | -- | ⬜ |
| TC-D10 | E | Soft Delete Sets is_active=false First | `destroy()` sets `is_active=0` then `delete()` | -- | -- | ⬜ |
| TC-D11 | F | Inactive Rule Not Checked For Overlap | Inactive record's range ignored in overlap check | -- | -- | ⬜ |
| TC-D12 | G | Activity Log -- All Events Tracked | Stored, Updated, Trashed, Restored, Deleted, Toggled, Lock Toggled all logged | -- | -- | ⬜ |
| TC-D13 | H | DB — P1 — CHECK Constraint: min_percentage < max_percentage | Insert with min_percentage >= max_percentage throws CHECK constraint violation; valid range saves successfully | -- | -- | ⬜ |
| TC-D14 | I | API/Integration — P1 — Overlapping Range Validation | Attempting to create division with range overlapping existing range returns validation error; non-overlapping range succeeds | -- | -- | ⬜ |
| TC-D15 | J | DB — P1 — Composite Unique Constraint: uq_grade_code (code+grading_type+scope+class_id) | Inserting duplicate (code, grading_type, scope, class_id) combination at DB level throws integrity constraint violation | -- | -- | ⬜ |
| TC-D16 | K | DB — P1 — Composite Unique Constraint: uq_scope_range (scope+class_id+min_percentage+max_percentage) | Inserting duplicate (scope, class_id, min_percentage, max_percentage) combination at DB level throws integrity constraint violation | -- | -- | ⬜ |
| TC-D17 | L | UI/API — P1 — ENUM Field Validation: grading_type, scope | Invalid values for grading_type (not GRADE/DIVISION) or scope (not SCHOOL/BOARD/CLASS) are rejected by validation | -- | -- | ⬜ |
| TC-CR01 | A | Model: $fillable properly defined for mass assignment | `$fillable` array includes code/name/description/grading_type/min_percentage/max_percentage/board_code/academic_session_id/display_order/color_code/scope/class_id/is_locked/is_active; no `$guarded` bypass | -- | -- | ⬜ |
| TC-CR02 | A | Model: $casts for is_active, min_percentage, max_percentage | `$casts` has `is_active => 'boolean'`, `min_percentage => 'decimal:2'`, `max_percentage => 'decimal:2'` | -- | -- | ⬜ |
| TC-CR03 | A | Model: SoftDeletes trait imported and correctly configured | `SoftDeletes` trait imported; `deleted_at` column in `$dates` or cast as `datetime` | -- | -- | ⬜ |
| TC-CR04 | B | Controller: Gate::authorize() on every CRUD method | Each method (index/show/create/store/edit/update/destroy/trashed/restore/forceDelete/toggleStatus/toggleLock) calls `Gate::authorize('tenant.grade-division.xxx')` | -- | -- | ⬜ |
| TC-CR05 | B | Controller: is_active=false set before soft delete in destroy() | `destroy()` method sets `$model->is_active = false`, calls `$model->save()`, then `$model->delete()` | -- | -- | ⬜ |
| TC-CR06 | B | Controller: Activity logged for every state-changing action | `Stored/Updated/Trashed/Restored/Deleted/Toggled/LockToggled` all logged via `activity()` with correct description and causer | -- | -- | ⬜ |
| TC-CR07 | C | Request: unique rule ignores current record ID on update | Update validation uses `unique:slb_grade_division_master,code,{recordId}` to skip the same record | -- | -- | ⬜ |
| TC-CR08 | C | Request: prepareForValidation() uppercases and trims code | `prepareForValidation()` applies `strtoupper(trim($this->code))` before validation runs | -- | -- | ⬜ |
| TC-CR09 | D | Policy: All required authorization methods defined | GradeDivisionPolicy defines `viewAny/view/create/update/delete/restore/forceDelete/status` each returning correct Gate check | -- | -- | ⬜ |
| TC-CR10 | E | Routes: Resource routes + extra custom routes registered | `Route::resource('grade-division', GradeDivisionController::class)` plus explicit `trashed/restore/forceDelete/toggleStatus` routes | -- | -- | ⬜ |
| TC-CR11 | B | Controller: Pagination used on index (not getAll) | `index()` calls `paginate(10)` instead of `get()` or `all()` to avoid unbounded results | -- | -- | ⬜ |
| TC-CR12 | B | Controller: Lock guard blocks update/destroy/toggleStatus when is_locked=true | Before any write operation, controller checks `$model->is_locked` and returns error | -- | -- | ⬜ |
| TC-CR13 | B | Controller: forceDelete scoped to onlyTrashed() | `forceDelete()` uses `onlyTrashed()->findOrFail($id)` to prevent deleting active records | -- | -- | ⬜ |
| TC-CR14 | B | Controller: JSON responses follow consistent structure | All AJAX endpoints return `{success: bool, message: string, data?: ...}` with correct HTTP status | -- | -- | ⬜ |
| TC-CR15 | C | Request: Custom withValidator() for range overlap detection | `withValidator()` checks same grading_type/scope/class_id and range intersection (`min <= existing_max AND max >= existing_min`) | -- | -- | ⬜ |

---

## 7. Detailed Test Steps


#### TC-CR01: Blade @can Directives — Permission-based Visibility for All Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php for add/create button | @can('tenant.grade-division.create') wraps the Add New button; user without create permission does not see it
| 2 | Inspect row-level action buttons (view, edit, delete, status toggle) | @can('tenant.grade-division.view'), @can('tenant.grade-division.edit'), @can('tenant.grade-division.delete'), @can('tenant.grade-division.status') used appropriately; expired permissions hide corresponding buttons
| 3 | Inspect trash.blade.php for restore/forceDelete buttons | @canany(['tenant.grade-division.restore', 'tenant.grade-division.forceDelete']) wraps action buttons in trash view
| 4 | Inspect view.blade.php for edit button | @can('tenant.grade-division.edit') wraps the Edit button on show/details page
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
| 2 | Verify success message after create | Page shows success alert: 'Grade division created successfully' (or equivalent for this screen)
| 3 | Update the record | PUT/PATCH to update(); redirects with flash
| 4 | Verify success message after update | 'Grade division updated successfully' (or equivalent)
| 5 | Soft delete the record | DELETE to destroy(); redirects with flash
| 6 | Verify success message after delete | 'Grade division trashed successfully' (or equivalent)
| 7 | Restore from trash | POST to restore(); redirects with flash
| 8 | Verify success message after restore | 'Grade division restored successfully' (or equivalent)
| 9 | Force delete from trash | DELETE to forceDelete(); redirects with flash
| 10 | Verify success message after force delete | 'Grade division force deleted successfully' (or equivalent)


### 6.1 Positive TC Steps

#### TC-P01: Grade Divisions Page Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Expand "Syllabus" → "Syllabus Master" → "Grade Divisions" tab | Page loads at `tab=grade_divisions` |
| 3 | Check filter/search | Filter dropdowns and search input present |
| 4 | Check "Add New" button | Visible |
| 5 | Check grade divisions table | Columns: Code, Name, Grading Type, Range, Scope, Class/Board, Lock, Status, Actions |
| 6 | Check pagination | If 10+ records, pagination links appear |

---

#### TC-P02: Create Grade Rule With Type=GRADE

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Grade Divisions tab | Page loads |
| 2 | Click "Add New" button | Create form opens |
| 3 | Enter code: "A1" | Code filled |
| 4 | Enter name: "Grade A1" | Name filled |
| 5 | Select grading_type: "GRADE" | Type selected |
| 6 | Enter min_percentage: 91.00 | Min filled |
| 7 | Enter max_percentage: 100.00 | Max filled |
| 8 | Select scope: "SCHOOL" | Scope selected |
| 9 | Set is_active = ON | Active |
| 10 | Click "Save" | POST to store |
| 11 | Check response | Success: "Grade division created successfully." |
| 12 | DB check: `SELECT * FROM slb_grade_division_master WHERE code='A1'` | Record exists; `grading_type` = 'GRADE'; code uppercased |

---

#### TC-P03: Create Division Rule With Type=DIVISION

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule with grading_type="DIVISION", code="1ST_DIV", min=60, max=74.99, scope="SCHOOL" | Created |
| 2 | DB check: `grading_type` = 'DIVISION' | Stored |

---

#### TC-P04: Create Rule With Scope=SCHOOL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule with scope="SCHOOL", no class_id, no board_code | Created |
| 2 | DB check: scope='SCHOOL', class_id=NULL, board_code=NULL | School-wide scope |

---

#### TC-P05: Create Rule With Scope=BOARD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule with scope="BOARD", board_code="CBSE", min=90, max=100 | Created |
| 2 | DB check: scope='BOARD', board_code='CBSE' | Board-specific |

---

#### TC-P06: Create Rule With Scope=CLASS (With Class)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule with scope="CLASS", class_id=C1, min=95, max=100 | Created |
| 2 | DB check: scope='CLASS', class_id=C1 | Class-specific |

---

#### TC-P07: Create Rule With All Optional Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Fill required: code="FULL", name="Full Rule", type="GRADE", min=50, max=100, scope="SCHOOL" | Required set |
| 3 | Enter description: "Full description here" | Description |
| 4 | Enter board_code: "CBSE" | Board code |
| 5 | Select academic_session | Session linked |
| 6 | Enter display_order: 2 | Order |
| 7 | Enter color_code: "#00FF00" | Color |
| 8 | Click "Save" | Created |
| 9 | DB check: All optional fields saved | Values match |

---

#### TC-P08: Create Rule With Academic Session Link

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule with academic_session_id = S1 | Created |
| 2 | DB check: `academic_session_id` = S1 | Session linked |

---

#### TC-P09: Create Rule With Color Code (Hex)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule with color_code = "#FF5733" | Created |
| 2 | DB check: color_code = '#FF5733' | Valid hex saved |

---

#### TC-P10: Edit Grade Division Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule: code="EDIT_01", name="Edit Test" | Exists |
| 2 | Click "Edit" button | Edit form loads |
| 3 | Verify all fields pre-filled | Code, name, type, range, scope, etc. all match |

---

#### TC-P11: Update Rule Name, Code, Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule: code="OLD", name="Old", min=10, max=50 | Exists |
| 2 | Edit: code="NEW", name="New", min=20, max=60 | Updated |
| 3 | Click "Save" | Update succeeds |
| 4 | DB check: All fields updated | Values changed |

---

#### TC-P12: Update Rule -- Change Scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule with scope=SCHOOL | Exists |
| 2 | Edit: change scope to CLASS, select class_id=C1 | Updated |
| 3 | DB check: scope='CLASS', class_id=C1 | Changed |

---

#### TC-P13: View Rule Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule with all fields filled | Exists |
| 2 | Click "View" button | Detail page loads |
| 3 | Check code, name, grading type displayed | Visible |
| 4 | Check min/max percentage displayed | Range shown |
| 5 | Check scope, class/board displayed | Scope info |
| 6 | Check lock status, active status | Badges visible |
| 7 | Check academic session, display order, color | Displayed |

---

#### TC-P14: Toggle Lock (Unlock → Lock)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule with is_locked=false | Unlocked |
| 2 | Click lock toggle button | AJAX POST to toggle-lock |
| 3 | Check response | JSON `{success: true, is_locked: true}` |
| 4 | DB check: `is_locked` = 1 | Locked |
| 5 | Activity log: "Lock Toggled" event | Logged |

---

#### TC-P15: Toggle Lock (Lock → Unlock)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click lock toggle on a locked rule | AJAX toggle-lock |
| 2 | Check response | JSON `{success: true, is_locked: false}` |
| 3 | DB check: `is_locked` = 0 | Unlocked |

---

#### TC-P16: Soft Delete Rule (Unlocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create unlocked rule: code="DEL_01" | Exists |
| 2 | Click delete button | SweetAlert confirmation |
| 3 | Confirm delete | Soft deleted |
| 4 | DB check: `is_active` = 0, `deleted_at` NOT NULL | Both set |
| 5 | Activity log: "Trashed" event | Logged |

---

#### TC-P17: Trash Page Shows Deleted Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a rule | Trashed |
| 2 | Click "Trash" button | Navigates to trash view |
| 3 | Check table shows deleted rule | Record visible |
| 4 | Check "Restore" and "Force Delete" buttons | Both present |

---

#### TC-P18: Restore Rule From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash, click "Restore" on trashed rule | Restore succeeds |
| 2 | DB check: `deleted_at` = NULL, `is_active` = 1 | Restored |
| 3 | Navigate back to main list | Rule visible again |
| 4 | Activity log: "Restored" event | Logged |

---

#### TC-P19: Force Delete Rule (Permanent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete, navigate to trash, click "Force Delete" | Confirmation |
| 2 | Confirm | Permanently removed |
| 3 | DB check: Record gone | Force deleted |
| 4 | Activity log: "Deleted" event | Logged |

---

#### TC-P20: Toggle Status Active ↔ Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule with is_active=ON, is_locked=false | Active + unlocked |
| 2 | Click toggle switch | AJAX POST to toggle-status |
| 3 | Check response | JSON `{success: true, is_active: false}` |
| 4 | DB check: is_active=0 | Toggled inactive |
| 5 | Click toggle again | is_active=1 |

---

#### TC-P21: Empty State -- No Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Scope with no grade divisions | No data |
| 2 | Verify table | Shows "No grade divisions found" message |
| 3 | Verify Add New button | Visible and enabled |

---

#### TC-P22: Multiple Rules At Different Scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create SCHOOL-scoped rule (0-100) | School rule |
| 2 | Create BOARD-scoped rule (0-100) | Board rule |
| 3 | Create CLASS-scoped rule (0-100) for class C1 | Class rule |
| 4 | All 3 created successfully (different scopes, no overlap) | No conflict |

---

#### TC-P23: Same Code Allowed For Different Grading Types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create GRADE rule with code="A1" | Grade rule |
| 2 | Create DIVISION rule with code="A1" (different grading_type) | Created (unique scoped includes grading_type) |

---

### 6.2 Negative TC Steps

#### TC-N01: Required -- Missing `code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, leave code empty | Empty |
| 2 | Click "Save" | HTTP 500: "The code field is required." |

---

#### TC-N02: Required -- Missing `name`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave name empty | Empty |
| 2 | Click "Save" | HTTP 500: "The name field is required." |

---

#### TC-N03: Required -- Missing `grading_type`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave grading_type empty | Empty |
| 2 | Click "Save" | HTTP 500: "Grading type is required." |

---

#### TC-N04: Required -- Missing `min_percentage`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave min_percentage empty | Empty |
| 2 | Click "Save" | HTTP 500: "Minimum percentage is required." |

---

#### TC-N05: Required -- Missing `max_percentage`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave max_percentage empty | Empty |
| 2 | Click "Save" | HTTP 500: "Maximum percentage is required." |

---

#### TC-N06: Required -- Missing `scope`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave scope empty | Empty |
| 2 | Click "Save" | HTTP 500: "Scope is required." |

---

#### TC-N07: Invalid Grading Type (Not GRADE/DIVISION)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter grading_type="INVALID" | Not in allowed list |
| 2 | Click "Save" | HTTP 500: "The selected grading type is invalid." |

---

#### TC-N08: Invalid Scope (Not SCHOOL/BOARD/CLASS)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter scope="INVALID" | Not in allowed list |
| 2 | Click "Save" | HTTP 500: "The selected scope is invalid." |

---

#### TC-N09: Duplicate Code Within Same Scope+Type+Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule: code="DUP" with type=GRADE, scope=SCHOOL | Exists |
| 2 | Create another: code="DUP" same type, scope, class | 500: "This grade/division code already exists for selected class and scope." |

---

#### TC-N10: Max Length -- Code > 20 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code of 21 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500: "The code must not be greater than 20 characters." |

---

#### TC-N11: Max Length -- Name > 100 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter name of 101 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500: "The name must not be greater than 100 characters." |

---

#### TC-N12: Invalid `min_percentage` -- Negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter min_percentage=-10 | Below 0 |
| 2 | Click "Save" | HTTP 500: numeric min validation |

---

#### TC-N13: Invalid `max_percentage` -- > 100

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter max_percentage=150 | > 100 |
| 2 | Click "Save" | HTTP 500: numeric max validation |

---

#### TC-N14: Max Percentage <= Min Percentage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter min=50, max=50 (equal) | Not > min |
| 2 | Click "Save" | HTTP 500: "Maximum percentage must be greater than minimum percentage." |
| 3 | Enter min=60, max=40 | Same error |

---

#### TC-N15: Range Overlap -- Same Scope+Type+Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule: min=30, max=60, type=GRADE, scope=SCHOOL | Exists |
| 2 | Create another: min=40, max=70, same type+scope | 500: "The percentage range overlaps with an existing active grade/division." |

---

#### TC-N16: Invalid Color Code Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter color_code="not-a-hex" | Invalid format |
| 2 | Click "Save" | 500: "Color code must be a valid hex value (e.g. #FF5733)." |

---

#### TC-N17: Update Locked Rule (403)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Lock a rule (is_locked=true) | Locked |
| 2 | Attempt to edit and save | Redirect/error: "Cannot update locked grade/division." |

---

#### TC-N18: Delete Locked Rule (403)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to delete a locked rule | Blocked: "Cannot delete locked grade/division." |

---

#### TC-N19: Toggle Status On Locked Rule (403)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to toggle status on a locked rule | Blocked with error |

---

#### TC-N20: View Rule With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `/syllabus/grade-division/99999` | HTTP 404 |

---

#### TC-N21: Edit/Update With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `/syllabus/grade-division/99999/edit` | HTTP 404 |

---

#### TC-N22: Permission 403 -- No Grade Division Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.grade-division.*` | 403 on all endpoints |

---

#### TC-N23: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate to grade divisions tab | Redirected to login |

---

#### TC-N24: Force Delete Non-Trashed Rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt force delete on active rule | 404: `onlyTrashed()` returns null |

---

#### TC-N25: Restore Non-Deleted Rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt restore on active rule | 404: `onlyTrashed()` returns null |

---

#### TC-N26: Invalid Academic Session FK

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set academic_session_id=99999 | Non-existent |
| 2 | Click "Save" | 500: "The selected academic session id is invalid." |

---

#### TC-N27: Invalid Class ID FK

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set class_id=99999 | Non-existent |
| 2 | Click "Save" | 500: "Selected class is invalid." |

---

#### TC-N28: Display Order Negative or Zero

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter display_order=0 | Below min |
| 2 | Click "Save" | 500: "The display order must be at least 1." |

---

#### TC-N29: Max Length — description > 255 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Fill required fields: code, name, grading_type, min_percentage, max_percentage, scope | Required fields set |
| 3 | Enter description of 256 characters | Exceeds max |
| 4 | Click "Save" | HTTP 500 |
| 5 | Validation error: "The description must not be greater than 255 characters." | Error returned |

---

#### TC-N30: Max Length — board_code > 50 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Fill required fields: code, name, grading_type, min_percentage, max_percentage, scope | Required fields set |
| 3 | Enter board_code of 51 characters | Exceeds max |
| 4 | Click "Save" | HTTP 500 |
| 5 | Validation error: "The board code must not be greater than 50 characters." | Error returned |

---

### 6.3 Dependency TC Steps

#### TC-D01: Range Overlap -- Exact Match Rejected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule: min=0, max=100, type=GRADE, scope=SCHOOL | Exists |
| 2 | Try to create same: min=0, max=100, same type+scope | 500: overlap error |

---

#### TC-D02: Range Overlap -- Partial Overlap Rejected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule A: min=20, max=50, type=GRADE, scope=SCHOOL | Exists |
| 2 | Try B: min=30, max=60, same type+scope | 500: overlap (30-50 shared) |

---

#### TC-D03: Range Non-Overlap -- Adjacent Ranges Allowed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule A: min=0, max=49.99, type=GRADE, scope=SCHOOL | Exists |
| 2 | Create rule B: min=50, max=100, same type+scope | Created (adjacent, no overlap) |

---

#### TC-D04: Range Overlap Only Within Same Grading Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create GRADE rule: min=0, max=100, scope=SCHOOL | Exists |
| 2 | Create DIVISION rule: min=0, max=100, scope=SCHOOL (different type) | Created (different grading_type, no overlap check across types) |

---

#### TC-D05: Lock Toggle -- Lock Then Edit Blocked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create unlocked rule | Unlocked |
| 2 | Toggle lock to locked | Locked |
| 3 | Attempt to edit the rule | 403: "Cannot update locked grade/division." |

---

#### TC-D06: Lock Toggle -- Unlock Then Edit Allowed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Take a locked rule, toggle lock to unlock | Unlocked |
| 2 | Edit the rule | Update succeeds |

---

#### TC-D07: Scope Fallback -- CLASS Takes Priority

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create SCHOOL rule: 90-100 for grade A1 | School-level |
| 2 | Create CLASS rule for Class 10: 95-100 for grade A1+ | Class-level |
| 3 | Evaluate student in Class 10 with 96% | Class rule applied: "A1+" (not school's "A1") |

---

#### TC-D08: Scope Fallback -- BOARD When No CLASS Rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create SCHOOL rule and BOARD rule for CBSE | Rules exist |
| 2 | No CLASS rule for the student's class | Fallback to BOARD |
| 3 | Student under CBSE board gets BOARD-mapped grade | Correct |

---

#### TC-D09: Scope Fallback -- SCHOOL Default

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Only SCHOOL rule exists (no CLASS or BOARD) | Default |
| 2 | Evaluate any student | SCHOOL rule applied |

---

#### TC-D10: Soft Delete Sets is_active=false First

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete an unlocked rule | `is_active` = 0 before `deleted_at` set |
| 2 | DB check: is_active=0, deleted_at NOT NULL | Both updated |

---

#### TC-D11: Inactive Rule Not Checked For Overlap

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rule A: min=0, max=50, is_active=1 | Active |
| 2 | Toggle A inactive | Inactive |
| 3 | Create rule B: min=0, max=50, same scope+type (overlaps inactive A) | Created (inactive A ignored) |

---

#### TC-D12: Activity Log -- All Events Tracked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create, update, lock toggle, status toggle, soft delete, restore, force delete | Activity log entries for Stored, Updated, Lock Toggled, Toggled, Trashed, Restored, Deleted |
| 2 | Verify each event | Correct description and causer |

---

#### TC-D13: CHECK Constraint -- min_percentage < max_percentage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Connect to database and attempt INSERT on slb_grade_division_master with min_percentage=90, max_percentage=80 (min > max) | MySQL CHECK constraint violation error thrown |
| 2 | Attempt INSERT with min_percentage=80, max_percentage=80 (equal values) | CHECK constraint violation thrown |
| 3 | Attempt INSERT with min_percentage=80, max_percentage=90 (valid range) | Insert succeeds |
| 4 | DB check: record with min=80, max=90 exists | Valid range saved successfully |

---

#### TC-D14: Overlapping Range Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create grade divisions with ranges 0-33, 34-60, 61-100 for same scope+type+class | All created |
| 2 | Attempt to create division with range 30-50 (overlaps 0-33 and 34-60) | 500: overlap error |
| 3 | Attempt to create division with range 55-70 (overlaps 34-60 and 61-100) | 500: overlap error |
| 4 | Attempt to create division with range 0-100 (fully covers all existing) | 500: overlap error |
| 5 | Create division with range 25-30, different grading_type | Created (different type, no overlap check) |
| 6 | Create division with range 90-100, different class_id | Created (different class, no overlap) |

---

#### TC-D15: Composite Unique Constraint -- uq_grade_code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: code="A1", grading_type="GRADE", scope="SCHOOL", class_id=1 | Created |
| 2 | At DB level, attempt INSERT with duplicate (code, grading_type, scope, class_id) | Integrity constraint violation (Duplicate entry) thrown |
| 3 | Create record with same code "A1" but grading_type="DIVISION" | Created (different type, unique scoped includes grading_type) |
| 4 | Create record with same code "A1", same grading_type, different scope | Created (different scope) |
| 5 | Create record with same code "A1", same scope+type, different class_id | Created (different class) |

---

#### TC-D16: Composite Unique Constraint -- uq_scope_range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record: scope="SCHOOL", class_id=NULL, min_percentage=0, max_percentage=50 | Created |
| 2 | At DB level, attempt INSERT with same (scope, class_id, min_percentage, max_percentage) | Integrity constraint violation (Duplicate entry) thrown |
| 3 | Create record with same scope+class_id but different min=0, max=30 | Created (different range) |
| 4 | Create record with same range but different scope="BOARD" | Created (different scope) |
| 5 | Create record with same range+scope but different class_id=2 | Created (different class) |

---

#### TC-D17: ENUM Field Validation -- grading_type, scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open grade division create form | Form visible |
| 2 | Set grading_type="INVALID" and submit | 500: "The selected grading type is invalid." |
| 3 | Set grading_type="grade" (lowercase) and submit | 500: "The selected grading type is invalid." |
| 4 | Set grading_type="GRADE" and submit | Valid (allowed ENUM value) |
| 5 | Set scope="INVALID" and submit | 500: "The selected scope is invalid." |
| 6 | Set scope="school" (lowercase) and submit | 500: "The selected scope is invalid." |
| 7 | Set scope="SCHOOL" and submit | Valid (allowed ENUM value) |

---

### 6.4 Code Review TC Steps

#### TC-CR01: Model -- $fillable Properly Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `app/Models/GradeDivisionMaster.php` | File loaded |
| 2 | Check `$fillable` property | Array includes: code, name, description, grading_type, min_percentage, max_percentage, board_code, academic_session_id, display_order, color_code, scope, class_id, is_locked, is_active |
| 3 | Check `$guarded` property | Not defined (or empty array) — no mass assignment bypass |
| 4 | Verify no `$guarded = ['*']` | No wildcard guarded |

---

#### TC-CR02: Model -- $casts for is_active, min_percentage, max_percentage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open model file | File loaded |
| 2 | Check `$casts` array | `'is_active' => 'boolean'` present |
| 3 | Check `$casts` for percentage fields | `'min_percentage' => 'decimal:2'` and `'max_percentage' => 'decimal:2'` present |
| 4 | Confirm no type mismatch | Values returned as native types (bool, float) |

---

#### TC-CR03: Model -- SoftDeletes Trait Imported

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open model file | File loaded |
| 2 | Check `use SoftDeletes;` inside class | Trait used |
| 3 | Check `use Illuminate\Database\Eloquent\SoftDeletes;` import | Import statement present |
| 4 | Verify `deleted_at` in `$dates` or cast as `datetime` | Soft delete column properly configured |

---

#### TC-CR04: Controller -- Gate::authorize() on Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `GradeDivisionController.php` | File loaded |
| 2 | Check `index()` method | `Gate::authorize('tenant.grade-division.viewAny')` called |
| 3 | Check `create()` method | `Gate::authorize('tenant.grade-division.create')` called |
| 4 | Check `store()` method | `Gate::authorize('tenant.grade-division.create')` called |
| 5 | Check `show()` method | `Gate::authorize('tenant.grade-division.view')` called |
| 6 | Check `edit()` method | `Gate::authorize('tenant.grade-division.update')` called |
| 7 | Check `update()` method | `Gate::authorize('tenant.grade-division.update')` called |
| 8 | Check `destroy()` method | `Gate::authorize('tenant.grade-division.delete')` called |
| 9 | Check `trashed()` method | `Gate::authorize('tenant.grade-division.restore')` called |
| 10 | Check `restore()` method | `Gate::authorize('tenant.grade-division.restore')` called |
| 11 | Check `forceDelete()` method | `Gate::authorize('tenant.grade-division.forceDelete')` called |
| 12 | Check `toggleStatus()` method | `Gate::authorize('tenant.grade-division.update')` called |

---

#### TC-CR05: Controller -- is_active=false Before Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroy()` method in controller | File loaded |
| 2 | Find `$model->is_active = false` or `->update(['is_active' => 0])` before delete | Assignment present |
| 3 | Find `$model->save()` or equivalent after setting is_active | Save called before delete |
| 4 | Find `$model->delete()` after save | Soft delete called last |

---

#### TC-CR06: Controller -- Activity Log for All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller file | File loaded |
| 2 | Search for `activity()` calls in `store()` | Logged with event `Stored` and description including code/name |
| 3 | Search for `activity()` in `update()` | Logged with event `Updated` |
| 4 | Search for `activity()` in `destroy()` | Logged with event `Trashed` |
| 5 | Search for `activity()` in `restore()` | Logged with event `Restored` |
| 6 | Search for `activity()` in `forceDelete()` | Logged with event `Deleted` |
| 7 | Search for `activity()` in `toggleStatus()` | Logged with event `Toggled` |
| 8 | Search for `activity()` in `toggleLock()` | Logged with event `Lock Toggled` |

---

#### TC-CR07: Request -- Unique Rule Ignores Current ID on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `GradeDivisionRequest.php` | File loaded |
| 2 | Find `rules()` method | Method defined |
| 3 | Check `code` rule for `store` context | `unique:slb_grade_division_master,code` (or with scope columns) |
| 4 | Check `code` rule for `update` context | `unique:slb_grade_division_master,code,{ignoreId}` — ignores current record |
| 5 | Verify `ignoreId` comes from route parameter | `$this->route('grade_division')` or equivalent |

---

#### TC-CR08: Request -- prepareForValidation() Uppercases Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `GradeDivisionRequest.php` | File loaded |
| 2 | Find `prepareForValidation()` method | Method present |
| 3 | Check `$this->merge(['code' => strtoupper(trim($this->code))])` | Code uppercased and trimmed |
| 4 | Check any other fields uppercased (board_code) | `board_code` also uppercased if present |

---

#### TC-CR09: Policy -- All Required Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `GradeDivisionPolicy.php` | File loaded |
| 2 | Check `viewAny()` method | Returns gate check for `tenant.grade-division.viewAny` |
| 3 | Check `view()` method | Returns gate check for `tenant.grade-division.view` |
| 4 | Check `create()` method | Returns gate check for `tenant.grade-division.create` |
| 5 | Check `update()` method | Returns gate check for `tenant.grade-division.update` |
| 6 | Check `delete()` method | Returns gate check for `tenant.grade-division.delete` |
| 7 | Check `restore()` method | Returns gate check for `tenant.grade-division.restore` |
| 8 | Check `forceDelete()` method | Returns gate check for `tenant.grade-division.forceDelete` |
| 9 | Check `status()` method | Returns gate check for `tenant.grade-division.update` |

---

#### TC-CR10: Routes -- Resource + Extra Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open routes file (e.g. `api.php` or `web.php`) | File loaded |
| 2 | Find `Route::resource('grade-division', GradeDivisionController::class)` | Resource route registered |
| 3 | Find explicit route for `trashed` | `GET /grade-division/trash/view` → `trashed` |
| 4 | Find explicit route for `restore` | `POST /grade-division/{id}/restore` → `restore` |
| 5 | Find explicit route for `forceDelete` | `DELETE /grade-division/{id}/force-delete` → `forceDelete` |
| 6 | Find explicit route for `toggleStatus` | `POST /grade-division/toggle-status/{id}` → `toggleStatus` |

---

#### TC-CR11: Controller -- Pagination on Index

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `index()` method in controller | File loaded |
| 2 | Check query uses `paginate(10)` | `GradeDivisionMaster::...->paginate(10)` used |
| 3 | Verify NOT using `get()` or `all()` | No unbounded result set |
| 4 | Verify pagination respects filters | Search/filter scopes applied before `paginate()` |

---

#### TC-CR12: Controller -- Lock Guard Blocks Write Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `update()` method | File loaded |
| 2 | Find `is_locked` check before update | `if ($model->is_locked) { return error }` |
| 3 | Open `destroy()` method | File loaded |
| 4 | Find `is_locked` check before delete | `if ($model->is_locked) { return error }` |
| 5 | Open `toggleStatus()` method | File loaded |
| 6 | Find `is_locked` check before toggle | `if ($model->is_locked) { return error }` |

---

#### TC-CR13: Controller -- forceDelete Uses onlyTrashed()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `forceDelete()` method | File loaded |
| 2 | Check `GradeDivisionMaster::onlyTrashed()->findOrFail($id)` | Scoped to only trashed records |
| 3 | Verify NOT using `GradeDivisionMaster::findOrFail($id)` | Active records cannot be force-deleted |
| 4 | Check error response if record not in trash | Returns 404 |

---

#### TC-CR14: Controller -- Consistent JSON Response Structure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller file | File loaded |
| 2 | Check `toggleStatus()` response | Returns `{success: true/false, is_active: bool, message: string}` |
| 3 | Check `toggleLock()` response | Returns `{success: true/false, is_locked: bool, message: string}` |
| 4 | Check `destroy()` response | Returns JSON with `success: true` and message |
| 5 | Check `restore()` response | Returns JSON with `success: true` and message |
| 6 | Check `forceDelete()` response | Returns JSON with `success: true` and message |
| 7 | Verify HTTP status codes | Success: 200, Validation: 500, Auth: 403, Not found: 404 |

---

#### TC-CR15: Request -- Custom withValidator() for Range Overlap

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `GradeDivisionRequest.php` | File loaded |
| 2 | Find `withValidator()` method | Method present |
| 3 | Check overlap query | Query checks same `grading_type`, `scope`, `class_id` |
| 4 | Check range intersection logic | `$existing->min_percentage < $this->max_percentage && $existing->max_percentage > $this->min_percentage` |
| 5 | Check inactive records excluded | `where('is_active', true)` in overlap query |
| 6 | Check current record excluded on update | `where('id', '!=', $this->route('grade_division'))` on update |
