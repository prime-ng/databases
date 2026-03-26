# EXA — Examination Module
## Requirement Document v1.0

**Module Code:** EXA
**Module Type:** Tenant Module (per-school)
**Table Prefix:** `exa_*`
**Proposed Module Path:** `Modules/Examination`
**RBS Reference:** Module I — Examination & Gradebook (sub-tasks I1–I10, 46 sub-tasks, lines 2592–2708)
**Development Status:** ❌ Not Started — Greenfield
**Document Date:** 2026-03-25
**Processing Mode:** RBS-ONLY

---

## 1. Executive Summary

### 1.1 Purpose

The Examination module is the formal school examination management system for Prime-AI. It handles the complete formal examination lifecycle specific to Indian K-12 schools: defining exam structure and type schemes (Unit Tests, Half-Yearly, Annual, Board exams), scheduling examination timetables, managing seating arrangements and invigilators, issuing admit cards, recording subject-wise marks, applying moderation workflows, computing grades and GPA/CGPA through configurable grade scales, generating class and section rank lists, producing PDF progress report cards with school branding, processing student promotions and detentions, and publishing results to parent/student portals.

This module is architecturally distinct from LmsExam (`exm_*`), which handles digital question papers, paper sets, blueprints, and online exam conduction. EXA handles the **formal examination system** — the scheduled institutional exams, offline mark entry, gradebooks, and physical report cards that Indian schools legally require.

### 1.2 Scope Summary

This module covers:
- Exam type and component configuration (Theory, Practical, Internal Assessment)
- Subject weightage schemes and grade calculation formulas
- Exam scheduling with date, time, subject, hall and invigilator assignment
- Conflict detection across student and invigilator timetables
- Seating arrangement generation with seat number and roll number
- Admit card PDF generation per student
- Subject-wise mark entry with absent marking, grace marks, practical/internal breakdowns
- Bulk mark upload via Excel template
- Marks verification and moderation workflow with approval trail
- Grade scale configuration (CBSE 10-point, ICSE, percentage-based)
- GPA/CGPA computation
- CCE (Continuous & Comprehensive Evaluation) support with formative + summative weightage
- Result processing: pass/fail determination, compartment flagging
- Rank list generation (class rank, section rank)
- Progress report card PDF generation with templates and school branding
- Bilingual report card support (English + regional language)
- Multi-board support (CBSE, ICSE, IB, Cambridge) with board-specific templates
- Custom report card designer (drag-and-drop fields)
- Student promotion and detention processing
- Result publishing to student/parent portal
- AI-based performance analytics: skill-gap identification, weak-area alerts, predictive risk

### 1.3 Module Statistics (Projected)

| Metric | Projected Count |
|---|---|
| RBS Features (F.I*.*) | 20 |
| RBS Tasks | 23 |
| RBS Sub-tasks | 46 |
| DB Tables (`exa_*`) | 16 |
| Named Routes (estimated) | ~65 |
| Blade Views (estimated) | ~40 |
| Controllers (estimated) | 12 |
| Models (estimated) | 16 |
| Services (estimated) | 4 |
| Jobs (estimated) | 2 |
| FormRequests (estimated) | 12 |

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

Indian schools operate two parallel exam systems:
1. **Digital/LMS exams** — online MCQ tests, quiz-based assessments (handled by LmsExam/LmsQuiz)
2. **Formal institutional exams** — scheduled hall-based written exams, centrally coordinated, with printed admit cards, invigilators, mark sheets, rank lists, and printed/digital report cards

EXA addresses the second system entirely. The formal examination cycle directly affects student promotions, board registrations, school accreditation, and parent trust. Indian regulatory frameworks (CBSE, State Boards) mandate structured mark records, signed report cards, and documented promotion decisions.

### 2.2 Key Features

1. Configurable exam types with formative/summative categories and percentage weightages
2. Theory + Practical + Internal Assessment component breakdown per subject
3. Exam timetable scheduling with hall, invigilator, and conflict detection
4. Auto-generated seating plans with customizable seat numbering patterns
5. PDF admit card generation per student with exam schedule
6. Subject-wise mark entry (individual and bulk Excel upload)
7. Marks moderation workflow with HOD/Principal approval
8. Configurable grade scales (CBSE 10-point, ICSE, percentage, custom)
9. CCE support: formative assessments weighted into summative result
10. Automatic pass/fail and compartment determination
11. Class and section rank list generation
12. PDF progress report cards with school branding, multiple templates
13. Board-specific report formats (CBSE, ICSE, IB, Cambridge)
14. Custom report card designer
15. Student promotion and detention processing with notifications
16. Portal result publishing
17. AI-based performance insights and predictive alerts

### 2.3 Menu Path

`Academic > Examination` or `Examination > [sub-menu items]`

### 2.4 Architecture

The module follows a lifecycle-driven architecture. An exam progresses through defined states (`draft → scheduled → ongoing → completed → published`). Each state gate is enforced at the service layer. Mark entry, result processing, and report card generation are performed as batch jobs for performance with real-time progress polling.

**Integration Points:**
- `sch_classes`, `sch_sections`, `sch_subjects` — class-subject-section structure
- `std_students` — student roster per class-section
- `sys_users` (staff) — invigilator assignment, mark entry audit
- `slb_academic_sessions` / `sch_academic_sessions` — session scoping
- LmsExam (`exm_*`) — optional: pull blueprint/marks from online exam into EXA mark entry
- `sys_media` — polymorphic admit card PDF and report card PDF storage
- Notification module — result publication notifications to parents/students

---

## 3. Stakeholders & Actors

