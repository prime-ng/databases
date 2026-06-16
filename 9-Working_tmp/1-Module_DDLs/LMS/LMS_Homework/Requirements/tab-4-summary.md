# Homework Tab 4: Summary

This tab shows aggregated homework results at a glance. It gives the teacher a bird's-eye view of how students are progressing across all homework assignments — who has submitted, who has been graded, who needs a resubmission, and who has not yet attempted the homework.

---

## How It Works

When the teacher opens this tab, they see a table that lists each homework with summary counts. For each homework, the table shows the topic, homework title, release date, due date, and four key counts:

**Assigned Students** — Total number of students who have been assigned this homework. This is the total number of assignment records created for this homework.

**Submitted Students** — Number of students who have actually submitted their homework. A submission is counted when the lms_homework_submissions table has a record with a non-null submitted_at for that assignment.

**Checked Students** — Number of students whose submission has been graded. A submission is counted as checked when graded_at is not null in the submissions table.

**Reassigned Students** — Number of students whose submission has been flagged for resubmission. This is counted when is_resubmission_requested is true on the submission.

The teacher can filter by Class, Section, Subject, and Date Range. They can also search by homework title or topic name.

Clicking on a homework row takes the teacher to the detailed view of that homework. The paper check icon takes them to the Paper Check evaluator.

---

## Important Business Rules

- All counts are derived from the lms_homework_assignment and lms_homework_submissions tables, not from the homework table directly.
- The assigned count counts all active assignment records for that homework, regardless of release status.
- The submitted count counts assignments that have at least one submission with a non-null submitted_at.
- The checked count counts assignments whose submission has a non-null graded_at.
- The reassigned count counts assignments whose submission has is_resubmission_requested = true.
- If no data matches the filters, the table is empty with a "No homework found" message.
- The summary is read-only. No actions can be performed from this tab.
- The teacher can navigate to the Paper Check evaluator or the full assignment detail view from this tab.

---

## Database Columns & Behavior

### lms_homework (display columns)
- `id` — Primary key. Used for grouping and joins.
- `title` — Homework title. VARCHAR(255), NOT NULL. Displayed in the table.
- `topic_id` — Links to topic for topic name display. INT UNSIGNED, FK to slb_topics.
- `class_id` — For class filter and display. INT UNSIGNED, FK to sch_classes.
- `section_id` — For section filter and display. INT UNSIGNED, FK to sch_sections.
- `subject_id` — For subject filter and display. INT UNSIGNED, FK to sch_subjects.
- `assign_date` — Displayed as release date. DATETIME, NOT NULL.
- `due_date` — Displayed as due date. DATETIME, NOT NULL.
- `is_active` — Only active homeworks are shown. TINYINT(1), default 1.

### lms_homework_assignment (count queries)
- `homework_id` — Grouped by this for counts. INT UNSIGNED, FK to lms_homework.
- `id` — Counted for total assigned students. INT UNSIGNED.
- `is_active` — Only counts active assignments. TINYINT(1), default 1.

### lms_homework_submissions (count queries)
- `assignment_id` — Linked to assignment for joins. INT UNSIGNED, FK to lms_homework_assignment.
- `submitted_at` — If NOT NULL, submission is counted as "submitted." DATETIME.
- `graded_at` — If NOT NULL, submission is counted as "checked." DATETIME.
- `is_resubmission_requested` — If true (1), counted as "reassigned." TINYINT(1), default 0.
- `homework_id` — For joining back to homework. INT UNSIGNED, FK to lms_homework.

---

## Deep Analysis

### Business Workflows & State Machines

The Summary tab is a read-only aggregation view. There is no user-initiated state machine — all four counts (Assigned, Submitted, Checked, Reassigned) are derived from the underlying `lms_homework_assignment` and `lms_homework_submissions` tables. Data refreshes on page load or filter change. The only workflow is the navigation click-through to the Paper Check evaluator or the full homework detail view.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Assigned count | Counts all active assignment records regardless of release status | N/A — computed value |
| Submitted count | Counts assignments with at least one submission having non-null `submitted_at` | N/A — computed value |
| Checked count | Counts assignments whose submission has non-null `graded_at` | N/A — computed value |
| Reassigned count | Counts assignments where submission has `is_resubmission_requested = 1` | N/A — computed value |
| Empty dataset after filter | Table shows "No homework found" | "No homework found." |
| Homework with 0 assigned students | Shows 0 across all columns | N/A — row still displays |
| Resubmission counted multiple times | A single submission can be reassigned multiple times; count shows current state only (latest `is_resubmission_requested` value) | N/A — snapshotted |
| Class/Section/Subject filter mismatch | Combined filters may yield zero results | "No homework found." |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Homework Core | `lms_homework` | `lms_homework_submissions.homework_id` | Join to homework display columns |
| Assignment Tracking | `lms_homework_assignment` | `lms_homework_assignment.homework_id` | Assigned student count |
| Submission Management | `lms_homework_submissions` | `lms_homework_submissions.assignment_id` | Submitted/Checked/Reassigned counts |
| School Management | `sch_classes`, `sch_sections`, `sch_subjects` | `lms_homework.{class_id,section_id,subject_id}` | Filter criteria |
| Syllabus | `slb_topics` | `lms_homework.topic_id` | Topic name display |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View summary table | Teacher | `lms.homework.summary.view` |
| View summary (cross-class) | Admin | `lms.homework.summary.view_all` |
| Navigate to Paper Check | Teacher | `lms.homework.paper_check.access` |
| Navigate to homework detail | Teacher | `lms.homework.detail.view` |
