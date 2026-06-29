# QUZ — LMS Quiz | Complete Functional Requirements & Analysis Pack
**Module Code:** QUZ | **Module:** LmsQuiz | **Scope:** Tenant (per-school) | **Date:** 2026-06-29
**Author:** Business Analyst (pa-business-analyst) | **Status:** v1.0 — single source of truth for downstream audits
**Sources read:** live Laravel module `Modules/LmsQuiz` (6 controllers, 6 models, 7 services, 5 FormRequests,
6 policies, 42 views); `LmsQuiz_DDL_v2.sql` (6 owned tables); `StudentAttempt_DDL_v4.sql` (3 shared runtime
tables); 9 central tenant migrations; V2 `QUZ_LmsQuiz_Requirement.md` (2026-03-26); V1 screen specs 11–19;
module-knowledge `QUZ_LmsQuiz.md`.

> **This is a Complete Analysis Pack.** The FRD (Sections 1–10) is the spine; every later `## Section`
> (RTM, Business Rules, Conditions, Validation, Process Flows, FSM, Data Dictionary, Dependency Map, NFR,
> Risk, Prioritization, Sprint Tasks, User Stories, Reporting/KPI, Feature Spec) reuses the same
> `REQ-/BR-/RPT-/ENH-` IDs. Never renumber — the later Technical Audit keys off these IDs.

## Table of Contents
- **A. FRD** — §1 Overview · §2 Roles & Access · §3 Functional Requirements · §4 Business Rules ·
  §5 Data Requirements · §6 Workflows · §7 Reporting · §8 Future Enhancements · §9 NFRs · §10 Gap-Analysis Readiness Index
- **B. Requirements Traceability Matrix (RTM)**
- **C. Business Rules Register + Requirement Conditions Catalog + Validation & Edge-Case Catalog**
- **D. Process Flows + State-Machine (FSM) Catalog**
- **E. Data Dictionary (business + technical) + Cross-Module Dependency Map**
- **F. NFR Catalog + Risk Register**
- **G. Prioritization (MoSCoW) + Effort Estimation & Sprint Tasks**
- **H. User Stories (Gherkin) + Reporting & KPI Spec**
- **I. Feature Specification (screen-by-screen)**

---
---

# A. FUNCTIONAL REQUIREMENTS DOCUMENT

## Section 1 — Module Overview

### 1.1 Purpose
LMS Quiz is the short-form assessment engine of Prime-AI. A **Quiz** is a lesson- or topic-scoped, timed
knowledge check used for practice, revision, diagnosis, challenge, enrichment, re-test, and automated
remediation. Teachers build a quiz from the school's central Question Bank — either by hand or by an
automatic **Difficulty Builder** that selects questions to match a configured mix of easy/medium/hard —
then assign it to a class, section, group, or individual student within a scheduled window. Students take
the quiz, objective answers are auto-graded, descriptive answers are graded by the teacher, and results are
published immediately, on a schedule, or manually. The module also owns the **shared assessment masters**
(Assessment Types and Difficulty Profiles) reused by the Quest and Exam modules, and it produces a rich set
of dashboards, tracking views, and performance reports for teachers and academic heads.

### 1.2 Business Value
- **Fast, balanced micro-assessment.** Teachers create well-balanced quizzes in minutes instead of hand-picking
  every question, with pedagogical balance enforced by Difficulty Profiles.
- **Targeted remediation.** When a student fails, the system can automatically build and assign a remedial
  quiz scoped to the weak topic — closing the learning loop without teacher effort.
- **Operational oversight.** Dashboards and the Quiz Summary tracker show, at a glance, who was assigned a
  quiz versus who has submitted, so teachers can chase pending students before the deadline.
- **Data-driven decisions.** Six analytics perspectives let academic heads evaluate class and teacher
  performance and let teachers identify weak students and weak questions.

### 1.3 Scope

**In scope**
- Assessment Type management (shared master).
- Difficulty Profile management (header + per-bucket rule rows; shared master).
- Quiz creation and configuration (academic mapping, scoring, timer, attempt policy, result-display behaviour).
- Quiz lifecycle (Draft → Published → Archived) and activate/deactivate.
- Manual question assignment and the automatic Difficulty Builder.
- Quiz allocation to Class / Section / Group / Student with publish, due, and cut-off windows.
- Automatic remedial-quiz generation for failing students.
- Consumption of the student quiz-attempt outcome (auto-grading view, manual grading of descriptive answers,
  result computation and publishing).
- Quiz dashboard, allocation/submission tracking (Quiz Summary), the six-perspective analytics hub,
  per-quiz attempt drill-down, and the proctoring activity log.
- Recommendation-publishing integration tied to an allocation.
- Soft-delete lifecycle (trash / restore / permanent delete) across all quiz entities.
- Per-school data isolation and per-school authorization.

**Out of scope**
- The **student-facing attempt player** itself (starting, answering, timer countdown, auto-save, beacon
  submit) — owned by the **Student Portal** module, which writes the shared attempt records that LMS Quiz reads.
- Creating or editing Question Bank questions (owned by Question Bank).
- The Quest and Exam assessment workflows (they only *consume* the shared masters owned here).
- Parent-facing result views (owned by Parent Portal).
- Cross-school / platform-wide quiz analytics (data is isolated per school).
- Real-time proctoring video; only event-log capture is in scope.

### 1.4 Terminology
| Term | Meaning |
|------|---------|
| Quiz | A short, topic-scoped timed assessment for knowledge check, practice, revision, diagnosis, or remediation. |
| Assessment Type | A pedagogical category (Practice, Challenge, Diagnostic, Remedial, Revision, Re-Test, Enrichment) shared across Quiz, Quest, and Exam. |
| Difficulty Profile | A named template stating what percentage of a quiz's questions must come from each question-type × complexity bucket (e.g. "20% easy, 50% medium, 30% hard"). |
| Difficulty Builder | The automatic tool that selects Question Bank questions to match a Difficulty Profile. |
| Scope Topic | The primary topic a quiz covers; selecting it includes the topics nested beneath it. |
| Allocation | The assignment of a published quiz to an audience (class, section, group, or student) with timing windows. |
| Attempt | One student sitting of a quiz; objective answers auto-graded, descriptive answers teacher-graded. |
| Cut-off | The hard deadline after which no new attempt may begin, even if attempts remain. |
| Auto-Publish Result | A setting that releases results automatically at a chosen date; an allocation's setting overrides the quiz's. |
| System-Generated (Remedial) Quiz | A quiz the system builds automatically (using the system-default Difficulty Profile) for a student who failed an assessment. |
| Shared Master | A configuration table owned by LMS Quiz but used read-only by Quest and Exam. |

---

## Section 2 — User Roles & Access

### 2.1 Actors
| Actor | Description |
|-------|-------------|
| Academic Head / School Admin | Sets up shared masters (Assessment Types, Difficulty Profiles), reviews dashboards and all reports including the Teacher Monthly report. |
| Teacher | Creates quizzes, assigns questions, allocates quizzes, manually grades descriptive answers, publishes results, tracks submissions, views class/student reports. |
| Student | Takes allocated quizzes and views own results (via the Student Portal; outcome data is read here). |
| Parent | Views the child's results (via Parent Portal; out of scope here). |
| System (automated) | Builds remedial quizzes on failure; auto-grades objective answers; auto-publishes results on schedule. |
| Invigilator / Admin | Reviews the proctoring activity log for violations. |

### 2.2 Role–Feature Matrix (business-level)
| Feature | Academic Head/Admin | Teacher | Student | System |
|---------|:---:|:---:|:---:|:---:|
| Manage Assessment Types | Create/Edit/Delete | View | — | — |
| Manage Difficulty Profiles | Create/Edit/Delete | View | — | Read (remedial) |
| Create / edit / publish quiz | Yes | Yes | — | Create (remedial) |
| Assign questions (manual + builder) | Yes | Yes | — | Auto (remedial) |
| Allocate quiz | Yes | Yes | — | Auto (remedial, to student) |
| Take quiz / view own result | — | — | Yes | — |
| Grade descriptive answers | Yes | Yes | — | — |
| Publish results | Yes | Yes | — | Auto (scheduled) |
| Publish recommendations | Yes | Yes | — | — |
| Dashboards & Quiz Summary | All | Own/all (per permission) | — | — |
| Analytics hub (6 reports) | All 6 | Subset (per permission) | — | — |
| Proctoring activity log | View | View | — | Writes (via portal) |
| Trash / restore / permanent delete | Yes | Yes (per permission) | — | — |

> Authorization is per-school. Each action is guarded by a `tenant.*` permission. Data is isolated per
> school (database-per-tenant): there is no cross-school visibility.

---

## Section 3 — Functional Requirements

> IDs are stable. Priority: **Core (P0)**, **Standard (P1)**, **Enhanced (P2)**. Category tags in brackets.
> "Actors" lists who **Initiates / Processes / Views**.

