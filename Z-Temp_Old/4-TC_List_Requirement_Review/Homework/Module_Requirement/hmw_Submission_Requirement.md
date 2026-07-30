# Homework Submission — Business Requirements

## What This Screen Does

The Homework Submission screen is where teachers manage everything related to student submissions. Think of it as the teacher's inbox for homework — every time a student submits their work, it appears here.

This screen serves two main purposes. First, it gives teachers a comprehensive, filterable list of all submissions across all homework. Instead of opening each homework separately to check submissions, the teacher can see everything in one place, filter by homework, student, status, or whether the work has been graded. Second, it provides the tools for teachers to grade submissions — entering marks, writing feedback, and deciding whether the student needs to redo the work.

This screen also handles special situations like late submissions (the system automatically detects and flags them), resubmissions (when a teacher asks a student to redo their work and the student submits again), and submissions made on behalf of students (when a teacher or admin submits for a student who could not do it themselves).

**How Students Interact with Submissions (Student Portal):**

Students do not use this screen directly. Instead, they use the Student Portal, which is a separate module. From the Student Portal, a student can:
- See a list of all homework assignments that have been released to them.
- Open an assignment to read the instructions and description.
- Type their answers into a text box (if the submission type is Text or Hybrid).
- Upload one or more files (if the submission type is File or Hybrid).
- Review their submitted work and see whether it has been graded.
- View their marks and teacher's feedback once the teacher has graded their submission.
- Resubmit their work if the teacher has requested a resubmission.

The submission data flows from the Student Portal into this Homework Submission screen. When a student submits via the portal, the submission record is created in the same database, and the teacher can see it here immediately.

---

## When This Screen Is Used

- **Reviewing All Submissions:** A teacher wants to see all submissions across all homework to check how many students have submitted and how many are pending grading.
- **Grading Submissions:** A teacher opens each submission to enter marks and provide written feedback.
- **Requesting Resubmissions:** A student's work is incomplete or incorrect. The teacher requests a resubmission, which allows the student to submit again.
- **Handling Late Submissions:** A student submitted after the due date. The system automatically flags it as late. The teacher can accept or reject the late submission based on school policy.
- **Submitting on Behalf of a Student:** A student was unable to access the Student Portal (for example, due to internet issues). The teacher or admin submits the work on their behalf.
- **Viewing a Student's Work:** A parent or teacher wants to see exactly what a student submitted — the text they wrote and the files they uploaded.
- **Bulk Download:** A teacher wants to download all submitted files for a homework as a single ZIP file for offline checking or record-keeping.
- **Managing Trashed Submissions:** A submission was accidentally created or is no longer needed and needs to be soft-deleted.

---

## Default Data Load

When a teacher navigates to the Homework Submission tab, the system loads all submission records in a paginated list showing 10 items per page. The list is ordered with the most recent submissions first. A filter bar at the top allows the teacher to narrow down results by:
- **Homework:** Select a specific homework to see only its submissions.
- **Student:** Search by student name or admission number.
- **Status:** Filter by submission status (Submitted, Under Review, Graded, Resubmit Requested, Rejected).
- **Late Flag:** Show only late or only on-time submissions.
- **Graded/Ungraded:** Show only submissions that have been graded or only those pending grading.
- **Active Status:** Show active or inactive (soft-deleted) submissions.

A search box lets the teacher type a student's name, admission number, email, or homework title to find specific submissions.

---

## Key Fields at a Glance

**Student Information**
Each submission record shows the student's full name and admission number, making it easy to identify who submitted the work.

**Homework Context**
The homework title, class, section, and subject are displayed so the teacher knows which homework this submission belongs to.

**Submission Content**
The actual work submitted by the student — either typed text or uploaded files (or both, depending on the submission type). The teacher can click to view the text in full or download the files.

**Submission Timing**
The date and time when the student submitted their work. If the submission was made after the due date, a red "Late" badge is shown next to the timestamp. The system automatically computes whether a submission is late by comparing the submission time against the student's effective due date (their individual due date if one was set, otherwise the homework's default due date).

**Resubmission Count**
If the teacher has asked the student to redo their work, the student's submission is marked as a resubmission. This counter shows how many times the student has resubmitted (0 for first-time submissions, 1 for the first resubmission, 2 for the second, etc.).

**Status**
The current state of the submission:
- **Submitted** (blue) — The student has submitted their work. It is awaiting review.
- **Under Review** (amber) — The teacher is currently reviewing the submission.
- **Graded** (green) — The teacher has entered marks and feedback.
- **Resubmit Requested** (orange) — The teacher has asked the student to redo their work.
- **Rejected** (red) — The submission was rejected (for example, it was inappropriate or not legible).

