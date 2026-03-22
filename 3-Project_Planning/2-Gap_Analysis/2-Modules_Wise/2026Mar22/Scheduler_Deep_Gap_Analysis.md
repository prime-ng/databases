# Scheduler Module — Production-Readiness Gap Analysis
**Date:** 2026-03-22  |  **Branch:** Brijesh_SmartTimetable  |  **Auditor:** Claude Code (Deep Audit)
**Module Path:** /Users/bkwork/Herd/prime_ai/Modules/Scheduler

---

## EXECUTIVE SUMMARY

| Severity    | Count |
|-------------|-------|
| Critical    | 5     |
| High        | 7     |
| Medium      | 8     |
| Low         | 5     |
| **Total**   | **25**|

### Module Scorecard

| Area                      | Score | Notes                                              |
|---------------------------|-------|----------------------------------------------------|
| DB / DDL Integrity        | N/A   | No DDL — skip                                     |
| Route Integrity           | 4/10  | Triplicated routes, missing methods                |
| Controller Quality        | 2/10  | Zero auth, empty stubs, double validation          |
| Model Quality             | 5/10  | Missing SoftDeletes, missing relationships         |
| Security                  | 1/10  | ZERO authorization on entire controller            |
| Performance               | 6/10  | Loads all schedules without pagination             |
| Authorization             | 0/10  | Zero Gate checks, zero policy                      |
| Test Coverage             | 6/10  | Good structural tests documenting gaps             |
| Architecture              | 7/10  | Good: services, contracts, enums, job registry     |
| **Overall**               | **3.9/10** |                                               |

---

## SECTION 1 — MISSING FEATURES

**MF-001 — `update()` Method is Empty (CRITICAL)**
- File: `SchedulerController.php` lines 76-78
- `update(Request $request, $id)` — completely empty body. Users cannot edit schedules.

**MF-002 — `destroy()` Method is Empty (CRITICAL)**
- File: `SchedulerController.php` lines 83-85
- `destroy($id)` — completely empty body. Users cannot delete schedules.

**MF-003 — `show()` Method Returns Generic View**
- File: `SchedulerController.php` lines 60-63
- `return view('scheduler::show')` — returns a generic module view, not a schedule detail view.

**MF-004 — `edit()` Method Returns Generic View**
- File: `SchedulerController.php` lines 68-71
- `return view('scheduler::edit')` — returns a generic module view without loading the schedule data.

**MF-005 — No Schedule Execution Engine**
- `SchedulerService::dueSchedules()` identifies due schedules but there is no command/job that dispatches them.
- Missing: `php artisan schedule:dispatch` command or kernel integration.

**MF-006 — No `trashedSchedule()` Method Despite Route**
- Route at web.php line 278: `[SchedulerController::class, 'trashedSchedule']`
- No such method exists on SchedulerController.

**MF-007 — No Schedule Run History View**
- `ScheduleRun` model exists but no controller/view to display run history.

**MF-008 — No Toggle Status Endpoint**
- No `toggleStatus()` method for enabling/disabling schedules via AJAX, unlike other modules.

**MF-009 — No Tenant Schedule Management**
- `Schedule` model supports `schedule_type = 'tenant'` and `tenant_id`, but all routes are in central domain only.
- No tenant-side schedule management routes in tenant.php.

---

## SECTION 2 — BUGS

**BUG-001 — Double Validation in `store()` (HIGH)**
- File: `SchedulerController.php` lines 34-42
- Method signature accepts `ScheduleRequest $request` (FormRequest with validation rules).
- Then ALSO calls `$request->validate([...])` inline with DIFFERENT rules.
- The FormRequest validation runs first, then inline validation overwrites/re-validates.
- FormRequest has `'sometimes'` rules for update, but store hardcodes `'required'`.
- This defeats the purpose of having a FormRequest.

**BUG-002 — `store()` Ignores FormRequest's `is_active` Default**
- File: `SchedulerController.php` line 50
- `'is_active' => $data['is_active'] ?? true` — uses null coalescing, but the FormRequest's `prepareForValidation()` already converts it to boolean. The `?? true` is redundant but harmless.

**BUG-003 — `payload` JSON Decode Without Error Handling**
- File: `SchedulerController.php` line 49
- `json_decode($data['payload'], true)` — if payload is invalid JSON, returns null silently.
- No validation rule for valid JSON.

**BUG-004 — ScheduleRun Model Missing Relationship to Schedule**
- File: `ScheduleRun.php` — has `schedule_id` in fillable but no `schedule()` BelongsTo relationship defined.

