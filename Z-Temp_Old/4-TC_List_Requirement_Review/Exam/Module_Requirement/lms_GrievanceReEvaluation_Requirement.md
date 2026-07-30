# Grievance & Re-Evaluation — Business Requirements

---

## What Does This Screen Do?

This screen allows teachers and administrators to view, manage, and resolve re-evaluation requests (called grievances) filed by students regarding their published exam results. Students submit grievances through their Student Portal when they believe a result has a marking error, a question error, is out of syllabus, or any other concern. The back-office interface provides a dashboard with status counts, a filterable list of all grievances, a detail view with context (student info, exam details, current marks), and a resolution form where the reviewer can change the status, add remarks, and optionally revise the student's marks.

There are two ways to access this functionality:
1. A standalone route (`/exam-grievances`) managed by `GrievanceReviewController` — a dedicated page with filters, a list table, and the ability to create new grievances manually.
2. A tab within the Exam Management page (`/exam/log-grievance`) managed by `LmsExamController@logGrievance` — which combines the grievance list with two additional tabs: Activity Log and Event Log (checkpoints). This tab view also includes class/section/student cascading filters and an inline resolve modal.

---

## Real-Life Example

After the final exam results are published, a student named Priya files a grievance from her Student Portal saying her Mathematics paper was marked incorrectly — she believes question 5 was worth 5 marks but only received 2. The Exam Coordinator logs in, goes to the Grievance Review page, and sees Priya's grievance at the top of the list (Open grievances are sorted first). She clicks the eye icon to view the details. She sees Priya's current score (72/100), the grievance type (Marking Error), and Priya's full text. She changes the status to "Under Review" to indicate she's investigating. After checking the scanned answer sheet, she finds the marking was indeed too strict. She sets the status to "Resolved", enters "Rechecked question 5 — awarded additional 3 marks" as remarks, enters 75 as the new marks, and saves. The system automatically updates Priya's exam result to 75/100, recalculates her percentage and grade, recomputes her rank, and logs the activity.

---

## How It Works

Step 1 — A student files a grievance from the Student Portal, providing the exam paper, grievance type (Marking Error, Question Error, Out of Syllabus, or Other), and a description. This creates a record in the `lms_exam_grievances` table with status "OPEN."

Step 2 — An administrator or teacher with the appropriate permission navigates to the grievance review page. The system checks the `tenant.re-evaluation-requests.viewAny` permission.

Step 3 — Four stat cards at the top show the count of grievances in each status: Open (red), Under Review (yellow), Resolved (green), Rejected (gray). These counts are calculated by querying each status separately.

Step 4 — Below the stats, a filter bar allows narrowing the list by: search text (student name or grievance text), status, grievance type, exam, and optionally class/section/student (in the tab view).

Step 5 — The grievance list table displays one row per grievance showing: student name and ID, exam title and paper title, type badge, truncated grievance text (80 characters), status badge with color coding (plus a "Marks Revised" badge if marks were changed), the date filed, an active/inactive toggle switch, and action buttons.

Step 6 — The list is sorted by status priority: Open grievances appear first, then Under Review, Resolved, and Rejected last.

Step 7 — Clicking the eye icon opens the detail view. This shows:
- A header card with the grievance ID, status badge, active toggle, and a "Marks Revised" badge if applicable
- The context section showing the student's name and ID, exam title, paper title, marks obtained, total marks, percentage, and current result status
- The grievance details section showing the grievance type badge, the related question (if applicable), and the full grievance text
- If the grievance was already resolved, the resolution section shows the resolution remarks, the reviewer's name, and the resolution timestamp

Step 8 — On the detail view, if the grievance is still Open or Under Review, a "Review Action" panel appears on the right with a form to:
- Change the status (to Under Review, Resolved, or Rejected)
- Enter new marks (only shown when "Resolved" is selected)
- Enter resolution remarks (required when resolving or rejecting)

Step 9 — When the reviewer resolves a grievance with new marks, the system:
- Compares the new marks to the current marks
- If different, updates the exam result record with the new marks, recalculates the percentage, assigns a new grade, and updates the result status (PASS/FAIL) based on the passing percentage
- Recomputes the student's rank using the `ResultComputationService`
- Records the old marks, new marks, and sets the `marks_changed` flag to true on the grievance record
- Sets the `resolved_at` timestamp and `reviewer_id`
- Logs the activity

Step 10 — The reviewer can also toggle the active/inactive status of any grievance using a switch in the list view. This hides the grievance without deleting it.

