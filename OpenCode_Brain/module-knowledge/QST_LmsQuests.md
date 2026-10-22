# Module Knowledge — LmsQuests (QST)

> Single source of accumulated knowledge for the LmsQuests module.
> Prefix: `lms_` (SHARED with LmsExam / LmsHomework / LmsQuiz / EventEngine — attribute only quests-owned tables here).
> Seeded: 2026-06-29 | Business Analyst (pa-business-analyst). All counts verified against live tree.

---

## Module Facts (verified 2026-06-29 against `/Users/bkwork/Herd/prime_ai/Modules/LmsQuests`)

| Fact | Value | Verification |
|------|-------|--------------|
| Module code | QST | conventions.md Master Reference |
| Table prefix | `lms_` (shared) | DDL + migrations |
| Scope | TENANT (per-school DB) | routes registered tenant-side; FKs to tenant tables |
| Controllers | 4 | `LmsQuestController`, `QuestScopeController`, `QuestQuestionController`, `QuestAllocationController` |
| Models | 4 | `Quest`, `QuestScope`, `QuestQuestion`, `QuestAllocation` |
| Services | 5 | `QuestQueryService`, `QuestUsageCheckService`, `QuestQuestionUsageCheckService`, `QuestScopeUsageCheckService`, `QuestAllocationUsageCheckService` |
| FormRequests | 4 | `QuestRequest`, `QuestScopeRequest`, `QuestQuestionRequest`, `QuestAllocationRequest` |
| Policies | 4 | `QuestPolicy`, `QuestScopePolicy`, `QuestQuestionPolicy`, `QuestAllocationPolicy` (module-local `app/Policies/`) |
| Blade views | 30 | counted across `resources/views/` (quest, quest-scope, quest-question, quest-allocation × 5 CRUD each = 20; tab_module/tab; dashboard; summary ×3; paper-check ×2; activity_log; index; components/layouts/master) |
| Seeders | 2 | `LmsQuestsDatabaseSeeder`, `LmsQuestSeeder` |
| Tests | 0 | `tests/Feature` & `tests/Unit` contain only `.gitkeep` |
| Owned DDL tables | 4 | see inventory below |
| Module migrations | 5 | 4 create + 1 alter (`2026_06_18_100000_update_lms_quests_and_scopes.php`) |
| Route file | `Modules/LmsQuests/routes/web.php` (+ `api.php`) | NOT in `routes/tenant.php` (V2 doc was outdated) |
| Route prefix / name | `/lms-quests` · `lms-quests.` | `RouteServiceProvider` |
| Route middleware | `web, InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive, auth, verified` | `RouteServiceProvider::mapWebRoutes()` |
| FRD status | Complete FRD authored 2026-06-29 (`QST_FRD_Complete_2026-06-29.md`) | — |
| Implementation estimate | ~75–80% teacher-side complete (was ~60% in V2 dated 2026-03-26) | see "Delta since V2" |

### Permission strings (from `Gate::authorize()` in controllers)
`tenant.quest.{viewAny,view,create,update,delete,restore,forceDelete}` ·
`tenant.quest-scope.{viewAny,view,create,update,delete,restore,forceDelete}` ·
`tenant.quest-question.{viewAny,view,create,update,delete,restore,forceDelete}` ·
`tenant.quest-allocation.{viewAny,view,create,update,delete,restore,forceDelete}`

---

## DDL Table Inventory

### Owned by QST (4 tables)
| Table | Purpose | Key columns (verified migration) |
|-------|---------|----------------------------------|
| `lms_quests` | Quest master (config, grading, timer, flags) | uuid, quest_code (UNIQUE), title, status (DRAFT/PUBLISHED/ARCHIVED), academic_session_id, class_id, subject_id, quest_type_id→`lms_assessment_types`, difficulty_config_id→`lms_difficulty_distribution_configs`, total_marks, total_questions, passing_percentage, allow_multiple_attempts, max_attempts, negative_marks, is_randomized, question_marks_shown, auto_publish_result, timer_enforced, show_correct_answer, show_explanation, ignore_difficulty_config, is_system_generated, only_unused_questions, only_authorised_questions, created_by |
| `lms_quest_scopes` | Multi-lesson/topic coverage per quest | quest_id, lesson_id→`slb_lessons`, topic_id→`slb_topics`, question_type_id→`slb_question_types`, target_question_count |
| `lms_quest_questions` | Junction: quest ↔ Question Bank question | quest_id, question_id→`qns_questions_bank`, ordinal, marks_override; UNIQUE(quest_id, question_id) |
| `lms_quest_allocations` | Assign quest to CLASS/SECTION/GROUP/STUDENT | quest_id, allocation_type ENUM, target_table_name, target_id (polymorphic, app-level FK), assigned_by, published_at, due_date, cut_off_date, is_auto_publish_result, result_publish_date |

