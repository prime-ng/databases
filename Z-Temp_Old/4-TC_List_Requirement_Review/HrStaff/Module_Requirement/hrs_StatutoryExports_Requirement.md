# Statutory Exports — Business Requirements

## What This Screen Does

The Statutory Exports feature provides compliance registers for statutory filings. It generates two reports per payroll run: the PF ECR (Electronic Challan-cum-Return) register and the ESI Challan register. These registers display per-employee contribution details needed for filing monthly returns with the Employees' Provident Fund Organisation (EPFO) and the Employees' State Insurance Corporation (ESIC).

The data originates from the payroll computation engine — PF and ESI contributions calculated per employee for each payroll run are stored in dedicated contribution register tables and displayed in structured tabular views ready for download or filing.

## When This Screen Is Used

- **Monthly PF ECR filing** when the compliance team needs to view or export PF contribution data per employee for a completed payroll run, including employee and employer contribution splits (EPF + EPS)
- **Monthly ESI Challan preparation** when the compliance team needs to view or export ESI contribution data per employee, including employee (0.75%) and employer (3.25%) contributions
- **Compliance audit** when reviewing statutory contribution amounts before submitting returns to EPFO/ESIC portals

## Default Data Load

The `StatutoryController@pfEcr` and `StatutoryController@esiChallan` methods load their respective views under the Payroll → Compliance Registers tab group, reached via routes `hr-staff.payroll.pf-ecr` and `hr-staff.payroll.esi-challan`. Each gates on `pay.bank_file.export`. They query the relevant contribution register table filtered by `payroll_run_id` with active records eager-loading the `complianceRecord.employee` relationship, then render the data in a tabular display.

## Key Fields at a Glance

**PF ECR Register**
- Employee identity (via compliance record → employee)
- `basic_wage` — PF-eligible wages capped at ₹15,000 (Basic + DA)
- `emp_contribution` — employee share at 12% of PF wages
- `employer_epf` — employer EPF contribution at 3.67%
- `employer_eps` — employer EPS (pension) contribution at 8.33%
- `ncp_days` — non-contributing days required for EPFO ECR file format
- `status` — filing lifecycle: `computed`, `submitted`, `challan_generated`

**ESI Challan Register**
- Employee identity (via compliance record → employee)
- `gross_wage` — ESI-eligible wages (gross ≤ ₹21,000 per month)
- `emp_contribution` — employee share at 0.75%
- `employer_contribution` — employer share at 3.25%
- `status` — filing lifecycle: `computed`, `submitted`, `challan_generated`

## Business Rules and Conditions

**Locked Run Dependency** — Both exports depend on a payroll run's computation having been executed. The controllers do not independently guard on run status, but the underlying contribution register tables are populated during payroll computation — if the run has not been computed, no records will exist.

**Permission Scope** — Both exports share the `pay.bank_file.export` permission, as they are compliance-adjacent exports that the same authorised role (Payroll Manager / Compliance Officer) would handle.

**Data Freshness** — Re-computing a payroll run regenerates the contribution register entries via `updateOrCreate` logic in the computation service, ensuring the registers are always in sync with the latest computation.

## Workflow Steps

**Viewing PF ECR** — The Payroll Manager opens a computed/locked payroll run and navigates to "PF ECR." The system queries `PfContributionRegister` records for that run, displaying each employee's PF wages, employee contribution, employer EPF, employer EPS, and NCP days in a table format.

**Viewing ESI Challan** — Similarly, navigating to "ESI Challan" displays `EsiContributionRegister` records for the run, showing gross wages and both employee and employer contributions.

## Example Scenario

After locking the January 2026 payroll run, Compliance Officer Priya navigates to "PF ECR" under the run. She sees 45 employees with PF contributions listed — each showing UAN-linked data, basic wage (capped at ₹15,000), employee contribution of ₹1,800, employer EPF of ₹550.50, and employer EPS of ₹1,249.50. She also checks "ESI Challan" which shows 12 employees with gross wages under ₹21,000 and ESI contributions at 0.75%/3.25%.

## Related Screens

- **Payroll Runs** — parent payroll run that provides the computation context
- **Compliance Records** — per-employee PF/ESI applicability and reference numbers linked through the register
- **Payroll Run Details** — the computation source for contribution amounts

## Requirements

