# Functional Requirements Document — Complete Analysis Pack
# Module: LmsQuests (Quests)
# Prime-AI School ERP Platform

| Field | Value |
|-------|-------|
| **Module Name** | LmsQuests |
| **Module Code** | QST |
| **Table Prefix** | `lms_` (shared LMS prefix — only `lms_quest*` tables are QST-owned) |
| **Document Version** | 1.0 |
| **Date** | 2026-06-29 |
| **Status** | Draft |
| **Prepared By** | Business Analysis — Prime-AI (pa-business-analyst) |
| **Reviewed By** | (Pending) |
| **Approved By** | (Pending) |
| **Sources read** | Live module code (`Modules/LmsQuests`), tenant migrations, DDL `LmsQuest_DDL_v2.sql`, V2 requirement `QST_LmsQuests_Requirement.md`, V1 screen-spec folder `LmsQuests_V2/`, AI_Brain rules/memory/conventions |

> This is the **Complete Analysis Pack** — a single consolidated document. Sections 1–10 are the FRD; Sections 11–19 carry the rest of the BA analysis catalogue (RTM, conditions, validation, FSM, data dictionary, dependency map, NFR/risk, prioritisation, estimation, user stories, KPIs). All later sections reuse the `REQ-/BR-/RPT-` IDs assigned in Sections 3–7 — never renumber them; the downstream audit reuses these IDs.

## Table of Contents
1. Module Overview
2. User Roles & Access
3. Functional Requirements (REQ-QST-001 … 021)
4. Business Rules Register (BR-QST-001 … 032)
5. Data Requirements (business + technical dictionary)
6. Workflows
7. Reporting & Analytics (RPT-QST-001 … 006)
8. Future Enhancement Log (ENH-QST-001 … 006)
9. Non-Functional Requirements
10. Gap Analysis Readiness Index
11. Requirements Traceability Matrix (RTM)
12. Requirement Conditions Catalogue
13. Validation & Edge-Case Catalogue
14. State Machine (FSM) Catalogue
15. Cross-Module Dependency Map
16. NFR Catalogue & Risk Register
17. Prioritisation (MoSCoW) & Effort Estimation
18. User Stories (P0/P1)
19. KPI / Metrics Catalogue

---

## Section 1 — Module Overview

### 1.1 Business Purpose
The Quests module lets teachers build longer, cross-lesson assessments — a "Quest" — that measure how well students integrate understanding across several lessons and topics at once, rather than a single short topic (which is what a Quiz covers). Schools use Quests for challenge, enrichment, diagnostic, revision, re-test and remedial purposes. A teacher chooses the academic context (year, class, subject), defines which lessons and topics the Quest covers, pulls questions from the school's Question Bank, configures grading and timing rules, and then assigns the Quest to a whole class, a section, a group, or individual students with publication and deadline dates. After students attempt the Quest, teachers monitor submissions, grade descriptive answers, publish results, and review performance analytics. Without this module a school has no structured way to run multi-lesson formative challenges or to track integrated mastery over a curriculum window.

### 1.2 Business Value
- Lets teachers assess deep, cross-topic understanding that single-topic quizzes cannot capture.
- Reuses the central Question Bank, so questions are authored once and reused across assessments with usage tracking to avoid over-exposure.
- Targeted assignment (class / section / group / individual) supports differentiated and remedial teaching.
- Built-in grading, result publication and analytics reduce manual marksheet effort and surface weak areas per class/subject.
- Publishing graded results automatically feeds the Recommendation engine, turning assessment outcomes into personalised learning suggestions.

### 1.3 Scope

#### In Scope
1. Creating and configuring Quests (context, grading rules, timer, attempt policy, display options, question-selection filters).
2. Defining a Quest's curriculum coverage as multiple lesson + topic scopes, each with an optional question-type filter and target count.
3. Adding/removing/reordering questions from the Question Bank into a Quest, with per-question marks override and difficulty/scope enforcement.
4. Assigning ("allocating") a Quest to a class, section, group or individual student with publish, due, cut-off and result-release dates.
5. Quest lifecycle: Draft → Published → Archived, with a readiness check before publishing.
6. Duplicating a Quest (with its scopes and questions) as a new draft.
7. Soft delete, trash listing, restore and permanent delete for Quests and each child entity, gated by usage checks.
8. Activate / deactivate (status toggle) of Quests, scopes, questions and allocations.
9. Teacher monitoring: management dashboard, allocation summary grid, per-Quest performance report, per-student attempt review.
10. Manual paper-check / grading of student answers (including annotated-file upload) and result publication.
11. Audit logging of all create/update/delete/restore/toggle actions.
12. Role-based access control across all Quest functions.

#### Out of Scope
1. **Student quest-taking experience** (taking the timed attempt, saving answers, auto-grading MCQs, submitting) — delivered by the **StudentPortal** module using the shared attempt tables. Quests depends on it but does not own it.
2. **Question authoring** — owned by **QuestionBank (QNS)**; Quests only consumes published questions.
3. **Assessment-type and difficulty-distribution master setup** — owned by **LmsQuiz (QUZ)**; Quests references these as read-only masters.
4. **Class / section / subject / lesson / topic / student master data** — owned by **SchoolSetup, Syllabus, StudentProfile**.
5. **Recommendation generation** — owned by **Recommendation (REC)**; Quests only emits a result-published event.
6. **Marksheet aggregation / report cards** — owned by MarksheetGeneration / HPC.

### 1.4 Key Terminology
| Business Term | Meaning |
|---------------|---------|
| Quest | A multi-lesson, broader-scope formative assessment, distinct from a single-topic Quiz. |
| Quest Type | The pedagogical category of a Quest (e.g. Challenge, Enrichment, Practice, Revision, Diagnostic, Remedial, Re-Test), drawn from a configurable master list. |
| Quest Scope | One coverage entry stating which lesson + topic a Quest includes, with an optional question-type filter and a target number of questions. A Quest has many scopes. |
| Quest Code | An auto-generated, globally unique identifier for a Quest (pattern: QUEST_{year}_{class}_{subject}_{random}). |
| Allocation | The assignment of a Quest to an audience (whole class, a section, a defined group, or a single student) with timing dates. |
| Publish Date | The date/time from which an allocated Quest becomes visible to students. |
| Due Date | The recommended completion deadline shown to students. |
| Cut-off Date | The hard deadline after which no new attempt may begin. |
| Result Publish Date | The date/time from which scored results become visible to students. |
| Auto-Publish Result | A setting that releases results automatically at the result-publish date without a manual teacher action. |
| Marks Override | A per-question mark value that replaces the question's default mark within this Quest. |
| Difficulty Distribution | A configured mix of question difficulty/type percentages that the Quest's question set must respect. |
| Passing Percentage | The minimum score percentage a student needs to pass the Quest (default 33%). |
| Negative Marking | A configured deduction applied for wrong answers (0 = disabled). |
| Paper Check | The teacher activity of reviewing and grading student answers (especially descriptive ones) for a Quest. |
| Usage Guard | A safety rule that blocks editing or deleting a Quest (or its parts) once it is in use by allocations, questions, or student attempts. |

---

## Section 2 — User Roles & Access

### 2.1 Actor Definitions
| Role | Who They Are | Relationship to This Module |
|------|-------------|-----------------------------|
| Teacher | Subject teacher in the school | Primary author: creates Quests, scopes, questions, allocations; monitors, grades, publishes results. |
| School Admin / Principal | School-level administrator | All teacher abilities plus permanent delete and restore-from-trash; manages assessment-type/difficulty masters (via LmsQuiz). |
| Student | Enrolled learner | Receives allocated Quests and attempts them (experience delivered by StudentPortal). |
| Parent | Guardian of a student | Views child's Quest outcomes (via portal — not in this module). |
| System | Automated platform processes | Auto-publishes results at the result-publish date; can act as the assigner (no named user). |

### 2.2 Role-Feature Access Matrix
| Feature | Teacher | School Admin | Student | System |
|---------|---------|--------------|---------|--------|
| View Quest hub / dashboard | Full | Full | No Access | n/a |
| Create / edit Quest | Full | Full | No Access | Create (system-generated) |
| Define scopes | Full | Full | No Access | n/a |
| Add / reorder / remove questions | Full | Full | No Access | Auto-select (proposed) |
| Allocate Quest | Full | Full | No Access | Auto-assign |
| Publish / archive / duplicate | Full | Full | No Access | n/a |
| Soft delete / trash | Full | Full | No Access | n/a |
| Restore / permanent delete | No Access | Full | No Access | n/a |
| Paper check / grade answers | Full | Full | No Access | n/a |
| Publish results | Full | Full | No Access | Auto at date |
| View performance reports | Full | Full | Own only (portal) | n/a |
| Take a Quest attempt | No Access | No Access | Full (portal) | Auto-timeout |

---

## Section 3 — Functional Requirements

### 3.1 Quest Creation & Configuration
**Requirement ID:** REQ-QST-001 | **Priority:** Core (P0) | **Tags:** [DATA_ENTRY][CONFIGURATION]