| Actor | Role |
|---|---|
| Principal / Admin | Creates exam types, approves exam schedule, approves moderation, publishes results, configures grade scales |
| Exam Controller | Creates exam timetable, seating arrangements, manages the overall exam event |
| Subject Teacher | Enters marks for their subject, uploads bulk mark sheets |
| Head of Department (HOD) | Reviews and approves marks moderation for their department |
| Class Teacher | Generates and distributes report cards, manages promotion list |
| Student | Views admit card, views published result and report card via portal |
| Parent | Views child's result, report card, and promotion status via portal |
| System / Scheduler | Runs batch jobs for result processing and depreciation |

---

## 4. Functional Requirements

### FR-EXA-001: Exam Type & Component Configuration
**RBS Reference:** I1 (Exam Structure & Scheme) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables:** `exa_exam_types`, `exa_exam_components`

**Description:** CRUD management of exam type masters. Each exam type defines whether it is formative (Unit Test, Class Test, FA-1/FA-2) or summative (Mid-Term, Half-Yearly, Annual, SA-1/SA-2), and carries a percentage weightage used for cumulative result calculation. Components define the breakdown within an exam type: Theory, Practical, Internal Assessment, Oral, Portfolio.

**Actors:** Admin / Principal
**Input:**
- Exam type: `name`, `code` (VARCHAR 20, UNIQUE), `exam_category` (ENUM formative/summative/annual), `weightage_percent` DECIMAL(5,2), `is_ccce_applicable` TINYINT(1)
- Exam component: `component_name` (Theory/Practical/Internal/Oral/Portfolio), `max_marks_default`, `is_mandatory`

**Processing:**
- Weightage across summative exam types within an academic session must total ≤ 100%
- Soft delete lifecycle; code uniqueness enforced at DB level
- Deleting an exam type is blocked if active exams reference it

**Output:** Exam type list used as FK in `exa_exams.exam_type_id`; components used in `exa_exam_subjects`

**Acceptance Criteria:**
- AC-001-01: Code must be unique — duplicate code returns 422 validation error
- AC-001-02: Formative exam type accepts weightage 0–40; summative 0–100; system warns if total session weightage > 100%
- AC-001-03: Soft delete and restore maintain audit trail
- AC-001-04: At least one component (Theory) must exist per exam type

---

### FR-EXA-002: Exam Schedule Management
**RBS Reference:** I2 (Exam Timetable Scheduling) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables:** `exa_exams`, `exa_exam_subjects`, `exa_invigilators_jnt`

**Description:** Creation and management of exam events with full timetable scheduling. An exam is a named event (e.g., "Half Yearly Examination 2025-26") linked to an academic session. Individual exam slots are created per subject per class-section with date, start/end time, hall, max marks, pass marks, and invigilator assignments. Conflict detection prevents scheduling the same student in two simultaneous exam slots or the same invigilator in two halls at the same time.

**Actors:** Exam Controller, Admin
**Input:**
- Exam header: `academic_session_id`, `exam_type_id`, `name`, `from_date`, `to_date`, `status`
- Exam subject slot: `exam_id`, `subject_id`, `class_section_id`, `exam_date`, `start_time`, `end_time`, `max_marks`, `pass_marks`, `theory_max`, `practical_max`, `internal_max`, `hall_id`
- Invigilator: `exam_subject_id`, `staff_id`, `is_chief_invigilator`

**Processing:**
- On slot save: detect if any student enrolled in the class-section already has another exam slot at the same date/time
- Detect invigilator time conflicts across halls
- Validate `pass_marks ≤ max_marks`; validate component marks sum to `max_marks`

**Output:** Exam timetable view per class, conflict report

**Acceptance Criteria:**
- AC-002-01: Student timetable clash detection — alert shown, save blocked unless overridden by Admin
- AC-002-02: Invigilator conflict detection — alert shown, save blocked unless overridden
- AC-002-03: Exam status transitions: draft → scheduled requires at least one subject slot
- AC-002-04: Exam dates must fall within academic session dates

---

### FR-EXA-003: Seating Arrangement
**RBS Reference:** I2 (Exam Timetable Scheduling, ST.I2.1.1.2) | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `exa_seating_arrangements`

**Description:** Automated generation of student seating plans for each exam subject slot. Assigns hall seat numbers and roll numbers to students. Supports mixed-class seating (students from different sections interleaved in the same hall). Allows manual override of individual seat assignments. Printable seating chart per hall.

**Actors:** Exam Controller
**Input:** `exam_subject_id`, hall seating pattern (ROLL_ORDER, ALPHABETICAL, RANDOM, MIXED_CLASS), hall capacity
**Processing:**
- Auto-assign seats based on selected pattern
- Roll number auto-generated as `[class_code]-[section_code]-[sequence]` or configurable format
- Validate seat count ≤ hall capacity
- Manual override: drag seat number from one student to another with conflict check

**Output:** Seating chart PDF per hall, student-wise seat slip

**Acceptance Criteria:**
- AC-003-01: Auto-generate fills all enrolled students without duplicate seat assignment
- AC-003-02: Manual override reflects immediately; duplicate seat triggers validation error
- AC-003-03: Seating chart PDF exports correctly with student name, roll number, seat number

---

### FR-EXA-004: Admit Card Generation
**RBS Reference:** I2 / I6 (Report Generation) | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `exa_admit_cards`

**Description:** Generation of individual PDF admit cards per student per exam. Admit card includes: school logo, student name, class, roll number, photograph, exam schedule (all subject slots with date/time/hall/seat), instructions, and principal signature. Bulk generation as a background job with download-all-as-ZIP option. Publishing admit cards to student/parent portal.

**Actors:** Exam Controller, Admin
**Input:** `exam_id`, class-section selection for bulk generation
**Processing:**
- Pull exam schedule from `exa_exam_subjects` joined with `exa_seating_arrangements`
- Generate PDF using DomPDF with school branding from `sch_organizations` / `sys_media`
- Store generated PDF reference in `exa_admit_cards.file_path` via `sys_media`
- Bulk generation dispatched as `GenerateAdmitCardsJob`

