# Payroll Module — Detailed Requirement Document v3

**Module:** Payroll | **Laravel Module:** `Modules/Payroll/` | **Prefix:** `prl_`
**Database:** tenant_db (dedicated per tenant — no tenant_id needed)
**Route:** `/payroll/*` | **RBS Module:** P — HR & Staff Management (46 sub-tasks)
**Date:** 2026-03-19 | **Version:** 3.0

**Changes from v2:** Verified ALL tables against `0-DDL_Masters/tenant_db_v2.sql`. `sch_employee_groups` DOES NOT EXIST → replaced by `prl_category_statutory_config` that extends existing `sch_categories`. `sch_employee_attendance` DOES NOT EXIST → replaced by `prl_monthly_attendance`. `sch_teachers` DOES NOT EXIST → use `sch_employees.is_teacher=1`. Fixed all singular table names. Integrated `sch_leave_types`/`sch_leave_config`/`sch_categories` understanding.

---

## 1. Module Overview & Purpose

The Payroll module is a **separate Laravel module** (`Modules/Payroll/`) that manages **Indian school staff salary processing**. It connects to the **Accounting module** via `VoucherServiceInterface` to post payroll journal vouchers.

**Relationship to Existing SchoolSetup Tables:**
- **`sch_employees`** (line 955) — Employee master. Enhanced with payroll columns via ALTER TABLE.
- **`sch_categories`** (line 584) — Staff categorization (`applicable_for = 'STAFF'` or `'BOTH'`). Used by `sch_leave_config` for leave allocation. Payroll extends this with `prl_category_statutory_config` for PF/ESI/PT flags.
- **`sch_leave_types`** (line 564) — Leave type master with `is_paid`, `requires_approval`, `allow_half_day`. Determines if leave deducts salary (LWP) or not.
- **`sch_leave_config`** (line 602) — Maps `staff_category_id` (→ `sch_categories`) + `leave_type_id` (→ `sch_leave_types`) to `total_allowed` per `academic_year`. Includes `carry_forward` and `max_carry_forward`.
- **`sch_attendance_types`** (line 543) — Attendance codes (P/A/L/H) with `applicable_for` flag.
- **`sch_department`** (line 476) — **SINGULAR name**. Department reference.
- **`sch_designation`** (line 486) — **SINGULAR name**. Designation reference.
- **`sch_teacher_profile`** (line 1035) — **SINGULAR name**. Teacher-specific data.

> **CRITICAL:** There is NO `sch_teachers` table, NO `sch_employee_groups` table, and NO `sch_employee_attendance` table in `tenant_db_v2.sql`. These were incorrectly claimed as existing in v1/v2.

---

## 2. Scope & Boundaries

### In Scope
- Pay heads (earnings, deductions, employer contributions) — prefix `prl_`
- Salary structure templates — prefix `prl_`
- Category statutory config (PF/ESI/PT per staff category) — prefix `prl_`
- Monthly payroll run — prefix `prl_`
- Monthly attendance summary — prefix `prl_`
- Daily attendance logs — prefix `prl_`
- Leave application & balance tracking — prefix `prl_`
- Statutory configuration & employee statutory details — prefix `prl_`
- Payslip PDF generation
- Performance appraisal — prefix `prl_`
- Staff training — prefix `prl_`
- HR reports

### Out of Scope (Handled by Other Modules)
- Employee profile CRUD → **SchoolSetup** (`sch_employees`, `sch_employees_profile`)
- Teacher-specific data → **SchoolSetup** (`sch_teacher_profile`, `sch_teacher_capabilities`)
- Department/Designation CRUD → **SchoolSetup** (`sch_department`, `sch_designation`)
- Leave type master → **SchoolSetup** (`sch_leave_types`) — **EXISTING, read-only**
- Leave allocation config → **SchoolSetup** (`sch_leave_config`) — **EXISTING, read-only**
- Staff categories → **SchoolSetup** (`sch_categories`) — **EXISTING, read-only**
- Attendance type codes → **SchoolSetup** (`sch_attendance_types`) — **EXISTING, read-only**
- Voucher engine → **Accounting** (via `VoucherServiceInterface`)
- Expense claims → **Accounting** (`acc_expense_claims`)
- Biometric device integration → Stubbed for now

