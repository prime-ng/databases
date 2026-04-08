# Context: StudentPortal StudentAttempt DDL v2 Schema Design
# Saved: 2026-04-02 16:09
# Session Duration: ~1 hour (roles activated → requirements read → DDL created → AI_Brain updated)
# Project: PrimeAI

---

## 1. SESSION OBJECTIVE

Design and create an enhanced DDL schema (`StudentAttempt_ddl_v2.sql`) for the StudentAttempt functionality in the StudentPortal module. The v1 DDL had critical issues (duplicate table definitions, missing standard columns, no result table for quiz/quest). v2 needed to be clean, complete, and aligned with the full LMS requirement spec.

---

## 2. SUMMARY OF WORK DONE

- Activated dual roles: **Business Analyst + DB Architect** (read `AI_Brain/agents/business-analyst.md` + `AI_Brain/agents/db-architect.md`)
- Read all 4 LMS v4 documentation files from `5-Work-In-Progress/2-In-Progress/LMS/v4/` (requirements, rules, code review, summary index)
- Read StudentPortal V2 requirement: `2-Requirement_Module_wise/2-Detailed_Requirements/V2/STP_StudentPortal_Requirement.md`
- Analyzed v1 DDL: `1-DDL_Tenant_Modules/55e-LMS_StudentAttempts/StudentAttempt_ddl_v1.sql` — identified 3 duplicate table definitions, missing columns, no quiz/quest result table
- Created **`StudentAttempt_ddl_v2.sql`** with 10 complete tables (see Section 6)
- Updated **`AI_Brain/memory/progress.md`** — StudentPortal status updated to ~55%
- Updated **`AI_Brain/memory/student-parent-portal.md`** — added StudentAttempt DDL section, updated screen status table to V2 (35 screens)
- Updated **Claude project `MEMORY.md`** — added StudentPortal current state + DDL entry for future sessions

---

## 3. FILES TOUCHED

### Created:
- `databases/1-DDL_Tenant_Modules/55e-LMS_StudentAttempts/StudentAttempt_ddl_v2.sql`
  — Complete DDL with 10 tables for Quiz/Quest/Exam attempts, results, grievances, proctoring logs, session checkpoints

### Modified:
- `AI_Brain/memory/progress.md`
  — Updated StudentPortal from ~28% → ~55%; added current work entry for StudentAttempt DDL
- `AI_Brain/memory/student-parent-portal.md`
  — Added V2 requirement file path, added StudentAttempt DDL v2 section (10 tables + design notes), replaced old S1-S27 table with accurate V2 screen status (35 screens, 22✅/8🟡/5❌)
- `/Users/bkwork/.claude/projects/-Users-bkwork-WorkFolder-1-Development-0-Git-Work-prime-ai-db-databases/memory/MEMORY.md`
  — Added StudentPortal status block with DDL path, critical gaps, and design decisions

### Discussed/Reviewed (not modified):
- `5-Work-In-Progress/2-In-Progress/LMS/v4/lms_summary_index.md` — LMS module overview, issue counts, stats
- `5-Work-In-Progress/2-In-Progress/LMS/v4/lms_rules_conditions.md` — Validation rules, CRUD conditions, business rules, lifecycle workflows, allocation types
- `2-Requirement_Module_wise/2-Detailed_Requirements/V2/STP_StudentPortal_Requirement.md` — Full StudentPortal V2 spec (FR-STP-01 to FR-STP-30)
- `databases/1-DDL_Tenant_Modules/55e-LMS_StudentAttempts/StudentAttempt_ddl_v1.sql` — Original v1 (issues documented below)

---

## 4. KEY DECISIONS & RATIONALE

- **Decision:** Unified `lms_quiz_quest_attempts` table for both Quiz and Quest
  **Why:** Both modules have identical attempt architecture; unifying avoids duplication and simplifies StudentPortal aggregation queries (My Learning hub reads both types in one query)
  **Alternatives Considered:** Separate `lms_quiz_attempts` + `lms_quest_attempts` tables

- **Decision:** Renamed `lms_student_attempts` → `lms_exam_attempts`
  **Why:** "lms_student_attempts" is ambiguous — could mean any type of attempt. "lms_exam_attempts" is specific to exams.

