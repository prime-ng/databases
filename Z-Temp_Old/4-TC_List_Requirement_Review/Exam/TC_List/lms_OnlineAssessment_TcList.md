# lms_OnlineAssessment_TcList

## Module: LmsExam → Assessment Tab → Online Assessment (Summary & Paper Check)

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Assessment |
| Feature | Online Assessment — Summary Dashboard, Report, Paper Check (PDF Annotation & Grading) |
| URL(s) | `/lms-exam/assessment` (parent), `GET /lms-exam/assessment?active_tab=online_assessment` (summary), `lms-exam.exam.report` (report route), `lms-exam.exam.attemptDetail` (student result), `lms-exam.exam.paper-check` (paper check online), `lms-exam.exam.paper-check-offline` (paper check offline QW), `lms-exam.exam.paper-check.bulk` (paper check offline bulk), `lms-exam.exam.paper-check.questions` (AJAX), `lms-exam.exam.paper-check.save-answer-grade` (AJAX POST), `lms-exam.exam.paper-check.submit-grade` (PUT), `lms-exam.exam.get-subjects-by-class` (AJAX), `lms-exam.exam.get-papers-by-exam` (AJAX), `lms-exam.exam.get-sets-by-paper` (AJAX) |
| Controller | `Modules\LmsExam\Http\Controllers\LmsExamController` — methods: `assessment()`, `report()`, `attemptDetail()`, `applyExamFilters()`, `paperCheck()`, `getPaperCheckQuestions()`, `saveAnswerGrade()`, `submitGrade()` |
| Model(s) | `ExamPaper`, `ExamAttempt`, `ExamAttemptAnswer`, `ExamResult`, `ExamAllocation`, `Exam`, `SchoolClass`, `Section`, `Subject`, `ExamBlueprint`, `ExamPaperSet`, `PaperSetQuestion`, `QuestionBank` |
| Permissions | `tenant.online-assessment.view`, `tenant.offline-assessment.view`, `tenant.exam.viewAny` |
| Pagination | Summary: 10/page; Report: 25/page; `withQueryString()` for filter persistence |
| JS Libraries | pdf.js, jspdf, MathJax, Chart.js, Bootstrap Icons, SweetAlert2, daterangepicker, moment.js |
| Annotation Tools | Marks, Correct, Wrong, Blank, Repeat, Comment, Text Box, Freehand Pen, View |

---

## 2. Pre-conditions

- Required permissions: `tenant.online-assessment.view`, `tenant.exam.viewAny`
- Required seed data: At least one `ExamPaper` with `mode=ONLINE`, allocated students, submitted attempts
- Online exam attempts must have status in (SUBMITTED, EVALUATION_PENDING, EVALUATED, RESULT_PUBLISHED) for submitted count
- For Paper Check: At least one submitted attempt with uploaded answer PDF
- For Report: Allocated students and at least one attempt per student
- Chart.js and pdf.js CDNs must be accessible
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

When the page loads via `assessment()` method:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Online Summary | LmsExamController@assessment | ExamPaper with exam, class, subject, status; mode=ONLINE; withCount(allocations, attempts) | class_section_id, subject_id, exam_id, exam_paper_id, exam_set_id, date_from, date_to, search | 10/page |
| Offline Summary | LmsExamController@assessment (clone) | ExamPaper mode=OFFLINE; same withCount | Same filters | 10/page |
| Lessons/Topics | Lesson/Topic models | is_active=1 | None | None |
| Exams | Exam model | is_active=1 | None | None |
| ClassSection List | Cache (3600s) | ClassSection with class, section | is_active=1 | None |
| Classes | SchoolClass | is_active=1 | None | None |
| Subjects | Subject | is_active=1 | None | None |

