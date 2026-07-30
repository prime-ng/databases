# slb_overview_dashboard_TcList

## Module: Syllabus → Reports → Overview Dashboard

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Reports |
| Feature | Overview Dashboard |
| URL(s) | `/syllabus/report?tab=dashboard` (report.index) |
| Controller | `Modules\Syllabus\Http\Controllers\SyllabusController@report()` |
| Model(s) | `Modules\Syllabus\Models\SyllabusSchedule` |
| Permissions | `tenant.syllabus-view-dashboard.viewAny` |
| Policy | `SyllabusReportPolicy::viewDashboard()` |
| View Partial | `resources/views/report/partials/dashboard.blade.php` |

---

## 2. Pre-conditions

- Required permissions: `tenant.syllabus-view-dashboard.viewAny`
- Required seed data: At least one active `OrganizationAcademicSession`, one active `SchoolClass`, one active `Subject`, one active `SyllabusSchedule` record with various `is_active` states
- Test user must have the above permission (default admin user or user assigned via role)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Dashboard requires at least one syllabus schedule record with `scheduled_start_date` and `scheduled_end_date` set for meaningful widget data

---



---

## 3. Default Data Load

When the page loads via SyllabusController@report() (GET /syllabus/report), the following data is fetched:

| Tab | Data Loaded | Source | Filters | Pagination |
|-----|------------|--------|---------|------------|
| All | Shared dropdowns: classes, subjects, academicSessions | SchoolClass::where(is_active,1)->orderBy(ordinal), Subject::where(is_active,1)->orderBy(name), OrganizationAcademicSession::where(is_active,1)->orderBy(name,DESC) | is_active=1 | None |
| All | Dashboard Stats (total, released, overdue, progress %) | SyllabusSchedule::selectRaw(COUNT,SUM) with CASE | academic_session_id, class_id, subject_id | None (single agg row) |
| All | Coverage Bar Chart (subject-wise) | SyllabusSchedule::join(sch_subjects)->selectRaw(COUNT,SUM)->groupBy(subject) | Same scoped filters | None |
| All | Completion Trend (last 15 days) | SyllabusSchedule::where(is_active,1)->where(updated_at,>=,15 days ago)->groupBy(DATE) | Same + is_active=1 | None |
| All | Class-wise Completion | SyllabusSchedule::join(sch_classes)->selectRaw(COUNT,SUM)->groupBy(class) | Same scoped filters | None |
| All | Status Distribution (On Track / Overdue / Released) | Derived from stats aggregation (no extra query) | Same | None |
| Dashboard | Recent Activity (last 10 completed) | SyllabusSchedule::with(topic,lesson,class,subject)->where(is_active,1)->latest(updated_at)->limit(10) | Same + is_active=1 | None (limit 10) |
| Progress Tracker | Grouped progress data | SyllabusSchedule::selectRaw(COUNT,SUM,COALESCE)->with(class,subject)->groupBy(class,subject) | Same scoped filters | 10/page (progress_page) |
| Coverage Audit | Schedule audit with start dates | SyllabusSchedule::with(class,subject,lesson,topic)->whereNotNull(scheduled_start_date)->orderBy(scheduled_start_date) | Same + has start_date | 10/page (audit_page) |
| Resource Matrix | Schedule with topic competencies | SyllabusSchedule::with(class,subject,lesson,topic.competencies) | Same scoped filters | 10/page (matrix_page) |
| Planning Accuracy | Schedule with variance calculation | SyllabusSchedule::selectRaw(DATEDIFF)->where(is_active,1)->whereNotNull(scheduled_end_date)->with(class,subject,lesson,topic,assignedTeacher.user) | Same + is_active=1 + has end_date | 10/page (accuracy_page) |
| Planning Accuracy | Accuracy breakdown (full dataset) | SyllabusSchedule::selectRaw(SUM,CASE) for on_time/slightly_late/very_late | Same + is_active=1 + has end_date | None |
| Planning Accuracy | Teacher accuracy ranking (top 10) | SyllabusSchedule::where(is_active,1)->whereNotNull(assigned_teacher_id)->with(assignedTeacher.user)->get()->groupBy(assigned_teacher_id) | Same + has teacher | None (top 10) |
## 4. Test Data Strategy