- **Decision:** Created `lms_quiz_quest_results` as a new table (was missing in v1)
  **Why:** v1 had no result record for quiz/quest — only `lms_exam_results` existed. The StudentPortal "My Results" screen needs a result record for all assessment types. Results are separate from attempts because they represent the final evaluated/published state.

- **Decision:** `lms_exam_results` UNIQUE on `(exam_paper_id, student_id)` not `(exam_id, student_id)`
  **Why:** v1 used `(exam_id, student_id)` but one exam can have multiple papers (one per subject). The correct granularity is one result per paper per student. Changed from v1.

- **Decision:** Added `lms_attempt_checkpoints` table
  **Why:** Online exams/quizzes can be interrupted by browser crashes. Without checkpoints, the student loses all answers. Auto-save to checkpoint every 60s (per architecture notes) and restore on reload. UPSERT pattern — one row per active attempt.

- **Decision:** `lms_attempt_activity_logs` is polymorphic on `attempt_type` (QUIZ/QUEST/EXAM)
  **Why:** v1 only covered EXAM. Quiz and Quest online attempts also need proctoring logs. Unified table avoids 3 separate identical tables.

- **Decision:** No soft delete (`deleted_at`) on activity logs and checkpoints
  **Why:** Activity logs are immutable audit records — should not be soft-deleted. Checkpoints are ephemeral — deleted when attempt is submitted (application responsibility). No `created_by` either — system-generated events.

- **Decision:** Added `selected_option_ids` (JSON) to both answer tables
  **Why:** Multi-MCQ questions need to store multiple selected option IDs. v1 only had `selected_option_id` (single). Both single-MCQ and multi-MCQ are needed to cover all question types in QuestionBank.

- **Decision:** FK strategy: RESTRICT for core, CASCADE for children, SET NULL for optional
  **Why:** RESTRICT on `student_id`, `exam_paper_id`, `lms_exams` prevents accidental data loss. CASCADE on answer tables when attempt is deleted. SET NULL on `allocation_id`, `evaluated_by`, `attempt_id` (in results) because these are optional references.

- **Decision:** `lms_exam_attempts` keeps UNIQUE on `(exam_paper_id, student_id)` — one attempt per paper
  **Why:** Exams are generally single-attempt. The unique constraint can be removed via migration if re-attempts are ever needed. Better to be strict now.

---

## 5. TECHNICAL DETAILS & PATTERNS

- **Standard columns on all tables:** `is_active TINYINT(1)`, `created_by INT UNSIGNED`, `created_at TIMESTAMP`, `updated_at TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`, `deleted_at TIMESTAMP NULL`
  - Exception: activity logs and checkpoints omit `deleted_at` (reasons above)
- **UUID storage:** `BINARY(16)` on `lms_quiz_quest_attempts` and `lms_exam_attempts` for compact unique identifiers
- **Polymorphic pattern used in:** `assessment_type`+`assessment_id` (quiz/quest attempts), `attempt_type`+`attempt_id` (logs + checkpoints) — no FK constraint on these columns
- **Caching pattern:** `question_type_id` is cached in answer tables to avoid JOIN on evaluation. `assessment_id`+`assessment_type` cached in `lms_quiz_quest_results` for fast StudentPortal queries.
- **Attempt numbering:** `attempt_number TINYINT` increments per `(student_id, assessment_type, assessment_id)`. UNIQUE constraint enforces no duplicate attempt numbers.
- **Proctoring fields on all attempt tables:** `ip_address VARCHAR(45)` (IPv6 compatible), `browser_agent TEXT`, `device_info JSON`, `violation_count INT`
- **Telemetry on all answer tables:** `time_spent_seconds INT`, `change_count SMALLINT` — both for analytics and anti-cheat
- **Evaluation pattern:** `is_evaluated TINYINT(1)` + `evaluated_by` (NULL = auto-graded by system, non-NULL = teacher) + `evaluated_at` + `evaluation_remarks`
- **Table naming convention:** `lms_` prefix throughout; plural nouns; `_jnt` suffix not needed here (no junction tables in this DDL)

---

## 6. DATABASE CHANGES

All tables are NEW (v2 supersedes v1 — v1 file not deleted, kept for reference).