---

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` for unique identifiers
- **Paper creation**: Create ONLINE mode papers with descriptive questions requiring manual evaluation
- **Attempt creation**: Create attempts with SUBMITTED/EVALUATION_PENDING status
- **Answer creation**: Create ExamAttemptAnswer records with file uploads (PDF) via attachment_data JSON
- **Result creation**: For evaluated attempts, create ExamResult with total_marks_obtained, percentage, grade
- **Pre-test cleanup**: Delete created ExamAttempt, ExamAttemptAnswer, ExamResult records
- **Chart data**: Ensure enough student variation for meaningful participation/score distribution charts
- **Paper Check**: Submit valid PDF answer sheets; use annotation tools

---

## 5. Business Conditions

### 5.1 Database Schema — `lms_exam_papers`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT PK | Auto-increment |
| BC-DB-02 | title | VARCHAR(255) | NOT NULL |
| BC-DB-03 | paper_code | VARCHAR(50) | NULL |
| BC-DB-04 | exam_id | BIGINT FK | NOT NULL, FK → `lms_exams.id` |
| BC-DB-05 | class_id | BIGINT FK | NOT NULL, FK → `sch_classes.id` |
| BC-DB-06 | subject_id | BIGINT FK | NOT NULL, FK → `sub_subjects.id` |
| BC-DB-07 | mode | ENUM('ONLINE','OFFLINE') | NOT NULL; determines summary tab placement |
| BC-DB-08 | total_marks | DECIMAL(8,2) | NULL |
| BC-DB-09 | passing_percentage | DECIMAL(5,2) | DEFAULT 0 |
| BC-DB-10 | is_active | TINYINT(1) | DEFAULT 1 |

### 5.2 Database Schema — `lms_exam_attempts`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-11 | id | BIGINT PK | Auto-increment |
| BC-DB-12 | student_id | BIGINT FK | NOT NULL, FK → `sch_students.id` |
| BC-DB-13 | exam_paper_id | BIGINT FK | NOT NULL, FK → `lms_exam_papers.id` |
| BC-DB-14 | status | ENUM | 'NOT_STARTED','IN_PROGRESS','SUBMITTED','EVALUATION_PENDING','EVALUATED','RESULT_PUBLISHED' |
| BC-DB-15 | is_evaluated | TINYINT(1) | DEFAULT 0 |
| BC-DB-16 | attempt_mode | VARCHAR(20) | NULL; 'ONLINE' or 'OFFLINE' |
| BC-DB-17 | actual_time_taken_seconds | INT | NULL |
| BC-DB-18 | actual_end_time | TIMESTAMP | NULL |

### 5.3 Database Schema — `lms_exam_results`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-19 | id | BIGINT PK | Auto-increment |
| BC-DB-20 | exam_attempt_id | BIGINT FK | NOT NULL, FK → `lms_exam_attempts.id` |
| BC-DB-21 | total_marks_obtained | DECIMAL(8,2) | NULL |
| BC-DB-22 | total_marks_possible | DECIMAL(8,2) | NULL |
| BC-DB-23 | percentage | DECIMAL(5,2) | NULL |
| BC-DB-24 | grade | VARCHAR(10) | NULL |
| BC-DB-25 | result_status | ENUM | 'PASS','FAIL','PENDING' |
| BC-DB-26 | is_published | TINYINT(1) | DEFAULT 0 |

### 5.4 Validation Rules

| BC ID | Field/Scope | Rule | Error Message |
|-------|-------------|------|---------------|
| BC-VAL-01 | date_from + date_to | Both required if one filled; valid date format | N/A (daterangepicker enforces format) |
| BC-VAL-02 | search | Max 255 chars | Truncated or ignored |
| BC-VAL-03 | exam_paper_id | Must exist in lms_exam_papers | 404 via findOrFail in report/paperCheck |
| BC-VAL-04 | attempt_id (submit grade) | Must exist in lms_exam_attempts | 404 via findOrFail |
| BC-VAL-05 | marks_obtained (submit grade) | Numeric, min 0, max paper total_marks | Validated in controller |

### 5.5 Authorization

| BC ID | Permission | Effect |
|-------|------------|--------|
| BC-AUTH-01 | tenant.online-assessment.view | Tab page access for assessment() |
| BC-AUTH-02 | tenant.offline-assessment.view | Required alongside above for assessment() |
| BC-AUTH-03 | tenant.exam.viewAny | report() and attemptDetail() methods |

### 5.6 Business Logic

| BC ID | Rule | Description |
|-------|------|-------------|
| BC-BIZ-01 | Summary Split by Mode | assessment() clones base query; onlineSummary mode=ONLINE; offlineSummary mode=OFFLINE |
| BC-BIZ-02 | Submitted Count | Status in (SUBMITTED, EVALUATION_PENDING, EVALUATED, RESULT_PUBLISHED) |
| BC-BIZ-03 | Checked Count | Status in (EVALUATED, RESULT_PUBLISHED) |
| BC-BIZ-04 | Report Allocation Resolution | report() resolves SECTION, CLASS, STUDENT, EXAM_GROUP allocation types to student IDs |
| BC-BIZ-05 | Report Provisional Marks | For non-evaluated attempts: marks_obtained from answers.sum('marks_obtained') / max_marks |
| BC-BIZ-06 | Report Final Marks | For evaluated attempts: result.total_marks_obtained / result.total_marks_possible |
| BC-BIZ-07 | Report Percentage Display | Provisional (text-muted tooltip) vs Final (text-primary bold) |
| BC-BIZ-08 | Chart Data — Participation | Evaluated / Pending / Not Attempted from attempt counts |
| BC-BIZ-09 | Chart Data — Score Distribution | 5 bins: 0-20%, 21-40%, 41-60%, 61-80%, 81-100%; uses result.percentage or provisional % |
| BC-BIZ-10 | Paper Check — Student Selector | Dropdown of all attempts; selecting loads student's PDF |
| BC-BIZ-11 | Paper Check — Annotation Layer | Absolute positioned div over PDF canvas; annotations are draggable |
| BC-BIZ-12 | Paper Check — Delete Zone | Drop annotation onto "Drop to delete" zone to remove |
| BC-BIZ-13 | Paper Check — Grade Modal | Final Review opens modal with grading form; PUT to submit_grade |
| BC-BIZ-14 | Cascading Filters | class_section → subject; exam → paper → set; auto-load on change |
| BC-BIZ-15 | Date Auto-Submit | daterangepicker apply/cancel events auto-submit the filter form |
| BC-BIZ-16 | Mode Hidden Input | Hidden field `mode` set to ONLINE or OFFLINE based on tab_id |

### 5.7 Referential Integrity

| BC ID | Constraint | Description |
|-------|------------|-------------|
| BC-REF-01 | lms_exam_papers.exam_id → lms_exams.id | Paper belongs to exam |
| BC-REF-02 | lms_exam_papers.class_id → sch_classes.id | Paper linked to class |
| BC-REF-03 | lms_exam_papers.subject_id → sub_subjects.id | Paper linked to subject |
| BC-REF-04 | lms_exam_attempts.exam_paper_id → lms_exam_papers.id | Attempt belongs to paper |
| BC-REF-05 | lms_exam_results.exam_attempt_id → lms_exam_attempts.id | Result belongs to attempt |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Scenario | Steps | Expected Result |
|-------|----------|-------|-----------------|
| TC-P01 | Load online assessment tab | Navigate to `/lms-exam/assessment?active_tab=online_assessment` | Summary table shows all online exam papers |
| TC-P02 | Summary columns displayed | Observe table | Exam Title, Class/Section/Subject, Mode, Exam Date, Assigned, Submitted, Checked, Action |
| TC-P03 | Online mode badge | Paper has mode=ONLINE | Badge "Online" (bg-primary) |
| TC-P04 | Assigned count | Paper with 5 allocations | Shows "5" badge |
| TC-P05 | Submitted count | 3/5 students submitted | Shows "3" badge |
| TC-P06 | Checked count | 2/3 submitted evaluated | Shows "2" badge |
| TC-P07 | Report button | Click Report for a paper | Opens report page with header, stats cards, charts, student table |
| TC-P08 | Report header info | Report page loads | Paper title, class, subject, exam name displayed |
| TC-P09 | Report stats cards | Verify 4 cards | Total Assigned, Total Attempts, Evaluated, Avg Score |
| TC-P10 | Report participation chart | Verify doughnut chart | Evaluated/Pending/Not Attempted segments |
| TC-P11 | Report score distribution chart | Verify bar chart | 5 bins with student counts |
| TC-P12 | Report student table | Scroll | Student Name, Admission No, Class/Section, Submission Date, Status, Marks, Percentage, Action |
| TC-P13 | Report student status badges | Different attempt statuses | EVALUATED → bg-success; SUBMITTED → bg-primary; NOT_STARTED → bg-secondary |
| TC-P14 | Report evaluated marks | Attempt with result | Shows result marks; final percentage in text-primary |
| TC-P15 | Report provisional marks | Attempt without result | Shows provisional marks; text-muted with tooltip |
| TC-P16 | Report search student | Type student name, click Search | Table filtered to matching students |
| TC-P17 | Report clear search | Click refresh after search | Search cleared; all students shown |
| TC-P18 | Report pagination | 25+ students | Page 2 shows next set of students |
| TC-P19 | Report view result button | Click View Result for evaluated student | Opens attempt detail / student result page |
| TC-P20 | Student result page header | Opens student result | Paper title, student name, score circle, pass/fail badge |
| TC-P21 | Student result pass/fail | Student above passing_percentage | Green "Passed" badge; green score circle |
| TC-P22 | Student result fail | Student below passing_percentage | Red "Failed" badge; red score circle |
| TC-P23 | Student result marks display | Result loaded | Marks Obtained / Total Marks shown |
| TC-P24 | Student result question analysis | Sections with questions | Section name, type, question list with marks |
| TC-P25 | Summary filter — class_section | Select class_section, click Search | Papers filtered by class |
| TC-P26 | Summary filter — subject | Select subject, click Search | Papers filtered by subject |
| TC-P27 | Summary filter — exam | Select exam, click Search | Papers filtered by exam |
| TC-P28 | Summary filter — paper | Select paper, click Search | Single paper shown |
| TC-P29 | Summary filter — paper set | Select set via cascading, click Search | Papers filtered by set |
| TC-P30 | Summary filter — date range | Select date range via daterangepicker | Auto-submits; papers filtered by exam start_date |
| TC-P31 | Summary filter — search by title | Type paper title, click Search | Matching papers shown |
| TC-P32 | Summary filter — cascading class→subject | Change class_section | Subject dropdown loads via AJAX |
| TC-P33 | Summary filter — cascading exam→paper→set | Change exam | Paper dropdown loads; change paper → set loads |
| TC-P34 | Summary reset button | Click refresh icon after filtering | Filters cleared; all papers shown |
| TC-P35 | Summary total badge | 10+ papers exist | "N exams" badge shows total count |
| TC-P36 | Paper Check — Student Selector | Open paper check; select student | PDF answer sheet loads in viewer |
| TC-P37 | Paper Check — PDF page navigation | Click next/prev page | PDF pages change; page indicator updates |
| TC-P38 | Paper Check — Zoom in/out | Click zoom +/- | PDF scales; zoom indicator updates |
| TC-P39 | Paper Check — Rotate | Click rotate | PDF rotates 90 degrees |
| TC-P40 | Paper Check — Add Mark annotation | Right-click on PDF | Mark menu appears; select marks to assign |
| TC-P41 | Paper Check — Correct annotation | Select correct tool; click on PDF | Green checkmark annotation placed |
| TC-P42 | Paper Check — Wrong annotation | Select wrong tool; click on PDF | Red X annotation placed |
| TC-P43 | Paper Check — Comment annotation | Select comment tool; click on PDF | Comment dialog opens; text saved |
| TC-P44 | Paper Check — Final Review | Click Final Review | Grade modal opens with student info, evaluation summary, grading form |
| TC-P45 | Grade Modal — Publish Result toggle | Toggle publish on | Becomes visible to student after submit |
| TC-P46 | Grade Modal — Submit grade | Fill marks, feedback, click Submit Grade | Grade saved via PUT; attempt status updated |
| TC-P47 | Check button for online paper | Summary row action column | "Check" button with fa-file-alt icon; route to paper-check |
| TC-P48 | Paper Check — Reset View | Click reset view | Zoom and rotation reset to defaults |
| TC-P49 | Paper Check — Delete Annotation | Drag annotation to "Drop to delete" zone | Annotation removed |
| TC-P50 | Attempt detail — pass/fail logic | Student score >= passing_percentage | Result shows "Passed" |

### 6.2 Negative Test Cases

| TC ID | Scenario | Steps | Expected Result |
|-------|----------|-------|-----------------|
| TC-N01 | Load assessment without permissions | Remove tenant.online-assessment.view | 403 error |
| TC-N02 | Report with non-existent paper_id | Visit `/lms-exam/report/99999` | 404 error |
| TC-N03 | Empty online summary | No online papers exist | "No exams found for the selected filters." |
| TC-N04 | All zero counts | Paper with allocations but no attempts | Assigned=5, Submitted=0, Checked=0 |
| TC-N05 | Invalid date range | Set date_from > date_to | Empty results |
| TC-N06 | No students in report | Paper with no allocations | No students found message; stats all zero |
| TC-N07 | All absent students | Paper where no student attempted | Assigned=5, Submitted=0, Avg Score 0% |
| TC-N08 | Chart with single student | Only 1 student data | Charts render with minimal data |
| TC-N09 | Rapid filter changes | Rapidly change exam dropdown multiple times | Last request wins; paper set dropdown consistent |
| TC-N10 | Invalid attempt_id in student result | Navigate to non-existent attempt | 404 |
| TC-N11 | Paper Check — no attempts | Paper with 0 submitted attempts | Student selector empty |
| TC-N12 | Paper Check — unsupported file | Student uploaded non-PDF | PDF viewer may show error or blank |
| TC-N13 | Paper Check — corrupted PDF | Student uploaded corrupt PDF | pdf.js shows error; placeholder visible |
| TC-N14 | Grade modal — marks > total_marks | Enter 150 when max=100 | Validation error |
| TC-N15 | Grade modal — negative marks | Enter -10 | Validation error |
| TC-N16 | Grade modal — empty marks | Leave marks blank | Marks submitted as null; possibly rejected |
| TC-N17 | No attempts for selected paper in report | Paper with allocations but no attempts | All stats zero; student table shows all as NOT_STARTED |
| TC-N18 | Student result — not submitted | Visit result for NOT_STARTED attempt | "Attempt is not yet submitted." message |
| TC-N19 | Filter combo with no matches | class_section for different grade | Empty summary |
| TC-N20 | daterangepicker with invalid format | Manually modify date from hidden field | Filter may not apply; no crash |
| TC-N21 | Invalid attempt_id (ghost/missing) in saveEvaluationAnswerGrade | Auto-creates new attempt from allocation; student_id must be in request | — | — | ⬜ |
| TC-N22 | Annotated PDF upload failure in saveEvaluationAnswerGrade | Storage exception caught+logged; grade saved but file may be missing | — | — | ⬜ |

### 6.3 Dependency / Integration Test Cases

| TC ID | Scenario | Steps | Expected Result |
|-------|----------|-------|-----------------|
| TC-D01 | Summary → Report navigation | Click Report button | Navigates to report page for that paper |
| TC-D02 | Report → Student Result navigation | Click View Result | Opens student result page |
| TC-D03 | Summary → Paper Check navigation | Click Check button | Opens Paper Check interface |
| TC-D04 | Online ↔ Offline assessment tabs | Switch between tabs | Both load correct data |
| TC-D05 | Assessment reflects upload changes | Upload marks in Upload tab; check summary | Checked count increases by 1 |
| TC-D06 | Paper Check grade → summary updated | Submit grade in Paper Check | Checked count increments; status changes |
| TC-D07 | Report avg score calculation | Multiple evaluated attempts | Avg reflects actual scores |
| TC-D08 | Cache — class section list stale | Add new class_section | May not show until cache (3600s) expires |
| TC-D09 | Search in report filters student table | Search student name | Only matching students shown |
| TC-D10 | Provisional → final marks transition | Evaluate PENDING attempt | Marks change from provisional to final |
| TC-D11 | Multiple papers for same exam | Create 3 online papers for 1 exam | All 3 appear in summary |
| TC-D12 | Tenant isolation | Tenant A and Tenant B data | Each sees only own papers |
| TC-D13 | Paper Check annotation persists | Place annotation → page navigation → return | Annotation still present |
| TC-D14 | Paper Check — switch students | Select Student A → annotate → select Student B | Student A annotations preserved; B's PDF loads |
| TC-D15 | Allocations across multiple types | SECTION + CLASS + STUDENT + GROUP allocations | All student IDs resolved in report |
| TC-D16 | Paper with 100+ allocated students | Large allocation count | Summary shows correct Assigned count; Report paginates at 25/page |
| TC-D17 | Chart.js CDN failure | Block chart.js CDN | Charts fail to render; page still functional |
| TC-D18 | MathJax rendering in questions | Question text with LaTeX | Student result renders math content |
| TC-D19 | Publish result → student sees grade | Toggle publish; check student portal | Result visible to student |
| TC-D20 | Student result — pass/fail border color | Pass → green top border; Fail → red | Visual differentiation |
| TC-D21 | CR | Code Review | P1 | Controller — Ghost Attempt Auto-Creation in saveEvaluationAnswerGrade | When attempt_id provided but attempt record not found (deleted/ghost), code auto-creates EVALUATION_PENDING attempt from ExamAllocation; requires student_id in request (not validated) | — | — | ◌ |
| TC-D22 | CR | Code Review | P1 | Controller — Annotated PDF Upload Soft-Fail | If annotated_pdf storage fails, exception is caught and logged; response still returns success:true (grade saved, file silently not saved) | — | — | ◌ |

### 6.4 Code Review / Static Analysis

| TC ID | Scenario | Expected Observation |
|-------|----------|----------------------|
| TC-CR01 | assessment() method | Clones baseQuery for online/offline; applies mode filter separately |
| TC-CR02 | applyExamFilters() | Filters: class_section_id, subject_id, exam_id, exam_paper_id, exam_set_id, date_range, search |
| TC-CR03 | withCount for submitted/checked | Closure scopes: submitted (6 statuses), checked (2 statuses) |
| TC-CR04 | report() allocation resolution | Handles SECTION, CLASS, STUDENT, EXAM_GROUP allocation types |
| TC-CR05 | report() manual pagination | 25 per page; LengthAwarePaginator with query string persistence |
| TC-CR06 | report() avg score calculation | Iterates all attempts; evaluates result.percentage or provisional |
| TC-CR07 | report() chart data | participationData: 3 segments; scoreData: 5 bins |
| TC-CR08 | View — summary table class/section badge | `$paper->allocations->first()?->section?->name ?? 'Mixed'` |
| TC-CR09 | View — Check button conditional | If mode=ONLINE or offline_entry_mode=QUESTION_WISE → paper-check route; else → paper-check.bulk |
| TC-CR10 | View — mode hidden input | `<input type="hidden" name="mode" value="ONLINE">` |
| TC-CR11 | View — daterangepicker auto-submit | `apply.daterangepicker` and `cancel.daterangepicker` events call form.submit() |
| TC-CR12 | View — cascading AJAX error handling | No explicit .fail() handlers; may hang on "Loading..." |
| TC-CR13 | View — student result pass/fail logic | Uses `$result->isPassed()` if result exists; else compares to `$paper->passing_percentage` |
| TC-CR14 | View — student result question analysis | Groups by blueprint section; shows section scores |
| TC-CR15 | View — HTML-preview in paper-check | `#cbse-html-preview` div for non-PDF content; class `d-none` by default |
| TC-CR16 | View — grade modal PUT method | `@method('PUT')` in form |
| TC-CR17 | View — annotation toolbar | 9 tools: marks, repeat, view, blank, comment, correct, wrong, text, pen |
| TC-CR18 | View — delete drop zone | `#cbse-delete-drop-zone` with dashed border |
| TC-CR19 | View — mobile responsive tabs | `#cbse-mobile-nav` with viewer/questions/tools tabs; hidden on lg+ |
| TC-CR20 | View — print styles | `.d-print-none` / `.d-print-block` classes |
| TC-CR21 | View — canvas size | `#cbse-canvas-wrap` with box-shadow; annotation layer position-absolute |
| TC-CR22 | View — toast container | Bottom-right position-fixed toast for feedback |
| TC-CR23 | View — MathJax configuration | tex2jax with inline/display math delimiters; processEscapes: true |
| TC-CR24 | View — student result MathJax processing | processMathContent() checks for HTML/LaTeX before wrapping |
| TC-CR25 | JS — initExamSummary function | Per-tab initialization; handles daterangepicker, cascading dropdowns |
| TC-CR26 | JS — daterangepicker ranges | Today, Yesterday, Last 7/30 Days, This/Last Month |
| TC-CR27 | JS — tab activation triggers init | `shown.bs.tab` event re-initializes daterangepicker |
| TC-CR28 | JS — paper-check PDF loader | `#cbse-pdf-loader` with spinner; shown/hidden during load |
| TC-CR29 | JS — annotation drag behavior | `.cbse-ann-item` with `cursor: move`; active state on selection |
| TC-CR30 | Controller — route authorization | assessment(): gates both online and offline permissions |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Load online assessment tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/lms-exam/assessment?active_tab=online_assessment` | Page loads with assessment tabs |
| 2 | Verify online_assessment pane is active | show active class present |
| 3 | Verify table | Summary table with all online papers |

#### TC-P02: Summary columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect table header | Columns: Exam Title, Class / Section / Subject, Mode, Exam Date, Assigned, Submitted, Checked, Action |

#### TC-P03: Online mode badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find paper with mode=ONLINE | Badge "Online" (bg-primary) displayed |

#### TC-P04: Assigned count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find paper with 5 allocations | "5" badge (bg-primary) in Assigned column |

#### TC-P05: Submitted count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 3 students with SUBMITTED+ status | "3" badge (bg-info text-dark) in Submitted column |

#### TC-P06: Checked count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 2 students with EVALUATED+ status | "2" badge (bg-success) in Checked column |

#### TC-P07: Report button

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Report button for any paper | Navigates to report page for that paper |

#### TC-P08: Report header info

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Observe report page header | Paper title, class name, subject name, exam title displayed |

#### TC-P09: Report stats cards

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Scroll to stats row | 4 cards: Total Assigned (blue), Total Attempts (info), Evaluated (green), Avg Score (yellow) |

#### TC-P10: Report participation chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify doughnut chart | 3 segments: Evaluated (green), Pending (yellow), Not Attempted (red) |

#### TC-P11: Report score distribution chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify bar chart | X-axis: 0-20%, 21-40%, 41-60%, 61-80%, 81-100%; Y-axis: student counts |

#### TC-P12: Report student table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Scroll to student table | Columns: Student Name, Admn No, Class/Section, Submission Date, Status, Marks, Percentage, Action |

#### TC-P13: Report status badges

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student with EVALUATED status | Badge bg-success "EVALUATED" |
| 2 | Student with SUBMITTED | Badge bg-primary "SUBMITTED" |
| 3 | Student with NOT_STARTED | Badge bg-secondary "NOT STARTED" |

#### TC-P14: Report evaluated marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Evaluated student with result | Shows "17 / 20" (fw-bold); percentage shown as "85%" (text-primary fw-bold) |

#### TC-P15: Report provisional marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | SUBMITTED student without result | Shows provisional marks in text-muted; percentage with tooltip "Provisional Percentage" |

#### TC-P16: Report search student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Type student name in search box | Input field populated |
| 2 | Click Search | Table filtered to matching students |

#### TC-P17: Report clear search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply search filter | Filtered results |
| 2 | Click refresh icon | URL cleared; all students shown |

#### TC-P18: Report pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 30 students exist | Page 1 shows 25 |
| 2 | Click page 2 | Next 5 students shown |

#### TC-P19: Report view result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click View Result for evaluated student | Navigates to student result page |

#### TC-P20: Student result page header

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load student result | Paper title, student name, admission no shown; score circle with percentage |

#### TC-P21: Student result pass

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Score above passing_percentage | Green border; "Passed" badge (bg-success); green score circle |

#### TC-P22: Student result fail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Score below passing_percentage | Red border; "Failed" badge (bg-danger); red score circle |

#### TC-P23: Student result marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify marks card | "17 / 20" displayed; "Marks Obtained" label |

#### TC-P24: Student result question analysis

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Scroll to question analysis | Sections listed with section name, type, target info |
| 2 | Click through sections | Each question shown with marks, status, evaluated answer |

#### TC-P25: Summary filter — class_section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class_section from dropdown | Dropdown populated |
| 2 | Click Search | Papers filtered to selected class |

#### TC-P26: Summary filter — subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select subject | Dropdown populated |
| 2 | Click Search | Papers filtered to subject |

#### TC-P27: Summary filter — exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select exam via cascading | Exam options loaded |
| 2 | Click Search | Papers filtered to exam |

#### TC-P28: Summary filter — paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select exam_paper_id | Paper options loaded |
| 2 | Click Search | Single paper shown |

#### TC-P29: Summary filter — paper set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select exam_set_id via cascading | Set options loaded from paper change |
| 2 | Click Search | Papers with that set shown |

#### TC-P30: Summary filter — date range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open daterangepicker | Calendar UI shown |
| 2 | Select "Last 7 Days" | Input populated; form auto-submitted |
| 3 | Verify filter applied | Papers with exam start_date in last 7 days shown |

#### TC-P31: Summary filter — search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter paper title in search box | Input populated |
| 2 | Click Search | Matching papers shown |

#### TC-P32: Cascading class→subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class_section | Subject dropdown shows "Loading..." then populated |
| 2 | Verify subject options | Subjects for that class/section loaded |

#### TC-P33: Cascading exam→paper→set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select exam | Paper dropdown shows "Loading..." then populated |
| 2 | Select paper | Set dropdown shows "Loading..." then populated |

#### TC-P34: Summary reset

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply multiple filters | URL has query params |
| 2 | Click refresh icon (btn-secondary) | All filters reset; URL back to base |

#### TC-P35: Summary total badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 10+ online papers exist | "N exams" badge (bg-secondary) in header |

#### TC-P36: Paper Check student selector

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Paper Check page | Page loads with three-column layout |
| 2 | Select student from dropdown | PDF answer sheet loads in center viewer |

#### TC-P37: PDF page navigation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click next page button | PDF viewer shows next page |
| 2 | Click prev page button | Previous page shown |
| 3 | Verify page indicator | "Page 2 / 5" updates correctly |

#### TC-P38: Zoom in/out

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click zoom in (+) | PDF scales up; "125%" shown |
| 2 | Click zoom out (-) | PDF scales down |

#### TC-P39: Rotate PDF

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click rotate button | PDF rotates 90 degrees clockwise |

#### TC-P40: Add Mark annotation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Right-click on PDF area | Mark menu appears near cursor |
| 2 | Select "3" marks | Number 3 annotation placed on PDF |

#### TC-P41: Correct annotation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Correct tool (green checkmark) | Tool activates; label shows "Active Tool: Correct" |
| 2 | Click on PDF answer area | Green checkmark annotation placed |

#### TC-P42: Wrong annotation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Wrong tool (red X) | Tool activates |
| 2 | Click on PDF | Red X annotation placed |

#### TC-P43: Comment annotation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Comment tool | Tool activates |
| 2 | Click on PDF | Comment box appears; type text and save |

#### TC-P44: Final Review modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Final Review" button | Grade modal opens (modal-xl) |
| 2 | Verify modal content | Student name, exam paper, evaluation summary, grading form |

#### TC-P45: Publish Result toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check "Publish Result" toggle | Checkbox checked |
| 2 | Submit grade | Result published to student |

#### TC-P46: Submit grade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter marks_obtained=18 | Input valid |
| 2 | Select grading status "Checked" | Status selected |
| 3 | Enter teacher feedback "Good work" | Text entered |
| 4 | Click Submit Grade | PUT request sent; success toast; modal closes |

#### TC-P47: Check button in summary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find online paper row | Action column shows Check button (btn-outline-info, fa-file-alt) |
| 2 | Click Check | Opens paper check route for that paper |

#### TC-P48: Reset view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Zoom to 150% and rotate | View modified |
| 2 | Click Reset View | Zoom=100%; rotation=0 |

#### TC-P49: Delete annotation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Place an annotation on PDF | Annotation visible |
| 2 | Drag annotation to "Drop to delete" zone | Annotation disappears |

#### TC-P50: Pass/fail logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create result with 85% for paper with passing_percentage=40 | Passed badge |
| 2 | Create result with 30% for same paper | Failed badge |

### 7.2 Negative TC Steps

#### TC-N01: No permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Remove tenant.online-assessment.view | User loses access |
| 2 | Load assessment page | 403 AuthorizationException |

#### TC-N02: Non-existent report paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/lms-exam/report/99999` | 404 ModelNotFoundException |

