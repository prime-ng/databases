# HrStaff Module — Requirement Specification Document v2
**Version:** 2.0  |  **Date:** 2026-03-26  |  **Author:** Claude Code (Automated)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** HRS  |  **Module Path:** `📐 Proposed: Modules/HrStaff/`
**Module Type:** Tenant  |  **Database:** `📐 Proposed: tenant_db`
**Table Prefix:** `hrs_*`  |  **Processing Mode:** RBS_ONLY
**RBS Reference:** C (Staff & HR Management)  |  **RBS Version:** v4.0
**V1 Baseline:** `2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Pending/HRS_HrStaff_Requirement.md`
**Gap Analysis:** N/A (Greenfield module)
**Generation Batch:** 8/10

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
| Module Name | HrStaff |
| Module Code | HRS |
| Laravel Module Namespace | `Modules\HrStaff` |
| Module Path | `📐 Proposed: Modules/HrStaff/` |
| Route Prefix | `hr-staff/` |
| Route Name Prefix | `hr-staff.` |
| DB Table Prefix | `hrs_*` |
| Module Type | Tenant (database-per-tenant via stancl/tenancy v3.9) |
| Registered In | `routes/tenant.php` |

### 1.2 Module Scale (Proposed)

| Artifact | Proposed Count |
|---|---|
| Controllers | 📐 10 |
| Models | 📐 16 |
| Services | 📐 7 |
| FormRequests | 📐 18 |
| Policies | 📐 10 |
| DDL Tables | 📐 15 |
| Views (Blade) | 📐 ~60 |

### 1.3 Module Purpose

HrStaff is the HR workflow and compliance layer for Prime-AI. It **extends** the existing `sch_employees` / `sch_employee_profiles` / `sch_departments` / `sch_designations` records with HR-specific data: leave management, salary structure assignment, statutory compliance (PF/ESI/TDS/Gratuity), performance appraisal, employee documents, and ID card generation. Payroll calculation remains in the separate `prl_*` module.

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

### 2.2 Primary User Roles

| Role | Key Actions |
|---|---|
| HR Manager | Full CRUD, leave approvals, compliance records, payroll prep, appraisal management |
| Principal | View all records, final-level leave approval, appraisal finalization |
| HOD | Approve leave for department, initiate/review department appraisals |
| Employee (Self-Service) | Apply leave, submit self-appraisal, view leave balance, download ID card |
| Accountant | Read salary structure assignments, PF/ESI registers (read-only) |

### 2.3 Indian Compliance Context

| Statutory | Applicability | Rate |
|---|---|---|
| PF (EPF Act 1952) | Employee basic ≤ ₹15,000 — mandatory; else voluntary | Employee 12%; Employer 12% (3.67% EPF + 8.33% EPS) |
| ESI (ESI Act 1948) | Employee gross ≤ ₹21,000 | Employee 0.75%; Employer 3.25% |
| TDS (IT Act Sec 192) | All salaried employees | Per tax slab — handled by Payroll |
| Gratuity (Gratuity Act 1972) | After 5 years continuous service | 15 days × last basic × years / 26 |
| PT (Profession Tax) | State-wise slabs | HrStaff stores enrollment; Payroll deducts |

---

## 3. Scope and Boundaries

### 3.1 In-Scope

- Employee HR record extension (contract type, bank details, emergency contacts, employment history)
- Employee document repository (upload, categorize, expiry reminders)
- Leave type configuration, holiday calendar, leave balance management
- Leave application and multi-level approval workflow (HOD → Principal)
- Attendance-leave reconciliation and LOP flagging
- Salary structure assignment (mapping employee to `prl_salary_structures`)
- Pay grade master
- Statutory compliance records: PF, ESI, TDS declarations, Gratuity
- Performance appraisal: KPI templates, appraisal cycles, self-appraisal, manager review, finalization
- Staff ID card generation (QR code, DomPDF)
- HR reports: headcount, attrition, leave utilization, compliance status

### 3.2 Out of Scope

| Item | Owner Module |
|---|---|
| Salary calculation, payslip generation | Payroll (`prl_*`) |
| Actual PF/ESI remittance and bank payment | Finance/Accounting (`acc_*`) |
| Form 16 generation and TDS computation | Payroll (`prl_*`) |
| Biometric device sync | Attendance (`att_*`) |
| Recruitment and applicant tracking | Future module (not planned) |
| Staff mobile app portal | Future phase |
| Performance-linked variable pay computation | Payroll (triggered by finalized appraisal flag) |

---

## 4. Functional Requirements

> All items are **📐 Proposed** and status is **❌ Not Started**.

---

### 4.1 Sub-Module C1 — Staff HR Records

