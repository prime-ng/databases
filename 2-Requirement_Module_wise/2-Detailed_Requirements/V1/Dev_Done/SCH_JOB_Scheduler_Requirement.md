# SCH_JOB — Scheduler Module
## Requirement Document v1.0

**Module Code:** SCH_JOB
**Module Type:** Cross-Layer (Prime + Tenant context, no dedicated tenant DB tables)
**Table Prefix:** `schedules`, `schedule_runs` (shared, no `sch_` prefix)
**RBS Reference:** Module SYS — System Administration (SYS1 — System Health Monitoring)
**Completion Status:** ~40%
**Document Date:** 2026-03-25

---

## 1. Module Overview

The Scheduler module is Prime-AI's background job management system. It provides a user interface for registering, viewing, and managing cron-based scheduled jobs that run across the platform. Jobs can be scoped to the Prime (central SaaS) layer or to individual tenant (school) contexts.

The module sits outside the tenant module hierarchy — it has no `rec_*` / `sch_*` / etc. table prefix, uses a shared `schedules` table, and is accessible from the central admin dashboard rather than a school's tenant dashboard.

**Core Value Proposition:** Platform administrators can schedule and monitor background tasks — billing report generation, PDF batch processing, notification dispatch, data archival — from a central UI without touching server cron files.

---

## 2. Business Context

Prime-AI runs several types of deferred or scheduled workloads that should not run synchronously during HTTP requests:

| Job Category | Examples |
|---|---|
| Billing & Finance | Monthly billing report generation, invoice PDF batching |
| LMS/Assessment | Batch homework grading, result PDF generation, quiz expiry |
| Notifications | Daily attendance SMS dispatch, fee reminder emails, event alerts |
| Maintenance | Database archival, tenant data purging, student count refresh |
| Analytics | Weekly skill gap recalculation, recommendation expiry sweep |
| Timetable | Scheduled constraint re-validation, substitution auto-assignment |

The Scheduler module provides a registry of all schedulable job types and a UI to create named schedule instances with cron expressions and optional payload configuration.

This maps to RBS SYS1.1.1.2: "Monitor background job queue (failed, pending jobs)."

---

## 3. Module Scope

### In Scope
- Job registry — static catalog of all schedulable job classes
- Schedule management — create named schedule entries with cron expressions
- Schedule run history — record each execution with status, duration, and error messages
- Schedule type differentiation — PRIME scope (central) vs TENANT scope (per-school)
- Cron validation and due-check service

### Out of Scope (Current Phase)
- Real-time system metrics dashboard (CPU, RAM, disk — RBS SYS1.1.1.1)
- Alert configuration for critical metric thresholds (RBS SYS1.1.2)
- API key management (RBS SYS2.1)
- Webhook configuration (RBS SYS2.1.2)
- Bulk data import/export wizards (RBS SYS3.1)
- Queue monitoring UI (failed/retried jobs)

---

## 4. Database Schema

The Scheduler module has NO dedicated DDL file. It uses two models that map to generic tables.

### 4.1 `schedules` Table

Stores the schedule definitions (cron configurations):

| Column | Type | Notes |
|---|---|---|
| `id` | INT UNSIGNED PK | |
| `name` | VARCHAR 255 | Display label for the schedule |
| `schedule_type` | VARCHAR | 'prime' or 'tenant' (from `SchedulerType` enum) |
| `tenant_id` | nullable | Scopes schedule to a specific tenant if type='tenant' |
| `job_key` | VARCHAR | Key from JobRegistry (e.g., 'prime_billing_report_job') |
| `payload` | JSON | Optional job parameters (cast to array) |
| `cron_expression` | VARCHAR | Standard cron syntax (e.g., '0 9 * * 1') |
| `is_active` | BOOLEAN | Whether the schedule is enabled |
| `created_at`, `updated_at` | TIMESTAMP | Standard audit |

**Note:** The `Schedule` model does NOT use `SoftDeletes`. This is a known gap — deleted schedules cannot be recovered.

**Note:** There are no `is_active`, `deleted_at`, or `created_by` columns per the standard table convention. This is a deviation from Prime-AI's DB conventions.

