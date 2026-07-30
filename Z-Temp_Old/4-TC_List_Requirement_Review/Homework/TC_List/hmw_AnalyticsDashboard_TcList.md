# hmw_AnalyticsDashboard_TcList

## Module: LmsHomework → Homework Master → Analytics Dashboard

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsHomework |
| Tab Group | Homework Master |
| Feature | Analytics Dashboard |
| URL(s) | `/lms-home-work` (index — default tab `homework_analytics`) |
| Controller | `Modules\LmsHomework\Http\Controllers\LmsHomeworkController` |
| Method(s) | `index()` (tab=homework_analytics) |
| Model(s) | `Homework`, `HomeworkAssignment`, `HomeworkSubmission` |
| Permissions | `tenant.home-work-dashbord.viewAny` |
| Soft Deletes | N/A (read-only dashboard) |
| Activity Log | N/A (read-only dashboard) |

---

## 2. Pre-conditions

- Required permissions: `tenant.home-work-dashbord.viewAny`
- Required seed data: At least one published `Homework` with assignments and submissions
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For chart tests: Submissions created across last 7 days with mixed graded/pending status
- For filter tests: Homework assigned to multiple classes, sections, and subjects

---

## 3. Default Data Load

When the page loads via `LmsHomeworkController@index()` with `tab=homework_analytics`, the following data is computed:

| Data | Source | Query | Filters | Aggregation |
|------|--------|-------|---------|-------------|
| Active Homeworks Count | Homework | `whereHas('status', fn => value='PUBLISHED')` | class_id, subject_id, section_id, date_range | COUNT |
| Total Assignments | HomeworkAssignment | Direct count with filters | class_id, subject_id, section_id, date_range | COUNT |
| Total Submissions | HomeworkSubmission | via homework relation with filters | class_id, subject_id, section_id, date_range | COUNT |
| Pending Grading | HomeworkSubmission | `whereNull('marks_obtained')` with filters | class_id, subject_id, section_id, date_range | COUNT |
| Submission Rate | Computed | `(Total Submissions / Total Assignments) x 100` | Same filters | Percentage |
| Latest 5 Submissions | HomeworkSubmission | `latest()->limit(5)` with student+homework | Same filters | List |
| Graded vs Pending (Donut) | HomeworkSubmission | `whereNotNull/Null('marks_obtained')` | Same filters | 2 counts |
| 7-Day Trend (Bar) | HomeworkSubmission | `whereDate('created_at', date)` for last 7 days | Same filters | 7 counts |
| Top 6 Subjects (Bar) | Homework | `groupBy('subject_id')` with count | Same filters | 6 counts |

---

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Homework**: Create with `status_id`=PUBLISHED dropdown value, varied class/subject/section
- **Assignments**: Create via homework publish flow or direct DB insert with student relations
- **Submissions**: Create with varied `submitted_at` timestamps across last 7 days, mixed `marks_obtained` (null = pending, non-null = graded)
- **Pre-test cleanup**: Delete created homework, assignments, submissions by UUID/ID after tests
- **Filter test data**: Create homework for at least 2 classes, 2 subjects, 2 sections

---

## 5. Business Conditions

### 5.1 Database Schema — `lms_homework` (relevant columns)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT PK | Auto-increment |
| BC-DB-02 | class_id | INT FK | NOT NULL, FK → `sch_classes.id` |
| BC-DB-03 | subject_id | INT FK | NOT NULL, FK → `sch_subjects.id` |
| BC-DB-04 | status_id | INT FK | NOT NULL, FK → `sys_dropdown_table.id` |
| BC-DB-05 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-06 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

### 5.2 Database Schema — `lms_homework_assignment` (relevant columns)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-10 | id | BIGINT PK | Auto-increment |
| BC-DB-11 | homework_id | INT FK | NOT NULL, FK → `lms_homework.id` |
| BC-DB-12 | student_id | INT FK | NOT NULL, FK → `std_students.id` |
| BC-DB-13 | class_id | INT | NOT NULL (denormalized) |
| BC-DB-14 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |

