# lms_StudentExamHistory_TcList

## Module: LmsExam → Advanced Reports → Student Exam History

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Advanced Reports |
| Feature | Student Exam History |
| URL(s) | `/lms-exam/exam-advanced-reports?active_tab=student-exam-history` (index) |
| Controller | `Modules\LmsExam\Http\Controllers\ExamAdvancedReportController@index()` |
| Method (Data) | `generateStudentExamHistoryData()` (private, line 501) |
| Model(s) | `Modules\StudentPortal\Models\ExamResult`, `Modules\StudentProfile\Models\StudentAcademicSession`, `Modules\StudentProfile\Models\Student`, `Modules\LmsExam\Models\Exam`, `Modules\LmsExam\Models\ExamPaper` |
| View (Partial) | `advanced-reports/partials/student-exam-history.blade.php` |
| Permissions | `tenant.lms-exam-report.viewAny` |
| Pagination | None (single student history) |
| Charts | ApexCharts: line (progress trend), polarArea (radar/competency) |
| Date Range | daterangepicker with moment.js |

---

## 2. Pre-conditions

- Required permission: `tenant.lms-exam-report.viewAny`
- Required seed data: At least one `Student` with `StudentAcademicSession` (is_current=1)
- Multiple `ExamResult` records for that student across different exams/subjects
- Varied percentages to show progress trend (improving, declining, or mixed)
- Class average data (ExamResult for other students in same exam) for comparison
- At least 3+ subjects with results for radar chart rendering
- Student profile data: photo_url, roll_number, full_name
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

When the page loads with `active_tab=student-exam-history`:

| Widget/Chart | Data Source | Query Logic | Filters |
|-------------|-------------|-------------|---------|
| Shared: Class Dropdown | `SchoolClass::where('is_active', 1)->orderBy('name')` | All active classes | is_active=1 |
| Shared: Student Dropdown | `Student::where('is_active', 1)->whereHas('studentAcademicSessions.classSection', ...)` | Students for selected class | class_id |
| **Student Profile Banner** | `generateStudentExamHistoryData()` → `$profile` | Student name, class, section, roll, photo, avg, top subject | student_id |
| **Metrics Cards (5)** | `generateStudentExamHistoryData()` → `$metrics` | total_exams, avg_pct, passed, highest, best_subject | student_id, date_from, date_to |
| **Progress Trend Chart** | `generateStudentExamHistoryData()` → `$charts['progress']` | Line chart: Student % vs Class Avg % per exam | student_id, date_from, date_to |
| **Competency Radar Chart** | `generateStudentExamHistoryData()` → `$charts['radar']` | Polar area: Avg score % per subject | student_id, date_from, date_to |
| **History Ledger** | `generateStudentExamHistoryData()` → `$rows` | Per-exam row with date, name, subject, marks, %, result, grade | student_id, date_from, date_to |

---

## 4. Test Data Strategy

- **Core dataset**: 1 student with 15+ exam results across 5+ subjects over 6 months
- **Progress trend**: Mix of increasing, decreasing, and stable performance
- **Class averages**: For each exam the student took, seed results for other students to calculate class avg
- **Subjects**: Math, Science, English, History, Geography — each with 3+ results
- **Profile**: Student with photo, roll number, full name
- **Empty state**: Student with no exam results
- **Default student**: When no student_id provided, falls back to most recent active session
- **Date range**: Results spanning 6 months for timeline testing

---

## 5. Business Conditions

### 4.1 Database Schema

#### `std_students`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK |
| BC-DB-02 | student_id | INT UNSIGNED | UNIQUE |
| BC-DB-03 | first_name | VARCHAR(100) | NOT NULL |
| BC-DB-04 | last_name | VARCHAR(100) | NULLABLE |
| BC-DB-05 | full_name | VARCHAR(255) | Virtual/computed |
| BC-DB-06 | photo_url | VARCHAR(255) | NULLABLE |
| BC-DB-07 | admission_no | VARCHAR(50) | NULLABLE |
| BC-DB-08 | roll_number | VARCHAR(20) | NULLABLE |
| BC-DB-09 | is_active | TINYINT(1) | DEFAULT 1 |

