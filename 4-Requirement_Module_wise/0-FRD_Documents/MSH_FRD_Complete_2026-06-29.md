# Functional Requirements Document (Complete Analysis Pack) — MarksheetGeneration
# Prime-AI School ERP Platform

| Field | Value |
|-------|-------|
| **Module Name** | MarksheetGeneration |
| **Module Code** | MSH |
| **Table Prefix** | `msh_` |
| **Document Version** | 1.0 |
| **Date** | 2026-06-29 |
| **Status** | Draft |
| **Prepared By** | Business Analysis — Prime-AI |
| **Reviewed By** | (Pending) |
| **Approved By** | (Pending) |
| **Document Type** | Complete Analysis Pack (FRD-first; all artifacts as `## Section`s, shared IDs) |
| **Sources** | Live module code (`Modules/MarksheetGeneration`), consolidated DDL (`MarksheetGeneration_DDL_v1.sql`, 23 tables), 23 tenant migrations, models/services, legacy design pack (D32, `MSG_RequirementSpec.md`), V1 screen specs (`MarksheetGeneration_V2/`) |

> **Naming note.** The canonical module code is **MSH** (per `module_list.md`). The legacy design pack and DDL use the
> code **MSG** and rule IDs `BR-MSG-`/`FR-MSG-`. This FRD renumbers to `REQ-MSH-`/`BR-MSH-`/`RPT-MSH-`/`ENH-MSH-` as the
> downstream contract; legacy MSG IDs appear only as cross-references. MSG and MSH are the same module.

---

## Table of Contents (Complete Analysis Pack)

- **Section 1–10** — Functional Requirements Document (the spine; all later sections cite its IDs)
- **Section 11** — Requirements Traceability Matrix (RTM)
- **Section 12** — Business Rules Register (standalone) + Requirement Conditions Catalog + Validation & Edge-Case Catalog
- **Section 13** — Process Flows + State Machine (FSM) Catalog
- **Section 14** — Data Dictionary (business + technical) + Cross-Module Dependency Map
- **Section 15** — NFR Catalog + Risk Register
- **Section 16** — Prioritization (MoSCoW) + Effort Estimation & Sprint Task Breakdown
- **Section 17** — User Stories (Gherkin) + Reporting & KPI Spec
- **Section 18** — Feature Specification (screen-by-screen)

---
---

# Section 1 — Module Overview

## 1.1 Business Purpose

MarksheetGeneration is the school's **result consolidation and report-card engine**. A Prime-AI school records marks in
several separate places — formal examinations, homework, quizzes, quests, and behavioural assessment — but none of these
on their own produces the single report card that Indian K-12 schools must issue to students and parents. This module
gathers all of those scores for a chosen term or session, applies the school's chosen weightages and grading rules, and
produces a subject-wise, exam-wise marksheet with totals, grade, division, rank, attendance, co-scholastic grades, and
promotion status. Without it, a school must assemble report cards manually in spreadsheets, with no audit trail and no
guarantee that two teachers compute the same student's result the same way.

## 1.2 Business Value

- Eliminates manual report-card assembly across multiple mark sources, saving days of clerical effort each term.
- Produces board-compliant report cards (CBSE 9-point grade, ICSE/State division formats, or a school's custom scheme).
- Guarantees one consistent, repeatable calculation for every student — totals, grades, ranks, and promotion are
  computed by the system, not by hand.
- Keeps an audit trail of every computation and every after-publication correction (who, when, and why).
- Lets parents and students see results the moment they are published, through the existing portals.

## 1.3 Scope

### In Scope
1. Configuring marksheet **types** (Unit Test, Term-1, Annual) and reusable configuration **templates**.
2. Choosing which **score sources** (Examination, Homework, Quiz, Quest) contribute and their **weightages**.
3. Grouping exam types into **terms** (e.g. Term-1 = UT-1 + UT-2 + Half-Yearly) and setting **per-exam weightages**.
4. Defining marksheet-specific **class groups** (Primary / Middle / Secondary) and assigning templates to classes or groups.
5. Configuring **Internal Assessment** components (Notebook, Subject Enrichment, etc.) and **Co-Scholastic** areas.
6. Configuring **theory/practical** mark splits per class-subject.
7. Creating **marksheet schedules** (one generation event per term/exam) for chosen class-sections.
8. **Computing** all student results for a schedule as a background job.
9. **Reviewing**, **publishing**, **locking**, and (with reason) **unlocking** results.
10. Teacher **entry** of IA marks, co-scholastic grades, and (Phase 1) attendance summary.
11. **Viewing, printing, and exporting** individual and bulk marksheets.
12. Computing **rank, division, and promotion status**.

### Out of Scope
1. Entry of the underlying exam/homework/quiz/quest marks — owned by **LmsExam, LmsHomework, LmsQuiz, LmsQuests**.
2. The Holistic Progress Card (NEP-2020) — owned by the **Hpc** module (separate templates and workflow).
3. Computing behavioural scores — owned by **BehaviouralAssessment** (this module only reads the result).
4. Transfer / bonafide / achievement certificates — owned by the **Certificate** module.
5. Linking result access to fee payment — handled (if at all) by **StudentFee**; not a marksheet concern.
6. Daily attendance capture — owned by the (planned) **Attendance** module; this module only holds a per-schedule summary.

## 1.4 Key Terminology

| Business Term | Meaning |
|---------------|---------|
| Marksheet Type | A named category of report card the school issues (Unit Test Result, Term-1 Report Card, Annual Report Card). |
| Configuration Template | A reusable blueprint that says which scores count, their weightages, the grading scheme, and pass/promotion rules. One template can serve many classes. |
| Source Component | A score source that feeds the marksheet — Examination (always required), Homework, Quiz, Quest. |
| Exam Group | A bundle of exam types treated as one term (e.g. Term-1 = UT-1 + UT-2 + Half-Yearly). |
| Class Group | A marksheet-specific grouping of classes (Primary 1–5, Middle 6–8, Secondary 9–12) used to share a template. |
| Internal Assessment (IA) | Teacher-assessed components such as Notebook and Subject Enrichment, with their own max marks. |
| Co-Scholastic Area | Non-academic graded areas (Work Education, Art Education, Health & Physical Education, Discipline). |
| Theory/Practical Split | For lab subjects, the division of a subject's marks into a theory portion and a practical portion. |
| Marksheet Schedule | A single generation event — "produce these report cards for these class-sections now." |
| Computation | The background process that reads all source scores and writes each student's results for a schedule. |
| Division | The overall band a student falls in (First / Second / Third Division, or Pass/Fail) from the grading scheme. |
| Promotion Status | The outcome derived from pass/fail across subjects: Promoted, Detained, Compartment, or Placed. |
| Withheld | A result deliberately not declared (e.g. pending enquiry); shown as "WH" instead of marks. |
| Absent | No mark because the student did not appear; shown as "AB", counted as no-mark rather than zero. |
| Best-of-N | An optional rule where only the best N of several unit-test scores count toward the result. |
| Result Lifecycle | The stages a schedule passes through: Draft → Computed → Reviewed → Published → Locked. |

---

# Section 2 — User Roles & Access

## 2.1 Actor Definitions

| Role | Who They Are | Their Relationship to This Module |
|------|-------------|-----------------------------------|
| School Admin | School-level administrator/operations owner | Configures types, templates, exam/class groups, schedules; triggers computation; unlocks results. |
| Principal | Head of school | Reviews computed results, approves publication, authorises unlocks. |
| Academic Coordinator | Senior academic staff | Sets up IA components, co-scholastic areas, theory/practical configs, promotion criteria. |
| Class Teacher | Teacher in charge of a section | Reviews class results, enters co-scholastic grades and attendance, previews/prints marksheets. |
| Subject Teacher | Teacher of a subject | Enters Internal Assessment marks for their subject. |
| Student | Enrolled learner | Views own published marksheet on the Student Portal. |
| Parent | Guardian of a student | Views their child's published marksheet on the Parent Portal. |

## 2.2 Role-Feature Access Matrix

| Feature | School Admin | Principal | Academic Coordinator | Class Teacher | Subject Teacher | Student/Parent |
|---------|------|------|------|------|------|------|
| Marksheet Types & Templates | Full Access | View | Full Access | No Access | No Access | No Access |
| Source/Exam Weightages | Full Access | View | Full Access | No Access | No Access | No Access |
| Exam Groups & Class Groups | Full Access | View | Full Access | No Access | No Access | No Access |
| IA / Co-Scholastic / Practical config | Full Access | View | Full Access | View | No Access | No Access |
| Template-to-class assignment | Full Access | View | Full Access | No Access | No Access | No Access |
| Marksheet Schedule setup | Full Access | View | Full Access | No Access | No Access | No Access |
| Trigger Computation | Full Access | View | Full Access | No Access | No Access | No Access |
| IA Marks entry | View | View | View | View | Full Access (own subject) | No Access |
| Co-Scholastic / Attendance entry | View | View | Full Access | Full Access (own section) | No Access | No Access |
| Result Review | Full Access | Full Access | Full Access | View (own section) | No Access | No Access |
| Publish / Lock / Unlock | Full Access | Full Access (approve) | No Access | No Access | No Access | No Access |
| Withhold / Declare a result | Full Access | Full Access | No Access | No Access | No Access | No Access |
| Marksheet Preview / Print / PDF | Full Access | Full Access | Full Access | Full Access (own section) | No Access | View own (published) |
| Computation Audit Log | Full Access | View | View | No Access | No Access | No Access |

---

# Section 3 — Functional Requirements

### 3.1 Marksheet Type Master
**Requirement ID:** REQ-MSH-001
**Priority:** Core (P0)
**Category Tags:** [DATA_ENTRY] [CONFIGURATION]

#### Business Description
The School Admin maintains the list of marksheet types the school issues — for example "Unit Test Result", "Term-1
Report Card", and "Annual Report Card". Each type has a code, a display name, an order, and an active flag. Types are the
top-level vocabulary every template and schedule refers to, so the school can speak about results in its own terms.

#### Actors
- **Initiates:** School Admin / Academic Coordinator
- **Processes / Approves:** School Admin
- **Views / Receives notification:** Anyone configuring templates and schedules

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-001 | Each marksheet type code must be unique within the school. | Validation |
| BR-MSH-002 | A marksheet type that is referenced by any template or schedule cannot be hard-deleted; it is deactivated (archived) instead. | Workflow |

#### Acceptance Criteria
1. An admin can create, edit, archive, and restore a marksheet type, and set its display order.
2. Creating a type with a code that already exists is rejected with a clear message.
3. Inactive types do not appear in template/schedule selection lists.

#### Integration with Other Modules
- Receives from: None. Sends to: None (internal master).

#### Enhancement Notes (Future)
Pre-seed board-standard type sets (CBSE/ICSE) on tenant onboarding — see ENH-MSH-001.

---

### 3.2 Source Component & Internal-Assessment Catalog
**Requirement ID:** REQ-MSH-002
**Priority:** Core (P0)
**Category Tags:** [CONFIGURATION]

#### Business Description
The school maintains the catalog of score sources (Examination, Homework, Quiz, Quest) and the catalog of Internal
Assessment component types (Notebook, Subject Enrichment, Periodic Assessment, Class Participation). Examination is always
a mandatory source. These catalogs are seeded for every school at onboarding and the school can extend the IA list.

#### Actors
- **Initiates:** System (seed) / Academic Coordinator (extend IA types)
- **Processes / Approves:** School Admin
- **Views / Receives notification:** Template builders

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-003 | Examination is a mandatory source component and must be present in every template. | Validation |
| BR-MSH-004 | Source component and IA component-type codes are each unique within the school. | Validation |

#### Acceptance Criteria
1. The four source components are available immediately after onboarding, with Examination flagged mandatory.
2. The standard IA component types are available and an admin can add more.
3. A duplicate code is rejected.

#### Integration with Other Modules
- Receives from: None. Sends to: None (internal masters).

#### Enhancement Notes (Future)
Allow custom school-defined source components (currently fixed) — see ENH-MSH-002.

---

### 3.3 Configuration Template Builder
**Requirement ID:** REQ-MSH-003
**Priority:** Core (P0)
**Category Tags:** [CONFIGURATION] [WORKFLOW]

#### Business Description
The School Admin builds a reusable configuration template for a session and marksheet type. The template names the exam
group it covers, chooses the grading scheme, sets the passing percentage and the compartment threshold, and optionally
turns on the Best-of-N rule. The template is the single object that defines "how this report card is calculated", and it
can be reused across many classes. Once a template is tied to a published schedule it becomes locked so historical results
cannot drift.

#### Actors
- **Initiates:** School Admin / Academic Coordinator
- **Processes / Approves:** School Admin
- **Views / Receives notification:** Class Teachers (read), Principal (review)

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-005 | A template's code is unique within an academic session. | Validation |
| BR-MSH-006 | A template must reference exactly one exam group and (where grades are produced) one grading scheme. | Validation |
| BR-MSH-007 | The passing percentage and compartment threshold are configurable per template (defaults: 33% pass, up to 2 failures = Compartment). | Configuration |
| BR-MSH-008 | A template linked to a published schedule is locked and cannot be edited; changing the rules requires a new template. | Workflow |

#### Acceptance Criteria
1. An admin can create a template, choose its exam group and grading scheme, and set pass/compartment rules.
2. A locked template cannot be edited and the screen explains why.
3. Templates can be reused by assigning them to multiple classes/groups.

#### Integration with Other Modules
- Receives from: Syllabus (grading/division bands). Sends to: None.

#### Enhancement Notes (Future)
"Copy from previous year" to clone a template into a new session — see ENH-MSH-003.

---

### 3.4 Source-Component Weightage Setup
**Requirement ID:** REQ-MSH-004
**Priority:** Core (P0)
**Category Tags:** [CONFIGURATION] [DATA_ENTRY]

#### Business Description
Within a template, the school decides how much each source contributes to a subject's marks — for example Examination
80%, Homework 10%, Quiz 10%. The contributions must add up to exactly 100% so every subject is scored on a complete basis.

#### Actors
- **Initiates:** School Admin / Academic Coordinator
- **Processes / Approves:** School Admin
- **Views / Receives notification:** Reviewers

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-009 | The sum of source-component weightages within a template must equal 100%. | Calculation |
| BR-MSH-010 | A source component may appear at most once per template. | Validation |

#### Acceptance Criteria
1. Saving weightages that do not total 100% is rejected with the running total shown.
2. The same source cannot be added twice to one template.
3. Examination is always present (per BR-MSH-003).

#### Integration with Other Modules
- Receives from: None. Sends to: None.

#### Enhancement Notes (Future)
None.

---

### 3.5 Exam Grouping & Per-Exam Weightage
**Requirement ID:** REQ-MSH-005
**Priority:** Core (P0)
**Category Tags:** [CONFIGURATION]

#### Business Description
The school groups individual exam types into a term (e.g. Term-1 = Unit Test 1 + Unit Test 2 + Half-Yearly) and sets how
much each exam type counts inside the Examination component (e.g. UT-1 10%, UT-2 10%, Half-Yearly 80%). Exam groups carry
a date range so homework/quiz/quest scores can be averaged over the right period.

#### Actors
- **Initiates:** School Admin
- **Processes / Approves:** School Admin
- **Views / Receives notification:** Template builders

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-011 | An exam group belongs to one academic session and its code is unique within that session. | Validation |
| BR-MSH-012 | The sum of per-exam-type weightages within a template's Examination component must equal 100%. | Calculation |
| BR-MSH-013 | An exam type may appear at most once within an exam group. | Validation |

#### Acceptance Criteria
1. An admin can create a term group and add/remove exam types with a display order.
2. Per-exam weightages that do not total 100% are rejected.
3. The exam group's date range is used to bound homework/quiz/quest averaging.

#### Integration with Other Modules
- Receives from: LmsExam (exam types). Sends to: None.

#### Enhancement Notes (Future)
None.

---

### 3.6 Class Group Management & Template Assignment
**Requirement ID:** REQ-MSH-006
**Priority:** Core (P0)
**Category Tags:** [CONFIGURATION]

#### Business Description
The school creates marksheet-specific class groups (Primary, Middle, Secondary) and assigns a template either to a whole
group or directly to an individual class. A direct class assignment always wins over the group assignment, so a single
class can be treated differently from its group when needed.

#### Actors
- **Initiates:** School Admin
- **Processes / Approves:** School Admin
- **Views / Receives notification:** Reviewers

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-014 | Marksheet class groups are maintained inside this module; the timetable's class grouping is not used here. | Workflow |
| BR-MSH-015 | A template assignment targets exactly one of: a single class, or a class group — never both and never neither. | Validation |
| BR-MSH-016 | When a class is covered by both a direct assignment and its group's assignment, the direct assignment is used. | Calculation |

#### Acceptance Criteria
1. An admin can create class groups and add/remove classes.
2. A template can be assigned to a group or to an individual class.
3. For a class with both, computation uses the directly assigned template.

#### Integration with Other Modules
- Receives from: SchoolSetup (classes). Sends to: None.

#### Enhancement Notes (Future)
None.

---

### 3.7 Internal Assessment & Co-Scholastic Configuration
**Requirement ID:** REQ-MSH-007
**Priority:** Standard (P1)
**Category Tags:** [CONFIGURATION]

#### Business Description
Within a template, the school defines its Internal Assessment components and their max marks (Notebook 5, Subject
Enrichment 5, etc.), and its Co-Scholastic areas with a 3-point or 5-point grading scale (Work Education, Art Education,
Health & PE, Discipline). The Discipline area can be set to auto-populate from the BehaviouralAssessment module.

#### Actors
- **Initiates:** Academic Coordinator
- **Processes / Approves:** School Admin
- **Views / Receives notification:** Class/Subject Teachers (entry)

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-017 | Each IA component and each co-scholastic area is unique within a template. | Validation |
| BR-MSH-018 | A co-scholastic area uses a defined grading scale (3-point or 5-point). | Validation |
| BR-MSH-019 | If a co-scholastic area is linked to behavioural assessment, its grade is auto-populated and only used when behavioural-result integration is enabled for the session. | Workflow |

#### Acceptance Criteria
1. An admin can add IA components with max marks and co-scholastic areas with a grading scale.
2. A behaviour-linked area auto-fills the Discipline grade when integration is on.
3. Duplicate components/areas within a template are rejected.

#### Integration with Other Modules
- Receives from: BehaviouralAssessment (Discipline grade when linked). Sends to: None.

#### Enhancement Notes (Future)
None.

---

### 3.8 Theory/Practical Split Configuration
**Requirement ID:** REQ-MSH-008
**Priority:** Core (P0)
**Category Tags:** [CONFIGURATION]

#### Business Description
For lab subjects the school records how a subject's marks split into theory and practical (e.g. Science Class 9: Theory 70,
Practical 30). Only subjects that actually have a practical need a configuration row.

