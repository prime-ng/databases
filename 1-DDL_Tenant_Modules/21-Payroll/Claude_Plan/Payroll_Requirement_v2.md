# Payroll Module — Detailed Requirement Document v2

**Module:** Payroll | **Laravel Module:** `Modules/Payroll/` | **Prefix:** `prl_`
**Database:** tenant_db (dedicated per tenant — no tenant_id needed)
**Route:** `/payroll/*` | **RBS Module:** P — HR & Staff Management (46 sub-tasks)
**Date:** 2026-03-19 | **Version:** 2.0

**Changes from v1:** Separate module (not inside Accounting), `prl_` prefix for all payroll tables, `sch_employees` reused (not `acc_employees`), `sch_leave_types` and `sch_leave_config` confirmed as existing, no tenant_id, `sch_employee_groups` and `sch_employee_attendance` use `sch_` prefix

---

## 1. Module Overview & Purpose

The Payroll module is a **separate Laravel module** (`Modules/Payroll/`) that manages **Indian school staff salary processing** — from pay head definitions and salary structures through monthly payroll computation to payslip generation. It connects to the **Accounting module** via `VoucherServiceInterface` to post payroll journal vouchers.

**Core Principle:** Payroll is an **independent module** with its own controllers, models, routes, and views. It consumes the Accounting module's voucher engine — it does NOT own the voucher tables.

**Indian School Payroll Context:**
- Statutory deductions: PF (12%+12%), ESI (0.75%+3.25%), Professional Tax (state-wise), TDS (income tax)
- CTC structure: Basic + DA + HRA + Conveyance + Special Allowance + Bonus
- Financial year: April–March; payroll runs monthly
- Teachers and non-teaching staff have different pay structures and statutory applicability
- Attendance-based LOP (Loss of Pay) deduction
- Employer contributions (PF, ESI) tracked separately — not deducted from employee salary

**Relationship to Other Modules:**
- **SchoolSetup:** Reuses `sch_employees`, `sch_teachers`, `sch_departments`, `sch_designations`, `sch_leave_types`, `sch_leave_config` — NOT duplicated
- **Accounting:** Payroll run creates a Payroll Journal Voucher via `VoucherServiceInterface`
- The existing `sch_employees` table is enhanced with payroll-specific columns (bank details, salary structure FK, statutory IDs) — NOT replaced

**Multi-Tenancy:**
- Dedicated database per tenant — NO `tenant_id` column in any table
- Pay heads and salary structures seeded during tenant provisioning

---

## 2. Scope & Boundaries

### In Scope
- Pay heads (earnings, deductions, employer contributions) — prefix `prl_`
- Salary structure templates (pay grade → pay head mapping) — prefix `prl_`
- Monthly payroll run (compute → review → approve → post) — prefix `prl_`
- Payslip generation (PDF via DomPDF)
- Statutory calculations (PF, ESI, PT, TDS)
- Leave application & balance tracking — prefix `prl_`
- Daily attendance logs — prefix `prl_`
- Statutory configuration — prefix `prl_`
- Performance appraisal (KPI templates, cycles, scoring) — prefix `prl_`
- Staff training management — prefix `prl_`
- Expense claims (staff reimbursement) — handled by Accounting module
- HR reports (salary register, PF report, department-wise summary)

### Out of Scope (Handled by Other Modules)
- Employee profile creation (personal details, qualifications) → **SchoolSetup** (`sch_employees`)
- Teacher-specific data (subjects, capabilities) → **SchoolSetup** (`sch_teachers`)
- Department/Designation CRUD → **SchoolSetup** (`sch_departments`, `sch_designations`)
- Leave type master → **SchoolSetup** (`sch_leave_types`) — **EXISTING, reused**
- Leave configuration → **SchoolSetup** (`sch_leave_config`) — **EXISTING, reused**
- Voucher engine (double-entry bookkeeping) → **Accounting** (`acc_vouchers`, `acc_voucher_items`)
- Expense claim management → **Accounting** (`acc_expense_claims`)
- Biometric device hardware integration → Stubbed (manual attendance for now)

---

## 3. RBS Mapping (Module P — 46 Sub-Tasks)

