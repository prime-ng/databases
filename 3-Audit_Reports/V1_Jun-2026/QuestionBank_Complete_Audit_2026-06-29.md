# QuestionBank Module — Complete Technical Audit (Mode X)

**Module Code:** QNS  
**Module Name:** QuestionBank  
**Audit Date:** 2026-06-29  
**Auditor Role:** pa-technical-auditor (AI_Brain v3)  
**Audit Mode:** Mode X — A + B + C + G + scoped D in one pass  
**Report Path:** `3-Audit_Reports/V1_Jun-2026/QuestionBank_Complete_Audit_2026-06-29.md`

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Health Score | **37 / 100** (raw; P0-capped — would be 40 maximum) |
| GO / NO-GO | **NO-GO** |
| New P0 findings | **4** |
| P0 confirmed still open (known-issues) | **2** (BUG-QNS-001 demo data; partial SEC-QNS-001 AJAX gaps) |
| P1 findings | **9** |
| P2 findings | **6** |
| P3 findings | **2** |
| Total new findings | **21** |
| Prior completion estimate | ~65-70% (BA-phase, 2026-06-29) |
| Revised completion estimate | **~50%** (effective usable completion after P0 block-outs) |

Four newly discovered P0s join two previously known ones. The most structurally serious is a **duplicate `Gate::policy(QuestionBank::class, ...)` registration** that silently renders `QuestionBankPolicy` dead — all 22+ `Gate::authorize('tenant.question-bank.*')` calls in the 2746-line controller check the wrong policy. Compounding this, no permission seeder exists, so non-super-admin users receive 403 everywhere. Two routes point to non-existent controller methods (HTTP 500). The `reviewApprove()` workflow bypasses the mandated FSM `APPROVED` state. API routes run without tenancy middleware. The already-known AI-generation stub (`generateQuestions()` permanent early return) and `scopeApproved()` wrong-column bug remain unresolved. `QuestionStatisticsService` is the strongest component — a full D31-compliant implementation — but is blocked at the DB write layer by a NOT NULL / nullable mismatch in the statistics migration.

---

## Module Inventory (verified, live filesystem)

| Asset | Count | Notes |
|-------|-------|-------|
| Controllers | 7 | QuestionBankController (2746 ln), AIQuestionGeneratorController (976 ln), QuestionMediaStoreController, QuestionStatisticController, QuestionTagController, QuestionUsageTypeController, QuestionVersionController |
| Models | 16 files | 1 confirmed duplicate: QuestionStatistics.php (plural) vs QuestionStatistic.php (singular) |
| Services | 2 | QuestionStatisticsService (HIGH quality — D31 full impl), QuestionUsageCheckService |
| FormRequests | 6 | All present; all return `Auth::check()` in authorize() |
| Policies | 10 | 2 confirmed dead: QuestionBankPolicy (overwritten in ServiceProvider), AIQuestionPolicy.php (never registered) |
| Views | 45 | |
| Seeders | 9 + 1 Support file | NO permission seeder |
| Imports | 2 | QuestionImport, QuestionReadOnly (maatwebsite/laravel-excel) |
| Jobs / Events / Tests | 0 / 0 / 0 | |
| DDL tables (tenant) | 13 | All migrations confirmed present |

---

## Layer G — Cross-Cutting Concerns (Security, Tenancy, Authorization)

### SEC-QNS-003 [P0, NEW] — Duplicate `Gate::policy(QuestionBank::class, ...)` — `QuestionBankPolicy` Dead

**Evidence — `Modules/QuestionBank/app/Providers/QuestionBankServiceProvider.php`:**
```php
Gate::policy(QuestionBank::class, QuestionBankPolicy::class);         // line 69 — registered first
// ... other registrations ...
Gate::policy(QuestionBank::class, AiQuestionGeneratorPolicy::class);  // line 75 — silently overwrites line 69
```
Laravel's `Gate::policy()` uses the model class name as the key. The second call silently replaces the first. `QuestionBankPolicy` is completely unreachable — all 22+ `Gate::authorize('tenant.question-bank.*')` calls in `QuestionBankController` now dispatch to `AiQuestionGeneratorPolicy`, a policy written for AI generation permissions, not general CRUD. This is a platform-defined pattern (PRM-D-001): previously confirmed in LmsQuiz (SEC-QUZ-002), LmsExam (SEC-EXM-009), and Prime (BUG-PRM-011).  
**Severity:** P0 — authorization is structurally broken for all QuestionBank CRUD operations  
**REQ gap:** BR-QNS-007, security baseline  
**Fix:** Remove the duplicate `Gate::policy(QuestionBank::class, ...)` registration on line 75. Consider registering `AiQuestionGeneratorPolicy` using a dedicated model class (`AiQuestionGeneration`) or via route-level `Gate::authorize()` calls only.

---

