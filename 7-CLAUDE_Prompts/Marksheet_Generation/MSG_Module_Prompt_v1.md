# MSG — Marksheet Generation Module Development Lifecycle Prompt (v1)

**Purpose:** Consolidated prompt to build 4 output files for the **MSG (MarksheetGeneration)** module. Aggregates marks from LmsHomework, LmsQuiz, LmsQuest, LmsExam (Online + Offline), and BehaviouralAssessment into configurable school marksheets. Execute phases sequentially; Claude STOPS after each phase for your review and approval before proceeding.

**Output Files:**
1. `MSG_RequirementSpec.md` — Detailed Requirement Specification Document
2. `MSG_FeatureSpec.md` — Feature Specification (Entity Inventory, Business Rules, FR Matrix, Permission Matrix)
3. `MSG_DDL_v1.sql` + `MSG_DataDictionary.md` — Database Schema + Data Dictionary
4. `MSG_Dev_Plan.md` — Complete Development Plan

**Developer:** Brijesh
**v1 Note:** New module. Table prefix: `msh_*`. Aggregates marks from 5 source modules into configurable school marksheets with per-class weightage configuration.

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
BRANCH            = marksheet-generation
RBS_MODULE_CODE   = T                              # Tenant module
DB_TABLE_PREFIX   = msh_                            # Single prefix
DATABASE_NAME     = tenant_db

OUTPUT_DIR        = {OLD_REPO}/7-Work_with_CLAUDE/Marksheet_Generation
MIGRATION_DIR     = {LARAVEL_REPO}/database/migrations/tenant
TENANT_DDL        = {DB_REPO}/1-Master_DDLs/tenant_db_v2.sql

# Source Module DDLs (READ ONLY — never modify these)
DDL_HOMEWORK      = {OLD_REPO}/1-DDL_Tenant_Modules/52a-LMS_Homework/DDL/LMS_Homework_DDL_v4.sql
DDL_QUIZ          = {OLD_REPO}/1-DDL_Tenant_Modules/53b-LMS_Quiz/DDL/LMS_Quiz_ddl_v2.sql
DDL_QUEST         = {OLD_REPO}/1-DDL_Tenant_Modules/54c-LMS_Quest/DDL/LMS_Quest_ddl_v2.sql
DDL_EXAM          = {OLD_REPO}/1-DDL_Tenant_Modules/55d-LMS_Exam/DDL/LMS_Exam_ddl_v5.sql
DDL_ATTEMPTS      = {OLD_REPO}/1-DDL_Tenant_Modules/55e-LMS_StudentAttempts/DDL/LMS_StudentAttempts_ddl_v2.sql
DDL_BA            = {OLD_REPO}/5-Work-In-Progress/2-In-Progress/BehaviouralAssessment/DDL/BA_DDL_v1.sql

# Output Files
REQUIREMENT_FILE  = MSG_RequirementSpec.md
FEATURE_FILE      = MSG_FeatureSpec.md
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
5. Repeat for Phases 3 and 4

---

## KEY CONTEXT — MSG (MARKSHEET GENERATION) MODULE

### What This Module Does

MarksheetGeneration is the **school result aggregation and marksheet configuration engine** for Prime-AI. It is a single Laravel module (`Modules\MarksheetGeneration`) that enables Indian K-12 schools to:

- Define which assessment sources contribute to student marksheets
- Configure weightage per source, per exam, and per class/class-group
- Support multiple marksheet publication types (per-exam, half-yearly, annual)
- Include practical exam marks where applicable
- Generate consolidated student marksheets pulling from 5 source modules

### Source Modules (READ FROM, NEVER MODIFY)

| Module | Tables Used | What It Provides |
|---|---|---|
| **LmsHomework** | `lms_homework`, `lms_homework_assignment`, `lms_homework_submissions` | Homework submission scores per student |
| **LmsQuiz** | `lms_quizzes`, `lms_quiz_allocations`, `lms_quiz_quest_results` | Quiz scores per student |
| **LmsQuest** | `lms_quests`, `lms_quest_allocations`, `lms_quiz_quest_results` | Quest scores per student |
| **LmsExam (Online)** | `lms_exams`, `lms_exam_types`, `lms_exam_scopes`, `lms_exam_results`, `lms_exam_attempts` | Online exam results |
| **LmsExam (Offline)** | `lms_exams`, `lms_exam_types`, `lms_exam_scopes`, `lms_exam_marks_entry` | Offline exam marks (manual entry) |
| **BehaviouralAssessment** | `ba_computed_scores`, `ba_config`, `ba_assessment_periods` | Behavioural scores (via `BehaviouralScoreService`) |

> **CRITICAL:** This module NEVER writes to any `lms_*` or `ba_*` table. All reads are read-only integrations via service classes or direct query.

