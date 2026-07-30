# std_ApplicationReview — Business Requirements

## What This Screen Does

The Application Review screen is the decision hub for leave applications within the Student Profile module. It provides authorized staff with a complete workflow to review, approve, reject, or request additional information/documentation for student leave applications. The feature comprises five functional views: a paginated review list with filters, a detailed review page with decision form, a real-time chat-style remarks interface, and a document viewer with cascading filters.

This screen transforms raw student leave requests into a structured decision pipeline. Without this feature, schools would have no centralized mechanism to track which leave applications have been reviewed, approved, or rejected, and no audit trail of the decision-making process.

---

## When This Screen Is Used

- Daily Review when class teachers and administrators review pending leave applications submitted by students or parents
- Decision Execution when an authorized reviewer determines the outcome of a specific leave request
- Information Exchange when the reviewer needs to request additional details or documents from the applicant, or provide remarks about the decision
- Document Verification when the reviewer needs to view supporting documents attached to a leave application or submitted in response to document requests
- Audit Review when tracking the history of status changes, reviewer actions, and communications related to a leave application

---

## Default Data Load

This screen is accessed via the `/student-profile/student-leave` URL with tab parameter `tab=application-review`. When the user navigates to the Student Leave page, the `StdLeaveController@index()` method loads the leave list with `tab=application-review` as the default display when no specific tab parameter is provided. The system loads class and section dropdown filters based on the logged-in user's assigned classes. Class teachers see their own class pre-selected as the default filter. Results are paginated at 15 records per page with ascending order.

---

## Key Fields at a Glance

**Application Identification**
The primary identifier is the `std_leave_applications` record, uniquely identified by `id`. Each application is tied to a `student_id` (linked via the `Student` model), an `academic_session_id`, and a `class_section_id`. The leave type (`leave_type_id` references a system dropdown) and date range (`from_date`, `to_date`) define the period of absence.

**Decision and Status Management**
The `status` field governs the application lifecycle and can be one of: Draft, Submitted, Under Review, Info Requested, Doc Requested, Approved, Rejected, Cancelled. The `reviewed_by` field records the user who made the decision, and `reviewed_at` timestamps the action. `approved_days` stores how many days within the range were approved, which may be less than `total_days` for partial approval.

**Audit Trail**
Each status change is automatically logged as a `status_change` remark in the `std_leave_application_remarks` table, capturing `old_status` and `new_status`. The `std_leave_application_remarks` table also stores chat-style comments (`message`), file attachments (linked via `std_leave_application_documents`), and tracks whether remarks come from the teacher side (`is_from_teacher`).

---

## Business Rules and Conditions

**Allowed Status Transitions via Review**
The review form allows setting the status to exactly one of five values: Under Review, Approved, Rejected, Info Requested, Doc Requested. The statuses "Draft", "Submitted", and "Cancelled" cannot be set via the review form. "Submitted" exists as a filterable value on the index but is not a valid target for updateReview.

**Attendance on Approval**
When the status is changed to "Approved", the system automatically upserts `std_student_attendance` rows with status "Leave" for each day within the approved range. If `approved_days` is less than `total_days`, attendance is marked only for the approved number of days. If `approved_days` is zero, no attendance rows are created.

**Automatic Status Change Logging**
Every status transition performed via updateReview automatically creates a `status_change` remark entry in `std_leave_application_remarks` recording the old and new status values. This ensures a complete audit trail without requiring the reviewer to manually log the change.

**Chat Disabled for Finalized Statuses**
The remarks chat interface is locked for applications with status "Approved", "Rejected", or "Cancelled". When a user selects an application in one of these finalized states, the chat footer displays a locked message instead of the input controls. The `storeRemark()` controller method also rejects these statuses with a 403 response server-side.

**Attachment Handling in Remarks**
When sending a remark, the user may include file attachments. Supported types are PDF, JPEG, and PNG (max 5 MB per file). If the user attaches files without typing a message, the system auto-generates "Attached N file(s)" as the message text. If neither message nor attachments are provided, the system returns a 422 validation error.