| Table | Purpose |
|---|---|
| `lms_quiz_quest_attempts` | Unified attempt record — QUIZ or QUEST (polymorphic `assessment_type`) |
| `lms_quiz_quest_attempt_answers` | Per-question responses for Quiz/Quest (MCQ, Multi-MCQ, Descriptive, File) |
| `lms_quiz_quest_results` | Final evaluated/published result for Quiz/Quest attempt |
| `lms_exam_attempts` | Exam attempt record — ONLINE or OFFLINE mode |
| `lms_exam_attempt_answers` | Per-question responses for Exam (same structure as quiz/quest answers) |
| `lms_exam_marks_entry` | Bulk total marks entry — for OFFLINE exams in BULK_TOTAL mode only |
| `lms_exam_results` | Final consolidated exam result — drives StudentPortal results view + HPC |
| `lms_exam_grievances` | Student re-evaluation requests on published exam results |
| `lms_attempt_activity_logs` | Proctoring/behavioral event log — polymorphic (QUIZ/QUEST/EXAM) |
| `lms_attempt_checkpoints` | Session save-state for resume after browser crash — UPSERT pattern |

**File:** `databases/1-DDL_Tenant_Modules/55e-LMS_StudentAttempts/StudentAttempt_ddl_v2.sql`

**External Tables Referenced (FKs into other modules):**
- `std_students` (StudentProfile)
- `sys_users` (SystemConfig)
- `sys_media` (SystemConfig)
- `qns_questions_bank`, `qns_question_options` (QuestionBank)
- `lms_quizzes`, `lms_quiz_allocations` (LmsQuiz)
- `lms_quests`, `lms_quest_allocations` (LmsQuests)
- `lms_exams`, `lms_exam_papers`, `lms_exam_paper_sets`, `lms_exam_allocations` (LmsExam)

---

## 7. PROBLEMS ENCOUNTERED & SOLUTIONS

- **Problem:** v1 DDL had `lms_student_attempts` defined TWICE, `lms_exam_results` defined TWICE, `lms_exam_grievances` defined TWICE — both versions had different columns and FK references
  **Cause:** v1 was assembled from two separate draft sessions with no deduplication
  **Solution:** Analyzed both versions of each duplicate table, merged best fields from each into a single clean v2 definition

- **Problem:** v1 had no result table for Quiz/Quest attempts
  **Cause:** v1 only modeled exam flow; quiz/quest result state was not considered
  **Solution:** Added `lms_quiz_quest_results` as a new table mirroring the `lms_exam_results` pattern

- **Problem:** LMS requirement files were too large to read in one call (43K+ tokens)
  **Cause:** `lms_requirements.md` is ~600KB, `lms_rules_conditions.md` ~80KB
  **Solution:** Read in sections (200 lines at a time), focused on sections relevant to attempts: Section 5 (Workflow Lifecycle), Section 6 (Allocation Rules), Section 3 (Business Rules)

- **Problem:** StudentPortal V2 requirement file was 21K tokens
  **Cause:** Comprehensive 16-section document
  **Solution:** Read in 250-line chunks focusing on FR-STP-11 (My Learning), FR-STP-09 (Exam Schedule), FR-STP-10 (Results), FR-STP-30 (Online Exam/Quiz Player stubs), Section 5 (Data Model), Section 8 (Business Rules)

---

## 8. CURRENT STATE OF WORK

### Completed:
- `StudentAttempt_ddl_v2.sql` — 10 tables, complete, ready for migration review
- AI_Brain memory files updated (progress.md, student-parent-portal.md)
- Claude project MEMORY.md updated

### In Progress:
- Nothing — clean stopping point after DDL creation + memory update

### Not Yet Started:
- Laravel migrations for the 10 tables (needs to go into `database/migrations/tenant/`)
- Models for each table (e.g., `QuizQuestAttempt`, `ExamAttempt`, `ExamResult`, etc.)
- Controllers/Services for StudentPortal attempt flow
- FR-STP-30 implementation (Online Exam/Quiz/Quest player screens — currently stubs)
- FR-STP-16 (homework submission endpoint — missing)
- FR-STP-17 (results with actual marks — needs `ExamResult` integration)
- Exam player anti-cheat: fullscreen enforcement, tab-switch detection, auto-save, auto-submit