**Grading Information**
If the submission has been graded, the marks obtained are displayed as a fraction (e.g., "15/20 — Pass"). The teacher's written feedback is shown below the marks. The date and time of grading, as well as who graded it, are recorded for audit purposes.

**Actions**
Each submission row has action buttons: View (to see full details), Edit (to modify the submission on behalf of the student), Review/Grade (to enter marks and feedback), and Delete (to soft-delete the submission).

---

## Business Rules and Conditions

**Submissions Must Have Content**
A submission must contain at least some text in the answer box OR at least one uploaded file. A completely empty submission is rejected. This prevents students from "submitting" blank work.

**One Submission Per Assignment (Unless Resubmission is Requested)**
A student can only submit once for each assignment. If they try to submit again, the system rejects it. The only exception is when the teacher has explicitly requested a resubmission — in that case, the student can submit again, and the system increments the resubmission counter.

**Late Detection Is Automatic**
The system automatically determines whether a submission is late by comparing the submission time against the effective due date. The effective due date is either the student's individual due date (if the teacher set one) or the homework's default due date. If the submission time is after the effective due date, the submission is automatically flagged as late — no manual action is needed.

**Late Policy Enforcement (Known Gap)**
The homework has a setting called "Allow Late Submission." When this is set to "No," the system should ideally block any submission made after the due date. However, in the current version, this hard block is not yet implemented — late submissions are flagged but not prevented. This is a known gap that is scheduled to be fixed.

**Marks Have Upper and Lower Limits**
When grading, the marks entered must be between 0 and the homework's maximum marks. A teacher cannot enter negative marks or marks higher than the maximum. For example, if the maximum marks is 20, the teacher can enter any value from 0 to 20.

**Grading Creates an Audit Trail**
When a teacher grades a submission, the system records who graded it and when. This creates an audit trail so that administrators can see which teacher graded which submission and when the grading happened.

**Resubmissions Reset the Timeline**
When a teacher requests a resubmission and the student submits again, the system increments the resubmission count, refreshes the submission timestamp, and re-evaluates the late flag. This means if the original submission was on time but the resubmission is late, the resubmission will be flagged as late.

**Score Publishing**
If the homework has "Auto-Publish Score" turned on, the marks become visible to the student immediately after grading. If it is turned off, the marks are hidden from the student until the teacher manually publishes them.

---

## Workflow Steps

**Viewing the Submissions List**
The teacher navigates to the Homework Submission tab. All submissions are displayed in a paginated list. The teacher can use the filter bar to narrow down the view — for example, selecting a specific homework to see only its submissions, or selecting "Ungraded" to see only submissions that need grading.

**Viewing a Submission in Detail**
The teacher clicks the View button next to a submission. A detailed view opens showing the student's submitted text (with formatting preserved), any uploaded files (with download links), the submission timestamp, late flag, and current status. If the submission has been graded, the marks and feedback are also displayed.

**Grading a Submission**
The teacher clicks the Review/Grade button. A grading form opens where the teacher can:
1. View the student's submitted work.
2. Enter marks (the system shows the maximum marks as a reference).
3. Type written feedback for the student.
4. Select the new status (Graded, Resubmit Requested, or Rejected).
5. Click Save to finalize the grade.

The system validates that the marks are within the allowed range (0 to maximum marks). If valid, the submission is saved with the teacher's name and the current timestamp recorded as the grading time.

**Requesting a Resubmission**
If a student's work is incomplete, incorrect, or needs improvement, the teacher can request a resubmission. Instead of grading the work as-is, the teacher sets the status to "Resubmit Requested" and optionally adds feedback explaining what needs to be improved. The student sees this status on their Student Portal and can submit updated work. When they do, the system creates a new version (not a new record) — it increments the resubmission count and refreshes the submission timestamp.

**Submitting on Behalf of a Student**
If a student cannot submit through the Student Portal, the teacher or admin can click "Add Submission" and manually create a submission for that student. They select the student and the homework, enter the text or upload files on the student's behalf, and save. The system records the submission as if the student submitted it themselves (the student is still recorded as the submitter).

**Bulk Downloading Submissions**
The teacher clicks the "Download All" button. The system compiles all submitted files for the selected homework into a single ZIP file, with each file named after the student who submitted it. The teacher downloads the ZIP to their computer for offline review.

---

## Example Scenario

**Scenario: A Full Submission Lifecycle**

Ms. Sharma published a homework on "Chemical Reactions" with a due date of 22 July. Over the next week, 30 of her 35 students submitted their work through the Student Portal.

**Day 1-5 (Submission Period):**
- Ravi submits on 18 July. The system records his submission with a timestamp of 18 July and flags it as "On Time" (since 18 July is before the 22 July due date).
- Anika submits on 23 July. The system records her submission with a timestamp of 23 July and automatically flags it as "Late" (since 23 July is after the 22 July due date).
- Vikram tries to submit twice on the same day. The second attempt is rejected because he already has a submission.

