# Subscription Plans — Requirements

## Parent Tab: Meal Cards

## What It Does
Meal subscription plan definitions — monthly, termly, or annual billing cycles. Plans define which meal categories are included and at what price. Hostel plans auto-enroll students on hostel admission; staff plans signal payroll deduction.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `name` | VARCHAR(150) | Required. Plan name (e.g. Full Day Plan, Hostel Mess Plan). |
| `description` | TEXT | Nullable. |
| `included_category_ids_json` | JSON | Required. Array of caf_menu_categories.id included. |
| `billing_period` | ENUM('Monthly','Termly','Annual') | Default 'Monthly'. |
| `price` | DECIMAL(10,2) | Required. Plan price in INR. |
| `academic_term_id` | SMALLINT UNSIGNED FK → sch_academic_terms | Nullable. Term this plan applies to. |
| `is_hostel_plan` | TINYINT(1) | Default 0. Auto-enroll on hostel admission (BR-CAF-015). |
| `is_staff_plan` | TINYINT(1) | Default 0. For staff PAY module deduction (BR-CAF-019). |
| `is_active` | TINYINT(1) | Default 1. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

## Business Rules

### Field-Level Validation

- Every plan must have a name.
- At least one meal category must be included in the plan. Every selected category must be valid and currently active.
- Plans are billed monthly, termly, or annually.
- A price must be set for each plan. It must be zero or a positive amount.
- A plan can optionally be linked to a specific academic term.
- A plan cannot be both a hostel plan and a staff plan simultaneously — these two types are mutually exclusive.

### JSON Structure: `included_category_ids_json`

```json
[1, 2, 3]
```

- A valid list of category IDs must be provided.
- At least one category must be included — empty lists are rejected with: "At least one meal category must be included in the plan."
- If duplicate categories are provided, the extras are silently removed.
- Every referenced category must exist and be currently active. Otherwise: "One or more selected meal categories are invalid or inactive."
- If the data cannot be interpreted as a valid list, the submission is rejected with: "The included categories format is invalid."

### Hostel Plan Auto-Enrollment (BR-CAF-015)

- When `is_hostel_plan = true`: upon hostel allotment (student assigned to hostel bed), auto-create enrollment.
- Cheapest active hostel plan auto-assigned. If multiple hostel plans, cheapest one is used.
- Auto-enrollment: status = 'Active', start_date = allotment_date, end_date = plan's academic term end.
- If no hostel plan exists, no auto-enrollment created.

### Staff Plan (BR-CAF-019)

- When `is_staff_plan = true`: eligible for staff enrollment.
- CAF never writes to PAY module. `payroll_deduction_flag` on staff meal logs is the read-only signal.

### Deleting a Plan

- A plan can only be deleted if no one is currently enrolled in it. If there are active enrollments, the system blocks the deletion and shows: "Cannot delete plan with active enrollments. Cancel all enrollments first."
- When deleted, the record is hidden from active use but remains saved in the database for record-keeping.

### List View

- Controller: SubscriptionPlanController@index. Gate: `tenant.cafeteria.subscription-plan.viewAny`.
- Columns: Name, Billing Period, Price, Included Categories (count/names), Type (Hostel/Staff/General badge), Status, Actions.

## Permissions

| Operation | Permission Key |
|---|---|
| CRUD | `tenant.cafeteria.subscription-plan.*` |
