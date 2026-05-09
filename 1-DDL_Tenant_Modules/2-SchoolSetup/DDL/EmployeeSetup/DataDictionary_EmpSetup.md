# Employee Setup — Data Dictionary (v5)

> **Source DDL:** `Employee_setup_ddl_v5.sql` (2026-05-07).
> **Database:** Tenant DB (per-school), MySQL 8+.
> **Scope:** Documents every column of every table in the Employee Setup sub-module — purpose, usability (where/how it is used at the application layer), and any computation formula.

## Conventions used in this document

- **Use** — what the field represents (the "what").
- **Usability** — where the field is consumed (UI screens, services, reports, schedulers).
- **Formula** — populated only when the value is computed or derived. `*` after a formula means it is auto-computed by a STORED GENERATED column at the DB layer; otherwise it is computed by application code or a nightly job.
- **Common audit columns** (appear on most tables) are documented once at the end (§ Appendix A) instead of repeating per table.

## Module overview

| # | Section | Tables |
|---|---------|--------|
| 1 | Master tables | `sch_staff_attendance_types`, `sch_staff_leave_types`, `sch_staff_leave_config` |
| 2 | Employee profile | `sch_employees`, `sch_employees_profile`, `sch_teacher_profile`, `sch_teacher_capabilities` |
| 3 | Personal & professional details | `sch_employee_addresses`, `sch_employee_emergency_contacts`, `sch_employee_bank_details`, `sch_employee_documents` |
| 4 | Employment history | `sch_employee_role_history`, `sch_employee_separations` |
| 5 | Leave management | `sch_leave_approval_policies`, `sch_leave_approval_policy_levels`, `sch_leave_approval_level_approvers`, `sch_employee_leave_applications`, `sch_employee_leave_approvals`, `sch_employee_leave_application_docs`, `sch_employee_leave_application_remarks`, `sch_employee_leave_balance` |
| 6 | Holiday calendar | `sch_holidays` |
| 7 | Shift management | `sch_employee_shifts`, `sch_employee_shift_assignments` |
| 8 | Attendance | `sch_employee_attendance`, `sch_employee_attendance_punches`, `sch_employee_attendance_corrections` |

**Total: 27 tables.**

---

# SECTION 1 — MASTER TABLES

## 1.1 `sch_staff_attendance_types`

Master list of attendance status codes used to mark daily attendance (Present, Absent, Leave, Late, Holiday, etc.).

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate primary key | Referenced by `sch_employee_attendance.status` (logical mapping via name/code) and reports | — |
| `code` | VARCHAR(10) UNIQUE | Short code like `PR`, `AB`, `LV`, `LT`, `HD` | Used in compact attendance reports, mobile UI tag, CSV import/export | — |
| `name` | VARCHAR(100) | Display name e.g. "Present", "Absent" | Shown in UI dropdowns and printed registers | — |
| `category` | ENUM | Groups types into Attendance / Leave / Holiday / Other | Drives grouped totals on reports (e.g. "Total leaves taken") | — |
| `is_present` | TINYINT(1) | Boolean — does this status count as present? | Core flag used by payroll & attendance % calculation | — |
| `can_be_half_day` | TINYINT(1) | Whether this status supports half-day marking | Controls availability of "Half Day" toggle in attendance UI | — |
| `affects_payroll` | TINYINT(1) | Whether this status counts for salary calculation | Used by payroll engine to decide salary deduction | — |
| `payroll_percentage` | DECIMAL(5,2) | % of daily pay for this status | Used in salary calc: `daily_pay × payroll_percentage / 100` | `daily_salary_for_day = base_daily × payroll_percentage / 100` |
| `requires_approval` | TINYINT(1) | Whether the status requires supervisor approval | Triggers approval flow when teacher/HR marks this status | — |
| `color_hex` | VARCHAR(7) | Hex color for calendar/UI cells | Calendar legends, Gantt-style attendance rosters | — |
| `icon_class` | VARCHAR(50) | CSS class for icon | UI rendering on cards & dashboards | — |
| `display_order` | INT | Sort order in dropdowns | UI ordering | — |
| `is_system` | TINYINT(1) | 1 = system-defined, cannot be deleted by user | Locks editing in admin UI | — |
| `is_active` | TINYINT(1) | Soft-active flag | Inactive types are hidden but kept for historical reports | — |
| `created_by` | INT UNSIGNED | FK → `sys_users.id` who created this row | Audit | — |
| `created_at` / `updated_at` / `deleted_at` | TIMESTAMP | Standard audit timestamps | See Appendix A | — |

---

## 1.2 `sch_staff_leave_types`

Master list of leave categories — Casual, Sick, Earned, Maternity, Paternity, Comp-off, Loss-of-pay, etc.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | Referenced by entitlement, balance, application | — |
| `code` | VARCHAR(20) UNIQUE | Short code: `CL`, `SL`, `EL`, `ML`, `PL`, `COMP`, `LWP`, `HALF` | Compact reports, payslip line items | — |
| `name` | VARCHAR(100) | Display name "Casual Leave" etc. | Dropdowns, leave-apply screens | — |
| `description` | VARCHAR(500) | Long-form policy text | Help-tip on the apply-leave form | — |
| `is_paid` | TINYINT(1) | Paid (1) vs Loss-of-pay (0) | Payroll deduction logic | If 0, payroll deducts `total_days × daily_rate` |
| `is_carry_forwardable` | TINYINT(1) | Whether unused days can roll to next year | Year-rollover scheduler reads this | — |
| `is_encashable` | TINYINT(1) | Can be paid out at year-end | Year-end encashment job | — |
| `requires_doc` | TINYINT(1) | Whether the user must upload a supporting document | Validation on apply-leave form | — |
| `min_doc_required_days` | TINYINT UNSIGNED | Doc only required if leave > N days (e.g. SL > 2 days) | Conditional doc requirement: `requires_doc AND total_days > min_doc_required_days` | — |
| `requires_substitute` | TINYINT(1) | Auto-create substitute teacher flow | Triggers `tt_substitution` workflow when teacher applies | — |
| `allows_half_day` | TINYINT(1) | Whether half-day applications are allowed for this type | UI half-day toggle | — |
| `allows_back_dated` | TINYINT(1) | Whether the leave can have a `from_date` in the past | UI date validation | — |
| `requires_approval` | TINYINT(1) | Approval required vs auto-approve | Skips approval workflow when 0 | — |
| `min_days_per_application` | DECIMAL(4,1) | Minimum days per single application (default 0.5 = half-day) | Form validation | — |
| `max_days_per_application` | DECIMAL(4,1) | Cap (e.g. 90 for Maternity); NULL = unlimited | Form validation | — |
| `min_advance_notice_days` | TINYINT UNSIGNED | Apply ≥ N days in advance | Form validation: `(from_date - today) ≥ min_advance_notice_days` | — |
| `max_consecutive_days` | TINYINT UNSIGNED | Max contiguous days; NULL = unlimited | Form validation | — |
| `display_order` | TINYINT UNSIGNED | UI ordering | Dropdown sort | — |
| `color_hex` | VARCHAR(7) | Calendar colour | Calendar visualisation | — |
| `is_system` | TINYINT(1) | 1 = built-in | Lock from delete | — |
| `is_active` | TINYINT(1) | Soft-active | Hide inactive types from new applications | — |
| `created_by`, audit columns | — | See Appendix A | — | — |

---

## 1.3 `sch_staff_leave_config`

