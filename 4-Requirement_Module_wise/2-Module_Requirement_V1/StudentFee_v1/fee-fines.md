# Fee Fines (Late Fee) — Requirements

## What It Does
Defines late fee/fine rules for overdue invoices. Supports percentage-based (per day or flat per tier) and fixed-amount fine calculation. Fines can be recurring with configurable intervals, have maximum caps, grace periods, and expiry actions. Tracks fine transactions per student with full/partial waiver capability.

Features:
- 4 standard fine rules: 2% daily recurring, fixed ₹500, 5% capped ₹2,000, transport ₹300
- Fine calculation modes: PerDay (compound daily), FlatPerTier (one-time)
- Recurring vs one-time fine application
- Configurable grace period before fines apply
- Max fine amount cap
- Max fine installments limit
- Expiry actions (what happens when fine exceeds limit)
- Fine transactions per invoice with waiver workflow
- Scheduled command for automatic fine application
- Dry-run mode for preview

## Database Fields

**fee_fine_rules**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `rule_name` | VARCHAR(200) | Required. E.g., `Daily Late Fee 2%`, `Fixed Late Fee ₹500`. |
| `applicable_on` | ENUM | Invoices, specific heads, etc. |
| `applicable_id` | INTEGER | Nullable. Specific head/group ID. |
| `fine_type` | ENUM | `Percentage`, `Fixed`. |
| `fine_value` | DECIMAL(10,2) | Required. If Percentage: e.g., 2.00 = 2%. If Fixed: e.g., 500.00. |
| `fine_calculation_mode` | ENUM | `PerDay`, `FlatPerTier`. |
| `max_fine_amount` | DECIMAL(12,2) | Nullable. Maximum fine that can accumulate. |
| `grace_period_days` | INTEGER | Default 0. Days after due date before fine starts. |
| `recurring` | BOOLEAN | Default false. Whether fine is reapplied on interval. |
| `recurring_interval_days` | INTEGER | Nullable. Days between recurring fine applications. |
| `max_fine_installments` | INTEGER | Nullable. Maximum number of times fine can be applied. |
| `applicable_from_day` | INTEGER | Nullable. Day range start for fine applicability. |
| `applicable_to_day` | INTEGER | Nullable. Day range end for fine applicability. |
| `action_on_expiry` | VARCHAR(100) | Nullable. Action when max fine reached (name removal, report, etc.). |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**fee_fine_transactions**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | BIGINT UNSIGNED FK → `std_students` | Required. |
| `invoice_id` | BIGINT UNSIGNED FK → `fee_invoices` | Required. |
| `fine_rule_id` | BIGINT UNSIGNED FK → `fee_fine_rules` | Required. |
| `fine_date` | DATE | Required. Date fine was applied. |
| `days_late` | INTEGER | Number of days past due date. |
| `fine_amount` | DECIMAL(10,2) | Computed fine amount. |
| `waived` | BOOLEAN | Default false. Whether fine was waived. |
| `waived_amount` | DECIMAL(10,2) | Default 0.00. Amount waived. |
| `waived_by` | BIGINT UNSIGNED FK → `sys_users` | Nullable. Who waived. |
| `waiver_reason` | VARCHAR(255) | Nullable. Why it was waived. |
| `waived_at` | DATETIME | Nullable. When it was waived. |

## Business Rules

**Fine Calculation Modes**
- `PerDay`: `fine = base_amount × (fine_value / 100) × days_late`. Compound — each day adds fine × days_late.
- `FlatPerTier`: `fine = fixed_amount` (one-time flat fine regardless of days late). Only applied once.

**Recurring Logic**
- If `recurring = false`: fine is applied once per overdue period
- If `recurring = true`: fine is reapplied every `recurring_interval_days` days
- Each reapplication creates a new `FeeFineTransaction` record
- Max reapplications controlled by `max_fine_installments`

**Grace Period**
- Fine calculation starts after `due_date + grace_period_days`
- `days_late` counts from the day after grace period ends
- Example: due_date = 10th, grace = 5 days → fine starts from 16th

**Max Fine Amount**
- If `max_fine_amount` is set, cumulative fine for the invoice cannot exceed this value
- Once max is reached, `action_on_expiry` is triggered (name removal, escalation)

**Duplicate Prevention**
- `ApplyFines` command checks for existing fine transactions before creating new ones
- Prevents duplicate fine for same `invoice_id + fine_rule_id + fine_date`
- For recurring: checks if fine was already applied for the current interval

**Waiver Rules**
- Fine can be fully or partially waived
- `waived_amount` cannot exceed `fine_amount`
- Once waived, the effective fine = `fine_amount - waived_amount`
- Waived fines cannot be edited

**ApplyFines Command**
- Signature: `fee:apply-fines {--dry-run} {--rule=}`
- Scheduled command runs daily (or as configured)
- Loads all active fine rules
- For each overdue invoice (Published/Partially Paid/Overdue past due_date):
  - Checks rule applicability (days_late within applicable_from_day → applicable_to_day)
  - Checks for existing fine (avoid duplicates)
  - Calculates fine via `FeeFineRule::calculateFine(days_late)`
  - Creates `FeeFineTransaction`
  - Updates invoice `fine_amount` + marks as `Overdue`
- `--dry-run` mode: preview without saving

## CRUD Operations

**List Fine Rules**
- Shows: rule name, type, value, calculation mode, grace period, recurring, active status

**Create Fine Rule**
- Conditional validation: Percent + cap requires max_fine_amount; recurring requires interval
- Fine type toggle changes form fields

**List Fine Transactions**
- Filterable by: student, invoice, waived status, date range
- Shows: student name, invoice no, rule, days late, fine amount, waived amount, effective amount

**Waive Fine**
- Full or partial waiver
- Validates waived_amount ≤ fine_amount
- Tracks waived_by, waiver_reason, waived_at

## Permissions

| Operation | Permission Key |
|---|---|
| View fine rules | `tenant.fee-fine-rule.viewAny` |
| Manage fine rules | `tenant.fee-fine-rule.*` |
| View fine transactions | `tenant.fee-fine-transaction.viewAny` |
| Manage fine transactions | `tenant.fee-fine-transaction.*` |
