# lms_ExamSummary_TcList

## Module: LmsExam → Exam Management → Assessment → Exam Summary

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Exam Management → Assessment |
| Feature | Exam Summary |
| URL(s) | `GET /exam/master?active_tab=exam_summary` (summary tab), `GET /exam/assessment/index` (standalone), `GET /exam/assessment?active_tab=online_assessment` (online), `GET /exam/assessment?active_tab=offline_assessment` (offline), `GET /exam/exam/{paperId}/report` (report) |
| Controller | `Modules\LmsExam\Http\Controllers\LmsExamController@masters()` (conditional), `LmsExamController@examSummary()` (dedicated) |
| Model(s) | `Modules\LmsExam\Models\ExamPaper` (with exam, class, subject, status, allocations, attempts) |
| View Paths | `resources/views/summary/index.blade.php`, `resources/views/summary/online_index.blade.php`, `resources/views/summary/offline_index.blade.php`, `resources/views/summary/report.blade.php`, `resources/views/summary/student_result.blade.php` |
| Service | `LmsExamQueryService` (for filter queries), `ExamDashboardService` |
| Libraries | daterangepicker, moment.js, Chart.js (report page) |
| Pagination | 10/page with custom page name `summary_page` |
| Filters | Class/Section, Subject, Exam, Paper, Paper Set, Date Range, Search (title/paper_code/exam title) |
| Tables | `lms_exam_papers`, `lms_exams`, `lms_exam_allocations`, `lms_exam_attempts`, `sch_classes`, `sch_sections`, `sch_subjects`, `lms_exam_paper_sets` |
| Computed Fields | `total_assigned` (allocations count), `total_submitted` (attempts with status in SUBMITTED/EVALUATION_PENDING/EVALUATED/RESULT_PUBLISHED), `total_checked` (attempts with status in EVALUATED/RESULT_PUBLISHED) |

---

## 2. Pre-conditions

- Required permissions: `tenant.exam.viewAny`
- Tenant context via `tenancy()->initialize()`
- At least one exam paper (online or offline) must exist in `lms_exam_papers`
- `lms_exam_allocations` must have records for assigned count
- `lms_exam_attempts` must have records for submitted/checked counts
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

When the page loads via `LmsExamController@masters()` with `active_tab=exam_summary`:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Summary Papers | `ExamPaper::with(exam, class, subject, status)->withCount(allocations, attempts)` | All papers with counts | class_section_id, subject_id, exam_id, exam_paper_id, exam_set_id, mode (both), date_from, date_to, search | 10/page (`summary_page`) |
| Class Section List (filter) | `ClassSection::with(class,section)->where('is_active',1)` | All active class-sections | is_active | None |
| Subjects (filter) | `SubjectStudyFormat::with(subject,studyFormat)` or `Subject::where('is_active',1)` | Based on class filter | class_section_id (cascade) | None |
| Exams (filter) | `Exam::where('is_active', true)->orderBy('title')` | Active exams | is_active | None |
| Papers (filter) | Dynamic via AJAX `get-papers-by-exam` | Based on exam_id | exam_id | None |
| Paper Sets (filter) | Dynamic via AJAX `get-sets-by-paper` | Based on exam_paper_id | exam_paper_id | None |

## 4. Test Data Strategy

- **Exam papers**: Create papers with known mode (ONLINE/OFFLINE), class, subject, exam relationships
- **Allocations**: Create allocation records for assigned count testing
- **Attempts**: Create attempts with various statuses (SUBMITTED, EVALUATED, EVALUATION_PENDING, RESULT_PUBLISHED, IN_PROGRESS) for submitted/checked counts
- **Date range**: Use exam start_date spanning multiple months
- **Cascading filters**: Class → Subject, Exam → Paper → Set chain via AJAX
- **Pre-test cleanup**: Delete created exam papers and related records after tests

---

## 5. Business Conditions

### 4.1 Database Schema — Relevant Tables

| BC ID | Column | Table | Type | Constraints |
|-------|--------|-------|------|-------------|
| BC-DB-01 | id | lms_exam_papers | INT PK | Auto-increment |
| BC-DB-02 | exam_id | lms_exam_papers | INT FK | FK → lms_exams.id |
| BC-DB-03 | class_id | lms_exam_papers | INT FK | FK → sch_classes.id |
| BC-DB-04 | subject_id | lms_exam_papers | INT FK | FK → sch_subjects.id |
| BC-DB-05 | mode | lms_exam_papers | ENUM | ONLINE, OFFLINE |
| BC-DB-06 | title | lms_exam_papers | VARCHAR | Paper title |
| BC-DB-07 | paper_code | lms_exam_papers | VARCHAR | Unique paper code |
| BC-DB-08 | offline_entry_mode | lms_exam_papers | ENUM NULL | BULK_TOTAL, QUESTION_WISE |
| BC-DB-09 | is_ques_wise_file_upload | lms_exam_papers | TINYINT | 0 or 1 |
| BC-DB-10 | total_marks | lms_exam_papers | DECIMAL | Possible total marks |
| BC-DB-11 | start_date | lms_exams | DATETIME | Exam start date |
| BC-DB-12 | end_date | lms_exams | DATETIME | Exam end date |
| BC-DB-13 | id | lms_exam_allocations | INT FK | FK → lms_exam_papers.id |
| BC-DB-14 | id | lms_exam_attempts | INT FK | FK → lms_exam_papers.id |
| BC-DB-15 | status | lms_exam_attempts | ENUM | Attempt statuses |

### 4.2 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | tenant.exam.viewAny | Access to exam summary tab |
| BC-AUTH-02 | Guest access | Redirect to /login |

