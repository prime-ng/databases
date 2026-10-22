# Module Knowledge — Scheduler (SDL)
**Module Code:** SDL | **Module Prefix:** `schedules.*` (no sdl_ prefix — exception; tables use generic names)
**Module Path:** `Modules/Scheduler/`
**DB Layer:** prime_db (Central — NOT tenant-scoped)
**Status:** ~40% complete | **FRD:** SDL_FRD_Complete_2026-06-29.md
**Last Updated:** 2026-06-29 | Agent: pa-business-analyst

---

## Module Facts

| Attribute | Value | Source |
|---|---|---|
| Module Type | Cross-Layer — Prime Admin only | V1/V2 req, code |
| DB Layer | prime_db (central) | migrations: no Schema::table with tenant prefix |
| Table Prefix | None — tables named `schedules` and `schedule_runs` | migrations |
| DDL Tables | 2 (`schedules`, `schedule_runs`) | Module migrations (NOT in _DDL folder) |
| Module Migrations | 2 files in `Modules/Scheduler/database/migrations/` | filesystem |
| Central Migrations | 0 files in `database/migrations/` for this module | filesystem |
| Controllers | 1 (`SchedulerController`) | filesystem |
| Models | 2 (`Schedule`, `ScheduleRun`) | filesystem |
| Services | 2 (`JobRegistry`, `SchedulerService`) | filesystem |
| FormRequests | 1 (`ScheduleRequest`) | filesystem |
| Contracts/Interfaces | 1 (`SchedulableJob`) | filesystem |
| Enums | 1 (`SchedulerType` — PHP class constants, NOT a PHP 8.1 backed enum) | code |
| Providers | 3 (`SchedulerServiceProvider`, `RouteServiceProvider`, `EventServiceProvider`) | filesystem |
| Views | 6 total (index root, schedule/index, schedule/create, schedule/edit, schedule/trash, components/layouts/master) | filesystem |
| Routes | 14 lines — module's own `routes/web.php` (1 resource route only) | filesystem |
| Tests | 1 file — `tests/Unit/SchedulerModuleTest.php` (16 tests, intentionally documents known gaps) | filesystem |
| Jobs | 0 | filesystem |
| Events | 0 | filesystem |
| Listeners | 0 | filesystem |
| Artisan Commands | 0 registered | SchedulerServiceProvider (stubs only, commented out) |
| Policies | 0 — no SchedulePolicy exists | filesystem |
| Seeders | 1 — `SchedulerDatabaseSeeder` (stub, body commented out) | filesystem |
| FRD Status | Generated 2026-06-29 | this session |
| Completion | ~40% | V2 req, gap analysis, code verification |

---

## DDL Table Inventory

Both tables live in `Modules/Scheduler/database/migrations/` (module-owned, NOT central migrations).
They are prime_db tables — these run via `php artisan module:migrate Scheduler`, NOT `php artisan tenants:migrate`.

### Table: `schedules`
Migration: `2026_01_02_112016_create_schedules_table.php`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | INT UNSIGNED PK | No | Auto-increment |
| `name` | VARCHAR 255 | No | Display label |
| `schedule_type` | ENUM('prime','tenant') | No | Indexed |
| `tenant_id` | VARCHAR 255 | Yes | Indexed; no FK constraint |
| `job_key` | VARCHAR 255 | No | Matches JobRegistry key |
| `payload` | JSON | Yes | Cast to array in model |
| `cron_expression` | VARCHAR 255 | No | No cron-syntax validation in migration |
| `is_active` | BOOLEAN | No | Default true |
| `last_run_at` | TIMESTAMP | Yes | Exists in migration; NOT in model `$fillable` (gap) |
| `next_run_at` | TIMESTAMP | Yes | Exists in migration; NOT in model `$fillable` (gap) |
| `created_at` | TIMESTAMP | Yes | Standard |
| `updated_at` | TIMESTAMP | Yes | Standard |

**Missing columns (require new migration):** `deleted_at`, `created_by`, `failure_count`

### Table: `schedule_runs`
Migration: `2026_01_02_155143_create_schedule_runs_table.php`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | INT UNSIGNED PK | No | Auto-increment |
| `schedule_id` | INT UNSIGNED FK | No | → `schedules.id` RESTRICT ON DELETE |
| `tenant_id` | VARCHAR 255 | Yes | Indexed |
| `status` | ENUM('running','success','failed') | No | Indexed |
| `error_message` | TEXT | Yes | |
| `started_at` | TIMESTAMP | No | |
| `finished_at` | TIMESTAMP | Yes | |
| `duration_ms` | INT | Yes | Not cast in model |
| `created_at` / `updated_at` | TIMESTAMP | Yes | Standard |

**Missing columns (require new migration):** `deleted_at`, `created_by`, `output`, `attempt`

---

## Known Gaps & Open Issues

### P0 — Critical (Must fix before any release)

