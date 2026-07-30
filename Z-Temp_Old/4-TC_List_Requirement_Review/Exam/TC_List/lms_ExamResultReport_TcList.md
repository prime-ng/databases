# lms_ExamResultReport_TcList

## Module: LmsExam → Advanced Reports → Exam Result Report

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Advanced Reports |
| Feature | Exam Result Report |
| URL(s) | `/lms-exam/exam-advanced-reports?active_tab=exam-result-report` (index) |
| Controller | `Modules\LmsExam\Http\Controllers\ExamAdvancedReportController@index()` |
| Method (Data) | `generateExamResultData()` (private, line 401) |
| Model(s) | `Modules\StudentPortal\Models\ExamResult`, `Modules\LmsExam\Models\Exam`, `Modules\LmsExam\Models\ExamPaper`, `Modules\StudentProfile\Models\Student`, `Modules\LmsQuiz\Models\Quiz`, `Modules\LmsQuests\Models\Quest` |
| View (Partial) | `advanced-reports/partials/exam-result-report.blade.php` |
| Permissions | `tenant.lms-exam-report.viewAny` |
| Pagination | 25 per page, standard Laravel pagination |
| Charts | ApexCharts: radialBar (pass rate), bar (grade distribution) |
| Date Range | daterangepicker with moment.js |

---

## 2. Pre-conditions

