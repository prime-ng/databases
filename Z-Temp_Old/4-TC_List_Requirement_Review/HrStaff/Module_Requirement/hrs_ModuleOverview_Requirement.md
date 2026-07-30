# HrStaff Module — Business Requirements Overview

## Module Purpose

The HrStaff module manages the complete employee lifecycle for a school — from hiring through payroll, performance appraisals, and increments. It transforms raw employee data into actionable HR operations: leave management with balance tracking, salary computation with statutory compliance (PF, ESI, PT, TDS), performance appraisal cycles with KPI-driven ratings, and rule-based increment processing tied to appraisal outcomes.

The module serves as the system of record for all staff-related financial and administrative operations, feeding payroll run data to bank disbursement files, generating Form 16 and payslips, and providing real-time reports on salary registers, CTC analysis, and payroll trends.

---

## Default Data Load

The module overview screen routes (`/hr-masters`, `/leave-management`, `/payroll-overview`, `/appraisals-overview`, `/hr-reports`) are combined tabbed pages rendered by `HrMenuController`. Each page loads multiple sub-tabse data simultaneously — shared dropdowns (academic sessions, departments, designations, employees) plus grid data per tab. No single "landing" dashboard exists; each tab group is accessed independently via the menu.

---

## HR Masters — Master Configuration

This tab group consolidates all HR reference data in one page. Each tab is a full CRUD interface or read-only list.

**Leave Types** — Configurable leave categories (CL, EL, SL, ML, PL, CO, LWP) with per-type rules: carry-forward days, paid/unpaid flag, medical certificate requirements, gender restrictions, and service eligibility.

**Holiday Calendar** — School holiday schedule per academic year with types (national, state, school, optional) and staff applicability filters.

**Pay Grades** — Salary grade bands with min/max CTC ranges per grade, optionally restricted to specific designations.

**Salary Components** — Pay structure building blocks (earnings, deductions, employer contributions) with calculation types: fixed, percentage-based, statutory, or manual.

**Salary Structures** — Template grouping of salary components with sequence ordering, formula overrides, and mandatory-component flags.

**ID Card Templates** — Configurable ID card layouts with field positioning and color scheme definitions.

**PT Slabs** — State-wise Profession Tax slabs (seeded for HP, KA, MH) used during payroll computation.

**Leave Balance Adjustments** — Manual adjustment audit trail for HR to correct leave balances; logs reason and adjusted-by employee.

**TDS Ledgers** — Monthly TDS cumulative ledger per employee per financial year for tax reporting.

---

## Leave Management — Staff Time-Off

**Leave Policy** — School-wide rules: max backdated days, minimum advance notice, approval levels (HOD-only or HOD + Principal), optional holiday count.

**Leave Balances** — Per-employee per-leave-type per-academic-year balance showing allocated, carried-forward, used, and LOP days. Initializable by academic year.

**Leave Applications** — Full leave application lifecycle: apply (with date-range day-count computation), multi-level approval workflow, cancellation, and status tracking.

**LOP Reconciliation** — Flagged attendance gaps awaiting HR confirmation or waiver before payroll deduction.

---

## Payroll — Salary Computation

**Payroll Runs** — Monthly payroll with FSM: draft → computing → computed → reviewing → approved → locked. Supports regular and supplementary runs.

**Compliance Registers** — PF contribution register and ESI contribution register per employee per month, with submission and challan-generation status tracking.

**Form 16** — Annual tax certificate generation (Part A + Part B) per employee per financial year, stored as password-protected PDFs.

**Statutory Exports** — PF ECR file generation and ESI challan export for regulatory filing.

---

## Appraisals — Performance Management

**KPI Templates** — Reusable KPI templates with weighted items (academic, behavioral, administrative categories) and configurable rating scale (5 or 10).

**Appraisal Cycles** — Time-bound review periods (annual, mid-year, probation, confirmation) with self-assessment and manager-review date windows, auto or manual reviewer assignment, and department filtering.

**Appraisals** — Employee performance records with two-phase rating (self + manager), weighted overall rating computation, HR finalization with ±10% tolerance, and automatic increment flag creation.

**Increment Policies** — Rules mapping finalised appraisal rating ranges to increment amounts (percentage of CTC or flat amount), optionally linked to specific appraisal cycles.

**Process Increments** — Processing engine that matches pending increment flags to policies, computes new CTC, creates salary revisions, and updates flag status.

---

## Reports — Payroll Analytics

**Salary Register** — Per-employee salary breakdown for a selected payroll run.

**Bank Summary** — Aggregated bank transfer summary for a selected payroll run.

**CTC Analysis** — Employee-wise annual CTC composition analysis.

**Payroll Trend** — Month-over-month payroll cost trends.

---

## Requirements

