# lms_OnlineUpload_TcList

## Module: LmsExam → Upload Tab → Online Upload (Descriptive Assessment)

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Upload |
| Feature | Online Upload — Descriptive Assessment for Online Exams |
| URL(s) | `/lms-exam/upload` (parent tab), `GET /lms-exam/upload?active_tab=online_upload` (sub-tab), `lms-exam.exam.question-wise.data` (AJAX GET), `lms-exam.exam.question-wise.save` (AJAX POST), `lms-exam.exam.attemptDetail` (GET view), `lms-exam.exam.paper-set.view-questions` (GET), `lms-exam.exam.get-exams-by-class` (AJAX), `lms-exam.sections` (AJAX), `lms-exam.exam.get-subjects-by-class-section` (AJAX), `lms-exam.paper-sets` (AJAX), `lms-exam.students` (AJAX), `lms-exam.exam.get-papers-by-exam` (AJAX) |
| Controller | `Modules\LmsExam\Http\Controllers\LmsExamController` — methods: `uploadOnline()`, `uploadOffline()`, `getStudentsData()`, `getQuestionWiseData()`, `saveQuestionWiseMarks()`, `getExamsByClass()`, `getSections()`, `getSubjectsByClassSection()`, `getStudents()`, `getPapersByExam()`, `getPaperSets()` |
| Model(s) | `ExamAttempt`, `ExamAttemptAnswer`, `ExamPaper`, `ExamPaperSet`, `ExamAllocation`, `Exam`, `Student`, `SchoolClass`, `Section`, `Subject` |
| Validation (Save) | Inline controller validation via `$request->validate()` in `saveQuestionWiseMarks()` — student_id required, exam_paper_id required, attachments optional |
| Permissions | `tenant.answer-sheet-online-exam.view` (tab visibility), `tenant.online-assessment.view` (controller gate) |
| Soft Deletes | N/A for this feature |
| Activity Log | Not directly logged (marks update logged via attempt status changes) |
| File Upload | PDF/Images via FormData attachments, stored via `storageService->storeFile()` |
| Pagination | 10 per page (default Laravel paginate), `active_tab=online_upload` appended to pagination links |

---

## 2. Pre-conditions

- Required permissions: `tenant.answer-sheet-online-exam.view`, `tenant.online-assessment.view`
- Required seed data: At least one active `SchoolClass`, `Section`, `Subject`, `Exam` (mode=ONLINE), `ExamPaper` (mode=ONLINE), `ExamPaperSet`, `Student` allocated to the paper, `ExamAttempt` with status != NOT_STARTED
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- At least one online exam must have been taken by students (attempts exist with status IN_PROGRESS, SUBMITTED, EVALUATION_PENDING, EVALUATED, or RESULT_PUBLISHED)
- For question-wise modal: At least one descriptive question (Short Answer/Long Answer type) must exist in the paper set
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For file upload tests: Valid PDF or image file under 50MB

---

## 3. Default Data Load

When the page loads via `uploadOnline()` method, the following data is fetched and available:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: All Classes | LmsExamController@uploadOnline | SchoolClass::where('is_active',1)->orderBy('name') | is_active=1 | None |
| Shared: Sections | LmsExamController@uploadOnline | Section::all() | None | None |
| Shared: Subjects | LmsExamController@uploadOnline | Subject::all() | None | None |
| Shared: Exams | LmsExamController@uploadOnline | Exam::where('is_active',1)->orderBy('title') | is_active=1 | None |
| Students Data | LmsExamController (AJAX callback) | Allocated students with attempt data, roll_no, student_name, admn_no, attempt_status, is_evaluated | class_id, section_id, subject_id, exam_id, exam_paper_id, exam_set_id, student_id | 10/page |
| Question-Wise Data | getQuestionWiseData() AJAX | Descriptive questions from paper set with student's answer_id, attachment_data, qn_no, type | student_id, exam_paper_id, exam_set_id=0, mode=ONLINE | None |

Page initially shows empty table with "Please search to view online data." — data loads only when `active_tab=online_upload` is present in request.

---

## 4. Test Data Strategy

- **Unique suffix**: Use `now()->format('His') . random_int(100, 999)` for unique test student names
- **Attempt creation**: Create `ExamAttempt` records with status `SUBMITTED` or `EVALUATION_PENDING` for allocated students
- **Descriptive answers**: Create `ExamAttemptAnswer` records with `descriptive_answer` text and/or `attachment_data` JSON for non-MCQ questions
- **Pre-test cleanup**: Delete created attempts and answers before/after tests to avoid collision
- **File upload**: Use valid PDF files under 2MB for attachment tests; invalid files for negative tests
- **Session isolation**: Each test should clear session/storage data via `location.reload()` simulation
- **JSON fields**: `attachment_data` stored as JSON in `lms_exam_attempt_answers` table

---

## 5. Business Conditions

### 4.1 Database Schema — `lms_exam_attempt_answers`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT PK | Auto-increment |
| BC-DB-02 | attempt_id | BIGINT FK | NOT NULL, FK → `lms_exam_attempts.id`, ON DELETE CASCADE |
| BC-DB-03 | question_id | BIGINT FK | NOT NULL, FK → `qns_questions_bank.id` |
| BC-DB-04 | selected_option_id | BIGINT FK NULL | FK → `qns_question_options.id` |
| BC-DB-05 | selected_option_ids | JSON | NULL, stores multiple selected option IDs |
| BC-DB-06 | descriptive_answer | TEXT | NULL |
| BC-DB-07 | attachment_data | JSON | NULL, stores file metadata: file_name, file_path, mime_type, size |
| BC-DB-08 | marks_obtained | DECIMAL(8,2) | DEFAULT NULL |
| BC-DB-09 | max_marks | DECIMAL(8,2) | DEFAULT NULL |
| BC-DB-10 | is_evaluated | TINYINT(1) | DEFAULT 0 |
| BC-DB-11 | evaluation_remarks | TEXT | NULL |
| BC-DB-12 | change_count | INT | DEFAULT 0 |
| BC-DB-13 | is_active | TINYINT(1) | DEFAULT 1 |
| BC-DB-14 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-15 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

