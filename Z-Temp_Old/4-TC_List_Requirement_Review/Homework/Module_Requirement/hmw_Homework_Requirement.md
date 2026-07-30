# Homework Management — Business Requirements

## What This Screen Does

The Homework Management screen is the central workspace where teachers create, publish, and manage all homework assignments for their classes. Think of it as the teacher's command centre for homework — they can see every homework they have ever created in one scrollable list, check whether each one is still a draft or has been published to students, and take actions like editing, cloning, or removing homework.

When a teacher creates a homework here, they are essentially defining a task: what the homework is about (title and description), which class and subject it is for, when students should start working on it (assign date) and when it must be submitted (due date), whether it carries marks (gradable), how difficult it is, and when it should become visible to students (immediately, on a specific date, or when a topic is completed in class). The teacher can also attach reference files such as worksheets or scanned question papers.

This screen is also where homework moves from being a draft (only the teacher can see it) to being published (every student gets their own copy). Once published, the system automatically creates one assignment record for every student enrolled in that class. The teacher does not need to manually distribute anything.

---

## When This Screen Is Used

- **Start of a New Topic:** A teacher has just finished teaching a chapter and wants to assign practice homework to reinforce the concepts.
- **Weekly Planning:** A teacher plans all homework for the upcoming week and sets them up with scheduled release dates so they appear to students automatically.
- **Across Sections:** A teacher teaches the same subject to Class 8-A and Class 8-B. Instead of creating the same homework twice, they create it once and clone it to the other section.
- **Review and Tracking:** A teacher wants to see all homework they have assigned, check which ones are still in draft status and need publishing, and verify due dates for the coming week.
- **Administrative Oversight:** The Principal or Academic Coordinator wants to review the homework load across classes and subjects to ensure it is balanced.

---

## Default Data Load

When a teacher navigates to the Homework tab, the system loads the most recent homework entries in a paginated list showing 10 items per page. The list is ordered with the newest homework at the top. A filter bar is displayed above the table allowing the teacher to narrow down results by Class, Section, Subject, Date Range, and Active/Inactive status. A search box lets them type a homework title or description to find specific items. The system also loads dropdown lists of all active Classes, Sections, and Subjects so the filter controls are populated and ready to use.

---

## Key Fields at a Glance

**Homework Identity**
Every homework has a title — a short, descriptive name such as "Chapter 5: Chemical Reactions" that appears as the primary identifier in the list. Below the title, if the teacher linked the homework to a specific syllabus topic, the topic name is shown in smaller text. This helps teachers quickly identify what each homework covers without opening it.

**Target Group**
Each homework is tied to a specific Class (e.g., Grade 8) and Subject (e.g., Science). Optionally, the teacher can select a specific Section (e.g., Section A) — if no section is selected, the homework applies to all sections of that class. This information is displayed in the table using colour-coded badges: blue for the class name and grey for the subject name.

**Schedule Window**
Two dates define the homework timeline: the Assign Date (when students should start working on it) and the Due Date (the last date for submission). These are displayed in a compact two-line format in the table. The system enforces that the due date must always be after the assign date — a homework cannot be due before it is assigned.

**Grading Information**
If the homework carries marks (gradable), the table shows the maximum marks and passing marks. For example, "Max: 20, Pass: 10" tells the teacher at a glance what the grading criteria are. If the homework is not gradable (completion-based only), the table shows a "Not Gradable" badge.

**Release Condition**
This tells the teacher how and when the homework becomes visible to students. A green "Immediate" badge means students can see it as soon as it is published. An amber "On Topic Done" badge means it will only appear when the teacher marks the linked syllabus topic as complete. A blue "Scheduled Date" badge means it will appear automatically on the chosen release date. Next to this, a badge shows whether the homework is currently a "Draft" (only teacher can see) or "Published" (students can see according to the release condition).

**Status and Actions**
Each row has an active/inactive toggle switch that lets the teacher temporarily disable a homework without deleting it. Three action buttons appear at the end of each row: a Clone button (to copy this homework to another section), a View button (to see full details), an Edit button (to make changes), and a Delete button (to move it to the trash). These buttons are only shown if the user has the necessary permission.

---

## Business Rules and Conditions

**Draft-Only Editing**
A homework can only be edited while it is in Draft status. Once it is published, the edit button is hidden. This prevents accidental changes to homework that students are already working on. If a teacher needs to change a published homework, they would need to create a new version or use per-student overrides in the Assignment Tracking screen.