- **Stat cards**: Seed syllabus schedule records with varying `is_active` values — some released (`is_active=1`), some overdue (`is_active=0 AND scheduled_end_date < today`), some pending
- **Subject coverage**: Seed records across at least 3 different `subject_id` values with different completion ratios
- **Trend data**: Seed records with `updated_at` spread across the last 15 days with varying `is_active` states
- **Class progress**: Seed records for at least 2 different `class_id` values with different `total` and `completed` distributions
- **Status distribution**: Ensure a mix of `On Track`, `Overdue`, and `Released` statuses in the dataset
- **Recent completions**: Ensure at least 10 recently released records exist with eager-loaded `topic`, `lesson`, `class`, `subject` relations
- **Empty state**: Create a separate academic session with zero syllabus schedule records
- **Pre-test cleanup**: Delete created records before/after tests to avoid collisions

---

## 5. Business Conditions

### 4.1 Database Schema — `slb_syllabus_schedule`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | academic_session_id | INT UNSIGNED | NOT NULL, FK → `sch_org_academic_sessions_jnt.id` |
| BC-DB-03 | class_id | INT UNSIGNED | NOT NULL, FK → `sch_classes.id` |
| BC-DB-04 | subject_id | INT UNSIGNED | NOT NULL, FK → `sch_subjects.id` |
| BC-DB-05 | lesson_id | INT UNSIGNED | NOT NULL, FK → `slb_lessons.id` |
| BC-DB-06 | topic_id | INT UNSIGNED | NOT NULL, FK → `slb_topics.id` |
| BC-DB-07 | assigned_teacher_id | INT UNSIGNED | NULLABLE, FK → `sch_employees.id` |
| BC-DB-08 | scheduled_start_date | DATE | NULLABLE |
| BC-DB-09 | scheduled_end_date | DATE | NULLABLE |
| BC-DB-10 | planned_periods | SMALLINT UNSIGNED | DEFAULT NULL |
| BC-DB-11 | is_active | TINYINT(1) | NOT NULL DEFAULT 0 (completion flag) |
| BC-DB-12 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-13 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

### 4.2 Authorization (Policy Gates)

| BC ID | Permission | Policy Method | Behavior |
|-------|-----------|---------------|----------|
| BC-AUTH-01 | tenant.syllabus-view-dashboard.viewAny | viewDashboard() | Without → 403 Forbidden on `/report?tab=dashboard` |

### 4.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | `$stats` single-query aggregation | Returns associative array with `total_topics`, `released`, `overdue`, `progress` computed via `selectRaw` |
| BC-BIZ-02 | `progress` percentage formula | `(released / total_topics) * 100` — if `total_topics=0`, progress defaults to 0 |
| BC-BIZ-03 | `$subjectCoverage` grouping | JOIN `sch_subjects`, GROUP BY `subject_id`, returns `total` + `released` + derived percentage per subject |
| BC-BIZ-04 | `$trendData` last 15 days | GROUP BY `DATE(updated_at)`, count released records per day; gaps return empty/zero for missing dates |
| BC-BIZ-05 | `$classProgress` grouping | GROUP BY `class_id` (JOIN `sch_classes`), shows `total` and `completed` counts per class |
| BC-BIZ-06 | `$statusDistribution` categories | Associative array with keys `On Track`, `Overdue`, `Released` — derived from `is_active` and date comparison |
| BC-BIZ-07 | `$recentCompletions` limit | Last 10 released records ordered by `updated_at DESC`, eager-loaded with `topic`, `lesson`, `class`, `subject` |
| BC-BIZ-08 | `$applyFilters` closure | Conditionally adds `WHERE` clauses for `academic_session_id`, `class_id`, `subject_id` from query params |
| BC-BIZ-09 | Dashboard widget rendering | 6 stat cards, subject coverage chart, 15-day trend chart, class progress table, status distribution, recent completions list all render in dashboard.blade.php |
| BC-BIZ-10 | Role-based data scoping | Principal sees all data; HOD sees department-filtered; Teacher sees own sections only |
| BC-BIZ-11 | Empty academic session | All widgets show empty/zero state when no syllabus schedule records exist for selected scope |
| BC-BIZ-12 | Screen loads via SyllabusController@report() at GET /syllabus/report with report tab group | Navigating to GET /syllabus/report with appropriate permissions loads the Report tab group; this screen's data is fetched and displayed |

