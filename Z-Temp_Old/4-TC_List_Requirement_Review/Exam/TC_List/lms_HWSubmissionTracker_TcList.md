# lms_HWSubmissionTracker_TcList

## Module: LmsExam → Advanced Reports → HW Submission Tracker

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Advanced Reports |
| Feature | HW Submission Tracker |
| URL(s) | `/lms-exam/exam-advanced-reports?active_tab=hw-submission-tracker` (index) |
| Controller | `Modules\LmsExam\Http\Controllers\ExamAdvancedReportController@index()` |
| Method (Data) | `generateHwSubmissionData()` (private, line 146) |
| Model(s) | `Modules\LmsHomework\Models\Homework`, `Modules\LmsHomework\Models\HomeworkAssignment`, `Modules\LmsHomework\Models\HomeworkSubmission` |
| View (Partial) | `advanced-reports/partials/hw-submission-tracker.blade.php` |
| Permissions | `tenant.lms-exam-report.viewAny` |
| Pagination | 15 per page (homeworks), 10 per page (modal details) |
| Charts | ApexCharts: donut (status), area (engagement trend) |
| Date Range Library | daterangepicker with moment.js |

---

## 2. Pre-conditions

- Required permission: `tenant.lms-exam-report.viewAny`
- Required seed data: Multiple `Homework` records with `HomeworkAssignment` and `HomeworkSubmission` records
- Submissions must have varied statuses: submitted, pending, late, graded, resubmission requested
- At least 15+ homework records for pagination testing
- Modal detail pagination requires 10+ students assigned per homework
- Late submissions must have `is_late=true` flag set
- Graded submissions must have `marks_obtained` set (not null)
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

When the page loads via `ExamAdvancedReportController@index()` (GET /lms-exam/exam-advanced-reports with `active_tab=hw-submission-tracker`), the following data is fetched:

| Widget/Chart | Data Source | Query Logic | Filters |
|-------------|-------------|-------------|---------|
| Shared Dropdowns | Same as HW Performance (classes, sections, subjects, lessons, topics, exams, students, teachers) | — | — |
| **Metrics Cards (5)** | `generateHwSubmissionData()` → `$metrics` | Aggregated totals: assignments, submitted, pending, late, avg_rate | class_id, section_id, subject_id, lesson_id, topic_id, date_from, date_to |
| **Submission Status Donut** | `generateHwSubmissionData()` → `$charts['status']` | Labels: Submitted, Pending, Late; Series: counts | Same filters |
| **Engagement Trend Area** | `generateHwSubmissionData()` → `$charts['trend']` | Last 10 homeworks submission counts | Same filters |
| **Homework Ledger Table** | `generateHwSubmissionData()` → `$homeworks` | Per-HW row with submission stats | Same filters |
| **Student Detail Modals** | `generateHwSubmissionData()` → `$detail_data` | Per-student submission details per HW | Same filters |
| **Paginator** | `LengthAwarePaginator` on homeworks | 15 per page | request('page', 1) |

---

## 4. Test Data Strategy

- **Core dataset**: Seed 20+ homework records with 10+ assignments each across multiple classes/subjects
- **Submission mix**: 60% submitted, 20% late, 20% pending across the dataset
- **Grading mix**: 50% of submissions graded (marks_obtained set), 50% ungraded
- **Late submissions**: Ensure at least 5 homeworks have `is_late=true` submissions
- **Resubmission**: Some homeworks with `is_resubmission_requested=true`
- **Empty state**: Class/subject combination with zero homework records
- **Date range**: Homeworks spread across a 90-day window
- **Pre-test cleanup**: Delete created homework/submission/assignment records

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
| BC-DB-08 | assign_date | DATE | NOT NULL |
| BC-DB-09 | due_date | DATE | NOT NULL |
| BC-DB-10 | max_marks | DECIMAL(8,2) | NOT NULL DEFAULT 0 |
| BC-DB-11 | is_gradable | TINYINT(1) | DEFAULT 1 |
| BC-DB-12 | is_active | TINYINT(1) | DEFAULT 1 |
| BC-DB-13 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-14 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

#### `lms_homework_assignments` (LmsHomework module)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-15 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-16 | homework_id | INT UNSIGNED | NOT NULL, FK → `lms_homeworks.id` (CASCADE) |
| BC-DB-17 | student_id | INT UNSIGNED | NOT NULL, FK → `std_students.id` (CASCADE) |
| BC-DB-18 | is_active | TINYINT(1) | DEFAULT 1 |
| BC-DB-19 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

