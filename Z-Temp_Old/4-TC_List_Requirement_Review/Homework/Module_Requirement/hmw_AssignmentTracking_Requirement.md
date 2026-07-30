# Assignment Tracking — Business Requirements

## What This Screen Does

The Assignment Tracking screen gives teachers a detailed, per-student view of what happened after a homework was published. Think of it as a class attendance register but for homework — it shows every student in the class and the current status of their homework assignment.

When a teacher publishes a homework, the system creates one "assignment record" for every student in the class. This screen is where the teacher can see all those individual records in one place. For each student, the teacher can see whether the assignment has been released (made visible to the student), whether the student has viewed it, whether they have submitted their work, and whether it has been graded. The teacher can also take specific actions for individual students — for example, giving a student extra time by changing their due date, manually releasing an assignment for a student who should have received it earlier, or sending a reminder notification.

This screen is especially useful for classes with many students where keeping track of each student's progress manually would be impossible. Instead of asking "Who has submitted?" in a group chat, the teacher can simply look at this screen and see exactly which students are on track, which ones are late, and which ones need individual attention.

---

## When This Screen Is Used

- **Checking Submission Progress:** A teacher wants to see how many students have submitted their homework, how many are overdue, and how many have not even viewed it yet.
- **Granting Extensions:** A student was absent for three days and needs extra time to complete their homework. The teacher extends only that student's due date without affecting the rest of the class.
- **Manual Release:** A homework was set to release on a scheduled date, but the system did not release it automatically for some students. The teacher manually toggles the release for those students.
- **Overriding Late Policy:** A usually responsible student submitted late because of a genuine technical issue. The teacher overrides the late submission policy for that student, allowing the submission to be accepted.
- **Sending Reminders:** It is two days before the due date and several students have not yet submitted. The teacher sends them a reminder notification from within this screen.
- **Quick Grading:** A teacher can grade a student's submission directly from the assignment view without navigating to a separate grading screen.

---

## Default Data Load

When a teacher navigates to the Assignment Tracking tab, the system loads all assignment records for the selected filters. By default (if no filters are selected), it shows assignments from the most recent homework across all classes the teacher has access to. Each record is displayed with the student's name and admission number, the homework title, the class/section/subject context, the release status, the due date, and the current assignment status. The list is paginated at 10 records per page and ordered with the most recent assignments first.

The system also loads a search bar that lets the teacher find specific assignments by typing a student's name, admission number, email address, or homework title. A class filter dropdown is available to narrow the view to a specific class.

---

## Key Fields at a Glance

**Student Information**
Each row shows the student's full name (First Name + Last Name) as the primary identifier. Below the name, the student's admission number is displayed in smaller grey text. This helps teachers quickly identify students, especially when there are multiple students with similar names.

**Homework Context**
The homework title is displayed so the teacher knows which homework each assignment belongs to. The class, section, and subject information is shown alongside, giving the teacher a quick reference for the context.

**Release Status**
This shows whether the assignment has been released (made visible) to the student. A green "Released" badge with a timestamp tells the teacher when it was released. If the assignment has not been released yet, an "Awaiting Release" badge is shown. The teacher can click a toggle button to manually release or unrelease the assignment for a specific student.

**Due Date**
Each student's due date is displayed. For most students, this will be the same as the homework's original due date. However, if the teacher has given a specific student an extension, the student's individual due date is shown here instead. This field can be edited inline to grant extensions.

**Assignment Status**
The current status of the assignment is shown as a colour-coded badge. The possible statuses are:
- **Pending Release** (grey) — The assignment has been created but not yet made visible to the student.
- **Assigned** (blue) — The assignment has been released and is visible to the student.
- **Viewed** (light blue) — The student has opened and viewed the assignment details.
- **Submitted** (green) — The student has submitted their work.
- **Late Submitted** (amber) — The student submitted after the due date.
- **Graded** (dark green) — The teacher has graded the submission.
- **Overdue** (red) — The due date has passed and the student has not submitted.
- **Exempted** (grey) — The student has been excused from this homework.

**Submission and Grading Information**
If the student has submitted, a link to view their submission is shown. If the submission has been graded, the marks obtained are displayed as a fraction (e.g., "15/20"). The teacher can click a button to grade the submission directly from this screen.

**Engagement Tracking**
Two fields track student engagement: "Viewed At" shows the date and time when the student first opened the assignment, and "View Count" shows how many times they have opened it. This information is automatically updated when the student accesses the assignment through their Student Portal.

---

## Business Rules and Conditions

**One Assignment Per Student Per Homework**
When a homework is published, the system creates exactly one assignment record for each enrolled student. This is enforced by a database rule that prevents two assignment records for the same combination of homework and student. If the teacher publishes the homework again (for example, if new students joined the class), the system updates existing records instead of creating duplicates.

**Extensions Can Only Add Time**
If a teacher wants to give a student extra time, they can change that student's individual due date. However, the new date must be later than the current due date. The system prevents setting an earlier deadline — you cannot reduce a student's time through this screen. This rule ensures that extensions are only used to give students more time, not to pressure them.