### SEC-QNS-004 [P0, NEW] — API Routes Lack Full Tenancy Middleware

**Evidence — `Modules/QuestionBank/app/Providers/RouteServiceProvider.php` (lines 60-62):**
```php
protected function mapApiRoutes(): void
{
    Route::middleware('api')->prefix('api')->name('api.')->group(module_path($this->name, '/routes/api.php'));
}
```
The web route stack applies `InitializeTenancyByDomain::class`, `PreventAccessFromCentralDomains::class`, `EnsureTenantIsActive::class`. The API route stack applies `'api'` only. Requests to API routes run without tenant context — queries hit the central DB or fail without a tenant connection. Identical to SEC-QUZ-003 (confirmed P0 in LmsQuiz).  
**Severity:** P0 — tenancy isolation broken on API routes  
**Fix:** Add full tenancy middleware to `mapApiRoutes()` (same stack as web routes, or use `middleware('api', InitializeTenancyByDomain::class, ...)` pattern consistent with the platform).

---

### SEC-QNS-005 [P0, CONFIRMED OPEN — BUG-QNS-001] — `generateQuestions()` Permanent Demo-Data Early Return

**Evidence — `AIQuestionGeneratorController.php` line 222:**
```php
return $this->getDemoResponse($request);  // lines 223-294 (real AI HTTP calls) are unreachable
```
The function permanently stubs out at line 222. Real OpenAI and Gemini calls (lines 223-294) are dead code. Noted in known-issues.md as BUG-QNS-001 — confirmed still open.  
**Severity:** P0 — REQ-QNS-014 (AI generation) completely undelivered in production  
**Fix:** Remove early return. Extract real AI calls into `AIQuestionService` using `config('services.openai.key')`.

---

### SEC-QNS-006 [P1, PARTIAL FIX from SEC-QNS-002] — `env()` Direct Access for API Keys Breaks After `config:cache`

**Evidence — `AIQuestionGeneratorController.php`:**
- Line 531: `$apiKey = env('CHATGPT_API_KEY');`
- Line 578: `$apiKey = env('GEMINI_API_KEY');`

Previously hardcoded (SEC-QNS-002 in known-issues — CRITICAL severity). Keys have been moved to `env()` which is the partial fix. **Remaining defect:** After `php artisan config:cache`, `env()` returns `null` — AI generation silently fails with null API key. Must use `config('services.openai.key')` and `config('services.gemini.key')` with corresponding entries in `config/services.php`.  
**Severity:** P1 — deployment configuration defect; AI silently fails in cached-config production  
**Status change:** CRITICAL → P1 (most severe exposure resolved; remaining is operational)

---

### SEC-QNS-007 [P1, CONFIRMED — BUG-QNS-01] — Wrong Policy Gate on `QuestionMediaStoreController`

**Evidence — `QuestionMediaStoreController.php` line 29:**
```php
Gate::authorize('tenant.competency.viewAny');
```
Should be `tenant.question-media.viewAny`. Copy-paste artifact from Syllabus module. QuestionMediaStore operations are authorized against the Syllabus competency policy — any user with competency view permission can see question media; any user without it cannot.  
**Severity:** P1 — wrong authorization scope on a resource controller

---

### SEC-QNS-008 [P1, CONFIRMED — SEC-QNS-04] — `EnsureTenantHasModule` Middleware Missing

**Evidence — `RouteServiceProvider::mapWebRoutes()` middleware array:**
```
web, InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive, auth, verified
```
`EnsureTenantHasModule:QuestionBank` (or equivalent module-license guard) is absent. Schools not licensed for QuestionBank can access all routes via the web stack.  
**Severity:** P1 — no module-license gate

---

### SEC-QNS-009 [P1, CONFIRMED — SEC-QNS-03] — `print()`, `validateFile()`, `startImport()` Have No `Gate::authorize()`

**Evidence — `QuestionBankController.php`:**
- `print()` at line 81: no Gate call
- `validateFile()` at line 92: no Gate call  
- `startImport()` at line 203: no Gate call

All three are wired to live routes (routes/web.php). `startImport()` creates database records; `validateFile()` loads Excel files into memory. Any authenticated user can trigger these.  
**Severity:** P1 — authorization bypass on three high-impact actions

---

### D39-QNS-001 [P1, NEW] — No Permission Seeder — Module Effectively Super-Admin-Only

No permission seeder exists in `database/seeders/` or `Modules/QuestionBank/database/seeders/` that defines `tenant.question-bank.*`, `tenant.question-media.*`, `tenant.question-statistic.*`, or any other QNS ability. The module has 10 policies and 40+ `Gate::authorize()` calls. Without seeded permissions:
- `Gate::before()` passes super-admins unconditionally
- All role-specific users (Admin, Teacher, DeptHead) silently receive 403 on every route

