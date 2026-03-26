# EXA — Examination Management
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** RBS_ONLY

---

## 1. Executive Summary

### 1.1 Purpose

The EXA module is the formal, traditional school examination management system for Prime-AI. It handles the complete institutional examination lifecycle as required by Indian K-12 schools: defining exam structures and type schemes (Unit Tests, Quarterly, Half-Yearly, Annual, Board exams), building examination timetables, managing seating arrangements and invigilator assignments, issuing admit cards, performing offline mark entry with moderation workflows, computing grades and GPA/CGPA through configurable grade scales, generating class and section rank lists, producing board-compliant PDF progress report cards with school branding, processing student promotions and detentions, and publishing results in a controlled manner to student/parent portals.

This module is architecturally and functionally distinct from LmsExam (`exm_*`), which handles digital question papers, automated online exams, and real-time proctoring. EXA manages the scheduled, paper-based institutional examinations that Indian schools legally require for student promotion, board registration, and accreditation.

### 1.2 Scope Summary

| Area | Coverage |
|---|---|
| Exam type & component configuration | Theory, Practical, Internal, Oral, Portfolio |
| Exam schedule management | Subject-wise date/time/hall/invigilator with conflict detection |
| Seating arrangement generation | Hall-wise, roll-number-wise, alphabetical, mixed-class patterns |
| Admit card generation | Per-student PDF via DomPDF with exam schedule, photo, roll number |
| Mark entry | Online grid, bulk Excel; absent/malpractice flags; component breakdown |
| Moderation workflow | HOD propose → Principal approve; full audit trail |
| Grace marks rules | Board-specific and school-configurable maximum |
| Grade scales | CBSE 10-point GPA, ICSE, percentage, custom multi-band |
| CCE support | FA1/FA2/SA1/SA2 formative+summative weight configuration |
| Result processing | Percentage, grade, GPA, rank, pass/fail, compartment |
| Report card generation | Multi-template PDF (CBSE/ICSE/IB/standard/custom); bilingual |
| Cumulative report card | All-term combined result in single report |
| Result publication | Gated publish with scheduled release date |
| Portal result viewing | Student/parent portal access post-publication |
| Board exam coordination | CBSE/ICSE registration, roll number assignment |
| Co-scholastic assessment | Activities, attitudes, sports, health (CBSE CCE) |
| Merit list & certificates | Top-N lists; CRT module integration |
| AI-based analytics | Weak-area detection, trend analysis, predictive risk alerts |

### 1.3 Module Statistics

| Metric | Count |
|---|---|
| RBS Feature Group | Module F (Examination & Assessment) |
| RBS Sub-features | F1–F6, FI1–FI10 |
| DB Tables (`exa_*`) | 22 |
| Named Routes (estimated) | ~80 |
| Blade Views (estimated) | ~50 |
| Controllers (estimated) | 14 |
| Models (estimated) | 22 |
| Services (estimated) | 6 |
| Jobs (estimated) | 4 |
| FormRequests (estimated) | 16 |

### 1.4 Implementation Status

| Layer | Status |
|---|---|
| DB Schema / Migrations | ❌ Not Started |
| Models | ❌ Not Started |
| Controllers | ❌ Not Started |
| Services | ❌ Not Started |
| FormRequests | ❌ Not Started |
| Blade Views | ❌ Not Started |
| Routes | ❌ Not Started |
| Jobs | ❌ Not Started |
| Tests | ❌ Not Started |

**Overall Implementation: 0% — Greenfield**

---

## 2. Module Overview

### 2.1 Business Purpose

Indian schools operate two fundamentally different exam systems that must not be conflated:

1. **Digital/LMS exams** — online MCQ tests, proctored digital assessments, auto-evaluated quizzes (handled by `EXM` and `QUZ` modules)
2. **Formal institutional examinations** — scheduled hall-based written exams with printed admit cards, signed answer sheets, invigilator oversight, manual mark entry, moderation workflows, rank lists, and printed/digital report cards

EXA addresses the second system entirely. The formal examination cycle in India:
- Directly governs student promotion and detention decisions
- Determines eligibility for board examinations (Class 10, Class 12)
- Forms the basis for transfer certificates and academic records
- Is mandated by CBSE, ICSE, and State Board regulatory frameworks
- Drives parent trust and school reputation

### 2.2 EXA vs EXM — Critical Distinction

| Dimension | EXA (This Module) | EXM (LMS Exam Module) |
|---|---|---|
| Nature | Offline paper-based | Online digital |
| Mark entry | Manual by teacher | Auto-evaluated (MCQ) or manual grading |
| Scheduling | Hall + invigilator + seating | Online room, timer, proctoring |
| Admit card | Physical PDF | Not applicable |
| Report card | PDF progress report | Online result dashboard |
| Board compliance | CBSE/ICSE format required | No board compliance |
| Primary user | Exam Controller, Subject Teacher | Student, LMS Teacher |

### 2.3 Exam Lifecycle States

```
draft → scheduled → ongoing → completed → published
```

Each state transition is gated at the service layer. State regression (e.g., back from `completed` to `ongoing`) requires explicit Admin override and is logged to `sys_activity_logs`.

### 2.4 Menu Path

`Examination > Dashboard`
`Examination > Exam Types`
`Examination > Exam Schedule`
`Examination > Seating Arrangement`
`Examination > Admit Cards`
`Examination > Mark Entry`
`Examination > Moderation`
`Examination > Results`
`Examination > Report Cards`
`Examination > CCE`
`Examination > Board Coordination`
`Examination > Analytics`
`Examination > Settings`

### 2.5 Architecture

The module is organized into six service layers:

| Service | Responsibility |
|---|---|
| `ExamScheduleService` | Exam event CRUD, conflict detection, status transitions |
| `SeatingService` | Auto-generation of seating plans and roll numbers |
| `MarkEntryService` | Mark validation, bulk upload, completion tracking |
| `ResultProcessingService` | Grade calculation, GPA, ranking, CCE combination |
| `ReportCardService` | PDF generation, template rendering, bulk dispatch |
| `ExamAnalyticsService` | Performance insights, weak-area detection, predictive risk |

---

## 3. Stakeholders & Roles

| Actor | Role Code | Responsibilities |
|---|---|---|
| Principal / Admin | `PRINCIPAL`, `ADMIN` | Creates exam types, approves exam schedule, approves moderation, publishes results, configures grade scales, final promotion decisions |
| Exam Controller | `EXAM_CONTROLLER` | Creates exam timetable, seating arrangements, coordinates invigilators, manages overall exam event |
| Head of Department | `HOD` | Reviews and verifies marks for their department; proposes moderation |
| Subject Teacher | `TEACHER` | Enters marks for assigned subjects; uploads bulk mark sheets; views subject analytics |
| Class Teacher | `CLASS_TEACHER` | Generates and distributes report cards; adds class teacher remarks; manages promotion list for their class |
| External Examiner | `EXAMINER` | Access to assigned practical exam papers only (read-only mark entry on assigned exam_subject_ids) |
| Student | `STUDENT` | Views published admit card; views published result, grade, rank, report card via portal |
| Parent | `PARENT` | Views child's published result, report card, promotion status via parent portal |
| System Scheduler | — | Runs batch result processing, bulk PDF generation, scheduled result publishing |

---

## 4. Functional Requirements

### FR-EXA-001: Exam Type & Component Configuration
**RBS Reference:** F.I1 (Exam Structure & Scheme) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables:** `exa_exam_types`, `exa_exam_components`

**Description:** CRUD management of exam type masters. Each exam type categorises the exam as formative (Unit Test, Class Test, FA-1/FA-2), summative (Mid-Term, Half-Yearly, SA-1/SA-2), annual, or board, and carries a session-level percentage weightage used for cumulative result computation. Components define the mark breakdown within an exam type: Theory, Practical, Internal Assessment, Oral, Portfolio. Multiple component definitions can exist per exam type with individual max/pass marks defaults.

**Actors:** Admin, Principal

**Processing Rules:**
- `weightage_percent` for all summative exam types within an academic session must total ≤ 100%
- `code` field enforced UNIQUE at DB level; uppercase convention recommended
- Deleting an exam type is blocked if active exams reference it (FK constraint + service-layer guard)
- At least one mandatory component (Theory) must exist per exam type
- Soft delete via `deleted_at`; restore preserves all child records

**Acceptance Criteria:**
- AC-001-01: Duplicate `code` returns HTTP 422 with field-level error
- AC-001-02: System warns when session cumulative weightage would exceed 100%
- AC-001-03: Exam type with active exams cannot be hard-deleted
- AC-001-04: Grade scale can be optionally assigned per exam type; falls back to school default

---

### FR-EXA-002: Exam Schedule Management
**RBS Reference:** F.I2 (Exam Timetable Scheduling) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables:** `exa_exams`, `exa_exam_subjects`, `exa_invigilators_jnt`

**Description:** Creation and management of named exam events with full timetable scheduling. An exam is a named event (e.g., "Half Yearly Examination 2025-26") linked to an academic session. Individual exam slots are created per subject per class-section with date, start/end time, hall, maximum marks, pass marks, component mark breakdown, and invigilator assignment. Conflict detection prevents scheduling the same student cohort in simultaneous exam slots or the same invigilator in two halls at the same time.

**Actors:** Exam Controller, Admin

**Processing Rules:**
- On slot save: detect if any student enrolled in the class-section has another exam slot at the same date/time
- Detect invigilator time conflicts across halls; chief invigilator cannot be assigned elsewhere simultaneously
- Validate: `pass_marks ≤ max_marks`; `theory_max + practical_max + internal_max = max_marks`
- Exam dates must fall within `sch_academic_sessions.from_date` to `to_date`
- Exam status `draft → scheduled` requires at least one complete subject slot
- Integration with ACD (Academic Calendar): exam period automatically flagged in `acd_calendar_events`

**Acceptance Criteria:**
- AC-002-01: Student timetable clash shows alert; save blocked unless Admin overrides
- AC-002-02: Invigilator conflict shows alert; save blocked unless Admin overrides
- AC-002-03: Component marks sum validation triggered on save and returns field-level error
- AC-002-04: Exam timetable printable as PDF with class-wise and subject-wise filters

---

### FR-EXA-003: Seating Arrangement Generation
**RBS Reference:** F.I2 (ST.I2.1.1.2) | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `exa_seating_arrangements`

**Description:** Automated generation of student seating plans for each exam hall per subject slot. Assigns hall seat numbers and exam roll numbers to students according to a configurable pattern. Supports mixed-class seating (students from different sections interleaved in the same hall). Allows manual override of individual seat assignments via drag-and-drop. Seating chart and individual seat slips are printable PDFs.

**Actors:** Exam Controller

**Seating Patterns:**
- `ROLL_ORDER` — students sorted by existing roll number
- `ALPHABETICAL` — sorted by name
- `RANDOM` — randomised allocation
- `MIXED_CLASS` — interleave students from multiple class-sections in the same hall