### 4.4 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | academic_session_id | sch_org_academic_sessions_jnt (id) | RESTRICT |
| BC-REF-02 | class_id | sch_classes (id) | CASCADE |
| BC-REF-03 | subject_id | sch_subjects (id) | CASCADE |
| BC-REF-04 | lesson_id | slb_lessons (id) | CASCADE |
| BC-REF-05 | topic_id | slb_topics (id) | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Dashboard page loads with all UI elements | Page loads at `/report?tab=dashboard` with 6 stat cards, charts, tables, and filter bar | — | — | ⬜ |
| TC-P02 | Stat cards display correct aggregated values | `total_topics`, `released`, `overdue`, `progress` all show correct computed values from seed data | — | — | ⬜ |
| TC-P03 | Subject coverage chart renders with grouped data | Bar chart shows each subject with `total` and `released` bars; percentage labels visible | — | — | ⬜ |
| TC-P04 | 15-day trend chart displays daily released counts | Line/bar chart shows count of released records for each of the last 15 days | — | — | ⬜ |
| TC-P05 | Class progress table shows correct per-class data | Table lists each class with `total` and `completed` topic counts sorted by class name | — | — | ⬜ |
| TC-P06 | Status distribution renders correctly | Donut/pie chart or summary shows `On Track`, `Overdue`, `Released` counts matching seed data | — | — | ⬜ |
| TC-P07 | Recent completions list shows last 10 released records | Ordered list shows 10 most recently updated active records with topic, lesson, class, subject names | — | — | ⬜ |
| TC-P08 | Filter dashboard by class | Selecting a class from dropdown reloads page with `?class_id=X`; widgets update to show only that class data | — | — | ⬜ |
| TC-P09 | Filter dashboard by class + subject | Both class and subject filters applied; widgets scope to matching combination | — | — | ⬜ |
| TC-P10 | Dashboard loads with different academic session | Selecting a different academic session scopes all widget data to that session | — | — | ⬜ |
| TC-P11 | Progress percentage calculation correctness | Verify `progress = (released / total_topics) * 100` matches manual calculation from seed data | — | — | ⬜ |
| TC-P12 | Dashboard refresh updates stale data | After adding/updating schedule records, refreshing dashboard shows updated widget values | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Permission 403 — No viewDashboard permission | User without `tenant.syllabus-view-dashboard.viewAny` gets 403 Forbidden on `/report?tab=dashboard` | — | — | ⬜ |
| TC-N02 | Guest access redirect | Unauthenticated user navigating to `/report` redirected to login page | — | — | ⬜ |
| TC-N03 | Empty state — no syllabus schedule records | All widgets show zero/empty state with appropriate empty messages; no errors | — | — | ⬜ |
| TC-N04 | Empty state — no active academic session | Error message: "No active academic session found. Please activate a session in Academic Setup before using the dashboard." | — | — | ⬜ |
| TC-N05 | Filter with no matching data | Selecting a class/subject with zero schedule records shows empty widgets, no chart rendering errors | — | — | ⬜ |
| TC-N06 | Division by zero edge case (total_topics=0) | Progress stat shows 0% or "N/A" instead of division error; no 500 error | — | — | ⬜ |
| TC-N07 | Role-based scoping — Teacher sees only own data | Teacher user sees only their assigned sections' data in widgets; other sections not visible | — | — | ⬜ |
| TC-N08 | Role-based scoping — HOD sees department subjects only | HOD user sees widgets scoped to their department's subjects; subjects outside department hidden | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Dashboard data reflects newly created schedule records | Creating a new released schedule record and refreshing dashboard updates stat counts accordingly | — | — | ⬜ |
| TC-D02 | A | Dashboard reflects soft-deleted schedule records | Soft-deleting a schedule record removes it from aggregation queries' scope | — | — | ⬜ |
| TC-D03 | B | Filter scoping with invalid class_id parameter | Passing `?class_id=99999` returns empty widgets or appropriate message, no 500 error | — | — | ⬜ |
| TC-D04 | C | Large dataset performance (10,000+ records) | All widgets load within acceptable time; pagination handles dataset size | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based tab visibility via viewAny | Report tabs are conditionally rendered via @can('tenant.syllabus-view-dashboard.viewAny') and nav-tab permission attribute; users without viewAny permission cannot see this tab | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | `syllabus.report` key → `'syllabus/report'` defined in `config/breadcrumb.php`; breadcrumb visible and links correctly to parent screen | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Relationship expressions in Blade use isset($var->relation) / optional($var?->relation) / null-safe operator; no undefined index/property errors when relation is null | — | — | ◌ |