#### Business Description
A teacher creates a Quest by giving it a title and the academic context it belongs to (academic year, class, subject) and choosing its Quest type. They configure grading and behaviour: total marks, total questions, passing percentage, negative marking, whether multiple attempts are allowed and how many, whether a timer is enforced and its duration, whether questions/options are randomised, and what students see during and after the attempt (marks, correct answers, explanations). They may attach a difficulty-distribution profile (or choose to ignore it) and set question-selection filters (only previously unused questions; only questions authorised for assessments). Every new Quest starts in Draft status and is given a unique Quest code automatically.

#### Actors
- **Initiates:** Teacher
- **Processes / Approves:** System (assigns code, defaults, creator)
- **Views / Receives:** Teacher, School Admin

#### Business Rules
| Rule ID | Business Rule | Type |
|---------|---------------|------|
| BR-QST-001 | Every Quest must have a globally unique Quest code. | Validation |
| BR-QST-002 | A Quest must have a title, an academic year, a class, a subject and a Quest type before it can be saved. | Validation |
| BR-QST-003 | Passing percentage must be between 0 and 100; total marks and total questions cannot be negative. | Validation |
| BR-QST-004 | If multiple attempts are not allowed, the maximum-attempts value must be 1. | Validation |
| BR-QST-005 | When a timer is enforced, a duration of at least 1 minute must be set. | Validation |
| BR-QST-006 | A new Quest is created in Draft status with the current user recorded as its creator. | Workflow |

#### Acceptance Criteria
1. A teacher can save a new Quest with title + academic context + type and it appears in the Quest list in Draft status.
2. Saving without a required field shows a validation message and does not create the Quest.
3. The saved Quest shows a unique Quest code that no other Quest shares.
4. Setting "multiple attempts off" forces maximum attempts to 1.

#### Integration
- Receives from: SchoolSetup (class/subject), Global (academic year), LmsQuiz (Quest type, difficulty profile).
- Sends to: None at creation.

#### Enhancement Notes
ENH-QST-002 (remove duplicate code-generation path); ENH-QST-005 (retire phantom fields).

---

### 3.2 Quest Scope Definition
**Requirement ID:** REQ-QST-002 | **Priority:** Core (P0) | **Tags:** [DATA_ENTRY][CONFIGURATION]

#### Business Description
A teacher defines what curriculum a Quest covers by adding one or more scope rows. Each row names a lesson and (optionally) a topic, optionally restricts to a question type, and states a target number of questions for that scope (zero meaning "no limit"). Because a Quest spans multiple lessons, multiple scope rows can be added at once in a single multi-row form, and they can be edited or removed later.

#### Actors
- **Initiates:** Teacher
- **Processes / Approves:** Teacher
- **Views / Receives:** Teacher, School Admin

#### Business Rules
| Rule ID | Business Rule | Type |
|---------|---------------|------|
| BR-QST-007 | A scope row must name a lesson; the topic is optional. | Validation |
| BR-QST-008 | The same lesson+topic combination cannot be added twice to one Quest. | Validation |
| BR-QST-009 | A target question count of zero means all matching questions are eligible (no limit). | Calculation |
| BR-QST-010 | A Quest may have at most 20 scope rows. | Validation |
| BR-QST-011 | Scopes cannot be edited or removed once the Quest is in use (allocated or attempted). | Workflow |

#### Acceptance Criteria
1. A teacher can add several lesson/topic scope rows for one Quest in a single submission.
2. Adding a duplicate lesson+topic pair is rejected with a clear message.
3. Attempting to add a 21st scope is rejected.
4. Editing scopes for an in-use Quest is blocked.

#### Integration
- Receives from: Syllabus (lessons, topics, question types).

#### Enhancement Notes
Topic cascade dropdowns provided via AJAX (see REQ-QST-019).

---

### 3.3 Quest Question Assignment
**Requirement ID:** REQ-QST-003 | **Priority:** Core (P0) | **Tags:** [DATA_ENTRY][INTEGRATION]

#### Business Description
A teacher selects questions from the Question Bank to populate a Quest. They search/filter the bank (by class, section, subject, lesson, topic, question type, complexity, Bloom level, cognitive skill, tags, usage), then add questions in bulk. Each question can carry an explicit marks override; otherwise the bank's default mark applies. Questions are ordered by an ordinal that can be changed by drag-and-drop, and individual marks can be edited inline. Questions can be removed in bulk. As questions are added, the system enforces the Quest's total-question limit, total-marks limit, difficulty-distribution rules and scope targets.

#### Actors
- **Initiates:** Teacher
- **Processes / Approves:** System (limit/scope/difficulty checks)
- **Views / Receives:** Teacher

#### Business Rules
| Rule ID | Business Rule | Type |
|---------|---------------|------|
| BR-QST-012 | The same question cannot be added twice to one Quest. | Validation |
| BR-QST-013 | The number of assigned questions cannot exceed the Quest's configured total questions. | Validation |
| BR-QST-014 | The sum of question marks cannot exceed the Quest's configured total marks. | Calculation |
| BR-QST-015 | When a difficulty profile is attached and not ignored, added questions must satisfy its type/complexity min–max percentages. | Validation |
| BR-QST-016 | Questions added must not exceed any scope's target question count for their type/lesson/topic. | Validation |
| BR-QST-017 | If "only unused questions" is set, questions already recorded in the question usage log are excluded. | Validation |
| BR-QST-018 | If "only authorised questions" is set, only questions flagged usable for assessments may be added. | Validation |
| BR-QST-019 | When no marks override is given, the question's default Question-Bank mark is used. | Calculation |
| BR-QST-020 | Adding a question records a usage-log entry against the Quest; removing it clears that entry. | Workflow |

#### Acceptance Criteria
1. A teacher can search the bank and bulk-add multiple questions to a Quest.
2. Adding beyond the total-question or total-marks limit is rejected with the exact counts.
3. Reordering questions persists the new sequence.
4. A duplicate question is rejected.
5. Removing questions in bulk also clears their Quest usage records.

#### Integration
- Receives from: QuestionBank (questions, options, usage log), Syllabus, SchoolSetup, LmsQuiz (difficulty details).

---

### 3.4 Quest Allocation
**Requirement ID:** REQ-QST-004 | **Priority:** Core (P0) | **Tags:** [WORKFLOW][CONFIGURATION]

#### Business Description
A teacher assigns a Quest to an audience by choosing an allocation type — a whole class, a section, a defined group, or an individual student — and the specific target. They set timing: when the Quest becomes visible (publish date), the recommended due date, the hard cut-off date after which no new attempt may start, and either an auto-publish-results setting with a result-release date or manual result release. Only active Quests can be allocated, and the target list is filtered to active records.

#### Actors
- **Initiates:** Teacher
- **Processes / Approves:** System (target resolution, date defaults)
- **Views / Receives:** Teacher, Student (once published)

#### Business Rules
| Rule ID | Business Rule | Type |
|---------|---------------|------|
| BR-QST-021 | A Quest must be active to be allocated. | Validation |
| BR-QST-022 | The allocation type must be one of Class, Section, Group, or Student, and the target must exist and be active. | Validation |
| BR-QST-023 | If both due date and cut-off date are set, the cut-off must be on or after the due date. | Validation |
| BR-QST-024 | A result-publish date may only be set when auto-publish results is enabled; otherwise it is cleared. | Validation |
| BR-QST-025 | If no cut-off date is given but a due date is, the cut-off defaults to the due date. | Workflow |
| BR-QST-026 | Allocation records the assigning user (or marks it system-assigned). | Workflow |

#### Acceptance Criteria
1. A teacher can allocate a Quest to a class, a section, a group, or a student.
2. Selecting a section resolves to the correct class-section combination.
3. A cut-off earlier than the due date is rejected.
4. A result-publish date set while auto-publish is off is rejected/cleared.

#### Integration
- Receives from: SchoolSetup (classes, sections, groups, class-section junction), StudentProfile (students).
- Sends to: StudentPortal (allocations drive the student quest list).

---

### 3.5 Quest Publish & Lifecycle
**Requirement ID:** REQ-QST-005 | **Priority:** Standard (P1) | **Tags:** [WORKFLOW][APPROVAL]

#### Business Description
A Quest moves through Draft → Published → Archived. Publishing should only succeed when the Quest is ready: it has questions, the assigned-question count matches the configured total, the academic context is complete, and settings are valid. Archiving deactivates the Quest. The platform provides a readiness check for this; today status can also change through the edit form, which can bypass the readiness check (a known gap).

#### Actors
- **Initiates:** Teacher
- **Processes / Approves:** System (readiness validation)
- **Views / Receives:** Teacher, School Admin

#### Business Rules
| Rule ID | Business Rule | Type |
|---------|---------------|------|
| BR-QST-027 | A Quest may become Published only when it has questions, the assigned-question count equals the configured total questions, the academic context is complete, and settings are valid. | Workflow |
| BR-QST-028 | Archiving a Quest deactivates it. | Workflow |

#### Acceptance Criteria
1. Publishing a Quest that fails the readiness check is rejected with a specific reason.
2. A published Quest is visible for allocation.
3. Archiving sets the Quest inactive and removes it from active lists.