**Processing Rules:**
- Roll number auto-generated as `[class_code]-[section_code]-[sequence]` or as configured in exam settings
- Seat count validation: total students ≤ hall capacity from `sch_halls.capacity`
- Manual override: reassign seat with duplicate seat number check
- Regenerating seating invalidates previously generated admit cards for that exam

**Acceptance Criteria:**
- AC-003-01: Auto-generate fills all enrolled students; no duplicate seat assignment per hall per subject slot
- AC-003-02: Duplicate seat number on manual override returns HTTP 422
- AC-003-03: Seating chart PDF: student name, roll number, seat number, hall name
- AC-003-04: Mixed-class seating correctly interleaves students maintaining section identity fields

---

### FR-EXA-004: Admit Card / Hall Ticket Generation
**RBS Reference:** F.I2 / F.I6 | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `exa_admit_cards`

**Description:** Generation of individual PDF admit cards (hall tickets) per student per exam. Admit card contents: school logo and name, student photograph, student name, class, section, roll number, exam name, full subject-wise exam schedule (date, time, hall, seat number), general instructions, principal/controller signature. Bulk generation dispatched as a background job (`GenerateAdmitCardsJob`). Download-all as ZIP. Controlled publishing to student/parent portal.

**Actors:** Exam Controller, Admin

**Processing Rules:**
- Admit card cannot be generated until seating arrangement is finalised for all subject slots in the exam
- Bulk generation: class-section selection → background job → progress polling endpoint
- PDF rendered via DomPDF using school branding from `sch_organisations` / `sys_media`
- Generated PDF path stored via `sys_media` polymorphic table; reference in `exa_admit_cards.media_id`
- `is_published = 1` makes card visible on student/parent portal

**Acceptance Criteria:**
- AC-004-01: Admit card blocked if seating arrangement incomplete for any subject in the exam
- AC-004-02: Bulk generation for 500 students via background job completes within 5 minutes
- AC-004-03: Published admit cards visible in student/parent portal immediately
- AC-004-04: Regenerating admit card after seating update overwrites existing PDF record

---

### FR-EXA-005: Mark Entry
**RBS Reference:** F.I3 (Marks Entry & Verification) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables:** `exa_mark_entries`

**Description:** Subject-wise mark entry per student per exam subject slot. Supports three entry modes: (1) individual form entry, (2) inline editable grid with bulk save for a class-section, (3) Excel bulk upload. Records theory marks, practical marks, internal assessment marks, grace marks, absent flag, and malpractice flag. Each entry carries an `entry_status` (draft / entered / verified) and a full audit trail linking to `sys_activity_logs`.

**Actors:** Subject Teacher (entry), HOD/Exam Controller (verification)

**Processing Rules:**
- Teacher can only enter marks for subjects assigned to them in `sch_staff_subject_assignments` (Gate policy)
- `is_absent = 1` forces theory/practical/internal marks to 0; grace marks can still apply per school policy
- `is_malpractice = 1` sets marks to 0 and locks the entry; can only be unlocked by Exam Controller
- `grace_marks` may not exceed school-configured maximum (default: 5% of max_marks)
- `marks_obtained` = theory + practical + internal + grace (generated column, STORED)
- On all entries for a subject slot completed, auto-flag `exa_exam_subjects.is_marks_entered = 1`

**Bulk Upload:**
- Template Excel columns: Roll No, Student Name, Theory, Practical, Internal, Grace, Absent, Malpractice, Remarks
- Server validates all rows before committing any — atomic upload
- Returns row-level error report in JSON if any row fails validation
- Subject teacher can download pre-populated template with enrolled students

**Acceptance Criteria:**
- AC-005-01: Absent student (is_absent=1) cannot have non-zero theory/practical/internal marks; API returns 422
- AC-005-02: Marks exceeding component max return 422 with field-level error
- AC-005-03: Bulk upload is atomic; partial commits are not permitted
- AC-005-04: Entry status transitions: `draft → entered` (by teacher) → `verified` (by HOD)
- AC-005-05: Malpractice mark entry is logged to `sys_activity_logs` with teacher and timestamp

---

### FR-EXA-006: Marks Moderation Workflow
**RBS Reference:** F.I4 (Moderation Workflow) | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `exa_mark_moderations`

**Description:** Multi-stage marks moderation workflow for borderline and exceptional cases. After marks are entered and verified, HOD or Exam Controller may propose moderation: adjusting marks for a student with documented justification (e.g., paper re-evaluation, grace for illness). Proposed moderation requires Principal approval before it affects the stored marks. All moderation actions are immutable records — no deletion permitted.

**Actors:** HOD, Exam Controller (propose); Principal, Admin (approve/reject)

**Processing Rules:**
- Moderation creates a record with `proposed_marks` and `moderation_reason`; original marks unchanged
- Status FSM: `proposed → approved / rejected`
- On approval: `exa_mark_entries.grace_marks` updated or `marks_obtained` recalculated; result re-queued for reprocessing
- On rejection: rejection reason recorded; original marks stand
- Multiple moderation requests on the same mark entry are allowed sequentially; latest approved one wins
- History is permanently preserved in `exa_mark_moderations`

**Acceptance Criteria:**
- AC-006-01: Only `exa.moderation.propose` permission holders can create moderation requests
- AC-006-02: Only `exa.moderation.approve` permission holders (Principal/Admin) can approve
- AC-006-03: Approved moderation triggers automatic result reprocessing for the affected student
- AC-006-04: Moderation records cannot be edited or deleted after creation

---

### FR-EXA-007: Grade Scale Configuration
**RBS Reference:** F.I5 (Gradebook Calculation Engine) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables:** `exa_grade_scales`, `exa_grade_scale_bands`

**Description:** Configuration of grading systems for the school. Supports multiple grade scales per tenant (e.g., CBSE 10-point GPA, ICSE letter grades, percentage-based, custom NEP 2020 competency). A grade scale comprises a set of bands, each defining a percentage range mapped to a grade letter, grade point, and descriptive remark. The applicable grade scale is assigned per exam type, with the school default applied when no specific assignment exists.

**Actors:** Admin, Principal

**Pre-seeded System Scales:**
- `CBSE_GPA` — CBSE 10-point: A1 (91-100, 10.0), A2 (81-90, 9.0), B1 (71-80, 8.0), B2 (61-70, 7.0), C1 (51-60, 6.0), C2 (41-50, 5.0), D (33-40, 4.0), E (0-32, 0.0, fail)
- `ICSE_LETTER` — ICSE: A (75+), B (60-74), C (45-59), D (35-44), E (<35, fail)
- `PERCENTAGE` — standard percentage pass/fail

**Processing Rules:**
- Bands within a scale: non-overlapping, collectively covering 0–100%
- GPA = weighted average of subject grade points (weighted by subject credit hours; equal weight if no credit defined)
- CGPA = average GPA across all summative exams in the session
- School default scale applied when no exam-type-specific scale is configured

**Acceptance Criteria:**
- AC-007-01: Overlapping band ranges return HTTP 422 validation error on save
- AC-007-02: Warning shown if bands do not collectively cover 0–100%
- AC-007-03: System-seeded scales are read-only; school can clone and customise
- AC-007-04: Deleting a grade scale blocked if it is referenced by any exam type or exam

---

### FR-EXA-008: Result Processing
**RBS Reference:** F.I5 (Gradebook Calculation Engine), F.I7 (Promotion & Detention) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables:** `exa_results`, `exa_result_subjects`

**Description:** Batch computation of exam results after mark entry is complete for all subjects. For each student, calculates: total marks, percentage, grade letter, grade point, GPA, pass/fail determination, compartment flagging, class rank, and section rank. Generates `exa_results` (one per student per exam) and `exa_result_subjects` (one per student-subject per exam). Result processing is idempotent — re-processing replaces existing results.

**Actors:** System (triggered by Exam Controller)

**Processing Algorithm (per student):**
1. Aggregate `marks_obtained` from `exa_mark_entries` for all subject slots in the exam
2. Compute `total_marks`, `total_max_marks`, `percentage = (total_marks / total_max_marks) * 100`
3. Apply grade scale: determine `grade_letter` and `grade_point` from `exa_grade_scale_bands`
4. Compute subject-level grade for each subject; store in `exa_result_subjects`
5. GPA = weighted average of subject grade points
6. Pass determination: student passes if grade band `is_pass = 1` AND passes all mandatory subjects
7. Compartment: student overall passes but failed in ≤ `max_allowed_compartment` non-mandatory subjects
8. Rank: sort by `percentage DESC` (tie-break: higher marks in Language subject first, then total of core subjects); assign `rank_in_class` and `rank_in_section` using competition ranking (shared rank, next rank skipped)
9. CCE overlay: if `exam_type.is_ccce_applicable = 1`, combine formative averages with summative per `exa_cce_configs` weightage before grade assignment

**Acceptance Criteria:**
- AC-008-01: Result processing blocked if any subject slot has `is_marks_entered = 0`
- AC-008-02: Absent students recorded as 0 marks for that subject in result
- AC-008-03: Compartment students flagged as `status = compartment`; not FAIL
- AC-008-04: Competition ranking applied: tied students share rank; next rank skips accordingly
- AC-008-05: Re-processing is idempotent; replaces prior results without creating duplicates

---

### FR-EXA-009: Rank List & Merit List
**RBS Reference:** F.I5 | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `exa_results` (read), `exa_rank_lists`

**Description:** Generation and publication of class-wise and section-wise rank/merit lists. Rank lists are printable PDFs listing students by rank with total marks, percentage, grade, and subject-wise marks. A merit list identifies the top N students (configurable) who become eligible for merit certificates via the CRT module integration. Rank lists are derivatives of result processing and auto-regenerated when marks are corrected.

**Actors:** Class Teacher, Exam Controller

**Processing Rules:**
- Reads from `exa_results` where `status IN (processed, published)`
- Class rank: all students across sections of the same class
- Section rank: students within a single class-section
- Merit list threshold: configurable as top-N count or top-N% (e.g., top 3 or top 10%)
- Merit list students emitted to CRT module as certificate-eligible records
- Subject rank: top performers per subject also tracked in `exa_result_subjects`

**Acceptance Criteria:**
- AC-009-01: Rank list uses competition ranking consistently with `exa_results.rank_in_class/section`
- AC-009-02: Merit threshold is configurable per exam per class
- AC-009-03: Rank list PDF includes school header, class name, exam name, generation date
- AC-009-04: CRT integration: merit students auto-notified to CRT module for certificate generation

---

### FR-EXA-010: Progress Report Card Generation
**RBS Reference:** F.I6 (Report Cards & Publishing), F.I8 (Board Pattern), F.I9 (Custom Designer) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables:** `exa_report_configs`, `exa_report_cards`