### P1 — Staff Master & HR Records (9 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P1.1.1.1 | Enter personal details | `sch_employees` (existing SchoolSetup) | Done |
| ST.P1.1.1.2 | Upload documents (ID, certificates) | Spatie Media on `sch_employees` | Done |
| ST.P1.1.1.3 | Assign employee code | `sch_employees.emp_code` | Done |
| ST.P1.1.2.1 | Update contact details | `sch_employees` edit | Done |
| ST.P1.1.2.2 | Manage emergency contacts | `sch_employees_profile` | Done |
| ST.P1.2.1.1 | Define designation & department | `sch_employees_profile.department_id`, `role_id` | Done |
| ST.P1.2.1.2 | Set joining date & contract type | `sch_employees.joining_date` | Done |
| ST.P1.2.2.1 | Upload appointment letter | Spatie Media on `sch_employees` | Done |
| ST.P1.2.2.2 | Track document renewal dates | Future: document renewal alert system | Pending |

### P2 — Staff Attendance & Leave (7 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P2.1.1.1 | Select leave type | `prl_leave_applications.leave_type_id` FK → **sch_leave_types** (existing) | New |
| ST.P2.1.1.2 | Submit leave request | `prl_leave_applications.status` = 'Submitted' | New |
| ST.P2.1.1.3 | Attach supporting document | Spatie Media on `prl_leave_applications` | New |
| ST.P2.1.2.1 | Approve/Reject leave | `prl_leave_applications.status` workflow | New |
| ST.P2.1.2.2 | Record remarks with history | `prl_leave_applications.reviewer_remarks` + activity log | New |
| ST.P2.2.1.1 | Fetch logs from biometric device | `prl_attendance_logs` (manual entry, biometric stubbed) | Stub |
| ST.P2.2.1.2 | Auto-mark attendance | AttendanceSyncService (biometric sync) | Stub |

### P3 — Payroll Preparation (8 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P3.1.1.1 | Add earnings & deductions | `prl_pay_heads` (type: earning/deduction/employer) | New |
| ST.P3.1.1.2 | Assign pay grade | `prl_salary_structures` + `prl_salary_structure_items` | New |
| ST.P3.1.2.1 | Auto-calculate components | PayrollComputeService (percentage-based calc) | New |
| ST.P3.1.2.2 | Record employer contributions | `prl_pay_heads` with type='employer_contribution' | New |
| ST.P3.2.1.1 | Calculate earnings & deductions | PayrollComputeService.processPayroll() | New |
| ST.P3.2.1.2 | Apply LOP for absences | LOP = (monthly_salary / total_working_days) * absent_days | New |
| ST.P3.2.2.1 | Add ad-hoc allowances | `prl_payroll_entries.adhoc_earnings_json` | New |
| ST.P3.2.2.2 | Apply manual deductions | `prl_payroll_entries.adhoc_deductions_json` | New |

### P4 — Compliance & Statutory Management (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P4.1.1.1 | Enable PF/ESI applicability | `sch_employee_groups.is_pf_applicable`, `is_esi_applicable` | New |
| ST.P4.1.1.2 | Record employee PF details | `prl_employee_statutory_details.pf_number`, `uan` | New |
| ST.P4.1.2.1 | PF report | PrlReportService.pfReport() | New |
| ST.P4.1.2.2 | ESI contribution report | PrlReportService.esiReport() | New |

### P5 — Performance Appraisal (8 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P5.1.1.1 | Add KPI categories | `prl_appraisal_templates` + `prl_appraisal_template_kpis_jnt` | New |
| ST.P5.1.1.2 | Set weightage for each KPI | `prl_appraisal_template_kpis_jnt.weightage` | New |
| ST.P5.1.2.1 | Set appraisal period | `prl_appraisal_cycles` (start_date, end_date) | New |
| ST.P5.1.2.2 | Assign reviewer | `prl_appraisals.reviewer_id` FK | New |
| ST.P5.2.1.1 | Staff fills self-assessment | `prl_appraisal_scores.self_score` | New |
| ST.P5.2.1.2 | Attach proofs | Spatie Media on `prl_appraisals` | New |
| ST.P5.2.2.1 | Score KPIs | `prl_appraisal_scores.reviewer_score` | New |
| ST.P5.2.2.2 | Provide final rating | `prl_appraisals.final_rating` | New |