**Document Icon Mapping**
Document cards in the Documents tab display file type icons based on extension: `.pdf` renders a red icon (`fa-file-pdf`), `.jpg`/`.png` render a blue icon (`fa-file-image`), `.doc`/`.docx` render a teal icon (`fa-file-word`), and all other extensions fall back to a gray generic icon (`fa-file-alt`).

**Cascading Filter Dependency**
Both the Remarks tab and Documents tab use a three-level cascade: the user selects a class section, which populates the student dropdown via AJAX (`getStudentsBySection`). Selecting a student populates the application dropdown via AJAX (`getApplicationsByStudent`). No chat or document content is displayed until an application is selected.

---

## Workflow Steps

**Reviewing and Deciding on a Leave Application**
The reviewer navigates to the Student Leave page and selects the Application Review tab. They use the search bar (by student name, email, or admission number) or the class/section/status filter dropdowns to locate the target application. Clicking the "Review" action button on the desired row opens the detailed Review page. The sidebar displays the student's avatar, name, ID, class/section, leave type, total days, half-day indicator, who applied, and the requested period. The application summary card shows the reason for leave in a styled quote block. The reviewer selects one of five status radio buttons (Under Review, Approved, Rejected, Info Requested, Doc Requested), optionally enters review remarks (max 1000 characters), and optionally adjusts the approved days (defaults to total_days, min 0, max total_days). Clicking "Apply Decision" submits the form via PUT to `/student-leave/{id}/update-review`. The system validates, transitions the status, auto-logs the status change remark, upserts attendance rows if Approved, writes a "Reviewed" activity log entry, and redirects back to the Application Review tab with a success flash message.

**Exchanging Remarks via Chat**
The reviewer navigates to the Leave Remarks tab, selects a class section from the first dropdown, then a student from the dynamically populated second dropdown, then an application from the third dropdown. The chat header displays the selected student's avatar, name, leave type, and status badge with links to Review and Edit pages. The chat body shows all existing remarks grouped by day with date dividers, teacher remarks right-aligned (blue), and other remarks left-aligned (green). The reviewer types a message in the auto-resizing textarea and presses Enter to send (Shift+Enter inserts a newline), or optionally attaches files. The system creates the remark and document records, logs a "Remark Added" activity entry, and appends the new chat item to the conversation via AJAX without page reload. For finalized statuses (Approved, Rejected, Cancelled), the chat footer shows a locked message and the input controls are hidden.

**Viewing Documents**
The reviewer navigates to the Documents tab and uses the same three-level cascade (class section → student → application) to filter. Document cards display a file type icon, document name, student name with date, uploader name, document type badge, description (if present), and a "Response" badge if the document was submitted in response to a document request. Each card has a dropdown with "View" (opens in new tab) and "Download" actions. A footer link "Open Related Application" navigates to the Review page for that application.

---

## Example Scenario

A class teacher logs in to review pending leave applications for the week. On the Application Review tab, they see 23 applications with "Submitted" status. They use the search bar to locate student "Rahul Sharma" by admission number "STU-2026-0421" and click "Review".

The Review page shows Rahul's profile in the sidebar: Class 10-A, requested leave from June 10 to June 14 (5 days, full days) for a family wedding. The teacher selects "Approved" as the status, notes "Approved — submit assignments upon return" in the review remarks, and changes approved_days to 4 (deciding that June 14 is a half-day that doesn't require a full leave mark). The teacher clicks "Apply Decision".

The system transitions the status from "Submitted" to "Approved", logs a status_change remark with old=Submitted and new=Approved, upserts 4 attendance rows (June 10–13, status=Leave) in `std_student_attendance`, writes a "Reviewed" activity log, and redirects to the tab with a green flash "Application reviewed successfully."