### Shared / external (referenced, NOT owned by QST)
| Table | Owner | QST usage |
|-------|-------|-----------|
| `lms_assessment_types` | LmsQuiz | `quest_type_id` FK (Quest "type": Challenge/Enrichment/Practice/etc.) |
| `lms_difficulty_distribution_configs` | LmsQuiz | `difficulty_config_id` FK |
| `lms_difficulty_distribution_details` | LmsQuiz | difficulty rule rows used by question-add validation |
| `lms_quiz_quest_attempts` | Shared (LmsQuiz/StudentPortal) | student attempts; QST filters `assessment_type='QUEST'`. Model lives in `Modules\StudentPortal\Models\QuizQuestAttempt` |
| `lms_quiz_quest_attempt_answers` | Shared | per-question answers; model `QuizQuestAttemptAnswer` in StudentPortal |
| `lms_quiz_quest_results` | Shared | evaluated results; model `QuizQuestResult` in StudentPortal |
| `qns_questions_bank`, `qns_question_options`, `qns_question_usage_log` | QuestionBank | question source, options, reuse log (QST writes `question_usage_type='QUEST'`) |

> **Shared-prefix caution:** `lms_quiz_*` and `lms_assessment_types`/`lms_difficulty_*` tables are NOT QST-owned. Only the four `lms_quest*` tables belong to QST.

---

## Three-Way Reconciliation (DDL ↔ migration ↔ model) — VERIFIED FINDINGS

