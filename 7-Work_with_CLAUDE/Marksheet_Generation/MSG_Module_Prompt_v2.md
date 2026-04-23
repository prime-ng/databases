# MSG — Marksheet Generation Module Development Lifecycle Prompt (v2)

**Purpose:** Consolidated prompt to build 4 output files for the **MSG (MarksheetGeneration)** module. Aggregates marks from LmsHomework, LmsQuiz, LmsQuest, LmsExam, and BehaviouralAssessment into configurable school marksheets aligned with Indian K-12 board requirements (CBSE / ICSE / State Boards). Execute phases sequentially; Claude **STOPS** after each phase for your review and approval before proceeding.

**Output Files:**
1. `MSG_RequirementSpec.md` — Detailed Requirement Specification Document
2. `MSG_DDL_v1.sql` + `MSG_DataDictionary.md` — Database Schema + Data Dictionary
3. `MSG_Dev_Plan.md` — Complete Development Plan

**Developer:** Brijesh
**v2 Changes from v1:**
- Fixed: Online/Offline is per-paper (`lms_exam_papers.mode`), NOT per-exam-type — removed incorrect `lms_exam_types.type` assumption
- Fixed: `is_absent` is on `lms_exam_attempts.status` / `lms_exam_results.result_status`, NOT on `lms_exam_marks_entry`
- Fixed: Removed incorrect split of Online/Offline Exam as separate source components — both feed `lms_exam_results`
- Fixed: Corrected StudentAttempts DDL path to `StudentAttempt_ddl_v3.sql`
- Added: Subject-wise result breakdown (per-subject, per-exam matrix — core of Indian marksheets)
- Added: CBSE / ICSE / State Board format compliance
- Added: Internal Assessment (IA) marks concept (periodic test, notebook, enrichment, participation)
- Added: Exam Term grouping (Term-1, Term-2) with term-level marksheet generation
- Added: Elective subject handling (not all students in a class take the same subjects)
- Added: Grading schema integration (`slb_grade_division_master`)
- Added: Attendance data on marksheet (working days, days present)
- Added: Rank, Division, and Promotion status computation
- Added: Co-Scholastic / Co-Curricular marks section (linked to BehaviouralAssessment + optional extras)
- Added: Explicit score column references from actual DDLs (no more "identify from DDL")
- Added: Validation instruction — Claude must verify every column reference against DDL before using

---

## DEFAULT PATHS

Read `{AI_BRAIN}/config/paths.md` — resolve all path variables from this file.

## Rules
- All paths come from `paths.md` unless overridden in CONFIGURATION below.
- If a variable exists in both `paths.md` and CONFIGURATION, the CONFIGURATION value wins.
- **NEVER use `tenant_id` columns** — this is a dedicated-database-per-tenant system (stancl/tenancy v3.9).
- **NEVER use ENUMs** — use `sys_dropdown_table` or a dedicated lookup table instead.
- Follow table naming conventions: prefix `msh_*`, junction tables suffixed `_jnt`, JSON columns suffixed `_json`, boolean columns prefixed `is_` or `has_`.
- Every table MUST include: `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`.
- **VALIDATION RULE:** Before referencing any column from a source module table, confirm the column exists in the DDL. If it doesn't exist, flag it as a pre-development verification item.

---

## Repositories

```
DB_REPO        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
OLD_REPO       = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db
AI_BRAIN       = {OLD_REPO}/AI_Brain
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
LARAVEL_CLAUDE = {LARAVEL_REPO}/.claude/rules
```

## CONFIGURATION

```
MODULE_CODE       = MSG
MODULE            = MarksheetGeneration
MODULE_DIR        = Modules/MarksheetGeneration/
BRANCH            = Brijesh_Main
RBS_MODULE_CODE   = T                              # Tenant module
DB_TABLE_PREFIX   = msh_                            # Single prefix
DATABASE_NAME     = tenant_db

OUTPUT_DIR        = {OLD_REPO}/1-DDL_Tenant_Modules/55h-MarksheetGeneration
MIGRATION_DIR     = {LARAVEL_REPO}/database/migrations/tenant
TENANT_DDL        = {DB_REPO}/1-Master_DDLs/tenant_db_v2.sql

# Source Module DDLs (READ ONLY — never modify these)
DDL_HOMEWORK      = {OLD_REPO}/1-DDL_Tenant_Modules/52a-LMS_Homework/DDL/LMS_Homework_DDL_v4.sql
DDL_QUIZ          = {OLD_REPO}/1-DDL_Tenant_Modules/53b-LMS_Quiz/DDL/LMS_Quiz_ddl_v2.sql
DDL_QUEST         = {OLD_REPO}/1-DDL_Tenant_Modules/54c-LMS_Quest/DDL/LMS_Quest_ddl_v2.sql
DDL_EXAM          = {OLD_REPO}/1-DDL_Tenant_Modules/55d-LMS_Exam/DDL/LMS_Exam_ddl_v5.sql
DDL_ATTEMPTS      = {OLD_REPO}/1-DDL_Tenant_Modules/55e-LMS_StudentAttempts/DDL/StudentAttempt_ddl_v3.sql
DDL_BA            = {OLD_REPO}/1-DDL_Tenant_Modules/55g-BehaviouralAssessment/DDL/BA_DDL_v2.sql

# Output Files
REQUIREMENT_FILE  = MSG_RequirementSpec.md
DDL_FILE_NAME     = MSG_DDL_v1.sql
DICT_FILE_NAME    = MSG_DataDictionary.md
DEV_PLAN_FILE     = MSG_Dev_Plan.md
```

---

## HOW TO USE THIS PROMPT

1. Paste this entire document into a new Claude conversation
2. Say: **"Start Phase 1"**
3. Claude reads required files, generates output, and **STOPS**
4. Review the output; give feedback or say: **"Approved. Proceed to Phase 2"**
5. Repeat for Phases 2 and 3

---

## KEY CONTEXT — MSG (MARKSHEET GENERATION) MODULE

### What This Module Does

MarksheetGeneration is the **school result aggregation, marksheet configuration, and report card generation engine** for Prime-AI. It is a single Laravel module (`Modules\MarksheetGeneration`) that enables Indian K-12 schools to:

- Define which assessment sources contribute to student marksheets
- Configure weightage per source, per exam, per class/class-group, and per subject
- Support multiple marksheet types per academic session (per-exam / term-end / annual)
- Handle the full CBSE / ICSE / State Board marksheet structure (Scholastic + Co-Scholastic areas)
- Include practical exam marks where applicable (theory-practical split per subject)
- Include Internal Assessment marks (periodic tests, notebook, subject enrichment, participation)
- Include Behavioural Assessment scores in the Co-Scholastic section
- Handle elective subjects (not all students in a class take the same subjects)
- Compute grades, rank, division, and promotion status
- Generate PDF marksheets via DomPDF

### Understanding the Indian K-12 Marksheet Structure

> **CRITICAL CONTEXT** — This module must support the standard Indian board marksheet format. Most Indian schools follow CBSE or ICSE patterns:

**CBSE Pattern (Classes 1-12):**
```
PART A — SCHOLASTIC AREAS
  Subject  | Per.Test-1 | Per.Test-2 | Half Yearly | Notebook | Sub.Enrichment | Total (out of 100)
  Math          10           10           80            5           5               100
  Science       10           10           80            5           5               100
  ...

  Theory marks + Practical marks (for subjects like Science, Computer) shown separately
  Grade: A1(91-100), A2(81-90), B1(71-80), B2(61-70), C1(51-60), C2(41-50), D(33-40), E(below 33)

PART B — CO-SCHOLASTIC AREAS
  Work Education                          A / B / C
  Art Education                           A / B / C
  Health & Physical Education             A / B / C

PART C — DISCIPLINE (replaced by BehaviouralAssessment in our system)
  Discipline Grade                        A / B / C

Attendance: Working Days: ___, Days Present: ___
Promotion Status: Promoted to Class ___ / Detained / Placed
```

**Key patterns a school may configure:**
- Different **exam structures per class group** (Primary = no periodic tests, Middle = 2 PTs + 1 HY + 1 Annual, Secondary = CBSE pattern with IA)
- **Term-wise marksheet** (Term-1 covers July-Nov, Term-2 covers Dec-March) OR **Annual marksheet** covering full year
- **Subjects vary by student** (electives in Classes 9-12: e.g., some take Computer Science, others take IT)
- **Practical marks** only for certain subjects (Science, Computer Science, Physical Education)
- **Internal Assessment** components vary by board and class level

### Source Modules (READ FROM, NEVER MODIFY)

| Module | Key Tables | Score Columns (verified from DDL) | What It Provides |
|---|---|---|---|
| **LmsHomework** | `lms_homework`, `lms_homework_submissions` | `lms_homework_submissions.marks_obtained` (DECIMAL 5,2), `lms_homework.max_marks` (DECIMAL 5,2) | Homework scores per student per subject |
| **LmsQuiz** | `lms_quizzes`, `lms_quiz_quest_results` | `lms_quiz_quest_results.total_marks_obtained`, `.max_marks`, `.percentage` (all DECIMAL) | Quiz scores per student |
| **LmsQuest** | `lms_quests`, `lms_quiz_quest_results` | Same table as Quiz — `assessment_type = 'QUEST'` discriminates | Quest scores per student |
| **LmsExam** | `lms_exams`, `lms_exam_papers`, `lms_exam_results` | `lms_exam_results.total_marks_obtained`, `.total_marks_possible`, `.percentage`, `.grade_obtained`, `.result_status` | Exam results per student per paper (both Online and Offline) |
| **BehaviouralAssessment** | `ba_computed_scores`, `ba_config` | Via `BehaviouralScoreService::getStudentScore()` → `{ numeric_score, grade, category_scores[] }` | Behavioural scores for Co-Scholastic section |

> **CRITICAL:** This module NEVER writes to any `lms_*` or `ba_*` table. All reads are read-only.

### Architecture Correction — Online vs Offline Exams

> **v1 ERROR FIXED:** The v1 prompt incorrectly assumed `lms_exam_types.type` distinguishes Online from Offline. In reality:
>
> - `lms_exam_types` stores exam categories: UT-1, UT-2, UT-3, UT-4, Half Yearly, Annual, etc.
> - **Online vs Offline is per-paper:** `lms_exam_papers.mode = ENUM('ONLINE', 'OFFLINE')`
> - A single exam (e.g., UT-1 for Class 9) can have papers with different modes (Math Online, Hindi Offline)
> - **Both modes produce results in `lms_exam_results`** — the mode is transparent at the marksheet level
> - For marksheet purposes, we read from `lms_exam_results` regardless of paper mode
> - `lms_exam_marks_entry` is intermediate (bulk offline marks entry) — final results always land in `lms_exam_results`

### Architecture Correction — Absent Flag

> **v1 ERROR FIXED:** `is_absent` is NOT on `lms_exam_marks_entry`. The correct locations are:
> - `lms_exam_attempts.status = 'ABSENT'`
> - `lms_exam_attempts.is_present_offline` (TINYINT, for offline exams)
> - `lms_exam_results.result_status = 'ABSENT'`

### Proposed Table Architecture

```
CONFIGURATION TABLES (School Admin sets these up):
  msh_marksheet_types          — e.g. "Unit Test Result", "Term-1 Report", "Annual Report Card"
  msh_exam_groups              — Groups multiple exams into a marksheet (e.g. "Term-1" = UT1 + UT2 + Half Yearly)
  msh_exam_group_items_jnt     — Junction: which lms_exams belong to which exam group
  msh_config_templates         — Reusable marksheet configuration blueprint per academic session
  msh_template_scholastic_components  — Scholastic source weightage (Exam, Homework, Quiz, Quest) per template
  msh_template_exam_weightages — Per-exam weightage within the Exam component (UT1=10%, UT2=10%, HY=80%)
  msh_template_ia_components   — Internal Assessment component definitions (Notebook, Sub.Enrichment, etc.)
  msh_template_coscholastic_components — Co-Scholastic components (Work Ed, Art Ed, Health & PE, Behaviour)
  msh_class_config_jnt         — Assigns a template to class or class-group
  msh_subject_practical_configs — Theory-Practical split per subject for classes that have practicals
  msh_grading_configs          — Grading schema link per template (A1, A2, B1... or A, B, C, D)

SCHEDULE & GENERATION TABLES:
  msh_marksheet_schedules      — Defines a marksheet generation event (type, session, date range, exam group)
  msh_schedule_class_jnt       — Which class-sections are included in this schedule

RESULT TABLES (System computes and stores):
  msh_student_results          — One row per student per schedule (total, grade, rank, division, promotion)
  msh_student_subject_results  — Per-subject breakdown (theory, practical, IA, total, grade) per student per schedule
  msh_student_subject_exam_marks — Per-exam marks per subject per student (the raw matrix: UT1, UT2, HY, etc.)
  msh_student_coscholastic_results — Co-Scholastic grades per student per schedule (Work Ed, Art, Health, Behaviour)
  msh_student_attendance       — Attendance summary per student per schedule (working days, days present)

AUDIT:
  msh_computation_logs         — Log of each computation run (who triggered, duration, status, error)
```