- Required permission: `tenant.lms-exam-report.viewAny`
- Required seed data: Multiple `ExamResult` records with varied `result_status` (PASS, FAIL, ABSENT), varied `percentage`, and linked to `ExamPaper` with `Subject`
- At least one `Exam` with `ExamPaper` records that have `Subject` relations
- Test user must have the above permission (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- At least 25+ result records for pagination testing
- Grade distribution across all 8 brackets: A+, A, B+, B, C+, C, D, F
- Result statuses: mix of PASS, FAIL, ABSENT for summary calculations

---

## 3. Default Data Load

When the page loads via `ExamAdvancedReportController@index()` (GET /lms-exam/exam-advanced-reports with `active_tab=exam-result-report`), the following data is fetched:

| Widget/Chart | Data Source | Query Logic | Filters |
|-------------|-------------|-------------|---------|
| Shared: Class Dropdown | `SchoolClass::where('is_active', 1)->orderBy('name')` | All active classes | is_active=1 |
| Shared: Section Dropdown | `Section::where('is_active', 1)->whereHas('classSections', ...)` | For selected class | class_id |
| Shared: Subject Dropdown | `Subject::active()->whereHas('subjectStudyFormats.classGroups', ...)` | For selected class | class_id |
| Shared: Lesson Dropdown | `Lesson::active()->where('subject_id', ...)` | For selected subject | subject_id |
| Shared: Topic Dropdown | `Topic::active()->whereLevel(0)->where('lesson_id', ...)` | For selected lesson | lesson_id |
| Shared: Exam Dropdown | `Exam::withTrashed()->where('is_active', true)->orderBy('start_date', 'desc')` | All exams | is_active=true |
| **Metrics Cards (5)** | `generateExamResultData()` → `$summary` | Total Students, Pass Rate, Class Avg, Peak, Floor | exam_id, paper_id, class_id, section_id, result_status |
| **Pass Rate Radial Chart** | `generateExamResultData()` → `$charts['pass_rate']` | Radial bar with pass percentage | Same filters |
| **Grade Distribution Bar** | `generateExamResultData()` → `$charts['grade_profile']` | 8 grade bars (A+ to F) | Same filters |
| **Grade Summary Table** | `generateExamResultData()` → `$grades_data` | Quick-look grade bracket counts | Same filters |
| **Results Ledger** | `generateExamResultData()` → `$results` (paginated) | Ranked student results with marks, %, division, rank | Same filters |
| **Papers List** | `generateExamResultData()` → `$papers` | Paper dropdown options | exam_id |

---

## 4. Test Data Strategy

- **Core dataset**: Seed 50+ `ExamResult` records for 1-2 exams across multiple papers
- **Result statuses**: 60% PASS, 30% FAIL, 10% ABSENT
- **Grade distribution**: Ensure at least 1 student in each of A+, A, B+, B, C+, C, D, F brackets
- **Ranking**: Ensure clear ordering by percentage (descending) for rank verification
- **Paginated ledger**: Seed 50+ results to test 25-per-page pagination
- **Filters**: Exam, Paper, Class, Section, Result Status combinations
- **Empty state**: Exam with zero results or class with no exam results
- **Pre-test cleanup**: Delete created exam, paper, result records

---

## 5. Business Conditions

### 4.1 Database Schema

#### `lms_exam_results` (StudentPortal module — cross-module)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | exam_id | INT UNSIGNED | NOT NULL, FK → `lms_exams.id` |
| BC-DB-03 | exam_paper_id | INT UNSIGNED | NOT NULL, FK → `lms_exam_papers.id` |
| BC-DB-04 | student_id | INT UNSIGNED | NOT NULL, FK → `std_students.id` |
| BC-DB-05 | attempt_id | INT UNSIGNED | NULLABLE, FK → `lms_exam_attempts.id` |
| BC-DB-06 | total_marks_possible | DECIMAL(8,2) | NOT NULL DEFAULT 0 |
| BC-DB-07 | total_marks_obtained | DECIMAL(8,2) | NOT NULL DEFAULT 0 |
| BC-DB-08 | percentage | DECIMAL(5,2) | NULLABLE |
| BC-DB-09 | result_status | VARCHAR(20) | DEFAULT NULL (PASS/FAIL/ABSENT) |
| BC-DB-10 | grade_obtained | VARCHAR(10) | DEFAULT NULL |
| BC-DB-11 | is_active | TINYINT(1) | DEFAULT 1 |
| BC-DB-12 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-13 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

#### `lms_exams` (LmsExam module)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-14 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-15 | title | VARCHAR(150) | NOT NULL |
| BC-DB-16 | code | VARCHAR(50) | NOT NULL, UNIQUE |
| BC-DB-17 | start_date | DATE | NOT NULL |
| BC-DB-18 | end_date | DATE | NOT NULL |
| BC-DB-19 | is_active | TINYINT(1) | DEFAULT 1 |

#### `lms_exam_papers` (LmsExam module)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-20 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-21 | exam_id | INT UNSIGNED | NOT NULL, FK → `lms_exams.id` |
| BC-DB-22 | subject_id | INT UNSIGNED | NOT NULL, FK → `sch_subjects.id` |
| BC-DB-23 | total_marks | DECIMAL(8,2) | NOT NULL |
| BC-DB-24 | passing_percentage | DECIMAL(5,2) | DEFAULT NULL |
| BC-DB-25 | is_active | TINYINT(1) | DEFAULT 1 |

### 4.2 Filter/Input Validation

| BC ID | Filter Field | Type | Validation Logic | Default |
|-------|-------------|------|------------------|---------|
| BC-VAL-01 | exam_id | INT | NULLABLE; must exist in lms_exams | null |
| BC-VAL-02 | paper_id | INT | NULLABLE; must exist in lms_exam_papers | null |
| BC-VAL-03 | class_id | INT | NULLABLE; must exist in sch_classes | null |
| BC-VAL-04 | section_id | INT | NULLABLE; must exist in sch_sections | null |
| BC-VAL-05 | result_status | STRING | NULLABLE; allowed: 'All', 'Pass', 'Fail', 'Absent' | 'All' |
| BC-VAL-06 | mode | STRING | NULLABLE; allowed: 'Both', 'Online', 'Offline' | 'Both' |
| BC-VAL-07 | date_from | DATE | NULLABLE; parsed via Carbon::parse | none |
| BC-VAL-08 | date_to | DATE | NULLABLE; parsed via Carbon::parse | none |

### 4.3 Authorization

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.lms-exam-report.viewAny | index() | Without → 403 Forbidden |
| BC-AUTH-02 | Guest access | Any reports route | Redirect to /login |

### 4.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Summary Metrics | total_students, present, absent, passed, failed, pass_pct, class_avg, highest, lowest |
| BC-BIZ-02 | Pass Percentage | `(passed / total_students) × 100` |
| BC-BIZ-03 | Class Average | `AVG(percentage)` across all results for the scope |
| BC-BIZ-04 | Ranking | Results sorted by percentage DESC; rank = position in sorted list + 1 |
| BC-BIZ-05 | Top 3 Trophy Badge | Rank ≤ 3 shows gold trophy icon in rank column |
| BC-BIZ-06 | Grade Assignment | A+ (90%+), A (80-89%), B+ (70-79%), B (60-69%), C+ (50-59%), C (40-49%), D (33-39%), F (<33%) |
| BC-BIZ-07 | Division Assignment | I (60%+), II (45-59%), III (33-44%), — (<33%) |
| BC-BIZ-08 | Grade Distribution | 8 buckets: A+, A, B+, B, C+, C, D, F — count of students in each |
| BC-BIZ-09 | Pass Rate Gauge | Radial bar showing pass percentage; green if high, gradient fill |
| BC-BIZ-10 | Grade Bar Chart | 8 bars with colors: green to red gradient, distributed colors |
| BC-BIZ-11 | Result Filter | `PASS` → WHERE result_status = 'PASS'; `FAIL` → WHERE = 'FAIL'; `ABSENT` → WHERE = 'ABSENT' |
| BC-BIZ-12 | Present Count | Results where status != 'ABSENT' |
| BC-BIZ-13 | Efficiency Progress Bar | Green (≥60%), blue (≥40%), red (<40%) |
| BC-BIZ-14 | Pass/Fail Badge | Green for PASS, red for FAIL/ABSENT |
| BC-BIZ-15 | Paginated Ledger | 25 per page with links() |
| BC-BIZ-16 | Paper Cascading | Selecting exam loads its papers via getDependencies() |
| BC-BIZ-17 | Empty Ledger | "No academic records identified for selected criteria." |
| BC-BIZ-18 | Division for null pct | Returns '—' |

### 4.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | exam_result.exam_id | lms_exams.id | CASCADE |
| BC-REF-02 | exam_result.exam_paper_id | lms_exam_papers.id | CASCADE |
| BC-REF-03 | exam_result.student_id | std_students.id | CASCADE |
| BC-REF-04 | exam_paper.exam_id | lms_exams.id | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Result Report page loads with all UI elements | Page loads with filters, 5 metric cards, 2 charts, grade table, results ledger, pagination | — | — | ⬜ |
| TC-P02 | Metrics cards show correct values | Total, Pass Rate, Class Avg, Peak, Floor all match seed | — | — | ⬜ |
| TC-P03 | Pass rate radial gauge renders | Gauge shows pass % in center with gradient fill | — | — | ⬜ |
| TC-P04 | Grade distribution bar chart renders | 8 bars for A+ through F with correct counts | — | — | ⬜ |
| TC-P05 | Grade summary table shows bracket counts | Quick-look table with 8 grade columns and counts | — | — | ⬜ |
| TC-P06 | Results ledger displays correct columns | #, Student Identity, Roll, Grand Total, Mark Secured, Efficiency %, Audit Status, Division, Rank | — | — | ⬜ |
| TC-P07 | Ranking is correct (highest % first) | Top-ranked student has highest percentage | — | — | ⬜ |
| TC-P08 | Top 3 students get trophy badge | Ranks 1-3 show trophy icon | — | — | ⬜ |
| TC-P09 | Pass/Fail badges displayed correctly | PASS = green, FAIL/ABSENT = red | — | — | ⬜ |
| TC-P10 | Division displayed per student | I (≥60%), II (≥45%), III (≥33%), — (<33%) | — | — | ⬜ |
| TC-P11 | Efficiency progress bar color coded | Green ≥60%, blue ≥40%, red <40% | — | — | ⬜ |
| TC-P12 | Filter by exam scopes results | Selecting exam shows only that exam's results | — | — | ⬜ |
| TC-P13 | Filter by paper scopes results | Selecting paper narrows to that paper's results | — | — | ⬜ |
| TC-P14 | Filter by class scopes results | Selecting class shows only that class's results | — | — | ⬜ |
| TC-P15 | Filter by section scopes results | Selecting section narrows results | — | — | ⬜ |
| TC-P16 | Filter by result_status = Pass | Only PASS results shown | — | — | ⬜ |
| TC-P17 | Filter by result_status = Fail | Only FAIL results shown | — | — | ⬜ |
| TC-P18 | Filter by result_status = Absent | Only ABSENT results shown | — | — | ⬜ |
| TC-P19 | Combined filters scope precisely | Exam + Paper + Class + Status all filter correctly | — | — | ⬜ |
| TC-P20 | Pagination — first page | 25 results on page 1 | — | — | ⬜ |
| TC-P21 | Pagination — subsequent pages | Clicking page 2 shows next 25 results | — | — | ⬜ |
| TC-P22 | Page header shows current/total pages | "Page X of Y" displayed | — | — | ⬜ |
| TC-P23 | Reset button clears filters | URL resets, dropdowns default | — | — | ⬜ |
| TC-P24 | Mode filter (Online/Offline) | Filtering by mode scopes results | — | — | ⬜ |
| TC-P25 | Total Students card shows present/absent breakdown | Card subtitle shows X Pres / Y Abs | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Permission 403 — No viewAny permission | 403 Forbidden | — | — | ⬜ |
| TC-N02 | Guest access redirect | Redirect to /login | — | — | ⬜ |
| TC-N03 | Empty state — no exam selected | "No academic records identified" | — | — | ⬜ |
| TC-N04 | Empty state — exam with no results | Empty ledger with message | — | — | ⬜ |
| TC-N05 | Invalid exam_id | No 500 error; empty state | — | — | ⬜ |
| TC-N06 | Invalid class_id | Empty result set; no 500 | — | — | ⬜ |
| TC-N07 | Malformed page parameter | Defaults to page 1 | — | — | ⬜ |
| TC-N08 | All students absent | Pass rate = 0%, present=0 | — | — | ⬜ |
| TC-N09 | All students failed | Pass rate = 0% | — | — | ⬜ |
| TC-N10 | All students passed | Pass rate = 100% | — | — | ⬜ |
| TC-N11 | Single student result | Single row in ledger | — | — | ⬜ |
| TC-N12 | Percentage = null for some results | Excluded from averages; no 500 | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Publishing new exam results adds to report | New results appear in ledger | — | — | ⬜ |
| TC-D02 | B | Updating a result's marks changes rank | Percentage change recalculates ranking | — | — | ⬜ |
| TC-D03 | C | Deleting exam removes all its results | Exam no longer in dropdown; results gone | — | — | ⬜ |
| TC-D04 | D | Large dataset (200+ results) pagination accuracy | All pages correct; no gaps/duplicates | — | — | ⬜ |
| TC-D05 | E | Cross-module: ExamResult from StudentPortal | Results created via StudentPortal reflected here | — | — | ⬜ |
| TC-D06 | F | Grade re-calculation when percentage changes | Updating percentage updates grade/division | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives | Tab wrapped by @can('tenant.lms-exam-report.viewAny') | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — generateExamResultData() at line 401 | Returns results, metrics, charts, papers, grades_data | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | View — null-safe checks | All relations use ?-> or optional() | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — Log::info data audit at line 460 | Logs total/pass/fail counts for monitoring | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — Ranking logic | Sorted by percentage DESC; search-based ranking | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — getDivision() method | Returns I/II/III/— based on % thresholds | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Controller — getGrade() method boundary values | Correct grade at each threshold (90,80,70,60,50,40,33) | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | JS — Pass rate radialBar chart | type:'radialBar', gradient fill, center label | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | JS — Grade bracket bar chart | type:'bar', distributed colors, 8 categories | — | — | ◌ |
| TC-CR10 | CR | Code Review | P1 | JS — AJAX cascading for class → sections | Class change loads sections; exam change loads papers | — | — | ◌ |
| TC-CR11 | CR | Code Review | P1 | ExamAdvancedReportController — All Generators Run On Every Request | index() calls ALL 6 generate*Data() methods regardless of active tab; performance anti-pattern (wasteful for inactive tabs) | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Blade @can Directives

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php | Tab wrapped by @can('tenant.lms-exam-report.viewAny') |
| 2 | Check nav-tab permission | Tab permission = 'tenant.lms-exam-report.viewAny' |
| 3 | User with permission | Tab visible |
| 4 | User without permission | Tab hidden; 403 |

---

#### TC-CR02: Controller — generateExamResultData()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller at line 401 | Method found |
| 2 | Verify ExamResult eager loading | with(['student', 'examPaper.subject', 'attempt']) |
| 3 | Verify filter chain | exam_id, paper_id, class/section via whereHas, result_status |
| 4 | Verify ranking logic | Sorted by percentage DESC |
| 5 | Verify return structure | results (paginated), metrics, charts, papers, grades_data |
| 6 | Verify pass_rate chart series | Single value = pass percentage |
| 7 | Verify grade_profile chart | labels = grade letters, series = counts per grade |

---

#### TC-CR03: View — null-safe Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open exam-result-report.blade.php | View in partials/ |
| 2 | Scan for $r->student?->full_name | ?-> operator used |
| 3 | Scan for $res->examPaper?->subject?->name | Chained null-safe |
| 4 | Load with missing relations | No errors; dashes shown |

---

#### TC-CR04: Log::info Data Audit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller line 460 | Log::info('Rep-3 Data Audit:', ['total'=>..., 'pass'=>..., 'fail'=>...]) |
| 2 | Verify log data | Correct total/pass/fail counts |
| 3 | Check Laravel log after report load | Audit entry appears in storage/logs |

---

#### TC-CR05: Ranking Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 428-446 | $sortedResults = $results->sortByDesc('percentage') |
| 2 | Verify rank assignment | search(fn($item) => $item->id === $r->id) + 1 |
| 3 | Test with identical percentages | Same % gets different ranks (by id order) |
| 4 | Verify top 3 detection | rank <= 3 triggers trophy badge |

---

#### TC-CR06: getDivision() Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller at line 774 | Method found |
| 2 | Test pct = null | Returns '—' |
| 3 | Test pct >= 60 | Returns 'I' |
| 4 | Test pct >= 45 | Returns 'II' |
| 5 | Test pct >= 33 | Returns 'III' |
| 6 | Test pct < 33 | Returns '—' |

---

#### TC-CR07: getGrade() Method Boundary Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller at line 782 | Method found |
| 2 | Test 90 | A+ |
| 3 | Test 80 | A |
| 4 | Test 70 | B+ |
| 5 | Test 60 | B |
| 6 | Test 50 | C+ |
| 7 | Test 40 | C |
| 8 | Test 33 | D |
| 9 | Test 32 | F |
| 10 | Test null | — |

---

#### TC-CR08: Pass Rate RadialBar Chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect JS at line 337 | type:'radialBar', startAngle:-90, endAngle:90 |
| 2 | Verify center label | 'OVERALL PASS RATE' name, value with % suffix |
| 3 | Verify gradient fill | Gradient from light to full color |
| 4 | Verify chart ID | #examPassFailModernChart |

---

#### TC-CR09: Grade Bracket Bar Chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect JS at line 357 | type:'bar', distributed:true, 8 categories |
| 2 | Verify colors array | 8 colors from green to red: #10b981, #84cc16, ..., #ef4444 |
| 3 | Verify data labels | Enabled above bars |
| 4 | Verify chart ID | #examGradeBracketChart |

---

#### TC-CR10: AJAX Cascading for Class → Sections and Exam → Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect class change at line 309 | AJAX with class_id → populates sections |
| 2 | Inspect exam change at line 319 | AJAX with type:'papers', id:examId → populates paper dropdown |
| 3 | Verify setLoader/updateOptions | Proper loading/enabling behavior |

---

### 6.1 Positive TC Steps

#### TC-P01: Result Report Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Advanced Reports → Exam Result Report | Tab pane shown |
| 3 | Check filter bar | 7-8 filter controls: Exam, Paper, Class, Section, Date Range, Mode, Result Filter |
| 4 | Check metric cards | 5 cards: Total Students, Pass Rate, Class Avg, Peak Score, Floor Score |
| 5 | Check charts | Radial gauge and bar chart rendered |
| 6 | Check grade summary table | 8 grade brackets with counts |
| 7 | Check results ledger | Table with 9 columns; pagination |

---

#### TC-P02: Metrics Cards Show Correct Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 40 total, 30 present, 10 absent, 25 pass, 5 fail, avg=65%, highest=98%, lowest=12% | Fixed dataset |
| 2 | Navigate to report with exam filter | Total Students = 40 (30 Pres / 10 Abs) |
| 3 | Pass Rate = 62.5% | (25/40) × 100 |
| 4 | Class Avg = 65% | Average percentage |
| 5 | Peak Score = 98% | Max percentage |
| 6 | Floor Score = 12% | Min percentage |

---

#### TC-P03: Pass Rate Radial Gauge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: pass rate = 75% | Expected gauge |
| 2 | Navigate to report | Gauge shows 75% in center |
| 3 | Verify gauge arc | 75% of arc filled green |

---

#### TC-P04: Grade Distribution Bar Chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: A+=5, A=8, B+=10, B=12, C+=7, C=6, D=4, F=3 | Distribution |
| 2 | Navigate to report | 8 bars with correct heights |
| 3 | Verify colors match grade order | Green to red gradient |

---

#### TC-P05: Grade Summary Table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to report | Grade table visible above ledger |
| 2 | Verify 8 grade columns | A+ (90%+), A (80-89%), B+ (75-79%), B (60-74%), C+ (55-59%), C (50-54%), D (33-49%), F (<33%) |
| 3 | Verify counts match seed | Each bracket count correct |

---

#### TC-P06: Results Ledger Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to report with data | Ledger rendered |
| 2 | Verify columns | #, Student Identity, System Roll, Grand Total, Mark Secured, Efficiency %, Audit Status, Division, Rank |
| 3 | Verify column order | Correct sequence |

---

#### TC-P07: Ranking Correct (Highest First)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: S1=95%, S2=88%, S3=72%, S4=65%, S5=45% | 5 students |
| 2 | Navigate to report | Rank 1 = S1 (95%), Rank 2 = S2 (88%), Rank 3 = S3 (72%), etc. |
| 3 | Verify rank numbers sequential | No gaps or duplicates |

---

#### TC-P08: Top 3 Trophy Badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: top 3 students with high scores | Ranks 1-3 |
| 2 | Navigate to report | Rank 1 shows trophy icon + "#1" |
| 3 | Rank 4+ shows plain "#4" | No trophy for rank 4+ |

---

#### TC-P09: Pass/Fail Badges

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: PASS and FAIL results | Both statuses |
| 2 | Navigate to report | PASS → green badge; FAIL → red badge |
| 3 | ABSENT → red badge | Same as FAIL |

---

#### TC-P10: Division Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: percentages 75%, 50%, 35%, 20% | Various divisions |
| 2 | Navigate to report | 75% → 'I', 50% → 'II', 35% → 'III', 20% → '—' |

---

#### TC-P11: Efficiency Progress Bar

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: percentages 75%, 45%, 25% | Three categories |
| 2 | Navigate to report | 75% → green bar, 45% → blue bar, 25% → red bar |
| 3 | Percentage label shown beside bar | Text shows exact % |

---

#### TC-P12: Filter By Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Exam A (30 results), Exam B (20 results) | Two exams |
| 2 | Select Exam A | Only Exam A results shown |
| 3 | Select Exam B | Only Exam B results shown |

---

#### TC-P13: Filter By Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Paper X (15 results), Paper Y (15 results) | Two papers |
| 2 | Select Exam then Paper X | Only Paper X results |
| 3 | Select Paper Y | Only Paper Y results |

---

#### TC-P14: Filter By Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class 9 (20 results), Class 10 (20 results) | Two classes |
| 2 | Select Class 9 | Only Class 9 results |

---

#### TC-P15: Filter By Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class + section | Only that section's results |

---

#### TC-P16: Filter By result_status = Pass

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Result filter = 'Pass' | Only PASS results in ledger |
| 2 | Verify absent/fail excluded | Not visible |

---

#### TC-P17: Filter By result_status = Fail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Result filter = 'Fail' | Only FAIL results shown |
| 2 | Verify PASS excluded | Not visible |

---

#### TC-P18: Filter By result_status = Absent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Result filter = 'Absent' | Only ABSENT results shown |
| 2 | Verify only absent students | All rows show ABSENT badge |

---

#### TC-P19: Combined Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Exam A + Paper X + Class 9 + Pass status | Precise subset |
| 2 | Verify only matching results | Filtered correctly |

---

#### TC-P20: Pagination — First Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 50 results | 2 pages expected |
| 2 | Navigate to page 1 | 25 results shown |
| 3 | Verify page 1 active | Pagination link highlighted |

---

#### TC-P21: Pagination — Subsequent Pages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click page 2 | Results 26-50 shown |
| 2 | Verify ranking continues | Ranks 26-50 correct |

---

#### TC-P22: Page Header Shows Current/Total

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to report | Header shows "Page 1 of 2" |

---

#### TC-P23: Reset Button

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filters | URL has params |
| 2 | Click Reset | URL clears; defaults shown |

---

#### TC-P24: Mode Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Online mode | Only online attempt results shown (Note: mode from attempt relation) |

---

#### TC-P25: Total Students Card Breakdown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 30 present, 10 absent | Card shows "30 Pres / 10 Abs" |

---

### 6.2 Negative TC Steps

#### TC-N01: Permission 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without permission | Dashboard |
| 2 | Navigate to report | 403 Forbidden |

---

#### TC-N02: Guest Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout | Redirect to login |
| 2 | Navigate to report URL | Redirect to /login |

---

#### TC-N03: No Exam Selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No exam selected | All results across exams shown or empty state |
| 2 | If no default exam | Empty ledger message shown |

---

#### TC-N04: Exam With No Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select exam with no results | "No academic records identified" |
| 2 | Metrics show 0 | All metrics zeroed |

---

#### TC-N05: Invalid exam_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | ?exam_id=99999 | Empty ledger; no 500 |

---

#### TC-N06: Invalid class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | ?class_id=99999 | No results; no 500 |

---

#### TC-N07: Malformed Page Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | ?page=-1| Defaults to page 1 |

---

#### TC-N08: All Students Absent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed all ABSENT | Pass rate = 0% |
| 2 | Present count = 0 | Card shows 0 Pres |

---

#### TC-N09: All Students Failed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed all FAIL | Pass rate = 0% |
| 2 | All red badges | Correct |

---

#### TC-N10: All Students Passed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed all PASS | Pass rate = 100% |
| 2 | Gauge shows 100% | Full arc filled |

---

#### TC-N11: Single Student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 1 result | Single row in ledger |
| 2 | Rank = 1 | Trophy badge shown |

---

#### TC-N12: Null Percentage Some Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed results with percentage = NULL | Excluded from avg |
| 2 | No division by zero | Avg calculated only on non-null |

---

### 6.3 Dependency TC Steps

#### TC-D01: Publishing New Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note result count = X | Before publish |
| 2 | Publish new exam results | Results created |
| 3 | Refresh report | Count = X + new count |

---

#### TC-D02: Updating Result Changes Rank

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note ranking of a student | Current rank = R |
| 2 | Increase student's marks | Percentage increases |
| 3 | Refresh report | Rank may improve |

---

#### TC-D03: Deleting Exam Removes Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete exam | Exam trashed |
| 2 | Exam no longer in dropdown | Not selectable |

---

#### TC-D04: Large Dataset Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 200 results | 8 pages |
| 2 | Cycle through all pages | No gaps/duplicates |

---

#### TC-D05: Cross-Module Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create ExamResult via StudentPortal | Result created |
| 2 | Refresh report | New result appears |

---

#### TC-D06: Grade Recalculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Change percentage from 85 to 45 | Grade changes from A+ to C+ |
| 2 | Division changes from I to III | Correct |

---

### 6.4 Code Review TC Steps

#### TC-CR04: Log::info Data Audit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect controller line 460 | Log::info with total/pass/fail |
| 2 | Load report with 40 results | Log shows total=40, pass=25, fail=5 |
| 3 | Check storage/logs | Entry present |

---

#### TC-CR05: Ranking Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 428-446 | $sortedResults = $results->sortByDesc('percentage') |
| 2 | Test with equal percentages | Ranks assigned by id order |
| 3 | Verify rank reset on re-load | Ranking recalculated each time |

---

#### TC-CR07: getGrade() Boundary Testing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Line 782-789 | if/else chain |
| 2 | pct = 89.9 | Returns 'A' (not A+) |
| 3 | pct = 90.0 | Returns 'A+' |
| 4 | pct = 79.9 | Returns 'B' (not B+) |
| 5 | pct = 80.0 | Returns 'A' |

---

#### TC-CR10: AJAX Class → Sections and Exam → Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Class change at line 309 | Gets sections and exams via depsUrl |
| 2 | Exam change at line 319 | Gets papers via type:'papers' |
| 3 | Verify error handling | .fail() logs to console |

---

#### TC-CR11: Controller — Grade Distribution Array Initialization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 462 | $grades = ['A+'=>0, 'A'=>0, 'B+'=>0, 'B'=>0, 'C+'=>0, 'C'=>0, 'D'=>0, 'F'=>0] |
| 2 | Verify foreach iteration | Each result increments matching grade bucket |
| 3 | Verify fallback grade | Uses grade_obtained if set, else calls getGrade() |
| 4 | Test with all empty | All buckets show 0 |

---

#### TC-CR12: Controller — Class/Section whereHas Filtering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 414-419 | whereHas('student.studentAcademicSessions.classSection', ...) |
| 2 | Verify class_id condition | ->where('class_id', $classId) chained inside whereHas |
| 3 | Verify section_id condition | ->where('section_id', $sectionId) chained inside whereHas |
| 4 | Verify both optional | Only conditionally added when provided |

---

#### TC-CR13: View — Result Status Badge Color Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade line 226 | Ternary: PASS → green badge, else red badge |
| 2 | Test status = 'PASS' | bg-success-subtle text-success |
| 3 | Test status = 'FAIL' | bg-danger-subtle text-danger |
| 4 | Test status = 'ABSENT' | bg-danger-subtle text-danger (same as FAIL) |

---

#### TC-CR14: View — Rank Trophy Badge Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade line 232-236 | if rank <= 3 → trophy badge with warning color |
| 2 | Test rank = 1 | bg-warning text-dark with trophy icon |
| 3 | Test rank = 4 | Plain text-muted "#4" |

---

#### TC-CR15: View — Efficiency Progress Bar Color Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade line 219 | Ternary: ≥60% → bg-success, ≥40% → bg-primary, else bg-danger |
| 2 | Test pct = 75 | bg-success |
| 3 | Test pct = 45 | bg-primary |
| 4 | Test pct = 25 | bg-danger |

---

#### TC-P26: Result Status Uppercase Normalization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed result_status = 'pass' (lowercase) | Mixed case |
| 2 | Controller uses strtoupper() at line 422 | Normalized to 'PASS' |
| 3 | Filter by 'Pass' (capital P) | Lowercase 'pass' matches due to strtoupper comparison |

---

#### TC-P27: Grade Bracket Range Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to report | Grade table shows ranges: A+ (90%+), A (80-89%), etc. |
| 2 | Verify column headers correct | Each bracket range shown correctly |

---

#### TC-P28: Ledger Row Number Starting Index

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to page 1 | Row numbers start at 1 |
| 2 | Navigate to page 2 | Row numbers start at 26 |

---

#### TC-P29: Marks Display Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to report | Grand Total shows integer marks |
| 2 | Mark Secured shows integer | Cast to (int) |

---

#### TC-P30: Badge CSS Styling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect PASS badge | bg-success-subtle text-success with border |
| 2 | Inspect FAIL badge | bg-danger-subtle text-danger with border |
| 3 | Verify min-width 50px | Badge has consistent width |

---

#### TC-P31: Radial Gauge Responsive Height

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check chart container | min-height: 280px |
| 2 | Resize browser | Chart responsive; no overflow |

---

#### TC-P32: Grade Bar Chart Responsive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check chart container | min-height: 280px |
| 2 | Verify 8 bars visible | All grade brackets shown |

---

#### TC-N13: Result Filter 'All' Shows All Statuses

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed PASS, FAIL, ABSENT | All three statuses |
| 2 | Set result_status = 'All' | All statuses shown in ledger |
| 3 | Verify PASS, FAIL, ABSENT rows visible | Complete dataset |

---

#### TC-N14: Very Small Percentage (<1%)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed result with 0.5% | Very low |
| 2 | Progress bar shows minimal width | No bar rendering issues |
| 3 | Still passes boundary checks | Grade = F, Division = — |

---

#### TC-N15: Marks Obtained Greater Than Total (edge case)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed total=50, obtained=55 | Obtained > total |
| 2 | Percentage = 110% | Displayed as-is |
| 3 | Grade could be A+ | Business logic handles >100% |

---

#### TC-N16: No Papers for Selected Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select exam with no papers | Paper dropdown shows only 'All Papers' |
| 2 | Results still load (if any) | Results based on all papers |

---

#### TC-D07: Data Sync — Result Count vs Exam Module

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count results in exam_results table | Total = X |
| 2 | Load report with matching exam filter | Ledger shows X results |
| 3 | Count matches | Consistent |

---

#### TC-D08: Data Sync — Grade vs getGrade()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed grade_obtained = NULL | Falls back to getGrade() |
| 2 | Seed grade_obtained = 'B' | Uses stored grade directly |
| 3 | Verify ledger shows correct grade | Both scenarios work |

---

## End of TC List
