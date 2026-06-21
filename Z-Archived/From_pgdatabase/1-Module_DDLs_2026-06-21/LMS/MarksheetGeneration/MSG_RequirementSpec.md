# MSG — MarksheetGeneration Module: Requirement Specification Document
**Version:** 1.0
**Date:** 2026-04-13
**Module Code:** MSG
**Table Prefix:** `msh_*`
**Module Type:** Tenant
**Author:** Brijesh + Claude (Business Analyst & Enterprise Architect)

---

## Section 1 — Executive Summary

### 1.1 What the Module Does
MarksheetGeneration is the **school result aggregation, configuration, and report card generation engine** for Prime-AI. It consolidates marks from five independent scoring modules — LmsExam, LmsHomework, LmsQuiz, LmsQuest, and BehaviouralAssessment — into a single configurable marksheet per student, per academic term or session.

### 1.2 Why It Is Needed
Currently, Prime-AI has five isolated scoring modules that each store marks independently:
- **LmsExam** stores exam results in `lms_exam_results` (per paper per student)
- **LmsHomework** stores graded submissions in `lms_homework_submissions`
- **LmsQuiz / LmsQuest** store results in `lms_quiz_quest_results`
- **BehaviouralAssessment** stores computed scores in `ba_computed_scores`

**The gap:** There is no consolidated result engine. No module aggregates these marks into a weighted, subject-wise, exam-wise marksheet that Indian schools actually issue to students and parents. Schools cannot currently:
- Configure how much each assessment type contributes to the final result
- Generate a standard CBSE/ICSE/State Board format marksheet
- Show per-subject, per-exam breakdowns with theory/practical splits
- Include Internal Assessment, Co-Scholastic, or Behavioural grades
- Compute overall grade, rank, division, or promotion status

### 1.3 Key Stakeholders
| Stakeholder | Role in Marksheet Lifecycle |
|---|---|
| **School Admin** | Configures templates, weightages, exam groups, schedules |
| **Principal** | Reviews computed results, approves publication, unlocks if needed |
| **Academic Coordinator** | Sets up IA components, co-scholastic areas, practical configs |
| **Class Teacher** | Reviews class results, enters co-scholastic/IA marks, previews marksheets |
| **Subject Teacher** | Enters IA marks for their subject (Notebook, Enrichment) |
| **Student** | Views own published marksheet on Student Portal |
| **Parent** | Views child's published marksheet on Parent Portal |

### 1.4 Integration Touch-Points
| Source Module | Integration Type | What MSG Reads |
|---|---|---|
| **LmsExam** | Read-only query | `lms_exam_results` (final per-paper per-student scores) |
| **LmsHomework** | Read-only query | `lms_homework_submissions.marks_obtained` (graded homework scores) |
| **LmsQuiz** | Read-only query | `lms_quiz_quest_results` WHERE `assessment_type='QUIZ'` |
| **LmsQuest** | Read-only query | `lms_quiz_quest_results` WHERE `assessment_type='QUEST'` |
| **BehaviouralAssessment** | Service call | `BehaviouralScoreService::getStudentScore()` for Co-Scholastic section |
| **SchoolSetup** | Read-only query | `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_subjects`, `sch_employees` |
| **Syllabus** | Read-only query | `slb_grade_division_master` for grading schemas |
| **StudentProfile** | Read-only query | `std_students`, `std_student_academic_sessions` |

### 1.5 Indian Education Board Context
This module must support the marksheet formats used by:
- **CBSE** — 9-point grading scale (A1 to E), Scholastic + Co-Scholastic + Discipline sections
- **ICSE** — Percentage-based with division (First/Second/Third/Pass/Fail)
- **State Boards** — Varies by state; typically percentage + grade + division
- **Custom / International** — Schools using their own grading and reporting structure

The configuration must be flexible enough to accommodate any of these patterns.

---

## Section 2 — Scope

### 2.1 In Scope

| Area | Details |
|---|---|
| **Marksheet Configuration** | Template creation, source component selection, weightage setup |
| **Exam Grouping** | Group multiple `lms_exam_types` into logical terms (Term-1, Term-2, Annual) |
| **Class Grouping** | Create marksheet-specific class groups (Primary, Middle, Secondary) for shared config — NOTE: `sch_class_groups_jnt` is timetable-specific, NOT usable for marksheet grouping |
| **Per-Exam Weightage** | UT1=10%, UT2=10%, HY=80% etc. within the Exam component |
| **Internal Assessment (IA)** | Configure IA components (Notebook, Subject Enrichment, Periodic Assessment, Participation) |
| **Co-Scholastic Section** | Work Education, Art Education, Health & PE, Discipline (from BA module) |
| **Theory-Practical Split** | Per subject-class: Science Theory=70 + Practical=30 |
| **Elective Subject Handling** | Student's marksheet only shows subjects they are enrolled in |
| **Subject-wise Result Matrix** | Per-subject, per-exam score breakdown — the core marksheet table |
| **Grading Schema** | Link to `slb_grade_division_master` for A1/A2/B1... or First/Second/Third Division |
| **Rank & Division** | Rank in class-section, overall division/result status |
| **Promotion Status** | Promoted / Detained / Placed / Compartment |
| **Attendance Summary** | Working days vs days present on marksheet |
| **Marksheet Schedule** | Define when marksheets are generated (per-exam, term-end, annual) |
| **Computation Engine** | Queued job to compute all student results for a schedule |
| **Publication Lifecycle** | Draft → Computed → Reviewed → Published → Locked |
| **Re-generation** | Admin unlock with reason + audit, then recompute |
| **PDF Generation** | DomPDF with inline styles, table layout, school header, signature placeholder |
| **Portal Integration** | Read-only marksheet view on Student Portal and Parent Portal |

### 2.2 Out of Scope

| Excluded Area | Reason |
|---|---|
| **Marks entry** | Owned by LmsExam, LmsHomework, LmsQuiz, LmsQuest respectively |
| **HPC (Holistic Progress Card)** | Separate module with its own PDF templates and evaluation workflow |
| **Board exam result upload** | External board results are not part of this system |
| **Fee integration** | No linkage between fee payment and marksheet access (separate business decision) |
| **Transfer Certificate** | Owned by Certificate module |
| **Any write to `lms_*`, `ba_*`, `sch_*`, `std_*`, `slb_*` tables** | Strictly read-only integration |