**Output:** Per-student PDF, bulk ZIP download, portal publishing toggle

**Acceptance Criteria:**
- AC-004-01: Admit card cannot be generated until seating arrangement is finalized for all subjects in the exam
- AC-004-02: Bulk generation completes in < 60s for 500 students (background job)
- AC-004-03: Published admit cards are visible to student/parent in portal

---

### FR-EXA-005: Mark Entry
**RBS Reference:** I3 (Marks Entry & Verification) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables:** `exa_mark_entries`

**Description:** Subject-wise mark entry per student per exam subject slot. Supports individual entry (form), bulk entry (inline grid), and bulk upload (Excel template). Mark entry records theory marks, practical marks, internal assessment marks, grace marks, and absent flag. Each entry carries an `entry_status` (draft/entered/verified) and full audit trail.

**Actors:** Subject Teacher, Exam Controller
**Input (per entry):**
- `exam_subject_id`, `student_id`
- `is_absent` TINYINT(1)
- `theory_marks` DECIMAL(5,2), `practical_marks` DECIMAL(5,2), `internal_marks` DECIMAL(5,2)
- `grace_marks` DECIMAL(4,2) DEFAULT 0
- `remarks` VARCHAR 255

**Processing:**
- Validate: each component marks ≤ max for that component
- `is_absent = 1` forces all marks to 0 and sets `marks_obtained = 0`
- Grace marks cannot exceed configured school limit (default 5%)
- `marks_obtained = theory_marks + practical_marks + internal_marks + grace_marks`
- On all entries for a subject slot completed, auto-flag subject slot as `marks_entered`

**Bulk Upload:**
- Template: Excel with columns [Roll No, Student Name, Theory, Practical, Internal, Grace, Absent, Remarks]
- Validate on server before committing; return row-level error report

**Output:** Marks ledger per subject, entry completion status per class-section

**Acceptance Criteria:**
- AC-005-01: Absent student cannot have non-zero theory/practical marks (except grace)
- AC-005-02: Marks exceeding component maximum return 422 with field-level error
- AC-005-03: Bulk upload validates all rows before any are committed — atomic
- AC-005-04: Entry status transitions: draft → entered (by teacher) → verified (by HOD)

---

### FR-EXA-006: Marks Moderation Workflow
**RBS Reference:** I4 (Moderation Workflow) | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `exa_mark_moderations`

**Description:** Multi-stage marks moderation workflow for borderline students. After marks are entered and verified, HOD or Exam Controller can propose moderation: add or adjust marks with justification. Moderation must be approved by Principal before it affects results. All moderation actions carry a full audit trail.

**Actors:** HOD (propose), Principal / Admin (approve/reject)
**Input:** `mark_entry_id`, `proposed_marks`, `moderation_reason` TEXT, `approver_id`
**Processing:**
- Moderation request status: `proposed → approved / rejected`
- Approved moderation updates `exa_mark_entries.grace_marks` or creates a moderation delta record
- Rejected moderation records rejection reason; original marks remain unchanged
- Full history preserved in `exa_mark_moderations` — no deletion

**Output:** Moderation queue, approval history, audit log

**Acceptance Criteria:**
- AC-006-01: Only users with `moderation.propose` permission can create moderation requests
- AC-006-02: Only users with `moderation.approve` permission can approve
- AC-006-03: Approved moderation recalculates student result automatically
- AC-006-04: Moderation records are immutable after approval

---

### FR-EXA-007: Grade Scale Configuration
**RBS Reference:** I5 (Gradebook Calculation Engine) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables:** `exa_grade_scales`, `exa_grade_scale_bands`

**Description:** Configuration of grading systems for the school. Supports multiple grade scales per school (e.g., CBSE 10-point GPA, ICSE letter grades, percentage-based). A grade scale comprises a set of bands, each defining a percentage range mapped to a grade letter, grade point, and descriptive remark. The applicable grade scale is assigned per exam type or per class.

**Actors:** Admin / Principal
**Input:**
- Scale: `name` (e.g., "CBSE 10-Point GPA"), `scale_type` ENUM(percentage/letter_grade/gpa/ccce), `is_default`
- Band: `grade_scale_id`, `min_percent` DECIMAL(5,2), `max_percent` DECIMAL(5,2), `grade_letter` VARCHAR 5 (A1/A2/B1…/E), `grade_point` DECIMAL(3,1), `description` (Outstanding/Excellent/…/Fail), `is_pass`

**Processing:**
- Bands within a scale must be non-overlapping and cover 0–100% without gaps
- GPA computed as weighted average of subject grade points (weighted by subject credit hours or equal weight)
- CGPA = average of GPA across all summative exams in the session

**Output:** Configured grade scale used in result processing

**Acceptance Criteria:**
- AC-007-01: Overlapping band ranges return validation error
- AC-007-02: Sum of gaps in 0–100 range → warning on save
- AC-007-03: Default scale is used when no specific scale assigned to exam type

---

### FR-EXA-008: Result Processing
**RBS Reference:** I5 (Gradebook Calculation Engine), I7 (Promotion & Detention Rules) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables:** `exa_results`, `exa_result_subjects`

**Description:** Batch processing of exam results after marks entry is complete for all subjects. Calculates: total marks, percentage, grade, grade point, pass/fail status, compartment (failed in specific subject(s) while passing overall), class rank, section rank. Generates a result record per student per exam that becomes the source for report cards.

