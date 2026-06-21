# Homework Tab 3: Assignment Tracking

This tab lets teachers track the status of homework assignments at the individual student level. It shows every student who has been assigned a homework, their current status in the lifecycle, and allows teachers to make per-student adjustments like extending due dates, overriding late submission policies, releasing or un-releasing assignments, and sending reminders.

---

## How It Works

When the teacher opens this tab, they see a table of all homework assignment records. Each row shows the homework title, the student's name, the student's current status in the assignment lifecycle (Pending Release, Assigned, Viewed, Submitted, Late Submitted, Graded, Overdue, or Exempted), the effective due date, release condition, and action buttons.

The teacher can filter by homework, student, status, class, section, and subject. They can search by student name, admission number, or email.

The teacher can click on any row to view the full assignment details, including the student's submission and any grading.

---

## Per-Student Actions

**Change Due Date:** The teacher can extend the due date for a specific student. The new due date cannot be earlier than the existing due date. They can also reset the due date to the homework default. When changed, a notification is sent to the student.

**Change Assign Date:** The teacher can adjust the scheduled release date for a specific student. This is only allowed if the assignment has not yet been released.

**Toggle Release:** The teacher can manually release or un-release an assignment for a specific student. Releasing sets is_released = 1 with a timestamp and changes the status to ASSIGNED. Un-releasing sets it back to PENDING_RELEASE.

**Override Late Submission:** The teacher can allow late submission for a specific student even if the homework default does not allow it, or deny it even if the homework allows it. A reason must be provided for the override.

**Send Reminder:** The teacher can send a reminder notification to a student who has not yet submitted. The reminder_sent_at timestamp is updated.

**Grade Directly:** If the student has submitted, the teacher can grade directly from the assignment detail view by entering marks and feedback.

---

## Assignment Lifecycle Statuses

Each assignment goes through a defined lifecycle. PENDING_RELEASE means the assignment record exists but is not yet visible to the student. ASSIGNED means it has been released and is visible. VIEWED means the student has opened it. SUBMITTED means the student submitted on time. LATE_SUBMITTED means the student submitted after the due date. GRADED means the teacher has evaluated the submission. OVERDUE means the due date has passed with no submission. EXEMPTED means the student is excused from this homework.

A scheduled job runs nightly to automatically mark overdue assignments.

---

## Important Business Rules

- A student cannot have duplicate assignments for the same homework. The combination of homework_id and student_id is unique.
- The effective due date for an assignment is: the assignment's due_date if set, otherwise the homework's due_date.
- The effective late submission policy is: the assignment's allow_late_submission if set (0 or 1), otherwise the homework's allow_late_submission.
- The due date can only be extended forward. A new due date cannot be earlier than the existing due date.
- The assign date cannot be changed after the assignment has been released.
- Toggling release sends a notification to the student on release.
- Sending a reminder creates a notification record and updates reminder_sent_at.
- Overdue status is set by a nightly scheduled job, not in real time.
- Assignment status transitions are one-directional. Once GRADED or OVERDUE, the status cannot go back without manual override.
- The assignment record is soft-deleted when the homework is deleted. Force-deleting the homework force-deletes all assignments.

---

## Database Columns & Behavior

### lms_homework_assignment
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `homework_id` — Links to the homework. INT UNSIGNED, FK to lms_homework. CASCADE on delete.
- `student_id` — The student this assignment is for. INT UNSIGNED, FK to std_students. CASCADE on delete.
- `academic_session_id` — Denormalized from homework. INT UNSIGNED, FK to sch_org_academic_sessions_jnt. RESTRICT on delete.
- `class_id` — Denormalized from homework. INT UNSIGNED, FK to sch_classes. RESTRICT on delete.
- `section_id` — Student's actual section (may differ from homework's section_id). INT UNSIGNED, FK to sch_sections. SET NULL on delete.
- `subject_id` — Denormalized from homework. INT UNSIGNED, FK to sch_subjects. RESTRICT on delete.
- `release_condition` — Per-student override of release condition. ENUM('IMMEDIATE', 'ON_TOPIC_COMPLETE', 'ON_SCHEDULED_DATE'), default 'ON_TOPIC_COMPLETE'. NULL = inherit from homework.
- `release_scheduled_date` — Per-student scheduled release date. DATETIME, DEFAULT NULL. NULL = inherit from homework.
- `is_released` — Whether this assignment is visible to the student. TINYINT(1), default 0. 0 = hidden, 1 = visible.
- `released_at` — When the assignment was released. DATETIME, DEFAULT NULL. Set when is_released changes from 0 to 1.
- `due_date` — Per-student due date override. DATETIME, DEFAULT NULL. NULL = use homework.due_date.
- `allow_late_submission` — Per-student late submission policy override. TINYINT(1), DEFAULT NULL. NULL = inherit from homework. 0 = deny. 1 = allow.
- `late_submission_override_reason` — Teacher's reason for the override. VARCHAR(500), DEFAULT NULL.
- `late_submission_override_by` — Teacher who made the override. INT UNSIGNED, FK to sys_users. SET NULL on delete.
- `late_submission_override_at` — When the override was made. DATETIME, DEFAULT NULL.
- `viewed_at` — When the student first opened the homework. DATETIME, DEFAULT NULL.
- `view_count` — How many times the student has viewed the homework. SMALLINT UNSIGNED, default 0.
- `student_notified_at` — When the "new homework" notification was sent to student. DATETIME, DEFAULT NULL.
- `parent_notified_at` — When the "new homework" notification was sent to parents. DATETIME, DEFAULT NULL.
- `reminder_sent_at` — When the last due-date reminder was sent. DATETIME, DEFAULT NULL.
- `status_id` — Current lifecycle status. INT UNSIGNED, FK to sys_dropdown_table. RESTRICT on delete. Values: PENDING_RELEASE, ASSIGNED, VIEWED, SUBMITTED, LATE_SUBMITTED, GRADED, OVERDUE, EXEMPTED.
- `assigned_by` — Teacher who published/assigned. INT UNSIGNED, FK to sys_users. RESTRICT on delete.
- `is_active` — Soft enable/disable. TINYINT(1), default 1.
- `created_by` — Creator. INT UNSIGNED, FK to sys_users. RESTRICT on delete.
- `updated_by` — Last modifier. INT UNSIGNED, FK to sys_users. SET NULL on delete.
- `created_at` — Creation timestamp. TIMESTAMP, NULLABLE.
- `updated_at` — Last update timestamp. TIMESTAMP, NULLABLE.
- `deleted_at` — Soft delete timestamp. TIMESTAMP, NULLABLE.