---



## 7. Detailed Test Steps



#### TC-CR05: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open report partial blade for this screen | View file found in report/partials/
| 2 | Scan for relationship access patterns (e.g. $record->relation->field) | All such expressions use isset() or optional() or ?-> null-safe operator
| 3 | Scan for foreach loops over relationships | Loop target checked with isset() or !empty() before iterating
| 4 | Load report with records that have missing relations | No 500 errors; null values displayed gracefully (dash or empty string)


#### TC-CR01: Blade @can Directives — Permission-based Tab Visibility via viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect report/index.blade.php | Tab is conditionally rendered via @can('tenant.syllabus-view-dashboard.viewAny')
| 2 | Check nav-tab component permission attribute | Tab's permission parameter matches 'tenant.syllabus-view-dashboard.viewAny'
| 3 | Log in as user with viewAny permission | Overview Dashboard tab visible in Report section |
| 4 | Log in as user without viewAny permission | Overview Dashboard tab hidden; user cannot access this report |

#### TC-CR02: Breadcrumb Config — Route Registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File contains routing configuration for the syllabus module |
| 2 | Verify the 'syllabus.report' key exists | Config has 'syllabus.report' => 'syllabus/report' entry
| 3 | Verify its value points to the correct parent screen URL | Value 'syllabus/report' correctly references Report tab view
| 4 | Load the screen via the Report tab tab | Breadcrumb trail shows correct hierarchy and highlights current screen |
| 5 | Click the breadcrumb parent link | Navigates correctly to Report tab page without errors |
### 6.1 Positive TC Steps

#### TC-P01: Dashboard Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Expand "Syllabus" from left sidebar | Menu options appear |
| 3 | Click "Reports" and select "Overview Dashboard" tab | Page loads at `/report?tab=dashboard` |
| 4 | Check page title/heading | "Overview Dashboard" or equivalent heading |
| 5 | Check the filter bar | Filter dropdowns for Academic Session, Class, Subject present |
| 6 | Check the stat cards section | 6 stat cards visible: Total Topics, Released, Overdue, Progress %, etc. |
| 7 | Check the subject coverage chart | Bar chart canvas/container visible |
| 8 | Check the 15-day trend chart | Trend chart container visible |
| 9 | Check the class progress table | Table with columns: Class, Total Topics, Completed Topics |
| 10 | Check the status distribution | Donut/pie chart or summary visible |
| 11 | Check the recent completions list | List of 10 most recent completions with topic/lesson/class/subject |

---

#### TC-P02: Stat Cards Display Correct Aggregated Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 50 syllabus schedule records: 30 released (is_active=1), 10 overdue (is_active=0, end_date < now), 10 pending | Fixed dataset |
| 2 | Navigate to `/report?tab=dashboard` | Dashboard loads |
| 3 | Read Total Topics stat card | Shows 50 |
| 4 | Read Released stat card | Shows 30 |
| 5 | Read Overdue stat card | Shows 10 |
| 6 | Read Progress % stat card | Shows 60% (30/50 * 100) |
| 7 | Verify remaining stat cards (if any) display correct values | Values match seed data |

---

#### TC-P03: Subject Coverage Chart Renders With Grouped Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed schedule records: Subject A (20 total, 15 released), Subject B (30 total, 10 released), Subject C (10 total, 8 released) | 3 subjects with different ratios |
| 2 | Navigate to dashboard | Page loads |
| 3 | Check subject coverage chart | Chart rendered with 3 groups |
| 4 | Verify Subject A bar shows total=20, released=15 | Correct bar heights |
| 5 | Verify Subject B bar shows total=30, released=10 | Correct bar heights |
| 6 | Verify Subject C bar shows total=10, released=8 | Correct bar heights |
| 7 | Hover over each bar | Tooltip displays exact values |

---

#### TC-P04: 15-Day Trend Chart Displays Daily Released Counts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed schedule records with updated_at spread: Day-15: 5 releases, Day-10: 3 releases, Day-5: 8 releases, Today: 2 releases | Records over 15-day window |
| 2 | Navigate to dashboard | Page loads |
| 3 | Check trend chart | Line/bar chart shows 15 data points |
| 4 | Verify Day-15 data point | Shows 5 |
| 5 | Verify Day-10 data point | Shows 3 |
| 6 | Verify Day-5 data point | Shows 8 |
| 7 | Verify Today data point | Shows 2 |
| 8 | Verify days with no releases | Days without releases shown as 0 or gap in line |

