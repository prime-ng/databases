# slb_lessons_TcList

## Module: Syllabus → Syllabus Master → Lessons

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Syllabus Master |
| Feature | Lessons |
| URL(s) | `/syllabus/master` (index via tab), `/syllabus/lesson` (index/create), `/syllabus/lesson/{id}` (show), `/syllabus/lesson/{id}/edit` (edit), `/syllabus/lesson/trash/view` (trash), `/syllabus/lesson/{id}/restore` (restore), `/syllabus/lesson/{id}/force-delete` (forceDelete), `/syllabus/lesson/{lesson}/toggle-status` (toggleStatus), `/syllabus/lessons/check-duplicate` (checkDuplicate), `/syllabus/lessons/update-order` (updateOrder), `/syllabus/get-subject` (getSubject), `/syllabus/get/books` (getBooks), `/syllabus/get-teachers` (getClassTeachers), `/syllabus/lesson/validate-file` (validateImportFile), `/syllabus/lesson/start-import` (startImport) |
| Controller | `Modules\Syllabus\Http\Controllers\LessonController` |
| Model(s) | `Modules\Syllabus\Models\Lesson` |
| Validation (Create) | `Modules\Syllabus\Http\Requests\LessonRequest` (bulk array-based) |
| Validation (Update) | `Modules\Syllabus\Http\Requests\UpdateLessonRequest` (single record) |
| Permissions | `tenant.lesson.viewAny`, `tenant.lesson.view`, `tenant.lesson.create`, `tenant.lesson.update`, `tenant.lesson.delete`, `tenant.lesson.restore`, `tenant.lesson.forceDelete`, `tenant.lesson.status` |
| Soft Deletes | Yes (`Lesson` uses `SoftDeletes` trait) |
| Activity Log | Events: `Deleted`, `Restored`, `Force Delete`, `Toggle Status` |
| Import | Excel via `LessonImport` (heading row based, with validation, skip empty rows, skip duplicates) |

---

## 2. Pre-conditions

- Required permissions: `tenant.lesson.viewAny`, `tenant.lesson.view`, `tenant.lesson.create`, `tenant.lesson.update`, `tenant.lesson.delete`, `tenant.lesson.restore`, `tenant.lesson.forceDelete`, `tenant.lesson.status`
- Required seed data: At least one active `OrganizationAcademicSession`, one active `SchoolClass`, one active `Subject`, one active `BokBook`
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For import tests: A valid `.xlsx` or `.csv` file with columns: `lesson_number`, `lesson_name`, `code`, `short_name`, `periods`, `weightage_percent`, `nep_code`, `book_chapter`, `year_week`, `active`, `description`, `learning_objectives`, `prerequisite_lesson_ids`

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
| Lessons Grid | getLessons() | Lesson::with(class,subject) | search(name,code), filters(class_id,subject_id,academic_session_id,bok_books_id) | 10/page (lessons_page) |
## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Lesson code**: Uppercase alphanumeric + suffix, max 20 chars, globally unique
- **Lesson name**: String max 150 chars, unique within `(academic_session_id, class_id, subject_id)` scope
- **Ordinal**: Positive integer min 1, unique within `(academic_session_id, class_id, subject_id)` scope
- **Bulk create**: `store()` accepts `lessons[]` array — each entry is one lesson row
- **UUID**: Auto-generated `Str::uuid()->getBytes()` on create (binary 16)
- **Pre-test cleanup**: Delete created lessons by code before/after tests to avoid collisions
- **JSON fields**: `learning_objectives`, `prerequisites`, `resources_json` stored as JSON in DB, cast to array by model
- **Activity log cleanup**: Records cleaned up after force-delete tests

---

## 5. Business Conditions

### 4.1 Database Schema — `slb_lessons`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | uuid | BINARY(16) | NOT NULL, UNIQUE |
| BC-DB-03 | academic_session_id | INT UNSIGNED | NOT NULL, FK → `sch_org_academic_sessions_jnt.id`, ON DELETE RESTRICT |
| BC-DB-04 | class_id | INT UNSIGNED | NOT NULL, FK → `sch_classes.id`, ON DELETE CASCADE |
| BC-DB-05 | subject_id | INT UNSIGNED | NOT NULL, FK → `sch_subjects.id`, ON DELETE CASCADE |
| BC-DB-06 | bok_books_id | INT UNSIGNED | NOT NULL, FK → `slb_books.id` (validated but no DDL FK shown) |
| BC-DB-07 | code | VARCHAR(20) | NOT NULL, UNIQUE |
| BC-DB-08 | name | VARCHAR(150) | NOT NULL, UNIQUE `(class_id, subject_id, name)` |
| BC-DB-09 | short_name | VARCHAR(50) | DEFAULT NULL |
| BC-DB-10 | ordinal | SMALLINT UNSIGNED | NOT NULL, indexed |
| BC-DB-11 | description | VARCHAR(255) | DEFAULT NULL |
| BC-DB-12 | learning_objectives | JSON | DEFAULT NULL (cast to array) |
| BC-DB-13 | prerequisites | JSON | DEFAULT NULL (cast to array) |
| BC-DB-14 | estimated_periods | SMALLINT UNSIGNED | DEFAULT NULL |
| BC-DB-15 | weightage_in_subject | DECIMAL(5,2) | DEFAULT NULL |
| BC-DB-16 | nep_alignment | VARCHAR(100) | DEFAULT NULL |
| BC-DB-17 | resources_json | JSON | DEFAULT NULL (cast to array) |
| BC-DB-18 | book_chapter_ref | VARCHAR(100) | DEFAULT NULL |
| BC-DB-19 | scheduled_year_week | INT UNSIGNED | DEFAULT NULL (format YYYYWW) |
| BC-DB-20 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 (cast to boolean) |
| BC-DB-21 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-22 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-23 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules — `LessonRequest` (Create, Bulk)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | academic_session_id | required, integer, exists:sch_org_academic_sessions_jnt,id | — |
| BC-VAL-02 | class_id | required, integer, exists:sch_classes,id | — |
| BC-VAL-03 | subject_id | required, integer, exists:sch_subjects,id | — |
| BC-VAL-04 | bok_books_id | required, integer, exists:slb_books,id | "Book is required." |
| BC-VAL-05 | lessons | required, array, min:1 | — |
| BC-VAL-06 | lessons.*.name | required, string, max:150, **inline unique scoped** (academic_session_id, class_id, subject_id) | "The lesson '{value}' already exists..." |
| BC-VAL-07 | lessons.*.code | required, string, max:20, **inline unique global** | "The code '{value}' already exists..." |
| BC-VAL-08 | lessons.*.ordinal | required, integer, min:1, **inline unique scoped** | "The order number '{value}' is already used by..." |
| BC-VAL-09 | lessons.*.short_name | nullable, string, max:50 | — |
| BC-VAL-10 | lessons.*.description | nullable, string, max:255 | — |
| BC-VAL-11 | lessons.*.learning_objectives | nullable, string | — |
| BC-VAL-12 | lessons.*.prerequisites | nullable, string | — |
| BC-VAL-13 | lessons.*.estimated_periods | nullable, integer, min:1 | — |
| BC-VAL-14 | lessons.*.weightage_in_subject | nullable, numeric, min:0, max:100 | — |
| BC-VAL-15 | lessons.*.nep_alignment | nullable, string, max:100 | — |
| BC-VAL-16 | lessons.*.book_chapter_ref | nullable, string, max:100 | — |
| BC-VAL-17 | lessons.*.scheduled_year_week | nullable, integer, min:202001, max:210052 | — |
| BC-VAL-18 | lessons.*.is_active | nullable, boolean | — |
| BC-VAL-19 | lessons.*.resources | nullable, array | — |
| BC-VAL-20 | lessons.*.resources.*.type | required, string, in:video,pdf,link,document,image,audio,ppt | "Invalid resource type..." |
| BC-VAL-21 | lessons.*.resources.*.title | required, string, max:200 | "Resource title must not exceed 200 characters." |
| BC-VAL-22 | lessons.*.resources.*.url | required, url, max:500 | "Resource URL must be a valid URL." |
| BC-VAL-23 | lessons.*.resources.*.description | nullable, string, max:500 | — |

