# Platform Backup Management — Requirement Document

## 1. Overview

The Platform Backup Management feature provides Super Admins with the ability to trigger manual database backups, schedule recurring backups, monitor backup run status, download completed backup files, and view backup history. All backup runs are executed asynchronously as queued background jobs (`RunBackupJob`). Completion and failure events trigger notifications (mail + database).

| Attribute | Value |
|-----------|-------|
| **Module** | **Maintenance** (NOT SystemConfig — cross-module dependency) |
| **Controllers** | `BackupController`, `BackupScheduleController` (both in `Modules\Maintenance`) |
| **Prefix** | `sys_` (`sys_backup_runs`, `sys_backup_schedules`) |
| **FRD IDs** | REQ-SYS-008, BR-SYS-020, RPT-SYS-002 |
| **Permissions** | `system-config.backup.*` (5 abilities), `system-config.backup-schedule.*` (4 abilities) |
| **Auth Pattern** | Explicit `Gate::authorize()` on every method |
| **Route Prefix** | `maintenance.backup.*` and `maintenance.backup.schedules.*` (in Maintenance module routes) |
| **DB Source** | Central database (`mysql` connection) — `sys_backup_runs`, `sys_backup_schedules` |
| **Models** | `Modules\Maintenance\Models\BackupRun`, `BackupSchedule` |
| **Background Job** | `Modules\Maintenance\Jobs\RunBackupJob` (queue: `backup`, tries: 1, timeout: 600s) |
| **Notifications** | `BackupSuccessNotification`, `BackupFailedNotification` (mail + database channels) |

**IMPORTANT:** The backup controllers and models are implemented in the **Maintenance** module, not in SystemConfig. The FRD references them under REQ-SYS-008 (Platform Backup Management) of the SystemConfig module. This requirement document covers both the SystemConfig FRD spec and the actual Maintenance module implementation, documenting the module boundary mismatch as a known issue.

---

## 2. Actor / User Role

| Role | Access |
|------|--------|
| Super Admin | Full access — create backups, manage schedules, download, delete |
| Platform Manager | Blocked per FRD US-SYS-008 (403 expected) |
| Platform Support | No access — backup operations are Super Admin only per FRD |
| School Admin | No access |

---

## 3. Functional Requirements

### Manual Backup

| ID | Requirement | Status | Notes |
|----|-------------|--------|-------|
| FR-BK-01 | Backup trigger form with database selection (central connections + tenants) | ✅ Implemented | Checkboxes for `mysql` (prime_db), `global_master_mysql` (global_db), individual tenants, or "All Tenants" |
| FR-BK-02 | Include files toggle | ✅ Implemented | `include_files` boolean in form + `FileBackupService` |
| FR-BK-03 | Backup queued as background job (non-blocking) | ✅ Implemented | `BackupService::dispatch()` → `RunBackupJob::dispatch()->onQueue('backup')` |
| FR-BK-04 | Backup Run record created with "pending" status | ✅ Implemented | `BackupRun::create(['status' => 'pending'])` |
| FR-BK-05 | Quick backup per connection/tenant (one-click from index) | ✅ Implemented | `quickBackup()` method |
| FR-BK-06 | Backup completion updates status to "completed" / "completed_with_warnings" | ✅ Implemented | Status updated in job `handle()` |
| FR-BK-07 | Backup failure updates status to "failed" with error_message | ✅ Implemented | Caught exceptions → `status = 'failed'` |
| FR-BK-08 | Progress percentage tracking | ✅ Implemented | `progress` column updated by dump progress callback |
| FR-BK-09 | Download completed backup file | ✅ Implemented | Local disk download or remote temp download via `BackupStorageService` |
| FR-BK-10 | Delete backup run (removes file + record) | ✅ Implemented | `destroy()` deletes local + remote files, then soft/hard deletes run |
| FR-BK-11 | Success notification (mail + in-app database notification) | ✅ Implemented | `BackupSuccessNotification` |
| FR-BK-12 | Failure notification (mail + in-app database notification) | ✅ Implemented | `BackupFailedNotification` |
| FR-BK-13 | Status polling endpoint for active runs | ✅ Implemented | `statuses()` returns JSON of pending/running runs |

