# Payroll Module — Detailed Requirement Document

**Module:** HR & Payroll | **Prefix:** `acc_` (payroll domain within Accounting) | **Database:** tenant_db
**Route:** `/accounting/payroll/*`, `/accounting/employee/*`, `/accounting/attendance/*`
**RBS Module:** P — HR & Staff Management (46 sub-tasks)
**Date:** 2026-03-19

---

## 1. Module Overview & Purpose

The Payroll module manages **Indian school staff salary processing** — from employee master records and salary structures through monthly payroll computation to payslip generation. It is a **domain within the Accounting module**, sharing the same voucher engine. Every payroll run creates a Payroll Journal Voucher in accounting.

**Indian School Payroll Context:**
- Statutory deductions: PF (12%+12%), ESI (0.75%+3.25%), Professional Tax (state-wise), TDS (income tax)
- CTC structure: Basic + DA + HRA + Conveyance + Special Allowance + Bonus
- Financial year: April–March; payroll runs monthly
- Teachers and non-teaching staff have different pay structures and statutory applicability
- Attendance-based LOP (Loss of Pay) deduction
- Employer contributions (PF, ESI) tracked separately — not deducted from employee salary

**Relationship to Existing Modules:**
- **SchoolSetup:** Reuses `sch_employees`, `sch_teachers`, `sch_departments`, `sch_designations` — NOT duplicated
- **Accounting:** Payroll run creates a Journal Voucher via VoucherService
- The `acc_employees` table acts as the **payroll bridge** — linking SchoolSetup employee records to salary structures and ledger accounts

---

## 2. Scope & Boundaries

### In Scope
- Employee groups (Teaching, Non-Teaching, Contract, Management)
- Employee master (payroll-specific: bank details, PF/ESI numbers, salary structure)
- Pay heads (earnings, deductions, employer contributions)
- Salary structure templates (pay grade → pay head mapping)
- Employee salary assignment (employee → salary structure + CTC)
- Monthly attendance (for LOP calculation)
- Monthly payroll run (compute → review → approve → post)
- Payslip generation (PDF via DomPDF)
- Statutory calculations (PF, ESI, PT, TDS)
- Expense claims (staff reimbursement)
- Leave application & balance tracking
- Performance appraisal (KPI templates, cycles, self/reviewer scoring)
- Staff training management
- HR reports (salary register, PF report, department-wise summary)

### Out of Scope (Handled by Other Modules)
- Employee profile creation (personal details, qualifications) → **SchoolSetup** (`sch_employees`)
- Teacher-specific data (subjects, capabilities) → **SchoolSetup** (`sch_teachers`)
- Department/Designation CRUD → **SchoolSetup** (`sch_departments`, `sch_designations`)
- Leave type master, leave config → **SchoolSetup** (`sch_leave_types`, `sch_leave_config`)
- Accounting voucher engine → **Accounting** (shared `acc_vouchers`)
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
| ST.P1.1.2.2 | Manage emergency contacts | `sch_employee_profiles` | Done |
| ST.P1.2.1.1 | Define designation & department | `sch_employee_profiles.department_id`, `role_id` | Done |
| ST.P1.2.1.2 | Set joining date & contract type | `sch_employees.joining_date` | Done |
| ST.P1.2.2.1 | Upload appointment letter | Spatie Media on `sch_employees` | Done |
| ST.P1.2.2.2 | Track document renewal dates | New: document renewal alert system | Pending |

### P2 — Staff Attendance & Leave (7 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P2.1.1.1 | Select leave type | `hr_leave_applications.leave_type_id` FK → sch_leave_types | New |
| ST.P2.1.1.2 | Submit leave request | `hr_leave_applications.status` = 'Submitted' | New |
| ST.P2.1.1.3 | Attach supporting document | Spatie Media on `hr_leave_applications` | New |
| ST.P2.1.2.1 | Approve/Reject leave | `hr_leave_applications.status` workflow | New |
| ST.P2.1.2.2 | Record remarks with history | `hr_leave_applications.reviewer_remarks` + activity log | New |
| ST.P2.2.1.1 | Fetch logs from biometric device | `hr_attendance_logs` (manual entry, biometric stubbed) | Stub |
| ST.P2.2.1.2 | Auto-mark attendance | AttendanceSyncService (biometric sync) | Stub |

