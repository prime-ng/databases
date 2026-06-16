# Mess Opt-Outs — Requirements

## What It Does
Per-meal opt-out requests. Students can opt out of mess meals for specific dates/meals. Approved opt-outs auto-mark mess attendance as absent and adjust mess bills.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | INT UNSIGNED FK → std_students | Required. |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `from_date` | DATE | Required. |
| `to_date` | DATE | Required. |
| `meal_types_json` | JSON | Required. Meals being skipped. |
| `reason` | ENUM(outside_meal, fasting, medical, personal, exam_period, other) | Required. |
| `reason_notes` | VARCHAR(500) | Nullable. |
| `is_recurring` | TINYINT(1) | Default 0. |
| `recurrence_pattern_json` | JSON | Nullable. |
| `requested_at` | TIMESTAMP | Required. |
| `approved_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `approved_at` | TIMESTAMP | Nullable. |
| `status` | INT UNSIGNED FK → hst_dynamic_status_masters | Default 1. |
| `mess_bill_credit_applied` | TINYINT(1) | Default 0. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Lifecycle**
Pending → Approved → Active → Expired / Rejected / Cancelled

**Bill Credit**
- `mess_bill_credit_applied` prevents double-crediting in billing

## CRUD Operations

**Create** — `POST /hostel/mess/opt-outs` → validates → saves

**List** — Tab in Mess & Dining | Paginated | Filter by status, student

**Approve** — `POST /hostel/mess/opt-outs/{id}/approve` → sets approved_by, approved_at → redirects

**Reject** — `POST /hostel/mess/opt-outs/{id}/reject` → records rejection → redirects

**Delete** — `DELETE /hostel/mess/opt-outs/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View | `tenant.hostel-mess-opt-out.viewAny` |
| Create | `tenant.hostel-mess-opt-out.create` |
| Approve | `tenant.hostel-mess-opt-out.approve` |
| Reject | `tenant.hostel-mess-opt-out.reject` |
