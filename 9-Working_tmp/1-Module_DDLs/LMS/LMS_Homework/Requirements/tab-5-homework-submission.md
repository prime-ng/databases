# Homework Tab 5: Homework Submission Management

This tab manages all student submissions. Teachers can view, filter, grade, and manage submissions from this centralized interface. It is the operational hub for handling student homework submissions once they have been turned in.

---

## How It Works

When the teacher opens this tab, they see a table of all submissions. Each row shows the homework title, the student's name, the submission text preview, the status (Submitted, Under Review, Graded, Rejected, Resubmit Requested), whether it was submitted late, the marks obtained, and action buttons.

The teacher can filter by homework, student, status, late submission flag, and active/inactive. They can also search by submission text, teacher feedback, student name, or homework title.

From the action buttons, the teacher can view the full submission details, edit the submission, grade it, request a resubmission, or delete it.

---

## Submission and Review Workflow

When a student submits, the submission is created with status SUBMITTED. If the submission was made after the due date, is_late is set to 1 and the status becomes LATE_SUBMITTED.

The teacher reviews the submission by opening it. They can update the status to UNDER_REVIEW while they examine it. They then assign marks, provide written feedback, and finalize the grade. If auto_publish_score is enabled on the homework, the score is immediately visible to the student. Otherwise, the teacher must manually publish it.

If the teacher finds the submission inadequate, they can request a resubmission. This sets is_resubmission_requested to true and changes the status to RESUBMIT_REQUESTED. The student can then revise and resubmit. Each resubmission increments the resubmission_count.

The teacher can reject a submission entirely if the content is invalid or empty. This sets the status to REJECTED.

---

## Important Business Rules

- There can only be one active submission per assignment. The assignment_id is unique in the submissions table.
- If a resubmission is requested, the existing submission record is updated — a new record is not created. The resubmission_count is incremented.
- The is_late flag is recalculated on each resubmission based on the current time vs the effective due date.
- Once a submission is graded (graded_at is set), the is_late flag is no longer recalculated. It stays as whatever it was at the time of grading.
- Grading triggers a notification to the student if auto_publish_score is enabled.
- The teacher can always change a grade later by editing the submission.
- Bulk download of all submission files for a homework is available as a ZIP file.
- Soft-deleted submissions can be restored. Force-deleted submissions are permanently removed.
- The submission status also updates the parent assignment's status. When a submission is graded, the assignment status is also set to GRADED.
- Score publishing can happen automatically (on grading if auto_publish_score = 1) or manually later.

---

## Database Columns & Behavior

### lms_homework_submissions
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `assignment_id` — Links to the assignment. INT UNSIGNED, FK to lms_homework_assignment. CASCADE on delete. UNIQUE — one submission per assignment.
- `homework_id` — Denormalized from assignment for query performance. INT UNSIGNED, FK to lms_homework. CASCADE on delete.
- `student_id` — Denormalized from assignment. INT UNSIGNED, FK to std_students. CASCADE on delete.
- `submission_text` — Student's typed response. LONGTEXT, DEFAULT NULL. For TEXT and HYBRID submission types.
- `sub_attachment_media_id` — JSON array of uploaded file metadata. JSON, DEFAULT NULL. Stores array of objects: { "media_id": INT, "file_name": STRING, "file_path": STRING, "file_size": INT, "mime_type": STRING, "uploaded_at": DATETIME, "type": "student"|"teacher_feedback", "source_file_path": STRING }.
- `submitted_at` — When the student submitted. DATETIME, NOT NULL. Updated on resubmission.
- `is_late` — Whether submitted after due date. TINYINT(1), default 0. Recalculated on resubmission. Frozen after grading.
- `resubmission_count` — Number of resubmissions. TINYINT UNSIGNED, default 0. 0 = first submission. Incremented on each resubmit.
- `status_id` — Submission status. INT UNSIGNED, FK to sys_dropdown_table. RESTRICT on delete. Values: SUBMITTED, UNDER_REVIEW, GRADED, REJECTED, RESUBMIT_REQUESTED.
- `is_resubmission_requested` — Whether teacher has asked for a redo. TINYINT(1), default 0. Set when teacher clicks "Request Resubmission." Reset on resubmission.
- `marks_obtained` — Score awarded by teacher. DECIMAL(5,2), DEFAULT NULL. NULL until graded.
- `teacher_feedback` — Written feedback from teacher. TEXT, DEFAULT NULL.
- `graded_by` — Teacher who graded. INT UNSIGNED, FK to sys_users. SET NULL on delete.
- `graded_at` — When grading was completed. DATETIME, DEFAULT NULL.
- `score_published_at` — When score was made visible to student. DATETIME, DEFAULT NULL. Set automatically if auto_publish_score = 1, or manually later.
- `is_active` — Soft enable/disable. TINYINT(1), default 1.
- `created_by` — Student's user ID who submitted. INT UNSIGNED, FK to sys_users. SET NULL on delete.
- `updated_by` — Teacher's user ID who graded. INT UNSIGNED, FK to sys_users. SET NULL on delete.
- `created_at` — Creation timestamp. TIMESTAMP, NULLABLE.
- `updated_at` — Last update timestamp. TIMESTAMP, NULLABLE.
- `deleted_at` — Soft delete timestamp. TIMESTAMP, NULLABLE.