#### `std_student_academic_sessions`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-10 | id | INT UNSIGNED | PK |
| BC-DB-11 | student_id | INT UNSIGNED | NOT NULL, FK |
| BC-DB-12 | class_section_id | INT UNSIGNED | NOT NULL, FK |
| BC-DB-13 | roll_no | VARCHAR(20) | NULLABLE |
| BC-DB-14 | is_current | TINYINT(1) | DEFAULT 0 |

#### `lms_exam_results`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-15 | id | INT UNSIGNED | PK |
| BC-DB-16 | exam_id | INT UNSIGNED | NOT NULL, FK |
| BC-DB-17 | exam_paper_id | INT UNSIGNED | NOT NULL, FK |
| BC-DB-18 | student_id | INT UNSIGNED | NOT NULL, FK |
| BC-DB-19 | total_marks_possible | DECIMAL(8,2) | DEFAULT 0 |
| BC-DB-20 | total_marks_obtained | DECIMAL(8,2) | DEFAULT 0 |
| BC-DB-21 | percentage | DECIMAL(5,2) | NULLABLE |
| BC-DB-22 | result_status | VARCHAR(20) | NULLABLE |
| BC-DB-23 | grade_obtained | VARCHAR(10) | NULLABLE |
| BC-DB-24 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

### 4.2 Filter/Input Validation

| BC ID | Filter | Type | Default |
|-------|--------|------|---------|
| BC-VAL-01 | class_id | INT, nullable | null |
| BC-VAL-02 | student_id | INT, nullable | Latest active session student |
| BC-VAL-03 | date_from | DATE, nullable | null (no filter) |
| BC-VAL-04 | date_to | DATE, nullable | null (no filter) |

### 4.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | tenant.lms-exam-report.viewAny | Without → 403 |
| BC-AUTH-02 | Guest access | Redirect to /login |

### 4.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Student Session Lookup | If student_id provided, get current session; else get latest current session |
| BC-BIZ-02 | No Session Fallback | If no session found, return empty profile with '—' and N/A avatar |
| BC-BIZ-03 | Student Results Query | ExamResult where student_id matches session's student_id |
| BC-BIZ-04 | Class Average Per Exam | ExamResult::where(exam_id)->where(exam_paper_id)->avg('percentage') |
| BC-BIZ-05 | Progress Chart | Student % (solid purple line) vs Class Avg % (dashed grey line) |
| BC-BIZ-06 | Radar Chart | Average score % per subject (polar area chart) |
| BC-BIZ-07 | Best Subject | Subject with highest average percentage |
| BC-BIZ-08 | Unique Exam Count | $results->unique('exam_id')->count() |
| BC-BIZ-09 | Pass Count | $results->where('result_status', 'PASS')->count() |
| BC-BIZ-10 | Avatar Fallback | If no photo_url, generate UI Avatars URL with student name initials |
| BC-BIZ-11 | Status Badge | PASS → green, FAIL/ABSENT → red |
| BC-BIZ-12 | Grade Display | Uses grade_obtained if set, else getGrade() |
| BC-BIZ-13 | Division Column | Shows class average percentage for comparison |
| BC-BIZ-14 | Empty History | "No assessment records identified for this student profile." |
| BC-BIZ-15 | Cumulative Summary | Exams Attempted count, Global Rank Avg, Profile Health % |

