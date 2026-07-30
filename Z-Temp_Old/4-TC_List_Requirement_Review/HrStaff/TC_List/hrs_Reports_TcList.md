# hrs_Reports_TcList

## Module: HrStaff → Reports → Reports (Tab Group)

## 1. Feature Information

| Item | Details |
|------|---------|
| Module / Tab Group / Feature | HrStaff / Reports / Salary Register, Bank Summary, CTC Analysis, Payroll Trend |
| URL(s) | `GET /reports/salary-register` (`hr-staff.reports.salary-register`), `GET /reports/bank-summary` (`hr-staff.reports.bank-summary`), `GET /reports/ctc-analysis` (`hr-staff.reports.ctc-analysis`), `GET /reports/payroll-trend` (`hr-staff.reports.payroll-trend`) |
| Controller | `Modules\HrStaff\Http\Controllers\PayrollReportController::salaryRegister()` lines 20–36, `bankSummary()` lines 41–58, `ctcAnalysis()` lines 63–83, `trend()` lines 88–106 |
| Model(s) | `Modules\HrStaff\Models\PayrollRun` (table: `pay_payroll_runs`), `Modules\HrStaff\Models\PayrollRunDetail` (table: `pay_payroll_run_details`) |
| Validation | None (read-only, no form requests) |
| Policy | None — direct `Gate::authorize('pay.report.view')` in controller |
| Permissions | `pay.report.view` |
| Pagination | None (all data loaded at once for filtered month) |
| Soft Deletes | Models use `SoftDeletes` but reports only query active records |
| Read-Only | Yes — no create/update/delete UI elements |

## 2. Pre-conditions

- User must be logged in with `pay.report.view` permission
- At least one payroll run must exist with `status = locked` to populate month filter
- For Salary Register/Bank Summary/CTC Analysis: payroll run must exist for the selected month
- For Payroll Trend: payroll runs with status approved or locked must exist
- Dusk env: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

## 3. Default Data Load

`PayrollReportController` methods each gate with `pay.report.view` and load their respective data sets. The reports menu page (`HrMenuController::reports()`) loads locked payroll months for the filter dropdown.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Month filter | `HrMenuController::reports()` | `PayrollRun::where('status', 'locked')->pluck('payroll_month')->unique()` | status=locked | None |
| Salary Register | `salaryRegister()` | `PayrollRun::where('payroll_month', $month)->where('run_type', 'regular')->active()->first()` then `details()->with([employee, salaryAssignment.salaryStructure])` | month, run_type=regular, is_active | None |
| Bank Summary | `bankSummary()` | DB join: `pay_payroll_run_details` + `pay_payroll_runs` + `hrs_employment_details`, group by bank_name | month, run_type=regular, deleted_at null | None |
| CTC Analysis | `ctcAnalysis()` | `PayrollRunDetail::with([employee, salaryAssignment])->whereHas('payrollRun', fn) ` | month, run_type=regular | None |
| Payroll Trend | `trend()` | `PayrollRun::active()->where('run_type', 'regular')->whereIn('status', ['approved','locked'])->orderBy('payroll_month')` | status=approved or locked, run_type=regular | None |

> **Data Source:** All four reports source data from the Payroll module (`pay_payroll_runs`, `pay_payroll_run_details`) and the HrStaff salary tables (`hrs_salary_assignments`, `hrs_employment_details`). Reports are read-only views of computed payroll data.

## 4. Test Data Strategy

- Create at least 4 payroll runs for different months (e.g., 2025-01 through 2025-04) with status = locked
- Each run should have 3+ employee detail records with varying gross/net/deduction values
- Employment details should include at least 2 different bank names for Bank Summary testing
- For CTC Analysis, ensure salary assignments have known CTC amounts
- For Payroll Trend, have at least 3 months of run data with different totals

## 5. Business Conditions

### 5.1 Database Schema — Relevant Tables

| BC ID | Table | Column | Type (DDL) | Constraints |
|-------|-------|--------|------------|-------------|
| BC-DB-01 | `pay_payroll_runs` | `payroll_month` | VARCHAR(7) | NOT NULL, UNIQUE with run_type |
| BC-DB-02 | `pay_payroll_runs` | `status` | ENUM('draft','computing','computed','reviewing','approved','locked') | NOT NULL, DEFAULT 'draft' |
| BC-DB-03 | `pay_payroll_runs` | `run_type` | ENUM('regular','supplementary') | NOT NULL, DEFAULT 'regular' |
| BC-DB-04 | `pay_payroll_runs` | `total_gross` | DECIMAL(14,2) | NULL |
| BC-DB-05 | `pay_payroll_runs` | `total_net` | DECIMAL(14,2) | NULL |
| BC-DB-06 | `pay_payroll_runs` | `employee_count` | SMALLINT UNSIGNED | NULL |
| BC-DB-07 | `pay_payroll_run_details` | `gross_pay` | DECIMAL(12,2) | NOT NULL, DEFAULT 0 |
| BC-DB-08 | `pay_payroll_run_details` | `net_pay` | DECIMAL(12,2) | NOT NULL, DEFAULT 0 |
| BC-DB-09 | `pay_payroll_run_details` | `total_deductions` | DECIMAL(12,2) | NOT NULL, DEFAULT 0 |
| BC-DB-10 | `hrs_employment_details` | `bank_name` | VARCHAR(100) | NULL |

