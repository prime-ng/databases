# Technical Audit Report — Recommendation Module (REC)
## Mode X: Complete 12-Layer Audit (A + B + C + G + Scoped D)

**Date:** 2026-06-30
**Auditor Agent:** pa-technical-auditor
**Module:** Recommendation (REC)
**Scope:** Tenant (80-95% complete)
**Table Prefix:** `rec_*`
**Laravel Path:** `/Users/bkwork/Herd/prime_ai/Modules/Recommendation/`
**DDL Source:** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/2-DDL_Tenant_Consolidated/Recommendation_DDL_v1.6.sql`
**FRD:** NOT FOUND at `0-FRD_Documents/REC_FRD_2026-06-30.md` — Mode B and Mode C are SKIPPED

---

## 1. Executive Summary

The Recommendation module implements an AI/rule-based academic recommendation engine for K-12 students. The engine matches quiz/assessment results against configured rules and dispatches personalised content recommendations (videos, PDFs, quizzes, bundles). It is approximately 60-65% complete against the V2 requirements document.

**The module CANNOT be deployed to production in its current state.**

Three P0 blockers exist simultaneously:

1. `RecommendationController::tabIndex()` and `tabIndex_2()` — the primary management screens — are completely ungated. Any authenticated tenant user can access them.
2. `StudentRecommendationController` uses `tenant.student-recommendation.create` permission for all 10 write methods including permanent-delete, meaning any user with create permission can permanently destroy recommendation records.
3. `StudentRecommendation::create()` — called by the recommendation engine on every result-publish event — fails at runtime with `SQLSTATE[42S22]: Column not found: 'rec_student_recommendations.created_at'` because the migration uses a custom `assigned_at` timestamp but the model leaves Eloquent's default `$timestamps = true`, causing Eloquent to write `created_at` to a column that does not exist.

In addition, no REC permissions are seeded in any seeder file, meaning FormRequest authorization returns false for all non-super-admin users in a fresh tenant — effectively locking every CRUD screen.

### Deploy Verdict

**NO-GO** — 4 P0 blockers, 8 P1 blockers

### Health Score

| Layer | Weight | Grade | Weighted |
|-------|--------|-------|----------|
| 6 — Tenancy Isolation | 15 | B (RSP correct, no leak; EnsureTenantHasModule missing) | 10 |
| 5 — Authorization / Policy | 14 | F (P0: gate bypass, wrong permissions, no seeder) | 0 |
| 8 — Data Integrity / Transactions | 13 | F (P0: create() fails at runtime; media_id type collision) | 0 |
| 7 — Validation / Mass-Assignment | 11 | C (all FormRequests have real authorize(); double-validation; D39 unseed) | 6 |
| 12 — Deployment | 10 | C (env() outside config in 2 files; exception messages exposed to users) | 5 |
| 2 — Migration / Model / DDL Consistency | 9 | F (3 D17 gaps: triggered_by_result_id, is_published, difficulty_band) | 0 |
| 1 — DDL Schema Integrity | 7 | C (wrong index column names, FK constraint column mismatch, ENUM x2) | 4 |
| 9 — Performance | 7 | C (unbounded Student::get() in 4 methods; synchronous engine listener) | 4 |
| 10 — Queue / Job | 6 | C (listener synchronous, no ExpireCommand) | 3 |
| 4 — Code Quality | 4 | C (dead import, commented dd(), double-validation in 5 controllers) | 2 |
| 3 — ORM Models | 2 | F (created_at cast on non-existent column; media_id array cast on INT) | 0 |
| 11 — Frontend / Blade | 2 | C (7 unescaped {!! !!} on description/content_text fields) | 1 |
| **TOTAL** | **100** | | **35 / 100** |

P0 cap: health capped at 40 when any P0 is open. Raw score 35 sits below the cap.

---

## 2. FRD Availability Notice

The BA FRD file `REC_FRD_2026-06-30.md` does NOT exist at the expected path:
`/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/REC_FRD_2026-06-30.md`

The module-knowledge file (`REC_Recommendation.md`) states "FRD Status: Generated 2026-06-30" but the file was not committed or was generated to a different path. The module-knowledge document itself (which contains BA-level gap analysis) is used as the reference baseline for this audit.

**Consequence:** Mode B (Gap Analysis) and Mode C (Business Rule Enforcement) are skipped in this report. Sections 6 and 7 note the skips explicitly.

---

## 3. Mode A — Schema Audit

### Layer 1: DDL Schema Integrity

**Source:** `Recommendation_DDL_v1.6.sql` (header reads v1.4 — version inconsistency P3)

#### DDL-REC-001 (P2): Wrong column in `idx_recRule_trigger` index

```sql
-- DDL line 216
KEY idx_recRule_trigger (trigger_event)
```

The column is named `trigger_event_id`, not `trigger_event`. This index definition references a non-existent column. MySQL would reject this DDL as written. The migration correctly uses `trigger_event_id`.

**File:** `Recommendation_DDL_v1.6.sql` line 216
**Fix:** Change index to `KEY idx_recRule_trigger (trigger_event_id)`

#### DDL-REC-002 (P2): Wrong column in `fk_recMat_competency` FK constraint

```sql
-- DDL lines ~145
CONSTRAINT fk_recMat_competency FOREIGN KEY (competency_code) REFERENCES slb_competency_types (id)
```

The column is `competency_id`, not `competency_code`. The DDL FK definition is invalid as written. The migration handles this correctly.

**Fix:** Change to `FOREIGN KEY (competency_id)`

#### DDL-REC-003 (P2): `class_id / subject_id / topic_id` nullability contradiction

DDL marks these `INT UNSIGNED DEFAULT NOT NULL` (invalid MySQL syntax and wrong constraint). The migration correctly makes them `nullable()`. The DDL must be corrected to reflect the actual schema.

#### DDL-REC-004 (P2): ENUM columns on `rec_student_recommendations`

DDL defines:
- `priority ENUM('LOW','MEDIUM','HIGH','CRITICAL')`
- `status ENUM('CANCELLED','COMPLETED','EXPIRED','IN_PROGRESS','PENDING','SKIPPED','VIEWED')`

This violates **D29** (no ENUM — use `sys_dropdown_table` FKs). The migration also uses `->enum()` — both DDL and migration are D29-non-compliant. Changing ENUMs on a high-volume table is costly once data exists.

#### DDL-REC-005 (P2): `media_id` declared as `INT UNSIGNED FK` but used as JSON

DDL: `media_id INT UNSIGNED FK → qns_media_store(id)`
Migration: `$table->unsignedInteger('media_id')->nullable()` with the same FK
Model cast: `'media_id' => 'array'`
Controller stores: an array of file-metadata objects

The column type is semantically incompatible with its use. See **BUG-REC-004** for the runtime impact.

---

### Layer 2: Migration ↔ Model ↔ DDL Three-Way Consistency

#### rec_student_recommendations

| Column | DDL | Migration | Model `$fillable` | Model `$casts` | Impact |
|--------|-----|-----------|-------------------|----------------|--------|
| `triggered_by_result_id` | Commented out | ABSENT | PRESENT | — | BUG-REC-001: silently dropped on insert |
| `is_published` | ABSENT | ABSENT | PRESENT | `boolean` | BUG-REC-002: silently dropped on insert |
| `created_at` | ABSENT | ABSENT | — | `datetime` | BUG-REC-003: Eloquent writes to non-existent column → fatal |
| `assigned_at` | PRESENT | PRESENT | PRESENT | — | Custom creation timestamp, not wired as CREATED_AT alias |
| `priority` | ENUM | `->enum()` | PRESENT | — | DDL-REC-004: D29 violation |
| `status` | ENUM | `->enum()` | PRESENT | — | DDL-REC-004: D29 violation |

#### rec_recommendation_rules

| Column | Migration | Model `$fillable` | Service reads | Impact |
|--------|-----------|-------------------|---------------|--------|
| `difficulty_band` | ABSENT | PRESENT | `$rule->difficulty_band` | MIG-REC-001: difficulty filtering always null = silently disabled |
| `section_id` | ABSENT | PRESENT | — | D17: saved data silently dropped |
| `created_by` | ABSENT | ABSENT | — | Audit trail gap |

#### rec_recommendation_materials

| Column | Migration Type | Model Cast | Controller stores | Impact |
|--------|---------------|------------|-------------------|--------|
| `media_id` | `unsignedInteger` FK | `'array'` | array of file objects | BUG-REC-004: type collision |

#### rec_material_bundles

| Column | Migration | Model | Controller | Impact |
|--------|-----------|-------|------------|--------|
| `school_id` | ABSENT | `BelongsTo Organization` | eager-loaded in show() | BUG-REC-005: FK always null; show() view blank |

---

### Layer 3: Eloquent ORM Models

#### BUG-REC-003 (P0): Eloquent default timestamps write `created_at` to non-existent column

**File:** `Modules/Recommendation/app/Models/StudentRecommendation.php`

The model does not override `$timestamps = false` or set `const CREATED_AT = 'assigned_at'`. Eloquent's default behaviour inserts both `created_at` and `updated_at` on every `create()` call. The migration has `updated_at` (manually defined) but NO `created_at` column.

Every call to `StudentRecommendation::create([...])` — including from the engine service — throws:

```
SQLSTATE[42S22]: Column not found: 1054 Unknown column 'rec_student_recommendations.created_at'
```

This means the entire recommendation engine is non-functional: every quiz result publish that matches a rule creates a failed DB query and the transaction rolls back silently (or the listener catch block suppresses it with a log).

**Fix (migration):**
```php
// 2026_06_XX_add_created_at_to_rec_student_recommendations.php
$table->timestamp('created_at')->useCurrent()->after('assigned_at');
```

**Alternative fix (model):**
```php
const CREATED_AT = 'assigned_at';
```

#### BUG-REC-004 (P1): `media_id` INT column used as JSON attachment store

**File:** `Modules/Recommendation/app/Models/RecommendationMaterial.php` line 38

```php
'media_id' => 'array',  // cast says array
```

**File:** `Modules/Recommendation/app/Http/Controllers/RecommendationMaterialController.php` line 138

```php
RecommendationMaterial::create(['media_id' => $attachments])  // $attachments is array of file objects
```

Eloquent JSON-encodes the array to a string (e.g. `[{"file_name":"algebra.pdf",...}]`). MySQL receives this string for an `unsignedInteger` column with a FK constraint to `qns_media_store`. In strict mode: error 1366 (Incorrect integer value). Without strict mode: value coerced to 0, FK constraint fails. All file attachment saves are broken.

**Fix:** Change migration column to `json` or `longText`, remove FK constraint, add `->nullable()`.

#### ORM-REC-001 (P1): TriggerEventPolicy not registered in ServiceProvider

**File:** `Modules/Recommendation/app/Providers/RecommendationServiceProvider.php`

`registerPolicies()` registers 7 policies. `TriggerEventPolicy.php` exists in the Policies directory but is NOT in the registration list. `RecAssessmentTypePolicy.php` does not exist (see GAP-REC-001).

Any `Gate::authorize()` calls in `RecTriggerEventController` that rely on a model policy will resolve to deny for non-super-admin users.

**Fix:** Add to `registerPolicies()`:
```php
RecTriggerEvent::class => TriggerEventPolicy::class,
```
Create `RecAssessmentTypePolicy.php` and register it.

#### ORM-REC-002 (P2): `MaterialBundle::school()` relationship uses non-existent FK

**File:** `Modules/Recommendation/app/Models/MaterialBundle.php`

```php
public function school(): BelongsTo
{
    return $this->belongsTo(Organization::class, 'school_id');
}
```

`rec_material_bundles` has no `school_id` column (confirmed in migration). `MaterialBundleController::show()` calls `$bundle->load(['school', ...])`. The resulting SQL `WHERE school_id IS NULL` returns null silently. The show view renders without school information. No crash, but data is permanently unavailable without a schema fix.

**File:** `Modules/Recommendation/app/Http/Controllers/MaterialBundleController.php` line 98-104

**Fix:** Add migration `$table->unsignedInteger('school_id')->nullable()` + FK to `sch_schools(id)`.

---

### Layer 4: Data Integrity and Transactions

#### DAT-REC-001 (P1): Engine idempotency check is software-level only

**File:** `Modules/Recommendation/app/Services/RecommendationEngineService.php`

```php
$exists = StudentRecommendation::where('student_id', $studentId)
    ->where('rule_id', $rule->id)
    ->where('triggered_by_quiz_id', $quizId)
    ->where('triggered_by_quest_id', $questId)
    ->exists();