### P6 — Staff Training & Development (6 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P6.1.1.1 | Set topic & trainer | `prl_training_programs.title`, `trainer_name` | New |
| ST.P6.1.1.2 | Define training schedule | `prl_training_programs.start_date`, `end_date` | New |
| ST.P6.1.2.1 | Add staff to training | `prl_training_enrollments_jnt` | New |
| ST.P6.1.2.2 | Notify participants | Notification module integration | Phase 2 |
| ST.P6.2.1.1 | Receive training feedback | `prl_training_enrollments_jnt.feedback_text`, `feedback_rating` | New |
| ST.P6.2.1.2 | Generate evaluation report | PrlReportService.trainingReport() | New |

### P7 — HR Reports & Analytics (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P7.1.1.1 | Staff register | PrlReportService.staffRegister() (from sch_employees) | New |
| ST.P7.1.1.2 | Department-wise strength report | PrlReportService.departmentStrength() | New |
| ST.P7.2.1.1 | Attrition rate analysis | Computed from employee records | New |
| ST.P7.2.1.2 | Leave trend analysis | PrlReportService.leaveTrend() | New |

---

## 4. Entity List (Tables & Columns)

### Existing Tables REUSED (from SchoolSetup — NOT duplicated)

| Table | Used For | Status |
|-------|----------|--------|
| `sch_employees` | Employee master (personal, qualifications, joining_date) | Existing — **enhance with payroll columns** |
| `sch_employees_profile` | Role, department, reporting_to, skills | Existing — no changes |
| `sch_teachers` | Teacher-specific (max_periods, subjects) | Existing — no changes |
| `sch_teacher_profiles` | Teaching profile details | Existing — no changes |
| `sch_departments` | Department reference | Existing — no changes |
| `sch_designations` | Designation reference | Existing — no changes |
| `sch_leave_types` | Leave type master (CL, EL, SL, etc.) | **Existing in tenant_db** — no changes |
| `sch_leave_config` | Leave quota per staff category per leave type | **Existing in tenant_db** — no changes |

### Enhancement to `sch_employees` (ALTER TABLE — NOT new table)

| New Column | Type | Description |
|------------|------|-------------|
| ledger_id | BIGINT UNSIGNED NULL FK | FK → acc_ledgers (auto-created salary payable ledger) |
| salary_structure_id | BIGINT UNSIGNED NULL FK | FK → prl_salary_structures |
| employee_group_id | BIGINT UNSIGNED NULL FK | FK → sch_employee_groups |
| bank_name | VARCHAR(100) NULL | Salary disbursement bank |
| bank_account_number | VARCHAR(50) NULL | Bank account number |
| bank_ifsc | VARCHAR(20) NULL | IFSC code |
| pf_number | VARCHAR(30) NULL | PF account number |
| esi_number | VARCHAR(30) NULL | ESI number |
| uan | VARCHAR(20) NULL | Universal Account Number |
| pan | VARCHAR(15) NULL | PAN card number |
| ctc_monthly | DECIMAL(15,2) NULL | Monthly CTC amount |
| date_of_leaving | DATE NULL | Relieving date |

> **Note:** Migration must use `Schema::hasColumn()` guard — some columns may already exist.

### Enhancement/New: `sch_employee_groups` (prefix `sch_` per user decision)

| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(100) | e.g., "Teaching Staff", "Non-Teaching Staff" |
| parent_id | BIGINT UNSIGNED NULL | Self-referencing hierarchy |
| is_pf_applicable | TINYINT(1) | PF deduction applies |
| is_esi_applicable | TINYINT(1) | ESI deduction applies |
| is_pt_applicable | TINYINT(1) | Professional Tax applies |
| is_system | TINYINT(1) | Cannot delete seeded groups |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### Enhancement/New: `sch_employee_attendance` (prefix `sch_` per user decision)

| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| employee_id | BIGINT UNSIGNED FK | FK → sch_employees |
| month | TINYINT | 1-12 |
| year | SMALLINT | e.g., 2026 |
| total_days | TINYINT | Total working days in month |
| present_days | DECIMAL(4,1) | Days present (half-day = 0.5) |
| lwp_days | DECIMAL(4,1) | Leave Without Pay days |
| overtime_hours | DECIMAL(5,1) NULL | Overtime hours |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |
| UNIQUE | (employee_id, month, year) | One record per month |