---

## Section 3 — Business Requirements

| BR ID | Requirement | Source Module | Priority |
|---|---|---|---|
| BR-MSG-001 | School can select which source modules participate in marksheet (Exam is mandatory; Homework, Quiz, Quest, BA are optional) | All | P0 |
| BR-MSG-002 | Per-source-component weightage is configurable (e.g., Exam=80%, Homework=5%, Quiz=5%, BA=10%). Sum must = 100% | All | P0 |
| BR-MSG-003 | Per-exam weightage within the Exam component (e.g., UT1=10%, UT2=10%, HY=80%). Sum within Exam component must = 100% | LmsExam | P0 |
| BR-MSG-004 | Exams can be grouped into logical terms (Term-1 = UT1+UT2+HY; Annual = all exams) for marksheet generation | LmsExam | P0 |
| BR-MSG-005 | Different class groups can share the same config template. A single template can be assigned to multiple classes. Direct class assignment overrides group-level assignment | — | P0 |
| BR-MSG-006 | Theory-Practical split is configurable per class-subject combination (e.g., Science Class 9: Theory=70, Practical=30 out of 100) | LmsExam | P0 |
| BR-MSG-007 | Internal Assessment (IA) components are configurable per template (e.g., Notebook=5, Subject Enrichment=5, Periodic Assessment=10) | LmsHomework, LmsQuiz | P1 |
| BR-MSG-008 | Co-Scholastic section supports configurable areas with 3-point or 5-point grading (Work Education=A/B/C, Art Education=A/B/C, Health & PE=A/B/C) | — | P1 |
| BR-MSG-009 | BehaviouralAssessment scores feed into the Co-Scholastic Discipline section. Only included if `ba_config.is_result_integration_enabled = true` | BehaviouralAssessment | P1 |
| BR-MSG-010 | Marksheet MUST show a subject-wise, exam-wise result matrix (Subject rows × Exam columns) with totals and grades | LmsExam | P0 |
| BR-MSG-011 | Elective subjects: a student's marksheet only includes subjects they are enrolled in. If student doesn't take a subject, that row is absent — not zero | SchoolSetup | P0 |
| BR-MSG-012 | Grading schema is configurable per template and links to `slb_grade_division_master`. Supports CBSE 9-point, ICSE percentage-based, or custom | Syllabus | P0 |
| BR-MSG-013 | Rank computation within class-section based on aggregate marks. School can disable rank display | — | P1 |
| BR-MSG-014 | Division computation (First/Second/Third or Pass/Fail) based on aggregate percentage and grading schema | — | P1 |
| BR-MSG-015 | Promotion status (Promoted / Detained / Placed / Compartment) derived from per-subject pass/fail criteria | — | P1 |
| BR-MSG-016 | Absent students shown as "AB" on marksheet. `lms_exam_results.result_status = 'ABSENT'` → score is NULL, not zero | LmsExam | P0 |
| BR-MSG-017 | Once marksheet is published, results are locked. Re-generation requires explicit admin unlock + mandatory reason + audit trail entry | — | P0 |
| BR-MSG-018 | Homework/Quiz/Quest scores aggregated by subject within the marksheet schedule's date range. Average of all graded items per subject | LmsHomework, LmsQuiz, LmsQuest | P1 |
| BR-MSG-019 | Attendance summary (total working days, days present) included on marksheet. Sourced from Attendance module if available, otherwise manual entry | — | P2 |
| BR-MSG-020 | School can generate multiple marksheets per year: after each exam, after each term, or annual. Each is a separate schedule with its own configuration | — | P0 |
| BR-MSG-021 | Marksheet PDF includes school logo, school name, student details, board affiliation, principal signature placeholder | — | P1 |
| BR-MSG-022 | Bulk computation for all students in a class-section runs as a queued job with progress tracking | — | P0 |
| BR-MSG-023 | Result can be withheld (`WITHHELD` status from `lms_exam_results.result_status`) — shown as "WH" on marksheet | LmsExam | P1 |
| BR-MSG-024 | Supplementary / Compartment: student failing in 1-2 subjects can be marked as "Compartment" instead of "Fail" (configurable threshold) | — | P2 |
| BR-MSG-025 | Best-of-N option: school can configure "best 2 of 4 unit tests count" for exam component (optional, off by default) | LmsExam | P2 |
| BR-MSG-026 | Online and Offline exam results are treated identically at the marksheet level — both read from `lms_exam_results`. Paper mode (`lms_exam_papers.mode`) is transparent to marksheet | LmsExam | P0 |
| BR-MSG-027 | Config templates are immutable once linked to a published schedule. To change config, create a new template version | — | P1 |
| BR-MSG-028 | Class grouping for marksheet purposes must be created within this module (`msh_class_groups`) since `sch_class_groups_jnt` is timetable-specific | SchoolSetup | P0 |

---

## Section 4 — Functional Requirements

### 4.1 Configuration Setup (FR-MSG-001 to FR-MSG-005)

| FR ID | Feature Name | Screen | Source Tables (READ) | Target Tables (WRITE) | Business Rules |
|---|---|---|---|---|---|
| FR-MSG-001 | Marksheet Type Master | SC-MSG-01 | — | `msh_marksheet_types` | CRUD for marksheet types (Unit Test, Term-1, Annual). School-configurable |
| FR-MSG-002 | Config Template Builder | SC-MSG-03 | `slb_grade_division_master` | `msh_config_templates`, `msh_template_scholastic_components` | Create/edit template. Select grading schema. Add source components with weightage. Sum = 100% (BR-MSG-002) |
| FR-MSG-003 | Exam Weightage Setup | SC-MSG-04 | `lms_exam_types` | `msh_template_exam_weightages` | Per-exam-type weightage within Exam component. Sum = 100% (BR-MSG-003) |
| FR-MSG-004 | Class Group Management | SC-MSG-07a | `sch_classes` | `msh_class_groups`, `msh_class_group_items_jnt` | Create marksheet-specific class groups (Primary=Classes 1-5, Middle=6-8, etc.) (BR-MSG-028) |
| FR-MSG-005 | Exam Group Setup | SC-MSG-02 | `lms_exam_types` | `msh_exam_groups`, `msh_exam_group_items_jnt` | Group exam types into terms. Term-1=UT1+UT2+HY. Annual=ALL (BR-MSG-004) |

