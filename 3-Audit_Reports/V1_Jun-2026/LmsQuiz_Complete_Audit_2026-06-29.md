# LmsQuiz Module — Complete Technical Audit (Mode X)
**Module Code:** QUZ  
**Module Name:** LmsQuiz  
**Audit Date:** 2026-06-29  
**Auditor Role:** pa-technical-auditor (AI_Brain v3)  
**Audit Mode:** Mode X — A + B + C + G + scoped D in one pass  
**Report Path:** `3-Audit_Reports/V1_Jun-2026/LmsQuiz_Complete_Audit_2026-06-29.md`

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Health Score | **40 / 100** (P0 cap applied) |
| GO / NO-GO | **NO-GO** |
| P0 findings | **1** |
| P1 findings | **8** |
| P2 findings | **7** |
| P3 findings | **7** |
| Total findings | **23** |
| Prior completion estimate | ~72% (progress.md) |
| Revised completion estimate | **~58%** |

The module has substantial functional coverage but three systemic failures block production readiness: API routes run without any tenant context (P0), the remedial quiz generation algorithm has two separate logic bugs (BUG-QUZ-002, BUG-QUZ-003) that make remedial quizzes target the wrong student and draw from the wrong question pool, and recommendation publishing always silently fails due to a non-existent column reference (BUG-QUZ-001). Four of six controllers also have their standalone index routes permanently returning 404. No permission seeder exists — non-super-admin users cannot access any feature.

---

## Module Inventory (verified)

| Asset | Count | Files |
|-------|-------|-------|
| Controllers | 6 | LmsQuizController (1272 ln), LmsQuizReportController (1444 ln), QuizAllocationController (708 ln), QuizQuestionController (1463 ln), AssessmentTypeController (297 ln), DifficultyDistributionConfigController (439 ln) |
| Models (owned) | 6 | Quiz, QuizAllocation, QuizQuestion, AssessmentType, DifficultyDistributionConfig, DifficultyDistributionDetail |
| Models (shared, cross-module) | 3 | QuizQuestAttempt, QuizQuestResult, QuizQuestAttemptAnswer (DDL-owned by StudentAttempt) |
| Services | 7 | RemedialQuizGenerationService, QuizUsageCheckService, QuizQueryService, + 4 others |
| FormRequests | 5 | QuizRequest, AssessmentTypeRequest, QuizQuestionRequest, QuizAllocationRequest, DifficultyDistributionConfigRequest |
| Policies | 3 | QuizPolicy (DEAD — overwritten), QuizAllocationPolicy, LmsQuizReportPolicy |
| Tenant migrations (owned) | 6 | lms_assessment_types, lms_difficulty_distribution_configs, lms_difficulty_distribution_details, lms_quizzes, lms_quiz_allocations, lms_quiz_questions |
| Tenant migrations (shared runtime) | 3 | lms_quiz_quest_attempts, lms_quiz_quest_attempt_answers, lms_quiz_quest_results |
| Route file | 1 | routes/web.php (87 ln) + routes/api.php (8 ln) |
| DDL spec | 1 | 2-DDL_Tenant_Consolidated/LmsQuiz_DDL_v2.sql |

---

## Layer G — Cross-Cutting Concerns (Security, Tenancy, Authorization)

### SEC-QUZ-003 [P0] — API Routes Lack All Tenancy Middleware

**Evidence — RouteServiceProvider.php lines 60-62:**
```php
protected function mapApiRoutes(): void
{
    Route::middleware('api')->prefix('api')->name('api.')->group(module_path($this->name, '/routes/api.php'));
}
```
**Evidence — routes/api.php:**
```php
Route::middleware(['auth:sanctum'])->prefix('v1')->group(function () {
    Route::apiResource('lmsquizzes', LmsQuizController::class)->names('lmsquiz');
});
```
The web route stack includes `InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive`. The API route stack includes NONE of these. `GET /api/v1/lmsquizzes` runs without tenant context — `Quiz::all()` either crashes or queries the default (central) DB, returning zero records or cross-tenant data depending on the DB connection config. This is a tenancy isolation failure.
**Severity:** P0 — tenancy bypass, data isolation broken  
**REQ gap:** REQ-QUZ-017, BR-QUZ-038  
**Fix:** Add the full tenancy middleware stack to `mapApiRoutes()` or move tenant API routes to the platform's `routes/tenant.php`.

---

### SEC-QUZ-002 [P1] — QuizPolicy Dead Due to Double Gate::policy Registration

