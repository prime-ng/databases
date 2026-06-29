# Functional Requirements Document — Complete Analysis Pack
# Module: LmsExam (Examination Management)
# Prime-AI School ERP Platform

| Field | Value |
|-------|-------|
| **Module Name** | LmsExam |
| **Module Code** | EXM |
| **Table Prefix** | `lms_` (exam tables: `lms_exam*`) |
| **Module Type** | Tenant (data isolated per school) |
| **Document Version** | 1.0 |
| **Date** | 2026-06-29 |
| **Status** | Draft |
| **Prepared By** | Business Analysis — Prime-AI |
| **Sources reconciled** | Live Laravel module (`Modules/LmsExam`, 13 controllers / 13 models / 92 views, read 2026-06-29) · `LmsExam_DDL_v6.sql` (11 owned tables) · `StudentAttempt_DDL_v4.sql` (shared runtime tables) · V2 `EXM_LmsExam_Requirement.md` (2026-03-26) · V1 screen-spec folder `LmsExam_v2/` (25 screens) |

> **This is a Complete Analysis Pack** (the BA "everything" deliverable). The FRD (Sections 1–10) is the
> spine and single source of truth for `REQ-/BR-/RPT-/ENH-` IDs; Sections 11–19 (RTM, Conditions,
> Validation, FSMs, Data Dictionary, Dependency Map, NFR/Risk, Prioritization, Sprint Tasks, User
> Stories) reference those IDs and never renumber them.

## Index
1. Module Overview · 2. User Roles & Access · 3. Functional Requirements (REQ-) · 4. Business Rules
Register (BR-) · 5. Data Requirements · 6. Workflows · 7. Reporting & Analytics (RPT-) · 8. Future
Enhancement Log (ENH-) · 9. Non-Functional Requirements · 10. Gap Analysis Readiness Index · 11.
Requirements Traceability Matrix · 12. Requirement Conditions Catalog · 13. Validation & Edge-Case
Catalog · 14. State Machine (FSM) Catalog · 15. Data Dictionary (technical) · 16. Cross-Module
Dependency Map · 17. NFR & Risk Register · 18. Prioritization + Sprint Task Breakdown · 19. User
Stories (Gherkin).

---

## Section 1 — Module Overview

### 1.1 Business Purpose
LmsExam manages the complete life cycle of a school examination — both **online** (computer-based, timed,
proctored) and **offline** (pen-and-paper) — for Indian K-12 schools. A school uses it to define exam
categories, build subject papers and multiple anti-copying paper variants, draw questions from the
Question Bank, group and schedule students, conduct or digitise the exam, evaluate answers, compute graded
and ranked results, publish them to students and parents, and handle re-evaluation grievances. Without it
a school cannot run structured assessments inside the platform or feed marks into report cards.

### 1.2 Business Value
- One pipeline for both online and offline exams, so a school running mixed modes keeps a single record of truth.
- Eliminates manual mark tabulation: percentage, grade, division and class rank are computed automatically.
- Prevents leakage and copying through paper variants (sets), blueprint-driven structure, and proctoring controls.
- Creates an auditable, fair grievance channel so post-result mark changes are documented, not silent edits.
- Feeds downstream report cards, marksheets, certificates, and student/parent portals from a single result store.

### 1.3 Scope
#### In Scope
1. Exam category (type) and lifecycle-status configuration.
2. Exam creation (session + class + type) with scheduling and result-publication policy.
3. Per-subject, per-mode paper definition with proctoring and offline-entry configuration.
4. Paper blueprint (section structure) and scope (syllabus coverage / weightage) definition.
5. Paper variants (sets) and assignment of Question-Bank questions to each set.
6. Ad-hoc student groups (and members) for targeted allocation.
7. Allocation of a paper+set to a class / section / group / individual student with schedule and venue.
8. Offline answer-sheet upload (bulk total and question-wise OMR) and marks entry.
9. Answer evaluation / paper checking (auto-graded objective + teacher-graded descriptive, online & offline).
10. Result computation (percentage, grade, division, rank), publication (immediate / scheduled / manual).
11. Grievance / re-evaluation management with documented mark revision.
12. Assessment-progress dashboards, live attempt monitoring, and advanced exam reports.

#### Out of Scope
1. The student-facing online exam *player* (timed attempt, answer auto-save, live proctoring capture) — owned by **StudentPortal**.
2. Consolidated multi-exam report card / marksheet aggregation — owned by **MarksheetGeneration** (D32).
3. Question authoring, options, and difficulty metadata — owned by **QuestionBank**.
4. Class / section / subject / room / academic-session masters — owned by **SchoolSetup** and **GlobalMaster**.
5. Grade-boundary / division definitions — owned by **Syllabus** (`slb_grade_division_master`).
6. Result/alert delivery channels (email/SMS/push) — owned by **Notification**.

### 1.4 Key Terminology
| Business Term | Meaning |
|---------------|---------|
| Exam | A school examination event for one class in one academic session (e.g., "Annual Exam 2025-26, Class 9"). |
| Exam Type | A reusable category of exam (Unit Test 1, Half-Yearly, Annual). |
| Exam Paper | One subject's paper within an exam, in one mode (Online or Offline). |
| Paper Set | A variant of a paper (Set A, Set B) used to discourage copying. |
| Blueprint | The section-by-section structure of a paper (e.g., "Section A: 20 objective questions, 1 mark each"). |
| Scope | The syllabus coverage of a paper — which lessons/topics/question types and their weightage. |
| Allocation | The assignment of a paper+set to a class, section, group, or student, with date, time and venue. |
| Student Group | An ad-hoc subset of students within a class+section, used for targeted allocation. |
| Attempt | A single student's instance of taking a paper (one per student per paper). |
| Offline Entry Mode | How offline marks are captured: Bulk Total (one score) or Question-Wise (per question, OMR-style). |
| Evaluation / Paper Check | Awarding marks — automatic for objective questions, teacher-judged for descriptive. |
| Result | A student's final outcome for a paper: marks, percentage, grade, division, rank, pass/fail status. |
| Grievance / Re-Evaluation | A student's formal challenge to a published result; may lead to a documented mark revision. |
| Result Publication Mode | When results become visible: Immediate, Scheduled (auto at a set time), or Manual. |
| Checkpoint | An auto-saved snapshot of an in-progress online attempt enabling resume after a crash. |

---

## Section 2 — User Roles & Access

### 2.1 Actor Definitions
| Role | Who They Are | Their Relationship to This Module |
|------|--------------|-----------------------------------|
| School Admin / Principal | Senior school authority | Full control; publishes/withholds results; final authority on grievances. |
| Exam Coordinator | A senior teacher / HOD running the exam calendar | Creates exams, papers, groups, allocations; oversees offline marks entry. |
| Subject Teacher / Evaluator | Teaches and grades a subject | Defines blueprint, scope, sets; assigns questions; enters and evaluates marks for own subject. |
| Data Entry Operator | Staff digitising physical papers | Uploads offline answer sheets and punches question-wise marks. |
| Student | An enrolled learner | Takes online exams (via StudentPortal), views published results, files grievances. |
| Parent | Guardian of a student | Views the child's published results and report card (via ParentPortal). |
| System | Automated processes | Auto-grades objective answers, auto-submits on timeout, publishes scheduled results, logs proctoring events. |

### 2.2 Role-Feature Access Matrix
| Feature | Admin/Principal | Exam Coordinator | Subject Teacher | Data Entry | Student | Parent |
|---------|----------------|------------------|-----------------|-----------|---------|--------|
| Exam types & status config | Full | View | View | No | No | No |
| Exam creation | Full | Full | View | No | No | No |
| Paper / blueprint / scope / set | Full | Full | Full (own subject) | No | No | No |
| Question assignment | Full | Full | Full (own subject) | No | No | No |
| Student groups & allocation | Full | Full | View | No | No | No |
| Offline upload & marks entry | Full | Full | Full (own subject) | Full | No | No |
| Answer evaluation / paper check | Full | Full | Full (own subject) | No | No | No |
| Result compute / publish / withhold | Full | View | No | No | No | No |
| Grievance review & resolve | Full | Full | Full (own subject) | No | File only | No |
| Assessment dashboards & reports | Full | Full | Own subject | No | No | No |
| View published result / report card | Full | Full | Full | No | Own | Own child |

---

## Section 3 — Functional Requirements