### 4.2 IA & Co-Scholastic Configuration (FR-MSG-006 to FR-MSG-009)

| FR ID | Feature Name | Screen | Source Tables (READ) | Target Tables (WRITE) | Business Rules |
|---|---|---|---|---|---|
| FR-MSG-006 | IA Component Setup | SC-MSG-05 | — | `msh_template_ia_components` | Define IA components per template (Notebook=5, Enrichment=5, etc.). Sum = IA max marks (BR-MSG-007) |
| FR-MSG-007 | Co-Scholastic Area Setup | SC-MSG-06 | `ba_config` | `msh_template_coscholastic_components` | Define co-scholastic areas (Work Ed, Art, Health & PE). Link Discipline to BA module if enabled (BR-MSG-008, BR-MSG-009) |
| FR-MSG-008 | Practical Config | SC-MSG-08 | `sch_subjects`, `sch_classes` | `msh_subject_practical_configs` | Set theory-practical split per class-subject. Theory 70 + Practical 30 = 100 (BR-MSG-006) |
| FR-MSG-009 | Promotion Criteria Config | (within Template Builder) | — | `msh_config_templates` (fields) | Configure pass marks percentage, max failures for compartment (BR-MSG-015, BR-MSG-024) |

### 4.3 Class Assignment (FR-MSG-010 to FR-MSG-012)

| FR ID | Feature Name | Screen | Source Tables (READ) | Target Tables (WRITE) | Business Rules |
|---|---|---|---|---|---|
| FR-MSG-010 | Class/Group Template Assignment | SC-MSG-07 | `sch_classes`, `msh_class_groups` | `msh_class_config_jnt` | Assign template to class-group or individual class. Direct class assignment overrides group (BR-MSG-005) |
| FR-MSG-011 | Elective Subject Resolution | (automatic) | `sch_class_groups_jnt` (timetable), `std_student_academic_sessions` | — | Resolve which subjects each student takes. Elective students get only their enrolled subjects (BR-MSG-011) |
| FR-MSG-012 | Best-of-N Configuration | (within Template Builder) | — | `msh_config_templates` (fields) | Optional: configure how many unit tests count (best 2 of 4). Off by default (BR-MSG-025) |

### 4.4 Marksheet Schedule Management (FR-MSG-013 to FR-MSG-015)

| FR ID | Feature Name | Screen | Source Tables (READ) | Target Tables (WRITE) | Business Rules |
|---|---|---|---|---|---|
| FR-MSG-013 | Marksheet Schedule Setup | SC-MSG-10 | `msh_exam_groups`, `msh_marksheet_types`, `sch_class_section_jnt` | `msh_marksheet_schedules`, `msh_schedule_class_jnt` | Create schedule: select type, exam group, class-sections, date range (BR-MSG-020) |
| FR-MSG-014 | Marksheet Schedule Dashboard | SC-MSG-09 | `msh_marksheet_schedules` | — | List all schedules with status, student count, action buttons (compute/review/publish) |
| FR-MSG-015 | Attendance Entry | SC-MSG-09a | — | `msh_student_attendance` | Manual entry of working days + days present per student per schedule (BR-MSG-019). Auto-populate from Attendance module if available |

### 4.5 Result Computation Engine (FR-MSG-016 to FR-MSG-021)

| FR ID | Feature Name | Screen | Source Tables (READ) | Target Tables (WRITE) | Business Rules |
|---|---|---|---|---|---|
| FR-MSG-016 | Trigger Computation | SC-MSG-11 | — | `msh_computation_logs` | Admin clicks "Compute Results" → dispatches `ComputeMarksheetJob` for the schedule (BR-MSG-022) |
| FR-MSG-017 | Exam Score Aggregation | (service) | `lms_exam_results`, `lms_exam_papers`, `lms_exams`, `lms_exam_types` | `msh_student_subject_exam_marks` | For each student × subject × exam-type: fetch `lms_exam_results.total_marks_obtained`. Apply per-exam weightage. Handle ABSENT/WITHHELD (BR-MSG-003, BR-MSG-016, BR-MSG-023, BR-MSG-026) |
| FR-MSG-018 | Homework/Quiz/Quest Aggregation | (service) | `lms_homework_submissions`, `lms_quiz_quest_results` | `msh_student_subject_results` (component breakdowns) | Average graded scores per student per subject within date range. Apply component weightage (BR-MSG-018) |
| FR-MSG-019 | IA Marks Collection | SC-MSG-12a | — | `msh_student_ia_marks` | Teacher enters IA marks per student per subject (Notebook, Enrichment, etc.) per schedule (BR-MSG-007) |
| FR-MSG-020 | Subject Total Computation | (service) | All computed component scores | `msh_student_subject_results` | Subject Total = Exam weighted + HW weighted + Quiz weighted + Quest weighted + IA total. Theory + Practical split if applicable. Apply grading schema → grade per subject (BR-MSG-010, BR-MSG-012) |
| FR-MSG-021 | Overall Aggregation | (service) | `msh_student_subject_results` | `msh_student_results` | Grand total, percentage, overall grade, rank in class-section, division, promotion status (BR-MSG-013, BR-MSG-014, BR-MSG-015) |

### 4.6 Result Review & Publication (FR-MSG-022 to FR-MSG-024)

| FR ID | Feature Name | Screen | Source Tables (READ) | Target Tables (WRITE) | Business Rules |
|---|---|---|---|---|---|
| FR-MSG-022 | Result Review Grid | SC-MSG-12 | `msh_student_subject_results`, `msh_student_results` | — | Class-level view: Student × Subject × Exam matrix. Principal/teacher reviews before publication |
| FR-MSG-023 | Publish Marksheet | SC-MSG-14 | — | `msh_marksheet_schedules` (status) | Change schedule status to Published. Notify teachers, students, parents. Lock results (BR-MSG-017) |
| FR-MSG-024 | Unlock & Recompute | SC-MSG-14 | — | `msh_marksheet_schedules`, `msh_computation_logs` | Admin enters unlock reason → status back to Computed → recompute allowed. Audit entry written (BR-MSG-017) |

### 4.7 Marksheet PDF & Reports (FR-MSG-025 to FR-MSG-027)