- `StatutoryController@pfEcr(PayrollRun)` — renders PF contribution register view; gates on `pay.bank_file.export`; queries `PfContributionRegister::with('complianceRecord.employee')->where('payroll_run_id', $run->id)->active()->get()`
- `StatutoryController@esiChallan(PayrollRun)` — renders ESI contribution register view; gates on `pay.bank_file.export`; queries `EsiContributionRegister::with('complianceRecord.employee')->where('payroll_run_id', $run->id)->active()->get()`
- `PfContributionRegister` model — table `hrs_pf_contribution_register`; tracks PF contribution amounts per employee per month with filing status
- `EsiContributionRegister` model — table `hrs_esi_contribution_register`; tracks ESI contribution amounts per employee per month with filing status
- Contribution registers populated during payroll computation by `PayrollComputationService`

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `pay.bank_file.export` | `pfEcr`, `esiChallan` | View statutory export registers |

## Logic Flow

**Page Load (PF ECR)** — User with `pay.bank_file.export` accesses the route. The system queries `PfContributionRegister::with('complianceRecord.employee')->where('payroll_run_id', $run->id)->active()->get()` and renders the `hrstaff::statutory.pf_ecr` view.

**Page Load (ESI Challan)** — Same flow but queries `EsiContributionRegister` and renders `hrstaff::statutory.esi_challan`.

## Validate Before Save

No form validation — these are read-only display views.

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| No records exist for the run | Empty table rendered (graceful) | View logic |
| Run not found | ModelNotFoundException → 404 | Automatic |
| Access without permission | HTTP 403 | Gate |

## Success Scenarios

**SC-001 — PF ECR Loaded** — Priya opens PF ECR for a computed run with 45 PF-eligible employees. The table displays all 45 records with correct PF wages and contribution splits.

**SC-002 — ESI Challan Loaded** — Priya opens ESI Challan for the same run. The table displays 12 ESI-eligible employees with gross wages and contribution amounts.

## Failure Scenarios

**FC-001 — Run Not Computed** — Priya opens PF ECR for a draft run that has not been computed. The contribution register tables are empty; the page renders an empty table.

**FC-002 — No PF/ESI Compliance Records** — Priya opens PF ECR for a run where no employees have PF compliance configured. The page renders an empty table.

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `pay_payroll_runs` | FK parent | Both registers FK → `pay_payroll_runs.id` |
| `hrs_compliance_records` | FK parent | Both registers FK → `hrs_compliance_records.id` |
| `sch_employees` | FK parent (via compliance) | Employee data for display |
| `PayrollComputationService` | Service | Populates register tables during computation |

**Table: `hrs_pf_contribution_register`**

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED | PK, Auto-increment |
| compliance_record_id | BIGINT UNSIGNED | NOT NULL, FK → hrs_compliance_records.id |
| payroll_run_id | BIGINT UNSIGNED | NULL, FK → pay_payroll_runs.id |
| month | TINYINT UNSIGNED | NOT NULL |
| year | SMALLINT UNSIGNED | NOT NULL |
| basic_wage | DECIMAL(12,2) | NOT NULL |
| emp_contribution | DECIMAL(10,2) | NOT NULL |
| employer_epf | DECIMAL(10,2) | NOT NULL |
| employer_eps | DECIMAL(10,2) | NOT NULL |
| ncp_days | TINYINT UNSIGNED | NOT NULL, DEFAULT 0 |
| status | ENUM('computed','submitted','challan_generated') | NOT NULL, DEFAULT 'computed' |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| deleted_at | TIMESTAMP | NULL |
| UNIQUE KEY | `uq_hrs_pfreg` | (`compliance_record_id`, `month`, `year`) |

**Table: `hrs_esi_contribution_register`**

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED | PK, Auto-increment |
| compliance_record_id | BIGINT UNSIGNED | NOT NULL, FK → hrs_compliance_records.id |
| payroll_run_id | BIGINT UNSIGNED | NULL, FK → pay_payroll_runs.id |
| month | TINYINT UNSIGNED | NOT NULL |
| year | SMALLINT UNSIGNED | NOT NULL |
| gross_wage | DECIMAL(12,2) | NOT NULL |
| emp_contribution | DECIMAL(10,2) | NOT NULL |
| employer_contribution | DECIMAL(10,2) | NOT NULL |
| status | ENUM('computed','submitted','challan_generated') | NOT NULL, DEFAULT 'computed' |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| deleted_at | TIMESTAMP | NULL |
| UNIQUE KEY | `uq_hrs_esireg` | (`compliance_record_id`, `month`, `year`) |