### 4.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Summary tab loads | Table shows all exam papers with assigned/submitted/checked counts |
| BC-BIZ-02 | Filter by class/section | Papers filtered by class_id derived from class_section_id |
| BC-BIZ-03 | Filter by subject | Papers filtered by subject_id |
| BC-BIZ-04 | Filter by exam | Papers filtered by exam_id |
| BC-BIZ-05 | Filter by paper | Papers filtered by exam_paper_id |
| BC-BIZ-06 | Filter by paper set | Papers filtered by exam_set_id |
| BC-BIZ-07 | Filter by date range | Papers where exam.start_date between date_from and date_to |
| BC-BIZ-08 | Search by title/paper_code | Papers matching search term in title, paper_code, or exam title |
| BC-BIZ-09 | Cascading class→subject | Selecting class dynamically loads subjects for that class |
| BC-BIZ-10 | Cascading exam→paper | Selecting exam dynamically loads papers for that exam |
| BC-BIZ-11 | Cascading paper→set | Selecting paper dynamically loads paper sets |
| BC-BIZ-12 | Date range auto-submit | Selecting date range presets auto-submits the form |
| BC-BIZ-13 | Clear filters | Reset button clears all filters |
| BC-BIZ-14 | Assigned count = allocations count | `total_assigned` = count of allocation records |
| BC-BIZ-15 | Submitted count = attempts with submission status | `total_submitted` = count with status in (SUBMITTED, EVALUATION_PENDING, EVALUATED, RESULT_PUBLISHED) |
| BC-BIZ-16 | Checked count = evaluated attempts | `total_checked` = count with status in (EVALUATED, RESULT_PUBLISHED) |
| BC-BIZ-17 | Action buttons vary by mode | ONLINE → online paper-check; OFFLINE + QUESTION_WISE → offline check; OFFLINE + BULK → bulk check |
| BC-BIZ-18 | Report link opens per-student report | Route `lms-exam.exam.report` with paper ID |
| BC-BIZ-19 | Pagination uses `summary_page` name | Avoids conflict with other paginated elements |
| BC-BIZ-20 | Both modes shown in summary | Summary does NOT filter by mode (unlike online/offline tabs) |
| BC-BIZ-21 | Empty state | "No exams found for the selected filters." displayed |
| BC-BIZ-22 | Class badge + section display | Class name badge, section name badge, subject name shown |
| BC-BIZ-23 | Mode badge | Online = primary badge; Offline = secondary badge + Bulk/Question Wise indicator |
| BC-BIZ-24 | Exam date formatting | Start date formatted as "d M, Y" |
| BC-BIZ-25 | Paper title + code display | Bold title + gray paper_code and exam title |
| BC-BIZ-26 | Filter persistence in pagination | All filter params passed to pagination links via `appends()` |
| BC-BIZ-27 | Report page — statistics cards | Total Assigned, Total Attempts, Evaluated, Avg Score cards |
| BC-BIZ-28 | Report page — charts | Participation Summary (doughnut) and Score Distribution (bar) |
| BC-BIZ-29 | Report page — student table | Student-wise performance with marks, percentage, status |
| BC-BIZ-30 | Report page — search student | Student table filters by name search |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Exam Summary Tab Loads With All Elements | Filters bar, table with 8 columns, pagination visible | — | — | ⬜ |
| TC-P02 | All Papers Shown (Both Modes) | Both ONLINE and OFFLINE papers visible in same table | — | — | ⬜ |
| TC-P03 | Table Columns Display Correctly | Exam Title, Class/Section/Subject, Mode, Exam Date, Assigned, Submitted, Checked, Action | — | — | ⬜ |
| TC-P04 | Filter By Class/Section | Selecting class-section filters papers for that class | — | — | ⬜ |
| TC-P05 | Filter By Subject (After Class Selected) | Subject dropdown populated based on class, filters papers | — | — | ⬜ |
| TC-P06 | Filter By Exam | Only papers belonging to selected exam shown | — | — | ⬜ |
| TC-P07 | Filter By Paper | Only selected paper shown | — | — | ⬜ |
| TC-P08 | Filter By Paper Set | Only papers with that set shown | — | — | ⬜ |
| TC-P09 | Filter By Date Range (Preset: Last 7 Days) | Papers within last 7 days shown | — | — | ⬜ |
| TC-P10 | Filter By Date Range (Custom) | Custom date range filters correctly | — | — | ⬜ |
| TC-P11 | Filter By Search (Paper Title) | Papers matching title keyword shown | — | — | ⬜ |
| TC-P12 | Filter By Search (Paper Code) | Papers matching paper_code shown | — | — | ⬜ |
| TC-P13 | Filter By Search (Exam Title) | Papers whose parent exam matches shown | — | — | ⬜ |
| TC-P14 | Multi-Filter: Class + Exam + Date Range | All filters applied together | — | — | ⬜ |
| TC-P15 | Clear Filters | Reset clears all filters, shows all papers | — | — | ⬜ |
| TC-P16 | Cascading Class→Subject AJAX | Selecting class triggers subject dropdown update | — | — | ⬜ |
| TC-P17 | Cascading Exam→Paper→Set AJAX | Selecting exam triggers paper dropdown; paper triggers set | — | — | ⬜ |
| TC-P18 | Date Range Auto-Submit | Selecting a date range preset auto-submits the form | — | — | ⬜ |
| TC-P19 | Pagination (10 Per Page) | Page 2 shows next 10 records, prev/next links work | — | — | ⬜ |
| TC-P20 | Pagination Preserves Filters | Filter params persist in pagination URL | — | — | ⬜ |
| TC-P21 | Assigned Count Shows Allocation Count | Badge shows correct number of allocated students | — | — | ⬜ |
| TC-P22 | Submitted Count Shows Attempt Count | Badge shows correct number of submitted attempts | — | — | ⬜ |
| TC-P23 | Checked Count Shows Evaluated Count | Badge shows correct number of evaluated attempts | — | — | ⬜ |
| TC-P24 | All Counts Zero For New Paper | New paper with no allocations/attempts → all counts 0 | — | — | ⬜ |
| TC-P25 | ONLINE Paper — Mode Badge Shows "Online" | Blue "Online" badge | — | — | ⬜ |
| TC-P26 | OFFLINE Paper — Mode Badge Shows "Offline" | Gray "Offline" badge + "Bulk" or "Question Wise" | — | — | ⬜ |
| TC-P27 | OFFLINE + QUESTION_WISE — "Question Wise" Badge | Shows "Question Wise" badge next to "Offline" | — | — | ⬜ |
| TC-P28 | OFFLINE + BULK_TOTAL — "Bulk" Badge | Shows "Bulk" badge next to "Offline" | — | — | ⬜ |
| TC-P29 | Action — Report Button | "Report" button links to detailed student report | — | — | ⬜ |
| TC-P30 | Action — Check Button For ONLINE Paper | "Check" links to online paper-check route | — | — | ⬜ |
| TC-P31 | Action — Check Button For OFFLINE + QUESTION_WISE | "Check" links to offline paper-check route | — | — | ⬜ |
| TC-P32 | Action — Check Button For OFFLINE + BULK | "Check" links to bulk paper-check route | — | — | ⬜ |
| TC-P33 | Empty State — No Papers Match Filters | "No exams found for the selected filters." displayed | — | — | ⬜ |
| TC-P34 | Paper Title Display With Code | Bold title + gray "paper_code • exam_title" below | — | — | ⬜ |
| TC-P35 | Class Badge Display | Class name shown as info badge | — | — | ⬜ |
| TC-P36 | Section Display | Section name shown as light badge (or "Mixed" if multiple) | — | — | ⬜ |
| TC-P37 | Subject Name Display | Subject name below class/section badges | — | — | ⬜ |
| TC-P38 | Exam Date Format | Date formatted as "15 Jun, 2025" | — | — | ⬜ |
| TC-P39 | Report Page Loads | Statistics cards, charts, student performance table visible | — | — | ⬜ |
| TC-P40 | Report Page — Statistics Cards | Total Assigned, Total Attempts, Evaluated, Avg Score cards with correct values | — | — | ⬜ |
| TC-P41 | Report Page — Participation Chart | Doughnut chart showing participation summary | — | — | ⬜ |
| TC-P42 | Report Page — Score Distribution Chart | Bar chart showing score distribution | — | — | ⬜ |
| TC-P43 | Report Page — Student Table | Student names, admission no, class/section, submission date, status, marks, percentage, action | — | — | ⬜ |
| TC-P44 | Report Page — Search Student | Student table filters by name | — | — | ⬜ |
| TC-P45 | Online Assessment Tab (Filtered) | Only ONLINE papers shown | — | — | ⬜ |
| TC-P46 | Offline Assessment Tab (Filtered) | Only OFFLINE papers shown | — | — | ⬜ |
| TC-P47 | Summary Shows All Papers (No Mode Filter) | All ONLINE + OFFLINE papers together | — | — | ⬜ |
| TC-P48 | Multiple Date Range Presets | Today, Yesterday, Last 7 Days, Last 30 Days, This Month, Last Month work | — | — | ⬜ |
| TC-P49 | Student Result Page Load | Per-student detailed result view with marks breakdown | — | — | ⬜ |
| TC-P50 | Pagination Count Display On Tab Header | Badge shows total count: "X exams" | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No Permission (Missing tenant.exam.viewAny) | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N02 | Guest Access Redirect | Redirect to /login | — | — | ⬜ |
| TC-N03 | No Papers Exist | Empty state with message | — | — | ⬜ |
| TC-N04 | Invalid Class ID Filter | Empty results | — | — | ⬜ |
| TC-N05 | Invalid Subject ID Filter | Empty results | — | — | ⬜ |
| TC-N06 | Invalid Exam ID Filter | Empty results | — | — | ⬜ |
| TC-N07 | Future Date Range | Empty results | — | — | ⬜ |
| TC-N08 | Date From After Date To | Empty results | — | — | ⬜ |
| TC-N09 | Search With Non-Existent Title | Empty results | — | — | ⬜ |
| TC-N10 | Empty Search String | Same as no filter (all results) | — | — | ⬜ |
| TC-N11 | Special Characters In Search | Treated as literal, no SQL injection | — | — | ⬜ |
| TC-N12 | XSS In Paper Title | Escaped by Blade, no script execution | — | — | ⬜ |
| TC-N13 | Invalid Paper ID For Report (404) | HTTP 404 — Model not found | — | — | ⬜ |
| TC-N14 | No Allocations For Any Paper | All assigned counts = 0 | — | — | ⬜ |
| TC-N15 | No Attempts For Any Paper | All submitted/checked counts = 0 | — | — | ⬜ |
| TC-N16 | Deleted Exam Reference | Paper with deleted exam → exam relation null | — | — | ⬜ |
| TC-N17 | Deleted Class Reference | Paper with deleted class → class relation null | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Assigned Count From Allocations Table | `total_assigned` matches actual allocation count for paper | — | — | ⬜ |
| TC-D02 | B | Submitted Count From Attempts Status | `total_submitted` matches attempts with submission statuses | — | — | ⬜ |
| TC-D03 | C | Checked Count From Attempts Status | `total_checked` matches attempts with evaluated/result_published | — | — | ⬜ |
| TC-D04 | D | Submitted > Checked When Eval Pending | Submitted count includes pending evaluation; checked count excludes them | — | — | ⬜ |
| TC-D05 | E | Allocation Creation Increments Assigned | Adding allocation increases assigned count by 1 | — | — | ⬜ |
| TC-D06 | F | Attempt Submission Increments Submitted | Submitting attempt increases submitted count | — | — | ⬜ |
| TC-D07 | G | Attempt Evaluation Increments Checked | Evaluating attempt increases checked count | — | — | ⬜ |
| TC-D08 | H | Report — Student Performance Data Source | Student table reads from allocations + attempts + results | — | — | ⬜ |
| TC-D09 | I | Report — Provisional Marks For Submitted Not Evaluated | Submitted attempts show provisional marks (answers sum) | — | — | ⬜ |
| TC-D10 | J | Report — Score Distribution Computed From Results | Bar chart shows distribution of percentage scores | — | — | ⬜ |
| TC-D11 | K | Integration — P1 — ExamPaper Model — withCount('allocations') | `$paper->total_assigned` returns integer count of allocations | — | — | ⬜ |
| TC-D12 | L | Integration — P1 — ExamPaper Model — withCount for submitted | Subquery counts attempts with correct statuses | — | — | ⬜ |
| TC-D13 | M | Integration — P1 — ExamPaper Model — belongsTo exam | `$paper->exam` returns Exam model; `$paper->exam->title` shows exam name | — | — | ⬜ |
| TC-D14 | N | Integration — P1 — ExamPaper Model — belongsTo class | `$paper->class` returns SchoolClass model | — | — | ⬜ |
| TC-D15 | O | Integration — P1 — ExamPaper Model — belongsTo subject | `$paper->subject` returns Subject model | — | — | ⬜ |
| TC-D16 | P | Integration — P1 — Controller — Masters() loads summary data conditionally | Only loads when active_tab=exam_summary | — | — | ⬜ |
| TC-D17 | Q | Integration — P1 — Controller — Gate::authorize before load | Without viewAny → 403 | — | — | ⬜ |
| TC-D18 | R | Integration — P1 — Controller — Pagination uses summary_page | Page param = "?summary_page=2" | — | — | ⬜ |
| TC-D19 | S | DEV — P1 — Routes — AJAX cascading dropdowns | get-subjects-by-class, get-papers-by-exam, get-sets-by-paper all return JSON | — | — | ⬜ |
| TC-D20 | T | DEV — P1 — Date range picker auto-submits on selection | apply.daterangepicker calls form.submit() | — | — | ⬜ |
| TC-D21 | U | DEV — P1 — Tab-specific filter form IDs | online uses summary_online, offline uses summary_offline | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade — isset()/null-safe Checks for Relationship Variables | All `$paper->exam?->title`, `$paper->class?->name` use null-safe operator | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — Conditional Data Loading Based On active_tab | Summary data loaded only when active_tab=exam_summary, online_assessment, or offline_assessment | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | View — Filter Form Uses Correct Route | Form action points to route('lms-exam.assessment.index') | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | View — Pagination Preserves active_tab Param | appends(['active_tab' => 'exam_summary']) in pagination links | — | — | ◌ |
| TC-CR05 | CR | Code Review | P2 | Controller — withCount Sub-queries for Performance | Assigned, Submitted, Checked computed via sub-queries, not separate queries | — | — | ◌ |
| TC-CR06 | CR | Code Review | P2 | View — Hidden mode Input For Assessment Tabs | mode=ONLINE for online tab, mode=OFFLINE for offline tab | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Blade — isset()/null-safe Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open online_index.blade.php | View file |
| 2 | Scan: `$paper->exam?->title` | Null-safe used |
| 3 | Scan: `$paper->class?->name` | Null-safe used |
| 4 | Scan: `$paper->subject?->name` | Null-safe used |
| 5 | Scan: `$paper->allocations->first()?->section?->name` | Full null-safe chain |
| 6 | Scan: `$paper->exam?->start_date?->format(...)` | Null-safe on both |
| 7 | Open offline_index.blade.php | Same patterns verified |
| 8 | Create paper with null relations | View renders with fallbacks |