**Description:** Generation of individual PDF progress report cards per student per exam. Report card includes: school identity block (logo, name, address, affiliation), student profile (name, class, section, roll number, photograph), subject-wise marks breakdown (theory/practical/internal), total marks, percentage, grade letter, grade point, GPA, rank, attendance summary (pulled from ATT module), teacher remarks, principal remarks, and promotion decision. Supports multiple template types and custom layout designer. Bilingual support (English + regional language for headers and grade descriptors).

**Actors:** Class Teacher, Admin

**Template Types:**
| Template | Description |
|---|---|
| `standard` | Generic school format with percentage + grade |
| `cbse` | CBSE CCE format: FA1/FA2/SA1/SA2 with grade points, co-scholastic section |
| `icse` | ICSE format: subject codes, letter grades, percentage |
| `ib` | IB MYP criterion-based grades (A–E per criterion) |
| `cambridge` | Cambridge grade descriptors |
| `custom` | School-defined field placement via layout designer |

**Processing Rules:**
- Report card blocked until `exa_results.status IN (processed, published)`
- Attendance summary fetched from ATT module: `att_student_attendance` aggregated by session
- Bulk generation dispatched via `GenerateReportCardsJob` with real-time progress polling
- PDF rendered by DomPDF; stored in `sys_media` (polymorphic); path in `exa_report_cards.media_id`
- Bilingual: secondary language labels from `glb_translations` table
- Custom template designer stores field positions/sizes as JSON in `exa_report_configs.custom_layout_json`
- CBSE template includes co-scholastic section from `exa_coscholastic_entries`

**Acceptance Criteria:**
- AC-010-01: Report card blocked if result not yet processed for the student
- AC-010-02: 500-student bulk generation completes in background within 5 minutes
- AC-010-03: Attendance percentage correctly pulled from ATT module and displayed on report card
- AC-010-04: Custom layout JSON is validated for required fields before save
- AC-010-05: CBSE template correctly formats all FA+SA components in CCE grid

---

### FR-EXA-011: Cumulative Report Card
**RBS Reference:** F.I6 | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `exa_cumulative_results`

**Description:** Generation of a cumulative (all-term combined) progress report card for a student within an academic session. Aggregates results across all exam events in the session (e.g., Unit Test + Half Yearly + Annual) using each exam type's `weightage_percent` to compute a weighted cumulative percentage and final grade. Cumulative report card can be generated at any point in the session and shows progression across terms. Used as the primary year-end academic record.

**Actors:** Class Teacher, Admin

**Processing Rules:**
- Cumulative percentage = Σ (exam_percentage × exam_type.weightage_percent) / Σ weightage_percent for processed exams
- Cumulative grade assigned from school default grade scale applied to cumulative percentage
- GPA cumulative = average GPA across all included summative exams
- CCE full-year grade: computed from Term1 and Term2 combined CCE grades
- `exa_cumulative_results` stores one record per student per academic session; idempotent regeneration

**Acceptance Criteria:**
- AC-011-01: Cumulative result computed only from exam types with weightage > 0 and status = published
- AC-011-02: Cumulative PDF includes a term-by-term progression table
- AC-011-03: Cumulative report replaces previous version on regeneration (idempotent)

---

### FR-EXA-012: CCE — Continuous & Comprehensive Evaluation
**RBS Reference:** F.I1, F.I5 | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `exa_cce_configs`, `exa_cce_assessments`

**Description:** Configuration and management of CBSE-aligned Continuous and Comprehensive Evaluation. CCE divides an academic year into two terms (Term 1, Term 2), each containing two Formative Assessments (FA1, FA2) and one Summative Assessment (SA). Formative Assessment includes oral tests, class tests, projects, and portfolio assignments. Configured weightage (default FA: 40%, SA: 60%) determines term grade. EXA's CCE layer plugs FA scores into the overall grade calculation for CCE-applicable exam types.

**Actors:** Admin (configure), Subject Teacher (enter FA scores)

**Formula:**
```
FA_avg = average(FA1_percent, FA2_percent) × fa_weightage / 100
SA_contrib = SA_percent × sa_weightage / 100
Term_grade_percent = FA_avg + SA_contrib
Year_grade_percent = average(Term1_grade, Term2_grade)
```

**Acceptance Criteria:**
- AC-012-01: `fa_weightage_percent + sa_weightage_percent = 100` enforced on save
- AC-012-02: Missing FA score defaults to 0 with a `missing_fa` flag warning in result
- AC-012-03: CCE final grade integrated into report card only when `exa_exam_types.is_ccce_applicable = 1`
- AC-012-04: CCE grade sheet per student per term is exportable as PDF/Excel

---

### FR-EXA-013: Co-Scholastic Assessment
**RBS Reference:** F.I5, F5 (Internal Assessment) | **Priority:** Medium | **Status:** 📐 Proposed
**Tables:** `exa_coscholastic_domains`, `exa_coscholastic_entries`

**Description:** Management of co-scholastic (non-academic) assessment for CBSE schools. Covers: Work Education, Art Education, Health & Physical Education, Discipline, and Attitudes & Values. Students are graded on a 3-point scale (A/B/C) or descriptive remarks per domain per term. Co-scholastic grades are included in the CBSE-format report card. Non-CBSE schools can configure custom co-scholastic domains.

**Actors:** Class Teacher, Subject Teacher (per domain), Admin (configure domains)

**Processing Rules:**
- Domain master in `exa_coscholastic_domains` — system-seeded for CBSE; customisable per school
- Grade entry per student per domain per term
- Grading scale: 3-point (A/B/C = Outstanding/Satisfactory/Needs Improvement) or descriptive remarks
- Co-scholastic section pulled into CBSE template during report card generation

**Acceptance Criteria:**
- AC-013-01: Co-scholastic grade entry not blocked by exam mark entry status
- AC-013-02: Co-scholastic section correctly renders in CBSE report card template
- AC-013-03: Custom domain creation available for non-CBSE schools

---

### FR-EXA-014: Promotion & Detention Processing
**RBS Reference:** F.I7 (Promotion & Detention Rules) | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `exa_promotion_rules`, `exa_promotion_lists`

**Description:** End-of-year promotion and detention processing. The school configures class-specific promotion rules (minimum overall percentage, minimum grade, mandatory subject pass requirements, minimum attendance threshold). The system applies these rules to final exam results and generates a promotion list classifying each student as PROMOTED, DETAINED, COMPARTMENT, or WITHHELD. DETAINED students trigger parent notification via the Notification module. PROMOTED student list exports to the Student module for class advancement.

**Actors:** Admin, Principal

**Processing Rules:**
- Rules applied to `exa_results` where `exam_type.exam_category = annual` or school-designated annual exam
- Classification: PROMOTED if all rules pass; COMPARTMENT if failed ≤ `max_allowed_compartment` non-mandatory subjects; DETAINED if overall fail criteria met; WITHHELD for incomplete documentation
- Attendance check: if `min_attendance_percent` configured, students below threshold auto-flagged even if marks qualify for promotion
- Principal manual override: change any student's status with mandatory override reason
- DETAINED notification fires to parent via Notification module
- PROMOTED list integration: exports `student_id + next_class_id + next_section_id` to Student module for batch class promotion

**Acceptance Criteria:**
- AC-014-01: Promotion rules configurable per class (Class 5 and Class 10 can have different criteria)
- AC-014-02: Manual override by Principal is logged with reason and override timestamp
- AC-014-03: COMPARTMENT students can be promoted after passing compartment exam
- AC-014-04: Attendance-based check integrates with ATT module attendance percentage

---

### FR-EXA-015: Result Publishing
**RBS Reference:** F.I6.2 (Publishing) | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `exa_exams` (status), `exa_report_cards` (is_published), `exa_admit_cards` (is_published)

**Description:** Controlled, gated publishing of results and report cards to the student/parent portal. Publishing requires explicit Admin action after reviewing results. Supports immediate publish and scheduled publish (future date/time via Laravel Scheduler). Once published, students and parents can view marks, grade, rank, and download report card PDF. Unpublishing is permitted before student portal access begins.

**Actors:** Admin, Principal

**Processing Rules:**
- On publish: `exa_exams.status = published`; all `exa_report_cards.is_published = 1` for that exam
- Scheduled publish: `publish_scheduled_at` stored; `PublishExamResultsJob` fires at that time
- Notification trigger: sends result-published alert to all students + registered parent accounts for affected class-sections
- Portal visibility: `is_published = 0` → result and report card not visible in portal (enforced in portal API Gate)
- Unpublish: reverts status to `completed`; portal access immediately removed

**Acceptance Criteria:**
- AC-015-01: Unpublished results not visible to students/parents regardless of portal access
- AC-015-02: Scheduled publishing fires within ±5 minutes of configured time
- AC-015-03: Notification sent on publish to all students + registered parents
- AC-015-04: Unpublishing is logged to `sys_activity_logs` with user and timestamp

---

### FR-EXA-016: Board Exam Coordination
**RBS Reference:** F.I8 (Board Pattern Support) | **Priority:** Medium | **Status:** 📐 Proposed
**Tables:** `exa_board_registrations`, `exa_board_roll_numbers`

**Description:** Management of student registration for external board examinations (CBSE Class 10/12, ICSE Class 10, State Board). Includes: collection of board registration details per eligible student, assignment of board roll numbers (LOC/index numbers), export of data in board-specified format (CSV/Excel/XML for CBSE portal uploads), tracking of registration status, and printing board-format admit cards with board roll numbers.

**Actors:** Exam Controller, Admin

**Processing Rules:**
- Board registration linked to `academic_session_id` + `class_id` + `board_type` (CBSE/ICSE/State)
- Eligibility check: student must be enrolled in designated board class with minimum attendance
- Board roll number assignment: manual entry or auto-sequential within school centre number
- Export format: board-configurable (CSV for CBSE LOC; XLSX for ICSE); stored as `sys_media` file
- Board admit card: separate from school admit card; uses board roll number instead of internal roll number
- Status tracking: `pending → registered → roll_assigned → admit_issued`

**Acceptance Criteria:**
- AC-016-01: Board registration export produces correctly formatted file per board type
- AC-016-02: Board roll number uniqueness enforced per board per session
- AC-016-03: Board admit card clearly distinguished from school admit card in portal and printout

---

### FR-EXA-017: AI-Based Examination Analytics
**RBS Reference:** F.I10 (AI-Based Examination Analytics) | **Priority:** Medium | **Status:** 📐 Proposed
**Tables:** `exa_performance_analytics`, `exa_ai_alerts`

**Description:** Rule-based analytics engine providing actionable insights from examination results. Identifies subject-wise weak areas per student, class-level underperforming subjects (cross-referenced with syllabus topics), and generates predictive risk alerts for students showing declining performance trends. Analytics are automatically triggered after result processing completes. Weak-area signals are emitted to the Recommendation module for remedial content suggestions.

**Actors:** System (automated), Teacher (views dashboard), Admin (views summary)

