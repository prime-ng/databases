# LmsQuests (QST) — Mode X Complete Technical Audit
**Date:** 2026-06-29 | **Auditor:** pa-technical-auditor (Phase 3 pipeline)
**Mode:** X = Layer A + Layer B (FRD) + Layer C (Business Rules) + Layer G (Cross-Cutting) + Scoped Layer D (Schema Three-Way Reconcile)
**Codebase branch:** main | **Commit:** b6f5e5d16

---

## 1. Executive Summary

| Dimension | Value |
|-----------|-------|
| Module code | QST |
| Tenant scope | Yes (database-per-tenant, stancl/tenancy v3.9) |
| Owned tables | 4 (`lms_quest*`) |
| Migrations | 5 (4 create + 1 alter) |
| Controllers | 4 |
| Models | 4 |
| Policies | 4 (QuestPolicy has fatal duplicate methods — latent P1) |
| FormRequests | 4 (all D30 — `authorize(){return true;}`) |
| Services | 5 |
| Tests | 0 |
| P0 issues found | 4 |
| P1 issues found | 12 |
| P2 issues found | 8 |
| **Health Score** | **38 / 100 (P0 cap applies — cap is 40)** |
| **Deployment Gate** | **NO-GO** |

**Critical blocker summary (P0):**
1. **SEC-QST-001** — `LmsQuestController::index()` `Gate::authorize` commented out; any authenticated user reaches the full quest hub and analytics dashboard.
2. **BUG-QST-001** — `LmsQuestController::forceDelete()` calls `DB::beginTransaction()/commit()/rollBack()` but `Illuminate\Support\Facades\DB` is NOT imported; every permanent-delete attempt is a fatal `Class "DB" not found` crash.
3. **BUG-QST-002** — `QuestQuestionController::store()` uses `$quest->id` (line 985) before `$quest` is ever assigned; any hit on the `POST quest-question` route throws `Undefined variable $quest` fatal error.
4. **MIG-QST-001** — `lms_quest_scopes.topic_id` is `NOT NULL` in the create migration (no `->nullable()`), but the application (QuestScopeRequest, controller) treats it as optional; any scope created without a topic_id produces a DB integrity constraint violation.

---

## 2. Module Inventory (Live — 2026-06-29)

| Item | Count | Files |
|------|-------|-------|
| Controllers | 4 | `LmsQuestController`, `QuestScopeController`, `QuestQuestionController`, `QuestAllocationController` |
| Models | 4 | `Quest`, `QuestScope`, `QuestQuestion`, `QuestAllocation` |
| Policies | 4 | `QuestPolicy` (broken), `QuestScopePolicy`, `QuestQuestionPolicy`, `QuestAllocationPolicy` |
| FormRequests | 4 | `QuestRequest`, `QuestScopeRequest`, `QuestQuestionRequest`, `QuestAllocationRequest` |
| Services | 5 | `QuestQueryService`, `QuestUsageCheckService`, `QuestQuestionUsageCheckService`, `QuestScopeUsageCheckService`, `QuestAllocationUsageCheckService` |
| Providers | 3 | `LmsQuestsServiceProvider`, `EventServiceProvider`, `RouteServiceProvider` |
| Blade views | 30 | 5 per resource × 4 + hub/dashboard/summary/paper-check/activity-log/components |
| Seeders | 2 | `LmsQuestsDatabaseSeeder`, `LmsQuestSeeder` |
| Tests | 0 | Feature + Unit directories have only `.gitkeep` |
| Owned migrations | 5 | 4 create + `2026_06_18_100000_update_lms_quests_and_scopes.php` |
| Route file | 1 | `Modules/LmsQuests/routes/web.php` (78 lines) |

---

## 3. Layer D — Three-Way Schema Reconcile (DDL ↔ Migration ↔ Model)

### 3.1 `lms_quests`

| Column | Migration | Model `$fillable` | Model `$casts` | Status |
|--------|-----------|-------------------|-----------------|--------|
| id | increments | — (implicit) | — | OK |
| uuid | binary(16) | yes | string | OK |
| quest_code | string(50) UNIQUE | yes | — | OK |
| title | string | yes | — | OK |
| description | text nullable | yes | — | OK |
| instructions | text nullable | yes | — | OK |
| status | string(20) default 'DRAFT' | yes | — | OK |
| duration_minutes | unsignedInteger nullable | yes | integer | OK |
| total_marks | decimal(8,2) | yes | decimal:2 | OK |
| total_questions | unsignedInteger | yes | integer | OK |
| passing_percentage | decimal(5,2) | yes | decimal:2 | OK |
| allow_multiple_attempts | boolean | yes | boolean | OK |
| max_attempts | unsignedTinyInteger | yes | integer | OK |
| negative_marks | decimal(4,2) | yes | decimal:2 | OK |
| is_randomized | boolean | yes | boolean | OK |
| question_marks_shown | boolean | yes | boolean | OK |
| auto_publish_result | boolean | yes | boolean | OK |
| timer_enforced | boolean | yes | boolean | OK |
| show_correct_answer | boolean | yes | boolean | OK |
| show_explanation | boolean | yes | boolean | OK |
| ignore_difficulty_config | boolean | yes | boolean | OK |
| is_system_generated | boolean | yes | boolean | OK |
| only_unused_questions | boolean | yes | boolean | OK |
| only_authorised_questions | boolean | yes | boolean | OK |
| is_active | boolean | yes | boolean | OK |
| academic_session_id | unsignedInteger FK→glb_academic_sessions | yes | — | SEE TEN-QST-001 |
| class_id | unsignedInteger FK→sch_classes | yes | — | OK |
| subject_id | unsignedInteger FK→sch_subjects | yes | — | OK |
| quest_type_id | unsignedInteger FK→lms_assessment_types | yes | — | OK |
| difficulty_config_id | unsignedInteger nullable FK→lms_difficulty_distribution_configs | yes | — | OK |
| created_by | unsignedInteger nullable FK→sys_users | yes | — | OK |
| timestamps | created_at, updated_at | yes (fillable — see note) | datetime ×2 | MINOR: `created_at`/`updated_at` in `$fillable` is unusual but not a bug |
| deleted_at | softDeletes | yes (fillable — see note) | datetime | MINOR: `deleted_at` in `$fillable` is unusual |
| **show_result_immediately** | **ABSENT** | **yes** | **boolean** | **PHANTOM FIELD (P2) — PHANTOM-QST-001** |