#### FR-HRS-001: Employee HR Details Extension 📐 ❌
- HR Manager records employment details in `hrs_employment_details` (one row per employee):
  - `contract_type`: `permanent` | `contractual` | `probation` | `part_time` | `substitute`
  - Probation period (months), probation end date, confirmation date
  - Notice period (days)
  - Bank account: account number, IFSC, bank name, branch (application-level encrypted)
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
- Template configurable per school (logo, colors, fields shown).
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
  - `max_backdated_days` (how many past days an application can cover)
  - `min_advance_days` (minimum advance notice for EL/PL)
  - `approval_levels`: 1 (HOD only) or 2 (HOD → Principal)
  - `optional_holiday_count` per employee per year

#### FR-HRS-008: Leave Balance Initialization 📐 ❌
- HR Manager triggers annual balance initialization (per academic year) → creates `hrs_leave_balances` rows:
  - Per employee × per leave type: `allocated_days`, `carry_forward_days`, `used_days` (default 0), `lop_days` (default 0)
  - Carry-forward from prior year: `MIN(prior_year_closing_balance, leave_type.carry_forward_days)`
- Manual adjustments logged in `hrs_leave_balance_adjustments` (reason required).

#### FR-HRS-009: Leave Application 📐 ❌
- Employee (self-service) submits `hrs_leave_applications`:
  - `leave_type_id`, `from_date`, `to_date`, `half_day` flag + half (`first` | `second`), `reason`, `media_id` (supporting doc)
  - `days_count` auto-calculated (excluding weekends + holidays from calendar)
- Pre-submission validations:
  1. Balance sufficient (except LWP)
  2. No overlapping approved leave
  3. Min service months satisfied
  4. Date range within allowed backdated/advance window
- Status on creation: `pending`.

#### FR-HRS-010: Leave Approval Workflow 📐 ❌
- Approval driven by `hrs_leave_policies.approval_levels` (1 or 2 levels).
- Each approval step stored in `hrs_leave_approvals` (`application_id`, `approver_id`, `level`, `action`, `remarks`, `actioned_at`).
- Approver actions: `approve` | `reject` | `return_for_clarification`.
- On final approval: balance updated (`used_days` += `days_count`); notification to employee.
- Employee can cancel if `from_date` is in the future → balance restored; `status` → `cancelled`.
- See Section 9 for FSM.

#### FR-HRS-011: Leave Balance Dashboard 📐 ❌
- Employee view: balance card per leave type (allocated, used, available, carry-forward) for current academic year.
- HR Manager view: matrix report (employees × leave types) with department/designation filters.
- Export: CSV and PDF.

#### FR-HRS-012: LOP Reconciliation 📐 ❌
- HrStaff reads `att_staff_attendances` (read-only).
- Absent without approved leave → auto-flagged in `hrs_lop_records` (employee, date, flag status: `flagged` | `confirmed` | `waived`).
- HR Manager reviews and confirms LOP before month-end close.
- Confirmed LOP records consumed by Payroll module as deduction input.

---

### 4.3 Sub-Module C4 — Payroll Preparation (HrStaff Scope)

> Full payroll processing is in `prl_*`. HrStaff manages the employee–salary mapping that Payroll reads.

#### FR-HRS-013: Pay Grade Master 📐 ❌
- HR Manager configures `hrs_pay_grades`: `grade_name`, `min_ctc`, `max_ctc`, `applicable_designation_ids` (JSON).

#### FR-HRS-014: Salary Structure Assignment 📐 ❌
- HR Manager assigns salary structure per employee in `hrs_salary_assignments`:
  - `employee_id`, `prl_salary_structure_id`, `pay_grade_id`, `ctc_amount`, `gross_monthly`, `effective_from_date`, `effective_to_date`, `revision_reason`
- History preserved: new row per revision; prior row gets `effective_to_date` set.
- Payroll reads latest active assignment for payroll run.

---

### 4.4 Sub-Module C4 — Statutory Compliance

#### FR-HRS-015: PF Compliance Records 📐 ❌
- `hrs_compliance_records` (one row per employee per `compliance_type`):
  - `compliance_type = 'pf'`: UAN, enrollment date, applicable flag, nominee JSON (name, relationship, share %)
- Monthly `hrs_pf_contribution_register`: month/year, basic wage, employee contribution (12%), employer EPF (3.67%), employer EPS (8.33%), status (`computed` | `submitted` | `challan_generated`).
- Export: Form 12A format (PDF/CSV).

#### FR-HRS-016: ESI Compliance Records 📐 ❌
- `hrs_compliance_records` (`compliance_type = 'esi'`): IP number, enrollment date, applicable flag, dispensary details.
- Monthly `hrs_esi_contribution_register`: gross wage, employee 0.75%, employer 3.25%, status.
- Export: Form 5 half-yearly returns (PDF/CSV).

