# lms_Dashboard_TcList

## Module: LmsExam → Exam Management → Dashboard

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Exam Management |
| Feature | Exam Dashboard (Default Landing Tab) |
| URL(s) | `GET /exam/master?active_tab=dashboard` (dashboard tab), `GET /exam/exam/index` (standalone) |
| Controller | `Modules\LmsExam\Http\Controllers\LmsExamController@masters()` |
| Service | `Modules\LmsExam\Services\ExamDashboardService` |
| Model(s) | `Exam`, `ExamPaper`, `ExamAllocation`, `ExamAttempt`, `ExamResult` |
| View Path | `resources/views/dashboard/index.blade.php` |
| Libraries | Chart.js, daterangepicker, moment.js |
| Filters | Class/Section, Subject/Study Format, Mode (Online/Offline/All), Date Range |
| KPI Cards (6) | Total Exams, Exam Papers, Allocations, Submitted, Evaluated, Pending Eval |
| Charts (2) | Monthly Activity (bar) — Papers Created vs Allocations, Submission Status (doughnut) |
| Breakdowns (4) | Subject-wise Paper Distribution (table), Class-wise Exam Count (progress bars), Paper Mode Split (online/offline), Recent Exams (last 8) |
| Tables (6) | `lms_exams`, `lms_exam_papers`, `lms_exam_allocations`, `exam_attempts`, `exam_results`, `lms_exam_paper_sets` |

---

## 2. Pre-conditions

- Required permissions: `tenant.exam.viewAny`
- Tenant context via `tenancy()->initialize()`
- At least some exam data must exist across all tables for non-zero dashboard values
- `ExamDashboardService` must be available via dependency injection
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

When the dashboard loads (default tab) via `LmsExamController@masters()` with `active_tab=dashboard`:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Class Section List | `ClassSection::with(class,section)->where('is_active',1)->orderBy('full_name')` | Active class-sections | is_active | None |
| Subject List (filter) | `ExamDashboardService::getDashboardSubjectList()` | Based on class_section_id filter | class_section_id | None |
| Dashboard Stats | `ExamDashboardService::getDashboardStats()` | 6 KPI values, chart data, breakdowns | class_id, subject_id, mode, date_from, date_to | None |
| Recent Exams | `ExamDashboardService::getRecentExams()` | Last 8 exams with paper/submission/eval counts | class_id | 8 records |
| Monthly Activity | `ExamDashboardService` | Papers created per month (6 months) + allocations per month | All filters | None |
| Subject Breakdown | `ExamDashboardService` | Top 6 subjects with paper counts, online/offline split | All filters | None |
| Class Breakdown | `ExamDashboardService` | Top 6 classes with exam counts | All filters | None |
| Paper Mode Split | `ExamDashboardService` | Online vs Offline counts + percentages | All filters | None |

## 4. Test Data Strategy

- **Exam data**: Create exams with various dates spanning last 6 months for monthly chart data
- **Papers**: Create papers in both ONLINE and OFFLINE modes for mode split
- **Allocations**: Create allocation records across multiple classes/subjects
- **Attempts**: Create attempts with various statuses (SUBMITTED, EVALUATED, IN_PROGRESS, etc.)
- **Results**: Create result records for evaluated students
- **Date range**: Test with presets and custom ranges
- **Pre-test cleanup**: Delete test data after tests

---

## 5. Business Conditions

### 4.1 Database Schema — Relevant Tables

| BC ID | Column | Table | Type | Details |
|-------|--------|-------|------|---------|
| BC-DB-01 | id | lms_exams | INT PK | Exam identity |
| BC-DB-02 | title | lms_exams | VARCHAR | Exam title |
| BC-DB-03 | start_date | lms_exams | DATETIME | Exam start |
| BC-DB-04 | class_id | lms_exam_papers | INT FK | Class reference |
| BC-DB-05 | subject_id | lms_exam_papers | INT FK | Subject reference |
| BC-DB-06 | mode | lms_exam_papers | ENUM | ONLINE / OFFLINE |
| BC-DB-07 | id | lms_exam_allocations | INT FK | Allocation records |
| BC-DB-08 | status | exam_attempts | ENUM | Attempt status |
| BC-DB-09 | id | exam_results | INT FK | Result records |
| BC-DB-10 | total_marks_obtained | exam_results | DECIMAL | Marks scored |

### 4.2 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | tenant.exam.viewAny | Access to dashboard |
| BC-AUTH-02 | Guest access | Redirect to /login |

