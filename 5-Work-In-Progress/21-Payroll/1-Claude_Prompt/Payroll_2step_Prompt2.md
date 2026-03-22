# PRL — Payroll Module Development Lifecycle Prompt

**Purpose:** This is a single consolidated prompt to build the "Feature Specification", "Complete Development Plan" & "Database Schema Design" for Payroll module. Execute this file in Claude and work through each phase sequentially. Claude will stop after each phase for your review and confirmation.

**Developer:** Brijesh | **Branch:** Brijesh_Finance

---

## DEFAULT PATHS :
Read "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md"

## Rules
- If any Path is missing in `paths.md` then find that in `CONFIGURATION` section below.
- If any variable exists at both place, in `paths.md` & in `CONFIGURATION` section also, then consider `CONFIGURATION` section Variable.

---

## CONFIGURATION :

```
MODULE_CODE       = PRL
MODULE            = Payroll
MODULE_DIR        = Modules/Payroll/
APP_REPO          = prime_ai_tarun
BRANCH            = Brijesh_Finance
RBS_MODULE_CODE   = P
DB_TABLE_PREFIX   = prl_
DATABASE_NAME     = tenant_db

OUTPUT_REPO       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
OUTPUT_DIR_A      = {OUTPUT_REPO}/1-DDL_Tenant_Modules/41-Payroll/DDL
OUTPUT_DIR_B      = {OUTPUT_REPO}/1-DDL_Tenant_Modules/21-Payroll/DDL
OUTPUT_DIR_C      = {OUTPUT_REPO}/1-DDL_Tenant_Modules/21-Payroll/DDL
OUTPUT_DIR_D      = {OUTPUT_REPO}/1-DDL_Tenant_Modules/21-Payroll/DDL

OTHER_OUTPUT_DIR  = {OUTPUT_REPO}/5-Work-In-Progress/21-Payroll/2-Claude_Plan
MIGRATION_DIR     = prime_ai_tarun/database/migrations/tenant
REQUIREMENT_FILE  = {OUTPUT_REPO}/1-DDL_Tenant_Modules/21-Payroll/Claude_Plan/Payroll_Requirement_v4.md
PLAN_FILE         = {OUTPUT_REPO}/1-DDL_Tenant_Modules/20-Account/Claude_Plan/Initial_Plan_v4.md
RBS_FILE          = 3-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v2.0.md
DDL_DIR           = {OUTPUT_REPO}/1-DDL_Tenant_Modules/21-Payroll/DDL
PERMISSION_GATE   = payroll.resource.action
FEATURE_FILE      = PRL_FeatureSpec.md
DEV_PLAN_FILE     = PRL_Dev_Plan.md
DDL_FILE_NAME     = PRL_DDL_v1.sql
```

---

## HOW TO USE THIS PROMPT

1. Execute this document into a new Claude conversation
2. Tell Claude: **"Start Phase 1"**
3. Claude will read the required files, generate the output, and STOP
4. You review the output, give feedback or confirm: **"Approved. Proceed to Phase 2"**
5. Repeat for all the phases

---

## KEY CONTEXT FOR PAYROLL MODULE

### What This Module Does
The Payroll module (`Modules/Payroll/`) manages **Indian school staff salary processing** — from pay head definitions and salary structures through monthly payroll computation, statutory deductions (PF/ESI/PT/TDS), and payslip generation. It also handles leave management, daily attendance, performance appraisals, and staff training.

### Architecture
- Payroll is a **separate Laravel module** — NOT part of Accounting
- It **consumes** the Accounting module's `VoucherServiceInterface` to post payroll journal vouchers
- It **reuses** existing SchoolSetup tables (never duplicates them)
- All new tables use `prl_` prefix (19 tables)
- Dedicated database per tenant — NO `tenant_id` column

### Tables Summary
| Category | Count | New/Existing |
|----------|-------|-------------|
| Payroll Core (`prl_`) | 5 | prl_pay_heads, prl_salary_structures, prl_salary_structure_items, prl_payroll_runs, prl_payroll_entries |
| Leave & Attendance (`prl_`) | 4 | prl_leave_applications, prl_leave_balances, prl_attendance_logs, prl_monthly_attendance |
| Statutory (`prl_`) | 3 | prl_statutory_configs, prl_employee_statutory_details, prl_category_statutory_config |
| Appraisal (`prl_`) | 5 | prl_appraisal_templates, _template_kpis_jnt, _cycles, prl_appraisals, _scores |
| Training (`prl_`) | 2 | prl_training_programs, prl_training_enrollments_jnt |
| **Total new `prl_` tables** | **19** | |
| Existing tables REUSED | 8 | sch_employees (enhanced by Accounting ALTER), sch_categories, sch_leave_types, sch_leave_config, sch_attendance_types, sch_department, sch_designation, sch_teacher_profile |