---

#### TC-P05: Class Progress Table Shows Correct Per-Class Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed records: Class 9 (40 total, 25 completed), Class 10 (30 total, 20 completed), Class 11 (50 total, 35 completed) | 3 classes |
| 2 | Navigate to dashboard | Page loads |
| 3 | Check class progress table | Table with rows for Class 9, 10, 11 |
| 4 | Verify Class 9 row: total=40, completed=25 | Correct values |
| 5 | Verify Class 10 row: total=30, completed=20 | Correct values |
| 6 | Verify Class 11 row: total=50, completed=35 | Correct values |
| 7 | Verify table sorted by class name | Order: Class 9, Class 10, Class 11 |

---

#### TC-P06: Status Distribution Renders Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed records: 25 On Track (active, end_date >= now), 10 Overdue (active=0 OR end_date < now), 15 Released (is_active=1) | Mixed status dataset |
| 2 | Navigate to dashboard | Page loads |
| 3 | Check status distribution widget | Shows 3 categories |
| 4 | Verify On Track count | Shows 25 |
| 5 | Verify Overdue count | Shows 10 |
| 6 | Verify Released count | Shows 15 |

---

#### TC-P07: Recent Completions List Shows Last 10 Released Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 15 released records with updated_at timestamps spread across last week | 15 records |
| 2 | Navigate to dashboard | Page loads |
| 3 | Check recent completions list | Shows exactly 10 records |
| 4 | Verify records ordered by most recent first | Newest updated_at at top |
| 5 | Verify each record shows topic name, lesson name, class name, subject name | All 4 fields visible per record |
| 6 | Click on a recent completion item | Drills into detail or links to progress tracker |

---

#### TC-P08: Filter Dashboard By Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed records: Class A (30 total), Class B (20 total) | 2 classes |
| 2 | Navigate to dashboard | All-class view shows 50 total topics |
| 3 | Select "Class A" from class filter dropdown | Page reloads with `?class_id={A_id}` |
| 4 | Verify stat cards reflect only Class A data | Total Topics = 30 |
| 5 | Verify subject coverage shows Class A subjects only | Only Class A subjects visible |
| 6 | Verify class progress table shows only Class A | Single row for Class A |
| 7 | Clear filter, select "Class B" | Widgets scope to Class B data |

---

#### TC-P09: Filter Dashboard By Class + Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed records: Class A / Subject X (15 topics), Class A / Subject Y (10 topics), Class B / Subject X (8 topics) | Mixed dataset |
| 2 | Select Class A from filter | Widgets scope to Class A (25 topics total) |
| 3 | Also select Subject X from filter | Page reloads with both params |
| 4 | Verify stat cards show only Class A + Subject X data | Total Topics = 15 |
| 5 | Verify subject coverage chart shows only Subject X | Single subject bar |
| 6 | Clear subject filter | Returns to Class A wide view (25 topics) |

---

#### TC-P10: Dashboard Loads With Different Academic Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Academic Session 2025-26 with 40 schedule records and Academic Session 2026-27 with 25 records | Two sessions with data |
| 2 | Navigate to dashboard with Session 2025-26 selected | Total Topics = 40 |
| 3 | Switch to Session 2026-27 | Total Topics = 25 |
| 4 | All widgets reflect the selected session's data | Charts/tables update |

---

#### TC-P11: Progress Percentage Calculation Correctness

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: total=80, released=60 | Dataset |
| 2 | Calculate expected: (60/80)*100 = 75% | — |
| 3 | Navigate to dashboard | Progress stat = 75% |
| 4 | Seed: total=0, released=0 | Empty dataset |
| 5 | Navigate to dashboard | Progress stat = 0% or "N/A" — no division error |

---

#### TC-P12: Dashboard Refresh Updates Stale Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to dashboard with 30 released records | Progress stat shows 30 released |
| 2 | In another tab, create 5 more released schedule records | Records added |
| 3 | Refresh dashboard page | Progress stat now shows 35 released |
| 4 | Verify all other widgets reflect updated data | Charts/tables updated |

---

### 6.2 Negative TC Steps