### 4.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Dashboard loads (default tab) | 6 KPI cards, 2 charts, 4 breakdown sections visible |
| BC-BIZ-02 | Total Exams KPI | Count of exams matching filters |
| BC-BIZ-03 | Exam Papers KPI | Count of exam papers matching filters |
| BC-BIZ-04 | Allocations KPI | Total student-exam allocations matching filters |
| BC-BIZ-05 | Submitted KPI | Count of attempts with submission statuses |
| BC-BIZ-06 | Evaluated KPI | Count of evaluated results |
| BC-BIZ-07 | Pending Eval KPI | Submitted - Evaluated (calculated, never negative) |
| BC-BIZ-08 | Filter by Class/Section | All widgets filtered to selected class |
| BC-BIZ-09 | Filter by Subject | All widgets filtered to selected subject (requires class) |
| BC-BIZ-10 | Filter by Mode | All widgets filtered to Online or Offline only |
| BC-BIZ-11 | Filter by Date Range | All widgets filtered to date range |
| BC-BIZ-12 | Multi-filter combination | All filters applied simultaneously |
| BC-BIZ-13 | Clear filters | Reset clears all, shows unfiltered data |
| BC-BIZ-14 | Monthly Activity Chart (6 months) | Bar chart shows papers created vs allocations per month |
| BC-BIZ-15 | Submission Status Doughnut Chart | Shows Submitted, Evaluated, Pending, Not Started segments |
| BC-BIZ-16 | Doughnut center shows total allocations | Number in center |
| BC-BIZ-17 | Subject-wise Paper Distribution (top 6) | Table with subject, paper count, online, offline, progress bar |
| BC-BIZ-18 | Class-wise Exam Count (top 6) | Progress bars showing relative exam counts per class |
| BC-BIZ-19 | Paper Mode Split | Online vs Offline counts + percentages + submitted/evaluated/pending/not-started breakdown |
| BC-BIZ-20 | Recent Exams Table (last 8) | 8 most recent exams with all columns |
| BC-BIZ-21 | Recent Exams — Submission % | Submission percentage calculated and displayed |
| BC-BIZ-22 | Recent Exams — Evaluation % | Evaluation percentage calculated and displayed |
| BC-BIZ-23 | Recent Exams — Status Badge | PUBLISHED=green, CONCLUDED=gray, ARCHIVED=dark, other=yellow |
| BC-BIZ-24 | KPI Cards Gradient Colors | 6 different gradient backgrounds |
| BC-BIZ-25 | KPI — Pending Eval Never Negative | max(0, submitted - evaluated) |
| BC-BIZ-26 | Subject cascade AJAX | Selecting class dynamically loads subjects |
| BC-BIZ-27 | Date range auto-submit disabled | Date picker does NOT auto-submit (unlike summary) |
| BC-BIZ-28 | Empty state for all sections | "No data for selected filters" / "No data available" / "No exams found" |
| BC-BIZ-29 | Recent Exams link to creation page | "View All →" link to exam creation tab |
| BC-BIZ-30 | All KPI cards show 0 when no data | Zero values, not errors |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Dashboard Loads As Default Tab | Dashboard is the first tab shown when entering Exam module | — | — | ⬜ |
| TC-P02 | Filter Bar Visible With All Controls | Class/Section, Subject, Mode, Date Range, Filter and Reset buttons | — | — | ⬜ |
| TC-P03 | 6 KPI Cards Visible With Values | Total Exams, Exam Papers, Allocations, Submitted, Evaluated, Pending Eval | — | — | ⬜ |
| TC-P04 | KPI Cards Show Gradient Backgrounds | Each card has different gradient color | — | — | ⬜ |
| TC-P05 | KPI — Total Exams Count | Shows count of all exams matching filters | — | — | ⬜ |
| TC-P06 | KPI — Exam Papers Count | Shows count of all papers matching filters | — | — | ⬜ |
| TC-P07 | KPI — Allocations Count | Shows count of all allocations matching filters | — | — | ⬜ |
| TC-P08 | KPI — Submitted Count | Shows count of submitted attempts matching filters | — | — | ⬜ |
| TC-P09 | KPI — Evaluated Count | Shows count of evaluated results matching filters | — | — | ⬜ |
| TC-P10 | KPI — Pending Eval = Submitted - Evaluated | Calculated value, never negative | — | — | ⬜ |
| TC-P11 | Filter By Class/Section | Select a class → all widgets update to show data for that class | — | — | ⬜ |
| TC-P12 | Filter By Subject (After Class Selected) | Subject filter available, filters data by subject | — | — | ⬜ |
| TC-P13 | Filter By Mode (Online) | Only ONLINE data shown in all widgets | — | — | ⬜ |
| TC-P14 | Filter By Mode (Offline) | Only OFFLINE data shown in all widgets | — | — | ⬜ |
| TC-P15 | Filter By Date Range (Last 7 Days) | Only data from last 7 days shown | — | — | ⬜ |
| TC-P16 | Filter By Date Range (Last 30 Days) | Only data from last 30 days | — | — | ⬜ |
| TC-P17 | Filter By Date Range (This Month) | Only current month data | — | — | ⬜ |
| TC-P18 | Filter By Date Range (Last Month) | Only last month data | — | — | ⬜ |
| TC-P19 | Filter By Date Range (Custom) | Custom start/end dates applied correctly | — | — | ⬜ |
| TC-P20 | Multi-Filter: Class + Mode + Date Range | All filters applied simultaneously | — | — | ⬜ |
| TC-P21 | Clear All Filters | Reset clears all filters, shows all data | — | — | ⬜ |
| TC-P22 | Monthly Activity Bar Chart Renders | Bar chart with 6 months of data, 2 datasets (Papers Created, Allocations) | — | — | ⬜ |
| TC-P23 | Monthly Activity — Last 6 Months Only | Only 6 month bars shown | — | — | ⬜ |
| TC-P24 | Monthly Activity — Papers Created Dataset | Blue bars for papers created per month | — | — | ⬜ |
| TC-P25 | Monthly Activity — Allocations Dataset | Teal bars for allocations per month | — | — | ⬜ |
| TC-P26 | Submission Status Doughnut Chart Renders | Doughnut with 4 segments: Submitted, Evaluated, Pending, Not Started | — | — | ⬜ |
| TC-P27 | Doughnut Center Shows Total Allocations | Number displayed in center of doughnut | — | — | ⬜ |
| TC-P28 | Doughnut Legend Shows Below Chart | Color-coded labels for each segment | — | — | ⬜ |
| TC-P29 | Subject-wise Paper Distribution Table | Table with Subject, Papers, Online, Offline, Share columns | — | — | ⬜ |
| TC-P30 | Subject Distribution Progress Bar | Bar showing relative share, percentage-based width | — | — | ⬜ |
| TC-P31 | Subject Distribution — Top 6 Subjects | Limited to 6 rows | — | — | ⬜ |
| TC-P32 | Class-wise Exam Count Progress Bars | Horizontal bars with class name, exam count, colored gradient | — | — | ⬜ |
| TC-P33 | Class-wise — Top 6 Classes | Limited to 6 classes | — | — | ⬜ |
| TC-P34 | Paper Mode Split — Online vs Offline Counts | Online count + percentage, Offline count + percentage | — | — | ⬜ |
| TC-P35 | Paper Mode Split — Progress Bar | Split progress bar (Online blue, Offline gray) | — | — | ⬜ |
| TC-P36 | Paper Mode Split — Submitted/Evaluated/Pending/Not Started | Breakdown below split bar | — | — | ⬜ |
| TC-P37 | Recent Exams Table (Last 8) | 8 most recent exams with Exam, Class, Type, Papers, Alloc, Submitted, Checked, Status, Date | — | — | ⬜ |
| TC-P38 | Recent Exams — Submission/Evaluation % | Percentage calculated and displayed below counts | — | — | ⬜ |
| TC-P39 | Recent Exams — Status Badge Colors | PUBLISHED=green, CONCLUDED=gray, ARCHIVED=dark, DRAFT/others=yellow | — | — | ⬜ |
| TC-P40 | Recent Exams — Link To Creation Page | "View All →" link navigates to exam creation tab | — | — | ⬜ |
| TC-P41 | Class→Subject AJAX Cascade | Selecting class triggers subject dropdown population | — | — | ⬜ |
| TC-P42 | Charts Re-render On Filter Change | Filters applied → charts update with new data | — | — | ⬜ |
| TC-P43 | All KPIs Zero When No Data | Zero exams → all KPIs show 0 | — | — | ⬜ |
| TC-P44 | Empty Subject Breakdown | "No data for selected filters." shown | — | — | ⬜ |
| TC-P45 | Empty Class Breakdown | "No data available." shown | — | — | ⬜ |
| TC-P46 | Empty Recent Exams | "No exams found." shown in table | — | — | ⬜ |
| TC-P47 | KPI — Pending Eval Matches | pending = submitted - evaluated, displayed as formatted number | — | — | ⬜ |
| TC-P48 | Date Range — Today Preset | Only today's data | — | — | ⬜ |
| TC-P49 | Charts Destroy And Re-create On Re-init | Old chart instances destroyed before new ones created | — | — | ⬜ |
| TC-P50 | All Dashboard Data Loads In Single Request | Page loads with all data; no subsequent AJAX for main data | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No Permission (Missing tenant.exam.viewAny) | HTTP 403 Forbidden | — | — | ⬜ |
| TC-N02 | Guest Access Redirect | Redirect to /login | — | — | ⬜ |
| TC-N03 | No Exam Data Exists | All KPIs = 0, empty states for charts/breakdowns | — | — | ⬜ |
| TC-N04 | Invalid Class ID Filter | All KPIs = 0 (no data for invalid class) | — | — | ⬜ |
| TC-N05 | Invalid Subject ID Filter | All KPIs = 0 (no data for invalid subject) | — | — | ⬜ |
| TC-N06 | Future Date Range | All KPIs = 0 (no data in future) | — | — | ⬜ |
| TC-N07 | Date From > Date To | All KPIs = 0 (invalid range) | — | — | ⬜ |
| TC-N08 | Subject Filter Without Class Selected | Subject dropdown disabled or empty | — | — | ⬜ |
| TC-N09 | Charts With Zero Data | Bar chart shows empty bars, doughnut shows single color or empty | — | — | ⬜ |
| TC-N10 | XSS In Exam Title | Title with script tag → escaped by Blade in Recent Exams table | — | — | ⬜ |
| TC-N11 | Single Exam Only | Dashboard renders with single exam in all widgets | — | — | ⬜ |
| TC-N12 | Only Online Exams Exist | Mode split shows 100% Online, 0% Offline | — | — | ⬜ |
| TC-N13 | Only Offline Exams Exist | Mode split shows 0% Online, 100% Offline | — | — | ⬜ |
| TC-N14 | Subject With No Papers | Subject breakdown for that subject shows 0 papers | — | — | ⬜ |
| TC-N15 | Class With Zero Exams | Class not shown in class breakdown (no data) | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Exam Creation Reflects In Dashboard | Creating exam increases Total Exams KPI | — | — | ⬜ |
| TC-D02 | B | Paper Creation Reflects In Dashboard | Creating paper increases Exam Papers KPI | — | — | ⬜ |
| TC-D03 | C | Allocation Creation Reflects In Dashboard | Creating allocation increases Allocations KPI | — | — | ⬜ |
| TC-D04 | D | Student Submission Updates Submitted KPI | Student submits → Submitted KPI increases | — | — | ⬜ |
| TC-D05 | E | Evaluation Updates Evaluated KPI | Teacher evaluates → Evaluated KPI increases | — | — | ⬜ |
| TC-D06 | F | Evaluation Reduces Pending Eval | Pending = Submitted - Evaluated; evaluation decreases pending | — | — | ⬜ |
| TC-D07 | G | Monthly Activity Reflects Paper Creation Month | Paper created in January → January bar increments | — | — | ⬜ |
| TC-D08 | H | Monthly Activity Reflects Allocation Month | Allocations in February → February bar increments | — | — | ⬜ |
| TC-D09 | I | Subject Breakdown Matches Actual Papers | Subject with 5 papers → breakdown shows 5 | — | — | ⬜ |
| TC-D10 | J | Class Breakdown Matches Actual Exams | Class with 3 exams → breakdown shows 3 | — | — | ⬜ |
| TC-D11 | K | Recent Exams — Most Recent First | Newest exam first, 8th newest last | — | — | ⬜ |
| TC-D12 | L | Integration — P1 — ExamDashboardService — getDashboardStats returns complete object | Returns object with total_exams, total_papers, total_allocations, total_submitted, total_evaluated, monthly_activity, monthly_allocations, subject_breakdown, class_breakdown, online_papers, offline_papers | — | — | ⬜ |
| TC-D13 | M | Integration — P1 — ExamDashboardService — getRecentExams returns 8 records | Query limited to 8, ordered by start_date desc, includes withCount data | — | — | ⬜ |
| TC-D14 | N | Integration — P1 — ExamDashboardService — getDashboardSubjectList | Returns subjects for class_section_id; returns all subjects if no filter | — | — | ⬜ |
| TC-D15 | O | Integration — P1 — LmsExamController — masters() loads dashboard data conditionally | Active_tab=dashboard triggers dashboard service calls | — | — | ⬜ |
| TC-D16 | P | Integration — P1 — LmsExamController — Gate::authorize before dashboard load | Without viewAny → 403 | — | — | ⬜ |
| TC-D17 | Q | DEV — P1 — ExamDashboardService — Filter parameters applied to all queries | class_id, subject_id, mode, date_from, date_to passed to each query method | — | — | ⬜ |
| TC-D18 | R | DEV — P1 — Chart.js — Charts initialized on tab show/load | Chart instances created with dashboard data; old instances destroyed before re-create | — | — | ⬜ |
| TC-D19 | S | DEV — P1 — Daterangepicker — Initialized on dashboard load | Pickers configured with Today, Last 7 Days, Last 30 Days, This Month, Last Month presets | — | — | ⬜ |
| TC-D20 | T | DEV — P1 — Class→Subject AJAX cascade | onchange of #edash_cs triggers $.get to get-subjects-by-class | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade — isset()/null-safe Checks for Relationship Variables | All `$e->class?->name`, `$e->examType?->name`, `$e->status?->code` use null-safe operator | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — Dashboard Data Loaded By Service | LmsExamController delegates to ExamDashboardService; controller does not run raw queries | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | View — Chart Data From Blade/PHP | Chart labels and datasets passed as JSON from PHP; not fetched via separate AJAX | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | View — Pending Eval Calculation In Blade | `max(0, $examDashboardStats['total_submitted'] - $examDashboardStats['total_evaluated'])` | — | — | ◌ |
| TC-CR05 | CR | Code Review | P2 | View — Date Picker Does Not Auto-Submit | apply.daterangepicker only sets hidden fields; user must click Filter button | — | — | ◌ |
| TC-CR06 | CR | Code Review | P2 | View — Progress Bar Max Calculation | `$maxPapers / $maxExams` used for percentage width; avoids division by zero with `?: 1` fallback | — | — | ◌ |
| TC-CR07 | CR | Code Review | P2 | JS — Chart Instance Management | barChart and donutChart variables checked and destroyed before re-creating on filter/render | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Blade — isset()/null-safe Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open dashboard/index.blade.php | View file |
| 2 | Scan: `$e->class?->name` | Null-safe used |
| 3 | Scan: `$e->examType?->name` | Null-safe used |
| 4 | Scan: `$e->status?->code` | Null-safe used |
| 5 | Scan: `$row->subject?->name` | Null-safe used |
| 6 | Scan: `$row->class?->name` | Null-safe used |
| 7 | Create exam with null relations | View renders with fallbacks |