### Architecture Overview

```
School Admin configures:
  msh_marksheet_types          (e.g. "Unit Test", "Half Yearly", "Annual")
  msh_source_components        (Homework, Quiz, Quest, Online Exam, Offline Exam, Behaviour)
  msh_config_templates         (reusable configuration blueprint)
  msh_config_template_components  (component weightage per template)
  msh_config_template_exams    (exam-specific weightage within template)
  msh_class_config_jnt         (assigns a template to one or more classes/class-groups)
  msh_practical_configs        (practical exam configuration per class-subject)
  msh_marksheet_schedules      (when each marksheet type is published)

System generates:
  msh_consolidated_results     (computed aggregate result per student per marksheet schedule)
  msh_result_components        (breakdown: score per component per student)
  msh_result_exam_breakdowns   (score per individual exam per student)
  msh_computation_logs         (audit log of each generation run)
```

### Business Rules Summary

1. **Weightages must sum to 100%** per configuration template (enforced at service layer + DB check constraint where possible)
2. **LmsExam has two types** — Online Exam (auto-scored from attempts) and Offline Exam (manual marks entry via `lms_exam_marks_entry`) — both must be supported with independent weightage
3. **Per-exam weightage**: UT1, UT2, UT3, UT4, Half Yearly, Annual each get individual weightage within the exam component. Sum of per-exam weightages within the exam component = 100% of that component's total
4. **Class-group configuration sharing**: A single `msh_config_template` can be assigned to multiple classes via `msh_class_config_jnt`. When a class has no direct assignment, it inherits from its class-group's assignment
5. **Practical exam support**: Optional per class-subject. Practical marks stored separately and combined with theory marks using a configurable split (e.g., Theory 70%, Practical 30%)
6. **Marksheet schedule types**:
   - `per_exam` — marksheet generated after each exam
   - `half_yearly` — after Half Yearly exam, covering UT1+UT2+Half Yearly
   - `annual` — year-end, covering all exams across the full academic session
7. **BehaviouralAssessment integration**: Pulled via `BehaviouralScoreService::getStudentScore()`. Only included if `ba_config.is_result_integration_enabled = true` AND school has configured BA weightage in `msh_config_template_components`
8. **Homework/Quiz/Quest aggregation**: Scores averaged across all assignments/quizzes/quests within the marksheet schedule's date range before applying weightage
9. **Zero marks vs absent**: `lms_exam_marks_entry.is_absent` flag must be preserved in consolidated result (absent ≠ zero marks)
10. **Result immutability**: Once a marksheet is published (`msh_marksheet_schedules.status = published`), computed results are locked — re-generation requires explicit admin unlock + audit entry
11. **Multi-tenant isolation**: All `msh_*` tables are tenant-scoped (dedicated DB per tenant). No `tenant_id` column on any table.
12. **Soft deletes** on all entities; audit columns (`created_by`, `updated_by`) on all tables.

---

## PHASE 1 — Requirement Specification Document

### Phase 1 Input Files

Read ALL these files in order before generating any output:

1. `{AI_BRAIN}/memory/project-context.md` — project context, tech stack, multi-tenancy rules
2. `{AI_BRAIN}/memory/modules-map.md` — existing module inventory and naming conventions
3. `{AI_BRAIN}/rules/tenancy-rules.md` — multi-tenancy rules (CRITICAL — no tenant_id column)
4. `{AI_BRAIN}/rules/module-rules.md` — module development conventions
5. `{DDL_HOMEWORK}` — read all table definitions to understand homework scoring columns
6. `{DDL_QUIZ}` — read all table definitions to understand quiz scoring columns
7. `{DDL_QUEST}` — read all table definitions to understand quest scoring columns
8. `{DDL_EXAM}` — read all table definitions; identify `lms_exam_types.type` column to distinguish Online vs Offline
9. `{DDL_ATTEMPTS}` — read `lms_quiz_quest_results`, `lms_exam_results`, `lms_exam_marks_entry` carefully for result columns
10. `{DDL_BA}` — read `ba_computed_scores`, `ba_config` to understand behavioural score API
11. `{TENANT_DDL}` — verify column names for: `sch_classes`, `sch_class_groups`, `sch_class_sections`, `sch_academic_sessions`, `std_students`, `sys_dropdown_table`

### Phase 1 Task — Generate `MSG_RequirementSpec.md`

Generate a comprehensive Requirement Specification Document. Organise it into these sections:

---

#### Section 1 — Executive Summary
- What the MarksheetGeneration module does
- Why it is needed (gap analysis: current state has 5 isolated scoring modules with no consolidated result engine)
- Key stakeholders: School Admin, Principal, Class Teacher, Student, Parent
- Integration touch-points: 5 source modules + SchoolSetup