### 5.2 Authorization

| BC ID | Permission | Behavior |
|-------|------------|----------|
| BC-AUTH-01 | `pay.report.view` | All 4 report tabs accessible |
| BC-AUTH-02 | No `pay.report.view` | Any report URL → 403 |
| BC-AUTH-03 | Guest | Redirect to `/login` |

### 5.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Reports page loads | Month filter dropdown populated with locked payroll months |
| BC-BIZ-02 | Salary Register — month with data | Table shows employee-wise gross, deductions, net pay |
| BC-BIZ-03 | Salary Register — month without data | Empty table, graceful display |
| BC-BIZ-04 | Bank Summary — groups by bank name | Per-bank row: bank_name, employee_count, total_amount |
| BC-BIZ-05 | Bank Summary — correct totals | total_amount = SUM(net_pay) for that bank's employees |
| BC-BIZ-06 | CTC Analysis — per-employee breakdown | Columns: employee name, emp_code, annual_ctc, monthly_gross, net_pay, deductions |
| BC-BIZ-07 | CTC Analysis — annual_ctc from salary assignment | CTC matches `salaryAssignment.ctc_amount` |
| BC-BIZ-08 | Payroll Trend — shows monthly data | Rows: month, total_gross, total_net, employee_count, status |
| BC-BIZ-09 | Payroll Trend — ascending month order | Data sorted by payroll_month ascending |
| BC-BIZ-10 | Payroll Trend — only approved/locked runs | Draft/computing/computed runs excluded |
| BC-BIZ-11 | Salary Register default month | Defaults to `now()->format('Y-m')` if no month param |
| BC-BIZ-12 | Month filter changes data | Selecting different month reloads corresponding data |

### 5.4 Referential Integrity

Reports are read-only — no FK constraints are exercised. Data integrity is managed by the Payroll module.

## 6. Test Case List

### 6.1 Display & Filter Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load Reports page | Month filter dropdown with locked months; 4 tab links visible | — | — | ⬜ |
| TC-P02 | Salary Register — view with data | Table shows employee name, gross_pay, total_deductions, net_pay per employee | — | — | ⬜ |
| TC-P03 | Salary Register — change month filter | Data reloads for selected month | — | — | ⬜ |
| TC-P04 | Salary Register — month with no run | Empty table with no data message | — | — | ⬜ |
| TC-P05 | Bank Summary — view grouped data | Rows per bank: bank_name, employee_count, total_amount | — | — | ⬜ |
| TC-P06 | Bank Summary — change month | Data reloads for selected month | — | — | ⬜ |
| TC-P07 | CTC Analysis — view per-employee | Each row: employee, emp_code, annual_ctc, monthly_gross, net_pay, deductions | — | — | ⬜ |
| TC-P08 | CTC Analysis — change month | Data reloads for selected month | — | — | ⬜ |
| TC-P09 | CTC Analysis — CTC matches salary assignment | annual_ctc column matches `salaryAssignment.ctc_amount` | — | — | ⬜ |
| TC-P10 | Payroll Trend — month-over-month table | Rows: month, total_gross, total_net, employee_count, status; ascending by month | — | — | ⬜ |
| TC-P11 | Payroll Trend — only approved/locked runs | Draft runs not included | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Access reports without `pay.report.view` | 403 Forbidden | — | — | ⬜ |
| TC-N02 | Guest access to reports | Redirect to /login | — | — | ⬜ |
| TC-N03 | Salary Register with invalid month | Empty result (graceful) | — | — | ⬜ |
| TC-N04 | No locked payroll runs exist | Month filter dropdown empty | — | — | ⬜ |
| TC-N05 | Direct URL with non-existent report type | 404 Not Found | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Reports read from locked payroll runs | Only runs with status=locked appear in filter | — | — | ⬜ |
| TC-D02 | A | Bank Summary joins 3 tables | Query joins `pay_payroll_run_details`, `pay_payroll_runs`, `hrs_employment_details` | — | — | ⬜ |
| TC-D03 | A | Payroll Trend excludes non-regular runs | Supplementary runs excluded | — | — | ⬜ |
| TC-D04 | B | Controller gate on all 4 methods | Each method calls `Gate::authorize('pay.report.view')` | — | — | ⬜ |
| TC-D05 | C | No create/update/delete endpoints exist | Only GET routes for reports | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — `Gate::authorize()` on every method | All 4 report methods call `Gate::authorize('pay.report.view')` | — | — | ◌ |
| TC-CR02 | CR | P1 | Route — 4 GET routes registered correctly | All under `/reports` prefix with correct names | — | — | ◌ |
| TC-CR03 | CR | P1 | View — Blade `@can` directives for tabs | Reports tab visibility guarded by `pay.report.view` | — | — | ◌ |
| TC-CR04 | CR | P1 | View — null-safe checks for relationship variables | `isset($run)`, `$details->isNotEmpty()` checks before rendering tables | — | — | ◌ |
| TC-CR05 | CR | P1 | Breadcrumb — route registered | Report routes in `config/breadcrumb.php` | — | — | ◌ |

