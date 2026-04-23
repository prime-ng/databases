# Context: MarksheetGeneration Module — Complete Design (Requirement + DDL + Dev Plan + Screen Specs)
# Saved: 2026-04-13 19:50
# Session Duration: ~3 hours
# Project: PrimeAI

---

## 1. SESSION OBJECTIVE
Design the complete MarksheetGeneration (MSG) module for Prime-AI — a school result aggregation and marksheet configuration engine that consolidates marks from 5 independent scoring modules (LmsExam, LmsHomework, LmsQuiz, LmsQuest, BehaviouralAssessment) into configurable Indian K-12 marksheets (CBSE/ICSE/State Board format). The task was to execute a multi-phase development lifecycle prompt that produces: Requirement Specification, DDL Schema, Data Dictionary, Development Plan, and Screen Design Specifications.

## 2. SUMMARY OF WORK DONE
- Evaluated v1 prompt created by Claude Sonnet, found 5 critical errors and 11 missing features
- Created enhanced v2 prompt (`MSG_Module_Prompt_v2.md`) with all corrections
- Executed Phase 1: Generated `MSG_RequirementSpec.md` — 28 BRs, 30 FRs, 18 use cases, 15+ screens, full computation algorithm, 13 open questions
- Executed Phase 2: Generated `MSG_DDL_v1.sql` (23 tables, MySQL 8.x) + `MSG_DataDictionary.md` (full column specs, FK types verified, sample data, ER diagram)
- Executed Phase 3: Generated `MSG_Dev_Plan.md` — 5 sprints / ~9.5 weeks, 10 services, 10 controllers, 23 models, 51 Pest tests, security checklist, migration plan
- Created Screen Design Specification (4 files) — 19 screens with ASCII wireframes, field-to-DDL mapping, validation rules, role-based access, data sources, navigation flow
- Updated AI Brain: D32 decision in `decisions.md`, MSG entry in `progress.md`, new memory file
- Read and verified ALL source module DDLs: LMS_Homework_DDL_v4, LMS_Quiz_ddl_v2, LMS_Quest_ddl_v2, LMS_Exam_ddl_v5, StudentAttempt_ddl_v3, BA_DDL_v2, tenant_db_v2 (sch_classes, sch_subjects, sch_class_section_jnt, slb_grade_division_master, sys_dropdown_table, sch_org_academic_sessions_jnt, std_students)

## 3. FILES TOUCHED
### Created:
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-Work_with_CLAUDE/Marksheet_Generation/MSG_Module_Prompt_v1.md` — Initial prompt (v1, by Sonnet)
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-Work_with_CLAUDE/Marksheet_Generation/MSG_Module_Prompt_v2.md` — Enhanced prompt (v2, by Opus) with all error fixes and new features
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/55h-MarksheetGeneration/MSG_RequirementSpec.md` — Phase 1 output: full requirement specification
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/55h-MarksheetGeneration/MSG_DDL_v1.sql` — Phase 2 output: 23-table DDL schema
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/55h-MarksheetGeneration/MSG_DataDictionary.md` — Phase 2 output: full data dictionary
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/55h-MarksheetGeneration/MSG_Dev_Plan.md` — Phase 3 output: sprint plan + service architecture
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/55h-MarksheetGeneration/Design/00_Screen_Index_Navigation.md` — Screen master index + navigation flow diagram
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/55h-MarksheetGeneration/Design/01_Masters_Configuration_Screens.md` — 8 screens: Types, Class Groups, Exam Groups, Template Builder (5 tabs), Assignment, Practical Config
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/55h-MarksheetGeneration/Design/02_Schedule_Entry_Screens.md` — 7 screens: Dashboard, Setup, Progress, IA Entry, Co-Scholastic Entry, Attendance Entry, Review Grid
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/55h-MarksheetGeneration/Design/03_Review_Publication_Portal_Screens.md` — 5 screens: Student Preview, Publication & Lock, PDF Download, Student Portal, Parent Portal
- `/Users/bkwork/.claude/projects/-Users-bkwork-Herd-prime-ai/memory/project_marksheet_generation_2026_04_13.md` — Auto-memory file for future sessions

### Modified:
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/state/decisions.md` — Added D32 (MarksheetGeneration architecture)
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/state/progress.md` — Added MSG entry under "Pending Modules"
- `/Users/bkwork/.claude/projects/-Users-bkwork-Herd-prime-ai/memory/MEMORY.md` — Added index entry for MSG memory

