# lms_ExamType_TcList

## Module: LmsExam → Masters → Exam Type

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Masters (Exam Master) |
| Feature | Exam Type |
| URL(s) | `GET lms-exam.masters.index?active_tab=exam_type` (index), `GET lms-exam.exam-type.create` (create), `POST lms-exam.exam-type.store` (store), `GET lms-exam.exam-type.show/{id}` (show), `GET lms-exam.exam-type.edit/{id}` (edit), `PUT lms-exam.exam-type.update/{id}` (update), `DELETE lms-exam.exam-type.destroy/{id}` (destroy), `GET lms-exam.exam-type.trashed` (trash), `POST lms-exam.exam-type.restore/{id}` (restore), `DELETE lms-exam.exam-type.forceDelete/{id}` (forceDelete), `POST lms-exam.exam-type.toggle-status/{id}` (toggleStatus) |
| Controller | `Modules\LmsExam\Http\Controllers\ExamTypeController` |
| Model(s) | `Modules\LmsExam\Models\ExamType` |
| Validation (Create) | `Modules\LmsExam\Http\Requests\ExamTypeRequest` |
| Validation (Update) | `Modules\LmsExam\Http\Requests\ExamTypeRequest` (same class, ignores own id on code unique) |
| Permissions | `tenant.exam-type.viewAny`, `tenant.exam-type.view`, `tenant.exam-type.create`, `tenant.exam-type.update`, `tenant.exam-type.delete`, `tenant.exam-type.restore`, `tenant.exam-type.forceDelete`, `tenant.exam-type.status`, `tenant.exam-type.import`, `tenant.exam-type.export`, `tenant.exam-type.print` |
| Soft Deletes | Yes (`ExamType` uses `SoftDeletes` trait; destroy() sets is_active=false before delete()) |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |

---

## 2. Pre-conditions

- Required permissions: `tenant.exam-type.viewAny`, `tenant.exam-type.view`, `tenant.exam-type.create`, `tenant.exam-type.update`, `tenant.exam-type.delete`, `tenant.exam-type.restore`, `tenant.exam-type.forceDelete`, `tenant.exam-type.status`
- Required seed data: At least one active exam type record in `lms_exam_types` table for listing/edit/show
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For usage-block tests: At least one exam record referencing an exam type via `exam_type_id`
- Database tables: `lms_exam_types`, `lms_exams` must exist in tenant schema

---

## 3. Default Data Load

When the page loads via Masters tab `?active_tab=exam_type`, the `ExamQueryService@examTypesQuery()` method fetches data:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Exam Types Grid | ExamQueryService@examTypesQuery() | ExamType::query()->latest() | search(code,name,description); is_active filter | None (client-side via tab search) |
| Shared: Master tabs | MastersController@index() | Shared dropdown data for all master tabs | is_active=1 | None |

---

## 4. Test Data Strategy

- **Unique suffix**: Use `now()->format('His') . random_int(100, 999)` for unique code/name
- **Code uniqueness**: `code` column has UNIQUE constraint `uq_exam_type_code` at DB level; validated in ExamTypeRequest
- **Name**: No unique constraint on name, but max 100 chars enforced
- **Pre-test cleanup**: Delete created exam types by UUID sequence or unique code suffix before/after tests
- **Usage check**: `ExamTypeUsageCheckService` checks `Exam::where('exam_type_id', $id)->count()` for edit/delete/restore/forceDelete blocking
- **Boolean casting**: `is_active` stored as TINYINT(1), cast to boolean in model
- **Soft-delete two-phase**: `destroy()` deactivates first (`is_active=false`), then calls `delete()`
- **Restore two-phase**: `restore()` calls model `restore()`, then sets `is_active=true`

---

## 5. Business Conditions

### 4.1 Database Schema — `lms_exam_types`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | code | VARCHAR(50) | NOT NULL, UNIQUE (uq_exam_type_code) |
| BC-DB-03 | name | VARCHAR(100) | NOT NULL |
| BC-DB-04 | description | VARCHAR(255) | DEFAULT NULL |
| BC-DB-05 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-06 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-07 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-08 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules — `ExamTypeRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | code | required, string, max:50, unique:lms_exam_types,code | "Exam type code is required" / "This exam type code already exists" |
| BC-VAL-02 | name | required, string, max:100 | "Exam type name is required" |
| BC-VAL-03 | description | nullable, string, max:255 | — |
| BC-VAL-04 | is_active | boolean | — |
| BC-VAL-05 | is_active (prepare) | merged via `$this->boolean('is_active')` from checkbox | — |

### 4.3 Validation Rules — `ExamTypeRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | code | required, string, max:50, unique:lms_exam_types,code + ignore current id | "This exam type code already exists" |
| BC-VAL-U02 | name | required, string, max:100 | "Exam type name is required" |
| BC-VAL-U03 | description | nullable, string, max:255 | — |
| BC-VAL-U04 | is_active | boolean | — |

