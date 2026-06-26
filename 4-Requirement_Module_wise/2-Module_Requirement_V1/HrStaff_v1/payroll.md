# Payroll Engine — Requirements

## What It Does
End-to-end payroll processing engine: run creation, computation, review, approval, lock, bank file export, and payment marking. Supports regular and supplementary runs. Integrates with salary structures, attendance (LOP), compliance (PF/ESI/PT/TDS), and payslip generation. 7-stage state machine with role-based gates at each stage.

Features:
- Regular and supplementary payroll runs
- 7-stage status workflow: draft → computing → computed → reviewing → approved → locked → paid
- Automatic computation of earnings, deductions, employer contributions
- LOP deduction integration (Loss of Pay)
- Per-employee override capability with audit trail
- Bank file export for salary disbursement
- Supplementary runs for corrections/adjustments
- PF ECR and ESI challan generation
- Events fired on approval and lock
- Soft-delete with restore

## Database Fields

**pay_payroll_runs**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `payroll_month` | VARCHAR(7) | Required. Format: `YYYY-MM`. |
| `academic_year_id` | BIGINT UNSIGNED FK → `glb_academic_sessions` | Required. |
| `run_type` | ENUM | `regular`, `supplementary`. |
| `parent_run_id` | BIGINT UNSIGNED FK → self | Nullable. Set when run_type = supplementary. Links to the main run. |
| `status` | ENUM | `draft`, `computing`, `computed`, `reviewing`, `approved`, `locked`, `paid`. |
| `initiated_by` | BIGINT UNSIGNED FK → `sch_employees` | Who created the run. |
| `approved_by` | BIGINT UNSIGNED FK → `sch_employees` | Nullable. Who approved. |
| `approved_at` | DATETIME | Nullable. When approved. |
| `locked_at` | DATETIME | Nullable. When locked. |
| `total_gross` | DECIMAL(14,2) | Sum of all employee gross pays. |
| `total_net` | DECIMAL(14,2) | Sum of all employee net pays. |
| `employee_count` | INTEGER | Number of employees in this run. |
| `computation_notes` | TEXT | Nullable. Notes about computation results. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**pay_payroll_run_details**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `payroll_run_id` | BIGINT UNSIGNED FK → `pay_payroll_runs` | Required. CASCADE on delete. |
| `employee_id` | BIGINT UNSIGNED FK → `sch_employees` | Required. |
| `salary_assignment_id` | BIGINT UNSIGNED FK → `hrs_salary_assignments` | Required. Snapshot of the salary assignment used. |
| `lop_days` | DECIMAL(3,1) | LOP days for this employee in this month. Default 0. |
| `gross_pay` | DECIMAL(10,2) | Gross pay before deductions. |
| `lwp_deduction` | DECIMAL(10,2) | Deduction for loss of pay: `gross_pay × (lop_days / working_days)`. |
| `pf_employee` | DECIMAL(10,2) | Employee PF contribution. |
| `pf_employer` | DECIMAL(10,2) | Employer PF contribution. |
| `esi_employee` | DECIMAL(10,2) | Employee ESI contribution. |
| `esi_employer` | DECIMAL(10,2) | Employer ESI contribution. |
| `tds_deducted` | DECIMAL(10,2) | TDS deducted. |
| `pt_deduction` | DECIMAL(10,2) | Professional Tax deducted. |
| `other_deductions` | DECIMAL(10,2) | Other manual deductions (loan recovery, etc.). |
| `total_deductions` | DECIMAL(10,2) | Sum of all deductions. |
| `net_pay` | DECIMAL(10,2) | `gross_pay - total_deductions`. |
| `computation_json` | JSON | Full breakdown: each component's computed value. Cast to array. |
| `payment_status` | ENUM | `pending`, `exported`, `paid`. Default `pending`. |
| `is_override` | BOOLEAN | Default false. Whether any values were manually overridden. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**pay_payroll_overrides**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `run_detail_id` | BIGINT UNSIGNED FK → `pay_payroll_run_details` | Required. CASCADE on delete. |
| `field_name` | VARCHAR(255) | Which field was overridden. |
| `original_value` | DECIMAL(10,2) | Value before override. |
| `override_value` | DECIMAL(10,2) | Value after override. |
| `reason` | VARCHAR(255) | Required. Why the override was made. Min 10, max 500. |
| `overridden_by` | BIGINT UNSIGNED FK → `sch_employees` | Who made the override. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**State Machine (7 stages)**

```
draft ──→ computing ──→ computed ──→ reviewing ──→ approved ──→ locked ──→ paid
  │           │              │             │              │            │
  └───────────┴──────────────┴─────────────┴──────────────┴────────────┘
                     (can delete only at draft status)
```

