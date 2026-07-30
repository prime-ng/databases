# Platform Backup Management — Test Case List

## 1. Module Overview

| Attribute | Value |
|-----------|-------|
| **FRD Module** | SystemConfig (REQ-SYS-008) |
| **Actual Module** | **Maintenance** (`Modules\Maintenance`) |
| **Controllers** | `BackupController`, `BackupScheduleController` |
| **Route Prefix** | `maintenance.backup.*`, `maintenance.backup.schedules.*` |
| **Permissions** | `system-config.backup.*` (5 abilities), `system-config.backup-schedule.*` (4 abilities) |
| **Auth Pattern** | `Gate::authorize()` on every method ✅ |
| **DB Tables** | `sys_backup_runs`, `sys_backup_schedules` (central `mysql` connection) |
| **Background Job** | `RunBackupJob` (queue: `backup`, tries: 1, timeout: 600s) |
| **Notifications** | `BackupSuccessNotification`, `BackupFailedNotification` (mail + database) |

---

## 2. Test Environment

- PHP 8.2+, Laravel 12
- Queue worker configured for `backup` queue (or `sync` driver for testing)
- MySQL 8.0+ with `sys_backup_runs` and `sys_backup_schedules` tables in central DB
- `mysqldump` available on the system (for actual backup execution)
- At least 3 tenant records in `sys_tenants` for multi-tenant backup tests
- `mail` driver set to `log` for notification tests
- Sufficient disk space (> 500MB free for backup file generation)

---

## 3. Test Case Matrix

### 3.1 Authentication & Authorization

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-BK-01 | Unauthenticated user redirected on index | Not logged in | 1. Access `GET /maintenance/backup` | Redirected to login | — | — | ⬜ | ◌ |
| TC-BK-02 | User without backup.viewAny gets 403 on index | No `system-config.backup.viewAny` | 1. Log in without permission<br>2. Access index | 403 Forbidden | — | — | ⬜ | ◌ |
| TC-BK-03 | User with backup.viewAny can view index | Has permission | 1. Log in with permission<br>2. Access index | 200 OK | — | — | ⬜ | ◌ |
| TC-BK-04 | User without backup.create gets 403 on create page | No create permission | 1. Access `GET /maintenance/backup/create` | 403 Forbidden | — | — | ⬜ | ◌ |
| TC-BK-05 | User without backup.create gets 403 on store | No create permission | 1. POST to store route | 403 Forbidden | — | — | ⬜ | ◌ |
| TC-BK-06 | User without backup.download gets 403 on download | No download permission | 1. Access download route | 403 Forbidden | — | — | ⬜ | ◌ |
| TC-BK-07 | User without backup.delete gets 403 on destroy | No delete permission | 1. DELETE to destroy route | 403 Forbidden | — | — | ⬜ | ◌ |
| TC-BK-08 | Unauthenticated user redirected on schedule index | Not logged in | 1. Access schedules index | Redirected to login | — | — | ⬜ | ◌ |
| TC-BK-09 | User without backup-schedule.viewAny gets 403 on schedule index | No schedule view permission | 1. Access schedule index | 403 Forbidden | — | — | ⬜ | ◌ |
| TC-BK-10 | User without backup-schedule.create gets 403 on schedule create | No schedule create | 1. Access schedule create route | 403 Forbidden | — | — | ⬜ | ◌ |
| TC-BK-11 | User without backup-schedule.update gets 403 on schedule update | No schedule update | 1. Access schedule edit/update | 403 Forbidden | — | — | ⬜ | ◌ |
| TC-BK-12 | User without backup-schedule.delete gets 403 on schedule delete | No schedule delete | 1. DELETE schedule | 403 Forbidden | — | — | ⬜ | ◌ |

### 3.2 Backup Index — Subject Display

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-BK-13 | Index page shows central subjects (Prime DB + Global DB) | Any state | 1. View backup index | Two central subjects listed: "Prime DB" (mysql) and "Global DB" (global_master_mysql) | — | — | ⬜ | ◌ |
| TC-BK-14 | Index page shows all tenants as subjects | Tenants exist | 1. View backup index | All tenants listed with name, backup_path (from tenant record) | — | — | ⬜ | ◌ |
| TC-BK-15 | Per-subject stats: total_backups and last_backup_at | Completed runs exist | 1. View subject row | Shows count of completed backups and last completed timestamp | — | — | ⬜ | ◌ |
| TC-BK-16 | Active backup indicator on subjects | Pending/running run exists | 1. View subject with active run | `is_active` flag true; visual indicator shown | — | — | ⬜ | ◌ |
| TC-BK-17 | `hasActive` global flag shown | Any active backup | 1. View index with active run | `$hasActive` true; global active indicator | — | — | ⬜ | ◌ |