### 4.1b Database Schema — `lms_exam_attempts`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-16 | id | BIGINT PK | Auto-increment |
| BC-DB-17 | student_id | BIGINT FK | NOT NULL, FK → `sch_students.id` |
| BC-DB-18 | exam_paper_id | BIGINT FK | NOT NULL, FK → `lms_exam_papers.id` |
| BC-DB-19 | paper_set_id | BIGINT FK | NULL, FK → `lms_exam_paper_sets.id` |
| BC-DB-20 | status | ENUM | 'NOT_STARTED','IN_PROGRESS','SUBMITTED','EVALUATION_PENDING','EVALUATED','RESULT_PUBLISHED' |
| BC-DB-21 | is_evaluated | TINYINT(1) | DEFAULT 0 |
| BC-DB-22 | is_present_offline | TINYINT(1) | NULL |
| BC-DB-23 | actual_started_time | DATETIME | NULL |
| BC-DB-24 | actual_end_time | DATETIME | NULL |
| BC-DB-25 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-26 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

### 4.2 Validation Rules — `saveQuestionWiseMarks()` (Online Save)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | student_id | required, integer, exists:sch_students,id | — |
| BC-VAL-02 | exam_paper_id | required, integer, exists:lms_exam_papers,id | — |
| BC-VAL-03 | exam_set_id | required, integer | — |
| BC-VAL-04 | mode | required, string, in:ONLINE,OFFLINE | — |
| BC-VAL-05 | attachments[*] | file, mimes:pdf,jpeg,jpg,png, max:51200 | — |
| BC-VAL-06 | No attempt check (view) | If student has no attempt_id, button disabled with "No Attempt" | — |

### 4.3 Authorization (Permission Gates)

| BC ID | Permission | Method/View | Behavior |
|-------|-----------|-------------|----------|
| BC-AUTH-01 | tenant.answer-sheet-online-exam.view | upload.blade.php tab | Tab hidden if unauthorized |
| BC-AUTH-02 | tenant.online-assessment.view | uploadOnline() controller | Without → 403 |

### 4.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads without active_tab=online_upload | Table shows "Please search to view online data." |
| BC-BIZ-02 | Page loads with active_tab=online_upload and search filters | Student list fetched with attempt_status, is_evaluated, admn_no, roll_no |
| BC-BIZ-03 | Student with attempt_status != NOT_STARTED | Badge shows "Present" (bg-success) |
| BC-BIZ-04 | Student with attempt_status = NOT_STARTED | Badge shows "Not Started" (bg-secondary) |
| BC-BIZ-05 | Student with is_evaluated=1 | Badge shows "Yes" (bg-success) |
| BC-BIZ-06 | Student with is_evaluated=0 | Badge shows "No" (bg-warning) |
| BC-BIZ-07 | Student with attempt_id exists | Action buttons: Question-Wise Assessment + View Attempt Detail enabled |
| BC-BIZ-08 | Student without attempt_id | Action button: "No Attempt" disabled (bg-secondary) |
| BC-BIZ-09 | Question-Wise Assessment button clicked | AJAX GET to question-wise.data with student_id, exam_paper_id, exam_set_id=0, mode=ONLINE |
| BC-BIZ-10 | AJAX returns no descriptive questions | Modal shows "No descriptive questions found for this student." |
| BC-BIZ-11 | AJAX returns descriptive questions | Modal table shows Qn, Qn Type with tooltip, Attached Data (teacher) with file upload |
| BC-BIZ-12 | Existing attachment_data for a question | "View" badge displayed with file URL link |
| BC-BIZ-13 | Teacher uploads a file for a question | File input shows selected filename |
| BC-BIZ-14 | Teacher clicks "Save Assessment" | AJAX POST to question-wise.save with formData containing attachments keyed by answer_id |
| BC-BIZ-15 | Save success | SweetAlert "Saved!" shown, modal hidden, page reloaded |
| BC-BIZ-16 | Save failure | SweetAlert "Error" shown with message |
| BC-BIZ-17 | View Set Questions button clicked | Opens paper-set.view-questions route in new tab |
| BC-BIZ-18 | View Set Questions clicked without set selected | SweetAlert warning "Please select a Paper Set first." |
| BC-BIZ-19 | Cascading dropdown: Class changes | Exams, Sections, Subjects, Students all reloaded via AJAX |
| BC-BIZ-20 | Cascading dropdown: Exam changes | Papers reloaded via AJAX |
| BC-BIZ-21 | Cascading dropdown: Paper changes | Paper Sets reloaded via AJAX |
| BC-BIZ-22 | Student dropdown uses Select2 | Searchable multi-select with All Students default |
| BC-BIZ-23 | Pagination links appended with active_tab=online_upload | Correct tab maintained across pages |
| BC-BIZ-24 | Descriptive-only filter in modal | Only Short Answer/Long Answer type questions shown; MCQs excluded |
| BC-BIZ-25 | Tooltip on question type column | Full question text shown via Bootstrap tooltip |
| BC-BIZ-26 | View Attempt Detail opens in new tab | Link has target="_blank" |
| BC-BIZ-27 | Reset button in search bar | Clears all filters and reloads page without query params |