No QuestionBank feature is accessible to any non-super-admin user in a fresh tenant.  
**Severity:** P1 — D39 pattern; entire module is super-admin-only until fixed

---

### BUG-QNS-004 [P1, NEW] — 6 AJAX Cascade Endpoints in AIQuestionGeneratorController Have No `Gate::authorize()`

**Evidence — `AIQuestionGeneratorController.php` (confirmed auth status per method):**

| Method | Line | Gate::authorize? |
|--------|------|-----------------|
| `index()` | 59 | YES — `tenant.question-bank.create` |
| `getSections()` | 84 | NO |
| `getSubjectGroups()` | 105 | NO |
| `getSubjects()` | 126 | NO |
| `getLessons()` | 149 | NO |
| `getTopics()` | 175 | NO |
| `generateQuestions()` | 201 | YES — `tenant.question-bank.create` |
| `saveQuestions()` | 718 | YES — `tenant.question-bank.create` |
| `downloadCSV()` | 960 | NO |

The six unprotected methods return curriculum data (sections, subjects, lessons, topics from school setup) and can export all generated questions to CSV. Any authenticated user can hit these endpoints regardless of QuestionBank permissions. Note: SEC-QNS-001 in known-issues (claiming "ZERO auth on all methods") is factually incorrect — 3 of 9 methods are gated. The correction is 6/9 missing.  
**Severity:** P1 — authorization bypass on data-returning AJAX endpoints; school curriculum enumerable

---

## Layer A — Module Structure and Scaffolding

### BUG-QNS-002 [P0, NEW] — Two Routes Map to Non-Existent Controller Methods → HTTP 500

**Evidence — `routes/web.php`:**
```php
Route::get('/get-ai-providers', [AIQuestionGeneratorController::class, 'getAIProviders']);    // line 108
Route::get('/ai-provider-status/{id}', [AIQuestionGeneratorController::class, 'checkProviderStatus']); // line 109
```
`AIQuestionGeneratorController.php` (976 lines, fully read): no `getAIProviders()` method. No `checkProviderStatus()` method. Both routes return HTTP 500 (`BadMethodCallException: Call to undefined method`) when hit. These appear to be planned-but-unbuilt AI provider management features.  
**Severity:** P0 — live routes 500 in production  
**Fix:** Implement both methods or remove the routes until the feature is built.

---

### DEAD-QNS-001 [P2, NEW] — `getDemoResponse()` Is Active Dead Code in Production

**Evidence — `AIQuestionGeneratorController.php` lines 317-408:**
The `getDemoResponse()` method (~90 lines of hardcoded demo arrays) is both (a) called via the early return at line 222 making it the ONLY code path and (b) dead code in that it should not exist in production. The method and all hardcoded arrays should be removed; the real AI service path should replace it.  
**Severity:** P2 — technical debt / misleads production debugging

---

### BUG-QNS-005 [P2, NEW] — Duplicate Policy File: `AIQuestionPolicy.php` Never Registered

**Evidence — `Modules/QuestionBank/app/Policies/` directory:**
Contains both `AIQuestionPolicy.php` and `AiQuestionGeneratorPolicy.php`. The ServiceProvider registers only `AiQuestionGeneratorPolicy`. `AIQuestionPolicy.php` is dead, misleads developers, and will cause confusion about which policy governs AI generation.  
**Severity:** P2 — dead code / developer confusion

---

### TEST-QNS-001 [P3, CONFIRMED — SEC-QNS-05] — Zero Tests

`Modules/QuestionBank/tests/` contains 0 test files. 2 services (including a complex D31 formula engine), 7 controllers, 16 models, 2 Excel importers, and 13 DDL tables have no test coverage. FRD specifies T-QNS-01 through T-QNS-25 (25 Pest tests required).  
**Severity:** P3 — test coverage debt

---

## Layer B — FRD Gap Analysis (REQ coverage)

### REQ-QNS Coverage

