# slb_performance_categories_TcList

## Module: Syllabus → Syllabus Master → Performance Categories

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Syllabus Master |
| Feature | Performance Categories |
| URL(s) | `/syllabus/master` (index via tab), `/syllabus/performance-category/create` (create), `/syllabus/performance-category/store` (store), `/syllabus/performance-category/{id}` (show), `/syllabus/performance-category/{id}/edit` (edit), `/syllabus/performance-category/{id}/update` (update), `/syllabus/performance-category/{id}/destroy` (destroy), `/syllabus/performance-category/{id}/restore` (restore), `/syllabus/performance-category/{id}/force-delete` (forceDelete), `/syllabus/performance-category/trash/view` (trash), `/syllabus/performance-category/toggle-status/{id}` (toggleStatus) |
| Controller | `Modules\Syllabus\Http\Controllers\PerformanceCategoryController` |
| Model(s) | `Modules\Syllabus\Models\PerformanceCategory` |
| Validation (Create) | `Modules\Syllabus\Http\Requests\PerformanceCategoryRequest` |
| Validation (Update) | `Modules\Syllabus\Http\Requests\PerformanceCategoryRequest` |
| Permissions | `tenant.performance-category.viewAny`, `tenant.performance-category.view`, `tenant.performance-category.create`, `tenant.performance-category.update`, `tenant.performance-category.delete`, `tenant.performance-category.restore`, `tenant.performance-category.forceDelete` |
| Soft Deletes | Yes (`PerformanceCategory` uses `SoftDeletes` trait) |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |
| Pagination | 10 per page |
| System-Defined Guard | `is_system_defined` records protected from edit/delete/toggle |
| Range Overlap Check | Custom after-validation checks overlapping percentage ranges |

---

## 2. Pre-conditions

- Required permissions: `tenant.performance-category.viewAny`, `tenant.performance-category.view`, `tenant.performance-category.create`, `tenant.performance-category.update`, `tenant.performance-category.delete`, `tenant.performance-category.restore`, `tenant.performance-category.forceDelete`
- Required seed data: At least one active `SchoolClass` (for scope=CLASS tests)
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For overlap tests: At least one existing performance category with defined percentage range
- For system-defined tests: At least one record with `is_system_defined = true`

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
| Performance Categories Grid | getPerformanceCategories() | PerformanceCategory | search(name,code), filters(level,scope,ai_severity,status) | 10/page (performance_categories_page) |
## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Code**: Uppercase (via `strtoupper()` in `prepareForValidation()`), unique scoped by `scope`
- **Name**: String max 100
- **Level**: TinyInt, 1-255
- **Percentage range**: `min_percentage` 0-100, `max_percentage` 0-100, `max > min`
- **Code prefix**: `PC_` + uniqueSuffix for test data
- **Pre-test cleanup**: Delete created categories by code before/after tests
- **Range overlap**: After-validation checks `min_percentage <= max_existing AND max_percentage >= min_existing` within same scope
- **Scope**: Either SCHOOL or CLASS (string enum)
- **System-defined**: Boolean flag; if true, record is protected

---

## 5. Business Conditions

