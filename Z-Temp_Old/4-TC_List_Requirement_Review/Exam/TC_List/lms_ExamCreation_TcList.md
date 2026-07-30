# lms_ExamCreation_TcList

## Module: LmsExam → Creation & Allocation → Exam Creation

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Creation & Allocation |
| Feature | Exam Creation |
| URL(s) | `/lms-exam/creation-allocation` (index via tab with `active_tab=exam_creation`), `/lms-exam/exam/store` (create/update), `/lms-exam/exam/{id}` (show), `/lms-exam/exam/{id}/edit` (edit), `/lms-exam/exam/{id}/destroy` (delete), `/lms-exam/exam/trash/view` (trash), `/lms-exam/exam/{id}/restore` (restore), `/lms-exam/exam/{id}/force-delete` (forceDelete), `/lms-exam/exam/{id}/toggle-status` (toggleStatus) |
| Controller | `Modules\LmsExam\Http\Controllers\LmsExamController` (monolithic; methods: store/update/destroy/show/edit/trashed/restore/forceDelete/toggleStatus) |
| Model(s) | `Modules\LmsExam\Models\Exam` (`lms_exams`, SoftDeletes, UUID boot, auto code generation) |
| Validation (Create) | `Modules\LmsExam\Http\Requests\ExamRequest` |
| Validation (Update) | `Modules\LmsExam\Http\Requests\ExamRequest` |
| Permissions | `tenant.exam.viewAny`, `tenant.exam.view`, `tenant.exam.create`, `tenant.exam.update`, `tenant.exam.delete`, `tenant.exam.restore`, `tenant.exam.forceDelete`, `tenant.exam.status`, `tenant.exam.import`, `tenant.exam.export`, `tenant.exam.print` |
| Soft Deletes | Yes (`Exam` uses `SoftDeletes` trait; destroy() sets `is_active=false` before `delete()`) |
| Activity Log | Events: `Stored`, `Updated` (with old/new diff), `Trashed`, `Restored`, `Deleted` (permanent), `Toggled` |
| Usage Check | `ExamUsageCheckService` — checks papers, allocations, student attempts |
| Publication Validation | `validateExamDifficulty()` runs DV1-DV8 checks when status → PUBLISHED |
| Query Service | `ExamQueryService::examsQuery()` — filters by search, status, exam_type, class, date_range, data_type |

---

## 2. Pre-conditions

- Required permissions: `tenant.exam.viewAny`, `tenant.exam.view`, `tenant.exam.create`, `tenant.exam.update`, `tenant.exam.delete`, `tenant.exam.restore`, `tenant.exam.forceDelete`, `tenant.exam.status`
- Required seed data: At least one active `OrganizationAcademicSession`, one active `SchoolClass`, one active `ExamType`, one active `ExamStatusEvent` with `event_type='EXAM'`, one `GradeDivisionMaster` (optional)
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For publication validation tests: At least one `ExamPaper` with `ExamPaperSet` and `PaperSetQuestion` records linked to the exam
- For usage-check tests: Pre-created `ExamPaper` records referencing the exam
- For usage-check tests: Pre-created `ExamAllocation` records linking to the exam via papers
- For usage-check tests: Pre-created `ExamAttempt` records linking to the exam via papers

---

## 3. Default Data Load

When the page loads via `creationAllocation()` (GET /lms-exam/creation-allocation with `active_tab=exam_creation`), the following data is fetched and passed to the view:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Exams Grid | `ExamQueryService::examsQuery()` | `Exam::latest()` with eager loads | search(code,title,description,class,exam_type,status), status_id, exam_type_id, class_id, date_range, data_type, is_active | 10/page (exam_page) |
| Shared: Exam Types | `ExamType::where('is_active', '1')->get()` | All active exam types | is_active=1 | None |
| Shared: Status List | `ExamStatusEvent::where('is_active', '1')->get()` | All active status events | is_active=1 | None |
| Shared: Classes | `SchoolClass::where('is_active', '1')->get()` | All active classes | is_active=1 | None |
| Shared: Sections | `Section::where('is_active', '1')->get()` | All active sections | is_active=1 | None |
| Shared: Subjects | `Subject::where('is_active', '1')->get()` | All active subjects | is_active=1 | None |
| Shared: Grading Schemas | `GradeDivisionMaster::where('is_active', '1')->get()` | All active grading schemas | is_active=1 | None |
| Shared: Exam Papers List | `ExamPaper::where('is_active', '1')->get()` | All active exam papers | is_active=1 | None |
| Shared: Exam Papers Paginated | `ExamQueryService::examPapersQuery()` | ExamPaper with exam,class,subject,status | Various filters | 10/page (exam_paper_page) |

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Exam code**: Auto-generated as `EXAM_<SESSION_CODE>_<CLASS_CODE>_<EXAM_TYPE_CODE>_<RANDOM6>`; also custom-suppliable (max 50 chars, globally unique)
- **Exam title**: String max 150 chars, no explicit uniqueness constraint
- **UUID**: Auto-generated `(string) Str::uuid()` on create via boot `creating` event
- **Pre-test cleanup**: Delete created exams by code before/after tests to avoid collisions
- **Unique combination**: `(academic_session_id, class_id, exam_type_id)` enforced at DB and validation level
- **Code duplicate on update**: If updated code already exists, appends `_<random4>` suffix automatically
- **created_by**: Auto-set to authenticated user ID on create
- **Result publishing**: `IMMEDIATE` sets `is_result_published=true`; `SCHEDULED` sets `is_result_published=false`

---

## 5. Business Conditions

