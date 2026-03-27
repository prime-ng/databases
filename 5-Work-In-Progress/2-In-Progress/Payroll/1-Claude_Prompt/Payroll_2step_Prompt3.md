# HRS — HR & Payroll Module Development Lifecycle Prompt (v3)

**Purpose:** Consolidated prompt to build 3 output files for the combined **HRS (HrStaff + Payroll)** module using `HRS_HrStaff_Requirement_v2.md` as the single source of truth. Execute phases sequentially; Claude stops after each for your review.

**Output Files:**
1. `HRS_FeatureSpec.md` — Feature Specification
2. `HRS_DDL_v1.sql` + Migration + Seeders — Database Schema Design
3. `HRS_Dev_Plan.md` — Complete Development Plan

**Developer:** Brijesh
**v3 Change:** Based on HRS_HrStaff_Requirement_v2.md (merged HR + Payroll). Replaces prl_* concept entirely.
Tables: `hrs_*` (HR layer, 23 tables) + `pay_*` (Payroll layer, 10 tables) = 33 new tables.

---

## DEFAULT PATHS

Read `{AI_BRAIN}/config/paths.md` — resolve all path variables from this file.

## Rules
- All paths come from `paths.md` unless overridden in CONFIGURATION below.
- If a variable exists in both `paths.md` and CONFIGURATION, the CONFIGURATION value wins.

---

## Repositories

```
DB_REPO        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
OLD_REPO       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
AI_BRAIN       = {OLD_REPO}/AI_Brain
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai_tarun
LARAVEL_CLAUDE = {LARAVEL_REPO}/.claude/rules
```

## CONFIGURATION

```
MODULE_CODE       = HRS
MODULE            = HrStaff
MODULE_DIR        = Modules/HrStaff/
BRANCH            = Brijesh_Main
RBS_MODULE_CODE   = C                              # Staff & HR in RBS v2 + PAY (merged)
DB_TABLE_PREFIX   = hrs_ and pay_                  # Dual prefix — both in same module
DATABASE_NAME     = tenant_db

OUTPUT_DIR        = {OLD_REPO}/5-Work-In-Progress/41-Payroll/2-Claude_Plan
MIGRATION_DIR     = {LARAVEL_REPO}/database/migrations/tenant
TENANT_DDL        = {DB_REPO}/1-Master_DDLs/tenant_db_v2.sql
REQUIREMENT_FILE  = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V2/HRS_HrStaff_Requirement_v2.md

FEATURE_FILE      = HRS_FeatureSpec.md
DDL_FILE_NAME     = HRS_DDL_v1.sql
DEV_PLAN_FILE     = HRS_Dev_Plan.md
```

---

## HOW TO USE THIS PROMPT

1. Paste this entire document into a new Claude conversation
2. Say: **"Start Phase 1"**
3. Claude reads the required files, generates output, and **STOPS**
4. Review the output; give feedback or say: **"Approved. Proceed to Phase 2"**
5. Repeat for Phase 3

---

## KEY CONTEXT — HRS (HR & PAYROLL) MODULE

### What This Module Does

HrStaff is the **complete HR workflow and payroll engine** for Prime-AI. It is a single Laravel module
(`Modules\HrStaff`) combining two tightly-coupled sub-systems:

**HR Layer (`hrs_*` tables):**
- Employment details: contract type, bank account (encrypted), emergency contacts
- Employee document repository with expiry reminders
- Leave management: type master, holiday calendar, balance init, application, 2-level approval, LOP reconciliation
- Statutory compliance: PF (UAN), ESI (IP number), TDS (PAN encrypted + declarations), Gratuity, PT
- Performance appraisal: KPI templates, cycles, self-appraisal, manager review, finalization
- Salary structure assignment — links each employee to a `pay_salary_structures` template
- Staff ID card generation (DomPDF, QR code)

**Payroll Layer (`pay_*` tables):**
- Salary component master (earnings / deductions / employer contributions)
- Salary structure templates with per-component formulas
- Monthly payroll run: initiate → compute → review → approve → lock (FSM)
- Payroll computation engine: gross earnings, LWP deduction, PF, ESI, PT, TDS, net pay
- Supplementary payroll runs for missed employees
- Payslip PDF (DomPDF, password-protected: `PAN_last4 + DDYYYY_of_DOB`)
- Bulk payslip email distribution
- Bank NEFT/RTGS file export (CSV + bank-specific formats)
- TDS monthly deduction + annual Form 16 generation
- PF ECR file (EPFO pipe-delimited format) + ESI challan export
- Appraisal-linked variable pay processing
- Payroll reports: salary register, bank summary, CTC analysis, trend

### Architecture Decisions
- **Single Laravel module** (`Modules\HrStaff`) — NO separate Payroll module. `prl_*` concept is deprecated.
- Stancl/tenancy v3.9 — dedicated DB per tenant — **NO `tenant_id` column** on any table.
- Route prefix: `hr-staff/` | Route name prefix: `hr-staff.`
- Accounting integration: loose coupling via `PayrollApproved` event — Accounting module listener creates Journal Voucher. HrStaff never writes to `acc_*` tables directly.
- `pay_payroll_runs.academic_year_id` → `sch_academic_years.id` (**NOT** acc_financial_years).
- `hrs_salary_assignments.pay_salary_structure_id` → `pay_salary_structures.id` — intentional cross-prefix FK within same module/DB.
- PAN and bank account number: Laravel `encrypt()` — never stored or logged in plaintext.

### Module Scale (v2)
| Artifact | Count |
|---|---|
| Controllers | ~20 (derived from routes in Section 7 of req spec) |
| Models | 📐 26 |
| Services | 📐 15 (Section 11 lists 15; req spec header says 13 — use actual count) |
| FormRequests | 📐 30 |
| Policies | 📐 13 |
| hrs_* tables | 23 (15 core + 8 auxiliary) |
| pay_* tables | 10 |
| **Total new tables** | **33** |
| Blade views (estimated) | ~110 |

### Complete Table Inventory

**hrs_* Core Tables (15):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 1 | `hrs_employment_details` | Employment | UNIQUE (employee_id) |
| 2 | `hrs_employment_history` | Employment | — |
| 3 | `hrs_employee_documents` | Documents | — |
| 4 | `hrs_leave_types` | Leave | UNIQUE (code) |
| 5 | `hrs_holiday_calendars` | Leave | — |
| 6 | `hrs_leave_policies` | Leave | — |
| 7 | `hrs_leave_balances` | Leave | UNIQUE (employee_id, leave_type_id, academic_year_id) |
| 8 | `hrs_leave_balance_adjustments` | Leave | — |
| 9 | `hrs_leave_applications` | Leave | — |
| 10 | `hrs_leave_approvals` | Leave | — |
| 11 | `hrs_pay_grades` | Salary | — |
| 12 | `hrs_salary_assignments` | Salary | cross-FK → pay_salary_structures |
| 13 | `hrs_compliance_records` | Compliance | UNIQUE (employee_id, compliance_type) |
| 14 | `hrs_appraisal_cycles` | Appraisal | — |
| 15 | `hrs_appraisals` | Appraisal | UNIQUE (cycle_id, employee_id) |

