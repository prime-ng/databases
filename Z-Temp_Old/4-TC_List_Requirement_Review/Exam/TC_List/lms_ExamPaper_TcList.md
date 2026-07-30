# lms_ExamPaper_TcList

## Module: LmsExam → Creation & Allocation → Exam Paper

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Creation & Allocation |
| Feature | Exam Paper |
| URL(s) | `/lms-exam/creation-allocation` (index via tab with `active_tab=exam_paper`), `/lms-exam/exam-paper/store` (create/update), `/lms-exam/exam-paper/create` (create form), `/lms-exam/exam-paper/{exam_paper}` (show), `/lms-exam/exam-paper/{exam_paper}/edit` (edit), `/lms-exam/exam-paper/{exam_paper}/destroy` (delete), `/lms-exam/exam-paper/trash/view` (trash), `/lms-exam/exam-paper/{exam_paper}/restore` (restore), `/lms-exam/exam-paper/{exam_paper}/force-delete` (forceDelete), `/lms-exam/exam-paper/{exam_paper}/toggle-status` (toggleStatus) |
| Controller | `Modules\LmsExam\Http\Controllers\ExamPaperController` |
| Model(s) | `Modules\LmsExam\Models\ExamPaper` (`lms_exam_papers`, SoftDeletes) |
| Validation (Create) | `Modules\LmsExam\Http\Requests\ExamPaperRequest` |
| Validation (Update) | `Modules\LmsExam\Http\Requests\ExamPaperRequest` |
| Permissions | `tenant.exam-paper.viewAny`, `tenant.exam-paper.view`, `tenant.exam-paper.create`, `tenant.exam-paper.update`, `tenant.exam-paper.delete`, `tenant.exam-paper.restore`, `tenant.exam-paper.forceDelete`, `tenant.exam-paper.status` |
| Soft Deletes | Yes (`ExamPaper` uses `SoftDeletes` trait; destroy() sets `is_active=false` before `delete()`) |
| Activity Log | Events: `Stored`, `Updated` (with old/new diff), `Trashed`, `Restored`, `Deleted` (permanent), `Toggled` |
| Usage Check | `ExamPaperUsageCheckService` — checks allocations, paper sets, blueprints, results, student attempts |
| Query Service | `ExamPaperController::queryBuilder()` — filters by exam, class, subject, mode, search, is_active |

---

## 2. Pre-conditions

- Required permissions: `tenant.exam-paper.viewAny`, `tenant.exam-paper.view`, `tenant.exam-paper.create`, `tenant.exam-paper.update`, `tenant.exam-paper.delete`, `tenant.exam-paper.restore`, `tenant.exam-paper.forceDelete`, `tenant.exam-paper.status`
- Required seed data: At least one active `Exam`, one active `SchoolClass`, one active `Subject`, one active `ExamStatusEvent` with `event_type='PAPER'`
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For usage-check tests: Pre-created `ExamPaperSet`, `ExamAllocation`, `ExamBlueprint`, `ExamResult`, `ExamAttempt` records referencing the paper
- For offline mode tests: `offline_entry_mode` field set to `BULK_TOTAL` or `QUESTION_WISE`
- For online mode tests: Various boolean flags for proctoring, randomization, etc.

---

## 3. Default Data Load

When the page loads via `creationAllocation()` (GET /lms-exam/creation-allocation with `active_tab=exam_paper`), the following data is fetched:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Exam Papers Grid | `ExamPaperController@queryBuilder()` | `ExamPaper::with(exam,class,subject,status)->latest()` | exam_id, class_id, subject_id, mode, search(paper_code,title,instructions,exam_title,subject_name), is_active | 10/page |
| Shared: Exams List | `Exam::where('is_active', '1')->get()` | All active exams | is_active=1 | None |
| Shared: Classes | `SchoolClass::where('is_active', '1')->get()` | All active classes | is_active=1 | None |
| Shared: Subjects | `Subject::where('is_active', '1')->get()` | All active subjects | is_active=1 | None |
| Shared: Statuses | `ExamStatusEvent::where('is_active', '1')->where('event_type', 'PAPER')->get()` | Active paper status events | is_active=1, event_type=PAPER | None |
| Shared: Difficulty Configs | `DifficultyDistributionConfig::where('is_active', '1')->get()` | All active difficulty configs | is_active=1 | None |

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Paper code**: Unique per exam (`exam_id, paper_code` composite unique); max 50 chars
- **Paper title**: String max 150 chars
- **Pre-test cleanup**: Delete created papers by code before/after tests to avoid collisions
- **Mode-specific fields**: `offline_entry_mode` required_if mode=OFFLINE; online-specific booleans default to 0
- **Boolean casting**: All TINYINT(1) fields cast to boolean via `prepareForValidation()`
- **Decimal precision**: `total_marks` DECIMAL(8,2), `passing_percentage` DECIMAL(5,2), `negative_marks` DECIMAL(5,2)

## 5. Business Conditions