**BUG-005 — Schedule Model Missing Relationship to ScheduleRuns**
- File: `Schedule.php` — no `runs()` HasMany relationship to ScheduleRun.

---

## SECTION 3 — SECURITY ISSUES

**SEC-001 — ZERO Authorization on Entire Controller (CRITICAL)**
- File: `SchedulerController.php` — 6 methods, 0 Gate::authorize calls.
- Methods: `index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`.
- ANY authenticated user can:
  - View all schedules
  - Create new schedules (including setting arbitrary cron expressions and job keys)
  - Access schedule detail/edit pages

**SEC-002 — No Job Key Validation Against Registry (HIGH)**
- File: `SchedulerController.php` line 36: `'job_key' => 'required|string'`
- Any string accepted as `job_key`. Should validate against `JobRegistry::all()` keys.
- Malicious user could set `job_key` to non-existent class, causing runtime errors.

**SEC-003 — Cron Expression Not Validated (HIGH)**
- `'cron_expression' => 'required|string'` — no validation that it's a valid cron expression.
- Invalid cron expressions will cause `SchedulerService::isDue()` to throw exceptions (caught by try/catch, but still problematic).

**SEC-004 — No Payload Size Limit**
- `'payload' => 'nullable|string'` — no max length. Could store extremely large JSON payloads.

**SEC-005 — Schedule Creation Allows Arbitrary Tenant ID**
- `Schedule` model has `tenant_id` in fillable, but `store()` hardcodes `schedule_type` to `'prime'`.
- However, if update is ever implemented, no validation prevents setting `tenant_id` to another tenant.

**SEC-006 — No Audit Trail / Activity Logging**
- No `activityLog()` calls anywhere in the controller. Schedule creation, modification, and deletion are untracked.

---

## SECTION 4 — PERFORMANCE ISSUES

**PERF-001 — `index()` Loads All Schedules Without Pagination (HIGH)**
- File: `SchedulerController.php` line 18
- `Schedule::orderBy('created_at', 'desc')->get()` — loads ALL schedules into memory.
- Should use `->paginate(10)`.

**PERF-002 — `SchedulerService::dueSchedules()` Loads All Active Schedules**
- File: `SchedulerService.php` line 16
- `Schedule::query()->where('is_active', true)->get()` — loads all active schedules then filters in PHP.
- For large schedule counts, this is inefficient. Should filter by cron at DB level where possible.

---

## SECTION 5 — AUTHORIZATION GAPS

**AUTH-001 — SchedulerController Has ZERO Gate::authorize Calls (CRITICAL)**
- Every method is unprotected:
  - `index()` — line 16: No auth
  - `create()` — line 25: No auth
  - `store()` — line 34: No auth
  - `show()` — line 60: No auth
  - `edit()` — line 68: No auth
  - `update()` — line 76: No auth (also empty)
  - `destroy()` — line 83: No auth (also empty)

**AUTH-002 — No Scheduler Policy Exists**
- No `SchedulerPolicy.php` file in any Policies directory.
- No Gate::policy registration for Schedule model in AppServiceProvider.

**AUTH-003 — Route Middleware Only Checks Auth, Not Permissions**
- Route group uses `['auth', 'verified']` but no permission middleware.

---

## SECTION 6 — MISSING POLICIES

| Entity       | Policy Exists | Registered in AppServiceProvider |
|--------------|---------------|----------------------------------|
| Schedule     | **No**        | **No**                           |
| ScheduleRun  | **No**        | **No**                           |

- Both models have ZERO policy protection.
- Need: `SchedulePolicy` with viewAny, view, create, update, delete, restore, forceDelete.

---

## SECTION 7 — DB / MODEL MISMATCHES

**DBM-001 — Schedule Model Missing SoftDeletes (HIGH)**
- File: `Schedule.php` — no `use SoftDeletes;` trait.
- Migration (line 24) has no `$table->softDeletes()` either.
- Project standard requires SoftDeletes on all models.

**DBM-002 — ScheduleRun Model Missing SoftDeletes**
- Same issue: no SoftDeletes trait or `deleted_at` column.

**DBM-003 — Both Models Missing `created_by` Column**
- Project standard requires `created_by` on all tables.
- Neither `schedules` nor `schedule_runs` migrations include it.

**DBM-004 — Schedule Migration Missing `deleted_at`**
- File: `2026_01_02_112016_create_schedules_table.php`
- No `$table->softDeletes()` call.

**DBM-005 — ScheduleRun Model Missing `$table` Property**
- File: `ScheduleRun.php` — no explicit `$table` declaration.
- Laravel convention resolves to `schedule_runs` which matches migration, but explicit declaration is safer.