### Backup Schedules

| ID | Requirement | Status | Notes |
|----|-------------|--------|-------|
| FR-BK-14 | Schedule listing (paginated 20 per page) | ✅ Implemented | `BackupScheduleController::index()` |
| FR-BK-15 | Create schedule with label, cron expression, database selection | ✅ Implemented | `create()` + `store()` with `StoreBackupScheduleRequest` |
| FR-BK-16 | Edit schedule | ✅ Implemented | `edit()` + `update()` |
| FR-BK-17 | Delete schedule | ✅ Implemented | `destroy()` |
| FR-BK-18 | Toggle schedule active/inactive | ✅ Implemented | `toggleStatus()` |
| FR-BK-19 | Scheduler integration: cron-based dispatch via `BackupScheduleService` | ✅ Implemented | `register()` called from console kernel with `withoutOverlapping()` |
| FR-BK-20 | `last_run_at` / `next_run_at` tracking on schedules | ✅ Implemented | Updated after each scheduled run |

### Backup Subject Display (Index View)

| ID | Requirement | Status | Notes |
|----|-------------|--------|-------|
| FR-BK-21 | Index page lists backup subjects (central + tenants) with per-subject stats | ✅ Implemented | `buildSubject()` creates array with type, id, name, description, total_backups, last_backup_at, is_active, runs |
| FR-BK-22 | Two central subjects: "Prime DB" (mysql) and "Global DB" (global_master_mysql) | ✅ Implemented | |
| FR-BK-23 | Each tenant listed as a subject | ✅ Implemented | With `backup_path` from tenant record |
| FR-BK-24 | Per-subject history endpoint (JSON) | ✅ Implemented | `subjectHistory()` returns runs + restores for a subject |
| FR-BK-25 | Active backup indicator on subjects | ✅ Implemented | `$hasActive` flag + per-subject `is_active` |
| FR-BK-26 | Restore log tracking per backup run | ✅ Implemented | `RestoreLog` model linked to `backup_run_id` |

---

## 4. Backup Run State Machine

```
Pending → Running → Completed / CompletedWithWarnings → (Download / Delete)
                  → Failed → (Delete)
```

| From | Event | To | Side Effects |
|------|-------|----|-------------|
| (new) | `BackupService::dispatch()` | Pending | Creates BackupRun record; dispatches `RunBackupJob` to `backup` queue |
| Pending | Job starts (`handle()`) | Running | Updates `started_at`; checks for concurrent active runs |
| Running | Job completes successfully | Completed | Sets `file_size_bytes`, `disk_path`, `completed_at`, `progress=100` |
| Running | Job completes with warnings | CompletedWithWarnings | Same as Completed, sets `error_message` to warning text |
| Running | Job throws exception | Failed | Sets `error_message`, `completed_at` |
| Pending | Queue worker picks up but concurrent job exists | Failed | Sets error: "Another backup is already in progress." |
| Pending | Insufficient disk space | Failed | Set error: "Insufficient disk space. At least 500MB required." |
| Pending | No valid connections | Failed | Sets error: "No valid database connections to back up." |
| Any | `BackupController::destroy()` | Deleted | Removes local/remote files; deletes BackupRun record |

---

## 5. Business Rules

| Rule ID | Rule | Source | Status |
|---------|------|--------|--------|
| BR-SYS-020 | Backup runs are queued background jobs; completion/failure trigger notifications | FRD | ✅ Implemented |
| — | Only one active backup at a time (concurrent guard) | Implementation | ✅ Guard in `RunBackupJob::handle()` |
| — | Minimum 500MB free disk space required | Implementation | ✅ Guard in `RunBackupJob::handle()` |
| — | If no valid connections, backup fails immediately | Implementation | ✅ Guard in `RunBackupJob::handle()` |
| — | File upload failure does not fail the backup — recorded as warning | Implementation | ✅ Warning collected, status = `completed_with_warnings` |
| — | At least one database or tenant must be selected | Implementation | ✅ `StoreBackupRequest` validation rule |
| — | Schedules use `withoutOverlapping()` to prevent concurrent scheduled runs | Implementation | ✅ In `BackupScheduleService::register()` |