#### `lms_homework_submissions` (LmsHomework module)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-20 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-21 | homework_id | INT UNSIGNED | NOT NULL, FK → `lms_homeworks.id` (CASCADE) |
| BC-DB-22 | student_id | INT UNSIGNED | NOT NULL, FK → `std_students.id` (CASCADE) |
| BC-DB-23 | marks_obtained | DECIMAL(8,2) | NULLABLE |
| BC-DB-24 | is_late | TINYINT(1) | DEFAULT 0 |
| BC-DB-25 | is_resubmission_requested | TINYINT(1) | DEFAULT 0 |
| BC-DB-26 | teacher_feedback | TEXT | NULLABLE |
| BC-DB-27 | submitted_at | DATETIME | NULLABLE |
| BC-DB-28 | is_active | TINYINT(1) | DEFAULT 1 |
| BC-DB-29 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-30 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

### 4.2 Filter/Input Validation

| BC ID | Filter Field | Type | Validation Logic | Default |
|-------|-------------|------|------------------|---------|
| BC-VAL-01 | class_id | INT | NULLABLE; must exist in sch_classes | null |
| BC-VAL-02 | section_id | INT | NULLABLE; must exist in sch_sections | null |
| BC-VAL-03 | subject_id | INT | NULLABLE; must exist in sch_subjects | null |
| BC-VAL-04 | lesson_id | INT | NULLABLE; must exist in slb_lessons | null |
| BC-VAL-05 | topic_id | INT | NULLABLE; must exist in slb_topics | null |
| BC-VAL-06 | date_from | DATE | NULLABLE; parsed via Carbon::parse | now()->subDays(30) |
| BC-VAL-07 | date_to | DATE | NULLABLE; parsed via Carbon::parse | now() |
| BC-VAL-08 | active_tab | STRING | Hidden; always 'hw-submission-tracker' | 'hw-submission-tracker' |

### 4.3 Authorization

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.lms-exam-report.viewAny | index() | Without → 403 Forbidden |
| BC-AUTH-02 | Guest access | Any reports route | Redirect to /login |

### 4.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Metrics Computation | `$totals['asgnd']` = total assignments, `$totals['subm']` = count of submissions, `$totals['pending']` = assigned - submitted, `$totals['late']` = submissions where is_late=true, `$totals['graded']` = submissions where marks_obtained not null |
| BC-BIZ-02 | Compliance Rate | `(submitted / assigned) × 100` displayed as avg_rate |
| BC-BIZ-03 | Status Donut Chart | Three segments: Submitted (green), Pending (yellow), Late (red); center shows compliance % |
| BC-BIZ-04 | Engagement Trend | Area chart of submission counts for last 10 homeworks (ordered by assign_date desc) |
| BC-BIZ-05 | Ledger Pagination | 15 homeworks per page using LengthAwarePaginator |
| BC-BIZ-06 | Per-HW Submission Rate | Calculated as `(submissions / assignments) × 100` for display |
| BC-BIZ-07 | Late Badge | If HW has late submissions > 0, badge shows red; else muted |
| BC-BIZ-08 | Pending Badge | If HW has pending > 0, badge shows yellow/warning; else green/success |
| BC-BIZ-09 | Section Null Inclusion | When section filter active, `WHERE section_id = ? OR section_id IS NULL` |
| BC-BIZ-10 | Detail Modal Pagination | 10 students per page with prev/next navigation |
| BC-BIZ-11 | Student Name in Modal | Shows avatar initial + full name |
| BC-BIZ-12 | Status Label Mapping | Null submission → 'Pending', resubmission_requested → 'Resubmission Requested', marks_obtained not null → 'Graded', else 'Submitted' |
| BC-BIZ-13 | Timing Badge | is_late → red 'Late' badge; else green 'On Time' badge |
| BC-BIZ-14 | Feedback Truncation | Feedback truncated at 50 chars with ellipsis in modal |
| BC-BIZ-15 | Empty Homework Collection | When no homeworks match filters: show empty state card with message "Please select filters and generate the report to see tracking analytics." |
| BC-BIZ-16 | Detail Modal Empty | If no detail data, modal shows "No submission records available." |

