# lms_OfflineAssessment_TcList

## Module: LmsExam → Assessment Tab → Offline Assessment (Summary & Paper Check)

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Assessment |
| Feature | Offline Assessment — Summary Dashboard, Question-Wise Offline Check, Bulk Total Check |
| URL(s) | `/lms-exam/assessment` (parent), `GET /lms-exam/assessment?active_tab=offline_assessment` (summary), `lms-exam.exam.report` (report), `lms-exam.exam.attemptDetail` (student result), `lms-exam.exam.paper-check-offline` (question-wise offline check), `lms-exam.exam.paper-check.bulk` (bulk total check), `lms-exam.exam.paper-check.bulk-save` (AJAX POST bulk save), `lms-exam.exam.paper-check.bulk-upload-pdf` (AJAX POST bulk PDF), `lms-exam.exam.question-wise.data-offline` (AJAX GET), `lms-exam.exam.question-wise.save-offline` (AJAX POST), `lms-exam.exam.paper-check.submit-grade-offline` (PUT), `lms-exam.exam.paper-check.get-files` (AJAX GET), `lms-exam.exam.paper-check.get-attachment-offline` (AJAX GET) |
| Controller | `Modules\LmsExam\Http\Controllers\LmsExamController` — methods: `assessment()`, `examPaperCheckOffline()`, `examPaperCheckBulk()`, `saveBulkGrades()`, `getEvaluationStudents()`, `getEvaluationQuestions()`, `getQuestionWiseDataOffline()`, `saveQuestionWiseMarksOffline()`, `getStudentAttachment()`, `getFiles()`, `report()`, `attemptDetail()` |
| Model(s) | `ExamPaper`, `ExamAttempt`, `ExamResult`, `OfflineExamUploadMark`, `OfflineExamUploadDetail`, `ExamAllocation`, `ExamPaperSet`, `PaperSetQuestion`, `QuestionBank`, `Student`, `ClassSection`, `StudentAcademicSession` |
| Permissions | `tenant.offline-assessment.view`, `tenant.exam.viewAny` |
| Pagination | Summary: 10/page; Report: 25/page |
| JS Libraries | pdf.js, jspdf, Chart.js, Bootstrap Icons, SweetAlert2, daterangepicker |
| Annotation Tools | Marks, View, Correct, Wrong, Repeat, Blank, Comment, Text Box, Freehand Pen |

---

## 2. Pre-conditions

- Required permissions: `tenant.offline-assessment.view`, `tenant.exam.viewAny`
- Required seed data: At least one `ExamPaper` with `mode=OFFLINE`, allocated students
- For question-wise check: Paper with `offline_entry_mode=QUESTION_WISE` or `is_ques_wise_file_upload=1`
- For bulk check: Paper with `offline_entry_mode=BULK_TOTAL` and `is_ques_wise_file_upload=0`
- Attempt stubs are auto-created for offline question-wise papers when paper check loads
- For bulk check: Allocated students with uploaded answer sheet PDFs
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

When the assessment page loads via `assessment()` method, both online and offline summaries are loaded:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Offline Summary | assessment() clone, mode=OFFLINE | ExamPaper with exam, class, subject, status; withCount(allocations, attempts) | class_section_id, subject_id, exam_id, exam_paper_id, exam_set_id, date_from, date_to, search | 10/page |
| Question-Wise Check | examPaperCheckOffline() | All allocated students; auto-creates EVALUATION_PENDING attempt stubs | Paper ID | None |
| Bulk Check | examPaperCheckBulk() | Students resolved from allocations (CLASS/SECTION/STUDENT types) | Paper ID | None |

---

## 4. Test Data Strategy

- **Paper creation**: Create papers with `mode=OFFLINE` and varying `offline_entry_mode` + `is_ques_wise_file_upload` combos
- **Attempt stubs**: For question-wise offline, attempts auto-created with status EVALUATION_PENDING
- **Bulk assessment**: Create `ExamResult` records with `total_marks_obtained` for evaluated students
- **Answer sheets**: Upload PDF files via `OfflineExamUploadMark.attachment_data`
- **Pre-test cleanup**: Delete created ExamAttempt, ExamResult, OfflineExamUploadMark records
- **File upload**: Valid PDF under 2MB for paper check PDF viewer

---

## 5. Business Conditions

### 5.1 Database Schema — `lms_exam_papers` (Offline-specific)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT PK | Auto-increment |
| BC-DB-02 | mode | ENUM('ONLINE','OFFLINE') | Must be OFFLINE for offline assessment |
| BC-DB-03 | offline_entry_mode | ENUM('BULK_TOTAL','QUESTION_WISE') | Determines paper check interface |
| BC-DB-04 | is_ques_wise_file_upload | TINYINT(1) | Override: if 1, question-wise check even for BULK_TOTAL |
| BC-DB-05 | total_marks | DECIMAL(8,2) | Max marks for the paper |
| BC-DB-06 | passing_percentage | DECIMAL(5,2) | DEFAULT 0 |

### 5.2 Database Schema — `lms_exam_attempts` (Offline)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-07 | id | BIGINT PK | Auto-increment |
| BC-DB-08 | student_id | BIGINT FK | NOT NULL |
| BC-DB-09 | exam_paper_id | BIGINT FK | NOT NULL |
| BC-DB-10 | status | ENUM | Includes EVALUATION_PENDING for auto-created stubs |
| BC-DB-11 | attempt_mode | VARCHAR | 'OFFLINE' |
| BC-DB-12 | is_present_offline | TINYINT(1) | NULL |

