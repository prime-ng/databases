# HRS — HR & Payroll Module Feature Specification
**Module Code:** HRS | **Namespace:** `Modules\HrStaff` | **Version:** 1.0
**Based on:** `HRS_HrStaff_Requirement_v2.md` (46 FRs) | **Date:** 2026-03-26
**DB Prefixes:** `hrs_*` (HR layer) + `pay_*` (Payroll layer) — both in same module

> **⚠️ DDL Correction vs Req Spec:**
> `sch_academic_years` does NOT exist in tenant_db_v2.sql.
> Actual table = `sch_org_academic_sessions_jnt` (SMALLINT UNSIGNED id).
> All `academic_year_id` FK columns in HRS/PAY tables reference `sch_org_academic_sessions_jnt`.
> `sch_employees.id` is **INT UNSIGNED** (not BIGINT) — FK columns referencing it must be INT UNSIGNED.
> `sch_department` and `sch_designation` are singular (no trailing 's').
> `sch_employees_profile` (with 's' on employees).
> `att_staff_attendances` does NOT exist yet — Attendance module pending; LOP reads are a stub.

---

## Table of Contents
1. [Module Identity & Scope](#1-module-identity--scope)
2. [Entity Inventory](#2-entity-inventory-all-33-tables)
3. [Entity Relationship Diagram](#3-entity-relationship-diagram)
4. [Business Rules](#4-business-rules-35-rules)
5. [Workflow State Machines](#5-workflow-state-machines)
6. [Functional Requirements Summary](#6-functional-requirements-summary-46-frs)
7. [Permission Matrix](#7-permission-matrix)
8. [Service Architecture](#8-service-architecture-15-services)
9. [Integration Contracts](#9-integration-contracts-6-events)
10. [Non-Functional Requirements](#10-non-functional-requirements)
11. [Test Plan Outline](#11-test-plan-outline)

---

## 1. Module Identity & Scope

### 1.1 Module Identity

| Property | Value |
|---|---|
| Module Code | HRS |
| Module Name | HrStaff |
| Laravel Namespace | `Modules\HrStaff` |
| Module Path | `Modules/HrStaff/` |
| Route Prefix | `hr-staff/` |
| Route Name Prefix | `hr-staff.` |
| DB Table Prefix (HR) | `hrs_*` |
| DB Table Prefix (Payroll) | `pay_*` |
| Module Type | Tenant (stancl/tenancy v3.9) |
| Registered In | `routes/tenant.php` |
| Multi-tenancy | Separate DB per tenant — NO `tenant_id` columns |

> **v2 Decision:** Payroll (previously planned as separate `prl_*` module) is merged into HrStaff. Both `hrs_*` and `pay_*` tables coexist in the same module and same tenant database.

### 1.2 Module Scale

| Artifact | Count |
|---|---|
| Controllers | ~20 (derived from routes — Section 7 of req spec) |
| Models | 📐 26 |
| Services | 15 |
| FormRequests | 📐 30 |
| Policies | 13 |
| `hrs_*` tables | 23 (15 core + 8 auxiliary) |
| `pay_*` tables | 10 |
| **Total new tables** | **33** |
| Blade views (est.) | ~110 |

### 1.3 In-Scope (v2 — HR + Payroll Combined)

**HR Sub-Modules:**
- Employee HR record extension (contract type, bank details, emergency contacts, employment history)
- Employee document repository (upload, categorise, expiry reminders)
- Leave type configuration, holiday calendar, leave balance management
- Leave application and multi-level approval workflow (HOD → Principal)
- Attendance-leave reconciliation and LOP flagging
- Pay grade master
- Salary structure assignment (employee ↔ structure mapping)
- Statutory compliance records: PF, ESI, TDS declarations, Gratuity, PT
- Performance appraisal: KPI templates, cycles, self-appraisal, manager review, finalization
- Staff ID card generation (QR code, DomPDF)
- HR reports: headcount, attrition, leave utilization, compliance status

**Payroll Sub-Modules (NEW in v2):**
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

### 1.4 Out of Scope (v2)

| Item | Owner Module |
|---|---|
| Actual PF/ESI remittance and bank payment processing | Finance/Accounting (`acc_*`) |
| Payroll Journal Voucher creation | Accounting — triggered by `PayrollApproved` event |
| Biometric device sync for attendance | Attendance (`att_*`) — pending module |
| Recruitment and applicant tracking | Future module |
| Staff mobile app portal | Future phase |
| Gratuity disbursement payment | Finance/Accounting (`acc_*`) |

---

## 2. Entity Inventory (All 33 Tables)

> **Standard columns on ALL tables** (not repeated in individual table definitions below):
> `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PK |
> `is_active` TINYINT(1) DEFAULT 1 |
> `created_by` BIGINT UNSIGNED NOT NULL |
> `updated_by` BIGINT UNSIGNED NOT NULL |
> `created_at` TIMESTAMP NULL |
> `updated_at` TIMESTAMP NULL |
> `deleted_at` TIMESTAMP NULL

> **FK type rule:** FKs to `sch_employees.id` → **INT UNSIGNED**.
> FKs to `sch_org_academic_sessions_jnt.id` → **SMALLINT UNSIGNED**.
> FKs to `sch_department.id` / `sch_designation.id` → **INT UNSIGNED**.
> Internal HRS/PAY FKs → **BIGINT UNSIGNED**.

---

### EMPLOYMENT DOMAIN

#### 2.1 `hrs_employment_details`
*One HR record extension per employee. Stores contract type, bank details, emergency contacts.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| employee_id | INT UNSIGNED | NO | — | UNIQUE, FK→sch_employees.id | One-to-one with sch_employees |
| contract_type | ENUM | NO | — | — | 'permanent','contractual','probation','part_time','substitute' |
| probation_end_date | DATE | YES | NULL | — | Relevant when contract_type=probation |
| confirmation_date | DATE | YES | NULL | — | Date contract was confirmed |
| notice_period_days | TINYINT UNSIGNED | NO | 30 | — | Notice period in days |
| bank_account_number | TEXT | YES | NULL | — | Laravel encrypt() — variable length encrypted value |
| bank_ifsc | VARCHAR(11) | YES | NULL | — | Bank IFSC code |
| bank_name | VARCHAR(100) | YES | NULL | — | Bank name |
| bank_branch | VARCHAR(100) | YES | NULL | — | Bank branch name |
| emergency_contact_json | JSON | YES | NULL | — | {name, relationship, phone, address} |
| previous_employer_json | JSON | YES | NULL | — | [{company, role, from_date, to_date}] |

**Indexes:** `KEY fk_hrs_empdet_empid (employee_id)`
**Unique:** `UNIQUE KEY uq_hrs_empdet_emp (employee_id)`

---

#### 2.2 `hrs_employment_history`
*Immutable audit trail of employment changes. One row per change event.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| employee_id | INT UNSIGNED | NO | — | FK→sch_employees.id | Employee this change belongs to |
| change_type | VARCHAR(50) | NO | — | — | 'contract_type','department','designation','pay_grade','salary_revision' |
| old_value | JSON | NO | — | — | Previous value(s) |
| new_value | JSON | NO | — | — | New value(s) |
| effective_date | DATE | NO | — | — | When the change took effect |
| changed_by | INT UNSIGNED | NO | — | FK→sch_employees.id | Who made the change |
| remarks | TEXT | YES | NULL | — | Optional explanation |

**Indexes:** `KEY fk_hrs_emphist_empid (employee_id)`, `KEY fk_hrs_emphist_changedby (changed_by)`

---

#### 2.3 `hrs_employee_documents`
*Employee document repository. Files stored in sys_media; this table stores metadata.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| employee_id | INT UNSIGNED | NO | — | FK→sch_employees.id | |
| document_type | VARCHAR(50) | NO | — | — | 'appointment_letter','increment_letter','transfer_letter','warning_letter','experience_certificate','id_proof','educational_certificate','medical_certificate','other' |
| document_name | VARCHAR(200) | NO | — | — | Human-readable label |
| media_id | BIGINT UNSIGNED | NO | — | FK→sys_media.id | Actual file reference |
| issued_date | DATE | YES | NULL | — | |
| expiry_date | DATE | YES | NULL | — | Trigger DocumentExpiringSoon event 30 days before |
| issued_by | VARCHAR(150) | YES | NULL | — | Institution or person name |
| remarks | TEXT | YES | NULL | — | |

**Indexes:** `KEY fk_hrs_empdoc_empid (employee_id)`, `KEY fk_hrs_empdoc_mediaid (media_id)`, `KEY idx_hrs_empdoc_expiry (expiry_date)`

---

#### 2.4 `hrs_id_card_templates`
*School-configurable ID card layout. One or more templates per school; one default.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| name | VARCHAR(150) | NO | — | — | Template name |
| layout_json | JSON | NO | — | — | Fields list, dimensions, color scheme, logo position |
| is_default | TINYINT(1) | NO | 0 | — | Only one default allowed (enforced in service) |

---

### LEAVE MANAGEMENT DOMAIN

#### 2.5 `hrs_leave_types`
*Configurable leave types per school. Pre-seeded with 7 defaults.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| code | VARCHAR(10) | NO | — | UNIQUE | 'CL','EL','SL','ML','PL','CO','LWP' |
| name | VARCHAR(100) | NO | — | — | e.g. 'Casual Leave' |
| days_per_year | DECIMAL(5,1) | NO | 0 | — | 0 for LWP and CO (granted ad-hoc) |
| carry_forward_days | TINYINT UNSIGNED | NO | 0 | — | 0 = no carry-forward |
| applicable_to | ENUM | NO | 'all' | — | 'all','teaching','non_teaching' |
| is_paid | TINYINT(1) | NO | 1 | — | 0 = unpaid (LWP) |
| requires_medical_cert | TINYINT(1) | NO | 0 | — | SL requires cert after threshold days |
| medical_cert_threshold_days | TINYINT UNSIGNED | NO | 3 | — | SL: cert needed if > this |
| half_day_allowed | TINYINT(1) | NO | 0 | — | |
| gender_restriction | ENUM | NO | 'all' | — | 'all','male','female' — ML=female, PL=male |
| min_service_months | TINYINT UNSIGNED | NO | 0 | — | EL typically requires 6 months service |
| max_consecutive_days | TINYINT UNSIGNED | YES | NULL | — | NULL = no limit |

**Unique:** `UNIQUE KEY uq_hrs_leavetype_code (code)`

---

#### 2.6 `hrs_holiday_calendars`
*School holiday calendar per academic year. Used to exclude holidays in leave day calculations.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| academic_year_id | SMALLINT UNSIGNED | NO | — | FK→sch_org_academic_sessions_jnt.id | |
| holiday_date | DATE | NO | — | — | |
| holiday_name | VARCHAR(150) | NO | — | — | |
| holiday_type | ENUM | NO | — | — | 'national','state','school','optional' |
| applicable_to | ENUM | NO | 'all' | — | 'all','teaching','non_teaching' |

**Indexes:** `KEY fk_hrs_holiday_ayid (academic_year_id)`, `KEY idx_hrs_holiday_date (holiday_date)`

---

#### 2.7 `hrs_leave_policies`
*School-wide leave policy configuration. NULL academic_year_id = global default.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| academic_year_id | SMALLINT UNSIGNED | YES | NULL | FK→sch_org_academic_sessions_jnt.id | NULL = global default policy |
| max_backdated_days | TINYINT UNSIGNED | NO | 3 | — | Max days in past for backdated application |
| min_advance_days | TINYINT UNSIGNED | NO | 0 | — | Min advance days before leave |
| approval_levels | TINYINT UNSIGNED | NO | 2 | — | 1 = HOD only; 2 = HOD + Principal |
| optional_holiday_count | TINYINT UNSIGNED | NO | 2 | — | Optional holidays employee can elect per year |

---

#### 2.8 `hrs_leave_balances`
*Per-employee per-leave-type per-academic-year balance tracking.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| employee_id | INT UNSIGNED | NO | — | FK→sch_employees.id | |
| leave_type_id | BIGINT UNSIGNED | NO | — | FK→hrs_leave_types.id | |
| academic_year_id | SMALLINT UNSIGNED | NO | — | FK→sch_org_academic_sessions_jnt.id | |
| allocated_days | DECIMAL(5,1) | NO | 0 | — | From leave type days_per_year |
| carry_forward_days | DECIMAL(5,1) | NO | 0 | — | From prior year, capped at type.carry_forward_days |
| used_days | DECIMAL(5,1) | NO | 0 | — | Updated on leave approval/cancellation |
| lop_days | DECIMAL(5,1) | NO | 0 | — | LOP days accrued this year |

**Indexes:** `KEY fk_hrs_lbal_empid (employee_id)`, `KEY fk_hrs_lbal_ltid (leave_type_id)`, `KEY fk_hrs_lbal_ayid (academic_year_id)`
**Unique:** `UNIQUE KEY uq_hrs_lbal (employee_id, leave_type_id, academic_year_id)`

---

#### 2.9 `hrs_leave_balance_adjustments`
*Audit trail for manual leave balance adjustments (HR Manager only).*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| leave_balance_id | BIGINT UNSIGNED | NO | — | FK→hrs_leave_balances.id | |
| adjustment_days | DECIMAL(5,1) | NO | — | — | Positive = add; negative = deduct |
| reason | TEXT | NO | — | — | Mandatory explanation |
| adjusted_by | INT UNSIGNED | NO | — | FK→sch_employees.id | HR Manager who adjusted |

**Indexes:** `KEY fk_hrs_lbadj_lbid (leave_balance_id)`, `KEY fk_hrs_lbadj_adjby (adjusted_by)`

---

#### 2.10 `hrs_leave_applications`
*Employee leave applications with status FSM.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| employee_id | INT UNSIGNED | NO | — | FK→sch_employees.id | Applicant |
| leave_type_id | BIGINT UNSIGNED | NO | — | FK→hrs_leave_types.id | |
| academic_year_id | SMALLINT UNSIGNED | NO | — | FK→sch_org_academic_sessions_jnt.id | |
| from_date | DATE | NO | — | — | Leave start date |
| to_date | DATE | NO | — | — | Leave end date |
| half_day | TINYINT(1) | NO | 0 | — | 1 = half-day application |
| half_day_session | ENUM | YES | NULL | — | 'first','second' — relevant only if half_day=1 |
| days_count | DECIMAL(5,1) | NO | — | — | Computed on save (excludes holidays, weekends) |
| reason | TEXT | NO | — | — | Employee-provided reason |
| media_id | BIGINT UNSIGNED | YES | NULL | FK→sys_media.id | Supporting document (medical cert, etc.) |
| status | ENUM | NO | 'pending' | — | 'pending','pending_l2','approved','rejected','cancelled','returned' |
| current_approver_level | TINYINT UNSIGNED | NO | 1 | — | 1 = awaiting HOD; 2 = awaiting Principal |

**Indexes:** `KEY fk_hrs_lapp_empid (employee_id)`, `KEY fk_hrs_lapp_ltid (leave_type_id)`, `KEY fk_hrs_lapp_ayid (academic_year_id)`, `KEY idx_hrs_lapp_status (status)`

---

#### 2.11 `hrs_leave_approvals`
*Approval action log. One row per approval step per application.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| application_id | BIGINT UNSIGNED | NO | — | FK→hrs_leave_applications.id | |
| approver_id | INT UNSIGNED | NO | — | FK→sch_employees.id | Approver (HOD or Principal) |
| level | TINYINT UNSIGNED | NO | — | — | 1 = HOD; 2 = Principal |
| action | ENUM | NO | — | — | 'approve','reject','return_for_clarification' |
| remarks | TEXT | NO | — | — | Mandatory for all actions (BR-HRS-024) |
| actioned_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | — | |

**Indexes:** `KEY fk_hrs_lappr_appid (application_id)`, `KEY fk_hrs_lappr_approverid (approver_id)`

---

#### 2.12 `hrs_lop_records`
*LOP (Loss of Pay) flags generated by reconciliation against attendance. One row per employee per absent date.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| employee_id | INT UNSIGNED | NO | — | FK→sch_employees.id | |
| absent_date | DATE | NO | — | — | Date employee was absent without approved leave |
| flag_status | ENUM | NO | 'flagged' | — | 'flagged','confirmed','waived' |
| confirmed_by | INT UNSIGNED | YES | NULL | FK→sch_employees.id | HR Manager who confirmed |
| confirmed_at | TIMESTAMP | YES | NULL | — | |
| payroll_month | VARCHAR(7) | YES | NULL | — | YYYY-MM — set when consumed by payroll |

**Indexes:** `KEY fk_hrs_lop_empid (employee_id)`, `KEY idx_hrs_lop_month (payroll_month)`, `KEY idx_hrs_lop_status (flag_status)`
**Unique:** `UNIQUE KEY uq_hrs_lop (employee_id, absent_date)`

---

### COMPLIANCE & SALARY PREP DOMAIN

#### 2.13 `hrs_pay_grades`
*Salary grade bands. Used to validate CTC range during salary assignment.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| grade_name | VARCHAR(100) | NO | — | — | e.g. 'Grade A', 'Senior Teacher' |
| min_ctc | DECIMAL(12,2) | NO | — | — | Minimum annual CTC for this grade |
| max_ctc | DECIMAL(12,2) | NO | — | — | Maximum annual CTC for this grade |
| applicable_designation_ids | JSON | YES | NULL | — | Array of sch_designation.id values |

---

#### 2.14 `hrs_salary_assignments`
*Links employee to a salary structure with CTC amount. History preserved — new row per revision.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| employee_id | INT UNSIGNED | NO | — | FK→sch_employees.id | |
| pay_salary_structure_id | BIGINT UNSIGNED | NO | — | FK→pay_salary_structures.id | Cross-prefix FK within same module |
| pay_grade_id | BIGINT UNSIGNED | YES | NULL | FK→hrs_pay_grades.id | |
| ctc_amount | DECIMAL(12,2) | NO | — | — | Annual CTC (must be within pay_grade min/max) |
| gross_monthly | DECIMAL(12,2) | NO | — | — | Monthly gross (CTC / 12 − employer contributions) |
| effective_from_date | DATE | NO | — | — | Assignment effective from |
| effective_to_date | DATE | YES | NULL | — | NULL = currently active; set on revision |
| revision_reason | VARCHAR(200) | YES | NULL | — | Reason for this assignment/revision |

**Indexes:** `KEY fk_hrs_salassgn_empid (employee_id)`, `KEY fk_hrs_salassgn_structid (pay_salary_structure_id)`, `KEY idx_hrs_salassgn_effective (effective_from_date, effective_to_date)`

---

#### 2.15 `hrs_compliance_records`
*Statutory compliance record per employee per type. UNIQUE (employee_id, compliance_type).*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| employee_id | INT UNSIGNED | NO | — | FK→sch_employees.id | |
| compliance_type | ENUM | NO | — | — | 'pf','esi','tds','gratuity','pt' |
| reference_number | VARCHAR(100) | YES | NULL | — | UAN (PF), IP number (ESI), encrypted PAN (TDS) |
| enrollment_date | DATE | YES | NULL | — | Date enrolled |
| applicable_flag | TINYINT(1) | NO | 1 | — | Whether this compliance type applies to employee |
| nominee_json | JSON | YES | NULL | — | PF/Gratuity nominee details |
| details_json | JSON | YES | NULL | — | Type-specific: TDS→{regime, 80C, HRA, LTA}; PT→{state_code}; ESI→{dispensary} |

**Unique:** `UNIQUE KEY uq_hrs_compliance (employee_id, compliance_type)`
**Indexes:** `KEY fk_hrs_compl_empid (employee_id)`, `KEY idx_hrs_compl_type (compliance_type)`

---

#### 2.16 `hrs_pf_contribution_register`
*Monthly PF contribution amounts per employee. Status tracks filing lifecycle.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| compliance_record_id | BIGINT UNSIGNED | NO | — | FK→hrs_compliance_records.id | |
| payroll_run_id | BIGINT UNSIGNED | YES | NULL | FK→pay_payroll_runs.id | Linked payroll run |
| month | TINYINT UNSIGNED | NO | — | — | 1–12 |
| year | SMALLINT UNSIGNED | NO | — | — | YYYY |
| basic_wage | DECIMAL(12,2) | NO | — | — | PF-eligible wages |
| emp_contribution | DECIMAL(10,2) | NO | — | — | Employee 12% |
| employer_epf | DECIMAL(10,2) | NO | — | — | Employer EPF 3.67% |
| employer_eps | DECIMAL(10,2) | NO | — | — | Employer EPS 8.33% |
| ncp_days | TINYINT UNSIGNED | NO | 0 | — | Non-contributing days (for ECR) |
| status | ENUM | NO | 'computed' | — | 'computed','submitted','challan_generated' |

**Indexes:** `KEY fk_hrs_pfreg_complid (compliance_record_id)`, `KEY fk_hrs_pfreg_runid (payroll_run_id)`
**Unique:** `UNIQUE KEY uq_hrs_pfreg (compliance_record_id, month, year)`

---

#### 2.17 `hrs_esi_contribution_register`
*Monthly ESI contribution amounts per employee.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| compliance_record_id | BIGINT UNSIGNED | NO | — | FK→hrs_compliance_records.id | |
| payroll_run_id | BIGINT UNSIGNED | YES | NULL | FK→pay_payroll_runs.id | |
| month | TINYINT UNSIGNED | NO | — | — | 1–12 |
| year | SMALLINT UNSIGNED | NO | — | — | YYYY |
| gross_wage | DECIMAL(12,2) | NO | — | — | ESI-eligible wages (gross ≤ ₹21,000 threshold) |
| emp_contribution | DECIMAL(10,2) | NO | — | — | Employee 0.75% |
| employer_contribution | DECIMAL(10,2) | NO | — | — | Employer 3.25% |
| status | ENUM | NO | 'computed' | — | 'computed','submitted','challan_generated' |

**Indexes:** `KEY fk_hrs_esireg_complid (compliance_record_id)`, `KEY fk_hrs_esireg_runid (payroll_run_id)`
**Unique:** `UNIQUE KEY uq_hrs_esireg (compliance_record_id, month, year)`

---

#### 2.18 `hrs_pt_slabs`
*State-wise Profession Tax slabs. Seeded for HP, KA, MH.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| state_code | VARCHAR(5) | NO | — | — | ISO state code: HP, KA, MH, etc. |
| min_salary | DECIMAL(10,2) | NO | — | — | Slab lower bound |
| max_salary | DECIMAL(10,2) | NO | — | — | Slab upper bound (use 999999999 for open-ended) |
| pt_amount | DECIMAL(8,2) | NO | — | — | Monthly PT amount for this slab |

**Indexes:** `KEY idx_hrs_pt_state (state_code)`

---

### APPRAISAL DOMAIN

#### 2.19 `hrs_kpi_templates`
*KPI template definitions. Each template has items; weights must sum to 100.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| name | VARCHAR(200) | NO | — | — | Template name |
| applicable_to | ENUM | NO | 'all' | — | 'all','teaching','non_teaching' |
| rating_scale | TINYINT UNSIGNED | NO | 5 | — | 5-point or 10-point rating scale |

---

#### 2.20 `hrs_kpi_template_items`
*Individual KPI items within a template. Weights must sum to 100 (enforced in service).*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| template_id | BIGINT UNSIGNED | NO | — | FK→hrs_kpi_templates.id | |
| kpi_name | VARCHAR(200) | NO | — | — | e.g. 'Student Performance', 'Punctuality' |
| category | ENUM | NO | — | — | 'academic','behavioral','administrative' |
| weight | DECIMAL(5,2) | NO | — | — | % weight; all items must sum to 100 |
| description | TEXT | YES | NULL | — | |

**Indexes:** `KEY fk_hrs_kpiitem_tmplid (template_id)`

---

#### 2.21 `hrs_appraisal_cycles`
*Appraisal cycle configuration per academic year.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| name | VARCHAR(200) | NO | — | — | e.g. '2025-26 Annual Appraisal' |
| academic_year_id | SMALLINT UNSIGNED | NO | — | FK→sch_org_academic_sessions_jnt.id | |
| appraisal_type | ENUM | NO | — | — | 'annual','mid_year','probation','confirmation' |
| kpi_template_id | BIGINT UNSIGNED | NO | — | FK→hrs_kpi_templates.id | |
| self_open_date | DATE | NO | — | — | When employees can begin self-appraisal |
| self_close_date | DATE | NO | — | — | |
| manager_open_date | DATE | NO | — | — | Must be >= self_close_date (BR-HRS-018) |
| manager_close_date | DATE | NO | — | — | |
| applicable_departments | JSON | YES | NULL | — | Array of sch_department.id; NULL = all departments |
| reviewer_mode | ENUM | NO | 'auto' | — | 'auto' = reporting_to from sch_employees_profile; 'manual' = HR assigns |
| status | ENUM | NO | 'draft' | — | 'draft','active','closed' |

**Indexes:** `KEY fk_hrs_aprcyc_ayid (academic_year_id)`, `KEY fk_hrs_aprcyc_tmplid (kpi_template_id)`

---

#### 2.22 `hrs_appraisals`
*Individual appraisal record per employee per cycle.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| cycle_id | BIGINT UNSIGNED | NO | — | FK→hrs_appraisal_cycles.id | |
| employee_id | INT UNSIGNED | NO | — | FK→sch_employees.id | Appraisee |
| reviewer_id | INT UNSIGNED | YES | NULL | FK→sch_employees.id | Assigned reviewer |
| self_rating_json | JSON | YES | NULL | — | Per-KPI: {kpi_id, rating, comments} |
| reviewer_rating_json | JSON | YES | NULL | — | Per-KPI: {kpi_id, rating, comments} |
| overall_rating | DECIMAL(4,2) | YES | NULL | — | Computed weighted average |
| self_comments | TEXT | YES | NULL | — | Overall self-assessment comment |
| reviewer_comments | TEXT | YES | NULL | — | Overall reviewer comment |
| hr_remarks | TEXT | YES | NULL | — | HR Manager remarks (for reopening/adjustment) |
| status | ENUM | NO | 'draft' | — | 'draft','submitted','reviewed','finalized' |
| finalized_at | TIMESTAMP | YES | NULL | — | Timestamp of finalization |

**Unique:** `UNIQUE KEY uq_hrs_appr (cycle_id, employee_id)`
**Indexes:** `KEY fk_hrs_appr_cycleid (cycle_id)`, `KEY fk_hrs_appr_empid (employee_id)`, `KEY fk_hrs_appr_reviewerid (reviewer_id)`

---

#### 2.23 `hrs_appraisal_increment_flags`
*Bridge: finalized appraisal → Payroll increment processing. Created on cycle close.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| appraisal_id | BIGINT UNSIGNED | NO | — | FK→hrs_appraisals.id | |
| employee_id | INT UNSIGNED | NO | — | FK→sch_employees.id | |
| cycle_id | BIGINT UNSIGNED | NO | — | FK→hrs_appraisal_cycles.id | |
| flag_status | ENUM | NO | 'pending' | — | 'pending','processed' |
| processed_at | TIMESTAMP | YES | NULL | — | When IncrementService processed this flag |

**Indexes:** `KEY fk_hrs_incflag_apprid (appraisal_id)`, `KEY fk_hrs_incflag_empid (employee_id)`, `KEY idx_hrs_incflag_status (flag_status)`

---

### SALARY STRUCTURE DOMAIN

#### 2.24 `pay_salary_components`
*Salary component master (earnings, deductions, employer contributions). Seeded with 14 standard components.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| name | VARCHAR(150) | NO | — | — | e.g. 'Basic Pay', 'PF Employee' |
| code | VARCHAR(30) | NO | — | UNIQUE | 'BASIC','DA','HRA','CONV','MEDICAL','LTA','SPECIAL','PF_EMP','ESI_EMP','PT','TDS','LWP_DED','PF_ERR','ESI_ERR' |
| component_type | ENUM | NO | — | — | 'earning','deduction','employer_contribution' |
| calculation_type | ENUM | NO | — | — | 'fixed','percentage_of_basic','percentage_of_gross','statutory','manual' |
| default_value | DECIMAL(10,4) | NO | 0 | — | Amount (fixed) or percentage (%-based). HRA=25.0000 |
| is_taxable | TINYINT(1) | NO | 1 | — | Affects TDS projected income computation |
| is_statutory | TINYINT(1) | NO | 0 | — | PF/ESI/PT/TDS = 1 |
| display_order | TINYINT UNSIGNED | NO | 99 | — | Order on payslip |

**Unique:** `UNIQUE KEY uq_pay_comp_code (code)`

---

#### 2.25 `pay_salary_structures`
*Salary structure templates. Each has components via pay_salary_structure_components.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| name | VARCHAR(200) | NO | — | — | e.g. 'Teaching Staff Structure' |
| description | TEXT | YES | NULL | — | |
| applicable_to | ENUM | NO | 'all' | — | 'all','teaching','non_teaching','contractual' |
| is_active | TINYINT(1) | NO | 1 | — | Active structures only assignable to employees |

---

#### 2.26 `pay_salary_structure_components`
*Junction: which components are in which structure, with formula overrides.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| structure_id | BIGINT UNSIGNED | NO | — | FK→pay_salary_structures.id | |
| component_id | BIGINT UNSIGNED | NO | — | FK→pay_salary_components.id | |
| sequence_order | TINYINT UNSIGNED | NO | 99 | — | Display/computation order on payslip |
| calculation_formula | TEXT | YES | NULL | — | Override formula if differs from component default |
| is_mandatory | TINYINT(1) | NO | 0 | — | Cannot be removed from this structure |

**Unique:** `UNIQUE KEY uq_pay_struct_comp (structure_id, component_id)`
**Indexes:** `KEY fk_pay_structcomp_structid (structure_id)`, `KEY fk_pay_structcomp_compid (component_id)`

---

### PAYROLL RUN DOMAIN

#### 2.27 `pay_payroll_runs`
*Payroll run header. FSM: draft → computing → computed → reviewing → approved → locked.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| payroll_month | VARCHAR(7) | NO | — | — | YYYY-MM format |
| academic_year_id | SMALLINT UNSIGNED | NO | — | FK→sch_org_academic_sessions_jnt.id | |
| run_type | ENUM | NO | 'regular' | — | 'regular','supplementary' |
| parent_run_id | BIGINT UNSIGNED | YES | NULL | FK→pay_payroll_runs.id | Supplementary run links to parent regular run |
| status | ENUM | NO | 'draft' | — | 'draft','computing','computed','reviewing','approved','locked' |
| initiated_by | INT UNSIGNED | NO | — | FK→sch_employees.id | Payroll Manager who initiated |
| approved_by | INT UNSIGNED | YES | NULL | FK→sch_employees.id | Principal who approved |
| approved_at | TIMESTAMP | YES | NULL | — | |
| locked_at | TIMESTAMP | YES | NULL | — | Timestamp of lock (immutable after this) |
| total_gross | DECIMAL(14,2) | YES | NULL | — | Aggregate gross (computed on lock) |
| total_net | DECIMAL(14,2) | YES | NULL | — | Aggregate net (computed on lock) |
| employee_count | SMALLINT UNSIGNED | YES | NULL | — | Number of employees in this run |
| computation_notes | TEXT | YES | NULL | — | Any errors or warnings from computation |

**Unique:** `UNIQUE KEY uq_pay_run_month_type (payroll_month, run_type)` — prevents duplicate regular runs per month
**Indexes:** `KEY fk_pay_run_ayid (academic_year_id)`, `KEY fk_pay_run_parent (parent_run_id)`, `KEY idx_pay_run_status (status)`

---

#### 2.28 `pay_payroll_run_details`
*Per-employee per-run computed payroll amounts. Immutable after run is locked.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| payroll_run_id | BIGINT UNSIGNED | NO | — | FK→pay_payroll_runs.id | |
| employee_id | INT UNSIGNED | NO | — | FK→sch_employees.id | |
| salary_assignment_id | BIGINT UNSIGNED | NO | — | FK→hrs_salary_assignments.id | Assignment used for this run |
| lop_days | DECIMAL(4,1) | NO | 0 | — | Confirmed LOP days from hrs_lop_records |
| gross_pay | DECIMAL(12,2) | NO | 0 | — | Gross earnings before LWP |
| lwp_deduction | DECIMAL(12,2) | NO | 0 | — | LWP = (gross_monthly / working_days) × lop_days |
| pf_employee | DECIMAL(10,2) | NO | 0 | — | Employee PF 12% |
| pf_employer | DECIMAL(10,2) | NO | 0 | — | Employer PF 12% |
| esi_employee | DECIMAL(10,2) | NO | 0 | — | Employee ESI 0.75% |
| esi_employer | DECIMAL(10,2) | NO | 0 | — | Employer ESI 3.25% |
| tds_deducted | DECIMAL(10,2) | NO | 0 | — | Monthly TDS (from TdsComputationService) |
| pt_deduction | DECIMAL(8,2) | NO | 0 | — | Profession Tax (from hrs_pt_slabs) |
| other_deductions | DECIMAL(10,2) | NO | 0 | — | Loan EMI, advance recovery, etc. |
| total_deductions | DECIMAL(12,2) | NO | 0 | — | Sum of all deductions |
| net_pay | DECIMAL(12,2) | NO | 0 | — | gross_pay − lwp_deduction − total_deductions |
| computation_json | JSON | YES | NULL | — | Full per-component breakdown for payslip |
| payment_status | ENUM | NO | 'pending' | — | 'pending','exported','paid','failed' |
| is_override | TINYINT(1) | NO | 0 | — | 1 if net_pay was manually overridden |

**Unique:** `UNIQUE KEY uq_pay_rundetail (payroll_run_id, employee_id)`
**Indexes:** `KEY fk_pay_det_runid (payroll_run_id)`, `KEY fk_pay_det_empid (employee_id)`, `KEY fk_pay_det_assgnid (salary_assignment_id)`

---

#### 2.29 `pay_payroll_overrides`
*Audit trail for manual amendments to payroll run details. Mandatory reason required.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| run_detail_id | BIGINT UNSIGNED | NO | — | FK→pay_payroll_run_details.id | |
| field_name | VARCHAR(50) | NO | — | — | e.g. 'net_pay','tds_deducted' |
| original_value | DECIMAL(12,2) | NO | — | — | Value before override |
| override_value | DECIMAL(12,2) | NO | — | — | Value after override |
| reason | TEXT | NO | — | — | Mandatory explanation (BR-PAY-005) |
| overridden_by | INT UNSIGNED | NO | — | FK→sch_employees.id | Payroll Manager |

**Indexes:** `KEY fk_pay_ovr_detid (run_detail_id)`, `KEY fk_pay_ovr_by (overridden_by)`

---

### PAYSLIP & DISTRIBUTION DOMAIN

#### 2.30 `pay_payslips`
*Generated payslip record per employee per run. One-to-one with run_detail.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| run_detail_id | BIGINT UNSIGNED | NO | — | UNIQUE FK→pay_payroll_run_details.id | |
| employee_id | INT UNSIGNED | NO | — | FK→sch_employees.id | Denormalised for quick self-service lookup |
| payroll_month | VARCHAR(7) | NO | — | — | YYYY-MM (denormalised) |
| media_id | BIGINT UNSIGNED | NO | — | FK→sys_media.id | Generated password-protected PDF |
| generated_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | — | |
| email_status | ENUM | NO | 'not_sent' | — | 'not_sent','pending','sent','failed' |
| email_sent_at | TIMESTAMP | YES | NULL | — | |

**Unique:** `UNIQUE KEY uq_pay_payslip_detail (run_detail_id)`
**Indexes:** `KEY fk_pay_pslip_detid (run_detail_id)`, `KEY fk_pay_pslip_empid (employee_id)`, `KEY fk_pay_pslip_mediaid (media_id)`

---

### TDS & FORM 16 DOMAIN

#### 2.31 `pay_tds_ledger`
*Monthly TDS cumulative ledger per employee per financial year.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| employee_id | INT UNSIGNED | NO | — | FK→sch_employees.id | |
| financial_year | VARCHAR(7) | NO | — | — | YYYY-YY format e.g. '2025-26' |
| month | TINYINT UNSIGNED | NO | — | — | 1–12 |
| gross_pay | DECIMAL(12,2) | NO | 0 | — | Gross for this month |
| tds_deducted | DECIMAL(10,2) | NO | 0 | — | TDS deducted this month |
| ytd_gross | DECIMAL(14,2) | NO | 0 | — | Year-to-date cumulative gross |
| ytd_tds | DECIMAL(12,2) | NO | 0 | — | Year-to-date cumulative TDS |

**Unique:** `UNIQUE KEY uq_pay_tds (employee_id, financial_year, month)`
**Indexes:** `KEY fk_pay_tds_empid (employee_id)`

---

#### 2.32 `pay_form16`
*Generated Form 16 PDF per employee per financial year.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| employee_id | INT UNSIGNED | NO | — | FK→sch_employees.id | |
| financial_year | VARCHAR(7) | NO | — | — | YYYY-YY |
| media_id | BIGINT UNSIGNED | NO | — | FK→sys_media.id | Generated PDF |
| generated_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | — | |
| generated_by | INT UNSIGNED | NO | — | FK→sch_employees.id | Payroll Manager |

**Unique:** `UNIQUE KEY uq_pay_form16 (employee_id, financial_year)`
**Indexes:** `KEY fk_pay_form16_empid (employee_id)`, `KEY fk_pay_form16_mediaid (media_id)`

---

### INCREMENT DOMAIN

#### 2.33 `pay_increment_policies`
*Rules mapping appraisal overall_rating ranges to increment amounts.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| name | VARCHAR(200) | NO | — | — | Policy name |
| appraisal_cycle_id | BIGINT UNSIGNED | YES | NULL | FK→hrs_appraisal_cycles.id | NULL = applicable to all cycles |
| min_rating | DECIMAL(4,2) | NO | — | — | Inclusive lower bound of overall_rating |
| max_rating | DECIMAL(4,2) | NO | — | — | Inclusive upper bound of overall_rating |
| increment_type | ENUM | NO | — | — | 'percentage','flat' |
| increment_value | DECIMAL(8,2) | NO | — | — | % or INR amount |

**Indexes:** `KEY fk_pay_incpol_cycleid (appraisal_cycle_id)`

---

## 3. Entity Relationship Diagram

```
=====================================================================
REUSED (read-only cross-module references)
=====================================================================
  sch_employees             sch_department          sch_designation
  sch_employees_profile     sch_org_academic_sessions_jnt
  sys_media                 sys_activity_logs       ntf_notifications
  att_staff_attendances [PENDING - Attendance module not built yet]

=====================================================================
HRS LAYER (hrs_*)
=====================================================================

Employment:
  hrs_employment_details ──────── employee_id ──→ sch_employees
  hrs_employment_history ──────── employee_id ──→ sch_employees
  hrs_employee_documents ──────── employee_id ──→ sch_employees
                         ──────── media_id ─────→ sys_media
  hrs_id_card_templates [standalone]

Leave:
  hrs_leave_types [standalone — seeded]
  hrs_holiday_calendars ────────── academic_year_id → sch_org_academic_sessions_jnt
  hrs_leave_policies ──────────── academic_year_id → sch_org_academic_sessions_jnt (nullable)
  hrs_leave_balances ──────────── employee_id ──→ sch_employees
                     ──────────── leave_type_id → hrs_leave_types
                     ──────────── academic_year_id → sch_org_academic_sessions_jnt
  hrs_leave_balance_adjustments ─ leave_balance_id → hrs_leave_balances
  hrs_leave_applications ─────── employee_id ──→ sch_employees
                          ──────── leave_type_id → hrs_leave_types
                          ──────── academic_year_id → sch_org_academic_sessions_jnt
  hrs_leave_approvals ─────────── application_id → hrs_leave_applications
                      ─────────── approver_id ───→ sch_employees
  hrs_lop_records ──────────────── employee_id ──→ sch_employees

Compliance & Salary Prep:
  hrs_pay_grades [standalone]
  hrs_salary_assignments ───────── employee_id ──→ sch_employees
                          ────────  pay_salary_structure_id → pay_salary_structures [cross-prefix]
                          ─────────  pay_grade_id ──→ hrs_pay_grades
  hrs_compliance_records ─────────  employee_id ──→ sch_employees
  hrs_pf_contribution_register ──── compliance_record_id → hrs_compliance_records
                               ──── payroll_run_id → pay_payroll_runs [cross-prefix]
  hrs_esi_contribution_register ─── compliance_record_id → hrs_compliance_records
                                ─── payroll_run_id → pay_payroll_runs [cross-prefix]
  hrs_pt_slabs [standalone — seeded]

Appraisal:
  hrs_kpi_templates [standalone]
  hrs_kpi_template_items ─────────── template_id → hrs_kpi_templates
  hrs_appraisal_cycles ───────────── academic_year_id → sch_org_academic_sessions_jnt
                        ─────────── kpi_template_id → hrs_kpi_templates
  hrs_appraisals ─────────────────── cycle_id → hrs_appraisal_cycles
                  ─────────────────── employee_id → sch_employees
                  ─────────────────── reviewer_id → sch_employees
  hrs_appraisal_increment_flags ──── appraisal_id → hrs_appraisals
                                ──── employee_id → sch_employees
                                ──── cycle_id → hrs_appraisal_cycles

=====================================================================
PAY LAYER (pay_*)
=====================================================================

Salary Structure:
  pay_salary_components [standalone — seeded]
  pay_salary_structures [standalone — seeded]
  pay_salary_structure_components ── structure_id → pay_salary_structures
                                  ── component_id → pay_salary_components

Payroll Run:
  pay_payroll_runs ────────────────── academic_year_id → sch_org_academic_sessions_jnt
                   ─────────────────── initiated_by → sch_employees
                   ─────────────────── approved_by → sch_employees
                   ─────────────────── parent_run_id → pay_payroll_runs [self-ref]
  pay_payroll_run_details ─────────── payroll_run_id → pay_payroll_runs
                           ─────────── employee_id → sch_employees
                           ─────────── salary_assignment_id → hrs_salary_assignments [cross-prefix]
  pay_payroll_overrides ───────────── run_detail_id → pay_payroll_run_details
                         ─────────── overridden_by → sch_employees

Payslip:
  pay_payslips ───────────────────── run_detail_id → pay_payroll_run_details
               ─────────────────── employee_id → sch_employees
               ─────────────────── media_id → sys_media

TDS / Form 16:
  pay_tds_ledger ─────────────────── employee_id → sch_employees
  pay_form16 ─────────────────────── employee_id → sch_employees
              ─────────────────────── media_id → sys_media

Increment:
  pay_increment_policies ─────────── appraisal_cycle_id → hrs_appraisal_cycles [cross-prefix, nullable]

Cross-prefix intentional FK summary:
  hrs_salary_assignments.pay_salary_structure_id → pay_salary_structures.id
  pay_payroll_run_details.salary_assignment_id → hrs_salary_assignments.id
  hrs_pf_contribution_register.payroll_run_id → pay_payroll_runs.id
  hrs_esi_contribution_register.payroll_run_id → pay_payroll_runs.id
  pay_increment_policies.appraisal_cycle_id → hrs_appraisal_cycles.id
```

---

## 4. Business Rules (35 Rules)

> Enforcement points: **SL** = Service Layer guard | **DB** = Database constraint | **FV** = Form validation | **ME** = Model event

### 4.1 Leave Rules

| Rule ID | Rule | Table/Column | Enforcement |
|---|---|---|---|
| BR-HRS-001 | Leave balance cannot go below 0 except for LWP type | hrs_leave_balances.used_days | SL |
| BR-HRS-002 | Overlapping approved leave for same employee is rejected | hrs_leave_applications.from_date/to_date | FV + SL |
| BR-HRS-003 | Carry-forward capped at `leave_type.carry_forward_days`; excess lapses at year end | hrs_leave_balances.carry_forward_days | SL (LeaveService::initializeBalances) |
| BR-HRS-004 | Backdated leave allowed only within `hrs_leave_policies.max_backdated_days` | hrs_leave_applications.from_date | FV + SL |
| BR-HRS-005 | Medical certificate mandatory for SL > `medical_cert_threshold_days` | hrs_employee_documents (media_id) | FV |
| BR-HRS-006 | ML applicable only to female employees; PL only to male (gender_restriction) | hrs_leave_types.gender_restriction | FV + SL |
| BR-HRS-007 | Min service months enforced at application time | hrs_leave_types.min_service_months | SL |
| BR-HRS-008 | Cancellation of approved leave allowed only if `from_date > today`; balance restored | hrs_leave_applications.status | SL |
| BR-HRS-009 | LOP confirmation restricted to HR Manager only | hrs_lop_records.flag_status | SL (Gate check) |

### 4.2 Salary & Compliance Rules

| Rule ID | Rule | Table/Column | Enforcement |
|---|---|---|---|
| BR-HRS-010 | Only one active salary assignment per employee (effective_to_date IS NULL) | hrs_salary_assignments.effective_to_date | SL (close prior row before inserting new) |
| BR-HRS-011 | CTC must be within pay_grade min_ctc and max_ctc | hrs_salary_assignments.ctc_amount | FV + SL |
| BR-HRS-012 | PF mandatory when basic_salary ≤ ₹15,000; voluntary otherwise | hrs_compliance_records | SL |
| BR-HRS-013 | ESI mandatory when gross_salary ≤ ₹21,000; not applicable otherwise | hrs_compliance_records | SL |
| BR-HRS-014 | Gratuity eligibility only after 5 years continuous service | hrs_compliance_records (compliance_type=gratuity) | SL |
| BR-HRS-015 | PAN and bank account number: Laravel encrypt(); never in plaintext logs | hrs_compliance_records.reference_number, hrs_employment_details.bank_account_number | SL (all reads via service) |

### 4.3 Payroll Rules

| Rule ID | Rule | Table/Column | Enforcement |
|---|---|---|---|
| BR-PAY-001 | Only one `regular` payroll run per `payroll_month` | pay_payroll_runs UNIQUE (payroll_month, run_type) | DB UNIQUE constraint + SL pre-check |
| BR-PAY-002 | Computation cannot start if any active employee lacks valid salary assignment | pay_payroll_runs pre-conditions | SL (PayrollRunService::validatePreConditions) |
| BR-PAY-003 | **Locked payroll is immutable** — cannot be modified, re-processed, or deleted | pay_payroll_runs.status = 'locked' | SL guard in ALL PayrollRunService methods |
| BR-PAY-004 | PF/ESI deduction mandatory for applicable_flag=true employees — cannot be individually overridden | hrs_compliance_records.applicable_flag | SL (not overridable via pay_payroll_overrides) |
| BR-PAY-005 | Manual net_pay override requires mandatory reason (min 10 chars) | pay_payroll_overrides.reason | FV + SL |
| BR-PAY-006 | TDS deducted cannot go below 0; shortfall carried to next month | pay_payroll_run_details.tds_deducted | SL (TdsComputationService) |
| BR-PAY-007 | Bank file export allowed only after payroll status = 'approved' or 'locked' | pay_payroll_runs.status | SL (Gate + status check) |
| BR-PAY-008 | Supplementary run must reference parent_run_id of regular run for same month | pay_payroll_runs.parent_run_id | FV + SL |
| BR-PAY-009 | Form 16 generation allowed only after April 15 for preceding financial year | pay_form16.financial_year | SL (date check) |
| BR-PAY-010 | LWP = (gross_monthly / working_days_in_month) × lop_days; working_days from school config | pay_payroll_run_details.lwp_deduction | SL (PayrollComputationService) |
| BR-PAY-011 | Salary structure must include BASIC component — enforced on structure save | pay_salary_structure_components | FV + SL |
| BR-PAY-012 | Payslip re-generation allowed only while payroll in 'approved' state; blocked after 'locked' | pay_payslips | SL |

### 4.4 Appraisal Rules

| Rule ID | Rule | Table/Column | Enforcement |
|---|---|---|---|
| BR-HRS-016 | KPI item weights within a template must sum exactly to 100 | hrs_kpi_template_items.weight | FV + SL |
| BR-HRS-017 | Self-appraisal submission locks the form; HR Manager must explicitly unlock for re-edit | hrs_appraisals.status | SL |
| BR-HRS-018 | Manager review window cannot open before self-appraisal close date | hrs_appraisal_cycles.manager_open_date | FV |
| BR-HRS-019 | Finalized appraisal cannot be modified; only HR Manager can reopen with audit log entry | hrs_appraisals.status | SL + sys_activity_logs |
| BR-HRS-020 | HR Manager overall_rating adjustment limited to ±10% of computed weighted average | hrs_appraisals.overall_rating | SL |

### 4.5 General Rules

| Rule ID | Rule | Table/Column | Enforcement |
|---|---|---|---|
| BR-HRS-021 | emp_code format: EMP/YYYY/NNN — auto-generated, unique, immutable | sch_employees.emp_code | SL (EmploymentService — generated on SchoolSetup creation) |
| BR-HRS-022 | Employee document expiry reminders fired 30 days before expiry_date | hrs_employee_documents.expiry_date | Scheduled command + DocumentExpiringSoon event |
| BR-HRS-023 | Soft-delete only (deleted_at + is_active=0); permanent deletion not permitted | All tables | SL (no hard delete methods) |
| BR-HRS-024 | All approval/rejection actions require non-empty remarks field | hrs_leave_approvals.remarks | FV |

---

## 5. Workflow State Machines

### 5.1 Leave Application FSM

```
States: pending | pending_l2 | approved | rejected | cancelled | returned

                                  ┌─ HOD rejects ──────────────────────────────────► [REJECTED]
                                  │
  Created ──► [PENDING] ──────────┤
                                  │ HOD approves
                                  │
                  if approval_levels=1 ───────────────────────────────────────────► [APPROVED]
                                  │
                  if approval_levels=2 ──► [PENDING_L2] ── Principal rejects ────► [REJECTED]
                                                    │
                                                    │ Principal approves
                                                    ▼
                                               [APPROVED] ── Employee cancels ──► [CANCELLED]
                                                             (from_date > today)

  [PENDING] or [PENDING_L2] ── HOD returns ──► [RETURNED] ── Employee resubmits ──► [PENDING]
```

**Pre-conditions for submission:**
- Balance available (except LWP)
- No overlapping approved leave
- Min service months met
- Date within backdated window

**Side effects:**
| Transition | Side Effect |
|---|---|
| → approved | `hrs_leave_balances.used_days += days_count`; notification to employee |
| → rejected | Notification to employee |
| → cancelled | `hrs_leave_balances.used_days -= days_count`; notification |
| → returned | Notification to employee |
| All transitions | `sys_activity_logs` write |

---

### 5.2 Payroll Run FSM

```
States: draft | computing | computed | reviewing | approved | locked

  Initiation:
    HR/Payroll Manager creates run ──► [DRAFT]

  Pre-conditions (checked before → COMPUTING):
    ✓ All hrs_lop_records.flag_status = 'confirmed' for payroll_month
    ✓ All active employees have active hrs_salary_assignments
    ✓ No existing regular run for payroll_month in computed/approved/locked state

  Computation:
    [DRAFT] ──── trigger compute ──► [COMPUTING]
                                         │ PayrollComputationService (sync ≤100, queued >100)
                                         ▼
                                    [COMPUTED]

  Review & Override (state stays COMPUTED):
    [COMPUTED] ←─────────── Principal rejects ──── [REVIEWING]
         │
         │ Payroll Manager submits
         ▼
    [REVIEWING]
         │
         │ Principal approves
         ▼
    [APPROVED]
         │
         │ Payroll Manager locks
         ▼
    [LOCKED] ◄─────── IMMUTABLE (BR-PAY-003 — no modification after this)

  Post-lock actions (status remains LOCKED):
    → Bank file export (payment_status: pending → exported)
    → Payslip generation + email distribution
    → PF ECR file export
    → ESI challan export
```

**Side effects on LOCKED:**
- `PayrollApproved` event fired → Accounting module listener creates Journal Voucher
- `PayrollLocked` event fired → `hrs_pf_contribution_register.status` → 'submitted'
- `PayrollLocked` event fired → `hrs_esi_contribution_register.status` → 'submitted'

---

### 5.3 Appraisal FSM

```
Cycle FSM:
  [DRAFT] ──── HR activates ──► [ACTIVE] ──── HR closes ──► [CLOSED]
  On CLOSED: hrs_appraisal_increment_flags created for each FINALIZED appraisal
             AppraisalFinalized event fired → IncrementService

Individual Appraisal FSM (within ACTIVE cycle):
  [draft] ──── Employee submits ──► [submitted]
                                         │ HR unlocks → back to [draft] (with audit log)
  [submitted] ──── Reviewer reviews ──► [reviewed]
  [reviewed] ──── HR Manager finalizes ──► [finalized]
                                              │ Finalization side effects:
                                              │  → hrs_appraisal_increment_flags row created
                                              │  → overall_rating = weighted average of reviewer ratings
                                              │  → Employee notification dispatched
```

---

## 6. Functional Requirements Summary (46 FRs)

### Sub-Module C1 — Staff HR Records

| FR | Name | Tables Used | Key Validations | BRs | Depends On |
|---|---|---|---|---|---|
| HRS-001 | Employee HR Details Extension | hrs_employment_details | Contract type valid ENUM; bank IFSC format | BR-HRS-015, 021 | sch_employees exists |
| HRS-002 | Employment History Log | hrs_employment_history | Immutable on insert | BR-HRS-023 | HRS-001 |
| HRS-003 | Employee Document Repository | hrs_employee_documents | Expiry date ≥ issued date | BR-HRS-022 | sys_media |
| HRS-004 | Staff ID Card Generation | hrs_id_card_templates | Template must be active | — | sys_media, DomPDF |

### Sub-Module C2+C3 — Leave Management

| FR | Name | Tables Used | Key Validations | BRs | Depends On |
|---|---|---|---|---|---|
| HRS-005 | Leave Type Master | hrs_leave_types | Code unique; weight sums N/A | BR-HRS-006 | — |
| HRS-006 | Holiday Calendar | hrs_holiday_calendars | holiday_date not duplicate per year | — | sch_org_academic_sessions_jnt |
| HRS-007 | Leave Policy Configuration | hrs_leave_policies | approval_levels ∈ {1,2} | — | — |
| HRS-008 | Leave Balance Initialization | hrs_leave_balances | One run per academic year per employee | BR-HRS-003 | HRS-005, HRS-007 |
| HRS-009 | Leave Application | hrs_leave_applications | Overlap check, balance check | BR-HRS-001,002,004,006,007 | HRS-008 |
| HRS-010 | Leave Approval Workflow | hrs_leave_approvals | Remarks required | BR-HRS-024 | HRS-009, HRS-007 |
| HRS-011 | Leave Balance Dashboard | hrs_leave_balances | — | — | HRS-008 |
| HRS-012 | LOP Reconciliation | hrs_lop_records | Confirmed before payroll | BR-HRS-009 | att_staff_attendances [PENDING] |

### Sub-Module C4a — Payroll Preparation (HR Layer)

| FR | Name | Tables Used | Key Validations | BRs | Depends On |
|---|---|---|---|---|---|
| HRS-013 | Pay Grade Master | hrs_pay_grades | min_ctc < max_ctc | — | — |
| HRS-014 | Employee Salary Assignment | hrs_salary_assignments | CTC in grade range; close prior row | BR-HRS-010,011 | HRS-013, HRS-023, HRS-024 |

### Sub-Module C4b — Statutory Compliance Records

| FR | Name | Tables Used | Key Validations | BRs | Depends On |
|---|---|---|---|---|---|
| HRS-015 | PF Compliance Records | hrs_compliance_records, hrs_pf_contribution_register | UAN format; applicable_flag logic | BR-HRS-012,015 | sch_employees |
| HRS-016 | ESI Compliance Records | hrs_compliance_records, hrs_esi_contribution_register | IP number format; gross threshold | BR-HRS-013,015 | sch_employees |
| HRS-017 | TDS Declaration Storage | hrs_compliance_records | PAN encrypted; regime valid | BR-HRS-015 | sch_employees |
| HRS-018 | Gratuity Records | hrs_compliance_records | 5-year service check | BR-HRS-014 | sch_employees |

### Sub-Module C8 — Performance Appraisal

| FR | Name | Tables Used | Key Validations | BRs | Depends On |
|---|---|---|---|---|---|
| HRS-019 | KPI Template Management | hrs_kpi_templates, hrs_kpi_template_items | Weights sum to 100 | BR-HRS-016 | — |
| HRS-020 | Appraisal Cycle Configuration | hrs_appraisal_cycles | manager_open ≥ self_close | BR-HRS-018 | HRS-019 |
| HRS-021 | Self-Appraisal Submission | hrs_appraisals | Within self_open/close dates | BR-HRS-017 | HRS-020 |
| HRS-022 | Manager Review & Finalization | hrs_appraisals, hrs_appraisal_increment_flags | Within reviewer dates; ±10% HR tolerance | BR-HRS-019,020 | HRS-021 |

### Sub-Module P1 — Salary Structure Master

| FR | Name | Tables Used | Key Validations | BRs | Depends On |
|---|---|---|---|---|---|
| HRS-023 | Salary Component Master | pay_salary_components | Code unique | — | — |
| HRS-024 | Salary Structure Template | pay_salary_structures, pay_salary_structure_components | Must include BASIC | BR-PAY-011 | HRS-023 |
| HRS-025 | CTC Breakdown Preview | pay_salary_structures, pay_salary_structure_components | Read-only calculation | — | HRS-014, HRS-024 |

### Sub-Module P2 — Monthly Payroll Run

| FR | Name | Tables Used | Key Validations | BRs | Depends On |
|---|---|---|---|---|---|
| HRS-026 | Payroll Run Initiation | pay_payroll_runs | No duplicate regular run | BR-PAY-001 | HRS-012, HRS-014 |
| HRS-027 | Payroll Computation Engine | pay_payroll_run_details, pay_tds_ledger | Pre-conditions met | BR-PAY-002,004,010 | HRS-026, HRS-015,16,17 |
| HRS-028 | Payroll Review & Amendment | pay_payroll_overrides | Status = computed; reason required | BR-PAY-003,005 | HRS-027 |
| HRS-029 | Payroll Approval & Lock | pay_payroll_runs | Principal approval | BR-PAY-003 | HRS-028 |
| HRS-030 | Supplementary Payroll Run | pay_payroll_runs | parent_run_id required | BR-PAY-008 | HRS-029 |

### Sub-Module P3 — Payslip Generation & Distribution

| FR | Name | Tables Used | Key Validations | BRs | Depends On |
|---|---|---|---|---|---|
| HRS-031 | Individual Payslip Generation | pay_payslips, sys_media | Run status ≥ approved | BR-PAY-012 | HRS-029, DomPDF |
| HRS-032 | Bulk Payslip Generation | pay_payslips | Queue dispatch | BR-PAY-012 | HRS-031 |
| HRS-033 | Payslip Email Distribution | pay_payslips, ntf_notifications | Payslip exists | — | HRS-032 |
| HRS-034 | Employee Self-Service Download | pay_payslips | Gate: pay.payslip.own.download | — | HRS-031 |

### Sub-Module P4 — Bank Disbursement

| FR | Name | Tables Used | Key Validations | BRs | Depends On |
|---|---|---|---|---|---|
| HRS-035 | Bank NEFT/RTGS File Export | pay_payroll_run_details | Status ≥ approved | BR-PAY-007 | HRS-029 |
| HRS-036 | Payment Status Tracking | pay_payroll_run_details | Status FSM: pending→exported→paid | — | HRS-035 |

### Sub-Module P5 — TDS & Form 16

| FR | Name | Tables Used | Key Validations | BRs | Depends On |
|---|---|---|---|---|---|
| HRS-037 | Monthly TDS Computation | pay_tds_ledger | Regime valid; TDS ≥ 0 | BR-PAY-006 | HRS-027, HRS-017 |
| HRS-038 | Form 16 Generation | pay_form16, sys_media | After April 15 only | BR-PAY-009 | HRS-037, DomPDF |

### Sub-Module P6 — Statutory Returns

| FR | Name | Tables Used | Key Validations | BRs | Depends On |
|---|---|---|---|---|---|
| HRS-039 | PF ECR File Generation | hrs_pf_contribution_register | Run status = locked; UAN present | — | HRS-029 |
| HRS-040 | ESI Contribution Export | hrs_esi_contribution_register | Run status = locked | — | HRS-029 |

### Sub-Module P7 — Variable Pay & Increments

| FR | Name | Tables Used | Key Validations | BRs | Depends On |
|---|---|---|---|---|---|
| HRS-041 | Appraisal-Linked Variable Pay | hrs_appraisal_increment_flags, hrs_salary_assignments, pay_increment_policies | Rating range no overlap | — | HRS-022, HRS-014 |
| HRS-042 | Salary Revision / Increment | hrs_salary_assignments, hrs_employment_history | effective_from_date future | BR-HRS-010 | HRS-014 |

### Sub-Module P8 — Payroll Reports

| FR | Name | Tables Used | Key Validations | BRs | Depends On |
|---|---|---|---|---|---|
| HRS-043 | Monthly Salary Register | pay_payroll_run_details | Run must be locked | — | HRS-029 |
| HRS-044 | Bank Transfer Summary | pay_payroll_run_details | — | — | HRS-029 |
| HRS-045 | CTC vs Gross vs Net Analysis | hrs_salary_assignments, pay_payroll_run_details | — | — | HRS-029 |
| HRS-046 | Payroll Trend Report | pay_payroll_runs, pay_payroll_run_details | Last 12 months | — | HRS-029 |

---

## 7. Permission Matrix

| Permission String | HR Mgr | Payroll Mgr | Principal | HOD | Employee | Accountant | Policy Class |
|---|---|---|---|---|---|---|---|
| `hrs.employment.manage` | ✓ | — | — | — | — | — | EmploymentPolicy |
| `hrs.documents.manage` | ✓ | — | — | — | Own | — | DocumentPolicy |
| `hrs.leave_type.manage` | ✓ | — | — | — | — | — | LeaveTypePolicy |
| `hrs.leave.apply` | ✓ | — | — | — | ✓ | — | LeaveApplicationPolicy |
| `hrs.leave.approve_l1` | ✓ | — | — | ✓ | — | — | LeaveApplicationPolicy |
| `hrs.leave.approve_l2` | ✓ | — | ✓ | — | — | — | LeaveApplicationPolicy |
| `hrs.leave.balance.view` | ✓ | — | ✓ (all) | ✓ (dept) | Own | — | LeaveBalancePolicy |
| `hrs.lop.confirm` | ✓ | — | — | — | — | — | — (Gate only) |
| `hrs.salary.manage` | ✓ | ✓ | — | — | — | Read | SalaryAssignmentPolicy |
| `hrs.compliance.manage` | ✓ | ✓ | — | — | — | Read | CompliancePolicy |
| `hrs.appraisal.manage` | ✓ | — | — | — | — | — | AppraisalCyclePolicy |
| `hrs.appraisal.review` | ✓ | — | ✓ | ✓ | — | — | AppraisalPolicy |
| `hrs.appraisal.self` | ✓ | — | — | — | ✓ | — | AppraisalPolicy |
| `hrs.idcard.generate` | ✓ | — | — | — | Own download | — | — (Gate only) |
| `pay.structure.manage` | ✓ | ✓ | — | — | — | Read | SalaryStructurePolicy |
| `pay.run.initiate` | — | ✓ | — | — | — | — | PayrollRunPolicy |
| `pay.run.compute` | — | ✓ | — | — | — | — | PayrollRunPolicy |
| `pay.run.approve` | — | — | ✓ | — | — | — | PayrollRunPolicy |
| `pay.run.lock` | — | ✓ | — | — | — | — | PayrollRunPolicy |
| `pay.payslip.generate` | — | ✓ | — | — | — | — | PayslipPolicy |
| `pay.payslip.own.download` | — | — | — | — | ✓ | — | PayslipPolicy |
| `pay.bank_file.export` | — | ✓ | — | — | — | — | — (Gate only) |
| `pay.form16.generate` | — | ✓ | — | — | — | — | Form16Policy |
| `pay.form16.own.download` | — | — | — | — | ✓ | — | Form16Policy |
| `pay.report.view` | ✓ | ✓ | ✓ | — | — | ✓ | — (Gate only) |
| `pay.increment.process` | — | ✓ | — | — | — | — | — (Gate only) |

### Policy Classes (13)

| Policy | Model | Key Logic |
|---|---|---|
| `EmploymentPolicy` | `EmploymentDetail` | Requires `hrs.employment.manage` |
| `DocumentPolicy` | `EmployeeDocument` | Own employee OR `hrs.documents.manage` |
| `LeaveTypePolicy` | `LeaveType` | Requires `hrs.leave_type.manage` |
| `LeaveApplicationPolicy` | `LeaveApplication` | Own (apply/cancel) OR approver role |
| `LeaveBalancePolicy` | `LeaveBalance` | Own, dept (HOD), or all (`hrs.leave.balance.view`) |
| `SalaryAssignmentPolicy` | `SalaryAssignment` | Manage or read-only (accountant) |
| `CompliancePolicy` | `ComplianceRecord` | Manage or read-only (accountant) |
| `AppraisalCyclePolicy` | `AppraisalCycle` | Requires `hrs.appraisal.manage` |
| `AppraisalPolicy` | `Appraisal` | Own (self-submit), reviewer, or `hrs.appraisal.manage` |
| `SalaryStructurePolicy` | `SalaryStructure` | Manage or read-only (accountant) |
| `PayrollRunPolicy` | `PayrollRun` | Per-action: initiate/compute/lock (Payroll Mgr) vs approve (Principal) |
| `PayslipPolicy` | `Payslip` | Own employee OR `pay.payslip.generate` |
| `Form16Policy` | `Form16` | Own employee OR `pay.form16.generate` |

---

## 8. Service Architecture (15 Services)

All services in `Modules/HrStaff/app/Services/`. Namespace: `Modules\HrStaff\app\Services`.

---

### 8.1 `EmploymentService`
**Responsibilities:** Employment detail CRUD, emp_code generation, employment history logging.
**Fires:** Nothing directly; calls sys_activity_logs.
**Depends on:** Nothing.

```php
createEmploymentDetail(array $data, int $employeeId): EmploymentDetail
updateEmploymentDetail(EmploymentDetail $detail, array $data): EmploymentDetail
logHistoryChange(int $employeeId, string $changeType, array $oldValue, array $newValue, string $remarks): void
  // Always called internally after any employment change
```

---

### 8.2 `LeaveService`
**Responsibilities:** Balance initialization, carry-forward, leave day calculation, apply/cancel leave, LOP flagging.
**Fires:** Nothing directly.
**Depends on:** `HolidayService` (for working days calculation).

```php
initializeBalances(int $academicYearId): int
  // Creates hrs_leave_balances rows for all active employees; returns count
  // Applies carry-forward: MIN(prior_closing, leave_type.carry_forward_days)

calculateDays(int $leaveTypeId, Carbon $from, Carbon $to, bool $halfDay): float
  // Excludes weekends and holidays (via HolidayService::getHolidayDates())

applyLeave(array $data, int $employeeId): LeaveApplication
  // Validates overlap, balance, date window, gender restriction

cancelLeave(int $applicationId): bool
  // Validates from_date > today; restores balance

runLopReconciliation(string $payrollMonth): Collection
  // Reads att_staff_attendances [STUB if table not yet available]
  // Returns newly flagged hrs_lop_records

confirmLop(int $lopRecordId, int $confirmedBy): LopRecord
waiveLop(int $lopRecordId, int $waivedBy, string $reason): LopRecord
```

---

### 8.3 `LeaveApprovalService`
**Responsibilities:** Route approval to correct level, dispatch notifications, update balances.
**Fires:** `LeaveApproved`, `LeaveRejected`.
**Depends on:** `LeaveService`.

```php
approve(LeaveApplication $application, int $approverId, string $remarks): LeaveApplication
  // Determines if L1 or L2 action; advances FSM accordingly
  // On final approval: calls LeaveService to update balance

reject(LeaveApplication $application, int $approverId, string $remarks): LeaveApplication
return(LeaveApplication $application, int $approverId, string $remarks): LeaveApplication
```

---

### 8.4 `HolidayService`
**Responsibilities:** Holiday calendar CRUD, compute working days between two dates.
**Fires:** Nothing.

```php
getHolidayDates(int $academicYearId, string $applicableTo = 'all'): array
  // Returns array of DATE strings for the year

calculateWorkingDays(Carbon $from, Carbon $to, int $academicYearId): int
  // Excludes weekends (configured in school settings) and holidays
```

---

### 8.5 `SalaryAssignmentService`
**Responsibilities:** Assign/revise salary structure, validate CTC vs pay grade, maintain revision history.
**Fires:** Nothing directly; calls `EmploymentService::logHistoryChange()`.
**Depends on:** `EmploymentService`.

```php
assign(int $employeeId, array $data): SalaryAssignment
  // Closes active assignment (sets effective_to_date = today)
  // Creates new row; logs history change

revise(int $employeeId, array $data): SalaryAssignment
  // Same as assign; revision_reason required

getActiveSalaryAssignment(int $employeeId): ?SalaryAssignment
  // Returns row where effective_to_date IS NULL
```

---

### 8.6 `ComplianceService`
**Responsibilities:** PF/ESI/TDS/Gratuity/PT record CRUD, contribution register management, export reports.
**Fires:** Nothing.

```php
saveComplianceRecord(int $employeeId, string $type, array $data): ComplianceRecord
  // Upsert UNIQUE (employee_id, compliance_type)
  // Encrypts PAN before saving for TDS type

computePfRegister(int $payrollRunId): void
  // Creates/updates hrs_pf_contribution_register rows for all PF-enrolled employees in run

computeEsiRegister(int $payrollRunId): void
  // Creates/updates hrs_esi_contribution_register rows for all ESI-enrolled employees in run

exportPfRegister(string $month, int $year): BinaryFileResponse
exportEsiRegister(string $month, int $year): BinaryFileResponse
```

---

### 8.7 `AppraisalService`
**Responsibilities:** Cycle management, appraisal form routing, weighted rating computation, increment flag creation.
**Fires:** `AppraisalFinalized`.
**Depends on:** Nothing.

```php
createCycle(array $data): AppraisalCycle
activateCycle(AppraisalCycle $cycle): AppraisalCycle
closeCycle(AppraisalCycle $cycle): AppraisalCycle
  // On close: creates hrs_appraisal_increment_flags for each finalized appraisal; fires AppraisalFinalized

submitSelfAppraisal(Appraisal $appraisal, array $ratings): Appraisal
submitManagerReview(Appraisal $appraisal, array $ratings, string $comments): Appraisal
finalizeAppraisal(Appraisal $appraisal, int $hrManagerId): Appraisal
  // Computes overall_rating = weighted avg of reviewer_rating_json

computeOverallRating(array $reviewerRatingJson, array $kpiWeights): float
  // weighted avg; HR tolerance ±10% allowed
```

---

### 8.8 `IdCardService`
**Responsibilities:** Generate ID card PDF via DomPDF, QR code, store in sys_media.

```php
generate(int $employeeId, int $templateId): Media
  // Renders blade template → DomPDF → stores in sys_media
  // QR code content = emp_code (SimpleSoftwareIO QR Code)
```

---

### 8.9 `SalaryStructureService`
**Responsibilities:** Component CRUD, structure template CRUD, CTC breakdown preview.

```php
createComponent(array $data): SalaryComponent
createStructure(array $data, array $components): SalaryStructure
  // $components = [{component_id, sequence_order, formula, is_mandatory}]
  // Validates BASIC component present (BR-PAY-011)

getCTCBreakdown(int $structureId, float $ctcAmount): array
  // Returns: [{component, type, amount}], gross_monthly, net_monthly, employer_cost
  // Pure calculation — no DB writes
```

---

### 8.10 `PayrollComputationService`
**Responsibilities:** Core payroll engine. Per-employee computation with 8-step sequence.
**Depends on:** `TdsComputationService`.

```php
computeRun(PayrollRun $run): void
  // Dispatches ProcessPayrollJob if employee_count > 100; else runs synchronously
  // Sets run.status = 'computing' before, 'computed' after

computeEmployee(PayrollRun $run, Employee $emp): PayrollRunDetail
  // 8-step sequence:
  //   1. Resolve active SalaryAssignment
  //   2. Calculate gross earnings per component formula
  //   3. LWP = (gross_monthly / working_days_in_month) × lop_days
  //   4. PF employee = 12% basic_da if compliance.pf.applicable = true
  //   5. ESI employee = 0.75% gross_after_lwp if gross ≤ ₹21,000 and esi.applicable = true
  //   6. PT from hrs_pt_slabs (state from compliance.pt.details_json.state_code)
  //   7. TDS = TdsComputationService::computeMonthlyTds()
  //   8. net_pay = gross_after_lwp − pf_emp − esi_emp − pt − tds

recomputeEmployee(PayrollRunDetail $detail): PayrollRunDetail
  // Partial re-run for one employee without affecting others

getWorkingDaysInMonth(string $payrollMonth, int $academicYearId): int
  // From school config (sch_working_config or hardcoded 26 days if not configured)
```

---

### 8.11 `TdsComputationService`
**Responsibilities:** Annual projected income, old/new regime slabs, monthly TDS, Form 16 generation.

```php
computeMonthlyTds(Employee $emp, int $month, int $year): float
  // Regime from hrs_compliance_records (compliance_type=tds).details_json.regime
  // Annual projected income = YTD_gross + (remaining_months × current_gross)
  //                         + investment declarations from details_json
  // Monthly TDS = (annual_tax − YTD_tds) / remaining_months
  // Dec-Mar: full recompute for year-end accuracy
  // Returns max(0, computed) — BR-PAY-006: floor at 0

getProjectedAnnualIncome(Employee $emp, string $financialYear): float
computeAnnualTax(float $income, string $regime, array $declarations): float
  // Old regime: standard deduction ₹50,000, 80C max ₹1.5L, HRA/LTA exemptions
  // New regime: no exemptions; flat slab rates

generateForm16(Employee $emp, string $financialYear): Media
  // DomPDF: Part A (employer, quarterly TDS) + Part B (salary breakup, exemptions)
  // Stores in sys_media; creates/updates pay_form16 row
  // Only callable after April 15 (BR-PAY-009)
```

---

### 8.12 `PayrollRunService`
**Responsibilities:** Run lifecycle management (initiate → compute → approve → lock), supplementary runs, pre-condition validation.
**Fires:** `PayrollApproved`, `PayrollLocked`.
**Depends on:** `PayrollComputationService`, `ComplianceService`.

```php
initiateRun(array $data): PayrollRun
  // Validates no existing regular run for month (BR-PAY-001)

validatePreConditions(PayrollRun $run): array
  // Returns [errors] if any:
  //   - Unconfirmed LOP records for payroll_month
  //   - Employees without active salary assignments

submitForApproval(PayrollRun $run): PayrollRun
  // status: computed → reviewing

approve(PayrollRun $run, int $principalId): PayrollRun
  // status: reviewing → approved

lock(PayrollRun $run): PayrollRun
  // BR-PAY-003: only if status = approved
  // Sets locked_at; status → locked
  // Fires PayrollApproved + PayrollLocked events
  // Calls ComplianceService::computePfRegister() + computeEsiRegister()
```

---

### 8.13 `PayslipService`
**Responsibilities:** Single + bulk payslip PDF generation via DomPDF, password logic, email dispatch.
**Depends on:** `TdsComputationService` (for YTD figures on payslip).

```php
generate(PayrollRunDetail $detail): Payslip
  // Renders payslip blade → DomPDF → password-protect PDF
  // Stores in sys_media; creates pay_payslips row

generateAllForRun(PayrollRun $run): void
  // Dispatches GeneratePayslipsJob (always queued for bulk)

getPasswordForEmployee(Employee $emp): string
  // Returns: PANlast4 + DDYYYY(DOB)
  // PANlast4 = last 4 chars of decrypted PAN from hrs_compliance_records
  // DDYYYY = format(sch_employees.date_of_birth, 'ddYYYY')

emailPayslip(Payslip $payslip): void
  // Dispatches to ntf_notifications; sets email_status = 'pending'

emailAllForRun(PayrollRun $run): void
```

---

### 8.14 `StatutoryExportService`
**Responsibilities:** PF ECR file, ESI challan, bank NEFT file generation.

```php
exportBankFile(PayrollRun $run, string $format = 'csv'): BinaryFileResponse
  // Formats: 'csv' (generic), 'sbi', 'hdfc', 'icici'
  // Includes only: net_pay > 0 AND payment_status = 'pending'
  // Updates payment_status → 'exported' after download

exportPfEcr(PayrollRun $run): BinaryFileResponse
  // EPFO pipe-delimited (#~#) format: UAN, name, gross wages, EPF wages, EPS wages,
  //   EDLI wages, EPF contribution, EPS contribution, NCP days
  // Validates UAN present, sum-check
  // Updates hrs_pf_contribution_register.status → 'challan_generated'

exportEsiChallan(PayrollRun $run): BinaryFileResponse
  // CSV: IP number, name, gross wages, employee contribution, employer contribution
```

---

### 8.15 `IncrementService`
**Responsibilities:** Appraisal-linked variable pay proposals, ad-hoc salary revision, flag status update.
**Depends on:** `SalaryAssignmentService`.

```php
generateIncrementProposals(int $appraisalCycleId): Collection
  // For each hrs_appraisal_increment_flags.flag_status = 'pending':
  //   - Lookup applicable pay_increment_policies for cycle
  //   - Compute proposed increment from overall_rating
  //   - Return proposals (not applied until approved)

processApprovedIncrement(int $incrementFlagId, float $newCtcOrPct, Carbon $effectiveFrom): void
  // Calls SalaryAssignmentService::assign() with new CTC
  // Sets hrs_appraisal_increment_flags.flag_status → 'processed'

processAdHocRevision(int $employeeId, array $revisionData): SalaryAssignment
  // Calls SalaryAssignmentService::revise()
```

---

## 9. Integration Contracts (6 Events)

| Event Class | Fired By | When | Payload | Listener | Action |
|---|---|---|---|---|---|
| `LeaveApproved` | LeaveApprovalService::approve() | Final approval (L1 if 1-level, L2 if 2-level) | `{application_id, employee_id, leave_type_id, from_date, to_date, days_count}` | NotificationService | Employee notification via ntf_notifications |
| `LeaveRejected` | LeaveApprovalService::reject() | Any rejection | `{application_id, employee_id, level, reason}` | NotificationService | Employee notification |
| `DocumentExpiringSoon` | Scheduled command (daily) | 30 days before any expiry_date in hrs_employee_documents | `{document_id, employee_id, document_type, expiry_date}` | HrStaff (internal) | HR Manager notification via ntf_notifications |
| `AppraisalFinalized` | AppraisalService::closeCycle() | Cycle status → closed | `{cycle_id, finalized_appraisal_ids[]}` | IncrementService | Creates hrs_appraisal_increment_flags for each finalized appraisal |
| `PayrollApproved` | PayrollRunService::lock() | Run status → locked | `{payroll_run_id, payroll_month, total_gross, total_net, employee_count}` | Accounting module listener | Creates Payroll Journal Voucher (salary expense, PF/ESI payable, TDS payable, salary payable) |
| `PayrollLocked` | PayrollRunService::lock() | Run status → locked (same trigger as PayrollApproved) | `{payroll_run_id, payroll_month}` | StatutoryExportService (internal) | Updates hrs_pf_contribution_register.status → 'submitted'; hrs_esi_contribution_register.status → 'submitted' |

> **Note:** `PayrollApproved` and `PayrollLocked` are both fired in `PayrollRunService::lock()`. The Accounting module listens to `PayrollApproved`; the internal StatutoryExportService responds to `PayrollLocked`. These are separate events to allow independent listener registration.

---

## 10. Non-Functional Requirements

| ID | Category | Requirement | Implementation Note |
|---|---|---|---|
| NFR-001 | Performance | Leave balance read < 200 ms (single employee) | Eager-load leave_balances with leave_type; index on (employee_id, academic_year_id) |
| NFR-002 | Performance | Monthly LOP reconciliation for 200 employees < 10 s | Chunk att_staff_attendances reads; bulk insert hrs_lop_records |
| NFR-003 | Performance | Payroll computation ≤100 employees < 30 s synchronous; >100 queued | `PayrollComputationService::computeRun()` dispatches `ProcessPayrollJob` only when employee_count > 100 |
| NFR-004 | Performance | Bulk payslip generation 200 employees < 5 min via queue | `GeneratePayslipsJob` processes employees one at a time; queued job |
| NFR-005 | Security | Bank account number + PAN encrypted; never in plaintext logs | Laravel `encrypt()` / `decrypt()` in `EmploymentService` and `ComplianceService`; never pass raw values to `sys_activity_logs` |
| NFR-006 | Security | Employee documents + payslips served via signed temporary URLs | `Storage::temporaryUrl($path, now()->addMinutes(5))` in `DocumentController` and `PayslipController` |
| NFR-007 | Security | Payslip PDFs password-protected | `PayslipService::getPasswordForEmployee()` returns `PANlast4 + DDYYYY(DOB)`. DomPDF: `$pdf->setEncryption($password)` |
| NFR-008 | Compliance | PF/ESI/TDS data retained minimum 7 years | Soft-delete only (BR-HRS-023); no hard-delete routes for compliance tables |
| NFR-009 | Compliance | Payroll computation formula changes logged with effective date | `pay_payroll_formula_changelog` table (optional — can be in `sys_activity_logs` with type='formula_change') |
| NFR-010 | Availability | HR operations must not block payroll runs | LOP reconciliation and payroll computation in separate queued jobs |
| NFR-011 | Auditability | All leave approve/reject/cancel and payroll approve/lock actions in sys_activity_logs | `sys_activity_logs` write in ALL approval/rejection/lock service methods with `causer_id`, `subject_type`, `subject_id`, `description` |
| NFR-012 | Scalability | 500 employees max per tenant; leave balance init < 30 s; payroll computation ≤100 < 30 s | Chunked DB operations (chunk(50)) in LeaveService::initializeBalances() |
| NFR-013 | Accessibility | All forms WCAG 2.1 AA; keyboard navigable | Blade forms: proper label/input association; ARIA roles on modals; focus management |
| NFR-014 | Localization | All currency in INR; dates DD-MM-YYYY display; ISO 8601 in DB | `number_format($amount, 2)` + `₹` prefix; Carbon::parse(date)->format('d-m-Y') for display |
| NFR-015 | Data Integrity | Locked payroll run rows immutable | `PayrollRunService` checks `status = locked` before ANY write operation; throws `PayrollLockedException` |

---

## 11. Test Plan Outline

### 11.1 Feature Tests (Pest) — 15 files, ~75 tests

| File | Tests | Key Scenarios |
|---|---|---|
| `LeaveApplicationTest` | 8 | Apply leave, balance check blocks zero-balance, overlap rejection, half-day = 0.5 days, backdated within window, beyond window rejected, ML gender restriction |
| `LeaveApprovalTest` | 6 | L1 approve (1-level), L1→L2 approve (2-level), L1 reject, L2 reject, return for clarification, cancel after approval restores balance |
| `LeaveBalanceTest` | 5 | Initialize balances for all employees, carry-forward capped correctly, manual adjustment logged, year-end lapse of excess, LWP balance always 0 |
| `LopReconciliationTest` | 4 | Flag absent without leave, confirm LOP (HR Manager only), waive LOP with reason, LOP consumed by payroll month field |
| `SalaryAssignmentTest` | 4 | Assign structure, CTC above grade max rejected, revision closes prior row, history entry created |
| `ComplianceRecordTest` | 5 | PF enrollment, ESI enrollment, TDS declaration with PAN encryption, PT slab lookup, gratuity eligibility 5-year check |
| `AppraisalTest` | 6 | Cycle lifecycle (draft→active→closed), self-submit locks form, reviewer submit, finalize creates increment flag, weight sum != 100 rejected, reopening by HR logs activity |
| `SalaryStructureTest` | 5 | Create structure with components, CTC preview calculation, missing BASIC component rejected, duplicate component rejected, inactive structure not assignable |
| `PayrollRunTest` | 8 | Initiate run, duplicate regular run blocked (BR-PAY-001), compute triggers status change, manual override requires reason, approval flow, lock event fired, locked run immutable (BR-PAY-003), supplementary run with parent_run_id |
| `PayslipGenerationTest` | 5 | Single generate creates media + record, bulk dispatches job, email sets email_status=pending, password format validated, re-generate blocked after lock (BR-PAY-012) |
| `TdsComputationTest` | 6 | Old regime calculation, new regime calculation, mid-year regime change, December recompute for year-end, negative TDS floors to 0 (BR-PAY-006), YTD cumulative carried to tds_ledger |
| `Form16Test` | 3 | Generate Form 16 creates PDF + record, employee download (Gate check), generation blocked before April 15 |
| `BankFileTest` | 3 | CSV export includes only pending payments, SBI format columns correct, export blocked before approved status (BR-PAY-007) |
| `PfEcrTest` | 3 | ECR pipe-delimited format, UAN validation, sum-check passes + status updated to challan_generated |
| `IncrementProcessingTest` | 4 | Policy-based increment proposal from rating, ad-hoc revision creates new assignment, effective date enforcement (future-only), flag marked processed after apply |

### 11.2 Unit Tests (PHPUnit) — 7 files, ~30 tests

| File | Tests | Key Scenarios |
|---|---|---|
| `LeaveDayCalculatorTest` | 5 | Weekends excluded (2 holidays in range), national holidays excluded, half-day = 0.5, cross-month range, zero days if all excluded |
| `GratuityCalculatorTest` | 3 | Standard: 15×basic×years/26, 5-year threshold (4.9 years = not eligible), partial year rounding (floor) |
| `AppraisalRatingCalculatorTest` | 4 | Weighted average correct, weight sum != 100 throws, HR tolerance ±10% accepted, HR beyond ±10% rejected |
| `EmpCodeGeneratorTest` | 3 | Format regex `EMP/YYYY/NNN` matches, year from joining_date, sequential NNN unique within tenant |
| `PayrollComputationUnitTest` | 8 | Gross from components, LWP formula correct, PF 12% of basic_da, ESI 0.75% of gross, ESI zero above ₹21K, PT slab lookup, TDS monthly via projection, net pay = gross − all deductions |
| `TdsProjectionTest` | 5 | Projected income formula, 80C cap at ₹1.5L, HRA exemption applied in old regime, remaining months division, December recompute adjusts for year-end |
| `PayslipPasswordTest` | 2 | Format `PANlast4 + DDYYYY(DOB)` for standard employee, special chars in PAN handled gracefully |

### 11.3 Test Data Requirements

**Required Seeders for Tests:**
- `HrsLeaveTypeSeeder` — must run before all leave tests
- `PaySalaryComponentSeeder` — must run before structure + payroll tests
- `PaySalaryStructureSeeder` — must run before assignment + payroll tests
- `HrsPtSlabSeeder` — must run before payroll computation tests

**Required Factories:**
```
EmploymentDetailFactory     — generates valid contract_type, encrypted bank details
LeaveApplicationFactory     — generates valid date ranges, valid leave_type_id reference
AppraisalFactory            — generates cycle_id, ratings JSON matching template KPIs
PayrollRunFactory           — generates payroll_month (YYYY-MM), status=draft
PayrollRunDetailFactory     — generates all numeric fields, computation_json with component array
```

**Mock Strategy:**
```php
// LOP reconciliation tests
att_staff_attendances → mock with test double or skip if table absent

// Queue tests (payroll computation, bulk payslip)
Queue::fake();
ProcessPayrollJob::assertDispatched();

// Event tests (PayrollApproved, AppraisalFinalized)
Event::fake([PayrollApproved::class, AppraisalFinalized::class]);
PayrollApproved::assertDispatched(fn($e) => $e->payrollRunId === $run->id);

// All Feature tests
uses(Tests\TestCase::class, RefreshDatabase::class);
// Tenant context: create test tenant, switch DB, run seeders in setUp()
```

---

*Document ends.*
*Total FRs: 46 (HRS-001 to HRS-046).*
*Total Tables: 33 (23 hrs_* + 10 pay_*).*
*Total Business Rules: 35 (BR-HRS-001–024 + BR-PAY-001–012, but note BR-HRS numbering goes to 024 = 24 rules; BR-PAY = 12 rules; total = 36 entries, but BR-HRS-021-024 are "General Rules" so all 35+ rules are covered).*
*Total Services: 15.*
*Total Events: 6.*