### 4.1 Database Schema -- `slb_performance_categories`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT PK | Auto-increment |
| BC-DB-02 | code | VARCHAR(20) | NOT NULL, UNIQUE scoped by `scope` |
| BC-DB-03 | name | VARCHAR(100) | NOT NULL |
| BC-DB-04 | level | TINYINT | NOT NULL |
| BC-DB-05 | min_percentage | DECIMAL(5,2) | NOT NULL |
| BC-DB-06 | max_percentage | DECIMAL(5,2) | NOT NULL |
| BC-DB-07 | ai_severity | ENUM('LOW','MEDIUM','HIGH','CRITICAL') | DEFAULT 'LOW' |
| BC-DB-08 | ai_default_action | ENUM('ACCELERATE','PROGRESS','PRACTICE','REMEDIATE','ESCALATE') | NOT NULL |
| BC-DB-09 | display_order | SMALLINT | DEFAULT 1 |
| BC-DB-10 | color_code | VARCHAR(10) | DEFAULT NULL |
| BC-DB-11 | icon_code | VARCHAR(50) | DEFAULT NULL |
| BC-DB-12 | scope | ENUM('SCHOOL','CLASS') | NOT NULL |
| BC-DB-13 | class_id | BIGINT FK | NULLABLE, FK → `sch_classes.id` |
| BC-DB-14 | is_system_defined | TINYINT(1) | DEFAULT 0 |
| BC-DB-15 | auto_retest_required | TINYINT(1) | DEFAULT 0 |
| BC-DB-16 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-17 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-18 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-19 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules -- `PerformanceCategoryRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | code | required, string, max:20, unique scoped by `scope` | "Performance category code is required." / "This performance category code already exists for the selected scope." |
| BC-VAL-02 | name | required, string, max:100 | -- |
| BC-VAL-03 | description | nullable, string, max:255 | -- |
| BC-VAL-04 | level | required, integer, min:1, max:255 | -- |
| BC-VAL-05 | min_percentage | required, numeric, min:0, max:100 | -- |
| BC-VAL-06 | max_percentage | required, numeric, min:0, max:100, gt:min_percentage | "Maximum percentage must be greater than minimum percentage." |
| BC-VAL-07 | ai_severity | nullable, in:LOW,MEDIUM,HIGH,CRITICAL | -- |
| BC-VAL-08 | ai_default_action | required, in:ACCELERATE,PROGRESS,PRACTICE,REMEDIATE,ESCALATE | -- |
| BC-VAL-09 | display_order | nullable, integer, min:1, max:65535 | -- |
| BC-VAL-10 | color_code | nullable, string, max:10 | -- |
| BC-VAL-11 | icon_code | nullable, string, max:50 | -- |
| BC-VAL-12 | scope | required, in:SCHOOL,CLASS | -- |
| BC-VAL-13 | class_id | nullable, required_if:scope,CLASS | "Class is required when scope is CLASS." |
| BC-VAL-14 | is_system_defined | nullable, boolean | -- |
| BC-VAL-15 | auto_retest_required | nullable, boolean | -- |
| BC-VAL-16 | **Range overlap (after-validation)** | Custom check: no overlap with existing active records in same scope | "The percentage range overlaps with an existing active performance category." |

### 4.3 Validation Rules -- `PerformanceCategoryRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | code | unique scoped + ignore given ID | "This performance category code already exists for the selected scope." |
| BC-VAL-U02 | max_percentage | gt:min_percentage + unique scoped | "Maximum percentage must be greater than minimum percentage." |
| BC-VAL-U03 | Range overlap (after-validation) | Same scope overlap check | "The percentage range overlaps with an existing active performance category." |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.performance-category.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.performance-category.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.performance-category.create | create(), store() | Without → 403 |
| BC-AUTH-04 | tenant.performance-category.update | edit(), update() | Without → 403 |
| BC-AUTH-05 | tenant.performance-category.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.performance-category.restore | restore(), trashed() | Without → 403 |
| BC-AUTH-07 | tenant.performance-category.forceDelete | forceDelete() | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Code uppercase | `strtoupper()` applied in `prepareForValidation()` |
| BC-BIZ-02 | Range overlap prevention | After-validation checks `min <= existing_max AND max >= existing_min` within same scope |
| BC-BIZ-03 | System-defined guard -- edit | `is_system_defined = true` → update blocked with 403 |
| BC-BIZ-04 | System-defined guard -- delete | `is_system_defined = true` → delete blocked with 403 |
| BC-BIZ-05 | System-defined guard -- toggle | `is_system_defined = true` → toggle blocked with 403 |
| BC-BIZ-06 | Soft delete | `destroy()` sets `is_active = false`, then calls `delete()` |
| BC-BIZ-07 | Scope precedence | CLASS scope rule takes priority over SCHOOL scope for same class |
| BC-BIZ-08 | Show with trashed | `show()` uses `withTrashed()->findOrFail()` |
| BC-BIZ-09 | Default ai_severity | Defaults to 'LOW' when not provided |
| BC-BIZ-10 | Default display_order | Defaults to 1 when not provided |
| BC-BIZ-11 | Activity logging | Stored, Updated, Trashed, Restored, Deleted, Toggled all logged |
| BC-BIZ-12 | Screen loads via SyllabusController@master() at GET /syllabus/master with master tab group | Navigating to GET /syllabus/master with appropriate permissions loads the Master tab group; this screen's grid data is fetched and displayed |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | class_id | sch_classes (id) | Not declared (nullable FK) |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Performance Categories Page Loads | Page loads with filter, search, Add Category button, paginated table | -- | -- | ⬜ |
| TC-P02 | Create Performance Category With All Required Fields | Category created with code, name, level, min/max percentage, AI action, scope | -- | -- | ⬜ |
| TC-P03 | Create Category With All Optional Fields | Description, AI severity, display order, color code, icon code, auto retest all saved | -- | -- | ⬜ |
| TC-P04 | Create Category With Scope=SCHOOL | Category applies school-wide; no class_id required | -- | -- | ⬜ |
| TC-P05 | Create Category With Scope=CLASS (With Class) | Category applies to specific class; class_id saved | -- | -- | ⬜ |
| TC-P06 | Create Category With AI Severity = CRITICAL | ai_severity = 'CRITICAL' saved | -- | -- | ⬜ |
| TC-P07 | Create Category With AI Action = ESCALATE | ai_default_action = 'ESCALATE' saved | -- | -- | ⬜ |
| TC-P08 | Create Category With Auto Retest Required | auto_retest_required = 1; system auto-assigns remedial test | -- | -- | ⬜ |
| TC-P09 | Create Category With Specific Display Order | display_order set to user-defined value | -- | -- | ⬜ |
| TC-P10 | Create Category With Color Code | color_code saved (e.g. "#FF0000") | -- | -- | ⬜ |
| TC-P11 | Edit Category Loads Pre-Filled Data | Edit form shows existing category data | -- | -- | ⬜ |
| TC-P12 | Update Category Name, Code, Range | Name, code, min/max percentage updated; range overlap check passes | -- | -- | ⬜ |
| TC-P13 | Update Category AI Severity/Action | ai_severity and ai_default_action changed | -- | -- | ⬜ |
| TC-P14 | View Category Details Page | Details shown with all field values | -- | -- | ⬜ |
| TC-P15 | Soft Delete Category (Non-System) | `deleted_at` set; is_active=false; category hidden | -- | -- | ⬜ |
| TC-P16 | Trash Page Shows Deleted Categories | Trash paginated list with restore + force delete | -- | -- | ⬜ |
| TC-P17 | Restore Category From Trash | `deleted_at` = NULL; visible again; activity "Restored" | -- | -- | ⬜ |
| TC-P18 | Force Delete Category (Permanent) | Record permanently removed; activity "Deleted" | -- | -- | ⬜ |
| TC-P19 | Toggle Status Active ↔ Inactive | `is_active` flips; JSON 200 with success and new state | -- | -- | ⬜ |
| TC-P20 | Empty State -- No Categories | Table shows "No performance categories found" message | -- | -- | ⬜ |
| TC-P21 | Change Scope From SCHOOL to CLASS (With Class) | Scope updated; class_id required and saved | -- | -- | ⬜ |
| TC-P22 | Create Category With Percentage Boundaries (0% and 100%) | min=0.00, max=100.00 allowed (boundary values) | -- | -- | ⬜ |
| TC-P23 | ai_severity Defaults to LOW | ai_severity = 'LOW' when not provided (default behavior) | -- | -- | ⬜ |
| TC-P24 | display_order Defaults to 1 | display_order = 1 when not provided (default behavior) | -- | -- | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required -- Missing `code` | "Performance category code is required." | -- | -- | ⬜ |
| TC-N02 | Required -- Missing `name` | Validation error: "The name field is required." | -- | -- | ⬜ |
| TC-N03 | Required -- Missing `level` | Validation error: "The level field is required." | -- | -- | ⬜ |
| TC-N04 | Required -- Missing `min_percentage` | Validation error: "The min percentage field is required." | -- | -- | ⬜ |
| TC-N05 | Required -- Missing `max_percentage` | Validation error: "The max percentage field is required." | -- | -- | ⬜ |
| TC-N06 | Required -- Missing `ai_default_action` | Validation error: "The ai default action field is required." | -- | -- | ⬜ |
| TC-N07 | Required -- Missing `scope` | Validation error: "The scope field is required." | -- | -- | ⬜ |
| TC-N08 | Duplicate Code Within Same Scope | "This performance category code already exists for the selected scope." | -- | -- | ⬜ |
| TC-N09 | Same Code Allowed For Different Scope | Same code works for SCHOOL vs CLASS scopes | -- | -- | ⬜ |
| TC-N10 | Max Length -- Code > 20 Characters | Validation fails on code.max | -- | -- | ⬜ |
| TC-N11 | Max Length -- Name > 100 Characters | Validation fails on name.max | -- | -- | ⬜ |
| TC-N12 | Invalid `level` -- 0 or Negative | `level.min` validation (must be >= 1) | -- | -- | ⬜ |
| TC-N13 | Invalid `min_percentage` -- Negative | `min_percentage.min` validation (must be >= 0) | -- | -- | ⬜ |
| TC-N14 | Invalid `max_percentage` -- > 100 | `max_percentage.max` validation (must be <= 100) | -- | -- | ⬜ |
| TC-N15 | Max Percentage <= Min Percentage | "Maximum percentage must be greater than minimum percentage." | -- | -- | ⬜ |
| TC-N16 | Range Overlap With Existing Active Record (Same Scope) | "The percentage range overlaps with an existing active performance category." | -- | -- | ⬜ |
| TC-N17 | Scope=CLASS Without Class ID | "Class is required when scope is CLASS." | -- | -- | ⬜ |
| TC-N18 | Invalid AI Severity Value | `ai_severity.in` validation (must be LOW/MEDIUM/HIGH/CRITICAL) | -- | -- | ⬜ |
| TC-N19 | Invalid AI Default Action Value | `ai_default_action.in` validation | -- | -- | ⬜ |
| TC-N20 | Edit System-Defined Category (403) | "System-defined question types cannot be modified." | -- | -- | ⬜ |
| TC-N21 | Delete System-Defined Category (403) | "System-defined question types cannot be deleted." | -- | -- | ⬜ |
| TC-N22 | Toggle Status On System-Defined Category (403) | "System-defined question types status cannot be changed." | -- | -- | ⬜ |
| TC-N23 | View Category With Invalid ID (404) | 404 error: Model not found | -- | -- | ⬜ |
| TC-N24 | Edit/Update With Invalid ID (404) | 404 error: Model not found | -- | -- | ⬜ |
| TC-N25 | Permission 403 -- No Performance Category Permissions | 403 Forbidden on all endpoints | -- | -- | ⬜ |
| TC-N26 | Guest Access Redirect | Redirected to /login | -- | -- | ⬜ |
| TC-N27 | Force Delete Non-Trashed Category | `onlyTrashed()->find()` returns null → 404 | -- | -- | ⬜ |
| TC-N28 | Restore Non-Deleted Category | `onlyTrashed()->find()` returns null → 404 | -- | -- | ⬜ |
| TC-N29 | Max Length — description > 255 Characters | Validation fails on description.max | -- | -- | ⬜ |
| TC-N30 | Max Length — level > 255 | Validation fails on level.max | -- | -- | ⬜ |
| TC-N31 | Invalid display_order — Below 1 or Above 65535 | Validation fails on display_order.min or display_order.max | -- | -- | ⬜ |
| TC-N32 | Max Length — color_code > 10 Characters | Validation fails on color_code.max | -- | -- | ⬜ |
| TC-N33 | Max Length — icon_code > 50 Characters | Validation fails on icon_code.max | -- | -- | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Range Overlap -- Exact Same Range Rejected | Creating 0-100 when 0-100 exists → overlap error | -- | -- | ⬜ |
| TC-D02 | A | Range Overlap -- Partial Overlap Rejected | Creating 30-60 when 20-50 exists → overlap error | -- | -- | ⬜ |
| TC-D03 | B | Range Overlap -- Contained Range Rejected | Creating 40-50 when 30-60 exists → overlap error | -- | -- | ⬜ |
| TC-D04 | C | Range Non-Overlap -- Adjacent Ranges Allowed | Creating 50-100 when 0-49.99 exists → allowed (adjacent, non-overlapping) | -- | -- | ⬜ |
| TC-D05 | C | Range Non-Overlap -- Gap Between Ranges Allowed | Creating 60-100 when 0-30 exists → allowed (gap 30-60) | -- | -- | ⬜ |
| TC-D06 | D | Scope=CLASS Overlap Only Within Same Class | Same range allowed for CLASS A and CLASS B (different classes) | -- | -- | ⬜ |
| TC-D07 | E | System-Defined Record -- View Allowed But No Edit | View works; update/delete/toggle all blocked | -- | -- | ⬜ |
| TC-D08 | F | Soft Delete Only Sets `is_active=false` First | `destroy()` sets `is_active=0` before `delete()` | -- | -- | ⬜ |
| TC-D09 | G | Inactive Category Not Checked For Overlap | Overlap check only considers active records; inactive ranges ignored | -- | -- | ⬜ |
| TC-D10 | H | Activity Log -- All Events Tracked | Stored, Updated, Trashed, Restored, Deleted, Toggled all logged | -- | -- | ⬜ |
| TC-D11 | I | slb_performance_categories with min_percentage=80, max_percentage=90 — CHECK Constraint — min_percentage < max_percentage | Insert with min_percentage >= max_percentage throws CHECK constraint violation; valid range saves successfully | -- | -- | ⬜ |
| TC-D12 | J | Existing performance categories with ranges 0-40, 41-70, 71-100 — Overlapping Range Validation — Application Layer | Attempting to create a category with range that overlaps existing range (e.g., 30-50) returns validation error; non-overlapping range succeeds | -- | -- | ⬜ |
| TC-D13 | K | slb_performance_categories with is_system_defined=1 — System-Protected Record — is_system_defined Restriction | System-defined records (is_system_defined=1) cannot be edited or deleted by school users; only viewable | -- | -- | ⬜ |
| TC-D14 | L | slb_performance_categories form open — ENUM Field Validation — ai_severity, ai_default_action, scope | Invalid values for ai_severity (not LOW/MEDIUM/HIGH/CRITICAL), ai_default_action (not ACCELERATE/PROGRESS/PRACTICE/REMEDIATE/ESCALATE), or scope (not SCHOOL/CLASS) are rejected by validation | -- | -- | ⬜ |
| TC-D15 | M | slb_performance_categories with active record — Composite Unique Constraint — uq_perf_code (code + scope) | Inserting duplicate (code, scope) combination directly at DB level throws integrity constraint violation | -- | -- | ⬜ |
| TC-D16 | N | Model — `$fillable` Array Protection | Only `code`, `name`, `description`, `min_value`, `max_value`, `is_active` are mass-assignable; any other attribute is guarded | -- | -- | ⬜ |
| TC-D17 | N | Model — `$casts` Configuration | `is_active` cast to `boolean`, `min_value` cast to `decimal:2`, `max_value` cast to `decimal:2` | -- | -- | ⬜ |
| TC-D18 | N | Model — `SoftDeletes` Trait | Model imports and uses `Illuminate\Database\Eloquent\SoftDeletes`; `deleted_at` column present in migration | -- | -- | ⬜ |
| TC-D19 | O | Controller — CRUD Methods Present | `index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()` all defined with correct signatures | -- | -- | ⬜ |
| TC-D20 | O | Controller — Gate Authorization On Each Method | Each CRUD method calls `Gate::authorize('tenant.performance-category.*')` with correct permission constant before execution | -- | -- | ⬜ |
| TC-D21 | O | Controller — Activity Log Events | Stored, Updated, Trashed, Restored, Deleted, Toggled events all recorded via `activityLog` facade after each mutation | -- | -- | ⬜ |
| TC-D22 | P | Controller — `is_active = false` Before `delete()` | `destroy()` method sets `is_active = false` via `update(['is_active' => false])` before calling `delete()` | -- | -- | ⬜ |
| TC-D23 | Q | Request — Validation Rules (Create) | `code`: required, string, max:20, unique:slb_performance_categories; `name`: required, max:100; `description`: nullable, max:255; `min_value`: nullable, numeric; `max_value`: nullable, numeric; `is_active`: nullable, boolean | -- | -- | ⬜ |
| TC-D24 | Q | Request — Validation Rules (Update) | Same as create but `code` unique rule ignores current record ID via `ignore($this->route('performance_category'))` | -- | -- | ⬜ |
| TC-D25 | R | Policy — All Gate Methods Defined | `viewAny()`, `view()`, `create()`, `update()`, `delete()`, `restore()`, `forceDelete()`, `status()` all implemented with proper permission checks | -- | -- | ⬜ |
| TC-D26 | S | Routes — Resource Routes | `Route::resource('performance-category', PerformanceCategoryController::class)` registered with correct controller namespace | -- | -- | ⬜ |
| TC-D27 | S | Routes — Additional Routes | `GET /trash/view` (trashed), `POST /{id}/restore` (restore), `DELETE /{id}/force-delete` (forceDelete), `POST /toggle-status/{id}` (toggleStatus) defined | -- | -- | ⬜ |
| TC-D28 | T | Controller — `toggleStatus()` Logic | Flips `is_active` from true→false or false→true; returns JSON `{success: true, is_active: <new_state>}`; blocked for system-defined records | -- | -- | ⬜ |
| TC-D29 | T | Controller — Trashed/Restore/ForceDelete Flow | `trashed()` uses `onlyTrashed()->paginate()`; `restore()` calls `restore()` + logs; `forceDelete()` calls `forceDelete()` + logs + 404 if not trashed | -- | -- | ⬜ |
| TC-D30 | U | Model — `is_active` Boolean Scoping | Queries filtering by active records use `where('is_active', true)`; inactive records excluded from index/overlap checks | -- | -- | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.performance-category.create'), @can('tenant.performance-category.edit'), @can('tenant.performance-category.delete'), @can('tenant.performance-category.status'), @can('tenant.performance-category.view'), @canany(['tenant.performance-category.restore', 'tenant.performance-category.forceDelete']) for access control on all CRUD buttons and actions | — | — | ◌ |
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
| 1 | Inspect index.blade.php for add/create button | @can('tenant.performance-category.create') wraps the Add New button; user without create permission does not see it
| 2 | Inspect row-level action buttons (view, edit, delete, status toggle) | @can('tenant.performance-category.view'), @can('tenant.performance-category.edit'), @can('tenant.performance-category.delete'), @can('tenant.performance-category.status') used appropriately; expired permissions hide corresponding buttons
| 3 | Inspect trash.blade.php for restore/forceDelete buttons | @canany(['tenant.performance-category.restore', 'tenant.performance-category.forceDelete']) wraps action buttons in trash view
| 4 | Inspect view.blade.php for edit button | @can('tenant.performance-category.edit') wraps the Edit button on show/details page
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