#### TC-N01: Permission 403 — No viewDashboard Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.syllabus-view-dashboard.viewAny` permission | Dashboard loads (other tabs may be visible) |
| 2 | Navigate to `/report?tab=dashboard` | 403 Forbidden or tab hidden from UI |
| 3 | Verify dashboard tab not displayed in report tab bar | Tab excluded from user's visible tabs |

---

#### TC-N02: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout completely | — |
| 2 | Navigate to `/report?tab=dashboard` | Redirected to login page |
| 3 | Try any other report route | Redirected to login |

---

#### TC-N03: Empty State — No Syllabus Schedule Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure academic session has zero syllabus schedule records | No data exists |
| 2 | Navigate to dashboard | Page loads without errors |
| 3 | Verify stat cards show 0 or empty state | Total Topics = 0, Released = 0, Overdue = 0 |
| 4 | Verify charts show empty/no data state | Subject coverage chart empty, trend chart empty |
| 5 | Verify tables show "No data" message | Class progress table shows empty message |
| 6 | Verify recent completions shows "No recent completions" | Empty list message |

---

#### TC-N04: Empty State — No Active Academic Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Deactivate or remove all academic sessions | No active session |
| 2 | Navigate to dashboard | Error message displayed: "No active academic session found." |
| 3 | Dashboard widgets hidden or disabled | Cannot load data without session |

---

#### TC-N05: Filter With No Matching Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed records only for Class A | No data for other classes |
| 2 | Select Class B from filter | Page reloads |
| 3 | Verify all widgets show empty/zero state | No data messages visible |
| 4 | Verify no chart rendering JavaScript errors | Console shows no errors |

---

#### TC-N06: Division By Zero Edge Case (total_topics=0)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure total_topics aggregation returns 0 | No schedule records |
| 2 | Navigate to dashboard | Progress stat displays 0% — no 500 error |
| 3 | Check server logs for division by zero errors | None logged |
| 4 | Check browser console for JS errors | None |

---

#### TC-N07: Role-Based Scoping — Teacher Sees Only Own Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed records: Teacher T1 has 30 records, Teacher T2 has 20 records | Data for 2 teachers |
| 2 | Login as Teacher T1 | Dashboard loads |
| 3 | Verify Total Topics stat shows 30 (not 50) | Scoped to T1 only |
| 4 | Verify class progress shows only T1's classes | T2's classes not visible |
| 5 | Verify recent completions shows only T1's completions | T2's completions excluded |

---

#### TC-N08: Role-Based Scoping — HOD Sees Department Subjects Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed records: Department D1 Sciences (Physics, Chemistry), Department D2 Arts (History, Geography) | Two departments |
| 2 | Login as HOD of D1 (Sciences) | Dashboard loads |
| 3 | Verify subject coverage shows only Physics and Chemistry | History, Geography not visible |
| 4 | Verify class progress shows only D1's classes | D2 classes excluded |
| 5 | All widget data scoped to HOD's department | Consistent scope |

---

### 6.3 Dependency TC Steps

#### TC-D01: Dashboard Reflects Newly Created Schedule Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to dashboard — note current Released count | Released = X |
| 2 | Create 5 new released schedule records via API or direct DB insert | Records created |
| 3 | Refresh dashboard | Released = X + 5 |
| 4 | Verify stat cards, charts, recent completions all updated | All widgets reflect new data |

---

#### TC-D02: Dashboard Reflects Soft-Deleted Schedule Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to dashboard — note current Total Topics | Total = X |
| 2 | Soft-delete 3 schedule records that were in the scope | Records deleted |
| 3 | Refresh dashboard | Total = X - 3 |
| 4 | Verify all aggregated counts exclude soft-deleted records | Consistent decrease |

---

#### TC-D03: Filter Scoping With Invalid class_id Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/report?tab=dashboard&class_id=99999` | Page loads without 500 error |
| 2 | Verify widgets show empty state | No data for non-existent class |
| 3 | Apply similarly invalid subject_id | Same graceful empty state |

---

#### TC-D04: Large Dataset Performance (10,000+ Records)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 10,000+ schedule records across multiple classes, subjects, dates | Large dataset |
| 2 | Navigate to dashboard | Page loads within acceptable time (< 5s) |
| 3 | Verify all aggregations compute correctly | Stats match expected values |
| 4 | Verify charts render without browser freezing | Charts display correctly |
| 5 | Test filter with large dataset scoping | Filter returns quickly with scoped data |