```

No unique constraint in the migration covers this 4-column combination. Under concurrent result-publish events (e.g., two HTTP requests publishing the same result at near-simultaneous times), both can pass the `exists()` check before either completes the insert, producing duplicate recommendations.

**Fix:** Add a migration:
```php
$table->unique(['student_id', 'rule_id', 'triggered_by_quiz_id', 'triggered_by_quest_id'], 'uq_rec_student_idempotency');
```

Wrap insert in `insertOrIgnore()` or catch `QueryException` with duplicate key error code.

#### DAT-REC-002 (P1): `difficulty_band` engine filter silently disabled

**File:** `Modules/Recommendation/app/Services/RecommendationEngineService.php` line 117

```php
if ($rule->difficulty_band && $rule->difficulty_band !== $currentDifficultyBand) {
    continue; // skip rule
}
```

`$rule->difficulty_band` is always `null` because the column does not exist in the migration (see MIG-REC-001). The null check `if ($rule->difficulty_band && ...)` evaluates to `false`, so the skip is never executed. Every rule matches every difficulty band regardless of configuration — difficulty-band-specific rules fire for all students regardless of their performance tier.

---

## 4. Mode G — Security Audit

### Layer 5: Authorization and Policy

#### SEC-REC-001 (P0): Gate::any() return value discarded — tabIndex screens completely ungated

**File:** `Modules/Recommendation/app/Http/Controllers/RecommendationController.php`

```php
// tabIndex() — line 28-34
Gate::any([
    'tenant.recommendation-rule.viewAny',
    'tenant.recommendation-material.viewAny',
    'tenant.student-recommendation.viewAny',
]);
// no abort_unless(), no if check — return value discarded
```

Same pattern at line 164-170 in `tabIndex_2()`.

`Gate::any()` returns a boolean. The returned value is not checked. Any authenticated tenant user accessing `/recommendation-mgt` or `/rec-material` gets full page access regardless of permissions.

**Fix:**
```php
abort_unless(
    Gate::any(['tenant.recommendation-rule.viewAny', 'tenant.recommendation-material.viewAny', 'tenant.student-recommendation.viewAny']),
    403
);
```

#### SEC-REC-002 (P0): StudentRecommendationController — 10 methods use `.create` permission for all operations including permanent delete

**File:** `Modules/Recommendation/app/Http/Controllers/StudentRecommendationController.php`

Methods using `Gate::authorize('tenant.student-recommendation.create')`:
- `show()` (L111) — should use `.view`
- `edit()` (L130) — should use `.update`
- `update()` (L155) — should use `.update`
- `destroy()` (L214) — should use `.delete`
- `trashed()` (L230) — should use `.viewTrashed`
- `restore()` (L244) — should use `.restore`
- `forceDelete()` (L259) — should use `.forceDelete`
- `markAsCompleted()` (L280) — should use `.update`
- `updateStatus()` (L296) — should use `.update`
- `addRating()` (L343) — should use `.update`

A user with only `create` permission can permanently delete any student recommendation record. The `StudentRecommendationPolicy` correctly defines all abilities (`.delete`, `.restore`, `.forceDelete`) — they are just never called.

**Fix:** Replace `Gate::authorize('tenant.student-recommendation.create')` with the correct ability name in each method, matching the policy definitions in `StudentRecommendationPolicy.php`.

#### SEC-REC-003 (P1): EnsureTenantHasModule:REC not applied

**File:** `Modules/Recommendation/app/Providers/RouteServiceProvider.php`

The web middleware group applies: `web, InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive, auth, verified`. The `EnsureTenantHasModule:REC` middleware is absent.

Schools that have not purchased or been assigned the Recommendation module can freely browse all recommendation routes. The route file has no per-route module check either.

**Fix:** Add to the web route group in `RouteServiceProvider::mapWebRoutes()`:
```php
->middleware(['web', 'InitializeTenancyByDomain', ..., 'EnsureTenantHasModule:REC'])
```

#### D39-REC-001 (P1): No REC permissions seeded anywhere

**Pattern:** D39

`RecommendationSeeder.php` and `RecommendationDatabaseSeeder.php` seed lookup data (materials, bundles, rules, demo student recommendations) but contain no `Permission::create()` or equivalent calls. No central `TenantRolePermissionSeeder` file references any `tenant.recommendation.*` permission string.

Consequence: In a fresh tenant, all 18 FormRequests return 403 because `$this->user()->can('tenant.recommendation-material.create')` resolves to false. All CRUD is locked for non-super-admin users.

**Permissions that need seeding (minimum viable set):**

| Permission String | Method |
|---|---|
| `tenant.recommendation-rule.viewAny` | index |
| `tenant.recommendation-rule.create` | create/store |
| `tenant.recommendation-rule.update` | edit/update |
| `tenant.recommendation-rule.delete` | destroy |
| `tenant.recommendation-material.viewAny` | index |
| `tenant.recommendation-material.create` | create/store |
| `tenant.recommendation-material.update` | edit/update |
| `tenant.recommendation-material.delete` | destroy |
| `tenant.student-recommendation.viewAny` | index |
| `tenant.student-recommendation.view` | show |
| `tenant.student-recommendation.create` | create/store |
| `tenant.student-recommendation.update` | edit/update |
| `tenant.student-recommendation.delete` | destroy |
| `tenant.student-recommendation.restore` | restore |
| `tenant.recommendation.forceDelete` | forceDelete |
| `tenant.material-bundle.viewAny` | index |
| `tenant.material-bundle.create` | create/store |
| `tenant.material-bundle.update` | edit/update |
| `tenant.material-bundle.delete` | destroy |
| `tenant.recommendation-mode.create` | create/store |
| `tenant.recommendation-mode.update` | edit/update |
| `tenant.dynamic-material-type.create` | create/store |
| `tenant.dynamic-material-type.update` | edit/update |
| `tenant.dynamic-purpose.create` | create/store |
| `tenant.dynamic-purpose.update` | edit/update |
| `tenant.assessment-type.viewAny` | index |
| `tenant.assessment-type.create` | create/store |
| `tenant.assessment-type.update` | edit/update |
| `tenant.assessment-type.delete` | destroy |
| `tenant.assessment-type.restore` | restore |
| `tenant.assessment-type.forceDelete` | forceDelete |
| `tenant.recommendation-trigger-event.create` | create/store |
| `tenant.recommendation-trigger-event.update` | edit/update |
| `tenant.trigger-events.viewAny` | viewAny (inconsistent naming — see GAP-REC-005) |

**Fix:** Create `Modules/Recommendation/database/seeders/RolePermissionSeeder.php` and call it from `RecommendationDatabaseSeeder::run()`. Assign appropriate permissions to Teacher, Admin, and Super Admin roles.

---

### Layer 6: Multi-Tenancy

**PASS — Tenancy middleware is correctly applied.**

`RouteServiceProvider::mapWebRoutes()` applies the full tenancy stack. No bare `tenant_id` column needed (database-per-tenant). No `InitializeTenancyByDomain` calls in controllers (correctly handled by middleware). No cross-tenant data leakage patterns found.

**CONCERN:** `RouteServiceProvider::mapApiRoutes()` applies only `'api'` middleware — no tenancy middleware. The module has no `/api.php` routes as of audit date. If API routes are added (see GAP-REC-008), they must include the full tenancy stack.

**MINOR RISK:** `GenerateRecommendationsListener` runs synchronously (not `ShouldQueue`). If this event is ever dispatched from a queued job (future scope), tenancy will not be initialized in that job context. See PERF-REC-001 for the performance aspect.

---

### Layer 11: Frontend / Blade

#### XSS-REC-001 (P2): Seven unescaped `{!! !!}` outputs on user-controlled fields

| File | Line | Field |
|------|------|-------|
| `views/dynamic-purposes/show.blade.php` | 40 | `$purpose->description` |
| `views/recommendation-modes/show.blade.php` | 40 | `$mode->description` |
| `views/material-bundles/show.blade.php` | 42 | `$bundle->description` |
| `views/assessment-types/show.blade.php` | 40 | `$type->description` |
| `views/dynamic-material-type/show.blade.php` | 40 | `$type->description` |
| `views/recommendation-materials/show.blade.php` | 132 | `$material->description` |
| `views/recommendation-materials/show.blade.php` | 137 | `$material->content_text` |

The `description` and `content_text` fields are admin-entered free-text. A malicious admin can inject `<script>` tags that execute in other admin users' browsers when they view the show page. In a multi-school SaaS context this is Stored XSS — severity P2 (requires admin-role to create, but affects all admin-role viewers).

The use of `{!! !!}` is deliberate to support formatted descriptions (HTML). If rich-text HTML is a product requirement, use a server-side sanitizer (HTMLPurifier or equivalent) before saving. If plain text is sufficient, replace with `{{ }}`.

**Fix:** Either sanitize on save via `strip_tags()` / HTMLPurifier, or replace `{!! !!}` with `{{ }}` if rich-text formatting is not a requirement.

---

## 5. Mode D (Scoped) — Systemic Pattern Violations

### D17: Fillable-vs-Columns Mismatch

| Model | Column in `$fillable` | In Migration | Impact |
|-------|-----------------------|--------------|--------|
| `StudentRecommendation` | `triggered_by_result_id` | ABSENT | Engine audit trail silently lost |
| `StudentRecommendation` | `is_published` | ABSENT | Engine flag silently dropped |
| `RecommendationRule` | `difficulty_band` | ABSENT | Difficulty band filtering disabled |
| `RecommendationRule` | `section_id` | ABSENT | Section-scoping on rules silently dropped |

**Resolution:** Add all four columns via a new migration. The columns are used in validated FormRequest rules and in service logic — they were clearly intended to exist.

#### MIG-REC-001 (P1): `difficulty_band` absent from rec_recommendation_rules migration

**File:** `database/migrations/tenant/2026_06_16_130100_create_rec_recommendation_rules_table.php`

The column is validated in `StoreRecommendationRuleRequest::rules()`:
```php
'difficulty_band' => ['nullable', 'in:EASY,MODERATE,HARD'],
```

The model includes it in `$fillable`. The engine reads it at `RecommendationEngineService.php:117`. But the column does not exist in the migration. Every value stored is silently discarded. Every engine filter on this column is silently skipped (see DAT-REC-002).

**Fix:** Add to migration:
```php
$table->enum('difficulty_band', ['EASY', 'MODERATE', 'HARD'])->nullable()->after('max_score_pct');
```
(Or use `sys_dropdown_table` FK per D29 — preferred.)

### D25: $request->all() Mass-Assignment

**PASS (partial):** No `Model::create($request->all())` found. The double-validation pattern in 5 controllers passes `$request->all()` to `Validator::make()` (not to the model). The model creates use explicitly mapped arrays. No D25 violation found.

### D29: ENUM vs sys_dropdown_table

`rec_student_recommendations`: `priority` and `status` are ENUM both in the DDL and migration. D29 violation. These are already seeded lookup values; refactoring to a `sys_dropdowns` FK would add a join on every query to the highest-volume table in the module. Given the table is not yet in production, this should be resolved before first data is inserted.

**Violations:** `priority` ENUM (4 values), `status` ENUM (7 values).

### D30: FormRequest authorize() returns true

**PASS — module is above platform norm.** All 18 FormRequests use real `$this->user()?->can(...)` checks. No bare `return true` found.

### D31: qns_question_statistics Formula Contract

**PASS.** `RecommendationEngineService::loadWrongAnswerStats()` correctly implements the D31 formula:
```php
LEFT JOIN qns_question_statistics qs ON qa.question_id = qs.question_id
```
Difficulty index ranges (EASY ≥70%, MODERATE 30-69%, HARD <30%) are applied correctly. Mis-keyed questions (`discrimination_index < 0`) are skipped. Default MEDIUM priority is used when statistics are absent. No D31 violation.

### D36: Generated Columns Pattern

**NOT APPLICABLE.** No generated columns exist in REC DDL or migrations.

### D38: SoftDeletes / Timestamps vs DDL

`rec_student_recommendations`: SoftDeletes is enabled (`use SoftDeletes`). The `deleted_at` column was added via `2026_06_18_000010_add_deleted_at_to_rec_student_recommendations.php`. This is **correct**.

`created_at` VIOLATION: Model declares default `$timestamps = true` but no `created_at` column exists in the migration. See BUG-REC-003. The migration uses `assigned_at` as the creation timestamp but does not alias it via `const CREATED_AT`.

### D39: Unseeded Permissions

Confirmed at D39-REC-001. No permission seeder exists in this module or in central seeders for any `tenant.recommendation.*` ability string.

---

## 6. Mode B — Gap Analysis

**SKIPPED: FRD not found.**

Gaps identified from module-knowledge cross-reference against live code:

| ID | Gap | Priority |
|----|-----|----------|
| GAP-REC-001 | `RecAssessmentTypePolicy` does not exist; `TriggerEventPolicy` exists but not registered | P1 |
| GAP-REC-002 | No `ExpireRecommendationsCommand` — overdue recommendations never auto-expired | P1 |
| GAP-REC-003 | No status transition FSM — arbitrary status transitions allowed (COMPLETED → PENDING) | P1 |
| GAP-REC-004 | `rec_material_bundles.school_id` column missing from migration | P1 |
| GAP-REC-005 | Permission naming inconsistency: `tenant.trigger-events.viewAny` (plural, in RecommendationController) vs `tenant.recommendation-trigger-event.*` (FormRequests) | P2 |
| GAP-REC-006 | INVALIDATED: `RecommendationMaterialController::create()` L41 and `edit()` L201 DO have `Gate::authorize()` calls. Module-knowledge listed this as a gap — false positive. | CLOSED |
| GAP-REC-007 | No analytics dashboard — `RecommendationAnalyticsController` not built; FR-REC-18 unimplemented | P2 |
| GAP-REC-008 | No Student Portal API endpoints for recommendations | P2 |

---

## 7. Mode C — Business Rule Enforcement

**SKIPPED: FRD not found.**

---

## 8. Code Quality and Performance

### Layer 4: Code Quality

#### VAL-REC-001 (P2): Double-validation anti-pattern in 5 controllers

Five controllers inject a typed FormRequest (which already validates and authorizes) and then immediately re-validate the same data with `$request->validate([...])` or `Validator::make($request->all(), [...])`:

| Controller | FormRequest injected | Secondary validation |
|------------|---------------------|---------------------|
| `StudentRecommendationController::store()` | `StoreStudentRecommendationRequest` | `$request->validate([...])` with different rules |
| `StudentRecommendationController::update()` | `UpdateStudentRecommendationRequest` | `$request->validate([...])` |
| `RecommendationRuleController::store()` | `StoreRecommendationRuleRequest` | `Validator::make($request->all(), [...])` |
| `RecommendationRuleController::update()` | `UpdateRecommendationRuleRequest` | `Validator::make($request->all(), [...])` |
| `RecommendationMaterialController::store()` | `StoreRecommendationMaterialRequest` | `Validator::make($request->all(), [...])` |

In `StudentRecommendationController::store()`, the FormRequest requires `'status' => 'sometimes'` while the inline `validate()` requires `'status' => 'required|in:...'`. These conflict. If `status` is absent from the request, the FormRequest passes but the inline validation fails.

**Fix:** Remove all secondary `$request->validate()` / `Validator::make()` calls. Move any missing rules into the corresponding FormRequest.

#### VAL-REC-002 (P2): `is_automated` boolean overridden with raw request check

**File:** `Modules/Recommendation/app/Http/Controllers/RecommendationRuleController.php` lines 185-186

```php
$validated['is_automated'] = $request->has('is_automated');
```

The FormRequest already validates and casts `is_automated` as a boolean. The controller then discards the validated value and re-reads the raw checkbox presence via `$request->has()`. This bypasses the validation layer. For a checkbox that is absent when unchecked, `$request->has()` correctly returns false, but using the raw request after validation defeats the purpose of FormRequest.

**Fix:** Remove the override. Trust the validated boolean from `$validated['is_automated']`.

#### DEAD-REC-001 (P3): Dead import in MaterialBundleController

**File:** `Modules/Recommendation/app/Http/Controllers/MaterialBundleController.php` line 14

```php
use Modules\Recommendation\Models\BundleMaterialJunction;
```

The actual model class is `BundleMaterialJnt` (in `BundleMaterialJnt.php`). `BundleMaterialJunction` does not exist. The import is never instantiated in any method (junction operations use `$bundle->materials()->sync/attach`), so PHP's lazy autoloader never throws. Remove the dead import.

#### DEAD-REC-002 (P3): Commented-out dd() in production code

**File:** `Modules/Recommendation/app/Http/Controllers/RecommendationRuleController.php` line 61

```php
// dd($request->all());
```

Remove before merge.

#### DEPLOY-REC-001 (P1): env() called outside config — breaks after config:cache

**Files and lines:**

| File | Line | Call |
|------|------|------|
| `app/Models/RecommendationMaterial.php` | 144 | `env('LMS_DISK', 'public')` |
| `app/Http/Controllers/RecommendationMaterialController.php` | 125 | `env('LMS_DISK', 'public')` |
| `app/Http/Controllers/RecommendationMaterialController.php` | 289 | `env('LMS_DISK', 'public')` |
| `app/Http/Controllers/RecommendationMaterialController.php` | 301 | `env('LMS_DISK', 'public')` |

After `php artisan config:cache`, `env()` returns `null`. `Storage::disk(null)` uses the default disk, which may not be `LMS_DISK`. All file upload and download operations silently break in production after config caching.

**Fix:** Add to `config/filesystems.php` (or a module config):
```php
'lms_disk' => env('LMS_DISK', 'public'),
```
Then replace all occurrences with `config('filesystems.lms_disk')`.

#### DEPLOY-REC-002 (P2): Exception messages exposed to users

**File:** `Modules/Recommendation/app/Http/Controllers/RecommendationMaterialController.php` (store, update methods)

```php
return redirect()->back()->with('error', 'Failed to create recommendation material: ' . $e->getMessage());
```

Exception messages may contain SQL queries, table names, file system paths, or stack trace fragments. Log the exception instead; show a generic message to the user.

**Fix:**
```php
Log::error('RecommendationMaterial store failed', ['exception' => $e]);
return redirect()->back()->with('error', 'Failed to save material. Please try again.');
```

---

### Layer 9: Performance

#### PERF-REC-001 (P1): Unbounded Student::get() in 4 controller methods

**Files:**

| Controller | Method | Line | Query |
|------------|--------|------|-------|
| `RecommendationController` | `tabIndex()` | ~109 | `Student::where('is_active', true)->orderBy('first_name')->get()` |
| `RecommendationController` | `tabIndex_2()` | ~247 | `Student::where('is_active', true)->orderBy('first_name')->get()` |
| `StudentRecommendationController` | `create()` | ~64 | `Student::where('is_active', true)->get()` |
| `StudentRecommendationController` | `edit()` | ~130 | `Student::where('is_active', true)->get()` |

For schools with 1000-3000 active students, each page load fetches all students into PHP memory. The students are used to populate a dropdown selector. Replace with Select2/AJAX endpoint or `->paginate()`.

#### PERF-REC-002 (P1): Synchronous engine listener blocks HTTP response

**File:** `Modules/Recommendation/app/Listeners/GenerateRecommendationsListener.php`

The listener does NOT implement `ShouldQueue`. When a quiz result is published, `RecommendationEngineService::processResult()` runs inline in the same HTTP request:
- Loads all active rules for the trigger event (DB query)
- For each matching rule: queries wrong-answer stats, computes priority, checks idempotency, inserts a recommendation — all within a single request
- For a student with 5 matching rules, this is 10-15+ DB queries added to the result-publish endpoint's response time

**Fix:** Implement `ShouldQueue` on the listener or extract to a queued Job:
```php
class GenerateRecommendationsListener implements ShouldQueue
{
    public string $queue = 'recommendations';
}
```

#### PERF-REC-003 (P2): Unbounded RecommendationMaterial::get() in MaterialBundleController

**File:** `Modules/Recommendation/app/Http/Controllers/MaterialBundleController.php` (create/edit)

```php
$groupedMaterials = RecommendationMaterial::where('is_active', true)
    ->with(['materialType', 'subject'])
    ->orderBy('title')
    ->get()
    ->groupBy('materialType.type_name');