#### TC-N03: Empty online summary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete all online papers | No papers match mode=ONLINE |
| 2 | Load online assessment tab | "No exams found for the selected filters." with colspan=9 |

#### TC-N04: All zero counts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with 5 allocations, 0 attempts | Assigned=5, Submitted=0, Checked=0 |

#### TC-N05: Invalid date range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date_from=2026-07-01, date_to=2026-01-01 | No papers match inverted range; empty table |

#### TC-N06: No student sessions in report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper with allocations but no student_academic_sessions | "No students found." in table; stats=0 |

#### TC-N07: All absent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 5 allocations, 0 attempts | Total Attempts=0; Avg Score=0%; all NOT_STARTED |

#### TC-N08: Single student chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 1 student evaluated | Participation chart: 1 segment; Score chart: 1 bar |

#### TC-N09: Rapid filter changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Rapidly change exam dropdown 5 times | Only last AJAX response populates paper dropdown |

#### TC-N10: Invalid attempt detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/lms-exam/attempt/99999` | 404 |

#### TC-N11: Paper Check no attempts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open paper check for paper with 0 submitted attempts | Student selector shows no options; viewer shows placeholder |

#### TC-N12: Unsupported file

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student uploaded .docx instead of PDF | PDF viewer may show html-preview or error |