#### TC-CR02: Service Delegation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open LmsExamController.php | Controller found |
| 2 | Inspect masters() with active_tab=dashboard | Calls $this->dashboardService->getDashboardStats(), getRecentExams(), getDashboardSubjectList() |
| 3 | Verify no inline queries | All queries in ExamDashboardService |

#### TC-CR03: Chart Data From PHP

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open dashboard/index.blade.php | Chart data from PHP variables |
| 2 | Bar chart labels: `json_encode(array_keys($monthly_activity))` | From PHP array |
| 3 | Doughnut data: `$total_submitted, $total_evaluated, ...` | From PHP variables |

### 6.1 Positive TC Steps — Detailed

#### TC-P01: Dashboard Loads As Default Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Exam module | URL has active_tab=dashboard |
| 2 | Verify dashboard content visible | Filter bar, KPI cards, charts, breakdowns all present |

#### TC-P02: Filter Bar

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check filter form | 4 filter controls: Class/Section, Subject/Study Format, Mode, Date Range |
| 2 | Check Filter button | Blue primary button |
| 3 | Check Reset button | Outlined secondary (undo icon) |

#### TC-P03: 6 KPI Cards

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check all 6 cards | Total Exams, Exam Papers, Allocations, Submitted, Evaluated, Pending Eval |
| 2 | Each has label + value + icon | All present |

#### TC-P04: Gradient Backgrounds

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Total Exams: purple-blue gradient | 135deg,#6a11cb,#2575fc |
| 2 | Exam Papers: orange-yellow | 135deg,#f7971e,#ffd200 |
| 3 | Allocations: peach-red | 135deg,#ff9966,#ff5e62 |
| 4 | Submitted: blue-cyan | 135deg,#2193b0,#6dd5ed |
| 5 | Evaluated: green | 135deg,#11998e,#38ef7d |
| 6 | Pending Eval: red | 135deg,#c0392b,#e74c3c |

#### TC-P11: Filter By Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create data for Class A (10 exams) and Class B (3 exams) | Different counts |
| 2 | Select Class A | Total Exams = 10 |
| 3 | Select Class B | Total Exams = 3 |
| 4 | All KPIs update accordingly | All widgets reflect new filter |

#### TC-P13 to TC-P14: Mode Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Online" | Only online papers counted |
| 2 | Select "Offline" | Only offline papers counted |
| 3 | Select "All Modes" (empty) | Both modes counted |