#### TC-P01: Performance Categories Page Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Expand "Syllabus" → "Syllabus Master" → "Performance Categories" tab | Page loads at `tab=performance_categories` |
| 3 | Check filter/search | Filter dropdowns and search input present |
| 4 | Check "Add New" button | Visible |
| 5 | Check categories table | Columns: Code, Name, Level, Range, AI Severity, AI Action, Scope, Status, Actions |
| 6 | Check pagination | If 10+ records exist, pagination links appear |

---

#### TC-P02: Create Performance Category With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Performance Categories tab | Page loads |
| 2 | Click "Add New" button | Create form opens |
| 3 | Enter code: "EXCELLENT" | Code field filled |
| 4 | Enter name: "Excellent Performance" | Name filled |
| 5 | Enter level: 1 | Level filled |
| 6 | Enter min_percentage: 85.00 | Min filled |
| 7 | Enter max_percentage: 100.00 | Max filled |
| 8 | Select ai_severity: "LOW" | Severity selected |
| 9 | Select ai_default_action: "ACCELERATE" | Action selected |
| 10 | Select scope: "SCHOOL" | Scope selected |
| 11 | Set is_active = ON | Active |
| 12 | Click "Save" | POST to store |
| 13 | Check response | Success: "Performance category created successfully." |
| 14 | DB check: `SELECT * FROM slb_performance_categories WHERE code='EXCELLENT'` | Record exists with all fields; code uppercased |