**hrs_* Auxiliary Tables (8):**
| # | Table | Purpose |
|---|---|---|
| 16 | `hrs_kpi_templates` | KPI template definitions |
| 17 | `hrs_kpi_template_items` | KPI items (weights must sum 100) |
| 18 | `hrs_lop_records` | LOP flag per employee per date |
| 19 | `hrs_id_card_templates` | ID card layout config |
| 20 | `hrs_pf_contribution_register` | Monthly PF computed amounts per employee |
| 21 | `hrs_esi_contribution_register` | Monthly ESI computed amounts per employee |
| 22 | `hrs_appraisal_increment_flags` | Appraisal→Payroll trigger (variable pay) |
| 23 | `hrs_pt_slabs` | State-wise profession tax slabs |

**pay_* Tables (10):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 1 | `pay_salary_components` | Structure | UNIQUE (code) |
| 2 | `pay_salary_structures` | Structure | — |
| 3 | `pay_salary_structure_components` | Structure | UNIQUE (structure_id, component_id) |
| 4 | `pay_payroll_runs` | Payroll | UNIQUE (payroll_month, run_type) for regular |
| 5 | `pay_payroll_run_details` | Payroll | UNIQUE (payroll_run_id, employee_id) |
| 6 | `pay_payroll_overrides` | Payroll | — |
| 7 | `pay_payslips` | Payslip | UNIQUE (run_detail_id) |
| 8 | `pay_tds_ledger` | TDS | UNIQUE (employee_id, financial_year, month) |
| 9 | `pay_form16` | TDS/Form16 | UNIQUE (employee_id, financial_year) |
| 10 | `pay_increment_policies` | Increment | — |

**Existing Tables REUSED (HrStaff reads from; never modifies schema):**
| Table | Source | HrStaff Usage |
|---|---|---|
| `sch_employees` | SchoolSetup | Employee master — base record |
| `sch_employee_profiles` | SchoolSetup | reporting_to, teacher-specific data |
| `sch_departments` | SchoolSetup | Department reference in compliance, reports |
| `sch_designations` | SchoolSetup | Designation reference |
| `sch_academic_years` | SchoolSetup | Leave balance and payroll year scoping |
| `sys_media` | System | Documents, payslips, ID cards (read+write via Media service) |
| `sys_activity_logs` | System | Audit trail (write-only) |
| `ntf_notifications` | Notification | Leave notifications, expiry alerts, payslip email dispatch |
| `att_staff_attendances` | Attendance | LOP reconciliation — **read-only cross-module** |

### Cross-Module Integration (Journal Voucher on Payroll Lock)
```
On PayrollApproved / PayrollLocked:
  Dr  Salary Expense (per dept cost centre)   ₹Gross
  Dr  Employer PF Contribution                ₹PF_employer
  Dr  Employer ESI Contribution               ₹ESI_employer
  Cr  PF Payable                              ₹(PF_emp + PF_employer)
  Cr  ESI Payable                             ₹(ESI_emp + ESI_employer)
  Cr  TDS Payable                             ₹TDS
  Cr  PT Payable                              ₹PT
  Cr  Salary Payable (per employee ledger)    ₹Net

Note: HrStaff fires the event. Accounting module owns the listener and writes to acc_*.
```

---

## PHASE 1 — Feature Specification

### Phase 1 Input Files
Read ALL these files in order before generating any output:

1. `{REQUIREMENT_FILE}` — **Primary and complete source** — HRS v2 requirement (46 FRs, Sections 1–16)
2. `{AI_BRAIN}/memory/project-context.md` — Project context and existing module list
3. `{AI_BRAIN}/memory/modules-map.md` — Existing module inventory (avoid duplication)
4. `{AI_BRAIN}/agents/business-analyst.md` — BA agent instructions (read if file exists)
5. `{TENANT_DDL}` — Verify actual column names for: sch_employees, sch_employee_profiles,
   sch_departments, sch_designations, sch_academic_years (use exact column names in spec)

### Phase 1 Task — Generate `HRS_FeatureSpec.md`

Generate a comprehensive feature specification document. Organise it into these 11 sections:

---

#### Section 1 — Module Identity & Scope
- Module code, namespace, route prefix, DB prefixes, module type
- In-scope items (HR sub-modules + Payroll sub-modules — verbatim from req v2 Section 3.1)
- Out-of-scope items (verbatim from req v2 Section 3.2)
- Module scale table (controller / model / service / FormRequest / policy / table counts)

#### Section 2 — Entity Inventory (All 33 Tables)
For each hrs_* and pay_* table, provide:
- Table name, short description (one line)
- Full column list: column name | data type | nullable | default | constraints | comment
- Unique constraints
- Indexes (list ALL FKs that need indexes, plus any other frequently filtered columns)
- Cross-module FK references clearly noted

Group tables by domain:
- **Employment** (hrs_employment_details, hrs_employment_history, hrs_employee_documents, hrs_id_card_templates)
- **Leave Management** (hrs_leave_types, hrs_holiday_calendars, hrs_leave_policies, hrs_leave_balances, hrs_leave_balance_adjustments, hrs_leave_applications, hrs_leave_approvals, hrs_lop_records)
- **Compliance & Salary Prep** (hrs_pay_grades, hrs_salary_assignments, hrs_compliance_records, hrs_pf_contribution_register, hrs_esi_contribution_register, hrs_pt_slabs)
- **Appraisal** (hrs_kpi_templates, hrs_kpi_template_items, hrs_appraisal_cycles, hrs_appraisals, hrs_appraisal_increment_flags)
- **Salary Structure** (pay_salary_components, pay_salary_structures, pay_salary_structure_components)
- **Payroll Run** (pay_payroll_runs, pay_payroll_run_details, pay_payroll_overrides)
- **Payslip & Distribution** (pay_payslips)
- **TDS & Form 16** (pay_tds_ledger, pay_form16)
- **Increment** (pay_increment_policies)

#### Section 3 — Entity Relationship Diagram (text-based)
Show all 33 tables grouped by layer (hrs_* vs pay_* vs sch_*/sys_* reads).
Use `→` for FK direction (child → parent).
Include cross-prefix FK: `hrs_salary_assignments.pay_salary_structure_id → pay_salary_structures.id`
Include cross-module FKs to sch_* tables.