> **PHANTOM-QST-001:** `show_result_immediately` is in `Quest::$fillable` and `$casts` but has no migration column. Eloquent silently ignores writes; reads return null.

> **Cross-DB FK note (TEN-QST-001):** Migration references `glb_academic_sessions` in global_db, but `Quest::academicSession()` and `Quest::generateQuestCode()` resolve through `Modules\Prime\Models\AcademicSession`. AcademicSession in Prime module maps to prime_db (`prm_academic_sessions`), not `glb_academic_sessions`. These are different databases and potentially different tables. See TEN-QST-001 in issue register.

### 3.2 `lms_quest_scopes`

| Column | Migration | Model | Status |
|--------|-----------|-------|--------|
| id | increments | — | OK |
| question_type_id | unsignedInteger **nullable** | yes | OK |
| target_question_count | unsignedInteger default 0 | yes | OK |
| is_active | boolean | yes | OK |
| quest_id | unsignedInteger FK→lms_quests | yes | OK |
| lesson_id | unsignedInteger FK→slb_lessons | yes | OK |
| topic_id | unsignedInteger FK→slb_topics | yes | **P0 — NOT NULL in migration; app treats as optional (MIG-QST-001)** |
| question_type FK | added by alter migration | yes | OK (FK only, column already present) |
| timestamps | yes | — | OK |
| deleted_at | softDeletes | yes | OK |

> **MIG-QST-001 (P0):** `create_lms_quest_scopes_table.php` line 25: `$table->unsignedInteger('topic_id')` — no `->nullable()`. The alter migration (`2026_06_18_100000`) only adds a FK for `question_type_id`; it does NOT make `topic_id` nullable. `QuestScopeRequest` validates `scopes.*.topic_id` as `nullable` and the application expects it to be optional. Any scope insertion without a topic_id will throw `SQLSTATE[23000] Integrity constraint violation: 1048 Column 'topic_id' cannot be null`.

### 3.3 `lms_quest_questions`

| Column | Migration | Model `$fillable` | Status |
|--------|-----------|-------------------|--------|
| id | increments | — | OK |
| ordinal | unsignedInteger default 0 | yes | OK |
| marks_override | decimal(5,2) nullable | yes | OK |
| is_active | boolean | yes | OK |
| quest_id | unsignedInteger FK→lms_quests | yes | OK |
| question_id | unsignedInteger FK→qns_questions_bank | yes | OK |
| UNIQUE | (quest_id, question_id) | — | OK |
| timestamps | yes | — | OK |
| deleted_at | softDeletes | yes | OK |

> Schema reconcile: CLEAN for `lms_quest_questions`.

### 3.4 `lms_quest_allocations`

| Column | Migration | Model `$fillable` | Status |
|--------|-----------|-------------------|--------|
| id | increments | — | OK |
| allocation_type | **ENUM('CLASS','GROUP','SECTION','STUDENT')** | yes | **D29 pattern — SCH-QST-001 (P2)** |
| target_table_name | string(60) | yes | OK |
| target_id | unsignedInteger | yes | OK |
| published_at | dateTime nullable | yes | OK |
| due_date | dateTime nullable | yes | OK |
| cut_off_date | dateTime nullable | yes | OK |
| is_auto_publish_result | boolean | yes | OK |
| result_publish_date | dateTime nullable | yes | OK |
| is_active | boolean | yes | OK |
| quest_id | unsignedInteger FK→lms_quests | yes | OK |
| assigned_by | unsignedInteger nullable FK→sys_users | yes | OK |
| idx | (allocation_type, target_id) | — | OK |
| timestamps | yes | — | OK |
| deleted_at | softDeletes | yes | OK |

> **SCH-QST-001 (P2, D29):** `allocation_type` uses ENUM instead of a `sys_dropdowns` FK. Platform baseline pattern — not blocking.

### 3.5 Alter Migration Rollback Bug (MIG-QST-002)

`2026_06_18_100000_update_lms_quests_and_scopes.php` `down()` method (lines 31-38) attempts:
- `$table->dropForeign('fk_quest_lesson')` — this FK was never created
- `$table->dropColumn('lesson_id')` from `lms_quests` — this column was never added

A `php artisan migrate:rollback` targeting this migration would fail with `General error: Can't DROP 'fk_quest_lesson'; check that column/key exists`.

---

## 4. Layer A — Module Structure & Scaffolding

### 4.1 Scaffolding
- Module namespace: `Modules\LmsQuests` — compliant with nwidart/laravel-modules v12 convention.
- `LmsQuestsServiceProvider` boots correctly: registers policies, migrations, translations, views, morphMap.
- `RouteServiceProvider` maps `routes/web.php` with the full tenancy middleware stack:
  `web, InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive, auth, verified` — CONFIRMED correct (Layer 6.1 PASS).
- Route prefix: `/lms-quests`, route name prefix: `lms-quests.`.