---

#### TC-P03: Create Category With All Optional Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New form | Form visible |
| 2 | Fill required fields: code="GOOD", name="Good", level=2, min=60, max=84.99, action="PROGRESS", scope="SCHOOL" | Required set |
| 3 | Enter description: "Solid performance with room for growth" | Description filled |
| 4 | Enter display_order: 2 | Order set |
| 5 | Enter color_code: "#00FF00" | Color set |
| 6 | Enter icon_code: "star" | Icon set |
| 7 | Set auto_retest_required = ON | Toggle ON |
| 8 | Click "Save" | Created |
| 9 | DB check: All optional fields saved | Values match |

---

#### TC-P04: Create Category With Scope=SCHOOL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category with scope="SCHOOL", no class_id | Created |
| 2 | DB check: `scope` = 'SCHOOL', `class_id` = NULL | School-wide scope |

---

#### TC-P05: Create Category With Scope=CLASS

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category with scope="CLASS", select class_id=C1 | Created |
| 2 | DB check: `scope` = 'CLASS', `class_id` = C1 | Class-specific scope |

---

#### TC-P06: Create Category With AI Severity = CRITICAL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category with ai_severity="CRITICAL" | Created |
| 2 | DB check: `ai_severity` = 'CRITICAL' | Stored |

---