---

## 6. Data Dictionary

### `sys_backup_runs` (central DB)

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | BIGINT UNSIGNED (PK) | Yes | |
| `name` | VARCHAR(255) | Yes | Auto-generated: "Manual — prime_db, 3 tenant DBs" |
| `databases_json` | JSON | Yes | `{ connections: [...], tenants: [...] }` |
| `all_tenants` | TINYINT(1) | Yes | Default 0 |
| `include_files` | TINYINT(1) | Yes | Default 0 |
| `status` | ENUM (pending/running/completed/completed_with_warnings/failed) | Yes | Default 'pending' |
| `progress` | TINYINT UNSIGNED | Yes | Default 0 |
| `disk_path` | VARCHAR(255) | No | Local path to backup zip |
| `remote_disk` | VARCHAR(255) | No | Remote disk name (S3 etc.) |
| `remote_path` | VARCHAR(255) | No | Remote path |
| `file_size_bytes` | BIGINT UNSIGNED | No | Set on completion |
| `started_at` | TIMESTAMP | No | Set when job starts running |
| `completed_at` | TIMESTAMP | No | Set on completion or failure |
| `triggered_by` | INT UNSIGNED (FK → `sys_users.id`) | No | ON DELETE SET NULL |
| `error_message` | TEXT | No | Error text or warnings |
| `created_at` | TIMESTAMP | Auto | |
| `updated_at` | TIMESTAMP | Auto | |

### `sys_backup_schedules` (central DB)

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | BIGINT UNSIGNED (PK) | Yes | |
| `label` | VARCHAR(255) | Yes | Human-readable schedule name |
| `databases_json` | JSON | Yes | `{ connections: [...], tenants: [...] }` |
| `all_tenants` | TINYINT(1) | Yes | Default 0 |
| `include_files` | TINYINT(1) | Yes | Default 0 |
| `cron_expression` | VARCHAR(100) | Yes | Standard cron syntax |
| `is_active` | TINYINT(1) | Yes | Default 1 |
| `last_run_at` | TIMESTAMP | No | |
| `next_run_at` | TIMESTAMP | No | |
| `created_by` | INT UNSIGNED (FK → `sys_users.id`) | Yes | ON DELETE CASCADE |
| `created_at` | TIMESTAMP | Auto | |
| `updated_at` | TIMESTAMP | Auto | |

---

## 7. Routes

All routes are registered in the **Maintenance** module (not SystemConfig):

| Method | URI | Name | Permission |
|--------|-----|------|-----------|
| GET | `/maintenance/backup` | `maintenance.backup.index` | `system-config.backup.viewAny` |
| GET | `/maintenance/backup/create` | `maintenance.backup.create` | `system-config.backup.create` |
| POST | `/maintenance/backup` | `maintenance.backup.store` | `system-config.backup.create` |
| GET | `/maintenance/backup/{type}/{id}/backup` | `maintenance.backup.quick` | `system-config.backup.create` |
| GET | `/maintenance/backup/{type}/{id}/history` | `maintenance.backup.history` | `system-config.backup.viewAny` |
| GET | `/maintenance/backup/{run}/download` | `maintenance.backup.download` | `system-config.backup.download` |
| DELETE | `/maintenance/backup/{run}` | `maintenance.backup.destroy` | `system-config.backup.delete` |
| GET | `/maintenance/backup/statuses` | `maintenance.backup.statuses` | `system-config.backup.viewAny` |
| GET | `/maintenance/backup/schedules` | `maintenance.backup.schedules.index` | `system-config.backup-schedule.viewAny` |
| GET | `/maintenance/backup/schedules/create` | `maintenance.backup.schedules.create` | `system-config.backup-schedule.create` |
| POST | `/maintenance/backup/schedules` | `maintenance.backup.schedules.store` | `system-config.backup-schedule.create` |
| GET | `/maintenance/backup/schedules/{schedule}/edit` | `maintenance.backup.schedules.edit` | `system-config.backup-schedule.update` |
| PUT | `/maintenance/backup/schedules/{schedule}` | `maintenance.backup.schedules.update` | `system-config.backup-schedule.update` |
| DELETE | `/maintenance/backup/schedules/{schedule}` | `maintenance.backup.schedules.destroy` | `system-config.backup-schedule.delete` |
| POST | `/maintenance/backup/schedules/{schedule}/toggle-status` | `maintenance.backup.schedules.toggleStatus` | `system-config.backup-schedule.update` |