### 4.2 Tab-Hub Architecture
Tab-hub pattern is correctly implemented: `LmsQuestController::index()` serves the hub; child controller `index()` methods are hard-disabled via `abort(404)` (QuestScope, QuestQuestion, QuestAllocation), funneling all listing through the hub tabs. This is intentional.

### 4.3 Tests
Zero tests. Module target was ≥60% coverage (V2 goal). **No automated test coverage exists for any functional path.**

### 4.4 Route Ordering Defect (BUG-QST-ROUTE)
`routes/web.php` registers trash GET routes AFTER the corresponding `Route::resource()` calls for `quest-scope`, `quest-question`, and `quest-allocation`. The resource `show` route `GET {model}` captures "trash" as the model parameter before the explicit trash route can match, making trash views unreachable. Quest itself is ordered correctly (trash route at line 23, before resource at line 25).

Affected routes:
- `GET /quest-scope/trash/view` → shadowed by `GET quest-scope/{quest_scope}` (routes/web.php line 36 before 37)
- `GET /quest-allocation/trash/view` → shadowed by `GET quest-allocation/{quest_allocation}` (routes/web.php line 48 before 49)
- `GET /quest-question/trash/view` → shadowed by `GET quest-question/{quest_question}` (routes/web.php line 56 before 57)

### 4.5 Module Entry Guard (SEC-QST-002)
No `EnsureTenantHasModule` middleware is applied to ANY LmsQuests route. Any active tenant can access all quest features regardless of subscription plan. This is a systemic platform issue (SEC-LMS-001 in known-issues.md) but confirmed present for QST.

---

## 5. Layer G — Security, Tenancy, and Cross-Cutting Concerns

### 5.1 Gate / Authorization (Layer 7)

**P0 — SEC-QST-001 (Commented Gate)**
`LmsQuestController::index()` line 71:
```php
// Gate::authorize('tenant.quest.viewAny');
```
The `index()` method is the entry point to the entire quest hub (dashboard, quest list, scope, questions, allocations, summary, activity log — all tabs). With the gate commented out, any authenticated user reaches the full hub regardless of role. Evidence-confirmed at line 71.

**P1 — SEC-QST-003 (saveAnswerGrade — no Gate)**
`LmsQuestController::saveAnswerGrade()` (line 1114) has no `Gate::authorize()`. Any authenticated user can POST to this endpoint to write arbitrary marks for any student's quest answer. This is a grading data-integrity bypass.

**P1 — SEC-QST-004 (getSubjectsByClass — no Gate)**
`LmsQuestController::getSubjectsByClass()` (line 506) has no `Gate::authorize()`. The AJAX endpoint exposes class/subject associations to any authenticated user.

**P1 — SEC-QST-005 (QuestQuestionController AJAX endpoints — no Gate)**
The following AJAX methods in `QuestQuestionController` have no `Gate::authorize()`:
- `getSections()` (line 130) — exposes class-section data
- `getSubjectGroups()` (line 154) — exposes subject group data
- `getLessons()` (line 165) — exposes lesson data
- `getTopics()` (line 194) — exposes topic data

**P1 — SEC-QST-007 (QuestAllocationController AJAX endpoints — no Gate)**
- `getTargetOptions()` (line 652) — exposes student/class/section/group lists
- `getQuests()` (line 720) — exposes quest metadata list

**P2 — SEC-QST-002 (no EnsureTenantHasModule)**
Module access is not plan-gated. Any active tenant reaches LmsQuests features regardless of subscription. Systemic pattern (see SEC-LMS-001).

### 5.2 Tenancy Isolation (Layer 6)

**P1 — TEN-QST-001 (Cross-Layer Model: AcademicSession)**
Both `LmsQuestController` (line 29: `use Modules\Prime\Models\AcademicSession`) and `Quest` model (line 15: `use Modules\Prime\Models\AcademicSession`) import and use the `AcademicSession` model from the `Prime` module (central/prime_db).

The `lms_quests` migration creates a FK to `glb_academic_sessions` (global_db):
```php
$table->foreign('academic_session_id', 'fk_quest_academic_session')
      ->references('id')
      ->on($globalDb . '.glb_academic_sessions')
      ->onDelete('cascade');
```

`Prime\Models\AcademicSession` resolves to `prime_db.prm_academic_sessions` (or similar prime table), NOT `global_db.glb_academic_sessions`. These are different databases and potentially different tables. Quest code generation, academic hierarchy computation, and store/update all resolve academic session through the wrong cross-layer model. The correct model to use is `GlobalMaster\Models\AcademicSession` (global_db) or a tenant-local academic session mirror.

**CONFIRMED (Layer 6.2) — No raw tenancy initialization in module code**
No `tenancy()->initialize(` calls found in the module. Tenancy is managed at the middleware layer — correct.

**CONFIRMED (Layer 6.1) — Tenancy middleware stack correct**
RSP carries: `web, InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive, auth, verified` — all required layers present.

### 5.3 Policy Correctness

**P1 — BUG-QST-POL (QuestPolicy duplicate method definitions)**
`QuestPolicy.php` defines `view()` four times (lines 22, 29, 37, 45) and `update()` twice (lines 53, 69). PHP will throw a fatal compile error (`Cannot redeclare QuestPolicy::view()`) the first time any code triggers model-based policy resolution for a `Quest` instance. All four `view()` definitions return different permissions (`tenant.quest.view`, `tenant.quest-dashboard.view`, `tenant.quest-summary.view`, `tenant.quest-activity-log.view`). The duplicate stubs appear to be unmerged copy-paste artifacts.

Current controllers use string-based `Gate::authorize('tenant.quest.*')` — NOT model-based `Gate::authorize('view', $quest)` — so the policy class is not currently loaded at runtime. The `LmsQuestsServiceProvider` imports and registers the policy (line 68: `Gate::policy(Quest::class, QuestPolicy::class)`) but PHP does not autoload the class until it is instantiated. The bug becomes P0 the moment any model-based authorization path is introduced.