**Actors:** System (triggered by Exam Controller)
**Input:** `exam_id`, grade scale assignment
**Processing (per student):**
1. Aggregate marks from `exa_mark_entries` for all subjects
2. Compute `total_marks`, `total_max_marks`, `percentage`
3. Apply grade scale: determine `grade_letter`, `grade_point`
4. Compute GPA if applicable
5. Pass/fail: student passes if `is_pass = true` in their grade band AND passes all mandatory subjects; otherwise FAIL
6. Compartment: student overall passes but failed in ≤ N subjects (configurable, default 1-2)
7. Rank: order students by `percentage DESC` (tie-break by subject-wise total); assign `rank_in_class` and `rank_in_section`
8. CCE: if `exam_type.is_ccce_applicable`, combine formative weightage + summative weightage per FA/SA config

**Output:** `exa_results` record per student; `exa_result_subjects` per student-subject

**Acceptance Criteria:**
- AC-008-01: Result processing blocked if any subject has pending mark entries
- AC-008-02: Absent students counted as 0 marks for that subject
- AC-008-03: Compartment students flagged as `status = compartment`; not FAIL
- AC-008-04: Rank ties: shared rank, next rank skipped (standard competition ranking)
- AC-008-05: Result processing is idempotent (re-processing replaces existing results)

---

### FR-EXA-009: Rank / Merit List
**RBS Reference:** I5 | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `exa_results` (read), `exa_rank_lists`

**Description:** Generation of class-wise and section-wise rank / merit lists. Rank lists are printable PDFs listing students by rank with total marks, percentage, and grade. Top performers can be flagged for merit certificates. Rank lists are generated as a derivative of result processing and can be re-generated if marks are corrected.

**Actors:** Class Teacher, Exam Controller
**Input:** `exam_id`, `class_id` (for class rank) or `class_section_id` (for section rank)
**Processing:**
- Read from `exa_results` where status = processed/published
- Sort by percentage DESC, apply tie-breaking rule
- Generate printable PDF rank list

**Output:** PDF rank list, merit list for top N students

**Acceptance Criteria:**
- AC-009-01: Rank list correctly implements competition ranking (tied students share rank)
- AC-009-02: Merit list threshold configurable (top 3, top 5, or top N%)
- AC-009-03: Rank list PDF includes school header, class name, exam name, date of generation

---

### FR-EXA-010: Progress Report Card Generation
**RBS Reference:** I6 (Report Cards & Publishing), I8 (Board Pattern Support), I9 (Custom Report Card Designer) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables:** `exa_report_configs`, `exa_report_templates`, `exa_report_cards`

**Description:** Generation of individual PDF progress report cards per student per exam. Report cards include: school identity, student details (name, class, section, roll number, photo), subject-wise marks breakdown (theory/practical/internal), total marks, percentage, grade, rank, attendance summary, teacher remarks, principal remarks, and promotion decision. Supports multiple template types (standard, CBSE, ICSE, IB, custom). Custom template designer allows drag-and-drop field placement. Bilingual support (English + regional language).

**Actors:** Class Teacher, Admin
**Input:**
- `exa_report_configs`: `exam_id`, `template_type` ENUM(standard/cbse/icse/ib/cambridge/custom), `show_rank`, `show_attendance`, `show_remarks`, `show_photo`, `language_code_secondary`, `header_text_json`
- Custom template designer: field positions in JSON

**Processing:**
- Merge data from `exa_results` + `exa_result_subjects` + student profile + attendance summary
- Render using DomPDF with school branding
- Batch generation via `GenerateReportCardsJob` (background)
- Store PDF path via `sys_media` polymorphic table

**Board-specific templates:**
- CBSE: 10-point GPA format with FA1/FA2/SA1/SA2 breakdowns
- ICSE: subject-code mapped, letter grade + percentage
- IB: MYP criterion-based grades
- Cambridge: Cambridge grade descriptors

**Bilingual Support:**
- Secondary language field list configurable per school
- Report card section headers and grade descriptors translated via `glb_translations`

**Output:** Per-student report card PDF, bulk download ZIP

**Acceptance Criteria:**
- AC-010-01: Report card cannot be generated until result is processed (status = processed or published)
- AC-010-02: Bulk generation for 500 students completes via background job
- AC-010-03: Custom template saves field layout as JSON and renders correctly on PDF
- AC-010-04: CBSE template correctly formats FA+SA CCE components

---

### FR-EXA-011: CCE — Continuous & Comprehensive Evaluation
**RBS Reference:** I1, I5 | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `exa_cce_configs`, `exa_cce_assessments`

**Description:** Configuration and management of CBSE-aligned Continuous and Comprehensive Evaluation. CCE divides a year into two terms (Term 1, Term 2), each with two Formative Assessments (FA1/FA2) and one Summative Assessment (SA). FA includes oral tests, class tests, projects, and portfolio assessments. Configured weightage (FA: 40%, SA: 60%) determines the final grade. EXA's CCE layer plugs formative assessment scores into the overall grade calculation.

**Actors:** Admin (configure), Subject Teacher (enter FA scores)
**Input:**
- Config: `academic_session_id`, `term` (Term1/Term2), `fa_weightage_percent`, `sa_weightage_percent`, `fa_count` (default 2)
- FA assessment: `student_id`, `subject_id`, `assessment_type` (oral/classtest/project/portfolio), `marks_obtained`, `max_marks`, `assessment_date`

**Processing:**
- `combined_fa_average = average(fa1, fa2) * fa_weightage / 100`
- `sa_contribution = sa_marks_percentage * sa_weightage / 100`
- `term_grade_percent = combined_fa_average + sa_contribution`
- Final year grade = average of Term1 + Term2 grade percentages

**Output:** CCE grade sheet per student, feeds into `exa_results` for report card

**Acceptance Criteria:**
- AC-011-01: FA weightage + SA weightage must equal 100% per term config
- AC-011-02: Missing FA scores default to 0 with warning flag
- AC-011-03: CCE final grade integrated into report card when exam type has `is_ccce_applicable = 1`

---

### FR-EXA-012: Promotion & Detention Processing
**RBS Reference:** I7 (Promotion & Detention Rules) | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `exa_promotion_rules`, `exa_promotion_lists`