### 3.3 Backup Create (Manual Trigger)

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-BK-18 | Create page shows central connection checkboxes | Any state | 1. Access create page | Checkboxes for "Prime DB" (mysql) and "Global DB" (global_master_mysql) | — | — | ⬜ | ◌ |
| TC-BK-19 | Create page shows tenant checkboxes | Tenants exist | 1. Access create page | All tenants listed with checkboxes | — | — | ⬜ | ◌ |
| TC-BK-20 | Create page shows "All Tenants" checkbox | Any state | 1. Access create page | "All Tenants" checkbox present | — | — | ⬜ | ◌ |
| TC-BK-21 | Create page shows "Include Files" toggle | Any state | 1. Access create page | Include files checkbox/switch present | — | — | ⬜ | ◌ |
| TC-BK-22 | Submit backup with valid selections | User has permission | 1. Select "Prime DB" + 1 tenant<br>2. Submit | Redirected to index with success message; BackupRun created with status=pending; job dispatched | — | — | ⬜ | ◌ |
| TC-BK-23 | Quick backup (one-click from index) | User has permission | 1. Click quick backup on a subject | Redirected with success; backup queued | — | — | ⬜ | ◌ |
| TC-BK-24 | Quick backup for "all" tenants | User has permission | 1. Click quick backup on "All Tenants" | Backup with `all_tenants = true` queued | — | — | ⬜ | ◌ |
| TC-BK-25 | Empty selection rejected by validation | No connections/tenants selected | 1. Submit with empty selections | Validation error: "Select at least one database or tenant to back up." | — | — | ⬜ | ◌ |
| TC-BK-26 | Validation: connections must be valid values | Invalid connection | 1. Submit with connection "invalid_db" | Validation error on `connections.*` (must be in: mysql, global_master_mysql) | — | — | ⬜ | ◌ |

### 3.4 Backup Execution (Queue/Job)

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-BK-27 | Backup job dispatches to `backup` queue | Run created | 1. Inspect `BackupService::dispatch()` | Job dispatched to `backup` queue | — | — | ✅ | ◌ |
| TC-BK-28 | Backup run status "pending" after creation | After dispatch | 1. Check BackupRun record | `status = 'pending'` | — | — | ⬜ | ◌ |
| TC-BK-29 | Job updates status to "running" when started | Job picked up | 1. Queue worker processes job | Status updated to `running`, `started_at` set to now | — | — | ⬜ | ◌ |
| TC-BK-30 | Job completes successfully | Backup succeeds | 1. Job runs successfully | Status = `completed`; `file_size_bytes`, `disk_path`, `completed_at` set; progress = 100 | — | — | ⬜ | ◌ |
| TC-BK-31 | Job completes with warnings | Upload fails but dump succeeds | 1. Simulate upload failure | Status = `completed_with_warnings`; error_message contains warning text | — | — | ⬜ | ◌ |
| TC-BK-32 | Job fails on exception | Dump throws | 1. Simulate dump failure | Status = `failed`; error_message contains exception details | — | — | ⬜ | ◌ |
| TC-BK-33 | Concurrent backup guard: second job fails | One backup already running | 1. Trigger 2nd backup while 1st running | 2nd run: status = `failed`, error = "Another backup is already in progress." | — | — | ⬜ | ◌ |
| TC-BK-34 | Insufficient disk space guard | < 500MB free | 1. Mock low disk space | Status = `failed`, error = "Insufficient disk space. At least 500MB required." | — | — | ⬜ | ◌ |
| TC-BK-35 | No valid connections guard | All connections failed | 1. Backup with no valid connections | Status = `failed`, error = "No valid database connections to back up." | — | — | ⬜ | ◌ |
| TC-BK-36 | `job failed()` override catches unhandled exceptions | Queue worker crash | 1. Force queue worker failure | Status = `failed`; notification sent | — | — | ⬜ | ◌ |
| TC-BK-37 | Progress tracking updates during run | In-progress backup | 1. Monitor progress during dump | Progress percentage updated (0-100) | — | — | ⬜ | ◌ |
| TC-BK-38 | All Tenants backup includes all active tenants | Multiple tenants | 1. Trigger with all_tenants=true | All tenant IDs resolved and backed up | — | — | ⬜ | ◌ |
| TC-BK-39 | Include Files option collects tenant files | include_files=true | 1. Trigger with include_files | FileBackupService::collectFiles() called | — | — | ⬜ | ◌ |