#### TC-N13: Corrupted PDF

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student uploaded corrupted PDF | pdf.js fails gracefully; loading spinner remains or error shown |

#### TC-N14: Marks > total

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter marks_obtained=150 when max=100 | Validation error; grade not submitted |

#### TC-N15: Negative marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter -10 as marks_obtained | Validation rejects; error shown |

#### TC-N16: Empty marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave marks_obtained blank | May submit as null; server may reject |

#### TC-N17: No attempts in report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper with allocations but 0 attempts | Total Attempts=0; Avg Score=0% |

#### TC-N18: Not submitted result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open result for NOT_STARTED attempt | "Attempt is not yet submitted." message |

#### TC-N19: No filter matches

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class_section for a different grade | Empty summary table |

#### TC-N20: Invalid date format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manually set date_from=abc | Filter may not apply; no crash |

### 7.3 Dependency TC Steps

#### TC-D01: Summary to Report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Report button for paper | Navigates to report? |
| 2 | Verify paper ID matches | Same paper context |

#### TC-D02: Report to Student Result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click View Result for a student | Navigates to attempt detail page |

#### TC-D03: Summary to Paper Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Check for online paper | Paper check interface opens |

#### TC-D04: Online/Offline tab switch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click online_assessment tab | Online data shown |
| 2 | Click offline_assessment tab | Offline data shown |

