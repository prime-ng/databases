# lms_ExamSubjectComparison_TcList

## Module: LmsExam → Advanced Reports → Exam Subject Comparison

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Advanced Reports |
| Feature | Exam Subject Comparison |
| URL(s) | `/lms-exam/exam-advanced-reports?active_tab=exam-subject-comparison` (index) |
| Controller | `Modules\LmsExam\Http\Controllers\ExamAdvancedReportController@index()` |
| Method (Data) | `generateExamSubjectComparisonData()` (private, line 605) |
| Model(s) | `Modules\StudentPortal\Models\ExamResult`, `Modules\LmsExam\Models\ExamPaper`, `Modules\LmsExam\Models\Exam`, `Modules\SchoolSetup\Models\Subject` |
| View (Partial) | `advanced-reports/partials/exam-subject-comparison.blade.php` |
| Permissions | `tenant.lms-exam-report.viewAny` |
| Pagination | None (single table) |
| Charts | ApexCharts: grouped bar (benchmarking), stacked bar (banding) |

---

## 2. Pre-conditions

- Required permission: `tenant.lms-exam-report.viewAny`
- Required seed data: One `Exam` with multiple `ExamPaper` records linked to different `Subject` records
- Multiple `ExamResult` records per paper with varied percentages
- At least 3+ subjects/papers for meaningful comparison
- Varied pass rates across subjects for benchmarking distinction
- Performance banding data: mix of High (75%+), Mid (40-74%), Low (<40%) across subjects
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

When the page loads via `ExamAdvancedReportController@index()` with `active_tab=exam-subject-comparison`:

| Widget/Chart | Data Source | Query Logic | Filters |
|-------------|-------------|-------------|---------|
| Shared Dropdowns | classes, sections, exams | Standard shared queries | — |
| **Metrics Cards (4)** | `generateExamSubjectComparisonData()` → `$metrics` | total_students, total_papers, overall_avg, avg_pass_rate, best_performing | exam_id, date_from, date_to |
| **Subject Benchmark Chart** | `generateExamSubjectComparisonData()` → `$charts['benchmarking']` | Grouped bar: Avg Score % + Pass Rate % per subject | exam_id, date_from, date_to |
| **Performance Banding Chart** | `generateExamSubjectComparisonData()` → `$charts['banding']` | Stacked bar: High/Mid/Low per subject | exam_id, date_from, date_to |
| **Subject Comparison Table** | `generateExamSubjectComparisonData()` → `$rows` | Per-subject stats with pass/fail counts | exam_id, date_from, date_to |

---

## 4. Test Data Strategy

- **Core dataset**: 1 exam with 5 papers covering Math, Science, English, History, Geography
- **Students**: 30+ results per paper with varied percentages
- **Pass rates**: Math (90%), Science (75%), English (85%), History (60%), Geography (45%)
- **Banding distribution**: Each subject should have students in High/Mid/Low brackets
- **Edge cases**: One subject with all PASS, one with mostly FAIL, one with 50/50 split
- **Empty state**: Exam with no results or no papers
- **Date filter**: Results spread across 3 months for date range testing

---

## 5. Business Conditions

### 4.1 Database Schema

#### `lms_exam_results` (StudentPortal)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | exam_id | INT UNSIGNED | NOT NULL, FK → `lms_exams.id` |
| BC-DB-03 | exam_paper_id | INT UNSIGNED | NOT NULL, FK → `lms_exam_papers.id` |
| BC-DB-04 | student_id | INT UNSIGNED | NOT NULL, FK → `std_students.id` |
| BC-DB-05 | total_marks_possible | DECIMAL(8,2) | NOT NULL DEFAULT 0 |
| BC-DB-06 | total_marks_obtained | DECIMAL(8,2) | NOT NULL DEFAULT 0 |
| BC-DB-07 | percentage | DECIMAL(5,2) | NULLABLE |
| BC-DB-08 | result_status | VARCHAR(20) | DEFAULT NULL |

#### `lms_exam_papers`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-09 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-10 | exam_id | INT UNSIGNED | NOT NULL, FK → `lms_exams.id` |
| BC-DB-11 | subject_id | INT UNSIGNED | NOT NULL, FK → `sch_subjects.id` |
| BC-DB-12 | total_marks | DECIMAL(8,2) | NOT NULL |