### 5.3 Database Schema — `lms_exam_results`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-13 | id | BIGINT PK | Auto-increment |
| BC-DB-14 | exam_attempt_id | BIGINT FK | NOT NULL, FK → lms_exam_attempts.id |
| BC-DB-15 | total_marks_obtained | DECIMAL(8,2) | NULL |
| BC-DB-16 | total_marks_possible | DECIMAL(8,2) | NULL |
| BC-DB-17 | percentage | DECIMAL(5,2) | NULL |
| BC-DB-18 | result_status | ENUM('PASS','FAIL','PENDING') | NULL |
| BC-DB-19 | is_published | TINYINT(1) | DEFAULT 0 |
| BC-DB-20 | teacher_remarks | TEXT | NULL |

### 5.4 Validation Rules

| BC ID | Field/Scope | Rule | Error Message |
|-------|-------------|------|---------------|
| BC-VAL-01 | student_marks (bulk save) | required array | "student_marks is required" |
| BC-VAL-02 | student_marks.*.marks | nullable, numeric | Must be valid number |
| BC-VAL-03 | student_marks.*.student_id | required | Must exist |

### 5.5 Authorization

| BC ID | Permission | Effect |
|-------|------------|--------|
| BC-AUTH-01 | tenant.offline-assessment.view | Summary tab access |
| BC-AUTH-02 | tenant.exam.viewAny | report(), examPaperCheckOffline(), examPaperCheckBulk() |

### 5.6 Business Logic

| BC ID | Rule | Description |
|-------|------|-------------|
| BC-BIZ-01 | Summary Mode Filter | assessment() clones query; offline mode=OFFLINE |
| BC-BIZ-02 | Action Button Logic | If `is_ques_wise_file_upload == 1` → paper-check-offline route; else → paper-check.bulk |
| BC-BIZ-03 | Attempt Stub Auto-Creation | examPaperCheckOffline() creates EVALUATION_PENDING attempts for allocated students without existing attempts |
| BC-BIZ-04 | Bulk Check — Redirect Prevention | examPaperCheckBulk() redirects to online paper-check if mode=ONLINE or offline_entry_mode=QUESTION_WISE or is_ques_wise_file_upload=1 |
| BC-BIZ-05 | Bulk Check — Allocation Resolution | Resolves CLASS, SECTION, STUDENT allocation types; excludes EXAM_GROUP |
| BC-BIZ-06 | Bulk Check — First Student Auto-Selected | First allocation row has `table-primary` class and radio checked |
| BC-BIZ-07 | Bulk Grade Save | Iterates student_marks array; creates/updates ExamResult for each non-null marks entry |
| BC-BIZ-08 | Offline Check — Default Set | Uses first active ExamPaperSet for stub creation when paper_set_id is null |
| BC-BIZ-09 | Summary Badge Logic | Offline mode badge; if is_ques_wise=1 shows "Question Wise", else "Bulk" |
| BC-BIZ-10 | Report Same as Online | report() and attemptDetail() are shared between online and offline |

### 5.7 Referential Integrity