### Business Rules Summary

1. **Marksheet = Scholastic + Co-Scholastic + Attendance** — follows standard Indian board pattern
2. **Per-exam weightage**: Within the Exam component, each exam (UT1, UT2, HY, Annual) gets configurable weightage. E.g., CBSE Class 10: Periodic Test-1=10%, Periodic Test-2=10%, Half Yearly/Annual=80%
3. **Exam grouping**: Exams are grouped into exam groups for marksheet purposes. A "Term-1" marksheet includes UT1 + UT2 + Half Yearly. An "Annual" marksheet may include ALL exams
4. **Internal Assessment (IA)**: Schools can define IA components (Notebook=5, Subject Enrichment=5, etc.) that contribute to the final subject score alongside exam marks
5. **Homework / Quiz / Quest contribute as IA or as separate components** — school configures whether homework scores feed into the IA "Periodic Assessment" sub-component or are a separate weighted component
6. **Subject-wise results are mandatory** — marksheet MUST show per-subject, per-exam score breakdown (the matrix)
7. **Theory-Practical split**: For subjects with practicals (Science, Computer), marks shown as: Theory + Practical = Total
8. **Elective handling**: A student's subject list comes from their class-section enrollment + subject assignment. If a student doesn't take a subject, that row is blank on the marksheet, not zero
9. **Grading schema**: Configurable per template. Links to `slb_grade_division_master`. Supports CBSE 9-point scale, ICSE percentage-based, or custom
10. **Rank computation**: Rank within class/class-section based on aggregate marks. Can be disabled by school
11. **Division / Result**: First Division / Second Division / Third Division OR Pass/Fail based on school config
12. **Promotion status**: Promoted / Detained / Placed — derived from pass/fail criteria per subject + overall
13. **Absent handling**: `lms_exam_results.result_status = 'ABSENT'` → shown as "AB" on marksheet, NOT as zero
14. **Published result lock + admin unlock**: Once marksheet is published, results are frozen. Unlock requires admin + reason + audit entry
15. **BehaviouralAssessment → Co-Scholastic section**: BA scores appear in Part B/C of marksheet. Only included if BA module is configured
16. **Attendance on marksheet**: Working days and days present — sourced from Attendance module (or manually entered if attendance module is not active)
17. **Class-group inheritance**: A config template assigned to a class-group applies to all classes in the group unless a class has its own direct assignment (direct wins over inherited)
18. **Multi-tenant isolation**: All `msh_*` tables tenant-scoped (no `tenant_id`). Soft deletes on all.

---

## PHASE 1 — Requirement Specification Document

### Phase 1 Input Files

Read ALL these files in order before generating any output:

1. `{AI_BRAIN}/memory/project-context.md` — project context, tech stack, multi-tenancy rules
2. `{AI_BRAIN}/memory/modules-map.md` — existing module inventory and naming conventions
3. `{AI_BRAIN}/rules/tenancy-rules.md` — multi-tenancy rules (CRITICAL — no tenant_id column)
4. `{AI_BRAIN}/rules/module-rules.md` — module development conventions
5. `{DDL_HOMEWORK}` — read FULL DDL; note columns: `lms_homework.max_marks`, `lms_homework_submissions.marks_obtained`, `lms_homework.class_id`, `lms_homework.subject_id`, `lms_homework.academic_session_id`
6. `{DDL_QUIZ}` — read FULL DDL; note: `lms_quizzes.total_marks`, `lms_quizzes.class_id`, `lms_quizzes.subject_id`
7. `{DDL_QUEST}` — read FULL DDL; note: `lms_quests.total_marks`, `lms_quests.class_id`, `lms_quests.subject_id`
8. `{DDL_EXAM}` — read FULL DDL; critical columns:
   - `lms_exam_types.code` (UT-1, UT-2, HY-EXAM, ANNUAL-EXAM) — these are exam categories, NOT online/offline
   - `lms_exams.exam_type_id` → FK to `lms_exam_types`
   - `lms_exams.class_id`, `lms_exams.academic_session_id`
   - `lms_exam_papers.mode = ENUM('ONLINE', 'OFFLINE')` — THIS is where online/offline is determined
   - `lms_exam_papers.subject_id`, `lms_exam_papers.total_marks`
   - `lms_exams.grading_schema_id` → FK to `slb_grade_division_master`
9. `{DDL_ATTEMPTS}` — read FULL DDL; critical columns:
   - `lms_exam_results.total_marks_obtained`, `.total_marks_possible`, `.percentage`, `.grade_obtained`, `.result_status` (PASS/FAIL/ABSENT/WITHHELD)
   - `lms_exam_results.exam_paper_id` — links result to specific paper (and thus to subject)
   - `lms_exam_attempts.status` (includes 'ABSENT')
   - `lms_quiz_quest_results.total_marks_obtained`, `.max_marks`, `.percentage`, `.assessment_type` (QUIZ/QUEST)
   - `lms_exam_marks_entry.total_marks_obtained` — intermediate bulk marks (NOT the final result table)
10. `{DDL_BA}` — read `ba_computed_scores`, `ba_config`, `ba_assessment_periods`
11. `{TENANT_DDL}` — verify column names for: `sch_classes`, `sch_class_groups`, `sch_class_sections`, `sch_academic_sessions`, `std_students`, `sch_subjects`, `slb_grade_division_master`, `sys_dropdown_table`

### Phase 1 Task — Generate `MSG_RequirementSpec.md`

Generate a comprehensive Requirement Specification Document. Organise it into these sections:

---