### 4.2 `schedule_runs` Table

Records each execution of a schedule:

| Column | Type | Notes |
|---|---|---|
| `id` | INT PK | Laravel default convention (no `$table` defined in model) |
| `schedule_id` | FK to `schedules` | Which schedule ran |
| `tenant_id` | nullable | If tenant-scoped, which tenant |
| `status` | VARCHAR | e.g., 'running', 'completed', 'failed' |
| `error_message` | TEXT | Error details on failure |
| `started_at` | DATETIME | Cast to datetime |
| `finished_at` | DATETIME | Cast to datetime |
| `duration_ms` | INT | Elapsed time in milliseconds |

**Note:** `ScheduleRun` uses the default Laravel table name convention (`schedule_runs`). No explicit `$table` is defined.

---

## 5. Functional Requirements

### 5.1 Job Registry

The `JobRegistry` service maintains a static registry of all schedulable job classes in the application. It serves as the single source of truth for what jobs can be scheduled.

**Current registered jobs:**

| Job Key | Class | Schedule Types Allowed |
|---|---|---|
| `tenant_test_job` | `App\Jobs\Tenant\TestJob` | ['tenant'] |
| `prime_test_job` | `App\Jobs\Prime\TestJob` | ['prime'] |
| `prime_billing_report_job` | `App\Jobs\Prime\BillingReportJob` | ['prime'] |

**Job contract (`SchedulableJob` interface):**
```php
interface SchedulableJob {
    public static function description(): string;
    public static function allowedScheduleTypes(): array;
}
```

All job classes must implement this interface. `JobRegistry::get($key)` validates the contract before returning the class.

`JobRegistry::forUi()` returns a formatted array with `key`, `label`, and `allowed_schedule_types` for the create-schedule dropdown.

### 5.2 Schedule CRUD

**Create Schedule:**
- Select job from registry dropdown (filtered by allowed schedule types)
- Enter display name
- Enter cron expression (validated as string max 255)
- Optionally enter JSON payload
- Set is_active flag

**List Schedules:**
- Show all schedules ordered by created_at desc
- Display name, job key, cron expression, is_active status

**Update Schedule:** Not yet implemented — `SchedulerController::update()` is an empty method body.

**Delete Schedule:** Not yet implemented — `SchedulerController::destroy()` is an empty method body.

### 5.3 Schedule Execution Service

`SchedulerService::dueSchedules()` returns all active schedules whose cron expression is currently due for execution:

- Queries all `is_active = true` schedules
- For each, calls `CronExpression::factory($schedule->cron_expression)->isDue()`
- Invalid cron expressions are logged as errors and skipped (defensive handling)

This method is intended to be called by a top-level Laravel console command that runs every minute via cron (`* * * * *`).

### 5.4 Schedule Type Context

`SchedulerType` is a non-backed PHP class (not a PHP 8.1 enum) with constants:

```php
class SchedulerType {
    const PRIME = 'prime';
    const TENANT = 'tenant';
}
```

- **PRIME** schedules run in the global application context with access to prime_db
- **TENANT** schedules run within a specific tenant's database context (requiring tenant initialization before job dispatch)

`Schedule::isPrime()` and `Schedule::isTenant()` helper methods check the `schedule_type` column.

---

## 6. Non-Functional Requirements

| Requirement | Specification |
|---|---|
| Authentication | Routes behind `auth, verified` middleware BUT no `Gate::authorize()` calls anywhere in `SchedulerController` — this is a critical security gap |
| Authorization | ZERO auth currently — entire controller is unprotected |
| Soft Deletes | NOT implemented on `Schedule` model — confirmed by unit test |
| Audit Trail | Not present |
| Cron Safety | `SchedulerService` defensively catches invalid cron expressions, logs them, and continues |

---

## 7. Controllers and Routes

### 7.1 Controller

**`SchedulerController`** (1 controller, no auth):

| Method | Status | Notes |
|---|---|---|
| `index()` | Complete | Lists schedules, no auth |
| `create()` | Complete | Calls `JobRegistry::forUi()`, no auth |
| `store(ScheduleRequest $request)` | Complete | Creates schedule, BUT also calls `$request->validate()` again (double validation) |
| `show($id)` | Stub | Returns generic view |
| `edit($id)` | Stub | Returns generic view |
| `update(Request $request, $id)` | Empty body | No implementation, no auth |
| `destroy($id)` | Empty body | No implementation, no auth |

