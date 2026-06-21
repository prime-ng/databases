# Homework Tab 6: Paper Check (Evaluator)

This is a dedicated evaluation interface for manually grading homework submissions. It provides an interactive PDF annotation tool, scoring controls, and resubmission management — all in a single screen designed for efficient grading.

---

## How It Works

The teacher first selects a homework. They see a list of all assignment records for that homework, showing each student's name, their submission status, marks obtained (if graded), and whether resubmission has been requested.

Clicking on a student opens the evaluator interface. The screen is split into sections:

**Student Info Header:** Shows the student's name, submission date, whether it was late, resubmission count, and current status.

**Submission Files:** The student's uploaded files are displayed. PDF files open in a built-in viewer with annotation tools. Images are shown directly. The teacher can download files or view them full-screen.

**Scoring Panel:** The teacher enters marks (if the homework is gradable). They can type written feedback. They can upload an annotated PDF — a marked-up version of the student's submission with corrections and comments drawn directly on it.

**Actions:** The teacher can save a draft of their evaluation (submission is kept in UNDER_REVIEW), finalize the grade (marks are locked and student is notified), or request a resubmission (student can redo and resubmit).

---

## Annotation Tools

The PDF viewer includes annotation capabilities when the teacher needs to mark up a student's submission. Tools include freehand drawing (pen), text highlighting, shape drawing (rectangle, circle, line), text insertion, and stamps (like checkmarks, crosses, and star ratings). Annotations are rendered on a canvas overlay on top of the PDF.

Annotations are saved locally in the browser's localStorage to prevent data loss. When the teacher finalizes, the annotated PDF can be uploaded back to the server as a flattened PDF/image that includes all annotations.

This is especially useful for subjects like Mathematics where the teacher needs to mark steps, or for languages where the teacher needs to highlight errors in the text.

---

## Important Business Rules

- Marks can only be entered if the homework is gradable (is_gradable = 1). Otherwise, the marks field is hidden.
- Partial marks are allowed — any value from 0 up to the homework's max_marks.
- The teacher can save a draft multiple times before finalizing. Each save updates the record but does not lock it.
- Finalizing the grade sets graded_by, graded_at, and updates the submission status to GRADED. The assignment status is also updated to GRADED.
- If auto_publish_score is enabled, the score_published_at is set on finalize. Otherwise, it remains null until the teacher manually publishes.
- Requesting a resubmission resets the submission status to SUBMITTED, clears the graded_by and graded_at, sets is_resubmission_requested = true, and increments resubmission_count.
- Rechecking (re-opening a graded submission for re-evaluation) clears the grade and sets the status back to SUBMITTED.
- The annotated PDF replaces the original student file in the attachment list when saved. Old annotations for the same file are cleaned up.
- All evaluation actions are logged in the activity log for audit purposes.
- Annotations in localStorage persist across page refreshes but are lost if the browser cache is cleared.

---

## Database Columns & Behavior

### lms_homework_submissions (used extensively in this tab)
- `id` — Used to load the submission. INT UNSIGNED.
- `assignment_id` — Links to assignment for status sync. INT UNSIGNED, UNIQUE.
- `submission_text` — Displayed for text submissions. LONGTEXT.
- `sub_attachment_media_id` — JSON array of file metadata. Stores both student files (type: "student") and teacher annotated files (type: "teacher_feedback"). Each entry: { file_name, file_path, file_size, mime_type, uploaded_at, type, source_file_path }.
- `submitted_at` — Displayed as submission date. DATETIME.
- `is_late` — Displayed as late badge. TINYINT(1).
- `resubmission_count` — Displayed. Incremented on resubmit requests.
- `marks_obtained` — The grade being entered/edited. DECIMAL(5,2), DEFAULT NULL.
- `teacher_feedback` — Written feedback. TEXT, DEFAULT NULL.
- `status_id` — Updated on save/finalize/resubmit. INT UNSIGNED, FK to sys_dropdown_table.
- `is_resubmission_requested` — Toggled when requesting resubmit. TINYINT(1), default 0.
- `graded_by` — Set on finalize. INT UNSIGNED, FK to sys_users.
- `graded_at` — Set on finalize. DATETIME.
- `score_published_at` — Set if auto_publish or manual publish. DATETIME.

