# Payroll Runs — Business Requirements

## What This Screen Does

Payroll Runs is the core payroll engine that processes monthly salary computation for all active school employees. It orchestrates the end-to-end payroll lifecycle — creating a run for a given month, computing gross-to-net amounts per employee, reviewing details with override capability, submitting for approval, approving, locking for immutability, and finally marking payments as disbursed.

The screen also supports supplementary runs to add employees who were missed in the regular monthly run, and exports bank transfer files in CSV format for NEFT/RTGS processing.

## When This Screen Is Used

- **Monthly payroll processing** when the Payroll Manager initiates a new payroll run for a specific month
- **Salary computation** when the system needs to calculate earnings, deductions, and net pay for all active employees based on their salary assignments, LOP records, compliance data, and TDS projections
- **Payroll review** when the Payroll Manager reviews computed amounts and applies manual overrides to specific fields with a mandatory reason
- **Payroll approval** when the Principal or authorised approver reviews and approves the computed payroll
- **Payroll locking** when the Payroll Manager locks the approved run to prevent any further modifications
- **Bank file export** when the accounts team downloads a CSV bank transfer file for disbursement
- **Payment marking** when the finance team confirms that disbursements have been processed
- **Supplementary correction** when employees who were missed in the regular run need to be added via a supplementary run linked to the original

## Default Data Load

The `PayrollController@index` method loads the payroll runs listing page under the Payroll tab group, reached via route `hr-staff.menu.payroll` with tab parameter `payroll-runs`. It queries `PayrollRun::active()->orderByDesc('payroll_month')->paginate(20)` — 20 runs per page. The list displays each run's month, status badge (coloured per FSM state), total gross, total net, employee count, and action buttons gated by permissions.

## Key Fields at a Glance

**Identity and Tracking**
- `payroll_month` — the month the run covers, in `YYYY-MM` format (e.g. `2025-12`)
- `run_type` — either `regular` (normal monthly) or `supplementary` (catch-up for missed employees)
- `parent_run_id` — links a supplementary run to its parent regular run; `null` for regular runs

**Automation Triggers**
- `status` — the FSM state: `draft` → `computing` → `computed` → `reviewing` → `approved` → `locked`
- `initiated_by` — the employee (Payroll Manager) who created the run
- `approved_by` and `approved_at` — who approved the run and when
- `locked_at` — when the run was locked, after which no changes are permitted

**Aggregate Values**
- `total_gross` — sum of all employee gross pays for this run, computed during the computation step
- `total_net` — sum of all employee net pays
- `employee_count` — number of employees included
- `computation_notes` — any errors or warnings generated during the computation process

## Business Rules and Conditions

**FSM State Transition Guarding** — Each status transition is guarded by the `PayrollRunService`: only `draft` runs can be computed; only `computed` runs can be submitted for review; only `reviewing` runs can be approved; only `approved` runs can be locked. Any invalid transition throws a `DomainException` with a descriptive message.

**Active Salary Assignment Prerequisite (BR-PAY-002)** — Computation will fail if any active employee lacks an active salary assignment (one where `effective_to_date` is null and `is_active` is true). The system throws a `DomainException` listing the unassigned employee IDs before any computation begins.

**Locked Run Immutability (BR-PAY-003)** — Once a run reaches `locked` status, it is immutable. Override attempts, recomputation, and status transitions are blocked with an HTTP 422 response: "Locked payroll cannot be modified (BR-PAY-003)."

**Override Audit Trail (BR-PAY-005)** — Every manual override of a computed field is recorded in `pay_payroll_overrides` with the original value, new value, field name, reason (minimum 10 characters), and the employee ID of the overrider.

**Bank File Export Guard** — Bank files can only be generated for locked runs. The export includes employees with `net_pay > 0` and `payment_status = 'pending'`. After export, those details' payment status is updated to `exported`.

**Supplementary Run Linking** — Supplementary runs reference their parent regular run via `parent_run_id`. The `run_type` field distinguishes them, and only `regular` runs appear as potential parents.

## Workflow Steps

**Creating a Payroll Run** — The Payroll Manager navigates to Payroll Runs, clicks "Create Run," fills in the Payroll Month (e.g. `2025-12`), Academic Year, and Run Type (`regular` or `supplementary`). If `supplementary`, they must also select a parent run. The system creates the run in `draft` status.

**Computing Payroll** — From the run detail page, the Payroll Manager clicks "Compute." The system transitions status to `computing`, then iterates over all active employees. For each employee with an active salary assignment, it calculates LOP deductions from confirmed LOP records, computes PF (12% capped at ₹15,000 Basic+DA), ESI (0.75% employee, 3.25% employer if gross ≤ ₹21,000), PT from state-wise slabs, TDS via the TDS computation engine, and derives net pay. On completion, status becomes `computed` with aggregates stored.