Per-(role × leave-type) entitlement and accrual rules. Year-rollover seeds `sch_employee_leave_balance` from these rows.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `leave_type_id` | INT UNSIGNED FK | FK → `sch_staff_leave_types` | Identifies which leave type this rule applies to | — |
| `applies_to_role_id` | INT UNSIGNED FK | NULL = all roles | Policy-matching dimension | — |
| `applies_to_department_id` | INT UNSIGNED FK | NULL = all departments | Policy-matching dimension | — |
| `applies_to_designation_id` | INT UNSIGNED FK | NULL = all designations | Policy-matching dimension | — |
| `applies_to_employment_type` | ENUM | NULL = all employment types | Permanent/Contract/etc. specific rules | — |
| `annual_entitlement` | DECIMAL(5,2) | Days granted per academic year | Year-rollover seeds balance | `opening_balance := annual_entitlement` |
| `accrual_method` | ENUM | `Lump_Sum` / `Monthly_Pro_Rata` / `Quarterly` | Drives accrual scheduler | `Monthly_Pro_Rata`: monthly accrual = `annual_entitlement / 12` |
| `accrual_start_offset_months` | TINYINT UNSIGNED | Wait N months from joining before accrual starts | Probation handling | Accrual begins on `joining_date + accrual_start_offset_months` |
| `is_carry_forwardable` | TINYINT(1) | Whether unused balance carries forward | Year-rollover logic | — |
| `max_carry_forward` | DECIMAL(5,2) | Max days that can be carried forward | Year-rollover cap | `carry_forward = MIN(remaining_balance, max_carry_forward)` |
| `is_encashable_at_separation` | TINYINT(1) | Encashable on resignation/retirement | Separation full-and-final calc | — |
| `max_encashable_days` | DECIMAL(5,2) | Cap on encashment | F&F amount calc | `encash_days = MIN(balance, max_encashable_days)` |
| `available_during_probation` | TINYINT(1) | 0: Not allowed during probation | Apply-leave form validation against `employment_status='Probation'` | — |
| `probation_entitlement_pro_rata` | TINYINT(1) | Pro-rata entitlement during probation | Initial allocation calc | If 1: `entitlement = annual × probation_months / 12` |
| `priority` | TINYINT UNSIGNED | Tie-breaker when multiple rows match (lower = higher priority) | Policy matcher service | — |
| `is_active`, `created_by`, audit columns | — | See Appendix A | — | — |

**Policy matching algorithm** — when computing entitlement for an employee:
1. Filter rows where each `applies_to_*` column either equals the employee's value or is NULL.
2. Pick the row with the smallest `priority`. If still tied, pick the most-specific (fewest NULL `applies_to_*`).

---

# SECTION 2 — EMPLOYEE CREATION & PROFILE MANAGEMENT

## 2.1 `sch_employees`

Master record per employee. Personal + identity + employment lifecycle. One row per employee.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | All FK references hang off this | — |
| `user_id` | INT UNSIGNED FK | FK → `sys_users.id` | Login identity, RBAC | — |
| `emp_code` | VARCHAR(20) UNIQUE | Internal employee code (e.g. `T-2026-0014`) | ID cards, payslips, search, reports | — |
| `emp_id_card_type` | ENUM | `QR` / `RFID` / `NFC` / `Barcode` | ID card printing service | — |
| `emp_smart_card_id` | VARCHAR(100) | Physical card serial/UID | Biometric/RFID terminal lookup | — |
| `first_name`, `middle_name`, `last_name` | VARCHAR(100) | Mirrored from `sys_users` for fast HR queries | List views, filters, payslips | — |
| `gender` | ENUM | Male/Female/Other/Prefer Not to Say | Statutory reports, restroom assignment | — |
| `date_of_birth` | DATE | DOB | Statutory; birthday reminders; retirement calc | `retirement_date = date_of_birth + 60 years` (config) |
| `marital_status` | ENUM | Marital state | Insurance/benefits forms | — |
| `blood_group` | ENUM | Blood group | Medical emergency screen | — |
| `nationality` | VARCHAR(50) | Default 'Indian' | Statutory forms, visa tracking | — |
| `religion` | VARCHAR(50) | Religion | Statutory diversity reports | — |
| `mother_tongue` | VARCHAR(50) | Native language | Bilingual classroom assignment | — |
| `photo_media_id` | INT UNSIGNED FK | FK → `sys_media.id` | Avatar in directory, ID card | — |
| `mobile_number_primary` | VARCHAR(20) | Primary phone | Notifications, SMS-OTP | — |
| `mobile_number_alternate` | VARCHAR(20) | Alternate phone | Backup contact | — |
| `personal_email` | VARCHAR(150) | Personal email | Off-boarded comms | — |
| `official_email` | VARCHAR(150) | School-issued email | Official comms | — |
| `aadhaar_number` | VARCHAR(20) UNIQUE | Aadhaar (encrypted at app layer) | Statutory; PF/ESI filings | — |
| `pan_number` | VARCHAR(15) UNIQUE | PAN | TDS filings | — |
| `pf_number` | VARCHAR(30) | Provident Fund number | Payroll PF deduction | — |
| `esi_number` | VARCHAR(30) | Employee State Insurance | ESI deduction & claims | — |
| `uan_number` | VARCHAR(20) | Universal Account Number for PF | EPFO portal | — |
| `is_teacher` | TINYINT(1) | 1 = teacher (drives `sch_teacher_profile` row) | Routing during onboarding | — |
| `joining_date` | DATE | Date of joining | Tenure / leave-accrual base date | `tenure_years = (today - joining_date) / 365.25` |
| `total_experience_years` | DECIMAL(4,1) | Total prior + current experience | Recruitment & promotion eval | — |
| `highest_qualification` | VARCHAR(100) | E.g. "M.Sc Mathematics" | Directory, statutory reports | — |
| `specialization` | VARCHAR(150) | Subject specialization | Teaching subject mapping | — |
| `last_institution` | VARCHAR(200) | Previous employer | Background check | — |
| `awards` | TEXT | Notable awards | Profile / faculty page | — |
| `skills` | TEXT | Free-text skills list | Search & matching | — |
| `qualifications_json` | JSON | Structured qualifications history | Profile page; e.g. `[{degree, university, year, percentage}]` | — |
| `certifications_json` | JSON | Structured certifications | Expiry tracking | — |
| `experiences_json` | JSON | Structured prior experience | CV view | — |
| `employment_status` | ENUM | Lifecycle state (`Active`/`On Leave`/`Resigned`/...) | Drives FSM; affects login & payroll | — |
| `employment_type` | ENUM | Permanent/Contract/etc. | Salary structure, leave entitlement | — |
| `confirmation_date` | DATE | Confirmation after probation | Triggers role-history "Confirmation" entry | — |
| `probation_end_date` | DATE | Last day of probation | Probation expiry alerts | — |
| `last_working_date` | DATE | Set on resignation/termination | F&F calc, access revocation | — |
| `notes` | TEXT | Free-form HR notes | HR back-office | — |
| `is_active` | TINYINT(1) | Soft-active flag | Hides inactive employees from active lists | — |
| `created_by`, `created_at`, `updated_at`, `deleted_at` | — | See Appendix A | — | — |

> **Note on `branch_id`.** The DDL references `idx_employees_branch (branch_id)` but the column is not declared in the visible v5 column list (apparent gap inherited from v4). Application code should treat it as DEFERRED until the column is explicitly added — index will fail to apply otherwise.

---

## 2.2 `sch_employees_profile`