**Publishing Creates Student Records**
When a teacher publishes a homework, the system creates one individual assignment record for every student who is actively enrolled in the target class (and section, if specified). For a class of 40 students, publishing creates 40 assignment records. This is a one-time bulk operation — the teacher does not need to assign homework to each student manually.

**Safe Re-Publishing**
If a teacher accidentally clicks Publish twice, or if new students join the class after publishing, clicking Publish again is completely safe. The system does not create duplicate records — it simply updates the existing assignment records for the students who already have them, and creates new ones only for students who do not.

**Homework Cannot Be Deleted If Students Have Submitted**
A teacher cannot delete a homework if even one student has already submitted their work for it. This prevents accidental loss of student submissions and grading data. The teacher must first delete the submissions or wait until the homework is complete before removing it.

**Three Ways to Release Homework**
Teachers can choose when homework becomes visible to students:
- **Immediately:** Visible the moment the teacher clicks Publish.
- **On a Scheduled Date:** Visible automatically on a future date and time set by the teacher. This is useful for homework that should appear at the start of the next week.
- **On Topic Completion:** Visible only when the teacher marks the linked syllabus topic as complete in the Syllabus module. This is useful for homework that should only be accessible after the teacher finishes teaching the related topic in class.

**Clone Creates a Fresh Draft**
Cloning a homework copies all its details (title, description, marks, attachments, etc.) to a new homework for a different section of the same class. The clone is always created as a Draft, giving the teacher a chance to review and customize it before publishing. The original homework is not affected in any way.

**Tenant Isolation**
All homework data belongs to one school (tenant). A teacher from School A can never see homework from School B, even if they somehow guess the URL. This is enforced at the database level — each school has its own set of tables.

---

## Workflow Steps

**Viewing the Homework List**
The teacher navigates to the LMS section and selects the Homework tab. The system displays the most recent homework entries. If there are many homework records, the teacher can use the filter bar at the top to narrow down the list — for example, selecting Class 8 from the dropdown and typing "Chemical" in the search box to find all homework about chemical reactions. The teacher can also use the date range picker to see homework created between specific dates.

**Creating a New Homework**
The teacher clicks the "Add Homework" button at the top of the list. A form page opens with several sections. First, the teacher selects the Academic Year (auto-set to the current year), then the Class (e.g., Grade 8). Based on the class selection, the system loads the available Sections and Subjects via AJAX — the teacher does not need to search for them. The teacher optionally selects a Lesson and Topic from the Syllabus to align the homework to the curriculum, which helps in tracking syllabus coverage. The teacher enters a Title and a Description (rich text is supported, allowing formatting like bold, bullet points, etc.). They select a Submission Type — Text (students type their answer), File (students upload a document), or Hybrid (both text and file are accepted). If the homework is gradable, the teacher checks the "Gradable" box and enters Maximum Marks (e.g., 20) and Passing Marks (e.g., 10). The system validates that passing marks cannot exceed maximum marks. The teacher selects a Difficulty Level (Easy, Medium, or Hard — from the Syllabus module). They set the Assign Date (when students should start) and Due Date (the deadline), and choose whether Late Submission is allowed. They select the Release Condition (Immediate, Scheduled Date, or On Topic Completion). If Scheduled Date is chosen, a date picker appears for the release date. The teacher can attach reference files such as a worksheet PDF or an image. Finally, they click Save. The homework is saved as a Draft and appears in the list.

**Editing a Draft Homework**
The teacher clicks the Edit button (pencil icon) on any homework that is still in Draft status. The edit form opens with all previously saved values pre-populated — the teacher can change any field, add or remove attachments, and save again. The system validates all fields as it did during creation.

**Publishing a Homework**
When the teacher is ready to make the homework available to students, they click the Publish button on a Draft homework. A confirmation dialog appears: "Publish Homework? This will create assignments for all enrolled students and cannot be undone." If the teacher confirms, the system processes the request in the background — it looks up all active students enrolled in the target class (and section, if specified), creates an assignment record for each student, updates the homework status from Draft to Published, and displays a success message showing the number of assignments created.

**Cloning a Homework**
If the teacher teaches the same subject to multiple sections of the same class, they can clone an existing homework instead of creating it from scratch. They click the Clone button on the homework they want to copy. A modal dialog opens showing a dropdown of available sections (only sections of the same class are listed, and the current section is excluded). The teacher selects the target section and clicks Clone. The system creates a new Draft homework with all the same details and attachments, linked to the selected section. The teacher can then edit and publish it independently.

**Toggling Active/Inactive Status**
If a teacher wants to temporarily hide a homework without deleting it, they can use the status toggle switch. Clicking the switch changes the homework's active status immediately via AJAX — the page does not reload. The change is reflected in the list right away.

