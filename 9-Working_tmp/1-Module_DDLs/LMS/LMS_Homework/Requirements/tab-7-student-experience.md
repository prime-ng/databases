# Homework Tab 7: Student Homework Experience (Student Portal)

This describes what students see and do when they access homework through the Student Portal. Teachers do not see these screens directly, but understanding the student experience is important for knowing how homework functions on the student side.

---

## Viewing Homework Assignments

When a student logs into their account and goes to "My Homework," they see a list of all homework assignments that have been allocated to them. Each assignment shows the homework title, subject, due date, and its current status. The list is organized into categories: Pending (visible but not yet started), Overdue (past due date, not submitted), Submitted (turned in), and Graded (evaluated by teacher). Counts are shown for each category.

A homework appears in the student's list only if three conditions are met. First, the teacher must have published the homework. Second, there must be an assignment record for this student. Third, the assignment must have is_released = 1. If any condition is missing, the homework is invisible to the student.

---

## Viewing Homework Details

When the student clicks on a homework, they see the full details. The homework title, description, subject, teacher's instructions, and any attached files are displayed. The due date is shown prominently, along with whether late submission is allowed.

If the homework has not been started, there is a "Start Homework" or "Submit Homework" button. If it has already been submitted, the button shows "View Submission" instead.

The student can see their assignment status at the top — whether it is Pending, Overdue, Submitted, or Graded.

---

## Submitting Homework

The submission interface adapts based on the homework's submission type. For TEXT type, a text editor is shown where the student types their response. For FILE type, a file upload area is shown where they can drag and drop or browse for files. For HYBRID type, both the text editor and file upload are shown. For OFFLINE_CHECK type, a message says "This homework will be submitted physically in class" and no submission form is shown.

Multiple files can be uploaded. Each file shows a preview (for images and PDFs) and a remove button. The student can add or remove files before submitting.

When the student clicks "Submit," a confirmation dialog appears: "You are about to submit your homework. You may not be able to edit it after submission." On confirmation, the submission is saved and the student is redirected to their homework list.

---

## Viewing Results

After the teacher grades the homework, the student can see their marks, the teacher's written feedback, and any annotated PDFs. The result card shows the marks obtained out of maximum marks, a pass or fail indicator (based on passing marks), and the teacher's comments.

If the teacher has requested a resubmission, the student sees a "Resubmit" button and a message explaining what needs to be improved. The student can revise and resubmit. Each resubmission cycle is tracked.

---

## Important Business Rules

- A homework assignment appears only if the homework is published, the student has a released assignment record, and is_released = 1.
- Late submissions are allowed only if the effective policy (homework default or assignment override) allows them. If not allowed, the submit button is disabled after the due date.
- Once submitted, the student cannot edit the submission unless the teacher requests a resubmission.
- On resubmission, the student can update their text and replace or add files. Previous files are removed.
- The student can view their submission and the teacher's feedback at any time after submission.
- If auto_publish_score is disabled, the student sees "Your homework has been graded. Results will be visible soon." until the teacher manually publishes the score.
- Notifications are sent to the student when a new homework is assigned, when the due date changes, and when the homework is graded.
- The student's parent also receives notifications (if configured in the system).

---

## Database Columns & Behavior

### lms_homework_assignment (student's record)
- `id` — Links to the student's assignment. INT UNSIGNED.
- `homework_id` — Links to homework details. INT UNSIGNED.
- `student_id` — Must match the logged-in student. INT UNSIGNED.
- `is_released` — Controls visibility. TINYINT(1). Only released (1) assignments appear.
- `status_id` — Displayed as current status. INT UNSIGNED. Values: ASSIGNED, VIEWED, SUBMITTED, LATE_SUBMITTED, GRADED, OVERDUE, EXEMPTED.
- `due_date` — Effective due date (assignment override or homework default). DATETIME.
- `allow_late_submission` — Effective late policy. TINYINT(1), DEFAULT NULL. NULL = inherit from homework.
- `viewed_at` — Set when student first opens the homework. DATETIME.
- `view_count` — Incremented each time student opens the homework. SMALLINT UNSIGNED.
- `student_notified_at` — When notification was sent. DATETIME.

### lms_homework_submissions (student's submission)
- `id` — Links to submission record. INT UNSIGNED.
- `assignment_id` — Unique per assignment. INT UNSIGNED.
- `submission_text` — Student's response. LONGTEXT. Editable on resubmission.
- `sub_attachment_media_id` — Student's uploaded files. JSON. Replaced on resubmission.
- `submitted_at` — When submitted. DATETIME. Updated on resubmission.
- `is_late` — Whether late. TINYINT(1).
- `resubmission_count` — How many times resubmitted. TINYINT UNSIGNED.
- `marks_obtained` — Visible only if published. DECIMAL(5,2).
- `teacher_feedback` — Teacher's comments. TEXT.
- `status_id` — Current submission status. INT UNSIGNED.
- `score_published_at` — When score became visible. DATETIME. If NULL, score is hidden.