Non-teacher employee profile (admin/staff/finance/IT). One ACTIVE row per `(employee_id, role_id)` enforced via `active_flag`.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `employee_id` | INT UNSIGNED FK | FK → `sch_employees.id` | Owner | — |
| `user_id` | INT UNSIGNED FK | FK → `sys_users.id` | RBAC | — |
| `role_id` | INT UNSIGNED FK | FK → `sch_employee_roles.id` | Role-based feature gating | — |
| `department_id` | INT UNSIGNED FK | FK → `sch_departments.id` | Department directory | — |
| `specialization_area` | VARCHAR(100) | E.g. HR / Finance / IT | Search; assignment routing | — |
| `qualification_level` | VARCHAR(50) | Bachelor/Master/PhD | Statutory reports | — |
| `qualification_field` | VARCHAR(100) | Field of study | Profile | — |
| `certifications` | JSON | Structured certifications with issue/expiry | Expiry alerts | — |
| `work_hours_daily` | DECIMAL(4,2) | Expected daily work hours (default 8.0) | Overtime calc baseline | `OT = max(0, actual_hours − work_hours_daily)` |
| `max_hours_daily` | DECIMAL(4,2) | Cap per day (default 10.0) | Overtime hard cap | — |
| `work_hours_weekly` | DECIMAL(5,2) | Expected weekly hours (default 40.0) | Weekly compliance | — |
| `max_hours_weekly` | DECIMAL(5,2) | Cap per week (default 50.0) | Weekly overtime cap | — |
| `preferred_shift` | ENUM | Morning/Evening/Flexible | Shift-assignment hint | — |
| `is_full_time` | TINYINT(1) | Full vs part-time | Salary structure | — |
| `core_responsibilities` | JSON | List of `{type, description}` | Job description page | — |
| `technical_skills` | JSON | `[{skill, proficiency}]` | Search & match | — |
| `soft_skills` | JSON | `[{skill, proficiency}]` | Performance review | — |
| `experience_months` | SMALLINT UNSIGNED | Total months of experience | Promotion eligibility | `experience_months = (today − joining_date_first_job) months` |
| `performance_rating` | TINYINT UNSIGNED | 1–5 | Appraisal / increment | — |
| `last_performance_review` | DATE | Last review date | Schedules next review | `next_review_due = last_performance_review + 12 months` |
| `security_clearance_done` | TINYINT(1) | 0/1 | Sensitive-data access gate | — |
| `reporting_to` | INT UNSIGNED FK | FK → `sch_employees.id` | Org chart, leave routing default | — |
| `can_approve_budget` | TINYINT(1) | 0/1 | Finance module gate | — |
| `can_manage_staff` | TINYINT(1) | 0/1 | Direct-reports view | — |
| `can_access_sensitive_data` | TINYINT(1) | 0/1 | Salary / PII screens | — |
| `assignment_meta` | JSON | E.g. `{current_projects, past_projects}` | Profile timeline | — |
| `notes` | TEXT | Free-form | HR | — |
| `effective_from` | DATE | When this profile became effective | Historical view | — |
| `effective_to` | DATE | Marked end-date (kept for audit; superseded by `active_flag`) | Historical view | — |
| `is_active` | TINYINT(1) | Active/inactive | Combined with `deleted_at` to drive `active_flag` | — |
| `active_flag` | TINYINT(1) GENERATED | Auto-computed: 1 when active and not deleted, NULL otherwise | Used in UNIQUE `(employee_id, role_id, active_flag)` to guarantee one active per pair | `CASE WHEN is_active=1 AND deleted_at IS NULL THEN 1 ELSE NULL END` * |
| audit columns | — | See Appendix A | — | — |

---

## 2.3 `sch_teacher_profile`

Teacher-specific profile. One row per teacher (UNIQUE on `employee_id`).

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `employee_id` | INT UNSIGNED FK UNIQUE | FK → `sch_employees.id` | One profile per teacher | — |
| `user_id`, `role_id`, `department_id`, `designation_id` | INT UNSIGNED FK | Standard org-context FKs | RBAC, directory | — |
| `teacher_house_room_id` | INT UNSIGNED | FK → staff-room/house room | Directory; locker assignment | — |
| `is_class_teacher` | TINYINT(1) | Denormalised flag | Fast filter "show class teachers" | — |
| `class_teacher_of_class_id` | INT UNSIGNED FK | FK → `sch_classes.id` | Class-teacher view | — |
| `class_teacher_of_section_id` | INT UNSIGNED FK | FK → `sch_sections.id` | Section-level scoping | — |
| `is_full_time` | TINYINT(1) | Full vs part-time | Allocation engine | — |
| `preferred_shift` | ENUM | Morning/Evening/Flexible | Shift assignment | — |
| `capable_handling_multiple_classes` | TINYINT(1) | Can handle multiple classes simultaneously (lab/library) | Allocation engine | — |
| `can_be_used_for_substitution` | TINYINT(1) | Available as substitute | Substitution dispatcher | — |
| `certified_for_lab` | TINYINT(1) | Lab-supervision certification | Lab period allocation | — |
| `is_proficient_with_computer` | TINYINT(1) | Comfortable with computer-aided teaching | Smart-classroom assignment | — |
| `can_manage_staff` | TINYINT(1) | Has direct reports / admin power | Reporting hierarchy | — |
| `special_skill_area` | VARCHAR(100) | E.g. STEM, Special Needs, Sports | Niche allocation | — |
| `soft_skills` | JSON | `[{skill, proficiency}]` | Appraisal | — |
| `assignment_meta` | JSON | `{current_classes, past_classes}` | Profile | — |
| `max_available_periods_weekly` | TINYINT UNSIGNED | Max weekly periods this teacher *can* take | FET solver upper bound | — |
| `min_available_periods_weekly` | TINYINT UNSIGNED | Min weekly periods to be considered full-time | FET solver lower bound | — |
| `max_allocated_periods_weekly` | TINYINT UNSIGNED | Hard upper limit on allocations | Solver hard constraint | — |
| `min_allocated_periods_weekly` | TINYINT UNSIGNED | Hard lower limit | Solver hard constraint | — |
| `can_be_split_across_sections` | TINYINT(1) | Allow splitting period assignment across sections | Solver flexibility | — |
| `min_teacher_availability_score` | DECIMAL(7,2) | 0..1 minimum availability acceptable | Solver scoring | `score = present_periods / total_offered_periods` |
| `max_teacher_availability_score` | DECIMAL(7,2) | 0..1 ceiling | Solver scoring | — |
| `performance_rating` | TINYINT UNSIGNED | 1–5 | Appraisal | — |
| `last_performance_review` | DATE | Last review date | Schedules next | `next_due = last_performance_review + 12m` |
| `security_clearance_done` | TINYINT(1) | 0/1 | Access gate | — |
| `reporting_to` | INT UNSIGNED FK | FK → `sch_employees.id` | Org chart | — |
| `can_access_sensitive_data` | TINYINT(1) | Sensitive-info access gate | RBAC | — |
| `notes` | TEXT | Free-form | HR | — |
| `effective_from`, `effective_to` | DATE | Validity period | Historical view | — |
| `created_by`, audit columns | — | See Appendix A | — | — |

---

## 2.4 `sch_teacher_capabilities`

