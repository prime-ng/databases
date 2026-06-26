# HR & Payroll Module — Requirement Specification Document v2
**Version:** 2.0  |  **Date:** 2026-03-26  |  **Author:** Claude Code
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** HRS  |  **Module Path:** `📐 Proposed: Modules/HrStaff/`
**Module Type:** Tenant  |  **Database:** `📐 Proposed: tenant_db`
**Table Prefixes:** `hrs_*` (HR) + `pay_*` (Payroll) — both in same module
**Processing Mode:** RBS_ONLY
**RBS Reference:** C (Staff & HR Management) + PAY (Payroll) — merged into single module
**RBS Version:** v2.0 (PrimeAI_Complete_Spec_v2.md)
**V1 Baseline:** `2-Requirement_Module_wise/2-Detailed_Requirements/V2/HRS_HrStaff_Requirement.md`
**V2 Change:** Payroll (previously `prl_*` / `pay_*` separate module) merged into HRS. Single HR & Payroll module.

---

## Table of Contents
1. [Module Overview](#1-module-overview)
2. [Business Context](#2-business-context)
3. [Scope and Boundaries](#3-scope-and-boundaries)
4. [Functional Requirements](#4-functional-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [Database Schema](#6-database-schema)
7. [API and Routes](#7-api-and-routes)
8. [Business Rules](#8-business-rules)
9. [Workflow State Machines](#9-workflow-state-machines)
10. [Authorization and RBAC](#10-authorization-and-rbac)
11. [Service Layer Architecture](#11-service-layer-architecture)
12. [Integration Points](#12-integration-points)
13. [UI/UX Requirements](#13-uiux-requirements)
14. [Test Coverage](#14-test-coverage)
15. [Implementation Priorities](#15-implementation-priorities)
16. [Open Questions and Decisions](#16-open-questions-and-decisions)

---

## 1. Module Overview

### 1.1 Module Identity

| Property | Value |
|---|---|
| Module Name | HrStaff (HR & Payroll) |
| Module Code | HRS |
| Laravel Module Namespace | `Modules\HrStaff` |
| Module Path | `📐 Proposed: Modules/HrStaff/` |
| Route Prefix | `hr-staff/` |
| Route Name Prefix | `hr-staff.` |
| DB Table Prefix (HR) | `hrs_*` |
| DB Table Prefix (Payroll) | `pay_*` |
| Module Type | Tenant (database-per-tenant via stancl/tenancy v3.9) |
| Registered In | `routes/tenant.php` |

> **v2 Decision:** Payroll (previously planned as a separate `prl_*` module) is merged into HrStaff. Both `hrs_*` and `pay_*` tables live in the same Laravel module, same tenant database. This eliminates inter-module coupling for the most tightly coupled feature pair in a school ERP.

### 1.2 Module Scale (Proposed)

| Artifact | v1 (HR only) | v2 (HR + Payroll) |
|---|---|---|
| Controllers | 📐 10 | 📐 16 |
| Models | 📐 16 | 📐 26 |
| Services | 📐 7 | 📐 13 |
| FormRequests | 📐 18 | 📐 30 |
| Policies | 📐 10 | 📐 13 |
| DDL Tables (`hrs_*`) | 📐 15 | 📐 15 |
| DDL Tables (`pay_*`) | 📐 0 | 📐 8 |
| Views (Blade) | 📐 ~60 | 📐 ~110 |

### 1.3 Module Purpose

HrStaff is the complete **HR workflow and payroll engine** for Prime-AI. It handles:
- **HR Layer:** Extends `sch_employees` with employment details, documents, leave management (types, balances, application, approval, LOP reconciliation), statutory compliance (PF/ESI/TDS/Gratuity), performance appraisal (KPI templates, cycles, self/manager review), and ID card generation.
- **Payroll Layer:** Owns the full payroll cycle — salary structure master, monthly payroll computation, payslip generation, bank disbursement files, TDS computation, Form 16 generation, PF/ESI challans, and payroll reports.

---

## 2. Business Context

### 2.1 Business Problem

| Pain Point | Impact |
|---|---|
| Manual leave tracking on paper/registers | Over-granting of leave, no balance enforcement |
| No multi-level approval workflow | Leave approvals bypassed or delayed |
| Scattered employee documents | Missing compliance proof during audits |
| Manual PF/ESI register maintenance | Errors in statutory filings |
| Appraisal conducted via informal discussion | No audit trail, subjective increment decisions |
| Employee ID cards printed externally | Delays in issuance, no QR code-based identity |
| Payroll calculated in Excel every month | Error-prone, no audit trail, cannot handle increments automatically |
| Payslips emailed manually as PDFs | No self-service download, password protection missing |
| Bank payment file prepared manually | NEFT file errors, delays in salary credit |
| Form 16 issued after manual TDS computation | Late issuance, compliance risk |
| No link between appraisal and salary revision | Increment decisions not tracked in system |

### 2.2 Primary User Roles

| Role | Key Actions |
|---|---|
| HR Manager | Full CRUD for HR records, leave approvals, compliance records, payroll prep, appraisal management, payroll run initiation |
| Payroll Manager | Initiate/compute/approve payroll runs, generate payslips, export bank file, generate Form 16 |
| Principal | View all records, final-level leave approval, appraisal finalization, payroll approval |
| HOD | Approve leave for department, initiate/review department appraisals |
| Employee (Self-Service) | Apply leave, submit self-appraisal, view leave balance, download payslip, download ID card, view Form 16 |
| Accountant | Read salary structure assignments, PF/ESI registers, payroll summary (read-only) |

### 2.3 Indian Compliance Context

| Statutory | Applicability | Rate | Handled By |
|---|---|---|---|
| PF (EPF Act 1952) | Basic ≤ ₹15,000 mandatory; else voluntary | Employee 12%; Employer 12% (3.67% EPF + 8.33% EPS) | HrStaff (compliance records + payroll deduction) |
| ESI (ESI Act 1948) | Gross ≤ ₹21,000 | Employee 0.75%; Employer 3.25% | HrStaff (compliance records + payroll deduction) |
| TDS (IT Act Sec 192) | All salaried employees | Per tax slab (old/new regime) | HrStaff Payroll (compute + deduct monthly) |
| Gratuity (Gratuity Act 1972) | After 5 years continuous service | 15 days × last basic × years / 26 | HrStaff (eligibility + projected amount) |
| PT (Profession Tax) | State-wise slabs | Varies by state | HrStaff (enrollment + payroll deduction) |
| Form 16 | All employees with TDS deducted | Annual — Part A (employer) + Part B (employee) | HrStaff Payroll (generate PDF) |
| PF ECR | All PF-enrolled employees | Monthly e-filing to EPFO | HrStaff Payroll (export ECR file) |
| ESI Return | All ESI-enrolled employees | Half-yearly Form 5 | HrStaff Compliance (export) |

---

## 3. Scope and Boundaries

### 3.1 In-Scope (v2 — HR + Payroll combined)

**HR Sub-Modules (unchanged from v1):**
- Employee HR record extension (contract type, bank details, emergency contacts, employment history)
- Employee document repository (upload, categorize, expiry reminders)
- Leave type configuration, holiday calendar, leave balance management
- Leave application and multi-level approval workflow (HOD → Principal)
- Attendance-leave reconciliation and LOP flagging
- Pay grade master
- Salary structure assignment (employee ↔ structure mapping)
- Statutory compliance records: PF, ESI, TDS declarations, Gratuity
- Performance appraisal: KPI templates, appraisal cycles, self-appraisal, manager review, finalization
- Staff ID card generation (QR code, DomPDF)
- HR reports: headcount, attrition, leave utilization, compliance status

**Payroll Sub-Modules (NEW in v2 — previously out of scope):**
- Salary component master (earnings + deduction components)
- Salary structure template (composition of components with calculation rules)
- Monthly payroll run: initiate, compute, review, approve, lock
- LWP-based deduction computation (from confirmed LOP records)
- Payslip generation (PDF per employee per month)
- Bulk payslip generation and email/self-service distribution
- Bank NEFT/RTGS file export (salary disbursement)
- TDS monthly deduction computation (per tax regime)
- Annual TDS reconciliation and projected tax computation
- Form 16 generation (Part A + Part B as PDF)
- PF ECR file generation (EPFO portal format)
- ESI contribution challan export
- Variable pay integration from finalized appraisals
- Salary increment processing (% or flat, with effective date)
- Payroll reports: salary register, bank transfer summary, CTC vs net analysis

### 3.2 Out of Scope (v2)

| Item | Owner Module |
|---|---|
| Actual PF/ESI remittance and bank payment processing | Finance/Accounting (`acc_*`) |
| Payroll Journal Voucher creation | Accounting (`acc_*`) — triggered by `PayrollApproved` event |
| Biometric device sync for attendance | Attendance (`att_*`) |
| Recruitment and applicant tracking | Future module (not planned) |
| Staff mobile app portal | Future phase |
| Gratuity disbursement payment | Finance/Accounting (`acc_*`) |

---

## 4. Functional Requirements

> All items are **📐 Proposed** and status is **❌ Not Started** unless noted.

---

### 4.1 Sub-Module C1 — Staff HR Records

#### FR-HRS-001: Employee HR Details Extension 📐 ❌
- HR Manager records employment details in `hrs_employment_details` (one row per employee):
  - `contract_type`: `permanent` | `contractual` | `probation` | `part_time` | `substitute`
  - Probation period (months), probation end date, confirmation date
  - Notice period (days)
  - Bank account: account number, IFSC, bank name, branch (application-level encrypted via Laravel `encrypt()`)
  - Emergency contact: name, relationship, phone, address
- Employee ID auto-generated on `sch_employees` creation: format `EMP/YYYY/NNN` (e.g., `EMP/2026/001`), unique within tenant.
- `reporting_to` managed via existing `sch_employee_profiles.reporting_to`.

#### FR-HRS-002: Employment History Log 📐 ❌
- System maintains `hrs_employment_history` for every change to contract type, department, designation, or salary grade.
- Each history record: `employee_id`, `change_type`, `old_value` (JSON), `new_value` (JSON), `effective_date`, `changed_by`, `remarks`.
- HR Manager can view full history per employee on a timeline view.

#### FR-HRS-003: Employee Document Repository 📐 ❌
- HR Manager and employee can upload to `hrs_employee_documents`:
  - Document types: `appointment_letter`, `increment_letter`, `transfer_letter`, `warning_letter`, `experience_certificate`, `id_proof`, `educational_certificate`, `medical_certificate`, `other`
  - Fields: `employee_id`, `document_type`, `document_name`, `media_id` (FK `sys_media`), `issued_date`, `expiry_date`, `issued_by`, `remarks`
- Files stored via `sys_media` (no direct public URL — secure download only).
- Renewal reminders dispatched 30 days before `expiry_date` (via `ntf_notifications`).

#### FR-HRS-004: Staff ID Card Generation 📐 ❌
- HR Manager generates ID card PDF via DomPDF.
- Card displays: photo, name, designation, department, `emp_code`, QR code encoding `emp_code`.
- Template configurable per school (logo, colors, fields shown) via `hrs_id_card_templates`.
- Stored as generated media in `sys_media`; downloadable and printable.

---

### 4.2 Sub-Module C2+C3 — Leave Management

#### FR-HRS-005: Leave Type Master 📐 ❌
- HR Manager configures `hrs_leave_types`:
  - `code` (unique, e.g., `CL`, `EL`, `SL`), `name`, `days_per_year`, `carry_forward_days` (0 = no carry-forward)
  - `applicable_to`: `all` | `teaching` | `non_teaching`
  - `is_paid`: boolean; `requires_medical_cert`: boolean; `medical_cert_threshold_days`
  - `half_day_allowed`: boolean; `gender_restriction`: `all` | `male` | `female`
  - `min_service_months` (eligibility gate), `max_consecutive_days`
- Pre-seeded defaults: CL (12d), EL (15d, carry-forward 30d), SL (12d), ML (180d, female), PL (15d, male), CO (variable), LWP (unlimited, unpaid).

#### FR-HRS-006: Holiday Calendar 📐 ❌
- HR Manager defines `hrs_holiday_calendars` per academic year:
  - `holiday_date`, `holiday_name`, `holiday_type` (`national` | `state` | `school` | `optional`), `applicable_to`
- Leave duration calculation **excludes** matching holidays and weekends (per school's working days config in `sch_*`).
- Optional holidays: employee can elect up to N per year (configurable in `hrs_leave_policies`).

#### FR-HRS-007: Leave Policy Configuration 📐 ❌
- `hrs_leave_policies` stores school-wide and employee-group-level policy overrides:
  - `max_backdated_days`, `min_advance_days`, `approval_levels` (1 or 2), `optional_holiday_count`

#### FR-HRS-008: Leave Balance Initialization 📐 ❌
- HR Manager triggers annual balance initialization (per academic year) → creates `hrs_leave_balances` rows.
- Carry-forward: `MIN(prior_year_closing_balance, leave_type.carry_forward_days)`.
- Manual adjustments logged in `hrs_leave_balance_adjustments` (reason required).

#### FR-HRS-009: Leave Application 📐 ❌
- Employee (self-service) submits `hrs_leave_applications`.
- Pre-submission validations: balance sufficient, no overlap, min service months, date within window.
- Status on creation: `pending`.

#### FR-HRS-010: Leave Approval Workflow 📐 ❌
- Approval driven by `hrs_leave_policies.approval_levels` (1 or 2 levels).
- Each step stored in `hrs_leave_approvals` (`application_id`, `approver_id`, `level`, `action`, `remarks`, `actioned_at`).
- Actions: `approve` | `reject` | `return_for_clarification`.
- On final approval: balance updated; notification to employee.
- Employee can cancel if `from_date` is in the future → balance restored.

#### FR-HRS-011: Leave Balance Dashboard 📐 ❌
- Employee: balance card per leave type (allocated, used, available, carry-forward).
- HR Manager: matrix report (employees × leave types) with department/designation filters. Export CSV/PDF.

#### FR-HRS-012: LOP Reconciliation 📐 ❌
- HrStaff reads `att_staff_attendances` (read-only cross-module reference).
- Absent without approved leave → auto-flagged in `hrs_lop_records` (flag_status: `flagged` | `confirmed` | `waived`).
- HR Manager confirms LOP before month-end close.
- **v2:** Confirmed LOP records consumed **internally** by the Payroll sub-module.

---

### 4.3 Sub-Module C4a — Payroll Preparation (HR Layer)

#### FR-HRS-013: Pay Grade Master 📐 ❌
- HR Manager configures `hrs_pay_grades`: `grade_name`, `min_ctc`, `max_ctc`, `applicable_designation_ids` (JSON).

#### FR-HRS-014: Employee Salary Assignment 📐 ❌
- HR Manager assigns salary structure per employee in `hrs_salary_assignments`:
  - `employee_id`, `pay_salary_structure_id` (FK → `pay_salary_structures.id`), `pay_grade_id`, `ctc_amount`, `gross_monthly`, `effective_from_date`, `effective_to_date`, `revision_reason`
- History preserved: new row per revision; prior row gets `effective_to_date` set.
- Payroll run reads the latest active assignment.

---

### 4.4 Sub-Module C4b — Statutory Compliance Records

#### FR-HRS-015: PF Compliance Records 📐 ❌
- `hrs_compliance_records` (`compliance_type = 'pf'`): UAN, enrollment date, applicable flag, nominee JSON.
- Monthly `hrs_pf_contribution_register`: basic wage, employee 12%, employer EPF 3.67%, employer EPS 8.33%, status.
- **v2:** Status transitions (`computed` → `submitted` → `challan_generated`) now driven by **internal Payroll sub-module** (not external prl_* module).
- Export: Form 12A format (PDF/CSV).

#### FR-HRS-016: ESI Compliance Records 📐 ❌
- `hrs_compliance_records` (`compliance_type = 'esi'`): IP number, enrollment date, dispensary details.
- Monthly `hrs_esi_contribution_register`: gross wage, employee 0.75%, employer 3.25%, status.
- Export: Form 5 half-yearly returns (PDF/CSV).

#### FR-HRS-017: TDS Declaration Storage 📐 ❌
- `hrs_compliance_records` (`compliance_type = 'tds'`): PAN (Laravel `encrypt()`), tax regime (`old` | `new`), investment declarations JSON (80C, 80D, HRA, LTA).
- **v2:** Form 16 generation is now **in-scope** (see FR-HRS-037).

#### FR-HRS-018: Gratuity Records 📐 ❌
- `hrs_compliance_records` (`compliance_type = 'gratuity'`): applicable flag, nominee details, eligibility date, projected amount.
- On employee exit: computed amount signalled to Finance via event.

---

### 4.5 Sub-Module C8 — Performance Appraisal

#### FR-HRS-019: KPI Template Management 📐 ❌
- HR Manager creates `hrs_kpi_templates` with `hrs_kpi_template_items`:
  - Template: `name`, `applicable_to`, `rating_scale` (5 or 10).
  - Item: `kpi_name`, `category` (`academic` | `behavioral` | `administrative`), `weight` (%, must sum 100), `description`.

#### FR-HRS-020: Appraisal Cycle Configuration 📐 ❌
- HR Manager creates `hrs_appraisal_cycles`:
  - `name`, `academic_year_id`, `appraisal_type` (`annual` | `mid_year` | `probation` | `confirmation`)
  - `kpi_template_id`, self-appraisal and manager review open/close dates
  - `applicable_departments` (JSON), `reviewer_assignment_mode` (`auto` | `manual`)

#### FR-HRS-021: Self-Appraisal Submission 📐 ❌
- Employee enters `hrs_appraisals`: per KPI — self-rating, self-comments, evidence upload.
- Status: `draft` → `submitted` (cannot revert without HR unlock).

#### FR-HRS-022: Manager Review and Finalization 📐 ❌
- Reviewer enters reviewer rating + comments per KPI item.
- System computes `overall_rating` = weighted average.
- Status: `reviewed` → `finalized` (by HR Manager).
- Finalization triggers: employee notification + creates `hrs_appraisal_increment_flags` for Payroll sub-module.

---

### 4.6 Sub-Module P1 — Salary Structure Master (NEW)

#### FR-HRS-023: Salary Component Master 📐 ❌
- HR/Payroll Manager creates `pay_salary_components`:
  - `name`, `code` (unique, e.g., `BASIC`, `DA`, `HRA`, `CONV`, `MEDICAL`, `LTA`, `SPECIAL`, `PF_EMP`, `PF_ERR`, `ESI_EMP`, `ESI_ERR`, `PT`, `TDS`, `LWP_DED`)
  - `component_type`: `earning` | `deduction` | `employer_contribution`
  - `calculation_type`: `fixed` | `percentage_of_basic` | `percentage_of_gross` | `statutory` | `manual`
  - `default_value`: DECIMAL — default amount or percentage
  - `is_taxable`: boolean (affects TDS computation)
  - `is_statutory`: boolean (PF, ESI, PT, TDS components)

#### FR-HRS-024: Salary Structure Template 📐 ❌
- HR/Payroll Manager creates `pay_salary_structures`:
  - `name`, `description`, `applicable_to` (`all` | `teaching` | `non_teaching` | `contractual`)
  - `is_active`: boolean
- `pay_salary_structure_components` defines composition:
  - `structure_id`, `component_id`, `sequence_order`, `calculation_formula` (override formula if needed), `is_mandatory`
- Validation: sum of earning % must be interpretable; structure must include at least BASIC, PF_EMP, ESI_EMP.

#### FR-HRS-025: CTC Breakdown Preview 📐 ❌
- When HR Manager assigns a structure to an employee (FR-HRS-014), system displays live CTC breakdown:
  - Earnings per component | Deductions per component | Net Monthly | Annual CTC | Employer cost
- Preview based on entered `ctc_amount` + structure composition rules.

---

### 4.7 Sub-Module P2 — Monthly Payroll Run (NEW)

#### FR-HRS-026: Payroll Run Initiation 📐 ❌
- Payroll Manager initiates a new `pay_payroll_runs` record:
  - `payroll_month` (YYYY-MM), `academic_year_id`, `run_type` (`regular` | `supplementary`)
  - `status`: `draft` on creation
- System validates pre-conditions:
  1. LOP records confirmed for the month (`hrs_lop_records.flag_status = confirmed`)
  2. All active employees have a valid salary assignment
  3. No prior run exists for this month in `computed`/`approved`/`locked` status (blocks duplicate runs)
- Only one `regular` run allowed per month; supplementary runs allowed for missed employees.

#### FR-HRS-027: Payroll Computation Engine 📐 ❌
- Payroll Manager triggers computation for a run → system processes `pay_payroll_run_details` (one row per employee):
  - **Inputs:** `hrs_salary_assignments` (structure + CTC), `hrs_compliance_records` (PF/ESI flags), `hrs_lop_records` (confirmed LOP days), previous month TDS (for cumulative projection)
  - **Computation steps (in sequence):**
    1. Resolve active salary assignment for the employee
    2. Calculate gross earnings per component (apply formulas in `pay_salary_structure_components`)
    3. Calculate LWP deduction: `(gross_per_day × lop_days)` where `gross_per_day = gross_monthly / working_days_in_month`
    4. Calculate PF deduction (employee + employer) if `compliance_records.pf.applicable_flag = true`
    5. Calculate ESI deduction (employee + employer) if `compliance_records.esi.applicable_flag = true`
    6. Calculate PT deduction from `hrs_pt_slabs` (state-wise slab) if enrolled
    7. Calculate TDS based on projected annual income and tax slab (see FR-HRS-037)
    8. Compute net pay = gross earnings − all deductions
  - **Computed fields:** `gross_pay`, `total_deductions`, `net_pay`, `pf_employee`, `pf_employer`, `esi_employee`, `esi_employer`, `tds_deducted`, `lwp_deduction`, `pt_deduction`, `computation_json` (full breakdown)
  - Run `status` → `computed` after engine completes.
- Processing is **synchronous** for ≤100 employees; dispatched as a **queued Job** for >100 employees.

#### FR-HRS-028: Payroll Review and Amendment 📐 ❌
- Payroll Manager reviews `pay_payroll_run_details` in a tabular UI before approval.
- Payroll Manager can **manually override** `net_pay` for individual employees (requires reason; logged in `pay_payroll_overrides`).
- Re-run computation for specific employees (partial re-compute without affecting others).
- Run `status` remains `computed` during review; amendments allowed only in `computed` state.

#### FR-HRS-029: Payroll Approval and Lock 📐 ❌
- Payroll Manager submits for approval → Principal reviews and approves.
- On approval: run `status` → `approved` → `locked`.
- **Locked payroll cannot be modified or re-processed** (BR-PAY-003).
- On lock: fires `PayrollApproved` event → Accounting module listener creates Journal Voucher.
- On lock: updates `hrs_pf_contribution_register` and `hrs_esi_contribution_register` status: `computed` → `submitted`.

#### FR-HRS-030: Supplementary Payroll Run 📐 ❌
- `run_type = supplementary`: processes employees who were missed in the regular run (e.g., joined mid-month).
- Supplementary run links to the same `payroll_month`; separate `pay_payroll_runs` row with `parent_run_id` FK.
- Supplementary payslips issued separately; bank file includes only supplementary employees.

---

### 4.8 Sub-Module P3 — Payslip Generation & Distribution (NEW)

#### FR-HRS-031: Individual Payslip Generation 📐 ❌
- Payroll Manager generates payslip PDF for a specific employee × payroll_month.
- Payslip displays: school header, employee details, earnings table, deductions table, net pay, YTD totals, employer contributions (PF), signatures placeholder.
- Generated via DomPDF; stored in `sys_media`; linked in `pay_payslips` table.
- Payslip PDF is **password-protected**: password = `PANlast4 + DDYYYY` of date of birth (e.g., `1234A01012000`).

#### FR-HRS-032: Bulk Payslip Generation 📐 ❌
- Payroll Manager triggers bulk generation for entire payroll run (all employees in one action).
- Dispatched as a **queued Job** (`GeneratePayslipsJob`); progress shown via polling.
- All generated PDFs stored in `sys_media`; downloadable as a ZIP archive by Payroll Manager.

#### FR-HRS-033: Payslip Email Distribution 📐 ❌
- After bulk generation: Payroll Manager triggers email distribution.
- Email sent to employee's registered email (from `sch_employees.email`) with payslip as attachment.
- Queued via `ntf_notifications`; delivery status tracked (`pending` | `sent` | `failed`).

#### FR-HRS-034: Employee Self-Service Payslip Download 📐 ❌
- Employee can download their own payslips from self-service portal (last 24 months).
- Payslip download requires Gate check (`hrs.payslip.own.download`).
- Password-protected PDF (same password as FR-HRS-031).

---

### 4.9 Sub-Module P4 — Bank Disbursement (NEW)

#### FR-HRS-035: Bank NEFT/RTGS File Export 📐 ❌
- Payroll Manager exports salary disbursement file for approved payroll run.
- File format: CSV with columns — `employee_name`, `account_number`, `IFSC`, `amount`, `remarks` (`SALARY YYYY-MM`).
- Alternative format: bank-specific fixed-width TXT (configurable per school — SBI, HDFC, ICICI supported).
- File includes only employees with `pay_payroll_run_details.net_pay > 0` and `payment_status = pending`.
- On export: `pay_payroll_run_details.payment_status` → `exported`.

#### FR-HRS-036: Payment Status Tracking 📐 ❌
- Payroll Manager can mark individual or bulk employees as `paid` after bank confirms credit.
- `pay_payroll_run_details.payment_status`: `pending` → `exported` → `paid` (or `failed`).
- Failed entries: Payroll Manager can initiate a supplementary run or manual payment.

---

### 4.10 Sub-Module P5 — TDS Computation & Form 16 (NEW)

#### FR-HRS-037: Monthly TDS Deduction Computation 📐 ❌
- TDS computed as part of payroll run (step 8 of FR-HRS-027).
- Annual projected income = `YTD_gross + (remaining_months × current_month_gross)` + investment declarations from `hrs_compliance_records.tds.details_json`.
- Tax slab applied as per `tax_regime` (`old` | `new`):
  - Old regime: standard deduction ₹50,000, 80C (max ₹1.5L), 80D, HRA, LTA exemptions applied.
  - New regime: no exemptions; flat slab rates applied.
- Monthly TDS = `(annual_tax_liability − YTD_tds_deducted) / remaining_months_in_financial_year`.
- TDS for December–March recomputed to adjust for year-end accuracy.
- Stored in `pay_payroll_run_details.tds_deducted`; cumulative in `pay_tds_ledger`.

#### FR-HRS-038: Form 16 Generation 📐 ❌
- **Eligibility:** Employees where cumulative TDS > 0 for the financial year.
- Payroll Manager generates Form 16 after financial year close (April trigger):
  - **Part A:** Employer details, employee details, quarterly TDS deposition summary, TAN, PAN.
  - **Part B:** Salary breakup, exemptions claimed, deductions, gross total income, tax payable.
- Generated per employee via DomPDF; stored in `sys_media`; linked in `pay_form16` table.
- Employee can download from self-service (`hrs.form16.own.download`).
- Bulk generation dispatched as queued Job.

---

### 4.11 Sub-Module P6 — Statutory Returns (NEW)

#### FR-HRS-039: PF ECR File Generation 📐 ❌
- Payroll Manager exports monthly PF Electronic Challan Return (ECR) file after payroll lock.
- ECR format: EPFO-prescribed pipe-delimited TXT (`#~#` separator) with UAN, member name, gross wages, EPF wages, EPS wages, EDLI wages, EPF contribution, EPS contribution, NCP days.
- File validated for: UAN format, sum-check, mandatory fields.
- On export: `hrs_pf_contribution_register.status` → `challan_generated`.

#### FR-HRS-040: ESI Contribution Export 📐 ❌
- Payroll Manager exports ESI contribution challan data for the month.
- Format: CSV with IP number, employee name, gross wages, employee contribution, employer contribution.
- Half-yearly Form 5 return export (for filing with ESIC portal): covers 6-month periods (April–September, October–March).

---

### 4.12 Sub-Module P7 — Variable Pay & Increments (NEW)

#### FR-HRS-041: Appraisal-Linked Variable Pay 📐 ❌
- After appraisal finalization (`hrs_appraisal_increment_flags.flag_status = pending`), Payroll Manager processes variable pay:
  - HR Manager defines increment rules in `pay_increment_policies`: `overall_rating` range → `increment_type` (`percentage` | `flat`) + `increment_value`.
  - System auto-proposes increment amount per employee based on `overall_rating` + `increment_policy`.
  - Payroll Manager reviews and approves proposals.
  - On approval: creates new `hrs_salary_assignments` row with `effective_from_date` = next month 1st.
  - `hrs_appraisal_increment_flags.flag_status` → `processed`.

#### FR-HRS-042: Salary Revision / Increment Processing 📐 ❌
- HR Manager can initiate ad-hoc salary revision outside appraisal cycle:
  - Inputs: `employee_id`, `revision_type` (`increment` | `revision` | `promotion`), `increment_percentage` or `new_ctc`, `effective_from_date`, `reason`.
- Creates new `hrs_salary_assignments` row; prior row closed with `effective_to_date`.
- Revision history visible in Employment History log (FR-HRS-002).
- Effective from the next payroll run after `effective_from_date`.

---

### 4.13 Sub-Module P8 — Payroll Reports (NEW)

#### FR-HRS-043: Monthly Salary Register 📐 ❌
- Payroll Manager views/exports salary register for a payroll run:
  - Columns: employee name, designation, department, basic, HRA, other earnings, gross, PF employee, ESI employee, TDS, PT, other deductions, net pay.
  - Filters: department, designation, employment type.
  - Exports: PDF (A3 landscape) + Excel.

#### FR-HRS-044: Bank Transfer Summary 📐 ❌
- Department-wise and overall summary: total gross, total deductions, total net pay, count of employees.
- Drilldown: department → individual employee amounts.
- Export: PDF + Excel.

#### FR-HRS-045: CTC vs Gross vs Net Analysis 📐 ❌
- Employee-wise and aggregate comparison:
  - Annual CTC (from `hrs_salary_assignments.ctc_amount`) vs Actual Gross YTD vs Actual Net YTD.
  - Employer cost = gross + employer PF + employer ESI.
- Export: Excel.

#### FR-HRS-046: Payroll Trend Report 📐 ❌
- Month-on-month payroll trend (last 12 months): total gross, net pay, headcount.
- Department-wise salary cost trend.
- Highlights: months where net pay deviated > 5% from prior month (anomaly detection).

---

## 5. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| NFR-001 | Performance | Leave balance read < 200 ms for single employee |
| NFR-002 | Performance | Monthly LOP reconciliation for 200 employees < 10 s |
| NFR-003 | Performance | Payroll computation for ≤100 employees < 30 s synchronous; >100 dispatched to queue |
| NFR-004 | Performance | Bulk payslip generation (200 employees) < 5 min via queue |
| NFR-005 | Security | Bank account numbers + PAN encrypted via Laravel `encrypt()`; never in plain text in activity logs |
| NFR-006 | Security | Employee documents + payslips served via signed temporary URLs |
| NFR-007 | Security | Payslip PDFs password-protected (PAN last 4 + DDYYYY of DOB) |
| NFR-008 | Compliance | PF/ESI/TDS data retained for minimum 7 years (soft-delete only) |
| NFR-009 | Compliance | Payroll computation formula changes logged with effective date in `pay_payroll_formula_changelog` |
| NFR-010 | Availability | HR module operations must not block payroll runs — async where possible |
| NFR-011 | Auditability | All leave approve/reject/cancel and payroll approve/lock actions logged in `sys_activity_logs` |
| NFR-012 | Scalability | Up to 500 employees per tenant; leave balance init < 30 s; payroll computation ≤100 < 30 s |
| NFR-013 | Accessibility | All forms WCAG 2.1 AA; keyboard navigable |
| NFR-014 | Localization | All currency in INR; dates in DD-MM-YYYY (display); DB stores ISO 8601 |
| NFR-015 | Data Integrity | Locked payroll run rows immutable — database-level check via `updated_at` audit + service guard |

---

## 6. Database Schema

> All tables include standard columns: `id`, `is_active` (default 1), `created_by`, `updated_by`, `created_at`, `updated_at`, `deleted_at`.
> All tables: InnoDB, UTF8MB4, MySQL 8.x. All 📐 Proposed.

---

### hrs_* Tables (HR Layer — unchanged from v1)

### 6.1 hrs_employment_details
| Column | Type | Notes |
|---|---|---|
| employee_id | BIGINT FK | → `sch_employees.id` UNIQUE |
| contract_type | ENUM | `permanent`,`contractual`,`probation`,`part_time`,`substitute` |
| probation_end_date | DATE | nullable |
| confirmation_date | DATE | nullable |
| notice_period_days | TINYINT | default 30 |
| bank_account_number | TEXT | Laravel `encrypt()` |
| bank_ifsc | VARCHAR(11) | |
| bank_name | VARCHAR(100) | |
| bank_branch | VARCHAR(100) | |
| emergency_contact_json | JSON | name, relationship, phone, address |
| previous_employer_json | JSON | nullable |

### 6.2 hrs_employment_history
| Column | Type | Notes |
|---|---|---|
| employee_id | BIGINT FK | → `sch_employees.id` |
| change_type | VARCHAR(50) | `contract_type`,`department`,`designation`,`pay_grade`,`salary_revision` |
| old_value | JSON | |
| new_value | JSON | |
| effective_date | DATE | |
| changed_by | BIGINT FK | → `sch_employees.id` |
| remarks | TEXT | nullable |

### 6.3 hrs_employee_documents
| Column | Type | Notes |
|---|---|---|
| employee_id | BIGINT FK | → `sch_employees.id` |
| document_type | VARCHAR(50) | |
| document_name | VARCHAR(200) | |
| media_id | BIGINT FK | → `sys_media.id` |
| issued_date | DATE | nullable |
| expiry_date | DATE | nullable |
| issued_by | VARCHAR(150) | |
| remarks | TEXT | nullable |

### 6.4 hrs_leave_types
| Column | Type | Notes |
|---|---|---|
| code | VARCHAR(10) | UNIQUE |
| name | VARCHAR(100) | |
| days_per_year | DECIMAL(5,1) | |
| carry_forward_days | TINYINT | 0 = no carry-forward |
| applicable_to | ENUM | `all`,`teaching`,`non_teaching` |
| is_paid | TINYINT(1) | |
| requires_medical_cert | TINYINT(1) | |
| medical_cert_threshold_days | TINYINT | default 3 |
| half_day_allowed | TINYINT(1) | |
| gender_restriction | ENUM | `all`,`male`,`female` |
| min_service_months | TINYINT | default 0 |
| max_consecutive_days | TINYINT | nullable |

### 6.5 hrs_holiday_calendars
| Column | Type | Notes |
|---|---|---|
| academic_year_id | BIGINT FK | → `sch_academic_years.id` |
| holiday_date | DATE | |
| holiday_name | VARCHAR(150) | |
| holiday_type | ENUM | `national`,`state`,`school`,`optional` |
| applicable_to | ENUM | `all`,`teaching`,`non_teaching` |

### 6.6 hrs_leave_policies
| Column | Type | Notes |
|---|---|---|
| academic_year_id | BIGINT FK | nullable (NULL = global default) |
| max_backdated_days | TINYINT | default 3 |
| min_advance_days | TINYINT | default 0 |
| approval_levels | TINYINT | 1 or 2 |
| optional_holiday_count | TINYINT | default 2 |

### 6.7 hrs_leave_balances
| Column | Type | Notes |
|---|---|---|
| employee_id | BIGINT FK | → `sch_employees.id` |
| leave_type_id | BIGINT FK | → `hrs_leave_types.id` |
| academic_year_id | BIGINT FK | → `sch_academic_years.id` |
| allocated_days | DECIMAL(5,1) | |
| carry_forward_days | DECIMAL(5,1) | default 0 |
| used_days | DECIMAL(5,1) | default 0 |
| lop_days | DECIMAL(5,1) | default 0 |
| UNIQUE | | (employee_id, leave_type_id, academic_year_id) |

### 6.8 hrs_leave_balance_adjustments
| Column | Type | Notes |
|---|---|---|
| leave_balance_id | BIGINT FK | → `hrs_leave_balances.id` |
| adjustment_days | DECIMAL(5,1) | positive = add, negative = deduct |
| reason | TEXT | |
| adjusted_by | BIGINT FK | → `sch_employees.id` |

### 6.9 hrs_leave_applications
| Column | Type | Notes |
|---|---|---|
| employee_id | BIGINT FK | → `sch_employees.id` |
| leave_type_id | BIGINT FK | → `hrs_leave_types.id` |
| academic_year_id | BIGINT FK | |
| from_date | DATE | |
| to_date | DATE | |
| half_day | TINYINT(1) | |
| half_day_session | ENUM | `first`,`second`, nullable |
| days_count | DECIMAL(5,1) | computed |
| reason | TEXT | |
| media_id | BIGINT FK | nullable → `sys_media.id` |
| status | ENUM | `pending`,`pending_l2`,`approved`,`rejected`,`cancelled`,`returned` |
| current_approver_level | TINYINT | 1 or 2 |

### 6.10 hrs_leave_approvals
| Column | Type | Notes |
|---|---|---|
| application_id | BIGINT FK | → `hrs_leave_applications.id` |
| approver_id | BIGINT FK | → `sch_employees.id` |
| level | TINYINT | 1 = HOD, 2 = Principal |
| action | ENUM | `approve`,`reject`,`return_for_clarification` |
| remarks | TEXT | |
| actioned_at | TIMESTAMP | |

### 6.11 hrs_pay_grades
| Column | Type | Notes |
|---|---|---|
| grade_name | VARCHAR(100) | |
| min_ctc | DECIMAL(12,2) | |
| max_ctc | DECIMAL(12,2) | |
| applicable_designation_ids | JSON | array of designation IDs |

### 6.12 hrs_salary_assignments
| Column | Type | Notes |
|---|---|---|
| employee_id | BIGINT FK | → `sch_employees.id` |
| pay_salary_structure_id | BIGINT FK | → `pay_salary_structures.id` (v2: internal FK, not external prl_*) |
| pay_grade_id | BIGINT FK | → `hrs_pay_grades.id` |
| ctc_amount | DECIMAL(12,2) | |
| gross_monthly | DECIMAL(12,2) | |
| effective_from_date | DATE | |
| effective_to_date | DATE | nullable |
| revision_reason | VARCHAR(200) | |

### 6.13 hrs_compliance_records
| Column | Type | Notes |
|---|---|---|
| employee_id | BIGINT FK | → `sch_employees.id` |
| compliance_type | ENUM | `pf`,`esi`,`tds`,`gratuity`,`pt` |
| reference_number | VARCHAR(100) | UAN / IP / PAN (encrypted for TDS) |
| enrollment_date | DATE | |
| applicable_flag | TINYINT(1) | |
| nominee_json | JSON | nullable |
| details_json | JSON | type-specific: regime, 80C, dispensary, state (for PT) |
| UNIQUE | | (employee_id, compliance_type) |

### 6.14 hrs_appraisal_cycles
| Column | Type | Notes |
|---|---|---|
| name | VARCHAR(200) | |
| academic_year_id | BIGINT FK | |
| appraisal_type | ENUM | `annual`,`mid_year`,`probation`,`confirmation` |
| kpi_template_id | BIGINT FK | → `hrs_kpi_templates.id` |
| self_open_date | DATE | |
| self_close_date | DATE | |
| manager_open_date | DATE | |
| manager_close_date | DATE | |
| applicable_departments | JSON | |
| reviewer_mode | ENUM | `auto`,`manual` |
| status | ENUM | `draft`,`active`,`closed` |

### 6.15 hrs_appraisals
| Column | Type | Notes |
|---|---|---|
| cycle_id | BIGINT FK | → `hrs_appraisal_cycles.id` |
| employee_id | BIGINT FK | → `sch_employees.id` |
| reviewer_id | BIGINT FK | → `sch_employees.id` |
| self_rating_json | JSON | per-KPI self ratings and comments |
| reviewer_rating_json | JSON | per-KPI reviewer ratings and comments |
| overall_rating | DECIMAL(4,2) | computed |
| self_comments | TEXT | |
| reviewer_comments | TEXT | |
| hr_remarks | TEXT | nullable |
| status | ENUM | `draft`,`submitted`,`reviewed`,`finalized` |
| finalized_at | TIMESTAMP | nullable |
| UNIQUE | | (cycle_id, employee_id) |

### Auxiliary hrs_* Tables
- `hrs_kpi_templates` — id, name, applicable_to, rating_scale
- `hrs_kpi_template_items` — id, template_id, kpi_name, category, weight, description
- `hrs_lop_records` — id, employee_id, date, flag_status (`flagged`|`confirmed`|`waived`), confirmed_by
- `hrs_id_card_templates` — id, name, layout_json, is_default
- `hrs_pf_contribution_register` — id, compliance_record_id, month, year, basic_wage, emp_contribution, employer_epf, employer_eps, status
- `hrs_esi_contribution_register` — id, compliance_record_id, month, year, gross_wage, emp_contribution, employer_contribution, status
- `hrs_appraisal_increment_flags` — id, appraisal_id, employee_id, cycle_id, flag_status (`pending`|`processed`)
- `hrs_pt_slabs` — id, state_code, min_salary, max_salary, pt_amount (for profession tax computation)

---

### pay_* Tables (Payroll Layer — NEW in v2)

### 6.16 pay_salary_components
| Column | Type | Notes |
|---|---|---|
| name | VARCHAR(150) | e.g. Basic Pay, DA, HRA, PF Employee |
| code | VARCHAR(30) | UNIQUE — e.g. BASIC, DA, HRA, PF_EMP |
| component_type | ENUM | `earning`,`deduction`,`employer_contribution` |
| calculation_type | ENUM | `fixed`,`percentage_of_basic`,`percentage_of_gross`,`statutory`,`manual` |
| default_value | DECIMAL(10,4) | amount or percentage |
| is_taxable | TINYINT(1) | affects TDS computation |
| is_statutory | TINYINT(1) | PF, ESI, PT, TDS = 1 |
| display_order | TINYINT | order on payslip |

### 6.17 pay_salary_structures
| Column | Type | Notes |
|---|---|---|
| name | VARCHAR(200) | |
| description | TEXT | nullable |
| applicable_to | ENUM | `all`,`teaching`,`non_teaching`,`contractual` |
| is_active | TINYINT(1) | default 1 |

### 6.18 pay_salary_structure_components
| Column | Type | Notes |
|---|---|---|
| structure_id | BIGINT FK | → `pay_salary_structures.id` |
| component_id | BIGINT FK | → `pay_salary_components.id` |
| sequence_order | TINYINT | display order on payslip |
| calculation_formula | TEXT | nullable — overrides component default |
| is_mandatory | TINYINT(1) | |
| UNIQUE | | (structure_id, component_id) |

### 6.19 pay_payroll_runs
| Column | Type | Notes |
|---|---|---|
| payroll_month | VARCHAR(7) | YYYY-MM format |
| academic_year_id | BIGINT FK | → `sch_academic_years.id` |
| run_type | ENUM | `regular`,`supplementary` |
| parent_run_id | BIGINT FK | nullable → `pay_payroll_runs.id` (for supplementary) |
| status | ENUM | `draft`,`computing`,`computed`,`reviewing`,`approved`,`locked` |
| initiated_by | BIGINT FK | → `sch_employees.id` |
| approved_by | BIGINT FK | nullable → `sch_employees.id` |
| approved_at | TIMESTAMP | nullable |
| locked_at | TIMESTAMP | nullable |
| total_gross | DECIMAL(14,2) | computed aggregate |
| total_net | DECIMAL(14,2) | computed aggregate |
| employee_count | SMALLINT | |
| UNIQUE | | (payroll_month, run_type) for `regular` runs |

### 6.20 pay_payroll_run_details
| Column | Type | Notes |
|---|---|---|
| payroll_run_id | BIGINT FK | → `pay_payroll_runs.id` |
| employee_id | BIGINT FK | → `sch_employees.id` |
| salary_assignment_id | BIGINT FK | → `hrs_salary_assignments.id` |
| lop_days | DECIMAL(4,1) | from confirmed hrs_lop_records |
| gross_pay | DECIMAL(12,2) | |
| lwp_deduction | DECIMAL(12,2) | |
| pf_employee | DECIMAL(10,2) | |
| pf_employer | DECIMAL(10,2) | |
| esi_employee | DECIMAL(10,2) | |
| esi_employer | DECIMAL(10,2) | |
| tds_deducted | DECIMAL(10,2) | |
| pt_deduction | DECIMAL(8,2) | |
| other_deductions | DECIMAL(10,2) | |
| total_deductions | DECIMAL(12,2) | |
| net_pay | DECIMAL(12,2) | |
| computation_json | JSON | full per-component breakdown |
| payment_status | ENUM | `pending`,`exported`,`paid`,`failed` |
| is_override | TINYINT(1) | 1 if net_pay manually overridden |
| UNIQUE | | (payroll_run_id, employee_id) |

### 6.21 pay_payroll_overrides
| Column | Type | Notes |
|---|---|---|
| run_detail_id | BIGINT FK | → `pay_payroll_run_details.id` |
| field_name | VARCHAR(50) | e.g. `net_pay`, `tds_deducted` |
| original_value | DECIMAL(12,2) | |
| override_value | DECIMAL(12,2) | |
| reason | TEXT | mandatory |
| overridden_by | BIGINT FK | → `sch_employees.id` |

### 6.22 pay_payslips
| Column | Type | Notes |
|---|---|---|
| run_detail_id | BIGINT FK | → `pay_payroll_run_details.id` UNIQUE |
| employee_id | BIGINT FK | → `sch_employees.id` |
| payroll_month | VARCHAR(7) | YYYY-MM |
| media_id | BIGINT FK | → `sys_media.id` (generated PDF) |
| generated_at | TIMESTAMP | |
| email_status | ENUM | `not_sent`,`pending`,`sent`,`failed` |
| email_sent_at | TIMESTAMP | nullable |

### 6.23 pay_tds_ledger
| Column | Type | Notes |
|---|---|---|
| employee_id | BIGINT FK | → `sch_employees.id` |
| financial_year | VARCHAR(7) | YYYY-YY e.g. 2025-26 |
| month | TINYINT | 1–12 |
| gross_pay | DECIMAL(12,2) | for that month |
| tds_deducted | DECIMAL(10,2) | for that month |
| ytd_gross | DECIMAL(14,2) | year-to-date cumulative |
| ytd_tds | DECIMAL(12,2) | year-to-date cumulative |
| UNIQUE | | (employee_id, financial_year, month) |

### 6.24 pay_form16
| Column | Type | Notes |
|---|---|---|
| employee_id | BIGINT FK | → `sch_employees.id` |
| financial_year | VARCHAR(7) | YYYY-YY |
| media_id | BIGINT FK | → `sys_media.id` |
| generated_at | TIMESTAMP | |
| UNIQUE | | (employee_id, financial_year) |

### 6.25 pay_increment_policies
| Column | Type | Notes |
|---|---|---|
| name | VARCHAR(200) | |
| appraisal_cycle_id | BIGINT FK | → `hrs_appraisal_cycles.id` nullable |
| min_rating | DECIMAL(4,2) | overall_rating lower bound |
| max_rating | DECIMAL(4,2) | overall_rating upper bound |
| increment_type | ENUM | `percentage`,`flat` |
| increment_value | DECIMAL(8,2) | % or flat INR amount |

---

## 7. API and Routes

> Route file: `routes/tenant.php`  |  Route name prefix: `hr-staff.`  |  Middleware: `auth`, `tenant`, `permission`

### 7.1 Staff HR Records

| Method | URI | Name | Controller | FR |
|---|---|---|---|---|
| GET | `hr-staff/employees/{emp}/hr` | `hr-staff.employment.show` | EmploymentController@show | HRS-001 |
| POST | `hr-staff/employees/{emp}/hr` | `hr-staff.employment.store` | EmploymentController@store | HRS-001 |
| PUT | `hr-staff/employees/{emp}/hr` | `hr-staff.employment.update` | EmploymentController@update | HRS-001 |
| GET | `hr-staff/employees/{emp}/history` | `hr-staff.history.index` | EmploymentController@history | HRS-002 |
| GET | `hr-staff/employees/{emp}/documents` | `hr-staff.documents.index` | DocumentController@index | HRS-003 |
| POST | `hr-staff/employees/{emp}/documents` | `hr-staff.documents.store` | DocumentController@store | HRS-003 |
| DELETE | `hr-staff/documents/{doc}` | `hr-staff.documents.destroy` | DocumentController@destroy | HRS-003 |
| GET | `hr-staff/employees/{emp}/id-card` | `hr-staff.id-card.show` | IdCardController@show | HRS-004 |
| POST | `hr-staff/employees/{emp}/id-card/generate` | `hr-staff.id-card.generate` | IdCardController@generate | HRS-004 |

### 7.2 Leave Management

| Method | URI | Name | Controller | FR |
|---|---|---|---|---|
| GET/POST/PUT/DELETE | `hr-staff/leave-types/{id?}` | `hr-staff.leave-types.*` | LeaveTypeController | HRS-005 |
| GET/POST/PUT/DELETE | `hr-staff/holidays/{id?}` | `hr-staff.holidays.*` | HolidayController | HRS-006 |
| GET/PUT | `hr-staff/leave-policy` | `hr-staff.leave-policy.*` | LeaveController@policy | HRS-007 |
| POST | `hr-staff/leave-balances/initialize` | `hr-staff.balances.initialize` | LeaveController@initializeBalances | HRS-008 |
| GET | `hr-staff/leave-balances` | `hr-staff.balances.index` | LeaveController@balances | HRS-011 |
| GET/POST | `hr-staff/leave-applications/{id?}` | `hr-staff.applications.*` | LeaveApplicationController | HRS-009 |
| POST | `hr-staff/leave-applications/{app}/approve` | `hr-staff.applications.approve` | LeaveApplicationController@approve | HRS-010 |
| POST | `hr-staff/leave-applications/{app}/reject` | `hr-staff.applications.reject` | LeaveApplicationController@reject | HRS-010 |
| POST | `hr-staff/leave-applications/{app}/cancel` | `hr-staff.applications.cancel` | LeaveApplicationController@cancel | HRS-010 |
| GET | `hr-staff/lop-reconciliation` | `hr-staff.lop.index` | LopController@index | HRS-012 |
| POST | `hr-staff/lop-reconciliation/confirm` | `hr-staff.lop.confirm` | LopController@confirm | HRS-012 |

### 7.3 Salary Structures & Compliance

| Method | URI | Name | Controller | FR |
|---|---|---|---|---|
| GET/POST/PUT/DELETE | `hr-staff/pay-grades/{id?}` | `hr-staff.pay-grades.*` | PayGradeController | HRS-013 |
| GET/POST/PUT | `hr-staff/employees/{emp}/salary` | `hr-staff.salary.*` | SalaryAssignmentController | HRS-014 |
| GET/POST/PUT | `hr-staff/employees/{emp}/compliance/{type}` | `hr-staff.compliance.*` | ComplianceController | HRS-015–018 |
| GET | `hr-staff/compliance/pf-register` | `hr-staff.compliance.pf-register` | ComplianceController@pfRegister | HRS-015 |
| GET | `hr-staff/compliance/esi-register` | `hr-staff.compliance.esi-register` | ComplianceController@esiRegister | HRS-016 |
| GET/POST/PUT/DELETE | `hr-staff/salary-components/{id?}` | `hr-staff.salary-components.*` | SalaryComponentController | HRS-023 |
| GET/POST/PUT/DELETE | `hr-staff/salary-structures/{id?}` | `hr-staff.salary-structures.*` | SalaryStructureController | HRS-024 |
| GET | `hr-staff/salary-structures/{str}/preview` | `hr-staff.salary-structures.preview` | SalaryStructureController@preview | HRS-025 |

### 7.4 Appraisal

| Method | URI | Name | Controller | FR |
|---|---|---|---|---|
| GET/POST/PUT/DELETE | `hr-staff/kpi-templates/{id?}` | `hr-staff.kpi-templates.*` | AppraisalController | HRS-019 |
| GET/POST/PUT | `hr-staff/appraisal-cycles/{id?}` | `hr-staff.cycles.*` | AppraisalController | HRS-020 |
| GET/POST | `hr-staff/appraisals/{id?}` | `hr-staff.appraisals.*` | AppraisalController | HRS-021–022 |
| POST | `hr-staff/appraisals/{apr}/submit-self` | `hr-staff.appraisals.submit-self` | AppraisalController@submitSelf | HRS-021 |
| POST | `hr-staff/appraisals/{apr}/submit-review` | `hr-staff.appraisals.submit-review` | AppraisalController@submitReview | HRS-022 |
| POST | `hr-staff/appraisals/{apr}/finalize` | `hr-staff.appraisals.finalize` | AppraisalController@finalize | HRS-022 |

### 7.5 Payroll Runs

| Method | URI | Name | Controller | FR |
|---|---|---|---|---|
| GET | `hr-staff/payroll` | `hr-staff.payroll.index` | PayrollController@index | HRS-026 |
| POST | `hr-staff/payroll` | `hr-staff.payroll.store` | PayrollController@store | HRS-026 |
| GET | `hr-staff/payroll/{run}` | `hr-staff.payroll.show` | PayrollController@show | HRS-027 |
| POST | `hr-staff/payroll/{run}/compute` | `hr-staff.payroll.compute` | PayrollController@compute | HRS-027 |
| GET | `hr-staff/payroll/{run}/details` | `hr-staff.payroll.details` | PayrollController@details | HRS-028 |
| PUT | `hr-staff/payroll/{run}/details/{detail}/override` | `hr-staff.payroll.override` | PayrollController@override | HRS-028 |
| POST | `hr-staff/payroll/{run}/submit` | `hr-staff.payroll.submit` | PayrollController@submit | HRS-029 |
| POST | `hr-staff/payroll/{run}/approve` | `hr-staff.payroll.approve` | PayrollController@approve | HRS-029 |
| POST | `hr-staff/payroll/{run}/lock` | `hr-staff.payroll.lock` | PayrollController@lock | HRS-029 |

### 7.6 Payslips

| Method | URI | Name | Controller | FR |
|---|---|---|---|---|
| POST | `hr-staff/payroll/{run}/payslips/generate` | `hr-staff.payslips.generate` | PayslipController@generate | HRS-031 |
| POST | `hr-staff/payroll/{run}/payslips/generate-all` | `hr-staff.payslips.generate-all` | PayslipController@generateAll | HRS-032 |
| POST | `hr-staff/payroll/{run}/payslips/email-all` | `hr-staff.payslips.email-all` | PayslipController@emailAll | HRS-033 |
| GET | `hr-staff/payroll/{run}/payslips/download-zip` | `hr-staff.payslips.download-zip` | PayslipController@downloadZip | HRS-032 |
| GET | `hr-staff/my-payslips` | `hr-staff.my-payslips.index` | PayslipController@myPayslips | HRS-034 |
| GET | `hr-staff/my-payslips/{payslip}/download` | `hr-staff.my-payslips.download` | PayslipController@download | HRS-034 |

### 7.7 Bank & Statutory

| Method | URI | Name | Controller | FR |
|---|---|---|---|---|
| GET | `hr-staff/payroll/{run}/bank-file` | `hr-staff.payroll.bank-file` | PayrollController@bankFile | HRS-035 |
| POST | `hr-staff/payroll/{run}/mark-paid` | `hr-staff.payroll.mark-paid` | PayrollController@markPaid | HRS-036 |
| GET | `hr-staff/payroll/{run}/pf-ecr` | `hr-staff.payroll.pf-ecr` | StatutoryController@pfEcr | HRS-039 |
| GET | `hr-staff/payroll/{run}/esi-challan` | `hr-staff.payroll.esi-challan` | StatutoryController@esiChallan | HRS-040 |
| GET | `hr-staff/form16/{year}` | `hr-staff.form16.index` | Form16Controller@index | HRS-038 |
| POST | `hr-staff/form16/{year}/generate-all` | `hr-staff.form16.generate-all` | Form16Controller@generateAll | HRS-038 |
| GET | `hr-staff/my-form16/{year}/download` | `hr-staff.my-form16.download` | Form16Controller@download | HRS-038 |

### 7.8 Increment & Payroll Reports

| Method | URI | Name | Controller | FR |
|---|---|---|---|---|
| GET/POST | `hr-staff/increment-policies/{id?}` | `hr-staff.increment-policies.*` | IncrementController | HRS-041 |
| GET | `hr-staff/increments` | `hr-staff.increments.index` | IncrementController@index | HRS-041 |
| POST | `hr-staff/increments/process` | `hr-staff.increments.process` | IncrementController@process | HRS-041 |
| POST | `hr-staff/employees/{emp}/salary-revision` | `hr-staff.salary.revision` | SalaryAssignmentController@revision | HRS-042 |
| GET | `hr-staff/reports/salary-register` | `hr-staff.reports.salary-register` | PayrollReportController@salaryRegister | HRS-043 |
| GET | `hr-staff/reports/bank-summary` | `hr-staff.reports.bank-summary` | PayrollReportController@bankSummary | HRS-044 |
| GET | `hr-staff/reports/ctc-analysis` | `hr-staff.reports.ctc-analysis` | PayrollReportController@ctcAnalysis | HRS-045 |
| GET | `hr-staff/reports/payroll-trend` | `hr-staff.reports.payroll-trend` | PayrollReportController@trend | HRS-046 |

---

## 8. Business Rules

### 8.1 Leave Rules (unchanged from v1)

| Rule ID | Rule |
|---|---|
| BR-HRS-001 | Leave balance cannot go below 0 except for LWP type |
| BR-HRS-002 | Overlapping approved leave for same employee is rejected at validation |
| BR-HRS-003 | Carry-forward capped at `hrs_leave_types.carry_forward_days`; excess lapses at year end |
| BR-HRS-004 | Backdated leave applications allowed only within `hrs_leave_policies.max_backdated_days` |
| BR-HRS-005 | Medical certificate mandatory for SL > `medical_cert_threshold_days` |
| BR-HRS-006 | ML applicable only to female employees; PL only to male employees |
| BR-HRS-007 | Min service months enforced at application time (EL: 6 months default) |
| BR-HRS-008 | Cancellation of approved leave allowed only if `from_date > today`; balance restored |
| BR-HRS-009 | LOP confirmation is restricted to HR Manager only (financial impact) |

### 8.2 Salary & Compliance Rules

| Rule ID | Rule |
|---|---|
| BR-HRS-010 | Only one active salary assignment per employee at any time (enforced via `effective_to_date IS NULL`) |
| BR-HRS-011 | CTC must be within `hrs_pay_grades.min_ctc` and `max_ctc` for assigned pay grade |
| BR-HRS-012 | PF mandatory when `basic_salary ≤ ₹15,000`; voluntary otherwise |
| BR-HRS-013 | ESI mandatory when `gross_salary ≤ ₹21,000`; not applicable otherwise |
| BR-HRS-014 | Gratuity eligibility only after 5 years of continuous service from joining date |
| BR-HRS-015 | PAN and bank account number encrypted; never logged in plain text |

### 8.3 Payroll Rules (NEW in v2)

| Rule ID | Rule |
|---|---|
| BR-PAY-001 | Only one `regular` payroll run allowed per `payroll_month`; system blocks duplicate initiation |
| BR-PAY-002 | Payroll computation cannot start if any active employee lacks a valid salary assignment |
| BR-PAY-003 | **Locked payroll cannot be modified, re-processed, or deleted** — enforced at service layer |
| BR-PAY-004 | PF/ESI deduction is mandatory for all employees with `applicable_flag = true` — cannot be overridden per employee |
| BR-PAY-005 | Manual override of `net_pay` requires a mandatory `reason` text; logged in `pay_payroll_overrides` |
| BR-PAY-006 | TDS deducted cannot be less than 0 (no negative TDS month — shortfall recovered in next month) |
| BR-PAY-007 | Bank file export allowed only after payroll `status = approved`; blocked on `draft` or `computed` |
| BR-PAY-008 | Supplementary run must reference `parent_run_id` of the corresponding regular run for the same month |
| BR-PAY-009 | Form 16 generation allowed only after April 15 for the preceding financial year |
| BR-PAY-010 | LWP deduction = `(gross_monthly / working_days_in_month) × lop_days` where working_days is configured per school |
| BR-PAY-011 | Salary structure must include BASIC component — validation on structure save |
| BR-PAY-012 | Payslip re-generation (overwrite) allowed only for payroll in `approved` state; blocked after `locked` |

### 8.4 Appraisal Rules (unchanged from v1)

| Rule ID | Rule |
|---|---|
| BR-HRS-016 | KPI item weights within a template must sum exactly to 100 |
| BR-HRS-017 | Self-appraisal submission locks the form; HR Manager must explicitly unlock for re-edit |
| BR-HRS-018 | Manager review window cannot open before self-appraisal close date |
| BR-HRS-019 | Finalized appraisal cannot be modified; only HR Manager can reopen with audit log entry |
| BR-HRS-020 | HR Manager overall rating adjustment limited to ±10% of computed weighted average |

### 8.5 General Rules

| Rule ID | Rule |
|---|---|
| BR-HRS-021 | `emp_code` format: `EMP/YYYY/NNN` — auto-generated, unique within tenant, immutable |
| BR-HRS-022 | Employee document expiry reminders fire 30 days before `expiry_date` |
| BR-HRS-023 | Soft-delete only (`deleted_at` + `is_active=0`); permanent deletion not permitted |
| BR-HRS-024 | All approval/rejection actions require non-empty `remarks` field |

---

## 9. Workflow State Machines

### 9.1 Leave Application FSM (unchanged)

```
            [PENDING] ──── HOD rejects ──────────────► [REJECTED]
                │
                │ HOD approves (level 1)
                │ (if approval_levels = 1 → goes directly to APPROVED)
                ▼
        [PENDING_L2] ──── Principal rejects ──────► [REJECTED]
                │
                │ Principal approves (level 2)
                ▼
         [APPROVED] ──── Employee cancels ─────────► [CANCELLED]
                          (from_date > today)          (balance restored)

        ── HOD returns ──► [RETURNED] ── Employee resubmits ──► [PENDING]

Side effects:
  approved   → hrs_leave_balances.used_days += days_count
  cancelled  → hrs_leave_balances.used_days -= days_count
  All transitions → ntf_notifications + sys_activity_logs
```

### 9.2 Payroll Run FSM (v2 — fully internal)

```
Initiation:
  HR/Payroll Manager creates run → [DRAFT]

Computation:
  [DRAFT] ──── Compute triggered ──► [COMPUTING] ──── done ──► [COMPUTED]
  Preconditions checked before COMPUTING:
    ✓ All LOP records confirmed for payroll_month
    ✓ All active employees have valid salary assignment
    ✓ No existing regular run for this month in COMPUTED/APPROVED/LOCKED

Review & Override:
  [COMPUTED] ──── Payroll Manager reviews; manual overrides allowed ──► stays [COMPUTED]

Approval:
  [COMPUTED] ──── Submit for approval ──► [REVIEWING]
  [REVIEWING] ──── Principal approves ──► [APPROVED]
  [REVIEWING] ──── Principal rejects  ──► [COMPUTED] (back to computed for amendment)

Lock:
  [APPROVED] ──── Payroll Manager locks ──► [LOCKED]
  On LOCKED:
    → PayrollApproved event fired → Accounting module listener creates Journal Voucher
    → hrs_pf_contribution_register.status: computed → submitted
    → hrs_esi_contribution_register.status: computed → submitted

Post-Lock actions (allowed on LOCKED):
  → Bank file export (pay_payroll_run_details.payment_status: pending → exported)
  → Payslip generation and email distribution
  → PF ECR file export
  → ESI challan export
```

### 9.3 Appraisal FSM (unchanged)

```
Cycle: [DRAFT] → [ACTIVE] → [CLOSED]
Appraisal: [draft] → [submitted] → [reviewed] → [finalized]
On CLOSED: hrs_appraisal_increment_flags created for each finalized appraisal
On increment processed: flag_status → processed; new hrs_salary_assignments row created
```

---

## 10. Authorization and RBAC

### 10.1 Roles and Permissions

| Permission | HR Manager | Payroll Manager | Principal | HOD | Employee | Accountant |
|---|---|---|---|---|---|---|
| `hrs.employment.manage` | Yes | No | No | No | No | No |
| `hrs.documents.manage` | Yes | No | No | No | Own | No |
| `hrs.leave_type.manage` | Yes | No | No | No | No | No |
| `hrs.leave.apply` | Yes | No | No | No | Yes | No |
| `hrs.leave.approve_l1` | Yes | No | No | Yes | No | No |
| `hrs.leave.approve_l2` | Yes | No | Yes | No | No | No |
| `hrs.leave.balance.view` | Yes | No | Yes | Dept | Own | No |
| `hrs.lop.confirm` | Yes | No | No | No | No | No |
| `hrs.salary.manage` | Yes | Yes | No | No | No | Read |
| `hrs.compliance.manage` | Yes | Yes | No | No | No | Read |
| `hrs.appraisal.manage` | Yes | No | No | No | No | No |
| `hrs.appraisal.review` | Yes | No | Yes | Yes | No | No |
| `hrs.appraisal.self` | Yes | No | No | No | Yes | No |
| `hrs.idcard.generate` | Yes | No | No | No | Own | No |
| `pay.structure.manage` | Yes | Yes | No | No | No | Read |
| `pay.run.initiate` | No | Yes | No | No | No | No |
| `pay.run.compute` | No | Yes | No | No | No | No |
| `pay.run.approve` | No | No | Yes | No | No | No |
| `pay.run.lock` | No | Yes | No | No | No | No |
| `pay.payslip.generate` | No | Yes | No | No | No | No |
| `pay.payslip.own.download` | No | No | No | No | Yes | No |
| `pay.bank_file.export` | No | Yes | No | No | No | No |
| `pay.form16.generate` | No | Yes | No | No | No | No |
| `pay.form16.own.download` | No | No | No | No | Yes | No |
| `pay.report.view` | Yes | Yes | Yes | No | No | Yes |
| `pay.increment.process` | No | Yes | No | No | No | No |

### 10.2 Policy Classes (Proposed)

| Policy | Model | Key Checks |
|---|---|---|
| `EmploymentPolicy` | `EmploymentDetail` | `hrs.employment.manage` |
| `DocumentPolicy` | `EmployeeDocument` | Own employee or `hrs.documents.manage` |
| `LeaveTypePolicy` | `LeaveType` | `hrs.leave_type.manage` |
| `LeaveApplicationPolicy` | `LeaveApplication` | Own application or approver role |
| `LeaveBalancePolicy` | `LeaveBalance` | Own or `hrs.leave.balance.view` |
| `SalaryAssignmentPolicy` | `SalaryAssignment` | `hrs.salary.manage` or read-only accountant |
| `CompliancePolicy` | `ComplianceRecord` | `hrs.compliance.manage` or read-only accountant |
| `AppraisalCyclePolicy` | `AppraisalCycle` | `hrs.appraisal.manage` |
| `AppraisalPolicy` | `Appraisal` | Own (self) or reviewer or `hrs.appraisal.manage` |
| `SalaryStructurePolicy` | `SalaryStructure` | `pay.structure.manage` |
| `PayrollRunPolicy` | `PayrollRun` | Role-based per action (initiate/compute/approve/lock) |
| `PayslipPolicy` | `Payslip` | Own employee or `pay.payslip.generate` |
| `Form16Policy` | `Form16` | Own employee or `pay.form16.generate` |

---

## 11. Service Layer Architecture

### 11.1 Services

| Service | Responsibilities |
|---|---|
| `EmploymentService` | Create/update employment details, auto-generate `emp_code`, log history |
| `LeaveService` | Balance initialization, carry-forward, apply/cancel leave, LOP flagging |
| `LeaveApprovalService` | Route approval to correct level, dispatch notifications, update balances |
| `HolidayService` | Holiday calendar CRUD, compute working days between two dates |
| `SalaryAssignmentService` | Assign/revise salary structure, validate CTC within pay grade, maintain history |
| `ComplianceService` | PF/ESI/TDS/Gratuity/PT record management, generate contribution registers, export reports |
| `AppraisalService` | Cycle management, appraisal form routing, overall rating computation, increment flag creation |
| `IdCardService` | Generate ID card PDF via DomPDF, store in sys_media |
| `SalaryStructureService` | Salary component CRUD, structure template CRUD, CTC breakdown preview |
| `PayrollComputationService` | Core payroll engine: resolve assignments, compute gross/deductions/net per employee |
| `TdsComputationService` | Annual projected income, tax slab application, monthly TDS, Form 16 generation |
| `PayrollRunService` | Run lifecycle management (initiate → compute → approve → lock), supplementary runs |
| `PayslipService` | Single + bulk payslip PDF generation via DomPDF, email distribution, ZIP archive |
| `StatutoryExportService` | PF ECR file, ESI challan, bank NEFT file generation |
| `IncrementService` | Appraisal-linked variable pay proposals, ad-hoc salary revision processing |

### 11.2 Key Service Methods

**PayrollComputationService:**
- `computeRun(PayrollRun $run): void` — main engine: iterates employees, calls per-employee compute
- `computeEmployee(PayrollRun $run, Employee $emp): PayrollRunDetail`
- `recomputeEmployee(PayrollRunDetail $detail): PayrollRunDetail`

**TdsComputationService:**
- `computeMonthlyTds(Employee $emp, int $month, int $year): float`
- `getProjectedAnnualIncome(Employee $emp, string $financialYear): float`
- `generateForm16(Employee $emp, string $financialYear): BinaryFileResponse`

**PayslipService:**
- `generate(PayrollRunDetail $detail): Payslip`
- `generateAllForRun(PayrollRun $run): void` — dispatches `GeneratePayslipsJob`
- `getPasswordForEmployee(Employee $emp): string` — `PANlast4 + DDYYYY(DOB)`
- `emailPayslip(Payslip $payslip): void`

**StatutoryExportService:**
- `exportBankFile(PayrollRun $run, string $format): BinaryFileResponse`
- `exportPfEcr(PayrollRun $run): BinaryFileResponse`
- `exportEsiChallan(PayrollRun $run): BinaryFileResponse`

**LeaveService:**
- `initializeBalances(int $academicYearId): void`
- `calculateDays(int $leaveTypeId, Carbon $from, Carbon $to, bool $halfDay): float`
- `applyLeave(array $data, int $employeeId): LeaveApplication`
- `cancelLeave(int $applicationId): bool`
- `runLopReconciliation(Carbon $month): Collection`

---

## 12. Integration Points

### 12.1 Inbound Integrations (HrStaff reads from)

| Source Module | Table/Event | Purpose | Access Type |
|---|---|---|---|
| SchoolSetup (`sch_*`) | `sch_employees`, `sch_employee_profiles` | Employee base record | Read + extend |
| SchoolSetup (`sch_*`) | `sch_departments`, `sch_designations` | Department/designation reference | Read-only |
| SchoolSetup (`sch_*`) | `sch_academic_years` | Leave balance and payroll year scoping | Read-only |
| Attendance (`att_*`) | `att_staff_attendances` | LOP reconciliation | Read-only |
| System (`sys_*`) | `sys_media` | Document and payslip/ID card file storage | Read + write |
| System (`sys_*`) | `sys_activity_logs` | Audit trail | Write-only |

### 12.2 Outbound Integrations (HrStaff provides to)

| Consumer Module | Table/Event | Data Provided |
|---|---|---|
| Accounting (`acc_*`) | `PayrollApproved` event | Triggers Journal Voucher creation for salary expense |
| Accounting (`acc_*`) | Gratuity computed amount on exit | Disbursement input via event |
| Notification (`ntf_*`) | `ntf_notifications` dispatch | Leave approved/rejected, document expiry, payslip email |

> **v2 change:** No outbound integrations to any `prl_*` module — payroll is fully internal.

### 12.3 Event Contracts

| Event | Fired By | Listener | Action |
|---|---|---|---|
| `LeaveApproved` | LeaveApprovalService | NotificationService | Employee notification |
| `LeaveRejected` | LeaveApprovalService | NotificationService | Employee notification |
| `DocumentExpiringSoon` | Scheduled command | HrStaff | HR Manager notification |
| `AppraisalFinalized` | AppraisalService | IncrementService | Create increment flag |
| `PayrollApproved` | PayrollRunService | Accounting module | Create Payroll Journal Voucher |
| `PayrollLocked` | PayrollRunService | StatutoryExportService | Update PF/ESI register status |

---

## 13. UI/UX Requirements

### 13.1 Key Screens

| Screen | Route Name | Description |
|---|---|---|
| Employee HR Profile | `hr-staff.employment.show` | Tabbed: Employment Details / Documents / Compliance / History |
| Leave Type List | `hr-staff.leave-types.index` | CRUD grid with enable/disable toggle |
| Holiday Calendar | `hr-staff.holidays.index` | Month-view calendar with add/edit modal |
| Leave Balance Dashboard | `hr-staff.balances.index` | Matrix table (employee × leave type) with dept filter |
| Leave Application Form | `hr-staff.applications.create` | Date range picker, auto-calculated days, balance preview |
| Pending Approvals | `hr-staff.applications.pending` | Tabbed: My Pending / All Pending (HR Manager) |
| LOP Reconciliation | `hr-staff.lop.index` | Month selector, table with flag/confirm/waive actions |
| Salary Component Master | `hr-staff.salary-components.index` | CRUD grid: components with type/calculation badges |
| Salary Structure List | `hr-staff.salary-structures.index` | CRUD grid; click → component composition |
| Salary Structure Builder | `hr-staff.salary-structures.edit` | Drag-and-drop component sequence; live CTC preview |
| Salary Assignment | `hr-staff.salary.edit` | Current structure card + revision history timeline |
| Compliance Dashboard | `hr-staff.compliance.index` | Employee list with PF/ESI/TDS/PT status badges |
| Appraisal Cycle Dashboard | `hr-staff.cycles.index` | Cycle cards with completion progress bars |
| Self-Appraisal Form | `hr-staff.appraisals.self` | KPI grid with rating sliders and comment fields |
| Manager Review Form | `hr-staff.appraisals.review` | Side-by-side self vs manager rating per KPI |
| ID Card Preview | `hr-staff.id-card.show` | Rendered card preview with Generate PDF button |
| Payroll Dashboard | `hr-staff.payroll.index` | Run history cards; initiate new run button |
| Payroll Run Detail | `hr-staff.payroll.show` | Status timeline; employee-wise computation table; totals |
| Payroll Review Grid | `hr-staff.payroll.details` | Sortable/filterable table; override button per row |
| Payslip List | `hr-staff.payslips.index` | Employee × month grid with generate/email/download actions |
| My Payslips | `hr-staff.my-payslips.index` | Employee self-service: list of downloadable payslips |
| Form 16 Management | `hr-staff.form16.index` | Financial year selector; generate all; download per employee |
| Salary Register Report | `hr-staff.reports.salary-register` | Filterable table; PDF + Excel export |
| Payroll Trend | `hr-staff.reports.payroll-trend` | Line chart (12 months); department drilldown |
| Increment Processing | `hr-staff.increments.index` | Appraisal cycle selector; proposed increments table; approve bulk |

### 13.2 UX Standards

- All forms use AJAX validation (no full-page reload on error).
- Leave application: days-count updates live on date range change.
- Payroll run: computation progress shown via polling (every 3 seconds for large runs).
- Payslip generation bulk: progress bar showing `X of N generated`.
- Salary structure builder: live CTC breakdown table updates as components are added/reordered.
- Compliance dashboard: red badge if PF/ESI not enrolled for applicable employee.
- Document list: expiry date color-coded (green > 90 days, amber 30–90 days, red < 30 days).
- Payroll review grid: orange highlight rows where `is_override = true`.
- All tables: pagination (25/50/100), search, column sort, CSV/Excel export.

---

## 14. Test Coverage

### 14.1 Feature Tests (Pest)

| Test File | Tests | Key Scenarios |
|---|---|---|
| `LeaveApplicationTest` | 8 | Apply leave, balance check, overlap rejection, half-day, cancel |
| `LeaveApprovalTest` | 6 | L1 approve, L2 approve, reject, return, balance update on approve/cancel |
| `LeaveBalanceTest` | 5 | Initialize balances, carry-forward cap, manual adjustment, year-end lapse |
| `LopReconciliationTest` | 4 | Flag absent without leave, confirm LOP, waive LOP, month-close lock |
| `SalaryAssignmentTest` | 4 | Assign structure, CTC out of range rejection, revision history |
| `ComplianceRecordTest` | 5 | PF enrollment, ESI enrollment, TDS declaration, PT slab, gratuity calc |
| `AppraisalTest` | 6 | Cycle creation, self-submit, reviewer submit, finalize, weight validation, increment flag |
| `SalaryStructureTest` | 5 | Create structure, add components, CTC preview, missing BASIC rejection, duplicate component |
| `PayrollRunTest` | 8 | Initiate run, pre-condition check, compute, override, approve, lock, duplicate run blocked, locked run immutable |
| `PayslipGenerationTest` | 5 | Single generate, bulk generate, email dispatch, password check, re-generate blocked after lock |
| `TdsComputationTest` | 6 | Old regime, new regime, mid-year regime change, Dec-Mar recompute, negative TDS floor |
| `Form16Test` | 3 | Generate Form 16, employee download, blocked before April 15 |
| `BankFileTest` | 3 | Export CSV, export TXT, blocked before approved status |
| `PfEcrTest` | 3 | ECR format, UAN validation, sum-check |
| `IncrementProcessingTest` | 4 | Policy-based increment, ad-hoc revision, effective date enforcement, flag marked processed |

### 14.2 Unit Tests (PHPUnit)

| Test File | Tests | Key Scenarios |
|---|---|---|
| `LeaveDayCalculatorTest` | 5 | Weekends excluded, holidays excluded, half-day = 0.5, cross-month range |
| `GratuityCalculatorTest` | 3 | Standard calc, 5-year threshold enforcement, partial year rounding |
| `AppraisalRatingCalculatorTest` | 4 | Weighted average, weight sum validation, ±10% HR tolerance |
| `EmpCodeGeneratorTest` | 3 | Unique code, format regex, year extraction |
| `PayrollComputationUnitTest` | 8 | Gross calculation, LWP formula, PF formula, ESI formula, PT slab, TDS monthly, net pay, override detection |
| `TdsProjectionTest` | 5 | Projected income calc, 80C cap, HRA exemption, remaining months division, year-end adjustment |
| `PayslipPasswordTest` | 2 | Password format validation, special chars in PAN |

### 14.3 Test Data Strategy

- Seeders: `HrsLeaveTypeSeeder`, `HrsHolidayCalendarSeeder`, `PaySalaryComponentSeeder` (standard components), `PaySalaryStructureSeeder`
- Factories: `EmploymentDetailFactory`, `LeaveApplicationFactory`, `AppraisalFactory`, `PayrollRunFactory`, `PayrollRunDetailFactory`
- RefreshDatabase on all Feature tests
- `att_staff_attendances` mocked for LOP reconciliation tests
- Payroll tests use in-memory factories; no real queue dispatch (fake queue)

---

## 15. Implementation Priorities

### Phase 1 — HR Foundation (Sprint 1–2)

| FR | Feature | Effort |
|---|---|---|
| HRS-001 | Employee HR details extension | M |
| HRS-003 | Document repository | M |
| HRS-005 | Leave type master | S |
| HRS-006 | Holiday calendar | S |
| HRS-008 | Leave balance initialization | M |
| HRS-009 | Leave application | M |
| HRS-010 | Leave approval workflow (2-level) | L |
| HRS-011 | Leave balance dashboard | S |

### Phase 2 — Compliance & Payroll Prep (Sprint 3–4)

| FR | Feature | Effort |
|---|---|---|
| HRS-012 | LOP reconciliation | M |
| HRS-013 | Pay grade master | S |
| HRS-015 | PF compliance records | M |
| HRS-016 | ESI compliance records | M |
| HRS-017 | TDS declaration storage | S |
| HRS-018 | Gratuity records | S |
| HRS-023 | Salary component master | M |
| HRS-024 | Salary structure templates | M |
| HRS-014 | Employee salary assignment | M |
| HRS-025 | CTC breakdown preview | S |
| HRS-004 | Staff ID card generation | M |

### Phase 3 — Payroll Engine (Sprint 5–6)

| FR | Feature | Effort |
|---|---|---|
| HRS-026 | Payroll run initiation | M |
| HRS-027 | Payroll computation engine | XL |
| HRS-028 | Payroll review and amendment | M |
| HRS-029 | Payroll approval and lock | M |
| HRS-037 | TDS monthly computation | L |
| HRS-030 | Supplementary payroll run | M |

### Phase 4 — Payslip, Statutory & Distribution (Sprint 7–8)

| FR | Feature | Effort |
|---|---|---|
| HRS-031 | Individual payslip generation | M |
| HRS-032 | Bulk payslip generation | M |
| HRS-033 | Payslip email distribution | M |
| HRS-034 | Employee self-service payslip download | S |
| HRS-035 | Bank NEFT file export | M |
| HRS-036 | Payment status tracking | S |
| HRS-039 | PF ECR file generation | M |
| HRS-040 | ESI challan export | S |

### Phase 5 — Form 16, Increments & Reports (Sprint 9–10)

| FR | Feature | Effort |
|---|---|---|
| HRS-038 | Form 16 generation | L |
| HRS-041 | Appraisal-linked variable pay | L |
| HRS-042 | Ad-hoc salary revision | M |
| HRS-043 | Monthly salary register | M |
| HRS-044 | Bank transfer summary | S |
| HRS-045 | CTC vs gross vs net analysis | M |
| HRS-046 | Payroll trend report | M |

### Phase 6 — Appraisal (Sprint 11–12)

| FR | Feature | Effort |
|---|---|---|
| HRS-019 | KPI template management | M |
| HRS-020 | Appraisal cycle configuration | M |
| HRS-021 | Self-appraisal submission | M |
| HRS-022 | Manager review and finalization | L |
| HRS-002 | Employment history log | S |
| HRS-007 | Leave policy configuration | S |

**Effort Key:** S = 1–2 days | M = 3–5 days | L = 6–8 days | XL = 8–12 days

---

## 16. Open Questions and Decisions

| # | Question | Options | Recommended |
|---|---|---|---|
| OQ-001 | Should `emp_code` be generated by HrStaff or SchoolSetup? | A: SchoolSetup on `sch_employees` creation; B: HrStaff on HR onboarding | **A** — generate in SchoolSetup so always available |
| OQ-002 | Bank account encryption: `encrypt()` or AES-256 custom? | A: Laravel `encrypt()` (APP_KEY); B: AES-256 custom key | **A** — simpler, Laravel convention |
| OQ-003 | PF/ESI register auto-compute or HR-triggered? | A: Scheduled (1st of month); B: HR triggers | **A** — reduces manual work; HR can re-trigger |
| OQ-004 | Holiday calendar: HrStaff-owned or shared `sch_*` table? | A: `hrs_holiday_calendars`; B: Shared `sch_holiday_calendars` | **B preferred** — Timetable + Attendance also need holidays |
| OQ-005 | Gratuity disbursement: event to Accounting or direct write? | A: Fire event, Accounting listens; B: Direct `acc_*` write | **A** — loose coupling |
| OQ-006 | LOP confirmation: HR Manager only or HOD can confirm for dept? | A: HR Manager only; B: HOD for their dept | **A** — financial impact, restrict to HR Manager |
| OQ-007 | ID card template: single global or per-school? | A: Single default; B: `hrs_id_card_templates` per-school | **B** — per-school branding is real need |
| OQ-008 | Leave: can HR Manager apply on behalf of employee? | A: Yes, with `applied_on_behalf_of` flag; B: Self-service only | **A** — needed for offline/verbal requests |
| OQ-009 | Payroll computation: synchronous or always queued? | A: Sync ≤100 employees; B: Always queued | **A** — sync for small schools is fine; queue for large |
| OQ-010 | Payroll role: separate `Payroll Manager` role or extend `HR Manager`? | A: Separate role; B: HR Manager handles payroll | **A** — schools often have separate payroll staff; fine-grained permissions |
| OQ-011 | TDS: should system support mid-year tax regime change? | A: Yes (update regime, recompute future months); B: Regime locked for financial year | **A** — employees can switch regime; allowed by IT Act |
| OQ-012 | Bank file format: generic CSV or bank-specific? | A: Generic CSV only; B: Bank-specific (SBI/HDFC/ICICI); C: Both | **B** — schools typically upload to specific bank portal; configurable per school |
| OQ-013 | Payslip password: PAN last 4 + DOB or configurable? | A: Fixed format (PAN4 + DDYYYY); B: HR-configurable | **A** — industry standard; no configuration overhead |

---

*Document ends.*
*Total FRs: 46 (HRS-001 to HRS-046).*
*HR FRs: HRS-001 to HRS-022 (unchanged from v1).*
*Payroll FRs (NEW in v2): HRS-023 to HRS-046.*
*All items 📐 Proposed. All FR status ❌ Not Started.*
*V2 Key Change: Payroll merged from separate module into HrStaff. Table prefix `pay_*` retained for payroll tables within the same module.*