#### Section 2 — Scope

**In Scope:**
- Marksheet configuration setup (template creation, component weightage, exam weightage)
- Class/class-group to template assignment
- Practical exam configuration per class-subject
- Marksheet schedule definition (per-exam / half-yearly / annual)
- Consolidated result computation and storage
- Marksheet publication lifecycle (draft → computed → reviewed → published → locked)
- Re-generation with audit trail
- PDF marksheet generation (DomPDF)

**Out of Scope (explicitly state):**
- Marks entry (owned by respective source modules — LmsExam, LmsHomework, etc.)
- Grade card design (owned by HPC module)
- Fee integration or fine calculations
- Board exam result upload
- Any modification to `lms_*`, `ba_*`, `sch_*`, `std_*` tables

#### Section 3 — Business Requirements (15–20 BRs)

For each BR, provide:
| BR ID | Requirement | Source Module Involved | Priority |
|---|---|---|---|

Cover:
- Configurable source components per school
- Per-component weightage
- Per-exam weightage (UT1, UT2, UT3, UT4, Half Yearly, Annual separately configurable)
- Class-level vs class-group-level template inheritance
- Practical exam support (theory-practical split per class-subject)
- Multiple marksheet types per academic session
- Online vs Offline exam mark source distinction
- BehaviouralAssessment optional integration
- Homework/Quiz/Quest date-range aggregation
- Absent student handling (absent ≠ zero)
- Published result lock + admin unlock flow
- Audit trail for every re-generation
- Multi-language support (Hindi/English)

#### Section 4 — Functional Requirements (20–25 FRs)

For each FR:
| FR ID | Feature Name | Screen/UI | Source Tables (READ) | Target Tables (WRITE) | Business Rules Applied |
|---|---|---|---|---|---|

Group into sub-modules:
- **FR-MSG-001 to FR-MSG-005**: Configuration Setup (templates, components, weightage)
- **FR-MSG-006 to FR-MSG-010**: Class Assignment & Practical Config
- **FR-MSG-011 to FR-MSG-013**: Marksheet Schedule Management
- **FR-MSG-014 to FR-MSG-018**: Result Computation Engine
- **FR-MSG-019 to FR-MSG-022**: Result Review & Publication
- **FR-MSG-023 to FR-MSG-025**: Marksheet PDF Generation & Reports

#### Section 5 — Use Case Matrix

| Use Case ID | Actor | Trigger | Main Flow | Alternate Flow |
|---|---|---|---|---|

Cover at minimum:
- UC-MSG-001: Admin creates marksheet config template for a class group
- UC-MSG-002: Admin assigns template to individual class (override)
- UC-MSG-003: Admin configures practical split for a class-subject
- UC-MSG-004: Admin creates Half Yearly marksheet schedule
- UC-MSG-005: System computes consolidated result for a student
- UC-MSG-006: Admin publishes marksheet
- UC-MSG-007: Admin unlocks published marksheet and triggers recomputation
- UC-MSG-008: Teacher previews individual student marksheet
- UC-MSG-009: Student views own marksheet via Student Portal
- UC-MSG-010: Parent views child's marksheet via Parent Portal

#### Section 6 — Non-Functional Requirements

| NFR ID | Category | Requirement | Implementation Note |
|---|---|---|---|

Cover: performance (bulk computation ≤ 60s for 500 students), concurrency, caching, RBAC, audit trail, multi-tenancy isolation, PDF quality, localisation, data retention.

#### Section 7 — Integration Contracts

For each source module, document the exact read contract:

**LmsHomework:**
- Tables: `lms_homework`, `lms_homework_assignment`, `lms_homework_submissions`
- Filter by: class_section_id, subject_id, academic_session_id, date range (marksheet schedule dates)
- Score field: identify from DDL the column holding the final score/marks
- Aggregation: average score across all submissions in range

**LmsQuiz:**
- Tables: `lms_quizzes`, `lms_quiz_allocations`, `lms_quiz_quest_results`
- Filter by: class_section_id, subject_id, date range
- Score field: identify from DDL
- Aggregation: average score across all quiz results in range

**LmsQuest:**
- Tables: `lms_quests`, `lms_quest_allocations`, `lms_quiz_quest_results`
- Filter + score + aggregation: same pattern as Quiz

**LmsExam Online:**
- Tables: `lms_exams` (where `lms_exam_types.type = 'online'`), `lms_exam_results`
- Per-exam linkage: `lms_exams.id` maps to `msh_config_template_exams.exam_id`
- Score field: identify from DDL