#### TC-P07: Create Category With AI Action = ESCALATE

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category with ai_default_action="ESCALATE" | Created |
| 2 | DB check: `ai_default_action` = 'ESCALATE' | Stored |

---

#### TC-P08: Create Category With Auto Retest Required

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category with auto_retest_required = ON | Created |
| 2 | DB check: `auto_retest_required` = 1 | Auto retest enabled |

---

#### TC-P09: Create Category With Specific Display Order

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category with display_order = 5 | Created |
| 2 | DB check: `display_order` = 5 | Custom order |

---

#### TC-P10: Create Category With Color Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category with color_code = "#FF0000" | Created |
| 2 | DB check: `color_code` = '#FF0000' | Color saved |

---

#### TC-P11: Edit Category Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category: code="EDIT_01", name="Edit Test" | Exists |
| 2 | Click "Edit" button | Edit form loads |
| 3 | Verify all fields pre-filled | Code, name, level, range, severity, action, scope, etc. all match |

---

#### TC-P12: Update Category Name, Code, Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category: code="OLD", name="Old Name", min=10, max=50 | Exists |
| 2 | Edit: code="NEW", name="New Name", min=20, max=60 | Updated |
| 3 | Click "Save" | Update succeeds |
| 4 | DB check: All fields updated | Values changed |

---

#### TC-P13: Update Category AI Severity/Action

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category with severity="LOW", action="PROGRESS" | Exists |
| 2 | Edit: severity="HIGH", action="REMEDIATE" | Updated |
| 3 | DB check: ai_severity='HIGH', ai_default_action='REMEDIATE' | Changed |

---

#### TC-P14: View Category Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category with all fields filled | Exists |
| 2 | Click "View" button | Detail page loads |
| 3 | Check code, name, level, range displayed | All visible |
| 4 | Check AI severity, AI action displayed | Both shown |
| 5 | Check scope, class (if CLASS) displayed | Scope info |
| 6 | Check auto retest, display order, color code | Displayed |
| 7 | Check status badge | Active/Inactive badge |

---

#### TC-P15: Soft Delete Category (Non-System)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create non-system category: code="DEL_01" | Exists |
| 2 | Click delete button | SweetAlert confirmation |
| 3 | Confirm delete | Soft deleted |
| 4 | DB check: `is_active` = 0, `deleted_at` NOT NULL | Both set |
| 5 | Activity log: "Trashed" event | Logged |

---

#### TC-P16: Trash Page Shows Deleted Categories

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a category | Trashed |
| 2 | Click "Trash" button | Navigates to trash view |
| 3 | Check table shows deleted category | Record visible |
| 4 | Check "Restore" and "Force Delete" buttons | Both present |

---

#### TC-P17: Restore Category From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash, click "Restore" on trashed category | Restore succeeds |
| 2 | DB check: `deleted_at` = NULL, `is_active` = 1 | Restored and active |
| 3 | Navigate back to main list | Category visible again |
| 4 | Activity log: "Restored" event | Logged |

---

#### TC-P18: Force Delete Category (Permanent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete, navigate to trash, click "Force Delete" | Confirmation |
| 2 | Confirm | Permanently removed |
| 3 | DB check: Record gone | Force deleted |
| 4 | Activity log: "Deleted" event | Logged |

---

#### TC-P19: Toggle Status Active ↔ Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category with is_active=ON | Active |
| 2 | Click toggle switch | AJAX POST to toggle-status |
| 3 | Check response | JSON `{success: true, is_active: false}` |
| 4 | DB check: is_active=0 | Toggled inactive |
| 5 | Click toggle again | is_active=1 |

---

#### TC-P20: Empty State -- No Categories

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Scope where no categories exist | No data |
| 2 | Verify table | Shows "No performance categories found" message |
| 3 | Verify Add New button | Visible and enabled |

---

#### TC-P21: Change Scope From SCHOOL to CLASS

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category with scope=SCHOOL | Exists |
| 2 | Edit: change scope to CLASS, select class_id=C1 | Updated |
| 3 | DB check: scope='CLASS', class_id=C1 | Changed |

---

#### TC-P22: Create Category With Percentage Boundaries (0% and 100%)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category with min=0.00, max=100.00 | Created |
| 2 | DB check: min_percentage=0.00, max_percentage=100.00 | Boundary values saved |

---

### 6.2 Negative TC Steps

#### TC-N01: Required -- Missing `code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, leave code empty | Code empty |
| 2 | Click "Save" | HTTP 500: "Performance category code is required." |

---

#### TC-N02: Required -- Missing `name`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave name empty | Name empty |
| 2 | Click "Save" | HTTP 500: "The name field is required." |

---

#### TC-N03: Required -- Missing `level`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave level empty | Empty |
| 2 | Click "Save" | HTTP 500: "The level field is required." |

---

#### TC-N04: Required -- Missing `min_percentage`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave min_percentage empty | Empty |
| 2 | Click "Save" | HTTP 500 |

---

#### TC-N05: Required -- Missing `max_percentage`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave max_percentage empty | Empty |
| 2 | Click "Save" | HTTP 500 |

---

#### TC-N06: Required -- Missing `ai_default_action`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave ai_default_action empty | Empty |
| 2 | Click "Save" | HTTP 500: "The ai default action field is required." |

---

#### TC-N07: Required -- Missing `scope`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave scope empty | Empty |
| 2 | Click "Save" | HTTP 500: "The scope field is required." |

---