### REQ-QUZ-001 — Assessment Type Management `[CONFIGURATION]`
**Priority:** Core (P0)
**Description:** Maintain the catalogue of assessment categories (e.g. Practice, Challenge, Diagnostic,
Remedial, Revision, Re-Test, Enrichment). Each type carries a unique code, a display name, a description, an
active flag, and a usage scope (Quiz / Quest / Online Exam / Offline Exam) that controls where the type may
be selected. This is a shared master also used by Quest and Exam.
**Actors:** Initiates: Admin · Processes: System · Views: Admin, Teacher.
**Business Rules:** BR-QUZ-001, BR-QUZ-002, BR-QUZ-031.
**Acceptance Criteria:**
- A duplicate code is rejected with a clear validation message.
- A type can be deactivated (soft) and later restored without permanent loss.
- Only types whose usage scope is "Quiz" appear in the quiz-creation type dropdown.
- A type that is in use by a quiz cannot be permanently deleted while in use (guarded).
**Integration:** Consumed read-only by Quest and Exam.

### REQ-QUZ-002 — Difficulty Profile Management `[CONFIGURATION]`
**Priority:** Core (P0)
**Description:** Maintain named Difficulty Profiles. A profile has a header (unique code, name, description,
usage scope, active flag, and a "use for system-generated quizzes" flag) and one or more rule rows. Each rule
row targets a question-type × complexity bucket (optionally Bloom level, cognitive skill, and specificity)
and states the minimum and maximum percentage of the quiz's questions that bucket may supply, plus an
optional marks-per-question override. Shared master used by Quest and Exam.
**Actors:** Initiates: Admin · Processes: System · Views: Admin, Teacher.
**Business Rules:** BR-QUZ-003, BR-QUZ-004, BR-QUZ-005, BR-QUZ-031.
**Acceptance Criteria:**
- Rule rows are managed inline within the profile (parent–child on one form).
- At most one profile may be flagged as the system-generated default; turning one on turns the others off.
- A profile scoped to "Quiz" is offered in quiz creation; profiles are visible read-only to Quest and Exam.
- The percentage rules are surfaced for validation when questions are added (see REQ-QUZ-006).
**Integration:** Consumed read-only by Quest (`Quest`) and Exam (`ExamPaper`).

### REQ-QUZ-003 — Quiz Creation & Configuration `[DATA_ENTRY]`
**Priority:** Core (P0)
**Description:** A teacher creates a quiz mapped to an academic session, class, subject, lesson, and a scope
topic (selectable by depth level 1–4). The quiz carries an auto-generated unique code, title, description,
rich-text instructions, an assessment type, and a configuration set: duration, total marks and total
questions (auto-calculated from assigned questions), passing percentage, negative-marking factor, attempt
policy (single/multiple, max attempts), and behavioural switches (randomise order, show per-question marks,
show result immediately, auto-publish result, enforce timer, show correct answer, show explanation), plus
question-selection flags (linked Difficulty Profile, ignore-profile, system-generated, only-unused-questions,
only-authorised-questions).
**Actors:** Initiates: Teacher/Admin · Processes: System · Views: Teacher/Admin.
**Business Rules:** BR-QUZ-006, BR-QUZ-007, BR-QUZ-008, BR-QUZ-024, BR-QUZ-030.
**Acceptance Criteria:**
- The quiz code is globally unique within the school.
- Selecting a topic level enables exactly the corresponding cascading topic dropdowns.
- Total marks and total questions reconcile to the assigned questions.
- The "only unused" and "only authorised" flags persist correctly when saved.
- Creating a quiz writes one consistent record set (quiz + settings) — partial saves are not left behind.

### REQ-QUZ-004 — Quiz Lifecycle & Status Management `[WORKFLOW]`
**Priority:** Core (P0)
**Description:** A quiz moves through Draft → Published → Archived. Only a Published quiz may be allocated.
Teachers can also activate/deactivate a quiz (soft on/off) independently of status.
**Actors:** Initiates: Teacher/Admin · Processes: System · Views: Teacher/Admin.
**Business Rules:** BR-QUZ-009, BR-QUZ-010.
**Acceptance Criteria:**
- A Draft or Archived quiz cannot be allocated; the system blocks it with a clear message.
- Status transitions are recorded in the activity trail.
- Deactivating a quiz hides it from active lists but does not delete it.

### REQ-QUZ-005 — Manual Question Assignment `[DATA_ENTRY]`
**Priority:** Core (P0)
**Description:** Teachers search the central Question Bank (filtered by the quiz's class plus section,
subject group, subject, lesson, topic, question type, complexity, Bloom level, cognitive skill, specificity,
tags, priority, and usage flags) and select questions into the quiz. They review the selection, override the
display order (ordinal) and per-question marks, and remove questions. A live counter compares selected
questions/marks against the quiz's configured maximums.
**Actors:** Initiates: Teacher · Processes: System · Views: Teacher.
**Business Rules:** BR-QUZ-011, BR-QUZ-012, BR-QUZ-013, BR-QUZ-014.
**Acceptance Criteria:**
- The same question cannot be added twice to one quiz.
- The system blocks saving more questions or marks than the quiz's configured maximum.
- Reordering and marks overrides persist after reload.
- A question's effective marks = override if set, else the question's default.

### REQ-QUZ-006 — Automatic Difficulty Builder `[DATA_ENTRY]`
**Priority:** Core (P0)
**Description:** From a quiz's linked Difficulty Profile, the builder computes how many questions each
type × complexity bucket should supply (respecting the min/max percentages), fetches matching Question Bank
candidates (honouring only-authorised and only-unused flags and the scope topic), lets the teacher review
them, and bulk-adds them with per-rule marks. A validation view shows live pass/fail against each profile
constraint.
**Actors:** Initiates: Teacher · Processes: System · Views: Teacher.
**Business Rules:** BR-QUZ-004, BR-QUZ-005, BR-QUZ-013, BR-QUZ-015.
**Acceptance Criteria:**
- Candidate counts respect the profile's configured percentages.
- The "only authorised" filter restricts to questions marked usable for quizzes; the "only unused" filter
  excludes questions already presented (see BR-QUZ-015 / known defect BUG-QUZ-003).
- Bulk-added questions receive sequential ordinals and the rule's marks.