**Description:** End-of-year promotion and detention processing. The school configures promotion rules (minimum percentage, minimum grade, mandatory subject pass requirements). The system generates a promotion list classifying each student as PROMOTED, DETAINED, or COMPARTMENT. Detained students trigger parent notification. Promoted students can be batch-updated to the next class-section in the Student module.

**Actors:** Admin / Principal
**Input:**
- Rules: `academic_session_id`, `class_id`, `min_percentage` DECIMAL(5,2), `mandatory_pass_subjects_json` JSON, `max_allowed_compartment`
- Promotion decision: override individual student status with reason

**Processing:**
- Apply rules to final `exa_results` where `exam_type.exam_category = annual` or designated annual exam
- Auto-classify: PROMOTED if all rules pass, DETAINED if fail criteria met, COMPARTMENT if borderline
- Notification trigger: DETAINED status fires notification to parent via Notification module
- Promoted students list exported for Student module class promotion workflow

**Output:** Promotion list per class, detained student notification queue

**Acceptance Criteria:**
- AC-012-01: Promotion rules are configurable per class (different criteria for Class 10 vs Class 5)
- AC-012-02: Manual override by Principal is logged with reason and overrider identity
- AC-012-03: Compartment students can be promoted after clearing compartment exam
- AC-012-04: Promotion list integrates with Student module for class-section advancement

---

### FR-EXA-013: Result Publishing
**RBS Reference:** I6 (Publishing, F.I6.2) | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `exa_exams` (status field), `exa_report_cards` (is_published)

**Description:** Controlled publishing of results and report cards to the student/parent portal. Publishing is a deliberate, gated action — the Admin reviews results before making them visible. Once published, students and parents can view marks, grade, rank, and download their report card PDF. Unpublishing is permitted before portal access begins.

**Actors:** Admin / Principal
**Input:** `exam_id`, publish action (publish/unpublish), `publish_date` (scheduled publishing)
**Processing:**
- On publish: `exa_exams.status = published`, `exa_report_cards.is_published = 1`
- If `publish_date` is in future: schedule via Laravel scheduler
- Trigger notification to all students/parents in the affected class-sections
- Portal visibility controlled by `is_published` flag on `exa_report_cards`

**Output:** Portal-visible results, download access for students/parents

**Acceptance Criteria:**
- AC-013-01: Unpublished results are not visible to students/parents even if portal is active
- AC-013-02: Scheduled publishing fires within ±5 minutes of configured time
- AC-013-03: Notification sent to all students + registered parent accounts on publish

---

### FR-EXA-014: AI-Based Examination Analytics
**RBS Reference:** I10 (AI-Based Examination Analytics) | **Priority:** Medium | **Status:** 📐 Proposed
**Tables:** `exa_performance_analytics`, `exa_ai_alerts`

**Description:** Rule-based (and optionally ML-backed) analytics engine providing actionable insights from examination results. Identifies subject-wise weak areas per student, class-level underperforming topics (cross-referenced with syllabus), and generates predictive risk alerts for students likely to fail next term. Feeds into the Recommendation module to auto-trigger remedial content recommendations.

**Actors:** System (automated), Teacher (views dashboard)
**Input:** `exa_results`, `exa_result_subjects`, `exa_mark_entries` (historical), syllabus mapping
**Processing:**
- Weak area: student scores below class average in a subject for 2+ consecutive exams → flag
- Skill gap: match underperforming topics to `slb_topics` taxonomy
- Predictive alert: if student's trajectory (last 3 exams) shows declining trend → risk score MEDIUM/HIGH
- Class-level insight: subjects with > 30% failure rate → flag for teacher action
- Emit recommendation trigger event to Recommendation module

**Output:** Analytics dashboard, per-student insights panel, alert notification to teachers

**Acceptance Criteria:**
- AC-014-01: Analytics engine runs automatically after result processing completes
- AC-014-02: Predictive alerts reach teachers via notification within 1 hour of result processing
- AC-014-03: Weak area identification correctly requires ≥ 2 consecutive exam data points

---

## 5. Proposed Database Tables

### 5.1 Exam Structure Tables

**`exa_exam_types`** — Master exam type definitions

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `name` | VARCHAR(100) NOT NULL | e.g., Unit Test 1, Half Yearly, Annual |
| `code` | VARCHAR(20) NOT NULL UNIQUE | e.g., UT1, HY, ANNUAL, FA1, SA2 |
| `exam_category` | ENUM('formative','summative','annual','board') NOT NULL | |
| `weightage_percent` | DECIMAL(5,2) NOT NULL DEFAULT 0 | percentage weight in cumulative result |
| `is_ccce_applicable` | TINYINT(1) NOT NULL DEFAULT 0 | CCE mode flag |
| `description` | TEXT NULL | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |

**`exa_exam_components`** — Theory/Practical/Internal breakdowns per exam type

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
| `name` | VARCHAR(150) NOT NULL | e.g., "Half Yearly Exam 2025-26 — Batch A" |
| `from_date` | DATE NOT NULL | |
| `to_date` | DATE NOT NULL | |
| `status` | ENUM('draft','scheduled','ongoing','completed','published') NOT NULL DEFAULT 'draft' | |
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

**`exa_invigilators_jnt`** — Staff invigilator assignments per exam subject slot

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

**`exa_seating_arrangements`** — Per-student seat assignments in exam halls

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
| `file_path` | VARCHAR(500) NULL | stored via sys_media |
| `media_id` | BIGINT UNSIGNED NULL FK→sys_media | |
| `is_published` | TINYINT(1) NOT NULL DEFAULT 0 | portal visibility |
| `generated_at` | TIMESTAMP NULL | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

### 5.4 Mark Entry & Moderation Tables

