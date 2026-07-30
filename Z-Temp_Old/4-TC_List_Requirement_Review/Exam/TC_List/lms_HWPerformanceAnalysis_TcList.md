# lms_HWPerformanceAnalysis_TcList

## Module: LmsExam → Advanced Reports → HW Performance Analysis

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Advanced Reports |
| Feature | HW Performance Analysis |
| URL(s) | `/lms-exam/exam-advanced-reports?active_tab=hw-performance-analysis` (index) |
| Controller | `Modules\LmsExam\Http\Controllers\ExamAdvancedReportController@index()` |
| Method (Data) | `generateHwPerformanceData()` (private, line 248) |
| Model(s) | `Modules\LmsHomework\Models\Homework`, `Modules\LmsHomework\Models\HomeworkAssignment`, `Modules\LmsHomework\Models\HomeworkSubmission`, `Modules\StudentProfile\Models\StudentAcademicSession`, `Modules\StudentProfile\Models\Student` |
| View (Partial) | `advanced-reports/partials/hw-performance-analysis.blade.php` |
| Permissions | `tenant.lms-exam-report.viewAny` |
| Pagination | None (flat matrix) |
| Chart Libraries | ApexCharts (area, bar) |
| Date Range Library | daterangepicker (moment.js) |

---

## 2. Pre-conditions