**Processing Rules:**
- Weak area: student scores below class average in the same subject for ≥ 2 consecutive exams → `WEAK_AREA` flag
- Skill gap: cross-reference with `slb_topics` to identify syllabus topics corresponding to low-scoring subjects
- Predictive alert: student's last 3 exam percentages show declining trend (slope < 0) → risk `MEDIUM`; decline > 10% per exam → risk `HIGH`
- Class insight: subject with > 30% failure rate in an exam → teacher-level alert
- Recommendation trigger: emit `ExamWeakAreaDetected` event to Recommendation module
- Analytics run as `ProcessExamAnalyticsJob` queued after `ResultProcessingJob` completes

**Acceptance Criteria:**
- AC-017-01: Analytics engine auto-queued after result processing completes
- AC-017-02: Teacher notified of MEDIUM/HIGH risk students within 1 hour of result processing
- AC-017-03: Weak area flag requires confirmed ≥ 2 consecutive exam data points
- AC-017-04: Class-level subject failure alerts reach the subject teacher via notification

---

## 5. Data Model

### 5.1 Exam Structure Tables

**`exa_exam_types`** — Master exam type definitions

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `name` | VARCHAR(100) NOT NULL | Unit Test 1, Half Yearly, Annual |
| `code` | VARCHAR(20) NOT NULL UNIQUE | UT1, HY, ANNUAL, FA1, SA2 |
| `exam_category` | ENUM('formative','summative','annual','board') NOT NULL | |
| `weightage_percent` | DECIMAL(5,2) NOT NULL DEFAULT 0 | session-level cumulative weight |
| `is_ccce_applicable` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `grade_scale_id` | BIGINT UNSIGNED NULL FK→exa_grade_scales | NULL = school default |
| `description` | TEXT NULL | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |

**`exa_exam_components`** — Mark breakdown components per exam type

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `exam_type_id` | BIGINT UNSIGNED NOT NULL FK→exa_exam_types | |
| `component_name` | ENUM('theory','practical','internal','oral','portfolio') NOT NULL | |
| `max_marks_default` | DECIMAL(5,2) NOT NULL | |
| `pass_marks_default` | DECIMAL(5,2) NOT NULL | |
| `is_mandatory` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

### 5.2 Exam Event Tables

**`exa_exams`** — Exam event master

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `academic_session_id` | BIGINT UNSIGNED NOT NULL FK→sch_academic_sessions | |
| `exam_type_id` | BIGINT UNSIGNED NOT NULL FK→exa_exam_types | |
| `name` | VARCHAR(150) NOT NULL | "Half Yearly Exam 2025-26" |
| `from_date` | DATE NOT NULL | |
| `to_date` | DATE NOT NULL | |
| `status` | ENUM('draft','scheduled','ongoing','completed','published') NOT NULL DEFAULT 'draft' | |
| `publish_scheduled_at` | TIMESTAMP NULL | scheduled auto-publish |
| `instructions` | TEXT NULL | printed on admit card |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |

**`exa_exam_subjects`** — Individual subject slots within an exam

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `exam_id` | BIGINT UNSIGNED NOT NULL FK→exa_exams | |
| `subject_id` | BIGINT UNSIGNED NOT NULL FK→sch_subjects | |
| `class_section_id` | BIGINT UNSIGNED NOT NULL FK→sch_class_sections | |
| `exam_date` | DATE NOT NULL | |
| `start_time` | TIME NOT NULL | |
| `end_time` | TIME NOT NULL | |
| `max_marks` | DECIMAL(5,2) NOT NULL | |
| `pass_marks` | DECIMAL(5,2) NOT NULL | |
| `theory_max` | DECIMAL(5,2) NOT NULL DEFAULT 0 | |
| `practical_max` | DECIMAL(5,2) NOT NULL DEFAULT 0 | |
| `internal_max` | DECIMAL(5,2) NOT NULL DEFAULT 0 | |
| `hall_id` | BIGINT UNSIGNED NULL FK→sch_halls | |
| `is_marks_entered` | TINYINT(1) NOT NULL DEFAULT 0 | all marks entered flag |
| `is_marks_verified` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |

**`exa_invigilators_jnt`** — Staff invigilator assignments per subject slot

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `exam_subject_id` | BIGINT UNSIGNED NOT NULL FK→exa_exam_subjects | |
| `staff_id` | BIGINT UNSIGNED NOT NULL FK→sys_users | |
| `is_chief_invigilator` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

### 5.3 Seating & Admit Card Tables

**`exa_seating_arrangements`** — Per-student seat assignments

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `exam_subject_id` | BIGINT UNSIGNED NOT NULL FK→exa_exam_subjects | |
| `student_id` | BIGINT UNSIGNED NOT NULL FK→std_students | |
| `hall_id` | BIGINT UNSIGNED NOT NULL FK→sch_halls | |
| `seat_number` | VARCHAR(20) NOT NULL | e.g., A-12 |
| `roll_number` | VARCHAR(30) NOT NULL | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| UNIQUE KEY | (`exam_subject_id`, `student_id`) | |
| UNIQUE KEY | (`exam_subject_id`, `seat_number`) | |

**`exa_admit_cards`** — Generated admit card PDF references

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `exam_id` | BIGINT UNSIGNED NOT NULL FK→exa_exams | |
| `student_id` | BIGINT UNSIGNED NOT NULL FK→std_students | |
| `media_id` | BIGINT UNSIGNED NULL FK→sys_media | polymorphic PDF ref |
| `is_published` | TINYINT(1) NOT NULL DEFAULT 0 | portal visibility |
| `generated_at` | TIMESTAMP NULL | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| UNIQUE KEY | (`exam_id`, `student_id`) | |

---

### 5.4 Mark Entry & Moderation Tables

**`exa_mark_entries`** — Per-student per-subject mark records

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `exam_subject_id` | BIGINT UNSIGNED NOT NULL FK→exa_exam_subjects | |
| `student_id` | BIGINT UNSIGNED NOT NULL FK→std_students | |
| `is_absent` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `is_malpractice` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `theory_marks` | DECIMAL(5,2) NOT NULL DEFAULT 0 | |
| `practical_marks` | DECIMAL(5,2) NOT NULL DEFAULT 0 | |
| `internal_marks` | DECIMAL(5,2) NOT NULL DEFAULT 0 | |
| `grace_marks` | DECIMAL(4,2) NOT NULL DEFAULT 0 | |
| `marks_obtained` | DECIMAL(5,2) GENERATED ALWAYS AS (theory_marks + practical_marks + internal_marks + grace_marks) STORED | |
| `entry_status` | ENUM('draft','entered','verified') NOT NULL DEFAULT 'draft' | |
| `entered_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `verified_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `verified_at` | TIMESTAMP NULL | |
| `remarks` | VARCHAR(255) NULL | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |
| UNIQUE KEY | (`exam_subject_id`, `student_id`) | |

**`exa_mark_moderations`** — Marks moderation workflow records

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `mark_entry_id` | BIGINT UNSIGNED NOT NULL FK→exa_mark_entries | |
| `proposed_marks` | DECIMAL(5,2) NOT NULL | |
| `moderation_reason` | TEXT NOT NULL | |
| `proposed_by` | BIGINT UNSIGNED NOT NULL FK→sys_users | |
| `status` | ENUM('proposed','approved','rejected') NOT NULL DEFAULT 'proposed' | |
| `approved_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `approved_at` | TIMESTAMP NULL | |
| `rejection_reason` | TEXT NULL | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

### 5.5 Grade Scale & Result Tables

**`exa_grade_scales`** — Grade scale master

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `name` | VARCHAR(100) NOT NULL | "CBSE 10-Point GPA Scale" |
| `code` | VARCHAR(20) NOT NULL UNIQUE | |
| `scale_type` | ENUM('percentage','letter_grade','gpa','ccce') NOT NULL | |
| `is_default` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `is_system` | TINYINT(1) NOT NULL DEFAULT 0 | read-only seeded scales |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |

**`exa_grade_scale_bands`** — Individual grade bands

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `grade_scale_id` | BIGINT UNSIGNED NOT NULL FK→exa_grade_scales | |
| `min_percent` | DECIMAL(5,2) NOT NULL | |
| `max_percent` | DECIMAL(5,2) NOT NULL | |
| `grade_letter` | VARCHAR(5) NOT NULL | A1, B2, C, F |
| `grade_point` | DECIMAL(3,1) NOT NULL DEFAULT 0 | 10.0, 9.0 |
| `description` | VARCHAR(100) NULL | Outstanding, Excellent |
| `is_pass` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**`exa_results`** — Computed result per student per exam

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `exam_id` | BIGINT UNSIGNED NOT NULL FK→exa_exams | |
| `student_id` | BIGINT UNSIGNED NOT NULL FK→std_students | |
| `total_marks` | DECIMAL(7,2) NOT NULL DEFAULT 0 | |
| `total_max_marks` | DECIMAL(7,2) NOT NULL DEFAULT 0 | |
| `percentage` | DECIMAL(5,2) NOT NULL DEFAULT 0 | |
| `grade_letter` | VARCHAR(5) NULL | |
| `grade_point` | DECIMAL(3,1) NULL | |
| `gpa` | DECIMAL(4,2) NULL | |
| `rank_in_class` | SMALLINT UNSIGNED NULL | |
| `rank_in_section` | SMALLINT UNSIGNED NULL | |
| `is_pass` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `status` | ENUM('draft','processed','compartment','detained','published') NOT NULL DEFAULT 'draft' | |
| `processed_at` | TIMESTAMP NULL | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| UNIQUE KEY | (`exam_id`, `student_id`) | |

**`exa_result_subjects`** — Subject-level result breakdown

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `result_id` | BIGINT UNSIGNED NOT NULL FK→exa_results | |
| `subject_id` | BIGINT UNSIGNED NOT NULL FK→sch_subjects | |
| `marks_obtained` | DECIMAL(5,2) NOT NULL | |
| `max_marks` | DECIMAL(5,2) NOT NULL | |
| `percentage` | DECIMAL(5,2) NOT NULL | |
| `grade_letter` | VARCHAR(5) NULL | |
| `grade_point` | DECIMAL(3,1) NULL | |
| `is_pass` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `is_absent` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `is_compartment` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `rank_in_subject` | SMALLINT UNSIGNED NULL | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

### 5.6 Report Card & Cumulative Tables

**`exa_report_configs`** — Report card configuration per exam

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `exam_id` | BIGINT UNSIGNED NOT NULL FK→exa_exams | |
| `template_type` | ENUM('standard','cbse','icse','ib','cambridge','custom') NOT NULL DEFAULT 'standard' | |
| `show_rank` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `show_attendance` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `show_remarks` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `show_photo` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `show_coscholastic` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `language_code_primary` | VARCHAR(10) NOT NULL DEFAULT 'en' | |
| `language_code_secondary` | VARCHAR(10) NULL | |
| `header_text_json` | JSON NULL | school-specific header fields |
| `footer_text` | TEXT NULL | |
| `custom_layout_json` | JSON NULL | drag-drop field positions |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**`exa_report_cards`** — Generated report card PDF per student per exam

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `exam_id` | BIGINT UNSIGNED NOT NULL FK→exa_exams | |
| `student_id` | BIGINT UNSIGNED NOT NULL FK→std_students | |
| `result_id` | BIGINT UNSIGNED NOT NULL FK→exa_results | |
| `media_id` | BIGINT UNSIGNED NULL FK→sys_media | |
| `is_published` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `published_at` | TIMESTAMP NULL | |
| `class_teacher_remarks` | TEXT NULL | |
| `principal_remarks` | TEXT NULL | |
| `generated_at` | TIMESTAMP NULL | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| UNIQUE KEY | (`exam_id`, `student_id`) | |

**`exa_cumulative_results`** — All-term combined result per student per session

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `academic_session_id` | BIGINT UNSIGNED NOT NULL FK→sch_academic_sessions | |
| `student_id` | BIGINT UNSIGNED NOT NULL FK→std_students | |
| `cumulative_percent` | DECIMAL(5,2) NOT NULL DEFAULT 0 | |
| `cumulative_grade` | VARCHAR(5) NULL | |
| `cumulative_gpa` | DECIMAL(4,2) NULL | |
| `is_promoted` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `media_id` | BIGINT UNSIGNED NULL FK→sys_media | cumulative PDF |
| `is_published` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| UNIQUE KEY | (`academic_session_id`, `student_id`) | |

---

### 5.7 CCE Tables

**`exa_cce_configs`** — CCE term configuration per session

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `academic_session_id` | BIGINT UNSIGNED NOT NULL FK→sch_academic_sessions | |
| `term` | ENUM('term1','term2','full_year') NOT NULL | |
| `fa_weightage_percent` | DECIMAL(5,2) NOT NULL DEFAULT 40 | |
| `sa_weightage_percent` | DECIMAL(5,2) NOT NULL DEFAULT 60 | |
| `fa_count` | TINYINT UNSIGNED NOT NULL DEFAULT 2 | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**`exa_cce_assessments`** — Individual FA score records

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `cce_config_id` | BIGINT UNSIGNED NOT NULL FK→exa_cce_configs | |
| `student_id` | BIGINT UNSIGNED NOT NULL FK→std_students | |
| `subject_id` | BIGINT UNSIGNED NOT NULL FK→sch_subjects | |
| `assessment_type` | ENUM('oral','classtest','project','portfolio','assignment') NOT NULL | |
| `fa_sequence` | TINYINT UNSIGNED NOT NULL | 1=FA1, 2=FA2 |
| `marks_obtained` | DECIMAL(5,2) NOT NULL | |
| `max_marks` | DECIMAL(5,2) NOT NULL | |
| `assessment_date` | DATE NOT NULL | |
| `entered_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