**Viewing Homework Details**
The teacher clicks the View button (eye icon) on any homework to see its full details on a read-only page. This shows all the information — title, description, class, subject, dates, marks, attachments, release condition, and a timeline of activity (who created it and when).

**Deleting (Trashing) a Homework**
The teacher clicks the Delete button (trash icon) on a homework. The system first checks whether any student has submitted work for this homework. If submissions exist, the deletion is blocked with an error message. If no submissions exist, the homework is soft-deleted — it disappears from the active list but can be restored later from the Trash page.

---

## Example Scenario

**Scenario: End-of-Chapter Homework Creation and Publishing**

Ms. Sharma teaches Science to Class 8-A and Class 8-B at Sunshine International School. She has just finished teaching Chapter 5: Chemical Reactions. She wants to assign homework to reinforce the concepts.

She logs into the system and navigates to the Homework tab. She clicks "Add Homework" and fills in the following:
- **Title:** "Chapter 5: Chemical Reactions — Practice Questions"
- **Class:** Grade 8
- **Section:** Section A (she will clone this to Section B later)
- **Subject:** Science
- **Lesson:** Chemical Reactions (selected from the Syllabus)
- **Topic:** Types of Chemical Reactions (selected from the Syllabus)
- **Description:** "Answer the following questions in your notebook. Write balanced chemical equations where applicable. Submit your answers as text."
- **Submission Type:** Text
- **Gradable:** Yes
- **Maximum Marks:** 20
- **Passing Marks:** 10
- **Difficulty Level:** Medium
- **Assign Date:** 15 July 2026
- **Due Date:** 22 July 2026
- **Late Submission:** Not Allowed
- **Release Condition:** Immediate
- **Attachments:** She uploads a PDF titled "Chemical_Reactions_Worksheet.pdf"

She clicks Save. The homework appears in the list with a "Draft" badge. She reviews it, confirms everything is correct, and clicks the Publish button. The system asks for confirmation. She clicks Yes. Within seconds, the system creates 35 assignment records for all 35 students in Class 8-A. A success message says "Homework published successfully! 35 assignments created."

Now she needs the same homework for Class 8-B. She clicks the Clone button on the homework, selects "Section B" from the modal dropdown, and clicks Clone. The system creates a new Draft homework linked to Class 8, Section B, with all the same details and the attached PDF. She opens the cloned version, changes the due date to 23 July (since Section B is one day behind in the syllabus), and publishes it.

**What the Student Sees (Student Portal):**

When Ravi, a student in Class 8-A, logs into his Student Portal, he sees a notification: "New Homework: Chapter 5: Chemical Reactions — Practice Questions." He opens it, reads the description, downloads the attached worksheet PDF, types his answers into the text box, and clicks Submit. His submission is timestamped, and since he submitted before the due date, it is marked as On Time.

---

## Related Screens

- **Homework Create Form** — The form teachers use to enter all homework details before saving.
- **Homework Edit Form** — The pre-populated form for modifying a draft homework.
- **Homework Details Page** — A read-only view showing all information about a specific homework.
- **Homework Trash Page** — A list of soft-deleted homework that can be restored or permanently deleted.
- **Assignment Tracking Screen** — Shows per-student assignment records for a published homework.
- **Submission Screen** — Where teachers view and grade student submissions.
- **Paper Check Screen** — A unified workspace for grading all submissions for a homework.

---

## Requirements

**Controller:** Modules\LmsHomework\Http\Controllers\LmsHomeworkController
**Model:** Modules\LmsHomework\Models\Homework (table: lms_homework)
**Form Request:** Modules\LmsHomework\Http\Requests\HomeworkRequest
**Policy:** Modules\LmsHomework\Policies\HomeworkPolicy (permission group: 	enant.home-work.*)
**Routes:** Resource route home-works under lms-home-work prefix, plus extra routes for publish, clone, toggle-status, trash, restore, and force-delete.

Key controller methods:
- index() — Loads the hub view with all tab data including the paginated homework list
- create() — Returns the homework creation form with dropdown data for class, subject, lesson, topic, difficulty levels, submission types, and statuses
- store(HomeworkRequest) — Validates input and creates a new homework record with Draft status; syncs attachments; logs activity
- show() — Returns the read-only homework details page
- edit() — Returns the pre-populated edit form for a Draft homework
- update(HomeworkRequest, ) — Validates and updates an existing homework; tracks changes for audit log
- destroy() — Soft-deletes a homework (only if it has no submissions); sets is_active to false
- 	rashed() — Lists soft-deleted homework with restore and force-delete options
- estore() — Restores a soft-deleted homework and sets is_active to true
- orceDelete() — Permanently deletes a homework and all its assignments and submissions
- 	oggleStatus() — Toggles the is_active flag via AJAX
- publish() — Publishes a Draft homework, creates assignment records for all enrolled students
- clone(Request, ) — Clones a homework to another section of the same class as a new Draft
- getSameClassSections() — Returns sections of the same class (excluding current) for the clone modal