**Reviewing and Overriding** — The Payroll Manager views computed details sorted by employee. They can override specific fields (`net_pay`, `tds_deducted`, `pf_employee`, `esi_employee`, `pt_deduction`, `other_deductions`) by providing a new value and a reason (minimum 10 characters). Overriding any field except `net_pay` triggers recalculation of `total_deductions` and `net_pay`. Each override is logged in the overrides audit trail.

**Submitting for Approval** — Once satisfied, the Payroll Manager submits the run. Status transitions from `computed` to `reviewing`. The run is now awaiting approval.

**Approving** — The Principal or authorised approver reviews the run and clicks "Approve." Status transitions from `reviewing` to `approved`, recording who approved and the timestamp. The `PayrollApproved` event fires.

**Locking** — The Payroll Manager locks the approved run. Status transitions to `locked` with a timestamp. The `PayrollLocked` event fires. No further modifications are allowed.

**Exporting Bank File** — From the locked run, the Payroll Manager clicks "Bank File Export" to download a CSV containing employee code, name, bank account, IFSC, net pay, and payment mode (NEFT) for all pending payments.

**Marking as Paid** — After disbursement, the Payroll Manager clicks "Mark Paid." All detail records with `payment_status = 'pending'` get updated to `paid`.

## Example Scenario

Green Valley School processes January 2026 payroll. Payroll Manager Anita creates a regular run for `2026-01` under the `2025-26` academic session. She clicks Compute — the system processes 85 active employees. Two employees fail: one has no salary assignment, another has an invalid TDS compliance record. The run completes with `employee_count = 83` and `computation_notes` listing the two errors. Anita reviews details, overrides `tds_deducted` for a new joiner whose TDS was under-calculated, recording the reason "Manual correction for partial month joining." She submits the run to Principal Sharma, who reviews and approves it. Anita locks the run, downloads the bank CSV, and uploads it to the bank portal. After successful disbursement, she clicks "Mark Paid" to close the run.

## Related Screens

- **Salary Assignment** — provides the active salary assignment (structure, CTC, gross) used for each employee's computation
- **Payslips** — generated employee-wise payslip PDFs from the locked run's detail records
- **Form 16** — annual TDS certificate generated from cumulative payroll data across all runs in a financial year
- **Statutory Exports (PF ECR / ESI Challan)** — compliance registers generated per payroll run for EPFO and ESIC filing
- **Compliance Records** — configures per-employee PF/ESI/TDS applicability and reference numbers used during computation
- **LOP Reconciliation** — confirmed LOP records feed into the LWP deduction calculation
- **TDS Ledger** — cumulative YTD TDS data per employee per month, read and written during payroll computation

## Requirements