### 5.3 Database Schema — `lms_homework_submissions` (relevant columns)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-20 | id | BIGINT PK | Auto-increment |
| BC-DB-21 | homework_id | INT FK | NOT NULL |
| BC-DB-22 | student_id | INT FK | NOT NULL |
| BC-DB-23 | submitted_at | DATETIME | NOT NULL |
| BC-DB-24 | marks_obtained | DECIMAL(5,2) | NULLABLE |
| BC-DB-25 | graded_at | DATETIME | NULLABLE |
| BC-DB-26 | is_late | BOOLEAN | DEFAULT false |
| BC-DB-27 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Submission Rate formula | `(total_submissions / total_assignments) * 100`, 0% if no assignments |
| BC-BIZ-02 | All metrics respect same filters | Changing class_id filter updates all KPIs and charts consistently |
| BC-BIZ-03 | Pending Grading count | Submissions where `marks_obtained IS NULL` |
| BC-BIZ-04 | Active Homeworks count | Only homework with published status |
| BC-BIZ-05 | Latest 5 submissions | Ordered by `created_at DESC`, limited to 5 |
| BC-BIZ-06 | 7-Day trend | Last 7 days including today, grouped by date |
| BC-BIZ-07 | Top 6 subjects | Grouped by subject_id, ordered by count DESC, limited to 6 |
| BC-BIZ-08 | Empty state — no data | All KPIs show 0, charts empty, "No data available" message |
| BC-BIZ-09 | Dashboard is read-only | No create/edit/delete actions available |
| BC-BIZ-10 | Default active tab | `homework_analytics` is default when no `tab` parameter |

### 5.5 Authorization (Permission Gates)

