# slb_planning_accuracy_TcList

## Module: Syllabus → Reports → Planning Accuracy

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Reports |
| Feature | Planning Accuracy |
| URL(s) | `/syllabus/report?tab=planning_accuracy` (report.index) |
| Controller | `Modules\Syllabus\Http\Controllers\SyllabusController@report()` |
| Model(s) | `Modules\Syllabus\Models\SyllabusSchedule` |
| Permissions | `tenant.view-teacher-accuracy.viewAny` |
| Policy | `SyllabusReportPolicy::viewTeacherAccuracy()` |
| View Partial | `resources/views/report/partials/teacher_accuracy.blade.php` |
| Pagination | 10 per page, page name `accuracy_page` |

---

## 2. Pre-conditions

- Required permissions: `tenant.view-teacher-accuracy.viewAny`
- Required seed data: At least one active `OrganizationAcademicSession`, multiple `SchoolClass`, `Subject`, `Lesson`, `Topic`, `SyllabusSchedule` records with `is_active=1` AND `scheduled_end_date IS NOT NULL`
- Test user must have the above permission (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Planning Accuracy requires records where `is_active=1` (completed) and `scheduled_end_date` is set for variance calculation

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

- **Variance data**: Seed schedule records with different DATEDIFF values between `updated_at` (or completed date) and `scheduled_end_date`:
  - On time: variance <= 0 days (completed early or on time)
  - Slightly late: variance between 1 and 3 days
  - Very late: variance >= 4 days
- **Teacher assignment**: Each record must reference an `assigned_teacher_id` linked to `sch_employees` with a `user` relation for `$teacherPerformance` ranking
- **Ranking data**: Seed at least 12 teachers with varying accuracy percentages (some high, some low) to test top 10 ranking
- **Pagination**: Seed at least 25 records across multiple classes/subjects to test 10-per-page pagination
- **Filters**: Data spanning at least 2 classes and multiple subjects
- **Empty state**: A scope with zero completed records
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
| BC-DB-09 | scheduled_end_date | DATE | NOT NULL for accuracy calculation |
| BC-DB-10 | planned_periods | SMALLINT UNSIGNED | DEFAULT NULL |
| BC-DB-11 | is_active | TINYINT(1) | NOT NULL DEFAULT 0 — must be 1 for accuracy calculation |
| BC-DB-12 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-13 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

### 4.2 Authorization (Policy Gates)

| BC ID | Permission | Policy Method | Behavior |
|-------|-----------|---------------|----------|
| BC-AUTH-01 | tenant.view-teacher-accuracy.viewAny | viewTeacherAccuracy() | Without → 403 Forbidden on `/report?tab=planning_accuracy` |

### 4.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | `$accuracyData` query | Selects `DATEDIFF(updated_at, scheduled_end_date) as variance_days` where `is_active=1` AND `scheduled_end_date IS NOT NULL` |
| BC-BIZ-02 | Eager-load teacher relations | Loads `assignedTeacher.user` to display teacher names |
| BC-BIZ-03 | Paginated at 10 per page (`accuracy_page`) | Results split into pages |
| BC-BIZ-04 | `$accuracyBreakdown` aggregate (unpaginated) | Full dataset (not paginated) grouped into `on_time` (variance <= 0), `slightly_late` (1-3), `very_late` (>= 4) |
| BC-BIZ-05 | `$teacherPerformance` top 10 ranking | Groups by `assigned_teacher_id`, calculates on-time percentage, sorts DESC, limits 10 |
| BC-BIZ-06 | `$onTimeCount` | Count of accuracy rows where variance_days <= 0 |
| BC-BIZ-07 | `$avgVariance` | Average of `variance_days` rounded to 1 decimal place |
| BC-BIZ-08 | `$applyFilters` closure | Adds `WHERE` clauses for `academic_session_id`, `class_id`, `subject_id` from query params |
| BC-BIZ-09 | Screen loads via SyllabusController@report() at GET /syllabus/report with report tab group | Navigating to GET /syllabus/report with appropriate permissions loads the Report tab group; this screen's data is fetched and displayed |

### 4.4 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | academic_session_id | sch_org_academic_sessions_jnt (id) | RESTRICT |
| BC-REF-02 | class_id | sch_classes (id) | CASCADE |
| BC-REF-03 | subject_id | sch_subjects (id) | CASCADE |
| BC-REF-04 | lesson_id | slb_lessons (id) | CASCADE |
| BC-REF-05 | topic_id | slb_topics (id) | CASCADE |
| BC-REF-06 | assigned_teacher_id | sch_employees (id) | SET NULL |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Planning accuracy page loads with all UI elements | Page loads at `/report?tab=planning_accuracy` with filter bar, accuracy table, breakdown chart, and teacher ranking | — | — | ⬜ |
| TC-P02 | Accuracy table displays correct columns | Columns: Teacher, On Time %, Late %, Avg Variance (Days), Total Topics | — | — | ⬜ |
| TC-P03 | Variance day calculation correctness | `DATEDIFF(updated_at, scheduled_end_date)` correctly computed for each record | — | — | ⬜ |
| TC-P04 | Accuracy breakdown distribution correct | `on_time`, `slightly_late`, `very_late` counts sum to total records and match seed data | — | — | ⬜ |
| TC-P05 | Teacher ranking ordered by accuracy descending | Top 10 teachers sorted by on-time completion % from highest to lowest | — | — | ⬜ |
| TC-P06 | onTimeCount and avgVariance summary cards | Summary cards show correct count of on-time records and average variance (1 decimal) | — | — | ⬜ |
| TC-P07 | Filter by date range | Selecting date range scopes accuracy data to records within that range | — | — | ⬜ |
| TC-P08 | Filter by class scopes data | Class filter limits records to that class only | — | — | ⬜ |
| TC-P09 | Filter by class + subject | Combined filter scopes to specific class+subject combination | — | — | ⬜ |
| TC-P10 | Pagination works — first page | First 10 accuracy rows displayed; page 1 active | — | — | ⬜ |
| TC-P11 | Pagination works — subsequent pages | Page 2 shows next rows; page 2 highlighted | — | — | ⬜ |
| TC-P12 | Teacher name displayed with user relation | Each row shows teacher's full name from `assignedTeacher.user` | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Permission 403 — No viewTeacherAccuracy permission | User without `tenant.view-teacher-accuracy.viewAny` gets 403 Forbidden | — | — | ⬜ |
| TC-N02 | Guest access redirect | Unauthenticated user redirected to login | — | — | ⬜ |
| TC-N03 | Empty state — no completed topics | Table shows "No completed topics found for the selected filters." | — | — | ⬜ |
| TC-N04 | Empty state — all is_active=0 or scheduled_end_date IS NULL | Zero accuracy records available | — | — | ⬜ |
| TC-N05 | Records with NULL assigned_teacher_id | Records without teacher assignment excluded or show "Unassigned" | — | — | ⬜ |
| TC-N06 | Malformed page parameter | `?accuracy_page=-1` or `?accuracy_page=abc` defaults to page 1 | — | — | ⬜ |
| TC-N07 | Page exceeding total pages | `?accuracy_page=999` shows last page or empty gracefully | — | — | ⬜ |
| TC-N08 | Insufficient data for teacher ranking | Fewer than 10 teachers available; ranking shows all available without error | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Updating scheduled_end_date changes variance | Changing end_date updates DATEDIFF and affects accuracy category | — | — | ⬜ |
| TC-D02 | A | Marking a record as complete (is_active=1) adds it to accuracy | Newly completed record appears in accuracy data after refresh | — | — | ⬜ |
| TC-D03 | B | Deleting a completed record removes it from accuracy | Soft-deleted record no longer counted in accuracy/pagination | — | — | ⬜ |
| TC-D04 | C | Same teacher across multiple class/subject groups | Teacher's accuracy aggregates across all their assigned completed topics | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based tab visibility via viewAny | Report tabs are conditionally rendered via @can('tenant.view-teacher-accuracy.viewAny') and nav-tab permission attribute; users without viewAny permission cannot see this tab | — | — | ◌ |
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
| 1 | Inspect report/index.blade.php | Tab is conditionally rendered via @can('tenant.view-teacher-accuracy.viewAny')
| 2 | Check nav-tab component permission attribute | Tab's permission parameter matches 'tenant.view-teacher-accuracy.viewAny'
| 3 | Log in as user with viewAny permission | Planning Accuracy tab visible in Report section |
| 4 | Log in as user without viewAny permission | Planning Accuracy tab hidden; user cannot access this report |

#### TC-CR02: Breadcrumb Config — Route Registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File contains routing configuration for the syllabus module |
| 2 | Verify the 'syllabus.report' key exists | Config has 'syllabus.report' => 'syllabus/report' entry
| 3 | Verify its value points to the correct parent screen URL | Value 'syllabus/report' correctly references Report tab view
| 4 | Load the screen via the Report tab tab | Breadcrumb trail shows correct hierarchy and highlights current screen |
| 5 | Click the breadcrumb parent link | Navigates correctly to Report tab page without errors |
### 6.1 Positive TC Steps

#### TC-P01: Planning Accuracy Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Expand "Syllabus" from left sidebar | Menu options appear |
| 3 | Click "Reports" and select "Planning Accuracy" tab | Page loads at `/report?tab=planning_accuracy` |
| 4 | Check the filter bar | Dropdowns for Academic Session, Class, Subject, date range present |
| 5 | Check accuracy table | Table with teacher accuracy rows visible |
| 6 | Check breakdown chart | Donut/chart showing on_time, slightly_late, very_late counts |
| 7 | Check teacher ranking section | Top 10 teachers list/table |
| 8 | Check summary cards | onTimeCount and avgVariance summary cards visible |
| 9 | Check pagination | If 10+ records, pagination links visible |

---

#### TC-P02: Accuracy Table Displays Correct Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to planning accuracy | Page loads |
| 2 | Check table header columns | Columns: Teacher, On Time %, Late %, Avg Variance (Days), Total Topics |
| 3 | Verify each row shows teacher data | Row has teacher name, percentages, variance, and topic count |

---

#### TC-P03: Variance Day Calculation Correctness

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Record A — scheduled_end_date=Jan 10, updated_at=Jan 8 (completed 2 days early, variance=-2) | Early completion |
| 2 | Seed: Record B — scheduled_end_date=Jan 10, updated_at=Jan 10 (completed on time, variance=0) | On time |
| 3 | Seed: Record C — scheduled_end_date=Jan 10, updated_at=Jan 14 (completed 4 days late, variance=+4) | Late |
| 4 | Navigate to planning accuracy | Record A variance = -2 days |
| 5 | Verify Record B variance = 0 days | On time |
| 6 | Verify Record C variance = +4 days | Late |

---

#### TC-P04: Accuracy Breakdown Distribution Correct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 10 on_time (variance <= 0), 5 slightly_late (1-3), 3 very_late (>= 4) | 18 total records |
| 2 | Navigate to planning accuracy | Breakdown chart shows: on_time=10, slightly_late=5, very_late=3 |
| 3 | Verify sum = 18 | 10 + 5 + 3 = 18 — matches total records |
| 4 | Adjust seed data: add 2 more very_late | Breakdown updates to: on_time=10, slightly_late=5, very_late=5 |

---

#### TC-P05: Teacher Ranking Ordered By Accuracy Descending

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 12 teachers with varying accuracy: T1 (95%), T2 (88%), T3 (82%), T4 (75%), T5 (70%), T6 (65%), T7 (60%), T8 (55%), T9 (50%), T10 (45%), T11 (40%), T12 (35%) | 12 teachers |
| 2 | Navigate to planning accuracy | Top 10 ranking shows T1 through T10 |
| 3 | Verify T1 is rank 1 (95%) | Highest accuracy |
| 4 | Verify T10 is rank 10 (45%) | Lowest in top 10 |
| 5 | Verify T11 and T12 not in top 10 | Correctly excluded |

---

#### TC-P06: onTimeCount and avgVariance Summary Cards

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 10 records with variance_days = [-2, -1, 0, 0, 1, 2, 3, 4, 5, 6] | Mixed variances |
| 2 | Navigate to planning accuracy | onTimeCount = 4 (records with variance <= 0) |
| 3 | Calculate expected avg: (-2 + -1 + 0 + 0 + 1 + 2 + 3 + 4 + 5 + 6) / 10 = 18/10 = 1.8 | avgVariance = 1.8 days |

---

#### TC-P07: Filter By Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Jan records (5), Feb records (8), Mar records (7) | 20 total across 3 months |
| 2 | Set date range: Jan 1 to Jan 31 | Only Jan records shown (5) |
| 3 | Set date range: Feb 1 to Feb 28 | Only Feb records shown (8) |
| 4 | Set date range: Jan 1 to Mar 31 | All 20 records shown |
| 5 | Verify breakdown and ranking update per scope | Summary metrics recalculated for scope |

---

#### TC-P08: Filter By Class Scopes Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class A (12 records), Class B (10 records) | Two classes |
| 2 | Select Class A | Only Class A records shown (12) |
| 3 | Verify breakdown shows Class A data only | onTimeCount/avgVariance for Class A |
| 4 | Select Class B | Only Class B records shown (10) |

---

#### TC-P09: Filter By Class + Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class A / Math (5 records), Class A / Science (7 records) | Combinations |
| 2 | Select Class A + Math | 5 records |
| 3 | Select Class A + Science | 7 records |
| 4 | Verify teacher ranking scoped to selected filters | Only teachers with records in scope appear |

---

#### TC-P10: Pagination Works (First Page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 25 accuracy records | 25 records |
| 2 | Navigate to planning accuracy — page 1 | 10 records displayed |
| 3 | Verify page 1 pagination link active | Page 1 highlighted |
| 4 | Veriy "Next" link visible | Pagination controls present |

---

#### TC-P11: Pagination Works (Subsequent Pages)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | With 25 records, click page 2 | Records 11-20 displayed |
| 2 | Click page 3 | Records 21-25 displayed |
| 3 | Click "Previous" | Returns to page 2 |
| 4 | Click page 1 | Returns to page 1 |

---

#### TC-P12: Teacher Name Displayed With User Relation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: record with assigned_teacher_id linked to Employee "Sharma" with user "Ravi Sharma" | Record exists |
| 2 | Navigate to planning accuracy | Row shows teacher name as "Ravi Sharma" |
| 3 | Verify name loaded via `assignedTeacher.user` relation | Correct eager-loading |

---

### 6.2 Negative TC Steps

#### TC-N01: Permission 403 — No viewTeacherAccuracy Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.view-teacher-accuracy.viewAny` | Dashboard loads (other tabs may be visible) |
| 2 | Navigate to `/report?tab=planning_accuracy` | 403 Forbidden or tab hidden from UI |
| 3 | Verify planning accuracy tab not displayed | Tab excluded from user's visible tabs |

---

#### TC-N02: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout completely | — |
| 2 | Navigate to `/report?tab=planning_accuracy` | Redirected to login page |

---

#### TC-N03: Empty State — No Completed Topics

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no records with `is_active=1 AND scheduled_end_date IS NOT NULL` | No accuracy data |
| 2 | Navigate to planning accuracy | Table shows: "No completed topics found for the selected filters." |
| 3 | Breakdown chart shows zero counts | on_time=0, slightly_late=0, very_late=0 |
| 4 | Teacher ranking section empty | "No teacher data available" message |
| 5 | Summary cards: onTimeCount=0, avgVariance=0 | Zero values displayed |

---

#### TC-N04: Empty State — All is_active=0 or scheduled_end_date IS NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed records but all have `is_active=0` | Not completed |
| 2 | Navigate to planning accuracy | Empty state displayed |
| 3 | Seed records with `is_active=1` but `scheduled_end_date=NULL` | No planned end date |
| 4 | Navigate to planning accuracy | Empty state displayed |

---

#### TC-N05: Records With NULL assigned_teacher_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: record with `assigned_teacher_id=NULL` | Unassigned record |
| 2 | Navigate to planning accuracy | Record displayed with "Unassigned" or "-" as teacher name |
| 3 | No 500 errors | Graceful handling of missing teacher relation |

---

#### TC-N06: Malformed Page Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `?tab=planning_accuracy&accuracy_page=-1` | Shows first page |
| 2 | Navigate to `?tab=planning_accuracy&accuracy_page=abc` | Shows first page |
| 3 | No 500 errors | Graceful handling |

---

#### TC-N07: Page Exceeding Total Pages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | With 3 pages of data, navigate to `?accuracy_page=999` | Shows last page or empty result set gracefully |
| 2 | No 500 errors | Handled by paginator |

---

#### TC-N08: Insufficient Data For Teacher Ranking

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed only 3 teachers with accuracy data | Fewer than 10 |
| 2 | Navigate to planning accuracy | Teacher ranking shows all 3 teachers |
| 3 | No error about insufficient data | Works gracefully with available teachers |

---

### 6.3 Dependency TC Steps

#### TC-D01: Updating scheduled_end_date Changes Variance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: record with scheduled_end_date=Jan 20, updated_at=Jan 22 (±2 variance) | Variance = +2 (slightly_late) |
| 2 | Update scheduled_end_date to Jan 25 | Now variance = -3 (on_time) |
| 3 | Refresh planning accuracy | Record category changed from slightly_late to on_time |
| 4 | Verify breakdown counts updated | on_time count increases by 1, slightly_late decreases by 1 |

---

#### TC-D02: Marking Record Complete Adds It To Accuracy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: record with `is_active=0` and `scheduled_end_date=Jan 15` | Not yet counted in accuracy |
| 2 | Navigate to planning accuracy | Record not in table |
| 3 | Set `is_active=1` on the record | Now counts as completed |
| 4 | Refresh planning accuracy | Record appears in table with variance calculated |
| 5 | Verify total counts increased by 1 | Breakdown, summary updated |

---

#### TC-D03: Deleting Completed Record Removes It From Accuracy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to planning accuracy — note record count | Count = X |
| 2 | Soft-delete a visible accuracy record | Record deleted |
| 3 | Refresh planning accuracy | Count = X - 1 |
| 4 | Verify teacher ranking accuracy % recalculated | Affected teacher's accuracy changes |

---

#### TC-D04: Same Teacher Across Multiple Class-Subject Groups

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Teacher T1 with 3 on-time records in Class A / Math and 2 late records in Class B / Science | T1 has 5 total, 3 on-time = 60% |
| 2 | Navigate to planning accuracy — no filter | T1 shows 60% accuracy across all classes |
| 3 | Filter by Class A / Math only | T1 shows 100% accuracy (3/3 on-time) |
| 4 | Filter by Class B / Science only | T1 shows 0% accuracy (0/2 on-time) |