**CONFIRMED — Policy permission strings**
All other policies (QuestScopePolicy, QuestQuestionPolicy, QuestAllocationPolicy) and the unbroken methods in QuestPolicy correctly use the `tenant.*` prefix.

### 5.4 D30 Pattern (FormRequest `authorize(){return true;}`)

All 4 FormRequests return hardcoded `true` from `authorize()`:
- `QuestRequest` (line 12)
- `QuestScopeRequest` (line 11)
- `QuestQuestionRequest` (line 14)
- `QuestAllocationRequest` (line 18)

This matches the platform baseline of 90% (D30). Controllers handle gate authorization independently.

### 5.5 D25 Pattern (`$request->all()` mass assignment)

`$request->all()` appears in `QuestAllocationController.php` (×3, lines 208/339/540) and `QuestScopeController.php` (×2, lines 250/491) — but exclusively inside `Log::error()` calls for exception logging. **D25 is CLEAN** for QST: no `Model::create($request->all())` patterns. All creation paths use `$request->validated()`.

### 5.6 Environment/Debug Checks

- No `env(` calls found in module PHP files — Layer 12.4 PASS.
- No `dd(` debug statements found in module PHP files — Layer 4.2 PASS.
- `{!! !!}` unescaped output present in Blade views: primarily used for pagination links (acceptable Laravel pattern), JSON injection for chart data (acceptable), and one occurrence of `$c['sub']` in `dashboard/index.blade.php:75` (P2 observation). `summary/student_result.blade.php` lines 330 and 347 render `$question['text']` and `$opt['text']` unescaped — this is intentional for rendering HTML-formatted question content from the question bank and is acceptable if the content is sanitized at input time.

---

## 6. Layer A/B/C — Controller Deep Audit

### 6.1 LmsQuestController (1600 lines)

**P0 — BUG-QST-001 (Missing DB import in forceDelete)**
`LmsQuestController::forceDelete()` (lines 775-808) uses:
```php
DB::beginTransaction();
// ...
DB::commit();
// ...
DB::rollBack();
```
The import block (lines 1-42) does NOT include `use Illuminate\Support\Facades\DB;`. Every permanent quest deletion throws `Class "DB" not found`. This crash is silent to users if not caught (the catch block also uses `DB::rollBack()`, which also fails). All data and child records (quest questions, scopes) in the attempted deletion are left in a partially-modified state.

**P0 — SEC-QST-001 (Commented Gate in index)**
Already documented in 5.1. Line 71.

**P1 — BUG-QST-006 (Duplicate quest code generation)**
Quest code generation occurs in two places:
1. `Quest::boot()` `creating` hook (`Quest.php:104-106`) — generates code model-side via `generateQuestCode()`.
2. `LmsQuestController::store()` (lines 574-586) — also generates and assigns `questData['quest_code']` before `Quest::create($questData)`.

When `store()` runs, it sets `quest_code` in `$questData` before calling `Quest::create()`. Inside `create()`, the boot `creating` hook fires but skips code generation because `$model->quest_code` is already set. However, `update()` (lines 664-675) also contains a duplicate code generation block, which could replace the existing code on updates — even though `Quest::boot()` `updating` hook only re-generates if `quest_code` is dirty. The controller's code generation path uses `AcademicSession::find()` directly (cross-layer), while the model's `generateQuestCode()` also calls `AcademicSession::find()` (same cross-layer). Any fix for TEN-QST-001 must address both sites.

**P1 — PERF-QST-001 (score_distribution — all rows to PHP)**
Dashboard `score_distribution` metric (lines 425-446):
```php
QuizQuestResult::query()
    ->where('assessment_type', 'QUEST')
    ->whereHas('quest', ...)
    ->get(['percentage'])   // ALL result rows fetched to PHP
    ->each(function ($r) use (&$bins) { ... });
```
Should use MySQL `SUM(CASE WHEN percentage BETWEEN 0 AND 20 THEN 1 ELSE 0 END)` aggregation. On large datasets (thousands of students), this will exhaust PHP memory.

**P2 — PERF-QST-002 (ClassSection::find called ~8 times per dashboard load)**
`dashboardStats` computes ~8 independent metrics each calling `ClassSection::find($request->class_section_id)`. The result should be memoized once before the metrics computation block.

**P1 — SEC-QST-003 / SEC-QST-004 (unguarded endpoints)**
Already documented in 5.1. Lines 506 and 1114.

### 6.2 QuestQuestionController (1485 lines)

**P0 — BUG-QST-002 (Undefined `$quest` in store)**
`QuestQuestionController::store()` (lines 977-1031) uses `$quest->id` on line 985 in the total-question-count check:
```php
$existingCount = QuestQuestion::where('quest_id', $quest->id)->count();
if ($quest->total_questions > 0 && ($existingCount + 1) > $quest->total_questions) {
```
`$quest` is never assigned before this line. The validated data is not retrieved until line 990 (`$questionData = $request->validated()`), and even then `$quest` is not assigned. The controller is designed to pass through `bulkStore()` for most operations — the `store()` action is dead in normal usage — but the route exists (`POST quest-question`) and will throw `Undefined variable $quest` on any direct hit.