---

## 9. OPEN QUESTIONS & TODOS

- [ ] **Migration files** — Create 10 tenant migration files for the v2 DDL tables
- [ ] **Model creation** — Create Laravel Eloquent models for all 10 tables in `Modules/StudentPortal/` or shared location
- [ ] **Quiz/Quest player** — Wire `quiz/index.blade.php` and `quest/index.blade.php` to routes; implement player controller
- [ ] **Online exam player** — Implement `online-exam/index.blade.php` with anti-cheat + `lms_exam_attempts` integration
- [ ] **Homework submission** — Add `POST student-portal/homework/{homework}/submit` endpoint
- [ ] **Results with marks** — Integrate `lms_exam_results` into `/student-portal/results` view
- [ ] **IDOR fix (P0)** — Fix `proceedPayment()` — `payable_id` must be server-side verified against student ownership
- [ ] **Security** — Add `Gate::authorize()` calls to all 7 StudentPortal controllers (currently zero)
- [ ] **FormRequests** — Create `StoreComplaintRequest`, `ProcessPaymentRequest` minimum
- [ ] **Checkpoint auto-save** — Implement client-side auto-save every 60s during online exams/quizzes (writes to `lms_attempt_checkpoints`)
- [?] **Re-attempts for exams** — Currently UNIQUE on (exam_paper_id, student_id). If re-attempts ever needed, remove UNIQUE and use attempt_number pattern like quiz/quest
- [?] **Homework attempts** — `lms_homework_submissions` in LmsHomework module handles submission tracking. Do we need a `lms_homework_results` table in this module for result/grade data, or does `HomeworkSubmission.marks_obtained` suffice?

---

## 10. IMPORTANT CONTEXT FOR FUTURE SESSIONS

**StudentPortal module location:** `Modules/StudentPortal/` (nwidart/laravel-modules v12)
**StudentPortal prefix:** `stp_` — but module owns ZERO tables; reads exclusively from other modules' tables
**Middleware:** `role:Student|Parent` (Spatie) at RouteServiceProvider level — no `EnsureTenantHasModule`
**Auth:** Same `sys_users` table as admin; `user_type = 'STUDENT'` or `'PARENT'`; Spatie role `Student` | `Parent`

**Critical security issue (P0):** `proceedPayment()` in `StudentPortalController` accepts `payable_id` from client without ownership verification — IDOR vulnerability. Must fix before any production deployment.

**LMS modules status (as of 2026-04-02):**
- LmsQuiz: ~90% — student attempt tracking absent
- LmsQuests: ~85% — student progress tracking absent
- LmsExam: ~90% — student grading absent
- LmsHomework: ~80% — no HomeworkPolicy (CR-002), `SchAcademicSession::class` undefined bug (CR-006)

**StudentAttempt DDL file:** `databases/1-DDL_Tenant_Modules/55e-LMS_StudentAttempts/StudentAttempt_ddl_v2.sql`

**Table naming in STP requirement doc uses different prefixes** (`hmw_`, `quz_`, `qst_`, `exm_`) vs actual code (`lms_`). Stick with `lms_` prefix used in actual module tables.

**LMS v4 docs location (working repo):**
`5-Work-In-Progress/2-In-Progress/LMS/v4/` (note: NOT the DB_REPO path)
- `lms_requirements.md` — master requirements (~600KB)
- `lms_rules_conditions.md` — rules, validations, workflows (~80KB)
- `lms_code_review.md` — 43 issues with severity ratings (~80KB)
- `lms_summary_index.md` — navigation index

**STP V2 requirement location:** `databases/2-Requirement_Module_wise/2-Detailed_Requirements/V2/STP_StudentPortal_Requirement.md`

**Branch:** `Brijesh` (current working branch)

---

## 11. DEPENDENCIES & CROSS-MODULE REFERENCES