**Released Assignments Cannot Be Undone**
Once an assignment has been released (made visible to the student), the assign date and release date fields become locked. The teacher cannot change the date on which it was assigned because the student may have already seen it. However, the teacher can still toggle the release status (hide it again if needed) and change the due date.

**Late Override Requires a Reason**
If a teacher wants to override the late submission policy for a specific student (for example, allowing a late submission even though the homework does not generally allow late submissions), they must provide a written reason. This creates an audit trail so that administrators can see why exceptions were made.

**Notifications Are Sent Automatically**
When a teacher toggles release, changes a due date, or sends a reminder, the system automatically creates a notification record. In the current version, these notifications are stored in the database and are ready to be delivered once the notification delivery system is fully connected.

---

## Workflow Steps

**Viewing the Assignment List**
The teacher navigates to the Assignment Tracking tab. By default, the most recent assignments are shown. If the teacher wants to see assignments for a specific class, they select the class from the filter dropdown and click Search. If they want to find a specific student, they type the student's name or admission number in the search box.

**Opening a Single Assignment**
The teacher clicks the View button next to a student's name. A detailed view opens showing all information about that assignment: the homework details, the student's individual due date, release status, view tracking data, and any submission or grading information. From this view, the teacher can take all individual actions (extend due date, toggle release, grade, etc.).

**Granting a Due Date Extension**
The teacher finds the student who needs extra time. They click the Edit Due Date button and select a new, later date from the date picker. The system checks that the new date is indeed later than the current date. If it is, the system saves the change, the student's individual due date is updated, and a notification is created for the student. If the teacher accidentally selects a date that is earlier, the system shows an error message and the date is not changed.

**Manually Releasing an Assignment**
If a homework was set to release on a scheduled date but the automatic release did not happen for a particular student, the teacher can click the Release Toggle button. The system immediately updates the assignment — it becomes visible to the student, the release timestamp is recorded, and the status changes from "Pending Release" to "Assigned". The student receives a notification that a new homework is available.

**Sending a Reminder**
The teacher selects one or more students who have not yet submitted and clicks "Send Reminder". The system stamps a "reminder sent" timestamp on each selected student's assignment record and creates a notification. The student will see the reminder the next time they log into their Student Portal.

**Grading from Assignment View**
If a student has already submitted their work, the teacher can click the Grade button. A grading form opens within the same page (or navigates to the grading screen), where the teacher can enter marks and feedback without leaving the Assignment Tracking context.

---

## Example Scenario

**Scenario: Managing a Mixed-Progress Class**

Mr. Patel teaches Mathematics to Class 9-A. He published a homework on "Quadratic Equations" a week ago with a due date of 20 July. Today is 22 July. He opens the Assignment Tracking tab to check progress.

He sees the following:
- **25 students** have submitted on time (status: Submitted)
- **5 students** submitted late (status: Late Submitted, flagged in amber)
- **3 students** have not submitted and the due date has passed (status: Overdue, flagged in red)
- **2 students** have not even viewed the assignment yet (status: Assigned, viewed_at is null)

Mr. Patel takes the following actions:
1. He opens the record for Priya, who was absent for a week due to illness. He changes her due date from 20 July to 25 July (extension only — the new date is later). The system accepts the change and creates a notification for Priya.
2. He opens the record for Vikram, who submitted late because of a family emergency. He overrides the late policy for Vikram by entering a reason: "Family emergency — grandfather hospitalized." The system records the override and marks the late flag as overridden.
3. He selects the 3 students who haven't submitted yet and clicks "Send Reminder." The system stamps a reminder timestamp on each record and sends notifications.
4. For the 2 students who haven't even viewed the assignment, he decides to also send a separate reminder about viewing the assignment.

**What the Student Sees (Student Portal):**

When Priya logs into her Student Portal, she sees that her due date for the Quadratic Equations homework has been extended to 25 July — she now has extra time to complete it. She also sees a notification explaining that her teacher extended the deadline.

When Vikram logs in, he sees that his late submission has been accepted. He does not see any penalty or warning because his teacher overrode the late policy.

The 3 students who haven't submitted see a reminder notification: "Reminder: Your homework 'Quadratic Equations' is due soon. Please submit your work."

---

## Related Screens

- **Homework Management** — Where homework is created and published (assignments originate from published homework).
- **Homework Submission** — Where submissions are created and managed.
- **Paper Check** — A unified workspace for grading all submissions for a homework.
- **Homework Details Page** — Shows the full homework details that this assignment belongs to.

---

## Requirements

**Controller:** Modules\LmsHomework\Http\Controllers\LmsHomeworkController
- Methods: ssignmentsIndex() (via index() with tab filter), ssignmentsShow(), ssignmentsGrade(), ssignmentUpdateStatus(), ssignmentUpdateDueDate(), ssignmentUpdateAssignDate(), 	oggleAssignmentRelease()

**Model:** Modules\LmsHomework\Models\HomeworkAssignment (table: lms_homework_assignment)
- Key fields: homework_id, student_id, academic_session_id, class_id, section_id, subject_id, is_released, released_at, due_date (per-student override), allow_late_submission (per-student override), late_submission_override_reason, late_submission_override_by, late_submission_override_at, viewed_at, view_count, student_notified_at, parent_notified_at, reminder_sent_at, status_id, assigned_by
- Unique constraint: (homework_id, student_id) — one assignment per student per homework

