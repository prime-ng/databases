# HRS — Table Summary (33 Tables)
**Module:** HrStaff (`Modules\HrStaff`) | **Date:** 2026-03-26
**Prefixes:** `hrs_*` (23 tables) + `pay_*` (10 tables)

---

## hrs_* Tables (23)

### Employment Domain (4 tables)
| # | Table | Purpose | Key Constraint |
|---|---|---|---|
| 1 | `hrs_employment_details` | One HR record extension per employee: contract type, bank details (encrypted), emergency contacts | UNIQUE (employee_id) — 1:1 with sch_employees |
| 2 | `hrs_employment_history` | Immutable audit trail of all employment status changes | — |
| 3 | `hrs_employee_documents` | Employee document repository: stores metadata; file in sys_media | — |
| 4 | `hrs_id_card_templates` | School-configurable ID card layout for DomPDF generation | — |

### Leave Management Domain (8 tables)
| # | Table | Purpose | Key Constraint |
|---|---|---|---|
| 5 | `hrs_leave_types` | Configurable leave type master; 7 defaults seeded (CL, EL, SL, ML, PL, CO, LWP) | UNIQUE (code) |
| 6 | `hrs_holiday_calendars` | School holiday calendar per academic year; used to exclude days in leave calculations | — |
| 7 | `hrs_leave_policies` | School-wide leave policy config (max backdated, approval levels); NULL year = global default | — |
| 8 | `hrs_leave_balances` | Per-employee per-leave-type per-year balance (allocated, carry-forward, used, LOP) | UNIQUE (employee_id, leave_type_id, academic_year_id) |
| 9 | `hrs_leave_balance_adjustments` | Audit trail for manual HR Manager balance corrections | — |
| 10 | `hrs_leave_applications` | Employee leave application with 6-state FSM | — |
| 11 | `hrs_leave_approvals` | Approval action log per step per application (HOD / Principal) | — |
| 12 | `hrs_lop_records` | Loss of Pay flags generated from attendance reconciliation; one row per employee per absent date | UNIQUE (employee_id, absent_date) |

### Compliance & Salary Prep Domain (6 tables)
| # | Table | Purpose | Key Constraint |
|---|---|---|---|
| 13 | `hrs_pay_grades` | Salary grade bands with CTC min/max; used to validate salary assignments | — |
| 14 | `hrs_salary_assignments` | Links employee to salary structure with CTC; new row per revision; cross-prefix FK to pay_salary_structures | — |
| 15 | `hrs_compliance_records` | Statutory compliance record per employee per type (PF, ESI, TDS, Gratuity, PT) | UNIQUE (employee_id, compliance_type) |
| 16 | `hrs_pf_contribution_register` | Monthly PF contribution amounts per employee; feeds EPFO ECR export | UNIQUE (compliance_record_id, month, year) |
| 17 | `hrs_esi_contribution_register` | Monthly ESI contribution amounts per employee; feeds ESI challan export | UNIQUE (compliance_record_id, month, year) |
| 18 | `hrs_pt_slabs` | State-wise Profession Tax slabs; seeded for HP, KA, MH | — |

### Appraisal Domain (5 tables)
| # | Table | Purpose | Key Constraint |
|---|---|---|---|
| 19 | `hrs_kpi_templates` | KPI template definitions; each template has weighted items | — |
| 20 | `hrs_kpi_template_items` | Individual KPI items within a template; weights must sum to 100 | — |
| 21 | `hrs_appraisal_cycles` | Appraisal cycle config per academic year (dates, type, KPI template, reviewer mode) | — |
| 22 | `hrs_appraisals` | Individual appraisal per employee per cycle; 4-state FSM | UNIQUE (cycle_id, employee_id) |
| 23 | `hrs_appraisal_increment_flags` | Bridge: finalized appraisal → IncrementService variable pay processing | — |

---

## pay_* Tables (10)