**Day 6 (Teacher Reviews and Grades):**
Ms. Sharma opens the Submission tab and filters by "Ungraded" to see all 30 submissions that need grading. She works through them one by one:
- For Ravi's submission, she reads his answers, enters 18 out of 20 marks, types "Excellent work — clearly explained all reaction types," and sets status to Graded. Since auto-publish is on, Ravi sees his score immediately.
- For Anika's late submission, she reads the work, enters 15 out of 20 marks, notes in the feedback "Good effort, but you lost marks for late submission — please submit on time next time," and grades it.
- For one student whose answer is incomplete, she sets the status to "Resubmit Requested" and types "Please complete questions 3, 4, and 5 — you only answered 1 and 2."

**What the Student Sees (Student Portal):**

Ravi logs in and sees his grade: "18/20 — Excellent work!" with Ms. Sharma's feedback.

Anika logs in and sees her grade: "15/20" with a note about late submission.

The student who was asked to resubmit logs in and sees a notification: "Your teacher has requested a resubmission for 'Chemical Reactions.' Please review the feedback and submit again." He sees the teacher's feedback, redoes the incomplete questions, and submits again. This time, the system shows "Resubmission #1" on his record.

---

## Related Screens

- **Homework Management** — Where the homework was created and published.
- **Assignment Tracking** — Shows per-student assignment records linked to these submissions.
- **Paper Check** — An alternative unified workspace for grading all submissions for a single homework.
- **Homework Submission (Student Portal)** — Where students actually submit their work (separate module).

---

## Requirements

**Controller:** Modules\LmsHomework\Http\Controllers\HomeworkSubmissionController
- Methods: index(), create(), store(), show(), edit(), update(), destroy(), 	rashed(), estore(), orceDelete(), 	oggleStatus(), eview(), ulkDownload()

**Model:** Modules\LmsHomework\Models\HomeworkSubmission (table: lms_homework_submissions)
- Traits: SoftDeletes, HasFactory, InteractsWithMedia (Spatie), SanitizesRichText
- Key fields: assignment_id (UNIQUE), homework_id, student_id, submission_text (LONGTEXT), sub_attachment_media_id (JSON), submitted_at, is_late, resubmission_count (TINYINT), status_id, is_resubmission_requested, marks_obtained (DECIMAL 5,2), teacher_feedback, graded_by, graded_at, score_published_at

**Form Requests:**
- HomeworkSubmissionRequest — Validates text or file required, assignment uniqueness, marks constraints, file types/sizes. Authorization: 	enant.home-work-submission.create or .update.
- HomeworkReviewRequest — Validates marks <= homework.max_marks, teacher_feedback max 2000 chars. Authorization: 	enant.home-work.update.

**Policy:** HomeworkSubmissionPolicy (permission group: 	enant.home-work-submission.*)

**Routes (under lms-home-work prefix):**
- Resource route homework-submission (full CRUD) + extra routes for 	rash/view, estore, orce-delete, 	oggle-status, eview/{id}, download-bulk/{homework_id}

**Tab Integration:** Included in the hub view as the home_work_submission tab, guarded by @can('tenant.home-work-submission.viewAny').

---

## Who Can Access This Screen

| Role | What They Can Do | Permission Needed |
|------|-----------------|-------------------|
| Teacher | View all submissions for their homework, grade, request resubmissions, submit on behalf of students, bulk download | 	enant.home-work-submission.* |
| School Admin | Same as Teacher, for all submissions across all homework | 	enant.home-work-submission.* |
| Student | Submit their own work, view grades/feedback (via Student Portal — separate module) | (handled by Student Portal) |

---

## How This Screen Works — Logic Flow (Non-Technical)

**Viewing Submissions:** The teacher clicks the Homework Submission tab. The system checks permission, then queries the database for all submission records that match the active filters. The query is efficient — it loads the student name, homework title, and status information in the same request so the page renders quickly.

**Grading a Submission:** The teacher clicks Review/Grade on a submission. The grading form loads with the submission details and a reference to the homework's maximum marks. The teacher enters marks and feedback. When they click Save, the system checks that the marks are between 0 and the maximum. If the check passes, the system updates the submission record with the marks, feedback, the teacher's user ID, and the current timestamp. If the homework has auto-publish enabled, the system also stamps the "score published" timestamp so the student can see their grade immediately. If the check fails, the system returns an error message.

**Requesting a Resubmission:** The teacher sets the status to "Resubmit Requested" and provides feedback. The system updates the submission status and sets a flag indicating that a resubmission has been requested. When the student submits again (via Student Portal), the system detects this flag, increments the resubmission counter, and allows the new submission to replace the previous one.

