# LOP Reconciliation — Requirements

## What It Does
Tracks Loss of Pay (LOP) days — unexcused absences where salary is deducted. Automatically flags absent employees based on attendance data, allows manual confirmation or waiver of flagged LOP records. Each LOP record is linked to a payroll month for deduction processing.

Features:
- Auto-flagging of absent days as LOP (via integration with attendance system)
- Manual flag, confirm, and waive workflow
- Payroll month association for deduction computation
- Bulk confirm/waive actions
- Soft-delete with restore

## Database Fields

**hrs_lop_records**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `employee_id` | BIGINT UNSIGNED FK → `sch_employees` | Required. CASCADE on delete. |
| `absent_date` | DATE | Required. The date of absence. |
| `flag_status` | ENUM | `flagged`, `confirmed`, `waived`. Default `flagged`. |
| `confirmed_by` | BIGINT UNSIGNED FK → `sch_employees` | Nullable. Who confirmed or waived the LOP. |
| `confirmed_at` | DATETIME | Nullable. When the action was taken. |
| `payroll_month` | VARCHAR(7) | Required. Format: `YYYY-MM`. The payroll month for deduction. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**LOP Flagging Logic**
- Employees without attendance on a working day (non-holiday, non-leave) are flagged
- Sundays and holidays are excluded (working day check against holiday calendar)
- Days with approved leave are excluded

**Flag Status Workflow**
```
flagged → confirmed (salary deducted)
flagged → waived   (no salary impact)
```
- Both confirm and waive are terminal actions
- A confirmed LOP cannot be waived (must be undone via new adjustment)
- A waived LOP cannot be confirmed (must be re-flagged)

**Payroll Month Association**
- `payroll_month` determines which payroll run this LOP is deducted in
- Format: `YYYY-MM` (e.g., `2026-04` for April 2026 payroll)
- Used by payroll computation to calculate `lwp_deduction = LOP days × (gross_pay / working_days)`

**Bulk Actions**
- Multiple LOP records can be confirmed or waived in one action
- `ConfirmLopRequest`: validates `lop_ids` array (min 1, all must exist), `action` (confirmed/waived)
- All selected records updated atomically

## CRUD Operations

**List LOP Records**
- Filterable by: employee, date range, flag_status, payroll_month
- Shows: employee name, absent date, flag status, payroll month, actions
- Bulk action checkboxes for confirm/waive

**Confirm / Waive LOP**
- Accepts array of LOP IDs and an action (confirmed/waived)
- Updates `flag_status`, `confirmed_by` (auth user), `confirmed_at` (now)
- Success redirect with count of processed records

## Permissions

| Operation | Permission Key |
|---|---|
| View LOP records | `hrs.leave.apply` |
| Confirm / Waive LOP | `hrs.employment.manage` |