### Salary Structure Domain (3 tables)
| # | Table | Purpose | Key Constraint |
|---|---|---|---|
| 24 | `pay_salary_components` | Salary component master (14 standard: 7 earnings, 5 deductions, 2 employer contributions) | UNIQUE (code) |
| 25 | `pay_salary_structures` | Salary structure templates (3 defaults seeded: teaching, non-teaching, contractual) | — |
| 26 | `pay_salary_structure_components` | Junction: which components belong to which structure, with formula overrides | UNIQUE (structure_id, component_id) |

### Payroll Run Domain (3 tables)
| # | Table | Purpose | Key Constraint |
|---|---|---|---|
| 27 | `pay_payroll_runs` | Payroll run header; 6-state FSM (draft→locked); locked = immutable (BR-PAY-003) | UNIQUE (payroll_month, run_type) |
| 28 | `pay_payroll_run_details` | Per-employee per-run computed amounts; contains full computation_json for payslip | UNIQUE (payroll_run_id, employee_id) |
| 29 | `pay_payroll_overrides` | Mandatory audit trail for manual amendments to run details | — |

### Payslip Domain (1 table)
| # | Table | Purpose | Key Constraint |
|---|---|---|---|
| 30 | `pay_payslips` | Generated payslip PDF record per employee per run; password = PANlast4 + DDYYYY(DOB) | UNIQUE (run_detail_id) |

### TDS & Form 16 Domain (2 tables)
| # | Table | Purpose | Key Constraint |
|---|---|---|---|
| 31 | `pay_tds_ledger` | Monthly TDS cumulative ledger per employee per financial year | UNIQUE (employee_id, financial_year, month) |
| 32 | `pay_form16` | Generated Form 16 PDF (Part A + Part B) per employee per financial year | UNIQUE (employee_id, financial_year) |

### Increment Domain (1 table)
| # | Table | Purpose | Key Constraint |
|---|---|---|---|
| 33 | `pay_increment_policies` | Rating-to-increment mapping rules (supports % or flat INR) | — |

---

## Cross-Prefix FK Summary (within same module)
| FK Column | Table | References |
|---|---|---|
| `pay_salary_structure_id` | `hrs_salary_assignments` | `pay_salary_structures.id` |
| `salary_assignment_id` | `pay_payroll_run_details` | `hrs_salary_assignments.id` |
| `payroll_run_id` | `hrs_pf_contribution_register` | `pay_payroll_runs.id` (nullable) |
| `payroll_run_id` | `hrs_esi_contribution_register` | `pay_payroll_runs.id` (nullable) |
| `appraisal_cycle_id` | `pay_increment_policies` | `hrs_appraisal_cycles.id` (nullable) |

## Cross-Module FK Summary (HRS reads from existing tables)
| Referenced Table | Used By | Note |
|---|---|---|
| `sch_employees` | 17 hrs_*/pay_* tables | INT UNSIGNED id |
| `sch_org_academic_sessions_jnt` | 8 hrs_*/pay_* tables | SMALLINT UNSIGNED id |
| `sys_media` | hrs_employee_documents, hrs_leave_applications, pay_payslips, pay_form16 | BIGINT UNSIGNED id |
| `sch_department` | Readable via hrs_appraisal_cycles.applicable_departments (JSON array) | No direct FK column |

## Seeder Execution Order
```
1. HrsLeaveTypeSeeder         → 7 leave types
2. HrsLeavePolicySeeder       → 1 global default policy
3. HrsPtSlabSeeder            → 7 PT slabs (HP×2 + KA×2 + MH×3)
4. HrsIdCardTemplateSeeder    → 1 default ID card template
5. PaySalaryComponentSeeder   → 14 salary components
6. PaySalaryStructureSeeder   → 3 structures + junction records
```

## Quick Stats
| Metric | Value |
|---|---|
| Total new tables | 33 |
| hrs_* tables | 23 (15 core + 8 auxiliary) |
| pay_* tables | 10 |
| Tables with soft-delete | 33 (all) |
| Tables with is_active | 33 (all) |
| Cross-prefix FKs | 5 |
| Cross-module FKs | 23 (sch_employees refs across 17 tables) |
| Seeded tables | 6 (hrs_leave_types, hrs_leave_policies, hrs_pt_slabs, hrs_id_card_templates, pay_salary_components, pay_salary_structures+junction) |
