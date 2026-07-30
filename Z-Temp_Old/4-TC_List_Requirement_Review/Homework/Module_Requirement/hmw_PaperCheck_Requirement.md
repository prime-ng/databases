# Paper Check — Business Requirements

## What This Screen Does

The Paper Check screen is a dedicated workspace designed for one specific task: grading all student submissions for a single homework, all in one place. Think of it as a teacher's grading desk where all the answer scripts for one exam are laid out, ready to be checked.

Unlike the Submission tab (which lists submissions across multiple homework), Paper Check focuses on one homework at a time. It shows every student who was assigned this homework, whether they have submitted or not, and provides inline tools for the teacher to view each student's submitted work, enter marks, write feedback, and upload annotated copies of the submitted files.

The screen gets its name from the traditional practice of "paper checking" — a teacher sitting at their desk with a stack of answer sheets, reading each one, marking it, and writing comments. This screen brings that entire workflow into a digital workspace.

---

## When This Screen Is Used

- **End-of-Homework Grading Session:** A teacher has collected all submissions for a homework and sits down to grade them all at once.
- **Focused Grading:** A teacher wants to grade only the submissions for a specific homework without being distracted by submissions for other homework.
- **Annotated Feedback:** A teacher wants to download a student's submitted file, add comments or corrections to it, and upload the annotated version back as feedback.
- **Re-Checking:** A teacher realizes they made an error while grading a submission. They unlock the submission (re-check), correct the marks, and re-finalize.
- **Batch Processing:** A teacher wants to quickly go through all submissions one by one, grading each in sequence without navigating back and forth between screens.

---

## Default Data Load

When a teacher opens Paper Check for a specific homework, the system loads the homework details (title, subject, class, section, topic) at the top of the page as context. Below that, it loads a complete list of all students who were assigned this homework, regardless of whether they have submitted. Each student row shows: student name and admission number, submission status, submission timestamp, whether it is late, and links to view/download their submitted files.

For students who have not submitted yet, the row shows a "Not Submitted" status. For students who have submitted and been graded, the current marks and feedback are shown. This gives the teacher a complete picture of the homework's progress in one glance.

All data is loaded in a single page request — the homework details, all assignments, and all related submissions are fetched together so the page loads quickly without multiple round trips.

---

## Key Fields at a Glance

**Homework Context Banner**
The top of the page shows the homework title, subject, class/section, and topic. This serves as a reminder of what the teacher is grading.

**Student Roster**
Every student who was assigned this homework is listed in a table. Each row represents one student. The table is ordered by student ID for consistency.

**Submission Status**
For each student, the current status of their submission is shown as a colour-coded badge:
- **Not Submitted** (grey) — The student has not submitted any work yet.
- **Submitted** (blue) — The student has submitted and is awaiting grading.
- **Under Review** (amber) — A teacher has opened the submission and is reviewing it.
- **Graded** (green) — The submission has been graded and finalized.
- **Resubmit Requested** (orange) — A resubmission was requested (student needs to resubmit).

**Submission Files**
If the student submitted files, they appear as clickable links. The teacher can click to view or download each file. For text-only submissions, the text content is displayed.

**Marks and Feedback**
For submissions that have been graded, the marks obtained and the teacher's feedback are displayed. If not yet graded, empty input fields are shown for the teacher to fill in.

**Annotated File Upload**
An option to upload an annotated version of the student's file. For example, the teacher can download the student's PDF, add handwritten comments or corrections using a PDF editor, and upload the marked-up version back. This annotated file replaces the original in the submission record and is visible to the student.

**Finalize and Re-check Buttons**
- **Finalize:** Locks the grading — the submission is marked as Graded, and the student can see their marks and feedback (depending on auto-publish settings).
- **Re-check:** Unlocks a previously graded submission — clears the marks and feedback so the teacher can re-grade it.

---

## Business Rules and Conditions

**Marks Must Be Within Range**
As with the Submission tab, marks entered in Paper Check must be between 0 and the homework's maximum marks. The teacher cannot enter a negative score or a score higher than the maximum.

**Grading Is Audited**
Every time a submission is graded or re-graded, the system records who graded it and when. This creates a complete audit trail of the grading process.

**Finalize Locks the Grade**
When a teacher clicks Finalize, the submission status changes to Graded, and the grade is locked. The teacher cannot accidentally change it — they must explicitly click Re-check to unlock it first. This prevents accidental modifications during the grading session.

**Re-check Clears Grade Data**
When a teacher clicks Re-check on a graded submission, the system clears the marks, feedback, grader name, and grading timestamp. The submission is returned to an "Under Review" state, allowing the teacher to re-enter the grade from scratch.