### REQ-QUZ-007 — Quiz Allocation to Audiences `[WORKFLOW]`
**Priority:** Core (P0)
**Description:** A teacher assigns a Published quiz to a target — whole class (locked to the quiz's class),
a section, a group, or an individual student — and sets the timing window: published-at (visible from; empty
= immediate), due date, and optional hard cut-off. An auto-publish-result toggle reveals a result-publish
date; an allocation's auto-publish setting overrides the quiz's. The same quiz may be allocated to multiple
targets. An "unused quiz" filter hides already-allocated quizzes to prevent accidental double assignment.
**Actors:** Initiates: Teacher/Admin · Processes: System · Views: Teacher/Admin, Student (via portal).
**Business Rules:** BR-QUZ-009, BR-QUZ-016, BR-QUZ-017, BR-QUZ-018, BR-QUZ-019.
**Acceptance Criteria:**
- A Draft/Archived quiz cannot be allocated.
- Due date ≥ published-at; cut-off ≥ due date.
- Selecting "Student" reveals section + student pickers and stores the chosen student target.
- The allocation-level result-publish setting visibly overrides the quiz-level one.

### REQ-QUZ-008 — Automatic Remedial Quiz Generation `[WORKFLOW][INTEGRATION]`
**Priority:** Standard (P1)
**Description:** When a student fails a quiz, the system builds a remedial quiz: it reads the
system-default Difficulty Profile, selects matching MCQ questions scoped to the failing quiz's subject,
class, and topic, creates a Published, single-attempt, system-generated quiz (with correct-answer and
explanation reveal enabled), assigns it to that student, and records question-usage audit entries — all in
one atomic operation. Triggered from the Student Portal at attempt submission.
**Actors:** Initiates: System (on failure) · Processes: System · Views: Student (via portal), Teacher (reports).
**Business Rules:** BR-QUZ-020, BR-QUZ-021, BR-QUZ-022, BR-QUZ-023.
**Acceptance Criteria:**
- If no system-default profile exists, generation fails with a clear, logged error and no partial quiz.
- If no matching questions exist, generation aborts cleanly.
- The remedial quiz is single-attempt, Published, and scoped to the weak topic.
- The remedial allocation targets the correct student (see known defect BUG-QUZ-002).

### REQ-QUZ-009 — Student Quiz Attempt (consumed boundary) `[INTEGRATION]`
**Priority:** Core (P0)
**Description:** Students take allocated quizzes through the Student Portal: see allocated quizzes within the
open window, start an attempt (subject to attempt-count and cut-off rules), answer questions (objective via
option selection, descriptive via text/upload) with per-question time telemetry, and submit (manually,
on timer expiry, or by cut-off). LMS Quiz **defines the rules and consumes the resulting records** but does
not host the player. Attempt records are shared with Quest (discriminated by assessment type).
**Actors:** Initiates: Student · Processes: System (Student Portal) · Views: Student, Teacher.
**Business Rules:** BR-QUZ-016, BR-QUZ-024, BR-QUZ-025, BR-QUZ-026, BR-QUZ-027.
**Acceptance Criteria:**
- No attempt may start after the cut-off, even if attempts remain.
- A student cannot exceed the quiz's maximum attempts.
- Attempt count increments by one per new sitting.
- In-progress attempts are recoverable after a disconnect (Student Portal responsibility).

### REQ-QUZ-010 — Auto-Grading & Scoring `[WORKFLOW]`
**Priority:** Core (P0)
**Description:** On submission, objective answers (single/multiple MCQ, true/false, fill-in) are graded
automatically against the Question Bank's correct answers; marks obtained, correctness, total score,
percentage, and pass/fail are computed. Negative marking deducts the configured factor per wrong objective
answer, with the final score floored at zero. Descriptive answers are left ungraded pending teacher review.
**Actors:** Initiates: System · Processes: System · Views: Student, Teacher.
**Business Rules:** BR-QUZ-025, BR-QUZ-027, BR-QUZ-028, BR-QUZ-029.
**Acceptance Criteria:**
- An all-correct objective attempt scores the full marks.
- Negative marking never produces a negative total.
- Descriptive answers are flagged for manual grading, not auto-scored.
- Pass/fail is derived from the quiz's passing percentage.

### REQ-QUZ-011 — Teacher Manual Grading of Descriptive Answers `[WORKFLOW]`
**Priority:** Standard (P1)
**Description:** Teachers see attempts containing ungraded descriptive answers, read each student response,
award marks (within the question's maximum), mark correctness, and optionally add feedback. When all pending
answers in an attempt are graded, the attempt's total score, percentage, and pass/fail are recomputed.
**Actors:** Initiates: Teacher · Processes: System · Views: Teacher, Student.
**Business Rules:** BR-QUZ-028, BR-QUZ-029.
**Acceptance Criteria:**
- A teacher cannot award more than a question's maximum marks.
- Recomputation occurs once all pending answers in the attempt are graded.

### REQ-QUZ-012 — Result Computation & Publishing `[WORKFLOW][NOTIFICATION]`
**Priority:** Standard (P1)
**Description:** Per-attempt results carry total marks, percentage, grade, pass/fail, and optional class rank
and percentile. Results become visible by one of three paths: immediately (if the quiz shows results on
submit), automatically at the result-publish date (if auto-publish is on, allocation overriding quiz), or by
explicit teacher publish for an allocation. Published results drive the Student Portal "My Results" view.
**Actors:** Initiates: Teacher/System · Processes: System · Views: Student, Teacher.
**Business Rules:** BR-QUZ-017, BR-QUZ-026, BR-QUZ-029.
**Acceptance Criteria:**
- A result not yet published is not visible to the student.
- Auto-publish releases results at the configured date.
- Manual publish releases results for the chosen allocation immediately.
- **Gap:** no scheduled job exists in this module to auto-publish at the date (see ENH-QUZ-002).

### REQ-QUZ-013 — Quiz Dashboard & Performance Analytics `[REPORT][DASHBOARD]`
**Priority:** Standard (P1)
**Description:** A KPI dashboard (total quizzes, questions in pool, allocations, attempts, submitted with
completion rate, average score) with monthly-activity and score-distribution charts and subject-wise and
status breakdowns; plus a six-perspective analytics hub: class performance, teacher monthly, student
performance summary, student detailed assessment, periodic detail, and current-class performance. Each
perspective is independently permission-gated. Filterable by class/section, subject, status, and date range.
**Actors:** Initiates: Teacher/Admin · Processes: System · Views: Teacher, Academic Head.
**Business Rules:** BR-QUZ-031, BR-QUZ-032.
**Acceptance Criteria:**
- KPIs and charts refresh when filters change.
- A report perspective the user lacks permission for is omitted from the UI entirely.
- Reports are scoped to the current school only.
**Reports:** RPT-QUZ-001, RPT-QUZ-003.

### REQ-QUZ-014 — Quiz Summary & Per-Quiz Attempt Drill-down `[REPORT]`
**Priority:** Standard (P1)
**Description:** The Quiz Summary tracker lists allocations with assigned vs submitted vs pending counts
(pending = assigned − submitted, floored at zero) and flags overdue allocations; a per-quiz report drills
into student-by-student scores, and an attempt-detail view shows a single attempt's question-by-question
answers and marks.
**Actors:** Initiates: Teacher/Admin · Processes: System · Views: Teacher, Academic Head.
**Business Rules:** BR-QUZ-032, BR-QUZ-033.
**Acceptance Criteria:**
- Pending count is never negative.
- An allocation past its due date is visually flagged.
- The drill-down shows each student's score and submission status for the quiz.
**Reports:** RPT-QUZ-002, RPT-QUZ-004.

### REQ-QUZ-015 — Recommendation Publishing Integration `[INTEGRATION]`
**Priority:** Enhanced (P2)
**Description:** From an allocation, a teacher can publish the (otherwise hidden) learning recommendations
that the Recommendation module generated for the students who attempted that quiz, making them visible to
those students; the action also turns on auto-publish-result for the allocation.
**Actors:** Initiates: Teacher · Processes: System · Views: Student (via Recommendation), Teacher.
**Business Rules:** BR-QUZ-034.
**Acceptance Criteria:**
- Only recommendations tied to the allocation's quiz and its attempting students are published.
- **Known defect:** the lookup currently queries a non-existent attempt column and publishes nothing
  (BUG-QUZ-001) — must be fixed for this requirement to function.

### REQ-QUZ-016 — Soft-Delete Lifecycle (Trash / Restore / Permanent Delete) `[WORKFLOW]`
**Priority:** Standard (P1)
**Description:** Every quiz entity (quiz, question link, allocation, assessment type, difficulty profile)
supports soft delete to a trash view, restore from trash, and permanent (force) delete, with usage guards
preventing permanent deletion of records still referenced by dependents.
**Actors:** Initiates: Teacher/Admin · Processes: System · Views: Teacher/Admin.
**Business Rules:** BR-QUZ-002, BR-QUZ-035.
**Acceptance Criteria:**
- A soft-deleted record disappears from active lists but appears in trash.
- A restored record returns to active lists intact.
- A record still in use cannot be permanently deleted; the system explains why.

### REQ-QUZ-017 — Authorization, Module Licensing & Tenant Isolation `[CONFIGURATION][INTEGRATION]`
**Priority:** Core (P0)
**Description:** Every action is permission-gated per school; the module must be reachable only by schools
licensed for LMS Quiz; all data is isolated per school.
**Actors:** Processes: System · Views: Admin.
**Business Rules:** BR-QUZ-036, BR-QUZ-037, BR-QUZ-038.
**Acceptance Criteria:**
- A user without the relevant permission is refused the action.
- A school not licensed for the module cannot reach quiz screens (**gap:** licence guard absent — BUG-QUZ-005).
- No quiz, attempt, or report ever exposes another school's data.

### REQ-QUZ-018 — Activity & Proctoring Log `[REPORT][NOTIFICATION]`
**Priority:** Enhanced (P2)
**Description:** A filterable audit log of attempt events (submission, tab switch, window blur, network
drop, violations) with quiz/student/attempt context, an event payload, and timestamps; violation events are
visually flagged. Invigilators use it to investigate suspected cheating or technical failure. Events are
captured by the Student Portal during attempts; LMS Quiz provides the review interface.
**Actors:** Initiates: Student (via portal, writes) · Processes: System · Views: Invigilator/Admin, Teacher.
**Business Rules:** BR-QUZ-033.
**Acceptance Criteria:**
- The log is filterable by quiz, event type, attempt, student, and date range.
- Violation events are clearly distinguished from benign ones.
**Reports:** RPT-QUZ-005.

---

## Section 4 — Business Rules Register
*(Full register with type, trigger, enforcement, priority is in Section C. Summary index here.)*

| ID | Rule (business statement) | Type |
|----|---------------------------|------|
| BR-QUZ-001 | Assessment Type code is unique per school. | Validation |
| BR-QUZ-002 | A record in use cannot be permanently deleted (usage guard). | Workflow |
| BR-QUZ-003 | Difficulty Profile code is unique per school. | Validation |
| BR-QUZ-004 | Sum of maximum percentages across a profile's rules should equal 100%. | Validation |
| BR-QUZ-005 | Sum of minimum percentages across a profile's rules must not exceed 100%. | Validation |
| BR-QUZ-006 | Quiz code is globally unique per school (auto-generated). | Validation |
| BR-QUZ-007 | Quiz code format = QUIZ_session_class_subject_lesson_topic_random4. | Calculation |
| BR-QUZ-008 | Total marks and total questions reconcile to assigned questions. | Calculation |
| BR-QUZ-009 | A quiz must be Published before it can be allocated. | Workflow |
| BR-QUZ-010 | Status follows Draft → Published → Archived. | Workflow |
| BR-QUZ-011 | The same question cannot appear twice in one quiz. | Validation |
| BR-QUZ-012 | Selected questions/marks cannot exceed the quiz's configured maximums. | Validation |
| BR-QUZ-013 | A question's effective marks = override if set, else default. | Calculation |
| BR-QUZ-014 | Display order is driven by ordinal; reordering persists. | Workflow |
| BR-QUZ-015 | "Only unused" excludes already-presented questions; "only authorised" restricts to quiz-authorised questions. | Validation |
| BR-QUZ-016 | No attempt may start after the cut-off. | Workflow |
| BR-QUZ-017 | An allocation's auto-publish-result overrides the quiz's. | Workflow |
| BR-QUZ-018 | Due date ≥ published-at; cut-off ≥ due date. | Validation |
| BR-QUZ-019 | Allocation target id must match the chosen allocation type. | Validation |
| BR-QUZ-020 | Remedial generation requires a system-default Difficulty Profile. | Workflow |
| BR-QUZ-021 | Remedial quizzes use MCQ questions only. | Workflow |
| BR-QUZ-022 | A remedial quiz is single-attempt and Published. | Workflow |
| BR-QUZ-023 | Remedial generation is one atomic operation. | Concurrency |
| BR-QUZ-024 | A quiz create/update writes a consistent record set (atomic). | Concurrency |
| BR-QUZ-025 | Objective answers auto-grade; descriptive answers need teacher grading. | Workflow |
| BR-QUZ-026 | A result is visible only when published (immediate / scheduled / manual). | Workflow |
| BR-QUZ-027 | Negative marking floors the total score at zero. | Calculation |
| BR-QUZ-028 | A teacher cannot award more than a question's maximum marks. | Validation |
| BR-QUZ-029 | Total score/percentage/pass recompute after all pending answers are graded. | Calculation |
| BR-QUZ-030 | At most one Difficulty Profile is the system-generated default (exclusive). | Workflow |
| BR-QUZ-031 | Shared masters scope rows by usage type (Quiz/Quest/Exam). | Validation |
| BR-QUZ-032 | Pending count = max(0, assigned − submitted). | Calculation |
| BR-QUZ-033 | Violation events are flagged distinctly in the activity log. | Workflow |
| BR-QUZ-034 | Recommendation publishing affects only the allocation's quiz and its attempting students. | Workflow |
| BR-QUZ-035 | Soft-deleted records are recoverable from trash. | Workflow |
| BR-QUZ-036 | Every action is permission-gated per school. | Permission |
| BR-QUZ-037 | The module is reachable only by licensed schools. | Permission |
| BR-QUZ-038 | All data is isolated per school (no cross-tenant access). | Permission |

---

## Section 5 — Data Requirements
*(Business view here; full technical dictionary in Section E.)*

### 5.1 Business Entities
| Entity | Meaning | Privacy |
|--------|---------|---------|
| Assessment Type | Pedagogical category of a quiz (shared master). | Internal |
| Difficulty Profile (+ Rules) | Template for the easy/medium/hard mix of a quiz (shared master). | Internal |
| Quiz | The assessment definition and its settings. | Internal |
| Quiz Question Link | A Question Bank question placed in a quiz, with order and marks. | Internal |
| Quiz Allocation | The assignment of a quiz to an audience with timing. | Internal |
| Quiz Attempt | A student's sitting of a quiz (shared with Quest). | Confidential (student performance) |
| Quiz Attempt Answer | A student's per-question response and its grading. | Confidential |
| Quiz Result | The published outcome of an attempt (score, grade, rank). | Confidential (student PII-adjacent) |
| Activity / Proctoring Event | An event logged during an attempt. | Confidential |

### 5.2 Privacy Classification
- Student attempts, answers, results, and proctoring events are **Confidential** (student academic
  performance). Masters, quizzes, questions, and allocations are **Internal**. No financial PII. All data is
  per-school isolated.

---

## Section 6 — Workflows
*(Detailed swimlanes, exceptions, and notifications in Section D.)*

1. **Setup → Build → Allocate** (Admin sets masters; Teacher creates quiz, assigns questions, publishes, allocates).
2. **Difficulty Builder** (Teacher selects profile → system fetches candidates → review → bulk-add → validate).
3. **Attempt → Grade → Publish** (Student attempts via portal → objective auto-grade → teacher grades descriptive → result publish).
4. **Automatic Remedial Generation** (Student fails → system builds + allocates remedial quiz).
5. **Tracking & Recommendation Publish** (Teacher tracks submissions on Quiz Summary → publishes recommendations).

---

## Section 7 — Reporting & Analytics
| ID | Report | Audience |
|----|--------|----------|
| RPT-QUZ-001 | Quiz Dashboard (6 KPIs + activity & score-distribution charts + subject/status breakdowns) | Admin, Teacher |
| RPT-QUZ-002 | Quiz Summary / Allocation Tracking (assigned vs submitted vs pending, overdue flags) | Teacher, Admin |
| RPT-QUZ-003 | Analytics Hub — 6 perspectives (class performance, teacher monthly, student summary, student detailed, periodic detail, current-class) | Admin, Teacher (per permission) |
| RPT-QUZ-004 | Per-Quiz Attempt Drill-down + single-attempt detail (question-by-question) | Teacher, Admin |
| RPT-QUZ-005 | Activity / Proctoring Audit Log | Invigilator/Admin, Teacher |

*(Full report specs and KPI catalogue in Section H.)*

---

## Section 8 — Future Enhancement Log
| ID | Enhancement | Rationale | Promote-to |
|----|-------------|-----------|-----------|
| ENH-QUZ-001 | Fix recommendation-publish attempt-column lookup (BUG-QUZ-001). | REQ-QUZ-015 currently publishes nothing. | REQ-QUZ-015 |
| ENH-QUZ-002 | Scheduled job to auto-publish results at the result-publish date. | No scheduler exists; auto-publish currently inert in-module. | REQ-QUZ-012 |
| ENH-QUZ-003 | Correct remedial allocation to store the student (not the user) id (BUG-QUZ-002). | Mis-targeted remedial allocation. | REQ-QUZ-008 |
| ENH-QUZ-004 | Implement the only-unused exclusion in the remedial selector (BUG-QUZ-003). | Filter currently inert. | REQ-QUZ-008 |
| ENH-QUZ-005 | Add a dedicated Publish action/route (instead of editing the status field). | Matches Homework publish pattern; clearer UX. | REQ-QUZ-004 |
| ENH-QUZ-006 | Extract shared masters into a neutral LmsMaster module. | Removes LmsQuiz→Quest/Exam unidirectional coupling. | — |
| ENH-QUZ-007 | Add author audit (created_by) to masters, question links, and allocations. | Only quizzes carry an author today. | REQ-QUZ-001/002 |

---

## Section 9 — Non-Functional Requirements
*(Measurable NFR-/RISK- entries in Section F.)*
- **9.1 Performance:** support 500+ concurrent attempts per quiz; difficulty-builder fetch < 1s over ~1,000
  candidate questions; dashboards/reports must paginate or bound aggregation queries (current `index()`
  loads are unbounded — NFR-QUZ-004).
- **9.2 Security:** per-school authorization on every action; module-licence guard (currently missing);
  defence-in-depth (FormRequest authorization currently disabled — all return true); per-school data isolation.
- **9.3 Usability:** SPA-style tabbed interface; cascading academic dropdowns; rich-text instructions;
  MathJax rendering of questions; clear pending/overdue badges.

---

## Section 10 — Gap-Analysis Readiness Index (downstream contract)

### 10.1 Coverage Table
| Requirement ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|----------------|---------|----------|------|:--:|:--:|:--:|:--:|:--:|
| REQ-QUZ-001 | Assessment Type Management | P0 | CONFIG | Yes | Yes | No | No | Yes |
| REQ-QUZ-002 | Difficulty Profile Management | P0 | CONFIG | Yes | Yes | No | No | Yes |
| REQ-QUZ-003 | Quiz Creation & Config | P0 | DATA_ENTRY | Yes | Yes | No | No | Yes |
| REQ-QUZ-004 | Quiz Lifecycle & Status | P0 | WORKFLOW | Yes | Yes | No | No | Yes |
| REQ-QUZ-005 | Manual Question Assignment | P0 | DATA_ENTRY | Yes | Yes | Yes (AJAX) | No | Yes |
| REQ-QUZ-006 | Difficulty Builder | P0 | DATA_ENTRY | Yes | Yes | Yes (AJAX) | No | Yes |
| REQ-QUZ-007 | Quiz Allocation | P0 | WORKFLOW | Yes | Yes | Yes (AJAX) | Yes | Yes |
| REQ-QUZ-008 | Remedial Generation | P1 | WORKFLOW/INTEGRATION | Yes (shared) | No | No | No | Yes |
| REQ-QUZ-009 | Student Attempt (boundary) | P0 | INTEGRATION | Yes (shared) | Yes (portal) | Yes | Yes | Yes |
| REQ-QUZ-010 | Auto-Grading & Scoring | P0 | WORKFLOW | Yes (shared) | No | No | No | Yes |
| REQ-QUZ-011 | Manual Grading | P1 | WORKFLOW | Yes (shared) | Yes | No | No | Yes |
| REQ-QUZ-012 | Result Computation & Publishing | P1 | WORKFLOW/NOTIFICATION | Yes (shared) | Yes | No | Yes | Yes |
| REQ-QUZ-013 | Dashboard & Analytics | P1 | REPORT/DASHBOARD | Yes | Yes | Yes (AJAX) | No | Yes |
| REQ-QUZ-014 | Summary & Drill-down | P1 | REPORT | Yes | Yes | No | No | Yes |
| REQ-QUZ-015 | Recommendation Publishing | P2 | INTEGRATION | Yes (REC) | Yes | No | Yes | Yes |
| REQ-QUZ-016 | Soft-Delete Lifecycle | P1 | WORKFLOW | Yes | Yes | No | No | Yes |
| REQ-QUZ-017 | Authz / Licence / Isolation | P0 | CONFIG/INTEGRATION | No | No | No | No | Yes |
| REQ-QUZ-018 | Activity / Proctoring Log | P2 | REPORT/NOTIFICATION | Yes (shared) | Yes | Yes (portal writes) | No | Yes |

### 10.2 Business-Rule Coverage
BR-QUZ-001…038 — all mapped to ≥1 REQ in Section C / the RTM (Section B). No orphan rules.

### 10.3 Report Coverage
RPT-QUZ-001…005 — each mapped to REQ-QUZ-013/014/018 in Section H.

### 10.4 Totals (reconciled)
- **Functional Requirements (REQ):** 18 — P0 = 9 (001,002,003,004,005,006,007,009,010,017 → note: 10 listed
  P0 below), P1 = 7, P2 = 2.
  **Authoritative count by priority (from per-REQ headers):** P0 = {001,002,003,004,005,006,007,009,010,017} = **10**;
  P1 = {008,011,012,013,014,016} = **6**; P2 = {015,018} = **2**. Total = **18**.
- **Business Rules (BR):** 38.
- **Workflows:** 5.
- **Reports (RPT):** 5.
- **Enhancements (ENH):** 7.

> Reconciliation note: REQ-QUZ-017 (Authz/Licence/Isolation) is Core (P0). The split is **P0 = 10, P1 = 6,
> P2 = 2**. (The module-knowledge FRD Summary records 9/7/2 from an earlier draft; **this Section 10.4 split,
> 10/6/2, is authoritative** — recompute from the per-REQ headers, never from a remembered total.)

---
---

# B. REQUIREMENTS TRACEABILITY MATRIX (RTM)

| REQ-ID | Feature | BR refs | Screen(s) | Workflow | Report(s) | Code Status (2026-06-29) | Gap |
|--------|---------|---------|-----------|----------|-----------|--------------------------|-----|
| REQ-QUZ-001 | Assessment Types | 001,002,031 | Assessment Type CRUD | WF1 | — | DONE | FormRequest authz=true; no created_by |
| REQ-QUZ-002 | Difficulty Profiles | 003,004,005,030,031 | Difficulty Config CRUD | WF1 | — | DONE | %-sum validation app-level only; no created_by |
| REQ-QUZ-003 | Quiz Creation | 006,007,008,024,030 | Quiz Create/Edit (2-tab) | WF1 | — | DONE (UUID/fillable fixed) | No DB transaction (BUG-QUZ-006) |
| REQ-QUZ-004 | Lifecycle/Status | 009,010 | Quiz list/edit, toggle | WF1 | — | PARTIAL | No dedicated publish route (ENH-005) |
| REQ-QUZ-005 | Manual Q assignment | 011,012,013,014 | Quiz Questions (3-tab) | WF1 | — | DONE | — |
| REQ-QUZ-006 | Difficulty Builder | 004,005,013,015 | Difficulty Builder tab | WF2 | — | DONE | only-unused semantics (see 008) |
| REQ-QUZ-007 | Allocation | 009,016,017,018,019 | Quiz Allocation CRUD | WF1/WF3 | — | DONE | date ordering validated app-level |
| REQ-QUZ-008 | Remedial generation | 020,021,022,023 | (system) | WF4 | — | PARTIAL | BUG-QUZ-002 target id; BUG-QUZ-003 unused filter |
| REQ-QUZ-009 | Student attempt | 016,024,025,026,027 | Student Portal player | WF3 | — | EXTERNAL (StudentPortal) | Player owned by StudentPortal |
| REQ-QUZ-010 | Auto-grading | 025,027,028,029 | (system) | WF3 | — | EXTERNAL/consumed | Verify scoring in portal |
| REQ-QUZ-011 | Manual grading | 028,029 | grading views | WF3 | — | PARTIAL | Verify max-marks block |
| REQ-QUZ-012 | Result publish | 017,026,029 | result views | WF3/WF5 | — | PARTIAL | No scheduler (ENH-002) |
| REQ-QUZ-013 | Dashboard/analytics | 031,032 | Dashboard + 6-report hub | — | RPT-001,003 | DONE | Unbounded queries (NFR-004) |
| REQ-QUZ-014 | Summary/drill-down | 032,033 | Quiz Summary, report, attemptDetail | WF5 | RPT-002,004 | DONE | — |
| REQ-QUZ-015 | Recommendation publish | 034 | allocation action | WF5 | — | BROKEN | BUG-QUZ-001 (non-existent column) |
| REQ-QUZ-016 | Soft-delete lifecycle | 002,035 | trash views x5 | WF1 | — | DONE | — |
| REQ-QUZ-017 | Authz/licence/isolation | 036,037,038 | (middleware/policies) | — | — | PARTIAL | BUG-QUZ-005 licence guard; SEC-QUZ-001/002 |
| REQ-QUZ-018 | Activity/proctoring log | 033 | activity-logs views | — | RPT-005 | DONE (view) / EXTERNAL (capture) | Capture owned by portal |

---
---

# C. BUSINESS RULES REGISTER + REQUIREMENT CONDITIONS + VALIDATION CATALOG

## C.1 Business Rules Register (full)
| BR-ID | Rule | Type | Trigger | Enforcement point | Priority |
|-------|------|------|---------|-------------------|----------|
| BR-QUZ-001 | Assessment Type code unique per school | Validation | Create/edit type | DB UNIQUE `uq_quiz_type_code` + FormRequest | P0 |
| BR-QUZ-002 | In-use record cannot be force-deleted | Workflow | Permanent delete | `*UsageCheckService` guards | P1 |
| BR-QUZ-003 | Difficulty Profile code unique | Validation | Create/edit profile | DB UNIQUE `uq_diff_config_code` | P0 |
| BR-QUZ-004 | Σ max% across rules = 100% | Validation | Save profile / add questions | App validation (DifficultyConfigRequest / builder) | P1 |
| BR-QUZ-005 | Σ min% ≤ 100% | Validation | Save profile | App validation | P1 |
| BR-QUZ-006 | Quiz code globally unique | Validation | Quiz create | DB UNIQUE `uq_quiz_code` + model boot | P0 |
| BR-QUZ-007 | Quiz code format fixed pattern | Calculation | Quiz create | `Quiz::boot()` creating hook | P1 |
| BR-QUZ-008 | total_marks/total_questions reconcile to assigned | Calculation | Add/remove questions | Controller / RemedialService `updateQuizTotals` | P1 |
| BR-QUZ-009 | Must be Published to allocate | Workflow | Allocation create | App validation (QuizAllocationController) | P0 |
| BR-QUZ-010 | Status Draft→Published→Archived | Workflow | Status change | App logic | P1 |
| BR-QUZ-011 | No duplicate question in a quiz | Validation | Add question | DB UNIQUE `uq_quiz_ques` | P0 |
| BR-QUZ-012 | Selected ≤ configured max questions/marks | Validation | Save questions | App validation (QuizQuestionController) | P0 |
| BR-QUZ-013 | Effective marks = override ?? default | Calculation | Grading/display | `QuizQuestion::getEffectiveMarksAttribute` | P1 |
| BR-QUZ-014 | Ordinal drives order; reorder persists | Workflow | update-ordinal | Controller | P1 |
| BR-QUZ-015 | only-unused excludes used; only-authorised restricts to for_quiz=1 | Validation | Question fetch | App filter (builder); **remedial path defective (BUG-QUZ-003)** | P1 |
| BR-QUZ-016 | No attempt start after cut-off | Workflow | Start attempt | StudentPortal validation | P0 |
| BR-QUZ-017 | Allocation auto-publish overrides quiz-level | Workflow | Result visibility | App logic | P1 |
| BR-QUZ-018 | due ≥ published; cut-off ≥ due | Validation | Allocation save | App validation | P1 |
| BR-QUZ-019 | target id matches allocation type | Validation | Allocation save | App validation (dynamic) | P1 |
| BR-QUZ-020 | Remedial needs system-default profile | Workflow | Remedial generate | `getSystemDifficultyConfig` (throws) | P1 |
| BR-QUZ-021 | Remedial uses MCQ only | Workflow | Remedial generate | `fetchQuestionsByConfig` (MCQ type filter) | P1 |
| BR-QUZ-022 | Remedial quiz single-attempt, Published | Workflow | Remedial generate | `createQuiz` | P1 |
| BR-QUZ-023 | Remedial generation atomic | Concurrency | Remedial generate | `DB::transaction` | P1 |
| BR-QUZ-024 | Quiz create/update atomic | Concurrency | Quiz save | **MISSING in CRUD (BUG-QUZ-006)** | P1 |
| BR-QUZ-025 | Objective auto-grade; descriptive manual | Workflow | Submit | StudentPortal scoring | P0 |
| BR-QUZ-026 | Result visible only when published | Workflow | Result view | App logic | P0 |
| BR-QUZ-027 | Negative marking floors total at 0 | Calculation | Scoring | Scoring service | P0 |
| BR-QUZ-028 | Cannot award > question max marks | Validation | Manual grade | App validation | P1 |
| BR-QUZ-029 | Recompute totals after all answers graded | Calculation | Manual grade complete | App logic | P1 |
| BR-QUZ-030 | One exclusive system-default profile | Workflow | Profile save | `DifficultyDistributionConfig::booted` saving hook | P1 |
| BR-QUZ-031 | Shared masters scoped by usage type | Validation | Type/profile select | FK to `qns_question_usage_type` + app filter | P0 |
| BR-QUZ-032 | Pending = max(0, assigned − submitted) | Calculation | Summary render | App computation | P1 |
| BR-QUZ-033 | Violation events flagged distinctly | Workflow | Log render | App (substring "VIOLATION") | P2 |
| BR-QUZ-034 | Recommendation publish limited to allocation's quiz + attempting students | Workflow | publishRecommendations | App; **broken by BUG-QUZ-001** | P2 |
| BR-QUZ-035 | Soft-deleted records recoverable | Workflow | Restore | SoftDeletes + restore action | P1 |
| BR-QUZ-036 | Action permission-gated per school | Permission | Every action | Controller `Gate::authorize` (FormRequests inert) | P0 |
| BR-QUZ-037 | Module reachable only by licensed schools | Permission | Route entry | **MISSING guard (BUG-QUZ-005)** | P0 |
| BR-QUZ-038 | Data isolated per school | Permission | Every query | Database-per-tenant connection swap | P0 |

## C.2 Requirement Conditions Catalog
*(Canonical copy also belongs at `5-Requirement_Conditions/LmsQuiz_Conditions.md`; this is the source.)*
Each condition id = the BR id above. On-violation behaviour:
- Validation BRs (001,003,004,005,006,011,012,018,019,028,031) → reject with field-level message; no write.
- Workflow BRs (002,009,010,014,016,020,021,022,025,026,033,034,035) → block the action and explain; no state change.
- Calculation BRs (007,008,013,027,029,032) → compute server-side; never trust client totals.
- Concurrency BRs (023,024) → wrap multi-write operations in a transaction; roll back on failure.
- Permission BRs (036,037,038) → refuse (403) and log; never leak another school's data.

## C.3 Validation & Edge-Case Catalog (selected)
| Field/Rule | Valid | Invalid | Boundary | Empty/null | Concurrency | Expected |
|------------|-------|---------|----------|------------|-------------|----------|
| Assessment code | `WK_QUIZ` | duplicate code | 20 chars | blank | two creates same code | reject duplicate / over-length |
| Profile %-sum | max% rows = 100 | sum = 120 | exactly 100 | no rows | — | reject ≠100 max / >100 min |
| Quiz code | auto-generated unique | manual duplicate | 50 chars | — | concurrent creates | DB UNIQUE rejects collision |
| Questions count | ≤ max | max+1 | == max | 0 selected | two teachers same quiz | block over-max |
| Duplicate question | new question | already-added | — | — | concurrent add | DB UNIQUE rejects |
| Allocation dates | due≥pub, cut≥due | due<pub | due==pub | empty pub = immediate | — | reject bad ordering |
| Allocate Draft quiz | Published | Draft/Archived | — | — | — | block with message |
| Negative marking | net ≥ 0 | computed < 0 | exactly 0 | no wrong answers | — | floor at 0 |
| Manual marks | ≤ question max | > max | == max | blank | — | block over-max |
| Cut-off start | within window | after cut-off | exactly cut-off | no cut-off = open | — | block after cut-off |

---
---

# D. PROCESS FLOWS + STATE-MACHINE CATALOG

## WF1 — Setup → Build → Allocate
Swimlanes: Admin | Teacher | System.
1. [Admin] create Assessment Types + Difficulty Profiles → [System] validate uniqueness & %-rules.
2. [Teacher] create Quiz (Draft) → [System] auto-generate code + UUID.
3. [Teacher] assign questions (manual or builder) → [System] enforce max counts + no-duplicates + reconcile totals.
4. [Teacher] publish Quiz → [System] mark Published.
5. [Teacher] create Allocation (target + window) → [System] block if not Published; validate date ordering.
**Exceptions:** non-Published allocate blocked; over-max questions blocked; duplicate code/question blocked.
**Notifications:** allocation publish should notify the target audience (planned; no in-module code found).

## WF2 — Difficulty Builder
1. [Teacher] open builder, choose profile + filters → 2. [System] compute per-bucket counts, fetch candidates
(honour authorised/unused/scope) → 3. [Teacher] review → 4. [System] bulk-add with ordinals + rule marks →
5. [System] show live pass/fail vs profile.
**Exception:** insufficient candidates for a bucket → flag shortfall.

## WF3 — Attempt → Grade → Publish
Swimlanes: Student (Portal) | Teacher | System.
1. [Student] start attempt (validate window + attempt count) → 2. answer (auto-save) → 3. submit / timeout /
cut-off → 4. [System] auto-grade objective, flag descriptive, compute score/percentage/pass (floor 0) →
5. [Teacher] grade descriptive (≤ max) → 6. [System] recompute → 7. publish (immediate / scheduled / manual).
**Exceptions:** start after cut-off blocked; attempts exhausted blocked; result hidden until published.
**Notifications:** result-publish alert (planned).

## WF4 — Automatic Remedial Generation
1. [System, on fail] read system-default profile (throw if none) → 2. select MCQ candidates by subject/class/
topic → 3. create Published single-attempt remedial quiz → 4. map questions + usage-log audit → 5. reconcile
totals → 6. allocate to student → all within one transaction.
**Exceptions:** no default profile / no candidates → abort cleanly, log, no partial quiz.
**Known defects:** student-target id stored as user id (BUG-QUZ-002); only-unused filter inert (BUG-QUZ-003).

## WF5 — Tracking & Recommendation Publish
1. [Teacher] open Quiz Summary → 2. [System] compute assigned/submitted/pending, flag overdue → 3. [Teacher]
publish recommendations for an allocation → 4. [System] turn on auto-publish, reveal hidden recommendations.
**Known defect:** the attempt lookup uses a non-existent column → nothing published (BUG-QUZ-001).

## D.2 State-Machine Catalogs
**Quiz status** (hard string, not dropdown — see SCH-QUZ-001):
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| Draft | Publish | questions assigned | Published | allocatable |
| Published | Archive | — | Archived | not allocatable |
| Published | Edit→Draft | not yet allocated/attempted (recommended) | Draft | — |
Terminal: Archived. Illegal: allocate while Draft/Archived (blocked by BR-QUZ-009).

**Attempt status** (ENUM on shared table, owned by StudentPortal):
NOT_STARTED → IN_PROGRESS → {SUBMITTED | TIMEOUT | ABANDONED} ; IN_PROGRESS → CANCELLED ;
SUBMITTED → REASSIGNED. Side-effects: SUBMITTED/TIMEOUT trigger grading + (on fail) remedial generation.

---
---

# E. DATA DICTIONARY + CROSS-MODULE DEPENDENCY MAP

## E.1 Owned tables (technical — three-way reconciled DDL ↔ migration ↔ model)
**`lms_assessment_types`** — shared master. Cols: id, code (UNIQUE, 20), name (100), description,
assessment_usage_type_id (FK `qns_question_usage_type`), is_active, timestamps, soft-delete. No `created_by`.
*DDL-spec bug: missing comma before the FK CONSTRAINT (line 65–66); migration is correct.*

**`lms_difficulty_distribution_configs`** — shared master. Cols: id, code (UNIQUE, 50), name, description,
usage_type_id (FK `qns_question_usage_type`), is_active, use_for_system_generated_quiz, timestamps, soft-delete.

**`lms_difficulty_distribution_details`** — child. Cols: id, difficulty_config_id (FK CASCADE),
question_type_id (FK `slb_question_types`), complexity_level_id (FK `slb_complexity_level`), bloom_id,
cognitive_skill_id, ques_type_specificity_id (all nullable FKs to slb_*), min_percentage, max_percentage,
marks_per_question, is_active, timestamps, soft-delete.

**`lms_quizzes`** — quiz master. Cols: id, uuid (BINARY(16) UNIQUE; model `getBytes()`), academic_session_id
(FK global `glb_academic_sessions`), class_id (FK `sch_classes`), subject_id (FK `sch_subjects`),
scope_topic_id (FK `slb_topics`), quiz_type_id (FK `lms_assessment_types`), lesson_id, quiz_code (UNIQUE 50),
title, description, instructions, status (VARCHAR default DRAFT), duration_minutes, total_marks,
total_questions, passing_percentage (33.00), allow_multiple_attempts, max_attempts, negative_marks,
is_randomized, question_marks_shown, show_result_immediately, auto_publish_result, timer_enforced,
show_correct_answer, show_explanation, difficulty_config_id (FK), ignore_difficulty_config,
is_system_generated, only_unused_questions, only_authorised_questions, created_by (FK `sys_users`), is_active,
timestamps, soft-delete. Indexes: idx_quiz_topic, idx_quiz_status.

**`lms_quiz_questions`** — junction. Cols: id, quiz_id (FK CASCADE), question_id (FK `qns_questions_bank`
CASCADE), ordinal, marks_override, is_active, timestamps, soft-delete. UNIQUE(quiz_id, question_id).

**`lms_quiz_allocations`** — Cols: id, quiz_id (FK CASCADE), allocation_type ENUM(CLASS/SECTION/GROUP/STUDENT;
migration order CLASS/GROUP/SECTION/STUDENT — cosmetic), target_table_name, target_id (app-level polymorphic,
no DB FK), assigned_by (FK `sys_users`), published_at, due_date, cut_off_date, is_auto_publish_result,
result_publish_date, is_active, timestamps, soft-delete. Index idx_quiz_alloc_target.

## E.2 Shared runtime tables (DDL-owned by StudentAttempt; models in `Modules\StudentPortal\Models`)
- `lms_quiz_quest_attempts` — assessment_type ENUM(QUIZ/QUEST); **`quiz_id`/`quest_id`** (XOR, CHECK);
  **`quiz_allocation_id`/`quest_allocation_id`** (note: no `allocation_id` column — source of BUG-QUZ-001);
  attempt_number; started_at/submitted_at/auto_submitted_at; status ENUM; score_obtained/max_score/
  percentage/is_passed; proctoring fields. UNIQUE(student,quiz,attempt_number) & (student,quest,attempt_number).
- `lms_quiz_quest_attempt_answers` — attempt_id (FK CASCADE), question_id, question_type_id (cache),
  selected_option_id / selected_option_ids (JSON) / answer_text / attachment_data (JSON), marks_obtained/
  max_marks/is_correct/is_evaluated/evaluated_by, time_spent_seconds/change_count. UNIQUE(attempt_id, question_id).
- `lms_quiz_quest_results` — attempt_id (UNIQUE), student_id, assessment_type + assessment_id (cache),
  total_marks_obtained/max_marks/percentage/grade_obtained/is_passed/rank_in_class/percentile,
  is_published/published_at/teacher_remarks.

## E.3 Cross-Module Dependency Map
**Inbound (LmsQuiz reads):**
| Source | Data | Why |
|--------|------|-----|
| QuestionBank | `qns_questions_bank`, `qns_question_options`, `qns_question_usage_type`, `qns_question_usage_log` | question pool, MCQ options, usage scoping, unused filter + remedial audit |
| SchoolSetup | classes, subjects, sections, groups, class-section junction | mapping + allocation targets |
| Syllabus | lessons, topics, question types, complexity, Bloom, cognitive, specificity | scope + profile rules |
| StudentProfile | `std_students` | attempt subject, student allocation |
| GlobalMaster/Prime | `glb_academic_sessions`, `sys_users` | session, creator/assigner |

**Outbound (consume LmsQuiz):**
| Target | Mechanism | What |
|--------|-----------|------|
| LmsQuests | model import (`AssessmentType`, `DifficultyDistributionConfig`) + shared runtime tables | shared masters; quest attempts |
| LmsExam | model import (`DifficultyDistributionConfig` in `ExamPaper`) | shared difficulty profile |
| Recommendation | `publishRecommendations` flips `StudentRecommendation.is_published` | reveal recommendations (broken — BUG-QUZ-001) |
| StudentPortal | owns attempt player + attempt/result models; calls `RemedialQuizGenerationService` | takes quizzes; triggers remediation |
| Notification (planned) | events | allocation/result alerts (no in-module code) |

---
---

# F. NFR CATALOG + RISK REGISTER

## F.1 NFR Catalog
| NFR-ID | Category | Requirement | Threshold |
|--------|----------|-------------|-----------|
| NFR-QUZ-001 | Performance/Scale | Concurrent attempts per quiz | 500+ without degradation |
| NFR-QUZ-002 | Performance | Difficulty-builder fetch | < 1s over ~1,000 candidates |
| NFR-QUZ-003 | Performance | Auto-submit latency on timeout (portal) | < 5s after timer zero |
| NFR-QUZ-004 | Performance | List/report queries bounded | paginate; no unbounded `get()` in `index()`/reports |
| NFR-QUZ-005 | Security | Per-school authorization on every action | 100% of actions gated |
| NFR-QUZ-006 | Security | Module-licence guard | `hasModule:QUZ` on route group (currently absent) |
| NFR-QUZ-007 | Security | Defence-in-depth (FormRequest authorization) | FormRequests enforce permission (currently return true) |
| NFR-QUZ-008 | Data integrity | Multi-write operations atomic | transaction on quiz create/update/destroy (currently absent) |
| NFR-QUZ-009 | Isolation | Per-school data isolation | no cross-tenant leakage |
| NFR-QUZ-010 | Maintainability | Test coverage | ≥ 40 critical-path tests (currently 0) |

## F.2 Risk Register
| RISK-ID | Risk | Likelihood | Impact | Mitigation | Owner |
|---------|------|:--:|:--:|------------|-------|
| RISK-QUZ-001 | Unlicensed tenant reaches quiz screens (no module guard) | M | H | add `hasModule:QUZ` middleware | Backend |
| RISK-QUZ-002 | Disabled FormRequest authorization + policy-overwrite weakens defence-in-depth | M | H | restore FormRequest authorize(); fix dual `Gate::policy(Quiz)` | Backend |
| RISK-QUZ-003 | Recommendation publishing silently broken (non-existent column) | H | M | fix column name (`quiz_allocation_id`) | Backend |
| RISK-QUZ-004 | Remedial allocation mis-targets student (user_id vs student id) | M | M | store `std_students.id` | Backend |
| RISK-QUZ-005 | Non-atomic quiz CRUD leaves orphan rows on partial failure | M | M | wrap in transaction | Backend |
| RISK-QUZ-006 | Unbounded dashboard/list queries degrade at scale | M | M | paginate / bound aggregations | Backend |
| RISK-QUZ-007 | Route-prefix typo (`lms-quize`) breaks external links | L | M | rename to `lms-quiz` with redirects | Backend |
| RISK-QUZ-008 | Zero tests on grading/scoring logic | H | M | add Pest suite | QA |
| RISK-QUZ-009 | Shared-master coupling: a model change breaks Quest/Exam | L | H | extract LmsMaster or contract-test | Architecture |

---
---

# G. PRIORITIZATION + EFFORT ESTIMATION & SPRINT TASKS

## G.1 MoSCoW
- **Must:** REQ-001,002,003,004,005,006,007,009,010,017 (P0); plus fix BUG-QUZ-005 (licence), SEC-QUZ-001/002.
- **Should:** REQ-008,011,012,013,014,016 (P1); fix BUG-QUZ-001/002/003/006.
- **Could:** REQ-015,018 (P2); ENH-005/006/007.
- **Won't (this release):** student attempt player (StudentPortal owns), parent views, cross-school analytics.

## G.2 Effort Estimation & Sprint Tasks
| # | Task | Type | Effort (h) | Depends on | Sprint |
|---|------|------|:--:|------------|--------|
| 1 | Fix recommendation lookup column (BUG-QUZ-001) | Backend | 2 | — | 1 |
| 2 | Fix remedial student-target id (BUG-QUZ-002) | Backend | 2 | — | 1 |
| 3 | Implement only-unused exclusion in remedial selector (BUG-QUZ-003) | Backend | 3 | — | 1 |
| 4 | Add `hasModule:QUZ` route guard (BUG-QUZ-005) | Backend | 2 | — | 1 |
| 5 | Restore FormRequest authorize() on all 5 requests (SEC-QUZ-001) | Backend | 4 | — | 1 |
| 6 | Fix dual `Gate::policy(Quiz)` overwrite (SEC-QUZ-002) | Backend | 1 | — | 1 |
| 7 | Wrap quiz create/update/destroy in transaction (BUG-QUZ-006) | Backend | 4 | — | 1 |
| 8 | Rename route prefix `lms-quize`→`lms-quiz` + redirects | Backend/Frontend | 6 | — | 2 |
| 9 | Scheduled auto-publish-result job (ENH-002) | Backend | 8 | — | 2 |
| 10 | Dedicated Publish action/route (ENH-005) | Backend/Frontend | 4 | — | 2 |
| 11 | Add `created_by` to masters/junction/allocation (ENH-007) | Schema/Backend | 6 | migration | 2 |
| 12 | Bound dashboard/list queries; paginate (NFR-004) | Backend | 8 | — | 2 |
| 13 | Pest suite: code-gen, %-validation, max-count, negative-marking, allocation dates, scoring | Testing | 28 | 1–7 | 2–3 |
| 14 | Fix `lms_assessment_types` DDL-spec comma (spec only) | Schema | 1 | — | 3 |

---
---

# H. USER STORIES (GHERKIN) + REPORTING & KPI SPEC

## H.1 User Stories (one per P0/P1 REQ; happy + boundary + permission + empty)
**US-QUZ-001 (REQ-QUZ-001, P0):** As an Admin I want to manage assessment types so categories are standardized.
- Happy: Given a unique code, when I save, then the type is created and offered in quiz creation (if usage = Quiz).
- Boundary: Given a duplicate code, when I save, then a validation error is shown.
- Permission: Given no manage permission, when I open the screen, then I cannot create/edit.
- Empty: Given no types, when I open quiz creation, then the type dropdown is empty with a hint.

**US-QUZ-002 (REQ-QUZ-002, P0):** As an Admin I want difficulty profiles so quizzes stay balanced.
- Happy: Given rules summing to 100% max, when I save, then the profile is usable.
- Boundary: Given max% sum ≠ 100, when I save, then I am warned.
- Permission/Exclusive: Given one default exists, when I flag another as default, then the previous default is cleared.

**US-QUZ-003 (REQ-QUZ-003, P0):** As a Teacher I want to create a quiz mapped to a topic.
- Happy: Given valid hierarchy, when I save, then a unique quiz code is generated.
- Boundary: Given topic level 3, when selected, then exactly topic dropdowns 1–3 enable.
- Permission: no create permission → blocked. Empty: no lessons → lesson dropdown empty.

**US-QUZ-005 (REQ-QUZ-005, P0):** As a Teacher I want to add Question Bank questions to a quiz.
- Happy: select within max → saved with ordinals. Boundary: max+1 → blocked.
- Duplicate: add same question twice → rejected. Permission: no permission → blocked.

**US-QUZ-006 (REQ-QUZ-006, P0):** As a Teacher I want the builder to pick balanced questions.
- Happy: profile chosen → candidate counts match percentages. Boundary: shortfall flagged.
- Empty: no candidates → clear message.

**US-QUZ-007 (REQ-QUZ-007, P0):** As a Teacher I want to allocate a published quiz to a student.
- Happy: select Student → section+student pickers appear → allocation saved.
- Boundary: due<published → rejected. Workflow: allocate Draft quiz → blocked. Permission: blocked without right.

**US-QUZ-008 (REQ-QUZ-008, P1):** As the System I generate a remedial quiz when a student fails.
- Happy: default profile + candidates → single-attempt remedial allocated to the student.
- Exception: no default profile → abort + log, no partial quiz. Empty: no candidates → abort cleanly.

**US-QUZ-009 (REQ-QUZ-009, P0):** As a Student I take an allocated quiz (via portal).
- Happy: within window + attempts remain → attempt starts. Boundary: after cut-off → blocked.
- Boundary: attempts exhausted → blocked.

**US-QUZ-010 (REQ-QUZ-010, P0):** As the System I auto-grade objective answers.
- Happy: all correct → full marks. Boundary: wrong answers with negative marking → never below 0.
- Descriptive: left ungraded for the teacher.

**US-QUZ-011 (REQ-QUZ-011, P1):** As a Teacher I grade descriptive answers.
- Happy: award ≤ max → saved. Boundary: > max → blocked. Recompute: totals update when all graded.

**US-QUZ-012 (REQ-QUZ-012, P1):** As a Teacher I publish results.
- Happy: manual publish → students see results. Auto: at result date (gap: no scheduler). Hidden until published.

**US-QUZ-013 (REQ-QUZ-013, P1):** As an Academic Head I view the dashboard and reports.
- Happy: filters change → KPIs/charts refresh. Permission: unauthorised report tab is hidden. Isolation: own school only.

**US-QUZ-014 (REQ-QUZ-014, P1):** As a Teacher I track who has not submitted.
- Happy: 30 assigned, 20 done → "20 Done / 10 Pending". Boundary: pending never negative. Overdue flagged red.

**US-QUZ-016 (REQ-QUZ-016, P1):** As a Teacher I restore a mistakenly deleted quiz.
- Happy: trashed quiz → restore → back in active list. Guard: in-use record cannot be force-deleted.

**US-QUZ-017 (REQ-QUZ-017, P0):** As the platform I enforce per-school authorization and licensing.
- Permission: no permission → 403. Licence: unlicensed school → blocked (gap). Isolation: no cross-school data.

## H.2 Reporting & KPI Spec
| RPT-ID | Purpose | Audience | Frequency | Contents | Filters | Export |
|--------|---------|----------|-----------|----------|---------|--------|
| RPT-QUZ-001 | Quiz Dashboard | Admin/Teacher | Real-time | 6 KPIs, monthly-activity bar, score-distribution doughnut, subject & status breakdowns | class/section, subject, status, date range | screen |
| RPT-QUZ-002 | Quiz Summary tracking | Teacher/Admin | Real-time | per-allocation assigned/done/pending, overdue flag, target name | class/section, subject, date range, search | screen |
| RPT-QUZ-003 | Analytics hub (6) | Admin/Teacher | On-demand | class performance, teacher monthly, student summary, student detailed, periodic, current-class | per report; permission-gated | screen |
| RPT-QUZ-004 | Per-quiz drill-down + attempt detail | Teacher/Admin | On-demand | student-by-student scores; question-by-question for one attempt | quiz, allocation | screen |
| RPT-QUZ-005 | Activity/Proctoring log | Invigilator/Admin/Teacher | On-demand | events with quiz/student/attempt context, payload, timestamp; violations flagged | quiz, event type, attempt, student, date | screen |

**KPIs:** Total Quizzes (+ Published); Questions in pool; Allocations; Attempts (+ In-Progress); Submitted
(+ completion rate = submitted ÷ assigned); Average Score % = mean of attempt percentages. Pass Rate =
passed ÷ submitted. Pending = max(0, assigned − submitted).

---
---

# I. FEATURE SPECIFICATION (screen-by-screen)

## I.1 Business Entities & Relationships
Quiz belongs to a session/class/subject/lesson and an Assessment Type, optionally a Difficulty Profile and a
scope Topic. A Quiz has many Question Links (to Question Bank questions) and many Allocations. An Allocation
targets a class/section/group/student. A student's Attempt (shared with Quest) belongs to a quiz and an
allocation, has many Answers, and produces one Result.

## I.2 Screen Specifications (8-tab hub + reports)
**Tab container (8 tabs):** Dashboard, Difficulty Config, Assessment Types, Quiz Creation, Quiz Questions,
Quiz Allocation, Quiz Summary, Activity Log — each gated by its own `tenant.*` permission.

**Screen: Assessment Type CRUD** — fields: code (req, unique, ≤20), name (req, ≤100), usage type (req,
dropdown Quiz/Quest/Online Exam/Offline Exam), description, active toggle. Actions: Create/Edit/Delete/Toggle/
Restore/Force-delete. Empty state: "No assessment types yet." Permissions: `tenant.assessment-type.*`.

**Screen: Difficulty Config** — left header (code, name, usage type, description, system-generated toggle,
active); right dynamic rule rows (question type, complexity, min%, max%, marks/q; advanced: Bloom, cognitive,
specificity). Action: add/remove rows; save. Permissions: `tenant.difficulty-config.*`.

**Screen: Quiz Create/Edit (2-tab)** — Tab 1 academic mapping (class→subject→lesson AJAX; topic level 1–4
cascade; title, type, status); Tab 2 config (duration, marks, questions, passing %, negative marks, max
attempts; 10 behavioural switches; difficulty profile + ignore toggle). Permissions: `tenant.quiz.*`.

**Screen: Quiz Questions (3-tab)** — quiz selector + live counters (selected/max questions & marks); Tab 1
selection (accordion filters: academic, properties, usage); Tab 2 review (edit ordinal + marks, remove);
Tab 3 validation (difficulty limits pass/fail, overall limits). Difficulty Builder sub-tab. AJAX endpoints
for sections/subjects/topics/search/existing/bulk-store/bulk-destroy/update-ordinal/update-marks.
Permissions: `tenant.quiz-question.*`.

**Screen: Quiz Allocation CRUD** — quiz dropdown (+ "unused only" filter); allocation type (CLASS locks to
quiz class; SECTION/GROUP/STUDENT reveal pickers); published-at, due, cut-off; auto-publish toggle reveals
result-publish date. Permissions: `tenant.quiz-allocation.*`.

**Screen: Quiz Summary** — filter (class/section, subject, date range, search); grid of allocations with
target, subject, due (red+bold if overdue), publish date, # assigned, Done/Pending badges, Report action.

**Screen: Activity Log** — filter (quiz, event type, attempt, student, date); grid with quiz/student, event
(red if VIOLATION), JSON payload, occurred-at, View action.

**Screen: Reports hub (6 tabs)** — each permission-gated: class performance, teacher monthly, student
performance summary, student detailed assessment, periodic detail, current-class performance; filter
dependencies via AJAX.

**Screen: Trash views (x5)** — soft-deleted lists per entity with Restore + Force-delete (usage-guarded).

## I.3 Acceptance Criteria (per screen)
Each screen's create/edit blocks invalid input per Section C.3, hides actions the user lacks permission for,
shows an empty-state message, and is scoped to the current school. The Quiz Questions screen blocks saving
over the quiz's max counts; the Allocation screen blocks Draft/Archived quizzes and bad date ordering; the
Summary screen never shows a negative pending count.

---

*End of QUZ Complete Analysis Pack. FRD is the single source of truth; downstream audits reuse the
REQ-/BR-/RPT-/ENH- IDs above without renumbering.*