| REQ | Requirement | Status | Evidence / Gap |
|-----|-------------|--------|----------------|
| REQ-QNS-001 | CRUD questions | DONE | QuestionBankController full resource, all routes wired |
| REQ-QNS-002 | Excel bulk import | DONE | QuestionImport (maatwebsite/laravel-excel), validateFile + startImport |
| REQ-QNS-003 | Taxonomy tagging | DONE | All FK columns in qns_questions_bank; topic/tag junction tables; bloomTaxonomy, complexityLevel, cognitiveSkill relationships |
| REQ-QNS-004 | Media attachment | PARTIAL | Junction table + QuestionMediaStoreController present; `questionMediaStores()` relationship uses wrong FK (ORM-QNS-002) |
| REQ-QNS-005 | Review workflow | PARTIAL | Workflow present; APPROVED state unreachable via `reviewApprove()` (BUG-QNS-003); no notification on approve/reject |
| REQ-QNS-006 | Version snapshots | DONE | `qns_question_versions` table; clean-slate update + JSON snapshot in DB transaction |
| REQ-QNS-007 | Usage tracking | PARTIAL | `qns_question_usage_log` table; QuestionUsageCheckService gates edits; log consistency unclear across LmsQuiz/LmsExam |
| REQ-QNS-008 | Performance categories | PARTIAL | Junction table + statistics service feed-forward; statistics write blocked by MIG-QNS-001 |
| REQ-QNS-009 | Statistics computation | DONE (service) / BLOCKED (write) | QuestionStatisticsService: full D31 implementation; blocked at DB write by NOT NULL mismatch (MIG-QNS-001) |
| REQ-QNS-010 | Availability scoping | PARTIAL | 6 scope levels in ENUM; conditional FK columns; enforcement inconsistent |
| REQ-QNS-011 | Question cloning | DONE | `storeClone()` method + route present |
| REQ-QNS-012 | Tag management | DONE | QuestionTagController full resource + trash/restore |
| REQ-QNS-013 | Question types (MCQ, etc.) | DONE | Reads from `slb_question_types`; MCQ option validation present |
| REQ-QNS-014 | AI question generation | NOT MET | Permanently returns demo data (BUG-QNS-001 P0); getAIProviders route 500 (BUG-QNS-002) |

**REQ summary:** 7/14 DONE, 5/14 PARTIAL, 2/14 NOT MET (REQ-QNS-005 FSM partial, REQ-QNS-014 absent)

### ORM-QNS-001 [P1, CONFIRMED — IMP-QNS-05] — `scopeApproved()` Wrong Column Name

**Evidence — `QuestionBank.php` line 210:**
```php
return $query->where('ques_reviewed_status', 'APPROVED');
```
Column in `qns_questions_bank` migration: `status` (confirmed in migration line 41: `ENUM('APPROVED', 'ARCHIVED', 'DRAFT', 'IN_REVIEW', 'PUBLISHED', 'REJECTED')`). Column `ques_reviewed_status` does not exist. The scope silently returns 0 rows. Any code using `QuestionBank::approved()->get()` or `->approved()` chained in a query returns empty results.  
**Severity:** P1 — BR-QNS-003 violated silently; assessment builders may receive empty question pools  
**Fix:** Change `'ques_reviewed_status'` to `'status'` in scopeApproved().

---

### ORM-QNS-002 [P2, NEW] — `questionMediaStores()` Relationship Uses Wrong Foreign Key

**Evidence — `QuestionBank.php` line 332:**
```php
return $this->hasMany(QuestionMediaStore::class, 'id')
    ->where('owner_type', 'QUESTION');
```
The second parameter to `hasMany()` is the foreign key ON the related model. Using `'id'` means: "find `qns_media_store` rows where `id` = this question's `id`" — a coincidental match by primary key collision, not a genuine relationship. The questions-to-media relationship is via `qns_question_media_jnt` (junction table) — this should use `hasManyThrough()` or `belongsToMany()` through the junction, not a direct `hasMany`.  
**Severity:** P2 — ORM relationship is broken; media loading via this relationship is incorrect  
**Fix:** Replace with `belongsToMany(QuestionMediaStore::class, 'qns_question_media_jnt', 'question_bank_id', 'media_id')` or use `hasManyThrough()` with the junction.

---

## Layer C — Business Rules Coverage

| BR | Rule | Status | Evidence |
|----|------|--------|---------|
| BR-QNS-001 | All taxonomy fields complete before IN_REVIEW | PARTIAL | No mandatory completeness check on submit-for-review |
| BR-QNS-002 | MCQ must have ≥1 `is_correct` option | ENFORCED | Controller validates option count and correct flag |
| BR-QNS-003 | Only APPROVED/PUBLISHED questions visible to assessment builders | MISSING | `scopeApproved()` wrong column → zero results (ORM-QNS-001) |
| BR-QNS-004 | `for_quiz`/`for_exam`/`for_quest` flags filter question availability | PARTIAL | Flags in DDL and fillable; enforcement depends on consumer modules |
| BR-QNS-005 | Unused questions excluded from assessment pickers | MISSING | No picker-side filtering; QuestionUsageCheckService only gates edits |
| BR-QNS-006 | Availability scope limits access by class/section/entity/student | PARTIAL | Scope levels defined; FK columns present; controller enforcement inconsistent |
| BR-QNS-007 | PrimeGurukul-owned questions are immutable by school admins | MISSING | No `ques_owner='PrimeGurukul'` guard in update/destroy; QuestionBankPolicy dead (SEC-QNS-003) |
| BR-QNS-008 | AI-generated questions (`created_by_AI=1`) must go through full IN_REVIEW cycle | VIOLATED | `reviewApprove()` bypasses APPROVED state → BUG-QNS-003 |
| BR-QNS-009 | Version snapshot created on any content modification | ENFORCED | `QuestionBankController::update()` clean-slate + version table in DB transaction |
| BR-QNS-010 | Negative marks ≥ 0 | PARTIAL | Column exists; no server-side non-negative validation |
| BR-QNS-011 | Rejection requires comment | ENFORCED | `reviewReject()` line 2718: `validate(['comment' => 'required'])` |
| BR-QNS-012 | Topic weightage soft warning at 100% | MISSING | No weightage check in storeTopics() |