#### TC-CR02: Controller — Conditional Data Loading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open LmsExamController.php | Controller found |
| 2 | Inspect masters() method | Checks `$request->get('active_tab')` for summary/online/offline |
| 3 | When active_tab=exam_summary | Summary query runs |
| 4 | When active_tab=online_assessment | Online filtered query runs |
| 5 | When active_tab=offline_assessment | Offline filtered query runs |
| 6 | When active_tab=dashboard | Summary query NOT run |

### 6.1 Positive TC Steps — Detailed

#### TC-P01: Exam Summary Tab Loads With All Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin, navigate to Exam Management → Assessment | Page loads |
| 2 | Click "Exam Summary" tab | active_tab=exam_summary |
| 3 | Check filter bar | Class/Section, Subject, Exam, Paper, Paper Set, Date Range, Search |
| 4 | Check table columns | Exam Title, Class/Section/Subject, Mode, Exam Date, Assigned, Submitted, Checked, Action |
| 5 | Check pagination | Pagination at bottom |
| 6 | Check total count badge | Shows "X exams" |

#### TC-P02: All Papers Shown (Both Modes)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 ONLINE and 2 OFFLINE papers | 5 total |
| 2 | Load exam summary tab | All 5 papers visible |
| 3 | Verify ONLINE papers have blue badge | "Online" badge |
| 4 | Verify OFFLINE papers have gray badge | "Offline" badge |

