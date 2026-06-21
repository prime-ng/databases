# Fee Structures (Hostel) — Requirements

## What It Does
Defines fee rates per room type, meal plan, and academic session. Components include room rent, mess charge, electricity, laundry, security deposit. Fee structures drive demand generation when allotments are created.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `academic_session_id` | INT UNSIGNED FK → sch_academic_term | Required. |
| `room_type` | TINYINT UNSIGNED FK → hst_room_types | Required. |
| `meal_plan` | ENUM(full_board, lunch_only, dinner_only, none) | Required. |
| `room_rent_monthly` | DECIMAL(10,2) | Default 0.00. |
| `mess_charge_monthly` | DECIMAL(10,2) | Default 0.00. |
| `electricity_charge_monthly` | DECIMAL(10,2) | Default 0.00. |
| `laundry_charge_monthly` | DECIMAL(10,2) | Default 0.00. |
| `security_deposit` | DECIMAL(10,2) | Default 0.00. |
| `effective_from` | DATE | Required. |
| `effective_to` | DATE | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Unique Constraint**
- (`hostel_id`, `academic_session_id`, `room_type`, `meal_plan`, `effective_from`)

**Fee Calculation**
- Proration: if student is allotted mid-month, fee is calculated from allotment date
- Fee demand is pushed to StudentFee module on allotment creation
- Changes mid-session only affect new allotments
- Defaulters report shows students with unpaid hostel fees

## CRUD Operations

**Create** — `GET /hostel/fee-structures/create` → form | `POST /hostel/fee-structures` → validates → saves → redirects

**List** — `GET /hostel/fee-structures` → paginated | Columns: Hostel, Session, Room Type, Meal Plan, Rent, Mess, Status, Actions

**View** — `GET /hostel/fee-structures/{id}` → detail view

**Calculate** — `GET /hostel/fee-structures/calculate` → fee preview form | `POST /hostel/fee-structures/calculate` → returns calculated fee for given student/period

**Defaulters** — `GET /hostel/fee-structures/defaulters` → lists students with overdue fees

**Edit** — `GET /hostel/fee-structures/{id}/edit` | `PUT` → validates → updates

**Delete (Soft)** — `DELETE /hostel/fee-structures/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-fee-structure.viewAny` |
| View details | `tenant.hostel-fee-structure.view` |
| Create | `tenant.hostel-fee-structure.create` |
| Edit/update | `tenant.hostel-fee-structure.update` |
| Soft delete | `tenant.hostel-fee-structure.delete` |
| Restore | `tenant.hostel-fee-structure.restore` |
| Force delete | `tenant.hostel-fee-structure.forceDelete` |