#### Section 1 — Executive Summary
- What the MarksheetGeneration module does
- Why it is needed (current state: 5 isolated scoring modules, no consolidated result engine, no formal marksheet)
- Key stakeholders: School Admin, Principal, Academic Coordinator, Class Teacher, Subject Teacher, Student, Parent
- Integration touch-points: 5 source modules + SchoolSetup + Syllabus (grading schema)
- Indian education board context: CBSE, ICSE, State Board — marksheet format variations

#### Section 2 — Scope

**In Scope:**
- Marksheet configuration setup (template creation, component weightage, exam weightage, IA components)
- Exam grouping into marksheet terms (Term-1, Term-2, Annual)
- Class/class-group to template assignment with inheritance
- Subject practical configuration (theory-practical split per class-subject)
- Internal Assessment configuration (notebook, subject enrichment, participation, etc.)
- Co-Scholastic section configuration (Work Education, Art, Health & PE, Behavioural Assessment)
- Marksheet schedule definition (per-exam / term-end / annual)
- Subject-wise, exam-wise result computation and storage
- Grading, Rank, Division, Promotion status computation
- Attendance summary on marksheet
- Elective subject handling (per-student subject list)
- PDF marksheet generation (DomPDF, inline styles, table-based layout)
- Marksheet publication lifecycle (draft → computed → reviewed → published → locked)
- Re-generation with audit trail

**Out of Scope (explicitly state):**
- Marks entry (owned by LmsExam, LmsHomework, etc.)
- Board exam result upload / board-specific external integration
- HPC (Holistic Progress Card) module — HPC is a separate module; this module generates standard marksheets
- Fee integration, fine calculations
- Transfer Certificate generation
- Any modification to `lms_*`, `ba_*`, `sch_*`, `std_*`, `slb_*` tables

#### Section 3 — Business Requirements (25–30 BRs)

For each BR, provide:
| BR ID | Requirement | Source Module Involved | Priority (P0/P1/P2) |
|---|---|---|---|

Must cover:
- BR-MSG-001: School can select which source modules participate (Exam mandatory, others optional)
- BR-MSG-002: Per-source-component weightage (e.g., Exam=80%, Homework=5%, Quiz=5%, BA=10%)
- BR-MSG-003: Per-exam weightage within Exam component (e.g., UT1=10%, UT2=10%, HY=80%) — sum = 100%
- BR-MSG-004: Exam grouping (Term-1 = UT1+UT2+HY; Annual = ALL)
- BR-MSG-005: Class-group-level template sharing with class-level override
- BR-MSG-006: Theory-Practical split per subject (e.g., Science: Theory=70, Practical=30)
- BR-MSG-007: Internal Assessment (IA) components configurable (Notebook=5, Enrichment=5, etc.)
- BR-MSG-008: Co-Scholastic section (Work Ed, Art, Health & PE) with 3-point grading (A/B/C)
- BR-MSG-009: BehaviouralAssessment integration into Co-Scholastic (if BA module active and configured)
- BR-MSG-010: Subject-wise, exam-wise result matrix (the core marksheet table)
- BR-MSG-011: Elective subjects — student's actual subject list determines marksheet rows
- BR-MSG-012: Grading schema — configurable per template, linked to `slb_grade_division_master`
- BR-MSG-013: Rank computation (rank in class-section, optional rank in class)
- BR-MSG-014: Division computation (First/Second/Third or Pass/Fail)
- BR-MSG-015: Promotion status (Promoted/Detained/Placed) based on pass criteria
- BR-MSG-016: Absent handling — `result_status = 'ABSENT'` shown as "AB", not zero
- BR-MSG-017: Published marksheet lock + admin unlock with reason + audit
- BR-MSG-018: Homework/Quiz/Quest — scores aggregated by subject within date range
- BR-MSG-019: Attendance summary (working days, days present) — from Attendance module or manual entry
- BR-MSG-020: Multiple marksheet generations per year (after each exam / term / annual)
- BR-MSG-021: Marksheet PDF — school logo, standard board format, principal signature placeholder
- BR-MSG-022: Bulk generation (all students in a class-section in one job)
- BR-MSG-023: Withheld status — result can be withheld (fee pending, disciplinary action)
- BR-MSG-024: Supplementary/Compartment — student failing ≤2 subjects can take supplementary
- BR-MSG-025: Best-of-N option (e.g., best 2 of 4 unit tests count for exam component) — optional

#### Section 4 — Functional Requirements (25–30 FRs)

For each FR:
| FR ID | Feature Name | Screen/UI | Source Tables (READ) | Target Tables (WRITE) | Business Rules Applied |
|---|---|---|---|---|---|

Group into sub-modules:
- **FR-MSG-001 to FR-MSG-005**: Template & Scholastic Configuration (template CRUD, source components, exam weightage)
- **FR-MSG-006 to FR-MSG-009**: IA & Co-Scholastic Configuration (IA components, co-scholastic areas, grading schema)
- **FR-MSG-010 to FR-MSG-013**: Class Assignment, Practical Config, Elective Handling
- **FR-MSG-014 to FR-MSG-016**: Exam Grouping & Marksheet Schedule Management
- **FR-MSG-017 to FR-MSG-022**: Result Computation Engine (subject-wise, exam-wise matrix + aggregation)
- **FR-MSG-023 to FR-MSG-025**: Result Review, Publication, Lock/Unlock
- **FR-MSG-026 to FR-MSG-028**: Marksheet PDF Generation & Reports
- **FR-MSG-029 to FR-MSG-030**: Student Portal & Parent Portal Integration

#### Section 5 — Indian Board Marksheet Patterns

Document the 3 primary patterns this module must support:

**Pattern 1 — CBSE (Classes 9-12) — Full Scholastic + Co-Scholastic:**
```
SCHOLASTIC AREAS:
Subject | Periodic Test (20) | Half Yearly / Annual (80) | Theory Total (100) | Practical (30) | Grand Total | Grade
English    15                    65                          80                    -                80            B2
Science    18                    60                          78                    25               103 → remap   B1
...

CO-SCHOLASTIC AREAS:
Activity              | Grade
Work Education          A
Art Education           B
Health & Physical Ed    A

DISCIPLINE:
Overall Grade: A

Attendance: 220/228 days
Result: Promoted to Class XI
```

