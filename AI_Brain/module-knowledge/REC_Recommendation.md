# Module Knowledge — Recommendation (REC)

**Last Updated:** 2026-06-30 | **Agents:** pa-business-analyst (2026-06-30), pa-technical-auditor (2026-06-30, Mode X) | **Source:** live code + migrations + V2 requirement doc + 12-layer audit
**Audit Report:** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Audit_Reports/Recommendation_Complete_Audit_2026-06-30.md`
**Audit Verdict:** NO-GO | Health: 35/100 (P0-capped) | P0: 3 | P1: 16 | P2: 13 | P3: 3

---

## Module Facts

| Field | Value |
|-------|-------|
| Module Name | Recommendation |
| Module Code | REC |
| Table Prefix | `rec_` |
| Scope | TENANT (tenant_db) |
| Route Prefix | `/recommendation/*` |
| FRD Status | Generated 2026-06-30 |
| Completion | ~60–65% (up from V2 doc's ~39%) |

### Live Code Counts (verified 2026-06-30 against `/Modules/Recommendation/`)

| Artifact | Count | Notes |
|----------|-------|-------|
| DDL tables (`rec_*`) | 10 | Verified from 10 create migrations |
| Tenant migrations | 11 | 10 create + 1 alter (add deleted_at to student_recommendations) |
| Controllers | 10 | All in `app/Http/Controllers/` |
| Models | 10 | `PerformanceSnapshot` model NOT present (cleaned up) |
| Services | 1 | `RecommendationEngineService` — fully implemented |
| FormRequests | 18 | 9 Store + 9 Update (exceeds V2 target of 10) |
| Policies | 8 | `RecAssessmentTypePolicy` MISSING |
| Views (Blade) | 49 | Full CRUD views for all entities |
| Route lines | 103 (web.php) | All 10 controllers routed |
| Events | 1 | `QuizQuestResultPublished` |
| Listeners | 1 | `GenerateRecommendationsListener` (wired in EventServiceProvider) |
| Jobs | 0 | ExpireRecommendationsCommand not built |
| Tests | 0 | Critical gap |
| Seeders | 2 | `RecommendationDatabaseSeeder`, `RecommendationSeeder` |
| Middleware | 0 | EnsureTenantHasModule:REC not applied |

---

## DDL Table Inventory

All tables in tenant_db (database-per-tenant; no tenant_id column).

| # | Table | Purpose | Key Columns | Notes |
|---|-------|---------|-------------|-------|
| 1 | `rec_trigger_events` | Lookup: event types that activate the rule engine | `event_name` UNIQUE, `is_active` | Seeded: ON_ASSESSMENT_RESULT, ON_TOPIC_COMPLETION, ON_ATTENDANCE_LOW, MANUAL_RUN, SCHEDULED_WEEKLY |
| 2 | `rec_recommendation_modes` | Lookup: how content is resolved for a rule | `mode_name` UNIQUE, `is_active` | Seeded: SPECIFIC_MATERIAL, SPECIFIC_BUNDLE, DYNAMIC_BY_TOPIC, DYNAMIC_BY_COMPETENCY |
| 3 | `rec_dynamic_material_types` | Lookup: material format categories for dynamic mode | `type_name` UNIQUE, `is_active` | Seeded: ANY_BEST_FIT, VIDEO, QUIZ, PDF, AUDIO, INTERACTIVE |
| 4 | `rec_dynamic_purposes` | Lookup: learning intent for dynamic mode | `purpose_name` UNIQUE, `is_active` | Seeded: REMEDIAL, ENRICHMENT, PRACTICE, REVISION |
| 5 | `rec_assessment_types` | Lookup: which assessment type a rule targets | `type_name` UNIQUE, `is_active` | Seeded: ALL, QUIZ, WEEKLY_TEST, TERM_EXAM, FINAL_EXAM |
| 6 | `rec_recommendation_materials` | Individual content items (videos, PDFs, quizzes, HTML, links) | `title`, `material_type` FK sys_dropdowns, `purpose` FK sys_dropdowns, `complexity_level` FK slb_complexity_level (singular), `subject_id`, `class_id`, `topic_id`, `tags` JSON | Composite index on (class_id, subject_id, topic_id) |
| 7 | `rec_material_bundles` | Ordered collections of materials | `title`, `created_by`, `is_active` | No school_id column; model/controller may reference it — GAP |
| 8 | `rec_bundle_materials_jnt` | Junction: bundle ↔ material with ordering | `bundle_id`, `material_id`, `sequence_order`, `is_mandatory` | UNIQUE on (bundle_id, material_id); CASCADE delete |
| 9 | `rec_recommendation_rules` | IF-THEN rules linking triggers to content | `trigger_event_id`, `class_id`, `subject_id`, `topic_id`, `min_score_pct`, `max_score_pct`, `assessment_type_id`, `recommendation_mode_id`, `target_material_id`, `target_bundle_id`, `dynamic_material_type_id`, `dynamic_purpose_id`, `priority`, `is_automated`, `is_active` | Index on trigger_event_id |
| 10 | `rec_student_recommendations` | Dispatched assignments per student | `uuid` CHAR(36) UNIQUE, `student_id`, `rule_id` nullable, `material_id`, `bundle_id`, `status` ENUM(CANCELLED/COMPLETED/EXPIRED/IN_PROGRESS/PENDING/SKIPPED/VIEWED), `priority` ENUM(CRITICAL/HIGH/MEDIUM/LOW), `assigned_date`, `due_date`, `assigned_at`, `first_viewed_at`, `completed_at`, `score_achieved`, `student_rating`, `student_feedback`, `reassigned_quiz`, `reassigned_quiz_id`, `manual_assigned_by`, `triggered_by_quiz_id`, `triggered_by_quest_id` | deleted_at added via 2026_06_18 migration; NO created_at column; MISSING triggered_by_result_id; MISSING is_published |

### DDL Gaps Confirmed

| Gap | Detail |
|-----|--------|
| `rec_student_recommendations.triggered_by_result_id` | Engine creates records with this field but migration has no such column — silently ignored by Eloquent |
| `rec_student_recommendations.is_published` | Engine creates records with `is_published` but column absent from migration |
| `rec_student_recommendations` — no `created_at` | Migration sets `updated_at` manually; no `created_at` column — Eloquent may use wrong timestamps |
| `rec_material_bundles` — no `school_id` | Controller/model reference `school_id`; DDL has no such column |
| `rec_performance_snapshots` — not created | V2 proposed table; `PerformanceSnapshot` model also not present in code; issue resolved by omission |
| `RecAssessmentTypePolicy` — file missing | Policy class referenced in AppServiceProvider import comment but file does not exist |

---

## Known Gaps & Open Issues

### P0 — Critical Security / Blockers

| ID | Issue | Location | Status |
|----|-------|----------|--------|
| SEC-REC-001 | `Gate::any()` return value discarded in `tabIndex()` and `tabIndex_2()` — authorization completely bypassed; any authenticated user can access both tab index screens | `RecommendationController` L:24, L:143 | OPEN |
| SEC-REC-002 | `StudentRecommendationController` — 10 methods (show, edit, update, destroy, trashed, restore, forceDelete, markAsCompleted, updateStatus, addRating) all use `tenant.student-recommendation.create` instead of correct permission — permanent delete grantable to any CREATE user | `StudentRecommendationController` | OPEN |
| SEC-REC-003 | `EnsureTenantHasModule:REC` middleware not applied to recommendation route group — module accessible even if school has not licensed REC | RouteServiceProvider or module web.php group | OPEN |
| BUG-REC-001 | `rec_student_recommendations` has no `triggered_by_result_id` column but engine inserts it — silently discarded; audit trail for automated triggers is lost | Migration + RecommendationEngineService | OPEN |
| BUG-REC-002 | `rec_student_recommendations` has no `is_published` column but engine inserts it — silently discarded | Migration + RecommendationEngineService | OPEN |
| BUG-REC-003 | `rec_student_recommendations` has no `created_at` column — Eloquent timestamp handling broken | Migration | OPEN |

### P1 — Architecture / Functionality Gaps

| ID | Issue | Status |
|----|-------|--------|
| GAP-REC-001 | `RecAssessmentTypePolicy` file does not exist; policy registration absent from module ServiceProvider | OPEN |
| GAP-REC-002 | No `ExpireRecommendationsCommand` Artisan command — overdue recommendations never auto-expired | OPEN |
| GAP-REC-003 | No status transition validation in `updateStatus()` — arbitrary transitions allowed (e.g., COMPLETED → PENDING) | OPEN |
| GAP-REC-004 | `rec_material_bundles` has no `school_id` column but model/controller reference it — silent data issue | OPEN |
| GAP-REC-005 | Permission naming inconsistency: some controllers still use `tenant.trigger-events.viewAny` (plural) instead of `tenant.trigger-event.viewAny` (singular) — standard broken | OPEN |
| GAP-REC-006 | ~~`RecommendationMaterialController` — `create()` and `edit()` methods lack `Gate::authorize()` calls~~ | **CLOSED — FALSE POSITIVE** (confirmed L41 and L201 have Gate::authorize) |
| GAP-REC-007 | No analytics dashboard controller or views — FR-REC-18 entirely unbuilt | OPEN |
| GAP-REC-008 | No Student Portal API endpoints for recommendations | OPEN |

### P2 — Enhancements

| ID | Issue | Status |
|----|-------|--------|
| ENH-REC-001 | `rec_performance_snapshots` table not created — DYNAMIC_BY_COMPETENCY mode works only on current-quiz scope, not rolling window | OPEN |
| ENH-REC-002 | Scheduled weekly recommendation batch (ON_SCHEDULED_WEEKLY trigger) not implemented | OPEN |
| ENH-REC-003 | Notification (NTF) integration: no notification fired when recommendation assigned | OPEN |
| ENH-REC-004 | Bulk assignment controller for post-exam remediation class-wide assignments | OPEN |
| ENH-REC-005 | Parent Portal read-only recommendation view | OPEN |
| ENH-REC-006 | `materials-old/` deprecated views directory (if still present) — cleanup needed | VERIFY |

---

## Design Decisions Made

| Decision | Detail |
|----------|--------|
| Trigger is `QuizQuestResultPublished` event (not `ExamResultSubmitted`) | The live engine listens to `QuizQuestResultPublished` from LMS Quiz/Quest modules (not LmsExam). Exam integration is future scope. |
| Priority computed from wrong-answer difficulty bands | Engine reads `qns_question_statistics` difficulty_index (D31 pattern): EASY (≥70%) wrong answers → HIGH priority; MODERATE (30-69%) → MEDIUM; HARD (<30%) → LOW; no stats → MEDIUM default. Mis-keyed questions (discrimination_index < 0) skipped. |
| Idempotency via (student_id + rule_id + triggered_by_quiz_id + triggered_by_quest_id) composite check | Engine skips creating duplicate recommendations using this 4-column uniqueness check before insert |
| DB transaction wraps all recommendation inserts for a result | `DB::transaction()` wraps the loop that creates StudentRecommendation records — atomicity guaranteed |
| `rec_student_recommendations` soft-deletes confirmed live | `deleted_at` migration (2026_06_18) applied — SoftDeletes trait now has backing column |
| `CANCELLED` status added to live ENUM | Live migration shows 7 statuses: CANCELLED added beyond V2's 6 — controller validates it |
| `slb_complexity_level` (singular) confirmed as correct table name | DDL FK references singular; `slb_complexity_levels` (plural) in store() is a bug |

---

## Cross-Module Dependencies

### Inbound (REC reads from)

| Source Module | Table(s) | Purpose |
|---------------|----------|---------|
| SchoolSetup | `sch_classes`, `sch_subjects`, `sch_teachers` | Scope rules and materials; manual_assigned_by FK |
| Syllabus | `slb_topics`, `slb_performance_categories`, `slb_complexity_level` | Topic scope for rules/materials; difficulty categorization |
| QuestionBank | `qns_media_store`, `qns_question_statistics`, `qns_questions_bank` | Media references in materials; wrong-answer difficulty stats for priority computation |
| StudentProfile | `std_students` | student_id FK for dispatched recommendations |
| LmsQuiz | `lms_quizzes`, `lms_quiz_questions`, `lms_quiz_quest_results`, `lms_quiz_quest_attempts`, `lms_quiz_quest_attempt_answers` | Trigger events; wrong-answer analysis |
| LmsQuests | `lms_quests`, `lms_quest_questions` | Same as LmsQuiz for quest-type assessments |
| SystemConfig | `sys_dropdowns` | Material type, purpose, content source dropdown values |

### Outbound (REC feeds)

| Target Module | Data Provided | Mechanism |
|---------------|---------------|-----------|
| StudentPortal | `rec_student_recommendations` | Student portal reads student's pending/active recommendations (API needed) |
| ParentPortal | `rec_student_recommendations` (future) | Parent reads child's recommendations (ENH) |
| Dashboard | Completion stats | Dashboard widgets (not yet implemented) |
| Notifications | NewRecommendationAssigned (future) | NTF integration on dispatch (ENH) |

### Event Flow

```
LmsQuiz/LmsQuests publishes result
    → QuizQuestResultPublished event fired
    → GenerateRecommendationsListener::handle() (synchronous — NOT queued: P1 risk)
    → RecommendationEngineService::processResult()
    → rec_student_recommendations rows created
```

**P1 Risk:** Listener is synchronous (not queued job); heavy rule evaluation blocks the HTTP response of the result publish endpoint.

---

## Lessons Learned

- [2026-06-30 | pa-business-analyst] REC completion was reported as ~39% in V2 (2026-03-26) but live code shows ~60-65% — engine service, event listener, and all 18 FormRequests were built after V2 was authored.
- [2026-06-30 | pa-business-analyst] The trigger event is `QuizQuestResultPublished` (REC-specific event), not `ExamResultSubmitted` as V2 speculated — LmsExam integration is future scope.
- [2026-06-30 | pa-business-analyst] Priority computation in the engine uses qns_question_statistics difficulty_index (D31 formula) — the REC engine depends on the QuestionBank statistics pipeline; if stats are absent (cold-start), default MEDIUM is used.
- [2026-06-30 | pa-business-analyst] `rec_student_recommendations` migration is missing `triggered_by_result_id`, `is_published`, and `created_at` columns — these are inserted by the engine and silently dropped by Eloquent — requires schema migration.
- [2026-06-30 | pa-business-analyst] `PerformanceSnapshot` model mentioned in V2 is NOT present in live code — likely removed. No `rec_performance_snapshots` table exists. DYNAMIC_BY_COMPETENCY currently resolves materials without a rolling-window snapshot.

---

## Pending Next Steps

1. **P0 — Fix `Gate::any()` bypass** in `RecommendationController::tabIndex()` and `tabIndex_2()`: replace with `abort_unless(Gate::any([...]), 403)`.
2. **P0 — Fix `StudentRecommendationController` permissions** in all 10 methods — each must use the correct `tenant.student-recommendation.{action}` permission.
3. **P0 — Add missing schema columns**: `triggered_by_result_id`, `is_published`, `created_at` to `rec_student_recommendations` via migration.
4. **P1 — Create `RecAssessmentTypePolicy`** and register it in module ServiceProvider.
5. **P1 — Build `ExpireRecommendationsCommand`** (nightly Artisan command) and register in scheduler.
6. **P1 — Make event listener async** — dispatch a queued Job instead of processing inline in the Listener.
7. **P1 — Resolve `rec_material_bundles.school_id` discrepancy** — either add column or remove references from model/controller.
8. **P1 — Build Analytics Dashboard** (`RecommendationAnalyticsController` + views, CSV export).
9. **P2 — Add 20+ Pest tests** (0 currently exist; engine, lifecycle, deduplication, auth, expiry all need tests).
10. **P2 — Student Portal API endpoints** for recommendation list/view/status-update/rating.
11. **Technical Auditor** — run 12-layer audit for SEC-REC-001 through SEC-REC-003 before any production deploy.

---

## New Findings from Mode X Audit (2026-06-30, pa-technical-auditor)

| Code | Severity | Finding |
|------|----------|---------|
| BUG-REC-003 | P0 | `StudentRecommendation::create()` always fails — `created_at` column absent from migration but `$timestamps = true` (default) — engine non-functional |
| BUG-REC-004 | P1 | `media_id` declared as `unsignedInteger FK` in migration but cast as `array` in model and stored as JSON array in controller — all file attachment saves fail |
| MIG-REC-001 | P1 | `difficulty_band` in `$fillable` + FormRequest + engine code but ABSENT from migration — difficulty-band filtering permanently disabled; rules ignore difficulty tier |
| D39-REC-001 | P1 | Zero REC permissions seeded anywhere — all FormRequest authorize() returns false for non-super-admin in fresh tenant — all CRUD returns 403 |
| ORM-REC-001 | P1 | TriggerEventPolicy not registered in ServiceProvider; RecAssessmentTypePolicy file missing entirely |
| DAT-REC-001 | P1 | Engine idempotency check is software-level only — no DB UNIQUE constraint — concurrent result publishes can insert duplicate recommendations |
| DAT-REC-002 | P1 | `difficulty_band` always null → engine difficulty-band filter skip never fires → all rules match all difficulty tiers |
| DEPLOY-REC-001 | P1 | `env('LMS_DISK')` called in RecommendationMaterial model (L144) and controller (L125, L289, L301) — returns null after config:cache — all file ops break in production |
| XSS-REC-001 | P2 | 7x `{!! description !!}` / `{!! content_text !!}` in 5 show.blade.php views — Stored XSS risk |
| DDL-REC-001 | P2 | `idx_recRule_trigger` index references `trigger_event` (column is `trigger_event_id`); `fk_recMat_competency` references `competency_code` (column is `competency_id`) |
| ORM-REC-002 | P2 | `MaterialBundle::school()` uses `school_id` FK not in migration — show() always renders without school info |
| VAL-REC-001 | P2 | Double-validation (FormRequest + inline validate) in 5 controllers — conflicting `status` field rules |
| VAL-REC-002 | P2 | `is_automated` overridden via `$request->has()` in RecommendationRuleController:185 — bypasses FormRequest validated boolean |
| PERF-REC-001 | P1 | Unbounded `Student::get()` in 4 controller methods — full student roster loaded into PHP memory per page |
| PERF-REC-002 | P1 | Engine listener synchronous (not ShouldQueue) — blocks HTTP response on every result-publish |
| DEAD-REC-001 | P3 | Dead `use BundleMaterialJunction` import in MaterialBundleController:14 (class is `BundleMaterialJnt`) |
| DEAD-REC-002 | P3 | Commented `// dd($request->all())` in RecommendationRuleController:61 |
| GAP-REC-006 | CLOSED | FALSE POSITIVE — RecommendationMaterialController::create() L41 and edit() L201 DO have Gate::authorize() |

## Version History

| Date | Agent | Summary |
|------|-------|---------|
| 2026-06-30 | pa-technical-auditor | Mode X 12-layer audit complete — 3 P0, 16 P1, 13 P2, 3 P3 found; GAP-REC-006 closed as false positive; new codes BUG-REC-003/004, MIG-REC-001, D39-REC-001, ORM-REC-001/002, DAT-REC-001/002, DEPLOY-REC-001, XSS-REC-001, DDL-REC-001, VAL-REC-001/002, PERF-REC-001/002, DEAD-REC-001/002 |
| 2026-06-30 | pa-business-analyst | Initial seed — verified all counts against live code + migrations; reconciled V2 doc (2026-03-26) with live state; identified SEC-REC-001/002/003 and BUG-REC-001/002/003; FRD generated |
