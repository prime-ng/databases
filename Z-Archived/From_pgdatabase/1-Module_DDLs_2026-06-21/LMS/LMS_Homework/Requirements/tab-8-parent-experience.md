# Homework Tab 8: Parent Homework View (Parent Portal)

This describes what parents see when they access homework through the Parent Portal. Parents can monitor their children's homework assignments, track submission status, view grades and feedback, and receive notifications — all without being able to submit or modify anything.

---

## Viewing Homework Assignments

When a parent logs in and goes to "Homework," they see homework for all their children associated with their account. The list is organized into tabs — Pending, Overdue, Submitted, Graded, and All. Each tab shows a count of how many assignments are in that category.

Each homework card shows the child's name, the homework title, subject, due date, and current status. The status is shown as a colored badge — red for Overdue, yellow for Pending, blue for Submitted, or green for Graded.

---

## Viewing Homework Details

When the parent clicks on a homework, they see the full details. The header shows the child's name, the homework title, the subject, and key metadata. A progress bar shows the status visually — from "Assigned" through "Submitted" to "Graded."

The parent can see the homework description and any files the teacher attached. They can see the due date and whether late submission is allowed.

If the homework has been submitted, the parent can see the submission text and files the child uploaded. If it has been graded, they can see the marks obtained, the pass or fail status, the teacher's written feedback, and any annotated PDFs.

The sidebar shows metadata — status, marks, due date, submitted date, graded date, and late submission status.

---

## Notifications

Parents receive notifications for key events. When a new homework is assigned to their child, a notification is sent. When the due date is changed, they are notified. When the homework is graded, they see the result in their notification feed.

Notification preferences can be configured in the parent's account settings. Parents can choose to receive notifications via email, SMS, or in-app (or all three).

---

## Important Business Rules

- Parents can only view homework. There is no submit, edit, or delete functionality.
- Parents see homework for all children linked to their account. Each child's homework is shown separately.
- A homework appears only if the assignment is released (is_released = 1) and the homework is published.
- Parents see the same statuses and lifecycle as students: Assigned, Viewed, Submitted, Late Submitted, Graded, Overdue.
- The parent view is read-only. No actions are available.
- If the score has not been published (score_published_at is null), marks display as "Awaiting publication" instead of the actual score.
- The parent portal uses the same underlying data as the student portal but with a different interface.
- Late submission overrides and due date extensions made by the teacher trigger parent notifications.
- Annotated PDFs uploaded by the teacher are visible to parents in the homework detail view.

---

## Database Columns & Behavior

### lms_homework_assignment (parent view)
- `id` — Loads the assignment. INT UNSIGNED.
- `student_id` — Used to show each child's assignments. INT UNSIGNED, FK to std_students.
- `homework_id` — Links to homework details. INT UNSIGNED.
- `is_released` — Controls visibility. TINYINT(1).
- `status_id` — Displayed as status badge. INT UNSIGNED.
- `due_date` — For display and overdue calculation. DATETIME.
- `viewed_at` — For information only. DATETIME.
- `parent_notified_at` — Tracks when parent was notified. DATETIME.
- `reminder_sent_at` — When last reminder was sent. DATETIME.

### lms_homework_submissions (for viewing results)
- `marks_obtained` — Shown only if published. DECIMAL(5,2).
- `teacher_feedback` — Displayed as feedback text. TEXT.
- `submission_text` — Displayed as child's response. LONGTEXT.
- `sub_attachment_media_id` — Displayed as downloadable files. JSON.
- `submitted_at` — Displayed as submission date. DATETIME.
- `is_late` — Displayed as late badge. TINYINT(1).
- `graded_at` — Displayed as grading date. DATETIME.
- `score_published_at` — Controls marks visibility. DATETIME.
- `status_id` — Displayed. INT UNSIGNED.

### lms_homework (read-only display)
- `title` — Homework title. VARCHAR(255).
- `description` — Full description. LONGTEXT.
- `submission_type_id` — For information. INT UNSIGNED.
- `max_marks` — Shown as maximum possible score. DECIMAL(5,2).
- `passing_marks` — For pass/fail calculation. DECIMAL(5,2).
- `is_gradable` — Controls whether marks section is shown. TINYINT(1).
- `auto_publish_score` — For information. TINYINT(1).
- `due_date` — Default due date. DATETIME.
- `hw_attachment_media_id` — Teacher's attached files. JSON.

---

## Deep Analysis

### Business Workflows & State Machines

The parent portal is entirely read-only — there is no state machine for parents. All state displayed to parents mirrors the student's assignment lifecycle:

- **Pending** (ASSIGNED, VIEWED — not yet submitted)
- **Overdue** (OVERDUE — past due date, no submission)
- **Submitted** (SUBMITTED, LATE_SUBMITTED — awaiting grading)
- **Graded** (GRADED — teacher has evaluated)

Parents see a progress bar that visually maps: `Assigned → Viewed → Submitted → Graded`. Each step is highlighted as the assignment progresses. Parents cannot influence or transition any state.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Cross-child visibility | Parent sees all children linked to their account | N/A — all children shown |
| Assignment visibility | Same as student: homework PUBLISHED + assignment exists + `is_released = 1` | N/A — filtered at query level |
| Score display | Hidden if `score_published_at` is NULL | "Awaiting publication" |
| Status badge colors | Overdue=Red, Pending=Yellow, Submitted=Blue, Graded=Green | N/A — UI convention |
| Notification — new homework | Sent if `parent_notified_at` is NULL and release event fires | N/A |
| Notification — due date change | Sent on teacher-initiated due date update | N/A |
| Notification — graded | Sent when `graded_at` is set and auto_publish or manual publish occurs | N/A |
| Notification delivery | Email, SMS, or in-app per parent's account settings | N/A |
| Annotated PDF visibility | Same file as student sees; type "teacher_feedback" in JSON | N/A |
| Late submission badge | `is_late` flag shown as a badge in submission details | N/A |
| No children linked | Empty state with appropriate message | "No children linked to your account." |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Assignment Tracking | `lms_homework_assignment` | `student_id` → child's ID | Parent views child's assignment status |
| Submission Management | `lms_homework_submissions` | `assignment_id` | View child's submission + teacher's feedback |
| Homework Core | `lms_homework` | `lms_homework_assignment.homework_id` | Homework details display |
| Parent-Student Mapping | `sys_users` (parent) → `std_students` (children) | (application-level mapping) | Resolves which children belong to which parent |
| Notifications | `notifications`, `notification_targets` | (event-based) | Alerts for new homework, due changes, grading |
| Media | `sys_media` | (referenced in JSON) | Teacher attachments and annotated PDFs |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View child's homework list | Parent | `lms.homework.parent.list` |
| View child's homework detail | Parent | `lms.homework.parent.detail` |
| View child's submission | Parent | `lms.homework.parent.submission.view` |
| View child's grades | Parent | `lms.homework.parent.grade.view` |
| Configure notification preferences | Parent | `lms.homework.parent.notification.configure` |
