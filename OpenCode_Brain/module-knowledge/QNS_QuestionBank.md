# Module Knowledge — QuestionBank (QNS)

> Seeded: 2026-06-29 | Updated: 2026-06-30 | Agent: pa-business-analyst
> Verified against: live Modules/QuestionBank/ tree, tenant migrations, V2 requirement doc, lms-modules.md, Technical Audit (QuestionBank_Complete_Audit_2026-06-29.md)

---

## Module Facts

| Attribute | Value |
|-----------|-------|
| Module Name | QuestionBank |
| Module Code | QNS |
| Table Prefix | `qns_` |
| DB Layer | tenant_db |
| Route Prefix | `/question-bank/*` |
| Route Lines | 116 (Modules/QuestionBank/routes/web.php) |
| DDL Table Count | 13 (all qns_* migrations present in database/migrations/tenant/) |
| Controllers | 7 |
| Models | 16 files (1 confirmed duplicate — QuestionStatistics vs QuestionStatistic) |
| Services | 2 (QuestionStatisticsService, QuestionUsageCheckService) |
| FormRequests | 6 |
| Policies | 10 (includes 2 duplicates: AIQuestionPolicy + AiQuestionGeneratorPolicy) |
| Views | 45 |
| Seeders | 9 seeders + 1 support file (Support/QuestionSampleData.php) |
| Imports | 2 (QuestionImport, QuestionReadOnly via maatwebsite/laravel-excel) |
| Jobs | 0 |
| Events | 0 |
| Tests | 0 (CRITICAL GAP) |
| Estimated Completion | ~50% (revised 2026-06-30 after Technical Audit; previously ~65-70%; 4 additional P0s discovered) |
| Health Score | 37 / 100 (NO-GO — Technical Audit 2026-06-29) |
| FRD Status | v1.1 generated 2026-06-30 (supersedes v1.0 from 2026-06-29) |

---

## DDL Table Inventory (13 tables, all migrations confirmed)

| # | Table | Migration File | Purpose |
|---|-------|----------------|---------|
| 1 | `qns_questions_bank` | 2026_06_15_151318 | Core question records (UUID BINARY16, full taxonomy FKs) |
| 2 | `qns_question_options` | 2026_06_15_151319 | MCQ/Match answer options with ordinal + is_correct |
| 3 | `qns_media_store` | 2026_06_16_114239 | Physical media file metadata (checksum/SHA-256, disk, size) |
| 4 | `qns_question_tags` | 2026_06_16_114240 | Keyword tag definitions (short_name UNIQUE, name) |
| 5 | `qns_question_performance_category_jnt` | 2026_06_16_114244 | Q ↔ PerformanceCategory mapping (recommendation_type, priority) |
| 6 | `qns_question_questiontag_jnt` | 2026_06_16_114245 | Q ↔ Tag many-to-many (UNIQUE on question_bank_id + tag_id) |
| 7 | `qns_question_review_log` | 2026_06_16_114246 | Approval/rejection audit trail (insert-only) |
| 8 | `qns_question_statistics` | 2026_06_16_114247 | Computed difficulty/discrimination/guessing metrics (1:1 with question) |
| 9 | `qns_question_topic_jnt` | 2026_06_16_114248 | Multi-topic coverage mapping with weightage DECIMAL(5,2) |
| 10 | `qns_question_usage_log` | 2026_06_16_114249 | Usage trail per quiz/exam (insert-only, written by consuming modules) |
| 11 | `qns_question_versions` | 2026_06_16_114250 | Full JSON snapshots on content modification |
| 12 | `qns_question_media_jnt` | 2026_06_16_114251 | Links questions/options to media with media_purpose context |
| 13 | `qns_question_usage_type` | 2026_06_15_145810 | Reference lookup: QUIZ/QUEST/ONLINE_EXAM/OFFLINE_EXAM (4 seeded rows) |

**Note:** `slb_question_types` table (in Syllabus module, migration 2026_06_15_145811) is a shared dependency. QuestionBank reads from it via FK but does not own it.

---

## Controller Inventory (7)