### lms_homework (for context)
- `id` — Used to load the homework. INT UNSIGNED.
- `title` — Displayed as homework title. VARCHAR(255).
- `is_gradable` — Controls whether marks field is shown. TINYINT(1).
- `max_marks` — Maximum allowed marks. DECIMAL(5,2).
- `auto_publish_score` — Controls automatic score visibility. TINYINT(1).
- `class_id`, `section_id`, `subject_id` — Displayed for context.

### lms_homework_assignment (for student list and status sync)
- `id` — Links to submission. INT UNSIGNED.
- `student_id` — Displayed as student name. INT UNSIGNED.
- `homework_id` — Filters to the selected homework. INT UNSIGNED.
- `status_id` — Synced when submission is graded. INT UNSIGNED.
- `due_date` — Used for late calculation. DATETIME.

---

## Deep Analysis

### Business Workflows & State Machines

The Paper Check evaluator provides a specialized grading interface with three teacher-driven actions on the current submission state:

| Current Submission State | Allowed Action | Resulting State | Side Effects |
|---|---|---|---|
| SUBMITTED / LATE_SUBMITTED | Save Draft | UNDER_REVIEW | Status updated. No notification. |
| SUBMITTED / LATE_SUBMITTED | Finalize Grade | GRADED | `graded_by`, `graded_at`, `marks_obtained`, `teacher_feedback` set. Assignment status synced to GRADED. Notification sent if `auto_publish_score`. |
| SUBMITTED / LATE_SUBMITTED / UNDER_REVIEW | Request Resubmission | RESUBMIT_REQUESTED | `is_resubmission_requested = 1`. Clears grade fields. Assignment status unchanged. |
| GRADED | Recheck | SUBMITTED | All grade fields cleared. Assignment status reverted. Enables re-evaluation. |
| UNDER_REVIEW | Save Draft (again) | UNDER_REVIEW | Overwrites previous draft. |

The save-as-draft workflow allows the teacher to annotate PDFs, enter partial marks, and return later. Drafts are persisted to the database (not localStorage — that's for annotation canvas state).

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Marks entry | Only shown if `is_gradable = 1` | N/A — field hidden |
| Marks entry | Must be 0 ≤ marks ≤ `max_marks` | "Marks must be between 0 and {max_marks}." |
| Marks entry | Supports partial marks (DECIMAL(5,2)) | N/A — allowed |
| Save Draft (no marks) | Allowed even if marks_obtained is NULL | N/A — draft state |
| Finalize (no marks, gradable) | Blocked if marks_obtained is NULL | "Marks are required before finalizing." |
| Finalize (not gradable) | Allowed without marks; only feedback saved | N/A |
| Finalize — auto_publish | If 1, `score_published_at` = NOW() | N/A |
| Request resubmission | Clears `graded_by`, `graded_at`, `marks_obtained` | N/A — automatic |
| Request resubmission | Increments `resubmission_count` | N/A — automatic |
| Recheck | Only available if status is GRADED | "This submission is not graded." |
| Annotated PDF upload | Stored as type "teacher_feedback" in `sub_attachment_media_id` JSON array | N/A |
| Annotations (localStorage) | Persist across page refreshes; lost on cache clear | N/A — browser behavior |
| Resubmission count | Max TINYINT UNSIGNED = 255 | N/A — practical limit far below |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Submission Management | `lms_homework_submissions` | (primary table) | All evaluation data read/written here |
| Assignment Tracking | `lms_homework_assignment` | `lms_homework_submissions.assignment_id` | Assignment status synced on grade |
| Homework Core | `lms_homework` | `lms_homework_submissions.homework_id` | Grading context (is_gradable, max_marks, auto_publish_score) |
| Users | `sys_users` | `lms_homework_submissions.{graded_by,updated_by}` | Teacher who graded |
| Media | `sys_media` | (referenced in JSON) | Annotated PDF uploads |
| Activity Log | `lms_homework_activity_log` | (event-based) | All evaluation actions logged |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| Open Paper Check evaluator | Teacher | `lms.homework.paper_check.access` |
| Save evaluation draft | Teacher | `lms.homework.paper_check.draft` |
| Finalize grade | Teacher | `lms.homework.paper_check.finalize` |
| Request resubmission | Teacher | `lms.homework.paper_check.resubmit.request` |
| Recheck graded submission | Teacher, Admin | `lms.homework.paper_check.recheck` |
| Upload annotated PDF | Teacher | `lms.homework.paper_check.annotation.upload` |
| Publish score from evaluator | Teacher | `lms.homework.paper_check.score.publish` |
| View all evaluations | Admin | `lms.homework.paper_check.view_all` |
