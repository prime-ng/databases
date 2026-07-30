# slb_progress_tracker_TcList

## Module: Syllabus → Reports → Progress Tracker

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Reports |
| Feature | Progress Tracker |
| URL(s) | `/syllabus/report?tab=progress` (report.index) |
| Controller | `Modules\Syllabus\Http\Controllers\SyllabusController@report()` |
| Model(s) | `Modules\Syllabus\Models\SyllabusSchedule` |
| Permissions | `tenant.view-syllabus-progress.viewAny` |
| Policy | `SyllabusReportPolicy::viewSyllabusProgress()` |
| View Partial | `resources/views/report/partials/progress.blade.php` |
| Pagination | 10 per page, page name `progress_page` |

---

## 2. Pre-conditions

- Required permissions: `tenant.view-syllabus-progress.viewAny`
- Required seed data: At least one active `OrganizationAcademicSession`, multiple `SchoolClass` records, multiple `Subject` records, multiple `SyllabusSchedule` records with varying `is_active`, `scheduled_end_date`, and `planned_periods` values
- Test user must have the above permission (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Progress Tracker requires at least 10+ unique (class_id, subject_id) combinations with schedule records for meaningful pagination testing

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

- **Grouped data**: Seed schedule records across multiple (class_id, subject_id) pairs — each pair should have a mix of released, overdue, and pending topics
- **Pagination**: Seed at least 25 unique (class_id, subject_id) groups spread across 3+ classes to test 10-per-page pagination
- **Completion states**: For each class-subject group:
  - Some records with `is_active=1` (completed)
  - Some records with `is_active=0 AND scheduled_end_date < NOW()` (overdue)
  - Some records with `is_active=0 AND scheduled_end_date >= NOW()` (pending/in progress)
- **Planned periods**: Vary `planned_periods` values (NULL, 0, 5, 10, 15) across groups
- **Filters**: Data should span at least 2 classes to test class filter scoping
- **Empty state**: Create a class-subject combination with zero schedule records
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
| BC-DB-07 | scheduled_start_date | DATE | NULLABLE |
| BC-DB-08 | scheduled_end_date | DATE | NULLABLE |
| BC-DB-09 | planned_periods | SMALLINT UNSIGNED | DEFAULT NULL |
| BC-DB-10 | is_active | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-11 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-12 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

### 4.2 Authorization (Policy Gates)

| BC ID | Permission | Policy Method | Behavior |
|-------|-----------|---------------|----------|
| BC-AUTH-01 | tenant.view-syllabus-progress.viewAny | viewSyllabusProgress() | Without → 403 Forbidden on `/report?tab=progress` |

### 4.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | `$progressData` aggregation | Query uses `selectRaw` with `COUNT(*) as total_topics`, `SUM(CASE WHEN is_active=1 THEN 1 ELSE 0 END) as completed_topics`, `SUM(CASE WHEN is_active=0 AND scheduled_end_date < NOW() THEN 1 ELSE 0 END) as overdue_topics`, `SUM(COALESCE(planned_periods, 0)) as total_periods` |
| BC-BIZ-02 | Group by class_id, subject_id | Results grouped by the combination of `class_id` and `subject_id` |
| BC-BIZ-03 | Eager-load class and subject | Each result row has related `class` and `subject` models for name display |
| BC-BIZ-04 | `$applyFilters` closure | Conditionally adds `WHERE` clauses for `academic_session_id`, `class_id`, `subject_id` from query params |
| BC-BIZ-05 | Pagination with `progress_page` | Results paginated at 10 per page using page name `progress_page` |
| BC-BIZ-06 | Progress percentage per row | `completed_topics / total_topics * 100` derived in view (if total=0, show 0%) |
| BC-BIZ-07 | Overdue calculation | `overdue_topics` derived from `is_active=0` AND `scheduled_end_date < NOW()` |
| BC-BIZ-08 | Screen loads via SyllabusController@report() at GET /syllabus/report with report tab group | Navigating to GET /syllabus/report with appropriate permissions loads the Report tab group; this screen's data is fetched and displayed |

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
| TC-P01 | Progress tracker page loads with all UI elements | Page loads at `/report?tab=progress` with filter bar, table with correct columns, and pagination | — | — | ⬜ |
| TC-P02 | Table displays correct columns | Columns: Class, Subject, Total Topics, Completed Topics, Overdue Topics, Progress %, Total Periods | — | — | ⬜ |
| TC-P03 | Progress data aggregation correctness for one class-subject group | Single group shows correct `total_topics`, `completed_topics`, `overdue_topics`, `total_periods` matching seed data | — | — | ⬜ |
| TC-P04 | Progress percentage displayed per row | Each row shows `(completed_topics / total_topics) * 100` as formatted percentage | — | — | ⬜ |
| TC-P05 | Multiple class-subject groups displayed | 5+ distinct (class_id, subject_id) groups each render as separate rows | — | — | ⬜ |
| TC-P06 | Filter by class scopes data correctly | Selecting Class A shows only class-subject groups belonging to Class A | — | — | ⬜ |
| TC-P07 | Filter by class + subject scopes data correctly | Selecting Class A + Subject X shows single row for that specific combination | — | — | ⬜ |
| TC-P08 | Pagination works (first page) | First page shows first 10 rows; page 1 highlighted as active | — | — | ⬜ |
| TC-P09 | Pagination works (subsequent pages) | Clicking page 2 shows next set of rows; page 2 highlighted as active | — | — | ⬜ |
| TC-P10 | Class and subject names displayed correctly | Each row shows the human-readable class name and subject name via eager-loaded relations | — | — | ⬜ |
| TC-P11 | Total periods column sums correctly | `SUM(COALESCE(planned_periods, 0))` matches manual sum of seed data per group | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Permission 403 — No viewSyllabusProgress permission | User without `tenant.view-syllabus-progress.viewAny` gets 403 Forbidden on `/report?tab=progress` | — | — | ⬜ |
| TC-N02 | Guest access redirect | Unauthenticated user redirected to login page | — | — | ⬜ |
| TC-N03 | Empty state — no data for selected filters | Table shows "No topics found for the selected filters." message | — | — | ⬜ |
| TC-N04 | Empty state — no academic session | Error message: "Please select Academic Session, Class, and Subject to generate the report." | — | — | ⬜ |
| TC-N05 | All total_topics = 0 for a group | Row shows 0 for all metrics; progress 0%; no division error | — | — | ⬜ |
| TC-N06 | Negative or malformed page parameter | `?progress_page=-1` or `?progress_page=abc` defaults to page 1 without error | — | — | ⬜ |
| TC-N07 | Page number exceeding total pages | `?progress_page=999` shows last page or empty page gracefully | — | — | ⬜ |
| TC-N08 | Invalid filter parameters (non-existent class_id) | Passing `?class_id=99999` returns empty table; no 500 error | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Updating a schedule record's `is_active` changes aggregated counts | Changing a record from `is_active=0` to `is_active=1` and refreshing updates completed_topics and progress % | — | — | ⬜ |
| TC-D02 | A | Deleting a schedule record reduces total_topics | Soft-deleting a record removes it from the aggregation; total_topics decreases by 1 | — | — | ⬜ |
| TC-D03 | B | Large dataset with 100+ groups tests pagination thoroughly | 100+ groups paginated correctly across 10 pages; no missing data | — | — | ⬜ |
| TC-D04 | C | Empty planned_periods treated as 0 in aggregation | Records with `planned_periods=NULL` are counted as 0 in `SUM(COALESCE(planned_periods, 0))` | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based tab visibility via viewAny | Report tabs are conditionally rendered via @can('tenant.view-syllabus-progress.viewAny') and nav-tab permission attribute; users without viewAny permission cannot see this tab | — | — | ◌ |
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
| 1 | Inspect report/index.blade.php | Tab is conditionally rendered via @can('tenant.view-syllabus-progress.viewAny')
| 2 | Check nav-tab component permission attribute | Tab's permission parameter matches 'tenant.view-syllabus-progress.viewAny'
| 3 | Log in as user with viewAny permission | Progress Tracker tab visible in Report section |
| 4 | Log in as user without viewAny permission | Progress Tracker tab hidden; user cannot access this report |

#### TC-CR02: Breadcrumb Config — Route Registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File contains routing configuration for the syllabus module |
| 2 | Verify the 'syllabus.report' key exists | Config has 'syllabus.report' => 'syllabus/report' entry
| 3 | Verify its value points to the correct parent screen URL | Value 'syllabus/report' correctly references Report tab view
| 4 | Load the screen via the Report tab tab | Breadcrumb trail shows correct hierarchy and highlights current screen |
| 5 | Click the breadcrumb parent link | Navigates correctly to Report tab page without errors |
### 6.1 Positive TC Steps

#### TC-P01: Progress Tracker Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Expand "Syllabus" from left sidebar | Menu options appear |
| 3 | Click "Reports" and select "Progress Tracker" tab | Page loads at `/report?tab=progress` |
| 4 | Check the filter bar | Dropdowns for Academic Session, Class, Subject present |
| 5 | Check the progress table | Table rendered with column headers |
| 6 | Check pagination links | If 10+ groups exist, pagination links appear at bottom |

---

#### TC-P02: Table Displays Correct Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to progress tracker | Page loads |
| 2 | Check table header columns | Columns present: Class, Subject, Total Topics, Completed, Overdue, Progress %, Total Periods |
| 3 | Verify column order matches specification | Class → Subject → Total Topics → Completed → Overdue → Progress % → Total Periods |

---

#### TC-P03: Progress Data Aggregation Correctness

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class A / Subject X — 20 total records: 12 completed (is_active=1), 3 overdue (is_active=0, end_date < now), 5 pending (is_active=0, end_date >= now), planned_periods: sum of 45 | Fixed group |
| 2 | Navigate to progress tracker | Group row visible |
| 3 | Verify Total Topics = 20 | Matches seed |
| 4 | Verify Completed = 12 | Matches seed |
| 5 | Verify Overdue = 3 | Matches seed |
| 6 | Verify Total Periods = 45 | Matches seed |

---

#### TC-P04: Progress Percentage Displayed Per Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Group A — 10 total, 7 completed | 70% expected |
| 2 | Navigate to progress tracker | Group A row visible |
| 3 | Verify Progress % = 70% | Calculated as (7/10)*100 |
| 4 | Seed: Group B — 5 total, 0 completed | 0% expected |
| 5 | Verify Progress % = 0% | Correctly shows 0% |

---

#### TC-P05: Multiple Class-Subject Groups Displayed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 5 distinct (class_id, subject_id) groups with varying data | 5 groups |
| 2 | Navigate to progress tracker | 5 rows visible in table |
| 3 | Verify each row shows unique class+subject combination | No duplicate group rows |
| 4 | Verify each row has correct aggregated values per group | Data matches seed per group |

---

#### TC-P06: Filter By Class Scopes Data Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class A has 3 groups (A+X, A+Y, A+Z), Class B has 2 groups (B+X, B+Y) | Two classes |
| 2 | Navigate to progress tracker — no filter | 5 rows visible |
| 3 | Select Class A from filter | Page reloads with `?class_id={A_id}` |
| 4 | Verify only Class A rows visible | 3 rows |
| 5 | Verify Class B rows hidden | Not in table |
| 6 | Clear filter, select Class B | 2 rows visible |

---

#### TC-P07: Filter By Class + Subject Scopes Data Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class A / Subject X (group), Class A / Subject Y (group), Class B / Subject X (group) | 3 groups |
| 2 | Select Class A + Subject X from filters | Single row for Class A / Subject X |
| 3 | Select Class A + Subject Y | Single row for Class A / Subject Y |
| 4 | Select Class B + Subject X | Single row for Class B / Subject X |

---

#### TC-P08: Pagination Works (First Page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 25 class-subject groups | 25 rows of data |
| 2 | Navigate to progress tracker | Page 1 displayed with rows 1-10 |
| 3 | Verify exactly 10 rows on page 1 | Row count = 10 |
| 4 | Verify pagination shows page 1 as active | Page 1 link highlighted |
| 5 | Verify "Next" and page 2 links visible | Pagination controls visible |

---

#### TC-P09: Pagination Works (Subsequent Pages)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | With 25 groups, click page 2 link | Navigates to `?tab=progress&progress_page=2` |
| 2 | Verify rows 11-20 displayed | 10 rows |
| 3 | Click page 3 link | Rows 21-25 displayed (5 rows) |
| 4 | Click "Previous" link | Returns to page 2 |
| 5 | Click "First" or page 1 | Returns to page 1 |

---

#### TC-P10: Class and Subject Names Displayed Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: class_id=9 (Class 9), subject_id=5 (Mathematics) with schedule records | Group exists |
| 2 | Navigate to progress tracker | Row shows "Class 9" as class name |
| 3 | Verify subject column shows "Mathematics" | Subject name from eager-loaded relation |

---

#### TC-P11: Total Periods Column Sums Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Group A — 3 records with planned_periods (5, 10, 15), 2 records with planned_periods=NULL | Total expected: 5+10+15+0+0 = 30 |
| 2 | Navigate to progress tracker | Group A Total Periods = 30 |
| 3 | Verify NULL planned_periods treated as 0 | Correct coalesce behavior |

---

### 6.2 Negative TC Steps

#### TC-N01: Permission 403 — No viewSyllabusProgress Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.view-syllabus-progress.viewAny` | Dashboard loads (other tabs may be visible) |
| 2 | Navigate to `/report?tab=progress` | 403 Forbidden or tab hidden from UI |
| 3 | Verify progress tab not displayed in report tab bar | Tab excluded from user's visible tabs |

---

#### TC-N02: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout completely | — |
| 2 | Navigate to `/report?tab=progress` | Redirected to login page |

---

#### TC-N03: Empty State — No Data For Selected Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a class/subject combination with zero schedule records | No data |
| 2 | Navigate to progress tracker | Table shows: "No topics found for the selected filters." |
| 3 | Verify no data rows visible | Empty table |

---

#### TC-N04: Empty State — No Academic Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Deactivate or remove all academic sessions | No active session |
| 2 | Navigate to progress tracker | Error message: "Please select Academic Session, Class, and Subject to generate the report." |
| 3 | Progress data table hidden or disabled | Cannot load without session |

---

#### TC-N05: All total_topics = 0 For a Group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No schedule records exist for a particular scope | Zero-count group |
| 2 | Navigate to progress tracker | Row shows 0 for all metrics |
| 3 | Verify Progress % = 0% | No division by zero error |

---

#### TC-N06: Negative Or Malformed Page Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/report?tab=progress&progress_page=-1` | Page loads normally, shows first page |
| 2 | Navigate to `/report?tab=progress&progress_page=abc` | Page loads normally, shows first page |
| 3 | No 500 errors or exception pages | Graceful handling of invalid page params |

---

#### TC-N07: Page Number Exceeding Total Pages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | With 3 pages of data, navigate to `?progress_page=999` | Shows last page or empty result set gracefully |
| 2 | No 500 errors | Handled by paginator |

---

#### TC-N08: Invalid Filter Parameters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/report?tab=progress&class_id=99999` | Page loads without 500 error |
| 2 | Table shows empty state | "No topics found" message |
| 3 | Navigate to `/report?tab=progress&subject_id=99999` | Same graceful handling |

---

### 6.3 Dependency TC Steps

#### TC-D01: Updating Schedule Record Changes Aggregated Counts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to progress tracker — note Completed count for Group A | Completed = X |
| 2 | Update a record in Group A from `is_active=0` to `is_active=1` | Record now counted as completed |
| 3 | Refresh progress tracker | Completed = X + 1 |
| 4 | Progress % recalculated | Percentage updated accordingly |

---

#### TC-D02: Deleting Schedule Record Reduces total_topics

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to progress tracker — note Total Topics for Group A | Total = X |
| 2 | Soft-delete a schedule record belonging to Group A | Record deleted |
| 3 | Refresh progress tracker | Total = X - 1 |
| 4 | Completed/Overdue counts also decrease if deleted record was in those categories | Consistent counts |

---

#### TC-D03: Large Dataset Tests Pagination Thoroughly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 100+ distinct (class_id, subject_id) groups | Large dataset |
| 2 | Navigate to progress tracker | Page 1 shows rows 1-10 |
| 3 | Click through all pages | Each page displays correct set of 10 rows (last page may have fewer) |
| 4 | Verify total pages count = ceil(total_groups / 10) | Correct pagination metadata |
| 5 | Navigate to last page | Remaining rows displayed correctly |

---

#### TC-D04: Empty planned_periods Treated As 0 in Aggregation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Group A — 5 records: planned_periods (10, NULL, 15, NULL, 5) | Expected total: 10+0+15+0+5 = 30 |
| 2 | Navigate to progress tracker | Total Periods = 30 |
| 3 | Verify NULLs are correctly coalesced to 0 | Correct aggregation behavior |