#### FR-HRS-017: TDS Declaration Storage 📐 ❌
- `hrs_compliance_records` (`compliance_type = 'tds'`): PAN (encrypted), tax regime (`old` | `new`), investment declarations JSON (80C, 80D, HRA, LTA).
- Form 16 generation delegated to Payroll.

#### FR-HRS-018: Gratuity Records 📐 ❌
- `hrs_compliance_records` (`compliance_type = 'gratuity'`): applicable flag, nominee details, eligibility date (joining + 5 years), projected amount (`last_basic × 15 × service_years / 26`).
- On employee exit: computed amount passed to Finance module.

---

### 4.5 Sub-Module C8 — Performance Appraisal 📐

#### FR-HRS-019: KPI Template Management 📐 ❌
- HR Manager creates `hrs_kpi_templates` with `hrs_kpi_template_items`:
  - Template: `name`, `applicable_to` (`all` | `teaching` | `non_teaching`), `rating_scale` (5 or 10)
  - Item: `kpi_name`, `category` (`academic` | `behavioral` | `administrative`), `weight` (%, must sum 100 per template), `description`

#### FR-HRS-020: Appraisal Cycle Configuration 📐 ❌
- HR Manager creates `hrs_appraisal_cycles`:
  - `name`, `academic_year_id`, `appraisal_type` (`annual` | `mid_year` | `probation` | `confirmation`)
  - `kpi_template_id`, `self_appraisal_open_date`, `self_appraisal_close_date`, `manager_review_open_date`, `manager_review_close_date`
  - `applicable_departments` (JSON), `reviewer_assignment_mode` (`auto` = reporting_to hierarchy | `manual`)

#### FR-HRS-021: Self-Appraisal Submission 📐 ❌
- Employee enters `hrs_appraisals` (one per employee per cycle):
  - Per KPI item: self-rating (within scale), self-comments, optional evidence upload
  - Status: `draft` → `submitted` (cannot revert without HR unlock)

#### FR-HRS-022: Manager Review and Finalization 📐 ❌
- Reviewer (HOD/Principal) enters reviewer rating + comments per KPI item.
- System computes `overall_rating` = weighted average of reviewer ratings.
- Status: `submitted` → `reviewed` → `finalized` (by HR Manager).
- Finalization triggers: employee notification with rating; sets `hrs_appraisal_increment_flags` for Payroll.

---

### 4.6 Sub-Module C9 — Staff ID Card

Already covered in FR-HRS-004. ID card templates are configured in `hrs_id_card_templates` (logo, layout, fields, colors).

---

## 5. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| NFR-001 | Performance | Leave balance read < 200 ms for single employee |
| NFR-002 | Performance | Monthly LOP reconciliation for 200 employees < 10 s |
| NFR-003 | Security | Bank account numbers encrypted at application level (AES-256); PAN encrypted |
| NFR-004 | Security | Employee documents served via signed temporary URLs (no public paths) |
| NFR-005 | Compliance | PF/ESI contribution data retained for minimum 7 years (soft-delete only) |
| NFR-006 | Availability | HR module must not block payroll runs — async where possible |
| NFR-007 | Auditability | All leave approve/reject/cancel actions logged in `sys_activity_logs` |
| NFR-008 | Scalability | Up to 500 employees per tenant; leave balance init < 30 s |
| NFR-009 | Accessibility | All forms WCAG 2.1 AA; keyboard navigable |
| NFR-010 | Localization | All currency in INR; dates in DD-MM-YYYY (display); DB stores ISO 8601 |

---

## 6. Database Schema

> All tables include standard columns: `id`, `is_active` (default 1), `created_by`, `created_at`, `updated_at`, `deleted_at`.
> All tables use InnoDB, UTF8MB4, MySQL 8.x.
> 📐 All proposed.

### 6.1 hrs_employment_details
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| employee_id | BIGINT FK | → `sch_employees.id` UNIQUE |
| contract_type | ENUM | `permanent`,`contractual`,`probation`,`part_time`,`substitute` |
| probation_end_date | DATE | nullable |
| confirmation_date | DATE | nullable |
| notice_period_days | TINYINT | default 30 |
| bank_account_number | TEXT | AES-256 encrypted |
| bank_ifsc | VARCHAR(11) | |
| bank_name | VARCHAR(100) | |
| bank_branch | VARCHAR(100) | |
| emergency_contact_json | JSON | name, relationship, phone, address |
| previous_employer_json | JSON | nullable |

### 6.2 hrs_employment_history
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| employee_id | BIGINT FK | → `sch_employees.id` |
| change_type | VARCHAR(50) | `contract_type`,`department`,`designation`,`pay_grade` |
| old_value | JSON | |
| new_value | JSON | |
| effective_date | DATE | |
| changed_by | BIGINT FK | → `sch_employees.id` |
| remarks | TEXT | nullable |