**BR summary:** 3/12 fully enforced, 3/12 partial, 5/12 missing, 1/12 violated (BR-QNS-008)

### BUG-QNS-003 [P0, NEW] — `reviewApprove()` Bypasses FSM — Writes `PUBLISHED` Directly

**Evidence — `QuestionBankController.php` line 2689-2692:**
```php
$question->update([
    'status' => 'PUBLISHED',       // ← skips 'APPROVED' intermediate state
    'ques_reviewed_at' => now(),
]);
```
FSM (from module-knowledge and FRD): `IN_REVIEW → APPROVED → PUBLISHED`. The APPROVED state enables a separate publish step. By going directly to PUBLISHED, the system never enters APPROVED, meaning:
1. BR-QNS-008 (AI questions must pass full IN_REVIEW cycle) is violated — there is no APPROVED gate
2. No "approved-not-yet-published" state is reachable via the UI
3. Notifications or publish-step hooks that should fire on APPROVED cannot be inserted without rework

Additionally: `reviewApprove()` sets no notification dispatch (FRD Section 2 specifies author notification on approve/reject). `reviewReject()` also sends no notification.  
**Severity:** P0 — FSM violation; BR-QNS-008 violated; REQ-QNS-005 acceptance criteria not met  
**Fix:** Change status to `'APPROVED'`. Add a separate `/question-bank/{id}/publish` action for the APPROVED → PUBLISHED transition. Dispatch notification to question author in both approve and reject.

---

## Layer D (Scoped) — Database Schema Audit

### DDL Table Inventory

All 13 `qns_*` migrations confirmed present in `database/migrations/tenant/`. No D36 issues found (no `storedAs`/`virtualAs` calls in any QNS migration). D38 (SoftDeletes/timestamps column presence) verified correct for all 13 tables.

### MIG-QNS-001 [P1, NEW] — `qns_question_statistics` NOT NULL Columns Block Service Write Layer

**Evidence — `database/migrations/tenant/2026_06_16_114247_create_qns_question_statistics_table.php`:**
```php
$table->decimal('discrimination_index', 5, 2);        // line 17: NOT NULL, no default
$table->decimal('guessing_factor', 5, 2);             // line 18: NOT NULL, no default
$table->unsignedInteger('avg_time_taken_seconds');     // line 21: NOT NULL, no default
```
`QuestionStatisticsService::computeAndPersist()` correctly sets these to `null` in the following cases (per D31 spec):
- `$discriminationIndex = null` when `$splitCount < 4` (fewer than 4 attempts per 27% group)
- `$guessingFactor = null` for non-MCQ question types
- `$avgTime = null` when `$validTimeFeed->isEmpty()` (no valid telemetry)

`updateOrCreate()` passes these null values to the DB → MySQL SQLSTATE 1048 "Column cannot be null" → statistics write FAILS with a runtime exception. The service computation is correct; the migration is the bug. This blocks statistics computation for:
- Any newly-added question (total_attempts < 4, both groups empty → discrimination = NULL)
- Any non-MCQ question (guessing = NULL)
- Any question with no time telemetry (avg = NULL)  

**Severity:** P1 — statistics D31 computation is correct but DB write fails at runtime for the majority of new questions  
**Fix:** Add `->nullable()` to `discrimination_index`, `guessing_factor`, and `avg_time_taken_seconds` in the migration (and create an alter-migration if already deployed).

---

### D29-QNS-001 [P2] — 6 ENUM Columns in `qns_questions_bank` Migration

| Column | ENUM Values |
|--------|-------------|
| `content_format` | HTML, JSON, LATEX, MARKDOWN, TEXT |
| `media_location_for_question` | Above Text, Below Text, Left, Right |
| `media_location_for_teacher_explanation` | Above Text, Below Text, Left, Right |
| `ques_owner` | PrimeGurukul, School |
| `availability` | CLASS_ONLY, ENTITY_ONLY, GLOBAL, SCHOOL_ONLY, SECTION_ONLY, STUDENT_ONLY |
| `status` | APPROVED, ARCHIVED, DRAFT, IN_REVIEW, PUBLISHED, REJECTED |

Platform norm D29: use `sys_dropdown_table` INT FKs instead of ENUM. Total: 6 ENUM columns in `qns_questions_bank`.  
**Severity:** P2 — platform systemic; values cannot be extended without DDL ALTER TABLE