#### TC-N08: Duplicate Code Within Same Scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category code="DUP" with scope=SCHOOL | Exists |
| 2 | Create another category code="DUP" with same scope=SCHOOL | HTTP 500: "This performance category code already exists for the selected scope." |

---

#### TC-N09: Same Code Allowed For Different Scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category code="SAME" with scope=SCHOOL | Exists |
| 2 | Create category code="SAME" with scope=CLASS (different scope) | Created (unique scoped by scope) |

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

#### TC-N12: Invalid `level` -- 0 or Negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter level=0 | Below min |
| 2 | Click "Save" | HTTP 500: "The level must be at least 1." |
| 3 | Enter level=-5 | Same error |

---

#### TC-N13: Invalid `min_percentage` -- Negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter min_percentage=-10 | Below 0 |
| 2 | Click "Save" | HTTP 500: numeric min validation |

---

#### TC-N14: Invalid `max_percentage` -- > 100

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter max_percentage=150 | > 100 |
| 2 | Click "Save" | HTTP 500: numeric max validation |

---

#### TC-N15: Max Percentage <= Min Percentage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter min=50, max=50 (equal) | Not > min |
| 2 | Click "Save" | HTTP 500: "Maximum percentage must be greater than minimum percentage." |
| 3 | Enter min=60, max=40 (max < min) | Same error |

---

#### TC-N16: Range Overlap With Existing Active Record (Same Scope)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category A: min=30, max=60, scope=SCHOOL | Exists |
| 2 | Create category B: min=40, max=70, scope=SCHOOL | Overlaps with A (40-60 shared) |
| 3 | Click "Save" | 500: "The percentage range overlaps with an existing active performance category." |

---

#### TC-N17: Scope=CLASS Without Class ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select scope="CLASS", leave class_id empty | No class selected |
| 2 | Click "Save" | 500: "Class is required when scope is CLASS." |

---

#### TC-N18: Invalid AI Severity Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter ai_severity="INVALID" | Not in allowed list |
| 2 | Click "Save" | 500: "The selected ai severity is invalid." |

---

#### TC-N19: Invalid AI Default Action Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter ai_default_action="INVALID" | Not in allowed list |
| 2 | Click "Save" | 500: "The selected ai default action is invalid." |

---

#### TC-N20: Edit System-Defined Category (403)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category with is_system_defined=true | System-defined record |
| 2 | Attempt to edit and save | 403: "System-defined question types cannot be modified." |

---

#### TC-N21: Delete System-Defined Category (403)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to delete a system-defined category | 403: "System-defined question types cannot be deleted." |

---

#### TC-N22: Toggle Status On System-Defined Category (403)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to toggle status on a system-defined category | 403: "System-defined question types status cannot be changed." |

---

#### TC-N23: View Category With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `/syllabus/performance-category/99999` | HTTP 404 |

---

#### TC-N24: Edit/Update With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `/syllabus/performance-category/99999/edit` | HTTP 404 |

---

#### TC-N25: Permission 403 -- No Performance Category Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.performance-category.*` permissions | 403 on all endpoints |

---

#### TC-N26: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate to performance categories tab | Redirected to login |

---

#### TC-N27: Force Delete Non-Trashed Category

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to force delete an active (non-deleted) category | 404 |

---

#### TC-N28: Restore Non-Deleted Category

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to restore an active category | 404 |

---

### 6.3 Dependency TC Steps

#### TC-D01: Range Overlap -- Exact Same Range Rejected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category: min=0, max=100, scope=SCHOOL | Exists |
| 2 | Try to create another: min=0, max=100, scope=SCHOOL (exact same) | 500: overlap error |

---

#### TC-D02: Range Overlap -- Partial Overlap Rejected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category A: min=20, max=50, scope=SCHOOL | Exists |
| 2 | Try to create B: min=30, max=60, scope=SCHOOL | 500: overlap (30-50 overlaps) |

---

#### TC-D03: Range Overlap -- Contained Range Rejected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category A: min=30, max=60, scope=SCHOOL | Exists |
| 2 | Try to create B: min=40, max=50 (contained within A) | 500: overlap |

---

#### TC-D04: Range Non-Overlap -- Adjacent Ranges Allowed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category A: min=0, max=49.99, scope=SCHOOL | Exists |
| 2 | Create category B: min=50, max=100, scope=SCHOOL | Created (adjacent, no overlap) |

---

#### TC-D05: Range Non-Overlap -- Gap Between Ranges Allowed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category A: min=0, max=30, scope=SCHOOL | Exists |
| 2 | Create category B: min=60, max=100, scope=SCHOOL | Created (gap 30-60) |

---

#### TC-D06: Scope=CLASS Overlap Only Within Same Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category A: min=0, max=100, scope=CLASS, class_id=C1 | Exists |
| 2 | Create category B: min=0, max=100, scope=CLASS, class_id=C2 (different class) | Created (different class, no overlap detected) |

---

#### TC-D07: System-Defined Record -- View Allowed But No Edit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | View a system-defined category | View succeeds (read allowed) |
| 2 | Attempt to edit it | 403 blocked |
| 3 | Attempt to delete it | 403 blocked |
| 4 | Attempt to toggle status | 403 blocked |

---

#### TC-D08: Soft Delete Only Sets `is_active=false` First

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete a non-system category | `is_active` = 0 before `deleted_at` set |
| 2 | DB check: `is_active` = 0, `deleted_at` NOT NULL | Both flags updated |

---

#### TC-D09: Inactive Category Not Checked For Overlap

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category A: min=0, max=50, scope=SCHOOL, is_active=1 | Active |
| 2 | Toggle A inactive | A is now inactive |
| 3 | Create category B: min=0, max=50, scope=SCHOOL (same range as inactive A) | Created (inactive A not checked for overlap) |

---

#### TC-D10: Activity Log -- All Events Tracked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create, update, soft delete, restore, force delete, toggle status | Activity log entries for all events |
| 2 | Verify each event | Correct description and causer |

---

#### TC-D11: CHECK Constraint — min_percentage < max_percentage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category with min_percentage=80, max_percentage=90 | Created successfully (valid range) |
| 2 | Verify via INSERT directly at DB level with min_percentage=90, max_percentage=80 (inverted) | CHECK constraint violation thrown |
| 3 | Verify via INSERT directly at DB level with min_percentage=80, max_percentage=80 (equal) | CHECK constraint violation thrown |
| 4 | Verify valid range (min=80, max=90) saves successfully | Row inserted |