**Evidence — LmsQuizServiceProvider.php:**
```php
Gate::policy(Quiz::class, QuizPolicy::class);            // line 65 — registered first
Gate::policy(QuizAllocation::class, QuizAllocationPolicy::class); // line 66
Gate::policy(QuizQuestion::class, QuizQuestionPolicy::class);     // line 67
Gate::policy(Quiz::class, LmsQuizReportPolicy::class);   // line 68 — overwrites line 65
```
Laravel's `Gate::policy()` stores one policy per model class. The second registration for `Quiz::class` silently discards the first. `QuizPolicy` is completely unreachable. Policy-based authorization calls for `Quiz` (e.g., `$this->authorize('update', $quiz)`) will route to `LmsQuizReportPolicy`, which was written to handle report permissions, not CRUD. Current controllers use string-based `Gate::authorize('tenant.quiz.*')` which is unaffected — but future code, tests, and any controller method that uses Eloquent model-instance authorization will silently use the wrong policy.  
**Severity:** P1 — architectural defect, wrong policy active for Quiz model  
**Platform pattern:** Same as SEC-EXM pattern confirmed in LmsExam.

---

### SEC-QUZ-004 [P1] — LmsQuizReportController::getDependencies() Unprotected

**Evidence — LmsQuizReportController.php:**
- Line 39: `Gate::authorize('tenant.lms-quiz-report.viewAny')` — only in `index()`
- `getDependencies()` at line 164: NO Gate call of any kind

The `getDependencies()` method is an AJAX endpoint returning subjects, sections, students, lessons, and topics depending on request parameters. It is reachable by any authenticated user (web + auth middleware) without the report permission. With D39 compounding this (no permissions seeded), the authorization chain is: auth middleware passes, no Gate check executes, student and class data returned.  
**Severity:** P1 — authorization bypass on data-leaking AJAX endpoint  
**REQ gap:** REQ-QUZ-013, BR-QUZ-036

---

### SEC-QUZ-001 [P2, D30] — All Five FormRequests Return `authorize(): true`

**Evidence:**
```
QuizRequest.php:13:                     return true;
AssessmentTypeRequest.php:13:           return true;
QuizQuestionRequest.php:15:             return true;
QuizAllocationRequest.php:20:           return true;
DifficultyDistributionConfigRequest.php:13: return true;
```
Platform baseline is 90% (437/485 per known-issues.md). Controllers use `Gate::authorize()` providing a compensating control — no immediate bypass. Still a P2 per D30 because it removes defense-in-depth.  
**Severity:** P2 — platform baseline pattern D30, compensating control present

---

### SEC-QUZ-005 [P2] — Stored XSS in Student Result View

**Evidence — summary/student_result.blade.php:**
- Line 143: `{!! trim($q['text']) ?: 'Content missing.' !!}` — question text
- Line 168: `{!! trim($opt['text']) ?: '—' !!}` — option text
- Line 170: `{!! $optBadge !!}` — option badge HTML
- Line 181: `{!! $q['explanation'] !!}` — explanation text

Question text, option text, and explanation come from `qns_questions_bank`, which is teacher-editable content. A teacher inserting `<script>alert(1)</script>` into a question or explanation would execute in every student's browser when they view their attempt result. No `e()` or Blade `{{ }}` escaping applied.  
**Severity:** P2 — stored XSS, teacher-to-student attack surface  
**REQ gap:** REQ-QUZ-014

### BUG-QUZ-005 [P1] — EnsureTenantHasModule Absent from Web Route Middleware

**Evidence — RouteServiceProvider.php::mapWebRoutes() lines 41-51:**
Middleware stack: `web`, `InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive`, `auth`, `verified`. `EnsureTenantHasModule` is absent. Schools without an LmsQuiz licence can reach all quiz screens.  
**Severity:** P1 — module licence bypass  
**REQ gap:** REQ-QUZ-017, BR-QUZ-037

---

## Layer A — Module Structure & Scaffolding

### BUG-QUZ-004 [P2] — Route Prefix Typo `lms-quize` (Extra 'e') Throughout

**Evidence — RouteServiceProvider.php lines 49-50:**
```php
'prefix' => 'lms-quize',
'as'     => 'lms-quize.',
```
**Evidence — routes/web.php line 19:** `Route::resource('quize', LmsQuizController::class)` and all 87 route lines use `quize`. All named routes in the module are misspelled (`lms-quize.quize.index`, `lms-quize.quize.store`, etc.). Controllers redirect to `route('lms-quize.quize.index')`. Any documentation, external link, or hard-coded URL using `lms-quiz` would fail.  
**Severity:** P2 — cosmetic but pervasive; the typo is self-consistent within the module so it functions, but is wrong.