| BC ID | Constraint | Description |
|-------|------------|-------------|
| BC-REF-01 | lms_exam_results.exam_attempt_id → lms_exam_attempts.id | Result belongs to attempt |
| BC-REF-02 | lms_exam_attempts.exam_paper_id → lms_exam_papers.id | Attempt belongs to paper |
| BC-REF-03 | exam_attempts.student_id → sch_students.id | Student must exist |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Scenario | Steps | Expected Result |
|-------|----------|-------|-----------------|
| TC-P01 | Load offline assessment tab | Navigate to `/lms-exam/assessment?active_tab=offline_assessment` | Summary table shows offline papers |
| TC-P02 | Offline mode badge | Paper has mode=OFFLINE | Badge "Offline" (bg-secondary) |
| TC-P03 | Bulk entry mode badge | Paper with BULK_TOTAL + is_ques_wise=0 | "Bulk" badge (bg-light) |
| TC-P04 | Question-wise entry mode badge | Paper with is_ques_wise_file_upload=1 | "Question Wise" badge (bg-light) |
| TC-P05 | Assigned/Submitted/Checked counts | Paper with allocations/attempts | Correct badge counts |
| TC-P06 | Check button — BULK_TOTAL | Paper with BULK_TOTAL, is_ques_wise=0 | Check button (btn-outline-warning) links to paper-check.bulk |
| TC-P07 | Check button — QUESTION_WISE | Paper with is_ques_wise=1 | Check button (btn-outline-info) links to paper-check-offline |
| TC-P08 | Report button | Click Report for offline paper | Report page opens with stats |
| TC-P09 | Bulk Check — student list loads | Open bulk check interface | Left panel shows all students with marks column |
| TC-P10 | Bulk Check — first student auto-selected | Load bulk page | First student radio checked; row highlighted (table-primary) |
| TC-P11 | Bulk Check — student row click selects | Click another student row | Radio selected; row highlighted |
| TC-P12 | Bulk Check — PDF auto-loads | Select student with uploaded PDF | PDF loads in center viewer |
| TC-P13 | Bulk Check — marks shown | Student with existing marks | "Given Mark" column shows marks in green |
| TC-P14 | Bulk Check — marks pending | Student without marks | "Given Mark" shows "-" (text-muted) |
| TC-P15 | Bulk Check — PDF viewer nav | Click prev/next page | Page changes; indicator updates |
| TC-P16 | Bulk Check — zoom controls | Click zoom in/out | PDF scales |
| TC-P17 | Bulk Check — annotation tools | Use Mark/Correct/Wrong tools | Annotations placed on PDF |
| TC-P18 | Bulk Check — Save button | Click Save | Bulk save AJAX called |
| TC-P19 | Bulk Check — Grade Modal | Click Final Review | Modal opens with Status, Marks, Feedback fields |
| TC-P20 | Bulk Check — Submit Grade | Fill form, click Submit Grade | Grade saved; success toast |
| TC-P21 | Offline Question-Wise Check — attempt stubs | Load page for paper with 0 existing attempts | Stub attempts created (EVALUATION_PENDING) for all allocated students |
| TC-P22 | Offline QW Check — student selector | Page loads | Student dropdown populated with all allocated students |
| TC-P23 | Offline QW Check — marks list | Select student | Left panel shows question list with Q#, Max, Marks, Action |
| TC-P24 | Offline QW Check — total score | Marks entered | Top shows "X / Y" total score |
| TC-P25 | Offline QW Check — PDF loads | Student with uploaded answer sheet | PDF shown in viewer |
| TC-P26 | Offline QW Check — annotation | Use annotation tools | Annotations rendered |
| TC-P27 | Offline QW Check — Grade Modal | Click Final Review | Modal with grading form |
| TC-P28 | Offline QW Check — Submit Grade | Click Submit Grade | Grade submitted |
| TC-P29 | Summary filter — class_section | Select filter, search | Papers filtered |
| TC-P30 | Summary filter — date range | Select date range | Auto-submits; papers filtered |
| TC-P31 | Summary pagination | 10+ offline papers | Pagination links shown |
| TC-P32 | Reset filters | Apply filters, click refresh | Filters cleared |
| TC-P33 | Report for offline paper | Click Report | Same report layout as online |
| TC-P34 | View Result from report | Click View Result | Student result page |
| TC-P35 | Student result — pass/fail | Evaluate offline student | Pass/fail badges correct |
| TC-P36 | Bulk Check — upload new PDF | Click upload in bulk interface | PDF uploaded; new file shown |
| TC-P37 | Offline QW Check — multi-page PDF | Student submits multi-page | All pages navigable |
| TC-P38 | Offline QW Check — auto-create with existing attempts | Some students already have attempts | Only missing attempts created |
| TC-P39 | Bulk Check — marks update | Save 85 for student A | Student A marks shown as 85 |
| TC-P40 | Both online/offline tabs work | Switch online↔offline | Both load correct data |
| TC-P51 | Bulk Save With marks=0 For All Students | marks=0 is processed (not skipped); creates ExamResult with percentage=0, result_status=FAIL | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Scenario | Steps | Expected Result |
|-------|----------|-------|-----------------|
| TC-N01 | No offline papers exist | Delete all offline papers | "No exams found for the selected filters." |
| TC-N02 | Bulk Check — no allocations | Paper with 0 allocated students | "No allocations found." in left panel |
| TC-N03 | Bulk Check — no uploaded PDF | Student without answer sheet | Viewer shows placeholder "Select a document to view" |
| TC-N04 | Bulk Check — corrupted PDF | Student uploaded corrupted file | PDF viewer error; placeholder visible |
| TC-N05 | Offline QW Check — no questions | Paper set has 0 questions | Marks list empty; 0/0 score |
| TC-N06 | Offline QW Check — no default set | Exam paper has 0 active paper sets | Stub creation fails; student dropdown may be empty |
| TC-N07 | Bulk Check — invalid marks | Enter non-numeric in marks | Validation error on save |
| TC-N08 | Bulk Check — marks > total | Enter 999 when max=100 | Validation may allow; logic may produce >100% |
| TC-N09 | Bulk Check — negative marks | Enter -10 | Validation may reject |
| TC-N10 | No permission | Remove tenant.offline-assessment.view | 403 |
| TC-N11 | Empty student list in QW Check | No allocations | Student selector empty |
| TC-N12 | Bulk Check rapid save | Click Save multiple times | First request processed; subsequent may cause duplicates or be idempotent |
| TC-N13 | Report for paper with no students | Paper with 0 allocations | "No students found." |
| TC-N14 | Summary — all zero counts | Paper with allocations, 0 attempts | Submitted=0, Checked=0 |
| TC-N15 | Invalid paper_id in paper-check | Navigate to paper-check/99999 | 404 |
| TC-N16 | Bulk Check — attempt without result | Student has attempt but no result | Marks shows "-"; Status shows attempt status |
| TC-N17 | Offline QW — non-PDF attachment | Student uploaded image | Viewer may use html preview or fail |
| TC-N18 | Date range with no results | Select ancient date range | Empty summary |
| TC-N19 | Publish unchecked grade | Submit without publish toggle | Student cannot see result |
| TC-N20 | Bulk grade save with empty marks | Submit all null marks | Nothing saved but no error |