### 5.8 Co-Scholastic Tables

**`exa_coscholastic_domains`** — Domain master (Work Education, Art Ed, etc.)

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `name` | VARCHAR(100) NOT NULL | "Work Education", "Art Education" |
| `code` | VARCHAR(20) NOT NULL UNIQUE | |
| `grading_type` | ENUM('abc','descriptive','marks') NOT NULL DEFAULT 'abc' | |
| `is_system` | TINYINT(1) NOT NULL DEFAULT 0 | CBSE-seeded domains |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**`exa_coscholastic_entries`** — Student grades per domain per term

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `academic_session_id` | BIGINT UNSIGNED NOT NULL FK→sch_academic_sessions | |
| `domain_id` | BIGINT UNSIGNED NOT NULL FK→exa_coscholastic_domains | |
| `student_id` | BIGINT UNSIGNED NOT NULL FK→std_students | |
| `term` | ENUM('term1','term2','full_year') NOT NULL | |
| `grade` | VARCHAR(5) NULL | A/B/C or custom |
| `remarks` | TEXT NULL | |
| `entered_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| UNIQUE KEY | (`academic_session_id`, `domain_id`, `student_id`, `term`) | |

---

### 5.9 Promotion Tables

**`exa_promotion_rules`** — Class-specific promotion criteria

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `academic_session_id` | BIGINT UNSIGNED NOT NULL FK→sch_academic_sessions | |
| `class_id` | BIGINT UNSIGNED NOT NULL FK→sch_classes | |
| `min_percentage` | DECIMAL(5,2) NOT NULL DEFAULT 33 | |
| `mandatory_pass_subjects_json` | JSON NULL | array of subject_ids |
| `max_allowed_compartment` | TINYINT UNSIGNED NOT NULL DEFAULT 1 | |
| `min_attendance_percent` | DECIMAL(5,2) NULL | NULL = not enforced |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**`exa_promotion_lists`** — Promotion decision per student

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `academic_session_id` | BIGINT UNSIGNED NOT NULL FK→sch_academic_sessions | |
| `student_id` | BIGINT UNSIGNED NOT NULL FK→std_students | |
| `result_id` | BIGINT UNSIGNED NOT NULL FK→exa_results | |
| `promotion_status` | ENUM('promoted','detained','compartment','withheld') NOT NULL | |
| `override_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `override_reason` | TEXT NULL | |
| `notification_sent` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

### 5.10 Board Coordination & Analytics Tables

**`exa_board_registrations`** — Board exam registration header per session

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `academic_session_id` | BIGINT UNSIGNED NOT NULL FK→sch_academic_sessions | |
| `class_id` | BIGINT UNSIGNED NOT NULL FK→sch_classes | |
| `board_type` | ENUM('CBSE','ICSE','STATE','OTHER') NOT NULL | |
| `centre_number` | VARCHAR(30) NULL | school's board centre no. |
| `registration_status` | ENUM('pending','submitted','confirmed') NOT NULL DEFAULT 'pending' | |
| `export_file_id` | BIGINT UNSIGNED NULL FK→sys_media | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**`exa_board_roll_numbers`** — Board roll number per student

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `board_registration_id` | BIGINT UNSIGNED NOT NULL FK→exa_board_registrations | |
| `student_id` | BIGINT UNSIGNED NOT NULL FK→std_students | |
| `board_roll_number` | VARCHAR(30) NOT NULL | |
| `registration_number` | VARCHAR(30) NULL | board candidate number |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| UNIQUE KEY | (`board_registration_id`, `student_id`) | |
| UNIQUE KEY | (`board_registration_id`, `board_roll_number`) | |

**`exa_performance_analytics`** — Computed analytics per student per exam

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `exam_id` | BIGINT UNSIGNED NOT NULL FK→exa_exams | |
| `student_id` | BIGINT UNSIGNED NOT NULL FK→std_students | |
| `subject_id` | BIGINT UNSIGNED NULL FK→sch_subjects | NULL = overall |
| `metric_type` | ENUM('weak_area','strong_area','declining_trend','improving') NOT NULL | |
| `risk_level` | ENUM('low','medium','high') NOT NULL DEFAULT 'low' | |
| `detail_json` | JSON NULL | trend data, topic references |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**`exa_ai_alerts`** — Actionable alerts emitted from analytics

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `analytics_id` | BIGINT UNSIGNED NOT NULL FK→exa_performance_analytics | |
| `alert_type` | ENUM('teacher_alert','recommendation_trigger','parent_notify') NOT NULL | |
| `recipient_id` | BIGINT UNSIGNED NOT NULL FK→sys_users | |
| `is_sent` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `sent_at` | TIMESTAMP NULL | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

## 6. API Endpoints & Routes

All routes under `Modules/Examination/Routes/tenant.php`. Route prefix: `examination`. Auth: `auth:web` + tenant middleware.

### 6.1 Exam Type & Grade Scale Routes

| Method | URI | Name | Controller |
|---|---|---|---|
| GET | `/examination/exam-types` | `exa.exam-types.index` | ExamTypeController@index |
| POST | `/examination/exam-types` | `exa.exam-types.store` | ExamTypeController@store |
| GET | `/examination/exam-types/{examType}/edit` | `exa.exam-types.edit` | ExamTypeController@edit |
| PUT | `/examination/exam-types/{examType}` | `exa.exam-types.update` | ExamTypeController@update |
| DELETE | `/examination/exam-types/{examType}` | `exa.exam-types.destroy` | ExamTypeController@destroy |
| GET | `/examination/grade-scales` | `exa.grade-scales.index` | GradeScaleController@index |
| POST | `/examination/grade-scales` | `exa.grade-scales.store` | GradeScaleController@store |
| GET | `/examination/grade-scales/{scale}/bands` | `exa.grade-scales.bands` | GradeScaleController@bands |
| PUT | `/examination/grade-scales/{scale}` | `exa.grade-scales.update` | GradeScaleController@update |

### 6.2 Exam Schedule Routes

| Method | URI | Name | Controller |
|---|---|---|---|
| GET | `/examination/exams` | `exa.exams.index` | ExamController@index |
| POST | `/examination/exams` | `exa.exams.store` | ExamController@store |
| GET | `/examination/exams/{exam}` | `exa.exams.show` | ExamController@show |
| PUT | `/examination/exams/{exam}` | `exa.exams.update` | ExamController@update |
| DELETE | `/examination/exams/{exam}` | `exa.exams.destroy` | ExamController@destroy |
| POST | `/examination/exams/{exam}/subjects` | `exa.exam-subjects.store` | ExamSubjectController@store |
| PUT | `/examination/exam-subjects/{subject}` | `exa.exam-subjects.update` | ExamSubjectController@update |
| DELETE | `/examination/exam-subjects/{subject}` | `exa.exam-subjects.destroy` | ExamSubjectController@destroy |
| POST | `/examination/exam-subjects/{subject}/invigilators` | `exa.invigilators.store` | InvigilatorController@store |
| GET | `/examination/exams/{exam}/timetable-pdf` | `exa.exams.timetable-pdf` | ExamController@timetablePdf |
| POST | `/examination/exams/{exam}/status` | `exa.exams.status` | ExamController@updateStatus |

### 6.3 Seating & Admit Card Routes

| Method | URI | Name | Controller |
|---|---|---|---|
| POST | `/examination/exam-subjects/{subject}/seating/generate` | `exa.seating.generate` | SeatingController@generate |
| GET | `/examination/exam-subjects/{subject}/seating` | `exa.seating.index` | SeatingController@index |
| PUT | `/examination/seating/{seat}` | `exa.seating.update` | SeatingController@update |
| GET | `/examination/exam-subjects/{subject}/seating/chart-pdf` | `exa.seating.chart-pdf` | SeatingController@chartPdf |
| POST | `/examination/exams/{exam}/admit-cards/generate` | `exa.admit-cards.generate` | AdmitCardController@generate |
| GET | `/examination/exams/{exam}/admit-cards` | `exa.admit-cards.index` | AdmitCardController@index |
| POST | `/examination/exams/{exam}/admit-cards/publish` | `exa.admit-cards.publish` | AdmitCardController@publish |
| GET | `/examination/exams/{exam}/admit-cards/download-zip` | `exa.admit-cards.download-zip` | AdmitCardController@downloadZip |
| GET | `/examination/admit-cards/{card}/download` | `exa.admit-cards.download` | AdmitCardController@download |