#### Section 4 — Business Rules (35 rules)
For each rule, state:
- Rule ID (BR-HRS-001–024, BR-PAY-001–012)
- Rule text (from req v2 Sections 8.1–8.5)
- Which table/column it enforces
- Enforcement point: `service_layer` | `db_constraint` | `form_validation` | `model_event`

Critical payroll rules to emphasise:
- BR-PAY-003: Locked payroll is immutable — service-layer guard, not DB-only
- BR-PAY-006: TDS cannot go below 0 — shortfall carried to next month
- BR-PAY-010: LWP formula = `(gross_monthly / working_days_in_month) × lop_days`
- BR-PAY-011: Structure must include BASIC component
- BR-HRS-015: PAN and bank account never stored in plaintext

#### Section 5 — Workflow State Machines (3 FSMs)
For each FSM, provide:
- State diagram (ASCII/text format)
- Valid transitions with trigger condition
- Pre-conditions (checked before transition allowed)
- Side effects (DB writes, events fired, balance updates)

FSMs to document:
1. **Leave Application** — `pending → pending_l2 → approved / rejected / returned / cancelled`
   Side effects: balance.used_days +/-, ntf_notifications dispatch, sys_activity_logs write
2. **Payroll Run** — `draft → computing → computed → reviewing → approved → locked`
   Pre-conditions before COMPUTING: all LOP confirmed, all employees have salary assignment, no existing regular run for month
   On LOCKED: PayrollApproved event, pf/esi registers status update
3. **Appraisal Cycle + Appraisal** — `cycle: draft→active→closed; appraisal: draft→submitted→reviewed→finalized`
   On finalized: hrs_appraisal_increment_flags created; AppraisalFinalized event fires

#### Section 6 — Functional Requirements Summary (46 FRs)
For each FR-HRS-001 to FR-HRS-046:
| FR ID | Name | Sub-Module | Tables Used | Key Validations | Related BRs | Depends On |
|---|---|---|---|---|---|---|

Group by sub-module (C1, C2+C3, C4a, C4b, C8, P1–P8 per req v2 Section 4).

#### Section 7 — Permission Matrix (all 25 permissions)
| Permission String | HR Mgr | Payroll Mgr | Principal | HOD | Employee | Accountant |
|---|---|---|---|---|---|---|

Include:
- `hrs.*` permissions (13 permissions from req v2 Section 10.1)
- `pay.*` permissions (12 permissions from req v2 Section 10.1)
- Which controller method checks each permission
- Which Policy class enforces it (13 policies from req v2 Section 10.2)

#### Section 8 — Service Architecture (all 15 services)
For each service from req v2 Section 11:
```
Service:     ClassName
File:        app/Services/ClassName.php
Namespace:   Modules\HrStaff\app\Services
Depends on:  [other services it calls]
Fires:       [events it dispatches]

Key Methods:
  methodName(TypeHint $param): ReturnType
    └── description of what it does
```

Services to document:
1. EmploymentService — emp_code auto-generation (EMP/YYYY/NNN), employment detail CRUD, history logging
2. LeaveService — balance init, carry-forward logic, apply/cancel, LOP reconciliation
3. LeaveApprovalService — route to correct level, dispatch notifications, update balances
4. HolidayService — calendar CRUD, working-days calculation between two dates
5. SalaryAssignmentService — assign/revise structure, validate CTC vs pay_grade, history
6. ComplianceService — PF/ESI/TDS/Gratuity/PT record management, contribution registers, register export
7. AppraisalService — cycle management, form routing, weighted rating computation, increment flags
8. IdCardService — DomPDF ID card, QR code generation, sys_media storage
9. SalaryStructureService — component CRUD, structure template CRUD, CTC breakdown preview
10. PayrollComputationService — main engine: `computeRun()`, `computeEmployee()`, `recomputeEmployee()`
11. TdsComputationService — projected annual income, old/new regime slabs, monthly TDS, Form 16
12. PayrollRunService — run lifecycle (initiate → lock), supplementary run, pre-condition checks
13. PayslipService — single generate, bulk GeneratePayslipsJob, password logic, email
14. StatutoryExportService — bank NEFT file, PF ECR (EPFO format), ESI challan
15. IncrementService — appraisal-linked variable pay, ad-hoc revision, flag.status → processed

#### Section 9 — Integration Contracts (6 events)
For each event:
| Event | Fired By (service + when) | Listener | Payload | Action |
|---|---|---|---|---|
- LeaveApproved → NotificationService → Employee notification
- LeaveRejected → NotificationService → Employee notification
- DocumentExpiringSoon → Scheduled command → HR Manager notification (30 days before expiry)
- AppraisalFinalized → IncrementService → Create hrs_appraisal_increment_flags
- PayrollApproved → Accounting module → Creates Journal Voucher (salary expense entry)
- PayrollLocked → StatutoryExportService → Updates pf/esi register status to `submitted`

#### Section 10 — Non-Functional Requirements
From req v2 Section 5 (NFR-001 to NFR-015).
For each NFR, add an "Implementation Note" column explaining HOW it will be met in code:
- NFR-003 (payroll sync ≤100): ProcessPayrollJob dispatched only when employee_count > 100
- NFR-004 (bulk payslip queue): GeneratePayslipsJob with individual PDF generation per employee
- NFR-005 (PAN/bank encryption): Laravel `encrypt()` / `decrypt()` in service layer; never in raw SQL
- NFR-006 (signed URLs): `Storage::temporaryUrl()` for sys_media served files
- NFR-007 (payslip password): `PayslipService::getPasswordForEmployee()` — `PANlast4 + DDYYYY(DOB)`
- NFR-011 (audit logging): `sys_activity_logs` write in all approval/rejection/lock service methods

#### Section 11 — Test Plan Outline
From req v2 Section 14 (complete list):

**Feature Tests (Pest) — 15 test files, ~75 tests total:**
| File | Count | Key Scenarios |
|---|---|---|
(List all 15 files from req v2 Section 14.1 with count and scenarios)

**Unit Tests (PHPUnit) — 7 test files, ~30 tests total:**
| File | Count | Key Scenarios |
|---|---|---|
(List all 7 files from req v2 Section 14.2)

**Test Data:**
- Required seeders for test database
- Required factories (EmploymentDetailFactory, LeaveApplicationFactory, AppraisalFactory, PayrollRunFactory, PayrollRunDetailFactory)
- Mock strategy: `att_staff_attendances` mock for LOP tests; `Queue::fake()` for job tests; `Event::fake()` for integration tests

---

### Phase 1 Output Files
| File | Location |
|---|---|
| `HRS_FeatureSpec.md` | `{OUTPUT_DIR}/HRS_FeatureSpec.md` |