#### TC-P22: Monthly Activity Bar Chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Dashboard loads with data | Chart renders with 6 month labels |
| 2 | Blue bars for "Papers Created" | First dataset |
| 3 | Teal bars for "Allocations" | Second dataset |
| 4 | Month labels | Jan, Feb, Mar, Apr, May, Jun (or similar) |

#### TC-P26: Submission Status Doughnut

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 100 allocated, 70 submitted, 50 evaluated | Segments: Submitted 70, Evaluated 50, Pending 20, Not Started 30 |
| 2 | Center shows 100 | Total Allocations |
| 3 | Legend: Submitted (blue), Evaluated (green), Pending (red), Not Started (yellow) | Color-coded |

#### TC-P29: Subject Distribution Table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 6 subjects with varying paper counts | All 6 shown |
| 2 | Subject name, Papers badge, Online badge, Offline badge, progress bar | All columns present |
| 3 | Progress bar width relative to max | Correct percentage |

#### TC-P32: Class-wise Exam Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 6 classes with varying exam counts | All 6 shown |
| 2 | Class name + exam count badge | Displayed |
| 3 | Gradient progress bar | Purple-blue gradient |

#### TC-P37: Recent Exams Table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 10 exams exist | Only 8 shown |
| 2 | Columns: Exam, Class, Type, Papers, Alloc, Submitted, Checked, Status, Date | All present |
| 3 | Submission % shown | Below submitted count |
| 4 | Evaluation % shown | Below checked count |
| 5 | Status badge color | PUBLISHED=green, etc |

#### TC-P41: Class→Subject AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Change class dropdown | AJAX to get-subjects-by-class |
| 2 | Subject list updates | Subjects for selected class shown |
| 3 | Clear class | Subject resets to "All Subjects" |

### 6.2 Negative TC Steps — Detailed

#### TC-N01: No Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without tenant.exam.viewAny | 403 on exam module |

#### TC-N02: Guest Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate to exam dashboard | Redirect to /login |

#### TC-N03: No Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no exam data | Empty system |
| 2 | Load dashboard | All KPIs = 0, empty states for charts and breakdowns |
| 3 | Verify no JS errors | Charts handle 0 data gracefully |

#### TC-N04 to TC-N07: Invalid Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | class_section_id=99999 | All KPIs = 0 |
| 2 | subject_id=99999 | All KPIs = 0 |
| 3 | Future date range | All KPIs = 0 |
| 4 | date_from > date_to | All KPIs = 0 |

#### TC-N08: Subject Without Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Without class filter, subject dropdown | Shows "All Subjects" only or disabled |
| 2 | Attempt to set subject_id without class | No filtering occurs or handled gracefully |

#### TC-N12: Only Online

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Only ONLINE papers exist | Mode split: 100% Online, 0% Offline |

#### TC-N13: Only Offline

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Only OFFLINE papers exist | Mode split: 0% Online, 100% Offline |

### 6.3 Dependency TC Steps — Detailed

#### TC-D01 to TC-D06: Data Creation Reflects in Dashboard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 5 exams | Total Exams = 5 |
| 2 | Create 10 papers | Exam Papers = 10 |
| 3 | Allocate 50 students | Allocations = 50 |
| 4 | 30 students submit | Submitted = 30 |
| 5 | 20 evaluated | Evaluated = 20 |
| 6 | Pending = 30 - 20 = 10 | Pending Eval = 10 |

#### TC-D07 to TC-D08: Monthly Activity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 papers in Jan, 3 in Feb | January bar = 2, February bar = 3 |
| 2 | Create 5 allocations in Jan, 2 in Mar | January allocation bar = 5, March bar = 2 |

#### TC-D11: Recent Exams Order

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exams on different dates | Most recent first in table |
| 2 | Verify "View All" link | Links to exam creation tab |

#### TC-D12: getDashboardStats Completeness

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call getDashboardStats() | Returns object with all keys: total_exams, total_papers, total_allocations, total_submitted, total_evaluated, monthly_activity, monthly_allocations, subject_breakdown, class_breakdown, online_papers, offline_papers |
| 2 | Verify all values numeric | No null/string values where numbers expected |

#### TC-D13: getRecentExams Returns 8

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 12 exams | Only 8 returned |
| 2 | Verify each has withCount data | paper_count, allocation_count, attempt counts |
| 3 | Ordered by start_date desc | Newest first |

#### TC-D18: Chart Initialization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Dashboard loads | Charts created on DOM ready |
| 2 | Filter applied, page reloads | Old charts destroyed, new ones created |
| 3 | Verify no memory leaks | Chart instances properly cleaned up |

### 6.4 Additional Integration Test Steps

#### TC-AD-01: All KPIs Match Filtered Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Class filter → Class A | Every KPI reflects Class A data only |
| 2 | Subject filter → Subject X | Every KPI reflects Subject X data |
| 3 | Mode filter → ONLINE | Every KPI reflects only ONLINE data |
| 4 | Date range → last month | Every KPI reflects last month data |

#### TC-AD-02: Recent Exams — Status Badge DRAFT

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with DRAFT status | Yellow "DRAFT" badge |
| 2 | Create exam with PUBLISHED status | Green "PUBLISHED" badge |
| 3 | Create exam with CONCLUDED status | Gray "CONCLUDED" badge |
| 4 | Create exam with ARCHIVED status | Dark "ARCHIVED" badge |

#### TC-AD-03: Recent Exams — Submission And Evaluation Percentages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 10 allocated, 5 submitted | Submission% = 50% |
| 2 | 5 submitted, 3 checked | Evaluation% = 60% |
| 3 | 0 allocated → no division error | Handles 0 gracefully |

#### TC-AD-04: Subject Breakdown — Max Papers Calculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Max papers = 10 (Subject A) | Subject A progress bar = 100% |
| 2 | Subject B = 5 papers | Progress bar = 50% |
| 3 | Subject C = 0 papers | Progress bar = 0% or not shown |

#### TC-AD-05: Class Breakdown — Max Exams Calculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Max exams = 8 (Class A) | Class A bar = 100% |
| 2 | Class B = 4 exams | Bar = 50% |

#### TC-AD-06: Monthly Activity — Empty Months

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Some months with 0 activity | Bars show 0 for those months |
| 2 | All 6 month labels still shown | Consistent x-axis |

#### TC-AD-07: Doughnut — Zero Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 0 submitted, 0 evaluated, 0 pending, 0 not started | Chart may show empty or single color |

#### TC-AD-08: KPI Number Formatting

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Value = 1000 | Displays as "1,000" |
| 2 | Value = 0 | Displays as "0" |
| 3 | Value = 999999 | Displays with commas |

#### TC-AD-09: Date Range — Last 30 Days Affects All KPIs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Last 30 days: 3 exams, 2 created in range, 1 outside | Total Exams = 2 |
| 2 | Other KPIs similarly filtered | Consistent |

#### TC-AD-10: Date Range — Today

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Exams created today only | KPIs reflect only today's data |

#### TC-AD-11: KPI Dark/Light Text

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Cards with light background (dark=true) | Text color = dark |
| 2 | Cards with dark background (dark=false) | Text color = white |
| 3 | Card 2 (Exam Papers) has dark text | Orange gradient, dark text |
| 4 | Card 5 (Evaluated) has dark text | Green gradient, dark text |

#### TC-AD-12: Recent Exams — Truncated Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Exam title longer than 28 chars | Truncated with "..." |

#### TC-AD-13: Subject Breakdown — Subject Name Null

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Subject relation null | Shows "—" as fallback |
| 2 | No 500 error | Graceful handling |