```

Fetches all active materials for the bundle-assignment UI. Grows linearly with content library size. Paginate or use a dedicated AJAX search endpoint for the bundle builder.

---

### Layer 10: Queue / Jobs

**Zero jobs** exist in this module. The engine listener is synchronous (PERF-REC-002). Two critical background processes are unbuilt:

1. **ExpireRecommendationsCommand** (GAP-REC-002) — no mechanism to set status to `EXPIRED` when `due_date` has passed. Overdue recommendations remain `PENDING` indefinitely.
2. **Scheduled Batch** (ENH-REC-002) — `ON_SCHEDULED_WEEKLY` trigger event exists in the lookup table but no command processes it.

---

### Layer 12: Deployment Readiness

| Check | Status |
|-------|--------|
| `env()` outside config | FAIL — 4 occurrences (DEPLOY-REC-001) |
| Hardcoded secrets | PASS — none found |
| Exception details exposed to users | FAIL — DEPLOY-REC-002 |
| `config:cache` compatibility | FAIL — env() calls will return null |
| `route:cache` compatibility | PASS (no closures in route file) |
| Debug artifacts in production code | FAIL — commented `dd()` at RuleController:61 |
| Zero test coverage | FAIL — 0 Pest tests for any code path |

---

## 9. Test Coverage

**0 tests exist for the Recommendation module.** (Confirmed: `Modules/Recommendation/tests/` contains no test files.)

| Test Area | Priority | Description |
|-----------|----------|-------------|
| Engine service unit tests | P1 | Test rule matching, priority computation, idempotency, D31 formula |
| Auth bypass regression | P1 | Verify tabIndex/tabIndex_2 now return 403 after SEC-REC-001 fix |
| Permission correctness | P1 | Verify destroy requires `.delete`, forceDelete requires `.forceDelete` |
| MediaId type safety | P1 | Verify material store/update does not write array to INT column |
| FormRequest validation | P2 | Test each of 18 FormRequests independently |
| Lifecycle transitions | P2 | Test valid and invalid status transitions |
| Tenant isolation | P2 | Verify no cross-tenant data bleed via engine |
| Expiry command | P2 | Unit test `ExpireRecommendationsCommand` once built |

---

## 10. Full Issue Register

### P0 — Deploy Blockers

| Code | Layer | Description | File | Line |
|------|-------|-------------|------|------|
| SEC-REC-001 | Auth | `Gate::any()` return discarded — tabIndex and tabIndex_2 completely ungated | `RecommendationController.php` | 28, 164 |
| SEC-REC-002 | Auth | 10 StudentRecommendation methods use `.create` instead of correct permission — forceDelete grantable to any create user | `StudentRecommendationController.php` | 111, 130, 155, 214, 230, 244, 259, 280, 296, 343 |
| BUG-REC-003 | ORM | `StudentRecommendation::create()` always fails — `created_at` column absent, Eloquent timestamps enabled | `StudentRecommendation.php` / migration | — |

### P1 — Must Fix Before Any Production Use

| Code | Layer | Description | File | Line |
|------|-------|-------------|------|------|
| SEC-REC-003 | Tenancy | `EnsureTenantHasModule:REC` middleware not applied — module accessible without REC license | `RouteServiceProvider.php` | — |
| D39-REC-001 | Auth | No REC permissions seeded in any seeder — all CRUD returns 403 for non-super-admin | `RecommendationDatabaseSeeder.php` | — |
| BUG-REC-001 | Migration | `triggered_by_result_id` absent from migration — engine audit trail silently discarded | migration `2026_06_16_130101` | — |
| BUG-REC-002 | Migration | `is_published` absent from migration — engine-set published flag silently discarded | migration `2026_06_16_130101` | — |
| BUG-REC-004 | Data | `media_id` column is `unsignedInteger` FK in migration; model casts to `array`; controller stores file arrays — type collision corrupts all file attachment saves | `RecommendationMaterialController.php` / `RecommendationMaterial.php` | 138, 38 |
| MIG-REC-001 | Migration | `difficulty_band` in `$fillable` and FormRequest but absent from migration — difficulty-band filtering permanently disabled | migration `2026_06_16_130100` | — |
| ORM-REC-001 | ORM | `TriggerEventPolicy` not registered in ServiceProvider; `RecAssessmentTypePolicy` missing entirely | `RecommendationServiceProvider.php` | — |
| DAT-REC-001 | Data | No DB-level unique constraint for engine idempotency — concurrent result publishes can insert duplicates | migration `2026_06_16_130101` | — |
| DAT-REC-002 | Data | `difficulty_band` always null → difficulty filtering silently skipped → rules fire regardless of student difficulty tier | `RecommendationEngineService.php` | 117 |
| GAP-REC-001 | Auth | `RecAssessmentTypePolicy` file missing; `TriggerEventPolicy` exists but unregistered | `Policies/` / `RecommendationServiceProvider.php` | — |
| GAP-REC-002 | Queue | No `ExpireRecommendationsCommand` — overdue recommendations never set to EXPIRED | — | — |
| GAP-REC-003 | Logic | No status transition FSM — arbitrary transitions allowed (e.g. COMPLETED → PENDING) | `StudentRecommendationController.php` | 296 |
| GAP-REC-004 | Migration | `rec_material_bundles.school_id` absent from migration — school relationship always null | migration `2026_06_16_130055` | — |
| DEPLOY-REC-001 | Deploy | `env('LMS_DISK')` called in model and controller — returns null after `config:cache`, breaking all file operations | `RecommendationMaterial.php`, `RecommendationMaterialController.php` | 144 / 125, 289, 301 |
| PERF-REC-001 | Perf | Unbounded `Student::get()` in 4 controller methods — full student roster in memory on every page load | `RecommendationController.php`, `StudentRecommendationController.php` | — |
| PERF-REC-002 | Queue | Engine listener is synchronous — processes rules, stats queries, and inserts in-band with result-publish HTTP request | `GenerateRecommendationsListener.php` | — |

### P2 — Must Fix Before Feature Sign-Off

| Code | Layer | Description | File |
|------|-------|-------------|------|
| DDL-REC-001 | DDL | `idx_recRule_trigger` index references `trigger_event` (non-existent); `fk_recMat_competency` references `competency_code` (non-existent column) | `Recommendation_DDL_v1.6.sql` |
| DDL-REC-002 | DDL | `class_id / subject_id / topic_id` marked NOT NULL in DDL, nullable in migration — DDL must be corrected | `Recommendation_DDL_v1.6.sql` |
| DDL-REC-004 | DDL | ENUM for priority and status on `rec_student_recommendations` — D29 violation | DDL + migration |
| ORM-REC-002 | ORM | `MaterialBundle::school()` uses `school_id` FK not in migration — show() view always blank for school name | `MaterialBundle.php` / `MaterialBundleController.php:98` |
| VAL-REC-001 | Validation | Double-validation (FormRequest + inline validate) in 5 controllers — conflicting rules for `status` field | `StudentRecommendationController.php` |
| VAL-REC-002 | Validation | `is_automated` override via `$request->has()` bypasses FormRequest validated boolean | `RecommendationRuleController.php:185` |
| GAP-REC-005 | Auth | Permission name mismatch: `tenant.trigger-events.viewAny` (plural, tabIndex) vs `tenant.recommendation-trigger-event.*` (FormRequests) | `RecommendationController.php:25` |
| GAP-REC-007 | Feature | Analytics dashboard entirely unbuilt — FR-REC-18 | — |
| GAP-REC-008 | Feature | No Student Portal API endpoints for recommendation list / status updates | — |
| XSS-REC-001 | Frontend | 7x unescaped `{!! description !!}` in show views — Stored XSS if admin injects HTML | 5 show.blade.php files |
| PERF-REC-003 | Perf | Unbounded `RecommendationMaterial::get()` in MaterialBundleController create/edit | `MaterialBundleController.php` |
| DEPLOY-REC-002 | Deploy | Exception message text exposed to user in error redirects | `RecommendationMaterialController.php` |
| STUB-REC-001 | Quality | `RecommendationController::create/show/edit` methods exist but are unrouted — dead code | `RecommendationController.php` |

### P3 — Cleanup

| Code | Layer | Description | File |
|------|-------|-------------|------|
| DEAD-REC-001 | Quality | Dead `use BundleMaterialJunction` import — class does not exist; PHP lazy-loads so no runtime error | `MaterialBundleController.php:14` |
| DEAD-REC-002 | Quality | Commented-out `// dd($request->all())` in production store method | `RecommendationRuleController.php:61` |
| DDL-REC-003 | DDL | DDL file header says v1.4 but filename is v1.6 — version inconsistency | `Recommendation_DDL_v1.6.sql` |

