# Marksheet Generation Module — Consolidated Requirement Document
## Core Marksheet · Standard Computation & Publication · Advanced Analytics (proposed)

| Field | Value |
|---|---|
| **Document** | Consolidated Requirement Document (CRD) |
| **Module family** | Marksheet Generation (MSG) |
| **Version** | 1.0 — Analysis baseline |
| **Date** | 2026-11-03 |
| **Status** | Requirement baseline — for architecture, remediation and build planning |
| **Prepared for** | Prime-AI Product & Engineering |
| **Supersedes** | The 5 BRD files in `_MarksheetGeneration`, the 17 screen requirement files in `MarksheetGeneration/Module_Requirement`, and `MarksheetGeneration_DDL_v1.1.sql` for requirement purposes |
| **Output folder** | `2-Prime-Ai_V2/9-Enhanced_Modules/MarksheetGeneration/Enhance_Design/` |
| **Authoritative schema** | `MarksheetGeneration_DDL_v1.1.sql` (23 physical tables) |
| **Authoritative as-built** | `Modules/MarksheetGeneration` in `prime_ai_dev` |

---

## Contents

- [0. How to read this document](#0-how-to-read-this-document)
- [1. Executive summary](#1-executive-summary)
- [2. Scope](#2-scope)
- [3. Actors and access](#3-actors-and-access)
- [4. Domain model and terminology](#4-domain-model-and-terminology)
- [5. Functional requirements](#5-functional-requirements)
  - [5.1 Foundation requirements](#51-foundation-requirements)
  - [5.2 Configuration requirements](#52-configuration-requirements)
  - [5.3 Scheduling and computation requirements](#53-scheduling-and-computation-requirements)
  - [5.4 Results and publication requirements](#54-results-and-publication-requirements)
  - [5.5 Output and reporting requirements](#55-output-and-reporting-requirements)
- [6. The ten correctness conditions — detailed interpretation](#6-the-ten-correctness-conditions--detailed-interpretation)
- [7. Business rules register](#7-business-rules-register)
- [8. Workflows](#8-workflows)
- [9. Data requirements](#9-data-requirements)
- [10. Reporting and analytics](#10-reporting-and-analytics)
- [11. Configuration catalogue](#11-configuration-catalogue)
- [12. Non-functional requirements](#12-non-functional-requirements)
- [13. Capability and build-status mapping](#13-capability-and-build-status-mapping)
- [14. Conflict resolution register](#14-conflict-resolution-register)
- [15. Additional suggestions](#15-additional-suggestions)
- [16. Open decisions](#16-open-decisions)
- [17. Traceability matrix](#17-traceability-matrix)
- [18. Glossary](#18-glossary)

---

## 0. How to read this document

### 0.1 Source hierarchy

This document reconciles four kinds of input. Where they disagree, the higher row wins, and the conflict is recorded in **Section 14**. A requirement that cannot be settled from the sources is **not invented**; it is raised in **Section 16 (Open Decisions)**.

| Rank | Source | What it contributes | What it cannot settle |
|---:|---|---|---|
| 1 | `MarksheetGeneration_DDL_v1.1.sql` | Physical data model, keys, constraints, seeded lookups, documented conditions | Screen behaviour and user intent |
| 2 | 17 screen requirement files — `.../4-TC_List_Requirement_Review/MarksheetGeneration/Module_Requirement/` | Field-level behaviour, business rules, workflows, examples | Whether the code actually does it |
| 3 | 5 BRD files — `.../4-Module_Requirement/_MarksheetGeneration/` | Business motive, module boundaries, high-level functional intent | Field-level precision; one file (`Temp.md`) is empty |
| 4 | Live code — `prime_ai_dev/Modules/MarksheetGeneration` | What is built today, including undocumented behaviour and defects | Product intent where code and documents disagree |

**Evidence convention used throughout:**

- **Documented** — stated in a BRD or a screen requirement file.
- **Schema-backed** — enforced or represented by the DDL.
- **As-built** — observed in the module source.
- **Gap** — documented or schema-backed intent that is missing, partial, or contradicted in code.
- **Decision needed** — no source resolves the point (Section 16).

### 0.2 Requirement IDs

| Prefix | Layer | Meaning |
|---|---|---|
| `FND-MSG-` | Foundation | Masters and shared configuration that everything else depends on |
| `STD-MSG-` | Standard | Template configuration, scheduling, computation, results, publication, output |
| `ADV-MSG-` | Advanced | Analytics, portals, automation and integrations that are target-state only |
| `BR-MSG-C` | Business rule — configuration | Master, template and component rules |
| `BR-MSG-S` | Business rule — scheduling | Schedule, lifecycle and computation-run rules |
| `BR-MSG-R` | Business rule — results | Result, mark and publication rules |
| `BR-MSG-O` | Business rule — output | Print, export and reporting rules |
| `CFG-MSG-` | Configuration parameter | School-settable parameter |
| `RPT-MSG-` | Report | Reporting requirement |
| `CF-` | Conflict | A recorded disagreement between sources |
| `OD-` | Open decision | A product question the sources do not answer |

**Priority:** P0 = must be correct before a school depends on the marksheet; P1 = required for a complete release; P2 = later / optional.

**Requirement status:** `Implemented` · `Partial` · `Missing` · `Contradicted` · `Decision needed`.

### 0.3 Product model (the target of this document)

Marksheet Generation is delivered today as a **single module**. Unlike Transport, it has no separate Standard and Prime codebase. This document therefore describes **capability layers inside one product**, not three licensed modules.

```
┌──────────────────────────────────────────────────────────────────────┐
│ ADVANCED — target state, not built                                   │
│ Parent/student result portal · analytics · longitudinal progress     │
│ AI anomaly detection · board-format packs · scheduled auto-publish   │
└───────────────────────────────▲──────────────────────────────────────┘
                                │ reads published results only
┌───────────────────────────────┴──────────────────────────────────────┐
│ STANDARD — the operational core (built, with gaps)                   │
│ Config templates · weightages · schedules · computation engine       │
│ lifecycle · review/publish/lock/unlock · results · print/export      │
└───────────────────────────────▲──────────────────────────────────────┘
                                │ depends on
┌───────────────────────────────┴──────────────────────────────────────┐
│ CORE — masters and configuration (built)                             │
│ Marksheet types · IA types · class groups · exam groups · sessions   │
│ teachers, classes, sections, subjects, students, permissions         │
└──────────────────────────────────────────────────────────────────────┘
```

The **Core** owns the vocabulary. The **Standard** layer turns that vocabulary into computed, reviewable and printable results. The **Advanced** layer is a consumer of published results and is explicitly out of the current build scope.

### 0.4 Status vocabulary

The module uses two different “status” concepts and they must never be conflated:

1. **Schedule lifecycle status** — `DRAFT → COMPUTED → REVIEWED → PUBLISHED → LOCKED`, stored as `msh_marksheet_schedules.status_id` (a `sys_dropdown_table` lookup).
2. **Per-student result status** — `NULL → DECLARED` or `WITHHELD`, stored as `msh_student_results.result_status` (a VARCHAR, not a lookup).

A schedule can be `PUBLISHED` while an individual student’s result is `WITHHELD`. Conversely, a result can carry `DECLARED` while its schedule is still `REVIEWED` if data was written outside the lifecycle. Section 14 records this as a design gap, not as intended behaviour.

### 0.5 What “computed marks” means in this document

The computation engine stores **normalized percentage points**, not raw school marks:

- `msh_student_subject_results.exam_weighted_total` is a 0–100 percentage after exam-type weightage.
- `homework_score`, `quiz_score`, `quest_score`, `ia_total` are 0–100 percentages.
- `subject_total` is the weighted sum of those percentages, so it is also expressed on a 0–100 scale for a fully weighted subject. `subject_max` is the sum of the active source weightages (normally 100).
- `msh_student_results.grand_total` is the sum of `subject_total` values, and `grand_max` is the sum of `subject_max` values.

The DDL comments use the words “marks”, “score” and “total” loosely. This document uses **normalized points** where precision matters and flags the confusion in Section 14.

---

## 1. Executive summary

### 1.1 The problem the module solves

An Indian K-12 school must, at the end of every term:

1. **Define** what a report card means for each class — which exams count, how much each counts, which internal assessments apply, what a pass is, and how numbers become grades.
2. **Collect** scores that already live in different academic modules — exams, homework, quizzes, quests, internal assessment, co-scholastic observation and attendance.
3. **Compute** a defensible subject total, subject grade, overall total, division, rank and promotion decision for every student.
4. **Review** the result before anyone outside the examination cell sees it.
5. **Publish** it under a controlled lifecycle, then freeze it so a later edit cannot silently change an issued report card.
6. **Produce** the physical or digital report card in the school’s own format.
7. **Prove** what was computed, when, by whom, from which source data, and what changed after an unlock.

The Marksheet Generation module is the system of record for steps 1, 3, 4, 5 and 7, and the aggregator for step 2. Step 6 is shared with the Template module.

### 1.2 The three artefacts that define the module today

| Artefact | What it is | What it gets right | What it does not finish |
|---|---|---|---|
| **BRD set (5 files)** | Business intent: dashboard, configuration, components, scheduling, results and print | Clear four-pillar navigation and a strict “no edit after publish” motive | No field-level rules; `Temp.md` is a placeholder only |
| **Screen requirement set (17 files)** | Field-level specification with 59 legacy business rules, workflows and examples | Detailed CRUD behaviour, uniqueness, deletion guards, lifecycle intent | Some rules contradict the DDL; several “must” statements are not implemented |
| **DDL v1.1 + module code** | 23 tables and a working computation pipeline | Masters, template configuration, normalized computation, lifecycle endpoints, exports, print bridge | Lifecycle can be bypassed; locks are advisory; recompute is destructive; ranking, promotion and result status are incomplete |

### 1.3 What this document decides

1. **One module, three capability layers.** Core configuration, Standard computation/publication, Advanced analytics. Only Core and Standard are in build scope.
2. **The DDL is the schema authority.** Where the code and DDL disagree (for example `grading_schema_id` nullability), the DDL wins and the code is a defect.
3. **The schedule is the unit of computation, review, publication and audit.** A result without a schedule is not a valid marksheet.
4. **Computation is deterministic and reproducible.** Given the same template, source data and schedule, a recompute must produce the same result. Destructive wiping is acceptable only inside a controlled recompute that preserves manual inputs.
5. **Publication freezes the recipe, not just the output.** Publishing must lock the config template; the lock must actually be enforced on every write path.
6. **A result is withheld per student, not per schedule.** Withholding must be reversible only through an explicit declare action with an audit trail.
7. **Marks are normalized points.** Raw school marks are evidence; the stored result is a weighted, normalized calculation. Any UI that shows “out of 100” must say so.
8. **No silent inference.** Promotion, “last result of session”, and grade schema selection must be explicit or configurable, not guessed from a type code.
9. **Every lifecycle action is logged.** Compute, review, publish, lock, unlock, withhold and declare each produce an immutable `msh_computation_logs` row.
10. **Unresolved product questions are listed, not guessed.** Section 16 is part of the deliverable.

### 1.4 Readiness statement

As of the 2026-11-03 source review:

- **Core configuration is usable.** All masters, templates, components, class assignments and practical configurations have working CRUD, uniqueness validation and soft-delete/restore.
- **Computation is functionally real but not production-safe.** The pipeline reads exams, homework, quizzes, quests, IA, behaviour and attendance; it computes normalized subject and overall results, grades, divisions and section ranks. However:
  - recompute hard-deletes co-scholastic grades before recreating blank rows;
  - a partial class-section failure leaves some results written while the schedule keeps its previous status;
  - `rank_in_class` is always `0`;
  - `result_status` is never set on publish;
  - the IA source is not seeded, so IA marks do not affect subject totals by default.
- **Lifecycle is partially enforced.** Review, publish, lock and unlock exist and are permission-gated, but schedule create/edit can set any status directly; unlock does not validate the current state; and template locks are not checked by any configuration write path.
- **Results and print are usable with caveats.** Student and subject results, IA marks, co-scholastic grades and attendance have screens. Excel export works. Print resolves a class-specific `MARKSHEET` template and falls back to the type default. PDF is not server-rendered; the documented browser-side path is partly disabled.
- **Data protection is weak.** Withhold/declare does not record who or when, despite the requirement; deletion guards described in the screen requirements are largely absent; computation logs document a status/action vocabulary the code does not use.

The remediation sequence is suggested in Section 15.

---

## 2. Scope

### 2.1 In scope

| Area | Core | Standard | Advanced | As-built status |
|---|:---:|:---:|:---:|---|
| Marksheet type master | ● | ○ | ○ | Implemented |
| IA component type master | ● | ○ | ○ | Implemented |
| Source component lookup (Exam, Homework, Quiz, Quest) | ● | ○ | ○ | Implemented, IA source missing |
| Marksheet-specific class groups and membership | ● | ○ | ○ | Implemented |
| Exam groups and exam-type membership | ● | ○ | ○ | Implemented |
| Academic session binding | ● | ○ | ○ | Implemented |
| Config template master (code, type, exam group, grading schema, pass rules, Best-of-N) | ● | ○ | ○ | Implemented, nullability conflict |
| Class / class-group assignment to template | ● | ○ | ○ | Implemented, unused by compute |
| Subject practical configuration (theory/practical split) | ● | ○ | ○ | Implemented |
| Scholastic source weightages |  | ● | ○ | Implemented, non-incremental save |
| Exam-type weightages |  | ● | ○ | Implemented |
| Template IA components |  | ● | ○ | Implemented |
| Template co-scholastic components |  | ● | ○ | Implemented |
| Marksheet schedule master and class-section mapping |  | ● | ○ | Implemented |
| Precheck |  | ● | ○ | Implemented, advisory only |
| Background computation job |  | ● | ○ | Implemented |
| Exam / Homework / Quiz / Quest ingestion |  | ● | ○ | Implemented |
| IA, co-scholastic and attendance capture |  | ● | ○ | Implemented |
| Behavioural-assessment auto-grade |  | ● | ○ | Implemented behind BA flag |
| Theory/practical split |  | ● | ○ | Implemented as proportional allocation |
| Subject and overall computation |  | ● | ○ | Implemented |
| Grade, division and pass/fail |  | ● | ○ | Implemented, grading schema unused |
| Rank |  | ● | ○ | Partial (section only) |
| Promotion |  | ● | ○ | Implemented via type-code inference |
| Review / publish / lock / unlock |  | ● | ○ | Implemented with gaps |
| Withhold / declare |  | ● | ○ | Implemented with gaps |
| Student, subject, IA and co-scholastic result screens |  | ● | ○ | Implemented |
| Computation log |  | ● | ○ | Implemented, vocabulary mismatch |
| Excel export |  | ● | ○ | Implemented |
| HTML print |  | ● | ○ | Implemented |
| Browser PDF |  | ● | ○ | Partial / disabled button |
| Dashboard and four-pillar navigation |  | ● | ○ | Implemented |
| Parent/student portal |  |  | ● | Out of scope |
| Longitudinal analytics and progress tracking |  |  | ● | Out of scope |
| AI anomaly detection / mark moderation |  |  | ● | Out of scope |
| Board-format report packs |  |  | ● | Out of scope |
| Scheduled auto-publish |  |  | ● | Out of scope |

● = owned · ○ = consumed read-only

### 2.2 Out of scope

1. **Exam conduct and paper marking** — `LmsExam` owns exams, papers and raw results. MSG reads published results only.
2. **Homework, quiz and quest authoring and grading** — `LmsHomework`, `LmsQuiz` and `LmsQuests` own those records. MSG reads graded/published totals only.
3. **Behavioural assessment scoring** — `BehaviouralAssessment` owns categories, periods and computed overall grades. MSG consumes the overall grade and an optional integration weightage.
4. **Attendance capture at period level** — the attendance module owns daily records; MSG reads a summary and also stores a manual summary row.
5. **Timetable and class-subject mapping** — `TimetableFoundation` owns `tt_class_requirement_groups`; MSG reads the subject list.
6. **Student, class, section, subject and session masters** — owned by `StudentProfile`, `SchoolSetup` and `GlobalMaster`.
7. **Template design and rendering** — the `Template` module owns layouts, purposes and assignments. MSG supplies context and data.
8. **Parent/student delivery** — portal visibility, push and email are not in this module.
9. **Board affiliation compliance** — the school configures its own grading schema and pass rules; MSG does not certify a board format.
10. **Fee clearance** — withholding is a manual administrative action; MSG does not read the fee ledger.

### 2.3 Assumptions

- MySQL 8.0.32+ (CHECK constraints, generated columns, window functions where later needed).
- One tenant database per school; MSG tables carry no `tenant_id`, by design (`D-MSG-001`).
- `sch_*`, `std_*`, `sys_*`, `lms_*`, `slb_*`, `tt_*` and `ba_*` tables already exist in the tenant.
- The school has at least one current `sch_org_academic_sessions_jnt` row and one `glb_academic_sessions` row linked to it.
- A class section is identified by `sch_class_section_jnt.id`; a class is `sch_classes.id`; a subject is `sch_subjects.id`.
- Published exam results are the only exam evidence; draft or unpublished exam rows are ignored.
- The Template module exposes `Template::for($model, 'MARKSHEET', $overrides, $templateId)` and a `MARKSHEET_PRINT` purpose.
- Queue workers are available in production; `sync` is acceptable for local development.
- The school accepts that normalized percentages, not raw paper marks, are the stored result basis.

### 2.4 Dependencies

| Dependency | Owner | Used by | Direction |
|---|---|---|---|
| `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_subjects` | SchoolSetup | Template class assignment, schedule classes, subject enumeration, practical config | Read |
| `sch_org_academic_sessions_jnt`, `glb_academic_sessions` | SchoolSetup / GlobalMaster | Session binding; org-session → global-session resolution | Read |
| `std_students`, `std_student_academic_sessions`, `std_student_subject_enrolments` | StudentProfile | Student enumeration and elective filtering | Read |
| `sys_users`, `sys_dropdown_table`, `sys_activity_logs` | Core | Audit, schedule statuses, permissions | Read/write (activity log) |
| `slb_grade_division_master` | Syllabus | Grade and division bands | Read |
| `lms_exam_types`, `lms_exams`, `lms_exam_papers`, `lms_exam_results` | LmsExam | Exam evidence and exam-type weightage | Read |
| `lms_homework`, `lms_homework_submissions` | LmsHomework | Homework evidence | Read |
| `lms_quizzes`, `lms_quests`, `lms_quiz_quest_results` | LmsQuiz / LmsQuests | Quiz and quest evidence | Read |
| `tt_class_requirement_groups` | TimetableFoundation | Subject list per class | Read |
| `ba_config`, `ba_computed_overall` | BehaviouralAssessment | Co-scholastic auto-grade and optional integration weight | Read |
| `std_student_attendance` | Attendance | Attendance summary | Read |
| `Template` module | Template | Print layout and variable binding | Call |
| `Maatwebsite\Excel` | Vendor | Schedule and result export | Call |
| Queue + scheduler | Infrastructure | Background compute, future auto-publish | Call |

**Write ownership:** MSG writes only `msh_*` tables. It never updates an `lms_*`, `ba_*`, `tt_*`, `std_*` or `sch_*` row. The one exception in code is reading and re-writing its own `msh_student_attendance` summary.

---

## 3. Actors and access

### 3.1 Actor definitions

| Actor | Who | Relationship to Marksheet Generation |
|---|---|---|
| School Admin | System administrator | Full configuration, all schedules, can unlock and override; manages permissions |
| Principal / Approver | Senior school authority | Reviews and publishes results; may unlock with a reason |
| Examination Coordinator | Academic operations lead | Primary daily user: templates, components, schedules, compute, review, publish, print |
| Class Teacher | Subject or homeroom teacher | Enters IA and co-scholastic grades; views own class results |
| Subject Teacher | Teaches one subject | Views subject results and may enter IA marks for that subject |
| Accountant / Front Office | Administrative staff | Withholds results for fee/library clearance; prints duplicates |
| Data Entry Operator | Clerical staff | Enters marks and attendance; no publish rights |
| Auditor / Board | Internal or external reviewer | Read-only access to results, computation logs and lifecycle history |
| Parent / Guardian | Fee payer and guardian | Advanced layer only: own child’s published result |
| Student | Learner | Advanced layer only: own published result |
| System | Queue worker, scheduler, engine | Computes, logs, and (future) auto-publishes |

### 3.2 Role-feature matrix

| Feature | Admin | Principal | Exam Coord. | Class Teacher | Subject Teacher | Front Office | Auditor | Parent/Student |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Dashboard | Full | Full | Full | Class | Subject | View | View | None |
| Marksheet types | Full | View | Full | None | None | None | View | None |
| IA component types | Full | View | Full | None | None | None | View | None |
| Class groups | Full | View | Full | None | None | None | View | None |
| Exam groups | Full | View | Full | None | None | None | View | None |
| Config templates | Full | View | Full | None | None | None | View | None |
| Scholastic / exam weightages | Full | View | Full | None | None | None | View | None |
| Template IA components | Full | View | Full | View | View | None | View | None |
| Template co-scholastic components | Full | View | Full | View | None | None | View | None |
| Practical configs | Full | View | Full | None | None | None | View | None |
| Schedule create/edit | Full | View | Full | None | None | None | View | None |
| Precheck | Full | View | Full | None | None | None | View | None |
| Compute | Full | No | Full | No | No | No | No | No |
| Review | Full | Full | Full | No | No | No | No | No |
| Publish | Full | Full | Optional* | No | No | No | No | No |
| Lock | Full | Full | Full | No | No | No | No | No |
| Unlock | Full | Full | No* | No | No | No | No | No |
| Student results | Full | View | Full | Class | Subject | View | View | Published only |
| IA marks entry | Full | View | Full | Class | Subject | None | View | None |
| Co-scholastic entry | Full | View | Full | Class | None | None | View | None |
| Attendance entry | Full | View | Full | Class | None | Full | View | None |
| Withhold | Full | Full | Full | No | No | Full | No | No |
| Declare | Full | Full | Full | No | No | No | No | No |
| Print / export | Full | Full | Full | Class | Subject | Full | View | Published only |
| Computation logs | Full | Full | Full | No | No | No | Full | None |

*The screen requirements describe a school-configurable approval chain. The current build has one permission set and no chain; the “Optional/No” cells are target-state policy, not enforced behaviour. See OD-05.

### 3.3 Permission catalogue (as-built)

The permission list declares CRUD plus lifecycle actions for each entity. The module authorises with `tenant.marksheet-generation.<entity>.<action>`.

| Permission group | Actions declared |
|---|---|
| `msh-dashboard` | viewAny, view, create, update, delete |
| `msh-configuration` | viewAny, view, create, update, delete |
| `msh-components` | viewAny, view, create, update, delete |
| `msh-scheduling` | viewAny, view, create, update, delete |
| `msh-results` | viewAny, view, create, update, delete |
| `msh-marksheet-type` | viewAny, view, create, update, delete |
| `msh-ia-component-type` | viewAny, view, create, update, delete |
| `msh-config-template` | viewAny, view, create, update, delete |
| `msh-class-group` | viewAny, view, create, update, delete |
| `msh-exam-group` | viewAny, view, create, update, delete |
| `msh-template-scholastic-component` | viewAny, view, create, update, delete |
| `msh-template-exam-weightage` | viewAny, view, create, update, delete |
| `msh-template-ia-component` | viewAny, view, create, update, delete |
| `msh-template-coscholastic-component` | viewAny, view, create, update, delete |
| `msh-class-config` | viewAny, view, create, update, delete |
| `msh-subject-practical-config` | viewAny, view, create, update, delete |
| `msh-marksheet-schedule` | viewAny, view, create, update, delete, review, lock, unlock, publish, export |
| `msh-schedule-class` | viewAny, view, create, update, delete |
| `msh-student-result` | viewAny, view, create, update, delete, export, print, withhold, declare |
| `msh-student-subject-result` | viewAny, view, create, update, delete |
| `msh-student-ia-mark` | viewAny, view, create, update, delete |
| `msh-student-coscholastic-result` | viewAny, view, create, update, delete |
| `msh-student-attendance` | viewAny, view, create, update, delete |
| `msh-student-subject-exam-mark` | viewAny, view, create, update, delete |
| `msh-computation-log` | viewAny, view, create, update, delete |

**Gap:** combined pages and some controllers authorise `.view`, while the corresponding index actions and policies authorise `.viewAny`. A user granted only `viewAny` can receive 403 on the combined page, and a user granted only `view` can receive 403 on a resource index. The permission catalogue must define one convention (see CF-35 and OD-16).

---

## 4. Domain model and terminology

### 4.1 Core concepts

| Term | Meaning |
|---|---|
| **Marksheet type** | A category of output — Unit Test, Term-1 Report Card, Annual Report Card. Governs which templates can be created and how the result is treated (including the current promotion inference). |
| **Source component** | A fixed assessment source that can contribute to a subject total: `EXAM`, `HOMEWORK`, `QUIZ`, `QUEST`. `EXAM` is mandatory; the schema permits an `IA` code but the seeder does not create one. |
| **IA component type** | A reusable internal-assessment category — Notebook, Subject Enrichment, Periodic Assessment, Participation. |
| **Class group** | A marksheet-specific band of classes (Primary, Middle, Secondary). It is deliberately separate from timetable class groups. |
| **Exam group** | A named bundle of exam types with an optional date window (Term-1 = UT1 + UT2 + Half-Yearly). |
| **Config template** | The grading recipe: session, marksheet type, exam group, grading schema, pass percentage, compartment limit, Best-of-N setting, lock flag, and all component mappings. |
| **Template scholastic component** | The weight of one source component (`EXAM`, `HOMEWORK`, …) in the subject total. Active weights must close to 100%. |
| **Template exam weightage** | The weight of one exam type inside the `EXAM` source. Active weights must close to 100%. |
| **Template IA component** | An IA category attached to a template with a maximum mark and display order. |
| **Template co-scholastic component** | A non-academic area attached to a template, with a grading scale and an optional behavioural-assessment link. |
| **Class config assignment** | A row linking a template to a class (direct) or a class group (inherited). The DDL states direct assignment overrides group assignment. |
| **Subject practical config** | The theory/practical maximum split for one class + subject + session. |
| **Schedule** | The computation event: one template, one session, a set of class sections, a date, and a lifecycle status. The unit of compute, review, publish, lock and audit. |
| **Schedule class** | The junction row that includes one class section in a schedule. |
| **Student result** | One row per student per schedule: grand total, percentage, overall grade, division, rank, subject counts, promotion and result status. |
| **Student subject result** | One row per student × subject per schedule: weighted exam total, theory, practical, homework, quiz, quest, IA total, subject total/max/percentage/grade/pass. |
| **Exam mark line item** | One row per student × subject × exam type per schedule: raw marks, max marks, result status and source `lms_exam_results.id`. |
| **IA mark** | One row per student × subject × template IA component per schedule, with marks obtained, max marks and who entered it. |
| **Co-scholastic result** | One row per student × co-scholastic component per schedule, with grade, remarks and an auto-vs-manual flag. |
| **Attendance summary** | One row per student per schedule with working days and days present. |
| **Computation log** | An immutable record of a compute, review, publish, lock, unlock, withhold or declare action. |
| **Normalized point** | A 0–100 percentage produced from raw marks, used for weighting. |
| **Result status** | Per-student `DECLARED` or `WITHHELD`. Independent of schedule lifecycle status. |
| **Lifecycle status** | The schedule state machine: `DRAFT`, `COMPUTED`, `REVIEWED`, `PUBLISHED`, `LOCKED`. |

### 4.2 Lifecycle (canonical)

```
                         ┌──────────────┐
                         │    DRAFT     │  editable; no results yet (or stale)
                         └──────┬───────┘
                    compute     │
                         ┌──────▼───────┐
                         │   COMPUTED   │  results written; editable via recompute
                         └──────┬───────┘
                    review      │
                         ┌──────▼───────┐
                         │   REVIEWED   │  marks frozen for teachers
                         └──────┬───────┘
                    publish     │            template becomes locked
                         ┌──────▼───────┐
                         │  PUBLISHED   │  visible to consumers
                         └──────┬───────┘
                    lock        │
                         ┌──────▼───────┐
                         │    LOCKED    │  schedule immutable
                         └──────┬───────┘
                    unlock      │  (reason ≥ 5 chars)
                         ┌──────▼───────┐
                         │   COMPUTED   │  re-open for correction
                         └──────────────┘
```

| Status | Compute allowed? | Editable? | Visible to consumers? | Meaning |
|---|:---:|:---:|:---:|---|
| DRAFT | Yes | Yes | No | Schedule created; template may still be incomplete |
| COMPUTED | Yes | Yes | No | Results exist; recompute permitted |
| REVIEWED | No | Marks frozen | No | Coordinator has accepted the run |
| PUBLISHED | No | No | Yes | Results released; template locked |
| LOCKED | No | No | Yes | Final; only an explicit unlock re-opens |

**Canonical rules (intent):**
- Status changes only through lifecycle actions, never through create/edit forms.
- Compute requires `DRAFT` or `COMPUTED` and an unlocked schedule.
- Review requires `COMPUTED`.
- Publish requires `REVIEWED`; publish locks the template.
- Lock requires `PUBLISHED`.
- Unlock requires `PUBLISHED` or `LOCKED`, a reason of at least 5 characters, and resets to `COMPUTED`.
- Only one computation may run per schedule at a time.
- A schedule with published or locked state or computed results cannot be deleted.

### 4.3 Computation pipeline (canonical)

```
Schedule + Config Template
        │
        ├── validate scholastic weights == 100
        ├── validate exam weights == 100
        ├── resolve org session → global session
        ├── load active schedule classes
        │
        └── for each class-section (own transaction):
              ├── resolve class_id
              ├── load exam-group date window
              ├── enumerate current students in session
              ├── enumerate subjects from timetable requirement groups
              ├── optional: filter by student subject enrolments
              │
              ├── for each subject:
              │     ├── read EXAM per exam type (published only)
              │     ├── read HOMEWORK (gradable, graded)
              │     ├── read QUIZ (published)
              │     ├── read QUEST (published)
              │     ├── read BEHAVIOUR (flag-gated)
              │     ├── load IA marks for schedule + subject
              │     ├── load practical config for class + subject
              │     │
              │     └── for each student:
              │           ├── combine exam types (weighted or Best-of-N)
              │           ├── split theory/practical proportionally
              │           ├── normalize IA to percentage
              │           ├── apply source weights → subject total/max
              │           ├── resolve subject grade and pass
              │           ├── persist subject result
              │           └── persist exam-type line items
              │
              ├── upsert co-scholastic rows (BA auto-grade when linked)
              ├── upsert attendance summary from attendance module
              ├── per student: sum subjects → grand total/max/percentage
              │                 resolve overall grade + division
              │                 derive promotion when final
              │                 persist student result
              └── assign dense section ranks
        │
        └── write computation log; update last_computed_at, total_students;
            set status COMPUTED only when no class-section errors
```

### 4.4 Data ownership

| Prefix | Owner | Contains |
|---|---|---|
| `msh_*` | Marksheet Generation | All masters, configuration, schedules, computed results, marks, attendance summaries, audit logs |
| `sch_*` | SchoolSetup | Classes, sections, class-section junctions, subjects, organization academic sessions |
| `std_*` | StudentProfile | Students, session enrolment, optional subject enrolment |
| `lms_*` | LmsExam / LmsHomework / LmsQuiz / LmsQuests | Raw assessment evidence |
| `slb_*` | Syllabus | Grade and division master |
| `tt_*` | TimetableFoundation | Class requirement groups (subject list) |
| `ba_*` | BehaviouralAssessment | Behaviour configuration and computed overall grades |
| `sys_*` | Core | Users, dropdowns, activity logs, permissions |

**Why MSG owns its results rather than computing on read:** a report card must be reproducible after source data changes. Storing the computed subject and overall results, plus the raw exam line items and the computation log, is what makes a published marksheet defensible. The trade-off is that recompute is a write operation and must be treated as such.

---

## 5. Functional requirements

Each requirement states intent, rules and acceptance. An **Implementation note** records the as-built reality without weakening the requirement. Requirement status uses the vocabulary in Section 0.2.

### 5.1 Foundation requirements

#### FND-MSG-001 — Marksheet type master
**Priority:** P0 · **Tier:** Core · **Status:** Implemented

The school defines the categories of marksheet it issues. A marksheet type is the top-level classification under which config templates are created. It carries a globally unique code, a display name, an optional description, a positive display order and an active flag.

**Rules**
- `code` is globally unique across all marksheet types, including soft-deleted rows that have not been purged (BR-MSG-C01).
- `name` is required and limited to 100 characters.
- `display_order` is a positive integer and controls dropdown order.
- Inactive types are hidden from template setup but remain readable on historical templates (BR-MSG-C03).
- A type referenced by any config template cannot be permanently deleted (BR-MSG-C02).
- Delete is a soft delete; restore returns the type to active availability.

**Acceptance**
1. Create `TERM1` / “Term-1 Report Card” with order 1; it appears first in the template type dropdown.
2. Attempt a second `TERM1`; the save is blocked with a field-level uniqueness message.
3. Create a template under `TERM1`, then attempt force-delete; the deletion is blocked and the referencing template is named.
4. Deactivate `TERM1`; it disappears from the template create dropdown but remains visible on the existing template.
5. Restore a soft-deleted type; it becomes selectable again without recreating its templates.

**Implementation note:** CRUD, soft delete, restore, toggle and force-delete exist. Force-delete catches the SQL integrity exception and returns a friendly message, but the pre-check does not name the referencing templates. The unique index includes soft-deleted rows, so recreating a deleted code can fail until the row is purged.

---

#### FND-MSG-002 — IA component type master
**Priority:** P0 · **Tier:** Core · **Status:** Implemented

The school maintains a reusable library of internal-assessment categories. Types are defined once and attached to templates with a per-template maximum mark.

**Rules**
- `code` is globally unique (BR-MSG-C04).
- `name`, optional description and positive `display_order` are required/validated as for marksheet types.
- A type referenced by any template IA component cannot be permanently deleted (BR-MSG-C05).
- Only active types appear in template component dropdowns (BR-MSG-C06).
- Delete is soft; restore reactivates.

**Acceptance**
1. Create `NOTEBOOK`, `SUB_ENRICHMENT`, `PERIODIC_ASSESS`, `PARTICIPATION` with sequential display order.
2. Attach `NOTEBOOK` to a template with max 5; it appears in teacher IA entry for that template.
3. Attempt to delete `NOTEBOOK` while attached; blocked.
4. Deactivate `PARTICIPATION`; it disappears from new component dropdowns but existing marks remain readable.

**Implementation note:** Implemented. The seeder creates exactly these four types. The template component service does not check whether the type is active at save time; the request validates existence only. Inactive types can therefore be attached by a direct request.

---

#### FND-MSG-003 — Source component lookup
**Priority:** P0 · **Tier:** Core · **Status:** Implemented, seed gap

Source components are the fixed vocabulary of assessment sources that can contribute to a subject total. The DDL documents `EXAM`, `HOMEWORK`, `QUIZ`, `QUEST` and permits other codes such as `UT1`, `UT2`, `HY`; the seeder creates only the first four.

**Rules**
- `code` is globally unique.
- `EXAM` is mandatory in every template (`is_mandatory = 1`).
- The lookup is seeded at tenant onboarding and is not ordinary school-editable master data.
- A source component referenced by a template cannot be deleted.
- Computation recognises a source by its **code**, not its id: `EXAM`, `HOMEWORK`, `QUIZ`, `QUEST`, `IA`.

**Acceptance**
1. A new tenant has exactly four source rows: `EXAM`, `HOMEWORK`, `QUIZ`, `QUEST`.
2. The template component dropdown shows all active sources; `EXAM` is marked mandatory.
3. A template cannot be considered computation-ready without an `EXAM` component that closes the source weightage to 100.

**Implementation note:** Seeded exactly as above. **There is no `IA` source row.** The computation engine builds an `IA` percentage and passes it to the weightage applier, but `applySourceWeightages()` iterates only over rows present in `msh_template_scholastic_components`. Because no template can reference a non-existent `IA` source, IA marks are computed and stored in `ia_total` but are **excluded from `subject_total`** unless an `IA` row is inserted manually and mapped to the template. This is a P0 conflict (CF-14). In addition, the `is_mandatory = 1` flag on `EXAM` is documentation only: neither template readiness nor compute checks that an `EXAM` component exists, so a template weighted 100% on Homework passes validation (CF-56).

---

#### FND-MSG-004 — Marksheet class group master and membership
**Priority:** P1 · **Tier:** Core · **Status:** Implemented

A marksheet class group is a logical band of classes that share grading rules. It exists so that a template can target “Primary (1–5)” instead of five separate class rows. It is deliberately separate from timetable class groups.

**Rules**
- `code` is globally unique (BR-MSG-C07).
- `display_order` is positive; default is next available.
- Membership is stored in `msh_class_group_items_jnt`; a class appears at most once per group.
- Saving synchronises membership: newly selected classes are linked, removed classes are unlinked, re-selected classes are restored (BR-MSG-C08).
- A group referenced by an active template assignment cannot be permanently deleted (BR-MSG-C09).
- Only active groups appear in template assignment dropdowns (BR-MSG-C10).
- Group membership does not itself assign a template; assignment is FND-MSG-007.

**Acceptance**
1. Create `PRIM` with classes 1–5 and order 1.
2. Add class 6; membership count increases and the junction row is created.
3. Remove class 3; the junction row is soft-deleted, not destroyed.
4. Re-add class 3; the same row is restored.
5. Assign `PRIM` to a template, then attempt force-delete; blocked with a message naming the assignment.
6. Deactivate `PRIM`; it disappears from template assignment options; existing assignments remain readable.

**Implementation note:** Implemented, including restore-on-reselect. The delete guard exists only as a foreign-key catch, not a service-level pre-check. `syncItems()` soft-deletes rows not in the selection; when the selection is empty it soft-deletes all rows, which is correct but worth testing.

---

#### FND-MSG-005 — Exam group master and membership
**Priority:** P0 · **Tier:** Core · **Status:** Implemented

An exam group bundles exam types into a logical term and optionally defines the term’s date window. Templates reference an exam group to know which exam types can be weighted and which date window scopes homework, quiz and quest evidence.

**Rules**
- `code` is unique within an academic session (BR-MSG-C11).
- `start_date` and `end_date` are optional; when both are present, `end_date >= start_date` (BR-MSG-C13).
- Membership is stored in `msh_exam_group_items_jnt` with a display order; an exam type appears at most once per group.
- Saving synchronises membership (BR-MSG-C12).
- A group referenced by an active template cannot be permanently deleted (BR-MSG-C14).
- The date window is advisory: it scopes HW/Quiz/Quest reads in computation, but it does not currently scope exams or attendance.

**Acceptance**
1. Create `T1_EXAMS` for session 2026-27 with 1 April–30 September 2026 and exam types PT1, PT2, Half-Yearly.
2. Attempt the same code in the same session; blocked.
3. Use the same code in 2027-28; allowed.
4. Set an end date before the start date; blocked with a field-level message.
5. Attach the group to a template; the template’s exam-weightage dropdown offers exactly the group’s exam types.
6. Attempt to delete the group while the template references it; blocked.

**Implementation note:** Implemented. The template edit form’s exam-weightage dropdown is sourced from active `lms_exam_types`, not from the selected exam group’s membership, so a user can weight an exam type that is not in the group. Computation then reads that exam type regardless of membership. This weakens the meaning of “exam group” (CF-33b).

---

#### FND-MSG-006 — Config template master
**Priority:** P0 · **Tier:** Core · **Status:** Implemented, schema conflict

The config template is the grading recipe. It binds one academic session, one marksheet type and one exam group, and carries the grading schema, passing percentage, compartment limit and Best-of-N settings.

**Rules**
- `code` is unique within the academic session (BR-MSG-C15).
- `academic_session_id`, `marksheet_type_id` and `exam_group_id` are required and must exist (BR-MSG-C16).
- `grading_schema_id` identifies the grade/division band set. The DDL declares it `NOT NULL`; the request currently allows `null` (CF-11).
- `passing_percentage` is 0–100, default 33.00.
- `compartment_max_failures` is 0–255, default 2.
- `is_best_of_n_enabled` requires a `best_of_n_count` of at least 1 when enabled.
- `is_locked` is system-controlled. It becomes 1 when a schedule using the template is published. A locked template is immutable (BR-MSG-C19).
- Template delete is soft; a template with schedules or configured components cannot be permanently deleted (BR-MSG-C18).
- `board_code` is informational and is used as a grade-band scope hint.

**Acceptance**
1. Create `CBSE_SEC_2026` for 2026-27, type Term Report Card, exam group Term-1, pass 33.00, compartment 2.
2. Create the same code in the same session; blocked. Reuse in another session; allowed.
3. Set pass 120; blocked by range validation.
4. Enable Best-of-N without a count; blocked.
5. Publish a schedule that uses the template; `is_locked` becomes 1 and every subsequent edit/delete is rejected.
6. Attempt to force-delete a template with a schedule; blocked.

**Implementation note:** Create/edit/soft-delete/restore/toggle exist. The lock flag is written by publish but **no configuration write path checks it**, so a locked template remains fully editable. The request accepts `is_locked` from the payload, so a client can unlock a template directly. `grading_schema_id` is nullable in the request and in the model despite the DDL’s `NOT NULL`.

---

#### FND-MSG-007 — Class and class-group assignment to template
**Priority:** P1 · **Tier:** Core · **Status:** Implemented, unused

A template is assigned to classes or class groups through `msh_class_config_jnt`. Each row targets exactly one of `class_id` or `class_group_id`.

**Rules**
- The CHECK constraint allows exactly one target per row.
- Direct class assignment takes precedence over group inheritance (DDL comment, BR-MSG-C31).
- Saving a template synchronises assignments; removed rows are soft-deleted and re-selected rows restored (BR-MSG-C17).
- A class or group may be assigned to more than one template; the resolution rule must define which wins. The current code returns the first matching row without an explicit priority.
- Assignment is metadata for downstream resolution; it does not by itself create a schedule.

**Acceptance**
1. Assign a template to class 6 directly and to group “Secondary” by inheritance.
2. A resolution request for class 6 returns the direct template.
3. Remove the direct assignment; resolution falls back to the group template.
4. Re-add the direct assignment; the soft-deleted row is restored, not duplicated.
5. A class with two direct template assignments produces a deterministic, documented winner (or a validation error).

**Implementation note:** `MarksheetConfigService::resolveTemplateForClass()` implements direct-first, group-fallback. **The computation engine never calls it.** A schedule names its template explicitly, and computation uses that template for all schedule classes. Class assignments are therefore decorative for computation and can disagree with the schedule. The “first match wins” behaviour for duplicate assignments is undefined at the database level (no uniqueness constraint) — CF-33.

---

#### FND-MSG-008 — Subject practical configuration
**Priority:** P0 · **Tier:** Core · **Status:** Implemented

The school declares, per academic session + class + subject, whether the subject has a practical component and how the maximum marks split between theory and practical.

**Rules**
- The triplet `(academic_session_id, class_id, subject_id)` is unique (BR-MSG-C20).
- `theory_max_marks` and `practical_max_marks` are each ≥ 0.
- `has_practical = 0` means the subject is treated as 100% theory; practical maximum should be 0.
- Only active configurations are used in computation (BR-MSG-C21).
- A configuration referenced by computed results cannot be permanently deleted (BR-MSG-C22).
- Delete is soft; restore reactivates (BR-MSG-C23).

**Acceptance**
1. Configure Physics for Grade 11, 2026-27, theory 70 / practical 30.
2. Configure Mathematics, no practical, theory 100 / practical 0.
3. Attempt a duplicate triplet; blocked.
4. Deactivate Physics; recompute treats it as 100% theory.
5. Attempt to force-delete a configuration used by results; blocked.

**Implementation note:** CRUD and uniqueness are implemented. The delete guard does **not** check computed results; it relies on foreign keys, and no MSH result table references `msh_subject_practical_configs.id`. A configuration can therefore be deleted after results exist, leaving historical results with no provenance. See CF-29.

---

#### FND-MSG-009 — Academic session binding and org-session resolution
**Priority:** P0 · **Tier:** Core · **Status:** Implemented, inconsistent

Every template, schedule, exam group and practical configuration binds to an **organization academic session** (`sch_org_academic_sessions_jnt.id`). Student enrolment and LMS evidence bind to a **global academic session** (`glb_academic_sessions.id`). The two are related by `sch_org_academic_sessions_jnt.academic_session_id`.

**Rules**
- All MSH configuration and schedule rows use the organization session id.
- All student, exam, homework, quiz, quest and attendance reads use the global session id.
- The mapping must be resolved once per computation run and used consistently.
- A schedule whose org session has no global mapping is invalid.
- Precheck and computation must use the same resolution.

**Acceptance**
1. A schedule created for 2026-27 resolves to the matching global session.
2. Computation enumerates exactly the students whose `std_student_academic_sessions.academic_session_id` equals that global id.
3. If the global mapping is missing, compute fails before writing any result.
4. Precheck reports the same student count that compute will process.

**Implementation note:** Computation resolves the mapping correctly. **Precheck does not**: it queries `StudentAcademicSession` with the organization session id, so its student counts can be zero or wrong. Precheck is advisory and does not block compute, which hides the defect. CF-30.

---

#### FND-MSG-010 — Navigation, dashboard and permission surface
**Priority:** P1 · **Tier:** Core · **Status:** Implemented, inconsistent

The module presents a dashboard and four combined hubs: Configuration, Components, Scheduling and Results. Each hub uses a tab query parameter to select its active tab and paginates each tab independently.

**Rules**
- Dashboard is the module landing page.
- Configuration tabs: Marksheet Types, Exam Groups, Class Groups, IA Component Types, Config Templates.
- Components tabs: Scholastic Components, Exam Weightages, IA Components, Co-scholastic Components.
- Scheduling tabs: Practical Configs, Schedules, Schedule Classes.
- Results tabs: Student Results, Subject Results, IA Marks, Co-scholastic Results.
- Each tab has its own page-name parameter so pagination in one tab does not reset another.
- Every page and action is permission-gated.
- Cross-tab filters must not leak; result tabs use tab-prefixed query parameters.

**Acceptance**
1. `/dashboard` shows live counts and the five most recent schedules and results.
2. `/configuration?tab=exam-groups` opens the Exam Groups tab and paginates with `eg_page`.
3. Switching to `/components?tab=ia-components` preserves the correct paginator.
4. A user without `msh-results.view` cannot open the Results hub.
5. Filtering Student Results by class section does not change the Subject Results tab’s filter.

**Implementation note:** Implemented. Combined pages authorise `.view` while resource index actions authorise `.viewAny` (CF-35). The dashboard counts include soft-deleted rows because several models’ `count()` calls do not exclude trashed records; this can overstate “active” metrics.

---

### 5.2 Configuration requirements

#### STD-MSG-001 — Scholastic source component weightage
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented, non-incremental

For each template, the school maps source components (`EXAM`, `HOMEWORK`, `QUIZ`, `QUEST`) to a weightage percentage and optional maximum marks. These weights determine how the normalized source percentages combine into the subject total.

**Rules**
- A source component can appear at most once per template (BR-MSG-C24).
- `weightage_percent` is 0–100 with at most two decimals.
- `max_marks` is optional and ≥ 0; it is display/format metadata only — it does not cap the computed percentage in the current engine.
- The sum of **active** weights must equal 100% within a 0.01 tolerance (BR-MSG-C28).
- Inactive components are excluded from both numerator and denominator.
- A null source score is excluded from both numerator and denominator, so a missing source does not depress the result; the subject maximum shrinks accordingly (BR-MSG-R19).
- Deleting a component used by computed results is blocked (BR-MSG-C26); delete is soft (BR-MSG-C27).
- Setup must be possible incrementally: adding the first component must not fail merely because the total is not yet 100.

**Acceptance**
1. Map Exam 80, Homework 10, Quiz 10; the template becomes computation-ready.
2. Attempt a second Exam row; blocked by uniqueness.
3. Attempt Exam 80 + Homework 30; the save is rejected because the active total would be 110.
4. Add Exam 100 first, then change it to 80 and add Homework 20; both saves succeed.
5. Deactivate Homework; the active total becomes 90 and compute fails validation with a clear message.
6. Delete all components; compute fails rather than silently producing zero.

**Implementation note:** Implemented with a critical usability defect. `TemplateScholasticComponentService::create()` inserts the row and **then** validates the sum inside the same transaction. Adding the first component of a new template always fails unless the single weight is exactly 100. The user cannot build 80/10/10 incrementally. The seeder bypasses the service and inserts directly, which is why seeded templates work. The same post-save validation applies to updates, so changing one of three rows also fails until the others are changed — which cannot happen atomically. CF-13.

---

#### STD-MSG-002 — Exam-type weightage
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented

Within the `EXAM` source, each exam type carries a weight. The engine reads published results per exam type, normalizes each to a percentage, and combines them by weight.

**Rules**
- An exam type can appear at most once per template (BR-MSG-C24).
- `weightage_percent` is 0–100; `max_marks` is optional display metadata.
- The sum of active exam weights must equal 100% within tolerance (BR-MSG-C29).
- Saving one row does **not** validate the sum; validation happens at compute time (documented rule BR-MSG-050 legacy, now BR-MSG-S07).
- Only exam types that appear in the template’s exam group should be selectable, and only those should be read.
- Deleting a weightage used by computed results is blocked; delete is soft.
- Absent or withheld exam results are excluded by the exam reader (`is_published = 1`, null-safe percentage), not treated as zero.

**Acceptance**
1. Weight PT1 20, Half-Yearly 30, Annual 50; compute closes to 100.
2. Save a single 30% row without touching the others; the save succeeds.
3. Run compute with an active total of 90; compute fails with a clear “exam weightages must sum to 100” message.
4. Remove an exam type from the group but leave its weight; compute either ignores it or blocks — the behaviour is documented and consistent.
5. Deactivate a weight; it is excluded from the sum and from the combination.

**Implementation note:** Saving is independent, as documented. Compute validates the sum. The template edit dropdown is not filtered by exam group, so a weight can reference an exam type outside the group; computation reads it anyway. The `max_marks` column is not used to cap the percentage.

---

#### STD-MSG-003 — Template IA component configuration
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented

The school attaches IA categories to a template, each with a maximum mark and display order.

**Rules**
- An IA type can appear at most once per template (BR-MSG-C24).
- `max_marks` is required and ≥ 0, with at most two decimals.
- `display_order` is a positive integer; if omitted, the next order is assigned.
- IA components are template-wide, not per subject. The same max applies to every subject unless the UI communicates otherwise.
- Deleting a component with recorded IA marks is blocked; delete is soft.
- Only active components are loaded by computation.

**Acceptance**
1. Attach Notebook (5, order 1), Portfolio (5, order 2), Viva (10, order 3).
2. Enter a mark of 9/10 for Viva; it is stored against the template component id.
3. Attempt a duplicate Notebook row; blocked.
4. Delete the Notebook component while marks exist; blocked.
5. Reorder components; the IA entry screen follows display order.

**Implementation note:** Implemented. The delete guard is not enforced in the service; it depends on the FK from `msh_student_ia_marks.ia_component_id`, which is `RESTRICT`, so a hard delete is blocked but a **soft delete succeeds** and leaves marks orphaned from the active component list. Computation then excludes the component, silently dropping those marks from the IA total.

---

#### STD-MSG-004 — Template co-scholastic component configuration
**Priority:** P1 · **Tier:** Standard · **Status:** Implemented, BA link partial

The school defines non-academic areas for a template, each with a code, name, grading scale, display order and an optional behavioural-assessment link.

**Rules**
- `code` is unique within the template (BR-MSG-C24).
- `name` is required; `grading_scale` defaults to `3_POINT` and may be a descriptive label such as `5_POINT`, `A-E`.
- `is_ba_linked = 1` means the grade may be auto-populated from the Behavioural Assessment module when integration is enabled.
- Deleting a component with recorded grades is blocked; delete is soft.
- Only active components are loaded by computation and displayed on results.
- A co-scholastic component is not part of the academic total and never affects subject or overall percentage.

**Acceptance**
1. Add `BEH` / Behaviour and Discipline / 5-Point / BA-linked.
2. Add `ART` / Art & Craft / 5-Point / manual.
3. Compute with BA integration enabled and a locked BA period; `BEH` receives the BA grade and is flagged auto.
4. Compute with BA integration disabled; `BEH` remains blank for manual entry.
5. Delete `ART` while a grade exists; blocked.

**Implementation note:** Implemented. Computation auto-fills a BA-linked component only when `ba_config.is_result_integration_enabled = 1` and a qualifying locked BA period exists. Otherwise it writes a row with `grade = null`. **Recompute hard-deletes all co-scholastic rows for the schedule**, including manual grades, then recreates blank rows. See CF-19.

---

#### STD-MSG-005 — Template lock enforcement
**Priority:** P0 · **Tier:** Standard · **Status:** Partial

Publishing a schedule freezes its grading recipe. A locked template cannot be edited, have components added or removed, be deactivated, or be deleted.

**Rules**
- `msh_config_templates.is_locked` is set to 1 inside the publish transaction (BR-MSG-C19, BR-MSG-S08).
- Every template write path — master update, component create/update/delete, class assignment sync, toggle status, delete — must reject a locked template.
- The lock is released only by an explicit administrative action that is logged; it is never released implicitly by schedule unlock.
- A locked template remains readable and usable by existing schedules.
- The UI disables edit/delete controls for a locked template.

**Acceptance**
1. Publish a schedule; the template shows a “Locked” badge.
2. Attempt to edit the passing percentage; blocked with a message naming the schedule.
3. Attempt to add a scholastic component; blocked.
4. Attempt to deactivate the template; blocked.
5. Attempt to delete; blocked.
6. Recompute the published schedule (after unlock); it still uses the locked recipe successfully.

**Implementation note:** Publish sets the flag, but **no write path reads it**. The request accepts `is_locked` from the client, so a crafted payload can unlock the template. The UI does not visibly disable all edit controls. This is the single largest lifecycle-integrity gap (CF-23).

---

#### STD-MSG-006 — Template data loading for computation
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented

Computation must load one consistent snapshot of the template and all active child configuration at the start of the run.

**Rules**
- Load the template row, active scholastic components keyed by source code, active exam weightages keyed by exam type id, and active IA components ordered by display order.
- Exclude soft-deleted and inactive rows.
- Fail the run before any result write if the template is missing or both weightage sums are not 100.
- Use the same loaded snapshot for every class section in the run so a mid-run configuration change cannot produce mixed results.
- Do not re-read template children per student.

**Acceptance**
1. A complete template yields non-empty scholastic, exam-weightage and IA collections.
2. An inactive component is absent from the snapshot.
3. Deleting a component during a run does not affect the in-flight run.
4. A template with a 90% exam sum fails before writing any `msh_student_results` row.

**Implementation note:** Implemented. The snapshot is loaded once before the class-section loop. Co-scholastic components are loaded once **inside** each class-section, from the database, so a concurrent change could affect later sections. Not a practical risk at current scale, but it breaks strict determinism.

---

#### STD-MSG-007 — Weightage closure validation
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented, contract ambiguous

The engine must refuse to compute when the active weightages do not define a complete recipe.

**Rules**
- Scholastic source weights must sum to 100 ± 0.01.
- Exam-type weights must sum to 100 ± 0.01.
- A missing or empty set is a failure, not a zero-weight subject.
- The failure is recorded as a failed computation log with the exact sum in the message.
- The schedule status does not advance on failure.
- The message names which weightage set failed and the observed total.

**Acceptance**
1. Scholastic 80/10/10 and exam 20/30/50; compute proceeds.
2. Scholastic 80/10/5; compute fails with “Scholastic component weightages must sum to 100 (got 95)”.
3. Exam 20/30/40; compute fails with the analogous message.
4. No components at all; compute fails, not produces zero totals.
5. Failure is visible on the schedule and in the computation log.

**Implementation note:** Implemented exactly. The requirement documents only say the sum “must not exceed 100%” in one place and “must equal 100” in another; the code enforces equality. Section 14 records the contradiction and Section 16 asks which is intended. Equality is the current contract.

---

#### STD-MSG-008 — Configuration change audit
**Priority:** P2 · **Tier:** Standard · **Status:** Partial

Every create, update, delete, restore and status toggle on configuration entities writes an application activity-log entry containing the actor, entity and a payload summary.

**Rules**
- The log identifies the entity type and id, the action, the actor and the timestamp.
- The payload summary includes changed fields at a level useful for dispute resolution.
- Logging failure must not silently roll back a successful business transaction; it is recorded and surfaced.
- Lifecycle actions additionally write an immutable `msh_computation_logs` row.
- Configuration logs are read-only to ordinary users.

**Acceptance**
1. Change a template’s passing percentage; an activity entry records old and new values.
2. Publish a schedule; both an activity entry and a computation log exist.
3. A user without audit permission cannot read the log.
4. Log rows survive soft deletion of the entity.

**Implementation note:** Controllers call `activityLog()` with a message but generally **do not pass old/new values**, so the payload is descriptive rather than forensic. Lifecycle actions write both an activity log and a computation log. The requirement is partially met.

---

### 5.3 Scheduling and computation requirements

#### STD-MSG-010 — Marksheet schedule master
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented, lifecycle bypass

A schedule is the event that turns a template into results for a set of class sections. It records the template, academic session, code, name, schedule date, lifecycle status, computation timestamp and lock metadata.

**Rules**
- `code` is unique within the academic session (BR-MSG-S01).
- `config_template_id` and `academic_session_id` are required and must exist.
- The template must belong to the same academic session as the schedule. This is not currently enforced (BR-MSG-S17).
- `status_id` is a valid `msh_marksheet_schedules.status_id` dropdown value.
- A new schedule starts as `DRAFT`. The create form must not offer `COMPUTED`, `REVIEWED`, `PUBLISHED` or `LOCKED`.
- Editing must not change lifecycle status; status changes only through lifecycle actions (BR-MSG-S02).
- `schedule_date` is optional but recommended; it is the intended issue date.
- `is_locked` is system-controlled, never client-controlled.
- Delete is soft and is blocked when the schedule is published/locked or has computed results (BR-MSG-S12).
- `total_students` is the number of enrolled students processed by the last successful run, not the number of results.

**Acceptance**
1. Create `TERM1_2026` / “Grade 10 Term 1 Final” with a template, session 2026-27 and classes 10-A, 10-B; status is `DRAFT`.
2. Duplicate the code in the same session; blocked. Reuse in another session; allowed.
3. Edit the name and classes while `DRAFT`; allowed.
4. Attempt to set status to `PUBLISHED` through the edit form; rejected.
5. Publish, then attempt to delete; blocked.
6. Attempt to create a schedule with a template from another session; blocked.

**Implementation note:** Create/edit accept **any** active status from `sys_dropdown_table`, including `PUBLISHED` and `LOCKED`, and the request accepts `is_locked` and `is_active` from the client. The edit form therefore bypasses the entire lifecycle and can also set the lock flag directly. Template/session consistency is not validated (CF-24, CF-25).

---

#### STD-MSG-011 — Schedule class-section mapping
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented

The schedule includes one or more class sections through `msh_schedule_class_jnt`. Only active, non-deleted mappings are computed.

**Rules**
- A class section appears at most once per schedule (BR-MSG-S13).
- Adding or updating mappings is blocked when the schedule is locked (BR-MSG-S14).
- A mapping cannot be deleted after results exist for that class section under the schedule (BR-MSG-S15).
- The mapping’s class section must be an active section of a class in the schedule’s session.
- The schedule must have at least one active mapping before compute; otherwise compute is a no-op and must report it.
- Saving a schedule synchronises mappings; removed mappings are soft-deleted and re-selected mappings restored.
- The schedule-class standalone screen excludes locked schedules from its dropdown.

**Acceptance**
1. Map 10-A and 10-B to a schedule; compute processes both.
2. Attempt to map 10-A twice; blocked.
3. Disable the 10-B mapping; compute skips it.
4. Lock the schedule; the standalone create/edit dropdown no longer offers it and direct updates are rejected.
5. Remove a mapping after results exist; blocked.
6. Create a schedule with no mappings and compute; the user receives an explicit “no class sections” message.

**Implementation note:** The junction, uniqueness and sync are implemented. The locked guard exists **only** in the standalone dropdown and the controller’s create/edit pages; the service does not check it, and schedule edit can rewrite mappings on a published schedule. The delete guard is absent. Compute with no mappings wipes results and marks the schedule `COMPUTED` with zero students (CF-20, CF-29).

---

#### STD-MSG-012 — Precheck
**Priority:** P1 · **Tier:** Standard · **Status:** Implemented, advisory

Before compute, the coordinator can run a precheck that reports template completeness and the volume of source evidence per class section. Precheck is a diagnostic, not a gate.

**Rules**
- Report exam group presence, grading schema presence, passing percentage, exam-weightage count and sum, scholastic-component count and sum, IA component count, co-scholastic count.
- Per class section, report student count, subject count, published exam-result count, graded homework count, published quiz count and IA mark count.
- Use the same session resolution and subject enumeration as compute.
- Clearly distinguish “zero evidence” from “configuration missing”.
- Precheck must not write results or change schedule status.
- A failed precheck should warn the user but must not silently allow a compute that will certainly fail; the user must confirm.

**Acceptance**
1. A complete template and populated classes show green checks and non-zero evidence counts.
2. A 90% exam sum shows a red check with the observed sum.
3. A class with no students shows zero and a warning.
4. A class with students but no published exams shows zero exam evidence.
5. Precheck does not alter `last_computed_at`, status or results.

**Implementation note:** Implemented as a read-only page. **It queries students with the organization session id**, while compute uses the global session id, so counts can be wrong. It is advisory only: the compute endpoint does not require a successful precheck. Exam and quiz counts are class-wide, not section-wide, and do not apply the exam-group date window. CF-30, CF-31.

---

#### STD-MSG-013 — Compute trigger and run gating
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented

Compute is triggered from the schedule page. It validates the schedule state, refuses concurrent runs, and dispatches a background job.

**Rules**
- Compute requires the schedule to be `DRAFT` or `COMPUTED` (BR-MSG-S03).
- Compute is blocked when `is_locked = 1` (BR-MSG-S04).
- Compute is blocked when a computation log for the schedule is `RUNNING` (BR-MSG-S05).
- The trigger records who dispatched it.
- In local/sync mode the job runs inline; in production it is queued.
- The job has a bounded timeout and does not auto-retry, because a retry can duplicate partial work.
- The user receives a clear “complete” or “queued” message.
- A second click while a run is active is rejected with a stable message, not a duplicate job.

**Acceptance**
1. Click Compute on a `DRAFT` schedule; a run starts and the status becomes `COMPUTED` on success.
2. Click Compute twice quickly; the second click is rejected while the first is running.
3. Click Compute on a `REVIEWED` schedule; rejected.
4. Click Compute on a locked schedule; rejected before dispatch.
5. Force the job to fail; the log becomes `FAILED` and the schedule does not advance.

**Implementation note:** Implemented, including the `RUNNING` guard. The guard is a check-then-dispatch race: two requests in the same millisecond can both see no running log and both dispatch. A database advisory lock or a unique partial index is needed for strictness. The job sets `tries = 1`, which is correct. `failed()` updates any `RUNNING` log to `FAILED` but does not revert results already written.

---

#### STD-MSG-014 — Student and subject enumeration
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented

For each class section, computation must determine exactly which students and which subjects participate.

**Rules**
- Students are those with `std_student_academic_sessions.class_section_id = section`, `academic_session_id = global session`, and `is_current = 1`.
- Subjects are the distinct active subjects in `tt_class_requirement_groups` for the section’s class.
- When `std_student_subject_enrolments` exists, a student is computed only for enrolled subjects; otherwise every student takes every class subject.
- A student with no subjects produces no subject result and no overall result.
- A class section with no students or no subjects is skipped and counted as zero.
- Duplicate student or subject rows must not produce duplicate results (guarded by unique keys).

**Acceptance**
1. A section with 40 current students and 6 subjects produces 240 subject results and 40 overall results.
2. A student enrolled in only 5 of 6 subjects produces 5 subject results.
3. A section with no current students produces zero and does not fail the whole run.
4. A subject with no exam, homework, quiz, quest or IA evidence still produces a subject row with null component values and a zero/partial total, not a missing row.
5. Re-running does not duplicate rows.

**Implementation note:** Implemented. Subject enumeration uses the timetable requirement groups, not `msh_class_config_jnt` or a marksheet-specific subject list. A subject taught but absent from the timetable group is silently excluded. Elective filtering depends on a table that may not exist; the code checks `Schema::hasTable` and degrades to “all subjects”. The DDL has no MSH-owned subject list, so this dependency is architectural, not incidental (CF-45).

---

#### STD-MSG-015 — Exam evidence ingestion
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented

Exam scores come from published `lms_exam_results` rows, joined to papers (for subject) and exams (for class, session and exam type).

**Rules**
- Only `is_published = 1` results are evidence.
- Only results for the section’s class, the global session, the subject and the requested exam type are read.
- Multiple papers for the same subject and exam type are summed: `SUM(total_marks_obtained)` over `SUM(total_marks_possible)`.
- The normalized score is `raw / max × 100`; null max or zero max yields null, not infinity.
- Absent and withheld rows are counted and surfaced as flags; they are not silently converted to zero.
- The source `lms_exam_results.id` is stored on the line item for traceability (the representative maximum id).
- Exam reads are **not** filtered by the exam group’s date window; the exam type is the scoping mechanism.
- A missing exam result yields a null score, which is excluded from weighting.

**Acceptance**
1. A published 72/80 exam result for Physics becomes 90.00 normalized.
2. An unpublished result is ignored.
3. Two papers (30/40 and 40/40) sum to 70/80 = 87.50.
4. An absent result is flagged `ABSENT` on the line item and excluded from the weighted total.
5. A withheld result is flagged `WITHHELD` and excluded.
6. Recompute after the source mark changes uses the new value.

**Implementation note:** Implemented as described. Date parameters exist on the reader but computation passes none, so exams are term-scoped only by exam type. The `result_status` on the line item is re-derived from the aggregate flags and the template pass percentage: `WITHHELD` wins, then `ABSENT`, then `PASS`/`FAIL`. That means a student with one absent paper among several present papers is marked `ABSENT` for the whole exam type even though a partial aggregate exists (CF-46).

---

#### STD-MSG-016 — Homework evidence ingestion
**Priority:** P1 · **Tier:** Standard · **Status:** Implemented

Homework contributes through graded submissions of gradable homework.

**Rules**
- `lms_homework.is_gradable = 1`.
- `lms_homework_submissions.graded_at IS NOT NULL` and `marks_obtained IS NOT NULL`.
- Filter by subject, class and global session.
- When the exam group has a date window, filter on `lms_homework.due_date` within it.
- Sum obtained and maximum marks across qualifying submissions; normalize to a percentage.
- Missing homework yields null and is excluded from source weighting.

**Acceptance**
1. Three graded homeworks of 8/10, 9/10 and 10/10 produce 27/30 = 90.00.
2. An ungraded submission is ignored.
3. Homework due outside the term window is ignored when a window exists.
4. A student with no graded homework has null homework and the subject maximum shrinks.
5. Recompute picks up a newly graded submission.

**Implementation note:** Implemented. The date filter uses `due_date`, while the exam group window is a term boundary; a homework assigned in-term but due after the window is excluded. This is defensible but must be documented to teachers.

---

#### STD-MSG-017 — Quiz and quest evidence ingestion
**Priority:** P1 · **Tier:** Standard · **Status:** Implemented

Quizzes and quests are read from the polymorphic `lms_quiz_quest_results` table, filtered by `assessment_type`.

**Rules**
- Only `is_published = 1` results.
- Quiz joins `lms_quizzes`; quest joins `lms_quests`.
- Filter by subject, class and global session.
- When the exam group has a date window, filter on result `created_at`.
- Sum obtained and maximum marks; normalize to a percentage.
- Absent and withheld quiz/quest results are not separately flagged; the reader exposes only raw/max/count.
- Missing evidence yields null and is excluded.

**Acceptance**
1. Two published quizzes of 18/20 and 20/20 produce 95.00.
2. An unpublished quiz is ignored.
3. A quiz outside the term window is ignored.
4. A student with no quiz has null quiz.
5. Quest and quiz never mix because `assessment_type` separates them.

**Implementation note:** Implemented. Because absent/withheld are not flagged, an absent quiz with a zero score is indistinguishable from a genuine zero and depresses the quiz percentage. This is a data-quality gap (CF-46b).

---

#### STD-MSG-018 — Internal assessment computation
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented, excluded from total

IA marks are teacher-entered per student × subject × template IA component. The IA total is the sum of obtained marks over the sum of maximum marks, normalized to a percentage.

**Rules**
- Only active, non-deleted IA components attached to the template are included.
- Only active, non-deleted `msh_student_ia_marks` rows for the schedule and subject are included.
- `marks_obtained` may be null (not yet entered); a null row is excluded from both numerator and denominator.
- `max_marks` is copied from the template component at entry time and stored on the mark row.
- The IA percentage is `SUM(marks_obtained) / SUM(max_marks) × 100`, rounded to 2 decimals.
- The IA percentage participates in the subject total only when an `IA` source component is mapped to the template.
- IA marks are preserved across recompute; they are an input, not an output.
- Entering a mark above the component maximum is rejected.

**Acceptance**
1. Notebook 4/5 + Portfolio 5/5 + Viva 8/10 = 17/20 = 85.00.
2. A blank component is excluded; 4/5 + 5/5 = 90.00, not 56.67.
3. A mark of 11/10 is rejected at entry.
4. Recompute preserves the entered marks and recalculates the IA percentage.
5. With no `IA` source mapped, `ia_total` is populated but `subject_total` does not include it — and the UI/template must say so.

**Implementation note:** Implemented as described, except that entry does not enforce `marks_obtained <= max_marks` (only `>= 0`), and `max_marks`/`entered_by` are accepted from the client (CF-57). The last point is the P0 trap: the seeded source vocabulary has no `IA`, so a school that configures IA components and enters marks reasonably expects them to count, but they do not. The only way to include IA today is to insert an `IA` row into `msh_source_components` manually and add a template scholastic component for it (CF-14).

---

#### STD-MSG-019 — Co-scholastic grades and behavioural auto-population
**Priority:** P1 · **Tier:** Standard · **Status:** Implemented, destructive recompute

Co-scholastic grades are per student × template component per schedule. They are qualitative and never affect the academic total.

**Rules**
- A student has at most one grade per component per schedule (BR-MSG-R04).
- `grade` is a short label (`A`, `B`, `A+`, etc.); `remarks` is optional up to 255 characters.
- `is_auto_from_ba = 1` only when the component is BA-linked, integration is enabled and a qualifying locked BA period produced a grade.
- Manual grades are the default when auto-population is unavailable.
- The UI distinguishes “Auto (BA)” from “Manual” (BR-MSG-R05).
- Only active components and active grade rows are displayed and printed (BR-MSG-R06).
- Recompute must **preserve manual grades** for students and components that still exist.
- Deleting a grade is soft; restore reactivates.

**Acceptance**
1. Compute a schedule with three co-scholastic components; three rows per student are created.
2. A BA-linked component with integration on receives the BA grade and the auto flag.
3. A manual component stays blank for teacher entry.
4. Enter “A” with remarks; it is stored and displayed as Manual.
5. Recompute after entering manual grades; the manual grades still exist.
6. Delete a grade; it is recoverable.

**Implementation note:** Auto-population works. **Recompute violates the preservation rule**: `wipePreviousResults()` hard-deletes every `msh_student_coscholastic_results` row for the schedule, then recreates blank rows. Every manual co-scholastic grade and remark is lost on every recompute. This is a P0 data-loss defect (CF-19, CF-43).

---

#### STD-MSG-020 — Attendance summary
**Priority:** P2 · **Tier:** Standard · **Status:** Implemented

Attendance is a per-student summary for the schedule, used on the printed marksheet. It is not part of the academic total.

**Rules**
- One row per student per schedule (unique key).
- `total_working_days` and `days_present` are non-negative integers, with `days_present <= total_working_days`.
- When the attendance module has data, the summary is auto-populated and flagged.
- Otherwise a manual summary can be entered.
- The attendance percentage is derived for display (`days_present / total_working_days × 100`); it is not stored.
- Recompute refreshes auto-populated rows but must not overwrite manual rows.
- The date range should match the exam group window; the current build counts the whole session.

**Acceptance**
1. Auto-populate 120 working days, 110 present → 91.67%.
2. Enter a manual summary when no attendance data exists.
3. Recompute does not overwrite a manual summary.
4. A printed marksheet shows the attendance percentage.
5. `days_present` greater than `total_working_days` is rejected.

**Implementation note:** Computation auto-populates from `std_student_attendance` by counting all rows for the student and session where `status = 'Present'`, with **no date filter**. `AttendanceReader` exists but is not used by the computation service. Manual rows are not distinguished from auto rows on recompute: the upsert overwrites them when attendance data exists, and leaves them when it does not. The DDL has no CHECK for `days_present <= total_working_days` (CF-41).

---

#### STD-MSG-021 — Theory and practical split
**Priority:** P1 · **Tier:** Standard · **Status:** Implemented, approximation

When a subject has a practical configuration, the weighted exam percentage is split into theory and practical portions in proportion to the configured maxima.

**Rules**
- With no practical configuration or `has_practical = 0`, the whole weighted exam value is theory and practical is null.
- With a practical configuration, `theory = exam × theory_max / (theory_max + practical_max)` and `practical = exam × practical_max / (theory_max + practical_max)`.
- The split applies the same ratio to every student in the class-subject.
- The split does not read separate theory and practical papers, because `lms_exam_papers` has no practical flag.
- The split values are display values stored on the subject result; they must sum to the exam-weighted total within rounding.
- A configuration with both maxima zero falls back to theory-only.

**Acceptance**
1. Physics 70/30 with an exam weighted total of 80 → theory 56.00, practical 24.00.
2. Mathematics 100/0 → theory equals the exam total, practical null.
3. A subject with no configuration → theory equals the exam total, practical null.
4. Theory + practical equals the exam total within 0.01.
5. The marksheet labels the split as calculated from the weighted total, not as raw paper marks.

**Implementation note:** Implemented exactly. It is an approximation, not a real theory/practical mark split, and the source code says so. A school that expects the practical column to reflect the actual practical paper will see a proportional allocation instead. CF-16.

---

#### STD-MSG-022 — Subject result assembly
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented

For each student × subject, the engine combines normalized source percentages using the template’s scholastic weights and persists one subject result.

**Rules**
- Source percentages: `EXAM` from exam weighting, `HOMEWORK`, `QUIZ`, `QUEST`, and `IA` when mapped.
- A null source is excluded from both numerator and denominator; it is not treated as zero.
- `subject_total = Σ(source_percent × weight) / 100` over present sources.
- `subject_max = Σ(weight)` over present sources. For a fully populated template this is 100; for a partial template it is the sum of present weights.
- `subject_percentage = subject_total / subject_max × 100`, or 0 when max is 0.
- `subject_grade` is resolved from the percentage; `is_passed` is `subject_percentage >= template.passing_percentage`.
- One row per student × subject × schedule (BR-MSG-R02).
- The row stores the component percentages, not raw marks; raw exam marks live on the line-item table.

**Acceptance**
1. Exam 80%, Homework 90%, Quiz 70% with weights 80/10/10 → subject total 81.00, max 100, percentage 81.00.
2. Exam 80% only, with Exam weight 80 → subject total 64.00, max 80, percentage 80.00.
3. A null quiz with Exam 80 and Homework 90 at 80/10 → total 73.00, max 90, percentage 81.11.
4. A failing percentage below 33 → `is_passed = 0` and a failing grade band.
5. Recompute replaces the row rather than duplicating it.

**Implementation note:** Implemented. The shrinking denominator (max < 100) is deliberate null-safety, but it means two students with different missing sources are not compared on the same maximum. The UI must show the effective maximum. `subject_max` is stored, so this is auditable (CF-15, CF-42).

---

#### STD-MSG-023 — Overall result, grade and division
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented

For each student, the engine sums subject totals and maxima, computes the overall percentage, and resolves an overall grade and division.

**Rules**
- `grand_total = Σ subject_total`; `grand_max = Σ subject_max`.
- `overall_percentage = grand_total / grand_max × 100`, or 0 when max is 0.
- `overall_grade` and `division` are resolved from grade/division bands.
- Band scope precedence is `CLASS` → `BOARD` → `SCHOOL`; within a scope, the first containing band wins.
- Subject grades use the student’s class id; overall grades use `classId = null` (school/board scope only).
- The template’s `grading_schema_id` is **not** used to select bands; the global active band set is used.
- `total_subjects`, `subjects_passed` and `subjects_failed` are stored.
- One overall row per student × schedule (BR-MSG-R01).

**Acceptance**
1. Six subjects totalling 486/600 → 81.00%, grade/division from the school bands.
2. A subject fail increments `subjects_failed` and decrements `subjects_passed`.
3. A class-scoped band overrides the school band for a subject grade.
4. An overall grade uses the board/school band, not the class band.
5. A template with an explicit grading schema produces the same grade as one without, if the global bands are identical — and a different grade if they are not, which is the defect.

**Implementation note:** Implemented as described. The `grading_schema_id` column exists, is required by the DDL, is selected in the UI and is ignored by `GradeResolver`. Two templates with different schemas therefore produce identical grades if global bands do not distinguish them (CF-17, CF-42).

---

#### STD-MSG-024 — Promotion derivation
**Priority:** P1 · **Tier:** Standard · **Status:** Implemented, inferred

Promotion is derived only for a result that represents the final result of the academic session.

**Rules**
- `is_last_result_for_session = 1` only for a final/annual/promotion marksheet type.
- `promotion_status` is null when the result is not final.
- When final: zero failed subjects → `PROMOTED`; failures ≤ `compartment_max_failures` → `COMPARTMENT`; otherwise `DETAINED`.
- `PLACED` is permitted by the request/validation vocabulary but is never produced by the engine.
- Promotion is never derived from a term or half-yearly result.
- The final-result determination must be explicit, not inferred from a free-text type code.
- A school may override a promotion decision manually with an audited reason.

**Acceptance**
1. Annual result with 0 fails → PROMOTED.
2. Annual result with 2 fails and limit 2 → COMPARTMENT.
3. Annual result with 3 fails and limit 2 → DETAINED.
4. Term-1 result → `is_last_result_for_session = 0`, promotion null even with failures.
5. Rename the marksheet type code from `ANNUAL` to `ANNUAL_RPT`; promotion must not silently disappear.

**Implementation note:** Implemented via a hard-coded code list: `ANNUAL`, `FINAL`, `SESSION_FINAL`, `PROMOTION`. Renaming or localising a type code changes promotion behaviour with no warning. `PLACED` is unreachable. There is no manual override path. CF-38.

---

#### STD-MSG-025 — Ranking
**Priority:** P1 · **Tier:** Standard · **Status:** Partial

The engine ranks students by grand total.

**Rules**
- Section rank is dense: ties share a rank and the next rank increments by one.
- Class rank is dense across all sections of the same class in the same schedule.
- Rank is computed after all results for the scope are written.
- A student with a null or zero grand total is still ranked, at the bottom.
- Withheld students may be excluded from rank or ranked but hidden; the policy is explicit.
- Rank is recalculated on every recompute.

**Acceptance**
1. Totals 90, 85, 85, 70 in one section → ranks 1, 2, 2, 3.
2. Section A and B of the same class are ranked together for class rank.
3. A recompute after a mark correction updates ranks.
4. A withheld student is handled per the chosen policy.

**Implementation note:** `RankCalculator` writes only `rank_in_section`. `rank_in_class` is inserted as `0` and never updated. The code comment explicitly defers cross-section ranking. This contradicts the DDL comment (“Rank within class across all sections”) and the student result screen’s “Rank” field. CF-18.

---

#### STD-MSG-026 — Idempotency and recompute
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented, destructive

Recomputing a schedule must produce the same result as a first compute from the same inputs, without duplicating rows and without destroying teacher-entered inputs.

**Rules**
- Previous **computed outputs** are cleared for the schedule before a new run: student results, subject results, exam line items and computed co-scholastic rows.
- Teacher-entered **inputs** are preserved: IA marks, manual attendance and manual co-scholastic grades.
- The clear and the rebuild are scoped to the schedule.
- A failed run must not leave a half-old, half-new result set visible as final.
- The schedule’s `last_computed_at` updates only after the run; `status` advances only on full success.
- The run is safe to repeat.

**Acceptance**
1. Compute twice with unchanged inputs; row counts and totals are identical.
2. Correct an exam mark and recompute; the subject and overall totals change.
3. Enter a manual co-scholastic grade and recompute; the grade survives.
4. Force one class section to fail; the schedule does not become `COMPUTED` and the failure is reported.
5. Compute with zero class sections; the user is told nothing was processed.

**Implementation note:** The clear is hard-delete and includes co-scholastic rows, so rule 3 fails. IA marks and attendance survive. The clear happens **before** the class-section loop, so a failure in the first section leaves the schedule with no results at all while the status remains whatever it was. A failure after some sections leaves partial results. There is no staging table or run-version column to distinguish a partial run (CF-19, CF-20, CF-21).

---

#### STD-MSG-027 — Computation logging
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented, vocabulary mismatch

Every computation and lifecycle action writes an immutable audit row.

**Rules**
- Log `COMPUTE`/`RECOMPUTE`, `REVIEW`, `PUBLISH`, `LOCK`, `UNLOCK`, `WITHHOLD` and `DECLARE`.
- `status` vocabulary is `IN_PROGRESS`, `SUCCESS`, `FAILED`, `PARTIAL` (DDL). A blocked run is a failure with a reason.
- `action` vocabulary includes the lifecycle actions above plus any added action.
- `started_at` and `completed_at` are timestamps; `duration_seconds` is derived.
- `total_students` is the processed count; `total_errors` is the error count.
- `error_log` is structured (JSON array), not newline-delimited prose.
- `remarks` carries the unlock reason and human-readable notes.
- The log is never soft-deleted; it has no `deleted_at`.
- A log row is written even when the run is blocked before any student is processed.

**Acceptance**
1. A successful run writes one `COMPUTE` / `SUCCESS` row with a duration and student count.
2. A weightage failure writes `COMPUTE` / `FAILED` with the message.
3. Review, publish, lock, unlock, withhold and declare each write their action.
4. A blocked run writes a row with a reason.
5. The log page shows status, action, actor, start, end, duration, students and errors.

**Implementation note:** Implemented with three mismatches: the code writes `RUNNING` (not `IN_PROGRESS`) and `BLOCKED` (not documented at all); `error_log` is newline-delimited text (not JSON); and `action` includes `REVIEW`, `WITHHOLD` and `DECLARE`, which the DDL does not document. `RECOMPUTE` is never written — a recompute is logged as `COMPUTE`. CF-36.

---

#### STD-MSG-028 — Partial-failure handling
**Priority:** P0 · **Tier:** Standard · **Status:** Partial

A failure in one class section must not silently produce a publishable mixed result.

**Rules**
- Each class section is processed in its own transaction so a database error does not poison the others.
- If any section fails, the run is `PARTIAL`, the schedule does **not** advance to `COMPUTED`, and the failed sections are listed.
- Results from successful sections are either retained with an explicit “partial” marker or rolled back; the choice is documented.
- A partial run cannot be reviewed or published until it succeeds completely or is explicitly accepted.
- The user sees which sections succeeded and which failed, with the error.
- The next compute clears the partial state.

**Acceptance**
1. Section A succeeds and B fails; the log is `PARTIAL`, status stays `DRAFT`/`COMPUTED` as before, and the page lists B’s error.
2. A partial run cannot be reviewed.
3. Recompute after fixing B produces a complete result set.
4. The successful section’s rows are either clearly marked or absent; no ambiguity.

**Implementation note:** The per-section transaction and `PARTIAL` status exist. The schedule keeps its previous status on error, which is correct. But successful sections’ rows remain in the result tables and are indistinguishable from a complete run; review is still allowed because the status may already be `COMPUTED` from a previous successful run. There is no run-version column. CF-21.

---

#### STD-MSG-029 — Review action
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented

Review moves a `COMPUTED` schedule to `REVIEWED`, signalling that the examination cell has accepted the run and teachers may no longer change marks.

**Rules**
- Only `COMPUTED` can be reviewed (BR-MSG-S06).
- The actor must hold `msh-marksheet-schedule.review`.
- Review writes a `REVIEW` computation log and an activity log.
- Review does not alter results, marks or template configuration.
- After review, IA and co-scholastic entry for that schedule is blocked for ordinary teachers.
- Review is reversible only through unlock, not through edit.

**Acceptance**
1. Review a `COMPUTED` schedule; status becomes `REVIEWED`.
2. Attempt to review a `DRAFT`; rejected with a clear message.
3. Attempt to edit a mark after review; blocked for a teacher.
4. Review writes an audit row naming the actor.
5. Review does not change any total.

**Implementation note:** Implemented. **Mark entry is not actually blocked after review**: the IA and co-scholastic controllers do not check schedule status, only the general permission. A teacher with update permission can continue editing a `REVIEWED` schedule’s marks. CF-22.

---

#### STD-MSG-030 — Publish action and template lock
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented, incomplete

Publish moves a `REVIEWED` schedule to `PUBLISHED` and locks its template.

**Rules**
- Only `REVIEWED` can be published (BR-MSG-S07).
- The actor must hold `msh-marksheet-schedule.publish`.
- Publish sets the template’s `is_locked = 1` (BR-MSG-S08).
- If the adopted publication policy is auto-declare (OD-13), publish marks every non-withheld student result as `DECLARED` so consumers know it is visible (BR-MSG-R07). If declaration is a separate action, publish must instead expose an explicit “declared” workflow and consumers must not treat schedule publication alone as visibility.
- Publish writes a `PUBLISH` computation log and an activity log.
- Publish is atomic: status, template lock, result statuses and logs succeed or all roll back.
- Publishing twice is rejected.
- A published schedule cannot be edited or deleted.

**Acceptance**
1. Publish a `REVIEWED` schedule; status becomes `PUBLISHED` and the template shows locked.
2. Under auto-declare, a withheld student remains `WITHHELD` and every other result becomes `DECLARED`. Under separate declaration, no result changes and the declaration workflow is the only path to visibility.
3. Publish a `COMPUTED` schedule; rejected.
4. A failure in the template lock rolls back the status change.
5. A second publish is rejected.
6. Consumers see only `DECLARED` results.

**Implementation note:** Status and template lock are implemented atomically. **Result statuses are not touched.** `result_status` stays null for every student, so any consumer filtering on `DECLARED` sees nothing. The code comment in `computeAndPersistOverall()` claims publish sets `DECLARED`, but `MarksheetScheduleLifecycleService::publish()` does not. CF-22b.

---

#### STD-MSG-031 — Lock action
**Priority:** P1 · **Tier:** Standard · **Status:** Implemented

Lock moves a `PUBLISHED` schedule to `LOCKED`, sets `is_locked = 1`, and records `locked_at` and `locked_by`.

**Rules**
- Only `PUBLISHED` can be locked (BR-MSG-S09).
- The actor must hold `msh-marksheet-schedule.lock`.
- Lock is the final state; it blocks compute, mark entry, result edit and schedule edit.
- Lock writes a `LOCK` computation log.
- Lock does not change results.
- A locked schedule remains readable and printable.

**Acceptance**
1. Lock a published schedule; status becomes `LOCKED` and the lock badge appears.
2. Attempt compute; blocked.
3. Attempt mark edit; blocked.
4. Attempt schedule edit; blocked.
5. Print still works.

**Implementation note:** Implemented for status, `is_locked`, `locked_at` and `locked_by`. Compute and withhold/declare check `is_locked`. Schedule edit and mark entry do not. Print still works. CF-22.

---

#### STD-MSG-032 — Unlock action
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented, permissive

Unlock re-opens a published or locked schedule for correction and requires a reason.

**Rules**
- Only `PUBLISHED` or `LOCKED` may be unlocked (BR-MSG-S10).
- The actor must hold `msh-marksheet-schedule.unlock`.
- `unlock_reason` is required and at least 5 characters (BR-MSG-S11).
- Unlock sets status to `COMPUTED`, clears `is_locked`, and records `unlocked_at`, `unlocked_by` and the reason.
- The reason is written to the computation log and the activity log.
- Unlock does **not** unlock the template; the recipe remains frozen.
- Unlock does not delete results; the next compute rebuilds them.
- Unlock is itself auditable and cannot be hidden.

**Acceptance**
1. Unlock a `LOCKED` schedule with a reason; status becomes `COMPUTED` and the reason is visible in the log.
2. Unlock with a 4-character reason; rejected.
3. Unlock a `DRAFT`; rejected.
4. After unlock, recompute and republish.
5. The template remains locked throughout.

**Implementation note:** Implemented except for the state check. `unlock()` accepts **any** status, including `DRAFT`, `COMPUTED` and `REVIEWED`, and always resets to `COMPUTED`. It sets `is_locked = false` but does **not** clear `locked_at` or `locked_by`, and does not unlock the template. A user with unlock permission can therefore “unlock” a draft, which is harmless but misleading, and the lock metadata becomes stale. CF-25.

---

### 5.4 Results and publication requirements

#### STD-MSG-040 — Student result list and filters
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented

The Student Results tab lists one row per student per schedule with identity, class section, grand total, percentage, grade, division, rank, promotion and result status.

**Rules**
- Default page size is 15.
- Filter by class section and by schedule; search by student name or admission number.
- With a class section selected, sort by grand total descending.
- Without a class section, group by class section and sort by grand total within each group.
- The class-section filter lists only sections that have computed results.
- The schedule filter lists only schedules that have results.
- Filters are tab-prefixed so they do not leak into other result tabs.
- Withheld rows are visibly badged and show the reason.
- The row exposes print, export, withhold/declare and detail actions per permission.

**Acceptance**
1. Open the tab; results are grouped by section and ordered by total.
2. Select 10-A; the list shows only 10-A, highest total first.
3. Search an admission number; the matching student appears.
4. Select a schedule; only that schedule’s results appear.
5. A withheld student shows a red badge and reason.
6. Switching to Subject Results preserves the Student Results filter.

**Implementation note:** Implemented. Class sections and schedules are derived from `msh_student_results` with `distinct()`, so soft-deleted results still influence the filter lists. Search is scoped to the active tab only.

---

#### STD-MSG-041 — Student result detail
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented

The detail page shows one student’s full result for one schedule: identity, totals, grade, division, rank, promotion, subject table, co-scholastic table, exam line items, IA marks and attendance.

**Rules**
- Subject and co-scholastic relations must be scoped to the result’s schedule, not the student’s whole history.
- Exam line items are grouped by subject and show exam type, marks, max and status.
- IA marks are grouped by subject and show component, marks and max.
- Attendance shows working days, present days and percentage.
- Withheld results show the reason and hide or mask the printable view per policy.
- The page offers print and export when permitted.

**Acceptance**
1. Open a result; every subject row matches the stored subject result.
2. A student with two schedules shows only the selected schedule’s subjects.
3. Exam line items reconcile to the weighted total.
4. IA components appear in display order.
5. Attendance percentage is correct.
6. A withheld result shows the reason.

**Implementation note:** Implemented, including explicit post-load schedule filtering because the model relationships are student-wide. This is a known trap: `subjectResults()` and `coscholasticResults()` deliberately omit a schedule constraint, so any new caller that forgets to filter will leak across schedules. CF-40.

---

#### STD-MSG-042 — Subject result view
**Priority:** P1 · **Tier:** Standard · **Status:** Implemented

The Subject Results tab expands each student to show subject-level marks: theory, practical, homework, quiz, quest, IA total, weighted exam total, subject total/max, percentage, grade and pass/fail.

**Rules**
- Default page size is 10.
- The tab is a read-only display of stored values; it must not recalculate on read.
- Each subject row shows the effective maximum (`subject_max`), not an assumed 100.
- Pass/fail is the stored `is_passed`, consistent with the template pass percentage at compute time.
- Standalone subject-result pages may be used for manual correction, with audit.
- Deletion is not offered from the tab.

**Acceptance**
1. Expand a student; all subjects appear with the stored values.
2. A subject with no practical shows a blank practical and theory equal to the exam total.
3. A subject with a partial source set shows `subject_max < 100`.
4. The grade matches the stored `subject_grade`.
5. A manual edit through the standalone page changes the stored row and is audited.

**Implementation note:** Implemented, including batch loading to avoid N+1. A full resource CRUD also exists for `student-subject-result`, so a user can create a subject row that the computation engine did not produce; there is no “computed vs manual” flag. This is a data-integrity risk, not a display defect (CF-48).

---

#### STD-MSG-043 — IA marks entry and review
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented, no lifecycle guard

Teachers enter IA marks per student × subject × template component.

**Rules**
- A student has at most one mark per component per subject per schedule (BR-MSG-R03).
- `marks_obtained` is ≥ 0 and ≤ the component’s `max_marks`.
- `max_marks` is copied from the template component and is not freely editable after entry.
- Only active components are offered.
- Entry is blocked when the schedule is `REVIEWED`, `PUBLISHED` or `LOCKED`.
- Entry writes `entered_by` and `entered_at`.
- Delete is soft; restore reactivates.
- A mark change after compute requires recompute to affect the subject total.

**Acceptance**
1. Enter 9/10 for Viva; the row stores the value and actor.
2. Attempt 11/10; rejected.
3. Attempt a duplicate component entry; blocked.
4. Attempt entry on a reviewed schedule; blocked.
5. Recompute reflects the new mark.
6. Delete and restore the mark.

**Implementation note:** CRUD and uniqueness are implemented. **The lifecycle guard is missing**: neither the controller nor the request checks schedule status or `is_locked`. A teacher can change IA marks on a `PUBLISHED` or `LOCKED` schedule, and the change will affect the next recompute without any published-result revision (CF-22). The upper bound is also missing: validation enforces `marks_obtained >= 0` but not `<= max_marks`, and `max_marks`, `entered_by` and `entered_at` are accepted from the request, so a client can raise the maximum or forge the actor (CF-57).

---

#### STD-MSG-044 — Co-scholastic grade entry and review
**Priority:** P1 · **Tier:** Standard · **Status:** Implemented, no lifecycle guard

Teachers enter or correct co-scholastic grades per student × component per schedule.

**Rules**
- One grade per student per component per schedule (BR-MSG-R04).
- `grade` is required; `remarks` is optional up to 255 characters.
- Manual entry sets `is_auto_from_ba = 0` and records the actor.
- A BA-linked component may be overridden manually only with an explicit confirmation and audit.
- Entry is blocked when the schedule is `REVIEWED`, `PUBLISHED` or `LOCKED`.
- The UI badges “Auto (BA)” vs “Manual”.
- Delete is soft; restore reactivates.

**Acceptance**
1. Enter “A” with remarks; stored as Manual.
2. A BA-linked row shows Auto (BA).
3. Attempt a duplicate component grade; blocked.
4. Attempt entry on a locked schedule; blocked.
5. Override an auto grade; the change is recorded and the badge changes to Manual.

**Implementation note:** CRUD and badge are implemented. The lifecycle guard and the override-confirmation rule are missing. `grade` is nullable in the request, and `entered_by`, `entered_at` and `is_auto_from_ba` are client-controlled, so the auto/manual badge and actor can be forged (CF-57). Combined with the destructive recompute, a manual grade is both editable after lock and deleted on the next recompute (CF-19, CF-22).

---

#### STD-MSG-045 — Attendance entry
**Priority:** P2 · **Tier:** Standard · **Status:** Implemented

The school can view and manually maintain a per-student attendance summary for a schedule.

**Rules**
- One row per student per schedule.
- `total_working_days` and `days_present` are non-negative; present cannot exceed total.
- Manual entry sets `is_auto_populated = 0` and records the actor.
- Auto-populated rows are read-only in the UI unless explicitly overridden.
- Entry is blocked on a locked schedule.
- Attendance is display-only and never affects the academic total.

**Acceptance**
1. Enter 120/110; percentage is 91.67%.
2. Attempt 110/120; rejected.
3. An auto row shows a source badge.
4. Attempt entry on a locked schedule; blocked.
5. The printed marksheet uses the stored summary.

**Implementation note:** Index/create/store/show/edit/update exist; there is no delete. The `days_present <= total_working_days` rule is not enforced by the request or the DDL. The controller does not check schedule status.

---

#### STD-MSG-046 — Withhold a student result
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented, incomplete

An authorised user can withhold one student’s result so it is not treated as declared, with a mandatory reason.

**Rules**
- A result can be withheld from any state except when the schedule is locked (BR-MSG-R07).
- `withheld_reason` is required and at least 5 characters (BR-MSG-R08).
- Withholding records the actor and timestamp (documented).
- Withholding writes a `WITHHOLD` computation log and an activity log.
- Withholding does not delete the result or change totals; it changes visibility only.
- A withheld result cannot be printed as an official marksheet unless an override is permitted.
- The reason is visible to authorised staff and on the result detail.

**Acceptance**
1. Withhold a result with a reason; status becomes `WITHHELD`.
2. Withhold without a reason; rejected.
3. Withhold on a locked schedule; rejected.
4. A withhold writes an audit row naming the student and reason.
5. The result remains computed and totals are unchanged.
6. A parent-facing consumer does not see it.

**Implementation note:** Implemented except for actor/timestamp columns: the DDL has no `withheld_at` or `withheld_by`, so only `updated_by` and the computation log carry provenance. The schedule check uses `is_locked`, not lifecycle status, so a `REVIEWED` or `PUBLISHED` (but unlocked) schedule permits withholding. That may be intended; it is not stated (OD-09).

---

#### STD-MSG-047 — Declare a student result
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented, permissive

Declare releases a withheld result for publication.

**Rules**
- Only a `WITHHELD` result can be declared (BR-MSG-R09).
- Declaring requires the withhold to be resolved; an optional note is recorded.
- Declaring sets `result_status = DECLARED`, clears the reason, and records the actor and timestamp.
- Declaring is blocked when the schedule is locked.
- Declaring writes a `DECLARE` computation log and an activity log.
- Declaring an already-declared result is idempotent and does not duplicate the audit.

**Acceptance**
1. Declare a withheld result; status becomes `DECLARED` and the reason is cleared.
2. Declare a non-withheld result; rejected.
3. Declare on a locked schedule; rejected.
4. Declare twice; no duplicate audit.
5. A declared result becomes visible to consumers.

**Implementation note:** Implemented, but **the state guard is missing**: `declare()` accepts any result and sets `DECLARED`, including one that was never withheld. The reason is cleared. Actor/timestamp columns are absent as for withhold. CF-27.

---

#### STD-MSG-048 — Student result deletion
**Priority:** P1 · **Tier:** Standard · **Status:** Contradicted

Deleting a student result removes it from the database; soft delete is not supported for this entity (BR-MSG-R10).

**Rules**
- Deletion requires `msh-student-result.delete`.
- Deletion is blocked when the schedule is published or locked.
- Deletion is hard, so no stale row can reappear through a trashed query.
- Deleting an overall result must also remove its subject, exam line-item and co-scholastic rows, or the database must reject the orphan.
- Deletion is audited before the row disappears.

**Acceptance**
1. Delete a draft result; it is gone from the table.
2. Attempt to delete a published result; blocked.
3. Subject and line-item rows are removed or blocked by FK.
4. An audit entry survives.
5. Recompute recreates the result if the student still belongs to the schedule.

**Implementation note:** `StudentResult` uses `SoftDeletes`, and `destroy()` calls `delete()`. The row remains with `deleted_at`, contradicting the requirement. Child rows are not deleted; they remain and can be re-associated by a recompute. The schedule-status guard is absent. CF-39.

---

#### STD-MSG-049 — Manual student result record
**Priority:** P2 · **Tier:** Standard · **Status:** Implemented, risky

A full CRUD surface exists for `msh_student_results` so an administrator can create or correct an overall result.

**Rules**
- If manual creation is permitted, it must be an explicit “manual result” with a source flag and audit.
- The unique `(schedule_id, student_id)` key is enforced.
- Manual totals must be internally consistent: `grand_total <= grand_max`, percentage = total/max, grade consistent with percentage.
- A manual result must not be silently overwritten by the next compute without warning.
- Promotion status is required only when `is_last_result_for_session = 1`.
- Manual creation is blocked on a published/locked schedule.

**Acceptance**
1. Create a result for a student with no computed row; it appears in the list.
2. Duplicate student/schedule; blocked.
3. Enter a percentage inconsistent with total/max; rejected or recalculated.
4. Recompute warns that a manual row will be replaced.
5. Locked schedule blocks manual creation.

**Implementation note:** CRUD exists with basic validation. There is no source flag, no consistency check and no lock guard. A manual row is hard-deleted by the next compute’s wipe, silently. CF-48.

---

#### STD-MSG-050 — Exam line-item visibility
**Priority:** P2 · **Tier:** Standard · **Status:** Implemented

The school can inspect the raw exam evidence behind a subject result.

**Rules**
- Show exam type, marks obtained, maximum, derived status and source result id.
- Only rows for the selected schedule and student are shown.
- A null marks value means “not attempted or absent” and is labelled, not shown as zero.
- The line items reconcile to `exam_weighted_total` after weightage.
- No edit is offered; the source LMS owns the mark.

**Acceptance**
1. Open a subject’s exam breakdown; each exam type appears.
2. An absent paper is labelled ABSENT.
3. The weighted combination of the line items equals the stored exam-weighted total within rounding.
4. No edit control is present.
5. A source result id links back to the LMS record where available.

**Implementation note:** Read-only index/show exist. The stored `result_status` can mark a whole exam type ABSENT when only one paper was absent, so the label can overstate absence. The source id is the maximum result id, not a per-paper list.

---

### 5.5 Output and reporting requirements

#### STD-MSG-060 — Schedule export
**Priority:** P2 · **Tier:** Standard · **Status:** Implemented

The coordinator can export a schedule’s computed results to Excel.

**Rules**
- Export includes one row per student with identity, section, totals, percentage, grade, division, rank, promotion and status.
- Export respects the schedule, not the current screen filter.
- Withheld results are included with their status and reason, clearly marked.
- The file name identifies the schedule.
- Export requires `msh-marksheet-schedule.export`.
- Export is read-only and does not change status.

**Acceptance**
1. Export a computed schedule; the workbook opens with the expected columns.
2. A withheld student is marked.
3. The row count equals the result count for the schedule.
4. A user without export permission is denied.
5. Exporting a draft schedule with no results produces an empty but valid file.

**Implementation note:** `MarksheetScheduleExport` exists and is wired. Column completeness should be verified against the requirement; the export is schedule-scoped.

---

#### STD-MSG-061 — Student result export
**Priority:** P1 · **Tier:** Standard · **Status:** Implemented

A single student’s subject matrix can be exported to Excel.

**Rules**
- One row per subject with exam weighted, theory, practical, homework, quiz, quest, IA, total, max, percentage, grade and pass.
- Scoped to the result’s schedule and student.
- Headers are human-readable; subject names are preferred over ids.
- Export requires `msh-student-result.export`.

**Acceptance**
1. Export a student result; every subject appears once.
2. Values match the on-screen subject table.
3. A second schedule for the same student is not mixed in.
4. The file name identifies the result.

**Implementation note:** Implemented. The export selects `subject_id`, not the subject name, so the workbook is less readable than the screen. This is a presentation gap, not a correctness gap.

---

#### STD-MSG-062 — Print preview and template resolution
**Priority:** P0 · **Tier:** Standard · **Status:** Implemented

Print renders the school’s marksheet design with the student’s computed data.

**Rules**
- Resolve a `MARKSHEET_PRINT` template assignment for the result’s class and session.
- If no class-specific assignment exists, fall back to the template type’s default layout. Print must never fail for lack of an assignment.
- Do not use a school-wide assignment that points to a non-marksheet document.
- Bind the result, not the raw student, so term-specific variables resolve.
- The rendered HTML is shown in a print-friendly view.
- Print requires `msh-student-result.print`.
- A result with no computed marks produces a clear message, not a blank page.

**Acceptance**
1. A class with a `MARKSHEET_PRINT` assignment prints that design.
2. A class without an assignment prints the type default.
3. A school-wide certificate assignment does not hijack the marksheet.
4. Variables show the correct term, subjects and totals.
5. A missing template shows an actionable error.

**Implementation note:** Implemented via `MarksheetTemplateResolver` and `Template::for($studentResult, 'MARKSHEET', [], $templateId)`. The resolver intentionally ignores school-wide assignments to avoid a known certificate bug. The template context is student-scoped (`SELF = student_id`), which is unambiguous only while a student has one result row; a second schedule makes variables ambiguous. CF-40.

---

#### STD-MSG-063 — PDF generation
**Priority:** P1 · **Tier:** Standard · **Status:** Partial / contradicted

The school can download a PDF of the marksheet that preserves the print formatting and signatures.

**Rules**
- The PDF must be generated from the same resolved template as print.
- Browser-side generation is acceptable if it preserves layout; server-side generation is acceptable if it preserves fonts and images.
- The PDF action must be reachable from the result screen.
- A failed generation shows an actionable message.
- PDF generation does not alter the result.
- The chosen mechanism is documented and tested in the supported browsers.

**Acceptance**
1. Click PDF; a file downloads.
2. The PDF matches the print preview.
3. Signatures and images are present.
4. A missing template produces a clear error.
5. The action is visible on the result screen.

**Implementation note:** The documented mechanism is browser-side `html2pdf`. The PDF button in `student-result/show.blade.php` is **commented out**. The `/pdf` route does not generate a file; it validates the template and redirects to print with `download=1&auto=1`, relying on the print view’s script. A large amount of server-side DomPDF preparation code exists but is not on the active path. This is a partial implementation with contradictory evidence (CF-34).

---

#### STD-MSG-064 — Computation log viewer
**Priority:** P1 · **Tier:** Standard · **Status:** Implemented

Authorised users can inspect computation and lifecycle history.

**Rules**
- List logs by schedule, newest first.
- Show action, status, actor, start, completion, duration, student count, error count and remarks.
- Show the full error log for a failed or partial run.
- Read-only; no edit or delete.
- Filter by schedule and action.
- Requires `msh-computation-log.view`.

**Acceptance**
1. Open the log for a schedule; compute and publish rows appear.
2. A failed run shows its error text.
3. An unlock shows the reason in remarks.
4. Logs cannot be edited or deleted.
5. A user without permission is denied.

**Implementation note:** Index/show exist. The status vocabulary mismatch (`RUNNING`, `BLOCKED`) and newline error text reduce readability, and the UI may not render the undocumented values with the intended colour. CF-36.

---

#### STD-MSG-065 — Dashboard metrics
**Priority:** P1 · **Tier:** Standard · **Status:** Implemented

The dashboard shows live counts of configuration and computed output, plus recent schedules and results.

**Rules**
- Counts: marksheet types (total/active), config templates (total/active), schedules (total/active), student results, schedule classes, practical configs, subject results, IA marks and co-scholastic results.
- Recent schedules: five most recent with template and status.
- Recent results: five most recent with student and section.
- Counts are live on each page load.
- Soft-deleted rows are excluded from “total” counts unless the label says otherwise.
- The dashboard is permission-gated.

**Acceptance**
1. The counts match direct database queries for the tenant.
2. A new schedule appears in Recent Schedules.
3. A computed result appears in Recent Results.
4. Deleting a result reduces the count.
5. A user without dashboard permission is denied.

**Implementation note:** Implemented. Several counts use `Model::count()` without `whereNull('deleted_at')`; because the models use SoftDeletes, Eloquent excludes trashed rows automatically, so the counts are correct. The “active” schedule count uses `is_active`, not lifecycle status, which can confuse “active” with “published”. Labels should distinguish.

---

#### STD-MSG-066 — User feedback and error surfacing
**Priority:** P1 · **Tier:** Standard · **Status:** Implemented

Every action returns a clear success or failure message, and domain failures are distinguishable from system failures.

**Rules**
- Validation errors are field-specific.
- Lifecycle violations return a domain message (“Only REVIEWED schedules can be published”).
- Unexpected exceptions are logged with context and return a generic message plus a correlation id.
- Success messages state what changed.
- A failed action never leaves a success flash.
- Destructive actions require confirmation.

**Acceptance**
1. Publish a draft; the message explains the required state.
2. Enter an invalid weight; the field is highlighted.
3. Force a database error; the user sees a generic failure and the log has the trace.
4. Delete an entity; a confirmation is required.
5. A successful action shows one success message.

**Implementation note:** Implemented broadly. Domain exceptions are caught and flashed; unexpected exceptions are logged and flashed generically. Correlation ids are not present. Some catches swallow the exception class and return a message that hides the cause, which slows support.

---

#### STD-MSG-067 — Advanced result consumer contract (target state)
**Priority:** P2 · **Tier:** Advanced · **Status:** Missing

A future parent/student portal and analytics layer must consume only published, declared results through a stable contract.

**Rules**
- A result is consumable only when the schedule is `PUBLISHED` or `LOCKED` and the student result is `DECLARED`.
- Withheld results are never returned to parent/student consumers.
- The contract exposes identity, term, subjects, grades, co-scholastic grades, attendance, totals, division, rank (if policy allows) and promotion (if final).
- The contract is versioned and read-only.
- Access is scoped to the authenticated student/guardian relationship.
- No raw exam line items are exposed to parents unless the school opts in.

**Acceptance**
1. A parent sees only their child’s declared results.
2. A withheld result returns “not available”, not a partial payload.
3. A draft or reviewed schedule returns nothing.
4. The payload includes the term and session.
5. Changing the internal schema does not break the versioned contract.

**Implementation note:** Not built. It is included because the current design has no consumer-facing publication marker (`result_status` is never set on publish), so the contract cannot be satisfied without fixing STD-MSG-030 first.

---

## 6. The ten correctness conditions — detailed interpretation

The module is only trustworthy if ten conditions hold. Each is stated as a condition, followed by why it matters, what the sources require, what the code does, and how to prove it.

### Condition 1 — Weightages must define a complete recipe before any mark is computed

**Condition.** A subject result exists only when the active scholastic source weights sum to 100% and the active exam-type weights sum to 100%, within a documented tolerance.

**Why it matters.** A missing weight is not a neutral omission. If `EXAM` is weighted 80 and the remaining 20 is unallocated, the student’s subject total is silently capped at 80 normalized points. If `EXAM` weights sum to 90, the exam component contributes at most 90 points. The report card looks plausible and is wrong. This is the most dangerous class of defect in a marksheet system because it is invisible without arithmetic.

**What the sources require.** The DDL comments state “Sum of weightage_percent must = 100” for both tables. The screen requirements state the sum “must not exceed 100%” for scholastic components and defer exam-type closure to compute time. The code enforces equality at compute.

**What the code does.** `validateScholasticWeightageSum()` and `validateExamWeightageSum()` sum active, non-deleted rows and throw when `abs(sum - 100) > 0.01`. Computation calls both before writing anything. A failure writes a `FAILED` log and returns a partial result without touching results. This is correct.

**Failure modes if unguarded.**
- A template saved at 90% computes every student 10 points low.
- A template saved at 110% computes every student 10 points high.
- A template with no components computes zero and may still be published.
- A template edited after review but before publish changes the recipe without a new review.

**Acceptance evidence.**
1. A 95% scholastic configuration blocks compute with the observed sum.
2. A 105% exam configuration blocks compute with the observed sum.
3. An empty component set blocks compute.
4. No result row is written by a blocked run.
5. The failure is visible in `msh_computation_logs`.

**Open point.** “Equals 100” versus “does not exceed 100” is a genuine product question. Equality is the current contract; Section 16 asks the school to confirm it.

---

### Condition 2 — Missing evidence must not be treated as zero

**Condition.** When a source has no evidence for a student, it is excluded from both the numerator and the denominator. It is never multiplied by zero as if the student scored nothing.

**Why it matters.** Consider a school that weights Exam 80, Homework 10, Quiz 10. A student who joined after the quiz has no quiz evidence. Treating the quiz as zero produces 90/100 = 90%; excluding it produces 90/90 = 100% of the evidence that exists. The first is punitive and indefensible; the second is the documented null-safe behaviour. The trade-off is that different students can be compared on different maxima, so the effective maximum must be visible.

**What the sources require.** The DDL marks source columns nullable. The screen requirements say a missing mark is “not yet entered”. The code comments cite BR-MSG-019 null-safe weightage.

**What the code does.** `WeightageApplier::applySourceWeightages()` skips any null source in both numerator and denominator. `applyExamTypeWeightages()` does the same per exam type. `subject_max` stores the sum of the weights actually used. `IA` is computed as null when no IA marks exist. The behaviour is consistent.

**Failure modes if unguarded.**
- A missing exam is recorded as zero and a good student fails.
- A missing homework makes a subject look weak.
- An absent student is ranked last instead of being excluded.
- A subject with no evidence produces a grade instead of “not assessed”.

**Acceptance evidence.**
1. Exam 80 with Exam weight 80 and no other sources → 64/80 = 80%, not 64/100 = 64%.
2. A student with no evidence at all → subject percentage 0, but the result is flagged as incomplete rather than silently failed.
3. `subject_max` is stored and displayed.
4. A withheld source is excluded, not zeroed.
5. An absent exam is flagged, not converted to zero without a label.

**Gap.** The engine does not distinguish “no evidence because the student was absent” from “no evidence because the school did not enter it”. Both produce null. A completeness signal is required before publication (Section 16, OD-04).

---

### Condition 3 — Exam types combine by weight, and the result is a percentage

**Condition.** Each exam type is normalized to a percentage of its own maximum, then combined using the exam-type weight. Raw marks from papers with different maxima are never added directly.

**Why it matters.** A half-yearly paper out of 80 and a unit test out of 20 cannot be added as raw marks. Normalizing each to a percentage makes them commensurable; weighting then expresses policy.

**What the sources require.** The DDL describes `msh_template_exam_weightages` as the per-exam-type weight within the Exam component. The screen requirement examples weight Periodic Test 1 at 20%, Half-Yearly at 30% and Final at 50%.

**What the code does.** `ExamScoreReader` sums obtained and possible marks per exam type and returns a `ScoreResult`. `WeightageApplier::applyExamTypeWeightages()` computes `Σ(percent × weight) / 100`. The result is 0–100. The effective maximum for the exam portion is the sum of the weights used, not necessarily 100.

**Failure modes if unguarded.**
- Raw 70/80 plus 15/20 is treated as 85/100 instead of 87.5/100.
- A paper with a 200-mark maximum skews the term.
- A missing exam type is counted as zero.
- A weight of 30 is applied as 30 instead of 30%.

**Acceptance evidence.**
1. 72/80 → 90.00; 18/20 → 90.00; weights 50/50 → 90.00.
2. 72/80 → 90.00; 10/20 → 50.00; weights 50/50 → 70.00.
3. A 200-mark paper normalizes correctly.
4. The weighted total cannot exceed 100.
5. The line items reconcile to the weighted total.

---

### Condition 4 — Best-of-N is a policy switch with a defined effect on weights

**Condition.** When Best-of-N is enabled, the engine selects the student’s best N exam types by normalized percentage and averages them. When disabled, it uses the weighted combination.

**Why it matters.** “Best 2 of 3 periodic tests” is a common school policy. Implemented loosely, it can double-count, include absent tests, or ignore the remaining exam types that are supposed to carry weight.

**What the sources require.** The template has `is_best_of_n_enabled` and `best_of_n_count`; the DDL says “only best N unit test scores count”. The screen requirements expose the toggle and count but do not define interaction with exam-type weights.

**What the code does.** `applyExamTypeWeightagesBestOfN()` collects non-null percentages, sorts descending, takes the top N, and averages them. It **ignores exam-type weights entirely** and returns a maximum of 100. If Best-of-N is enabled on a template that also contains a final exam, the final exam competes with unit tests for a top-N slot.

**Failure modes if unguarded.**
- A final exam is dropped because two unit tests scored higher.
- A student with only one of three tests gets that one score as the whole exam component.
- The configured weights are silently ignored.
- The result is not comparable with a non-Best-of-N template.

**Acceptance evidence.**
1. Best 2 of 3 percentages 60, 80, 70 → 75.00.
2. A null/absent test is not selected.
3. Best-of-N is scoped to the intended exam types, not all exam types.
4. Weights are either applied to the selected set or explicitly documented as ignored.
5. A template with Best-of-N disabled uses the weighted path.

**Gap.** The implementation is mathematically defined but policy-ambiguous. Section 16 asks whether Best-of-N applies to all exam types or only unit tests, and whether weights still apply (OD-06).

---

### Condition 5 — Theory and practical are split from the same evidence, transparently

**Condition.** The theory and practical columns are derived from the weighted exam total in proportion to the configured maxima, and the report clearly states that they are allocated rather than read from separate papers.

**Why it matters.** A school expects the practical column to reflect the practical paper. The current engine cannot do that because `lms_exam_papers` has no practical flag. A proportional split is a reasonable approximation, but presenting it as real paper marks is misleading.

**What the sources require.** The practical configuration screen says the system “pulls practical marks from a separate internal assessment workflow and caps theory marks at the configured theory maximum”. The code does neither: it splits one combined total.

**What the code does.** `PracticalSplitter::split()` multiplies the weighted exam total by `theory_max / (theory_max + practical_max)` and the complementary ratio. It returns null practical when no practical is configured. It applies the same ratio to every student.

**Failure modes if unguarded.**
- Theory and practical do not sum to the exam total (rounding).
- A zero/zero configuration divides by zero.
- A student who skipped the practical still receives a practical score.
- The marksheet claims a practical mark that no teacher entered.

**Acceptance evidence.**
1. 80 weighted with 70/30 → 56/24.
2. 80 weighted with 100/0 → 80/null.
3. 0/0 → 80/null.
4. Theory + practical = exam total within 0.01.
5. The UI labels the split as allocated.

**Open point.** Whether the school accepts an allocated split or requires real per-paper practical evidence is a product decision (OD-07). If real evidence is required, the LMS exam paper model needs a practical flag and the reader needs a second query.

---

### Condition 6 — Grade resolution uses the template’s grading schema, with a defined scope precedence

**Condition.** A subject grade and an overall grade come from the grade bands selected by the template’s grading schema, using a documented scope precedence.

**Why it matters.** Two templates can legitimately use different grade scales — a primary template with A–E and a secondary template with A1–A2–B1. If the resolver ignores the template schema, both receive the same grade, and a board-specific scale cannot be honoured.

**What the sources require.** `msh_config_templates.grading_schema_id` is a required FK to `slb_grade_division_master`. The screen requirement says the grading schema defines how numeric marks convert to grades. The DDL says the same.

**What the code does.** `GradeResolver` queries active `GradeDivisionMaster` rows by `grading_type` (`GRADE` or `DIVISION`) and scope (`CLASS`, `BOARD`, `SCHOOL`), orders by scope precedence and then by `min_percentage` descending, and returns the first containing band. It **never filters by `grading_schema_id`**. Subject grades pass the class id; overall grades pass null, so only BOARD/SCHOOL bands apply.

**Failure modes if unguarded.**
- A primary and secondary template produce identical grades.
- A board-specific scale is ignored.
- A class-scoped band applies to subjects but not to the overall result, producing an inconsistent report card.
- A percentage outside all bands returns an em dash and may be treated as a pass by a naive consumer.

**Acceptance evidence.**
1. Two schemas with different bands produce different grades for the same percentage.
2. A class-scoped band overrides a school band for a subject.
3. The overall grade uses the template schema and the documented scope.
4. An unmatched percentage is explicit, not silently “—”.
5. The chosen band id is traceable from the result.

**Gap.** The schema binding is the single clearest schema-vs-code contradiction. Fixing it requires `GradeResolver` to accept the template’s schema id and filter bands accordingly, plus a decision on whether overall grades may use class scope (OD-08).

---

### Condition 7 — Pass/fail and promotion are explicit, not inferred from names

**Condition.** Subject pass/fail uses the template’s passing percentage. Promotion is computed only for an explicitly designated final result, with a documented failure limit.

**Why it matters.** Promotion is a high-stakes, irreversible academic decision. Inferring “final” from a free-text type code means renaming `ANNUAL` to `ANNUAL_RPT` can stop all promotion decisions without any error. Conversely, an over-broad code list can grant promotion on a term result.

**What the sources require.** The DDL says `promotion_status` applies only when `is_last_result_for_session = TRUE`, and that it should apply only to a final exam result, not a term or half-yearly. It does not define how “final” is identified. The screen requirement says promotion is “Promoted” or “Detained” and adds compartment logic in the DDL.

**What the code does.** `computeAndPersistOverall()` reads the marksheet type code and sets `is_last_result_for_session` when the uppercase code is one of `ANNUAL`, `FINAL`, `SESSION_FINAL`, `PROMOTION`. It then applies: zero failures → `PROMOTED`; failures ≤ `compartment_max_failures` → `COMPARTMENT`; otherwise `DETAINED`. `PLACED` is unreachable. Subject pass is `subject_percentage >= passing_percentage`.

**Failure modes if unguarded.**
- Renaming a type silently disables promotion.
- A term result with a code of `FINAL` grants promotion.
- A compartment limit of 0 means any failure detains, which may be intended but is not obvious.
- A subject percentage computed on a shrunken maximum passes a student who would fail on the full maximum.

**Acceptance evidence.**
1. Annual type → promotion computed.
2. Term type → promotion null.
3. 2 fails with limit 2 → COMPARTMENT.
4. 3 fails with limit 2 → DETAINED.
5. Renaming the type does not change the decision when an explicit “is final” setting is used.
6. A manual override is possible and audited.

**Gap.** The inference is undocumented in the requirements and brittle. Section 16 asks for an explicit final-result flag on the template or schedule (OD-10).

---

### Condition 8 — Ranking is dense, scoped and reproducible

**Condition.** Section rank is dense within a schedule and section; class rank is dense across all sections of the class in the same schedule.

**Why it matters.** Rank is printed on the report card and used for awards. A rank of 0 or a missing class rank is visibly wrong. A non-dense rank after a tie misstates every subsequent position.

**What the sources require.** The DDL documents `rank_in_section` as “dense ranking” and `rank_in_class` as “rank within class across all sections”. The student result screen shows a single “Rank” field.

**What the code does.** `RankCalculator::assignRanks()` orders by `grand_total` descending, increments the rank only when the total changes, and writes `rank_in_section`. It does **not** write `rank_in_class`; the insert sets it to `0`.

**Failure modes if unguarded.**
- Ties receive 1, 2, 3 instead of 1, 1, 2.
- Class rank is always 0.
- A recompute ranks a stale partial set.
- Withheld students are ranked and printed.

**Acceptance evidence.**
1. 90, 85, 85, 70 → 1, 2, 2, 3.
2. Class rank combines sections correctly.
3. Recompute recalculates both ranks.
4. Withheld students follow an explicit policy.
5. A null total is ranked last, not first.

**Gap.** Class rank is a missing P1 feature. The screen must not display a 0 as if it were a rank; it should show “—”.

---

### Condition 9 — Recompute is idempotent and preserves teacher input

**Condition.** A recompute from the same inputs produces the same outputs, without duplicates, and without destroying marks a teacher entered.

**Why it matters.** Corrections are normal. If a recompute deletes co-scholastic grades, the school must re-enter them every time a single exam mark changes. If it duplicates rows, totals double. If it leaves a partial set, a report card can mix two runs.

**What the sources require.** The DDL’s unique keys imply idempotency. The screen requirements treat IA marks and co-scholastic grades as inputs that teachers own. Recompute is described as a correction workflow.

**What the code does.** `wipePreviousResults()` hard-deletes student results, subject results, exam line items and **co-scholastic results** for the schedule, then rebuilds. IA marks and attendance are not deleted. The wipe runs before the class-section loop. A failure after the wipe can leave fewer results than before. Unique keys prevent duplicates.

**Failure modes if unguarded.**
- Manual co-scholastic grades disappear on every recompute.
- A failed recompute leaves no results at all.
- A partial recompute leaves a mixture that looks complete.
- Manual subject rows are deleted.
- A concurrent compute doubles work.

**Acceptance evidence.**
1. Compute twice; identical rows and totals.
2. Manual co-scholastic grade survives.
3. IA marks survive.
4. A forced failure does not leave a publishable mixed state.
5. A manual result row is not silently deleted without warning.

**Gap.** This is the most damaging as-built defect after template locking. The fix is to exclude `msh_student_coscholastic_results` from the wipe, upsert computed fields, and add a run-version or staging table for partial-run visibility (OD-11).

---

### Condition 10 — Publication is immutable and visibility is explicit

**Condition.** A published result cannot change without an audited unlock. Consumers see a result only when both the schedule is published/locked and the student result is declared.

**Why it matters.** A report card is a formal document. If a mark can change after publication with no trace, the school cannot defend it to a parent or a board. If the publication marker is missing, a portal either shows nothing or shows everything, including withheld results.

**What the sources require.** The BRD says “marksheets cannot be edited once published” and requires an unlock reason. The screen requirement says publish locks the template and lock makes the schedule immutable. The result screen defines `DECLARED` and `WITHHELD`.

**What the code does.** Publish sets the schedule status and locks the template, but does **not** set `result_status`. Lock sets `is_locked`, which blocks compute and withhold/declare. It does not block IA entry, co-scholastic entry, schedule edit or template edit. Unlock resets to `COMPUTED` and records a reason. No consumer contract exists.

**Failure modes if unguarded.**
- A parent portal filtering on `DECLARED` shows no results.
- A portal ignoring `DECLARED` shows withheld results.
- A teacher edits an IA mark after publication and a later recompute changes the issued result.
- A template edit changes the recipe for an already-published schedule.
- An unlock leaves stale `locked_at`/`locked_by`.

**Acceptance evidence.**
1. Publish sets `DECLARED` for every non-withheld result.
2. A withheld result stays `WITHHELD`.
3. All mark-entry paths reject `REVIEWED`/`PUBLISHED`/`LOCKED`.
4. All template write paths reject `is_locked = 1`.
5. Unlock validates the source state and clears lock metadata.
6. A consumer sees only declared results.

**Gap.** Every sub-condition except the schedule status change is missing or partial. This is the core remediation theme.

---

## 7. Business rules register

The legacy documents use a single `BR-MSG-###` sequence, but the sequence is **reused**: the same number means different things in the screen requirements, the DDL and the code comments. This register assigns a unique canonical ID by domain and maps the legacy number in Section 14.

### 7.1 Configuration rules

| ID | Rule | Priority | Source | Status |
|---|---|---|---|---|
| BR-MSG-C01 | Marksheet type code is globally unique. | P0 | Screen req. (legacy 022) | Implemented |
| BR-MSG-C02 | A marksheet type referenced by a template cannot be permanently deleted. | P0 | Screen req. (023) | Partial |
| BR-MSG-C03 | Only active marksheet types appear in template setup. | P1 | Screen req. (024) | Implemented |
| BR-MSG-C04 | IA component type code is globally unique. | P0 | Screen req. (015) | Implemented |
| BR-MSG-C05 | An IA type referenced by a template cannot be permanently deleted. | P0 | Screen req. (016) | Partial |
| BR-MSG-C06 | Only active IA types appear in component setup. | P1 | Screen req. (017) | Partial |
| BR-MSG-C07 | Class group code is globally unique. | P0 | Screen req. (001) | Implemented |
| BR-MSG-C08 | Class group membership is synchronised on save, restoring re-selected classes. | P1 | Screen req. (002) | Implemented |
| BR-MSG-C09 | A class group referenced by a template assignment cannot be permanently deleted. | P0 | Screen req. (003) | Partial |
| BR-MSG-C10 | Only active class groups appear in template assignment. | P1 | Screen req. (004) | Implemented |
| BR-MSG-C11 | Exam group code is unique within an academic session. | P0 | Screen req. (011) | Implemented |
| BR-MSG-C12 | Exam group membership is synchronised on save. | P1 | Screen req. (012) | Implemented |
| BR-MSG-C13 | When both exam-group dates are present, end date is on or after start date. | P1 | Screen req. (013) | Implemented |
| BR-MSG-C14 | An exam group referenced by a template cannot be permanently deleted. | P0 | Screen req. (014) | Partial |
| BR-MSG-C15 | Config template code is unique within an academic session. | P0 | Screen req. (005) | Implemented |
| BR-MSG-C16 | A template requires a session, marksheet type, exam group and grading schema. | P0 | DDL + screen req. | Partial (schema nullable) |
| BR-MSG-C17 | Template class assignments are synchronised on save, restoring re-selected targets. | P1 | Screen req. (007) | Implemented |
| BR-MSG-C18 | A template with schedules or components cannot be permanently deleted. | P0 | Screen req. (008) | Partial |
| BR-MSG-C19 | A locked template is immutable on every write path. | P0 | Screen req. (006) + DDL | Missing |
| BR-MSG-C20 | Practical configuration triplet (session, class, subject) is unique. | P0 | Screen req. (042) | Implemented |
| BR-MSG-C21 | Only active practical configurations are used in computation. | P0 | Screen req. (043) | Implemented |
| BR-MSG-C22 | A practical configuration used by computed results cannot be permanently deleted. | P1 | Screen req. (044) | Missing |
| BR-MSG-C23 | Practical configuration delete is soft and restore reactivates. | P2 | Screen req. (045) | Implemented |
| BR-MSG-C24 | A source, exam type, IA type or co-scholastic code cannot be mapped twice to one template. | P0 | DDL + screen req. | Implemented |
| BR-MSG-C25 | Component weightage is 0–100 with at most two decimals; maxima are ≥ 0. | P0 | Screen req. | Implemented |
| BR-MSG-C26 | A component used by computed results cannot be permanently deleted. | P1 | Screen req. | Partial |
| BR-MSG-C27 | Component delete is soft and restore reactivates. | P2 | Screen req. | Implemented |
| BR-MSG-C28 | Active scholastic source weightages sum to 100 ± 0.01. | P0 | DDL + code | Implemented at compute; save UX broken |
| BR-MSG-C29 | Active exam-type weightages sum to 100 ± 0.01. | P0 | DDL + code | Implemented at compute |
| BR-MSG-C30 | Only active components participate in computation and display. | P0 | DDL + code | Implemented |
| BR-MSG-C31 | Direct class assignment takes precedence over class-group assignment. | P1 | DDL comment | Implemented in resolver, unused by compute |
| BR-MSG-C32 | A template must belong to the same session as its schedule. | P0 | Derived from DDL | Missing |
| BR-MSG-C33 | Component setup must succeed incrementally; a partial total is a draft state, not an error. | P0 | Derived from workflow | Contradicted |
| BR-MSG-C34 | A template’s grading schema determines the grade bands used. | P0 | DDL + screen req. | Missing |

### 7.2 Scheduling and computation rules

| ID | Rule | Priority | Source | Status |
|---|---|---|---|---|
| BR-MSG-S01 | Schedule code is unique within an academic session. | P0 | Screen req. (018) | Implemented |
| BR-MSG-S02 | Schedule status changes only through lifecycle actions. | P0 | Screen req. (019) | Contradicted |
| BR-MSG-S03 | Compute is allowed only from DRAFT or COMPUTED. | P0 | Screen req. (019) | Implemented |
| BR-MSG-S04 | Compute is blocked when the schedule is locked. | P0 | Screen req. (019) | Implemented |
| BR-MSG-S05 | Only one computation may run per schedule. | P0 | Screen req. (020) | Partial (race) |
| BR-MSG-S06 | Review is allowed only from COMPUTED. | P0 | Screen req. (019) | Implemented |
| BR-MSG-S07 | Publish is allowed only from REVIEWED. | P0 | Screen req. (019) | Implemented |
| BR-MSG-S08 | Publish locks the linked template. | P0 | Screen req. (019) | Implemented |
| BR-MSG-S09 | Lock is allowed only from PUBLISHED. | P0 | Screen req. (019) | Implemented |
| BR-MSG-S10 | Unlock is allowed only from PUBLISHED or LOCKED. | P0 | Screen req. (019) | Missing |
| BR-MSG-S11 | Unlock requires a reason of at least 5 characters and is audited. | P0 | Screen req. (019) | Implemented |
| BR-MSG-S12 | A schedule with results or in a published/locked state cannot be deleted. | P0 | Screen req. (021) | Missing |
| BR-MSG-S13 | A class section appears at most once per schedule. | P0 | Screen req. (025) | Implemented |
| BR-MSG-S14 | Schedule-class mappings cannot change while the schedule is locked. | P0 | Screen req. (026) | Partial |
| BR-MSG-S15 | A mapping cannot be deleted after results exist for that section. | P1 | Screen req. (027) | Missing |
| BR-MSG-S16 | A schedule must have at least one active class-section mapping before compute. | P0 | Derived | Missing |
| BR-MSG-S17 | Schedule template and academic session must match. | P0 | Derived | Missing |
| BR-MSG-S18 | Compute must fail before writing when either weightage set is not 100. | P0 | DDL + code | Implemented |
| BR-MSG-S19 | Recompute must preserve manual IA, attendance and co-scholastic inputs. | P0 | Derived from ownership | Contradicted |
| BR-MSG-S20 | A partial run must not be reviewable or publishable as if complete. | P0 | Derived | Partial |
| BR-MSG-S21 | Precheck and compute must use the same session and subject resolution. | P1 | Derived | Contradicted |
| BR-MSG-S22 | Every compute/lifecycle action writes an immutable audit row. | P0 | DDL + screen req. | Implemented |
| BR-MSG-S23 | Audit status and action values must match the documented vocabulary. | P1 | DDL | Contradicted |
| BR-MSG-S24 | Unlock must not release the template lock. | P0 | Derived from BR-MSG-C19 | Implemented |
| BR-MSG-S25 | Unlock must clear stale lock metadata. | P2 | Derived | Missing |

### 7.3 Result rules

| ID | Rule | Priority | Source | Status |
|---|---|---|---|---|
| BR-MSG-R01 | One student result per student per schedule. | P0 | Screen req. (035) | Implemented |
| BR-MSG-R02 | One subject result per student × subject × schedule. | P0 | Screen req. (039) | Implemented |
| BR-MSG-R03 | One IA mark per student × subject × component × schedule. | P0 | Screen req. (032) | Implemented |
| BR-MSG-R04 | One co-scholastic grade per student × component × schedule. | P0 | Screen req. (028) | Implemented |
| BR-MSG-R05 | Auto-vs-manual co-scholastic source is visibly identified. | P1 | Screen req. (029) | Implemented |
| BR-MSG-R06 | Only active co-scholastic and IA rows are displayed and printed. | P1 | Screen req. (030, 033) | Implemented |
| BR-MSG-R07 | Result status transitions are Draft/Computed → Published, with Withheld from any state and Declare back to Published. | P0 | Screen req. (036) | Contradicted |
| BR-MSG-R08 | Withholding requires a reason of at least 5 characters. | P0 | Screen req. (036) | Implemented |
| BR-MSG-R09 | Only a WITHHELD result can be declared. | P0 | Screen req. (036) | Missing |
| BR-MSG-R10 | Student result deletion is direct, not soft. | P1 | Screen req. (037) | Contradicted |
| BR-MSG-R11 | Computed totals, percentages, grades and pass/fail are stored, not derived on read. | P0 | Screen req. (041) | Implemented |
| BR-MSG-R12 | The Subject Results tab is read-only. | P1 | Screen req. (040) | Partial |
| BR-MSG-R13 | BA auto-grade requires integration enabled and a locked period. | P1 | DDL + code | Implemented |
| BR-MSG-R14 | Attendance auto-population requires attendance data and is flagged. | P2 | DDL + code | Implemented |
| BR-MSG-R15 | Result status is null until publication/withholding. | P1 | DDL | Implemented |
| BR-MSG-R16 | Section rank is dense. | P1 | DDL + code | Implemented |
| BR-MSG-R17 | Class rank is dense across sections of the same class. | P1 | DDL | Missing |
| BR-MSG-R18 | Promotion applies only to an explicit final result. | P0 | DDL | Partial (inferred) |
| BR-MSG-R19 | Missing source evidence is excluded from numerator and denominator; effective maximum is stored and shown. | P0 | Derived + code | Implemented, under-signalled |
| BR-MSG-R20 | Recompute clears only computed outputs, never teacher inputs. | P0 | Derived | Contradicted |
| BR-MSG-R21 | Manual result and subject rows are distinguishable from computed rows. | P2 | Derived | Missing |
| BR-MSG-R22 | Bounds: marks ≥ 0 and ≤ component/exam maximum. | P0 | Screen req. | Partial |

### 7.4 Output rules

| ID | Rule | Priority | Source | Status |
|---|---|---|---|---|
| BR-MSG-O01 | Print resolves a class/session `MARKSHEET_PRINT` assignment, then the type default. | P0 | Code + BRD | Implemented |
| BR-MSG-O02 | A school-wide non-marksheet assignment must not hijack print. | P1 | Code comment | Implemented |
| BR-MSG-O03 | Print binds the result, not the student, so term context is explicit. | P0 | Code | Implemented |
| BR-MSG-O04 | A student must have one unambiguous result per print context. | P0 | Derived | Partial |
| BR-MSG-O05 | PDF preserves layout, signatures and images. | P1 | BRD | Partial |
| BR-MSG-O06 | Excel export is schedule-scoped or student-scoped and read-only. | P2 | Screen req. | Implemented |
| BR-MSG-O07 | Dashboard metrics are live and permission-gated. | P1 | Screen req. (009, 010) | Implemented |
| BR-MSG-O08 | Audit and computation logs are immutable. | P0 | DDL | Implemented |
| BR-MSG-O09 | Consumers see only published + declared results. | P0 | Derived | Missing |
| BR-MSG-O10 | Every user action yields a clear success or domain error. | P1 | BRD | Implemented |

---

## 8. Workflows

Each workflow states the actor, preconditions, steps, outputs and failure handling. Where the as-built flow differs, the difference is noted at the end of the workflow.

### 8.1 Academic-year master setup

**Actor:** Examination Coordinator / School Admin
**Trigger:** Start of a new academic session
**Preconditions:** Classes, sections, subjects and the organization session exist.

1. Confirm the current organization academic session and its link to the global session.
2. Create or update marksheet types (Unit Test, Term-1, Annual).
3. Create or update IA component types (Notebook, Subject Enrichment, Periodic Assessment, Participation).
4. Create class groups and assign member classes.
5. Create exam groups for the session and select their exam types.
6. Set the exam-group date windows.
7. Verify that the seeded source components exist (Exam, Homework, Quiz, Quest).
8. Confirm that every active class group that will be used has at least one class.

**Output:** A reusable vocabulary for templates.
**Failure handling:** A missing session blocks all template creation. A missing exam type blocks exam-group membership. The screen reports which prerequisite is missing.
**As-built:** All steps exist. The source-component list is seeded but not school-editable through a dedicated screen.

### 8.2 Config template assembly

**Actor:** Examination Coordinator
**Trigger:** The grading policy for a class band is known.
**Preconditions:** At least one active marksheet type, exam group, grading schema and academic session.

1. Open Configuration → Config Templates → Add.
2. Enter code, name, description and board code.
3. Select the academic session, marksheet type, exam group and grading schema.
4. Set passing percentage and compartment maximum failures.
5. Optionally enable Best-of-N and set the count.
6. Add class and class-group assignments.
7. Save; the code uniqueness is validated within the session.
8. Open the template detail page to confirm the header and assignments.

**Output:** A template shell that is not yet computation-ready.
**Failure handling:** Duplicate code, invalid session, missing type or invalid pass percentage blocks the save with a field message.
**As-built:** The template saves with a null grading schema despite the DDL. Class assignments are saved but not used by compute.

### 8.3 Component and weightage setup

**Actor:** Examination Coordinator
**Trigger:** A template shell exists.
**Preconditions:** Source components, exam types and IA types are active.

1. Open Components → Scholastic Components.
2. Add `EXAM` with its weight and optional maximum.
3. Add `HOMEWORK`, `QUIZ` and `QUEST` with their weights.
4. Confirm the active total is exactly 100.
5. Open Exam Weightages and add each exam type with its weight.
6. Confirm the exam total is exactly 100.
7. Open IA Components and attach Notebook, Portfolio, Viva with maxima and order.
8. Open Co-scholastic Components and attach Behaviour, Art, Health with scales and BA links.
9. Return to the template detail page and confirm all four sections are populated.

**Output:** A computation-ready template.
**Failure handling:** A non-100 total must be shown as an incomplete draft, not as a save failure that prevents further editing.
**As-built defect:** Step 2 fails unless the first weight is exactly 100, because the service validates the sum after inserting the first row. The user cannot reach step 4 through the UI for an 80/10/10 recipe. The workaround is a single 100% `EXAM` row, then edit it and add the others — but editing also validates post-save, so the intermediate state fails. In practice only the seeder or direct SQL can build a multi-source template. This is the highest-priority UX/correctness fix.

### 8.4 Class assignment

**Actor:** Examination Coordinator
**Trigger:** A template is ready to target classes.
**Preconditions:** Active classes and class groups exist.

1. Edit the template.
2. Add a class group (for example Secondary 9–10) and/or specific classes.
3. Save; the assignment junction is synchronised.
4. Verify the template detail page lists the targets.
5. Confirm no class is targeted by two templates with conflicting intent.

**Output:** A documented applicability map.
**Failure handling:** A missing class or group blocks the row. Removing an assignment soft-deletes it.
**As-built:** Implemented. The computation engine ignores this map, so the map is documentation only. If the school expects the schedule to inherit its template from the class assignment, it will not.

### 8.5 Practical configuration

**Actor:** Examination Coordinator
**Trigger:** A class has a subject with a practical component.
**Preconditions:** Session, class and subject exist.

1. Open Scheduling → Practical Configs → Add.
2. Select session, class and subject.
3. Enable “Has Practical”.
4. Enter theory maximum and practical maximum.
5. Save; the triplet uniqueness is validated.
6. Repeat for each practical subject.
7. For non-practical subjects, either omit the row or save `has_practical = 0` with theory 100 and practical 0.

**Output:** A split rule used by computation.
**Failure handling:** Duplicate triplet, negative marks or a missing reference blocks the save.
**As-built:** Implemented. The split is proportional allocation, not real paper evidence. A deleted configuration is not blocked by computed results.

### 8.6 Schedule creation

**Actor:** Examination Coordinator
**Trigger:** The term’s marks are ready to compile.
**Preconditions:** A computation-ready template and at least one class section with students.

1. Open Scheduling → Schedules → Add.
2. Enter a session-unique code and a descriptive name.
3. Select the template and the same academic session.
4. Set the intended schedule date.
5. Select one or more class sections.
6. Save; the schedule starts in `DRAFT` and the class mappings are created.
7. Open the schedule detail page.

**Output:** A draft schedule ready for precheck and compute.
**Failure handling:** Duplicate code, missing template/session or an invalid class section blocks the save.
**As-built:** The form offers every status and the request accepts `is_locked`; a user can create an already-published or locked schedule. The template/session match is not validated.

### 8.7 Precheck

**Actor:** Examination Coordinator
**Trigger:** A draft schedule exists.
**Preconditions:** The template has components; class sections have students.

1. Open the schedule and click Precheck.
2. Review template checks: exam group, grading schema, passing percentage, component counts and sums.
3. Review per-section checks: students, subjects, published exams, graded homework, published quizzes, IA marks.
4. Resolve red items (usually a missing weightage or missing evidence).
5. Re-run precheck until the configuration checks are green.
6. Proceed to compute.

**Output:** A diagnostic report; no data change.
**Failure handling:** Precheck is read-only and cannot fail the schedule. A red item is a warning.
**As-built:** Student counts use the wrong session id, and evidence counts are class-wide rather than section-wide. Precheck does not block compute.

### 8.8 Compute

**Actor:** Examination Coordinator
**Trigger:** Precheck is acceptable.
**Preconditions:** Schedule `DRAFT` or `COMPUTED`, unlocked, no running job.

1. Click Compute.
2. The controller validates status, lock and running-job state.
3. The job opens a `COMPUTE` log in `RUNNING`.
4. The engine validates template weightages.
5. The engine resolves the global session and loads class sections.
6. The engine clears prior computed outputs for the schedule.
7. For each class section, in a transaction, it enumerates students and subjects and computes each subject and overall result.
8. The engine assigns section ranks.
9. The engine writes co-scholastic rows and attendance summaries.
10. On success, it updates `last_computed_at`, `total_students` and status `COMPUTED`, and closes the log as `SUCCESS`.
11. On any section error, it closes the log as `PARTIAL` and leaves the status unchanged.

**Output:** Student, subject, exam line-item, co-scholastic and attendance rows.
**Failure handling:** A weightage failure is `FAILED` before any write. A locked schedule is `BLOCKED`. A section error is `PARTIAL`. The user sees the log and error text.
**As-built:** As described, with the destructive co-scholastic wipe and the partial-run ambiguity.

### 8.9 Review, publish and lock

**Actor:** Examination Coordinator (review), Principal (publish), Principal/Coordinator (lock)
**Trigger:** Compute succeeded and the results are acceptable.
**Preconditions:** Schedule `COMPUTED` for review; `REVIEWED` for publish; `PUBLISHED` for lock.

1. Open the schedule; verify totals and spot-check students.
2. Click Review; status becomes `REVIEWED`. Teachers should no longer edit marks.
3. The Principal reviews the summary and clicks Publish.
4. Publish sets status `PUBLISHED` and locks the template in one transaction.
5. Publish should mark every non-withheld result `DECLARED`.
6. After distribution, click Lock; status becomes `LOCKED`, `is_locked = 1`, and lock metadata is recorded.
7. Confirm the schedule is read-only and printable.

**Output:** A published, frozen result set.
**Failure handling:** A wrong source state is rejected with a domain message. A failure rolls back the whole action.
**As-built:** Review/publish/lock status transitions and template lock are implemented. Result declaration and post-review mark freezing are not.

### 8.10 Unlock, correct and republish

**Actor:** Principal / School Admin
**Trigger:** A published mark is wrong.
**Preconditions:** Schedule `PUBLISHED` or `LOCKED`.

1. Open the schedule and click Unlock.
2. Enter a reason of at least 5 characters.
3. Confirm; status becomes `COMPUTED`, `is_locked` is cleared, and the reason is logged.
4. Correct the source mark in the owning module, or correct an IA/co-scholastic mark directly.
5. Recompute; verify the corrected totals.
6. Review again.
7. Publish again; the template remains locked.
8. Lock again when distribution is complete.

**Output:** A corrected, republished result with an audit trail.
**Failure handling:** A missing reason blocks the action. A locked schedule cannot be corrected without unlock.
**As-built:** Unlock accepts any state and leaves stale lock metadata. Recompute destroys manual co-scholastic grades, so step 4 may lose work.

### 8.11 Withhold and declare a result

**Actor:** Front Office / Examination Coordinator
**Trigger:** A student has an administrative hold (fees, library, discipline).
**Preconditions:** The schedule is not locked.

1. Open Results → Student Results and locate the student.
2. Click Withhold.
3. Enter a reason of at least 5 characters.
4. Save; result status becomes `WITHHELD` and the reason is stored.
5. When the hold is cleared, open the same result and click Declare.
6. Save; status becomes `DECLARED`, the reason is cleared and the result is visible to consumers.

**Output:** A per-student visibility decision with an audit trail.
**Failure handling:** A missing reason blocks withholding. A locked schedule blocks both actions.
**As-built:** Works, but declare does not require the result to be withheld, and actor/timestamp columns are absent.

### 8.12 Print and export

**Actor:** Class Teacher / Front Office
**Trigger:** Results are published and a physical or digital copy is needed.
**Preconditions:** A computed result exists and the user has print/export permission.

1. Open the student result detail.
2. Click Print; the resolver finds the class/session `MARKSHEET_PRINT` assignment or falls back to the type default.
3. The Template engine renders the layout with the result context.
4. Review the print preview.
5. Click PDF (where enabled) to download, or use the browser’s print dialog.
6. Alternatively, click Export to download the subject matrix as Excel.
7. For a whole schedule, use the schedule export.

**Output:** A printable HTML page, an optional PDF, or an Excel file.
**Failure handling:** A missing template shows an actionable message. A result with no computed marks shows a message rather than a blank page.
**As-built:** Print works. PDF is a redirect to print with `download=1`, and the button is commented out. Excel works but uses subject ids.

### 8.13 Delete and restore

**Actor:** School Admin
**Trigger:** A configuration or result row is obsolete.
**Preconditions:** The entity is not protected by a lifecycle or reference.

1. Attempt delete on the entity.
2. The system checks lifecycle state, computed results and references.
3. If allowed, the row is soft-deleted (or hard-deleted for a student result per the requirement).
4. The row disappears from active lists but remains in the trash view.
5. Restore returns it to active state.
6. Force-delete removes it permanently when no reference blocks it.

**Output:** A clean active set with a recoverable trash.
**Failure handling:** A protected entity is blocked with a message naming the blocker.
**As-built:** Soft delete and restore exist broadly. The documented guards are mostly absent, and student results soft-delete despite the requirement.

### 8.14 Failure recovery

**Actor:** Examination Coordinator / Engineer
**Trigger:** A compute or lifecycle action fails.
**Preconditions:** Access to the computation log and the source modules.

1. Open Computation Logs and find the failed run.
2. Read the error text and identify the class section or template check.
3. If the failure is configuration (weightage, template), fix it and recompute.
4. If the failure is source data (missing exam, bad mark), fix it in the owning module and recompute.
5. If the failure is partial, determine which sections succeeded.
6. Recompute after the fix; verify row counts and totals.
7. If the schedule status is inconsistent, use an audited unlock or a controlled repair; do not edit status directly.

**Output:** A complete, consistent run.
**Failure handling:** A partial run must not be published. A failed run must not leave the schedule looking complete.
**As-built:** There is no run-version marker, so “which sections succeeded” requires manual inspection. Direct status edits through the schedule edit form are possible and dangerous.

---

## 9. Data requirements

### 9.1 Entity catalogue

The DDL contains **23 tables** although its header says “22 tables”. The physical count is authoritative.

| # | Table | Domain | Purpose | Key constraints | Est. rows |
|---:|---|---|---|---|---|
| 1 | `msh_marksheet_types` | Master | Report-card categories | `code` unique; soft delete | 5–8 / school |
| 2 | `msh_source_components` | Master | Assessment sources | `code` unique; fixed seed | 4 |
| 3 | `msh_ia_component_types` | Master | IA categories | `code` unique | 4–6 |
| 4 | `msh_class_groups` | Configuration | Marksheet class bands | `code` unique | 3–5 |
| 5 | `msh_class_group_items_jnt` | Configuration | Group ↔ class | unique `(group, class)` | 15–20 |
| 6 | `msh_exam_groups` | Configuration | Term exam bundles | unique `(session, code)` | 2–4 / session |
| 7 | `msh_exam_group_items_jnt` | Configuration | Group ↔ exam type | unique `(group, type)` | 6–12 / session |
| 8 | `msh_config_templates` | Configuration | Grading recipe | unique `(session, code)`; FKs | 3–6 / session |
| 9 | `msh_template_scholastic_components` | Configuration | Source weights | unique `(template, source)` | 3–4 / template |
| 10 | `msh_template_exam_weightages` | Configuration | Exam-type weights | unique `(template, exam type)` | 3–6 / template |
| 11 | `msh_template_ia_components` | Configuration | IA maxima/order | unique `(template, IA type)` | 2–4 / template |
| 12 | `msh_template_coscholastic_components` | Configuration | Co-scholastic areas | unique `(template, code)` | 3–5 / template |
| 13 | `msh_class_config_jnt` | Configuration | Template ↔ class/group | CHECK exactly one target; no unique key | 10–20 / session |
| 14 | `msh_subject_practical_configs` | Configuration | Theory/practical split | unique `(session, class, subject)` | 5–15 |
| 15 | `msh_marksheet_schedules` | Schedule | Computation event | unique `(session, code)`; status FK | 4–10 / session |
| 16 | `msh_schedule_class_jnt` | Schedule | Schedule ↔ class section | unique `(schedule, section)` | 5–20 / schedule |
| 17 | `msh_student_results` | Result | Overall result | unique `(schedule, student)` | 500–2,000 / schedule |
| 18 | `msh_student_subject_results` | Result | Subject result | unique `(schedule, student, subject)` | 3K–15K / schedule |
| 19 | `msh_student_subject_exam_marks` | Result | Raw exam line items | unique `(schedule, student, subject, exam type)` | 15K–80K / schedule |
| 20 | `msh_student_ia_marks` | Result | IA component marks | unique `(schedule, student, subject, component)` | 6K–20K / schedule |
| 21 | `msh_student_coscholastic_results` | Result | Co-scholastic grades | unique `(schedule, student, component)` | 1.5K–3K / schedule |
| 22 | `msh_student_attendance` | Result | Attendance summary | unique `(schedule, student)` | 500–2K / schedule |
| 23 | `msh_computation_logs` | Audit | Immutable action log | no `deleted_at`; FKs | 10–30 / session |

### 9.2 Critical table detail

#### `msh_config_templates`

| Column | Type | Null | Notes |
|---|---|:---:|---|
| `id` | INT UNSIGNED | no | PK |
| `academic_session_id` | SMALLINT UNSIGNED | no | FK → `sch_org_academic_sessions_jnt.id`, RESTRICT |
| `marksheet_type_id` | INT UNSIGNED | no | FK → `msh_marksheet_types.id`, RESTRICT |
| `exam_group_id` | INT UNSIGNED | no | FK → `msh_exam_groups.id`, RESTRICT |
| `grading_schema_id` | INT UNSIGNED | **no in DDL** | FK → `slb_grade_division_master.id`, **SET NULL** (contradiction) |
| `code` | VARCHAR(50) | no | Unique with session |
| `name` | VARCHAR(150) | no | |
| `description` | VARCHAR(500) | yes | |
| `board_code` | VARCHAR(50) | yes | Informational |
| `passing_percentage` | DECIMAL(5,2) | no | Default 33.00 |
| `compartment_max_failures` | TINYINT UNSIGNED | no | Default 2 |
| `is_best_of_n_enabled` | TINYINT(1) | no | Default 0 |
| `best_of_n_count` | TINYINT UNSIGNED | yes | Required when enabled |
| `is_locked` | TINYINT(1) | no | Default 0; system-controlled |
| `is_active` | TINYINT(1) | no | Default 1 |
| audit | | | `created_by`, `updated_by`, timestamps, `deleted_at` |

**Integrity note:** `ON DELETE SET NULL` on a `NOT NULL` column is invalid intent. MySQL may reject the FK or silently allow a null write depending on configuration. The DDL should either make the column nullable or use `RESTRICT`.

#### `msh_marksheet_schedules`

| Column | Type | Null | Notes |
|---|---|:---:|---|
| `id` | INT UNSIGNED | no | PK |
| `config_template_id` | INT UNSIGNED | no | FK → template, RESTRICT |
| `academic_session_id` | SMALLINT UNSIGNED | no | FK → org session, RESTRICT |
| `code` | VARCHAR(50) | no | Unique with session |
| `name` | VARCHAR(150) | no | |
| `schedule_date` | DATE | yes | Intended issue date |
| `status_id` | INT UNSIGNED | no | FK → `sys_dropdown_table.id`, RESTRICT |
| `last_computed_at` | DATETIME | yes | Last run |
| `total_students` | INT UNSIGNED | yes | Processed count |
| `is_locked` | TINYINT(1) | no | Default 0 |
| `locked_at` / `locked_by` | DATETIME / INT | yes | Lock provenance |
| `unlock_reason` | TEXT | yes | Mandatory on unlock |
| `unlocked_at` / `unlocked_by` | DATETIME / INT | yes | Unlock provenance |
| audit | | | standard |

**Missing:** `published_at`, `published_by`, `reviewed_at`, `reviewed_by`. These are only reconstructable from `msh_computation_logs`.

#### `msh_student_results`

| Column | Type | Null | Notes |
|---|---|:---:|---|
| `id` | INT UNSIGNED | no | PK |
| `schedule_id` | INT UNSIGNED | no | FK → schedule, CASCADE |
| `student_id` | INT UNSIGNED | no | FK → student, RESTRICT |
| `class_section_id` | INT UNSIGNED | no | Denormalized |
| `grand_total` | DECIMAL(8,2) | yes | Sum of subject totals |
| `grand_max` | DECIMAL(8,2) | yes | Sum of subject maxima |
| `overall_percentage` | DECIMAL(5,2) | yes | |
| `overall_grade` | VARCHAR(10) | yes | |
| `division` | VARCHAR(30) | yes | |
| `rank_in_section` | SMALLINT UNSIGNED | yes | Dense |
| `rank_in_class` | SMALLINT UNSIGNED | yes | Not populated |
| `total_subjects` | TINYINT UNSIGNED | yes | |
| `subjects_passed` / `subjects_failed` | TINYINT UNSIGNED | yes | |
| `is_last_result_for_session` | TINYINT UNSIGNED | no | Default 0 |
| `promotion_status` | VARCHAR(30) | yes | PROMOTED, DETAINED, COMPARTMENT, PLACED |
| `result_status` | VARCHAR(20) | yes | DECLARED, WITHHELD |
| `withheld_reason` | VARCHAR(255) | yes | |
| audit | | | standard, including soft delete |

**Missing:** `withheld_at`, `withheld_by`, `declared_at`, `declared_by`, `run_id`/`computation_log_id`. Without a run id, a result cannot be tied to the exact computation that produced it.

#### `msh_student_subject_results`

Stores `exam_weighted_total`, `theory_marks`, `practical_marks`, `homework_score`, `quiz_score`, `quest_score`, `ia_total`, `subject_total`, `subject_max`, `subject_percentage`, `subject_grade`, `is_passed`. All score columns are nullable. Unique `(schedule, student, subject)`. **All scores are normalized 0–100 values or weighted points, not raw school marks.**

#### `msh_student_subject_exam_marks`

Stores `marks_obtained`, `max_marks`, `result_status`, `exam_result_id` per `(schedule, student, subject, exam_type)`. This is the only table that preserves raw exam evidence. `result_status` is derived at compute time and can overstate absence for an aggregate of papers.

#### `msh_student_ia_marks`

Stores `marks_obtained`, `max_marks`, `entered_by`, `entered_at` per `(schedule, student, subject, template IA component)`. `max_marks` is copied at entry. This is teacher input and must survive recompute.

#### `msh_student_coscholastic_results`

Stores `grade`, `remarks`, `entered_by`, `entered_at`, `is_auto_from_ba` per `(schedule, student, component)`. This is teacher input for manual rows and computed output for auto rows. The current recompute deletes both.

#### `msh_computation_logs`

Stores `action`, `triggered_by`, `started_at`, `completed_at`, `duration_seconds`, `total_students`, `total_errors`, `status`, `error_log`, `remarks`. No `deleted_at`. Intended as an immutable audit trail.

### 9.3 Data quality rules

| Rule | Applies to | Enforcement |
|---|---|---|
| Every required FK exists | All tables | DDL FK |
| Codes unique where declared | Types, groups, templates, schedules | DDL unique |
| One result per student per schedule | `msh_student_results` | DDL unique |
| One subject result per student × subject × schedule | `msh_student_subject_results` | DDL unique |
| One IA mark per component context | `msh_student_ia_marks` | DDL unique |
| One co-scholastic grade per component context | `msh_student_coscholastic_results` | DDL unique |
| One attendance summary per student per schedule | `msh_student_attendance` | DDL unique |
| Weightage ranges 0–100 | Template components | Request validation |
| Weightage sums 100 | Template components | Service/compute |
| Marks ≥ 0 and ≤ max | IA, exam, subject | Request validation (partial) |
| `days_present <= total_working_days` | Attendance | **Not enforced** |
| `end_date >= start_date` | Exam groups | Request validation |
| Exactly one class/group target | `msh_class_config_jnt` | DDL CHECK |
| Academic session consistency (template ↔ schedule) | Schedule | **Not enforced** |
| No duplicate class assignment for a template | `msh_class_config_jnt` | **Not enforced** |
| Result belongs to a schedule in the same session as the student | Results | **Not enforced** |

### 9.4 Privacy and consent

- Student names, admission numbers, marks, grades, ranks and promotion decisions are personal academic data.
- Access is role-based; parents/students, when added, must see only their own declared result.
- Withheld reasons can contain sensitive financial or disciplinary information; they must not be exposed to parent/student consumers.
- Behavioural-assessment grades are sensitive; only the derived grade is exposed, not the underlying observations.
- Attendance percentages are personal data and follow the same access rules.
- Exports create uncontrolled copies; the school must define a retention and sharing policy.
- Print previews may be cached by the browser; shared terminals must clear them.

### 9.5 Retention

| Data | Retention | Rationale |
|---|---|---|
| Computed results | Life of the academic session + statutory retention | Report card evidence |
| Exam line items | Same as results | Traceability to LMS evidence |
| IA and co-scholastic marks | Same as results | Teacher evidence |
| Attendance summaries | Same as results | Report card evidence |
| Computation logs | At least the statutory audit period | Dispute and audit |
| Templates and components | Retained even when inactive | Reproduce historical results |
| Soft-deleted configuration | Until force-deleted | Recoverability |
| Trash for results | Per school policy; hard delete preferred for erroneous drafts | Avoid stale re-association |

**Rule:** A template used by a published schedule must never be hard-deleted, even after the session ends, because the result cannot be explained without its recipe.

---

## 10. Reporting and analytics

### 10.1 Foundation and Standard reports

| ID | Report | Audience | Content | As-built |
|---|---|---|---|---|
| RPT-MSG-001 | Dashboard | Coordinator, Admin | Counts of types, templates, schedules, results, subject results, IA marks, co-scholastic grades, practical configs; recent schedules and results | Implemented |
| RPT-MSG-002 | Schedule result register | Coordinator, Principal | One row per student: identity, section, total, max, percentage, grade, division, rank, promotion, status | Implemented as Excel export |
| RPT-MSG-003 | Student subject matrix | Teacher, Coordinator | One row per subject with all component scores, total, max, percentage, grade, pass | Implemented as Excel export |
| RPT-MSG-004 | Printed marksheet | School, parent | School-designed report card with subjects, co-scholastic, attendance, totals and signatures | Implemented |
| RPT-MSG-005 | Computation audit | Auditor, Admin | Every compute/lifecycle action with actor, time, duration, students, errors and remarks | Implemented viewer |
| RPT-MSG-006 | IA register | Class teacher, Coordinator | Per student × subject × component marks with maxima and entered-by | Implemented inline view |
| RPT-MSG-007 | Co-scholastic register | Class teacher, Coordinator | Per student × component grade, remarks and auto/manual source | Implemented inline view |
| RPT-MSG-008 | Attendance register | Coordinator | Working days, present days, percentage per student | Partial; no dedicated report |
| RPT-MSG-009 | Weightage compliance | Coordinator | Per template: active source and exam weight sums, component counts, readiness | Partial; only precheck |
| RPT-MSG-010 | Promotion / compartment list | Principal | Final-result students grouped by PROMOTED, COMPARTMENT, DETAINED | Missing |
| RPT-MSG-011 | Rank list | Principal, school | Section and class rank, ties, totals | Partial; class rank missing |
| RPT-MSG-012 | Missing evidence | Coordinator | Students/subjects with null exam, homework, quiz, IA or attendance | Missing |
| RPT-MSG-013 | Template usage | Admin | Templates with schedules, classes and lock state | Missing |
| RPT-MSG-014 | Withheld register | Front office | Withheld students, reasons, who and when | Partial; no who/when columns |
| RPT-MSG-015 | Subject performance | Principal | Average, pass rate, distribution by subject and section | Missing |

### 10.2 Advanced reports (target state)

| ID | Report | Why it matters | Dependency |
|---|---|---|---|
| RPT-MSG-020 | Longitudinal student progress | Compare a student across terms and sessions | A stable student result history and a published marker |
| RPT-MSG-021 | Section/subject comparison | Identify teaching or assessment gaps | Clean result data and a run id |
| RPT-MSG-022 | Grade distribution and moderation | Detect anomalous grading or weighting | Grade schema binding and historical bands |
| RPT-MSG-023 | Board-format compliance pack | Produce a board-specific extract | Configurable format mapping |
| RPT-MSG-024 | Anomaly detection | Flag impossible or suspicious mark patterns | Line-item history and statistical baselines |
| RPT-MSG-025 | Parent/student result view | Self-service access | Result declaration and a scoped API |

### 10.3 Reporting rules

- Every report must state its scope: session, schedule, class section and result status filter.
- A report that includes withheld students must label them; a parent-facing report must exclude them.
- A report must show the effective maximum when any source is missing, not assume 100.
- Exports must use human-readable subject and exam-type names, not ids.
- Computed values are read from stored results, not recalculated at report time, so a report matches what was published.
- A report must not expose behavioural observations, only derived grades.
- Report access is permission-gated and audited when it contains personal data.

---

## 11. Configuration catalogue

| ID | Parameter | Scope | Default | Owner | Status |
|---|---|---|---|---|---|
| CFG-MSG-001 | Passing percentage | Template | 33.00 | Coordinator | Implemented |
| CFG-MSG-002 | Compartment maximum failures | Template | 2 | Coordinator | Implemented |
| CFG-MSG-003 | Best-of-N enabled | Template | Off | Coordinator | Implemented |
| CFG-MSG-004 | Best-of-N count | Template | null | Coordinator | Implemented |
| CFG-MSG-005 | Board code | Template | null | Coordinator | Implemented, informational |
| CFG-MSG-006 | Grading schema | Template | required | Coordinator | Implemented in schema, ignored in code |
| CFG-MSG-007 | Template lock state | Template | unlocked | System | Implemented, unenforced |
| CFG-MSG-008 | Marksheet type list | School | seeded | Admin | Implemented |
| CFG-MSG-009 | IA type list | School | seeded 4 | Admin | Implemented |
| CFG-MSG-010 | Source component list | School | seeded 4 | System | Implemented, no IA |
| CFG-MSG-011 | Class group membership | School | empty | Coordinator | Implemented |
| CFG-MSG-012 | Exam group membership | Session | empty | Coordinator | Implemented |
| CFG-MSG-013 | Exam group date window | Session | null | Coordinator | Implemented, HW/Quiz/Quest only |
| CFG-MSG-014 | Scholastic source weights | Template | none | Coordinator | Implemented |
| CFG-MSG-015 | Exam-type weights | Template | none | Coordinator | Implemented |
| CFG-MSG-016 | IA maxima and order | Template | none | Coordinator | Implemented |
| CFG-MSG-017 | Co-scholastic areas and scales | Template | none | Coordinator | Implemented |
| CFG-MSG-018 | BA link per co-scholastic area | Template | off | Coordinator | Implemented |
| CFG-MSG-019 | Practical split per class-subject | Session | none | Coordinator | Implemented |
| CFG-MSG-020 | Schedule date | Schedule | null | Coordinator | Implemented |
| CFG-MSG-021 | Schedule lifecycle status | Schedule | DRAFT | System | Implemented, bypassable |
| CFG-MSG-022 | Unlock reason minimum length | Policy | 5 | System | Implemented |
| CFG-MSG-023 | Withhold reason minimum length | Policy | 5 | System | Implemented |
| CFG-MSG-024 | Weightage tolerance | System | 0.01 | System | Implemented |
| CFG-MSG-025 | Compute timeout | System | 1,800 s | Engineer | Implemented |
| CFG-MSG-026 | Compute retry count | System | 1 | Engineer | Implemented |
| CFG-MSG-027 | Queue connection | System | env | Engineer | Implemented |
| CFG-MSG-028 | BA integration enabled | External module | off | BA admin | Consumed |
| CFG-MSG-029 | BA integration weightage | External module | 5–20 | BA admin | Consumed but unused in academic total |
| CFG-MSG-030 | Attendance auto-population | System | on when data exists | System | Implemented |
| CFG-MSG-031 | Print template assignment | Template module | type default | Admin | Implemented |
| CFG-MSG-032 | Result visibility policy (withheld) | School | hidden | Principal | **Decision needed** |
| CFG-MSG-033 | Rank display policy | School | show | Principal | **Decision needed** |
| CFG-MSG-034 | Final-result designation | Template/schedule | inferred | Coordinator | **Decision needed** |
| CFG-MSG-035 | Soft-delete retention | School | indefinite | Admin | **Decision needed** |

**Configuration principles**
- A parameter that changes a computed number must be versioned or locked at publication.
- A parameter that changes visibility must be explicit, not inferred.
- External-module parameters (BA integration, grading schema) must be validated for existence at compute time, not assumed.
- A parameter with no enforcement point is documentation, not configuration.

---

## 12. Non-functional requirements

### 12.1 Performance

| Requirement | Target | As-built risk |
|---|---|---|
| Dashboard load | < 1.5 s for 2,000 results | Multiple `count()` queries; acceptable with indexes |
| Result list load | < 2 s per 15 rows | Eager loading present; filter lists use `distinct()` on results |
| Schedule compute | < 10 min for 500 students × 8 subjects | Per-subject readers and per-student writes; no chunking; 30-minute job timeout |
| Single student print | < 2 s | Template render dominates |
| Excel export | < 30 s for 2,000 rows | In-memory collection |
| Precheck | < 5 s per schedule | Several class-wide counts per section; can be slow on large tenants |

**Compute hot spots observed in code:**
- For every subject, five readers run; each reader re-resolves the class-section and re-queries enrolled students.
- For every student × subject, a subject row and multiple exam line items are inserted individually.
- `persistExamTypeLineItems()` inserts one row per exam type per student per subject.
- Co-scholastic upserts run per component × student.
- Attendance upsert runs per student.
- No batch insert, no chunking, no progress reporting.

**Required improvement:** resolve class/section/enrolment once per section, pass it to readers, batch-insert subject and line-item rows in chunks, and report progress through the log.

### 12.2 Scalability

- Row volume per schedule: up to 2,000 student results, 15,000 subject results and 80,000 exam line items. A session with eight schedules approaches 800,000 line items.
- The unique keys support efficient recompute deletes by `schedule_id`; ensure an index on `schedule_id` alone for each result table (the composite unique key starts with `schedule_id`, which is sufficient in MySQL).
- Computation is per schedule; two schedules can run concurrently but compete for the same source tables.
- A queue worker must be tenant-aware; the behavioural reader memoises by tenant key.
- The design has no partition or archive strategy; historical sessions should be archived by schedule.

### 12.3 Availability and resilience

- A compute failure must not corrupt previously published results. The current wipe-then-rebuild model violates this for the same schedule; a published schedule is protected only by the lock, which is the correct guard.
- A queue outage leaves the schedule unchanged; the user must see “queued” and be able to retry.
- A database deadlock during a class-section transaction rolls back that section; the run becomes `PARTIAL`.
- The module has no circuit breaker for a missing LMS table; readers should degrade to null evidence, not crash the run. `BehaviouralScoreReader` does; the others assume tables exist.
- An immutable audit log must survive application errors.

### 12.4 Security

- Every controller action is permission-gated. Verify that no route is missing a gate, especially the special lifecycle and export routes.
- Mass assignment: `MarksheetScheduleRequest` and `ConfigTemplateRequest` accept `is_locked` and `is_active`; these are system fields and must be removed from client input.
- Template IDs and schedule IDs are enumerable; policies must check tenant and, where relevant, class ownership. The current policies check permission only, not record ownership.
- Print and export expose personal data; log access and restrict bulk export.
- Formula injection: Excel exports must escape cells beginning with `=`, `+`, `-` or `@`.
- SQL injection: all queries use the query builder with bindings; no raw user input was found.
- XSS: print HTML comes from the Template module; ensure the template engine escapes student names and remarks.
- CSRF: lifecycle actions are POST within the auth middleware; verify no GET state change.

### 12.5 Privacy

- Collect only the data needed for a report card.
- Do not expose raw behavioural observations.
- Withheld reasons may contain sensitive context; restrict to authorised staff.
- Provide a retention and deletion policy consistent with the school’s legal obligations.
- Parent/student access must be scoped by relationship, not by guessable id.
- Exports and print previews are uncontrolled copies; warn the user.

### 12.6 Usability

- A coordinator must be able to build a template from zero to computation-ready without SQL. The current weightage save validation breaks this (CF-13).
- A blocked compute must say exactly which check failed and what to change.
- The schedule page must show the lifecycle state, the last compute, the template lock state and the next allowed action.
- The result page must distinguish “not assessed” from “zero”.
- The print preview must be reachable in one click from the result list.
- The dashboard must distinguish active configuration from published results.

### 12.7 Auditability

- Every lifecycle action, mark entry and configuration change is attributable to a user and a timestamp.
- Computation logs are immutable and readable.
- Results must be traceable to the exact computation run; the current schema lacks a run id.
- Withhold/declare must record who and when; the current schema lacks dedicated columns.
- Template locks must record when and by which publish.
- Deletion of results and configurations must leave an audit trace.

### 12.8 Maintainability

- The module has a clear service layer (`MarksheetComputationService`, `WeightageApplier`, `GradeResolver`, `PracticalSplitter`, `RankCalculator`, readers) and thin controllers. Preserve this separation.
- The computation service is 759 lines and mixes orchestration, persistence and enumeration. Extract a `SubjectResultPersister`, `StudentEnumerator` and `CoScholasticWriter`.
- Add unit tests for weightage, grade, practical split and rank; integration tests for the full pipeline with a seeded tenant.
- Document the normalized-point contract in code and UI.
- Replace hard-coded type-code lists and status strings with constants or lookup ids.
- Align DDL comments, migrations and code vocabulary.

### 12.9 Compatibility

- MySQL 8.0.32+.
- PHP 8.2+ with Laravel 11 conventions used by the module.
- Supported browsers: current Chrome, Edge, Firefox and Safari. Browser-side PDF must be tested in each.
- Print layout depends on the Template module’s HTML/CSS; test A4 and Letter.

### 12.10 Accessibility and localisation

- Print and on-screen tables must have meaningful headers and sufficient contrast.
- Status must not be conveyed by colour alone; use text badges.
- Dates should follow the school’s locale; the database stores ISO dates.
- Grade labels may be localised; store the code and display the label.
- Numeric formatting must respect the school’s decimal and thousands conventions.

---

## 13. Capability and build-status mapping

| Requirement | Capability | Layer | Status | Primary evidence |
|---|---|---|---|---|
| FND-MSG-001 | Marksheet types | Core | Implemented | `MarksheetTypeController`, table 1 |
| FND-MSG-002 | IA types | Core | Implemented | `IaComponentTypeController`, table 3 |
| FND-MSG-003 | Source components | Core | Implemented, seed gap | Seeder, table 2 |
| FND-MSG-004 | Class groups | Core | Implemented | `ClassGroupService`, tables 4–5 |
| FND-MSG-005 | Exam groups | Core | Implemented | `ExamGroupService`, tables 6–7 |
| FND-MSG-006 | Config templates | Core | Implemented, schema conflict | `ConfigTemplateService`, table 8 |
| FND-MSG-007 | Class assignment | Core | Implemented, unused | `MarksheetConfigService`, table 13 |
| FND-MSG-008 | Practical configs | Core | Implemented | `SubjectPracticalConfigService`, table 14 |
| FND-MSG-009 | Session binding | Core | Partial | `MarksheetComputationService`, precheck |
| FND-MSG-010 | Navigation and permissions | Core | Implemented, inconsistent | Combined controllers, permission list |
| STD-MSG-001 | Scholastic weights | Standard | Implemented, non-incremental | `TemplateScholasticComponentService` |
| STD-MSG-002 | Exam weights | Standard | Implemented | `TemplateExamWeightageService` |
| STD-MSG-003 | Template IA | Standard | Implemented | `TemplateIaComponentService` |
| STD-MSG-004 | Template co-scholastic | Standard | Implemented | `TemplateCoscholasticComponentService` |
| STD-MSG-005 | Template lock enforcement | Standard | Missing | `MarksheetConfigService::lockTemplate` only |
| STD-MSG-006 | Template snapshot | Standard | Implemented | `loadTemplateData()` |
| STD-MSG-007 | Weightage closure | Standard | Implemented | `validate*WeightageSum()` |
| STD-MSG-008 | Configuration audit | Standard | Partial | `activityLog()` calls |
| STD-MSG-010 | Schedule master | Standard | Implemented, bypassable | `MarksheetScheduleService` |
| STD-MSG-011 | Schedule classes | Standard | Implemented, unguarded | `syncClassSections()` |
| STD-MSG-012 | Precheck | Standard | Implemented, advisory | `MarksheetScheduleController::precheck` |
| STD-MSG-013 | Compute gating | Standard | Implemented | `compute()` + `ComputeMarksheetJob` |
| STD-MSG-014 | Student/subject enumeration | Standard | Implemented | `computeForClassSection()` |
| STD-MSG-015 | Exam ingestion | Standard | Implemented | `ExamScoreReader` |
| STD-MSG-016 | Homework ingestion | Standard | Implemented | `HomeworkScoreReader` |
| STD-MSG-017 | Quiz/quest ingestion | Standard | Implemented | `QuizScoreReader`, `QuestScoreReader` |
| STD-MSG-018 | IA computation | Standard | Implemented, excluded | `computeSubjectResult()` |
| STD-MSG-019 | Co-scholastic + BA | Standard | Implemented, destructive | `computeForClassSection()` |
| STD-MSG-020 | Attendance | Standard | Implemented | `std_student_attendance` upsert |
| STD-MSG-021 | Practical split | Standard | Implemented, approximate | `PracticalSplitter` |
| STD-MSG-022 | Subject assembly | Standard | Implemented | `WeightageApplier` |
| STD-MSG-023 | Overall result | Standard | Implemented | `computeAndPersistOverall()` |
| STD-MSG-024 | Promotion | Standard | Implemented, inferred | type-code list |
| STD-MSG-025 | Ranking | Standard | Partial | `RankCalculator` |
| STD-MSG-026 | Idempotency | Standard | Partial, destructive | `wipePreviousResults()` |
| STD-MSG-027 | Computation logging | Standard | Implemented, mismatch | `open/closeComputationLog()` |
| STD-MSG-028 | Partial failure | Standard | Partial | per-section try/catch |
| STD-MSG-029 | Review | Standard | Implemented | `lifecycle->review()` |
| STD-MSG-030 | Publish + template lock | Standard | Implemented, incomplete | `lifecycle->publish()` |
| STD-MSG-031 | Lock | Standard | Implemented | `lifecycle->lock()` |
| STD-MSG-032 | Unlock | Standard | Implemented, permissive | `lifecycle->unlock()` |
| STD-MSG-040 | Student result list | Standard | Implemented | `results()` combined page |
| STD-MSG-041 | Result detail | Standard | Implemented | `StudentResultController::show` |
| STD-MSG-042 | Subject view | Standard | Implemented | subject-results tab |
| STD-MSG-043 | IA entry | Standard | Implemented, unguarded | `StudentIaMarkController` |
| STD-MSG-044 | Co-scholastic entry | Standard | Implemented, unguarded | `StudentCoscholasticResultController` |
| STD-MSG-045 | Attendance entry | Standard | Implemented | `StudentAttendanceController` |
| STD-MSG-046 | Withhold | Standard | Implemented, incomplete | `StudentResultReviewService` |
| STD-MSG-047 | Declare | Standard | Implemented, permissive | `StudentResultReviewService` |
| STD-MSG-048 | Result deletion | Standard | Contradicted | `StudentResult` SoftDeletes |
| STD-MSG-049 | Manual result CRUD | Standard | Implemented, risky | `StudentResultController` |
| STD-MSG-050 | Exam line items | Standard | Implemented | `StudentSubjectExamMarkController` |
| STD-MSG-060 | Schedule export | Standard | Implemented | `MarksheetScheduleExport` |
| STD-MSG-061 | Student export | Standard | Implemented | `StudentResultExport` |
| STD-MSG-062 | Print | Standard | Implemented | `MarksheetTemplateResolver`, `Template::for` |
| STD-MSG-063 | PDF | Standard | Partial | commented button, redirect route |
| STD-MSG-064 | Log viewer | Standard | Implemented | `ComputationLogController` |
| STD-MSG-065 | Dashboard | Standard | Implemented | `dashboard()` |
| STD-MSG-066 | Feedback | Standard | Implemented | controllers |
| STD-MSG-067 | Consumer contract | Advanced | Missing | — |
| RPT-MSG-001–015 | Reports | Standard | Partial | see Section 10 |
| RPT-MSG-020–025 | Advanced reports | Advanced | Missing | — |

---

## 14. Conflict resolution register

### 14.1 Resolution policy

1. **Schema beats prose for structure.** If the DDL says a column is `NOT NULL`, the code and request must enforce it.
2. **Screen requirement beats BRD for behaviour.** The BRD states motive; the screen file states what the screen does.
3. **Code beats prose only as evidence of as-built.** A code behaviour does not become a requirement merely because it exists.
4. **A silent inference is a defect.** If a value affects a result and is not explicit in configuration, it is recorded here.
5. **Unresolved product intent goes to Section 16.** It is not “resolved” by choosing a side without authority.

### 14.2 Structural and behavioural conflicts

| ID | Conflict | Sources | Resolution adopted | Impact | Severity |
|---|---|---|---|---|---|
| CF-01 | DDL header says 22 tables; file contains 23 `CREATE TABLE` statements. | DDL header vs body | 23 is authoritative. Correct the header. | Documentation only | Low |
| CF-02 | The same `BR-MSG-###` number means different rules in the screen requirements, DDL and code. | All | Canonical domain IDs (`BR-MSG-C/S/R/O`) with a legacy map in 14.3. | Traceability | High |
| CF-03 | BR-MSG-002: class-group junction sync (screen) vs scholastic sum = 100 (DDL). | Screen vs DDL | Split into BR-MSG-C08 and BR-MSG-C28. | Traceability | Medium |
| CF-04 | BR-MSG-003: class-group cascade protection (screen) vs exam-weightage sum = 100 (DDL). | Screen vs DDL | Split into BR-MSG-C09 and BR-MSG-C29. | Traceability | Medium |
| CF-05 | BR-MSG-005: template session uniqueness (screen) vs direct class assignment precedence (DDL). | Screen vs DDL | Split into BR-MSG-C15 and BR-MSG-C31. | Traceability | Medium |
| CF-06 | BR-MSG-009: dashboard live computation (screen) vs BA auto-population (code). | Screen vs code | Split into RPT-MSG-001 / BR-MSG-R13. | Traceability | Medium |
| CF-07 | BR-MSG-011: exam-group session uniqueness (screen) vs per-student elective resolution (code). | Screen vs code | Split into BR-MSG-C11 and STD-MSG-014. | Traceability | Medium |
| CF-08 | BR-MSG-019: lifecycle state machine (screen) vs null-safe weightage/attendance (code). | Screen vs code | Split into BR-MSG-S03–S11 and BR-MSG-R19/R14. | Traceability | Medium |
| CF-09 | BR-MSG-025: schedule-class unique mapping (screen) vs Best-of-N (code). | Screen vs code | Split into BR-MSG-S13 and STD-MSG-001/Condition 4. | Traceability | Medium |
| CF-10 | BR-MSG-027: schedule-class deletion restriction (screen) vs template `is_locked` (DDL). | Screen vs DDL | Split into BR-MSG-S15 and BR-MSG-C19. | Traceability | Medium |
| CF-11 | `grading_schema_id` is `NOT NULL` in DDL but `nullable` in request and model; FK is `ON DELETE SET NULL` on a non-null column. | DDL vs request/code | Make it `NOT NULL` and `RESTRICT`, or make it nullable by design. | Schema integrity; template can exist without a grade source | High |
| CF-12 | Scholastic weights “must not exceed 100” (screen) vs “must equal 100” (DDL/code). | Screen vs DDL/code | Equality is the compute contract; raise as OD-01 for product confirmation. | Determines whether partial templates are legal | High |
| CF-13 | The template component service validates the sum **after** each insert/update, so a multi-source template cannot be built incrementally. | Code vs workflow | Treat as a defect: validation must run on an explicit “finalise” action or allow a draft total < 100 and block only at compute. | Blocks normal setup; forces SQL/seeder | P0 |
| CF-14 | No `IA` source component is seeded; the engine computes IA but cannot include it in subject totals. | Seeder vs computation | Add an `IA` source, or document IA as display-only. | IA marks silently excluded | P0 |
| CF-15 | DDL calls result columns “marks”; the engine stores normalized percentages and weighted points. | DDL vs code | Document normalized points; add units to column comments and UI. | Misinterpretation of “485/500” style totals | High |
| CF-16 | Practical config says real theory/practical evidence; the splitter allocates the combined weighted total proportionally. | Screen vs code | Accept as Phase-1 approximation, label it, and plan real paper evidence. | Practical column is not a real practical mark | High |
| CF-17 | `grading_schema_id` is ignored by `GradeResolver`; bands are chosen globally by scope. | DDL/screen vs code | Treat as a defect; bind the resolver to the template schema. | Different templates cannot use different scales | P0 |
| CF-18 | `rank_in_class` is documented and displayed but always written as `0`. | DDL/screen vs code | Implement cross-section rank or hide the field until implemented. | Wrong rank on report card | High |
| CF-19 | Recompute hard-deletes `msh_student_coscholastic_results`, destroying manual grades. | Code vs ownership rule | Exclude co-scholastic from the wipe; upsert only computed columns. | Data loss on every recompute | P0 |
| CF-20 | The wipe runs before the class-section loop; a failure can leave zero results while the status is unchanged. | Code vs idempotency | Move the wipe into a staging/swap model or restore on failure. | Empty or partial result set | P0 |
| CF-21 | A partial run leaves successful sections’ rows indistinguishable from a complete run. | Code vs partial-failure rule | Add a run id / status to results, or stage and swap. | A mixed run can be reviewed/published | P0 |
| CF-22 | Review/lock do not block IA or co-scholastic entry; only compute and withhold/declare check `is_locked`. | Screen vs code | Enforce schedule status on every mark and result write. | Published marks can change | P0 |
| CF-22b | Publish does not set `result_status = DECLARED`; the code comment claims it does. | Screen/comment vs code | Set `DECLARED` for all non-withheld results inside the publish transaction. | Consumers see nothing or everything | P0 |
| CF-23 | Publish locks the template, but no template/component write path checks `is_locked`; the request accepts `is_locked` from the client. | Screen/DDL vs code | Enforce the lock in services and remove system fields from requests. | The frozen recipe is editable | P0 |
| CF-24 | Schedule create/edit accepts any `status_id`, including `PUBLISHED`/`LOCKED`. | Screen vs request | Restrict create to `DRAFT`; restrict edit to non-lifecycle fields. | Full lifecycle bypass | P0 |
| CF-25 | Unlock accepts any status and does not clear `locked_at`/`locked_by`. | Screen vs code | Require `PUBLISHED`/`LOCKED`; clear lock metadata; keep template locked. | Misleading state and audit | High |
| CF-26 | Withhold/declare check only `is_locked`, not `REVIEWED`/`PUBLISHED` status. | Screen vs code | Decide whether withholding after publish is allowed; enforce the decision. | Inconsistent visibility | High |
| CF-27 | Declare does not require the result to be `WITHHELD`. | Screen vs code | Reject declare unless `WITHHELD`. | Audited state is meaningless | High |
| CF-28 | Withhold/declare require actor and timestamp columns that the DDL does not have. | Screen vs DDL | Add `withheld_at/by`, `declared_at/by`, or store provenance only in logs and say so. | Weak audit | High |
| CF-29 | Deletion guards described in the screen requirements are absent (schedule, practical config, mappings, components). | Screen vs code | Implement service-level guards with named blockers. | Reference integrity and data loss | High |
| CF-30 | Precheck queries students with the organization session id; compute uses the global session id. | Code vs code | Extract one session resolver and use it in both. | Precheck counts are wrong | High |
| CF-31 | Precheck is advisory; compute does not require it. | Screen vs code | Decide whether precheck is a gate; if advisory, say so in the UI. | Users can compute on known-bad data | Medium |
| CF-32 | Exam-group date window filters HW/Quiz/Quest only; exams and attendance are not filtered. | DDL comment vs code | Document the scope or apply the window consistently. | Term leakage for exams/attendance | Medium |
| CF-33 | `msh_class_config_jnt` is maintained but never used by computation; the schedule names its template directly. | DDL/screen vs code | Either make the schedule inherit from the class map or drop the map from the compute story. | Configuration can disagree with results | High |
| CF-33b | Exam-weightage dropdown is not restricted to the template’s exam group. | Screen vs code | Filter the selectable exam types; validate membership at save. | Weights for exams outside the term | Medium |
| CF-34 | PDF requirement says browser-side generation; the button is commented out and `/pdf` redirects to print. | BRD vs code | Choose browser-side or server-side, implement and test one path. | No reliable PDF | High |
| CF-35 | Combined pages authorise `.view`; resource indexes/policies authorise `.viewAny`. | Permission list vs code | Standardise on one convention for index/show. | Spurious 403s | Medium |
| CF-36 | Computation log DDL documents `IN_PROGRESS/SUCCESS/FAILED/PARTIAL` and actions `COMPUTE/RECOMPUTE/PUBLISH/UNLOCK/LOCK`; code writes `RUNNING`, `BLOCKED`, `REVIEW`, `WITHHOLD`, `DECLARE` and never `RECOMPUTE`. | DDL vs code | Align the vocabulary in DDL, code and UI. | Unreadable/undocumented audit | Medium |
| CF-37 | `result_status` documents only `DECLARED/WITHHELD` and defaults null; computation leaves it null; publish does not set it. | DDL vs code | Define the state machine explicitly and populate on publish. | No publication marker | P0 |
| CF-38 | Promotion is inferred from marksheet type codes `ANNUAL/FINAL/SESSION_FINAL/PROMOTION`; `PLACED` is unreachable. | Code vs requirement | Add an explicit “final result” flag; document or implement `PLACED`. | Promotion can silently disable | High |
| CF-39 | Student result requirement says direct (hard) deletion; the model uses SoftDeletes. | Screen vs code | Choose one; if soft, adjust the requirement and prevent stale re-association. | Contradictory behaviour | Medium |
| CF-40 | Print context binds `SELF = student_id`, so two schedules for one student make variables ambiguous. | Code comment vs data model | Add schedule/term scoping to the template context. | Wrong data on a printed marksheet | High |
| CF-41 | `AttendanceReader` exists but is unused; attendance is counted session-wide with no date window and no `days_present <= total` check. | Code vs design | Use the reader, apply the term window, add validation. | Wrong attendance percentage | Medium |
| CF-42 | Class-scoped bands apply to subject grades but overall grades pass `null`, so the same percentage can receive different scopes. | Code vs expectation | Define whether overall grades may use class scope; enforce consistently. | Inconsistent report card | High |
| CF-43 | Manual co-scholastic grades are both deleted by recompute and editable after lock. | Code vs ownership | Preserve manual rows; enforce lifecycle on edits. | Data loss and post-publication change | P0 |
| CF-44 | Template component services have no lock check; direct requests can change a locked template. | Code vs BR-MSG-C19 | Enforce lock in every service method. | Frozen recipe changes | P0 |
| CF-45 | Subject enumeration uses timetable requirement groups, not a marksheet-owned subject list; a subject absent from the timetable is silently excluded. | Code vs expectation | Document the dependency or add a marksheet subject selection. | Missing subjects on report card | High |
| CF-46 | Exam line-item `result_status` marks the whole exam type ABSENT/WITHHELD if any paper in the aggregate is absent/withheld, even when a partial aggregate exists. | Code vs evidence semantics | Store per-paper status or a count; label the aggregate accurately. | Misleading absence label | Medium |
| CF-46b | Quiz/quest readers do not flag absent/withheld, so an absent zero is indistinguishable from a genuine zero. | Code vs null-safety | Add flags and exclude absent/withheld from the denominator. | Depressed quiz/quest scores | Medium |
| CF-47 | `msh_marksheet_schedules.total_students` counts enrolled students processed, not result rows written; a section whose students are all filtered out by elective enrolment still contributes its student count even though no result rows were written. | Code vs field name | Rename to `processed_students` or count results. | Misleading metric | Low |
| CF-48 | Manual student-result and subject-result CRUD can create rows the engine did not compute, with no “manual” flag; the next recompute deletes them silently. | Code vs computed-output rule | Add a source flag and a warning, or remove manual create. | Unexplained rows; silent loss | High |
| CF-49 | The DDL has no `run_id`/`computation_log_id` on result rows, so a result cannot be tied to the run that produced it. | DDL vs auditability | Add a run reference. | Weak audit and partial-run diagnosis | High |
| CF-50 | `msh_class_config_jnt` has no uniqueness constraint, so duplicate direct assignments are possible and “first match wins” is undefined. | DDL vs resolution rule | Add a unique key or a priority column. | Non-deterministic template resolution | Medium |
| CF-51 | `msh_computation_logs.error_log` is documented as a JSON array but written as newline-delimited text. | DDL vs code | Pick one format; JSON is preferred. | Hard to parse/report | Low |
| CF-52 | The DDL’s `ON DELETE SET NULL` on `grading_schema_id` conflicts with `NOT NULL`; MySQL may reject the constraint. | DDL internal | Fix the FK action or nullability. | Migration may fail | High |
| CF-53 | `msh_student_results.result_status` is VARCHAR, not a lookup, while schedule status is a dropdown; the two vocabularies are governed differently. | DDL design | Use a lookup or a documented enum table for consistency. | Inconsistent status handling | Medium |
| CF-54 | `msh_student_attendance` has no CHECK for `days_present <= total_working_days`, and the request does not enforce it. | DDL/request vs data quality | Add validation. | Impossible attendance percentages | Medium |
| CF-55 | `msh_template_*` FKs use `ON DELETE CASCADE` from the template, but the template is soft-deleted; a force-delete silently destroys components and possibly history. | DDL vs retention | Use `RESTRICT` for templates referenced by results; archive instead of force-delete. | Historical recipe loss | High |
| CF-56 | `msh_source_components.is_mandatory = 1` for `EXAM`, but neither template save nor compute checks that an `EXAM` component exists. A template weighted 100% on Homework passes validation. | DDL/comment vs code | Enforce the mandatory source at readiness/compute. | A “marksheet” can contain no exam evidence | High |
| CF-57 | Mark-entry requests accept system/provenance fields from the client: `max_marks`, `entered_by`, `entered_at`, `is_auto_from_ba`. IA validation does not enforce `marks_obtained <= max_marks`; co-scholastic `grade` is nullable. | Code vs integrity | Derive maxima and actor server-side; enforce bounds and required fields. | Forged actors, inflated maxima, misleading auto badges | High |

### 14.3 Legacy `BR-MSG-###` mapping

The screen requirements define 59 legacy rules. The DDL and code reuse eight of those numbers for different meanings. The table below maps the duplicated numbers; all other legacy numbers map one-to-one to the canonical ID in parentheses.

| Legacy # | Screen requirement meaning | DDL / code meaning | Canonical IDs |
|---|---|---|---|
| 001 | Class group code unique | — | BR-MSG-C07 |
| 002 | Class group junction sync | Scholastic weight sum = 100 | BR-MSG-C08; BR-MSG-C28 |
| 003 | Class group cascade protection | Exam weight sum = 100 | BR-MSG-C09; BR-MSG-C29 |
| 004 | Class group status gating | — | BR-MSG-C10 |
| 005 | Template code unique per session | Direct class assignment precedence | BR-MSG-C15; BR-MSG-C31 |
| 006 | Locked template protection | — | BR-MSG-C19 |
| 007 | Class assignment sync | — | BR-MSG-C17 |
| 008 | Template deletion restriction | — | BR-MSG-C18 |
| 009 | Dashboard live computation | BA auto-population | RPT-MSG-001; BR-MSG-R13 |
| 010 | Dashboard access gating | — | FND-MSG-010 |
| 011 | Exam group code unique per session | Per-student elective resolution | BR-MSG-C11; STD-MSG-014 |
| 012 | Exam group junction sync | — | BR-MSG-C12 |
| 013 | Exam group date validation | — | BR-MSG-C13 |
| 014 | Exam group deletion safeguards | — | BR-MSG-C14 |
| 015 | IA type code unique | — | BR-MSG-C04 |
| 016 | IA type cascade protection | — | BR-MSG-C05 |
| 017 | IA type status gating | — | BR-MSG-C06 |
| 018 | Schedule code unique per session | — | BR-MSG-S01 |
| 019 | Lifecycle state machine | Null-safe weightage / attendance auto | BR-MSG-S03–S11; BR-MSG-R19/R14 |
| 020 | One running job per schedule | — | BR-MSG-S05 |
| 021 | Schedule deletion restriction | — | BR-MSG-S12 |
| 022 | Marksheet type code unique | — | BR-MSG-C01 |
| 023 | Marksheet type deletion safeguards | — | BR-MSG-C02 |
| 024 | Marksheet type status gating | — | BR-MSG-C03 |
| 025 | Schedule-class unique mapping | Best-of-N | BR-MSG-S13; Condition 4 |
| 026 | Locked schedule guard | — | BR-MSG-S14 |
| 027 | Schedule-class deletion restriction | Template `is_locked` | BR-MSG-S15; BR-MSG-C19 |
| 028–059 | Coscholastic, IA, result, practical, component rules | — | See Section 7 |

**Canonical mapping for the unduplicated legacy rules:**

| Legacy | Canonical | Legacy | Canonical |
|---|---|---|---|
| 028 | BR-MSG-R04 | 044 | BR-MSG-C22 |
| 029 | BR-MSG-R05 | 045 | BR-MSG-C23 |
| 030 | BR-MSG-R06 | 046 | BR-MSG-C24 |
| 031 | BR-MSG-C26 | 047 | BR-MSG-C26 |
| 032 | BR-MSG-R03 | 048 | BR-MSG-C27 |
| 033 | BR-MSG-R06 | 049 | BR-MSG-C24 |
| 034 | BR-MSG-C26 / R22 | 050 | STD-MSG-002 |
| 035 | BR-MSG-R01 | 051 | BR-MSG-C26 |
| 036 | BR-MSG-R07 | 052 | BR-MSG-C27 |
| 037 | BR-MSG-R10 | 053 | BR-MSG-C24 |
| 038 | BR-MSG-O05 | 054 | BR-MSG-C26 |
| 039 | BR-MSG-R02 | 055 | BR-MSG-C27 |
| 040 | BR-MSG-R12 | 056 | BR-MSG-C24 |
| 041 | BR-MSG-R11 | 057 | BR-MSG-C28 |
| 042 | BR-MSG-C20 | 058 | BR-MSG-C26 |
| 043 | BR-MSG-C21 | 059 | BR-MSG-C27 |

### 14.4 Severity summary

**P0 — must fix before a school depends on the module**
- CF-13 incremental weightage setup is impossible.
- CF-14 IA cannot affect subject totals.
- CF-17 grading schema is ignored.
- CF-19 recompute destroys manual co-scholastic grades.
- CF-20/21 partial recompute can leave empty or mixed results.
- CF-22/22b publication does not freeze marks or declare results.
- CF-23/44 template lock is not enforced.
- CF-24 schedule status can be set directly.
- CF-37 no publication marker for consumers.

**P1 — required for a complete release**
- CF-11/52 grading-schema nullability and FK.
- CF-15 normalized-point semantics must be documented.
- CF-16 practical split must be labelled.
- CF-18 class rank must be implemented or hidden.
- CF-25 unlock state and metadata.
- CF-27 declare state.
- CF-28 withhold/declare provenance.
- CF-29 deletion guards.
- CF-30 precheck session mismatch.
- CF-33 class assignment unused.
- CF-38 promotion inference.
- CF-40 print context ambiguity.
- CF-42 grade scope consistency.
- CF-45 subject enumeration dependency.
- CF-48 manual rows indistinguishable.
- CF-49 no run id.
- CF-55 cascade delete versus history.
- CF-56 mandatory `EXAM` source is not enforced.
- CF-57 client-controlled maxima, actors and auto flags in mark entry.

**P2 — quality and polish**
- CF-01 header count.
- CF-31 precheck advisory messaging.
- CF-32 date-window scope.
- CF-34 PDF path.
- CF-35 permission convention.
- CF-36 audit vocabulary.
- CF-39 delete semantics.
- CF-41 attendance reader/window.
- CF-46/46b absence semantics.
- CF-47 metric naming.
- CF-50 duplicate assignment.
- CF-51 error log format.
- CF-53 status vocabulary.
- CF-54 attendance validation.

---

## 15. Additional suggestions

### 15.1 Architecture and delivery

1. **Introduce a computation run id.** Add `run_id` (or `computation_log_id`) to every result table and write it on insert. This single change makes partial runs diagnosable, enables a “show me this run” view, and lets a publish assert that it is publishing one complete run.
2. **Stage and swap instead of wipe and rebuild.** Write a new run into the same tables with a `run_id`, then mark the run complete and let readers use the latest complete run. Old runs can be retained for audit and cleaned by policy. This removes the destructive window entirely.
3. **One session resolver.** Create `AcademicSessionResolver::globalIdForOrg($orgSessionId)` and use it in precheck, compute, print and every report. This eliminates CF-30 and prevents a whole class of future mismatches.
4. **One lock guard.** A `TemplateWriteGuard::assertUnlocked($templateId)` called by every template and component service, and a `ScheduleWriteGuard::assertEditable($schedule)` called by every mark and result service. Do not rely on controllers.
5. **One lifecycle service.** Keep all status transitions in `MarksheetScheduleLifecycleService`, remove `status_id` and `is_locked` from the create/edit requests, and make the form incapable of expressing a lifecycle jump.
6. **Separate “configuration draft” from “computation-ready”.** Add an explicit `is_ready` or a readiness check on the template. A template can be saved with a partial weight total while being assembled; compute requires readiness. This resolves CF-13 without weakening Condition 1.
7. **Extract persistence from orchestration.** `MarksheetComputationService` should enumerate and calculate; a persister should batch-write. This improves testability and performance.
8. **Version the template snapshot on publish.** Store a compact JSON snapshot of the template and component configuration on the schedule at publish time. Then a historical report card can be explained even if a template is later edited or force-deleted.

### 15.2 Data and trust

9. **Document normalized points everywhere.** Column comments, UI labels, exports and the glossary should say “normalized points (0–100)” or “weighted points”, never bare “marks”, unless the value is raw.
10. **Store the effective maximum and the missing-source list.** Add a `components_missing` JSON or a `is_complete` flag on the subject result so a report can say “Quiz not assessed” rather than silently shrinking the denominator.
11. **Preserve manual inputs by construction.** Co-scholastic and attendance rows should have a `source` column (`MANUAL`, `BA`, `ATTENDANCE`, `COMPUTED`) and the engine should only update rows it owns.
12. **Add provenance columns for visibility decisions.** `withheld_at`, `withheld_by`, `declared_at`, `declared_by` on `msh_student_results`.
13. **Use a lookup for result status.** Either a `sys_dropdown_table` key or a small `msh_result_statuses` table; avoid a free VARCHAR that drifts from the documented vocabulary.
14. **Enforce attendance bounds.** Add a CHECK or request rule for `days_present <= total_working_days`.
15. **Do not cascade-delete history.** Change template child FKs to `RESTRICT` or archive templates instead of force-deleting. A published result without its recipe is not auditable.
16. **Add a unique key or priority to class assignments.** If a class can have two templates, define which wins; otherwise add a unique key on `(config_template_id, class_id)` and `(config_template_id, class_group_id)` plus a resolution priority.

### 15.3 Computation correctness

17. **Bind grades to the template schema.** Pass `grading_schema_id` into `GradeResolver`; filter bands by schema and then by scope. Decide whether overall grades may use class scope.
18. **Seed an `IA` source and decide its weight.** If IA is meant to count, add the source and make the template mapping explicit; if it is display-only, remove the misleading computation and label it.
19. **Make Best-of-N explicit.** Restrict it to configured exam types (for example a `counts_for_best_of_n` flag), and decide whether weights apply to the selected set. Document the exact formula on the template screen.
20. **Plan real practical evidence.** Add a practical flag to exam papers or a separate practical mark source, then replace the proportional split. Until then, label the split.
21. **Implement class rank or hide it.** A dense rank across sections is straightforward once all sections of a class are computed. If not implemented, the UI must show “—”, never 0.
22. **Add an explicit final-result flag.** Put `is_final_result` on the template or schedule, or a `result_purpose` lookup. Stop inferring from type codes.
23. **Define absent/withheld semantics per component.** A missing exam should not be silently null if the student was absent; distinguish absent, exempt, withheld and not-entered, and decide how each affects the denominator.
24. **Validate subject evidence completeness before publish.** A publish check should list subjects with no exam evidence and require an explicit acknowledgement.

### 15.4 Operations

25. **Make precheck a readiness gate, not a report.** Compute should require a recent successful precheck or show a blocking confirmation. At minimum, fix its session and section counts.
26. **Show the next allowed action.** The schedule page should render exactly one primary lifecycle button based on status, with the reason the others are disabled.
27. **Choose one PDF path and finish it.** Either enable the browser button and test it, or wire the existing DomPDF preparation and remove the redirect. Do not leave both half-built.
28. **Add a “published result” read model.** A view or query object that returns only published + declared results, used by any future portal. This makes the consumer contract enforceable in one place.
29. **Add operational dashboards.** Compute duration, failure rate, partial runs, templates not ready, schedules stuck in a state.
30. **Add a repair command.** An artisan command that reports schedules with inconsistent status, results without a run, orphaned marks and locked templates with no published schedule. Read-only by default, with an explicit `--fix` and audit.

### 15.5 Engineering quality

31. **Test the maths, not just the CRUD.** Unit-test `WeightageApplier` (weighted, Best-of-N, null sources), `PracticalSplitter`, `GradeResolver` (scope precedence and schema), `RankCalculator` (ties) and promotion. Integration-test a seeded schedule end to end.
32. **Test the lifecycle matrix.** For every status × action, assert allowed/denied. This is the cheapest way to prevent CF-22/24/25/27.
33. **Replace magic strings with constants.** Status values, action values, type codes and source codes should be enums or constants shared by DDL seed, services and UI.
34. **Align migrations and DDL.** Generate migrations from the DDL, or verify the DDL against the migrations in CI. The 22/23 discrepancy and the `SET NULL`/`NOT NULL` conflict suggest drift.
35. **Add static analysis and a permission audit.** A CI check that every controller action has a gate and every gate references a declared permission would have caught CF-35.
36. **Document the normalized-point contract in the module README.** A new engineer should not have to read the computation service to learn that `subject_total` is not a raw mark.

---

## 16. Open decisions

These are product or policy questions the sources do not answer. Each is stated with the evidence, the options and a recommendation where the evidence supports one. **No recommendation is a decision; the school or product owner must confirm.**

| ID | Question | Why it matters | Options | Recommendation |
|---|---|---|---|---|
| OD-01 | Must active weightages sum to exactly 100, or may they sum to less than 100 as a draft? | Determines whether a partial template can exist and whether compute must fail. | (a) Exactly 100 always; (b) allow < 100 as draft, block compute; (c) allow < 100 and compute on the effective maximum. | (b) — it preserves correctness and makes setup possible. |
| OD-02 | Is an incomplete template a legal saved state? | Tied to OD-01 and CF-13. | (a) No, save fails; (b) Yes, with a readiness flag. | (b). |
| OD-03 | Should IA marks count toward the subject total? | Currently computed but excluded because no `IA` source exists. | (a) Yes, seed an `IA` source and require a weight; (b) No, display-only; (c) Optional per template. | (c) — schools differ; make it explicit. |
| OD-04 | How should “no evidence” be distinguished from “absent” and “zero”? | Affects fairness and the denominator. | (a) Treat all as null; (b) distinguish four states; (c) treat absent as zero. | (b). |
| OD-05 | Who may publish, and is there a two-step approval chain? | The screen requirements mention configurable approval; the code has one permission. | (a) One-step coordinator; (b) coordinator → principal; (c) configurable per school. | (c), defaulting to (b) for board results. |
| OD-06 | Does Best-of-N apply to all exam types or only designated ones, and do weights still apply? | Changes the computed exam total materially. | (a) All types, weights ignored; (b) designated types, weights ignored; (c) designated types, weights applied to the selected set. | (c). |
| OD-07 | Is a proportional theory/practical split acceptable, or is real paper evidence required? | The current practical column is allocated, not measured. | (a) Accept and label; (b) require real practical papers. | (a) for Phase 1, (b) as the target. |
| OD-08 | May a class-scoped grade band apply to the overall grade, or only to subject grades? | The code uses class scope for subjects and not for the overall. | (a) Same scope for both; (b) overall uses board/school only. | (a) unless a board rule says otherwise. |
| OD-09 | May a result be withheld after the schedule is published? | The code allows it while unlocked; the requirement is silent. | (a) Yes, with audit; (b) only before publish; (c) only with an admin override. | (a) — administrative holds often arise after publication. |
| OD-10 | How is a “final result of the session” designated? | Promotion depends on it; the code infers from type codes. | (a) Template flag; (b) schedule flag; (c) explicit type code list. | (a) plus (b) for override. |
| OD-11 | On recompute, should manual co-scholastic and attendance inputs be preserved? | The current code destroys co-scholastic grades. | (a) Preserve all manual inputs; (b) full rebuild with re-entry; (c) preserve and version. | (a). |
| OD-12 | What is the consumer-facing result contract and status vocabulary? | Needed for any portal. | (a) `DECLARED/WITHHELD`; (b) add `DRAFT/COMPUTED/REVIEWED/PUBLISHED`; (c) separate visibility flag. | (a) plus the schedule gate. |
| OD-13 | Does publish automatically declare every non-withheld result? | The code comment says yes; the code does not. | (a) Yes; (b) declare is a separate per-student action. | (a), with withhold as the exception. |
| OD-14 | How is a template lock released? | Currently only a direct column write. | (a) Never; (b) explicit admin unlock with reason; (c) automatic when no published schedule references it. | (b). |
| OD-15 | Are manual student-result and subject-result CRUD screens retained? | They can create rows the engine did not compute. | (a) Remove create, keep correction with a flag; (b) keep full CRUD; (c) read-only. | (a). |
| OD-16 | Is the index permission `.view` or `.viewAny`? | Causes spurious 403s. | (a) `.view` everywhere; (b) `.viewAny` for lists and `.view` for records. | (b), applied consistently. |
| OD-17 | Is rank shown to parents, and are withheld students ranked? | Policy and privacy. | (a) Show rank, exclude withheld; (b) show rank, include withheld; (c) hide rank. | (a). |
| OD-18 | Should attendance cover the whole session or the exam-group term? | Changes the printed percentage. | (a) Term window; (b) session to date; (c) configurable. | (a) when a window exists, else session. |
| OD-19 | What should print do when a student has results in two schedules? | The template context is ambiguous. | (a) Require a schedule in the print context; (b) use the latest; (c) use the highest-priority schedule. | (a). |
| OD-20 | Browser-side or server-side PDF? | The current path is contradictory. | (a) Browser `html2pdf`; (b) server DomPDF; (c) both. | (b) for consistency and signatures. |
| OD-21 | Is student-result deletion hard or soft? | The requirement says hard; the code soft-deletes. | (a) Hard with cascade; (b) soft with trash. | (a) for erroneous drafts, (b) for published history. |
| OD-22 | What promotion outcomes are supported, including `PLACED` and manual override? | The code produces three; the schema allows four. | (a) Three; (b) four with manual `PLACED`; (c) configurable. | (b) with an audited override. |
| OD-23 | Is the subject list authoritative in the timetable or in the marksheet module? | A missing timetable subject silently disappears from the report card. | (a) Timetable; (b) marksheet-owned list; (c) union with validation. | (b) for marksheet correctness, or (c) with a warning. |
| OD-24 | Does the exam-group date window apply to exams and attendance, or only HW/Quiz/Quest? | Term leakage. | (a) All evidence; (b) only continuous assessment; (c) configurable per source. | (a) for consistency. |
| OD-25 | Does the behavioural integration weightage affect the academic total, or only co-scholastic? | The reader exposes a weight but compute does not use it. | (a) Co-scholastic only; (b) blend into academic total; (c) configurable. | (a) unless the school explicitly opts into (b). |
| OD-26 | May a student have more than one result per session? | Print and consumer contracts assume one. | (a) Yes, per schedule; (b) one final plus term snapshots; (c) one only. | (a) with schedule-scoped print. |
| OD-27 | Which wins when `board_code` and `grading_schema_id` disagree? | Grade selection ambiguity. | (a) Schema; (b) board code; (c) schema with board fallback. | (c). |

---

## 17. Traceability matrix

### 17.1 BRD to requirements

| BRD file | Primary intent | Requirements |
|---|---|---|
| `01-Dashboard-and-Navigation.md` | Command centre, metrics, four pillars | FND-MSG-010, STD-MSG-065, RPT-MSG-001 |
| `02-Configuration-Templates.md` | Types, exam groups, class groups, templates | FND-MSG-001, 004, 005, 006, 007; STD-MSG-008 |
| `03-Components-and-Weightages.md` | Scholastic, exam, IA and co-scholastic weights | STD-MSG-001, 002, 003, 004, 007 |
| `04-Scheduling-and-Lifecycle.md` | Schedule, lifecycle, authorization | STD-MSG-010–013, 029–032 |
| `05-Student-Results-and-Print.md` | Result storage, review, export, print | STD-MSG-040–050, 060–063 |

### 17.2 Screen requirement to requirements

| Screen file | Requirements |
|---|---|
| `msh_Dashboard_Requirement.md` | FND-MSG-010, STD-MSG-065, RPT-MSG-001 |
| `msh_ConfigTemplates_Requirement.md` | FND-MSG-006, 007; STD-MSG-005, 008; BR-MSG-C15–C19, C31, C32 |
| `msh_ClassGroups_Requirement.md` | FND-MSG-004; BR-MSG-C07–C10 |
| `msh_ExamGroups_Requirement.md` | FND-MSG-005; BR-MSG-C11–C14 |
| `msh_MarksheetTypes_Requirement.md` | FND-MSG-001; BR-MSG-C01–C03 |
| `msh_IAComponentTypes_Requirement.md` | FND-MSG-002; BR-MSG-C04–C06 |
| `msh_MarksheetSchedules_Requirement.md` | STD-MSG-010–013, 029–032; BR-MSG-S01–S12 |
| `msh_ScheduleClasses_Requirement.md` | STD-MSG-011; BR-MSG-S13–S15 |
| `msh_SubjectPracticalConfigs_Requirement.md` | FND-MSG-008, STD-MSG-021; BR-MSG-C20–C23 |
| `msh_TemplateScholasticComponents_Requirement.md` | STD-MSG-001, 007; BR-MSG-C24, C26, C28 |
| `msh_TemplateExamWeightages_Requirement.md` | STD-MSG-002, 007; BR-MSG-C24, C29 |
| `msh_TemplateIAComponents_Requirement.md` | STD-MSG-003, 018; BR-MSG-C24 |
| `msh_TemplateCoscholasticComponents_Requirement.md` | STD-MSG-004, 019; BR-MSG-C24 |
| `msh_StudentResults_Requirement.md` | STD-MSG-040, 041, 046, 047, 048, 049, 062, 063; BR-MSG-R01, R07–R10 |
| `msh_StudentSubjectResults_Requirement.md` | STD-MSG-042, 050, 061; BR-MSG-R02, R11, R12 |
| `msh_StudentIAMarks_Requirement.md` | STD-MSG-043, 018; BR-MSG-R03, R06, R22 |
| `msh_StudentCoscholasticResults_Requirement.md` | STD-MSG-044, 019; BR-MSG-R04–R06, R13 |

### 17.3 DDL table to requirements

| Table | Requirements |
|---|---|
| `msh_marksheet_types` | FND-MSG-001 |
| `msh_source_components` | FND-MSG-003, STD-MSG-001 |
| `msh_ia_component_types` | FND-MSG-002 |
| `msh_class_groups`, `msh_class_group_items_jnt` | FND-MSG-004 |
| `msh_exam_groups`, `msh_exam_group_items_jnt` | FND-MSG-005 |
| `msh_config_templates` | FND-MSG-006, STD-MSG-005, 007 |
| `msh_template_scholastic_components` | STD-MSG-001, 007 |
| `msh_template_exam_weightages` | STD-MSG-002, 007 |
| `msh_template_ia_components` | STD-MSG-003, 018 |
| `msh_template_coscholastic_components` | STD-MSG-004, 019 |
| `msh_class_config_jnt` | FND-MSG-007 |
| `msh_subject_practical_configs` | FND-MSG-008, STD-MSG-021 |
| `msh_marksheet_schedules` | STD-MSG-010, 029–032 |
| `msh_schedule_class_jnt` | STD-MSG-011 |
| `msh_student_results` | STD-MSG-022, 023, 024, 025, 040, 046, 047, 048, 049 |
| `msh_student_subject_results` | STD-MSG-021, 022, 042 |
| `msh_student_subject_exam_marks` | STD-MSG-015, 050 |
| `msh_student_ia_marks` | STD-MSG-018, 043 |
| `msh_student_coscholastic_results` | STD-MSG-019, 044 |
| `msh_student_attendance` | STD-MSG-020, 045 |
| `msh_computation_logs` | STD-MSG-027, 064 |

### 17.4 Source file to requirement

| File | Requirements evidenced |
|---|---|
| `MarksheetComputationService.php` | STD-MSG-014–028 |
| `WeightageApplier.php` | STD-MSG-001, 002, 007, 022; Conditions 1–4 |
| `PracticalSplitter.php` | STD-MSG-021; Condition 5 |
| `GradeResolver.php` | STD-MSG-023; Condition 6 |
| `RankCalculator.php` | STD-MSG-025; Condition 8 |
| `MarksheetScheduleLifecycleService.php` | STD-MSG-029–032; Condition 10 |
| `StudentResultReviewService.php` | STD-MSG-046, 047 |
| `MarksheetConfigService.php` | FND-MSG-006, 007; STD-MSG-005, 006, 007 |
| `MarksheetScheduleController.php` | STD-MSG-010–013, 029–032, 060 |
| `StudentResultController.php` | STD-MSG-040–050, 061–063 |
| `MarksheetGenerationController.php` | FND-MSG-010, STD-MSG-040, 065 |
| `MarksheetScheduleRequest.php` | STD-MSG-010; CF-24 |
| `ConfigTemplateRequest.php` | FND-MSG-006; CF-11, CF-23 |
| `MarksheetGenerationDatabaseSeeder.php` | FND-MSG-003; CF-14 |
| `MarksheetTemplateResolver.php` | STD-MSG-062; Condition 10 |

---

## 18. Glossary

| Term | Definition |
|---|---|
| **Academic session** | A school year. Two identifiers exist: `sch_org_academic_sessions_jnt.id` for MSH configuration and `glb_academic_sessions.id` for student/LMS data. |
| **Active** | `is_active = 1` and, where applicable, `deleted_at IS NULL`. Active does not mean published. |
| **Assessment source** | One of `EXAM`, `HOMEWORK`, `QUIZ`, `QUEST` (and `IA` if added). A source is a weighted contributor to a subject total. |
| **BA** | Behavioural Assessment module. Supplies co-scholastic grades and an optional integration weight. |
| **Best-of-N** | A policy that averages a student’s top N exam-type percentages instead of using all weights. |
| **Class group** | A marksheet-specific band of classes, distinct from a timetable class group. |
| **Co-scholastic** | Non-academic areas such as behaviour, art, health and discipline. Grade-based; never part of the academic total. |
| **Compartment** | A promotion outcome for a final result with failures at or below the template’s compartment limit. |
| **Computation log** | An immutable row recording a compute or lifecycle action. |
| **Config template** | The grading recipe: session, marksheet type, exam group, grading schema, pass rules and component mappings. |
| **Dense rank** | Ties share a rank; the next distinct value increments by one (90, 85, 85, 70 → 1, 2, 2, 3). |
| **Division** | A coarse performance band (First, Second, Third) resolved from division bands. |
| **Exam group** | A named bundle of exam types with an optional date window. |
| **Exam type** | A category from `lms_exam_types` (Unit Test 1, Half-Yearly, Annual). |
| **Final result** | A result designated as the last result of the session, eligible for promotion. Currently inferred from the marksheet type code. |
| **Grade band** | A percentage range mapped to a grade code in `slb_grade_division_master`. |
| **Grading schema** | The band set selected by a template. Currently stored but not used by the resolver. |
| **IA** | Internal Assessment. Teacher-evaluated components such as notebook, portfolio and viva. |
| **Lifecycle status** | The schedule state machine: `DRAFT`, `COMPUTED`, `REVIEWED`, `PUBLISHED`, `LOCKED`. |
| **Locked template** | A template with `is_locked = 1`, intended to be immutable after a schedule using it is published. |
| **Locked schedule** | A schedule with `is_locked = 1`, intended to block compute and result changes. |
| **Marksheet type** | A category of report card: Unit Test, Term-1, Annual. |
| **Normalized point** | A 0–100 value produced by dividing raw marks by their maximum and multiplying by 100. |
| **Null-safe weighting** | Excluding a missing source from both numerator and denominator instead of treating it as zero. |
| **Practical split** | The allocation of a weighted exam total into theory and practical portions by configured maxima. |
| **Precheck** | A read-only diagnostic of template completeness and evidence volume before compute. |
| **Publication** | The transition that releases a reviewed schedule and freezes its template. |
| **Result status** | Per-student `DECLARED` or `WITHHELD`, independent of schedule status. |
| **Review** | The transition from `COMPUTED` to `REVIEWED`, signalling examination-cell acceptance. |
| **Schedule** | The computation event for one template, session and set of class sections. |
| **Schedule class** | A junction row linking a schedule to a class section. |
| **Source weight** | The percentage contribution of a source component to the subject total. |
| **Subject result** | The stored per-student, per-subject computed row. |
| **Subject total / max** | Weighted points achieved and the sum of active weights used. |
| **Template lock** | The `is_locked` flag on a config template. |
| **Tenant** | One school database. MSH tables have no `tenant_id` by design. |
| **Unlock** | The audited reversal of a published or locked schedule back to `COMPUTED`. |
| **Withhold** | The per-student suppression of a result’s visibility, with a reason. |

---

## Document control

| Item | Value |
|---|---|
| **Inputs read** | 5 BRD files, 17 screen requirement files, DDL v1.1 (884 lines, 23 tables), module source (controllers, services, computation helpers, readers, requests, models, exports, jobs, seeders, routes, permissions) |
| **Requirement count** | 10 Foundation, 8 Configuration, 23 Scheduling/Computation, 11 Results, 8 Output, 1 Advanced |
| **Business rules** | 34 configuration, 25 scheduling, 22 result, 10 output |
| **Conflicts recorded** | 57 numbered conflicts (plus three lettered sub-findings: CF-22b, CF-33b, CF-46b) |
| **Open decisions** | 27 |
| **Known input gaps** | `Temp.md` is a placeholder, not a requirement; no school-provided board format; no sample report card from the school; no production performance trace |
| **Assumptions made** | Only those listed in 2.3. No missing behaviour was invented. |
| **Next review** | After product answers OD-01 to OD-27; then convert the P0 conflicts into an engineering remediation plan |

**How to use this document.** Start with Section 1.4 for readiness, Section 14.4 for the P0 list, and Section 16 for the decisions that block design. Use Section 5 for build tickets, Section 7 for rule-level acceptance, Section 9 for migrations, and Section 17 to trace any statement back to its source.

---

*End of document.*