### 3.5 Status Polling

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-BK-40 | Statuses endpoint returns active runs | Pending/running runs exist | 1. GET `/maintenance/backup/statuses` | JSON array of active runs with id, status, progress, file_size_bytes, completed_at | — | — | ⬜ | ◌ |
| TC-BK-41 | Statuses endpoint returns empty array when no active runs | No pending/running | 1. GET statuses | `[]` | — | — | ⬜ | ◌ |
| TC-BK-42 | Subject history endpoint returns per-subject runs | Runs for a subject | 1. GET `/maintenance/backup/{type}/{id}/history` | JSON with `runs` + `restores` arrays | — | — | ⬜ | ◌ |
| TC-BK-43 | Subject history: runs contain formatted dates | Completed runs | 1. View subject history | Dates in "d M Y, h:i A" format; file_size_human readable | — | — | ⬜ | ◌ |

### 3.6 Backup Download

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-BK-44 | Download completed backup (local) | Completed run, local file exists | 1. Click download | File downloaded via `response()->download()` | — | — | ⬜ | ◌ |
| TC-BK-45 | Download completed backup (remote) | Completed run, only remote file | 1. Click download | File temp-downloaded via `BackupStorageService::downloadToTemp()` | — | — | ⬜ | ◌ |
| TC-BK-46 | Download non-completed backup = 404 | Pending/failed run | 1. Attempt download | 404 Not Found | — | — | ⬜ | ◌ |
| TC-BK-47 | Download non-existent backup run = 404 | Invalid ID | 1. Request download for invalid ID | 404 (Model binding) | — | — | ⬜ | ◌ |

### 3.7 Backup Delete

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-BK-48 | Delete completed backup — file removed + record deleted | Completed run | 1. Delete backup | Local file deleted; remote file deleted; BackupRun record deleted; redirected with success | — | — | ⬜ | ◌ |
| TC-BK-49 | Delete failed backup — no file to clean, record deleted | Failed run | 1. Delete failed backup | No file to clean; record deleted; success | — | — | ⬜ | ◌ |

### 3.8 Backup Schedule CRUD

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-BK-50 | Schedule index shows all schedules paginated (20/page) | 25 schedules exist | 1. View schedule index | 20 on page 1; pagination links | — | — | ⬜ | ◌ |
| TC-BK-51 | Schedule create form shows all required fields | Any state | 1. Access schedule create | Fields: label, cron_expression, connection checkboxes, tenant checkboxes, all_tenants, include_files, is_active | — | — | ⬜ | ◌ |
| TC-BK-52 | Create schedule with valid data | User has permission | 1. Fill form + submit | Schedule created; redirected with success | — | — | ⬜ | ◌ |
| TC-BK-53 | Create schedule: label required | Empty label | 1. Submit with empty label | Validation error on label | — | — | ⬜ | ◌ |
| TC-BK-54 | Create schedule: cron_expression required | Empty cron | 1. Submit with empty cron | Validation error on cron_expression | — | — | ⬜ | ◌ |
| TC-BK-55 | Create schedule: at least one DB or all_tenants | Empty selection | 1. Submit with no connections, tenants, or all_tenants | Validation error: "Select at least one database, tenant, or enable All tenants." | — | — | ⬜ | ◌ |
| TC-BK-56 | Edit schedule form pre-populated | Existing schedule | 1. Access edit route | Form shows current label, cron, selections | — | — | ⬜ | ◌ |
| TC-BK-57 | Update schedule | Changed values | 1. Modify label + cron, submit | Schedule updated; redirected with success | — | — | ⬜ | ◌ |
| TC-BK-58 | Delete schedule | Existing schedule | 1. Click delete | Schedule deleted; redirected with success | — | — | ⬜ | ◌ |
| TC-BK-59 | Toggle schedule status active/inactive | Existing schedule | 1. Click toggle | `is_active` flipped; success message | — | — | ⬜ | ◌ |