| Controller | Key Methods | Status |
|------------|-------------|--------|
| QuestionBankController | index, create, store, show, edit, update, destroy, clone, storeClone, print, validateFile, startImport, reviewIndex, reviewShow, reviewApprove, reviewReject, 10+ AJAX cascade endpoints | ~85% — missing Gate on print/validateFile/startImport |
| AIQuestionGeneratorController | index, getSections, getSubjectGroups, getSubjects, getLessons, getTopics, generateQuestions (STUBBED — returns demo data), saveQuestions, downloadCSV | ~30% — zero auth, demo data hardcoded |
| QuestionMediaStoreController | full resource + trash/restore/forceDelete/toggleStatus | ~80% — wrong policy gate (competency.* bug) |
| QuestionStatisticController | full resource + trash/restore/forceDelete/toggleStatus + sync | ~75% |
| QuestionTagController | full resource + trash/restore/forceDelete/toggleStatus | ~90% |
| QuestionUsageTypeController | full resource + trash/restore/forceDelete/toggleStatus | ~90% |
| QuestionVersionController | full resource + restore/forceDelete/toggleStatus | ~80% |

---

## Service Inventory (2)

| Service | Purpose | Quality |
|---------|---------|---------|
| QuestionStatisticsService | Full D31 statistics computation: difficulty_index (p-value), discrimination_index (Kelley 27% rule), guessing_factor (empirical/cold-start), time metrics with outlier guard, performance category feed-forward | HIGH — 100% Eloquent, 0 raw SQL, all spec edge cases handled |
| QuestionUsageCheckService | Checks if a question is in use by LmsExam/LmsQuiz/LmsQuests; returns usage message; blocks edit if in use | MEDIUM — correct logic, no tests |

---

## D31 — Question Statistics Formula Contract

Source: QuestionStatisticsService.php (code-verified 2026-06-29)

| Metric | Formula | Edge Cases |
|--------|---------|-----------|
| difficulty_index | (correct_answers ÷ total_attempts) × 100 | NULL if total_attempts = 0 |
| discrimination_index | (pU − pL) × 100; Kelley D-index; top/bottom 27% split by attempt_percentage | NULL if fewer than 4 attempts per group; clamp to [−100, +100] |
| guessing_factor | MCQ only: pL × 100 if total_attempts ≥ 30 AND pL available; else 100 ÷ k (k = option count) | NULL for non-MCQ; clamp to [0, 100] |
| min_time_taken_seconds | MIN time where is_correct=1 AND time > 0 | NULL if no correct attempts |
| max_time_taken_seconds | MAX time where time > 0 AND time < ceiling (ceiling = expected_time × 3 or 3600) | NULL if no valid telemetry |
| avg_time_taken_seconds | AVG of valid time feed (time > 0 AND time < ceiling) | NULL if no valid telemetry |
| total_attempts | COUNT of evaluated, non-null is_correct rows across Quiz+Quest+Exam combined | 0 = skip update |

Answer feed: Combines `lms_quiz_quest_attempt_answers` (is_evaluated=1, is_active=1) + exam attempt answers. Ability proxy: Quiz/Quest = attempt.percentage; Exam = attempt.result.percentage.

---

## Question Status State Machine

DRAFT → IN_REVIEW → APPROVED → PUBLISHED → ARCHIVED (terminal)
DRAFT → APPROVED (admin shortcut for trusted content)
IN_REVIEW → REJECTED → DRAFT (teacher revises after rejection)

Enforced via: status ENUM on qns_questions_bank. Only APPROVED and PUBLISHED questions are visible to assessment builders. AI-generated questions (created_by_AI=1) must go through full IN_REVIEW stage.

---

## Known Gaps & Open Issues

### P0 — Critical (Block Production)