### BUG-QUZ-007 [P1] — QuizAllocationController::index() Always 404

**Evidence — QuizAllocationController.php:**
```php
public function index(Request $request)
{
    abort(404);  // line 31 — unconditional
    Gate::authorize('tenant.quiz-allocation.viewAny');  // line 32 — unreachable
    ...
}
```
The standalone quiz allocation list route (`GET /lms-quize/quiz-allocation`) permanently returns 404. Gate check is dead code. Allocations are only accessible via the tab-based dashboard in `LmsQuizController::index()`.  
**Severity:** P1 — functional regression on named route

### BUG-QUZ-008 [P2] — AssessmentTypeController::index() Always 404

**Evidence — AssessmentTypeController.php lines 25-26:**
```php
abort(404);
Gate::authorize('tenant.assessment-type.viewAny');
```
Standalone assessment-type list route permanently 404.  
**Severity:** P2

### BUG-QUZ-009 [P2] — DifficultyDistributionConfigController::index() Always 404

**Evidence — DifficultyDistributionConfigController.php lines 33-34:**
```php
abort(404);
Gate::authorize('tenant.difficulty-config.viewAny');
```
Standalone difficulty config list route permanently 404.  
**Severity:** P2

### BUG-QUZ-010 [P2] — QuizQuestionController::index() Always 404

**Evidence — QuizQuestionController.php lines 42-43:**
```php
abort(404);
Gate::authorize('tenant.quiz-question.viewAny');
```
Standalone quiz-question list route permanently 404.  
**Summary pattern:** 4 of 6 controllers have `abort(404)` as the first statement in `index()`. The module uses a tab-based UI through `LmsQuizController::index()`, so individual list routes are intentionally dead — but they remain registered, Gate checks are dead code, and any bookmark or direct link returns 404.  
**Severity:** P2 — functional regression (routes registered but dead)

---

## Layer D — Database: DDL ↔ Migration ↔ Model Three-Way Reconcile

### DAT-QUZ-001 [P2, D29] — Four ENUM Columns Across Three Tables

| Table | Column | ENUM values |
|-------|--------|-------------|
| `lms_quiz_allocations` | `allocation_type` | CLASS, SECTION, GROUP, STUDENT |
| `lms_quiz_quest_attempts` | `assessment_type` | QUEST, QUIZ |
| `lms_quiz_quest_attempts` | `status` | ABANDONED, CANCELLED, IN_PROGRESS, NOT_STARTED, REASSIGNED, SUBMITTED, TIMEOUT |
| `lms_quiz_quest_results` | `assessment_type` | QUEST, QUIZ |

All four use `->enum()` in migrations (confirmed). The DDL spec for `lms_quiz_allocations` also specifies ENUM, meaning both DDL and migration are non-compliant with D29. The three remaining columns in the shared runtime tables inherit this pattern from the StudentAttempt design.  
**Fix per D29:** Replace with `TINYINT UNSIGNED` FK to `sys_dropdown_table`; handle the `status` domain as a lookup table entry.

### DAT-QUZ-002 [P3] — `is_system_generated` Duplicate in Quiz::$fillable

**Evidence — Quiz.php lines 33 and 62:** `'is_system_generated'` appears twice in `$fillable`. No runtime error in current Laravel, but indicates copy-paste during model construction.

### DAT-QUZ-003 [P3] — `lesson_id` Has No FK Constraint in DDL Spec or Migration

DDL spec (`lms_quizzes` constraints block lines 125-131) lists FK for `academic_session_id`, `class_id`, `subject_id`, `scope_topic_id`, `quiz_type_id`, `difficulty_config_id`, `created_by` — but NOT `lesson_id`. Migration `2026_06_15_150343_create_lms_quizzes_table.php` line 20 defines `lesson_id` as `unsignedInteger()` with no `foreign()` call. DDL and migration are consistent in omitting the FK, but the omission means deleted lessons leave orphan quiz records. The `QuizRequest` does validate `lesson_id` with `exists:slb_lessons,id` — application-level guard only.  
**Note:** This may be cross-DB (slb_ schema), explaining the omission.

### DAT-QUZ-004 [P3, D39] — No Permission Seeder Exists