### 6.4 Mark Entry Routes

| Method | URI | Name | Controller |
|---|---|---|---|
| GET | `/examination/exam-subjects/{subject}/marks` | `exa.marks.index` | MarkEntryController@index |
| POST | `/examination/exam-subjects/{subject}/marks` | `exa.marks.store` | MarkEntryController@store |
| PUT | `/examination/marks/{entry}` | `exa.marks.update` | MarkEntryController@update |
| POST | `/examination/exam-subjects/{subject}/marks/bulk` | `exa.marks.bulk` | MarkEntryController@bulk |
| GET | `/examination/exam-subjects/{subject}/marks/template` | `exa.marks.template` | MarkEntryController@template |
| POST | `/examination/exam-subjects/{subject}/marks/verify` | `exa.marks.verify` | MarkEntryController@verify |
| POST | `/examination/moderations` | `exa.moderations.store` | ModerationController@store |
| PUT | `/examination/moderations/{mod}/approve` | `exa.moderations.approve` | ModerationController@approve |
| PUT | `/examination/moderations/{mod}/reject` | `exa.moderations.reject` | ModerationController@reject |

### 6.5 Result & Report Card Routes

| Method | URI | Name | Controller |
|---|---|---|---|
| POST | `/examination/exams/{exam}/results/process` | `exa.results.process` | ResultController@process |
| GET | `/examination/exams/{exam}/results` | `exa.results.index` | ResultController@index |
| GET | `/examination/exams/{exam}/results/{student}` | `exa.results.show` | ResultController@show |
| GET | `/examination/exams/{exam}/rank-list` | `exa.rank-list.show` | RankListController@show |
| GET | `/examination/exams/{exam}/rank-list/pdf` | `exa.rank-list.pdf` | RankListController@pdf |
| POST | `/examination/exams/{exam}/report-cards/generate` | `exa.report-cards.generate` | ReportCardController@generate |
| GET | `/examination/exams/{exam}/report-cards` | `exa.report-cards.index` | ReportCardController@index |
| POST | `/examination/exams/{exam}/report-cards/publish` | `exa.report-cards.publish` | ReportCardController@publish |
| GET | `/examination/exams/{exam}/report-cards/download-zip` | `exa.report-cards.download-zip` | ReportCardController@downloadZip |
| POST | `/examination/exams/{exam}/publish` | `exa.exams.publish` | ExamController@publish |
| GET | `/examination/sessions/{session}/cumulative` | `exa.cumulative.show` | CumulativeController@show |
| POST | `/examination/sessions/{session}/cumulative/generate` | `exa.cumulative.generate` | CumulativeController@generate |

### 6.6 CCE, Co-Scholastic, Promotion & Board Routes

| Method | URI | Name | Controller |
|---|---|---|---|
| GET | `/examination/cce` | `exa.cce.index` | CceController@index |
| POST | `/examination/cce/configs` | `exa.cce.configs.store` | CceController@storeConfig |
| POST | `/examination/cce/assessments` | `exa.cce.assessments.store` | CceController@storeAssessment |
| GET | `/examination/cce/grade-sheet/{student}` | `exa.cce.grade-sheet` | CceController@gradeSheet |
| POST | `/examination/coscholastic` | `exa.coscholastic.store` | CoscholasticController@store |
| GET | `/examination/promotions/{session}` | `exa.promotions.show` | PromotionController@show |
| POST | `/examination/promotions/{session}/process` | `exa.promotions.process` | PromotionController@process |
| PUT | `/examination/promotions/{entry}/override` | `exa.promotions.override` | PromotionController@override |
| GET | `/examination/promotions/{session}/export` | `exa.promotions.export` | PromotionController@export |
| GET | `/examination/board-registrations` | `exa.board.index` | BoardController@index |
| POST | `/examination/board-registrations` | `exa.board.store` | BoardController@store |
| POST | `/examination/board-registrations/{reg}/roll-numbers` | `exa.board.roll-numbers.store` | BoardController@storeRollNumbers |
| GET | `/examination/board-registrations/{reg}/export` | `exa.board.export` | BoardController@export |
| GET | `/examination/analytics` | `exa.analytics.index` | ExamAnalyticsController@index |

---

## 7. UI Screens

### SCR-EXA-01: Examination Dashboard
**Route:** `exa.exams.index` (dashboard view)
**Elements:**
- Summary cards: Total Exams in Session, Marks Pending, Results Processed, Report Cards Generated
- Active exams list with status badges (draft/scheduled/ongoing/completed/published)
- Progress bars per exam showing marks entry completion percentage per class
- Quick-action buttons: New Exam, Enter Marks, Generate Report Cards
- Alert panel: exams with incomplete mark entry past exam date

### SCR-EXA-02: Exam Type Configuration
**Route:** `exa.exam-types.index`
**Elements:**
- Sortable table: Name, Code, Category, Weightage %, CCE flag, Grade Scale, Actions
- Session total weightage indicator (sum bar with 100% limit warning)
- Inline edit component dialog with component manager sub-table (add/remove theory/practical/internal rows)

### SCR-EXA-03: Exam Schedule Builder
**Route:** `exa.exams.show`
**Elements:**
- Exam header form: name, academic session, exam type, from/to date, instructions
- Subject slot table: subject, class-section, date, time, hall, max marks (theory/practical/internal), pass marks, invigilator
- Conflict indicator badges (red for student conflict, orange for invigilator conflict)
- Print timetable button
- Exam status stepper (draft → scheduled → ongoing → completed → published)

### SCR-EXA-04: Seating Arrangement
**Route:** `exa.seating.index`
**Elements:**
- Subject slot selector dropdown
- Pattern selector: ROLL_ORDER / ALPHABETICAL / RANDOM / MIXED_CLASS
- Visual hall grid: seat cells with student name on hover
- Drag-drop for manual seat reassignment
- Buttons: Generate, Reset, Print Chart, Print Seat Slips

### SCR-EXA-05: Admit Card Manager
**Route:** `exa.admit-cards.index`
**Elements:**
- Class-section selection for bulk generation
- Generation progress bar (polling backend job status)
- Student list with admit card status (generated / not generated / published)
- Bulk generate, publish toggle, download ZIP, individual download actions

### SCR-EXA-06: Mark Entry Grid
**Route:** `exa.marks.index`
**Elements:**
- Subject and class-section selector
- Inline editable grid: rows = students, columns = Theory / Practical / Internal / Grace / Absent / Malpractice / Remarks
- Row highlight: green (verified), blue (entered), orange (draft), red (absent/malpractice)
- Bulk save button with real-time validation feedback (cell-level errors highlighted)
- Download Excel template / Upload Excel buttons
- Mark entry completion status banner (X of Y students entered)
- Submit for verification button (teacher → HOD)

### SCR-EXA-07: Moderation Queue
**Route:** `exa.moderations.*`
**Elements:**
- Pending moderation table: student, subject, current marks, proposed marks, reason, proposer
- HOD view: propose moderation form with justification text area
- Principal view: approve/reject buttons with rejection reason field
- Moderation history tab with full audit trail

### SCR-EXA-08: Result Dashboard
**Route:** `exa.results.index`
**Elements:**
- Per-class result summary: pass count, fail count, compartment count, average %
- Process results button (with prerequisite check: all marks entered and verified)
- Result table: student, total marks, percentage, grade, rank, status
- Export: PDF class result sheet, Excel marks ledger

### SCR-EXA-09: Rank / Merit List
**Route:** `exa.rank-list.show`
**Elements:**
- Class rank / Section rank toggle
- Rank table: rank, student name, total, percentage, grade, subject-wise marks
- Merit list threshold input (top N students)
- Print PDF button, Export Excel button

### SCR-EXA-10: Report Card Generator
**Route:** `exa.report-cards.index`
**Elements:**
- Template type selector with preview thumbnail
- Toggle panel: show rank, attendance, photo, co-scholastic, remarks
- Primary/secondary language selectors
- Custom layout designer (if template = custom): drag-drop field placement canvas
- Bulk generate button (class-section selection) with background job progress indicator
- Individual preview: live in-browser PDF preview per student
- Class teacher remarks entry per student
- Publish controls with publish date picker (scheduled)

### SCR-EXA-11: CCE Configuration & Entry
**Route:** `exa.cce.index`
**Elements:**
- Term configuration: FA weightage / SA weightage per term (must sum to 100)
- FA assessment entry table per student per subject (FA1, FA2 rows with marks and type)
- CCE grade sheet view: FA1/FA2/SA columns with combined term grade
- Export CCE grade sheet PDF/Excel

### SCR-EXA-12: Promotion Manager
**Route:** `exa.promotions.show`
**Elements:**
- Promotion rules configuration panel (per class: min %, mandatory subjects, compartment limit)
- Process promotion button
- Promotion list table: student, result %, grade, auto-status (promoted/detained/compartment)
- Override column: Principal can change status with reason field
- Export promotion list; send notifications button

### SCR-EXA-13: Board Examination Coordination
**Route:** `exa.board.index`
**Elements:**
- Board type selector (CBSE/ICSE/State)
- Student list with eligibility status and board roll number entry
- Auto-assign sequential roll numbers button
- Export data in board format (CSV/XLSX)
- Registration status tracker

---

## 8. Business Rules

| ID | Rule |
|---|---|
| BR-EXA-001 | Marks cannot exceed component maximum — `theory_marks ≤ theory_max`; `practical_marks ≤ practical_max` |
| BR-EXA-002 | Report card generated only after all subjects' marks are entered and result is processed |
| BR-EXA-003 | Grade assignment always uses the configured grade scale; falls back to school default |
| BR-EXA-004 | `theory_max + practical_max + internal_max = max_marks` on exam subject slot creation |
| BR-EXA-005 | Absent students (is_absent=1) shown as "AB" on mark ledger — distinct from zero marks in display, but recorded as 0 for calculation |
| BR-EXA-006 | Grace marks per student per subject may not exceed `exa_settings.max_grace_percent` × `max_marks` (default 5%) |
| BR-EXA-007 | Moderation can only raise marks, never lower them — `proposed_marks > marks_obtained` |
| BR-EXA-008 | A subject teacher may only enter marks for subjects in their `sch_staff_subject_assignments` |
| BR-EXA-009 | Result processing is blocked if any `exa_exam_subjects.is_marks_entered = 0` for the exam |
| BR-EXA-010 | Once `exa_exams.status = published`, mark entries are locked — no further changes without Admin override |
| BR-EXA-011 | Compartment flag is only applied when student passes overall but fails in ≤ `max_allowed_compartment` non-mandatory subjects |
| BR-EXA-012 | Competition ranking: tied students share rank; the next rank is skipped by the number of tied students |
| BR-EXA-013 | CCE: `fa_weightage_percent + sa_weightage_percent = 100` per term config |
| BR-EXA-014 | Board roll numbers must be unique per board registration |
| BR-EXA-015 | Scheduled result publish time must be in the future at save |
| BR-EXA-016 | Malpractice entries may only be unlocked by Exam Controller or Admin — not by the entering teacher |
| BR-EXA-017 | Co-scholastic domains marked `is_system = 1` cannot be deleted or renamed |