### 6.3 hrs_employee_documents
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| employee_id | BIGINT FK | → `sch_employees.id` |
| document_type | VARCHAR(50) | see FR-HRS-003 enum |
| document_name | VARCHAR(200) | |
| media_id | BIGINT FK | → `sys_media.id` |
| issued_date | DATE | nullable |
| expiry_date | DATE | nullable |
| issued_by | VARCHAR(150) | |
| remarks | TEXT | nullable |

### 6.4 hrs_leave_types
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
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
| id | BIGINT PK | |
| academic_year_id | BIGINT FK | → `sch_academic_years.id` |
| holiday_date | DATE | |
| holiday_name | VARCHAR(150) | |
| holiday_type | ENUM | `national`,`state`,`school`,`optional` |
| applicable_to | ENUM | `all`,`teaching`,`non_teaching` |

### 6.6 hrs_leave_policies
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| academic_year_id | BIGINT FK | nullable (NULL = global default) |
| max_backdated_days | TINYINT | default 3 |
| min_advance_days | TINYINT | default 0 |
| approval_levels | TINYINT | 1 or 2 |
| optional_holiday_count | TINYINT | default 2 |

### 6.7 hrs_leave_balances
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
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
| id | BIGINT PK | |
| leave_balance_id | BIGINT FK | → `hrs_leave_balances.id` |
| adjustment_days | DECIMAL(5,1) | positive = add, negative = deduct |
| reason | TEXT | |
| adjusted_by | BIGINT FK | → `sch_employees.id` |

### 6.9 hrs_leave_applications
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
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
| status | ENUM | `pending`,`approved`,`rejected`,`cancelled`,`returned` |
| current_approver_level | TINYINT | 1 or 2 |

### 6.10 hrs_leave_approvals
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| application_id | BIGINT FK | → `hrs_leave_applications.id` |
| approver_id | BIGINT FK | → `sch_employees.id` |
| level | TINYINT | 1 = HOD, 2 = Principal |
| action | ENUM | `approve`,`reject`,`return_for_clarification` |
| remarks | TEXT | |
| actioned_at | TIMESTAMP | |

### 6.11 hrs_pay_grades
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| grade_name | VARCHAR(100) | |
| min_ctc | DECIMAL(12,2) | |
| max_ctc | DECIMAL(12,2) | |
| applicable_designation_ids | JSON | array of designation IDs |

### 6.12 hrs_salary_assignments
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| employee_id | BIGINT FK | → `sch_employees.id` |
| prl_salary_structure_id | BIGINT | FK to Payroll module table |
| pay_grade_id | BIGINT FK | → `hrs_pay_grades.id` |
| ctc_amount | DECIMAL(12,2) | |
| gross_monthly | DECIMAL(12,2) | |
| effective_from_date | DATE | |
| effective_to_date | DATE | nullable |
| revision_reason | VARCHAR(200) | |

### 6.13 hrs_compliance_records
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| employee_id | BIGINT FK | → `sch_employees.id` |
| compliance_type | ENUM | `pf`,`esi`,`tds`,`gratuity` |
| reference_number | VARCHAR(100) | UAN / IP number / PAN (encrypted for TDS) |
| enrollment_date | DATE | |
| applicable_flag | TINYINT(1) | |
| nominee_json | JSON | nullable — for PF gratuity nominees |
| details_json | JSON | type-specific fields |
| UNIQUE | | (employee_id, compliance_type) |

### 6.14 hrs_appraisal_cycles
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
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
| id | BIGINT PK | |
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

### Auxiliary Tables (not full schema — referenced by FRs)
- `hrs_kpi_templates` — id, name, applicable_to, rating_scale
- `hrs_kpi_template_items` — id, template_id, kpi_name, category, weight, description
- `hrs_lop_records` — id, employee_id, date, flag_status (`flagged`|`confirmed`|`waived`), confirmed_by
- `hrs_id_card_templates` — id, name, layout_json, is_default
- `hrs_pf_contribution_register` — id, compliance_record_id, month, year, basic_wage, emp_contribution, employer_epf, employer_eps, status
- `hrs_esi_contribution_register` — id, compliance_record_id, month, year, gross_wage, emp_contribution, employer_contribution, status
- `hrs_appraisal_increment_flags` — id, appraisal_id, employee_id, cycle_id, flag_status (`pending`|`processed`)

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

### 7.3 Payroll Preparation & Compliance

| Method | URI | Name | Controller | FR |
|---|---|---|---|---|
| GET/POST/PUT/DELETE | `hr-staff/pay-grades/{id?}` | `hr-staff.pay-grades.*` | PayGradeController | HRS-013 |
| GET/POST/PUT | `hr-staff/employees/{emp}/salary` | `hr-staff.salary.*` | SalaryAssignmentController | HRS-014 |
| GET/POST/PUT | `hr-staff/employees/{emp}/compliance/{type}` | `hr-staff.compliance.*` | ComplianceController | HRS-015–018 |
| GET | `hr-staff/compliance/pf-register` | `hr-staff.compliance.pf-register` | ComplianceController@pfRegister | HRS-015 |
| GET | `hr-staff/compliance/esi-register` | `hr-staff.compliance.esi-register` | ComplianceController@esiRegister | HRS-016 |