- The system MUST provide combined tabbed pages for HR Masters, Leave Management, Payroll, Appraisals, and Reports, with each sub-tab loading independent data grids.
- The system MUST enforce soft-delete with full restore/force-delete workflow on all master-data CRUD resources (leave types, holidays, pay grades, salary components, salary structures, ID card templates, PT slabs, leave balance adjustments, TDS ledgers, KPI templates, appraisal cycles, increment policies).
- The system MUST use Spatie Permission-based authorization with distinct permission strings per functional area: `hrs.appraisal.manage`, `hrs.appraisal.self`, `hrs.appraisal.review`, `pay.increment.process`.
- The system MUST log all state-changing operations via the `activityLog()` helper with descriptive messages.
- The system MUST implement approval-level leave management: leave applications go through a configurable number of approval levels (HOD and/or Principal) with status FSM (pending → approved/rejected/cancelled/returned).
- The system MUST compute payroll through a multi-stage pipeline: draft → computing → computed → reviewing → approved → locked, with bank file export and mark-as-paid at the final stage.
- The system MUST enforce statutory compliance by computing PF, ESI, PT, and TDS per employee per month using compliance record configurations and regulatory thresholds.
- The system MUST support appraisal cycles with self-assessment and manager-review date windows, KPI-weighted rating computation, and auto-creation of increment flags on finalization.
- The system MUST process salary increments by matching finalized appraisal ratings to increment policies, computing new CTC, and creating salary revision records with effective-dated future assignments.
- The system MUST protect encrypted PII fields (bank account numbers) via Laravel's `encrypt()` and never store them in plaintext.

---

## Dependencies module and tables

### Primary Tables

| Table Name | Description | Module Area |
|---|---|---|
| `hrs_leave_types` | Configurable leave type definitions | HR Masters |
| `hrs_holiday_calendars` | School holiday schedule per academic year | HR Masters |
| `hrs_pay_grades` | Salary grade bands with min/max CTC | HR Masters |
| `pay_salary_components` | Salary component definitions (earnings, deductions, employer) | HR Masters |
| `pay_salary_structures` | Salary structure templates | HR Masters |
| `pay_salary_structure_components` | Junction: components linked to structures with formula overrides | HR Masters |
| `hrs_id_card_templates` | Configurable ID card layout templates | HR Masters |
| `hrs_pt_slabs` | State-wise Profession Tax slabs | HR Masters |
| `hrs_employment_details` | One-to-one HR extension per employee | HR Core |
| `hrs_employment_history` | Immutable audit trail of employment changes | HR Core |
| `hrs_employee_documents` | Employee document repository linked to sys_media | HR Core |
| `hrs_leave_policies` | School-wide leave policy configuration | Leave Management |
| `hrs_leave_balances` | Per-employee per-leave-type per-academic-year balance | Leave Management |
| `hrs_leave_applications` | Employee leave applications with FSM status | Leave Management |
| `hrs_leave_approvals` | Approval action log per leave application step | Leave Management |
| `hrs_lop_records` | LOP flags from attendance reconciliation | Leave Management |
| `hrs_leave_balance_adjustments` | Manual leave balance adjustment audit trail | Leave Management |
| `hrs_compliance_records` | Statutory compliance per employee per type (PF, ESI, TDS, PT, Gratuity) | Payroll |
| `hrs_salary_assignments` | Employee-to-structure link with CTC; new row per revision | Payroll |
| `pay_payroll_runs` | Monthly payroll run header with FSM | Payroll |
| `pay_payroll_run_details` | Per-employee per-run computed payroll | Payroll |
| `pay_payroll_overrides` | Manual amendment audit trail | Payroll |
| `pay_payslips` | Generated payslip PDF records | Payroll |
| `pay_tds_ledger` | Monthly TDS cumulative ledger | Payroll |
| `pay_form16` | Generated Form 16 PDF records | Payroll |
| `hrs_pf_contribution_register` | Monthly PF contribution amounts | Payroll |
| `hrs_esi_contribution_register` | Monthly ESI contribution amounts | Payroll |
| `hrs_kpi_templates` | KPI template definitions | Appraisals |
| `hrs_kpi_template_items` | Individual KPI items with weights per template | Appraisals |
| `hrs_appraisal_cycles` | Appraisal cycle configuration | Appraisals |
| `hrs_appraisals` | Individual appraisal records per employee per cycle | Appraisals |
| `hrs_appraisal_increment_flags` | Bridge: finalized appraisal to increment processing | Appraisals |
| `pay_increment_policies` | Rules mapping rating ranges to increment amounts | Increments |

### External Module Dependencies

| Module | Nature of Dependency |
|---|---|
| SchoolSetup | **Required** — Provides `sch_employees`, `sch_org_academic_sessions_jnt`, `sch_departments`, `sch_designations`, `sys_users` |
| StudentProfile | **Optional** — Consumption only (no direct FK); payroll trends may be cross-referenced |
| Attendance | **Required** — `att_staff_attendances` drives LOP flagging (pending module);