| This DDL Table | Depends On | Module |
|---|---|---|
| All attempt tables | `std_students` | StudentProfile |
| All answer/evaluation tables | `sys_users` (evaluated_by) | SystemConfig |
| All answer tables | `qns_questions_bank`, `qns_question_options` | QuestionBank |
| `lms_quiz_quest_attempts` | `lms_quizzes`, `lms_quiz_allocations` | LmsQuiz |
| `lms_quiz_quest_attempts` | `lms_quests`, `lms_quest_allocations` | LmsQuests |
| `lms_exam_attempts` | `lms_exam_papers`, `lms_exam_paper_sets`, `lms_exam_allocations` | LmsExam |
| `lms_exam_results` | `lms_exams`, `lms_exam_papers` | LmsExam |
| `lms_exam_grievances` | `lms_exam_results` | This DDL |
| `lms_exam_attempt_answers` | `sys_media` (attachment_id) | SystemConfig |
| `lms_exam_attempts` | `sys_media` (offline_paper_uploaded_id) | SystemConfig |

**Used by (downstream):**
- StudentPortal: My Learning (FR-STP-11), Results (FR-STP-10), Online Exam Player (FR-STP-30)
- HPC Module: `lms_exam_results` feeds into report cards
- Performance Analytics (FR-STP-16): aggregates all result tables

---

## 12. CONVERSATION HIGHLIGHTS — RAW NOTES

**v1 DDL Issues Identified:**
1. `lms_student_attempts` — defined TWICE (lines 63-96 and 156-192); first version uses `paper_set_id`+`exam_paper_id`, second uses only `exam_id`
2. `lms_exam_results` — defined TWICE; first version (lines 239-263) uses `(exam_id, student_id)` UNIQUE, second version (lines 269-300) adds `attempt_id`, `rank_in_class`, `percentile`, `teacher_remarks`, etc.
3. `lms_exam_grievances` — defined TWICE; first (lines 305-320) minimal, second (lines 326-348) includes `marks_changed`, `old_marks`, `new_marks`, `resolved_at`
4. `lms_quiz_quest_attempt_answers` had syntax error: missing newline between `is_evaluated` column definition and `evaluated_by`
5. `lms_exam_marks_entry` missing `is_active`, `updated_at`, `deleted_at`
6. `lms_attempt_activity_logs` missing `is_active`
7. No result table for quiz/quest (only `lms_exam_results`)
8. No checkpoint table

**StudentPortal Completion Evidence (from V2 req doc):**
- 7 controllers: `StudentPortalController`, `StudentPortalComplaintController`, `NotificationController`, `StudentLmsController`, `StudentProgressController`, `StudentTeachersController`, `StudentTimetableController`
- Table prefix `stp_` — but zero owned tables (reads from external modules only)
- Known typo in Student model: `currentFeeAssignemnt` (missing 'g') — used in 3 controller methods
- `mark-read` notification uses GET (should be POST/PATCH — CSRF bypass risk)
- Hard-coded dropdown ID `104` in `StudentPortalComplaintController` lines 73 and 125

**LMS Status from Summary Index (as of 2026-03-19):**
- 47 controllers, 64 models, ~190 routes, 22 policies, 43 code review issues
- CRITICAL: CR-001 (API keys), CR-002 (no HomeworkPolicy), CR-031 (all Gate::authorize() commented in ExamBlueprintController)

**quiz/quest `canPublish()` conditions (from lms_rules_conditions.md §2.3):**
1. `questQuestions().count() > 0`
2. `questQuestions().count() === total_questions`
3. `validateSettings()` returns empty array
4. `academic_session_id`, `class_id`, `subject_id`, `lesson_id` all set

**Exam allocation types:** CLASS, SECTION, EXAM_GROUP, STUDENT
**Quiz/Quest allocation types:** CLASS, SECTION, GROUP, STUDENT (different name: GROUP vs EXAM_GROUP)

**`allow_multiple_attempts` + `max_attempts` pattern** (from QuizRequest rules):
- `allow_multiple_attempts`: boolean
- `max_attempts`: `required_if:allow_multiple_attempts=true`, integer, min:1, max:10
- This drives `attempt_number` increment logic in `lms_quiz_quest_attempts`

**Offline exam entry modes** (from ExamPaperRequest):
- `BULK_TOTAL` — teacher enters total marks only → uses `lms_exam_marks_entry`
- `QUESTION_WISE` — teacher enters per-question marks → uses `lms_exam_attempt_answers`

---
*End of Context Save*