`LmsQuizDatabaseSeeder::run()` calls only: `LmsAssessmentTypeSeeder`, `LmsDifficultyDistributionConfigSeeder`, `LmsQuizSeeder`, `LmsQuizQuestionSeeder`, `LmsQuizAllocationSeeder` — all demo data seeders. No permission seeder exists anywhere in `database/seeders/` or in the module. Permissions referenced in `Gate::authorize()` calls (`tenant.quiz.viewAny`, `tenant.quiz.create`, `tenant.quiz.update`, `tenant.quiz.delete`, `tenant.quiz.restore`, `tenant.quiz.forceDelete`, `tenant.quiz-allocation.*`, `tenant.quiz-question.*`, `tenant.assessment-type.*`, `tenant.difficulty-config.*`, `tenant.lms-quiz-report.*`) are never seeded into Spatie. The `Gate::before()` super-admin bypass masks this in development. Non-super-admin users cannot access any LmsQuiz feature in production.

### Three-Way Reconcile — `lms_quizzes` (PASS with notes)

| Column | DDL Spec | Migration | Model |
|--------|----------|-----------|-------|
| `quiz_type_id` | INT UNSIGNED NOT NULL → FK `lms_assessment_types` | `unsignedInteger`, FK correct | `assessmentType()` uses `quiz_type_id` explicitly — MATCH |
| `lesson_id` | INT UNSIGNED NOT NULL, NO FK | `unsignedInteger`, NO FK | `lesson()` → `Lesson::class, 'lesson_id'` — consistent |
| `status` | VARCHAR(20) DEFAULT 'DRAFT' | `string(20)->default('DRAFT')` | not in $casts (correct, treated as string) — MATCH |
| `is_system_generated` | TINYINT(1) | `boolean` | in `$fillable` TWICE, in `$casts` as boolean — functional, duplicate |

Three-way reconcile for `lms_quizzes`: PASS. No structural divergence between DDL spec, migration, and model.

### Three-Way Reconcile — `lms_quiz_allocations` (PASS with D29 note)

Migration matches DDL spec. Polymorphic `target_id` design (no FK on target) is intentional and documented in DDL comment. D29 violation (ENUM) present in both DDL and migration.

### Three-Way Reconcile — `lms_quiz_quest_attempts` (PASS, shared table)

Migration defines `quiz_allocation_id` FK (line 43-44) — this is the correct column name. Confirms BUG-QUZ-001 (controller queries non-existent `allocation_id`). Unique constraints on `[student_id, quiz_id, attempt_number]` and `[student_id, quest_id, attempt_number]` correctly enforce attempt-count limit per REQ-QUZ-009.

### Three-Way Reconcile — lms_assessment_types, lms_difficulty_distribution_configs, lms_difficulty_distribution_details, lms_quiz_questions (PASS)

All four tables: DDL spec aligns with migrations; no divergence found. Foreign key names match between DDL and migration in all four tables.

---

## Layer B — FRD ↔ Code Conformance

### REQ Coverage Matrix

| REQ ID | Title | Status | Finding |
|--------|-------|--------|---------|
| REQ-QUZ-001 | Quiz CRUD | Partial | store/update lack DB::transaction (BUG-QUZ-006) |
| REQ-QUZ-002 | Assessment Types Management | Partial | index always 404 (BUG-QUZ-008) |
| REQ-QUZ-003 | Difficulty Profiles | Partial | index always 404 (BUG-QUZ-009) |
| REQ-QUZ-004 | Quiz Settings | Implemented | — |
| REQ-QUZ-005 | Question Selection | Implemented | — |
| REQ-QUZ-006 | Automatic Difficulty Builder | Broken | BUG-QUZ-003 (query overwrite breaks unused-question filter) |
| REQ-QUZ-007 | Quiz Allocation to Audiences | Partial | index always 404 (BUG-QUZ-007); store/show/edit/update functional |
| REQ-QUZ-008 | Automatic Remedial Quiz Generation | Broken | BUG-QUZ-002 (wrong target_id) + BUG-QUZ-003 (query overwrite) |
| REQ-QUZ-009 | Student Quiz Attempt (consumed) | N/A | Student Portal boundary; attempt tables present and correctly structured |
| REQ-QUZ-010 | Auto-Grading & Scoring | N/A | Student Portal boundary |
| REQ-QUZ-011 | Teacher Manual Grading | Partial | LmsQuizReportController handles this; only 1 Gate call in 1444 lines |
| REQ-QUZ-012 | Result Computation & Publishing | Partial | BUG-QUZ-001 (wrong column in recommendation publish) |
| REQ-QUZ-013 | Quiz Dashboard & Analytics | Implemented | ARCH-QUZ-003 (8+ COUNT queries per load) |
| REQ-QUZ-014 | Quiz Summary & Drill-down | Implemented | XSS in student result view (SEC-QUZ-005) |
| REQ-QUZ-015 | Recommendation Publishing Integration | Broken | BUG-QUZ-001 (lookup uses non-existent column) |
| REQ-QUZ-016 | Soft-Delete Lifecycle | Implemented | forceDelete IS transactional; store/update not |
| REQ-QUZ-017 | Authorization, Module Licensing & Tenant Isolation | Partial | SEC-QUZ-003 (API no tenancy), BUG-QUZ-005 (no EnsureTenantHasModule), DAT-QUZ-004 (no permissions seeded) |
| REQ-QUZ-018 | Activity & Proctoring Log | Implemented | — |