| BC ID | Permission | Method | Behavior |
|-------|-----------|--------|----------|
| BC-AUTH-01 | tenant.home-work-dashbord.viewAny | index() (tab=homework_analytics) | Without → 403 |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Dashboard Loads With All KPI Cards | 5 KPI cards visible: Active Homeworks, Total Assignments, Total Submissions, Pending Grading, Submission Rate | — | — | ⬜ |
| TC-P02 | KPI Values Are Accurate — Active Homeworks | Count matches published homework matching filters | — | — | ⬜ |
| TC-P03 | KPI Values Are Accurate — Total Assignments | Count matches assignment records matching filters | — | — | ⬜ |
| TC-P04 | KPI Values Are Accurate — Total Submissions | Count matches submission records matching filters | — | — | ⬜ |
| TC-P05 | KPI Values Are Accurate — Pending Grading | Count matches submissions where marks_obtained IS NULL | — | — | ⬜ |
| TC-P06 | KPI Values Are Accurate — Submission Rate | Percentage = (submissions / assignments) x 100, consistent with raw counts | — | — | ⬜ |
| TC-P07 | 7-Day Submission Trend Chart Loads | Bar chart rendered with 7 data points (last 7 days) | — | — | ⬜ |
| TC-P08 | 7-Day Trend Values Match DB | Each day's count matches submissions created on that date | — | — | ⬜ |
| TC-P09 | Graded vs Pending Donut Chart Loads | Donut chart shows 2 segments: graded count and pending count | — | — | ⬜ |
| TC-P10 | Top 6 Subjects Chart Loads | Horizontal bar chart shows top 6 subjects by homework count | — | — | ⬜ |
| TC-P11 | Latest 5 Submissions Table Loads | Table shows 5 most recent submissions with student name, homework title, status | — | — | ⬜ |
| TC-P12 | Filter By Class Updates All KPIs | Selecting a class updates all 5 KPI cards + all charts to reflect only that class's data | — | — | ⬜ |
| TC-P13 | Filter By Subject Updates All KPIs | Selecting a subject updates all metrics consistently | — | — | ⬜ |
| TC-P14 | Filter By Section Updates All KPIs | Selecting a section updates all metrics consistently | — | — | ⬜ |
| TC-P15 | Filter By Date Range Updates All KPIs | Selecting from/to dates updates all metrics for that date range | — | — | ⬜ |
| TC-P16 | Multiple Filters Combine Correctly | Class + Subject + Date Range all applied together; all metrics consistent | — | — | ⬜ |
| TC-P17 | Clear Filters Resets To All Data | Clearing all filters shows unfiltered dashboard | — | — | ⬜ |
| TC-P18 | Empty State — No Data For Filter | All KPIs show 0, charts empty, "No data available" message shown | — | — | ⬜ |
| TC-P19 | Submission Rate 0% When No Assignments | When no assignment records exist, rate shows 0% (no division error) | — | — | ⬜ |
| TC-P20 | Dashboard Is Default Tab | Navigating to `/lms-home-work` without tab param shows analytics tab by default | — | — | ⬜ |
| TC-P21 | Submission Rate Color Coding | High (>=85%) green, Medium (50-84%) amber, Low (<50%) red | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Permission 403 — No Dashboard Permission | User without `tenant.home-work-dashbord.viewAny` sees 403 or tab hidden | — | — | ⬜ |
| TC-N02 | Guest Access Redirect | Logged-out user redirected to /login | — | — | ⬜ |
| TC-N03 | Invalid Date Range | "Please select a valid date range." error | — | — | ⬜ |
| TC-N04 | Very Large Dataset — Performance | Dashboard loads within acceptable time even with thousands of records (aggregate queries) | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Active Homeworks count only includes PUBLISHED status | Draft/Archived homework excluded from count | — | — | ⬜ |
| TC-D02 | A | Total Assignments = SUM of all assignment records | Matches `SELECT COUNT(*) FROM lms_homework_assignment` with filters | — | — | ⬜ |
| TC-D03 | B | Total Submissions <= Total Assignments | Submission count never exceeds assignment count (referential integrity) | — | — | ⬜ |
| TC-D04 | B | Pending Grading + Graded = Total Submissions | `whereNull(marks_obtained)` + `whereNotNull(marks_obtained)` = total submissions | — | — | ⬜ |
| TC-D05 | C | Filter consistency — same filter across all queries | Class filter on homework, assignments, and submissions all return data for same class | — | — | ⬜ |
| TC-D06 | D | Submission count after soft-delete | Soft-deleted submissions excluded from counts (`is_active=1` filter) | — | — | ⬜ |
| TC-D07 | E | Chart.js renders correctly with empty data | Charts render with empty datasets (no JS errors) when no data matches | — | — | ⬜ |
| TC-D08 | F | Submission Rate decimal precision | Rate rounded to 1 decimal place (e.g., 84.4%) | — | — | ⬜ |
| TC-D09 | G | Access via hub tab vs direct URL | Both tab click and direct URL show same dashboard data | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Blade @can for dashboard tab visibility | Hub index wraps analytics tab in @can('tenant.home-work-dashbord.viewAny') | — | — | ◌ |
| TC-CR02 | CR | P1 | Null-safe checks on student/homework relations in latest submissions | `$submission?->student?->name` and `$submission?->homework?->title` use ?-> | — | — | ◌ |
| TC-CR03 | CR | P1 | Filter consistency — all sub-queries share same scope | Class/subject/section/date filters applied identically to all 5 KPIs and charts | — | — | ◌ |
| TC-CR04 | CR | P1 | Chart.js renders with empty/zero datasets | Bar/donut charts handle empty arrays without JS console errors | — | — | ◌ |
| TC-CR05 | CR | P1 | Aggregate queries single-SQL, no N+1 | Each KPI is one COUNT query; latest submissions eager-loads student+homework | — | — | ◌ |
| TC-CR06 | CR | P1 | Dashboard is Read-Only — No Action Buttons Present | Blade view at analytics/index.blade.php has no create/edit/delete controls | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-P01: Dashboard Loads With All KPI Cards

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads successfully |
| 2 | Expand "LMS" from left sidebar | Menu options appear |
| 3 | Click "Homework" menu item | Analytics Dashboard loads as default tab (`tab=homework_analytics`) |
| 4 | Check Active Homeworks KPI card | Card visible with count displayed |
| 5 | Check Total Assignments KPI card | Card visible with count displayed |
| 6 | Check Total Submissions KPI card | Card visible with count displayed |
| 7 | Check Pending Grading KPI card | Card visible with count displayed |
| 8 | Check Submission Rate KPI card | Card visible with percentage displayed |