---

## 3. RBS Mapping (Module P — 46 Sub-Tasks)

### P1 — Staff Master & HR Records (9 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P1.1.1.1 | Enter personal details | `sch_employees` (existing) | Done |
| ST.P1.1.1.2 | Upload documents | Spatie Media on `sch_employees` | Done |
| ST.P1.1.1.3 | Assign employee code | `sch_employees.emp_code` | Done |
| ST.P1.1.2.1 | Update contact details | `sch_employees` edit | Done |
| ST.P1.1.2.2 | Manage emergency contacts | `sch_employees_profile` | Done |
| ST.P1.2.1.1 | Define designation & department | `sch_employees_profile.department_id`→**sch_department**, `role_id` | Done |
| ST.P1.2.1.2 | Set joining date & contract type | `sch_employees.joining_date` | Done |
| ST.P1.2.2.1 | Upload appointment letter | Spatie Media on `sch_employees` | Done |
| ST.P1.2.2.2 | Track document renewal dates | Future enhancement | Pending |

### P2 — Staff Attendance & Leave (7 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P2.1.1.1 | Select leave type | `prl_leave_applications.leave_type_id` FK → **`sch_leave_types`** | New |
| ST.P2.1.1.2 | Submit leave request | `prl_leave_applications.status` = 'Submitted' | New |
| ST.P2.1.1.3 | Attach supporting document | Spatie Media on `prl_leave_applications` | New |
| ST.P2.1.2.1 | Approve/Reject leave | `prl_leave_applications.status` workflow | New |
| ST.P2.1.2.2 | Record remarks with history | `prl_leave_applications.reviewer_remarks` + activity log | New |
| ST.P2.2.1.1 | Fetch logs from biometric device | `prl_attendance_logs` (manual entry, biometric stubbed) | Stub |
| ST.P2.2.1.2 | Auto-mark attendance | AttendanceSyncService | Stub |

### P3 — Payroll Preparation (8 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P3.1.1.1 | Add earnings & deductions | `prl_pay_heads` | New |
| ST.P3.1.1.2 | Assign pay grade | `prl_salary_structures` + `prl_salary_structure_items` | New |
| ST.P3.1.2.1 | Auto-calculate components | PayrollComputeService | New |
| ST.P3.1.2.2 | Record employer contributions | `prl_pay_heads` type='employer_contribution' | New |
| ST.P3.2.1.1 | Calculate earnings & deductions | PayrollComputeService.processPayroll() | New |
| ST.P3.2.1.2 | Apply LOP for absences | `prl_monthly_attendance.lwp_days` → LOP deduction | New |
| ST.P3.2.2.1 | Add ad-hoc allowances | `prl_payroll_entries.adhoc_earnings_json` | New |
| ST.P3.2.2.2 | Apply manual deductions | `prl_payroll_entries.adhoc_deductions_json` | New |

### P4 — Compliance & Statutory (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.P4.1.1.1 | Enable PF/ESI applicability per category | `prl_category_statutory_config.is_pf_applicable` (extends `sch_categories`) | New |
| ST.P4.1.1.2 | Record employee PF details | `prl_employee_statutory_details` | New |
| ST.P4.1.2.1 | PF report | PrlReportService.pfReport() | New |
| ST.P4.1.2.2 | ESI contribution report | PrlReportService.esiReport() | New |

### P5-P7 — Appraisal, Training, Reports
*(Same as v2 — all using `prl_` prefix)*

---

## 4. Entity List — VERIFIED against `tenant_db_v2.sql`

### Existing Tables REUSED (all verified present in DDL)

| Table | Line # | Purpose | Changes |
|-------|--------|---------|---------|
| `sch_employees` | 955 | Employee master | **ALTER TABLE** — add 14 payroll columns (see Section 14) |
| `sch_employees_profile` | 984 | Role, department, skills | None |
| `sch_leave_types` | 564 | Leave types: code, name, `is_paid`, `requires_approval`, `allow_half_day` | None |
| `sch_leave_config` | 602 | Leave allocation: `staff_category_id`→sch_categories, `leave_type_id`→sch_leave_types, `total_allowed`, `carry_forward`, `max_carry_forward` per `academic_year` | None |
| `sch_categories` | 584 | Staff/student categories: code, name, `applicable_for`(STUDENT/STAFF/BOTH) | None |
| `sch_attendance_types` | 543 | Attendance codes: P/A/L/H, `applicable_for`(STUDENT/STAFF/BOTH) | None |
| `sch_department` | 476 | Department reference (**SINGULAR**) | None |
| `sch_designation` | 486 | Designation reference (**SINGULAR**) | None |
| `sch_teacher_profile` | 1035 | Teacher-specific data (**SINGULAR**) | None |
| `sch_teacher_capabilities` | 1088 | Subject competency | None |