### 4.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | attempt_id | lms_exam_attempts (id) | CASCADE |
| BC-REF-02 | question_id | qns_questions_bank (id) | RESTRICT |
| BC-REF-03 | student_id | sch_students (id) | CASCADE |
| BC-REF-04 | exam_paper_id | lms_exam_papers (id) | CASCADE |
| BC-REF-05 | paper_set_id | lms_exam_paper_sets (id) | SET NULL |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Online Upload Page Loads With All UI Elements | Page loads with search bar, filters (Class, Section, Subject, Exam, Paper, Paper Set, Student), empty table with message "Please search to view online data." | — | — | ⬜ |
| TC-P02 | Load Students After Selecting All Filters | After selecting Class→Section→Subject→Exam→Paper→Paper Set and clicking Search, table populates with student data showing Admn No, Name, Exam, Paper, Paper Set, Attendance, Checked, Action | — | — | ⬜ |
| TC-P03 | Present Student Displayed With Green Badge | Student with attempt_status != NOT_STARTED shows "Present" badge (bg-success) | — | — | ⬜ |
| TC-P04 | Not Started Student Displayed With Grey Badge | Student with attempt_status = NOT_STARTED shows "Not Started" badge (bg-secondary) | — | — | ⬜ |
| TC-P05 | Evaluated Student Shows Yes Badge | Student with is_evaluated=1 shows "Yes" badge (bg-success) | — | — | ⬜ |
| TC-P06 | Non-Evaluated Student Shows No Badge | Student with is_evaluated=0 shows "No" badge (bg-warning) | — | — | ⬜ |
| TC-P07 | Action Buttons Enabled For Student With Attempt | Question-Wise Assessment (file-pen) and View Attempt Detail (eye) buttons visible and enabled | — | — | ⬜ |
| TC-P08 | Action Button Disabled For Student Without Attempt | "No Attempt" disabled button shown for student without attempt_id | — | — | ⬜ |
| TC-P09 | Question-Wise Modal Opens With Descriptive Questions | Clicking Question-Wise Assessment opens modal titled "Online Descriptive Assessment: [Student Name]" with table of descriptive questions | — | — | ⬜ |
| TC-P10 | Existing Attachment Shows View Badge | If student has previously uploaded file for a question, "View" badge with file URL is shown in the modal | — | — | ⬜ |
| TC-P11 | Teacher Uploads File For Descriptive Question | File input field shown for each descriptive question; teacher can select PDF/image file | — | — | ⬜ |
| TC-P12 | Save Assessment Success | Clicking Save Assessment sends AJAX POST; success SweetAlert shown, modal hides, page reloads | — | — | ⬜ |
| TC-P13 | Cascading Dropdown: Class → Exam | Selecting a Class loads Exams for that class via AJAX | — | — | ⬜ |
| TC-P14 | Cascading Dropdown: Class → Section | Selecting a Class loads Sections via AJAX | — | — | ⬜ |
| TC-P15 | Cascading Dropdown: Class → Subject | Selecting a Class loads Subjects via AJAX | — | — | ⬜ |
| TC-P16 | Cascading Dropdown: Class → Students | Selecting a Class loads Students list via AJAX | — | — | ⬜ |
| TC-P17 | Cascading Dropdown: Exam → Paper | Selecting an Exam loads Papers via AJAX | — | — | ⬜ |
| TC-P18 | Cascading Dropdown: Paper → Paper Set | Selecting a Paper loads Paper Sets via AJAX | — | — | ⬜ |
| TC-P19 | View Set Questions Button Opens New Tab | Clicking View Set Questions opens paper-set.view-questions route in new browser tab | — | — | ⬜ |
| TC-P20 | View Attempt Detail Opens New Tab | Clicking eye icon opens attempt detail page in new tab | — | — | ⬜ |
| TC-P21 | Pagination Maintains active_tab Parameter | Clicking page 2 keeps active_tab=online_upload in URL | — | — | ⬜ |
| TC-P22 | Reset Button Clears All Filters | Clicking reset icon removes all query params and reloads to initial empty state | — | — | ⬜ |
| TC-P23 | Select2 Student Dropdown Searchable | Student dropdown supports search-as-you-type via Select2 | — | — | ⬜ |
| TC-P24 | No Students Found Message | When no students match filter criteria, table shows "No students found for the selected criteria." | — | — | ⬜ |
| TC-P25 | Tooltip Shows Full Question Text | Hovering over question type in modal shows full question text via Bootstrap tooltip | — | — | ⬜ |
| TC-P26 | Filter By Specific Student | Selecting a specific student in dropdown filters the table to show only that student | — | — | ⬜ |
| TC-P27 | Multiple Students Displayed In Table | Table shows all allocated students for selected paper/set with correct roll numbers | — | — | ⬜ |
| TC-P28 | Modal Shows Correct Student Name | Modal title displays the student name passed from the button's onclick handler | — | — | ⬜ |
| TC-P29 | Save With No Files Selected | Clicking Save Assessment when no new files selected — formData has no attachments, save proceeds without error | — | — | ⬜ |
| TC-P30 | Full Flow: Filter → View Students → Open Modal → Save → Reload | Complete workflow: select filters, search, click student action, view modal, upload file, save, page reloads | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Search Without Subject Selected | Form submission prevented via HTML5 required attribute on subject select | — | — | ⬜ |
| TC-N02 | Search Without Exam Selected | Form submission prevented via HTML5 required attribute on exam select | — | — | ⬜ |
| TC-N03 | Search Without Paper Selected | Form submission prevented via HTML5 required attribute on paper select | — | — | ⬜ |
| TC-N04 | Search Without Paper Set Selected | Form submission prevented via HTML5 required attribute on exam set select | — | — | ⬜ |
| TC-N05 | Invalid File Type For Upload | Server returns error for non-PDF/image file uploads | — | — | ⬜ |
| TC-N06 | File Size Exceeds Limit | Server rejects files > 50MB with validation error | — | — | ⬜ |
| TC-N07 | Click Question-Wise For Student Without Descriptive Questions | Modal shows "No descriptive questions found for this student." | — | — | ⬜ |
| TC-N08 | AJAX Error During Question Data Load | SweetAlert shows error message "Failed to load data" | — | — | ⬜ |
| TC-N09 | AJAX Error During Save Assessment | SweetAlert shows error message "Server error" | — | — | ⬜ |
| TC-N10 | View Set Questions Without Paper Set Selected | SweetAlert warning: "Please select a Paper Set first." | — | — | ⬜ |
| TC-N11 | Permission Denied — Missing answer-sheet-online-exam.view | Tab not visible in upload page | — | — | ⬜ |
| TC-N12 | Permission Denied — Missing online-assessment.view | 403 Forbidden on upload page controller | — | — | ⬜ |
| TC-N13 | Guest Access Redirect | Redirected to /login for all routes | — | — | ⬜ |
| TC-N14 | Empty Class Selection Clears Dependent Dropdowns | Selecting "All Classes" resets Section, Subject, Exam, Paper, Paper Set, Student to empty/default states | — | — | ⬜ |
| TC-N15 | XSS Injection In Student Name | Student name with script tags rendered safely via Blade {{ }} escaping | — | — | ⬜ |
| TC-N16 | Invalid student_id in AJAX request | Server returns 404 or error for non-existent student_id | — | — | ⬜ |
| TC-N17 | Non-Integer student_id | Server returns validation error | — | — | ⬜ |
| TC-N18 | Non-Integer exam_paper_id | Server returns validation error | — | — | ⬜ |
| TC-N19 | Invalid File Path In Uploaded Attachment | View badge link 404s or shows placeholder | — | — | ⬜ |
| TC-N20 | Network Failure During Cascading Dropdown Load | Dropdown shows "Loading..." and then falls back gracefully | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Cascade: Attempt status change reflects in Online Upload | Updating attempt status to EVALUATED updates the Checked badge from No to Yes | — | — | ⬜ |
| TC-D02 | A | Cascade: Allocation change reflects in student list | Adding/removing student allocation updates the student list on reload | — | — | ⬜ |
| TC-D03 | B | Cascade: Paper Set change affects question list | Changing paper set questions changes the descriptive questions shown in modal | — | — | ⬜ |
| TC-D04 | C | Cascade: Marks saved via Online Upload update attempt is_evaluated | After saving assessment, attempt.is_evaluated becomes 1 | — | — | ⬜ |
| TC-D05 | D | Cascade: Student deletion cascades to attempts (CASCADE) | Deleting student from sch_students cascades to delete their exam attempts | — | — | ⬜ |
| TC-D06 | E | Cascade: Exam Paper deletion cascades to attempts (CASCADE) | Deleting a paper cascades to all student attempts for that paper | — | — | ⬜ |
| TC-D07 | F | Integration: Online Upload data source depends on ExamAllocation | Only allocated students appear in the search results | — | — | ⬜ |
| TC-D08 | G | Integration: Descriptive questions filtered by question_type_code | Only non-MCQ questions (Short Answer, Long Answer) loaded in modal | — | — | ⬜ |
| TC-D09 | H | Unit: Paginator append active_tab parameter | Pagination links contain `?active_tab=online_upload` | — | — | ⬜ |
| TC-D10 | I | Unit: FormData construction for save | attachments array keyed by answer_id correctly built from file inputs | — | — | ⬜ |
| TC-D11 | J | Cross-Module: File storage service integration | `storageService->storeFile()` correctly stores uploaded file and returns file info JSON | — | — | ⬜ |
| TC-D12 | K | DB: lms_exam_attempt_answers.attachment_data JSON format | JSON contains file_name, file_path, mime_type, size keys | — | — | ⬜ |
| TC-D13 | L | DB: FK CASCADE — delete exam_attempt deletes attempt_answers | Deleting from lms_exam_attempts cascades to lms_exam_attempt_answers | — | — | ⬜ |
| TC-D14 | M | Integration: Save marks updates both attempt_answers and attempt | Marks saved to attempt_answer; attempt.is_evaluated set to 1; status updated | — | — | ⬜ |
| TC-D15 | N | Unit: Descriptive question filter logic | Question type code must not contain 'MCQ', 'MULTIPLE', or 'MSQ' | — | — | ⬜ |
| TC-D16 | O | Integration: View Set Questions requires active paper set | Route paper-set.view-questions requires valid paper_set_id | — | — | ⬜ |
| TC-D17 | P | Integration: Tooltip initialization after AJAX load | Bootstrap tooltips initialized after question-wise modal content is loaded | — | — | ⬜ |
| TC-D18 | Q | DB \| P1 \| lms_exam_attempt_answers.attachment_data JSON validation | attachment_data stores file metadata in valid JSON; parseable by json_decode | — | — | ⬜ |
| TC-D19 | R | Unit \| P1 \| ExamAttempt model — is_evaluated casting | is_evaluated stored as TINYINT(1) but accessible as boolean via model casting | — | — | ⬜ |
| TC-D20 | S | Unit \| P1 \| ExamAttempt model — belongsTo Student relationship | attempt->student returns correct Student model; eager loading works | — | — | ⬜ |
| TC-D21 | T | Unit \| P1 \| ExamAttemptAnswer model — scope filtering by question type | Query filters correctly exclude MCQ types; returns only descriptive answer records | — | — | ⬜ |
| TC-D22 | U | Integration \| P1 \| Controller — findOrFail — question-wise.data with invalid combo | Invalid (student_id, exam_paper_id) combination returns JSON with success=false | — | — | ⬜ |
| TC-D23 | V | Integration \| P1 \| Controller — Gate::authorize before data load | Gate check performed before any data queries; unauthorized returns 403 | — | — | ⬜ |
| TC-D24 | W | Cross-Module \| P1 \| Storage Service — buildPath for online upload | Path includes session_code, class_id, exam_paper_id, student_id, attempt_id, uploader=teacher | — | — | ⬜ |
| TC-D25 | X | DEV \| P1 \| Blade view — @can directive for tab visibility | @can('tenant.answer-sheet-online-exam.view') wraps the include; unauthorized users don't see tab | — | — | ⬜ |
| TC-D26 | Y | DEV \| P1 \| JS — viewSetQuestions() reads exam-set-select value | Gets the correct select element within the same tab-pane; validates setId before opening | — | — | ⬜ |
| TC-D27 | Z | DEV \| P1 \| JS — handleOnlineUploadClick() sets global variables | Sets currentOnStudentId, currentOnPaperId, currentOnStudentName before AJAX call | — | — | ⬜ |
| TC-D28 | AA | DEV \| P1 \| JS — saveOnlineQuestionWise() builds FormData correctly | Iterates .on-qw-file inputs; appends only non-empty file inputs keyed by data-ansid | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for tab and search | Upload tab content wrapped in @can('tenant.answer-sheet-online-exam.view'); search form and table only visible when active_tab matches | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — DB Transactions in saveQuestionWiseMarks() for offline mode | DB::beginTransaction() wraps all create/update operations; DB::commit() on success, DB::rollback() on exception | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | $selectedPaper, $selectedSet, $selectedStudent checked with isset() before use; optional() operator used | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — JSON Success Response After Save | saveQuestionWiseMarks() returns response()->json() with success: true/false and message | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | JS — CSRF Token Included in AJAX Requests | All AJAX POST requests include _token field with csrf_token(); meta tag CSRF also used in headers | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | JS — Input Sanitization/Escaping | Teacher file input handles files safely; no direct HTML rendering of user input without escaping | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | View — Pagination Links With active_tab Parameter | $studentsData->links() appends active_tab to query string; condition checks method_exists before calling links() | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | JS — Select2 Initialization | select2() called on student-select only if $.fn.select2 exists; width set to 100%, allowClear enabled | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | Route — Named routes used consistently | All AJAX URLs use named routes (lms-exam.exam.question-wise.data, lms-exam.exam.question-wise.save, etc.) | — | — | ◌ |
| TC-CR10 | CR | Code Review | P1 | View — Blade {{ }} Escaping | All dynamic content rendered with {{ }} (double curly braces) for XSS protection | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Blade @can Directives — Permission-based Visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open upload.blade.php | Tab registration for online_upload found with permission key |
| 2 | Inspect @can('tenant.answer-sheet-online-exam.view') | The include of online_upload partial is wrapped in @can directive |
| 3 | Log in as user with permission | Online upload tab visible; content loads |
| 4 | Log in as user without permission | Tab hidden; no access to online upload content |

