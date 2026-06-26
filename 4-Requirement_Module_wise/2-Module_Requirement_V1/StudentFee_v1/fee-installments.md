# Fee Installments — Requirements

## What It Does
Divides the total fee amount into scheduled payments (installments) per fee structure. Typically 4 quarterly installments at 25% each, but configurable to any number with any percentage split. Each installment has a due date, grace period, and overdue detection.

Features:
- Configurable number of installments per structure
- Percentage or fixed amount per installment
- Due date with grace period
- Overdue detection via helper
- Grace period before late fee applies
- Soft-delete with full restore

## Database Fields

**fee_installments**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `fee_structure_id` | BIGINT UNSIGNED FK → `fee_structure_masters` | Required. CASCADE on delete. |
| `installment_no` | INTEGER | Required. Sequence number (1, 2, 3, 4...). Unique per structure. |
| `installment_name` | VARCHAR(200) | Required. E.g., `First Installment`, `Second Installment`, `Term 1`. |
| `due_date` | DATE | Required. Payment due date. |
| `percentage_due` | DECIMAL(5,2) | Required. Percentage of total fee due. E.g., 25.00. |
| `amount_due` | DECIMAL(12,2) | Required. Computed: `total_fee_amount × (percentage_due / 100)`. |
| `grace_days` | INTEGER | Default 0. Days after due date before fine applies. |
| `is_active` | BOOLEAN | Default true. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Percentage Validation**
- Sum of `percentage_due` across all installments for a structure must equal 100.00
- Validated on create and update
- If total would exceed 100% with a new installment, the update is blocked

**Amount Computation**
- `amount_due = structure.total_fee_amount × (percentage_due / 100)`
- Recalculated when `percentage_due` is updated or when structure `total_fee_amount` changes
- Stored explicitly (not computed at runtime)

**Due Date with Grace**
- Actual last payment date = `due_date + grace_days`
- Helper `getLastDateWithGrace()` returns the grace-extended date
- Helper `isOverdue()` returns true if current date > last date with grace and invoice is unpaid

**Installment Uniqueness**
- `installment_no` is unique per `fee_structure_id` (no duplicate installment numbers in one structure)
- Installments are ordered by `installment_no` (1, 2, 3...)

## CRUD Operations

**List Installments**
- Filterable by fee structure
- Shows: installment no, name, due date, percentage, amount, grace days

**Create Installment**
- Validation: unique installment_no per structure, total percentage ≤ 100% including new
- Amount auto-calculated from structure total × percentage

**Show / Edit / Update / Destroy**
- Edit: rechecks percentage ≤ 100% excluding self (other installments + new value)
- Destroy: deactivates + soft deletes

**Toggle Active Status / Soft Delete / Restore / Force Delete**

## Permissions

| Operation | Permission Key |
|---|---|
| View installments | `tenant.fee-installment.viewAny` |
| Create / Update / Delete | `tenant.fee-installment.*` |
