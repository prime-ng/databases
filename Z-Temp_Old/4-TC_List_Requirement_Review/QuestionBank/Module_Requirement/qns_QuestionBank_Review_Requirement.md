# Question Review — Business Requirements

## What This Screen Does

The Question Review screen is where department heads and reviewers evaluate questions submitted by teachers. Think of it as a quality control desk — reviewers can see all questions awaiting their review, examine the question details, and either approve or reject them with feedback.

The review workflow ensures that only quality questions reach students. Questions pass through states: DRAFT → IN_REVIEW → APPROVED → PUBLISHED (or REJECTED). Each review decision is logged with the reviewer's identity, the decision, the date, and an optional comment (mandatory for rejection). Activity is recorded via activityLog().

---

## When This Screen Is Used

- **Reviewing Submitted Questions** — When a teacher submits a question for review, it appears in the reviewer's queue
- **Approving a Question** — When a reviewer finds the question correct and well-constructed
- **Rejecting a Question** — When a question has errors, incomplete taxonomy, or quality issues
- **Viewing Review History** — To see the complete audit trail of all review decisions for a question

---

## Who Can Access This Screen

- **Head of Department** — Can review questions for their department's subjects
- **Academic Coordinator** — Full review access
- **School Admin** — Full review access
- **Teacher** — Can view review status of their own questions
- **Principal** — Read-only

All access is controlled by permissions like `tenant.question-bank.viewAny`, `tenant.question-bank.view`, `tenant.question-bank.update`.

---

## How This Screen Works — Logic Flow (Non-Technical)

### The Review List

When a reviewer opens the Question Review tab, the system shows a paginated list of questions awaiting review. The list includes filters for Class, Subject, and Review Status. Each row shows: question content (truncated), class/subject, author (creator name + date), review status (coloured badge), and an Actions button.

### Viewing Review Details

Clicking "View Details" opens the detailed review page which shows:
- **Left Column:** Question title (linked to the full question view), reviewer details, review status badge with icon, review date
- **Right Column:** Status (Active/Inactive), created at, last updated, deleted at (if applicable)
- **Review Comment Card:** The reviewer's feedback with coloured border matching the status (green for approved, red for rejected, yellow for pending)
- **Question Summary Card:** If the question still exists, shows class, subject, question type, marks, Bloom level, complexity, status badge, and created by
- **Review Log Card:** Shows the single review log entry with reviewer details, decision, comment, and timestamp

### Approving a Question

When a reviewer clicks "Approve," the system:
1. Changes the question status from IN_REVIEW to APPROVED
2. Creates a review log entry with the reviewer's ID, status = APPROVED, and comment (defaults to 'Approved' if no comment provided)
3. Records an activity log entry via `activityLog()`
4. Redirects to the review list filtered by APPROVED status
5. Shows a success message "Question Approved successfully."

### Rejecting a Question

When a reviewer clicks "Reject," the system:
1. Validates that a comment is provided (required for rejection)
2. Changes the question status from IN_REVIEW to REJECTED
3. Creates a review log entry with the reviewer's ID, status = REJECTED, and mandatory comment
4. Records an activity log entry via `activityLog()`
5. Redirects to the review list filtered by REJECTED status
6. Shows a success message "Question Rejected successfully."

### Review History

Every review decision is recorded in the `qns_question_review_log` table, creating an audit trail. Each review log entry can be viewed individually via the review show endpoint (`/question-review/{id}`), which loads a single log with its associated question, reviewer, and status data.

---

## Business Rules and Conditions

### Rule 1: Rejection Requires Comment
When a reviewer rejects a question, a written explanation is mandatory. Rejecting without a comment is blocked with "A comment is required when rejecting a question."

### Rule 2: Immutable Review Log
Once a review log entry is created, it cannot be edited via the application. The model uses `SoftDeletes`, so entries can be soft-deleted at the database level, but no edit/delete UI is exposed. It serves as a permanent audit trail.

### Rule 3: Status Transition Path
- DRAFT → IN_REVIEW → APPROVED → PUBLISHED (standard path)
- IN_REVIEW → REJECTED (with comment required)

### Rule 4: reviewApprove Sets APPROVED (Not PUBLISHED)
The `reviewApprove()` method in `QuestionReviewService` sets the question status to `APPROVED`, not `PUBLISHED`. This matches the expected FSM path (IN_REVIEW → APPROVED). Note that the FRD v1.0 documented this as a PUBLISHED bypass gap, but the current code correctly transitions to APPROVED. A separate publish action is required to move from APPROVED to PUBLISHED.

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| Rejection Comment | A comment is mandatory when rejecting a question |
| Review Log | Log entries are immutable via UI; model supports SoftDeletes at DB level |
| Default Comment | Approve defaults comment to 'Approved' when none provided |
| Activity Logging | Approve/reject calls activityLog() to record the action |
| FSM Correct | reviewApprove() sets APPROVED (not PUBLISHED) as per correct FSM |

---

## Validate Before Save — Error Messages

| Scenario | Error Message |
|----------|--------------|
| Rejection without comment | "A comment is required when rejecting a question." |

---

## Success Scenarios

- A department head opens the review queue, sees a question pending review, examines the content, finds everything correct, clicks "Approve" with an optional comment "Good question. Ready for publishing." The question status changes to APPROVED, a review log entry is created, and an activity log entry is recorded.

- A reviewer finds a question with an incorrect answer key. They click "Reject" and enter "The correct answer should be Option B, not Option C. Please fix and re-submit." The question status changes to REJECTED, and an activity log entry is recorded.

---

## Failure Scenarios

- A reviewer clicks "Reject" without typing any comment. The system blocks the action with "A comment is required when rejecting a question."

---

## Example Scenario

Mr. Verma, the Head of the Science Department, opens the Question Review tab. He sees 3 questions pending review.

He opens the first question — a Biology MCQ about photosynthesis. The question is well-written. He clicks "Approve" with a comment "Well-structured question. Approved."

He opens the second question — a Physics numerical. The question content is good, but the complexity level is set to "Easy" when it should be "Hard". He clicks "Reject" and enters "The complexity level should be Hard, not Easy. Please update." The question status is set to REJECTED.

---

## Related Screens

- **Question Bank** — Where question details and review history can be viewed

---

## Dependencies module and tables

| Module | Tables |
|--------|--------|
| QuestionBank Core | `qns_questions_bank` (FK → question_id), `qns_question_review_log` (primary table) |
| System Config | `sys_users` (reviewer FK), `sys_dropdown_table` (review_status_id) |
