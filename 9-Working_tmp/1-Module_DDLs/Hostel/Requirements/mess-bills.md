# Mess Bills — Requirements

## What It Does
Monthly mess bill summary per student. Calculates charges based on meal plan, attendance, opt-outs, and special diets. Pushes bill amounts to StudentFee module for collection.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | INT UNSIGNED FK → std_students | Required. |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `academic_session_id` | INT UNSIGNED FK → sch_academic_term | Required. |
| `bill_month` | DATE | Required. First day of month. |
| `meal_plan` | ENUM(full_board, lunch_only, dinner_only, none) | Required. |
| `total_meals_planned` | SMALLINT UNSIGNED | Required. |
| `meals_consumed` | SMALLINT UNSIGNED | Default 0. |
| `meals_on_leave` | SMALLINT UNSIGNED | Default 0. |
| `meals_opted_out` | SMALLINT UNSIGNED | Default 0. |
| `special_diet_count` | SMALLINT UNSIGNED | Default 0. |
| `base_charge` | DECIMAL(10,2) | Default 0.00. |
| `special_diet_charge` | DECIMAL(10,2) | Default 0.00. |
| `leave_credit` | DECIMAL(10,2) | Default 0.00. |
| `opt_out_credit` | DECIMAL(10,2) | Default 0.00. |
| `manual_adjustment` | DECIMAL(10,2) | Default 0.00. |
| `adjustment_reason` | VARCHAR(255) | Nullable. |
| `total_amount` | DECIMAL(10,2) | GENERATED ALWAYS AS (base_charge + special_diet_charge - leave_credit - opt_out_credit + manual_adjustment) STORED |
| `pushed_to_fee` | TINYINT(1) | Default 0. |
| `pushed_at` | TIMESTAMP | Nullable. |
| `fee_demand_id` | BIGINT UNSIGNED | Nullable. |
| `status` | INT UNSIGNED FK → hst_dynamic_status_masters | Default 1. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Unique Constraint**
- (`student_id`, `hostel_id`, `bill_month`)

**Lifecycle**
Draft → Finalised → Disputed → Adjusted → Settled

**total_amount** — Auto-computed generated column

## CRUD Operations

**Create** — `POST /hostel/mess/bills` → generates bill

**List** — Tab in Mess & Dining | Paginated | Columns: Student, Month, Total, Status, Actions

**Publish** — `POST /hostel/mess/bills/{id}/publish` → sets status to finalised

**View** — `GET /hostel/mess/bills/{id}` → detail with breakdown

**Edit** — `GET /hostel/mess/bills/{id}/edit` | `PUT` → manual adjustment

**Delete (Soft)** — `DELETE /hostel/mess/bills/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View | `tenant.hostel-mess-bill.viewAny` |
| Create | `tenant.hostel-mess-bill.create` |
| Edit | `tenant.hostel-mess-bill.update` |
| Publish | `tenant.hostel-mess-bill.publish` |