**`exa_mark_entries`** — Per-student per-subject mark records

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `exam_subject_id` | BIGINT UNSIGNED NOT NULL FK→exa_exam_subjects | |
| `student_id` | BIGINT UNSIGNED NOT NULL FK→std_students | |
| `is_absent` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `theory_marks` | DECIMAL(5,2) NOT NULL DEFAULT 0 | |
| `practical_marks` | DECIMAL(5,2) NOT NULL DEFAULT 0 | |
| `internal_marks` | DECIMAL(5,2) NOT NULL DEFAULT 0 | |
| `grace_marks` | DECIMAL(4,2) NOT NULL DEFAULT 0 | |
| `marks_obtained` | DECIMAL(5,2) GENERATED AS (theory_marks + practical_marks + internal_marks + grace_marks) STORED | |
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
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

### 5.5 Gradebook & Result Tables

**`exa_grade_scales`** — Grade scale master (one scale = one system like CBSE GPA or ICSE %)

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `name` | VARCHAR(100) NOT NULL | e.g., "CBSE 10-Point GPA Scale" |
| `code` | VARCHAR(20) NOT NULL UNIQUE | |
| `scale_type` | ENUM('percentage','letter_grade','gpa','ccce') NOT NULL | |
| `is_default` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |

**`exa_grade_scale_bands`** — Individual grade bands within a scale

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `grade_scale_id` | BIGINT UNSIGNED NOT NULL FK→exa_grade_scales | |
| `min_percent` | DECIMAL(5,2) NOT NULL | |
| `max_percent` | DECIMAL(5,2) NOT NULL | |
| `grade_letter` | VARCHAR(5) NOT NULL | e.g., A1, B2, C, F |
| `grade_point` | DECIMAL(3,1) NOT NULL DEFAULT 0 | e.g., 10.0, 9.0, 8.0 |
| `description` | VARCHAR(100) NULL | e.g., Outstanding, Excellent, Very Good |
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

**`exa_result_subjects`** — Per-subject result breakdown per student per exam

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
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

### 5.6 Report Card Tables

**`exa_report_configs`** — Configuration for report card generation per exam

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `exam_id` | BIGINT UNSIGNED NOT NULL FK→exa_exams | |
| `template_type` | ENUM('standard','cbse','icse','ib','cambridge','custom') NOT NULL DEFAULT 'standard' | |
| `show_rank` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `show_attendance` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `show_remarks` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `show_photo` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `language_code_primary` | VARCHAR(10) NOT NULL DEFAULT 'en' | |
| `language_code_secondary` | VARCHAR(10) NULL | |
| `header_text_json` | JSON NULL | school-specific header fields |
| `footer_text` | TEXT NULL | |
| `custom_layout_json` | JSON NULL | drag-drop template layout |
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
| `file_path` | VARCHAR(500) NULL | |
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

---

### 5.7 CCE & Promotion Tables

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

**`exa_cce_assessments`** — Individual formative assessment score records

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `cce_config_id` | BIGINT UNSIGNED NOT NULL FK→exa_cce_configs | |
| `student_id` | BIGINT UNSIGNED NOT NULL FK→std_students | |
| `subject_id` | BIGINT UNSIGNED NOT NULL FK→sch_subjects | |
| `assessment_type` | ENUM('oral','classtest','project','portfolio','assignment') NOT NULL | |
| `fa_sequence` | TINYINT UNSIGNED NOT NULL | 1 = FA1, 2 = FA2 |
| `marks_obtained` | DECIMAL(5,2) NOT NULL | |
| `max_marks` | DECIMAL(5,2) NOT NULL | |
| `assessment_date` | DATE NOT NULL | |
| `entered_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**`exa_promotion_rules`** — Configurable promotion criteria per class

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `academic_session_id` | BIGINT UNSIGNED NOT NULL FK→sch_academic_sessions | |
| `class_id` | BIGINT UNSIGNED NOT NULL FK→sch_classes | |
| `min_percentage` | DECIMAL(5,2) NOT NULL DEFAULT 33 | |
| `mandatory_pass_subjects_json` | JSON NULL | array of subject_ids that must be passed |
| `max_allowed_compartment` | TINYINT UNSIGNED NOT NULL DEFAULT 1 | |
| `min_attendance_percent` | DECIMAL(5,2) NULL | if NULL, attendance not considered |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**`exa_promotion_lists`** — Generated promotion decision per student

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

## 6. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| NFR-EXA-001 | Performance | Result processing for a class of 500 students across 12 subjects must complete within 30 seconds |
| NFR-EXA-002 | Performance | Bulk admit card or report card generation (500 PDFs) must complete as background job within 5 minutes |
| NFR-EXA-003 | Performance | Mark entry grid for 60 students should load within 2 seconds |
| NFR-EXA-004 | Security | Mark entry is restricted to assigned subject teachers; cross-subject entry blocked by Gate policy |
| NFR-EXA-005 | Security | Result data is tenant-isolated; stancl/tenancy prevents cross-school data access |
| NFR-EXA-006 | Security | Published results accessible to students/parents only after exam status = published |
| NFR-EXA-007 | Reliability | Bulk job failure does not corrupt partial results — transactional processing |
| NFR-EXA-008 | Scalability | Module supports up to 5,000 students per tenant across 200 class-sections |
| NFR-EXA-009 | Audit | All mark entry, moderation, and promotion decisions logged to `sys_activity_logs` |
| NFR-EXA-010 | Localization | Report cards support UTF-8 regional language characters (Hindi, Tamil, Telugu, etc.) |

---

## 7. Integration Points

| Module | Integration | Direction |
|---|---|---|
| SchoolSetup (`sch_*`) | Classes, sections, subjects, halls, academic sessions | EXA reads |
| StudentProfile (`std_*`) | Student roster, photos, class-section enrollment | EXA reads |
| LmsExam (`exm_*`) | Optional: online exam marks can be imported into EXA mark entry | EXA reads |
| Timetable (`tt_*`) | Conflict detection: student class timetable vs exam slot | EXA reads |
| Attendance | Attendance summary for report card | EXA reads |
| Notification | Detention alerts, result-published alerts, compartment notices | EXA writes |
| Recommendation | Weak-area signal → trigger remedial content recommendation | EXA writes |
| StudentPortal | Admit card, result, report card visibility | EXA writes |
| sys_media | PDF storage for admit cards, report cards | EXA writes |
| sys_activity_logs | Audit trail for all mark entry and moderation actions | EXA writes |

---

## 8. User Interface Requirements

### 8.1 Exam Dashboard
- Cards: Upcoming Exams, Marks Pending, Results Processed, Report Cards Generated
- Quick-action buttons: Schedule Exam, Enter Marks, Generate Report Cards
- Status board per exam: progress bar for marks entry completion per class

### 8.2 Exam Timetable View
- Calendar-style view showing all exam subject slots for the current exam
- Per-slot card: subject name, class-section, date/time, hall, invigilator
- Conflict indicators (red badge) on conflicted slots

### 8.3 Mark Entry Grid
- Inline editable grid: rows = students, columns = theory/practical/internal/grace/absent
- Green/orange/red row highlight based on marks status (entered/not entered/absent)
- Bulk save button with real-time validation feedback
- Excel download template + upload button

### 8.4 Seating Arrangement View
- Visual hall layout with seat grid
- Student name overlaid on assigned seat
- Drag-drop for manual reassignment
- Print/PDF button for seating chart

### 8.5 Report Card Preview
- Live preview of report card PDF in-browser before bulk generation
- Template selector dropdown
- Toggle switches: show/hide rank, attendance, photo, remarks

---

## 9. Examination Lifecycle Workflow

```
[Setup Phase]
Configure Exam Types → Configure Grade Scales → Define CCE Config (if applicable)