**Auto-Publish Controls Score Visibility**
If the homework's "Auto-Publish Score" setting is enabled, the score is immediately visible to the student when the teacher clicks Finalize. If disabled, the student cannot see their score until the teacher manually publishes it from the Submission tab.

**Annotated Files Are Optional**
The teacher is not required to upload an annotated file. They can grade a submission using just marks and text feedback, without any file annotation.

---

## Workflow Steps

**Opening Paper Check**
From the Homework Management list, the teacher clicks the Paper Check button (or navigates directly to the Paper Check URL for a specific homework). The system loads the grading workspace with all students listed.

**Grading a Submission**
1. The teacher finds the student in the list and clicks on their row to expand the grading panel.
2. The system loads the student's submitted text and files.
3. The teacher reads the submission, enters marks in the "Marks Obtained" field, and types feedback in the "Teacher Feedback" box.
4. Optionally, the teacher downloads the student's file, annotates it using an external tool, and uploads the annotated version.
5. The teacher clicks "Save" to save the grade without finalizing, or "Finalize" to lock the grade.
6. The system validates the marks, saves the grade, and updates the submission status.

**Finalizing a Grade**
When the teacher is satisfied with the marks and feedback, they click Finalize. The system sets the submission status to Graded, records the grader's name and current timestamp, and — if auto-publish is on — makes the score visible to the student. The row in the table updates to show the green "Graded" badge.

**Re-checking a Grade**
If the teacher realizes they made a mistake after finalizing, they click the Re-check button on that student's row. The system prompts for confirmation ("Re-check will clear the existing grade. Continue?"). On confirmation, the system clears the marks, feedback, grader, and grading timestamp. The submission status returns to "Under Review," and the teacher can re-enter the correct grade.

**Using the Annotated File Feature**
1. The teacher downloads the student's submitted file from the Paper Check screen.
2. The teacher opens the file in a PDF editor or annotation tool.
3. The teacher adds comments, corrections, or marks directly on the file.
4. The teacher uploads the annotated file back to the Paper Check screen.
5. The system stores the annotated file as a teacher-feedback file, linked to the submission. The student can view this annotated file in their Student Portal.

---

## Example Scenario

**Scenario: Full Homework Grading Session**

Mr. Patel has 30 submissions for his "Quadratic Equations" homework. He opens the Paper Check screen and sees all 30 students listed. He decides to grade them in batches of 10.

**Batch 1 (First 10 submissions):**
He opens each student's submission one by one. For each, he reads their answers, enters marks (out of 20), types a brief feedback comment, and clicks Save. He does not Finalize yet — he wants to review all grades before locking them.

**Batch 2 (Next 10 submissions):**
He continues grading. For one student whose work is exceptional, he enters 20/20 and types "Perfect score — excellent understanding!" For another student whose work is weak, he enters 8/20 and types "Please review Chapter 3 and practice more problems."

**Batch 3 (Final 10 submissions):**
He finishes grading all 30 submissions.

**Finalization:**
Mr. Patel reviews his grades one more time to ensure consistency. Satisfied, he selects all 30 submissions and clicks Finalize All. The system locks all grades, stamps the current time as the grading time, and — since auto-publish is on — makes all scores visible to students immediately.

**Annotated File Example:**
For one student who made a specific error in their calculation, Mr. Patel downloads the student's submitted PDF, opens it in a PDF editor, circles the error and writes "Check your sign here — it should be -b, not +b," saves the annotated PDF, and uploads it back to the Paper Check screen. The student can see the annotated file with the specific correction marked.

**What the Student Sees (Student Portal):**

When Ravi logs into his Student Portal after grading, he sees:
- His score: "18/20"
- Teacher's feedback: "Good work — you understood the quadratic formula well. Practice more word problems."
- The annotated file: He can open the PDF and see his teacher's corrections circled in red.

---

## Related Screens

- **Homework Management** — The list where the Paper Check button is located for each homework.
- **Homework Submission Tab** — An alternative list-based view of submissions across all homework.
- **Assignment Tracking** — Shows per-student assignment status; grades entered in Paper Check update the assignment status here.

---

## Requirements

**Controller:** Modules\LmsHomework\Http\Controllers\LmsHomeworkController
- Methods: paperCheck() — Loads the grading workspace for a specific homework
- getCheckData(, ) — Returns submission details as JSON for dynamic loading
- getSubmissionFiles(, ) — Returns file URLs for student's submission
- saveCheck() — Saves marks, feedback, and annotated file for a submission

**Models:**
- Homework (lms_homework) — Loaded with subject, class, section, topic for context banner
- HomeworkAssignment (lms_homework_assignment) — Loaded with student, submission, and status for the roster
- HomeworkSubmission (lms_homework_submissions) — Contains marks, feedback, files, and grading data

**Policy:** HomeworkPolicy (permission group: 	enant.home-work.* — viewAny for access, update for grading)

