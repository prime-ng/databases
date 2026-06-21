# Homework Tab 1: Homework Analytics (Dashboard)

This is the first tab the teacher sees when they open the Homework module. It provides a quick overview of everything happening with homework — summary numbers, charts, and recent activity — all in one place.

---

## How It Works

When the teacher opens this tab, they see several summary cards at the top. One card shows the total number of published homework assignments currently active. Another shows total submissions received. A third shows how many submissions are still pending grading. A fourth shows the overall submission rate as a percentage of assignments that have been submitted.

Below the summary cards, there are charts. One chart compares graded versus pending submissions as a pie or donut chart. Another shows submission trends over the last 7 days as a bar chart. A third breaks down homework count by subject, showing the top 6 subjects with the most homework assigned.

At the bottom, there is a list of the most recent 5 submissions. Each entry shows the student name, the homework title, the submission date, and its current status. The teacher can click through to view details.

The teacher can filter all dashboard data by Class, Section, Subject, and Date Range. When filters are applied, all summary cards and charts update to reflect only the filtered data.

---

## Important Business Rules

- The dashboard is read-only — no actions can be performed from this tab.
- If no homework exists, all cards show zero and charts are empty. A message appears prompting the teacher to create their first homework.
- Data is live-queried from the database. For schools with heavy usage, there may be a brief loading delay.
- The submission rate is calculated as: (Total Submissions / Total Assignments) × 100. If no assignments exist, it shows 0%.
- The subject chart shows only the top 6 subjects by homework count. Remaining subjects are grouped as "Others."
- The 7-day submission chart shows submissions created on each of the last 7 calendar days. Days with zero submissions still appear.
- The dashboard shows data only for the teacher's own school. Admins see data across all schools.

---

## Database Columns & Behavior

### lms_homework (used indirectly via aggregate queries)
- `id` — Primary key. Used for counting total homeworks.
- `class_id` — Filters to the selected class. INT FK to sch_classes.
- `section_id` — Filters to the selected section. INT FK to sch_sections. NULL means all sections.
- `subject_id` — Filters to the selected subject. INT FK to sch_subjects.
- `status_id` — Filters to PUBLISHED status only for the active homeworks count. INT FK to sys_dropdown_table.
- `is_active` — Only active (1) homeworks are counted. TINYINT(1), default 1.
- `created_at` — Used for date range filtering. TIMESTAMP.

### lms_homework_assignment (used for assignment counts)
- `id` — Primary key. Used for counting total assignments.
- `homework_id` — Links to the homework. INT FK to lms_homework.
- `class_id` — Denormalized from homework. Used for class filter.
- `section_id` — Student's actual section. Used for section filter.
- `is_released` — Counts only released assignments. TINYINT(1), default 0.
- `status_id` — Used for status-based counting. INT FK to sys_dropdown_table.

### lms_homework_submissions (used for submission counts)
- `id` — Primary key. Used for counting total submissions.
- `homework_id` — Links to homework. Used for filter joins.
- `student_id` — Links to student. INT FK to std_students.
- `submitted_at` — Used for date range filtering and 7-day trend. DATETIME.
- `marks_obtained` — NULL means pending grading. DECIMAL(5,2). When NULL, counted as pending.
- `graded_at` — When set, submission is considered graded. DATETIME. When NULL, counted as pending grading.
- `is_active` — Only active submissions are counted. TINYINT(1), default 1.
- `created_at` — Used for the 7-day trend chart. TIMESTAMP.

---

## Deep Analysis

### Business Workflows & State Machines

The dashboard is a read-only aggregation view. There is no state machine for the dashboard itself — it is a reporting layer that queries live data from the homework lifecycle tables. The only relevant "workflow" is the filter-refresh cycle: teacher selects filter criteria → system runs aggregate queries → cards and charts re-render. Filters (Class, Section, Subject, Date Range) are independent and combinatorial.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Empty state (no homework) | All cards show 0, charts are empty | "No homework assignments found. Create your first homework to get started." |
| Submission rate calculation | (Total Submissions / Total Assignments) × 100. If no assignments → 0% | N/A — computed value |
| 7-day trend chart | Shows last 7 calendar days. Days with 0 submissions still appear as 0 | N/A — days are always rendered |
| Top-6 subjects chart | Top 6 by homework count; remaining grouped as "Others" | N/A — automatic grouping |
| Date range filter | applied to `created_at` on submissions and homeworks | N/A — UI date picker |
| Multi-school admin | Admins see data across all schools; teachers scoped to own school | N/A — row-level scoping |
| Loading state | Brief delay for heavy schools; no data shown until query completes | Loading spinner |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| School Management | `sch_classes` | `lms_homework.class_id` | Class filter for dashboard aggregation |
| School Management | `sch_sections` | `lms_homework.section_id` | Section filter for dashboard aggregation |
| School Management | `sch_subjects` | `lms_homework.subject_id` | Subject filter + top-6 subject chart |
| Student Management | `std_students` | `lms_homework_submissions.student_id` | Submission count by student |
| Common/Dropdown | `sys_dropdown_table` | `lms_homework.status_id` | Filter to PUBLISHED status only |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View dashboard | Teacher | `lms.homework.analytics.view` |
| View dashboard (all schools) | Admin | `lms.homework.analytics.view_all` |
| Apply filters | Teacher | `lms.homework.analytics.filter` |