Capability matrix: which `(class × subject_study_format)` a teacher can teach, with proficiency, priority, and solver hints.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `teacher_profile_id` | INT UNSIGNED FK | FK → `sch_teacher_profile.id` | Owner | — |
| `class_id` | INT UNSIGNED FK | FK → `sch_classes.id` | Capability dimension | — |
| `subject_study_format_id` | INT UNSIGNED FK | FK → `sch_subject_study_format_jnt.id` | Capability dimension | — |
| `proficiency_percentage` | TINYINT UNSIGNED | 0–100 | Solver scoring component | — |
| `teaching_experience_months` | SMALLINT UNSIGNED | Months teaching this combination | Solver scoring | `experience_score = LEAST(teaching_experience_months / 60, 1)` |
| `is_primary_subject` | TINYINT(1) | Primary teaching focus | Solver preference | — |
| `competency_level` | ENUM | `Facilitator`/`Basic`/`Intermediate`/`Advanced`/`Expert` | Solver scoring (qualitative) | — |
| `priority_order` | INT UNSIGNED | Tie-breaker — lower = higher priority | Solver | — |
| `priority_weight` | TINYINT UNSIGNED | 0–100 — institutional priority weight | Solver scoring | `score += priority_weight × W_PRIORITY` |
| `scarcity_index` | TINYINT UNSIGNED | How rare is this skill in the school | Solver — boost for rare skills | `scarcity_index = ROUND(100 × (1 − teachers_with_capability / total_teachers))` |
| `is_hard_constraint` | TINYINT(1) | 1 = solver MUST honour | Solver | — |
| `allocation_strictness` | ENUM | `Hard`/`Medium`/`Soft` | Solver penalty weights | — |
| `override_priority` | TINYINT UNSIGNED | Manual priority override (lower = higher) | Solver — wins over computed | — |
| `override_reason` | VARCHAR(255) | Audit text for the override | Audit / explanation panel | — |
| `historical_success_ratio` | TINYINT UNSIGNED | 0–100 — past performance | Solver scoring | `historical_success_ratio = ROUND(100 × successful_periods / total_periods)` |
| `last_allocation_score` | TINYINT UNSIGNED | Last computed solver score | Diagnostic / explainability | `score = (proficiency × Wp + experience_score × We + priority_weight × Wpw + scarcity_index × Ws + historical_success_ratio × Wh) / sum(weights)` |
| `effective_from`, `effective_to` | DATE | Validity range | Historical | — |
| `is_active` | TINYINT(1) | Active/inactive | Combined with `active_flag` | — |
| `active_flag` | TINYINT(1) GENERATED | Auto: 1 when active else NULL | Enforces UNIQUE `(teacher_profile_id, class_id, subject_study_format_id, active_flag)` | `CASE WHEN is_active=1 THEN 1 ELSE NULL END` * |
| `created_by`, audit columns | — | See Appendix A | — | — |

---

# SECTION 3 — EMPLOYEE PERSONAL & PROFESSIONAL DETAILS

## 3.1 `sch_employee_addresses`

Multi-row address store per employee (Current / Permanent / Emergency / Local).

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `employee_id` | INT UNSIGNED FK | FK → `sch_employees.id` | Owner | — |
| `address_type` | ENUM | `Current`/`Permanent`/`Emergency`/`Local_Address`/`Other` | Distinguishes purpose | — |
| `address_line_1` | VARCHAR(200) NOT NULL | Building / street | Postal address rendering | — |
| `address_line_2` | VARCHAR(200) | Locality | Postal | — |
| `landmark` | VARCHAR(150) | Nearby reference | Courier delivery | — |
| `city` | VARCHAR(100) NOT NULL | City | Demographic reports | — |
| `district` | VARCHAR(100) | District | Government forms | — |
| `state` | VARCHAR(100) NOT NULL | State | TDS state mapping | — |
| `pincode` | VARCHAR(15) NOT NULL | Postal code | Postal validation | — |
| `country` | VARCHAR(50) | Default 'India' | International staff | — |
| `is_same_as_permanent` | TINYINT(1) | 1 = current address copy of permanent | UI shortcut "Same as permanent" | — |
| `is_primary` | TINYINT(1) | Primary among multiple of same type | Default selected on profile | — |
| `effective_from`, `effective_to` | DATE | Validity range | Historical move-tracking | — |
| `notes` | VARCHAR(255) | Free-form | HR | — |
| `is_active`, `created_by`, audit columns | — | See Appendix A | — | — |

---

## 3.2 `sch_employee_emergency_contacts`

Emergency contact persons per employee.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `employee_id` | INT UNSIGNED FK | Owner | — | — |
| `contact_name` | VARCHAR(150) NOT NULL | Contact name | Emergency call list | — |
| `relation` | VARCHAR(50) NOT NULL | Spouse/Father/Mother/Sibling/Friend/Other | Filter and sort | — |
| `mobile_number` | VARCHAR(20) NOT NULL | Primary phone | First call | — |
| `alternate_number` | VARCHAR(20) | Backup phone | Fallback | — |
| `email` | VARCHAR(150) | Email | Emergency mailer | — |
| `address` | VARCHAR(500) | Emergency address | Hospital / police forms | — |
| `is_primary` | TINYINT(1) | 1 = call FIRST | Auto-dial first | — |
| `priority_order` | TINYINT UNSIGNED | Order when looping (1 = first) | Call-cascade order | — |
| `is_active`, `created_by`, audit columns | — | See Appendix A | — | — |

---

## 3.3 `sch_employee_bank_details`

Salary bank account information.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `employee_id` | INT UNSIGNED FK | Owner | — | — |
| `bank_name` | VARCHAR(150) NOT NULL | Bank | Salary file generation | — |
| `branch_name` | VARCHAR(150) | Branch | Reference | — |
| `account_holder_name` | VARCHAR(150) NOT NULL | Account holder name (may differ from employee for joint) | Verification | — |
| `account_number` | VARCHAR(50) NOT NULL | Account # (encrypted at app layer) | Salary credit | — |
| `account_type` | ENUM | Savings/Current/Salary/NRE/NRO/Other | Compliance | — |
| `ifsc_code` | VARCHAR(20) NOT NULL | IFSC | NEFT/IMPS routing | — |
| `swift_code` | VARCHAR(20) | SWIFT | Overseas wires | — |
| `iban` | VARCHAR(40) | IBAN | Overseas wires | — |
| `is_primary_for_salary` | TINYINT(1) | Account chosen for salary | Payroll picks this account | — |
| `verified_at` | TIMESTAMP | Verification timestamp | Compliance | — |
| `verified_by` | INT UNSIGNED FK | FK → `sys_users.id` (verifier) | Audit | — |
| `cancelled_cheque_media_id` | INT UNSIGNED FK | FK → `sys_media.id` | Verification artefact | — |
| `notes` | VARCHAR(255) | Free-form | HR | — |
| `is_active`, `created_by`, audit columns | — | See Appendix A | — | — |

---

## 3.4 `sch_employee_documents`

Generic document store (joining letter, ID proof, contracts, certifications).

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `employee_id` | INT UNSIGNED FK | Owner | — | — |
| `document_category` | ENUM | `ID_Proof`/`Address_Proof`/`Educational`/`Experience`/`Joining`/`Contract`/`NDA`/`Salary_Slip`/`Tax`/`Health`/`Photo`/`Other` | Tabbed UI | — |
| `document_name` | VARCHAR(150) NOT NULL | Display name e.g. "Aadhaar Card" | UI list | — |
| `document_number` | VARCHAR(100) | Card / certificate # | Verification | — |
| `issued_by` | VARCHAR(150) | Issuing authority | Verification | — |
| `issued_date` | DATE | Issue date | Verification | — |
| `expiry_date` | DATE | Expiry; NULL = non-expiring | Renewal alerts | Alert if `expiry_date − today ≤ 30 days` |
| `media_id` | INT UNSIGNED FK | FK → `sys_media.id` | File preview/download | — |
| `file_name` | VARCHAR(255) | Convenience for legacy storage | Legacy fallback | — |
| `is_verified` | TINYINT(1) | Verification status | Compliance dashboard | — |
| `verified_at` | TIMESTAMP | Verification time | Audit | — |
| `verified_by` | INT UNSIGNED FK | Verifier | Audit | — |
| `notes` | VARCHAR(500) | Free-form | HR | — |
| `is_active`, `created_by`, audit columns | — | See Appendix A | — | — |

---

# SECTION 4 — EMPLOYMENT HISTORY

## 4.1 `sch_employee_role_history`