**Routes (under lms-home-work prefix):**
- GET /home-works/{id}/paper-check — Load the Paper Check workspace
- GET /home-works/{homeworkId}/check-data/{submissionId} — AJAX endpoint for submission details
- GET /home-works/{homeworkId}/get-files/{studentId} — AJAX endpoint for file URLs
- POST /home-works/check/save/{submissionId} — AJAX endpoint to save grading data

**Views:**
- paper-check/index.blade.php — The main grading workspace (514 lines)
- paper-check/evaluator-js.blade.php — Inline JavaScript for dynamic grading interactions

---

## Who Can Access This Screen

| Role | What They Can Do | Permission Needed |
|------|-----------------|-------------------|
| Teacher | Grade submissions for their own homework, annotate files, finalize/re-check | 	enant.home-work.viewAny (access) + 	enant.home-work.update (grading) |
| School Admin | Grade submissions for any homework | 	enant.home-work.viewAny + 	enant.home-work.update |

---

## How This Screen Works — Logic Flow (Non-Technical)

The teacher navigates to the Paper Check screen for a specific homework. The system loads the homework details and all student assignments in one database query. For each student, it checks whether a submission exists. If it does, the submission data (text, files, current marks, feedback) is loaded. If it does not, the student is shown with a "Not Submitted" status.

When the teacher saves a grade, the system sends the data to the server via an AJAX call (the page does not reload). The server validates that the marks are within the allowed range. If valid, it updates the submission record with the new marks and feedback. The server responds with a success message, and the page updates the student's row to show the new grade — all without a full page reload.

When the teacher clicks Finalize, the system locks the grade by setting the submission status to Graded and recording the timestamp. The student can now see their grade in the Student Portal (if auto-publish is on). If the teacher later clicks Re-check, the system clears the grade data and returns the submission to an unlocked state.

---

## Validate Before Save

| Field | Validation Rule | What Happens on Violation |
|-------|----------------|---------------------------|
| Marks Obtained | Must be between 0 and the homework's maximum marks | "Marks cannot exceed maximum marks of [value]." |
| Teacher Feedback | Must be 2000 characters or fewer | "Feedback is too long (max 2000 characters)." |
| Annotated File Upload | Allowed types: pdf, doc, docx, txt, jpg, jpeg, png. Max size: 10 MB | "Invalid file type or size exceeds 10MB." |

---

## Error Handling and Validation Messages

| Scenario | What the User Sees | Type |
|----------|-------------------|------|
| Teacher enters marks exceeding the maximum | "Marks cannot exceed maximum marks." | Validation |
| Teacher uploads an invalid file as annotation | "File must be of type: pdf, doc, docx, txt, jpg, jpeg, png." | Validation |
| Teacher uploads a very large annotation file | "File may not be greater than 10240 kilobytes." | Validation |
| The save operation fails due to a server error | "Failed to save check. Please try again." | Server Error — HTTP 500 |
| User without permission tries to access | "This action is unauthorized." | Authorization — HTTP 403 |

---

## Success Scenarios

**SC-001 — Submission Graded Successfully**
Mr. Patel opens a student's submission, enters 15/20 marks, types feedback, and clicks Save. The system saves the grade via AJAX, and the student's row updates to show the new score. The student can see their grade in the Student Portal.

**SC-002 — Grade Finalized and Published**
After saving grades for all 30 submissions, Mr. Patel clicks Finalize. All submission statuses change to Graded, and scores become visible to students immediately (auto-publish is on).

**SC-003 — Re-check After Error**
Mr. Patel realizes he entered 18 marks for a student who deserved 15. He clicks Re-check, confirms, and the system clears the grade. He re-enters 15, saves, and finalizes again.

**SC-004 — Annotated File Uploaded**
Mr. Patel downloads a student's PDF, adds comments using a PDF editor, uploads the annotated version. The file is stored as teacher-feedback and is visible to the student.

---

## Failure Scenarios

**FC-001 — Marks Out of Range**
Mr. Patel accidentally enters 25 marks for a homework with a maximum of 20. The system rejects the entry with "Marks cannot exceed maximum marks." He corrects it to 18 and saves successfully.

**FC-002 — Unauthorized Access**
A teacher without grading permission tries to access Paper Check. The system returns a 403 Forbidden page.

---

## Dependencies module and tables

| Module | Tables Used | Why |
|--------|-------------|-----|
| LmsHomework | lms_homework, lms_homework_assignment, lms_homework_submissions | Core homework and submission data |
| SchoolSetup | sch_classes, sch_sections, sch_subjects | Context display (class, section, subject names) |
| StudentProfile | std_students | Student details for the roster |
| Prime | sys_users | Recording who graded each submission |