| ID | Issue | Location | Fix |
|----|-------|----------|-----|
| SEC-QNS-01 | AI generation still returns demo data; real AI provider not called | AIQuestionGeneratorController@generateQuestions line 222: early return getDemoResponse() | Remove early return; implement AIQuestionService with real HTTP calls |
| SEC-QNS-02 | Zero authorization on ALL AIQuestionGeneratorController methods | AIQuestionGeneratorController — all methods | Add Gate::authorize() using AiQuestionGeneratorPolicy |
| SEC-QNS-03 | Gate::authorize() missing on QuestionBankController@print, @validateFile, @startImport | QuestionBankController lines 82, 93, 203 | Add Gate::authorize('tenant.question-bank.viewAny') |
| SEC-QNS-04 | EnsureTenantHasModule middleware missing from route group | routes/web.php — no module guard | Add EnsureTenantHasModule:QNS to route group |
| SEC-QNS-05 | 0 tests across all 7 controllers | Modules/QuestionBank/tests/ | Minimum 25 Pest tests required (T-QNS-01 through T-QNS-25) |

**4 additional P0 gaps discovered by Technical Audit 2026-06-29 (now GAP-QNS-P0-01 through P0-04 below):**

| ID | Issue | Location | Fix |
|----|-------|----------|-----|
| GAP-QNS-P0-01 | Duplicate Gate::policy(QuestionBank::class) in QuestionBankServiceProvider: line 69 registers QuestionBankPolicy; line 75 registers AiQuestionGeneratorPolicy for same model — first silently overwritten; all 22+ Gate::authorize('tenant.question-bank.*') now go to wrong policy | QuestionBankServiceProvider.php line 75 | Fix to register QuestionBankPolicy only; remove duplicate |
| GAP-QNS-P0-02 | No QNS permission seeder — all Question Bank permissions undefined; every intended role (Teacher/DeptHead/Admin) receives 403 for all QNS routes (only super-admin passes Gate::before bypass) | database/seeders/ (no QNS seeder present) | Create TenantPermissionSeeder for QNS; define ~15 permissions; assign to Teacher/DeptHead/Admin |
| GAP-QNS-P0-03 | scopeApproved() on QuestionBank model references column 'ques_reviewed_status' — does not exist; actual column is 'status'; scope silently returns zero results; all assessment builders see empty question picker | Modules/QuestionBank/Models/QuestionBank.php scopeApproved() | Fix to reference 'status' column |
| GAP-QNS-P0-04 | reviewApprove() sets question status = PUBLISHED, bypassing required APPROVED intermediate state; AI-generated questions can reach live assessments without completing the review gate (BR-QNS-008 violation) | QuestionBankController@reviewApprove | Fix to set status = APPROVED; require separate publish action |

Note: API key security (previously SEC-QNS-001/002 from March 2026) is PARTIALLY FIXED — controller now reads from env('CHATGPT_API_KEY') and env('GEMINI_API_KEY') rather than hardcoded strings. However: (a) still uses env() directly rather than config('services.*'), (b) keys must be confirmed rotated.

**Statistics migration NOT NULL mismatch (confirmed by Technical Audit as MIG-QNS-001):** The qns_question_statistics migration defines discrimination_index, guessing_factor, and avg_time_taken_seconds as NOT NULL DECIMAL — but QuestionStatisticsService correctly produces null per D31 spec for these fields when insufficient data or non-MCQ type. DB write fails with SQLSTATE 1048. Fix: add migration to make these three columns NULLABLE.

### P1 — High Priority (Fix Before Release)

| ID | Issue | Evidence |
|----|-------|---------|
| BUG-QNS-01 | QuestionMediaStoreController uses wrong policy gate: tenant.competency.* instead of tenant.question-media.* | Copy-paste from Syllabus module |
| BUG-QNS-02 | getDemoResponse() method (lines 302–393) still in AIQuestionGeneratorController | Dead code + misleads in production |
| BUG-QNS-03 | AIQuestionService not extracted — 2747-line fat controller | QuestionBankController 2747 lines |
| BUG-QNS-04 | DDL FK constraint bug: qns_question_usage_log CONSTRAINT references 'usage_context' but column named 'question_usage_type' | V2 doc Appendix E: DDL-QNS-01 |
| BUG-QNS-05 | Duplicate model: QuestionStatistics.php vs QuestionStatistic.php | Only QuestionStatistic (singular) should exist |
| BUG-QNS-06 | Duplicate policy: AIQuestionPolicy.php vs AiQuestionGeneratorPolicy.php | Only AiQuestionGeneratorPolicy correct |
| BUG-QNS-07 | No rate limiting on AI generation endpoint (POST /generate-questions) | Can drive runaway API costs |
| BUG-QNS-08 | generateQuestions() uses inline Validator::make() instead of FormRequest | Missing AIQuestionGenerateRequest |

