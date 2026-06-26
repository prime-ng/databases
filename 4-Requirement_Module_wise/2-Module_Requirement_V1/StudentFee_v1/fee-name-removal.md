# Name Removal & Defaulters — Requirements

## What It Does
Tracks students whose names have been removed from rolls due to prolonged fee default. Records the removal reason, overdue amount, days overdue, and the fine rule that triggered it. Supports re-admission workflow with re-admission fee tracking. Maintains a defaulter history aggregate per student per session with risk scoring.

Features:
- Name removal logging with full audit trail
- Re-admission tracking with fee payment
- Defaulter score computation (risk assessment)
- Defaulter history aggregator (cumulative fine stats)
- High-risk student identification

## Database Fields

**fee_name_removal_logs**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | BIGINT UNSIGNED FK → `std_students` | Required. |
| `academic_session_id` | BIGINT UNSIGNED FK → `glb_academic_sessions` | Required. |
| `removal_date` | DATE | Required. Date of removal. |
| `removal_reason` | VARCHAR(500) | Required. Why the student was removed. |
| `total_due_at_removal` | DECIMAL(12,2) | Required. Total outstanding at time of removal. |
| `days_overdue` | INTEGER | Required. Days past due date. |
| `triggered_by_rule_id` | BIGINT UNSIGNED FK → `fee_fine_rules` | Nullable. Which fine rule's expiry action triggered this. |
| `removed_by` | BIGINT UNSIGNED FK → `sys_users` | Required. Who authorized the removal. |
| `re_admission_date` | DATE | Nullable. If student is re-admitted. |
| `re_admission_fee_paid` | DECIMAL(12,2) | Nullable. Re-admission fee amount. |
| `re_admission_fee_head_id` | BIGINT UNSIGNED FK → `fee_head_masters` | Nullable. Which fee head for re-admission. |
| `re_admission_transaction_id` | BIGINT UNSIGNED FK → `fee_transactions` | Nullable. Payment transaction for re-admission. |
| `re_admitted_by` | BIGINT UNSIGNED FK → `sys_users` | Nullable. Who authorized re-admission. |
| `re_activated_date` | DATE | Nullable. When the student was re-activated. |

**fee_defaulter_histories**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | BIGINT UNSIGNED FK → `std_students` | Required. |
| `academic_session_id` | BIGINT UNSIGNED FK → `glb_academic_sessions` | Required. |
| `total_fine_count` | INTEGER | Total number of fine transactions. |
| `total_fine_amount` | DECIMAL(12,2) | Cumulative fine amount. |
| `total_waived_amount` | DECIMAL(12,2) | Cumulative waived amount. |
| `max_days_late` | INTEGER | Maximum days late for any installment. |
| `avg_days_late` | DECIMAL(5,1) | Average days late per installment. |
| `missed_installments` | INTEGER | Number of installments missed entirely. |
| `name_removed` | BOOLEAN | Whether name was ever removed. |
| `re_admitted` | BOOLEAN | Whether student was re-admitted. |
| `defaulter_score` | DECIMAL(5,2) | Computed risk score. |
| `last_computed_at` | DATETIME | When the score was last computed. |

## Business Rules

**Name Removal Trigger**
- Triggered by fine rule expiry action (when cumulative fine reaches `action_on_expiry`)
- Also triggered manually by admin for chronic defaulters
- On removal: student's active flag is toggled, access to classes/portal revoked
- All details archived in `fee_name_removal_logs`

**Re-admission Flow**
- When a removed student returns: set `re_admission_date`, `re_admission_fee_paid`
- Re-admission fee processed via `FeeTransaction` linked to `re_admission_transaction_id`
- On re-admission: student is re-activated, new `FeeStudentAssignment` may be created

**Defaulter Score Computation**
- Weighted metric: `defaulter_score = f(total_fine, max_days_late, missed_installments, name_removed)`
- Exact formula: weighted combination of:
  - Total fine amount relative to total fee
  - Max days late (log scale)
  - Missed installment ratio
  - Name removal penalty
- `scopeHighRisk()`: filters students with score above threshold
- `isHighRisk()`: helper to check if student exceeds risk threshold

## CRUD Operations

**List Name Removal Logs**
- Search by student name
- Shows: student, removal date, total due, days overdue, removed by, re-admission status

**View Defaulter History**
- Available on student detail or via separate listing
- Shows aggregate statistics per student per session

## Permissions

| Operation | Permission Key |
|---|---|
| View name removal logs | `tenant.student-fee-management.viewAny` |
| Manage name removal | `tenant.fee-student-assignment.delete` |