#### TC-CR02: Controller — DB Transactions in saveQuestionWiseMarks()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect saveQuestionWiseMarks() method | DB::beginTransaction() at start |
| 2 | Check try-catch block | Catch block has DB::rollback() |
| 3 | Check success path | DB::commit() after all operations |
| 4 | Simulate DB write failure | Transaction rolled back; no partial data |

#### TC-CR03: View — isset()/null-safe Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open online_upload.blade.php | View file found |
| 2 | Scan for $selectedPaper usage | isset($selectedPaper) or optional() used before accessing properties |
| 3 | Scan for $selectedSet usage | isset($selectedSet) guard present |
| 4 | Load page without selected paper | No undefined index/property errors; graceful fallback |
| 5 | Load page with null relations | No 500 errors; dash or empty values displayed |

#### TC-CR04: Controller — JSON Success Response After Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save assessment with valid data | AJAX POST returns JSON response |
| 2 | Verify JSON response after save | Contains success: true and message: 'Question wise marks uploaded successfully' |
| 3 | Save with invalid data | JSON with success: false and error message |
| 4 | Verify error status code | 422 for validation errors; 500 for server errors |

#### TC-CR05: JS — CSRF Token in AJAX Requests

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect saveOnlineQuestionWise() JS function | formData.append('_token', csrf_token()) present |
| 2 | Inspect AJAX setup | CSRF token from meta tag used in headers |
| 3 | Submit save without CSRF token | Server returns 419 CSRF mismatch error |
| 4 | Submit save with valid token | Request accepted; save proceeds |