#### Actors
- **Initiates:** Academic Coordinator
- **Processes / Approves:** School Admin
- **Views / Receives notification:** Computation engine

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-020 | A theory/practical configuration is unique per academic session, class, and subject. | Validation |
| BR-MSH-021 | Theory max marks plus practical max marks must equal the subject's total exam marks. | Calculation |
| BR-MSH-022 | Where a school's theory and practical papers cannot be told apart by their maximum marks, the school must designate the split explicitly. | Validation |

#### Acceptance Criteria
1. An admin can set theory/practical max marks for a class-subject and toggle "has practical".
2. A split whose parts do not sum to the subject total is rejected.
3. Subjects without practicals need no configuration and are treated as theory-only.

#### Integration with Other Modules
- Receives from: SchoolSetup (subjects/classes), LmsExam (paper totals). Sends to: None.

#### Enhancement Notes (Future)
Add an explicit practical flag at the exam-paper level to remove the marks-matching ambiguity — see ENH-MSH-004 (legacy Q-13).

---

### 3.9 Marksheet Schedule Setup
**Requirement ID:** REQ-MSH-009
**Priority:** Core (P0)
**Category Tags:** [WORKFLOW] [CONFIGURATION]

#### Business Description
The School Admin creates a marksheet schedule — a single generation event that names the marksheet type, the term/exam
group, the issue date, and the class-sections to include. The schedule is the object every computed result is attached to,
and it carries the result lifecycle status.

#### Actors
- **Initiates:** School Admin
- **Processes / Approves:** School Admin / Principal
- **Views / Receives notification:** Class Teachers

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-023 | A schedule's code is unique within an academic session. | Validation |
| BR-MSH-024 | A schedule must reference a configuration template and at least one class-section. | Validation |
| BR-MSH-025 | A school may run multiple schedules per year (after each exam, each term, or annually); each is independent. | Workflow |

#### Acceptance Criteria
1. An admin can create a schedule, pick its template/term, and add class-sections.
2. A schedule with no class-sections cannot be computed.
3. Multiple schedules can coexist for one session.

#### Integration with Other Modules
- Receives from: SchoolSetup (class-sections). Sends to: None.

#### Enhancement Notes (Future)
None.

---

### 3.10 Result Computation
**Requirement ID:** REQ-MSH-010
**Priority:** Core (P0)
**Category Tags:** [WORKFLOW] [INTEGRATION] [SCHEDULED]

#### Business Description
When a schedule is ready, the admin triggers computation. The system runs in the background: for every student in every
included class-section it reads the exam, homework, quiz, and quest scores, applies the template's weightages and
theory/practical split, adds Internal Assessment marks, computes each subject's total and grade, then the overall total,
percentage, grade, division, rank, and promotion status. Each run is recorded in an audit log, and a student's marksheet
only includes the subjects that student is actually enrolled in.