Append-only audit log of role/department/designation changes.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `employee_id` | INT UNSIGNED FK | Owner | — | — |
| `change_type` | ENUM | `Promotion`/`Demotion`/`Transfer`/`Role_Change`/`Department_Change`/`Designation_Change`/`Confirmation`/`Probation_Extended`/`Other` | Filtering, reports | — |
| `from_role_id`, `from_department_id`, `from_designation_id` | INT UNSIGNED FK | Snapshot BEFORE change | Diff display | — |
| `to_role_id`, `to_department_id`, `to_designation_id` | INT UNSIGNED FK | Snapshot AFTER change | Diff display | — |
| `effective_from` | DATE NOT NULL | Effective date | Tenure timeline | — |
| `effective_to` | DATE | NULL = current; set when superseded | Timeline | — |
| `reason` | VARCHAR(500) | Reason / justification | Audit | — |
| `order_reference` | VARCHAR(100) | HR order number | Audit | — |
| `approved_by` | INT UNSIGNED FK | FK → `sys_users.id` | Audit | — |
| `approved_at` | TIMESTAMP | Approval timestamp | Audit | — |
| `order_media_id` | INT UNSIGNED FK | FK → `sys_media.id` (scanned order) | Document attachment | — |
| `is_active`, `created_by`, audit columns | — | See Appendix A | — | — |

---

## 4.2 `sch_employee_separations`

Resignation / termination / retirement workflow record.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `employee_id` | INT UNSIGNED FK | Owner | — | — |
| `separation_type` | ENUM | `Resignation`/`Termination`/`Retirement`/`End_of_Contract`/`Death`/`Absconded`/`Other` | Drives workflow | — |
| `initiated_by` | ENUM | `Employee`/`Employer`/`System` | Audit | — |
| `initiated_at` | TIMESTAMP | When initiated | SLA timers | — |
| `notice_period_days` | SMALLINT UNSIGNED | Notice period required | Drives `intended_last_working_date` | `intended_last_working_date = notice_start_date + notice_period_days` |
| `notice_start_date` | DATE | Notice clock start | — | — |
| `intended_last_working_date` | DATE | Planned LWD | Calendar | — |
| `actual_last_working_date` | DATE | Actual LWD | Access revocation, F&F | — |
| `reason_category` | VARCHAR(100) | Coarse reason | Attrition analytics | — |
| `reason` | TEXT | Free-form reason | Audit | — |
| `status` | ENUM | `Initiated`/`Under_Review`/`Approved`/`Notice_Period`/`Completed`/`Cancelled`/`Rejected` | Workflow FSM | — |
| `approved_by` | INT UNSIGNED FK | FK → `sys_users.id` | Audit | — |
| `approved_at` | TIMESTAMP | Approval time | SLA | — |
| `exit_interview_done` | TINYINT(1) | 0/1 | Checklist | — |
| `exit_interview_notes` | TEXT | Interview transcript | HR archive | — |
| `clearance_complete` | TINYINT(1) | All-cleared flag | Gate F&F payment | — |
| `clearance_summary_json` | JSON | Per-dept clearance e.g. `{IT:true, Library:true, Finance:false}` | Dashboard | — |
| `final_settlement_done` | TINYINT(1) | F&F payment status | Gate relieving letter | — |
| `final_settlement_amount` | DECIMAL(12,2) | F&F amount paid | Payroll record | `F&F = pending_salary + leave_encash − advances − recoveries + bonus + gratuity` |
| `relieving_letter_issued` / `experience_letter_issued` | TINYINT(1) | Issuance flags | Off-boarding | — |
| `relieving_letter_media_id` / `experience_letter_media_id` | INT UNSIGNED FK | Letter attachments | Download | — |
| `is_eligible_for_rehire` | TINYINT(1) | Future re-hire eligibility | Background check on re-application | — |
| `rehire_notes` | VARCHAR(500) | Notes for future re-hire | HR | — |
| `is_active`, `created_by`, audit columns | — | See Appendix A | — | — |

---

# SECTION 5 — LEAVE MANAGEMENT

## 5.1 `sch_leave_approval_policies`

Master list of approval policies — matches an employee's context to an approval pipeline.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `name` | VARCHAR(150) NOT NULL | Display name | Admin UI | — |
| `description` | VARCHAR(500) | Long description | Admin UI | — |
| `applies_to_role_id`, `applies_to_department_id`, `applies_to_designation_id`, `applies_to_leave_type_id` | INT UNSIGNED FK | NULL = wildcard | Policy matcher | — |
| `priority` | TINYINT UNSIGNED | Tie-breaker (lower = higher) | Matcher | — |
| `is_active`, `created_by`, audit | — | See Appendix A | — | — |

**Policy match algorithm** — same as §1.3 (most-specific match wins; tiebreak via `priority`).

---

## 5.2 `sch_leave_approval_policy_levels`

Ordered approval levels within a policy (Level 1 → 2 → 3 …).

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `policy_id` | INT UNSIGNED FK | FK → `sch_leave_approval_policies.id` | Parent | — |
| `level_number` | TINYINT UNSIGNED NOT NULL | 1, 2, 3, … (UNIQUE per policy) | Sequence | — |
| `level_name` | VARCHAR(100) NOT NULL | "Reporting Manager" / "HOD" / "HR" / "Principal" | UI | — |
| `approval_mode` | ENUM | `ANY_ONE` (any one approver suffices) / `ALL` (all approvers must approve) | Workflow engine | — |
| `escalation_after_hours` | SMALLINT UNSIGNED | Escalate after N hours of inaction; NULL = never | Scheduler | `deadline = pending_since + escalation_after_hours` |
| `notify_applicant_on_escalation` | TINYINT(1) | Notify applicant on escalation | Notification engine | — |
| `is_active`, `created_by`, audit | — | See Appendix A | — | — |

---

## 5.3 `sch_leave_approval_level_approvers`

Authorised approvers per level (User / Role / Designation / Department-head / Reporting-to).

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `level_id` | INT UNSIGNED FK | FK → `sch_leave_approval_policy_levels.id` | Parent | — |
| `approver_type` | ENUM | `USER`/`ROLE`/`DESIGNATION`/`DEPARTMENT_HEAD`/`REPORTING_TO` | Resolves who can approve | — |
| `approver_user_id` | INT UNSIGNED FK | Direct user | Used when `type=USER` | — |
| `approver_role_id` | INT UNSIGNED FK | Role-based | Used when `type=ROLE` | — |
| `approver_designation_id` | INT UNSIGNED FK | Designation-based | Used when `type=DESIGNATION` | — |
| `approver_department_id` | INT UNSIGNED FK | Department head | Used when `type=DEPARTMENT_HEAD` | — |
| `approver_reporting_to_id` | INT UNSIGNED FK | Direct reporting manager | Used when `type=REPORTING_TO` | — |
| `is_active`, `created_by`, audit | — | See Appendix A | — | — |

**Resolver rule** — for each row, exactly one of the `approver_*_id` columns must match the `approver_type`.

---

## 5.4 `sch_employee_leave_applications`