### 4.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | homework.class_id | sch_classes.id | CASCADE |
| BC-REF-02 | homework.section_id | sch_sections.id | SET NULL |
| BC-REF-03 | homework.subject_id | sch_subjects.id | CASCADE |
| BC-REF-04 | assignment.homework_id | lms_homeworks.id | CASCADE |
| BC-REF-05 | assignment.student_id | std_students.id | CASCADE |
| BC-REF-06 | submission.homework_id | lms_homeworks.id | CASCADE |
| BC-REF-07 | submission.student_id | std_students.id | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Submission Tracker page loads with all UI elements | Page loads with 6 filter controls, 5 metric cards, 2 charts, ledger table, and pagination | — | — | ⬜ |
| TC-P02 | Metrics cards display correct values | Assignments, Submissions, Pending, Late Items, Compliance % all correct | — | — | ⬜ |
| TC-P03 | Status donut chart shows correct proportions | Submitted/Pending/Late segments correct; center shows compliance % | — | — | ⬜ |
| TC-P04 | Engagement trend area chart renders | Shows last 10 homeworks submission count trend | — | — | ⬜ |
| TC-P05 | Ledger table shows correct columns | #, Homework Item, Class, Subject, Assign Date, Due Date, Assigned, Subm., Late, Graded, Pending, Action | — | — | ⬜ |
| TC-P06 | Per-HW submission stats correct | assigned/submitted/late/graded/pending counts match seed data | — | — | ⬜ |
| TC-P07 | Late badge turns red when late > 0 | Badge shows bg-danger-subtle text-danger when late count > 0 | — | — | ⬜ |
| TC-P08 | Pending badge turns yellow when pending > 0 | Badge shows bg-warning-subtle text-warning when pending > 0 | — | — | ⬜ |
| TC-P09 | Action button opens detail modal | Clicking eye button opens modal with student details | — | — | ⬜ |
| TC-P10 | Detail modal shows student information | Name with avatar, Submitted At, Status, Timing, Marks, Feedback | — | — | ⬜ |
| TC-P11 | Detail modal pagination works (10 per page) | If >10 students, pagination controls visible and functional | — | — | ⬜ |
| TC-P12 | Filter by class scopes data | Selecting class shows only that class's homework records | — | — | ⬜ |
| TC-P13 | Filter by section scopes data | Selecting section narrows to that section's records | — | — | ⬜ |
| TC-P14 | Filter by subject scopes data | Selecting subject shows only that subject's homeworks | — | — | ⬜ |
| TC-P15 | Filter by lesson scopes data | Selecting lesson narrows to that lesson's homeworks | — | — | ⬜ |
| TC-P16 | Filter by topic scopes data | Selecting topic narrows to that topic's homeworks | — | — | ⬜ |
| TC-P17 | Filter by date range scopes homeworks | Homeworks within date range displayed; outside excluded | — | — | ⬜ |
| TC-P18 | Combined filters scope precisely | Multiple filters combined narrow to exact subset | — | — | ⬜ |
| TC-P19 | Pagination — first page | First 15 homeworks displayed on page 1 | — | — | ⬜ |
| TC-P20 | Pagination — subsequent pages | Clicking page 2 shows next 15 homeworks | — | — | ⬜ |
| TC-P21 | Reset button clears all filters | URL resets, dropdowns default, all data shown | — | — | ⬜ |
| TC-P22 | Date range presets work | Today, Last 7 Days, Last 30 Days, This Month apply correct dates | — | — | ⬜ |
| TC-P23 | Cascading dropdowns load dependencies | Class → sections+subjects, Subject → lessons, Lesson → topics | — | — | ⬜ |
| TC-P24 | Detail modal marks display | Graded submissions show marks; ungraded show '—' | — | — | ⬜ |
| TC-P25 | Feedback truncation in modal | Feedback >50 chars truncated with '...' | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Permission 403 — No viewAny permission | User without permission gets 403 | — | — | ⬜ |
| TC-N02 | Guest access redirect | Unauthenticated user redirected to /login | — | — | ⬜ |
| TC-N03 | Empty state — no homeworks match filters | Empty state card with message and Clear Filters button | — | — | ⬜ |
| TC-N04 | Empty detail modal — no submissions | Modal shows "No submission records available." | — | — | ⬜ |
| TC-N05 | No class selected with section filter | Section dropdown disabled; section filter not applied | — | — | ⬜ |
| TC-N06 | Invalid class_id | Shows empty state; no 500 error | — | — | ⬜ |
| TC-N07 | Invalid date format | Defaults to last 30 days; no 500 error | — | — | ⬜ |
| TC-N08 | Malformed page parameter | `?page=-1` or `?page=abc` defaults to page 1 | — | — | ⬜ |
| TC-N09 | Page exceeding total pages | Shows last page gracefully; no 500 error | — | — | ⬜ |
| TC-N10 | No submissions at all | All metrics show 0; donut shows only pending | — | — | ⬜ |
| TC-N11 | All submissions are late | Donut shows all red (late); compliance = 0% | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Creating a new homework adds row to ledger | New HW appears after page refresh | — | — | ⬜ |
| TC-D02 | B | Student submitting homework updates counters | Submissions count increases, pending decreases | — | — | ⬜ |
| TC-D03 | C | Deleting homework removes it from ledger | HW no longer visible; pagination recalculated | — | — | ⬜ |
| TC-D04 | D | Large dataset (50+ homeworks) pagination accuracy | All pages paginate correctly; no missing/duplicate data | — | — | ⬜ |
| TC-D05 | E | Cross-module: HW from LmsHomework appears | All HW records from module reflected in tracker | — | — | ⬜ |
| TC-D06 | F | Teacher grading updates graded count | After grading, graded count increments | — | — | ⬜ |
| TC-D07 | G | Late submission flag updates late count | Setting is_late=true updates late counter | — | — | ⬜ |
| TC-D08 | H | Resubmission request status in modal | Modal shows 'Resubmission Requested' label | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based tab visibility | Tab wrapped by @can('tenant.lms-exam-report.viewAny') | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — `generateHwSubmissionData()` private method at line 146 | Returns array with homeworks, totals, metrics, detail_data, charts, paginator | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | View — null-safe checks on relationships ($hw->subject?->name) | All accesses use ?-> or optional(); no undefined errors | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | View — Submission status badge logic in getSubmissionStatusLabel() | Null → Pending, resubmission → Resubmission Requested, graded → Graded, else Submitted | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | JS — Modal pagination client-side logic | window.hwPagin object stores page functions; renderPage() shows 10 items per page | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | JS — ApexCharts donut and area charts | Donut with 3 segments + center total label; Area with smooth curve gradient | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | JS — Date range picker hidden inputs sync | apply sets hidden date_from/date_to; cancel clears them | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | JS — AJAX cascading dropdowns | Class→Section+Subject, Subject→Lesson, Lesson→Topic via getDependencies() | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | View — Empty state @if(!empty()) guards | Ledger table and modals wrapped with @if(!empty($hwSubmissionData['homeworks'])) | — | — | ◌ |
| TC-CR10 | CR | Code Review | P1 | Controller — parseDateRange() exception handling | Invalid dates caught; defaults to last 30 days | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Blade @can Directives — Permission-based Tab Visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect advanced-reports/index.blade.php | Tab wrapped by @can('tenant.lms-exam-report.viewAny') |
| 2 | Check nav-tab permission attribute | Tab permission = 'tenant.lms-exam-report.viewAny' |
| 3 | Login as user with viewAny permission | HW Submission Tracker tab visible |
| 4 | Login as user without viewAny permission | Tab hidden; 403 on direct URL |