#### Actors
- **Initiates:** School Admin
- **Processes / Approves:** System (background job)
- **Views / Receives notification:** Admin (progress + errors)

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-026 | Computation may run only when the schedule is in Draft or Computed status (never Published or Locked). | Workflow |
| BR-MSH-027 | Two computations for the same schedule cannot run at the same time. | Concurrency |
| BR-MSH-028 | A student's marksheet includes only the subjects the student is enrolled in; an un-enrolled subject is absent, not zero. | Calculation |
| BR-MSH-029 | An absent score is recorded as no-mark and shown "AB"; a withheld score is shown "WH"; neither is treated as zero. | Calculation |
| BR-MSH-030 | When Best-of-N is enabled, only the best N of the configured unit-test scores count toward the Examination component. | Calculation |

#### Acceptance Criteria
1. Triggering computation queues a background run and shows progress and any per-student errors.
2. Each subject total reflects the configured weightages, theory/practical split, and IA marks.
3. Overall total, percentage, grade, division, section rank, and promotion status are produced per student.
4. Absent/withheld marks appear as "AB"/"WH"; un-enrolled subjects do not appear.
5. A second computation for the same schedule is blocked while one is running.

#### Integration with Other Modules
- Receives from: LmsExam, LmsHomework, LmsQuiz, LmsQuests (scores), BehaviouralAssessment (Discipline), Syllabus (grades), StudentProfile/SchoolSetup (enrolment). Sends to: None (writes only its own result tables).

#### Enhancement Notes (Future)
Auto-recompute trigger when a source mark is corrected — see ENH-MSH-005.

---

### 3.11 Internal-Assessment, Co-Scholastic & Attendance Entry
**Requirement ID:** REQ-MSH-011
**Priority:** Standard (P1)
**Category Tags:** [DATA_ENTRY]

#### Business Description
Subject Teachers enter Internal Assessment marks (Notebook, Enrichment, etc.) per student per subject for a schedule.
Class Teachers / Coordinators enter co-scholastic grades per student per area, and (in Phase 1) the attendance summary —
total working days and days present — per student. These values feed the computed marksheet.

#### Actors
- **Initiates:** Subject Teacher (IA) / Class Teacher (co-scholastic, attendance)
- **Processes / Approves:** Academic Coordinator
- **Views / Receives notification:** Computation engine, reviewers

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-031 | Entered IA marks cannot exceed the component's configured max marks. | Validation |
| BR-MSH-032 | A co-scholastic grade must be a valid value on the area's grading scale. | Validation |
| BR-MSH-033 | Days present cannot exceed total working days. | Validation |
| BR-MSH-034 | Behaviour-linked co-scholastic grades are not manually editable when auto-population is on. | Workflow |

#### Acceptance Criteria
1. A subject teacher can enter/update IA marks for their subject, bounded by max marks.
2. A class teacher can enter co-scholastic grades and attendance for their section.
3. Invalid (over-max, off-scale, present > working days) entries are rejected.

#### Integration with Other Modules
- Receives from: BehaviouralAssessment (auto Discipline grade). Sends to: None.

#### Enhancement Notes (Future)
Bulk Excel upload of IA / attendance — see ENH-MSH-006.

---

### 3.12 Result Review
**Requirement ID:** REQ-MSH-012
**Priority:** Standard (P1)
**Category Tags:** [WORKFLOW] [APPROVAL]

#### Business Description
After computation, a Principal or Class Teacher reviews the class result grid — students against subjects and exams, with
totals, grades, and flagged anomalies (Absent, Withheld, very low). The schedule moves from Computed to Reviewed to mark
that the results have been checked before publication.

#### Actors
- **Initiates:** Principal / Class Teacher
- **Processes / Approves:** Principal
- **Views / Receives notification:** School Admin

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-035 | A schedule can move to Reviewed only from Computed status. | Workflow |
| BR-MSH-036 | The reviewer's identity and time are recorded for the review step. | Workflow |

#### Acceptance Criteria
1. A reviewer can open the class grid and see per-student subject/exam breakdowns and anomalies.
2. Marking a schedule Reviewed is allowed only from Computed.
3. The review is recorded with who and when.

#### Integration with Other Modules
- Receives from: None. Sends to: None.

#### Enhancement Notes (Future)
None.

---

### 3.13 Publish, Lock & Unlock
**Requirement ID:** REQ-MSH-013
**Priority:** Core (P0)
**Category Tags:** [WORKFLOW] [APPROVAL] [NOTIFICATION]

#### Business Description
A Principal/Admin publishes a reviewed schedule, which makes results visible to students and parents, locks the underlying
template, and records the event. A published schedule can be locked to freeze it. If a correction is needed after
publishing, an admin must unlock with a mandatory reason; this returns the schedule to Computed, records the reason in the
audit log, and allows re-computation.

#### Actors
- **Initiates:** Principal / School Admin
- **Processes / Approves:** Principal
- **Views / Receives notification:** Students, Parents, Class Teachers

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-037 | Publishing is allowed only from Reviewed status and locks the linked template. | Workflow |
| BR-MSH-038 | Locking is allowed only from Published status. | Workflow |
| BR-MSH-039 | Unlocking requires a mandatory reason, returns the schedule to Computed, and writes an audit-log entry with the reason, user, and time. | Workflow |
| BR-MSH-040 | Students and parents can see a marksheet only after its schedule is published. | Permission |

#### Acceptance Criteria
1. Publishing a reviewed schedule notifies stakeholders, locks the template, and records the event.
2. Lock is allowed only from Published; publish only from Reviewed.
3. Unlock without a reason is rejected; with a reason it returns to Computed and writes an audit entry.

#### Integration with Other Modules
- Receives from: None. Sends to: Notification (publish alerts), StudentPortal/ParentPortal (visibility).

#### Enhancement Notes (Future)
None.

---

### 3.14 Withhold / Declare a Student Result
**Requirement ID:** REQ-MSH-014
**Priority:** Standard (P1)
**Category Tags:** [WORKFLOW] [APPROVAL]

#### Business Description
An Admin/Principal can withhold an individual student's result (e.g. pending an enquiry or fee/discipline hold), recording
a reason, and later declare it. A withheld result is not shown as marks on the marksheet.

#### Actors
- **Initiates:** School Admin / Principal
- **Processes / Approves:** Principal
- **Views / Receives notification:** Class Teacher, Student/Parent (sees "Withheld")

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-041 | Withholding a result requires a reason and marks the result Withheld. | Validation |
| BR-MSH-042 | A withheld result can be declared again, returning it to the normal Declared state. | Workflow |

#### Acceptance Criteria
1. An admin can withhold a student result with a mandatory reason.
2. A withheld result shows as "Withheld" wherever results are displayed.
3. An admin can declare a withheld result.

#### Integration with Other Modules
- Receives from: None. Sends to: StudentPortal/ParentPortal (status shown).

#### Enhancement Notes (Future)
None.

---

### 3.15 Marksheet Preview, Print, PDF & Export
**Requirement ID:** REQ-MSH-015
**Priority:** Core (P0)
**Category Tags:** [REPORT]

#### Business Description
Teachers and admins can preview an individual student's full marksheet — scholastic matrix, co-scholastic grades,
attendance, rank, division, and promotion — and print it or save it as a PDF that carries the school's branding. Result
sets can also be exported to a spreadsheet, and schedules support a downloadable export.

#### Actors
- **Initiates:** Class Teacher / School Admin
- **Processes / Approves:** —
- **Views / Receives notification:** Students/Parents (published view)

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-043 | A marksheet PDF/print carries the school logo, name, board affiliation, student details, and a signature placeholder. | Calculation |
| BR-MSH-044 | A student/parent can only download a marksheet for a published schedule, scoped to that student. | Permission |

#### Acceptance Criteria
1. A user can preview an individual marksheet matching the printed format.
2. A user can print or save the marksheet as a PDF with school branding.
3. Result data can be exported to a spreadsheet.

#### Integration with Other Modules
- Receives from: SchoolSetup (school branding), Template (print layout). Sends to: None.

#### Enhancement Notes (Future)
Bulk ZIP download of all marksheets for a class-section.

---

### 3.16 Computation Audit Log
**Requirement ID:** REQ-MSH-016
**Priority:** Standard (P1)
**Category Tags:** [REPORT] [DASHBOARD]

#### Business Description
Every computation, publish, unlock, and lock action is recorded with who triggered it, when it started and finished, how
many students were processed, the outcome, and any errors. Admins can view this immutable log to trace exactly how and when
a set of results came to be.

#### Actors
- **Initiates:** System
- **Processes / Approves:** —
- **Views / Receives notification:** School Admin

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-045 | Audit-log entries are immutable — they are never edited or deleted. | Workflow |
| BR-MSH-046 | A failed computation closes its log entry with a Failed outcome and the error detail. | Workflow |

#### Acceptance Criteria
1. Each computation/publish/unlock/lock creates a log entry with actor, timing, counts, and outcome.
2. A crashed computation does not leave a permanently "in progress" entry.
3. Log entries cannot be edited or deleted from any screen.

#### Integration with Other Modules
- Receives from: None. Sends to: None.

#### Enhancement Notes (Future)
None.

---

### 3.17 Marksheet Dashboard
**Requirement ID:** REQ-MSH-017
**Priority:** Standard (P1)
**Category Tags:** [DASHBOARD]

#### Business Description
A landing dashboard summarises schedules by status (Draft/Computed/Reviewed/Published/Locked), shows student counts and
last-computed times, and surfaces the next action for each schedule (compute, review, publish). It gives the admin a
single place to drive the term's result cycle.

#### Actors
- **Initiates:** School Admin
- **Processes / Approves:** —
- **Views / Receives notification:** Principal, Academic Coordinator

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-047 | The dashboard shows only schedules for the current school and selected academic session. | Permission |

#### Acceptance Criteria
1. The dashboard lists schedules with status, student count, and last-computed time.
2. Each schedule shows the appropriate next action for its status.
3. Data is scoped to the school and chosen session.

#### Integration with Other Modules
- Receives from: None. Sends to: None.

#### Enhancement Notes (Future)
None.

---

### 3.18 Portal Marksheet View (Student & Parent)
**Requirement ID:** REQ-MSH-018
**Priority:** Standard (P1)
**Category Tags:** [REPORT] [INTEGRATION]

#### Business Description
Once a schedule is published, students see their own marksheets on the Student Portal and parents see their children's
marksheets on the Parent Portal, with download. Access is strictly scoped so no one can view another student's result.

#### Actors
- **Initiates:** Student / Parent
- **Processes / Approves:** —
- **Views / Receives notification:** Student, Parent

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-MSH-048 | A student sees only their own published marksheets; a parent sees only their linked children's. | Permission |
| BR-MSH-049 | Unpublished schedules are not visible on the portals. | Permission |

#### Acceptance Criteria
1. A student/parent sees only published marksheets they are entitled to.
2. Attempting to access another student's marksheet is refused.
3. Before publication, the portal shows a "results not yet available" state.

#### Integration with Other Modules
- Receives from: StudentProfile/Prime (student-parent links). Sends to: StudentPortal, ParentPortal.

#### Enhancement Notes (Future)
None.

---

# Section 4 — Business Rules Register