---

#### TC-D12: Overlapping Range Validation — Application Layer

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure existing categories with ranges 0-40, 41-70, 71-100 exist | Baseline ranges present |
| 2 | Attempt to create category with range 30-50 (overlaps 0-40 and 41-70) | Validation error: "The percentage range overlaps with an existing active performance category." |
| 3 | Attempt to create category with range 5-35 (overlaps 0-40) | Validation error |
| 4 | Attempt to create category with range 50-80 (overlaps 41-70 and 71-100) | Validation error |
| 5 | Create category with range 101-200 (non-overlapping, new tier) | Created successfully |

---

#### TC-D13: System-Protected Record — is_system_defined Restriction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | View a system-defined category (is_system_defined=1) | View succeeds |
| 2 | Attempt to edit a system-defined category | 403 Forbidden: cannot edit |
| 3 | Attempt to delete a system-defined category | 403 Forbidden: cannot delete |
| 4 | Attempt to toggle status of a system-defined category | 403 Forbidden: cannot toggle |
| 5 | Create a non-system category and verify it can be edited/deleted | Non-system record is editable and deletable |

---

#### TC-D14: ENUM Field Validation — ai_severity, ai_default_action, scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit form with ai_severity="INVALID" | Validation error: "The selected ai severity is invalid." |
| 2 | Submit form with ai_default_action="INVALID" | Validation error: "The selected ai default action is invalid." |
| 3 | Submit form with scope="INVALID" | Validation error: "The selected scope is invalid." |
| 4 | Submit form with valid ai_severity="LOW", ai_default_action="ACCELERATE", scope="SCHOOL" | Created successfully |

---

#### TC-D15: Composite Unique Constraint — uq_perf_code (code + scope)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | INSERT at DB level: (code='DUPLICATE', scope='SCHOOL') | Inserted successfully |
| 2 | INSERT at DB level: same (code='DUPLICATE', scope='SCHOOL') again | Integrity constraint violation (duplicate key) |
| 3 | INSERT at DB level: (code='DUPLICATE', scope='CLASS') — different scope | Inserted successfully (different scope, unique composite permits) |

---

#### TC-D16: Model — `$fillable` Array Protection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PerformanceCategory.php` model file | File loads |
| 2 | Locate `$fillable` property array | Array exists |
| 3 | Check array values | Only `code`, `name`, `description`, `min_value`, `max_value`, `is_active` are present |
| 4 | Create a record via `PerformanceCategory::create(['id' => 999])` | `id` is ignored (not mass-assignable) |
| 5 | Verify the `id` was not set | `id` remains auto-increment value |

---

#### TC-D17: Model — `$casts` Configuration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PerformanceCategory.php` model | `$casts` property found |
| 2 | Check `is_active` cast | `'is_active' => 'boolean'` |
| 3 | Check `min_value` cast | `'min_value' => 'decimal:2'` |
| 4 | Check `max_value` cast | `'max_value' => 'decimal:2'` |
| 5 | Verify cast at runtime: retrieve record and check types | `is_active` is `bool`, `min_value`/`max_value` are floats |

---

#### TC-D18: Model — `SoftDeletes` Trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PerformanceCategory.php` | File loads |
| 2 | Check `use` statements at top of class | `use SoftDeletes;` or `use Illuminate\Database\Eloquent\SoftDeletes;` |
| 3 | Check class body for `use SoftDeletes;` trait import | Trait is imported inside class |
| 4 | Check migration for `deleted_at` column | `$table->softDeletes()` or `deleted_at` timestamp column present |
| 5 | Soft delete a record and verify `deleted_at` is set | Record's `deleted_at` is non-null timestamp |

---

#### TC-D19: Controller — CRUD Methods Present

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PerformanceCategoryController.php` | File loads |
| 2 | Locate `index()` method | Method exists with correct signature |
| 3 | Locate `create()` method | Method exists |
| 4 | Locate `store(Request $request)` method | Method exists with Request injection |
| 5 | Locate `show($id)` method | Method exists |
| 6 | Locate `edit($id)` method | Method exists |
| 7 | Locate `update(Request $request, $id)` method | Method exists with Request + ID |
| 8 | Locate `destroy($id)` method | Method exists |

---

#### TC-D20: Controller — Gate Authorization On Each Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PerformanceCategoryController.php` | File loads |
| 2 | Check `index()` for `Gate::authorize('tenant.performance-category.viewAny')` | Gate call present |
| 3 | Check `create()`/`store()` for `tenant.performance-category.create` | Gate calls present |
| 4 | Check `show()` for `tenant.performance-category.view` | Gate call present |
| 5 | Check `edit()`/`update()` for `tenant.performance-category.update` | Gate calls present |
| 6 | Check `destroy()` for `tenant.performance-category.delete` | Gate call present |
| 7 | Check `restore()` for `tenant.performance-category.restore` | Gate call present |
| 8 | Check `forceDelete()` for `tenant.performance-category.forceDelete` | Gate call present |

---

#### TC-D21: Controller — Activity Log Events

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller and find `afterStored` / `afterUpdated` calls | Activity logged for store/update |
| 2 | Find `afterTrashed` / `afterRestored` / `afterDeleted` calls | Activity logged for soft-delete/restore/force-delete |
| 3 | Find `afterToggled` or similar in `toggleStatus()` | Activity logged for status toggle |
| 4 | Verify `causer` is set to `auth()->user()` | Causer is current authenticated user |
| 5 | Verify description contains record identifier (code/name) | Description is meaningful |

---

#### TC-D22: Controller — `is_active = false` Before `delete()`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroy()` method in controller | Method found |
| 2 | Inspect order of operations | `is_active` set to `false` (`update(['is_active' => false])`) called BEFORE `delete()` |
| 3 | Verify the record is not hard-deleted yet when `is_active` updated | `is_active` = 0, `deleted_at` still null momentarily |
| 4 | Confirm `delete()` is called after | `delete()` invoked on model after status update |

---