**Late Detection:** When any submission is created (whether by the student via the portal or by a teacher on their behalf), the system compares the submission timestamp against the effective due date. If the submission time is after the due date, the is_late flag is set to 	rue. This happens automatically — no manual intervention is needed.

---

## Validate Before Save

| Action | Validation Rule | What Happens on Violation |
|--------|----------------|---------------------------|
| Creating a submission | Submission must contain text OR at least one file (not both empty) | "Submission must contain text or a file." — the form is not submitted |
| Creating a submission | Only one submission per assignment (no duplicate) | "A submission for this assignment already exists." — unless resubmission was requested |
| Grading a submission | Marks must be between 0 and the homework's maximum marks | "Marks cannot exceed maximum marks of [value]." |
| Grading a submission | Teacher feedback must be 2000 characters or less | "Feedback is too long (max 2000 characters)." |
| Uploading files | Each file must be an allowed type: pdf, doc, docx, txt, jpg, jpeg, png, zip | "File must be of type: pdf, doc, docx, txt, jpg, jpeg, png, zip." |
| Uploading files | Each file must be 10 MB or smaller | "File may not be greater than 10240 kilobytes." |

---

## Error Handling and Validation Messages

| Scenario | What the User Sees | Type |
|----------|-------------------|------|
| Student submits empty work (no text, no file) | "Submission must contain text or a file." | Validation |
| Student tries to submit twice (no resubmission) | "A submission for this assignment already exists." | Concurrency |
| Teacher enters marks higher than maximum | "Marks cannot exceed maximum marks." | Validation |
| Teacher writes very long feedback | "Feedback is too long (max 2000 characters)." | Validation |
| Teacher uploads an invalid file type | "File must be of type: pdf, doc, docx, txt, jpg, jpeg, png, zip." | Validation |
| Teacher uploads a file larger than 10 MB | "File may not be greater than 10240 kilobytes." | Validation |
| User without permission tries to grade | "This action is unauthorized." | Authorization — HTTP 403 |
| No files exist for bulk download | "No submission files found for this homework." | Notice — HTTP 404 |

---

## Success Scenarios

**SC-001 — Student Submits On Time**
Ravi opens his homework assignment on the Student Portal. He types his answers into the text box and clicks Submit. The system creates a submission record with the current timestamp. Since the submission time (18 July) is before the due date (22 July), the system sets the late flag to "No." Ravi sees a confirmation: "Your homework has been submitted successfully."

**SC-002 — Teacher Grades a Submission**
Ms. Sharma opens Ravi's submission, reads his answers, enters 18 out of 20 marks, types "Excellent work," and clicks Save. The system saves the marks, records her name as the grader, stamps the current time as the grading time, and — since auto-publish is on — makes the score visible to Ravi immediately.

**SC-003 — Resubmission Requested and Completed**
Ms. Sharma reviews a student's incomplete submission. She sets the status to "Resubmit Requested" with feedback: "Please complete questions 3, 4, and 5." The student sees this on their portal, redoes the work, and submits again. The system increments the resubmission count to 1 and refreshes the submission timestamp.

**SC-004 — Bulk Download Successful**
Ms. Sharma clicks "Download All" for her Chemical Reactions homework. The system compiles all 30 submitted files into a ZIP archive named "Chemical_Reactions_Submissions.zip" with each file named after the student. The ZIP downloads to her computer.

---

## Failure Scenarios

**FC-001 — Empty Submission Rejected**
Anika accidentally clicks Submit without typing anything or attaching a file. The system rejects the submission with the error: "Submission must contain text or a file." Anika adds her answers and submits successfully.

**FC-002 — Duplicate Submission Rejected**
Vikram submits his homework on Monday. On Tuesday, he tries to submit again (thinking his first attempt failed). The system rejects the second submission because a submission for his assignment already exists. He is advised to contact his teacher if he needs to resubmit.

**FC-003 — Marks Exceed Maximum**
Mr. Patel tries to enter 25 marks for a homework that has a maximum of 20. The system rejects the entry with: "Marks cannot exceed maximum marks." He corrects it to 18 and saves successfully.

**FC-004 — Unauthorized Grading Attempt**
A teacher who has not been granted grading permission tries to access the review form. The system returns a 403 Forbidden page.

---

## Dependencies module and tables

| Module | Tables Used | Why |
|--------|-------------|-----|
| LmsHomework | lms_homework_submissions, lms_homework_assignment, lms_homework | Core submission, assignment, and homework data |
| SchoolSetup | sch_classes, sch_sections, sch_subjects | Class/section/subject references for display |
| StudentProfile | std_students | Student name, admission number, and enrollment data |
| Prime | sys_dropdown_table (submission statuses), sys_users (graded_by), sys_media (Spatie file storage) | Dropdown values, user tracking, and file storage |