- `PayrollController@index` — renders the payroll runs list; gates on `pay.run.initiate`
- `PayrollController@store(StorePayrollRunRequest)` — creates a new draft run via `PayrollRunService::create()`; gates on `pay.run.initiate`; logs activity "Payroll run created."
- `PayrollController@show(PayrollRun)` — shows a single run with details, employee, and initiator/approver info; eager-loads `details.employee`, `initiatedByEmployee`, `approvedByEmployee`; gates on `pay.run.initiate`
- `PayrollController@compute(PayrollRun)` — triggers `PayrollRunService::compute()` which delegates to `PayrollComputationService::computeRun()`; gates on `pay.run.compute`; guards editable status via `guardEditable()` (blocks locked/approved runs)
- `PayrollController@details(PayrollRun)` — paginated details view (50 per page) with employee, salary assignment, and structure; gates on `pay.run.compute`
- `PayrollController@override(OverridePayrollDetailRequest, PayrollRun, PayrollRunDetail)` — applies field-level override with audit trail; gates on `pay.run.compute`; blocks locked runs with 422; recalculates derived fields unless overriding `net_pay` directly
- `PayrollController@submit(PayrollRun)` — transitions `computed` to `reviewing` via `PayrollRunService::submit()`; gates on `pay.run.compute`; throws `DomainException` on invalid status
- `PayrollController@approve(PayrollRun)` — transitions `reviewing` to `approved` via `PayrollRunService::approve()`; gates on `pay.run.approve`; fires `PayrollApproved` event
- `PayrollController@lock(PayrollRun)` — transitions `approved` to `locked` via `PayrollRunService::lock()`; gates on `pay.run.lock`; fires `PayrollLocked` event
- `PayrollController@bankFile(PayrollRun)` — streams CSV via `BankExportService::generateBankFile()`; gates on `pay.bank_file.export`; guards on `isLocked()`; updates payment_status to `exported`
- `PayrollController@markPaid(PayrollRun)` — updates all pending details to `paid` via `PayrollRunService::markPaid()`; gates on `pay.bank_file.export`; only allowed on locked runs
- `StorePayrollRunRequest` — validates `payroll_month` (required, `YYYY-MM` regex), `academic_year_id` (required, exists on `sch_org_academic_sessions_jnt`), `run_type` (required, in `regular,supplementary`), `parent_run_id` (nullable, required_if `supplementary`, exists on `pay_payroll_runs`)
- `OverridePayrollDetailRequest` — validates `field_name` (required, in allowed list), `override_value` (required, numeric, min:0), `reason` (required, string, min:10, max:500)
- `PayrollRunPolicy` — defines `viewAny`/`view` (pay.run.initiate or pay.run.approve), `create` (pay.run.initiate), `compute` (pay.run.compute), `approve` (pay.run.approve), `lock` (pay.run.lock), `delete` (pay.run.initiate + draft status), `forceDelete` (returns false)
- `PayrollRunService::create()` — sets status to `draft`, records `created_by`, `updated_by`, `initiated_by` from authenticated user's employee ID
- `PayrollRunService::guardEditable()` — aborts with 422 if locked or approved
- `PayrollComputationService::computeRun()` — wraps entire computation in a DB transaction; updates status to `computing`, then to `computed` with aggregates and optional computation notes
- `PayrollComputationService::computeEmployee()` — resolves active salary assignment, calculates LOP, PF, ESI, PT, TDS; uses `TdsComputationService` for TDS and ledger recording; uses `updateOrCreate` on `PayrollRunDetail` so recomputation is idempotent
- All write methods log activity via the `activityLog()` helper
- Model uses `SoftDeletes`, `$casts` for decimal/timestamp fields

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `pay.run.initiate` | `index`, `store`, `show` | View runs and create new runs |
| `pay.run.compute` | `compute`, `details`, `override`, `submit` | Compute, review details, apply overrides, submit for approval |
| `pay.run.approve` | `approve` | Approve runs in reviewing status |
| `pay.run.lock` | `lock` | Lock approved runs |
| `pay.bank_file.export` | `bankFile`, `markPaid` | Export bank CSV and mark payments as paid |
| Policy | `PayrollRunPolicy` | Applied via `Gate::authorize()` calls in each controller method |

## Logic Flow

**Page Load (index)** — User with `pay.run.initiate` accesses the payroll runs list. `PayrollRun::active()` filters to soft-delete-free records, ordered by `payroll_month` descending, paginated at 20 per page. The view renders a table with status badges and permission-gated action buttons.

**Create Run** — User fills the `StorePayrollRunRequest` form. Validation checks month format, academic year existence, run type enum, and parent run existence for supplementary runs. `PayrollRunService::create()` sets the initial status to `draft` and records the initiating employee. Activity is logged and the user is redirected to the run's show page with a success message.

**Compute Run** — User clicks "Compute." `guardEditable()` ensures the run is not locked or approved. `PayrollComputationService::computeRun()` runs in a transaction: status becomes `computing`, then iterates all active employees. For each employee with an active salary assignment (BR-PAY-002), it computes LOP from confirmed `hrs_lop_records`, calculates working days via `HolidayService`, derives statutory contributions (PF at 12% of capped basic, ESI at 0.75%/3.25% if applicable, PT from slab, TDS from projection), and stores the detail with a `computation_json` breakdown. Errors for individual employees are captured in `computation_notes`. On completion, aggregates are saved and status becomes `computed`.

**Override Detail** — From the details view, user selects a field to override. `OverridePayrollDetailRequest` validates field name against an allowlist. The override is recorded in `PayrollOverride` with original value, new value, and reason. If the field is not `net_pay`, derived fields (`total_deductions`, `net_pay`) are recalculated. The detail's `is_override` flag is set to `true`.

**Submit/Approve/Lock** — Each is a single-status transition guarded by `PayrollRunService`. Invalid transitions throw `DomainException` caught by the controller, which redirects back with a flash error.

**Bank File Export** — `BankExportService::generateBankFile()` guards on `isLocked()`, queries pending details with `net_pay > 0`, fetches bank details from `EmploymentDetail`, generates a CSV, and updates payment status to `exported`.