#### TC-CR06: JS — Input Sanitization/Escaping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect file upload handling | Files appended directly from input.files[0] — no risky string manipulation |
| 2 | Inspect student name display in modal | addslashes() used in onclick handler for student_name |
| 3 | Attempt XSS via student name | Script not executed; escaped safely |

#### TC-CR07: View — Pagination Links With active_tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open pagination section in view | {{ $studentsData->links() }} with condition check |
| 2 | Verify active_tab append | Route URL maintains active_tab=online_upload across pagination |
| 3 | Navigate to page 2 | URL contains ?active_tab=online_upload&page=2 |

#### TC-CR08: JS — Select2 Initialization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect document.ready block | select2() called only if $.fn.select2 exists |
| 2 | Verify student dropdown has select2 | Dropdown searchable with placeholder "All Students" |
| 3 | Check allowClear setting | Clear button visible when selection made |

#### TC-CR09: Route — Named Routes Consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search for route() calls in view | All AJAX URLs use named routes, not hardcoded paths |
| 2 | Verify route names in web.php | Each named route exists with correct controller mapping |
| 3 | Test a route | Returns expected JSON response from controller |

#### TC-CR10: View — Blade Escaping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Scan all {{ }} expressions in view | All dynamic data output uses double curly braces |
| 2 | Search for {!! !!} (unescaped) usage | Not used for user-supplied content |
| 3 | Inject XSS via student name | Rendered as escaped HTML entity; no script execution |

### 6.1 Positive TC Steps

#### TC-P01: Online Upload Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Navigate to LmsExam → Upload tab | Page loads with tab structure |
| 3 | Click "Descriptive Ques (Online Exam)" sub-tab | URL updates to ?active_tab=online_upload |
| 4 | Check search bar | Class, Section, Subject, Exam, Paper, Paper Set, Student dropdowns visible |
| 5 | Check search/reset/view set buttons | Three buttons (search, reset, view questions) visible in button group |
| 6 | Check table headers | Admn No, Student Name, Exam, Paper, Paper Set, Attendance, Checked, Action visible |
| 7 | Check initial message | "Please search to view online data." displayed in table body |
| 8 | Check pagination area | Empty (no data yet) |

#### TC-P02: Load Students After Selecting All Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a Class from dropdown | Exam, Section, Subject, Student dropdowns populated via AJAX |
| 2 | Select a Section | Subject list filtered (optional) |
| 3 | Select a Subject | Filter set |
| 4 | Select an Exam | Paper dropdown populated |
| 5 | Select a Paper | Paper Set dropdown populated |
| 6 | Select a Paper Set | Filter set |
| 7 | Click Search button | Form submits via GET; page reloads with query params |
| 8 | Verify student table populated | Rows appear with Admn No, Name, Roll No, Paper, Set, Attendance badge, Checked badge, Action buttons |

#### TC-P03: Present Student Displayed With Green Badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure student has attempt with status != NOT_STARTED | Attempt exists for allocated student |
| 2 | Load Online Upload with filters for this student | Student appears in table |
| 3 | Check Attendance column | Green badge "Present" displayed |
| 4 | DB check: attempt status is SUBMITTED/IN_PROGRESS/EVALUATION_PENDING/EVALUATED | Confirmed |

#### TC-P04: Not Started Student Displayed With Grey Badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure student is allocated but has NOT_STARTED attempt | Attempt status = NOT_STARTED |
| 2 | Load Online Upload for this student | Student appears in table |
| 3 | Check Attendance column | Grey badge "Not Started" displayed |
| 4 | Verify action button disabled | "No Attempt" disabled button shown |

#### TC-P05: Evaluated Student Shows Yes Badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set attempt.is_evaluated = 1 | Student is evaluated |
| 2 | Load Online Upload | Student appears |
| 3 | Check Checked column | Green badge "Yes" displayed |

#### TC-P06: Non-Evaluated Student Shows No Badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set attempt.is_evaluated = 0 | Student not evaluated |
| 2 | Load Online Upload | Student appears |
| 3 | Check Checked column | Yellow badge "No" displayed |

#### TC-P07: Action Buttons Enabled For Student With Attempt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Allocate student to paper, create attempt | attempt_id exists |
| 2 | Load Online Upload | Student row renders |
| 3 | Check Action column | Both buttons (file-pen + eye) visible and enabled |
| 4 | Click file-pen button | Modal opens (via handleOnlineUploadClick) |
| 5 | Click eye button | Attempt detail opens in new tab |

#### TC-P08: Action Button Disabled For Student Without Attempt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Allocate student without creating attempt | No attempt_id |
| 2 | Load Online Upload | Student row renders |
| 3 | Check Action column | Single disabled button "No Attempt" shown |
| 4 | Verify button disabled | bg-secondary, pointer-events: none |

#### TC-P09: Question-Wise Modal Opens With Descriptive Questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click file-pen button on a student with attempt | Loading SweetAlert shows |
| 2 | Wait for AJAX response | SweetAlert closes |
| 3 | Verify modal opens | Modal titled "Online Descriptive Assessment: [Student Name]" |
| 4 | Check modal table | Columns: Qn, Qn Type (with tooltip icon), Attached Data (Teacher) |
| 5 | Verify only descriptive questions shown | No MCQ-type questions in the list |
| 6 | Verify file input fields | Each row has file input accepting PDF/image |