### 7.4 Appraisal

| Method | URI | Name | Controller | FR |
|---|---|---|---|---|
| GET/POST/PUT/DELETE | `hr-staff/kpi-templates/{id?}` | `hr-staff.kpi-templates.*` | AppraisalController | HRS-019 |
| GET/POST/PUT | `hr-staff/appraisal-cycles/{id?}` | `hr-staff.cycles.*` | AppraisalController | HRS-020 |
| GET/POST | `hr-staff/appraisals/{id?}` | `hr-staff.appraisals.*` | AppraisalController | HRS-021–022 |
| POST | `hr-staff/appraisals/{apr}/submit-self` | `hr-staff.appraisals.submit-self` | AppraisalController@submitSelf | HRS-021 |
| POST | `hr-staff/appraisals/{apr}/submit-review` | `hr-staff.appraisals.submit-review` | AppraisalController@submitReview | HRS-022 |
| POST | `hr-staff/appraisals/{apr}/finalize` | `hr-staff.appraisals.finalize` | AppraisalController@finalize | HRS-022 |

---

## 8. Business Rules

### 8.1 Leave Rules

| Rule ID | Rule |
|---|---|
| BR-HRS-001 | Leave balance cannot go below 0 except for LWP type |
| BR-HRS-002 | Overlapping approved leave for same employee is rejected at validation |
| BR-HRS-003 | Carry-forward capped at `hrs_leave_types.carry_forward_days`; excess is lapsed at year end |
| BR-HRS-004 | Backdated leave applications allowed only within `hrs_leave_policies.max_backdated_days` |
| BR-HRS-005 | Medical certificate mandatory for SL > `medical_cert_threshold_days` |
| BR-HRS-006 | ML applicable only to female employees; PL only to male employees |
| BR-HRS-007 | Min service months enforced at application time (EL: 6 months default) |
| BR-HRS-008 | Cancellation of approved leave allowed only if `from_date > today`; balance restored |
| BR-HRS-009 | LOP deduction is not automatic — HR Manager must confirm before month close |

### 8.2 Salary & Compliance Rules

| Rule ID | Rule |
|---|---|
| BR-HRS-010 | Only one active salary assignment per employee at any time (enforced via `effective_to_date`) |
| BR-HRS-011 | CTC must be within `hrs_pay_grades.min_ctc` and `max_ctc` for assigned pay grade |
| BR-HRS-012 | PF mandatory when `basic_salary ≤ ₹15,000`; voluntary otherwise |
| BR-HRS-013 | ESI mandatory when `gross_salary ≤ ₹21,000`; not applicable otherwise |
| BR-HRS-014 | Gratuity eligibility only after 5 years of continuous service from joining date |
| BR-HRS-015 | PAN and bank account number encrypted; never logged in plain text in `sys_activity_logs` |

### 8.3 Appraisal Rules

| Rule ID | Rule |
|---|---|
| BR-HRS-016 | KPI item weights within a template must sum exactly to 100 |
| BR-HRS-017 | Self-appraisal submission locks the form; HR Manager must explicitly unlock for re-edit |
| BR-HRS-018 | Manager review window cannot open before self-appraisal close date |
| BR-HRS-019 | Finalized appraisal cannot be modified; only HR Manager can reopen with audit log entry |
| BR-HRS-020 | HR Manager overall rating adjustment limited to ±10% of computed weighted average |

### 8.4 General Rules

| Rule ID | Rule |
|---|---|
| BR-HRS-021 | `emp_code` format: `EMP/YYYY/NNN` — auto-generated, unique within tenant, immutable after creation |
| BR-HRS-022 | Employee document expiry reminders fire at 30 days before `expiry_date` (single notification) |
| BR-HRS-023 | Soft-delete only (`deleted_at` + `is_active=0`); permanent deletion not permitted |
| BR-HRS-024 | All approval/rejection actions require non-empty `remarks` field |

---

## 9. Workflow State Machines

### 9.1 Leave Application FSM