---

## 8. Permissions

### Backup Permissions (5 abilities)

| Permission | Used By |
|-----------|---------|
| `system-config.backup.viewAny` | `index()`, `statuses()`, `subjectHistory()` |
| `system-config.backup.create` | `create()`, `store()`, `quickBackup()` |
| `system-config.backup.download` | `download()` |
| `system-config.backup.delete` | `destroy()` |

### Backup Schedule Permissions (4 abilities)

| Permission | Used By |
|-----------|---------|
| `system-config.backup-schedule.viewAny` | `index()` |
| `system-config.backup-schedule.create` | `create()`, `store()` |
| `system-config.backup-schedule.update` | `edit()`, `update()`, `toggleStatus()` |
| `system-config.backup-schedule.delete` | `destroy()` |

---

## 9. Services & Job Flow

### BackupService

- `dispatch(connections, tenantIds, userId, allTenants, includeFiles)`: Creates BackupRun record + dispatches `RunBackupJob`
- `buildRunName(...)`: Generates human-readable name like "Manual — prime_db, all tenants"
- `buildTenantConnectionName(tenantId)`: Returns `backup_tenant_{id}`
- `buildDatabaseName(tenantId)`: Returns `tenant_{id}`

### RunBackupJob (Queue: `backup`)

1. Finds BackupRun by ID
2. Checks for concurrent active runs → fails if found
3. Checks disk space ≥ 500MB → fails if insufficient
4. Updates status to `running`, sets `started_at`
5. Builds connection list from `databases_json` + resolves tenant DB names
6. Optionally collects files via `FileBackupService`
7. Calls `DatabaseDumper::dumpMultiple()` to create zip
8. Uploads to remote storage (if configured), may keep local copy
9. Updates status to `completed` or `completed_with_warnings`
10. On exception: updates status to `failed`
11. Sends `BackupSuccessNotification` or `BackupFailedNotification`
12. `failed()` method (queue job failed): updates status to `failed`, notifies

### BackupScheduleService

- `register(Schedule $schedule)`: Iterates active schedules, registers cron callbacks with `withoutOverlapping()`
- Each callback dispatches backup via `BackupService::dispatch()`, updates `last_run_at` and `next_run_at`

### BackupStorageService

- Handles upload to remote disk, local deletion, temp download for serving files

---

## 10. Known Issues & Gaps

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | **Module Boundary Mismatch:** Backup features are implemented in the **Maintenance** module, not in SystemConfig as cited by FRD REQ-SYS-008 | **High** | ⬜ Cross-module refactor needed or FRD-module mapping must be updated |
| 2 | FRD mentions "Platform Backup Management" as part of SystemConfig, but all code lives in `Modules/Maintenance` with routes under `maintenance.*` prefix | High | ⬜ Routes may need aliasing or menu mapping to appear under SystemConfig |
| 3 | No centralized route registration mapping `system-config.*` named routes to backup controllers | Medium | ⬜ Current routes use `maintenance.*` names, which may not match SystemConfig menu system |
| 4 | No documented way to access backup UI from SystemConfig sidebar/navigation | Medium | ⬜ Menu sync configuration must link to `maintenance.backup.*` routes |
| 5 | Auth coverage is explicit (`Gate::authorize()` on every method) — verified present | ✅ Good | |
| 6 | No feature tests for backup flows (FRD RISK-SYS-009) | High | ⬜ Backlog |
| 7 | `RestoreLog` model exists but no restore UI is exposed | Info | ⬜ Pending feature |
| 8 | No backup file size limit or retention policy configuration in UI | Low | ⬜ Enhancement |
| 9 | Schedule CRUD uses `StoreBackupScheduleRequest` for both create and update — validated fields match | ✅ Good | |
| 10 | The `include_files` feature depends on `FileBackupService::collectFiles()` — behavior undocumented | Medium | ⬜ Document |