#### Integration
- None (internal state).

#### Enhancement Notes
ENH-QST-001 — dedicated publish/archive action that always enforces the readiness check.

---

### 3.6 Quest Duplication
**Requirement ID:** REQ-QST-006 | **Priority:** Enhanced (P2) | **Tags:** [DATA_ENTRY]

#### Business Description
A teacher can duplicate an existing Quest to save setup effort. The copy gets a new unique Quest code, a "(Copy)" title, Draft status, the current user as creator, and clones the original's scopes and questions.

#### Actors
- **Initiates:** Teacher
- **Processes / Approves:** System
- **Views / Receives:** Teacher

#### Business Rules
| Rule ID | Business Rule | Type |
|---------|---------------|------|
| BR-QST-029 | A duplicated Quest is created in Draft with a new unique code and cloned scopes and questions. | Workflow |

#### Acceptance Criteria
1. Duplicating produces an independent Draft Quest with cloned scopes and questions.
2. The new Quest has a different, unique code.

#### Integration
- None.

#### Enhancement Notes
ENH-QST-003 — expose duplication through a dedicated action (model capability exists; UI wiring pending).

---

### 3.7 Soft Delete, Trash & Restore
**Requirement ID:** REQ-QST-007 | **Priority:** Standard (P1) | **Tags:** [WORKFLOW]

#### Business Description
Quests and each child entity (scopes, questions, allocations) can be soft-deleted to a trash list, restored, or permanently deleted. Every such action is blocked when the record is in use (allocated, has assigned questions, or has student attempts). Soft-deleting a Quest also archives and deactivates it. Permanent deletion of a Quest also removes its scopes and questions.

#### Actors
- **Initiates:** Teacher (delete/trash), School Admin (restore, permanent delete)
- **Processes / Approves:** System (usage guard)
- **Views / Receives:** Teacher, School Admin

#### Business Rules
| Rule ID | Business Rule | Type |
|---------|---------------|------|
| BR-QST-030 | A Quest or child record in use (allocations, questions, or student attempts) cannot be edited, deleted, restored, or permanently deleted. | Workflow |
| BR-QST-031 | Soft-deleting a Quest also sets it Archived and inactive; permanently deleting a Quest also removes its scopes and questions. | Workflow |

#### Acceptance Criteria
1. Deleting a Quest moves it to trash and marks it archived/inactive.
2. A trashed Quest can be restored to Draft by an admin.
3. Delete/restore/permanent-delete is blocked for in-use records with a clear message.
4. Permanent delete of a Quest cascades to its scopes and questions.

#### Integration
- None.

---

### 3.8 Status Toggle (Activate / Deactivate)
**Requirement ID:** REQ-QST-008 | **Priority:** Standard (P1) | **Tags:** [WORKFLOW]

#### Business Description
A teacher can flip a Quest, scope, question, or allocation between active and inactive without deleting it. For scopes, toggling one applies to all scope rows of the same Quest.

#### Actors
- **Initiates:** Teacher
- **Processes / Approves:** System
- **Views / Receives:** Teacher

#### Business Rules
| Rule ID | Business Rule | Type |
|---------|---------------|------|
| BR-QST-032 | Toggling a scope's active state applies to all scope rows belonging to the same Quest. | Workflow |

#### Acceptance Criteria
1. Toggling active status updates the record and is reflected in lists.
2. Toggling any scope updates all scopes of that Quest together.

#### Integration
- None.

---

### 3.9 Quest Management Dashboard
**Requirement ID:** REQ-QST-009 | **Priority:** Standard (P1) | **Tags:** [DASHBOARD][REPORT]

#### Business Description
A dashboard tab gives teachers an at-a-glance view of Quest activity: counts of Quests, questions, allocations, submissions and checked papers; average score; status breakdown (Draft/Published/Archived); monthly Quest and allocation trends; subject-wise and class-wise breakdowns; a score-distribution chart; and a list of recent Quests with their submission/evaluation counts. The view can be filtered by class-section, subject, and date range.

#### Actors
- **Initiates:** Teacher
- **Views / Receives:** Teacher, School Admin

#### Business Rules
(Reporting rules captured under RPT-QST-001.)

#### Acceptance Criteria
1. Dashboard metric cards reflect the applied class/subject/date filters.
2. Charts render trends and distributions consistent with the underlying records.
3. Recent-Quests list shows submission and evaluation counts per Quest.

#### Integration
- Receives from: StudentPortal (attempts/results), SchoolSetup, QuestionBank.

---

### 3.10 Quest Summary / Allocation Monitoring
**Requirement ID:** REQ-QST-010 | **Priority:** Standard (P1) | **Tags:** [DASHBOARD][REPORT]

#### Business Description
A summary tab lists Quest allocations with, for each, the Quest, subject, assigner, target audience and the number of students assigned, submitted, in-progress and checked. It supports search and filtering by class-section, subject and date range, and links through to the per-Quest performance report and paper-check.

#### Actors
- **Initiates:** Teacher
- **Views / Receives:** Teacher, School Admin

#### Acceptance Criteria
1. Each allocation row shows assigned/submitted/in-progress/checked counts.
2. Filtering by class-section/subject/date updates the grid.
3. The "assigned" count correctly reflects class, section, group or single-student targets.

#### Integration
- Receives from: StudentPortal (attempt status), SchoolSetup, StudentProfile.

---

### 3.11 Paper Check & Manual Grading
**Requirement ID:** REQ-QST-011 | **Priority:** Core (P0) | **Tags:** [WORKFLOW][DATA_ENTRY]

#### Business Description
For a chosen Quest, a teacher opens the paper-check view to see all student attempts and grade them. They can view a student's answers (including any uploaded answer files), award per-question marks (capped at each question's maximum), add evaluation remarks, optionally upload an annotated answer PDF, compute the percentage and grade, mark pass/fail against the passing percentage, and save the result. Grading can be done question-by-question or as a batch save of the whole paper.

#### Actors
- **Initiates:** Teacher
- **Processes / Approves:** Teacher (grader)
- **Views / Receives:** Student (after publication)

#### Business Rules
| Rule ID | Business Rule | Type |
|---------|---------------|------|
| BR-QST-014 | (reuse) Awarded marks for a question cannot exceed that question's maximum marks. | Validation |
| BR-QST-027 | (reuse) Pass/fail is determined by comparing the achieved percentage to the Quest's passing percentage. | Calculation |

#### Acceptance Criteria
1. A teacher can see every student attempt for a Quest and open any answer.
2. Awarding more than a question's maximum marks is rejected.
3. Saving grades updates the attempt's total, percentage, grade and pass/fail.
4. An annotated PDF can be attached to a graded answer.

#### Integration
- Receives from: StudentPortal (attempts, answers, files).
- Sends to: StudentPortal/Recommendation (result records, publication event).

---

### 3.12 Result Publication & Recommendation Trigger
**Requirement ID:** REQ-QST-012 | **Priority:** Standard (P1) | **Tags:** [WORKFLOW][NOTIFICATION][INTEGRATION]

#### Business Description
When a teacher publishes a graded result (or enables auto-publish on an allocation), the result becomes visible to the student and a result-published event is raised so the Recommendation engine can generate personalised follow-up. Enabling auto-publish on an allocation also makes any previously hidden recommendations for that allocation's students visible.

#### Actors
- **Initiates:** Teacher / System (auto-publish)
- **Processes / Approves:** Recommendation module
- **Views / Receives:** Student

#### Business Rules
| Rule ID | Business Rule | Type |
|---------|---------------|------|
| BR-QST-024 | (reuse) Results are released to students only via manual publish or auto-publish at the result-publish date. | Workflow |

#### Acceptance Criteria
1. Publishing a result raises the result-published event.
2. Enabling auto-publish on an allocation reveals previously hidden recommendations for its students.

#### Integration
- Sends to: Recommendation (event); StudentPortal (visibility).

---

### 3.13 Quest Performance Report
**Requirement ID:** REQ-QST-013 | **Priority:** Standard (P1) | **Tags:** [REPORT]

