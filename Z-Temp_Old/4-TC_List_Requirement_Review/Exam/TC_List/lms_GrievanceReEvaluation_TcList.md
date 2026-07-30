# lms_GrievanceReEvaluation_TcList

## Module: LmsExam → Exam Management → Grievance & Re-Evaluation

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Exam Management → Re-Evaluation |
| Feature | Grievance & Re-Evaluation Review |
| URL(s) | `GET /exam/master?active_tab=re_evaluation` (index via tab), `GET /exam/exam-grievances` (standalone index), `GET /exam/exam-grievances/{id}` (show), `POST /exam/exam-grievances/store` (store), `PATCH /exam/exam-grievances/{id}/resolve` (resolve), `POST /exam/exam-grievances/{id}/toggle-status` (toggleStatus) |
| Controller | `Modules\LmsExam\Http\Controllers\GrievanceReviewController` |
| Model(s) | `Modules\StudentPortal\Models\ExamGrievance` (table: `lms_exam_grievances`) |
| Supporting Models | `Modules\StudentPortal\Models\ExamResult`, `Modules\LmsExam\Models\Exam`, `Modules\LmsExam\Services\ResultComputationService` |
| Validation | `Modules\LmsExam\Http\Requests\GrievanceRequest` |
| Permissions | `tenant.re-evaluation-requests.viewAny` (index), `tenant.re-evaluation-requests.view` (show), `tenant.re-evaluation-requests.create` (store), `tenant.re-evaluation-requests.update` (resolve, toggleStatus) |
| View Paths | `resources/views/exam-grievances/index.blade.php`, `resources/views/exam-grievances/show.blade.php`, `resources/views/exam-grievances/partial_list.blade.php` |
| Pagination | 20 records per page |
| Statuses | OPEN → UNDER_REVIEW → RESOLVED or REJECTED |
| Grievance Types | MARKING_ERROR, QUESTION_ERROR, OUT_OF_SYLLABUS, OTHER |
| Mark Revision | Uses `ResultComputationService::computePercentage()`, `calculateGrade()`, `determineResultStatus()`, `recomputeRank()` |
| Activity Log | Logged on every status update with message "Grievance #[id] status set to [status]." |
| DB Transactions | `resolve()` wrapped in `DB::beginTransaction/commit/rollback` |

---

## 2. Pre-conditions

- Required permissions: `tenant.re-evaluation-requests.viewAny`, `tenant.re-evaluation-requests.view`, `tenant.re-evaluation-requests.create`, `tenant.re-evaluation-requests.update`
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- At least one exam with `exam_result` record must exist
- At least one student with a published exam result must exist
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For mark revision tests: Student must have a result with `total_marks_obtained` and `total_marks_possible` set
- For student portal grievance flow: Student must be logged in via Student Portal

---

## 3. Default Data Load

When the page loads via `GrievanceReviewController@index()`, the following data is fetched:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Grievances List | `ExamGrievance::with(student, examResult.exam, examPaper)` | Ordered by FIELD(status, 'OPEN', 'UNDER_REVIEW', 'RESOLVED', 'REJECTED') | status, grievance_type, exam_id, search | 20/page |
| Status Counts (4 cards) | `ExamGrievance::where('status', X)->count()` | 4 separate count queries | None | None |
| Exam List (filter dropdown) | `Exam::where('is_active', true)->orderBy('title')` | All active exams | is_active | None |
| Classes (partial_list) | `SchoolClass::where('is_active',1)` | Active classes | is_active | None |
| Sections | Dynamic via AJAX `get-sections-by-class` | Based on selected class | class_id | None |
| Students | Dynamic via AJAX `student-search` | Based on class/section | class_id, section_id | None |

## 4. Test Data Strategy

- **Grievance records**: Create `ExamGrievance` records directly in DB for pre-configured state tests
- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Status priority**: OPEN → UNDER_REVIEW → RESOLVED → REJECTED sorting order
- **Pre-test cleanup**: Delete created grievances by known IDs before/after tests to avoid collisions
- **Mark revision**: Test with decimal marks (0.5 increments), integer marks, and zero marks
- **Result computation**: Verify percentage, grade, result_status recomputation on mark change
- **Rank recomputation**: Verify `recomputeRank()` is called when marks change
- **Activity logging**: Each resolve action must produce an activity log entry
- **Toggle active**: `is_active` boolean toggle via AJAX POST
- **Manual creation**: Required fields: student_id, exam_paper_id, grievance_type, grievance_text

---

## 5. Business Conditions

### 4.1 Database Schema — `lms_exam_grievances`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | exam_result_id | INT FK | FK → `lms_exam_results.id` |
| BC-DB-03 | student_id | INT FK | FK → `std_students.id` |
| BC-DB-04 | exam_paper_id | INT FK | FK → `lms_exam_papers.id` |
| BC-DB-05 | grievance_type | ENUM | MARKING_ERROR, QUESTION_ERROR, OUT_OF_SYLLABUS, OTHER |
| BC-DB-06 | grievance_text | TEXT | The student's grievance description |
| BC-DB-07 | status | ENUM | OPEN, UNDER_REVIEW, RESOLVED, REJECTED |
| BC-DB-08 | reviewer_id | INT FK NULL | FK → `sys_users.id` |
| BC-DB-09 | resolution_remarks | TEXT NULL | Reviewer's remarks |
| BC-DB-10 | resolved_at | DATETIME NULL | When resolved |
| BC-DB-11 | marks_changed | TINYINT(1) | Whether marks were revised |
| BC-DB-12 | old_marks | DECIMAL(10,2) NULL | Marks before revision |
| BC-DB-13 | new_marks | DECIMAL(10,2) NULL | Marks after revision |
| BC-DB-14 | is_active | TINYINT(1) | DEFAULT 1, controls visibility |
| BC-DB-15 | created_by | INT FK NULL | FK → `sys_users.id` |
| BC-DB-16 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-17 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

### 4.2 Validation Rules — `GrievanceRequest`

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | student_id | required, integer, exists:std_students,id | — |
| BC-VAL-02 | exam_paper_id | required, integer, exists:lms_exam_papers,id | — |
| BC-VAL-03 | exam_result_id | nullable, integer, exists:lms_exam_results,id | — |
| BC-VAL-04 | grievance_type | required, string, in:MARKING_ERROR,QUESTION_ERROR,OUT_OF_SYLLABUS,OTHER | — |
| BC-VAL-05 | grievance_text | required, string, max:5000 | — |
| BC-VAL-06 | status (resolve) | required, string, in:OPEN,UNDER_REVIEW,RESOLVED,REJECTED | — |
| BC-VAL-07 | new_marks (resolve) | nullable, numeric, min:0 | — |
| BC-VAL-08 | resolution_remarks | nullable, string, max:2000 | — |
| BC-VAL-09 | Resolution remarks required | required_if:status,RESOLVED,REJECTED | "Resolution remarks are required when resolving or rejecting." |