#### TC-D05: Upload → summary sync

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload marks in Upload tab | is_evaluated=1 |
| 2 | Navigate to Assessment tab | Checked count incremented |

#### TC-D06: Paper Check → summary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit grade in Paper Check | Attempt status → EVALUATED |
| 2 | Load assessment summary | Checked count includes this attempt |

#### TC-D07: Avg score calculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 3 attempts: 80%, 90%, 70% | Avg Score = 80% |

#### TC-D08: Cache delay

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add new class_section | Not visible until cache (3600s) expires |

#### TC-D09: Search filters student table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search "John" | Only students named John shown |

#### TC-D10: Provisional to final

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Evaluate pending attempt | Marks change from provisional (text-muted) to final (text-primary) |

#### TC-D11: Multiple papers per exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 papers for same exam | All 3 rows in summary |

#### TC-D12: Tenant isolation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tenant A: 5 online papers | Summary shows 5 |
| 2 | Tenant B: 3 online papers | Summary shows 3 |

#### TC-D13: Annotation persistence

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Place annotation on page 1 | Annotation visible |
| 2 | Go to page 2 | Page 2 loads |
| 3 | Return to page 1 | Annotation still present |

#### TC-D14: Switch students in Paper Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Student A, place annotation | A's PDF with annotation |
| 2 | Select Student B | B's PDF loads; A's annotations not visible |
| 3 | Select Student A again | A's annotations restored |

