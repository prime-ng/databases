# LmsHomework — Complete Analysis Pack (FRD + Full BA Suite)
# Prime-AI School ERP Platform

| Field | Value |
|-------|-------|
| **Module Name** | LmsHomework |
| **Module Code** | HMW |
| **Table Prefix** | `lms_` (shared — only 3 tables are homework-owned) |
| **Document Version** | 1.0 |
| **Date** | 2026-06-29 |
| **Status** | Draft |
| **Prepared By** | Business Analysis — Prime-AI |
| **Mode** | Complete Analysis Pack (FRD-spine) |
| **Sources read** | Live code (`Modules/LmsHomework`), `LmsHomework_DDL_v5.sql`, central tenant migrations (2026_06_16), V2 `HMW_LmsHomework_Requirement.md`, V1 screen-spec folder `LmsHomework_v2/` |

> This single file is the source of truth. It assigns stable `REQ-/BR-/RPT-/ENH-` IDs that all
> downstream gap analyses reuse — **never renumber**. The FRD is **Section A**; every later section
> references its IDs. Business-language register is used in narrative sections; technical register is
> confined to the clearly-marked technical sections (Data Dictionary §F technical view, Dependency Map §H).

## Table of Contents
- **Section A — Functional Requirements Document (FRD)** — A1 Overview · A2 Roles · A3 Functional Requirements · A4 Business Rules Register · A5 Data Requirements · A6 Workflows · A7 Reporting · A8 Enhancements · A9 NFRs · A10 Gap-Analysis Readiness Index
- **Section B — Requirements Traceability Matrix (RTM)**
- **Section C — Requirement Conditions Catalog** (+ canonical copy note)
- **Section D — Validation & Edge-Case Catalog**
- **Section E — Process Flows & State Machines (FSM)**
- **Section F — Data Dictionary** (business + technical view)
- **Section G — Cross-Module Dependency Map**
- **Section H — NFR Catalog & Risk Register**
- **Section I — Prioritization (MoSCoW) & Sprint Task Breakdown**
- **Section J — User Stories (Gherkin) & KPI Catalog**
- **Section K — Feature/Screen Specifications**
- **Section L — Anomalies & Module Knowledge note**

---
---

# Section A — Functional Requirements Document (FRD)

## A1 — Module Overview

### A1.1 Business Purpose
LmsHomework lets teachers set, distribute, track and grade homework for Indian K-12 classes. A teacher
creates a homework task aligned to the academic year, class, section, subject and (optionally) the
lesson/topic being taught, sets a due date and grading rules, then publishes it. On publishing, the
system hands every enrolled student their own copy of the homework, follows who has seen, submitted and
been graded, and keeps the school informed through notifications. Without this module, homework lives on
paper and WhatsApp, with no record of who submitted, who is late, or what marks were given.

### A1.2 Business Value
- Replaces manual homework registers with a single, searchable record per student.
- Makes "who is late / who hasn't submitted" instantly visible, per class and per student.
- Lets teachers grade, give written feedback and annotate submitted work in one place.
- Aligns homework to the syllabus (lesson/topic) so coverage can be tracked.
- Supports timed/auto release so homework appears exactly when intended (immediately, on a date, or when a topic is finished).
- Keeps a permanent, per-school audit trail of every homework action.

### A1.3 Scope

#### In Scope
1. Creating, editing, archiving and deleting homework tasks (templates) for a class-section-subject.
2. Attaching teacher reference files to a homework.
3. Publishing a homework, which generates one assignment record per enrolled student.
4. Three release conditions: release immediately, on a scheduled date, or when a syllabus topic is completed.
5. Per-student tracking: release status, view count, per-student due-date extension, late-submission override, reminders.
6. Student submissions (typed text and/or uploaded files), with automatic late detection.
7. Resubmission handling when a teacher asks a student to redo work.
8. Grading: marks, pass/fail against passing marks, written feedback, and an annotated paper-check workspace.
9. Score publishing — automatic on grading or manual.
10. Bulk download of all submissions for a homework as a single ZIP.
11. Scheduled automation: auto-release on date, and auto-mark overdue assignments.
12. Homework analytics dashboard and a per-homework summary report.
13. Notifications on key lifecycle events.
14. Cloning a homework to another section of the same class.

#### Out of Scope
1. The student- and parent-facing portals where students actually submit and parents view results — owned by **StudentPortal** and **ParentPortal**.
2. The class/section/subject/academic-session masters — owned by **SchoolSetup**.
3. The lesson/topic/syllabus-schedule masters — owned by **Syllabus**.
4. The generic notification delivery engine (channels, templates) — owned by **Notification**.
5. The cross-module automation Rule Engine (trigger/action/rule tables) — owned by **EventEngine** (historically prototyped here; now removed).
6. Consolidated report cards / marks aggregation — owned by **MarksheetGeneration**.

### A1.4 Key Terminology
| Business Term | Meaning |
|---------------|---------|
| Homework | A teacher-created task (the template) for a class-section-subject; starts as a Draft. |
| Assignment | One student's personal copy of a published homework; tracks release, viewing, due date and status. |
| Submission | A student's response (text and/or files) to their assignment. |
| Release Condition | When a homework becomes visible: Immediately, On a Scheduled Date, or On Topic Completion. |
| Gradable | A homework that carries marks (with maximum and passing marks); non-gradable is completion-only. |
| Late Submission | A submission made after the effective due date; flagged automatically. |
| Allow Late Submission | A setting (per homework, overridable per student) that controls whether late work is accepted. |
| Auto-Publish Score | When on, a student sees their marks the moment the teacher grades. |
| Paper Check | A workspace where a teacher views a submission, enters marks/feedback, and uploads an annotated file. |
| Resubmission | A re-attempt after a teacher rejects work or requests a redo; counted per submission. |
| Timeline Status | A computed label (Upcoming / Ongoing / Overdue) based on assign and due dates. |
| Effective Due Date | The student's own due date if set, otherwise the homework's due date. |

---

## A2 — User Roles & Access