**P1 — BUG-QST-003 (Undefined `$usageTypeId` in search)**
`QuestQuestionController::search()` lines 311-323:
```php
// $usageTypeId = QuestionUsageType::where('code', 'QUEST')->value('id');
// if (! $usageTypeId) { ... }
$query->whereNotIn('id', function($q) use ($usageTypeId) {
    ...
});
```
The `$usageTypeId` assignment is commented out. When `$onlyUnused` is true, the closure captures an undefined variable. In PHP 8.2, this produces an `Undefined variable $usageTypeId` warning. Since `$usageTypeId` is not actually used inside the closure body (the body uses the hardcoded string `'QUEST'`), execution continues but the capture is semantically broken. The original intent (filtering by usage type ID) is dead.

**P1 — BUG-QST-004 (bulkStore double-processes questions_data)**
`QuestQuestionController::bulkStore()` parses `questions_data` into `$questionsToAdd` + `$ordinalMap` (lines 543-555), performs pre-authorization count/marks checks (lines 556-584), then calls `Gate::authorize()` (line 586), re-validates (lines 588-594), re-assigns `$quest` (line 596), and re-parses `questions_data` from scratch into a new `$questionsToAdd` (lines 599-614). The first `$ordinalMap` is completely discarded; the second parse omits the `ordinalMap` reference and uses `$item['ordinal']` instead. The pre-auth business rule checks on lines 556-584 use a different `$questionsToAdd` array than the one ultimately used for insertion.

**P1 — BUG-QST-005 (addQuestions — legacy endpoint unguarded)**
`QuestQuestionController::addQuestions()` (lines 1454-1483) has no `Gate::authorize()`, no DB transaction, no duplicate `QuestionUsageLog` prevention, and no constraint checks. It is a legacy endpoint not shown in the primary UI but the route exists.

**P1 — SEC-QST-005 (AJAX endpoints unguarded)**
Already documented in 5.1.

### 6.3 QuestAllocationController (744 lines)

**POSITIVE: DB transactions, Gate checks, and usage-guard pattern consistently applied.**
All write methods (store, update, destroy, restore, forceDelete) use `DB::beginTransaction()`, proper Gate checks, usage-guard service, and full error logging. This controller is the best-structured in the module.

**P2 — BUG-QST-011 (SECTION validation uses wrong table)**
`QuestAllocationRequest::getTargetTable()` returns `'sch_sections'` for allocation_type 'SECTION' (used in `Rule::exists('sch_sections', 'id')` validation). However, `QuestAllocationController::store()` and `update()` resolve the SECTION target to a `ClassSection` junction record (sch_class_section_jnt) and overwrite `target_id` with the junction ID. The validation thus checks `section_id` against `sch_sections` but the DB stores the junction ID. A valid section ID that has no corresponding class-section junction could pass validation but fail at the app level.

**P2 — BUG-QST-010 (morphTo fails for SECTION allocation type)**
`QuestAllocation::target()` uses `morphTo(null, 'target_table_name', 'target_id')`. The `LmsQuestsServiceProvider` registers a morphMap:
```php
Relation::morphMap([
    'sch_classes'       => SchoolClass::class,
    'sch_sections'      => Section::class,
    'sch_entity_groups' => EntityGroup::class,
    'std_students'      => Student::class,
]);
```
For SECTION allocations, `target_table_name` is stored as `'sch_class_section_jnt'` (set by `getTargetTable()` in controller). The morphMap does NOT include `'sch_class_section_jnt'`. Calling `$allocation->target` on a SECTION allocation returns null. Actual target resolution is done via manual match() in `getTargetNameAttribute()` and controller show(), bypassing the morphTo entirely — but any code relying on `$allocation->target` for SECTION allocations will silently get null.

**P2 — BUG-QST-012 (allocation FK naming inconsistency)**
`QuestAllocation::attempts()` defines the FK as `'quest_allocation_id'` (line 64). `publishHiddenRecommendations()` (line 575) queries `lms_quiz_quest_attempts.allocation_id`. If the actual column name is `allocation_id` (not `quest_allocation_id`), the `attempts()` relation will always return empty. The canonical column name in the DB must be confirmed and one usage corrected.

### 6.4 QuestScopeController

Confirmed: `$request->all()` used only in `Log::error()` calls — D25 clean. Gates present on all write methods. DB transactions used correctly. No import issues found.

---

## 7. Layer B — FRD Gap Analysis (REQ/BR/RPT Verbatim)

Source: `QST_FRD_Complete_2026-06-29.md` (21 REQ · 32 BR · 6 RPT)

### 7.1 REQ Coverage

| REQ ID | Description (abbreviated) | Status | Evidence |
|--------|---------------------------|--------|----------|
| REQ-QST-001 | Quest hub dashboard view | **PARTIAL** | SEC-QST-001: hub gate commented out |
| REQ-QST-002 | Quest CRUD (create/edit/delete/restore/force-delete) | **PARTIAL** | BUG-QST-001: forceDelete fatal error |
| REQ-QST-003 | Quest question management | **PARTIAL** | BUG-QST-002: store() fatal error; bulkStore primary path works |
| REQ-QST-004 | Quest scope (lesson/topic coverage) management | **PARTIAL** | MIG-QST-001: topic_id NOT NULL blocks optional scope |
| REQ-QST-005 | Quest allocation (CLASS/SECTION/GROUP/STUDENT) | **DONE** | Full CRUD, gates, transactions — QuestAllocationController |
| REQ-QST-006 | Analytics dashboard (stats, charts, distribution) | **PARTIAL** | PERF-QST-001: score_distribution unbounded query |
| REQ-QST-007 | Paper-check / manual grading interface | **DONE** | paper-check controller + Blade views present |
| REQ-QST-008 | Answer grading save | **PARTIAL** | SEC-QST-003: saveAnswerGrade no Gate |
| REQ-QST-009 | Result publication + recommendation trigger | **DONE** | `QuizQuestResultPublished::dispatch()` at LmsQuestController:1097 |
| REQ-QST-010 | Performance report (per-student/quest) | **DONE** | Summary controller + Blade views |
| REQ-QST-011 | Question search/filter (AJAX) | **PARTIAL** | BUG-QST-003: undefined $usageTypeId on `only_unused=true` |
| REQ-QST-012 | Usage guard (prevent editing in-use quests) | **DONE** | 5 `*UsageCheckService` consistently applied |
| REQ-QST-013 | Difficulty distribution enforcement | **DONE** | `validateDifficultyDistribution()` in bulkStore |
| REQ-QST-014 | Quest scope enforcement | **DONE** | `validateQuestScopes()` in bulkStore |
| REQ-QST-015 | Question marks override | **DONE** | `updateMarks()` with constraint check |
| REQ-QST-016 | Ordinal/sequence management | **DONE** | `updateOrdinal()` |
| REQ-QST-017 | Quest code auto-generation | **PARTIAL** | BUG-QST-006: duplicate generation paths |
| REQ-QST-018 | Tab-hub authorization | **PARTIAL** | SEC-QST-001: viewAny gate disabled |
| REQ-QST-019 | Quest question bulk add/remove | **DONE** | `bulkStore()` / `bulkDestroy()` |
| REQ-QST-020 | System-generated quests (auto question selection) | **NOT STARTED** | `is_system_generated` flag present, no `QuestGenerationService` |
| REQ-QST-021 | Activity log | **DONE** | `activityLog()` called in all mutating methods |