**Mark Paid** — Updates all details' `payment_status` to `paid` for a locked run via `PayrollRunService::markPaid()`.

## Validate Before Save

**StorePayrollRunRequest:**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `payroll_month` | required, string, regex:/^\d{4}-\d{2}$/ | The Payroll Month must be in YYYY-MM format. |
| `academic_year_id` | required, exists:sch_org_academic_sessions_jnt,id | The Academic Year field is required. |
| `run_type` | required, in:regular,supplementary | The Run Type field is required. |
| `parent_run_id` | nullable, required_if:run_type,supplementary, exists:pay_payroll_runs,id | The Parent Run field is required when Run Type is supplementary. |

**OverridePayrollDetailRequest:**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `field_name` | required, string, in:net_pay,tds_deducted,pf_employee,esi_employee,pt_deduction,other_deductions | The selected Field is invalid. |
| `override_value` | required, numeric, min:0 | Override Value must be a number and at least 0. |
| `reason` | required, string, min:10, max:500 | Override Reason must be at least 10 characters. |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Cannot compute locked run | "Locked payroll cannot be modified (BR-PAY-003)." | Controller check (422) |
| Cannot compute approved run | "Approved payroll cannot be recomputed." | Controller check (422) |
| Cannot submit with invalid status | "Cannot submit payroll with status: {status}" | DomainException |
| Cannot approve with invalid status | "Cannot approve payroll with status: {status}" | DomainException |
| Cannot lock with invalid status | "Cannot lock payroll with status: {status}" | DomainException |
| Cannot mark paid on unlocked run | "Only locked payroll runs can be marked as paid." | DomainException |
| Cannot generate bank file on unlocked run | "Bank file can only be generated for locked payroll runs." | DomainException |
| Employees with no active salary assignment | "Cannot compute payroll: the following active employees have no active salary assignment: {ids}" | DomainException (pre-flight) |
| Locked payroll override attempt | "Locked payroll cannot be modified." | Controller check (422) |
| Supplementary run missing parent | "The Parent Run field is required when Run Type is supplementary." | Validation error |

## Success Scenarios

**SC-001 — Payroll Run Created** — Anita creates a regular payroll run for `2026-01`. The system saves the run with status `draft`, logs "Payroll run created." with the month, and redirects to the run show page with success flash "Payroll run created."

**SC-002 — Payroll Computed Successfully** — After clicking Compute for a draft run with 83 employees, the system processes all employees. Status becomes `computed`, aggregates (`total_gross`: ₹24,50,000, `total_net`: ₹18,20,000, `employee_count`: 83) are stored. The user sees "Payroll computed for 83 employees."

**SC-003 — Field Override Applied** — Anita overrides `tds_deducted` from ₹2,500 to ₹3,000 for employee #42 with reason "Manual correction for partial month joining." An override record is created, derived fields are recalculated, and she sees "Override applied to tds_deducted."

**SC-004 — Payroll Approved** — Principal Sharma approves the run. Status becomes `approved`, `approved_by` and `approved_at` are recorded. Flash: "Payroll approved."

**SC-005 — Payroll Locked** — Anita locks the approved run. Status becomes `locked`, `locked_at` recorded. Flash: "Payroll locked."

**SC-006 — Bank File Exported** — Anita clicks "Bank File Export" on a locked run. A CSV file `bank-transfer-2026-01.csv` is downloaded with employee codes, names, bank details, and net pay. Details' payment_status updates to `exported`.

## Failure Scenarios

**FC-001 — Computation Blocked Due to Missing Salary Assignments** — A draft run has 85 active employees, but 2 have no active salary assignment. The system aborts with DomainException listing both employee IDs. No computation occurs.

**FC-002 — Submit on Draft Run Fails** — User clicks Submit on a run still in `draft` status. The system responds with "Cannot submit payroll with status: draft."

**FC-003 — Lock on Non-Approved Run Fails** — User tries to lock a `computed` run. The system responds with "Cannot lock payroll with status: computed."

**FC-004 — Override on Locked Run Fails** — User attempts to override a field on a locked run. HTTP 422: "Locked payroll cannot be modified."