Step 11 — Optionally, an admin can manually create a grievance on behalf of a student using a modal form. They search for the student, select the paper, choose the grievance type, and enter the description. The system automatically finds the corresponding exam result for that student and paper. If no result exists, it returns an error.

---

## Key Features / Widgets / Tabs

- **Status Count Cards (4)** — Open (red, exclamation icon), Under Review (yellow, magnifying glass), Resolved (green, check icon), Rejected (gray, ban icon). Each card shows the count prominently.
- **Filter Bar** — Search input (student name or grievance text), Status dropdown, Grievance Type dropdown, Exam dropdown, and in the tab view: Class/Section/Student cascading dropdowns.
- **Grievance List Table** — Shows Student (name + ID), Exam/Paper (title + paper title), Type (color badge), Grievance (truncated to 80 chars), Status (color badge with optional "Marks Revised" sub-badge), Filed On (date), Active (toggle switch), Action (eye button). In the tab view, there is also a resolve button.
- **Active/Inactive Toggle** — AJAX toggle switch that flips the `is_active` flag on a grievance without page reload.
- **Grievance Detail View** — Shows full context: grievance header (ID, status, active toggle, mark revision badge), student and exam info (name, ID, exam title, paper title, marks, percentage, result), grievance details (type badge, question reference, full grievance text), and resolution info if already resolved.
- **Review Action Panel** — Form on the detail view (visible only for Open/Under Review grievances) with: status dropdown, revised marks input (appears when "Resolved" is selected), remarks textarea, and save button.
- **Create Grievance Modal** — Modal with student search (Select2 with AJAX), paper selector (loaded based on student), grievance type dropdown, and description textarea.
- **Resolve Modal** (tab view only) — Inline modal to update status, enter remarks, and optionally revise marks without navigating to the detail page.
- **Cascading Class/Section/Student dropdowns** (tab view only) — Filters load dynamically via AJAX when a class is selected.
- **Activity Log Tab** — Second tab showing student exam activity events (attempt started, tab switch, window blur, fullscreen exit, violations).
- **Event Log Tab** — Third tab showing saved checkpoints (exam progress snapshots).
- **Auto-Seed of Event Types** — On accessing the log/grievance page, the system automatically creates the standard event types if they don't exist.
- **Pagination** — 20 records per page (standalone view) or 15 records per page (tab view), with distinct page parameter names to avoid conflicts.

---

## Business Rules

| # | Rule | Found In Code? |
|---|------|----------------|
| 1 | Grievance types are limited to: MARKING_ERROR, QUESTION_ERROR, OUT_OF_SYLLABUS, OTHER | Model/Request enum validation; Request line 27 |
| 2 | Statuses allowed: OPEN, UNDER_REVIEW, RESOLVED, REJECTED | Model fillable; Request line 34 |
| 3 | Grievance list is sorted by status priority: OPEN first, then UNDER_REVIEW, RESOLVED, REJECTED | Controller: `orderByRaw("FIELD(status, 'OPEN', 'UNDER_REVIEW', 'RESOLVED', 'REJECTED')")` |
| 4 | The standalone GrievanceReviewController checks permissions via Gates; the tab logGrievance method checks three separate gates for the three tabs | Controller GrievanceReviewController lines 25, 75, 109, 127, 205; LmsExamController lines 1033-1035 |
| 5 | Creating a grievance: if `exam_result_id` is not provided, the system auto-finds it by matching `student_id` + `exam_paper_id` | GrievanceReviewController lines 80-88 |
| 6 | Auto-find error: if no matching exam result is found, the system returns an error: "No result found for this student and paper." | GrievanceReviewController line 86 |
| 7 | Mark revision only happens when status is RESOLVED AND `new_marks` is provided AND the new marks differ from the old marks | GrievanceReviewController lines 147-176 |
| 8 | When marks change, the system updates: `total_marks_obtained`, `percentage`, `grade_obtained`, `result_status` on the ExamResult record | GrievanceReviewController lines 163-168 |
| 9 | Rank is recomputed after marks change via `ResultComputationService::recomputeRank()` for the same exam_id and exam_paper_id | GrievanceReviewController line 170 |
| 10 | The passing percentage for determining PASS/FAIL comes from the ExamPaper's `passing_percentage` field, defaulting to 33% | GrievanceReviewController line 159 |
| 11 | Resolving a grievance always sets `resolved_at` to the current timestamp | GrievanceReviewController line 143 |
| 12 | Resolution remarks are required when status is RESOLVED or REJECTED | Request line 35: `required_if:status,RESOLVED,REJECTED` |
| 13 | The toggle switch for active/inactive is handled via an AJAX call that flips the `is_active` boolean | GrievanceReviewController lines 203-215 |
| 14 | The review form on the detail page is ONLY shown when status is OPEN or UNDER_REVIEW | View: `$canEdit = in_array($grievance->status, ['OPEN', 'UNDER_REVIEW'])` |
| 15 | The "Marks Revised" badge appears on the list and detail views when `marks_changed` is true | View checks `$g->marks_changed` |
| 16 | The new marks input in the detail view shows the current marks as a reference and limits the max value to the paper's total marks | View: `max="{{ $result?->total_marks_possible ?? 999 }}"` |
| 17 | Activity is logged for every status update with message format: "Grievance #[id] status set to [status]." | GrievanceReviewController lines 180-183 |
| 18 | The tab view logGrievance() auto-seeds five event types (ATTEMPT_STARTED, TAB_SWITCH, WINDOW_BLUR, FULLSCREEN_EXIT, VIOLATION) if they don't exist | LmsExamController lines 1038-1049 |
| 19 | The tab view has two additional tabs: "activity_log" (shows AttemptActivityLog entries) and "event_log_pending" (shows AttemptCheckpoint entries) | LmsExamController lines 1091-1138 |
| 20 | The student search in the logGrievance method uses CONCAT(first_name, middle_name, last_name) to match full name; the standalone GrievanceReviewController uses the `full_name` field directly | LmsExamController line 1084 vs GrievanceReviewController line 50 |
| 21 | The new marks input accepts steps of 0.5 (decimal precision) | View: `step="0.5"` |
| 22 | The grievance text is limited to 2000 characters when creating via the form request | Request line 28: `max:2000` |