**Pattern 2 — Primary Classes (1-5) — Simplified:**
```
Subject | FA-1 (10) | FA-2 (10) | SA-1 (30) | FA-3 (10) | FA-4 (10) | SA-2 (30) | Total (100) | Grade
English    8           7           24          8           9           26          82            A2
...
(No practicals, no IA, simple grading)
```

**Pattern 3 — State Board / Custom:**
```
School may define their own structure with any combination of exams, weights, and grading schemes.
The configuration must be flexible enough to handle non-CBSE patterns.
```

#### Section 6 — Use Case Matrix

| Use Case ID | Actor | Trigger | Main Flow | Alternate Flow |
|---|---|---|---|---|

Cover at minimum 15 use cases:
- UC-MSG-001: Admin creates marksheet config template for CBSE Classes 9-10
- UC-MSG-002: Admin configures exam group "Term-1" (UT1 + UT2 + Half Yearly)
- UC-MSG-003: Admin assigns template to class group "Secondary" (Classes 9-12)
- UC-MSG-004: Admin overrides template for Class 12 (different practical subjects)
- UC-MSG-005: Admin configures practical split for Science (Theory=70, Practical=30)
- UC-MSG-006: Admin configures IA components (Notebook=5, Enrichment=5)
- UC-MSG-007: Admin creates "Term-1 Report Card" schedule linking to exam group "Term-1"
- UC-MSG-008: Admin triggers result computation for Class 9-A Term-1
- UC-MSG-009: System computes subject-wise, exam-wise matrix for each student
- UC-MSG-010: System computes grades using linked grading schema
- UC-MSG-011: System computes rank within class-section
- UC-MSG-012: System determines promotion status
- UC-MSG-013: Class teacher reviews computed results before publication
- UC-MSG-014: Admin publishes marksheet — students + parents notified
- UC-MSG-015: Admin unlocks published marksheet for re-computation (marks error found)
- UC-MSG-016: Student views own marksheet on Student Portal
- UC-MSG-017: Parent views child's marksheet on Parent Portal
- UC-MSG-018: Teacher downloads PDF marksheet for a student (with school logo + signature)

#### Section 7 — Integration Contracts (with verified column references)

For each source module, document the **exact read contract** using column names verified from DDL:

**LmsExam (PRIMARY SOURCE):**
```
Score Source:    lms_exam_results
Join Path:      lms_exam_results.exam_paper_id → lms_exam_papers.id
                lms_exam_papers.exam_id → lms_exams.id
                lms_exam_papers.subject_id → sch_subjects.id
                lms_exams.exam_type_id → lms_exam_types.id (for UT-1, HY, Annual matching)
Score Columns:  lms_exam_results.total_marks_obtained (DECIMAL 8,2)
                lms_exam_results.total_marks_possible (DECIMAL 8,2)
                lms_exam_results.percentage (DECIMAL 5,2)
                lms_exam_results.grade_obtained (VARCHAR 10)
                lms_exam_results.result_status (ENUM: PASS/FAIL/ABSENT/WITHHELD)
Paper Max:      lms_exam_papers.total_marks (DECIMAL 8,2)
Paper Mode:     lms_exam_papers.mode (ENUM: ONLINE/OFFLINE) — for info only, not separate weightage
Filter:         lms_exams.academic_session_id, lms_exams.class_id, lms_exam_papers.subject_id
Published:      lms_exam_results.is_published = 1
```

**LmsHomework:**
```
Score Source:    lms_homework_submissions
Join Path:      lms_homework_submissions.homework_id → lms_homework.id
Score Columns:  lms_homework_submissions.marks_obtained (DECIMAL 5,2)
Max Marks:      lms_homework.max_marks (DECIMAL 5,2)
Filter:         lms_homework.class_id, lms_homework.subject_id, lms_homework.academic_session_id
                lms_homework_submissions.status_id = (GRADED status from sys_dropdown_table)
Date Filter:    lms_homework.due_date BETWEEN schedule.start_date AND schedule.end_date
Aggregation:    AVG(marks_obtained / max_marks) × 100 across all graded submissions in range
```

**LmsQuiz / LmsQuest:**
```
Score Source:    lms_quiz_quest_results
Discriminator:  lms_quiz_quest_results.assessment_type = 'QUIZ' or 'QUEST'
Score Columns:  lms_quiz_quest_results.total_marks_obtained (DECIMAL 8,2)
                lms_quiz_quest_results.max_marks (DECIMAL 8,2)
                lms_quiz_quest_results.percentage (DECIMAL 5,2)
Published:      lms_quiz_quest_results.is_published = 1
Join for subject: lms_quiz_quest_results.assessment_id → lms_quizzes.id (for QUIZ)
                  lms_quiz_quest_results.assessment_id → lms_quests.id (for QUEST)
                  lms_quizzes.subject_id / lms_quests.subject_id → sch_subjects.id
Filter:         academic_session_id, class_id, subject_id from lms_quizzes / lms_quests
Aggregation:    AVG(percentage) across all published results in date range per subject
```

**BehaviouralAssessment (Co-Scholastic):**
```
API Call:       BehaviouralScoreService::getStudentScore(studentId, periodId)
Returns:        { numeric_score, grade, category_scores[] }
Pre-condition:  ba_config.is_result_integration_enabled = true
Usage:          Maps to Co-Scholastic "Discipline" section of marksheet
```

**Attendance (if Attendance module is active):**
```
Tables:         Read from attendance module tables (TBD — verify if attendance module exists)
Fallback:       If attendance module not active, allow manual entry per class-section per schedule
Columns Needed: total_working_days, days_present per student per date range
```

#### Section 8 — Screen Inventory (~15 screens)

| Screen ID | Screen Name | Actor | Key Fields / Actions |
|---|---|---|---|