### 4.2 Filter/Input Validation

| BC ID | Filter Field | Type | Validation Logic | Default |
|-------|-------------|------|------------------|---------|
| BC-VAL-01 | class_id | INT | NULLABLE | null |
| BC-VAL-02 | section_id | INT | NULLABLE | null |
| BC-VAL-03 | exam_id | INT | NULLABLE | null |
| BC-VAL-04 | date_from | DATE | NULLABLE | none |
| BC-VAL-05 | date_to | DATE | NULLABLE | none |

### 4.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | tenant.lms-exam-report.viewAny | Without → 403 |
| BC-AUTH-02 | Guest access | Redirect to /login |

### 4.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Subject-wise Aggregation | Per paper: avg percentage, pass count, fail count, pass rate, max, min |
| BC-BIZ-02 | Pass Rate Calculation | `(passed / total_results) × 100` per paper |
| BC-BIZ-03 | Performance Bands | High ≥ 75%, Mid 40-74%, Low < 40% |
| BC-BIZ-04 | Overall Average | Average of all subject average percentages |
| BC-BIZ-05 | Avg Pass Rate | Average of all subject pass rates |
| BC-BIZ-06 | Best Performing | Subject with highest avg_pct |
| BC-BIZ-07 | Benchmarking Chart | Grouped bar: Avg Score % (purple) + Pass Rate % (green) per subject |
| BC-BIZ-08 | Banding Chart | Stacked bar: High (green), Mid (yellow), Low (red) per subject |
| BC-BIZ-09 | Pass Rate Progress Bar | Green ≥75%, yellow ≥50%, red <50% |
| BC-BIZ-10 | Empty Paper Handling | Paper with 0 results is skipped (continue) |
| BC-BIZ-11 | Unique Student Count | Results->unique('student_id')->count() |