### BR Enforcement Status

| BR ID | Rule | Status | Finding |
|-------|------|--------|---------|
| BR-QUZ-001 | Quiz status lifecycle (DRAFT→PUBLISHED→ARCHIVED) | Enforced | `QuizRequest` validates `in:DRAFT,PUBLISHED,ARCHIVED` |
| BR-QUZ-002 | SoftDeletes on all entities | Enforced | All 6 owned tables have `softDeletes()` in migration |
| BR-QUZ-004 | Difficulty builder respects profile min/max percentages | Implemented | — |
| BR-QUZ-005 | Difficulty builder uses quiz's subject/class/topic scope | Implemented | — |
| BR-QUZ-009 | Only PUBLISHED quiz can be allocated | Enforced | QuizAllocationRequest validates quiz status |
| BR-QUZ-011 | Same question cannot be added twice | Enforced | `uq_quiz_ques` unique constraint on `[quiz_id, question_id]` |
| BR-QUZ-015 | only_unused_questions filter excludes already-used questions | VIOLATED | BUG-QUZ-003: query overwrite returns usage-log rows, not filtered questions |
| BR-QUZ-016 | Due date >= published_at; cut-off >= due_date | Partial | Validation in QuizAllocationRequest — confirm coverage |
| BR-QUZ-020 | Remedial allocation targets the failing student | VIOLATED | BUG-QUZ-002: `user_id` stored as `target_id` instead of `std_students.id` |
| BR-QUZ-023 | Remedial generation is atomic (full or nothing) | Enforced | `RemedialQuizGenerationService::generate()` wraps in `DB::transaction()` |
| BR-QUZ-025 | Negative marking floors total score at zero | N/A | Student Portal boundary |
| BR-QUZ-029 | Manual grading triggers recomputation | N/A | Student Portal boundary |
| BR-QUZ-034 | Recommendation publish targets only the allocation's attempting students | VIOLATED | BUG-QUZ-001: `->where('a.allocation_id', $id)` — column does not exist |
| BR-QUZ-036 | Every action permission-gated per school | PARTIAL | DAT-QUZ-004 (permissions not seeded), SEC-QUZ-004 (getDependencies ungated) |
| BR-QUZ-037 | EnsureTenantHasModule blocks unlicensed schools | VIOLATED | BUG-QUZ-005: middleware absent from web stack |
| BR-QUZ-038 | No data exposed across school boundaries | PARTIAL | SEC-QUZ-003: API routes without tenancy initialization |

### RPT Coverage

| RPT ID | Status |
|--------|--------|
| RPT-QUZ-001 | Implemented (LmsQuizReportController, 6 perspectives) |
| RPT-QUZ-002 | Implemented (quiz-level attempt drill-down) |
| RPT-QUZ-003 | Implemented (dashboard KPIs and charts) |
| RPT-QUZ-004 | Implemented (per-student score view) |
| RPT-QUZ-005 | Not confirmed — check StudentPortal boundary |

---

## Layer C — Business Logic Defects

### BUG-QUZ-001 [P1] — Recommendation Publish Uses Non-Existent Column

**Location:** `QuizAllocationController::publishHiddenRecommendations()` (lines 534-552)  
**Evidence:**
```php
$studentIds = DB::table('lms_quiz_quest_results as r')
    ->join('lms_quiz_quest_attempts as a', 'a.id', '=', 'r.attempt_id')
    ->where('a.allocation_id', $allocationId)   // column does not exist
    ->where('r.assessment_type', $type)
    ->pluck('r.student_id');
```
The column `allocation_id` does not exist on `lms_quiz_quest_attempts`. The actual column (confirmed in migration line 43) is `quiz_allocation_id`. The query always returns an empty collection. The Recommendation module records are never published, and the allocation's `is_auto_publish_result` is never set.  
**Root cause:** Column renamed during schema evolution; raw DB query not updated.  
**Fix:** Change `'a.allocation_id'` to `'a.quiz_allocation_id'`.  
**REQ gap:** REQ-QUZ-015; BR-QUZ-034 VIOLATED

---

### BUG-QUZ-002 [P1] — Remedial Allocation Stores Wrong Target ID