---

### New Tables — Payroll Core (prefix `prl_`)

#### 4.1 prl_pay_heads
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(100) | e.g., "Basic Salary", "HRA", "PF Employee" |
| code | VARCHAR(20) UNIQUE | PAY_BASIC, PAY_HRA, DED_PF, etc. |
| type | ENUM('earning','deduction','employer_contribution') | Pay head category |
| calculation_type | ENUM('flat_amount','percentage','on_attendance','computed') | How to calculate |
| percentage_of | VARCHAR(50) NULL | e.g., "basic", "basic_da", "gross" |
| default_percentage | DECIMAL(5,2) NULL | Default % value |
| default_amount | DECIMAL(15,2) NULL | Default flat amount |
| statutory_type | ENUM('pf','esi','pt','tds') NULL | Statutory linkage |
| is_taxable | TINYINT(1) | Subject to income tax |
| is_statutory | TINYINT(1) | Government-mandated |
| ledger_id | BIGINT UNSIGNED NULL FK | FK → acc_ledgers (expense/liability ledger in Accounting) |
| sequence | INT | Display order on payslip |
| is_system | TINYINT(1) | Cannot delete seeded records |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

#### 4.2 prl_salary_structures
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(100) | e.g., "Teaching Staff Grade A" |
| code | VARCHAR(20) UNIQUE | Structure code |
| description | TEXT NULL | Description |
| effective_from | DATE | Structure validity start |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

#### 4.3 prl_salary_structure_items
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| salary_structure_id | BIGINT UNSIGNED FK | FK → prl_salary_structures (CASCADE) |
| pay_head_id | BIGINT UNSIGNED FK | FK → prl_pay_heads |
| amount | DECIMAL(15,2) NULL | Fixed amount (overrides pay_head default) |
| percentage | DECIMAL(5,2) NULL | Percentage (overrides pay_head default) |
| is_mandatory | TINYINT(1) | Cannot remove from employee |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

#### 4.4 prl_payroll_runs
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| month | TINYINT | Payroll month (1-12) |
| year | SMALLINT | Payroll year |
| financial_year_id | BIGINT UNSIGNED FK | FK → acc_financial_years (from Accounting) |
| status | ENUM('draft','processing','computed','approved','posted','locked') | Run status |
| total_employees | INT | Count of employees processed |
| total_gross | DECIMAL(15,2) | Sum of all gross salaries |
| total_deductions | DECIMAL(15,2) | Sum of all deductions |
| total_net | DECIMAL(15,2) | Sum of all net salaries |
| total_employer_pf | DECIMAL(15,2) | Employer PF contribution |
| total_employer_esi | DECIMAL(15,2) | Employer ESI contribution |
| voucher_id | BIGINT UNSIGNED NULL FK | FK → acc_vouchers (created on posting to Accounting) |
| processed_by | BIGINT UNSIGNED NULL | FK → sys_users |
| approved_by | BIGINT UNSIGNED NULL | FK → sys_users |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |
| UNIQUE | (month, year) | One run per month |

#### 4.5 prl_payroll_entries
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| payroll_run_id | BIGINT UNSIGNED FK | FK → prl_payroll_runs (CASCADE) |
| employee_id | BIGINT UNSIGNED FK | FK → sch_employees (existing table) |
| gross_salary | DECIMAL(15,2) | Total earnings |
| total_earnings | DECIMAL(15,2) | Sum of earning pay heads |
| total_deductions | DECIMAL(15,2) | Sum of deduction pay heads |
| net_salary | DECIMAL(15,2) | Take-home pay |
| lop_days | DECIMAL(4,1) | Loss of Pay days |
| lop_amount | DECIMAL(15,2) | LOP deduction amount |
| pf_employee | DECIMAL(15,2) | Employee PF |
| pf_employer | DECIMAL(15,2) | Employer PF |
| esi_employee | DECIMAL(15,2) | Employee ESI |
| esi_employer | DECIMAL(15,2) | Employer ESI |
| pt_amount | DECIMAL(15,2) | Professional Tax |
| tds_amount | DECIMAL(15,2) | TDS deducted |
| adhoc_earnings_json | JSON NULL | Ad-hoc bonuses/allowances |
| adhoc_deductions_json | JSON NULL | Ad-hoc deductions/recoveries |
| earnings_breakdown_json | JSON | Detailed earning pay heads |
| deductions_breakdown_json | JSON | Detailed deduction pay heads |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