---

## Validation & Error Messages

| Scenario | Message | Location |
|----------|---------|----------|
| No exam result found when auto-creating grievance | "No result found for this student and paper. Please verify the selection." | GrievanceReviewController store() line 86 |
| Grievance updated successfully | "Grievance updated successfully." | GrievanceReviewController resolve() line 189 |
| Grievance logged successfully | "Grievance logged successfully." | GrievanceReviewController store() line 101 |
| Failed to update grievance | "Failed to update grievance. Please try again." | GrievanceReviewController resolve() catch block line 196 |
| Status toggled successfully | "Status updated successfully." (JSON response) | GrievanceReviewController toggleStatus() line 211 |
| No grievances found | "No grievances found" | View, @empty block |
| AJAX toggle fails | "Failed to update status." (alert) + checkmark reverted | View, JS error handler |
| Validation errors | Displayed as a list in the alert box on the detail view | View: `@if($errors->any())` block |

Validation rules from GrievanceRequest:
- `student_id` — required (POST), must exist in `std_students` table
- `exam_paper_id` — required (POST), must exist in `lms_exam_papers`
- `exam_result_id` — optional (POST), must exist in `lms_exam_results` if provided
- `grievance_type` — required (POST), must be one of: MARKING_ERROR, QUESTION_ERROR, OUT_OF_SYLLABUS, OTHER
- `grievance_text` — required (POST), string, max 2000 characters
- `status` — required (PATCH), must be one of: UNDER_REVIEW, RESOLVED, REJECTED
- `resolution_remarks` — required if status is RESOLVED or REJECTED, string, max 1000 characters
- `new_marks` — optional (PATCH), numeric, minimum 0

---

## Permissions

| Permission Key | Type | Description |
|----------------|------|-------------|
| `tenant.re-evaluation-requests.viewAny` | Gate | Required to view the grievance list (both standalone and tab) |
| `tenant.re-evaluation-requests.view` | Gate | Required to view a single grievance detail |
| `tenant.re-evaluation-requests.create` | Gate | Required to manually create a new grievance |
| `tenant.re-evaluation-requests.update` | Gate | Required to resolve/update a grievance and toggle active status |
| `tenant.student-attempt-activity-log.view` | Gate | Required for the Activity Log tab in logGrievance |
| `tenant.student-attempt-event-log.view` | Gate | Required for the Event Log tab in logGrievance |

---

## Related Screens

- **Student Portal (Grievance Filing)** — Students file grievances from the Student Portal; this is the admin back-office to review them.
- **Exam Management (Log & Grievance Tab)** — A combined tab page that includes grievances plus activity logs and event logs in one view.
- **Exam Result Report** — The grievance modifies exam results; the updated scores reflect here.
- **Paper Check Interface** — Grievances about marking errors relate to the paper-check workflow.
- **Student Profile** — Student details shown in the grievance context come from the student profile module.