#### TC-P02: KPI Values Are Accurate — Active Homeworks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders with all KPIs |
| 3 | Note the Active Homeworks KPI count on the card | Count value is visible |
| 4 | Run DB query: `SELECT COUNT(*) FROM lms_homework WHERE status_id = (SELECT id FROM sys_dropdown_table WHERE dropdown_key = 'PUBLISHED') AND is_active = 1` | DB count matches the KPI display |

#### TC-P03: KPI Values Are Accurate — Total Assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 3 | Note the Total Assignments KPI count | Count value displayed |
| 4 | Run DB query: `SELECT COUNT(*) FROM lms_homework_assignment WHERE is_active = 1` | DB count matches KPI value |
| 5 | Apply a class filter and repeat KPI vs DB comparison | Filtered assignment count still matches DB |

#### TC-P04: KPI Values Are Accurate — Total Submissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 3 | Note the Total Submissions KPI count | Count value displayed |
| 4 | Run DB query: `SELECT COUNT(*) FROM lms_homework_submissions WHERE is_active = 1` | DB count matches KPI value |

#### TC-P05: KPI Values Are Accurate — Pending Grading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 3 | Note the Pending Grading KPI count | Count value displayed |
| 4 | Run DB query: `SELECT COUNT(*) FROM lms_homework_submissions WHERE marks_obtained IS NULL AND is_active = 1` | DB count of ungraded submissions matches KPI |

#### TC-P06: KPI Values Are Accurate — Submission Rate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 3 | Note Total Assignments, Total Submissions, and Submission Rate KPIs | All three values visible |
| 4 | Manually compute: `(Total Submissions / Total Assignments) * 100` | Computed percentage equals the Submission Rate KPI value |
| 5 | Verify when Total Assignments = 0 | Submission Rate shows 0% (no division error) |

#### TC-P07: 7-Day Submission Trend Chart Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 3 | Scroll to the 7-Day Submission Trend chart section | Chart container is visible |
| 4 | Verify a bar chart is rendered with 7 bars | Bar chart displays with 7 data points across 7 days |
| 5 | Hover over each bar | Tooltip shows the date and submission count for that day |

#### TC-P08: 7-Day Trend Values Match DB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 3 | Note the submission count for each day on the 7-Day Trend chart | Chart shows 7 daily counts |
| 4 | Run DB query for each of the last 7 days: `SELECT DATE(created_at), COUNT(*) FROM lms_homework_submissions WHERE DATE(created_at) = 'YYYY-MM-DD' AND is_active = 1 GROUP BY DATE(created_at)` | Each day's DB count matches the corresponding chart bar value |

#### TC-P09: Graded vs Pending Donut Chart Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 3 | Scroll to the Graded vs Pending chart section | Donut chart is visible |
| 4 | Verify the chart shows 2 colored segments | Two segments displayed (graded = green, pending = orange/red) |
| 5 | Verify legend labels show "Graded" and "Pending" with correct counts | Legend matches the 2 segments |

#### TC-P10: Top 6 Subjects Chart Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 3 | Scroll to the Top Subjects chart section | Horizontal bar chart is visible |
| 4 | Verify exactly 6 subject bars are displayed | Chart shows top 6 subjects ranked by homework count |
| 5 | Verify bars are ordered from highest to lowest count | Longest bar at top, shortest at bottom |