- SC-MSG-01: **Marksheet Type Master** — CRUD for marksheet types (Unit Test Result, Term-1 Report, Annual Report Card)
- SC-MSG-02: **Exam Group Setup** — Create exam groups by selecting lms_exam_types to include (e.g., Term-1 = UT1+UT2+HY)
- SC-MSG-03: **Config Template Builder** — Create/edit template: add scholastic sources, set weightages, link grading schema
- SC-MSG-04: **Exam Weightage Setup** — Within a template, assign per-exam weightage (UT1=10%, UT2=10%, HY=80%)
- SC-MSG-05: **IA Component Setup** — Define Internal Assessment components (Notebook=5, Enrichment=5, etc.)
- SC-MSG-06: **Co-Scholastic Setup** — Define Co-Scholastic areas + grading (A/B/C), link BA if available
- SC-MSG-07: **Class/Class-Group Assignment** — Assign template to class or class-group, show inheritance
- SC-MSG-08: **Practical Config** — Per class-subject, set theory-practical split (Theory 70 + Practical 30 = 100)
- SC-MSG-09: **Marksheet Schedule Dashboard** — List all schedules, show status, trigger computation
- SC-MSG-10: **Marksheet Schedule Setup** — Create schedule: type, exam group, date range, class-sections
- SC-MSG-11: **Computation Progress** — Trigger computation, real-time job progress (Livewire polling)
- SC-MSG-12: **Result Review Grid** — Class-level: Student × Subject × Exam matrix with totals and grades
- SC-MSG-13: **Individual Student Marksheet Preview** — Full marksheet view (Scholastic + Co-Scholastic + Attendance)
- SC-MSG-14: **Publication & Lock** — Publish/Lock schedule, Unlock with reason
- SC-MSG-15: **Marksheet PDF Download** — Generate/download PDF (admin/teacher/student/parent views)

#### Section 9 — Non-Functional Requirements

| NFR ID | Category | Requirement | Implementation Note |
|---|---|---|---|

Cover: performance (≤60s for 500 students), bulk PDF generation, concurrency, caching, RBAC (Gate::authorize on every method), audit trail, multi-tenancy, PDF quality (DomPDF, inline styles, table layout), localisation (Hindi/English), data retention (soft delete).

#### Section 10 — Computation Algorithm (Detailed)

Document the full algorithm as pseudocode:

```
MarksheetComputationService::computeForSchedule(scheduleId):

1. Load schedule → get exam_group, config_template, class-sections
2. For each class_section in schedule:
   2a. Resolve config_template (direct class assignment → class-group inheritance → error if none)
   2b. Load students enrolled in class_section
   2c. Load subjects for class_section (including electives per student)
   2d. For each student:
       i.   For each subject assigned to this student:
            — EXAM COMPONENT:
              For each exam in exam_group:
                • Find lms_exam_results WHERE exam_paper.exam_id matches AND exam_paper.subject_id matches AND student_id matches
                • If result_status = 'ABSENT' → store "AB"
                • If result_status = 'WITHHELD' → store "WH"
                • Otherwise → store total_marks_obtained
                • If subject has practical config → split: theory paper marks + practical paper marks
                • Apply per-exam weightage
              Aggregate: weighted exam total for this subject
            
            — HOMEWORK COMPONENT (if configured):
              • Find all graded homework submissions for this student + subject within schedule date range
              • Compute average score normalized to component max marks
              • Apply homework weightage
            
            — QUIZ / QUEST COMPONENT (if configured):
              • Find published quiz/quest results for this student + subject within date range
              • Compute average percentage, normalize to component max marks
              • Apply quiz/quest weightage
            
            — IA COMPONENTS (if configured):
              • For each IA component (Notebook, Enrichment, etc.):
                Source TBD — may be teacher manual entry via this module's own IA entry screen
                Store per-IA-component marks
            
            — SUBJECT TOTAL = Exam weighted + HW weighted + Quiz weighted + Quest weighted + IA total
            — Apply grading schema → get grade for this subject
            — Store in msh_student_subject_results
       
       ii.  CO-SCHOLASTIC:
            — For each co-scholastic component:
              If component = "Discipline" and BA is configured → call BehaviouralScoreService
              Else → teacher manual grade entry (A/B/C)
            — Store in msh_student_coscholastic_results
       
       iii. ATTENDANCE:
            — Fetch from Attendance module (or manual entry)
            — Store in msh_student_attendance
       
       iv.  AGGREGATION:
            — Grand total across all subjects
            — Percentage = grand_total / grand_max × 100
            — Apply grading schema → overall grade
            — Compute rank in class-section
            — Compute division (First/Second/Third)
            — Determine promotion status (pass in all subjects? fail in ≤2 → compartment?)
            — Store in msh_student_results

3. Mark schedule status = 'computed'
4. Write computation_log entry
```

#### Section 11 — Open Questions (Claude must surface these for Brijesh's decision)

1. Should `msh_source_components` be seeded as fixed or allow school to add custom components?
2. When a student has ZERO attempts in Homework/Quiz within the range — is the component score NULL ("not assessed") or 0?
3. Should the Exam component support "best of N" (e.g., best 2 of 4 unit tests)?
4. IA marks (Notebook, Subject Enrichment) — are these entered through this module's own screen, or do they already exist in another module?
5. Attendance data — does an Attendance module exist with per-student daily data, or must this module accept manual entry?
6. Co-Scholastic grades (Work Ed, Art, Health & PE) — entered through this module, or from another module?
7. Board affiliation — should template include a "board type" field (CBSE/ICSE/State/Custom) to auto-suggest default grading schemas?
8. Class-wise subject list — comes from `sch_class_section_jnt` + `sch_subjects` in SchoolSetup? Or from `slb_*` (Syllabus)?
9. Promotion criteria — configurable per template (e.g., "must pass all subjects" vs "can fail ≤2 subjects and get compartment")? 
10. Should marksheet PDF support school-specific templates (custom header, logo, signature), or one standard format?
11. For Term-1 marksheet — should Homework/Quiz/Quest scores be from the FULL term date range, or only from a configurable "included assessments" list?
12. Is grade calculation for individual subjects (A1, A2, B1...) owned by this module, or should it re-use the grading from `lms_exam_results.grade_obtained`?

---

**STOP AFTER PHASE 1.** Output `{OUTPUT_DIR}/MSG_RequirementSpec.md`. Wait for review and approval.

---

## PHASE 2 — DDL Schema + Data Dictionary

### Phase 2 Input Files

1. `{OUTPUT_DIR}/MSG_RequirementSpec.md` — Phase 1 output (approved)
2. `{TENANT_DDL}` — for FK verification and `sys_dropdown_table` structure
3. `{AI_BRAIN}/rules/tenancy-rules.md`
4. All source module DDLs from CONFIGURATION section above (for FK reference validation)
5. `{LARAVEL_CLAUDE}/migrations.md` — Migration rules