### 6.3 Dependency / Integration Test Cases

| TC ID | Scenario | Steps | Expected Result |
|-------|----------|-------|-----------------|
| TC-D01 | Offline summary → Report | Click Report | Report page with offline paper stats |
| TC-D02 | Offline summary → Bulk Check (BULK_TOTAL) | Click Check for BULK_TOTAL paper | Bulk check interface |
| TC-D03 | Offline summary → QW Check (QUESTION_WISE) | Click Check for QW paper | Offline question-wise check interface |
| TC-D04 | Bulk Check → Summary sync | Save grade in Bulk; go to summary | Checked count updated |
| TC-D05 | Upload tab → Assessment tab sync | Upload offline marks; navigate to assessment | Summary reflects changes |
| TC-D06 | Offline QW Check → student result | Submit grade; open attempt detail | Result shows in student page |
| TC-D07 | Bulk grade → Report avg | Grade 3 students | Avg score calculated correctly |
| TC-D08 | Attempt stub → Paper Check | Create attempt via stub; reload check page | Student appears in selector with EVALUATION_PENDING |
| TC-D09 | Multiple allocation types resolved | CLASS + SECTION + STUDENT allocations | All students shown in bulk check |
| TC-D10 | Reset from bulk check | Click reset button | Zoom/rotation reset |
| TC-D11 | Delete annotation | Drag to delete zone | Annotation removed |
| TC-D12 | Switch student in bulk check | Select Student A → view PDF → select Student B | B's PDF loads; Student A's data preserved |
| TC-D13 | Tenant isolation | Tenant A and B data separate | Each sees own offline papers |
| TC-D14 | Publication flow | Grade + publish → student portal | Student sees result |
| TC-D15 | Bulk save with teacher feedback | Save marks with feedback text | Feedback stored in teacher_remarks |
| TC-D16 | Offline QW — save individual question | Use save-answer-grade for one question | Marks saved for that question |
| TC-D17 | UFM flag during grading | Mark as UFM | Malpractice flag recorded |
| TC-D18 | Reject flag during grading | Mark as Reject | Rejection recorded; status updated |
| TC-D19 | Large student count | 100+ allocated students | Bulk left panel scrollable; all shown |
| TC-D20 | Cross-tab navigation | Upload → Assessment → Upload | Tab state preserved via active_tab param |

### 6.4 Code Review / Static Analysis

