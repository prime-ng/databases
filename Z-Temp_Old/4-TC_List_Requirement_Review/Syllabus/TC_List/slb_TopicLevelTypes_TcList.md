# slb_topic_level_types_TcList

## Module: Syllabus → Syllabus Master → Topic Types

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Syllabus Master |
| Feature | Topic Types |
| URL(s) | `/syllabus/master` (index via tab), `/syllabus/topic-level-types/create` (create), `/syllabus/topic-level-types` (store), `/syllabus/topic-level-types/{id}` (show), `/syllabus/topic-level-types/{id}/edit` (edit), `/syllabus/topic-level-types/{id}` (update), `/syllabus/topic-level-types/trash/view` (trash), `/syllabus/topic-level-types/{id}/restore` (restore), `/syllabus/topic-level-types/{id}/force-delete` (forceDelete), `/syllabus/topic-level-types/{id}/toggle-status` (toggleStatus) |
| Controller | `Modules\Syllabus\Http\Controllers\TopicLevelTypeController` |
| Model(s) | `Modules\Syllabus\Models\TopicLevelType` |
| Validation (Create) | `Modules\Syllabus\Http\Requests\TopicLevelTypeRequest` |
| Validation (Update) | `Modules\Syllabus\Http\Requests\TopicLevelTypeRequest` (ignores current ID for unique) |
| Permissions | `tenant.topic-level-type.viewAny`, `tenant.topic-level-type.view`, `tenant.topic-level-type.create`, `tenant.topic-level-type.update`, `tenant.topic-level-type.delete`, `tenant.topic-level-type.restore`, `tenant.topic-level-type.forceDelete`, `tenant.topic-level-type.status` |
| Soft Deletes | Yes (`TopicLevelType` uses `SoftDeletes` trait) |
| Activity Log | Events: `Created`, `Updated`, `Delete`, `Restored`, `Force Delete`, `Toggle Status` |
| Import | Not supported |

---

## 2. Pre-conditions

- Required permissions: `tenant.topic-level-type.viewAny`, `tenant.topic-level-type.view`, `tenant.topic-level-type.create`, `tenant.topic-level-type.update`, `tenant.topic-level-type.delete`, `tenant.topic-level-type.restore`, `tenant.topic-level-type.forceDelete`, `tenant.topic-level-type.status`
- Required seed data: None initially; sequential level creation (first must be level 0)
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
| Topic Level Types Grid | getTopicLevelTypes() | TopicLevelType | search(name,code), filter(status) | 10/page (topic_level_types_page) |
## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Level**: TinyInt UNIQUE (0–9), sequential (first must be 0, next must be max+1)
- **Code**: VARCHAR(3) UNIQUE, max 3 chars
- **Name**: VARCHAR(150) UNIQUE, max 150 chars
- **Sequential constraint**: `withValidator()` enforces level continuity; first record must be level 0
- **Pre-test cleanup**: Delete created records by code/level before/after tests to avoid collisions
- **JSON fields**: None

---

## 5. Business Conditions