### lms_homework (read-only display)
- `title` — Homework title. VARCHAR(255).
- `description` — Full description. LONGTEXT.
- `submission_type_id` — Controls UI (TEXT/FILE/HYBRID/OFFLINE_CHECK). INT UNSIGNED.
- `max_marks` — For display. DECIMAL(5,2).
- `passing_marks` — For pass/fail calculation. DECIMAL(5,2).
- `is_gradable` — Controls whether marks are shown at all. TINYINT(1).
- `auto_publish_score` — Controls automatic score visibility. TINYINT(1).
- `allow_late_submission` — Default late policy. TINYINT(1).
- `hw_attachment_media_id` — Teacher's attached files. JSON.

---

## Deep Analysis

### Business Workflows & State Machines

The student-facing homework lifecycle involves these transitions:

| Current Assignment State | Student Action | Resulting State | Side Effects |
|---|---|---|---|
| PENDING_RELEASE | (invisible — nothing to do) | — | No UI shown |
| ASSIGNED | Open homework | VIEWED | `viewed_at` set, `view_count` incremented |
| VIEWED | Click "Start Homework" | VIEWED | Prepares submission UI |
| VIEWED / ASSIGNED | Submit on time | SUBMITTED | `lms_homework_submissions` row created. Assignment status → SUBMITTED. |
| VIEWED / ASSIGNED | Submit late (if allowed) | LATE_SUBMITTED | `is_late = 1`. Same row creation. |
| ASSIGNED / VIEWED | Do nothing past due_date | OVERDUE | Set by nightly cron. Submit button disabled if late not allowed. |
| SUBMITTED / LATE_SUBMITTED | Teacher grades | GRADED | Student sees marks/feedback |
| SUBMITTED / LATE_SUBMITTED | Teacher requests resubmit | RESUBMIT_REQUESTED | Student sees "Resubmit" button |
| RESUBMIT_REQUESTED | Resubmit | SUBMITTED | `resubmission_count++`, `submitted_at` updated, `is_late` recalculated |
| GRADED | View result | GRADED | Read-only view of marks and feedback |

The student cannot initiate state changes beyond submission and viewing. All grading transitions are teacher-driven.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Visibility | Must have: homework PUBLISHED + assignment record exists + `is_released = 1` | N/A — invisible if conditions not met |
| Submit — TEXT type | Text editor must have content (if required) | "Please enter your response before submitting." |
| Submit — FILE type | At least one file must be uploaded | "Please upload at least one file." |
| Submit — HYBRID type | Either text or file (or both) required | "Please provide a response or upload a file." |
| Submit — OFFLINE_CHECK type | No submission form shown | N/A — informational message displayed |
| Submit — late (not allowed) | Submit button disabled after due_date | "Late submissions are not allowed for this homework." |
| Submit — after already submitted | Button shows "View Submission" instead | N/A — read-only view |
| Resubmit — replaces files | Previous files removed | "Your previous files will be replaced." |
| Submit — confirmation dialog | Must confirm before submission | "You are about to submit your homework. You may not be able to edit it after submission." |
| View score — not published | `score_published_at` is NULL | "Your homework has been graded. Results will be visible soon." |
| View score — published | Score shown with pass/fail indicator | N/A |
| Resubmit without teacher request | Not possible — button appears only when `is_resubmission_requested = 1` | N/A |
| Overdue cron mark | Happens nightly; student may briefly see ASSIGNED after due_date | N/A — eventual consistency |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Assignment Tracking | `lms_homework_assignment` | `student_id` = logged-in student | Student's assignment list and state |
| Submission Management | `lms_homework_submissions` | `assignment_id` (via assignment) | Student's submission content |
| Homework Core | `lms_homework` | `lms_homework_assignment.homework_id` | Homework details and settings |
| Student Management | `std_students` | (user-to-student mapping) | Resolves logged-in user to student record |
| Users | `sys_users` | (user ID) | Authentication + notification delivery |
| Notifications | `notifications` | (event-based) | New homework, due change, grade notification |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View homework list (own) | Student | `lms.homework.student.list` |
| View homework detail | Student | `lms.homework.student.detail` |
| Submit homework | Student | `lms.homework.student.submit` |
| Resubmit homework | Student | `lms.homework.student.resubmit` |
| View own grades/feedback | Student | `lms.homework.student.grade.view` |
| View own submission | Student | `lms.homework.student.submission.view` |