| FR ID | Feature Name | Screen | Source Tables (READ) | Target Tables (WRITE) | Business Rules |
|---|---|---|---|---|---|
| FR-MSG-025 | Individual Student Marksheet Preview | SC-MSG-13 | All result tables | — | Full marksheet: Scholastic (subject × exam matrix) + Co-Scholastic + Attendance + Rank + Promotion |
| FR-MSG-026 | PDF Marksheet Generation | SC-MSG-15 | All result tables | — (PDF file output) | DomPDF. Inline styles. Table layout. School logo + header. Board format. Signature placeholder (BR-MSG-021) |
| FR-MSG-027 | Bulk PDF Download | SC-MSG-15 | All result tables | — (ZIP file output) | Download all marksheets for a class-section as a ZIP of PDFs |

### 4.8 Portal Integration (FR-MSG-028 to FR-MSG-030)

| FR ID | Feature Name | Screen | Source Tables (READ) | Target Tables (WRITE) | Business Rules |
|---|---|---|---|---|---|
| FR-MSG-028 | Student Portal Marksheet View | (StudentPortal route) | `msh_student_results`, `msh_student_subject_results` | — | Student sees own published marksheets. Scoped to own student_id (IDOR prevention) |
| FR-MSG-029 | Parent Portal Marksheet View | (ParentPortal route) | Same as above | — | Parent sees child's published marksheets. Scoped to linked children (IDOR prevention) |
| FR-MSG-030 | Co-Scholastic Entry | SC-MSG-06a | — | `msh_student_coscholastic_results` | Class teacher / coordinator enters co-scholastic grades (A/B/C) per student per schedule (BR-MSG-008) |

---

## Section 5 — Indian Board Marksheet Patterns

### Pattern 1 — CBSE Classes 9-12 (Full Scholastic + Co-Scholastic)

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        [SCHOOL LOGO]  SCHOOL NAME                               │
│                        Affiliated to CBSE (Affiliation No: XXXXXXX)             │
│                        REPORT CARD — Session 2025-26 (Term-1)                   │
│                                                                                  │
│  Student: ________    Class: IX-A    Roll No: __    DOB: __                      │
├─────────────────────────────────────────────────────────────────────────────────┤
│  PART A — SCHOLASTIC AREAS                                                       │
│                                                                                  │
│  Subject     │ PT-1(10)│ PT-2(10)│ HY(80) │ Notebook(5)│ Enrich(5)│ Total │Grade│
│  ────────────┼─────────┼─────────┼────────┼────────────┼──────────┼───────┼─────│
│  English     │    8    │    7    │   64   │     4      │    4     │  87   │ A2  │
│  Hindi       │    9    │    8    │   72   │     5      │    5     │  99   │ A1  │
│  Mathematics │    7    │    6    │   58   │     4      │    3     │  78   │ B1  │
│  Science*    │    8    │    7    │   52/70│  3  │  4  │ 74+25=99│ A1  │
│  Social Sci  │    6    │    7    │   60   │     4      │    4     │  81   │ A2  │
│  Computer*   │    9    │    9    │   56/70│  5  │  5  │ 84+28=112→remap│ A1 │
│                                                                                  │
│  * Subjects with Practical: Theory marks + Practical marks shown separately      │
│                                                                                  │
│  PART B — CO-SCHOLASTIC AREAS                                                    │
│  Work Education           │ A                                                    │
│  Art Education            │ B                                                    │
│  Health & Physical Ed     │ A                                                    │
│                                                                                  │
│  PART C — DISCIPLINE                                                             │
│  Overall Grade: A   (from BehaviouralAssessment module)                          │
│                                                                                  │
│  Attendance: 110 / 114 working days                                              │
│  Overall Grade: A1   │   Rank: 5 / 42   │   Result: Promoted to Class X         │
│                                                                                  │
│  Class Teacher: ___________      Principal: ____________    Date: ___________    │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Pattern 2 — Primary Classes 1-5 (Simplified)

```
Subject    │ FA-1(10) │ FA-2(10) │ SA-1(30) │ FA-3(10) │ FA-4(10) │ SA-2(30) │ Total │ Grade
────────────┼──────────┼──────────┼──────────┼──────────┼──────────┼──────────┼───────┼──────
English     │    8     │    7     │   24     │    8     │    9     │   26     │  82   │  A2
Mathematics │    9     │    8     │   27     │    7     │    8     │   28     │  87   │  A2
EVS         │    7     │    8     │   22     │    9     │    8     │   25     │  79   │  B1
Hindi       │    8     │    9     │   26     │    8     │    7     │   27     │  85   │  A2

(No practicals, no IA breakdown, simple grading)
```

### Pattern 3 — State Board / Custom

Schools using state board affiliation or international curricula can define their own:
- Custom exam types and weightages
- Custom grading schemas via `slb_grade_division_master`
- Custom number of assessment components
- No mandatory structure — the configuration must be flexible

---

## Section 6 — Use Case Matrix