### Discussed/Reviewed (not modified):
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/config/paths.md` — Path resolution for prompt variables
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/memory/project-context.md` — Project context
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/memory/modules-map.md` — Full module inventory
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/rules/tenancy-rules.md` — Tenancy rules (no tenant_id)
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/rules/module-rules.md` — Module conventions
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/52a-LMS_Homework/DDL/LMS_Homework_DDL_v4.sql` — Homework DDL (score columns verified)
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/53b-LMS_Quiz/DDL/LMS_Quiz_ddl_v2.sql` — Quiz DDL (score columns verified)
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/54c-LMS_Quest/DDL/LMS_Quest_ddl_v2.sql` — Quest DDL (score columns verified)
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/55d-LMS_Exam/DDL/LMS_Exam_ddl_v5.sql` — Exam DDL (full read, architecture corrections found)
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/55e-LMS_StudentAttempts/DDL/StudentAttempt_ddl_v3.sql` — Attempts/Results DDL (full read)
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/55g-BehaviouralAssessment/DDL/BA_DDL_v2.sql` — BA DDL (structure verified)
- `/Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/tenant_db_v2.sql` — Verified: sch_classes, sch_subjects, sch_class_section_jnt, slb_grade_division_master, sys_dropdown_table, sch_org_academic_sessions_jnt, std_students
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/5-Work-In-Progress/2-In-Progress/BehaviouralAssessment/Prompt/BA_Module_Prompt_v1.md` — Reference for prompt structure

## 4. KEY DECISIONS & RATIONALE

- **Decision D32:** MarksheetGeneration is a new tenant module with prefix `msh_*` (23 tables), read-only integration with 5 source modules
  **Why:** No consolidated result engine exists. Schools need CBSE/ICSE-format marksheets.
  **Alternatives Considered:** Extending LmsExam module — rejected because marksheet is cross-module aggregation

- **Decision D-MSG-003:** Created `msh_class_groups` as a NEW table separate from `sch_class_groups_jnt`
  **Why:** `sch_class_groups_jnt` is a timetable-specific junction (class+section+subject+study_format). It is NOT a simple class grouping like "Primary/Middle/Secondary".
  **Alternatives Considered:** Using `sch_class_groups_jnt` — rejected after reading actual DDL and confirming it's timetable-specific

- **Decision D-MSG-004:** Online/Offline exam mode is transparent to marksheet
  **Why:** Both modes produce `lms_exam_results`. The distinction is per-paper (`lms_exam_papers.mode`), not per-exam. v1 prompt incorrectly split them as separate source components.
  **Alternatives Considered:** Separate weightage for Online vs Offline — rejected because it contradicts the actual data model

- **Decision D-MSG-005:** Absent flag read from `lms_exam_results.result_status = 'ABSENT'`
  **Why:** v1 incorrectly assumed `lms_exam_marks_entry.is_absent`. Actual DDL has no such column. Absent is on `lms_exam_attempts.status` and `lms_exam_results.result_status`.

- **Decision D-MSG-006:** IA marks (Notebook, Subject Enrichment) owned by MSG module
  **Why:** No other module captures these marks. Teacher entry via MSG's own screen (SC-MSG-12a).

- **Decision D-MSG-007:** Co-Scholastic grades owned by MSG module, with BA auto-populate for Discipline
  **Why:** No other module captures Work Education, Art Education, Health & PE grades. Discipline links to BehaviouralAssessment via `BehaviouralScoreService`.

- **Decision:** No ENUMs in any `msh_*` table — all status/type fields use `sys_dropdown_table`
  **Why:** Project-wide rule D29. `msh_marksheet_schedules.status_id` uses sys_dropdown_table with seeded values: DRAFT, COMPUTED, REVIEWED, PUBLISHED, LOCKED.

- **Decision:** `msh_class_config_jnt` has CHECK constraint ensuring exactly one of `class_id` or `class_group_id` is set
  **Why:** A config assignment targets either a direct class OR a class-group, never both. CHECK prevents data corruption.

- **Decision:** Theory vs Practical identified by matching `lms_exam_papers.total_marks` against `msh_subject_practical_configs` (Option C)
  **Why:** `lms_exam_papers` has no `is_practical` flag. Open Question Q-13 — must be resolved before Sprint 3.

## 5. TECHNICAL DETAILS & PATTERNS

- **Score column references (verified from actual DDLs):**
  - Homework: `lms_homework_submissions.marks_obtained` (DECIMAL 5,2), `lms_homework.max_marks` (DECIMAL 5,2)
  - Quiz/Quest: `lms_quiz_quest_results.total_marks_obtained` (DECIMAL 8,2), `.max_marks`, `.percentage`, `.assessment_type` ENUM('QUIZ','QUEST')
  - Exam: `lms_exam_results.total_marks_obtained` (DECIMAL 8,2), `.total_marks_possible`, `.percentage`, `.grade_obtained`, `.result_status` ENUM('PASS','FAIL','ABSENT','WITHHELD')
  - BA: `BehaviouralScoreService::getStudentScore(studentId, periodId)` → `{ numeric_score, grade, category_scores[] }`

