# Attendance (Sessions) — Requirements

## What It Does
Roll call session management for hostel shifts (morning, evening, night). Each session aggregates student attendance entries for a specific hostel/date/shift combination.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `attendance_date` | DATE | Required. |
| `shift` | ENUM(morning, evening, night) | Required. |
| `marked_by` | INT UNSIGNED FK → sys_users | Required. |
| `present_count` | SMALLINT UNSIGNED | Default 0. |
| `absent_count` | SMALLINT UNSIGNED | Default 0. |
| `leave_count` | SMALLINT UNSIGNED | Default 0. |
| `late_count` | SMALLINT UNSIGNED | Default 0. |
| `is_locked` | TINYINT(1) | Default 0. 1 = no further edits. |
| `remarks` | VARCHAR(500) | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Unique Constraint**
- (`hostel_id`, `attendance_date`, `shift`) — one session per shift per day per hostel

**Session Lifecycle**
Open → Locked (read-only)

**Business Rules**
- Session cannot be created for a future date
- Locked sessions are read-only
- Counts (present, absent, leave, late) are auto-summed from entries
- On leave pass approval, student is auto-marked as "On Leave" in entries
- Students in sick bay are auto-marked as "In Sick Bay"

## CRUD Operations

**Create** — `GET /hostel/attendance/create` → form with hostel, date, shift | `POST /hostel/attendance` → validates → creates → redirects to entries page

**List** — `GET /hostel/attendance` → paginated table | Columns: Date, Shift, Hostel, Present, Absent, Leave, Late, Locked, Actions | Tab in Allotments page

**View** — `GET /hostel/attendance/{session}` → shows session summary

**View Entries** — `GET /hostel/attendance/{session}/entries` → shows per-student entries for this session

**Store Entries** — `POST /hostel/attendance/{session}/entries` → saves individual attendance entries

**Bulk Mark** — `POST /hostel/attendance/{session}/bulk-mark` → marks all students as present, then allows individual adjustments

**Lock** — `POST /hostel/attendance/{session}/lock` → sets `is_locked = 1` → no further edits

**Edit** — Only when session is open (not locked)

**Delete (Soft)** — Only when session is open

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-attendance.viewAny` |
| View details | `tenant.hostel-attendance.view` |
| Create | `tenant.hostel-attendance.create` |
| Edit/update | `tenant.hostel-attendance.update` |
| Lock | `tenant.hostel-attendance.lock` |
| Soft delete | `tenant.hostel-attendance.delete` |
| Restore | `tenant.hostel-attendance.restore` |
| Force delete | `tenant.hostel-attendance.forceDelete` |