#### TC-AD-14: Class Breakdown — Class Name Null

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Class relation null | Shows "—" as fallback |

#### TC-AD-15: Doughnut — Color Scheme

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submitted segment | Blue #2575fc |
| 2 | Evaluated segment | Green #38ef7d |
| 3 | Pending segment | Red #e74c3c |
| 4 | Not Started segment | Yellow #ffd200 |

#### TC-AD-16: Monthly Bar — Bar Border Radius

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Papers bars have borderRadius:5 | Rounded corners |
| 2 | Allocations bars have borderRadius:5 | Rounded corners |

#### TC-AD-17: Chart Responsiveness

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Resize browser window | Charts resize responsively |
| 2 | View on mobile | Charts stack vertically |

#### TC-AD-18: Recent Exams — Exam Code Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Exam has code "EXM-001" | Shown below truncated title in gray |

#### TC-AD-19: Paper Mode Split — Breakdown Cards

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submitted card | Light blue bg, "Submitted" text |
| 2 | Evaluated card | Light green bg, "Evaluated" text |
| 3 | Pending Eval card | Light orange, "Pending Eval" |
| 4 | Not Started card | Light red, "Not Started" |

#### TC-AD-20: Subject Contribution To Total

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Subject A = 5 of 20 total papers | Share progress bar = 25% |

#### TC-AD-21: KPI — Pending Eval = Submitted - Evaluated With Zero

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submitted=0, Evaluated=0 | Pending = max(0, 0-0) = 0 |
| 2 | Submitted=5, Evaluated=7 (impossible but guarded) | Pending = max(0, 5-7) = 0 |

#### TC-AD-22: Class→Subject AJAX — Error Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Server returns error on subject load | Subject dropdown shows "All Subjects" |
| 2 | No JS error | Graceful handling |

#### TC-AD-23: Filter Reset — Full State Clear

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply 3 filters | All 3 active |
| 2 | Click Reset | URL: only active_tab=dashboard |
| 3 | Subject dropdown reset | "All Subjects" selected |

#### TC-AD-24: Doughnut — Center Number Zero

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 0 total allocations | Center shows "0" |
| 2 | "Total Alloc." label below | Still visible |

#### TC-AD-25: Month Labels Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify month labels | e.g., "Jun 2025", "Jul 2025" or short month names |

#### TC-AD-26: Bar Chart — Tooltip On Hover

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Hover over bar | Tooltip shows dataset label and value |
| 2 | Index mode tooltip | Shows both datasets for that month |

#### TC-AD-27: Doughnut — Tooltip With Percentage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Hover over doughnut segment | Tooltip shows name, count, and percentage |
| 2 | Percentage = segment/total * 100 | Correct calculation |

#### TC-AD-28: Recent Exams — Link To Full View

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "View All →" | Navigates to exam creation tab |
| 2 | Correct route | lms-exam.creation-allocation.index with active_tab=exam_creation |

#### TC-AD-29: KPI Cards — Floating Icon

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Each card has icon | Font Awesome icon in top-right, opacity 0.1 |
| 2 | Icon matches card theme | Relevant icon per card |

#### TC-AD-30: Dashboard Load Time

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Dashboard with 1000+ records across tables | Loads within acceptable time |
| 2 | Multiple queries optimized | Service queries use efficient counting |

### 6.5 Filter Combination Tests

#### TC-AD-31: Filter — Class + Subject + Mode + Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class A, Subject X, Mode Online, Date Range Last 30 Days | All 4 filters applied simultaneously |
| 2 | Verify Total Exams KPI | Count reflects all 4 filters |
| 3 | Verify Monthly Activity chart | Chart data filtered by all 4 criteria |
| 4 | Verify Subject Breakdown table | Only subjects matching filters shown |
| 5 | Verify Recent Exams | Only matching exams shown |

#### TC-AD-32: Filter — Class + Subject Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class A and Subject X only | Filters applied without mode/date constraints |
| 2 | Verify all widgets reflect combined filter | Consistent across all sections |

#### TC-AD-33: Filter — Class + Mode Online Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class A, Mode Online | All widgets show online-only data for Class A |
| 2 | Mode split shows 100% Online | Correct filter reflection |

#### TC-AD-34: Filter — Class + Custom Date Range Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class A + custom date range (Jan 1 - Jan 31) | Only Class A data in January shown |
| 2 | Verify KPIs match expected counts | Consistent filtering |

#### TC-AD-35: Filter — Subject + Mode + Date Range Without Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to select Subject without Class | Subject dropdown disabled |
| 2 | Submit subject_id via URL without class | Data may be unfiltered or handled gracefully |

#### TC-AD-36: Filter — Mode + Date Range Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Mode Online, Date Range Last 7 Days | All data filtered to online exams in last 7 days |
| 2 | Verify date range applies to exam start_date | Correct boundary |

#### TC-AD-37: Filter — Class Only With All Others Default

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class B only | Subject = All, Mode = All, Date = All |
| 2 | Verify only Class B data across all widgets | Consistent |

#### TC-AD-38: Filter — Last Month + Mode Online

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Last month + Online | Only last month's online data |
| 2 | Verify Monthly Activity shows only last month data | Chart adjusts |

#### TC-AD-39: Filter — Multiple Consecutive Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class A → Filter → Select Class B → Filter → Select Mode Online → Filter | Each filter reloads dashboard correctly |
| 2 | Dashboard state consistent after each change | No stale data |

#### TC-AD-40: Filter — Subject List Updates With Class Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class X → Subject dropdown populates | Subjects for Class X |
| 2 | Change to Class Y → Subject dropdown updates | Subjects for Class Y |
| 3 | Previously selected Subject cleared | Reset to All Subjects |

#### TC-AD-41: Filter — All Filters Then Reset

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set Class + Subject + Mode + Date Range | All filters active |
| 2 | Click Reset | All fields reset |
| 3 | Verify KPIs show unfiltered totals | All data visible |

#### TC-AD-42: Filter — Class + Subject Cascade With Mode

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Class A → Subject X → Mode Online | Cascade works at each level |
| 2 | Verify subject list correctly filtered by class | Correct subjects loaded |
| 3 | Mode correctly scoped to selected class+subject | Data consistent |

#### TC-AD-43: Filter — Date Range Preset + Class Combination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | This Month + Class A | Only Class A data this month |
| 2 | Last Month + Class B | Only Class B data last month |
| 3 | Last 7 Days + Class C | Only Class C data in last 7 days |

#### TC-AD-44: Filter — Class With Multiple Sections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Class has Section A and Section B | Both sections in dropdown |
| 2 | Select Class A → Section A | Only Class A, Section A data |
| 3 | Select Class A → Section B | Only Class A, Section B data |

#### TC-AD-45: Filter — Search Within Filtered Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply Class filter | Results scoped to class |
| 2 | Type in search (if available) | Further narrow results |
| 3 | Clear search | Results return to previous filter scope |

#### TC-AD-46: Filter — Class + Date Range Last Year

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class A with date range from previous year | Data from previous year for Class A |
| 2 | Verify monthly activity shows correct historical data | Chart reflects past period |

#### TC-AD-47: Filter — Subject + Mode Online (Preselected Class)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Class preselected, pick Subject Y, Mode Online | Online papers for Subject Y in Class |
| 2 | Toggle to Mode Offline | Offline papers for Subject Y in Class |

#### TC-AD-48: Filter — Class + All Modes + Full Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Class A, All Modes, date from 1 year ago to today | Complete unfiltered data for Class A |
| 2 | Compare unfiltered total with no-class no-filter total | Class filter applied correctly |