**LmsExam Offline:**
- Tables: `lms_exams` (where `lms_exam_types.type = 'offline'`), `lms_exam_marks_entry`
- Absent flag: preserve `is_absent` column
- Score field: identify from DDL

**BehaviouralAssessment:**
- API: `BehaviouralScoreService::getStudentScore(studentId, periodId)`
- Pre-condition: `ba_config.is_result_integration_enabled = true`
- Returns: `{ numeric_score, grade, category_scores[] }`
- Only included if school has configured BA component in `msh_config_template_components`

#### Section 8 — Screen Inventory (~12 screens)

For each screen, provide:
| Screen ID | Screen Name | Actor | Key Fields / Actions |
|---|---|---|---|

Screens to document:
- SC-MSG-01: Marksheet Source Components Master (read-only listing of 6 components)
- SC-MSG-02: Config Template Builder (create/edit template, add components, set weightages)
- SC-MSG-03: Exam Weightage Setup (assign weightage per exam within "Exam" component)
- SC-MSG-04: Class/Class-Group Template Assignment
- SC-MSG-05: Practical Exam Configuration (per class-subject, theory-practical split)
- SC-MSG-06: Marksheet Schedule Setup (define type: per-exam/half-yearly/annual, link exams)
- SC-MSG-07: Marksheet Schedule Dashboard (list all schedules, status, action buttons)
- SC-MSG-08: Result Computation Progress (trigger computation, show real-time job progress)
- SC-MSG-09: Result Review Grid (class-level: student × subject × component breakdown)
- SC-MSG-10: Individual Student Marksheet Preview
- SC-MSG-11: Marksheet Publication & Lock Screen
- SC-MSG-12: Marksheet PDF Download (admin/teacher/student/parent view)

---

**STOP AFTER PHASE 1.** Output `{OUTPUT_DIR}/MSG_RequirementSpec.md`. Wait for review and approval.

---

## PHASE 2 — Feature Specification

### Phase 2 Input Files

1. `{OUTPUT_DIR}/MSG_RequirementSpec.md` — Phase 1 output (approved)
2. `{AI_BRAIN}/memory/project-context.md`
3. `{AI_BRAIN}/rules/tenancy-rules.md`
4. `{TENANT_DDL}` — for cross-module FK column verification
5. All source module DDLs from CONFIGURATION section above

### Phase 2 Task — Generate `MSG_FeatureSpec.md`

Generate a comprehensive feature specification. Organise into these sections:

---

#### Section 1 — Module Identity & Scale

| Artifact | Count |
|---|---|
| Controllers | estimate |
| Models | estimate |
| Services | 4 |
| FormRequests | estimate |
| Policies | estimate |
| Jobs | 1 (bulk computation) |
| msh_* tables | estimate |
| Blade views | estimate |

Module details:
- Namespace: `Modules\MarksheetGeneration`
- Route prefix: `marksheet-generation/`
- Route name prefix: `marksheet-generation.`
- Table prefix: `msh_`
- Module type: Tenant

#### Section 2 — Complete Table Inventory (All `msh_*` Tables)

Design and document ALL required tables. At minimum include:

| # | Table | Domain | Purpose |
|---|---|---|---|
| 1 | `msh_source_components` | Master | 6 fixed components: Homework, Quiz, Quest, Online Exam, Offline Exam, Behaviour |
| 2 | `msh_marksheet_types` | Master | e.g. Unit Test, Half Yearly, Annual (school-configurable) |
| 3 | `msh_config_templates` | Configuration | Reusable marksheet configuration blueprint per academic session |
| 4 | `msh_config_template_components` | Configuration | Which components included + weightage per template |
| 5 | `msh_config_template_exams` | Configuration | Individual exam (UT1, UT2…) weightage within the Exam component |
| 6 | `msh_class_config_jnt` | Configuration | Assigns template to class or class-group (with inheritance flag) |
| 7 | `msh_practical_configs` | Configuration | Theory-Practical split per class-subject combination |
| 8 | `msh_marksheet_schedules` | Schedule | Defines a marksheet event (type, academic session, date range, linked exams) |
| 9 | `msh_schedule_exam_jnt` | Schedule | Junction: schedule ↔ linked exams (from lms_exams) |
| 10 | `msh_consolidated_results` | Result | Aggregate result per student per schedule |
| 11 | `msh_result_components` | Result | Score breakdown per component per student per schedule |
| 12 | `msh_result_exam_breakdowns` | Result | Score per individual exam per student per schedule |
| 13 | `msh_computation_logs` | Audit | Log of each computation run (triggered by, duration, status, error) |

For EACH table, provide:
- Full column list: `column_name | data_type | nullable | default | constraints | comment`
- Unique constraints
- Indexes (all FKs + filtered columns)
- Cross-module FK references