**Policy:** HomeworkAssignmentTrackingPolicy (permission group: 	enant.home-work-assignment-tracking.*)

**Routes (under ssignments/ prefix):**
- GET /assignments — List all assignments (via index with tab filter)
- GET /assignments/{id} — View single assignment details
- POST /assignments/{id}/grade — Grade the submission linked to this assignment
- PATCH /assignments/{id}/status — Update assignment status inline
- PATCH /assignments/{id}/due-date — Override per-student due date
- PATCH /assignments/{id}/assign-date — Update assign date (only if not yet released)
- PATCH /assignments/{id}/toggle-release — Toggle release status for this assignment

**Tab Integration:** Included in the hub view as the homework_assignment tab, guarded by @can('tenant.home-work-assignment-tracking.viewAny').

---

## Who Can Access This Screen

| Role | What They Can Do | Permission Needed |
|------|-----------------|-------------------|
| Teacher | View assignments for their own homework, extend due dates, toggle release, send reminders, grade submissions | 	enant.home-work-assignment-tracking.* |
| School Admin | Same as Teacher, but for all homework across all classes and teachers | 	enant.home-work-assignment-tracking.* |

---

## How This Screen Works — Logic Flow (Non-Technical)

The teacher clicks on the Assignment Tracking tab. The system checks whether the user has permission to view this tab. If they do, the system queries the database for all assignment records. The query is smart — it only returns assignments that match the active filters (class, search term) and it loads related information like student name, homework title, and submission status in the same request so that the page renders quickly without multiple round trips to the database.

When the teacher changes a student's due date, the system first checks that the new date is later than the current date. If the check passes, the system updates the student's individual due date in the database and creates a notification record. If the check fails, the system returns an error message explaining why the date was rejected.

When the teacher toggles the release status, the system flips the is_released flag — if it was false, it becomes true (and vice versa). It also updates the timestamp and status accordingly. If the assignment was just released, the status changes from "Pending Release" to "Assigned", and a notification is created informing the student.

---

## Validate Before Save

| Action | Validation Rule | What Happens on Violation |
|--------|----------------|---------------------------|
| Extending due date | New date must be later than current due date | "Due date override must be later than the existing due date." — the system rejects the change |
| Changing assign date after release | Cannot change assign date once is_released = true | "Assign date cannot be changed after release." — the field is locked/read-only |
| Overriding late policy | A written reason is required | "Reason is required for late submission override." — the system prompts for a reason before saving |

---

## Error Handling and Validation Messages

| Scenario | What the User Sees | Type |
|----------|-------------------|------|
| Teacher enters a due date earlier than the current one | "Due date override must be later than the existing due date." | Validation |
| Teacher tries to change assign date on a released assignment | "Assign date cannot be changed after release." | Business Rule |
| Teacher overrides late policy without providing a reason | "Reason is required for late submission override." | Validation |
| User without permission tries to access this screen | "This action is unauthorized." | Authorization — HTTP 403 |

---

## Success Scenarios

**SC-001 — Extension Granted**
Priya was absent for a week. Mr. Patel changes her due date from 20 July to 25 July. The system accepts the change because the new date is later. Priya's assignment now shows the extended deadline, and she receives a notification about the extension.

**SC-002 — Assignment Manually Released**
A scheduled homework should have been released automatically but was not released for student Rahul. Mr. Patel clicks the Release Toggle. The system releases the assignment for Rahul immediately — he can now see it in his Student Portal — and sends a notification.

**SC-003 — Reminder Sent**
Three students have not submitted their homework. Mr. Patel selects them and clicks Send Reminder. The system records a reminder timestamp on each student's assignment and sends a notification. The students see the reminder when they log in.

---

## Failure Scenarios

**FC-001 — Invalid Extension Date**
Mr. Patel tries to give Vikram an extension by setting his due date to 18 July, but the current due date is 20 July (the new date is earlier). The system rejects the change with the error: "Due date override must be later than the existing due date." Mr. Patel sets the date to 23 July instead, and it is accepted.

**FC-002 — Change Assign Date After Release**
Mr. Patel tries to change the assign date on an assignment that was already released three days ago. The system rejects the change because the assignment has already been visible to the student. The field is locked.

**FC-003 — Unauthorized Access**
A teacher who has not been granted assignment tracking permission tries to access the tab. The tab is not visible to them (the system hides it), and if they try to navigate directly by URL, they receive a 403 error.

---

## Dependencies module and tables

| Module | Tables Used | Why |
|--------|-------------|-----|
| LmsHomework | lms_homework_assignment, lms_homework, lms_homework_submissions | Core assignment data linked to homework and submissions |
| SchoolSetup | sch_classes, sch_sections, sch_subjects | Class, section, and subject references for display and filtering |
| StudentProfile | std_students | Student name, admission number, and enrollment data |
| Prime | sys_dropdown_table, sys_users | Assignment status values and user tracking |