### Critical Design Decisions
1. **`sch_employees` is already enhanced** by Accounting module's ALTER TABLE (14 cols: ledger_id, salary_structure_id, staff_category_id, bank details, statutory IDs, ctc_monthly, date_of_leaving). Payroll does NOT create a separate employee table.
2. **`sch_categories`** serves as employee grouping. Payroll extends it with `prl_category_statutory_config` (PF/ESI/PT flags per category) instead of creating a duplicate `sch_employee_groups`.
3. **`prl_monthly_attendance`** is a NEW table (replaces non-existent `sch_employee_attendance`).
4. **`sch_leave_types`** (is_paid, requires_approval, allow_half_day) and **`sch_leave_config`** (total_allowed, carry_forward per category per year) are EXISTING tables — Payroll reads from them, never modifies.
5. **Leave balance initialization:** `prl_leave_balances.total_allocated` sourced from `sch_leave_config.total_allowed` at start of academic year.

### Cross-Module Integration
- **Payroll → Accounting:** `PayrollApproved` event → VoucherServiceInterface creates Payroll Journal Voucher:
  ```
  Dr  Salary Expense (by dept cost center)  ₹Gross
  Dr  Employer PF Contribution              ₹PF_employer
  Dr  Employer ESI Contribution             ₹ESI_employer
  Cr  PF Payable                            ₹(PF_emp + PF_employer)
  Cr  ESI Payable                           ₹(ESI_emp + ESI_employer)
  Cr  TDS Payable                           ₹TDS
  Cr  PT Payable                            ₹PT
  Cr  Salary Payable (per employee ledger)  ₹Net
  ```
- **SchoolSetup → Payroll:** sch_employees, sch_categories, sch_leave_types, sch_leave_config, sch_department
- **Accounting → Payroll:** acc_financial_years (FK on payroll runs), acc_ledgers (employee salary ledger)

---

## PHASE 1 — Requirements, Feature Specification & Development Plan

### Phase 1 Input Files
Read these files BEFORE generating output:
1. `{REQUIREMENT_FILE}` — Complete Payroll Module requirement (v4, fully independent)
2. `{PLAN_FILE}` — Initial plan with architecture and table summary
3. `{RBS_FILE}` — Find Module P section (line 3431, 46 sub-tasks: P1-P7)
4. `AI_Brain/memory/project-context.md` — Project context
5. `AI_Brain/memory/modules-map.md` — Existing modules (avoid duplication)
6. `AI_Brain/agents/business-analyst.md` — BA agent instructions
7. `databases/0-DDL_Masters/tenant_db_v2.sql` — Verify existing sch_ tables (lines 564-617 for leave, line 584 for categories, line 955 for employees)

### Phase 1 Tasks:
**Task 1A:** Generate a comprehensive Feature Specification for the Payroll Module.
**Task 1B:** Generate a Detailed Development Plan for the Payroll Module.

**Module:** Payroll
**RBS Module Code:** P — HR & Staff Management (46 sub-tasks: P1-P7)
**Table Prefix:** `prl_`
**Database:** tenant_db (dedicated per tenant — no tenant_id)

**Description:** The Payroll module manages Indian school staff salary processing including:
- **Pay Heads:** Earnings (Basic, DA, HRA, Conveyance, Special Allowance, Overtime, Bonus) and Deductions (PF, ESI, PT, TDS, Advance Recovery, Loan EMI) and Employer Contributions (PF Employer, ESI Employer)
- **Salary Structures:** Pay grade templates with component mapping
- **Monthly Payroll Run:** Compute → Review → Approve → Post (creates Journal Voucher in Accounting)
- **LOP Calculation:** Based on prl_monthly_attendance + approved leave (sch_leave_types.is_paid determines LWP)
- **Statutory Compliance:** PF (12%/12%, ceiling ₹15K), ESI (0.75%/3.25%, ceiling ₹21K), PT (state slabs), TDS (income tax slabs)
- **Leave Management:** Applications, balance tracking, carry forward (rules from sch_leave_config)
- **Attendance:** Daily logs + monthly summary for payroll
- **Performance Appraisal:** KPI templates, cycles, self-assessment + reviewer scoring
- **Staff Training:** Program enrollment and feedback
- **Payslip PDF:** Individual employee payslip via DomPDF