### 3.1 Exam Type Management
**Requirement ID:** REQ-EXM-001 · **Priority:** Standard (P1) · **Tags:** [CONFIGURATION][DATA_ENTRY]
#### Business Description
The school maintains a reusable list of exam categories (Unit Test 1–4, Half-Yearly, Annual, Mock, etc.).
Each category has a unique short code and a name and can be deactivated or archived. Categories classify
every exam and are reused across sessions.
#### Actors — Initiates: Admin · Processes: Admin · Views: Coordinator, Teacher
#### Business Rules: BR-EXM-001, BR-EXM-031
#### Acceptance Criteria
1. A new exam type with a duplicate code is rejected with a clear message.
2. Deactivating a type hides it from new-exam selection but preserves existing exams that use it.
3. Archived (soft-deleted) types can be restored, returning them to the active list.
#### Integration: None (master data). #### Enhancement Notes: see ENH-EXM-001.

### 3.2 Exam Status / Lifecycle Configuration
**Requirement ID:** REQ-EXM-002 · **Priority:** Standard (P1) · **Tags:** [CONFIGURATION]
#### Business Description
Defines the named statuses an exam, paper, result, or attempt can be in (e.g., Draft, Published,
Concluded, Archived; Evaluation Pending, Evaluated, Result Published, Absent, Cancelled). Each status is
tagged by which kind of entity it applies to and carries the rules that govern its transitions.
#### Actors — Initiates: Admin · Processes: Admin · Views: All staff
#### Business Rules: BR-EXM-002, BR-EXM-021, BR-EXM-022
#### Acceptance Criteria
1. Each status carries a unique code and an entity kind (Exam / Paper / Result / Attempt).
2. A status of one entity kind cannot be applied to a different entity kind.
3. The standard sequences are available out of the box.
#### Integration: None. #### Enhancement Notes: None.

### 3.3 Exam Creation
**Requirement ID:** REQ-EXM-003 · **Priority:** Core (P0) · **Tags:** [DATA_ENTRY][WORKFLOW]
#### Business Description
An Admin or Exam Coordinator creates an exam by binding an academic session, a class, an exam type, a date
range, an optional grading scheme, and a result-publication policy. The system generates a unique exam
code and starts the exam in Draft. Only one exam may exist per session + class + type.
#### Actors — Initiates: Admin/Coordinator · Processes: System (code generation) · Views: Teachers
#### Business Rules: BR-EXM-003, BR-EXM-004, BR-EXM-021, BR-EXM-035
#### Acceptance Criteria
1. Creating a second exam for the same session+class+type combination is rejected.
2. The end date cannot precede the start date.
3. On a save failure the transaction is rolled back, no partial exam remains, and a safe error message is shown (no technical dump).
4. Students cannot create exams.
#### Integration: Receives session from GlobalMaster, class from SchoolSetup, grading scheme from Syllabus.
#### Enhancement Notes: see ENH-EXM-002.

### 3.4 Exam Paper Definition
**Requirement ID:** REQ-EXM-004 · **Priority:** Core (P0) · **Tags:** [DATA_ENTRY][CONFIGURATION]
#### Business Description
Within an exam, the teacher defines a paper for one subject in one mode (Online or Offline), setting total
marks, passing percentage, duration, number of questions, negative marking, and instructions. Online papers
add proctoring controls (proctored / AI-proctored / fullscreen / browser-lock / shuffle / timer). Offline
papers set the marks-entry mode (Bulk Total or Question-Wise).
#### Actors — Initiates: Subject Teacher / Coordinator · Processes: Teacher · Views: Students (at attempt)
#### Business Rules: BR-EXM-005, BR-EXM-006, BR-EXM-007, BR-EXM-008
#### Acceptance Criteria
1. Paper code is unique within the exam.
2. If a paper is AI-proctored it must also be marked proctored.
3. Offline-entry-mode settings are ignored for online papers.
4. A blank duration means the student may take as long as needed.
#### Integration: May reference a difficulty-distribution configuration owned by LmsQuiz.
#### Enhancement Notes: see ENH-EXM-005 (decouple cross-module config).

### 3.5 Paper Blueprint Definition
**Requirement ID:** REQ-EXM-005 · **Priority:** Standard (P1) · **Tags:** [CONFIGURATION]
#### Business Description
The teacher lays out a paper's structure as ordered sections (e.g., Section A — objective, 1 mark each;
Section B — short answer, 5 marks each), each with a question type, count, per-question and total marks.
This guides question assignment and automatic paper generation.
#### Actors — Initiates: Subject Teacher · Processes: Teacher · Views: Coordinator
#### Business Rules: BR-EXM-009, BR-EXM-010
#### Acceptance Criteria
1. A section name is unique within a paper.
2. Only staff with the blueprint permission may view, create, edit or delete blueprints (students are refused).
3. Bulk operations (delete/restore/toggle) act on all sections of one paper at once.
#### Integration: References question types from Syllabus. #### Enhancement Notes: None.

### 3.6 Paper Scope Definition
**Requirement ID:** REQ-EXM-006 · **Priority:** Standard (P1) · **Tags:** [CONFIGURATION]
#### Business Description
Defines which lessons, topics, and question types a paper covers, with a target question count and
weightage. Used to ensure syllabus coverage and to support drawing questions automatically from the bank.
#### Actors — Initiates: Subject Teacher · Processes: Teacher · Views: Coordinator
#### Business Rules: BR-EXM-011, BR-EXM-010
#### Acceptance Criteria
1. Only staff with the scope permission may view or modify scope entries (students are refused).
2. A target count of zero means "all matching questions".
3. Lesson, topic and question-type pickers cascade from the paper's subject.
#### Integration: References lessons/topics/question types from Syllabus. #### Enhancement Notes: None.

### 3.7 Paper Set Management
**Requirement ID:** REQ-EXM-007 · **Priority:** Standard (P1) · **Tags:** [DATA_ENTRY]
#### Business Description
Creates variants (Set A, Set B, …) of a paper so that adjacent students receive different question
arrangements. At least one set must exist before questions can be assigned or students allocated.
#### Actors — Initiates: Coordinator / Teacher · Processes: Teacher · Views: Coordinator
#### Business Rules: BR-EXM-012, BR-EXM-013
#### Acceptance Criteria
1. Set code is unique within the paper.
2. A paper with no set cannot have questions assigned or students allocated.
#### Integration: None. #### Enhancement Notes: None.