### 4.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete |
|-------|-----------|------------------|----------|
| BC-REF-01 | exam_result.exam_id | lms_exams.id | CASCADE |
| BC-REF-02 | exam_result.exam_paper_id | lms_exam_papers.id | CASCADE |
| BC-REF-03 | exam_result.student_id | std_students.id | CASCADE |
| BC-REF-04 | session.class_section_id | sch_class_sections.id | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Student Exam History page loads with all UI elements | Filter bar, student profile banner, 5 metric cards, 2 charts, history ledger | — | — | ⬜ |
| TC-P02 | Student profile banner displays correct info | Name, class, section, roll number, photo, avg score, top subject | — | — | ⬜ |
| TC-P03 | Metrics cards show correct student stats | Unit Audits, Academic Avg, Success Units, Peak Score, Strong Suit | — | — | ⬜ |
| TC-P04 | Progress trend chart displays student vs class avg | Line chart with student % (solid) and class avg % (dashed) | — | — | ⬜ |
| TC-P05 | Competency radar chart displays per-subject averages | Polar area chart with subject spokes | — | — | ⬜ |
| TC-P06 | History ledger shows correct columns | Date, Exam/Assessment Title, Subject Area, Secured/Max, Efficiency %, Result, Division, Grade | — | — | ⬜ |
| TC-P07 | Per-exam row shows correct data | Marks, percentage, grade, status all match seed | — | — | ⬜ |
| TC-P08 | Result status badge correct color | PASS → green, FAIL/ABSENT → red | — | — | ⬜ |
| TC-P09 | Efficiency progress bar color coded | ≥75% green, ≥40% blue, <40% red | — | — | ⬜ |
| TC-P10 | Filter by student scopes to that student's history | Selecting different student shows their history | — | — | ⬜ |
| TC-P11 | Filter by class loads students via AJAX | Class change → student dropdown populated | — | — | ⬜ |
| TC-P12 | Filter by date range scopes results | Results within date range included | — | — | ⬜ |
| TC-P13 | Combined filters (class + student + date range) | Precise subset of history | — | — | ⬜ |
| TC-P14 | Default student (no student_id) loads latest active | Most recent active session's student shown | — | — | ⬜ |
| TC-P15 | Cumulative summary at bottom | Exams Attempted, Global Rank Avg, Profile Health % | — | — | ⬜ |
| TC-P16 | Progress trend compares student vs class average | Both lines visible and different | — | — | ⬜ |
| TC-P17 | Radar chart shows multiple subject spokes | Each subject as a spoke with avg % | — | — | ⬜ |
| TC-P18 | Strong Suit metric matches highest subject avg | Best subject displayed in metrics | — | — | ⬜ |
| TC-P19 | Grade column shows correct letter grade | A+, A, B+, B, C+, C, D, F as applicable | — | — | ⬜ |
| TC-P20 | Division column shows class avg for comparison | Class average % displayed in Division column | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Permission 403 — No viewAny | 403 Forbidden | — | — | ⬜ |
| TC-N02 | Guest access redirect | Redirect to /login | — | — | ⬜ |
| TC-N03 | Student with no exam results | Empty history: "No assessment records identified for this student profile." | — | — | ⬜ |
| TC-N04 | No student selected | Default student shown (latest active) | — | — | ⬜ |
| TC-N05 | Invalid student_id | Empty history; no 500 | — | — | ⬜ |
| TC-N06 | Invalid class_id | Student dropdown empty; no 500 | — | — | ⬜ |
| TC-N07 | No academic session for student | Profile shows '—' for all fields; generic avatar | — | — | ⬜ |
| TC-N08 | Single exam result only | Single row; charts with single data point | — | — | ⬜ |
| TC-N09 | Student photo null → avatar fallback | UI Avatars URL generated with initials | — | — | ⬜ |
| TC-N10 | All results ABSENT | All statuses red; avg = 0%; pass count = 0 | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Publishing new exam result adds to student history | New row appears in history ledger | — | — | ⬜ |
| TC-D02 | B | Updating marks changes percentage and grade | History row updates; charts recalculate | — | — | ⬜ |
| TC-D03 | C | Changing student's class/section updates profile banner | Profile shows new class and section | — | — | ⬜ |
| TC-D04 | D | Large dataset (50+ exam results) performance | All results display correctly; chart renders | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives | Tab wrapped by @can('tenant.lms-exam-report.viewAny') | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — generateStudentExamHistoryData() at line 501 | Returns profile, rows, metrics, charts | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | View — null-safe checks | $session->student?->full_name etc. | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — Default student fallback | If no student_id, uses latest current session | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — Class average per exam | Query ExamResult by exam_id + exam_paper_id for avg | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | JS — Line chart with two series | Student % (solid) + Class Avg % (dashed) | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | JS — PolarArea radar chart | type:'polarArea', scores per subject | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | JS — AJAX student lookup by class | Class change → students_by_class endpoint | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | View — Avatar with fallback | photo_url used if exists; UI Avatars fallback | — | — | ◌ |
| TC-CR10 | CR | Code Review | P1 | View — Cumulative summary | Exams Attempted, Global Rank Avg, Profile Health | — | — | ◌ |
| TC-CR11 | CR | Code Review | P1 | ExamAdvancedReportController — All Generators Run On Every Request | index() calls ALL 6 generate*Data() methods regardless of active tab; performance anti-pattern (wasteful for inactive tabs) | — | — | ◌ |

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