### 4.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete |
|-------|-----------|------------------|----------|
| BC-REF-01 | exam_result.exam_paper_id | lms_exam_papers.id | CASCADE |
| BC-REF-02 | exam_paper.exam_id | lms_exams.id | CASCADE |
| BC-REF-03 | exam_paper.subject_id | sch_subjects.id | RESTRICT |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Subject Comparison page loads with all UI elements | Filter bar, 4 metric cards, 2 charts, comparison table | — | — | ⬜ |
| TC-P02 | Metrics cards show correct summary values | Analysed Students, Net Exam Avg, Pass Consistency, Leading Subject | — | — | ⬜ |
| TC-P03 | Benchmarking chart renders grouped bars | Two bars per subject: Avg Score % and Pass Rate % | — | — | ⬜ |
| TC-P04 | Banding chart renders stacked bars | Three segments per subject: High/Mid/Low | — | — | ⬜ |
| TC-P05 | Comparison table shows correct columns | #, Subject, Max Marks, Avg Marks, Avg %, Peak %, Lowest %, Pass/Fail, Pass Rate | — | — | ⬜ |
| TC-P06 | Per-subject avg % correct | Average percentage matches manual calculation | — | — | ⬜ |
| TC-P07 | Per-subject pass rate correct | Pass count / total × 100 | — | — | ⬜ |
| TC-P08 | Pass/Fail badges show correct counts | Green badge for pass count, red badge for fail count | — | — | ⬜ |
| TC-P09 | Pass rate progress bar color coded | Green ≥75%, yellow ≥50%, red <50% | — | — | ⬜ |
| TC-P10 | Leading Subject correctly identified | Subject with highest avg_pct shown in metrics | — | — | ⬜ |
| TC-P11 | Filter by exam scopes data | Selecting exam shows only that exam's subject comparison | — | — | ⬜ |
| TC-P12 | Filter by class scopes data | Selecting class shows only that class's results | — | — | ⬜ |
| TC-P13 | Filter by section scopes data | Selecting section narrows results | — | — | ⬜ |
| TC-P14 | Combined filters scope precisely | Exam + Class + Section combine correctly | — | — | ⬜ |
| TC-P15 | Multiple subjects displayed as separate rows | Each paper = one row in table | — | — | ⬜ |
| TC-P16 | Reset button clears filters | URL resets, defaults | — | — | ⬜ |
| TC-P17 | Date range filter scopes results | Results within date range included | — | — | ⬜ |
| TC-P18 | High/Mid/Low banding counts correct for each subject | Band counts match manual bucket calculation | — | — | ⬜ |
| TC-P19 | Subject name displayed via eager-loaded relation | Subject name from ExamPaper->subject | — | — | ⬜ |
| TC-P20 | Max marks displayed per subject | total_marks from exam_papers table | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Permission 403 — No viewAny | 403 Forbidden | — | — | ⬜ |
| TC-N02 | Guest access redirect | Redirect to /login | — | — | ⬜ |
| TC-N03 | No exam selected | Empty state: "Generate report to visualize cross-subject success metrics." | — | — | ⬜ |
| TC-N04 | Exam with no results | Empty table; metrics show 0 or '—' | — | — | ⬜ |
| TC-N05 | Exam with no papers | Empty table; metrics zeroed | — | — | ⬜ |
| TC-N06 | Invalid exam_id | Empty state; no 500 | — | — | ⬜ |
| TC-N07 | Invalid class_id | Empty state; no 500 | — | — | ⬜ |
| TC-N08 | Single paper exam | Single row in table; still shows charts | — | — | ⬜ |
| TC-N09 | All students failed one subject | Pass rate = 0%, all red bar | — | — | ⬜ |
| TC-N10 | All students passed one subject | Pass rate = 100%, all green bar | — | — | ⬜ |
| TC-N11 | Zero marks possible for paper | avg_pct = 0%; no division by zero | — | — | ⬜ |
| TC-N12 | No date range specified | All results returned (no date filter) | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Adding new paper to exam adds row to comparison | New subject appears in table after refresh | — | — | ⬜ |
| TC-D02 | B | Changing result marks updates subject averages | Updating marks recalculates avg_pct for that subject | — | — | ⬜ |
| TC-D03 | C | Deleting exam paper removes its row | Paper no longer visible; metrics recalculated | — | — | ⬜ |
| TC-D04 | D | Large dataset (20+ papers) rendering | All papers displayed without performance issues | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives | Tab wrapped by @can('tenant.lms-exam-report.viewAny') | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — generateExamSubjectComparisonData() at line 605 | Returns rows, metrics, charts | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | View — null-safe checks | $paper->subject?->name used consistently | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — Band calculation logic | Bands: ≥75% High, 40-74% Mid, <40% Low | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | JS — Grouped bar chart config | type:'bar', two series (Avg Score, Pass Rate) | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | JS — Stacked bar chart config | type:'bar', stacked:true, three series (High/Mid/Low) | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Controller — Empty paper skipped | count===0 → continue; skips papers with no results | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | View — Pass rate bar color logic | ≥75% green, ≥50% yellow, <50% red | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | View — Summary row at bottom | Papers Audited, Overall Avg, Pass Consistency, Top Performer | — | — | ◌ |
| TC-CR10 | CR | Code Review | P1 | JS — AJAX class dependency | Class change loads sections and exams | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Blade @can Directives

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php | Tab wrapped by @can |
| 2 | Check nav-tab permission | 'tenant.lms-exam-report.viewAny' |
| 3 | User with permission | Tab visible |
| 4 | User without permission | Tab hidden; 403 |

---

#### TC-CR02: Controller — generateExamSubjectComparisonData()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller at line 605 | Method found |
| 2 | Verify results query | ExamResult when exam_id provided, date range |
| 3 | Verify papers query | ExamPaper with subject when exam_id provided |
| 4 | Verify per-paper loop | For each paper: calculate avg, pass rate, bands |
| 5 | Verify return structure | rows, metrics, charts |

---

#### TC-CR03: View — null-safe Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open view file | Checked |
| 2 | Scan for $paper->subject?->name | ?-> used |
| 3 | Load with null subject | Shows 'Subject N' fallback |

---