**FC-005 — Bank File on Non-Locked Run Fails** — User attempts bank export on an approved (not locked) run. DomainException: "Bank file can only be generated for locked payroll runs."

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `sch_org_academic_sessions_jnt` | FK parent | `pay_payroll_runs.academic_year_id` → `sch_org_academic_sessions_jnt.id` (RESTRICT) |
| `sch_employees` | FK parent | `initiated_by`, `approved_by` → `sch_employees.id` (RESTRICT); also `pay_payroll_run_details.employee_id` |
| `pay_payroll_runs` (self) | FK parent | `parent_run_id` → `pay_payroll_runs.id` for supplementary runs (RESTRICT) |
| `hrs_salary_assignments` | FK parent | `pay_payroll_run_details.salary_assignment_id` → `hrs_salary_assignments.id` (RESTRICT) |
| `pay_payroll_run_details` | Child | Children: `pay_payroll_overrides.run_detail_id` (CASCADE), `pay_payslips.run_detail_id` (RESTRICT) |
| `PayrollComputationService` | Service | Used for salary computation logic |
| `PayrollRunService` | Service | Orchestrates the FSM lifecycle |
| `BankExportService` | Service | Generates bank transfer CSV |
| `HolidayService` | Service | Calculates working days per month |
| `TdsComputationService` | Service | Computes monthly TDS and records ledger entries |
| `SalaryStructureService` | Service | Resolves PF base from structure components |
| Activity Log | Helper | Logged on create, compute, override, submit, approve, lock, bank export, mark paid |

**Table: `pay_payroll_runs`**

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED | PK, Auto-increment |
| payroll_month | VARCHAR(7) | NOT NULL, YYYY-MM format |
| academic_year_id | SMALLINT UNSIGNED | NOT NULL, FK → sch_org_academic_sessions_jnt.id |
| run_type | ENUM('regular','supplementary') | NOT NULL, DEFAULT 'regular' |
| parent_run_id | BIGINT UNSIGNED | NULL, FK → pay_payroll_runs.id (self) |
| status | ENUM('draft','computing','computed','reviewing','approved','locked') | NOT NULL, DEFAULT 'draft' |
| initiated_by | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| approved_by | INT UNSIGNED | NULL, FK → sch_employees.id |
| approved_at | TIMESTAMP | NULL |
| locked_at | TIMESTAMP | NULL |
| total_gross | DECIMAL(14,2) | NULL |
| total_net | DECIMAL(14,2) | NULL |
| employee_count | SMALLINT UNSIGNED | NULL |
| computation_notes | TEXT | NULL |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |
| UNIQUE KEY | `uq_pay_run_month_type` | (`payroll_month`, `run_type`) |

**Table: `pay_payroll_run_details`**

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED | PK, Auto-increment |
| payroll_run_id | BIGINT UNSIGNED | NOT NULL, FK → pay_payroll_runs.id |
| employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| salary_assignment_id | BIGINT UNSIGNED | NOT NULL, FK → hrs_salary_assignments.id |
| lop_days | DECIMAL(4,1) | NOT NULL, DEFAULT 0 |
| gross_pay | DECIMAL(12,2) | NOT NULL, DEFAULT 0 |
| lwp_deduction | DECIMAL(12,2) | NOT NULL, DEFAULT 0 |
| pf_employee | DECIMAL(10,2) | NOT NULL, DEFAULT 0 |
| pf_employer | DECIMAL(10,2) | NOT NULL, DEFAULT 0 |
| esi_employee | DECIMAL(10,2) | NOT NULL, DEFAULT 0 |
| esi_employer | DECIMAL(10,2) | NOT NULL, DEFAULT 0 |
| tds_deducted | DECIMAL(10,2) | NOT NULL, DEFAULT 0 |
| pt_deduction | DECIMAL(8,2) | NOT NULL, DEFAULT 0 |
| other_deductions | DECIMAL(10,2) | NOT NULL, DEFAULT 0 |
| total_deductions | DECIMAL(12,2) | NOT NULL, DEFAULT 0 |
| net_pay | DECIMAL(12,2) | NOT NULL, DEFAULT 0 |
| computation_json | JSON | NULL |
| payment_status | ENUM('pending','exported','paid','failed') | NOT NULL, DEFAULT 'pending' |
| is_override | TINYINT(1) | NOT NULL, DEFAULT 0 |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |
| UNIQUE KEY | `uq_pay_rundetail` | (`payroll_run_id`, `employee_id`) |

**Table: `pay_payroll_overrides`**

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED | PK, Auto-increment |
| run_detail_id | BIGINT UNSIGNED | NOT NULL, FK → pay_payroll_run_details.id, CASCADE |
| field_name | VARCHAR(50) | NOT NULL |
| original_value | DECIMAL(12,2) | NOT NULL |
| override_value | DECIMAL(12,2) | NOT NULL |
| reason | TEXT | NOT NULL |
| overridden_by | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |
| FK | `fk_pay_ovr_detid` | CASCADE on DELETE |
| FK | `fk_pay_ovr_by` | RESTRICT on DELETE |