```
                  ┌──────────────────────────────────────────┐
                  │           Employee submits                │
                  ▼                                           │
            [PENDING] ──── HOD rejects ────────────► [REJECTED]
                  │
                  │ HOD approves (level 1)
                  │ (if approval_levels = 1 → skip to APPROVED)
                  ▼
          [PENDING_L2] ──── Principal rejects ──────► [REJECTED]
                  │                                    (balance unchanged)
                  │ Principal approves (level 2)
                  ▼
           [APPROVED] ──── Employee cancels ──────────► [CANCELLED]
                            (from_date > today)          (balance restored)

          ─── HOD returns ──► [RETURNED] ──── Employee resubmits ──► [PENDING]

States:   pending | pending_l2 | approved | rejected | cancelled | returned
Triggers: approve(level) | reject(level) | return_for_clarification | cancel
Side effects:
  - approved: hrs_leave_balances.used_days += days_count
  - cancelled: hrs_leave_balances.used_days -= days_count
  - All transitions: ntf_notifications dispatched to employee
  - All transitions: sys_activity_logs entry
```

### 9.2 Payroll Run Integration FSM (HrStaff's contribution)

```
HrStaff side (month-end preparation):
  ┌─────────────────────────────────────────────────────────────┐
  │ 1. HR Manager confirms LOP records                          │
  │    hrs_lop_records.flag_status: flagged → confirmed         │
  │                                                             │
  │ 2. Salary assignments verified (active assignment exists)   │
  │    hrs_salary_assignments.effective_to_date IS NULL         │
  │    or effective_to_date >= payroll_month                    │
  │                                                             │
  │ 3. Compliance records current (PF/ESI applicable flags set) │
  │                                                             │
  │ 4. HR Manager signals "Ready for Payroll"                   │
  │    → Payroll module reads: salary assignments +             │
  │      confirmed LOP records + compliance applicability       │
  └─────────────────────────────────────────────────────────────┘

Payroll side (prl_* module — out of HrStaff scope):
  payroll_run.status: draft → processing → computed → approved → disbursed

  On PayrollApproved event (fired by prl_*):
    → Accounting module creates Payroll Journal Voucher (acc_* module)
    → hrs_pf_contribution_register.status: computed → submitted (triggered by prl_*)
    → hrs_esi_contribution_register.status: computed → submitted
```

### 9.3 Appraisal FSM

```
Cycle created → [DRAFT]
     │
     │ HR activates cycle
     ▼
  [ACTIVE]
     │
     │ Self-appraisal window open
     │ Employee → appraisal.status: draft → submitted
     │
     │ Manager review window open
     │ Reviewer → appraisal.status: submitted → reviewed
     │
     │ HR Manager finalizes each appraisal
     │ appraisal.status: reviewed → finalized
     │
     │ All appraisals finalized
     ▼
  [CLOSED]
     │
     └── hrs_appraisal_increment_flags created for Payroll
```

---

## 10. Authorization and RBAC

### 10.1 Roles and Permissions

| Permission | HR Manager | Principal | HOD | Employee | Accountant |
|---|---|---|---|---|---|
| `hrs.employment.manage` | Yes | No | No | No | No |
| `hrs.documents.manage` | Yes | No | No | Own | No |
| `hrs.leave_type.manage` | Yes | No | No | No | No |
| `hrs.leave.apply` | Yes | No | No | Yes | No |
| `hrs.leave.approve_l1` | Yes | No | Yes | No | No |
| `hrs.leave.approve_l2` | Yes | Yes | No | No | No |
| `hrs.leave.balance.view` | Yes | Yes | Dept | Own | No |
| `hrs.lop.confirm` | Yes | No | No | No | No |
| `hrs.salary.manage` | Yes | No | No | No | Read |
| `hrs.compliance.manage` | Yes | No | No | No | Read |
| `hrs.appraisal.manage` | Yes | No | No | No | No |
| `hrs.appraisal.review` | Yes | Yes | Yes | No | No |
| `hrs.appraisal.self` | Yes | No | No | Yes | No |
| `hrs.idcard.generate` | Yes | No | No | Own | No |

> Permissions registered in `sys_permissions` and assigned to roles via `sys_model_has_roles_jnt`.

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
| `PayGradePolicy` | `PayGrade` | `hrs.salary.manage` |

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
| `ComplianceService` | PF/ESI/TDS/Gratuity record management, generate contribution registers, export reports |
| `AppraisalService` | Cycle management, appraisal form routing, overall rating computation, increment flag creation |
| `IdCardService` | Generate ID card PDF via DomPDF, store in sys_media |

### 11.2 Key Service Methods

**LeaveService:**
- `initializeBalances(int $academicYearId): void` — bulk insert for all active employees
- `calculateDays(int $leaveTypeId, Carbon $from, Carbon $to, bool $halfDay): float`
- `applyLeave(array $data, int $employeeId): LeaveApplication`
- `cancelLeave(int $applicationId): bool`
- `runLopReconciliation(Carbon $month): Collection`

**LeaveApprovalService:**
- `approve(LeaveApplication $app, int $approverId, string $remarks): bool`
- `reject(LeaveApplication $app, int $approverId, string $remarks): bool`
- `returnForClarification(LeaveApplication $app, int $approverId, string $remarks): bool`
- `getNextApprover(LeaveApplication $app): ?Employee`