| Rule ID | Description | Feature | Rule Type | Priority |
|---------|-------------|---------|-----------|----------|
| BR-MSH-001 | Marksheet type code unique within school. | REQ-MSH-001 | Validation | P0 |
| BR-MSH-002 | Referenced marksheet type is archived, not hard-deleted. | REQ-MSH-001 | Workflow | P0 |
| BR-MSH-003 | Examination is a mandatory source in every template. | REQ-MSH-002 | Validation | P0 |
| BR-MSH-004 | Source / IA component codes unique within school. | REQ-MSH-002 | Validation | P0 |
| BR-MSH-005 | Template code unique within a session. | REQ-MSH-003 | Validation | P0 |
| BR-MSH-006 | Template references one exam group and one grading scheme. | REQ-MSH-003 | Validation | P0 |
| BR-MSH-007 | Passing % and compartment threshold configurable per template. | REQ-MSH-003 | Configuration | P0 |
| BR-MSH-008 | Template linked to a published schedule is locked. | REQ-MSH-003 | Workflow | P1 |
| BR-MSH-009 | Source-component weightages sum to 100%. | REQ-MSH-004 | Calculation | P0 |
| BR-MSH-010 | A source component appears at most once per template. | REQ-MSH-004 | Validation | P0 |
| BR-MSH-011 | Exam group belongs to one session; code unique in session. | REQ-MSH-005 | Validation | P0 |
| BR-MSH-012 | Per-exam-type weightages sum to 100%. | REQ-MSH-005 | Calculation | P0 |
| BR-MSH-013 | An exam type appears at most once in an exam group. | REQ-MSH-005 | Validation | P0 |
| BR-MSH-014 | Marksheet class groups maintained in this module (not timetable). | REQ-MSH-006 | Workflow | P0 |
| BR-MSH-015 | A template assignment targets exactly one of class or class-group. | REQ-MSH-006 | Validation | P0 |
| BR-MSH-016 | Direct class assignment overrides group assignment. | REQ-MSH-006 | Calculation | P0 |
| BR-MSH-017 | IA component / co-scholastic area unique within a template. | REQ-MSH-007 | Validation | P1 |
| BR-MSH-018 | Co-scholastic area uses a defined 3/5-point grading scale. | REQ-MSH-007 | Validation | P1 |
| BR-MSH-019 | Behaviour-linked area auto-populates only when integration is enabled. | REQ-MSH-007 | Workflow | P1 |
| BR-MSH-020 | Practical config unique per session, class, subject. | REQ-MSH-008 | Validation | P0 |
| BR-MSH-021 | Theory + practical max marks = subject exam total. | REQ-MSH-008 | Calculation | P0 |
| BR-MSH-022 | Where theory/practical papers share max marks, split must be designated explicitly. | REQ-MSH-008 | Validation | P0 |
| BR-MSH-023 | Schedule code unique within a session. | REQ-MSH-009 | Validation | P0 |
| BR-MSH-024 | Schedule references a template and at least one class-section. | REQ-MSH-009 | Validation | P0 |
| BR-MSH-025 | Multiple independent schedules allowed per year. | REQ-MSH-009 | Workflow | P0 |
| BR-MSH-026 | Computation only from Draft or Computed status. | REQ-MSH-010 | Workflow | P0 |
| BR-MSH-027 | No concurrent computation for the same schedule. | REQ-MSH-010 | Concurrency | P0 |
| BR-MSH-028 | Marksheet includes only enrolled subjects (elective handling). | REQ-MSH-010 | Calculation | P0 |
| BR-MSH-029 | Absent = "AB", Withheld = "WH", never treated as zero. | REQ-MSH-010 | Calculation | P0 |
| BR-MSH-030 | Best-of-N: only best N unit-test scores count when enabled. | REQ-MSH-010 | Calculation | P2 |
| BR-MSH-031 | Entered IA marks cannot exceed component max. | REQ-MSH-011 | Validation | P1 |
| BR-MSH-032 | Co-scholastic grade must be valid on the area's scale. | REQ-MSH-011 | Validation | P1 |
| BR-MSH-033 | Days present cannot exceed total working days. | REQ-MSH-011 | Validation | P1 |
| BR-MSH-034 | Behaviour-linked grades not manually editable when auto-on. | REQ-MSH-011 | Workflow | P1 |
| BR-MSH-035 | Reviewed only reachable from Computed. | REQ-MSH-012 | Workflow | P1 |
| BR-MSH-036 | Reviewer identity and time recorded. | REQ-MSH-012 | Workflow | P1 |
| BR-MSH-037 | Publish only from Reviewed; locks the template. | REQ-MSH-013 | Workflow | P0 |
| BR-MSH-038 | Lock only from Published. | REQ-MSH-013 | Workflow | P0 |
| BR-MSH-039 | Unlock requires reason, returns to Computed, writes audit entry. | REQ-MSH-013 | Workflow | P0 |
| BR-MSH-040 | Students/parents see a marksheet only after publication. | REQ-MSH-013 | Permission | P0 |
| BR-MSH-041 | Withholding a result requires a reason. | REQ-MSH-014 | Validation | P1 |
| BR-MSH-042 | A withheld result can be declared again. | REQ-MSH-014 | Workflow | P1 |
| BR-MSH-043 | Marksheet PDF carries school branding + signature placeholder. | REQ-MSH-015 | Calculation | P0 |
| BR-MSH-044 | Portal download scoped to the student and published schedule. | REQ-MSH-015 | Permission | P0 |
| BR-MSH-045 | Audit-log entries are immutable. | REQ-MSH-016 | Workflow | P1 |
| BR-MSH-046 | Failed computation closes its log entry with error detail. | REQ-MSH-016 | Workflow | P1 |
| BR-MSH-047 | Dashboard scoped to school and selected session. | REQ-MSH-017 | Permission | P1 |
| BR-MSH-048 | Student sees own / parent sees linked children's results only. | REQ-MSH-018 | Permission | P1 |
| BR-MSH-049 | Unpublished schedules invisible on portals. | REQ-MSH-018 | Permission | P1 |
| BR-MSH-050 | A computation run cannot complete unless the linked template's weightages (source and per-exam) already total 100%. | REQ-MSH-010 | Validation | P0 |

---

# Section 5 — Data Requirements

> Business entities; database column/table names appear only in Section 14 (technical Data Dictionary).

### 5.1 Marksheet Type
**What it represents:** A named category of report card the school issues.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Code | Short machine code (e.g. TERM1) | Yes | Unique per school |
| Name | Display name | Yes | |
| Description | Free text | No | |
| Display order | Sort order | Yes | |
| Active | Whether selectable | Yes | Archive instead of delete |
**Relationships:** Used by templates and schedules. **Retention:** Kept while referenced; archived otherwise. **Privacy:** Internal.

### 5.2 Configuration Template
**What it represents:** The blueprint for how a report card is calculated.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Session | Academic session | Yes | |
| Marksheet type | Which report card | Yes | |
| Exam group | The term it covers | Yes | |
| Grading scheme | Grade/division bands | No | Needed when grades are shown |
| Board context | CBSE/ICSE/State/Custom | No | Guides defaults |
| Passing percentage | Subject pass threshold | Yes | Default 33% |
| Compartment threshold | Max failures before Detained | Yes | Default 2 |
| Best-of-N enabled / count | Optional best-N rule | No | Off by default |
| Locked | Frozen after publish | Yes | |
**Relationships:** Has source components, per-exam weightages, IA components, co-scholastic areas; assigned to classes/groups. **Retention:** Retained per session. **Privacy:** Internal.

### 5.3 Source Component & Weightage
**What it represents:** A score source and how much it counts.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Source | Exam/Homework/Quiz/Quest | Yes | Exam mandatory |
| Weightage % | Contribution | Yes | Sum = 100 |
| Max marks | Optional cap | No | |
**Relationships:** Belongs to a template. **Privacy:** Internal.

### 5.4 Exam Group & Items
**What it represents:** A term composed of exam types, with per-exam weightage.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Session | Academic session | Yes | |
| Code / Name | Term identity | Yes | Unique per session |
| Date range | Start/end for averaging | No | Used for HW/Quiz/Quest |
| Exam types + order | Members | Yes | |
| Per-exam weightage % | Within Exam component | Yes | Sum = 100 |
**Relationships:** Referenced by templates/schedules. **Privacy:** Internal.

### 5.5 Class Group & Assignment
**What it represents:** Marksheet class grouping and template assignment.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Group code/name | Primary/Middle/Secondary | Yes | |
| Member classes | Classes in group | Yes | |
| Assignment target | Class or group | Yes | Exactly one |
**Relationships:** Connects templates to classes. **Privacy:** Internal.

### 5.6 IA / Co-Scholastic / Practical Config
**What it represents:** Non-exam scoring configuration per template/subject.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| IA component + max marks | e.g. Notebook = 5 | Yes | |
| Co-scholastic area + scale | e.g. Work Ed, 3-point | Yes | |
| Behaviour-linked | Auto Discipline | No | |
| Theory / Practical max | Per class-subject | Yes (lab subjects) | Sum = subject total |
**Relationships:** Belong to template / class-subject. **Privacy:** Internal.

### 5.7 Marksheet Schedule
**What it represents:** A generation event and its lifecycle.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Template | Config used | Yes | |
| Session / Code / Name | Identity | Yes | Code unique per session |
| Issue date | Planned date | No | |
| Status | Lifecycle stage | Yes | Draft→Computed→Reviewed→Published→Locked |
| Last computed / total students | Run summary | No | |
| Lock / unlock details | Reason, who, when | No | Reason mandatory on unlock |
| Class-sections | Coverage | Yes | At least one |
**Relationships:** Has results, attendance, computation logs. **Retention:** Retained ≥5 sessions (configurable). **Privacy:** Internal.

### 5.8 Student Result (Aggregate)
**What it represents:** A student's overall outcome for a schedule.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Grand total / max / % | Overall marks | Yes (after compute) | |
| Overall grade / division | Bands | Yes | |
| Rank in section / class | Ranking | No | Section rank standard |
| Subjects passed/failed | Counts | Yes | |
| Promotion status | Promoted/Detained/Compartment/Placed | Yes | |
| Result status | Declared / Withheld | Yes | NULL until publish |
| Withheld reason | Free text | No | Required if withheld |
**Relationships:** Belongs to schedule + student; has subject results. **Privacy:** Confidential (student academic record). **PII:** linked to a named student.

### 5.9 Student Subject Result & Exam Marks
**What it represents:** Per-subject result and the raw subject × exam-type matrix cells.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Subject | The subject | Yes | Only enrolled subjects |
| Exam weighted / theory / practical | Exam-derived marks | No | Practical NULL if none |
| Homework/Quiz/Quest/IA | Component scores | No | NULL = not assessed |
| Subject total / max / % / grade | Subject outcome | Yes | |
| Passed | Pass/fail | Yes | |
| Per-exam marks + status | Matrix cell | Yes | AB/WH supported |
**Relationships:** Belong to schedule + student. **Privacy:** Confidential.

### 5.10 Student IA Marks, Co-Scholastic Results, Attendance
**What it represents:** Teacher-entered values per student per schedule.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| IA marks | Per component per subject | No | ≤ max |
| Co-scholastic grade | Per area | No | On scale; auto if linked |
| Working days / present | Attendance summary | No | present ≤ working |
**Relationships:** Belong to schedule + student. **Privacy:** Confidential.