#### TC-D15: Multi-type allocations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create SECTION, CLASS, STUDENT, GROUP allocations | All resolved in report student list |

#### TC-D16: Large allocation count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 100 students allocated | Assigned=100; Report paginated at 25/page = 4 pages |

#### TC-D17: Chart.js CDN failure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Block CDN | Charts show empty canvas; page still functional |

#### TC-D18: MathJax rendering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Question with `\(x^2\)` | Math rendered correctly in student result |

#### TC-D19: Published result visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit grade with publish toggle on | Student can see grade in portal |
| 2 | Submit grade without publish | Student cannot see grade |

#### TC-D20: Pass/fail border color

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Passed student | Green top border (5px solid #198754) |
| 2 | Failed student | Red top border (5px solid #dc3545) |

### 7.4 Code Review TC Steps

#### TC-CR01: assessment() method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect assessment() | Base query cloned; online vs offline mode applied separately |

#### TC-CR02: applyExamFilters() comprehensive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect applyExamFilters | Handles class_section_id, subject_id, exam_id, exam_paper_id, exam_set_id, date_from/to, search |

#### TC-CR03: withCount closures

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect withCount('attempts as total_submitted') | Closure filters by 6 statuses |
| 2 | Inspect withCount('attempts as total_checked') | Closure filters by 2 statuses |

#### TC-CR04: report() allocation types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect allocation switch | 4 cases: SECTION, CLASS, STUDENT, EXAM_GROUP |
| 2 | Verify SECTION resolution | Uses class_section_jnt_id or class_id+section_id fallback |

#### TC-CR05: report() manual pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect pagination code | 25 per page; resolveCurrentPage; LengthAwarePaginator |

#### TC-CR06: report() avg score

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect avg calculation | Iterates all attempts; sums result% or provisional%; divides by scored count |

#### TC-CR07: report() chart data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect participationData | 3 labels: Evaluated, Pending, Not Attempted |
| 2 | Inspect scoreData | 5 bins; iterates all attempts |

#### TC-CR08: View section badge fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect section badge | `$paper->allocations->first()?->section?->name ?? 'Mixed'` |

#### TC-CR09: Check button route logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect condition | `if(mode==ONLINE || offline_entry_mode==QUESTION_WISE) → paper-check` else `→ paper-check.bulk` |

#### TC-CR10: Mode hidden input

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect form | `<input type="hidden" name="mode" value="ONLINE">` for online tab |

#### TC-CR11: Daterangepicker auto-submit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect apply event | `$('#examSummaryFilter_').submit()` called |
| 2 | Inspect cancel event | Same submit() called with cleared values |

#### TC-CR12: Cascading AJAX no fail handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect class_section change AJAX | No .fail() handler; "Loading..." persists on error |

#### TC-CR13: Pass/fail logic in result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect isPass condition | Uses `$result->isPassed()` if result exists; else compares to `$paper->passing_percentage` |

#### TC-CR14: Question analysis grouping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blueprint loop | Groups questions by blueprint section; shows section scores |

#### TC-CR15: HTML preview fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect #cbse-html-preview | d-none by default; used for non-PDF answers |

#### TC-CR16: Grade modal PUT method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect gradeForm | `@method('PUT')` blade directive |

#### TC-CR17: Annotation toolbar tools

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect toolbar | 9 data-tool values: mark, repeat, view, blank, comment, correct, wrong, text, pen |

#### TC-CR18: Delete drop zone

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect #cbse-delete-drop-zone | border-dashed class; positioned near header |

#### TC-CR19: Mobile responsive tabs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect #cbse-mobile-nav | d-lg-none; 3 tabs: Viewer, Questions, Tools |

#### TC-CR20: Print styles

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect print classes | d-print-none on UI elements; d-print-block on print report |

#### TC-CR21: Canvas annotation layer

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect #cbse-annotation-layer | position-absolute; top-0; start-0; w-100; h-100; z-index:10; pointer-events:none |

#### TC-CR22: Toast container

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect toast | position-fixed bottom-0 end-0; text-bg-dark |

#### TC-CR23: MathJax config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect MathJax config | tex2jax with inlineMath (\\\\($\\\\)) and displayMath (\\\\[$\\\\]); processEscapes:true |

#### TC-CR24: MathJax content processing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect processMathContent | Skips if contains HTML or already LaTeX; wraps in \\( \\) |

#### TC-CR25: initExamSummary JS

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect function | Accepts tabId; initializes daterangepicker per tab |

#### TC-CR26: Daterangepicker ranges

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect ranges | Today, Yesterday, Last 7 Days, Last 30 Days, This Month, Last Month |

#### TC-CR27: Tab activation re-init

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect shown.bs.tab | Calls initExamSummary() again for tab |

#### TC-CR28: PDF loader

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect #cbse-pdf-loader | d-none by default; shown during PDF load; spinner + text |

#### TC-CR29: Annotation drag

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect .cbse-ann-item CSS | cursor: move; scale(1.1) on hover; active state with blue shadow |

#### TC-CR30: Route authorization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect assessment() | Two Gate::authorize calls (online + offline) |
| 2 | Inspect report() | Gate::authorize('tenant.exam.viewAny') |