#### TC-P11: Latest 5 Submissions Table Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 3 | Scroll to the Latest 5 Submissions table section | Table with 5 rows is visible |
| 4 | Verify columns: Student Name, Homework Title, Status, Submitted Date | All expected columns present |
| 5 | Verify rows are in descending order by submission date | Most recent submission appears first |
| 6 | Verify each row shows a student avatar/name, homework title, and graded/pending badge | Data is populated and formatted correctly |

#### TC-P12: Filter By Class Updates All KPIs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework for Class A (3 homeworks) and Class B (2 homeworks) with assignments and submissions | Both classes have data |
| 2 | Login as admin | Dashboard loads |
| 3 | Navigate to Homework Analytics Dashboard | Dashboard shows all KPIs for all classes |
| 4 | Select Class A from class filter dropdown | Dashboard refreshes |
| 5 | Verify Active Homeworks KPI shows count for Class A only | Count matches Class A homeworks |
| 6 | Verify Total Assignments KPI shows assignments for Class A only | Count matches Class A assignments |
| 7 | Verify charts (bar/donut) reflect Class A data only | Charts updated |
| 8 | Switch filter to Class B and repeat verification | Class B data shown |

#### TC-P13: Filter By Subject Updates All KPIs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework for Subject A (4 homeworks) and Subject B (2 homeworks) with assignments and submissions | Both subjects have data |
| 2 | Login as admin | Dashboard loads |
| 3 | Navigate to Homework Analytics Dashboard | Dashboard renders with all subjects |
| 4 | Select Subject A from the filter dropdown | All 5 KPI cards update to show only Subject A data |
| 5 | Verify Active Homeworks reflects Subject A count | Count matches Subject A homeworks |
| 6 | Select Subject B from the filter dropdown | All KPIs update to Subject B data |
| 7 | Verify charts redraw with Subject B data | Charts update consistently |

#### TC-P14: Filter By Section Updates All KPIs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework for Section A and Section B with assignments and submissions | Both sections have data |
| 2 | Login as admin | Dashboard loads |
| 3 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 4 | Select Section A from the filter dropdown | All 5 KPI cards update to show only Section A data |
| 5 | Verify Total Submissions reflects only Section A submissions | Count matches Section A records |
| 6 | Clear the section filter | Dashboard returns to showing all sections |

#### TC-P15: Filter By Date Range Updates All KPIs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create submissions with dates in Week 1 (past 7-14 days) and Week 2 (past 0-7 days) | Data exists in two date ranges |
| 2 | Login as admin | Dashboard loads |
| 3 | Navigate to Homework Analytics Dashboard | Dashboard renders with all dates |
| 4 | Set date range filter to Week 1 (from/to 14 days ago to 7 days ago) | All KPIs update to show only Week 1 data |
| 5 | Verify Pending Grading count reflects Week 1 submissions | Count matches date-filtered DB query |
| 6 | Change date range to Week 2 (from/to 7 days ago to today) | All KPIs update to Week 2 data |

#### TC-P16: Multiple Filters Combine Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework across Class A/B, Subject X/Y, and different date ranges | Multi-dimensional test data exists |
| 2 | Login as admin | Dashboard loads |
| 3 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 4 | Select Class A + Subject X + date range (last 7 days) | All KPIs and charts reflect the intersection of these filters |
| 5 | Verify Active Homeworks count matches query: `SELECT COUNT(*) FROM lms_homework WHERE class_id = A AND subject_id = X AND status = PUBLISHED AND created_at >= date_range` | KPI matches combined filter DB query |
| 6 | Verify charts also respect the same combined filters | Chart data consistent with KPIs |

#### TC-P17: Clear Filters Resets To All Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders with unfiltered data |
| 3 | Note the initial KPI values | Baseline values recorded |
| 4 | Apply a Class filter | KPIs change to filtered subset |
| 5 | Apply a Subject filter | KPIs narrow further |
| 6 | Click "Clear Filters" or reset button | All filter dropdowns reset to default |
| 7 | Verify all KPI values return to the initial baseline values | Dashboard shows unfiltered data |