---

#### TC-CR02: Controller — `generateHwSubmissionData()` Private Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller at line 146 | Method found with Request parameter |
| 2 | Verify date filter logic | Date range applied via whereBetween('assign_date', ...) |
| 3 | Verify filter chaining | class_id, section_id, subject_id, lesson_id, topic_id all chained |
| 4 | Verify return structure | Returns array with homeworks, totals, metrics, detail_data, charts, paginator |
| 5 | Check paginator | LengthAwarePaginator with 15 per page |
| 6 | Check section null handling | OR whereNull('section_id') for section filter |

---

#### TC-CR03: View — null-safe Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open hw-submission-tracker.blade.php | View file in partials/ |
| 2 | Scan for $hw->subject?->name patterns | All use ?-> or optional() |
| 3 | Scan for $hw->class?->name patterns | Null-safe operators used |
| 4 | Load with missing relations | No 500 errors; dashes displayed |

---

#### TC-CR04: Submission Status Label Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller at line 800 | getSubmissionStatusLabel() method |
| 2 | Test null submission | Returns 'Pending' |
| 3 | Test is_resubmission_requested=true | Returns 'Resubmission Requested' |
| 4 | Test marks_obtained not null | Returns 'Graded' |
| 5 | Test submitted but no marks | Returns 'Submitted' |

---

#### TC-CR05: JS — Modal Pagination Client-Side

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect modal JS at line 241 | window.hwPagin global object stores page functions per HW ID |
| 2 | Verify renderPage function | Calculates start/end indices, builds HTML rows |
| 3 | Verify pagination controls | Prev/Next with page numbers; ellipsis for >7 pages |
| 4 | Verify 10 per page | perPage = 10 constant |
| 5 | Verify showing X-Y of Z label | Bottom-left shows range info |

---

#### TC-CR06: JS — ApexCharts Donut and Area Charts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check donut chart config at line 387 | type:'donut', series from status data, colors: green/yellow/red |
| 2 | Verify center total label | Donut center shows 'Completion' label with avg_rate value |
| 3 | Check area chart config at line 415 | type:'area', smooth curve, gradient fill |
| 4 | Verify x-axis categories | Homework titles from trend labels |
| 5 | Verify chart IDs | #hwStatusChart and #hwTrendChart |

---

#### TC-CR07: JS — Date Range Picker Hidden Inputs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect daterangepicker at line 309 | Picker on #hw_tracker_daterange |
| 2 | Verify apply handler | Sets #hw_tracker_df and #hw_tracker_dt with YYYY-MM-DD |
| 3 | Verify cancel handler | Clears both hidden inputs |
| 4 | Verify presets | Today, Last 7 Days, Last 30 Days, This Month |
| 5 | Verify pre-population | Existing date_from/date_to shown as formatted range |

---

#### TC-CR08: JS — AJAX Cascading Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check class change handler at line 345 | AJAX to depsUrl with class_id |
| 2 | Verify sections/subjects populated | res.sections → #filter_hw_section, res.subjects → #filter_hw_subject |
| 3 | Check subject change at line 360 | type:'lessons' populates #filter_hw_lesson |
| 4 | Check lesson change at line 370 | type:'topics' populates #filter_hw_topic |
| 5 | Verify populate() function | Builds option elements, re-enables dropdown |