### 5.11 Computation Log
**What it represents:** An immutable record of each run/action.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Action | Compute/Recompute/Publish/Unlock/Lock | Yes | |
| Triggered by / timing | User + start/finish | Yes | |
| Students / errors / status | Run outcome | Yes | |
| Remarks | Unlock reason etc. | No | |
**Relationships:** Belongs to schedule. **Retention:** Permanent. **Privacy:** Internal (immutable audit).

---

# Section 6 — Workflows

### 6.1 Configuration Workflow
**Trigger:** Start of an academic session. **End State:** A template assigned to every class to be graded.
1. Admin creates marksheet types and (if needed) extends IA component types.
2. Admin creates class groups and exam groups (with per-exam weightages).
3. Admin builds a configuration template (grading scheme, pass/compartment rules), adds source-component weightages, IA components, co-scholastic areas.
   - Decision: weightages ≠ 100% → save blocked (BR-MSH-009/012).
4. Coordinator sets theory/practical splits for lab subjects.
5. Admin assigns the template to a class group or specific classes.
**Exception Paths:** If a class has neither direct nor group assignment, computation will skip it and log an error.
**Notifications:** None (configuration phase).

### 6.2 Schedule & Entry Workflow
**Trigger:** Exams concluded for a term. **End State:** Schedule ready to compute with all manual entries captured.
1. Admin creates a marksheet schedule (type, exam group, class-sections, issue date).
2. Subject teachers enter IA marks; class teachers enter co-scholastic grades and attendance.
   - Decision: entry over max / off-scale / present > working days → rejected (BR-MSH-031/032/033).
**Exception Paths:** Behaviour-linked Discipline is auto-filled and not editable when integration is on.
**Notifications:** None.

### 6.3 Computation Workflow
**Trigger:** Admin clicks "Compute". **End State:** Schedule = Computed; all result rows written; audit entry created.
1. System validates preconditions: status is Draft/Computed; template present per class; weightages total 100% (BR-MSH-050).
   - Decision: a computation already running for this schedule → blocked (BR-MSH-027).
2. System opens an audit-log entry and runs the job in the background.
3. Per class-section, per student: reads exam/HW/Quiz/Quest scores, applies weightages and theory/practical split, adds IA, computes subject totals/grades, then overall total/%/grade/division/rank/promotion.
   - Decision: source marks not published / missing → that item treated as not-assessed or AB; error logged per student.
4. System sets schedule status to Computed and closes the audit entry as Success.
**Exception Paths:** If the job crashes, the audit entry is closed as Failed with the error (BR-MSH-046); status stays as it was.
**Notifications:**
| At Step | Who Receives | Message Summary |
|---------|-------------|-----------------|
| 4 | School Admin | "Computation complete for {schedule}: {N} students processed." |
| Exception | School Admin | "Computation failed for {schedule}: {error}." |

### 6.4 Review → Publish → Lock Workflow
**Trigger:** Results computed. **End State:** Schedule Published (then optionally Locked); stakeholders notified.
1. Principal/teacher reviews the result grid and marks the schedule Reviewed (from Computed only — BR-MSH-035).
2. Principal/Admin publishes (from Reviewed only): template is locked, event recorded, stakeholders notified (BR-MSH-037).
3. Admin optionally locks the schedule (from Published only — BR-MSH-038).
**Exception Paths:** Principal rejects at review → schedule stays Computed for correction/recompute.
**Notifications:**
| At Step | Who Receives | Message Summary |
|---------|-------------|-----------------|
| 2 | Class Teachers, Students, Parents | "Results for {schedule} are now published." |

### 6.5 Unlock & Recompute Workflow
**Trigger:** Correction needed after publication. **End State:** Schedule back to Computed, recomputed, re-published.
1. Admin unlocks with a mandatory reason → status returns to Computed; audit entry written (BR-MSH-039).
2. Source marks corrected (in the owning module) → admin recomputes.
3. Schedule re-reviewed and re-published.
**Exception Paths:** Unlock attempted with no reason → rejected.
**Notifications:**
| At Step | Who Receives | Message Summary |
|---------|-------------|-----------------|
| 3 | Students, Parents | "Updated results for {schedule} are now available." |

### 6.6 Withhold / Declare Workflow
**Trigger:** A hold on an individual student's result. **End State:** Result Withheld, later Declared.
1. Admin/Principal withholds a student result with a reason (BR-MSH-041).
2. Marksheet shows "Withheld" for that student.
3. When cleared, admin declares the result (BR-MSH-042).
**Exception Paths:** Withhold with no reason → rejected.
**Notifications:** Optional alert to class teacher.

---

# Section 7 — Reporting & Analytics Requirements

### 7.1 Individual Student Marksheet
**Report ID:** RPT-MSH-001 | **Audience:** Teacher/Admin/Student/Parent | **Frequency:** Per term/As-needed
| Column / KPI | What It Shows |
|--------------|---------------|
| Subject × exam matrix | Marks per subject per exam type |
| Subject total / grade | Per-subject outcome |
| Co-scholastic grades | Per area |
| Attendance | Working days vs present |
| Overall total/%/grade/division/rank | Aggregate outcome |
| Promotion status | Promoted/Detained/Compartment/Placed |
**Filters:** By schedule, student. **Export:** PDF (print), on-screen. **Rules:** Branding + signature (BR-MSH-043); portal scope (BR-MSH-044).

### 7.2 Class Result Review Grid
**Report ID:** RPT-MSH-002 | **Audience:** Principal/Class Teacher | **Frequency:** Per term
| Column / KPI | What It Shows |
|--------------|---------------|
| Students × subjects | Totals and grades per student |
| Anomaly flags | AB / WH / very low highlighted |
| Section rank | Rank within class-section |
**Filters:** By schedule, class-section. **Export:** On-screen, Excel. **Rules:** Visible from Computed onward.

### 7.3 Marksheet Schedule Status Report
**Report ID:** RPT-MSH-003 | **Audience:** School Admin | **Frequency:** Daily during result cycle
| Column / KPI | What It Shows |
|--------------|---------------|
| Schedule / type / term | Identity |
| Status | Lifecycle stage |
| Student count / last computed | Run summary |
| Next action | Compute/Review/Publish |
**Filters:** By session, status. **Export:** On-screen, Excel. **Rules:** Scoped to school + session (BR-MSH-047).

### 7.4 Computation Audit Report
**Report ID:** RPT-MSH-004 | **Audience:** School Admin/Principal | **Frequency:** As-needed
| Column / KPI | What It Shows |
|--------------|---------------|
| Action / actor / timing | Who did what, when |
| Students processed / errors | Run scale and health |
| Outcome | Success/Failed/Partial |
| Remarks | Unlock reason etc. |
**Filters:** By schedule, action. **Export:** On-screen. **Rules:** Immutable (BR-MSH-045).

### 7.5 Bulk Marksheet Pack
**Report ID:** RPT-MSH-005 | **Audience:** Admin/Class Teacher | **Frequency:** Per term
| Column / KPI | What It Shows |
|--------------|---------------|
| All student marksheets for a class-section | Combined PDF/ZIP pack |
**Filters:** By schedule, class-section. **Export:** PDF/ZIP. **Rules:** Published schedules only.

---

# Section 8 — Future Enhancement Log

| Enhancement ID | Requested Feature | Reason / Business Value | Requested By | Priority | Status |
|----------------|------------------|-------------------------|--------------|----------|--------|
| ENH-MSH-001 | Pre-seed board-standard marksheet type sets (CBSE/ICSE) at onboarding | Faster school setup | BA | P2 | Backlog |
| ENH-MSH-002 | Allow custom school-defined source components | Flexibility beyond the fixed four | BA | P2 | Backlog |
| ENH-MSH-003 | "Copy from previous year" template cloning | Saves re-entry each session | BA | P2 | Backlog |
| ENH-MSH-004 | Explicit practical flag at exam-paper level (resolves legacy Q-13) | Removes theory/practical ambiguity | Architect | P1 | Backlog |
| ENH-MSH-005 | Auto-recompute trigger when a source mark is corrected | Keeps results current automatically | BA | P2 | Backlog |
| ENH-MSH-006 | Bulk Excel upload of IA marks / attendance | Faster teacher entry | BA | P2 | Backlog |

---

# Section 9 — Non-Functional Requirements

### 9.1 Performance Expectations
| Requirement | Standard |
|-------------|---------|
| Screen load | All screens load within 3 seconds for up to 500 concurrent users |
| Bulk computation | 500 students × 8 subjects × 6 exams completes within 60 seconds (queued, chunked) |
| Marksheet generation (one) | ≤ 3 seconds |
| Bulk marksheet (50) | ≤ 30 seconds |
| Result review grid | Loads within 10 seconds for a full class-section |

### 9.2 Security Requirements (Business Language)
| Requirement | Rule |
|-------------|------|
| Access control | Only users with the correct role can reach each screen and action |
| Data isolation | One school's results are never visible to another school |
| Student/parent scope | A student sees only their own results; a parent only their linked children's |
| Audit trail | Every computation and after-publication change records who, when, and why |
| Result integrity | Published results are locked; corrections require a logged unlock with reason |

### 9.3 Usability Requirements
| Requirement | Standard |
|-------------|---------|
| Mobile access | Marksheet view and entry screens usable on mobile browsers |
| Language | English labels; Hindi/regional as future enhancement |
| Marksheet readability | Printed marksheet matches the on-screen preview exactly |
| Configurable values | Status and type lists are configurable so schools can extend them |

---

# Section 10 — Gap Analysis Readiness Index

### 10.1 Requirement Coverage Summary

| Requirement ID | Feature Name | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|---------------|-------------|---------|------|------------------|---------------|------------|--------------------|--------------------|
| REQ-MSH-001 | Marksheet Type Master | P0 | DATA_ENTRY, CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-MSH-002 | Source/IA Catalog | P0 | CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-MSH-003 | Config Template Builder | P0 | CONFIGURATION, WORKFLOW | Yes | Yes | No | No | Yes |
| REQ-MSH-004 | Source-Component Weightage | P0 | CONFIGURATION, DATA_ENTRY | Yes | Yes | No | No | Yes |
| REQ-MSH-005 | Exam Grouping & Weightage | P0 | CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-MSH-006 | Class Group & Assignment | P0 | CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-MSH-007 | IA & Co-Scholastic Config | P1 | CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-MSH-008 | Theory/Practical Split | P0 | CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-MSH-009 | Marksheet Schedule Setup | P0 | WORKFLOW, CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-MSH-010 | Result Computation | P0 | WORKFLOW, INTEGRATION, SCHEDULED | Yes | Yes | Yes | Yes | Yes |
| REQ-MSH-011 | IA/Co-Scholastic/Attendance Entry | P1 | DATA_ENTRY | Yes | Yes | No | No | Yes |
| REQ-MSH-012 | Result Review | P1 | WORKFLOW, APPROVAL | No | Yes | No | No | Yes |
| REQ-MSH-013 | Publish / Lock / Unlock | P0 | WORKFLOW, APPROVAL, NOTIFICATION | Yes | Yes | No | Yes | Yes |
| REQ-MSH-014 | Withhold / Declare | P1 | WORKFLOW, APPROVAL | Yes | Yes | No | No | Yes |
| REQ-MSH-015 | Preview / Print / PDF / Export | P0 | REPORT | No | Yes | No | No | Yes |
| REQ-MSH-016 | Computation Audit Log | P1 | REPORT, DASHBOARD | Yes | Yes | No | No | No |
| REQ-MSH-017 | Marksheet Dashboard | P1 | DASHBOARD | No | Yes | No | No | No |
| REQ-MSH-018 | Portal Marksheet View | P1 | REPORT, INTEGRATION | No | Yes | Yes | No | Yes |