---

### New Tables — HR Extensions (prefix `prl_`)

#### 4.6 prl_leave_applications
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| employee_id | BIGINT UNSIGNED FK | FK → sch_employees |
| leave_type_id | BIGINT UNSIGNED FK | FK → **sch_leave_types** (existing in tenant_db) |
| from_date | DATE | Leave start |
| to_date | DATE | Leave end |
| days_count | DECIMAL(4,1) | Total days (half-day = 0.5) |
| is_half_day | TINYINT(1) | Half-day flag |
| half_day_type | ENUM('first_half','second_half') NULL | Which half |
| reason | TEXT | Leave reason |
| status | ENUM('draft','submitted','approved','rejected','cancelled') | Workflow |
| approved_by | BIGINT UNSIGNED NULL | FK → sys_users |
| approved_at | TIMESTAMP NULL | Approval timestamp |
| reviewer_remarks | TEXT NULL | Approver comments |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

> **Note:** `leave_type_id` references the existing `sch_leave_types` table. Leave quotas are read from existing `sch_leave_config`.

#### 4.7 prl_leave_balances
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| employee_id | BIGINT UNSIGNED FK | FK → sch_employees |
| leave_type_id | BIGINT UNSIGNED FK | FK → **sch_leave_types** (existing) |
| academic_year | VARCHAR(20) | e.g., "2025-26" |
| total_allocated | DECIMAL(4,1) | Annual allocation (from sch_leave_config) |
| used | DECIMAL(4,1) | Used so far |
| pending | DECIMAL(4,1) | Pending approval |
| carried_forward | DECIMAL(4,1) | From previous year |
| available | DECIMAL(4,1) | Remaining balance |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |
| UNIQUE | (employee_id, leave_type_id, academic_year) | One per combo |

#### 4.8 prl_attendance_logs
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| employee_id | BIGINT UNSIGNED FK | FK → sch_employees |
| attendance_date | DATE | Date |
| check_in | TIME NULL | Check-in time |
| check_out | TIME NULL | Check-out time |
| source | ENUM('biometric','manual','app') | Data source |
| status | ENUM('present','absent','half_day','on_leave','holiday','weekend') | Status |
| late_minutes | INT NULL | Minutes late |
| early_leave_minutes | INT NULL | Left early by |
| remarks | VARCHAR(255) NULL | Notes |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |
| UNIQUE | (employee_id, attendance_date) | One per day |

#### 4.9 prl_statutory_configs
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| config_type | ENUM('pf','esi','pt','tds') | Statutory type |
| employee_contribution_pct | DECIMAL(5,2) | Employee % |
| employer_contribution_pct | DECIMAL(5,2) | Employer % |
| threshold_amount | DECIMAL(15,2) NULL | Ceiling salary |
| effective_from | DATE | Effective date |
| slab_json | JSON NULL | For PT/TDS: slab-based calculation |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

#### 4.10 prl_employee_statutory_details
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| employee_id | BIGINT UNSIGNED FK | FK → sch_employees |
| pf_number | VARCHAR(30) NULL | PF account number |
| esi_number | VARCHAR(30) NULL | ESI number |
| uan | VARCHAR(20) NULL | Universal Account Number |
| pan_number | VARCHAR(15) NULL | PAN number |
| is_pf_applicable | TINYINT(1) | PF applies |
| is_esi_applicable | TINYINT(1) | ESI applies |
| is_pt_applicable | TINYINT(1) | PT applies |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

#### 4.11-4.15 Appraisal Tables (prefix `prl_`)
- `prl_appraisal_templates` — name, description, appraisal_type(Annual/HalfYearly/Quarterly)
- `prl_appraisal_template_kpis_jnt` — template_id, kpi_name, kpi_category, weightage, max_score
- `prl_appraisal_cycles` — name, template_id, start_date, end_date, status(Upcoming/InProgress/Completed)
- `prl_appraisals` — cycle_id, employee_id, reviewer_id, self_score, reviewer_score, final_rating, status(Pending/SelfDone/ReviewDone/Completed), remarks
- `prl_appraisal_scores` — appraisal_id, template_kpi_id, self_score, reviewer_score, remarks