- **FK type map (verified from tenant_db_v2.sql):**
  - `sch_classes.id` = INT UNSIGNED
  - `sch_org_academic_sessions_jnt.id` = SMALLINT UNSIGNED (not INT!)
  - `std_students.id` = INT UNSIGNED
  - `sys_dropdown_table.id` = INT UNSIGNED
  - `slb_grade_division_master.id` = INT UNSIGNED

- **Computation algorithm:** 7-step process (A through G) documented in RequirementSpec Section 10. Steps: Exam marks → HW/Quiz/Quest aggregation → IA marks → Subject totals + grade → Co-Scholastic → Attendance → Overall aggregation (rank, division, promotion)

- **Livewire components:** 2 needed — ComputationProgressComponent (2s polling) and ResultReviewGridComponent (dynamic columns, sorting)

- **DomPDF pattern:** Follows D13 HPC pattern — inline styles, table-based layout, no flexbox/grid, no JS, no Bootstrap classes

- **Screen count:** 19 total (8 config + 7 schedule/entry + 4 review/publication/portal)

## 6. DATABASE CHANGES

- 23 new `msh_*` tables designed in `MSG_DDL_v1.sql`:
  - Masters: `msh_marksheet_types`, `msh_source_components`, `msh_ia_component_types`
  - Config: `msh_class_groups`, `msh_class_group_items_jnt`, `msh_exam_groups`, `msh_exam_group_items_jnt`, `msh_config_templates`, `msh_template_scholastic_components`, `msh_template_exam_weightages`, `msh_template_ia_components`, `msh_template_coscholastic_components`, `msh_class_config_jnt`, `msh_subject_practical_configs`
  - Schedule: `msh_marksheet_schedules`, `msh_schedule_class_jnt`
  - Results: `msh_student_results`, `msh_student_subject_results`, `msh_student_subject_exam_marks`, `msh_student_ia_marks`, `msh_student_coscholastic_results`, `msh_student_attendance`
  - Audit: `msh_computation_logs` (no deleted_at — immutable)
- 23 tenant migrations listed in dependency order
- Seeders: `msh_source_components` (4 rows), `msh_ia_component_types` (4 rows), `sys_dropdown_table` (5 status values)
- NO changes to any existing tables

## 7. PROBLEMS ENCOUNTERED & SOLUTIONS

- **Problem:** v1 prompt assumed `lms_exam_types.type` distinguishes Online/Offline
  **Cause:** `lms_exam_types` stores exam categories (UT-1, HY-EXAM), not modes. Online/Offline is per-paper.
  **Solution:** Corrected in v2 — read `lms_exam_papers.mode` but treat as transparent at marksheet level

- **Problem:** v1 assumed `is_absent` on `lms_exam_marks_entry`
  **Cause:** Column doesn't exist there. Absent flag is on `lms_exam_attempts.status` and `lms_exam_results.result_status`
  **Solution:** Corrected all references to use `lms_exam_results.result_status = 'ABSENT'`

- **Problem:** `sch_class_groups_jnt` is not usable for marksheet class grouping
  **Cause:** It's a timetable junction (class+section+subject+study_format+subject_type), not a simple grouping
  **Solution:** Created `msh_class_groups` + `msh_class_group_items_jnt` as MSG-owned tables

- **Problem:** v1 DDL path for StudentAttempts was wrong (`LMS_StudentAttempts_ddl_v2.sql`)
  **Cause:** File was renamed to `StudentAttempt_ddl_v3.sql`
  **Solution:** Fixed path in v2 prompt

- **Problem:** No `is_practical` flag on `lms_exam_papers` to distinguish theory vs practical papers
  **Cause:** DDL doesn't include this column
  **Solution:** Proposed Option C — match by `total_marks` against `msh_subject_practical_configs`. Flagged as Open Question Q-13 (critical, must resolve before Sprint 3)

## 8. CURRENT STATE OF WORK
### Completed:
- v2 prompt created and saved
- Phase 1 (RequirementSpec) — APPROVED
- Phase 2 (DDL + Data Dictionary) — APPROVED
- Phase 3 (Dev Plan) — APPROVED
- Screen Design Specification (4 files, 19 screens) — COMPLETED
- AI Brain updated (D32 decision, progress entry, memory file)

### In Progress:
- None — all design phases complete

### Not Yet Started:
- Actual Laravel module implementation (Sprint 1-5)
- Blade view implementation (requires `/frontend` or `/frontend-design` skill)
- Resolution of 13 Open Questions (particularly Q-13: theory/practical paper identification)
- Pre-development verification checklist (V-01 through V-10 against actual DB)

