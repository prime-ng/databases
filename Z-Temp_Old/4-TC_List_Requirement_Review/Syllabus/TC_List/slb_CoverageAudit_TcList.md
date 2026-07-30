# slb_coverage_audit_TcList

## Module: Syllabus → Reports → Coverage Audit

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Reports |
| Feature | Coverage Audit |
| URL(s) | `/syllabus/report?tab=coverage` (report.index) |
| Controller | `Modules\Syllabus\Http\Controllers\SyllabusController@report()` |
| Model(s) | `Modules\Syllabus\Models\SyllabusSchedule` |
| Permissions | `tenant.view-coverage-audit.viewAny` |
| Policy | `SyllabusReportPolicy::viewCoverageAudit()` |
| View Partial | `resources/views/report/partials/coverage.blade.php` |
| Pagination | 10 per page, page name `audit_page` |

---

## 2. Pre-conditions

- Required permissions: `tenant.view-coverage-audit.viewAny`
- Required seed data: At least one active `OrganizationAcademicSession`, multiple `SchoolClass`, `Subject`, `Lesson`, `Topic` records; `SyllabusSchedule` records with `scheduled_start_date IS NOT NULL`
- Test user must have the above permission (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Coverage Audit only includes records where `scheduled_start_date` is NOT NULL — seed data must respect this condition

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

- **Core dataset**: Seed 25+ `SyllabusSchedule` records with `scheduled_start_date` set (NOT NULL) across multiple classes and subjects
- **Excluded records**: Seed a few records with `scheduled_start_date = NULL` — these must NOT appear in audit results
- **Date ordering**: Seed records with staggered `scheduled_start_date` values to test ASC ordering
- **Relations**: Ensure each schedule record has valid `class`, `subject`, `lesson`, `topic` relations for eager loading
- **Completion states**: Mix of `is_active=1` (completed/scheduled) and `is_active=0` (not yet completed) records
- **Date range filter**: Ensure dates span at least a 3-month window for date range filtering tests
- **Empty state**: Academic session with zero schedule records having `scheduled_start_date NOT NULL`
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
| BC-DB-08 | scheduled_start_date | DATE | NULLABLE — records with NULL are excluded from audit |
| BC-DB-09 | scheduled_end_date | DATE | NULLABLE |
| BC-DB-10 | planned_periods | SMALLINT UNSIGNED | DEFAULT NULL |
| BC-DB-11 | is_active | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-12 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-13 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

### 4.2 Authorization (Policy Gates)

| BC ID | Permission | Policy Method | Behavior |
|-------|-----------|---------------|----------|
| BC-AUTH-01 | tenant.view-coverage-audit.viewAny | viewCoverageAudit() | Without → 403 Forbidden on `/report?tab=coverage` |

### 4.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | `scheduled_start_date IS NOT NULL` filter | Only records with a non-null `scheduled_start_date` are included in `$auditData` |
| BC-BIZ-02 | Ordered by `scheduled_start_date ASC` | Results sorted chronologically by start date |
| BC-BIZ-03 | Paginated at 10 per page using `audit_page` | Results split into pages of 10 |
| BC-BIZ-04 | Eager-loaded relations | Each row loads `class`, `subject`, `lesson`, `topic` relationships |
| BC-BIZ-05 | `$applyFilters` closure | Conditionally adds `WHERE` clauses for `academic_session_id`, `class_id`, `subject_id` |
| BC-BIZ-06 | Tab partial rendering | View rendered from `resources/views/report/partials/coverage.blade.php` |
| BC-BIZ-07 | Filter by date range | `scheduled_start_date` BETWEEN start_date AND end_date when date range filter applied |
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
| TC-P01 | Coverage audit page loads with all UI elements | Page loads at `/report?tab=coverage` with filter bar, audit table, and pagination | — | — | ⬜ |
| TC-P02 | Audit table displays correct columns | Columns: Lesson, Topic, Scheduled Start, Scheduled End, Status, Class, Subject | — | — | ⬜ |
| TC-P03 | Only records with scheduled_start_date NOT NULL appear | Records with NULL `scheduled_start_date` excluded; only valid entries visible | — | — | ⬜ |
| TC-P04 | Records ordered by scheduled_start_date ASC | Earliest start date first; latest start date last on each page | — | — | ⬜ |
| TC-P05 | Filter by class scopes data correctly | Selecting a class shows only audit records for that class | — | — | ⬜ |
| TC-P06 | Filter by class + subject scopes data correctly | Class + Subject filters combined scope to matching records | — | — | ⬜ |
| TC-P07 | Filter by date range | Records within date range displayed; records outside range excluded | — | — | ⬜ |
| TC-P08 | Pagination works — first page | First 10 records displayed; page 1 active | — | — | ⬜ |
| TC-P09 | Pagination works — subsequent pages | Clicking page 2 shows next 10 records | — | — | ⬜ |
| TC-P10 | Eager-loaded relations display correct names | Each row shows human-readable Lesson name, Topic name, Class name, Subject name | — | — | ⬜ |
| TC-P11 | Status indicator based on is_active | Active records show "Completed" or "On Track"; inactive show "Pending" or "Overdue" | — | — | ⬜ |
| TC-P12 | Combined filters (class + subject + date range) | All three filters combined scope to precise matching subset | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Permission 403 — No viewCoverageAudit permission | User without `tenant.view-coverage-audit.viewAny` gets 403 Forbidden | — | — | ⬜ |
| TC-N02 | Guest access redirect | Unauthenticated user redirected to login | — | — | ⬜ |
| TC-N03 | Empty state — no records with scheduled_start_date NOT NULL | Table shows "No topics found for the selected filters." | — | — | ⬜ |
| TC-N04 | Filter with no matching data | Selecting filters with zero matching records shows empty table | — | — | ⬜ |
| TC-N05 | Malformed page parameter | `?audit_page=-1` or `?audit_page=abc` defaults to page 1 | — | — | ⬜ |
| TC-N06 | Page exceeding total pages | `?audit_page=999` shows last page or empty gracefully | — | — | ⬜ |
| TC-N07 | Invalid date range format | Non-date strings in date range filter ignored or show validation message | — | — | ⬜ |
| TC-N08 | All records filtered out by date range | Date range with no matching records shows empty table gracefully | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Creating a new schedule record with scheduled_start_date adds to audit | New record appears in audit table after refresh | — | — | ⬜ |
| TC-D02 | A | Deleting a schedule record removes it from audit | Soft-deleted record no longer visible in audit table | — | — | ⬜ |
| TC-D03 | B | Setting NULL scheduled_start_date excludes record | Updating a record's start_date to NULL removes it from audit data | — | — | ⬜ |
| TC-D04 | C | Large dataset (100+ records) pagination accuracy | All 100+ records paginated correctly across pages; no missing or duplicate data | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based tab visibility via viewAny | Report tabs are conditionally rendered via @can('tenant.view-coverage-audit.viewAny') and nav-tab permission attribute; users without viewAny permission cannot see this tab | — | — | ◌ |
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
| 1 | Inspect report/index.blade.php | Tab is conditionally rendered via @can('tenant.view-coverage-audit.viewAny')
| 2 | Check nav-tab component permission attribute | Tab's permission parameter matches 'tenant.view-coverage-audit.viewAny'
| 3 | Log in as user with viewAny permission | Coverage Audit tab visible in Report section |
| 4 | Log in as user without viewAny permission | Coverage Audit tab hidden; user cannot access this report |

#### TC-CR02: Breadcrumb Config — Route Registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File contains routing configuration for the syllabus module |
| 2 | Verify the 'syllabus.report' key exists | Config has 'syllabus.report' => 'syllabus/report' entry
| 3 | Verify its value points to the correct parent screen URL | Value 'syllabus/report' correctly references Report tab view
| 4 | Load the screen via the Report tab tab | Breadcrumb trail shows correct hierarchy and highlights current screen |
| 5 | Click the breadcrumb parent link | Navigates correctly to Report tab page without errors |
### 6.1 Positive TC Steps

#### TC-P01: Coverage Audit Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Expand "Syllabus" from left sidebar | Menu options appear |
| 3 | Click "Reports" and select "Coverage Audit" tab | Page loads at `/report?tab=coverage` |
| 4 | Check the filter bar | Dropdowns for Academic Session, Class, Subject, and date range present |
| 5 | Check the audit table | Table rendered with column headers |
| 6 | Check pagination links | If 10+ records exist, pagination links visible |

---

#### TC-P02: Audit Table Displays Correct Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to coverage audit | Page loads |
| 2 | Check table header columns | Columns present: Lesson, Topic, Scheduled Start, Scheduled End, Status, Class, Subject |
| 3 | Verify column order matches specification | Lesson → Topic → Scheduled Start → Scheduled End → Status → Class → Subject |

---

#### TC-P03: Only Records With scheduled_start_date NOT NULL Appear

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 15 records with `scheduled_start_date` set, 5 records with `scheduled_start_date=NULL` | Mixed dataset |
| 2 | Navigate to coverage audit | 15 records visible (per pagination) |
| 3 | Verify none of the 5 NULL-start-date records appear | All 5 excluded |
| 4 | Verify every visible row has a non-null start date | No NULL dates in table |

---

#### TC-P04: Records Ordered By scheduled_start_date ASC

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed records with start dates: Jan 1, Jan 15, Feb 1, Feb 15, Mar 1 | 5 records |
| 2 | Navigate to coverage audit | Rows order: Jan 1 → Jan 15 → Feb 1 → Feb 15 → Mar 1 |
| 3 | Verify first row has earliest date | Jan 1 at top |
| 4 | Verify last row has latest date | Mar 1 at bottom |

---

#### TC-P05: Filter By Class Scopes Data Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class A (10 records), Class B (8 records), Class C (5 records) | 3 classes |
| 2 | Select Class A from filter | Only Class A records visible |
| 3 | Verify no Class B or C records shown | Scoped correctly |
| 4 | Clear filter, select Class B | Only Class B records visible |

---

#### TC-P06: Filter By Class + Subject Scopes Data Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class A / Math (5 records), Class A / Science (5 records), Class B / Math (3 records) | Combinations |
| 2 | Select Class A + Math | 5 records shown |
| 3 | Select Class A + Science | 5 records shown |
| 4 | Select Class B + Math | 3 records shown |

---

#### TC-P07: Filter By Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Jan 1-15 (5 records), Feb 1-15 (5 records), Mar 1-15 (5 records) | 3 date windows |
| 2 | Set date range: Jan 1 to Jan 31 | 5 records visible (Jan 1-15) |
| 3 | Set date range: Feb 1 to Feb 28 | 5 records visible (Feb 1-15) |
| 4 | Set date range: Jan 1 to Mar 31 | All 15 records visible |
| 5 | Verify date range boundaries inclusive | Records on boundary dates included |

---

#### TC-P08: Pagination Works (First Page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 25 records with scheduled_start_date set | 25 records |
| 2 | Navigate to coverage audit — page 1 | 10 records displayed |
| 3 | Verify records sorted ASC on page 1 | Earliest 10 records |
| 4 | Verify pagination shows page 1 as active | Highlighted |

---

#### TC-P09: Pagination Works (Subsequent Pages)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | With 25 records, click page 2 | Records 11-20 displayed |
| 2 | Click page 3 | Records 21-25 displayed |
| 3 | Click "Previous" | Returns to page 2 |
| 4 | Verify records sorted ASC across pages | Page 2 dates later than page 1, page 3 later than page 2 |

---

#### TC-P10: Eager-Loaded Relations Display Correct Names

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: schedule record linked to Lesson "Algebra", Topic "Linear Equations", Class "Class 9", Subject "Mathematics" | Record exists |
| 2 | Navigate to coverage audit | Row shows "Algebra" (Lesson), "Linear Equations" (Topic), "Class 9" (Class), "Mathematics" (Subject) |

---

#### TC-P11: Status Indicator Based On is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: record A with is_active=1 (completed), record B with is_active=0 (pending), record C with is_active=0 AND end_date < now (overdue) | 3 statuses |
| 2 | Navigate to coverage audit | Record A shows green "Completed" or "Active" badge |
| 3 | Record B shows yellow/blue "Pending" or "In Progress" badge | Correct status |
| 4 | Record C shows red "Overdue" badge | Correct status |

---

#### TC-P12: Combined Filters (Class + Subject + Date Range)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class A / Math — Jan records (3), Feb records (3); Class A / Science — Jan records (2); Class B / Math — Jan records (4) | Multiple dimensions |
| 2 | Select Class A + Math + Jan date range | 3 records (A+Math+Jan) |
| 3 | Select Class A + Math + Feb date range | 3 records (A+Math+Feb) |
| 4 | Select Class A + Science + Jan date range | 2 records |
| 5 | Select Class B + Math + Jan date range | 4 records |

---

### 6.2 Negative TC Steps

#### TC-N01: Permission 403 — No viewCoverageAudit Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.view-coverage-audit.viewAny` | Dashboard loads (other tabs may be visible) |
| 2 | Navigate to `/report?tab=coverage` | 403 Forbidden or tab hidden from UI |
| 3 | Verify coverage tab not displayed in report tab bar | Tab excluded |

---

#### TC-N02: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout completely | — |
| 2 | Navigate to `/report?tab=coverage` | Redirected to login page |

---

#### TC-N03: Empty State — No Records With scheduled_start_date NOT NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed session with schedule records but all have `scheduled_start_date=NULL` | No valid audit data |
| 2 | Navigate to coverage audit | Table shows: "No topics found for the selected filters. Please widen your selection or check if topics have been mapped for this session." |
| 3 | Verify no data rows visible | Empty table |

---

#### TC-N04: Filter With No Matching Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed records only for Class A | No records for other classes |
| 2 | Select Class B from filter | Empty table, no matching records |
| 3 | Verify appropriate empty state message | "No topics found" message displayed |

---

#### TC-N05: Malformed Page Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `?tab=coverage&audit_page=-1` | Page loads normally, shows first page |
| 2 | Navigate to `?tab=coverage&audit_page=abc` | Page loads normally, shows first page |
| 3 | No 500 errors or exception pages | Graceful handling |

---

#### TC-N06: Page Exceeding Total Pages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | With 3 pages of data, navigate to `?audit_page=999` | Shows last page or empty result set gracefully |
| 2 | No 500 errors | Handled by paginator |

---

#### TC-N07: Invalid Date Range Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter start_date="not-a-date" or end_date="invalid" | Validation message shown or parameter ignored |
| 2 | Enter start_date=2026-13-01 (invalid month) | Graceful handling; no 500 error |
| 3 | Verify audit data loads without date filter | Date filter ignored; all data displayed |

---

#### TC-N08: All Records Filtered Out By Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed records with dates in Jan-Feb | Records exist |
| 2 | Set date range to Jun-Jul (no overlap) | No records match |
| 3 | Table shows empty state | Appropriate message displayed |
| 4 | Widen date range to include all records | Data reappears |

---

### 6.3 Dependency TC Steps

#### TC-D01: Creating New Schedule Record With scheduled_start_date Adds to Audit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to coverage audit — note current record count | Count = X |
| 2 | Create a new schedule record with `scheduled_start_date = '2026-03-15'` | Record created |
| 3 | Refresh coverage audit | Record count = X + 1 |
| 4 | Verify new record appears in correct chronological position | Ordered by start date ASC |

---

#### TC-D02: Deleting Schedule Record Removes It From Audit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to coverage audit — note a visible record | Record visible |
| 2 | Soft-delete that record | Record trashed |
| 3 | Refresh coverage audit | Record no longer visible |
| 4 | Verify total count decreased by 1 | Consistent |

---

#### TC-D03: Setting NULL scheduled_start_date Excludes Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to coverage audit — record with start_date=2026-01-15 visible | Record visible |
| 2 | Update that record's `scheduled_start_date = NULL` | Start date cleared |
| 3 | Refresh coverage audit | Record no longer visible |
| 4 | Verify excluded records count increases | Exclusion logic correct |

---

#### TC-D04: Large Dataset (100+ Records) Pagination Accuracy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 100+ records with staggered scheduled_start_date values | Large dataset |
| 2 | Navigate to coverage audit | Page 1 shows first 10 (earliest dates) |
| 3 | Navigate to page 5 | Records 41-50, correctly ordered |
| 4 | Navigate to last page | Remaining records, correctly ordered |
| 5 | Verify no records skipped or duplicated across pages | Complete dataset covered |
