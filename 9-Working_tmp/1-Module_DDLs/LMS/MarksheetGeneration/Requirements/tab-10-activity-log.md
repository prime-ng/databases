# MarksheetGeneration Tab 10: Activity Log (Audit Trail)

This tab provides a complete audit trail of every significant action performed within the MarksheetGeneration module. Every computation trigger, publication event, lock, and unlock is recorded with full detail — who performed the action, when it happened, what the outcome was, and any associated remarks. This log is immutable and serves as the system of record for all marksheet lifecycle events.

---

## How It Works

The activity log displays a searchable, filterable table of all events recorded in the msh_computation_logs table. Each row shows the schedule name, the action performed (COMPUTE, RECOMPUTE, PUBLISH, UNLOCK, LOCK), the user who triggered the action, the start and completion timestamps, the duration, the number of students processed, the number of errors, and the final status (SUCCESS, FAILED, PARTIAL, or IN_PROGRESS).

The admin can filter events by schedule, by action type, by date range, and by status. Clicking on any row expands it to show the full error log in a readable format — if the computation failed, the error messages describe exactly which class-section or student caused the failure and why.

For unlock events, the remarks column contains the mandatory unlock reason provided by the admin. For publish events, the remarks may contain optional notes about the publication. All timestamps are recorded in the school's configured timezone.

---

## Important Business Rules

- The computation log is immutable — records cannot be edited or deleted. This is enforced at the database level (no deleted_at column on msh_computation_logs).
- Every compute or recompute action creates a new log entry. Previous entries for the same schedule are preserved for historical reference.
- An unlock action must always have a non-empty remarks field containing the reason. The system validates this before allowing the unlock.
- If a computation is triggered but the schedule is already being computed (status check fails), the log records the attempt as FAILED with an appropriate error message.
- The log table is expected to grow modestly — approximately 10-30 entries per school per academic session. No archiving is needed in Phase 1.
- Error logs are stored as JSON text. Each error entry contains: class_section_id, student_id (if applicable), error message, and timestamp.

---

## Database Columns & Behavior

### msh_computation_logs
- `id` — Primary key. INT UNSIGNED, auto-increment. Immutable — no soft deletes.
- `schedule_id` — FK to msh_marksheet_schedules. INT UNSIGNED. Cascade delete.
- `action` — Type of event. VARCHAR(30). Values: COMPUTE, RECOMPUTE, PUBLISH, UNLOCK, LOCK.
- `triggered_by` — FK to sys_users. INT UNSIGNED. Who performed the action.
- `started_at` — When the action started. DATETIME, NOT NULL.
- `completed_at` — When it finished. DATETIME, nullable. NULL while still in progress.
- `duration_seconds` — Total runtime in seconds. INT UNSIGNED, nullable.
- `total_students` — Students processed. INT UNSIGNED, nullable.
- `total_errors` — Error count. INT UNSIGNED, default 0.
- `status` — Outcome status. VARCHAR(20), default 'IN_PROGRESS'. Values: IN_PROGRESS, SUCCESS, FAILED, PARTIAL.
- `error_log` — Detailed error information. TEXT, nullable. Stored as JSON array.
- `remarks` — Free-text notes or unlock reason. TEXT, nullable.
- Indexed on schedule_id, triggered_by, and action for fast filtered queries.
- No deleted_at column — entries are permanent.

---

## Deep Analysis

### Business Workflows & State Machines
The activity log is an immutable append-only trail. Every significant action — **COMPUTE, RECOMPUTE, PUBLISH, UNLOCK, LOCK** — inserts a new row in `msh_computation_logs`. No UPDATE or DELETE is ever performed on these rows. The log captures the full lifecycle of each schedule: when it was first computed, if it was recomputed, when it was published, locked, and any subsequent unlocks. Each entry tracks its own status (`IN_PROGRESS → SUCCESS/FAILED/PARTIAL`), making the log a self-contained audit of each operation.

### Validation Rules & Edge Cases
- **Immutability enforced**: No `deleted_at` column. Application layer must prohibit any UPDATE or DELETE on this table.
- **Concurrent computation guard**: If a schedule already has an IN_PROGRESS log entry, the system rejects a new COMPUTE/RECOMPUTE request and logs a FAILED entry with an appropriate error message.
- Unlock events MUST have a non-empty `remarks` (min 10 chars). This is the unlock reason.
- Error logs are JSON arrays: `[{class_section_id, student_id?, message, timestamp}, ...]`. The frontend parses and displays these in an expandable panel.
- The log is expected to grow at ~10-30 entries per school per session. No archiving needed in Phase 1.
- Filters by schedule, action type, date range, and status must use indexes on `schedule_id`, `action`, and `status` for performance.
- Timestamps are stored in UTC; the UI converts to the school's configured timezone.

### Integration Points
- **msh_marksheet_schedules**: The parent entity for all logged actions. Cascade delete cleans up logs when a schedule is deleted (only possible in Draft).
- **sys_users**: `triggered_by` FK for user attribution.
- **sys_dropdowns**: Indirect — schedule status changes are also tracked via the log.
- **Student/Parent Portal**: In future phases, publication events in the log may drive notification triggers.

### Permissions Matrix
| Role | View All Logs | View Schedule-specific Logs | View Error Details | Export Logs |
|---|---|---|---|---|
| Super Admin | Yes | Yes | Yes | Yes |
| School Admin | Yes | Yes | Yes | Yes |
| Principal | Yes | Yes | Yes | Yes |
| Coordinator | Yes | Yes (own schedules) | Yes (own schedules) | No |
| Class Teacher | No | Own class-section only | Own class-section only | No |
| Subject Teacher | No | No | No | No |
| Student/Parent | No | No | No | No |