| UC ID | Actor | Trigger | Main Flow | Alternate Flow |
|---|---|---|---|---|
| UC-MSG-001 | Admin | Academic year start | Creates marksheet class groups (Primary=1-5, Middle=6-8, Secondary=9-12) | Skip if school has only one class level |
| UC-MSG-002 | Admin | After exam types defined | Creates exam groups (Term-1=UT1+UT2+HY, Term-2=UT3+UT4+Annual) | Single "Annual" group if school does one marksheet per year |
| UC-MSG-003 | Admin | Configuration phase | Creates config template with source components + weightages for "CBSE Secondary" | Copy from previous year's template if available |
| UC-MSG-004 | Admin | Within template | Sets per-exam weightage: UT1=10%, UT2=10%, HY=80% | Equal weightage if school prefers |
| UC-MSG-005 | Coordinator | Within template | Configures IA components: Notebook=5, Subject Enrichment=5 | No IA if not applicable (Primary classes) |
| UC-MSG-006 | Coordinator | Per subject | Configures practical split for Science (Theory=70, Practical=30) | No practical config for non-lab subjects |
| UC-MSG-007 | Admin | After template ready | Assigns template to class group "Secondary" → applies to Classes 9-12 | Override for Class 12 if different practical subjects |
| UC-MSG-008 | Admin | After exams concluded | Creates marksheet schedule: "Term-1 Report Card" for Classes 9-12, linked to Term-1 exam group | Per-exam marksheet if school wants one after each UT |
| UC-MSG-009 | Admin | Schedule ready | Triggers "Compute Results" → system dispatches ComputeMarksheetJob | Computation fails if source exam results not yet published → error logged |
| UC-MSG-010 | System | Job running | For each student: fetches exam scores, HW/Quiz/Quest averages, applies weightage, computes subject totals, grades, rank | Student has ABSENT for an exam → that exam marked "AB", weightage redistributed or "AB" propagated |
| UC-MSG-011 | Class Teacher | After computation | Reviews result grid: Student × Subject × Exam marks. Flags anomalies | Requests recomputation if source marks were corrected |
| UC-MSG-012 | Class Teacher | IA entry | Enters Notebook and Enrichment marks per student per subject | Bulk upload via Excel (future enhancement) |
| UC-MSG-013 | Class Teacher | Co-Scholastic | Enters co-scholastic grades (A/B/C) for Work Ed, Art, Health & PE per student | BA discipline grade auto-populated if BA module active |
| UC-MSG-014 | Admin/Principal | After review | Publishes marksheet → status=Published → students and parents notified | Principal rejects → sends back for correction |
| UC-MSG-015 | Admin | Error discovered | Unlocks published marksheet: enters reason "Marks correction for student X in Math" → audit log entry → status=Computed | If already printed, flag for re-printing |
| UC-MSG-016 | Student | After publication | Opens Student Portal → sees list of published marksheets → clicks to view | Marksheet not yet published → "Results will be available soon" |
| UC-MSG-017 | Parent | After publication | Opens Parent Portal → sees child's marksheets → downloads PDF | Multiple children → each child's marksheet accessible |
| UC-MSG-018 | Teacher/Admin | PDF needed | Clicks "Download PDF" → system generates DomPDF marksheet → serves as download | Bulk download → ZIP of all student PDFs for a class-section |

---

## Section 7 — Integration Contracts (Verified Column References)

### 7.1 LmsExam — PRIMARY SOURCE

```
Score Source:      lms_exam_results (table in StudentAttempt_ddl_v3.sql)
Join Path:         lms_exam_results.exam_paper_id → lms_exam_papers.id
                   lms_exam_papers.exam_id → lms_exams.id
                   lms_exam_papers.subject_id → sch_subjects.id
                   lms_exams.exam_type_id → lms_exam_types.id
                   lms_exams.class_id → sch_classes.id
                   lms_exams.academic_session_id → glb_academic_sessions.id

Score Columns:     lms_exam_results.total_marks_obtained  (DECIMAL 8,2)
                   lms_exam_results.total_marks_possible   (DECIMAL 8,2)
                   lms_exam_results.percentage             (DECIMAL 5,2)
                   lms_exam_results.grade_obtained         (VARCHAR 10)
                   lms_exam_results.result_status          ENUM('PASS','FAIL','ABSENT','WITHHELD')

Paper Max Marks:   lms_exam_papers.total_marks             (DECIMAL 8,2)
Paper Mode:        lms_exam_papers.mode                    ENUM('ONLINE','OFFLINE')
                   → Transparent to marksheet; both produce lms_exam_results

Exam Type Link:    lms_exams.exam_type_id → lms_exam_types.id
                   lms_exam_types.code = 'UT-1','UT-2','HY-EXAM','ANNUAL-EXAM' etc.

Unique Key:        lms_exam_results: UNIQUE(exam_paper_id, student_id)
Published Guard:   lms_exam_results.is_published = 1

Query Pattern:
  SELECT er.student_id, er.total_marks_obtained, er.total_marks_possible,
         er.result_status, ep.subject_id, et.code AS exam_type_code
  FROM lms_exam_results er
  JOIN lms_exam_papers ep ON er.exam_paper_id = ep.id
  JOIN lms_exams e ON ep.exam_id = e.id
  JOIN lms_exam_types et ON e.exam_type_id = et.id
  WHERE e.academic_session_id = ?
    AND e.class_id = ?
    AND ep.subject_id = ?
    AND et.id IN (... exam types in the exam group ...)
    AND er.is_published = 1
    AND er.is_active = 1
```

### 7.2 LmsHomework

```
Score Source:      lms_homework_submissions
Join Path:         lms_homework_submissions.homework_id → lms_homework.id

Score Columns:     lms_homework_submissions.marks_obtained  (DECIMAL 5,2)
Max Marks:         lms_homework.max_marks                   (DECIMAL 5,2)
Gradable Guard:    lms_homework.is_gradable = 1

Filter:            lms_homework.class_id = ?
                   lms_homework.subject_id = ?
                   lms_homework.academic_session_id = ?
                   lms_homework_submissions.status_id = (GRADED from sys_dropdown_table)
Date Filter:       lms_homework.due_date BETWEEN schedule.start_date AND schedule.end_date

Aggregation:       AVG(marks_obtained / max_marks) * component_max_marks
                   Across all graded submissions for that student + subject within range

VERIFIED COLUMNS:
  ✅ lms_homework_submissions.marks_obtained (DECIMAL 5,2) — line 233 of DDL v4
  ✅ lms_homework.max_marks (DECIMAL 5,2) — line 58 of DDL v4
  ✅ lms_homework.is_gradable (TINYINT) — line 57 of DDL v4
  ✅ lms_homework.class_id, .subject_id, .academic_session_id — lines 43-46
```

### 7.3 LmsQuiz / LmsQuest