#### TC-P18: Empty State — No Data For Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders with data |
| 3 | Select a Class that has no homework or submissions | All KPI cards show 0 |
| 4 | Verify Active Homeworks = 0 | Empty state count 0 |
| 5 | Verify Total Assignments = 0 | Empty state count 0 |
| 6 | Verify charts show "No data available" message or empty state placeholder | Charts display gracefully without errors |
| 7 | Check browser console for JS errors | No Chart.js errors logged |

#### TC-P19: Submission Rate 0% When No Assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a published homework with NO assignments and NO submissions | Homework exists but has no assignment records |
| 2 | Login as admin | Dashboard loads |
| 3 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 4 | Apply a filter that isolates the homework with no assignments | Active Homeworks = 1, Total Assignments = 0 |
| 5 | Verify Submission Rate KPI shows 0% | No division-by-zero error, rate is 0% |

#### TC-P20: Dashboard Is Default Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to `/lms-home-work` without any `tab` query parameter | Page loads with the Homework Master hub |
| 3 | Verify that the Analytics Dashboard tab is automatically selected | Default active tab is `homework_analytics` |
| 4 | Verify that all 5 KPI cards and charts are rendered | Full analytics dashboard visible by default |

#### TC-P21: Submission Rate Color Coding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create test data resulting in submission rate >= 85% | High rate scenario ready |
| 2 | Login as admin and navigate to Analytics Dashboard | Dashboard renders |
| 3 | Check Submission Rate KPI for high rate scenario | Rate displayed in green color (success) |
| 4 | Create test data resulting in submission rate between 50% and 84% | Medium rate scenario ready |
| 5 | Refresh dashboard and check Submission Rate KPI | Rate displayed in amber/orange color (warning) |
| 6 | Create test data resulting in submission rate < 50% | Low rate scenario ready |
| 7 | Refresh dashboard and check Submission Rate KPI | Rate displayed in red color (danger) |

#### TC-N01: Permission 403 — No Dashboard Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.home-work-dashbord.viewAny` permission | Dashboard loads without Homework menu |
| 2 | Navigate directly to `/lms-home-work?tab=homework_analytics` | 403 Forbidden page displayed |

#### TC-N02: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open a new browser session and ensure user is logged out | No active session |
| 2 | Navigate to `/lms-home-work?tab=homework_analytics` | Redirected to login page |
| 3 | Verify the URL contains `/login` | Guest user cannot access dashboard |
| 4 | After login, verify dashboard loads correctly | Redirect back to dashboard after authentication |

#### TC-N03: Invalid Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 3 | Set From date to a date AFTER the To date (e.g., From = 2025-01-15, To = 2025-01-01) | Invalid range entered |
| 4 | Click "Apply" or submit the filter | Validation error message appears: "Please select a valid date range." |
| 5 | Correct the date range (From before To) and re-apply | KPIs update normally |

#### TC-N04: Very Large Dataset — Performance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Use DB seeding to create 10,000+ homework records with assignments and submissions across 50 classes | Large dataset exists |
| 2 | Login as admin | Dashboard loads |
| 3 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 4 | Measure page load time from navigation to full render | Load time is within acceptable threshold (e.g., < 5 seconds) |
| 5 | Apply class filter and measure response time | Filtered data loads within acceptable threshold |
| 6 | Verify no timeout or browser crash occurs | Page remains responsive |

#### TC-D01: Active Homeworks Count Only Includes PUBLISHED Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with DRAFT status (1 record) | Draft exists |
| 2 | Create homework with PUBLISHED status (3 records) | Published exists |
| 3 | Create homework with ARCHIVED status (1 record) | Archived exists |
| 4 | Load Analytics Dashboard | Active Homeworks = 3 (only published) |
| 5 | Verify Draft and Archived are excluded | Count correctly excludes non-published |