### 4.1 Database Schema — `lms_exam_papers`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | exam_id | INT UNSIGNED | NOT NULL, FK → `lms_exams.id` ON DELETE CASCADE |
| BC-DB-03 | class_id | INT UNSIGNED | NOT NULL, FK → `sch_classes.id` |
| BC-DB-04 | subject_id | INT UNSIGNED | NOT NULL, FK → `sch_subjects.id` |
| BC-DB-05 | paper_code | VARCHAR(50) | NOT NULL, UNIQUE `(exam_id, paper_code)` |
| BC-DB-06 | title | VARCHAR(150) | NOT NULL |
| BC-DB-07 | mode | ENUM('ONLINE','OFFLINE') | NOT NULL |
| BC-DB-08 | total_marks | DECIMAL(8,2) | NOT NULL DEFAULT 0.00 |
| BC-DB-09 | passing_percentage | DECIMAL(5,2) | NOT NULL DEFAULT 0.00 |
| BC-DB-10 | duration_minutes | INT UNSIGNED | DEFAULT NULL |
| BC-DB-11 | total_questions | INT UNSIGNED | NOT NULL DEFAULT 0 |
| BC-DB-12 | negative_marks | DECIMAL(5,2) | DEFAULT 0.00 |
| BC-DB-13 | instructions | TEXT | DEFAULT NULL |
| BC-DB-14 | only_unused_questions | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-15 | only_authorised_questions | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-16 | difficulty_config_id | INT UNSIGNED | DEFAULT NULL, FK → `lms_difficulty_distribution_configs.id` |
| BC-DB-17 | ignore_difficulty_config | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-18 | allow_calculator | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-19 | show_marks_per_question | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-20 | is_randomized | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-21 | is_proctored | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-22 | is_ai_proctored | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-23 | fullscreen_required | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-24 | browser_lock_required | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-25 | shuffle_questions | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-26 | shuffle_options | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-27 | timer_enforced | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-28 | offline_entry_mode | ENUM('BULK_TOTAL','QUESTION_WISE') | DEFAULT 'QUESTION_WISE' |
| BC-DB-29 | is_ques_wise_file_upload | TINYINT(1) | DEFAULT 0 |
| BC-DB-30 | status_id | INT UNSIGNED | NOT NULL DEFAULT 0, FK → `lms_exam_status_events.id` |
| BC-DB-31 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-32 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-33 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-34 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules — `ExamPaperRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | exam_id | required, exists:lms_exams,id | "Exam is required" |
| BC-VAL-02 | class_id | required, exists:sch_classes,id | "Class is required" |
| BC-VAL-03 | subject_id | required, exists:sch_subjects,id | "Subject is required" |
| BC-VAL-04 | paper_code | required, string, max:50, unique scope (exam_id) ignoring own ID | "Paper code is required" / "This paper code already exists for this exam" |
| BC-VAL-05 | title | required, string, max:150 | "Paper title is required" |
| BC-VAL-06 | mode | required, in:ONLINE,OFFLINE | "Exam mode is required" |
| BC-VAL-07 | total_marks | required, numeric, min:0, max:999999.99 | "Total marks are required" |
| BC-VAL-08 | passing_percentage | required, numeric, min:0, max:100 | "Passing percentage is required" |
| BC-VAL-09 | total_questions | nullable, integer, min:0 | — |
| BC-VAL-10 | duration_minutes | nullable, integer, min:1, max:1440 | — |
| BC-VAL-11 | instructions | nullable, string | — |
| BC-VAL-12 | negative_marks | nullable, numeric, min:0 | — |
| BC-VAL-13 | allow_calculator | boolean | — |
| BC-VAL-14 | show_marks_per_question | boolean | — |
| BC-VAL-15 | is_randomized | boolean | — |
| BC-VAL-16 | shuffle_options | boolean | — |
| BC-VAL-17 | timer_enforced | boolean | — |
| BC-VAL-18 | is_proctored | boolean | — |
| BC-VAL-19 | is_ai_proctored | boolean | — |
| BC-VAL-20 | fullscreen_required | boolean | — |
| BC-VAL-21 | browser_lock_required | boolean | — |
| BC-VAL-22 | shuffle_questions | boolean | — |
| BC-VAL-23 | offline_entry_mode | required_if:mode,OFFLINE, in:BULK_TOTAL,QUESTION_WISE | "Entry mode is required for offline exams" |
| BC-VAL-24 | is_ques_wise_file_upload | boolean | — |
| BC-VAL-25 | status_id | required, exists:lms_exam_status_events,id | "Status is required" |
| BC-VAL-26 | is_active | boolean | — |
| BC-VAL-27 | only_unused_questions | boolean | — |
| BC-VAL-28 | only_authorised_questions | boolean | — |
| BC-VAL-29 | difficulty_config_id | nullable, exists:lms_difficulty_distribution_configs,id | — |
| BC-VAL-30 | ignore_difficulty_config | boolean | — |

### 4.3 Validation Rules — `ExamPaperRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | paper_code | unique scope (exam_id) ignoring current paper ID | "This paper code already exists for this exam" |
| BC-VAL-U02 | Same as create | All other rules same as create | Same messages |
| BC-VAL-U03 | Usage (controller) | Checked before edit/update/destroy/restore/forceDelete | "Cannot edit/update/delete/restore this exam paper because it is allocated or has student attempts." |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.exam-paper.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.exam-paper.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.exam-paper.create | create(), store() | Without → 403 |
| BC-AUTH-04 | tenant.exam-paper.update | edit(), update(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.exam-paper.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.exam-paper.restore | trashed(), restore() | Without → 403 |
| BC-AUTH-07 | tenant.exam-paper.forceDelete | forceDelete() | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Paper code unique per exam | `Rule::unique('lms_exam_papers', 'paper_code')->where('exam_id', $this->exam_id)->ignore($paperId)` |
| BC-BIZ-02 | Usage check on edit | `ExamPaperUsageCheckService::isUsed()` blocks edit when allocations/sets/blueprints/results/attempts exist |
| BC-BIZ-03 | Usage check on update | Same block |
| BC-BIZ-04 | Usage check on delete | Same block |
| BC-BIZ-05 | Usage check on restore | Same block |
| BC-BIZ-06 | Usage check on forceDelete | Same block |
| BC-BIZ-07 | Status toggle NOT blocked by usage | toggleStatus works even if paper is in use |
| BC-BIZ-08 | Soft delete deactivates first | Sets `is_active=false` before `delete()` |
| BC-BIZ-09 | Restore reactivates | Sets `is_active=true` after `restore()` |
| BC-BIZ-10 | Boolean casting in prepareForValidation | All boolean fields cast via `$this->boolean()` |
| BC-BIZ-11 | offline_entry_mode required_if mode=OFFLINE | Validation: `required_if:mode,OFFLINE` |
| BC-BIZ-12 | Activity log — Stored | On successful create |
| BC-BIZ-13 | Activity log — Updated | On successful update (with old/new diff) |
| BC-BIZ-14 | Activity log — Trashed | On soft delete |
| BC-BIZ-15 | Activity log — Restored | On restore |
| BC-BIZ-16 | Activity log — Deleted | On force delete |
| BC-BIZ-17 | Activity log — Toggled | On status toggle |
| BC-BIZ-18 | DB transaction on create | store() wrapped in DB::beginTransaction/commit/rollback |
| BC-BIZ-19 | DB transaction on update | update() wrapped in transaction |
| BC-BIZ-20 | DB transaction on delete | destroy() wrapped in transaction |
| BC-BIZ-21 | DB transaction on restore | restore() wrapped in transaction |
| BC-BIZ-22 | DB transaction on forceDelete | forceDelete() wrapped in transaction |
| BC-BIZ-23 | DB transaction on toggleStatus | toggleStatus() wrapped in transaction |
| BC-BIZ-24 | Ajax toggle returns JSON | JSON `{success, is_active, message}` |
| BC-BIZ-25 | Status scope | Only status events with `event_type='PAPER'` shown in form |
| BC-BIZ-26 | Difficulty config only from active configs | `DifficultyDistributionConfig::where('is_active', '1')` |
| BC-BIZ-27 | Online-specific booleans default 0 | is_proctored, is_ai_proctored, fullscreen_required, browser_lock_required, shuffle_questions default 0 |
| BC-BIZ-28 | show_marks_per_question default 1 | Default true for showing marks per question |
| BC-BIZ-29 | timer_enforced default 1 | Timer enforced by default |
| BC-BIZ-30 | Usage check returns detailed message | "This exam paper is used in: X allocation(s), Y paper set(s)." |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | exam_id | lms_exams (id) | CASCADE |
| BC-REF-02 | class_id | sch_classes (id) | None (NO ACTION) |
| BC-REF-03 | subject_id | sch_subjects (id) | None (NO ACTION) |
| BC-REF-04 | difficulty_config_id | lms_difficulty_distribution_configs (id) | None (NO ACTION) |
| BC-REF-05 | status_id | lms_exam_status_events (id) | None (NO ACTION) |
| BC-REF-06 | exam_paper_id (in lms_exam_paper_sets) | lms_exam_papers (id) | CASCADE |
| BC-REF-07 | exam_paper_id (in lms_exam_scopes) | lms_exam_papers (id) | CASCADE |
| BC-REF-08 | exam_paper_id (in lms_exam_blueprints) | lms_exam_papers (id) | CASCADE |
| BC-REF-09 | exam_paper_id (in lms_exam_allocations) | lms_exam_papers (id) | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Exam Paper List Page Loads With All UI Elements | Page loads with search bar, exam filter, class filter, subject filter, mode filter, Add Paper button, table, pagination | — | — | ⬜ |
| TC-P02 | Filter Exam Papers By Exam | Table shows only papers belonging to selected exam | — | — | ⬜ |
| TC-P03 | Filter Exam Papers By Class | Table shows only papers for selected class | — | — | ⬜ |
| TC-P04 | Filter Exam Papers By Subject | Table shows only papers for selected subject | — | — | ⬜ |
| TC-P05 | Filter Exam Papers By Mode | Table shows only ONLINE or OFFLINE papers | — | — | ⬜ |
| TC-P06 | Search Exam Papers By Paper Code | Table filters to show only papers matching paper_code | — | — | ⬜ |
| TC-P07 | Search Exam Papers By Title | Table filters to show only papers matching title | — | — | ⬜ |
| TC-P08 | Search Exam Papers By Exam Title | Table filters by exam title via relationship | — | — | ⬜ |
| TC-P09 | Search Exam Papers By Subject Name | Table filters by subject name via relationship | — | — | ⬜ |
| TC-P10 | Filter By Active/Inactive Status | Active filter shows only active papers; Inactive shows only inactive | — | — | ⬜ |
| TC-P11 | Create ONLINE Exam Paper With All Required Fields | Paper created with exam_id, class_id, subject_id, paper_code, title, mode=ONLINE, total_marks, passing_percentage, status_id — all saved correctly | — | — | ⬜ |
| TC-P12 | Create OFFLINE Exam Paper With All Required Fields | Paper created with mode=OFFLINE including offline_entry_mode (BULK_TOTAL or QUESTION_WISE) | — | — | ⬜ |
| TC-P13 | Create ONLINE Paper With All Optional Flags | is_proctored, is_ai_proctored, fullscreen_required, browser_lock_required, shuffle_questions, allow_calculator, show_marks_per_question, is_randomized, shuffle_options, timer_enforced all saved | — | — | ⬜ |
| TC-P14 | Create Paper With Difficulty Config | difficulty_config_id linked; ignore_difficulty_config toggle saved | — | — | ⬜ |
| TC-P15 | Create Paper With Question Source Settings | only_unused_questions=1, only_authorised_questions=1 saved | — | — | ⬜ |
| TC-P16 | Create Paper With Instructions | Instructions text saved | — | — | ⬜ |
| TC-P17 | Create Paper With Duration And Total Questions | duration_minutes (1-1440) and total_questions saved | — | — | ⬜ |
| TC-P18 | Create Paper With Negative Marks | negative_marks saved (decimal) | — | — | ⬜ |
| TC-P19 | Edit Exam Paper Loads Pre-Filled Data | Edit form shows existing paper data in all fields | — | — | ⬜ |
| TC-P20 | Update Exam Paper Title And Code | Title and paper_code updated; unique per exam enforced | — | — | ⬜ |
| TC-P21 | Update Exam Paper Mode From ONLINE To OFFLINE | Mode changed; offline_entry_mode now required | — | — | ⬜ |
| TC-P22 | Update Exam Paper Total Marks And Passing Percentage | total_marks and passing_percentage updated | — | — | ⬜ |
| TC-P23 | Update Exam Paper Toggle Online Flags | boolean flags toggled on/off | — | — | ⬜ |
| TC-P24 | Update Exam Paper Change Difficulty Config | difficulty_config_id changed | — | — | ⬜ |
| TC-P25 | View Exam Paper Details Page | Paper details shown with exam, class, subject, mode, marks, percentage, duration, flags, instructions, status, usage info | — | — | ⬜ |
| TC-P26 | Soft Delete Unused Exam Paper | `is_active=false` set; `deleted_at` timestamp set; activity log "Trashed" | — | — | ⬜ |
| TC-P27 | Trash Page Shows Deleted Exam Papers | Only soft-deleted papers listed with restore + force delete buttons | — | — | ⬜ |
| TC-P28 | Restore Exam Paper From Trash | `deleted_at=NULL`; `is_active=true`; activity log "Restored" | — | — | ⬜ |
| TC-P29 | Force Delete Unused Exam Paper | Record permanently removed; activity log "Deleted" | — | — | ⬜ |
| TC-P30 | Toggle Status Active To Inactive (AJAX) | `is_active` flips to 0; AJAX 200 `{success:true, is_active:false}` | — | — | ⬜ |
| TC-P31 | Toggle Status Inactive To Active (AJAX) | `is_active` flips to 1; AJAX 200 `{success:true, is_active:true}` | — | — | ⬜ |
| TC-P32 | Activity Logged After Create | `Stored` event logged with message "A new exam paper was created." | — | — | ⬜ |
| TC-P33 | Activity Logged After Update | `Updated` event logged with old/new value diff JSON | — | — | ⬜ |
| TC-P34 | Activity Logged After Soft Delete | `Trashed` event logged | — | — | ⬜ |
| TC-P35 | Activity Logged After Restore | `Restored` event logged | — | — | ⬜ |
| TC-P36 | Activity Logged After Force Delete | `Deleted` event logged | — | — | ⬜ |
| TC-P37 | Activity Logged After Toggle | `Toggled` event logged | — | — | ⬜ |
| TC-P38 | Full Lifecycle: Create → Edit → Toggle → Delete → Trash → Restore → Force Delete | All 7 transitions successful; activity logged at each step | — | — | ⬜ |
| TC-P39 | Empty State — No Exam Papers | Table shows "No exam papers found" message; Add Exam Paper button visible | — | — | ⬜ |
| TC-P40 | Create OFFLINE Paper With QUESTION_WISE Entry Mode | offline_entry_mode=QUESTION_WISE; is_ques_wise_file_upload toggle saved | — | — | ⬜ |
| TC-P41 | Create OFFLINE Paper With BULK_TOTAL Entry Mode | offline_entry_mode=BULK_TOTAL | — | — | ⬜ |
| TC-P42 | Same Paper Code Allowed Under Different Exam | Two papers in different exams can share same paper_code | — | — | ⬜ |
| TC-P43 | Pagination Works On Exam Paper List | Page 2 shows next 10 records; page links preserve active_tab=exam_paper | — | — | ⬜ |
| TC-P44 | ToggleStatus Works Even When Paper Is Used | Status can be toggled even with allocations/sets (not blocked by usage check) | — | — | ⬜ |
| TC-P45 | Create Paper Without Optional Boolean Flags | All optional booleans default to 0/false in DB | — | — | ⬜ |
| TC-P46 | Update Paper — Change Status To Different PAPER Status | Status changed and saved; only PAPER type statuses shown | — | — | ⬜ |
| TC-P47 | Create Paper With High Total Marks (999999.99) | Max decimal value accepted | — | — | ⬜ |
| TC-P48 | Create Paper With Zero Passing Percentage | passing_percentage=0 accepted (min:0) | — | — | ⬜ |
| TC-P49 | Update Paper Instructions | Instructions text updated | — | — | ⬜ |
| TC-P50 | Show Paper Details With Usage Details | If paper has allocations/sets, usage breakdown shown on show page | — | — | ⬜ |
| TC-P51 | Filter By status_id | Grid shows papers matching selected status_id | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `exam_id` | Validation error: "Exam is required" | — | — | ⬜ |
| TC-N02 | Required — Missing `class_id` | Validation error: "Class is required" | — | — | ⬜ |
| TC-N03 | Required — Missing `subject_id` | Validation error: "Subject is required" | — | — | ⬜ |
| TC-N04 | Required — Missing `paper_code` | Validation error: "Paper code is required" | — | — | ⬜ |
| TC-N05 | Required — Missing `title` | Validation error: "Paper title is required" | — | — | ⬜ |
| TC-N06 | Required — Missing `mode` | Validation error: "Exam mode is required" | — | — | ⬜ |
| TC-N07 | Required — Missing `total_marks` | Validation error: "Total marks are required" | — | — | ⬜ |
| TC-N08 | Required — Missing `passing_percentage` | Validation error: "Passing percentage is required" | — | — | ⬜ |
| TC-N09 | Required — Missing `status_id` | Validation error: "Status is required" | — | — | ⬜ |
| TC-N10 | Required — Missing `offline_entry_mode` When Mode=OFFLINE | Validation error: "Entry mode is required for offline exams" | — | — | ⬜ |
| TC-N11 | Duplicate Paper Code Within Same Exam | "This paper code already exists for this exam" | — | — | ⬜ |
| TC-N12 | Max Length — Title > 150 Characters | Validation fails on title.max | — | — | ⬜ |
| TC-N13 | Max Length — Paper Code > 50 Characters | Validation fails on paper_code.max | — | — | ⬜ |
| TC-N14 | Invalid Mode Value | Validation error: "The selected mode is invalid." | — | — | ⬜ |
| TC-N15 | Invalid `offline_entry_mode` Value | Validation error: "The selected offline entry mode is invalid." | — | — | ⬜ |
| TC-N16 | Total Marks Negative | Validation fails on total_marks.min (must be >= 0) | — | — | ⬜ |
| TC-N17 | Total Marks Exceeds 999999.99 | Validation fails on total_marks.max | — | — | ⬜ |
| TC-N18 | Passing Percentage Negative | Validation fails on passing_percentage.min | — | — | ⬜ |
| TC-N19 | Passing Percentage > 100 | Validation fails on passing_percentage.max | — | — | ⬜ |
| TC-N20 | Invalid Duration — 0 or Negative | Validation fails on duration_minutes.min (must be >= 1) | — | — | ⬜ |
| TC-N21 | Duration Exceeds 1440 | Validation fails on duration_minutes.max | — | — | ⬜ |
| TC-N22 | Invalid FK — Non-Existent `exam_id` | Validation error: "The selected exam id is invalid." | — | — | ⬜ |
| TC-N23 | Invalid FK — Non-Existent `class_id` | Validation error: "The selected class id is invalid." | — | — | ⬜ |
| TC-N24 | Invalid FK — Non-Existent `subject_id` | Validation error: "The selected subject id is invalid." | — | — | ⬜ |
| TC-N25 | Invalid FK — Non-Existent `status_id` | Validation error: "The selected status id is invalid." | — | — | ⬜ |
| TC-N26 | Invalid FK — Non-Existent `difficulty_config_id` | Validation error on difficulty_config_id.exists | — | — | ⬜ |
| TC-N27 | Edit Blocked — Paper Has Allocations | "Cannot edit this exam paper because it is allocated or has student attempts." | — | — | ⬜ |
| TC-N28 | Update Blocked — Paper Has Attempts | "Cannot update this exam paper because it is allocated or has student attempts." | — | — | ⬜ |
| TC-N29 | Delete Blocked — Paper Has Paper Sets | "Cannot delete this exam paper because it is allocated or has student attempts." | — | — | ⬜ |
| TC-N30 | Restore Blocked — Paper Has Blueprints | "Cannot restore this exam paper because it is allocated or has student attempts." | — | — | ⬜ |
| TC-N31 | Force Delete Blocked — Paper Has Results | "Cannot permanently delete this exam paper because it is allocated or has student attempts." | — | — | ⬜ |
| TC-N32 | View Paper With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N33 | Edit/Update Paper With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N34 | Delete Paper With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N35 | Toggle Status With Invalid ID (404) | JSON 500: `{success: false, message: "Failed to update status."}` | — | — | ⬜ |
| TC-N36 | Restore Non-Deleted Paper | `onlyTrashed()->find()` returns null → 404 | — | — | ⬜ |
| TC-N37 | Force Delete Non-Trashed Paper | Paper found but not trashed; forceDelete proceeds | — | — | ⬜ |
| TC-N38 | Permission 403 — No Paper Permissions | 403 Forbidden on all endpoints for user without `tenant.exam-paper.*` gates | — | — | ⬜ |
| TC-N39 | Guest Access Redirect | Redirected to /login for all exam paper routes | — | — | ⬜ |
| TC-N40 | XSS Injection In Title/Instructions | Stored as literal string; Blade `{{ }}` escapes output; no script execution | — | — | ⬜ |
| TC-N41 | Whitespace-Only Title | Required validation catches empty/whitespace-only strings | — | — | ⬜ |
| TC-N42 | Negative Marks Negative Value | Validation error on negative_marks.min | — | — | ⬜ |
| TC-N43 | Total Questions Negative | Validation error on total_questions.min | — | — | ⬜ |
| TC-N44 | OFFLINE Mode Without offline_entry_mode | `required_if` validation fires | — | — | ⬜ |
| TC-N45 | Status Toggle With Invalid Boolean | Validation error: "The is active field must be true or false." | — | — | ⬜ |
| TC-N46 | Duplicate Paper Code Across Different Exams Allowed | Paper code must only be unique per exam, not globally | — | — | ⬜ |
| TC-N47 | Edit With Non-Exam-Type Status | Status dropdown only shows `event_type='PAPER'` statuses | — | — | ⬜ |
| TC-N48 | Create Paper For Non-Existent Exam | Exam must exist in `lms_exams` table | — | — | ⬜ |
| TC-N49 | Update Paper To Mode OFFLINE Without Entry Mode | If changing to OFFLINE, offline_entry_mode is required | — | — | ⬜ |
| TC-N50 | Create Paper With Empty Paper Code | Required validation rejects empty string | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create Paper → Auto-default is_active=1 | New paper created with `is_active=1` by DB default | — | — | ⬜ |
| TC-D02 | B | Soft Delete Paper → Paper Sets Cascade (DDL CASCADE) | DDL specifies CASCADE on `fk_set_paper`; deleting paper cascades to its sets | — | — | ⬜ |
| TC-D03 | B | Soft Delete Paper → Scopes Cascade | Exam scopes referencing paper cascaded | — | — | ⬜ |
| TC-D04 | B | Soft Delete Paper → Blueprints Cascade | Blueprints referencing paper cascaded | — | — | ⬜ |
| TC-D05 | B | Soft Delete Paper → Allocations Cascade | Allocations referencing paper cascaded | — | — | ⬜ |
| TC-D06 | C | Restore Paper → Sets/Scopes/Blueprints Remain Deleted | `restore()` only restores paper, not child records (no cascading restore) | — | — | ⬜ |
| TC-D07 | D | Exam Deletion Cascades To Papers (CASCADE) | Deleting an exam automatically deletes all its papers (DDL CASCADE) | — | — | ⬜ |
| TC-D08 | E | Cannot Delete Class/Subject While Paper References It (FK) | FK constraint error when trying to delete referenced class/subject | — | — | ⬜ |
| TC-D09 | F | Toggle Status — Inactive Paper Hidden From Dropdowns | Inactive paper excluded from paper dropdown lists | — | — | ⬜ |
| TC-D10 | G | Usage Check — getUsageCount Returns Correct Sum | Allocations + paperSets + blueprints + results + attempts count | — | — | ⬜ |
| TC-D11 | H | Usage Check — getUsageDetails Returns Breakdown Array | Returns counts for each category that has usage | — | — | ⬜ |
| TC-D12 | I | Usage Check — getUsageMessage Returns Formatted String | "This exam paper is used in: X allocation(s), Y paper set(s)." | — | — | ⬜ |
| TC-D13 | J | Concurrent Update — Two Users Edit Same Paper | Last save wins; no data corruption | — | — | ⬜ |
| TC-D14 | K | Rapid Status Toggle (Race Condition) | Handles rapid toggles without data corruption | — | — | ⬜ |
| TC-D15 | L | DB | P1 | lms_exam_papers with existing record | Unique Composite Constraint — uq_exam_paper_code (exam_id, paper_code) | Inserting duplicate (exam_id, paper_code) combination at DB level throws integrity constraint violation | — | — | ⬜ |
| TC-D16 | M | DB | P1 | lms_exam_papers with existing record | ENUM Validation — mode Column | Inserting value other than 'ONLINE' or 'OFFLINE' in mode column throws DB error | — | — | ⬜ |
| TC-D17 | N | DB | P1 | lms_exam_papers with existing record | ENUM Validation — offline_entry_mode Column | Inserting value other than 'BULK_TOTAL' or 'QUESTION_WISE' throws DB error | — | — | ⬜ |
| TC-D18 | O | Integration | P1 | ExamPaper with sets/allocations/blueprints/results/attempts | Usage Check — ExamPaperUsageCheckService::isUsed() | Returns true when paper has dependent records; blocks all destructive operations | — | — | ⬜ |
| TC-D19 | P | Integration | P1 | ExamPaper controller | Activity Log — All CRUD Events | Activity logged for Stored, Updated, Trashed, Restored, Deleted, Toggled events | — | — | ⬜ |
| TC-D20 | Q | Unit | P1 | ExamPaper model | Model Table Name | `ExamPaper` model has `protected $table = 'lms_exam_papers'` | — | — | ⬜ |
| TC-D21 | R | Unit | P1 | ExamPaper model | Model Fillable | `$fillable` includes all 31 columns listed | — | — | ⬜ |
| TC-D22 | S | Unit | P1 | ExamPaper model | SoftDeletes Trait | Model uses SoftDeletes; deleted_at column exists | — | — | ⬜ |
| TC-D23 | T | Unit | P1 | ExamPaper model | Model Relationships | belongsTo: exam, class, subject, status, difficultyConfig; hasMany: examScopes, examBlueprints, allocations, attempts, results, paperSets | — | — | ⬜ |
| TC-D24 | U | Unit | P1 | ExamPaper model | $casts Definition | All boolean fields cast to boolean; decimal fields cast to decimal:2 | — | — | ⬜ |
| TC-D25 | V | Unit | P1 | ExamPaperRequest | Unique Validation | paper_code unique scope (exam_id) ignoring own ID | — | — | ⬜ |
| TC-D26 | W | Unit | P1 | ExamPaperRequest | Required Validation | Required rules for exam_id, class_id, subject_id, paper_code, title, mode, total_marks, passing_percentage, status_id | — | — | ⬜ |
| TC-D27 | X | Unit | P1 | ExamPaperRequest | Boolean Casting | `prepareForValidation()` casts all 14 boolean fields | — | — | ⬜ |
| TC-D28 | Y | Unit | P1 | ExamPaperRequest | required_if For offline_entry_mode | `required_if:mode,OFFLINE` | — | — | ⬜ |
| TC-D29 | Z | Unit | P1 | ExamPaperPolicy | Permission Gates | ExamPaperPolicy defines viewAny, view, create, update, delete, restore, forceDelete, status, import, export, print gates | — | — | ⬜ |
| TC-D30 | AA | Unit | P1 | Routes | Resource Routes | Routes for exam-paper CRUD + trashed, restore, forceDelete, toggleStatus | — | — | ⬜ |
| TC-D31 | AB | Unit | P1 | ExamPaperUsageCheckService | getUsageCount Returns Correct Count | Allocations + PaperSets + Blueprints + Results + Attempts | — | — | ⬜ |
| TC-D32 | AC | Unit | P1 | ExamPaperUsageCheckService | getUsageDetails Returns Breakdown | Array with keys: Allocations, Paper Sets, Blueprints, Results, StudentAttempts | — | — | ⬜ |
| TC-D33 | AD | Unit | P1 | ExamPaperUsageCheckService | getUsageMessage Returns Formatted | "This exam paper is used in: X allocation(s), Y paper set(s)." | — | — | ⬜ |
| TC-D34 | AE | Unit | P1 | ExamPaperUsageCheckService | hasAttempts Method | Returns true when usage count > 0 | — | — | ⬜ |
| TC-D35 | AF | Unit | P1 | ExamPaperController | Transaction Handling | All state-changing methods use DB::beginTransaction/commit/rollback | — | — | ⬜ |
| TC-D36 | AG | Unit | P1 | ExamPaperController | findOrFail Usage | edit, update, show, destroy, restore, forceDelete, toggleStatus use findOrFail | — | — | ⬜ |
| TC-D37 | AH | Unit | P1 | ExamPaperController | Gate Authorization | Gate::authorize() called before each CRUD operation | — | — | ⬜ |
| TC-D38 | AI | Unit | P1 | ExamPaperController | queryBuilder Filters | All filters: exam_id, class_id, subject_id, mode, search (multi-field), is_active; ordered by latest() | — | — | ⬜ |
| TC-D39 | AJ | Integration | P1 | ExamPaperController | show() Loads Usage Details | view receives $isUsed and $usageDetails variables | — | — | ⬜ |
| TC-D40 | AK | Cross-Module | P1 | Paper Sets — lms_exam_paper_sets FK References lms_exam_papers.id | `lms_exam_paper_sets.exam_paper_id` FK → `lms_exam_papers.id` ON DELETE CASCADE; deleting paper cascades to its sets | — | — | ⬜ |
| TC-D41 | AL | Cross-Module | P1 | Allocations — lms_exam_allocations FK References lms_exam_papers.id | `lms_exam_allocations.exam_paper_id` FK → `lms_exam_papers.id` ON DELETE CASCADE | — | — | ⬜ |
| TC-D42 | AM | Cross-Module | P1 | Scopes — lms_exam_scopes FK References lms_exam_papers.id | `lms_exam_scopes.exam_paper_id` FK → `lms_exam_papers.id` ON DELETE CASCADE | — | — | ⬜ |
| TC-D43 | AN | Cross-Module | P1 | Blueprints — lms_exam_blueprints FK References lms_exam_papers.id | `lms_exam_blueprints.exam_paper_id` FK → `lms_exam_papers.id` ON DELETE CASCADE | — | — | ⬜ |
| TC-D44 | AO | Cross-Module | P1 | Status Events — Only PAPER type shown in form | `ExamStatusEvent::where('event_type', 'PAPER')` filter applied; EXAM type statuses excluded | — | — | ⬜ |
| TC-D45 | AP | Code Review | P1 | Blade @can Directives For Paper CRUD Buttons | @can('tenant.exam-paper.create'), @can('tenant.exam-paper.edit'), @can('tenant.exam-paper.delete') used | — | — | ◌ |
| TC-D46 | AQ | Code Review | P1 | View — isset()/null-safe Checks | Blade views use isset/optional for relationship access | — | — | ◌ |
| TC-D47 | AR | Code Review | P1 | Controller — JSON Response After ToggleStatus | toggleStatus returns response()->json() with success flag | — | — | ◌ |
| TC-D48 | AS | Unit | P1 | ExamPaperRequest authorize() | FormRequest Gates checks tenant.exam-paper.create for POST, tenant.exam-paper.update for PUT/PATCH | — | — | ◌ |
| TC-D49 | AT | Code Review | P1 | Controller — Usage Check Before Edit/Update/Destroy/Restore/ForceDelete | ExamPaperUsageCheckService::isUsed() called before each destructive operation | — | — | ◌ |
| TC-D50 | AU | Code Review | P1 | Controller — try-catch Exception Handling | All state-changing methods wrapped in try-catch; exceptions caught and handled | — | — | ◌ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.exam-paper.create'), @can('tenant.exam-paper.edit'), @can('tenant.exam-paper.delete'), @can('tenant.exam-paper.view'), @canany(['tenant.exam-paper.restore', 'tenant.exam-paper.forceDelete']) for access control on all CRUD buttons and actions | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | Exam paper routes registered in breadcrumb config; breadcrumb visible and links correctly | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — try-catch Exception Handling on All CRUD Methods | All state-changing methods use try-catch; exceptions are caught, logged, and user receives error feedback | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — DB Transactions on Multi-Step Writes | Methods use DB::beginTransaction/commit/rollback; partial writes do not occur on failure | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Relationship expressions in Blade use isset/$var?->relation/null-safe operator; no undefined property errors | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | View — Flash Messages After CRUD | After CRUD actions, controller redirects with success/error flash messages | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Controller — findOrFail on All ID-Dependent Methods | All ID-dependent methods use findOrFail; 404 returned on not found | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | Controller — Usage Check Before Edit/Update/Destroy/Restore/ForceDelete | ExamPaperUsageCheckService::isUsed() called before each destructive operation; blocked with error when used | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | View — Show Page Disabled Edit Button When isUsed | Edit button disabled with tooltip when `$isUsed` is true | — | — | ◌ |
| TC-CR10 | CR | Code Review | P1 | Controller — prepareForValidation Bool Casting | All 14 boolean fields cast via `$this->boolean()` before validation | — | — | ◌ |
| TC-CR11 | CR | Code Review | P1 | Controller — $filters array missing status_id | queryBuilder() supports status_id filter (line 75-77) but $filters array in index() (line 29-35) does not include it; view may not expose status filter UI | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR03: Controller — try-catch Exception Handling on All CRUD Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperController.php | Controller class found in Modules/LmsExam/Http/Controllers/ |
| 2 | Inspect store() method | Business logic wrapped in try {} catch(\Exception $e) {}; on exception, DB rollback and error logged |
| 3 | Inspect update() method | try-catch present; findOrFail inside try |
| 4 | Inspect destroy() method | try-catch present; is_active toggle inside try |
| 5 | Inspect restore() method | try-catch present; is_active restore inside try |
| 6 | Inspect forceDelete() method | try-catch present; withTrashed+findOrFail inside try |
| 7 | Inspect toggleStatus() method | try-catch present; DB transaction inside try |
| 8 | Simulate DB failure during store | Exception caught; user redirected with error message; no partial data written |

#### TC-CR04: Controller — DB Transactions on Multi-Step Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperController.php | Controller class found |
| 2 | Inspect store() method | DB::beginTransaction() before create; DB::commit() after activityLog; DB::rollback() on exception |
| 3 | Inspect update() method | DB::beginTransaction before update; commit after activityLog; rollback on exception |
| 4 | Inspect destroy() method | is_active=false toggle + delete() + activityLog all in single transaction |
| 5 | Inspect restore() method | is_active=true + restore() + activityLog in single transaction |
| 6 | Inspect forceDelete() method | forceDelete() + activityLog in single transaction |
| 7 | Verify no partial writes occur | If activityLog throws exception after model save, model changes are rolled back |

#### TC-CR05: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open exam-paper/index.blade.php | View file found in lmsexam::exam-paper/ |
| 2 | Scan for relationship access patterns (e.g. $record->relation->field) | All such expressions use isset() or optional() or ?-> null-safe operator |
| 3 | Scan for foreach loops over relationships | Loop target checked with isset() or !empty() before iterating |
| 4 | Create a record with null relationship | View renders without undefined index/property error |
| 5 | Load index page with records that have missing relations | No 500 errors; null values displayed gracefully (dash or empty string) |

#### TC-CR06: View — Flash Messages After CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new exam paper | POST to store(); redirects with session flash |
| 2 | Verify success message after create | Page shows success alert: 'Exam paper created successfully' (flash('created.exam-paper')) |
| 3 | Update the exam paper | PUT to update(); redirects with flash |
| 4 | Verify success message after update | 'Exam paper updated successfully' |
| 5 | Soft delete the exam paper | DELETE to destroy(); redirects with flash |
| 6 | Verify success message after delete | 'Exam paper trashed successfully' |
| 7 | Restore from trash | POST to restore(); redirects with flash |
| 8 | Verify success message after restore | 'Exam paper restored successfully' |
| 9 | Force delete from trash | DELETE to forceDelete(); redirects with flash |
| 10 | Verify success message after force delete | 'Exam paper force deleted successfully' |

#### TC-CR01: Blade @can Directives — Permission-based Visibility for All Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php for add/create button | @can('tenant.exam-paper.create') wraps the Add Paper button; user without create permission does not see it |
| 2 | Inspect row-level action buttons (view, edit, delete, status toggle) | @can('tenant.exam-paper.view'), @can('tenant.exam-paper.edit'), @can('tenant.exam-paper.delete'), @can('tenant.exam-paper.status') used appropriately |
| 3 | Inspect trash.blade.php for restore/forceDelete buttons | @canany(['tenant.exam-paper.restore', 'tenant.exam-paper.forceDelete']) wraps action buttons |
| 4 | Inspect show.blade.php for edit button | @can('tenant.exam-paper.edit') wraps the Edit button; disabled with tooltip when `$isUsed` is true |
| 5 | Log in as user with all permissions | All buttons visible and functional |
| 6 | Log in as user with viewAny only (no create/edit/delete) | Add Paper button hidden; action columns show view icon only |

#### TC-CR07: Controller — findOrFail on All ID-Dependent Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperController.php | Controller class found |
| 2 | Inspect show($id) method | Uses ExamPaper::findOrFail($id) |
| 3 | Inspect edit($id) method | Uses ExamPaper::findOrFail($id) |
| 4 | Inspect update($request, $id) method | Uses ExamPaper::findOrFail($id) |
| 5 | Inspect destroy($id) method | Uses ExamPaper::findOrFail($id) |
| 6 | Inspect restore($id) method | Uses ExamPaper::onlyTrashed()->findOrFail($id) |
| 7 | Inspect forceDelete($id) method | Uses ExamPaper::withTrashed()->findOrFail($id) |
| 8 | Inspect toggleStatus($request, $id) method | Uses ExamPaper::findOrFail($id) |

#### TC-CR08: Controller — Usage Check Before Edit/Update/Destroy/Restore/ForceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperController.php | Controller class found |
| 2 | Inspect edit($id) method | `$usageCheck->isUsed($id)` called before proceeding; if true → back with error |
| 3 | Inspect update() method | Usage check called first; if used → back with error |
| 4 | Inspect destroy() method | Usage check called first; if used → back with error |
| 5 | Inspect restore() method | Usage check called first; if used → back with error |
| 6 | Inspect forceDelete() method | Usage check called first; if used → back with error |
| 7 | Verify toggleStatus does NOT check usage | Status can be toggled even when paper is in use |

#### TC-CR09: View — Show Page Disabled Edit Button When isUsed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open show.blade.php | View file found in lmsexam::exam-paper/ |
| 2 | Find the Edit button code | @can('tenant.exam-paper.edit') wraps a link |
| 3 | Check for `$isUsed` condition | `@if(!$isUsed)` wraps active link; `@else` shows disabled span with title "Cannot edit - being used" |
| 4 | Create paper that is used | Navigate to show page; Edit button appears disabled/grayed with tooltip |

#### TC-CR10: Controller — prepareForValidation Bool Casting

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperRequest.php | FormRequest class found |
| 2 | Inspect prepareForValidation() method | All boolean fields listed: is_proctored, is_ai_proctored, fullscreen_required, browser_lock_required, shuffle_questions, is_active, only_unused_questions, only_authorised_questions, ignore_difficulty_config, allow_calculator, show_marks_per_question, is_randomized, shuffle_options, timer_enforced, is_ques_wise_file_upload |
| 3 | Verify each uses `$this->boolean()` | Each line: `$this->merge(['field' => $this->boolean('field')])` |

#### TC-P01: Exam Paper List Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Navigate to Creation & Allocation tab, Exam Paper tab | Page loads at `/lms-exam/creation-allocation?active_tab=exam_paper` |
| 3 | Check search input | Search field with placeholder "Search paper code, title..." present |
| 4 | Check exam filter dropdown | Dropdown with list of active exams present |
| 5 | Check class filter dropdown | Dropdown with list of active classes |
| 6 | Check subject filter dropdown | Dropdown with list of active subjects |
| 7 | Check mode filter dropdown | Dropdown: All Modes, ONLINE, OFFLINE |
| 8 | Check "Add Exam Paper" button | Button visible (if create permission) |
| 9 | Check paper table | Columns: Code, Title, Exam, Class, Subject, Mode, Status, Actions |
| 10 | Check pagination | If 10+ papers exist, pagination links appear |

#### TC-P02: Filter Exam Papers By Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper under Exam A and Exam B | Both exist |
| 2 | Select Exam A from dropdown | Only Exam A papers shown |
| 3 | Clear filter | Both visible |

#### TC-P03: Filter Exam Papers By Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper for Class 10 and Class 9 | Both exist |
| 2 | Select Class 10 | Only Class 10 papers shown |

#### TC-P04: Filter Exam Papers By Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper for Math and Science | Both exist |
| 2 | Select Math | Only Math papers shown |

#### TC-P05: Filter Exam Papers By Mode

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create ONLINE and OFFLINE papers | Both exist |
| 2 | Select ONLINE | Only ONLINE papers shown |

#### TC-P06: Search Exam Papers By Paper Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with code "MATH_ON_001" | Paper exists |
| 2 | Search "MATH_ON" | Paper found |

#### TC-P07: Search Exam Papers By Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with title "Mathematics Online" | Paper exists |
| 2 | Search "Mathematics" | Paper found |

#### TC-P08: Search Exam Papers By Exam Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with title "Annual Exam 2026" and paper under it | Paper exists |
| 2 | Search "Annual Exam" | Paper found (matches on exam.title via relationship) |

#### TC-P09: Search Exam Papers By Subject Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper for subject "Physics" | Paper exists |
| 2 | Search "Physics" | Paper found (matches on subject.name via relationship) |

#### TC-P10: Filter By Active/Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active and inactive papers | Both exist |
| 2 | Select "Active" from filter | Only active papers shown |
| 3 | Select "Inactive" | Only inactive papers shown |

#### TC-P11: Create ONLINE Exam Paper With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Exam Paper tab | Page loads |
| 2 | Click "Add Exam Paper" | Create form opens |
| 3 | Select exam from dropdown | Exam selected |
| 4 | Select class from dropdown | Class selected |
| 5 | Select subject from dropdown | Subject selected |
| 6 | Enter paper_code: "ANNUAL_10_MATH_ON" | Code filled |
| 7 | Enter title: "Annual 2026 - Class 10 - Math - Online" | Title filled |
| 8 | Select mode: ONLINE | Mode selected |
| 9 | Enter total_marks: 100 | Marks filled |
| 10 | Enter passing_percentage: 35 | Pass % filled |
| 11 | Select status: NOT_STARTED | Status selected |
| 12 | Click "Create Exam Paper" | POST to `/lms-exam/exam-paper/store` |
| 13 | Check response | Success: "Exam paper created successfully." |
| 14 | DB check: `SELECT * FROM lms_exam_papers WHERE paper_code='ANNUAL_10_MATH_ON'` | Record exists with all required fields, is_active=1 |

#### TC-P12: Create OFFLINE Exam Paper With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill required fields (exam, class, subject, code, title, marks, pass%) | Fields set |
| 2 | Select mode: OFFLINE | Mode selected |
| 3 | Select offline_entry_mode: QUESTION_WISE | Entry mode selected |
| 4 | Click "Create Exam Paper" | Paper created |
| 5 | DB check | mode='OFFLINE', offline_entry_mode='QUESTION_WISE' |

#### TC-P13: Create ONLINE Paper With All Optional Flags

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create ONLINE paper | Mode selected |
| 2 | Set is_proctored = ON | Proctoring enabled |
| 3 | Set is_ai_proctored = ON | AI proctoring enabled |
| 4 | Set fullscreen_required = ON | Fullscreen enforced |
| 5 | Set browser_lock_required = ON | Browser locked |
| 6 | Set shuffle_questions = ON | Questions shuffled |
| 7 | Set allow_calculator = ON | Calculator allowed |
| 8 | Set show_marks_per_question = ON | Marks shown |
| 9 | Set is_randomized = ON | Randomized |
| 10 | Set shuffle_options = ON | Options shuffled |
| 11 | Set timer_enforced = ON | Timer enforced |
| 12 | Click "Create" | Paper created |
| 13 | DB check | All flag columns = 1 |

#### TC-P14: Create Paper With Difficulty Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper | Fields set |
| 2 | Select difficulty_config_id | Config selected |
| 3 | Set ignore_difficulty_config = OFF | Not ignored |
| 4 | Click "Create" | Paper created |
| 5 | DB check | difficulty_config_id set, ignore_difficulty_config=0 |

#### TC-P15: Create Paper With Question Source Settings

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set only_unused_questions = ON | Only unused questions |
| 2 | Set only_authorised_questions = ON | Only authorised |
| 3 | Click "Create" | Paper created |
| 4 | DB check | both columns = 1 |

#### TC-P16: Create Paper With Instructions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter instructions: "Read all questions carefully before answering." | Instructions filled |
| 2 | Click "Create" | Paper created |
| 3 | DB check | instructions saved correctly |

#### TC-P17: Create Paper With Duration And Total Questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter duration_minutes: 180 | Duration set |
| 2 | Enter total_questions: 50 | Question count set |
| 3 | Click "Create" | Paper created |
| 4 | DB check | duration_minutes=180, total_questions=50 |

#### TC-P18: Create Paper With Negative Marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter negative_marks: 0.50 | 0.5 marks deducted per wrong answer |
| 2 | Click "Create" | Paper created |
| 3 | DB check | negative_marks=0.50 |

#### TC-P19: Edit Exam Paper Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with all fields filled | Paper exists with ID=X |
| 2 | Click "Edit" button | Navigates to `/lms-exam/exam-paper/{X}/edit` |
| 3 | Verify form pre-filled | All fields match stored values |

#### TC-P20: Update Exam Paper Title And Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit paper, change title and paper_code | Fields updated |
| 2 | Click "Update" | Update succeeds |
| 3 | DB check | title and paper_code updated |

#### TC-P21: Update Exam Paper Mode From ONLINE To OFFLINE

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit ONLINE paper | Form pre-filled |
| 2 | Change mode to OFFLINE | offline_entry_mode field appears (required_if) |
| 3 | Select offline_entry_mode | Entry mode selected |
| 4 | Click "Update" | Update succeeds |
| 5 | DB check | mode='OFFLINE', offline_entry_mode set |

#### TC-P22: Update Exam Paper Total Marks And Passing Percentage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Change total_marks from 100 to 80 | Marks updated |
| 2 | Change passing_percentage from 35 to 40 | % updated |
| 3 | Click "Update" | Update succeeds |
| 4 | DB check | total_marks=80.00, passing_percentage=40.00 |

#### TC-P23: Update Exam Paper Toggle Online Flags

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle is_proctored from ON to OFF | Flag changed |
| 2 | Toggle shuffle_questions from OFF to ON | Flag changed |
| 3 | Click "Update" | Update succeeds |
| 4 | DB check | is_proctored=0, shuffle_questions=1 |

#### TC-P24: Update Exam Paper Change Difficulty Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Change difficulty_config_id | Config changed |
| 2 | Click "Update" | Update succeeds |
| 3 | DB check | difficulty_config_id updated |

#### TC-P25: View Exam Paper Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with all fields | Paper exists |
| 2 | Click "View" button | Navigates to show page |
| 3 | Check exam name displayed | Parent exam shown |
| 4 | Check class and subject | Correct names |
| 5 | Check mode badge | ONLINE/OFFLINE badge |
| 6 | Check total_marks and passing_percentage | Displayed |
| 7 | Check duration and questions | Displayed if set |
| 8 | Check all flags | Displayed as ON/OFF |
| 9 | Check instructions | Displayed if set |
| 10 | Check status badge | Color-coded status |
| 11 | Check usage info | If in use, shows breakdown |

#### TC-P26: Soft Delete Unused Exam Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with no allocations/sets/attempts | Paper exists |
| 2 | Click delete button | SweetAlert confirmation |
| 3 | Confirm delete | DELETE sent |
| 4 | Check toast | "Exam paper trashed successfully" |
| 5 | DB check | is_active=0, deleted_at NOT NULL |

#### TC-P27: Trash Page Shows Deleted Exam Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete 2 papers | Both trashed |
| 2 | Click "Trash" button | Navigates to trash view |
| 3 | Check table lists only trashed papers | Both visible with Restore and Force Delete |

#### TC-P28: Restore Exam Paper From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Restore" on trashed paper | Restore POST sent |
| 2 | Check toast | "Exam paper restored successfully" |
| 3 | DB check | deleted_at=NULL, is_active=1 |

#### TC-P29: Force Delete Unused Exam Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Delete Forever" on trashed paper | SweetAlert confirmation |
| 2 | Confirm | forceDelete executed |
| 3 | DB check | Record permanently removed |

#### TC-P30: Toggle Status Active To Inactive (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click status toggle on active paper | AJAX POST with is_active=0 |
| 2 | Check response | `{success: true, is_active: false}` |
| 3 | DB check | is_active=0 |

#### TC-P31: Toggle Status Inactive To Active (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click status toggle on inactive paper | AJAX POST with is_active=1 |
| 2 | Check response | `{success: true, is_active: true}` |
| 3 | DB check | is_active=1 |

#### TC-P32 to TC-P38: Activity Log and Full Lifecycle

(Follow same pattern as Exam Creation — verify each activity event type logged correctly after each CRUD operation)

#### TC-N01: Required — Missing exam_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all fields EXCEPT exam_id | Leave exam empty |
| 2 | Submit | Error: "Exam is required" |

#### TC-N10: Required — Missing offline_entry_mode When Mode=OFFLINE

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select mode=OFFLINE | offline_entry_mode required |
| 2 | Leave offline_entry_mode empty | Field empty |
| 3 | Submit | Error: "Entry mode is required for offline exams" |

#### TC-N11: Duplicate Paper Code Within Same Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with paper_code="DUP001" in Exam A | Paper exists |
| 2 | Try to create another paper with same code in Exam A | Validation error: "This paper code already exists for this exam" |
| 3 | Create same code in Exam B | Allowed (unique per exam) |

#### TC-N27: Edit Blocked — Paper Has Allocations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with allocations | Paper in use |
| 2 | Click Edit | UsageCheck returns true |
| 3 | Error shown | "Cannot edit this exam paper because it is allocated or has student attempts." |

#### TC-N44: OFFLINE Mode Without offline_entry_mode

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select mode=OFFLINE | offline_entry_mode field is required |
| 2 | Leave empty, submit | Validation error: "Entry mode is required for offline exams" |

#### TC-D15: Unique Composite Constraint — uq_exam_paper_code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert duplicate (exam_id, paper_code) directly in DB | Integrity constraint violation 1062 |

#### TC-D16: ENUM Validation — mode Column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert paper with mode='HYBRID' directly in DB | DB error: Invalid ENUM value |

#### TC-D40: Paper Sets FK CASCADE

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with 2 paper sets | Paper and sets exist |
| 2 | Delete paper | DDL CASCADE deletes both sets automatically |

#### TC-D44: Only PAPER Type Statuses Shown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create/edit paper form | Status dropdown only shows statuses with event_type='PAPER' |
| 2 | Verify EXAM type statuses (DRAFT, PUBLISHED) NOT shown | Only NOT_STARTED, IN_PROGRESS, SUBMITTED, EVALUATION_PENDING, EVALUATED, RESULT_PUBLISHED, ABSENT, CANCELLED shown |

#### TC-D45: Blade @can Directives — Paper CRUD Buttons Visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open exam-paper/index.blade.php | View file found in lmsexam::exam-paper/ |
| 2 | Find Add Exam Paper button | Wrapped in @can('tenant.exam-paper.create') |
| 3 | Find Edit button in action column | Wrapped in @can('tenant.exam-paper.edit') |
| 4 | Find Delete button | Wrapped in @can('tenant.exam-paper.delete') |
| 5 | Find View button | Wrapped in @can('tenant.exam-paper.view') |
| 6 | Find Status toggle | Wrapped in @can('tenant.exam-paper.status') |
| 7 | Open trash.blade.php | Restore wrapped in @can('tenant.exam-paper.restore'); ForceDelete in @can('tenant.exam-paper.forceDelete') |

#### TC-D46: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open exam-paper/index.blade.php | View file found in lmsexam::exam-paper/ |
| 2 | Scan for `$paper->exam->title` patterns | All use optional() or ?-> null-safe operator |
| 3 | Scan for `$paper->class->name` patterns | Protected with isset/optional |
| 4 | Load page when paper has null exam (orphaned) | No 500 error; null displayed gracefully |

#### TC-D47: Controller — JSON Response After ToggleStatus

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperController.php | Controller found |
| 2 | Inspect toggleStatus() method | Returns `response()->json([...])` |
| 3 | Verify JSON structure on success | `{success: true, is_active: bool, message: string}` |
| 4 | Verify JSON structure on failure | `{success: false, message: string}` |
| 5 | Verify HTTP status codes | 200 on success, 500 on exception |

#### TC-D48: FormRequest authorize() Gates Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperRequest.php | FormRequest found |
| 2 | Inspect authorize() method | POST → Gate::allows('tenant.exam-paper.create') |
| 3 | PUT/PATCH → Gate::allows('tenant.exam-paper.update') | Correct gate mapped |
| 4 | DELETE → Gate::allows('tenant.exam-paper.delete') | Correct gate mapped |
| 5 | Default returns Gate::allows('tenant.exam-paper.view') | Fallback gate |

#### TC-D49: Controller — Usage Check Before Destructive Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperController.php | Controller found |
| 2 | Verify edit() calls isUsed | `$usageCheck->isUsed($id)` before proceeding |
| 3 | Verify update() calls isUsed | Usage check at top of method |
| 4 | Verify destroy() calls isUsed | Usage check before findOrFail |
| 5 | Verify restore() calls isUsed | Usage check before onlyTrashed find |
| 6 | Verify forceDelete() calls isUsed | Usage check before forceDelete |
| 7 | Verify toggleStatus() does NOT check usage | No isUsed call before status update |

#### TC-D50: Controller — try-catch Exception Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperController.php | Controller found |
| 2 | Inspect store() | try { DB::beginTransaction ... create ... commit } catch(\Exception) { rollback; back with error } |
| 3 | Inspect update() | try-catch present; rollback on failure |
| 4 | Inspect destroy() | try-catch present; rollback on failure |
| 5 | Inspect restore() | try-catch present; rollback on failure |
| 6 | Inspect forceDelete() | try-catch present; rollback on failure |
| 7 | Inspect toggleStatus() | try-catch present; rollback + JSON error on failure |

#### TC-D51: Extended — ExamPaper Model $casts Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaper.php model | Model in Modules/LmsExam/Models/ |
| 2 | Inspect $casts property | All boolean fields listed with 'boolean' cast |
| 3 | Verify decimal casts | total_marks => 'decimal:2', passing_percentage => 'decimal:2', negative_marks => 'decimal:2' |
| 4 | Verify integer casts | total_questions => 'integer', duration_minutes => 'integer' |
| 5 | Verify datetime casts | created_at, updated_at, deleted_at => 'datetime' |

#### TC-D52: Extended — ExamPaper belongsTo Relationships Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaper.php model | Model found |
| 2 | Inspect exam() relation | `$this->belongsTo(Exam::class, 'exam_id')` |
| 3 | Inspect class() relation | `$this->belongsTo(SchoolClass::class, 'class_id')` |
| 4 | Inspect subject() relation | `$this->belongsTo(Subject::class, 'subject_id')` |
| 5 | Inspect status() relation | `$this->belongsTo(ExamStatusEvent::class, 'status_id')` |
| 6 | Inspect difficultyConfig() relation | `$this->belongsTo(DifficultyDistributionConfig::class, 'difficulty_config_id')` |

#### TC-D53: Extended — ExamPaper hasMany Relationships Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaper.php model | Model found |
| 2 | Inspect examScopes() | `$this->hasMany(ExamScope::class, 'exam_paper_id')` |
| 3 | Inspect examBlueprints() | `$this->hasMany(ExamBlueprint::class, 'exam_paper_id')` |
| 4 | Inspect allocations() | `$this->hasMany(ExamAllocation::class, 'exam_paper_id')` |
| 5 | Inspect attempts() | `$this->hasMany(ExamAttempt::class, 'exam_paper_id')` |
| 6 | Inspect results() | `$this->hasMany(ExamResult::class, 'exam_paper_id')` |
| 7 | Inspect paperSets() | `$this->hasMany(ExamPaperSet::class, 'exam_paper_id')` |

#### TC-D54: Extended — ExamPaperRequest Field Length Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperRequest.php | Request found |
| 2 | Check paper_code max | rules['paper_code'] includes 'max:50' |
| 3 | Check title max | rules['title'] includes 'max:150' |
| 4 | Check duration_minutes min/max | 'min:1|max:1440' |
| 5 | Check total_marks min/max | 'min:0|max:999999.99' |
| 6 | Check passing_percentage min/max | 'min:0|max:100' |

#### TC-D55: Extended — ExamPaperRequest Custom Messages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperRequest.php messages() method | Custom messages defined |
| 2 | Verify exam_id.required | "Exam is required" |
| 3 | Verify paper_code.unique | "This paper code already exists for this exam" |
| 4 | Verify offline_entry_mode.required_if | "Entry mode is required for offline exams" |
| 5 | Verify mode.required | "Exam mode is required" |

#### TC-D56: Extended — prepareForValidation All Boolean Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperRequest.php | Request found |
| 2 | Count boolean merges in prepareForValidation | 15 boolean fields cast |
| 3 | List all: is_proctored, is_ai_proctored, fullscreen_required, browser_lock_required, shuffle_questions, is_active, only_unused_questions, only_authorised_questions, ignore_difficulty_config, allow_calculator, show_marks_per_question, is_randomized, shuffle_options, timer_enforced, is_ques_wise_file_upload | All present |

#### TC-D57: Extended — toggleStatus Validates Request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperController.php toggleStatus() | Method found |
| 2 | Inspect validation | `$request->validate(['is_active' => 'required|boolean'])` |
| 3 | Verify DB transaction used | DB::beginTransaction before save; commit/rollback after |
| 4 | Verify activityLog called | activityLog($examPaper, 'Toggled', [...]) |

#### TC-D58: Extended — Index View Columns Displayed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open exam-paper/index.blade.php | View found |
| 2 | Check table headers | Columns: Paper Code, Title, Exam, Class, Subject, Mode, Status, Actions |
| 3 | Check action buttons | View, Edit, Delete, Toggle Status per row |
| 4 | Check search bar filters | Exam dropdown, search input |

#### TC-D59: Extended — Create View Form Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open exam-paper/create.blade.php | View found |
| 2 | Check form fields present | exam_id, class_id, subject_id, paper_code, title, mode, total_marks, passing_percentage, duration_minutes, total_questions, negative_marks, instructions, all boolean toggles, offline_entry_mode, difficulty_config_id, status_id, is_active |
| 3 | Check mode toggle shows/hides fields | OFFLINE shows offline_entry_mode; ONLINE shows proctoring flags |

#### TC-D60: Extended — Show View Displays All Paper Settings

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open exam-paper/show.blade.php | View found |
| 2 | Check basic info section | Exam, Class, Subject, Code, Title displayed |
| 3 | Check mode-specific section | ONLINE: proctoring/randomization flags; OFFLINE: entry mode |
| 4 | Check marks section | Total marks, passing percentage, negative marks |
| 5 | Check timing section | Duration, total questions |
| 6 | Check instructions | Full text displayed |
| 7 | Check usage section | If used, shows allocations/sets/blueprints counts |