```
Score Source:      lms_quiz_quest_results (shared table for both)
Discriminator:     lms_quiz_quest_results.assessment_type = 'QUIZ' or 'QUEST'

Score Columns:     lms_quiz_quest_results.total_marks_obtained  (DECIMAL 8,2)
                   lms_quiz_quest_results.max_marks             (DECIMAL 8,2)
                   lms_quiz_quest_results.percentage            (DECIMAL 5,2)
Published Guard:   lms_quiz_quest_results.is_published = 1

Subject Join:      lms_quiz_quest_results.assessment_id → lms_quizzes.id (for QUIZ)
                   lms_quiz_quest_results.assessment_id → lms_quests.id  (for QUEST)
                   lms_quizzes.subject_id / lms_quests.subject_id → sch_subjects.id

Filter:            lms_quizzes.class_id (or lms_quests.class_id) = ?
                   lms_quizzes.subject_id (or lms_quests.subject_id) = ?
                   lms_quizzes.academic_session_id = ?

Aggregation:       AVG(percentage) across all published results in date range per subject

NOTE: assessment_id in lms_quiz_quest_results is polymorphic (points to lms_quizzes.id
      when assessment_type='QUIZ', or lms_quests.id when assessment_type='QUEST').
      The join must be conditional on assessment_type.

VERIFIED COLUMNS:
  ✅ lms_quiz_quest_results.total_marks_obtained (DECIMAL 8,2) — line 177 of DDL v3
  ✅ lms_quiz_quest_results.max_marks (DECIMAL 8,2) — line 178
  ✅ lms_quiz_quest_results.percentage (DECIMAL 5,2) — line 179
  ✅ lms_quiz_quest_results.assessment_type ENUM('QUIZ','QUEST') — line 174
  ✅ lms_quiz_quest_results.is_published (TINYINT) — line 185
```

### 7.4 BehaviouralAssessment (Co-Scholastic Section)

```
API Call:          BehaviouralScoreService::getStudentScore(studentId, periodId)
Returns:           { numeric_score, grade, category_scores[] }

Pre-condition:     ba_config.is_result_integration_enabled = true
                   AND school has configured BA component in msh_template_coscholastic_components

Usage:             Maps to Co-Scholastic "Discipline" row on marksheet
                   Grade value (A/B/C or 1-5) displayed directly

VERIFIED from BA_DDL_v2.sql:
  ✅ ba_computed_scores — cached per-student scores (student_id, category_id, period_id)
  ✅ ba_config — session config with rating_scale_id, is_result_integration_enabled
  ✅ BehaviouralScoreService — pull-based integration (BA never writes to exm_* tables)
```

### 7.5 SchoolSetup (Cross-Module References)

```
VERIFIED from tenant_db_v2.sql:
  ✅ sch_classes (id INT UNSIGNED, code CHAR(5), short_name, name) — line 4209
  ✅ sch_sections (id INT UNSIGNED, code CHAR(5), short_name, name) — line 4227
  ✅ sch_class_section_jnt (id, class_id, section_id, code, class_teacher_id) — line 4244
  ✅ sch_subjects (id INT UNSIGNED, code CHAR(5), short_name, name) — line 4311
  ✅ slb_grade_division_master (id, code, name, grading_type ENUM('GRADE','DIVISION'),
     min_percentage, max_percentage, board_code, scope, class_id) — line 5034

⚠️ IMPORTANT FINDING:
  sch_class_groups_jnt is a TIMETABLE-SPECIFIC junction (class+section+subject+study_format).
  It is NOT a simple class grouping table (Primary, Middle, Secondary).
  → MarksheetGeneration must create its own msh_class_groups table.
```

### 7.6 Attendance (Conditional)

```
Status:            Attendance module (att_*) is planned but NOT yet built.
                   Basic attendance exists in StudentProfile (zero-auth controller — SEC issue).

Strategy:          
  Phase 1: Manual entry of attendance summary via msh_student_attendance table
  Phase 2: Auto-populate from Attendance module when available (via service interface)

Columns Needed:    total_working_days (INT), days_present (INT) per student per schedule
```

---

## Section 8 — Screen Inventory

| Screen ID | Screen Name | Actor | Key Fields / Actions |
|---|---|---|---|
| SC-MSG-01 | Marksheet Type Master | Admin | CRUD: code, name, description. E.g., "Unit Test", "Term-1 Report", "Annual Report Card" |
| SC-MSG-02 | Exam Group Setup | Admin | Create group (name, description) + select exam types to include (multi-select from lms_exam_types). E.g., Term-1 = [UT-1, UT-2, HY-EXAM] |
| SC-MSG-03 | Config Template Builder | Admin | Create template: name, academic_session, marksheet_type, grading_schema. Add scholastic components (Exam, HW, Quiz, Quest) with weightage. Sum validation |
| SC-MSG-04 | Exam Weightage Setup | Admin | Within template: for each exam type in linked exam group, set weightage percentage. Sum = 100% |
| SC-MSG-05 | IA Component Setup | Coordinator | Within template: define IA components (Notebook=5 marks, Subject Enrichment=5, etc.) |
| SC-MSG-06 | Co-Scholastic Area Setup | Coordinator | Define areas: Work Education, Art Education, Health & PE, Discipline. Grading type (A/B/C). Link Discipline to BA if enabled |
| SC-MSG-06a | Co-Scholastic Entry Grid | Class Teacher | Student × Co-Scholastic area matrix. Enter A/B/C per student per area. Auto-populate Discipline from BA |
| SC-MSG-07 | Class/Group Template Assignment | Admin | Left panel: class groups / individual classes. Right panel: available templates. Assign with drag-drop or select. Show inheritance (group → classes) |
| SC-MSG-07a | Class Group Management | Admin | CRUD class groups: name (Primary, Middle, Secondary), add/remove classes. Note: separate from timetable's sch_class_groups_jnt |
| SC-MSG-08 | Practical Config | Coordinator | Class-Subject grid. Toggle "Has Practical" per subject. If yes: Theory marks + Practical marks (must sum to exam paper total) |
| SC-MSG-09 | Marksheet Schedule Dashboard | Admin | Table: Schedule Name, Type, Exam Group, Classes, Status (Draft/Computed/Published), Student Count, Actions (Compute/Review/Publish) |
| SC-MSG-09a | Attendance Entry | Class Teacher | Student list for class-section. Enter working_days and days_present per student per schedule. Bulk upload option |
| SC-MSG-10 | Marksheet Schedule Setup | Admin | Create: name, marksheet_type, exam_group, academic_session, start_date, end_date, select class-sections |
| SC-MSG-11 | Computation Progress | Admin | "Compute Results" button → shows real-time job progress (Livewire polling). Class-section by class-section. Error log if any |
| SC-MSG-12 | Result Review Grid | Principal/Teacher | Matrix view: Rows=Students, Columns=Subjects. Each cell shows exam-wise breakdown + total + grade. Highlight anomalies (AB, WH, very low). Filter by class-section |
| SC-MSG-12a | IA Marks Entry | Subject Teacher | Student × IA Component grid per subject. Enter marks per student. Validate ≤ max marks per component |
| SC-MSG-13 | Individual Student Marksheet Preview | Teacher/Admin | Full marksheet view: Scholastic table + Co-Scholastic + Attendance + Rank + Division + Promotion. Matches PDF format |
| SC-MSG-14 | Publication & Lock | Admin/Principal | Buttons: Review → Publish → Lock. Unlock button (requires reason text). Audit log visible |
| SC-MSG-15 | Marksheet PDF Download | All | "Download PDF" for individual student. "Bulk Download" for class-section (ZIP). Preview before download |