## 9. OPEN QUESTIONS & TODOS
- [ ] Q-01: `msh_source_components` — fixed 4 rows or school-extensible?
- [ ] Q-02: Student with ZERO graded HW/Quiz — NULL or 0? (Default assumption: NULL)
- [ ] Q-03: Best-of-N for unit tests — include in Sprint 1 or defer?
- [ ] Q-04: IA marks — this module owns entry (assumed YES)
- [ ] Q-05: Attendance module exists? (assumed NO — manual entry Phase 1)
- [ ] Q-06: Co-Scholastic entry — this module owns it (assumed YES)
- [ ] Q-08: Student subject list source — `sch_class_groups_jnt` or another table?
- [?] **Q-13 (CRITICAL):** `lms_exam_papers` has no `is_practical` flag. Must resolve before Sprint 3. Options: (a) add migration, (b) naming convention, (c) match by total_marks against config
- [ ] Q-09: Promotion criteria configurable? (assumed YES — `compartment_max_failures` field)
- [ ] Q-10: PDF format — one standard or school-specific templates?
- [ ] Q-11: HW/Quiz/Quest date range vs specific assessment selection?
- [ ] Q-12: Grade calculation — this module computes own grades (assumed YES)
- [ ] Run pre-development verification V-01 through V-10 against actual tenant DB

## 10. IMPORTANT CONTEXT FOR FUTURE SESSIONS

- **Module output directory:** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/55h-MarksheetGeneration/`
- **Prompt file (v2):** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-Work_with_CLAUDE/Marksheet_Generation/MSG_Module_Prompt_v2.md`
- **Decision ID:** D32 in `AI_Brain/state/decisions.md`
- **Table prefix:** `msh_*` (23 tables)
- **Branch name:** `marksheet-generation`
- **Route prefix:** `marksheet-generation/`
- **Module name:** `Modules\MarksheetGeneration`
- **Score reader interface:** `ScoreReaderInterface` with `getScores(classSectionId, subjectId, sessionId, fromDate, toDate)` signature
- **Status lifecycle:** DRAFT → COMPUTED → REVIEWED → PUBLISHED → LOCKED (stored in `sys_dropdown_table`)
- **Key constraint:** `sch_org_academic_sessions_jnt.id` is SMALLINT UNSIGNED (not INT) — FK columns must match
- **BehaviouralAssessment integration:** Pull-based via `BehaviouralScoreService::getStudentScore()`. Only if `ba_config.is_result_integration_enabled = true`
- **User prefers:** Business Analyst + Enterprise Architect role for planning/design; `/frontend-design` or `/frontend` skill for actual Blade implementation

## 11. DEPENDENCIES & CROSS-MODULE REFERENCES

| Module | Dependency Type | Tables Used |
|---|---|---|
| LmsExam | Read-only query | `lms_exam_results`, `lms_exam_papers`, `lms_exams`, `lms_exam_types` |
| LmsHomework | Read-only query | `lms_homework`, `lms_homework_submissions` |
| LmsQuiz | Read-only query | `lms_quizzes`, `lms_quiz_quest_results` |
| LmsQuest | Read-only query | `lms_quests`, `lms_quiz_quest_results` |
| BehaviouralAssessment | Service call | `BehaviouralScoreService`, `ba_config`, `ba_computed_scores` |
| SchoolSetup | Read-only query | `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_subjects`, `sch_employees` |
| Syllabus | Read-only query | `slb_grade_division_master` |
| StudentProfile | Read-only query | `std_students`, `std_student_academic_sessions` |
| StudentPortal | Portal integration | Read-only marksheet view endpoints |
| ParentPortal | Portal integration | Read-only marksheet view endpoints |

## 12. CONVERSATION HIGHLIGHTS — RAW NOTES

- User started by asking to create a Marksheet Generation prompt. Sonnet created v1, then user switched to Opus for evaluation + enhancement.
- v1 had 5 critical errors — all found by reading actual DDL files (not just assuming column names).
- The `sch_class_groups_jnt` discovery was unexpected — every reference in the codebase to "class groups" actually means the timetable junction, NOT a simple grouping. This required creating `msh_class_groups`.
- `slb_grade_division_master` has `grading_type ENUM('GRADE','DIVISION')` with `min_percentage`/`max_percentage` ranges + `board_code` + `scope` + `class_id` — perfect for marksheet grading.
- `sch_org_academic_sessions_jnt.id` is SMALLINT UNSIGNED — a potential gotcha for FK definitions.
- User explicitly approved each phase before proceeding to the next.
- Screen designs include ASCII wireframes — can be directly used as reference for `/frontend-design` skill.
- User's linter made minor whitespace adjustments to the Design files — these are intentional and should not be reverted.

---
*End of Context Save*