### P3 — Payroll Preparation (8 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P3.1.1.1 | Add earnings & deductions | `acc_pay_heads` (type: earning/deduction/employer) | New |
| ST.P3.1.1.2 | Assign pay grade | `acc_salary_structures` + `acc_salary_structure_items` | New |
| ST.P3.1.2.1 | Auto-calculate components | PayrollComputeService (percentage-based calc) | New |
| ST.P3.1.2.2 | Record employer contributions | `acc_pay_heads` with type='employer_contribution' | New |
| ST.P3.2.1.1 | Calculate earnings & deductions | PayrollComputeService.processPayroll() | New |
| ST.P3.2.1.2 | Apply LOP for absences | LOP = (monthly_salary / total_working_days) * absent_days | New |
| ST.P3.2.2.1 | Add ad-hoc allowances | `acc_payroll_entries.adhoc_earnings_json` | New |
| ST.P3.2.2.2 | Apply manual deductions | `acc_payroll_entries.adhoc_deductions_json` | New |

### P4 — Compliance & Statutory Management (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P4.1.1.1 | Enable PF/ESI applicability | `acc_employee_groups.is_pf_applicable`, `is_esi_applicable` | New |
| ST.P4.1.1.2 | Record employee PF details | `hr_employee_statutory_details.pf_number`, `uan` | New |
| ST.P4.1.2.1 | PF report | ReportService.pfReport() | New |
| ST.P4.1.2.2 | ESI contribution report | ReportService.esiReport() | New |

### P5 — Performance Appraisal (8 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P5.1.1.1 | Add KPI categories | `hr_appraisal_templates` + `hr_appraisal_template_kpis_jnt` | New |
| ST.P5.1.1.2 | Set weightage for each KPI | `hr_appraisal_template_kpis_jnt.weightage` | New |
| ST.P5.1.2.1 | Set appraisal period | `hr_appraisal_cycles` (start_date, end_date) | New |
| ST.P5.1.2.2 | Assign reviewer | `hr_appraisals.reviewer_id` FK | New |
| ST.P5.2.1.1 | Staff fills self-assessment | `hr_appraisal_scores.self_score` | New |
| ST.P5.2.1.2 | Attach proofs | Spatie Media on `hr_appraisals` | New |
| ST.P5.2.2.1 | Score KPIs | `hr_appraisal_scores.reviewer_score` | New |
| ST.P5.2.2.2 | Provide final rating | `hr_appraisals.final_rating` | New |

### P6 — Staff Training & Development (6 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P6.1.1.1 | Set topic & trainer | `hr_training_programs.title`, `trainer_name` | New |
| ST.P6.1.1.2 | Define training schedule | `hr_training_programs.start_date`, `end_date` | New |
| ST.P6.1.2.1 | Add staff to training | `hr_training_enrollments_jnt` | New |
| ST.P6.1.2.2 | Notify participants | Notification module integration | Phase 2 |
| ST.P6.2.1.1 | Receive training feedback | `hr_training_enrollments_jnt.feedback_text`, `feedback_rating` | New |
| ST.P6.2.1.2 | Generate evaluation report | ReportService.trainingReport() | New |

### P7 — HR Reports & Analytics (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P7.1.1.1 | Staff register | ReportService.staffRegister() (from sch_employees) | New |
| ST.P7.1.1.2 | Department-wise strength report | ReportService.departmentStrength() | New |
| ST.P7.2.1.1 | Attrition rate analysis | Computed from employee records | New |
| ST.P7.2.1.2 | Leave trend analysis | ReportService.leaveTrend() | New |

---

## 4. Entity List (Tables & Columns)

### Existing Tables REUSED (from SchoolSetup — NOT duplicated)

| Table | Used For |
|-------|----------|
| `sch_employees` | Employee master (personal, qualifications, joining_date) |
| `sch_employees_profile` | Role, department, reporting_to, skills |
| `sch_teachers` | Teacher-specific (max_periods, subjects) |
| `sch_teacher_profiles` | Teaching profile details |
| `sch_departments` | Department reference |
| `sch_designations` | Designation reference |
| `sch_leave_types` | Leave type master (CL, EL, SL, etc.) |
| `sch_leave_config` | Leave quota per staff category |

### New Tables — Payroll Domain (in Accounting DDL, prefix `acc_`)

#### 4.1 acc_employee_groups
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