**DBM-006 — Schedule Model Missing `last_run_at` and `next_run_at` in Fillable**
- Migration defines `last_run_at` and `next_run_at` columns (lines 23-24 of migration).
- Model's `$fillable` does NOT include them.
- These columns cannot be mass-assigned; service must update them manually or they'll never be populated.

**DBM-007 — ScheduleRun Missing `duration_ms` Cast**
- `duration_ms` is an integer column but not in `$casts`. Minor but inconsistent with casting started_at/finished_at.

---

## SECTION 8 — ROUTE ISSUES

**RT-001 — Scheduler Routes Triplicated in web.php (HIGH)**
- Routes appear at three locations in web.php:
  1. Lines 274-281 (under first `central.` domain group)
  2. Lines 516-521 (under second route group — likely middle)
  3. Lines 841-845 (under third route group)
- Each registration creates a separate set of named routes that may conflict.

**RT-002 — `trashedSchedule` Route Points to Non-Existent Method**
- Route at lines 278/520/845: `[SchedulerController::class, 'trashedSchedule']`
- No `trashedSchedule()` method exists on SchedulerController.
- Will throw MethodNotAllowedHttpException at runtime.

**RT-003 — Module's Own routes/web.php Not Used**
- All scheduling routes are in global web.php, not in the module's own route file.

**RT-004 — No API Routes for Scheduler**
- No REST API endpoints for programmatic schedule management.
- Important for multi-tenant SaaS where tenants may need API access.

**RT-005 — Route Naming Inconsistency**
- Routes use `central.scheduler.schedule.*` naming.
- Controller redirects use `central.scheduler.schedule.index`.
- Comment says "School Timing Profile Routes" (copy-paste error from another module).

---

## SECTION 9 — MISSING FORM REQUESTS

| Controller Method                  | Uses FormRequest? | Issue                                     |
|------------------------------------|-------------------|-------------------------------------------|
| SchedulerController::store()       | Yes + inline      | Double validation — FormRequest ignored    |
| SchedulerController::update()      | No (Request)      | Empty method, bare Request type-hint       |
| SchedulerController::show()        | N/A               | No input                                  |
| SchedulerController::edit()        | N/A               | No input                                  |

- `ScheduleRequest` exists and is well-structured, but `store()` overrides it with inline validation.

---

## SECTION 10 — TEST COVERAGE GAPS

**TEST-001 — Good Structural Tests But No Feature Tests**
- File: `tests/Unit/SchedulerModuleTest.php`
- Contains 16 Pest tests covering:
  - Model table names, fillable fields, casts
  - Missing SoftDeletes (intentionally documented)
  - Controller existence and zero-auth documentation
  - Empty update/destroy method verification
  - Architecture class existence checks
- These tests DOCUMENT the problems rather than verify correct behavior.