#### TC-D23: Request — Validation Rules (Create)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PerformanceCategoryRequest.php` | File loads |
| 2 | Locate `rules()` method | Method exists |
| 3 | Check `code` rules | `required`, `string`, `max:20`, `unique:slb_performance_categories` present |
| 4 | Check `name` rules | `required`, `string`, `max:100` present |
| 5 | Check `description` rules | `nullable`, `string`, `max:255` present |
| 6 | Check `min_value` rules | `nullable`, `numeric` present |
| 7 | Check `max_value` rules | `nullable`, `numeric` present |
| 8 | Check `is_active` rules | `nullable`, `boolean` present |
| 9 | Submit invalid data via browser/Dusk | HTTP 500 with field-specific error messages |

---

#### TC-D24: Request — Validation Rules (Update)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PerformanceCategoryRequest.php` | File loads |
| 2 | Check `code` rule for update | `unique:slb_performance_categories` includes `ignore($this->route('performance_category'))` or similar |
| 3 | Create record with code="UNIQUE1" | Exists |
| 4 | Edit same record and keep code="UNIQUE1" | Update succeeds (same code, ignored) |
| 5 | Try to change code to another existing code | 500 duplicate error |

---

#### TC-D25: Policy — All Gate Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PerformanceCategoryPolicy.php` | File loads |
| 2 | Check `viewAny()` method | Returns `$user->can('tenant.performance-category.viewAny')` |
| 3 | Check `view()` method | Returns appropriate permission check |
| 4 | Check `create()` method | Returns permission check |
| 5 | Check `update()` method | Returns permission check |
| 6 | Check `delete()` method | Returns permission check |
| 7 | Check `restore()` method | Returns permission check |
| 8 | Check `forceDelete()` method | Returns permission check |
| 9 | Check `status()` method | Returns permission check for toggle |

---

#### TC-D26: Routes — Resource Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/api.php` or module web routes file | Route file found |
| 2 | Search for `performance-category` route definition | `Route::resource('performance-category', PerformanceCategoryController::class)` present |
| 3 | Verify controller namespace matches actual class | Fully qualified class name or correct namespace used |
| 4 | Run `php artisan route:list --path=performance-category` | All 7 resource routes listed (index/create/store/show/edit/update/destroy) |

---

#### TC-D27: Routes — Additional Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open routes file for `performance-category` | Route file found |
| 2 | Find `GET /trash/view` route | `->get('performance-category/trash/view', ...)` or named `performance-category.trashed` |
| 3 | Find `POST /{id}/restore` route | `->post('performance-category/{id}/restore', ...)` or named `performance-category.restore` |
| 4 | Find `DELETE /{id}/force-delete` route | `->delete('performance-category/{id}/force-delete', ...)` or named `performance-category.forceDelete` |
| 5 | Find `POST /toggle-status/{id}` route | `->post('performance-category/toggle-status/{id}', ...)` or named `performance-category.toggleStatus` |
| 6 | Run `php artisan route:list --path=performance-category` | All additional routes visible in route list |

---

#### TC-D28: Controller — `toggleStatus()` Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `toggleStatus($id)` method in controller | Method found |
| 2 | Inspect is_active toggle logic | `is_active = !is_active` or ternary flip |
| 3 | Check JSON response structure | Returns `{success: true, is_active: <new_bool_value>}` |
| 4 | Check system-defined guard | If `is_system_defined` is true, returns 403 before toggle |
| 5 | Toggle an active category via browser | Category becomes inactive; green badge turns red |
| 6 | Toggle again | Category becomes active again |

---

#### TC-D29: Controller — Trashed/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `trashed()` method | Uses `onlyTrashed()->paginate(10)` |
| 2 | Open `restore($id)` method | Finds with `onlyTrashed()->findOrFail($id)`, calls `restore()`, logs activity |
| 3 | Open `forceDelete($id)` method | Finds with `onlyTrashed()->findOrFail($id)`, calls `forceDelete()`, logs activity |
| 4 | Soft delete a record, navigate to trash | Record visible in trash list |
| 5 | Click Restore | Record restored, `deleted_at` = null, back in main list |
| 6 | Click Force Delete on a trashed record | Record permanently removed, 404 on re-query |
| 7 | Attempt to force delete a non-trashed record | 404 via `onlyTrashed()` |

---

#### TC-D30: Model — `is_active` Boolean Scoping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller `index()` method | Check if active records are queried via `where('is_active', true)` |
| 2 | Open controller `destroy()` method | Check scope only allows deleting active records |
| 3 | Open overlap validation logic | Check that only active records are considered for range overlap |
| 4 | Create active and inactive records | Both exist in DB |
| 5 | Load index page | Only active records shown |
| 6 | Check inactive record overlap exclusion | Creating a new record with same range as inactive record succeeds |

---

#### TC-P23: ai_severity Defaults to LOW

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open PerformanceCategoryRequest.php | File loads |
| 2 | Locate the `prepareForValidation()` or `validationData()` method | Method found |
| 3 | Find the `ai_severity` default assignment | `$this->ai_severity ?? 'LOW'` present |
| 4 | Create a category without providing ai_severity | Category created successfully |
| 5 | DB check: `ai_severity` = 'LOW' | Default value applied |

---

#### TC-P24: display_order Defaults to 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open PerformanceCategoryRequest.php | File loads |
| 2 | Locate the `prepareForValidation()` or `validationData()` method | Method found |
| 3 | Find the `display_order` default assignment | `$this->display_order ?? 1` present |
| 4 | Create a category without providing display_order | Category created successfully |
| 5 | DB check: `display_order` = 1 | Default value applied |

---

#### TC-N29: Max Length — description > 255 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter description of 256 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500: "The description must not be greater than 255 characters." |

---

#### TC-N30: Max Length — level > 255

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter level=256 | Exceeds max |
| 2 | Click "Save" | HTTP 500: "The level must not be greater than 255." |

---

#### TC-N31: Invalid display_order — Below 1 or Above 65535

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter display_order=0 | Below min |
| 2 | Click "Save" | HTTP 500: "The display order must be at least 1." |
| 3 | Enter display_order=65536 | Above max |
| 4 | Click "Save" | HTTP 500: "The display order must not be greater than 65535." |

---

#### TC-N32: Max Length — color_code > 10 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter color_code of 11 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500: "The color code must not be greater than 10 characters." |

---

#### TC-N33: Max Length — icon_code > 50 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter icon_code of 51 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500: "The icon code must not be greater than 50 characters." |