1. **`lesson_id` on `lms_quests` — RESOLVED.** V2 (GAP-MDL-001) flagged `lesson_id` in `Quest::$fillable` with no backing column. Live `Quest` model no longer lists `lesson_id`; the create migration adds no `lesson_id`; DDL v2 has none. Lesson coverage is correctly handled via `lms_quest_scopes`. (Note: the alter migration's `down()` still references dropping a `lesson_id` it never adds — latent migration-rollback bug, not a schema defect.)
2. **`show_result_immediately` — PHANTOM FIELD (model only).** Present in `Quest` `$fillable` + `$casts`, but NO column in the create migration and none in DDL v2. Eloquent silently ignores it on write. Flag for cleanup.
3. **`pending` — PHANTOM FIELD (request only).** `QuestRequest` validates and merges `pending` ("ONLY NEW COLUMN"), but no `pending` column exists in `lms_quests` (grep confirms none). It is not in `$fillable`, so it is silently dropped on create/update. Dead validation.
4. **Services exist now.** V2 said "0 services"; live has 5. Module evolved substantially since V2 (2026-03-26).
5. **Student attempt pipeline now exists (in StudentPortal).** V2 said absent. Live: attempt/answer/result models live in `Modules\StudentPortal`; `LmsQuestController` now implements teacher-side paper-check, per-question grading, result publication, performance report, attempt-detail review, and a rich analytics dashboard.

---

## Known Gaps & Open Issues

### P0
- **SEC-QST-001 (UNRESOLVED):** `LmsQuestController::index()` has `Gate::authorize('tenant.quest.viewAny')` **commented out** (live line ~71). Any authenticated user can view the quest hub + analytics. Must re-enable.
- **EnsureTenantHasModule (V2 SEC-QST-002) — still not applied.** Route group uses `EnsureTenantIsActive` but no module-entitlement gate. Module access is not plan-gated.

### P1
- **No automated tests (0 files).** V2 target was ≥60% coverage.
- **Duplicate quest-code generation (V2 GAP-ARCH-004, UNRESOLVED).** Code is generated in BOTH `Quest::boot()` and `LmsQuestController::store()/update()`; the controller path overwrites the model-generated code.
- **`QuestQuestionController::store()` references undefined `$quest`** before assignment (uses `$quest->id` at top of method; `$quest` only set later). Latent fatal if route is hit — primary add path is `bulkStore`, so seldom exercised.
- **Child resource `index()` actions are hard-disabled** (`abort(404)`) in QuestScope/QuestQuestion/QuestAllocation controllers — all listing is funneled through the tab hub (`LmsQuestController::index`). Intentional but leaves dead resource routes.
- **System-generated quests not implemented.** `is_system_generated` flag + filters exist; no `QuestGenerationService` to auto-pick questions.

### P2 / Notes
- Attempt FK naming inconsistency: `QuestAllocation::attempts()` joins on `quest_allocation_id`, while `publishHiddenRecommendations()` queries `lms_quiz_quest_attempts.allocation_id`. Confirm canonical column.
- `negative_marks` stored & validated but no live scoring logic deducts it (auto-grading lives in StudentPortal; teacher grading is manual).
- Model accessors `getStatisticsAttribute()` / `getSummaryAttribute()` run multiple queries per access (N+1 risk on lists).

---

## Design Decisions Observed
- **Tab-hub UI pattern:** one entry screen (`tab_module/tab.blade.php`) hosts Dashboard / Quest / Scope / Question / Allocation / Summary / Activity-Log tabs; child controllers exist only for CRUD form/store/update/delete + AJAX.
- **Polymorphic allocation:** `allocation_type` + `target_table_name` + `target_id` (no DB FK on target; resolved in app via `morphTo`/match). SECTION targets resolve to `sch_class_section_jnt.id` (store() converts section_id→ClassSection junction id).
- **Usage-guard before mutation:** every edit/update/delete/restore/forceDelete checks a `*UsageCheckService::isUsed()` (allocations / questions / attempts) and blocks the action if the quest is in use.
- **Shared LMS masters** (`AssessmentType`, `DifficultyDistribution*`) imported from `Modules\LmsQuiz`; attempt models imported from `Modules\StudentPortal`.
- **Question reuse log:** adding/removing quest questions writes/removes `qns_question_usage_log` rows with `question_usage_type='QUEST'`.
- **Recommendation hook:** publishing a graded result dispatches `Modules\Recommendation\Events\QuizQuestResultPublished`; toggling auto-publish flips hidden `StudentRecommendation` rows visible.

---

## Cross-Module Dependencies
| Module | Code | Type | Detail |
|--------|------|------|--------|
| QuestionBank | QNS | CRITICAL | source of all questions; usage log; options |
| LmsQuiz | QUZ | SHARED MODELS | `AssessmentType`, `DifficultyDistributionConfig/Detail` |
| StudentPortal | STP | SHARED MODELS / pipeline | attempt/answer/result models; student quest-taking UI |
| SchoolSetup | SCC/SCO | FK | classes, sections, subjects, subject groups, entity groups, class-section junction |
| Syllabus | SLB | FK | lessons, topics, question types, topic level types |
| StudentProfile | STD | FK | students, academic-session enrolments |
| Prime / Global | PRM/GLB | FK | academic sessions, media |
| Recommendation | REC | EVENT | `QuizQuestResultPublished`; hidden recommendation publication |
| SystemConfig | SYS | AUTH | users, policies, permissions, activity log, dropdown masters |
| Notification | NTF | PROPOSED | publish / due-date / result alerts (not yet wired) |

---

## FRD Summary
- **File:** `4-Requirement_Module_wise/0-FRD_Documents/QST_FRD_Complete_2026-06-29.md` (consolidated Complete Analysis Pack; FRD is Sections 1–10 inside it)
- **Date:** 2026-06-29 | **Version:** 1.0
- **Counts:** 21 REQ · 32 BR · 6 RPT · 6 workflows · 6 ENH
- **Priority split:** P0 = 7 · P1 = 10 · P2 = 4
- Register: business-language narrative; technical detail confined to the Data Dictionary technical view + Dependency Map.

## Pending Next Steps (post-FRD handoffs)
1. DDL Schema Gap Analysis (DB Architect / Technical Auditor) — confirm phantom columns, attempt FK naming.
2. Application Code Gap (Technical Auditor, FRD-driven) — verify each REQ vs live controllers/views.
3. Business-Rule Enforcement audit (Technical Auditor Mode C) — especially SEC-QST-001, publish guard bypass, usage-guards.
4. Completion Scoring (Status_Analyzer, 6-dim).
5. Test Coverage Gap (Testing Architect) — module has 0 tests.

## Version History
| Date | Change | Author |
|------|--------|--------|
| 2026-06-29 | Seeded from live tree (code + DDL + migrations + V2 + V1). FRD Complete authored. | pa-business-analyst |

## Lessons Learned
- [2026-06-29 | BA] LmsQuests V2 (2026-03-26) is materially stale: it reports 0 services and an absent student pipeline, but the live module has 5 services and a full teacher-side grading/monitoring/reporting suite, with the student-taking pipeline relocated to StudentPortal. Always re-verify counts and feature status against the live tree before trusting a months-old requirement doc.
- [2026-06-29 | BA] Routes moved out of `routes/tenant.php` (V2 cited lines 669–721) into the module's own `routes/web.php` via `RouteServiceProvider`; the V2 route-ordering 404 bugs (get-topics / get-target-options) are RESOLVED there.
- [2026-06-29 | BA] Phantom fields are easy to mis-document: `show_result_immediately` (model) and `pending` (request) have no backing column — three-way reconcile against the migration caught both.