| TC ID | Scenario | Expected Observation |
|-------|----------|----------------------|
| TC-CR01 | assessment() method | Clones baseQuery; offline mode=OFFLINE filter |
| TC-CR02 | examPaperCheckOffline() | Auto-creates attempt stubs: finds default set; firstOrCreate per allocation |
| TC-CR03 | examPaperCheckOffline() status filter | Loads attempts with status IN (EVALUATION_PENDING, SUBMITTED, EVALUATED, RESULT_PUBLISHED) |
| TC-CR04 | examPaperCheckBulk() redirect guard | Redirects if mode=ONLINE or offline_entry_mode=QUESTION_WISE or is_ques_wise_file_upload=1 |
| TC-CR05 | examPaperCheckBulk() allocation resolution | Handles CLASS, SECTION, STUDENT types; gets students from ClassSection->studentAcademicSessions |
| TC-CR06 | examPaperCheckBulk() first row highlight | `$key === 0 ? 'table-primary' : ''` for first row |
| TC-CR07 | examPaperCheckBulk() first radio checked | `{{ $key === 0 ? 'checked' : '' }}` on radio input |
| TC-CR08 | saveBulkGrades() validation | student_marks required array; marks nullable numeric; student_id required |
| TC-CR09 | View — action button condition | `if($paper->is_ques_wise_file_upload == '1')` → paper-check-offline; else → paper-check.bulk |
| TC-CR10 | View — offline mode badge | `mode == 'OFFLINE'` shows bg-secondary "Offline" plus entry mode badge |
| TC-CR11 | View — bulk student table onclick | Radio click via `dispatchEvent(new Event('change'))` on row click |
| TC-CR12 | View — bulk marks cell | `$row['marks_obtained'] !== null` → green; else gray "-" |
| TC-CR13 | View — bulk annotation toolbar | 9 tools: mark, view, correct, wrong, repeat, blank, comment, text, pen |
| TC-CR14 | View — offline QW check same layout as online | Same 3-column layout (Marks, PDF Viewer, Tools) |
| TC-CR15 | View — offline QW student selector | Rendered from `$attempts` collection with student name and status |
| TC-CR16 | Controller — getEvaluationStudents() | Returns student_id, student_name, status, submitted_at for paper |
| TC-CR17 | Controller — getEvaluationQuestions() | Handles null paper_set_id by fallback to first active set |
| TC-CR18 | View — summary filter form | Hidden mode input for OFFLINE; same daterangepicker and cascading as online |
| TC-CR19 | View — bulk Max Marks badge | `{{ (float) $paper->total_marks }} Max Marks` in left panel header |
| TC-CR20 | Controller — stub creation uses firstOrCreate | Prevents duplicate attempts for same student+paper |
| TC-CR21 | CR | Code Review | P1 | Controller — marks===null vs marks=0 in saveBulkGrades | Line 2524: `if ($data['marks'] === null) continue;` — null skips silently, 0 goes through; two different behaviors | — | — | ◌ |
| TC-CR22 | CR | Code Review | P1 | Controller — Transaction Before findOrFail in bulkUploadMarks | DB::beginTransaction starts BEFORE Student::findOrFail and ExamPaper::findOrFail; if 404 occurs, transaction stays open (never commit/rollback) | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Load offline assessment tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/lms-exam/assessment?active_tab=offline_assessment` | Page loads with assessment tabs |
| 2 | Verify offline_assessment pane active | show active class present |
| 3 | Verify table | Summary table with offline papers only |

#### TC-P02: Offline mode badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find paper with mode=OFFLINE | Badge "Offline" (bg-secondary) displayed |

#### TC-P03: Bulk entry mode badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper with BULK_TOTAL + is_ques_wise=0 | "Bulk" badge (bg-light text-dark border) |

#### TC-P04: Question-wise entry mode badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper with is_ques_wise_file_upload=1 | "Question Wise" badge (bg-light text-dark border) |

#### TC-P05: Counts correct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 10 allocations, 6 submitted, 4 checked | Assigned=10, Submitted=6, Checked=4 |

#### TC-P06: Bulk check button

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find BULK_TOTAL paper row | Check button uses btn-outline-warning with fa-list-ol icon |
| 2 | Inspect href | Links to lms-exam.exam.paper-check.bulk route |

#### TC-P07: Question-wise check button

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find is_ques_wise=1 paper row | Check button uses btn-outline-info with fa-file-alt icon |
| 2 | Inspect href | Links to lms-exam.exam.paper-check-offline route |

#### TC-P08: Report button

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Report for offline paper | Report page with same layout as online report |

#### TC-P09: Bulk check student list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open bulk check for BULK_TOTAL paper | Left panel shows table with Student, Given Mark, Select columns |
| 2 | Verify students listed | All allocated students shown |

#### TC-P10: First student auto-selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load bulk check page | First row has table-primary class |
| 2 | Verify radio | First student's radio is checked |

#### TC-P11: Click student row selects

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click second student row | Radio checked; row highlighted; first row loses highlight |

#### TC-P12: PDF auto-loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select student with uploaded answer sheet | PDF viewer loads document automatically |

#### TC-P13: Marks shown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student with result.total_marks_obtained=85 | "Given Mark" shows "85" in text-success |

#### TC-P14: Pending marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student without result | "Given Mark" shows "-" in text-muted |

#### TC-P15: PDF viewer nav

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click next page | PDF advances; page indicator updates "Page 2 / 5" |
| 2 | Click prev page | Returns to page 1 |

#### TC-P16: Zoom controls

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click zoom in | PDF scales; "125%" shown |
| 2 | Click zoom out | Returns to "100%" |

#### TC-P17: Annotations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Correct tool | Tool activates |
| 2 | Click on PDF | Green checkmark annotation placed |
| 3 | Click Wrong tool | Tool activates |
| 4 | Click on PDF | Red X annotation placed |

#### TC-P18: Save button

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Save icon (floppy disk) | AJAX call to bulk-save; success toast |

#### TC-P19: Bulk grade modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Final Review | Grade modal opens |
| 2 | Verify form | Status dropdown, Marks input, Feedback textarea |

#### TC-P20: Submit grade (bulk)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select status "Checked" | Status set |
| 2 | Enter marks_obtained=85 | Marks entered |
| 3 | Enter feedback "Well done" | Feedback entered |
| 4 | Click Submit Grade | Grade saved; modal closes; success toast |

#### TC-P21: QW Check attempt stub creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open offline QW check for paper with 0 attempts | ExamAttempt::firstOrCreate runs for each allocation |
| 2 | Verify DB | New attempts with status=EVALUATION_PENDING, attempt_mode=OFFLINE, created_by=auth()->id() |

#### TC-P22: QW Check student selector

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load offline QW check page | Student dropdown populated with all allocated students |
| 2 | Verify options | Student name + status shown |

#### TC-P23: QW Check marks list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a student | Left panel shows marks table with Q#, Max, Marks, Action |
| 2 | Verify total score | "0 / 100" shown at top |

#### TC-P24: Total score updates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter marks=5 for question 1 | Total updates to "5 / 100" |
| 2 | Enter marks=10 for question 2 | Total updates to "15 / 100" |

#### TC-P25: QW Check PDF loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select student with uploaded answer sheet | PDF loads in center viewer |
| 2 | Verify multiple pages | Page navigation works |

#### TC-P26: QW Check annotations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select View tool | Tool activates |
| 2 | Click on PDF | "Viewed" annotation placed |
| 3 | Select Mark tool; right-click | Mark menu appears |

#### TC-P27: QW Check Grade Modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Final Review | Grade modal opens with grading form |
| 2 | Verify fields | Grading Status, Marks Obtained, Feedback, Publish toggle |

#### TC-P28: QW Check Submit Grade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill form | Valid data |
| 2 | Click Submit Grade | PUT request sent; success response |

#### TC-P29: Summary filter class_section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class_section | Cascading loads subjects |
| 2 | Click Search | Papers filtered |

#### TC-P30: Summary filter date range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select date range | Auto-submits; papers filtered |

#### TC-P31: Summary pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 12 offline papers exist | Page 1 shows 10; page link shows 2 |

#### TC-P32: Reset filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filters | URL has params |
| 2 | Click refresh icon | Filters cleared |

#### TC-P33: Report for offline paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Report | Same report page as online |

#### TC-P34: View Result from report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click View Result | Student result page opens |

#### TC-P35: Student result badges

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student above passing % | "Passed" green badge |
| 2 | Student below passing % | "Failed" red badge |

#### TC-P36: Upload PDF in bulk

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click upload button in bulk interface | File dialog opens |
| 2 | Select PDF | PDF uploaded; viewer updates |

#### TC-P37: Multi-page PDF

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student uploads 5-page PDF | All 5 pages navigable in viewer |

#### TC-P38: Stub creation skips existing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 10 allocations, 3 already have attempts | Only 7 new stubs created |

#### TC-P39: Bulk marks update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save marks=85 for Student A | "Given Mark" cell updates to "85" (green) |
| 2 | Reload page | 85 persists |

#### TC-P40: Tab switching

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click online_assessment tab | Online papers shown |
| 2 | Click offline_assessment tab | Offline papers shown |

### 7.2 Negative TC Steps

#### TC-N01: No offline papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete/disable all OFFLINE mode papers | "No exams found for the selected filters." |

#### TC-N02: No allocations in bulk

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open bulk check for paper with 0 allocations | "No allocations found." in table |

#### TC-N03: No PDF uploaded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select student without uploaded answer sheet | PDF viewer shows "Select a document to view" placeholder |

#### TC-N04: Corrupted PDF

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student uploaded corrupted PDF | pdf.js shows error; placeholder remains |

#### TC-N05: No questions in QW check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open QW check for set with 0 questions | Marks list empty; score "0 / 0" |

#### TC-N06: No default set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper has 0 active paper sets | Stub creation may fail; empty student selector |

#### TC-N07: Invalid marks in bulk

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter "abc" in marks field | Form validation rejects; not submitted |

#### TC-N08: Marks > total

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter marks=999 for paper max=100 | May be accepted; percentage >100% |

#### TC-N09: Negative marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter marks=-10 | Validation rejects |

#### TC-N10: No permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Remove permission | 403 on assessment page |

#### TC-N11: Empty QW student list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper with 0 allocations | Student selector has no options |

#### TC-N12: Rapid bulk save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Save multiple times | First request processes; duplicates prevented by firstOrCreate logic |

#### TC-N13: Empty report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper with 0 allocations | "No students found." |

#### TC-N14: All zero summary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 5 allocations, 0 attempts | Submitted=0, Checked=0 |

#### TC-N15: Invalid paper ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/lms-exam/paper-check-offline/99999` | 404 |

