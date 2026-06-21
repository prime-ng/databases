# Laundry — Requirements

## What It Does
Per-student laundry submission and return ticket tracking. Manages the lifecycle from submission → collection → washing → drying → ironing → return with item counts and charge tracking.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | INT UNSIGNED FK → std_students | Required. |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `ticket_number` | VARCHAR(50) | Required. Unique within hostel. |
| `submitted_at` | TIMESTAMP | Required. |
| `expected_return_at` | TIMESTAMP | Nullable. |
| `returned_at` | TIMESTAMP | Nullable. |
| `item_count` | SMALLINT UNSIGNED | Required. |
| `items_description` | TEXT | Nullable. |
| `status` | INT UNSIGNED FK → hst_dynamic_status_masters | Default 1. |
| `weight_kg` | DECIMAL(5,2) | Nullable. For weight-based billing. |
| `charge_amount` | DECIMAL(10,2) | Nullable. |
| `charge_pushed_to_fee` | TINYINT(1) | Default 0. |
| `dispute_notes` | TEXT | Nullable. |
| `submitted_to` | VARCHAR(100) | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Unique Constraint**
- (`hostel_id`, `ticket_number`)

**Lifecycle**
submitted → in_wash → ready → collected / lost / damaged / disputed

**Turnaround**
- Max 48 hours (configurable)
- Tickets beyond 48 hours without "collected" status are flagged as delayed
- Ticket number format: LT-YYYYMMDD-admission_number-HHMMSS

## CRUD Operations

**Create** — `POST /hostel/laundry` → validates → saves

**List** — `GET /hostel/laundry` → paginated | Tab in Facility Mgmt | Columns: Ticket#, Student, Items, Status, Submitted, Actions | Filtered by status, date range

**View** — `GET /hostel/laundry/{id}` → detail

**Edit** — `GET /hostel/laundry/{id}/edit` | `PUT`

**Get Students (AJAX)** — `GET /hostel/laundry/get-students` → JSON

**Delete (Soft)** — `DELETE /hostel/laundry/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View | `tenant.hostel-laundry.viewAny` |
| Create | `tenant.hostel-laundry.create` |
| Edit | `tenant.hostel-laundry.update` |
| Delete | `tenant.hostel-laundry.delete` |