> **Tables that DO NOT EXIST (corrected from v2):**
> - ~~`sch_employee_groups`~~ → Replaced by `prl_category_statutory_config` extending `sch_categories`
> - ~~`sch_employee_attendance`~~ → Replaced by new `prl_monthly_attendance`
> - ~~`sch_teachers`~~ → No separate table; use `sch_employees.is_teacher = 1`

### How Leave Management Works with Existing Tables

```
sch_categories (Staff categories — e.g., "Teaching Staff", "Admin Staff")
    │ applicable_for = 'STAFF' or 'BOTH'
    │
    ├──→ sch_leave_config (Leave allocation per category per year)
    │       staff_category_id → sch_categories.id
    │       leave_type_id → sch_leave_types.id
    │       total_allowed = 12 (e.g., 12 CL per year for Teaching Staff)
    │       carry_forward = 1, max_carry_forward = 5
    │
    └──→ prl_category_statutory_config (NEW — PF/ESI/PT flags per category)
            staff_category_id → sch_categories.id
            is_pf_applicable = 1, is_esi_applicable = 0, is_pt_applicable = 1

sch_leave_types (Leave type definitions — CL, SL, PL, LOP)
    │ is_paid: 1=Paid, 0=Unpaid (LOP)
    │ requires_approval: 1=Yes
    │ allow_half_day: 1=Yes
    │
    └──→ prl_leave_applications (NEW — runtime leave requests)
    └──→ prl_leave_balances (NEW — runtime balances per employee)
            total_allocated = from sch_leave_config.total_allowed
            carried_forward = from previous year's balance

Payroll LOP Calculation:
    If sch_leave_types.is_paid = 0 (LOP type)
    → Days count as LWP in prl_monthly_attendance.lwp_days
    → LOP Amount = (Gross / total_working_days) × lwp_days
```

---

### New Tables — Payroll Core (prefix `prl_`) — 19 tables

#### 4.1 prl_pay_heads
*(Same as v2)*

#### 4.2 prl_salary_structures
*(Same as v2)*

#### 4.3 prl_salary_structure_items
*(Same as v2)*

#### 4.4 prl_payroll_runs
*(Same as v2 — `financial_year_id` FK → `acc_financial_years`, `voucher_id` FK → `acc_vouchers`)*

#### 4.5 prl_payroll_entries
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| payroll_run_id | BIGINT UNSIGNED FK | FK → prl_payroll_runs (CASCADE) |
| employee_id | BIGINT UNSIGNED FK | FK → **`sch_employees`** (existing, not acc_employees) |
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
| adhoc_earnings_json | JSON NULL | Ad-hoc bonuses |
| adhoc_deductions_json | JSON NULL | Ad-hoc deductions |
| earnings_breakdown_json | JSON | Detailed earning pay heads |
| deductions_breakdown_json | JSON | Detailed deduction pay heads |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

#### 4.6 prl_leave_applications
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| employee_id | BIGINT UNSIGNED FK | FK → **`sch_employees`** |
| leave_type_id | INT UNSIGNED FK | FK → **`sch_leave_types`** (existing — uses `is_paid` to determine LWP) |
| from_date | DATE | Leave start |
| to_date | DATE | Leave end |
| days_count | DECIMAL(4,1) | Total days (0.5 for half-day) |
| is_half_day | TINYINT(1) | Half-day flag (only if `sch_leave_types.allow_half_day = 1`) |
| half_day_type | ENUM('first_half','second_half') NULL | Which half |
| reason | TEXT | Leave reason |
| status | ENUM('draft','submitted','approved','rejected','cancelled') | Workflow |
| approved_by | BIGINT UNSIGNED NULL | FK → sys_users |
| approved_at | TIMESTAMP NULL | Approval timestamp |
| reviewer_remarks | TEXT NULL | Approver comments |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