Leave application records — the central request entity.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `employee_id` | INT UNSIGNED FK | Applicant | List filter | — |
| `academic_session_id` | INT UNSIGNED FK | FK → `sch_org_academic_sessions_jnt.id` | Per-academic-year balance | — |
| `leave_type_id` | INT UNSIGNED FK | FK → `sch_staff_leave_types.id` | Validation, balance debit | — |
| `from_date`, `to_date` | DATE NOT NULL | Range applied for | Calendar | — |
| `total_days` | DECIMAL(4,1) NOT NULL DEFAULT 1.0 | Effective days requested | Balance debit | `total_days = working_days_between(from_date, to_date) − holidays_in_range − weekends; halve if is_half_day` |
| `is_half_day` | TINYINT(1) | Half-day flag | UI | — |
| `half_day_slot` | ENUM | `Morning`/`Afternoon` | Substitution scheduling | — |
| `is_emergency` | TINYINT(1) | Emergency / same-day leave | Bypasses `min_advance_notice_days`; flagged for review | — |
| `reason` | TEXT NOT NULL | Justification | Approval | — |
| `status` | ENUM | `Draft`/`Submitted`/`Under Review`/`Info Requested`/`Doc Requested`/`Escalated`/`Approved`/`Rejected`/`Cancelled` | Workflow FSM | — |
| `approval_policy_id` | INT UNSIGNED FK | Policy resolved at submit-time | Workflow engine | — |
| `current_level_number` | TINYINT UNSIGNED | Current pending level | Dashboard "where is my leave" | — |
| `pending_with_user_id` | INT UNSIGNED FK | Currently-actionable user | Approver dashboard | — |
| `applied_by` | INT UNSIGNED FK NOT NULL | Who created (employee or admin on-behalf) | Audit | — |
| `submitted_at` | TIMESTAMP | Time of submission | SLA clock starts | — |
| `cancelled_by`, `cancelled_at`, `cancellation_reason` | — | Cancellation audit | History | — |
| `final_reviewed_by`, `final_reviewed_at` | — | Final decision audit | History | — |
| `approved_days` | DECIMAL(4,1) | Approved subset (partial approval allowed) | Balance debit | `balance.total_used += approved_days` |
| `final_remarks` | TEXT | Final approval/rejection notes | Audit | — |
| `is_active`, `created_by`, audit | — | See Appendix A | — | — |

---

## 5.5 `sch_employee_leave_approvals`

Per-level approver action trail — one row per (application, level, approver action).

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `leave_application_id` | INT UNSIGNED FK | FK → application | Parent | — |
| `policy_level_id` | INT UNSIGNED FK | FK → policy level | Which level | — |
| `level_number` | TINYINT UNSIGNED | Redundant for fast queries | Dashboard | — |
| `level_name` | VARCHAR(100) | Snapshot of level name | Display (preserved if level renamed later) | — |
| `approver_user_id` | INT UNSIGNED FK | Who acted | Audit | — |
| `action` | ENUM | `Pending`/`Approved`/`Rejected`/`Info Requested`/`Doc Requested`/`Escalated`/`Skipped` | Workflow | — |
| `remarks` | TEXT | Action remarks | Audit | — |
| `acted_at` | TIMESTAMP | When acted | SLA | — |
| `escalation_deadline` | TIMESTAMP | Auto-escalation cutoff | Scheduler | `deadline = pending_at + level.escalation_after_hours` |
| `escalated_at` | TIMESTAMP | Escalation timestamp | Audit | — |
| `escalated_to_level` | TINYINT UNSIGNED | Next level on escalation | Workflow | — |
| `is_active`, `created_by`, audit | — | See Appendix A | — | — |

---

## 5.6 `sch_employee_leave_application_docs`

Supporting documents attached to a leave application.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `leave_application_id` | INT UNSIGNED FK | Parent | — | — |
| `document_name` | VARCHAR(150) NOT NULL | Display name | UI | — |
| `document_type_id` | INT UNSIGNED FK | FK → `sys_dropdown_table.id` | Categorisation | — |
| `description` | VARCHAR(255) | Optional description | UI | — |
| `file_name` | VARCHAR(255) NOT NULL | Filename | Convenience | — |
| `media_id` | INT UNSIGNED FK | FK → `sys_media.id` | Spatie media link | — |
| `uploaded_by` | INT UNSIGNED FK NOT NULL | Uploader | Audit | — |
| `is_in_response_to_request` | TINYINT(1) | 1 if this doc was uploaded in response to an info/doc request | Workflow correlation | — |
| `request_remark_id` | INT UNSIGNED | FK → `sch_employee_leave_application_remarks.id` (the request remark) | Threading | — |
| `is_active`, `created_by`, audit | — | See Appendix A | — | — |

---

## 5.7 `sch_employee_leave_application_remarks`

Approver ↔ Employee message thread + FSM audit log.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `leave_application_id` | INT UNSIGNED FK | Parent | — | — |
| `approval_level_id` | INT UNSIGNED FK | Level context (NULL for general comment) | Threading | — |
| `remark_type` | ENUM | `Comment`/`Info_Request`/`Doc_Request`/`Response`/`Status_Change` | Display style | — |
| `message` | TEXT NOT NULL | Message body | UI | — |
| `is_from_approver` | TINYINT(1) | 1 if from an approver | UI alignment | — |
| `remarked_by` | INT UNSIGNED FK NOT NULL | Author | Display | — |
| `parent_remark_id` | INT UNSIGNED FK | Reply-to | Threading | — |
| `is_resolved` | TINYINT(1) | Resolution status (e.g. info-request closed) | Outstanding-asks dashboard | — |
| `resolved_at` | TIMESTAMP | Resolution time | SLA | — |
| `read_at` | TIMESTAMP | When recipient first read | Read receipts | — |
| `read_by` | INT UNSIGNED FK | Reader | Read receipts | — |
| `old_status` / `new_status` | VARCHAR(30) | FSM transition snapshot for `Status_Change` rows | Audit | — |
| `is_active`, `created_by`, audit | — | See Appendix A | — | — |

---

## 5.8 `sch_employee_leave_balance`

Live leave-balance ledger per `(employee, academic_year, leave_type)`.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `employee_id` | INT UNSIGNED FK | Owner | UNIQUE with year + leave-type | — |
| `academic_year` | VARCHAR(9) NOT NULL | E.g. "2026-2027" | UI filter | — |
| `leave_type_id` | INT UNSIGNED FK | FK → leave type | Type-wise balance | — |
| `opening_balance` | DECIMAL(5,2) | Year-start entitlement | Year-rollover seed | `opening_balance := config.annual_entitlement` |
| `carry_forward` | DECIMAL(5,2) | Carried from prior year | Year-rollover | `carry_forward = MIN(prior_year_remaining, config.max_carry_forward)` |
| `total_used` | DECIMAL(5,2) | Days used so far | Real-time on approval | `total_used = SUM(approved_days WHERE status='Approved')` |
| `total_pending` | DECIMAL(5,2) | Days in pending applications | UI hint | `total_pending = SUM(total_days WHERE status IN ('Submitted','Under Review',...))` |
| `available_balance` | DECIMAL(5,2) STORED | Live available days | Form validation, payslip | `opening_balance + carry_forward − total_used` * |
| `manual_adjustment` | DECIMAL(5,2) | HR-applied adjustment (+/−) | Corrections | — |
| `adjustment_reason` | VARCHAR(255) | Why the adjustment | Audit | — |
| `is_active`, `created_by`, `updated_by`, audit | — | See Appendix A | — | — |

> **Ledger refresh rule.** Whenever an application moves to `Approved`, increment `total_used` by `approved_days`. When it moves to `Rejected`/`Cancelled`, decrement `total_pending`. `available_balance` is auto-recomputed by the STORED generated column.

---

# SECTION 6 — HOLIDAY CALENDAR

## 6.1 `sch_holidays`

School holiday calendar (public, religious, optional, school-specific).

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `academic_session_id` | INT UNSIGNED FK | FK → `sch_org_academic_sessions_jnt.id` | Year scoping | — |
| `holiday_date` | DATE NOT NULL | The date | Calendar | — |
| `name` | VARCHAR(150) NOT NULL | "Diwali", "Republic Day" | UI label | — |
| `description` | VARCHAR(500) | Notes | UI | — |
| `holiday_type` | ENUM | `Public`/`Religious`/`Optional`/`School_Specific`/`Sunday`/`Saturday`/`Vacation`/`Other` | Filter, payroll handling | — |
| `is_optional` | TINYINT(1) | Optional holidays — employee picks N from a list | Optional-leave UI | — |
| `is_paid` | TINYINT(1) | Paid (1) / unpaid (0) | Payroll | — |
| `applies_to_role_id` / `applies_to_department_id` | INT UNSIGNED FK | NULL = all | Role/dept-scoped holidays | — |
| `is_active`, `created_by`, audit | — | See Appendix A | — | — |

