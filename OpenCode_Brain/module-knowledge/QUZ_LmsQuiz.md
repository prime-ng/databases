# Module Knowledge — LmsQuiz (QUZ)

> Seeded 2026-06-29 by Business Analyst (pa-business-analyst) from a live read of the Laravel module
> (`/Users/bkwork/Herd/prime_ai/Modules/LmsQuiz`), `LmsQuiz_DDL_v2.sql`, `StudentAttempt_DDL_v4.sql`,
> central tenant migrations, V2 requirement, and V1 screen specs. Every schema claim three-way
> reconciled (DDL ↔ migration ↔ model). All counts verified against the filesystem — nothing asserted
> that was not confirmed.

---

## Module Facts

| Fact | Value (verified 2026-06-29) |
|------|------------------------------|
| Module name / code / prefix | LmsQuiz / **QUZ** / `lms_` (**SHARED** prefix — see "Prefix Sharing") |
| Layer | Tenant (`tenant_db`) — data isolated per school (database-per-tenant, no `tenant_id` column) |
| App path | `/Users/bkwork/Herd/prime_ai/Modules/LmsQuiz` |
| Owned DDL | `2-DDL_Tenant_Consolidated/LmsQuiz_DDL_v2.sql` (**6** CREATE TABLE) |
| Quiz-owned tables | **6**: `lms_assessment_types`, `lms_difficulty_distribution_configs`, `lms_difficulty_distribution_details`, `lms_quizzes`, `lms_quiz_questions`, `lms_quiz_allocations` |
| Shared runtime tables (DDL-owned by StudentAttempt) | **3**: `lms_quiz_quest_attempts`, `lms_quiz_quest_attempt_answers`, `lms_quiz_quest_results` (shared QUIZ+QUEST) |
| Migrations | **6** quiz + **3** runtime in central `database/migrations/tenant/` (2026_06_15 / 2026_06_16) — NOT in module dir (module `database/migrations/` is `.gitkeep` only) |
| Controllers | **6**: `LmsQuizController` (~1280 ln), `LmsQuizReportController` (~1900 ln / 68KB), `QuizQuestionController` (~57KB), `QuizAllocationController` (~25KB), `DifficultyDistributionConfigController`, `AssessmentTypeController` |
| Models | **6**: `Quiz`, `QuizQuestion`, `QuizAllocation`, `AssessmentType`, `DifficultyDistributionConfig`, `DifficultyDistributionDetail` (runtime `QuizQuestAttempt`/`QuizQuestResult`/`QuizQuestAttemptAnswer` models live in `Modules\StudentPortal\Models`) |
| Services | **7**: `RemedialQuizGenerationService` (domain logic, ~12KB), `QuizQueryService`, + 5 `*UsageCheckService` delete-guards (AssessmentType, DifficultyConfig, QuizAllocation, QuizQuestion, Quiz) |
| FormRequests | **5**: `QuizRequest`, `QuizQuestionRequest`, `QuizAllocationRequest`, `AssessmentTypeRequest`, `DifficultyDistributionConfigRequest` |
| Policies | **6** in module's own `app/Policies/`: `QuizPolicy`, `QuizQuestionPolicy`, `QuizAllocationPolicy`, `AssessmentTypePolicy`, `DifficultyDistributionConfigPolicy`, `LmsQuizReportPolicy` |
| Providers | **3**: `LmsQuizServiceProvider`, `EventServiceProvider` (empty `$listen`), `RouteServiceProvider` |
| Console commands | **0** (none registered; `registerCommandSchedules()` is an empty stub) |
| Seeders | **7**: `LmsQuizDatabaseSeeder`, `LmsQuizSeeder`, `LmsQuizQuestionSeeder`, `LmsQuizAllocationSeeder`, `LmsAssessmentTypeSeeder`, `LmsDifficultyDistributionConfigSeeder`, `LmsReportsFullDemoSeeder` |
| Blade views | **42** across 14 folders (quiz x5, quiz-question x6, quiz-allocation x5, assessment-type x5, difficulty-config x5, reports +6 partials, summary x3, dashboard, activity logs x2, tab_module, components) |
| Tests | **0** (only `.gitkeep` in `tests/Unit` and `tests/Feature`) |
| Routes | Module `routes/web.php` (D22 — module owns routes) + minimal `routes/api.php` (apiResource `lmsquizzes`); `routes/console.php` empty |
| Route group prefix | **`lms-quize`** / name prefix `lms-quize.` — **TYPO (extra 'e') STILL PRESENT** (see Known Gaps) |
| FRD status | FRD + Complete Analysis Pack created 2026-06-29 (`QUZ_FRD_Complete_2026-06-29.md`) |
| Completion estimate | **~75–80%** (teacher-facing setup/build/allocate ~95%; reports/analytics + remedial auto-gen now BUILT; student attempt *player* owned by StudentPortal; revised UP from V2's "~70%") |

### Status correction vs V2 (V2 dated 2026-03-26 is stale in several areas)
The live module is materially ahead of the V2 requirement. Confirmed against live code:
- **UUID storage FIXED** — `Quiz::boot()` now uses `Str::uuid()->getBytes()` (V2 BUG-04 / NFR-QUZ-09 resolved).
- **`only_unused_questions` + `only_authorised_questions` NOW in `$fillable`** (V2 BUG-05/06 resolved).
- **Gate active on `index()`** and across CRUD controllers (11–18 gates each) — V2 "verify" resolved.
- **Reports/analytics NOW EXIST** — `LmsQuizReportController` (index + filter-dependencies) plus
  `LmsQuizController::report()` / `attemptDetail()` read `lms_quiz_quest_attempts`/`_results` (V2 said FR-QUZ-009 0%).
- **Automatic quiz generation NOW EXISTS (remedial path)** — `RemedialQuizGenerationService::generate()`
  builds a system-generated quiz from the system-default difficulty config (V2 FR-QUZ-010 0% → built).
- **Recommendation integration NOW EXISTS** — `QuizAllocationController::publishRecommendations()`.
Per the [2026-06-27] cross-module lesson, never trust a stated % without an `ls`/grep of the live tree.
**Still open from V2:** route typo `lms-quize`/`quize`; no `EnsureTenantHasModule`/`hasModule:QUZ` guard;
no `DB::transaction` in CRUD store/update/destroy; all 5 FormRequest `authorize()`=true; 0 tests.

---

## Prefix Sharing (CRITICAL — read before attributing tables)
`lms_` is shared by **LmsExam (EXM)**, **LmsQuiz (QUZ)**, **LmsQuests (QST)**, **LmsHomework (HMW)** and
historically the EventEngine rule engine. Attribution for QUZ:

**Owned by LmsQuiz (`LmsQuiz_DDL_v2.sql`, 6 tables — setup/definition + shared masters):**
`lms_assessment_types`*, `lms_difficulty_distribution_configs`*, `lms_difficulty_distribution_details`*,
`lms_quizzes`, `lms_quiz_questions`, `lms_quiz_allocations`.
(* `lms_assessment_types`, `lms_difficulty_distribution_configs`/`_details` are **SHARED MASTERS** owned by
LmsQuiz but consumed read-only by LmsQuests (`Quest` model) and LmsExam (`ExamPaper` model). They carry a
`usage_type_id`/`assessment_usage_type_id` FK to `qns_question_usage_type` to scope rows to QUIZ/QUEST/EXAM.)

**Shared runtime/result tables — quiz+quest DOMAIN but DDL-OWNED by the StudentAttempt engine**
(`StudentAttempt_DDL_v4.sql`, also mirrored in `StudentPortal_DDL_v4.sql`):
`lms_quiz_quest_attempts`, `lms_quiz_quest_attempt_answers`, `lms_quiz_quest_results`.
- These hold BOTH quiz and quest attempts, discriminated by `assessment_type` ENUM('QUIZ','QUEST').
- The **models** (`QuizQuestAttempt`, `QuizQuestAttemptAnswer`, `QuizQuestResult`) live in
  **`Modules\StudentPortal\Models\`** — LmsQuiz controllers `use` them for reporting/analytics only.
- The online attempt *player* (student taking the quiz; writing attempts/answers) is a **StudentPortal**
  responsibility. LmsQuiz **consumes** the results for teacher reports, analytics, drill-down, and the
  remedial-trigger callback. Same split as LmsExam.

**Naming drift to remember:** V2 used aspirational column names for the runtime tables
(`assessment_id`, `allocation_id`, `completed_at`, `total_score`). Actual live column names are
`quiz_id`/`quest_id`, `quiz_allocation_id`/`quest_allocation_id`, `submitted_at`/`auto_submitted_at`,
`score_obtained`. (`lms_quiz_quest_results` does carry a redundant `assessment_id` cache + `assessment_type`.)

---

## DDL Table Inventory — owned (6) — three-way reconciled (DDL ↔ migration ↔ model)

| Table | Purpose | Key constraints / notes |
|-------|---------|--------------------------|
| `lms_assessment_types` | Pedagogical quiz/assessment categories (Challenge, Practice, Diagnostic, Remedial, Revision, Re-Test, Enrichment); shared master | UNIQUE(`code`, 20); FK `assessment_usage_type_id`→`qns_question_usage_type`; no `created_by`. **DDL-SPEC BUG: missing comma after `UNIQUE KEY uq_quiz_type_code (code)` before the CONSTRAINT (line 65–66) — literal DDL run would fail; migration ships correctly.** |
| `lms_difficulty_distribution_configs` | Named difficulty profile header (% of Easy/Med/Hard per type) — shared master | UNIQUE(`code`, 50); FK `usage_type_id`→`qns_question_usage_type`; `use_for_system_generated_quiz` (only one may be 1 — enforced in model `booted()` saving hook); no `created_by` |
| `lms_difficulty_distribution_details` | Child rows: per question-type × complexity × (optional Bloom/cognitive/specificity) min%/max%/marks | FK→config CASCADE, →`slb_question_types`, →`slb_complexity_level`; optional FKs `bloom_id`/`cognitive_skill_id`/`ques_type_specificity_id`; no `created_by` |
| `lms_quizzes` | Quiz master (academic hierarchy + settings + grading + generation flags) | UNIQUE(`uuid` BINARY(16)), UNIQUE(`quiz_code`); FKs session/class/subject/topic/type/diff-config/creator; `status` VARCHAR DRAFT/PUBLISHED/ARCHIVED (hard string, not dropdown FK); has `created_by` |
| `lms_quiz_questions` | Junction: QB question → quiz, with ordinal + marks override | UNIQUE(`quiz_id`,`question_id`); FK→`lms_quizzes` CASCADE, →`qns_questions_bank` CASCADE; no `created_by` |
| `lms_quiz_allocations` | Assigns published quiz to CLASS/SECTION/GROUP/STUDENT with timing windows | `allocation_type` ENUM; `target_table_name`+`target_id` (app-level polymorphic FK, no DB FK); `is_auto_publish_result` overrides quiz-level; FK→quiz CASCADE, →`sys_users` (assigned_by); no `created_by` |

### Shared runtime tables (StudentAttempt-owned) — quiz-relevant columns
- `lms_quiz_quest_attempts` — one row per student attempt. `assessment_type` ENUM(QUIZ/QUEST); `quiz_id`
  XOR `quest_id` (CHECK-enforced); `quiz_allocation_id`/`quest_allocation_id`; `attempt_number`;
  `status` ENUM(NOT_STARTED/IN_PROGRESS/SUBMITTED/TIMEOUT/ABANDONED/CANCELLED/REASSIGNED);
  `score_obtained`/`max_score`/`percentage`/`is_passed`; proctoring `ip_address`/`browser_agent`/
  `device_info`/`violation_count`. Two UNIQUE keys: (student, quiz, attempt_number) and (student, quest, attempt_number).
- `lms_quiz_quest_attempt_answers` — per-question response; `selected_option_id` / `selected_option_ids`
  (JSON multi-MCQ) / `answer_text` / `attachment_data`; `marks_obtained`/`max_marks`/`is_correct`/
  `is_evaluated`/`evaluated_by`; telemetry `time_spent_seconds`/`change_count`. UNIQUE(attempt_id, question_id).
- `lms_quiz_quest_results` — final published result; `assessment_type`+`assessment_id` (cache),
  `total_marks_obtained`/`max_marks`/`percentage`/`grade_obtained`/`is_passed`/`rank_in_class`/
  `percentile`; `is_published`/`published_at`/`teacher_remarks`. UNIQUE(attempt_id).

---

## Known Gaps & Open Issues

### P0 — Security
- **SEC-QUZ-001 / D30:** ALL 5 FormRequest `authorize()` return hardcoded `true` (`QuizRequest`,
  `QuizQuestionRequest`, `QuizAllocationRequest`, `AssessmentTypeRequest`, `DifficultyDistributionConfigRequest`).
  Defense-in-depth collapses to controller Gates only. (Controllers DO carry permission-string Gates —
  11–18 each — so most actions are still guarded at the controller layer; the report controller has only 1.)
- **SEC-QUZ-002 (policy-overwrite bug):** `LmsQuizServiceProvider::registerPolicies()` binds
  `Gate::policy(Quiz::class, QuizPolicy::class)` and then `Gate::policy(Quiz::class, LmsQuizReportPolicy::class)`.
  Laravel keeps only the LAST mapping per model → **`QuizPolicy` is dead** for model-resolved gates; only
  `LmsQuizReportPolicy` survives for `Quiz`. (Impact limited because controllers use permission-string gates,
  not `$this->authorize($model)`.) Same pattern as EXM SEC-EXM-009 / HMW A-AUTH-2.

### P1 — Functional / behavioural defects (NEW, found in this seeding)
- **BUG-QUZ-001 (CONFIRMED, recommendation publishing broken):** `QuizAllocationController::publishHiddenRecommendations()`
  (line ~538) queries `lms_quiz_quest_attempts as a` filtering `where('a.allocation_id', $allocationId)` —
  **column `allocation_id` does not exist** on that table (real columns: `quiz_allocation_id` /
  `quest_allocation_id`). The query throws / returns nothing → `publishRecommendations()` never publishes
  hidden `StudentRecommendation` rows. (The `allocation_id` keys elsewhere in the file are Log-context arrays,
  harmless; this is the one in a live SQL JOIN.)
- **BUG-QUZ-002 (NEW, remedial allocation target mismatch):** `RemedialQuizGenerationService::createAllocation()`
  sets `allocation_type='STUDENT'`, `target_table_name='std_students'`, but `target_id => $student->user_id`
  (a `sys_users.id`). `QuizAllocation::getTargetNameAttribute()` resolves STUDENT via
  `Student::find($target_id)` (a `std_students.id`) → label resolution and any student-scoped attempt lookup
  using `target_id` will mis-resolve. Storing `user_id` where the read path expects `std_students.id`.
- **BUG-QUZ-003 (NEW, only-unused filter destroys query):** `RemedialQuizGenerationService::fetchQuestionsByConfig()`
  — when `only_unused_questions` is set, the branch does `$query->select('question_bank_id')->from('qns_question_usage_log')...`,
  which **overwrites the QuestionBank select/from** instead of adding a NOT-IN exclusion. The intended "exclude
  already-used questions" rule (BR) is not implemented; the query returns usage-log rows, not filtered questions.
- **BUG-QUZ-004 (route typo, confirmed STILL PRESENT):** `RouteServiceProvider` uses prefix `lms-quize`
  (extra 'e') and `Route::resource('quize', ...)`; all named routes are `lms-quize.quize.*`. External links to
  the correct `lms-quiz`/`quiz` spelling 404. (V2 BUG-01/02/03.)
- **BUG-QUZ-005 (no module-license guard, confirmed):** `RouteServiceProvider::mapWebRoutes()` applies
  `InitializeTenancyByDomain` + `PreventAccessFromCentralDomains` + `EnsureTenantIsActive` + `auth` + `verified`,
  but **no `EnsureTenantHasModule` / `hasModule:QUZ`** → a tenant without the LmsQuiz licence can reach quiz routes.
  (V2 BUG-08 / NFR-QUZ-07.)
- **BUG-QUZ-006 (no transaction on CRUD, confirmed):** `LmsQuizController` has **0** `DB::transaction`; quiz
  create/update/destroy perform multiple writes (quiz + questions + totals) non-atomically. (V2 BUG-09 / NFR-QUZ-10.)
  (`RemedialQuizGenerationService::generate()` DOES wrap its writes in `DB::transaction`.)

### P2 — Data / schema quality
- **DATA-QUZ-001:** `created_by` missing on `AssessmentType`, `DifficultyDistributionConfig`,
  `DifficultyDistributionDetail`, `QuizQuestion`, `QuizAllocation` models AND on the underlying owned DDL
  tables (only `lms_quizzes` has `created_by`). No author audit on master/junction/allocation rows.
- **SCH-QUZ-001 (D29 tension):** `lms_quizzes.status` is a hard VARCHAR (DRAFT/PUBLISHED/ARCHIVED) and
  `lms_quiz_allocations.allocation_type` / `lms_quiz_quest_attempts.status` are hard ENUMs, not
  `sys_dropdowns` FK-driven — diverges from the D29 "prefer config-driven dropdown" rule.
- **DATA-QUZ-002 (DDL-spec only):** `LmsQuiz_DDL_v2.sql` missing-comma syntax error on `lms_assessment_types`
  (line 65–66). Migration ships correctly; fix belongs to the DDL spec owner. (Same DDL-vs-migration pattern as EXM DAT-EXM-002.)
- **TEST-QUZ-001:** 0 automated tests for a module with grading/scoring/allocation logic (V2 target was ≥40).

### Reassessed / not issues
- UUID binary storage, `$fillable` completeness, and Gate-on-`index()` (all V2 P0/P1) are **FIXED** in live code.
- Permission strings are clean single-`tenant.` prefix (D24 baseline OK); 0 `dd()/dump()/var_dump()` in
  controllers; `$request->all()` appears only inside Log-context arrays and a report filter snapshot
  (not mass-assignment) — acceptable.

---

## Design Decisions (observed in code/DDL)
- **D-QUZ-1:** Shared masters owned by LmsQuiz (`lms_assessment_types`, `lms_difficulty_distribution_configs`/`_details`)
  are scoped to a usage type via FK `qns_question_usage_type` so QUIZ/QUEST/ONLINE_EXAM/OFFLINE_EXAM rows
  coexist in one table; consuming modules filter by usage type. Architectural suggestion (V2 #18): extract to a
  neutral `LmsMaster` module to remove the LmsQuiz→Quest/Exam unidirectional coupling. Not done.
- **D-QUZ-2:** Quiz code auto-generated in `Quiz::boot()` creating hook:
  `QUIZ_{session}_{class}_{subject}_{lesson}_{topic}_{random4}` (UNIQUE). UUID = `Str::uuid()->getBytes()` into BINARY(16).
- **D-QUZ-3:** Difficulty profile drives question selection: each detail row gives min%/max% of total questions
  for a (question-type × complexity) bucket; the difficulty builder and `RemedialQuizGenerationService` use a
  midpoint-% strategy to compute per-bucket counts.
- **D-QUZ-4:** `lms_quiz_allocations.is_auto_publish_result` OVERRIDES quiz-level `auto_publish_result` so
  different target groups can have different result-release timing.
- **D-QUZ-5:** Single system-default difficulty config — `DifficultyDistributionConfig::booted()` saving hook
  forces `use_for_system_generated_quiz` to exclusive (sets all others to 0 when one is turned on).
- **D-QUZ-6 (remedial trigger):** `RemedialQuizGenerationService` is invoked from
  `StudentPortal`'s quiz-attempt submit when a student fails; it builds a PUBLISHED, system-generated,
  single-attempt remedial quiz (MCQ-only) scoped to the failing quiz's subject/class/topic, allocates it to the
  student, and writes `qns_question_usage_log` audit rows.
- **D-QUZ-7:** Result visibility is layered — `show_result_immediately` (own score on submit) vs
  `auto_publish_result`/allocation override (class results at `result_publish_date`) vs manual publish.
- **D-QUZ-8 (per D22):** The module owns its routes in `routes/web.php` via `RouteServiceProvider` (prefix
  `lms-quize`), not the central `routes/tenant.php` the V2 doc referenced.

---

## Cross-Module Dependencies

| Direction | Module | What |
|-----------|--------|------|
| Inbound (reads) | QuestionBank (QNS) | `qns_questions_bank` (question pool, `for_quiz`, `complexity_level_id`, `question_type_id`), `qns_question_options` (MCQ), `qns_question_usage_type` (usage scoping), `qns_question_usage_log` (unused filter + remedial audit) |
| Inbound (reads) | SchoolSetup (SCH) | `sch_classes`, `sch_subjects`, sections, `sch_entity_groups`, class-section junction (allocation targets, cascading dropdowns) |
| Inbound (reads) | Syllabus (SLB) | `slb_lessons`*, `slb_topics`, `slb_question_types`, `slb_complexity_level`, `slb_bloom_taxonomy`, `slb_cognitive_skill`, `slb_ques_type_specificity` (*DDL comments say `sch_lessons` but the migration + model FK target `slb_topics`; lesson resolves via Syllabus `Lesson` model) |
| Inbound (reads) | StudentProfile (STD) | `std_students` (attempt subject, allocation STUDENT target) |
| Inbound (reads) | GlobalMaster / Prime | `glb_academic_sessions`, `sys_users` (creator/assigner) |
| Outbound (consumed by) | LmsQuests (QST) | imports `AssessmentType` + `DifficultyDistributionConfig` models; shares runtime tables (assessment_type='QUEST') |
| Outbound (consumed by) | LmsExam (EXM) | `ExamPaper` imports `DifficultyDistributionConfig` (cross-module model coupling) |
| Outbound (writes) | Recommendation (REC) | `publishRecommendations()` flips `StudentRecommendation.is_published` (triggered_by_quiz_id) — currently broken by BUG-QUZ-001 |
| Runtime (owns player) | StudentPortal | owns the attempt player + `QuizQuestAttempt`/`QuizQuestResult`/`QuizQuestAttemptAnswer` models; calls back to `RemedialQuizGenerationService` |
| Runtime (planned) | Notification | result-publish / allocation alerts (no LmsQuiz-side notification code found) |

---

## FRD Summary
| Item | Value |
|------|-------|
| FRD file | `4-Requirement_Module_wise/0-FRD_Documents/QUZ_FRD_Complete_2026-06-29.md` (Complete Analysis Pack — FRD is Section A) |
| Date | 2026-06-29 |
| Functional Requirements (REQ-) | 18 |
| Business Rules (BR-) | 34 |
| Workflows | 5 |
| Reports (RPT-) | 5 |
| Enhancements (ENH-) | 7 |
| Priority split | P0 = 9 · P1 = 7 · P2 = 2 |

## Pending Next Steps (post-FRD handoffs)
1. DDL Schema Gap Analysis — DB Architect / Technical Auditor (owned 6 + shared 3 runtime tables; verify
   `created_by` additive need + DDL syntax fix on `lms_assessment_types`).
2. Application Code Gap — Technical Auditor (Mode B; verify reports/analytics + remedial-gen coverage,
   confirm BUG-QUZ-001/002/003).
3. Business-Rule Enforcement + Security audit — Technical Auditor (Mode C; SEC-QUZ-001 D30, SEC-QUZ-002
   policy-overwrite, BUG-QUZ-004 route typo, BUG-QUZ-005 module guard, BUG-QUZ-006 transactions).
4. Completion Scoring (6-dim) — Status_Analyzer.
5. Test Coverage Gap — Testing Architect (currently 0 tests).

## Lessons Learned
- [2026-06-29 | Business Analyst] QUZ owns the LMS *shared masters* (`lms_assessment_types`,
  `lms_difficulty_distribution_configs`/`_details`) consumed by QST and EXM — attribute these to QUZ but flag
  the cross-module model coupling. The 3 runtime tables (`lms_quiz_quest_*`) are quiz+quest shared and
  DDL-owned by StudentAttempt; their models live in StudentPortal. Never attribute runtime tables to QUZ's DDL.
- [2026-06-29 | Business Analyst] V2 (2026-03-26) badly understated QUZ: it called reports, analytics, and
  auto-generation "0%/absent" and listed UUID + fillable + Gate bugs as open — all are BUILT/FIXED in the live
  tree. Always grep live before trusting a stated %.
- [2026-06-29 | Business Analyst] Found 3 live bugs the V2 doc did not: a non-existent-column JOIN
  (`a.allocation_id` vs `quiz_allocation_id`) silently breaks recommendation publishing; the remedial service
  stores `user_id` in a `target_id` that the read path resolves as `std_students.id`; and the only-unused filter
  overwrites the question query instead of excluding. Static "looks complete" controllers can still carry
  column-name and identity-mapping defects — verify the column actually exists on the joined table.
- [2026-06-29 | Business Analyst] `Gate::policy(Quiz::class, …)` registered twice (QuizPolicy then
  LmsQuizReportPolicy) silently kills QuizPolicy — same overwrite trap as EXM/HMW. Saved only because
  controllers use permission-string gates.

## Version History
| Version | Date | Change | Agent |
|---------|------|--------|-------|
| 1.0 | 2026-06-29 | Seeded from live code, DDL v2, StudentAttempt DDL v4, 9 migrations, V2 + V1 screen specs. Three-way reconciled. Status corrected ~70%→~75–80%. 6 owned + 3 shared runtime tables documented; 6 open issues (incl. 3 new bugs) + policy-overwrite logged. Complete FRD pack created. | Business Analyst |