#### 4.7 prl_leave_balances
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| employee_id | BIGINT UNSIGNED FK | FK → **`sch_employees`** |
| leave_type_id | INT UNSIGNED FK | FK → **`sch_leave_types`** (existing) |
| academic_year | VARCHAR(9) | e.g., "2025-26" (matches `sch_leave_config.academic_year` format) |
| total_allocated | DECIMAL(5,2) | Sourced from **`sch_leave_config.total_allowed`** for this category+type |
| used | DECIMAL(5,2) | Consumed so far |
| pending | DECIMAL(5,2) | Pending approval |
| carried_forward | DECIMAL(5,2) | From previous year (per `sch_leave_config.carry_forward` rules) |
| available | DECIMAL(5,2) | Remaining: total_allocated + carried_forward - used - pending |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |
| UNIQUE | (employee_id, leave_type_id, academic_year) | One per combo |

**Initialization Logic:**
- At start of each academic year, Payroll creates `prl_leave_balances` for every active employee.
- `total_allocated` = `sch_leave_config.total_allowed` WHERE `staff_category_id` = employee's `sch_employees.staff_category_id` AND `leave_type_id` matches.
- `carried_forward` = previous year's `available` balance, capped by `sch_leave_config.max_carry_forward`.

#### 4.8 prl_attendance_logs
*(Same as v2 — daily check-in/out, employee_id → `sch_employees`)*

#### 4.9 prl_monthly_attendance (NEW — replaces non-existent `sch_employee_attendance`)
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| employee_id | BIGINT UNSIGNED FK | FK → **`sch_employees`** |
| month | TINYINT | 1-12 |
| year | SMALLINT | e.g., 2026 |
| total_working_days | TINYINT | Working days in month (excl. holidays/weekends) |
| present_days | DECIMAL(4,1) | Days present (half-day = 0.5) |
| approved_leave_days | DECIMAL(4,1) | Approved paid leave days |
| lwp_days | DECIMAL(4,1) | Leave Without Pay days (`sch_leave_types.is_paid = 0`) |
| absent_days | DECIMAL(4,1) | Unapproved absences |
| overtime_hours | DECIMAL(5,1) NULL | Overtime hours |
| late_count | INT DEFAULT 0 | Days marked late |
| remarks | TEXT NULL | Notes |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |
| UNIQUE | (employee_id, month, year) | One record per month |

**Computation:** Summarized from `prl_attendance_logs` + `prl_leave_applications` (approved). Used by `PayrollComputeService` for LOP calculation.

#### 4.10 prl_statutory_configs
*(Same as v2)*

#### 4.11 prl_employee_statutory_details
*(Same as v2 — employee_id → `sch_employees`)*

#### 4.12 prl_category_statutory_config (NEW — replaces non-existent `sch_employee_groups`)
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| staff_category_id | INT UNSIGNED FK | FK → **`sch_categories`** (existing staff categories) |
| is_pf_applicable | TINYINT(1) DEFAULT 1 | PF deduction applies to this category |
| is_esi_applicable | TINYINT(1) DEFAULT 0 | ESI deduction applies |
| is_pt_applicable | TINYINT(1) DEFAULT 1 | Professional Tax applies |
| default_salary_structure_id | BIGINT UNSIGNED NULL FK | FK → `prl_salary_structures` (default for category) |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |
| UNIQUE | (staff_category_id) | One config per category |

**Why this instead of `sch_employee_groups`:**
- `sch_categories` already defines staff groups (Teaching, Non-Teaching, etc.)
- `sch_leave_config` already references `sch_categories.id` via `staff_category_id`
- Creating `sch_employee_groups` would duplicate `sch_categories`
- `prl_category_statutory_config` extends the existing category system with payroll-specific flags

#### 4.13-4.17 Appraisal Tables (prefix `prl_`)
*(Same as v2)*

#### 4.18-4.19 Training Tables (prefix `prl_`)
*(Same as v2)*

---

## 5. Salary Computation Flow