### Unique Constraints
- `uq_hws_assignment` — UNIQUE on (assignment_id). Ensures one active submission per assignment.

---

## Deep Analysis

### Business Workflows & State Machines

The submission lifecycle within this tab follows a teacher-driven review workflow:

| Current State | Allowed Next States | Trigger | Notes |
|---|---|---|---|
| SUBMITTED | UNDER_REVIEW | Teacher clicks "Review" | Status set manually |
| SUBMITTED | REJECTED | Teacher rejects invalid/empty content | Terminal for this cycle |
| SUBMITTED | RESUBMIT_REQUESTED | Teacher requests redo | Student must resubmit |
| UNDER_REVIEW | GRADED | Teacher finalizes grade | Marks locked, notification sent if auto_publish |
| UNDER_REVIEW | RESUBMIT_REQUESTED | Teacher requests redo during review | Clears grade fields |
| UNDER_REVIEW | REJECTED | Teacher rejects during review | Terminal |
| GRADED | (re-check) SUBMITTED | Teacher re-opens for re-evaluation | Clears grade, resets status |
| RESUBMIT_REQUESTED | SUBMITTED | Student resubmits | `resubmission_count` incremented, `is_late` recalculated |
| REJECTED | SUBMITTED | Student resubmits (if allowed) | Same as above |
| GRADED | (terminal) | Natural end state | Score may be published later |

Late detection: `is_late` is set on initial submission based on `NOW() > effective_due_date`. On resubmission, `is_late` is recalculated. After grading, `is_late` is frozen.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Grade — marks_obtained | Must be ≥ 0 and ≤ max_marks | "Marks must be between 0 and {max_marks}." |
| Grade — marks_obtained | Can be NULL (not yet graded) | N/A — pending state |
| Grade — teacher_feedback | Max length determined by TEXT column (~65KB) | "Feedback is too long." |
| Request resubmission | Clears `graded_by`, `graded_at`, `marks_obtained` | N/A — automatic |
| Request resubmission | Sets `is_resubmission_requested = 1` | N/A — automatic |
| Re-check submission | Only if status is GRADED | "Only graded submissions can be rechecked." |
| Delete submission | Soft delete; can be restored | N/A — soft delete |
| Force delete submission | Permanent removal | "This action cannot be undone." |
| Bulk download ZIP | Generated on demand; deleted after download | N/A — temporary file |
| Score publish (manual) | Requires `graded_at` to be set | "Cannot publish score before grading." |
| Score publish (auto) | Triggered immediately on grading if `auto_publish_score = 1` | N/A — automatic |
| Late flag after grading | Frozen; not recalculated on subsequent edits | N/A — design invariant |
| Single submission per assignment | UNIQUE constraint on `assignment_id` | "A submission already exists for this assignment." |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Assignment Tracking | `lms_homework_assignment` | `lms_homework_submissions.assignment_id` (CASCADE) | Parent assignment; status synced on grade |
| Homework Core | `lms_homework` | `lms_homework_submissions.homework_id` (CASCADE) | Denormalized for query performance |
| Student Management | `std_students` | `lms_homework_submissions.student_id` (CASCADE) | Denormalized student reference |
| Users | `sys_users` | `lms_homework_submissions.{graded_by,created_by,updated_by}` | Grading and audit trail |
| Common/Dropdown | `sys_dropdown_table` | `lms_homework_submissions.status_id` | Submission status values |
| Notifications | `notifications` | (event-based) | On grade, resubmit request, score publish |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View submissions list | Teacher | `lms.homework.submission.view` |
| View submission detail | Teacher | `lms.homework.submission.detail` |
| Grade submission | Teacher | `lms.homework.submission.grade` |
| Request resubmission | Teacher | `lms.homework.submission.resubmit.request` |
| Reject submission | Teacher | `lms.homework.submission.reject` |
| Re-check submission | Teacher | `lms.homework.submission.recheck` |
| Publish score manually | Teacher | `lms.homework.submission.score.publish` |
| Delete submission (soft) | Teacher | `lms.homework.submission.delete` |
| Force delete submission | Admin | `lms.homework.submission.force_delete` |
| Bulk download ZIP | Teacher | `lms.homework.submission.bulk_download` |
| View all submissions | Admin | `lms.homework.submission.view_all` |