**Location:** `RemedialQuizGenerationService::createAllocation()` line 289  
**Evidence:**
```php
'target_id' => $student->user_id,
```
**Read path — QuizAllocation.php::getTargetNameAttribute() for STUDENT:**
```php
case 'STUDENT':
    return Student::find($this->target_id)?->full_name ?? 'Unknown';
```
`Student::find()` looks up `std_students.id`. `$student->user_id` is `sys_users.id`. The two IDs do not correspond. Remedial allocation stores the user's `sys_users.id` but the display path looks up `std_students.id`. The allocation appears to target a different student (or none) depending on ID overlap.  
**Root cause:** Identity mismatch between `sys_users.id` and `std_students.id`.  
**Fix:** Change to `'target_id' => $student->id` (uses `std_students.id`).  
**REQ gap:** REQ-QUZ-008; BR-QUZ-020 VIOLATED

---

### BUG-QUZ-003 [P1] — `only_unused_questions` Filter Overwrites QuestionBank Query

**Location:** `RemedialQuizGenerationService::fetchQuestionsByConfig()` lines 164-168  
**Evidence:**
```php
if ($triggeringQuiz->only_unused_questions) {
    $query->select('question_bank_id')
          ->from('qns_question_usage_log')
          ->where('question_usage_type', 'QUIZ');
}
```
`$query` at this point is a QuestionBank Eloquent query (targeting `qns_questions_bank`). The `->select()` and `->from()` calls REPLACE the QuestionBank table and its select list with `qns_question_usage_log`. The resulting SQL queries the usage log, not the question bank. The remedial quiz builder receives usage-log rows instead of filtered question records.  
**Root cause:** Wrong operation — should add a `->whereNotIn('id', ...)` subquery, not overwrite the base query.  
**Fix:** Replace with:
```php
$usedIds = DB::table('qns_question_usage_log')
    ->where('question_usage_type', 'QUIZ')
    ->pluck('question_bank_id');
$query->whereNotIn('id', $usedIds);
```
**REQ gap:** REQ-QUZ-006, REQ-QUZ-008; BR-QUZ-015 VIOLATED

---

### BUG-QUZ-006 [P1] — Quiz store() and update() Not Wrapped in DB::transaction

**Location:** `LmsQuizController::store()` (lines 458-490) and `update()` (lines 919-975)  
`store()`: `Quiz::create($quizData)` followed by `activityLog(...)`. No transaction. If `activityLog` fails, the quiz is created but no audit trail exists.  
`update()`: `$quiz->update($quizData)` followed by `activityLog(...)`. Same pattern.  
`forceDelete()` (lines 1042-1075): IS wrapped in `DB::transaction()` — inconsistent.  
Note: `QuizAllocationController::store()` and `RemedialQuizGenerationService::generate()` ARE transactional (confirmed).  
**Severity:** P1 — inconsistency; low operational risk unless activityLog failure causes confusion.  
**REQ gap:** REQ-QUZ-001

---

## Layer Findings — Architectural Concerns (P3)

### ARCH-QUZ-001 [P3] — Hard Dependency on StudentPortal Module

`Quiz.php` imports `Modules\StudentPortal\Models\QuizQuestAttempt` (line 19) and `Modules\StudentPortal\Models\QuizQuestResult` (line 20). These are shared runtime tables. If StudentPortal module is disabled or refactored, `Quiz::attempts()` and `Quiz::results()` relationships fail at runtime. The `lms_quiz_quest_attempts` and `lms_quiz_quest_results` tables are listed as "DDL-owned by StudentAttempt" in module knowledge, yet the Quiz model imports them from StudentPortal, not from its own namespace.

### ARCH-QUZ-002 [P3] — Route Duplication on difficulty-distribution-config show

`routes/web.php` line 36 comment: "Resource except show". Line 37: `Route::resource(...)` — no `except: ['show']` option passed. The resource registers a `show` route. Line 46 explicitly registers the same `show` path again. Two routes share the same URI — last registration wins. Misleading comment creates maintenance confusion.

### ARCH-QUZ-003 [P3] — Dashboard Makes 8+ Separate COUNT Queries Per Page Load

`LmsQuizController::index()` lines 229-383 construct `$quizDashboardStats` with 8+ separate `::count()` calls, 2 anonymous function blocks executing `::get()->each()`, and 2 additional dashboard queries (`$recentQuizzes`, `$activityLogs`). All execute synchronously on every request with no cache layer. No unbounded `->get()` without `->limit()` (mitigated), but the COUNT fan-out is a performance concern under concurrent load.

### PERF-QUZ-001 [P3] — LmsQuizReportController Loads All Active Students

