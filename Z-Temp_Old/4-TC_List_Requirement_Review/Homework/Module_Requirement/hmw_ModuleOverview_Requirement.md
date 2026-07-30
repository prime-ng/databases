# LmsHomework Module — Module Overview

## What This Module Does

The LmsHomework module is the school's complete homework management system. It replaces the traditional paper-based homework register with a digital system that handles the entire homework lifecycle — from creation by teachers to submission by students to grading and feedback.

Think of this module as three layers working together:

1. **Teacher Layer:** Teachers create homework (define the task, set dates, choose release conditions), publish it to their classes, track which students have submitted, grade submissions, and provide feedback.

2. **System Layer:** The system automatically generates individual assignment records for every student when a homework is published, detects late submissions, sends notifications, and runs scheduled tasks to release homework on specific dates or mark overdue assignments.

3. **Student Layer (via Student Portal):** Students see their assigned homework, view instructions and attached files, submit their work (text or file upload), view their grades and feedback, and resubmit if requested by the teacher.

The module is designed for Indian K-12 schools where a teacher typically teaches one subject to multiple sections of the same class. Features like cloning homework to another section and per-student due date extensions are built specifically for this use case.

---

## Module Architecture

The module follows a Tab-Based Hub design — all major features are accessible from a single page with five tabs:

| Tab | What It Does | Permission Required |
|-----|--------------|---------------------|
| **Homework Analytics** | Dashboard with KPIs, charts, and trends at a glance | 	enant.home-work-dashbord.viewAny |
| **Homework** | Create, publish, edit, clone, and manage homework | 	enant.home-work.viewAny |
| **Assignment Tracking** | Per-student view of assignments with due date overrides, release toggles, and reminders | 	enant.home-work-assignment-tracking.viewAny |
| **Summary** | Per-homework breakdown of assigned/submitted/checked/reassigned counts | 	enant.home-work-summary.viewAny |
| **Homework Submission** | View, create, grade, and manage student submissions | 	enant.home-work-submission.viewAny |

Additionally, there is a standalone **Paper Check** screen for grading all submissions of a specific homework in one workspace.

---

## Core Data Model

The module uses three database tables that work together:

**1. Homework (lms_homework)**
This is the template or definition of a homework task. It stores: title, description, target class/subject/section, assign date, due date, marks (max and passing), difficulty level, submission type, release condition, status (Draft/Published/Archived), and teacher's reference file attachments.

**2. Assignment (lms_homework_assignment)**
When a homework is published, the system creates one assignment record for each student. This is the student's personal copy of the homework. It stores: which homework it belongs to, which student, whether it has been released, the student's individual due date (if different from the default), view tracking (when the student opened it and how many times), and notification timestamps.

**3. Submission (lms_homework_submissions)**
When a student submits their work, a submission record is created. It stores: the student's submitted text and/or file attachments, the submission timestamp, whether it was late, the teacher's marks and feedback, who graded it and when, and the resubmission count.

---

## Key Workflows

**W1 — Create → Publish → Assign**
A teacher creates a homework (saved as Draft). When ready, they publish it. The system creates one assignment per enrolled student. The homework status changes to Published.

**W2 — Submit → Grade → Publish Score**
A student submits their work (via Student Portal). The teacher opens the submission, enters marks and feedback, and finalizes the grade. If auto-publish is on, the score is immediately visible to the student.

**W3 — Scheduled Release / Topic Release**
Homework can be set to release immediately, on a specific date, or when a syllabus topic is completed. Background jobs handle the scheduled release and overdue marking.

**W4 — Resubmission**
If a student's work is incomplete or needs improvement, the teacher can request a resubmission. The student submits again, and the resubmission counter increments.

**W5 — Per-Student Overrides**
Teachers can give individual students due date extensions, override late submission policies, and send reminders — all from the Assignment Tracking screen.

---

## State Machines

**Homework Status Flow:**
Draft → Published → Archived
(Only Draft homework can be edited. Publishing creates assignments.)

**Assignment Status Flow:**
Pending Release → Assigned → Viewed → Submitted/Late Submitted → Graded
(Also possible: Overdue from Assigned/Viewed if past due without submission, Exempted for excused students.)

**Submission Status Flow:**
Submitted → Under Review → Graded
(Also possible: Resubmit Requested from Submitted or Graded, then back to Submitted on resubmission.)