### Phase 2 Task — Generate `MSG_DDL_v1.sql` + `MSG_DataDictionary.md`

#### DDL Output (`MSG_DDL_v1.sql`)

Write MySQL 8.x-compatible DDL. For EVERY `msh_*` table:

**Mandatory columns on ALL tables:**
```sql
id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
is_active       TINYINT(1) NOT NULL DEFAULT 1,
created_by      BIGINT UNSIGNED NOT NULL,
updated_by      BIGINT UNSIGNED NULL,
created_at      TIMESTAMP NULL DEFAULT NULL,
updated_at      TIMESTAMP NULL DEFAULT NULL,
deleted_at      TIMESTAMP NULL DEFAULT NULL
```

**DDL rules:**
- No ENUMs — use `sys_dropdown_table` or a dedicated lookup table.
- No `tenant_id` column on any table.
- All FK columns must have an INDEX.
- Junction tables must have a composite UNIQUE constraint on the joining columns.
- JSON columns suffixed `_json`. Boolean columns prefixed `is_` or `has_`.
- Include `COMMENT` on each table and all non-obvious columns.
- Group tables: Masters → Configuration → Schedule → Results → Audit.
- Add section headers as SQL comments.

**Expected tables (minimum — Claude may add more based on Phase 1):**

**Masters:**
- `msh_marksheet_types` — school-configurable marksheet types
- `msh_source_components` — seeded: Exam, Homework, Quiz, Quest (4 rows — Exam is mandatory)
- `msh_ia_component_types` — seeded IA types: Notebook, Subject Enrichment, Participation, Periodic Assessment

**Configuration:**
- `msh_config_templates` — blueprint per academic session
- `msh_template_scholastic_components` — which source components participate + weightage per template
- `msh_template_exam_weightages` — per-exam-type weightage within Exam component
- `msh_template_ia_components` — IA component definitions + max marks per template
- `msh_template_coscholastic_components` — co-scholastic areas per template
- `msh_grading_configs` — grading schema link per template (FK → slb_grade_division_master)
- `msh_class_config_jnt` — assigns template to class or class-group
- `msh_subject_practical_configs` — theory-practical split per class-subject
- `msh_exam_groups` — groups of exams for marksheet generation
- `msh_exam_group_items_jnt` — junction: exam group ↔ lms_exam_types

**Schedule:**
- `msh_marksheet_schedules` — defines a marksheet generation event
- `msh_schedule_class_jnt` — which class-sections are in this schedule

**Results:**
- `msh_student_results` — one row per student per schedule (aggregate: total, grade, rank, division, promotion)
- `msh_student_subject_results` — per-subject: theory marks, practical marks, IA marks, total, grade
- `msh_student_subject_exam_marks` — per-exam per-subject per-student marks (the raw matrix)
- `msh_student_ia_marks` — per-IA-component marks per subject per student per schedule
- `msh_student_coscholastic_results` — co-scholastic grades per student per schedule
- `msh_student_attendance` — attendance summary per student per schedule

**Audit:**
- `msh_computation_logs` — log per computation run

After DDL, include:
```sql
-- LARAVEL MIGRATION CHECKLIST
-- For each table, list the migration filename and class name
-- e.g.: 2026_04_13_000001_create_msh_marksheet_types_table.php
```

#### Data Dictionary Output (`MSG_DataDictionary.md`)

For EVERY `msh_*` table:

**Table Header:**
```
Table:       msh_[name]
Schema:      tenant_db
Module:      MarksheetGeneration
Domain:      [Master / Configuration / Schedule / Result / Audit]
Purpose:     [one sentence]
Row Volume:  [estimated rows per school per year]
```

**Column Table:**
| Column | Data Type | Nullable | Default | FK Reference | Business Meaning |
|---|---|---|---|---|---|

**Index Table:**
| Index Name | Columns | Type | Purpose |
|---|---|---|---|

**Sample Data (2–3 rows):** Illustrative values to clarify intent.

**Relationships:**
Show FK relationships using `→` notation and cross-module references.

---

**STOP AFTER PHASE 2.** Output `{OUTPUT_DIR}/MSG_DDL_v1.sql` and `{OUTPUT_DIR}/MSG_DataDictionary.md`. Wait for review and approval.

---

## PHASE 3 — Development Plan

### Phase 3 Input Files

1. `{OUTPUT_DIR}/MSG_RequirementSpec.md` — Phase 1 (approved)
2. `{OUTPUT_DIR}/MSG_DDL_v1.sql` — Phase 2 (approved)
3. `{AI_BRAIN}/memory/modules-map.md` — module scaffolding conventions
4. `{AI_BRAIN}/rules/module-rules.md` — module development rules
5. `{LARAVEL_CLAUDE}/migrations.md` — migration rules

### Phase 3 Task — Generate `MSG_Dev_Plan.md`

Generate a complete, actionable development plan:

---

#### Section 1 — Module Overview

| Item | Value |
|---|---|
| Module Name | MarksheetGeneration |
| Module Code | MSG |
| Branch | marksheet-generation |
| DB Prefix | msh_* |
| Module Type | Tenant |
| Tables | [count from Phase 2] |
| Controllers | [estimate] |
| Services | [4 main + 5 score readers + 1 computation] |
| Jobs | 1 (bulk computation) |
| Estimated Complexity | High |

#### Section 2 — Pre-Development Checklist

- [ ] Verify `lms_exam_papers.mode` column exists in actual migration (ONLINE/OFFLINE)
- [ ] Verify `lms_exam_results` has `result_status` ENUM with 'ABSENT', 'WITHHELD' values
- [ ] Verify `lms_exam_types.code` values match expected exam categories (UT-1, HY-EXAM, etc.)
- [ ] Verify `lms_quiz_quest_results.assessment_type` and `assessment_id` columns
- [ ] Verify `slb_grade_division_master` structure for grading schema integration
- [ ] Verify `sch_class_groups` ↔ `sch_classes` relationship
- [ ] Verify `BehaviouralScoreService` exists and method signature
- [ ] Verify if Attendance module exists with per-student daily attendance data
- [ ] Verify `sys_dropdown_table` usage pattern from `{TENANT_DDL}`
- [ ] Resolve ALL open questions from Phase 1 Section 11 before Sprint 1

#### Section 3 — Service Architecture