#### 4.2 acc_employees
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| employee_group_id | BIGINT UNSIGNED FK | FK → acc_employee_groups |
| teacher_id | BIGINT UNSIGNED NULL FK | FK → sch_teachers (if teacher) |
| sch_employee_id | BIGINT UNSIGNED NULL FK | FK → sch_employees (always) |
| ledger_id | BIGINT UNSIGNED NULL FK | FK → acc_ledgers (auto-created under Salary Payable) |
| designation | VARCHAR(100) NULL | Job title override |
| bank_name | VARCHAR(100) NULL | Salary bank |
| bank_account_number | VARCHAR(50) NULL | Account number |
| bank_ifsc | VARCHAR(20) NULL | IFSC code |
| pf_number | VARCHAR(30) NULL | PF account number |
| esi_number | VARCHAR(30) NULL | ESI number |
| uan | VARCHAR(20) NULL | Universal Account Number |
| pan | VARCHAR(15) NULL | PAN card number |
| date_of_joining | DATE NULL | Joining date (payroll effective) |
| date_of_leaving | DATE NULL | Leaving date |
| salary_structure_id | BIGINT UNSIGNED NULL FK | FK → acc_salary_structures |
| ctc_monthly | DECIMAL(15,2) NULL | Monthly CTC |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

#### 4.3 acc_pay_heads
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
| ledger_id | BIGINT UNSIGNED NULL FK | FK → acc_ledgers (expense/liability ledger) |
| sequence | INT | Display order on payslip |
| is_system | TINYINT(1) | Cannot delete |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

#### 4.4 acc_salary_structures
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(100) | e.g., "Teaching Staff Grade A" |
| code | VARCHAR(20) UNIQUE | Structure code |
| description | TEXT NULL | Description |
| effective_from | DATE | Structure validity start |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

#### 4.5 acc_salary_structure_items
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| salary_structure_id | BIGINT UNSIGNED FK | FK → acc_salary_structures (CASCADE) |
| pay_head_id | BIGINT UNSIGNED FK | FK → acc_pay_heads |
| amount | DECIMAL(15,2) NULL | Fixed amount (overrides pay_head default) |
| percentage | DECIMAL(5,2) NULL | Percentage (overrides pay_head default) |
| is_mandatory | TINYINT(1) | Cannot remove from employee |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

#### 4.6 acc_employee_attendance
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| employee_id | BIGINT UNSIGNED FK | FK → acc_employees |
| month | TINYINT | 1-12 |
| year | SMALLINT | e.g., 2026 |
| total_days | TINYINT | Total working days in month |
| present_days | DECIMAL(4,1) | Days present (half-day = 0.5) |
| lwp_days | DECIMAL(4,1) | Leave Without Pay days |
| overtime_hours | DECIMAL(5,1) NULL | Overtime hours |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |
| UNIQUE | (employee_id, month, year) | One record per month |

#### 4.7 acc_payroll_runs
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| month | TINYINT | Payroll month (1-12) |
| year | SMALLINT | Payroll year |
| financial_year_id | BIGINT UNSIGNED FK | FK → acc_financial_years |
| status | ENUM('draft','processing','computed','approved','posted','locked') | Run status |
| total_employees | INT | Count of employees processed |
| total_gross | DECIMAL(15,2) | Sum of all gross salaries |
| total_deductions | DECIMAL(15,2) | Sum of all deductions |
| total_net | DECIMAL(15,2) | Sum of all net salaries |
| total_employer_pf | DECIMAL(15,2) | Employer PF contribution |
| total_employer_esi | DECIMAL(15,2) | Employer ESI contribution |
| voucher_id | BIGINT UNSIGNED NULL FK | FK → acc_vouchers (created on posting) |
| processed_by | BIGINT UNSIGNED NULL | User who ran payroll |
| approved_by | BIGINT UNSIGNED NULL | User who approved |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |
| UNIQUE | (month, year) | One run per month |

#### 4.8 acc_payroll_entries
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| payroll_run_id | BIGINT UNSIGNED FK | FK → acc_payroll_runs (CASCADE) |
| employee_id | BIGINT UNSIGNED FK | FK → acc_employees |
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

### New Tables — HR Extensions (prefix `hr_`)