---

## Section 9 — Non-Functional Requirements

| NFR ID | Category | Requirement | Implementation Note |
|---|---|---|---|
| NFR-MSG-001 | Multi-Tenancy | All `msh_*` tables are tenant-scoped. No `tenant_id` column. stancl/tenancy v3.9 database-per-tenant | Standard tenant migration path |
| NFR-MSG-002 | Performance | Bulk computation for 500 students × 8 subjects × 6 exams must complete within 60 seconds | Queued job, chunked per class-section (50 students/chunk). Eager load relationships |
| NFR-MSG-003 | Performance | PDF generation for one student ≤ 3 seconds. Bulk PDF for 50 students ≤ 30 seconds | DomPDF with cached CSS. Generate in queue for bulk |
| NFR-MSG-004 | Concurrency | Two admins cannot trigger computation for the same schedule simultaneously | DB lock on `msh_marksheet_schedules.status` + optimistic locking |
| NFR-MSG-005 | Caching | Computed results cached in `msh_student_*` tables. PDF cached per student per schedule with cache key | Redis or file cache. Invalidate on recomputation |
| NFR-MSG-006 | RBAC | Laravel Policies on every model. `Gate::authorize()` in every controller method. No hardcoded `true` in `FormRequest::authorize()` | Follow D30 mitigation pattern |
| NFR-MSG-007 | Audit Trail | Every computation run logged in `msh_computation_logs`. Every unlock logged with reason, user, timestamp | Immutable log entries |
| NFR-MSG-008 | PDF Quality | DomPDF with inline styles only. Table-based layout (no flexbox/grid). No JavaScript. No Bootstrap classes. School logo as base64 | Follow HPC DomPDF pattern (D13) |
| NFR-MSG-009 | Localisation | All user-facing labels support Hindi/English via `__()` helper. Subject names from SchoolSetup (already localised) | Laravel localisation files |
| NFR-MSG-010 | Data Retention | Soft deletes on all `msh_*` entities. Published marksheets retained for school's configured retention period (default: 5 academic sessions) | Configurable in `msh_config_templates` |
| NFR-MSG-011 | Security | Student marksheet access scoped to own student_id. Parent access scoped to linked children. PDF download via signed URL (`URL::temporarySignedRoute`) | IDOR prevention on all data endpoints |
| NFR-MSG-012 | No ENUMs | All status fields and type fields use `sys_dropdown_table` or dedicated lookup tables. No ENUM columns in any `msh_*` table | Per project-wide rule |

---

## Section 10 — Computation Algorithm

```
MarksheetComputationService::computeForSchedule(scheduleId):

INPUT:
  schedule → { id, exam_group_id, academic_session_id, start_date, end_date }
  class_sections → from msh_schedule_class_jnt
  config_template → resolved per class via msh_class_config_jnt (direct → group inheritance)

ALGORITHM:

1. VALIDATE PRE-CONDITIONS
   - Schedule status must be 'draft' or 'computed' (not 'published' or 'locked')
   - All exam results in the linked exam group must have is_published = 1
   - Config template must exist for every class in the schedule
   
2. FOR EACH class_section_id IN schedule.class_sections:
   
   2a. RESOLVE CONFIG
       config = msh_class_config_jnt WHERE class_id = class_section.class_id
       IF NOT FOUND → check msh_class_config_jnt WHERE class_group includes this class
       IF STILL NOT FOUND → log error, skip class-section
   
   2b. LOAD STUDENTS
       students = std_students enrolled in this class_section for this academic_session
   
   2c. LOAD SUBJECTS
       For each student, resolve their subject list:
       - Core subjects: all mandatory subjects for the class
       - Elective subjects: student-specific (from class_groups_jnt enrollment)
   
   2d. FOR EACH student:
       
       ════════════════════════════════════════════════════
       STEP A — EXAM MARKS (per subject, per exam type)
       ════════════════════════════════════════════════════
       
       FOR EACH subject IN student.subjects:
         FOR EACH exam_type IN exam_group.exam_types:
           
           score = ExamScoreReader.getScore(student_id, exam_type_id, subject_id, session_id)
           
           IF score.result_status = 'ABSENT' → store "AB", marks = NULL
           IF score.result_status = 'WITHHELD' → store "WH", marks = NULL
           ELSE → store score.total_marks_obtained
           
           IF subject has practical config:
             theory_paper = paper WHERE mode=any AND is_theory=true (TBD: may need flag)
             practical_paper = paper WHERE mode=any AND is_practical=true
             theory_marks = theory exam result
             practical_marks = practical exam result
           
           exam_weightage = msh_template_exam_weightages[exam_type_id].weightage_percent
           weighted_exam_mark = marks * exam_weightage / 100
           
           → STORE in msh_student_subject_exam_marks
         
         exam_component_total = SUM(weighted_exam_marks for all exams in group)
         
         IF best_of_n enabled:
           Sort unit test marks descending, take top N, recompute weighted total
       
       ════════════════════════════════════════════════════
       STEP B — HOMEWORK COMPONENT (per subject, if configured)
       ════════════════════════════════════════════════════
       
       IF 'Homework' IN template.scholastic_components:
         FOR EACH subject:
           hw_scores = HomeworkScoreReader.getScores(student_id, subject_id, session_id,
                                                      schedule.start_date, schedule.end_date)
           IF hw_scores is empty → component_score = NULL
           ELSE → avg_pct = AVG(marks_obtained / max_marks) across all graded HWs
                  component_score = avg_pct * hw_component_max_marks
       
       ════════════════════════════════════════════════════
       STEP C — QUIZ / QUEST COMPONENT (per subject, if configured)
       ════════════════════════════════════════════════════
       
       Same pattern as Homework but reading from lms_quiz_quest_results.
       Filter by assessment_type = 'QUIZ' or 'QUEST' respectively.
       
       ════════════════════════════════════════════════════
       STEP D — INTERNAL ASSESSMENT (per subject, if configured)
       ════════════════════════════════════════════════════
       
       IF template has IA components:
         FOR EACH subject:
           FOR EACH ia_component (Notebook, Enrichment, etc.):
             ia_marks = msh_student_ia_marks[student_id, subject_id, ia_component_id, schedule_id]
             (Entered by teacher via SC-MSG-12a)
       
       ════════════════════════════════════════════════════
       STEP E — SUBJECT TOTAL + GRADE
       ════════════════════════════════════════════════════
       
       FOR EACH subject:
         IF has practical split:
           theory_total = exam_theory_weighted + hw_weighted + quiz_weighted + quest_weighted + ia_total
           practical_total = exam_practical_marks (not weighted — raw marks)
           subject_total = theory_total + practical_total
         ELSE:
           subject_total = exam_weighted + hw_weighted + quiz_weighted + quest_weighted + ia_total
         
         subject_percentage = subject_total / subject_max * 100
         subject_grade = LOOKUP slb_grade_division_master WHERE grading_type='GRADE'
                         AND min_percentage <= subject_percentage < max_percentage
         subject_pass = subject_percentage >= passing_percentage (from template)
         
         → STORE in msh_student_subject_results
       
       ════════════════════════════════════════════════════
       STEP F — CO-SCHOLASTIC
       ════════════════════════════════════════════════════
       
       Already entered by teacher via SC-MSG-06a.
       If Discipline linked to BA → call BehaviouralScoreService.getStudentScore(student_id, period_id)
       → STORE/UPDATE in msh_student_coscholastic_results
       
       ════════════════════════════════════════════════════
       STEP G — OVERALL AGGREGATION
       ════════════════════════════════════════════════════
       
       grand_total = SUM(subject_total) across all subjects
       grand_max = SUM(subject_max) across all subjects
       overall_percentage = grand_total / grand_max * 100
       overall_grade = LOOKUP slb_grade_division_master WHERE grading_type='GRADE'
       division = LOOKUP slb_grade_division_master WHERE grading_type='DIVISION'
       
       failed_subjects = COUNT(subjects WHERE subject_pass = false)
       IF failed_subjects = 0 → promotion_status = 'PROMOTED'
       ELIF failed_subjects <= compartment_threshold → promotion_status = 'COMPARTMENT'
       ELSE → promotion_status = 'DETAINED'
       
       → STORE in msh_student_results
   
   2e. COMPUTE RANKS for this class-section
       ORDER students BY grand_total DESC → assign rank 1, 2, 3...
       Ties share the same rank (dense ranking)
       → UPDATE msh_student_results.rank_in_section

3. UPDATE msh_marksheet_schedules.status = 'computed'

4. INSERT msh_computation_logs (schedule_id, triggered_by, started_at, completed_at,
                                 total_students, status='SUCCESS', error_log=NULL)
```