- Required permission: `tenant.lms-exam-report.viewAny`
- Required seed data: At least one active `Homework` with `HomeworkAssignment` and `HomeworkSubmission` records across multiple classes/sections/subjects
- Test user must have the above permission (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- At least one `StudentAcademicSession` with `is_current=1` must exist for student lookup
- Homeworks must have `max_marks > 0` for percentage calculation
- For matrix rendering: at least 2+ homeworks and 2+ students required to display a full matrix
- Gradable filter requires `is_gradable` column to be set on homework records

---

## 3. Default Data Load

When the page loads via `ExamAdvancedReportController@index()` (GET /lms-exam/exam-advanced-reports with `active_tab=hw-performance-analysis`), the following data is fetched:

| Widget/Chart | Data Source | Query Logic | Filters |
|-------------|-------------|-------------|---------|
| Shared: Class Dropdown | `SchoolClass::where('is_active', 1)->orderBy('name')` | All active classes | is_active=1 |
| Shared: Section Dropdown | `Section::where('is_active', 1)->whereHas('classSections', ...)` | Sections for selected class_id | class_id, is_active=1 |
| Shared: Subject Dropdown | `Subject::active()->whereHas('subjectStudyFormats.classGroups', ...)` | Subjects for selected class_id | class_id |
| Shared: Lesson Dropdown | `Lesson::active()->where('subject_id', ...)` | Lessons for selected subject_id | subject_id |
| Shared: Topic Dropdown | `Topic::active()->whereLevel(0)->where('lesson_id', ...)` | Topics for selected lesson_id | lesson_id |
| Shared: Exam Dropdown | `Exam::withTrashed()->where('is_active', true)->orderBy('start_date', 'desc')` | All active exams | is_active=true |
| Shared: Student Dropdown | `Student::where('is_active', 1)->whereHas('studentAcademicSessions.classSection', ...)` | Students for selected class | class_id, is_active=1 |
| Shared: Teacher Dropdown | `User::whereHas('teacher')->orderBy('name')` | All teachers | — |
| **Metrics Cards** | `generateHwPerformanceData()` → `$metrics` | Homework query with aggregations | class_id, section_id, subject_id, lesson_id, topic_id, gradable, date_from, date_to |
| **Class Performance Timeline Chart** | `generateHwPerformanceData()` → `$charts['performance']` | HW averages per homework (area chart) | Same filters |
| **Scoring Distribution Chart** | `generateHwPerformanceData()` → `$charts['distribution']` | Student count per performance bracket (bar chart) | Same filters |
| **Performance Matrix** | `generateHwPerformanceData()` → `$matrix` | Student×Homework percentage matrix | Same filters |
| **HW Averages Footer** | `generateHwPerformanceData()` → `$hw_averages` | Class average per homework | Same filters |

---

## 4. Test Data Strategy

- **Core dataset**: Seed 5-10 `Homework` records across 2-3 classes with varying `max_marks` (10, 20, 50, 100)
- **Student dataset**: Seed 10-15 `Student` records with `StudentAcademicSession` (is_current=1) across 2 classes with sections
- **Submissions**: For each (student × homework) pair, create a `HomeworkSubmission` with:
  - Mix of on-time and late submissions (`is_late` = true/false)
  - Mix of graded and ungraded (`marks_obtained` = some values / null)
  - Mix of resubmission requested (`is_resubmission_requested` = true/false)
- **Performance brackets**: Ensure submissions span all 5 brackets: <35%, 35-49%, 50-69%, 70-84%, 85%+
- **Gradable filter**: Seed some homework with `is_gradable=true` and some with `is_gradable=false`
- **Empty state**: Class/subject combination with zero homeworks or zero student submissions
- **Date range**: Ensure homeworks span at least 60 days for date range testing
- **Partial data**: Some students with mixed submission status (some HW submitted, some not)
- **Pre-test cleanup**: Delete created homework/submission/student records before/after tests

---

## 5. Business Conditions

### 4.1 Database Schema

#### `lms_homeworks` (LmsHomework module)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | class_id | INT UNSIGNED | NOT NULL, FK → `sch_classes.id` |
| BC-DB-03 | section_id | INT UNSIGNED | NULLABLE, FK → `sch_sections.id` |
| BC-DB-04 | subject_id | INT UNSIGNED | NOT NULL, FK → `sch_subjects.id` |
| BC-DB-05 | lesson_id | INT UNSIGNED | NULLABLE, FK → `slb_lessons.id` |
| BC-DB-06 | topic_id | INT UNSIGNED | NULLABLE, FK → `slb_topics.id` |
| BC-DB-07 | title | VARCHAR(255) | NOT NULL |
| BC-DB-08 | description | TEXT | NULLABLE |
| BC-DB-09 | assign_date | DATE | NOT NULL |
| BC-DB-10 | due_date | DATE | NOT NULL |
| BC-DB-11 | max_marks | DECIMAL(8,2) | NOT NULL DEFAULT 0 |
| BC-DB-12 | is_gradable | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-13 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-14 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-15 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

#### `lms_homework_assignments` (LmsHomework module)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-16 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-17 | homework_id | INT UNSIGNED | NOT NULL, FK → `lms_homeworks.id` |
| BC-DB-18 | student_id | INT UNSIGNED | NOT NULL, FK → `std_students.id` |
| BC-DB-19 | is_active | TINYINT(1) | DEFAULT 1 |
| BC-DB-20 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

#### `lms_homework_submissions` (LmsHomework module)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-21 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-22 | homework_id | INT UNSIGNED | NOT NULL, FK → `lms_homeworks.id` |
| BC-DB-23 | student_id | INT UNSIGNED | NOT NULL, FK → `std_students.id` |
| BC-DB-24 | marks_obtained | DECIMAL(8,2) | NULLABLE |
| BC-DB-25 | is_late | TINYINT(1) | DEFAULT 0 |
| BC-DB-26 | is_resubmission_requested | TINYINT(1) | DEFAULT 0 |
| BC-DB-27 | teacher_feedback | TEXT | NULLABLE |
| BC-DB-28 | submitted_at | DATETIME | NULLABLE |
| BC-DB-29 | is_active | TINYINT(1) | DEFAULT 1 |
| BC-DB-30 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-31 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

#### `std_student_academic_sessions` (StudentProfile module)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-32 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-33 | student_id | INT UNSIGNED | NOT NULL, FK → `std_students.id` |
| BC-DB-34 | class_section_id | INT UNSIGNED | NOT NULL, FK → `sch_class_sections.id` |
| BC-DB-35 | roll_no | VARCHAR(20) | NULLABLE |
| BC-DB-36 | is_current | TINYINT(1) | DEFAULT 0 |
| BC-DB-37 | is_active | TINYINT(1) | DEFAULT 1 |
| BC-DB-38 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-39 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

### 4.2 Filter/Input Validation

| BC ID | Filter Field | Type | Validation Logic | Default |
|-------|-------------|------|------------------|---------|
| BC-VAL-01 | class_id | INT | NULLABLE; must exist in sch_classes | null (all classes) |
| BC-VAL-02 | section_id | INT | NULLABLE; must exist in sch_sections | null (all sections) |
| BC-VAL-03 | subject_id | INT | NULLABLE; must exist in sch_subjects | null (all subjects) |
| BC-VAL-04 | lesson_id | INT | NULLABLE; must exist in slb_lessons | null (all lessons) |
| BC-VAL-05 | topic_id | INT | NULLABLE; must exist in slb_topics | null (all topics) |
| BC-VAL-06 | gradable | STRING | NULLABLE; allowed: 'Yes', 'No', 'Both' | 'Both' |
| BC-VAL-07 | date_from | DATE | NULLABLE; parsed via Carbon::parse() | now()->subDays(30) |
| BC-VAL-08 | date_to | DATE | NULLABLE; parsed via Carbon::parse() | now() |
| BC-VAL-09 | active_tab | STRING | Hidden; always 'hw-performance-analysis' | 'hw-performance-analysis' |

### 4.3 Authorization

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.lms-exam-report.viewAny | index() | Without → 403 Forbidden |
| BC-AUTH-02 | Guest access | Any reports route | Redirect to /login |

### 4.4 Business Logic (calculation formulas, aggregation logic)

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Performance Matrix Build | Each student×homework cell shows percentage: `(marks_obtained / max_marks) × 100` |
| BC-BIZ-02 | NS (Not Submitted) Handling | When no submission exists, cell shows 'NS' and is excluded from averages |
| BC-BIZ-03 | Student Aggregate % | `(sum of marks_obtained / sum of max_marks) × 100` across all homeworks for that student |
| BC-BIZ-04 | Color Coding Per Cell | <35% red, 35-49% orange, 50-69% yellow, 70-84% light green, 85%+ dark green |
| BC-BIZ-05 | Grade Assignment | 90%+ A+, 80-89% A, 70-79% B+, 60-69% B, 50-59% C+, 40-49% C, 33-39% D, <33% F |
| BC-BIZ-06 | Class Average Metric | `average of all student percentages` across all submissions |
| BC-BIZ-07 | Avg Completion Rate | `(total submissions / total possible assignments) × 100` |
| BC-BIZ-08 | High Performers Count | Count of students with any cell >= 90% |
| BC-BIZ-09 | HW Average Per Column | `average percentage for that homework across all students who submitted` |
| BC-BIZ-10 | Late Submission Markers | Cells with `is_late=true` show a red dot indicator |
| BC-BIZ-11 | Empty Matrix State | When no data: metrics show 0, charts show empty, table shows "Select Class and Subject to generate the performance matrix" |
| BC-BIZ-12 | Section Null Handling | When section_id filter is set: `WHERE section_id = ? OR section_id IS NULL` |
| BC-BIZ-13 | Gradable Filter Logic | `gradable=Yes` → `WHERE is_gradable = true`; `gradable=No` → `WHERE is_gradable = false`; `Both` → no filter |
| BC-BIZ-14 | Score Distribution Bands | Struggling (<35%), Attention (35-49%), Satisfactory (50-69%), Good (70-84%), Outstanding (85%+) |
| BC-BIZ-15 | Class Performance Timeline | X-axis: homework titles with dates, Y-axis: average percentage per homework |
| BC-BIZ-16 | Student Unique Filter | `$students->unique('student_id')` removes duplicate student entries from cross-section scenarios |
| BC-BIZ-17 | Empty Student Collection | If no students match the class/section filter, return empty matrix with zero metrics |
| BC-BIZ-18 | Empty Homework Collection | If no homeworks match filters, return empty matrix with zero metrics |
| BC-BIZ-19 | Aggregate Score Calculation | `total_obt` and `total_max` accumulate across all cells per student for overall % |
| BC-BIZ-20 | Sticky Header/Footer | Matrix table has sticky headers (thead) and sticky footer (tfoot) for scrolling |

### 4.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | homework.class_id | sch_classes.id | CASCADE |
| BC-REF-02 | homework.section_id | sch_sections.id | SET NULL |
| BC-REF-03 | homework.subject_id | sch_subjects.id | CASCADE |
| BC-REF-04 | homework.lesson_id | slb_lessons.id | SET NULL |
| BC-REF-05 | homework.topic_id | slb_topics.id | SET NULL |
| BC-REF-06 | assignment.homework_id | lms_homeworks.id | CASCADE |
| BC-REF-07 | assignment.student_id | std_students.id | CASCADE |
| BC-REF-08 | submission.homework_id | lms_homeworks.id | CASCADE |
| BC-REF-09 | submission.student_id | std_students.id | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Performance Analysis page loads with all UI elements | Page loads with filter bar, 4 metric cards, 2 charts, and performance matrix table | — | — | ⬜ |
| TC-P02 | Matrix displays correct columns (homeworks) and rows (students) | Each homework becomes a column, each student becomes a row with % cells | — | — | ⬜ |
| TC-P03 | Cell percentage calculation correct for submitted homework | Cell shows `(marks_obtained / max_marks) × 100` with correct color code | — | — | ⬜ |
| TC-P04 | Non-submitted homework shows 'NS' in cell | Student without submission shows 'NS'; excluded from averages | — | — | ⬜ |
| TC-P05 | Student aggregate percentage computed correctly | Last column shows `(total_obt / total_max) × 100` with grade badge | — | — | ⬜ |
| TC-P06 | Color coding applied per bracket | <35% red bg, 35-49% orange, 50-69% yellow, 70-84% light green, 85%+ dark green | — | — | ⬜ |
| TC-P07 | Grade badge displayed per student | A+ (90%+), A (80-89%), B+ (70-79%), B (60-69%), C+ (50-59%), C (40-49%), D (33-39%), F (<33%) | — | — | ⬜ |
| TC-P08 | Class average footer row shows per-HW averages | Footer displays average % per homework and overall class average | — | — | ⬜ |
| TC-P09 | Filter by class_id scopes data to that class | Selecting a class shows only that class's homeworks and students | — | — | ⬜ |
| TC-P10 | Filter by section scopes data | Selecting a section narrows to that section's homeworks/students | — | — | ⬜ |
| TC-P11 | Filter by subject scopes data | Selecting a subject shows only that subject's homeworks | — | — | ⬜ |
| TC-P12 | Filter by lesson scopes data | Selecting a lesson narrows to that lesson's homeworks | — | — | ⬜ |
| TC-P13 | Filter by topic scopes data | Selecting a topic narrows to that topic's homeworks | — | — | ⬜ |
| TC-P14 | Filter by gradable = 'Yes' shows only gradable HWs | Only homeworks with `is_gradable=true` appear in matrix | — | — | ⬜ |
| TC-P15 | Filter by gradable = 'No' shows only non-gradable HWs | Only homeworks with `is_gradable=false` appear in matrix | — | — | ⬜ |
| TC-P16 | Filter by date range scopes homeworks | Homeworks with assign_date within range appear; outside excluded | — | — | ⬜ |
| TC-P17 | Combined filters (class + subject + lesson + date range) | All filters combined correctly scope to precise subset | — | — | ⬜ |
| TC-P18 | Class Performance Timeline chart renders correctly | Area chart shows average % per homework as line with gradient fill | — | — | ⬜ |
| TC-P19 | Scoring Distribution chart renders correctly | Bar chart shows student count in 5 brackets with correct colors | — | — | ⬜ |
| TC-P20 | Metrics cards show correct values | Assignments Audited, Avg Completion Rate, Avg Score Marks, Top Bracket (90%+) | — | — | ⬜ |
| TC-P21 | Late submission indicator shown as red dot | Cells with `is_late=true` show red circle badge | — | — | ⬜ |
| TC-P22 | Section null handling: HW with section=NULL included | When section filter active, homeworks with NULL section still appear | — | — | ⬜ |
| TC-P23 | Large dataset (30+ students, 20+ homeworks) renders correctly | Matrix scrollable within 600px max-height; all data visible | — | — | ⬜ |
| TC-P24 | Reset button clears all filters | Clicking reset returns to default state with all data | — | — | ⬜ |
| TC-P25 | Date range presets work correctly | Last 7 Days, Last 30 Days, This Month, Last Month all apply correct dates | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Permission 403 — No viewAny permission | User without `tenant.lms-exam-report.viewAny` gets 403 Forbidden | — | — | ⬜ |
| TC-N02 | Guest access redirect | Unauthenticated user redirected to /login | — | — | ⬜ |
| TC-N03 | Empty state — no homeworks match filters | Matrix shows empty state message "Select Class and Subject to generate the performance matrix" | — | — | ⬜ |
| TC-N04 | Empty state — no students in selected class | Metrics show 0, charts empty, matrix shows empty message | — | — | ⬜ |
| TC-N05 | All homeworks have max_marks = 0 | Division by zero avoided; cells show 0% or 'N/A', no 500 error | — | — | ⬜ |
| TC-N06 | No class selected, no data | Empty state shown; user prompted to select class | — | — | ⬜ |
| TC-N07 | Invalid class_id parameter | Passing `?class_id=99999` shows empty state; no 500 error | — | — | ⬜ |
| TC-N08 | Invalid date format | Non-parseable date string → defaults to last 30 days; no 500 error | — | — | ⬜ |
| TC-N09 | Malformed gradable parameter | Passing `?gradable=Invalid` defaults to 'Both'; no 500 error | — | — | ⬜ |
| TC-N10 | Section-only filter without class_id | Section filter does nothing when no class selected (no sections loaded) | — | — | ⬜ |
| TC-N11 | Students exist but no submissions for any homework | Matrix shows all cells as 'NS'; aggregate 0%; no 500 error | — | — | ⬜ |
| TC-N12 | All submissions ungraded (marks_obtained = null) | Cells show 'NS' (not submitted/ungraded); averages exclude nulls | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Creating a new homework assignment adds column to matrix | New HW appears as new column after page refresh | — | — | ⬜ |
| TC-D02 | B | Grading a submission updates cell value | Submitting marks updates cell % and color | — | — | ⬜ |
| TC-D03 | C | Deleting a homework removes its column from matrix | HW column disappears; totals recalculated | — | — | ⬜ |
| TC-D04 | D | Adding new student to class adds row to matrix | New student appears as new row with 'NS' cells | — | — | ⬜ |
| TC-D05 | E | Changing student's class moves them to different class scope | Student no longer appears under old class filter | — | — | ⬜ |
| TC-D06 | F | Large dataset (100+ students × 50+ HWs) performance | Matrix renders in reasonable time; no browser crash | — | — | ⬜ |
| TC-D07 | G | Cross-module: Homework from LmsHomework module reflected | Homeworks created in LmsHomework appear in this report | — | — | ⬜ |
| TC-D08 | H | Submission marks from teacher grading reflected in matrix | Marks entered via grading interface update the matrix cells | — | — | ⬜ |
| TC-D09 | I | Late flag set on submission shows red dot indicator | Setting `is_late=true` on submission shows red dot in matrix cell | — | — | ⬜ |
| TC-D10 | J | Uniqueness: student with multiple academic sessions deduplicated | `$students->unique('student_id')` ensures one row per student | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based tab visibility via viewAny | Tab wrapped by @can('tenant.lms-exam-report.viewAny'); users without permission cannot see this tab | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — `generateHwPerformanceData()` private method exists at line 248 | Method defined, returns array with matrix, homeworks, metrics, charts, hw_averages | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | View — null-safe checks on HW relations ($hw->subject?->name, optional()) | All relationship accesses use ?-> or optional(); no undefined index errors when relation is null | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | JS — ApexCharts initialization with 500ms delay | Charts render after DOM stable; try/catch prevents errors from breaking page | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | JS — Date range picker hidden inputs sync correctly | daterangepicker apply/cancel events properly set/clear hidden date_from/date_to fields | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | JS — AJAX cascading dropdowns properly load dependencies | Class→sections+subjects, Subject→lessons, Lesson→topics cascade via getDependencies() endpoint | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Color mapping logic for performance cells | Colors mapped correctly: <35% red (#fecaca), 35-49% orange (#fed7aa), 50-69% yellow (#fef08a), 70-84% light green (#d9f99d), 85%+ dark green (#a7f3d0) | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | Grade calculation in `getGrade()` private method | Method returns correct letter grade for each percentage threshold; test boundary values 90, 80, 70, 60, 50, 40, 33, 32 | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | `parseDateRange()` handles exceptions gracefully | Invalid dates caught by try/catch; falls back to last 30 days | — | — | ◌ |
| TC-CR10 | CR | Code Review | P1 | Sticky header/footer CSS for matrix scrolling | thead has `sticky-top` class, tfoot has custom `sticky-bottom`; matrix container has `max-height: 600px` | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Blade @can Directives — Permission-based Tab Visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect advanced-reports/index.blade.php | Tab is wrapped by @can('tenant.lms-exam-report.viewAny') |
| 2 | Check nav-tab component permission attribute | Tab's permission = 'tenant.lms-exam-report.viewAny' |
| 3 | Login as user with viewAny permission | HW Performance Analysis tab visible |
| 4 | Login as user without viewAny permission | HW Performance Analysis tab hidden; 403 on direct URL access |

---

#### TC-CR02: Controller — `generateHwPerformanceData()` Private Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamAdvancedReportController.php | Controller file found |
| 2 | Locate generateHwPerformanceData() at line 248 | Method exists with Request parameter |
| 3 | Verify return structure | Returns array with 'matrix', 'homeworks', 'metrics', 'charts', 'hw_averages' keys |
| 4 | Check empty handling | Returns zeroed structure when homeworks or students are empty |
| 5 | Check student unique filter | Uses `$students->unique('student_id')` to deduplicate |

---

#### TC-CR03: View — null-safe Checks on HW Relations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open hw-performance-analysis.blade.php | View file found in partials/ |
| 2 | Scan for relationship access (e.g. $hw->subject?->name) | All expressions use ?-> or optional() |
| 3 | Scan for foreach over $hwPerformanceData['homeworks'] | Loop target checked with !empty() before iterating |
| 4 | Load report with records that have missing relations | No 500 errors; null values display dash or '—' |
| 5 | Verify `$hwPerformanceData['homeworks']` has title fallback | Uses `$hw->title ?? '—'` for display |

---

#### TC-CR04: JS — ApexCharts Initialization with Delay

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect JS in hw-performance-analysis.blade.php | setTimeout with 500ms delay before chart render |
| 2 | Check performance timeline chart config | Chart type 'area', smooth curve, gradient fill, y-axis max 100 |
| 3 | Check scoring distribution chart config | Chart type 'bar', distributed colors, 5 categories |
| 4 | Verify try/catch wrapping | Chart init wrapped in try/catch; errors logged to console only |
| 5 | Check chart container IDs | #hwPerformanceTimelineChart and #hwScoreDistributionChart |

---

#### TC-CR05: JS — Date Range Picker Hidden Inputs Sync

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect daterangepicker initialization | Picker bound to #hw_perf_daterange input |
| 2 | Verify apply event handler | apply sets #hw_perf_df with YYYY-MM-DD and #hw_perf_dt with end date |
| 3 | Verify cancel/clear event handler | cancel clears both hidden inputs and display input |
| 4 | Verify existing dates pre-populated | If $_GET date_from/date_to exist, display shows formatted range |
| 5 | Verify presets configured | Last 7 Days, Last 30 Days, This Month, Last Month ranges present |

---

#### TC-CR06: JS — AJAX Cascading Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect class change handler | On #filter_hwp_class change, AJAX to filter-dependencies endpoint |
| 2 | Verify sections/subjects populated | Response sections populate #filter_hwp_section; subjects populate #filter_hwp_subject |
| 3 | Inspect subject change handler | On #filter_hwp_subject change, lessons loaded via type='lessons' |
| 4 | Inspect lesson change handler | On #filter_hwp_lesson change, topics loaded via type='topics' |
| 5 | Verify setLoader/updateOptions helpers | Functions properly disable during load and re-enable after data received |

---

#### TC-CR07: Color Mapping Logic for Performance Cells

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade color logic at line 178-185 | if/else chain maps pct < 35 → red, pct < 50 → orange, etc. |
| 2 | Test with pct = 34 | Background = #fecaca (red), text = #991b1b |
| 3 | Test with pct = 35 | Background = #fed7aa (orange), text = #9a3412 |
| 4 | Test with pct = 50 | Background = #fef08a (yellow), text = #854d0e |
| 5 | Test with pct = 70 | Background = #d9f99d (light green), text = #3f6212 |
| 6 | Test with pct = 85 | Background = #a7f3d0 (dark green), text = #065f46 |
| 7 | Test with pct = null | Background = transparent, text = #334155 (NS) |

---

#### TC-CR08: Grade Calculation in `getGrade()` Private Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller and locate getGrade() at line 782 | Method returns letter grade based on percentage |
| 2 | Test boundary: pct = 90 | Returns 'A+' |
| 3 | Test boundary: pct = 80 | Returns 'A' |
| 4 | Test boundary: pct = 70 | Returns 'B+' |
| 5 | Test boundary: pct = 60 | Returns 'B' |
| 6 | Test boundary: pct = 50 | Returns 'C+' |
| 7 | Test boundary: pct = 40 | Returns 'C' |
| 8 | Test boundary: pct = 33 | Returns 'D' |
| 9 | Test boundary: pct = 32 | Returns 'F' |
| 10 | Test null input | Returns '—' |

---

#### TC-CR09: `parseDateRange()` Exception Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect parseDateRange() at line 136 | Method wraps Carbon::parse in try/catch |
| 2 | Pass valid dates '2026-01-01' and '2026-01-31' | Returns [startOfDay, endOfDay] |
| 3 | Pass invalid date 'not-a-date' | Catches exception and falls back to [now()->subDays(30), now()] |
| 4 | Verify date range with date_from only | Method requires both date_from AND date_to; if one missing, no date filter applied |
| 5 | Verify time boundary inclusive | startDate uses startOfDay(); endDate uses endOfDay() |

---

#### TC-CR10: Sticky Header/Footer CSS for Matrix Scrolling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect matrix table structure at line 154 | Container div has `max-height: 600px` with `overflow-y: auto` |
| 2 | Verify thead has sticky-top class | thead element has `sticky-top` Bootstrap class for vertical scrolling |
| 3 | Verify first two th have sticky left positioning | # column and Student Name column have `position: sticky; left: 0/40px; z-index: 11` |
| 4 | Verify tfoot has sticky-bottom styling | tfoot row has `sticky-bottom` class via custom style |
| 5 | Scroll vertically in matrix | Header stays fixed at top, footer stays fixed at bottom |
| 6 | Scroll horizontally | # and Name columns stay fixed on left |

---

### 6.1 Positive TC Steps

#### TC-P01: Performance Analysis Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Navigate to LmsExam → Advanced Reports | Page loads at /lms-exam/exam-advanced-reports |
| 3 | Click 'HW Performance Analysis' tab | Tab pane shown with active_tab=hw-performance-analysis |
| 4 | Check filter bar | 7 filter controls: Class, Section, Subject, Performance Horizon, Lesson, Topic, Format |
| 5 | Check metric cards | 4 cards: Assignments Audited, Avg Completion Rate, Avg Score Marks, Top Bracket (90%+) |
| 6 | Check charts | 2 chart containers: Class Performance Timeline and Scoring Distribution |
| 7 | Check performance matrix | Excel-style table with student rows and homework columns |

---

#### TC-P02: Matrix Displays Correct Columns and Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 3 homeworks (HW-A, HW-B, HW-C) with 5 students (S1-S5) | Dataset ready |
| 2 | Navigate to performance analysis with appropriate filters | Matrix loads |
| 3 | Check column headers | Each homework title shown with date and max_marks badge |
| 4 | Check row labels | 5 student names listed in first column |
| 5 | Verify row count = 5 | All 5 students appear |

---

#### TC-P03: Cell Percentage Calculation Correct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Student A, HW-1 with max_marks=50, marks_obtained=35 | 70% expected |
| 2 | Navigate to performance analysis | Cell for Student A × HW-1 shows "70%" |
| 3 | Verify color coding | Green (70-84% bracket) |
| 4 | Verify label format | "70%" exactly |

---

#### TC-P04: Non-Submitted Homework Shows 'NS'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Student B has no submission for HW-2 | No submission record |
| 2 | Navigate to performance analysis | Cell for Student B × HW-2 shows "NS" |
| 3 | Verify background | Transparent (no color fill) |

---

#### TC-P05: Student Aggregate Percentage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Student X: HW-1 (30/50 = 60%), HW-2 (40/50 = 80%), HW-3 (NS) | Expected agg: (30+40)/(50+50) = 70% |
| 2 | Navigate to performance analysis | Agg. % column shows "70%" |
| 3 | Verify grade badge shows "B+" | Correct grade for 70% |

---

#### TC-P06: Color Coding Per Bracket

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed submissions: 20% (<35), 40% (35-49), 60% (50-69), 75% (70-84), 90% (85+) | 5 cells |
| 2 | Navigate to performance analysis | 20% → red, 40% → orange, 60% → yellow, 75% → light green, 90% → dark green |
| 3 | Verify boundary at 34.9% vs 35% | 34.9% red, 35% orange |

---

#### TC-P07: Grade Badge Per Student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed students with different aggregate %s | Range of grades |
| 2 | Navigate to performance analysis | Each student row has grade badge in last column |
| 3 | Verify grade = 'A+' for 95% | Badge shows "A+" |

---

#### TC-P08: Class Average Footer Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 3 homeworks with class averages | Footer expected |
| 2 | Navigate to performance analysis | Footer row shows average % per homework column |
| 3 | Verify last footer cell = overall class average | Primary colored cell with class_avg % |

---

#### TC-P09: Filter By Class Scopes Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class A (3 HWs, 5 students), Class B (2 HWs, 3 students) | Two classes |
| 2 | Select Class A | Only Class A homeworks and students visible |
| 3 | Select Class B | Only Class B data visible |
| 4 | Select no class (all) | Both classes' data visible |

---

#### TC-P10: Filter By Section Scopes Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Section A (5 students), Section B (3 students) in same class | Two sections |
| 2 | Select class then Section A | Only Section A students and their HWs visible |
| 3 | Clear section, select Section B | Only Section B data visible |

---

#### TC-P11: Filter By Subject Scopes Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Math (3 HWs), Science (2 HWs) | Two subjects |
| 2 | Select subject = Math | Only Math homeworks in matrix columns |
| 3 | Select subject = Science | Only Science homeworks in columns |

---

#### TC-P12: Filter By Lesson Scopes Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Lesson 1 (2 HWs), Lesson 2 (3 HWs) within same subject | Two lessons |
| 2 | Select subject then Lesson 1 | Only Lesson 1 HWs shown |
| 3 | Clear lesson, select Lesson 2 | Only Lesson 2 HWs shown |

---

#### TC-P13: Filter By Topic Scopes Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Topic A (2 HWs), Topic B (1 HW) within same lesson | Two topics |
| 2 | Select lesson then Topic A | Only Topic A HWs shown |
| 3 | Clear topic, select Topic B | Only Topic B HWs shown |

---

#### TC-P14: Gradable = 'Yes' Shows Only Gradable HWs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 2 gradable HWs, 2 non-gradable HWs | Mixed set |
| 2 | Select Format = 'Gradable Only' | Only 2 gradable HWs appear in matrix |
| 3 | Verify non-gradable HWs excluded | Not in column headers |

---

#### TC-P15: Gradable = 'No' Shows Only Non-Gradable HWs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 2 gradable HWs, 2 non-gradable HWs | Mixed set |
| 2 | Select Format = 'Non-Gradable' | Only 2 non-gradable HWs appear |
| 3 | Verify gradable HWs excluded | Not visible |

---

#### TC-P16: Filter By Date Range Scopes Homeworks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: HW-A (assign_date=Jan 5), HW-B (Feb 10), HW-C (Mar 15) | Three dates |
| 2 | Set date range: Jan 1 - Jan 31 | Only HW-A visible |
| 3 | Set date range: Feb 1 - Feb 28 | Only HW-B visible |
| 4 | Set date range: Jan 1 - Mar 31 | All 3 HWs visible |
| 5 | Verify boundary inclusive | HWs on start/end dates included |

---

#### TC-P17: Combined Filters Scoping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class A / Math / Lesson 1 / Jan HWs (3), Class A / Math / Lesson 2 / Jan HWs (2), Class A / Science / Jan HWs (2) | Multi-dimension |
| 2 | Select Class A + Math + Lesson 1 + Jan range | 3 HWs visible |
| 3 | Select Class A + Math + Lesson 2 + Jan range | 2 HWs visible |
| 4 | Select Class A + Science + Jan range | 2 HWs visible |

---

#### TC-P18: Class Performance Timeline Chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 5 homeworks with different averages | Chart data |
| 2 | Navigate to performance analysis | Area chart renders in #hwPerformanceTimelineChart |
| 3 | Verify X-axis labels | Homework titles with dates |
| 4 | Verify Y-axis max = 100 | Scale 0-100% |
| 5 | Verify gradient fill | Smooth gradient from color to transparent |
| 6 | Hover over data point | Tooltip shows percentage value |

---

#### TC-P19: Scoring Distribution Chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed submissions across all 5 brackets | Distribution data |
| 2 | Navigate to performance analysis | Bar chart renders in #hwScoreDistributionChart |
| 3 | Verify 5 bars | Struggling (red), Attention (orange), Satisfactory (yellow), Good (green), Outstanding (purple) |
| 4 | Verify bar heights match actual counts | Data labels on top of each bar |

---

#### TC-P20: Metrics Cards Show Correct Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 3 HWs, 10 students, 25 submissions | Metrics calculable |
| 2 | Navigate to performance analysis | Card 1 shows total_hw count |
| 3 | Card 2 shows avg_completion% | Correct completion rate |
| 4 | Card 3 shows avg_score% | Correct average score |
| 5 | Card 4 shows high_performers count | Students with any cell >= 90% |

---

#### TC-P21: Late Submission Red Dot Indicator

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Student X submitted HW-1 late (is_late=true) | Late flag set |
| 2 | Navigate to performance analysis | Cell for X × HW-1 shows red dot badge |
| 3 | Verify dot CSS | Badge with bg-danger, rounded-circle, 5px |

---

#### TC-P22: Section Null Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: HW-A with section_id=NULL, HW-B with section_id=1 | Mix of null and assigned |
| 2 | Select Section A (id=1) | Both HW-A and HW-B appear (HW-A included via OR section_id IS NULL) |
| 3 | Verify both HWs visible | Section null logic correct |

---

#### TC-P23: Large Dataset Rendering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 30+ students, 20+ homeworks with submissions | Large dataset |
| 2 | Navigate to performance analysis | Matrix renders without browser lag |
| 3 | Scroll vertically | Header sticky, footer sticky |
| 4 | Scroll horizontally | # and Name columns fixed |
| 5 | Verify all 600+ cells visible | Complete matrix rendered |

---

#### TC-P24: Reset Button Clears Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply various filters, submit | Filtered data shown |
| 2 | Click reset button (rotate-right icon) | URL resets to ?active_tab=hw-performance-analysis |
| 3 | Verify all filter dropdowns default | All selects show placeholder/empty |

---

#### TC-P25: Date Range Presets Work

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open date range picker | Presets visible: Last 7 Days, Last 30 Days, This Month, Last Month |
| 2 | Click 'Last 7 Days' | date_from = 7 days ago, date_to = today |
| 3 | Click 'Last 30 Days' | date_from = 30 days ago |
| 4 | Click 'This Month' | date_from = month start, date_to = month end |
| 5 | Click 'Last Month' | Previous month range |

---

### 6.2 Negative TC Steps

#### TC-N01: Permission 403 — No viewAny Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without tenant.lms-exam-report.viewAny | Dashboard loads |
| 2 | Navigate to /lms-exam/exam-advanced-reports?active_tab=hw-performance-analysis | 403 Forbidden |
| 3 | Verify tab hidden from UI | HW Performance Analysis tab not shown |

---

#### TC-N02: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout | Redirected to login |
| 2 | Navigate to report URL | Redirected to /login |

---

#### TC-N03: Empty State — No Homeworks Match

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed class with no homeworks | No data |
| 2 | Select that class | Empty state shown |
| 3 | Verify message | "Select Class and Subject to generate the performance matrix." |
| 4 | Verify metrics show 0 | All cards show 0 |

---

#### TC-N04: Empty State — No Students in Selected Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class with homeworks but no students | Students empty |
| 2 | Verify matrix empty | Empty state message shown |
| 3 | Verify metrics zeroed | All metrics = 0 |

---

#### TC-N05: All max_marks = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed homework with max_marks = 0 | Edge case |
| 2 | Navigate to performance analysis | No 500 error |
| 3 | Verify cell shows 0% or 'N/A' | Graceful handling |

---

#### TC-N06: No Class Selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Clear all filters, submit with no class | All data across classes shown |
| 2 | If no global data, empty state | Appropriate message displayed |

---

#### TC-N07: Invalid class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate with ?class_id=99999 | No 500 error |
| 2 | Empty matrix displayed | Empty state message |

---

#### TC-N08: Invalid Date Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate with ?date_from=invalid | parseDateRange catches exception |
| 2 | Defaults to last 30 days | Date filter applied with default range |
| 3 | No 500 error | Graceful handling |

---

#### TC-N09: Malformed Gradable Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set ?gradable=InvalidValue | Defaults to 'Both' (all units) |
| 2 | All homeworks visible | No gradable filter applied |

---

#### TC-N10: Section Without Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set section_id without class_id | Section dropdown disabled when no class selected |
| 2 | No section filter applied | All sections data shown |

---

#### TC-N11: Students Exist But No Submissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed students with assignments but no submissions | All pending |
| 2 | Navigate to performance analysis | All cells show 'NS' |
| 3 | Aggregate = 0% | No 500 error |

---

#### TC-N12: All Submissions Ungraded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed submissions with marks_obtained = NULL | Ungraded |
| 2 | Navigate to performance analysis | Cells show 'NS' for ungraded |
| 3 | Averages exclude null marks | No division by zero |

---

### 6.3 Dependency TC Steps

#### TC-D01: Creating New Homework Adds Column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note current matrix columns | Current HW count = X |
| 2 | Create new homework in same class/subject | HW created |
| 3 | Refresh performance analysis | New column appears for new HW |
| 4 | Column count = X + 1 | Correct |

---

#### TC-D02: Grading Submission Updates Cell

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note NS cell for Student × HW | Currently shows 'NS' |
| 2 | Submit marks via grading interface | Submission record created |
| 3 | Refresh performance analysis | Cell now shows percentage value with color |

---

#### TC-D03: Deleting Homework Removes Column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note current matrix columns | Current HW count = X |
| 2 | Soft-delete one homework | HW trashed |
| 3 | Refresh performance analysis | Column removed; count = X-1 |

---

#### TC-D04: Adding New Student Adds Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note current student rows | Count = X |
| 2 | Enroll new student in class | Student added |
| 3 | Assign homeworks to new student | Assignments created |
| 4 | Refresh performance analysis | New row appears; count = X+1 |

---

#### TC-D05: Changing Student's Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note student visible in Class A | Student in Class A matrix |
| 2 | Change student's class_section to Class B | Academic session updated |
| 3 | Refresh Class A matrix | Student no longer visible |
| 4 | Switch to Class B | Student now visible in Class B matrix |

---

#### TC-D06: Large Dataset Performance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 100 students × 50 homeworks = 5000 cells | Large dataset |
| 2 | Load performance analysis | Page renders within acceptable time |
| 3 | Scroll matrix | Smooth scrolling, no jank |
| 4 | Verify all 5000 cells rendered | Complete data visible |

---

#### TC-D07: Cross-Module Homework Reflection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework via LmsHomework module | HW created |
| 2 | Navigate to performance analysis (same class/subject) | New HW appears in matrix |
| 3 | Verify data consistency | Same title, max_marks, subject |

---

#### TC-D08: Teacher Grading Reflected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Teacher grades submission with 45/50 | Marks saved |
| 2 | Refresh performance analysis | Cell shows 90% with dark green color |

---

#### TC-D09: Late Flag Shows Red Dot

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set is_late=true on a submission | Late flag set |
| 2 | Refresh performance analysis | Cell shows red dot indicator |
| 3 | Verify dot visible even if score shown | Dot next to percentage |

---

#### TC-D10: Student Deduplication

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed student with 2 academic sessions (same class) | Duplicate entries |
| 2 | Navigate to performance analysis | Student appears once only |
| 3 | Verify unique filter applied | unique('student_id') deduplicates |

---

### 6.4 Code Review TC Steps

#### TC-CR04: JS — ApexCharts Initialization with Delay

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open view file and locate JS section | setTimeout at line 320 with 500ms delay |
| 2 | Verify performance chart config | ApexCharts with type:'area', categories from HW titles, y-axis max 100 |
| 3 | Verify distribution chart config | ApexCharts with type:'bar', distributed colors, 5 categories |
| 4 | Verify try/catch block | Errors caught and logged to console only |
| 5 | Verify chart ID attributes | #hwPerformanceTimelineChart and #hwScoreDistributionChart present in DOM |

---

#### TC-CR05: JS — Date Range Picker Hidden Inputs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect daterangepicker initialization at line 288 | Picker initialized on #hw_perf_daterange |
| 2 | Test apply event | Sets #hw_perf_df with YYYY-MM-DD start date, #hw_perf_dt with end date |
| 3 | Test cancel event | Clears #hw_perf_df, #hw_perf_dt, and display input |
| 4 | Test pre-population | If date_from and date_to exist in query, display shows formatted range |
| 5 | Test preset 'Last 7 Days' | Correct moment calculations for 6 days ago to today |

---

#### TC-CR06: JS — AJAX Cascading Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect class change handler at line 253 | AJAX call to route('lms-exam.exam-advanced-reports.filter-dependencies') with class_id |
| 2 | Verify sections populated | Response res.sections populates #filter_hwp_section dropdown |
| 3 | Verify subjects populated | Response res.subjects populates #filter_hwp_subject dropdown |
| 4 | Inspect subject change at line 267 | AJAX with type:'lessons', id:subjectId → populates #filter_hwp_lesson |
| 5 | Inspect lesson change at line 277 | AJAX with type:'topics', id:lessonId → populates #filter_hwp_topic |
| 6 | Verify setLoader function | Sets loading text and disables dropdown during AJAX |
| 7 | Verify updateOptions function | Clears existing options, appends new ones, re-enables dropdown |
| 8 | Verify .fail() handler | Errors logged to console, page not broken |

---

#### TC-CR09: parseDateRange Exception Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller at line 136 | parseDateRange method visible |
| 2 | Verify try/catch wrapping | Carbon::parse wrapped in try/catch |
| 3 | Trace exception path | On exception, falls back to [now()->subDays(30), now()] |
| 4 | Verify both dates required | Function only called when date_from AND date_to are present |
| 5 | Verify time boundaries | startDate = startOfDay(), endDate = endOfDay() |

---

#### TC-CR10: Sticky Header/Footer CSS

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect container at line 154 | div with class table-responsive, style max-height:600px |
| 2 | Inspect thead at line 156 | class="sticky-top" applied |
| 3 | Inspect # and Name cells at lines 158-159 | position: sticky; left: 0/40px; z-index: 11 |
| 4 | Inspect tfoot at line 206 | class="sticky-bottom" with bg-light |
| 5 | Test vertical scroll | Header and footer remain fixed while body scrolls |
| 6 | Test horizontal scroll | # and Name columns remain fixed on left side |

---

#### TC-CR11: JS — getColorByPct() Private Method Mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller and locate getColorByPct() at line 791 | Method returns color class based on percentage |
| 2 | Test with pct = null | Returns 'secondary' |
| 3 | Test with pct = 85 | Returns 'success' |
| 4 | Test with pct = 70 | Returns 'primary' |
| 5 | Test with pct = 50 | Returns 'info' |
| 6 | Test with pct = 33 | Returns 'warning' |
| 7 | Test with pct = 32 | Returns 'danger' |

---

#### TC-CR12: JS — getDivision() Private Method Boundary Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller and locate getDivision() at line 774 | Method returns division string |
| 2 | Test with pct = null | Returns '—' |
| 3 | Test with pct = 60 | Returns 'I' (First) |
| 4 | Test with pct = 45 | Returns 'II' (Second) |
| 5 | Test with pct = 33 | Returns 'III' (Third) |
| 6 | Test with pct = 32 | Returns '—' (No division) |
| 7 | Test with pct = 100 | Returns 'I' |
| 8 | Test with pct = 59.9 | Returns 'II' |

---

#### TC-CR13: JS — getSubmissionStatusLabel() Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller at line 800 | getSubmissionStatusLabel method |
| 2 | Test with null submission | Returns 'Pending' |
| 3 | Test with resubmission requested | Returns 'Resubmission Requested' |
| 4 | Test with marks_obtained not null | Returns 'Graded' |
| 5 | Test with submission but no marks | Returns 'Submitted' |

---

#### TC-CR14: View — Empty Matrix Forelse Fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade matrix table at line 172 | @forelse used with @empty fallback |
| 2 | Verify colspan calculation | `count($hwPerformanceData['homeworks']) + 4` for proper spanning |
| 3 | Empty state shows icon + message | fa-chart-line icon and prompt text |
| 4 | Verify conditional summary hidden when empty | @if(!empty($hwPerformanceData['matrix'])) wraps summary section |

---

#### TC-CR15: Controller — Logging/Data Audit (line 460 pattern)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check if generateHwPerformanceData() has Log::info calls | No logging in HW performance method (unlike exam result) |
| 2 | Verify this is consistent | HW perf does not log; exam result does — no inconsistency |

---

## End of TC List