#### TC-AD-49: Filter — Rapid Filter Toggle (Online/Offline)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Switch from Online to Offline to Online within 2 seconds | Each toggle updates correctly |
| 2 | Verify final mode is Online and data matches | No race condition |

#### TC-AD-50: Filter — Class With No Subjects Assigned

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class that has no subjects in system | Subject dropdown shows No subjects or remains disabled |
| 2 | All KPIs show 0 for that class | No subjects means no exam data |

### 6.6 KPI Verification Tests

#### TC-AD-51: KPI — Total Exams Exact Count Match

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count exams in DB matching filter | Matches Total Exams card value |
| 2 | Verify with 3 different filter combinations | Consistent accuracy |

#### TC-AD-52: KPI — Exam Papers Exact Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count papers in DB | Matches Exam Papers card |
| 2 | Verify with 5 different class filters | Each card reflects correct count |

#### TC-AD-53: KPI — Allocations Exact Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count allocation records in DB | Matches Allocations card |
| 2 | Verify allocations include all statuses | COUNT includes all |

#### TC-AD-54: KPI — Submitted Count Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count attempts with status=SUBMITTED | Matches Submitted card |
| 2 | Create 15 new submissions | Submitted increases by 15 |

#### TC-AD-55: KPI — Evaluated Count Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count results with evaluation | Matches Evaluated card |
| 2 | Evaluate 5 pending submissions | Evaluated increases by 5 |

#### TC-AD-56: KPI — Pending Eval Calculation Cross-Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submitted = 50, Evaluated = 30 | Pending Eval = 20 |
| 2 | Submitted = 50, Evaluated = 50 | Pending Eval = 0 |
| 3 | Submitted = 50, Evaluated = 55 (data anomaly) | Pending Eval = 0 (never negative) |

#### TC-AD-57: KPI — Number Formatting With Large Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Total Exams = 12345 | Displays as 12,345 |
| 2 | Allocations = 500000 | Displays as 500,000 |
| 3 | Submitted = 9999 | Displays as 9,999 |
| 4 | Evaluated = 1000000 | Displays as 1,000,000 |

#### TC-AD-58: KPI — Card Icon and Gradient Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Total Exams: icon=fa-file-text, gradient=purple-blue | Correct icon + gradient |
| 2 | Exam Papers: icon=fa-book, gradient=orange-yellow | Correct icon + gradient |
| 3 | Allocations: icon=fa-users, gradient=peach-red | Correct icon + gradient |
| 4 | Submitted: icon=fa-check-circle, gradient=blue-cyan | Correct icon + gradient |
| 5 | Evaluated: icon=fa-star, gradient=green | Correct icon + gradient |
| 6 | Pending Eval: icon=fa-clock, gradient=red | Correct icon + gradient |

#### TC-AD-59: KPI — All Cards Show Zero On Empty Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No data in any exam table | All 6 cards show 0 |
| 2 | Verify no NaN, undefined, or blank values | Proper 0 display |

#### TC-AD-60: KPI — CSS Animation On Value Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filter that changes KPI values | Cards animate count-up (if implemented) |
| 2 | Verify smooth transition | No abrupt jumps |

#### TC-AD-61: KPI — Dark/Light Text Readability

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Card 1 (purple): light background → dark text | Text readable, WCAG contrast |
| 2 | Card 6 (red): dark background → white text | Text readable, WCAG contrast |

#### TC-AD-62: KPI — Value Updates After Exam Deletion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete 3 exams with their papers | Total Exams decreases by 3 |
| 2 | Exam Papers decreases accordingly | All KPIs consistent |

### 6.7 Responsive Layout Tests

#### TC-AD-63: Responsive — Desktop View (1920x1080)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | View on 1920x1080 monitor | Full layout, 6 KPI cards in one row |
| 2 | Charts side by side | Bar chart left, doughnut right |
| 3 | All 4 breakdowns visible | No scrolling needed |

#### TC-AD-64: Responsive — Tablet View (768x1024)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | View on tablet portrait | KPI cards wrap to 2 rows of 3 |
| 2 | Charts stack vertically | Bar above doughnut |
| 3 | Breakdown sections stack | Vertically arranged |
| 4 | Filter bar wraps | Controls stack gracefully |

#### TC-AD-65: Responsive — Mobile View (375x667)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | View on iPhone SE size | KPI cards stack in single column |
| 2 | Filter controls full-width | Dropdowns occupy full width |
| 3 | Charts sized to viewport | No horizontal scroll |
| 4 | Recent Exams table horizontally scrollable | Table container scrolls |

#### TC-AD-66: Responsive — Very Small Screen (320x480)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | View on 320px wide screen | No broken layout |
| 2 | All text readable | Font sizes not too small |
| 3 | Touch targets meet minimum size | 44x44px for interactive elements |
| 4 | No content overflow | All content visible with scroll |

#### TC-AD-67: Responsive — Orientation Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Rotate from portrait to landscape | Layout reflows correctly |
| 2 | Charts resize to new dimensions | Chart.js responsive = true |
| 3 | No layout shift errors | Consistent display |

#### TC-AD-68: Responsive — Tablet Landscape (1024x768)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | View on tablet landscape | KPI cards in 3x2 grid |
| 2 | Charts side by side | Side-by-side layout resumes |
| 3 | Filter controls horizontal | Single row layout |

#### TC-AD-69: Responsive — Device Pixel Ratio (Retina)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | View on Retina display | Charts render at 2x resolution |
| 2 | Text is crisp | No blurriness on high-DPI |
| 3 | Icons sharp | Font Awesome renders correctly |

### 6.8 Chart Interaction Tests

#### TC-AD-70: Chart — Bar Chart Hover Tooltip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Hover over Papers Created bar | Tooltip shows dataset label, month, count |
| 2 | Hover over Allocations bar | Tooltip shows allocations data |
| 3 | Hover between two bars (index mode) | Both dataset values shown |

#### TC-AD-71: Chart — Doughnut Hover Tooltip With Percentages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Hover over Submitted segment | Tooltip: Submitted: 70 (35%) |
| 2 | Hover over Evaluated segment | Tooltip: Evaluated: 50 (25%) |
| 3 | Hover over Pending segment | Tooltip: Pending: 20 (10%) |
| 4 | Hover over Not Started segment | Tooltip: Not Started: 60 (30%) |

#### TC-AD-72: Chart — Legend Toggle Visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Papers Created in bar chart legend | Dataset toggles visibility |
| 2 | Click again | Dataset reappears |
| 3 | Click doughnut legend items | Segment toggles visibility |
| 4 | Verify chart updates correctly | Data re-renders without error |

#### TC-AD-73: Chart — Window Resize Behavior

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Drag browser from 1400px to 800px width | Charts resize proportionally |
| 2 | Drag back to 1400px | Charts return to original size |
| 3 | Verify no distortion | Aspect ratio maintained |

#### TC-AD-74: Chart — Data Update On Filter Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filter → data changes | Old chart destroyed, new chart created |
| 2 | Verify Chart.js instances | No duplicate instances in memory |
| 3 | Verify animation plays | New data renders with animation |

#### TC-AD-75: Chart — Doughnut Center Label

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 200 total allocations | Center shows 200 |
| 2 | Filter reduces to 50 | Center updates to 50 |
| 3 | 0 allocations | Center shows 0 with Total Alloc. label |

#### TC-AD-76: Chart — Bar Chart Click Event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click on a bar (if click handler implemented) | Action triggered (e.g., drill-down) |
| 2 | Click on empty area | No unintended navigation |

#### TC-AD-77: Chart — Doughnut Animation On Load

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Refresh dashboard | Doughnut plays entrance animation |
| 2 | Segments animate from 0 to final value | Smooth easing |