### 10.2 Business Rules Coverage Summary

| Rule ID | Rule Summary | Feature Ref | Validation Required | Data Check Required | Workflow Gate |
|---------|-------------|-------------|--------------------|--------------------|---------------|
| BR-MSH-001 | Type code unique | REQ-MSH-001 | Yes | Yes | No |
| BR-MSH-002 | Archive referenced type | REQ-MSH-001 | No | Yes | Yes |
| BR-MSH-003 | Exam mandatory | REQ-MSH-002 | Yes | No | Yes |
| BR-MSH-004 | Component codes unique | REQ-MSH-002 | Yes | Yes | No |
| BR-MSH-005 | Template code unique/session | REQ-MSH-003 | Yes | Yes | No |
| BR-MSH-006 | One exam group + grading scheme | REQ-MSH-003 | Yes | Yes | No |
| BR-MSH-007 | Pass/compartment configurable | REQ-MSH-003 | Yes | No | No |
| BR-MSH-008 | Template locked on publish | REQ-MSH-003 | No | Yes | Yes |
| BR-MSH-009 | Source weightages = 100 | REQ-MSH-004 | Yes | No | Yes |
| BR-MSH-010 | Source once per template | REQ-MSH-004 | Yes | Yes | No |
| BR-MSH-011 | Exam group session/code | REQ-MSH-005 | Yes | Yes | No |
| BR-MSH-012 | Per-exam weightages = 100 | REQ-MSH-005 | Yes | No | Yes |
| BR-MSH-013 | Exam type once per group | REQ-MSH-005 | Yes | Yes | No |
| BR-MSH-014 | Own class groups | REQ-MSH-006 | No | Yes | Yes |
| BR-MSH-015 | Assignment one target | REQ-MSH-006 | Yes | Yes | No |
| BR-MSH-016 | Direct overrides group | REQ-MSH-006 | No | Yes | Yes |
| BR-MSH-017 | IA/area unique/template | REQ-MSH-007 | Yes | Yes | No |
| BR-MSH-018 | Co-scholastic scale valid | REQ-MSH-007 | Yes | No | No |
| BR-MSH-019 | BA auto only if enabled | REQ-MSH-007 | No | Yes | Yes |
| BR-MSH-020 | Practical config unique | REQ-MSH-008 | Yes | Yes | No |
| BR-MSH-021 | Theory+practical = total | REQ-MSH-008 | Yes | Yes | No |
| BR-MSH-022 | Designate ambiguous split | REQ-MSH-008 | Yes | Yes | No |
| BR-MSH-023 | Schedule code unique | REQ-MSH-009 | Yes | Yes | No |
| BR-MSH-024 | Schedule has template + class | REQ-MSH-009 | Yes | Yes | No |
| BR-MSH-025 | Multiple schedules/year | REQ-MSH-009 | No | No | Yes |
| BR-MSH-026 | Compute only Draft/Computed | REQ-MSH-010 | No | Yes | Yes |
| BR-MSH-027 | No concurrent compute | REQ-MSH-010 | No | Yes | Yes |
| BR-MSH-028 | Enrolled subjects only | REQ-MSH-010 | No | Yes | No |
| BR-MSH-029 | AB/WH not zero | REQ-MSH-010 | No | Yes | No |
| BR-MSH-030 | Best-of-N | REQ-MSH-010 | No | Yes | No |
| BR-MSH-031 | IA ≤ max | REQ-MSH-011 | Yes | No | No |
| BR-MSH-032 | Co-scholastic on scale | REQ-MSH-011 | Yes | No | No |
| BR-MSH-033 | present ≤ working | REQ-MSH-011 | Yes | No | No |
| BR-MSH-034 | BA grades not editable | REQ-MSH-011 | No | Yes | Yes |
| BR-MSH-035 | Reviewed from Computed | REQ-MSH-012 | No | Yes | Yes |
| BR-MSH-036 | Reviewer recorded | REQ-MSH-012 | No | Yes | Yes |
| BR-MSH-037 | Publish from Reviewed + lock | REQ-MSH-013 | No | Yes | Yes |
| BR-MSH-038 | Lock from Published | REQ-MSH-013 | No | Yes | Yes |
| BR-MSH-039 | Unlock reason + audit | REQ-MSH-013 | Yes | Yes | Yes |
| BR-MSH-040 | Visible after publish | REQ-MSH-013 | No | Yes | Yes |
| BR-MSH-041 | Withhold needs reason | REQ-MSH-014 | Yes | No | Yes |
| BR-MSH-042 | Declare again | REQ-MSH-014 | No | Yes | Yes |
| BR-MSH-043 | Branding on PDF | REQ-MSH-015 | No | Yes | No |
| BR-MSH-044 | Portal scope | REQ-MSH-015 | No | Yes | Yes |
| BR-MSH-045 | Audit immutable | REQ-MSH-016 | No | Yes | Yes |
| BR-MSH-046 | Failed run closed | REQ-MSH-016 | No | Yes | Yes |
| BR-MSH-047 | Dashboard scoped | REQ-MSH-017 | No | Yes | Yes |
| BR-MSH-048 | Own/children results | REQ-MSH-018 | No | Yes | Yes |
| BR-MSH-049 | Unpublished hidden | REQ-MSH-018 | No | Yes | Yes |
| BR-MSH-050 | Weightage = 100 before compute | REQ-MSH-010 | Yes | Yes | Yes |

### 10.3 Report Coverage Summary

| Report ID | Report Name | Priority | Filters Count | Export Needed |
|-----------|------------|---------|---------------|---------------|
| RPT-MSH-001 | Individual Student Marksheet | P0 | 2 | Yes (PDF) |
| RPT-MSH-002 | Class Result Review Grid | P1 | 2 | Yes (Excel) |
| RPT-MSH-003 | Schedule Status Report | P1 | 2 | Yes (Excel) |
| RPT-MSH-004 | Computation Audit Report | P1 | 2 | No |
| RPT-MSH-005 | Bulk Marksheet Pack | P1 | 2 | Yes (PDF/ZIP) |

### 10.4 Total Scope Numbers

| Category | Count |
|----------|-------|
| Total Functional Requirements (REQ-) | 18 |
| Total Business Rules (BR-) | 50 |
| Total Workflows defined | 6 |
| Total Reports required | 5 |
| Total Enhancements logged | 6 |
| Total P0 (Core) Requirements | 11 |
| Total P1 (Standard) Requirements | 7 |
| Total P2 (Enhanced) Requirements | 0 |

> Priority split derived from Section 10.1: P0 = REQ-MSH-001..006, 008, 009, 010, 013, 015 (11); P1 = REQ-MSH-007, 011, 012, 014, 016, 017, 018 (7); P2 = 0. Total REQ = 18. (P2 requirements: none — Best-of-N is a P2 *rule*, BR-MSH-030, inside the P0 computation requirement.)

---
---

# Section 11 — Requirements Traceability Matrix (RTM)

| REQ-ID | Feature | BR refs | Screen(s) | Workflow | Report(s) | User Story | Code Status (2026-06-29) |
|--------|---------|---------|-----------|----------|-----------|------------|--------------------------|
| REQ-MSH-001 | Marksheet Type Master | 001–002 | Marksheet Types (config tab) | 6.1 | — | US-MSH-001 | Implemented (CRUD + trash/restore) |
| REQ-MSH-002 | Source/IA Catalog | 003–004 | IA Component Types | 6.1 | — | US-MSH-002 | Implemented (seeded + IA CRUD) |
| REQ-MSH-003 | Config Template Builder | 005–008 | Config Template builder | 6.1 | — | US-MSH-003 | Implemented (lockTemplate live) |
| REQ-MSH-004 | Source-Component Weightage | 009–010 | Scholastic Components | 6.1 | — | US-MSH-004 | Implemented (sum=100 validated) |
| REQ-MSH-005 | Exam Grouping & Weightage | 011–013 | Exam Groups, Exam Weightages | 6.1 | — | US-MSH-005 | Implemented |
| REQ-MSH-006 | Class Group & Assignment | 014–016 | Class Groups, Template Assignment | 6.1 | — | US-MSH-006 | Implemented (XOR + override) |
| REQ-MSH-007 | IA & Co-Scholastic Config | 017–019 | IA / Co-Scholastic Components | 6.1 | — | US-MSH-007 | Implemented; BA auto-feed to verify |
| REQ-MSH-008 | Theory/Practical Split | 020–022 | Practical Configs | 6.1 | — | US-MSH-008 | Implemented; Q-13 ambiguity open |
| REQ-MSH-009 | Schedule Setup | 023–025 | Schedule create/edit | 6.2 | RPT-003 | US-MSH-009 | Implemented |
| REQ-MSH-010 | Result Computation | 026–030, 050 | Computation/precheck | 6.3 | — | US-MSH-010 | Implemented (job + readers + helpers) |
| REQ-MSH-011 | IA/Co-Scholastic/Attendance Entry | 031–034 | IA Marks, Co-Scholastic, Attendance | 6.2 | — | US-MSH-011 | Implemented |
| REQ-MSH-012 | Result Review | 035–036 | Review (lifecycle) | 6.4 | RPT-002 | US-MSH-012 | Implemented (review action) |
| REQ-MSH-013 | Publish / Lock / Unlock | 037–040 | Schedule lifecycle actions | 6.4, 6.5 | — | US-MSH-013 | Implemented (lifecycle service) |
| REQ-MSH-014 | Withhold / Declare | 041–042 | Student Result actions | 6.6 | — | US-MSH-014 | Implemented (review service) |
| REQ-MSH-015 | Preview / Print / PDF / Export | 043–044 | Student Result print/pdf/export | — | RPT-001, 005 | US-MSH-015 | Implemented (Template render + html2pdf; bulk ZIP to verify) |
| REQ-MSH-016 | Computation Audit Log | 045–046 | Computation Log index/show | 6.3 | RPT-004 | — | Implemented (read-only views) |
| REQ-MSH-017 | Marksheet Dashboard | 047 | Dashboard | — | RPT-003 | — | Implemented |
| REQ-MSH-018 | Portal Marksheet View | 048–049 | StudentPortal/ParentPortal | 6.4 | RPT-001 | US-MSH-018 | Cross-module (portal side) — verify |

> Code-status column reflects the live tree on 2026-06-29 and supersedes the stale in-repo `AUDIT_REPORT.md` (2026-04-18).