#### TC-N16: Attempt without result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student has attempt but no result | Marks shows "-"; status shown |

#### TC-N17: Non-PDF attachment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student uploaded image | Viewer may show html preview |

#### TC-N18: Date range no match

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select ancient date range | Empty summary |

#### TC-N19: Unpublished result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit grade without publish toggle | Student cannot see result |

#### TC-N20: All null marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit all null marks | Nothing saved; no error |

### 7.3 Dependency TC Steps

#### TC-D01: Summary to Report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Report for offline paper | Report page loads with paper context |

#### TC-D02: Summary to Bulk Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Check for BULK_TOTAL paper | Bulk check interface opens |

#### TC-D03: Summary to QW Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Check for is_ques_wise=1 paper | Offline QW check interface opens |

#### TC-D04: Bulk Check → Summary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save grade for student | is_evaluated=1 |
| 2 | Navigate to assessment summary | Checked count incremented |

#### TC-D05: Upload → Assessment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload marks in Upload tab | Evaluate status updated |
| 2 | Navigate to Assessment tab | Checked count reflects change |

#### TC-D06: QW Grade → Student result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit grade in QW check | Attempt status = EVALUATED |
| 2 | Open attempt detail | Result displayed |

#### TC-D07: Avg score in report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 3 students: 80, 90, 70 marks | Avg = (80+90+70)/3 = 80 |

#### TC-D08: Attempt stub persistence

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load QW check → stubs created | Attempts in DB |
| 2 | Reload QW check | No duplicate stubs (firstOrCreate) |

#### TC-D09: Multiple allocation types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | CLASS + SECTION + STUDENT allocations | All types resolved; students shown |

#### TC-D10: Reset view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Zoom to 150%, rotate | View modified |
| 2 | Click Reset | Zoom=100%; rotation=0 |

#### TC-D11: Delete annotation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Place annotation | Visible |
| 2 | Drag to "Drop to delete" | Annotation removed |

#### TC-D12: Switch student in bulk

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | View Student A's PDF | A's document shown |
| 2 | Select Student B | B's PDF loads |

#### TC-D13: Tenant isolation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tenant A has 5 offline papers | Summary shows 5 |
| 2 | Tenant B has 2 | Summary shows 2 |

#### TC-D14: Publication flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Grade with publish=true | Student sees result in portal |
| 2 | Grade with publish=false | Student portal shows pending |

#### TC-D15: Feedback storage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save grade with "Good work" | teacher_remarks = "Good work" |

#### TC-D16: Save individual question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save marks for one question via API | Only that question updated |

#### TC-D17: UFM flag

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click UFM button | Malpractice flag set on attempt |