#### TC-P03 to TC-P15: Filter Tests

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class → subject → exam → paper → set | Each filter cascades correctly |
| 2 | Select date range "Last 7 Days" | Auto-submits, filtered results |
| 3 | Type paper title in search | Filtered by title |
| 4 | Type paper_code in search | Matched by paper_code |
| 5 | Clear all filters | All papers shown |

#### TC-P16 to TC-P18: Cascading Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class → Subject dropdown updates | AJAX GET to get-subjects-by-class |
| 2 | Select exam → Paper dropdown updates | AJAX to get-papers-by-exam |
| 3 | Select paper → Set dropdown updates | AJAX to get-sets-by-paper |

#### TC-P19 to TC-P20: Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 15 papers | 2 pages |
| 2 | Page 1: 10 records | Shows 1-10 |
| 3 | Page 2: 5 records | Shows 11-15 |
| 4 | Apply filter, go to page 2 | Params preserved |

#### TC-P21 to TC-P24: Counts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with 5 allocations | Assigned badge = 5 |
| 2 | Create 3 submitted attempts | Submitted badge = 3 |
| 3 | Evaluate 2 of them | Checked badge = 2 |
| 4 | New paper with 0 everything | All badges = 0 |

#### TC-P25 to TC-P28: Mode Badges

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | ONLINE paper | Blue "Online" badge |
| 2 | OFFLINE + BULK_TOTAL | Gray "Offline" + "Bulk" |
| 3 | OFFLINE + QUESTION_WISE | Gray "Offline" + "Question Wise" |
| 4 | OFFLINE + is_ques_wise_file_upload=1 | Gray "Offline" + "Question Wise" |

#### TC-P29 to TC-P32: Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Report for paper | Navigates to /exam/exam/{paperId}/report |
| 2 | Click Check for ONLINE paper | Links to paper-check route |
| 3 | Click Check for OFFLINE QUESTION_WISE | Links to paper-check-offline |
| 4 | Click Check for OFFLINE BULK | Links to paper-check.bulk |

#### TC-P39: Report Page Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Report button on paper row | Report page loads |
| 2 | Check header | Paper title, class, subject, exam displayed |
| 3 | Check stats cards | Total Assigned, Total Attempts, Evaluated, Avg Score |
| 4 | Check charts | Participation Summary doughnut, Score Distribution bar |
| 5 | Check student table | Student-wise performance with all columns |

#### TC-P40: Report Statistics Cards

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper: 10 allocated, 8 submitted, 6 evaluated, avg 75% | Cards show: 10, 8, 6, 75% |
| 2 | Paper with 0 everything | Cards show: 0, 0, 0, 0% |
| 3 | All evaluated | Total Attempts = Evaluated |

### 6.2 Negative TC Steps — Detailed

#### TC-N01: No Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without tenant.exam.viewAny | 403 on assessment page |

#### TC-N02: Guest Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate to summary tab | Redirect to /login |

#### TC-N03: No Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no exam papers exist | Empty table |
| 2 | Load summary tab | "No exams found" message |

#### TC-N04 to TC-N08: Invalid Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | class_id=99999 | Empty |
| 2 | subject_id=99999 | Empty |
| 3 | exam_id=99999 | Empty |
| 4 | Future date range | Empty |
| 5 | date_from > date_to | Empty |

#### TC-N13: Invalid Report ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open /exam/exam/99999/report | HTTP 404 |

### 6.3 Dependency TC Steps — Detailed

#### TC-D01 to TC-D07: Count Accuracy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with 3 allocations | total_assigned = 3 |
| 2 | Create 2 attempts with SUBMITTED status | total_submitted = 2 |
| 3 | Evaluate 1 of them (EVALUATED status) | total_checked = 1 |
| 4 | Pending: 2 submitted - 1 checked = 1 | Difference visible |
| 5 | Add 1 more allocation | Assigned increments |

#### TC-D11: ExamPaper withCount

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $paper->total_assigned | Returns count from withCount('allocations') |
| 2 | $paper->total_submitted | Returns count from withCount subquery |
| 3 | $paper->total_checked | Returns count from withCount subquery |

#### TC-D16: Conditional Loading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Masters with active_tab=dashboard | Summary query NOT executed |
| 2 | Masters with active_tab=exam_summary | Summary query executed |
| 3 | Masters with active_tab=online_assessment | ONLINE filtered summary executed |

#### TC-D18: Custom Pagination Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to page 2 | URL has `summary_page=2` |
| 2 | Other paginated elements on same page | Use different page names, no conflict |

### 6.4 Additional Integration Test Steps

#### TC-AD-01: Multi-Filter All Combinations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Class + Subject + Date | All 3 applied |
| 2 | Exam + Search | Both applied |
| 3 | Paper + Set | Both applied |
| 4 | All 6 filters together | All applied correctly |

#### TC-AD-02: Submitted vs Checked Discrepancy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 10 submitted, 4 evaluated | Submitted=10, Checked=4 |
| 2 | 6 pending evaluation | Difference = 6 |

#### TC-AD-03: Report — Student With No Attempt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student allocated but not attempted | Status = NOT_STARTED, Marks = "-- / --" |
| 2 | Action button disabled | No "View Result" link |

#### TC-AD-04: Report — Student With Absent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt with status = ABSENT | Red bg-danger badge "ABSENT" |
| 2 | Marks = "-- / --" | No marks shown |

#### TC-AD-05: Report — Student With Provisional Marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt SUBMITTED (not evaluated) | Provisional marks from answer sum |
| 2 | Marks show with muted text | Title "Provisional Marks" |

#### TC-AD-06: Date Range — Last 30 Days

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Papers: 5 from 25 days ago, 3 from 60 days ago | Last 30 days: 5 results |

#### TC-AD-07: Mode Badge Online + Offline

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Mixed modes in summary | Both badges shown |
| 2 | Online tab shows only ONLINE | OFFLINE hidden |
| 3 | Offline tab shows only OFFLINE | ONLINE hidden |

#### TC-AD-08: Pagination With Search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search "Math" → 12 matches | 2 pages |
| 2 | Navigate page 2 | search param preserved |

