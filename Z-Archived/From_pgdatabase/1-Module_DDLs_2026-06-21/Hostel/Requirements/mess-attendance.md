# Mess Attendance — Requirements

## What It Does
Per-meal student attendance for the mess. Tracks which students ate each meal (breakfast/lunch/dinner/snacks) on each date. Used for meal planning and mess bill calculation.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `attendance_date` | DATE | Required. |
| `meal_type` | ENUM(breakfast, lunch, dinner, snacks) | Required. |
| `student_id` | INT UNSIGNED FK → std_students | Required. |
| `status` | INT UNSIGNED FK → hst_dynamic_status_masters | Required. |
| `is_special_diet_served` | TINYINT(1) | Default 0. |
| `special_diet_served_desc` | VARCHAR(255) | Nullable. |
| `marked_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `shift_id` | TINYINT UNSIGNED | Nullable. For multi-shift mess. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Unique Constraint**
- (`hostel_id`, `attendance_date`, `meal_type`, `student_id`)

**Bulk Mark**
- All students marked present, then individual adjustments

## CRUD Operations

**Index** — `GET /hostel/mess/attendance` → filter by date, meal type, hostel

**Store** — `POST /hostel/mess/attendance` → single attendance record

**Bulk Store** — `POST /hostel/mess/attendance/bulk` → bulk mark all students

**Report** — `GET /hostel/mess/attendance/report` → monthly attendance report

## Permissions

| Operation | Permission Key |
|---|---|
| View | `tenant.hostel-mess-attendance.viewAny` |
| Create/edit | `tenant.hostel-mess-attendance.create` |