---

## 11. Dependencies

| Dependency | Type | Module | Details |
|------------|------|--------|---------|
| `Modules\Maintenance\Models\BackupRun` | Model | Maintenance | `sys_backup_runs` on `mysql` connection |
| `Modules\Maintenance\Models\BackupSchedule` | Model | Maintenance | `sys_backup_schedules` on `mysql` connection |
| `Modules\Maintenance\Models\RestoreLog` | Model | Maintenance | Restore tracking |
| `Modules\Maintenance\Jobs\RunBackupJob` | Job | Maintenance | Background execution |
| `Modules\Maintenance\Services\BackupService` | Service | Maintenance | Dispatch logic |
| `Modules\Maintenance\Services\BackupScheduleService` | Service | Maintenance | Cron registration |
| `Modules\Maintenance\Services\BackupStorageService` | Service | Maintenance | Remote storage |
| `Modules\Maintenance\Services\DatabaseDumper` | Service | Maintenance | MySQL dump |
| `Modules\Maintenance\Services\FileBackupService` | Service | Maintenance | File collection |
| `Modules\Prime\Models\Tenant` | Model | Prime | Tenant listing |
| `Modules\Prime\Models\User` | Model | Prime | Notification recipients |

---

## 12. Mock Data / Seed Requirements

- At least 10 BackupRun records across various statuses (pending, running, completed, failed)
- At least 3 BackupSchedule records with different cron expressions
- At least 1 completed backup with a valid `disk_path` for download testing
- Sample tenant records in `sys_tenants` for subject display

---

## 13. Version History

| Version | Date | Author | Notes |
|---------|------|--------|-------|
| 1.0 | 2026-07-23 | OpenCode | Initial requirement document from controller analysis + FRD SYS_FRD_Complete_2026-06-30 |

---

## 14. Appendix — FRD Excerpts

**REQ-SYS-008:** Platform Backup Management — Status: PARTIAL (85%). BackupController + BackupScheduleController + services + job + notifications implemented; auth coverage on backup routes unknown.

**RPT-SYS-002 (Backup History Report):** Backup run timestamp, status, connections/schools, file size, duration, download link, error summary. Filters: status, date range. Rules: Only Completed runs downloadable; Failed runs show error; Queued/Running show real-time status.

**US-SYS-008:** Super Admin triggers/schedules backups. AC: manual trigger queues background job → "Backup queued" confirmation; completion updates status + sends notification; failure sends notification with error; download completed file; non-Super-Admin blocked with 403.

**BR-SYS-020:** Backup runs are queued background jobs; Super Admin is not blocked; completion and failure each trigger a notification.

---

## 15. Review Notes

- Backup implementation is **substantially complete** (~90%) with all core flows implemented
- The module placement (Maintenance vs SystemConfig) is the primary architectural concern
- All controller methods have proper authorization gates — this is one of the few SystemConfig-related features with complete auth coverage
- Form Request validation is well-structured with `withValidator()` for business rules
- The concurrent backup guard, disk space check, and empty-connections guard show defensive programming
- Notification system covers both mail and in-app database channels
- The `BackupScheduleService` gracefully handles missing DB during cold boot with try/catch

---

## 16. Open Questions

| # | Question | Raised By | Status |
|---|----------|-----------|--------|
| 1 | Should backup controllers be moved from Maintenance to SystemConfig to match FRD module assignment? | — | ⬜ Open |
| 2 | Should `maintenance.*` routes be aliased with `system-config.*` names for menu consistency? | — | ⬜ Open |
| 3 | Is a restore UI planned (RestoreLog model exists but no controller)? | — | ⬜ Open |
| 4 | Should backup retention policy (max age, max count, min free space) be configurable via UI? | — | ⬜ Open |

---

## 17. Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Business Analyst | OpenCode AI | 2026-07-23 | — |
| Tech Lead | — | — | — |
| QA Lead | — | — | — |