#### TC-AD-09: Paper Code Uniqueness Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper with code "EXAM-2025-001" | Code displayed below title |

#### TC-AD-10: Report — All Students Evaluated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All 20 students evaluated | Checked = 20 = Submitted |
| 2 | Avg score computed correctly | Average of all percentages |

#### TC-AD-11: Report — Score Distribution Chart Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Results: 0-33%: 2, 33-60%: 5, 60-80%: 8, 80-100%: 5 | Bar chart shows correct distribution |

#### TC-AD-12: Report — Participation Chart Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 20 allocated, 15 attempted, 12 evaluated, 3 pending | Chart segments: Submitted, Evaluated, Pending, Not Attempted |

#### TC-AD-13: Summary — Paper With Exam Date in Past

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper with exam date 2024-01-15 | Shows "15 Jan, 2024" |
| 2 | Filter current year | Not shown (outside range) |

#### TC-AD-14: Summary — Paper With Exam Date in Future

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper with exam date next month | Shown in list |
| 2 | Assigned/submitted/checked = 0 | Future exam, no activity yet |

#### TC-AD-15: Cascading — Exam Without Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select exam with zero papers | Paper dropdown shows "All Papers" only |
| 2 | No error | Graceful handling |

#### TC-AD-16: Cascading — Paper Without Sets

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select paper with no sets | Set dropdown resets to "All Paper Sets" |
| 2 | No error | Graceful handling |

#### TC-AD-17: Summary — Class Not Selected Shows All

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave class filter empty | All papers across all classes shown |

#### TC-AD-18: Summary — Subject Dropdown Initialization On Class Select

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | class_section_id pre-selected on page load | Auto-triggers class change event |
| 2 | Subject dropdown populated correctly | Subjects for that class shown |

#### TC-AD-19: Report — Student Result Status Colors

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | EVALUATED status | Green badge |
| 2 | SUBMITTED status | Primary badge |
| 3 | IN_PROGRESS status | Info badge |
| 4 | ABSENT status | Danger badge |
| 5 | NOT_STARTED status | Secondary badge |

#### TC-AD-20: Report — Grade Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Evaluated student | Grade displayed (A/B/C/D/E/F) |
| 2 | Not evaluated student | No grade shown |

#### TC-AD-21: Report — Marks With Result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student with result record | Shows "18 / 20" in bold |
| 2 | Student without result (but submitted) | Shows provisional marks with muted text |

#### TC-AD-22: Summary — Total Exams Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tab header shows total count | Badge: "X exams" |

#### TC-AD-23: Summary — Action Button Disabled State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No check action for empty paper | Check button still present, routes to check page |

#### TC-AD-24: Search — Exact Match

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search "Science Final Exam" | Exact title match returns that paper |

#### TC-AD-25: Search — Partial Match

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search "Science" | All papers with "Science" in title returned |

#### TC-AD-26: Search — Case Insensitivity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search "science" | Matches "Science Final Exam" |

#### TC-AD-27: Date Range — Form Auto-Submit On Selection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open date picker | Preset ranges visible |
| 2 | Select "Last 7 Days" | Form auto-submits |
| 3 | Click "Clear" | Form auto-submits with cleared dates |

#### TC-AD-28: Online Tab — Action Check Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Online paper in online_assessment tab | Check button → paper-check route |

#### TC-AD-29: Offline Tab — Action Check Route Based On Entry Mode

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Offline + QUESTION_WISE → paper-check-offline | Correct route |
| 2 | Offline + BULK → paper-check.bulk | Correct route |

#### TC-AD-30: Summary — Offline Paper With is_ques_wise_file_upload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | is_ques_wise_file_upload=1 | Shows "Question Wise" badge |
| 2 | is_ques_wise_file_upload=0 | Shows "Bulk" badge |
| 3 | Check route based on this flag | Affects which check route used |

### 6.5 Filter Combination Tests

#### TC-AD-31: Class + Subject + Date Range — Three-Way Combined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class A, Subject Math, date Last 30 Days | All 3 filters displayed in filter bar |
| 2 | Submit form | Papers matching Class A + Math + within 30 days |
| 3 | Verify count corresponds to intersection | No papers outside criteria shown |

#### TC-AD-32: Class + Exam + Date Range — Combined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class B, Exam "Final Term", Custom Date Jan–Mar 2025 | Three filters bar visible |
| 2 | Submit | Only Class B papers for "Final Term" exam in Jan–Mar |
| 3 | Change date to Apr–Jun, re-submit | Different set, same class + exam constraint |

#### TC-AD-33: Subject + Paper + Set — Cascading Combined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Subject Physics | Paper dropdown populated with Physics papers |
| 2 | Select a specific Paper | Set dropdown populated with its sets |
| 3 | Select Set A | Only the single paper matching all 3 shown |

#### TC-AD-34: All 6 Filters Applied Together

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set Class + Subject + Exam + Paper + Set + Date Range | All 6 filter dropdowns have selections |
| 2 | Submit | At most 1 result (extremely narrow filter) |
| 3 | Verify pagination URL contains all 6 params | `class_section_id=x&subject_id=y&exam_id=z&exam_paper_id=w&exam_set_id=v&date_from=u&date_to=t` |

#### TC-AD-35: Search Across All Three Searchable Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search "SEMESTER" | Matches paper title "Semester Exam", code "SEM-001", exam title "Semester Final" |
| 2 | Search exact paper code "EXAM-2025-001" | Only that one paper returned |
| 3 | Search exam title words "Midterm Examination" | All papers under exams with "Midterm" in title |
| 4 | Combine search with class filter | Intersection of search + class applied |

#### TC-AD-36: Subject + Paper + Search — Four-Way Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Subject + Paper, type search term | 3 active filters |
| 2 | Submit | Results match all three criteria |
| 3 | Clear paper filter, keep subject + search | Broader result set, subject + search still applied |

#### TC-AD-37: Class + Search — Verify Class Scope Applied

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class A only, search "math" | Only Class A papers with "math" in title/code/exam |
| 2 | Change to Class B, same search | Different result set (Class B papers) |
| 3 | No class selected, same search | All classes, papers with "math" |

#### TC-AD-38: All 6 Filters + Search — Maximum Combination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set all 6 dropdown filters + type search | 7 filter parameters active |
| 2 | Submit | Extremely narrow set (likely 0 results) |
| 3 | Verify no SQL error or timeout | Empty state displayed gracefully |

#### TC-AD-39: Filter Persistence After Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply Class + Subject + Date Range → 25 results | 3 pages |
| 2 | Go to page 2 | URL shows class_section_id, subject_id, date_from, date_to, summary_page=2 |
| 3 | Go to page 3 | All filter params preserved |
| 4 | Apply new filter from page 3 | Resets to page 1 with new filter |

#### TC-AD-40: Reset All Filters After Multi-Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply 4+ filters (Class, Subject, Exam, Date Range) | Many filters active |
| 2 | Click "Reset" or "Clear All" | All dropdowns reset to default |
| 3 | Date range cleared, search emptied | Form fully reset |
| 4 | Page reloads with all papers (no filter) | Full dataset shown |