### 6.9 AJAX Cascade Failure Scenarios

#### TC-AD-78: AJAX — Network Failure On Subject Load

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Disconnect network (offline mode) | AJAX fails |
| 2 | Select class | Subject dropdown shows error state |
| 3 | User sees fallback message | Failed to load subjects or similar |
| 4 | Reconnect, select class again | Subjects load correctly |

#### TC-AD-79: AJAX — Slow Response / Timeout

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate 10s+ server delay on subject endpoint | Loading indicator shown |
| 2 | Subject dropdown shows Loading... | User feedback |
| 3 | After response arrives | Dropdown populates correctly |
| 4 | No double submission | Only one request processed |

#### TC-AD-80: AJAX — Empty Response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class with no subjects | AJAX returns empty array |
| 2 | Subject dropdown shows No subjects available | Empty state |
| 3 | No JS errors | Graceful handling |

#### TC-AD-81: AJAX — Malformed Response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Server returns HTML instead of JSON | AJAX error handler catches |
| 2 | Subject dropdown shows fallback | All Subjects selected |
| 3 | Console error logged | Debug information available |

#### TC-AD-82: AJAX — Rapid Class Change (Race Condition)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Rapidly change class dropdown 5 times in 1 second | Only last request processed |
| 2 | No stale responses overwriting final state | Correct final subject list |
| 3 | Abort previous AJAX on each change | AbortController or flag pattern used |

#### TC-AD-83: AJAX — Server Returns 500 Error

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Server throws exception on subject endpoint | 500 response returned |
| 2 | Subject dropdown shows generic error | Graceful degradation |
| 3 | Dashboard filter form remains usable | No UI lockup |

#### TC-AD-84: AJAX — Concurrent Filter And Class Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Filter while class subject AJAX is in flight | Both requests handled independently |
| 2 | Dashboard reloads with latest filter state | No data inconsistency |

### 6.10 Permission Boundary Tests

#### TC-AD-85: Permission — Admin With Full Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with tenant.exam.viewAny | Dashboard loads fully |
| 2 | All 6 KPI cards visible | Full data access |
| 3 | All filters functional | No restrictions |

#### TC-AD-86: Permission — Teacher Role With Scoped Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher (owns specific classes) | Dashboard loads with teacher class data |
| 2 | Class dropdown shows only teacher classes | Scoped data |
| 3 | KPIs reflect teacher scope | Correct aggregation |

#### TC-AD-87: Permission — Student Role No Dashboard Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as student | No access to dashboard |
| 2 | Navigate to exam/dashboard | 403 Forbidden or redirect |
| 3 | Verify student cannot see any exam data | Proper authorization |

#### TC-AD-88: Permission — Cross-Tenant Data Isolation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login to Tenant A | Shows only Tenant A exam data |
| 2 | Login to Tenant B (different data) | Shows only Tenant B exam data |
| 3 | Verify no data leakage between tenants | Complete isolation |

#### TC-AD-89: Permission — Revoked Permission Mid-Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Admin revokes tenant.exam.viewAny for user | On next action, access denied |
| 2 | User performs filter action | 403 returned |
| 3 | Dashboard shows error state | Access denied message |

#### TC-AD-90: Permission — Department Head View

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as department head | Shows data for all classes in department |
| 2 | Verify scope includes multiple classes | Broader access than teacher |
| 3 | Cannot see other departments data | Proper boundary |

### 6.11 Performance Tests

#### TC-AD-91: Performance — Dashboard With 10K Exams

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 10,000 exams across 20 classes | Dashboard loads |
| 2 | KPI counts accurate | All aggregations correct |
| 3 | Page load time < 5 seconds | Acceptable performance |
| 4 | Charts render without freezing | Smooth interaction |

#### TC-AD-92: Performance — Dashboard With 50K+ Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 50,000 exam papers | Dashboard loads |
| 2 | Subject breakdown shows top 6 | Limit enforced |
| 3 | No memory leaks in browser | Stable performance |

#### TC-AD-93: Performance — Concurrent Filter Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply new filter every 500ms for 10 changes | All requests processed |
| 2 | Dashboard remains responsive | No UI freezes |
| 3 | Each filter correctly applied | Consistent final state |

#### TC-AD-94: Performance — Multiple Dashboard Tabs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open 5 dashboard tabs simultaneously | All load without error |
| 2 | Each tab has different tenant context | Independent data |
| 3 | Total server memory within limits | No OOM errors |

#### TC-AD-95: Performance — DB Query Optimization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enable query log | No N+1 queries |
| 2 | Verify eager loading | withCount, with used appropriately |
| 3 | Total queries < 20 per dashboard load | Optimized |

#### TC-AD-96: Performance — Large Dataset With All Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 10K exams, apply Class + Subject + Mode + Date filters | Filter response < 3 seconds |
| 2 | Verify count accuracy against DB query | Data integrity maintained |

#### TC-AD-97: Performance — Memory Usage With Chart.js

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load dashboard 20 times in same session | No progressive memory growth |
| 2 | Check Chrome DevTools Memory tab | Chart instances properly garbage collected |

### 6.12 Cross-Browser Tests

#### TC-AD-98: Browser — Google Chrome Latest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load dashboard in Chrome | All features work |
| 2 | Chart.js animations smooth | Hardware accelerated |
| 3 | Date range picker renders | Correct styling |
| 4 | AJAX cascades work | Subject loading functional |

#### TC-AD-99: Browser — Mozilla Firefox Latest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load dashboard in Firefox | All features work |
| 2 | CSS gradients render correctly | KPI card backgrounds visible |
| 3 | Chart tooltips positioned correctly | No offset issues |
| 4 | No console errors | Cross-browser compatibility |

#### TC-AD-100: Browser — Apple Safari Latest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load dashboard in Safari | All features work |
| 2 | Date range picker displays correctly | Safari-specific CSS handled |
| 3 | Charts render without WebGL issues | Canvas 2D fallback |
| 4 | Font rendering consistent | Fonts load correctly |

#### TC-AD-101: Browser — Microsoft Edge Latest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load dashboard in Edge | Chromium-based, similar to Chrome |
| 2 | All interactive elements work | Dropdowns, buttons, charts |
| 3 | No Edge-specific rendering issues | Consistent behavior |

#### TC-AD-102: Browser — Mobile Chrome Android

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load on Chrome Android | Responsive layout works |
| 2 | Touch events work | Dropdowns, buttons tappable |
| 3 | Date picker opens native picker | OS-native date widget |
| 4 | Chart touch interactions | Touch tooltips work |

#### TC-AD-103: Browser — Safari iOS

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load on Safari iOS | All features functional |
| 2 | Momentum scrolling on tables | Smooth scroll |
| 3 | No iOS zoom on input focus | Proper viewport meta |

### 6.13 Security Tests

#### TC-AD-104: Security — XSS In Filter Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit class_id = `<script>alert(xss)</script>` | Value sanitized or rejected |
| 2 | Submit subject_id with script tag | Escaped, no script execution |
| 3 | Submit mode with injected HTML | Proper input validation |

#### TC-AD-105: Security — SQL Injection Attempts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit class_id = `1; DROP TABLE lms_exams;--` | Eloquent parameter binding prevents injection |
| 2 | Submit date with SQL injection payload | Safe parsing |
| 3 | Subject filter with SQL injection | No injection possible |

#### TC-AD-106: Security — CSRF Protection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Intercept filter request, remove CSRF token | CSRF validation fails |
| 2 | Request rejected with 419 | Proper CSRF protection |
| 3 | Valid CSRF token present in all forms | Token rendered in page |