---

#### TC-CR09: Empty State Guards

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade at line 70 | @if(!empty($hwSubmissionData['homeworks'])) wraps metrics + charts + table |
| 2 | Verify @else shows empty state | Card with icon, message, Clear Filters button |
| 3 | Verify modal empty state at line 232 | Modal shows "No submission records available." |
| 4 | Verify @endif placement | All content correctly guarded |

---

#### TC-CR10: parseDateRange Exception Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller at line 136 | Method visible |
| 2 | Verify try/catch | Invalid dates caught |
| 3 | Test with valid dates | Returns [startOfDay, endOfDay] |
| 4 | Test with invalid dates | Falls back to [now()->subDays(30), now()] |

---

### 6.1 Positive TC Steps

#### TC-P01: Submission Tracker Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Advanced Reports → HW Submission Tracker | Tab pane shown |
| 3 | Check filter bar | 6 filter controls: Class, Section, Subject, Lesson, Topic, Date Range |
| 4 | Check metric cards | 5 cards: Assignments, Submissions, Pending, Late Items, Compliance |
| 5 | Check charts | Donut chart and area chart rendered |
| 6 | Check ledger table | Table with 12 columns; pagination links if 15+ HWs |

---

#### TC-P02: Metrics Cards Display Correct Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 3 HWs, 30 assignments, 20 submissions, 5 late, 10 pending | Fixed dataset |
| 2 | Navigate to tracker | Assignments = 30, Submissions = 20, Pending = 10, Late = 5 |
| 3 | Verify Compliance = 66.7% | (20/30) × 100 = 66.7% |

---

#### TC-P03: Status Donut Chart Shows Correct Proportions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 20 subm, 10 pending, 5 late | Chart data |
| 2 | Navigate to tracker | Donut segments: green (submitted), yellow (pending), red (late) |
| 3 | Hover over submitted segment | Tooltip shows "Submitted: 20" |

---

#### TC-P04: Engagement Trend Area Chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 10+ homeworks with varied submission counts | Trend data |
| 2 | Navigate to tracker | Area chart shows submission count trend |
| 3 | Verify last 10 HWs shown | Chart limited to 10 data points |

---

#### TC-P05: Ledger Table Column Headers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to tracker | Table rendered |
| 2 | Verify 12 columns | #, Homework Item, Class, Subject, Assign Date, Due Date, Assigned, Subm., Late, Graded, Pending, Action |
| 3 | Verify column order matches spec | Correct sequence |

---

#### TC-P06: Per-HW Submission Stats

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: HW-X with 10 assignments, 7 submissions (2 late, 3 graded), 3 pending | Fixed |
| 2 | Navigate to tracker | HW-X row: Assigned=10, Subm=7, Late=2, Graded=3, Pending=3 |

---

#### TC-P07: Late Badge Color

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HW with late=3 | Late > 0 |
| 2 | Check Late badge | bg-danger-subtle text-danger applied |
| 3 | Seed HW with late=0 | Late badge shows bg-light text-muted |

---

#### TC-P08: Pending Badge Color

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HW with pending=5 | Pending > 0, badge shows bg-warning-subtle text-warning |
| 2 | Seed HW with pending=0 | Badge shows bg-success-subtle text-success |

---

#### TC-P09: Action Button Opens Detail Modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click eye button on any HW row | Modal opens with #modal-hw-{id} |
| 2 | Verify modal title shows HW name | Modal header shows homework title |
| 3 | Verify student count shown | "Student Submission Details (X students)" |
| 4 | Close modal | Modal dismissed correctly |

---

#### TC-P10: Detail Modal Student Information

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open detail modal | Student rows visible |
| 2 | Check student column | Avatar initial + full name |
| 3 | Check Submitted At column | Date/time formatted (d-M-y H:i) |
| 4 | Check Status column | Graded/Submitted/Pending/Resubmission Requested badge |
| 5 | Check Timing column | On Time (green) or Late (red) badge |
| 6 | Check Marks column | Marks obtained or '—' |
| 7 | Check Feedback column | Teacher feedback text (truncated) |

---

#### TC-P11: Detail Modal Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HW with 25 students | 25 detail records |
| 2 | Open modal | Page 1 shows 10 students |
| 3 | Click page 2 | Shows records 11-20 |
| 4 | Click page 3 | Shows records 21-25 |
| 5 | Verify showing label | "Showing 1-10 of 25" |

---

#### TC-P12: Filter By Class Scopes Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class A (5 HWs), Class B (3 HWs) | Two classes |
| 2 | Select Class A | Only Class A HWs in ledger |
| 3 | Select Class B | Only Class B HWs in ledger |
| 4 | No filter | All 8 HWs visible |