#### 4.16-4.17 Training Tables (prefix `prl_`)
- `prl_training_programs` — title, description, trainer_name, trainer_type(Internal/External), start_date, end_date, max_participants, status(Upcoming/InProgress/Completed/Cancelled)
- `prl_training_enrollments_jnt` — training_program_id, employee_id, status(Enrolled/Attended/Absent/Completed), feedback_text, feedback_rating

---

## 5. Salary Computation Flow

```
1. Load Employee (sch_employees) → Salary Structure (prl_salary_structures) → Items (prl_salary_structure_items → prl_pay_heads)

2. Calculate Earnings:
   ├── Basic Salary          = flat_amount from structure
   ├── DA                    = Basic × DA%
   ├── HRA                   = Basic × HRA%
   ├── Conveyance            = flat_amount
   ├── Special Allowance     = flat_amount
   ├── Overtime              = (Basic/total_days) × overtime_hours
   └── Gross Salary          = sum(all earnings)

3. Apply LOP Deduction:
   ├── Approved Leave Days   = from prl_leave_applications (status='approved', NOT LWP type)
   ├── LOP Days              = total_working_days - present_days - approved_leave_days
   └── LOP Amount            = (Gross / total_days) × LOP_days

4. Calculate Deductions:
   ├── PF (Employee 12%)     = min(Basic + DA, ₹15,000) × 12%  [from prl_statutory_configs]
   ├── ESI (Employee 0.75%)  = Gross × 0.75% (if Gross ≤ ₹21,000)  [from prl_statutory_configs]
   ├── Professional Tax      = slab-based on Gross (state-wise)  [from prl_statutory_configs]
   ├── TDS                   = estimated annual tax / 12  [from prl_statutory_configs]
   ├── Advance Recovery      = flat_amount (if any)
   └── Total Deductions      = sum(all deductions) + LOP

5. Calculate Net Salary:
   └── Net = Gross - Total Deductions

6. Calculate Employer Contributions (NOT deducted from employee):
   ├── PF (Employer 12%)     = min(Basic + DA, ₹15,000) × 12%
   └── ESI (Employer 3.25%)  = Gross × 3.25% (if Gross ≤ ₹21,000)

7. Create Payroll Journal Voucher (via Accounting VoucherServiceInterface):
   Dr  Salary Expense (by department cost center)  ₹Gross
   Dr  Employer PF Contribution                    ₹PF_employer
   Dr  Employer ESI Contribution                   ₹ESI_employer
   Cr  PF Payable                                  ₹(PF_employee + PF_employer)
   Cr  ESI Payable                                 ₹(ESI_employee + ESI_employer)
   Cr  TDS Payable                                 ₹TDS
   Cr  PT Payable                                  ₹PT
   Cr  Salary Payable (per employee ledger)         ₹Net
```

---

## 6. Business Rules

1. **One Payroll Per Month:** Only one `prl_payroll_runs` record per (month, year) combination
2. **Attendance Prerequisite:** `sch_employee_attendance` must be entered before payroll can be computed
3. **LOP Calculation:** LOP days = total_working_days - present_days - approved_leave_days (from `prl_leave_applications` where leave type is NOT LWP)
4. **PF Ceiling:** PF calculated on min(Basic + DA, ₹15,000) — configurable in `prl_statutory_configs`
5. **ESI Ceiling:** ESI applicable only when Gross ≤ ₹21,000/month — configurable in `prl_statutory_configs`
6. **Payroll Lock:** Once status='locked', no edits allowed to that month's payroll
7. **Payroll Voucher:** Posting creates ONE Payroll Journal Voucher per run via Accounting module's `VoucherServiceInterface`
8. **Leave Balance Check:** Leave application rejected if `prl_leave_balances.available < days_count`
9. **Leave Allocation:** `prl_leave_balances.total_allocated` initialized from `sch_leave_config` at start of academic year
10. **Half-Day Leave:** Counts as 0.5 days from balance
11. **Appraisal Workflow:** Self-assessment must be completed before reviewer can score
12. **No tenant_id:** Dedicated database per tenant — data isolation at DB level
13. **sch_employees Reuse:** All employee references FK to `sch_employees.id` — never a separate payroll employee table