---

### D29-QNS-002 [P2] — 1 ENUM Column in `qns_question_media_jnt` Migration

`media_purpose ENUM('OPTION', 'OPT_EXPLANATION', 'QUESTION', 'QUES_EXPLANATION', 'RECOMMENDATION')` — same D29 pattern.  
**Severity:** P2

---

## Layer B / Persistence — DAT-QNS-001 [P1, NEW] — `syncAll()` Runs Synchronously, HTTP Timeout at Scale

**Evidence — `QuestionStatisticsService.php` lines 18-29:**
```php
public function syncAll(): void
{
    $questions = QuestionBank::active()->get();   // unbounded — fetches ALL active questions
    foreach ($questions as $question) {
        $this->computeAndPersist($question);      // blocking per-question HTTP loop
    }
}
```
Route `POST /question-statistic/sync` (in QuestionStatisticController) dispatches `syncAll()` synchronously in an HTTP request. For schools with >5,000 questions this will exceed the PHP `max_execution_time` (typically 60s). Should be dispatched as a queued Job with `chunk()` to avoid memory exhaustion.  
**Severity:** P1 — operational failure at scale; IMP-QNS-01 in BA phase

---

## Layer G — Validation (D30)

### D30-QNS-001 [P2] — All 6 FormRequests Return Bare `Auth::check()`

**Evidence — `QuestionBankRequest.php` (representative, confirmed):**
```php
public function authorize(): bool
{
    return Auth::check();
}
```
All 6 FormRequests perform authentication-only checks. No resource-level permission check, no ownership check. Platform D30 baseline (437/485 = 90% of FormRequests are bare `true` or equivalent). QNS is marginally better (checks auth vs unauthenticated) but functionally equivalent in authorization terms.  
**Severity:** P2 — D30 pattern; platform systemic

---

## Layer B — Code Quality

### PERF-QNS-001 [P3] — God Controller: `QuestionBankController` at 2746 Lines

Single controller handles CRUD, clone, print, Excel import (validateFile + startImport), review workflow (reviewIndex, reviewShow, reviewApprove, reviewReject), 10+ AJAX cascade endpoints, and filter data. Cannot be unit-tested in isolation. BA-phase noted as BUG-QNS-03 — confirmed 2746 lines.  
**Severity:** P3 — refactoring required before test coverage is practical

---

## D31 Formula Contract Verification

**Source:** `QuestionStatisticsService.php` (lines 1-278, fully read)  
**Reference:** Decision D31 (AI_Brain/state/decisions.md)

| Spec Section | Metric | Formula | Verified |
|---|---|---|---|
| §1 | `difficulty_index` | `(correct / total) × 100`; NULL on 0 attempts | PASS |
| §2 | `discrimination_index` | Kelley 27% rule: `(pU − pL) × 100`; NULL if <4 per group; clamp [−100, +100] | PASS |
| §3 | `guessing_factor` | MCQ only: empirical `pL × 100` if ≥30 attempts; else `100/k`; NULL non-MCQ; clamp [0, 100] | PASS |
| §4 | `min_time_taken_seconds` | MIN where `is_correct=1 AND time>0`; NULL if no correct attempts | PASS |
| §5 | `max_time_taken_seconds` | MAX where `time>0 AND time<ceiling`; ceiling = `expected_time × 3` or 3600 | PASS |
| §6 | `avg_time_taken_seconds` | AVG of valid time feed; NULL if empty | PASS |
| §7 | `total_attempts` | COUNT of evaluated answer rows from Quiz+Quest+Exam feed | PASS |
| §8 | `last_computed_at` | `now()` unconditionally | PASS |
| §9 | Upsert | `updateOrCreate(['question_bank_id' => $id], [...])` on UNIQUE constraint | PASS |
| Feed-forward | Performance category `priority` | Difficulty/discrimination bands → priority 1-10; negative discrimination → priority 10 (MIS-KEYED) | PASS |

**D31 Verdict:** The service implementation is fully spec-compliant. All 9 spec sections and all documented edge cases are correctly handled. The D31 contract is sound.

**Runtime Blocker:** The service fails at the DB write layer (not in computation) due to MIG-QNS-001 — `discrimination_index`, `guessing_factor`, and `avg_time_taken_seconds` are NOT NULL in the migration but the service correctly produces null for them under spec-defined conditions.

---

## Platform Pattern Checklist