---

#### TC-P13: Filter By Section Scopes Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Sec A (3 HWs), Sec B (2 HWs) | Two sections |
| 2 | Select class then Section A | Only Section A HWs |

---

#### TC-P14: Filter By Subject Scopes Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Math (4 HWs), Science (2 HWs) | Two subjects |
| 2 | Select Math | Only Math HWs shown |

---

#### TC-P15: Filter By Lesson Scopes Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Lesson 1 (2 HWs), Lesson 2 (3 HWs) | Two lessons |
| 2 | Select Lesson 1 | Only Lesson 1 HWs |

---

#### TC-P16: Filter By Topic Scopes Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Topic A (2 HWs), Topic B (1 HW) | Two topics |
| 2 | Select Topic A | Only Topic A HWs shown |

---

#### TC-P17: Filter By Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Jan (3 HWs), Feb (2 HWs), Mar (2 HWs) | Three months |
| 2 | Set Jan 1-31 | 3 HWs visible |
| 3 | Set Feb 1-28 | 2 HWs visible |
| 4 | Set Jan 1 - Mar 31 | All 7 HWs visible |

---

#### TC-P18: Combined Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class A / Math / Jan (2 HWs), Class A / Science / Jan (2 HWs) | Multi-dimension |
| 2 | Select Class A + Math + Jan | 2 HWs visible |
| 3 | Select Class A + Science + Jan | 2 HWs visible |

---

#### TC-P19: Pagination — First Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 25 homeworks | 25 records |
| 2 | Navigate to page 1 | 15 records shown |
| 3 | Verify pagination links | Page 1 active; page 2 visible |

---

#### TC-P20: Pagination — Subsequent Pages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click page 2 | Records 16-25 shown |
| 2 | Verify page 2 active | Page 2 highlighted |
| 3 | Click Previous | Returns to page 1 |

---

#### TC-P21: Reset Button

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filters | URL has parameters |
| 2 | Click Reset | URL clears; filters default |

---

#### TC-P22: Date Range Presets

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open date picker | Presets: Today, Last 7 Days, Last 30 Days, This Month |
| 2 | Select Today | date_from = today, date_to = today |
| 3 | Select Last 30 Days | date_from = 30 days ago |

---

#### TC-P23: Cascading Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a class | Sections and subjects load via AJAX |
| 2 | Select a subject | Lessons load via AJAX |
| 3 | Select a lesson | Topics load via AJAX |

---

#### TC-P24: Detail Modal Marks Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed graded submission with marks=45 | Marks shown |
| 2 | Open modal | Marks column shows '45' |

---

#### TC-P25: Feedback Truncation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed feedback with 100 chars | Long feedback |
| 2 | Open modal | Feedback truncated to 50 chars + '...' |

---

### 6.2 Negative TC Steps

#### TC-N01: Permission 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without permission | Dashboard loads |
| 2 | Navigate to report URL | 403 Forbidden |
| 3 | Tab hidden from UI | Not visible in tab bar |

---

#### TC-N02: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout | Redirected |
| 2 | Navigate to URL | Redirected to /login |

---

#### TC-N03: Empty State — No Homeworks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class with no HWs | No data |
| 2 | Empty state shown | Card with icon and message |
| 3 | Clear Filters button present | Link to reset |

---

#### TC-N04: Empty Detail Modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open modal for HW with no submissions | Modal shows "No submission records available." |
| 2 | Verify no data rows | Empty table body |

---

#### TC-N05: Section Without Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set section_id only | Section dropdown disabled without class_id |
| 2 | Filter not applied | All sections data shown |

---

#### TC-N06: Invalid class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate with ?class_id=99999 | No 500 error |
| 2 | Empty state shown | Empty data message |

---

#### TC-N07: Invalid Date Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set invalid date | Defaults to last 30 days |
| 2 | No 500 error | Graceful handling |

---

#### TC-N08: Malformed Page Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | ?page=-1 | Defaults to page 1 |
| 2 | ?page=abc | Defaults to page 1 |

---

#### TC-N09: Page Exceeding Total

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | With 2 pages, navigate to ?page=999 | Shows last page |
| 2 | No 500 error | Graceful |

---

#### TC-N10: No Submissions At All

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HWs with assignments but no submissions | All pending |
| 2 | Metrics: submitted=0, pending=total, late=0 | Donut shows 100% pending |

---

#### TC-N11: All Submissions Late

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed all submissions with is_late=true | All late |
| 2 | Late count = submission count | Donut shows all late |

---

### 6.3 Dependency TC Steps

#### TC-D01: Creating New Homework Adds Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note HW count = X | Current count |
| 2 | Create new homework | HW created |
| 3 | Refresh tracker | Count = X+1 |

---

#### TC-D02: Student Submitting Updates Counters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note pending count for HW | Pending = X |
| 2 | Student submits homework | Submission created |
| 3 | Refresh tracker | Pending = X-1; Submissions = Y+1 |