---

## 7. Workflows

### Payroll Run Workflow
```
Draft → Processing → Computed → Approved → Posted → Locked
                                   │
                                   └── (Rejected → back to Computed for re-processing)
```
- **Posted:** Creates Payroll Journal Voucher via Accounting VoucherServiceInterface

### Leave Application Workflow
```
Draft → Submitted → Approved → [Cancelled]
                  → Rejected
```
- On Approval: `prl_leave_balances.used += days_count`, `available -= days_count`
- On Cancellation: Reverse balance changes
- **Leave types and quotas read from existing `sch_leave_types` + `sch_leave_config`**

### Appraisal Workflow
```
Pending → SelfDone → ReviewDone → Completed
```

---

## 8. Integration Points

| Direction | Source | Target | Mechanism |
|-----------|--------|--------|-----------|
| Payroll → Accounting | PayrollApproved event | Create Payroll Journal Voucher | `VoucherServiceInterface` |
| SchoolSetup → Payroll | `sch_employees`, `sch_teachers` | Employee data (enhanced with payroll columns) | FK reference |
| SchoolSetup → Payroll | `sch_leave_types`, `sch_leave_config` | Leave type definitions and quotas | FK reference |
| SchoolSetup → Payroll | `sch_departments` | Department for cost center allocation | FK reference |
| Leave → Payroll | `prl_leave_applications` (approved) | LOP calculation in payroll | Query |
| Attendance → Payroll | `sch_employee_attendance` | Present days for salary calc | Query |
| Accounting → Payroll | `acc_financial_years` | Payroll run linked to fiscal year | FK reference |
| Accounting → Payroll | `acc_ledgers` | Employee salary payable ledger | FK reference |
| Payroll → PDF | `prl_payroll_entries` | Payslip PDF generation | DomPDF |

---

## 9. Reports

| Report | Description | Parameters |
|--------|-------------|------------|
| Salary Register | All employees: gross, deductions, net for a month | Month, Year |
| Department-wise Salary | Salary totals by department | Month, Year |
| PF Report | Employee + Employer PF contributions | Month range |
| ESI Report | ESI contributions | Month range |
| Professional Tax Report | PT deductions by state slab | Month range |
| TDS Report | TDS deductions | Financial year |
| Payslip (PDF) | Individual employee payslip | Employee, Month, Year |
| Bank Transfer Sheet | CSV/Excel for bulk bank transfer | Month, Year |
| Staff Register | Complete employee list with details | Department, Status |
| Leave Balance Report | Leave balances per employee per type | Academic year |
| Attendance Summary | Monthly attendance summary | Month, Year |
| Appraisal Summary | KPI scores and ratings | Cycle |
| Training Report | Program-wise enrollment and feedback | Date range |
| Attrition Report | Employee turnover analysis | Year |

---

## 10. Seed Data

### Employee Groups (5 records — seeded in `sch_employee_groups`)
| Name | PF | ESI | PT |
|------|:---:|:---:|:---:|
| Teaching Staff | Yes | No | Yes |
| Non-Teaching Staff | Yes | Yes | Yes |
| Administrative Staff | Yes | No | Yes |
| Contract Staff | No | No | No |
| Management | No | No | Yes |

### Pay Heads — Earnings (7 records — in `prl_pay_heads`)
Basic Salary (flat), Dearness Allowance (% of Basic), HRA (% of Basic, 25%), Conveyance (flat), Special Allowance (flat), Overtime (on_attendance), Bonus (flat)

### Pay Heads — Deductions (6 records — in `prl_pay_heads`)
PF Employee 12% (% of Basic+DA), ESI Employee 0.75% (% of Gross), Professional Tax (computed/slab), TDS (computed/slab), Advance Recovery (flat), Loan EMI (flat)

### Pay Heads — Employer Contributions (2 records — in `prl_pay_heads`)
PF Employer 12% (% of Basic+DA), ESI Employer 3.25% (% of Gross)