### 4.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.re-evaluation-requests.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.re-evaluation-requests.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.re-evaluation-requests.create | store() | Without → 403 |
| BC-AUTH-04 | tenant.re-evaluation-requests.update | resolve(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | Guest access | Any grievance route | Redirect to /login |

### 4.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Index loads | 4 stat cards (Open, Under Review, Resolved, Rejected) with counts |
| BC-BIZ-02 | Filter by status | Only grievances matching the selected status shown |
| BC-BIZ-03 | Filter by grievance type | Only matching grievance type shown |
| BC-BIZ-04 | Filter by exam | Only grievances for the selected exam shown |
| BC-BIZ-05 | Search by student name | Matches student full_name using LIKE |
| BC-BIZ-06 | Search by grievance text | Matches grievance_text using LIKE |
| BC-BIZ-07 | Status priority sorting | OPEN first, then UNDER_REVIEW, RESOLVED, REJECTED |
| BC-BIZ-08 | Show grievance details | Student, exam, paper, marks, percentage, result status displayed |
| BC-BIZ-09 | Review action panel | Only visible when status is OPEN or UNDER_REVIEW |
| BC-BIZ-10 | Change to UNDER_REVIEW | Status updated, reviewer_id set |
| BC-BIZ-11 | Resolve without mark change | Status=RESOLVED, resolved_at set, marks_changed=false |
| BC-BIZ-12 | Resolve with mark change | New marks saved, percentage/grade/status recomputed, rank recomputed, marks_changed=true |
| BC-BIZ-13 | Reject grievance | Status=REJECTED, resolution_remarks saved, resolved_at set |
| BC-BIZ-14 | Toggle active status | is_active flips, AJAX returns new state |
| BC-BIZ-15 | Manual grievance creation | New record with status=OPEN, created_by set to auth user |
| BC-BIZ-16 | Auto-find exam_result | If exam_result_id not provided, found by student_id + exam_paper_id |
| BC-BIZ-17 | No result found error | "No result found for this student and paper." returned |
| BC-BIZ-18 | Marks revised badge | In list view, shows "Marks Revised" badge when marks_changed=true |
| BC-BIZ-19 | Activity log on resolve | "Grievance #[id] status set to [status]." logged |
| BC-BIZ-20 | Old marks displayed | In show view, marks revised badge shows old → new marks |
| BC-BIZ-21 | Resolved grievance cannot be edited | Review action panel shows locked message |
| BC-BIZ-22 | Rejected grievance cannot be edited | Review action panel shows locked message |
| BC-BIZ-23 | Empty state (no grievances) | "No grievances found" message displayed |
| BC-BIZ-24 | Pagination preserves filters | Filter values persisted in pagination links |
| BC-BIZ-25 | Grievance text truncated in list | Limited to 80 characters |
| BC-BIZ-26 | Client-side marks block toggle | "Revised Marks" input shown only when RESOLVED selected |
| BC-BIZ-27 | Remarks required client-side | Remarks marked required when RESOLVED or REJECTED |
| BC-BIZ-28 | DB transaction rollback on error | If resolve fails, all changes rolled back |
| BC-BIZ-29 | Mark revision computes passing percentage | Uses paper's passing_percentage or default 33% |
| BC-BIZ-30 | Mark revision boundary: exactly passing | Percentage exactly at passing threshold results in PASS |

### 4.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | exam_result_id | lms_exam_results (id) | CASCADE |
| BC-REF-02 | student_id | std_students (id) | CASCADE |
| BC-REF-03 | exam_paper_id | lms_exam_papers (id) | CASCADE |
| BC-REF-04 | reviewer_id | sys_users (id) | SET NULL |
| BC-REF-05 | created_by | sys_users (id) | SET NULL |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Grievance Index Page Loads With All UI Elements | Page loads with 4 stat cards, search/filter form, table, pagination | — | — | ⬜ |
| TC-P02 | 4 Stat Cards Show Correct Counts | Open, Under Review, Resolved, Rejected counts displayed in gradient cards | — | — | ⬜ |
| TC-P03 | Stat Card Colors And Icons Match Status | Red/Orange for Open, Yellow for Under Review, Green for Resolved, Gray for Rejected | — | — | ⬜ |
| TC-P04 | Filter By Status — Open | Only OPEN status grievances displayed | — | — | ⬜ |
| TC-P05 | Filter By Status — Under Review | Only UNDER_REVIEW status grievances displayed | — | — | ⬜ |
| TC-P06 | Filter By Status — Resolved | Only RESOLVED status grievances displayed | — | — | ⬜ |
| TC-P07 | Filter By Status — Rejected | Only REJECTED status grievances displayed | — | — | ⬜ |
| TC-P08 | Filter By Grievance Type — Marking Error | Only MARKING_ERROR type grievances displayed | — | — | ⬜ |
| TC-P09 | Filter By Grievance Type — Question Error | Only QUESTION_ERROR type grievances displayed | — | — | ⬜ |
| TC-P10 | Filter By Grievance Type — Out Of Syllabus | Only OUT_OF_SYLLABUS type grievances displayed | — | — | ⬜ |
| TC-P11 | Filter By Grievance Type — Other | Only OTHER type grievances displayed | — | — | ⬜ |
| TC-P12 | Filter By Exam | Only grievances belonging to selected exam displayed | — | — | ⬜ |
| TC-P13 | Search By Student Name (Exact) | Grievances for that student displayed | — | — | ⬜ |
| TC-P14 | Search By Student Name (Partial) | Grievances for students with matching partial name displayed | — | — | ⬜ |
| TC-P15 | Search By Grievance Text | Grievances containing search term in grievance_text displayed | — | — | ⬜ |
| TC-P16 | Clear All Filters | Reset button clears all filters, shows all grievances | — | — | ⬜ |
| TC-P17 | Status Priority Sorting - Single Page | OPEN records appear before UNDER_REVIEW before RESOLVED before REJECTED | — | — | ⬜ |
| TC-P18 | All Fields Visible In Table Row | Student name+ID, Exam/Paper, Type badge, Grievance text (truncated), Status badge, Filed date, Active toggle, Action eye button | — | — | ⬜ |
| TC-P19 | Show Grievance Detail Page Loads | All grievance information displayed: header card, student context, exam result, type, text, resolution | — | — | ⬜ |
| TC-P20 | Show Page — Status Color-Coded Header Card | Card has left border matching status color | — | — | ⬜ |
| TC-P21 | Show Page — Student Information | Student full name and ID displayed | — | — | ⬜ |
| TC-P22 | Show Page — Exam And Paper Context | Exam title and paper title displayed | — | — | ⬜ |
| TC-P23 | Show Page — Marks Obtained And Percentage | Current marks, total marks, percentage, result status (PASS/FAIL) displayed | — | — | ⬜ |
| TC-P24 | Show Page — Grievance Type Badge | Type displayed as badge (Marking Error, Question Error, Out of Syllabus, Other) | — | — | ⬜ |
| TC-P25 | Show Page — Full Grievance Text | Complete grievance text displayed in yellow-highlighted box | — | — | ⬜ |
| TC-P26 | Show Page — Review Action Panel Visible (OPEN) | Status dropdown, Revised Marks block, Remarks textarea, Save button visible | — | — | ⬜ |
| TC-P27 | Show Page — Review Action Panel Visible (UNDER_REVIEW) | Same panel visible as OPEN status | — | — | ⬜ |
| TC-P28 | Show Page — Review Action Panel Hidden (RESOLVED) | Lock icon with "cannot be edited" message displayed | — | — | ⬜ |
| TC-P29 | Show Page — Review Action Panel Hidden (REJECTED) | Lock icon with "cannot be edited" message displayed | — | — | ⬜ |
| TC-P30 | Show Page — Existing Resolution Displayed | Resolution remarks and reviewer name shown when already resolved | — | — | ⬜ |
| TC-P31 | Show Page — Marks Revised Badge | If marks_changed=true, "Marks Revised: old → new" badge shown in header | — | — | ⬜ |
| TC-P32 | Change Status To Under Review | Status updated from OPEN to UNDER_REVIEW, reviewer_id set | — | — | ⬜ |
| TC-P33 | Resolve Grievance Without Mark Change | Status=RESOLVED, resolved_at set, marks_changed=false | — | — | ⬜ |
| TC-P34 | Resolve Grievance With Mark Increase | Marks updated in exam_results, percentage recalculated, grade updated | — | — | ⬜ |
| TC-P35 | Resolve Grievance With Mark Decrease | Marks updated downward, percentage recalculated, grade may change | — | — | ⬜ |
| TC-P36 | Resolve Grievance — Result Status Changes PASS TO FAIL | Mark change causes result_status to flip from PASS to FAIL | — | — | ⬜ |
| TC-P37 | Resolve Grievance — Result Status Changes FAIL TO PASS | Mark change causes result_status to flip from FAIL to PASS | — | — | ⬜ |
| TC-P38 | Resolve Grievance — Rank Recalculated | `recomputeRank()` called after mark change | — | — | ⬜ |
| TC-P39 | Resolve Grievance — Same Marks No Change | new_marks equals old_marks → marks_changed=false, no rank recomputation | — | — | ⬜ |
| TC-P40 | Reject Grievance With Remarks | Status=REJECTED, resolution_remarks saved, resolved_at set | — | — | ⬜ |
| TC-P41 | Toggle Active Status ON → OFF | is_active flips to 0, AJAX success response | — | — | ⬜ |
| TC-P42 | Toggle Active Status OFF → ON | is_active flips to 1, AJAX success response | — | — | ⬜ |
| TC-P43 | Manual Grievance Creation (All Fields) | New grievance created with status=OPEN | — | — | ⬜ |
| TC-P44 | Manual Grievance — Auto-Find Exam Result | exam_result_id not provided → auto-found from student+paper | — | — | ⬜ |
| TC-P45 | Pagination Works (20 Records) | Page 2 shows records 21-40, next/previous links functional | — | — | ⬜ |
| TC-P46 | Pagination Preserves Filter State | Filters persist across page navigation | — | — | ⬜ |
| TC-P47 | Empty State — No Grievances Found | Table shows "No grievances found" with icon | — | — | ⬜ |
| TC-P48 | Full Grievance Lifecycle: Create → Open → Under Review → Resolved | All transitions succeed; activity logged at each step | — | — | ⬜ |
| TC-P49 | Full Grievance Lifecycle: Create → Open → Rejected | Create → review → reject flow works | — | — | ⬜ |
| TC-P50 | Show Page — Related Question Display | If question_id present, question content shown in grievance details | — | — | ⬜ |
| TC-P51 | Client-Side — Revised Marks Block Shown On RESOLVED Select | When status changed to RESOLVED, marks input appears | — | — | ⬜ |
| TC-P52 | Client-Side — Revised Marks Block Hidden On REJECTED Select | When status changed to REJECTED, marks input hidden | — | — | ⬜ |
| TC-P53 | Client-Side — Remarks Required When Resolved/Rejected | Remarks textarea marked as required dynamically | — | — | ⬜ |
| TC-P54 | Client-Side — New Marks Validated Within Range | Max marks constraint from total_marks_possible | — | — | ⬜ |
| TC-P55 | Show Page — Filed On Displayed | created_at shown as "Filed X ago • d M Y, h:i A" | — | — | ⬜ |
| TC-P56 | Show Page — Resolved On Displayed | resolved_at shown as "Resolved by X on d M Y, h:i A" | — | — | ⬜ |
| TC-P57 | Multi-Filter Combination: Status + Type + Exam | All three filters applied together, only matching results shown | — | — | ⬜ |
| TC-P58 | Multi-Filter Combination: Search + Status | Search term AND status filter applied together | — | — | ⬜ |
| TC-P59 | Resolve Grievance With Decimal Marks (0.5) | new_marks=8.5 accepted, stored as DECIMAL(10,2) | — | — | ⬜ |
| TC-P60 | Resolve Grievance With Zero Marks | new_marks=0 accepted, percentage=0% computed | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Index Without Permission (No viewAny) | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N02 | Show Without Permission (No view) | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N03 | Store Without Permission (No create) | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N04 | Resolve Without Permission (No update) | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N05 | ToggleStatus Without Permission (No update) | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N06 | Guest Access Redirect | Redirected to /login for all grievance routes | — | — | ⬜ |
| TC-N07 | Show With Invalid Grievance ID (404) | HTTP 404 — Model not found | — | — | ⬜ |
| TC-N08 | Resolve With Invalid Grievance ID (404) | HTTP 404 — Model not found | — | — | ⬜ |
| TC-N09 | Toggle Status With Invalid Grievance ID (404) | HTTP 404 — Model not found | — | — | ⬜ |
| TC-N10 | Store — Missing student_id | Validation error: "The student id field is required." | — | — | ⬜ |
| TC-N11 | Store — Missing exam_paper_id | Validation error: "The exam paper id field is required." | — | — | ⬜ |
| TC-N12 | Store — Missing grievance_type | Validation error: "The grievance type field is required." | — | — | ⬜ |
| TC-N13 | Store — Invalid grievance_type | Validation error: "The selected grievance type is invalid." | — | — | ⬜ |
| TC-N14 | Store — Missing grievance_text | Validation error: "The grievance text field is required." | — | — | ⬜ |
| TC-N15 | Store — grievance_text Exceeds 5000 Characters | Validation error: max exceeded | — | — | ⬜ |
| TC-N16 | Store — Invalid student_id (Non-Existent) | Validation error: "The selected student id is invalid." | — | — | ⬜ |
| TC-N17 | Store — Invalid exam_paper_id (Non-Existent) | Validation error: "The selected exam paper id is invalid." | — | — | ⬜ |
| TC-N18 | Store — No Result Found For Student And Paper | Error message: "No result found for this student and paper." | — | — | ⬜ |
| TC-N19 | Resolve — Missing status field | Validation error: "The status field is required." | — | — | ⬜ |
| TC-N20 | Resolve — Invalid status value | Validation error: "The selected status is invalid." | — | — | ⬜ |
| TC-N21 | Resolve — Negative New Marks | Validation error: "The new marks must be at least 0." | — | — | ⬜ |
| TC-N22 | Resolve — New Marks Exceeds Max Possible | new_marks > total_marks_possible → no client validation, but should be handled | — | — | ⬜ |
| TC-N23 | Resolve — Missing Resolution Remarks For RESOLVED | Validation error: "Resolution remarks are required when resolving or rejecting." | — | — | ⬜ |
| TC-N24 | Resolve — Missing Resolution Remarks For REJECTED | Validation error: "Resolution remarks are required when resolving or rejecting." | — | — | ⬜ |
| TC-N25 | XSS In grievance_text | Stored as literal string; Blade `{{ }}` escapes output; no script execution | — | — | ⬜ |
| TC-N26 | XSS In resolution_remarks | Stored as literal string; escaped by Blade | — | — | ⬜ |
| TC-N27 | Whitespace-Only grievance_text | Required validation catches empty/whitespace-only strings | — | — | ⬜ |
| TC-N28 | Whitespace-Only resolution_remarks | Required_if validation catches empty/whitespace-only when required | — | — | ⬜ |
| TC-N29 | Store — Empty String In All Fields | Required validations fail for all empty fields | — | — | ⬜ |
| TC-N30 | Resolve — DB Transaction Rollback On Exception | If mark update fails, grievance status not changed | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Resolve → Mark Update → exam_results Updated | New marks, percentage, grade_obtained, result_status saved in lms_exam_results | — | — | ⬜ |
| TC-D02 | B | Resolve → Mark Update → Rank Recalculated | ResultComputationService::recomputeRank() called with exam_id, exam_paper_id | — | — | ⬜ |
| TC-D03 | C | Mark Revision → Result Status Recalculated | If marks cross passing threshold, result_status flips | — | — | ⬜ |
| TC-D04 | D | Mark Revision → Grade Recalculated | Grade computed based on new percentage | — | — | ⬜ |
| TC-D05 | E | Activity Log Created On Resolve | activity_logs table has entry "Grievance #[id] status set to [status]." | — | — | ⬜ |
| TC-D06 | F | Toggle Active → Grievance Hidden From Student Portal | When is_active=0, student cannot see grievance in My Grievances | — | — | ⬜ |
| TC-D07 | G | Student Portal → File Grievance → Appears In Admin List | Student files grievance → teacher sees it in review list | — | — | ⬜ |
| TC-D08 | H | Student Cannot File Duplicate Grievance For Same Result | Duplicate check in StudentGrievanceController prevents 2nd filing | — | — | ⬜ |
| TC-D09 | I | Auto-Find Exam Result — Student+Paper Must Match | If student has multiple results, correct one selected by (student_id, exam_paper_id) | — | — | ⬜ |
| TC-D10 | J | Static Badge Display — Marks Revised | In list view, marks_changed=true shows "Marks Revised" badge below status | — | — | ⬜ |
| TC-D11 | K | Static Badge Display — Old → New Marks | In show view header, "Marks Revised: 15 → 18" displayed | — | — | ⬜ |
| TC-D12 | L | Integration — P1 — Controller — DB::transaction in resolve() | GrievanceReviewController@resolve() uses DB::beginTransaction/commit/rollback; on exception, all changes revert | — | — | ⬜ |
| TC-D13 | M | Integration — P1 — Controller — findOrFail in show/resolve/toggleStatus | Valid IDs load model; invalid (non-existent) IDs throw ModelNotFoundException → HTTP 404 | — | — | ⬜ |
| TC-D14 | N | Integration — P1 — Controller — Gate::authorize() Before All Actions | Each controller method calls Gate::authorize('tenant.re-evaluation-requests.*') before any business logic | — | — | ⬜ |
| TC-D15 | O | Unit — P1 — ExamGrievance Model — $casts Verification | `marks_changed` cast to boolean; `old_marks`/`new_marks` cast to decimal; `is_active` cast to boolean; `created_at`/`updated_at` cast to Carbon dates; `resolved_at` cast to Carbon/null | — | — | ⬜ |
| TC-D16 | P | Unit — P1 — ExamGrievance Model — Relationship: belongsTo student | `$grievance->student` returns related Student model; `$grievance->student()->associate($student)` sets student_id; returns null if student deleted | — | — | ⬜ |
| TC-D17 | Q | Unit — P1 — ExamGrievance Model — Relationship: belongsTo examResult | `$grievance->examResult` returns ExamResult model; eager loading `ExamGrievance::with('examResult')` works; returns null if no exam_result_id | — | — | ⬜ |
| TC-D18 | R | Unit — P1 — ExamGrievance Model — Relationship: belongsTo examPaper | `$grievance->examPaper` returns ExamPaper model; eager loading `ExamGrievance::with('examPaper')` works | — | — | ⬜ |
| TC-D19 | S | Unit — P1 — ExamGrievance Model — Relationship: belongsTo reviewer (sys_users) | `$grievance->reviewer` returns User model when reviewer_id set; returns null for unresolved grievances | — | — | ⬜ |
| TC-D20 | T | Integration — P1 — ResultComputationService — computePercentage with various inputs | Normal input (18/20 = 90%); zero total (avoid division by zero); 100% (20/20); 0% (0/20); decimal precision (18.5/20 = 92.5%) | — | — | ⬜ |
| TC-D21 | U | Integration — P1 — ResultComputationService — calculateGrade with various percentages | 90%+ = A; 75-89% = B; 60-74% = C; 50-59% = D; 33-49% = E; <33% = F; boundary values at exact thresholds | — | — | ⬜ |
| TC-D22 | V | Integration — P1 — ResultComputationService — determineResultStatus with passing_percentage | Percentage >= passing_percentage → PASS; percentage < passing_percentage → FAIL; boundary (exactly passing) → PASS | — | — | ⬜ |
| TC-D23 | W | Integration — P1 — ResultComputationService — recomputeRank called after mark update | `resolve()` calls `$computation->recomputeRank($result->exam_id, $result->exam_paper_id)`; rank column in lms_exam_results updated for all students in same exam+paper | — | — | ⬜ |
| TC-D24 | X | Integration — P1 — GrievanceRequest Validation — FormRequest authorize() | GrievanceRequest::authorize() returns true (handled by controller Gate); validation rules cover create and resolve contexts | — | — | ⬜ |
| TC-D25 | Y | Integration — P1 — GrievanceRequest Validation — resolve context requires resolution_remarks | When status=RESOLVED or REJECTED, resolution_remarks required_if rule enforced; error message "Resolution remarks are required when resolving or rejecting." | — | — | ⬜ |
| TC-D26 | Z | Integration — P1 — Routes — All grievance routes mapped correctly | `lms-exam.exam-grievances.index` (GET), `lms-exam.exam-grievances.show` (GET/{id}), `lms-exam.exam-grievances.store` (POST), `lms-exam.exam-grievances.resolve` (PATCH/{id}), `lms-exam.exam-grievances.toggleStatus` (POST/{id}); each has auth + tenant middleware | — | — | ⬜ |
| TC-D27 | AA | Cross-Module — P1 — Student Portal — Student Can File Grievance After Result Published | Student logs into portal → views published result → clicks "File Grievance" → fills form → grievance created with status=OPEN | — | — | ⬜ |
| TC-D28 | AB | Cross-Module — P1 — Student Portal — Track Grievance Status | Student views "My Grievances" page → sees status badge, type, date, resolution (if resolved) | — | — | ⬜ |
| TC-D29 | AC | Cross-Module — P1 — Student Portal — Cannot File Duplicate Grievance | Student already filed grievance for result → button disabled or shows "Grievance Already Filed" message | — | — | ⬜ |
| TC-D30 | AD | DEV — P1 — GrievanceReviewController@resolve updates exam_results via DB transaction | Resolve with new_marks: exam_results updated, grievance updated, activity logged; if any step fails, all rolled back | — | — | ⬜ |
| TC-D31 | AE | DEV — P1 — Exam Result Deletion Cascades To Grievances | Deleting a result from lms_exam_results cascades to delete linked grievances (CASCADE FK) | — | — | ⬜ |
| TC-D32 | AF | DEV — P1 — Student Deletion Cascades To Grievances | Deleting a student from std_students cascades to delete linked grievances (CASCADE FK) | — | — | ⬜ |
| TC-D33 | AG | DEV — P1 — Partial List — Cascading Class→Section→Student dropdowns | Selecting class loads sections via AJAX; selecting section loads students via AJAX; all filter params preserved | — | — | ⬜ |
| TC-D34 | AH | DEV — P1 — Resolve Modal From Partial List | Clicking resolve button in partial_list opens modal with pre-filled data; form submits PATCH to resolve route | — | — | ⬜ |
| TC-D35 | AI | DEV — P1 — New Grievance Modal From Partial List | Clicking + button opens create modal; Select2 for student search; student-papers cascade via AJAX; form POSTs to store route | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.re-evaluation-requests.create'), @can('tenant.re-evaluation-requests.update') for access control on action buttons; user without permissions cannot see buttons | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | `lms-exam.exam-grievances.index` key → correct breadcrumb path defined | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — DB Transactions in store/resolve | resolve() uses DB::beginTransaction() + try-catch + DB::commit()/rollback(); no transaction in store() | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | All relationship access uses null-safe operator `$grievance->student?->full_name`; no undefined index/property errors when relation is null | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — JSON Response on toggleStatus | toggleStatus returns `response()->json(['status'=>'success', 'message' => 'Status updated successfully.', 'active' => $grievance->is_active])` | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — Redirect Response on resolve/store | resolve() returns redirect()->route(...)->with('success', ...); store() returns back()->with('success', ...) | — | — | ◌ |
| TC-CR07 | CR | Code Review | P2 | Client JS — SweetAlert Toast on toggle/grievance action | AJAX success calls showToast('success', message); error shows alert and reverts toggle | — | — | ◌ |
| TC-CR08 | CR | Code Review | P2 | Client JS — New Marks Input Max Constraint | new_marks input has max attribute set to total_marks_possible | — | — | ◌ |
| TC-CR09 | CR | Code Review | P2 | Controller — Index query uses whereHas for exam filter | WhereHas('examResult', fn($q) => $q->where('exam_id', $filters['exam_id'])) used correctly | — | — | ◌ |
| TC-CR10 | CR | Code Review | P1 | GrievanceReviewController — toggleStatus Returns Stale is_active | toggleStatus() (line 207-213) calls update() then returns $grievance->is_active WITHOUT refresh(); returned value is pre-update value (stale) | — | — | ◌ |
| TC-CR11 | CR | Code Review | P1 | GrievanceReviewController — No Duplicate Grievance Prevention | No validation check for existing identical grievance (same student + paper + issue); duplicate submissions not blocked | — | — | ◌ |
| TC-CR12 | CR | Code Review | P1 | GrievanceReviewController — Sorting Uses Raw SQL | index() sorts by `FIELD(status, 'OPEN','UNDER_REVIEW','RESOLVED','REJECTED')` — raw SQL in ORDER BY; verify no injection vector | — | — | ◌ |
| TC-CR13 | CR | Code Review | P1 | GrievanceReviewController — Inconsistent JSON Response Format | toggleStatus() returns `{status: 'success', ...}` while other controllers return `{success: true, ...}` — inconsistent | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR03: Controller — DB Transactions in resolve()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open GrievanceReviewController.php | Controller class found in Modules/LmsExam/Http/Controllers/ |
| 2 | Inspect resolve() method | DB::beginTransaction() before write operations |
| 3 | Verify try-catch block | try wraps all writes; catch does DB::rollBack() |
| 4 | Verify commit on success | DB::commit() called after activityLog |
| 5 | Verify rollback on exception | DB::rollBack() called in catch block; returns back with error |
| 6 | Verify store() has no transaction | store() does not use DB::transaction |
| 7 | Simulate DB failure during resolve | Transaction rolled back; no partial updates to exam_results or grievance |

#### TC-CR04: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open index.blade.php for grievances | View file found in exam-grievances/ |
| 2 | Scan for relationship access patterns | All use null-safe operator `?->` (e.g., `$g->student?->full_name`) |
| 3 | Scan for foreach loops over relationships | Loop target checked before iterating |
| 4 | Create a grievance with null examResult | View renders without undefined property error |
| 5 | Load index with grievances that have missing relations | No 500 errors; null values shown as "—" |

#### TC-CR05: Controller — JSON Response on toggleStatus

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open GrievanceReviewController.php | Controller found |
| 2 | Locate toggleStatus() method | Method exists with Gate::authorize and toggle logic |
| 3 | Inspect the method return | Returns response()->json(['status'=>'success', 'message'=>'Status updated successfully.', 'active' => $grievance->is_active]) |
| 4 | Send AJAX POST to toggleStatus endpoint | JSON response with success flag and new active state |
| 5 | Verify frontend behavior | Toast notification displayed on success |

#### TC-CR01: Blade @can Directives — Permission-based Visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php for create button | @can('tenant.re-evaluation-requests.create') wraps the Add Grievance button |
| 2 | Inspect show.blade.php for resolve form | @can('tenant.re-evaluation-requests.update') wraps the review action panel |
| 3 | Log in as user with all permissions | All action buttons visible and functional |
| 4 | Log in as user with viewAny only (no create/update) | Add Grievance button hidden; Review Action panel not shown |

### 6.1 Positive TC Steps

#### TC-P01: Grievance Index Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Navigate to Exam Management → Re-Evaluation tab | Page loads at GET /exam/master?active_tab=re_evaluation |
| 3 | Check 4 stat cards at top | Open, Under Review, Resolved, Rejected cards visible with counts |
| 4 | Check filter form | Search input, Status dropdown, Type dropdown, Exam dropdown present |
| 5 | Check table columns | Student, Exam/Paper, Type, Grievance, Status, Filed On, Active, Action |
| 6 | Check pagination | Pagination links at bottom |
| 7 | Check Add Grievance button | Plus button visible (with create permission) |

#### TC-P02: 4 Stat Cards Show Correct Counts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 OPEN, 3 UNDER_REVIEW, 4 RESOLVED, 1 REJECTED grievance | 10 total grievances |
| 2 | Reload index page | Open card shows "2", Under Review shows "3", Resolved shows "4", Rejected shows "1" |
| 3 | Add 1 more OPEN grievance | Reload → Open card shows "3" |
| 4 | Resolve one OPEN grievance | Status counts recalculated; Open decreases, Resolved increases |

#### TC-P03: Stat Card Colors And Icons Match Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect Open card | Red color (#e17055), fa-circle-exclamation icon |
| 2 | Inspect Under Review card | Yellow color (#fdcb6e), fa-magnifying-glass icon |
| 3 | Inspect Resolved card | Green color (#00b894), fa-circle-check icon |
| 4 | Inspect Rejected card | Gray color (#636e72), fa-ban icon |

#### TC-P04: Filter By Status — Open

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create grievances with different statuses | 2 OPEN, 2 UNDER_REVIEW, 2 RESOLVED, 2 REJECTED |
| 2 | Select "Open" from Status dropdown | status=OPEN |
| 3 | Click Filter | Only 2 OPEN grievances shown |
| 4 | Verify no other statuses visible | UNDER_REVIEW, RESOLVED, REJECTED hidden |

#### TC-P05 to TC-P07: Filter By Status (Under Review / Resolved / Rejected)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Under Review" | Only UNDER_REVIEW grievances shown |
| 2 | Select "Resolved" | Only RESOLVED grievances shown |
| 3 | Select "Rejected" | Only REJECTED grievances shown |

#### TC-P08 to TC-P11: Filter By Grievance Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create grievances of each type | 1 MARKING_ERROR, 1 QUESTION_ERROR, 1 OUT_OF_SYLLABUS, 1 OTHER |
| 2 | Select "Marking Error" | Only MARKING_ERROR shown |
| 3 | Select "Question Error" | Only QUESTION_ERROR shown |
| 4 | Select "Out of Syllabus" | Only OUT_OF_SYLLABUS shown |
| 5 | Select "Other" | Only OTHER shown |

#### TC-P12: Filter By Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 exams, grievances for each | 3 grievances for Exam A, 2 for Exam B |
| 2 | Select Exam A from dropdown | Only 3 grievances for Exam A shown |
| 3 | Switch to Exam B | Only 2 grievances for Exam B shown |

#### TC-P13 to TC-P15: Search Functionality

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Type student name "John Doe" in search | Only grievances by "John Doe" shown |
| 2 | Type partial "John" | All students with "John" in name shown |
| 3 | Type grievance text keyword "marks" | Grievances containing "marks" in grievance_text shown |

#### TC-P16: Clear All Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filters (status=OPEN, type=MARKING_ERROR) | Filtered results |
| 2 | Click Reset/Rotate button | All filters cleared, all grievances shown |
| 3 | Verify URL | No query parameters |

#### TC-P17: Status Priority Sorting

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 1 grievance of each status | 4 grievances |
| 2 | Reload index page | Order: Open → Under Review → Resolved → Rejected |
| 3 | Create 2nd Open grievance | Both Open grievances appear first, sorted by created_at desc within same status |

#### TC-P18: All Fields Visible In Table Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a grievance with full data | Grievance exists |
| 2 | View index table row | Student name + ID, Exam/Paper names, Type badge, Truncated text (80 chars), Status badge, Created date, Active toggle, Eye button |
| 3 | Verify marks revised badge | If marks_changed, "Marks Revised" info badge shown |

#### TC-P19: Show Grievance Detail Page Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a grievance with all relations | Grievance exists |
| 2 | Click Eye button on that row | Navigates to GET /exam/exam-grievances/{id} |
| 3 | Check page layout | Left column: Info (header card + context + details + resolution), Right column: Review action panel |

#### TC-P20: Show Page — Status Color-Coded Header Card

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | View OPEN grievance | Left border: red; Status badge: red "Open" |
| 2 | View UNDER_REVIEW grievance | Left border: yellow; Status badge: yellow "Under Review" |
| 3 | View RESOLVED grievance | Left border: green; Status badge: green "Resolved" |
| 4 | View REJECTED grievance | Left border: gray; Status badge: gray "Rejected" |

#### TC-P21: Show Page — Student Information

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open show page for grievance with student | Student full name displayed, "Student ID: X" below |

#### TC-P22: Show Page — Exam And Paper Context

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open show page | Exam title displayed in fw-semibold, paper title below in gray |
| 2 | If no exam result relation | Falls back to "—" |

#### TC-P23: Show Page — Marks Obtained And Percentage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open show | Marks obtained in large font, "/ X total" below, percentage displayed, PASS/FAIL badge |

#### TC-P24: Show Page — Grievance Type Badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | View grievance of each type | Type badge shows correct label: "Marking Error", "Question Error", "Out of Syllabus", "Other" |

#### TC-P25: Show Page — Full Grievance Text

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open show | Full grievance text in yellow-highlighted box with left yellow border |
| 2 | Verify text is not truncated | Unlike list view, full text shown |

#### TC-P26: Show Page — Review Action Panel Visible (OPEN)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create OPEN grievance | Status = OPEN |
| 2 | Open show page | Right column shows "Review Action" panel: Status dropdown, Revised Marks (hidden initially), Remarks textarea, Save button |

#### TC-P27: Show Page — Review Action Panel Visible (UNDER_REVIEW)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Change status to UNDER_REVIEW | Status updated |
| 2 | Open show page | Same review panel visible |

#### TC-P28 to TC-P29: Show Page — Review Action Panel Hidden

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open RESOLVED grievance | Lock icon and "This grievance is RESOLVED and cannot be edited." |
| 2 | Open REJECTED grievance | Lock icon and "This grievance is REJECTED and cannot be edited." |

#### TC-P30: Show Page — Existing Resolution Displayed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Resolve a grievance with remarks | Resolution saved |
| 2 | Open show page | Resolution remarks in green-bordered box, "Resolved by X on date" below |

#### TC-P31: Show Page — Marks Revised Badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Resolve with mark change (15 → 18) | marks_changed=true, old_marks=15, new_marks=18 |
| 2 | Open show page | Badge "Marks Revised: 15 → 18" in header card |

#### TC-P32: Change Status To Under Review

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open OPEN grievance | Review panel visible |
| 2 | Select "Under Review" from dropdown | Status=UNDER_REVIEW |
| 3 | Add remarks "Investigating the marking" | Remarks saved |
| 4 | Click Save Decision | PATCH to resolve endpoint |
| 5 | Check success message | "Grievance updated successfully." |
| 6 | DB check: status | UNDER_REVIEW, reviewer_id set, resolution_remarks saved |

#### TC-P33: Resolve Grievance Without Mark Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open OPEN/UNDER_REVIEW grievance | Review panel visible |
| 2 | Select "Resolved" from dropdown | Revised Marks block appears |
| 3 | Leave new_marks blank | No mark change |
| 4 | Add resolution remarks "No error found. Marks are correct." | Remarks saved |
| 5 | Click Save Decision | Status=RESOLVED, resolved_at set |
| 6 | DB check: marks_changed=false | No mark revision |

#### TC-P34: Resolve Grievance With Mark Increase

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create result with total_marks_obtained=15, total_marks_possible=20 | Current result |
| 2 | File grievance, review it | Status=UNDER_REVIEW |
| 3 | Select "Resolved", enter new_marks=18 | New marks higher |
| 4 | Add remarks "Re-evaluated: additional marks awarded." | Remarks saved |
| 5 | Click Save | Resolved successfully |
| 6 | DB check: exam_results total_marks_obtained=18 | Updated |
| 7 | DB check: percentage=90%, grade=A, result_status=PASS | Recalculated |
| 8 | DB check: grievance marks_changed=true, old_marks=15, new_marks=18 | Audited |

#### TC-P35: Resolve Grievance With Mark Decrease

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create result with total_marks_obtained=18, total_marks_possible=20 | Current |
| 2 | Resolve with new_marks=15 | Marks reduced |
| 3 | DB check: marks updated to 15, percentage=75% | Decreased correctly |

#### TC-P36 to TC-P37: Result Status Flips

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Result at 12/20 (60%, PASS), reduce to 5/20 (25%) | Result status flips to FAIL |
| 2 | Result at 4/20 (20%, FAIL), increase to 14/20 (70%) | Result status flips to PASS |

#### TC-P38: Resolve Grievance — Rank Recalculated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 students with marks in same exam+paper | Rank: 1st, 2nd, 3rd |
| 2 | Resolve grievance for 3rd student with higher marks | Student's marks increase past 2nd |
| 3 | DB check: ranks recomputed | Previously 3rd student now 2nd |

#### TC-P39: Resolve — Same Marks No Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Current marks=15/20 | Existing result |
| 2 | Resolve with new_marks=15 (same) | marks_changed=false, rank NOT recomputed |
| 3 | DB: exam_results unchanged | No update to result |

#### TC-P40: Reject Grievance With Remarks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open grievance, select "Rejected" | Status dropdown |
| 2 | Add remarks "No marking error found." | Remarks filled |
| 3 | Click Save | Status=REJECTED, resolved_at set |
| 4 | Verify marks block hidden | REJECTED does not show marks input |

#### TC-P41 to TC-P42: Toggle Active Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle is_active OFF | AJAX POST to toggleStatus; response: active=false |
| 2 | Verify DB: is_active=0 | Toggled |
| 3 | Toggle is_active ON | AJAX POST; response: active=true |
| 4 | Verify DB: is_active=1 | Toggled back |

#### TC-P43: Manual Grievance Creation (All Fields)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add Grievance" button | Modal opens |
| 2 | Search and select student | Student selected |
| 3 | Select paper | Paper selected |
| 4 | Select grievance_type="MARKING_ERROR" | Type selected |
| 5 | Enter grievance_text="Marks not added correctly for Q3." | Text entered |
| 6 | Click Save | POST to store route |
| 7 | Verify new grievance appears in list | Status=OPEN, created_by set |

#### TC-P44: Auto-Find Exam Result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Store grievance without exam_result_id | Controller finds ExamResult by (student_id, exam_paper_id) |
| 2 | If found → links to that result | exam_result_id set |
| 3 | If not found → error | "No result found" |

#### TC-P45 to TC-P46: Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 25 grievances | Pagination at bottom: "Showing 1 to 20 of 25" |
| 2 | Click page 2 | Shows records 21-25 |
| 3 | Apply filter, click page 2 | Filter params preserved in URL |

#### TC-P47: Empty State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no grievances exist | Empty table |
| 2 | Reload index page | "No grievances found" with face icon |
| 3 | Apply filter that matches zero results | Same empty state |

#### TC-P48: Full Grievance Lifecycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student files grievance → OPEN | Grievance created |
| 2 | Teacher reviews → sets UNDER_REVIEW | Status updated |
| 3 | Teacher investigates → resolves with mark update | RESOLVED, marks changed, rank recomputed |
| 4 | Activity logged at each step | 3 activity log entries |

#### TC-P49: Full Grievance Lifecycle — Reject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create grievance → OPEN | Created |
| 2 | Set UNDER_REVIEW | Updated |
| 3 | Reject with remarks | REJECTED, resolved_at set |
| 4 | Verify result NOT changed | Marks unchanged in exam_results |

#### TC-P50: Show Page — Related Question Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create grievance with question_id | question_id set |
| 2 | Open show page | "Related Question" section shows question content |
| 3 | If question relation missing | Shows "Question ID: X" as fallback |

#### TC-P51 to TC-P54: Client-Side Behavior

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Resolved" status | Revised Marks block appears |
| 2 | Select "Rejected" status | Revised Marks block hidden |
| 3 | Select "Resolved" or "Rejected" | Remarks label shows red * (required) |
| 4 | Select "Under Review" | Remarks not required, marks block hidden |
| 5 | new_marks input max attribute | Set to total_marks_possible value |

### 6.2 Negative TC Steps

#### TC-N01 to TC-N05: Permission Tests

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without viewAny | 403 on index |
| 2 | Login without view | 403 on show |
| 3 | Login without create | 403 on store |
| 4 | Login without update | 403 on resolve and toggleStatus |

#### TC-N06: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate to any grievance route | Redirect to /login |

#### TC-N07 to TC-N09: Invalid IDs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open /exam/exam-grievances/99999 | 404 |
| 2 | PATCH /exam/exam-grievances/99999/resolve | 404 |
| 3 | POST /exam/exam-grievances/99999/toggle-status | 404 |

#### TC-N10 to TC-N18: Store Validation Errors

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit store without student_id | Validation error required |
| 2 | Submit store without exam_paper_id | Validation error required |
| 3 | Submit store without grievance_type | Validation error required |
| 4 | Submit store with invalid type | "The selected grievance type is invalid." |
| 5 | Submit store without grievance_text | Required validation |
| 6 | Submit store with text > 5000 chars | Max validation |
| 7 | Submit store with invalid student_id | FK exists validation |
| 8 | Submit store with no matching result | "No result found" |

#### TC-N19 to TC-N24: Resolve Validation Errors

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit resolve without status | Required validation |
| 2 | Submit resolve with invalid status | Invalid selection |
| 3 | Submit resolve with negative new_marks | Min validation |
| 4 | Submit resolve with RESOLVED but no remarks | required_if validation |
| 5 | Submit resolve with REJECTED but no remarks | required_if validation |

#### TC-N25 to TC-N28: XSS and Whitespace

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create grievance with `<script>alert('xss')</script>` | Stored as literal, escaped by Blade |
| 2 | Add resolution remarks with XSS | Stored safely, escaped |
| 3 | Submit whitespace-only text | Required validation fails |

### 6.3 Dependency TC Steps

#### TC-D12: DB Transaction in resolve()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller, inspect resolve() | DB::beginTransaction at start |
| 2 | Verify try block contains exam_results update + grievance update + activityLog | All writes in transaction |
| 3 | Verify catch block does rollBack() | Rollback on any exception |
| 4 | Force exception during mark update | Grievance status NOT changed |
| 5 | DB verify no partial updates | All or nothing |

#### TC-D20: ResultComputationService — computePercentage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | computePercentage(18, 20) | 90.0 |
| 2 | computePercentage(0, 20) | 0.0 |
| 3 | computePercentage(20, 20) | 100.0 |
| 4 | computePercentage(18.5, 20) | 92.5 |
| 5 | computePercentage(10, 0) | 0.0 (avoid division by zero) |

#### TC-D21: ResultComputationService — calculateGrade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Percentage = 95 | Grade A |
| 2 | Percentage = 80 | Grade B |
| 3 | Percentage = 65 | Grade C |
| 4 | Percentage = 55 | Grade D |
| 5 | Percentage = 40 | Grade E |
| 6 | Percentage = 20 | Grade F |
| 7 | Percentage exactly at boundary (90, 75, 60, 50, 33) | Upper grade awarded at boundary |

#### TC-D22: determineResultStatus with passing_percentage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Passing=33, Percentage=50 | PASS |
| 2 | Passing=33, Percentage=33 | PASS (boundary) |
| 3 | Passing=33, Percentage=32 | FAIL |
| 4 | Passing=40, Percentage=39 | FAIL |
| 5 | Passing=40, Percentage=40 | PASS (boundary) |

#### TC-D26: Routes Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run route:list --path=exam/exam-grievances | Index: GET, Show: GET/{id}, Store: POST, Resolve: PATCH/{id}, toggleStatus: POST/{id} |
| 2 | Verify middleware | All routes have auth + tenant middleware |

#### TC-D27 to TC-D29: Student Portal Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student logs into portal, views published result | Result page shows "File Grievance" button |
| 2 | Student files grievance | Grievance created as OPEN |
| 3 | Teacher views in admin | New grievance visible |
| 4 | Student checks "My Grievances" | Sees status badge |
| 5 | Student attempts to file duplicate | Warning "Grievance Already Filed" shown |

#### TC-D33: Cascading Class→Section→Student Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load partial_list view | Classes dropdown populated |
| 2 | Select a class | AJAX loads sections for that class |
| 3 | Select a section | AJAX loads students for that section |
| 4 | All filters preserved across requests | Filter params in URL |

#### TC-D34: Resolve Modal From Partial List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Resolve" button in partial_list | Modal opens with student name, current status, old marks |
| 2 | Change status, add remarks | Form prepared |
| 3 | Submit | PATCH to resolve route |
| 4 | Verify grievance updated | Status changed |

#### TC-D35: New Grievance Modal From Partial List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "+" button | Modal opens with Select2 student search |
| 2 | Search and select student | Student selected |
| 3 | Student-papers cascade loads | Papers for that student shown in optgroups |
| 4 | Fill all fields, save | POST to store, grievance created |

#### TC-D12: DB Transaction in resolve() - Detailed Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open GrievanceReviewController.php | Controller file |
| 2 | Locate resolve() method | Method at line ~125 |
| 3 | Verify DB::beginTransaction() at start | First line after try block |
| 4 | Verify exam_result update inside try | $result->update([...]) |
| 5 | Verify grievance update inside try | $grievance->update([...]) |
| 6 | Verify activityLog inside try | activityLog() called before DB::commit() |
| 7 | Verify DB::commit() at end of try | After all writes |
| 8 | Verify DB::rollBack() in catch | On exception, all changes reverted |
| 9 | Enable query log, trigger resolve with exception | No INSERT/UPDATE on any table |
| 10 | Disable exception, trigger normal resolve | All 3 writes committed atomically |

#### TC-D20: ResultComputationService — computePercentage Detailed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call computePercentage(18, 20) | Returns 90.0 |
| 2 | Call computePercentage(0, 20) | Returns 0.0 |
| 3 | Call computePercentage(20, 20) | Returns 100.0 |
| 4 | Call computePercentage(10, 20) | Returns 50.0 |
| 5 | Call computePercentage(18.5, 20) | Returns 92.5 |
| 6 | Call computePercentage(10, 0) | Returns 0.0 (no division by zero) |
| 7 | Call computePercentage(10, null) | Returns 0.0 (null safe) |
| 8 | Call computePercentage(null, 20) | Returns 0.0 (null safe) |
| 9 | Call computePercentage(7, 20) | Returns 35.0 |
| 10 | Call computePercentage(6.6, 20) | Returns 33.0 |

#### TC-D21: ResultComputationService — calculateGrade Boundary Cases

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Percentage = 100 | Grade A |
| 2 | Percentage = 90 | Grade A (boundary) |
| 3 | Percentage = 89.99 | Grade B |
| 4 | Percentage = 75 | Grade B (boundary) |
| 5 | Percentage = 74.99 | Grade C |
| 6 | Percentage = 60 | Grade C (boundary) |
| 7 | Percentage = 59.99 | Grade D |
| 8 | Percentage = 50 | Grade D (boundary) |
| 9 | Percentage = 49.99 | Grade E |
| 10 | Percentage = 33 | Grade E (boundary) |
| 11 | Percentage = 32.99 | Grade F |
| 12 | Percentage = 0 | Grade F |

#### TC-D22: determineResultStatus Boundary Cases

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | passing_pct=33, pct=50.00 | PASS |
| 2 | passing_pct=33, pct=33.00 | PASS (exact boundary) |
| 3 | passing_pct=33, pct=32.99 | FAIL |
| 4 | passing_pct=33, pct=0.00 | FAIL |
| 5 | passing_pct=40, pct=40.00 | PASS (exact boundary) |
| 6 | passing_pct=40, pct=39.99 | FAIL |
| 7 | passing_pct=50, pct=50.00 | PASS |
| 8 | passing_pct=50, pct=49.99 | FAIL |
| 9 | passing_pct=0, pct=0.00 | PASS (no passing threshold) |
| 10 | passing_pct=100, pct=99.99 | FAIL |
| 11 | passing_pct=null, pct=50.00 | Uses default 33%, PASS |

#### TC-D26: Routes Verification — Full Route List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `php artisan route:list --path=exam/exam-grievances` | All grievance routes listed |
| 2 | Verify index route | `GET /exam/exam-grievances` → GrievanceReviewController@index |
| 3 | Verify show route | `GET /exam/exam-grievances/{id}` → GrievanceReviewController@show |
| 4 | Verify store route | `POST /exam/exam-grievances/store` → GrievanceReviewController@store |
| 5 | Verify resolve route | `PATCH /exam/exam-grievances/{id}/resolve` → GrievanceReviewController@resolve |
| 6 | Verify toggleStatus route | `POST /exam/exam-grievances/{id}/toggle-status` → GrievanceReviewController@toggleStatus |
| 7 | Verify all routes have auth middleware | Middleware column shows 'auth' |
| 8 | Verify all routes have tenant middleware | Middleware column shows 'tenant' |
| 9 | Verify route names match | lms-exam.exam-grievances.index, .show, .store, .resolve, .toggleStatus |
| 10 | Verify no missing routes | All 5 CRUD-like routes present |

#### TC-D27: Cross-Module Student Portal Grievance Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student logs into Student Portal | Portal loads |
| 2 | Navigate to Online Exam → View Published Result | Result page shows "File Grievance" button/link |
| 3 | Click "File Grievance" | Navigates to /online-exam/{id}/grievance/create |
| 4 | Verify form fields | Grievance Type dropdown, Grievance Text textarea |
| 5 | Select type "MARKING_ERROR", enter text "Q3 marks not added" | Fields filled |
| 6 | Click "Submit Grievance" | POST to /online-exam/{id}/grievance |
| 7 | Check success message | "Grievance filed successfully" |
| 8 | Switch to Admin account, open grievance list | New grievance visible with OPEN status |
| 9 | Verify exam_result_id auto-linked | Result matches student+paper |
| 10 | Verify created_at timestamp | Set to current time |

#### TC-D28: Cross-Module Student Portal — Track Grievance Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student logs into portal | Portal loads |
| 2 | Click "My Grievances" | GET /my-grievances |
| 3 | Verify table columns | Student ID, Exam/Paper, Type, Status, Filed On, Action |
| 4 | View OPEN grievance | Status badge shows "Open" in red |
| 5 | Admin changes status to UNDER_REVIEW | Updated |
| 6 | Student refreshes My Grievances | Status changed to "Under Review" in yellow |
| 7 | Admin resolves with remarks | Updated |
| 8 | Student refreshes | Status "Resolved" in green, resolution shown |
| 9 | Student views grievance detail | Full text and resolution visible |

#### TC-D29: Cross-Module Student Portal — Duplicate Prevention

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student files grievance for result | First grievance created |
| 2 | Student returns to same result page | "File Grievance" button disabled or "Grievance Already Filed" warning |
| 3 | Student clicks "My Grievances" | Existing grievance visible |
| 4 | Student tries to POST duplicate | Controller checks existing record; rejects with error |
| 5 | DB check: only 1 grievance for that result | Single record |

#### TC-D30: Resolve Updates exam_results via DB Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Record exam_results state for student | total_marks_obtained=15, percentage=75%, grade=B |
| 2 | Resolve grievance with new_marks=18 | Resolved |
| 3 | DB check: exam_results for student | total_marks_obtained=18, percentage=90%, grade=A |
| 4 | DB check: grievance marks_changed=true | old_marks=15, new_marks=18 |
| 5 | DB check: activity_logs | Entry for grievance status update |
| 6 | If marks same (new=old=15) | exam_results NOT updated, marks_changed=false |
| 7 | If DB write fails mid-way | Transaction rollback; grievance still at previous status |

#### TC-D31: Exam Result Deletion Cascades To Grievances

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam_result with linked grievance | Both exist |
| 2 | Delete the exam_result record | DDL CASCADE fires |
| 3 | DB check: grievance still exists | `exam_result_id` = NULL (if ON DELETE SET NULL) or record deleted |
| 4 | DB check: grievance no longer linked | exam_result_id = NULL |

#### TC-D32: Student Deletion Cascades To Grievances

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create student with linked grievance | Grievance.student_id = student.id |
| 2 | Delete the student record | CASCADE or RESTRICT based on FK config |
| 3 | DB check: grievance.student_id | NULL or record deleted |

#### TC-D33: Cascading Class→Section→Student Dropdowns — Full Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load re_evaluation tab with partial_list | Classes dropdown populated |
| 2 | Verify default "All Classes" selected | First option selected |
| 3 | Select a specific class | AJAX fires: GET /get-sections-by-class?class_id=X |
| 4 | Verify section dropdown populated | Options for sections in that class |
| 5 | Verify student dropdown cleared | Reset to "All Students" |
| 6 | Select a specific section | AJAX fires: GET /student-search?class_id=X&section_id=Y |
| 7 | Verify student dropdown populated | Options for students in that section |
| 8 | Clear class selection | Both section and student reset to "All" |
| 9 | Verify filter params in URL | class_id, section_id, student_id as GET params |
| 10 | Verify page reload with filter params | Table data filtered correctly |

#### TC-D34: Resolve Modal From Partial List — Detailed Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load re_evaluation tab with grievances | Table visible |
| 2 | Click resolve button (check-to-slot icon) | showResolveModal() called |
| 3 | Verify modal title | "Resolve Grievance: {student_name}" |
| 4 | Verify status pre-selected | Current status selected |
| 5 | Verify remarks pre-filled | Current resolution_remarks in textarea |
| 6 | Verify old marks displayed | In read-only input |
| 7 | Verify new marks input empty | Blank for entering |
| 8 | Change status to RESOLVED | Marks revision fields appear |
| 9 | Enter new marks, add remarks | Fields filled |
| 10 | Click "Update Grievance" | Form submits PATCH to resolve route |
| 11 | Verify modal closes | Modal hidden |
| 12 | Verify table refreshed | Status updated |

### 5.4 Code Review TC Steps — Detailed

#### TC-CR07: Client JS — SweetAlert Toast on Toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open index.blade.php | View file found |
| 2 | Search for showToast function | Function defined: Swal.fire({toast:true, position:'top-end', ...}) |
| 3 | Toggle is_active switch | AJAX POST to toggleStatus |
| 4 | On success | showToast('success', 'Status updated successfully.') |
| 5 | On error | alert('Failed to update status.'); checkbox reverted |
| 6 | Verify timer | 2500ms timer with progress bar |

#### TC-CR08: Client JS — New Marks Input Max Constraint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open show.blade.php | View file |
| 2 | Find new_marks input | `max="{{ $result?->total_marks_possible ?? 999 }}"` |
| 3 | Open grievance with result marks_possible=20 | max=20 |
| 4 | Try entering value > 20 | Browser validation prevents |
| 5 | Try entering negative value | min=0 prevents |

#### TC-CR09: Controller — Index Query Uses whereHas For Exam Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open GrievanceReviewController.php | Controller |
| 2 | Inspect index() method | Query built with whereHas for exam filter |
| 3 | Verify whereHas syntax | `$query->whereHas('examResult', fn($q) => $q->where('exam_id', $filters['exam_id']))` |
| 4 | Select exam filter | Only grievances with exam result belonging to that exam shown |
| 5 | Verify no exam_id filter | All grievances shown across all exams |

#### TC-CR04: View — isset/null-safe Complete Scan

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open index.blade.php | Scan all variable accesses |
| 2 | Check: `$g->student?->full_name` | Null-safe used |
| 3 | Check: `$g->examResult?->exam?->title` | Double null-safe chain |
| 4 | Check: `$g->examResult?->examPaper?->title` | Null-safe used |
| 5 | Check: `$g->created_at->format(...)` | Direct call (created_at always set) |
| 6 | Open show.blade.php | Scan all variable accesses |
| 7 | Check: `$grievance->student?->full_name` | Null-safe used |
| 8 | Check: `$result?->exam?->title` | Null-safe chain |
| 9 | Check: `$result?->total_marks_obtained` | Null-safe used |
| 10 | Check: `$grievance->reviewer?->name` | Null-safe used |
| 11 | Load page with null relations | All display as "—" or graceful fallback |

### 6.2 Negative TC Steps — Additional

#### TC-N30: DB Transaction Rollback On Exception

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify resolve() method in controller | Wrapped in try-catch with DB transaction |
| 2 | Simulate exception after exam_result update but before grievance update | Force exception |
| 3 | Verify DB::rollBack() called | Catch block executed |
| 4 | Verify exam_result NOT updated | Old marks preserved |
| 5 | Verify grievance NOT updated | Status unchanged |
| 6 | Verify error message returned | "Failed to update grievance. Please try again." |
| 7 | Verify input preserved | Form values restored via ->withInput() |
| 8 | Normal resolve (no exception) | DB::commit() called, all changes saved |

#### TC-N31: Resolve — Marks Over Max Possible

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Exam result: total_marks_possible=20 | Max 20 |
| 2 | Try to resolve with new_marks=25 | Input max=20 prevents in browser |
| 3 | Submit via API with new_marks=25 (bypass JS) | Application handles gracefully |
| 4 | Verify result_status computed correctly | Percentage may exceed 100% |

#### TC-N32: Store — SQL Injection In Search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit search with `' OR 1=1 --` | Treated as literal string, not SQL injection |
| 2 | Submit search with `'; DROP TABLE lms_exam_grievances; --` | Treated as literal, safe |
| 3 | Verify query uses parameterized LIKE | $query->where('grievance_text', 'like', $term) with bound parameter |

#### TC-N33: Store — Large Payload In grievance_text

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit grievance_text with 5001+ characters | Validation: max exceeded, error returned |
| 2 | Submit grievance_text with exactly 5000 characters | Accepted (boundary) |
| 3 | Submit grievance_text with multibyte Unicode | Stored correctly in TEXT column |

#### TC-N34: Toggle Status — Concurrent Requests

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send 2 simultaneous toggle requests | Both processed sequentially |
| 2 | Final state = result of last request | Last write wins |
| 3 | No data corruption | is_active always 0 or 1 |

#### TC-N35: Invalid Attempt To Resolve Already Resolved Grievance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Resolve grievance (status=RESOLVED) | Success |
| 2 | Try to call resolve endpoint again | No error but status unchanged |
| 3 | Verify no duplicate activity log | Only original resolution logged |

### 6.4 Additional Integration Test Steps

#### TC-DB-01: Schema — All Columns Present In lms_exam_grievances

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run DESCRIBE lms_exam_grievances | All 17 columns present with correct types |
| 2 | Verify ENUM values for status | OPEN, UNDER_REVIEW, RESOLVED, REJECTED |
| 3 | Verify ENUM values for grievance_type | MARKING_ERROR, QUESTION_ERROR, OUT_OF_SYLLABUS, OTHER |
| 4 | Verify default values | is_active=1, marks_changed=0, status='OPEN' |
| 5 | Verify nullable columns | reviewer_id, resolution_remarks, resolved_at, old_marks, new_marks = NULL |

#### TC-DB-02: Schema — All Columns In lms_exam_results (Related)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DESCRIBE lms_exam_results | Has total_marks_obtained, total_marks_possible, percentage, grade_obtained, result_status |
| 2 | Verify DECIMAL types | total_marks_obtained, percentage = DECIMAL |
| 3 | Verify ENUM for result_status | PASS, FAIL (or similar) |
| 4 | Verify FK constraints | exam_id, exam_paper_id, student_id all NOT NULL with FKs |

#### TC-PS-01: Activity Log Entry After Grievance Resolve

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create and resolve grievance | Resolved |
| 2 | Query activity_logs table | Entry exists: "Grievance #[id] status set to RESOLVED." |
| 3 | Verify performed_by | Auth user name stored |
| 4 | Verify timestamp | Matches resolution time |

#### TC-PS-02: Multiple Status Changes — All Logged

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create grievance → OPEN | No activity (creation not logged in controller) |
| 2 | Change to UNDER_REVIEW | Activity: "Grievance #[id] status set to UNDER_REVIEW." |
| 3 | Change to RESOLVED | Activity: "Grievance #[id] status set to RESOLVED." |
| 4 | Query all entries for this grievance | 2 entries with different messages |

#### TC-PS-03: Undo Status Change (Re-resolve already resolved)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Resolve grievance | RESOLVED |
| 2 | Open show page | Lock icon displayed, no review panel |
| 3 | Can't change status via UI | Panel not rendered |

#### TC-PS-04: Multiple Grievances For Same Student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student has 2 exam results | Two results |
| 2 | File grievance for each | Both created |
| 3 | Filter by student name | Both grievances shown |
| 4 | Each has correct exam+paper reference | Linked to different results |

#### TC-PS-05: Grievance Counts Reset After Filter Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All status counts shown in cards | 4 cards |
| 2 | Apply a status filter | Cards still show ALL counts (not filtered) |
| 3 | Verify cards independent of table filter | Status counts are global, not filtered |

#### TC-PS-06: Grievance Type Display Consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create grievance type MARKING_ERROR | Shows "Marking Error" |
| 2 | Create grievance type QUESTION_ERROR | Shows "Question Error" |
| 3 | Create grievance type OUT_OF_SYLLABUS | Shows "Out of Syllabus" |
| 4 | Create grievance type OTHER | Shows "Other" |
| 5 | Verify match labels used in filter dropdown | Same 4 labels |

#### TC-PS-07: New Marks Validation — Decimal Step

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | new_marks input has step="0.5" | Allows 0, 0.5, 1, 1.5 etc |
| 2 | Enter 0.5 as new_marks | Accepted |
| 3 | Enter 0.75 as new_marks | Not valid (step mismatch in browser) |
| 4 | Enter integer 10 | Accepted |

#### TC-PS-08: New Marks Input — Empty Means No Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave new_marks blank | null submitted |
| 2 | Controller checks `isset($data['new_marks']) && $data['new_marks'] !== null` | False → marks not updated |
| 3 | marks_changed stays false | No mark revision |
| 4 | Verify same marks preserved | exam_results unchanged |

#### TC-PS-09: Show Page — Status Switch Toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open show page for grievance | Status switch toggle visible next to status badge |
| 2 | Toggle OFF | AJAX POST to toggleStatus |
| 3 | Verify active state changed | is_active=0 |
| 4 | Refresh show page | Toggle shows OFF |

#### TC-PS-10: Breadcrumb Navigation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open standalone index page | Breadcrumb: "Exam Management > Grievance Review" |
| 2 | Navigate to show page | Breadcrumb: "Grievance Detail" with back link |
| 3 | Click breadcrumb link | Navigates to index |

#### TC-PS-11: Multi-Filter Combination With Search + Status + Type + Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply search="John" | Filters to John |
| 2 | Add status=OPEN | Further filtered to OPEN only |
| 3 | Add type=MARKING_ERROR | Only OPEN + MARKING_ERROR + matching name |
| 4 | Add exam=Science Exam | Only matching exam |
| 5 | Verify URL params | All 4 params in query string |
| 6 | Verify table results | Exact match of all 4 criteria |

#### TC-PS-12: Reset Filters From Multi-Filter State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply 4 filters | URL has 4 params |
| 2 | Click Reset | URL clears, no params |
| 3 | Verify all grievances shown | No filters applied |

#### TC-PS-13: Grievance Text Truncation In List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create grievance with 200-char text | grievance_text = 200 chars |
| 2 | View in index table | Truncated to 80 chars with "..." |
| 3 | View in show page | Full 200 chars displayed without truncation |

#### TC-PS-14: Grievance With Null student_id Fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create grievance without student relation | student_id=null or deleted student |
| 2 | View in index table | Shows "—" for student name, "ID —" for ID |
| 3 | Verify no 500 error | View renders gracefully |

#### TC-PS-15: Grievance With Null examResult Fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create grievance without exam_result relation | exam_result_id=null or deleted result |
| 2 | View in index table | Exam shows "—" |
| 3 | View in show page | Exam "—", Marks "—", Percentage "—", Result "—" |

#### TC-PS-16: Mass Test — 100 Grievances Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 100 grievances | 100 records |
| 2 | Load index page | Page 1: 20 records, "Showing 1 to 20 of 100" |
| 3 | Click through pages 2-5 | Each page shows 20 records |
| 4 | Page 5: records 81-100 | Last 20 records |
| 5 | Verify no page 6 | Only 5 pages |

#### TC-PS-17: Grievance Created By Different User

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Admin A creates grievance | created_by = Admin A ID |
| 2 | Admin B resolves grievance | reviewer_id = Admin B ID |
| 3 | Show page shows reviewer | "Resolved by Admin B on ..." |
| 4 | DB check: created_by ≠ reviewer_id | Different users recorded |

#### TC-PS-18: Show Page — Question Context (When Present)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create grievance with question_id=5 | question_id set |
| 2 | Ensure question relation exists | Question model available |
| 3 | Open show page | "Related Question" section with question content |
| 4 | If question deleted | Shows "Question ID: 5" as fallback |

#### TC-PS-19: Activities Logged With Proper Context

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Resolve grievance | activityLog called |
| 2 | Inspect activity log payload | Message, performed_by, related model |
| 3 | Verify context links to grievance | Log entry references grievance ID |
| 4 | Verify timestamp | Current time |

#### TC-PS-20: Full Grievance Cycle — Student Portal To Admin Resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student "Alice" takes exam, gets result | Result published |
| 2 | Alice files grievance: "Q3 not marked" | Grievance created as OPEN |
| 3 | Admin sees grievance in list | Status=OPEN, type=OTHER |
| 4 | Admin changes to UNDER_REVIEW | Status updated |
| 5 | Admin reviews answers, finds error | Resolves with new marks |
| 6 | Marks updated from 12 to 16 | Percentage recalculated |
| 7 | Grade updated from C to B | Grade recalculated |
| 8 | Alice checks "My Grievances" | Sees RESOLVED with remarks |
| 9 | Activity log shows all 2 transitions | UNDER_REVIEW and RESOLVED logged |

#### TC-PS-21: Grievance Without Question Reference

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create grievance without question_id | question_id = null |
| 2 | Open show page | Question section not rendered |
| 3 | Verify no error | Page renders normally |

#### TC-PS-22: Resolution Without Remarks (Open Status Change)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Change status from OPEN to UNDER_REVIEW | Remarks not required |
| 2 | Leave remarks empty | Validation passes (not required for UNDER_REVIEW) |
| 3 | Verify status updated | Status = UNDER_REVIEW, resolution_remarks = null |

#### TC-PS-23: Multiple Grievances — Same Student, Different Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student has 3 exam results | 3 results |
| 2 | File grievance for each paper | 3 grievances |
| 3 | Search by student name | All 3 shown |
| 4 | Each lists correct paper in column | Correct paper reference |

#### TC-PS-24: Grievance Status Priority — Mixed Statuses

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 4 grievances: REJECTED, OPEN, RESOLVED, UNDER_REVIEW | One of each |
| 2 | Load index page | Order: OPEN, UNDER_REVIEW, RESOLVED, REJECTED |
| 3 | Verify priority override | Created_at order secondary within same status |

#### TC-PS-25: Grievance Marks Revised — Exam Result Audit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Resolve with mark change (15→18) | marks_changed=true |
| 2 | Check exam_results updated_at | Timestamp updated |
| 3 | Compare old vs new marks | old_marks=15, new_marks=18 |
| 4 | Verify percentage before/after | 75% → 90% |
| 5 | Verify grade before/after | C → A |

#### TC-PS-26: All Grievance Types Filter — Verify No Cross-Contamination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 1 grievance of each type | 4 grievances |
| 2 | Filter MARKING_ERROR | Only 1 shown |
| 3 | Clear filter, filter QUESTION_ERROR | Different 1 shown |
| 4 | Verify no overlap | Each filter returns correct subset |

#### TC-PS-27: Pagination — Last Page Partial

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 22 grievances | 22 records = 2 pages |
| 2 | Page 1: 20 records | Shows 1-20 |
| 3 | Page 2: 2 records | Shows 21-22 |
| 4 | Verify no page 3 | Only 2 pages total |

#### TC-PS-28: Index — With No Exams In Dropdown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no active exams exist | Exam table empty |
| 2 | Load index page | Exam dropdown shows "All Exams" only |
| 3 | No 500 error | Page renders with empty exam dropdown |

#### TC-PS-29: Stat Cards With Zero Counts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no grievances exist | All counts = 0 |
| 2 | Load index page | All 4 cards show "0" |
| 3 | Create 1 OPEN grievance | Open card shows "1", others "0" |

#### TC-PS-30: Store — Large Grievance Text At Limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate grievance_text = 5000 chars | At max limit |
| 2 | Submit store with this text | Accepted (boundary) |
| 3 | DB check: length = 5000 | Stored correctly |
| 4 | Show page displays full text | 5000 chars rendered |