### 4.4 Authorization

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.exam-type.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.exam-type.create | create(), store() | Without → 403 |
| BC-AUTH-03 | tenant.exam-type.view | show() | Without → 403 |
| BC-AUTH-04 | tenant.exam-type.update | edit(), update(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.exam-type.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.exam-type.restore | trashed(), restore() | Without → 403 |
| BC-AUTH-07 | tenant.exam-type.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.exam-type.status | Status switch (view did not render toggle button) | Without → toggle button hidden |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create exam type | `ExamType::create($typeData)` with validated data; DB transaction wraps; activityLog('Stored') |
| BC-BIZ-02 | Update exam type | Blocked if `ExamTypeUsageCheckService::isUsed()` returns true; track changes via `getChanges()`; activityLog('Updated') with diff JSON |
| BC-BIZ-03 | Delete (soft) exam type | Blocked if isUsed(); sets `is_active=false`, saves, then calls `$examType->delete()`; activityLog('Trashed') |
| BC-BIZ-04 | Restore exam type | Blocked if isUsed(); calls `$examType->restore()`, then sets `is_active=true`; activityLog('Restored') |
| BC-BIZ-05 | Force delete exam type | Blocked if isUsed(); calls `$examType->forceDelete()`; activityLog('Deleted') |
| BC-BIZ-06 | Toggle status | AJAX endpoint; validates `is_active` required + boolean; DB transaction; activityLog('Toggled'); returns JSON |
| BC-BIZ-07 | Usage check blocks edit | If any exam references this type, edit() and update() return back with error |
| BC-BIZ-08 | Usage check blocks delete | If any exam references this type, destroy() returns back with error |
| BC-BIZ-09 | Usage check blocks restore | If any exam references this type, restore() returns back with error |
| BC-BIZ-10 | Usage check blocks forceDelete | If any exam references this type, forceDelete() returns back with error |
| BC-BIZ-11 | Show page displays usage | show() passes `$isUsed`, `$usageDetails`, `$examList` to view; if used, warning alert shown with exam list |
| BC-BIZ-12 | Transaction rollback on failure | DB::beginTransaction/commit/rollback in store, update, destroy, restore, forceDelete, toggleStatus |
| BC-BIZ-13 | Trash view | `trashed()` returns `ExamType::onlyTrashed()->paginate(10)` for trash listing |
| BC-BIZ-14 | Index with search/filter | ExamQueryService builds query with optional is_active filter and search (code, name, description) |
| BC-BIZ-15 | Code uniqueness enforced at DB | UNIQUE KEY `uq_exam_type_code` on `code` column prevents duplicates |
| BC-BIZ-16 | View shows usage details | Usage section in show view lists where used module, count, and exam list with code/title/status |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | exam_type_id (lms_exams) | lms_exam_types (id) | RESTRICT (via FK constraint fk_exam_type) |
| BC-REF-02 | exam_type_id (msh_exam_group_items) | lms_exam_types (id) | RESTRICT |
| BC-REF-03 | exam_type_id (msh_template_exam_wise) | lms_exam_types (id) | RESTRICT |
| BC-REF-04 | exam_type_id (msh_student_subject_exam_mapping) | lms_exam_types (id) | RESTRICT |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Exam Types Tab Loads With All UI Elements | Tab loads with search bar, is_active filter, table with Code/Name/Description/Active/Action columns | — | — | ⬜ |
| TC-P02 | Search Exam Types By Code | Table filters to show only matching exam types by code | — | — | ⬜ |
| TC-P03 | Search Exam Types By Name | Table filters to show only matching exam types by name | — | — | ⬜ |
| TC-P04 | Search Exam Types By Description | Table filters to show only matching exam types by description | — | — | ⬜ |
| TC-P05 | Filter Exam Types By Active Status | Selecting Active shows only active types; Inactive shows only inactive types | — | — | ⬜ |
| TC-P06 | Create Exam Type With All Required Fields | Exam type created with code, name, is_active=true, description=null | — | — | ⬜ |
| TC-P07 | Create Exam Type With Optional Description | Exam type created with description saved correctly | — | — | ⬜ |
| TC-P08 | Create Exam Type With Inactive Status | Exam type created with is_active=false when toggle is off | — | — | ⬜ |
| TC-P09 | Edit Exam Type Loads Pre-Filled Data | Edit form shows existing exam type data; code, name, description, is_active all pre-filled | — | — | ⬜ |
| TC-P10 | Update Exam Type Code And Name | Code and name updated; code unique validation passes for new code | — | — | ⬜ |
| TC-P11 | Update Exam Type Description | Description updated from null to value, or value to new value | — | — | ⬜ |
| TC-P12 | Update Exam Type Active Status | is_active toggled via edit form | — | — | ⬜ |
| TC-P13 | View Exam Type Details Page | Detail page shows code, name, description, active badge, created_at, updated_at | — | — | ⬜ |
| TC-P14 | View Exam Type Usage Details (When Used) | Show page displays warning alert with usage details and exam list | — | — | ⬜ |
| TC-P15 | View Exam Type Without Usage | Show page displays no warning alert | — | — | ⬜ |
| TC-P16 | Toggle Exam Type Status (Active to Inactive) via AJAX | Status switch toggles is_active; JSON response with success=true | — | — | ⬜ |
| TC-P17 | Toggle Exam Type Status (Inactive to Active) via AJAX | Status switch toggles is_active back to true | — | — | ⬜ |
| TC-P18 | Soft Delete Exam Type (Not Used) | Exam type moved to trash; is_active set to false; activity logged as Trashed | — | — | ⬜ |
| TC-P19 | View Trashed Exam Types | Trash page lists only soft-deleted exam types with restore/forceDelete actions | — | — | ⬜ |
| TC-P20 | Restore Soft-Deleted Exam Type | Exam type restored; is_active set back to true; activity logged as Restored | — | — | ⬜ |
| TC-P21 | Force Delete Exam Type | Exam type permanently removed from DB; activity logged as Deleted | — | — | ⬜ |
| TC-P22 | Full Lifecycle: Create → View → Toggle Inactive → Toggle Active → Edit → Delete → Restore → Force Delete | All transitions succeed; activity logged at each step | — | — | ⬜ |
| TC-P23 | Empty State — No Exam Types | Table shows "No exam types found" message | — | — | ⬜ |
| TC-P24 | Edit Button Disabled When Exam Type Is Used | Show page shows greyed-out edit button when isUsed=true | — | — | ⬜ |
| TC-P25 | View-Only User Can See List But No Actions | User with viewAny only sees list; action buttons hidden | — | — | ⬜ |
| TC-P26 | Refresh Filters Resets Search | Clicking reset button clears all filters and reloads | — | — | ⬜ |
| TC-P27 | Trash Page Empty State | No trashed exam types shows "No Trashed Exam Types Found" | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `code` | Validation error: "Exam type code is required" | — | — | ⬜ |
| TC-N02 | Required — Missing `name` | Validation error: "Exam type name is required" | — | — | ⬜ |
| TC-N03 | Duplicate `code` | HTTP redirect with error: "This exam type code already exists" | — | — | ⬜ |
| TC-N04 | Max Length — Code > 50 Characters | Validation fails on code.max | — | — | ⬜ |
| TC-N05 | Max Length — Name > 100 Characters | Validation fails on name.max | — | — | ⬜ |
| TC-N06 | Max Length — Description > 255 Characters | Validation fails on description.max | — | — | ⬜ |
| TC-N07 | Edit Blocked When Exam Type Is Used | Edit page redirects back with error: "Cannot update this exam type because it is being used in exams." | — | — | ⬜ |
| TC-N08 | Update Blocked When Exam Type Is Used | Update POST redirects back with error: "Cannot update this exam type because it is being used in exams." | — | — | ⬜ |
| TC-N09 | Delete Blocked When Exam Type Is Used | Destroy redirects back with error: "Cannot delete this exam type because it is being used in exams." | — | — | ⬜ |
| TC-N10 | Restore Blocked When Exam Type Is Used | Restore redirects back with error: "Cannot restore this exam type because it is being used in exams." | — | — | ⬜ |
| TC-N11 | Force Delete Blocked When Exam Type Is Used | ForceDelete redirects back with error: "Cannot permanently delete this exam type because it is being used in exams." | — | — | ⬜ |
| TC-N12 | View Exam Type With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N13 | Edit Exam Type With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N14 | Update Exam Type With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N15 | Delete Exam Type With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N16 | Restore Exam Type With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N17 | Force Delete Exam Type With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N18 | Toggle Status With Invalid ID | JSON 500 error: Model not found | — | — | ⬜ |
| TC-N19 | Toggle Status Without is_active Parameter | Validation error: "The is active field is required." | — | — | ⬜ |
| TC-N20 | Toggle Status With Non-Boolean is_active | Validation error: "The is active field must be true or false." | — | — | ⬜ |
| TC-N21 | Permission 403 — No Exam Type Permissions | 403 Forbidden on all CRUD endpoints for user without `tenant.exam-type.*` gates | — | — | ⬜ |
| TC-N22 | Guest Access Redirect | Redirected to /login for all exam type routes | — | — | ⬜ |
| TC-N23 | XSS Injection In Code Or Name | Stored as literal string; Blade `{{ }}` escapes output; no script execution | — | — | ⬜ |
| TC-N24 | Whitespace-Only Code | Required validation catches empty/whitespace-only strings | — | — | ⬜ |
| TC-N25 | Create With Non-String Code | Validation fails on code.string | — | — | ⬜ |
| TC-N26 | Update Code To Duplicate Value | Unique validation (ignoring own ID) catches duplicate | — | — | ⬜ |
| TC-N27 | Force Delete On Non-Trashed Record | Model must be fetched via withTrashed(); works on non-trashed too | — | — | ⬜ |
| TC-N28 | Restore Non-Trashed Record | onlyTrashed()->findOrFail() will 404 | — | — | ⬜ |
| TC-N29 | DB Error During Create — Transaction Rollback | Simulate DB failure; transaction rolls back; no partial record created | — | — | ⬜ |
| TC-N30 | DB Error During Update — Transaction Rollback | Simulate DB failure; transaction rolls back; original data preserved | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create Exam Type → Activity Logged | activity_logs table has entry with event 'Stored', message 'A new exam type was created.' | — | — | ⬜ |
| TC-D02 | B | Update Exam Type → Changes Tracked In Activity Log | activity_logs has entry with changes JSON diff showing old/new values | — | — | ⬜ |
| TC-D03 | C | Delete Exam Type → Is_Active Set False Before Delete | DB record shows is_active=0 AND deleted_at IS NOT NULL | — | — | ⬜ |
| TC-D04 | D | Restore Exam Type → Is_Active Set True After Restore | DB record shows is_active=1 AND deleted_at IS NULL | — | — | ⬜ |
| TC-D05 | E | Usage Check Blocks Edit — Exam References Type | Exam exists with exam_type_id=X; edit(X) returns error | — | — | ⬜ |
| TC-D06 | F | Usage Check Blocks Delete — Exam References Type | Exam exists with exam_type_id=X; destroy(X) returns error | — | — | ⬜ |
| TC-D07 | G | Toggle Status Returns JSON — Frontend Handles Response | Response has success, is_active, message; frontend toast shown | — | — | ⬜ |
| TC-D08 | H | Transaction Rollback On Store Exception | DB::rollback() called; no partial record; user returned to form with error | — | — | ⬜ |
| TC-D09 | I | ExamTypePolicy — All Gates Coverage | Policy defines 11 gates: viewAny, view, create, update, delete, restore, forceDelete, status, import, export, print | — | — | ⬜ |
| TC-D10 | J | ExamTypeRequest — authorize() Matches HTTP Method | POST→create, PUT/PATCH→update, DELETE→delete, GET→view | — | — | ⬜ |
| TC-D11 | K | Unique Code Constraint At DB Level | Direct INSERT with duplicate code throws integrity constraint violation | — | — | ⬜ |
| TC-D12 | L | SoftDeletes Trait — onlyTrashed/withTrashed | onlyTrashed() returns only deleted; withTrashed() returns all including deleted | — | — | ⬜ |
| TC-D13 | M | ExamType Model — $casts Boolean | is_active stored as TINYINT(1), accessed as boolean via model | — | — | ⬜ |
| TC-D14 | N | ExamType Model — hasMany Exams Relationship | $examType->exams returns related Exam models where exam_type_id matches | — | — | ⬜ |
| TC-D15 | O | ExamType Model — scopeActive | ExamType::active() applies where('is_active', true) | — | — | ⬜ |
| TC-D16 | P | Controller — findOrFail — edit/update/show/destroy with Valid and Invalid IDs | Valid ID loads model; Invalid ID throws ModelNotFoundException → HTTP 404 | — | — | ⬜ |
| TC-D17 | Q | Controller — Gate::authorize — Authorization Before CRUD | Gate::authorize called before every controller action | — | — | ⬜ |
| TC-D18 | R | Controller — activityLog — Activity Logged After CRUD Operations | Each store/update/destroy/restore/forceDelete/toggleStatus logs activity | — | — | ⬜ |
| TC-D19 | S | Controller — DB Transactions in store/update/destroy/restore/forceDelete/toggleStatus | DB::beginTransaction/commit/rollback wraps all write operations | — | — | ⬜ |
| TC-D20 | T | Routes — Resourceful Routes + Custom Routes (trashed, restore, forceDelete, toggleStatus) | All routes map to correct controller methods with auth middleware | — | — | ⬜ |
| TC-D21 | U | Blade @can Directives — Permission-based visibility for action buttons | @can('tenant.exam-type.*') wraps create button, action columns, status toggle | — | — | ⬜ |
| TC-D22 | V | Breadcrumb Config — Route registered | Breadcrumb visible and links correctly to Masters tab | — | — | ⬜ |
| TC-D23 | W | View — isset()/null-safe Checks for Relationships | All relationship expressions use isset/optional/null-safe; no undefined property errors | — | — | ⬜ |
| TC-D24 | X | Controller — Redirect With Flash Messages After CRUD | All CRUD actions return redirect with session flash success/error | — | — | ⬜ |
| TC-D25 | Y | ExamTypeUsageCheckService — getUsageDetails Returns Array | Returns ['Exams' => count, 'Active Exams' => count] or empty array | — | — | ⬜ |
| TC-D26 | Z | ExamTypeUsageCheckService — getUsageMessage Returns String | Returns 'This exam type is used in: X exam(s).' or empty string | — | — | ⬜ |
| TC-D27 | AA | ExamTypeUsageCheckService — getExams Returns Collection | Returns all Exam records where exam_type_id matches | — | — | ⬜ |
| TC-D28 | AB | FormRequest prepareForValidation Converts is_active | Checkbox unchecked → boolean(false); Checkbox checked → boolean(true) | — | — | ⬜ |
| TC-D29 | AC | Cascade RESTRICT — Cannot Delete Exam Type While Exams Reference It | FK constraint prevents deletion; controller blocks before DB reaches constraint | — | — | ⬜ |
| TC-D30 | AD | ToggleStatus Returns 500 On Exception | Catch block returns JSON with success=false, message, status 500 | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.exam-type.status'), @canany(['tenant.exam-type.view', 'tenant.exam-type.update', 'tenant.exam-type.delete']), @canany(['tenant.exam-type.restore', 'tenant.exam-type.forceDelete']), @can('tenant.exam-type.edit') for access control on all buttons | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered | Breadcrumb config has entry for exam type routes | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — DB Transactions in store/update/destroy/restore/forceDelete/toggleStatus | All write methods use DB::beginTransaction + commit/rollback with try-catch | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | View uses `$type->name ?? '-'`, `$type->description ?? '-'` null coalescing; no undefined property errors | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — Redirect/JSON Response After CRUD | All CRUD actions return redirect with flash() or JSON response with success flag | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Usage Check Service Used In All Protected Methods | edit, update, destroy, restore, forceDelete all instantiate ExamTypeUsageCheckService | — | — | ◌ |

---

## 7. Detailed Test Steps

### 6.1 Positive TC Steps

#### TC-P01: Exam Types Tab Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Expand "Exam" from left sidebar | Menu options appear |
| 3 | Click "Masters" and select "Exam Types" tab | Page loads with `active_tab=exam_type` parameter |
| 4 | Check the search input | Search text field with placeholder "Search by code, name..." present |
| 5 | Check the is_active filter dropdown | Dropdown with All Status/Active/Inactive options present |
| 6 | Check the search button | Primary button with magnifying glass icon |
| 7 | Check the reset button | Secondary button with rotate-right icon |
| 8 | Check the table headers | Code, Name, Description, Active, Action columns present |
| 9 | Check the "Add Exam Type" button | Create button visible (if create permission) |

---

#### TC-P02: Search Exam Types By Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam types with codes: "UT-1", "UT-2", "HY-EXAM" | 3 exam types exist |
| 2 | Type "UT-1" in search box and click search | Form submits with `?search=UT-1&active_tab=exam_type` |
| 3 | Verify table shows only "UT-1" | Other 2 exam types not visible |
| 4 | Clear search and reset | All 3 exam types visible again |

---

#### TC-P03: Search Exam Types By Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam types: "Unit Test 1", "Unit Test 2", "Annual Exam" | 3 exam types exist |
| 2 | Type "Unit" in search box and click search | Page reloads with search filter |
| 3 | Verify table shows only "Unit Test 1" and "Unit Test 2" | "Annual Exam" not visible |
| 4 | Clear search | All 3 exam types visible again |

---

#### TC-P04: Search Exam Types By Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type with description "First unit examination" | Exam type exists |
| 2 | Create exam type with description "Second unit examination" | Exam type exists |
| 3 | Search "unit examination" | Both exam types appear |
| 4 | Search "Second" | Only second exam type appears |

---

#### TC-P05: Filter Exam Types By Active Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active exam type (is_active=1) and inactive exam type (is_active=0) | Both exist |
| 2 | Select "Active" from is_active filter | Only active exam type shown |
| 3 | Select "Inactive" from is_active filter | Only inactive exam type shown |
| 4 | Select "All Status" | Both exam types shown |

---

#### TC-P06: Create Exam Type With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Masters → Exam Types tab | Page loads |
| 2 | Click "Add Exam Type" button | Create form opens at /exam-type/create |
| 3 | Enter code: "UT-1" | Code field filled |
| 4 | Enter name: "Unit Test 1" | Name field filled |
| 5 | Ensure is_active toggle is checked | Switch is ON |
| 6 | Leave description empty | Optional field |
| 7 | Click "Create Exam Type" | POST to /exam-type/store |
| 8 | Redirect to masters tab with success message | Flash: "Exam type created successfully" |
| 9 | DB check: `SELECT * FROM lms_exam_types WHERE code='UT-1'` | Record exists; code='UT-1', name='Unit Test 1', is_active=1, description=NULL |

---

#### TC-P07: Create Exam Type With Optional Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill code: "ANNUAL-EXAM", name: "Annual Exam" | Required fields |
| 3 | Enter description: "Final annual examination for the academic year" | Description filled |
| 4 | Click "Create Exam Type" | POST to store |
| 5 | DB check: description column | "Final annual examination for the academic year" saved |

---

#### TC-P08: Create Exam Type With Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill code: "MOCK-1", name: "Mock Test 1" | Required fields |
| 3 | Uncheck "Exam Type Active" toggle | Switch OFF |
| 4 | Click "Create Exam Type" | POST to store |
| 5 | DB check: is_active | is_active=0 |

---

#### TC-P09: Edit Exam Type Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type: code="UT-1", name="Unit Test 1", description="First unit test", is_active=1 | Record exists with ID=X |
| 2 | Click "Edit" button on that row | Loads edit form at /exam-type/{id}/edit |
| 3 | Verify code pre-filled | "UT-1" |
| 4 | Verify name pre-filled | "Unit Test 1" |
| 5 | Verify description pre-filled | "First unit test" |
| 6 | Verify is_active checked | Toggle ON |

---

#### TC-P10: Update Exam Type Code And Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type: code="OLD-CODE", name="Old Name" | Record exists |
| 2 | Navigate to edit page | Form pre-filled |
| 3 | Change code to "NEW-CODE", name to "New Name" | Fields updated |
| 4 | Click "Update Exam Type" | PUT to /exam-type/{id}/update |
| 5 | Redirect with success | Flash: "Exam type updated successfully" |
| 6 | DB check: code="NEW-CODE", name="New Name" | Updated correctly |

---

#### TC-P11: Update Exam Type Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type with description="Old description" | Record exists |
| 2 | Edit: change description to "Updated description" | Field updated |
| 3 | Click "Update Exam Type" | Update succeeds |
| 4 | DB check: description | "Updated description" |

---

#### TC-P12: Update Exam Type Active Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type with is_active=1 | Record exists |
| 2 | Navigate to edit page | Form pre-filled |
| 3 | Uncheck "Exam Type Active" toggle | Switch OFF |
| 4 | Click "Update Exam Type" | Update succeeds |
| 5 | DB check: is_active | is_active=0 |

---

#### TC-P13: View Exam Type Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type with all fields | Record exists |
| 2 | Click "View" button on that row | Loads detail view at /exam-type/{id} |
| 3 | Check exam code displayed | Code shown in table |
| 4 | Check exam name displayed | Name shown |
| 5 | Check status badge | "Active" (green) or "Inactive" (red) badge |
| 6 | Check created_at | Formatted date/time |
| 7 | Check last updated | Formatted date/time |
| 8 | Check description | Description shown |

---

#### TC-P14: View Exam Type Usage Details (When Used)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type, then create an exam referencing that type via exam_type_id | Exam type is used |
| 2 | Navigate to show page for that exam type | Detail page loads |
| 3 | Check for warning alert | Warning alert with "Usage Details" heading |
| 4 | Check usage table | Shows "LmsExam" module, "Exams" row with count |
| 5 | Check exam list table | Shows exam code, title, status |
| 6 | Verify Edit button greyed out | Edit button has class "btn-secondary" with tooltip "Cannot edit - being used" |

---

#### TC-P15: View Exam Type Without Usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type with no referencing exams | Unused type |
| 2 | Navigate to show page | Detail page loads |
| 3 | Check no warning alert | No "Usage Details" section |
| 4 | Verify Edit button active | Edit button is clickable (btn-warning) |

---

#### TC-P16: Toggle Exam Type Status (Active to Inactive) via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type with is_active=1 | Record exists |
| 2 | Click status switch to turn OFF | AJAX POST to /exam-type/{id}/toggle-status |
| 3 | Check response | JSON {success: true, is_active: false, message: "Status updated successfully"} |
| 4 | DB check: is_active | is_active=0 |
| 5 | Check activity log | Entry with event 'Toggled' |

---

#### TC-P17: Toggle Exam Type Status (Inactive to Active) via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type with is_active=0 | Record exists |
| 2 | Click status switch to turn ON | AJAX POST |
| 3 | Check response | JSON {success: true, is_active: true} |
| 4 | DB check: is_active | is_active=1 |

---

#### TC-P18: Soft Delete Exam Type (Not Used)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type not used in any exam | Clean record |
| 2 | Click "Delete" button on that row | DELETE to /exam-type/{id}/destroy |
| 3 | Redirect to masters tab | Flash: "Exam type trashed successfully" |
| 4 | DB check: is_active=0, deleted_at IS NOT NULL | Soft deleted |
| 5 | DB check: record still exists | Not permanently deleted |
| 6 | Check activity log | 'Trashed' event logged |

---

#### TC-P19: View Trashed Exam Types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete an exam type | Soft-deleted record exists |
| 2 | Navigate to Trash view | /exam-type/trashed loads |
| 3 | Check table columns | #, Code, Name, Description, Status, Action |
| 4 | Check trashed record displayed | Shows deleted exam type with "Inactive" badge |
| 5 | Check action buttons | Restore and Force Delete buttons visible (with permissions) |

---

#### TC-P20: Restore Soft-Deleted Exam Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure exam type is soft-deleted | deleted_at IS NOT NULL |
| 2 | Click "Restore" button on trashed row | POST to /exam-type/{id}/restore |
| 3 | Redirect with success | Flash: "Exam type restored successfully" |
| 4 | DB check: is_active=1, deleted_at IS NULL | Restored and reactivated |
| 5 | Check activity log | 'Restored' event logged |

---

#### TC-P21: Force Delete Exam Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure exam type is soft-deleted | deleted_at IS NOT NULL |
| 2 | Click "Force Delete" button on trashed row | DELETE to /exam-type/{id}/forceDelete |
| 3 | Redirect with success | Flash: "Exam type permanently deleted" |
| 4 | DB check: record does not exist | Permanently removed |
| 5 | Check activity log | 'Deleted' event logged |

---

#### TC-P22: Full Lifecycle: Create → View → Toggle Inactive → Toggle Active → Edit → Delete → Restore → Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type with code="FULL-LIFECYCLE", name="Full Lifecycle Test" | Created successfully |
| 2 | View the created exam type | Detail page shows all fields |
| 3 | Toggle status to inactive | is_active becomes 0 |
| 4 | Toggle status back to active | is_active becomes 1 |
| 5 | Edit: change name to "Lifecycle Updated" | Updated successfully |
| 6 | Soft delete the exam type | Moved to trash |
| 7 | View trash page | Soft-deleted record visible |
| 8 | Restore the exam type | Restored and active |
| 9 | Soft delete again | Moved to trash |
| 10 | Force delete | Permanently removed |

---

#### TC-P23: Empty State — No Exam Types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no exam types exist in DB | Clean state |
| 2 | Navigate to Exam Types tab | Page loads |
| 3 | Check table body | Shows "No exam types found" message |
| 4 | Check Add button still visible | Create button present (if permission allows) |

---

#### TC-P24: Edit Button Disabled When Exam Type Is Used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type and exam referencing it | isUsed=true |
| 2 | Navigate to show page | Detail page loads |
| 3 | Check Edit button | Button has class "btn-secondary", tooltip "Cannot edit - being used" |
| 4 | Click greyed out button | No action triggered |

---

#### TC-P25: View-Only User Can See List But No Actions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with only tenant.exam-type.viewAny permission | Dashboard |
| 2 | Navigate to Exam Types tab | List loaded |
| 3 | Check Action column | No view/edit/delete buttons |
| 4 | Check Active column | No status toggle |
| 5 | Check Add button | Hidden |

---

#### TC-P26: Refresh Filters Resets Search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply search filter and is_active filter | Filtered results |
| 2 | Click reset (rotate-right) button | URL resets to base without query params |
| 3 | Check table | All exam types shown |

---

#### TC-P27: Trash Page Empty State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no trashed exam types exist | Clean trash |
| 2 | Navigate to trash page | /exam-type/trashed loads |
| 3 | Check table body | Shows "No Trashed Exam Types Found" |

---

### 6.2 Negative TC Steps

#### TC-N01: Required — Missing `code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Leave code blank; enter name="Test" | Code empty |
| 3 | Click "Create Exam Type" | Form submission fails |
| 4 | Check validation error | "Exam type code is required" shown |

---

#### TC-N02: Required — Missing `name`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter code="TEST"; leave name blank | Name empty |
| 3 | Click "Create Exam Type" | Validation error: "Exam type name is required" |

---

#### TC-N03: Duplicate `code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type with code="DUP-CODE" | First record exists |
| 2 | Try creating another exam type with same code "DUP-CODE" | Validation error: "This exam type code already exists" |
| 3 | Try DB-level INSERT with same code | Integrity constraint violation |

---

#### TC-N04: Max Length — Code > 50 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter code of 51 characters | Validation fails |
| 3 | Enter code of exactly 50 characters | Validation passes |

---

#### TC-N05: Max Length — Name > 100 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter name of 101 characters | Validation fails |
| 3 | Enter name of exactly 100 characters | Validation passes |

---

#### TC-N06: Max Length — Description > 255 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter description of 256 characters | Validation fails |
| 3 | Enter description of exactly 255 characters | Validation passes |

---

#### TC-N07: Edit Blocked When Exam Type Is Used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type and exam referencing it | isUsed=true |
| 2 | Navigate to /exam-type/{id}/edit | Redirected back with error |
| 3 | Check error message | "Cannot update this exam type because it is being used in exams." |

---

#### TC-N08: Update Blocked When Exam Type Is Used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have exam type with referencing exams | isUsed=true |
| 2 | Send PUT to /exam-type/{id}/update with valid data | Redirected back with error |
| 3 | Check error message | "Cannot update this exam type because it is being used in exams." |

---

#### TC-N09: Delete Blocked When Exam Type Is Used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have exam type with referencing exams | isUsed=true |
| 2 | Send DELETE to /exam-type/{id}/destroy | Redirected back with error |
| 3 | Check error message | "Cannot delete this exam type because it is being used in exams." |

---

#### TC-N10: Restore Blocked When Exam Type Is Used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete an exam type, then create exam referencing it | isUsed=true for deleted record |
| 2 | Send POST to /exam-type/{id}/restore | Redirected back with error |
| 3 | Check error message | "Cannot restore this exam type because it is being used in exams." |

---

#### TC-N11: Force Delete Blocked When Exam Type Is Used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete an exam type, then create exam referencing it | isUsed=true for deleted record |
| 2 | Send DELETE to /exam-type/{id}/forceDelete | Redirected back with error |
| 3 | Check error message | "Cannot permanently delete this exam type because it is being used in exams." |

---

#### TC-N12: View Exam Type With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to /exam-type/99999 (non-existent ID) | HTTP 404 error |
| 2 | Check error page | ModelNotFoundException rendered as 404 |

---

#### TC-N13 to TC-N17: Invalid ID Tests

| TC ID | Action | Expected Result |
|-------|--------|-----------------|
| TC-N13 | GET /exam-type/99999/edit | HTTP 404 |
| TC-N14 | PUT /exam-type/99999 | HTTP 404 |
| TC-N15 | DELETE /exam-type/99999/destroy | HTTP 404 |
| TC-N16 | POST /exam-type/99999/restore | HTTP 404 (onlyTrashed findOrFail) |
| TC-N17 | DELETE /exam-type/99999/forceDelete | HTTP 404 |

---

#### TC-N18: Toggle Status With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to /exam-type/99999/toggle-status with is_active=1 | JSON 500 |
| 2 | Check response | {success: false, message: "Failed to update status."} |

---

#### TC-N19: Toggle Status Without is_active Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to /exam-type/{id}/toggle-status without is_active | Validation error |
| 2 | Check response | JSON error: "The is active field is required." |

---

#### TC-N20: Toggle Status With Non-Boolean is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to /exam-type/{id}/toggle-status with is_active="string" | Validation fails |
| 2 | Check response | JSON error: "The is active field must be true or false." |

---

#### TC-N21: Permission 403 — No Exam Type Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with no exam-type permissions | Dashboard |
| 2 | Access GET /exam-type/index | 403 Forbidden |
| 3 | Access GET /exam-type/create | 403 Forbidden |
| 4 | Access POST /exam-type/store | 403 Forbidden |
| 5 | Access GET /exam-type/{id}/edit | 403 Forbidden |
| 6 | Access PUT /exam-type/{id} | 403 Forbidden |
| 7 | Access DELETE /exam-type/{id}/destroy | 403 Forbidden |
| 8 | Access POST /exam-type/{id}/toggle-status | 403 Forbidden |
| 9 | Access GET /exam-type/trashed | 403 Forbidden |
| 10 | Access POST /exam-type/{id}/restore | 403 Forbidden |
| 11 | Access DELETE /exam-type/{id}/forceDelete | 403 Forbidden |

---

#### TC-N22: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate to any exam type route | Redirect to /login |

---

#### TC-N23: XSS Injection In Code Or Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type with code="<script>alert('xss')</script>" | Stored as literal |
| 2 | Navigate to index tab | Blade escapes; text displayed literally |
| 3 | Navigate to show page | Text displayed literally; no script execution |

---

#### TC-N24: Whitespace-Only Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter code as spaces only | Code "string" validation passes but required catches |
| 3 | Click submit | Validation error: "Exam type code is required" (required rule) |

---

#### TC-N25: Create With Non-String Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST with code as array | Validation fails on code.string |
| 2 | Send POST with code as integer | Validation fails on code.string |

---

#### TC-N26: Update Code To Duplicate Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type A with code="CODE-A" | Exists |
| 2 | Create exam type B with code="CODE-B" | Exists |
| 3 | Edit exam type B, change code to "CODE-A" | Unique validation fails (ignoring B's own ID but A's code conflicts) |

---

#### TC-N27: Force Delete On Non-Trashed Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type (not deleted) | Exists |
| 2 | Send DELETE to /exam-type/{id}/forceDelete | Works (withTrashed finds record with null deleted_at) |
| 3 | DB check | Record permanently removed |

---

#### TC-N28: Restore Non-Trashed Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type (not deleted) | Exists |
| 2 | Send POST to /exam-type/{id}/restore | 404 (onlyTrashed does not find record) |

---

#### TC-N29: DB Error During Create — Transaction Rollback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate DB connection failure during store | Catch block executes |
| 2 | Verify DB::rollBack() called | Transaction rolled back |
| 3 | Verify redirect back with input and error | User returned to form with error message |

---

#### TC-N30: DB Error During Update — Transaction Rollback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate DB failure during update | Catch block executes |
| 2 | Verify DB::rollBack() called | Original data preserved |
| 3 | Verify redirect back with input and error | Error message shown |

---

### 6.3 Dependency TC Steps

#### TC-D01: Create Exam Type → Activity Logged

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type | store() succeeds |
| 2 | Query activity_logs table | Entry with event='Stored', message='A new exam type was created.', performed_by=user name |

---

#### TC-D02: Update Exam Type → Changes Tracked In Activity Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update exam type code from "OLD" to "NEW" | update() succeeds |
| 2 | Query activity_logs table | Entry with event='Updated', message contains JSON changes: code{old:"OLD", new:"NEW"} |

---

#### TC-D03: Delete Exam Type → Is_Active Set False Before Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete exam type | destroy() succeeds |
| 2 | Query lms_exam_types with trashed | Record has is_active=0 AND deleted_at IS NOT NULL |

---

#### TC-D04: Restore Exam Type → Is_Active Set True After Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore soft-deleted exam type | restore() succeeds |
| 2 | Query lms_exam_types | Record has is_active=1 AND deleted_at IS NULL |

---

#### TC-D05: Usage Check Blocks Edit — Exam References Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type with ID=1 | Record exists |
| 2 | Create exam with exam_type_id=1 | Reference exists |
| 3 | Try to edit exam type ID=1 | isUsed returns true; redirect with error |

---

#### TC-D06: Usage Check Blocks Delete — Exam References Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have exam referencing exam type | isUsed=true |
| 2 | Try to delete exam type | Blocked; error returned |

---

#### TC-D07: Toggle Status Returns JSON — Frontend Handles Response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle status via AJAX | JSON response received |
| 2 | Check response structure | {success: bool, is_active: bool, message: string} |
| 3 | Check frontend toast | Success/error toast displayed |

---

#### TC-D08: Transaction Rollback On Store Exception

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force DB exception during store | Catch block runs |
| 2 | Verify no record created | DB rollback prevents partial insert |
| 3 | Verify user redirected back with input | Old input preserved in form |

---

#### TC-D09: ExamTypePolicy — All Gates Coverage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamTypePolicy.php | File found in Modules/LmsExam/Policies/ |
| 2 | Scan all methods | viewAny, view, create, update, delete, restore, forceDelete, status, import, export, print — 11 gates |
| 3 | Verify each returns $user->can('tenant.exam-type.*') | All return proper permission checks |

---

#### TC-D10: ExamTypeRequest — authorize() Matches HTTP Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST request | authorize() checks tenant.exam-type.create |
| 2 | PUT/PATCH request | Checks tenant.exam-type.update |
| 3 | DELETE request | Checks tenant.exam-type.delete |
| 4 | GET request | Checks tenant.exam-type.view (fallback) |

---

#### TC-D11: Unique Code Constraint At DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | INSERT directly with duplicate code | Integrity constraint violation: Duplicate entry for key 'uq_exam_type_code' |

---

#### TC-D12: SoftDeletes Trait — onlyTrashed/withTrashed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete exam type | Soft deleted |
| 2 | ExamType::onlyTrashed()->get() | Returns only deleted records |
| 3 | ExamType::withTrashed()->get() | Returns all including deleted |
| 4 | ExamType::all() | Excludes deleted (default) |

---

#### TC-D13: ExamType Model — $casts Boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Query exam type | $examType->is_active returns boolean (true/false) |
| 2 | DB stores 0 or 1 | TINYINT(1) in DB |
| 3 | Set is_active = true | DB stores 1 |

---

#### TC-D14: ExamType Model — hasMany Exams Relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type with exams | $examType->exams returns collection |
| 2 | $examType->exams()->count() | Matches Exam::where('exam_type_id', $id)->count() |

---

#### TC-D15: ExamType Model — scopeActive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | ExamType::active()->get() | Returns only records with is_active=1 |

---

#### TC-D16: Controller — findOrFail — Valid and Invalid IDs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access with valid ID | Model loaded |
| 2 | Access with invalid (non-existent) ID | ModelNotFoundException → HTTP 404 |

---

#### TC-D17: Controller — Gate::authorize — Authorization Before CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index() | Gate::authorize('tenant.exam-type.viewAny') called |
| 2 | Inspect create() | Gate::authorize('tenant.exam-type.create') called |
| 3 | Inspect store() | Gate::authorize('tenant.exam-type.create') called |
| 4 | Inspect show() | Gate::authorize('tenant.exam-type.view') called |
| 5 | Inspect edit() | Gate::authorize('tenant.exam-type.update') called |
| 6 | Inspect update() | Gate::authorize('tenant.exam-type.update') called |
| 7 | Inspect destroy() | Gate::authorize('tenant.exam-type.delete') called |
| 8 | Inspect trashed() | Gate::authorize('tenant.exam-type.restore') called |
| 9 | Inspect restore() | Gate::authorize('tenant.exam-type.restore') called |
| 10 | Inspect forceDelete() | Gate::authorize('tenant.exam-type.forceDelete') called |
| 11 | Inspect toggleStatus() | Gate::authorize('tenant.exam-type.update') called |

---

#### TC-D18: Controller — activityLog — Activity Logged After CRUD Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type | 'Stored' event logged |
| 2 | Update exam type | 'Updated' event logged |
| 3 | Soft delete | 'Trashed' event logged |
| 4 | Restore | 'Restored' event logged |
| 5 | Force delete | 'Deleted' event logged |
| 6 | Toggle status | 'Toggled' event logged |

---

#### TC-D19: Controller — DB Transactions in All Write Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() | DB::beginTransaction → try → commit/rollback |
| 2 | Inspect update() | DB::beginTransaction → try → commit/rollback |
| 3 | Inspect destroy() | DB::beginTransaction → try → commit/rollback |
| 4 | Inspect restore() | DB::beginTransaction → try → commit/rollback |
| 5 | Inspect forceDelete() | DB::beginTransaction → try → commit/rollback |
| 6 | Inspect toggleStatus() | DB::beginTransaction → try → commit/rollback |

---

#### TC-D20: Routes — Resourceful Routes + Custom Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check route:list | All routes map to correct controller methods |
| 2 | Verify custom routes: trashed, restore, forceDelete, toggle-status | Present with correct HTTP verbs |
| 3 | Verify auth middleware | All routes have auth guard |

---

#### TC-D21: Blade @can Directives — Permission-based Visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php for status switch | @canany(['tenant.exam-type.status']) wraps Active column |
| 2 | Inspect for action column | @canany(['tenant.exam-type.view', 'tenant.exam-type.update', 'tenant.exam-type.delete']) wraps Action |
| 3 | Inspect trash.blade.php for action | @canany(['tenant.exam-type.restore', 'tenant.exam-type.forceDelete']) wraps action |
| 4 | Inspect show.blade.php for edit button | @can('tenant.exam-type.edit') wraps Edit button |

---

#### TC-D22: Breadcrumb Config — Route Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open breadcrumb config | File contains entry for exam type routes |
| 2 | Load exam type screen | Breadcrumb trail shows correct hierarchy |

---

#### TC-D23: View — isset()/null-safe Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php | Uses `$type->code ?? '-'`, `$type->name ?? '-'` null coalescing |
| 2 | Inspect show.blade.php | Uses `$examType->created_at?->format(...)` null-safe |
| 3 | Load index with null description | Renders dash; no error |

---

#### TC-D24: Controller — Redirect With Flash Messages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type | Redirect with session('success') = flash('created.exam-type') |
| 2 | Update exam type | Redirect with session('success') = flash('updated.exam-type') |
| 3 | Delete exam type | Redirect with session('success') = flash('trashed.exam-type') |
| 4 | Restore exam type | Redirect with session('success') = flash('restored.exam-type') |
| 5 | Force delete | Redirect with session('success') = flash('force_deleted.exam-type') |

---

#### TC-D25: ExamTypeUsageCheckService — getUsageDetails Returns Array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check used type | Returns ['Exams' => N, 'Active Exams' => M] |
| 2 | Check unused type | Returns [] empty array |

---

#### TC-D26: ExamTypeUsageCheckService — getUsageMessage Returns String

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Used type with 3 exams | Returns 'This exam type is used in: 3 exam(s).' |
| 2 | Unused type | Returns '' empty string |

---

#### TC-D27: ExamTypeUsageCheckService — getExams Returns Collection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call with valid type ID | Returns Collection of Exam records |

---

#### TC-D28: FormRequest prepareForValidation Converts is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit form with checkbox checked | $this->boolean('is_active') returns true |
| 2 | Submit form with checkbox unchecked | $this->boolean('is_active') returns false |

---

#### TC-D29: Cascade RESTRICT — Cannot Delete Exam Type While Exams Reference

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with exam_type_id=X | FK constraint active |
| 2 | Try to DB-level DELETE from lms_exam_types WHERE id=X | FK constraint violation (RESTRICT) |
| 3 | Controller blocks before DB | UsageCheckService blocks with user-friendly message |

---

#### TC-D30: ToggleStatus Returns 500 On Exception

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force exception during toggle | Catch block executes |
| 2 | Check response | JSON {success: false, message: "Failed to update status."} with status 500 |

---

### 6.4 Code Review TC Steps

#### TC-CR01: Blade @can Directives — Permission-based Visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php for create button | @can handled by x-backend.tab.search-bar component |
| 2 | Inspect status switch column | @canany(['tenant.exam-type.status']) wraps the column |
| 3 | Inspect action column | @canany(['tenant.exam-type.view', 'tenant.exam-type.update', 'tenant.exam-type.delete']) wraps action |
| 4 | Inspect trash.blade.php | @canany(['tenant.exam-type.restore', 'tenant.exam-type.forceDelete']) wraps action |
| 5 | Inspect show.blade.php | @can('tenant.exam-type.edit') wraps Edit button; additional check on !$isUsed |
| 6 | Login as user with all permissions | All buttons visible and functional |
| 7 | Login as user with viewAny only | No create/edit/delete buttons visible |

#### TC-CR02: Breadcrumb Config — Route Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open breadcrumb config file | File contains routing configuration |
| 2 | Verify exam type route entries | Present for create, edit, show pages |
| 3 | Load create/edit/show screen | Breadcrumb trail shows correct hierarchy |

#### TC-CR04: Controller — DB Transactions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamTypeController.php | Controller found |
| 2 | Inspect store() method | DB::beginTransaction wraps create; commit on success, rollback on exception |
| 3 | Inspect update() method | DB::beginTransaction before write + try-catch with rollback/commit |
| 4 | Inspect destroy() method | DB::beginTransaction wraps is_active=false, save, delete |
| 5 | Inspect restore() method | DB::beginTransaction wraps restore, is_active=true, save |
| 6 | Inspect forceDelete() method | DB::beginTransaction wraps forceDelete; commit on success, rollback on exception |
| 7 | Inspect toggleStatus() method | DB::beginTransaction wraps save; commit/rollback on condition |
| 8 | Simulate DB failure during any operation | Transaction rolled back; no partial state |

#### TC-CR05: View — isset()/null-safe Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open index.blade.php | All expressions use `??` null coalescing or `->` nullable |
| 2 | Open show.blade.php | Uses `$examType->created_at?->format(...)` null-safe operator |
| 3 | Open trash.blade.php | Uses `Str::limit($examType->description, 50) ?? '—'` |
| 4 | Create record with null description | View renders gracefully |
| 5 | Load index with records that have missing relations | No 500 errors; null values displayed as dash |

#### TC-CR06: Controller — Response After CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam type | Redirect to masters tab with session success flash |
| 2 | Verify flash message | 'created.exam-type' translation key |
| 3 | Toggle status via AJAX | JSON response with success: true/false |
| 4 | Trigger validation error | Redirect back with input and error flash |
| 5 | Trigger exception | Redirect back with error flash; transaction rolled back |

#### TC-CR07: Usage Check Service In All Protected Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamTypeController.php | File found |
| 2 | Inspect edit() | Instantiate ExamTypeUsageCheckService, call isUsed($id) at top |
| 3 | Inspect update() | Instantiate ExamTypeUsageCheckService, call isUsed($id) at top |
| 4 | Inspect destroy() | Instantiate ExamTypeUsageCheckService, call isUsed($id) |
| 5 | Inspect restore() | Instantiate ExamTypeUsageCheckService, call isUsed($id) |
| 6 | Inspect forceDelete() | Instantiate ExamTypeUsageCheckService, call isUsed($id) |
| 7 | Verify show() also uses service | show() passes usage data to view |
| 8 | Verify all 5 methods block when isUsed() returns true | Each returns back with error message |