#### TC-CR04: Band Calculation Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 658-660 | $bandingHigh: pct >= 75, $bandingMid: 40-74, $bandingLow: <40 |
| 2 | Test pct = 75 | Counted in High |
| 3 | Test pct = 40 | Counted in Mid |
| 4 | Test pct = 39.9 | Counted in Low |

---

#### TC-CR05: Grouped Bar Chart (Benchmarking)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect JS at line 222 | type:'bar', two series: Avg Score %, Pass Rate % |
| 2 | Verify colors | purple (#6366f1), green (#10b981) |
| 3 | Verify y-axis max = 100 | Scale 0-100 |
| 4 | Verify chart ID | #subjectBenchmarkingChart |

---

#### TC-CR06: Stacked Bar Chart (Banding)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect JS at line 236 | type:'bar', stacked:true, three series |
| 2 | Verify colors | green (#10b981), yellow (#f59e0b), red (#ef4444) |
| 3 | Verify chart ID | #subjectBandingChart |

---

#### TC-CR07: Empty Paper Skipped

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 635 | if ($count === 0) continue |
| 2 | Seed paper with 0 results | Paper not included in table/charts |

---

#### TC-CR08: Pass Rate Bar Color

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade line 150 | Ternary: ≥75% → bg-success, ≥50% → bg-warning, else bg-danger |
| 2 | Test rate = 80 | Green bar |
| 3 | Test rate = 55 | Yellow bar |
| 4 | Test rate = 30 | Red bar |

---

#### TC-CR09: Summary Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade lines 168-181 | @if(!empty) guards summary |
| 2 | Verify 4 summary items | Papers Audited, Overall Avg, Pass Consistency, Top Performer |

---

#### TC-CR10: AJAX Class Dependency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect JS lines 202-215 | Class change loads sections and exams |
| 2 | Verify clear on empty class | If no classId, sections/exams reset to placeholder |

---

### 6.1 Positive TC Steps

#### TC-P01: Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard |
| 2 | Navigate to Exam Subject Comparison tab | Tab pane shown |
| 3 | Check filter bar | Class, Section, Exam dropdowns + Run Benchmarking button |
| 4 | Check metric cards | 4 cards with summary values |
| 5 | Check charts | Benchmarking grouped bar + Banding stacked bar |
| 6 | Check comparison table | Subject rows with stats |

---

#### TC-P02: Metrics Cards Show Correct Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 5 papers, 100 students, overall avg 72%, avg pass rate 80%, best=Math (85%) | Fixed |
| 2 | Navigate to report | Analysed Students = 100, Net Exam Avg = 72%, Pass Consistency = 80%, Leading Subject = Math |

---

#### TC-P03: Benchmarking Chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 3 subjects with different avgs and pass rates | Chart data |
| 2 | Navigate to report | Grouped bar chart with 3 subject groups |
| 3 | Each group has 2 bars | Purple (Avg %) and Green (Pass Rate %) |

---

#### TC-P04: Banding Chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed subjects with varied band distribution | Band data |
| 2 | Navigate to report | Stacked bar with green/yellow/red segments |

---

#### TC-P05: Comparison Table Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to report with data | Table rendered |
| 2 | Verify 9 columns | #, Subject, Max Marks, Avg Marks, Avg %, Peak %, Lowest %, Pass/Fail, Pass Rate |
| 3 | Verify column order | Correct sequence |

---

#### TC-P06: Per-Subject Avg % Correct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Math paper — 4 results (80%, 70%, 90%, 60%) | Expected avg = 75% |
| 2 | Navigate to report | Math row shows Avg % = 75% |

---

#### TC-P07: Per-Subject Pass Rate Correct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Math — 10 results, 8 PASS, 2 FAIL | Expected rate = 80% |
| 2 | Navigate to report | Pass Rate = 80% |

---

#### TC-P08: Pass/Fail Badges

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to report | Pass count = green badge, Fail count = red badge |
| 2 | Verify badge CSS | bg-success-subtle / bg-danger-subtle |

---

#### TC-P09: Pass Rate Progress Bar Color

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Subject with pass rate 85% | Green progress bar |
| 2 | Subject with pass rate 55% | Yellow progress bar |
| 3 | Subject with pass rate 30% | Red progress bar |

---

#### TC-P10: Leading Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Math (avg 85%), Science (avg 72%), English (avg 78%) | Best = Math |
| 2 | Leading Subject card shows "Mathematics" | Correct top performer |

---

#### TC-P11: Filter By Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Exam A (3 papers), Exam B (2 papers) | Two exams |
| 2 | Select Exam A | Only Exam A's subjects shown |
| 3 | Select Exam B | Only Exam B's subjects shown |

---

#### TC-P12: Filter By Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class 9 results, Class 10 results | Two classes |
| 2 | Select Class 9 | Only Class 9 results aggregated |

---

#### TC-P13: Filter By Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class + section | Only that section's results |

---

#### TC-P14: Combined Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class 9 + Section A + Exam A | Precise subset |

---

#### TC-P15: Multiple Subjects As Separate Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 5 papers | 5 rows in table |
| 2 | Verify each row different subject | Unique subject names |

---

#### TC-P16: Reset Button

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filters | Parameters in URL |
| 2 | Click Reset | URL clears |

---

#### TC-P17: Date Range Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date range | Results within range included |
| 2 | Results outside excluded | Correct scoping |

---

#### TC-P18: Banding Counts Correct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Math — 5 results (85%, 60%, 30%, 90%, 45%) | High=2, Mid=2, Low=1 |
| 2 | Navigate to report | Math banding: High=2, Mid=2, Low=1 |

---

#### TC-P19: Subject Name Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed paper with subject "Mathematics" | Table shows "Mathematics" |

---

#### TC-P20: Max Marks Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed paper with total_marks=100 | Max Marks = 100 |

---

### 6.2 Negative TC Steps

#### TC-N01: Permission 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without permission | 403 Forbidden |

---

#### TC-N02: Guest Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout | Redirect to /login |

---

#### TC-N03: No Exam Selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No exam filter | Empty table with message |
| 2 | Message: "Generate report to visualize cross-subject success metrics." | Correct |

---

#### TC-N04: Exam With No Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select exam with no results | Papers may appear but all stats 0 |
| 2 | Table shows 0s | No errors |

---

#### TC-N05: Exam With No Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select exam with no papers | Empty table |

---

#### TC-N06: Invalid exam_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | ?exam_id=99999 | Empty state; no 500 |

---

#### TC-N07: Invalid class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | ?class_id=99999 | Empty state; no 500 |

---

#### TC-N08: Single Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Exam with 1 paper | Single row; charts show single subject |

---

#### TC-N09: All Failed Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Subject where all results FAIL | Pass rate = 0% |
| 2 | Progress bar red | Correct |

---

#### TC-N10: All Passed Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Subject where all results PASS | Pass rate = 100% |
| 2 | Progress bar green | Correct |

---

#### TC-N11: Zero Max Marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper with total_marks = 0 | Avg % = 0; no division by zero |

---

#### TC-N12: No Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No date_from/date_to | All results returned |

---

### 6.3 Dependency TC Steps

#### TC-D01: Adding New Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note paper count = X | Current |
| 2 | Add new paper to exam | Paper created |
| 3 | Refresh comparison | Count = X+1 |

---

#### TC-D02: Changing Marks Updates Averages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note subject avg = X% | Current avg |
| 2 | Update result marks for that subject | Marks changed |
| 3 | Refresh | Avg recalculated |

---

#### TC-D03: Deleting Paper Removes Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a paper | Paper removed |
| 2 | Refresh comparison | Row gone; metrics recalculated |

---

#### TC-D04: Large Dataset

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 20+ papers | 20 rows |
| 2 | Page renders correctly | All rows visible; scrollable |

---

### 6.4 Code Review TC Steps

#### TC-CR04: Band Calculation Boundaries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 658-660 | Three filter calls for High/Mid/Low |
| 2 | Test pct >= 75 | Counted in High |
| 3 | Test pct = 40 to 74 | Counted in Mid |
| 4 | Test pct < 40 | Counted in Low |
| 5 | Boundary: pct = 74.9 | Mid (not High) |
| 6 | Boundary: pct = 75.0 | High |
| 7 | Boundary: pct = 39.9 | Low |
| 8 | Boundary: pct = 40.0 | Mid |

---

#### TC-CR07: Empty Paper Continue

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 635 | $count === 0 → continue |
| 2 | Verify 0-count paper excluded | Not in rows array |
| 3 | Verify no chart entry | Not in labels/series arrays |

---

#### TC-CR08: Pass Rate Bar Color

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade line 150 | Ternary CSS class |
| 2 | pass_rate >= 75 | bg-success |
| 3 | pass_rate >= 50 | bg-warning |
| 4 | pass_rate < 50 | bg-danger |

---

#### TC-CR09: Summary Row Rendering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade lines 168-181 | Guarded by @if(!empty($examSubjectComparisonData['rows'])) |
| 2 | Verify 4 cells: Papers Audited, Overall Average, Pass consistency, Top Performer | All present |
| 3 | Empty rows state | Summary row hidden |

---

#### TC-P21: Average Marks Calculation Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Subject with 3 results: marks_obtained=45, 50, 55; total_marks_possible=100 each | Expected avg marks = (45+50+55)/3 = 50 |
| 2 | Navigate to report | Avg Marks = 50.0 |

---

#### TC-P22: Highest Percentage Per Subject

| Step # | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed: Subject scores 45%, 72%, 88%, 60% | Highest = 88% |
| 2 | Navigate to report | Peak % shows 88% |

---

#### TC-P23: Lowest Percentage Per Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Subject scores 45%, 72%, 88%, 60% | Lowest = 45% |
| 2 | Navigate to report | Lowest % shows 45% |

---

#### TC-P24: Total Students Count Unique

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 30 results but only 25 unique student_ids | Expected unique count = 25 |
| 2 | Navigate to report | Analysed Students = 25 |

---

#### TC-P25: Total Papers Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 5 papers with results | total_papers = 5 |
| 2 | Navigate to report | Metrics shows paper count = 5 |

---

#### TC-P26: Best Performing Subject Calculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Math (avg 85%), Science (avg 72%), English (avg 78%) | Best = Math (85%) |
| 2 | Navigate to report | Leading Subject = Mathematics |

---

#### TC-P27: Overall Average Calculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 3 subjects with avg_pct 85%, 72%, 78% | Overall avg = (85+72+78)/3 = 78.3% |
| 2 | Navigate to report | Net Exam Avg = 78.3% |

---

#### TC-P28: Average Pass Rate Calculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 3 subjects with pass_rate 90%, 75%, 80% | Avg pass rate = (90+75+80)/3 = 81.7% |
| 2 | Navigate to report | Pass Consistency = 81.7% |

---

#### TC-P29: Subject With 100% Pass Rate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Subject with all results PASS | Pass rate = 100% |
| 2 | Progress bar full green | Correct visual |

---

#### TC-P30: Subject With 0% Pass Rate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Subject with all results FAIL | Pass rate = 0% |
| 2 | Progress bar full red | Correct visual |

---

#### TC-P31: Benchmark Chart — Single Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed exam with only 1 paper | Single group in chart |
| 2 | Two bars visible for that subject | Avg % and Pass Rate bars |

---

#### TC-P32: Banding Chart — All Low Performers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: All results < 40% | Banding shows 100% Low (red) |
| 2 | Navigate to report | Stacked bar entirely red |

---

#### TC-P33: Banding Chart — All High Performers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: All results ≥ 75% | Banding shows 100% High (green) |
| 2 | Navigate to report | Stacked bar entirely green |

---

#### TC-P34: Banding Chart — Perfect Distribution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Equal distribution across High/Mid/Low | Each band = 33.3% |
| 2 | Three segments visible | Green/Yellow/Red equal sizes |

---

#### TC-P35: Pass/Fail Count Sum Equals Total Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 10 PASS + 5 FAIL = 15 | Total = 15 |
| 2 | Verify passed + failed = total count | passed(10) + failed(5) = 15 |

---

#### TC-P36: AJAX Cascading — Class Changes Load Sections + Exams

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a class | Sections and exams load via AJAX |
| 2 | Verify sections populated | #filter_esc_section has options |
| 3 | Verify exams populated | #filter_esc_exam has exam options |

---

#### TC-P37: AJAX — Clear Class Clears Sections and Exams

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class, then clear to blank | Sections and exams reset to placeholders |
| 2 | Verify sections | "All Sections" only option |
| 3 | Verify exams | "Select Exam" only option |

---

#### TC-P38: Run Benchmarking Button Submits Form

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select exam, click Run Benchmarking | Form submits with active_tab=exam-subject-comparison |
| 2 | Page reloads with data | Report table and charts render |

---

#### TC-P39: Reset Button Clears Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filters, click reset | URL resets to ?active_tab=exam-subject-comparison |

---

#### TC-P40: Table Row Striking — Alternating Row Colors

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect table class | table-hover class applied for row highlighting |

---

#### TC-N13: Exam Selected But No class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select exam without class | Results from all classes shown |
| 2 | Aggregate across all classes | Correct totals |

---

#### TC-N14: Section Without Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set section without class | Section ignored (dropdown disabled) |

---

#### TC-N15: Date Range End Before Start

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date_from > date_to | Query returns empty (no results in inverted range) |
| 2 | No 500 error | Empty table |

---

#### TC-N16: Exam With Only Absent Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed all results ABSENT | All passed = 0, failed = 0, pass rate = 0% |
| 2 | avg_pct may be 0% or null | Displayed gracefully |

---

#### TC-D05: Result Status Change Affects Pass Rate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Change FAIL to PASS for a result | Pass count increments, fail count decrements |
| 2 | Refresh comparison | Pass rate recalculated |

---

#### TC-D06: Adding Student Result Adds to Subject Pool

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create new ExamResult for a subject | Subject's result count +1 |
| 2 | Refresh comparison | Avg/pass rate recalculated |

---

#### TC-D07: Deleting All Results for a Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete all results for one subject | Paper has 0 results |
| 2 | Paper excluded from table | Skipped via continue logic |

---

#### TC-CR11: Controller — Date Range Filtering in Subject Comparison

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 608-618 | $resultsQuery with date range when provided |
| 2 | Verify whereBetween on created_at | Date applied to ExamResult query |
| 3 | Test with both dates | Results within range only |
| 4 | Test without dates | All results returned |

---

#### TC-CR12: Controller — Metrics Calculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 663-669 | $metrics array with 5 keys |
| 2 | total_students from unique student_ids | Correct deduplication |
| 3 | total_papers from count($rows) | Papers with results only |
| 4 | best_performing from sortByDesc('avg_pct') | First item's subject name |

---

#### TC-CR13: Controller — Chart Series Building

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 671-687 | Two chart structures: benchmarking and banding |
| 2 | Benchmarking series: avgSeries and passSeries | Two data arrays |
| 3 | Banding series: bandingHigh/Mid/Low | Three data arrays |
| 4 | Labels from $labels array | Subject names as categories |

---

#### TC-CR14: View — Forelse Empty State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade line 133 | @forelse($examSubjectComparisonData['rows'] as $i => $row) |
| 2 | Verify @empty block | Icon + message: "Generate report to visualize cross-subject success metrics." |

---

#### TC-CR15: View — Pass/Fail Badge Styling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade lines 143-145 | Two badges: pass (green), fail (red), separated by slash |
| 2 | Pass badge CSS | bg-success-subtle text-success |
| 3 | Fail badge CSS | bg-danger-subtle text-danger |

---

#### TC-CR16: View — Progress Bar Width Calculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade line 150 | style="width: {{ $row['pass_rate'] }}%" |
| 2 | Test pass_rate = 85% | Width = 85% |
| 3 | Test pass_rate = 0% | Width = 0% (minimal bar) |

---

#### TC-CR17: JS — Chart Renders After 500ms Delay

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect JS line 219 | setTimeout with 500ms delay |
| 2 | Verify try/catch | Chart errors caught and logged |

---

#### TC-CR18: Controller — Rounding Behavior

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect round() calls | round($value, 1) used consistently |
| 2 | Test avg_pct = 72.55 | Rounds to 72.6 |
| 3 | Test pass_rate = 80.44 | Rounds to 80.4 |

---

## End of TC List