1. **draft**: Run created but no computation done. Editable. Deletable.
2. **computing**: Computation in progress (intermediate status).
3. **computed**: Computation complete. Values ready for review. Details viewable.
4. **reviewing**: HR is reviewing computed values. Override allowed.
5. **approved**: Approved by authorized person. Cannot be modified. `PayrollApproved` event fired.
6. **locked**: Final lock. Payslips generated. `PayrollLocked` event fired.
7. **paid**: Salary disbursed. Payment status updated for each employee.

**Computation Process**
- Triggered by `POST /hr-staff/payroll/{run}/compute`
- For each employee with active salary assignment:
  1. Compute gross pay: sum all earning components per structure
  2. Compute LOP deduction: `gross_pay × (lop_days / working_days_in_month)`
  3. Compute PF/ESI contributions based on compliance records
  4. Compute PT based on state slab
  5. Compute TDS based on YTD taxable income and tax slabs
  6. Compute net pay: `gross_pay - lwp_deduction - pf - esi - tds - pt - other_deductions`
  7. Store full computation breakdown in `computation_json`
- Updates run totals: `total_gross`, `total_net`, `employee_count`

**Run Type Behavior**
- `regular`: Standard monthly run for all active employees
- `supplementary`: Additional run for corrections, mid-month joiners, arrears. Must link to a `parent_run_id` that is in `locked` or `paid` status.

**Bank File Export**
- Triggered by `GET /hr-staff/payroll/{run}/bank-file`
- Generates CSV/Excel file with: employee name, bank account, IFSC, net pay, amount in words
- Format configurable for different bank templates
- Used for salary disbursement via bank transfer
- On export: `payment_status` updated to `exported` for all employees

**Mark as Paid**
- Triggered by `POST /hr-staff/payroll/{run}/mark-paid`
- Updates all employee `payment_status` to `paid`
- Idempotent: can be called multiple times without side effects

**Override Rules**
- Only allowed when run is in `reviewing` status
- Overridable fields: `net_pay`, `tds_deducted`, `pf_employee`, `esi_employee`, `pt_deduction`, `other_deductions`
- Each override creates a `PayrollOverride` record with original and new values
- `is_override` flag set to true on the run detail
- Override reason required (min 10, max 500 chars)
- An override recalculates `total_deductions` and `net_pay` automatically

**Supplementary Run Logic**
- Supplementary runs for the same month as the parent
- Only includes employees who need adjustments (not all employees)
- Supplementary `net_pay` is additional to the regular run
- Bank file for supplementary shows only the supplementary amounts

## CRUD Operations

**List Payroll Runs**
- Shows all runs: regular and supplementary
- Columns: month, type, status, employee count, total gross, total net, initiated by
- Color-coded status badges (draft=grey, computing=yellow, computed=blue, reviewing=orange, approved=green, locked=dark, paid=purple)
- Action buttons based on current status

**Create Payroll Run**
- Select month/year, run type
- If supplementary: select parent run
- Created in `draft` status

**Show Payroll Run**
- Summary header: month, status, totals, employee count
- Employee detail table: each employee's gross, deductions, net
- Action buttons based on status

**Compute Payroll**
- Status: `draft` → → `computed`
- Shows computation progress (for large runs)
- On error: specific employee-level error messages

**View Payroll Details**
- Per-employee breakdown: opening gross, LOP deduction, each earning component, each deduction, total deductions, net pay
- Computation JSON shown as expandable row

**Override Payroll Detail**
- Creates override record, updates run detail values
- Only available in `reviewing` status

**Submit for Approval**
- Status: `computed`/`reviewing` → `reviewing`

**Approve Payroll**
- Status: `reviewing` → `approved`
- Sets `approved_by`, `approved_at`
- Fires `PayrollApproved` event

**Lock Payroll**
- Status: `approved` → `locked`
- Sets `locked_at`
- Fires `PayrollLocked` event
- After lock: payslips can be generated

**Export Bank File**
- Downloads CSV/Excel bank transfer file
- Only available in `locked` or `paid` status

**Mark as Paid**
- Status: `locked` → `paid`
- Updates all employee `payment_status` to `paid`

## Permissions

| Operation | Permission Key |
|---|---|
| View payroll runs | `pay.run.initiate` |
| Create payroll run | `pay.run.initiate` |
| Compute payroll | `pay.run.compute` |
| Approve payroll | `pay.run.approve` |
| Lock payroll | `pay.run.lock` |
| Delete draft run | `pay.run.initiate` |
| Download bank file | `pay.run.initiate` |