### 4.1 Database Schema — `lms_exams`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | uuid | BINARY(16) | NOT NULL, UNIQUE |
| BC-DB-03 | academic_session_id | INT UNSIGNED | NOT NULL, FK → `glb_academic_sessions.id` |
| BC-DB-04 | class_id | INT UNSIGNED | NOT NULL, FK → `sch_classes.id` |
| BC-DB-05 | exam_type_id | INT UNSIGNED | NOT NULL, FK → `lms_exam_types.id` |
| BC-DB-06 | code | VARCHAR(50) | NOT NULL, UNIQUE |
| BC-DB-07 | title | VARCHAR(150) | NOT NULL |
| BC-DB-08 | description | TEXT | DEFAULT NULL |
| BC-DB-09 | start_date | DATE | NOT NULL |
| BC-DB-10 | end_date | DATE | NOT NULL |
| BC-DB-11 | grading_schema_id | INT UNSIGNED | DEFAULT NULL, FK → `slb_grade_division_master.id` |
| BC-DB-12 | status_id | INT UNSIGNED | NOT NULL DEFAULT 0, FK → `lms_exam_status_events.id` |
| BC-DB-13 | result_published | ENUM('IMMEDIATE','SCHEDULED','MANUAL') | NOT NULL DEFAULT 'MANUAL' |
| BC-DB-14 | scheduled_result_at | DATETIME | DEFAULT NULL |
| BC-DB-15 | is_result_published | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-16 | created_by | INT UNSIGNED | DEFAULT NULL, FK → `sys_users.id` |
| BC-DB-17 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-18 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-19 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-20 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules — `ExamRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | academic_session_id | required | "Academic session is required" |
| BC-VAL-02 | class_id | required, exists:sch_classes,id | "Class is required" / "Selected class is invalid" |
| BC-VAL-03 | exam_type_id | required, exists:lms_exam_types,id, unique scope (academic_session_id, class_id) ignoring own ID | "Exam type is required" / "This exam type already exists for the selected session and class" |
| BC-VAL-04 | code | nullable, string, max:50, unique:lms_exams,code ignoring own ID | — |
| BC-VAL-05 | title | required, string, max:150 | "Exam title is required" |
| BC-VAL-06 | description | nullable, string | — |
| BC-VAL-07 | start_date | required, date, before_or_equal:end_date | "Start date must be before or equal to end date" |
| BC-VAL-08 | end_date | required, date, after_or_equal:start_date | "End date must be after or equal to start date" |
| BC-VAL-09 | scheduled_result_at | nullable, date, after_or_equal:start_date | — |
| BC-VAL-10 | result_published | nullable, in:IMMEDIATE,MANUAL,SCHEDULED | — |
| BC-VAL-11 | grading_schema_id | nullable, exists:slb_grade_division_master,id | — |
| BC-VAL-12 | status_id | required, exists:lms_exam_status_events,id | "Status is required" |
| BC-VAL-13 | is_active | boolean | — |
| BC-VAL-14 | is_result_published | boolean | — |

### 4.3 Validation Rules — `ExamRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | exam_type_id | unique scope ignoring current exam ID | "This exam type already exists for the selected session and class" |
| BC-VAL-U02 | code | unique ignoring current exam ID; controller appends random suffix on duplicate | — |
| BC-VAL-U03 | Same as create | All other rules same as create | Same messages |
| BC-VAL-U04 | Usage (controller) | Checked before edit/update/destroy/restore/forceDelete | "Cannot edit/update/delete/restore this exam because it has papers, allocations, or student attempts." |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.exam.viewAny | creationAllocation(), show(), examSummary() | Without → 403 |
| BC-AUTH-02 | tenant.exam.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.exam.create | store() | Without → 403 |
| BC-AUTH-04 | tenant.exam.update | update(), edit(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.exam.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.exam.restore | trashed(), restore() | Without → 403 |
| BC-AUTH-07 | tenant.exam.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.exam.status | toggleStatus() (via update gate) | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Auto-generate UUID | `(string) Str::uuid()` on creating event |
| BC-BIZ-02 | Auto-generate code | `generateExamCode()` creates `EXAM_<SESSION>_<CLASS>_<TYPE>_<RANDOM6>` |
| BC-BIZ-03 | Code uniqueness loop | While generated code exists, append `_<counter>` until unique |
| BC-BIZ-04 | created_by auto-set | Set to `auth()->id()` on creating event if empty |
| BC-BIZ-05 | Code duplicate on update | If updated code already exists for other record, append `_<random4>` |
| BC-BIZ-06 | IMMEDIATE result publishing | If `result_published=IMMEDIATE`, `is_result_published=true` |
| BC-BIZ-07 | SCHEDULED result publishing | If `result_published=SCHEDULED`, `is_result_published=false` |
| BC-BIZ-08 | Usage check on edit | Blocks with "Cannot edit this exam because it has papers, allocations, or student attempts." |
| BC-BIZ-09 | Usage check on update | Same block message |
| BC-BIZ-10 | Usage check on delete | Blocks with "Cannot delete this exam because it has papers, allocations, or student attempts." |
| BC-BIZ-11 | Usage check on restore | Blocks with "Cannot restore this exam because it has papers, allocations, or student attempts." |
| BC-BIZ-12 | Usage check on force delete | Blocks with "Cannot permanently delete this exam because it has papers, allocations, or student attempts." |
| BC-BIZ-13 | Status toggle NOT blocked by usage | toggleStatus works even if exam is in use |
| BC-BIZ-14 | Soft delete deactivates first | Sets `is_active=false` before `delete()` |
| BC-BIZ-15 | Restore reactivates | Sets `is_active=true` after `restore()` |
| BC-BIZ-16 | Publication validation DV1 | Set contains no questions → error |
| BC-BIZ-17 | Publication validation DV2 | Set total marks != paper target marks → error |
| BC-BIZ-18 | Publication validation DV3-DV4 | Blueprint question count/marks mismatch → error |
| BC-BIZ-19 | Publication validation DV5-DV6 | Difficulty distribution minimum not met → error |
| BC-BIZ-20 | Publication validation DV7 | Scope coverage missing required questions → error |
| BC-BIZ-21 | Publication validation DV8 | Unique question check across randomized sets (informational) |
| BC-BIZ-22 | Activity log — Stored | On successful create |
| BC-BIZ-23 | Activity log — Updated | On successful update (with old/new diff) |
| BC-BIZ-24 | Activity log — Trashed | On soft delete |
| BC-BIZ-25 | Activity log — Restored | On restore |
| BC-BIZ-26 | Activity log — Deleted | On force delete |
| BC-BIZ-27 | Activity log — Toggled | On status toggle |
| BC-BIZ-28 | DB transaction on create | store() wrapped in DB::beginTransaction/commit/rollback |
| BC-BIZ-29 | DB transaction on update | update() wrapped in transaction |
| BC-BIZ-30 | DB transaction on delete | destroy() wrapped in transaction |
| BC-BIZ-31 | DB transaction on restore | restore() wrapped in transaction |
| BC-BIZ-32 | DB transaction on force delete | forceDelete() wrapped in transaction |
| BC-BIZ-33 | DB transaction on toggleStatus | toggleStatus() wrapped in transaction |
| BC-BIZ-34 | Ajax toggle returns JSON | JSON `{success, is_active, message}` |
| BC-BIZ-35 | Publication validation runs only on status change to PUBLISHED | Checks `$newStatus->code === 'PUBLISHED'` |
| BC-BIZ-36 | Status scope | Only status events with `event_type='EXAM'` shown in form |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | academic_session_id | glb_academic_sessions (id) | None (NO ACTION) |
| BC-REF-02 | class_id | sch_classes (id) | None (NO ACTION) |
| BC-REF-03 | exam_type_id | lms_exam_types (id) | None (NO ACTION) |
| BC-REF-04 | grading_schema_id | slb_grade_division_master (id) | None (NO ACTION) |
| BC-REF-05 | status_id | lms_exam_status_events (id) | None (NO ACTION) |
| BC-REF-06 | created_by | sys_users (id) | None (NO ACTION) |
| BC-REF-07 | exam_id (in lms_exam_papers) | lms_exams (id) | CASCADE |
| BC-REF-08 | exam_paper_id (in lms_exam_paper_sets) | lms_exam_papers (id) | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Exam List Page Loads With All UI Elements | Page loads with search bar, status filter, exam type filter, class filter, date range filter, Add Exam button, table, pagination | — | — | ⬜ |
| TC-P02 | Filter Exams By Status | Table shows only exams matching selected status event | — | — | ⬜ |
| TC-P03 | Filter Exams By Exam Type | Table shows only exams matching selected exam type | — | — | ⬜ |
| TC-P04 | Filter Exams By Class | Table shows only exams matching selected class | — | — | ⬜ |
| TC-P05 | Filter Exams By Date Range | Table shows only exams whose start_date falls within selected range | — | — | ⬜ |
| TC-P06 | Search Exams By Title | Table filters to show only exams with title matching search term | — | — | ⬜ |
| TC-P07 | Search Exams By Code | Table filters to show only exams with code matching search term | — | — | ⬜ |
| TC-P08 | Create Exam With All Required Fields | Exam created with academic_session_id, class_id, exam_type_id, title, start_date, end_date, status_id — all saved correctly | — | — | ⬜ |
| TC-P08a | Create Form Shows Only Current Academic Session | Academic session dropdown loads only `is_current=1` session; non-current sessions not listed | — | — | ⬜ |
| TC-P09 | Create Exam With Auto-Generated Code | Code auto-generated as `EXAM_<SESSION>_<CLASS>_<TYPE>_<RANDOM6>` format; stored in DB | — | — | ⬜ |
| TC-P10 | Create Exam With Custom Code | Custom code saved; unique constraint checked | — | — | ⬜ |
| TC-P11 | Create Exam With All Optional Fields | Description, grading_schema_id, result_published mode, scheduled_result_at, is_active all saved | — | — | ⬜ |
| TC-P12 | Create Exam With IMMEDIATE Result Publishing | `result_published=IMMEDIATE` sets `is_result_published=true` | — | — | ⬜ |
| TC-P13 | Create Exam With SCHEDULED Result Publishing | `result_published=SCHEDULED` with `scheduled_result_at` datetime | — | — | ⬜ |
| TC-P14 | Create Exam With Grading Schema | `grading_schema_id` linked to `slb_grade_division_master` | — | — | ⬜ |
| TC-P15 | UUID Auto-Generated On Create | `uuid` field populated with valid UUID string | — | — | ⬜ |
| TC-P16 | created_by Auto-Set On Create | `created_by` set to authenticated user ID | — | — | ⬜ |
| TC-P17 | Edit Exam Loads Pre-Filled Data | Edit form shows existing exam data in all fields | — | — | ⬜ |
| TC-P18 | Update Exam Title | Title updated successfully; `updated_at` changed | — | — | ⬜ |
| TC-P19 | Update Exam Dates | start_date and end_date updated; before/after validation enforced | — | — | ⬜ |
| TC-P20 | Update Exam Status To PUBLISHED With Valid Structure | DV1-DV8 all pass; status changed to PUBLISHED | — | — | ⬜ |
| TC-P21 | Update Exam Status To DRAFT | Status changed back to DRAFT | — | — | ⬜ |
| TC-P22 | Update Exam — Change Result Publishing Mode MANUAL→IMMEDIATE | Mode changed from MANUAL to IMMEDIATE; `is_result_published` updated to true | — | — | ⬜ |
| TC-P22a | Update Exam — Change Result Publishing Mode MANUAL→SCHEDULED | Mode changed from MANUAL to SCHEDULED; `is_result_published` set to false | — | — | ⬜ |
| TC-P23 | Update Exam With New Custom Code | Code updated; unique constraint checked; duplicate triggers auto-suffix | — | — | ⬜ |
| TC-P24 | Update Exam — Change Grading Schema | gradding_schema_id changed | — | — | ⬜ |
| TC-P25 | View Exam Details Page | Exam details shown with title, code, session, class, type, dates, status, grading schema, result publishing, creator, stats | — | — | ⬜ |
| TC-P26 | Soft Delete Unused Exam | `is_active=false` set; `deleted_at` timestamp set; activity log "Trashed" | — | — | ⬜ |
| TC-P27 | Trash Page Shows Deleted Exams | `/lms-exam/exam/trash/view` lists only soft-deleted exams with restore + force delete buttons | — | — | ⬜ |
| TC-P28 | Restore Exam From Trash | `deleted_at=NULL`; `is_active=true`; activity log "Restored" | — | — | ⬜ |
| TC-P29 | Force Delete Unused Exam | Record permanently removed; activity log "Deleted" | — | — | ⬜ |
| TC-P30 | Toggle Status Active To Inactive (AJAX) | `is_active` flips to 0; AJAX 200 `{success:true, is_active:false}` | — | — | ⬜ |
| TC-P31 | Toggle Status Inactive To Active (AJAX) | `is_active` flips to 1; AJAX 200 `{success:true, is_active:true}` | — | — | ⬜ |
| TC-P32 | Activity Logged After Create | `SELECT * FROM glb_activity_logs WHERE event='Stored'` returns entry with exam ID and user ID | — | — | ⬜ |
| TC-P33 | Activity Logged After Update | `Updated` event logged with old/new value diff | — | — | ⬜ |
| TC-P34 | Activity Logged After Soft Delete | `Trashed` event logged | — | — | ⬜ |
| TC-P35 | Activity Logged After Restore | `Restored` event logged | — | — | ⬜ |
| TC-P36 | Activity Logged After Force Delete | `Deleted` event logged | — | — | ⬜ |
| TC-P37 | Activity Logged After Toggle | `Toggled` event logged | — | — | ⬜ |
| TC-P38 | Full Lifecycle: Create → Edit → Toggle → Delete → Trash → Restore → Force Delete | All 7 transitions successful; activity logged at each step | — | — | ⬜ |
| TC-P39 | Empty State — No Exams | Table shows "No exams found" message; Add Exam button visible | — | — | ⬜ |
| TC-P40 | Create Exam With Same Title Different Session/Class/Type | Same title allowed for different unique combo | — | — | ⬜ |
| TC-P41 | Update Exam With Same Code On Different Record | Duplicate code appends random suffix automatically via model `updating` event | — | — | ⬜ |
| TC-P42 | Status Toggle Returns Correct JSON Structure | `{success: true/false, is_active: bool, message: string}` | — | — | ⬜ |
| TC-P42a | Update Exam With No Field Changes | Submit update with identical field values; no error; redirects with success; activity log has no diff entries | — | — | ⬜ |
| TC-P42b | Update Exam — Code Field Unchanged Skips Regeneration | Exam code not modified on update; duplicate code on another record does NOT trigger suffix appending (isDirty('code') guard) | — | — | ⬜ |
| TC-P43 | Pagination Works On Exam List | Page 2 shows next 10 records; page links preserve active_tab=exam_creation | — | — | ⬜ |
| TC-P44 | Publication Validation DV1 — Set Has Questions | Creating/updating to PUBLISHED checks each set has >0 questions | — | — | ⬜ |
| TC-P45 | Publication Validation DV2 — Marks Match | Creating/updating to PUBLISHED checks total marks per set match paper total_marks | — | — | ⬜ |
| TC-P46 | Publication Validation DV3-DV4 — Blueprint Aligned | Creating/updating to PUBLISHED checks blueprint question count/marks match | — | — | ⬜ |
| TC-P47 | Publication Validation DV5-DV6 — Difficulty Distribution | Creating/updating to PUBLISHED checks difficulty config minimums | — | — | ⬜ |
| TC-P48 | Publication Validation DV7 — Scope Coverage | Creating/updating to PUBLISHED checks scope required questions present | — | — | ⬜ |
| TC-P49 | Create Exam Sets `is_active=1` By Default | New exam created with `is_active=1` | — | — | ⬜ |
| TC-P50 | Academic Hierarchy Attribute Computed | `academic_hierarchy` and `academic_hierarchy_string` return correct array/string | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `academic_session_id` | Validation error: "Academic session is required" | — | — | ⬜ |
| TC-N02 | Required — Missing `class_id` | Validation error: "Class is required" | — | — | ⬜ |
| TC-N03 | Required — Missing `exam_type_id` | Validation error: "Exam type is required" | — | — | ⬜ |
| TC-N04 | Required — Missing `title` | Validation error: "Exam title is required" | — | — | ⬜ |
| TC-N05 | Required — Missing `start_date` | Validation error: "Start date is required" | — | — | ⬜ |
| TC-N06 | Required — Missing `end_date` | Validation error: "End date is required" | — | — | ⬜ |
| TC-N07 | Required — Missing `status_id` | Validation error: "Status is required" | — | — | ⬜ |
| TC-N08 | Duplicate Combination — Same Session+Class+ExamType | "This exam type already exists for the selected session and class" | — | — | ⬜ |
| TC-N09 | Max Length — Title > 150 Characters | Validation fails on title.max | — | — | ⬜ |
| TC-N10 | Max Length — Code > 50 Characters | Validation fails on code.max | — | — | ⬜ |
| TC-N11 | Invalid Date — End Date Before Start Date | Validation error: "End date must be after or equal to start date" | — | — | ⬜ |
| TC-N12 | Invalid Date — Start Date After End Date | Validation error: "Start date must be before or equal to end date" | — | — | ⬜ |
| TC-N13 | Invalid FK — Non-Existent `class_id` | Validation error: "Selected class is invalid" | — | — | ⬜ |
| TC-N14 | Invalid FK — Non-Existent `exam_type_id` | Validation error: "Selected exam type is invalid" | — | — | ⬜ |
| TC-N15 | Invalid FK — Non-Existent `status_id` | Validation error: "Selected status is invalid" | — | — | ⬜ |
| TC-N16 | Invalid FK — Non-Existent `grading_schema_id` | Validation error on grading_schema_id.exists | — | — | ⬜ |
| TC-N17 | Invalid `result_published` Value | Validation error: "The selected result published is invalid." | — | — | ⬜ |
| TC-N18 | Duplicate Code On Create | If custom code already exists, unique validation rejects with "The code has already been taken." | — | — | ⬜ |
| TC-N19 | Edit Blocked — Exam Has Papers | "Cannot edit this exam because it has papers, allocations, or student attempts." | — | — | ⬜ |
| TC-N20 | Update Blocked — Exam Has Allocations | "Cannot update this exam because it has papers, allocations, or student attempts." | — | — | ⬜ |
| TC-N21 | Delete Blocked — Exam Has Attempts | "Cannot delete this exam because it has papers, allocations, or student attempts." | — | — | ⬜ |
| TC-N22 | Restore Blocked — Exam Has Papers | "Cannot restore this exam because it has papers, allocations, or student attempts." | — | — | ⬜ |
| TC-N23 | Force Delete Blocked — Exam Has Papers | "Cannot permanently delete this exam because it has papers, allocations, or student attempts." | — | — | ⬜ |
| TC-N24 | View Exam With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N25 | Edit/Update Exam With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N26 | Delete Exam With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N27 | Toggle Status With Invalid ID (404) | JSON 500: `{success: false, message: "Failed to update status."}` | — | — | ⬜ |
| TC-N28 | Restore Non-Deleted Exam (Already Active) | `onlyTrashed()->find()` returns null → 404 | — | — | ⬜ |
| TC-N29 | Force Delete Non-Trashed Exam | `withTrashed()->findOrFail()` finds but not trashed; forceDelete proceeds on active record | — | — | ⬜ |
| TC-N30 | Permission 403 — No Exam Permissions | 403 Forbidden on all CRUD endpoints for user without `tenant.exam.*` gates | — | — | ⬜ |
| TC-N31 | Guest Access Redirect | Redirected to /login for all exam routes | — | — | ⬜ |
| TC-N32 | XSS Injection In Title | Stored as literal string; Blade `{{ }}` escapes output; no script execution | — | — | ⬜ |
| TC-N33 | Whitespace-Only Title | Required validation catches empty/whitespace-only strings | — | — | ⬜ |
| TC-N34 | Publication DV1 Failure — Empty Set | "Set 'X' in paper 'Y' contains no questions." | — | — | ⬜ |
| TC-N35 | Publication DV2 Failure — Marks Mismatch | "Set 'X' total marks (Y) does not match Paper target marks (Z)." | — | — | ⬜ |
| TC-N36 | Publication DV3-DV4 Failure — Blueprint Mismatch | "Set 'X' is missing Y questions of type 'Z'." / marks mismatch message | — | — | ⬜ |
| TC-N37 | Publication DV5-DV6 Failure — Difficulty Mismatch | "Set 'X' lacks questions for complexity 'Y'." | — | — | ⬜ |
| TC-N38 | Publication DV7 Failure — Scope Not Covered | "Set 'X' does not cover required questions for Topic 'Y'." | — | — | ⬜ |
| TC-N39 | Status Toggle With Invalid Boolean | Validation error: "The is active field must be true or false." | — | — | ⬜ |
| TC-N39a | Status Toggle — Model Save Failure | Simulate DB constraint failure during `$exam->save()` in toggleStatus; returns JSON `{success: false}` without exception (note: not 500) | — | — | ⬜ |
| TC-N40 | `scheduled_result_at` Before `start_date` | Validation error on scheduled_result_at.after_or_equal | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create Exam → UUID Auto-Generated | `uuid` field populated as string UUID in `lms_exams` table | — | — | ⬜ |
| TC-D02 | A | Create Exam → Code Auto-Generated | `code` follows pattern `EXAM_<SESSION>_<CLASS>_<TYPE>_<RANDOM6>` | — | — | ⬜ |
| TC-D03 | B | Soft Delete Exam → Exam Papers Cascade (DDL) | DDL specifies CASCADE on `fk_paper_exam`; deleting exam cascades to papers | — | — | ⬜ |
| TC-D04 | C | Restore Exam → Papers Remain Deleted | `restore()` only restores exam, not child papers (no cascading restore) | — | — | ⬜ |
| TC-D05 | D | Cannot Delete Academic Session/Class/Type While Exam References (FK) | FK constraint error when deleting referenced session/class/type | — | — | ⬜ |
| TC-D06 | E | Toggle Status — Inactive Exam Hidden From Dropdowns | Inactive exam excluded from exam dropdown lists | — | — | ⬜ |
| TC-D07 | F | Update Exam — Change `academic_session_id` | Exam moves to new academic session (FK must exist) | — | — | ⬜ |
| TC-D08 | G | Concurrent Update — Two Users Edit Same Exam | Last save wins; no data corruption | — | — | ⬜ |
| TC-D09 | H | Rapid Status Toggle (Race Condition) | Handles rapid toggles without data corruption | — | — | ⬜ |
| TC-D10 | I | Publication Flow — DV Fails Blocks Status Change | When DV fails, status not updated; transaction rolled back | — | — | ⬜ |
| TC-D11 | J | Publication Flow — DV Passes Status Changes | When DV passes, status updated to PUBLISHED | — | — | ⬜ |
| TC-D12 | K | IMMEDIATE Result Publishing After Status Change | When `result_published=IMMEDIATE`, `is_result_published` set to true on create and update | — | — | ⬜ |
| TC-D13 | L | Exam Created With `is_active` Default 1 | Model default ensures `is_active=1` for new records | — | — | ⬜ |
| TC-D14 | M | DB | P1 | lms_exams with existing exam record | Unique Composite Constraint — uq_exam_session_class_type (academic_session_id, class_id, exam_type_id) | Inserting duplicate (academic_session_id, class_id, exam_type_id) combination at DB level throws integrity constraint violation | — | — | ⬜ |
| TC-D15 | N | DB | P1 | lms_exams with existing exam record | UUID Unique Constraint — uq_exam_uuid | Duplicate UUID insertion throws integrity constraint violation | — | — | ⬜ |
| TC-D16 | O | DB | P1 | lms_exams with existing exam record | Code Unique Constraint — uq_exam_code | Duplicate code insertion throws integrity constraint violation | — | — | ⬜ |
| TC-D17 | P | Integration | P1 | Exam with papers, allocations, attempts | Usage Check — ExamUsageCheckService::isUsed() | Returns true when exam has papers/allocations/attempts; blocks edit/delete/restore/forceDelete | — | — | ⬜ |
| TC-D18 | Q | Integration | P1 | Exam controller | Activity Log — All CRUD Events | Activity logged for Stored, Updated, Trashed, Restored, Deleted, Toggled events | — | — | ⬜ |
| TC-D19 | R | Unit | P1 | Exam model | Model Table Name | `Exam` model has `protected $table = 'lms_exams'` matching DB table | — | — | ⬜ |
| TC-D20 | S | Unit | P1 | Exam model | Model Fillable | `$fillable` includes all 14 columns listed in requirement | — | — | ⬜ |
| TC-D21 | T | Unit | P1 | Exam model | SoftDeletes Trait | `Exam` model uses `SoftDeletes` trait; `deleted_at` column exists | — | — | ⬜ |
| TC-D22 | U | Unit | P1 | Exam model | Model Relationships | `Exam` model has belongsTo: academicSession, class, examType, gradingSchema, status, creator; hasMany: examPapers; hasManyThrough: examAllocations, examAttempts, examResults | — | — | ⬜ |
| TC-D23 | V | Unit | P1 | Exam model | $casts Definition | `Exam` model casts: is_active, is_result_published as boolean; start_date, end_date as date; scheduled_result_at as datetime; uuid as string | — | — | ⬜ |
| TC-D24 | W | Unit | P1 | Exam model | Boot Creating Event | `creating` event sets uuid, code (if empty), created_by (if empty) | — | — | ⬜ |
| TC-D25 | X | Unit | P1 | Exam model | Boot Updating Event | `updating` event checks code uniqueness and appends random suffix on duplicate | — | — | ⬜ |
| TC-D26 | Y | Unit | P1 | Exam model | Accessors | Academic hierarchy, is_published, is_draft, is_concluded, is_archived, duration_days, is_currently_active, statistics attributes computed correctly | — | — | ⬜ |
| TC-D27 | Z | Unit | P1 | Exam model | Scopes | active, published, draft, concluded, archived, byAcademicSession, byClass, byExamType, byCreator, dateRange scopes defined | — | — | ⬜ |
| TC-D28 | AA | Unit | P1 | ExamRequest validation | Unique Validation | exam_type_id unique scope (academic_session_id, class_id) ignoring own ID | — | — | ⬜ |
| TC-D29 | AB | Unit | P1 | ExamRequest validation | Required Validation | Required rules for academic_session_id, class_id, exam_type_id, title, start_date, end_date, status_id | — | — | ⬜ |
| TC-D30 | AC | Unit | P1 | ExamRequest validation | Boolean Casting | `prepareForValidation()` casts is_active and is_result_published to boolean | — | — | ⬜ |
| TC-D31 | AD | Unit | P1 | ExamPolicy | Permission Gates | ExamPolicy defines viewAny, view, create, update, delete, restore, forceDelete, status, import, export, print gates | — | — | ⬜ |
| TC-D32 | AE | Unit | P1 | Routes | Resource + Additional Routes | Routes for exam CRUD + trashed, restore, forceDelete, toggleStatus | — | — | ⬜ |
| TC-D33 | AF | Unit | P1 | ExamUsageCheckService | getUsageCount Returns Correct Count | Papers count + allocations count + attempts count | — | — | ⬜ |
| TC-D34 | AG | Unit | P1 | ExamUsageCheckService | getUsageDetails Returns Detailed Breakdown | Returns array with ExamPapers, Allocations, StudentAttempts counts | — | — | ⬜ |
| TC-D35 | AH | Unit | P1 | ExamQueryService | examsQuery Builds Correct Filter Query | Applies filters: search, status_id, exam_type_id, class_id, date_range, data_type, is_active | — | — | ⬜ |
| TC-D36 | AI | Unit | P1 | LmsExamController | Transaction Handling | All state-changing methods use DB::beginTransaction/commit/rollback | — | — | ⬜ |
| TC-D37 | AJ | Unit | P1 | LmsExamController | findOrFail Usage | edit, update, show, destroy use `Exam::findOrFail($id)` — returns 404 when not found | — | — | ⬜ |
| TC-D38 | AK | Unit | P1 | LmsExamController | Gate Authorization Before CRUD | `Gate::authorize('tenant.exam.*')` called before each CRUD operation | — | — | ⬜ |
| TC-D39 | AL | Integration | P1 | LmsExamController | Publication Validation Runs Before Status Change | validateExamDifficulty() called only when new status code = 'PUBLISHED'; errors rolled back | — | — | ⬜ |
| TC-D40 | AM | Cross-Module | P1 | Exam Papers — lms_exam_papers FK References lms_exams.id | `lms_exam_papers.exam_id` FK → `lms_exams.id` with ON DELETE CASCADE; deleting an exam cascades to all its papers | — | — | ⬜ |
| TC-D41 | AN | Cross-Module | P1 | Allocations — lms_exam_allocations Links Through ExamPaper | Allocations reference exam_paper_id; when exam deleted, papers cascade-delete → allocations cascade-delete | — | — | ⬜ |
| TC-D42 | AO | Cross-Module | P1 | Attempts — ExamAttempt Links Through ExamPaper | Student attempts reference exam_paper_id; cascade chain from exam → papers → attempts | — | — | ⬜ |
| TC-D43 | AP | Cross-Module | P1 | Status Events — Only EXAM type shown in form | `ExamStatusEvent::where('event_type', 'EXAM')` filter applied; PAPER type statuses excluded | — | — | ⬜ |
| TC-D44 | AQ | Unit | P1 | ExamController | ToggleStatus Uses update Gate | `toggleStatus` authorizes via `tenant.exam.update` gate | — | — | ⬜ |
| TC-D45 | AR | Integration | P1 | Exam model | generateExamCode Handles Duplicate By Appending Counter | When generated code already exists, appends `_1`, `_2` etc. until unique | — | — | ⬜ |
| TC-D46 | AS | Code Review | P1 | View — Blade @can Directives For Exam CRUD Buttons | @can('tenant.exam.create'), @can('tenant.exam.edit'), @can('tenant.exam.delete'), @can('tenant.exam.status') wrap respective buttons | — | — | ◌ |
| TC-D47 | AT | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Blade views use isset/optional for relationships; null values displayed gracefully | — | — | ◌ |
| TC-D48 | AU | Code Review | P1 | Controller — JSON Success Response After ToggleStatus | toggleStatus returns response()->json() with success flag | — | — | ◌ |
| TC-D49 | AV | Unit | P1 | ExamRequest authorize() | FormRequest Gates | authorize() checks tenant.exam.create for POST, tenant.exam.update for PUT/PATCH, tenant.exam.delete for DELETE | — | — | ◌ |
| TC-D50 | AW | Unit | P1 | Exam model | Mutator — scheduled_result_at | `setScheduledResultAtAttribute` converts datetime-local format to Y-m-d H:i:s | — | — | ◌ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.exam.create'), @can('tenant.exam.edit'), @can('tenant.exam.delete'), @can('tenant.exam.status'), @can('tenant.exam.view'), @canany(['tenant.exam.restore', 'tenant.exam.forceDelete']) for access control on all CRUD buttons and actions | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | Exam routes registered in breadcrumb config; breadcrumb visible and links correctly to parent screens | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — try-catch Exception Handling on All CRUD Methods | All state-changing methods (store, update, destroy, restore, forceDelete, toggleStatus) use try-catch; exceptions are caught, logged, and user receives error feedback | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — DB Transactions on Multi-Step Writes | Methods use DB::beginTransaction/commit/rollback; partial writes do not occur on failure | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Relationship expressions in Blade use isset/$var?->relation/null-safe operator; no undefined property errors when relation is null | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | View — Flash Messages After CRUD | After CRUD actions, controller redirects with success/error flash; Blade displays alert with correct action-specific message | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Controller — findOrFail on All ID-Dependent Methods | edit(), update(), show(), destroy(), restore(), forceDelete(), toggleStatus() use findOrFail for 404 handling | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | Controller — Usage Check Before Edit/Update/Destroy/Restore/ForceDelete | ExamUsageCheckService::isUsed() called before edit, update, destroy, restore, forceDelete; blocks with error message when used | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | Controller — Publication Validation Only on PUBLISHED | validateExamDifficulty() only called when $newStatus->code === 'PUBLISHED' | — | — | ◌ |
| TC-CR10 | CR | Code Review | P1 | Model — Exam Boot Events | creating event sets uuid, code, created_by; updating event handles code uniqueness | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR03: Controller — try-catch Exception Handling on All CRUD Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open LmsExamController.php | Controller class found in Modules/LmsExam/Http/Controllers/ |
| 2 | Inspect store() method | Business logic wrapped in try {} catch(\Exception $e) {}; on exception, DB rollback and error logged |
| 3 | Inspect update() method | try-catch present; findOrFail inside try; validation errors from FormRequest caught before try block |
| 4 | Inspect destroy() method | try-catch present; is_active toggle inside try; activityLog inside try |
| 5 | Inspect restore() method | try-catch present; is_active restore inside try |
| 6 | Inspect forceDelete() method | try-catch present; withTrashed+findOrFail inside try |
| 7 | Inspect toggleStatus() method | try-catch present; DB transaction inside try |
| 8 | Simulate DB failure during store (e.g. unique constraint violation) | Exception caught; user redirected with error message; no partial data written |

#### TC-CR04: Controller — DB Transactions on Multi-Step Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open LmsExamController.php | Controller class found |
| 2 | Inspect store() method | DB::beginTransaction() before create; DB::commit() after activityLog; DB::rollback() on exception |
| 3 | Inspect update() method | DB::beginTransaction() before update; commit after activityLog; rollback on exception |
| 4 | Inspect destroy() method | is_active=false toggle + delete() + activityLog all in single transaction |
| 5 | Inspect restore() method | is_active=true + restore() + activityLog in single transaction |
| 6 | Inspect forceDelete() method | forceDelete() + activityLog in single transaction |
| 7 | Verify no partial writes occur | If activityLog throws exception after model save, model changes are rolled back |

#### TC-CR05: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open index.blade.php for Exam | View file found in lmsexam::exam/ |
| 2 | Scan for relationship access patterns (e.g. $record->relation->field) | All such expressions use isset() or optional() or ?-> null-safe operator |
| 3 | Scan for foreach loops over relationships | Loop target checked with isset() or !empty() before iterating |
| 4 | Create a record with null relationship (e.g. null grading_schema_id) | View renders without undefined index/property error |
| 5 | Load index page with records that have missing relations | No 500 errors; null values displayed gracefully (dash or empty string) |

#### TC-CR06: View — Flash Messages After CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new exam | POST to store(); redirects with session flash |
| 2 | Verify success message after create | Page shows success alert: 'Exam created successfully' (flash('created.exam')) |
| 3 | Update the exam | PUT to update(); redirects with flash |
| 4 | Verify success message after update | 'Exam updated successfully' |
| 5 | Soft delete the exam | DELETE to destroy(); redirects with flash |
| 6 | Verify success message after delete | 'Exam trashed successfully' |
| 7 | Restore from trash | POST to restore(); redirects with flash |
| 8 | Verify success message after restore | 'Exam restored successfully' |
| 9 | Force delete from trash | DELETE to forceDelete(); redirects with flash |
| 10 | Verify success message after force delete | 'Exam force deleted successfully' |

#### TC-CR01: Blade @can Directives — Permission-based Visibility for All Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php for add/create button | @can('tenant.exam.create') wraps the Add Exam button; user without create permission does not see it |
| 2 | Inspect row-level action buttons (view, edit, delete, status toggle) | @can('tenant.exam.view'), @can('tenant.exam.edit'), @can('tenant.exam.delete'), @can('tenant.exam.status') used appropriately |
| 3 | Inspect trash.blade.php for restore/forceDelete buttons | @canany(['tenant.exam.restore', 'tenant.exam.forceDelete']) wraps action buttons in trash view |
| 4 | Inspect show.blade.php for edit button | @can('tenant.exam.edit') wraps the Edit button; disabled with tooltip when `$isUsed` is true |
| 5 | Log in as user with all permissions | All buttons visible and functional |
| 6 | Log in as user with viewAny only (no create/edit/delete) | Add Exam button hidden; action columns show view icon only or no actions |

#### TC-CR07: Controller — findOrFail on All ID-Dependent Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open LmsExamController.php | Controller class found |
| 2 | Inspect show($id) method | Uses Exam::findOrFail($id) |
| 3 | Inspect edit($id) method | Uses Exam::findOrFail($id) |
| 4 | Inspect update($request, $id) method | Uses Exam::findOrFail($id) |
| 5 | Inspect destroy($id) method | Uses Exam::findOrFail($id) |
| 6 | Inspect restore($id) method | Uses Exam::onlyTrashed()->findOrFail($id) |
| 7 | Inspect forceDelete($id) method | Uses Exam::withTrashed()->findOrFail($id) |
| 8 | Inspect toggleStatus($request, $id) method | Uses Exam::findOrFail($id) |

#### TC-CR08: Controller — Usage Check Before Edit/Update/Destroy/Restore/ForceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open LmsExamController.php | Controller class found |
| 2 | Inspect edit($id) method | `$usageCheck->isUsed($id)` called before proceeding; if true → back with error |
| 3 | Inspect update($request, $id) method | Usage check called first; if used → back with error |
| 4 | Inspect destroy($id) method | Usage check called first; if used → back with error |
| 5 | Inspect restore($id) method | Usage check called first; if used → back with error |
| 6 | Inspect forceDelete($id) method | Usage check called first; if used → back with error |
| 7 | Verify toggleStatus does NOT check usage | Status can be toggled even when exam is in use |

#### TC-CR09: Controller — Publication Validation Only on PUBLISHED

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open LmsExamController.php | Controller class found |
| 2 | Inspect update() method | After model update, new status looked up: `ExamStatusEvent::find($examData['status_id'])` |
| 3 | Check condition | `if ($newStatus && $newStatus->code === 'PUBLISHED')` wraps validateExamDifficulty() call |
| 4 | Verify other status transitions skip validation | DRAFT → DRAFT, CONCLUDED → ARCHIVED do not trigger DV checks |
| 5 | Verify DV errors rollback transaction | On validation failure, DB::rollBack() called, status not changed |

#### TC-CR10: Model — Exam Boot Events

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Exam.php model | Model class in Modules/LmsExam/Models/ |
| 2 | Inspect boot() method | `static::creating()` function present |
| 3 | Verify uuid generation | `$model->uuid = (string) Str::uuid()` |
| 4 | Verify code generation | `$model->code = $model->generateExamCode()` called when empty |
| 5 | Verify created_by auto-set | `$model->created_by = auth()->id()` when empty |
| 6 | Inspect `static::updating()` function | Checks `$model->isDirty('code')` |
| 7 | Verify code duplicate handling on update | If code already exists for other record, appends `_` . Str::random(4) |

#### TC-P01: Exam List Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Navigate to Exam → Creation & Allocation tab | Page loads at `/lms-exam/creation-allocation` with `active_tab=exam_creation` |
| 3 | Check the search input | Search text field with placeholder "Search Exam..." present |
| 4 | Check the status filter dropdown | Dropdown "All Status" with list of status events present |
| 5 | Check the exam type filter dropdown | Dropdown "All Types" with list of exam types present |
| 6 | Check the class filter dropdown | Dropdown "All Classes" with list of active classes present |
| 7 | Check the date range filter | Date from/to picker fields present |
| 8 | Check the "Add Exam" button | Button visible (if create permission) |
| 9 | Check the exam table | Columns: Code, Title, Class, Exam Type, Dates, Status, Actions |
| 10 | Check pagination | If 10+ exams exist, pagination links appear |

#### TC-P02: Filter Exams By Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with status DRAFT and another with PUBLISHED | Both exist |
| 2 | Select DRAFT from status dropdown | Page reloads with `?status_id={draft_id}` |
| 3 | Verify table shows only DRAFT exam | PUBLISHED exam not shown |
| 4 | Clear filter | Both exams visible |

#### TC-P03: Filter Exams By Exam Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with type UT-1 and another with ANNUAL | Both exist |
| 2 | Select UT-1 from exam type dropdown | Only UT-1 exam shown |
| 3 | Clear filter | Both visible |

#### TC-P04: Filter Exams By Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam for Class 10 and another for Class 9 | Both exist |
| 2 | Select Class 10 from class dropdown | Only Class 10 exam shown |
| 3 | Clear filter | Both visible |

#### TC-P05: Filter Exams By Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with start_date 2026-01-15 and another with 2026-03-20 | Both exist |
| 2 | Set date_from=2026-01-01, date_to=2026-02-28 | Apply filter |
| 3 | Verify only January exam shown | March exam not visible |
| 4 | Clear date range | Both visible |

#### TC-P06: Search Exams By Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exams: "Annual Exam 2026", "Half Yearly Exam 2026", "Unit Test 1" | 3 exams exist |
| 2 | Type "Annual" in search box and press Enter | Page reloads with `?search=Annual` |
| 3 | Verify table shows only "Annual Exam 2026" | Other 2 exams not visible |
| 4 | Clear search | All 3 exams visible again |

#### TC-P07: Search Exams By Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with code = "EXAM_2026_ANNUAL_C10_ABC123" | Exam exists |
| 2 | Type "ANNUAL" in search box | Exam found by code match |
| 3 | Clear search | All exams visible |

#### TC-P08: Create Exam With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Creation & Allocation tab, Exam tab | Page loads |
| 2 | Click "Add Exam" button | Create form opens at `/lms-exam/exam/create` |
| 3 | Enter title: "Annual Exam 2025-26" | Field filled |
| 4 | Academic session auto-selected (current session) | Session selected |
| 5 | Select class from dropdown | Class selected |
| 6 | Select exam type from dropdown | Exam type selected |
| 7 | Enter start_date: 2026-03-01 | Date set |
| 8 | Enter end_date: 2026-03-15 | Date set |
| 9 | Select status: DRAFT | Status selected |
| 10 | Click "Create Exam" | POST to `/lms-exam/exam/store` |
| 11 | Check response | Success: "Exam created successfully." |
| 12 | Redirect to creation-allocation tab with active_tab=exam_creation | Page reloads, exam visible in table |
| 13 | DB check: `SELECT * FROM lms_exams WHERE title='Annual Exam 2025-26'` | Record exists with all required fields, `uuid` populated, `code` auto-generated, `is_active=1` |

#### TC-P09: Create Exam With Auto-Generated Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam without providing code | Code field left empty |
| 2 | Fill all required fields (title, session, class, exam_type, dates, status) | Fields filled |
| 3 | Click "Create Exam" | Exam created |
| 4 | DB check: `SELECT code FROM lms_exams WHERE title=?` | Code follows pattern `EXAM_<SESSION>_<CLASS>_<TYPE>_<RANDOM6>` |
| 5 | Verify code is globally unique | No other record with same code |

#### TC-P10: Create Exam With Custom Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all required fields | Fields filled |
| 2 | Enter custom code: "MY_EXAM_2026_001" | Code field filled |
| 3 | Click "Create Exam" | Exam created |
| 4 | DB check: `SELECT code FROM lms_exams WHERE code='MY_EXAM_2026_001'` | Record exists with exact custom code |

#### TC-P11: Create Exam With All Optional Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Exam form | Form visible |
| 2 | Fill required fields (title, session, class, exam_type, dates, status) | Required fields set |
| 3 | Enter description: "This is the annual examination for all students" | Optional field filled |
| 4 | Select grading schema from dropdown | Schema selected |
| 5 | Set result_published = SCHEDULED | Mode selected |
| 6 | Set scheduled_result_at = 2026-03-20 10:00 | Datetime set |
| 7 | Leave is_active = ON (default) | Toggle ON |
| 8 | Click "Create Exam" | Exam created |
| 9 | DB check: `SELECT * FROM lms_exams WHERE title=?` | All optional fields saved with correct values |
| 10 | Verify `is_active` = 1 | Default active |

#### TC-P12: Create Exam With IMMEDIATE Result Publishing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all required fields | Fields set |
| 2 | Set result_published = IMMEDIATE | Mode selected |
| 3 | Click "Create Exam" | Exam created |
| 4 | DB check: `SELECT result_published, is_result_published FROM lms_exams WHERE title=?` | result_published='IMMEDIATE', is_result_published=1 |

#### TC-P13: Create Exam With SCHEDULED Result Publishing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all required fields | Fields set |
| 2 | Set result_published = SCHEDULED | Mode selected |
| 3 | Set scheduled_result_at = 2026-03-20 14:30 | Datetime set |
| 4 | Click "Create Exam" | Exam created |
| 5 | DB check: `SELECT result_published, scheduled_result_at, is_result_published FROM lms_exams` | scheduled_result_at saved, is_result_published=0 |

#### TC-P14: Create Exam With Grading Schema

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all required fields | Fields set |
| 2 | Select grading schema from dropdown | e.g., "A+, A, B+, B, C" |
| 3 | Click "Create Exam" | Exam created |
| 4 | DB check: `SELECT grading_schema_id FROM lms_exams WHERE title=?` | grading_schema_id = selected schema ID |

#### TC-P15: UUID Auto-Generated On Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam | Exam created |
| 2 | DB check: `SELECT uuid FROM lms_exams WHERE id={id}` | uuid is a valid UUID string (36 chars with hyphens) |

#### TC-P16: created_by Auto-Set On Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin user with ID = 1 | Authenticated |
| 2 | Create exam | Exam created |
| 3 | DB check: `SELECT created_by FROM lms_exams WHERE id={id}` | created_by = 1 |

#### TC-P17: Edit Exam Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with all fields filled | Exam exists with ID=X |
| 2 | Click "Edit" button on that exam | Navigates to `/lms-exam/exam/{X}/edit` |
| 3 | Verify form pre-filled | title, code, session, class, exam_type, dates, status, grading_schema, result_publishing all match |
| 4 | Verify code field editable | Code field is input, not read-only |

#### TC-P18: Update Exam Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam: title="Old Title" | Exam exists with ID=X |
| 2 | Navigate to edit page | Form pre-filled |
| 3 | Change title to "New Title" | Field updated |
| 4 | Click "Update Exam" | PUT request to `/lms-exam/exam/{X}` |
| 5 | Check response | "Exam updated successfully." |
| 6 | DB check: `SELECT title, updated_at FROM lms_exams WHERE id={X}` | title="New Title", updated_at changed |

#### TC-P19: Update Exam Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam: start=2026-03-01, end=2026-03-15 | Exam exists |
| 2 | Edit: start=2026-04-01, end=2026-04-15 | Dates changed |
| 3 | Click "Update" | Update succeeds |
| 4 | DB check | start_date=2026-04-01, end_date=2026-04-15 |

#### TC-P20: Update Exam Status To PUBLISHED With Valid Structure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with DRAFT status, with properly set up papers, sets, scopes, blueprints, difficulty config | Fully structured exam |
| 2 | Edit exam, set status to PUBLISHED | Status changed |
| 3 | Click "Update" | DV1-DV8 all pass |
| 4 | DB check: `SELECT status_id FROM lms_exams WHERE id={id}` | status_id points to PUBLISHED status event |
| 5 | Activity log: `Updated` event logged with status change | Old/new diff includes status_id |

#### TC-P21: Update Exam Status To DRAFT

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with PUBLISHED status | Exam published |
| 2 | Edit exam, set status to DRAFT | Status changed |
| 3 | Click "Update" | No DV validation (code is not PUBLISHED) |
| 4 | DB check | status_id points to DRAFT status event |

#### TC-P22: Update Exam — Change Result Publishing Mode

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with result_published=MANUAL | Exam exists |
| 2 | Edit: change to IMMEDIATE | Mode changed |
| 3 | Click "Update" | Update succeeds |
| 4 | DB check: `SELECT result_published, is_result_published FROM lms_exams` | IMMEDIATE, is_result_published=1 |

#### TC-P22a: Update Exam — Change Result Publishing Mode MANUAL→SCHEDULED

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with result_published=MANUAL | Exam exists, is_result_published=0 |
| 2 | Edit: change to SCHEDULED, set scheduled_result_at | Mode changed, datetime set |
| 3 | Click "Update" | Update succeeds |
| 4 | DB check: `SELECT result_published, is_result_published FROM lms_exams` | SCHEDULED, is_result_published=0 |

#### TC-P23: Update Exam With New Custom Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with code="OLD_CODE" | Exam exists |
| 2 | Edit: change code to "NEW_CODE" | Code changed |
| 3 | Click "Update" | Update succeeds |
| 4 | DB check: `SELECT code FROM lms_exams WHERE id={id}` | code="NEW_CODE" |
| 5 | If NEW_CODE already exists for another exam | Code auto-changed to "NEW_CODE_<random4>" |

#### TC-P24: Update Exam — Change Grading Schema

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with grading_schema_id=1 | Exam exists |
| 2 | Edit: change to grading_schema_id=2 | Schema changed |
| 3 | Click "Update" | Update succeeds |
| 4 | DB check | grading_schema_id=2 |

#### TC-P25: View Exam Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with all fields filled | Exam exists |
| 2 | Click "View" button (eye icon) on that exam | Navigates to `/lms-exam/exam/{id}` |
| 3 | Check page heading | Exam title displayed |
| 4 | Check code displayed | Auto-generated or custom code shown |
| 5 | Check academic hierarchy | Session > Class > Exam Type breadcrumb shown |
| 6 | Check dates displayed | start_date and end_date shown |
| 7 | Check status badge | Color-coded status badge |
| 8 | Check grading schema | Grading schema name shown (if set) |
| 9 | Check result publishing mode | IMMEDIATE/MANUAL/SCHEDULED shown |
| 10 | Check creator name | Created by user name shown |
| 11 | Check usage status | If has papers, shows "In Use" indicator |

#### TC-P26: Soft Delete Unused Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with no papers/allocations/attempts | Exam exists with ID=X |
| 2 | Click delete button on that exam row | SweetAlert "Are you sure?" |
| 3 | Click "Cancel" | Alert closes, exam not deleted |
| 4 | Click delete again, then confirm | AJAX DELETE sent |
| 5 | Check toast | Green toast: "Exam trashed successfully" |
| 6 | DB check: `SELECT is_active, deleted_at FROM lms_exams WHERE id={X}` | is_active=0, deleted_at NOT NULL |
| 7 | Verify exam no longer visible in main table | Disappeared from list |
| 8 | Activity log: `SELECT * FROM glb_activity_logs WHERE event='Trashed' ORDER BY id DESC LIMIT 1` | "Trashed" event logged |

#### TC-P27: Trash Page Shows Deleted Exams

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete 2 exams | Both trashed |
| 2 | Click "Trash" button | Navigates to `/lms-exam/exam/trash/view` |
| 3 | Check trash page loads | Heading: "Exam Trash" |
| 4 | Check table lists only trashed exams | Both deleted exams visible with Restore and Force Delete buttons |
| 5 | Verify active exams not shown | Only soft-deleted records |

#### TC-P28: Restore Exam From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | From trash page, click "Restore" button on a trashed exam | POST to restore route |
| 2 | Check toast | "Exam restored successfully." |
| 3 | DB check: `SELECT deleted_at, is_active FROM lms_exams WHERE id={X}` | deleted_at=NULL, is_active=1 |
| 4 | Verify exam visible again on main list | Back in active table |

#### TC-P29: Force Delete Unused Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | From trash page, click "Delete Forever" button | SweetAlert confirmation |
| 2 | Confirm | DELETE to forceDelete route |
| 3 | Check toast | "Exam force deleted successfully." |
| 4 | DB check: `SELECT * FROM lms_exams WHERE id={X}` | Record permanently removed |
| 5 | Activity log: `SELECT * FROM glb_activity_logs WHERE event='Deleted'` | "Deleted" event logged |

#### TC-P30: Toggle Status Active To Inactive (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with is_active=1 | Exam active |
| 2 | Click status toggle button on that exam row | AJAX POST to `/lms-exam/exam/{id}/toggle-status` with `is_active=0` |
| 3 | Check response | JSON `{success: true, is_active: false, message: "Status updated"}` |
| 4 | DB check: `SELECT is_active FROM lms_exams WHERE id={id}` | is_active=0 |
| 5 | UI check: Toggle button appearance changed | Gray/red "Inactive" badge |

#### TC-P31: Toggle Status Inactive To Active (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with is_active=0 | Exam inactive |
| 2 | Click status toggle button | AJAX POST with `is_active=1` |
| 3 | Check response | `{success: true, is_active: true}` |
| 4 | DB check | is_active=1 |
| 5 | UI check | Green "Active" badge |

#### TC-P32: Activity Logged After Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with title "LogTest" | Exam created with ID=X |
| 2 | Query activity log | `activityLog()` called with $exam, 'Stored' |
| 3 | DB check: `SELECT * FROM glb_activity_logs WHERE loggable_id={X} AND event='Stored'` | Entry exists with message "A new exam was created." and performed_by |

#### TC-P33: Activity Logged After Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update exam title | Exam updated |
| 2 | DB check: `SELECT * FROM glb_activity_logs WHERE loggable_id={X} AND event='Updated' ORDER BY id DESC` | Entry exists with JSON diff of changed attributes |

#### TC-P34: Activity Logged After Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete exam | Exam trashed |
| 2 | Query activity log for 'Trashed' event | Entry exists |

#### TC-P35: Activity Logged After Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore exam from trash | Exam restored |
| 2 | Query activity log for 'Restored' event | Entry exists |

#### TC-P36: Activity Logged After Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force delete exam from trash | Exam permanently deleted |
| 2 | Query activity log for 'Deleted' event | Entry exists |

#### TC-P37: Activity Logged After Toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle exam status | Status toggled |
| 2 | Query activity log for 'Toggled' event | Entry exists |

#### TC-P38: Full Lifecycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam "Lifecycle Test" | Exam created successfully; Stored event logged |
| 2 | Edit exam — change title | Title updated; Updated event logged with diff |
| 3 | Toggle status inactive | Status toggled; Toggled event logged |
| 4 | Toggle status active | Status toggled back |
| 5 | Soft delete exam | is_active=0, deleted_at set; Trashed event logged |
| 6 | Restore exam | is_active=1, deleted_at=null; Restored event logged |
| 7 | Force delete exam | Record removed; Deleted event logged |

#### TC-P39: Empty State — No Exams

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no exams exist for selected filters | Empty dataset |
| 2 | Navigate to Exam tab | Table shows "No exams found" message |
| 3 | Check Add Exam button | Button visible (if create permission) |

#### TC-P40: Create Exam With Same Title Different Session/Class/Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam: title="Annual Exam", session=S1, class=C1, type=T1 | First exam created |
| 2 | Create exam: title="Annual Exam", session=S2, class=C2, type=T2 | Second exam created with same title |
| 3 | DB check: Both records exist | Two exams with same title, different combos |

#### TC-P41: Update Exam With Same Code On Different Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam A with code="CODE123" | Exam A exists |
| 2 | Create exam B with code="OTHER" | Exam B exists |
| 3 | Edit exam B, change code to "CODE123" | Update triggers `updating` event |
| 4 | Model detects duplicate | Appends random suffix: "CODE123_XyZ1" |
| 5 | DB check: `SELECT code FROM lms_exams WHERE id=B.id` | code="CODE123_XyZ1" (unique) |

#### TC-P42: Status Toggle Returns Correct JSON Structure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle exam status via AJAX | Response received |
| 2 | Inspect response JSON | Contains keys: success (bool), is_active (bool), message (string) |
| 3 | Verify HTTP status | 200 OK on success |

#### TC-P43: Pagination Works On Exam List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 15 exams | 15 exams exist |
| 2 | Navigate to Exam tab | Shows 10 exams, page 1 |
| 3 | Click page 2 | Shows remaining 5 exams; URL has `?exam_page=2&active_tab=exam_creation` |

#### TC-P44: Publication Validation DV1 — Set Has Questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with paper that has a set but NO questions | Exam set up |
| 2 | Try to publish exam (change status to PUBLISHED) | Update attempted |
| 3 | Validation fails | Error: "Set 'SET_A' in paper 'Math Paper' contains no questions." |
| 4 | DB check: status NOT changed | Still DRAFT |

#### TC-P45: Publication Validation DV2 — Marks Match

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with total_marks=100, set with questions summing to 80 | Marks mismatch |
| 2 | Try to publish | Error: "Set 'SET_A' total marks (80.00) does not match Paper target marks (100.00)." |

#### TC-P46: Publication Validation DV3-DV4 — Blueprint Aligned

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create blueprint requiring 5 MCQs but set has only 3 MCQs | Count mismatch |
| 2 | Try to publish | Error: "Set 'SET_A' is missing 2 questions of type 'Section A'." |
| 3 | Fix marks mismatch | Blueprint marks 50 vs set marks 30 → second error |

#### TC-P47: Publication Validation DV5-DV6 — Difficulty Distribution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Configure difficulty rule: min 20% Easy, paper has 0 Easy questions | Rule not met |
| 2 | Try to publish | Error: "Set 'SET_A' lacks questions for complexity 'Easy'. (Actual: 0, Min Required: 2)" |

#### TC-P48: Publication Validation DV7 — Scope Coverage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create scope requiring 3 questions from Topic X, set has 0 from Topic X | Scope not covered |
| 2 | Try to publish | Error: "Set 'SET_A' does not cover required questions for Topic 'X'." |

#### TC-P49: Create Exam Sets is_active=1 By Default

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam without specifying is_active | Default = 1 |
| 2 | DB check: `SELECT is_active FROM lms_exams WHERE id={id}` | is_active=1 |

#### TC-P50: Academic Hierarchy Attribute Computed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with session S1, class C1, type T1 | Exam exists |
| 2 | Access `$exam->academic_hierarchy` | Array: [academic_session => S1 name, class => C1 name, exam_type => T1 name] |
| 3 | Access `$exam->academic_hierarchy_string` | String: "S1 name > C1 name > T1 name" |

#### TC-N01: Required — Missing academic_session_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill all fields EXCEPT academic_session_id | Leave session empty |
| 3 | Submit form | Validation error: "Academic session is required" |
| 4 | Form re-displayed with input values preserved | Old values in fields |

#### TC-N02: Required — Missing class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all fields EXCEPT class_id | Leave class empty |
| 2 | Submit | Error: "Class is required" |

#### TC-N03: Required — Missing exam_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all fields EXCEPT exam_type_id | Leave type empty |
| 2 | Submit | Error: "Exam type is required" |

#### TC-N04: Required — Missing title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all fields EXCEPT title | Leave title empty |
| 2 | Submit | Error: "Exam title is required" |

#### TC-N05: Required — Missing start_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all fields EXCEPT start_date | Leave start date empty |
| 2 | Submit | Error: "Start date is required" |

#### TC-N06: Required — Missing end_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all fields EXCEPT end_date | Leave end date empty |
| 2 | Submit | Error: "End date is required" |

#### TC-N07: Required — Missing status_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all fields EXCEPT status_id | Leave status empty |
| 2 | Submit | Error: "Status is required" |

#### TC-N08: Duplicate Combination — Same Session+Class+ExamType

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with session=S1, class=C1, type=T1 | First exam created |
| 2 | Try to create another exam with same S1+C1+T1 | Validation error: "This exam type already exists for the selected session and class" |
| 3 | DB check: Only one record with this combination | No duplicate inserted |

#### TC-N09: Max Length — Title > 150 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter title of 151 characters | Validation fails on title.max |
| 2 | Error returned | "The title must not be greater than 150 characters." |

#### TC-N10: Max Length — Code > 50 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code of 51 characters | Validation fails on code.max |

#### TC-N11: Invalid Date — End Date Before Start Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set start_date=2026-03-15, end_date=2026-03-01 | End before start |
| 2 | Submit | Validation error: "End date must be after or equal to start date" |

#### TC-N12: Invalid Date — Start Date After End Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set start_date=2026-03-20, end_date=2026-03-10 | Start after end |
| 2 | Submit | Error: "Start date must be before or equal to end date" |

#### TC-N13: Invalid FK — Non-Existent class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set class_id = 99999 (non-existent) | Invalid FK |
| 2 | Submit | Validation error: "Selected class is invalid" |

#### TC-N14: Invalid FK — Non-Existent exam_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set exam_type_id = 99999 | Invalid |
| 2 | Submit | Error: "Selected exam type is invalid" |

#### TC-N15: Invalid FK — Non-Existent status_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set status_id = 99999 | Invalid |
| 2 | Submit | Error: "Selected status is invalid" |

#### TC-N16: Invalid FK — Non-Existent grading_schema_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set grading_schema_id = 99999 | Invalid |
| 2 | Submit | Validation error: "The selected grading schema id is invalid." |

#### TC-N17: Invalid result_published Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set result_published = "INVALID_VALUE" | Invalid enum |
| 2 | Submit | Validation error: "The selected result published is invalid." |

#### TC-N18: Duplicate Code On Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with custom code = "DUPCODE" | First exam created |
| 2 | Try to create another exam with same code "DUPCODE" | Validation error: "The code has already been taken." |

#### TC-N19: Edit Blocked — Exam Has Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam | Exam exists |
| 2 | Create exam paper linked to this exam | Paper exists |
| 3 | Click Edit on the exam | UsageCheck returns true |
| 4 | Error displayed | "Cannot edit this exam because it has papers, allocations, or student attempts." |

#### TC-N20: Update Blocked — Exam Has Allocations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with papers and allocations | Exam in use |
| 2 | Try to update exam via form POST | UsageCheck blocks |
| 3 | Error shown | "Cannot update this exam because it has papers, allocations, or student attempts." |

#### TC-N21: Delete Blocked — Exam Has Attempts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with papers and student attempts | Exam in use |
| 2 | Try to delete exam | UsageCheck blocks |
| 3 | Error shown | "Cannot delete this exam because it has papers, allocations, or student attempts." |

#### TC-N22: Restore Blocked — Exam Has Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with papers | Exam in use |
| 2 | UsageCheck blocks restore | Error: "Cannot restore this exam because it has papers, allocations, or student attempts." |

#### TC-N23: Force Delete Blocked — Exam Has Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with papers | Exam in use |
| 2 | UsageCheck blocks forceDelete | Error: "Cannot permanently delete this exam because it has papers, allocations, or student attempts." |

#### TC-N24: View Exam With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/lms-exam/exam/99999` | 404 page: Model not found |

#### TC-N25: Edit/Update Exam With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/lms-exam/exam/99999/edit` | 404 error |

#### TC-N26: Delete Exam With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to destroy route with invalid ID | 404 error |

#### TC-N27: Toggle Status With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `/lms-exam/exam/99999/toggle-status` | findOrFail throws ModelNotFoundException, caught by catch block → JSON 500 |

#### TC-N28: Restore Non-Deleted Exam (Already Active)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam (not deleted) | Exam exists, deleted_at=NULL |
| 2 | POST to restore route | `onlyTrashed()->findOrFail()` returns null → 404 |

#### TC-N29: Force Delete Non-Trashed Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam (not deleted) | Exam active |
| 2 | POST to forceDelete | `withTrashed()->findOrFail()` finds it; forceDelete proceeds directly |

#### TC-N30: Permission 403 — No Exam Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without any `tenant.exam.*` permissions | User authenticated |
| 2 | Navigate to Exam tab | 403 Forbidden: Gate::authorize('tenant.exam.viewAny') fails |

#### TC-N31: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (guest user) | Not authenticated |
| 2 | Navigate to any exam route | Redirected to /login |

#### TC-N32: XSS Injection In Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with title: `<script>alert('XSS')</script>` | Title stored as literal string |
| 2 | Load exam list page | Script not executed; Blade `{{ }}` escapes HTML |
| 3 | View source code | `&lt;script&gt;alert('XSS')&lt;/script&gt;` |

#### TC-N33: Whitespace-Only Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter title as "   " (spaces only) | Required validation fails |
| 2 | Error returned | "Exam title is required" |

#### TC-N34: Publication DV1 Failure — Empty Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with empty question set | Set exists but has 0 questions |
| 2 | Try to publish exam | Validation error: "Set 'X' in paper 'Y' contains no questions." |

#### TC-N35: Publication DV2 Failure — Marks Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper total_marks=100, set questions sum to 50 | Marks mismatch |
| 2 | Try to publish | Error: "Set 'X' total marks (50.00) does not match Paper target marks (100.00)." |

#### TC-N36: Publication DV3-DV4 Failure — Blueprint Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blueprint requires 5 questions, set has 2 matching | Count mismatch |
| 2 | Try to publish | Error: "Set 'X' is missing 3 questions of type 'Section A'." |

#### TC-N37: Publication DV5-DV6 Failure — Difficulty Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Difficulty rule min 30% Difficult, set has 0 difficult questions | Rule not met |
| 2 | Try to publish | Error: "Set 'X' lacks questions for complexity 'Difficult'." |

#### TC-N38: Publication DV7 Failure — Scope Not Covered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Scope requires 2 questions from Topic T, set has 0 | Coverage missing |
| 2 | Try to publish | Error: "Set 'X' does not cover required questions for Topic 'T'." |

#### TC-N39: Status Toggle With Invalid Boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggle-status with is_active="invalid" | Validation error: "The is active field must be true or false." |

#### TC-N40: scheduled_result_at Before start_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set start_date=2026-03-15, scheduled_result_at=2026-03-10 | Scheduled before start |
| 2 | Submit | Validation error on scheduled_result_at.after_or_equal |