---

## 11. Remediation Roadmap

### Sprint 1 — P0 Blockers (Days 1-3, 1 dev)

1. **Fix SEC-REC-001:** Wrap `Gate::any()` in `abort_unless()` in `tabIndex()` (L28) and `tabIndex_2()` (L164).
2. **Fix SEC-REC-002:** Correct all 10 `Gate::authorize()` calls in `StudentRecommendationController` to use the right permission string per method.
3. **Fix BUG-REC-003:** Add migration to add `created_at` column to `rec_student_recommendations` OR set `const CREATED_AT = 'assigned_at'` in `StudentRecommendation` model. The migration approach is cleaner (preserves timestamps in both columns).
4. **Fix D39-REC-001:** Create `RolePermissionSeeder.php` with all 33 permission strings listed above. Call from `RecommendationDatabaseSeeder`.

### Sprint 2 — P1 Blockers (Days 4-10, 1-2 devs)

5. **Fix BUG-REC-004:** Change `rec_recommendation_materials.media_id` migration column to `json` (or `longText`), remove FK to `qns_media_store`, update DDL.
6. **Fix MIG-REC-001:** Add `difficulty_band` column to `rec_recommendation_rules` migration.
7. **Fix BUG-REC-001/002:** Add `triggered_by_result_id` and `is_published` columns to `rec_student_recommendations` migration.
8. **Fix DEPLOY-REC-001:** Replace all 4 `env('LMS_DISK')` calls with `config('filesystems.lms_disk')` and add config key.
9. **Fix ORM-REC-001:** Register `TriggerEventPolicy` in ServiceProvider; create and register `RecAssessmentTypePolicy`.
10. **Fix GAP-REC-004:** Add `school_id` column to `rec_material_bundles` migration.
11. **Fix PERF-REC-002:** Implement `ShouldQueue` on `GenerateRecommendationsListener` or extract to queued `GenerateRecommendationsJob`.
12. **Fix SEC-REC-003:** Apply `EnsureTenantHasModule:REC` to web route group.
13. **Fix DAT-REC-001:** Add unique index for idempotency: `(student_id, rule_id, triggered_by_quiz_id, triggered_by_quest_id)`.