---

## Who Can Access This Screen

| Role | What They Can Do | Permission Needed |
|------|-----------------|-------------------|
| Teacher | Create homework, edit their own drafts, publish, clone, delete (if no submissions), toggle active status | 	enant.home-work.* |
| School Admin | Same as Teacher, but for all homework across all classes and subjects | 	enant.home-work.* |
| Principal | Can only view the homework list and open details — cannot create, edit, publish, or delete | 	enant.home-work.viewAny, 	enant.home-work.view |

---

## How This Screen Works — Logic Flow (Non-Technical)

The teacher navigates to the LMS Homework section from the main menu. The system checks whether the user has permission to view any of the Homework tabs. If they do, the hub page loads with five tabs — Homework Analytics, Homework, Assignment Tracking, Summary, and Homework Submission. The Homework tab is selected by default (unless the user has previously selected a different tab, in which case their last selection is remembered).

The system loads the homework list by querying the database for all homework records that match any active filters (if none are selected, all records are returned). The records are sorted with the newest homework first and divided into pages of 10 items each. The system also loads the list of active Classes, Sections, and Subjects to populate the filter dropdowns.

When the teacher clicks the "Add Homework" button, the system navigates to a new page with a form divided into logical sections. The teacher selects the class first — this triggers an automatic lookup of sections and subjects for that class, which populate their respective dropdowns. As the teacher fills in each field, the system validates the input in real-time (for example, ensuring the due date is after the assign date). When the teacher clicks Save, the system performs a final validation of all fields, creates the homework record in the database with a Draft status, attaches any uploaded files, logs the action in the audit trail, and redirects back to the homework list with a green success message.

When the teacher clicks Publish, a confirmation dialog appears explaining what will happen. If the teacher confirms, the system looks up all active students enrolled in the target class and section for the current academic year. For each student, it creates an assignment record — think of it as giving each student their own personal copy of the homework with its own status tracking. The system then changes the homework status from Draft to Published and reports back how many assignments were created.

---

## Validate Before Save

**Creating a New Homework:**
1. **Class is required** — The teacher must select a class from the dropdown. The system checks that the selected class exists in the database and is active.
2. **Subject is required** — The teacher must select a subject. The system checks that the selected subject exists and is active.
3. **Title is required** — The homework must have a title between 1 and 255 characters.
4. **Description is required** — The teacher must provide a description of the homework. Rich text is supported.
5. **Submission Type is required** — The teacher must select how students will submit (Text, File, or Hybrid). The system checks that the selected type exists in the dropdown configuration.
6. **Assign Date is required** — The date when students should start working on the homework. Must be a valid date.
7. **Due Date is required and must be after Assign Date** — The submission deadline. The system rejects any due date that is on or before the assign date with the error "Due date must be after assign date."
8. **Release Condition is required** — Must be one of: IMMEDIATE, ON_TOPIC_COMPLETE, or ON_SCHEDULED_DATE.
9. **Release Scheduled Date is required if condition is ON_SCHEDULED_DATE** — If the teacher chooses scheduled release, they must pick a date. This date must be on or after the assign date.
10. **If Gradable: Maximum and Passing Marks are required** — Maximum marks must be between 0 and 999.99. Passing marks must be less than or equal to maximum marks. If the teacher enters passing marks higher than maximum marks, the system shows the error: "Passing marks must be less than or equal to maximum marks."
11. **File Attachments** — If the teacher uploads files, each file must be of an allowed type (PDF, DOC, DOCX, TXT, JPG, JPEG, PNG, ZIP) and no larger than 10 MB. Invalid files are rejected individually with a specific error message.

**Editing an Existing Homework:**
- The same validations apply as for creation.
- Additionally, if the assign date is being changed on an existing homework, the new date must be on or after today. This prevents backdating.

---

## Error Handling and Validation Messages