#### 4.9 hr_leave_applications
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| employee_id | BIGINT UNSIGNED FK | FK → sch_employees |
| leave_type_id | BIGINT UNSIGNED FK | FK → sch_leave_types |
| from_date | DATE | Leave start |
| to_date | DATE | Leave end |
| days_count | DECIMAL(4,1) | Total days (half-day = 0.5) |
| is_half_day | TINYINT(1) | Half-day flag |
| half_day_type | ENUM('first_half','second_half') NULL | Which half |
| reason | TEXT | Leave reason |
| status | ENUM('draft','submitted','approved','rejected','cancelled') | Workflow |
| approved_by | BIGINT UNSIGNED NULL | Approver |
| approved_at | TIMESTAMP NULL | Approval timestamp |
| reviewer_remarks | TEXT NULL | Approver comments |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

#### 4.10 hr_leave_balances
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| employee_id | BIGINT UNSIGNED FK | FK → sch_employees |
| leave_type_id | BIGINT UNSIGNED FK | FK → sch_leave_types |
| academic_year | VARCHAR(20) | e.g., "2025-26" |
| total_allocated | DECIMAL(4,1) | Annual allocation |
| used | DECIMAL(4,1) | Used so far |
| pending | DECIMAL(4,1) | Pending approval |
| carried_forward | DECIMAL(4,1) | From previous year |
| available | DECIMAL(4,1) | Remaining balance |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |
| UNIQUE | (employee_id, leave_type_id, academic_year) | One per combo |

#### 4.11 hr_attendance_logs
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

#### 4.12 hr_statutory_configs
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

#### 4.13 hr_employee_statutory_details
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

#### 4.14-4.18 Appraisal Tables
- `hr_appraisal_templates` — name, description, appraisal_type(Annual/HalfYearly/Quarterly)
- `hr_appraisal_template_kpis_jnt` — template_id, kpi_name, kpi_category, weightage, max_score
- `hr_appraisal_cycles` — name, template_id, start_date, end_date, status(Upcoming/InProgress/Completed)
- `hr_appraisals` — cycle_id, employee_id, reviewer_id, self_score, reviewer_score, final_rating, status(Pending/SelfDone/ReviewDone/Completed), remarks
- `hr_appraisal_scores` — appraisal_id, template_kpi_id, self_score, reviewer_score, remarks

#### 4.19-4.20 Training Tables
- `hr_training_programs` — title, description, trainer_name, trainer_type(Internal/External), start_date, end_date, max_participants, status(Upcoming/InProgress/Completed/Cancelled)
- `hr_training_enrollments_jnt` — training_program_id, employee_id, status(Enrolled/Attended/Absent/Completed), feedback_text, feedback_rating

---

## 5. Salary Computation Flow

```
1. Load Employee → Salary Structure → Structure Items (Pay Heads)
2. Calculate Earnings:
   ├── Basic Salary          = flat_amount from structure
   ├── DA                    = Basic × DA%
   ├── HRA                   = Basic × HRA%
   ├── Conveyance            = flat_amount
   ├── Special Allowance     = flat_amount
   ├── Overtime              = (Basic/total_days) × overtime_hours
   └── Gross Salary          = sum(all earnings)

3. Apply LOP Deduction:
   ├── LOP Days              = total_days - present_days - approved_leave_days
   └── LOP Amount            = (Gross / total_days) × LOP_days

4. Calculate Deductions:
   ├── PF (Employee 12%)     = min(Basic + DA, ₹15,000) × 12%
   ├── ESI (Employee 0.75%)  = Gross × 0.75% (if Gross ≤ ₹21,000)
   ├── Professional Tax      = slab-based on Gross (state-wise)
   ├── TDS                   = estimated annual tax / 12
   ├── Advance Recovery      = flat_amount (if any)
   └── Total Deductions      = sum(all deductions) + LOP

5. Calculate Net Salary:
   └── Net = Gross - Total Deductions

6. Calculate Employer Contributions (NOT deducted from employee):
   ├── PF (Employer 12%)     = min(Basic + DA, ₹15,000) × 12%
   └── ESI (Employer 3.25%)  = Gross × 3.25% (if Gross ≤ ₹21,000)

7. Create Payroll Journal Voucher:
   Dr  Salary Expense (by department)  ₹Gross
   Dr  Employer PF Contribution        ₹PF_employer
   Dr  Employer ESI Contribution       ₹ESI_employer
   Cr  PF Payable                      ₹(PF_employee + PF_employer)
   Cr  ESI Payable                     ₹(ESI_employee + ESI_employer)
   Cr  TDS Payable                     ₹TDS
   Cr  PT Payable                      ₹PT
   Cr  Salary Payable                  ₹Net (per employee ledger)
```