#### TC-D18: Reject flag

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Reject button | Rejection recorded; status updated |

#### TC-D19: Large student count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 100+ students allocated | Left panel scrollable; no performance degradation |

#### TC-D20: Cross-tab navigation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set active_tab=offline_assessment | Tab active |
| 2 | Navigate to upload | Upload tab |
| 3 | Return to assessment | active_tab preserved in URL if passed |

### 7.4 Code Review TC Steps

#### TC-CR01: assessment() offline mode filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect assessment() | BaseQuery cloned; offline -> where('mode', 'OFFLINE') |

#### TC-CR02: examPaperCheckOffline() stub creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect loop | Iterates allocations; checks `!$alloc->attempt` before creating |
| 2 | Verify firstOrCreate | Prevents duplicate attempts |

#### TC-CR03: examPaperCheckOffline() status filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect attempt query | whereIn status: EVALUATION_PENDING, SUBMITTED, EVALUATED, RESULT_PUBLISHED |

#### TC-CR04: examPaperCheckBulk() redirect guard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect guard condition | Redirects if mode=ONLINE || offline_entry_mode=QUESTION_WISE || is_ques_wise_file_upload=1 |

#### TC-CR05: examPaperCheckBulk() allocation resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect switch | 3 types handled: CLASS, SECTION, STUDENT |

#### TC-CR06: First row highlight

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect tr class | `$key === 0 ? 'table-primary' : ''` |

#### TC-CR07: First radio checked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect radio | `{{ $key === 0 ? 'checked' : '' }}` |

#### TC-CR08: saveBulkGrades() validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect validate | student_marks required|array; *.marks nullable|numeric; *.student_id required |

#### TC-CR09: Action button condition

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade | `if($paper->is_ques_wise_file_upload == '1')` → paper-check-offline; else → paper-check.bulk |

#### TC-CR10: Offline mode badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect mode badge | `mode == 'OFFLINE'` → bg-secondary "Offline" badge |
| 2 | Inspect entry mode badge | `is_ques_wise_file_upload == '1'` → "Question Wise" else "Bulk" |

#### TC-CR11: Row click select

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect onclick | Finds radio; checks if not checked; dispatches 'change' event |

#### TC-CR12: Marks cell display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect cell | `$row['marks_obtained'] !== null` → text-success, else text-muted "-" |

#### TC-CR13: Bulk annotation toolbar

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect toolbar | 9 tools: mark, view, correct, wrong, repeat, blank, comment, text, pen |

#### TC-CR14: QW Check same 3-column layout as online

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare layouts | Same col-lg-2 / col-lg-7 / col-lg-3 structure |

#### TC-CR15: Student selector in QW check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect selector | Rendered from $attempts; shows student name + status |

#### TC-CR16: getEvaluationStudents() response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect method | Returns student_id, student_name, status, submitted_at |

#### TC-CR17: getEvaluationQuestions() null set fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect set fallback | If paper_set_id null, gets first active set by paper ID |

#### TC-CR18: Summary filter form offline

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect form | Hidden mode input value='OFFLINE'; same daterangepicker + cascading |

#### TC-CR19: Max marks badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect bulk header | `{{ (float) $paper->total_marks }} Max Marks` badge (bg-primary) |

#### TC-CR20: Stub firstOrCreate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect stub creation | firstOrCreate on exam_paper_id + student_id; sets allocation_id, paper_set_id, status=EVALUATION_PENDING, attempt_mode=OFFLINE |

### Additional Positive TC Steps

#### TC-P41: Bulk Check — Multiple Page PDF Navigation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load multi-page PDF in viewer | PDF renders first page |
| 2 | Click next page 5 times | Navigates through pages without error |
| 3 | Verify page indicator | "Page 6 / 10" shown |

#### TC-P42: Bulk Check — Annotation After Page Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Place correct annotation on page 1 | Green checkmark visible |
| 2 | Go to page 2 | Page 2 loads |
| 3 | Place wrong annotation on page 2 | Red X visible on page 2 |
| 4 | Return to page 1 | Page 1 correct annotation still present |

#### TC-P43: Bulk Check — Grade Modal Submission Info

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select student with known data | Student loaded |
| 2 | Open Grade Modal | Student name, exam paper displayed in submission info section |
| 3 | Verify marks field pre-populated | Existing marks shown if available |

#### TC-P44: Offline QW Check — Save Individual Question Marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open QW check for student | Marks list shows all questions |
| 2 | Enter marks=7 for question 1 | Input accepts value |
| 3 | Click Save for question 1 | AJAX saves to OfflineExamUploadDetail |
| 4 | Verify total score updates | Score increments |

#### TC-P45: Offline QW Check — Question Type Badges

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper set has MCQ, Short Answer, Long Answer | Each question shows correct type badge |
| 2 | Verify MCQ badge | "MCQ" or label shown |
| 3 | Verify descriptive badges | "Short Answer" / "Long Answer" shown |

#### TC-P46: Summary — Total Exams Badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 8 offline papers exist | "8 exams" badge (bg-secondary) in header |

#### TC-P47: Offline QW Check — View Question Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click View Question Paper button | Opens paper set questions in new tab |

