# Reports — Business Requirements

## What This Screen Does

The Reports screen provides four read-only payroll reports for management review. All reports aggregate payroll data from locked payroll runs. No create, update, or delete operations are available — the screen is purely for viewing and filtering data.

## When This Screen Is Used

- **Monthly payroll review** when the Principal or HR Manager reviews the salary register before disbursement
- **Bank transfer preparation** when the accounts team needs a bank-wise summary of net pay amounts for fund transfer
- **Compensation analysis** when leadership reviews CTC versus net pay across employee categories
- **Trend monitoring** when tracking payroll cost trends month-over-month

## Default Data Load

The screen loads via `HrMenuController::reports()` (line 236) which queries `PayrollRun::where('status', 'locked')->pluck('payroll_month')->unique()` to populate the month filter dropdown. Each report tab loads its data via its respective controller method in `PayrollReportController`. The four report tabs are: Salary Register, Bank Summary, CTC Analysis, and Payroll Trend. The route prefix is `/reports` under `hr-staff.menu.reports`. Report views are rendered server-side with filter forms that POST/GET to the same route.

## Reports at a Glance

**Salary Register** — Shows a monthly breakdown of all employees' gross pay, deductions, and net pay from a locked payroll run. Filtered by month (defaults to current month). Each row includes employee details, salary structure, and all pay components.

**Bank Summary** — Groups salary disbursement by bank name. Shows per-bank employee count and total net pay amount. Filtered by month. Useful for preparing bank transfer files.

**CTC Analysis** — Compares annual CTC (from salary assignment) versus monthly gross, net pay, and deductions. Filtered by month. Each row shows employee, employee code, annual CTC, monthly gross, net pay, and total deductions.

**Payroll Trend** — Shows month-over-month aggregate payroll data (total gross, total net, employee count, run status) for all locked and approved regular payroll runs. No month filter — the full trend history is displayed.

## Business Rules and Conditions

**Read-Only** — All four report tabs are view-only. No forms submit data to create, update, or delete records. Filter forms only reload the same page with different query parameters.

**Data Source** — All reports query from `pay_payroll_runs` and `pay_payroll_run_details` tables, which are populated by the Payroll Computation Engine when a run is computed.

**Locked Runs Only** — The month filter dropdown shows only months with at least one locked payroll run. The Salary Register and Bank Summary filters use `PayrollRun::where('run_type', 'regular')->active()` to find the relevant run.

**Payroll Trend Scope** — Includes only runs with `status` in `['approved', 'locked']` and `run_type = 'regular'`.

## Workflow Steps

1. The user navigates to HR Reports from the main menu
2. The Reports page loads with the month filter dropdown pre-populated from locked payroll runs
3. The user clicks a report tab (Salary Register, Bank Summary, CTC Analysis, or Payroll Trend)
4. The corresponding controller method loads and displays the data
5. For Salary Register, Bank Summary, and CTC Analysis, the user can change the month filter and reload

## Example Scenario

The Principal wants to review March 2025 salaries. They navigate to HR Reports, select "March 2025" from the month filter, and click the Salary Register tab. The system shows every employee's gross, deductions, and net pay for that month, sourced from the locked March payroll run.

## Related Screens

- **Payroll Runs** — The source data for reports; runs must be computed and locked before data appears in reports

## Requirements

- `HrMenuController::reports()` loads locked payroll run months as filter options; returns `hrstaff::pages.reports` view
- `PayrollReportController::salaryRegister()` (line 20) gates with `pay.report.view`, loads month filter (default: now's Y-m), finds the regular active payroll run for that month, loads details with employee and salary assignment relations; returns `hrstaff::reports.salary_register`
- `PayrollReportController::bankSummary()` (line 41) gates with `pay.report.view`, queries a join of `pay_payroll_run_details`, `pay_payroll_runs`, and `hrs_employment_details` grouped by `bank_name`, selecting `employee_count` and `total_amount`; returns `hrstaff::reports.bank_summary`
- `PayrollReportController::ctcAnalysis()` (line 63) gates with `pay.report.view`, loads details where the payroll run matches the month and run_type = regular, maps each to `employee`, `emp_code`, `annual_ctc`, `monthly_gross`, `net_pay`, `deductions`; returns `hrstaff::reports.ctc_analysis`
- `PayrollReportController::trend()` (line 88) gates with `pay.report.view`, loads all regular runs with status approved or locked, orders by month ascending, maps to `month`, `total_gross`, `total_net`, `employee_count`, `status`; returns `hrstaff::reports.payroll_trend`
- All four methods use `Gate::authorize('pay.report.view')`
- No create/store/update/destroy methods — purely read-only
- Report views are in `Modules/HrStaff/resources/views/reports/`
- Routes: `hr-staff.reports.salary-register` (GET), `hr-staff.reports.bank-summary` (GET), `hr-staff.reports.ctc-analysis` (GET), `hr-staff.reports.payroll-trend` (GET), all under `/reports` prefix

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `pay.report.view` | `salaryRegister()`, `bankSummary()`, `ctcAnalysis()`, `trend()` | All four reports share this permission |

## How This Screen Works — Logic Flow

**Page Load (menu):** `HrMenuController::reports()` queries locked payroll run months, passes `payrollMonths` to the reports Blade view.

**Salary Register:** `PayrollReportController::salaryRegister()` filters by month (default current). Finds a single active regular payroll run. Loads details with employee and salary structure. Returns view with `details`, `month`, `run`.

**Bank Summary:** `PayrollReportController::bankSummary()` filters by month. Runs a raw DB query joining three tables, grouping by `bank_name`. Returns view with `summary` and `month`.

**CTC Analysis:** `PayrollReportController::ctcAnalysis()` filters by month. Loads `PayrollRunDetail` with employee and salary assignment, where the run matches. Maps each record to a plain array with employee details, CTC, gross, net, deductions. Returns view with `analysis` and `month`.

**Payroll Trend:** `PayrollReportController::trend()` queries all approved/locked regular runs. Maps to month-level summary. Returns view with `trend` (ordered ascending by month).

## Validate Before Save

None — the screen is read-only. The month filter is optional and defaults to `now()->format('Y-m')`.

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| No run found for month | Empty grid (no details loaded) | Display (graceful) |
| No locked runs exist | Month dropdown shows nothing | Display (graceful) |

## Success Scenarios

**SC-001 — View Salary Register** — User selects January 2025. System displays all employees with gross pay, deductions, net pay for the January 2025 regular payroll run.

**SC-002 — View Bank Summary** — User selects January 2025. System shows bank-wise aggregates: "State Bank of India: 25 employees, ₹12,50,000", "HDFC Bank: 15 employees, ₹7,30,000".

**SC-003 — View CTC Analysis** — User selects January 2025. System shows per-employee CTC vs net comparison.

**SC-004 — View Payroll Trend** — User opens the Payroll Trend tab. System shows a month-by-month chart/table of gross, net, and employee count from April 2024 through March 2025.

## Failure Scenarios

**FC-001 — No data for month** — User selects a month with no locked payroll run. Salary Register shows an empty table with no details.

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `PayrollRun` | Data source | `pay_payroll_runs` table |
| `PayrollRunDetail` | Data source | `pay_payroll_run_details` table |
| `EmploymentDetail` | Data source | `hrs_employment_details` (for bank name in Bank Summary) |
| `SalaryAssignment` | Data source | `hrs_salary_assignments` (for CTC amount in CTC Analysis) |

No FK dependencies for the reports feature — it only reads existing data. The reports page is accessed via `GET` routes under `hr-staff.reports.*` name prefix.