### A2.1 Actor Definitions
| Role | Who They Are | Their Relationship to This Module |
|------|-------------|-----------------------------------|
| Teacher | Subject/class teacher | Creates, publishes, tracks, grades and gives feedback on homework. |
| School Admin / Principal | School administrator | Full oversight; can manage any homework, override due dates, view analytics. |
| Student | Enrolled pupil | Receives assignments and submits work (via StudentPortal — out of this module's UI). |
| Parent | Guardian | Receives homework/grade notifications and views child status (via ParentPortal — out of scope here). |
| System (Scheduler) | Automated background jobs | Releases scheduled homework and marks overdue assignments nightly. |

### A2.2 Role-Feature Access Matrix
| Feature | Teacher | School Admin | Student | Parent | System |
|---------|---------|--------------|---------|--------|--------|
| Create / edit homework | Full | Full | No Access | No Access | — |
| Publish homework | Full | Full | No Access | No Access | — |
| Clone homework | Full | Full | No Access | No Access | — |
| Delete / restore / archive homework | Full | Full | No Access | No Access | — |
| Track assignments (overrides, reminders) | Full | Full | No Access | No Access | — |
| Submit homework | No (acts on behalf) | On behalf | Full (portal) | No Access | — |
| Grade / paper-check / feedback | Full | Full | No Access | No Access | — |
| Publish score | Full | Full | No Access | View result | — |
| Bulk download submissions | Full | Full | No Access | No Access | — |
| Analytics dashboard & summary | Full | Full | No Access | No Access | — |
| Receive lifecycle notifications | — | — | Receives | Receives | Sends |
| Scheduled release / overdue marking | — | — | — | — | Executes |

---

## A3 — Functional Requirements

### A3.1 Homework Template Creation & Management
**Requirement ID:** REQ-HMW-001 · **Priority:** Core (P0) · **Tags:** [DATA_ENTRY][CONFIGURATION]
**Business Description:** A teacher creates a homework task tied to the current academic year, a class,
an optional section (blank = all sections), a subject, and optionally a lesson and topic. They set a
title, a rich description, submission type (Text / File / Hybrid), grading rules, assign and due dates,
late policy and release condition. A new homework is saved as a Draft and can be freely edited until
published. Editing and viewing are supported, with full server-side validation.
**Actors:** Initiates Teacher/Admin · Processes Teacher/Admin · Views Teacher/Admin.
**Business Rules:** BR-HMW-001, 002, 003, 004, 005, 006.
**Acceptance Criteria:**
1. A homework can be created with all required fields and is stored as Draft.
2. Saving with a missing title, subject, class, description, submission type, assign date or due date is rejected with a clear message.
3. A due date earlier than or equal to the assign date is rejected.
4. If marked gradable, maximum and passing marks are required and passing marks cannot exceed maximum.
5. A Draft homework can be edited and re-saved; the editor pre-loads the saved topic chain.
**Integration:** Receives class/section/subject/session from SchoolSetup; lesson/topic/schedule and difficulty from Syllabus. **Enhancement Notes:** ENH-HMW-001, 002.

### A3.2 Homework Publishing & Per-Student Assignment Generation
**Requirement ID:** REQ-HMW-002 · **Priority:** Core (P0) · **Tags:** [WORKFLOW][APPROVAL]
**Business Description:** Publishing promotes a Draft homework to Published and generates one assignment
record for every active enrolled student in the target class (and section, if specified) for the
academic year. Re-publishing is safe (idempotent) — existing assignment rows are updated, not duplicated.
**Actors:** Initiates Teacher/Admin · Processes System · Views Teacher/Admin.
**Business Rules:** BR-HMW-007, 008, 009, 010.
**Acceptance Criteria:**
1. Only a Draft homework can be published; publishing a non-Draft is rejected.
2. Publishing a homework to a class of N enrolled students creates exactly N assignment records.
3. Re-publishing the same homework does not create duplicate assignments.
4. The homework status becomes Published and the action is recorded in the audit trail.
5. The number of assignments created is reported back to the teacher.
**Integration:** Reads enrolled students from StudentProfile. **Enhancement Notes:** ENH-HMW-003.

### A3.3 Release Condition Configuration
**Requirement ID:** REQ-HMW-003 · **Priority:** Standard (P1) · **Tags:** [WORKFLOW][SCHEDULED]
**Business Description:** Each homework carries a release condition: **Immediately** (visible as soon as
published), **On a Scheduled Date** (visible from a chosen date), or **On Topic Completion** (visible when
the linked syllabus topic is marked complete). The condition determines whether assignments are released
at publish time or held as Pending Release.
**Actors:** Initiates Teacher/Admin · Processes System.
**Business Rules:** BR-HMW-011, 012, 013.
**Acceptance Criteria:**
1. Immediate release sets each assignment to released and status Assigned at publish.
2. Scheduled / On-Topic release leaves assignments unreleased with status Pending Release.
3. Choosing On a Scheduled Date requires a release date on or after the assign date.
**Integration:** On Topic Completion listens to Syllabus schedule. **Enhancement Notes:** ENH-HMW-004.

### A3.4 Homework Attachments
**Requirement ID:** REQ-HMW-004 · **Priority:** Standard (P1) · **Tags:** [DATA_ENTRY]
**Business Description:** A teacher can attach one or more reference files (worksheets, scans) to a
homework. On edit, kept files are retained and removed files are deleted from storage. Files are stored
under the school- and homework-specific cloud path.
**Actors:** Initiates Teacher/Admin.
**Business Rules:** BR-HMW-014, 015.
**Acceptance Criteria:**
1. Allowed file types (pdf, doc, docx, txt, jpg, jpeg, png, zip) up to 10 MB each can be attached.
2. Files removed on the edit screen are deleted from storage; kept files remain.
3. A homework can be saved with no attachments.

### A3.5 Homework Clone to Another Section
**Requirement ID:** REQ-HMW-005 · **Priority:** Enhanced (P2) · **Tags:** [WORKFLOW]
**Business Description:** A teacher can copy a homework to another section of the **same class**. The clone
is created as a Draft and copies attachments.
**Actors:** Initiates Teacher/Admin.
**Business Rules:** BR-HMW-016, 017.
**Acceptance Criteria:**
1. Cloning to a section of a different class is rejected.
2. Cloning to the same source section is rejected.
3. The clone is created as Draft with attachments copied.

### A3.6 Homework Trash, Restore, Archive & Force Delete
**Requirement ID:** REQ-HMW-006 · **Priority:** Standard (P1) · **Tags:** [WORKFLOW]
**Business Description:** Homework can be soft-deleted (trashed), restored from trash, or permanently
removed. A homework that already has submissions cannot be soft-deleted. Permanent delete cascades to its
assignments and submissions.
**Actors:** Initiates Teacher/Admin.
**Business Rules:** BR-HMW-018, 019, 020.
**Acceptance Criteria:**
1. A homework with at least one submission cannot be trashed.
2. A trashed homework can be restored and reappears in the list.
3. Permanent delete removes the homework and its dependent assignments/submissions; the action is audited.

### A3.7 Homework Active/Inactive Toggle
**Requirement ID:** REQ-HMW-007 · **Priority:** Enhanced (P2) · **Tags:** [CONFIGURATION]
**Business Description:** A teacher can toggle a homework active/inactive without deleting it.
**Actors:** Initiates Teacher/Admin.
**Business Rules:** BR-HMW-021.
**Acceptance Criteria:**
1. Toggling updates the active flag and is audited.
2. The new state is reflected immediately in the list.

### A3.8 Student Homework Submission
**Requirement ID:** REQ-HMW-008 · **Priority:** Core (P0) · **Tags:** [DATA_ENTRY][WORKFLOW]
**Business Description:** Against an assignment, a student (or admin on their behalf) submits typed text
and/or files. The system records the submission time, automatically flags whether it is late against the
effective due date, sets the submission and assignment status, and prevents a second submission for the
same assignment unless a resubmission was requested.
**Actors:** Initiates Student/Admin · Processes System · Views Teacher/Admin.
**Business Rules:** BR-HMW-022, 023, 024, 025, 026.
**Acceptance Criteria:**
1. A submission requires at least text or one attached file.
2. A submission stores the submit time and an automatically computed late flag.
3. A second submission for an assignment that already has one (without a resubmission request) is rejected with a clear message.
4. On submit, the assignment status moves to Submitted or Late-Submitted.
**Integration:** Reads assignment/homework; stores files via the LMS storage path. **Enhancement Notes:** ENH-HMW-005.

### A3.9 Late Submission Detection & Policy
**Requirement ID:** REQ-HMW-009 · **Priority:** Core (P0) · **Tags:** [WORKFLOW]
**Business Description:** The effective due date is the student's own due date if set, otherwise the
homework due date. A submission after that date is flagged late. The late policy (allow/deny), with a
per-student override, governs whether late work should be accepted.
**Actors:** Initiates Student · Processes System.
**Business Rules:** BR-HMW-023, 027, 028.
**Acceptance Criteria:**
1. A submission after the effective due date is flagged late; before it, not late.
2. The effective due date resolves to the per-student date when one is set.
3. The effective late policy resolves to the per-student override when one is set.
> Known gap (see Section L, A-FN-1): denial of a late submission when late is not allowed is **not yet hard-enforced** at submit time.

### A3.10 Resubmission Workflow
**Requirement ID:** REQ-HMW-010 · **Priority:** Standard (P1) · **Tags:** [WORKFLOW]
**Business Description:** A teacher can request a resubmission. The student then updates their work; on
resubmit the resubmission count increases, the submit time refreshes, the late flag is re-evaluated and
the status returns to Submitted/Late-Submitted.
**Actors:** Initiates Teacher (request) / Student (resubmit) · Processes System.
**Business Rules:** BR-HMW-029, 030.
**Acceptance Criteria:**
1. Requesting a resubmission sets the submission status to Resubmit-Requested.
2. A resubmission increments the resubmission count and refreshes the submit time and late flag.
3. The single submission record per assignment is reused (no duplicate row).

### A3.11 Submission Grading & Feedback (Review)
**Requirement ID:** REQ-HMW-011 · **Priority:** Core (P0) · **Tags:** [WORKFLOW][APPROVAL]
**Business Description:** A teacher reviews a submission, enters marks and written feedback, and sets the
status (e.g. Graded / Resubmit-Requested). The system records who graded and when, validates marks
against the homework maximum, and notifies the student.
**Actors:** Initiates Teacher/Admin · Processes System · Views Student.
**Business Rules:** BR-HMW-031, 032, 029.
**Acceptance Criteria:**
1. Only a user with grade permission can grade; others are refused.
2. Marks cannot exceed the homework maximum and cannot be negative.
3. Grading records the grader and grade time and writes an audit entry.
4. A grade notification is created for the student.
**Integration:** Sends to Notification. **Enhancement Notes:** ENH-HMW-006.

### A3.12 Paper Check — Annotated Evaluation Workspace
**Requirement ID:** REQ-HMW-012 · **Priority:** Standard (P1) · **Tags:** [WORKFLOW][DASHBOARD]
**Business Description:** A unified per-homework workspace lists all student submissions with files. The
teacher opens a submission, views or downloads files, enters marks/feedback, uploads an annotated copy
(which can replace a specific original file), and finalizes grading or unlocks for re-check.
**Actors:** Initiates Teacher/Admin.
**Business Rules:** BR-HMW-031, 033.
**Acceptance Criteria:**
1. The workspace lists every submission for the homework with its student and files.
2. An uploaded annotated file is stored as a teacher-feedback file and is retrievable.
3. Finalize sets the submission and assignment to Graded; re-check unlocks the submission and clears grade data.

### A3.13 Score Publishing
**Requirement ID:** REQ-HMW-013 · **Priority:** Standard (P1) · **Tags:** [WORKFLOW][NOTIFICATION]
**Business Description:** When auto-publish-score is on, the student's marks become visible the moment the
teacher grades (publish time is stamped). When off, scores are withheld until manually published.
**Actors:** Initiates Teacher/System.
**Business Rules:** BR-HMW-034.
**Acceptance Criteria:**
1. Grading a homework with auto-publish-score on stamps the score-published time.
2. With auto-publish off, the score-published time stays blank until manual publish.

### A3.14 Assignment Tracking & Per-Student Overrides
**Requirement ID:** REQ-HMW-014 · **Priority:** Standard (P1) · **Tags:** [WORKFLOW][DASHBOARD]
**Business Description:** A teacher can browse assignments (filter by homework, student, status, class,
section, subject), open a single assignment with its submission and grading form, change a per-student
due date (extension only, with a reason for late overrides), update assign/release date before release,
toggle release, change status inline, and send reminders.
**Actors:** Initiates Teacher/Admin.
**Business Rules:** BR-HMW-035, 036, 037, 038.
**Acceptance Criteria:**
1. A new per-student due date earlier than the existing one is rejected.
2. The assign/release date cannot be changed once an assignment is released.
3. Toggling release updates the release state, timestamp and status, and triggers a student notification.
4. Changing the status or due date is reflected immediately and notifications are created.
**Enhancement Notes:** ENH-HMW-007.

### A3.15 Submission Bulk Download
**Requirement ID:** REQ-HMW-015 · **Priority:** Enhanced (P2) · **Tags:** [REPORT]
**Business Description:** A teacher can download all submission files for a homework as a single ZIP, named
per student.
**Actors:** Initiates Teacher/Admin.
**Business Rules:** BR-HMW-039.
**Acceptance Criteria:**
1. A ZIP of all submission files is produced, with files named by student.
2. When no submission files exist, a clear "nothing to download" response is returned.

### A3.16 Scheduled Lifecycle Automation (Release & Overdue)
**Requirement ID:** REQ-HMW-016 · **Priority:** Standard (P1) · **Tags:** [SCHEDULED][NOTIFICATION]
**Business Description:** Two background jobs run per tenant: one releases scheduled homework whose
release date has arrived (creating/refreshing assignments and notifying students); the other marks
released, unsubmitted, past-due assignments as Overdue.
**Actors:** Initiates System.
**Business Rules:** BR-HMW-040, 041.
**Acceptance Criteria:**
1. On or after its release date, a scheduled homework's assignments become released with status Assigned.
2. Released, unsubmitted assignments past their due date are set to Overdue (without re-updating already-overdue/completed rows).
3. Each job runs isolated per tenant.
> Known gap (Section L, A-FN-3): the On-Topic-Completion auto-release listener never matches and is effectively dead.
**Enhancement Notes:** ENH-HMW-004.

### A3.17 Homework Analytics Dashboard
**Requirement ID:** REQ-HMW-017 · **Priority:** Standard (P1) · **Tags:** [DASHBOARD][REPORT]
**Business Description:** A dashboard shows active homework count, total assignments, total submissions,
pending grading, submission rate, latest submissions, graded-vs-pending split, submissions over the last
7 days, and homework count by top subjects — filterable by class, section, subject and date range.
**Actors:** Views Teacher/Admin.
**Business Rules:** BR-HMW-042.
**Acceptance Criteria:**
1. Each metric reflects the selected class/section/subject/date filters.
2. The submission rate is total submissions ÷ total assignments × 100.
3. Charts render the last-7-days and top-subject breakdowns.
**Report:** RPT-HMW-001.

### A3.18 Homework Summary Report
**Requirement ID:** REQ-HMW-018 · **Priority:** Standard (P1) · **Tags:** [REPORT]
**Business Description:** A per-homework summary lists each homework with its assigned, submitted, checked
(graded) and reassigned (resubmission-requested) counts, filterable by class/section/subject/date and
searchable by title/topic.
**Actors:** Views Teacher/Admin.
**Business Rules:** BR-HMW-043.
**Acceptance Criteria:**
1. Each row shows assigned, submitted, checked and reassigned counts for the homework.
2. Filters and search constrain the rows shown.
3. Results are paginated.
**Report:** RPT-HMW-002.

### A3.19 Submission Listing & Filtering
**Requirement ID:** REQ-HMW-019 · **Priority:** Standard (P1) · **Tags:** [REPORT]
**Business Description:** A submissions list filterable by homework, student, status, late flag, active
flag, graded/ungraded, and searchable by student name/admission number/email or homework title.
**Actors:** Views Teacher/Admin.
**Business Rules:** BR-HMW-044.
**Acceptance Criteria:**
1. Each filter narrows results correctly.
2. The graded filter separates graded from ungraded submissions.
3. Results are paginated.
**Report:** RPT-HMW-003.

### A3.20 Lifecycle Notifications
**Requirement ID:** REQ-HMW-020 · **Priority:** Standard (P1) · **Tags:** [NOTIFICATION]
**Business Description:** The system raises notifications on key events: homework released/assigned, due
date changed, late-submission extended, reminder sent, and homework graded.
**Actors:** Processes System · Views Student/Parent.
**Business Rules:** BR-HMW-045.
**Acceptance Criteria:**
1. Each listed lifecycle event creates a notification record with a meaningful title and description.
2. The relevant per-student/parent notification timestamp is stamped.
> Known gap (Section L, A-FN-2): recipient targeting is currently commented out, so notifications are created but not delivered.

### A3.21 Cascading Dropdown Helpers
**Requirement ID:** REQ-HMW-021 · **Priority:** Enhanced (P2) · **Tags:** [INTEGRATION]
**Business Description:** Supporting lookups drive the create/edit forms: sections by class, subjects by
class/section, lessons by class+subject, and the topic hierarchy/ancestors by lesson and level.
**Actors:** Initiates Teacher/Admin (form interaction).
**Business Rules:** BR-HMW-046.
**Acceptance Criteria:**
1. Selecting a class returns its sections; selecting class/section returns its subjects.
2. Selecting subject returns its lessons; selecting lesson returns its topic hierarchy.
3. The full topic ancestor chain is returned for a chosen topic.

### A3.22 Access Control & Tenant Isolation
**Requirement ID:** REQ-HMW-022 · **Priority:** Core (P0) · **Tags:** [CONFIGURATION][INTEGRATION]
**Business Description:** Every screen and action is permission-gated per role; all data is isolated to the
school (tenant) database; and all create/update/delete actions are audited.
**Actors:** All.
**Business Rules:** BR-HMW-047, 048, 049.
**Acceptance Criteria:**
1. A user without the required permission is refused access to the screen/action.
2. One school's homework, assignments and submissions are never visible to another school.
3. Create/update/delete/grade/restore actions record who performed them and when.
> Known gap (Section L, A-AUTH-1): the permission strings checked at the form layer differ from those at the controller/policy layer.

---

## A4 — Business Rules Register
| Rule ID | Description | Feature | Type | Priority |
|---------|-------------|---------|------|----------|
| BR-HMW-001 | A homework requires class, subject, title, description, submission type, assign date and due date. | REQ-HMW-001 | Validation | P0 |
| BR-HMW-002 | Due date must be after the assign date. | REQ-HMW-001 | Validation | P0 |
| BR-HMW-003 | If gradable, maximum and passing marks are required and passing marks ≤ maximum marks. | REQ-HMW-001 | Validation | P0 |
| BR-HMW-004 | Section may be blank, meaning the homework applies to all sections of the class. | REQ-HMW-001 | Validation | P1 |
| BR-HMW-005 | A new homework is created in Draft and the current academic year is assigned automatically. | REQ-HMW-001 | Workflow | P0 |
| BR-HMW-006 | A homework is editable only while in Draft (enforced via the editable check). | REQ-HMW-001 | Workflow | P1 |
| BR-HMW-007 | Only a Draft homework can be published. | REQ-HMW-002 | Workflow | P0 |
| BR-HMW-008 | Publishing creates exactly one assignment per active enrolled student in the target class/section. | REQ-HMW-002 | Workflow | P0 |
| BR-HMW-009 | Re-publishing is idempotent — existing assignments are updated, never duplicated (one per homework+student). | REQ-HMW-002 | Concurrency | P0 |
| BR-HMW-010 | On publish, the homework status becomes Published. | REQ-HMW-002 | Workflow | P0 |
| BR-HMW-011 | Immediate release → assignment released, status Assigned. | REQ-HMW-003 | Workflow | P1 |
| BR-HMW-012 | Scheduled/On-Topic release → assignment unreleased, status Pending Release. | REQ-HMW-003 | Workflow | P1 |
| BR-HMW-013 | A scheduled-date release requires a release date on or after the assign date. | REQ-HMW-003 | Validation | P1 |
| BR-HMW-014 | Attachments are limited to allowed types (pdf/doc/docx/txt/jpg/jpeg/png/zip), max 10 MB each. | REQ-HMW-004 | Validation | P1 |
| BR-HMW-015 | On edit, files marked for removal are deleted from storage; kept files are retained. | REQ-HMW-004 | Workflow | P1 |
| BR-HMW-016 | A homework can only be cloned to another section of the same class. | REQ-HMW-005 | Validation | P2 |
| BR-HMW-017 | A clone is created as Draft and the source section cannot be the target. | REQ-HMW-005 | Validation | P2 |
| BR-HMW-018 | A homework with one or more submissions cannot be soft-deleted. | REQ-HMW-006 | Validation | P1 |
| BR-HMW-019 | A trashed homework can be restored. | REQ-HMW-006 | Workflow | P1 |
| BR-HMW-020 | Permanent delete cascades to the homework's assignments and submissions. | REQ-HMW-006 | Workflow | P1 |
| BR-HMW-021 | Toggling active/inactive updates the active flag and is audited. | REQ-HMW-007 | Workflow | P2 |
| BR-HMW-022 | A submission must contain at least text or one attached file. | REQ-HMW-008 | Validation | P0 |
| BR-HMW-023 | Late flag = effective due date < submit time (effective due = student due if set, else homework due). | REQ-HMW-008/009 | Calculation | P0 |
| BR-HMW-024 | Only one submission may exist per assignment unless a resubmission was requested. | REQ-HMW-008 | Concurrency | P0 |
| BR-HMW-025 | On submit, assignment status moves to Submitted or Late-Submitted accordingly. | REQ-HMW-008 | Workflow | P0 |
| BR-HMW-026 | Submission attachments are limited to allowed types, max 10 MB each. | REQ-HMW-008 | Validation | P1 |
| BR-HMW-027 | Effective late policy = per-student override if set, else homework default. | REQ-HMW-009 | Calculation | P1 |
| BR-HMW-028 | A late submission should be denied when the effective late policy is "deny". | REQ-HMW-009 | Validation | P0 |
| BR-HMW-029 | Requesting a resubmission sets the submission status to Resubmit-Requested. | REQ-HMW-010/011 | Workflow | P1 |
| BR-HMW-030 | A resubmission increments the resubmission count, refreshes submit time and re-evaluates the late flag. | REQ-HMW-010 | Workflow | P1 |
| BR-HMW-031 | Marks obtained cannot exceed the homework maximum and cannot be negative. | REQ-HMW-011/012 | Validation | P0 |
| BR-HMW-032 | Grading records the grader and grade time and writes an audit entry. | REQ-HMW-011 | Workflow | P0 |
| BR-HMW-033 | An annotated file is stored as a teacher-feedback file and may replace a specific original file. | REQ-HMW-012 | Workflow | P1 |
| BR-HMW-034 | Auto-publish-score on → score-published time is stamped at grading; off → withheld until manual publish. | REQ-HMW-013 | Workflow | P1 |
| BR-HMW-035 | A per-student due date cannot be set earlier than the existing due date. | REQ-HMW-014 | Validation | P1 |
| BR-HMW-036 | The assign/release date cannot be changed once the assignment is released. | REQ-HMW-014 | Validation | P1 |
| BR-HMW-037 | Toggling release updates release state, timestamp and status. | REQ-HMW-014 | Workflow | P1 |
| BR-HMW-038 | A late-submission override on an assignment requires a reason. | REQ-HMW-014 | Validation | P1 |
| BR-HMW-039 | Bulk download includes only submission files and names each file by student. | REQ-HMW-015 | Workflow | P2 |
| BR-HMW-040 | The release job releases scheduled homework only on/after its release date and only when Published. | REQ-HMW-016 | Workflow | P1 |
| BR-HMW-041 | The overdue job marks only released, unsubmitted, past-due assignments and skips already-overdue/completed. | REQ-HMW-016 | Workflow | P1 |
| BR-HMW-042 | Submission rate = total submissions ÷ total assignments × 100. | REQ-HMW-017 | Calculation | P1 |
| BR-HMW-043 | Summary counts: assigned, submitted (has submission), checked (graded), reassigned (resubmission requested). | REQ-HMW-018 | Calculation | P1 |
| BR-HMW-044 | The graded filter selects submissions with marks recorded; ungraded selects those without. | REQ-HMW-019 | Workflow | P1 |
| BR-HMW-045 | Each named lifecycle event creates a notification record and stamps the relevant timestamp. | REQ-HMW-020 | Workflow | P1 |
| BR-HMW-046 | Cascading lookups return only active records scoped to the chosen parent. | REQ-HMW-021 | Workflow | P2 |
| BR-HMW-047 | Every screen/action requires the matching role permission. | REQ-HMW-022 | Permission | P0 |
| BR-HMW-048 | All homework data is isolated per school (database-per-tenant). | REQ-HMW-022 | Permission | P0 |
| BR-HMW-049 | Create/update/delete/grade/restore actions are recorded in the audit trail. | REQ-HMW-022 | Workflow | P0 |

---

## A5 — Data Requirements

### A5.1 Homework (Template)
**What it represents:** The teacher's homework definition for a class-section-subject.
| Information | What it stores | Required? | Notes |
|-------------|----------------|-----------|-------|
| Academic Year | The session the homework belongs to | Yes | Auto-set to current session |
| Class / Section / Subject | Target group | Class/Subject Yes; Section No | Blank section = all sections |
| Lesson / Topic / Schedule | Syllabus alignment | No | Topic supports a multi-level hierarchy |
| Title / Description | What the homework is | Yes | Description is rich text |
| Submission Type | Text / File / Hybrid | Yes | Config-driven list |
| Gradable, Max Marks, Passing Marks | Grading rules | Marks required if gradable | Passing ≤ Max |
| Difficulty Level | Easy/Medium/Hard | No | From Syllabus |
| Assign / Due Date | Schedule window | Yes | Due after Assign |
| Allow Late Submission | Late policy default | Yes | Default deny |
| Auto-Publish Score | Immediate grade visibility | Yes | Default off |
| Release Condition / Release Date | When it becomes visible | Condition Yes | Date required if scheduled |
| Status | Draft / Published / Archived | Yes | Config-driven |
| Attachments | Teacher reference files | No | Stored files |
**Relationships:** Has many Assignments; has many Submissions; belongs to Class/Section/Subject/Lesson/Topic.
**Data Retention:** Soft-deleted; retained for audit; permanent delete cascades. **Privacy:** Internal.

### A5.2 Assignment (Per-Student)
**What it represents:** One student's copy of a published homework.
| Information | What it stores | Required? | Notes |
|-------------|----------------|-----------|-------|
| Homework / Student | The pairing | Yes | Unique per homework+student |
| Academic Year/Class/Section/Subject | Denormalized context | Yes | Section = student's actual section |
| Release Condition / Scheduled Date | Per-student release | No | Inherit from homework |
| Released / Released At | Visibility state | Yes/No | |
| Due Date (override) | Per-student due | No | Blank = homework due |
| Allow Late (override) + reason/by/at | Per-student late policy | No | Reason required for override |
| Viewed At / View Count | Engagement | No | |
| Notification timestamps | Student/parent/reminder | No | |
| Status | Pending Release → … → Graded/Overdue/Exempted | Yes | Config-driven |
| Assigned By | Publishing teacher | Yes | |
**Relationships:** Belongs to Homework & Student; has one Submission. **Privacy:** Internal.

### A5.3 Submission
**What it represents:** A student's response and its evaluation.
| Information | What it stores | Required? | Notes |
|-------------|----------------|-----------|-------|
| Assignment / Homework / Student | Links | Yes | One per assignment |
| Submission Text / Attachments | The work | At least one | |
| Submitted At / Is Late | Timing | Yes | Late auto-computed |
| Resubmission Count / Resubmission Requested | Re-attempts | Yes | |
| Status | Submitted/Under Review/Graded/Rejected/Resubmit-Requested | Yes | Config-driven |
| Marks / Feedback / Graded By / Graded At | Evaluation | No | Marks ≤ Max |
| Score Published At | Visibility of marks | No | Auto/manual |
**Relationships:** Belongs to Assignment/Homework/Student. **Privacy:** Confidential (marks/feedback are student-personal).

---

## A6 — Workflows
See **Section E** for full step/exception/notification detail and state machines. The five workflows are:
W1 Create → Publish → Assign; W2 Submit → Grade → Publish Score; W3 Scheduled/Topic Release;
W4 Resubmission; W5 Per-Student Due-Date Override & Reminders.

---

## A7 — Reporting & Analytics Requirements

### A7.1 Homework Analytics Dashboard
**Report ID:** RPT-HMW-001 · **Purpose:** At-a-glance teaching workload & submission health · **Audience:** Teacher/Admin · **Frequency:** Daily.
**Contents:** Active homework count; total assignments; total submissions; pending grading; submission rate; latest 5 submissions; graded vs pending; submissions over last 7 days; homework count by top 6 subjects.
**Filters:** Class, Section, Subject, Date range. **Export:** On-screen. **Rules:** BR-HMW-042.

### A7.2 Homework Summary
**Report ID:** RPT-HMW-002 · **Purpose:** Per-homework progress · **Audience:** Teacher/Admin · **Frequency:** As-needed.
**Contents:** Homework (title/topic/subject/class/section) with assigned, submitted, checked, reassigned counts.
**Filters:** Class, Section, Subject, Date range; search by title/topic. **Export:** On-screen (paginated). **Rules:** BR-HMW-043.

### A7.3 Submission Register
**Report ID:** RPT-HMW-003 · **Purpose:** Track and find submissions · **Audience:** Teacher/Admin · **Frequency:** Daily.
**Contents:** Submission with student, homework, status, late flag, marks. **Filters:** Homework, student, status, late, active, graded; search by student/title. **Export:** On-screen (paginated). **Rules:** BR-HMW-044.

### A7.4 Paper-Check Worklist
**Report ID:** RPT-HMW-004 · **Purpose:** Grading worklist per homework · **Audience:** Teacher · **Frequency:** As-needed.
**Contents:** All submissions for a homework with student, files, status. **Filters:** By homework. **Export:** Bulk ZIP download of files (RPT links to REQ-HMW-015). **Rules:** BR-HMW-031, 033.

---

## A8 — Future Enhancement Log
| Enhancement ID | Requested Feature | Business Value | Requested By | Priority | Status |
|----------------|-------------------|----------------|--------------|----------|--------|
| ENH-HMW-001 | Move `release_condition` from a fixed code list to the configurable dropdown system (per D29) | School-configurable release types without a release | BA | P2 | Backlog |
| ENH-HMW-002 | Subject-type validation tying submission type to homework content | Cleaner data entry | BA | P3 | Backlog |
| ENH-HMW-003 | Batch-assignment audit log for bulk publish (success/failure counts) | Re-run failed publishes safely | BA | P3 | Backlog |
| ENH-HMW-004 | Working On-Topic-Completion auto-release (fix observer key/status mismatch) | Promised release mode actually fires | BA | P1 | Backlog |
| ENH-HMW-005 | Student & Parent portals integration (submit / view results / parent visibility) | End-to-end student usage | Product | P1 | Backlog |
| ENH-HMW-006 | Wire notification recipient targeting so notifications are delivered | Students/parents actually informed | BA | P1 | Backlog |
| ENH-HMW-007 | Plagiarism / similarity check on text submissions | Academic integrity | Product | P3 | Backlog |
| ENH-HMW-008 | Feed graded homework marks into MarksheetGeneration | Consolidated report cards | Product | P2 | Backlog |

---

## A9 — Non-Functional Requirements

### A9.1 Performance
| Requirement | Standard |
|-------------|----------|
| Screen load | Lists/dashboards load within 3s for up to 500 concurrent users |
| Publish to large class | Assignment generation for a 60-student class completes within 10s |
| Dropdown lookups | Cascading lookups respond within 1s; large sets lazy-loaded |
| Bulk ZIP | A homework's submission ZIP builds within 30s |

### A9.2 Security (Business Language)
| Requirement | Rule |
|-------------|------|
| Access control | Only users with the correct permission may use each screen/action |
| Data isolation | One school's data is never visible to another (database-per-tenant) |
| Grading authority | Only authorized teachers/admins may grade |
| Audit trail | All changes record who and when |
| File safety | Only allowed file types/sizes are accepted |

### A9.3 Usability
| Requirement | Standard |
|-------------|----------|
| Mobile | Core screens work on mobile browsers |
| Language | English labels (regional as future enhancement) |
| Guidance | Validation messages are specific and actionable |

---

## A10 — Gap Analysis Readiness Index

### A10.1 Requirement Coverage Summary
| Requirement ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|---|---|---|---|---|---|---|---|---|
| REQ-HMW-001 | Homework Creation & Management | P0 | DATA_ENTRY,CONFIG | Yes | Yes | No | No | Yes |
| REQ-HMW-002 | Publishing & Assignment Generation | P0 | WORKFLOW,APPROVAL | Yes | Yes | Yes | Yes | Yes |
| REQ-HMW-003 | Release Condition Configuration | P1 | WORKFLOW,SCHEDULED | Yes | Yes | No | Yes | Yes |
| REQ-HMW-004 | Homework Attachments | P1 | DATA_ENTRY | Yes | Yes | No | No | Yes |
| REQ-HMW-005 | Clone to Section | P2 | WORKFLOW | Yes | Yes | No | No | Yes |
| REQ-HMW-006 | Trash/Restore/Force Delete | P1 | WORKFLOW | Yes | Yes | No | No | Yes |
| REQ-HMW-007 | Active Toggle | P2 | CONFIGURATION | Yes | Yes | No | No | No |
| REQ-HMW-008 | Student Submission | P0 | DATA_ENTRY,WORKFLOW | Yes | Yes | No | Yes | Yes |
| REQ-HMW-009 | Late Detection & Policy | P0 | WORKFLOW | Yes | Yes | No | No | Yes |
| REQ-HMW-010 | Resubmission Workflow | P1 | WORKFLOW | Yes | Yes | No | Yes | Yes |
| REQ-HMW-011 | Grading & Feedback (Review) | P0 | WORKFLOW,APPROVAL | Yes | Yes | Yes | Yes | Yes |
| REQ-HMW-012 | Paper Check Workspace | P1 | WORKFLOW,DASHBOARD | Yes | Yes | Yes | No | Yes |
| REQ-HMW-013 | Score Publishing | P1 | WORKFLOW,NOTIFICATION | Yes | Yes | No | Yes | Yes |
| REQ-HMW-014 | Assignment Tracking & Overrides | P1 | WORKFLOW,DASHBOARD | Yes | Yes | Yes | Yes | Yes |
| REQ-HMW-015 | Submission Bulk Download | P2 | REPORT | No | Yes | Yes | No | Yes |
| REQ-HMW-016 | Scheduled Automation | P1 | SCHEDULED,NOTIFICATION | Yes | No | No | Yes | Yes |
| REQ-HMW-017 | Analytics Dashboard | P1 | DASHBOARD,REPORT | Yes | Yes | No | No | Yes |
| REQ-HMW-018 | Summary Report | P1 | REPORT | Yes | Yes | No | No | Yes |
| REQ-HMW-019 | Submission Listing & Filtering | P1 | REPORT | Yes | Yes | No | No | Yes |
| REQ-HMW-020 | Lifecycle Notifications | P1 | NOTIFICATION | Yes | No | No | Yes | Yes |
| REQ-HMW-021 | Cascading Dropdown Helpers | P2 | INTEGRATION | No | No | Yes | No | No |
| REQ-HMW-022 | Access Control & Tenant Isolation | P0 | CONFIG,INTEGRATION | No | Yes | No | No | Yes |

### A10.2 Business Rules Coverage Summary
| Rule ID | Summary | Feature Ref | Validation Required | Data Check Required | Workflow Gate |
|---------|---------|-------------|---------------------|---------------------|---------------|
| BR-HMW-001 | Required fields on homework | REQ-HMW-001 | Yes | No | No |
| BR-HMW-002 | Due > assign | REQ-HMW-001 | Yes | No | No |
| BR-HMW-003 | Marks required & passing ≤ max | REQ-HMW-001 | Yes | No | No |
| BR-HMW-005 | New = Draft, year auto-set | REQ-HMW-001 | No | Yes | Yes |
| BR-HMW-006 | Editable only in Draft | REQ-HMW-001 | No | Yes | Yes |
| BR-HMW-007 | Publish only from Draft | REQ-HMW-002 | No | Yes | Yes |
| BR-HMW-008 | One assignment per student | REQ-HMW-002 | No | Yes | Yes |
| BR-HMW-009 | Idempotent re-publish | REQ-HMW-002 | No | Yes | Yes |
| BR-HMW-011/012 | Release state per condition | REQ-HMW-003 | No | Yes | Yes |
| BR-HMW-013 | Release date ≥ assign | REQ-HMW-003 | Yes | No | No |
| BR-HMW-014/026 | File type/size limits | REQ-HMW-004/008 | Yes | No | No |
| BR-HMW-016/017 | Clone same class only, Draft | REQ-HMW-005 | Yes | Yes | Yes |
| BR-HMW-018 | No delete with submissions | REQ-HMW-006 | No | Yes | Yes |
| BR-HMW-022 | Text or file required | REQ-HMW-008 | Yes | No | No |
| BR-HMW-023 | Late = due < submit | REQ-HMW-008/009 | No | Yes | No |
| BR-HMW-024 | One submission per assignment | REQ-HMW-008 | Yes | Yes | Yes |
| BR-HMW-027 | Effective late policy | REQ-HMW-009 | No | Yes | Yes |
| BR-HMW-028 | Deny late when not allowed | REQ-HMW-009 | Yes | Yes | Yes |
| BR-HMW-030 | Resubmission count/refresh | REQ-HMW-010 | No | Yes | Yes |
| BR-HMW-031 | Marks ≤ max, ≥ 0 | REQ-HMW-011/012 | Yes | No | Yes |
| BR-HMW-032 | Grade audit + grader/time | REQ-HMW-011 | No | Yes | Yes |
| BR-HMW-034 | Auto/manual score publish | REQ-HMW-013 | No | Yes | Yes |
| BR-HMW-035 | Due override not earlier | REQ-HMW-014 | Yes | No | Yes |
| BR-HMW-036 | No assign-date change after release | REQ-HMW-014 | Yes | Yes | Yes |
| BR-HMW-040/041 | Scheduled release/overdue gates | REQ-HMW-016 | No | Yes | Yes |
| BR-HMW-042/043 | Analytics/summary calculations | REQ-HMW-017/018 | No | Yes | No |
| BR-HMW-047 | Permission per action | REQ-HMW-022 | Yes | No | Yes |
| BR-HMW-048 | Tenant isolation | REQ-HMW-022 | No | Yes | Yes |
| BR-HMW-049 | Audit trail | REQ-HMW-022 | No | Yes | Yes |
> (Rules not listed individually above are workflow/calculation rules captured in §A4 and traced in §B.)

### A10.3 Report Coverage Summary
| Report ID | Report Name | Priority | Filters Count | Export Needed |
|-----------|-------------|----------|---------------|---------------|
| RPT-HMW-001 | Analytics Dashboard | P1 | 4 | No |
| RPT-HMW-002 | Homework Summary | P1 | 5 | No |
| RPT-HMW-003 | Submission Register | P1 | 7 | No |
| RPT-HMW-004 | Paper-Check Worklist | P1 | 1 | Yes (ZIP) |

### A10.4 Total Scope Numbers
| Category | Count |
|----------|-------|
| Total Functional Requirements (REQ-) | 22 |
| Total Business Rules (BR-) | 49 |
| Total Workflows defined | 5 |
| Total Reports required | 4 |
| Total Enhancements logged | 8 |
| Total P0 (Core) Requirements | 6 |
| Total P1 (Standard) Requirements | 12 |
| Total P2 (Enhanced) Requirements | 4 |

---
---

# Section B — Requirements Traceability Matrix (RTM)
| REQ-ID | Feature | BR refs | Screen(s) | Workflow | Report | User Story | Code Status (observed) |
|--------|---------|---------|-----------|----------|--------|------------|------------------------|
| REQ-HMW-001 | Homework Create/Manage | 001–006 | home-work/create,edit,show,index | W1 | — | US-HMW-001 | DONE |
| REQ-HMW-002 | Publish & Assign | 007–010 | publish action | W1 | — | US-HMW-002 | DONE |
| REQ-HMW-003 | Release Conditions | 011–013 | create/edit | W3 | — | US-HMW-003 | PARTIAL (on-topic dead) |
| REQ-HMW-004 | Attachments | 014–015 | create/edit | W1 | — | — | DONE |
| REQ-HMW-005 | Clone | 016–017 | clone action | W1 | — | — | DONE |
| REQ-HMW-006 | Trash/Restore/Force | 018–020 | home-work/trash | W1 | — | — | DONE |
| REQ-HMW-007 | Active Toggle | 021 | index | — | — | — | DONE |
| REQ-HMW-008 | Submission | 022–026 | submission/create,index | W2 | RPT-003 | US-HMW-004 | DONE |
| REQ-HMW-009 | Late Detection/Policy | 023,027,028 | submission | W2 | — | US-HMW-005 | PARTIAL (no hard block) |
| REQ-HMW-010 | Resubmission | 029,030 | submission/edit,paper-check | W4 | — | US-HMW-006 | DONE |
| REQ-HMW-011 | Grading (Review) | 029,031,032 | submission/edit,assignment/show | W2 | — | US-HMW-007 | DONE |
| REQ-HMW-012 | Paper Check | 031,033 | paper-check/index | W2 | RPT-004 | US-HMW-008 | DONE |
| REQ-HMW-013 | Score Publishing | 034 | paper-check,review | W2 | — | US-HMW-009 | DONE |
| REQ-HMW-014 | Assignment Tracking | 035–038 | assignment/list,show | W5 | — | US-HMW-010 | DONE |
| REQ-HMW-015 | Bulk Download | 039 | submission | — | RPT-004 | — | DONE |
| REQ-HMW-016 | Scheduled Automation | 040–041 | (jobs) | W3 | — | US-HMW-011 | PARTIAL (key mismatch) |
| REQ-HMW-017 | Analytics Dashboard | 042 | analytics/index | — | RPT-001 | — | DONE |
| REQ-HMW-018 | Summary Report | 043 | summary/index | — | RPT-002 | — | DONE |
| REQ-HMW-019 | Submission Listing | 044 | submission/index | — | RPT-003 | — | DONE |
| REQ-HMW-020 | Lifecycle Notifications | 045 | (system) | W2,W3,W5 | — | — | PARTIAL (no targeting) |
| REQ-HMW-021 | Dropdown Helpers | 046 | create/edit (AJAX) | — | — | — | DONE |
| REQ-HMW-022 | Access & Tenant Isolation | 047–049 | all | all | — | US-HMW-012 | PARTIAL (perm mismatch) |

---

# Section C — Requirement Conditions Catalog
> Reuses `BR-HMW-*` IDs (no parallel numbering). Canonical copy to be mirrored at
> `{REQUIREMENT_CONDITIONS}/LmsHomework_Conditions.md` (points back to this file).

| Condition (=BR) | Entity/Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|-----------------|--------------|----------------------|------|---------|------------------------|
| BR-HMW-002 | Homework.due_date | Due after assign | Validation | Save homework | Reject with message |
| BR-HMW-003 | Homework.max/passing marks | Required if gradable; passing ≤ max | Validation | Save homework | Reject with message |
| BR-HMW-007 | Homework.status | Publish only from Draft | Workflow | Publish | Reject (422) |
| BR-HMW-009 | Assignment(homework,student) | Unique per pair | Concurrency | Publish/re-publish | Update, never duplicate |
| BR-HMW-013 | Homework.release_scheduled_date | ≥ assign date | Validation | Save (scheduled) | Reject with message |
| BR-HMW-016 | Clone target | Same class only | Validation | Clone | Reject (422) |
| BR-HMW-018 | Homework | No submissions before delete | Validation | Soft delete | Reject with message |
| BR-HMW-022 | Submission | Text or file present | Validation | Submit | Reject with message |
| BR-HMW-024 | Submission(assignment) | One per assignment | Concurrency | Submit | Reject unless resubmission |
| BR-HMW-028 | Submission late | Deny when policy = deny | Validation | Submit | Should reject (GAP A-FN-1) |
| BR-HMW-031 | Submission.marks | 0 ≤ marks ≤ max | Validation | Grade | Reject with message |
| BR-HMW-035 | Assignment.due_date | Override not earlier | Validation | Edit due date | Reject (422) |
| BR-HMW-036 | Assignment | No assign-date change after release | Validation | Edit assign date | Reject (403) |
| BR-HMW-038 | Assignment late override | Reason required | Validation | Override | Reject |
| BR-HMW-047 | All actions | Permission required | Permission | Any action | Refuse (403) |
| BR-HMW-048 | All data | Per-school isolation | Permission | Any query | Scoped to tenant DB |

---

# Section D — Validation & Edge-Case Catalog
| Field/Rule | Valid | Invalid | Boundary | Empty/Null | Concurrency | Expected |
|------------|-------|---------|----------|------------|-------------|----------|
| Due date | After assign | = or < assign | = assign + 1 min | Missing | — | Reject if not after assign |
| Passing vs Max marks | passing < max | passing > max | passing = max | Both null (non-gradable) | — | Reject if passing > max |
| Marks obtained | 0..max | > max or < 0 | exactly max / exactly 0 | null (ungraded) | Two graders | Reject out of range |
| Submission content | text only / file only / both | neither | 1 char text / 1 byte file | both empty | — | Reject if both empty |
| One submission per assignment | first submit | second submit (no resubmission) | resubmission requested | — | Two simultaneous submits | Lock + reject duplicate |
| Per-student due override | later date | earlier date | equal date | RESET (clear) | — | Reject earlier |
| Assign-date change | before release | after release | at release moment | — | — | Reject after release |
| File upload | pdf/doc/…≤10MB | exe / 11MB | exactly 10MB | no file | — | Reject wrong type/size |
| Late policy | allow → late stored | deny → should block | submit at due moment | no due date → not late | — | Block when deny (GAP) |
| Publish | Draft | Published/Archived | — | no enrolled students → 0 assignments | re-publish | Idempotent |
| Tenant isolation | own school data | cross-school id | — | — | — | Not found / no access |

---

# Section E — Process Flows & State Machines

### W1 — Create → Publish → Assign
Trigger: Teacher creates homework. End: Assignments exist for all students.
1. Teacher fills form → validation (BR-001..006) → saved as Draft.
2. Teacher attaches files (BR-014/015).
3. Teacher publishes → guard: must be Draft (BR-007).
4. System resolves enrolled active students → creates one assignment each (BR-008/009).
5. Release branch by condition (see W3) → homework set Published (BR-010) → count returned.
Exceptions: No current academic year set → block; non-Draft publish → 422; no students → 0 assignments.
Notifications: Step 5 — Student "New Homework Assigned" (W3); recipient targeting currently disabled (A-FN-2).

### W2 — Submit → Grade → Publish Score
Trigger: Student submits. End: Graded (+score published if auto).
1. Submit → assignment located/locked → uniqueness check (BR-024) → late computed (BR-023) → submission saved → assignment status Submitted/Late-Submitted (BR-025).
2. Teacher opens paper-check/review → enters marks/feedback → marks validated (BR-031).
3. Finalize → status Graded, grader/time recorded (BR-032), assignment Graded.
4. If auto-publish-score → score-published time stamped (BR-034) → student "Homework Graded" notification (BR-045).
Exceptions: duplicate submission → rejected; late when policy deny → should block (A-FN-1); marks out of range → rejected.

### W3 — Scheduled / Topic Release
Trigger: Publish with non-immediate condition, or background job.
- Immediate → released, status Assigned (BR-011).
- Scheduled → held Pending Release; nightly release job releases on/after date (BR-040), notifies student.
- On Topic Complete → held Pending Release; should release when syllabus topic completed — **currently dead** (A-FN-3).
Overdue sweep: released, unsubmitted, past-due → Overdue (BR-041).

### W4 — Resubmission
1. Teacher requests resubmission → status Resubmit-Requested (BR-029).
2. Student resubmits → count++, submit time refreshed, late re-evaluated (BR-030), status Submitted/Late.
Exception: resubmission on a finalized/graded item → governed by status guard.

### W5 — Per-Student Due-Date Override & Reminders
1. Teacher edits a student's due date → must not be earlier (BR-035); late override needs reason (BR-038).
2. Toggle release → state/status/time updated (BR-037); assign-date locked after release (BR-036).
3. Send reminder → reminder timestamp set; notification created (BR-045).

### State Machines (config-driven via `sys_dropdowns`, per D29)
**Homework:** Draft → Published → Archived. (Edit allowed only in Draft.)
**Assignment:** Pending Release → Assigned → Viewed → Submitted | Late-Submitted → Graded; Overdue (from Assigned/Viewed if past due, unsubmitted); Exempted (terminal). Illegal: skipping to Graded without a submission.
**Submission:** Submitted → Under Review → Graded; Submitted/Graded → Resubmit-Requested → (resubmit) Submitted/Late-Submitted; Rejected. Terminal-for-display: Graded with score published.

---

# Section F — Data Dictionary

### Business view (default register)
Covered in §A5 (Homework, Assignment, Submission entities with business fields, required flags, privacy).

### Technical view (technical register — for DB Architect / Auditor only)
Three homework-owned tables (`lms_` prefix). Three-way reconciled (DDL v5 ↔ migration ↔ model).

**`lms_homework`** (model `Homework`, `SoftDeletes`, `InteractsWithMedia`):
academic_session_id (FK sch_org_academic_sessions_jnt), class_id (FK sch_classes), section_id (FK sch_sections, NULL=all), subject_id (FK sch_subjects), lesson_id (FK slb_lessons), topic_id (FK slb_topics), schedule_id (FK slb_syllabus_schedule), title, description (LONGTEXT NOT NULL), hw_attachment_media_id (JSON nullable), submission_type_id (FK sys_dropdowns), is_gradable, max_marks(5,2), passing_marks(5,2), difficulty_level_id (FK slb_complexity_level), auto_publish_score, assign_date, due_date, allow_late_submission, **release_condition** (ENUM IMMEDIATE/ON_TOPIC_COMPLETE/ON_SCHEDULED_DATE), release_scheduled_date, status_id (FK sys_dropdowns), is_active, created_by/updated_by (FK sys_users), timestamps, deleted_at.
Anomalies: DDL spells column `realease_condition` (typo) and declares a dangling FK `fk_hw_release_cond → release_condition_id` (nonexistent col); `hw_attachment_media_id` declared `Json UNSIGNED` (invalid); DDL FKs target `sys_dropdown_table` vs migration `sys_dropdowns`. RECONCILE: migration+model authoritative (ENUM `release_condition`, JSON nullable, `sys_dropdowns`).

**`lms_homework_assignment`** (model `HomeworkAssignment`, `SoftDeletes`):
homework_id (FK lms_homework CASCADE), student_id (FK std_students CASCADE), academic_session_id, class_id, section_id (student's actual), subject_id, release_condition (ENUM), release_scheduled_date, is_released, released_at, due_date (override), allow_late_submission (override), late_submission_override_reason/by/at, viewed_at, view_count, student_notified_at, parent_notified_at, reminder_sent_at, status_id (FK sys_dropdowns), assigned_by (FK sys_users), audit cols. UNIQUE(homework_id, student_id). Same dangling `fk_hwa_release_cond` anomaly in DDL.

**`lms_homework_submissions`** (model `HomeworkSubmission`, `SoftDeletes`, `InteractsWithMedia`):
assignment_id (FK lms_homework_assignment CASCADE, **UNIQUE** per DDL CHG-1), homework_id, student_id (FK std_students), submission_text (LONGTEXT), sub_attachment_media_id (JSON), submitted_at, is_late, resubmission_count (TINYINT), status_id (FK sys_dropdowns), is_resubmission_requested (INT NOT NULL, no default — model casts boolean), marks_obtained(5,2), teacher_feedback, graded_by (FK sys_users), graded_at, score_published_at, audit cols.

Dropdown keys (`HomeworkDropdownKeys`): HOMEWORK_STATUS=`lms_homework.status_id`, SUBMISSION_TYPE=`lms_homework.submission_type_id`, ASSIGNMENT_STATUS=`lms_homework_assignment.status_id`, SUBMISSION_STATUS=`lms_homework_submissions.status_id`, ASSIGNMENT_STATUS_ALT=`lms_homework.homework_assignment_status` (inconsistent — A-FN-4).

---

# Section G — Cross-Module Dependency Map (technical register)
**Inbound (this module reads from):**
| Source Module | Data/Entity | Why |
|---------------|-------------|-----|
| SchoolSetup | sch_classes, sch_sections, sch_subjects, sch_org_academic_sessions_jnt, sch_class_section_jnt, sch_subject_groups, sch_class_groups_jnt | Targeting, enrollment, cascading lookups |
| Syllabus | slb_lessons, slb_topics, slb_complexity_level, slb_syllabus_schedule | Content alignment; topic-complete trigger |
| StudentProfile | std_students (+ enrollment) | Resolve students on publish |
| Prime | sys_dropdowns (Dropdown), sys_users, sys_media | Statuses/types, audit FKs, legacy media |

**Outbound (this module feeds):**
| Target Module | Mechanism | What |
|---------------|-----------|------|
| Notification | Creates Notification records on lifecycle events | Assigned/released/due-changed/graded/reminder (targeting disabled — A-FN-2) |
| Scheduler | Console commands | Scheduled release + overdue marking |
| StudentPortal / ParentPortal (planned) | Shared tables | Student submission UI, parent visibility |
| EventEngine (legacy) | Stale model references | Rule-Engine `sys_*` tables (removed from this module) |

---

# Section H — NFR Catalog & Risk Register

### NFR Catalog
| NFR-ID | Category | Requirement | Threshold |
|--------|----------|-------------|-----------|
| NFR-HMW-001 | Performance | List/dashboard load | < 3s @ 500 users |
| NFR-HMW-002 | Performance | Publish to 60-student class | < 10s |
| NFR-HMW-003 | Scalability | LMS file volume (~430K files/yr/tenant per D28) handled via cloud-path storage | No DB blob storage |
| NFR-HMW-004 | Security | Permission-gated actions | 403 on missing permission |
| NFR-HMW-005 | Security | Tenant isolation | Zero cross-tenant visibility |
| NFR-HMW-006 | Compliance | Audit trail on changes | Who + when recorded |
| NFR-HMW-007 | Usability | Mobile-capable core screens | Works on mobile browsers |
| NFR-HMW-008 | Reliability | Per-tenant job isolation | One tenant's failure does not block others |

### Risk Register
| Risk ID | Risk | Cat | Likelihood | Impact | Mitigation | Owner |
|---------|------|-----|------------|--------|------------|-------|
| RISK-HMW-001 | Late submissions accepted when policy says deny (A-FN-1) | Compliance | H | M | Add hard block in submit (BR-028) | Backend |
| RISK-HMW-002 | Notifications created but never delivered (A-FN-2) | UX | H | H | Wire NotificationTarget creation (ENH-006) | Backend |
| RISK-HMW-003 | On-Topic-Completion release never fires (A-FN-3) | Functional | H | M | Fix observer dropdown key/status (ENH-004) | Backend |
| RISK-HMW-004 | Permission-string mismatch form vs controller (A-AUTH-1) | Security | M | H | Standardise to `tenant.home-work*` strings | Backend |
| RISK-HMW-005 | DDL dangling FK / typo would fail a literal DDL run (A-DDL-1/2) | Schema | M | M | Correct DDL v6 to match migration | DB Architect |
| RISK-HMW-006 | Only 1 automated test against 22 REQs | Quality | H | M | Build test suite (Section I S4) | Testing |
| RISK-HMW-007 | Dropdown ALT-key used by jobs may resolve empty (A-FN-4) | Functional | M | M | Standardise to canonical ASSIGNMENT_STATUS key | Backend |

---

# Section I — Prioritization (MoSCoW) & Sprint Task Breakdown

### MoSCoW
- **Must (P0):** REQ-001, 002, 008, 009, 011, 022.
- **Should (P1):** REQ-003, 004, 006, 010, 012, 013, 014, 016, 017, 018, 019, 020.
- **Could (P2):** REQ-005, 007, 015, 021.
- **Won't (this release):** Student/Parent portal UI (owned elsewhere), Rule Engine execution (EventEngine).

### Sprint Task Breakdown (remediation-focused; module is largely built)
| # | Task | Type | Effort (h) | Depends on | Sprint |
|---|------|------|-----------|------------|--------|
| 1 | Enforce late-submission denial at submit (REQ-009/BR-028) | Backend | 4 | — | S1 |
| 2 | Wire notification recipient targeting (REQ-020/ENH-006) | Backend | 8 | Notification | S1 |
| 3 | Align permission strings form↔controller↔policy (REQ-022) | Backend | 4 | — | S1 |
| 4 | Fix On-Topic-Completion observer key/status (REQ-016/ENH-004) | Backend | 6 | Syllabus | S2 |
| 5 | Standardise assignment-status dropdown key in jobs (A-FN-4) | Backend | 3 | — | S2 |
| 6 | Correct DDL v6 (typo, dangling FK, dropdown table name) | Schema | 4 | — | S2 |
| 7 | Remove stale Rule-Engine imports + dev `seedTestData` (A-CODE-1/4) | Backend | 2 | — | S2 |
| 8 | Build Pest suite covering all P0 REQ acceptance criteria | Testing | 24 | 1–6 | S3 |
| 9 | Single-policy binding cleanup for Homework model (A-AUTH-2) | Backend | 2 | — | S3 |
| 10 | Validate/repair API route surface or remove (A-CODE-3) | Backend | 4 | — | S3 |

### Effort Estimation Summary
P0 remediation ≈ 16h · P1 fixes ≈ 19h · Tests ≈ 24h · Cleanup ≈ 8h → **~67h (~8–9 dev-days)** to close known gaps and reach a tested, release-ready state. (Net-new build is mostly complete.)

---

# Section J — User Stories (Gherkin) & KPI Catalog

### User Stories (one per P0/P1 representative REQ)
**US-HMW-001** (REQ-001, P0) — As a Teacher, I want to create a homework so that I can assign it later.
- Scenario happy: Given a current academic year, When I save a homework with all required fields, Then it is stored as Draft.
- Scenario invalid: Given due date ≤ assign date, When I save, Then I see a validation error.
- Scenario permission: Given a user without create permission, When they open create, Then access is refused.
- DoD: Draft created; audited; year auto-set.

**US-HMW-002** (REQ-002, P0) — As a Teacher, I want to publish a homework so that every student gets a copy.
- Happy: Given a Draft and 30 enrolled students, When I publish, Then 30 assignments are created and status = Published.
- Boundary: Given re-publish, When I publish again, Then no duplicate assignments.
- Permission: non-permitted user → refused. DoD: count returned; audited; notification raised.

**US-HMW-004** (REQ-008, P0) — As a Student, I want to submit my homework so the teacher can grade it.
- Happy: Given an assignment, When I submit text or a file before due, Then a submission is stored (not late).
- Invalid: empty text and no file → rejected. Duplicate → rejected unless resubmission. Empty-state: no assignment → cannot submit.

**US-HMW-005** (REQ-009, P0) — As a School, I want late work flagged/blocked per policy.
- Happy: submit after due → late flagged. Deny policy: submit late when deny → should be blocked (GAP). Override: per-student allow → accepted.

**US-HMW-007** (REQ-011, P0) — As a Teacher, I want to grade and give feedback.
- Happy: enter marks ≤ max + feedback → Graded, grader/time recorded, student notified.
- Boundary: marks = max accepted; max+0.01 rejected; negative rejected. Permission: non-permitted → 403.

**US-HMW-010** (REQ-014, P1) — As a Teacher, I want to extend a student's due date.
- Happy: later date accepted with notification. Invalid: earlier date rejected. Edge: after release, assign-date locked.

**US-HMW-011** (REQ-016, P1) — As the System, I release scheduled homework and mark overdue.
- Happy: on release date, assignments → Assigned. Overdue: released, unsubmitted, past-due → Overdue. Isolation: per-tenant.

**US-HMW-012** (REQ-022, P0) — As an Admin, I want data and actions secured per school and role.
- Happy: permitted user proceeds. Permission: missing permission → 403. Isolation: cross-school id → not found.

### KPI Catalog
| KPI | Definition (business) | Source | Target | Cadence |
|-----|-----------------------|--------|--------|---------|
| Submission Rate | Submissions ÷ Assignments × 100 | Assignments + Submissions | ≥ 85% | Weekly |
| On-Time Rate | Non-late submissions ÷ total submissions | Submissions | ≥ 80% | Weekly |
| Grading Turnaround | Avg days from submit to grade | Submissions (submitted_at→graded_at) | ≤ 3 days | Weekly |
| Pending Grading | Submissions without marks | Submissions | Trend ↓ | Daily |
| Resubmission Rate | Resubmission-requested ÷ submissions | Submissions | Monitor | Monthly |

---

# Section K — Feature / Screen Specifications
Aligned to the V1 screen-spec folder `LmsHomework_v2/` and live views.
| Screen | View | Purpose | Key Actions | Permissions |
|--------|------|---------|-------------|-------------|
| Homework Hub (tabbed) | `lmshome-work/index` | Container: analytics, homework, assignments, submissions, summary tabs | Filter, search, navigate | tenant.home-work.viewAny |
| Homework Create/Edit | `home-work/create`,`edit` | Define/edit a homework (cascading class→section→subject→lesson→topic) | Save, attach files, set release | create / update |
| Homework Show | `home-work/show` | Read-only detail with topic chain | View | view |
| Homework Trash | `home-work/trash` | Soft-deleted list | Restore, force delete | restore / forceDelete |
| Assignments List/Show | `assignment/list`,`show` | Per-student tracking & grading form | Override due, toggle release, reminder, grade | viewAny / update |
| Submission List/Create/Edit/Show/Trash | `submission/*` | Manage submissions | Submit, edit, grade (review), restore | home-work-submission.* |
| Paper Check | `paper-check/index` | Annotated evaluation workspace | View files, save check, finalize, recheck, annotate | update |
| Analytics | `analytics/index` | Dashboard metrics & charts | Filter | viewAny |
| Summary | `summary/index` | Per-homework counts | Filter, search | viewAny |
Empty states: each list shows a "no records" state; analytics shows zeros when no data. Layouts: tabbed hub; two-column forms with AJAX-driven dropdowns.

---

# Section L — Anomalies & Module-Knowledge Note
The following confirmed anomalies are catalogued in detail in the module-knowledge file
`AI_Brain/module-knowledge/HMW_LmsHomework.md` (sections "Known Gaps & Open Issues"). Summary:
- **A-DDL-1/2** DDL typo `realease_condition` + dangling `release_condition_id` FK; migration/model authoritative (ENUM `release_condition`).
- **A-DDL-3** DDL `sys_dropdown_table` vs migration `sys_dropdowns` (runtime uses `sys_dropdowns`).
- **A-DDL-4/5/6** `hw_attachment_media_id Json UNSIGNED`; academic_session_id type divergence; `is_resubmission_requested` NOT NULL no default vs boolean cast.
- **A-FN-1** Late submission not hard-blocked when policy denies (BR-028 open).
- **A-FN-2** Notification recipient targeting commented out everywhere → notifications never delivered.
- **A-FN-3** On-Topic-Completion observer matches wrong dropdown key/status → dead.
- **A-FN-4** Assignment-status dropdown ALT key inconsistent; jobs may resolve empty.
- **A-AUTH-1** Permission strings differ: controller/policy `tenant.home-work*` vs FormRequests `tenant.homework*` / `grade-homework`.
- **A-AUTH-2** Homework model bound to 3 policies; only the last wins.
- **A-AUTH-3** EventEngine mis-binds to nonexistent `RuleEngineConfigPolicy` — confirmed NOT inside this module (flagged only).
- **A-CODE-1** Stale Rule-Engine imports (TriggerEvent/ActionType/RuleEngineConfig models do not exist here).
- **A-CODE-2** Module `database/migrations` empty; real migrations are central.
- **A-CODE-3** `routes/api.php` apiResource points at a web/view controller → effectively non-functional.
- **A-CODE-4** `seedTestData()` dev fixture left in production controller.
- **Prefix sharing:** only `lms_homework`, `lms_homework_assignment`, `lms_homework_submissions` are HMW-owned; the `sys_*` Rule-Engine tables are EventEngine/SystemConfig.

---

## Document Control
| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-06-29 | Initial Complete Analysis Pack (FRD + RTM + Conditions + Validation + FSM + Data Dictionary + Dependency Map + NFR/Risk + Prioritization/Sprint + Stories/KPI + Screens + Anomalies). Seeded from live code, DDL v5, migrations, V2 + V1. | Business Analysis — Prime-AI |

*This file is the single source of truth for LmsHomework requirements. All gap analyses, completion scoring, and test coverage must reference these REQ-/BR-/RPT-/ENH- IDs and the §A10 totals (denominators).*