### Statutory Config (4 records — in `prl_statutory_configs`)
PF (12%/12%, ceiling ₹15,000), ESI (0.75%/3.25%, ceiling ₹21,000), PT (HP slabs), TDS (old regime slabs)

---

## 11. User Roles & Permissions

| Role | Permissions |
|------|------------|
| School Admin | Full payroll access |
| HR Manager | Employee salary assignment, payroll processing, leave approval, appraisals |
| Payroll Manager | Payroll run, payslip generation, statutory reports |
| Department Head | Leave approval for department, appraisal review |
| Employee (Self-service) | View own payslip, apply leave, self-appraisal |

**Permission strings:**
```
payroll.pay-head.viewAny/create/update/delete
payroll.salary-structure.viewAny/create/update/delete
payroll.employee-salary.viewAny/create/update
payroll.payroll-run.viewAny/create/process/approve/post/lock
payroll.payslip.viewAny/generate/download
payroll.leave.viewAny/create/approve/reject
payroll.attendance.viewAny/create/update
payroll.statutory.viewAny/create/update
payroll.appraisal.viewAny/create/score/complete
payroll.training.viewAny/create/enroll
payroll.report.view
```

---

## 12. Dependencies

| This Module Needs | From Module | Entities |
|-------------------|------------|----------|
| Employees | SchoolSetup | `sch_employees` (enhanced with payroll columns) |
| Employee Groups | SchoolSetup | `sch_employee_groups` (new or enhanced) |
| Attendance Summary | SchoolSetup | `sch_employee_attendance` (new or enhanced) |
| Teachers | SchoolSetup | `sch_teachers` (for teacher identification) |
| Departments | SchoolSetup | `sch_departments` (for cost center allocation) |
| Leave Types | SchoolSetup | `sch_leave_types` (**existing in tenant_db**) |
| Leave Config | SchoolSetup | `sch_leave_config` (**existing in tenant_db**) |
| Financial Year | Accounting | `acc_financial_years` (FK on payroll runs) |
| Ledgers | Accounting | `acc_ledgers` (employee salary payable ledger) |
| Voucher Posting | Accounting | `VoucherServiceInterface` (post payroll journal) |
| Users | System | `sys_users` (created_by, approved_by) |

---

## 13. Controllers & Services Summary

### Controllers (11)
PayHeadController, SalaryStructureController, EmployeeSalaryController, PayrollController (monthly run wizard), AttendanceController (monthly grid/daily log), LeaveApplicationController, StatutoryConfigController, AppraisalController, TrainingController, PrlReportController, PrlDashboardController

### Services (6)
PayrollComputeService (monthly calculation → VoucherServiceInterface), StatutoryCalcService (PF/ESI/PT/TDS), LeaveApplicationService, AttendanceSyncService (biometric stub), AppraisalService, PayslipPdfService (DomPDF)

### FormRequests (~10)
Store/Update for: PayHead, SalaryStructure, EmployeeSalary, PayrollRun, Attendance, LeaveApplication, StatutoryConfig, Appraisal, Training

---

## 14. Table Summary

| Category | Tables | Prefix |
|----------|--------|--------|
| Payroll Core (new) | prl_pay_heads, prl_salary_structures, prl_salary_structure_items, prl_payroll_runs, prl_payroll_entries | `prl_` |
| HR Leave (new) | prl_leave_applications, prl_leave_balances, prl_attendance_logs | `prl_` |
| HR Statutory (new) | prl_statutory_configs, prl_employee_statutory_details | `prl_` |
| HR Appraisal (new) | prl_appraisal_templates, prl_appraisal_template_kpis_jnt, prl_appraisal_cycles, prl_appraisals, prl_appraisal_scores | `prl_` |
| HR Training (new) | prl_training_programs, prl_training_enrollments_jnt | `prl_` |
| SchoolSetup enhanced | sch_employee_groups, sch_employee_attendance | `sch_` |
| SchoolSetup reused | sch_employees (ALTER), sch_leave_types, sch_leave_config | `sch_` |
| **Total new tables** | **17 `prl_` + 2 `sch_` new/enhanced** | |
| **Total reused** | **6 `sch_` existing** | |