Document these services:
1. **MarksheetConfigService** — template CRUD, component config, exam weightage, class assignment, practical config, IA config, co-scholastic config, grading schema link
2. **MarksheetComputationService** — main orchestrator: calls score readers, applies weightage hierarchy, computes subject totals, grades, rank, division, promotion status
3. **MarksheetPublicationService** — schedule lifecycle: draft → computed → reviewed → published → locked + admin unlock
4. **MarksheetPdfService** — PDF generation via DomPDF (inline styles, table layout, school logo, signature placeholder)

Score Reader sub-services:
- `ExamScoreReader` — reads from `lms_exam_results` via `lms_exam_papers` join
- `HomeworkScoreReader` — reads from `lms_homework_submissions`
- `QuizScoreReader` — reads from `lms_quiz_quest_results` WHERE `assessment_type = 'QUIZ'`
- `QuestScoreReader` — reads from `lms_quiz_quest_results` WHERE `assessment_type = 'QUEST'`
- `BehaviouralScoreReader` — delegates to `BehaviouralScoreService`
- `AttendanceReader` — reads from Attendance module or manual entry

#### Section 4 — Sprint-by-Sprint Plan

**Sprint 1 — Foundation & Configuration (2 weeks)**
- Module scaffolding, migrations, models, seeders
- MarksheetConfigService (template CRUD, scholastic components, exam weightage)
- Views: SC-MSG-01 to SC-MSG-04

**Sprint 2 — IA, Co-Scholastic, Class Assignment (1.5 weeks)**
- IA component config, Co-Scholastic setup, practical config
- Class/class-group assignment with inheritance
- Exam grouping
- Views: SC-MSG-05 to SC-MSG-08

**Sprint 3 — Computation Engine (2.5 weeks)**
- 6 Score Reader services
- MarksheetComputationService (full algorithm)
- ComputeMarksheetJob (queued, chunked per class-section)
- Grade, Rank, Division, Promotion computation
- Views: SC-MSG-09 to SC-MSG-11

**Sprint 4 — Review, Publication & PDF (2 weeks)**
- MarksheetPublicationService (publish, lock, unlock + audit)
- MarksheetPdfService (DomPDF, inline styles, table-based layout, school logo)
- Views: SC-MSG-12 to SC-MSG-15

**Sprint 5 — Portal Integration & Polish (1 week)**
- StudentPortal + ParentPortal read-only endpoints
- PDF download for student/parent
- End-to-end integration tests

#### Section 5 — File Structure

Complete file tree for `Modules/MarksheetGeneration/`.

#### Section 6 — Permission Matrix

| Permission String | Super Admin | Principal | Coordinator | Class Teacher | Subject Teacher | Student | Parent |
|---|---|---|---|---|---|---|---|

#### Section 7 — Test Plan (~10 test files, ~50 tests)

| File | Count | Key Scenarios |
|---|---|---|

#### Section 8 — Cross-Module Dependencies & Risks

| Dependency | Module | Risk | Mitigation |
|---|---|---|---|

#### Section 9 — Security Checklist

- [ ] Every controller method has `Gate::authorize()`
- [ ] All FormRequests have `authorize()` with real Gate check (NOT hardcoded `true`)
- [ ] Student marksheet access scoped to own student_id (IDOR prevention)
- [ ] Parent access scoped to linked children only
- [ ] Published lock enforced at service layer, not just UI
- [ ] Admin unlock requires reason (stored in `msh_computation_logs`)
- [ ] PDF download URLs signed (`URL::temporarySignedRoute`)
- [ ] No raw SQL — use Eloquent throughout
- [ ] All score readers validate `is_published = 1` before reading results

---

**STOP AFTER PHASE 3.** Output `{OUTPUT_DIR}/MSG_Dev_Plan.md`.

All 4 output files (3 phases) are now complete. Review and confirm before starting implementation.

---

## QUICK REFERENCE — Source Module Score Columns (verified from DDL)

### LmsHomework (DDL v4)
```
Score:  lms_homework_submissions.marks_obtained (DECIMAL 5,2)
Max:    lms_homework.max_marks (DECIMAL 5,2)
Filter: lms_homework.class_id, .subject_id, .academic_session_id
Status: lms_homework_submissions.status_id (must be GRADED)
```

### LmsQuiz (DDL v2) + LmsQuest (DDL v2)
```
Score:  lms_quiz_quest_results.total_marks_obtained (DECIMAL 8,2)
Max:    lms_quiz_quest_results.max_marks (DECIMAL 8,2)
Pct:    lms_quiz_quest_results.percentage (DECIMAL 5,2)
Type:   lms_quiz_quest_results.assessment_type = 'QUIZ' or 'QUEST'
AssocID: lms_quiz_quest_results.assessment_id → lms_quizzes.id or lms_quests.id
Published: lms_quiz_quest_results.is_published = 1
```

### LmsExam (DDL v5 + StudentAttempts v3)
```
Score:     lms_exam_results.total_marks_obtained (DECIMAL 8,2)
Max:       lms_exam_results.total_marks_possible (DECIMAL 8,2)
Pct:       lms_exam_results.percentage (DECIMAL 5,2)
Grade:     lms_exam_results.grade_obtained (VARCHAR 10)
Status:    lms_exam_results.result_status (ENUM: PASS/FAIL/ABSENT/WITHHELD)
Paper FK:  lms_exam_results.exam_paper_id → lms_exam_papers.id
Subject:   lms_exam_papers.subject_id → sch_subjects.id
Mode:      lms_exam_papers.mode (ENUM: ONLINE/OFFLINE) — transparent to marksheet
Exam Type: lms_exams.exam_type_id → lms_exam_types.id (UT-1, HY-EXAM, etc.)
Published: lms_exam_results.is_published = 1
```

### BehaviouralAssessment (DDL v2)
```
API: BehaviouralScoreService::getStudentScore(studentId, periodId)
Returns: { numeric_score, grade, category_scores[] }
Config: ba_config.is_result_integration_enabled must be true
```

### Cross-Module Reference Tables
```
sch_classes            — class master
sch_class_groups       — class group (Primary, Middle, Secondary)
sch_class_sections     — class × section combination
sch_subjects           — subject master
sch_academic_sessions  — current and past academic sessions
std_students           — student master
slb_grade_division_master — grading schema definitions
sys_dropdown_table     — generic dropdown lookups
```