### Unique Constraint
- `uq_hwa_homework_student` — UNIQUE on (homework_id, student_id). Ensures one assignment per student per homework.

---

## Deep Analysis

### Business Workflows & State Machines

The assignment lifecycle is the core state machine of the Homework module. Each student's assignment transitions through these states:

| Current State | Allowed Next States | Trigger | Notes |
|---|---|---|---|
| PENDING_RELEASE | ASSIGNED | Release condition met (IMMEDIATE on publish / topic completed / scheduled date) | is_released set to 1 |
| ASSIGNED | VIEWED | Student opens the homework | viewed_at set, view_count incremented |
| ASSIGNED | OVERDUE | Nightly cron job detects past due_date | Only if no submission exists |
| VIEWED | SUBMITTED | Student submits on time | Delegates to submission table |
| VIEWED | OVERDUE | Nightly cron job | No submission before due_date |
| VIEWED | LATE_SUBMITTED | Student submits after due_date | Only if late submission allowed |
| SUBMITTED | GRADED | Teacher grades | Delegates to submission grading |
| LATE_SUBMITTED | GRADED | Teacher grades | Same as above |
| SUBMITTED | OVERDUE | Not allowed — submission exists | N/A |
| GRADED | (terminal) | N/A | Can be rechecked (goes back to SUBMITTED) |
| OVERDUE | (terminal) | N/A | Teacher can manually override |
| EXEMPTED | (terminal) | Teacher marks exempt | Skipped from all processing |

Per-student overrides (due_date extension, late_submission toggle, manual release) are independent of the state machine but influence transition conditions.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Change due_date | Cannot be earlier than existing due_date | "New due date must be after the current due date." |
| Change due_date | Can be set to NULL (reset to homework default) | N/A — allowed |
| Change assign_date | Only allowed if assignment not yet released | "Cannot change assign date after assignment has been released." |
| Toggle release | Flips is_released + sets released_at | N/A — silent update |
| Toggle release (un-release) | Only if status is PENDING_RELEASE or ASSIGNED | "Cannot un-release a submission that has already been viewed or submitted." |
| Override late submission | Reason required (max 500 chars) | "A reason is required for late submission override." |
| Override late submission | Override_by, override_at set automatically | N/A |
| Send reminder | Only if not yet submitted | "This student has already submitted." |
| Send reminder | Updates reminder_sent_at; prevents duplicate within 24h (app-level) | "A reminder was already sent recently." |
| Bulk publish — duplicate | UNIQUE(homework_id, student_id) enforced | "This student already has an assignment for this homework." |
| Overdue marking (cron) | Skips SUBMITTED, LATE_SUBMITTED, GRADED, EXEMPTED | N/A — cron internal |
| Overdue marking (cron) | Uses COALESCE(assignment.due_date, homework.due_date) | N/A — computed |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Homework Core | `lms_homework` | `lms_homework_assignment.homework_id` (CASCADE) | Parent homework definition |
| Student Management | `std_students` | `lms_homework_assignment.student_id` (CASCADE) | Target student |
| School Management | `sch_classes`, `sch_sections`, `sch_subjects` | `lms_homework_assignment.{class_id,section_id,subject_id}` | Denormalized for query perf |
| Organization | `sch_org_academic_sessions_jnt` | `lms_homework_assignment.academic_session_id` | Session scoping |
| Users | `sys_users` | `lms_homework_assignment.{assigned_by,created_by,updated_by,late_submission_override_by}` | Audit trail |
| Common/Dropdown | `sys_dropdown_table` | `lms_homework_assignment.status_id` | Lifecycle status dropdown |
| Notifications | `notifications` | (event-based) | Sent on release, due change, reminder |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View assignment list | Teacher | `lms.homework.assignment.view` |
| Change due date | Teacher | `lms.homework.assignment.due_date.change` |
| Change assign date | Teacher | `lms.homework.assignment.assign_date.change` |
| Toggle release | Teacher | `lms.homework.assignment.release.toggle` |
| Override late submission | Teacher | `lms.homework.assignment.late_submission.override` |
| Send reminder | Teacher | `lms.homework.assignment.reminder.send` |
| Grade directly | Teacher | `lms.homework.assignment.grade` |
| Exempt student | Teacher, Admin | `lms.homework.assignment.exempt` |
| View all assignments | Admin | `lms.homework.assignment.view_all` |