#### TC-P10: Existing Attachment Shows View Badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Previously upload attachment for a question | attachment_data JSON exists in DB |
| 2 | Open question-wise modal for this student | Question row shows "View" badge link |
| 3 | Click "View" badge | File opens/downloads in new tab |

#### TC-P11: Teacher Uploads File For Descriptive Question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open question-wise modal | Modal loaded with file inputs |
| 2 | Click file input on a question row | File browser opens |
| 3 | Select a valid PDF/image file | File name shown in input |
| 4 | Verify multiple files can be selected across questions | Each question's file input independent |

#### TC-P12: Save Assessment Success

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload files for descriptive questions | Files selected |
| 2 | Click "Save Assessment" button | Saving SweetAlert shown |
| 3 | AJAX POST sent to question-wise.save | FormData with _token, student_id, exam_paper_id, exam_set_id, attachments |
| 4 | Wait for response | Success SweetAlert "Saved! Descriptive marks updated successfully." |
| 5 | Modal hides | Modal dismissed |
| 6 | Page reloads | Location.reload() called |

#### TC-P13: Cascading Dropdown — Class → Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a Class from dropdown | Class value set |
| 2 | Check Exam dropdown | Options loaded from AJAX; exam list shows only exams for selected class |
| 3 | Verify previous selection preserved | If request('exam_id') matches, it's pre-selected |

#### TC-P14: Cascading Dropdown — Class → Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a Class | Section dropdown populated |
| 2 | Check sections match class | Sections filtered by class_id |

#### TC-P15: Cascading Dropdown — Class → Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a Class | Subject dropdown populated |
| 2 | Verify subjects filtered by class | Only subjects linked to that class shown |

#### TC-P16: Cascading Dropdown — Class → Students

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a Class | Student dropdown populated via AJAX |
| 2 | Verify students show name and code | Format: "Name (code)" in Select2 |
| 3 | Verify "All Students" default option | First option is "All Students" |

#### TC-P17: Cascading Dropdown — Exam → Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select an Exam | Paper dropdown populated |
| 2 | Verify papers belong to selected exam | Only papers with exam_id matching shown |
| 3 | If no papers, "No Papers Available" shown | Options reflect empty state |

#### TC-P18: Cascading Dropdown — Paper → Paper Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a Paper | Paper Set dropdown populated |
| 2 | Verify sets belong to selected paper | Sets with exam_paper_id matching shown |
| 3 | No sets scenario | "No Paper Sets Available" shown |

#### TC-P19: View Set Questions Button Opens New Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a Paper Set | Set ID present |
| 2 | Click "View Set Questions" button | window.open called with paper-set.view-questions route |
| 3 | Verify new tab opens | Browser opens new tab with question details |

#### TC-P20: View Attempt Detail Opens New Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click eye icon for student with attempt | New tab opens |
| 2 | Verify URL is attemptDetail route | Route lms-exam.exam.attemptDetail with attempt_id |
| 3 | Verify attempt detail page loads correctly | Student answers, status, timings displayed |

#### TC-P21: Pagination Maintains active_tab Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load Online Upload with data > 10 rows | Pagination links appear |
| 2 | Click page 2 | URL contains ?active_tab=online_upload&page=2 |
| 3 | Verify online upload tab remains active | Table still shows online upload data |

#### TC-P22: Reset Button Clears All Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filters via search | URL has query params |
| 2 | Click reset (rotate-right) button | URL cleared; page reloads without params |
| 3 | Verify empty state returns | "Please search to view online data." shown |

#### TC-P23: Select2 Student Dropdown Searchable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click student dropdown | Select2 widget opens |
| 2 | Type partial student name | Select2 filters options in real-time |
| 3 | Select a student | Value set; display shows student name |
| 4 | Click clear (x) on Select2 | Value cleared; "All Students" restored |

#### TC-P24: No Students Found Message

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a Class with no allocated students | Empty allocation |
| 2 | Click Search | Table shows "No students found for the selected criteria." |
| 3 | Verify colspan covers all 8 columns | Message spans full width |

#### TC-P25: Tooltip Shows Full Question Text

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open question-wise modal for a student with descriptive answers | Questions loaded |
| 2 | Hover over question type cell with info icon | Tooltip popup shows full question text |
| 3 | Verify tooltip initialization runs after AJAX load | Tooltips initialized in success callback |

#### TC-P26: Filter By Specific Student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select student in dropdown | Student ID set in filter |
| 2 | Click Search | Only that student's data shown |
| 3 | Verify single student row | One row in table matching selected student |

#### TC-P27: Multiple Students Displayed In Table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select paper with 5 allocated students | 5 allocations exist |
| 2 | Click Search | Table shows 5 rows |
| 3 | Verify each student's roll_no displayed | Roll No prefix in student name column |

#### TC-P28: Modal Shows Correct Student Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Question-Wise Assessment for Student A | Modal opens |
| 2 | Verify modal title | "Online Descriptive Assessment: [Student A Name]" |
| 3 | Close modal | Modal dismissed |
| 4 | Click for Student B | Modal title shows Student B name |

#### TC-P29: Save With No Files Selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open question-wise modal | Modal with empty file inputs |
| 2 | Click "Save Assessment" without selecting any files | FormData sent without attachments |
| 3 | Verify success response | Server saves empty assessment; success returned |
| 4 | Verify page reloads | Location.reload() after success |

#### TC-P30: Full Flow: Filter → View Students → Open Modal → Save → Reload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class, Section, Subject, Exam, Paper, Paper Set | All filters set |
| 2 | Click Search | Student table populated |
| 3 | Click Question-Wise Assessment on first student | Modal opens with descriptive questions |
| 4 | Upload file for a question | File selected |
| 5 | Click Save Assessment | AJAX POST; success response |
| 6 | Verify page reloads | Browser refreshes; modal gone |
| 7 | Verify Checked badge updates | If marks saved, badge may update to "Yes" |

### 6.2 Negative TC Steps

#### TC-N11: Permission Denied — Missing answer-sheet-online-exam.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Remove permission from user | Permission revoked |
| 2 | Login as that user | Dashboard loads |
| 3 | Navigate to Upload page | Tab "Descriptive Ques (Online Exam)" not visible |
| 4 | Check only offline tab visible | Only offline tab shown (if permission granted for that) |

