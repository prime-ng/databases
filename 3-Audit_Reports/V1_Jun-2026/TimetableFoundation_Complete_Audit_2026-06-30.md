# Mode X Complete Technical Audit — TimetableFoundation Module
**Date:** 2026-06-30
**Auditor:** pa-technical-auditor (AI Brain v3)
**Audit Mode:** X (A + B + C + G + scoped D)
**Module:** TimetableFoundation (`Modules/TimetableFoundation/`)
**Table prefix:** `tt_*` (TTF owns all tt_ migrations; SmartTimetable and StandardTimetable are consumers)
**Platform:** PHP 8.2 / Laravel 12 / MySQL 8.x / stancl/tenancy v3.9 / nwidart/laravel-modules v12

---

## Executive Summary

TimetableFoundation is the mandatory infrastructure layer for the school scheduling subsystem. SmartTimetable and StandardTimetable both depend on it entirely. Its health directly blocks timetable generation for every tenant.

This audit found **5 P0 (critical) issues** that, in combination, mean:

1. Any school not subscribed to the TimetableFoundation module can still access all 138+ routes (subscription bypass).
2. All API routes run without tenant database context, making tenant data unreachable or misdirected via API.
3. 19 of 23 authorization policy classes are completely bypassed — any authenticated user can perform any operation regardless of role.
4. Every AcademicSession lookup across 6 controllers and 3 models reads from the wrong database (prime_db instead of the tenant's own DB), returning wrong-school data.
5. Two foreign module controllers are registered in TTF's own route group, creating hard runtime failures if those modules are disabled.

**Deploy Gate: NO-GO**
**Health Score: 39 / 100 (P0-capped at 40)**

One BA-documented P0 bug is refuted: `Config::scopeByStatus()` does not exist in the current codebase. The FRD's AC-002.6 "current bug: fails" annotation does not match live code — the Config model and controller correctly use `is_active` via inline closures. This finding is documented to prevent duplicate investigation.

---

## Module Inventory (Verified)

| Asset type | Count |
|---|---|
| Controllers | 27 |
| Models | 34 |
| Services | 5 |
| FormRequests | 4 |
| Policies | 23 (4 effectively registered; 19 dead) |
| Routes (web) | ~138 |
| Routes (api) | ~6 via apiResource |
| Views | 172 |
| Tests | 6 files |
| Tenant migrations (tt_*) | 40 |
| Console commands | 1 (BackfillSubActivityDetails) |

---

## P0 Issue Register

### P0-001 — EnsureTenantHasModule Missing from All Web Routes
**Code:** SEC-PLATFORM-003 (TTF instance)
**File:** `Modules/TimetableFoundation/app/Providers/RouteServiceProvider.php`
**Layer:** Multi-Tenancy / Route Middleware

The web route group middleware stack is:
```
['web', InitializeTenancyByDomain::class, PreventAccessFromCentralDomains::class,
 EnsureTenantIsActive::class, 'auth', 'verified']
```

`EnsureTenantHasModule::class` is absent. `EnsureTenantHasModule` is the middleware that checks whether the current tenant's subscription includes a module before granting access. Without it, a school that has not purchased or activated TimetableFoundation can access all 138+ web routes, modify timetable data, and use the solver.

**Fix:** Add `EnsureTenantHasModule:TimetableFoundation` to the web middleware array in `RouteServiceProvider::boot()` immediately after `EnsureTenantIsActive::class`.

---

### P0-002 — API Routes Lack All Tenancy Middleware
**Code:** SEC-TTF-004 (new)
**File:** `Modules/TimetableFoundation/routes/api.php`
**File:** `Modules/TimetableFoundation/app/Providers/RouteServiceProvider.php`
**Layer:** Multi-Tenancy / API Route Middleware

The API route group uses only:
```php
Route::middleware(['auth:sanctum'])
```

There is no `InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive`, or `EnsureTenantHasModule`. The apiResource registration for `TimetableFoundationController` runs every controller method without tenant database context. Model queries hit whichever database is the default Laravel connection at that moment (central/prime_db), not the tenant's database. This is a complete tenant isolation failure for all API endpoints.

**Fix:** Update API route group to:
```php
Route::middleware([
    'api',
    InitializeTenancyByDomain::class,
    PreventAccessFromCentralDomains::class,
    EnsureTenantIsActive::class,
    EnsureTenantHasModule::class . ':TimetableFoundation',
    'auth:sanctum',
])
```

---

### P0-003 — 19 of 23 Authorization Policies Dead; 1 Policy Killed by Duplicate Gate::policy Call
**Code:** SEC-PLATFORM-008 (TTF instance); SEC-TTF-001 (TTF-specific dead-policy pattern)
**File:** `Modules/TimetableFoundation/app/Providers/TimetableFoundationServiceProvider.php`
**Layer:** Authorization

`registerPolicies()` contains exactly 5 `Gate::policy()` calls, but one is silently overwritten:

```php
protected function registerPolicies(): void
{
    Gate::policy(SchoolDay::class, DayPolicy::class);
    Gate::policy(PeriodSetPeriod::class, PeriodPolicy::class);
    Gate::policy(SchoolShift::class, TimingProfilePolicy::class);        // line 66 — overwritten
    Gate::policy(SchoolShift::class, SchoolTimingProfilePolicy::class);  // line 67 — wins
    Gate::policy(Config::class, TimetableConfigPolicy::class);
}
```

Laravel's `Gate::policy()` does not throw an error on duplicate model registration; the second call overwrites the first. `TimingProfilePolicy` is a dead class (D22/SEC-PLATFORM-008 platform pattern).

The 4 effectively registered policies are:
- `SchoolDay` → `DayPolicy`
- `PeriodSetPeriod` → `PeriodPolicy`
- `SchoolShift` → `SchoolTimingProfilePolicy`
- `Config` → `TimetableConfigPolicy`

The 19 completely unregistered policy classes (files exist at `app/Policies/` but no `Gate::policy()` maps to them):

| Policy class | Intended model |
|---|---|
| `AcademicTermPolicy` | AcademicTerm |
| `ActivityPolicy` | Activity |
| `ClassSubgroupPolicy` | ClassSubgroup-related |
| `ClassTimetableTypePolicy` | ClassTimetableType |
| `ClassWorkingDayPolicy` | ClassWorkingDay |
| `DayTypePolicy` | DayType |
| `PeriodConfigPolicy` | PeriodConfig |
| `PeriodSetPolicy` | PeriodSet |
| `PeriodTypePolicy` | PeriodType |
| `RequirementConsolidationPolicy` | RequirementConsolidation |
| `RoomAvailabilityPolicy` | RoomAvailability |
| `SchoolShiftPolicy` | SchoolShift (separate from TimingProfile) |
| `SlotRequirementPolicy` | SlotRequirement |
| `TeacherAssignmentRolePolicy` | TeacherAssignmentRole |
| `TeacherAvailabilityPolicy` | TeacherAvailability |
| `TimetablePolicy` | Timetable |
| `TimetableTypePolicy` | TimetableType |
| `WorkingDayPolicy` | WorkingDay |
| `TimingProfilePolicy` | SchoolShift (dead — overwritten at line 66) |

`Gate::authorize()` calls in controllers reference permission strings (e.g., `'timetable-foundation.activity.create'`), not model-based policy methods. These string-based checks require the permission to exist in the database and to be granted to the user's role. Policy-based `can()` checks are entirely absent for the 19 unregistered models. Any authenticated user with any permission that includes these actions passes.

**Fix:** Register all 23 policies in `registerPolicies()`, removing the duplicate `SchoolShift` entry:
```php
Gate::policy(SchoolShift::class, SchoolShiftPolicy::class);
Gate::policy(SchoolShift::class, TimingProfilePolicy::class); // separate timing-profile context
// OR: Gate::policy(TimingProfile::class, TimingProfilePolicy::class); if TimingProfile is a separate model
```
Add missing registrations for all 19 policy classes listed above.

---

### P0-004 — Cross-Layer AcademicSession Import (prime_db in Tenant Context)
**Code:** SEC-PLATFORM-007 (TTF instance); TEN-TTF-001 (new TTF-specific tracking)
**Layer:** Multi-Tenancy / Tenant Isolation
**Severity:** Critical data integrity + cross-tenant data leak

`Modules\Prime\Models\AcademicSession` is a prime_db model. Using it inside tenant-context code reads from the shared prime_db `academic_sessions` table, which contains sessions for ALL schools, not just the current tenant. `AcademicSession::current()` or `AcademicSession::active()` in tenant context returns whoever has the globally active session — which may be a different school's session, or null, depending on DB state.

**Affected files (confirmed):**

Controllers:
| File | Lines |
|---|---|
| `app/Http/Controllers/TimetableFoundationController.php` | 51 (import), 910 (query: `AcademicSession::current()->first()`) |
| `app/Http/Controllers/ActivityController.php` | 11 (import), 60 (query: `AcademicSession::current()->firstOrFail()`) |
| `app/Http/Controllers/WorkingDayController.php` | 9 (import), 53, 209, 318, 589, 686 (multiple queries) |
| `app/Http/Controllers/ClassWorkingDayController.php` | 9 (import), 464, 581 (queries) |
| `app/Http/Controllers/RequirementConsolidationController.php` | 10 (import), 41 (query) |
| `app/Http/Controllers/TimetableController.php` | 9 (import), 34, 156 (queries) |

Models:
| File | Lines |
|---|---|
| `app/Models/Timetable.php` | 13 (import), 88 (`belongsTo(AcademicSession::class)`) |
| `app/Models/ClassWorkingDay.php` | 7 (import), 71 (relationship) |
| `app/Models/ClassModeRule.php` | 8 (import), 110 (relationship) |

Note: `TimetableFoundationController.php` line 150 correctly uses `\Modules\SchoolSetup\Models\OrganizationAcademicSession` in the same file — demonstrating the correct pattern exists but was applied inconsistently.

**Fix:** Replace all `Modules\Prime\Models\AcademicSession` references with `Modules\SchoolSetup\Models\OrganizationAcademicSession`, which is the tenant-scoped academic session model. Update relationships, query scopes, and method calls accordingly (`OrganizationAcademicSession::current()` or equivalent).

---

### P0-005 — Cross-Module Controllers in TTF Route Group
**Code:** ARCH-TTF-001 (new)
**File:** `Modules/TimetableFoundation/routes/web.php` lines 29–30, 304, 313
**Layer:** Architecture / Module Coupling

The TTF route file imports and registers controllers from two foreign modules:

```php
// Line 29
use Modules\SchoolSetup\Http\Controllers\ClassSubjectGroupController;
// Line 30
use Modules\SmartTimetable\Http\Controllers\TtGenerationStrategyController;

// Line 304 — SmartTimetable controller on TTF route
Route::resource('generation-strategies', TtGenerationStrategyController::class);

// Line 313 — SchoolSetup controller on TTF route
Route::post('/class-subject-group/generate-class-groups',
    [ClassSubjectGroupController::class, 'generateClassGroups']);
```

**Impact:**
1. If the `SmartTimetable` module is disabled or uninstalled, the `TtGenerationStrategyController` class-not-found error kills the entire TTF route file load (all 138 routes 500 at boot, not just the generation-strategies endpoint).
2. Same for `ClassSubjectGroupController` from `SchoolSetup`.
3. Route names and permissions are in the `timetable-foundation.*` namespace, but the business logic lives in foreign modules — there is no single source of truth for generation strategy behaviour.

**Fix:** Move `TtGenerationStrategyController` to `TimetableFoundation` (or create a TTF wrapper) and remove the direct module cross-import. The FRD (Section 3, REQ-TTF-004) notes this as GAP-TTF-10 and confirms the strategy management belongs to TTF's responsibility scope. For `ClassSubjectGroupController`, route the endpoint to a TTF-owned controller method that internally delegates via a service interface.

---

## P1 Issue Register

### P1-001 — TeacherAvailablity Model Class Name Typo (Missing 'i')
**Code:** ORM-TT-001 (new)
**File:** `Modules/TimetableFoundation/app/Models/TeacherAvailablity.php` (class declaration)
**Layer:** Model / ORM

Class declaration: `class TeacherAvailablity extends Model` — missing the 'i' in 'Availability'.
Table: `tt_teacher_availabilities` (correct spelling).

Any code that writes `use Modules\TimetableFoundation\Models\TeacherAvailability;` (correct spelling) will fail with `Class not found`. The controller imports the typo-named class (`TeacherAvailabilityController.php:13: use Modules\TimetableFoundation\Models\TeacherAvailablity;`) — correctly matching the typo — but this creates a permanent landmine for any future developer.

A secondary typo exists in both the model's fillable array and the migration: column `competancy_level` should be `competency_level`. This is entrenched in the DDL and would require a migration to rename.

**Fix:** Rename the file to `TeacherAvailability.php` and the class to `TeacherAvailability`. Update all references (minimum: `TeacherAvailabilityController.php:13`). For `competancy_level`, create a migration `rename_column tt_teacher_availabilities competancy_level to competency_level` and update model fillable + casts.

---

### P1-002 — TeacherAvailabilityController::store() Is a Live Stub
**Code:** BUG-TT-013 (new)
**File:** `Modules/TimetableFoundation/app/Http/Controllers/TeacherAvailabilityController.php` lines 39–41
**Layer:** Controller

The `store()` method body consists only of a gate check; no implementation exists:
```php
public function store(Request $request)
{
    Gate::authorize('timetable-foundation.teacher-availability.create');
    // no implementation
}
```

The route `POST /teacher-availability` is live and registered. A form submission returns an empty 200 response (or a redirect with no processing), silently discarding the user's data.

**Fix:** Implement the store() method with validation, model persistence, and appropriate response.

---

### P1-003 — God Controller: TimetableFoundationController (2561 lines)
**Code:** PERF-TT-014 (new)
**File:** `Modules/TimetableFoundation/app/Http/Controllers/TimetableFoundationController.php`
**Layer:** Code Quality

2561 lines. Handles Pre-Requisites Setup (Page 1), Timetable Configuration (Page 2), plus dashboard tab loading. Contains `AcademicSession` cross-layer imports and SmartTimetable model imports (`TeacherAvailabilityDetail`, `TtGenerationStrategy`, `ParallelGroup`). A single class that mixes dashboard, configuration, and prerequisite checking concerns.

**Fix:** Split into `PreRequisitesDashboardController`, `TimetableConfigController`, and retain `TimetableFoundationController` only for module entry-point routing. Extract SmartTimetable queries behind a service interface.

---

### P1-004 — God Controller: ActivityController (1853 lines)
**Code:** PERF-TT-015 (new)
**File:** `Modules/TimetableFoundation/app/Http/Controllers/ActivityController.php`
**Layer:** Code Quality

1853 lines. Imports SmartTimetable models directly (`ClassGroupJnt`, `ClassGroupRequirement`, `ClassSubgroup`, `Constraint`, `ParallelGroup`). Also imports cross-layer `AcademicSession` (P0-004). Handles activity CRUD, sub-activity management, requirement generation, and subject allocation in a single class.

**Fix:** Extract `SubActivityController`, `ActivityRequirementController`, and a service layer that abstracts SmartTimetable model queries.

---

### P1-005 — God Controller: RequirementConsolidationController (1219 lines)
**Code:** PERF-TT-016 (new)
**File:** `Modules/TimetableFoundation/app/Http/Controllers/RequirementConsolidationController.php`
**Layer:** Code Quality

1219 lines. Uses `DB::transaction` correctly (line 935) but the method body inside the transaction spans 80+ lines of inline logic that should live in a service. Cross-layer `AcademicSession` import confirmed.

---

### P1-006 — All 4 FormRequests Return `true` from authorize() — D30 Pattern
**Code:** VAL-TT-001 (new); platform pattern D30
**Files:**
- `Modules/TimetableFoundation/app/Http/Requests/TimingProfileRequest.php:32`
- `Modules/TimetableFoundation/app/Http/Requests/AcademicTermRequest.php:17`
- `Modules/TimetableFoundation/app/Http/Requests/SchoolTimingProfileRequest.php:45`
- `Modules/TimetableFoundation/app/Http/Requests/ConfigRequest.php:13`
**Layer:** Authorization / Validation

Every FormRequest `authorize()` method returns a bare `true`, giving any authenticated user the ability to pass FormRequest authorization regardless of permissions. Controllers compensate with `Gate::authorize()` calls, but the D30 pattern means any future controller method that relies solely on FormRequest authorization is open by default.

**Fix:** Per platform standard, implement proper authorization in each FormRequest:
```php
public function authorize(): bool
{
    return $this->user()->can('timetable-foundation.{entity}.{action}');
}
```

---

### P1-007 — 22 of 27 Controllers Have No FormRequest at All
**Code:** VAL-TT-002 (new)
**Layer:** Input Validation

Only 4 controllers (`ConfigController`, `AcademicTermController`, `SchoolShiftController` via `TimingProfileRequest`, `SchoolTimingProfileController` via `SchoolTimingProfileRequest`) have dedicated FormRequest objects. The remaining 22 controllers accept raw `Request` instances. Input validation is performed either inline with `$request->validate()` (acceptable) or absent entirely. This is not always D25 (the controllers that were checked use `$request->validated()` after inline rules), but it means there is no centralized validation contract for most entities.

**Fix:** Create FormRequests for the 22 uncovered controllers at minimum for `store()` and `update()` methods. Priority: `ActivityRequest` (given the 1853-line controller complexity), `WorkingDayRequest`, `TimetableRequest`.

---

### P1-008 — SmartTimetable Model Bidirectional Dependency (ARCH)
**Code:** ARCH-TTF-002 (new)
**Layer:** Architecture / Module Coupling

TTF imports SmartTimetable models in multiple files:

| TTF file | SmartTimetable imports |
|---|---|
| `app/Models/Timetable.php` | `GenerationRun`, `TtGenerationStrategy` |
| `app/Models/Activity.php` | `ParallelGroup` |
| `app/Models/TimetableCell.php` | `GenerationRun` |
| `app/Http/Controllers/ActivityController.php` | `ClassGroupJnt`, `ClassGroupRequirement`, `ClassSubgroup`, `Constraint`, `ParallelGroup` |
| `app/Http/Controllers/ClassSubjectSubgroupController.php` | `ClassGroupJnt`, `ClassSubgroup` |
| `app/Http/Controllers/TimetableFoundationController.php` | `TeacherAvailabilityDetail`, `TtGenerationStrategy`, `ParallelGroup` |

Combined with P0-005 (SmartTimetable controller in TTF routes), this creates a **bidirectional** hard dependency: TTF requires SmartTimetable to even load its routes and models. This inverts the intended dependency direction — TTF is the foundation that SmartTimetable should depend on, not the reverse.

**Fix:** Define service interfaces in TTF (`TimetableStrategyRepositoryInterface`, `GenerationRunRepositoryInterface`) that SmartTimetable implements. TTF models should only hold foreign key integers (`generation_strategy_id`, `generation_run_id`) and resolve the relationship via interface, not via hard SmartTimetable model imports.

---

## P2 Issue Register

### P2-001 — D36 Partial: tt_room_availability.available_for_full_timetable_duration Plain vs Generated
**Code:** MIG-TT-001 (extends existing known-issue)
**File:** `database/migrations/tenant/2026_06_16_152638_create_tt_room_availability_table.php:19`
**Layer:** Migration / DDL Consistency

Migration declares: `$table->boolean('available_for_full_timetable_duration')->default(true)` — a plain writable boolean.

The DDL file (`2-DDL_Tenant_Consolidated/Timetable_DDL_v7.8.sql`) specifies this column as a STORED generated column derived from date comparison (analogous to `tt_teacher_availabilities.available_for_full_timetable_duration` which is correctly generated). The migration-DDL mismatch means:
- PHP code can write arbitrary values to this column (it accepts writes).
- When a room's availability dates change, the flag does not auto-update — it retains the original value.
- The business invariant (flag = whether room is available for the full timetable duration) is not enforced.

For contrast, `tt_teacher_availabilities.available_for_full_timetable_duration` is correctly implemented as STORED generated via `DB::statement()` in `2026_06_16_152641_create_tt_teacher_availability_table.php`.

**Correction to existing MIG-TT-001:** The known-issue entry MIG-TT-001 lists `tt_period_set.total_periods` as a degraded generated column. Investigation shows `total_periods` in both the migration and DDL is a plain writable `unsignedTinyInteger` — this is consistent, not a defect. The existing entry for `duration_minutes` is also confirmed correct (properly GENERATED). Only `tt_room_availability.available_for_full_timetable_duration` requires the upgrade.

**Fix:** Add a migration:
```php
DB::statement("ALTER TABLE tt_room_availabilities MODIFY available_for_full_timetable_duration TINYINT(1) GENERATED ALWAYS AS (IF(room_available_from_date <= timetable_start_date, 1, 0)) STORED");
```
(Verify exact expression against DDL before applying.)

---

### P2-002 — D29 Pattern: 28 ->enum() Declarations Across 20 tt_ Migrations
**Code:** D29-TTF-001 (new)
**Layer:** DDL Schema Integrity

Platform decision D29 bans the Laravel `->enum()` migration helper because MySQL ENUM types cannot be altered without full table reconstruction, break zero-downtime deploys, and cannot be referenced via `sys_dropdown_table` FK lookups. TTF has 28 enum column declarations spread across 20 migration files:

| Migration | Enum columns |
|---|---|
| `tt_resource_booking` | 3 enums |
| `tt_substitution_log` | 2 |
| `tt_teacher_availability` | 2 (`competancy_level`, `allocation_strictness`) |
| `tt_timetable` | 2 (`generation_method`, `status`) |
| `tt_teacher_unavailable` | 2 |
| `tt_teacher_absence` | 2 |
| `tt_generation_strategy` | 2 |
| `tt_change_log` | 1 |
| `tt_timetable_cell` | 1 |
| `tt_sub_activity_detail` | 1 |
| `tt_room_availability_detail` | 1 |
| `tt_teacher_availability_detail` | 1 |
| `tt_room_availability` | 1 |
| `tt_generation_run` | 1 |
| `tt_constraint_violation` | 1 |
| `tt_conflict_detection` | 1 |
| `tt_activity` | 1 |
| `tt_constraint_type` | 1 |
| `tt_constraint_category_scope` | 1 |
| `tt_config` | 1 |

**Fix:** For columns whose values are fixed platform constants (e.g., `generation_method`: FULL_AUTO/MANUAL/SEMI_AUTO), convert to `string` with a `CHECK` constraint or a referenced lookup table. For user-configurable values, reference `sys_dropdown_table`. Priority order: `tt_timetable.status` (most queried), `tt_timetable.generation_method`, `tt_teacher_availability.competancy_level`.

---

### P2-003 — Test Suite Strips Tenancy Middleware; Only Covers Unauthenticated Redirects
**Code:** TEST-TT-001 (new)
**File:** `Modules/TimetableFoundation/tests/Feature/RouteAuthenticationTest.php`
**Layer:** Tests

The test file's `beforeEach()` explicitly removes all tenancy middleware:
```php
$this->withoutMiddleware([
    InitializeTenancyByDomain::class,
    PreventAccessFromCentralDomains::class,
    EnsureTenantIsActive::class,
]);
```

Tests only assert that unauthenticated GET/POST requests are redirected. The test suite is structurally incapable of detecting:
- Missing `EnsureTenantHasModule` (P0-001)
- API tenancy failures (P0-002)
- Cross-layer AcademicSession returns wrong-school data (P0-004)
- Policy registration gaps (P0-003)
- Business rule enforcement (date overlap, cascade delete blocking)

The 5 P0 issues in this module would all pass the current test suite.

**Fix:** Add feature tests that use actual tenant context (`tenancy()->initialize($tenant)` in `beforeEach`), test authenticated + authorized access (not just unauthenticated redirects), and verify at least one business rule per controller (overlap rejection, cascade block, etc.).

---

### P2-004 — Column Name Typo Entrenched in DDL: competancy_level
**Code:** BUG-TT-015 (new)
**File:** `database/migrations/tenant/2026_06_16_152641_create_tt_teacher_availability_table.php:31`
**File:** `app/Models/TeacherAvailablity.php` (fillable + casts)
**Layer:** DDL Schema

The column is named `competancy_level` (missing 'e' in competency) in both the migration DDL and the model. This is entrenched across the schema. While functional, it creates confusion for any query referencing the column by name and mismatches the business domain language in the FRD.

**Fix:** Add a migration renaming the column:
```sql
ALTER TABLE tt_teacher_availabilities RENAME COLUMN competancy_level TO competency_level;
```
Update model fillable, casts, and any `->where('competancy_level', ...)` query calls.

---

## P3 Issue Register

### P3-001 — view() Called with Wrong View Name in TeacherAvailabilityController::edit()
**Code:** BUG-TT-016 (new)
**File:** `Modules/TimetableFoundation/app/Http/Controllers/TeacherAvailabilityController.php`
**Layer:** Controller / View

`edit()` calls `view('timetablefoundation::edit')` — a top-level generic name that does not correspond to any teacher-availability-specific view. The correct name should be `timetablefoundation::teacher-availability.edit` (following the module's own view naming convention). This renders the wrong template or throws a view-not-found error on the edit route.

---

### P3-002 — Unregistered BackfillSubActivityDetails Console Command
**Code:** DEAD-TT-003 (new)
**File:** Confirmed console command exists; not scheduled
**Layer:** Console / Queue

The `BackfillSubActivityDetails` command exists but is commented out of `registerCommandSchedules()`. If the backfill was used to populate historical data, it should either be scheduled or removed from the codebase.

---

### P3-003 — {!! !!} Unescaped Output (Safe Context — Boolean Badge Renders)
**Code:** UI-TT-001 (informational)
**Files:** `resources/views/activity/show.blade.php` (lines 30–31, 46, 48, 54, 76, 104); `resources/views/pages/teacher-availability/show.blade.php` (lines 395–407)
**Layer:** Frontend / Blade

Multiple views use `{!! !!}` to render HTML badge strings. All confirmed cases render hardcoded HTML strings derived from boolean model attributes (`$activity->is_active`, `$activity->is_compulsory`, etc.) — no user-controlled string reaches the unescaped output. This is safe in current code. However, the pattern is brittle: if a future developer adds a user-provided string to these constructs, XSS will occur without any warning.

**Fix:** Replace boolean badge constructs with a Blade component or component class:
```blade
<x-status-badge :active="$activity->is_active" />
```
This eliminates the `{!! !!}` usage entirely and provides a safer, reusable pattern.

---

## BA-Documented P0 Refuted — Config::scopeByStatus()

The BA FRD document (`TTF_FRD_2026-06-30.md`, AC-002.6) states: "The 'Is Active' scope filter (`scopeByStatus`) queries the `is_active` column — not a non-existent `status` column. YES/NO [current bug: fails]"

**Investigation result: NOT CONFIRMED in current code.**

The `Config` model (`app/Models/Config.php`) contains:
- `scopeActive()` — correctly filters by `is_active`
- No `scopeByStatus()` method exists anywhere in the TTF codebase

`ConfigController.php` uses `Config::query()->when(...)` with inline `is_active` filter and calls `$request->validated()`. There is no invocation of any non-existent scope.

This bug appears to have been fixed before the audit date, or the BA was examining a prior version of the code. This is documented here to prevent duplicate investigation. The FRD's AC-002.6 should be updated to `YES (resolved)`.

---

## FRD Gap Analysis (Mode B)

Cross-referenced against `TTF_FRD_2026-06-30.md` and `TTF_FRD_Complete_2026-06-30.md`.

| Requirement | AC | Status | Notes |
|---|---|---|---|
| REQ-TTF-001: Pre-Req Setup Dashboard | AC-001.1: Tab panels render | LIKELY MET | TimetableFoundationController.php has preRequisitesSetup() |
| REQ-TTF-001 | AC-001.4: Teacher without admin sees 403 | RISK | Policy not registered (P0-003 above) |
| REQ-TTF-002: Config Management | AC-002.1–AC-002.5 | MET | ConfigController, ConfigRequest, Gate::authorize all correct |
| REQ-TTF-002 | AC-002.6: scopeByStatus bug | REFUTED — see above | Bug not present in current code |
| REQ-TTF-003: Academic Term | AC-003.1: Overlap date range rejected | GAP — not implemented | AcademicTermController has no overlap check; only orders by start_date |
| REQ-TTF-003 | AC-003.2: Delete blocked on dependencies | UNVERIFIED | destroy() not reviewed in full |
| REQ-TTF-003 | AC-003.3: Soft-delete + restore | LIKELY MET | SoftDeletes on model; restore route registered |
| REQ-TTF-004: Generation Strategy | AC-004.1–AC-004.4 | PARTIAL / CROSS-MODULE | Implemented in SmartTimetable controller; TTF routes point there (P0-005) |
| REQ-TTF-005: School Shift | AC-005.1: Duplicate code error | UNVERIFIED | Likely relies on DB unique constraint |
| REQ-TTF-005 | AC-005.3: Delete blocked on Timetable Type link | UNVERIFIED | destroy() not reviewed |
| REQ-TTF-006: Day Type | AC-006.2: is_working_day affects term day count | UNVERIFIED | WorkingDayController 710 lines — not fully reviewed |
| REQ-TTF-007: Period Type | AC-007.3: Cannot delete type referenced by Slot | UNVERIFIED | Foreign key constraint likely handles this at DB level |

**Critical Gap:** REQ-TTF-003 AC-003.1 — No application-level date overlap validation for Academic Terms. DB-level uniqueness constraint alone cannot enforce multi-column date range non-overlap. A user can create two terms for the same session with overlapping date ranges and the application will not reject them.

---

## Business Rule Enforcement (Mode C)

| Rule | Enforcement | Status |
|---|---|---|
| BR-TTF-011: Tenant-managed config keys are read-only | `is_tenant_modifiable` check in ConfigController | VERIFIED MET |
| BR-TTF-012: Only one Generation Strategy is default | No enforcement found in TTF (lives in SmartTimetable controller) | CROSS-MODULE GAP |
| BR-TTF-013: Academic Term dates must not overlap | No application validation | GAP |
| BR-TTF-014: Shift code, name, ordinal unique | Relies on DB unique constraint only | PARTIAL — no friendly error message |
| BR-TTF-015: Changing term scope requires re-generating activities | No enforcement found | GAP |

---

## Architecture Gap Analysis (Mode G — Scoped to TTF)

### GAP-TTF-01: TTF Has Hard Runtime Dependency on SmartTimetable
TTF routes, models, and controllers import SmartTimetable classes directly. If SmartTimetable is toggled off (tenant subscription), the TTF route file fails to load entirely. The foundation module must not depend on consumer modules.

### GAP-TTF-02: Academic Session Abstraction Missing
The correct model (`OrganizationAcademicSession` from `SchoolSetup`) is used in some TTF files but not others. There is no TTF-internal service or trait that provides a `currentAcademicSession()` helper — each controller looks up the session independently, leading to inconsistent model usage. A `TimetableContextService::currentSession()` method should be the single point of session resolution.

### GAP-TTF-03: No Module Service Layer for Cross-Module Data
5 services exist in TTF (`PriorityConfigService` and others) but there is no service that abstracts the cross-module data reads (SchoolSetup buildings, rooms, subjects; SmartTimetable strategies). Controllers directly import foreign-module models, making cross-module coupling invisible to dependency injection.

### GAP-TTF-04: API Route Group Is Structurally Incomplete
The API route group has no tenancy middleware, no module gate, and registers only a single apiResource. It appears to be a scaffold that was never completed. Either the API routes should be properly secured or removed until needed.

---

## Layer Health Matrix

| Layer | Weight | Score | Weighted | Rationale |
|---|---:|:---:|---:|---|
| 1. DDL Schema Integrity | 7 | AMBER | 3.5 | D29 ENUMs in 20 migrations; `competancy_level` typo |
| 2. Migration-Model-DDL Consistency | 9 | AMBER | 4.5 | D36 partial (`tt_room_availability`); model class name typo |
| 3. Model & ORM Correctness | 2 | AMBER | 1.0 | Cross-layer imports in 3 models; class name typo |
| 4. Code Quality | 4 | AMBER | 2.0 | 2 God controllers (2561, 1853 lines); 2 large (1219, 710) |
| 5. Authorization | 14 | RED | 0 | 19/23 policies dead; all 4 FRs return true; D30 |
| 6. Multi-Tenancy Isolation | 15 | RED | 0 | No EnsureTenantHasModule; API unguarded; cross-layer Session |
| 7. Input Validation | 11 | RED | 0 | 22/27 controllers have no FormRequest; D30 on all 4 that exist |
| 8. Data Integrity / Transactions | 13 | GREEN | 13.0 | DB::transaction used consistently; no unguarded multi-write |
| 9. Performance | 7 | AMBER | 3.5 | God controllers risk N+1; unbounded queries in large controllers |
| 10. Queue / Job | 6 | GREEN | 6.0 | No jobs needed; command exists but not scheduled (P3 only) |
| 11. Frontend / Blade | 2 | AMBER | 1.0 | `{!! !!}` pattern present but low XSS risk in current code |
| 12. Deployment | 10 | AMBER | 5.0 | No `env()` in controllers; no route:cache blockers found |
| **Total** | **100** | | **39.5** | |

**Raw score: 39.5 / 100**
**P0 cap: any P0 present → max 40**
**Final Health Score: 39 / 100**
**Deploy Gate: NO-GO**

---

## Remediation Roadmap

### Sprint 1 (P0 — Block Deploy)
1. Add `EnsureTenantHasModule:TimetableFoundation` to RSP web middleware stack (1h)
2. Add full tenancy middleware to API route group in RSP (1h)
3. Replace all `Modules\Prime\Models\AcademicSession` with `OrganizationAcademicSession` in 6 controllers + 3 models (4h)
4. Register all 23 policies in `TimetableFoundationServiceProvider::registerPolicies()` — remove duplicate SchoolShift mapping (2h)
5. Move `TtGenerationStrategyController` logic to TTF or create a TTF wrapper controller; remove SchoolSetup cross-import from routes (4h)

### Sprint 2 (P1 — Quality / Correctness)
6. Rename `TeacherAvailablity` class and file to `TeacherAvailability`; update all references (2h)
7. Implement `TeacherAvailabilityController::store()` (4h)
8. Fix `TeacherAvailabilityController::edit()` view name (30min)
9. Implement FormRequest `authorize()` properly in all 4 existing requests (2h)
10. Add FormRequests for top-3 priority controllers: Activity, WorkingDay, Timetable (8h)
11. Begin decomposing `TimetableFoundationController` into 2 focused controllers (8h)

### Sprint 3 (P2 — Schema Debt)
12. Create migration: drop `->enum()` on `tt_timetable.status` and `.generation_method`; replace with `string` + CHECK constraint (3h)
13. Create migration: rename `competancy_level` to `competency_level` on `tt_teacher_availabilities` (1h)
14. Upgrade `tt_room_availability.available_for_full_timetable_duration` to STORED generated column (2h)
15. Extend test suite with tenant-scoped feature tests covering authorization, business rules (8h)
16. Implement Academic Term date-overlap validation in `AcademicTermController::store()` and `update()` (3h)

### Sprint 4 (Architectural Debt)
17. Define service interfaces to decouple TTF from SmartTimetable model imports
18. Implement `TimetableContextService::currentSession()` as single point of session resolution
19. Decompose remaining God controllers (ActivityController, RequirementConsolidationController)

---

## Known-Issues Update Required

The following known-issue codes should be added to `AI_Brain/lessons/known-issues.md` (starting after the current maximum of BUG-TT-012, SEC-TT-003, PERF-TT-013, DEAD-TT-002, MIG-TT-001):

| Code | Severity | Summary |
|---|---|---|
| BUG-TT-013 | P1 | TeacherAvailabilityController::store() is a live stub |
| BUG-TT-014 | P2 | tt_room_availability.available_for_full_timetable_duration plain vs generated |
| BUG-TT-015 | P2 | competancy_level column name typo (missing 'e') |
| BUG-TT-016 | P3 | TeacherAvailabilityController::edit() calls wrong view name |
| SEC-TT-004 | P0 | API routes lack tenancy middleware entirely |
| PERF-TT-014 | P1 | TimetableFoundationController God controller (2561 lines) |
| PERF-TT-015 | P1 | ActivityController God controller (1853 lines) |
| PERF-TT-016 | P1 | RequirementConsolidationController 1219 lines |
| ORM-TT-001 | P1 | TeacherAvailablity model class name typo (missing 'i') |
| TEN-TT-001 | P0 | Cross-layer AcademicSession imports in 6 controllers + 3 models |
| ARCH-TT-001 | P0 | Cross-module controllers (SmartTimetable, SchoolSetup) registered in TTF routes |
| ARCH-TT-002 | P1 | SmartTimetable model bidirectional dependency in TTF |
| TEST-TT-001 | P2 | Test suite strips tenancy middleware; only covers unauthenticated redirects |
| D29-TTF-001 | P2 | 28 ->enum() declarations across 20 tt_ migrations |

SEC-PLATFORM-003, SEC-PLATFORM-007, SEC-PLATFORM-008 are already in known-issues as platform patterns and confirmed in TTF.
MIG-TT-001 should be corrected: remove `tt_period_set.total_periods` (plain in both DDL and migration — consistent); retain `tt_room_availability.available_for_full_timetable_duration` (confirmed D36 degradation).
VAL-TT-001/VAL-TT-002 can reference platform pattern D30 for FormRequest authorize().

---

*Audit complete. Report generated by pa-technical-auditor on 2026-06-30.*
*Artifact: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Audit_Reports/TimetableFoundation_Complete_Audit_2026-06-30.md`*
