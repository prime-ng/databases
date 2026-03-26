# HrStaff Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** HRS | **Module Path:** `Modules/HrStaff`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `hrs_*`
**Processing Mode:** RBS-ONLY (Greenfield — No code, DDL, or tests exist)
**RBS Reference:** Module P — HR & Staff Management (lines 3431–3535)

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
9. [Authorization and RBAC](#9-authorization-and-rbac)
10. [Service Layer Architecture](#10-service-layer-architecture)
11. [Integration Points](#11-integration-points)
12. [Test Coverage](#12-test-coverage)
13. [Implementation Status](#13-implementation-status)
14. [Known Issues and Technical Debt](#14-known-issues-and-technical-debt)
15. [Development Priorities and Recommendations](#15-development-priorities-and-recommendations)

---

## 1. Module Overview

The HrStaff module is the human resources management system for Indian K-12 schools on the Prime-AI SaaS ERP platform. It manages the complete lifecycle of school employees — from onboarding and document management to leave administration, performance appraisal, training and development, statutory compliance (PF, ESI, TDS, gratuity), and employee exit processing. HrStaff is distinct from the Payroll module (`prl_*`): HrStaff manages employee master data, HR workflows, and compliance records; Payroll calculates and disburses salary.

### 1.1 Module Identity

| Property | Value |
|---|---|
| Module Name | HrStaff |
| Module Code | HRS |
| nwidart Module Namespace | `Modules\HrStaff` |
| Module Path | `Modules/HrStaff` |
| Route Prefix | `hr-staff/` |
| Route Name Prefix | `hr-staff.` |
| DB Table Prefix | `hrs_*` |
| Module Type | Tenant (per-school, database-per-tenant via stancl/tenancy v3.9) |
| Registered In | `routes/tenant.php` |

### 1.2 Module Scale (Proposed)

| Metric | Proposed Count |
|---|---|
| Controllers | 📐 12 |
| Models | 📐 18 |
| Services | 📐 8 |
| FormRequests | 📐 20 |
| Policies | 📐 12 |
| Browser Tests | 📐 14 |
| DDL Tables | 📐 14 |
| Views | 📐 ~80 Blade templates |

---

## 2. Business Context

### 2.1 Business Purpose

Indian schools employ a diverse workforce — teaching staff, administrative staff, support staff, and contract workers. HR processes in most schools are manual and paper-based, leading to the following operational problems:

1. **Onboarding Complexity**: Collecting appointment letters, educational certificates, ID proofs, PAN/Aadhaar, PF nomination forms, and issuing employee ID cards involves multiple departments and is highly error-prone without a system.
2. **Leave Administration**: Indian labour law recognises Casual Leave, Earned/Privilege Leave, Medical/Sick Leave, Maternity/Paternity Leave, and Compensatory-Off. Schools must track these against statutory minimums, maintain leave balances per academic year, and process multi-level approvals.
3. **Statutory Compliance**: Provident Fund (PF under EPF Act 1952), Employees' State Insurance (ESI under ESI Act 1948), Tax Deducted at Source (TDS under Income Tax Act), and gratuity (Payment of Gratuity Act 1972) require per-employee enrollment records, contribution registers, and periodic government returns.
4. **Performance Appraisal**: Schools require systematic annual/bi-annual KPI-based appraisals to govern increment and promotion decisions.
5. **Training and Development**: Professional development programs for teachers (training on new pedagogy, curriculum changes, technology tools) and non-teaching staff need to be tracked for attendance, outcomes, and certificate issuance.
6. **Employee Exit**: Resignation processing, full-and-final settlement triggers, clearance from departments, and issuance of experience certificates are unstructured without a dedicated workflow.

### 2.2 Primary Users

| Role | Primary Actions |
|---|---|
| HR Manager / Administrator | Full module access — all CRUD, approvals, reports |
| Principal | View all records, approve appraisals, approve exit clearance |
| HOD (Head of Department) | View department employees, approve leave, initiate appraisal |
| Employee (Self-Service) | Apply for leave, fill self-appraisal, update contact details, view payslips (via Payroll) |
| Accountant / Finance | View compliance records, access salary structure (links to Payroll) |

### 2.3 Indian School Context

- All monetary amounts in INR.
- PF applicability: Employee contribution 12% of basic salary; employer contribution 12% (3.67% to EPF, 8.33% to EPS). Applicable to employees drawing basic ≤ ₹15,000/month (mandatory), voluntary for others.
- ESI applicability: Employee 0.75% of gross; employer 3.25% of gross. Applicable to employees drawing gross ≤ ₹21,000/month.
- TDS: TDS on salary under Section 192 of Income Tax Act — Form 16 issued annually.
- Gratuity: 15 days' last drawn wage per year of service, payable after 5 years of continuous service.
- Leave types per Central Government / State Government rules (reference for aided schools); CBSE private schools follow own policies.
- Appointment letters, increment letters, transfer orders, warning letters are physical documents that must be scanned and attached.
- Academic year drives leave balance resets (typically April–March).

---

## 3. Scope and Boundaries

### 3.1 In-Scope Features

- Employee onboarding workflow (post-hiring): document collection checklist, ID card issuance, system access provisioning
- Employment master data extensions (HrStaff extends existing `sch_employees`, `sch_employees_profile`, `sch_teacher_profile` with HR-specific data)
- Leave type configuration and holiday calendar management
- Leave application and multi-level approval workflow
- Leave balance tracking per employee per academic year
- Attendance integration — link leave records to `att_staff_attendances` (Attendance module)
- Employee document repository (appointment letters, increment letters, educational certificates, ID proofs)
- Performance appraisal — KPI template management, appraisal cycle, self-appraisal, manager review, finalization
- Training program management — schedule, enrollment, attendance, feedback, certificate
- Statutory compliance records (PF, ESI, TDS, gratuity enrollment numbers and contribution register links)
- Employee exit management — resignation, termination, retirement; clearance workflow; experience certificate generation
- HR reports and analytics — headcount, department strength, attrition, leave utilization, compliance status
- Staff ID card generation (QR code based, using `emp_code`)

### 3.2 Out of Scope

- Salary calculation, payslip generation, and payroll processing — handled by Payroll module (`prl_*`)
- Recruitment and applicant tracking — separate Admission/HR Recruitment module (not yet planned)
- Biometric device hardware integration — Attendance module handles device sync; HrStaff reads from `att_staff_attendances`
- PF/ESI actual remittance processing and bank payment — Finance/Accounting module handles
- Tax computation and Form 16 generation — Payroll module responsibility
- Staff portal mobile app — planned but not in scope for this document
- Performance-linked variable pay computation — Payroll module, triggered by finalized appraisal

---

## 4. Functional Requirements

### 4.1 P1 — Staff Master & HR Records

#### 4.1.1 Employee Onboarding

**RBS Ref:** F.P1.1 — Staff Profile (Tasks T.P1.1.1, T.P1.1.2), F.P1.2 — Job & Employment Details (T.P1.2.1, T.P1.2.2)

**FR-HRS-001: Employee Onboarding Workflow**
📐 Status: Not Started

- HR Manager initiates onboarding for a new employee (who must already exist in `sch_employees` — created during Staff Profile module setup).
- Onboarding creates an `hrs_onboarding_checklists` record linked to `employee_id`.
- Checklist items are driven by a configurable template (`hrs_onboarding_checklist_items`), covering:
  - Personal document collection (Aadhaar, PAN, passport photo, address proof)
  - Educational certificate upload
  - Appointment letter signing and upload
  - PF nomination form (Form 2) collection
  - ESI enrollment (if applicable)
  - Bank account details for salary credit
  - System login credential generation
  - Employee ID card generation and handover
- Each checklist item has a status: `pending`, `submitted`, `verified`, `waived`
- HR Manager can mark items as verified or waived with remarks
- Onboarding is marked `complete` when all mandatory items are verified/waived
- Upon completion, system notifies (via `ntf_notifications`) the employee and principal
- Employee ID card printable PDF generated from `emp_code` (QR code) using DomPDF

**FR-HRS-002: Employment Details Management**
📐 Status: Not Started

- HR Manager can record/update employment-specific details in `hrs_employment_details`:
  - Contract type: `permanent`, `contractual`, `probation`, `part_time`, `substitute`
  - Probation period (months), probation end date
  - Confirmation date (when probation ends and employee is confirmed)
  - Notice period (days) — governs exit processing
  - Bank account details (account number, IFSC, bank name, branch — encrypted at application level)
  - Emergency contact details (name, relationship, phone, address)
  - Previous employer references (JSON)
- `reporting_to` is managed via `sch_employees_profile.reporting_to` (existing field)

#### 4.1.2 Document Management

**FR-HRS-003: Employee Document Repository**
📐 Status: Not Started

- HR Manager or employee can upload documents to `hrs_employee_documents`.
- Document types supported:
  - `appointment_letter` — issued at joining
  - `increment_letter` — annual increment order
  - `transfer_letter` — interdepartmental/school transfer
  - `warning_letter` — formal disciplinary notice
  - `experience_certificate` — issued on exit
  - `id_proof` — Aadhaar, PAN, passport
  - `educational_certificate` — degrees, diplomas
  - `medical_certificate` — for sick leave
  - `other` — catch-all
- Each document record stores: `employee_id`, `document_type`, `document_name`, `file_path` (linked to `sys_media`), `issued_date`, `expiry_date` (nullable — for ID proofs, certifications), `issued_by`, `remarks`
- Renewal reminders: if `expiry_date` is within 30 days, HR Manager is notified
- Documents are searchable/filterable by employee, type, and date range
- Download action returns file via secure storage (no direct public URL)

### 4.2 P2 — Staff Attendance & Leave

#### 4.2.1 Leave Configuration

**FR-HRS-004: Leave Type Master**
📐 Status: Not Started

- HR Manager configures school-specific leave types in `hrs_leave_types`:
  - Name (e.g., "Casual Leave", "Earned Leave", "Sick Leave", "Maternity Leave")
  - Code (unique shortcode, e.g., `CL`, `EL`, `SL`, `ML`)
  - Days per year (annual entitlement, e.g., 12 for CL)
  - Carry-forward days (max days that can be carried to next year; 0 = no carry-forward)
  - Applicable to: `all`, `teaching`, `non_teaching`
  - Is paid: `1` (paid leave) / `0` (loss of pay)
  - Requires medical certificate: `1` / `0` (triggered for sick leave beyond threshold)
  - Min consecutive days and max consecutive days (constraints)
  - Half-day allowed flag
  - Gender restriction: `all`, `female`, `male` (for maternity/paternity)
  - Minimum service months required (e.g., 6 months for earned leave eligibility)
- Pre-seeded leave types based on Indian labour norms (configurable by school):
  - Casual Leave (CL) — 12 days, not carry-forward, paid
  - Earned/Privilege Leave (EL) — 15 days, carry-forward 30 days, paid
  - Sick Leave (SL) — 12 days, no carry-forward, paid, requires medical cert > 3 days
  - Maternity Leave (ML) — 180 days, female only, paid
  - Paternity Leave (PL) — 15 days, male only, paid
  - Compensatory Off (CO) — variable, carry-forward 30 days, paid
  - Loss of Pay (LOP) — unlimited, not paid

**FR-HRS-005: Holiday Calendar Management**
📐 Status: Not Started

- HR Manager can define school-specific holiday calendar in `hrs_holiday_calendars`:
  - Calendar name, academic year link
  - Holiday date, holiday name
  - Holiday type: `national`, `state`, `regional`, `school`, `optional`
  - Applicable to: `all`, `teaching`, `non_teaching`
- Holidays auto-exclude from leave day count when calculating leave duration
- Pre-seeded national holidays (configurable): Republic Day, Independence Day, Gandhi Jayanti, Diwali, Holi, Eid, Christmas, etc.
- Optional holidays: employees can choose up to N optional holidays per year (configurable)

#### 4.2.2 Leave Balance Management

**FR-HRS-006: Leave Balance Initialization**
📐 Status: Not Started

- At the start of each academic year, HR Manager triggers `hrs_leave_balances` initialization for all active employees.
- Process:
  1. For each active employee, for each applicable leave type: create balance record with `allocated_days = leave_type.days_per_year`
  2. Add carry-forward balance from previous year: `carry_forward_days = MIN(prev_year_balance, leave_type.carry_forward_days)`
  3. Total available = `allocated_days + carry_forward_days`
- Manual adjustment: HR Manager can add or deduct days with a reason (logged in `hrs_leave_balance_adjustments`)
- Balance is consumed in real-time as leaves are approved

#### 4.2.3 Leave Application and Approval

**FR-HRS-007: Leave Application**
📐 Status: Not Started

- Employee submits leave application via self-service:
  - Select leave type (dropdown filtered by applicable_to, gender eligibility, service eligibility)
  - From date and to date (date range picker)
  - Half-day flag (if leave type supports it): first half / second half
  - Days count auto-calculated (excluding weekends and holidays from calendar)
  - Reason (text, required)
  - Supporting document attachment (required if leave_type.requires_medical_cert and days > threshold)
- System validates:
  - Sufficient leave balance available
  - No overlapping approved leave for same employee
  - Minimum service months satisfied
  - Date range not in the past beyond school's allowed backdated leave days (configurable)
- Application enters `pending` status

**FR-HRS-008: Leave Approval Workflow**
📐 Status: Not Started

- Approval flow is configurable: single-level (HOD only) or two-level (HOD → Principal)
- At each level, approver sees pending applications for their reportees
- Actions: `approve`, `reject`, `return_for_clarification`
- Approval must include remarks
- On final approval:
  - `hrs_leave_applications.status` → `approved`
  - `hrs_leave_balances.used_days` incremented by `days_count`
  - `hrs_leave_balances.balance_days` decremented
  - Notification dispatched to employee
- On rejection: `status` → `rejected`; notification dispatched; balance unchanged
- Employee can cancel an approved leave (if leave start date is in the future): balance restored; cancellation logged

**FR-HRS-009: Leave Balance Dashboard**
📐 Status: Not Started

- Employee self-service view: leave balance card per type for current academic year
- HR Manager view: bulk leave balance report (employee × leave type matrix)
- Filter by department, designation, employee name
- Export to CSV/PDF

#### 4.2.4 Attendance Integration

**FR-HRS-010: Attendance-Leave Reconciliation**
📐 Status: Not Started

- HrStaff reads from `att_staff_attendances` (Attendance module) — read-only integration, no writes.
- Absent days without approved leave → auto-flag for Loss of Pay
- HR Manager can run reconciliation report for a date range showing:
  - Employee name, date, attendance status, leave status, LOP flag
- LOP days are passed to Payroll module as deduction input (via `hrs_lop_records` table, consumed by `prl_*`)
- No automatic deduction — HR Manager confirms LOP before month close

### 4.3 P3 — Payroll Preparation (Salary Structure — HrStaff Scope)

**Note:** Payroll calculation, payslip generation, and disbursement are in the Payroll module (`prl_*`). HrStaff's scope is limited to maintaining the salary structure and CTC breakdown for each employee, which Payroll reads.

**FR-HRS-011: Salary Structure Assignment**
📐 Status: Not Started

- HR Manager assigns a salary structure to each employee via `hrs_salary_assignments`:
  - Link to `prl_salary_structures.id` (Payroll module's structure definition)
  - Effective from date / effective to date (for revision tracking)
  - CTC (Cost to Company) amount
  - Employee monthly gross
  - Pay grade (FK to `hrs_pay_grades`)
  - Revision reason (increment, promotion, correction)
- History of all salary revisions maintained — new row per revision, previous row gets `effective_to` set
- HR Manager cannot edit Payroll module tables directly; HrStaff stores the assignment mapping only

**FR-HRS-012: Pay Grade Master**
📐 Status: Not Started

- HR Manager configures `hrs_pay_grades`:
  - Grade name (e.g., "Grade 1", "PB-1", "Teacher Grade A")
  - Minimum CTC, maximum CTC
  - Applicable designations (JSON array of designation IDs)
- Pay grade governs salary range validations and PF/ESI applicability thresholds

### 4.4 P4 — Compliance & Statutory Management

**RBS Ref:** F.P4.1 — Statutory Records (Tasks T.P4.1.1, T.P4.1.2)

**FR-HRS-013: PF Enrollment and Records**
📐 Status: Not Started

- HR Manager records PF enrollment details in `hrs_compliance_records` (compliance_type = `pf`):
  - PF account number (UAN — Universal Account Number)
  - PF enrollment date
  - PF applicable flag (mandatory if basic ≤ ₹15,000; voluntary otherwise)
  - Nominee name, nominee relationship, nominee share (JSON — for Form 2)
  - PF exit date (if employee withdraws after exit)
- Monthly contribution tracking via `hrs_pf_contribution_register`:
  - Month/year, basic wage, employee contribution (12%), employer EPF contribution (3.67%), employer EPS contribution (8.33%), total
  - Status: `computed`, `submitted`, `challan_generated`
- PF monthly report export (Form 12A format) in PDF/CSV

**FR-HRS-014: ESI Enrollment and Records**
📐 Status: Not Started

- HR Manager records ESI enrollment in `hrs_compliance_records` (compliance_type = `esi`):
  - ESI IP number (Insurance Policy number)
  - ESI enrollment date
  - ESI applicable flag (if gross ≤ ₹21,000)
  - Dispensary details
- Monthly ESI contribution tracking via `hrs_esi_contribution_register`:
  - Month/year, gross wage, employee contribution (0.75%), employer contribution (3.25%)
  - Status: `computed`, `submitted`
- ESI half-yearly returns export (Form 5) in PDF/CSV

**FR-HRS-015: TDS Enrollment and Form 16**
📐 Status: Not Started

- HR Manager records TDS details in `hrs_compliance_records` (compliance_type = `tds`):
  - PAN number (encrypted)
  - Regime selected: `old` or `new` (post-2020 tax regime option)
  - Investment declarations for old regime: Section 80C, 80D, HRA, LTA (JSON)
- Form 16 generation is Payroll module responsibility; HrStaff stores declarations only
- Annual TDS record export for employee reference

**FR-HRS-016: Gratuity Records**
📐 Status: Not Started

- HR Manager records gratuity enrollment in `hrs_compliance_records` (compliance_type = `gratuity`):
  - Gratuity applicable flag (after 5 years of continuous service)
  - Gratuity nominee name and relationship
  - Projected gratuity amount (auto-calculated: `(last_basic × 15 × years_of_service) / 26`)
  - Date of gratuity eligibility
- On employee exit: gratuity amount computed and passed to Finance module for disbursement

### 4.5 P5 — Performance Appraisal

**RBS Ref:** F.P5.1 — Appraisal Setup (T.P5.1.1, T.P5.1.2), F.P5.2 — Appraisal Execution (T.P5.2.1, T.P5.2.2)

**FR-HRS-017: KPI Template Management**
📐 Status: Not Started

- HR Manager creates KPI templates in `hrs_kpi_templates`:
  - Template name (e.g., "Teaching Staff Annual Appraisal", "Admin Staff Mid-Year Review")
  - Applicable to: `teaching`, `non_teaching`, `all`
  - KPI items per template (stored in `hrs_kpi_template_items`):
    - KPI name (e.g., "Student Result Improvement", "Classroom Management", "Punctuality")
    - Category (e.g., `academic`, `behavioral`, `administrative`)
    - Weight (percentage, all weights in template must sum to 100)
    - Rating scale: 1–5 or 1–10 (configurable per template)
    - Description / measurement criteria

**FR-HRS-018: Appraisal Cycle Configuration**
📐 Status: Not Started

- HR Manager creates an appraisal cycle in `hrs_appraisal_cycles`:
  - Cycle name (e.g., "Annual Appraisal 2025-26")
  - Academic year link
  - Appraisal type: `annual`, `mid_year`, `probation`, `confirmation`
  - KPI template to use
  - Self-appraisal window: open date → close date
  - Manager review window: open date → close date
  - Applicable department(s) / designation(s) / employee type
  - Reviewers assignment: automatic (uses `reporting_to` hierarchy) or manual assignment

**FR-HRS-019: Self-Appraisal Submission**
📐 Status: Not Started

- During self-appraisal window, employee accesses their appraisal form via self-service:
  - For each KPI item in the template: enter self-rating (numeric, within scale), enter self-comments (text), optionally upload supporting evidence (file attachment via `sys_media`)
  - Overall self-comments section
  - Submit action → `hrs_appraisals.status` changes from `draft` to `submitted`
  - Once submitted, employee cannot edit (unless HR Manager reopens)

**FR-HRS-020: Manager Review and Final Rating**
📐 Status: Not Started

- During manager review window, reviewer (HOD or Principal) accesses submitted appraisals:
  - For each KPI item: enter reviewer rating (numeric, within scale), enter reviewer comments
  - Overall reviewer comments
  - Calculate overall rating: weighted average of reviewer KPI ratings
  - Reviewer submits review → `status` → `reviewed`
- HR Manager finalizes appraisal:
  - Can adjust overall rating within a configured tolerance band
  - Add management remarks
  - Mark status → `finalized`
- Finalized appraisals can trigger:
  - Notification to employee with rating
  - Flag for increment processing in Payroll module (via `hrs_appraisal_increment_flags`)

### 4.6 P6 — Staff Training & Development

**RBS Ref:** F.P6.1 — Training Programs (T.P6.1.1, T.P6.1.2), F.P6.2 — Training Evaluation (T.P6.2.1, T.P6.2.2)

**FR-HRS-021: Training Program Creation**
📐 Status: Not Started

- HR Manager creates training programs in `hrs_training_programs`:
  - Program name
  - Training type: `internal` (conducted at school), `external` (offsite/online)
  - Topic / objective
  - Trainer name and organization
  - Venue / URL (for online)
  - Start date, end date
  - Duration (hours)
  - Maximum participants
  - Applicable employee type: `teaching`, `non_teaching`, `all`
  - Mandatory flag (mandatory attendance vs voluntary enrollment)
  - Budget (INR)
  - Attachments: agenda, pre-reading materials

**FR-HRS-022: Training Enrollment**
📐 Status: Not Started

- HR Manager or employee can enroll staff in `hrs_training_enrollments`:
  - Enrollment validates: max_participants not exceeded; employee not already enrolled in same program
  - Enrollment status: `enrolled`, `attended`, `completed`, `absent`, `cancelled`
- Enrolled employees receive notification (via `ntf_notifications`) with program details and attachments

**FR-HRS-023: Training Attendance and Feedback**
📐 Status: Not Started

- After training, HR Manager marks attendance per enrollment (`attended` / `absent`)
- Enrolled employees can submit feedback:
  - Rating (1–5)
  - Feedback text
  - Suggestions
- Feedback stored in `hrs_training_enrollments.feedback_rating`, `feedback_text`
- HR Manager can generate:
  - Training evaluation report (average feedback ratings per program)
  - Attendance report (employee × program matrix)

**FR-HRS-024: Training Certificate Management**
📐 Status: Not Started

- For completed training programs, HR Manager can upload/generate training certificates:
  - Certificate uploaded as PDF (stored in `sys_media`, linked via `hrs_training_enrollments.certificate_media_id`)
  - Or certificate auto-generated via DomPDF from a configurable certificate template
  - Employee can download their own certificate from self-service
  - Certificate contributes to employee's training history (counted in HR reports)

### 4.7 P7 — Employee Exit Management

**FR-HRS-025: Resignation Initiation**
📐 Status: Not Started

- Employee or HR Manager initiates an exit record in `hrs_exit_records`:
  - Exit type: `resignation`, `termination`, `retirement`, `death`, `abandonment`
  - Exit initiation date
  - Employee-stated last working date
  - Notice period days (auto-populated from `hrs_employment_details.notice_period_days`)
  - Last working date (HR-confirmed, accounting for notice period, garden leave, notice buyout)
  - Exit reason / resignation letter upload

**FR-HRS-026: Exit Clearance Workflow**
📐 Status: Not Started

- Upon exit record creation, system auto-generates clearance checklist in `hrs_exit_clearances`:
  - Clearance items configured in `hrs_exit_clearance_templates`:
    - IT Department: Return laptop, revoke system access
    - Library: Clear all outstanding books
    - Finance: Settle pending dues/advances
    - Principal: Handover of responsibilities
    - HR: Return ID card and access card
  - Each clearance item assigned to a responsible department/person
  - Status per item: `pending`, `cleared`, `waived`
- Overall exit clearance status `cleared` only when all mandatory items are cleared/waived
- Full-and-final settlement trigger sent to Finance module when clearance is complete

**FR-HRS-027: Experience Certificate Generation**
📐 Status: Not Started

- HR Manager can generate experience certificate as DomPDF PDF:
  - School letterhead, principal signature line
  - Employee name, designation, department
  - Date of joining, last working date
  - Duration of service (auto-computed: years and months)
  - Nature of duties (text field)
  - Conduct remarks
- Certificate stored in `hrs_employee_documents` (document_type = `experience_certificate`)
- Employee and principal notified

### 4.8 P8 — HR Reports and Analytics

**RBS Ref:** F.P7.1 — Reports (T.P7.1.1, T.P7.1.2), F.P7.2 — Analytics (T.P7.2.1, T.P7.2.2)

**FR-HRS-028: HR Reports**
📐 Status: Not Started

- HR Manager can generate the following reports (all support PDF and CSV export via DomPDF and `fputcsv`):
  - **Staff Register**: Full list of active employees with designation, department, joining date, contact
  - **Department-Wise Strength**: Headcount by department; breakdown of teaching vs non-teaching
  - **New Joinings Report**: Employees joined in a date range
  - **Relieved Employees Report**: Exit records in a date range; includes exit type
  - **Leave Utilization Report**: Per employee, per leave type — allocated, used, balance; filterable by department
  - **Leave Pending Report**: All pending leave applications with aging
  - **PF Contribution Register**: Monthly PF contribution per employee
  - **ESI Contribution Register**: Monthly ESI contribution per employee
  - **Training Attendance Report**: Employee × program matrix for a period
  - **Appraisal Summary Report**: Ratings distribution per department per cycle

**FR-HRS-029: HR Analytics Dashboard**
📐 Status: Not Started

- Interactive dashboard with:
  - Total headcount (current active employees) — widget
  - New joinings this month / this year
  - Exits this month / this year
  - Attrition rate (rolling 12-month): `(exits / avg_headcount) × 100`
  - Leave trend chart: monthly leave days taken over last 12 months (per type)
  - Top leave takers (top 5 employees by leave days in current year)
  - Compliance status widget: PF enrolled %, ESI enrolled %, TDS PAN collected %
  - Upcoming document renewals (next 30 days)
  - Upcoming probation confirmations (next 60 days)

---

## 5. Non-Functional Requirements

### 5.1 Performance
- Leave balance check on application submission must complete within 500ms
- HR reports with up to 500 employees must generate within 5 seconds
- Bulk leave balance initialization for 500 employees must complete within 30 seconds (queued job)

### 5.2 Security
- PAN number and bank account details stored encrypted (Laravel encrypt/decrypt helpers)
- Employee documents accessible only to HR Manager, Principal, and the document owner
- Self-service actions (leave application, self-appraisal) restricted to the authenticated employee
- No cross-tenant data access (enforced by stancl/tenancy row isolation)

### 5.3 Reliability
- Leave approval/rejection actions must be atomic (database transaction) — balance update and status update as one unit
- Exit clearance checklist must be auto-generated at exit initiation (not deferred)

### 5.4 Compliance
- PF/ESI contribution data must be export-ready in government-prescribed formats
- All audit-sensitive changes (leave approval, appraisal finalization, exit clearance) logged to `sys_activity_logs`

### 5.5 Usability
- Multi-language support for labels via `glb_translations` (Hindi + English minimum)
- Leave calendar view showing employee absence overlaps by department

---

## 6. Database Schema

### 6.1 Existing Tables Used (SchoolSetup Module — Read/Join Only)

| Table | Usage |
|---|---|
| `sch_employees` | Primary employee reference — employee_id FK in all hrs_* tables |
| `sch_employees_profile` | Employment role, department, designation, reporting_to |
| `sch_teacher_profile` | Teacher-specific profile (teaching staff) |
| `sch_departments` | Department master |
| `sch_designations` | Designation master |
| `sys_users` | User account reference for all employees |
| `sys_media` | File/document storage |
| `sys_activity_logs` | Audit trail |

### 6.2 Proposed New Tables (`hrs_*`)

---

#### 📐 `hrs_employment_details`
Stores contract, banking, and emergency contact details for each employee.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `employee_id` | INT UNSIGNED | NOT NULL, FK→sch_employees | One-to-one with sch_employees |
| `contract_type` | ENUM('permanent','contractual','probation','part_time','substitute') | NOT NULL DEFAULT 'permanent' | Employment nature |
| `probation_months` | TINYINT UNSIGNED | DEFAULT NULL | Probation duration |
| `probation_end_date` | DATE | DEFAULT NULL | Auto-calculated or manual |
| `confirmation_date` | DATE | DEFAULT NULL | Post-probation confirmation |
| `notice_period_days` | SMALLINT UNSIGNED | DEFAULT 30 | Governs exit processing |
| `bank_account_number_encrypted` | VARCHAR(255) | DEFAULT NULL | Laravel encrypted |
| `bank_ifsc` | VARCHAR(20) | DEFAULT NULL | |
| `bank_name` | VARCHAR(100) | DEFAULT NULL | |
| `bank_branch` | VARCHAR(100) | DEFAULT NULL | |
| `emergency_contact_name` | VARCHAR(100) | DEFAULT NULL | |
| `emergency_contact_relation` | VARCHAR(50) | DEFAULT NULL | |
| `emergency_contact_phone` | VARCHAR(20) | DEFAULT NULL | |
| `previous_references_json` | JSON | DEFAULT NULL | Array of employer references |
| `is_active` | TINYINT(1) | DEFAULT 1 | Soft deactivation |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | Soft delete |

---

#### 📐 `hrs_pay_grades`
Salary grade master with CTC range.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `name` | VARCHAR(100) | NOT NULL | e.g., "Grade 1", "Teacher Grade A" |
| `code` | VARCHAR(20) | UNIQUE NOT NULL | |
| `min_ctc` | DECIMAL(12,2) | NOT NULL | |
| `max_ctc` | DECIMAL(12,2) | NOT NULL | |
| `applicable_designations_json` | JSON | DEFAULT NULL | Array of sch_designations.id |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `hrs_salary_assignments`
Maps employees to pay grades and salary structures (Payroll reads this).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `employee_id` | INT UNSIGNED | NOT NULL, FK→sch_employees | |
| `pay_grade_id` | BIGINT UNSIGNED | FK→hrs_pay_grades NULL | |
| `prl_salary_structure_id` | BIGINT UNSIGNED | DEFAULT NULL | FK to Payroll module (app-level, not DB FK) |
| `ctc_annual` | DECIMAL(12,2) | NOT NULL | Cost to Company annual |
| `gross_monthly` | DECIMAL(10,2) | NOT NULL | |
| `effective_from_date` | DATE | NOT NULL | |
| `effective_to_date` | DATE | DEFAULT NULL | NULL = current |
| `revision_reason` | ENUM('initial','increment','promotion','correction','restructure') | DEFAULT 'initial' | |
| `remarks` | TEXT | DEFAULT NULL | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `hrs_leave_types`
School-configurable leave type master.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `name` | VARCHAR(100) | NOT NULL | e.g., "Casual Leave" |
| `code` | VARCHAR(10) | UNIQUE NOT NULL | e.g., "CL" |
| `days_per_year` | DECIMAL(5,1) | NOT NULL | Annual entitlement |
| `carry_forward_days` | DECIMAL(5,1) | DEFAULT 0 | Max carry-forward |
| `applicable_to` | ENUM('all','teaching','non_teaching') | DEFAULT 'all' | |
| `gender_restriction` | ENUM('all','male','female') | DEFAULT 'all' | For maternity/paternity |
| `min_service_months` | SMALLINT UNSIGNED | DEFAULT 0 | Minimum months before eligibility |
| `is_paid` | TINYINT(1) | DEFAULT 1 | |
| `half_day_allowed` | TINYINT(1) | DEFAULT 0 | |
| `requires_medical_cert` | TINYINT(1) | DEFAULT 0 | |
| `medical_cert_after_days` | TINYINT UNSIGNED | DEFAULT 3 | Certificate required if > N days |
| `min_consecutive_days` | TINYINT UNSIGNED | DEFAULT 1 | |
| `max_consecutive_days` | TINYINT UNSIGNED | DEFAULT NULL | NULL = no limit |
| `display_order` | TINYINT UNSIGNED | DEFAULT 0 | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `hrs_holiday_calendars`
School holiday calendar per academic year.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `academic_session_id` | INT UNSIGNED | NOT NULL | FK→academic_sessions (app-level) |
| `holiday_date` | DATE | NOT NULL | |
| `holiday_name` | VARCHAR(150) | NOT NULL | |
| `holiday_type` | ENUM('national','state','regional','school','optional') | NOT NULL | |
| `applicable_to` | ENUM('all','teaching','non_teaching') | DEFAULT 'all' | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

UNIQUE KEY `uq_holiday_session_date` (`academic_session_id`, `holiday_date`)

---

#### 📐 `hrs_leave_balances`
Per-employee, per-leave-type balance for each academic year.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `employee_id` | INT UNSIGNED | NOT NULL, FK→sch_employees | |
| `leave_type_id` | BIGINT UNSIGNED | NOT NULL, FK→hrs_leave_types | |
| `academic_session_id` | INT UNSIGNED | NOT NULL | FK→academic_sessions |
| `allocated_days` | DECIMAL(5,1) | NOT NULL DEFAULT 0 | From leave type |
| `carry_forward_days` | DECIMAL(5,1) | DEFAULT 0 | From previous year |
| `additional_days` | DECIMAL(5,1) | DEFAULT 0 | Manual adjustments |
| `used_days` | DECIMAL(5,1) | DEFAULT 0 | Consumed by approved leaves |
| `balance_days` | DECIMAL(5,1) | GENERATED ALWAYS AS (allocated_days + carry_forward_days + additional_days - used_days) STORED | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

UNIQUE KEY `uq_leave_balance` (`employee_id`, `leave_type_id`, `academic_session_id`)

---

#### 📐 `hrs_leave_applications`
Individual leave requests with approval chain.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `employee_id` | INT UNSIGNED | NOT NULL, FK→sch_employees | |
| `leave_type_id` | BIGINT UNSIGNED | NOT NULL, FK→hrs_leave_types | |
| `academic_session_id` | INT UNSIGNED | NOT NULL | |
| `from_date` | DATE | NOT NULL | |
| `to_date` | DATE | NOT NULL | |
| `half_day` | ENUM('none','first_half','second_half') | DEFAULT 'none' | |
| `days_count` | DECIMAL(4,1) | NOT NULL | Calculated excluding holidays |
| `reason` | TEXT | NOT NULL | |
| `document_media_id` | BIGINT UNSIGNED | FK→sys_media NULL | Medical cert or other doc |
| `status` | ENUM('pending','approved','rejected','cancelled','returned') | DEFAULT 'pending' | |
| `level1_approved_by` | BIGINT UNSIGNED | FK→sys_users NULL | HOD approval |
| `level1_approved_at` | TIMESTAMP | DEFAULT NULL | |
| `level1_remarks` | TEXT | DEFAULT NULL | |
| `level2_approved_by` | BIGINT UNSIGNED | FK→sys_users NULL | Principal approval |
| `level2_approved_at` | TIMESTAMP | DEFAULT NULL | |
| `level2_remarks` | TEXT | DEFAULT NULL | |
| `cancelled_at` | TIMESTAMP | DEFAULT NULL | |
| `cancellation_reason` | TEXT | DEFAULT NULL | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `hrs_compliance_records`
PF, ESI, TDS, Gratuity enrollment data per employee.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `employee_id` | INT UNSIGNED | NOT NULL, FK→sch_employees | |
| `compliance_type` | ENUM('pf','esi','tds','gratuity') | NOT NULL | |
| `enrollment_number` | VARCHAR(100) | DEFAULT NULL | UAN for PF, IP for ESI, PAN for TDS |
| `enrollment_date` | DATE | DEFAULT NULL | |
| `is_applicable` | TINYINT(1) | DEFAULT 1 | |
| `details_json` | JSON | DEFAULT NULL | Type-specific data (nominees, declarations) |
| `exit_date` | DATE | DEFAULT NULL | For PF/ESI deactivation on exit |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

UNIQUE KEY `uq_compliance_employee_type` (`employee_id`, `compliance_type`)

---

#### 📐 `hrs_kpi_templates`
Appraisal KPI template definitions.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `name` | VARCHAR(150) | NOT NULL | |
| `applicable_to` | ENUM('all','teaching','non_teaching') | DEFAULT 'all' | |
| `rating_scale` | TINYINT UNSIGNED | DEFAULT 5 | 5 or 10 |
| `description` | TEXT | DEFAULT NULL | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `hrs_kpi_template_items`
Individual KPI items within a template.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `kpi_template_id` | BIGINT UNSIGNED | NOT NULL, FK→hrs_kpi_templates | |
| `kpi_name` | VARCHAR(200) | NOT NULL | |
| `category` | VARCHAR(100) | DEFAULT NULL | e.g., academic, behavioral |
| `weight` | DECIMAL(5,2) | NOT NULL | Percentage; all items in template must sum to 100 |
| `measurement_criteria` | TEXT | DEFAULT NULL | |
| `display_order` | TINYINT UNSIGNED | DEFAULT 0 | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `hrs_appraisal_cycles`
Appraisal cycle configuration per academic year.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `name` | VARCHAR(150) | NOT NULL | |
| `academic_session_id` | INT UNSIGNED | NOT NULL | |
| `appraisal_type` | ENUM('annual','mid_year','probation','confirmation') | DEFAULT 'annual' | |
| `kpi_template_id` | BIGINT UNSIGNED | NOT NULL, FK→hrs_kpi_templates | |
| `self_appraisal_open_date` | DATE | NOT NULL | |
| `self_appraisal_close_date` | DATE | NOT NULL | |
| `manager_review_open_date` | DATE | NOT NULL | |
| `manager_review_close_date` | DATE | NOT NULL | |
| `applicable_to` | ENUM('all','teaching','non_teaching') | DEFAULT 'all' | |
| `applicable_departments_json` | JSON | DEFAULT NULL | NULL = all |
| `status` | ENUM('draft','active','closed') | DEFAULT 'draft' | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `hrs_appraisals`
Individual appraisal records per employee per cycle.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `employee_id` | INT UNSIGNED | NOT NULL, FK→sch_employees | |
| `cycle_id` | BIGINT UNSIGNED | NOT NULL, FK→hrs_appraisal_cycles | |
| `reviewer_id` | BIGINT UNSIGNED | FK→sys_users NULL | Assigned reviewer |
| `overall_self_rating` | DECIMAL(4,2) | DEFAULT NULL | Computed weighted average of self ratings |
| `overall_reviewer_rating` | DECIMAL(4,2) | DEFAULT NULL | Computed weighted average of reviewer ratings |
| `final_rating` | DECIMAL(4,2) | DEFAULT NULL | HR finalized rating |
| `self_comments` | TEXT | DEFAULT NULL | |
| `reviewer_comments` | TEXT | DEFAULT NULL | |
| `management_remarks` | TEXT | DEFAULT NULL | |
| `status` | ENUM('draft','submitted','reviewed','finalized') | DEFAULT 'draft' | |
| `self_submitted_at` | TIMESTAMP | DEFAULT NULL | |
| `reviewed_at` | TIMESTAMP | DEFAULT NULL | |
| `finalized_at` | TIMESTAMP | DEFAULT NULL | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

UNIQUE KEY `uq_appraisal_employee_cycle` (`employee_id`, `cycle_id`)

---

#### 📐 `hrs_appraisal_kpi_scores`
Per-KPI scores for each appraisal.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `appraisal_id` | BIGINT UNSIGNED | NOT NULL, FK→hrs_appraisals | |
| `kpi_item_id` | BIGINT UNSIGNED | NOT NULL, FK→hrs_kpi_template_items | |
| `self_rating` | DECIMAL(4,2) | DEFAULT NULL | |
| `self_comment` | TEXT | DEFAULT NULL | |
| `evidence_media_id` | BIGINT UNSIGNED | FK→sys_media NULL | |
| `reviewer_rating` | DECIMAL(4,2) | DEFAULT NULL | |
| `reviewer_comment` | TEXT | DEFAULT NULL | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `hrs_training_programs`
Training program master.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `name` | VARCHAR(200) | NOT NULL | |
| `training_type` | ENUM('internal','external','online') | DEFAULT 'internal' | |
| `topic` | VARCHAR(300) | NOT NULL | |
| `trainer_name` | VARCHAR(150) | DEFAULT NULL | |
| `trainer_organization` | VARCHAR(150) | DEFAULT NULL | |
| `venue` | VARCHAR(200) | DEFAULT NULL | Physical venue or URL |
| `start_date` | DATE | NOT NULL | |
| `end_date` | DATE | NOT NULL | |
| `duration_hours` | DECIMAL(5,2) | DEFAULT NULL | |
| `max_participants` | SMALLINT UNSIGNED | DEFAULT NULL | NULL = unlimited |
| `applicable_to` | ENUM('all','teaching','non_teaching') | DEFAULT 'all' | |
| `is_mandatory` | TINYINT(1) | DEFAULT 0 | |
| `budget_inr` | DECIMAL(12,2) | DEFAULT NULL | |
| `attachment_media_id` | BIGINT UNSIGNED | FK→sys_media NULL | Agenda/pre-read |
| `status` | ENUM('upcoming','ongoing','completed','cancelled') | DEFAULT 'upcoming' | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `hrs_training_enrollments`
Employee enrollment and outcome per training program.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `program_id` | BIGINT UNSIGNED | NOT NULL, FK→hrs_training_programs | |
| `employee_id` | INT UNSIGNED | NOT NULL, FK→sch_employees | |
| `enrolled_by` | BIGINT UNSIGNED | FK→sys_users NULL | HR Manager or self |
| `enrolled_at` | TIMESTAMP | DEFAULT NULL | |
| `status` | ENUM('enrolled','attended','completed','absent','cancelled') | DEFAULT 'enrolled' | |
| `feedback_rating` | TINYINT UNSIGNED | DEFAULT NULL | 1–5 |
| `feedback_text` | TEXT | DEFAULT NULL | |
| `suggestions` | TEXT | DEFAULT NULL | |
| `certificate_media_id` | BIGINT UNSIGNED | FK→sys_media NULL | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

UNIQUE KEY `uq_training_enrollment` (`program_id`, `employee_id`)

---

#### 📐 `hrs_employee_documents`
Document repository for all employee-related files.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `employee_id` | INT UNSIGNED | NOT NULL, FK→sch_employees | |
| `document_type` | ENUM('appointment_letter','increment_letter','transfer_letter','warning_letter','experience_certificate','id_proof','educational_certificate','medical_certificate','other') | NOT NULL | |
| `document_name` | VARCHAR(200) | NOT NULL | Display name |
| `media_id` | BIGINT UNSIGNED | FK→sys_media NOT NULL | File reference |
| `issued_date` | DATE | DEFAULT NULL | |
| `expiry_date` | DATE | DEFAULT NULL | For ID proofs |
| `issued_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `remarks` | TEXT | DEFAULT NULL | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `hrs_exit_records`
Employee exit record with clearance tracking.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `employee_id` | INT UNSIGNED | NOT NULL, FK→sch_employees | UNIQUE (one exit record) |
| `exit_type` | ENUM('resignation','termination','retirement','death','abandonment') | NOT NULL | |
| `initiation_date` | DATE | NOT NULL | Date resignation/termination notified |
| `employee_stated_date` | DATE | DEFAULT NULL | Date employee requested as LWD |
| `notice_period_days` | SMALLINT UNSIGNED | DEFAULT NULL | From employment details |
| `last_working_date` | DATE | DEFAULT NULL | HR-confirmed LWD |
| `resignation_letter_media_id` | BIGINT UNSIGNED | FK→sys_media NULL | |
| `exit_reason` | TEXT | DEFAULT NULL | |
| `clearance_status` | ENUM('pending','in_progress','cleared') | DEFAULT 'pending' | |
| `clearance_completed_at` | TIMESTAMP | DEFAULT NULL | |
| `fnf_triggered` | TINYINT(1) | DEFAULT 0 | Full-and-final trigger to Finance |
| `remarks` | TEXT | DEFAULT NULL | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `hrs_onboarding_checklists`
Per-employee onboarding checklist tracking.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `employee_id` | INT UNSIGNED | NOT NULL, FK→sch_employees | UNIQUE |
| `status` | ENUM('pending','in_progress','complete') | DEFAULT 'pending' | |
| `completed_at` | TIMESTAMP | DEFAULT NULL | |
| `notes` | TEXT | DEFAULT NULL | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `hrs_onboarding_checklist_items`
Individual items within an employee's onboarding checklist.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `checklist_id` | BIGINT UNSIGNED | NOT NULL, FK→hrs_onboarding_checklists | |
| `item_name` | VARCHAR(200) | NOT NULL | e.g., "Aadhaar Card Copy" |
| `item_type` | ENUM('document','action','access') | NOT NULL | |
| `is_mandatory` | TINYINT(1) | DEFAULT 1 | |
| `status` | ENUM('pending','submitted','verified','waived') | DEFAULT 'pending' | |
| `media_id` | BIGINT UNSIGNED | FK→sys_media NULL | Uploaded document |
| `verified_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `verified_at` | TIMESTAMP | DEFAULT NULL | |
| `remarks` | TEXT | DEFAULT NULL | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

## 7. API and Routes

### 7.1 Web Routes (Tenant — `routes/tenant.php`)

All routes prefixed with `hr-staff/`, named `hr-staff.*`, middleware `['auth', 'verified', 'tenant']`.

#### Employment Management
```
GET    hr-staff/employment                          hr-staff.employment.index
GET    hr-staff/employment/{employee}/details       hr-staff.employment.details
POST   hr-staff/employment/{employee}/details       hr-staff.employment.details.store
PUT    hr-staff/employment/{employee}/details       hr-staff.employment.details.update
GET    hr-staff/employment/{employee}/salary        hr-staff.employment.salary.index
POST   hr-staff/employment/{employee}/salary        hr-staff.employment.salary.store
GET    hr-staff/employment/pay-grades               hr-staff.pay-grades.index
POST   hr-staff/employment/pay-grades               hr-staff.pay-grades.store
PUT    hr-staff/employment/pay-grades/{id}          hr-staff.pay-grades.update
DELETE hr-staff/employment/pay-grades/{id}          hr-staff.pay-grades.destroy
```

#### Leave Management
```
GET    hr-staff/leave-types                         hr-staff.leave-types.index
POST   hr-staff/leave-types                         hr-staff.leave-types.store
PUT    hr-staff/leave-types/{id}                    hr-staff.leave-types.update
DELETE hr-staff/leave-types/{id}                    hr-staff.leave-types.destroy
GET    hr-staff/holiday-calendar                    hr-staff.holiday-calendar.index
POST   hr-staff/holiday-calendar                    hr-staff.holiday-calendar.store
DELETE hr-staff/holiday-calendar/{id}               hr-staff.holiday-calendar.destroy
POST   hr-staff/leave-balances/initialize           hr-staff.leave-balances.initialize
GET    hr-staff/leave-balances                      hr-staff.leave-balances.index
GET    hr-staff/leave-applications                  hr-staff.leave-applications.index
POST   hr-staff/leave-applications                  hr-staff.leave-applications.store
GET    hr-staff/leave-applications/{id}             hr-staff.leave-applications.show
POST   hr-staff/leave-applications/{id}/approve     hr-staff.leave-applications.approve
POST   hr-staff/leave-applications/{id}/reject      hr-staff.leave-applications.reject
POST   hr-staff/leave-applications/{id}/cancel      hr-staff.leave-applications.cancel
```

#### Compliance
```
GET    hr-staff/compliance/{employee}               hr-staff.compliance.index
POST   hr-staff/compliance/{employee}/pf            hr-staff.compliance.pf.store
PUT    hr-staff/compliance/{employee}/pf/{id}       hr-staff.compliance.pf.update
POST   hr-staff/compliance/{employee}/esi           hr-staff.compliance.esi.store
POST   hr-staff/compliance/{employee}/tds           hr-staff.compliance.tds.store
GET    hr-staff/compliance/reports/pf               hr-staff.compliance.reports.pf
GET    hr-staff/compliance/reports/esi              hr-staff.compliance.reports.esi
```

#### Appraisal
```
GET    hr-staff/appraisal/kpi-templates             hr-staff.kpi-templates.index
POST   hr-staff/appraisal/kpi-templates             hr-staff.kpi-templates.store
GET    hr-staff/appraisal/cycles                    hr-staff.cycles.index
POST   hr-staff/appraisal/cycles                    hr-staff.cycles.store
GET    hr-staff/appraisal/cycles/{cycle}/appraisals hr-staff.appraisals.index
POST   hr-staff/appraisal/{id}/self-submit          hr-staff.appraisals.self-submit
POST   hr-staff/appraisal/{id}/review               hr-staff.appraisals.review
POST   hr-staff/appraisal/{id}/finalize             hr-staff.appraisals.finalize
```

#### Training
```
GET    hr-staff/training/programs                   hr-staff.training.programs.index
POST   hr-staff/training/programs                   hr-staff.training.programs.store
PUT    hr-staff/training/programs/{id}              hr-staff.training.programs.update
GET    hr-staff/training/programs/{id}/enroll       hr-staff.training.enrollments.index
POST   hr-staff/training/programs/{id}/enroll       hr-staff.training.enrollments.store
POST   hr-staff/training/enrollments/{id}/mark-attendance hr-staff.training.enrollments.attendance
POST   hr-staff/training/enrollments/{id}/feedback  hr-staff.training.enrollments.feedback
```

#### Exit Management
```
GET    hr-staff/exit                                hr-staff.exit.index
POST   hr-staff/exit/{employee}/initiate            hr-staff.exit.initiate
GET    hr-staff/exit/{employee}/clearance           hr-staff.exit.clearance.show
POST   hr-staff/exit/{employee}/clearance/{item}    hr-staff.exit.clearance.update
POST   hr-staff/exit/{employee}/experience-certificate hr-staff.exit.experience-cert
```

#### Documents & Reports
```
GET    hr-staff/documents/{employee}                hr-staff.documents.index
POST   hr-staff/documents/{employee}                hr-staff.documents.store
GET    hr-staff/documents/{employee}/{id}/download  hr-staff.documents.download
GET    hr-staff/reports/dashboard                   hr-staff.reports.dashboard
GET    hr-staff/reports/staff-register              hr-staff.reports.staff-register
GET    hr-staff/reports/department-strength         hr-staff.reports.department-strength
GET    hr-staff/reports/leave-utilization           hr-staff.reports.leave-utilization
GET    hr-staff/reports/attrition                   hr-staff.reports.attrition
```

---

## 8. Business Rules

| Rule ID | Description |
|---|---|
| BR-HRS-001 | Leave balance must be >= days_count before an application can be submitted (except LOP). |
| BR-HRS-002 | Overlapping approved leaves for the same employee on the same dates are not permitted. |
| BR-HRS-003 | Leave cancellation is only permitted before the leave start date. |
| BR-HRS-004 | PF applicability is mandatory if `basic_salary <= 15000` INR/month; voluntary above threshold. |
| BR-HRS-005 | ESI applicability is mandatory if `gross_salary <= 21000` INR/month. |
| BR-HRS-006 | Gratuity is payable only after 5 years of continuous service. |
| BR-HRS-007 | KPI weights within a template must sum to exactly 100%. |
| BR-HRS-008 | Employee cannot submit self-appraisal outside the self-appraisal window dates. |
| BR-HRS-009 | Manager cannot submit review outside the manager review window dates. |
| BR-HRS-010 | Training enrollment must not exceed max_participants for the program. |
| BR-HRS-011 | Exit clearance status can only transition to 'cleared' when all mandatory clearance items are cleared or waived. |
| BR-HRS-012 | Experience certificate can only be generated after last_working_date is confirmed. |
| BR-HRS-013 | Salary assignment effective_to of previous record is auto-set to new record's effective_from - 1 day on revision. |
| BR-HRS-014 | Leave balance initialization overwrites existing balances only if force_reinitialize flag is set by HR Manager. |
| BR-HRS-015 | Medical certificate upload is mandatory for sick leave applications exceeding medical_cert_after_days threshold. |

---

## 9. Authorization and RBAC

### 9.1 Proposed Permissions

| Permission | HR Manager | Principal | HOD | Employee (Self) |
|---|---|---|---|---|
| `hrs.employee.view` | Yes | Yes | Dept only | Own only |
| `hrs.employment.manage` | Yes | No | No | No |
| `hrs.leave_type.manage` | Yes | No | No | No |
| `hrs.leave.apply` | Yes | Yes | Yes | Yes |
| `hrs.leave.approve_level1` | Yes | No | Yes | No |
| `hrs.leave.approve_level2` | Yes | Yes | No | No |
| `hrs.compliance.manage` | Yes | No | No | No |
| `hrs.appraisal.manage_cycle` | Yes | No | No | No |
| `hrs.appraisal.self_submit` | No | No | No | Yes |
| `hrs.appraisal.review` | Yes | Yes | Yes | No |
| `hrs.appraisal.finalize` | Yes | Yes | No | No |
| `hrs.training.manage` | Yes | No | No | No |
| `hrs.training.feedback` | No | No | No | Yes |
| `hrs.exit.manage` | Yes | Yes | No | No |
| `hrs.reports.view` | Yes | Yes | Dept only | No |

---

## 10. Service Layer Architecture

| Service | Responsibility |
|---|---|
| 📐 `OnboardingService` | Create checklist from template, mark items, notify on completion |
| 📐 `LeaveService` | Apply leave, calculate days (excluding holidays), approve/reject, cancel, balance update |
| 📐 `LeaveBalanceService` | Initialize balances for year, carry-forward, manual adjustments |
| 📐 `ComplianceService` | PF/ESI/TDS record management, contribution register computation, report export |
| 📐 `AppraisalService` | Cycle management, appraisal generation, self-submit, review, finalize, weighted average calculation |
| 📐 `TrainingService` | Program CRUD, enrollment management, attendance marking, feedback, certificate generation |
| 📐 `ExitService` | Exit initiation, clearance checklist generation, clearance item updates, FnF trigger, experience certificate |
| 📐 `HrReportService` | All HR reports (staff register, leave utilization, attrition, compliance status) — CSV and PDF |

---

## 11. Integration Points

| Module | Integration Type | Description |
|---|---|---|
| SchoolSetup | Read-only FK | `sch_employees`, `sch_departments`, `sch_designations` as master references |
| Attendance | Read-only | Read `att_staff_attendances` for LOP reconciliation |
| Payroll (`prl_*`) | Read-write | HrStaff writes `hrs_salary_assignments`; Payroll reads it. On appraisal finalize, writes `hrs_appraisal_increment_flags`; Payroll acts on it. |
| Finance/Accounting | Event | Exit clearance fires event for FnF settlement; compliance contributions fire event for remittance |
| Notification (`ntf_*`) | Outbound | Dispatch notifications for leave decisions, onboarding completion, training enrollment, appraisal status, document renewal reminders |
| System Media (`sys_media`) | Read-write | All document uploads, training certificates, resignation letters stored via sys_media |
| Auth (`sys_users`) | Read-only | Employee login identity, created_by/approved_by references |

---

## 12. Test Coverage

### 12.1 Proposed Test Cases

| Test | Type | Description |
|---|---|---|
| 📐 `LeaveApplicationTest` | Feature | Apply leave, check balance deduction on approval, restore on cancellation |
| 📐 `LeaveOverlapTest` | Feature | Reject application when overlapping approved leave exists |
| 📐 `LeaveBalanceInitializationTest` | Feature | Initialize balances for all employees, verify carry-forward computation |
| 📐 `AppraisalWeightSumTest` | Unit | KPI weights in template must sum to 100 |
| 📐 `AppraisalSelfSubmitWindowTest` | Feature | Reject self-submit outside appraisal window |
| 📐 `TrainingEnrollmentCapacityTest` | Feature | Reject enrollment when max_participants reached |
| 📐 `CompliancePfApplicabilityTest` | Unit | PF mandatory flag logic based on basic salary threshold |
| 📐 `ExitClearanceCompletionTest` | Feature | Exit clearance status only clears when all mandatory items are cleared/waived |
| 📐 `SalaryRevisionHistoryTest` | Feature | Previous salary assignment effective_to auto-set on new revision |
| 📐 `ExperienceCertificateGenerationTest` | Feature | PDF generated correctly, stored in employee documents |

---

## 13. Implementation Status

### 13.1 Feature Status Summary

| FR Code | Feature | Status |
|---|---|---|
| FR-HRS-001 | Employee Onboarding Workflow | ❌ Not Started |
| FR-HRS-002 | Employment Details Management | ❌ Not Started |
| FR-HRS-003 | Employee Document Repository | ❌ Not Started |
| FR-HRS-004 | Leave Type Master | ❌ Not Started |
| FR-HRS-005 | Holiday Calendar Management | ❌ Not Started |
| FR-HRS-006 | Leave Balance Initialization | ❌ Not Started |
| FR-HRS-007 | Leave Application | ❌ Not Started |
| FR-HRS-008 | Leave Approval Workflow | ❌ Not Started |
| FR-HRS-009 | Leave Balance Dashboard | ❌ Not Started |
| FR-HRS-010 | Attendance-Leave Reconciliation | ❌ Not Started |
| FR-HRS-011 | Salary Structure Assignment | ❌ Not Started |
| FR-HRS-012 | Pay Grade Master | ❌ Not Started |
| FR-HRS-013 | PF Enrollment and Records | ❌ Not Started |
| FR-HRS-014 | ESI Enrollment and Records | ❌ Not Started |
| FR-HRS-015 | TDS Enrollment and Form 16 | ❌ Not Started |
| FR-HRS-016 | Gratuity Records | ❌ Not Started |
| FR-HRS-017 | KPI Template Management | ❌ Not Started |
| FR-HRS-018 | Appraisal Cycle Configuration | ❌ Not Started |
| FR-HRS-019 | Self-Appraisal Submission | ❌ Not Started |
| FR-HRS-020 | Manager Review and Final Rating | ❌ Not Started |
| FR-HRS-021 | Training Program Creation | ❌ Not Started |
| FR-HRS-022 | Training Enrollment | ❌ Not Started |
| FR-HRS-023 | Training Attendance and Feedback | ❌ Not Started |
| FR-HRS-024 | Training Certificate Management | ❌ Not Started |
| FR-HRS-025 | Resignation Initiation | ❌ Not Started |
| FR-HRS-026 | Exit Clearance Workflow | ❌ Not Started |
| FR-HRS-027 | Experience Certificate Generation | ❌ Not Started |
| FR-HRS-028 | HR Reports | ❌ Not Started |
| FR-HRS-029 | HR Analytics Dashboard | ❌ Not Started |

### 13.2 Code Artifacts — All Proposed (None Exist)

| Artifact | Path (Proposed) |
|---|---|
| 📐 Module root | `Modules/HrStaff/` |
| 📐 OnboardingController | `Modules/HrStaff/Http/Controllers/OnboardingController.php` |
| 📐 LeaveController | `Modules/HrStaff/Http/Controllers/LeaveController.php` |
| 📐 LeaveBalanceController | `Modules/HrStaff/Http/Controllers/LeaveBalanceController.php` |
| 📐 ComplianceController | `Modules/HrStaff/Http/Controllers/ComplianceController.php` |
| 📐 AppraisalController | `Modules/HrStaff/Http/Controllers/AppraisalController.php` |
| 📐 TrainingController | `Modules/HrStaff/Http/Controllers/TrainingController.php` |
| 📐 ExitController | `Modules/HrStaff/Http/Controllers/ExitController.php` |
| 📐 EmploymentController | `Modules/HrStaff/Http/Controllers/EmploymentController.php` |
| 📐 HrDocumentController | `Modules/HrStaff/Http/Controllers/HrDocumentController.php` |
| 📐 HrReportController | `Modules/HrStaff/Http/Controllers/HrReportController.php` |
| 📐 HrDashboardController | `Modules/HrStaff/Http/Controllers/HrDashboardController.php` |
| 📐 All Service classes | `Modules/HrStaff/Services/` |
| 📐 All Models | `Modules/HrStaff/Models/` |
| 📐 DDL | `1-DDL_Tenant_Modules/XX-HrStaff/DDL/` |

---

## 14. Known Issues and Technical Debt

1. **PF/ESI Threshold Changes**: Government revises PF/ESI wage ceilings periodically. The system must support threshold configuration (stored in tenant settings, not hardcoded) so that schools can update without a code deployment.
2. **Leave Day Calculation Complexity**: Leave duration must exclude weekends (school-specific working days from `sch_school_days`) and holidays (from `hrs_holiday_calendars`). The `LeaveService::calculateLeaveDays()` method must join both sources — complexity to be addressed during implementation.
3. **Payroll Module DB FK Gap**: `hrs_salary_assignments.prl_salary_structure_id` references the Payroll module table, which is in the same tenant database. A formal FK constraint is recommended once Payroll DDL is finalized; for now managed at application level.
4. **Biometric Sync**: HrStaff reads from `att_staff_attendances` but the Attendance module's biometric sync schedule and device compatibility is outside HrStaff scope. Attendance module must be implemented before Attendance-Leave reconciliation can be tested.
5. **Multi-Level Approval Configurability**: The current design supports up to 2-level approval. Schools with complex hierarchies (HOD → VP → Principal) would require additional levels — this should be addressed in v2 using a polymorphic approval chain pattern.

---

## 15. Development Priorities and Recommendations

### 15.1 Phase 1 — Foundation (Recommended First Sprint)
1. **Employment Details** (FR-HRS-002) — Extends existing sch_employees with contract, banking, emergency contact data. Low risk, high value.
2. **Leave Type Master and Holiday Calendar** (FR-HRS-004, FR-HRS-005) — Prerequisites for all leave workflows.
3. **Leave Balance Initialization** (FR-HRS-006) — Must run before any leave applications in an academic year.
4. **Leave Application and Approval** (FR-HRS-007, FR-HRS-008) — Core daily HR workflow; highest user-facing priority.

### 15.2 Phase 2 — Compliance and Documents
5. **Employee Document Repository** (FR-HRS-003) — Immediate value for onboarding and document management.
6. **PF/ESI/TDS/Gratuity Records** (FR-HRS-013 to FR-HRS-016) — Required for compliance reporting; needed for Payroll integration.
7. **Onboarding Workflow** (FR-HRS-001) — Structured onboarding; depends on document repository.

### 15.3 Phase 3 — Performance and Training
8. **KPI Templates and Appraisal Cycles** (FR-HRS-017, FR-HRS-018) — Configuration before any appraisals.
9. **Appraisal Self-Submit and Review** (FR-HRS-019, FR-HRS-020) — Core appraisal workflow.
10. **Training Programs, Enrollment, Feedback** (FR-HRS-021 to FR-HRS-024) — Professional development tracking.

### 15.4 Phase 4 — Exit and Analytics
11. **Exit Management and Experience Certificate** (FR-HRS-025 to FR-HRS-027) — Required before any employee departure.
12. **HR Reports and Dashboard** (FR-HRS-028, FR-HRS-029) — Analytics layer; builds on all above.

### 15.5 Integration Prerequisites
- SchoolSetup module (sch_employees, sch_departments, sch_designations) must be complete — it is.
- Attendance module must be partially operational before FR-HRS-010 (LOP reconciliation).
- Payroll module's `prl_salary_structures` table must be created before `hrs_salary_assignments` FK can be formalized.