### Phase 1 Quality Gate
- [ ] All 33 new tables (23 hrs_* + 10 pay_*) appear in Section 2 entity inventory
- [ ] All 46 FRs (HRS-001 to HRS-046) appear in Section 6
- [ ] All 35 business rules (BR-HRS-001–024 + BR-PAY-001–012) in Section 4 with enforcement point
- [ ] All 3 FSMs documented with ASCII state diagram and side effects
- [ ] All 15 services listed with key method signatures in Section 8
- [ ] All 6 integration events documented with payload in Section 9
- [ ] `hrs_salary_assignments.pay_salary_structure_id → pay_salary_structures.id` correctly noted as intentional cross-prefix FK
- [ ] `pay_payroll_runs.academic_year_id → sch_academic_years.id` (NOT acc_financial_years — verify this)
- [ ] **No acc_* FK references** in any table definition
- [ ] **No prl_* references** anywhere in the document
- [ ] Permission matrix covers all 25 permissions across all 6 roles
- [ ] NFR-007 implementation note: payslip password = PANlast4 + DDYYYY of DOB
- [ ] All sch_* column names verified against tenant_db_v2.sql (use EXACT names from DDL)

**After Phase 1, STOP and say:**
"Phase 1 (Feature Specification) complete. Output saved to `{OUTPUT_DIR}/HRS_FeatureSpec.md`. Please review and say 'Approved. Proceed to Phase 2' to continue."

---

## PHASE 2 — Database Schema Design (DDL + Seeders)

### Phase 2 Input Files
1. `{OUTPUT_DIR}/HRS_FeatureSpec.md` — Entity inventory (Section 2) from Phase 1
2. `{REQUIREMENT_FILE}` — Section 6 (canonical column definitions for all 33 tables)
3. `{AI_BRAIN}/agents/db-architect.md` — DB Architect agent instructions (read if exists)
4. `{TENANT_DDL}` — Existing schema: verify sch_* table column names and data types; check no duplicate tables being created

### Phase 2A Task — Generate DDL (`HRS_DDL_v1.sql`)

Generate CREATE TABLE statements for all 33 tables. Produce one single SQL file.