**Used by** — leave-day counter (excludes holidays from `total_days`), attendance engine (sets `sch_employee_attendance.is_holiday=1`).

---

# SECTION 7 — SHIFT MANAGEMENT

## 7.1 `sch_employee_shifts`

Shift master.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `code` | VARCHAR(20) UNIQUE | Short code | Reports | — |
| `name` | VARCHAR(100) NOT NULL | Display name | UI | — |
| `start_time` | TIME NOT NULL | Shift start | Schedule | — |
| `end_time` | TIME NOT NULL | Shift end | Schedule | — |
| `break_duration_minutes` | SMALLINT UNSIGNED | Break minutes (e.g. 60 for lunch) | Working-hour calc | — |
| `working_hours` | DECIMAL(4,2) NOT NULL | Net working hours | Payroll baseline | `working_hours = (end_time − start_time) − break_duration_minutes/60` |
| `grace_minutes_late` | SMALLINT UNSIGNED | Grace before late mark | Attendance engine | If `actual_check_in − start_time > grace_minutes_late` → mark `Late` |
| `grace_minutes_early` | SMALLINT UNSIGNED | Grace before early-leaving mark | Attendance | — |
| `half_day_threshold_minutes` | SMALLINT UNSIGNED | If present minutes < threshold → half-day | Attendance | If `working_hours_present_min < half_day_threshold_minutes` → `Half Day` |
| `applies_to_days` | JSON | E.g. `["Mon","Tue",...]`; NULL = all | Calendar | — |
| `is_default` | TINYINT(1) | 1 = default for new employees | Onboarding | — |
| `description` | VARCHAR(255) | Notes | UI | — |
| `is_active`, `created_by`, audit | — | See Appendix A | — | — |

---

## 7.2 `sch_employee_shift_assignments`

Employee × Shift × effective range. UNIQUE `(employee_id, active_flag)` ensures only one active shift per employee at a time.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `employee_id` | INT UNSIGNED FK | Owner | — | — |
| `shift_id` | INT UNSIGNED FK | FK → `sch_employee_shifts.id` | Assigned shift | — |
| `effective_from` | DATE NOT NULL | Start | Timeline | — |
| `effective_to` | DATE | End; NULL = current | Timeline | — |
| `assignment_reason` | VARCHAR(255) | Why this shift | Audit | — |
| `is_active` | TINYINT(1) | Active flag | Combined with `active_flag` | — |
| `active_flag` | TINYINT(1) GENERATED | Auto: 1 when active and not deleted, else NULL | Enforces UNIQUE one-active-shift-per-employee | `CASE WHEN is_active=1 AND deleted_at IS NULL THEN 1 ELSE NULL END` * |
| `created_by`, audit | — | See Appendix A | — | — |

---

# SECTION 8 — ATTENDANCE

## 8.1 `sch_employee_attendance`

Daily attendance summary — ONE ROW per (employee, date). Aggregated final state. Raw punches live in `sch_employee_attendance_punches`.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `employee_id` | INT UNSIGNED FK | Owner | UNIQUE with `date` | — |
| `date` | DATE NOT NULL | Calendar day | Calendar / reports | — |
| `shift_id` | INT UNSIGNED FK | Applicable shift | Working-hours base | — |
| `check_in_time` | TIME | First punch-in of the day | Display | `MIN(punch_at WHERE punch_type='In')::time` |
| `check_out_time` | TIME | Last punch-out of the day | Display | `MAX(punch_at WHERE punch_type='Out')::time` |
| `total_punches` | SMALLINT UNSIGNED | Punch count | QC | `COUNT(punches WHERE !is_invalid)` |
| `attendance_source` | ENUM | `Biometric`/`MobileApp`/`Manual`/`SmartCard`/`QRCode`/`RFID`/`WebCheckIn`/`Other` | Source-of-record audit | — |
| `device_id` | VARCHAR(100) | Terminal ID for first/last punch | Forensics | — |
| `check_in_lat`, `check_in_lng`, `check_out_lat`, `check_out_lng` | DECIMAL(10,7) | Geo for first/last punch | Geo-fence audit | — |
| `working_hours` | DECIMAL(5,2) | Net hours present | Payroll | `working_hours = (check_out_time − check_in_time)/hour − break_minutes/60` |
| `late_minutes` | SMALLINT | Minutes late beyond grace | Reporting | `late_minutes = MAX(0, check_in_minutes − shift.start_minutes − shift.grace_minutes_late)` |
| `early_minutes` | SMALLINT | Minutes left early beyond grace | Reporting | `early_minutes = MAX(0, shift.end_minutes − check_out_minutes − shift.grace_minutes_early)` |
| `is_overtime` | TINYINT(1) | OT eligibility flag | Payroll OT | If `working_hours > sch_employees_profile.work_hours_daily` |
| `overtime_hours` | DECIMAL(4,2) | OT hours | Payroll OT | `overtime_hours = MAX(0, working_hours − work_hours_daily)` |
| `is_holiday` | TINYINT(1) | Denormalised from `sch_holidays` | Payroll | — |
| `is_weekend` | TINYINT(1) | Calendar weekend | Payroll | — |
| `status` | ENUM | `Present`/`Absent`/`On Leave`/`Half Day`/`Late`/`Holiday`/`Weekend`/`On_Tour`/`Work_From_Home` | Final state | Computed from punches + leave + holiday rules |
| `leave_application_id` | INT UNSIGNED FK | FK → application (if `On Leave`) | Cross-link | — |
| `remarks` | VARCHAR(255) | Free-form note | UI | — |
| `marked_by` | INT UNSIGNED FK | Who marked manually | Audit | — |
| `marked_at` | TIMESTAMP | When marked | Audit | — |
| `auto_marked` | TINYINT(1) | 1 = system; 0 = manual | Audit | — |
| `is_active`, `created_by`, audit | — | See Appendix A | — | — |

**Day-close formula (executed by nightly attendance engine):**

```
LET shift   = lookup_shift(employee_id, date)
LET punches = sch_employee_attendance_punches WHERE employee_id, DATE(punch_at)=date AND !is_invalid
IF holiday(date)               THEN status = 'Holiday'
ELIF weekend(date)             THEN status = 'Weekend'
ELIF approved_leave_on(date)   THEN status = 'On Leave'
ELIF |punches| = 0             THEN status = 'Absent'
ELSE
    check_in_time  = MIN(punches.punch_at)
    check_out_time = MAX(punches.punch_at)
    working_hours  = (check_out_time − check_in_time) − break
    late_minutes   = MAX(0, check_in − (shift.start + shift.grace_late))
    early_minutes  = MAX(0, (shift.end − shift.grace_early) − check_out)
    IF working_hours_minutes < shift.half_day_threshold_minutes THEN status = 'Half Day'
    ELIF late_minutes > 0                                       THEN status = 'Late'
    ELSE                                                        status = 'Present'
overtime_hours = MAX(0, working_hours − employee.work_hours_daily)
```

---

## 8.2 `sch_employee_attendance_punches`