| Pattern | Status | Evidence |
|---------|--------|---------|
| D17 — activityLog on all mutating paths | PARTIAL | Some mutating actions log; not comprehensive |
| D24 — `tenant.` prefix (no typos like `tennat.`) | PASS | All Gate calls use correct `tenant.` prefix |
| D25 — No `$request->all()` into models | PASS | Not found in QNS controllers |
| D29 — No ENUM (use sys_dropdown FKs) | FAIL | 7 ENUM columns across 2 migrations (D29-QNS-001, D29-QNS-002) |
| D30 — FormRequest authorize() gated | FAIL | All 6 return `Auth::check()` (D30-QNS-001) |
| D36 — No GENERATED columns degraded | PASS | No `storedAs`/`virtualAs` in any QNS migration |
| D37 — Status INT FK vs string literal consistent | PASS | Status stored as ENUM string; review_status_id uses FK correctly |
| D38 — SoftDeletes/timestamps DDL = model | PASS | All 13 tables verified; `deleted_at` present where SoftDeletes used |
| D39 — Permissions seeded | FAIL | No QNS permission seeder (D39-QNS-001) |
| PRM-D-001 — Gate::policy duplicate overwrite | FAIL | QuestionBank::class registered twice (SEC-QNS-003) |

---

## Finding Catalog (all findings)

| Code | Severity | Layer | Summary |
|------|----------|-------|---------|
| SEC-QNS-003 | P0 | G/Auth | Duplicate Gate::policy(QuestionBank::class) — QuestionBankPolicy dead, AiQuestionGeneratorPolicy governs all CRUD |
| BUG-QNS-002 | P0 | A/Routing | Routes /get-ai-providers + /ai-provider-status/{id} → non-existent methods → HTTP 500 |
| BUG-QNS-003 | P0 | C/FSM | reviewApprove() writes PUBLISHED directly, bypassing APPROVED state; FSM and BR-QNS-008 violated |
| SEC-QNS-004 | P0 | G/Tenancy | API routes missing tenancy middleware stack — runs in central DB context |
| BUG-QNS-001 | P0 | A/Code | generateQuestions() early return at line 222 — real AI permanently unreachable (CONFIRMED OPEN, known-issues) |
| SEC-QNS-006 | P1 | G/Config | env('CHATGPT_API_KEY') and env('GEMINI_API_KEY') direct in controller — null after config:cache (partial fix from SEC-QNS-002) |
| SEC-QNS-007 | P1 | G/Auth | QuestionMediaStoreController uses tenant.competency.viewAny — wrong policy prefix |
| SEC-QNS-008 | P1 | G/Tenancy | EnsureTenantHasModule middleware absent from web route stack |
| SEC-QNS-009 | P1 | G/Auth | print(), validateFile(), startImport() have no Gate::authorize() |
| D39-QNS-001 | P1 | G/Auth | No permission seeder — module is super-admin-only for non-SA users |
| BUG-QNS-004 | P1 | G/Auth | 6 AJAX cascade endpoints in AIQuestionGeneratorController ungated (getSections, getSubjects, getLessons, getTopics, getSubjectGroups, downloadCSV) |
| MIG-QNS-001 | P1 | D/Schema | qns_question_statistics: discrimination_index, guessing_factor, avg_time_taken_seconds NOT NULL but service writes null — SQLSTATE 1048 runtime error |
| ORM-QNS-001 | P1 | B/ORM | scopeApproved() references 'ques_reviewed_status' not 'status' — always returns 0 rows silently |
| DAT-QNS-001 | P1 | B/Perf | syncAll() unbounded synchronous loop — HTTP timeout for banks >5K questions |
| D29-QNS-001 | P2 | D/Schema | 6 ENUM columns in qns_questions_bank (D29 pattern violation) |
| D29-QNS-002 | P2 | D/Schema | 1 ENUM column in qns_question_media_jnt (D29 pattern violation) |
| D30-QNS-001 | P2 | G/Validation | All 6 FormRequests return Auth::check() — no resource-level authorization |
| ORM-QNS-002 | P2 | B/ORM | questionMediaStores() uses 'id' as FK — broken relationship; should use BelongsToMany through junction |
| DEAD-QNS-001 | P2 | A/Code | getDemoResponse() ~90 lines of hardcoded arrays — dead code in production |
| BUG-QNS-005 | P2 | A/Code | AIQuestionPolicy.php never registered in ServiceProvider — dead file alongside AiQuestionGeneratorPolicy.php |
| PERF-QNS-001 | P3 | A/Code | QuestionBankController at 2746 lines — God controller; service extraction required |
| TEST-QNS-001 | P3 | A/Tests | 0 tests — 7 controllers, 16 models, 2 services, 2 importers, no Pest coverage |

---

## Health Score

