# Attendance Entries — Requirements

## What It Does
Per-student roll-call entry within an attendance session. Records individual attendance status (present/absent/leave/late) with optional late remarks and check-in time.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `attendance_id` | BIGINT UNSIGNED FK → hst_attendance | Required. ON DELETE CASCADE. |
| `student_id` | INT UNSIGNED FK → std_students | Required. |
| `status` | INT UNSIGNED FK → hst_dynamic_status_masters | Required. |
| `late_remarks` | VARCHAR(255) | Nullable. |
| `check_in_time` | TIME | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Unique Constraint**
- (`attendance_id`, `student_id`) — one entry per student per session

**Parent Notification**
- Absent status triggers parent notification after 30 minutes
- If absent is corrected to present before notification, no alert is sent

**Cascading**
- When attendance session is deleted, entries cascade delete

## CRUD Operations

**List** — `GET /hostel/attendance/{session}/entries` → shown as editable table within session detail | Filtered by status

**Store** — `POST /hostel/attendance/{session}/entries` → creates one or many entries

**Bulk Mark** — `POST /hostel/attendance/{session}/bulk-mark` → marks all students present in one action

**Edit** — Individual entry status can be changed while session is open via inline edit

**Delete** — Entry removed when session is open

## Permissions

| Operation | Permission Key |
|---|---|
| View entries | `tenant.hostel-attendance.view` |
| Create/edit | `tenant.hostel-attendance.update` |