`LmsQuizReportController::index()` line 109: `Student::where('is_active', 1)->get()`. No pagination, no limit. This loads all active students in the tenant on every report page load. In a school with 3,000+ students this is a 3,000-row unbounded SELECT transmitted to the browser as a dropdown.

---

## Platform Pattern Compliance

| Pattern | Status | Detail |
|---------|--------|--------|
| D17 — $fillable vs migration mismatch | PASS (minor) | `is_system_generated` duplicate in $fillable; no column missing from migration |
| D24 — Permission prefix consistency | PASS | String gates consistently use `tenant.quiz.*`, `tenant.quiz-allocation.*`, `tenant.assessment-type.*`, `tenant.difficulty-config.*`, `tenant.lms-quiz-report.*` |
| D25 — $request->all() into models | PASS | All controllers use `$request->validated()` — D25 clean |
| D29 — ENUM prohibition | FAIL | 4 ENUM columns across 3 tables (DAT-QUZ-001) |
| D30 — FormRequest authorize() | FAIL | All 5 FormRequests return true (SEC-QUZ-001) |
| D36 — GENERATED columns degraded | N/A | No GENERATED ALWAYS columns in LmsQuiz DDL |
| D37 — status as INT FK vs string | PARTIAL | `status` uses VARCHAR string (consistent with DDL spec for this module); `allocation_type` uses ENUM |
| D38 — SoftDeletes vs DDL | PASS | All owned tables have `deleted_at` in both DDL and migration; SoftDeletes trait present in all 6 owned models |
| D39 — Permissions never seeded | FAIL | No permission seeder exists (DAT-QUZ-004) |

---

## Positive Findings (What Is Working Correctly)