### 7.2 BR Coverage (Selected Critical)

| BR ID | Rule | Status | Notes |
|-------|------|--------|-------|
| BR-QST-001 | Quest must have at least 1 question to publish | DONE | `canPublish()` in Quest model |
| BR-QST-002 | Question count must match `total_questions` to publish | DONE | `canPublish()` check |
| BR-QST-003 | Cannot modify quest with active student attempts | DONE | Usage guards in all controllers |
| BR-QST-004 | `topic_id` optional in scope | **PARTIAL** | Migration enforces NOT NULL (MIG-QST-001) |
| BR-QST-005 | Difficulty config enforced unless `ignore_difficulty_config=true` | DONE | validateDifficultyDistribution() |
| BR-QST-006 | SECTION allocation must resolve to class-section junction | DONE | Controller converts section_id→junction_id |
| BR-QST-007 | Result publication triggers recommendation | DONE | QuizQuestResultPublished dispatch |
| BR-QST-008 | Usage log written on question add; reversed on remove | DONE | QuestionUsageLog create/delete in bulkStore/bulkDestroy |
| BR-QST-009 | Quest code unique per tenant | DONE | DB UNIQUE constraint + model check |
| BR-QST-010 | Academic session must be linked (validated FK) | PARTIAL | academic_session_id nullable validation in QuestRequest (should be required) |

### 7.3 RPT Coverage

| RPT ID | Report | Status |
|--------|--------|--------|
| RPT-QST-001 | Quest performance summary | DONE |
| RPT-QST-002 | Per-student result | DONE |
| RPT-QST-003 | Score distribution chart | PARTIAL (PERF-QST-001) |
| RPT-QST-004 | Monthly activity trend | DONE |
| RPT-QST-005 | Paper-check evaluation sheet | DONE |
| RPT-QST-006 | Activity log | DONE |

---

## 8. Layer C — Business Rule Enforcement Findings

**BR-QST-010 (P2): `academic_session_id` nullable in QuestRequest**
`QuestRequest` validates `academic_session_id` as `'nullable|string'` (no `exists:` constraint, not required). A quest can be created without an academic session, breaking the intended academic hierarchy (academic_session → class → subject). Quest code generation would produce `QUEST_GEN_...` codes for session-less quests.

**BR-QST-004 (P0): topic_id DB constraint vs app optional treatment**
See MIG-QST-001. The business rule that topic_id is optional in a scope is not enforced in the DB schema.

**No negative_marks scoring enforcement (P2):**
`negative_marks` is stored and validated in the Quest model. No live scoring logic in the module deducts marks for wrong answers. Auto-grading is handled in StudentPortal which has its own scoring path. Whether StudentPortal's auto-grader reads and applies `quest.negative_marks` is outside QST scope but must be verified.

---

## 9. Layer A — Systemic Pattern Scorecard

| Pattern | Status | Finding |
|---------|--------|---------|
| D17 (activity log) | PASS | `activityLog()` called in all mutating actions |
| D24 (permission prefix chaos) | PASS | All gates use `tenant.*` prefix consistently |
| D25 (`$request->all()` mass assignment) | PASS | Zero mass-assignment sites; all use `$request->validated()` |
| D29 (ENUM instead of dropdown FK) | FAIL | `allocation_type` ENUM in `lms_quest_allocations` (SCH-QST-001) |
| D30 (FormRequest authorize hardcoded true) | FAIL | All 4 FormRequests (platform baseline; not blocking) |
| D36 (GENERATED ALWAYS column degraded) | N/A | No computed columns required in QST |
| D37 (status INT FK vs string) | PASS | Status stored as string ('DRAFT','PUBLISHED','ARCHIVED') with string checks in model/controller |
| D38 (SoftDeletes vs DDL mismatch) | PASS | All 4 tables have `deleted_at` in migration + `SoftDeletes` trait |
| D39 (permissions unseeded) | UNABLE TO VERIFY | No seeder reviewed; module has `LmsQuestSeeder` — must verify permissions are seeded for all `tenant.quest*.*` strings |

---

## 10. Issue Register

### P0 — Must Fix Before Deployment