### Sprint 3 — P2 / Quality (Days 11-20)

14. Fix XSS-REC-001 in 5 show views (sanitize on save or escape on output).
15. Remove double-validation in 5 controllers (VAL-REC-001).
16. Fix `is_automated` bypass (VAL-REC-002).
17. Fix PERF-REC-001 (AJAX student search or pagination).
18. Build `ExpireRecommendationsCommand` (GAP-REC-002).
19. Implement status transition FSM (GAP-REC-003).
20. Fix permission naming inconsistency (GAP-REC-005).
21. Fix DEPLOY-REC-002 (exception messages).
22. Remove DEAD-REC-001, DEAD-REC-002, STUB-REC-001.
23. Correct DDL v1.6 file to match actual migration schema.
24. Write minimum Pest test suite (engine unit tests, auth regression tests).

---

## 12. Cross-Module Impact

| Module | Impact |
|--------|--------|
| LmsQuiz / LmsQuests | Fires `QuizQuestResultPublished` — engine is broken (BUG-REC-003) so no recommendations are generated on any quiz result today |
| QuestionBank | `qns_question_statistics` used by engine (D31) — dependency correct; `qns_media_store` FK on `media_id` must be removed (BUG-REC-004) |
| Syllabus | `slb_complexity_level` (singular) confirmed correct — no BUG-REC-002 table-name issue here |
| StudentPortal | GAP-REC-008: no API endpoints — portal cannot surface recommendations |
| Notification | ENH-REC-003: no notification on recommendation assignment |

---

*Report generated 2026-06-30 by pa-technical-auditor. AI_Brain version: current. Evidence fully gathered from live code at `/Users/bkwork/Herd/prime_ai/Modules/Recommendation/`.*