| ID | Gap | Evidence |
|---|---|---|
| SEC-001 / AUTH-001 | ZERO `Gate::authorize()` calls in entire `SchedulerController` — any authenticated user (including tenant school staff) can view, create, and access all schedule pages | SchedulerController.php verified in code |
| AUTH-002 | No `SchedulePolicy` exists anywhere in the codebase | filesystem search |
| MF-001 | `update()` method is completely empty — cannot edit schedules | SchedulerController.php line 76-78 |
| MF-002 | `destroy()` method is completely empty — cannot delete schedules | SchedulerController.php line 83-85 |
| MF-005 | No execution engine: `SchedulerService::runSchedule()` missing; no Artisan command; `ScheduleRun` records are never written | SchedulerService.php: only `dueSchedules()` exists; no console command anywhere |

### P1 — High (Fix before release)

| ID | Gap | Evidence |
|---|---|---|
| BUG-001 | Double validation in `store()`: `ScheduleRequest` (FormRequest) runs rules then `store()` calls `$request->validate()` again with DIFFERENT inline rules — the FormRequest is effectively bypassed | SchedulerController.php lines 34-42 |
| SEC-002 | `job_key` not validated against `JobRegistry::all()` keys — any arbitrary string accepted | ScheduleRequest.php: only `required|string` |
| SEC-003 | `cron_expression` not validated as a valid cron syntax — invalid expressions silently stored | ScheduleRequest.php: only `required|string|max:255` |
| DBM-001 | `Schedule` model missing `SoftDeletes` — deleted schedules are permanently destroyed | Schedule.php: no `use SoftDeletes;` trait |
| DBM-002 | `ScheduleRun` model missing `SoftDeletes` | ScheduleRun.php: no `use SoftDeletes;` trait |
| RT-001 | Scheduler routes triplicated in central `web.php` (3 registration blocks create conflicting named routes) | V2 req confirmed; module's own `routes/web.php` has only 1 resource route |
| RT-002 | `trashedSchedule` route in `web.php` points to non-existent controller method | V2 req; no `trashedSchedule()` method on controller |
| PERF-001 | `index()` loads ALL schedules with `->get()` — no pagination | SchedulerController.php line 18 |
| ARCH-007 | Zero `activityLog()` calls anywhere — all CRUD is untracked | code search |

### P2 — Medium (Next sprint)

| ID | Gap | Evidence |
|---|---|---|
| MF-003 | `show()` returns generic `scheduler::show` view with no data loaded | SchedulerController.php line 62 |
| MF-004 | `edit()` returns generic `scheduler::edit` view with no schedule loaded | SchedulerController.php line 70 |
| MF-007 | No run history view/route | No `schedule/runs.blade.php`, no runs route |
| MF-008 | No toggle status endpoint | Index view has button but no action URL or route |
| VIEW-001 | `schedule/edit.blade.php` — WRONG CONTENT (copy-pasted from Dropdown module) | filesystem |
| VIEW-002 | `schedule/trash.blade.php` — WRONG CONTENT (copy-pasted from Dropdown module) | filesystem |
| DBM-006 | `last_run_at` and `next_run_at` exist in migration but NOT in `Schedule::$fillable` — cannot be mass-assigned | Schedule.php vs migration |
| BUG-004 | `ScheduleRun` has no `schedule()` BelongsTo relationship | ScheduleRun.php |
| BUG-005 | `Schedule` has no `runs()` HasMany relationship | Schedule.php |

### P3 — Low / Technical Debt

| ID | Gap | Evidence |
|---|---|---|
| ARCH-004 | `SchedulerType` uses PHP class constants instead of PHP 8.1+ backed enum | Enums/SchedulerType.php |
| DBM-005 | `ScheduleRun` model has no explicit `$table` property | ScheduleRun.php |
| DBM-003 | Neither model has `created_by` column in migration or fillable | migrations |
| ARCH-006 | `JobRegistry` hardcodes only 3 jobs; platform needs 10+ registered | JobRegistry.php |
| ARCH-002 | `SchedulerService` is orphaned — never called by controller or any command | code search |

---

## Design Decisions Made

- **D-SDL-01**: Scheduler is a PRIME-only module — all routes are central, no tenant-side schedule management UI. Tenant-scoped jobs run in tenant context (via tenancy initialization in the execution engine) but the management UI is strictly central.
- **D-SDL-02**: Tables use generic names (`schedules`, `schedule_runs`) with no module prefix — this is a deliberate exception from the platform naming convention. The V2 requirement doc confirms "Table Prefix: N/A".
- **D-SDL-03**: `SchedulerType` PRIME vs TENANT distinguishes whether the job runs in central context (prime_db) or within a specific tenant's database context (requiring `tenancy()->initialize($tenant)` before dispatch).
- **D-SDL-04**: `JobRegistry` is a static catalog — not auto-discovered. Every schedulable job must be manually registered. V2 target requires 10+ jobs in the registry.
- **D-SDL-05**: `SchedulerService::dueSchedules()` filters in PHP (not DB) — loads all active schedules then checks cron expression. Acceptable at current scale; DB-level filtering deferred to future.
- **D-SDL-06**: The RSP tenancy middleware gap (D23 from modules-map) applies — Scheduler's `RouteServiceProvider` applies only `web` middleware, no `InitializeTenancyByDomain`. This is correct because it's a central module.
- **D-SDL-07**: Gap-analysis module score is 3.9/10 overall (from 2026-03-22 audit). Authorization score is 0/10 — the single most critical gap.