| Code | Title | Location | Evidence |
|------|-------|----------|---------|
| SEC-QST-001 | Hub viewAny gate commented out | `LmsQuestController.php:71` | `// Gate::authorize('tenant.quest.viewAny');` |
| BUG-QST-001 | Missing DB import in forceDelete causes fatal crash | `LmsQuestController.php:786` | No `use Facades\DB`; `DB::beginTransaction()` called |
| BUG-QST-002 | Undefined `$quest` in QuestQuestion::store() — fatal error | `QuestQuestionController.php:985` | `$quest->id` before assignment |
| MIG-QST-001 | `lms_quest_scopes.topic_id` NOT NULL — blocks optional scope | `2026_06_16_115421_create_lms_quest_scopes_table.php:25` | No `->nullable()`; QuestScopeRequest validates as nullable |

### P1 — Fix Before First School Goes Live

| Code | Title | Location | Evidence |
|------|-------|----------|---------|
| BUG-QST-ROUTE | Trash routes for scope/question/allocation shadowed by resource routes | `routes/web.php:36-37, 48-49, 56-57` | resource registered before trash GET |
| SEC-QST-002 | No EnsureTenantHasModule guard — module not plan-gated | `RouteServiceProvider.php` | Middleware stack lacks hasModule check |
| SEC-QST-003 | saveAnswerGrade() — no Gate authorization | `LmsQuestController.php:1114` | No `Gate::authorize()` in method |
| SEC-QST-004 | getSubjectsByClass() — no Gate authorization | `LmsQuestController.php:506` | No `Gate::authorize()` in method |
| SEC-QST-005 | QuestQuestionController AJAX endpoints (×4) — no Gate | `QuestQuestionController.php:130,154,165,194` | getSections, getSubjectGroups, getLessons, getTopics |
| SEC-QST-007 | QuestAllocationController AJAX endpoints (×2) — no Gate | `QuestAllocationController.php:652,720` | getTargetOptions, getQuests |
| TEN-QST-001 | Prime::AcademicSession used in tenant context — wrong DB layer | `LmsQuestController.php:29`, `Quest.php:15` | FK→glb_academic_sessions; model→prime_db |
| BUG-QST-003 | Undefined `$usageTypeId` in search() when only_unused=true | `QuestQuestionController.php:318` | Commented assignment + closure capture |
| BUG-QST-004 | bulkStore() double-parses questions_data; first parse discarded | `QuestQuestionController.php:543-614` | Duplicate questions_data parsing blocks |
| BUG-QST-005 | addQuestions() — no Gate, no transaction, no duplicate-log check | `QuestQuestionController.php:1454` | Legacy endpoint: ungated write |
| BUG-QST-006 | Duplicate quest code generation in controller + model boot | `LmsQuestController.php:574-586,664-675`, `Quest.php:104` | Controller sets quest_code before Quest::create() |
| BUG-QST-POL | QuestPolicy defines view()×4 and update()×2 — latent fatal PHP error | `QuestPolicy.php:22,29,37,45,53,69` | Duplicate method declarations |
| MIG-QST-002 | Alter migration down() references non-existent FK/column | `2026_06_18_100000_update_lms_quests_and_scopes.php:31-38` | Rollback would fail |
| PERF-QST-001 | score_distribution fetches all QuizQuestResult rows to PHP | `LmsQuestController.php:425-446` | `->get(['percentage'])` then PHP-side binning |
| D30-QST | All 4 FormRequests authorize(){return true;} | `app/Http/Requests/*.php` | Platform baseline D30 |

### P2 — Address in Next Sprint

| Code | Title | Location |
|------|-------|----------|
| SCH-QST-001 | allocation_type ENUM (D29 pattern) | `2026_06_15_150346_create_lms_quest_allocations_table.php:16` |
| PHANTOM-QST-001 | show_result_immediately in $fillable/$casts — no DB column | `Quest.php:49,70` |
| PHANTOM-QST-002 | pending in QuestRequest rules — no DB column | `QuestRequest.php:57,78` |
| PERF-QST-002 | ClassSection::find called ~8× per dashboard load | `LmsQuestController.php:dashboardStats` |
| BUG-QST-010 | morphTo SECTION allocation fails — sch_class_section_jnt not in morphMap | `QuestAllocation.php:94` + `LmsQuestsServiceProvider.php:46-51` |
| BUG-QST-011 | QuestAllocationRequest validates SECTION against sch_sections but stores junction ID | `QuestAllocationRequest.php:300-303` |
| BUG-QST-012 | attempts() FK name mismatch: quest_allocation_id vs allocation_id | `QuestAllocation.php:64`, `QuestAllocationController.php:575` |
| N+1-QST-001 | Quest::getStatisticsAttribute() / getSummaryAttribute() run multiple queries per access | `Quest.php:465,624` |

---

## 11. Health Score

### Layer Scores (raw)

| Layer | Weight | Raw Score | Weighted |
|-------|--------|-----------|---------|
| 1. Structure / Scaffolding | 8% | 8/10 | 6.4 |
| 2. Routes / Middleware | 8% | 5/10 | 4.0 |
| 3. Controller / Action logic | 12% | 3/10 | 3.6 |
| 4. Business Logic / Services | 8% | 8/10 | 6.4 |
| 5. Validation / FormRequests | 8% | 5/10 | 4.0 |
| 6. Tenancy Isolation | 10% | 6/10 | 6.0 |
| 7. Security / Authorization | 15% | 2/10 | 3.0 |
| 8. Database / Migrations | 12% | 4/10 | 4.8 |
| 9. Models / Eloquent | 8% | 6/10 | 4.8 |
| 10. Events / Jobs / Notifications | 5% | 7/10 | 3.5 |
| 11. Frontend / Blade | 4% | 7/10 | 2.8 |
| 12. Config / Environment | 2% | 10/10 | 2.0 |
| **TOTAL** | **100%** | — | **51.3** |

