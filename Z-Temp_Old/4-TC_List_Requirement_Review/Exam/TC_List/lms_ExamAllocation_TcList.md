# lms_exam_allocation_TcList

## Module: LmsExam → Creation & Allocation → Exam Allocation

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Creation & Allocation |
| Feature | Exam Allocation |
| URL(s) | `/lms-exam/creation-allocation` (index via tab), `/lms-exam/exam-allocation/create` (create), `/lms-exam/exam-allocation/store` (store), `/lms-exam/exam-allocation/{id}` (show), `/lms-exam/exam-allocation/{id}/edit` (edit), `/lms-exam/exam-allocation/{id}` (update), `/lms-exam/exam-allocation/{id}/destroy` (destroy), `/lms-exam/exam-allocation/trash/view` (trashed), `/lms-exam/exam-allocation/{id}/restore` (restore), `/lms-exam/exam-allocation/{id}/force-delete` (forceDelete), `/lms-exam/exam-allocation/{id}/toggle-status` (toggleStatus AJAX), `/lms-exam/exam-allocation/paper-sets` (paperSets AJAX), `/lms-exam/exam-allocation/sections` (sections AJAX), `/lms-exam/exam-allocation/exam-groups` (examGroups AJAX), `/lms-exam/exam-allocation/students` (students AJAX), `/lms-exam/exam-allocation/get-exam-papers` (getExamPapers AJAX) |
| Controller | `Modules\LmsExam\Http\Controllers\ExamAllocationController` |
| Model(s) | `Modules\LmsExam\Models\ExamAllocation` |
| Validation (Create) | `Modules\LmsExam\Http\Requests\ExamAllocationRequest` — validates exam_paper_id, paper_set_id, allocation_type (CLASS/SECTION/EXAM_GROUP/STUDENT), class_id, scheduled_start_time, scheduled_end_time (after:start), location (required_if:!conducted_in_school), room_id (required_if:conducted_in_school), class_section_jnt_id (required_if:SECTION), exam_group_id (required_if:EXAM_GROUP), student_id (required_if:STUDENT), conducted_in_school, is_active; prepareForValidation resolves section_id from class_section_jnt |
| Validation (Update) | Same `ExamAllocationRequest` — same conditional rules |
| Permissions | `tenant.exam-allocation.viewAny`, `tenant.exam-allocation.view`, `tenant.exam-allocation.create`, `tenant.exam-allocation.update`, `tenant.exam-allocation.delete`, `tenant.exam-allocation.restore`, `tenant.exam-allocation.forceDelete` |
| Soft Deletes | Yes (`ExamAllocation` uses `SoftDeletes` trait; `destroy()` sets is_active=false before soft delete) |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |
| Usage Service | `ExamAllocationUsageCheckService` — checks `lms_exam_attempts` for student attempts |
| Computed Attribute | `allocation_target` — returns human-readable target based on allocation_type |
| Allocation Types | `CLASS` (all students in class), `SECTION` (class-section), `EXAM_GROUP` (student group), `STUDENT` (individual) |

---

## 2. Pre-conditions

- Required permissions: `tenant.exam-allocation.viewAny`, `tenant.exam-allocation.view`, `tenant.exam-allocation.create`, `tenant.exam-allocation.update`, `tenant.exam-allocation.delete`, `tenant.exam-allocation.restore`, `tenant.exam-allocation.forceDelete`
- Required seed data: At least one active `ExamPaper`, one active `ExamPaperSet`, one active `SchoolClass`, one active `Section`, one active `ClassSection`, one active `ExamStudentGroup`, one active `Student`, one active `Room`
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For CLASS allocation tests: Class with at least 2 students
- For SECTION allocation tests: Class-section junction with at least 2 students
- For EXAM_GROUP allocation tests: Student group with at least 2 members
- For STUDENT allocation tests: Individual active student
- For usage check tests: Allocation with student attempt (ExamAttempt record)
- For AJAX tests: Class with sections, groups, students created
- For create form tests: Exam paper that does NOT have allocations yet (showUnallocatedOnly)

---

## 3. Default Data Load

When the page loads via Creation & Allocation tab (`active_tab=exam_allocation`):

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Allocations Grid | queryBuilder() | ExamAllocation::with(examPaper,paperSet,class,section,classSection,examGroup,student) | Filters: exam_paper_id, allocation_type, class_id, section_id, exam_id, scheduled_date, is_active, search | 10/page |
| Exam Papers | ExamAllocationController@index() | ExamPaper::with('class')->where('is_active','1')->get() | is_active=1 | None |
| Paper Sets | ExamAllocationController@index() | ExamPaperSet::where('is_active','1')->get() | is_active=1 | None |
| Classes | ExamAllocationController@index() | SchoolClass::where('is_active','1')->get() | is_active=1 | None |
| Sections | ExamAllocationController@index() | Section::where('is_active','1')->get() | is_active=1 | None |
| Exam Groups | ExamAllocationController@index() | ExamStudentGroup::where('is_active','1')->get() | is_active=1 | None |
| Students | ExamAllocationController@index() | Student::where('is_active','1')->get() | is_active=1 | None |
| Exams | ExamAllocationController@index() | Exam::where('is_active','1')->get() | is_active=1 | None |
| Exam Papers (create view) | create() | ExamPaper::with('class')->whereDoesntHave('allocations')->where('is_active','1')->get() | is_active=1, no existing allocations | None |
| Paper Sets (create view) | create() | ExamPaperSet::where('is_active','1')->get() | is_active=1 | None |
| Rooms (create view) | create() | Room::where('is_active','1')->get() | is_active=1 | None |

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Allocation types**: Test each of the 4 types (CLASS, SECTION, EXAM_GROUP, STUDENT) separately
- **Scheduled times**: Use valid H:i format with end_time after start_time
- **Conditional fields**: conducted_in_school=true → room_id required; conducted_in_school=false → location required
- **Pre-test cleanup**: Delete created allocations by ID before/after tests
- **Usage test data**: Create ExamAttempt record linked to allocation for usage check tests
- **AJAX test data**: Ensure class has sections, exam groups, and students registered
- **Search test data**: Create allocations with varied locations, paper titles, set codes, class names, student names

---

## 5. Business Conditions

### 4.1 Database Schema — `lms_exam_allocations`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | exam_paper_id | INT UNSIGNED FK | NOT NULL, FK → `lms_exam_papers.id`, ON DELETE CASCADE |
| BC-DB-03 | paper_set_id | INT UNSIGNED FK | NOT NULL, FK → `lms_exam_paper_sets.id` |
| BC-DB-04 | allocation_type | ENUM('CLASS','SECTION','EXAM_GROUP','STUDENT') | NOT NULL |
| BC-DB-05 | class_id | INT UNSIGNED FK | NOT NULL, FK → `sch_classes.id` |
| BC-DB-06 | section_id | INT UNSIGNED FK NULL | FK → `sch_sections.id` |
| BC-DB-07 | class_section_jnt_id | INT UNSIGNED FK NULL | FK → `sch_class_section_jnt.id` |
| BC-DB-08 | exam_group_id | INT UNSIGNED FK NULL | FK → `lms_exam_student_groups.id` |
| BC-DB-09 | student_id | INT UNSIGNED FK NULL | FK → `std_students.id` |
| BC-DB-10 | scheduled_date | DATE NULL | Optional override date |
| BC-DB-11 | scheduled_start_time | TIME | NOT NULL |
| BC-DB-12 | scheduled_end_time | TIME | NOT NULL |
| BC-DB-13 | conducted_in_school | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-14 | room_id | INT UNSIGNED FK NULL | FK → `sch_rooms.id` |
| BC-DB-15 | location | VARCHAR(100) NULL | Free text |
| BC-DB-16 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-17 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-18 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-19 | deleted_at | TIMESTAMP NULL | Soft delete |

