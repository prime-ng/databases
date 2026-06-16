# Room Reservations — Requirements

## What It Does
Pre-allotment reservation for incoming students. Holds a bed for a future student before they arrive on campus. Can be converted to a full allotment on confirmation, or cancelled/expired.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | INT UNSIGNED FK → std_students | Nullable. NULL during admission inquiry. |
| `prospective_name` | VARCHAR(150) | Nullable. Used when student_id is NULL. |
| `prospective_contact` | VARCHAR(20) | Nullable. |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `requested_room_id` | BIGINT UNSIGNED FK → hst_rooms | Nullable. Specific room requested. |
| `requested_room_type` | ENUM(single, double, triple, dormitory) | Nullable. |
| `requested_meal_plan` | ENUM(full_board, lunch_only, dinner_only, none) | Nullable. |
| `academic_session_id` | INT UNSIGNED FK → sch_academic_term | Required. |
| `intended_join_date` | DATE | Required. |
| `valid_until` | DATE | Required. Reservation expiry. |
| `deposit_amount` | DECIMAL(10,2) | Nullable. |
| `deposit_paid` | TINYINT(1) | Default 0. |
| `deposit_paid_at` | TIMESTAMP | Nullable. |
| `deposit_receipt_no` | VARCHAR(50) | Nullable. |
| `status` | INT UNSIGNED FK → hst_dynamic_status_masters | Default 1. |
| `converted_to_allotment_id` | BIGINT UNSIGNED FK → hst_allotments | Nullable. Set when converted. |
| `cancellation_reason` | VARCHAR(500) | Nullable. |
| `notes` | VARCHAR(500) | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Lifecycle**
Pending → Confirmed (converts to allotment) → Cancelled → Expired

**Business Rules**
- Reserved bed cannot be allotted to another student during the reservation period
- `valid_until` cannot exceed 30 days from `intended_join_date`
- Confirming creates an allotment for the same bed
- Multiple reservations cannot overlap on the same room

## CRUD Operations

**Create** — `GET /hostel/reservations/create` → form | `POST /hostel/reservations` → validates → saves → redirects

**List** — Tab in Allotments page | Table with search | Paginated 15 per page | Named page `reservations_page`

**View** — `GET /hostel/reservations/{id}` → detail view

**Edit** — `GET /hostel/reservations/{id}/edit` | `PUT` → updates

**Confirm** — `POST /hostel/reservations/{reservation}/confirm` → creates allotment from reservation → sets `converted_to_allotment_id` → redirects

**Cancel** — `POST /hostel/reservations/{reservation}/cancel` → records `cancellation_reason` → redirects

**Delete (Soft)** — `DELETE /hostel/reservations/{id}`

**Restore / Force Delete** — Standard trash patterns

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-reservation.viewAny` |
| View details | `tenant.hostel-reservation.view` |
| Create | `tenant.hostel-reservation.create` |
| Edit/update | `tenant.hostel-reservation.update` |
| Soft delete | `tenant.hostel-reservation.delete` |
| Restore | `tenant.hostel-reservation.restore` |
| Force delete | `tenant.hostel-reservation.forceDelete` |