#### Business Description
For a single Quest, a teacher views a performance report: the full set of assigned students (aggregated across all the Quest's allocations), each student's attempt status (not started / in progress / submitted), the average score, and a score-distribution chart. The student list is searchable and paginated.

#### Actors
- **Initiates:** Teacher
- **Views / Receives:** Teacher, School Admin

#### Acceptance Criteria
1. The report lists all students assigned through any of the Quest's allocations, without duplicates.
2. Each student shows their latest attempt status.
3. Average score and score-distribution reflect published/evaluated results.

#### Integration
- Receives from: StudentPortal, SchoolSetup, StudentProfile.

---

### 3.14 Student Attempt Detail Review
**Requirement ID:** REQ-QST-014 | **Priority:** Standard (P1) | **Tags:** [REPORT]

#### Business Description
A teacher opens a single student's attempt to review the detailed outcome: pass/fail, percentage, attempt number, time taken, submission time, marks obtained, correct/wrong counts, each question with its options and the student's answer, descriptive answer text and any attached/annotated files, and the explanation.

#### Actors
- **Initiates:** Teacher
- **Views / Receives:** Teacher

#### Acceptance Criteria
1. The detail view shows the attempt's outcome summary and per-question answers.
2. Uploaded and annotated answer files are accessible.
3. For descriptive questions, the student's text answer and remarks are shown.

#### Integration
- Receives from: StudentPortal (attempt, answers, media).

---

### 3.15 Difficulty Distribution Enforcement
**Requirement ID:** REQ-QST-015 | **Priority:** Standard (P1) | **Tags:** [CONFIGURATION][WORKFLOW]

#### Business Description
When a Quest references a difficulty-distribution profile (and is not set to ignore it), the system enforces, as questions are added, that the mix of question types/complexity stays within the profile's minimum and maximum percentages, and can suggest per-question marks from matching rules. A Quest can opt out via the "ignore difficulty configuration" flag.

#### Actors
- **Initiates:** Teacher (during question add)
- **Processes / Approves:** System
- **Views / Receives:** Teacher

#### Business Rules
| Rule ID | Business Rule | Type |
|---------|---------------|------|
| BR-QST-015 | (reuse) Added questions must satisfy the attached difficulty profile's min–max percentages unless ignored. | Validation |

#### Acceptance Criteria
1. Adding questions that breach a difficulty rule's maximum is rejected with the rule detail.
2. Setting "ignore difficulty configuration" disables enforcement.
3. Where a matching rule defines marks, the system can apply those marks to added questions.

#### Integration
- Receives from: LmsQuiz (difficulty configs/details).

---

### 3.16 Question Usage Tracking & Reuse Filters
**Requirement ID:** REQ-QST-016 | **Priority:** Standard (P1) | **Tags:** [INTEGRATION][WORKFLOW]

#### Business Description
The module records which Question-Bank questions have been used in Quests and honours per-Quest reuse filters: "only unused questions" (exclude questions already in the usage log) and "only authorised questions" (only those flagged usable for assessments). Usage records are added when questions are added and removed when questions are removed.

#### Actors
- **Initiates:** Teacher (implicitly, on add/remove)
- **Processes / Approves:** System
- **Views / Receives:** Teacher

#### Business Rules
| Rule ID | Business Rule | Type |
|---------|---------------|------|
| BR-QST-017 | (reuse) "Only unused questions" excludes questions present in the usage log. | Validation |
| BR-QST-018 | (reuse) "Only authorised questions" restricts to questions flagged usable for assessments. | Validation |
| BR-QST-020 | (reuse) Adding/removing a question writes/clears a Quest usage-log entry. | Workflow |

#### Acceptance Criteria
1. With "only unused" on, previously used questions are not offered/added.
2. Removing a question from a Quest clears its usage record.

#### Integration
- Receives from / Sends to: QuestionBank (usage log).

---

### 3.17 Activity Log / Audit Trail
**Requirement ID:** REQ-QST-017 | **Priority:** Standard (P1) | **Tags:** [REPORT]

#### Business Description
Every create, update, delete, restore and toggle action on a Quest, scope, question or allocation is recorded with the action, a message and the performing user. A Quest-attempt activity log tab lets teachers review attempt-related events, filterable by event type and date range.

#### Actors
- **Initiates:** System (on each action)
- **Views / Receives:** Teacher, School Admin

#### Acceptance Criteria
1. Each create/update/delete/restore/toggle writes an audit entry naming the actor.
2. The activity-log tab can be filtered by event type and date range.

#### Integration
- Uses platform activity-log infrastructure.

---

### 3.18 Access Control & Permissions
**Requirement ID:** REQ-QST-018 | **Priority:** Core (P0) | **Tags:** [INTEGRATION]

#### Business Description
Every Quest function is protected by a permission specific to its entity and action (view, create, update, delete, restore, permanent delete). Only users granted the relevant permission may perform each action, and data is isolated to the user's own school.

#### Actors
- **Initiates:** Any role
- **Processes / Approves:** System (authorisation)

#### Business Rules
| Rule ID | Business Rule | Type |
|---------|---------------|------|
| BR-QST-018a | Each Quest action requires its corresponding permission; unauthorised users are refused. | Permission |

> Known gap: the Quest hub listing screen currently does not enforce its view permission (see Risk RISK-QST-001 / Gap in §10).

#### Acceptance Criteria
1. A user without a given permission is refused that action.
2. A user only sees and acts on their own school's Quests.
3. The Quest hub view enforces the view permission.

#### Integration
- Uses SystemConfig RBAC.

---

### 3.19 Cascade Filtering (AJAX support)
**Requirement ID:** REQ-QST-019 | **Priority:** Enhanced (P2) | **Tags:** [DATA_ENTRY]

#### Business Description
Forms provide dependent dropdowns so that selecting a class filters sections; selecting a class/subject filters lessons; selecting a lesson filters topics (including a multi-level topic hierarchy); and selecting an allocation type filters the target options. These keep teachers from picking invalid combinations.

#### Actors
- **Initiates:** Teacher
- **Processes / Approves:** System

#### Acceptance Criteria
1. Dependent dropdowns return only options valid for the parent selection.
2. The topic dropdown reflects the multi-level topic hierarchy.

#### Integration
- Receives from: SchoolSetup, Syllabus.

---

### 3.20 System-Generated Quests
**Requirement ID:** REQ-QST-020 | **Priority:** Enhanced (P2) | **Tags:** [CONFIGURATION][SCHEDULED] | **Status: Not yet built**

#### Business Description
A Quest can be flagged as system-generated so the platform auto-selects its questions from the Question Bank according to the difficulty profile and the Quest's scope, honouring the unused/authorised filters. The configuration flag exists; the automatic selection capability is not yet implemented.

#### Actors
- **Initiates:** Teacher (sets flag) / System (selection)
- **Processes / Approves:** System

#### Business Rules
| Rule ID | Business Rule | Type |
|---------|---------------|------|
| BR-QST-013 / BR-QST-015 / BR-QST-017 / BR-QST-018 | (reuse) Auto-selection must respect total counts, difficulty profile, and reuse filters. | Calculation |

#### Acceptance Criteria
1. A system-generated Quest is populated with questions matching its scope and difficulty profile.
2. If insufficient questions exist for a tier, the teacher is warned with the shortfall.

#### Integration
- Receives from: QuestionBank, LmsQuiz.

#### Enhancement Notes
ENH-QST-004 — build the auto-selection capability.

---

### 3.21 Student Quest-Taking Pipeline (dependency)
**Requirement ID:** REQ-QST-021 | **Priority:** Core (P0) | **Tags:** [WORKFLOW] | **Owned by StudentPortal**

#### Business Description
Students see the Quests allocated to them within their valid timing window, start an attempt (subject to max-attempts and the cut-off), answer and save progress, submit, and later view their result when released. Multiple-choice answers are auto-graded; descriptive answers wait for teacher grading (REQ-QST-011). This experience is delivered by the StudentPortal module on the shared attempt tables; Quests depends on it for the full assessment loop to function.

#### Actors
- **Initiates:** Student
- **Processes / Approves:** System (auto-grade, timer), Teacher (descriptive)
- **Views / Receives:** Student

#### Business Rules
| Rule ID | Business Rule | Type |
|---------|---------------|------|
| BR-QST-021b | A student may start an attempt only within the allocation's publish-to-cut-off window. | Workflow |
| BR-QST-004b | A student is limited to the Quest's maximum number of attempts. | Workflow |

#### Acceptance Criteria
1. A student can attempt a Quest only inside its valid window and within max attempts.
2. A submitted attempt yields a stored result that the teacher can grade and publish.

#### Integration
- Owned by StudentPortal; consumes Quest, scope, question and allocation definitions.

---

## Section 4 — Business Rules Register
| Rule ID | Description | Feature | Type | Priority |
|---------|-------------|---------|------|----------|
| BR-QST-001 | Quest code must be globally unique. | REQ-QST-001 | Validation | P0 |
| BR-QST-002 | Title + academic year + class + subject + Quest type required to save. | REQ-QST-001 | Validation | P0 |
| BR-QST-003 | Passing % within 0–100; marks/questions non-negative. | REQ-QST-001 | Validation | P0 |
| BR-QST-004 | Multiple attempts off ⇒ max attempts = 1. | REQ-QST-001 | Validation | P0 |
| BR-QST-005 | Timer enforced ⇒ duration ≥ 1 minute. | REQ-QST-001 | Validation | P1 |
| BR-QST-006 | New Quest starts Draft; creator recorded. | REQ-QST-001 | Workflow | P0 |
| BR-QST-007 | Scope row needs a lesson; topic optional. | REQ-QST-002 | Validation | P0 |
| BR-QST-008 | No duplicate lesson+topic scope per Quest. | REQ-QST-002 | Validation | P1 |
| BR-QST-009 | Target count 0 = no limit. | REQ-QST-002 | Calculation | P1 |
| BR-QST-010 | Max 20 scopes per Quest. | REQ-QST-002 | Validation | P2 |
| BR-QST-011 | Scopes locked once Quest is in use. | REQ-QST-002 | Workflow | P1 |
| BR-QST-012 | No duplicate question per Quest. | REQ-QST-003 | Validation | P0 |
| BR-QST-013 | Assigned questions ≤ configured total questions. | REQ-QST-003 | Validation | P0 |
| BR-QST-014 | Sum of marks ≤ configured total marks; awarded ≤ max per question. | REQ-QST-003 / 011 | Calculation | P0 |
| BR-QST-015 | Added questions satisfy difficulty profile min–max (unless ignored). | REQ-QST-003 / 015 | Validation | P1 |
| BR-QST-016 | Questions must not exceed scope target counts. | REQ-QST-003 | Validation | P1 |
| BR-QST-017 | "Only unused" excludes used questions. | REQ-QST-003 / 016 | Validation | P1 |
| BR-QST-018 | "Only authorised" restricts to assessment-authorised questions. | REQ-QST-003 / 016 | Validation | P1 |
| BR-QST-018a | Each action requires its permission; unauthorised refused. | REQ-QST-018 | Permission | P0 |
| BR-QST-019 | No override ⇒ use Question-Bank default marks. | REQ-QST-003 | Calculation | P1 |
| BR-QST-020 | Add/remove question writes/clears usage log. | REQ-QST-003 / 016 | Workflow | P1 |
| BR-QST-021 | Quest must be active to allocate. | REQ-QST-004 | Validation | P0 |
| BR-QST-021b | Student attempt only within publish→cut-off window. | REQ-QST-021 | Workflow | P0 |
| BR-QST-022 | Allocation type valid; target exists and active. | REQ-QST-004 | Validation | P0 |
| BR-QST-023 | Cut-off ≥ due date when both set. | REQ-QST-004 | Validation | P1 |
| BR-QST-024 | Result-publish date only with auto-publish; results released via publish/auto. | REQ-QST-004 / 012 | Validation/Workflow | P1 |
| BR-QST-025 | Missing cut-off defaults to due date. | REQ-QST-004 | Workflow | P2 |
| BR-QST-026 | Allocation records assigner (or system). | REQ-QST-004 | Workflow | P1 |
| BR-QST-027 | Publish allowed only when ready (questions present, count matches, context complete, settings valid); pass/fail by passing %. | REQ-QST-005 / 011 | Workflow/Calculation | P1 |
| BR-QST-028 | Archiving deactivates the Quest. | REQ-QST-005 | Workflow | P1 |
| BR-QST-029 | Duplicate ⇒ new Draft, new code, cloned scopes/questions. | REQ-QST-006 | Workflow | P2 |
| BR-QST-030 | In-use records cannot be edited/deleted/restored/force-deleted. | REQ-QST-007 | Workflow | P1 |
| BR-QST-031 | Soft-delete archives+deactivates; force-delete cascades to scopes/questions. | REQ-QST-007 | Workflow | P1 |
| BR-QST-032 | Toggling a scope applies to all scopes of the Quest. | REQ-QST-008 | Workflow | P2 |
| BR-QST-004b | Student limited to Quest max attempts. | REQ-QST-021 | Workflow | P0 |

> Count: 32 distinct BR IDs (BR-QST-001…032) plus 3 sub-rules (018a, 021b, 004b) used where a rule has a related variant; the canonical register count is **32**.

---

## Section 5 — Data Requirements

### 5.1 Quest (business view)
**What it represents:** A multi-lesson assessment definition with its grading and behaviour configuration.

| Information | Meaning | Required | Notes |
|-------------|---------|----------|-------|
| Quest Code | Unique identifier | Yes | Auto-generated |
| Title | Display name | Yes | |
| Description / Instructions | Free text for students | No | |
| Academic Year / Class / Subject | Context | Yes | |
| Quest Type | Pedagogical category | Yes | From master |
| Status | Draft / Published / Archived | Yes | Default Draft |
| Total Marks / Total Questions | Targets | Yes | |
| Passing Percentage | Pass threshold | Yes | Default 33% |
| Duration | Time limit (minutes) | No | Blank = unlimited |
| Attempt policy | Multiple attempts? max attempts | Yes | |
| Negative Marks | Deduction factor | No | 0 = off |
| Display flags | Randomise, show marks/correct answer/explanation, enforce timer | No | |
| Question filters | Only unused / only authorised; difficulty profile; ignore profile | No | |
| System-generated | Auto-select questions | No | Flag only (capability pending) |

**Relationships:** has many Scopes; has many Questions (via junction); has many Allocations; has many student Attempts/Results (shared tables).
**Retention / Privacy:** Internal (teacher-authored). Soft-deleted, archivable. No student PII on the Quest itself.

### 5.2 Quest Scope
Coverage entry: lesson (+optional topic), optional question-type filter, target count. Belongs to one Quest. Internal.

### 5.3 Quest Question (assignment)
Link of a Question-Bank question to a Quest with order and optional marks override. Unique per (Quest, Question). Internal.

### 5.4 Quest Allocation
Assignment of a Quest to a Class/Section/Group/Student with publish/due/cut-off/result dates and assigner. Internal; references student/group identifiers.

### 5.5 Attempt / Answer / Result (shared, StudentPortal-owned)
Student attempt records, per-question answers (with files), and evaluated results. **Sensitive** — contains student performance data; per-school isolated.

### 5.6 Technical Data Dictionary (technical register)
| Table | Owner | Key columns / notes |
|-------|-------|---------------------|
| `lms_quests` | QST | uuid (binary16), quest_code UNIQUE, status VARCHAR, academic_session_id→glb_academic_sessions, class_id→sch_classes, subject_id→sch_subjects, quest_type_id→lms_assessment_types, difficulty_config_id→lms_difficulty_distribution_configs, created_by→sys_users; total_marks DECIMAL(8,2), total_questions, passing_percentage DECIMAL(5,2), negative_marks DECIMAL(4,2), allow_multiple_attempts, max_attempts, is_randomized, question_marks_shown, auto_publish_result, timer_enforced, show_correct_answer, show_explanation, ignore_difficulty_config, is_system_generated, only_unused_questions, only_authorised_questions; soft deletes. **Anomalies:** model field `show_result_immediately` and request field `pending` have NO backing column. |
| `lms_quest_scopes` | QST | quest_id→lms_quests, lesson_id→slb_lessons, topic_id→slb_topics, question_type_id→slb_question_types (FK added by 2026_06_18 migration), target_question_count. |
| `lms_quest_questions` | QST | quest_id, question_id→qns_questions_bank, ordinal, marks_override DECIMAL(5,2); UNIQUE(quest_id, question_id). |
| `lms_quest_allocations` | QST | quest_id, allocation_type ENUM(CLASS,SECTION,GROUP,STUDENT), target_table_name, target_id (polymorphic, app-level FK), assigned_by→sys_users, published_at, due_date, cut_off_date, is_auto_publish_result, result_publish_date; INDEX(allocation_type,target_id). |
| `lms_assessment_types`, `lms_difficulty_distribution_configs/_details` | LmsQuiz | read-only masters. |
| `lms_quiz_quest_attempts/_attempt_answers`, `lms_quiz_quest_results` | Shared (models in StudentPortal) | attempts filtered by `assessment_type='QUEST'`; FK to attempt is `quest_allocation_id` in one relation vs `allocation_id` elsewhere — confirm canonical. |
| `qns_questions_bank`, `qns_question_options`, `qns_question_usage_log` | QuestionBank | question source / usage tracking (`question_usage_type='QUEST'`). |

---

## Section 6 — Workflows

### 6.1 Quest Authoring → Publish
**Trigger:** Teacher creates a Quest. **End state:** Quest Published (ready to allocate).
1. Teacher creates Quest (Draft) → BR-QST-001..006.
2. Teacher adds scopes (lessons/topics) → BR-QST-007..010.
3. Teacher adds questions from the bank → BR-QST-012..020; difficulty/scope checks.
4. Teacher requests publish → readiness check (BR-QST-027).
   - Decision: not ready → return reasons (missing questions, count mismatch, incomplete context).
   - Decision: ready → status = Published.
**Exception paths:** readiness fails → stay Draft with errors; Quest in use → editing blocked (BR-QST-030).
**Notifications:** (proposed) notify on publish — ENH-QST-006.

### 6.2 Allocation
**Trigger:** Teacher allocates an active Quest. **End state:** Allocation saved with timing.
1. Choose type + target (BR-QST-021..022). 2. Set dates (BR-QST-023..025). 3. System records assigner (BR-QST-026).
**Exception:** invalid date order or target → rejected.
**Notifications:** (proposed) notify students on publish date / approaching due date.

### 6.3 Student Attempt (dependency — StudentPortal)
**Trigger:** Student opens an allocated Quest in window. **End state:** Attempt submitted/timed-out.
Start (BR-QST-021b, 004b) → answer/save → submit → MCQ auto-grade; descriptive pending.
**Exception:** outside window / over max attempts → blocked; timer expiry → auto-timeout.

### 6.4 Paper Check, Grading & Result Publication
**Trigger:** Teacher opens paper-check for a Quest. **End state:** Results graded and published.
1. View attempts → 2. Grade per question (cap at max — BR-QST-014) → 3. Compute %, grade, pass/fail (BR-QST-027) → 4. Optionally attach annotated PDF → 5. Publish result → raises result-published event (REQ-QST-012).
**Exception:** awarded > max marks → rejected.
**Notifications (system events):** result-published event → Recommendation; published results visible to student.

### 6.5 Delete / Trash / Restore / Permanent Delete
**Trigger:** Teacher/Admin acts on a Quest or child. **End state:** record trashed/restored/removed.
Usage guard checked first (BR-QST-030). Soft-delete archives+deactivates (BR-QST-031); force-delete cascades to scopes/questions.
**Exception:** in-use record → action blocked with message.

---

## Section 7 — Reporting & Analytics

### 7.1 Quest Management Dashboard — RPT-QST-001
**Purpose:** Overview of Quest activity and outcomes. **Audience:** Teacher/Admin. **Frequency:** Daily.
Contents: total quests/questions/allocations/submissions/checked; average score; status breakdown; monthly quest & allocation trends; subject- and class-wise breakdown; score distribution; recent quests with counts.
Filters: class-section, subject, date range. Export: on-screen.

### 7.2 Quest Summary / Allocation Monitor — RPT-QST-002
**Purpose:** Per-allocation submission tracking. **Audience:** Teacher. **Frequency:** Daily.
Contents: per allocation — quest, subject, assigner, target, assigned/submitted/in-progress/checked counts. Filters: class-section, subject, date. Export: on-screen.

### 7.3 Quest Performance Report — RPT-QST-003
**Purpose:** Per-Quest student outcomes. **Audience:** Teacher/Admin. **Frequency:** As-needed.
Contents: assigned students (deduped across allocations), attempt status, average score, score-distribution chart. Filters: search by student. Export: on-screen (paginated).

### 7.4 Student Attempt Detail — RPT-QST-004
**Purpose:** Single student's attempt review. **Audience:** Teacher. **Frequency:** As-needed.
Contents: outcome summary, per-question answers/options, descriptive text, files, explanations. Export: on-screen.

### 7.5 Activity / Audit Log — RPT-QST-005
**Purpose:** Audit of attempt and management actions. **Audience:** Teacher/Admin. **Frequency:** As-needed.
Contents: events with actor/message/time. Filters: event type, date range. Export: on-screen.

### 7.6 Trash Listings — RPT-QST-006
**Purpose:** Review soft-deleted Quests/scopes/questions/allocations for restore. **Audience:** Admin. **Frequency:** As-needed.
Contents: trashed records grouped (scopes grouped per quest). Export: on-screen.

---

## Section 8 — Future Enhancement Log
| Enhancement ID | Feature | Business Value | Priority | Status |
|----------------|---------|----------------|----------|--------|
| ENH-QST-001 | Dedicated publish/archive action that always enforces the readiness check | Prevents publishing incomplete Quests via the edit form | P1 | Backlog |
| ENH-QST-002 | Single source for Quest-code generation (remove duplicate path) | Avoids inconsistent codes | P2 | Backlog |
| ENH-QST-003 | Expose Quest duplication via a dedicated action/button | Saves teacher setup time (capability exists) | P2 | Backlog |
| ENH-QST-004 | Build system-generated question auto-selection | Automates Quest building per difficulty/scope | P2 | Backlog |
| ENH-QST-005 | Retire phantom fields (`show_result_immediately`, `pending`) | Schema/code hygiene | P3 | Backlog |
| ENH-QST-006 | Notifications on publish / due-date / result release | Keeps students informed | P2 | Backlog |

---

## Section 9 — Non-Functional Requirements

### 9.1 Performance
| Requirement | Standard |
|-------------|----------|
| Quest hub / list load | ≤ 3s for 500 concurrent users |
| Dashboard analytics | ≤ 10s; eager-load to avoid N+1 (current accessors run multiple queries) |
| Concurrent student attempts | 500+ simultaneously (via StudentPortal) |

### 9.2 Security
| Requirement | Rule |
|-------------|------|
| Access control | Each action gated by its permission; **re-enable the Quest-hub view permission** (currently disabled). |
| Module entitlement | Apply module-entitlement middleware to the route group (currently only tenant-active is enforced). |
| Data isolation | One school's Quests never visible to another (database-per-tenant). |
| Audit | All create/update/delete/restore/toggle logged with actor. |
| Logging hygiene | Avoid logging raw request payloads (use validated/named fields). |

### 9.3 Usability
| Requirement | Standard |
|-------------|----------|
| Tab-hub navigation | All Quest functions reachable from one hub screen. |
| Dependent dropdowns | Prevent invalid academic combinations. |
| Mobile | Core screens usable on mobile browsers. |
| Language | English (regional as future enhancement). |

---

## Section 10 — Gap Analysis Readiness Index

### 10.1 Requirement Coverage Summary
| Requirement ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|---------------|---------|----------|------|-------------------|---------------|------------|---------------------|------------------|
| REQ-QST-001 | Quest Creation & Config | P0 | DATA_ENTRY/CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-QST-002 | Scope Definition | P0 | DATA_ENTRY | Yes | Yes | Yes | No | Yes |
| REQ-QST-003 | Question Assignment | P0 | DATA_ENTRY/INTEGRATION | Yes | Yes | Yes | No | Yes |
| REQ-QST-004 | Allocation | P0 | WORKFLOW/CONFIG | Yes | Yes | Yes | Yes | Yes |
| REQ-QST-005 | Publish & Lifecycle | P1 | WORKFLOW/APPROVAL | No | Yes | Yes | No | Yes |
| REQ-QST-006 | Duplication | P2 | DATA_ENTRY | No | Yes | Yes | No | Yes |
| REQ-QST-007 | Soft Delete/Trash/Restore | P1 | WORKFLOW | No | Yes | Yes | No | Yes |
| REQ-QST-008 | Status Toggle | P1 | WORKFLOW | No | Yes | Yes | No | Yes |
| REQ-QST-009 | Management Dashboard | P1 | DASHBOARD/REPORT | No | Yes | Yes | No | No |
| REQ-QST-010 | Allocation Summary Monitor | P1 | DASHBOARD/REPORT | No | Yes | Yes | No | No |
| REQ-QST-011 | Paper Check & Grading | P0 | WORKFLOW/DATA_ENTRY | Yes | Yes | Yes | Yes | Yes |
| REQ-QST-012 | Result Publication & Recommendation | P1 | WORKFLOW/NOTIFICATION/INTEGRATION | Yes | Yes | Yes | Yes | Yes |
| REQ-QST-013 | Performance Report | P1 | REPORT | No | Yes | Yes | No | No |
| REQ-QST-014 | Attempt Detail Review | P1 | REPORT | Yes | Yes | Yes | No | No |
| REQ-QST-015 | Difficulty Enforcement | P1 | CONFIG/WORKFLOW | No | Yes | Yes | No | Yes |
| REQ-QST-016 | Usage Tracking & Filters | P1 | INTEGRATION/WORKFLOW | Yes | No | Yes | No | Yes |
| REQ-QST-017 | Activity Log | P1 | REPORT | Yes | Yes | Yes | No | No |
| REQ-QST-018 | Access Control | P0 | INTEGRATION | No | No | Yes | No | Yes |
| REQ-QST-019 | Cascade Filtering (AJAX) | P2 | DATA_ENTRY | No | No | Yes | No | No |
| REQ-QST-020 | System-Generated Quests | P2 | CONFIG/SCHEDULED | No | Yes | Yes | No | Yes |
| REQ-QST-021 | Student Attempt Pipeline (StudentPortal) | P0 | WORKFLOW | Yes | Yes | Yes | Yes | Yes |

### 10.2 Business Rules Coverage Summary
| Rule ID | Summary | Feature Ref | Validation Required | Data Check Required | Workflow Gate |
|---------|---------|-------------|--------------------|--------------------|---------------|
| BR-QST-001 | Unique code | REQ-001 | Yes | Yes | No |
| BR-QST-002 | Required context | REQ-001 | Yes | No | No |
| BR-QST-003 | Numeric ranges | REQ-001 | Yes | No | No |
| BR-QST-004 | Attempts policy | REQ-001 | Yes | No | No |
| BR-QST-005 | Timer duration | REQ-001 | Yes | No | No |
| BR-QST-006 | Draft+creator | REQ-001 | No | No | Yes |
| BR-QST-007 | Lesson required | REQ-002 | Yes | No | No |
| BR-QST-008 | No dup scope | REQ-002 | Yes | Yes | No |
| BR-QST-009 | 0 = no limit | REQ-002 | No | No | No |
| BR-QST-010 | Max 20 scopes | REQ-002 | Yes | Yes | No |
| BR-QST-011 | Scope lock in-use | REQ-002 | No | Yes | Yes |
| BR-QST-012 | No dup question | REQ-003 | Yes | Yes | No |
| BR-QST-013 | Count ≤ total | REQ-003 | Yes | Yes | Yes |
| BR-QST-014 | Marks ≤ total / ≤ max | REQ-003/011 | Yes | Yes | Yes |
| BR-QST-015 | Difficulty min–max | REQ-003/015 | Yes | Yes | Yes |
| BR-QST-016 | Scope targets | REQ-003 | Yes | Yes | Yes |
| BR-QST-017 | Only unused | REQ-003/016 | Yes | Yes | No |
| BR-QST-018 | Only authorised | REQ-003/016 | Yes | Yes | No |
| BR-QST-018a | Permission per action | REQ-018 | Yes | No | Yes |
| BR-QST-019 | Default marks | REQ-003 | No | Yes | No |
| BR-QST-020 | Usage log write | REQ-003/016 | No | Yes | Yes |
| BR-QST-021 | Active to allocate | REQ-004 | Yes | Yes | Yes |
| BR-QST-021b | Attempt window | REQ-021 | Yes | Yes | Yes |
| BR-QST-022 | Valid target | REQ-004 | Yes | Yes | No |
| BR-QST-023 | Date order | REQ-004 | Yes | No | No |
| BR-QST-024 | Result-publish gating | REQ-004/012 | Yes | No | Yes |
| BR-QST-025 | Cut-off default | REQ-004 | No | No | Yes |
| BR-QST-026 | Assigner recorded | REQ-004 | No | No | Yes |
| BR-QST-027 | Publish readiness / pass% | REQ-005/011 | Yes | Yes | Yes |
| BR-QST-028 | Archive deactivates | REQ-005 | No | No | Yes |
| BR-QST-029 | Duplicate rules | REQ-006 | No | Yes | Yes |
| BR-QST-030 | In-use guard | REQ-007 | No | Yes | Yes |
| BR-QST-031 | Delete cascade rules | REQ-007 | No | Yes | Yes |
| BR-QST-032 | Scope toggle group | REQ-008 | No | Yes | Yes |
| BR-QST-004b | Max attempts (student) | REQ-021 | Yes | Yes | Yes |

### 10.3 Report Coverage Summary
| Report ID | Name | Priority | Filters Count | Export Needed |
|-----------|------|----------|---------------|---------------|
| RPT-QST-001 | Management Dashboard | P1 | 3 | No |
| RPT-QST-002 | Allocation Summary | P1 | 3 | No |
| RPT-QST-003 | Performance Report | P1 | 1 | No |
| RPT-QST-004 | Attempt Detail | P1 | 0 | No |
| RPT-QST-005 | Activity Log | P1 | 2 | No |
| RPT-QST-006 | Trash Listings | P2 | 0 | No |

### 10.4 Total Scope Numbers
| Category | Count |
|----------|-------|
| Total Functional Requirements (REQ-) | 21 |
| Total Business Rules (BR-) | 32 |
| Total Workflows defined | 5 (6.1–6.5) |
| Total Reports required | 6 |
| Total Enhancements logged | 6 |
| Total P0 (Core) Requirements | 7 (REQ-001,002,003,004,011,018,021) |
| Total P1 (Standard) Requirements | 10 (REQ-005,007,008,009,010,012,013,014,015,016,017 → note 11 listed; see reconciliation) |
| Total P2 (Enhanced) Requirements | 4 (REQ-006,019,020 + …) |

> **Priority reconciliation (authoritative):** P0 = 7 (REQ-001, 002, 003, 004, 011, 018, 021). P2 = 3 (REQ-006, 019, 020). P1 = 11 (REQ-005, 007, 008, 009, 010, 012, 013, 014, 015, 016, 017). 7 + 11 + 3 = 21. (The P1 row above is the correct count of 11; the "10" was a draft figure — use **P1 = 11**.)

---

## Section 11 — Requirements Traceability Matrix (RTM)
| REQ-ID | Feature | BR refs | Screen(s) | Workflow | Report(s) | Code Status (live) | Gap |
|--------|---------|---------|-----------|----------|-----------|--------------------|-----|
| REQ-QST-001 | Creation | 001–006 | quest/create,edit | 6.1 | — | DONE | duplicate code-gen; phantom fields |
| REQ-QST-002 | Scopes | 007–011 | quest-scope/* | 6.1 | — | DONE | child index 404 (by design) |
| REQ-QST-003 | Questions | 012–020 | quest-question/* | 6.1 | — | DONE | store() undefined `$quest` |
| REQ-QST-004 | Allocation | 021–026 | quest-allocation/* | 6.2 | — | DONE | — |
| REQ-QST-005 | Publish | 027,028 | quest/edit | 6.1 | — | PARTIAL | no dedicated publish route (guard bypass) |
| REQ-QST-006 | Duplicate | 029 | — | 6.1 | — | PARTIAL | model only; no UI action |
| REQ-QST-007 | Trash/Restore | 030,031 | */trash | 6.5 | RPT-006 | DONE | — |
| REQ-QST-008 | Toggle | 032 | tab hub | 6.5 | — | DONE | — |
| REQ-QST-009 | Dashboard | — | dashboard/index | — | RPT-001 | DONE | accessor N+1 |
| REQ-QST-010 | Summary | — | summary/index | — | RPT-002 | DONE | — |
| REQ-QST-011 | Paper Check | 014,027 | paper-check/* | 6.4 | — | DONE | — |
| REQ-QST-012 | Result Publish | 024 | paper-check | 6.4 | — | DONE | notifications absent |
| REQ-QST-013 | Performance Rpt | — | summary/report | — | RPT-003 | DONE | — |
| REQ-QST-014 | Attempt Detail | — | summary/student_result | — | RPT-004 | DONE | — |
| REQ-QST-015 | Difficulty | 015 | quest-question | 6.1 | — | DONE | — |
| REQ-QST-016 | Usage Filters | 017,018,020 | quest-question (AJAX) | 6.1 | — | DONE | usage-type code path commented |
| REQ-QST-017 | Activity Log | — | activity_log/index | — | RPT-005 | DONE | — |
| REQ-QST-018 | Access Control | 018a | (all) | — | — | PARTIAL | hub viewAny gate disabled |
| REQ-QST-019 | Cascade AJAX | — | (forms) | — | — | DONE | — |
| REQ-QST-020 | System-Generated | 013,015,017,018 | quest/create flag | — | — | NOT STARTED | no generation service |
| REQ-QST-021 | Student Pipeline | 021b,004b | StudentPortal | 6.3 | — | DONE (StudentPortal) | owned externally |

---

## Section 12 — Requirement Conditions Catalogue
> Reuses BR- IDs (canonical condition IDs). Canonical home also at `5-Requirement_Conditions/LmsQuests_Conditions.md` if/when split out.

| Condition (=BR-) | Entity/Field | Condition (business) | Type | Trigger | On-Violation |
|------------------|--------------|----------------------|------|---------|--------------|
| BR-QST-001 | Quest.code | Globally unique | Validation | Save | Regenerate/reject |
| BR-QST-003 | Quest.passing_percentage | 0–100 | Validation | Save | Reject |
| BR-QST-004 | Quest.max_attempts | =1 when multiple off | Validation | Save | Reject |
| BR-QST-005 | Quest.duration | ≥1 when timer on | Validation | Save | Reject |
| BR-QST-008 | Scope (lesson,topic) | Unique per quest | Validation | Save | Reject |
| BR-QST-010 | Scopes | ≤20 per quest | Validation | Save | Reject |
| BR-QST-012 | Question | Unique per quest | Validation | Add | Reject |
| BR-QST-013 | Questions count | ≤ total_questions | Validation | Add | Reject w/ counts |
| BR-QST-014 | Marks | ≤ total / ≤ max | Validation | Add/Grade | Reject |
| BR-QST-015 | Difficulty mix | Within min–max % | Validation | Add | Reject w/ rule |
| BR-QST-016 | Scope target | Not exceeded | Validation | Add | Reject |
| BR-QST-023 | Dates | cut-off ≥ due | Validation | Save allocation | Reject |
| BR-QST-024 | result_publish_date | Only with auto-publish | Validation | Save allocation | Reject/clear |
| BR-QST-027 | Quest publish | Ready conditions met | Workflow | Publish | Block w/ reasons |
| BR-QST-030 | In-use record | Not mutated | Workflow | Edit/Delete | Block |

---

## Section 13 — Validation & Edge-Case Catalogue
| Field/Rule | Valid | Invalid | Boundary | Empty/null | Concurrency | Expected |
|------------|-------|---------|----------|------------|-------------|----------|
| Quest code | unique string | duplicate | very long title→code | blank → auto-gen | two creates same instant | both unique (loop/regen) |
| passing_percentage | 33 | 120 | 0 / 100 | blank | — | reject out of range |
| max_attempts | 3 (multi on) | 0 | 1 / 10 | blank | — | force 1 when multi off |
| duration | 60 | 0 (timer on) | 1 / 300 | blank=unlimited | — | reject <1 when timer on |
| scope lesson/topic | new pair | duplicate pair | 20th / 21st scope | topic null ok | two adds same pair | reject duplicate/21st |
| question add | within limits | over total | exactly = total | none selected | concurrent adds exceed total | reject overflow |
| marks override | ≤ remaining | exceeds total | = total | null→default | concurrent grade | reject overflow |
| allocation dates | cut-off ≥ due | cut-off < due | equal dates | nulls allowed | — | reject bad order |
| publish | ready | count mismatch | exactly matching | no questions | — | block w/ reason |
| grade marks | ≤ max | > max | = max | 0 | concurrent grade | reject > max |
| usage guard | not used | in use | first allocation just added | — | allocate during edit | block edit |

---

## Section 14 — State Machine (FSM) Catalogue

### Quest status
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| (none) | Create | required context | DRAFT | code generated, creator set |
| DRAFT | Publish | readiness (BR-QST-027) | PUBLISHED | published_at set |
| PUBLISHED | Archive | — | ARCHIVED | is_active=false |
| any | Soft delete | not in use | (trashed) | archived+inactive |
| (trashed) | Restore | not in use | DRAFT | is_active=true |
Illegal: publish without readiness; edit/delete when in use.

### Attempt status (shared; StudentPortal)
NOT_STARTED → IN_PROGRESS (start) → SUBMITTED (submit) / TIMEOUT (timer) / ABANDONED / CANCELLED; SUBMITTED → REASSIGNED (admin grants retry). Backed by ENUM on `lms_quiz_quest_attempts.status`.

---

## Section 15 — Cross-Module Dependency Map
**Inbound (Quests reads from):**
| Source | Data | Why |
|--------|------|-----|
| QuestionBank | questions, options, usage log | populate & track Quest questions |
| LmsQuiz | assessment types, difficulty configs/details | Quest type & difficulty enforcement |
| SchoolSetup | classes, sections, subjects, groups, class-section junction | context & allocation targets |
| Syllabus | lessons, topics, question types | scopes & filtering |
| StudentProfile | students, academic-session enrolments | allocation targets & reporting |
| Global/Prime | academic sessions, media | context & files |
| StudentPortal | attempts, answers, results | monitoring, grading, reporting |
| SystemConfig | users, permissions, activity log, dropdowns | auth & audit |

**Outbound (Quests feeds):**
| Target | Mechanism | What |
|--------|-----------|------|
| StudentPortal | shared allocation/quest definitions | drives student quest list & attempts |
| Recommendation | `QuizQuestResultPublished` event; hidden-recommendation publication | result-driven personalisation |
| QuestionBank | usage-log writes (`question_usage_type='QUEST'`) | question exposure tracking |

---

## Section 16 — NFR Catalogue & Risk Register

### NFR
| NFR-ID | Category | Requirement | Threshold |
|--------|----------|-------------|-----------|
| NFR-QST-01 | Performance | Hub/list load | ≤3s @500 users |
| NFR-QST-02 | Performance | Dashboard analytics | ≤10s; no N+1 |
| NFR-QST-03 | Scalability | Concurrent attempts | 500+ (StudentPortal) |
| NFR-QST-04 | Security | Action authorisation | every action gated; hub gate re-enabled |
| NFR-QST-05 | Security | Module entitlement | entitlement middleware on route group |
| NFR-QST-06 | Security | Tenant isolation | per-school DB isolation |
| NFR-QST-07 | Auditability | CUD logging | all actions logged with actor |
| NFR-QST-08 | Maintainability | Single code-gen path | remove duplicate generation |
| NFR-QST-09 | Testability | Coverage | ≥60% feature coverage (currently 0) |

### Risk
| Risk ID | Risk | Cat | Likelihood | Impact | Mitigation | Owner |
|---------|------|-----|------------|--------|------------|-------|
| RISK-QST-001 | Quest-hub view permission disabled → unauthorised data exposure | Security | High | High | Re-enable view gate | Backend |
| RISK-QST-002 | No module-entitlement gate → access outside plan | Security | Med | Med | Add entitlement middleware | Backend |
| RISK-QST-003 | Publish via edit form bypasses readiness check | Correctness | Med | Med | Dedicated publish action (ENH-QST-001) | Backend |
| RISK-QST-004 | Zero automated tests | Quality | High | Med | Add P0/P1 feature tests | QA |
| RISK-QST-005 | Phantom fields mislead developers | Maintainability | Med | Low | Remove fields (ENH-QST-005) | Backend |
| RISK-QST-006 | `QuestQuestionController::store()` undefined `$quest` | Correctness | Low | Med | Fix or remove dead path | Backend |
| RISK-QST-007 | Attempt FK naming inconsistency (allocation_id vs quest_allocation_id) | Data integrity | Med | Med | Confirm canonical column | DB Architect |

---

## Section 17 — Prioritisation (MoSCoW) & Effort Estimation

### MoSCoW
- **Must:** REQ-001, 002, 003, 004, 011, 018, 021 (+ re-enable hub gate, fix store() path).
- **Should:** REQ-005, 007, 008, 009, 010, 012, 013, 014, 015, 016, 017; tests.
- **Could:** REQ-006, 019, 020; notifications (ENH-QST-006).
- **Won't (now):** LXP rewards; analytics-of-analytics.

### Effort (indicative, against similar LMS modules)
| Work item | Type | Effort (h) | Depends on |
|-----------|------|-----------|------------|
| Re-enable hub view gate | Backend/Security | 1–2 | — |
| Add module-entitlement middleware | Backend | 1–2 | — |
| Dedicated publish/archive action (ENH-001) | Backend/Frontend | 6–8 | — |
| Remove duplicate code-gen (ENH-002) | Backend | 2–3 | — |
| Fix store() undefined `$quest` | Backend | 1 | — |
| Retire phantom fields (ENH-005) | Backend/Schema | 2–3 | — |
| Expose duplication action (ENH-003) | Backend/Frontend | 3–4 | — |
| System-generated selection (ENH-004) | Backend/Service | 16–24 | difficulty data |
| Notifications (ENH-006) | Backend/Integration | 6–10 | Notification module |
| Feature/unit tests to ≥60% | Testing | 24–32 | above fixes |
| Confirm attempt FK naming | DB Architect | 1–2 | — |
| **Total** | | **63–91 h** | |

---

## Section 18 — User Stories (P0/P1)
- **US-QST-001 (REQ-001, P0):** As a Teacher, I want to create a Quest with academic context and grading rules so that I can assess across multiple lessons. AC: happy path saves Draft with unique code; missing context rejected; multi-off forces max=1; without view-permission user is refused.
- **US-QST-002 (REQ-002, P0):** As a Teacher, I want to define multiple lesson/topic scopes so the Quest covers a curriculum window. AC: add several rows; duplicate pair rejected; 21st rejected; in-use scopes locked.
- **US-QST-003 (REQ-003, P0):** As a Teacher, I want to add Question-Bank questions within limits so the Quest is valid. AC: bulk add; over-limit rejected with counts; duplicate rejected; reorder persists; empty selection rejected.
- **US-QST-004 (REQ-004, P0):** As a Teacher, I want to allocate a Quest to a class/section/group/student with dates so the right students get it on time. AC: each type works; bad date order rejected; result date without auto-publish rejected; inactive quest not allocatable.
- **US-QST-005 (REQ-011, P0):** As a Teacher, I want to grade student answers and publish results so students get feedback. AC: see all attempts; over-max marks rejected; saving updates %/grade/pass; annotated PDF attaches; publish raises recommendation event.
- **US-QST-006 (REQ-018, P0):** As a School Admin, I want every Quest action permission-gated so only authorised staff act. AC: no-permission → refused; cross-school data never shown; hub view gated.
- **US-QST-007 (REQ-021, P0):** As a Student, I want to attempt allocated Quests within the window so my work counts. AC: outside window blocked; over max attempts blocked; submitted attempt produces a gradable result.
- **US-QST-008 (REQ-005, P1):** As a Teacher, I want publishing blocked until the Quest is ready so I never publish incomplete Quests. AC: count mismatch/no questions → blocked with reason; ready → Published.
- **US-QST-009 (REQ-009/010, P1):** As a Teacher, I want a dashboard and allocation summary so I can monitor activity. AC: filters update metrics; counts match records.
- **US-QST-010 (REQ-007, P1):** As an Admin, I want to trash/restore/permanently delete Quests safely so in-use data is protected. AC: in-use blocked; restore returns to Draft; force-delete cascades.

---

## Section 19 — KPI / Metrics Catalogue
| KPI | Definition (business) | Source | Target | Cadence |
|-----|-----------------------|--------|--------|---------|
| Quest submission rate | submitted ÷ assigned per allocation | attempts vs allocation target | ≥80% | Per Quest |
| Average Quest score | mean result percentage | results | school-defined | Weekly |
| Pass rate | passed ÷ evaluated | results | ≥ passing threshold cohort | Per Quest |
| Grading turnaround | time from submission to result publish | attempts/results | ≤ school SLA | Weekly |
| Question reuse exposure | distinct questions used in Quests | usage log | balanced | Termly |
| Quest authoring volume | Quests created per month | quests | trend | Monthly |

---

## Document Control
| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-06-29 | Initial Complete Analysis Pack from live code + DDL + migrations + V2/V1 synthesis; three-way reconciled. | Business Analysis — Prime-AI |

*This document is the single source of truth for LmsQuests (QST) requirements. All gap analyses, completion scoring, and test coverage must reference its REQ-/BR-/RPT- IDs without renumbering.*