---

# Section 12 — Business Rules Register (standalone), Requirement Conditions Catalog & Validation Catalog

## 12.1 Business Rules Register
See **Section 4** (canonical 50-rule register). Not restated here to avoid divergence.

## 12.2 Requirement Conditions Catalog
> Canonical copy also belongs at `5-Requirement_Conditions/MarksheetGeneration_Conditions.md`; this is the source.

| Condition ID (=BR-) | Entity/Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|---------------------|--------------|----------------------|------|---------|------------------------|
| BR-MSH-009 | Template source weightages | Must total exactly 100% | Calculation | Save template components | Block save; show running total |
| BR-MSH-012 | Per-exam weightages | Must total exactly 100% | Calculation | Save exam weightages | Block save |
| BR-MSH-015 | Template assignment | Exactly one of class / class-group | Validation | Save assignment | Block save |
| BR-MSH-021 | Practical split | Theory + practical = subject total | Calculation | Save practical config | Block save |
| BR-MSH-026 | Schedule status | Compute only from Draft/Computed | Workflow | Trigger compute | Reject with status message |
| BR-MSH-027 | Schedule compute lock | No concurrent compute | Concurrency | Trigger compute | Reject "already running" |
| BR-MSH-029 | Exam mark | Absent/Withheld stored as no-mark | Calculation | Compute | Record AB/WH, not 0 |
| BR-MSH-031 | IA marks | ≤ component max | Validation | Save IA entry | Reject |
| BR-MSH-033 | Attendance | present ≤ working days | Validation | Save attendance | Reject |
| BR-MSH-037 | Publish | Only from Reviewed; lock template | Workflow | Publish | Reject; lock on success |
| BR-MSH-039 | Unlock | Reason mandatory; audit entry | Workflow | Unlock | Reject without reason |
| BR-MSH-041 | Withhold | Reason mandatory | Validation | Withhold | Reject without reason |
| BR-MSH-050 | Compute precondition | Weightages = 100 before run | Validation | Trigger compute | Block run |

## 12.3 Validation & Edge-Case Catalog

| Field/Rule | Valid example | Invalid example | Boundary | Empty/null | Concurrency case | Expected behaviour |
|------------|---------------|-----------------|----------|------------|------------------|--------------------|
| Source weightages | 80+10+10 | 80+10+5 (=95) | Exactly 100 | No components | — | Reject unless exactly 100 |
| Per-exam weightages | 10+10+80 | 10+10+70 | Exactly 100 | — | — | Reject unless 100 |
| Practical split | 70+30=100 | 70+40 | =subject total | has_practical off → no row | — | Reject mismatch |
| IA mark | 4 of 5 | 6 of 5 | =max | not entered → not assessed | two teachers same cell | Reject over-max; last-write recorded |
| Attendance | 110/114 | 120/114 | present=working | NULL summary | — | Reject present>working |
| Exam result | 64 | — | 0; max | ABSENT→AB; WITHHELD→WH | — | AB/WH not zero |
| Compute trigger | Draft→run | Published→run | — | empty schedule | second click while running | Block per BR-026/027/050 |
| Unlock | reason given | blank reason | — | — | — | Reject blank reason |
| Best-of-N | best 2 of 4 | N>available | N=count | disabled → all count | — | Pick top N when enabled |

---

# Section 13 — Process Flows & State Machine (FSM) Catalog

## 13.1 Process Flows
See **Section 6** (six workflows, with triggers, exception paths, and notifications).

## 13.2 FSM — Marksheet Schedule
Backed by the schedule status master (configurable dropdown, key `msh_marksheet_schedules.status_id`).

| From State | Event/Action | Guard (condition) | To State | Side-Effects |
|------------|--------------|-------------------|----------|--------------|
| (none) | Create schedule | template + ≥1 class-section | DRAFT | — |
| DRAFT | Compute | weightages=100; no run active | COMPUTED | result rows written; audit COMPUTE; total_students set |
| COMPUTED | Recompute | not Published/Locked | COMPUTED | results replaced; audit RECOMPUTE |
| COMPUTED | Review | — | REVIEWED | reviewer recorded; audit row |
| REVIEWED | Publish | — | PUBLISHED | template locked; stakeholders notified; audit PUBLISH; results → Declared |
| PUBLISHED | Lock | — | LOCKED | schedule frozen; audit LOCK |
| PUBLISHED | Unlock | reason provided | COMPUTED | unlock fields set; audit UNLOCK(reason) |
| REVIEWED | Unlock | reason provided | COMPUTED | audit UNLOCK |

**Terminal state:** LOCKED (re-openable only via unlock from PUBLISHED — LOCKED is the frozen end state).
**Illegal transitions (must be blocked):** DRAFT→PUBLISHED, COMPUTED→PUBLISHED (must pass REVIEWED), PUBLISHED/LOCKED→Compute, any→edit-template when locked.

## 13.3 FSM — Student Result (within a schedule)
| From State | Event | Guard | To State | Side-Effects |
|------------|-------|-------|----------|--------------|
| (computed, status NULL) | Publish schedule | schedule→PUBLISHED | DECLARED | result visible on portals |
| DECLARED | Withhold | reason provided | WITHHELD | shown as "WH"; reason stored |
| WITHHELD | Declare | — | DECLARED | shown normally |

---

# Section 14 — Data Dictionary & Cross-Module Dependency Map

## 14.1 Data Dictionary (technical view — 23 `msh_*` tables, tenant_db)

| # | Table | Domain | Purpose | Key FKs (read targets in *italics*) |
|---|-------|--------|---------|-------------------------------------|
| 1 | `msh_marksheet_types` | Master | Report-card types | — |
| 2 | `msh_source_components` | Master | Exam/HW/Quiz/Quest sources | — |
| 3 | `msh_ia_component_types` | Master | IA component catalog | — |
| 4 | `msh_class_groups` | Config | Marksheet class grouping | — |
| 5 | `msh_class_group_items_jnt` | Config | Classes ↔ group | `class_group_id`, *`sch_classes`* |
| 6 | `msh_exam_groups` | Config | Terms; date range | *`sch_org_academic_sessions_jnt`* |
| 7 | `msh_exam_group_items_jnt` | Config | Exam types in group | `exam_group_id`, *`lms_exam_types`* |
| 8 | `msh_config_templates` | Config | Calculation blueprint | `marksheet_type_id`, `exam_group_id`, *`slb_grade_division_master`*, *session* |
| 9 | `msh_template_scholastic_components` | Config | Source weightages | `config_template_id`, `source_component_id` |
| 10 | `msh_template_exam_weightages` | Config | Per-exam weightage | `config_template_id`, *`lms_exam_types`* |
| 11 | `msh_template_ia_components` | Config | IA max marks | `config_template_id`, `ia_component_type_id` |
| 12 | `msh_template_coscholastic_components` | Config | Co-scholastic areas | `config_template_id` |
| 13 | `msh_class_config_jnt` | Config | Template→class/group (XOR) | `config_template_id`, *`sch_classes`*, `class_group_id` |
| 14 | `msh_subject_practical_configs` | Config | Theory/practical split | *session*, *`sch_classes`*, *`sch_subjects`* |
| 15 | `msh_marksheet_schedules` | Schedule | Generation event + lifecycle | `config_template_id`, *session*, *`sys_dropdowns`* (status), *`sys_users`* |
| 16 | `msh_schedule_class_jnt` | Schedule | Class-sections in schedule | `schedule_id`, *`sch_class_section_jnt`* |
| 17 | `msh_student_results` | Result | Aggregate per student | `schedule_id`, *`std_students`*, *`sch_class_section_jnt`* |
| 18 | `msh_student_subject_results` | Result | Per-subject result | `schedule_id`, *`std_students`*, *`sch_subjects`* |
| 19 | `msh_student_subject_exam_marks` | Result | Subject×exam matrix (core/high-volume) | `schedule_id`, *`std_students`*, *`sch_subjects`*, *`lms_exam_types`*, *`lms_exam_results`* |
| 20 | `msh_student_ia_marks` | Result | IA marks (teacher) | `schedule_id`, *`std_students`*, *`sch_subjects`*, `ia_component_id` |
| 21 | `msh_student_coscholastic_results` | Result | Co-scholastic grades | `schedule_id`, *`std_students`*, `coscholastic_component_id` |
| 22 | `msh_student_attendance` | Result | Attendance summary | `schedule_id`, *`std_students`* |
| 23 | `msh_computation_logs` | Audit | Immutable run log (no `deleted_at`) | `schedule_id`, *`sys_users`* |

**Technical notes (for DB Architect / Auditor):**
- FK column types in the live migrations match the DDL PK targets (INT UNSIGNED via `unsignedInteger`; session via `unsignedSmallInteger`). The April-2026 `unsignedBigInteger` drift is resolved.
- Status FK target table is **`sys_dropdowns`** in live code (the consolidated DDL text still says `sys_dropdown_table`; DDL is stale on the name).
- No ENUM columns; status/type via `sys_dropdowns` or lookup tables (D-MSG-002 / D29).
- `msh_class_config_jnt` carries a CHECK enforcing exactly one of `class_id` / `class_group_id`.

## 14.2 Cross-Module Dependency Map

**Inbound (this module reads):**
| Source Module | Data/Entity | Why |
|---------------|-------------|-----|
| LmsExam | exam results, papers, exams, exam types | Exam component marks (per subject × exam type) |
| LmsHomework | graded homework submissions | Homework component (averaged in term range) |
| LmsQuiz / LmsQuests | quiz/quest results | Quiz & Quest components |
| BehaviouralAssessment | behavioural score | Co-scholastic Discipline (when linked + enabled) |
| SchoolSetup | classes, sections, class-sections, subjects, session | Structure + class-section coverage |
| Syllabus | grade/division bands | Grade & division computation |
| StudentProfile | students, enrolment | Student set + elective subject resolution |
| SystemConfig | status dropdown, users | Lifecycle status, audit actor |
| Template | print template | Marksheet print/PDF layout |

**Outbound (this module feeds):**
| Target Module | Mechanism | What |
|---------------|-----------|------|
| StudentPortal | shared result tables (read) | Student's own published marksheets |
| ParentPortal | shared result tables (read) | Children's published marksheets |
| Notification | publish event | Publish/update alerts |

> Boundary rule (D-MSG-004): MSH **never writes** to `lms_*`, `ba_*`, `sch_*`, `std_*`, `slb_*` — all source integration is read-only.

---

# Section 15 — NFR Catalog & Risk Register