**ComplianceService:**
- `computePfRegister(int $month, int $year): Collection`
- `computeEsiRegister(int $month, int $year): Collection`
- `exportPfForm12A(int $month, int $year): BinaryFileResponse`
- `exportEsiForm5(int $halfYear, int $year): BinaryFileResponse`

**AppraisalService:**
- `computeOverallRating(Appraisal $appraisal): float` — weighted avg of reviewer KPI ratings
- `finalizeAppraisal(int $appraisalId, string $hrRemarks, ?float $adjustedRating): bool`
- `createIncrementFlags(int $cycleId): void`

---

## 12. Integration Points

### 12.1 Inbound Integrations (HrStaff reads from)

| Source Module | Table/Event | Purpose | Access Type |
|---|---|---|---|
| SchoolSetup (`sch_*`) | `sch_employees`, `sch_employee_profiles` | Employee base record | Read + extend |
| SchoolSetup (`sch_*`) | `sch_departments`, `sch_designations` | Department/designation reference | Read-only |
| SchoolSetup (`sch_*`) | `sch_academic_years` | Leave balance year scoping | Read-only |
| Attendance (`att_*`) | `att_staff_attendances` | LOP reconciliation | Read-only |
| Payroll (`prl_*`) | `prl_salary_structures` | Salary structure FK for assignments | Read-only |
| System (`sys_*`) | `sys_media` | Document and ID card file storage | Read + write |
| System (`sys_*`) | `sys_activity_logs` | Audit trail | Write-only |

### 12.2 Outbound Integrations (HrStaff provides to)

| Consumer Module | Table/Event | Data Provided |
|---|---|---|
| Payroll (`prl_*`) | `hrs_salary_assignments` | Active salary structure per employee |
| Payroll (`prl_*`) | `hrs_lop_records` (confirmed) | LOP days per employee for deduction |
| Payroll (`prl_*`) | `hrs_compliance_records` | PF/ESI applicability flags |
| Payroll (`prl_*`) | `hrs_appraisal_increment_flags` | Increment signal post-appraisal finalization |
| Accounting (`acc_*`) | `PayrollApproved` event (listener) | Triggers Journal Voucher creation |
| Finance (`acc_*`) | Gratuity computed amount on exit | Disbursement input |
| Notification (`ntf_*`) | `ntf_notifications` dispatch | Leave approved/rejected, document expiry |

### 12.3 Event Contracts

| Event | Fired By | Listener | Action |
|---|---|---|---|
| `LeaveApproved` | LeaveApprovalService | NotificationService | Dispatch employee notification |
| `LeaveRejected` | LeaveApprovalService | NotificationService | Dispatch employee notification |
| `DocumentExpiringSoon` | Scheduled command | HrStaff | Dispatch HR manager notification |
| `AppraisalFinalized` | AppraisalService | Payroll module | Create increment flag |
| `PayrollApproved` | Payroll module | Accounting module | Create Payroll Journal Voucher |

---

## 13. UI/UX Requirements

### 13.1 Key Screens

| Screen | Route Name | Description |
|---|---|---|
| Employee HR Profile | `hr-staff.employment.show` | Tabbed view: Employment Details / Documents / Compliance / History |
| Leave Type List | `hr-staff.leave-types.index` | CRUD grid with enable/disable toggle |
| Holiday Calendar | `hr-staff.holidays.index` | Month-view calendar with add/edit modal |
| Leave Balance Dashboard | `hr-staff.balances.index` | Matrix table (employee × leave type) with dept filter |
| Leave Application Form | `hr-staff.applications.create` | Date range picker, auto calculated days, balance preview |
| Pending Approvals | `hr-staff.applications.pending` | Tabbed: My Pending / All Pending (HR Manager) |
| LOP Reconciliation | `hr-staff.lop.index` | Month selector, table with flag/confirm/waive actions |
| Salary Assignment | `hr-staff.salary.edit` | Current structure card + revision history timeline |
| Compliance Dashboard | `hr-staff.compliance.index` | Employee list with PF/ESI/TDS/Gratuity status badges |
| Appraisal Cycle Dashboard | `hr-staff.cycles.index` | Cycle cards with completion progress bars |
| Self-Appraisal Form | `hr-staff.appraisals.self` | KPI grid with rating sliders and comment fields |
| Manager Review Form | `hr-staff.appraisals.review` | Side-by-side self vs manager rating per KPI |
| ID Card Preview | `hr-staff.id-card.show` | Rendered card preview with Generate PDF button |

### 13.2 UX Standards