### 3.9 Notifications

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-BK-60 | Success notification sent on completion | Job completes | 1. Run successful backup | BackupSuccessNotification sent to triggering user via mail + database | — | — | ⬜ | ◌ |
| TC-BK-61 | Success notification has correct data | Completed run | 1. Inspect notification | Subject: "Backup completed — {name}"; contains file size, duration, download link | — | — | ⬜ | ◌ |
| TC-BK-62 | Failure notification sent on failure | Job fails | 1. Run failing backup | BackupFailedNotification sent with error message | — | — | ⬜ | ◌ |
| TC-BK-63 | Failure notification has correct data | Failed run | 1. Inspect notification | Subject: "Backup FAILED — {name}"; error message included | — | — | ⬜ | ◌ |
| TC-BK-64 | Notification fallback to admin email when no triggering user | Scheduled run (triggered_by = null) | 1. Run scheduled backup | Notification sent to `config('mail.admin_address')` | — | — | ⬜ | ◌ |

### 3.10 Backup Name Generation

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-BK-65 | Manual backup name format | Manual trigger | 1. Inspect run name | "Manual — prime_db, 3 tenant DBs" | — | — | ⬜ | ◌ |
| TC-BK-66 | Manual backup with all tenants | Manual + all_tenants | 1. Inspect run name | "Manual — prime_db, all tenants" | — | — | ⬜ | ◌ |
| TC-BK-67 | Scheduled backup name format | Schedule trigger | 1. Inspect scheduled run name | "Scheduled — global_db" | — | — | ⬜ | ◌ |
| TC-BK-68 | Backup with no connections description | Only tenants selected | 1. Inspect run name | "Manual — 1 tenant DB" (no connections listed) | — | — | ⬜ | ◌ |

---

## 4. Boundary & Edge Cases

| TC# | Test Case | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------|-----------------|----|----|--------|----|
| TC-BK-69 | No tenants in system | 1. View backup index | Only central subjects shown; no tenant subjects | — | — | ⬜ | ◌ |
| TC-BK-70 | Schedule with invalid cron expression | 1. Submit with invalid cron | Stored as-is (no cron validation in request rules) | — | — | ⬜ | ◌ |
| TC-BK-71 | Schedule with very long label (255+ chars) | 1. Submit with > 255 label chars | Validation error (max:255 rule) | — | — | ⬜ | ◌ |
| TC-BK-72 | Delete backup run that doesn't exist | 1. DELETE to non-existent ID | 404 (Model binding) | — | — | ⬜ | ◌ |
| TC-BK-73 | Trigger backup while queue worker down | No worker running | 1. Submit backup | Job dispatched to queue; stays pending until worker picks up | — | — | ⬜ | ◌ |
| TC-BK-74 | All tenants = true + specific tenants selected | 1. Submit with both | Both applied (all_tenants overrides specific selections? Behavior: all_tenants takes precedence) | — | — | ⬜ | ◌ |
| TC-BK-75 | Schedule with include_files toggled on | 1. Create schedule with include_files | Files collected on each scheduled run | — | — | ⬜ | ◌ |

---

## 5. Test Data Requirements

| Data Type | Quantity | Details |
|-----------|----------|---------|
| BackupRun records | ≥ 10 | Mix of: pending, running, completed, completed_with_warnings, failed |
| Completed backup files on disk | ≥ 3 | With actual file at disk_path |
| BackupSchedule records | ≥ 5 | Various cron expressions |
| Tenant records | ≥ 3 | With valid UUIDs for tenant DB resolution |
| Central connections | 2 | `mysql` (prime_db) + `global_master_mysql` (global_db) |
| Users with various permissions | ≥ 4 | Super Admin, user with backup.*, user with backup-schedule.*, no-permission user |

---

## 6. Test Execution Checklist

| Check | Description | Done? |
|-------|-------------|-------|
| Auth tests pass — all backup routes (TC-BK-01 to TC-BK-07) | | ⬜ |
| Auth tests pass — all schedule routes (TC-BK-08 to TC-BK-12) | | ⬜ |
| Backup index display correct (TC-BK-13 to TC-BK-17) | | ⬜ |
| Backup create/trigger works (TC-BK-18 to TC-BK-26) | | ⬜ |
| Job execution flow verified (TC-BK-27 to TC-BK-39) | | ⬜ |
| Status polling endpoints work (TC-BK-40 to TC-BK-43) | | ⬜ |
| Download works for local/remote files (TC-BK-44 to TC-BK-47) | | ⬜ |
| Delete works for completed/failed runs (TC-BK-48, TC-BK-49) | | ⬜ |
| Schedule CRUD verified (TC-BK-50 to TC-BK-59) | | ⬜ |
| Notifications sent correctly (TC-BK-60 to TC-BK-64) | | ⬜ |
| Name generation correct (TC-BK-65 to TC-BK-68) | | ⬜ |
| Edge cases tested (TC-BK-69 to TC-BK-75) | | ⬜ |

