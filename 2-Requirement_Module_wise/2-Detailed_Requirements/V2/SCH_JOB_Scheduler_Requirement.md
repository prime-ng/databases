# Scheduler Module — Requirement Specification Document v2
**Version:** 2.0  |  **Date:** 2026-03-26  |  **Author:** Claude Code (Automated)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** SCH_JOB  |  **Module Path:** `Modules/Scheduler/`
**Module Type:** Other  |  **Database:** `N/A — Uses system tables`
**Table Prefix:** `N/A`  |  **Processing Mode:** FULL
**RBS Reference:** SYS (System Administration)  |  **RBS Version:** v4.0
**V1 Baseline:** `2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Done/SCH_JOB_Scheduler_Requirement.md`
**Gap Analysis:** `3-Project_Planning/2-Gap_Analysis/2-Modules_Wise/2026Mar22/Scheduler_Deep_Gap_Analysis.md`
**Generation Batch:** 1/10

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Business Context](#2-business-context)
3. [Module Scope](#3-module-scope)
4. [Database Schema](#4-database-schema)
5. [Functional Requirements](#5-functional-requirements)
6. [Non-Functional Requirements](#6-non-functional-requirements)
7. [Controllers and Routes](#7-controllers-and-routes)
8. [Models Inventory](#8-models-inventory)
9. [Services Inventory](#9-services-inventory)
10. [Views Inventory](#10-views-inventory)
11. [FormRequests Inventory](#11-formrequests-inventory)
12. [Events, Listeners, Commands](#12-events-listeners-commands)
13. [Testing Requirements](#13-testing-requirements)
14. [Future / Out-of-Scope Suggestions](#14-future--out-of-scope-suggestions)
15. [Permissions and RBAC](#15-permissions-and-rbac)
16. [Completion Criteria and Effort](#16-completion-criteria-and-effort)

---

## 1. Module Overview

### 1.1 Purpose

The Scheduler module is Prime-AI's background job management system. It provides a central administrative interface for registering, configuring, and monitoring cron-based scheduled jobs that execute across the platform. Jobs can be scoped to the **PRIME** context (central SaaS operations) or the **TENANT** context (per-school operations that run inside a specific tenant's database context).

The module is classified as type **Other** — it has no dedicated `sch_*` table prefix, has no per-tenant DB schema, and is accessed exclusively from the central admin dashboard. It lives in `Modules/Scheduler/` following the `nwidart/laravel-modules v12.0` convention.

### 1.2 Current Completion Status: ~40%

| Sub-Area | Status | Notes |
|---|---|---|
| Job Registry Service | ✅ Implemented | 3 jobs registered, contract enforced |
| Schedule Create (UI + Store) | 🟡 Partial | Works but has double-validation bug, no auth |
| Schedule List | 🟡 Partial | Loads all rows (no pagination), no auth |
| Schedule Show | ❌ Not Started | Returns generic view, no data loaded |
| Schedule Edit / Update | ❌ Not Started | Edit returns generic view; update() is empty |
| Schedule Delete | ❌ Not Started | destroy() is completely empty |
| Schedule Toggle Status | ❌ Not Started | UI has button but no route/method |
| Schedule Run History UI | ❌ Not Started | ScheduleRun model exists, no view/route |
| Schedule Execution Engine | ❌ Not Started | SchedulerService cannot dispatch jobs |
| Artisan Command | ❌ Not Started | No console command registered |
| Authorization / RBAC | ❌ Not Started | Zero Gate::authorize calls in controller |
| Soft Deletes | ❌ Not Started | Missing SoftDeletes on both models |
| Audit Trail | ❌ Not Started | No activityLog() calls anywhere |
| Permission Seeder | ❌ Not Started | No permissions registered |

### 1.3 Architecture Classification

The Scheduler module is a **cross-layer** module that operates in the central (prime) domain. It is loaded by the global `web.php` routes file and uses the `prime_db` connection for the `schedules` and `schedule_runs` tables. The `Modules/Scheduler/routes/web.php` file defines only a resource route stub — the actual registration in the central domain occurs via the global `web.php` (routes are currently triplicated across the global file — a known bug).

---

## 2. Business Context

### 2.1 Why This Module Exists

Prime-AI handles numerous workloads that must not execute during synchronous HTTP requests due to their duration, resource intensity, or need for database-context switching. Examples include:

- Monthly billing cycle report generation (across all tenants)
- Student fee reminder SMS/email batches sent by each school
- Nightly attendance consolidation for analytics
- Weekly skill gap recalculation (LXP module)
- PDF batch generation for report cards (HPC module)
- Data archival and purging at year-end

Without a scheduler management UI, a platform operator must SSH into the server, edit system cron files, and restart daemons to manage these tasks. The Scheduler module eliminates this by providing a web UI backed by Laravel's Artisan scheduling system.

### 2.2 Stakeholders

| Stakeholder | Role |
|---|---|
| Prime Admin (Super Admin) | Creates, edits, enables/disables, and monitors all schedules |
| Platform Ops Team | Reviews run history, investigates failures, adjusts cron expressions |
| Module Developers | Registers new job classes via `JobRegistry` and `SchedulableJob` contract |
| School Admin (Tenant User) | Indirectly affected — tenant-scoped jobs run in their school's context |

### 2.3 RBS Mapping

| RBS Reference | Description | Coverage |
|---|---|---|
| SYS1.1.1.2 | Monitor background job queue (failed, pending jobs) | Partial — run history planned |
| SYS1.1.1.3 | Manage scheduled background tasks | Core scope |
| SYS1.1.2.1 | Alert on job failure | Out of scope (V2 suggestion) |

### 2.4 Job Category Reference

| Job Category | Example Jobs | Schedule Type |
|---|---|---|
| Billing & Finance | Monthly billing report PDF generation, invoice batching | prime |
| LMS / Assessment | Batch homework grading, result PDF generation, quiz expiry | tenant |
| Notifications | Daily attendance SMS, fee reminder emails, event alerts | tenant |
| Maintenance | Database archival, student count refresh, purge deleted records | prime / tenant |
| Analytics | Weekly skill gap recalculation, recommendation expiry sweep | tenant |
| Timetable | Constraint re-validation, substitution auto-assignment | tenant |

---

## 3. Module Scope

### 3.1 In Scope (V2 Target)

- Job registry — static catalog of all schedulable job classes with `SchedulableJob` contract enforcement
- Schedule CRUD — complete create, read, update, soft-delete for schedule configurations
- Toggle status — enable or disable a schedule without deleting it
- Schedule execution engine — `SchedulerService::runSchedule()` method + `ScheduleDispatchCommand` artisan command
- Schedule run history — record and display every execution with status, duration, and error output
- Authorization — `SchedulePolicy` with `Gate::authorize()` on every controller method
- Soft deletes — `SoftDeletes` on both `Schedule` and `ScheduleRun` models
- Audit trail — `sys_activity_logs` entries for all CRUD operations
- Permission seeder — seed `admin.scheduler.*` permissions into Spatie permission tables
- Job key validation — validate `job_key` input against `JobRegistry::all()` keys
- Cron expression validation — validate cron syntax before saving
- Pagination — paginate schedule list to prevent full-table load
- Route consolidation — eliminate triplicated route registration in global `web.php`

### 3.2 Out of Scope (Current Phase)

- Real-time system health metrics (CPU, RAM, disk) — RBS SYS1.1.1.1
- Alert/notification configuration for job failure thresholds — RBS SYS1.1.2
- Queue monitoring UI for Laravel Horizon or failed job queue inspection
- API key management and webhook configuration — RBS SYS2.1
- Bulk data import/export wizards — RBS SYS3.1
- Tenant-side schedule management UI (tenant admins creating their own schedules)
- Auto-discovery of job classes from the filesystem

---

## 4. Database Schema

The Scheduler module uses two tables in the **prime_db** database (no tenant-DB schema). Neither table uses a module-specific prefix. Both tables must be updated via migrations to reach the V2 target state.

### 4.1 `schedules` Table

**Current state (from migration `2026_01_02_112016_create_schedules_table.php`):**

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | BIGINT UNSIGNED PK | No | Auto-increment |
| `name` | VARCHAR 255 | No | Display label |
| `schedule_type` | ENUM('prime','tenant') | No | Indexed |
| `tenant_id` | VARCHAR | Yes | Indexed; no FK to tenants table |
| `job_key` | VARCHAR 255 | No | |
| `payload` | JSON | Yes | |
| `cron_expression` | VARCHAR 255 | No | |
| `is_active` | BOOLEAN | No | Default true |
| `last_run_at` | TIMESTAMP | Yes | Exists in migration, NOT in model fillable |
| `next_run_at` | TIMESTAMP | Yes | Exists in migration, NOT in model fillable |
| `created_at` | TIMESTAMP | Yes | |
| `updated_at` | TIMESTAMP | Yes | |

**Missing columns (require new migration):**

| Column | Type | Reason |
|---|---|---|
| `deleted_at` | TIMESTAMP NULL | Platform standard — soft deletes |
| `created_by` | BIGINT UNSIGNED NULL | Platform standard — audit ownership |
| `failure_count` | INT UNSIGNED | View references `$schedule->failure_count` but column doesn't exist |

**Design note:** The `tenant_id` column stores the string tenant identifier. There is no foreign key constraint to a tenants table. The relationship is informal. This is a known architectural limitation.

**Proposed V2 target DDL:**

```sql
CREATE TABLE `schedules` (
  `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`             VARCHAR(255)    NOT NULL,
  `schedule_type`    ENUM('prime','tenant') NOT NULL,
  `tenant_id`        VARCHAR(255)    NULL,
  `job_key`          VARCHAR(255)    NOT NULL,
  `payload`          JSON            NULL,
  `cron_expression`  VARCHAR(255)    NOT NULL,
  `is_active`        TINYINT(1)      NOT NULL DEFAULT 1,
  `failure_count`    INT UNSIGNED    NOT NULL DEFAULT 0,
  `last_run_at`      TIMESTAMP       NULL,
  `next_run_at`      TIMESTAMP       NULL,
  `created_by`       BIGINT UNSIGNED NULL,
  `created_at`       TIMESTAMP       NULL,
  `updated_at`       TIMESTAMP       NULL,
  `deleted_at`       TIMESTAMP       NULL,
  PRIMARY KEY (`id`),
  INDEX `schedules_schedule_type_index` (`schedule_type`),
  INDEX `schedules_tenant_id_index` (`tenant_id`),
  INDEX `schedules_is_active_index` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 4.2 `schedule_runs` Table

**Current state (from migration `2026_01_02_155143_create_schedule_runs_table.php`):**

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | BIGINT UNSIGNED PK | No | Auto-increment |
| `schedule_id` | BIGINT UNSIGNED FK | No | References `schedules.id` RESTRICT ON DELETE |
| `tenant_id` | VARCHAR | Yes | Indexed |
| `status` | ENUM('running','success','failed') | No | Indexed |
| `error_message` | TEXT | Yes | |
| `started_at` | TIMESTAMP | No | |
| `finished_at` | TIMESTAMP | Yes | |
| `duration_ms` | INT | Yes | |
| `created_at` | TIMESTAMP | Yes | |
| `updated_at` | TIMESTAMP | Yes | |

**Missing columns (require new migration):**

| Column | Type | Reason |
|---|---|---|
| `deleted_at` | TIMESTAMP NULL | Platform standard — soft deletes |
| `created_by` | BIGINT UNSIGNED NULL | Platform standard |
| `output` | LONGTEXT NULL | Store job stdout/output for debugging |
| `attempt` | TINYINT UNSIGNED | Track retry attempt number |

**Proposed V2 target DDL:**

```sql
CREATE TABLE `schedule_runs` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `schedule_id`    BIGINT UNSIGNED NOT NULL,
  `tenant_id`      VARCHAR(255)    NULL,
  `status`         ENUM('running','success','failed') NOT NULL,
  `error_message`  TEXT            NULL,
  `output`         LONGTEXT        NULL,
  `attempt`        TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `started_at`     TIMESTAMP       NOT NULL,
  `finished_at`    TIMESTAMP       NULL,
  `duration_ms`    INT             NULL,
  `created_by`     BIGINT UNSIGNED NULL,
  `created_at`     TIMESTAMP       NULL,
  `updated_at`     TIMESTAMP       NULL,
  `deleted_at`     TIMESTAMP       NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_schedule_runs_schedule_id` FOREIGN KEY (`schedule_id`) REFERENCES `schedules` (`id`) ON DELETE RESTRICT,
  INDEX `schedule_runs_tenant_id_index` (`tenant_id`),
  INDEX `schedule_runs_status_index` (`status`),
  INDEX `schedule_runs_started_at_index` (`started_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 4.3 Required Migrations (V2)

| Migration Name | Action |
|---|---|
| `add_soft_deletes_to_schedules_table` | Add `deleted_at`, `created_by`, `failure_count` to `schedules` |
| `add_soft_deletes_to_schedule_runs_table` | Add `deleted_at`, `created_by`, `output`, `attempt` to `schedule_runs` |

---

## 5. Functional Requirements

Status legend: ✅ Implemented | 🟡 Partial | ❌ Not Started | 🆕 New in V2

### 5.1 Job Registry (FR-JR)

**FR-JR-01** ✅ — `JobRegistry::all()` returns an associative array mapping job key strings to fully-qualified job class names. Currently returns 3 jobs: `tenant_test_job`, `prime_test_job`, `prime_billing_report_job`.

**FR-JR-02** ✅ — `JobRegistry::get(string $jobKey)` validates that the returned class implements `Modules\Scheduler\Contracts\SchedulableJob`. Returns `null` for unregistered keys or non-compliant classes.

**FR-JR-03** ✅ — `JobRegistry::forUi()` returns an array of `['key', 'label', 'allowed_schedule_types']` entries derived from `SchedulableJob::description()` and `SchedulableJob::allowedScheduleTypes()`.

**FR-JR-04** 🆕 — Every job class used in the platform that should be schedulable MUST be added to `JobRegistry::all()`. V2 target registry must include at minimum:

| Job Key | Planned Job Class | Scope |
|---|---|---|
| `tenant_test_job` | `App\Jobs\Tenant\TestJob` | tenant |
| `prime_test_job` | `App\Jobs\Prime\TestJob` | prime |
| `prime_billing_report_job` | `App\Jobs\Prime\BillingReportJob` | prime |
| `expire_recommendations_job` | `App\Jobs\Tenant\ExpireRecommendationsJob` | tenant |
| `fee_reminder_job` | `App\Jobs\Tenant\FeeReminderJob` | tenant |
| `attendance_sms_job` | `App\Jobs\Tenant\AttendanceSmsJob` | tenant |
| `pdf_batch_report_job` | `App\Jobs\Tenant\PdfBatchReportJob` | tenant |
| `data_archival_job` | `App\Jobs\Prime\DataArchivalJob` | prime/tenant |
| `skill_gap_recalculation_job` | `App\Jobs\Tenant\SkillGapRecalculationJob` | tenant |
| `timetable_constraint_validation_job` | `App\Jobs\Tenant\TimetableConstraintValidationJob` | tenant |

**FR-JR-05** 🆕 — `SchedulableJob` interface contract must remain unchanged. All new job classes MUST implement `description(): string` and `allowedScheduleTypes(): array`.

**FR-JR-06** 🆕 — `SchedulerType` class MUST be converted from a constant-class to a PHP 8.1 native backed enum: `enum SchedulerType: string { case PRIME = 'prime'; case TENANT = 'tenant'; }`. All referencing code must be updated accordingly.

### 5.2 Schedule CRUD (FR-CRUD)

**FR-CRUD-01** ✅ — List schedules ordered by `created_at` DESC.

**FR-CRUD-02** ❌ [P0 SECURITY GAP] — Every controller method MUST call `Gate::authorize()` with the corresponding permission before any business logic executes. Currently zero `Gate::authorize()` calls exist in `SchedulerController`. This is a CRITICAL security vulnerability — any authenticated user (including tenant school staff) can view, create, and access all schedule management pages.

**FR-CRUD-03** 🟡 — Create schedule: select job from registry dropdown, enter name, enter cron expression, optionally enter JSON payload, set `is_active`. Currently working but with double-validation bug (see FR-CRUD-12) and no authorization.

**FR-CRUD-04** ❌ — Create schedule form MUST enforce that `job_key` is validated against `JobRegistry::all()` keys. Currently `'job_key' => 'required|string'` accepts any arbitrary string.

**FR-CRUD-05** ❌ — Cron expression MUST be validated as a syntactically valid cron expression before saving. Currently only `'required|string'` — invalid cron strings pass validation and are silently skipped during execution.

**FR-CRUD-06** ❌ — Payload MUST be validated as valid JSON when not empty. Currently `json_decode($data['payload'], true)` is called without error handling; invalid JSON returns null silently.

**FR-CRUD-07** ❌ — `update()` method in `SchedulerController` is completely empty. Must be implemented to update: `name`, `cron_expression`, `payload`, `is_active`, with same validations as `store()`.

**FR-CRUD-08** ❌ — `edit()` method returns `scheduler::edit` generic view without loading the `Schedule` model. Must load and pass the schedule to the view.

**FR-CRUD-09** ❌ — `destroy()` method in `SchedulerController` is completely empty. Must be implemented as a soft delete (`$schedule->delete()`). Requires `SoftDeletes` trait on `Schedule` model and `deleted_at` migration.

**FR-CRUD-10** ❌ — `show()` method returns `scheduler::show` generic view without loading the `Schedule` model or its run history. Must load the schedule, eager-load recent runs, and render a proper detail view.

**FR-CRUD-11** ❌ — Toggle status: a PATCH endpoint `schedulers/{schedule}/toggle` must enable or disable a schedule (`is_active` flip) via AJAX/form. The index view (`schedule/index.blade.php`) already renders an Enable/Disable button — the action URL and route are missing.

**FR-CRUD-12** ❌ [BUG-001] — Double validation in `store()`: the method accepts `ScheduleRequest $request` (which already runs validation via FormRequest) but then calls `$request->validate([...])` again with different inline rules. The inline validation overrides the FormRequest. Fix: remove the inline `$request->validate()` call entirely and rely solely on `ScheduleRequest`.

**FR-CRUD-13** ❌ — `store()` hardcodes `'schedule_type' => 'prime'` for all new schedules. The form must allow selection of schedule type (`prime` or `tenant`). When `tenant` is selected, a tenant selector must appear and `tenant_id` must be saved.

**FR-CRUD-14** 🆕 — Soft restore: a POST endpoint `schedulers/{id}/restore` (accessible from the trash view) must restore a soft-deleted schedule.

**FR-CRUD-15** 🆕 — Trash/trashed view: list soft-deleted schedules with restore and force-delete actions. The module already has a `schedule/trash.blade.php` view (currently copy-pasted from Dropdown module — incorrect content) and the routes in `web.php` reference a `trashedSchedule()` method that does not exist.

**FR-CRUD-16** ❌ [RT-002] — The `trashedSchedule` route in `web.php` points to a non-existent controller method. Must either implement `SchedulerController::trashedSchedule()` or remove the route.

**FR-CRUD-17** 🆕 — Pagination: `index()` currently calls `Schedule::orderBy('created_at', 'desc')->get()` which loads all rows. Must use `->paginate(15)` with search/filter support.

**FR-CRUD-18** 🆕 — Search and filter: the index view already renders a search bar and status dropdown filter. The controller must implement these filters: search by `name` or `job_key`, filter by `is_active` status.

### 5.3 Schedule Execution Engine (FR-EXE)

**FR-EXE-01** ❌ [CRITICAL] — `SchedulerService` MUST have a `runSchedule(Schedule $schedule): ScheduleRun` method that:
  1. Looks up the job class via `JobRegistry::get($schedule->job_key)`
  2. If the job class is null, creates a `ScheduleRun` record with status `failed` and an appropriate error message
  3. If `schedule->isTenant()`, initializes the tenant context (via `stancl/tenancy` tenant initialization) before dispatching
  4. Dispatches the job to the queue
  5. Creates and returns a `ScheduleRun` record with status `running`, `started_at`, and relevant metadata
  6. Updates `schedule->last_run_at` to `now()` and increments `failure_count` on failure

**FR-EXE-02** ❌ [CRITICAL] — An Artisan console command `scheduler:dispatch` (class `ScheduleDispatchCommand`) MUST be created:
  - Runs every minute when registered in the Laravel application schedule
  - Calls `SchedulerService::dueSchedules()` to retrieve all active, currently-due schedules
  - For each due schedule, calls `SchedulerService::runSchedule($schedule)`
  - Logs successes and failures via `logger()`
  - Handles exceptions per schedule gracefully (one failure must not abort the entire run)

**FR-EXE-03** ❌ — `ScheduleDispatchCommand` MUST be registered in `SchedulerServiceProvider::registerCommandSchedules()`:
  ```php
  $schedule->command('scheduler:dispatch')->everyMinute()->withoutOverlapping();
  ```

**FR-EXE-04** ❌ — `SchedulerService` MUST update `Schedule::next_run_at` after each execution by computing the next due time from the cron expression.

**FR-EXE-05** ❌ — `SchedulerService::runSchedule()` MUST create a `ScheduleRun` record with final status `success` or `failed`, `finished_at`, `duration_ms`, and `error_message` (on failure). Currently `ScheduleRun` model is never written to by any code.

**FR-EXE-06** 🆕 — Manual trigger: a POST endpoint `schedulers/{schedule}/run` must allow an authorized admin to trigger a schedule immediately on-demand (outside of its cron schedule). This bypasses the cron-due check and directly calls `SchedulerService::runSchedule()`.

### 5.4 Schedule Run History (FR-HIST)

**FR-HIST-01** ❌ — A run history view MUST be accessible from the schedule list (the "Runs" button in `index.blade.php` currently has an empty `href=""`). Route: `schedulers/{schedule}/runs`.

**FR-HIST-02** ❌ — The run history view must display: `status` (badge), `started_at`, `finished_at`, `duration_ms` (human-readable), `tenant_id` (if tenant-scoped), `error_message` (on failure), `attempt` number.

**FR-HIST-03** ❌ — Run history must be paginated (15 per page), ordered by `started_at` DESC.

**FR-HIST-04** 🆕 — Run history must display aggregate stats at the top: total runs, success count, failure count, average duration.

**FR-HIST-05** 🆕 — On failure status, the full `error_message` and (where stored) `output` must be expandable/collapsible in the UI.

### 5.5 Authorization and Security (FR-AUTH)

**FR-AUTH-01** ❌ [P0 — CRITICAL] — A `SchedulePolicy` class MUST be created at `Modules/Scheduler/app/Policies/SchedulePolicy.php` with methods: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`. This policy must be registered in `AppServiceProvider` via `Gate::policy(Schedule::class, SchedulePolicy::class)`.

**FR-AUTH-02** ❌ [P0 — CRITICAL] — `SchedulerController` MUST call `Gate::authorize()` at the top of every public method before any query or view rendering:

| Method | Required Gate Call |
|---|---|
| `index()` | `Gate::authorize('viewAny', Schedule::class)` |
| `create()` | `Gate::authorize('create', Schedule::class)` |
| `store()` | `Gate::authorize('create', Schedule::class)` |
| `show($schedule)` | `Gate::authorize('view', $schedule)` |
| `edit($schedule)` | `Gate::authorize('update', $schedule)` |
| `update($request, $schedule)` | `Gate::authorize('update', $schedule)` |
| `destroy($schedule)` | `Gate::authorize('delete', $schedule)` |
| `trashedSchedule()` | `Gate::authorize('viewAny', Schedule::class)` |
| `toggleStatus($schedule)` | `Gate::authorize('update', $schedule)` |
| `run($schedule)` | `Gate::authorize('admin.scheduler.run', $schedule)` |
| `runs($schedule)` | `Gate::authorize('view', $schedule)` |

**FR-AUTH-03** ❌ — `ScheduleRequest::authorize()` currently returns `true` unconditionally. It must be updated to check the appropriate policy action (`create` or `update` depending on HTTP method).

**FR-AUTH-04** 🆕 — Route middleware must be updated to include the `verified` middleware group AND a specific role/permission middleware guard to restrict access to Prime Admins only. Tenant-context users must never reach scheduler routes.

**FR-AUTH-05** ❌ — `job_key` input MUST be validated against `array_keys(JobRegistry::all())` to prevent arbitrary class injection. A custom validation rule or `in:` rule must be used.

**FR-AUTH-06** ❌ — Payload input MUST have a maximum size limit (e.g., `max:10000` characters) to prevent excessively large JSON storage.

**FR-AUTH-07** ❌ — No audit trail currently exists. All CRUD operations (create, update, delete, restore, run) MUST call `activityLog()` following the platform's `sys_activity_logs` convention.

### 5.6 Route Management (FR-ROUTE)

**FR-ROUTE-01** ❌ [RT-001] — Scheduler routes are currently registered three times in the global `web.php` (at lines 274, 516, and 841). These duplicate registrations create conflicting named routes. The global `web.php` registrations must be consolidated to a single registration block, OR the module's own `routes/web.php` must be used as the canonical registration and global `web.php` entries removed.

**FR-ROUTE-02** ❌ [RT-002] — The `trashedSchedule` named route registered in global `web.php` points to a method that does not exist on `SchedulerController`. Must implement `trashedSchedule()` or remove the route entry.

**FR-ROUTE-03** ❌ [RT-003] — The module's own `Modules/Scheduler/routes/web.php` defines a resource route with the name prefix `scheduler` but the global `web.php` uses `central.scheduler.schedule.*`. These naming schemes are inconsistent. A single canonical naming scheme must be agreed upon and applied consistently.

**FR-ROUTE-04** ❌ — Route comment in global `web.php` says "School Timing Profile Routes" — a copy-paste error from another module. Must be corrected.

**FR-ROUTE-05** 🆕 — Additional routes needed for V2:

| Route | HTTP | Controller Method | Name |
|---|---|---|---|
| `schedulers/{schedule}/toggle` | PATCH | `toggleStatus` | `scheduler.toggle` |
| `schedulers/{schedule}/run` | POST | `run` | `scheduler.run` |
| `schedulers/{schedule}/runs` | GET | `runs` | `scheduler.runs` |
| `schedulers/trashed` | GET | `trashedSchedule` | `scheduler.trashed` |
| `schedulers/{id}/restore` | POST | `restore` | `scheduler.restore` |

---

## 6. Non-Functional Requirements

### 6.1 Security

| Requirement | Status | Specification |
|---|---|---|
| Authentication | ✅ | Routes behind `auth, verified` middleware |
| Authorization | ❌ | ZERO Gate::authorize calls — P0 critical gap. Must add SchedulePolicy and gate checks on all methods. |
| Input Validation — job_key | ❌ | Must validate against JobRegistry::all() keys |
| Input Validation — cron | ❌ | Must validate as a valid cron expression |
| Input Validation — payload | ❌ | Must validate as valid JSON; must enforce max size |
| Tenant isolation | ❌ | Tenant users must never access scheduler routes |
| Audit trail | ❌ | All operations must be logged via sys_activity_logs |

### 6.2 Data Integrity

| Requirement | Status | Specification |
|---|---|---|
| Soft deletes — Schedule | ❌ | SoftDeletes trait + deleted_at column missing from Schedule model and migration |
| Soft deletes — ScheduleRun | ❌ | SoftDeletes trait + deleted_at column missing from ScheduleRun model and migration |
| created_by — Schedule | ❌ | Missing from fillable and migration |
| created_by — ScheduleRun | ❌ | Missing from fillable and migration |
| failure_count column | ❌ | Index view references `$schedule->failure_count` but column does not exist in migration or model fillable |
| last_run_at / next_run_at in fillable | ❌ | Both columns exist in migration but are NOT in `Schedule::$fillable`, preventing mass-assignment |

### 6.3 Performance

| Requirement | Status | Specification |
|---|---|---|
| Paginated index | ❌ | Must use ->paginate(15). Currently loads all schedules with ->get() |
| dueSchedules() query | 🟡 | Loads all active schedules then filters in PHP. Acceptable for current scale; improve when schedule count > 500 |

### 6.4 Code Quality

| Requirement | Status | Specification |
|---|---|---|
| Business logic in service layer | ❌ | store() contains JSON parsing and model creation. Must move to SchedulerService::createSchedule() |
| SchedulerService used by controller | ❌ | Service is never called by controller; it is orphaned code |
| PHP 8.1+ enum | ❌ | SchedulerType uses class constants; must be converted to backed enum |
| Explicit $table on ScheduleRun | ❌ | Best practice: declare protected $table = 'schedule_runs' explicitly |
| registerCommands() in ServiceProvider | ❌ | ScheduleDispatchCommand must be added to registerCommands() array |
| View templates — copy-paste errors | ❌ | edit.blade.php and trash.blade.php have wrong content (copied from Dropdown module) |

### 6.5 Reliability

| Requirement | Specification |
|---|---|
| Cron safety | SchedulerService::isDue() correctly catches invalid expressions and logs them. This behavior MUST be preserved. |
| Per-schedule error isolation | A failure in one scheduled job must not prevent other due jobs from running |
| Execution overlap protection | ScheduleDispatchCommand must use withoutOverlapping() when registered in the kernel |

---

## 7. Controllers and Routes

### 7.1 Current Controller Inventory

**File:** `Modules/Scheduler/app/Http/Controllers/SchedulerController.php`

| Method | Signature | Status | Issues |
|---|---|---|---|
| `index()` | `index(): View` | 🟡 | No auth, no pagination, no search/filter |
| `create()` | `create(): View` | 🟡 | No auth |
| `store()` | `store(ScheduleRequest $request): RedirectResponse` | 🟡 | No auth, double validation (BUG-001), hardcoded schedule_type='prime', no job_key validation, no JSON validation |
| `show()` | `show($id): View` | ❌ | No auth, returns generic `scheduler::show` view, no model loaded |
| `edit()` | `edit($id): View` | ❌ | No auth, returns generic `scheduler::edit` view, no model loaded |
| `update()` | `update(Request $request, $id)` | ❌ | Completely empty body, no auth |
| `destroy()` | `destroy($id)` | ❌ | Completely empty body, no auth |

**Missing methods (to be added):**

| Method | Signature | Priority |
|---|---|---|
| `trashedSchedule()` | `trashedSchedule(): View` | P1 |
| `restore()` | `restore(int $id): RedirectResponse` | P1 |
| `toggleStatus()` | `toggleStatus(Schedule $schedule): JsonResponse` | P1 |
| `run()` | `run(Schedule $schedule): RedirectResponse` | P2 |
| `runs()` | `runs(Schedule $schedule): View` | P2 |

### 7.2 Target Route Table (V2)

All routes must be within a single middleware group: `['auth', 'verified', 'role:super-admin|prime-admin']`.

| HTTP | URI | Controller Method | Name | Auth Required |
|---|---|---|---|---|
| GET | `/schedulers` | `index` | `scheduler.index` | viewAny |
| GET | `/schedulers/create` | `create` | `scheduler.create` | create |
| POST | `/schedulers` | `store` | `scheduler.store` | create |
| GET | `/schedulers/{schedule}` | `show` | `scheduler.show` | view |
| GET | `/schedulers/{schedule}/edit` | `edit` | `scheduler.edit` | update |
| PUT/PATCH | `/schedulers/{schedule}` | `update` | `scheduler.update` | update |
| DELETE | `/schedulers/{schedule}` | `destroy` | `scheduler.destroy` | delete |
| GET | `/schedulers/trashed` | `trashedSchedule` | `scheduler.trashed` | viewAny |
| POST | `/schedulers/{id}/restore` | `restore` | `scheduler.restore` | restore |
| PATCH | `/schedulers/{schedule}/toggle` | `toggleStatus` | `scheduler.toggle` | update |
| POST | `/schedulers/{schedule}/run` | `run` | `scheduler.run` | admin.scheduler.run |
| GET | `/schedulers/{schedule}/runs` | `runs` | `scheduler.runs` | view |

### 7.3 API Routes

**File:** `Modules/Scheduler/routes/api.php` (currently empty)

No REST API endpoints exist. For V2, no API endpoints are required (the scheduler is a prime-admin-only feature, not tenant-facing).

---

## 8. Models Inventory

### 8.1 `Schedule` Model

**File:** `Modules/Scheduler/app/Models/Schedule.php`

**Current state:**
- Table: `schedules` (explicitly declared)
- SoftDeletes: NOT present — `use SoftDeletes` trait is missing
- Fillable: `name`, `schedule_type`, `tenant_id`, `job_key`, `payload`, `cron_expression`, `is_active`
- Missing from fillable: `last_run_at`, `next_run_at`, `failure_count`, `created_by`
- Casts: `payload => 'array'`, `is_active => 'boolean'`
- Helper methods: `isPrime(): bool`, `isTenant(): bool`
- Relationships: NONE defined

**Required V2 changes:**
- Add `use SoftDeletes;` trait (and import `Illuminate\Database\Eloquent\SoftDeletes`)
- Add `last_run_at`, `next_run_at`, `failure_count`, `created_by`, `deleted_at` to `$fillable`
- Add casts: `last_run_at => 'datetime'`, `next_run_at => 'datetime'`
- Add `runs()` relationship: `return $this->hasMany(ScheduleRun::class);`
- Add scope: `scopeActive($query)` → `$query->where('is_active', true)`
- Add scope: `scopePrime($query)` → `$query->where('schedule_type', SchedulerType::PRIME->value)`
- Add scope: `scopeTenant($query)` → `$query->where('schedule_type', SchedulerType::TENANT->value)`

### 8.2 `ScheduleRun` Model

**File:** `Modules/Scheduler/app/Models/ScheduleRun.php`

**Current state:**
- Table: NOT explicitly declared (`$table` property missing — relies on Laravel convention resolving to `schedule_runs`)
- SoftDeletes: NOT present
- Fillable: `schedule_id`, `tenant_id`, `status`, `error_message`, `started_at`, `finished_at`, `duration_ms`
- Missing from fillable: `output`, `attempt`, `created_by`
- Casts: `started_at => 'datetime'`, `finished_at => 'datetime'`
- Missing cast: `duration_ms` is integer but not cast
- Relationships: NONE defined

**Required V2 changes:**
- Add `protected $table = 'schedule_runs';` explicitly
- Add `use SoftDeletes;` trait
- Add `output`, `attempt`, `created_by`, `deleted_at` to `$fillable`
- Add cast: `duration_ms => 'integer'`
- Add `schedule()` relationship: `return $this->belongsTo(Schedule::class);`

---

## 9. Services Inventory

### 9.1 `JobRegistry` Service

**File:** `Modules/Scheduler/app/Services/JobRegistry.php`
**Status:** ✅ Architecture sound, 🟡 incomplete job coverage

| Method | Status | Notes |
|---|---|---|
| `all(): array` | ✅ | Returns 3 job entries. Must grow to 10+ in V2. |
| `get(string $jobKey): ?string` | ✅ | Validates SchedulableJob contract before returning. Returns null for unknown keys or non-compliant classes. |
| `forUi(): array` | ✅ | Returns dropdown-ready array with key, label, allowed_schedule_types. |

**V2 additions required:**
- `keys(): array` — convenience method returning `array_keys(self::all())` for use in validation rules
- `getLabel(string $jobKey): ?string` — returns human-readable label for a key (for display in views)

### 9.2 `SchedulerService` Service

**File:** `Modules/Scheduler/app/Services/SchedulerService.php`
**Status:** 🟡 Partial — service exists but is orphaned (never called by controller or command)

| Method | Status | Notes |
|---|---|---|
| `dueSchedules(): Collection` | ✅ | Returns active schedules whose cron is currently due. Defensively catches invalid cron expressions. |
| `isDue(Schedule $schedule): bool` | ✅ | Protected. Uses `CronExpression::factory()->isDue()`. Safe catch on `\Throwable`. |
| `runSchedule(Schedule $schedule): ScheduleRun` | ❌ | MISSING — entire execution capability does not exist. |
| `createSchedule(array $data): Schedule` | ❌ | MISSING — controller currently handles model creation directly. |

**V2 required additions to `SchedulerService`:**

```
runSchedule(Schedule $schedule): ScheduleRun
  - Look up job class via JobRegistry::get()
  - If null: return failed ScheduleRun with error
  - If tenant-scoped: initialize tenancy context
  - Dispatch job
  - Create ScheduleRun(status='running', started_at=now())
  - Update Schedule::last_run_at = now()
  - On success: update ScheduleRun(status='success', finished_at, duration_ms)
  - On failure: update ScheduleRun(status='failed', error_message), increment failure_count

createSchedule(array $validatedData): Schedule
  - Centralizes Schedule::create() logic from controller
  - Handles JSON decode of payload
  - Computes next_run_at from cron expression
  - Fires ScheduleCreated event

updateSchedule(Schedule $schedule, array $validatedData): Schedule
  - Updates schedule fields
  - Recomputes next_run_at if cron_expression changed
  - Fires ScheduleUpdated event

computeNextRunAt(string $cronExpression): ?Carbon
  - Wraps CronExpression to return next due datetime
  - Returns null on invalid expression
```

---

## 10. Views Inventory

### 10.1 Current Views

| View File | Route Used By | Status | Issues |
|---|---|---|---|
| `schedule/index.blade.php` | `index()` | 🟡 | Table renders; "Runs" href is empty; Toggle Status form action is empty; references `$schedule->failure_count` which doesn't exist in DB |
| `schedule/create.blade.php` | `create()` | ✅ | Functional create form |
| `schedule/edit.blade.php` | `edit()` | ❌ | WRONG CONTENT — copied from Dropdown module; shows dropdown edit form, not schedule edit form |
| `schedule/trash.blade.php` | `trashedSchedule()` | ❌ | WRONG CONTENT — copied from Dropdown module; shows dropdown trash view, not schedule trash |
| `index.blade.php` | (module root) | ❌ | Unused placeholder |
| `components/layouts/master.blade.php` | N/A | ❌ | Generic scaffold |

### 10.2 Missing Views (V2 Required)

| View File | Purpose | Priority |
|---|---|---|
| `schedule/show.blade.php` | Schedule detail: name, type, cron, payload, status, last/next run, run history summary | P1 |
| `schedule/runs.blade.php` | Run history list for a specific schedule: paginated table with status, timing, error details | P1 |
| `schedule/_partials/run-status-badge.blade.php` | Reusable badge partial for run status (running/success/failed) | P2 |

### 10.3 Views Requiring Fixes

| View File | Fix Required |
|---|---|
| `schedule/index.blade.php` | Populate "Runs" href with `route('scheduler.runs', $schedule)`; populate Toggle Status form action; wrap with `@can` guards; add pagination links |
| `schedule/edit.blade.php` | Replace entirely with proper schedule edit form (name, cron_expression, payload, is_active, schedule_type) |
| `schedule/trash.blade.php` | Replace entirely with proper schedule trash view (name, job_key, deleted_at, restore/force-delete actions) |

---

## 11. FormRequests Inventory

### 11.1 `ScheduleRequest`

**File:** `Modules/Scheduler/app/Http/Requests/ScheduleRequest.php`
**Status:** 🟡 Partial — structure is good, has critical issues

| Aspect | Status | Notes |
|---|---|---|
| Create/update differentiation | ✅ | Uses `$isUpdate` flag to toggle `required` vs `sometimes` |
| `prepareForValidation()` | ✅ | Normalizes `is_active` checkbox to boolean |
| `authorize()` | ❌ | Returns `true` unconditionally; must check policy |
| `job_key` validation | ❌ | Only `required|string` — no registry key validation |
| `cron_expression` validation | ❌ | Only `required|string|max:255` — no cron syntax validation |
| `payload` validation | ❌ | No `json` validation rule and no max size |
| `schedule_type` rule | ❌ | Not present; must be `in:prime,tenant` |
| `tenant_id` conditional rule | ❌ | Must be `required_if:schedule_type,tenant` |
| Double validation in controller | ❌ | store() calls $request->validate() inline — overrides FormRequest |

**V2 target rules for `ScheduleRequest`:**

```php
'name'            => [$isUpdate ? 'sometimes' : 'required', 'string', 'max:255'],
'schedule_type'   => [$isUpdate ? 'sometimes' : 'required', Rule::in(SchedulerType::values())],
'tenant_id'       => ['nullable', 'required_if:schedule_type,tenant', 'string', 'max:255'],
'job_key'         => [$isUpdate ? 'sometimes' : 'required', 'string', Rule::in(JobRegistry::keys())],
'cron_expression' => [$isUpdate ? 'sometimes' : 'required', 'string', 'max:255', new ValidCronExpression()],
'payload'         => ['nullable', 'string', 'max:10000', new ValidJsonString()],
'is_active'       => ['boolean'],
```

**New custom validation rules required:**
- `ValidCronExpression` rule class: wraps `CronExpression::factory($value)->isDue()` — if it throws, rule fails
- `ValidJsonString` rule class: wraps `json_decode($value)` — if `json_last_error()` is not `JSON_ERROR_NONE`, rule fails

---

## 12. Events, Listeners, Commands

### 12.1 Current State

**Events:** None defined anywhere in the module.

**Listeners:** None defined.

**Artisan Commands:** None registered. `SchedulerServiceProvider::registerCommands()` is empty (commented-out stub). `registerCommandSchedules()` is also empty/commented.

**EventServiceProvider:** `Modules/Scheduler/app/Providers/EventServiceProvider.php` exists but has no event-listener bindings.

### 12.2 Required Artisan Command (V2)

**`ScheduleDispatchCommand`**
- Class: `Modules\Scheduler\Console\Commands\ScheduleDispatchCommand`
- Signature: `scheduler:dispatch`
- Description: Dispatches all due scheduled jobs
- Logic:
  1. Instantiate `SchedulerService`
  2. Call `dueSchedules()` → collect due schedules
  3. For each due schedule: call `runSchedule($schedule)` inside try/catch
  4. On exception: log error, continue to next schedule
  5. Output summary: `Dispatched {n} schedule(s). {f} failure(s).`
- Registration: Added to `registerCommands()` array in `SchedulerServiceProvider`
- Kernel binding: Added to `registerCommandSchedules()` with `->everyMinute()->withoutOverlapping()`

### 12.3 Required Events (V2 — optional but recommended)

| Event Class | When Fired | Data |
|---|---|---|
| `ScheduleCreated` | After `SchedulerService::createSchedule()` | `$schedule` |
| `ScheduleUpdated` | After `SchedulerService::updateSchedule()` | `$schedule` |
| `ScheduleDeleted` | After `Schedule::delete()` | `$schedule` |
| `ScheduleExecuted` | After successful job dispatch | `$schedule`, `$scheduleRun` |
| `ScheduleFailed` | After dispatch failure | `$schedule`, `$scheduleRun`, `$exception` |

### 12.4 Required Seeder

**`SchedulerPermissionSeeder`** — seeds the following Spatie permissions:

```php
$permissions = [
    'admin.scheduler.viewAny',
    'admin.scheduler.view',
    'admin.scheduler.create',
    'admin.scheduler.update',
    'admin.scheduler.delete',
    'admin.scheduler.restore',
    'admin.scheduler.forceDelete',
    'admin.scheduler.run',
];
```

Must be called from the main `DatabaseSeeder` or the `SchedulerDatabaseSeeder`. Currently `SchedulerDatabaseSeeder::run()` is a commented-out stub.

---

## 13. Testing Requirements

### 13.1 Existing Tests

**File:** `Modules/Scheduler/tests/Unit/SchedulerModuleTest.php`
**Framework:** Pest (no database)
**Tests:** 16 total

| Test Group | Tests | Quality |
|---|---|---|
| Schedule Model | 6 tests (table, no SoftDeletes, fillable, casts, isPrime, isTenant) | Documents gaps rather than verifying correct state |
| ScheduleRun Model | 4 tests (instantiable, fillable, datetime casts, default table) | Correct |
| SchedulerController — Zero Auth | 4 tests (controller exists, zero Gate calls, empty update, empty destroy) | Intentionally documents known bugs |
| Architecture | 6 tests (class existence checks for all components) | Correct |

**Critical note:** The test for zero Gate::authorize calls (`not->toContain('Gate::authorize')`) is currently **asserting the broken state**. Once the security fix is applied, this test must be inverted to assert that Gate::authorize IS present in each method.

### 13.2 Test Coverage Gaps (V2 Required)

**Unit Tests:**

| Test Class | Purpose | Priority |
|---|---|---|
| `SchedulerServiceTest` | `dueSchedules()` returns only active, due schedules; invalid cron is skipped and logged | P0 |
| `JobRegistryTest` | `get()` returns null for unknown keys; validates SchedulableJob contract; `forUi()` format | P0 |
| `ScheduleModelTest` | SoftDeletes active, `runs()` relationship, scopes (active, prime, tenant) | P1 |
| `ScheduleRunModelTest` | `schedule()` relationship, explicit table declaration | P1 |
| `ValidCronExpressionRuleTest` | Valid expressions pass; invalid expressions fail with message | P1 |
| `ValidJsonStringRuleTest` | Valid JSON passes; malformed JSON fails | P1 |

**Feature Tests:**

| Test Class | Purpose | Priority |
|---|---|---|
| `SchedulerControllerAuthTest` | Unauthenticated user is redirected; non-admin gets 403; admin can access index/create | P0 |
| `ScheduleCreateTest` | Valid create succeeds; invalid job_key rejected; invalid cron rejected; invalid JSON payload rejected | P0 |
| `ScheduleUpdateTest` | Update modifies fields; update with invalid cron rejected | P1 |
| `ScheduleDeleteTest` | Soft delete sets deleted_at; hard delete on trashed; restore works | P1 |
| `ScheduleToggleTest` | Toggle flips is_active status | P1 |
| `ScheduleRunHistoryTest` | Runs view shows paginated history for a schedule | P2 |
| `ScheduleDispatchCommandTest` | Command dispatches due schedules; skips non-due; handles exceptions gracefully | P1 |

**Updated existing test (required):**

The test `'entire controller has ZERO Gate::authorize calls'` must be REPLACED with tests that verify Gate::authorize IS called correctly once the security fix is implemented. The current test documents the broken state and will fail after the fix — that is the intended outcome.

---

## 14. Future / Out-of-Scope Suggestions

> Section 14 contains suggestions only. None of these items are V2 requirements.

**SUG-01 — Queue Monitoring UI**
A UI wrapper around Laravel Horizon or the `failed_jobs` table would let admins inspect pending, running, and failed queue items. This is RBS SYS1.1.1.2 and is explicitly out of scope for V2.

**SUG-02 — Job Auto-Discovery**
Rather than maintaining a static `JobRegistry::all()` array, job classes could be auto-discovered from a configurable set of directories using PHP reflection to find classes implementing `SchedulableJob`. This would reduce maintenance burden as the job catalog grows.

**SUG-03 — Failure Notification**
When a scheduled job fails, a configurable notification (email, in-app) could be sent to designated admins. This maps to RBS SYS1.1.2 and is out of scope for V2.

**SUG-04 — Tenant Self-Service Scheduling**
Tenants (school admins) could be allowed to enable/disable tenant-scoped schedules for their own school from within the tenant dashboard. This requires tenant-side routes, views, and a scoped version of the schedule management UI. Out of scope for V2.

**SUG-05 — Schedule History Retention Policy**
A configurable retention window (e.g., keep only last 90 days of `schedule_runs`) with an automated cleanup job would prevent unbounded table growth. Out of scope for V2.

**SUG-06 — Cron Expression Builder UI**
A visual cron expression builder (like crontab.guru UI component) would improve usability for non-technical admins configuring schedules. Out of scope for V2.

**SUG-07 — Schedule Dependency Chains**
Some jobs must run sequentially (e.g., run archival before billing). A simple `depends_on` field in the `schedules` table, combined with execution-order logic in `ScheduleDispatchCommand`, could support chained job execution. Out of scope for V2.

---

## 15. Permissions and RBAC

### 15.1 Permission Naming Convention

All Scheduler permissions use the `admin.` prefix because the Scheduler is a central admin function, not a tenant-specific one.

| Permission | Used In |
|---|---|
| `admin.scheduler.viewAny` | `SchedulePolicy::viewAny()`, `index()`, `trashedSchedule()` |
| `admin.scheduler.view` | `SchedulePolicy::view()`, `show()`, `runs()` |
| `admin.scheduler.create` | `SchedulePolicy::create()`, `create()`, `store()` |
| `admin.scheduler.update` | `SchedulePolicy::update()`, `edit()`, `update()`, `toggleStatus()` |
| `admin.scheduler.delete` | `SchedulePolicy::delete()`, `destroy()` |
| `admin.scheduler.restore` | `SchedulePolicy::restore()`, `restore()` |
| `admin.scheduler.forceDelete` | `SchedulePolicy::forceDelete()`, force delete from trash |
| `admin.scheduler.run` | Custom gate — `run()` manual trigger |

### 15.2 Role Assignment

| Role | Permissions Granted |
|---|---|
| Super Admin | All `admin.scheduler.*` |
| Prime Admin | `viewAny`, `view`, `create`, `update`, `delete`, `run` |
| Support Staff | `viewAny`, `view` only |
| School Admin (Tenant) | None — must never reach scheduler routes |

### 15.3 Policy Class Specification

**Class:** `Modules\Scheduler\Policies\SchedulePolicy`
**Registration:** `Gate::policy(Schedule::class, SchedulePolicy::class)` in `AppServiceProvider`

```php
public function viewAny(User $user): bool
    → $user->hasPermissionTo('admin.scheduler.viewAny')

public function view(User $user, Schedule $schedule): bool
    → $user->hasPermissionTo('admin.scheduler.view')

public function create(User $user): bool
    → $user->hasPermissionTo('admin.scheduler.create')

public function update(User $user, Schedule $schedule): bool
    → $user->hasPermissionTo('admin.scheduler.update')

public function delete(User $user, Schedule $schedule): bool
    → $user->hasPermissionTo('admin.scheduler.delete')

public function restore(User $user, Schedule $schedule): bool
    → $user->hasPermissionTo('admin.scheduler.restore')

public function forceDelete(User $user, Schedule $schedule): bool
    → $user->hasPermissionTo('admin.scheduler.forceDelete')
```

---

## 16. Completion Criteria and Effort

### 16.1 Gap Summary from Audit (All 25 Items)

| ID | Severity | Description | Status in V2 |
|---|---|---|---|
| SEC-001 / AUTH-001 | CRITICAL | Zero Gate::authorize in entire controller | ❌ Must fix — P0 |
| MF-001 | CRITICAL | update() method is completely empty | ❌ Must fix — P0 |
| MF-002 | CRITICAL | destroy() method is completely empty | ❌ Must fix — P0 |
| MF-005 | CRITICAL | No schedule execution engine (runSchedule + artisan command) | ❌ Must fix — P0 |
| AUTH-002 | CRITICAL | No SchedulePolicy exists or is registered | ❌ Must fix — P0 |
| BUG-001 | HIGH | Double validation in store() (FormRequest + inline) | ❌ Must fix — P1 |
| SEC-002 | HIGH | job_key not validated against JobRegistry | ❌ Must fix — P1 |
| SEC-003 | HIGH | cron_expression not validated as valid cron | ❌ Must fix — P1 |
| DBM-001 | HIGH | Schedule model missing SoftDeletes | ❌ Must fix — P1 |
| DBM-002 | HIGH | ScheduleRun model missing SoftDeletes | ❌ Must fix — P1 |
| PERF-001 | HIGH | index() loads all schedules without pagination | ❌ Must fix — P1 |
| RT-001 | HIGH | Scheduler routes triplicated in web.php | ❌ Must fix — P1 |
| RT-002 | HIGH | trashedSchedule route points to non-existent method | ❌ Must fix — P1 |
| ARCH-007 | HIGH | Zero activity logging (sys_activity_logs) anywhere | ❌ Must fix — P1 |
| MF-003 | MEDIUM | show() returns generic view with no data | ❌ Must fix — P2 |
| MF-004 | MEDIUM | edit() returns generic view with no data | ❌ Must fix — P2 |
| MF-007 | MEDIUM | No schedule run history view | ❌ Must fix — P2 |
| MF-008 | MEDIUM | No toggle status endpoint | ❌ Must fix — P2 |
| BUG-004 | MEDIUM | ScheduleRun missing schedule() relationship | ❌ Must fix — P2 |
| BUG-005 | MEDIUM | Schedule missing runs() relationship | ❌ Must fix — P2 |
| DBM-006 | MEDIUM | last_run_at / next_run_at not in Schedule fillable | ❌ Must fix — P2 |
| SEC-006 | MEDIUM | No audit trail / activity logging | ❌ Must fix — P2 |
| ARCH-004 | LOW | SchedulerType is not a PHP 8.1+ backed enum | 🆕 V2 suggestion |
| DBM-005 | LOW | ScheduleRun missing explicit $table declaration | ❌ Must fix — P2 |
| DBM-003 | LOW | Both models missing created_by column | ❌ Must fix — P3 |
| ARCH-006 | LOW | JobRegistry hardcodes job classes | 🆕 Future suggestion |

### 16.2 V2 Completion Checklist

**P0 — Security (Must fix before any release):**
- [ ] Create `SchedulePolicy` and register in `AppServiceProvider`
- [ ] Add `Gate::authorize()` to all 7 existing controller methods
- [ ] Add `Gate::authorize()` to all 5 new controller methods
- [ ] Update `ScheduleRequest::authorize()` to use policy
- [ ] Seed `admin.scheduler.*` permissions via `SchedulerPermissionSeeder`
- [ ] Validate `job_key` against `JobRegistry::keys()` in FormRequest
- [ ] Validate `cron_expression` via `ValidCronExpression` rule
- [ ] Validate `payload` as JSON with max size

**P1 — Core Completeness:**
- [ ] Add `SoftDeletes` to `Schedule` model + migration
- [ ] Add `SoftDeletes` to `ScheduleRun` model + migration
- [ ] Add `failure_count`, `created_by` to `schedules` table migration
- [ ] Add `output`, `attempt`, `created_by` to `schedule_runs` table migration
- [ ] Fix `Schedule::$fillable` — add `last_run_at`, `next_run_at`, `failure_count`, `created_by`
- [ ] Remove inline `$request->validate()` from `store()` (BUG-001 fix)
- [ ] Implement `update()` method
- [ ] Implement `destroy()` method (soft delete)
- [ ] Implement `trashedSchedule()` method
- [ ] Implement `restore()` method
- [ ] Consolidate triplicated routes in global `web.php`
- [ ] Add pagination to `index()` — `paginate(15)` with search/filter
- [ ] Add `activityLog()` calls to all CRUD operations
- [ ] Add `runs()` HasMany on `Schedule`
- [ ] Add `schedule()` BelongsTo on `ScheduleRun`

**P2 — Execution Engine:**
- [ ] Implement `SchedulerService::runSchedule()`
- [ ] Implement `SchedulerService::createSchedule()` and `updateSchedule()`
- [ ] Create `ScheduleDispatchCommand` artisan command
- [ ] Register command in `SchedulerServiceProvider`
- [ ] Register kernel schedule in `registerCommandSchedules()`
- [ ] Implement `show()` with model loading and run history
- [ ] Implement `edit()` with model loading
- [ ] Implement `run()` manual trigger method
- [ ] Implement `runs()` run history view method
- [ ] Implement `toggleStatus()` AJAX method
- [ ] Create `schedule/show.blade.php`
- [ ] Create `schedule/runs.blade.php`
- [ ] Fix `schedule/edit.blade.php` — replace with proper schedule edit form
- [ ] Fix `schedule/trash.blade.php` — replace with proper schedule trash view
- [ ] Fix `schedule/index.blade.php` — populate Runs href, Toggle action, add pagination, add `@can` guards
- [ ] Compute and save `next_run_at` on create/update

**P3 — Quality:**
- [ ] Convert `SchedulerType` to PHP 8.1 backed enum
- [ ] Add `protected $table = 'schedule_runs';` to `ScheduleRun`
- [ ] Expand `JobRegistry` with all 10 production jobs
- [ ] Implement `ValidCronExpression` custom rule class
- [ ] Implement `ValidJsonString` custom rule class
- [ ] Move model creation from `store()` into `SchedulerService::createSchedule()`
- [ ] Add `SchedulerService` injection into `SchedulerController` (DI via constructor)
- [ ] Add `schedule_type` selection to create form
- [ ] Add tenant selector (shown conditionally when schedule_type = 'tenant')

**Testing:**
- [ ] Invert `SchedulerModuleTest` Gate::authorize test (once security fix applied)
- [ ] Add `SchedulerServiceTest` (dueSchedules, runSchedule)
- [ ] Add `JobRegistryTest`
- [ ] Add `SchedulerControllerAuthTest` (feature test — HTTP auth enforcement)
- [ ] Add `ScheduleCreateTest` (feature test — validation rules)
- [ ] Add `ScheduleUpdateTest` and `ScheduleDeleteTest`
- [ ] Add `ScheduleDispatchCommandTest`
- [ ] Add `ValidCronExpressionRuleTest` and `ValidJsonStringRuleTest`
- [ ] Minimum 25 tests total (unit + feature) with all green before marking complete

### 16.3 Effort Estimation

| Priority Band | Items | Estimated Hours |
|---|---|---|
| P0 (Security) | 8 items | 5h |
| P1 (Core Completeness) | 17 items | 8h |
| P2 (Execution Engine + UI) | 20 items | 12h |
| P3 (Quality + Expansion) | 10 items | 5h |
| Testing | 15 tests | 8h |
| **Total** | **70 items** | **38h** |

### 16.4 Definition of Done

The Scheduler module is considered **production-ready** when ALL of the following are true:

1. All CRUD operations (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`, `restore`) are implemented and tested
2. Every controller method calls `Gate::authorize()` with the appropriate permission
3. `SchedulePolicy` exists, is registered, and has 100% test coverage
4. `Schedule` and `ScheduleRun` models both use `SoftDeletes`
5. `SchedulerService::runSchedule()` dispatches jobs and creates `ScheduleRun` records
6. `ScheduleDispatchCommand` artisan command is registered and runs every minute via Laravel scheduler
7. Run history is visible in the UI (`schedule/runs.blade.php`) with status, timing, and errors
8. Toggle status works (AJAX PATCH endpoint and UI button wired up)
9. Manual trigger (`run()`) works for on-demand job dispatch
10. All input is validated: `job_key` against registry, `cron_expression` as valid cron, `payload` as valid JSON
11. Zero triplicated route registrations in global `web.php`
12. All registered route names match the controller's redirect calls
13. All platform deferred jobs (10+ keys) are registered in `JobRegistry`
14. `sys_activity_logs` entries are written for all CRUD and run operations
15. Minimum 25 automated tests (unit + feature) all passing on CI

---

*Document generated by Claude Code (Automated) — 2026-03-26*
*Based on code inspection of `Modules/Scheduler/` at `/Users/bkwork/Herd/prime_ai/`*
*Gap analysis source: `Scheduler_Deep_Gap_Analysis.md` — 25 gaps, overall score 3.9/10*