### 7.2 Routes

Module routes file uses a resource route with the name prefix `scheduler`:

```php
Route::middleware(['auth', 'verified'])->group(function () {
    Route::resource('schedulers', SchedulerController::class)->names('scheduler');
});
```

The production tenant.php file also registers this under the `central.scheduler.schedule` name prefix based on the `store()` redirect:
`redirect()->route('central.scheduler.schedule.index')`

This naming mismatch is a known issue.

---

## 8. Models Inventory

| Model | Table | SoftDeletes | Key Notes |
|---|---|---|---|
| `Schedule` | `schedules` | No | Has `isPrime()` and `isTenant()` helper methods. Payload cast to array. |
| `ScheduleRun` | `schedule_runs` (convention) | No | No explicit `$table` property. Timestamps `started_at` and `finished_at` cast to datetime. No relationship back to `Schedule` model. |

**Missing relationships:**
- `Schedule` has no `hasMany(ScheduleRun::class)` relationship
- `ScheduleRun` has no `belongsTo(Schedule::class)` relationship

---

## 9. Services Inventory

| Service | Location | Purpose | Status |
|---|---|---|---|
| `JobRegistry` | `Modules\Scheduler\Services\JobRegistry` | Static catalog of schedulable jobs. `all()`, `get($key)`, `forUi()` | Complete |
| `SchedulerService` | `Modules\Scheduler\Services\SchedulerService` | `dueSchedules()` — returns schedules due to run | Complete (but no `runSchedule()` method) |

---

## 10. Identified Gaps and Issues

### 10.1 Critical Issues

| Issue | Impact |
|---|---|
| Zero `Gate::authorize()` calls in `SchedulerController` | Any authenticated user can view and create schedules, including tenant users who should have no access to system scheduler management |
| `update()` and `destroy()` methods are empty | Cannot edit or delete schedules via UI |
| `Schedule` model missing `SoftDeletes` | Deleted schedules are permanently gone with no recovery path |
| Double validation in `store()`: `ScheduleRequest` runs rules, then `$request->validate()` runs same rules again inline | Confusing, maintainability risk |

### 10.2 Architecture Gaps

| Gap | Description | Priority |
|---|---|---|
| No `runSchedule(Schedule $schedule)` method in `SchedulerService` | The service can identify due schedules but cannot execute them | CRITICAL |
| No Laravel console command integrating `SchedulerService` | Nothing currently calls `SchedulerService::dueSchedules()` | CRITICAL |
| `ScheduleRun` is never written to | No code creates `ScheduleRun` records during job execution | HIGH |
| No schedule run history UI | Even if runs were recorded, no view/route exists to display them | HIGH |
| `SchedulerType` is a constant class, not a PHP 8.1 backed enum | Cannot benefit from type safety, match expressions, or enum helpers | LOW |
| `Schedule::tenant_id` has no FK constraint or relationship defined | Cannot query which schedules belong to a specific tenant | MEDIUM |

### 10.3 Job Registry Coverage Gap

The registry currently covers only 3 jobs. The following platform jobs need to be registered once implemented:

| Planned Job Key | Purpose | Scope |
|---|---|---|
| `expire_recommendations_job` | Mark overdue student recommendations as EXPIRED | tenant |
| `fee_reminder_job` | Send fee payment reminder SMS/email to parents | tenant |
| `attendance_sms_job` | Send daily attendance SMS to parents | tenant |
| `pdf_batch_report_job` | Batch generate report card PDFs | tenant |
| `data_archival_job` | Archive old academic year data | prime/tenant |
| `skill_gap_recalculation_job` | Recalculate student skill gaps weekly | tenant |
| `timetable_constraint_validation_job` | Re-run constraint validation after bulk changes | tenant |

---

## 11. FormRequest

**`ScheduleRequest`** — Only FormRequest in the module:

- Handles both create (`required` fields) and update (`sometimes` fields)
- `prepareForValidation()` normalizes `is_active` checkbox to boolean
- `authorize()` always returns `true` — no auth check in FormRequest either

---

## 12. Testing

### Existing Test

**`tests/Unit/SchedulerModuleTest.php`** — Pest unit test (no database needed):

- Tests `Schedule` model: correct table name, no SoftDeletes, fillable fields, casts, `isPrime()` and `isTenant()` methods
- Tests `ScheduleRun` model: instantiable, fillable fields, datetime casts, default table name
- Tests `SchedulerController`: zero `Gate::authorize` calls (documents the security issue as a known fact)
- Tests architecture: all service/request/enum/contract classes exist

The tests deliberately document the zero-auth state (they assert `not->toContain('Gate::authorize')`) as a known audit finding.

### Tests Needed

- `SchedulerServiceTest` — `dueSchedules()` returns only active schedules whose cron is due
- `JobRegistryTest` — `get()` returns null for unregistered keys, validates SchedulableJob contract
- `SchedulerControllerAuthTest` — verify auth is enforced once Gate calls are added
- `CronExpressionTest` — invalid expressions are caught and logged

---

## 13. Development Work Remaining

### Priority 1 — Security
1. Add `Gate::authorize('admin.scheduler.viewAny')` to `index()` and `create()`
2. Add `Gate::authorize('admin.scheduler.create')` to `store()`
3. Add `Gate::authorize('admin.scheduler.update')` to `update()`
4. Add `Gate::authorize('admin.scheduler.delete')` to `destroy()`
5. Register scheduler permissions in the permission seeder

### Priority 2 — Complete CRUD
6. Implement `update(ScheduleRequest $request, Schedule $schedule)` — update name, cron_expression, payload, is_active
7. Implement `destroy(Schedule $schedule)` — soft-delete (requires adding SoftDeletes to model + migration)
8. Add `SoftDeletes` to `Schedule` model and add `deleted_at` column to `schedules` table
9. Implement `show(Schedule $schedule)` — display schedule details + run history

### Priority 3 — Execution Engine
10. Add `runSchedule(Schedule $schedule): ScheduleRun` to `SchedulerService`:
    - Look up job class via `JobRegistry::get($schedule->job_key)`
    - If tenant-scoped: initialize tenant context
    - Dispatch the job
    - Create and return a `ScheduleRun` record
11. Create `RunScheduledJobsCommand` (artisan console command):
    - Called every minute by server cron
    - Calls `SchedulerService::dueSchedules()`
    - For each due schedule: calls `runSchedule()`
    - Logs successes and failures
12. Add missing model relationships:
    - `Schedule::hasMany(ScheduleRun::class)`
    - `ScheduleRun::belongsTo(Schedule::class)`

### Priority 4 — UI Completion
13. Create schedule run history view (`schedule-run-history` blade)
14. Add run history tab to schedule show view
15. Add toggle status for schedule (enable/disable without deleting)

### Priority 5 — Job Coverage
16. Implement and register all platform jobs listed in Section 10.3
17. Each job must implement `SchedulableJob` interface
18. Add job to `JobRegistry::all()`

---

## 14. Permission Naming Convention (Target State)

Since the Scheduler is a central admin function (not tenant-specific), permissions should use the `admin.` prefix:

```
admin.scheduler.viewAny
admin.scheduler.create
admin.scheduler.update
admin.scheduler.delete
admin.scheduler.restore
admin.scheduler.forceDelete
admin.scheduler.run
```

---

## 15. Completion Criteria

The module is considered complete when:

1. All CRUD operations work with proper `Gate::authorize()` on every method
2. `Schedule` model uses `SoftDeletes`
3. `SchedulerService::runSchedule()` dispatches jobs and creates `ScheduleRun` records
4. `RunScheduledJobsCommand` artisan command works and is registered in Laravel scheduler
5. Run history is visible in the UI (per-schedule list of past runs with status/duration/errors)
6. Toggle status works (enable/disable a schedule without deleting)
7. All current Prime-AI deferred jobs are registered in `JobRegistry`
8. Minimum 15 unit tests covering service logic and registry behavior
9. Security tests confirm proper auth enforcement
