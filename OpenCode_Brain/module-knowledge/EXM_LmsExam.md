# Module Knowledge — LmsExam (EXM)

> Single source of accumulated knowledge for the LmsExam module. Seeded 2026-06-29 by Business Analyst
> from a live read of the Laravel module, DDL, and requirement sources. All counts verified against the
> filesystem — assert nothing not confirmed.

## Module Facts

| Fact | Value (verified 2026-06-29) |
|------|------------------------------|
| Module name / code / prefix | LmsExam / **EXM** / `lms_` (exam tables are `lms_exam*`) |
| Layer | Tenant (`tenant_db`) — data isolated per school (database-per-tenant) |
| App path | `/Users/bkwork/Herd/prime_ai/Modules/LmsExam` |
| Owned DDL | `2-DDL_Tenant_Consolidated/LmsExam_DDL_v6.sql` (11 CREATE TABLE) |
| Controllers | **13** (excl. `.gitkeep`) |
| Models | **13** |
| Services | **11** (10 `*UsageCheckService` delete-guards + 1 `ExamQueryService`) — NOT domain-logic services |
| FormRequests | **12** |
| Policy files | **21** in `app/Policies/` |
| Console commands | **1** (`PublishScheduledResults`) |
| Views (blade) | **92** across 19 folders |
| Seeders | **3** (`LmsExamDatabaseSeeder`, `LmsExamPaperCheckSeeder`, `LmsExamTypeSeeder`) |
| Tests | **0** (only `.gitkeep` in `tests/Unit`, `tests/Feature`) |
| Routes | All in module `routes/web.php` (D22 — module owns its routes); `routes/api.php` minimal |
| FRD | `EXM_FRD_Complete_2026-06-29.md` (this seeding cycle) |
| Estimated completion | **~80–85%** (revised UP from V2's "65%"; see "Status correction" below) |

### Status correction (IMPORTANT)
The V2 requirement (`EXM_LmsExam_Requirement.md`, dated 2026-03-26) states "~65% complete" and "the
student-facing attempt and grading pipeline is entirely absent — no attempt, result, grievance, or
report card controllers exist." **This is OUTDATED.** The live module (last touched 2026-06-17) now has:
- Offline answer-sheet upload (bulk + question-wise OMR) — `OfflineExamUploadMark`/`Detail` models + routes
- Answer evaluation / paper-check grading (online descriptive + offline), incl. bulk annotated-PDF upload
- Assessment progress dashboards (online & offline)
- Grievance / re-evaluation review (`GrievanceReviewController` + resolve workflow)
- Advanced reports (`ExamAdvancedReportController`, 6 report generators)
- Scheduled result publication (`PublishScheduledResults` console command)

Per the [2026-06-27] cross-module lesson: a seeded "65%/greenfield" figure means counts were not run
against the filesystem. Always `ls`/grep the live tree.

## Shared-prefix / cross-module table ownership (CRITICAL — `lms_` is shared)
`lms_` is shared by LmsExam, LmsQuiz, LmsHomework, LmsQuests, and the StudentAttempt engine. Attribution:

**Owned by LmsExam (`LmsExam_DDL_v6.sql`, 11 tables) — setup/definition layer:**
`lms_exam_types`, `lms_exam_status_events`, `lms_exam_student_groups`, `lms_exam_student_group_members`,
`lms_exams`, `lms_exam_papers`, `lms_exam_paper_sets`, `lms_exam_scopes`, `lms_exam_blueprints`,
`lms_paper_set_questions`, `lms_exam_allocations`.

**Runtime/result tables — exam-DOMAIN but DDL-OWNED by the StudentAttempt engine**
(`StudentAttempt_DDL_v4.sql`, also mirrored in `StudentPortal_DDL_v4.sql`):
`lms_exam_attempts`, `lms_exam_attempt_answers`, `lms_offline_exam_upload_marks`,
`lms_offline_exam_upload_detail`, `lms_exam_results`, `lms_exam_grievances`.
Cross-type (QUIZ/QUEST/EXAM polymorphic): `attemp_activity_event_types`, `lms_attempt_activity_logs`,
`lms_attempt_checkpoints`.
- **Model ownership is split:** `OfflineExamUploadMark` + `OfflineExamUploadDetail` models live in
  `Modules/LmsExam/app/Models/`, but `ExamResult` and `ExamGrievance` models live in
  **`Modules/StudentPortal/Models/`** (consumed by `GrievanceReviewController` via
  `use Modules\StudentPortal\Models\ExamGrievance` / `ExamResult`).
- The online attempt *player* (student taking the exam, writing `lms_exam_attempts` /
  `lms_exam_attempt_answers` / checkpoints) is a **StudentPortal** responsibility; LmsExam consumes the
  results for evaluation, results, grievance, and reporting.

**Naming drift to remember:** V2 doc used aspirational names (`lms_student_attempts`, `lms_exam_answers`,
`lms_exam_marks_entry`, `lms_exam_attempt_checkpoints`). Actual live names are `lms_exam_attempts`,
`lms_exam_attempt_answers`, `lms_offline_exam_upload_marks`/`_detail`, `lms_attempt_checkpoints`.

## DDL Table Inventory — owned (11)
| Table | Purpose | Key constraints |
|-------|---------|-----------------|
| `lms_exam_types` | Exam categories (UT-1, HY-EXAM, ANNUAL) | UNIQUE(code); no `created_by` |
| `lms_exam_status_events` | Lifecycle status master; `event_type` ENUM(EXAM/PAPER/RESULT/ATTEMPT) + `action_logic` JSON | UNIQUE(code) |
| `lms_exam_student_groups` | Ad-hoc exam groups per class+section | UNIQUE(class_id, section_id, code); `exam_id` commented-out in DDL |
| `lms_exam_student_group_members` | Group membership | UNIQUE(group_id, student_id) |
| `lms_exams` | Exam event (session+class+type) | UNIQUE(uuid), UNIQUE(code), UNIQUE(session,class,type); `result_published` ENUM, `scheduled_result_at` |
| `lms_exam_papers` | Per-subject per-mode paper + proctoring/offline config | UNIQUE(exam_id, paper_code); `mode` ENUM(ONLINE/OFFLINE), `offline_entry_mode` ENUM(BULK_TOTAL/QUESTION_WISE) |
| `lms_exam_paper_sets` | Paper variants (SET_A/B) | UNIQUE(exam_paper_id, set_code) |
| `lms_exam_scopes` | Lesson/topic/qtype coverage + weightage | FK slb_lessons/topics/question_types |
| `lms_exam_blueprints` | Section structure (qtype, count, marks) | UNIQUE(exam_paper_id, section_name) |
| `lms_paper_set_questions` | QB questions linked to a set | UNIQUE(paper_set_id, question_id); `override_marks` NOT NULL |
| `lms_exam_allocations` | Paper+set → CLASS/SECTION/GROUP/STUDENT + schedule | `allocation_type` ENUM; class_id NOT NULL |

## Cross-Module Dependencies
**Inbound (EXM consumes):** QuestionBank (`qns_questions_bank`, `qns_question_options`); LmsQuiz
(`lms_difficulty_distribution_configs` — `ExamPaper` imports `LmsQuiz\Models\DifficultyDistributionConfig`,
a cross-module model coupling); SchoolSetup (`sch_classes`, `sch_sections`, `sch_subjects`, `sch_rooms`);
Syllabus (`slb_lessons`, `slb_topics`, `slb_question_types`, `slb_grade_division_master`); StudentProfile
(`std_students`); GlobalMaster (`glb_academic_sessions`); SystemConfig (`sys_users`, `sys_media`).
**Outbound (consume EXM):** StudentPortal (attempt player, "My Results"; owns `ExamResult`/`ExamGrievance`
models), ParentPortal (child results/report card), MarksheetGeneration (D32 — reads `lms_exam_results`,
read-only; theory/practical via `total_marks` match, D-MSG-008/Q-13), Certificate (rank certificates),
Notification (result-publish alerts), HPC (progress card), Dashboard, Recommendation (D31 stats feed).

## Known Gaps & Open Issues
### P0 — Security
- **SEC-EXM-005 / D30 (CONFIRMED STILL PRESENT 2026-06-29):** ALL 12 FormRequest `authorize()` methods
  return hardcoded `return true` (incl. `GrievanceRequest`, `PaperSetQuestionRequest` = the old
  SEC-EXM-006). Defense-in-depth collapses to controller Gates only.
- **GrievanceReviewController has ZERO `Gate::authorize()` calls** — grievance create/resolve/toggle
  (which revises published marks) is unprotected at the controller layer; with `GrievanceRequest`
  authorize()=true there is no authorization at all on a marks-mutating workflow. (NEW finding.)
- **Policy registration overwrite bug (NEW finding):** `LmsExamServiceProvider::registerPolicies()`
  calls `Gate::policy(Exam::class, ...)` **13 times** for the same `Exam::class` model with different
  policy classes (LmsExamReportPolicy, OnlineAssessmentPolicy, OfflineAssessmentPolicy,
  ReEvaluationRequestsPolicy, StudentAttemptActivityLogPolicy, ExamResultReportPolicy, etc.). Laravel
  keeps only the LAST mapping per model — so ~12 of these policies are effectively dead. Report/
  assessment/grievance authorization via model policy does not work as intended.

### P1 — Resolved since V2 / verify
- BUG-01 (`dd($e)` in `LmsExamController::store`): **FIXED** — zero `dd(`/`dump(`/`var_dump` in any controller.
- BUG-02 (`ExamBlueprintController` Gates commented): **FIXED** — 11 active `Gate::authorize`, 0 commented.
- BUG-03 (`ExamScopeController` Gates commented): **FIXED** — 10 active, 0 commented.

### P1 — Still open
- **BUG-04 / NFR-09 (module licensing):** No `EnsureTenantHasModule` / `hasModule:EXM` middleware on the
  route group. RouteServiceProvider applies `InitializeTenancyByDomain` + `EnsureTenantIsActive` only.
- **`ExamScopePolicy` / `ExamBlueprintPolicy` not registered** in the ServiceProvider policy map
  (controllers rely on permission-string Gates, not model policies).
- **`created_by` missing** on 5 config models (`ExamType`, `ExamStatusEvent`, `ExamScope`,
  `ExamBlueprint`, `ExamStudentGroup`) and on the underlying owned DDL tables — needs additive migration.
- **No domain Service layer:** the 11 services are delete-guard `*UsageCheckService` + `ExamQueryService`.
  `LmsExamController` (~820 lines) and `PaperSetQuestionController` (~1200 lines) hold business logic.
- **Memory risk (NFR-13):** legacy `QuestionBank::get()` / `Student::get()` loads — verify replaced by AJAX.
- **0 automated tests** for a P0-security, marks-mutating module.

### DDL-quality anomalies in shared `StudentAttempt_DDL_v4.sql` (owned by StudentAttempt, flag only)
- `lms_offline_exam_upload_detail`: UNIQUE/index reference `attempt_id` and `is_active` columns that do
  not exist on the table (actual cols: `offline_exam_upload_id`; no `is_active`). Two FK names duplicate
  names used in the sibling table. COMMENT is copy-pasted ("Bulk total… One row per attempt").
- `attemp_activity_event_types`: missing comma after `PRIMARY KEY (id)` before `UNIQUE KEY` (CREATE would
  fail as written); table name itself is misspelled (`attemp_`).

## Design Decisions Made
- Exam status FSM (config-driven via `lms_exam_status_events`, D29 spirit): EXAM DRAFT→PUBLISHED→
  CONCLUDED→ARCHIVED; PAPER/ATTEMPT NOT_STARTED→IN_PROGRESS→SUBMITTED→EVALUATION_PENDING→EVALUATED→
  RESULT_PUBLISHED (+ ABSENT/CANCELLED). Note: live runtime tables (`lms_exam_attempts`,
  `lms_exam_results`) use hard ENUMs for `status`/`result_status`, not FK to the status master.
- Result publication modes: IMMEDIATE / SCHEDULED / MANUAL (`lms_exams.result_published`); SCHEDULED
  driven by `PublishScheduledResults` command against `scheduled_result_at`.
- Offline marks: `BULK_TOTAL` → one row in `lms_offline_exam_upload_marks`; `QUESTION_WISE` (OMR-style)
  → per-question rows in `lms_offline_exam_upload_detail`. CHECK on `marks_entry_mode` vs `is_ques_wise_file_upload`.
- Grievance: `grievance_type` ENUM(MARKING_ERROR/QUESTION_ERROR/OUT_OF_SYLLABUS/OTHER); status
  OPEN→UNDER_REVIEW→RESOLVED/REJECTED; on RESOLVED with `marks_changed=1`, `lms_exam_results` recomputed.

## Known Gaps & Open Issues (Technical Auditor — 2026-06-29 Mode X Complete Audit)
Report: `3-Audit_Reports/V1_Jun-2026/LmsExam_Complete_Audit_2026-06-29.md`. Health **40/100** (P0-capped; uncapped ≈59.5). Deploy **NO-GO**. Totals: P0=1, P1=7, P2=4, P3=2.
### P0 (verified against live code)
- **SEC-EXM-005 (confirmed + EXTENDED):** `GrievanceReviewController` has ZERO `Gate::authorize` on ALL 5 methods (index/store/show/resolve/toggleStatus), not just show/resolve. `resolve()` rewrites published `lms_exam_results` marks/percentage for any student; `GrievanceRequest::authorize()` also returns true → no authorization at any layer. Sibling controllers carry 10–27 gates.
### P1
- **SEC-EXM-008:** all 12 FormRequest `authorize()` = true (D30, confirmed). Supersedes the SEC-EXM-006 scope.
- **SEC-EXM-009 (confirmed):** policy-overwrite — `Gate::policy(Exam::class, …)` 13× (`LmsExamServiceProvider.php:87–108`), only the last (`LmsActivityDashboardPolicy`) survives; ExamPolicy + ~11 report/assessment policies dead. ExamScopePolicy/ExamBlueprintPolicy/AnswerSheetOnlineExam unregistered. NEW: imports `HwSubmissionTrackerPolicy`/`HwPerformanceAnalysisPolicy` (lines 41–42) reference non-existent classes (files are `Homework*Policy`).
- **SEC-EXM-010 (NEW):** advanced-reports hub gated by the WRONG permission `tenant.hw-submission-tracker.view` (`ExamAdvancedReportController.php:38`); no per-exam-report gates.
- **SEC-EXM-011 / BUG-04 (confirmed):** no `hasModule:EXM` license guard (`RouteServiceProvider.php:41–48`) → REQ-EXM-019 fails.
- **BUG-EXM-003 (confirmed STILL PRESENT):** `ExamStudentGroupMemberController::toggleStatus()` missing → `routes/web.php:171` returns 500.
- **BUG-EXM-004 (NEW):** grievance `resolve()` recomputes only marks+percentage, NOT grade/division/rank (`GrievanceReviewController.php:142–159`) → stale published grade/rank (BR-EXM-031/033/034 partial).
- **PERF-LMS-002 (confirmed):** unbounded dashboard queries + God controllers (LmsExamController 3767, PaperSetQuestionController 1465; no domain service layer).
### P2
- **DATA-EXM-001:** created_by missing on 5 config models + owned DDL (only 2 of 11 owned tables have it).
- **SCH-EXM-001:** 6 D29 ENUMs in owned DDL.
- **DAT-EXM-002:** **CORRECTION to prior note** — the StudentAttempt DDL-spec anomalies (`attemp_activity_event_types` missing comma; `lms_offline_exam_upload_detail` phantom `attempt_id`/`is_active`) are **DDL-SPEC-ONLY; the live migrations ship CORRECTLY** (real columns/indexes). Runtime is safe; fix belongs to the StudentAttempt DDL owner. Migration also renames the misspelled table to `lms_attemp_activity_event_types`.
- **DEAD-EXM-003:** `ReleaseScheduledExamResults` command is dead (imported `SP:49`, never registered) AND broken (queries removed column `show_result_type`); duplicates the live `lms-exam:publish-results`.
### Reassessed
- **SEC-EXM-007 → non-issue:** under database-per-tenant the connection is swapped; ExamQueryService needs no explicit tenant_id scoping.
- EXM is ABOVE platform baseline on D24 (single clean `tenant.` prefix, no `tennat.`), D25 (0 `$request->all()`), privilege-fillable (none), secrets (none), route closures (none), debug (none).

## Lessons Learned
- [2026-06-29 | Technical Auditor] Live migrations can be CORRECT while the DDL `.sql` spec is broken — the reverse of the usual D-pattern. The StudentAttempt `attemp_activity_event_types`/`offline_exam_upload_detail` anomalies never ship because provisioning uses migrations; always three-way reconcile before flagging a "live" defect.
- [2026-06-29 | Technical Auditor] `Gate::policy(SameModel::class, …)` registered repeatedly silently keeps only the LAST mapping — EXM registers Exam::class 13× → ~12 policies dead. Confirmed live; controllers are saved only because they use permission-string gates, not model policies.
- [2026-06-29 | Technical Auditor] A controller with zero gates is invisible to a per-controller gate-count scan unless you assert >0; GrievanceReviewController (gates=0) sits beside siblings with 10–27 gates — the contrast is the tell for an auth hole on a mark-mutating workflow.
- [2026-06-29 | Business Analyst] EXM is a multi-DDL module: setup tables in `LmsExam_DDL_v6.sql`, but
  runtime/result/grievance tables are owned by the StudentAttempt engine and the result/grievance
  *models* live in `Modules/StudentPortal`. Never attribute the `lms_exam_*` runtime tables to LmsExam's
  DDL without checking `StudentAttempt_DDL_v4.sql`.
- [2026-06-29 | Business Analyst] The V2 requirement doc badly understates completion (65% / "student
  pipeline absent") — the live tree shows upload, evaluation, grievance, reports and scheduled publish
  all built. Always reconcile the doc against the live tree before trusting a stated %.
- [2026-06-29 | Business Analyst] `Gate::policy()` registered repeatedly for the same model silently
  overwrites — a real and easy-to-miss authorization defect (12 EXM report/assessment policies dead).

## Pending Next Steps (post-FRD handoffs)
1. DDL Schema Gap Analysis — DB Architect / Technical Auditor (owned 11 + shared runtime tables).
2. Application Code Gap — Technical Auditor (FRD-driven; verify upload/evaluation/result/grievance/reports).
3. Business-Rule Enforcement + Security audit — Technical Auditor (SEC-EXM-005, grievance auth gap,
   policy-overwrite bug, BUG-04 module guard).
4. Completion Scoring (6-dim) — Status_Analyzer.
5. Test Coverage Gap — Testing Architect (currently 0 tests).

## FRD Summary
- File: `4-Requirement_Module_wise/0-FRD_Documents/EXM_FRD_Complete_2026-06-29.md` (Complete Analysis Pack).
- REQ: 19 · BR: 36 · Workflows: 5 · Reports (RPT): 6 · Enhancements (ENH): 6.
- Priority split: P0 = 9 · P1 = 8 · P2 = 2.

## Version History
| Date | Change | Author |
|------|--------|--------|
| 2026-06-29 | Seeded from live code + DDL + V2/V1 reconciliation; Complete FRD generated; status corrected 65%→~80–85%; shared-table ownership + 3 new defects documented | Business Analyst |
| 2026-06-29 | Mode X Complete Audit appended: 1 P0 (SEC-EXM-005 extended), 7 P1, 4 P2, 2 P3; SEC-EXM-009/010/BUG-EXM-004 new; SEC-EXM-007 cleared; DAT-EXM-002 corrected (migrations correct, DDL-spec only); Health 40/100, Deploy NO-GO | Technical Auditor |