#### TC-AD-107: Security — IDOR Attempts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Teacher accesses class_id of another tenant class | No data returned |
| 2 | User modifies subject_id to access unauthorized data | Filtered by tenant scope |
| 3 | Attempt to view allocations for restricted exam | 403 or data omitted |

#### TC-AD-108: Security — Rate Limiting On Filter Endpoint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send 100 rapid filter requests | Rate limiting triggered |
| 2 | Subsequent requests return 429 | Too Many Requests |
| 3 | After rate limit window, requests succeed | Normal operation resumes |

#### TC-AD-109: Security — Mass Assignment Attempts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit unexpected filter parameters | Extra params ignored |
| 2 | Submit _token with invalid value | Request rejected |
| 3 | No unintended side effects | Dashboard state unchanged |

### 6.14 Date Range Edge Cases

#### TC-AD-110: Date — Month Boundary Crossing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date range: Jan 31 - Feb 1 | Data from both months included |
| 2 | Verify exams on Jan 31 included | Lower boundary included |
| 3 | Verify exams on Feb 1 included | Upper boundary included |

#### TC-AD-111: Date — Year Boundary Crossing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date range: Dec 30 - Jan 5 (cross-year) | Data from December AND January |
| 2 | Verify exams on Dec 31 included | Year boundary crossed correctly |
| 3 | Verify exams on Jan 1 included | Correct year recognition |

#### TC-AD-112: Date — Leap Year Feb 29

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date range including Feb 29 of leap year | Feb 29 data included |
| 2 | Non-leap year: Feb 28 included, Feb 29 not available | Correct handling |
| 3 | Verify This Month in February of leap year | Feb 29 appears |

#### TC-AD-113: Date — Timezone Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Server timezone UTC, user timezone EST | Dates convert correctly |
| 2 | Exam created at 11:59 PM EST on Jan 1 | Appears in Jan 1 or Jan 2 based on timezone |
| 3 | Date range picker uses user local timezone | Correct date boundaries |

#### TC-AD-114: Date — Extremely Large Date Range (10 Years)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date range spanning 10 years (2020-2030) | All data in range returned |
| 2 | KPIs aggregate correctly over large range | No performance degradation |
| 3 | Monthly activity chart adjusts | Shows more months or normalizes |

#### TC-AD-115: Date — Future Date Range With Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exams with future start dates | Data exists in future |
| 2 | Set date range covering those future dates | Future exams shown in dashboard |
| 3 | Recent exams include future exams | Sorted correctly by start_date |

#### TC-AD-116: Date — Single Day Range (Today)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date_from = date_to = today | Only today data shown |
| 2 | Verify KPIs match today only | Correct aggregation |

#### TC-AD-117: Date — Date Range With Only Start Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date_from only, leave date_to empty | All data from start date to infinity |
| 2 | Verify behavior (may default to today) | Consistent |

#### TC-AD-118: Date — Date Range With Only End Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave date_from empty, set date_to only | All data up to end date |
| 2 | Verify behavior (may default to epoch) | Consistent |

### 6.15 Empty / Partial Data Combinations

#### TC-AD-119: Data — Only Online Exams Exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Only ONLINE papers in system | Mode split: 100% Online, 0% Offline |
| 2 | Mode filter All shows all data | Both counts correct |
| 3 | Mode filter Offline shows 0 | Empty data state |

#### TC-AD-120: Data — Only Offline Exams Exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Only OFFLINE papers in system | Mode split: 0% Online, 100% Offline |
| 2 | All KPIs reflect only offline data | Consistent |

#### TC-AD-121: Data — Only Future Exams

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All exams start 30+ days in future | Dashboard with future data |
| 2 | Monthly activity shows creation months | Papers created in past months |
| 3 | Recent exams shows future exams | Sorted by start_date desc |

#### TC-AD-122: Data — Only Past / Concluded Exams

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All exams concluded or archived | Dashboard shows historical data |
| 2 | Status badges show CONCLUDED or ARCHIVED | Correct coloring |
| 3 | KPIs reflect historical counts | All data accurate |

#### TC-AD-123: Data — Single Exam With Multiple Papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 1 exam with 20 papers across 3 subjects | Total Exams = 1, Papers = 20 |
| 2 | Subject breakdown shows 3 subjects | Top 1 may be the only entry |

#### TC-AD-124: Data — No Allocations Exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Exams and papers exist, but 0 allocations | Allocations KPI = 0 |
| 2 | Doughnut center shows 0 | Correct empty state |
| 3 | Submitted and Evaluated KPIs = 0 | Consistent |

#### TC-AD-125: Data — All Submitted, None Evaluated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 100 allocations, 100 submitted, 0 evaluated | Submitted = 100, Evaluated = 0, Pending = 100 |
| 2 | Doughnut: Submitted 100%, Evaluated 0%, Pending 0% | Correct segment proportions |

#### TC-AD-126: Data — All Students Evaluated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 100 allocations, 100 submitted, 100 evaluated | Submitted = 100, Evaluated = 100, Pending = 0 |
| 2 | Doughnut: Evaluated 100% of submitted | Correct segment display |

#### TC-AD-127: Data — Single Subject With All Exams

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Subject X has 50 exams, all others have 0 | Subject breakdown shows Subject X only |
| 2 | Class breakdown shows classes involved | Correct cross-section |

### 6.16 Integration With Other Tabs

#### TC-AD-128: Integration — Navigate To Creation Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click View All in Recent Exams | Navigates to creation tab |
| 2 | URL changes to active_tab=exam_creation | Correct tab active |
| 3 | Creation page loads with exam list | Seamless transition |

#### TC-AD-129: Integration — Tab Switch Preserves Independent State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set Dashboard filters: Class A, Mode Online | Filters set on Dashboard |
| 2 | Switch to Summary tab | Summary loads with its own independent state |
| 3 | Switch back to Dashboard | Dashboard filters may reset (design-dependent) |

#### TC-AD-130: Integration — Exam Creation Reflects On Dashboard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Creation tab | Creation form visible |
| 2 | Create new exam | Exam saved |
| 3 | Switch back to Dashboard | Total Exams KPI incremented |
| 4 | Recent Exams shows new exam at top | Correct ordering |

#### TC-AD-131: Integration — Bulk Delete From List Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Exam List tab | Exam list shown |
| 2 | Delete 3 exams | Exams removed |
| 3 | Return to Dashboard | KPIs decreased by 3 |
| 4 | Recent Exams updated | Deleted exams removed |

#### TC-AD-132: Integration — Dashboard URL Bookmarking

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set filters on Dashboard | URL updates with query params |
| 2 | Copy URL, open in new tab | Filters restored from URL params |
| 3 | Verify all KPIs match filtered state | Bookmark works correctly |

#### TC-AD-133: Integration — Browser Back / Forward Navigation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filter on Dashboard | Dashboard loads with filter |
| 2 | Navigate to another tab | Other tab loads |
| 3 | Press browser Back button | Returns to Dashboard with previous filter state |

#### TC-AD-134: Integration — Student Submission From Exam Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student submits exam from Student Exam tab | Submission recorded |
| 2 | Navigate to Dashboard | Submitted KPI increased |
| 3 | Pending Eval recalculated | submitted - evaluated |

#### TC-AD-135: Integration — Teacher Evaluation From Evaluation Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Teacher evaluates 10 submissions from Evaluation tab | Evaluated KPI increases by 10 |
| 2 | Navigate to Dashboard | Pending Eval decreases by 10 |
| 3 | All other KPIs unchanged | Only evaluated and pending affected |

(End of file)