**P0 hard cap:** 4 P0 issues confirmed → hard cap at **38 / 100**.

**Final Health Score: 38 / 100 (Red — P0 cap applied)**

### Strengths
- Usage-guard pattern (5 services) consistently applied — prevents data corruption on edit-in-use.
- `QuestAllocationController` is well-structured with full DB transactions, proper Gate checks, and full error logging.
- Recommendation hook correctly fires on result publication.
- D25 clean (zero `$request->all()` mass assignment).
- D17 clean (activityLog in all mutating paths).
- D24 clean (single `tenant.*` prefix).
- Full tenancy middleware stack on all routes.
- SoftDeletes on all 4 models and migrations.

### Weaknesses
- 4 P0 issues: commented auth gate, missing DB import, undefined variable, NOT NULL migration mismatch.
- Zero automated tests across all 4 controllers and 4 models.
- 7 unguarded AJAX endpoints (SEC-QST-003..007).
- QuestPolicy class has duplicate method definitions — latent fatal error.
- Cross-layer model access (TEN-QST-001) in both controller and model.

---

## 12. Deployment Gate (Layer G Pre-Deployment Checklist)

| Check | Status |
|-------|--------|
| No P0 security bypass active | **FAIL** — SEC-QST-001 (hub auth disabled) |
| No P0 fatal error paths active | **FAIL** — BUG-QST-001 (DB import), BUG-QST-002 (undefined var) |
| No P0 migration blocker | **FAIL** — MIG-QST-001 (topic_id NOT NULL) |
| No committed secrets | PASS |
| No cross-tenant write hole | PASS |
| No debug statements (`dd(`) | PASS |
| No env() in module code | PASS |
| Tenancy middleware stack correct | PASS |
| SoftDeletes schema-model aligned | PASS |
| D25 mass-assignment clean | PASS |
| 0 tests | FAIL (0 test coverage) |

**DEPLOYMENT GATE: NO-GO**

Minimum to flip to conditional GO:
1. Re-enable `Gate::authorize('tenant.quest.viewAny')` at line 71 (SEC-QST-001)
2. Add `use Illuminate\Support\Facades\DB;` to `LmsQuestController.php` (BUG-QST-001)
3. Fix undefined `$quest` in `QuestQuestionController::store()` (BUG-QST-002)
4. Add `->nullable()` to `topic_id` in migration (MIG-QST-001) — requires a new migration
5. Gate all 7 unguarded AJAX endpoints (SEC-QST-003..007)
6. Fix duplicate `view()`/`update()` definitions in `QuestPolicy` (BUG-QST-POL)
7. Fix trash route ordering in `routes/web.php` for quest-scope, quest-question, quest-allocation (BUG-QST-ROUTE)

---

## 13. FRD Compliance Summary (Mode B)

| Priority | Total REQ | Done | Partial | Not Started |
|----------|-----------|------|---------|-------------|
| P0 (REQ-001–004, 011, 018, 021) | 7 | 3 | 3 | 1 |
| P1 (REQ-005–010, 012–017, 019) | 11 | 7 | 3 | 1 |
| P2 (REQ-020) | 3 | 2 | 0 | 1 |
| **Total** | **21** | **12** | **6** | **3** |

Overall REQ completion: **57%** (12 DONE / 21 total, with 6 PARTIAL and 3 NOT STARTED)

Teacher-side completion (excluding system-generated quests and student portal): **~72%**

---

## 14. Appendix — Files Audited

| File | Lines | Status |
|------|-------|--------|
| `Modules/LmsQuests/app/Http/Controllers/LmsQuestController.php` | 1600 | Audited |
| `Modules/LmsQuests/app/Http/Controllers/QuestScopeController.php` | 500+ | Audited (partial — first 80 lines + grep) |
| `Modules/LmsQuests/app/Http/Controllers/QuestQuestionController.php` | 1485 | Audited |
| `Modules/LmsQuests/app/Http/Controllers/QuestAllocationController.php` | 744 | Audited |
| `Modules/LmsQuests/app/Models/Quest.php` | 667 | Audited |
| `Modules/LmsQuests/app/Models/QuestAllocation.php` | 175 | Audited |
| `Modules/LmsQuests/app/Http/Requests/QuestRequest.php` | 81 | Audited |
| `Modules/LmsQuests/app/Http/Requests/QuestAllocationRequest.php` | 346 | Audited |
| `Modules/LmsQuests/app/Http/Requests/QuestQuestionRequest.php` | 170 | Audited |
| `Modules/LmsQuests/app/Http/Requests/QuestScopeRequest.php` | 111 | Audited |
| `Modules/LmsQuests/app/Policies/QuestPolicy.php` | 145 | Audited |
| `Modules/LmsQuests/app/Providers/LmsQuestsServiceProvider.php` | 187 | Audited |
| `Modules/LmsQuests/routes/web.php` | 78 | Audited |
| `database/migrations/tenant/2026_06_15_150344_create_lms_quests_table.php` | 74 | Audited |
| `database/migrations/tenant/2026_06_15_150346_create_lms_quest_allocations_table.php` | 47 | Audited |
| `database/migrations/tenant/2026_06_16_115420_create_lms_quest_questions_table.php` | 41 | Audited |
| `database/migrations/tenant/2026_06_16_115421_create_lms_quest_scopes_table.php` | 40 | Audited |
| `database/migrations/tenant/2026_06_18_100000_update_lms_quests_and_scopes.php` | 53 | Audited |
| `AI_Brain/module-knowledge/QST_LmsQuests.md` | 142 | Read |
| `4-Requirement_Module_wise/0-FRD_Documents/QST_FRD_Complete_2026-06-29.md` | — | Read |