### 4.2 Validation Rules — `ExamAllocationRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | exam_paper_id | required, exists:lms_exam_papers,id | "Exam paper is required" |
| BC-VAL-02 | paper_set_id | required, exists:lms_exam_paper_sets,id | "Paper set is required" |
| BC-VAL-03 | allocation_type | required, in:CLASS,SECTION,EXAM_GROUP,STUDENT | "Allocation type is required" |
| BC-VAL-04 | class_id | required, exists:sch_classes,id | "Class is required" |
| BC-VAL-05 | scheduled_start_time | required, date_format:H:i | "Start time is required" |
| BC-VAL-06 | scheduled_end_time | required, date_format:H:i, after:scheduled_start_time | "End time must be after start time" |
| BC-VAL-07 | conducted_in_school | nullable, boolean | — |
| BC-VAL-08 | location | required_if:conducted_in_school,false, string, max:100 | "Location is required when exam is not conducted in school" |
| BC-VAL-09 | room_id | required_if:conducted_in_school,true, exists:sch_rooms,id | "Room is required when exam is conducted in school" |
| BC-VAL-10 | is_active | boolean | — |
| BC-VAL-11 | class_section_jnt_id | required_if:allocation_type,SECTION, exists:sch_class_section_jnt,id + where(class_id) + where(is_active) | "Class section junction is required for section allocation" |
| BC-VAL-12 | exam_group_id | required_if:allocation_type,EXAM_GROUP, exists:lms_exam_student_groups,id | "Exam group is required for group allocation" |
| BC-VAL-13 | student_id | required_if:allocation_type,STUDENT, exists:std_students,id | "Student is required for student allocation" |