---

## Section 11 — Open Questions (To resolve before Sprint 1)

| # | Question | Default Assumption | Impact If Wrong |
|---|---|---|---|
| 1 | Should `msh_source_components` be seeded as fixed (4 rows: Exam, HW, Quiz, Quest) or allow school to add custom components? | **Fixed 4 rows** — seeded during tenant onboarding | If custom needed, need CRUD screen + validation changes |
| 2 | When a student has ZERO graded items in Homework/Quiz within the date range, is the component score NULL ("not assessed") or 0? | **NULL** — treated as "not assessed", does not drag down total | If 0, failing students unfairly penalised |
| 3 | Should the Exam component support "best of N" (e.g., best 2 of 4 unit tests)? | **Off by default**, optional toggle on template | Adds complexity to computation engine |
| 4 | IA marks (Notebook, Subject Enrichment) — entered through this module's own screen, or do they exist elsewhere? | **This module owns IA entry** via SC-MSG-12a | If another module owns it, need read integration instead |
| 5 | Attendance data — does the Attendance module (`att_*`) exist with per-student daily data? | **Not yet built.** Manual entry in Phase 1, auto-populate in Phase 2 | If available, skip manual entry screen |
| 6 | Co-Scholastic grades (Work Ed, Art, Health & PE) — entered through this module or from another module? | **This module owns entry** via SC-MSG-06a | If HPC or another module owns it, need read integration |
| 7 | Board affiliation — should template include a "board type" field (CBSE/ICSE/State/Custom) to auto-suggest grading schema? | **Yes** — guides default grading schema selection | Minor UX impact if omitted |
| 8 | Student's subject list — resolved from which table? `sch_class_groups_jnt` has class+section+subject, but is that the enrollment or just timetable config? | **Assume `sch_class_groups_jnt`** filtered by class_id = student's class | If wrong, need a different join path |
| 9 | Promotion criteria — is "must pass all subjects" the only rule, or does school configure min pass count? | **Configurable** — `compartment_max_failures` field on template (default=2) | Simple if hardcoded, flexible if configurable |
| 10 | Should marksheet PDF support school-specific templates (custom headers, multiple formats) or one standard format? | **One standard format** with school logo + name configurable | If multiple formats needed, significant PDF work |
| 11 | For Term-1 marksheet — should HW/Quiz/Quest scores be from the FULL term date range, or only from a configurable "included assessments" list? | **Date range** (schedule.start_date to schedule.end_date) | If per-assessment selection needed, add junction table |
| 12 | Is grade calculation per subject owned by this module, or should it reuse `lms_exam_results.grade_obtained`? | **This module computes its own grades** using `slb_grade_division_master`, since the marksheet grade considers all components (not just exam) | If reusing, grade won't reflect IA/HW/Quiz contributions |
| 13 | Theory vs Practical paper identification — how do we distinguish theory and practical exam papers within the same exam? Is there a flag on `lms_exam_papers`? | **⚠️ No `is_practical` flag found on `lms_exam_papers`**. May need a new flag or convention (e.g., paper title contains "Practical") | Critical for theory-practical split computation. Must verify or add flag |

---

**PHASE 1 COMPLETE.** Output saved to:
`{OLD_REPO}/1-DDL_Tenant_Modules/55h-MarksheetGeneration/MSG_RequirementSpec.md`

**Awaiting review and approval before proceeding to Phase 2 (DDL Schema + Data Dictionary).**