```
1. Load Employee (sch_employees, with staff_category_id → sch_categories)
   → Load Salary Structure (prl_salary_structures via sch_employees.salary_structure_id)
   → Load Structure Items (prl_salary_structure_items → prl_pay_heads)
   → Load Statutory Config (prl_category_statutory_config for employee's staff_category_id)

2. Calculate Earnings (from pay heads)

3. Apply LOP:
   → Read prl_monthly_attendance for this employee/month/year
   → LOP days = lwp_days + absent_days
   → LOP amount = (Gross / total_working_days) × LOP_days
   → NOTE: sch_leave_types.is_paid determines if approved leave is LWP

4. Calculate Deductions:
   → PF: only if prl_category_statutory_config.is_pf_applicable = 1
   → ESI: only if prl_category_statutory_config.is_esi_applicable = 1
   → PT: only if prl_category_statutory_config.is_pt_applicable = 1
   → Rates from prl_statutory_configs

5. Net = Gross - Deductions - LOP

6. Post via Accounting VoucherServiceInterface → Payroll Journal Voucher
```

---

## 6. Business Rules

1. **One Payroll Per Month:** One `prl_payroll_runs` per (month, year)
2. **Monthly Attendance Prerequisite:** `prl_monthly_attendance` must be populated before payroll
3. **LOP from Leave Types:** `sch_leave_types.is_paid = 0` means those leave days count as LWP
4. **Leave Allocation from Config:** `prl_leave_balances.total_allocated` sourced from `sch_leave_config.total_allowed`
5. **Carry Forward Rules:** Governed by `sch_leave_config.carry_forward` and `max_carry_forward`
6. **Category Statutory:** PF/ESI/PT applicability per `prl_category_statutory_config` (extends `sch_categories`)
7. **PF Ceiling:** From `prl_statutory_configs` — configurable, not hardcoded
8. **ESI Ceiling:** From `prl_statutory_configs` — configurable
9. **Payroll Lock:** status='locked' prevents edits
10. **Voucher Posting:** ONE Payroll Journal Voucher per run via `VoucherServiceInterface`
11. **Half-Day Leave:** Only allowed if `sch_leave_types.allow_half_day = 1`
12. **Approval Required:** Only if `sch_leave_types.requires_approval = 1`
13. **No tenant_id:** Dedicated database per tenant
14. **sch_employees Reuse:** All employee_id FKs → `sch_employees.id`
15. **No sch_teachers table:** Use `sch_employees.is_teacher = 1`

---

## 7-9. Workflows, Integration Points, Reports

*(Same as v2 with these FK corrections:)*
- All `sch_departments` → **`sch_department`** (SINGULAR)
- All `sch_designations` → **`sch_designation`** (SINGULAR)
- `acc_employees` → **`sch_employees`** (enhanced)

---

## 10. Seed Data

### Category Statutory Config (5 records — in `prl_category_statutory_config`)
Maps to existing `sch_categories` where `applicable_for` IN ('STAFF','BOTH'):
| Category (from sch_categories) | PF | ESI | PT | Default Structure |
|-------------------------------|:---:|:---:|:---:|-------------------|
| Teaching Staff | Yes | No | Yes | Teaching Grade A |
| Non-Teaching Staff | Yes | Yes | Yes | Non-Teaching Grade |
| Administrative Staff | Yes | No | Yes | Admin Grade |
| Contract Staff | No | No | No | Contract Grade |
| Management | No | No | Yes | Management Grade |

### Pay Heads, Statutory Config
*(Same as v2)*

---

## 11. User Roles & Permissions

*(Same as v2)*

---

## 12. Dependencies — VERIFIED

| This Module Needs | From Module | Correct Table Name | Line # | Status |
|-------------------|------------|-------------------|--------|--------|
| Employees | SchoolSetup | `sch_employees` | 955 | Exists (enhanced) |
| Employee Profile | SchoolSetup | `sch_employees_profile` | 984 | Exists |
| Staff Categories | SchoolSetup | `sch_categories` | 584 | Exists |
| Leave Types | SchoolSetup | `sch_leave_types` | 564 | Exists |
| Leave Config | SchoolSetup | `sch_leave_config` | 602 | Exists |
| Attendance Types | SchoolSetup | `sch_attendance_types` | 543 | Exists |
| Departments | SchoolSetup | **`sch_department`** | 476 | Exists (SINGULAR) |
| Designations | SchoolSetup | **`sch_designation`** | 486 | Exists (SINGULAR) |
| Teacher Profile | SchoolSetup | **`sch_teacher_profile`** | 1035 | Exists (SINGULAR) |
| Financial Year | Accounting | `acc_financial_years` | NEW | New |
| Ledgers | Accounting | `acc_ledgers` | NEW | New (restructured) |
| Voucher Posting | Accounting | `VoucherServiceInterface` | N/A | Interface |
| Users | System | `sys_users` | 87 | Exists |