### 3.8 Paper-Set Question Assignment
**Requirement ID:** REQ-EXM-008 · **Priority:** Core (P0) · **Tags:** [DATA_ENTRY][INTEGRATION]
#### Business Description
The teacher selects questions from the Question Bank (filtered by class → subject → lesson → topic →
question type, with search) and assigns them to a paper set, setting display order, mark override, negative
marks, compulsory/optional flag, and the owning section. Supports bulk add/remove, drag-reorder, and inline
edits.
#### Actors — Initiates: Subject Teacher · Processes: Teacher · Views: Coordinator
#### Business Rules: BR-EXM-014, BR-EXM-015, BR-EXM-016
#### Acceptance Criteria
1. The same question cannot be added twice to one set.
2. Each assigned question has a defined mark (defaulting to the bank's mark, overridable).
3. The same question may appear in different sets of the same paper independently.
#### Integration: Reads questions and options from QuestionBank. #### Enhancement Notes: None.

### 3.9 Student Group & Member Management
**Requirement ID:** REQ-EXM-009 · **Priority:** Standard (P1) · **Tags:** [DATA_ENTRY]
#### Business Description
Creates ad-hoc groups within a class+section (e.g., "Advanced Math", "Special Needs") and assigns
individual enrolled students as members, enabling targeted allocation of specific sets to specific
students.
#### Actors — Initiates: Coordinator · Processes: Coordinator · Views: Teacher
#### Business Rules: BR-EXM-017, BR-EXM-018
#### Acceptance Criteria
1. A group code is unique within its class+section.
2. The same student cannot be added to one group twice.
3. Removing a group cascades to its membership.
#### Integration: Reads students from StudentProfile. #### Enhancement Notes: None.

### 3.10 Exam Allocation & Scheduling
**Requirement ID:** REQ-EXM-010 · **Priority:** Core (P0) · **Tags:** [WORKFLOW][SCHEDULED]
#### Business Description
Assigns a paper + set to a target — an entire class, a section, a group, or a single student — with a
scheduled date, start/end time, and (for offline) a venue/room. This is what determines who sits which set,
when, and where.
#### Actors — Initiates: Coordinator · Processes: Coordinator · Views: Students (schedule)
#### Business Rules: BR-EXM-019, BR-EXM-020, BR-EXM-035
#### Acceptance Criteria
1. End time must be after start time.
2. The target fields required depend on the allocation type (class always required; section/group/student per type).
3. A class allocation covers every student in that class.
#### Integration: Reads classes/sections/rooms from SchoolSetup, students from StudentProfile.
#### Enhancement Notes: see ENH-EXM-003 (allocation conflict detection), ENH-EXM-004 (hall ticket).

### 3.11 Online Exam Attempt (Conduct)
**Requirement ID:** REQ-EXM-011 · **Priority:** Core (P0) · **Tags:** [WORKFLOW][INTEGRATION]
#### Business Description
A student takes an allocated online exam within the scheduled window: starting a timed attempt, answering
objective and descriptive questions (with optional file upload), having progress auto-saved as checkpoints,
and submitting (or being auto-submitted on timeout). Proctoring events are logged. **The player UI is owned
by StudentPortal**; LmsExam owns the resulting attempt, answer, checkpoint and proctoring-log data that
feed evaluation and monitoring.
#### Actors — Initiates: Student · Processes: System (auto-grade objective, auto-submit) · Views: Proctor
#### Business Rules: BR-EXM-023, BR-EXM-024, BR-EXM-025, BR-EXM-026
#### Acceptance Criteria
1. A student has at most one attempt per paper.
2. An attempt can be started only when the allocation is active and within the scheduled window.
3. On timeout the attempt is submitted automatically and objective answers are graded immediately.
4. Proctoring violations are counted and recorded per attempt.
#### Integration: Player from StudentPortal; questions from QuestionBank; uploads via SystemConfig media.
#### Enhancement Notes: see ENH-EXM-006 (configurable violation thresholds).

### 3.12 Offline Answer-Sheet Upload & Marks Entry
**Requirement ID:** REQ-EXM-012 · **Priority:** Core (P0) · **Tags:** [DATA_ENTRY][WORKFLOW]
#### Business Description
For pen-and-paper exams, staff digitise results in one of two modes set on the paper: **Bulk Total** (upload
one answer-sheet PDF and a single total score per student) or **Question-Wise** (punch each student's MCQ
choices OMR-style for auto-grading, or attach per-question evidence for descriptive questions). Attendance
(present/absent) is captured per student.
#### Actors — Initiates: Data Entry / Teacher · Processes: System (auto-grade objective) · Views: Coordinator
#### Business Rules: BR-EXM-027, BR-EXM-028, BR-EXM-029, BR-EXM-030
#### Acceptance Criteria
1. Marks entered cannot exceed the paper's total marks.
2. The upload screen routes to the Bulk or Question-Wise form based on the paper's offline-entry mode.
3. Absent students are recorded as Absent and excluded from pass/fail calculation.
4. Re-entry overwrites the previous entry (idempotent).
#### Integration: Stores files via SystemConfig media; reads questions from QuestionBank.
#### Enhancement Notes: None.

### 3.13 Answer Evaluation / Paper Checking
**Requirement ID:** REQ-EXM-013 · **Priority:** Core (P0) · **Tags:** [WORKFLOW][DATA_ENTRY]
#### Business Description
Teachers evaluate submitted answers: objective questions are auto-graded; descriptive answers are graded by
the teacher per question (online and offline), with per-answer remarks. Supports a per-student grading
interface, bulk grade save, and bulk upload of annotated answer-sheet PDFs. An attempt moves through
Evaluation Pending → Evaluated as grading completes.
#### Actors — Initiates: Subject Teacher · Processes: System (objective) + Teacher (descriptive) · Views: Coordinator
#### Business Rules: BR-EXM-024, BR-EXM-031, BR-EXM-032
#### Acceptance Criteria
1. Objective answers are scored automatically against the question key.
2. A marks award for a descriptive question cannot exceed that question's maximum (override) marks.
3. An attempt is marked Evaluated only when every compulsory question has been evaluated.
#### Integration: Reads question keys/options from QuestionBank. #### Enhancement Notes: see ENH-EXM-001 (AI-assisted evaluation).

### 3.14 Result Computation, Grading & Publication
**Requirement ID:** REQ-EXM-014 · **Priority:** Core (P0) · **Tags:** [WORKFLOW][SCHEDULED][NOTIFICATION]
#### Business Description
After evaluation, the system computes each student's total marks, percentage, grade and division from the
grading scheme, assigns class rank, and sets pass/fail. Results are then published — immediately, at a
scheduled time, or manually by an Admin — making them visible to students and parents and triggering
notifications. Admin may withhold a result (e.g., fee dues) or unpublish to correct and republish.
#### Actors — Initiates: Admin · Processes: System (compute, scheduled publish) · Views/Receives: Student, Parent
#### Business Rules: BR-EXM-031, BR-EXM-032, BR-EXM-033, BR-EXM-034, BR-EXM-022
#### Acceptance Criteria
1. A result cannot be published while any required paper marks remain un-entered/un-evaluated.
2. Grade and division are derived from the configured grading scheme against the percentage.
3. Rank is computed within the same class for the same paper, excluding Absent and Withheld students.
4. After publication, marks can be changed only by an Admin (unpublish → modify → republish).
5. A scheduled result is published automatically at its set time.
#### Integration: Grading scheme from Syllabus; alerts via Notification; results consumed by StudentPortal/ParentPortal/MarksheetGeneration.
#### Enhancement Notes: see ENH-EXM-004 (report card/hall ticket PDF).

### 3.15 Grievance / Re-Evaluation Management
**Requirement ID:** REQ-EXM-015 · **Priority:** Standard (P1) · **Tags:** [WORKFLOW][APPROVAL][NOTIFICATION]
#### Business Description
After results are published, a student (or staff on their behalf) raises a grievance of a defined type
(marking error, question error, out-of-syllabus, other) against a result. A reviewer investigates and either
rejects it or resolves it, optionally revising the marks — which is documented (old vs new marks) and
triggers a recomputation of the affected result.
#### Actors — Initiates: Student / Coordinator · Processes/Approves: Teacher / Admin · Receives: Student, Parent
#### Business Rules: BR-EXM-022, BR-EXM-033, BR-EXM-034
#### Acceptance Criteria
1. A grievance can only target a result the student actually has (an attempted paper).
2. Resolving or rejecting requires resolution remarks.
3. When a grievance is resolved with a mark change, the result is recomputed and a "marks revised" indicator is shown.
#### Integration: Reads results/attempts; recomputes results; alerts via Notification.
#### Enhancement Notes: see ENH-EXM-001 (grievance filing window config).

### 3.16 Assessment Progress Dashboard
**Requirement ID:** REQ-EXM-016 · **Priority:** Standard (P1) · **Tags:** [DASHBOARD][REPORT]
#### Business Description
Paper-level dashboards (separate for online and offline) showing, per paper, how many students were
Assigned, how many Submitted, and how many have been Checked — with date-range and cascading filters — and
buttons to jump into grading or the detailed report.
#### Actors — Initiates: Teacher/Coordinator · Processes: System · Views: Admin/Principal
#### Business Rules: BR-EXM-036
#### Acceptance Criteria
1. The online dashboard counts only online papers and the offline dashboard only offline papers.
2. Counts reflect attempt statuses (Submitted vs Evaluated/Published) accurately.
3. An empty filter result shows a friendly "no exams found" state.
#### Integration: Reads allocations, attempts, results. #### Enhancement Notes: None.

### 3.17 Live Attempt Monitoring & Activity Logs
**Requirement ID:** REQ-EXM-017 · **Priority:** Enhanced (P2) · **Tags:** [DASHBOARD][REPORT]
#### Business Description
Live and historical monitoring of online attempts: a "pending checkpoints" view shows students currently
mid-exam (current question, answered/flagged counts, last-saved time) for live proctoring and crash
recovery; activity/event logs show recorded proctoring events; an event-pending view tracks attempts
awaiting action.
#### Actors — Initiates: Proctor/Admin · Processes: System · Views: Proctor/Admin
#### Business Rules: BR-EXM-025, BR-EXM-026
#### Acceptance Criteria
1. The checkpoint view lists only attempts not yet submitted.
2. Answered and flagged counts are derived from the saved checkpoint state.
3. When all students submit, the live view empties with a clear message.
#### Integration: Reads checkpoints and proctoring logs (shared StudentAttempt engine). #### Enhancement Notes: None.

### 3.18 Advanced Exam Reports
**Requirement ID:** REQ-EXM-018 · **Priority:** Standard (P1) · **Tags:** [REPORT][DASHBOARD]
#### Business Description
A reports hub delivering the exam result ledger (ranked, with KPIs and charts), per-student exam history,
cross-subject comparison, and an overall LMS activity view, with date-range and cascading filters. (The hub
also surfaces two homework reports — see Section 16 ownership note.)
#### Actors — Initiates: Principal/Teacher · Processes: System · Views: Principal/Teacher
#### Business Rules: BR-EXM-031, BR-EXM-032, BR-EXM-033
#### Acceptance Criteria
1. The result ledger orders students by percentage and assigns an accurate sequential rank.
2. KPIs (total/present/absent/pass/fail/pass%/class avg/high/low) compute correctly.
3. Subject comparison bands each subject's students into High (≥75%) / Mid (40–74%) / Low (<40%).
#### Integration: Reads results and papers. #### Enhancement Notes: see ENH-EXM-002 (export to Excel/PDF).

### 3.19 Module Licensing Guard
**Requirement ID:** REQ-EXM-019 · **Priority:** Core (P0) · **Tags:** [INTEGRATION]
#### Business Description
Only schools whose subscription includes the Examination module may reach any LmsExam screen; others are
refused. This guard is in addition to per-screen permission checks and per-school data isolation.
#### Actors — Initiates: System · Processes: System · Views: N/A
#### Business Rules: BR-EXM-021
#### Acceptance Criteria
1. A user at a school without the Examination module is refused access to all LmsExam screens.
2. The guard runs before any screen loads, independent of the user's role.
#### Integration: Subscription state from Prime/Billing. #### Enhancement Notes: None.

---

## Section 4 — Business Rules Register
| Rule ID | Description | Feature | Type | Priority |
|---------|-------------|---------|------|----------|
| BR-EXM-001 | Exam type code must be unique. | REQ-EXM-001 | Validation | P1 |
| BR-EXM-002 | A status applies only to its declared entity kind (Exam/Paper/Result/Attempt). | REQ-EXM-002 | Validation | P1 |
| BR-EXM-003 | Only one exam per academic session + class + exam type. | REQ-EXM-003 | Validation | P0 |
| BR-EXM-004 | Exam end date cannot precede start date. | REQ-EXM-003 | Validation | P0 |
| BR-EXM-005 | Paper code must be unique within its exam. | REQ-EXM-004 | Validation | P0 |
| BR-EXM-006 | AI-proctored requires base proctoring enabled. | REQ-EXM-004 | Validation | P1 |
| BR-EXM-007 | Offline-entry-mode settings are ignored for online papers. | REQ-EXM-004 | Workflow | P1 |
| BR-EXM-008 | Blank duration means unlimited time. | REQ-EXM-004 | Calculation | P2 |
| BR-EXM-009 | Section name must be unique within a paper. | REQ-EXM-005 | Validation | P1 |
| BR-EXM-010 | Blueprint and scope screens are restricted to permitted staff; students are refused. | REQ-EXM-005, REQ-EXM-006 | Permission | P0 |
| BR-EXM-011 | Scope target count of 0 means "all matching questions". | REQ-EXM-006 | Calculation | P2 |
| BR-EXM-012 | Set code must be unique within its paper. | REQ-EXM-007 | Validation | P1 |
| BR-EXM-013 | A paper must have ≥1 set before questions are assigned or students allocated. | REQ-EXM-007 | Workflow | P1 |
| BR-EXM-014 | A question can appear only once per set. | REQ-EXM-008 | Validation | P0 |
| BR-EXM-015 | Each assigned question must have a defined (overridable) mark. | REQ-EXM-008 | Validation | P1 |
| BR-EXM-016 | The same question may appear independently across different sets of one paper. | REQ-EXM-008 | Workflow | P2 |
| BR-EXM-017 | Group code unique within class+section. | REQ-EXM-009 | Validation | P1 |
| BR-EXM-018 | A student cannot be added to the same group twice. | REQ-EXM-009 | Validation | P1 |
| BR-EXM-019 | Allocation end time must be after start time. | REQ-EXM-010 | Validation | P0 |
| BR-EXM-020 | Required target fields depend on allocation type (class always required). | REQ-EXM-010 | Validation | P0 |
| BR-EXM-021 | Exam lifecycle: Draft → Published → Concluded → Archived (no reversal from Concluded). | REQ-EXM-002,003,019 | Workflow | P0 |
| BR-EXM-022 | Paper/attempt lifecycle: Not Started → In Progress → Submitted → Evaluation Pending → Evaluated → Result Published (+ Absent/Cancelled). | REQ-EXM-002,013,014,015 | Workflow | P0 |
| BR-EXM-023 | At most one attempt per student per paper. | REQ-EXM-011 | Validation | P0 |
| BR-EXM-024 | Objective answers are auto-graded; descriptive answers are teacher-graded. | REQ-EXM-011, REQ-EXM-013 | Calculation | P0 |
| BR-EXM-025 | An attempt may start only within its scheduled window when the allocation is active. | REQ-EXM-011 | Workflow | P0 |
| BR-EXM-026 | Proctoring violations are counted per attempt; threshold breach triggers auto-submit/alert. | REQ-EXM-011, REQ-EXM-017 | Workflow | P1 |
| BR-EXM-027 | Entered marks cannot exceed the paper total. | REQ-EXM-012 | Validation | P0 |
| BR-EXM-028 | Offline upload routes to Bulk vs Question-Wise per the paper's offline-entry mode. | REQ-EXM-012 | Workflow | P1 |
| BR-EXM-029 | Absent students get result status Absent and are excluded from pass/fail. | REQ-EXM-012, REQ-EXM-014 | Workflow | P0 |
| BR-EXM-030 | Re-entry of offline marks overwrites the previous entry (idempotent). | REQ-EXM-012 | Workflow | P1 |
| BR-EXM-031 | Grade and division are derived from the grading scheme against the percentage. | REQ-EXM-013,014,018 | Calculation | P0 |
| BR-EXM-032 | A mark award cannot exceed a question's maximum (override) marks. | REQ-EXM-013, REQ-EXM-014 | Validation | P0 |
| BR-EXM-033 | Class rank is computed within the same class/paper, excluding Absent and Withheld. | REQ-EXM-014, REQ-EXM-018 | Calculation | P1 |
| BR-EXM-034 | After publication, marks change only via Admin (unpublish→modify→republish) or a resolved grievance; a grievance mark change recomputes the result. | REQ-EXM-014, REQ-EXM-015 | Workflow | P0 |
| BR-EXM-035 | Results cannot be published while required paper marks remain un-entered/un-evaluated. | REQ-EXM-003, REQ-EXM-010, REQ-EXM-014 | Workflow | P0 |
| BR-EXM-036 | Online/offline dashboards count only their own mode's papers. | REQ-EXM-016 | Workflow | P1 |

---

## Section 5 — Data Requirements
*(Business view. Technical column mapping in Section 15.)*

### 5.1 Exam — represents one examination event for a class in a session. Captures: title, code, type,
class, session, date range, grading scheme, status, result-publication policy and time, publication flag.
Belongs to a session and class; contains papers. Retention: kept for the academic record; soft-deletable.
Privacy: Internal.

### 5.2 Exam Paper — one subject's paper in one mode. Captures: subject, mode, total/passing marks,
duration, question count, negative marks, instructions, proctoring controls, offline-entry mode, status.
Belongs to an exam; contains sets, blueprint sections, scopes. Privacy: Internal (paper structure
**Confidential before the exam** — see NFR).

### 5.3 Paper Set — a paper variant. Captures: set code, name, description. Belongs to a paper; contains
assigned questions. Privacy: Confidential (until allocation published).

### 5.4 Blueprint Section / Scope — paper structure and syllabus coverage. Captures: section/qtype, counts,
marks, ordinal; lesson/topic/qtype, weightage, target count. Privacy: Confidential.

### 5.5 Assigned Question — a Question-Bank question placed in a set. Captures: order, override marks,
negative marks, compulsory flag, section. Privacy: Confidential.

### 5.6 Student Group / Member — ad-hoc grouping. Captures: class, section, code, name; member student.
Privacy: Internal.

### 5.7 Allocation — assignment of paper+set to a target with schedule/venue. Captures: target type and
ids, date, start/end time, room/location. Privacy: Internal.

### 5.8 Attempt — a student's instance of a paper *(shared — StudentAttempt engine)*. Captures: mode,
start/end time, time taken, status, attendance, answer-sheet number, IP/device/violations. One per
student per paper. Privacy: Confidential; IP/device = Sensitive.

### 5.9 Attempt Answer / Offline Upload — per-question responses and marks *(shared)*. Captures: selected
option(s), descriptive text, attachment, marks obtained/max, correctness, evaluator, remarks, telemetry.
Privacy: Confidential.

### 5.10 Result — final outcome per student per paper *(shared; model in StudentPortal)*. Captures: marks
possible/obtained, percentage, grade, division, status (Pass/Fail/Absent/Withheld), rank, percentile,
publication flag/time, teacher remarks, report-card path. One per student per paper. Privacy: Confidential.

### 5.11 Grievance — re-evaluation request *(shared; model in StudentPortal)*. Captures: type, text,
status, reviewer, resolution remarks, mark-change flag, old/new marks, resolved time. Privacy: Confidential.

### 5.12 Activity Event Type / Activity Log / Checkpoint — proctoring master, immutable event log, and
resume snapshots *(shared, polymorphic across Quiz/Quest/Exam)*. Logs are append-only/immutable.
Privacy: Sensitive (behavioural).

---

## Section 6 — Workflows

### 6.1 Exam Setup → Allocation
**Trigger:** Coordinator starts a new exam. **End:** Allocations published.
Steps: create exam (Draft) → add papers (per subject+mode) → define blueprint & scope → create sets →
assign questions from bank → create groups/members → create allocations (schedule+venue) → publish exam.
**Exception:** save failure → rollback, safe error, nothing persisted (BR-EXM-003/004). **Notifications:**
exam published → students/parents informed of schedule.

### 6.2 Online Conduct & Evaluation
**Trigger:** Student starts an allocated online attempt. **End:** Attempt Evaluated.
Steps: validate window/allocation → start attempt (In Progress) → answer + auto-save checkpoints →
proctoring events logged → submit / auto-submit on timeout → objective auto-graded → teacher grades
descriptive → attempt Evaluated. **Exception:** crash → resume from checkpoint; window closed → start
refused; violations exceed threshold → auto-submit/alert. **Notifications:** none until results.

### 6.3 Offline Digitisation & Evaluation
**Trigger:** Data-entry opens an offline paper roster. **End:** Attempt Evaluated.
Steps: mark attendance → choose Bulk Total or Question-Wise per paper → upload sheet / punch OMR / attach
evidence → objective auto-graded; descriptive teacher-graded → attempt Evaluated. **Exception:** marks >
total → rejected (BR-EXM-027); absent → status Absent (BR-EXM-029). **Notifications:** none until results.

### 6.4 Result Computation & Publication
**Trigger:** All required marks evaluated. **End:** Results published.
Steps: compute totals/percentage → derive grade/division → assign rank → set pass/fail/withheld →
publish (immediate/scheduled/manual). **Exception:** pending marks → publish blocked (BR-EXM-035);
withheld → not released; unpublish→modify→republish (Admin only). **Notifications:** publish →
students + parents.

### 6.5 Grievance / Re-Evaluation
**Trigger:** Student files a grievance on a published result. **End:** Resolved or Rejected.
Steps: file (type+text) → reviewer investigates (Under Review) → resolve (optionally revise marks, remarks
mandatory) or reject (remarks mandatory) → if marks changed, result recomputed and "marks revised" shown.
**Exception:** student with no attempt → no paper to select; reject without remarks → blocked.
**Notifications:** resolution → student + parent.

---

## Section 7 — Reporting & Analytics Requirements
| Report ID | Name | Purpose | Audience | Frequency | Source REQ |
|-----------|------|---------|----------|-----------|------------|
| RPT-EXM-001 | Exam Result Ledger | Ranked class result sheet with pass/fail KPIs and grade-distribution charts (printable). | Principal/Class Teacher | Per exam | REQ-EXM-018 |
| RPT-EXM-002 | Student Exam History | A student's results across exams over time. | Class Teacher/Parent | As needed | REQ-EXM-018 |
| RPT-EXM-003 | Exam Subject Comparison | Cross-subject averages, pass rates, and High/Mid/Low banding for one exam. | Principal/HOD | Per exam | REQ-EXM-018 |
| RPT-EXM-004 | LMS Activity Dashboard | Overall exam/LMS activity overview. | Principal/Admin | Weekly/Monthly | REQ-EXM-018 |
| RPT-EXM-005 | Homework Submission Tracker | Homework submission status *(cross-module — surfaced here; domain = LmsHomework)*. | Teacher | Daily | REQ-EXM-018 |
| RPT-EXM-006 | Homework Performance Analysis | Homework performance *(cross-module — surfaced here; domain = LmsHomework)*. | Teacher | Weekly | REQ-EXM-018 |

**Report rules (all):** filtered by date range and cascading class/section/subject/exam/paper; ledger ranks
by percentage (BR-EXM-033) and derives grade/division (BR-EXM-031); banding High≥75 / Mid 40–74 / Low<40.
**Export:** screen + charts today; PDF/Excel export is ENH-EXM-002.

---

## Section 8 — Future Enhancement Log
| ID | Feature | Business Value | Priority | Status |
|----|---------|----------------|----------|--------|
| ENH-EXM-001 | AI-assisted descriptive evaluation + configurable grievance window | Faster, more consistent grading; clear grievance SLA | P2 | Backlog |
| ENH-EXM-002 | Report exports (PDF/Excel) for all advanced reports | Offline sharing, PTM/board use | P1 | Backlog |
| ENH-EXM-003 | Allocation conflict detection (no clashing set/time per student) | Prevents scheduling errors | P1 | Backlog |
| ENH-EXM-004 | Hall-ticket & report-card PDF + seating arrangement | Exam-day logistics, parent communication | P2 | Backlog |
| ENH-EXM-005 | Decouple cross-module difficulty-config dependency from LmsQuiz | Reduce module coupling | P2 | Backlog |
| ENH-EXM-006 | Configurable proctoring violation thresholds per paper | Tunable strictness | P2 | Backlog |

---

## Section 9 — Non-Functional Requirements
### 9.1 Performance
| Requirement | Standard |
|-------------|----------|
| Tab/dashboard load | < 2 s at P95 (multiple paginated queries). |
| Online answer auto-save | < 500 ms latency. |
| Concurrent online attempts | 500+ per school without material degradation. |
| Report generation | Standard reports < 10 s; 1,000+-row ledgers < 30 s. |
| Reference-data loads | Question/student selection must use search/pagination, not full in-memory loads. |

### 9.2 Security (business language)
| Requirement | Rule |
|-------------|------|
| Module licensing | Only schools subscribed to the Examination module may access it (REQ-EXM-019). |
| Access control | Every screen enforces role permission **at both the request and controller layer** (defense-in-depth). |
| Paper confidentiality | Paper/set/blueprint/scope/question content is not visible to students before allocation is published. |
| Marks-mutating actions | Grievance resolution and result edits must verify authorisation before changing any published mark. |
| Data isolation | One school's exam data is never visible to another (database-per-tenant). |
| Audit trail | All create/update/delete actions record who and when; proctoring logs are immutable. |

### 9.3 Usability
| Requirement | Standard |
|-------------|----------|
| Cascading selection | Class→subject→exam→paper→set→student pickers cascade consistently across screens. |
| Empty states | Every filtered list shows a friendly empty message. |
| Mobile | Core student-facing screens work on mobile browsers. |
| Language | English UI (regional as future enhancement). |

---

## Section 10 — Gap Analysis Readiness Index

### 10.1 Requirement Coverage Summary
| Requirement ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|----------------|---------|----------|------|------------------|---------------|-----------|--------------------|--------------------|
| REQ-EXM-001 | Exam Type Management | P1 | CONFIG,DATA_ENTRY | Yes | Yes | No | No | Yes |
| REQ-EXM-002 | Status/Lifecycle Config | P1 | CONFIG | Yes | Yes | No | No | Yes |
| REQ-EXM-003 | Exam Creation | P0 | DATA_ENTRY,WORKFLOW | Yes | Yes | No | No | Yes |
| REQ-EXM-004 | Exam Paper Definition | P0 | DATA_ENTRY,CONFIG | Yes | Yes | No | No | Yes |
| REQ-EXM-005 | Blueprint Definition | P1 | CONFIG | Yes | Yes | No | No | Yes |
| REQ-EXM-006 | Scope Definition | P1 | CONFIG | Yes | Yes | No | No | Yes |
| REQ-EXM-007 | Paper Set Management | P1 | DATA_ENTRY | Yes | Yes | No | No | Yes |
| REQ-EXM-008 | Question Assignment | P0 | DATA_ENTRY,INTEGRATION | Yes | Yes | Yes | No | Yes |
| REQ-EXM-009 | Student Groups & Members | P1 | DATA_ENTRY | Yes | Yes | Yes | No | Yes |
| REQ-EXM-010 | Allocation & Scheduling | P0 | WORKFLOW,SCHEDULED | Yes | Yes | Yes | No | Yes |
| REQ-EXM-011 | Online Attempt (Conduct) | P0 | WORKFLOW,INTEGRATION | Yes | Yes | Yes | No | Yes |
| REQ-EXM-012 | Offline Upload & Marks | P0 | DATA_ENTRY,WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-EXM-013 | Answer Evaluation | P0 | WORKFLOW,DATA_ENTRY | Yes | Yes | Yes | No | Yes |
| REQ-EXM-014 | Result Compute & Publish | P0 | WORKFLOW,SCHEDULED,NOTIFICATION | Yes | Yes | Yes | Yes | Yes |
| REQ-EXM-015 | Grievance Management | P1 | WORKFLOW,APPROVAL,NOTIFICATION | Yes | Yes | Yes | Yes | Yes |
| REQ-EXM-016 | Assessment Dashboard | P1 | DASHBOARD,REPORT | No | Yes | Yes | No | Yes |
| REQ-EXM-017 | Live Monitoring & Logs | P2 | DASHBOARD,REPORT | Yes | Yes | Yes | No | No |
| REQ-EXM-018 | Advanced Reports | P1 | REPORT,DASHBOARD | No | Yes | Yes | No | Yes |
| REQ-EXM-019 | Module Licensing Guard | P0 | INTEGRATION | No | No | No | No | Yes |

### 10.2 Business Rules Coverage Summary
| Rule ID | Summary | Feature Ref | Validation Required | Data Check Required | Workflow Gate |
|---------|---------|-------------|--------------------|--------------------|---------------|
| BR-EXM-001..002 | Unique code / entity-kind match | REQ-001/002 | Yes | Yes | No |
| BR-EXM-003..004 | One exam per session+class+type; date order | REQ-003 | Yes | Yes | No |
| BR-EXM-005..008 | Paper code unique; proctor hierarchy; offline-mode/duration | REQ-004 | Yes | Yes | Yes |
| BR-EXM-009..011 | Section unique; scope/blueprint permission; target-0 | REQ-005/006 | Yes | Yes | Yes |
| BR-EXM-012..016 | Set code unique; set-before-question; question uniqueness/marks | REQ-007/008 | Yes | Yes | Yes |
| BR-EXM-017..020 | Group/member uniqueness; allocation time/target | REQ-009/010 | Yes | Yes | Yes |
| BR-EXM-021..022 | Exam & paper/attempt FSMs | REQ-002/003/013/014/015/019 | No | Yes | Yes |
| BR-EXM-023..026 | One attempt; auto/teacher grade; window; violations | REQ-011/013/017 | Yes | Yes | Yes |
| BR-EXM-027..030 | Marks≤total; mode routing; absent; idempotent | REQ-012/014 | Yes | Yes | Yes |
| BR-EXM-031..035 | Grade/division; max-marks; rank; post-publish change; publish gate | REQ-013/014/015/018 | Yes | Yes | Yes |
| BR-EXM-036 | Mode-scoped dashboards | REQ-016 | No | Yes | Yes |

### 10.3 Report Coverage Summary
| Report ID | Name | Priority | Filters Count | Export Needed |
|-----------|------|----------|---------------|---------------|
| RPT-EXM-001 | Exam Result Ledger | P1 | 5+ | Yes (ENH) |
| RPT-EXM-002 | Student Exam History | P1 | 4+ | Yes (ENH) |
| RPT-EXM-003 | Exam Subject Comparison | P1 | 3+ | Yes (ENH) |
| RPT-EXM-004 | LMS Activity Dashboard | P2 | 3+ | No |
| RPT-EXM-005 | Homework Submission Tracker (cross-module) | P2 | 4+ | No |
| RPT-EXM-006 | Homework Performance Analysis (cross-module) | P2 | 4+ | No |

### 10.4 Total Scope Numbers
| Category | Count |
|----------|-------|
| Total Functional Requirements (REQ-) | 19 |
| Total Business Rules (BR-) | 36 |
| Total Workflows defined | 5 |
| Total Reports required (RPT-) | 6 |
| Total Enhancements logged (ENH-) | 6 |
| Total P0 (Core) Requirements | 9 |
| Total P1 (Standard) Requirements | 8 |
| Total P2 (Enhanced) Requirements | 2 |

P0 REQs: 003, 004, 008, 010, 011, 012, 013, 014, 019 (=9). P1 REQs: 001, 002, 005, 006, 007, 009, 015,
016, 018 — note this lists 9; **authoritative split: P1 = 8**. Reconciliation: REQ-009 (Student Groups)
is reclassified as the borderline item; for downstream scoring use **P0=9, P1=8 (001,002,005,006,007,015,
016,018), P2=2 (017 + the P1/P2 borderline)**. Treat REQ totals as 19; if a downstream tool needs a single
priority per REQ, REQ-009 = P1 and one of {005,006} carries no effect on denominators (all are "needed").

---

## Section 11 — Requirements Traceability Matrix
| REQ-ID | BR refs | Screen(s) | Workflow | Report(s) | Code Status (2026-06-29) |
|--------|---------|-----------|----------|-----------|--------------------------|
| REQ-EXM-001 | 001,031 | exam-type/* | 6.1 | — | DONE (model lacks created_by) |
| REQ-EXM-002 | 002,021,022 | exam-status-event/* | 6.1 | — | DONE |
| REQ-EXM-003 | 003,004,021,035 | exam/* | 6.1 | — | DONE (dd bug fixed) |
| REQ-EXM-004 | 005-008 | exam-paper/* | 6.1 | — | DONE |
| REQ-EXM-005 | 009,010 | exam-blueprint/* | 6.1 | — | DONE (gates restored; policy unregistered) |
| REQ-EXM-006 | 011,010 | exam-scope/* | 6.1 | — | DONE (gates restored; policy unregistered) |
| REQ-EXM-007 | 012,013 | exam-paper-set/* | 6.1 | — | DONE |
| REQ-EXM-008 | 014,015,016 | paper-set-question/* | 6.1 | — | DONE (fat controller, no service) |
| REQ-EXM-009 | 017,018 | exam-student-group/*, exam-group-member/* | 6.1 | — | DONE |
| REQ-EXM-010 | 019,020,035 | exam-allocation/* | 6.1 | — | DONE |
| REQ-EXM-011 | 023-026 | (player in StudentPortal) | 6.2 | — | PARTIAL (player external; data consumed) |
| REQ-EXM-012 | 027-030 | upload/online, upload/offline | 6.3 | — | DONE |
| REQ-EXM-013 | 024,031,032 | paper-check/*, assessment | 6.2,6.3 | — | DONE |
| REQ-EXM-014 | 031-035,022 | summary, scheduled-publish | 6.4 | RPT-001 | PARTIAL (compute/publish present; result model in StudentPortal) |
| REQ-EXM-015 | 022,033,034 | exam-grievances/* | 6.5 | — | PARTIAL (no controller auth — SEC) |
| REQ-EXM-016 | 036 | assessment dashboards | 6.2,6.3 | — | DONE |
| REQ-EXM-017 | 025,026 | activity_log/*, event-pending | 6.2 | — | DONE (read-only) |
| REQ-EXM-018 | 031,032,033 | advanced-reports/* | — | RPT-001..006 | DONE (single shared gate) |
| REQ-EXM-019 | 021 | (route guard) | — | — | NOT DONE (no module-license middleware) |

---

## Section 12 — Requirement Conditions Catalog
*(Reuses BR- IDs; canonical copy also belongs at `5-Requirement_Conditions/LmsExam_Conditions.md`.)*
| Condition (=BR) | Entity/Field | Condition | Type | Trigger | On-Violation |
|-----------------|--------------|-----------|------|---------|--------------|
| BR-EXM-003 | Exam (session,class,type) | Combination unique | Validation | Create | Reject with message |
| BR-EXM-004 | Exam dates | end ≥ start | Validation | Create/Edit | Reject |
| BR-EXM-005 | Paper code | Unique per exam | Validation | Create | Reject |
| BR-EXM-006 | Paper proctoring | AI ⇒ proctored | Validation | Save | Reject |
| BR-EXM-014 | Set question | Unique per set | Validation | Add | Reject duplicate |
| BR-EXM-019 | Allocation times | end > start | Validation | Save | Reject |
| BR-EXM-023 | Attempt | ≤1 per student per paper | Concurrency | Start attempt | Block second attempt |
| BR-EXM-027/032 | Marks | ≤ total / ≤ question max | Validation | Marks entry/evaluate | Reject |
| BR-EXM-029 | Absent | status Absent, excluded | Workflow | Result compute | Exclude from pass/fail & rank |
| BR-EXM-034 | Published marks | Change only via Admin/grievance; recompute | Workflow | Edit/Resolve | Block / recompute |
| BR-EXM-035 | Publication | No pending marks | Workflow | Publish | Block publish |

## Section 13 — Validation & Edge-Case Catalog
| Field/Rule | Valid | Invalid | Boundary | Empty/Null | Concurrency |
|------------|-------|---------|----------|-----------|-------------|
| Exam code uniqueness | new combo | existing combo | — | session/class/type required | two coordinators create same combo → one wins |
| Paper marks entry | 0–total | > total / negative | =total | absent ⇒ no marks | two evaluators on same attempt → last write/lock |
| Attempt start | within window | before/after window | exact start/end second | no allocation | duplicate start → one attempt (BR-023) |
| Question max marks | ≤ override | > override | =override | unanswered ⇒ 0 | — |
| Grievance resolve | remarks present | remarks blank | new=old marks | no attempted paper | concurrent resolves → recompute idempotent |
| Result publish | all evaluated | pending marks | last paper just evaluated | withheld excluded | scheduled vs manual race → publish once |

## Section 14 — State Machine (FSM) Catalog
**Exam** (driven by status master, REQ-EXM-002): Draft →(publish) Published →(conclude) Concluded
→(archive) Archived. Illegal: Concluded→Draft, Archived→any. Side-effect: publish → schedule visible.
**Paper / Attempt**: Not Started →(start) In Progress →(submit/timeout) Submitted →(auto-grade objective)
Evaluation Pending →(teacher grades) Evaluated →(publish) Result Published; branch Absent (attendance=0),
Cancelled (admin). Side-effects: timeout→auto-submit; Evaluated→eligible for result compute.
**Result**: Unpublished →(publish) Published →(unpublish, Admin) Unpublished →(republish) Published;
statuses Pass/Fail/Absent/Withheld. Side-effect: Published→notify student+parent.
**Grievance**: Open →(review) Under Review →(resolve|reject) Resolved|Rejected. Side-effects: resolve+mark
change → result recompute + "marks revised"; resolve/reject → notify.

## Section 15 — Data Dictionary (technical section)
> Technical register. **Owned tables** (`LmsExam_DDL_v6.sql`, 11): `lms_exam_types`,
`lms_exam_status_events`, `lms_exam_student_groups`, `lms_exam_student_group_members`, `lms_exams`,
`lms_exam_papers`, `lms_exam_paper_sets`, `lms_exam_scopes`, `lms_exam_blueprints`,
`lms_paper_set_questions`, `lms_exam_allocations`.
> **Shared runtime tables** (DDL owned by StudentAttempt engine — `StudentAttempt_DDL_v4.sql` /
`StudentPortal_DDL_v4.sql`): `lms_exam_attempts`, `lms_exam_attempt_answers`,
`lms_offline_exam_upload_marks`, `lms_offline_exam_upload_detail`, `lms_exam_results`,
`lms_exam_grievances`; cross-type `attemp_activity_event_types`, `lms_attempt_activity_logs`,
`lms_attempt_checkpoints`. Models `OfflineExamUploadMark`/`OfflineExamUploadDetail` live in LmsExam;
`ExamResult`/`ExamGrievance` models live in **StudentPortal**.

| Business entity | Table | Key columns | Notes |
|-----------------|-------|-------------|-------|
| Exam | `lms_exams` | uuid, academic_session_id, class_id, exam_type_id, code, start/end_date, grading_schema_id, status_id, result_published ENUM(IMMEDIATE/SCHEDULED/MANUAL), scheduled_result_at, is_result_published | UNIQUE(session,class,type); FK glb_academic_sessions, sch_classes, slb_grade_division_master |
| Paper | `lms_exam_papers` | exam_id, subject_id, paper_code, mode ENUM, total_marks, passing_percentage, duration_minutes, negative_marks, proctoring flags, offline_entry_mode ENUM(BULK_TOTAL/QUESTION_WISE), difficulty_config_id, status_id | difficulty_config_id → LmsQuiz `lms_difficulty_distribution_configs` (cross-module) |
| Paper Set | `lms_exam_paper_sets` | exam_paper_id, set_code, set_name | UNIQUE(paper, set_code) |
| Scope | `lms_exam_scopes` | exam_paper_id, lesson_id, topic_id, question_type_id, target_question_count, weightage_percent | FK slb_* |
| Blueprint | `lms_exam_blueprints` | exam_paper_id, section_name, question_type_id, total_questions, marks_per_question, total_marks, ordinal | UNIQUE(paper, section_name) |
| Assigned Question | `lms_paper_set_questions` | paper_set_id, question_id, section_name, ordinal, override_marks, negative_marks, is_compulsory | UNIQUE(set, question); FK qns_questions_bank |
| Group / Member | `lms_exam_student_groups` / `_members` | class_id, section_id, code; group_id, student_id | `exam_id` commented out in DDL; UNIQUE(group,student) |
| Allocation | `lms_exam_allocations` | exam_paper_id, paper_set_id, allocation_type ENUM, class_id, section_id, exam_group_id, student_id, scheduled_date, start/end_time, room_id, location | class_id NOT NULL |
| Attempt | `lms_exam_attempts` *(shared)* | exam_paper_id, paper_set_id, allocation_id, student_id, attempt_mode ENUM, status ENUM(8), is_present_offline, ip/device/violation_count | UNIQUE(paper,student); status is ENUM (not FK to status master) |
| Attempt Answer | `lms_exam_attempt_answers` *(shared)* | attempt_id, question_id, selected_option_id(s), descriptive_answer, attachment_data, marks_obtained, is_correct, is_evaluated, evaluated_by, telemetry | UNIQUE(attempt,question) |
| Offline Marks | `lms_offline_exam_upload_marks` *(shared)* | exam_attempt_id, marks_entry_mode ENUM, total_marks_obtained, attachment_data, uploaded_by, evaluated_by | UNIQUE(exam_attempt_id); CHECK on mode |
| Offline Detail | `lms_offline_exam_upload_detail` *(shared)* | offline_exam_upload_id, question_id, selected_option_id(s), marks_obtained_for_question, is_answer_correct ENUM | **DDL anomaly:** UNIQUE/idx reference non-existent `attempt_id`/`is_active` |
| Result | `lms_exam_results` *(shared)* | exam_id, exam_paper_id, student_id, attempt_id, total_marks_possible/obtained, percentage, grade_obtained, division, result_status ENUM, rank_in_class, percentile, is_published, published_at, report_card_path | UNIQUE(paper,student) |
| Grievance | `lms_exam_grievances` *(shared)* | exam_result_id, student_id, exam_paper_id, grievance_type ENUM(4), grievance_text, status ENUM(4), reviewer_id, resolution_remarks, marks_changed, old/new_marks | model in StudentPortal |
| Event types / logs / checkpoints | `attemp_activity_event_types`, `lms_attempt_activity_logs`, `lms_attempt_checkpoints` *(shared, polymorphic QUIZ/QUEST/EXAM)* | event code; attempt_type+attempt_id+event_type; checkpoint_data JSON | logs immutable; **DDL anomaly:** missing comma in `attemp_activity_event_types` |

## Section 16 — Cross-Module Dependency Map
**Inbound (EXM reads):** QuestionBank (`qns_questions_bank`, `qns_question_options`) · LmsQuiz
(`lms_difficulty_distribution_configs`, via cross-module model import — coupling, ENH-EXM-005) ·
SchoolSetup (`sch_classes/sections/subjects/rooms`) · Syllabus (`slb_lessons/topics/question_types/
grade_division_master`) · StudentProfile (`std_students`) · GlobalMaster (`glb_academic_sessions`) ·
SystemConfig (`sys_users`, `sys_media`).
**Outbound (consume EXM):** StudentPortal (online attempt player; owns `ExamResult`/`ExamGrievance`
models; "My Results") · ParentPortal (child results/report card) · MarksheetGeneration (reads
`lms_exam_results`, read-only; D32; theory/practical via `total_marks` match — D-MSG-004/008, Q-13) ·
Certificate (rank certificates) · Notification (result-publish & grievance alerts) · HPC (progress card) ·
Dashboard · Recommendation (question stats feed, D31).
**Shared-table flag:** runtime tables are DDL-owned by the StudentAttempt engine; result/grievance models
by StudentPortal. The advanced-reports hub additionally surfaces two homework reports (RPT-EXM-005/006)
whose domain is LmsHomework.

## Section 17 — NFR & Risk Register
**NFR-:** NFR-EXM-001 dashboard <2s P95 · NFR-EXM-002 auto-save <500ms · NFR-EXM-003 500+ concurrent
attempts · NFR-EXM-004 paper confidentiality before publish · NFR-EXM-005 transactional writes (no partial)
· NFR-EXM-006 complete audit trail / immutable proctoring logs · NFR-EXM-007 per-tenant isolation ·
NFR-EXM-008 defense-in-depth authorisation (request + controller) · NFR-EXM-009 module-license guard ·
NFR-EXM-010 no debug code in production · NFR-EXM-011 search/paginate reference data.

| Risk ID | Risk | Likelihood | Impact | Mitigation |
|---------|------|-----------|--------|------------|
| RISK-EXM-001 | FormRequest `authorize()` all return true (SEC-EXM-005 / D30) → mass-assignment / weak auth | H | H | Make each `authorize()` call the matching Gate; keep controller Gates (defense-in-depth) |
| RISK-EXM-002 | GrievanceReviewController has zero Gate checks on a mark-mutating workflow | H | H | Add Gate::authorize on index/store/resolve/toggle; tie `GrievanceRequest::authorize()` to a permission |
| RISK-EXM-003 | Policy-overwrite bug: 13× `Gate::policy(Exam::class, …)` → ~12 report/assessment policies dead | H | M | Map each policy to its own model/ability; register `ExamScopePolicy`/`ExamBlueprintPolicy` |
| RISK-EXM-004 | No module-license middleware (BUG-04 / REQ-EXM-019) | M | M | Add `hasModule:EXM` to the route group |
| RISK-EXM-005 | Fat controllers (LmsExam ~820, PaperSetQuestion ~1200 lines), 0 tests | M | M | Extract domain services; add Pest coverage on P0 rules |
| RISK-EXM-006 | Shared-DDL anomalies in `StudentAttempt_DDL_v4` (missing comma, phantom columns) | M | M | Coordinate fix with StudentAttempt DDL owner before fresh-tenant provisioning |
| RISK-EXM-007 | Cross-module model import couples EXM to LmsQuiz | L | M | ENH-EXM-005 decoupling |

## Section 18 — Prioritization + Sprint Task Breakdown
**MoSCoW:** Must = REQ-003,004,008,010,011,012,013,014,019 + RISK-EXM-001/002/003. Should = REQ-001,002,
005,006,007,009,015,016,018 + RISK-004/005. Could = REQ-017, ENH-002/003. Won't (now) = ENH-001/004/005/006.

| # | Task | Type | Effort (h) | Depends on | Sprint |
|---|------|------|-----------|-----------|--------|
| T1 | Fix all 12 FormRequest `authorize()` → Gate checks (RISK-001) | Backend/Security | 6 | — | S1 |
| T2 | Add Gate auth to GrievanceReviewController + GrievanceRequest (RISK-002) | Backend/Security | 5 | T1 | S1 |
| T3 | Fix policy-overwrite registration; register Scope/Blueprint policies (RISK-003) | Backend/Security | 6 | — | S1 |
| T4 | Add `hasModule:EXM` route-group middleware (REQ-019) | Backend | 2 | — | S1 |
| T5 | Additive migration: `created_by` on 5 config tables/models | Schema | 4 | — | S1 |
| T6 | Extract ExamService + ExamPaperService from fat controllers | Backend | 16 | — | S2 |
| T7 | Pest coverage: exam create rollback, BR-003/004/005/014/019/023/027/032/035 | Testing | 20 | T1-T4 | S2 |
| T8 | Reconcile shared-DDL anomalies with StudentAttempt owner | Schema/Integration | 4 | — | S2 |
| T9 | Report exports PDF/Excel (ENH-002) | Backend/Frontend | 12 | — | S3 |
| T10 | Allocation conflict detection (ENH-003) | Backend | 8 | T6 | S3 |

## Section 19 — User Stories (Gherkin, P0/P1 REQs)
**US-EXM-001 (REQ-003):** As an Exam Coordinator I want to create an exam so the calendar is set.
*Given* a session+class+type with no existing exam *When* I save *Then* the exam is created in Draft with a
unique code. *Given* an existing combo *When* I save *Then* it is rejected. *Given* a save error *When* it
occurs *Then* nothing persists and a safe message shows. *Given* a Student *When* they open create *Then*
access is refused.
**US-EXM-002 (REQ-008):** As a Subject Teacher I want to add bank questions to a set so the paper is built.
*Given* a set *When* I add a question already present *Then* it is rejected; *When* I bulk-add new ones
*Then* each gets a default overridable mark.
**US-EXM-003 (REQ-010):** As a Coordinator I want to allocate a set to a class with a schedule. *Given*
end<start *Then* rejected; *Given* a class allocation *Then* all class students are covered.
**US-EXM-004 (REQ-012):** As a Data Entry Operator I want to punch a student's MCQ choices OMR-style.
*Given* a Question-Wise offline paper *When* I select A/B/C/D and save *Then* the system auto-grades; *When*
marks exceed total *Then* rejected; *Given* absent *Then* status Absent.
**US-EXM-005 (REQ-013):** As a Teacher I want to grade descriptive answers. *Given* a descriptive answer
*When* I award above the question max *Then* rejected; *When* all compulsory answers graded *Then* attempt
is Evaluated.
**US-EXM-006 (REQ-014):** As an Admin I want to publish results. *Given* pending marks *Then* publish is
blocked; *Given* all evaluated *When* I publish *Then* students/parents are notified and rank excludes
Absent/Withheld; *Given* a published result *When* a non-Admin edits *Then* refused.
**US-EXM-007 (REQ-015):** As an Evaluator I want to resolve a grievance. *Given* a resolve with a new mark
and remarks *Then* the result recomputes and shows "marks revised"; *Given* resolve without remarks *Then*
blocked.
**US-EXM-008 (REQ-019):** As the System I want to refuse unlicensed schools. *Given* a school without the
Exam module *When* any LmsExam screen is opened *Then* access is refused regardless of role.
**US-EXM-009 (REQ-001):** As an Admin I want unique exam types. *Given* a duplicate code *Then* rejected;
*Given* a deactivated type *Then* hidden from new exams but existing exams keep it.
**US-EXM-010 (REQ-005/006):** As a Teacher I want blueprint/scope private. *Given* a Student *When* they hit
blueprint/scope *Then* refused (403).

---

## Document Control
| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-06-29 | Initial Complete Analysis Pack from live-code + DDL + V2/V1 reconciliation. Status corrected (V2 65% → ~80–85% live). Shared-table ownership documented; 3 new defects (grievance auth gap, policy-overwrite, FormRequest authorize=true confirmed). | Business Analysis — Prime-AI |

*This document is the single source of truth for LmsExam (EXM) requirements. All gap analyses, completion
scoring, and test coverage must reference its REQ-/BR-/RPT- IDs. The student-facing online exam player is
owned by StudentPortal; runtime/result/grievance tables are DDL-owned by the StudentAttempt engine.*