Later, the teacher navigates to the Leave Remarks tab to respond to a parent's query about a different application. They select the class section, find the student, and see the application has "Info Requested" status. The teacher types a response in the chat and attaches a scanned document. The parent will see the response and uploaded document from their portal.

---

## Related Screens

- **Student Leave List (tab=leave-type)** — The companion tab where leave applications are created and managed; applications flow from here into the review pipeline
- **Student Profile Screen** — The parent screen accessed via `/student-profile` that hosts the Student Leave section
- **Attendance Module** — Receives attendance data from approval actions; the `std_student_attendance` rows created on approval appear in daily attendance reports
- **Student/Parent Portal** — Consumes the review decisions and remarks; applicants can view the status, decision remarks, and respond to info/document requests

---

## Requirements

- The system MUST serve the Application Review Index at `GET /student-profile/student-leave?tab=application-review` via `StdLeaveController@index()`.
- The system MUST authorize the index view via `Gate::authorize()` using the `tenant.student-leave.viewAny` permission.
- The system MUST authorize the review page via `Gate::authorize()` using the `tenant.student-leave.review` permission.
- The system MUST authorize update review, store remark, and remark/document creation via `Gate::authorize()` using the `tenant.student-leave.update` permission.
- The system MUST authorize AJAX endpoints (`getStudentsBySection`, `getApplicationsByStudent`) via `Gate::authorize()` using the `tenant.student-leave.view` permission.
- The system MUST load class and section filter dropdowns on index, defaulting the class filter to the logged-in class teacher's assigned class when applicable.
- The system MUST support filtering by search (student name, email, admission_no), class_id, section_id, and status on the index list.
- The system MUST paginate index results at 15 records per page with query string persistence.
- The system MUST render the Review page at `GET /student-profile/student-leave/{id}/review` with student info sidebar, application summary card, and review form.
- The system MUST accept PUT requests at `/student-profile/student-leave/{id}/update-review` to process the decision.
- The system MUST validate the `status` field as required and one of: Under Review, Approved, Rejected, Info Requested, Doc Requested.
- The system MUST validate `review_remarks` as nullable string, max 1000 characters.
- The system MUST validate `approved_days` as nullable integer, min 0, max equal to the application's `total_days`.
- The system MUST auto-create a `status_change` remark entry recording `old_status` and `new_status` on every status transition.
- The system MUST upsert `std_student_attendance` rows (status='Leave') for the approved number of days when status changes to Approved.
- The system MUST write a "Reviewed" activity log entry on every successful updateReview action.
- The system MUST redirect to `student-leave.index?tab=application-review` with a success flash message after updateReview.
- The system MUST render the Leave Remarks tab at `GET /student-profile/student-leave?tab=leave-remarks` with cascading filters and chat interface.
- The system MUST render the Documents tab at `GET /student-profile/student-leave?tab=documents` with cascading filters and document cards.
- The system MUST provide AJAX endpoint `GET /student-profile/student-leave/ajax/students` returning students filtered by `class_section_id`.
- The system MUST provide AJAX endpoint `GET /student-profile/student-leave/ajax/applications` returning applications filtered by `student_id`.
- The system MUST accept POST requests at `/student-profile/student-leave/remarks/store` to create remarks with optional attachments.
- The system MUST validate `storeRemark` requests: `leave_application_id` required and exists, `message` nullable string, `attachments.*` nullable file max 5120 KB, `document_type_id` nullable integer exists in dropdown, `description` nullable string max 255.
- The system MUST require at least one of `message` or `attachments` for a remark to be stored.
- The system MUST reject `storeRemark` with HTTP 403 when the application status is Approved, Rejected, or Cancelled.
- The system MUST generate "Attached N file(s)" as the message when attachments are provided without a message.
- The system MUST auto-resize the chat textarea and submit on Enter (Shift+Enter for newline).
- The system MUST return JSON with rendered `_chat_item` HTML from `storeRemark` for AJAX responses.
- The system MUST display document cards with file type icons determined by extension.
- The system MUST provide View and Download actions on document cards, and an "Open Related Application" footer link.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.student-leave.*` (all permissions) | Full access: view any, review, update, view list |
| Class Teacher | `tenant.student-leave.viewAny` + `.review` + `.update` + `.view` | Full review workflow for assigned class; sees default class filter |
| Administrator | `tenant.student-leave.viewAny` + `.review` + `.update` + `.view` | Full review workflow across all classes/sections |
| HOD / Academic Staff | `tenant.student-leave.viewAny` + `.view` | Read-only: can view list, remarks, documents, but cannot review or update |
| Student / Parent | No explicit permission | No access via this screen (applicants interact via their own portal) |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user navigates to the Student Profile section and clicks on Student Leave. The system defaults to the Application Review tab if no tab is specified.
2. The system checks the user's permission via `Gate::authorize()`. If the user lacks the required permission, a 403 error is shown.
3. The system loads class and section filters. If the logged-in user is a class teacher, their assigned class is pre-selected as the default filter.
4. The user can filter the list by typing a student name/admission number in the search bar, or by selecting a class, section, or status from the dropdowns. Clicking "Clear" resets all filters.
5. Each application row displays student name with admission number, class/section, leave type, date range, total days, half-day indicator, who applied, a color-coded status badge, and action buttons (Edit, Review, Add Remark, View Documents).
6. The user clicks "Review" on a row, which opens the detailed Review page at `/student-leave/{id}/review`.
7. The Review page shows a sidebar with the student's photo, name, ID, class/section, leave type, total days, partial-day flag, who applied the request, and the requested date period. Below the sidebar, an application summary card presents the leave reason in a styled quote.
8. The main review form presents five radio buttons for the new status (Under Review, Approved, Rejected, Info Requested, Doc Requested) with the current status pre-checked. A textarea allows optional review remarks (max 1000 characters). An "Approved Days" numeric input defaults to total_days with a minimum of 0 and maximum of total_days. The last action section shows who previously reviewed and when.
9. The user makes a decision and clicks "Apply Decision". The system validates all inputs, transitions the status, automatically logs the status change as an audit remark, creates attendance records if Approved, logs the activity, and redirects back to the Application Review tab with a success message.
10. To exchange remarks, the user switches to the Leave Remarks tab. They select a class section from the first dropdown — the system dynamically loads the student dropdown. Selecting a student loads the application dropdown. Once an application is selected, the chat interface activates showing conversation history.
11. If the application has a finalized status (Approved, Rejected, Cancelled), the chat input is locked with a message explaining why. Otherwise, the user can type remarks and attach files, sending via Enter key. The chat updates instantly without page reload.
12. To view documents, the user switches to the Documents tab and follows the same cascading filter process. Document cards show file type icons, metadata, and actions for viewing or downloading. Each card has an "Open Related Application" link.

---

## Validate Before Save (Multiple Conditions)

1. **Status Required** — `status` field must not be empty. Error: "Status is required."
2. **Status Allowed Value** — `status` must be one of: Under Review, Approved, Rejected, Info Requested, Doc Requested. Error: "Selected status is not valid."
3. **Review Remarks Max Length** — `review_remarks` must not exceed 1000 characters. Error: "Review remarks must not exceed 1000 characters."
4. **Approved Days Required** — `approved_days` must be an integer when provided. Error: "Approved days must be a number."
5. **Approved Days Min** — `approved_days` must be at least 0. Error: "Approved days must be at least 0."
6. **Approved Days Max** — `approved_days` must not exceed the application's total_days. Error: "Approved days cannot exceed the total leave days."
7. **Application Exists** — `leave_application_id` must exist in `std_leave_applications` table. Error: "The selected leave application is invalid."
8. **Message or Attachments Required** — At least one of `message` or `attachments` must be provided when storing a remark. Error: "Please provide a message or attach a file."
9. **Attachment File Size** — Each attachment must not exceed 5120 KB (5 MB). Error: "Attachment must not exceed 5 MB."
10. **Attachment File Type** — Attachments must be one of: pdf, jpeg, png, jpg. Error: "Attachment must be a file of type: pdf, jpeg, png, jpg."
11. **Document Type Exists** — `document_type_id` must exist in `sys_dropdown_table` when provided. Error: "Selected document type is invalid."
12. **Description Max Length** — `description` must not exceed 255 characters. Error: "Description must not exceed 255 characters."
13. **Chat Not Allowed for Finalized Statuses** — Application must not be in Approved, Rejected, or Cancelled status to send a remark. Error: "Chat is disabled for this application."
14. **Authorization — viewAny** — User must have `tenant.student-leave.viewAny` permission to access the index. Error: "This action is unauthorized." (403)
15. **Authorization — review** — User must have `tenant.student-leave.review` permission to access the Review page. Error: "This action is unauthorized." (403)
16. **Authorization — update** — User must have `tenant.student-leave.update` permission to update review or store remarks. Error: "This action is unauthorized." (403)

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Status field is missing | "Status is required." | 422 |
| Status value not in allowed list | "Selected status is not valid." | 422 |
| Review remarks exceed 1000 characters | "Review remarks must not exceed 1000 characters." | 422 |
| Approved days is negative | "Approved days must be at least 0." | 422 |
| Approved days exceeds total_days | "Approved days cannot exceed the total leave days." | 422 |
| Non-existing application ID for review/update | "No query results for model [LeaveApplication]." | 404 |
| Soft-deleted application ID for review/update | "No query results for model [LeaveApplication]." | 404 |
| Missing leave_application_id for remark | "The selected leave application is invalid." | 422 |
| No message and no attachments for remark | "Please provide a message or attach a file." | 422 |
| Attachment exceeds 5 MB | "Attachment must not exceed 5 MB." | 422 |
| Attachment has invalid file type | "Attachment must be a file of type: pdf, jpeg, png, jpg." | 422 |
| Invalid document_type_id | "Selected document type is invalid." | 422 |
| Description exceeds 255 characters | "Description must not exceed 255 characters." | 422 |
| Send remark on Approved application | "Chat is disabled for this application." | 403 |
| Send remark on Rejected application | "Chat is disabled for this application." | 403 |
| Send remark on Cancelled application | "Chat is disabled for this application." | 403 |
| Unauthorized access (missing permission: viewAny) | "This action is unauthorized." | 403 |
| Unauthorized access (missing permission: review) | "This action is unauthorized." | 403 |
| Unauthorized access (missing permission: update) | "This action is unauthorized." | 403 |
| Guest user (not authenticated) | Redirect to /login | 302 |

---

## Success Scenarios

**SC-001: Approving a Leave Application with Full Attendance**
1. Reviewer finds an application with "Submitted" status for student in Class 10-A (leave: June 10–14, 5 days).
2. Reviewer opens the Review page, selects "Approved" status, enters remarks "Approved.", keeps approved_days at default 5.
3. System validates, transitions status to Approved, logs status_change remark (Submitted→Approved), upserts 5 attendance rows (June 10–14, status=Leave), writes "Reviewed" activity log.
4. System redirects to Application Review tab with success flash: "Application reviewed successfully."

**SC-002: Partial Approval with Limited Attendance**
1. Reviewer approves a 5-day leave but the student only needs 3 days off.
2. Reviewer sets approved_days to 3 before submitting.
3. System creates attendance rows for only 3 days (the first 3 days of the range), not all 5.

**SC-003: Sending a Remark with File Attachments**
1. Reviewer navigates to Leave Remarks tab, selects class section, student, and an application with "Info Requested" status.
2. Reviewer types a response in the chat textarea and attaches two PDF files.
3. System creates a LeaveApplicationRemark with the message and is_from_teacher=true, creates two LeaveApplicationDocument records linked to the remark, writes "Remark Added" activity log.
4. Chat updates instantly showing the new remark with attachment links.

**SC-004: Requesting Additional Information**
1. Reviewer opens an application, selects "Info Requested" status, and types "Please provide doctor's certificate for the medical leave."
2. System transitions status from "Submitted" to "Info Requested", logs the status change, saves the review remarks.
3. The student/parent sees the updated status and remark on their portal and can respond via the remarks chat.

---

## Failure Scenarios

**FC-001: Invalid Status Value Rejected**
1. Reviewer attempts to change status to "Cancelled" via the updateReview endpoint (manipulated request).
2. System validation fails because "Cancelled" is not in the allowed list (Under Review, Approved, Rejected, Info Requested, Doc Requested).
3. Error: "Selected status is not valid." (422). Status remains unchanged.

**FC-002: Approved Days Exceeds Total Days**
1. Reviewer sets approved_days to 8 for an application with total_days=5.
2. System validation fails with error: "Approved days cannot exceed the total leave days."
3. No changes are saved. Reviewer must correct the value.

**FC-003: Sending Remark on a Finalized Application**
1. Reviewer navigates to Leave Remarks tab for an application already marked as "Approved".
2. Chat footer shows a locked icon with message "Chat is disabled — application is already approved."
3. Reviewer attempts to send a remark via direct POST request.
4. System returns HTTP 403 with error: "Chat is disabled for this application."

**FC-004: Unauthorized Access Attempt**
1. A user who lacks `tenant.student-leave.review` directly navigates to `/student-profile/student-leave/5/review`.
2. `Gate::authorize()` throws an authorization exception.
3. System returns HTTP 403 with message: "This action is unauthorized."

**FC-005: Non-Existing Application Accessed**
1. Reviewer navigates to `/student-profile/student-leave/9999/review` where ID 9999 does not exist.
2. `findOrFail()` throws ModelNotFoundException.
3. System returns HTTP 404.

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Primary Table | `std_leave_applications` | `id`, `student_id`, `academic_session_id`, `class_section_id`, `leave_type_id`, `from_date`, `to_date`, `total_days`, `is_half_day`, `half_day_slot`, `reason`, `status` (enum: Draft/Submitted/Under Review/Info Requested/Doc Requested/Approved/Rejected/Cancelled), `is_active`, `applied_by`, `reviewed_by`, `reviewed_at`, `approved_days`, `review_remarks`, `deleted_at` (SoftDeletes), `created_at`, `updated_at` |
| Related Table | `std_leave_application_remarks` | `id`, `leave_application_id`, `remark_type` (comment/info_request/doc_request/response/status_change), `message`, `is_from_teacher`, `remarked_by`, `parent_remark_id`, `is_resolved`, `resolved_at`, `old_status`, `new_status`, `is_active`, `created_at`, `updated_at` — permanent audit trail (no SoftDeletes) |
| Related Table | `std_leave_application_documents` | `id`, `leave_application_id`, `document_name`, `document_type_id`, `description`, `file_name`, `media_id`, `uploaded_by`, `is_in_response_to_request`, `request_remark_id`, `is_active`, `deleted_at` (SoftDeletes + InteractsWithMedia), `created_at`, `updated_at` — media collection `leave-documents` on disk `public`, accepts pdf/jpeg/png |
| Related Table | `std_student_attendance` | Upserted on approval — receives rows with status='Leave' for each approved day |
| Module Dependency | Student Profile Module | Core module hosting the leave management subsystem via `/student-profile` URL prefix |
| Module Dependency | User & Permission Module | `Gate::authorize()` checks `tenant.student-leave.*` permissions (viewAny, review, update, view) |
| Module Dependency | Attendance Module | Consumes approved leave data via `std_student_attendance` rows for daily attendance reporting |
| Module Dependency | System Dropdown Module | `leave_type_id` and `document_type_id` reference `sys_dropdown_table` for configurable leave types and document categories |