**No wireframes.** Generate the feature specification from:
- `Payroll_Requirement_v4.md` (19 tables, 11 controllers, 6 services — fully self-contained)
- `Initial_Plan_v4.md` (architecture, integration points, sch_ table verification)
- RBS Module P sub-tasks (P1-P7, 46 sub-tasks)
- Indian K-12 school domain knowledge (statutory rules, CTC structure)
- Patterns from existing Prime-AI modules (especially Vendor for CRUD pattern)

**Generate Feature Spec (`PRL_FeatureSpec.md`):**
1. Entity list — all 19 new `prl_` tables + 8 reused `sch_` tables with columns, types, relationships
2. Entity Relationship Diagram (text-based) — showing prl_ tables + cross-module FKs
3. Business rules — validation rules, cascade behaviors, status workflows (payroll run, leave application, appraisal)
4. Salary Computation Flow — step-by-step from CTC → Gross → Deductions → Net → Voucher
5. Permission list — all Gate permissions in `payroll.resource.action` format
6. Dependencies — which existing modules/tables this connects to (with DDL line numbers)
7. Integration events — PayrollApproved → Accounting, Leave → LOP, Attendance → Payroll

**Generate Dev Plan (`PRL_Dev_Plan.md`):**
1. Phase breakdown (Phases 3-9 from Development Lifecycle Blueprint)
2. Controller list with methods per controller (11 controllers)
3. Service list with key methods (6 services)
4. FormRequest list (~10 Store/Update pairs)
5. View/Blade file list (estimated ~35 files)
6. Seeder execution order
7. Testing strategy (unit + feature test counts)
8. Estimated timeline per phase

Do NOT generate screen layouts yet — that comes in Phase 3.

### Phase 1 Output Files
| File | Location |
|------|----------|
| `PRL_FeatureSpec.md` | `{OTHER_OUTPUT_DIR}/PRL_FeatureSpec.md` |
| `PRL_Dev_Plan.md` | `{OTHER_OUTPUT_DIR}/PRL_Dev_Plan.md` |

### Phase 1 Quality Gate
- [ ] Every RBS sub-task (P1-P7, 46 total) maps to at least one entity/column
- [ ] All 19 `prl_` table relationships (FK) are defined
- [ ] All 8 reused `sch_` tables listed with correct SINGULAR names (`sch_department`, `sch_designation`, `sch_teacher_profile`)
- [ ] Table names use `prl_` prefix convention (NOT `acc_` or `hr_`)
- [ ] `prl_category_statutory_config` correctly extends `sch_categories` (not duplicates it)
- [ ] `prl_monthly_attendance` correctly replaces non-existent `sch_employee_attendance`
- [ ] Salary computation flow documented (CTC → Earnings → LOP → Deductions → Net → Voucher)
- [ ] Leave balance initialization logic documented (from sch_leave_config.total_allowed)
- [ ] All cross-module integration events listed (PayrollApproved → Accounting)
- [ ] Business rules include: one payroll per month, attendance prerequisite, PF/ESI ceiling, payroll locking
- [ ] Dev Plan covers all remaining phases (3-9) with file counts

**After completing Phase 1, STOP and say:** "Phase 1 (Feature Specification + Dev Plan) complete. Output: `PRL_FeatureSpec.md` & `PRL_Dev_Plan.md`. Please review and confirm to proceed to Phase 2 (DDL Design)."

---

## PHASE 2 — Database Schema Design (DDL + Seeders)

### Phase 2 Input Files
1. `{OTHER_OUTPUT_DIR}/PRL_FeatureSpec.md` — Feature spec from Phase 1
2. `{REQUIREMENT_FILE}` — Required table schemas (Section 4 has all 19 table definitions)
3. `AI_Brain/agents/db-architect.md` — DB Architect agent instructions
4. `databases/0-DDL_Masters/tenant_db_v2.sql` — Existing schema (verify sch_ tables, check for duplicates)
5. `databases/1-DDL_Tenant_Modules/20-Account/DDL/ACC_DDL_v1.sql` — Accounting DDL (for cross-module FK reference: acc_financial_years, acc_vouchers, acc_ledgers)

### Phase 2A Task — Generate DDL
Generate the DDL SQL for all 19 new `prl_` tables in the Payroll Module.