---

## 6. Business Rules

1. **One Payroll Per Month:** Only one `acc_payroll_runs` record per (month, year) combination
2. **Attendance Prerequisite:** Attendance must be entered before payroll can be computed
3. **LOP Calculation:** LOP days = total_working_days - present_days - approved_leave_days (where leave is NOT LWP)
4. **PF Ceiling:** PF calculated on min(Basic + DA, ₹15,000) — configurable in hr_statutory_configs
5. **ESI Ceiling:** ESI applicable only when Gross ≤ ₹21,000/month — configurable
6. **Payroll Lock:** Once status='locked', no edits allowed to that month's payroll
7. **Payroll Voucher:** Posting creates ONE Payroll Journal Voucher per run (not per employee)
8. **Leave Balance Check:** Leave application rejected if balance insufficient
9. **Half-Day Leave:** Counts as 0.5 days from balance
10. **Appraisal Workflow:** Self-assessment must be completed before reviewer can score

---

## 7. Workflows

### Payroll Run Workflow
```
Draft → Processing → Computed → Approved → Posted → Locked
                                   │
                                   └── (Rejected → back to Computed for re-processing)
```

### Leave Application Workflow
```
Draft → Submitted → Approved → [Cancelled]
                  → Rejected
```
- On Approval: `hr_leave_balances.used += days_count`, `available -= days_count`
- On Cancellation: Reverse balance changes

### Appraisal Workflow
```
Pending → SelfDone → ReviewDone → Completed
```

---

## 8. Integration Points

| Direction | Source | Target | Mechanism |
|-----------|--------|--------|-----------|
| Payroll → Accounting | PayrollApproved event | Create Payroll Journal Voucher | VoucherService |
| SchoolSetup → Payroll | sch_employees, sch_teachers | acc_employees (bridge) | FK reference |
| Leave → Payroll | hr_leave_applications (approved) | LOP calculation in payroll | Query |
| Attendance → Payroll | acc_employee_attendance | Present days for salary calc | Query |
| Payroll → PDF | acc_payroll_entries | Payslip PDF generation | DomPDF |

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
| Leave Balance Report | Leave balances per employee | Academic year |
| Attendance Summary | Monthly attendance summary | Month, Year |
| Appraisal Summary | KPI scores and ratings | Cycle |

---

## 10. Seed Data

### Employee Groups (5 records)
| Name | PF | ESI | PT |
|------|:---:|:---:|:---:|
| Teaching Staff | Yes | No | Yes |
| Non-Teaching Staff | Yes | Yes | Yes |
| Administrative Staff | Yes | No | Yes |
| Contract Staff | No | No | No |
| Management | No | No | Yes |

### Pay Heads — Earnings (7 records)
Basic Salary (flat), Dearness Allowance (% of Basic), HRA (% of Basic, 25%), Conveyance (flat), Special Allowance (flat), Overtime (on_attendance), Bonus (flat)

### Pay Heads — Deductions (6 records)
PF Employee 12% (% of Basic+DA), ESI Employee 0.75% (% of Gross), Professional Tax (computed/slab), TDS (computed/slab), Advance Recovery (flat), Loan EMI (flat)

### Pay Heads — Employer Contributions (2 records)
PF Employer 12% (% of Basic+DA), ESI Employer 3.25% (% of Gross)

### Statutory Config (4 records)
PF (12%/12%, ceiling ₹15,000), ESI (0.75%/3.25%, ceiling ₹21,000), PT (HP slabs), TDS (old regime slabs)

---

## 11. Controllers & Services

### Controllers (11)
EmployeeGroupController, EmployeeController (payroll view), PayHeadController, SalaryStructureController, PayrollController (monthly run wizard), AttendanceController (monthly grid), HrLeaveApplicationController, HrStatutoryController, HrAppraisalController, HrTrainingController, HrReportController

### Services (6)
PayrollComputeService, StatutoryCalcService (PF/ESI/PT/TDS), LeaveApplicationService, AttendanceSyncService, AppraisalService, PayslipPdfService

### FormRequests (~10)
Store/Update for: Employee, PayHead, SalaryStructure, PayrollRun, Attendance, LeaveApplication, Appraisal, Training