---

#### TC-D03: Deleting Homework Removes Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note HW count = X | Current count |
| 2 | Soft-delete HW | HW trashed |
| 3 | Refresh tracker | Count = X-1 |

---

#### TC-D04: Large Dataset Pagination Accuracy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 50+ homeworks | 50 records |
| 2 | Page 1 shows 1-15 | Correct |
| 3 | Page 2 shows 16-30 | Correct |
| 4 | Page 3 shows 31-45 | Correct |
| 5 | Page 4 shows 46-50 | Correct |

---

#### TC-D05: Cross-Module HW Reflection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create HW via LmsHomework module | HW created |
| 2 | Refresh tracker | New HW appears |

---

#### TC-D06: Teacher Grading Updates Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note graded count = X | Before grading |
| 2 | Grade a submission | marks_obtained set |
| 3 | Refresh tracker | Graded = X+1 |

---

#### TC-D07: Late Flag Updates Late Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note late count = X | Before update |
| 2 | Set submission is_late=true | Flag updated |
| 3 | Refresh tracker | Late = X+1 |

---

#### TC-D08: Resubmission Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set is_resubmission_requested=true | Flag set |
| 2 | Open detail modal | Status shows "Resubmission Requested" |

---

### 6.4 Code Review TC Steps

#### TC-CR04: Submission Status Label Mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect getSubmissionStatusLabel at line 800 | Returns correct label based on submission state |
| 2 | Test null submission | 'Pending' |
| 3 | Test is_resubmission_requested=true | 'Resubmission Requested' |
| 4 | Test marks_obtained not null | 'Graded' |
| 5 | Test submitted without marks | 'Submitted' |

---

#### TC-CR05: Modal Pagination Client-Side JS

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect JS at line 241 | window.hwPagin global pagination system |
| 2 | Verify renderPage function | Correctly slices details array by page |
| 3 | Verify ellipsis for >7 pages | Smart ellipsis rendering |
| 4 | Verify page click handler | Pagination links call window.hwPagin[hwId](page) |

---

#### TC-CR06: ApexCharts Configuration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect donut chart at line 387 | type:'donut', 3 colors, center total label |
| 2 | Verify donut center formatter | Shows compliance rate percentage |
| 3 | Inspect area chart at line 415 | type:'area', smooth curve, blue gradient |
| 4 | Verify data labels from backend | sD.series and tD.series from @json |

---

#### TC-CR09: Empty State Guards

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade line 70 | @if(!empty($hwSubmissionData['homeworks'])) |
| 2 | Verify metrics/charts/table inside guard | Only rendered when data present |
| 3 | Verify @else block contains empty state | Icon + message + Clear Filters button |

---

#### TC-CR11: Controller — Section NULL Handling Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller at line 162 | Section filter uses orWhereNull('section_id') |
| 2 | Verify HW with section_id=NULL included | NULL section homeworks always included in results |
| 3 | Test section filter = 1 | HWs with section_id=1 AND HWs with section_id=NULL appear |
| 4 | Test section filter = 2 | HWs with section_id=2 AND NULL section appear |

---

#### TC-CR12: Controller — Date Range conditional filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 148-151 | $hasDateFilter = both date_from and date_to present |
| 2 | Verify whereBetween only when hasDateFilter | Query builder conditionally adds date range clause |
| 3 | Test with both dates | whereBetween('assign_date', [$dateFrom, $dateTo]) applied |
| 4 | Test without dates | No date filter; all records returned |

---

#### TC-CR13: View — Homework ID formatting

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 163 | ID formatted as str_pad((string)$hw['id'], 5, '0', STR_PAD_LEFT) |
| 2 | Test HW ID = 1 | Displays as "#00001" |
| 3 | Test HW ID = 12345 | Displays as "#12345" |

---

#### TC-CR14: View — Modal JS inline within @foreach

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect modal script at line 241 | Script inside @foreach creates per-HW pagination |
| 2 | Verify no duplicate variable declarations | var keyword used (block scoped) |
| 3 | Verify window.hwPagin creation | Only created once (if(!window.hwPagin) check) |

---

#### TC-CR15: View — Modal Late/Timing Badge Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 257-259 | Ternary: late === 'Yes' → red 'Late', else green 'On Time' |
| 2 | Test late = 'Yes' | Badge: bg-danger-subtle text-danger |
| 3 | Test late = 'No' | Badge: bg-success-subtle text-success |
| 4 | Test late = null | Defaults to green 'On Time' (else branch) |

---

#### TC-P26: Compliance Rate Calculation Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 50 assignments total, 35 submitted | Expected compliance = 70% |
| 2 | Verify metrics card shows 70% | avg_rate = round(35/50 * 100, 1) = 70.0% |

---