---

## Cross-Module Dependencies

### Inbound (Scheduler reads from)
| Source Module | Data/Entity | Why |
|---|---|---|
| Prime (central) | Tenant records (`prm_tenant`) | Required when dispatching TENANT-scoped jobs to determine which tenant context to initialize |
| All modules | Registered job classes | Each module with schedulable jobs must have its job class added to `JobRegistry::all()` |

### Outbound (Scheduler triggers)
| Target Module | Mechanism | What |
|---|---|---|
| Recommendation | `ExpireRecommendationsJob` (planned) | Marks overdue student recommendations expired — tenant-scoped |
| StudentFee / Notification | `FeeReminderJob` (planned) | Triggers fee reminder notifications — tenant-scoped |
| StudentProfile / Notification | `AttendanceSmsJob` (planned) | Daily attendance SMS dispatch — tenant-scoped |
| HPC / MarksheetGeneration | `PdfBatchReportJob` (planned) | Batch generate PDF reports — tenant-scoped |
| Billing | `BillingReportJob` (exists, registered) | Monthly billing report generation — prime-scoped |
| Any data module | `DataArchivalJob` (planned) | Year-end data archival — prime/tenant-scoped |

---

## Lessons Learned

- [2026-06-29 | pa-business-analyst]: Scheduler module DDL is NOT in the old_db DDL folder — a file named `Scheduler_ddl_v1.sql` exists at `1-DDL_Modules/_Scheduler/DDL/` but it contains `tst_schedules` — a testing framework table, not the Scheduler module. The actual Scheduler module tables are defined only in its own module migrations.
- [2026-06-29 | pa-business-analyst]: The V2 requirement doc uses code "SCH_JOB"; the pipeline uses "SDL". Use SDL for all FRD IDs (REQ-SDL-, BR-SDL-, etc.). The legacy SCH_JOB code should not be mixed into new artifacts.
- [2026-06-29 | pa-business-analyst]: The test file `SchedulerModuleTest.php` intentionally asserts BROKEN state (asserting zero Gate::authorize, asserting empty update/destroy). These tests must be INVERTED after the security fix — they are not tests of correct behavior, they are documentation of current gaps.
- [2026-06-29 | pa-business-analyst]: The execution engine (`SchedulerService::runSchedule()` + `ScheduleDispatchCommand`) is the single most valuable missing piece. Without it, the module has no actual scheduling capability — it's only a form for creating schedule records that are never executed.
- [2026-06-29 | pa-business-analyst]: Despite the 0/10 authorization score, the service-layer architecture (`SchedulableJob` contract, `JobRegistry`, `SchedulerService`) is genuinely well-designed and should be preserved as-is.

---

## FRD Summary

| Field | Value |
|---|---|
| FRD File | `SDL_FRD_Complete_2026-06-29.md` (flat in `0-FRD_Documents/`) |
| FRD Date | 2026-06-29 |
| Total REQ | 9 |
| Total BR | 24 |
| Total RPT | 3 |
| Total ENH | 7 |
| P0 Requirements | 3 (REQ-SDL-001, REQ-SDL-002, REQ-SDL-008) |
| P1 Requirements | 5 (REQ-SDL-003 to REQ-SDL-007) |
| P2 Requirements | 1 (REQ-SDL-009) |
| User Stories produced | 8 (all P0/P1 REQs) |

---

## Pending Next Steps

1. **P0 Security Fix**: Add `SchedulePolicy`, register in `AppServiceProvider`, add `Gate::authorize()` to all 7 controller methods, update `ScheduleRequest::authorize()`.
2. **P0 Execution Engine**: Implement `SchedulerService::runSchedule()`, create `ScheduleDispatchCommand` artisan command, register in `SchedulerServiceProvider`.
3. **P0 CRUD Completion**: Implement `update()` and `destroy()` methods.
4. **P1 Schema Migrations**: Add `deleted_at`, `created_by`, `failure_count` to `schedules`; add `deleted_at`, `created_by`, `output`, `attempt` to `schedule_runs`.
5. **P1 Fix Views**: Replace `edit.blade.php` and `trash.blade.php` (wrong content); create `show.blade.php` and `runs.blade.php`.
6. **P1 Route Consolidation**: Remove duplicate route registrations from central `web.php`.
7. **Technical Audit**: Hand off to Technical Auditor (Mode X) for 12-layer audit — security layer is the top priority given 0/10 authorization score.
8. **Testing**: Invert the broken-state assertions in `SchedulerModuleTest.php` once security fix is applied; add feature tests.

---

## Version History

| Version | Date | Change | Agent |
|---|---|---|---|
| 1.0 | 2026-06-29 | Initial seed — verified all counts against live filesystem and migrations | pa-business-analyst |