### 4.1 Database Schema — `slb_topic_level_types`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT PK | Auto-increment |
| BC-DB-02 | level | TINYINT | NOT NULL, UNIQUE (0–9) |
| BC-DB-03 | code | VARCHAR(3) | NOT NULL, UNIQUE |
| BC-DB-04 | name | VARCHAR(150) | NOT NULL, UNIQUE |
| BC-DB-05 | homework_release_flag | TINYINT(1) | DDL only (not fillable in model) |
| BC-DB-06 | quiz_release_flag | TINYINT(1) | DDL only (not fillable in model) |
| BC-DB-07 | quest_release_flag | TINYINT(1) | DDL only (not fillable in model) |
| BC-DB-08 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 (cast to boolean) |
| BC-DB-09 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-10 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-11 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules — `TopicLevelTypeRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | level | required, integer, min:0, max:9, unique:slb_topic_level_types,level | "The level field is required." |
| BC-VAL-02 | level | min:0 | "Level must be at least 0." |
| BC-VAL-03 | level | max:9 | "Level cannot exceed 9." |
| BC-VAL-04 | level | unique | "This level already exists." |
| BC-VAL-05 | code | required, string, max:3, unique:slb_topic_level_types,code | "The code field is required." |
| BC-VAL-06 | code | max:3 | "Code cannot exceed 3 characters." |
| BC-VAL-07 | code | unique | "This code already exists." |
| BC-VAL-08 | name | required, string, max:150, unique:slb_topic_level_types,name | "The name field is required." |
| BC-VAL-09 | name | max:150 | "Name cannot exceed 150 characters." |
| BC-VAL-10 | name | unique | "This name already exists." |
| BC-VAL-11 | is_active | sometimes, boolean | — |
| BC-VAL-12 | Sequence (custom) | withValidator(): first must be 0, subsequent must be max+1 | "The first level must be 0." / "Level must be N to maintain sequence." |

### 4.3 Validation Rules — `TopicLevelTypeRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | level | required, integer, min:0, max:9, unique + ignore($id) | "The level field is required." |
| BC-VAL-U02 | level | min:0 | "Level must be at least 0." |
| BC-VAL-U03 | level | max:9 | "Level cannot exceed 9." |
| BC-VAL-U04 | level | unique + ignore | "This level already exists." |
| BC-VAL-U05 | code | required, string, max:3, unique + ignore($id) | "The code field is required." |
| BC-VAL-U06 | code | max:3 | "Code cannot exceed 3 characters." |
| BC-VAL-U07 | code | unique + ignore | "This code already exists." |
| BC-VAL-U08 | name | required, string, max:150, unique + ignore($id) | "The name field is required." |
| BC-VAL-U09 | name | max:150 | "Name cannot exceed 150 characters." |
| BC-VAL-U10 | name | unique + ignore | "This name already exists." |
| BC-VAL-U11 | is_active | sometimes, boolean | — |
| BC-VAL-U12 | Sequence (custom) | withValidator(): new level ≤ max(existing)+1, no gaps | "Level must be N to maintain sequence." |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.topic-level-type.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.topic-level-type.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.topic-level-type.create | store(), create() | Without → 403 |
| BC-AUTH-04 | tenant.topic-level-type.update | update(), edit(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.topic-level-type.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.topic-level-type.restore | restore(), trashed() | Without → 403 |
| BC-AUTH-07 | tenant.topic-level-type.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.topic-level-type.status | toggleStatus() (via update gate) | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-02 | Default is_active on create | Defaults to true |
| BC-BIZ-03 | Sequential level — First record | First record MUST be level 0 |
| BC-BIZ-04 | Sequential level — Subsequent records | New level must equal `max(existing level) + 1` |
| BC-BIZ-05 | Sequential level — Update constraint | New level cannot exceed `max(existing levels) + 1` |
| BC-BIZ-06 | Delete blocked if topics exist | If `Topic::whereHas('topicLevelType')` at level >= current, redirect with error "Topic Type cannot be deleted because topics exist at this level or below." |
| BC-BIZ-07 | Delete sets is_active false | Sets `is_active = false` before `delete()` |
| BC-BIZ-08 | Restore sets is_active true | `restore()` sets `is_active = true` |
| BC-BIZ-09 | Status toggle | `is_active` flips; returns JSON `{success, is_active, message}` |
| BC-BIZ-10 | Force delete — FK RESTRICT | `slb_topics.level_id` ON DELETE RESTRICT prevents force delete if topics exist |
| BC-BIZ-11 | Show uses withTrashed | `show()` calls `withTrashed()->findOrFail($id)` |
| BC-BIZ-12 | Pagination | Index paginated at 10 per page, ordered by `level` |
| BC-BIZ-13 | Activity log — Created | On create |
| BC-BIZ-14 | Activity log — Updated | On update |
| BC-BIZ-15 | Activity log — Delete | On soft delete |
| BC-BIZ-16 | Activity log — Restored | On restore |
| BC-BIZ-17 | Activity log — Force Delete | On force delete |
| BC-BIZ-18 | Activity log — Toggle Status | On status toggle |
| BC-BIZ-19 | Redirect after CRUD | Redirect to `syllabus.master.index` with tab `topic_level_types` |
| BC-BIZ-20 | Only 3 fillable fields | Model fillable: `level`, `code`, `name`, `is_active` (gatekeeper flags not fillable) |
| BC-BIZ-21 | Screen loads via SyllabusController@master() at GET /syllabus/master with master tab group | Navigating to GET /syllabus/master with appropriate permissions loads the Master tab group; this screen's grid data is fetched and displayed |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | level_id (in slb_topics) | slb_topic_level_types (id) | RESTRICT |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Topic Types List Page Loads With All UI Elements | Page loads with Add New, Trash, search, table: Level, Code, Name, Status, Actions | — | — | ⬜ |
| TC-P02 | Search By Name Or Code | Table filters correctly | — | — | ⬜ |
| TC-P03 | Filter By Active/Inactive Status | Filter works correctly | — | — | ⬜ |
| TC-P04 | Create First Topic Type Level 0 (Root Topic) | First record created with level=0 | — | — | ⬜ |
| TC-P05 | Create Sequential Level 1 (Sub Topic) | Level 1 created after level 0 | — | — | ⬜ |
| TC-P06 | Create Sequential Level 2 (Micro Topic) | Level 2 created after level 1 | — | — | ⬜ |
| TC-P07 | Create Full Sequential Chain (Levels 0→1→2→3) | All levels created in correct sequence | — | — | ⬜ |
| TC-P08 | Create With Code Max 3 Characters | Code "TOP" (3 chars) accepted | — | — | ⬜ |
| TC-P09 | Edit Topic Type Loads Pre-Filled Data | Edit form shows existing data | — | — | ⬜ |
| TC-P10 | Update Topic Type All Fields | Level, code, name, is_active all updated | — | — | ⬜ |
| TC-P11 | View Topic Type Details Page | Details shown with level, code, name, status | — | — | ⬜ |
| TC-P12 | Soft Delete Topic Type (No Topics Linked) | `deleted_at` set | — | — | ⬜ |
| TC-P13 | Trash Page Shows Deleted Records | Trash page lists only soft-deleted records | — | — | ⬜ |
| TC-P14 | Restore Topic Type From Trash | `deleted_at` = NULL; activity log "Restored" | — | — | ⬜ |
| TC-P15 | Force Delete Topic Type (No Topics Linked) | Record permanently removed | — | — | ⬜ |
| TC-P16 | Toggle Status Active ↔ Inactive | `is_active` flips; AJAX 200 | — | — | ⬜ |
| TC-P17 | Pagination Works (10 Per Page) | Pagination links with 11+ records | — | — | ⬜ |
| TC-P18 | Records Ordered By Level Ascending | Index shows records ordered by level (0→1→2...) | — | — | ⬜ |
| TC-P19 | Empty State — No Records Yet | "No records found" message | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing Level | "The level field is required." | — | — | ⬜ |
| TC-N02 | Required — Missing Code | "The code field is required." | — | — | ⬜ |
| TC-N03 | Required — Missing Name | "The name field is required." | — | — | ⬜ |
| TC-N04 | Invalid Level — Below 0 (Negative) | "Level must be at least 0." | — | — | ⬜ |
| TC-N05 | Invalid Level — Above 9 | "Level cannot exceed 9." | — | — | ⬜ |
| TC-N06 | Invalid Code — Exceeds 3 Characters | "Code cannot exceed 3 characters." | — | — | ⬜ |
| TC-N07 | Invalid Name — Exceeds 150 Characters | name.max validation fails | — | — | ⬜ |
| TC-N08 | Duplicate Level | "This level already exists." | — | — | ⬜ |
| TC-N09 | Duplicate Code | "This code already exists." | — | — | ⬜ |
| TC-N10 | Duplicate Name | "This name already exists." | — | — | ⬜ |
| TC-N11 | Non-Sequential First Level (Not 0) | "The first level must be 0." | — | — | ⬜ |
| TC-N12 | Non-Sequential Subsequent Level (Skip) | "Level must be N to maintain sequence." | — | — | ⬜ |
| TC-N13 | View Record With Invalid ID (404) | HTTP 404 | — | — | ⬜ |
| TC-N14 | Edit/Update Record With Invalid ID (404) | HTTP 404 | — | — | ⬜ |
| TC-N15 | Delete Record With Invalid ID (404) | Redirect with error | — | — | ⬜ |
| TC-N16 | Toggle Status With Invalid ID (404) | JSON 404 | — | — | ⬜ |
| TC-N17 | Restore Non-Deleted Record (Already Active) | 404 error | — | — | ⬜ |
| TC-N18 | Force Delete Non-Trashed Record | 404 error | — | — | ⬜ |
| TC-N19 | Permission 403 — No Topic Type Permissions | 403 on all CRUD | — | — | ⬜ |
| TC-N20 | Guest Access Redirect | Redirected to /login | — | — | ⬜ |
| TC-N21 | XSS Injection In Name/Code | Stored as literal; Blade escapes | — | — | ⬜ |
| TC-N22 | Whitespace-Only Name/Code | Required validation catches | — | — | ⬜ |
| TC-N24 | Update Level To Non-Sequential Value | `withValidator()` blocks non-sequential update | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Soft Delete Blocked — Topics Reference This Level | "Topic Type cannot be deleted because topics exist at this level or below." | — | — | ⬜ |
| TC-D02 | B | Force Delete Blocked — Topics Reference (RESTRICT) | FK constraint prevents force delete if topics exist | — | — | ⬜ |
| TC-D03 | C | Toggle Status — Inactive Record Hidden From Topic Creation Dropdown | Inactive type excluded from topic level dropdowns | — | — | ⬜ |
| TC-D04 | D | Sequential Integrity After Soft Delete/Restore | Sequential check works correctly with soft-deleted records excluded | — | — | ⬜ |
| TC-D05 | E | UI — P1 — slb_topic_level_types (read from slb_topic_level_types) — System-Protected Master Data — PG_Team Controlled | Topic level types are set by PG_Team and NOT available for school to create/edit/delete; screen enforces read-only access or hides CRUD buttons | — | — | ⬜ |
| TC-D06 | F | DB — P1 — slb_topic_level_types with existing record — Unique Constraint — level, code, name | Inserting duplicate level, code, or name at DB level throws integrity constraint violation (uq_topic_type_level, uq_topic_type_code, uq_topic_type_name) | — | — | ⬜ |
| TC-D07 | G | DB — P1 — slb_topic_level_types with existing type, slb_topics referencing it — FK RESTRICT — level_id Deletion Blocked | Deleting a topic level type that is referenced by slb_topics.level_id throws FK RESTRICT error; cannot delete while topics reference it | — | — | ⬜ |
| TC-D08 | H | Cross-Module \| P1 \| Quiz/Homework/Exam — Release Toggles Control Cross-Module Content Release | Topic level types have Homework Release, Quiz Release, Quest Release, Question Bank Tagging, and Exam Release toggles; these settings are read by LmsHomework, LmsQuiz, LmsQuests, and Exam modules to determine allowed hierarchy level for content release | — | — | ⬜ |
| TC-CR01 | H | Model — $fillable Protects Against Mass Assignment | Only `level`, `code`, `name`, `description`, `is_active` are fillable; mass-assigning other columns (`homework_release_flag`, `quiz_release_flag`, `quest_release_flag`, `id`, `created_at`, `updated_at`, `deleted_at`) is silently ignored | — | — | ⬜ |
| TC-CR02 | H | Model — $casts Ensures Type Integrity | `$casts` includes `is_active => 'boolean'` and `level => 'integer'`; values are correctly typecast on access (e.g. `is_active` returns `true`/`false`, `level` returns integer) | — | — | ⬜ |
| TC-CR03 | H | Model — SoftDeletes Trait Correctly Implemented | Model uses `SoftDeletes` trait; `deleted_at` column nullable; soft-deleted records excluded from default queries; `withTrashed()` and `onlyTrashed()` scopes functional | — | — | ⬜ |
| TC-CR04 | H | Controller — Gate Authorization on Every Action | Every controller method (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`, `toggleStatus`, `trashed`, `restore`, `forceDelete`) calls `Gate::authorize()` with correct permission before executing business logic | — | — | ⬜ |
| TC-CR05 | H | Controller — Activity Logged on All State Changes | Each state-changing action fires an activity log event: `Created` (store), `Updated` (update), `Delete` (destroy), `Restored` (restore), `Force Delete` (forceDelete), `Toggle Status` (toggleStatus); log entry contains relevant model details | — | — | ⬜ |
| TC-CR06 | H | Controller — Destroy Sets is_active=false, Restore Sets is_active=true | Before `$model->delete()`, controller sets `$model->is_active = false` and saves; on `restore()`, controller sets `$model->is_active = true` and saves; trashed records always inactive | — | — | ⬜ |
| TC-CR07 | H | Request — Validation Rules Cover All Fields | `TopicLevelTypeRequest` defines: `code` => `required|string|max:20|unique:slb_topic_level_types,code`, `name` => `required|string|max:100`, `level` => `nullable|integer`, `description` => `nullable|string|max:255`, `is_active` => `nullable|boolean`; each constraint fires correct error message on violation | — | — | ⬜ |
| TC-CR08 | H | Request — Unique Rule Ignores Current ID on Update | When ID is present (update), unique rules modify to ignore the current record: `unique:slb_topic_level_types,code,{id}`; same record can keep its own values without false-positive duplicate error | — | — | ⬜ |
| TC-CR09 | H | Policy — All Required Methods Defined | `TopicLevelTypePolicy` defines all 8 methods: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`, `status`; each method returns boolean after checking the corresponding permission | — | — | ⬜ |
| TC-CR10 | H | Policy — Permission Strings Match Route/Gate Names | Policy methods use correct permission strings prefixed `tenant.topic-level-type.` (e.g. `tenant.topic-level-type.viewAny`, `tenant.topic-level-type.create`, `tenant.topic-level-type.status`); strings match the gates authorized in controller | — | — | ⬜ |
| TC-CR11 | H | Routes — Resourceful + Custom Routes Registered | `Route::resource('topic-level-type', TopicLevelTypeController::class)` generates all RESTful routes; additional routes for `trashed` (GET), `restore` (POST `{topicLevelType}/restore`), `force-delete` (DELETE `{topicLevelType}/force-delete`), `toggle-status` (POST `{topicLevelType}/toggle-status`) | — | — | ⬜ |
| TC-CR12 | H | Routes — Route Model Binding Resolves 404 Automatically | Controller methods type-hint `TopicLevelType $topicLevelType`; implicit or explicit route model binding resolves 404 via `ModelNotFoundException` for invalid IDs | — | — | ⬜ |
| TC-CR13 | H | Controller — Toggle Status Returns Consistent JSON | `toggleStatus()` returns JSON with shape `{success: bool, is_active: bool, message: string}`; HTTP 200 on success, 404 on missing record, 403 on unauthorized | — | — | ⬜ |
| TC-CR14 | H | Controller — CRUD Redirects Consistent | All successful state-changing actions (store, update, destroy, restore) redirect to `route('syllabus.master.index', ['tab' => 'topic_level_types'])` with a success flash message | — | — | ⬜ |
| TC-CR15 | H | Database — Unique Indexes Match Request Validation | Database has unique indexes on `level` (`uq_topic_level_type_level`), `code` (`uq_topic_level_type_code`), `name` (`uq_topic_level_type_name`); DB-level enforcement matches `unique` rules in FormRequest; duplicate insertion at DB level throws integrity constraint violation | — | — | ⬜ |
| TC-CR16 | H | Request — prepareForValidation() Casts is_active via $this->boolean() | `prepareForValidation()` calls `$this->boolean('is_active')` to cast string/0/1/"true"/"false" to boolean before validation; ensures is_active is always boolean-typed for validator | — | — | ⬜ |

---

## 7. Detailed Test Steps


#### TC-CR01: Blade @can Directives — Permission-based Visibility for All Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php for add/create button | @can('tenant.topic-level-type.create') wraps the Add New button; user without create permission does not see it
| 2 | Inspect row-level action buttons (view, edit, delete, status toggle) | @can('tenant.topic-level-type.view'), @can('tenant.topic-level-type.edit'), @can('tenant.topic-level-type.delete'), @can('tenant.topic-level-type.status') used appropriately; expired permissions hide corresponding buttons
| 3 | Inspect trash.blade.php for restore/forceDelete buttons | @canany(['tenant.topic-level-type.restore', 'tenant.topic-level-type.forceDelete']) wraps action buttons in trash view
| 4 | Inspect view.blade.php for edit button | @can('tenant.topic-level-type.edit') wraps the Edit button on show/details page
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

#### TC-CR03: Controller — try-catch Exception Handling on All CRUD Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller file for this screen | Controller class found in Modules/Syllabus/Http/Controllers/
| 2 | Inspect store() method | Business logic wrapped in try {} catch(\Exception $e) {}; on exception, DB rollback and error logged
| 3 | Inspect update() method | try-catch present; findOrFail inside try; validation errors from FormRequest caught before try block
| 4 | Inspect destroy() method | try-catch present; is_active toggle inside try; activityLog inside try
| 5 | Inspect restore() method | try-catch present; is_active restore inside try
| 6 | Inspect forceDelete() method | try-catch present; onlyTrashed+findOrFail inside try
| 7 | Simulate DB failure during store (e.g. unique constraint violation) | Exception caught; user redirected with error message; no partial data written


#### TC-CR04: Controller — DB Transactions on Multi-Step Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller file for this screen | Controller class found
| 2 | Inspect methods that combine create/update + activityLog | Both operations wrapped in DB::transaction(); if activityLog fails, create/update is rolled back
| 3 | Inspect destroy() method | is_active=false toggle + delete() + activityLog all in single transaction
| 4 | Inspect restore() method | is_active=true + restore() + activityLog in single transaction
| 5 | Verify no partial writes occur | If activityLog throws exception after model save, model changes are rolled back


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
| 2 | Verify success message after create | Page shows success alert: 'Topic level type created successfully' (or equivalent for this screen)
| 3 | Update the record | PUT/PATCH to update(); redirects with flash
| 4 | Verify success message after update | 'Topic level type updated successfully' (or equivalent)
| 5 | Soft delete the record | DELETE to destroy(); redirects with flash
| 6 | Verify success message after delete | 'Topic level type trashed successfully' (or equivalent)
| 7 | Restore from trash | POST to restore(); redirects with flash
| 8 | Verify success message after restore | 'Topic level type restored successfully' (or equivalent)
| 9 | Force delete from trash | DELETE to forceDelete(); redirects with flash
| 10 | Verify success message after force delete | 'Topic level type force deleted successfully' (or equivalent)


### 6.1 Positive TC Steps

#### TC-P01: Topic Types List Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login, navigate to Syllabus → Syllabus Master → Topic Types tab | Page loads |
| 2 | Check search, status filter, Add New, Trash, table columns | All UI elements present |

---

#### TC-P02: Search By Name Or Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create "Root Topic" (code="TOP"), "Sub Topic" (code="SUB") | 2 records |
| 2 | Search "Root" | Only "Root Topic" visible |
| 3 | Search "SUB" | Only "Sub Topic" visible |

---

#### TC-P03: Filter By Active/Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active and inactive records | Both exist |
| 2 | Select "Active" | Only active |
| 3 | Select "Inactive" | Only inactive |

---

#### TC-P04: Create First Topic Type Level 0 (Root Topic)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add New" | Form opens |
| 2 | Enter level: 0, code: "TOP", name: "Root Topic" | Fields filled |
| 3 | Click "Save" | POST to store |
| 4 | Check response | Success message |
| 5 | DB check: record exists with level=0 | Created correctly |

---

#### TC-P05: Create Sequential Level 1 (Sub Topic)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add New" (level 0 exists) | Form opens |
| 2 | Enter level: 1, code: "SUB", name: "Sub Topic" | Sequential level |
| 3 | Click "Save" | Record created |
| 4 | DB check: level=1 exists | Created correctly |

---

#### TC-P06: Create Sequential Level 2 (Micro Topic)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | After levels 0 and 1 exist, create level 2 | Form opens |
| 2 | Enter level: 2, code: "MIC", name: "Micro Topic" | Sequential |
| 3 | Click "Save" | Record created |

---

#### TC-P07: Create Full Sequential Chain (Levels 0→1→2→3)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create levels 0, 1, 2, 3 sequentially | All created |
| 2 | DB check: all 4 levels exist with correct values | Levels 0-3 present |

---

#### TC-P08: Create With Code Max 3 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code="TOP" (3 chars) | Valid |
| 2 | Click "Save" | Record created |

---

#### TC-P09: Edit Topic Type Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record level=0, code="EDITTEST", name="Edit Test" | Exists |
| 2 | Click "Edit" | Form pre-filled |

---

#### TC-P10: Update Topic Type All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record, edit | Form loaded |
| 2 | Change level, code, name, is_active | All updated |
| 3 | Click "Save" | Update succeeds |

---

#### TC-P11: View Topic Type Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record, click "View" | Level, code, name, status shown |

---

#### TC-P12: Soft Delete Topic Type (No Topics Linked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with no topics referencing it | Exists |
| 2 | Click delete, confirm | Soft deleted |
| 3 | DB check: deleted_at NOT NULL | Trashed |

---

#### TC-P13: Trash Page Shows Deleted Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete a record | In trash |
| 2 | Click "Trash" | Shows record |

---

#### TC-P14: Restore Topic Type From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate trash, click "Restore", confirm | Restored |
| 2 | Activity log "Restored" | Logged |

---

#### TC-P15: Force Delete Topic Type (No Topics Linked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete, force delete | Permanently removed |
| 2 | Activity log "Force Delete" | Logged |

---

#### TC-P16: Toggle Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active record, toggle | is_active flips |
| 2 | Toggle again | Flips back |

---

#### TC-P17: Pagination Works (10 Per Page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 11+ records | Exist |
| 2 | Check pagination | Page 1: 10 records |

---

#### TC-P18: Records Ordered By Level Ascending

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create levels 2, 0, 1 in that order | 3 records |
| 2 | Navigate to list | Displayed as 0, 1, 2 (ascending) |

---

#### TC-P19: Empty State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate with no records | "No records found" |

---

### 6.2 Negative TC Steps

#### TC-N01: Required — Missing Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add New, leave level empty | Missing |
| 2 | Click "Save" | HTTP 500: "The level field is required." |

---

#### TC-N02: Required — Missing Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave code empty | Missing |
| 2 | Click "Save" | HTTP 500: "The code field is required." |

---

#### TC-N03: Required — Missing Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave name empty | Missing |
| 2 | Click "Save" | HTTP 500: "The name field is required." |

---

#### TC-N04: Invalid Level — Below 0 (Negative)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter level: -1 | Below min |
| 2 | Click "Save" | HTTP 500: "Level must be at least 0." |

---

#### TC-N05: Invalid Level — Above 9

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter level: 10 | Above max |
| 2 | Click "Save" | HTTP 500: "Level cannot exceed 9." |

---

#### TC-N06: Invalid Code — Exceeds 3 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code of 4 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500: "Code cannot exceed 3 characters." |

---

#### TC-N07: Invalid Name — Exceeds 150 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter name of 151 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500 |

---

#### TC-N08: Duplicate Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create level 0 | Exists |
| 2 | Create another level 0 | HTTP 500: "This level already exists." |

---

#### TC-N09: Duplicate Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with code="TOP" | Exists |
| 2 | Create another with code="TOP" | HTTP 500: "This code already exists." |

---

#### TC-N10: Duplicate Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with name="Root Topic" | Exists |
| 2 | Create another with same name | HTTP 500: "This name already exists." |

---

#### TC-N11: Non-Sequential First Level (Not 0)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No records exist | Empty table |
| 2 | Attempt to create level 1 (not 0) | HTTP 500: "The first level must be 0." |

---

#### TC-N12: Non-Sequential Subsequent Level (Skip)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Level 0 exists | Max level = 0 |
| 2 | Attempt to create level 2 (skipping 1) | HTTP 500: "Level must be 1 to maintain sequence. Current max level is 0." |

---

#### TC-N13: View Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open with invalid ID | HTTP 404 |

---

#### TC-N14: Edit/Update Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit with invalid ID | HTTP 404 |
| 2 | PUT to invalid ID | HTTP 404 |

---

#### TC-N15: Delete Record With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE to invalid ID | Redirect with error |

---

#### TC-N16: Toggle Status With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST toggle-status invalid ID | JSON 404 |

---

#### TC-N17: Restore Non-Deleted Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active record, try restore | 404 |

---

#### TC-N18: Force Delete Non-Trashed Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active record, try force delete | 404 |

---

#### TC-N19: Permission 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without permissions | 403 on all CRUD |

---

#### TC-N20: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate | Redirected to login |

---

#### TC-N21: XSS Injection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with XSS payload | Stored literal, not executed |

---

#### TC-N22: Whitespace-Only Name/Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Whitespace-only values | Validation fails |

---



---

#### TC-N24: Update Level To Non-Sequential Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Levels 0, 1, 2 exist | Max level = 2 |
| 2 | Edit level 1, change to level 5 (gap) | HTTP 500: "Level must be N to maintain sequence." |

---

### 6.3 Dependency TC Steps

#### TC-D01: Soft Delete Blocked — Topics Reference This Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create topic type level 0 | Exists |
| 2 | Create a topic referencing level 0 | Topic uses this level |
| 3 | Attempt to soft delete level 0 | Redirect with error: "Topic Type cannot be deleted because topics exist at this level or below." |
| 4 | DB check: deleted_at still NULL | Not deleted |

---

#### TC-D02: Force Delete Blocked — Topics Reference (RESTRICT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Topic type with topics at this level | Topics exist |
| 2 | Attempt force delete (even if soft-deleted) | FK RESTRICT prevents deletion |
| 3 | Delete referencing topics first | Then deletion succeeds |

---

#### TC-D03: Toggle Status — Inactive Record Hidden From Topic Creation Dropdown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active topic type | Active |
| 2 | Toggle to inactive | is_active = 0 |
| 3 | Navigate to topic create form | Inactive type NOT in level dropdown |
| 4 | Toggle back to active | Appears again |

---

#### TC-D04: Sequential Integrity After Soft Delete/Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create levels 0, 1 | Levels exist |
| 2 | Soft delete level 1 | Level 1 in trash |
| 3 | Attempt to create new level 1 | Succeeds (soft-deleted records excluded from unique check + sequential check uses max active level = 0, so new level must be 1) |

---

#### TC-D05: System-Protected Master Data — PG_Team Controlled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as school admin user | Dashboard loaded |
| 2 | Navigate to Syllabus → Syllabus Master → Topic Types | Page loads |
| 3 | Verify that Add New / Create button is hidden or disabled | School user cannot create topic level types |
| 4 | Verify that Edit actions on existing records are hidden or disabled | School user cannot edit topic level types |
| 5 | Verify that Delete actions on existing records are hidden or disabled | School user cannot delete topic level types |
| 6 | Verify that the page displays existing topic level types in read-only mode | Data viewable but not modifiable |

---

#### TC-D06: Unique Constraint — level, code, name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Connect to the application database | DB connection established |
| 2 | Insert a record with level=0, code='TOP', name='Root Topic' | Insert succeeds |
| 3 | Attempt to insert another record with level=0 | Integrity constraint violation: uq_topic_type_level |
| 4 | Attempt to insert another record with code='TOP' | Integrity constraint violation: uq_topic_type_code |
| 5 | Attempt to insert another record with name='Root Topic' | Integrity constraint violation: uq_topic_type_name |
| 6 | Insert a record with different level, code, and name | Insert succeeds |

---

#### TC-D07: FK RESTRICT — level_id Deletion Blocked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a topic level type with level=0 | Record exists |
| 2 | Create a topic in slb_topics referencing level_id of the created type | Topic exists with FK reference |
| 3 | Attempt to DELETE the topic level type directly at DB level | FK RESTRICT error thrown; deletion blocked |
| 4 | Verify the topic level type record still exists in the table | Record preserved |

---

#### TC-CR01: Model — $fillable Protects Against Mass Assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicLevelType` model source file | `$fillable` array visible |
| 2 | Verify `$fillable` contains: `'level'`, `'code'`, `'name'`, `'description'`, `'is_active'` | Exactly these 5 fields listed |
| 3 | Verify `$fillable` does NOT contain: `homework_release_flag`, `quiz_release_flag`, `quest_release_flag`, `id`, `created_at`, `updated_at`, `deleted_at` | Only intended fields mass-assignable |
| 4 | Attempt `TopicLevelType::create(['level' => 0, 'homework_release_flag' => 1])` via tinker | `homework_release_flag` silently ignored; record created with `homework_release_flag = NULL` |

---

#### TC-CR02: Model — $casts Ensures Type Integrity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicLevelType` model source file | `$casts` array visible |
| 2 | Verify `$casts` includes `'is_active' => 'boolean'` | is_active cast to boolean |
| 3 | Verify `$casts` includes `'level' => 'integer'` | level cast to integer |
| 4 | Create a record with `is_active = 1`, `level = 0` | Record saved |
| 5 | Retrieve record and call `dd($record->is_active, gettype($record->is_active), $record->level, gettype($record->level))` via tinker | `is_active` is `true` (boolean), `level` is `0` (integer) |

---

#### TC-CR03: Model — SoftDeletes Trait Correctly Implemented

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicLevelType` model source file | `use SoftDeletes;` present |
| 2 | Verify `deleted_at` column is nullable in migration | `$table->softDeletes()` or `timestamp('deleted_at')->nullable()` |
| 3 | Create a record, then soft delete it (`$record->delete()`) | `deleted_at` populated with timestamp |
| 4 | Query all records (`TopicLevelType::all()`) | Soft-deleted record excluded |
| 5 | Query with `TopicLevelType::withTrashed()->get()` | Soft-deleted record included |
| 6 | Query with `TopicLevelType::onlyTrashed()->get()` | Only soft-deleted record returned |

---

#### TC-CR04: Controller — Gate Authorization on Every Action

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicLevelTypeController` source file | Controller class visible |
| 2 | Check `index()` method | `Gate::authorize('tenant.topic-level-type.viewAny')` called before query |
| 3 | Check `create()` method | `Gate::authorize('tenant.topic-level-type.create')` called |
| 4 | Check `store()` method | `Gate::authorize('tenant.topic-level-type.create')` called |
| 5 | Check `show()` method | `Gate::authorize('tenant.topic-level-type.view')` called |
| 6 | Check `edit()` method | `Gate::authorize('tenant.topic-level-type.update')` called |
| 7 | Check `update()` method | `Gate::authorize('tenant.topic-level-type.update')` called |
| 8 | Check `destroy()` method | `Gate::authorize('tenant.topic-level-type.delete')` called |
| 9 | Check `toggleStatus()` method | `Gate::authorize('tenant.topic-level-type.status')` called |
| 10 | Check `trashed()` method | `Gate::authorize('tenant.topic-level-type.restore')` called |
| 11 | Check `restore()` method | `Gate::authorize('tenant.topic-level-type.restore')` called |
| 12 | Check `forceDelete()` method | `Gate::authorize('tenant.topic-level-type.forceDelete')` called |

---

#### TC-CR05: Controller — Activity Logged on All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a record via store() | Activity log entry with event `Created` and model details |
| 2 | Update the record via update() | Activity log entry with event `Updated` and changed attributes |
| 3 | Soft delete the record via destroy() | Activity log entry with event `Delete` |
| 4 | Restore the record via restore() | Activity log entry with event `Restored` |
| 5 | Force delete the record via forceDelete() | Activity log entry with event `Force Delete` |
| 6 | Toggle status via toggleStatus() | Activity log entry with event `Toggle Status` and status change detail |

---

#### TC-CR06: Controller — Destroy Sets is_active=false, Restore Sets is_active=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active record (`is_active = true`) | Record active |
| 2 | Soft delete the record | `is_active` set to `false` before `deleted_at` populated |
| 3 | DB check: record's `is_active` value | `0` (false) |
| 4 | Restore the record from trash | `is_active` set back to `true` |
| 5 | DB check: restored record's `is_active` value | `1` (true) |

---

#### TC-CR07: Request — Validation Rules Cover All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicLevelTypeRequest` source file | Validation rules visible |
| 2 | Verify `code` rule: `required|string|max:20|unique:slb_topic_level_types,code` | Rule defined |
| 3 | Verify `name` rule: `required|string|max:100` | Rule defined |
| 4 | Verify `level` rule: `nullable|integer` | Rule defined |
| 5 | Verify `description` rule: `nullable|string|max:255` | Rule defined |
| 6 | Verify `is_active` rule: `nullable|boolean` | Rule defined |
| 7 | Create with 21-char code | HTTP 500: code validation error |
| 8 | Create with 101-char name | HTTP 500: name validation error |
| 9 | Create with 256-char description | HTTP 500: description validation error |
| 10 | Create with non-integer level | HTTP 500: level validation error |

---

#### TC-CR08: Request — Unique Rule Ignores Current ID on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with `code='TOP', level=0, name='Root'` | Record exists |
| 2 | Open edit form for the same record | Form loads with existing data |
| 3 | Submit update with same `code='TOP'`, `level=0`, `name='Root'` (no changes) | Update succeeds; no duplicate error |
| 4 | Open `TopicLevelTypeRequest` source and check `rules()` method | When `$this->route('topic_level_type')` or `$this->method()` is PUT/PATCH, unique rules include `,{id}` ignore clause |

---

#### TC-CR09: Policy — All Required Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicLevelTypePolicy` source file | Policy class visible |
| 2 | Verify `viewAny()` method exists | Method defined with permission check |
| 3 | Verify `view()` method exists | Method defined with permission check |
| 4 | Verify `create()` method exists | Method defined with permission check |
| 5 | Verify `update()` method exists | Method defined with permission check |
| 6 | Verify `delete()` method exists | Method defined with permission check |
| 7 | Verify `restore()` method exists | Method defined with permission check |
| 8 | Verify `forceDelete()` method exists | Method defined with permission check |
| 9 | Verify `status()` method exists | Method defined with permission check |

---

#### TC-CR10: Policy — Permission Strings Match Route/Gate Names

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicLevelTypePolicy` and check `viewAny()` | Returns `$user->can('tenant.topic-level-type.viewAny')` |
| 2 | Check `view()` | Returns `$user->can('tenant.topic-level-type.view')` |
| 3 | Check `create()` | Returns `$user->can('tenant.topic-level-type.create')` |
| 4 | Check `update()` | Returns `$user->can('tenant.topic-level-type.update')` |
| 5 | Check `delete()` | Returns `$user->can('tenant.topic-level-type.delete')` |
| 6 | Check `restore()` | Returns `$user->can('tenant.topic-level-type.restore')` |
| 7 | Check `forceDelete()` | Returns `$user->can('tenant.topic-level-type.forceDelete')` |
| 8 | Check `status()` | Returns `$user->can('tenant.topic-level-type.status')` |
| 9 | Cross-reference with controller `Gate::authorize()` calls | Permission strings match exactly |

---

#### TC-CR11: Routes — Resourceful + Custom Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open route file (web.php or api.php) | Route definitions visible |
| 2 | Verify `Route::resource('topic-level-type', TopicLevelTypeController::class)` | Resourceful routes registered |
| 3 | Verify `GET /syllabus/topic-level-types` | Routes to `index` |
| 4 | Verify `POST /syllabus/topic-level-types` | Routes to `store` |
| 5 | Verify `GET /syllabus/topic-level-types/{topicLevelType}` | Routes to `show` |
| 6 | Verify `PUT|PATCH /syllabus/topic-level-types/{topicLevelType}` | Routes to `update` |
| 7 | Verify `DELETE /syllabus/topic-level-types/{topicLevelType}` | Routes to `destroy` |
| 8 | Verify `GET /syllabus/topic-level-types/trash/view` | Routes to `trashed` (custom) |
| 9 | Verify `POST /syllabus/topic-level-types/{topicLevelType}/restore` | Routes to `restore` (custom) |
| 10 | Verify `DELETE /syllabus/topic-level-types/{topicLevelType}/force-delete` | Routes to `forceDelete` (custom) |
| 11 | Verify `POST /syllabus/topic-level-types/{topicLevelType}/toggle-status` | Routes to `toggleStatus` (custom) |

---

#### TC-CR12: Routes — Route Model Binding Resolves 404 Automatically

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller methods: `show()`, `edit()`, `update()`, `destroy()`, `restore()`, `forceDelete()`, `toggleStatus()` | Each type-hints `TopicLevelType $topicLevelType` as parameter |
| 2 | Verify route parameter name `{topicLevelType}` matches model variable name `$topicLevelType` | Implicit binding works (or explicit `Route::model()` binding registered) |
| 3 | Send GET request to `/syllabus/topic-level-types/99999` (non-existent ID) | HTTP 404 returned |
| 4 | Send PUT request to non-existent ID | HTTP 404 returned |
| 5 | Send DELETE request to non-existent ID | HTTP 404 returned |
| 6 | Send POST toggle-status to non-existent ID | JSON HTTP 404 returned |

---

#### TC-CR13: Controller — Toggle Status Returns Consistent JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active record, send toggle-status POST | HTTP 200 |
| 2 | Inspect response body | `{"success": true, "is_active": false, "message": "Status updated successfully"}` shape |
| 3 | Toggle again | `{"success": true, "is_active": true, "message": "Status updated successfully"}` |
| 4 | Decode JSON and verify all 3 keys present | `success`, `is_active`, `message` keys exist |
| 5 | Toggle without permission | HTTP 403; JSON or error page |
| 6 | Toggle non-existent ID | HTTP 404; JSON `{"message": "Not Found"}` |

---

#### TC-CR14: Controller — CRUD Redirects Consistent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create new record via store() | Redirected to `syllabus.master.index?tab=topic_level_types` with success flash |
| 2 | Update existing record via update() | Redirected to same route with success flash |
| 3 | Soft delete record via destroy() | Redirected to same route with success flash |
| 4 | Restore record via restore() | Redirected to same route with success flash |
| 5 | Verify flash message type | Session has `success` flash message (e.g. "Topic Type created successfully.") |

---

#### TC-CR15: Database — Unique Indexes Match Request Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Connect to database and inspect `slb_topic_level_types` indexes | Indexes visible |
| 2 | Verify unique index on `level` column | `uq_topic_level_type_level` or `UNIQUE (level)` exists |
| 3 | Verify unique index on `code` column | `uq_topic_level_type_code` or `UNIQUE (code)` exists |
| 4 | Verify unique index on `name` column | `uq_topic_level_type_name` or `UNIQUE (name)` exists |
| 5 | Insert duplicate `level` directly in DB | Integrity constraint violation thrown |
| 6 | Insert duplicate `code` directly in DB | Integrity constraint violation thrown |
| 7 | Insert duplicate `name` directly in DB | Integrity constraint violation thrown |

#### TC-CR16: Request — prepareForValidation() Casts is_active via $this->boolean()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicLevelTypeRequest.php` | Request file loaded |
| 2 | Check `prepareForValidation()` method exists | Method defined in request class |
| 3 | Check implementation: `$this->merge(['is_active' => $this->boolean('is_active')])` | `$this->boolean()` call present, converts truthy/falsy input to boolean |
| 4 | Submit create with is_active = "1" (string) | `$this->boolean('is_active')` casts to true |
| 5 | Submit create with is_active = 0 (integer) | `$this->boolean('is_active')` casts to false |
| 6 | Submit create with is_active = "true" (string) | `$this->boolean('is_active')` casts to true |
| 7 | Submit create without is_active field | `$this->boolean('is_active')` returns false (default) |
| 8 | Verify merged value reaches validation | Validator receives boolean-typed is_active |

#### TC-D08: Quiz/Homework/Exam — Release Toggles Control Cross-Module Content Release

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Topic Level Types screen | Level types shown with release toggle columns |
| 2 | Verify Homework Release toggle exists | Boolean field for homework_release_flag |
| 3 | Verify Quiz Release toggle exists | Boolean field for quiz_release_flag |
| 4 | Verify Quest Release toggle exists | Boolean field for quest_release_flag |
| 5 | Verify Question Bank Tagging toggle exists | Boolean field for qbank_tagging_flag |
| 6 | Verify Exam Release toggle exists | Boolean field for exam_release_flag |
| 7 | Set Quiz Release=OFF for "Mini-Topic" level | Toggle saved |
| 8 | Try to create a Quiz scoped at Mini-Topic level | System should block or not offer Mini-Topic as an option |