> **Does NOT depend on:** ~~`sch_teachers`~~ (doesn't exist), ~~`sch_employee_groups`~~ (doesn't exist), ~~`sch_employee_attendance`~~ (doesn't exist)

---

## 13. Controllers & Services

### Controllers (11)
PayHeadController, SalaryStructureController, EmployeeSalaryController, PayrollController, AttendanceController, LeaveApplicationController, StatutoryConfigController, CategoryStatutoryConfigController, AppraisalController, TrainingController, PrlReportController, PrlDashboardController

### Services (6)
PayrollComputeService, StatutoryCalcService, LeaveApplicationService, AttendanceSyncService, AppraisalService, PayslipPdfService

---

## 14. sch_employees Enhancement (ALTER TABLE)

| New Column | Type | Description |
|------------|------|-------------|
| is_active | TINYINT(1) DEFAULT 1 | Missing from current DDL |
| created_by | BIGINT UNSIGNED NULL | Missing from current DDL |
| staff_category_id | INT UNSIGNED NULL FK | FK → `sch_categories` (which staff group — matches `sch_leave_config`) |
| ledger_id | BIGINT UNSIGNED NULL FK | FK → `acc_ledgers` (salary payable auto-ledger) |
| salary_structure_id | BIGINT UNSIGNED NULL FK | FK → `prl_salary_structures` |
| bank_name | VARCHAR(100) NULL | Salary bank |
| bank_account_number | VARCHAR(50) NULL | Bank account |
| bank_ifsc | VARCHAR(20) NULL | IFSC code |
| pf_number | VARCHAR(30) NULL | PF account number |
| esi_number | VARCHAR(30) NULL | ESI number |
| uan | VARCHAR(20) NULL | Universal Account Number |
| pan | VARCHAR(15) NULL | PAN number |
| ctc_monthly | DECIMAL(15,2) NULL | Monthly CTC |
| date_of_leaving | DATE NULL | Relieving date |

> Migration must use `Schema::hasColumn()` guard.

---

## 15. Table Summary — VERIFIED

| Category | Count | Tables | Status |
|----------|-------|--------|--------|
| Payroll Core | 5 | prl_pay_heads, prl_salary_structures, prl_salary_structure_items, prl_payroll_runs, prl_payroll_entries | All NEW |
| HR Leave | 3 | prl_leave_applications, prl_leave_balances, prl_attendance_logs | All NEW |
| HR Monthly | 1 | **prl_monthly_attendance** | **NEW** (was incorrectly `sch_employee_attendance`) |
| HR Statutory | 3 | prl_statutory_configs, prl_employee_statutory_details, **prl_category_statutory_config** | All NEW (last one replaces `sch_employee_groups`) |
| HR Appraisal | 5 | prl_appraisal_templates, _kpis_jnt, _cycles, prl_appraisals, _scores | All NEW |
| HR Training | 2 | prl_training_programs, prl_training_enrollments_jnt | All NEW |
| Enhanced | 1 | `sch_employees` (ALTER TABLE — 14 new columns) | Existing |
| Reused | 8 | sch_categories, sch_leave_types, sch_leave_config, sch_attendance_types, sch_department, sch_designation, sch_teacher_profile, sch_employees_profile | Existing — no changes |
| **Total new `prl_` tables** | **19** | | |

### Duplication Check — CLEAN
- No `prl_` table duplicates any existing table in `tenant_db_v2.sql`
- `prl_category_statutory_config` **extends** `sch_categories` (not duplicates it)
- `prl_leave_applications`/`prl_leave_balances` are runtime tables, not config — no overlap with `sch_leave_config`
- `prl_monthly_attendance` is a summary table — no overlap with `sch_attendance_types` (which is just code definitions)
- No overlap with `acc_*` or `inv_*` tables