- All forms use AJAX validation (no full page reload on error).
- Leave application: days-count updates live on date range change.
- Approval screens: approver sees employee balance summary inline before actioning.
- Appraisal form: weight indicator per KPI; running total shows remaining weight to distribute.
- Compliance dashboard: red badge if PF/ESI not enrolled for applicable employee.
- Document list: expiry date color-coded (green > 90 days, amber 30–90 days, red < 30 days).
- All tables: pagination (25/50/100), search, column sort, CSV export.

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
| `ComplianceRecordTest` | 5 | PF enrollment, ESI enrollment, TDS declaration, gratuity calc |
| `AppraisalTest` | 6 | Cycle creation, self-submit, reviewer submit, finalize, weight validation, increment flag |
| `EmploymentDetailsTest` | 3 | Create employment detail, emp_code format, bank detail encryption |

### 14.2 Unit Tests (PHPUnit)

| Test File | Tests | Key Scenarios |
|---|---|---|
| `LeaveDayCalculatorTest` | 5 | Weekends excluded, holidays excluded, half-day = 0.5, cross-month range |
| `GratuityCalculatorTest` | 3 | Standard calc, 5-year threshold enforcement, partial year rounding |
| `AppraisalRatingCalculatorTest` | 4 | Weighted average, weight sum validation, ±10% HR tolerance |
| `EmpCodeGeneratorTest` | 3 | Unique code, format regex, year extraction |

### 14.3 Test Data Strategy

- Seeders: `HrsLeaveTypeSeeder`, `HrsHolidayCalendarSeeder` (national holidays pre-seeded for Indian FY 2025-26)
- Factory: `EmploymentDetailFactory`, `LeaveApplicationFactory`, `AppraisalFactory`
- RefreshDatabase trait on all Feature tests
- `att_staff_attendances` mocked for LOP reconciliation tests (no real Attendance module dependency)

---

## 15. Implementation Priorities

### Phase 1 — Foundation (Sprint 1–2)
> Must-have for module to be usable

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
> Required for month-end payroll integration

| FR | Feature | Effort |
|---|---|---|
| HRS-012 | LOP reconciliation | M |
| HRS-013 | Pay grade master | S |
| HRS-014 | Salary structure assignment | M |
| HRS-015 | PF compliance records | M |
| HRS-016 | ESI compliance records | M |
| HRS-017 | TDS declaration storage | S |
| HRS-018 | Gratuity records | S |
| HRS-004 | Staff ID card generation | M |

### Phase 3 — Appraisal & Reporting (Sprint 5–6)
> Value-add; non-blocking for payroll

| FR | Feature | Effort |
|---|---|---|
| HRS-019 | KPI template management | M |
| HRS-020 | Appraisal cycle configuration | M |
| HRS-021 | Self-appraisal submission | M |
| HRS-022 | Manager review and finalization | L |
| HRS-002 | Employment history log | S |
| HRS-007 | Leave policy configuration | S |

**Effort Key:** S = 1–2 days | M = 3–5 days | L = 6–8 days

---

## 16. Open Questions and Decisions

| # | Question | Options | Recommended |
|---|---|---|---|
| OQ-001 | Should `emp_code` be generated by HrStaff or SchoolSetup? | A: SchoolSetup on sch_employees creation; B: HrStaff on HR onboarding | A — generate in SchoolSetup so it's always available |
| OQ-002 | Bank account encryption: application-level AES or Laravel encrypt()? | A: AES-256 with custom key; B: Laravel `encrypt()` (APP_KEY) | B — simpler, consistent with Laravel conventions |
| OQ-003 | PF/ESI contribution register: auto-compute monthly or HR triggers? | A: Scheduled command auto-computes on 1st of each month; B: HR Manager triggers | A — reduces manual work; HR can re-trigger if needed |
| OQ-004 | Holiday calendar: shared across modules or HrStaff-owned? | A: HrStaff owns `hrs_holiday_calendars`; B: Shared `sch_holiday_calendars` | B preferred — Timetable and Attendance also need holidays |
| OQ-005 | Gratuity disbursement: signal to Accounting or auto-create voucher? | A: HrStaff fires event, Accounting listens; B: HrStaff writes directly to acc_* | A — loose coupling preferred |
| OQ-006 | LOP confirmation: can HOD confirm or only HR Manager? | A: HR Manager only; B: HOD confirms for their dept | A — financial impact; restrict to HR Manager |
| OQ-007 | ID card template: single global template or per-school configurable? | A: Single default DomPDF template; B: Admin-configurable via hrs_id_card_templates | B — per-school branding is a real need |
| OQ-008 | Leave application: can HR Manager apply on behalf of employee? | A: Yes, with `applied_on_behalf_of` flag; B: Employee self-service only | A — needed for offline/verbal requests |

---

*Document ends. Total FRs: 22 (HRS-001 to HRS-022). All items 📐 Proposed. All FR status ❌ Not Started.*