#### TC-D02: Total Assignments = SUM of All Assignment Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 3 | Note the Total Assignments KPI value | Value displayed |
| 4 | Run raw SQL: `SELECT COUNT(*) AS cnt FROM lms_homework_assignment ha JOIN lms_homework h ON ha.homework_id = h.id WHERE ha.is_active = 1 AND h.is_active = 1` | DB count matches Total Assignments KPI |
| 5 | Apply a subject filter and re-verify KPI vs filtered DB query | Assignment count remains consistent with DB |

#### TC-D03: Total Submissions <= Total Assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 3 | Note Total Assignments and Total Submissions KPI values | Both values displayed |
| 4 | Verify Total Submissions <= Total Assignments | Submission count does not exceed assignment count |
| 5 | Apply various filters (class, subject, date) | Invariant holds for every filter combination |

#### TC-D04: Pending Grading + Graded = Total Submissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 3 | Note Total Submissions, Pending Grading KPIs | Values displayed |
| 4 | Compute Graded = Total Submissions - Pending Grading | Graded count is consistent |
| 5 | Verify Graded count matches Donut chart "Graded" segment value | Donut chart graded count equals computed graded count |
| 6 | Verify Pending Grading + Graded = Total Submissions | Sum matches the Total Submissions KPI |

#### TC-D05: Filter Consistency — Same Filter Across All Queries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework for Class A and Class B with assignments and submissions in both | Data exists for both classes |
| 2 | Login as admin | Dashboard loads |
| 3 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 4 | Apply filter for Class A only | All 5 KPIs and 3 charts reflect Class A data |
| 5 | Run separate DB queries for Class A: Active Homeworks, Total Assignments, Total Submissions, Pending Grading, Submission Rate | Every KPI matches its respective DB query using class_id = A |
| 6 | Switch filter to Class B | All metrics consistently switch to Class B data |

#### TC-D06: Submission Count After Soft-Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create published homework with submissions | Active submissions exist |
| 2 | Login as admin and navigate to Analytics Dashboard | Dashboard renders |
| 3 | Note Total Submissions KPI | Baseline count recorded |
| 4 | Soft-delete a submission: `UPDATE lms_homework_submissions SET is_active = 0 WHERE id = X` | Submission marked inactive |
| 5 | Refresh the dashboard | Total Submissions count decreases by 1 |
| 6 | Verify DB query with `is_active = 1` matches the new KPI | KPI correctly excludes soft-deleted records |

#### TC-D07: Chart.js Renders Correctly With Empty Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 3 | Apply a filter that matches no data (e.g., nonexistent class) | All KPIs show 0 |
| 4 | Inspect the 7-Day Trend chart | Chart renders with empty bars or flat line (no JS errors) |
| 5 | Inspect the Graded vs Pending donut chart | Chart renders with empty segments or placeholder text |
| 6 | Inspect Top 6 Subjects chart | Chart renders with empty bars or "No data" message |
| 7 | Open browser console | Zero Chart.js errors or exceptions |

#### TC-D08: Submission Rate Decimal Precision

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exactly 3 assignments and 2 submissions for a specific filter | Rate = 66.67% expected |
| 2 | Login as admin | Dashboard loads |
| 3 | Navigate to Homework Analytics Dashboard | Dashboard renders |
| 4 | Apply filter that isolates the 3 assignments / 2 submissions scenario | KPIs show Total Assignments = 3, Total Submissions = 2 |
| 5 | Verify Submission Rate KPI displays exactly 1 decimal place | Rate shows "66.7%" |
| 6 | Create 1 assignment and 1 submission | Rate shows "100.0%" (not "100%") |

#### TC-D09: Access Via Hub Tab vs Direct URL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to `/lms-home-work` | Homework Master hub displays |
| 3 | Click the "Analytics Dashboard" tab | Dashboard renders with all KPIs and charts |
| 4 | Note the Active Homeworks count | Baseline recorded |
| 5 | Open a new tab and navigate directly to `/lms-home-work?tab=homework_analytics` | Same dashboard renders |
| 6 | Verify the Active Homeworks count matches the baseline | Both access methods show consistent data |