| Scenario | What the User Sees | Type |
|----------|-------------------|------|
| Teacher forgets to select a class | "Please select a class." | Validation |
| Teacher forgets to enter a title | "The homework title is required." | Validation |
| Teacher forgets to enter a description | "Please provide a description." | Validation |
| Teacher sets due date on or before assign date | "Due date must be after assign date." | Validation |
| Teacher sets passing marks higher than max marks | "Passing marks must be less than or equal to maximum marks." | Validation |
| Teacher chooses Scheduled Date release but does not pick a date | "The release scheduled date is required when the release condition is set to scheduled date." | Validation |
| Teacher uploads a file that is too large | "The file may not be greater than 10240 kilobytes." | Validation |
| Teacher uploads a .exe file | "The file must be a file of type: pdf, doc, docx, txt, jpg, jpeg, png, zip." | Validation |
| Teacher tries to publish a homework that is already Published | "Only draft homework can be published." | Business Rule |
| Teacher tries to delete a homework that has submissions | "Cannot delete homework with existing submissions." | Business Rule |
| Teacher tries to clone to the same section | "Clone target must be a different section of the same class." | Business Rule |
| User without permission tries any action | "This action is unauthorized." | Authorization — HTTP 403 |

---

## Success Scenarios

**SC-001 — Homework Created Successfully**
Ms. Sharma fills in all required fields for a new homework and clicks Save. The system validates all fields, creates the homework as a Draft, attaches her worksheet PDF, logs the creation in the audit trail, and redirects her back to the Homework list. She sees her new homework at the top of the list with a green "Draft" badge and a success message.

**SC-002 — Homework Published with 35 Assignments**
Ms. Sharma clicks Publish on her Draft homework. The confirmation dialog appears. She clicks Yes. The system processes the request: it finds all 35 students enrolled in Class 8-A, creates 35 assignment records (one per student), changes the homework status to Published, and shows a success message: "Homework published successfully! 35 assignments created." Each student will now see the homework in their Student Portal.

**SC-003 — Homework Cloned to Another Section**
Ms. Sharma clicks Clone on her published homework for Class 8-A. A modal dialog opens showing "Section B" as an option. She selects Section B and clicks Clone. The system creates a new Draft homework for Class 8-B with the same title, description, marks, and attached PDF. Ms. Sharma opens the clone, changes the due date, and publishes it independently.

**SC-004 — Homework Toggled Inactive**
Ms. Sharma finds an old homework that should no longer appear in active lists. She clicks the status toggle switch next to it. The switch flips from green (active) to grey (inactive) immediately. The page does not need to reload — the change happened via an AJAX call.

**SC-005 — Homework Trashed (No Submissions)**
Ms. Sharma realizes she created a homework for the wrong class. She checks that no students have submitted (the homework is still in Draft), then clicks the Delete button. The homework disappears from the active list. She can restore it later from the Trash page if needed.

---

## Failure Scenarios

**FC-001 — Attempt to Publish an Already Published Homework**
Mr. Patel published a homework yesterday. Today, he clicks Publish again by mistake. The system rejects the request with the error: "Only draft homework can be published." The status remains Published, and no duplicate assignments are created.

**FC-002 — Attempt to Delete a Homework with Student Submissions**
Mr. Patel tries to delete a homework that was published two weeks ago and has 25 student submissions. The system blocks the deletion with the error: "Cannot delete homework with existing submissions." Mr. Patel must either wait until the homework life cycle is complete or archive it instead.

**FC-003 — Due Date Before Assign Date**
Ms. Sharma enters the assign date as 22 July and the due date as 15 July. When she clicks Save, the system highlights the due date field in red and shows: "Due date must be after assign date." She corrects the due date and saves successfully.

**FC-004 — Clone to the Same Section**
Mr. Patel clicks Clone on a homework for Class 8-A but accidentally selects "Section A" (the same section) from the modal. The system rejects with: "Clone target must be a different section of the same class." He selects "Section B" instead and the clone succeeds.

**FC-005 — Unauthorized Access**
A teacher who has not been granted the homework creation permission tries to access the "Add Homework" page. The system returns a 403 Forbidden page: "This action is unauthorized." The teacher contacts the school admin to request the necessary permission.

---

## Dependencies module and tables

| Module | Tables Used | Why |
|--------|-------------|-----|
| LmsHomework (self) | lms_homework, lms_homework_assignment, lms_homework_submissions | Core homework data |
| SchoolSetup | sch_classes, sch_sections, sch_subjects, sch_org_academic_sessions_jnt, sch_class_section_jnt | Target class, section, subject, and academic year references |
| Syllabus | slb_lessons, slb_topics, slb_complexity_level, slb_syllabus_schedule | Lesson/topic alignment and difficulty levels |
| StudentProfile | std_students | Look up enrolled students when publishing homework |
| Prime | sys_dropdown_table, sys_users | Homework statuses, submission types, and user tracking |