## 15.1 NFR Catalog
| NFR-ID | Category | Requirement (measurable) | Acceptance Threshold |
|--------|----------|--------------------------|----------------------|
| NFR-MSH-001 | Scalability | Bulk compute 500×8×6 | ≤ 60s, chunked per class-section |
| NFR-MSH-002 | Performance | Single marksheet generation | ≤ 3s |
| NFR-MSH-003 | Performance | Bulk 50 marksheets | ≤ 30s |
| NFR-MSH-004 | Performance | Result review grid load | ≤ 10s per class-section |
| NFR-MSH-005 | Concurrency | One compute per schedule | second attempt blocked |
| NFR-MSH-006 | Security | Role-gated screens/actions | every action authorised |
| NFR-MSH-007 | Security | Per-school data isolation | no cross-tenant access (DB-per-tenant) |
| NFR-MSH-008 | Security | Student/parent scope | own/children only; no IDOR |
| NFR-MSH-009 | Auditability | Immutable computation log | every run/action logged |
| NFR-MSH-010 | Data retention | Soft-delete config/results; logs permanent | ≥5 sessions (configurable) |
| NFR-MSH-011 | Usability | Mobile-capable view/entry | core screens usable on mobile |
| NFR-MSH-012 | Compliance | CBSE/ICSE/State/custom formats | configurable grading & components |

## 15.2 Risk Register
| Risk ID | Risk | Category | Likelihood | Impact | Mitigation | Owner |
|---------|------|----------|-----------|--------|------------|-------|
| RISK-MSH-001 | Theory/practical papers indistinguishable by max marks (Q-13) | Correctness | M | H | Explicit split designation (BR-MSH-022); add paper-level practical flag (ENH-MSH-004) | Architect |
| RISK-MSH-002 | Source marks not published before compute → wrong/empty results | Data | M | H | Precondition check + per-student error logging | Backend |
| RISK-MSH-003 | High-volume core matrix (60K–400K rows/yr) → slow compute/queries | Performance | M | M | Chunked job, indexes on matrix table | Backend/DBA |
| RISK-MSH-004 | BA auto-feed / Attendance auto-feed not fully wired | Integration | M | M | Verify reader-to-result paths; manual fallback for attendance | Backend |
| RISK-MSH-005 | Elective students get class-level subject set (wrong marksheet) | Correctness | M | H | Per-student enrolment resolution (BR-MSH-028) — verify in audit | Backend |
| RISK-MSH-006 | Stale in-repo audit misleads developers | Process | M | L | This FRD's RTM code-status supersedes the 2026-04-18 report | BA |
| RISK-MSH-007 | PDF fidelity (Hindi/images) via browser print path | Usability | L | M | Template-module render + html2pdf; verify across browsers | Frontend |

---

# Section 16 — Prioritization & Effort Estimation

## 16.1 MoSCoW
- **Must (P0):** REQ-MSH-001..006, 008, 009, 010, 013, 015 — configuration spine, computation, publish/lock, marksheet output.
- **Should (P1):** REQ-MSH-007, 011, 012, 014, 016, 017, 018 — IA/co-scholastic, entry, review, withhold, audit, dashboard, portals.
- **Could (P2):** Best-of-N (BR-MSH-030) and the ENH backlog.
- **Won't (this release):** Custom source components, auto-recompute, bulk Excel upload.

## 16.2 Effort Estimation & Sprint Tasks
> Most items already implemented in the live tree; effort below reflects remaining verification/closure work.

| # | Task | Type | Effort (h) | Depends on | Sequence |
|---|------|------|-----------|------------|----------|
| 1 | Re-audit code vs this FRD (supersede 2026-04-18 report) | Testing/Integration | 8 | FRD | Sprint 1 |
| 2 | Verify elective per-student subject resolution (BR-MSH-028) | Backend | 6 | #1 | Sprint 1 |
| 3 | Verify BA auto-feed to co-scholastic Discipline (BR-MSH-019/034) | Integration | 6 | #1 | Sprint 1 |
| 4 | Confirm theory/practical split + Q-13 handling (BR-MSH-021/022) | Backend | 6 | #1 | Sprint 1 |
| 5 | Confirm Best-of-N compute (BR-MSH-030) | Backend | 4 | #1 | Sprint 2 |
| 6 | Bulk marksheet ZIP export (RPT-MSH-005) | Backend/Frontend | 8 | #1 | Sprint 2 |
| 7 | Attendance auto-feed path + fallback (BR-MSH-033) | Integration | 6 | #1 | Sprint 2 |
| 8 | Portal scope/IDOR verification (BR-MSH-048/049) | Backend/Testing | 6 | #1 | Sprint 2 |
| 9 | Pest coverage to all P0 acceptance criteria | Testing | 12 | #1–#8 | Sprint 3 |

---

# Section 17 — User Stories & Reporting/KPI Spec

## 17.1 User Stories (Gherkin) — one per P0/P1 REQ

**US-MSH-003** | P0 | REQ-MSH-003
As a School Admin, I want to build a configuration template so that report cards are calculated consistently.
- Scenario (happy): Given a session and marksheet type, When I create a template with an exam group and grading scheme, Then it is saved and available for assignment.
- Scenario (locked): Given a template linked to a published schedule, When I try to edit it, Then editing is refused with an explanation.
- Scenario (permission): Given a Class Teacher, When they open template builder, Then access is refused.
- DoD: template persists; lock enforced on publish; audit unaffected; session-scoped.

**US-MSH-004** | P0 | REQ-MSH-004
As an Admin, I want source weightages validated so that every subject is scored on 100%.
- Scenario (happy): Given Exam 80 + HW 10 + Quiz 10, When I save, Then it succeeds.
- Scenario (boundary): Given a total of 95%, When I save, Then it is rejected with the running total shown.
- Scenario (empty): Given no components, When I compute, Then compute is blocked (BR-MSH-050).
- DoD: sum=100 enforced at save and pre-compute.

**US-MSH-010** | P0 | REQ-MSH-010
As an Admin, I want to compute all results so that report cards are produced automatically.
- Scenario (happy): Given a Draft schedule with valid config, When I compute, Then results are written and status becomes Computed.
- Scenario (absent): Given a student absent in an exam, When computed, Then that cell shows "AB" and is not counted as zero.
- Scenario (concurrency): Given a compute already running, When I trigger again, Then it is blocked.
- Scenario (failure): Given the job crashes, When it fails, Then the audit entry closes as Failed with the error.
- DoD: totals/grades/rank/promotion produced; AB/WH respected; enrolled subjects only; audit written.

**US-MSH-013** | P0 | REQ-MSH-013
As a Principal, I want to publish/lock/unlock results so that they are released safely and corrections are traceable.
- Scenario (happy): Given a Reviewed schedule, When I publish, Then the template locks, stakeholders are notified, and results are visible.
- Scenario (guard): Given a Computed (not Reviewed) schedule, When I publish, Then it is refused.
- Scenario (unlock): Given a Published schedule, When I unlock without a reason, Then it is refused; with a reason it returns to Computed and writes an audit entry.
- DoD: status guards enforced; template lock on publish; unlock reason + audit.

**US-MSH-015** | P0 | REQ-MSH-015
As a Teacher, I want to preview and print a marksheet so that I can issue it with school branding.
- Scenario (happy): Given a computed student result, When I open preview, Then the on-screen marksheet matches the print/PDF.
- Scenario (scope): Given a parent, When they download, Then only their child's published marksheet is served.
- DoD: branding + signature placeholder present; portal scope enforced.

**US-MSH-001/002/005/006/008/009** (P0 config) — As an Admin/Coordinator, I want to maintain types, catalogs, exam/class groups, practical splits, and schedules so that the calculation is correctly set up. (happy / duplicate-rejected / permission-denied scenarios; DoD = unique codes, session scope, archive-not-delete.)

**US-MSH-007/011/012/014/018** (P1) — As Coordinator/Teacher/Principal/Parent, I want to configure IA & co-scholastic, enter marks/attendance, review, withhold/declare, and view portal marksheets so that the full report-card lifecycle works. (happy / boundary / permission / empty-state scenarios; DoD includes validation bounds, status guards, and portal scoping.)

## 17.2 KPI / Metrics
| KPI | Definition (business) | Source data | Target | Cadence |
|-----|-----------------------|-------------|--------|---------|
| Result publication timeliness | Days from exam-end to publish | schedule dates | ≤ 10 days | Per term |
| Computation success rate | Successful runs ÷ total runs | computation log | ≥ 99% | Per term |
| Withheld results | Count/% withheld at publish | student results | trend down | Per term |
| Pass / promotion rate | % Promoted vs Compartment/Detained | student results | school KPI | Per term |
| Recompute frequency | Unlock+recompute events per schedule | computation log | ≤ 1 | Per term |

---

# Section 18 — Feature Specification (screen-by-screen)

> The module presents four tabbed working areas (Configuration, Components, Scheduling, Results) plus a Dashboard and per-entity show/print screens (98 blade views). Mapped to legacy screen IDs SC-MSG-01..15.

| Screen | Area | Actor | Key actions | REQ ref |
|--------|------|-------|-------------|---------|
| Dashboard | Dashboard | Admin | Status summary, next action per schedule | REQ-MSH-017 |
| Marksheet Types | Configuration | Admin | CRUD, archive/restore | REQ-MSH-001 |
| IA Component Types | Configuration | Coordinator | CRUD | REQ-MSH-002 |
| Class Groups | Configuration | Admin | CRUD, add/remove classes | REQ-MSH-006 |
| Exam Groups | Configuration | Admin | CRUD, add exam types | REQ-MSH-005 |
| Config Templates | Configuration | Admin | Builder, assign to classes | REQ-MSH-003/006 |
| Scholastic Components | Components | Admin | Source weightages (sum 100) | REQ-MSH-004 |
| Exam Weightages | Components | Admin | Per-exam weightage (sum 100) | REQ-MSH-005 |
| IA Components | Components | Coordinator | IA max marks | REQ-MSH-007 |
| Co-Scholastic Components | Components | Coordinator | Areas + scale + BA link | REQ-MSH-007 |
| Practical Configs | Scheduling | Coordinator | Theory/practical split | REQ-MSH-008 |
| Schedules | Scheduling | Admin | Create/edit, precheck, compute, review, publish, lock, unlock, export | REQ-MSH-009/010/012/013 |
| Schedule Classes | Scheduling | Admin | Add class-sections | REQ-MSH-009 |
| Student Results | Results | Teacher/Admin | List, show, print, PDF, export, withhold, declare | REQ-MSH-014/015 |
| Subject Results | Results | Teacher | Per-subject view | REQ-MSH-010 |
| Subject Exam Marks | Results | Admin | Matrix view (read) | REQ-MSH-010 |
| IA Marks | Results | Subject Teacher | Entry grid | REQ-MSH-011 |
| Co-Scholastic Results | Results | Class Teacher | Entry grid | REQ-MSH-011 |
| Attendance | Results | Class Teacher | Working days/present entry | REQ-MSH-011 |
| Computation Log | Results | Admin | Audit index/show (read-only) | REQ-MSH-016 |

**Layout:** AdminLTE tabbed pages with modal-based create/edit for masters; full-page builders for templates and schedules. **Empty states:** "No schedules yet — create one to begin." **Permissions:** per role matrix (Section 2.2).

---

## Document Control

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-06-29 | Initial Complete Analysis Pack synthesised from live code, DDL, migrations, and design pack. | Business Analysis — Prime-AI |

*This document is the single source of truth for MarksheetGeneration (MSH) requirements. All gap analyses, completion scoring, and test coverage reference its REQ-/BR-/RPT-/ENH- IDs; never renumber them.*
