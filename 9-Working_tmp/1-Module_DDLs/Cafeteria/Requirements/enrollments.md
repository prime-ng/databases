# Enrollments — Requirements

## Parent Tab: Meal Cards

## What It Does
Student/staff × plan enrollment records — tracks who is subscribed to which meal plan, their enrollment status (Active/Paused/Cancelled/Expired), and the enrollment period.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `subscription_plan_id` | INT UNSIGNED FK → caf_subscription_plans | Required. ON DELETE RESTRICT. |
| `student_id` | INT UNSIGNED FK → std_students | Nullable. Mutually exclusive with staff_id. |
| `staff_id` | INT UNSIGNED FK → sys_users | Nullable. Mutually exclusive with student_id. |
| `meal_card_id` | INT UNSIGNED FK → caf_meal_cards | Nullable. Plan fee deducted from this card. ON DELETE SET NULL. |
| `start_date` | DATE | Required. |
| `end_date` | DATE | Nullable. NULL = plan expiry. |
| `status` | ENUM('Active','Paused','Cancelled','Expired') | Default 'Active'. |
| `cancellation_reason` | TEXT | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

## Business Rules

### Field-Level Validation

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `subscription_plan_id` | Required, exists:caf_subscription_plans,id | |
| `student_id` / `staff_id` | Mutually exclusive | Both: "A subscription can only belong to either a student or a staff member, not both." Neither: "Select either a student or a staff member." |
| `meal_card_id` | Nullable, exists:caf_meal_cards,id | |
| `start_date` | Required, date | Must be today or future. |
| `end_date` | Nullable, date, after_or_equal:start_date | "End date must be on or after the start date." |
| `status` | Required, enum | Transitions validated by workflow below. |
| `cancellation_reason` | Required if status = 'Cancelled' | "A cancellation reason is required." |

### Enrollment Lifecycle State Machine

| From | To | Guard | Side Effects |
|---|---|---|---|
| Active | Paused | None | Benefits suspended. |
| Active | Cancelled | `cancellation_reason` required | Permanent termination. |
| Paused | Active | Not expired. If expired: "Cannot resume an expired enrollment." | Benefits resumed. |
| Active / Paused | Expired | Auto: `end_date < today()` | Nightly cron. |
| Cancelled | (any) | None. Immutable. | |

**Auto-Expiry Cron:**
- Nightly cron `SubscriptionService::expireEnrollments()` checks Active/Paused enrollments where `end_date < today()`.
- Batch updates with audit logging per enrollment.

### List View

- Controller: SubscriptionEnrollmentController@index. Gate: `tenant.cafeteria.subscription-enrollment.viewAny`.
- Columns: Plan Name, Student/Staff Name, Start Date, End Date, Status (badge), Actions.
- Filters: status dropdown (Active/Expired/Cancelled).

## Permissions

| Operation | Permission Key |
|---|---|
| Manage | `tenant.cafeteria.subscription-enrollment.*` |