1. **Gate coverage on LmsQuizController** — `index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `restore()`, `forceDelete()`, `toggleStatus()`, `trashed()` all have `Gate::authorize()` at method entry. BUG-LMS-005 confirmed FIXED.
2. **QuizAllocationController::store()** — wraps in `DB::beginTransaction()` / `DB::commit()` / `DB::rollBack()`.
3. **RemedialQuizGenerationService::generate()** — wraps entire remedial quiz creation in `DB::transaction()` (BR-QUZ-023 enforced).
4. **D25 clean** — All 6 controllers use `$request->validated()`, no `$request->all()` passed to model `create()/update()`.
5. **Quiz model boot()** — correctly uses `Str::uuid()->getBytes()` for BINARY(16) UUID generation.
6. **QuizQuestion unique constraint** — `uq_quiz_ques` on `[quiz_id, question_id]` enforces BR-QUZ-011 at DB level.
7. **Soft-delete consistency** — `deleted_at` in all 9 tables (owned + shared runtime), `SoftDeletes` in all 6 owned models.
8. **Cross-DB FK pattern** — `lms_quizzes.academic_session_id` correctly references `$globalDb . '.glb_academic_sessions'` (cross-DB pattern handled properly).
9. **QuizAllocationController::publishHiddenRecommendations() uses DB::transaction** — the function body IS transactional; the query bug (BUG-QUZ-001) returns empty set silently, which is the only failure mode.
10. **QuizUsageCheckService** — guards `edit()` and `destroy()` on quiz, preventing mutation of in-use quizzes (BR-QUZ-002 compatible).

---

## Findings Index

| Code | Severity | Layer | Title |
|------|----------|-------|-------|
| SEC-QUZ-003 | P0 | G | API routes lack all tenancy middleware |
| SEC-QUZ-002 | P1 | G | QuizPolicy dead — policy overwrite in ServiceProvider |
| SEC-QUZ-004 | P1 | G | LmsQuizReportController::getDependencies() ungated |
| BUG-QUZ-001 | P1 | C | Recommendation publish uses non-existent column `allocation_id` |
| BUG-QUZ-002 | P1 | C | Remedial allocation stores `user_id` instead of `std_students.id` as target_id |
| BUG-QUZ-003 | P1 | C | `only_unused_questions` filter overwrites QuestionBank query FROM/SELECT |
| BUG-QUZ-005 | P1 | G | EnsureTenantHasModule absent from web route middleware stack |
| BUG-QUZ-006 | P1 | C | Quiz store() and update() not wrapped in DB::transaction |
| BUG-QUZ-007 | P1 | A | QuizAllocationController::index() abort(404) — always 404 |
| SEC-QUZ-001 | P2 | G | All 5 FormRequests return authorize():true (D30) |
| SEC-QUZ-005 | P2 | G | Stored XSS in student_result.blade.php via {!! !!} on question/option/explanation |
| BUG-QUZ-004 | P2 | A | Route prefix typo `lms-quize` (extra 'e') throughout RouteServiceProvider + routes |
| BUG-QUZ-008 | P2 | A | AssessmentTypeController::index() abort(404) — always 404 |
| BUG-QUZ-009 | P2 | A | DifficultyDistributionConfigController::index() abort(404) — always 404 |
| BUG-QUZ-010 | P2 | A | QuizQuestionController::index() abort(404) — always 404 |
| DAT-QUZ-001 | P2 | D | Four ENUM columns across three tables (D29 violation) |
| DAT-QUZ-002 | P3 | D | is_system_generated duplicate in Quiz::$fillable |
| DAT-QUZ-003 | P3 | D | lesson_id has no FK constraint in DDL spec or migration |
| DAT-QUZ-004 | P3 | D | No permission seeder — all LmsQuiz permissions unregistered in Spatie (D39) |
| ARCH-QUZ-001 | P3 | A | Hard dependency on Modules\StudentPortal in Quiz model |
| ARCH-QUZ-002 | P3 | A | Route duplication on difficulty-distribution-config show |
| ARCH-QUZ-003 | P3 | A | Dashboard fires 8+ COUNT queries per page load with no caching |
| PERF-QUZ-001 | P3 | A | LmsQuizReportController loads all active students unbounded |

---

## Health Score Derivation

| Dimension | Weight | Raw | Weighted |
|-----------|--------|-----|---------|
| Security / Tenancy | 30% | 45 | 13.5 |
| Functional Correctness | 30% | 50 | 15.0 |
| Architecture / Structure | 20% | 62 | 12.4 |
| Data Integrity / DB | 20% | 68 | 13.6 |
| **Weighted sum** | | | **54.5** |
| **P0 cap (1 P0 present)** | | | **40** |

**Health Score: 40 / 100 — P0 cap applied**  
**Verdict: NO-GO**

---

## Remediation Priority Queue

### Immediate (before any QA pass)
1. **SEC-QUZ-003** — Add tenancy middleware stack to `mapApiRoutes()` in RouteServiceProvider
2. **BUG-QUZ-001** — Fix `'a.allocation_id'` → `'a.quiz_allocation_id'` in `publishHiddenRecommendations()`
3. **BUG-QUZ-002** — Fix `$student->user_id` → `$student->id` in `createAllocation()`
4. **BUG-QUZ-003** — Replace query overwrite with `whereNotIn('id', $usedIds)` in `fetchQuestionsByConfig()`
5. **SEC-QUZ-004** — Add `Gate::authorize('tenant.lms-quiz-report.viewAny')` to `getDependencies()`
6. **BUG-QUZ-005** — Add `EnsureTenantHasModule` to `mapWebRoutes()` middleware stack
7. **DAT-QUZ-004** — Create and register permission seeder for all `tenant.quiz.*` and sibling permissions

### Short-term (before release)
8. **SEC-QUZ-005** — Replace `{!! !!}` with `{{ }}` (or `e()`) in `summary/student_result.blade.php` lines 143, 168, 181; use `{!! $optBadge !!}` only if `$optBadge` is system-generated HTML, not DB content
9. **SEC-QUZ-002** — Remove duplicate `Gate::policy(Quiz::class, ...)` at line 68 or extract report policy mapping to `LmsQuizReportPolicy` with a separate gate define
10. **BUG-QUZ-006** — Wrap `Quiz::create()` + `activityLog()` and `$quiz->update()` + `activityLog()` in `DB::transaction()`
11. **BUG-QUZ-007/008/009/010** — Decide whether standalone index routes should work or be removed; if removed, drop the `Route::resource()` for the 4 affected controllers and replace with only the needed individual routes
12. **BUG-QUZ-004** — Rename route prefix from `lms-quize` to `lms-quiz` in RouteServiceProvider and update all route names throughout web.php and all controller redirect calls

### Deferred (tech debt)
13. **DAT-QUZ-001** — Replace 4 ENUM columns with TINYINT FK per D29 (needs migration + enum-to-lookup data seeder)
14. **DAT-QUZ-003** — Add FK constraint for `lesson_id` in `lms_quizzes` if cross-schema FK is supported; otherwise document the omission
15. **ARCH-QUZ-001** — Move shared runtime model imports to LmsQuiz's own namespace or to a SharedAttempt module
16. **PERF-QUZ-001** — Paginate or AJAX-load students in LmsQuizReportController
17. **ARCH-QUZ-003** — Cache dashboard stats with `Cache::remember()` keyed by tenant + filter combination

---

*Audit completed 2026-06-29. Evidence-based — all findings backed by file path + line number. No speculative findings included.*