#### TC-CR01: Blade @can for Dashboard Tab Visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open the hub index Blade file (e.g., `index.blade.php` in LmsHomework module) | Source code is accessible |
| 2 | Locate the tab navigation section (typically `<ul class="nav nav-tabs">`) | Tab list is visible |
| 3 | Find the analytics dashboard tab `<li>` element | Tab exists |
| 4 | Verify the tab is wrapped in `@can('tenant.home-work-dashbord.viewAny')` directive | `@can` directive guards the analytics tab |
| 5 | Verify there is a corresponding `@endcan` closing tag | Directive is properly closed |

#### TC-CR02: Null-Safe Checks on Student/Homework Relations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open the controller source file (`LmsHomeworkController.php`) | Source code is accessible |
| 2 | Locate the method that builds the latest 5 submissions query | Query found (typically `HomeworkSubmission::latest()->limit(5)->get()`) |
| 3 | Inspect the Blade view that renders the latest submissions table | View file located |
| 4 | Verify `$submission?->student?->name` uses null-safe operator `?->` | Null-safe operator used for student relation |
| 5 | Verify `$submission?->homework?->title` uses null-safe operator `?->` | Null-safe operator used for homework relation |
| 6 | Verify all relation chaining uses `?->` instead of `->` | No unsafe chaining present |

#### TC-CR03: Filter Consistency — All Sub-Queries Share Same Scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open the controller source file (`LmsHomeworkController.php`) | Source code is accessible |
| 2 | Locate the `index()` method's analytics logic | Analytics query block identified |
| 3 | Inspect how class_id, subject_id, section_id, and date_range filters are applied | All 5 KPI queries use the same filter scope |
| 4 | Verify filters are not duplicated or hardcoded per query | A shared scope or conditional `where` block is used |
| 5 | Confirm that chart queries also reuse the same filter scope | Charts and KPIs share identical filter logic |

#### TC-CR04: Chart.js Renders With Empty/Zero Datasets

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open the Blade view or JS file containing Chart.js initialization code | Chart setup code is accessible |
| 2 | Locate the bar chart (7-Day Trend) dataset initialization | Dataset config found |
| 3 | Verify the code handles empty `data` arrays with `data: []` or conditional rendering | Empty array does not cause Chart.js error |
| 4 | Locate the donut chart (Graded vs Pending) initialization | Donut chart code found |
| 5 | Verify zero-value segments are handled (no 0/0 division) | Graceful handling of zero counts |
| 6 | Check for `console.error` or try-catch around chart initialization | Errors are caught and logged gracefully |

#### TC-CR05: Aggregate Queries Single-SQL, No N+1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open the controller source file (`LmsHomeworkController.php`) | Source code is accessible |
| 2 | Locate each KPI query (Active Homeworks, Total Assignments, etc.) | 5 separate aggregate queries identified |
| 3 | Verify each KPI is a single `COUNT()` or aggregate query (no loops) | Each KPI is one DB call |
| 4 | Locate the Latest 5 Submissions query | Query found |
| 5 | Verify `with(['student', 'homework'])` eager-loading is used | Relations are eager-loaded, not lazy-loaded |
| 6 | Confirm there is no `foreach` over submissions making individual DB calls | No N+1 pattern present |

#### TC-CR06: Dashboard is Read-Only — No Action Buttons Present

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `analytics/index.blade.php` (the analytics dashboard view) | File loaded |
| 2 | Search for any `<form>` with POST/DELETE/PUT method, `<a>` with delete/remove class, or button with create/edit/delete action | No create, edit, or delete controls present |
| 3 | Search for route names containing `create`, `edit`, `store`, `update`, `destroy` in the view | None referenced in analytics blade |
| 4 | Verify the view only renders KPI cards, charts, and the latest submissions table | Only read-only display widgets present |
| 5 | Confirm no inline editing or row-action dropdowns exist in the table | Table rows are display-only, no action buttons |