**Rules (MUST follow):**
1. Table prefix: `prl_`
2. Every table MUST have: `id` (BIGINT UNSIGNED AUTO_INCREMENT), `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
3. Index ALL foreign keys
4. Junction tables suffix: `_jnt`
5. JSON columns suffix: `_json`
6. Boolean columns prefix: `is_` or `has_`
7. Use `BIGINT UNSIGNED` for all IDs (except FKs to sch_leave_types/sch_categories which use `INT UNSIGNED`)
8. Add `COMMENT` on every column
9. Use InnoDB, utf8mb4_unicode_ci
10. Use `IF NOT EXISTS`
11. FK naming: `fk_prl_{table}_{column}`
12. **Do NOT recreate sch_employees** — it's already enhanced by Accounting migration
13. **Do NOT create sch_employee_groups** — use `prl_category_statutory_config` instead
14. **Do NOT create sch_employee_attendance** — use `prl_monthly_attendance` instead

**Cross-module FK references (tables from other modules):**
- `acc_financial_years` — referenced by `prl_payroll_runs.financial_year_id`
- `acc_vouchers` — referenced by `prl_payroll_runs.voucher_id`
- `acc_ledgers` — referenced by `prl_pay_heads.ledger_id`
- `sch_employees` — referenced by many prl_ tables via `employee_id`
- `sch_leave_types` — referenced by `prl_leave_applications.leave_type_id` and `prl_leave_balances.leave_type_id`
- `sch_categories` — referenced by `prl_category_statutory_config.staff_category_id`
- `sys_users` — referenced by `approved_by`, `created_by` columns

**Generate:**
1. DDL SQL file — all 19 CREATE TABLE statements with comments
2. Laravel Migration file — for `database/migrations/tenant/`
3. Table summary — one-line description of each table including its purpose and key FKs

### Phase 2B Task — Generate Seeders
Generate Laravel seeders (namespace `Modules\Payroll\Database\Seeders`):

1. **`PayHeadSeeder.php`** — 15 records:
   - 7 Earnings: Basic Salary (flat), DA (% of basic), HRA (% of basic, 25%), Conveyance (flat), Special Allowance (flat), Overtime (on_attendance), Bonus (flat)
   - 6 Deductions: PF Employee 12% (% of basic_da), ESI Employee 0.75% (% of gross), PT (computed/slab), TDS (computed/slab), Advance Recovery (flat), Loan EMI (flat)
   - 2 Employer Contributions: PF Employer 12% (% of basic_da), ESI Employer 3.25% (% of gross)
   - Each with: code (PAY_BASIC, DED_PF, EMP_PF, etc.), type, calculation_type, statutory_type, is_taxable, is_statutory, is_system=1, sequence

2. **`StatutoryConfigSeeder.php`** — 4 records:
   - PF: employee 12%, employer 12%, threshold ₹15,000
   - ESI: employee 0.75%, employer 3.25%, threshold ₹21,000
   - PT: slab_json with HP slabs [{min:0, max:10000, tax:0}, {min:10001, max:999999, tax:200}]
   - TDS: slab_json with old regime [{min:0, max:250000, rate:0}, {min:250001, max:500000, rate:5}, {min:500001, max:1000000, rate:20}, {min:1000001, max:999999999, rate:30}]

3. **`CategoryStatutoryConfigSeeder.php`** — 5 records:
   Maps to existing `sch_categories` (where applicable_for IN ('STAFF','BOTH')):
   - Teaching Staff: PF=Yes, ESI=No, PT=Yes
   - Non-Teaching Staff: PF=Yes, ESI=Yes, PT=Yes
   - Administrative Staff: PF=Yes, ESI=No, PT=Yes
   - Contract Staff: PF=No, ESI=No, PT=No
   - Management: PF=No, ESI=No, PT=Yes
   - Use `DB::table('sch_categories')->where('name', $name)->value('id')` for staff_category_id lookups

### Phase 2 Output Files
| File | Location |
|------|----------|
| `PRL_DDL_v1.sql` | `{DDL_DIR}/PRL_DDL_v1.sql` |
| `PRL_Migration.php` | `{DDL_OUTPUT_DIR}/PRL_Migration.php` |
| `PRL_Seeders/` | `{DDL_OUTPUT_DIR}/PRL_Seeders/` (3 seeder files) |
| `PRL_TableSummary.md` | `{DDL_OUTPUT_DIR}/PRL_TableSummary.md` |

### Phase 2 Quality Gate
- [ ] All 19 `prl_` tables from Payroll_Requirement_v4.md exist in DDL
- [ ] Foreign keys use correct `prl_` prefix (NOT `acc_` or `hr_`)
- [ ] Cross-module FKs correct: `prl_payroll_runs.financial_year_id` → `acc_financial_years`, `prl_payroll_runs.voucher_id` → `acc_vouchers`
- [ ] `prl_pay_heads.ledger_id` → `acc_ledgers` (expense/liability ledger in Accounting)
- [ ] `prl_leave_applications.leave_type_id` → `sch_leave_types` (INT UNSIGNED, not BIGINT)
- [ ] `prl_leave_balances` has UNIQUE (employee_id, leave_type_id, academic_year)
- [ ] `prl_payroll_runs` has UNIQUE (month, year)
- [ ] `prl_monthly_attendance` has UNIQUE (employee_id, month, year)
- [ ] `prl_category_statutory_config` has UNIQUE (staff_category_id)
- [ ] `prl_payroll_entries` has employee_id FK → `sch_employees` (NOT acc_employees — doesn't exist)
- [ ] Required columns (id, is_active, created_by, timestamps, deleted_at) on ALL 19 tables
- [ ] No `sch_employee_groups` table created (use prl_category_statutory_config instead)
- [ ] No `sch_employee_attendance` table created (use prl_monthly_attendance instead)
- [ ] PayHeadSeeder has all 15 records (7 earnings + 6 deductions + 2 employer contributions)
- [ ] StatutoryConfigSeeder has slab_json for PT and TDS

**After completing Phase 2, STOP and say:** "Phase 2 (DDL + Seeders) complete. Output: `PRL_DDL_v1.sql` + 3 seeders. Please review the DDL and confirm to proceed to Phase 3 (Screen Planning)."

---

## QUICK REFERENCE — Payroll Tables (19 new `prl_`)

| # | Table | Domain | Key FKs |
|---|-------|--------|---------|
| 1 | `prl_pay_heads` | Core | ledger_id→acc_ledgers |
| 2 | `prl_salary_structures` | Core | — |
| 3 | `prl_salary_structure_items` | Core | salary_structure_id, pay_head_id |
| 4 | `prl_payroll_runs` | Core | financial_year_id→acc_financial_years, voucher_id→acc_vouchers |
| 5 | `prl_payroll_entries` | Core | payroll_run_id, employee_id→sch_employees |
| 6 | `prl_leave_applications` | Leave | employee_id→sch_employees, leave_type_id→sch_leave_types |
| 7 | `prl_leave_balances` | Leave | employee_id→sch_employees, leave_type_id→sch_leave_types |
| 8 | `prl_attendance_logs` | Attendance | employee_id→sch_employees |
| 9 | `prl_monthly_attendance` | Attendance | employee_id→sch_employees |
| 10 | `prl_statutory_configs` | Statutory | — |
| 11 | `prl_employee_statutory_details` | Statutory | employee_id→sch_employees |
| 12 | `prl_category_statutory_config` | Statutory | staff_category_id→sch_categories |
| 13 | `prl_appraisal_templates` | Appraisal | — |
| 14 | `prl_appraisal_template_kpis_jnt` | Appraisal | template_id |
| 15 | `prl_appraisal_cycles` | Appraisal | template_id |
| 16 | `prl_appraisals` | Appraisal | cycle_id, employee_id→sch_employees, reviewer_id→sch_employees |
| 17 | `prl_appraisal_scores` | Appraisal | appraisal_id, template_kpi_id |
| 18 | `prl_training_programs` | Training | — |
| 19 | `prl_training_enrollments_jnt` | Training | training_program_id, employee_id→sch_employees |

### Existing Tables REUSED (verified against tenant_db_v2.sql — NO changes by Payroll)

| Table | Line # | Used For |
|-------|--------|----------|
| `sch_employees` | 955 | Employee master (enhanced by Accounting ALTER — 14 cols already added) |
| `sch_categories` | 584 | Staff grouping (applicable_for='STAFF'/'BOTH') |
| `sch_leave_types` | 564 | Leave types: code, name, is_paid, requires_approval, allow_half_day |
| `sch_leave_config` | 602 | Leave allocation: staff_category_id→sch_categories, total_allowed, carry_forward |
| `sch_attendance_types` | 543 | Attendance codes: P/A/L/H |
| `sch_department` | 476 | Department reference (SINGULAR name) |
| `sch_designation` | 486 | Designation reference (SINGULAR name) |
| `sch_teacher_profile` | 1035 | Teacher-specific data (SINGULAR name) |