### 4.3 Validation Rules — `ExamAllocationRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | Same rules as Create | Same conditional validation applied | Same messages |
| BC-VAL-U02 | Usage (controller) | Checked before edit/update/destroy/restore/forceDelete | Dynamic usage message |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.exam-allocation.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.exam-allocation.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.exam-allocation.create | create(), store() | Without → 403 |
| BC-AUTH-04 | tenant.exam-allocation.update | edit(), update(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.exam-allocation.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.exam-allocation.restore | trashed(), restore() | Without → 403 |
| BC-AUTH-07 | tenant.exam-allocation.forceDelete | forceDelete() | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create CLASS allocation | Allocation with allocation_type='CLASS', class_id set, all other target fields null |
| BC-BIZ-02 | Create SECTION allocation | allocation_type='SECTION', class_section_jnt_id required, section_id auto-resolved from junction |
| BC-BIZ-03 | Create EXAM_GROUP allocation | allocation_type='EXAM_GROUP', exam_group_id required, class_id also required |
| BC-BIZ-04 | Create STUDENT allocation | allocation_type='STUDENT', student_id required, class_id also required |
| BC-BIZ-05 | Auto-resolve section_id from class_section_jnt | On create/update with SECTION type, controller finds ClassSection and sets section_id |
| BC-BIZ-06 | Conditional room/location based on conducted_in_school | conducted_in_school=true → room_id required; conducted_in_school=false → location required |
| BC-BIZ-07 | Time validation — end after start | scheduled_end_time must be after scheduled_start_time (date_format:H:i) |
| BC-BIZ-08 | Usage check before edit | ExamAllocationUsageCheckService checks exam attempts; if attempts exist, edit blocked |
| BC-BIZ-09 | Usage check before update | Same check; update blocked with usage message |
| BC-BIZ-10 | Usage check before delete | Same check; delete blocked with usage message |
| BC-BIZ-11 | Usage check before forceDelete | Same check; forceDelete blocked with usage message |
| BC-BIZ-12 | Soft delete sets is_active=false | destroy() sets is_active=false before calling delete() |
| BC-BIZ-13 | Restore sets is_active=true | restore() sets is_active=true after calling restore() |
| BC-BIZ-14 | Toggle status (AJAX) | toggleStatus() updates is_active via AJAX with boolean validation |
| BC-BIZ-15 | Create with explicit scheduled_date | scheduled_date optional; if provided, validated as date format |
| BC-BIZ-16 | Create form shows only unallocated papers | ExamPaper::whereDoesntHave('allocations') in create view |
| BC-BIZ-17 | AJAX getExamPapers with unallocated_only flag | Returns only papers without allocations when flag is true |
| BC-BIZ-18 | AJAX paperSets for exam paper | Returns paper sets for selected exam_paper_id, ordered by set_code |
| BC-BIZ-19 | AJAX sections for class | Returns sections (via ClassSection junction) for selected class_id |
| BC-BIZ-20 | AJAX examGroups for class/section/exam | Returns exam student groups filtered by class_id, optional section_id and exam_id |
| BC-BIZ-21 | AJAX students for class/section | Returns students with current academic session matching class and section |
| BC-BIZ-22 | DB transaction on all write operations | store(), update(), destroy(), restore(), forceDelete(), toggleStatus() use DB::transaction |
| BC-BIZ-23 | Activity log with changes tracking | update() captures old/new values for changed attributes in activity log |
| BC-BIZ-24 | Show page checks usage | show() calls usage service and passes usage details to view |
| BC-BIZ-25 | Index search across multiple fields | search filters by location, paper title/code, set code/name, class name/code, student name/code |
| BC-BIZ-26 | Index filter by exam paper | Filters by exam_paper_id |
| BC-BIZ-27 | Index filter by allocation type | Filters by allocation_type (CLASS/SECTION/EXAM_GROUP/STUDENT) |
| BC-BIZ-28 | Index filter by class | Filters by class_id |
| BC-BIZ-29 | Index filter by exam | Filters by exam_id via whereHas examPaper |
| BC-BIZ-30 | Index filter by scheduled date | Filters by exact scheduled_date |
| BC-BIZ-31 | Index filter by is_active | Filters by is_active boolean |
| BC-BIZ-32 | allocation_target computed attribute | Returns formatted string: "Class: X", "Section: X - Y", "Exam Group: X", "Student: X" |
| BC-BIZ-33 | scheduledDateTime computed attribute | Returns combined date + start - end time string |
| BC-BIZ-34 | prepareForValidation resolves class_section_jnt | When SECTION type and both class_id + section_id provided, auto-resolves junction ID |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | exam_paper_id | lms_exam_papers (id) | CASCADE |
| BC-REF-02 | paper_set_id | lms_exam_paper_sets (id) | RESTRICT |
| BC-REF-03 | class_id | sch_classes (id) | RESTRICT |
| BC-REF-04 | section_id | sch_sections (id) | RESTRICT |
| BC-REF-05 | exam_group_id | lms_exam_student_groups (id) | RESTRICT |
| BC-REF-06 | student_id | std_students (id) | RESTRICT |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Exam Allocation Index Page Loads | Page loads with filters (exam_paper, allocation_type, class, exam, date, is_active), search, grid with 10 items per page | — | — | ⬜ |
| TC-P02 | Filter By Exam Paper | Grid shows allocations for selected exam paper | — | — | ⬜ |
| TC-P03 | Filter By Allocation Type | Grid filters by CLASS/SECTION/EXAM_GROUP/STUDENT | — | — | ⬜ |
| TC-P04 | Filter By Class | Grid shows allocations for selected class | — | — | ⬜ |
| TC-P05 | Filter By Exam | Grid shows allocations for papers under selected exam | — | — | ⬜ |
| TC-P06 | Filter By Scheduled Date | Grid shows allocations on exact date | — | — | ⬜ |
| TC-P07 | Filter By Active Status | Grid shows active/inactive allocations | — | — | ⬜ |
| TC-P08 | Search By Location | Search matches location text | — | — | ⬜ |
| TC-P09 | Search By Paper Title/Code | Search matches exam paper title or paper_code | — | — | ⬜ |
| TC-P10 | Search By Set Code/Name | Search matches paper_set set_code or set_name | — | — | ⬜ |
| TC-P11 | Search By Class Name/Code | Search matches class name or code | — | — | ⬜ |
| TC-P12 | Search By Student Name/Code | Search matches student name or student_code | — | — | ⬜ |
| TC-P13 | Create CLASS Allocation (Conducted In School) | Allocation with type=CLASS, room_id set, scheduled times valid | — | — | ⬜ |
| TC-P14 | Create SECTION Allocation | Allocation with type=SECTION, class_section_jnt_id set, section_id auto-resolved | — | — | ⬜ |
| TC-P15 | Create EXAM_GROUP Allocation | Allocation with type=EXAM_GROUP, exam_group_id set | — | — | ⬜ |
| TC-P16 | Create STUDENT Allocation | Allocation with type=STUDENT, student_id set | — | — | ⬜ |
| TC-P17 | Create Allocation Not Conducted In School (With Location) | conducted_in_school=false, location text provided, room_id null | — | — | ⬜ |
| TC-P18 | Create Allocation With Scheduled Date | scheduled_date set to future date; stored correctly | — | — | ⬜ |
| TC-P19 | Create Allocation Without Scheduled Date (Defaults To Paper) | scheduled_date null; paper's default date used | — | — | ⬜ |
| TC-P20 | Show Allocation Details With Usage Info | Show page displays all allocation fields plus usage details if attempts exist | — | — | ⬜ |
| TC-P21 | Load Edit Form With Pre-Filled Data | Edit form shows allocation data with conditional fields appropriate to type | — | — | ⬜ |
| TC-P22 | Update Allocation — Change Paper Set | paper_set_id updated; allocation preserved | — | — | ⬜ |
| TC-P23 | Update Allocation — Change Scheduled Times | start_time and end_time updated; end still after start | — | — | ⬜ |
| TC-P24 | Update Allocation — Toggle conducted_in_school | Switching from school=true to school=false: room cleared, location required | — | — | ⬜ |
| TC-P25 | Update Allocation — Change Room | room_id changed; updates saved | — | — | ⬜ |
| TC-P26 | Update Allocation — Change Location | location text changed | — | — | ⬜ |
| TC-P27 | Update Allocation — SECTION Type Changes | class_section_jnt_id changed; section_id auto-resolved | — | — | ⬜ |
| TC-P28 | Soft Delete Allocation | is_active=false before soft delete; moved to trash | — | — | ⬜ |
| TC-P29 | View Trash Page | Shows soft-deleted allocations | — | — | ⬜ |
| TC-P30 | Restore Trashed Allocation | is_active=true after restore; back to active | — | — | ⬜ |
| TC-P31 | ForceDelete Permanently | Allocation permanently removed from database | — | — | ⬜ |
| TC-P32 | Toggle Status (AJAX) Active/Inactive | is_active toggled; returns JSON with success and new status | — | — | ⬜ |
| TC-P32a | Toggle Status Bypasses Usage Check | toggleStatus() does NOT call ExamAllocationUsageCheckService; can toggle even when student attempts exist | — | — | ⬜ |
| TC-P33 | AJAX Get Paper Sets For Exam Paper | Returns paper sets for selected exam paper | — | — | ⬜ |
| TC-P34 | AJAX Get Sections For Class | Returns sections linked to selected class via ClassSection | — | — | ⬜ |
| TC-P35 | AJAX Get Exam Groups For Class+Section | Returns exam student groups filtered by class_id and optional section_id/exam_id | — | — | ⬜ |
| TC-P36 | AJAX Get Students For Class+Section | Returns students with academic session matching class and section | — | — | ⬜ |
| TC-P37 | AJAX Get Exam Papers (Unallocated Only) | Returns only exam papers without allocations when flag set | — | — | ⬜ |
| TC-P38 | Create Form Shows Only Papers Without Allocations | create() uses whereDoesntHave('allocations') | — | — | ⬜ |
| TC-P38a | Edit Form Shows ALL Papers With Allocation Counts | edit() uses withCount('allocations') (all papers, including allocated ones); allocation count visible | — | — | ⬜ |
| TC-P39 | Full Lifecycle: Create → Show → Edit → Trash → Restore → ForceDelete | All transitions succeed | — | — | ⬜ |
| TC-P40 | Empty State — No Allocations Found | Grid shows "No allocations found" | — | — | ⬜ |
| TC-P41 | Create Allocation With All Optional Fields Filled | scheduled_date, conducted_in_school, room_id all set; saves correctly | — | — | ⬜ |
| TC-P42 | allocation_target Shows Correct Format For CLASS Type | "Class: X" where X is class name | — | — | ⬜ |
| TC-P43 | allocation_target Shows Correct Format For SECTION Type | "Section: X - Y" where X is class name, Y is section name | — | — | ⬜ |
| TC-P44 | allocation_target Shows Correct Format For EXAM_GROUP Type | "Exam Group: X" where X is group name | — | — | ⬜ |
| TC-P45 | allocation_target Shows Correct Format For STUDENT Type | "Student: X" where X is student name | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `exam_paper_id` | Validation error: "Exam paper is required" | — | — | ⬜ |
| TC-N02 | Required — Missing `paper_set_id` | Validation error: "Paper set is required" | — | — | ⬜ |
| TC-N03 | Required — Missing `allocation_type` | Validation error: "Allocation type is required" | — | — | ⬜ |
| TC-N04 | Required — Missing `class_id` | Validation error: "Class is required" | — | — | ⬜ |
| TC-N05 | Required — Missing `scheduled_start_time` | Validation error: "Start time is required" | — | — | ⬜ |
| TC-N06 | Required — Missing `scheduled_end_time` | Validation error: "End time is required" | — | — | ⬜ |
| TC-N07 | Invalid — `allocation_type` Not In Allowed Values | Validation error: "The selected allocation type is invalid." | — | — | ⬜ |
| TC-N08 | Invalid — `scheduled_end_time` Before Start Time | Validation error: "End time must be after start time" | — | — | ⬜ |
| TC-N09 | Invalid — `scheduled_start_time` Wrong Format | Validation error: "The scheduled start time does not match the format H:i." | — | — | ⬜ |
| TC-N10 | Required — `room_id` Missing When conducted_in_school=true | Validation error: "Room is required when exam is conducted in school" | — | — | ⬜ |
| TC-N11 | Required — `location` Missing When conducted_in_school=false | Validation error: "Location is required when exam is not conducted in school" | — | — | ⬜ |
| TC-N12 | Required — `class_section_jnt_id` Missing For SECTION Type | Validation error: "Class section junction is required for section allocation" | — | — | ⬜ |
| TC-N13 | Required — `exam_group_id` Missing For EXAM_GROUP Type | Validation error: "Exam group is required for group allocation" | — | — | ⬜ |
| TC-N14 | Required — `student_id` Missing For STUDENT Type | Validation error: "Student is required for student allocation" | — | — | ⬜ |
| TC-N15 | Invalid — Non-Existent `exam_paper_id` | Validation error: "The selected exam paper id is invalid." | — | — | ⬜ |
| TC-N16 | Invalid — Non-Existent `paper_set_id` | Validation error: "The selected paper set id is invalid." | — | — | ⬜ |
| TC-N17 | Invalid — Non-Existent `class_id` | Validation error: "The selected class id is invalid." | — | — | ⬜ |
| TC-N18 | Invalid — Non-Existent `room_id` | Validation error: "The selected room id is invalid." | — | — | ⬜ |
| TC-N19 | Invalid — Non-Existent `class_section_jnt_id` | Validation error: "The selected class section junction id is invalid." | — | — | ⬜ |
| TC-N20 | Invalid — `class_section_jnt_id` Does Not Match `class_id` | Validation fails (exists rule with where clause) | — | — | ⬜ |
| TC-N21 | Invalid — Location > 100 Characters | Validation error: "The location must not be greater than 100 characters." | — | — | ⬜ |
| TC-N22 | Permission 403 — No Allocation Permissions | 403 Forbidden on all endpoints without `tenant.exam-allocation.*` | — | — | ⬜ |
| TC-N23 | Guest Access Redirect | Redirected to /login | — | — | ⬜ |
| TC-N24 | Show With Invalid ID (404) | 404 via findOrFail | — | — | ⬜ |
| TC-N25 | Edit/Update With Invalid ID (404) | 404 via findOrFail | — | — | ⬜ |
| TC-N26 | Delete With Invalid ID (404) | 404 via findOrFail | — | — | ⬜ |
| TC-N27 | Edit Blocked By Usage Check | "This allocation has X student attempt(s). Therefore cannot be edited." | — | — | ⬜ |
| TC-N28 | Update Blocked By Usage Check | "This allocation has X student attempt(s). Therefore cannot be updated." | — | — | ⬜ |
| TC-N29 | Delete Blocked By Usage Check | "This allocation has X student attempt(s). Therefore cannot be deleted." | — | — | ⬜ |
| TC-N30 | ForceDelete Blocked By Usage Check | "This allocation has X student attempt(s). Therefore cannot be permanently deleted." | — | — | ⬜ |
| TC-N31 | Restore Trashed Allocation Without Usage Check | restore() does NOT check usage; proceeds regardless (unlike other restore operations) | — | — | ⬜ |
| TC-N32 | Toggle Status On Non-Existent ID | 404 via findOrFail | — | — | ⬜ |
| TC-N33 | AJAX Get Paper Sets With Invalid ID | Empty array returned | — | — | ⬜ |
| TC-N34 | XSS Injection In Location Field | Stored as literal; escaped on output | — | — | ⬜ |
| TC-N35 | SECTION type With Non-Active class_section_jnt | exists rule with where('is_active',true); validation fails if junction inactive | — | — | ⬜ |
| TC-N36 | AJAX students() — Student Without User Record | Student exists but has no `user` relation; AJAX returns student name as `full_name` fallback, no 500 error | — | — | ⬜ |
| TC-N37 | AJAX students() — With class_id Only (No section_id) | Partial filter with only class_id returns students from that class across all sections | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create Allocation → Activity Logged | activityLog('Stored') with performed_by | — | — | ⬜ |
| TC-D02 | B | Update Allocation → Activity Logged | activityLog('Updated') with old/new value changes | — | — | ⬜ |
| TC-D03 | C | Delete Allocation → Activity Logged | activityLog('Trashed') recorded | — | — | ⬜ |
| TC-D04 | D | Restore Allocation → Activity Logged | activityLog('Restored') recorded | — | — | ⬜ |
| TC-D05 | E | ForceDelete Allocation → Activity Logged | activityLog('Deleted') with paper title | — | — | ⬜ |
| TC-D06 | F | Toggle Status → Activity Logged | activityLog('Toggled') recorded | — | — | ⬜ |
| TC-D07 | G | SECTION Type Auto-Resolves section_id | Controller finds ClassSection junction and sets section_id before save | — | — | ⬜ |
| TC-D08 | H | prepareForValidation Resolves Junction | When SECTION type with class_id+section_id provided, junction ID auto-resolved | — | — | ⬜ |
| TC-D09 | I | Soft Delete Sets is_active=false | Before delete(), is_active set to false and saved | — | — | ⬜ |
| TC-D10 | J | Restore Sets is_active=true | After restore(), is_active set to true | — | — | ⬜ |
| TC-D11 | K | Exam Paper Deletion Cascades To Allocations | Deleting exam paper cascades to all its allocations (ON DELETE CASCADE) | — | — | ⬜ |
| TC-D12 | L | Paper Set Deletion — Allocations Not Affected (No CASCADE) | DDL has no CASCADE for paper_set_id; FK constraint blocks deletion | — | — | ⬜ |
| TC-D13 | M | DB Transaction Rollback On Failure | On exception, all changes rolled back | — | — | ⬜ |
| TC-D14 | N | Update Tracks Changes | update() captures old/new values in $changedAttributes; logs via activityLog | — | — | ⬜ |
| TC-D15 | O | Index Query Builder Combines All Filters | exam_paper_id, allocation_type, class_id, section_id, exam_id, scheduled_date, search, is_active all work together | — | — | ⬜ |
| TC-D16 | P | DB \| P1 \| lms_exam_allocations table — exam_paper_id FK CASCADE | Deleting exam paper cascades to allocations | — | — | ⬜ |
| TC-D17 | Q | Integration \| P1 \| Controller — Gate::authorize('tenant.exam-allocation.*') | Gate called before each operation; without permissions → 403 | — | — | ⬜ |
| TC-D18 | R | Integration \| P1 \| Controller — activityLog — Activity Logged After CRUD | 'Stored' after create; 'Updated' with changes after update; 'Trashed' after delete; 'Restored' after restore; 'Deleted' after forceDelete; 'Toggled' after toggleStatus | — | — | ⬜ |
| TC-D19 | S | Unit \| P1 \| ExamAllocation model — belongsTo Relationships | examPaper, paperSet, class, section, classSection, examGroup, student, room all work | — | — | ⬜ |
| TC-D20 | T | Unit \| P1 \| ExamAllocation model — hasMany attempts | attempts() returns related ExamAttempt records; empty collection when none | — | — | ⬜ |
| TC-D21 | U | Unit \| P1 \| ExamAllocation model — SoftDeletes Trait | delete() sets deleted_at; restore() nullifies; withTrashed() includes | — | — | ⬜ |
| TC-D22 | V | Unit \| P1 \| ExamAllocation model — \$casts | is_active boolean; scheduled_date date; start/end_time datetime | — | — | ⬜ |
| TC-D23 | W | Integration \| P1 \| ExamAllocationRequest — Conditional Validation | Required rules for class_section_jnt/exam_group/student based on allocation_type | — | — | ⬜ |
| TC-D24 | X | Integration \| P1 \| ExamAllocationRequest — Conditional Location/Room | required_if rules for location (when not in school) and room_id (when in school) | — | — | ⬜ |
| TC-D25 | Y | Integration \| P1 \| ExamAllocationUsageCheckService — isUsed | Returns true when ExamAttempt exists for allocation; false when none | — | — | ⬜ |
| TC-D26 | Z | Integration \| P1 \| Controller — getAllocationTargetAttribute | Returns formatted string based on allocation_type with relation data | — | — | ⬜ |
| TC-D27 | AA | Integration \| P1 \| Controller — getScheduledDateTimeAttribute | Returns combined date + start-end time string | — | — | ⬜ |
| TC-D28 | AB | Integration \| P1 \| Controller — AJAX getExamPapers with unallocated_only | Returns papers where doesNotHave('allocations') when flag true | — | — | ⬜ |
| TC-D29 | AC | Integration \| P1 \| Controller — SECTION type resolves section_id | store() and update() both resolve section_id from class_section_jnt_id | — | — | ⬜ |
| TC-D30 | AD | Integration \| P1 \| Controller — Create shows only unallocated papers | create() uses whereDoesntHave('allocations') | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Controller — DB Transactions in All Write Operations | store(), update(), destroy(), restore(), forceDelete(), toggleStatus() all use DB::beginTransaction/commit/rollback | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Request — Complex Conditional Validation via Switch | ExamAllocationRequest::rules() uses switch($this->allocation_type) for type-specific required fields | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Request — prepareForValidation Auto-Resolves Junction | prepares class_section_jnt_id from class_id+section_id when allocation_type=SECTION | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — Usage Check Before Destructive Operations | edit(), update(), destroy(), forceDelete() call ExamAllocationUsageCheckService::isUsed() | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — Activity Logging With Change Tracking | update() captures $originalData and $changes; logs changedAttributes with old/new values | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — Conditional SECTION section_id Resolution | Both store() and update() check allocation_type === 'SECTION' and resolve section_id from ClassSection::find() | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Controller — Model Computed Attributes | allocation_target returns formatted string via match(); scheduledDateTime returns combined date+time | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | Controller — AJAX Endpoints Return Consistent JSON | All AJAX endpoints (paperSets, sections, examGroups, students, getExamPapers, toggleStatus) return response()->json() with success flag | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | Controller — Query Builder With Combined Filters | queryBuilder() handles 8+ filters with when() conditions; search uses orWhereHas across 5 relationships | — | — | ◌ |
| TC-CR10 | CR | Code Review | P1 | Controller — Soft Delete Pattern (is_active=false before delete) | destroy() sets is_active=false and saves before calling delete(); restore() sets is_active=true after calling restore() | — | — | ◌ |
| TC-CR11 | CR | Code Review | P1 | Controller — forceDelete Catch Block Logs Error | forceDelete() catch block uses `Log::error()` for debugging; verify `use Illuminate\Support\Facades\Log;` imported at top of file | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Controller — DB Transactions in All Write Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamAllocationController.php | Controller in Modules/LmsExam/Http/Controllers/ |
| 2 | Inspect store() | DB::beginTransaction() before create; DB::commit() after; DB::rollBack() on exception |
| 3 | Inspect update() | DB::beginTransaction() before update; DB::commit() after; DB::rollBack() on exception |
| 4 | Inspect destroy() | DB::beginTransaction() before deactivate+delete; DB::commit() after; DB::rollBack() on exception |
| 5 | Inspect restore() | DB::beginTransaction() before restore+reactivate; DB::commit() after; DB::rollBack() on exception |
| 6 | Inspect forceDelete() | DB::beginTransaction() before forceDelete; DB::commit() after; DB::rollBack() on exception |
| 7 | Inspect toggleStatus() | DB::beginTransaction() before save; DB::commit() after; DB::rollBack() on exception |

#### TC-CR02: Request — Complex Conditional Validation via Switch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamAllocationRequest.php | Request in Modules/LmsExam/Http/Requests/ |
| 2 | Inspect rules() method | Base rules for exam_paper_id, paper_set_id, allocation_type, class_id, times, location/room conditional |
| 3 | Inspect switch statement | CASE 'SECTION' adds class_section_jnt_id required with exists+where(class_id)+where(is_active); CASE 'EXAM_GROUP' adds exam_group_id required; CASE 'STUDENT' adds student_id required; CASE 'CLASS'/default sets all optional to nullable |
| 4 | Verify location required_if | location required when conducted_in_school is false |
| 5 | Verify room_id required_if | room_id required when conducted_in_school is true |

#### TC-P13: Create CLASS Allocation (Conducted In School)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Exam Allocation tab | Page loads |
| 2 | Click "Add Allocation" button | Create form opens |
| 3 | Select exam paper from dropdown | Paper selected |
| 4 | Select paper set from AJAX-populated dropdown | Set selected |
| 5 | Select allocation type = "CLASS" | Type selected |
| 6 | Select class from dropdown | Class selected |
| 7 | Enter scheduled_start_time = "09:00" | Start time set |
| 8 | Enter scheduled_end_time = "11:00" | End time set |
| 9 | Toggle conducted_in_school = true | Room field appears |
| 10 | Select room from dropdown | Room selected |
| 11 | Click "Create Allocation" | POST to store |
| 12 | Check response | Success message |
| 13 | DB check: `SELECT * FROM lms_exam_allocations WHERE class_id={id}` | Record exists; allocation_type='CLASS'; room_id set; scheduled_start_time='09:00'; scheduled_end_time='11:00' |

#### TC-P14: Create SECTION Allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation form | Form visible |
| 2 | Select exam paper, set, allocation_type='SECTION' | Type selected |
| 3 | Select class | Class selected |
| 4 | Select section from AJAX-populated dropdown | Section selected |
| 5 | Verify class_section_jnt_id auto-selected | Junction resolved |
| 6 | Enter start=09:00, end=11:00 | Times set |
| 7 | conducted_in_school = false, enter location = "Hall A" | Location set |
| 8 | Click "Create Allocation" | POST to store |
| 9 | Check response | Success |
| 10 | DB check: allocation_type='SECTION', class_section_jnt_id set, section_id auto-resolved | Correct values |

#### TC-P16: Create STUDENT Allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation form | Form visible |
| 2 | Select exam paper, set, allocation_type='STUDENT' | Type selected |
| 3 | Select class | Class selected |
| 4 | Select student from AJAX-populated dropdown | Student selected |
| 5 | Enter start=09:00, end=11:00 | Times set |
| 6 | conducted_in_school = true, select room | Room set |
| 7 | Click "Create Allocation" | POST to store |
| 8 | Check response | Success |
| 9 | DB check: allocation_type='STUDENT', student_id set | Correct values |

#### TC-N08: Invalid — scheduled_end_time Before Start Time

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation form | Form visible |
| 2 | Fill all required fields | Fields complete |
| 3 | Enter start_time = "10:00", end_time = "09:00" | End before start |
| 4 | Click "Create Allocation" | Validation fails |
| 5 | Error response | "End time must be after start time" |

#### TC-N10: Required — room_id Missing When conducted_in_school=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation form | Form visible |
| 2 | Fill all fields, set conducted_in_school=true | Room field required |
| 3 | Leave room_id empty | Empty |
| 4 | Click "Create Allocation" | Validation fails |
| 5 | Error response | "Room is required when exam is conducted in school" |

#### TC-N12: Required — class_section_jnt_id Missing For SECTION Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation form | Form visible |
| 2 | Select allocation_type='SECTION' | Type selected |
| 3 | Select class, but do NOT select section | Section empty |
| 4 | Fill all other fields | Complete |
| 5 | Click "Create Allocation" | Validation fails |
| 6 | Error response | "Class section junction is required for section allocation" |

#### TC-P33: AJAX Get Paper Sets For Exam Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam paper with 2 paper sets (Set A, Set B) | Paper + sets exist |
| 2 | Call AJAX POST `/lms-exam/exam-allocation/paper-sets` with exam_paper_id | POST |
| 3 | Check response | success: true, paper_sets array with 2 items |
| 4 | Verify each set has id and name | "Set A (SA001)", "Set B (SA002)" |

#### TC-P36: AJAX Get Students For Class+Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure class C1 has 2 students with active academic session | Students exist |
| 2 | Call AJAX POST `/lms-exam/exam-allocation/students` with class_id=C1 | POST |
| 3 | Check response | success: true, students array with 2 items |
| 4 | Verify each student has id, name, code | Correct student data |

#### TC-N27: Edit Blocked By Usage Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation for student | Allocation exists |
| 2 | Create ExamAttempt linked to this allocation | Attempt exists |
| 3 | Navigate to edit for this allocation | Controller calls isUsed() |
| 4 | Error response | "This allocation has 1 student attempt(s). Therefore cannot be edited." |
| 5 | Verify redirect to index | Edit form not shown |

#### TC-P28: Soft Delete Allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation | Allocation exists, is_active=1 |
| 2 | Click "Delete" on allocation | POST to destroy |
| 3 | Check response | Success message |
| 4 | DB check: is_active=0, deleted_at set | Correct soft delete behavior |
| 5 | Verify allocation no longer in active list | Only in trash |

#### TC-P30: Restore Trashed Allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view | Soft-deleted allocation visible |
| 2 | Click "Restore" | POST to restore |
| 3 | Check response | Success message |
| 4 | DB check: deleted_at=null, is_active=1 | Restored and reactivated |
| 5 | Verify allocation appears in active list | Back in index |

#### TC-D07: SECTION Type Auto-Resolves section_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation with allocation_type='SECTION', class_section_jnt_id=CS1 | POST to store |
| 2 | In store(), controller finds ClassSection CS1 | ClassSection::find(CS1) |
| 3 | Controller sets allocationData['section_id'] = CS1.section_id | Auto-resolved |
| 4 | DB check: allocation.section_id = correct section ID | section_id saved |
| 5 | Repeat for update() method | Same auto-resolution |

#### TC-P42-45: allocation_target Computed Attribute

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create CLASS allocation with class "Grade 10" | Type=CLASS |
| 2 | Access $allocation->allocation_target | "Class: Grade 10" |
| 3 | Create SECTION allocation with class "Grade 10" and section "A" | Type=SECTION |
| 4 | Access allocation_target | "Section: Grade 10 - A" |
| 5 | Create EXAM_GROUP allocation with group "Advanced Math" | Type=EXAM_GROUP |
| 6 | Access allocation_target | "Exam Group: Advanced Math" |
| 7 | Create STUDENT allocation with student "John Doe" | Type=STUDENT |
| 8 | Access allocation_target | "Student: John Doe" |

#### TC-P01: Exam Allocation Index Page Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Navigate to Creation & Allocation and select Exam Allocation tab | Page loads with active_tab=exam_allocation |
| 3 | Verify exam paper filter dropdown | Present |
| 4 | Verify allocation type filter | Present |
| 5 | Verify class filter dropdown | Present |
| 6 | Verify exam filter dropdown | Present |
| 7 | Verify scheduled date filter | Date picker present |
| 8 | Verify is_active filter | Present |
| 9 | Verify search input | Present |
| 10 | Verify grid columns | All present |
| 11 | Verify pagination (10/page) | Present |

#### TC-P02: Filter By Exam Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocations for Paper A (3) and Paper B (2) | 5 total allocations |
| 2 | Select Paper A from filter | Page reloads with exam_paper_id |
| 3 | Verify 3 allocations shown | Correct |
| 4 | Select Paper B | 2 shown |
| 5 | Clear filter | All 5 shown |

#### TC-P03: Filter By Allocation Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create CLASS (2), SECTION (2), EXAM_GROUP (1), STUDENT (1) | All types exist |
| 2 | Filter by CLASS | Only 2 CLASS shown |
| 3 | Filter by SECTION | Only 2 SECTION shown |
| 4 | Filter by EXAM_GROUP | Only 1 group shown |
| 5 | Filter by STUDENT | Only 1 student shown |

#### TC-P13: Create CLASS Allocation (Conducted In School)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create allocation form | Form loads |
| 2 | Select exam paper (from unallocated-only list) | Paper selected |
| 3 | Select paper set from AJAX dropdown | Set selected |
| 4 | Select allocation_type = CLASS | Fields update |
| 5 | Select class (e.g., Grade 10) | Class selected |
| 6 | Enter scheduled_start_time = 09:00 | Start time set |
| 7 | Enter scheduled_end_time = 11:00 | End time set |
| 8 | conducted_in_school = true | Room field required |
| 9 | Select room from dropdown | Room selected |
| 10 | Click Create Allocation | POST to store |
| 11 | Check response | Success message |
| 12 | DB check: allocation_type=CLASS, room_id set | Correct values |
| 13 | Verify activityLog(Stored) created | Logged |

#### TC-P14: Create SECTION Allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Select paper, set, allocation_type=SECTION | Type selected |
| 3 | Select class | Class selected |
| 4 | Select section from AJAX dropdown | Section selected |
| 5 | Verify class_section_jnt_id auto-resolved | prepareForValidation works |
| 6 | Enter start and end times | Times set |
| 7 | conducted_in_school=false | Location field required |
| 8 | Enter location = Main Hall | Location filled |
| 9 | Click Create Allocation | POST |
| 10 | DB check: class_section_jnt_id set, section_id auto-resolved | Correct |

#### TC-P16: Create STUDENT Allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Select paper, set, allocation_type=STUDENT | Type selected |
| 3 | Select class | Class selected |
| 4 | Select student from AJAX dropdown | Student selected |
| 5 | Enter times | Times set |
| 6 | conducted_in_school=false, enter location=Home | Location set |
| 7 | Click Create Allocation | POST |
| 8 | DB check: student_id set | Correct |

#### TC-P20: Show Allocation Details With Usage Info

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation with an attempt | Allocation + attempt exist |
| 2 | Click View on allocation | Show page loads |
| 3 | Verify allocation fields displayed | All fields visible |
| 4 | Verify isUsed = true displayed | Usage info shown |
| 5 | Verify usageDetails shows Attempts count | Details present |

#### TC-P22: Update Allocation — Change Paper Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation with Paper Set A | Record exists |
| 2 | Click Edit | Edit form loads with pre-filled data |
| 3 | Change paper set to Paper Set B | Set changed |
| 4 | Submit update | POST |
| 5 | DB check: paper_set_id = B | Updated |

#### TC-P24: Update Allocation — Toggle conducted_in_school

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit allocation originally with conducted_in_school=true, room_id=R1 | Original data |
| 2 | Toggle conducted_in_school to false | Room field hidden, location field appears |
| 3 | Enter location = Exam Hall | Location filled |
| 4 | Submit update | POST |
| 5 | DB check: conducted_in_school=0, room_id=null, location=Exam Hall | Switched correctly |

#### TC-P28: Soft Delete Allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation with is_active=1 | Active record |
| 2 | Click Delete | POST to destroy |
| 3 | Check response | Success |
| 4 | DB check: is_active=0, deleted_at set | Deactivated + soft-deleted |
| 5 | Verify not shown in active list | Only in trash |

#### TC-P30: Restore Trashed Allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view | Soft-deleted allocation visible |
| 2 | Click Restore | POST to restore |
| 3 | Check response | Success |
| 4 | DB check: deleted_at=null, is_active=1 | Restored and reactivated |

#### TC-P31: ForceDelete Permanently

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore allocation (from previous test) | Active again |
| 2 | Delete it again | In trash |
| 3 | Navigate to trash, click Permanently Delete | POST to forceDelete |
| 4 | Check response | Success |
| 5 | DB check: record permanently removed | Gone |

#### TC-P32: Toggle Status (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation with is_active=1 | Active |
| 2 | Call toggleStatus AJAX with is_active=0 | POST |
| 3 | Check JSON response | success: true, is_active: false |
| 4 | DB check: is_active=0 | Toggled |
| 5 | Toggle again to 1 | Works both ways |

#### TC-P33: AJAX Get Paper Sets

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Exam paper has Set A and Set B | 2 sets exist |
| 2 | Call paperSets with exam_paper_id | AJAX |
| 3 | Verify 2 paper_sets returned | Both with id and name |

#### TC-P34: AJAX Get Sections For Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Class C1 has sections S1, S2 via ClassSection junction | 2 sections |
| 2 | Call sections with class_id=C1 | AJAX |
| 3 | Verify 2 sections returned | Both with id and name |

#### TC-P35: AJAX Get Exam Groups For Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Class C1 has ExamGroup G1 (active) and G2 (active) | 2 groups |
| 2 | Call examGroups with class_id=C1 | AJAX |
| 3 | Verify 2 groups returned | Both with id and name |
| 4 | Filter by section_id as well | Filtered correctly |

#### TC-P36: AJAX Get Students For Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Class C1 has 2 students with active academic session | 2 students |
| 2 | Call students with class_id=C1 | AJAX |
| 3 | Verify 2 students returned | Each has id, name, code |

#### TC-P37: AJAX Get Exam Papers (Unallocated Only)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper A has allocations, Paper B has none | B is unallocated |
| 2 | Call getExamPapers with unallocated_only=true | AJAX |
| 3 | Paper A excluded, Paper B included | Correct filter |

#### TC-P38: Create Form Shows Only Unallocated Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper A has allocations, Paper B has none | Data ready |
| 2 | Navigate to create allocation form | Form loads |
| 3 | Check exam paper dropdown | Only Paper B shown |
| 4 | Verify controller: whereDoesntHave(allocations) | Code confirmed |

#### TC-P42: allocation_target For CLASS Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create CLASS allocation with class Grade 10 | Type=CLASS |
| 2 | Access $allocation->allocation_target | Class: Grade 10 |

#### TC-P43: allocation_target For SECTION Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create SECTION allocation with class Grade 10, section A | Type=SECTION |
| 2 | Access allocation_target | Section: Grade 10 - A |

#### TC-P44: allocation_target For EXAM_GROUP Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create EXAM_GROUP allocation with group Advanced Math | Type=EXAM_GROUP |
| 2 | Access allocation_target | Exam Group: Advanced Math |

#### TC-P45: allocation_target For STUDENT Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create STUDENT allocation with student John Doe | Type=STUDENT |
| 2 | Access allocation_target | Student: John Doe |

#### TC-N01: Required — Missing exam_paper_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to store without exam_paper_id | Missing field |
| 2 | Validation error | Exam paper is required |

#### TC-N02: Required — Missing paper_set_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST without paper_set_id | Missing |
| 2 | Validation error | Paper set is required |

#### TC-N04: Required — Missing class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST without class_id | Missing |
| 2 | Validation error | Class is required |

#### TC-N08: Invalid — end_time Before Start Time

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation with start=10:00, end=09:00 | End before start |
| 2 | Validation error | End time must be after start time |

#### TC-N10: Required — room_id Missing When conducted_in_school=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | conducted_in_school=true, leave room_id empty | Missing |
| 2 | Validation error | Room is required when exam is conducted in school |

#### TC-N12: Required — class_section_jnt_id Missing For SECTION

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | allocation_type=SECTION, class selected, no section | Missing |
| 2 | Validation error | Class section junction is required for section allocation |

#### TC-N13: Required — exam_group_id Missing For EXAM_GROUP

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | allocation_type=EXAM_GROUP, leave exam_group_id empty | Missing |
| 2 | Validation error | Exam group is required for group allocation |

#### TC-N14: Required — student_id Missing For STUDENT

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | allocation_type=STUDENT, leave student_id empty | Missing |
| 2 | Validation error | Student is required for student allocation |

#### TC-N27: Edit Blocked By Usage Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation | Record exists |
| 2 | Create ExamAttempt linked to allocation | Attempt exists |
| 3 | Navigate to edit | Controller calls isUsed() |
| 4 | Redirect with error | This allocation has 1 student attempt(s). Therefore cannot be edited. |

#### TC-N29: Delete Blocked By Usage Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Same as N27 setup | Allocation with attempt |
| 2 | Click Delete | Controller checks usage |
| 3 | Error redirect | This allocation has 1 student attempt(s). Therefore cannot be deleted. |

#### TC-D07: SECTION Type Auto-Resolves section_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation with type=SECTION, class_section_jnt_id=CS1 | POST |
| 2 | Controller finds ClassSection CS1 | ClassSection::find(CS1) |
| 3 | Sets section_id = CS1.section_id | Auto-resolved |
| 4 | DB check: section_id matches junction | Correct |

#### TC-D09: Soft Delete Sets is_active=false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Destroy allocation | POST to destroy |
| 2 | Inspect controller: is_active=false before delete() | Code confirmed |
| 3 | DB check: is_active=0 before delete | Deactivated then deleted |

#### TC-D10: Restore Sets is_active=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore allocation | POST to restore |
| 2 | Inspect controller: is_active=true after restore() | Code confirmed |
| 3 | DB check: is_active=1, deleted_at=null | Reactivated |

#### TC-D11: Exam Paper Deletion Cascades To Allocations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with allocation | Paper + allocation |
| 2 | Delete exam paper | Paper deleted |
| 3 | DB check: allocation also gone | CASCADE works |
| 4 | Verify DDL: ON DELETE CASCADE on fk_alloc_paper | Confirmed |

#### TC-D13: DB Transaction Rollback On Failure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST store() with valid data, mock exception after create | Exception |
| 2 | Verify rollBack called | Transaction rolled back |
| 3 | DB check: no allocation created | 0 records |

#### TC-D14: Update Tracks Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update allocation location from Hall A to Hall B | Change made |
| 2 | Verify activityLog(Updated) with changedAttributes | Old: Hall A, New: Hall B logged |
| 3 | Inspect controller: $originalData, $changes, $changedAttributes | Code confirms tracking |

#### TC-D17: Gate Authorization Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect each controller method | Gate::authorize() present |
| 2 | Verify viewAny on index() | Present |
| 3 | Verify create on create() and store() | Present |
| 4 | Verify update on edit() and update() | Present |
| 5 | Verify delete on destroy() | Present |
| 6 | Test without permission | 403 Forbidden |

#### TC-D19: ExamAllocation model — belongsTo Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check examPaper() | BelongsTo ExamPaper |
| 2 | Check paperSet() | BelongsTo ExamPaperSet |
| 3 | Check class() | BelongsTo SchoolClass |
| 4 | Check section() | BelongsTo Section |
| 5 | Check classSection() | BelongsTo ClassSection |
| 6 | Check examGroup() | BelongsTo ExamStudentGroup |
| 7 | Check student() | BelongsTo Student |
| 8 | Check room() | BelongsTo Room |
| 9 | Test all with eager loading | Works |

#### TC-D20: ExamAllocation model — hasMany attempts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation with no attempts | No attempts |
| 2 | Access $allocation->attempts | Empty collection |
| 3 | Create ExamAttempt linking to allocation | Attempt exists |
| 4 | Access $allocation->attempts | Collection with 1 item |

#### TC-D23: ExamAllocationRequest — Conditional Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamAllocationRequest.php | File found |
| 2 | Inspect rules() switch statement | CASE SECTION, EXAM_GROUP, STUDENT, CLASS handled |
| 3 | Verify location required_if logic | conducted_in_school=false |
| 4 | Verify room_id required_if logic | conducted_in_school=true |

#### TC-D25: ExamAllocationUsageCheckService — isUsed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation without attempts | No usage |
| 2 | Call isUsed() | Returns false |
| 3 | Create ExamAttempt for allocation | Usage created |
| 4 | Call isUsed() | Returns true |
| 5 | getUsageMessage includes attempt count | Correct message |

#### TC-D26: getAllocationTargetAttribute

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check model for computed attribute | getAllocationTargetAttribute defined |
| 2 | Verify match() for all 4 types | CLASS, SECTION, EXAM_GROUP, STUDENT covered |
| 3 | Verify fallback for unknown type | Returns Unknown |

#### TC-D28: AJAX getExamPapers with unallocated_only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper A has allocation, Paper B has none | Data ready |
| 2 | Call getExamPapers with unallocated_only=true | AJAX |
| 3 | Verify only Paper B returned | Correct filter |
| 4 | Call without flag | Both returned |

#### TC-P50: Bulk Create Multiple Allocations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation for CLASS type with 2 sections | Bulk data |
| 2 | Verify multiple records created | Each section has record |
| 3 | All share same exam_paper_id and paper_set_id | Consistent |

#### TC-P51: Filter By Conducted In School

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 in-school and 2 out-of-school allocations | Mixed data |
| 2 | Filter by conducted_in_school = true | 2 in-school shown |
| 3 | Filter by conducted_in_school = false | 2 out-of-school shown |

#### TC-P52: Filter By Room

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation in Room A and Room B | 2 rooms |
| 2 | Filter by room_id = Room A | Only Room A shown |

#### TC-P53: Filter By Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocations under Exam E1 and Exam E2 | 2 exams |
| 2 | Filter by exam_id = E1 | Only E1 allocations shown |

#### TC-P54: Filter By Scheduled Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocations on 2026-01-15, 2026-02-20, 2026-03-10 | 3 dates |
| 2 | Set date range from 2026-02-01 to 2026-03-01 | Range applied |
| 3 | Only 2026-02-20 shown | Filtered correctly |

### 7.2 Additional Negative Test Cases

#### TC-N33: Store — Invalid Exam Paper ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST store with exam_paper_id = 99999 | Non-existent |
| 2 | Validation error | Invalid exam paper |

#### TC-N34: Store — Invalid Paper Set ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST store with paper_set_id = 99999 | Non-existent |
| 2 | Validation error | Invalid paper set |

#### TC-N35: Store — Invalid Class ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST store with class_id = 99999 | Non-existent |
| 2 | Validation error | Invalid class |

#### TC-N36: Store — SECTION Type Without class_section_jnt_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with allocation_type=SECTION, class_id set, no class_section_jnt_id | Missing junction |
| 2 | Validation error | Class section junction required |

#### TC-N37: Store — EXAM_GROUP Type Without exam_group_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with allocation_type=EXAM_GROUP, no exam_group_id | Missing group |
| 2 | Validation error | Exam group required for group allocation |

#### TC-N38: Store — STUDENT Type Without student_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with allocation_type=STUDENT, no student_id | Missing student |
| 2 | Validation error | Student required for student allocation |

#### TC-N39: Store — Conflicting Type and Target IDs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with allocation_type=CLASS, but student_id populated | Conflict |
| 2 | Validation error | Invalid target for allocation type |

#### TC-N40: Update — Non-Existent Allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST update with allocation_id=99999 | Not found |
| 2 | 404 response | Allocation not found |

#### TC-N41: Toggle Status On Non-Existent Allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call toggleStatus with allocation_id=99999 | Not found |
| 2 | AJAX response | success: false |

#### TC-N42: Force Delete Without Prior Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call forceDelete on active allocation (not soft-deleted) | Active record |
| 2 | 404 or error | Must soft-delete first |

### 7.3 Additional Code Review Test Cases

#### TC-CR07: ExamAllocationRequest Conditional Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamAllocationRequest.php | rules() method |
| 2 | Verify switch on allocation_type | 4 cases |
| 3 | Verify CLASS case: room_id required_if conducted_in_school | Conditional rule |
| 4 | Verify SECTION case: class_section_jnt_id required | Required rule |
| 5 | Verify EXAM_GROUP case: exam_group_id required | Required rule |
| 6 | Verify STUDENT case: student_id required | Required rule |

#### TC-CR08: ExamAllocation Index Query

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index() in controller | Eager loading |
| 2 | Verify with(examPaper, paperSet, class, section, room, examGroup, student) | All relations |
| 3 | Verify filters: exam_paper_id, allocation_type, class_id, exam_id, scheduled_date, is_active | All present |

#### TC-CR09: Show Page With Usage Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect show() method | Single allocation fetched |
| 2 | Verify isUsed() called | Usage check |
| 3 | Verify usageDetails passed to view | View data |

#### TC-CR10: allocation_target Accessor Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamAllocation model | getAllocationTargetAttribute |
| 2 | Verify match on allocation_type | 4 branches |
| 3 | Verify CLASS: returns class.name | Class name |
| 4 | Verify SECTION: returns Class - Section | Combined name |
| 5 | Verify EXAM_GROUP: returns group.name | Group name |
| 6 | Verify STUDENT: returns student.name | Student name |

#### TC-CR11: Soft Delete Sets is_active=false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect destroy() | is_active=false before delete |
| 2 | Verify restore() | is_active=true after restore |
| 3 | Confirm consistent pattern | Follows exam module convention |

#### TC-CR12: DB Transaction On Store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() | beginTransaction |
| 2 | Verify create inside transaction | After validation |
| 3 | commit() on success | Present |
| 4 | rollBack() on exception | Present |

#### TC-CR13: Activity Logging

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() | activityLog(Stored) |
| 2 | Inspect update() | activityLog(Updated, changes) |
| 3 | Inspect destroy() | activityLog(Trashed) |
| 4 | Inspect restore() | activityLog(Restored) |
| 5 | Inspect forceDelete() | activityLog(Deleted) |
| 6 | Inspect toggleStatus() | activityLog(Toggled) |

#### TC-CR14: Exam Allocation Gate Authorization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect each controller method | Gate::authorize() present |
| 2 | verify viewAny on index/show | Permission check |
| 3 | verify create on create/store | Permission check |
| 4 | verify update on edit/update | Permission check |
| 5 | verify delete on destroy | Permission check |