#### Section 3 — Entity Relationship Diagram (text-based)

Show all `msh_*` tables grouped by domain. Use `→` for FK direction (child → parent). Include cross-module references to `sch_*`, `std_*`, `lms_*`, `ba_*` tables.

#### Section 4 — Business Rules (20 rules)

| BR ID | Rule | Enforcement Point |
|---|---|---|

Enforcement points: `service_layer` | `db_constraint` | `form_validation` | `model_event`

Critical rules to include:
- BR-MSG-001: Sum of component weightages in a template must equal 100 — `form_validation` + `service_layer`
- BR-MSG-002: Sum of exam weightages within Exam component must equal 100 — `form_validation` + `service_layer`
- BR-MSG-003: A class can have at most one active template per marksheet type per academic session — `db_constraint`
- BR-MSG-004: Class inherits class-group template unless overridden — `service_layer`
- BR-MSG-005: Practical config is optional; if absent, subject is 100% theory — `service_layer`
- BR-MSG-006: Online exam score sourced from `lms_exam_results`; offline from `lms_exam_marks_entry` — `service_layer`
- BR-MSG-007: Absent students (is_absent=true) get NULL score, not zero, in breakdown — `service_layer`
- BR-MSG-008: Published schedules are locked — no recomputation without explicit admin unlock + audit entry — `service_layer`
- BR-MSG-009: BA component included ONLY if ba_config.is_result_integration_enabled = true — `service_layer`
- BR-MSG-010: Homework/Quiz/Quest scores averaged across all items within schedule date range — `service_layer`
- BR-MSG-011: Per-exam weightage applied BEFORE component-level weightage — `service_layer`
- BR-MSG-012: If a student has no score for a component (no attempts), component score = NULL (not zero), unless school config says treat as zero — `service_layer`
- BR-MSG-013: Config templates are immutable once linked to a published schedule — `service_layer`
- BR-MSG-014: Computation runs as a queued job; user sees progress — `job + event broadcast`
- BR-MSG-015: Soft delete on all entities; audit columns on all tables — `db_constraint`
- (derive remaining rules from Section 3 of Phase 1 output)

#### Section 5 — Computation Algorithm (Service-Level Pseudocode)

For `MarksheetComputationService::computeForSchedule(scheduleId)`, document the full algorithm:

```
1. Load schedule + linked config template + class assignments
2. For each class_section in scope:
   a. Load all students in class_section
   b. For each student:
      i.   For each component in template (Homework/Quiz/Quest/OnlineExam/OfflineExam/BA):
           - Call component-specific reader service (HomeworkScoreReader, QuizScoreReader, etc.)
           - Reader returns { student_id, raw_score, max_score, count_items, has_null }
           - Normalize to 100: normalized = (raw_score / max_score) * 100
           - Apply component weightage: weighted = normalized * component_weight_pct / 100
           - Store in msh_result_components
      ii.  For Exam component: break down by individual exam
           - For each linked exam in schedule:
             * Fetch score (online: lms_exam_results; offline: lms_exam_marks_entry)
             * Apply per-exam weightage within Exam component
           - Store per-exam breakdown in msh_result_exam_breakdowns
      iii. For Practical subjects:
           - Fetch practical marks from lms_exam_marks_entry (offline only)
           - Apply theory-practical split from msh_practical_configs
      iv.  Aggregate: consolidated_score = SUM(weighted component scores)
           - Store in msh_consolidated_results
3. Mark schedule status = 'computed'
4. Write computation_log entry
```

#### Section 6 — Service Architecture (4 Services)

For each service, document using the format:

```
Service:     ClassName
File:        app/Services/ClassName.php
Namespace:   Modules\MarksheetGeneration\app\Services
Depends on:  [services/repositories it calls]
Fires:       [events it dispatches]

Key Methods:
  methodName(TypeHint $param): ReturnType
    └── description
```

Services:
1. **MarksheetConfigService** — CRUD for templates, component config, exam weightage, class assignment, practical config; validates weightage sums; guards template immutability once linked to published schedule
2. **MarksheetComputationService** — main computation orchestrator; calls 6 score-reader services; applies weightage hierarchy; handles absent flags; writes to msh_consolidated_results, msh_result_components, msh_result_exam_breakdowns; dispatches `ComputationCompleted` event
3. **MarksheetPublicationService** — schedule lifecycle: draft → computed → reviewed → published → locked; admin unlock flow with audit; triggers recomputation after unlock; permission checks
4. **MarksheetPdfService** — PDF generation via DomPDF; student marksheet layout (theory + practical + component breakdown + total + grade); supports admin/teacher/student/parent views; caches PDF per student per schedule