### 4.3 Validation Rules — `UpdateLessonRequest` (Single Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | academic_session_id | required, integer, exists:sch_org_academic_sessions_jnt,id | — |
| BC-VAL-U02 | class_id | required, integer, exists:sch_classes,id | — |
| BC-VAL-U03 | subject_id | required, integer, exists:sch_subjects,id | — |
| BC-VAL-U04 | bok_books_id | required, integer, exists:slb_books,id | "The Book selection is required." |
| BC-VAL-U05 | name | required, string, max:150, `Rule::unique` scoped + `ignore($lessonId)` + `whereNull('deleted_at')` | "A lesson with this name already exists..." |
| BC-VAL-U06 | code | required, string, max:20, `Rule::unique` global + `ignore($lessonId)` + `whereNull('deleted_at')` | "This lesson code is already in use." |
| BC-VAL-U07 | ordinal | required, integer, min:1, `Rule::unique` scoped + `ignore($lessonId)` + `whereNull('deleted_at')` | "This order number is already assigned..." |
| BC-VAL-U08 | short_name | nullable, string, max:50 | — |
| BC-VAL-U09 | description | nullable, string, max:255 | — |
| BC-VAL-U10 | learning_objectives | nullable, string | — |
| BC-VAL-U11 | prerequisites | nullable, array | — |
| BC-VAL-U12 | prerequisites.* | integer, exists:slb_lessons,id | — |
| BC-VAL-U13 | estimated_periods | nullable, integer, min:1 | — |
| BC-VAL-U14 | weightage_in_subject | nullable, numeric, min:0, max:100 | — |
| BC-VAL-U15 | nep_alignment | nullable, string, max:100 | — |
| BC-VAL-U16 | book_chapter_ref | nullable, string, max:100 | — |
| BC-VAL-U17 | scheduled_year_week | nullable, integer, min:202001, max:210052 | — |
| BC-VAL-U18 | is_active | nullable, boolean | — |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.lesson.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.lesson.view | show(), view() | Without → 403 |
| BC-AUTH-03 | tenant.lesson.create | store(), create() | Without → 403 |
| BC-AUTH-04 | tenant.lesson.update | update(), edit(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.lesson.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.lesson.restore | restore(), trashed() | Without → 403 |
| BC-AUTH-07 | tenant.lesson.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.lesson.status | toggleStatus() (via update gate) | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Bulk store via `lessons[]` array | Multiple lessons created in single DB transaction |
| BC-BIZ-02 | Ordinal auto-shift on reorder | `updateOrder()` accepts `order[{id, ordinal}]` and updates each ordinal |
| BC-BIZ-03 | Default is_active | Defaults to true when creating (prepareForValidation casts, model default 1) |
| BC-BIZ-04 | Code auto-uppercase | `strtoupper(trim($code))` applied in both store and update |
| BC-BIZ-05 | Name trimming | `trim($lessonData['name'])` in store, `trim($request->name)` in update |
| BC-BIZ-06 | JSON objectives storage | `learning_objectives` stored as `{"learning_objectives": "..."}` in store; direct JSON array in update |
| BC-BIZ-07 | JSON prerequisites storage | `prerequisites` stored as `{"prerequisites": "..."}` in store; direct JSON array in update |
| BC-BIZ-08 | Soft delete cascades | `booted()` deleting event cascades to `topics`, `syllabusSchedules`, `examScopes` |
| BC-BIZ-09 | Force delete blocked by exam scopes | If `examScopes()->exists()`, return error message |
| BC-BIZ-10 | Force delete blocked by questions | If `QuestionBank::where('lesson_id', $id)->count() > 0`, return error with count |
| BC-BIZ-11 | Duplicate check AJAX | `checkDuplicate()` returns JSON `{exists: true/false}` for name/code/ordinal |
| BC-BIZ-12 | Import file validation | `validateImportFile()` pre-validates each row, returns error file on failure |
| BC-BIZ-13 | Import session storage | Validated file stored in `storage/app/public/imports/`, filters in session |
| BC-BIZ-14 | Import execution | `startImport()` reads session file, runs `LessonImport`, returns create/skip counts |
| BC-BIZ-15 | Activity log — Deleted | On soft delete |
| BC-BIZ-16 | Activity log — Restored | On restore |
| BC-BIZ-17 | Activity log — Force Delete | On force delete |
| BC-BIZ-18 | Activity log — Toggle Status | On status toggle |
| BC-BIZ-19 | Status toggle | `is_active` flips via `$lesson->is_active = !$lesson->is_active` |
| BC-BIZ-20 | Resources_json on store | Nested payload: `resources_json = {class_id, subject_id, estimated_periods, nep_alignment, book_chapter_ref, scheduled_year_week}` |
| BC-BIZ-21 | UUID auto-generation | `Str::uuid()->getBytes()` on every create |
| BC-BIZ-22 | Import auto-code generation | Empty code → `'C' + class_id + '-S' + subject_id + '-L' + ordinal` |
| BC-BIZ-23 | Import UTF-8 sanitization | `sanitize()` method handles non-UTF8 encoding conversion |
| BC-BIZ-24 | Screen loads via SyllabusController@master() at GET /syllabus/master with master tab group | Navigating to GET /syllabus/master with appropriate permissions loads the Master tab group; this screen's grid data is fetched and displayed |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | academic_session_id | sch_org_academic_sessions_jnt (id) | RESTRICT |
| BC-REF-02 | class_id | sch_classes (id) | CASCADE |
| BC-REF-03 | subject_id | sch_subjects (id) | CASCADE |
| BC-REF-04 | bok_books_id | slb_books (id) | Not declared in DDL (validated in request) |
| BC-REF-05 | lesson_id (in slb_topics) | slb_lessons (id) | CASCADE |
| BC-REF-06 | lesson_id (in slb_syllabus_schedules) | slb_lessons (id) | Not shown |
| BC-REF-07 | lesson_id (in lms_exam_scopes) | slb_lessons (id) | Not shown |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Lessons List Page Loads With All UI Elements | Page loads with class/subject filter, search, Add Lesson button, Trash button, table, pagination | — | — | ⬜ |
| TC-P02 | Filter Lessons By Class + Subject | Table shows only lessons matching selected class and subject | — | — | ⬜ |
| TC-P03 | Search Lessons By Name Or Code | Table filters to show only matching lessons by name or code | — | — | ⬜ |
| TC-P04 | Filter By Active/Inactive Status | Active filter shows only active lessons; Inactive shows only inactive | — | — | ⬜ |
| TC-P05 | Create Single Lesson With All Required Fields | Lesson created with correct values in DB — name, code, ordinal, bok_books_id | — | — | ⬜ |
| TC-P06 | Create Multiple Lessons In One Request (Bulk) | 3 lessons created in single transaction, each with unique code and ordinal | — | — | ⬜ |
| TC-P07 | Create Lesson With All Optional Fields | Short name, description, learning objectives, estimated periods, weightage, NEP alignment, book chapter ref, year week, resources all saved correctly | — | — | ⬜ |
| TC-P08 | Create Lesson With Resources (Video, PDF, Link) | Resources array validated and stored in `resources_json` | — | — | ⬜ |
| TC-P09 | Create Lesson Without Ordinal (Defaults) | Ordinal = min:1 validation applies; cannot be empty (required rule) | — | — | ⬜ |
| TC-P10 | Edit Lesson Loads Pre-Filled Data | Edit page shows existing lesson data in form fields | — | — | ⬜ |
| TC-P11 | Update Lesson All Fields | Name, code, ordinal, short_name, description, estimated_periods, weightage, is_active all updated | — | — | ⬜ |
| TC-P12 | Update Lesson — Change Book Mapping | `bok_books_id` updated to new valid book | — | — | ⬜ |
| TC-P13 | View Lesson Details Page | Lesson details shown with name, code, ordinal, class, subject, book, status, description, objectives | — | — | ⬜ |
| TC-P14 | Soft Delete Lesson | `deleted_at` set; lesson no longer visible on main list | — | — | ⬜ |
| TC-P15 | Trash Page Shows Deleted Lessons | `/syllabus/lesson/trash/view` lists only soft-deleted lessons with restore + force delete buttons | — | — | ⬜ |
| TC-P16 | Restore Lesson From Trash | `deleted_at` set to NULL; lesson visible on main list again; activity log "Restored" | — | — | ⬜ |
| TC-P17 | Force Delete Lesson (No Dependencies) | Record permanently removed; activity log "Force Delete" | — | — | ⬜ |
| TC-P18 | Toggle Status Active ↔ Inactive | `is_active` flips value; AJAX 200 with success message | — | — | ⬜ |
| TC-P19 | Update Lesson Order (Drag Reorder) | Ordinals updated correctly for all affected lessons | — | — | ⬜ |
| TC-P20 | AJAX Duplicate Check — Name Available | Returns `{exists: false}` when name is unique within scope | — | — | ⬜ |
| TC-P21 | AJAX Duplicate Check — Code Available | Returns `{exists: false}` when code is globally unique | — | — | ⬜ |
| TC-P22 | AJAX Duplicate Check — Ordinal Available | Returns `{exists: false}` when ordinal is unique within scope | — | — | ⬜ |
| TC-P23 | Get Subjects By Class ID | Returns JSON list of subjects linked to selected class | — | — | ⬜ |
| TC-P24 | Get Books By Class + Subject | Returns JSON list of books linked to selected class and subject | — | — | ⬜ |
| TC-P25 | Get Class Teachers | Returns JSON list of teachers assigned to selected class | — | — | ⬜ |
| TC-P26 | Import — Validate Valid File | Returns JSON with `status=success`, passed row count, file path | — | — | ⬜ |
| TC-P27 | Import — Execute Import After Validation | Lessons created from file rows; `createdCount` matches passed rows | — | — | ⬜ |
| TC-P28 | Import — Auto-Code Generation When Code Empty | Code auto-generated as `C{class_id}-S{subject_id}-L{ordinal}` | — | — | ⬜ |
| TC-P29 | Full Lifecycle: Create → Edit → Toggle → Delete → Trash → Restore → Force Delete | All 7 transitions successful; activity logged at Delete, Restore, Force Delete, Toggle Status | — | — | ⬜ |
| TC-P30 | Empty State — No Class/Subject Filter Selected | Table shows prompt message "Select a class and subject to view lessons"; Add Lesson button disabled | — | — | ⬜ |
| TC-P31 | Empty State — No Lessons For Selected Filter | Table shows "No lessons found for the selected class and subject" message; Add Lesson button visible | — | — | ⬜ |
| TC-P32 | Add/Remove Prerequisite Lessons Via Edit | Prerequisites updated successfully; view page shows linked prerequisites | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Empty `lessons` Array | Validation error: validation fails for missing `lessons` array | — | — | ⬜ |
| TC-N02 | Required — Missing Name In Lesson Row | Validation error: "Lesson name is required" (lessons.*.name.required) | — | — | ⬜ |
| TC-N03 | Required — Missing Code In Lesson Row | Validation error: "Lesson code is required" | — | — | ⬜ |
| TC-N04 | Required — Missing `bok_books_id` | Validation error: "Book is required." | — | — | ⬜ |
| TC-N05 | Required — Missing `academic_session_id` / `class_id` / `subject_id` | Validation error for each missing required FK field | — | — | ⬜ |
| TC-N06 | Duplicate Lesson Name Within Scope | "The lesson '{name}' already exists for the selected academic session, class and subject." | — | — | ⬜ |
| TC-N07 | Duplicate Lesson Code (Global) | "The code '{code}' already exists in the database." | — | — | ⬜ |
| TC-N08 | Duplicate Ordinal Within Scope | "The order number '{ordinal}' is already used by '{lesson}'..." | — | — | ⬜ |
| TC-N09 | Max Length — Name > 150 Characters | Validation fails on lessons.*.name.max | — | — | ⬜ |
| TC-N10 | Max Length — Code > 20 Characters | Validation fails on lessons.*.code.max | — | — | ⬜ |
| TC-N11 | Invalid Ordinal — 0 or Negative | Validation fails on lessons.*.ordinal.min (must be >= 1) | — | — | ⬜ |
| TC-N12 | Invalid Weightage — Negative Or > 100 | Validation fails on lessons.*.weightage_in_subject.min/max | — | — | ⬜ |
| TC-N13 | Invalid `scheduled_year_week` — Below 202001 Or Above 210052 | Validation fails on lessons.*.scheduled_year_week.min/max | — | — | ⬜ |
| TC-N14 | Invalid FK — Non-Existent `class_id` | Validation error: "The selected class is invalid." | — | — | ⬜ |
| TC-N15 | Invalid FK — Non-Existent `bok_books_id` | Validation error: "The selected bok books id is invalid." | — | — | ⬜ |
| TC-N16 | View Lesson With Invalid ID (404) | 404 error: "Lesson not found" | — | — | ⬜ |
| TC-N17 | Edit/Update Lesson With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N18 | Delete Lesson With Invalid ID (404) | 404 error: "Lesson not found" | — | — | ⬜ |
| TC-N19 | Toggle Status With Invalid ID (404) | JSON 404: `{success: false, message: "Lesson not found"}` | — | — | ⬜ |
| TC-N20 | Restore Non-Deleted Lesson (Already Active) | `onlyTrashed()->find()` returns null → 404 | — | — | ⬜ |
| TC-N21 | Force Delete Non-Trashed Lesson | `onlyTrashed()->find()` returns null → 404 | — | — | ⬜ |
| TC-N22 | Permission 403 — No Lesson Permissions | 403 Forbidden on all CRUD endpoints for user without `tenant.lesson.*` gates | — | — | ⬜ |
| TC-N23 | Guest Access Redirect | Redirected to /login for all lesson routes | — | — | ⬜ |
| TC-N24 | XSS Injection In Name/Code | Stored as literal string; Blade `{{ }}` escapes output; no script execution | — | — | ⬜ |
| TC-N25 | Whitespace-Only Name/Code | Required validation catches empty/whitespace-only strings | — | — | ⬜ |
| TC-N26 | Duplicate Code Within Same Request (Bulk) | Inline validation catches duplicate codes submitted in same `lessons[]` array | — | — | ⬜ |
| TC-N27 | Duplicate Ordinal Within Same Request (Bulk) | Inline validation catches duplicate ordinals submitted in same `lessons[]` array | — | — | ⬜ |
| TC-N28 | Resources — Invalid Type | Validation error: "Invalid resource type. Allowed: video, pdf, link, document, image, audio, ppt." | — | — | ⬜ |
| TC-N29 | Resources — Invalid URL | Validation error: "Resource URL must be a valid URL." | — | — | ⬜ |
| TC-N30 | Import — Invalid File Type (Not XLSX/CSV) | Validation error: "The file must be a file of type: xlsx, csv." | — | — | ⬜ |
| TC-N31 | Import — File With Duplicate Ordinals | Error rows generated: "Duplicate ordinal for selected filters" | — | — | ⬜ |
| TC-N32 | Import — File With Duplicate Codes | Error rows generated: "Duplicate code already exists" | — | — | ⬜ |
| TC-N33 | Import — Start Import Without Validated File | JSON error: "No validated file found" | — | — | ⬜ |
| TC-N34 | Invalid Estimated Periods — Zero Or Negative | Validation error: "Estimated periods must be at least 1." | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Soft-Delete Lesson — Topics Cascade Deleted | All child topics soft-deleted via `booted()` deleting event | — | — | ⬜ |
| TC-D02 | A | Soft-Delete Lesson — Syllabus Schedules Cascade Deleted | Syllabus schedules soft-deleted via `booted()` deleting event | — | — | ⬜ |
| TC-D03 | A | Soft-Delete Lesson — Exam Scopes Cascade Deleted | Exam scopes soft-deleted via `booted()` deleting event | — | — | ⬜ |
| TC-D04 | B | Restore Lesson — Topics Remain Deleted | `restore()` only restores lesson, not child topics (no cascading restore) | — | — | ⬜ |
| TC-D05 | C | Force Delete Blocked — Exam Scopes Exist | Error message: "This lesson cannot be deleted because it is linked with exam scopes." | — | — | ⬜ |
| TC-D06 | C | Force Delete Blocked — Questions Reference Lesson | Error message: "This lesson cannot be deleted because it is referenced by {count} question(s)." | — | — | ⬜ |
| TC-D07 | D | Cannot Delete Academic Session While Lesson References It (RESTRICT) | FK constraint error when trying to delete referenced academic_session | — | — | ⬜ |
| TC-D08 | D | Class Deletion Cascades To Lessons (CASCADE) | Deleting a class automatically deletes all its lessons | — | — | ⬜ |
| TC-D09 | D | Subject Deletion Cascades To Lessons (CASCADE) | Deleting a subject automatically deletes all its lessons | — | — | ⬜ |
| TC-D10 | E | Import Flow — Validate Then Execute | After successful validation, `startImport()` creates lessons from stored file | — | — | ⬜ |
| TC-D11 | E | Import Flow — Validation Failure Stops Import | On validation errors, error file is returned; no import started | — | — | ⬜ |
| TC-D12 | F | Toggle Status — Inactive Lesson Hidden From Dropdowns | Inactive lesson excluded from prerequisite selection and other dropdowns | — | — | ⬜ |
| TC-D13 | F | Update `academic_session_id` On Lesson | Lesson moves to new academic session (FK must exist) | — | — | ⬜ |
| TC-D14 | G | Concurrent Update — Two Users Edit Same Lesson | Last save wins; no data corruption | — | — | ⬜ |
| TC-D15 | G | Rapid Status Toggle (Race Condition) | Handles rapid toggles without data corruption | — | — | ⬜ |
| TC-D16 | G | Same Ordinal Allowed For Different (Class, Subject) Scopes | Two lessons in different class/subject can share same ordinal | — | — | ⬜ |
| TC-D17 | G | Same Name Allowed For Different (Class, Subject) Scopes | Two lessons in different class/subject can share same name | — | — | ⬜ |
| TC-D20 | J | DB | P1 | slb_lessons with existing lesson record | Composite Unique Constraint — uq_lesson_class_subject_name (class_id + subject_id + name) | Inserting duplicate (class_id, subject_id, name) combination at DB level throws integrity constraint violation | — | — | ⬜ |
| TC-D21 | K | DB | P1 | slb_lessons with existing lesson record | Binary(16) UUID Format Validation — uuid Column | uuid stores 16-byte binary; auto-generated via Str::uuid()->getBytes(); unique constraint uq_lesson_uuid enforced at DB level | — | — | ⬜ |
| TC-D22 | L | Integration | P1 | Lesson with child topics, syllabus schedules, and exam scopes | Multi-Level Cascade Chain — Lesson → Topics → Dependents | Force-deleting a lesson cascades to: topics (soft delete), syllabus_schedule records, exam_scope records; class deletion cascades to lessons (DDL CASCADE) | — | — | ⬜ |
| TC-D23 | M | DB | P1 | slb_lessons referencing non-existent academic_session_id | FK RESTRICT — academic_session_id Deletion Blocked | Attempting to delete an academic session that has lesson references throws FK RESTRICT error; lessons must be deleted first | — | — | ⬜ |
| TC-D24 | N | UI/API | P1 | Lesson with estimated_periods as SMALLINT UNSIGNED | SMALLINT UNSIGNED Boundary — estimated_periods | estimated_periods rejects values > 65535 (SMALLINT UNSIGNED max) and negative values; boundary values 0, 1, 65535 handled correctly | — | — | ⬜ |
| TC-D25 | O | Unit | P1 | LessonController code inspection | Code Review: Model Table Name | Model `Lesson` has `protected $table = 'slb_lessons'` matching DB table | — | — | ⬜ |
| TC-D26 | P | Unit | P1 | LessonController code inspection | Code Review: Model Fillable | `Lesson` model $fillable includes: name, code, class_id, subject_id, academic_session_id, description, duration_minutes, is_active, bok_books_id, ordinal, lesson_type | — | — | ⬜ |
| TC-D27 | Q | Unit | P1 | LessonController code inspection | Code Review: SoftDeletes Trait | `Lesson` model uses `SoftDeletes` trait; `deleted_at` column exists in migration | — | — | ⬜ |
| TC-D28 | R | Unit | P1 | LessonController code inspection | Code Review: Model Relationships | `Lesson` model has `belongsTo` for class, subject, academicSession; `hasMany` for topics, schedules | — | — | ⬜ |
| TC-D29 | S | Unit | P1 | LessonController code inspection | Code Review: $casts Definition | `Lesson` model has `$casts` for `is_active` as boolean and `duration_minutes` as integer | — | — | ⬜ |
| TC-D30 | T | Unit | P1 | LessonController store/update/destroy methods | Code Review: findOrFail Usage | Controller uses `Lesson::findOrFail($id)` in edit, update, show, destroy — returns 404 when record not found | — | — | ⬜ |
| TC-D31 | U | Unit | P1 | LessonController store/update/destroy methods | Code Review: Gate Authorization | `Gate::authorize('tenant.lesson.create')` before store; `Gate::authorize('tenant.lesson.update')` before update; `Gate::authorize('tenant.lesson.delete')` before destroy | — | — | ⬜ |
| TC-D32 | V | Unit | P1 | LessonController store/update/destroy methods | Code Review: activityLog After CRUD | `activityLog()` called after store, update, destroy, restore, forceDelete with appropriate action type | — | — | ⬜ |
| TC-D33 | W | Unit | P1 | LessonController destroy method | Code Review: is_active Toggle Before Delete | `destroy()` sets `is_active = false` before calling `delete()` on the model | — | — | ⬜ |
| TC-D34 | X | Unit | P1 | LessonRequest validation rules | Code Review: Unique Validation | `LessonRequest` has `unique:slb_lessons` validation on code field (with ignore ID on update) | — | — | ⬜ |
| TC-D35 | Y | Unit | P1 | LessonRequest validation rules | Code Review: Required Validation | Required validation rules exist for `name`, `class_id`, `subject_id`; nullable for `description` | — | — | ⬜ |
| TC-D36 | Z | Unit | P1 | LessonRequest validation rules | Code Review: Max Length Validation | Max length rules: name:100, code:20, description:255 | — | — | ⬜ |
| TC-D37 | AA | Unit | P1 | LessonRequest validation rules | Code Review: Boolean Validation | `is_active` field has `boolean` validation rule | — | — | ⬜ |
| TC-D38 | AB | Unit | P1 | LessonPolicy code inspection | Code Review: Permission Gates | `LessonPolicy` defines viewAny, view, create, update, delete, restore, forceDelete, status gates | — | — | ⬜ |
| TC-D39 | AC | Unit | P1 | Routes file code inspection | Code Review: Resource + Additional Routes | Routes include resource routes + trashed, restore, forceDelete, toggleStatus for lesson | — | — | ⬜ |
| TC-D40 | AD | Cross-Module | P1 | Exam Module — lms_exam_scopes FK References slb_lessons.id | `lms_exam_scopes` table has FK referencing `slb_lessons.id`; deleting a lesson with existing exam scopes is blocked by FK constraint | — | — | ⬜ |
| TC-D41 | AE | Cross-Module | P1 | Question Bank — qbank_question_banks FK References lesson_id | `qbank_question_banks` table has FK referencing `lesson_id`; LessonController@destroy() checks Question Bank references before forceDelete; if question bank entries reference this lesson, deletion is blocked | — | — | ⬜ |
| TC-D42 | AF | Import — UTF-8 Sanitization of Non-UTF8 Characters | Import CSV with non-UTF8 characters → `sanitize()` converts them to valid UTF-8; no data loss or encoding errors | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.lesson.create'), @can('tenant.lesson.edit'), @can('tenant.lesson.delete'), @can('tenant.lesson.status'), @can('tenant.lesson.view'), @canany(['tenant.lesson.restore', 'tenant.lesson.forceDelete']) for access control on all CRUD buttons and actions | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | `syllabus.master` key → `'syllabus/master'` defined in `config/breadcrumb.php`; breadcrumb visible and links correctly to parent screen | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — try-catch Exception Handling on All CRUD Methods | All state-changing methods (store, update, destroy, restore, forceDelete) use try-catch; exceptions are caught, logged, and user receives error feedback; no unhandled \Exception causes 500 | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — DB Transactions on Multi-Step Writes | Methods performing multiple DB operations (create+activityLog, destroy+is_active toggle) use DB::transaction() or beginTransaction/commit/rollback; partial writes do not occur on failure | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Relationship expressions in Blade use isset($var->relation) / optional($var?->relation) / null-safe operator; no undefined index/property errors when relation is null | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | View — Success Flash Messages After Create/Update/Delete | After CRUD actions, controller redirects with success flash; Blade displays success alert with correct action-specific message | — | — | ◌ |


---



## 7. Detailed Test Steps



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
| 1 | Inspect index.blade.php for add/create button | @can('tenant.lesson.create') wraps the Add New button; user without create permission does not see it
| 2 | Inspect row-level action buttons (view, edit, delete, status toggle) | @can('tenant.lesson.view'), @can('tenant.lesson.edit'), @can('tenant.lesson.delete'), @can('tenant.lesson.status') used appropriately; expired permissions hide corresponding buttons
| 3 | Inspect trash.blade.php for restore/forceDelete buttons | @canany(['tenant.lesson.restore', 'tenant.lesson.forceDelete']) wraps action buttons in trash view
| 4 | Inspect view.blade.php for edit button | @can('tenant.lesson.edit') wraps the Edit button on show/details page
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

#### TC-P01: Lessons List Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Expand "Syllabus" from left sidebar | Menu options appear |
| 3 | Click "Syllabus Master" and select "Lessons" tab | Page loads at `/syllabus/lesson` |
| 4 | Check the class filter dropdown | Dropdown with list of active classes present |
| 5 | Check the subject filter dropdown | Dropdown with list of active subjects present |
| 6 | Check the search input | Search text field with placeholder present |
| 7 | Check the status filter | Dropdown with options: "All", "Active", "Inactive" |
| 8 | Check the "Add Lesson" button | Green/blue button visible (if create permission) |
| 9 | Check the "Trash" button | Trash button visible (if restore permission) |
| 10 | Check the lessons table | Columns: Name, Code, Ordinal, Class, Subject, Status, Actions |
| 11 | Check pagination | If 10+ lessons exist, pagination links appear |

---

#### TC-P02: Filter Lessons By Class + Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 lessons in Class A / Subject X | Lessons exist |
| 2 | Create 1 lesson in Class B / Subject Y | Lesson exists |
| 3 | Select Class A from class dropdown | Page reloads with `?class_id={A_id}` |
| 4 | Verify table shows only Class A lessons | 2 lessons visible, Class B lesson not shown |
| 5 | Also select Subject X from subject dropdown | Page reloads with both filters |
| 6 | Verify only Class A + Subject X lessons shown | Only matching lesson(s) visible |
| 7 | Clear both filters | All 3 lessons visible again |

---

#### TC-P03: Search Lessons By Name Or Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lessons: "Algebra" (code="ALG"), "Geometry" (code="GEO"), "Trigonometry" (code="TRI") | 3 lessons exist |
| 2 | Type "Alge" in search box and press Enter | Page reloads with `?search=Alge` |
| 3 | Verify table shows only "Algebra" | Other 2 lessons not visible |
| 4 | Clear search, type "GEO" | Only "Geometry" shown (matched by code) |
| 5 | Clear search | All 3 lessons visible again |

---

#### TC-P04: Filter By Active/Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active lesson "ActiveOne" (is_active=1) and inactive lesson "InactiveOne" (is_active=0) | Both exist |
| 2 | Select "Active" from status filter | Only "ActiveOne" visible |
| 3 | Select "Inactive" from filter | Only "InactiveOne" visible |
| 4 | Select "All" | Both lessons visible |

---

#### TC-P05: Create Single Lesson With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Syllabus Master → Lessons tab | Page loads |
| 2 | Click "Add Lesson" button | Lesson form opens (inline or modal) |
| 3 | Select an academic session from dropdown | Session selected |
| 4 | Select a class from dropdown | Class selected |
| 5 | Select a subject from dropdown | Subject selected |
| 6 | Select a book from dropdown (`bok_books_id`) | Book selected |
| 7 | Enter name: "Chapter 1: Algebra Basics" | Field filled |
| 8 | Enter code: "9TH_MATH_L01" | Field filled |
| 9 | Enter ordinal: "1" | Field filled |
| 10 | Click "Save" / "Submit" | AJAX POST to `/syllabus/lesson` (bulk `lessons[0]` payload) |
| 11 | Check response | Success: "Lessons created successfully." |
| 12 | Redirect to master index with `tab=lesson` | Page reloads, lesson visible in table |
| 13 | DB check: `SELECT * FROM slb_lessons WHERE code='9TH_MATH_L01'` | Record exists with all required fields, `uuid` populated, `is_active=1` |

---

#### TC-P06: Create Multiple Lessons In One Request (Bulk)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add Lesson" button | Form opens |
| 2 | Select session, class, subject, book | Filter fields set |
| 3 | In the lessons table, add 3 rows: (name="Lesson A", code="LEC_A", ordinal=1), (name="Lesson B", code="LEC_B", ordinal=2), (name="Lesson C", code="LEC_C", ordinal=3) | 3 lesson rows entered |
| 4 | Click "Save" | POST to store with `lessons[0]`, `lessons[1]`, `lessons[2]` |
| 5 | Check response | Success message |
| 6 | DB check: `SELECT COUNT(*) FROM slb_lessons WHERE code IN ('LEC_A','LEC_B','LEC_C')` | 3 records created |
| 7 | DB check: All 3 have same `academic_session_id`, `class_id`, `subject_id`, `bok_books_id` | Correct shared FK values |

---

#### TC-P07: Create Lesson With All Optional Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Lesson form | Form visible |
| 2 | Fill required fields (session, class, subject, book, name="Full Lesson", code="FULL01", ordinal=5) | Required fields set |
| 3 | Enter short_name="Algebra Basics" | Optional field filled |
| 4 | Enter description="This is a comprehensive lesson on algebra" | Description filled |
| 5 | Enter learning_objectives as multi-line: "Understand variables\nSolve equations\nGraph functions" | 3 objectives entered |
| 6 | Enter estimated_periods: 12 | Field filled |
| 7 | Enter weightage_in_subject: 15.5 | Field filled |
| 8 | Enter nep_alignment: "NEP_2020_MATH_01" | Field filled |
| 9 | Enter book_chapter_ref: "Chapter 1, Page 5-25" | Field filled |
| 10 | Enter scheduled_year_week: 202601 | Field filled |
| 11 | Set is_active toggle ON | Toggle ON |
| 12 | Click "Save" | Lesson created |
| 13 | DB check: `SELECT * FROM slb_lessons WHERE code='FULL01'` | All optional fields saved with correct values |
| 14 | Verify `learning_objectives` is valid JSON | Stored as JSON array |
| 15 | Verify `weightage_in_subject` = 15.50 | Decimal precision preserved |

---

#### TC-P08: Create Lesson With Resources (Video, PDF, Link)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Lesson form | Form visible |
| 2 | Fill required fields (name="Resource Lesson", code="RES01", ordinal=6) | Required fields set |
| 3 | In Resources section, add a Video resource: type="video", title="Intro Video", url="https://example.com/intro.mp4" | Resource row added |
| 4 | Add a PDF resource: type="pdf", title="Worksheet", url="https://example.com/worksheet.pdf" | Second resource row added |
| 5 | Add a Link resource: type="link", title="Reference", url="https://example.com/ref" | Third resource row added |
| 6 | Click "Save" | Lesson created |
| 7 | DB check: `SELECT resources_json FROM slb_lessons WHERE code='RES01'` | `resources_json` contains array of 3 resource objects with correct type/title/url |
| 8 | Verify each resource has required fields | type `in:video,pdf,link`, title max 200, url valid |

---

#### TC-P09: Create Lesson Without Ordinal (Defaults)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Lesson form | Form visible |
| 2 | Fill required fields (name="NoOrdinal", code="NORD") | Required fields set |
| 3 | Leave ordinal empty | Empty |
| 4 | Click "Save" | Validation error: "Lesson order number is required." (ordinal is required, min:1) |
| 5 | Enter ordinal = 1 | Ordinal filled |
| 6 | Click "Save" | Lesson created successfully |

---

#### TC-P10: Edit Lesson Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson: name="EditTest", code="EDT01", ordinal=10 | Lesson exists with ID=X |
| 2 | Click "Edit" button (pencil icon) on that row | Navigates to `/syllabus/lesson/{X}/edit` |
| 3 | Verify form pre-filled | name="EditTest", code="EDT01", ordinal=10 |
| 4 | Verify book dropdown shows the correct book | `bok_books_id` matches stored value |
| 5 | Verify academic session, class, subject dropdowns match stored values | All match |

---

#### TC-P11: Update Lesson All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson: name="OldName", code="OLD01", ordinal=5 | Lesson exists with ID=X |
| 2 | Navigate to edit page for lesson X | Form pre-filled |
| 3 | Change name to "NewName", code to "NEW01", ordinal to 10 | Fields updated |
| 4 | Change short_name to "ShortNew" | Updated |
| 5 | Change description to "Updated description" | Updated |
| 6 | Change estimated_periods to 20 | Updated |
| 7 | Change weightage_in_subject to 25.50 | Updated |
| 8 | Change is_active to OFF | Toggle OFF |
| 9 | Click "Save" | PUT request to `/syllabus/lesson/{X}` |
| 10 | Check response | "Lesson updated successfully." |
| 11 | DB check: `SELECT * FROM slb_lessons WHERE id={X}` | All fields updated; `updated_at` changed |
| 12 | Verify code is uppercased: "NEW01" | `strtoupper()` applied |

---

#### TC-P12: Update Lesson — Change Book Mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson with book B1 (name="BookTest", code="BKT01") | Lesson exists with book_id=B1 |
| 2 | Edit lesson, select a different book B2 from dropdown | Book changed |
| 3 | Click "Save" | Update succeeds |
| 4 | DB check: `SELECT bok_books_id FROM slb_lessons WHERE code='BKT01'` | bok_books_id = B2 |

---

#### TC-P13: View Lesson Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson: name="ViewTest", code="VEW01", description="View description" | Lesson exists |
| 2 | Click "View" button (eye icon) on that row | Navigates to `/syllabus/lesson/view/{id}` |
| 3 | Check page heading | Lesson name displayed: "ViewTest" |
| 4 | Check code displayed | "VEW01" |
| 5 | Check ordinal displayed | Correct ordinal shown |
| 6 | Check class and subject names displayed | Correct names |
| 7 | Check book name displayed | Correct book title |
| 8 | Check status badge | Green "Active" or red "Inactive" badge |
| 9 | Check description displayed | "View description" |
| 10 | Check learning objectives displayed | Objectives list shown |

---

#### TC-P14: Soft Delete Lesson

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson: name="DeleteTest", code="DEL01" | Lesson exists with ID=X |
| 2 | Click delete button (trash icon) on that row | SweetAlert "Are you sure?" with "Move to Trash: The item can be restored later!" |
| 3 | Click "Cancel" | Alert closes, lesson not deleted |
| 4 | Click delete again, then click "Yes, delete it!" | AJAX DELETE sent |
| 5 | Check toast | Green toast: "Lesson deleted successfully" |
| 6 | DB check: `SELECT deleted_at FROM slb_lessons WHERE id={X}` | `deleted_at` NOT NULL (soft deleted) |
| 7 | Verify lesson no longer visible in main lessons table | Disappeared from list |
| 8 | Activity log: `SELECT * FROM glb_activity_logs WHERE event='Deleted' ORDER BY id DESC LIMIT 1` | "Deleted" event logged |

---

#### TC-P15: Trash Page Shows Deleted Lessons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a lesson (name="TrashTest", code="TRS01") | Lesson is trashed |
| 2 | Click "Trash" button on lessons page | Navigates to `/syllabus/lesson/trash/view` |
| 3 | Check trash page loads | Heading: "Trashed Lessons" |
| 4 | Check table shows deleted lesson | "TrashTest" row visible |
| 5 | Check "Restore" button | Button/link present on each row |
| 6 | Check "Force Delete" button | Force delete button present |

---

#### TC-P16: Restore Lesson From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash page (lesson "TrashTest" is soft-deleted) | Trash page shows the lesson |
| 2 | Click "Restore" on that row | SweetAlert "Sure to restore?" |
| 3 | Click confirm | Restore succeeds |
| 4 | Check toast | Success message: "Lesson restored successfully" |
| 5 | DB check: `SELECT deleted_at FROM slb_lessons WHERE id={X}` | `deleted_at` = NULL (restored) |
| 6 | Navigate back to main lessons tab | Lesson "TrashTest" visible again |
| 7 | Activity log: `SELECT * FROM glb_activity_logs WHERE event='Restored'` | "Restored" event logged |

---

#### TC-P17: Force Delete Lesson (No Dependencies)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson (name="ForceTest", code="FRC01") then soft-delete it | Lesson is in trash |
| 2 | Navigate to trash page | Trash page shows "ForceTest" |
| 3 | Click "Force Delete" on that row | SweetAlert "Delete Permanently ?" with warning text |
| 4 | Click confirm | Force delete succeeds |
| 5 | Check toast | "Lesson deleted permanently" |
| 6 | DB check: `SELECT * FROM slb_lessons WHERE code='FRC01'` WITH trashed | Record permanently gone |
| 7 | Activity log: "Force Delete" event logged | Event exists |

---

#### TC-P18: Toggle Status Active ↔ Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson with is_active=ON (name="ToggleTest", code="TGL01") | Lesson is active |
| 2 | Click the status toggle switch on that row | AJAX POST to `/syllabus/lesson/{id}/toggle-status` |
| 3 | Check response | JSON `{success: true, message: "..."}` |
| 4 | DB check: `SELECT is_active FROM slb_lessons WHERE id={id}` | is_active=0 (false) |
| 5 | Status badge in table changes to "Inactive" | Badge updated |
| 6 | Click the toggle switch again | AJAX POST sent again |
| 7 | DB check: `SELECT is_active FROM slb_lessons WHERE id={id}` | is_active=1 (true) — toggled back |
| 8 | Activity log: 2 entries with event="Toggle Status" | Both toggles logged |

---

#### TC-P19: Update Lesson Order (Drag Reorder)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 lessons for same class+subject: "Alpha" (ordinal=1), "Beta" (ordinal=2), "Gamma" (ordinal=3) | 3 lessons exist |
| 2 | Drag "Gamma" to the top position (above Alpha) | SortableJS triggers AJAX POST to `/syllabus/lessons/update-order` |
| 3 | Check response | JSON `{success: true, message: "Lesson order updated successfully"}` |
| 4 | DB check: `SELECT name, ordinal FROM slb_lessons WHERE class_id={X} AND subject_id={Y} ORDER BY ordinal` | New order: Gamma(1), Alpha(2), Beta(3) |

---

#### TC-P20: AJAX Duplicate Check — Name Available

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class_id=C1, subject_id=S1 on the form | Filters set |
| 2 | Enter name="UniqueName" in a new lesson row | Field changed |
| 3 | Trigger on-blur or on-keyup duplicate check | AJAX POST to `/syllabus/lessons/check-duplicate` |
| 4 | Check response | `{success: true, exists: false, message: "name is available."}` |
| 5 | No validation error shown | Green check or no error |

---

#### TC-P21: AJAX Duplicate Check — Code Available

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code="UNIQUECODE" in a new lesson row | Field changed |
| 2 | Trigger duplicate check | AJAX POST with field="code", value="UNIQUECODE" |
| 3 | Check response | `{exists: false, message: "code is available."}` |

---

#### TC-P22: AJAX Duplicate Check — Ordinal Available

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson with ordinal=5 for class=C1, subject=S1 | Lesson exists |
| 2 | In a new lesson row, enter ordinal=3 (available) | Field changed |
| 3 | Trigger duplicate check | AJAX POST with field="ordinal", value="3" |
| 4 | Check response | `{exists: false, message: "ordinal is available."}` |

---

#### TC-P23: Get Subjects By Class ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a class from class dropdown | JavaScript fires AJAX GET to `/syllabus/get-subject?class_id={id}` |
| 2 | Check response | JSON array of subjects linked to this class (with id, name, code) |
| 3 | Verify subject dropdown populated | Subjects appear in dropdown |

---

#### TC-P24: Get Books By Class + Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class and subject | JavaScript fires AJAX GET to `/syllabus/get/books?class_id={id}&subject_id={id}` |
| 2 | Check response | JSON `{status: true, data: [{id, title, ...}]}` |
| 3 | Verify book dropdown populated | Books appear in dropdown |

---

#### TC-P25: Get Class Teachers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a class | JavaScript fires AJAX GET to `/syllabus/get-teachers?class_id={id}` |
| 2 | Check response | JSON array of teachers with id and user name |
| 3 | Verify teacher dropdown populated | Teachers appear in dropdown |

---

#### TC-P26: Import — Validate Valid File

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare valid XLSX file with 3 lessons rows with unique names, codes, ordinals | File ready |
| 2 | Select academic session, class, subject, book | Filters set |
| 3 | Upload the file via "Import" button | AJAX POST to `/syllabus/lesson/validate-file` |
| 4 | Check response | JSON `{status: "success", file: "imports/...xlsx", total: 3, passed: 3, failed: 0}` |
| 5 | Verify file stored in `storage/app/public/imports/` | File exists |
| 6 | Verify session contains `lesson_import_file` and `lesson_import_filters` | Session data set |

---

#### TC-P27: Import — Execute Import After Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | After successful validation (TC-P26), click "Confirm Import" or equivalent | AJAX POST to `/syllabus/lesson/start-import` |
| 2 | Check response | JSON `{status: "completed", created: 3, skipped: 0, errors: []}` |
| 3 | DB check: `SELECT COUNT(*) FROM slb_lessons WHERE code IN (...imported codes...)` | 3 lessons created |
| 4 | Verify lesson data matches file rows | name, ordinal, code, periods, weightage all match |
| 5 | Verify session cleared (or consumed) | `lesson_import_file` no longer in session |

---

#### TC-P28: Import — Auto-Code Generation When Code Empty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare XLSX file with lesson_number=5, lesson_name="AutoCode Lesson", code field empty | File ready |
| 2 | Select class_id=9, subject_id=3, validate and import | — |
| 3 | DB check: `SELECT code FROM slb_lessons WHERE name='AutoCode Lesson'` | code = "C9-S3-L5" (auto-generated) |

---

#### TC-P29: Full Lifecycle: Create → Edit → Toggle → Delete → Trash → Restore → Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson: name="Lifecycle", code="LFC01", ordinal=1 | Lesson created successfully |
| 2 | Edit lesson: change name to "Lifecycle Updated" | Update succeeds |
| 3 | Toggle status OFF then ON | Both toggles succeed, is_active flips each time |
| 4 | Soft delete lesson | `deleted_at` set |
| 5 | Navigate to trash page | Lesson visible in trash |
| 6 | Restore lesson | `deleted_at` = NULL |
| 7 | Navigate to main list | Lesson visible again |
| 8 | Soft delete again | `deleted_at` set |
| 9 | Navigate to trash, force delete | Record permanently removed |
| 10 | Verify activity logs for: Deleted, Restored, Force Delete, Toggle Status | All 4+ events logged |

---

#### TC-P30: Empty State — No Class/Subject Filter Selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login and navigate to Syllabus Master → Lessons tab | Page loads at `/syllabus/lesson` |
| 2 | Ensure no class or subject is selected in the filter dropdowns | Both dropdowns show placeholder/default option |
| 3 | Observe the table area | Empty table with centered message: "Select a class and subject to view lessons" |
| 4 | Check Add Lesson button | Disabled or hidden (no scope to create in) |
| 5 | Select a class | Class filter applied |
| 6 | Verify prompt message remains until subject also selected | Still showing "Select a class and subject" |
| 7 | Select a subject | Page reloads with both filters; table shows lessons or "No lessons found" |

---

#### TC-P31: Empty State — No Lessons For Selected Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a class and subject combination that has zero lessons | Valid scope with no data |
| 2 | Verify table area | Shows message: "No lessons found for the selected class and subject" |
| 3 | Verify Add Lesson button | Visible and enabled (user can create first lesson) |
| 4 | Create a lesson for this scope | Lesson created successfully |
| 5 | Verify the empty state message is gone | Lessons table shows the new record |

---

#### TC-P32: Add/Remove Prerequisite Lessons Via Edit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 lessons in same class+subject: "Main Lesson" (code="MAIN01"), "PreReq A" (code="PRE_A"), "PreReq B" (code="PRE_B") | 3 lessons exist |
| 2 | Navigate to edit page for "Main Lesson" | Edit form pre-filled |
| 3 | Scroll to Prerequisites section | Multi-select dropdown or tag input visible |
| 4 | Select "PreReq A" and "PreReq B" from the prerequisites dropdown | Both selected |
| 5 | Click "Save" | Lesson updated: "Lesson updated successfully." |
| 6 | View lesson detail page | Prerequisites section shows "PreReq A" and "PreReq B" as linked lessons |
| 7 | Edit "Main Lesson" again, remove "PreReq B" from prerequisites | Only "PreReq A" remains |
| 8 | Click "Save" | Update succeeds |
| 9 | View lesson detail page | Only "PreReq A" shown as prerequisite |
| 10 | DB check: `SELECT prerequisites FROM slb_lessons WHERE code='MAIN01'` | JSON array with single ID matching "PreReq A" |

---

### 6.2 Negative TC Steps

#### TC-N01: Required — Empty `lessons` Array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Lesson form | Form visible |
| 2 | Fill academic_session_id, class_id, subject_id, bok_books_id | Filters set |
| 3 | Do not add any lesson rows (lessons array empty or not sent) | Empty |
| 4 | Click "Save" | HTTP 500 |
| 5 | Validation error: "The lessons field is required." | Error returned |
| 6 | DB check: `SELECT COUNT(*) FROM slb_lessons` | No new records |

---

#### TC-N02: Required — Missing Name In Lesson Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Lesson form | Form visible |
| 2 | Fill filters (session, class, subject, book) | Filters set |
| 3 | Add a lesson row: leave name empty, fill code="NONAME01", ordinal=1 | Name empty |
| 4 | Click "Save" | HTTP 500 |
| 5 | Validation error: "Lesson name is required." | Error for `lessons.0.name` |

---

#### TC-N03: Required — Missing Code In Lesson Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Lesson form, add lesson row with name="No Code", ordinal=1, leave code empty | Code empty |
| 2 | Click "Save" | HTTP 500 |
| 3 | Error: "Lesson code is required." | `lessons.0.code` required |

---

#### TC-N04: Required — Missing `bok_books_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Lesson form | Form visible |
| 2 | Fill all fields except book (leave bok_books_id empty) | Book not selected |
| 3 | Click "Save" | HTTP 500 |
| 4 | Error: "Book is required." | `bok_books_id` required |

---

#### TC-N05: Required — Missing academic_session_id / class_id / subject_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Lesson form, leave academic_session_id empty | Empty |
| 2 | Click "Save" | HTTP 500: "The academic session id field is required." |
| 3 | Fill session, leave class_id empty | Click Save → "The class id field is required." |
| 4 | Fill class, leave subject_id empty | Click Save → "The subject id field is required." |

---

#### TC-N06: Duplicate Lesson Name Within Scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pre-requisite: Create lesson "Algebra" for session=S1, class=C1, subject=S2 | Lesson exists |
| 2 | Open Add Lesson form, select same S1, C1, S2 | Same scope |
| 3 | Add lesson row with name="Algebra", code="DIFF01", ordinal=5 | Name duplicates |
| 4 | Click "Save" | HTTP 500 |
| 5 | Error: "The lesson 'Algebra' already exists for the selected academic session, class and subject." | Inline unique validation |
| 6 | DB check: Only 1 lesson named "Algebra" for (S1, C1, S2) | No duplicate created |

---

#### TC-N07: Duplicate Lesson Code (Global)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pre-requisite: Create lesson with code="GLOBAL01" | Global code taken |
| 2 | Open Add Lesson, add row with code="GLOBAL01" | Same code |
| 3 | Click "Save" | HTTP 500 |
| 4 | Error: "The code 'GLOBAL01' already exists in the database." | Inline unique validation |

---

#### TC-N08: Duplicate Ordinal Within Scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pre-requisite: Create lesson with ordinal=3 for (S1, C1, S2) | Ordinal taken |
| 2 | Open Add Lesson, same scope, add row with ordinal=3 | Ordinal duplicates |
| 3 | Click "Save" | HTTP 500 |
| 4 | Error: "The order number '3' is already used by '{lesson}' for this academic session, class and subject." | Inline scoped unique |

---

#### TC-N09: Max Length — Name > 150 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add lesson row with name of 151 characters | Field exceeds max |
| 2 | Click "Save" | HTTP 500 |
| 3 | Error: "Lesson name must not exceed 150 characters." | `lessons.*.name.max` |

---

#### TC-N10: Max Length — Code > 20 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add lesson row with code of 21 characters | Field exceeds max |
| 2 | Click "Save" | HTTP 500 |
| 3 | Error: "Lesson code must not exceed 20 characters." | `lessons.*.code.max` |

---

#### TC-N11: Invalid Ordinal — 0 or Negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add lesson row with ordinal=0 | Below minimum |
| 2 | Click "Save" | HTTP 500: "Lesson order number must be at least 1." |
| 3 | Change ordinal to -5 | Negative |
| 4 | Click "Save" | HTTP 500: same min error |

---

#### TC-N12: Invalid Weightage — Negative Or > 100

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add lesson row with weightage_in_subject=-10 | Negative |
| 2 | Click "Save" | HTTP 500: "Weightage must be at least 0." |
| 3 | Change weightage to 150 | > 100 |
| 4 | Click "Save" | HTTP 500: "Weightage must not exceed 100." |

---

#### TC-N13: Invalid scheduled_year_week — Below 202001 Or Above 210052

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add lesson row with scheduled_year_week=201999 | Below min (202001) |
| 2 | Click "Save" | HTTP 500: "YearWeek must be at least 202001." |
| 3 | Change to 210053 | Above max (210052) |
| 4 | Click "Save" | HTTP 500: "YearWeek must not exceed 210052." |

---

#### TC-N14: Invalid FK — Non-Existent class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Lesson form | Form visible |
| 2 | Set class_id=99999 (non-existent) | Invalid |
| 3 | Fill all other fields | Valid data |
| 4 | Click "Save" | HTTP 500: "The selected class id is invalid." |

---

#### TC-N15: Invalid FK — Non-Existent bok_books_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Lesson form | Form visible |
| 2 | Set bok_books_id=99999 (non-existent) | Invalid |
| 3 | Fill all other fields | Valid data |
| 4 | Click "Save" | HTTP 500: "The selected bok books id is invalid." |

---

#### TC-N16: View Lesson With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open URL: `/syllabus/lesson/view/99999` (non-existent) | HTTP 404 or redirect with "Lesson not found" |

---

#### TC-N17: Edit/Update Lesson With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open URL: `/syllabus/lesson/99999/edit` | HTTP 404 (Model not found) |
| 2 | Send PUT to `/syllabus/lesson/99999` with valid payload | HTTP 404 |

---

#### TC-N18: Delete Lesson With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send DELETE to `/syllabus/lesson/99999` | Redirect with "Lesson not found" error |

---

#### TC-N19: Toggle Status With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `/syllabus/lesson/99999/toggle-status` | JSON 404: `{success: false, message: "Lesson not found"}` |

---

#### TC-N20: Restore Non-Deleted Lesson (Already Active)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson that is active (not deleted) | Lesson exists with deleted_at=NULL |
| 2 | Send GET to `/syllabus/lesson/{id}/restore` | `onlyTrashed()->find($id)` returns null → 404 error |

---

#### TC-N21: Force Delete Non-Trashed Lesson

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson that is active (not deleted) | Lesson exists with deleted_at=NULL |
| 2 | Send DELETE to `/syllabus/lesson/{id}/force-delete` | `onlyTrashed()->find($id)` returns null → 404 error |

---

#### TC-N22: Permission 403 — No Lesson Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without any `tenant.lesson.*` permissions | Dashboard loads |
| 2 | Navigate to `/syllabus/lesson` (index) | 403 Forbidden (missing viewAny) |
| 3 | POST to `/syllabus/lesson` (store) without create permission | 403 Forbidden |
| 4 | PUT to `/syllabus/lesson/{id}` without update permission | 403 Forbidden |
| 5 | DELETE to `/syllabus/lesson/{id}` without delete permission | 403 Forbidden |
| 6 | POST to `/syllabus/lesson/{id}/toggle-status` without update permission | 403 Forbidden |
| 7 | GET to `/syllabus/lesson/trash/view` without restore permission | 403 Forbidden |
| 8 | GET to `/syllabus/lesson/{id}/restore` without restore permission | 403 Forbidden |
| 9 | DELETE to `/syllabus/lesson/{id}/force-delete` without forceDelete permission | 403 Forbidden |

---

#### TC-N23: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout completely | — |
| 2 | Navigate to `/syllabus/lesson` | Redirected to login page |
| 3 | Try POST to `/syllabus/lesson` | Redirected to login or 401 Unauthorized |
| 4 | Try any other lesson route | Redirected to login |

---

#### TC-N24: XSS Injection In Name/Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson with name=`<script>alert('xss')</script>`, code="XSS01" | Lesson created (server accepts string) |
| 2 | DB check: `SELECT name FROM slb_lessons WHERE code='XSS01'` | Stored as-is `<script>alert('xss')</script>` |
| 3 | View the lesson on the list page | Script does NOT execute — Blade `{{ }}` auto-escapes HTML |
| 4 | Clean up: delete the XSS lesson | Class removed |

---

#### TC-N25: Whitespace-Only Name/Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add lesson row with name="   " (spaces only), code="   " (spaces only), ordinal=1 | Empty strings after trim? |
| 2 | Click "Save" | Validation fails: "Lesson name is required", "Lesson code is required" (required check on trimmed value) |

---

#### TC-N26: Duplicate Code Within Same Request (Bulk)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add 2 lesson rows: row1 code="DUP", row2 code="DUP" (same) | Both in same request |
| 2 | Click "Save" | Inline validation catches duplicate: "The code 'DUP' already exists in the database." |

---

#### TC-N27: Duplicate Ordinal Within Same Request (Bulk)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add 2 lesson rows: row1 ordinal=1, row2 ordinal=1 (same) | Both in same request |
| 2 | Click "Save" | Inline validation catches duplicate: "The order number '1' is already used by..." |

---

#### TC-N28: Resources — Invalid Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add resources with type="exe" (invalid) | Not in allowed list |
| 2 | Click "Save" | HTTP 500: "Invalid resource type. Allowed: video, pdf, link, document, image, audio, ppt." |

---

#### TC-N29: Resources — Invalid URL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add resources with url="not-a-valid-url" | Invalid URL format |
| 2 | Click "Save" | HTTP 500: "Resource URL must be a valid URL." |

---

#### TC-N30: Import — Invalid File Type (Not XLSX/CSV)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload a `.txt` file to `/syllabus/lesson/validate-file` | HTTP 500: "The file must be a file of type: xlsx, csv." |

---

#### TC-N31: Import — File With Duplicate Ordinals

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare XLSX with 2 rows both having lesson_number=1 (same ordinal) | File has duplicates |
| 2 | Upload and validate | Error rows generated: "Row 2 : Duplicate ordinal for selected filters" |
| 3 | Verify response includes error.txt download | File contains error details |
| 4 | No lessons imported (validation failed) | `failed > 0`, `passed` < total |

---

#### TC-N32: Import — File With Duplicate Codes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare XLSX with 2 rows both having code="DUPCODE" | File has duplicate codes |
| 2 | Upload and validate | Error: "Row 3 : Duplicate code \"DUPCODE\" already exists" |
| 3 | Or: code already exists in DB | Same error: "Duplicate code already exists" |

---

#### TC-N33: Import — Start Import Without Validated File

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Clear session (no `lesson_import_file` session key) | No file in session |
| 2 | Send POST to `/syllabus/lesson/start-import` | JSON error: `{status: "error", message: "No validated file found"}` |

---

#### TC-N34: Invalid Estimated Periods — Zero Or Negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Lesson form | Form visible |
| 2 | Fill all required fields (session, class, subject, book, name="EstTest", code="EST01", ordinal=1) | Valid data entered |
| 3 | Enter estimated_periods = 0 | Below minimum (1) |
| 4 | Click "Save" | HTTP 500 validation error |
| 5 | Verify error message | "Estimated periods must be at least 1." (lessons.0.estimated_periods.min) |
| 6 | Change estimated_periods to -5 | Negative value |
| 7 | Click "Save" | HTTP 500 validation error (same min:1 rule) |
| 8 | Change estimated_periods to 10 (valid positive integer) | Within range |
| 9 | Click "Save" | Lesson created successfully |

---

### 6.3 Dependency TC Steps

#### TC-D01: Soft-Delete Lesson — Topics Cascade Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson with 2 topics (level 0) | Topics exist for lesson |
| 2 | Soft delete the lesson (via destroy()) | Lesson `deleted_at` set |
| 3 | DB check: `SELECT deleted_at FROM slb_topics WHERE lesson_id={lessonId}` | All child topics have `deleted_at` set (cascaded via `booted()` deleting event) |
| 4 | Verify topic records still exist (soft deleted, not force deleted) | `deleted_at` NOT NULL, records remain |

---

#### TC-D02: Soft-Delete Lesson — Syllabus Schedules Cascade Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson with a syllabus schedule record | Schedule exists for lesson |
| 2 | Soft delete the lesson | `booted()` deleting event fires |
| 3 | DB check: `SELECT deleted_at FROM slb_syllabus_schedules WHERE lesson_id={lessonId}` | Schedules have `deleted_at` set |

---

#### TC-D03: Soft-Delete Lesson — Exam Scopes Cascade Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson with an exam scope record | ExamScope exists for lesson |
| 2 | Soft delete the lesson | `booted()` deleting event fires |
| 3 | DB check: ExamScope records for lesson have `deleted_at` set | Cascaded |

---

#### TC-D04: Restore Lesson — Topics Remain Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson with 2 topics, then soft delete the lesson | Lesson + topics all soft-deleted |
| 2 | Restore the lesson via `restore()` | Lesson `deleted_at` = NULL |
| 3 | DB check: `SELECT deleted_at FROM slb_topics WHERE lesson_id={lessonId}` | Topics STILL have `deleted_at` set (restore does NOT cascade to children) |

---

#### TC-D05: Force Delete Blocked — Exam Scopes Exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson with an exam scope record | ExamScope references lesson |
| 2 | Soft delete the lesson | Lesson in trash |
| 3 | Attempt force delete | Redirect back with error: "This lesson cannot be deleted because it is linked with exam scopes." |
| 4 | DB check: Lesson record still exists in trash | Not force deleted |

---

#### TC-D06: Force Delete Blocked — Questions Reference Lesson

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson with 3 question bank records referencing it | Questions exist for lesson |
| 2 | Soft delete the lesson | Lesson in trash |
| 3 | Attempt force delete | Error: "This lesson cannot be deleted because it is referenced by 3 question(s). Please delete or update those questions first." |
| 4 | DB check: Lesson still in trash | Not force deleted |

---

#### TC-D07: Cannot Delete Academic Session While Lesson References It (RESTRICT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson referencing academic_session_id=S1 | Lesson exists with FK |
| 2 | Attempt to delete the academic session S1 | FK constraint error: RESTRICT prevents deletion |
| 3 | Delete the lesson first | Lesson removed |
| 4 | Now delete the academic session | Deletion succeeds |

---

#### TC-D08: Class Deletion Cascades To Lessons (CASCADE)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson referencing class_id=C1 | Lesson exists |
| 2 | Delete the class C1 | DDL CASCADE deletes all lessons for that class |
| 3 | DB check: `SELECT * FROM slb_lessons WHERE class_id=C1` | No records (cascaded) |

---

#### TC-D09: Subject Deletion Cascades To Lessons (CASCADE)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson referencing subject_id=S1 | Lesson exists |
| 2 | Delete the subject S1 | DDL CASCADE deletes all lessons for that subject |
| 3 | DB check: `SELECT * FROM slb_lessons WHERE subject_id=S1` | No records (cascaded) |

---

#### TC-D10: Import Flow — Validate Then Execute

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload valid XLSX with 5 lesson rows | Validation passes, file stored in session |
| 2 | Call `startImport()` | Lessons created: `created: 5` |
| 3 | DB check: 5 new lesson records matching file data | All fields (name, code, ordinal, periods, weightage, etc.) match |

---

#### TC-D11: Import Flow — Validation Failure Stops Import

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload XLSX with 3 rows, 2 of which have invalid data (missing name, invalid ordinal) | Validation fails |
| 2 | Verify error file returned (text/plain download) | Error listing rows with descriptions |
| 3 | Verify `lesson_import_file` NOT set in session | Session not updated |
| 4 | No lessons created from file | 0 new records |

---

#### TC-D12: Toggle Status — Inactive Lesson Hidden From Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inactive lesson (is_active=0) | Lesson exists but inactive |
| 2 | Navigate to prerequisite selection or any lesson dropdown | Inactive lesson NOT in dropdown options |
| 3 | Toggle lesson back to active | Lesson appears in dropdowns again |

---

#### TC-D13: Update academic_session_id On Lesson (Update)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson with academic_session_id=S1 | Lesson in session S1 |
| 2 | Edit the lesson, change to academic_session_id=S2 (valid, different) | Session changed |
| 3 | Click "Save" | Update succeeds |
| 4 | DB check: `SELECT academic_session_id FROM slb_lessons WHERE id={id}` | = S2 |

---

#### TC-D14: Concurrent Update — Two Users Edit Same Lesson

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A opens edit for lesson X | Form loaded with initial values |
| 2 | User B opens edit for same lesson X | Form loaded with same values |
| 3 | User A changes name to "Version A" and saves | Update succeeds, name = "Version A" |
| 4 | User B changes name to "Version B" and saves | Update succeeds, name = "Version B" (last save wins) |
| 5 | DB check: Lesson X name = "Version B" | No data corruption — last write persists |

---

#### TC-D15: Rapid Status Toggle (Race Condition)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson with is_active=1 | Active |
| 2 | Rapidly click the toggle switch 10 times in succession | Each AJAX request completes |
| 3 | DB check: `SELECT is_active FROM slb_lessons WHERE id={id}` | `is_active` = depends on parity (if 10 toggles, back to original) |
| 4 | No 500 errors or data corruption | All requests return 200 |

---

#### TC-D16: Same Ordinal Allowed For Different (Class, Subject) Scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson with ordinal=1 for Class A / Subject X | Lesson exists |
| 2 | Create lesson with ordinal=1 for Class B / Subject Y (different scope) | Lesson created successfully (unique constraint is scoped) |
| 3 | DB check: Both lessons have ordinal=1 | Both exist without conflict |

---

#### TC-D17: Same Name Allowed For Different (Class, Subject) Scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson named "Algebra" for Class 9 / Subject Math | Lesson exists |
| 2 | Create lesson named "Algebra" for Class 10 / Subject Math (different class) | Lesson created successfully (unique constraint is scoped) |
| 3 | DB check: Both lessons named "Algebra" | Both exist without conflict |
| 4 | Update lesson: change class of first "Algebra" to Class 10 / Subject Math | Fails: duplicate name in new scope |

---

#### TC-D20: Composite Unique Constraint — uq_lesson_class_subject_name (class_id + subject_id + name)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify the composite unique constraint on `slb_lessons` table: `uq_lesson_class_subject_name` covering `(class_id, subject_id, name)` | Constraint exists in DB schema |
| 2 | Create a lesson with specific `class_id`, `subject_id`, and name "UniqueName" | Lesson created successfully |
| 3 | Using raw DB insert (or API endpoint bypassing validation), attempt to insert another lesson with the same `class_id`, `subject_id`, and name "UniqueName" | Insert fails with integrity constraint violation error (SQLSTATE[23000]) |
| 4 | Verify that the duplicate record was NOT inserted | Only 1 record exists for that combination |

---

#### TC-D21: Binary(16) UUID Format Validation — uuid Column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new lesson via the controller | Lesson created successfully |
| 2 | DB check: `SELECT uuid, LENGTH(uuid) FROM slb_lessons WHERE id={id}` | uuid is 16 bytes (BINARY(16)), NOT a human-readable string |
| 3 | Verify uuid was auto-generated via `Str::uuid()->getBytes()` | uuid is a valid binary UUID, not NULL |
| 4 | DB check: Verify unique constraint `uq_lesson_uuid` | Attempt inserting a record with the same binary uuid → integrity constraint violation |

---

#### TC-D22: Multi-Level Cascade Chain — Lesson → Topics → Dependents

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a lesson with child topics, syllabus schedule records, and exam scope records | All dependent records exist |
| 2 | Soft-delete the lesson via the destroy endpoint | Lesson soft-deleted successfully |
| 3 | DB check: Verify topics cascade — `SELECT deleted_at FROM slb_topics WHERE lesson_id={id}` | All child topics have `deleted_at` set (cascade via `booted()` event) |
| 4 | DB check: Verify syllabus schedules cascade — `SELECT deleted_at FROM slb_syllabus_schedules WHERE lesson_id={id}` | All schedule records have `deleted_at` set |
| 5 | DB check: Verify exam scopes cascade — `SELECT deleted_at FROM lms_exam_scopes WHERE lesson_id={id}` | All exam scope records have `deleted_at` set |
| 6 | Force-delete the lesson from trash | Lesson permanently removed |
| 7 | DB check: Verify force-delete removes all dependent records permanently | Topics, schedules, and exam scopes hard-deleted (or orphaned depending on DDL) |
| 8 | Test DDL CASCADE: Delete the parent class of the lesson | DDL CASCADE deletes all lessons for that class |

---

#### TC-D23: FK RESTRICT — academic_session_id Deletion Blocked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a lesson referencing an active academic_session_id=S1 | Lesson exists with FK to S1 |
| 2 | Attempt to delete the academic session S1 directly in DB | FK RESTRICT error: Cannot delete or update a parent row; FK constraint fails |
| 3 | Attempt to delete academic session S1 via the UI/API | Same FK constraint error returned |
| 4 | Delete the lesson(s) referencing academic session S1 first | Lessons deleted successfully |
| 5 | Now delete academic session S1 | Deletion succeeds (no remaining references) |

---

#### TC-D24: SMALLINT UNSIGNED Boundary — estimated_periods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson with estimated_periods = 0 | Validation rule min:1 catches at application level; if bypassed via raw DB, SMALLINT UNSIGNED allows 0 |
| 2 | Create lesson with estimated_periods = 1 (minimum valid) | Lesson created; DB stores 1 |
| 3 | Create lesson with estimated_periods = 65535 (SMALLINT UNSIGNED max) | Lesson created; DB stores 65535 |
| 4 | Attempt to insert estimated_periods = 65536 (exceeds max) | DB error: Out of range value for column; or truncation |
| 5 | Attempt to insert estimated_periods = -1 (negative) | DB error: Out of range value for negative; if via API, validation rule min:1 catches it first |
| 6 | Verify boundary values 0, 1, and 65535 are stored correctly | DB select returns exact values without corruption |

---

#### TC-D25: Code Review: Model Table Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/Syllabus/Models/Lesson.php` | File opens in IDE |
| 2 | Locate the `$table` property declaration | `protected $table` exists |
| 3 | Verify its value | `protected $table = 'slb_lessons'` matches DB table name |

---

#### TC-D26: Code Review: Model Fillable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/Syllabus/Models/Lesson.php` | File opens |
| 2 | Locate the `$fillable` array | `protected $fillable` property exists |
| 3 | Verify all expected fields are present | Array includes: name, code, class_id, subject_id, academic_session_id, description, duration_minutes, is_active, bok_books_id, ordinal, lesson_type |

---

#### TC-D27: Code Review: SoftDeletes Trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/Syllabus/Models/Lesson.php` | File opens |
| 2 | Check the `use` statements inside the class | `use SoftDeletes;` or `use Illuminate\Database\Eloquent\SoftDeletes;` present |
| 3 | Open the migration file for `slb_lessons` table | `deleted_at` column is defined as nullable timestamp |

---

#### TC-D28: Code Review: Model Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/Syllabus/Models/Lesson.php` | File opens |
| 2 | Check for `class()` method | `belongsTo(Class::class)` defined |
| 3 | Check for `subject()` method | `belongsTo(Subject::class)` defined |
| 4 | Check for `academicSession()` method | `belongsTo(AcademicSession::class)` defined |
| 5 | Check for `topics()` method | `hasMany(Topic::class)` defined |
| 6 | Check for `schedules()` method | `hasMany(SyllabusSchedule::class)` defined |

---

#### TC-D29: Code Review: $casts Definition

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/Syllabus/Models/Lesson.php` | File opens |
| 2 | Locate the `$casts` property | `protected $casts` array exists |
| 3 | Verify `is_active` cast | `'is_active' => 'boolean'` present |
| 4 | Verify `duration_minutes` cast | `'duration_minutes' => 'integer'` present |

---

#### TC-D30: Code Review: findOrFail Usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/Syllabus/Http/Controllers/LessonController.php` | File opens |
| 2 | Check `edit()` method | Uses `Lesson::findOrFail($id)` |
| 3 | Check `update()` method | Uses `Lesson::findOrFail($id)` |
| 4 | Check `show()` / `view()` method | Uses `Lesson::findOrFail($id)` |
| 5 | Check `destroy()` method | Uses `Lesson::findOrFail($id)` |
| 6 | Verify all return 404 when not found | `findOrFail` throws `ModelNotFoundException` → HTTP 404 |

---

#### TC-D31: Code Review: Gate Authorization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/Syllabus/Http/Controllers/LessonController.php` | File opens |
| 2 | Check `store()` method | `Gate::authorize('tenant.lesson.create')` called before create logic |
| 3 | Check `update()` method | `Gate::authorize('tenant.lesson.update')` called before update logic |
| 4 | Check `destroy()` method | `Gate::authorize('tenant.lesson.delete')` called before delete logic |

---

#### TC-D32: Code Review: activityLog After CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/Syllabus/Http/Controllers/LessonController.php` | File opens |
| 2 | Check `store()` method | `activityLog()` called after successful create |
| 3 | Check `update()` method | `activityLog()` called after successful update |
| 4 | Check `destroy()` method | `activityLog()` called after successful delete |
| 5 | Check `restore()` method | `activityLog()` called after successful restore |
| 6 | Check `forceDelete()` method | `activityLog()` called after successful force delete |
| 7 | Verify each call has appropriate action type | Action type string matches the operation (e.g., "Created", "Updated", "Deleted", "Restored", "Force Deleted") |

---

#### TC-D33: Code Review: is_active Toggle Before Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/Syllabus/Http/Controllers/LessonController.php` | File opens |
| 2 | Locate `destroy()` method | Method implementation visible |
| 3 | Check for `is_active` assignment | `$lesson->is_active = false;` or equivalent before `$lesson->delete()` |
| 4 | Verify the save/delete sequence | `is_active` set to false, then `delete()` called on the model |

---

#### TC-D34: Code Review: Unique Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/Syllabus/Http/Requests/LessonRequest.php` | File opens |
| 2 | Locate `rules()` method | Returns array of validation rules |
| 3 | Check `code` field rule | Contains `unique:slb_lessons` or `Rule::unique('slb_lessons')` |
| 4 | Check for update scenario | `ignore($lessonId)` or `ignore($this->route('lesson'))` applied on update path |

---

#### TC-D35: Code Review: Required Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/Syllabus/Http/Requests/LessonRequest.php` | File opens |
| 2 | Check `name` field rule | Contains `required` |
| 3 | Check `class_id` field rule | Contains `required` |
| 4 | Check `subject_id` field rule | Contains `required` |
| 5 | Check `description` field rule | Contains `nullable` or not marked as required |

---

#### TC-D36: Code Review: Max Length Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/Syllabus/Http/Requests/LessonRequest.php` | File opens |
| 2 | Check `name` field rule | Contains `max:100` |
| 3 | Check `code` field rule | Contains `max:20` |
| 4 | Check `description` field rule | Contains `max:255` |

---

#### TC-D37: Code Review: Boolean Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/Syllabus/Http/Requests/LessonRequest.php` | File opens |
| 2 | Locate the `is_active` field validation rule | Rule exists for `lessons.*.is_active` |
| 3 | Verify `boolean` rule present | Rule array includes `boolean` or `'boolean'` |

---

#### TC-D38: Code Review: Permission Gates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/Syllabus/Policies/LessonPolicy.php` | File opens |
| 2 | Check `viewAny()` method | Gate defined with `tenant.lesson.viewAny` |
| 3 | Check `view()` method | Gate defined with `tenant.lesson.view` |
| 4 | Check `create()` method | Gate defined with `tenant.lesson.create` |
| 5 | Check `update()` method | Gate defined with `tenant.lesson.update` |
| 6 | Check `delete()` method | Gate defined with `tenant.lesson.delete` |
| 7 | Check `restore()` method | Gate defined with `tenant.lesson.restore` |
| 8 | Check `forceDelete()` method | Gate defined with `tenant.lesson.forceDelete` |
| 9 | Check `status()` method | Gate defined with `tenant.lesson.status` |

---

#### TC-D39: Code Review: Resource + Additional Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open the routes file (e.g., `Modules/Syllabus/Routes/web.php`) | File opens |
| 2 | Check for resource route definition | `Route::resource('lesson', LessonController::class)` present |
| 3 | Check for trashed route | `Route::get('lesson/trash/view', ...)` or `->get('trash/view', ...)` present |
| 4 | Check for restore route | `Route::get('lesson/{id}/restore', ...)` present |
| 5 | Check for forceDelete route | `Route::delete('lesson/{id}/force-delete', ...)` present |
| 6 | Check for toggleStatus route | `Route::post('lesson/{lesson}/toggle-status', ...)` present |

#### TC-D40: Exam Module — lms_exam_scopes FK References slb_lessons.id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a lesson | Lesson created |
| 2 | Create an exam scope referencing the lesson in `lms_exam_scopes` | FK references lesson.id |
| 3 | Try to delete the lesson via destroy() | Blocked by FK constraint or application check; returns error |
| 4 | Delete the exam scope first | Scope removed |
| 5 | Delete the lesson | Deletion succeeds |

#### TC-D41: Question Bank — qbank_question_banks FK References lesson_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a lesson | Lesson created |
| 2 | Create a Question Bank entry referencing the lesson | qbank_question_banks.lesson_id = lesson.id |
| 3 | Try to forceDelete the lesson | Controller checks Question Bank references → deletion blocked |
| 4 | Remove the question bank reference | Reference cleared |
| 5 | forceDelete the lesson | Deletion proceeds |

---

#### TC-D42: Import — UTF-8 Sanitization of Non-UTF8 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `LessonImport` class — locate the `sanitize()` method or equivalent UTF-8 sanitization logic | Method uses `mb_convert_encoding()` or `iconv()` to convert non-UTF8 input to valid UTF-8 |
| 2 | Prepare a CSV/XLSX file containing non-UTF8 characters: e.g., ISO-8859-1 encoded text with accented characters (é, ñ, ü) and invalid UTF-8 byte sequences | File has mixed encoding |
| 3 | Upload file to `/syllabus/lesson/validate-file` | Validation response: `status: "success"` |
| 4 | Execute import via `/syllabus/lesson/start-import` | Import completes successfully |
| 5 | DB check: `SELECT name, description, learning_objectives FROM slb_lessons WHERE code='...'` | All text fields contain valid UTF-8 strings; accented characters preserved correctly |
| 6 | Verify no `mb_convert_encoding()` encoding errors or warnings in logs | Logs clean of encoding-related warnings |
| 7 | Test edge case: file with purely ASCII characters (no non-UTF8) | Import proceeds normally; sanitize() is a no-op |