#### TC-N12: Permission Denied — Missing online-assessment.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Remove tenant.online-assessment.view | Permission revoked |
| 2 | Access upload URL directly | 403 Forbidden error |

### 6.3 Dependency TC Steps

#### TC-D01: Cascade — Attempt Status Update Reflects

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load online upload showing student with "Not Started" | Status NOT_STARTED |
| 2 | Create attempt record with status SUBMITTED | DB updated |
| 3 | Reload online upload page | Student now shows "Present" badge |
| 4 | Set is_evaluated=1 | Badge changes from "No" to "Yes" on reload |

#### TC-D02: Cascade — Allocation Change Reflects

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load upload page with existing allocations | Students displayed |
| 2 | Remove a student's allocation in DB | Allocation deleted |
| 3 | Reload page | That student no longer appears |
| 4 | Add new allocation | Student appears on reload |

#### TC-D07: Integration — Allocation Dependency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create student without allocation for a paper | Student exists in system |
| 2 | Load upload page for that paper | Student not shown |
| 3 | Create allocation record | Student now appears on reload |
| 4 | Verify only allocated students shown | Non-allocated students excluded |

#### TC-D08: Integration — Descriptive Question Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper set with mix of MCQ and descriptive questions | Question types mixed |
| 2 | Student submits attempt answering all questions | Answers exist |
| 3 | Open question-wise modal | Only descriptive questions shown |
| 4 | Verify MCQ questions excluded | No MCQ rows in modal table |

#### TC-D11: Cross-Module — Storage Service Integration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload a file via save | storageService->storeFile() called |
| 2 | Verify file stored at correct path | Path structure: session_code/class_id/exam_paper_id/student_id/attempt_id/ |
| 3 | Verify file info JSON returned | Contains file_name, file_path, mime_type, size |
| 4 | Verify file accessible via URL | getFileUrl() returns valid URL |

#### TC-D12: DB — attachment_data JSON Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save assessment with file upload | attachment_data written to DB |
| 2 | Query lms_exam_attempt_answers | attachment_data contains valid JSON |
| 3 | Verify JSON keys | file_name, file_path, mime_type, size all present |
| 4 | Parse JSON | No parse errors; values match uploaded file |

#### TC-D13: DB — FK CASCADE on Attempt Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create attempt with answer records | Both tables have data |
| 2 | Delete attempt from lms_exam_attempts | Record deleted |
| 3 | Check lms_exam_attempt_answers | Related answer records also deleted |
| 4 | Verify CASCADE constraint | ON DELETE CASCADE on FK attempt_id |

#### TC-D14: Integration — Save Marks Updates Both Tables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save assessment marks | AJAX POST to question-wise.save |
| 2 | Check lms_exam_attempt_answers | marks_obtained updated for each question |
| 3 | Check lms_exam_attempts | is_evaluated = 1 |
| 4 | Verify status progression | Status may be updated to EVALUATED |

### 6.4 Code Review TC Steps

#### TC-CR02: Controller — DB Transactions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open LmsExamController.php | Controller file at Modules/LmsExam/Http/Controllers/ |
| 2 | Inspect saveQuestionWiseMarks() | DB::beginTransaction() wraps all operations |
| 3 | Verify commit on success | DB::commit() called before success response |
| 4 | Verify rollback on exception | Catch block calls DB::rollback() |
| 5 | Test with DB failure | No partial data; transaction rolled back |

#### TC-CR09: Route — Named Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search web.php for route names | All named routes defined |
| 2 | Test route('lms-exam.exam.question-wise.data') | Returns question-wise data |
| 3 | Test route('lms-exam.exam.question-wise.save') | POST accepted |
| 4 | Test missing route parameter | Route model binding works for paper-set.view-questions |

#### TC-N13: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout from application | Session cleared |
| 2 | Access upload URL directly | Redirected to /login |
| 3 | Login with valid credentials | Redirect back to upload page |

#### TC-N14: Empty Class Selection Clears Dependent Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a Class and populate all dependents | All dropdowns populated |
| 2 | Change Class to "All Classes" (empty value) | Section, Subject, Exam, Paper, Set, Student all reset to defaults |
| 3 | Verify no stale data in dropdowns | All show placeholder options |

#### TC-N15: XSS Injection In Student Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update student name to include script tag | Name stored in DB with script |
| 2 | Load online upload page | Student name displayed as text; script not executed |
| 3 | Inspect HTML source | &lt;script&gt; shown as escaped entities |

#### TC-N16: Invalid student_id in AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manually send AJAX GET with non-existent student_id | JSON response with success=false |
| 2 | Verify error message | Descriptive error returned |
| 3 | Check server logs | No fatal error/exception |

#### TC-N17: Non-Integer student_id Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send request with student_id='abc' | Validation or SQL error handled gracefully |
| 2 | Send request with student_id=null | Validation error returned |
| 3 | Verify proper error response | JSON with error message; no 500 crash |

#### TC-N18: Non-Integer exam_paper_id Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send request with exam_paper_id='xyz' | Server handles gracefully |
| 2 | Check response | Error message returned |
| 3 | Verify no DB exception | Exception caught; rolled back |

#### TC-N19: Invalid File Path In Attachment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manually edit attachment_data with invalid path | JSON in DB has wrong path |
| 2 | Open question-wise modal | "View" badge shown with broken link |
| 3 | Click "View" | 404 or file not found error |
| 4 | Check UI doesn't crash | Other questions load fine; error is isolated |

#### TC-N20: Network Failure During Cascading Dropdown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Disconnect network | Internet off |
| 2 | Select a Class | Dependent dropdowns show "Loading..." |
| 3 | Wait for AJAX fail | fallback handler called; dropdowns reset to defaults |
| 4 | Verify user can retry | Reconnect; re-select; dropdowns populate correctly |

### 6.4 Code Review TC Steps (Continued)

#### TC-CR11: JS — AJAX Error Handling in Cascading Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect class change handler | .fail() callback on AJAX calls for students |
| 2 | Simulate network failure on student load | Student dropdown falls back to "All Students" |
| 3 | Verify other dropdowns unaffected | Section, Subject, Exam still show placeholder |

#### TC-CR12: View — Hidden Inputs for Tab State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect search form HTML | Two hidden inputs: name=active_tab value=online_upload, name=tab value=online_upload |
| 2 | Submit form | Both hidden fields included in GET params |
| 3 | Verify tab persistence | After form submit, active_tab=online_upload preserved |