Score Reader Services (called by MarksheetComputationService — document as sub-services):
- `HomeworkScoreReader::getScore(studentId, classSectionId, subjectId, fromDate, toDate)`
- `QuizScoreReader::getScore(studentId, classSectionId, subjectId, fromDate, toDate)`
- `QuestScoreReader::getScore(...)` (same signature as Quiz)
- `ExamScoreReader::getScore(studentId, examId, examType)` — `examType` = 'online' | 'offline'
- `BehaviouralScoreReader::getScore(studentId, periodId)` — delegates to `BehaviouralScoreService`

#### Section 7 — Permission Matrix

| Permission String | Super Admin | Principal | Vice Principal | Class Teacher | Subject Teacher | Student | Parent |
|---|---|---|---|---|---|---|---|

Permissions to include:
- `msg.config.*` — template CRUD, class assignment, practical config
- `msg.schedule.*` — marksheet schedule management
- `msg.compute.*` — trigger computation, view progress
- `msg.review.*` — review computed results
- `msg.publish.*` — publish, lock, unlock
- `msg.report.class` — class-level result grid
- `msg.report.student` — individual student marksheet
- `msg.report.download` — PDF download

#### Section 8 — Integration Events

| Event | Fired By | Listener | Payload | Action |
|---|---|---|---|---|
| ComputationCompleted | MarksheetComputationService | NotificationService | schedule_id, class_section_id, student_count | Notify principal/coordinator |
| MarksheetPublished | MarksheetPublicationService | NotificationService | schedule_id, class_section_ids[] | Notify teachers + students + parents |
| MarksheetUnlocked | MarksheetPublicationService | AuditService | schedule_id, unlocked_by, reason | Write audit entry; notify principal |

#### Section 9 — Test Plan Outline (~8 test files, ~40 tests)

| File | Count | Key Scenarios |
|---|---|---|
| ConfigTemplateTest | 6 | CRUD, weightage sum validation, immutability guard |
| ClassAssignmentTest | 5 | Direct assign, group inherit, override, conflict |
| PracticalConfigTest | 4 | Create, split validation, subject without practical |
| MarksheetScheduleTest | 6 | CRUD, status transitions, linked exams |
| ComputationTest | 10 | All 5 sources, absent flag, null handling, BA excluded when disabled |
| PublicationTest | 5 | Publish, lock, unlock + audit, recompute after unlock |
| PdfTest | 4 | Generate for student, teacher view, parent view, empty result |

---

**STOP AFTER PHASE 2.** Output `{OUTPUT_DIR}/MSG_FeatureSpec.md`. Wait for review and approval.

---

## PHASE 3 — DDL Schema + Data Dictionary

### Phase 3 Input Files

1. `{OUTPUT_DIR}/MSG_FeatureSpec.md` — Phase 2 output (approved)
2. `{TENANT_DDL}` — for FK verification and `sys_dropdown_table` structure
3. `{AI_BRAIN}/rules/tenancy-rules.md`
4. All source module DDLs from CONFIGURATION section above

### Phase 3 Task — Generate `MSG_DDL_v1.sql` + `MSG_DataDictionary.md`

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
- No ENUMs. Use lookup from `sys_dropdown_table` or a dedicated master table.
- No `tenant_id` column on any table.
- All FK columns must have an INDEX immediately after table definition.
- Junction tables must have a composite UNIQUE constraint on the joining columns.
- JSON columns must be named with `_json` suffix (e.g., `settings_json`).
- Boolean columns must be named with `is_` or `has_` prefix.
- Include `COMMENT` on each table and on all non-obvious columns.
- Group tables in this order: Masters → Configuration → Schedule → Results → Audit.
- Add section headers as SQL comments.

After DDL, include:
```sql
-- LARAVEL MIGRATION CHECKLIST
-- For each table, list the migration filename and class name
-- e.g.: 2026_04_13_000001_create_msh_source_components_table.php
```

#### Data Dictionary Output (`MSG_DataDictionary.md`)

For EVERY `msh_*` table, provide:

**Table Header:**
```
Table:       msh_[name]
Schema:      tenant_db
Module:      MarksheetGeneration
Domain:      [Configuration / Schedule / Result / Audit]
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

---

**STOP AFTER PHASE 3.** Output `{OUTPUT_DIR}/MSG_DDL_v1.sql` and `{OUTPUT_DIR}/MSG_DataDictionary.md`. Wait for review and approval.

---

## PHASE 4 — Development Plan

### Phase 4 Input Files

1. `{OUTPUT_DIR}/MSG_RequirementSpec.md` — Phase 1 output (approved)
2. `{OUTPUT_DIR}/MSG_FeatureSpec.md` — Phase 2 output (approved)
3. `{OUTPUT_DIR}/MSG_DDL_v1.sql` — Phase 3 output (approved)
4. `{AI_BRAIN}/memory/modules-map.md` — For module scaffolding conventions
5. `{AI_BRAIN}/rules/module-rules.md` — Module development rules
6. `{LARAVEL_CLAUDE}/migrations.md` — Migration rules

### Phase 4 Task — Generate `MSG_Dev_Plan.md`

Generate a complete, actionable development plan. Organise into these sections:

---

#### Section 1 — Module Overview

| Item | Value |
|---|---|
| Module Name | MarksheetGeneration |
| Module Code | MSG |
| Branch | marksheet-generation |
| DB Prefix | msh_* |
| Module Type | Tenant |
| Tables | [count from Phase 3] |
| Controllers | [from Phase 2 estimate] |
| Services | 4 + 5 score readers |
| Jobs | 1 |
| Migrations | [count from Phase 3 DDL] |
| Estimated Complexity | High |

#### Section 2 — Pre-Development Checklist

List ALL items that must be verified before starting development:
- [ ] Verify `lms_exam_types.type` column distinguishes Online vs Offline in actual DB schema
- [ ] Verify `lms_exam_marks_entry` has `is_absent` column in actual migration
- [ ] Verify `lms_quiz_quest_results` covers both Quiz and Quest (same table) — confirm from DDL
- [ ] Verify `BehaviouralScoreService` method signature and return type
- [ ] Confirm `ba_computed_scores` structure for pulling behavioural scores
- [ ] Confirm `sch_class_groups` relationship to `sch_classes` from SchoolSetup DDL
- [ ] Confirm `sys_dropdown_table` usage pattern from `{TENANT_DDL}`
- [ ] Confirm `lms_exam_scopes` — how exams are linked to class sections

#### Section 3 — Migration Plan

| Step | Migration File | Table Created | Dependencies |
|---|---|---|---|

List migrations in correct dependency order (masters before FKs).

#### Section 4 — Sprint-by-Sprint Development Plan

**Sprint 1 — Foundation & Configuration (Target: 2 weeks)**

Tasks:
- [ ] Module scaffolding (`php artisan module:make MarksheetGeneration`)
- [ ] Migrations: all `msh_*` tables in dependency order
- [ ] Models: one per table, with relationships, SoftDeletes, audit columns
- [ ] Seeders: `msh_source_components` (6 fixed records)
- [ ] `MarksheetConfigService`: template CRUD, component/exam weightage
- [ ] `MarksheetConfigController` + FormRequests + Policies
- [ ] Views: SC-MSG-02 (Config Template Builder), SC-MSG-03 (Exam Weightage)
- [ ] Tests: ConfigTemplateTest (6 tests)

**Sprint 2 — Class Assignment & Scheduling (Target: 1.5 weeks)**

Tasks:
- [ ] `MarksheetConfigService` extension: class assignment, practical config
- [ ] Views: SC-MSG-04 (Class Assignment), SC-MSG-05 (Practical Config), SC-MSG-06 (Schedule Setup)
- [ ] `MarksheetPublicationService`: schedule lifecycle (draft → computed)
- [ ] Tests: ClassAssignmentTest (5 tests), PracticalConfigTest (4 tests), MarksheetScheduleTest (6 tests)

**Sprint 3 — Computation Engine (Target: 2 weeks)**

Tasks:
- [ ] 5 Score Reader services (HomeworkScoreReader, QuizScoreReader, QuestScoreReader, ExamScoreReader, BehaviouralScoreReader)
- [ ] `MarksheetComputationService`: full algorithm per Section 5 of Phase 2
- [ ] `ComputeMarksheetJob`: queued job, chunked per class section
- [ ] Views: SC-MSG-07 (Schedule Dashboard), SC-MSG-08 (Computation Progress with real-time update)
- [ ] Tests: ComputationTest (10 tests)

**Sprint 4 — Review, Publication & PDF (Target: 1.5 weeks)**

Tasks:
- [ ] `MarksheetPublicationService` extension: publish, lock, unlock + audit
- [ ] `MarksheetPdfService` (DomPDF)
- [ ] Views: SC-MSG-09 (Result Review Grid), SC-MSG-10 (Student Preview), SC-MSG-11 (Publication), SC-MSG-12 (PDF Download)
- [ ] Tests: PublicationTest (5 tests), PdfTest (4 tests)

**Sprint 5 — Student Portal & Parent Portal Integration (Target: 1 week)**

Tasks:
- [ ] Read-only API endpoints for StudentPortal and ParentPortal
- [ ] Marksheet view in StudentPortal (`msg.report.student` permission)
- [ ] Marksheet view in ParentPortal (`msg.report.student` permission, parent-scoped)
- [ ] PDF download for student/parent
- [ ] End-to-end integration test with StudentPortal

#### Section 5 — File Structure

Provide the complete file tree for the module:

```
Modules/MarksheetGeneration/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   └── [list all controllers]
│   │   └── Requests/
│   │       └── [list all FormRequests]
│   ├── Jobs/
│   │   └── ComputeMarksheetJob.php
│   ├── Models/
│   │   └── [one per msh_* table]
│   ├── Policies/
│   │   └── [list all policies]
│   └── Services/
│       └── [4 main + 5 score readers]
├── database/
│   └── seeders/
│       └── MarksheetGenerationDatabaseSeeder.php
├── resources/views/
│   └── [12 blade views]
└── routes/
    └── web.php
