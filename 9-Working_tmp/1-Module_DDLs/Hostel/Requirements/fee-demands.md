# Fee Demands (Hostel) — Requirements

## What It Does
Local audit of fee demands raised against the StudentFee module. Every charge originating in the hostel module (room rent, mess, damage, penalties) is logged here for reconciliation.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | INT UNSIGNED FK → std_students | Required. |
| `allotment_id` | BIGINT UNSIGNED FK → hst_allotments | Nullable. NULL for one-off charges. |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `academic_session_id` | INT UNSIGNED FK → sch_academic_term | Required. |
| `demand_type` | ENUM(room_rent, mess, electricity, laundry, security_deposit, damage, penalty, adjustment, other) | Required. |
| `period_start` | DATE | Nullable. |
| `period_end` | DATE | Nullable. |
| `amount` | DECIMAL(10,2) | Required. |
| `description` | VARCHAR(500) | Nullable. |
| `source_table` | VARCHAR(100) | Nullable. Origin reference. |
| `source_id` | BIGINT UNSIGNED | Nullable. |
| `status` | INT UNSIGNED FK → hst_dynamic_status_masters | Default 1. |
| `pushed_at` | TIMESTAMP | Nullable. |
| `external_demand_id` | VARCHAR(100) | Nullable. |
| `external_invoice_id` | VARCHAR(100) | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Lifecycle**
Draft → Pushed → Accepted/Rejected → Revised → Settled

**Business Rules**
- Auto-generated on allotment creation from fee structure
- Damage charges linked via `source_table` = 'hst_room_inventory'
- Payment status synced from StudentFee module
- Overdue = past due date without full payment

## CRUD Operations

**Create** — `POST /hostel/fee-demands` → manual demand creation for one-off charges

**List** — `GET /hostel/fee-demands` → paginated | Filter by status, student, demand type | Columns: Student, Type, Amount, Period, Status, Actions

**View** — `GET /hostel/fee-demands/{id}` → full detail

**Edit** — `GET /hostel/fee-demands/{id}/edit` | `PUT` → updates

**Delete (Soft)** — `DELETE /hostel/fee-demands/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-fee-demand.viewAny` |
| View details | `tenant.hostel-fee-demand.view` |
| Create | `tenant.hostel-fee-demand.create` |
| Edit/update | `tenant.hostel-fee-demand.update` |
| Soft delete | `tenant.hostel-fee-demand.delete` |
| Restore | `tenant.hostel-fee-demand.restore` |
| Force delete | `tenant.hostel-fee-demand.forceDelete` |