| Layer | Weight | Score | Notes |
|-------|--------|-------|-------|
| 1 — DDL Schema | 8 | 0.55 | All 13 migrations present; MIG-QNS-001 + 7 D29 ENUMs |
| 2 — Migration↔Model Drift | 8 | 0.45 | scopeApproved wrong col; statistics NOT NULL mismatch; ORM-QNS-002 |
| 3 — Service Quality | 5 | 0.72 | QuestionStatisticsService D31-compliant; QuestionUsageCheckService OK; syncAll() blocking |
| 4 — Authorization | 14 | 0.08 | Duplicate policy overwrite; 9 unguarded methods; wrong gate; no seeder |
| 5 — Tenancy | 12 | 0.42 | Web routes correct; API routes no tenancy; no EnsureTenantHasModule |
| 6 — Validation | 6 | 0.42 | FormRequests exist; all bare Auth::check(); D30 pattern |
| 7 — Business Rules | 10 | 0.42 | 3/12 enforced; FSM bypassed; scopeApproved broken; BR-QNS-008 violated |
| 8 — Data Integrity | 7 | 0.42 | FSM bypass; statistics write blocked by NOT NULL |
| 9 — Code Quality | 5 | 0.32 | 2746-line controller; dead code; missing methods; 2 dead policy files |
| 10 — Performance/Async | 6 | 0.55 | syncAll() sync; D31 service itself is clean |
| 11 — Frontend/UI | 2 | 0.85 | No confirmed XSS; Blade views present |
| 12 — Deployment Gate | 7 | 0.18 | 2 routes → HTTP 500; env() keys; no rate limit |
| 13 — Test Coverage | 10 | 0.00 | 0 tests |
| **Total** | **100** | | **Raw: 37** |

**Health Score: 37 / 100** (P0 present — maximum is 40; raw is already 37 so cap does not inflate the score)  
**Verdict: DEPLOY NO-GO**

---

## Recommended Fix Priority

### Immediate (P0 — Before Any Deployment)
1. **SEC-QNS-003**: Remove second `Gate::policy(QuestionBank::class, ...)` from ServiceProvider line 75
2. **BUG-QNS-002**: Implement `getAIProviders()` and `checkProviderStatus()` or remove routes
3. **BUG-QNS-003**: Change `reviewApprove()` to write `status = 'APPROVED'`; add separate publish action
4. **SEC-QNS-004**: Add tenancy middleware to `mapApiRoutes()` in RouteServiceProvider
5. **BUG-QNS-001**: Remove early return at AIQuestionGeneratorController:222

### Sprint 1 (P1 — Before Feature Testing)
6. **MIG-QNS-001**: Add `->nullable()` to discrimination_index, guessing_factor, avg_time_taken_seconds + alter migration
7. **D39-QNS-001**: Create `QuestionBankPermissionSeeder` for all `tenant.question-bank.*` abilities
8. **ORM-QNS-001**: Fix `scopeApproved()` column name to `status`
9. **SEC-QNS-006**: Replace `env('CHATGPT_API_KEY')` with `config('services.openai.key')` (and add config/services.php entries)
10. **SEC-QNS-007**: Fix `QuestionMediaStoreController` gate to `tenant.question-media.viewAny`
11. **SEC-QNS-008**: Add `EnsureTenantHasModule:QuestionBank` to RSP middleware stack
12. **SEC-QNS-009**: Add `Gate::authorize()` to `print()`, `validateFile()`, `startImport()`
13. **BUG-QNS-004**: Add `Gate::authorize()` to 6 AJAX endpoints in AIQuestionGeneratorController
14. **DAT-QNS-001**: Extract `syncAll()` into a queued Job with `QuestionBank::active()->chunk(100, ...)`

### Sprint 2 (P2 / Structural)
15. **ORM-QNS-002**: Fix `questionMediaStores()` to `belongsToMany` through `qns_question_media_jnt`
16. **D30-QNS-001**: Add resource-level authorization to all 6 FormRequest `authorize()` methods
17. **DEAD-QNS-001**: Remove `getDemoResponse()` and hardcoded demo arrays
18. **BUG-QNS-005**: Delete `AIQuestionPolicy.php`
19. **PERF-QNS-001**: Extract `QuestionBankService` — move CRUD logic out of 2746-line controller

---

## Revision Notes

- **SEC-QNS-001** in known-issues.md states "ZERO auth on ALL methods" in AIQuestionGeneratorController — this is inaccurate. Confirmed: `index()`, `generateQuestions()`, `saveQuestions()` are gated. Six other methods are not. The correction is logged here.
- **SEC-QNS-002** in known-issues.md (hardcoded API keys — CRITICAL) is PARTIALLY remediated: keys are now read from `env()` not hardcoded strings. Remaining defect (SEC-QNS-006) is a deployment configuration issue, severity P1.
- IMP-QNS-05 from BA phase (`scopeApproved()` wrong column) is confirmed and elevated to P1 (ORM-QNS-001).
- Progress.md note that "6 controllers unrouted" is stale and incorrect — all 7 controllers are routed.

---

*Audit completed: 2026-06-29 | Mode X (A + B + C + G + scoped D) | pa-technical-auditor*