#### TC-P27: Graded Count Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HW with 8 submissions: 5 graded, 3 ungraded | Graded count = 5 |
| 2 | Verify ledger row shows Graded = 5 | Correct count displayed in #graded column |

---

#### TC-P28: Resubmission Count Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HW with 2 resubmission-requested submissions | Resubm count = 2 |
| 2 | Verify #resubm column shows 2 | Correct resubmission count |

---

#### TC-P29: Feedback Display — Short Feedback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed feedback = "Good work!" (10 chars) | ≤ 50 chars |
| 2 | Open modal | Full feedback displayed without truncation |

---

#### TC-P30: Timing Label — On Time Submission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed submission with is_late=false | On time |
| 2 | Open modal | Timing column shows green "On Time" badge |

---

#### TC-P31: Timing Label — Late Submission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed submission with is_late=true | Late |
| 2 | Open modal | Timing column shows red "Late" badge |

---

#### TC-P32: Student Avatar Initials in Modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed student named "John Doe" | First char = 'J' |
| 2 | Open modal | Avatar circle shows "J" |

---

#### TC-P33: Modal Detail Row Count Accuracy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HW with exactly 10 students | 10 detail records |
| 2 | Open modal | Page 1 shows all 10; pagination shows 1 page only |
| 3 | Seed HW with 11 students | 11 records |
| 4 | Open modal | Page 1 shows 10; page 2 link appears |

---

#### TC-P34: Reset Clears Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date range and submit | Date filter applied |
| 2 | Click Reset | Date range input cleared; hidden inputs cleared |

---

#### TC-P35: No Subject Selected Shows All Subjects

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave subject as "All Subjects" | Homeworks from all subjects in ledger |
| 2 | Verify subject column shows different subjects | Multiple subjects visible |

---

#### TC-P36: Empty Lesson Filter Shows All Lessons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class + subject, leave lesson as "All Lessons" | All lessons HWs shown |
| 2 | Verify lesson names in HW items | Multiple lessons represented |

---

#### TC-P37: Empty Topic Filter Shows All Topics

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class + subject + lesson, leave topic as "All Topics" | All topics HWs shown |
| 2 | Verify metadata | Complete data across topics |

---

#### TC-P38: Assign Date Format in Ledger

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HW with assign_date = 2026-01-15 | Date expected |
| 2 | Navigate to tracker | Assign Date shows "15-Jan-26" (d-M-y format) |

---

#### TC-P39: Due Date Format in Ledger

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HW with due_date = 2026-01-22 | Date expected |
| 2 | Navigate to tracker | Due Date shows "22-Jan-26" (d-M-y format) |

---

#### TC-P40: Submitted At Format in Modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed submission with submitted_at = 2026-01-15 14:30:00 | DateTime expected |
| 2 | Open modal | Submitted At shows "15-Jan-26 14:30" (d-M-y H:i format) |

---

#### TC-N12: Topic Filter Without Lesson

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select topic_id without lesson_id | Topic dropdown disabled when no lesson selected |
| 2 | Filter not applied | Topic filter ignored |

---

#### TC-N13: Date Range End Before Start

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date_from = Feb 1, date_to = Jan 1 | End before start |
| 2 | Query executes with inverted range | No 500 error; potentially empty results if no HWs match |

---

#### TC-N14: Single Day Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date_from = Jan 15, date_to = Jan 15 | Single day |
| 2 | Only HWs assigned on Jan 15 shown | Correct scoping |

---

#### TC-N15: All Homework Assignments Have is_active=0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HWs with is_active=0 | Deactivated |
| 2 | Navigate to tracker | No HWs shown (query doesn't filter by is_active) — actually query may still return them |
| 3 | Note: Controller doesn't filter is_active on homework query | All homeworks returned regardless of is_active |

---

#### TC-D09: Data Cross-Check — Tracker vs Performance Matrix Counts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open HW Submission Tracker | Note total assignments count |
| 2 | Open HW Performance Analysis | Total assignments count should match (same filters) |
| 3 | Compare counts | Both reports return consistent data |

---

#### TC-D10: Data Cross-Check — Late Counts Across Reports

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open HW Submission Tracker | Note late submission count per HW |
| 2 | Open HW Performance Analysis | Late indicator dots should correspond to same submissions |
| 3 | Verify consistency | Late flags consistent across both reports |

---

#### TC-CR16: Controller — generateHwSubmissionData Paginator

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 244 | LengthAwarePaginator with 15 per page |
| 2 | Verify page parameter | Uses (int) $request->get('page', 1) |
| 3 | Verify path set | ['path' => request()->url(), 'query' => request()->query()] pattern used elsewhere |

---

#### TC-CR17: View — Button/Link Permission Fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check if view has @can checks for action buttons | No per-action permission checks (single permission for whole report) |
| 2 | Verify consistency | All users with viewAny can see all data and modals |

---

## End of TC List