### P2 — Improvements

| ID | Improvement |
|----|-----------|
| IMP-QNS-01 | QuestionStatisticsService should dispatch a queued job (not sync loop via syncAll()) |
| IMP-QNS-02 | QuestionBankService refactor: extract createQuestion(), updateQuestion(), createVersionSnapshot(), submitForReview() from fat controller |
| IMP-QNS-03 | Cache filter data in getFilterData() — Bloom/complexity/cognitive skill reference tables rarely change |
| IMP-QNS-04 | Replace LOWER() duplicate check in validateFile() with hash-based index |
| IMP-QNS-05 | scopeApproved() on QuestionBank model references 'ques_reviewed_status' not 'status' — column name mismatch |

---

## Design Decisions Made

| Decision | What | Evidence |
|----------|------|---------|
| D31 | qns_question_statistics formula contract — difficulty_index, discrimination_index, guessing_factor computation spec | QuestionStatisticsService.php fully implements all 49 spec points |
| UUID binary | uuid stored as BINARY(16) with PHP UUID bytes (Str::uuid()->getBytes()) in creating hook; custom accessor for hex conversion | QuestionBank.php getUuidAttribute() |
| Review in controller | Review approve/reject workflow implemented in QuestionBankController (not a separate QuestionReviewController) | routes/web.php /question-review/* routes |
| Clean-slate update | On edit, ALL options/media/tags/topics are deleted and re-created atomically in DB transaction | QuestionBankController@update |
| Usage-gated edit | Questions in use by LmsExam/LmsQuiz/LmsQuests cannot be permanently edited; QuestionUsageCheckService gates the edit action | QuestionBankController@edit |
| Multi-source statistics | Statistics aggregate answers from BOTH quiz+quest (lms_quiz_quest_attempt_answers) AND exam (exam_attempt_answer) tables unified into a single feed | QuestionStatisticsService@computeAndPersist |
| Availability scope | 6 levels: GLOBAL / SCHOOL_ONLY / CLASS_ONLY / SECTION_ONLY / ENTITY_ONLY / STUDENT_ONLY; conditional FK columns per scope | qns_questions_bank fillable + controller |

---

## Cross-Module Dependencies

### Incoming (QNS reads from)

| Source Module | Tables/Models Used | Purpose |
|---------------|-------------------|---------|
| Syllabus (slb_*) | slb_bloom_taxonomy, slb_complexity_level, slb_cognitive_skill, slb_ques_type_specificity, slb_question_types, slb_performance_categories, slb_lessons, slb_topics, slb_competencies, slb_books | All taxonomy tagging FKs; question types; curriculum anchoring |
| SchoolSetup (sch_*) | sch_classes, sch_sections, sch_subjects, sch_subject_groups, sch_entity_groups | Academic hierarchy anchoring |
| StudentProfile (std_*) | std_students | STUDENT_ONLY availability scoping |
| SystemConfig (sys_*) | sys_users (created_by, reviewer_id), sys_dropdown_table (review_status_id, recommendation_type) | Ownership, review workflow, recommendation type dropdown |
| StudentPortal | QuizQuestAttemptAnswer, ExamAttemptAnswer | Statistics computation — answer feed |
| Prime | Dropdown (sys_dropdowns proxy) | recommendation_type, review_status values |

### Outgoing (QNS feeds)

| Target Module | Mechanism | What |
|---------------|-----------|------|
| LmsQuiz | for_quiz=1 flag; question picker reads qns_questions_bank | Quiz question sourcing |
| LmsQuests | for_quest=1 flag; question picker reads qns_questions_bank | Quest question sourcing |
| LmsExam | for_exam=1 / for_offline_exam=1 flags; paper set builder reads qns_questions_bank | Exam paper question sourcing |
| Recommendation (rec_*) | qns_question_performance_category_jnt (recommendation_type: REVISION/PRACTICE/CHALLENGE) | LXP personalized learning paths |

### External Dependencies

| External | Purpose | Status |
|----------|---------|--------|
| OpenAI GPT-4o-mini | AI question generation | Keys moved to env(); generation still returns demo data |
| Google Gemini 2.0 Flash | AI question generation | Keys moved to env(); generation still returns demo data |
| maatwebsite/laravel-excel | Excel bulk import/export | Implemented (QuestionImport, QuestionReadOnly) |

---

## Lessons Learned

- [2026-06-29 | pa-business-analyst] QuestionBank: The modules-map says 2 services but this understates the actual work — QuestionStatisticsService is a full D31 implementation (49 spec points, all Kelley D-index edge cases), not a stub. Verify service quality, not just count.
- [2026-06-29 | pa-business-analyst] QuestionBank: QuestionBankController is 2747 lines. The review workflow (approve/reject) is embedded in it via /question-review routes, not a separate controller. The V2 doc proposed a separate QuestionReviewController — this has not been built.
- [2026-06-29 | pa-business-analyst] QuestionBank: scopeApproved() on QuestionBank model references 'ques_reviewed_status' which is NOT the column name in the migration (column is 'status'). This scope will always return zero results — a silent bug.
- [2026-06-29 | pa-business-analyst] QuestionBank: The statistics_help.md file mentioned in MEMORY.md as path `51-QuestionBank/DDL/statistics_help.md` does not exist at the configured path. The QuestionStatisticsService.php IS the living contract and should be treated as D31 canonical source.

---

## FRD Summary

| Attribute | Value |
|-----------|-------|
| FRD File (standalone) | `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/QNS_FRD_2026-06-30.md` (v1.1, current) |
| FRD File (Complete Pack) | `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/QNS_FRD_Complete_2026-06-30.md` (v1.1, current) |
| Conditions Catalog | `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/5-Requirement_Conditions/QuestionBank_Conditions.md` |
| FRD Date | 2026-06-30 |
| REQ Count | 14 |
| BR Count | 12 |
| RPT Count | 5 |
| ENH Count | 5 |
| P0 (Core) | 4 (REQ-QNS-001, 003, 005, 014) |
| P1 (Standard) | 7 (REQ-QNS-002, 004, 006, 007, 010, 011, 012) |
| P2 (Enhanced) | 3 (REQ-QNS-008, 009, 013) |
| Workflows | 4 (Question Lifecycle FSM, AI Generation, Excel Import, Statistics Computation) |
| NFRs | 16 |

---

## Pending Next Steps

1. DDL Schema Gap Analysis → Technical Auditor (Layer 1–2): verify migrations match V2 DDL spec; check DDL-QNS-01 FK constraint bug and DDL-QNS-02 ON DELETE SET NULL conflict
2. Application Code Gap Analysis → Technical Auditor (Mode B): verify all 5 P0 security gaps; test scopeApproved() column name bug
3. Statistics Computation Service → make async (queued job) before production
4. AI Service extraction → build AIQuestionService; remove getDemoResponse(); implement real API calls via config('services.openai.key')
5. Test Coverage → 25 Pest feature/unit tests (T-QNS-01 through T-QNS-25 per V2 doc)
6. QuestionReviewController → dedicated controller for review workflow with notification integration

---

## Version History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0 | 2026-06-29 | pa-business-analyst | Initial seed — verified counts against live filesystem, migrations, V2 doc, code audit |
| 1.1 | 2026-06-30 | pa-business-analyst | Incorporated Technical Audit findings: 4 new P0 gaps (GAP-QNS-P0-01 through 04), MIG-QNS-001 statistics NOT NULL mismatch; revised completion to ~50%; health score 37/100; FRD paths updated to v1.1; Conditions Catalog written |