---

## 9. Workflows

### 9.1 Examination Lifecycle FSM

```
                       +-------- Admin override ---------+
                       |                                  |
[DRAFT] ──add subjects──> [SCHEDULED] ──exam start date──> [ONGOING]
                                                              |
                                              all marks entered & verified
                                                              |
                                                        [COMPLETED]
                                                              |
                                              result processed + report cards generated
                                                              |
                                                        [PUBLISHED]
```

**State Transition Guards:**
- `draft → scheduled`: requires ≥ 1 subject slot with hall and invigilator assigned
- `scheduled → ongoing`: can be manual or automatic on exam from_date
- `ongoing → completed`: requires `is_marks_entered = 1` on all `exa_exam_subjects` for the exam
- `completed → published`: requires result processed (all `exa_results.status != draft`) and report cards generated

### 9.2 Mark Entry Workflow

```
Teacher enters marks (draft)
       ↓
Teacher submits for verification (entered)
       ↓
HOD reviews and verifies (verified)
       ↓ [optional path]
HOD proposes moderation → Principal approves → marks recalculated → back to verified
       ↓
All subjects verified → Exam status: completed
```

### 9.3 Result Processing Workflow

```
Exam Controller triggers Process Results
       ↓
ResultProcessingService validates prerequisites
  (all is_marks_entered = 1, all verified or moderation resolved)
       ↓
For each student:
  1. Aggregate marks from exa_mark_entries
  2. Compute total, percentage
  3. Apply grade scale → grade_letter, grade_point
  4. Compute GPA
  5. Determine pass/fail/compartment
  6. CCE overlay (if applicable)
       ↓
Compute class rank and section rank (competition ranking)
       ↓
Persist exa_results + exa_result_subjects
       ↓
Queue ProcessExamAnalyticsJob
       ↓
exa_exams.status = completed (if was ongoing)
```

### 9.4 Report Card Generation Workflow

```
Admin configures exa_report_configs (template, language, toggles)
       ↓
Class teacher adds remarks per student
       ↓
Principal adds principal remarks (optional)
       ↓
Admin triggers bulk generate → GenerateReportCardsJob dispatched
       ↓
Job: for each student in class-sections
  1. Fetch exa_results + exa_result_subjects
  2. Fetch attendance summary from ATT module
  3. Fetch co-scholastic entries (if CBSE template)
  4. Render DomPDF with selected template blade
  5. Store PDF via sys_media → update exa_report_cards.media_id
       ↓
Progress polling endpoint: /report-cards/progress
       ↓
Admin reviews → set publish_scheduled_at or publish immediately
       ↓
On publish: is_published = 1 → notification sent to students/parents
```

### 9.5 Promotion Processing Workflow

```
Admin configures exa_promotion_rules per class
       ↓
Admin triggers Process Promotions for session
       ↓
PromotionService:
  1. Fetch annual exam exa_results
  2. Check min_percentage, mandatory subjects, compartment limit
  3. Check min_attendance_percent (from ATT module) if configured
  4. Assign: PROMOTED / DETAINED / COMPARTMENT / WITHHELD
       ↓
Persist exa_promotion_lists
       ↓
DETAINED students → NotificationService::sendDetentionAlert(student, parent)
       ↓
Principal reviews → manual overrides with reason
       ↓
PROMOTED list exported to Student module for class advancement
```

---

## 10. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| NFR-EXA-001 | Performance | Result processing for 500 students across 12 subjects must complete within 30 seconds |
| NFR-EXA-002 | Performance | Bulk admit card or report card generation (500 PDFs) must complete as background job within 5 minutes |
| NFR-EXA-003 | Performance | Mark entry grid for 60 students must load within 2 seconds |
| NFR-EXA-004 | Performance | Rank list PDF generation must complete within 10 seconds for a class of 300 students |
| NFR-EXA-005 | Security | Mark entry restricted to subject-assigned teachers; Gate policy enforced at controller level |
| NFR-EXA-006 | Security | Result data is tenant-isolated; stancl/tenancy v3.9 prevents cross-school data access |
| NFR-EXA-007 | Security | Published results accessible to students/parents only after `exa_exams.status = published` |
| NFR-EXA-008 | Security | Board roll number data masked in non-Exam-Controller views (PII protection) |
| NFR-EXA-009 | Reliability | Bulk job failure does not corrupt partial results — DB transactions wrap per-student processing |
| NFR-EXA-010 | Reliability | Failed bulk job can be retried from where it left off using job progress tracking |
| NFR-EXA-011 | Scalability | Module supports up to 5,000 students per tenant across 200 class-sections |
| NFR-EXA-012 | Audit | All mark entry, moderation, and promotion decisions logged to `sys_activity_logs` with actor + timestamp |
| NFR-EXA-013 | Localization | Report cards support UTF-8 regional language characters (Hindi, Tamil, Telugu, Kannada, etc.) via DomPDF font embedding |
| NFR-EXA-014 | Accessibility | Mark entry grid keyboard navigable (Tab between cells; Enter to save) |
| NFR-EXA-015 | Storage | Generated PDF assets stored in tenant-scoped disk path; purged on soft-delete of exam |

---

## 11. Dependencies

### 11.1 Inbound Dependencies (EXA reads from)

| Module | Tables / Data | Usage |
|---|---|---|
| SchoolSetup (`sch_*`) | `sch_classes`, `sch_sections`, `sch_subjects`, `sch_halls`, `sch_academic_sessions`, `sch_class_sections` | Exam scheduling, student enrollment, hall capacity |
| StudentProfile (`std_*`) | `std_students`, `std_student_class_sections`, student photos | Student roster, seating, admit cards, result records |
| Staff (`sch_staff_*`) | `sch_staff_subject_assignments` | Gate policy for mark entry |
| Users (`sys_users`) | Invigilator and teacher lookups | Invigilator assignment, mark entry actor |
| Timetable (`tt_*`) | `tt_timetable_cells`, `tt_activities` | Conflict detection: student class timetable vs exam slot |
| Attendance (`att_*`) | `att_student_attendance` | Attendance summary on report card; promotion eligibility check |
| LmsExam (`exm_*`) | `exm_exam_results` | Optional: import online exam marks into EXA mark entry |
| Syllabus (`slb_*`) | `slb_topics` | Skill-gap mapping in analytics (topic → subject cross-reference) |
| GlobalMaster (`glb_*`) | `glb_translations` | Bilingual report card labels |
| Media (`sys_media`) | Polymorphic file storage | PDF storage for admit cards, report cards, board exports |

### 11.2 Outbound Dependencies (EXA writes to / triggers)

| Module | Integration | Direction |
|---|---|---|
| Notification (`ntf_*`) | Result-published alert, detention alert, compartment notice, teacher weak-area alert | EXA emits event → NTF sends |
| Recommendation (`rec_*`) | `ExamWeakAreaDetected` event → trigger remedial content recommendation for student | EXA emits event |
| StudentPortal (`stp_*`) | Admit card, result, report card portal visibility via `is_published` flag | EXA controls visibility |
| ParentPortal (`ppt_*`) | Child's result and report card access | EXA controls visibility |
| Certificate (`crt_*`) | Merit list students emitted for merit certificate generation | EXA emits merit list |
| Academic Calendar (`acd_*`) | Exam period and exam dates auto-created in academic calendar | EXA writes `acd_calendar_events` |
| Student Module (`std_*`) | PROMOTED student list for class advancement | EXA exports list (no direct write) |
| Activity Logs (`sys_activity_logs`) | Audit trail for all state changes, mark entry, moderation, promotion overrides | EXA writes |

---

## 12. Test Scenarios

| ID | Scenario | Type | Expected Result |
|---|---|---|---|
| TS-EXA-001 | Create exam type with duplicate code | Unit | HTTP 422 with code uniqueness error |
| TS-EXA-002 | Create exam subject slot with invigilator conflict | Feature | Conflict detected; alert shown; save blocked |
| TS-EXA-003 | Auto-generate seating for 60 students in hall with capacity 50 | Feature | Error: students exceed hall capacity |
| TS-EXA-004 | Mark entry: absent student with non-zero theory marks | Unit | HTTP 422 |
| TS-EXA-005 | Bulk mark upload: one row with marks > max; verify atomic rejection | Feature | All rows rejected; row-level error report returned |
| TS-EXA-006 | Moderation: propose > max_marks; should be blocked | Unit | HTTP 422: proposed exceeds maximum |
| TS-EXA-007 | Grade scale: overlapping bands save attempt | Unit | HTTP 422 with overlap error |
| TS-EXA-008 | Process results: one subject has is_marks_entered = 0 | Feature | Processing blocked with prerequisite error |
| TS-EXA-009 | Result processing: verify competition ranking with 3-way tie | Unit | Tied students share rank; next rank skips by 3 |
| TS-EXA-010 | CCE: fa_weightage + sa_weightage = 90 (not 100) | Unit | HTTP 422 on config save |
| TS-EXA-011 | Bulk report card generation for 200 students dispatches background job | Feature | Job queued; progress endpoint returns 0–100% |
| TS-EXA-012 | Publish exam before result processed | Feature | Publish blocked; error message returned |
| TS-EXA-013 | Student portal: access result before is_published = 1 | Feature | HTTP 403 / empty result set in portal |
| TS-EXA-014 | Promotion: student below min_attendance_percent flagged correctly | Feature | Student classified as WITHHELD |
| TS-EXA-015 | Board roll number: assign duplicate roll number for same board registration | Unit | HTTP 422 unique constraint error |
| TS-EXA-016 | Analytics: declining trend flag after 3 exams with declining percentage | Unit | MEDIUM risk alert created |
| TS-EXA-017 | Mark entry: malpractice student cannot be un-flagged by entering teacher | Feature | HTTP 403 for teacher; success for Exam Controller |
| TS-EXA-018 | Cumulative result regeneration: idempotent re-processing replaces old record | Feature | Single cumulative record per student per session |
| TS-EXA-019 | Co-scholastic entry: add A grade for Work Education; verify on CBSE report card PDF | Feature | Co-scholastic section appears correctly |
| TS-EXA-020 | Scheduled publish fires within ±5 minutes of configured time | Integration | NTF alerts sent; portal access opened on schedule |

---

## 13. Glossary