**14 DDL Rules — all mandatory:**
1. Table prefix: `hrs_` for HR layer tables; `pay_` for Payroll layer tables — no mixing
2. Every table MUST include: `id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY`, `is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable'`, `created_by BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id'`, `updated_by BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id'`, `created_at TIMESTAMP NULL`, `updated_at TIMESTAMP NULL`, `deleted_at TIMESTAMP NULL COMMENT 'Soft delete'`
3. Index ALL foreign key columns — every FK column must have a KEY entry
4. Junction/bridge tables: use suffix `_jnt` (e.g. hrs_kpi_template_items uses no _jnt since it's not a pure junction, but pay_salary_structure_components is a junction)
5. JSON columns: suffix `_json` (e.g. emergency_contact_json, computation_json)
6. Boolean flag columns: prefix `is_` or `has_`
7. All IDs and FK references: `BIGINT UNSIGNED` (consistency with tenant_db convention)
8. Add COMMENT on every column — describe what it holds, valid values for ENUMs
9. Engine: `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`
10. Use `CREATE TABLE IF NOT EXISTS`
11. FK constraint naming: `fk_hrs_{tableshort}_{column}` for hrs_ tables; `fk_pay_{tableshort}_{column}` for pay_ tables
12. **Do NOT recreate sch_* tables** — reference via FK only
13. **No `tenant_id` column** — stancl/tenancy v3.9 uses separate DB per tenant
14. **`hrs_compliance_records.reference_number`**: use `VARCHAR(100)` — stores UAN / IP number / encrypted PAN string (not a fixed-length field)

**DDL Table Order (dependency-safe — define referenced tables before referencing tables):**

Layer 1 — No dependencies on other hrs_*/pay_* tables:
  hrs_kpi_templates, hrs_leave_types, hrs_id_card_templates,
  hrs_pay_grades, hrs_pt_slabs,
  pay_salary_components, pay_salary_structures

Layer 2 — Depends on Layer 1:
  hrs_kpi_template_items (→ hrs_kpi_templates),
  pay_salary_structure_components (→ pay_salary_structures + pay_salary_components)

Layer 3 — Depends on sch_* only:
  hrs_employment_details (→ sch_employees UNIQUE),
  hrs_employment_history (→ sch_employees),
  hrs_employee_documents (→ sch_employees + sys_media),
  hrs_leave_policies (academic_year_id nullable),
  hrs_holiday_calendars (→ sch_academic_years),
  hrs_compliance_records (→ sch_employees UNIQUE per type),
  hrs_pf_contribution_register (→ hrs_compliance_records),
  hrs_esi_contribution_register (→ hrs_compliance_records),
  hrs_lop_records (→ sch_employees)

Layer 4 — Depends on Layer 1 + sch_*:
  hrs_salary_assignments (→ sch_employees + pay_salary_structures + hrs_pay_grades),
  hrs_appraisal_cycles (→ sch_academic_years + hrs_kpi_templates),
  hrs_leave_balances (→ sch_employees + hrs_leave_types + sch_academic_years),
  hrs_leave_applications (→ sch_employees + hrs_leave_types + sch_academic_years),
  pay_payroll_runs (→ sch_academic_years; self-ref parent_run_id nullable)

Layer 5 — Depends on Layer 4:
  hrs_leave_balance_adjustments (→ hrs_leave_balances),
  hrs_leave_approvals (→ hrs_leave_applications + sch_employees),
  hrs_appraisals (→ hrs_appraisal_cycles + sch_employees),
  hrs_appraisal_increment_flags (→ hrs_appraisals + sch_employees + hrs_appraisal_cycles),
  pay_payroll_run_details (→ pay_payroll_runs + sch_employees + hrs_salary_assignments),
  pay_increment_policies (→ hrs_appraisal_cycles nullable)

Layer 6 — Depends on Layer 5:
  pay_payroll_overrides (→ pay_payroll_run_details),
  pay_payslips (→ pay_payroll_run_details + sch_employees + sys_media),
  pay_tds_ledger (→ sch_employees),
  pay_form16 (→ sch_employees + sys_media)

**Critical unique constraints to include:**
```sql
-- hrs_employment_details
UNIQUE KEY uq_hrs_emp_details_emp (employee_id)

-- hrs_leave_types
UNIQUE KEY uq_hrs_leave_type_code (code)

-- hrs_leave_balances
UNIQUE KEY uq_hrs_leave_bal (employee_id, leave_type_id, academic_year_id)

-- hrs_compliance_records
UNIQUE KEY uq_hrs_compliance (employee_id, compliance_type)

-- hrs_appraisals
UNIQUE KEY uq_hrs_appraisal (cycle_id, employee_id)

-- pay_salary_components
UNIQUE KEY uq_pay_component_code (code)

-- pay_salary_structure_components
UNIQUE KEY uq_pay_struct_comp (structure_id, component_id)

-- pay_payroll_runs (partial uniqueness enforced in service, not DB, since supplementary runs share payroll_month)
-- Add UNIQUE (payroll_month, run_type) to catch duplicates at DB level

-- pay_payroll_run_details
UNIQUE KEY uq_pay_run_detail (payroll_run_id, employee_id)

-- pay_payslips
UNIQUE KEY uq_pay_payslip_detail (run_detail_id)

-- pay_tds_ledger
UNIQUE KEY uq_pay_tds (employee_id, financial_year, month)

-- pay_form16
UNIQUE KEY uq_pay_form16 (employee_id, financial_year)
```

**ENUM values (exact, to match application code):**
```
hrs_employment_details.contract_type: 'permanent','contractual','probation','part_time','substitute'
hrs_leave_types.applicable_to: 'all','teaching','non_teaching'
hrs_leave_types.gender_restriction: 'all','male','female'
hrs_leave_applications.status: 'pending','pending_l2','approved','rejected','cancelled','returned'
hrs_leave_applications.half_day_session: 'first','second'
hrs_leave_approvals.action: 'approve','reject','return_for_clarification'
hrs_compliance_records.compliance_type: 'pf','esi','tds','gratuity','pt'
hrs_appraisal_cycles.appraisal_type: 'annual','mid_year','probation','confirmation'
hrs_appraisal_cycles.reviewer_mode: 'auto','manual'
hrs_appraisal_cycles.status: 'draft','active','closed'
hrs_appraisals.status: 'draft','submitted','reviewed','finalized'
hrs_appraisal_increment_flags.flag_status: 'pending','processed'
pay_salary_components.component_type: 'earning','deduction','employer_contribution'
pay_salary_components.calculation_type: 'fixed','percentage_of_basic','percentage_of_gross','statutory','manual'
pay_salary_structures.applicable_to: 'all','teaching','non_teaching','contractual'
pay_payroll_runs.run_type: 'regular','supplementary'
pay_payroll_runs.status: 'draft','computing','computed','reviewing','approved','locked'
pay_payroll_run_details.payment_status: 'pending','exported','paid','failed'
pay_payslips.email_status: 'not_sent','pending','sent','failed'
pay_increment_policies.increment_type: 'percentage','flat'
```

**File header comment to include:**
```sql
-- =============================================================================
-- HRS — HR & Payroll Module DDL
-- Module: HrStaff (Modules\HrStaff)
-- Table Prefixes: hrs_* (23 tables) + pay_* (10 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: [DATE]
-- Based on: HRS_HrStaff_Requirement_v2.md
-- =============================================================================
```

### Phase 2B Task — Generate Laravel Migration (`HRS_Migration.php`)

Single migration file for `database/migrations/tenant/YYYY_MM_DD_000000_create_hrs_and_pay_tables.php`.
- `up()`: creates all 33 tables in Layer 1 → Layer 6 dependency order using `Schema::create()`
- `down()`: drops all tables in reverse order (Layer 6 → Layer 1)
- Use `Blueprint` column helpers; match ENUM types with `->enum()`, JSON with `->json()`
- All FK constraints added in `up()` using `$table->foreign()`

### Phase 2C Task — Generate Seeders (7 files)

Namespace: `Modules\HrStaff\Database\Seeders`

**1. `HrsLeaveTypeSeeder.php`** — 7 records:
```
CL  (Casual Leave):     12d/yr, is_paid=1, carry_forward_days=0, half_day_allowed=1, applicable_to=all
EL  (Earned Leave):     15d/yr, is_paid=1, carry_forward_days=30, half_day_allowed=0, min_service_months=6
SL  (Sick Leave):       12d/yr, is_paid=1, carry_forward_days=0, requires_medical_cert=1, medical_cert_threshold=3
ML  (Maternity Leave):  180d/yr, is_paid=1, carry_forward_days=0, gender_restriction=female
PL  (Paternity Leave):  15d/yr, is_paid=1, carry_forward_days=0, gender_restriction=male
CO  (Compensatory Off): 0d/yr (granted ad-hoc), is_paid=1, carry_forward_days=7, half_day_allowed=1
LWP (Leave Without Pay):0d/yr cap, is_paid=0, carry_forward_days=0, applicable_to=all
```

**2. `HrsLeavePolicySeeder.php`** — 1 global default:
```
academic_year_id=NULL, max_backdated_days=3, min_advance_days=0, approval_levels=2, optional_holiday_count=2
```

**3. `HrsPtSlabSeeder.php`** — PT slabs for 3 states:
```
Himachal Pradesh (HP): [0–10000: ₹0] [10001+: ₹200]
Karnataka (KA):        [0–15000: ₹0] [15001+: ₹200]
Maharashtra (MH):      [0–7500: ₹0] [7501–10000: ₹175] [10001+: ₹200]
```
Use: `state_code`, `min_salary`, `max_salary`, `pt_amount` columns.

**4. `HrsIdCardTemplateSeeder.php`** — 1 default template:
```
name='Default', is_default=1
layout_json: {
  "fields": ["photo","name","designation","department","emp_code","qr_code"],
  "dimensions": {"width": "85.6mm", "height": "53.98mm"},
  "color_scheme": "blue"
}
```

**5. `PaySalaryComponentSeeder.php`** — 14 standard components:
```
Earnings (7):
  BASIC     — Basic Pay             — fixed         — is_taxable=1, display_order=1
  DA        — Dearness Allowance    — %_of_basic    — default_value=0,  is_taxable=1, display_order=2
  HRA       — House Rent Allowance  — %_of_basic    — default_value=25, is_taxable=1, display_order=3
  CONV      — Conveyance Allowance  — fixed         — is_taxable=1, display_order=4
  MEDICAL   — Medical Allowance     — fixed         — is_taxable=1, display_order=5
  LTA       — Leave Travel Allow.   — fixed         — is_taxable=1, display_order=6
  SPECIAL   — Special Allowance     — fixed         — is_taxable=1, display_order=7

Deductions (5):
  PF_EMP    — PF Employee (12%)     — statutory     — is_statutory=1, is_taxable=0, display_order=10
  ESI_EMP   — ESI Employee (0.75%)  — statutory     — is_statutory=1, is_taxable=0, display_order=11
  PT        — Profession Tax        — statutory     — is_statutory=1, is_taxable=0, display_order=12
  TDS       — Income Tax (TDS)      — statutory     — is_statutory=1, is_taxable=0, display_order=13
  LWP_DED   — Loss of Pay Deduction — manual        — is_statutory=0, is_taxable=0, display_order=14

Employer Contributions (2):
  PF_ERR    — PF Employer (12%)     — statutory     — is_statutory=1, component_type=employer_contribution, display_order=20
  ESI_ERR   — ESI Employer (3.25%)  — statutory     — is_statutory=1, component_type=employer_contribution, display_order=21
```

**6. `PaySalaryStructureSeeder.php`** — 3 default structures:
Each structure adds components via `pay_salary_structure_components`:
```
"Teaching Staff Structure"  (applicable_to=teaching):
  Mandatory: BASIC, PF_EMP, ESI_EMP, PT, TDS, PF_ERR, ESI_ERR
  Optional:  HRA(25%), DA, CONV, MEDICAL, LTA, SPECIAL

"Non-Teaching Structure"    (applicable_to=non_teaching):
  Same as Teaching Staff Structure

"Contractual Structure"     (applicable_to=contractual):
  Mandatory: BASIC, TDS, LWP_DED
  Optional:  CONV, SPECIAL
```

**7. `HrsSeederRunner.php`** (Master seeder, calls all in order):
```php
$this->call([
    HrsLeaveTypeSeeder::class,
    HrsLeavePolicySeeder::class,
    HrsPtSlabSeeder::class,
    HrsIdCardTemplateSeeder::class,
    PaySalaryComponentSeeder::class,
    PaySalaryStructureSeeder::class,
]);
```

### Phase 2 Output Files
| File | Location |
|---|---|
| `HRS_DDL_v1.sql` | `{OUTPUT_DIR}/HRS_DDL_v1.sql` |
| `HRS_Migration.php` | `{OUTPUT_DIR}/HRS_Migration.php` |
| `HRS_TableSummary.md` | `{OUTPUT_DIR}/HRS_TableSummary.md` |
| `Seeders/HrsLeaveTypeSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/HrsLeavePolicySeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/HrsPtSlabSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/HrsIdCardTemplateSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/PaySalaryComponentSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/PaySalaryStructureSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/HrsSeederRunner.php` | `{OUTPUT_DIR}/Seeders/` |

### Phase 2 Quality Gate
- [ ] All 23 hrs_* tables exist in DDL (15 core + 8 auxiliary from req v2 Section 6)
- [ ] All 10 pay_* tables exist in DDL
- [ ] Standard columns (id, is_active, created_by, updated_by, created_at, updated_at, deleted_at) on ALL 33 tables
- [ ] `hrs_salary_assignments.pay_salary_structure_id` → `pay_salary_structures.id` (cross-prefix FK — correct)
- [ ] `pay_payroll_runs.academic_year_id` → `sch_academic_years.id` (**NOT** acc_financial_years)
- [ ] **No `acc_*` FK references** in any table
- [ ] **No `prl_*` table references** anywhere
- [ ] **No `tenant_id` column** on any table
- [ ] All unique constraints listed above are present
- [ ] All ENUM columns use exact values from the ENUM list in Phase 2A instructions
- [ ] `hrs_employment_details.bank_account_number` is TEXT (encrypted value has variable length)
- [ ] `hrs_compliance_records.reference_number` is VARCHAR(100)
- [ ] `pay_payroll_run_details.computation_json` JSON column exists (full per-component breakdown)
- [ ] `pay_payroll_runs.parent_run_id` is nullable BIGINT UNSIGNED self-reference (for supplementary runs)
- [ ] All FK columns have corresponding KEY index
- [ ] FK naming follows `fk_hrs_` / `fk_pay_` convention
- [ ] PaySalaryComponentSeeder has all 14 components (7 earnings + 5 deductions + 2 employer contributions)
- [ ] PaySalaryStructureSeeder creates junction records in `pay_salary_structure_components`
- [ ] `HrsSeederRunner.php` calls all 6 seeders in correct dependency order
- [ ] `HRS_TableSummary.md` has one-line description for all 33 tables

**After Phase 2, STOP and say:**
"Phase 2 (Database Schema Design) complete. Output: `HRS_DDL_v1.sql` + Migration + 7 seeders. Please review and say 'Approved. Proceed to Phase 3' to continue."

---

## PHASE 3 — Complete Development Plan

### Phase 3 Input Files
1. `{OUTPUT_DIR}/HRS_FeatureSpec.md` — Services (Section 8), permissions (Section 7), tests (Section 11)
2. `{REQUIREMENT_FILE}` — Section 7 (routes), Section 13 (UI screens), Section 14 (tests), Section 15 (phases)
3. `{AI_BRAIN}/memory/modules-map.md` — Patterns from completed modules (especially naming conventions)

### Phase 3 Task — Generate `HRS_Dev_Plan.md`

Generate the complete implementation blueprint. Organise into 8 sections:

---

#### Section 1 — Controller Inventory

For each controller, provide:
| Controller Class | File Path | Methods | FR Coverage |
|---|---|---|---|

Derive controllers from req v2 Section 7 (routes). For each controller list:
- All public methods with HTTP method + URI + route name
- Which FormRequest each write method uses
- Which Policy / Gate permission is checked

Controllers to define (align to req v2 Section 7 route tables):
1. `EmploymentController` — show, store, update, history
2. `DocumentController` — index, store, destroy
3. `IdCardController` — show, generate
4. `LeaveTypeController` — index, store, show, update, destroy
5. `HolidayController` — index, store, show, update, destroy
6. `LeaveController` — policy (show/update), initializeBalances, balances
7. `LeaveApplicationController` — index, store, show, approve, reject, cancel
8. `LopController` — index, confirm
9. `PayGradeController` — index, store, show, update, destroy
10. `SalaryAssignmentController` — show, store, update, revision
11. `ComplianceController` — show, store, update, pfRegister, esiRegister
12. `SalaryComponentController` — index, store, show, update, destroy
13. `SalaryStructureController` — index, store, show, update, destroy, preview
14. `AppraisalController` — kpi templates CRUD + cycles CRUD + appraisals CRUD + submitSelf + submitReview + finalize
15. `PayrollController` — index, store, show, compute, details, override, submit, approve, lock, bankFile, markPaid
16. `PayslipController` — generate, generateAll, emailAll, downloadZip, myPayslips, download
17. `StatutoryController` — pfEcr, esiChallan
18. `Form16Controller` — index, generateAll, download
19. `IncrementController` — index, store, show, update, process
20. `PayrollReportController` — salaryRegister, bankSummary, ctcAnalysis, trend

#### Section 2 — Service Inventory (15 services)

For each service:
- Class name, file path, namespace
- Constructor dependencies (injected services/interfaces)
- All public methods with signature and 1-line description
- Events fired
- Other services called (dependency graph)

Include the payroll computation sequence as inline pseudocode in `PayrollComputationService`:
```
computeEmployee(PayrollRun $run, Employee $emp): PayrollRunDetail
  Step 1: Resolve hrs_salary_assignments (latest where effective_to_date IS NULL)
  Step 2: Calculate gross earnings per pay_salary_structure_components formula
  Step 3: LWP = (gross_monthly / working_days) × lop_days (from confirmed hrs_lop_records)
  Step 4: PF employee = 12% of basic_da if compliance.pf.applicable_flag = true
  Step 5: ESI employee = 0.75% of gross_after_lwp if gross ≤ ₹21,000 and compliance.esi.applicable = true
  Step 6: PT = slab lookup from hrs_pt_slabs (state from compliance.pt.details_json)
  Step 7: TDS = TdsComputationService::computeMonthlyTds() — projected annual method
  Step 8: net_pay = gross_after_lwp − pf_emp − esi_emp − pt − tds
  Write: pay_payroll_run_details row + pay_tds_ledger upsert
```

#### Section 3 — FormRequest Inventory (30 FormRequests)

For each FormRequest:
| Class | Controller Method | Key Validation Rules |
|---|---|---|

Group by controller. Aim for 30 total (1–2 per write operation per controller).
Key FormRequests to detail:
- `StoreLeaveApplicationRequest` — date range validation, balance check
- `ApproveLeaveRequest` — remarks required
- `StoreSalaryAssignmentRequest` — CTC within pay_grade min/max, structure must be active
- `StorePayrollRunRequest` — month format YYYY-MM, no duplicate regular run
- `OverridePayrollDetailRequest` — reason required (text, min 10 chars), field_name must be overridable
- `StoreIncrementPolicyRequest` — rating range must not overlap with other policies for same cycle

#### Section 4 — Blade View Inventory (~110 views)

List all blade views grouped by sub-module. For each view:
| View File | Route Name | Controller Method | Description |
|---|---|---|---|

Sub-modules and approximate view counts:
- Employment & Documents: ~8 views
- ID Cards: ~3 views
- Leave Management: ~15 views (type CRUD + calendar + balance matrix + application form + approval + LOP)
- Compliance: ~8 views
- Salary & Pay Grades: ~10 views
- Appraisal: ~12 views
- Salary Structure: ~8 views
- Payroll Runs: ~12 views (dashboard + run detail + review grid + compute status + approve/lock)
- Payslips: ~8 views (list + generate + email + self-service)
- Statutory Exports: ~4 views (PF ECR + ESI challan)
- Form 16: ~4 views
- Increments: ~6 views
- Payroll Reports: ~12 views (salary register + bank summary + CTC + trend + export)
- Shared partials: ~8 partials (modals, table headers, pagination, export buttons)

For each key screen from req v2 Section 13.1, document:
- Route name, view file path, key UI components (modals, tables, AJAX calls)
- Live CTC preview — salary structure builder uses `fetch()` to hit preview endpoint
- Payroll compute status polling — polls `/hr-staff/payroll/{run}/status` every 3 seconds
- Bulk payslip progress bar — polls GeneratePayslipsJob status

#### Section 5 — Complete Route List

Consolidate ALL routes from req v2 Section 7 into a single table:
| Method | URI | Route Name | Controller@method | Middleware | FR |
|---|---|---|---|---|---|

Group by section (7.1–7.8). Count total routes at the end.
Middleware on all routes: `['auth', 'tenant', 'EnsureTenantHasModule:HrStaff']`

#### Section 6 — Implementation Phases (from req v2 Section 15)

For each of the 6 phases, provide a detailed sprint plan:

**Phase 1 — HR Foundation (Sprint 1–2)**
FRs: HRS-001, 003, 005, 006, 008, 009, 010, 011
Files to create:
- Controllers: EmploymentController, DocumentController, LeaveTypeController, HolidayController, LeaveController, LeaveApplicationController
- Services: EmploymentService, LeaveService, LeaveApprovalService, HolidayService
- Models: EmploymentDetail, EmploymentHistory, EmployeeDocument, LeaveType, HolidayCalendar, LeavePolicy, LeaveBalance, LeaveBalanceAdjustment, LeaveApplication, LeaveApproval
- FormRequests: 10 (Store/Update pairs for each CRUD)
- Views: ~23 blade views
- Tests: LeaveApplicationTest, LeaveApprovalTest, LeaveBalanceTest (19 feature tests)

**Phase 2 — Compliance & Payroll Prep (Sprint 3–4)**
FRs: HRS-004, 012, 013, 014, 015, 016, 017, 018, 023, 024, 025
Files to create:
- Controllers: LopController, PayGradeController, SalaryAssignmentController, ComplianceController, SalaryComponentController, SalaryStructureController, IdCardController
- Services: SalaryAssignmentService, ComplianceService, IdCardService, SalaryStructureService
- Models: LopRecord, PayGrade, SalaryAssignment, ComplianceRecord, PfContributionRegister, EsiContributionRegister, PtSlab, SalaryComponent, SalaryStructure, SalaryStructureComponent
- FormRequests: 10
- Views: ~29 blade views
- Tests: SalaryAssignmentTest, ComplianceRecordTest, SalaryStructureTest (14 feature tests)

**Phase 3 — Payroll Engine (Sprint 5–6)**
FRs: HRS-026, 027, 028, 029, 030, 037
Files to create:
- Controllers: PayrollController (partial — through lock)
- Services: PayrollComputationService, TdsComputationService, PayrollRunService
- Jobs: ProcessPayrollJob
- Models: PayrollRun, PayrollRunDetail, PayrollOverride, TdsLedger
- FormRequests: 6
- Views: ~12 blade views (payroll dashboard, run detail, review grid, status)
- Tests: PayrollRunTest, TdsComputationTest, PayrollComputationUnitTest (22 tests)

**Phase 4 — Payslip, Statutory & Distribution (Sprint 7–8)**
FRs: HRS-031, 032, 033, 034, 035, 036, 039, 040
Files to create:
- Controllers: PayslipController, StatutoryController (add to PayrollController: bankFile, markPaid)
- Services: PayslipService, StatutoryExportService
- Jobs: GeneratePayslipsJob
- Models: Payslip
- FormRequests: 4
- Views: ~12 blade views
- Tests: PayslipGenerationTest, BankFileTest, PfEcrTest (11 feature tests)

**Phase 5 — Form 16, Increments & Reports (Sprint 9–10)**
FRs: HRS-038, 041, 042, 043, 044, 045, 046
Files to create:
- Controllers: Form16Controller, IncrementController, PayrollReportController
- Services: IncrementService (+ extend TdsComputationService::generateForm16())
- Jobs: GenerateForm16Job
- Models: Form16, IncrementPolicy
- FormRequests: 5
- Views: ~22 blade views (form16 + increments + 4 report views + charts)
- Tests: Form16Test, IncrementProcessingTest, TdsProjectionTest (13 tests)

**Phase 6 — Appraisal (Sprint 11–12)**
FRs: HRS-002, 007, 019, 020, 021, 022
Files to create:
- Controllers: AppraisalController
- Services: AppraisalService
- Models: KpiTemplate, KpiTemplateItem, AppraisalCycle, Appraisal, AppraisalIncrementFlag
- FormRequests: 5
- Views: ~12 blade views
- Tests: AppraisalTest, AppraisalRatingCalculatorTest (10 tests)

#### Section 7 — Seeder Execution Order

```
php artisan module:seed HrStaff --class=HrsSeederRunner
  ↓ HrsLeaveTypeSeeder       (no dependencies)
  ↓ HrsLeavePolicySeeder     (no dependencies)
  ↓ HrsPtSlabSeeder          (no dependencies)
  ↓ HrsIdCardTemplateSeeder  (no dependencies)
  ↓ PaySalaryComponentSeeder (no dependencies)
  ↓ PaySalaryStructureSeeder (depends on PaySalaryComponentSeeder — creates junction rows)
```

For test runs: use `HrsLeaveTypeSeeder` + `PaySalaryComponentSeeder` as minimum required seeders.

#### Section 8 — Testing Strategy

**Framework:** Pest for Feature tests; PHPUnit for Unit tests.

**Feature Test Setup:**
```php
uses(Tests\TestCase::class, RefreshDatabase::class);
// All feature tests use tenant DB refresh
// att_staff_attendances: mock with \Mockery or use factory
// Queue: Queue::fake() in payroll tests
// Events: Event::fake() in integration tests
```

**Minimum Test Coverage Targets:**
- Leave module: 100% of FSM transitions tested (each valid transition + each invalid transition blocked)
- Payroll computation: each computation step tested individually (unit) + full run tested (feature)
- Payroll run FSM: all 6 states tested, BR-PAY-003 (locked immutable) explicitly tested
- TDS: old regime, new regime, December recompute, negative TDS floor (BR-PAY-006)
- Payslip password: `PayslipPasswordTest` — format `PANlast4+DDYYYY` verified

**Feature Test File Summary (from req v2 Section 14.1):**
List all 15 test files with file path, test count, and key scenarios.

**Unit Test File Summary (from req v2 Section 14.2):**
List all 7 unit test files with file path, test count, and scenarios.

**Factory Requirements:**
```
EmploymentDetailFactory     — generates contract_type, encrypted bank details
LeaveApplicationFactory     — generates date ranges, valid leave_type_id
AppraisalFactory            — generates cycle_id, employee_id, valid rating data
PayrollRunFactory           — generates payroll_month (YYYY-MM), status=draft
PayrollRunDetailFactory     — generates all numeric fields, computation_json
```

---

### Phase 3 Output Files
| File | Location |
|---|---|
| `HRS_Dev_Plan.md` | `{OUTPUT_DIR}/HRS_Dev_Plan.md` |

### Phase 3 Quality Gate
- [ ] All 20 controllers listed with all methods
- [ ] All 15 services listed with at minimum 3 key method signatures each
- [ ] All 30 FormRequests listed with their key validation rules
- [ ] All 46 FRs (HRS-001 to HRS-046) appear in at least one implementation phase
- [ ] All 6 implementation phases have: FRs covered, files to create, test count
- [ ] Payroll computation pseudocode present in Section 2 (PayrollComputationService)
- [ ] Seeder execution order documented with dependency note
- [ ] Queue jobs documented: ProcessPayrollJob, GeneratePayslipsJob, GenerateForm16Job
- [ ] Route list consolidated with middleware and FR reference
- [ ] View count per sub-module totals approximately 110
- [ ] Test strategy includes Event::fake() and Queue::fake() guidance
- [ ] BR-PAY-003 (locked payroll immutable) test explicitly referenced

**After Phase 3, STOP and say:**
"Phase 3 (Development Plan) complete. Output: `HRS_Dev_Plan.md`. All 3 output files are ready:
1. `{OUTPUT_DIR}/HRS_FeatureSpec.md`
2. `{OUTPUT_DIR}/HRS_DDL_v1.sql` + Migration + 7 Seeders
3. `{OUTPUT_DIR}/HRS_Dev_Plan.md`
Development lifecycle for HRS module is ready to begin."

---

## QUICK REFERENCE — HRS Module Tables vs Controllers vs Services

| Domain | hrs_* / pay_* Tables | Controller | Service(s) |
|---|---|---|---|
| Employment | hrs_employment_details, hrs_employment_history, hrs_employee_documents | EmploymentController, DocumentController | EmploymentService |
| ID Card | hrs_id_card_templates | IdCardController | IdCardService |
| Leave | hrs_leave_types, hrs_holiday_calendars, hrs_leave_policies, hrs_leave_balances, hrs_leave_balance_adjustments, hrs_leave_applications, hrs_leave_approvals, hrs_lop_records | LeaveTypeController, HolidayController, LeaveController, LeaveApplicationController, LopController | LeaveService, LeaveApprovalService, HolidayService |
| Compliance | hrs_compliance_records, hrs_pf_contribution_register, hrs_esi_contribution_register, hrs_pt_slabs | ComplianceController | ComplianceService |
| Salary Prep | hrs_pay_grades, hrs_salary_assignments | PayGradeController, SalaryAssignmentController | SalaryAssignmentService |
| Appraisal | hrs_kpi_templates, hrs_kpi_template_items, hrs_appraisal_cycles, hrs_appraisals, hrs_appraisal_increment_flags | AppraisalController | AppraisalService |
| Salary Structure | pay_salary_components, pay_salary_structures, pay_salary_structure_components | SalaryComponentController, SalaryStructureController | SalaryStructureService |
| Payroll Run | pay_payroll_runs, pay_payroll_run_details, pay_payroll_overrides | PayrollController | PayrollRunService, PayrollComputationService, TdsComputationService |
| Payslip | pay_payslips | PayslipController | PayslipService |
| Statutory | (reads hrs_pf_contribution_register, hrs_esi_contribution_register) | StatutoryController | StatutoryExportService |
| TDS / Form 16 | pay_tds_ledger, pay_form16 | Form16Controller | TdsComputationService |
| Increment | pay_increment_policies | IncrementController | IncrementService |
| Reports | (reads all pay_* + hrs_salary_assignments) | PayrollReportController | — (direct queries) |