Raw punch log — one row per swipe / mobile check-in / kiosk scan.

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `employee_id` | INT UNSIGNED FK | Owner | — | — |
| `attendance_id` | INT UNSIGNED FK | Set after aggregation into daily summary | Links raw to summary | — |
| `punch_at` | DATETIME NOT NULL | Punch timestamp | Aggregation | — |
| `punch_type` | ENUM | `In`/`Out`/`Break_Out`/`Break_In`/`Tour_Out`/`Tour_In`/`Unknown` | Aggregator logic | — |
| `attendance_source` | ENUM | Source of punch | Audit | — |
| `device_id` | VARCHAR(100) | Terminal ID | Forensics | — |
| `device_location` | VARCHAR(150) | Terminal physical location | Forensics | — |
| `latitude`, `longitude` | DECIMAL(10,7) | Geo (mobile/web check-in) | Geo-fence | — |
| `ip_address` | VARCHAR(45) | IPv4/v6 | Forensics | — |
| `user_agent` | VARCHAR(255) | Browser/app UA | Forensics | — |
| `is_within_geofence` | TINYINT(1) | NULL if no geofence configured | Anti-fraud | Compare `(lat, lng)` against tenant geo-fence polygon |
| `is_processed` | TINYINT(1) | 1 = aggregated into attendance row | Aggregator gate | — |
| `is_invalid` | TINYINT(1) | 1 = duplicate / out-of-shift / spam | Aggregator skip | — |
| `invalidation_reason` | VARCHAR(255) | Why invalidated | Audit | — |
| `raw_payload` | JSON | Full vendor payload | Forensic | — |
| `created_at` | TIMESTAMP | Insert time | Reporting | — |

> **Note:** This table intentionally has only `created_at` (no `updated_at`/`deleted_at`/`is_active`) — punches are append-only and immutable.

---

## 8.3 `sch_employee_attendance_corrections`

Manual correction request workflow (employee files, manager approves).

| Column | Type | Use | Usability | Formula |
|--------|------|-----|-----------|---------|
| `id` | INT UNSIGNED PK | Surrogate PK | — | — |
| `attendance_id` | INT UNSIGNED FK | FK → daily attendance row | Target | — |
| `employee_id` | INT UNSIGNED FK | Applicant | — | — |
| `correction_type` | ENUM | `Forgot_Punch_In`/`Forgot_Punch_Out`/`Wrong_Status`/`On_Tour`/`Work_From_Home`/`Time_Adjustment`/`Other` | Drives validation | — |
| `requested_check_in` | TIME | Requested check-in | Apply on approval | — |
| `requested_check_out` | TIME | Requested check-out | Apply on approval | — |
| `requested_status` | ENUM | Requested final status | Apply on approval | — |
| `reason` | TEXT NOT NULL | Justification | Approval UI | — |
| `supporting_doc_media_id` | INT UNSIGNED FK | Optional supporting doc | Approval UI | — |
| `status` | ENUM | `Pending`/`Approved`/`Rejected`/`Cancelled` | Workflow | — |
| `reviewed_by` | INT UNSIGNED FK | Reviewer | Audit | — |
| `reviewed_at` | TIMESTAMP | Review time | Audit | — |
| `review_remarks` | VARCHAR(500) | Reviewer notes | Audit | — |
| `applied_at` | TIMESTAMP | When the correction was actually written back to the daily row | Reconciliation | — |
| `is_active`, `created_by`, audit | — | See Appendix A | — | — |

**On approval:** the engine writes back `requested_check_in`, `requested_check_out`, and `requested_status` into the linked `sch_employee_attendance` row, recomputes `working_hours` / `late_minutes` / `early_minutes` / `overtime_hours`, and stamps `applied_at = now()`.

---

# Appendix A — Common Audit Columns

These columns appear on most tables. They are documented once here.

| Column | Type | Use | Usability |
|--------|------|-----|-----------|
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | Soft-active flag. 1 = active, 0 = inactive | UI shows active rows only; reports may include inactive when `?include_inactive=true`. Combined with `deleted_at` to drive `active_flag` STORED columns where present. |
| `created_by` | INT UNSIGNED NULL | FK → `sys_users.id` of the row's creator | Audit trail; "Created by ..." footer in UI |
| `updated_by` | INT UNSIGNED NULL (only on `sch_employee_leave_balance`) | FK → `sys_users.id` of the last updater | Audit |
| `created_at` | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | Row creation time | Audit; sort-by-recent in lists |
| `updated_at` | TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | Last update time | Audit; "Last modified ..." footer; cache invalidation hints |
| `deleted_at` | TIMESTAMP NULL | Soft-delete timestamp | NULL = not deleted; non-NULL = soft-deleted; combined with `is_active` in `active_flag` STORED columns to power UNIQUE-when-active constraints |

# Appendix B — Generated `active_flag` Pattern

Used on `sch_employees_profile`, `sch_teacher_capabilities`, `sch_employee_shift_assignments`.

```sql
`active_flag` TINYINT(1) GENERATED ALWAYS AS (
  CASE WHEN (`is_active` = 1 AND `deleted_at` IS NULL) THEN 1 ELSE NULL END
) STORED
```

**Why:** MySQL's UNIQUE constraint treats NULLs as "not equal", so `UNIQUE (employee_id, role_id, active_flag)` permits unlimited soft-deleted/inactive rows but only ONE row where `active_flag = 1`. This is how the schema enforces "only one active row per (employee, role)" without triggers.

# Appendix C — Cross-Table Calculation Reference

| Computation | Inputs | Formula | Where executed |
|-------------|--------|---------|----------------|
| Daily salary line | `sch_staff_attendance_types.payroll_percentage`, base salary | `daily_amount = base_daily × payroll_percentage / 100` | Payroll engine |
| Leave-days requested | `from_date`, `to_date`, `is_half_day`, `sch_holidays`, weekend rule | `total_days = working_days(from,to) − holidays_in_range; halve if is_half_day` | Apply-leave service |
| Leave available balance | balance row | `available = opening_balance + carry_forward − total_used` (STORED column) | DB |
| Year-end carry forward | balance prior year, config | `cf = MIN(prior_year_remaining, max_carry_forward)` (only when `is_carry_forwardable=1`) | Year-rollover job |
| Encashment at separation | balance, config | `encash_days = MIN(balance, max_encashable_days)` if `is_encashable_at_separation=1` | F&F service |
| Working hours per shift | shift master | `working_hours = (end − start) − break_minutes/60` | Stored on `sch_employee_shifts` |
| Late minutes | shift, check-in | `late = MAX(0, check_in − shift.start − shift.grace_late)` | Day-close engine |
| Half-day decision | shift, presence minutes | If `present_minutes < shift.half_day_threshold_minutes` → `Half Day` | Day-close engine |
| Overtime hours | profile, working hours | `OT = MAX(0, working_hours − sch_employees_profile.work_hours_daily)` | Day-close engine |
| Tenure years | `joining_date` | `tenure_years = (today − joining_date) / 365.25` | Profile view |
| Retirement date | `date_of_birth`, retirement-age config (default 60) | `retirement_date = date_of_birth + retirement_age years` | HR scheduler |
| Notice last-working-date | separation row | `intended_last_working_date = notice_start_date + notice_period_days` | Separation workflow |
| Final settlement (F&F) | balance, salary, dues | `F&F = pending_salary + leave_encash − advances − recoveries + bonus + gratuity` | Payroll F&F service |
| Approval escalation deadline | level config, pending-since | `deadline = pending_since + level.escalation_after_hours` | Workflow scheduler |
| Capability allocation score | capability row | `score = (proficiency × Wp + experience_score × We + priority_weight × Wpw + scarcity_index × Ws + historical_success_ratio × Wh) / sum(weights)` | FET solver |
| Document expiry alert | document row | Alert when `expiry_date − today ≤ 30 days` | Renewal scheduler |

---

> **Source-of-truth note.** This data dictionary tracks `Employee_setup_ddl_v5.sql` as committed on 2026-05-07. If a future v6 / patch changes columns, update this file immediately to keep the dictionary aligned with the schema.