**Missing Test Coverage:**
- No HTTP/feature tests for routes
- No schedule creation tests
- No SchedulerService unit tests
- No JobRegistry tests
- No cron expression validation tests
- No authorization tests (meaningless since auth doesn't exist)
- No ScheduleRun logging tests
- No integration test for schedule dispatch flow

---

## SECTION 11 — STUB / EMPTY METHODS

| File                        | Method    | Line | Status                |
|-----------------------------|-----------|------|-----------------------|
| SchedulerController.php     | show()    | 60   | Returns generic view  |
| SchedulerController.php     | edit()    | 68   | Returns generic view  |
| SchedulerController.php     | update()  | 76   | Completely empty      |
| SchedulerController.php     | destroy() | 83   | Completely empty      |

---

## SECTION 12 — ARCHITECTURE VIOLATIONS

**ARCH-001 — Controller Contains Business Logic**
- `store()` method (lines 34-53) handles JSON parsing, data transformation, and model creation.
- Should use `SchedulerService` for schedule creation.

**ARCH-002 — SchedulerService Not Used by Controller**
- `SchedulerService` exists with `dueSchedules()` method but is never called by the controller or any command.
- It's orphaned code.

**ARCH-003 — No Artisan Command for Schedule Dispatch**
- `SchedulerService::dueSchedules()` returns due schedules but nothing dispatches them.
- Expected: `ScheduleDispatchCommand` registered in Laravel's kernel to run `php artisan schedule:run`.

**ARCH-004 — SchedulerType is Not a PHP 8.1+ Enum**
- File: `Enums/SchedulerType.php` — uses class constants instead of PHP 8.1 native enum.
- Since Laravel 11+ targets PHP 8.2+, should use backed enum.

**ARCH-005 — No Event/Listener Pattern for Schedule Events**
- No events fired on schedule creation, execution, failure.
- Should emit `ScheduleCreated`, `ScheduleExecuted`, `ScheduleFailed` events.

**ARCH-006 — JobRegistry Hardcodes Job Classes**
- File: `JobRegistry.php` lines 18-22
- Only 3 jobs hardcoded. Should be configurable or auto-discovered.
- References `App\Jobs\Prime\BillingReportJob`, `App\Jobs\Tenant\TestJob`, `App\Jobs\Prime\TestJob` — these may not exist.

**ARCH-007 — No Activity Logging**
- Zero `activityLog()` calls in the entire module. Violates project convention.

---

## SECTION 13 — WHAT IS WORKING CORRECTLY

1. **Service Architecture** — `SchedulerService` and `JobRegistry` demonstrate proper service layer thinking.
2. **Contract/Interface** — `SchedulableJob` interface with `description()` and `allowedScheduleTypes()` is well-designed.
3. **Enum Class** — `SchedulerType` provides constants for schedule types.
4. **FormRequest** — `ScheduleRequest` is well-structured with update/create differentiation.
5. **Cron Validation in Service** — `SchedulerService::isDue()` safely catches invalid cron expressions.
6. **Model Helpers** — `Schedule::isPrime()` and `isTenant()` are clean helper methods.
7. **Migration Structure** — Proper foreign keys, indexes, enum columns in migrations.
8. **Job Registry UI Format** — `JobRegistry::forUi()` provides dropdown-ready data.
9. **Module Structure** — Follows nwidart/laravel-modules convention.
10. **Test Suite Documents Gaps** — SchedulerModuleTest.php explicitly verifies and documents the known issues (zero auth, empty methods).

---

## PRIORITY FIX PLAN

### P0 — Critical (Fix Immediately)
| ID       | Issue                                                    | Effort |
|----------|----------------------------------------------------------|--------|
| SEC-001  | Add Gate::authorize to all SchedulerController methods    | 1h     |
| AUTH-002 | Create SchedulePolicy and register in AppServiceProvider  | 1h     |
| MF-001   | Implement `update()` method with proper validation        | 1.5h   |
| MF-002   | Implement `destroy()` method with soft delete             | 1h     |
| SEC-002  | Validate job_key against JobRegistry::all() keys          | 0.5h   |

### P1 — High (Fix Before Release)
| ID       | Issue                                                    | Effort |
|----------|----------------------------------------------------------|--------|
| BUG-001  | Remove inline validation in store(), use FormRequest only | 0.5h   |
| SEC-003  | Add cron expression validation rule                       | 1h     |
| DBM-001  | Add SoftDeletes to Schedule model + migration             | 1h     |
| RT-001   | Consolidate triplicated route groups                      | 1h     |
| RT-002   | Implement trashedSchedule() or remove route               | 0.5h   |
| PERF-001 | Add pagination to index()                                 | 0.25h  |
| ARCH-007 | Add activityLog() calls to all CRUD operations            | 1h     |

### P2 — Medium (Fix in Next Sprint)
| ID       | Issue                                                    | Effort |
|----------|----------------------------------------------------------|--------|
| MF-005   | Create schedule dispatch Artisan command                  | 3h     |
| MF-004   | Implement proper edit() with schedule data loading        | 1h     |
| MF-003   | Implement proper show() with schedule details             | 1h     |
| BUG-004  | Add schedule() relationship to ScheduleRun                | 0.25h  |
| BUG-005  | Add runs() relationship to Schedule                       | 0.25h  |
| MF-007   | Create schedule run history view                          | 2h     |
| DBM-006  | Add last_run_at/next_run_at to fillable                   | 0.25h  |
| SEC-006  | Add activity logging throughout module                    | 1h     |

### P3 — Low (Technical Debt)
| ID       | Issue                                                    | Effort |
|----------|----------------------------------------------------------|--------|
| ARCH-004 | Convert SchedulerType to PHP 8.1+ native enum             | 0.5h   |
| ARCH-005 | Add event/listener pattern for schedule lifecycle          | 2h     |
| ARCH-006 | Make JobRegistry configurable                              | 1h     |
| MF-009   | Add tenant-side schedule management                        | 4h     |
| DBM-002  | Add SoftDeletes to ScheduleRun                             | 0.5h   |

---

## EFFORT ESTIMATION

| Priority | Items | Estimated Hours |
|----------|-------|----------------|
| P0       | 5     | 5h             |
| P1       | 7     | 5.25h          |
| P2       | 8     | 8.75h          |
| P3       | 5     | 8h             |
| **Total**| **25**| **27h**        |