#### TC-AD-41: Numeric Search and Partial Code Match

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search "001" | Paper codes ending in "001" matched |
| 2 | Search "2025" | All papers with "2025" in title, code, or exam title |
| 3 | Verify leading zeros handling | Search treats as string, not integer |

#### TC-AD-42: Browser Back/Forward With Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply Class + Date Range, submit | Filtered URL |
| 2 | Navigate to another browser tab, press Back | Returns to filtered summary |
| 3 | Filters still applied from URL params | Page state restored from query string |

### 6.6 Permission Matrix Tests

#### TC-AD-43: viewAny Permission — Full Access to Summary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with `tenant.exam.viewAny` | Exam Summary tab visible |
| 2 | All filter dropdowns operable | Full filter functionality |
| 3 | Report and Check action buttons present | Action column shows all links |

#### TC-AD-44: Missing viewAny — 403 Forbidden

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create role without `tenant.exam.viewAny` | Permission absent |
| 2 | Assign to user, login, navigate to exam summary | HTTP 403 Forbidden |
| 3 | Other unrelated tabs remain accessible | Only exam module restricted |

#### TC-AD-45: Admin Role — Sees All Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | All papers across all classes visible |
| 2 | No class restriction applied | Full dataset |

#### TC-AD-46: Teacher Role — Scope to Own Classes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Assign teacher to Class A only | Teacher scope defined |
| 2 | Login as teacher | Only Class A papers shown in summary |
| 3 | Class dropdown shows only assigned classes | Class A, not Class B or C |

#### TC-AD-47: Subject Teacher Role — Class + Subject Scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Assign subject teacher for Class A, Subject Math | Scope = Class A + Math |
| 2 | Login as subject teacher | Only Class A + Math papers shown |
| 3 | Subject dropdown pre-filtered to assigned subjects | Only Math available |

#### TC-AD-48: Student Role — Own Allocations Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as student | Summary shows only papers where student is allocated |
| 2 | Action buttons restricted | No Check/Report; possibly "View Result" only |
| 3 | Filter scope limited to student's data | No class/subject filter (or limited) |

#### TC-AD-49: Permission Revoked Mid-Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Admin with viewAny opens summary | Page renders |
| 2 | In another session, admin removes viewAny role | Permission DB updated |
| 3 | Refresh summary page | 403 on subsequent request |

### 6.7 AJAX Cascade Edge Cases
### 6.7 AJAX Cascade Edge Cases

#### TC-AD-50: Class Without Subjects — AJAX Returns Empty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class that has zero active subjects | AJAX GET to get-subjects-by-class returns [] |
| 2 | Subject dropdown shows "No subjects available" | Disabled, no options |
| 3 | Submit filter without subject | Works with class filter only, no error |

#### TC-AD-51: Exam Without Papers — AJAX Returns Empty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select exam that has no papers | AJAX to get-papers-by-exam returns [] |
| 2 | Paper dropdown shows "All Papers" only | Cannot select a specific paper |
| 3 | Submit with exam only | 0 results (exam has no papers) |

#### TC-AD-52: Paper Without Sets — AJAX Returns Empty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select paper that has zero paper sets | AJAX to get-sets-by-paper returns [] |
| 2 | Set dropdown shows "All Paper Sets" only | Empty state for sets |
| 3 | Submit with paper filter | Paper results unaffected by set |

#### TC-AD-53: Network Timeout on AJAX Cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Throttle network to Slow 3G | Class selected |
| 2 | Subject AJAX takes > 10 seconds | Loading spinner or "Loading..." in dropdown |
| 3 | Request eventually times out | Error message "Failed to load subjects" |
| 4 | Other filters remain usable | No cascade failure to unrelated dropdowns |

#### TC-AD-54: 500 Server Error From get-subjects-by-class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate server error on subject endpoint | AJAX returns HTTP 500 |
| 2 | Subject dropdown shows error state | "Error loading subjects" message |
| 3 | Changing class re-triggers AJAX | Retry works when server recovers |

#### TC-AD-55: 500 Server Error From get-papers-by-exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate server error on paper cascade | AJAX returns HTTP 500 |
| 2 | Paper dropdown disabled with error | "Error loading papers" |
| 3 | Exam filter alone still works | Submit form with exam only |

#### TC-AD-56: Rapid Class Switching — Debounce Race Condition

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Rapidly select Class A -> Class B -> Class C in < 1s | Each triggers AJAX |
| 2 | Only last response (Class C subjects) populates dropdown | No stale Class A data shown |
| 3 | Aborted requests handled gracefully | No console errors from cancelled XHR |

### 6.8 Pagination Edge Cases

#### TC-AD-57: Zero Results — Pagination Hidden

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Filter to yield 0 papers | Empty state message shown |
| 2 | Pagination controls absent | No page links, no prev/next |
| 3 | Count badge shows "0 exams" | Accurate count |

#### TC-AD-58: Exactly 1 Page (10 Results)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Filter to return exactly 10 papers | Single page |
| 2 | Pagination shows only page 1 | No prev/next links |
| 3 | Showing "1 to 10 of 10" | Correct summary text |

#### TC-AD-59: Last Page With Fewer Items (13 Total, Page 2 has 3)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 13 papers | 2 pages needed |
| 2 | Page 1 shows 10 items | Items 1-10 |
| 3 | Navigate to page 2 | Shows 3 items (11-13) |
| 4 | Prev link goes back to page 1 | Navigation works |

#### TC-AD-60: Navigate to Non-Existent Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manually set ?summary_page=9999 | Page loads with no results or last page |
| 2 | No PHP/JS error | No exception, no stack trace |
| 3 | Paginator clamps to last available page | Correct behavior |

#### TC-AD-61: Pagination With Search — Page Reset on New Search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search "test" -> 15 results -> go to page 2 | Page 2 of search results |
| 2 | Change search to "exam" | Resets to page 1, new results |
| 3 | Old search param replaced in URL | Only new search in query string |

#### TC-AD-62: Pagination Count Badge With Filtered Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Total papers = 50, filtered to 27 | Badge shows "27 exams" |
| 2 | Page 1 shows items 1-10 | "Showing 1 to 10 of 27" |
| 3 | Page 3 shows items 21-27 | "Showing 21 to 27 of 27" |

#### TC-AD-63: Negative Page Number

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set ?summary_page=-1 | Treated as page 1 |
| 2 | Set ?summary_page=abc | Non-numeric treated as page 1 |
| 3 | No validation errors shown | Graceful handling |

### 6.9 Report Page Detailed Tests

#### TC-AD-64: Statistics Cards — Various Data Sizes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper: 50 allocated, 40 submitted, 30 evaluated, avg 72.5% | Cards: Assigned=50, Attempts=40, Evaluated=30, Avg=72.5% |
| 2 | Paper with 0 allocations | All cards show 0 or "---" |
| 3 | All 50 evaluated, Attempts = Evaluated = 50 | Cards match |

#### TC-AD-65: Charts — Empty Data State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper with 0 allocations, 0 attempts | Participation doughnut chart shows "No data" |
| 2 | Score distribution bar chart empty | "No scores to display" message |
| 3 | Chart.js console errors absent | Library handles empty datasets |