#### TC-CR13: JS — Modal Bootstrap Initialization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect modal HTML | Bootstrap modal with id=onlineQuestionWiseModal |
| 2 | Check modal-xl class | Wide modal for question assessment |
| 3 | Verify modal-dialog-scrollable | Scrollable content for many questions |
| 4 | Inspect close button | btn-close-white on info header |

#### TC-CR14: Controller — applyExamFilters Method Usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect uploadOnline() method | Does NOT call applyExamFilters (unlike assessment) |
| 2 | Verify data loading pattern | Students loaded via separate AJAX/data endpoints |
| 3 | Check query parameter handling | Request inputs passed directly to view for filter persistence |

#### TC-CR15: JS — Form Submit Handler

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect search form | Standard GET form, no preventDefault |
| 2 | Submit form | Browser navigates to same URL with query params |
| 3 | Verify active_tab preserved | active_tab=online_upload in query string |

#### TC-CR16: View — Empty State Messages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No active_tab match | "Please search to view online data." with colspan=8 |
| 2 | active_tab matches but no data | "No students found for the selected criteria." with colspan=8 |
| 3 | Verify distinct messages | Two different strings for two different states |

#### TC-CR17: JS — Tooltip Initialization After AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect question-wise data success callback | Bootstrap tooltip initialization code runs after HTML is injected |
| 2 | Verify selector | document.querySelectorAll('[data-bs-toggle="tooltip"]') used |
| 3 | Verify new bootstrap.Tooltip() called | Each tooltip element initialized |

#### TC-CR18: View — Addslashes for Student Name in onclick

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect button onclick handler | addslashes($student->student_name) used in JS string |
| 2 | Student name with apostrophe (e.g., O'Brien) | JS string not broken; modal shows correct name |
| 3 | Student name with quotes | Escaped properly; no JS syntax error |

#### TC-CR19: View — Request Value Checks for Pre-selection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect class select | request('class_id') === (string)$class->id ? 'selected' : '' |
| 2 | Inspect section select | request('section_id') == $section->id ? 'selected' : '' |
| 3 | Verify pre-selection works on page reload | Filters persist after form submit |

#### TC-CR20: JS — Select2 Configuration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect select2 initialization | width: '100%', placeholder: "All Students", allowClear: true |
| 2 | Verify feature check | if ($.fn.select2) guard before initialization |
| 3 | Test Select2 functionality | Searchable dropdown with clear option |

### Additional Positive TC Steps

#### TC-P31: View Set Questions With Multiple Paper Sets

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with 3 active paper sets | Paper has Set A, Set B, Set C |
| 2 | Select Set A | Set A selected |
| 3 | Click View Set Questions | Opens Set A questions |
| 4 | Switch to Set B, click View | Opens Set B questions with different content |

#### TC-P32: Question-Wise Modal With Multiple Pages of Questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper set with 20 descriptive questions | 20 questions in set |
| 2 | Open question-wise modal | Modal-dialog-scrollable enables scrolling |
| 3 | Scroll through questions | All 20 questions visible via scroll |
| 4 | Verify no pagination needed | Single scrollable list |

#### TC-P33: Upload Multiple Files In Single Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open modal with 5 descriptive questions | 5 file inputs |
| 2 | Select files for questions 1, 3, 5 | 3 files selected |
| 3 | Click Save Assessment | FormData contains 3 attachments keyed by answer_id |
| 4 | Verify each file saved independently | Each question's attachment_data updated only if file uploaded |

#### TC-P34: Re-upload File For Previously Uploaded Question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open modal; question has existing attachment | "View" badge shown |
| 2 | Select a new file for the same question | File input shows new filename |
| 3 | Save Assessment | Old attachment replaced with new file |
| 4 | Verify old file removed from storage | Only new file exists in storage path |

#### TC-P35: Filter Preserved After Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply class_id=5, subject_id=10 filters | Query params set |
| 2 | Click page 2 | URL contains &class_id=5&subject_id=10&page=2 |
| 3 | Verify filters applied on page 2 | Same filtered data, different page |

#### TC-P36: Section Change Re-filters Subjects

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class A (no section selected) | Subjects for Class A loaded |
| 2 | Select Section B | Subjects re-fetched with Class A + Section B |
| 3 | Verify subject list updated | Subjects may be filtered further by section |

#### TC-P37: Exam Change Without Class Selection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Do not select any Class | Exam dropdown shows "Loading..." state |
| 2 | Check exam dropdown | Populated via AJAX when class selected first |
| 3 | Verify cascading requirement | Exams require a class to be selected first |

#### TC-P38: Paper Set Change Updates Question Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Paper A (has Set X and Set Y) | Both sets shown |
| 2 | Select Set X | Set X selected |
| 3 | Click View Set Questions | Questions for Set X shown |
| 4 | Switch to Set Y | View Set Questions now shows Set Y questions |

#### TC-P39: Loading State During AJAX Cascading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a class with slow network | Dependent dropdowns show "Loading..." option |
| 2 | Wait for AJAX completion | Options replaced with actual data |
| 3 | Verify no duplicate options | Clean replacement; no stale options preserved |

#### TC-P40: Cross-Tab Navigation Maintains Upload State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Upload tab | Upload page loads |
| 2 | Switch from online_upload to offline_upload tab | Tab switches; data reloads |
| 3 | Switch back to online_upload | Previous filter state (via URL) preserved |

### Additional Negative TC Steps

#### TC-N21: AJAX Call Without Required Parameters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call question-wise.data without student_id | Server returns error |
| 2 | Call question-wise.data without exam_paper_id | Server returns error |
| 3 | Verify proper error handling | No 500 crash; JSON error returned |

#### TC-N22: Save Assessment Without student_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manually craft POST request without student_id | Validation error |
| 2 | Check response | Server returns 422 with validation message |

#### TC-N23: Consecutive Rapid Saves

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Save Assessment multiple times rapidly | Only first request processes; subsequent blocked or idempotent |
| 2 | Verify no duplicate records | Single set of marks saved |
| 3 | Check loading state | Button disabled during save; no concurrent saves |

#### TC-N24: Large Number of Students (Performance)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Allocate 100+ students to a paper | Many allocations |
| 2 | Load online upload page | Data loads within acceptable time |
| 3 | Verify pagination works | Pages split data into 10 per page |
| 4 | Check page load time | < 5 seconds for 100+ students |

#### TC-N25: Corrupted attachment_data JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manually set attachment_data to invalid JSON | DB has corrupted data |
| 2 | Open question-wise modal | Server handles parse error gracefully |
| 3 | Check "View" badge behavior | No badge shown or fallback display |