## 7. Detailed Test Steps

#### TC-CR01 through TC-CR05: Code Review
| TC ID | Action | Expected Result |
|-------|--------|-----------------|
| TC-CR01 | Open `PayrollReportController.php` | Verify `Gate::authorize('pay.report.view')` on all 4 methods: salaryRegister(), bankSummary(), ctcAnalysis(), trend() |
| TC-CR02 | Open `routes/web.php` | Verify 4 GET routes under `/reports` prefix with correct names: reports.salary-register, reports.bank-summary, reports.ctc-analysis, reports.payroll-trend |
| TC-CR03 | Open `resources/views/pages/reports.blade.php` | Verify `@can('pay.report.view')` guards tab visibility |
| TC-CR04 | Open report views | Verify `isset($run)` / `$details->isNotEmpty()` null-safe checks before rendering tables |
| TC-CR05 | Check `config/breadcrumb.php` | Verify report routes (reports.salary-register, reports.bank-summary, etc.) registered with correct hierarchy |

### 7.1 Display & Filter TC Steps

#### TC-P01: Load Reports page
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user with `pay.report.view` | — |
| 2 | Navigate to HR Reports | Page loads with month filter dropdown showing locked payroll months; 4 tab links visible (Salary Register, Bank Summary, CTC Analysis, Payroll Trend) |

#### TC-P02: Salary Register with data
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure locked payroll run exists for 2025-03 | — |
| 2 | Navigate to Salary Register tab or `GET /reports/salary-register?month=2025-03` | Table displays: Employee Name, Gross Pay, Total Deductions, Net Pay per employee |
| 3 | Verify net_pay = gross_pay - total_deductions for a row | — |

#### TC-P03, TC-P04, TC-P06, TC-P08, TC-P09, TC-P11: Additional display scenarios (compact table)

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-P03 | On Salary Register, change month filter to a different locked month | Submit filter | Data reloads for selected month |
| TC-P04 | Select a month with no payroll run (e.g., far future) | Submit filter | Empty table, no errors |
| TC-P06 | On Bank Summary, change month filter | Submit filter | Data reloads for selected month |
| TC-P08 | On CTC Analysis, change month filter | Submit filter | Data reloads for selected month |
| TC-P09 | On CTC Analysis, verify annual_ctc column | Compare against `salaryAssignment.ctc_amount` | Values match |
| TC-P11 | Create a draft payroll run, ensure it does not appear | Load Payroll Trend | Draft run excluded; only approved/locked runs shown |

#### TC-P05: Bank Summary
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Bank Summary tab for 2025-03 | Rows grouped by bank: e.g., "SBI — 5 employees, ₹2,50,000.00", "HDFC — 3 employees, ₹1,80,000.00" |

#### TC-P07: CTC Analysis
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to CTC Analysis tab for 2025-03 | Each row: Employee Name, Emp Code, Annual CTC, Monthly Gross, Net Pay, Deductions |

#### TC-P10: Payroll Trend
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Payroll Trend tab | Table with rows: Month (2025-01, 2025-02, 2025-03...), Total Gross, Total Net, Employee Count, Status |
| 2 | Verify ascending month order | 2025-01 before 2025-02 before 2025-03 |

### 7.2 Negative TC Steps

#### TC-N01: Access without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `pay.report.view` | — |
| 2 | Navigate to any report URL | 403 Forbidden |

#### TC-N02: Guest access
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out | — |
| 2 | Navigate to `GET /reports/salary-register` | Redirect to `/login` |

#### TC-N03, TC-N05: Additional error scenarios (compact table)

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-N03 | Navigate to Salary Register with `?month=invalid` | — | Empty result (graceful) |
| TC-N05 | Navigate to `GET /reports/non-existent` | — | 404 Not Found |

#### TC-N04: No locked runs exist
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no locked payroll runs exist | — |
| 2 | Load Reports page | Month filter dropdown is empty |

### 7.3 Dependency TC Steps

#### TC-D01 through TC-D05: Data source and authorization dependency checks (compact table)

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-D01 | Change a payroll run's status from locked to draft | Load Reports | Month no longer appears in filter dropdown |
| TC-D02 | Open `PayrollReportController.php` | Check `bankSummary()` DB query | Join across `pay_payroll_run_details`, `pay_payroll_runs`, `hrs_employment_details` |
| TC-D03 | Create a supplementary payroll run | Load Payroll Trend | Supplementary run excluded |
| TC-D04 | Open `PayrollReportController.php` | Check all 4 methods | Each calls `Gate::authorize('pay.report.view')` |
| TC-D05 | Check routes/web.php | Verify only GET routes exist | No POST/PUT/DELETE report routes |