#### TC-AD-66: Charts — Full Data Rendering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 100 students: 15 not started, 5 in-progress, 10 submitted, 5 absent, 65 evaluated | Doughnut: 5 segments with correct proportions |
| 2 | Scores: 0-33%: 10, 33-60%: 20, 60-80%: 25, 80-100%: 10 | Bar chart: 4 bars with correct heights |
| 3 | Legend colors match segment colors | Visual consistency |

#### TC-AD-67: Student Table — Search and Sort

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 30 students in table | Full list rendered |
| 2 | Search "John" | Only students with "John" in name shown |
| 3 | Clear search | Full list restored |
| 4 | Click "Percentage" column header | Sorted descending by percentage |
| 5 | Click again | Sorted ascending |
| 6 | Sort arrow indicator visible | Active sort column highlighted |

#### TC-AD-68: Student Table — Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 25 students in report | 10 per page, 3 pages |
| 2 | Page 1: 10, Page 2: 10, Page 3: 5 | Correct split |
| 3 | Student search interacts with pagination | Filtered subset paginated correctly |

#### TC-AD-69: Report — Action "View Result" for Each Student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Evaluated student row | "View Result" link enabled |
| 2 | SUBMITTED (not evaluated) student | Link enabled (provisional result) |
| 3 | NOT_STARTED student | Link disabled or absent |
| 4 | Click "View Result" | Navigates to student result page |

### 6.10 Student Result View Tests

#### TC-AD-70: Marks Breakdown — Per-Question Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open result for EVALUATED student | Per-question marks shown |
| 2 | Each question: question text, max marks, obtained marks | Full breakdown |
| 3 | Total marks sum matches card total | Aggregate correct |

#### TC-AD-71: Grade Calculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student with 92% | Grade A (>= 90%) |
| 2 | Student with 78% | Grade B (>= 75%) |
| 3 | Student with 45% | Grade D or E (as per system config) |
| 4 | Not evaluated student | No grade displayed |

#### TC-AD-72: Pass/Fail Status Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student with marks >= passing threshold | "PASS" badge in green |
| 2 | Student with marks < passing threshold | "FAIL" badge in red |
| 3 | Student marked ABSENT | "ABSENT" badge, not pass/fail |
| 4 | Verify passing threshold from institution config | Threshold correctly applied |

#### TC-AD-73: Provisional Marks for Submitted (Not Evaluated)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student with SUBMITTED status, no evaluation | Marks shown as "Provisional" |
| 2 | Visual indicator: muted text or "(Provisional)" label | Clear distinction from evaluated |
| 3 | After evaluation, refresh, evaluated marks replace provisional | Data updates correctly |

#### TC-AD-74: Result Publish Workflow — Before Publish

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student evaluated, status = EVALUATED | total_checked includes this student |
| 2 | Admin sees marks on report page | Visible to staff |
| 3 | Student portal does NOT show result | Hidden until published |

#### TC-AD-75: Result Publish Workflow — After Publish

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Admin publishes result | Status changes to RESULT_PUBLISHED |
| 2 | total_checked stays same (already counted) | Count unchanged |
| 3 | Student portal shows result | Now visible to student |

### 6.11 Mode-Specific Tests

#### TC-AD-76: Online Paper — Check Routes to Online Paper-Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Check on ONLINE paper in summary | Routes to online paper-check page |
| 2 | URL matches pattern /exam/paper/{id}/check | Correct online route |
| 3 | Same behavior from online_assessment tab | Mode-independent routing |

#### TC-AD-77: Offline Bulk — Check Routes to Bulk Mark Entry

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Check on OFFLINE + BULK_TOTAL paper | Routes to offline bulk mark entry |
| 2 | Bulk entry form shows all allocated students | Student list for mark entry |
| 3 | Route matches bulk check pattern | Correct offline bulk route |

#### TC-AD-78: Offline Question-Wise — Check Routes to Question-Wise Entry

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Check on OFFLINE + QUESTION_WISE paper | Routes to question-wise mark entry |
| 2 | Question-wise form shows paper questions | Question list for mark entry |
| 3 | Route matches question-wise pattern | Correct offline QW route |

#### TC-AD-79: Mode Routing — Determined by Paper, Not Current Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | While on Online Assessment tab, click Check on OFFLINE paper | Routes to offline check (not online) |
| 2 | While on Offline Assessment tab, click Check on ONLINE paper | Routes to online check |
| 3 | Route driven by $paper->mode, not active_tab | Consistent routing |

### 6.12 Date Range Edge Cases

#### TC-AD-80: Timestamps With Hours and Minutes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Exam start_date = 2025-06-15 08:30:00 | Display: "15 Jun, 2025" (time truncated) |
| 2 | Filter date_from = 2025-06-15 00:00:00, date_to = 2025-06-15 23:59:59 | Paper included (start within range) |
| 3 | Filter date_from = 2025-06-16 00:00:00 | Paper excluded (start before range) |

#### TC-AD-81: Cross-Month Boundary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Exam on 2025-01-31 | January paper |
| 2 | Filter Jan 25 - Feb 5 | Included (cross-month) |
| 3 | Filter "This Month" (February) | Excluded (start in January) |

#### TC-AD-82: Cross-Year Boundary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Exam on 2025-12-28 | December 2025 paper |
| 2 | Filter Dec 25, 2025 - Jan 5, 2026 | Included (cross-year) |
| 3 | Filter Last Year (2025) | Included |
| 4 | Filter This Year (2026) | Excluded |

#### TC-AD-83: date_from > date_to — Invalid Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date_from = 2025-12-31, date_to = 2025-01-01 | Invalid range |
| 2 | Form either shows validation error or returns empty | No crash |
| 3 | No error trace or exception visible | Clean UX |

#### TC-AD-84: Same Day Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date_from = date_to = 2025-06-15 | Papers starting on June 15 only |
| 2 | Paper from June 14 excluded | Precise range |
| 3 | Paper from June 15 included | Exact match |

#### TC-AD-85: Far Future Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date_from = 2028-01-01 | No papers (unless future exam exists) |
| 2 | No error or timeout | Query handles large date values |
| 3 | Date picker allows selecting future years | No restriction in picker |

### 6.13 Empty/Error State Tests

#### TC-AD-86: Paper With Deleted Exam (Null Relation)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete exam record referenced by a paper | exam_id now orphaned |
| 2 | Load exam summary | Paper row renders without error |
| 3 | Exam title shows "---" or "Deleted" | Null-safe operator works |
| 4 | Action buttons still functional | Paper record itself exists |

#### TC-AD-87: Paper With Deleted Class (Null Relation)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete class record referenced by a paper | class_id now orphaned |
| 2 | Load exam summary | Class badge shows "---" |
| 3 | No Blade error | Null-safe in view |

#### TC-AD-88: Paper With Deleted Subject (Null Relation)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete subject record referenced by a paper | subject_id now orphaned |
| 2 | Load exam summary | Subject name shows "---" |
| 3 | No JavaScript or PHP errors | Graceful degradation |