All statuses are configurable via the dropdown system — schools can customize the status names without changing code.

---

## Key Business Rules

- One homework can have many assignments (one per student), but each student has exactly one assignment per homework.
- Publishing a homework is idempotent — doing it again does not create duplicates.
- Homework can only be edited while in Draft status.
- Late submissions are automatically detected by comparing submission time against the due date.
- One submission per assignment unless the teacher requests a resubmission.
- Marks must be between 0 and the homework's maximum marks.
- All create, update, delete, and grade actions are recorded in the audit trail.
- All data is isolated per school (tenant) — one school can never see another school's data.

---

## Technical Architecture

**Controllers (2):**
- LmsHomeworkController (~2367 lines) — Handles homework CRUD, publishing, cloning, assignment tracking, paper check, analytics, summary, and AJAX dropdown endpoints.
- HomeworkSubmissionController (~697 lines) — Handles submission CRUD, grading/review, and bulk download.

**Models (3):**
- Homework (299 lines) — SoftDeletes, Spatie Media Library, scopes for search/status/class/subject/timeline
- HomeworkAssignment (119 lines) — SoftDeletes, unique constraint on (homework_id, student_id)
- HomeworkSubmission (242 lines) — SoftDeletes, Spatie Media Library, resubmission support

**Form Requests (3):**
- HomeworkRequest — Validates homework creation and updates
- HomeworkSubmissionRequest — Validates submission creation and updates
- HomeworkReviewRequest — Validates grading (marks within range, feedback length)

**Policies (5):**
- HomeworkPolicy — Registered, covers 	enant.home-work.*
- HomeworkSubmissionPolicy — Registered, covers 	enant.home-work-submission.*
- HomeworkAssignmentTrackingPolicy — Registered, covers 	enant.home-work-assignment-tracking.*
- HomeworkSummaryPolicy — Exists on disk but NOT registered in ServiceProvider
- HomeworkDashboardPolicy — Exists on disk but NOT registered in ServiceProvider

**Services (2):**
- HomeworkQueryService — Encapsulates homework listing queries with filters
- LmsStorageService — Manages file storage for homework attachments

**Console Commands (2):**
- ReleaseScheduledHomework — Releases homework on scheduled date (runs per-tenant)
- UpdateHomeworkStatus — Marks overdue assignments (runs per-tenant)

**Observer (1):**
- SyllabusScheduleObserver — Listens for syllabus topic completion to trigger On-Topic-Complete release (currently not functional due to key mismatch)

**Database Migrations (3 central migrations):**
- 2026_06_16_122811_create_lms_homework_table.php
- 2026_06_16_122812_create_lms_homework_assignment_table.php
- 2026_06_16_122813_create_lms_homework_submissions_table.php

---

## Known Gaps and Limitations

| Issue | Description | Status |
|-------|-------------|--------|
| Late Submission Not Blocked | When a homework does not allow late submissions, the system flags late submissions but does not hard-block them at submit time | Known gap — scheduled for fix |
| Notifications Not Delivered | Notification records are created but recipient targeting is commented out — students and parents never actually receive them | Known gap — scheduled for fix |
| On-Topic-Complete Not Working | The automatic release when a syllabus topic is completed is not functional due to a dropdown key mismatch in the observer | Known gap — scheduled for fix |
| Permission String Mismatch | FormRequests use 	enant.homework.* while controllers and policies use 	enant.home-work.* (hyphen vs no hyphen) | Known gap — scheduled for alignment |
| Module migrations empty | The module's own database/migrations/ directory contains .gitkeep only; real migrations are in the central tenant migrations folder | Architectural decision |

---

## Module Dependencies

| Module | How This Module Depends On It |
|--------|------------------------------|
| **SchoolSetup** | Classes, sections, subjects, and academic sessions for targeting homework |
| **Syllabus** | Lessons, topics, complexity levels, and syllabus schedule for content alignment |
| **StudentProfile** | Student records for enrollment lookup when publishing homework |
| **Prime** | Dropdown configuration (sys_dropdown_table) for statuses and types; user records for tracking who created/graded |
| **Notification** | Creates notification records on lifecycle events (release, grade, reminder) |
| **StudentPortal** (planned) | Where students submit work and view grades (UI is in this separate module) |
| **ParentPortal** (planned) | Where parents view their child's homework status and grades |
