# Movement Log (Gate Register) — Requirements

## What It Does
In/out movement register for students. Logs every exit from and entry to the hostel with timestamps, destination, purpose, and expected return time. Tracks overdue returns and supports parent consent for overnight movements.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | INT UNSIGNED FK → std_students | Required. |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `movement_date` | DATE | Required. |
| `out_time` | TIME | Required. |
| `in_time` | TIME | Nullable. Set on return. |
| `expected_return_time` | TIME | Nullable. |
| `destination` | VARCHAR(255) | Required. |
| `purpose` | VARCHAR(500) | Nullable. |
| `gate_pass_issued_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `overdue_notified` | TINYINT(1) | Default 0. |
| `is_overnight` | TINYINT(1) | Default 0. |
| `parent_consent_received` | TINYINT(1) | Default 0. |
| `consent_media_id` | INT UNSIGNED FK → sys_media | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Movement Lifecycle**
Out → Returned → Overdue (if expected return exceeded by 30+ min)

**Business Rules**
- A student cannot have two open (out) movements simultaneously
- Overdue movements are highlighted to warden dashboard
- Parent notification sent for overdue returns
- Overnight movements require parent consent

## CRUD Operations

**Create** — `GET /hostel/movement-log/create` → form | `POST /hostel/movement-log` → validates → saves → redirects

**List** — `GET /hostel/movement-log` → paginated table | Filters: Date, Hostel, Student | Columns: Student, Out Time, Destination, Expected Return, Status, Actions

**Pending Returns** — `GET /hostel/movement-log/pending` → shows students currently out (no in_time)

**Record Return** — `POST /hostel/movement-log/{id}/return` → sets `in_time` to now → closes movement

**View** — `GET /hostel/movement-log/{id}` → detail view

**Edit** — `GET /hostel/movement-log/{id}/edit` | `PUT` → updates

**Delete (Soft)** — `DELETE /hostel/movement-log/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-movement-log.viewAny` |
| View details | `tenant.hostel-movement-log.view` |
| Create | `tenant.hostel-movement-log.create` |
| Edit/update | `tenant.hostel-movement-log.update` |
| Soft delete | `tenant.hostel-movement-log.delete` |
| Record return | `tenant.hostel-movement-log.return` |