#### TC-AD-89: All Three Relations Deleted Simultaneously

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete exam, class, and subject for one paper | All FKs orphaned |
| 2 | Load exam summary | Row renders with fallbacks for all three |
| 3 | assigned/submitted/checked counts display correctly | Count queries unaffected by relations |
| 4 | Action buttons remain clickable | Paper object still valid |

#### TC-AD-90: Online Tab — No Online Papers Exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create only OFFLINE papers | No ONLINE papers exist |
| 2 | Click Online Assessment tab | "No exams found" empty state |
| 3 | Offline Assessment tab shows offline papers | Mode filter works |
| 4 | Exam Summary tab shows all (both modes) | Summary unifies |

### 6.14 XSS/Security Tests

#### TC-AD-91: Script Injection in Paper Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with title <script>alert('XSS')</script> | Stored in DB raw |
| 2 | Load exam summary | Title rendered as escaped HTML entities |
| 3 | No alert dialog | Blade escaping prevents XSS |

#### TC-AD-92: HTML Injection in Exam Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with title <img src=x onerror=alert(1)> | Stored raw |
| 2 | Load exam summary | Escaped in HTML, no image load |
| 3 | View page source | HTML entities visible |

#### TC-AD-93: Reflected XSS via Search Field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search恶意脚本 | Searched as literal |
| 2 | Search input retains value, escaped | No script execution |
| 3 | No reflected XSS in response | Input sanitized in output |

#### TC-AD-94: SQL Injection via Filter Parameters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set class_id = `1 OR 1=1` | Invalid integer, cast to 0 or rejected |
| 2 | Set date_from = malformed date string | Invalid date, validation error |
| 3 | Search uses LIKE with escaped percent | Literal search, parameterized query |
| 4 | Verify all tables intact | Queries use parameterized bindings |

#### TC-AD-95: IDOR — Access Other Tenant's Paper Report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Get paper ID from a different tenant's data | Cross-tenant ID |
| 2 | Navigate to /exam/exam/{paperId}/report | 404 or 403 (tenant isolation) |
| 3 | Try URL manipulation to bypass scope | Scoped by tenant_id |

### 6.15 Performance Tests

#### TC-AD-96: Large Dataset — 1000+ Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 1000 exam papers across classes/subjects | Bulk dataset |
| 2 | Load exam summary | Loads within acceptable time (< 3s) |
| 3 | Apply class filter with 200 matching | Filter query performs efficiently |
| 4 | Navigate to page 50 | 50th page renders normally |

#### TC-AD-97: Large Dataset — 10K+ Allocations, 5K+ Attempts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Single paper with 10000 allocations | Large allocation set |
| 2 | 5000 attempts with mixed statuses | Large attempt set |
| 3 | Load summary row for that paper | withCount sub-queries complete in reasonable time |
| 4 | Load report page for that paper | Report page loads without timeout |

#### TC-AD-98: Query Optimization — No N+1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enable DB query log | Capture all queries |
| 2 | Load summary page (10 papers) | Total queries < 15 (1 for papers + eager loads) |
| 3 | Verify counts via withCount sub-queries | No separate SELECT COUNT per paper |
| 4 | Report page similarly optimized | Minimal queries for student data |

#### TC-AD-99: Memory Usage With Large Paginated Dataset

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load summary page 1 of 1000 papers | Only 10 papers loaded (paginated) |
| 2 | Memory usage < 64MB | Efficient pagination |
| 3 | No memory limit errors in logs | No OOM issues |

### 6.16 Concurrent Data Change Tests

#### TC-AD-100: Paper Created While Viewing Summary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A loads summary, 10 papers on page 1 | Initial count = 10 |
| 2 | User B creates a new paper in another session | New paper persisted |
| 3 | User A refreshes | New paper appears (count = 11) |
| 4 | Badge updates to "11 exams" | Correct count |

#### TC-AD-101: Allocation Added While Viewing Summary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A loads summary, Paper X shows assigned=5 | Initial assigned count |
| 2 | User B adds 3 allocations to Paper X | DB updated |
| 3 | User A refreshes | Paper X now shows assigned=8 |
| 4 | Count comes from fresh query (no cache) | Accurate |

#### TC-AD-102: Attempt Submitted While Viewing Report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A (admin) loads report, 10 allocated, 5 submitted | Stats: 10, 5, evaluated count |
| 2 | Student submits attempt | Attempts table updated |
| 3 | User A refreshes report | Total Attempts = 6 |
| 4 | Student table shows new attempt row | Real-time data after refresh |

#### TC-AD-103: Paper Deleted While on Page 2

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A on page 2 (items 11-20) | Current page data |
| 2 | User B deletes paper #15 | Paper removed |
| 3 | User A refreshes page 2 | Items shift (11-14, 16-21) |
| 4 | No 404 or partial page error | Paginator recalculates correctly |

### 6.17 Data Accuracy Tests

#### TC-AD-104: Assigned Count Verified With Direct SQL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note paper ID from UI, run raw COUNT query on lms_exam_allocations | Raw DB count |
| 2 | Compare with UI's total_assigned | Match |
| 3 | Repeat for 5 random papers | All match |

#### TC-AD-105: Submitted Count Verified With Direct SQL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run raw COUNT on lms_exam_attempts with status IN submitted statuses | Raw DB submitted count |
| 2 | Compare with UI total_submitted | Match |
| 3 | Test with paper having 0, 10, 100 attempts | All match |

#### TC-AD-106: Checked Count Verified With Direct SQL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run raw COUNT on attempts with evaluated/result_published statuses | Raw DB checked count |
| 2 | Compare with UI total_checked | Match |
| 3 | Verify pending = submitted - checked | Discrepancy correct |

#### TC-AD-107: Report Avg Score — Manual Recalculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Get all evaluated students' scores from DB | Raw score list |
| 2 | Calculate average manually: sum(scores) / count | Manual average |
| 3 | Compare with UI Avg Score card | Match |
| 4 | Paper with 0 evaluated, Avg = 0% or "---" | No division by zero |

### 6.18 URL Manipulation Tests

#### TC-AD-108: Direct Navigation With Invalid Tab Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to /exam/master?active_tab=invalid_tab | No error, loads default tab |
| 2 | No exception or stack trace | Graceful fallback |
| 3 | Query param retained in URL | Not stripped |

#### TC-AD-109: Direct Navigation With Invalid Mode

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to /exam/assessment?active_tab=online_assessment&mode=INVALID | No error |
| 2 | Mode ignored or reset to valid value | Sensible default |
| 3 | No SQL error from invalid ENUM value | Validation applied |

#### TC-AD-110: URL With All Filter Params Directly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to URL with class_section_id, subject_id, exam_id, exam_paper_id, exam_set_id, date_from, date_to, search all set | Page loads with all filters pre-applied |
| 2 | Dropdowns show correct selections | UI state matches URL |
| 3 | Results match expected filtered set | Query executed correctly |

#### TC-AD-111: Invalid Pagination Page Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to ?summary_page=-1 | Negative, treated as page 1 |
| 2 | Navigate to ?summary_page=abc | Non-numeric, treated as page 1 |
| 3 | Navigate to ?summary_page= | Empty, treated as page 1 |
| 4 | No exceptions or error messages | Clean URL handling |