```

#### Section 6 — Cross-Module Dependencies & Risks

| Dependency | Module | Risk | Mitigation |
|---|---|---|---|
| lms_exam_types distinguishes online/offline | LmsExam | Schema assumption | Verify in Pre-Dev Checklist |
| lms_exam_marks_entry has is_absent | LmsExam | Schema assumption | Verify in Pre-Dev Checklist |
| BehaviouralScoreService exists | BehaviouralAssessment | Module not yet built | Implement interface + stub; wire up when BA is ready |
| sch_class_groups relationship | SchoolSetup | Inheritance logic depends on this | Verify SchoolSetup DDL |
| StudentPortal/ParentPortal API contract | StudentPortal, ParentPortal | Integration risk if portals aren't ready | Expose controller endpoints early |

#### Section 7 — Security Checklist

- [ ] Every controller method has `Gate::authorize()`
- [ ] All FormRequests have `authorize()` returning a real Gate check (NOT hardcoded `true`)
- [ ] Student marksheet access scoped to own student ID (IDOR prevention)
- [ ] Parent access scoped to linked children only
- [ ] Published lock enforced at service layer, not just UI
- [ ] Admin unlock requires explicit reason (stored in `msh_computation_logs`)
- [ ] PDF download URLs are signed (`URL::temporarySignedRoute`)

#### Section 8 — Open Questions (resolve before Sprint 1)

1. Should `msh_source_components` be seeded as fixed (6 rows) or allow school to add custom components?
2. If a student has ZERO attempts in Homework within the schedule range, is the component score NULL or 0? (Default: NULL — treat as "not assessed")
3. Should the Exam component support a "best of N" rule (e.g., best 3 out of 4 Unit Tests count)?
4. Practical exam marks: sourced from `lms_exam_marks_entry` only, or is there a separate offline entry for practicals?
5. When a class is assigned to both a class-group template AND a direct template, which wins? (Default: direct assignment wins)
6. Should Half Yearly marksheet include Homework/Quiz/Quest from the FULL half-year range, or only from a configurable "included assessments" list?
7. Is grade calculation (A+, A, B, etc.) owned by this module, or delegated to HPC?

---

**STOP AFTER PHASE 4.** Output `{OUTPUT_DIR}/MSG_Dev_Plan.md`.

All 4 output files are now complete. Review and confirm before starting implementation.

---

## QUICK REFERENCE — Source Module Tables

### LmsHomework
- `lms_homework` — homework definition (subject, class_section, max_marks, due_date)
- `lms_homework_assignment` — assignment to students
- `lms_homework_submissions` — student submission with score

### LmsQuiz
- `lms_quizzes` — quiz definition (subject, session, total_marks)
- `lms_quiz_allocations` — quiz assigned to class_section
- `lms_quiz_quest_results` — student result (shared with Quest)

### LmsQuest
- `lms_quests` — quest definition
- `lms_quest_allocations` — quest assigned to class_section
- `lms_quiz_quest_results` — student result (shared with Quiz)

### LmsExam
- `lms_exam_types` — defines Online vs Offline type
- `lms_exams` — exam master (UT1, UT2, Half Yearly, Annual, etc.)
- `lms_exam_scopes` — exam linked to class_section + subject
- `lms_exam_results` — online exam auto-scored results
- `lms_exam_marks_entry` — offline exam manual marks (includes `is_absent`)
- `lms_exam_attempts` — online exam attempt records

### BehaviouralAssessment
- `ba_computed_scores` — cached per-student behavioural scores
- `ba_config` — session config including `is_result_integration_enabled`
- API: `BehaviouralScoreService::getStudentScore(studentId, periodId)`

### Cross-Module Reference Tables (from SchoolSetup + StudentProfile)
- `sch_classes` — class master
- `sch_class_groups` — class group (e.g., "Primary", "Middle", "Secondary")
- `sch_class_sections` — class × division combination
- `sch_class_section_jnt` — students assigned to class sections
- `sch_academic_sessions` — current and past academic sessions
- `std_students` — student master