| Term | Definition |
|---|---|
| **EXA** | Examination Management — traditional offline school exam system |
| **EXM** | LmsExam — online digital examination system (different module) |
| **CCE** | Continuous and Comprehensive Evaluation — CBSE assessment pattern with FA+SA structure |
| **FA** | Formative Assessment — ongoing evaluation (oral, class test, project, portfolio) |
| **SA** | Summative Assessment — terminal written examination per term |
| **GPA** | Grade Point Average — weighted average of subject grade points |
| **CGPA** | Cumulative Grade Point Average — GPA averaged across all terms/exams in session |
| **Compartment** | Status where student passes overall but failed ≤ N non-mandatory subjects |
| **Detained** | Student who fails to meet promotion criteria and must repeat the class |
| **Withheld** | Result withheld pending documentation or attendance shortfall resolution |
| **Moderation** | Administrative adjustment to marks with documented justification and approval workflow |
| **Grace Marks** | Additional marks awarded by moderation to borderline students within school/board limits |
| **Malpractice** | Exam misconduct; marks set to zero; entry locked pending inquiry |
| **Invigilator** | Staff member assigned to supervise students in an exam hall |
| **Hall Ticket** | Admit card — printed document authorising student to appear in examination |
| **Roll Number** | Internal exam identification number assigned to student for the exam event |
| **Board Roll Number** | External roll number assigned by CBSE/ICSE for board examination registration |
| **Merit List** | Ranked list of top-performing students; used to trigger certificate generation |
| **LOC** | List of Candidates — CBSE format file for board exam registration |
| **Competition Ranking** | Ranking method where tied students share the same rank; next rank skips accordingly |
| **Co-Scholastic** | Non-academic assessment domains: Work Education, Art, Physical Education, Discipline |
| **DomPDF** | PHP PDF generation library used for admit cards, report cards, and mark ledgers |

---

## 14. Suggestions (V2 Enhancements)

### SUG-EXA-001: Answer Script Tracking
Track distribution and collection of physical answer scripts per hall per exam slot. Record: `scripts_distributed`, `scripts_collected`, `missing_scripts` count. Useful for board compliance and internal audits.

### SUG-EXA-002: Digital Answer Submission (Hybrid Mode)
For practical exams and internal assessments, allow teachers to accept digital submissions (scanned or uploaded PDFs) and annotate/mark them within the platform. Bridges EXA and EXM for hybrid schools.

### SUG-EXA-003: Parent Digital Signature on Report Card
Support parent digital acknowledgement of report card receipt via OTP confirmation in the parent portal, replacing the physical signature. Store acknowledgement timestamp and OTP reference.

### SUG-EXA-004: Exam Fee Integration
Link exam fee collection (for board exams) to the FIN module. Track whether a student has paid board exam registration fee before including them in the board LOC export.

### SUG-EXA-005: Comparative Class Performance Dashboard
Visual chart comparing class average percentage across consecutive exams (e.g., UT1 vs UT2 vs Half Yearly) per subject. Enables teacher-level trend identification without going into individual student records.

### SUG-EXA-006: Supplementary / Re-Exam Management
Add a sub-workflow for compartment exam scheduling: a COMPARTMENT student gets a supplementary exam slot; marks entered separately; if they pass, status changes to PROMOTED with annotation.

### SUG-EXA-007: IB & Cambridge Assessment Extensions
For international schools using IB MYP or Cambridge IGCSE, extend `exa_result_subjects` with criterion-based scoring columns (criterion A–H for IB, component-level breakdown for Cambridge) beyond the current theory/practical model.

### SUG-EXA-008: Automated Invigilator Rotation
Suggest invigilator assignments automatically based on availability, subject exclusion (teacher cannot invigilate their own subject), and timetable conflicts — similar to the smart timetable constraint engine.

---

## 15. Appendices

### Appendix A: RBS Traceability Matrix

| RBS Feature | FR Coverage |
|---|---|
| F.I1 — Exam Types & Weightage | FR-EXA-001 |
| F.I2 — Exam Timetable Scheduling | FR-EXA-002, FR-EXA-003 |
| F.I2 — Conflict Checking | FR-EXA-002 |
| F.I3 — Marks Entry & Verification | FR-EXA-005 |
| F.I4 — Moderation Workflow | FR-EXA-006 |
| F.I5 — Gradebook Calculation Engine | FR-EXA-007, FR-EXA-008 |
| F.I5 — Rank Generation | FR-EXA-009 |
| F.I5 — CCE Calculation | FR-EXA-012 |
| F.I6 — Report Cards & Publishing | FR-EXA-010, FR-EXA-011, FR-EXA-015 |
| F.I7 — Promotion & Detention Rules | FR-EXA-014 |
| F.I8 — Board Pattern Support | FR-EXA-016 |
| F.I9 — Custom Report Card Designer | FR-EXA-010 (custom template) |
| F.I10 — AI-Based Analytics | FR-EXA-017 |
| F5 — Internal Assessment / Co-Scholastic | FR-EXA-013 |
| Admit Card (derived from F.I2/F.I6) | FR-EXA-004 |
| Cumulative Report (derived from F.I6) | FR-EXA-011 |

### Appendix B: Grade Scale Pre-Seeds

**CBSE 10-Point GPA (code: CBSE_GPA)**

| Grade | Range | Grade Point | Description |
|---|---|---|---|
| A1 | 91–100 | 10.0 | Outstanding |
| A2 | 81–90 | 9.0 | Excellent |
| B1 | 71–80 | 8.0 | Very Good |
| B2 | 61–70 | 7.0 | Good |
| C1 | 51–60 | 6.0 | Average |
| C2 | 41–50 | 5.0 | Satisfactory |
| D | 33–40 | 4.0 | Needs Improvement |
| E | 0–32 | 0.0 | Fail |

**ICSE Letter Grade (code: ICSE_LETTER)**

| Grade | Range | Description |
|---|---|---|
| A | 75–100 | Distinction |
| B | 60–74 | First Division |
| C | 45–59 | Second Division |
| D | 35–44 | Pass |
| E | 0–34 | Fail |

### Appendix C: Exam Type Pre-Seeds

| Code | Name | Category | Weightage |
|---|---|---|---|
| FA1 | Formative Assessment 1 | formative | 10 |
| FA2 | Formative Assessment 2 | formative | 10 |
| SA1 | Summative Assessment 1 (Mid-Term) | summative | 30 |
| SA2 | Summative Assessment 2 (Annual) | summative | 50 |
| UT1 | Unit Test 1 | formative | 0 |
| UT2 | Unit Test 2 | formative | 0 |
| HY | Half Yearly | summative | 40 |
| ANNUAL | Annual Examination | annual | 60 |
| BOARD | Board Examination | board | 0 |

### Appendix D: Controller Reference

| Controller | Location | Primary Responsibility |
|---|---|---|
| `ExamTypeController` | `Http/Controllers` | CRUD exam types and components |
| `ExamController` | `Http/Controllers` | Exam event CRUD, status transitions, publish |
| `ExamSubjectController` | `Http/Controllers` | Subject slot CRUD within exam |
| `InvigilatorController` | `Http/Controllers` | Invigilator assignment |
| `SeatingController` | `Http/Controllers` | Seating auto-generation and manual update |
| `AdmitCardController` | `Http/Controllers` | Admit card generation, publish, download |
| `MarkEntryController` | `Http/Controllers` | Mark entry grid, bulk upload, verification |
| `ModerationController` | `Http/Controllers` | Moderation propose/approve/reject |
| `GradeScaleController` | `Http/Controllers` | Grade scale and band management |
| `ResultController` | `Http/Controllers` | Result processing trigger, result views |
| `RankListController` | `Http/Controllers` | Rank list and merit list generation |
| `ReportCardController` | `Http/Controllers` | Report card generation, config, publish |
| `CumulativeController` | `Http/Controllers` | Cumulative result generation and view |
| `CceController` | `Http/Controllers` | CCE config and FA assessment entry |
| `CoscholasticController` | `Http/Controllers` | Co-scholastic domain entry |
| `PromotionController` | `Http/Controllers` | Promotion rule config, processing, overrides |
| `BoardController` | `Http/Controllers` | Board registration, roll numbers, export |
| `ExamAnalyticsController` | `Http/Controllers` | Analytics dashboard and alert management |

---

## 16. V1 → V2 Delta

| Area | V1 Coverage | V2 Enhancement |
|---|---|---|
| Exam Types | Basic CRUD, component definition | Added `grade_scale_id` per exam type; added board category; pre-seeded exam type list |
| Exam Schedule | Subject slots with conflict detection | Added ACD calendar integration; added malpractice flag on mark entry |
| Seating | 4 patterns, manual override | Added cross-class hall seating detail; admit card invalidation on re-generate |
| Admit Cards | Bulk generation, portal publish | Added download-all ZIP; progress polling endpoint |
| Mark Entry | Grid + Excel upload + absent + grace | Added `is_malpractice` flag; teacher Gate policy from `sch_staff_subject_assignments`; atomic bulk validation details |
| Moderation | Propose → approve/reject | Added: moderation can only raise marks (BR-EXA-007); sequential moderation history |
| Grade Scales | CBSE/ICSE/percentage/custom | Added `is_system` flag for read-only pre-seeded scales; added clone-and-customise flow |
| Result Processing | Total/grade/rank/pass/fail | Added subject-rank to `exa_result_subjects`; added CCE overlay in processing algorithm; competition ranking tie-break rule clarified |
| Report Cards | Multi-template + bilingual | Added: co-scholastic toggle (`show_coscholastic`); attendance from ATT module explicitly; cumulative PDF from `exa_cumulative_results` |
| Cumulative Report | Mentioned briefly in V1 | Full FR-EXA-011 with dedicated `exa_cumulative_results` table |
| Co-Scholastic | Mentioned in CCE section | Full FR-EXA-013 with `exa_coscholastic_domains` and `exa_coscholastic_entries` tables |
| Promotion | Rules + list + notification | Added attendance check integration with ATT module; WITHHELD status added |
| Board Coordination | Open question in V1 | Full FR-EXA-016 with `exa_board_registrations` and `exa_board_roll_numbers` tables; export formats defined |
| Analytics | Basic weak-area + alerts | Added `exa_performance_analytics` and `exa_ai_alerts` tables; class-level failure rate alerts; recommendation event emission |
| New in V2 | — | FR-EXA-011 (Cumulative Report Card), FR-EXA-013 (Co-Scholastic), FR-EXA-016 (Board Coordination); 8 Suggestions section; Appendices B/C/D |
| API Routes | ~65 estimated in V1 | ~80 named routes defined explicitly in Section 6 |
| UI Screens | 5 basic screens in V1 | 13 detailed screen specifications in Section 7 |
| Business Rules | Validation table (10 rules) | 17 explicit business rules in Section 8 |
| Permissions | 17 permissions listed | Unchanged; malpractice unlock permission added to NFR-EXA-008 |
| Data Model | 16 tables | 22 tables (added: `exa_coscholastic_domains`, `exa_coscholastic_entries`, `exa_cumulative_results`, `exa_board_registrations`, `exa_board_roll_numbers`, `exa_performance_analytics` split from analytics) |