#### TC-P48: Offline QW Check — Solutions Button

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Solutions button | Solutions view loaded (if available) |

#### TC-P49: Bulk Check — Delete Annotation on Different Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Place annotation on page 1 | Visible |
| 2 | Go to page 2 | Page 2 shown |
| 3 | Return to page 1 | Annotation still present |
| 4 | Drag to delete | Annotation removed |

#### TC-P50: Offline QW Check — Grade Modal Publish Toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Publish Result toggle | Checkbox toggles |
| 2 | Submit grade | Result published if checked |
| 3 | Check student portal | Grade visible only if published |

### Additional Negative TC Steps

#### TC-N21: Bulk Check — Empty Marks Array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit empty student_marks array | Validation error: "student_marks is required" |

#### TC-N22: Bulk Check — Non-numeric Marks In Array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit marks="abc" for a student | Validation rejects; error returned |

#### TC-N23: Offline QW Check — Null paper_set_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create attempt without paper_set_id | Fallback to first active set |
| 2 | If no sets exist | Error: "No question set found for this paper." |

#### TC-N24: Offline QW Check — Save Marks With Invalid Question ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send save request with question_id=99999 | Server handles gracefully; error or skip |

#### TC-N25: Summary — Disabled Class With All Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Disable all classes | Class section list empty; no papers shown |

#### TC-N26: Bulk Check — No Default Paper Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper with 0 active sets | Bulk load works but set-dependent features may fail |

#### TC-N27: Offline QW Check — Missing Student Academic Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student allocated but no academic session | Attempt stub created with minimal data |

#### TC-N28: Bulk Check — Student With Only Failed Attempt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student has attempt status=NOT_STARTED | Marks shows "-"; no PDF loaded |

#### TC-N29: Summary — Zero Assigned Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper with 0 allocations | Assigned=0, Submitted=0, Checked=0 |

#### TC-N30: Bulk Check — Rapid Student Switching

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Student A, then Student B rapidly | B's document loads; A's state preserved |

### Additional Dependency TC Steps

#### TC-D21: Bulk Check — Auto-load PDF on Student Select

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click student row | PDF loads automatically without extra button click |

#### TC-D22: Offline QW Check — Grade Affects Bulk Upload Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Grade student in QW check | is_evaluated=1 |
| 2 | Navigate to Upload tab | Student shows Checked=Yes |

#### TC-D23: Bulk Save With Feedback → Report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save grade with teacher feedback | Feedback stored |
| 2 | Open report | Teacher feedback shown in student result |

#### TC-D24: Summary Filter Persistence On Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply class filter, search | URL has class_section_id param |
| 2 | Click page 2 | class_section_id preserved in URL |

#### TC-D25: Multiple Annotation Tools On Same PDF

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Place correct + comment + mark on page | All three annotations visible simultaneously |

#### TC-D26: Bulk Check — Reset View After Zoom

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Zoom to 200%, rotate 2x | View modified |
| 2 | Click Reset View | Back to 100%, 0 rotation |

#### TC-D27: Offline QW Check — Different Tools Per Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Page 1: correct annotation | Saved per page |
| 2 | Page 2: wrong annotation | Independent from page 1 |
| 3 | Navigate back and forth | Each page retains annotations |

#### TC-D28: Report — Same Report For Online And Offline

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open report for offline paper | Same layout/stats as online report |

#### TC-D29: Bulk Save — Idempotent Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save marks=85 for student | Saved |
| 2 | Save marks=85 for same student | Overwritten; no duplicate |

#### TC-D30: Both Check Buttons In Same Summary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | View summary with BULK_TOTAL and QUESTION_WISE papers | Each row shows correct button style and route |

### Additional Code Review TC Steps

#### TC-CR21: Bulk Check — Student Row Data Attributes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect tr data attributes | data-student-id, data-attempt-id, data-paper-set-id, data-marks all populated |

#### TC-CR22: Bulk Check — Badge Styles

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect bulk check header | bg-light card-header; primary badge for max marks |

#### TC-CR23: Offline QW Check — Same CSS as Online

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare offline-check styles | Same .cbse-panel-body, .cbse-viewer-body, #cbse-viewer-shell, #cbse-annotation-layer as online index |

#### TC-CR24: Offline QW Check — Mobile Nav

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect mobile nav | 3 tabs: Viewer, Questions, Tools; d-lg-none |

#### TC-CR25: Bulk Check — Save Button In Toolbar

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect right panel | Save button (cbse-save-state-btn) with bi-save icon |

#### TC-CR26: Bulk Check — Grade Modal Simpler Than QW

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare grade modals | Bulk: Status, Marks, Feedback only (no per-question grading) |

#### TC-CR27: Offline QW Check — Grade Modal Same As Online

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare grade modals | Same layout: Submission Info, Evaluation Summary, Grading Form |

#### TC-CR28: Controller — Default Set Fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect examPaperCheckOffline | Gets first active set: `ExamPaperSet::where('exam_paper_id', $id)->where('is_active', true)->value('id')` |

#### TC-CR29: Controller — Bulk Check Student Query

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect student query | Student::where('is_active',1)->whereIn('id', $studentIds)->with academicSessions and examAttempts |

#### TC-CR30: Controller — Bulk Check Attempt Relation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect examAttempts relation | where exam_paper_id=$id, attempt_mode=OFFLINE, with('result') |