[Exam Creation Phase]
Create Exam Event (draft) → Add Subject Slots → Assign Invigilators → Conflict Check
    → Exam Status: scheduled

[Pre-Exam Phase]
Generate Seating Arrangements → Generate Admit Cards → Publish Admit Cards to Portal
    → Exam Status: ongoing

[During/After Exam Phase]
Subject Teachers Enter Marks (draft → entered) → HOD Verifies Marks (entered → verified)
    → (optional) Moderation Proposed → Principal Approves Moderation
    → All subjects verified → Exam Status: completed

[Result Processing Phase]
Trigger Result Processing Job → Calculate Total/Percentage/Grade/Rank → CCE Combined
    → Generate Class/Section Rank Lists → Process Promotion/Detention Rules
    → Review Results → Exam Status: processed

[Publishing Phase]
Generate Report Cards (batch job) → Review Report Cards → Set Publish Date
    → Publish → Exam Status: published
    → Notification to Students/Parents → Portal Access Open
```

**CCE Overlay (for formative exams):**
```
FA1 Assessment Entry → FA2 Assessment Entry → SA Exam (→ above workflow)
    → Combined CCE Grade Calculation → CCE Report Card
```

---

## 10. Validation Rules

| Field | Rule |
|---|---|
| `exa_exam_types.code` | UNIQUE, VARCHAR 20, uppercase recommended |
| `exa_exam_types.weightage_percent` | 0–100 DECIMAL, session total ≤ 100 |
| `exa_exams.from_date` | Must be within `academic_session.from_date` and `to_date` |
| `exa_exam_subjects.pass_marks` | Must be ≤ `max_marks` |
| `exa_exam_subjects.theory_max + practical_max + internal_max` | Must equal `max_marks` |
| `exa_mark_entries.theory_marks` | ≥ 0 and ≤ `exam_subject.theory_max` |
| `exa_mark_entries` absent constraint | `is_absent = 1` → theory_marks/practical_marks/internal_marks = 0 |
| `exa_grade_scale_bands` | Non-overlapping ranges within scale; collectively cover 0–100 |
| `exa_cce_configs.fa_weightage_percent + sa_weightage_percent` | Must equal 100 |
| `exa_promotion_rules.min_percentage` | 0–100 DECIMAL |

---

## 11. Security & Permissions

| Permission | Description |
|---|---|
| `exa.exam_type.manage` | Create/edit/delete exam types |
| `exa.exam.create` | Create and schedule exam events |
| `exa.exam.manage` | Edit existing exams, add subject slots |
| `exa.seating.manage` | Generate and edit seating arrangements |
| `exa.admit_card.generate` | Generate admit cards |
| `exa.admit_card.publish` | Publish admit cards to portal |
| `exa.marks.enter` | Enter marks for assigned subjects |
| `exa.marks.verify` | Verify marks (HOD level) |
| `exa.moderation.propose` | Propose marks moderation |
| `exa.moderation.approve` | Approve/reject moderation (Principal) |
| `exa.result.process` | Trigger result processing |
| `exa.result.publish` | Publish results to portal |
| `exa.report_card.generate` | Generate report cards |
| `exa.report_card.publish` | Publish report cards to portal |
| `exa.promotion.process` | Run promotion/detention processing |
| `exa.grade_scale.manage` | Configure grade scales and bands |
| `exa.analytics.view` | View performance analytics and AI alerts |

**Gate Rules:**
- A subject teacher can only enter marks for subjects assigned to them in `sch_staff_subject_assignments`
- Students and parents can only view their own results (tenant + student_id scope enforced at API level)
- Moderation approval requires `exa.moderation.approve` — not delegatable to non-Principal roles

---

## 12. Reporting Requirements

| Report | Description | Filters |
|---|---|---|
| Marks Ledger | Subject-wise marks for all students in a class-section | Exam, Class, Section, Subject |
| Class Result Summary | Pass/fail counts, average percentage, top 3 students | Exam, Class |
| Rank List | Students ordered by rank with marks and grade | Exam, Class / Section |
| Compartment List | Students in compartment status with failed subjects | Exam, Class |
| Detention List | Students detained with reason | Exam, Class |
| Subject Performance | Average marks per subject vs class average | Exam, Class |
| Comparative Analysis | Exam-over-exam trend per class/subject | Class, Date Range |
| CCE Progress Report | FA1/FA2/SA breakdown per student per term | Student, Term |
| Grade Distribution | Bar chart: how many students per grade band | Exam, Class |
| AI Alert Summary | Students with predicted risk or identified weak areas | Class, Exam |

---

## 13. Development Phases & Priority

| Phase | FRs | Priority | Estimated Effort |
|---|---|---|---|
| Phase 1 — Foundation | FR-EXA-001, FR-EXA-002, FR-EXA-007 | Critical | 4 weeks |
| Phase 2 — Exam Operations | FR-EXA-003, FR-EXA-004, FR-EXA-005, FR-EXA-006 | Critical | 4 weeks |
| Phase 3 — Results & Gradebook | FR-EXA-008, FR-EXA-009, FR-EXA-011 | Critical | 3 weeks |
| Phase 4 — Report Cards | FR-EXA-010, FR-EXA-013 | High | 3 weeks |
| Phase 5 — CCE & Board | FR-EXA-011, FR-EXA-012 (board templates) | High | 2 weeks |
| Phase 6 — Promotion | FR-EXA-012 | High | 2 weeks |
| Phase 7 — Analytics & AI | FR-EXA-014 | Medium | 2 weeks |
| **Total** | | | **~20 weeks** |

---

## 14. Open Questions & Decisions Required

| ID | Question | Stakeholder | Impact |
|---|---|---|---|
| OQ-EXA-001 | Should EXA mark entry allow importing marks directly from LmsExam online exam results? | Product Owner | Architecture — lms_exam_marks_entry FK linkage |
| OQ-EXA-002 | Single grade scale per school or per class or per exam type? Recommendation: per exam type with school default | Academic Head | Grade scale assignment model |
| OQ-EXA-003 | Should seating arrangement support cross-class hall sharing (different classes in same hall)? | Exam Controller | Seating algorithm complexity |
| OQ-EXA-004 | CCE: does the school run full CBSE CCE (FA+SA) or simplified in-house formative tracking? | Principal | CCE config complexity |
| OQ-EXA-005 | Custom report card designer: full WYSIWYG (complex) or predefined field-slot template (simpler)? | Product Owner | Development scope |
| OQ-EXA-006 | Board report card (CBSE/ICSE): export to government portal format or PDF only? | Compliance | Integration with CBSE portal |
| OQ-EXA-007 | Promotion decision: should EXA directly update student class/section in Student module or merely generate a list for manual action? | Product Owner | Cross-module write authorization |

---

## 15. Appendix — RBS Traceability Matrix

| RBS Feature | RBS Sub-tasks | FR Coverage |
|---|---|---|
| F.I1.1 — Exam Types | ST.I1.1.1.1, ST.I1.1.1.2 | FR-EXA-001 |
| F.I1.2 — Weightage & Scheme | ST.I1.2.1.1, ST.I1.2.1.2 | FR-EXA-001, FR-EXA-007 |
| F.I2.1 — Timetable Setup | ST.I2.1.1.1, ST.I2.1.1.2 | FR-EXA-002, FR-EXA-003 |
| F.I2.1 — Conflict Checking | ST.I2.1.2.1, ST.I2.1.2.2 | FR-EXA-002 |
| F.I3.1 — Marks Entry | ST.I3.1.1.1, ST.I3.1.1.2, ST.I3.1.2.1, ST.I3.1.2.2 | FR-EXA-005 |
| F.I3.2 — Marks Verification | ST.I3.2.1.1, ST.I3.2.1.2 | FR-EXA-005 |
| F.I4.1 — Moderation Review | ST.I4.1.1.1, ST.I4.1.1.2, ST.I4.1.2.1, ST.I4.1.2.2 | FR-EXA-006 |
| F.I5.1 — Grade Calculation | ST.I5.1.1.1, ST.I5.1.1.2, ST.I5.1.2.1, ST.I5.1.2.2 | FR-EXA-007, FR-EXA-008 |
| F.I6.1 — Report Generation | ST.I6.1.1.1, ST.I6.1.1.2, ST.I6.1.2.1, ST.I6.1.2.2 | FR-EXA-010 |
| F.I6.2 — Publishing | ST.I6.2.1.1, ST.I6.2.1.2 | FR-EXA-013 |
| F.I7.1 — Promotion Processing | ST.I7.1.1.1, ST.I7.1.1.2 | FR-EXA-012 |
| F.I7.2 — Detention Workflow | ST.I7.2.1.1, ST.I7.2.1.2 | FR-EXA-012 |
| F.I8.1 — Board Templates | ST.I8.1.1.1, ST.I8.1.1.2 | FR-EXA-010 |
| F.I8.2 — Board Mapping | ST.I8.2.1.1, ST.I8.2.1.2 | FR-EXA-010 |
| F.I9.1 — Template Designer | ST.I9.1.1.1, ST.I9.1.1.2, ST.I9.1.2.1, ST.I9.1.2.2 | FR-EXA-010 |
| F.I10.1 — Performance Insights | ST.I10.1.1.1, ST.I10.1.1.2, ST.I10.1.2.1, ST.I10.1.2.2 | FR-EXA-014 |
| Admit Card (derived) | — | FR-EXA-004 |
| CCE (derived from I1+I5) | — | FR-EXA-011 |
| Rank/Merit List (derived from I5) | — | FR-EXA-009 |