---

## 7. Automation Notes

- Use `Queue::fake()` for testing job dispatch without execution
- Use `Notification::fake()` for testing notification sending
- Use `Storage::fake('local')` for file operation tests
- For testing actual job execution: set `QUEUE_CONNECTION=sync` in test environment
- Mock `disk_free_space()` for disk space guard tests
- Mock `DatabaseDumper` to test job flow without actual MySQL dumps
- Create `BackupRun` model factories for test data setup
- Permission tests should use `Gate::authorize` — create users with specific permission grants
- Test schedule CRUD independently of the scheduler registration

---

## 8. Known Issues

| # | Issue | Impact | Status |
|---|-------|--------|--------|
| 1 | **Module Boundary Mismatch:** Backup features in Maintenance module, not SystemConfig as cited by FRD | Documentation/access confusion | ⬜ Open |
| 2 | Route names use `maintenance.*` prefix, not `system-config.*` — menu system may not link correctly | Navigation disconnect | ⬜ Open |
| 3 | RestoreLog model exists but no restore UI is exposed | Incomplete workflow | ⬜ Pending |
| 4 | No backup retention policy (max age, count) configurable via UI | Unlimited backup accumulation | ⬜ Enhancement |
| 5 | No feature tests exist — this list is forward-looking | All TCs unexecuted | ⬜ Backlog |

---

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/maintenance/backup` | `maintenance.backup.index` | `BackupController@index` |
| GET | `/maintenance/backup/create` | `maintenance.backup.create` | `BackupController@create` |
| POST | `/maintenance/backup` | `maintenance.backup.store` | `BackupController@store` |
| GET | `/maintenance/backup/{type}/{id}/backup` | `maintenance.backup.quick` | `BackupController@quickBackup` |
| GET | `/maintenance/backup/{type}/{id}/history` | `maintenance.backup.history` | `BackupController@subjectHistory` |
| GET | `/maintenance/backup/{run}/download` | `maintenance.backup.download` | `BackupController@download` |
| DELETE | `/maintenance/backup/{run}` | `maintenance.backup.destroy` | `BackupController@destroy` |
| GET | `/maintenance/backup/statuses` | `maintenance.backup.statuses` | `BackupController@statuses` |
| GET | `/maintenance/backup/schedules` | `maintenance.backup.schedules.index` | `BackupScheduleController@index` |
| GET | `/maintenance/backup/schedules/create` | `maintenance.backup.schedules.create` | `BackupScheduleController@create` |
| POST | `/maintenance/backup/schedules` | `maintenance.backup.schedules.store` | `BackupScheduleController@store` |
| GET | `/maintenance/backup/schedules/{schedule}/edit` | `maintenance.backup.schedules.edit` | `BackupScheduleController@edit` |
| PUT | `/maintenance/backup/schedules/{schedule}` | `maintenance.backup.schedules.update` | `BackupScheduleController@update` |
| DELETE | `/maintenance/backup/schedules/{schedule}` | `maintenance.backup.schedules.destroy` | `BackupScheduleController@destroy` |
| POST | `/maintenance/backup/schedules/{schedule}/toggle-status` | `maintenance.backup.schedules.toggleStatus` | `BackupScheduleController@toggleStatus` |

---

## 10. Execution Status

| Total TCs | Pass | Fail | Blocked | Not Run | Coverage |
|-----------|------|------|---------|---------|----------|
| 75 | 0 | 0 | 0 | 75 | 0% |

**Last Executed:** —
**Executed By:** —
**Environment:** —
**Remarks:** Initial test case list created from code analysis. Implementation is substantially complete (~90%) but module placement (Maintenance vs SystemConfig) is a known concern. Some tests require queue infrastructure.

---

## Document History

| Version | Date | Author | Notes |
|---------|------|--------|-------|
| 1.0 | 2026-07-23 | OpenCode AI | Initial TC list from controller + FRD analysis |