#### TC-CR02: Controller — generateStudentExamHistoryData()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller at line 501 | Method found |
| 2 | Verify session lookup | student_id → current session; else latest current |
| 3 | Verify no-session handling | Returns empty profile with '—' fields |
| 4 | Verify results query | ExamResult for student with exam/examPaper.subject relations |
| 5 | Verify class avg calculation | ExamResult::where(exam_id)->where(exam_paper_id)->avg('percentage') |
| 6 | Verify return structure | profile, rows, metrics, charts |

---

#### TC-CR03: View — null-safe Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open view file | All accesses use ?-> |
| 2 | Check $session->student?->full_name | Null-safe used |
| 3 | Check $session->classSection?->class?->name | Chained null-safe |
| 4 | Load with null relations | '—' displayed |

---

#### TC-CR04: Default Student Fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 506-516 | If no student_id, queries latest() current session |
| 2 | Test without student_id | Loads most recent active student |
| 3 | Test with valid student_id | Loads that specific student |

---

#### TC-CR05: Class Average Per Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 541-543 | Query: ExamResult where exam_id + exam_paper_id → avg('percentage') |
| 2 | Verify calculation | Class average for same exam+paper |
| 3 | Test with no other results | Class avg = 0 |

---

#### TC-CR06: Line Chart with Two Series

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect JS at line 274 | type:'line', two series: Student % + Class Avg % |
| 2 | Verify series config | Series[0]: solid purple (#6366f1), Series[1]: dashed grey (#94a3b8) |
| 3 | Verify y-axis max = 100 | Scale 0-100% |
| 4 | Verify chart ID | #studentProgressTrendChart |

---

#### TC-CR07: PolarArea Radar Chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect JS at line 289 | type:'polarArea', data from radar series |
| 2 | Verify labels | Subject names |
| 3 | Verify colors | 7 colors for different subjects |
| 4 | Verify chart ID | #studentCompetencyPolarChart |

---

#### TC-CR08: AJAX Student Lookup by Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect JS at line 237 | Class change → GET with type='students_by_class', class_id |
| 2 | Verify student dropdown populated | Response items populate #filter_seh_student |
| 3 | Verify loading state | setLoader disables dropdown during AJAX |

---

#### TC-CR09: Avatar with Fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade line 63 | <img src="{{ $...['image'] }}" |
| 2 | Check controller fallback | If no photo_url, UI Avatars URL with name initials |
| 3 | Verify avatar dimensions | 70x70 rounded circle |

---

#### TC-CR10: Cumulative Summary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade lines 210-223 | @if(!empty($studentExamHistoryData['rows'])) guards summary |
| 2 | Verify 3 summary fields | Exams Attempted, Global Rank Avg, Profile Health |

---

### 6.1 Positive TC Steps

#### TC-P01: Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard |
| 2 | Navigate to Student Exam History tab | Tab pane shown |
| 3 | Check filter bar | Class, Student, Date Range filters |
| 4 | Check profile banner | Photo, name, class, section, roll, avg, top subject |
| 5 | Check metric cards | 5 cards |
| 6 | Check charts | Progress line chart + radar chart |
| 7 | Check history ledger | Table with 8 columns |

---

#### TC-P02: Student Profile Banner

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select student with full profile data | Banner shows photo, name |
| 2 | Verify class info | Badge shows Class (Section) |
| 3 | Verify roll number | Badge shows Roll: 123 |
| 4 | Verify avg score | Big number shows avg_pct% |
| 5 | Verify top subject | Top subject name displayed |

---

#### TC-P03: Metrics Cards

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 10 exams, avg 72%, 8 passed, highest 95%, best=Math | Expected metrics |
| 2 | Card 1: Unit Audits = 10 | Correct unique exam count |
| 3 | Card 2: Academic Avg = 72% | Average percentage |
| 4 | Card 3: Success Units = 8 | Pass count |
| 5 | Card 4: Peak Score = 95% | Highest percentage |
| 6 | Card 5: Strong Suit = Mathematics | Best subject |

---

#### TC-P04: Progress Trend Chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 5 exams with student scores and class avgs | Chart data |
| 2 | Navigate to report | Line chart with 5 data points |
| 3 | Verify student line | Solid purple line |
| 4 | Verify class avg line | Dashed grey line |
| 5 | Hover over data point | Tooltip shows both values |

---

#### TC-P05: Competency Radar Chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed results in 5 subjects | 5 spokes |
| 2 | Navigate to report | Polar area chart with 5 segments |
| 3 | Verify subject labels | Each spoke labeled with subject name |

---

#### TC-P06: History Ledger Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to report | Table rendered |
| 2 | Verify 8 columns | Date, Exam/Assessment Title, Subject Area, Secured/Max, Efficiency %, Result, Division, Grade |

---

#### TC-P07: Per-Exam Row Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Exam "Midterms", Math, 80/100, 80%, PASS, Grade B+ | Row shows all values correctly |
| 2 | Verify date formatted | d M Y format |
| 3 | Verify marks format | "80 / 100" |
| 4 | Verify percentage | 80% with progress bar |

---

#### TC-P08: Result Status Badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PASS → green badge | bg-success-subtle text-success |
| 2 | FAIL → red badge | bg-danger-subtle text-danger |

---

#### TC-P09: Efficiency Progress Bar Color

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | pct >= 75 → green | bg-success |
| 2 | pct >= 40 → blue | bg-primary |
| 3 | pct < 40 → red | bg-danger |

---

#### TC-P10: Filter By Student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Student A | Student A's history shown |
| 2 | Select Student B | Student B's history shown |

---

#### TC-P11: Class → Student AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a class | Student dropdown populated via AJAX |
| 2 | Verify students list | Only students in that class shown |

---

#### TC-P12: Date Range Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date range | Only results within range shown |

---

#### TC-P13: Combined Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Class + Student + Date range | Precise history subset |

---

#### TC-P14: Default Student Load

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to tab without student_id | Most recent active student loaded |
| 2 | Verify profile shows that student | Correct student details displayed |

---

#### TC-P15: Cumulative Summary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to report with data | Summary row visible at bottom |
| 2 | Verify 3 items | Exams Attempted, Global Rank Avg, Profile Health |

---

#### TC-P16: Student vs Class Average

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed student with diverse scores vs class | Both lines visible |
| 2 | Verify student line above class avg in some exams | Correct positioning |
| 3 | Verify student line below class avg in others | Correct positioning |

---

#### TC-P17: Radar Chart Multiple Subjects

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed results in Math, Science, English, History, Geography | 5 spokes |
| 2 | Verify segment sizes proportional to avg % | Larger segment = higher average |

---

#### TC-P18: Strong Suit Metric

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Math avg 85%, Science avg 72% | Strong Suit = Math |
| 2 | Verify metric card shows "Mathematics" | Correct best subject |

---

#### TC-P19: Grade Column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 85% → Grade A | Grade column shows "A" |
| 2 | Uses grade_obtained if exists | Falls back to getGrade() if null |

---

#### TC-P20: Division Column (Class Avg)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Class avg = 65% | Division column shows "65% (Avg)" |

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

#### TC-N03: No Exam Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select student with no results | "No assessment records identified for this student profile." |

---

#### TC-N04: No Student Selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No student_id in URL | Default student loads (latest active session) |

---

#### TC-N05: Invalid student_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | ?student_id=99999 | Empty profile; no 500 |

---

#### TC-N06: Invalid class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | ?class_id=99999 | Empty student dropdown; no 500 |

---

#### TC-N07: No Academic Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student has no active session | Profile shows '—' for name/class/section |
| 2 | Avatar shows N/A fallback | UI Avatars with N? |

---

#### TC-N08: Single Exam Result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 1 result | Single row in ledger |
| 2 | Progress chart has 1 data point | Single point on line |

---

#### TC-N09: Photo Fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student with null photo_url | UI Avatars URL generated |
| 2 | Verify URL format | 'https://ui-avatars.com/api/?name=...' |

---

#### TC-N10: All Results ABSENT

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed all ABSENT | All badges red |
| 2 | Pass count = 0 | Success Units = 0 |

---

### 6.3 Dependency TC Steps

#### TC-D01: Publishing New Result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note history count = X | Before |
| 2 | Create new ExamResult for student | Result created |
| 3 | Refresh history | Count = X+1 |

---

#### TC-D02: Updating Marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Change marks from 70 to 85 | Percentage updates |
| 2 | Refresh history | New % shown; grade may change |

---

#### TC-D03: Changing Class/Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update student's class_section | Session updated |
| 2 | Refresh history | Profile shows new class/section |

---

#### TC-D04: Large Dataset

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 50 exam results | All 50 rows in ledger |
| 2 | Charts render correctly | Progress trend shows 50 points |

---

### 6.4 Code Review TC Steps

#### TC-CR04: Default Student Fallback Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 506-516 | If/else for student_id |
| 2 | No student_id | $session = StudentAcademicSession::latest()->first() |
| 3 | With student_id | $session = StudentAcademicSession::where('student_id', $studentId)->where('is_current', 1)->first() |

---

#### TC-CR05: Class Average Query

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 541-543 | ExamResult::where('exam_id', $r->exam_id)->where('exam_paper_id', $r->exam_paper_id)->avg('percentage') |
| 2 | Verify filtering by same exam+paper | Correct comparison scope |

---

#### TC-CR09: Avatar Fallback Generation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect controller lines 592-597 | 'image' key: photo_url ?? UI Avatars URL |
| 2 | Verify fallback URL | urlencode($session->student?->full_name ?? 'S') |
| 3 | Verify background color | '6366f1' (indigo) |

---

#### TC-CR10: Cumulative Summary Guard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade at line 210 | @if(!empty($studentExamHistoryData['rows'])) |
| 2 | Empty state | Summary hidden |

---

#### TC-CR11: Controller — Subject Scores Aggregation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 564-567 | $subjectScores[$subName][] = $pct for each result |
| 2 | Verify per-subject array building | Each subject gets array of percentage values |
| 3 | Verify average per subject | array_sum($s)/count($s) for each subject |
| 4 | Verify sort descending | Collection sorted by average, first key is best subject |

---

#### TC-CR12: Controller — Progress Chart Series Building

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 560-562 | $progressLabels and $studentTrend / $classTrend arrays |
| 2 | Verify student series | Array of student percentages per exam |
| 3 | Verify class avg series | Array of class average percentages per exam |

---

#### TC-CR13: View — Date Format in Ledger

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade line 179 | {{ $r['date'] }} where date = $r->created_at->format('d M Y') |
| 2 | Verify format pattern | "15 Jan 2026" style with leading zero day |
| 3 | Load report with dates | All dates formatted correctly |

---

#### TC-CR14: View — Pass/Fail Badge Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade line 192-193 | strtoupper($r['status'] ?? 'N/A'), PASS → green, else red |
| 2 | Test status = 'PASS' | bg-success-subtle text-success with border |
| 3 | Test status = 'FAIL' | bg-danger-subtle text-danger with border |
| 4 | Test status = 'ABSENT' | bg-danger-subtle text-danger (falls in else) |
| 5 | Test status = null | Shows 'N/A' with red badge |

---

#### TC-CR15: View — Form Submit to Current URL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect form at line 5 | method="GET", action="{{ url()->current() }}" |
| 2 | Verify hidden active_tab input | value="student-exam-history" |
| 3 | Verify Retrieve button type="submit" | Form submits on click |

---

#### TC-P21: Progress Trend — Improving Trajectory

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Results with increasing percentages (40%, 55%, 70%, 85%) | Upward trend |
| 2 | Navigate to report | Line chart shows upward slope from left to right |
| 3 | Verify student line consistently above previous point | Each exam higher than last |

---

#### TC-P22: Progress Trend — Declining Trajectory

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Results with decreasing percentages (90%, 75%, 60%, 45%) | Downward trend |
| 2 | Navigate to report | Line chart shows downward slope |
| 3 | Verify student line consistently below previous | Each exam lower than last |

---

#### TC-P23: Progress Trend — Consistent Performance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: All results around 70-75% | Flat line |
| 2 | Navigate to report | Line chart shows minimal variation |
| 3 | Student line close to horizontal | Consistent performance visualized |

---

#### TC-P24: Radar Chart — Single Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Results in only 1 subject (Math) | Single spoke |
| 2 | Navigate to report | Polar chart renders with 1 segment |
| 3 | No JavaScript errors | Chart renders successfully |

---

#### TC-P25: Radar Chart — All Subjects Equal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: All subjects with same avg 75% | Equal segments |
| 2 | Navigate to report | Radar chart shows symmetric shape |
| 3 | All segments same size | Balanced visualization |

---

#### TC-P26: Radar Chart — One Subject Dominant

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Math avg 95%, other subjects 50-60% | Math much larger |
| 2 | Navigate to report | Math segment visibly larger than others |
| 3 | Strong suit metric shows Math | Consistent with radar |

---

#### TC-P27: History Ledger — Chronological Sort

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Results with dates Jan, Feb, Mar | Three dates |
| 2 | Navigate to report | Jan row first, Feb second, Mar third |
| 3 | Verify orderBy('created_at', 'asc') | Correct ascending order |

---

#### TC-P28: History Ledger — Subject Badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to report | Subject area shown as badge |
| 2 | Badge appearance | bg-light text-dark border fw-medium |

---

#### TC-P29: History Ledger — Marks Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 80 obtained / 100 total | Display: "80 / 100" |
| 2 | Verify fw-bold class | Bold styling applied |

---

#### TC-P30: History Ledger — Efficiency Percent with Progress Bar

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to report | Each row shows % with mini progress bar |
| 2 | Verify bar width = percentage | style="width:80%" matches value |
| 3 | Verify color coding | ≥75% green, ≥40% blue, <40% red |

---

#### TC-P31: History Ledger — Grade Column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to report | Grade shown in last column |
| 2 | Verify bold large font | fw-bold fs-6 classes |

---

#### TC-P32: Reset Button Behavior

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filters (class + student + date) | URL has parameters |
| 2 | Click reset (rotate-right icon) | URL clears to ?active_tab=student-exam-history |
| 3 | Page reloads with defaults | Default student loaded |

---

#### TC-P33: Date Range Picker Presets

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open date picker on timeline range | Presets show: Today, Last 30 Days, This Month |
| 2 | Click 'Last 30 Days' | date_from = 30 days ago, date_to = today |
| 3 | Click 'This Month' | date_from = month start, date_to = month end |

---

#### TC-P34: Retrieve Button Submits Form

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class and student | Dropdowns populated |
| 2 | Click 'Retrieve' button | Form submits via GET |
| 3 | Page reloads with student_id in URL | History data displayed |

---

#### TC-P35: Profile Banner — Active Indicator

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to report | Green dot on student photo |
| 2 | Verify CSS | position-absolute bottom-0 end-0 p-1 bg-success rounded-circle |

---

#### TC-P36: Profile Banner Layout

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check banner display | Photo left, name+badges center, stats right |
| 2 | Verify gradient background | linear-gradient(135deg, #ffffff, #f8fafc) |
| 3 | Verify left border | 5px solid #6366f1 (indigo accent) |

---

#### TC-P37: Metrics — Unique Exam Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 12 results but only 8 distinct exam_ids | Expected unique = 8 |
| 2 | Navigate to report | Unit Audits = 8 |
| 3 | Verify controller logic | $results->unique('exam_id')->count() |

---

#### TC-P38: Metrics — Average Percentage Calculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 4 results: 80%, 70%, 90%, 60% | Expected avg = 75% |
| 2 | Navigate to report | Academic Avg = 75% |
| 3 | Verify rounding | round(75.0, 1) = 75.0 |

---

#### TC-P39: Metrics — Highest Percentage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: percentages 45%, 72%, 88%, 60% | Peak = 88% |
| 2 | Navigate to report | Peak Score = 88% |

---

#### TC-P40: Metrics — Strong Suit Identification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Math avg 85%, Science 72%, English 78% | Best = Math |
| 2 | Navigate to report | Strong Suit = Mathematics |

---

#### TC-N11: Student With Only FAIL Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed all results with result_status='FAIL' | All fail |
| 2 | Navigate to report | All red badges |
| 3 | Success Units = 0 | Pass count = 0 |

---

#### TC-N12: Student With Only PASS Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed all results with result_status='PASS' | All pass |
| 2 | Navigate to report | All green badges |
| 3 | Success Units = total count | Every result counted as pass |

---

#### TC-N13: Date Range Outside Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed results in Jan-Feb | Results in Jan-Feb |
| 2 | Set date range to Jun-Jul (no overlap) | No results match |
| 3 | Empty history message displayed | "No assessment records identified." |

---

#### TC-N14: Student Name With Special Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed student named "Jean-Pierre Lévesque" | Special chars |
| 2 | Navigate to report | Name displays correctly |
| 3 | Avatar URL encoded | URL-safe encoding in query string |

---

#### TC-N15: Zero Total Marks Possible

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed result with total_marks_possible = 0 | Zero marks |
| 2 | Navigate to report | Percentage = 0 or null |
| 3 | No division by zero error | Graceful display |

---

#### TC-D05: Cross-Module — Online Assessment Result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student completes online exam via Quiz module | ExamResult created |
| 2 | Refresh student history | New result row appears |
| 3 | Verify data accuracy | Exam name, marks, percentage correct |

---

#### TC-D06: Cross-Module — Offline Assessment Result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Teacher enters marks via Offline Assessment | ExamResult created |
| 2 | Refresh student history | New row with correct data |

---

#### TC-D07: Class Average Data Consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Other students in same exam have specific marks | Class avg calculable |
| 2 | Verify class avg displayed in ledger | Division column shows avg% |
| 3 | Recalculate manually | Matches displayed value |

---

#### TC-D08: Grade Fallback Consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed grade_obtained = NULL for result | Falls back to getGrade() |
| 2 | Seed grade_obtained = 'B' for another result | Uses stored grade directly |
| 3 | Both scenarios display correct grades | Consistent behavior |

---

#### TC-CR16: View — Forelse Empty State in Ledger

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade line 177 | @forelse($studentExamHistoryData['rows'] as $r) |
| 2 | @empty block content | Icon + "No assessment records identified for this student profile." |
| 3 | colspan = 8 | Spans all table columns |

---

#### TC-CR17: View — Cumulative Summary Guard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade line 210 | @if(!empty($studentExamHistoryData['rows'])) |
| 2 | Summary shows 3 fields | Exams Attempted, Global Rank Avg, Profile Health |
| 3 | Empty history hides summary | Guard prevents empty summary |

---

#### TC-CR18: Controller — Empty Session Return Structure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 518-525 | Return array with profile, rows[], metrics[], charts[] |
| 2 | Profile has fallback '—' for all fields | name, class, section, roll_no all '—' |
| 3 | Avatar fallback URL | 'https://ui-avatars.com/api/?name=N%2FA&background=6366f1&color=fff' |

---

## End of TC List
