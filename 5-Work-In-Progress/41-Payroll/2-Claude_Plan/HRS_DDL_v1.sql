-- =============================================================================
-- HRS — HR & Payroll Module DDL
-- Module: HrStaff (Modules\HrStaff)
-- Table Prefixes: hrs_* (23 tables) + pay_* (10 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: 2026-03-26
-- Based on: HRS_HrStaff_Requirement_v2.md
-- =============================================================================
--
-- ⚠️  DDL CORRECTIONS vs Requirement Spec:
--   1. sch_academic_years does NOT exist — use sch_org_academic_sessions_jnt (SMALLINT UNSIGNED id)
--   2. sch_employees.id = INT UNSIGNED — all FK columns referencing it must be INT UNSIGNED
--   3. sch_department / sch_designation are SINGULAR (no trailing 's')
--   4. sch_employees_profile (with 's' on employees, not employee)
--   5. att_staff_attendances does NOT exist yet (Attendance module pending)
--
-- sch_* tables are NOT created here — they already exist in tenant_db.
-- No acc_* FK references — Accounting integration is event-driven only.
-- No tenant_id columns — stancl/tenancy v3.9 uses separate DB per tenant.
-- Cross-prefix FK: hrs_salary_assignments.pay_salary_structure_id → pay_salary_structures.id
-- Cross-prefix FK: pay_payroll_run_details.salary_assignment_id → hrs_salary_assignments.id
-- =============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- =============================================================================
-- LAYER 1 — No dependencies on other hrs_*/pay_* tables (7 tables)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. hrs_kpi_templates
--    KPI template definitions. Each template has weighted items.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_kpi_templates` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`         VARCHAR(200)    NOT NULL                  COMMENT 'Template name e.g. Teaching KPI 2025-26',
  `applicable_to` ENUM('All','Teaching','Non-Teaching') NOT NULL DEFAULT 'All' COMMENT 'Staff category this template applies to',
  `rating_scale` TINYINT UNSIGNED NOT NULL DEFAULT 5       COMMENT '5-point or 10-point rating scale',
  `is_active`    TINYINT(1)      NOT NULL DEFAULT 1         COMMENT 'Soft enable/disable',
  `created_by`   BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`   BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`   TIMESTAMP       NULL,
  `updated_at`   TIMESTAMP       NULL,
  `deleted_at`   TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 2. hrs_leave_types
--    Configurable leave types per school. Pre-seeded with 7 defaults.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_leave_types` (
  `id`                       BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `code`                     VARCHAR(10)      NOT NULL                  COMMENT 'Short code: CL, EL, SL, ML, PL, CO, LWP',
  `name`                     VARCHAR(100)     NOT NULL                  COMMENT 'e.g. Casual Leave, Earned Leave',
  `days_per_year`            DECIMAL(5,1)     NOT NULL DEFAULT 0        COMMENT '0 for LWP and CO (granted ad-hoc)',
  `carry_forward_days`       TINYINT UNSIGNED NOT NULL DEFAULT 0        COMMENT '0 = no carry-forward; max days to carry to next year',
  `applicable_to`            ENUM('all','teaching','non_teaching') NOT NULL DEFAULT 'all' COMMENT 'Which staff category can apply for this leave',
  `is_paid`                  TINYINT(1)       NOT NULL DEFAULT 1        COMMENT '0 = unpaid leave (LWP)',
  `requires_medical_cert`    TINYINT(1)       NOT NULL DEFAULT 0        COMMENT '1 = medical certificate required (SL)',
  `medical_cert_threshold_days` TINYINT UNSIGNED NOT NULL DEFAULT 3    COMMENT 'SL: certificate required if absence > this many days',
  `half_day_allowed`         TINYINT(1)       NOT NULL DEFAULT 0        COMMENT '1 = half-day application supported',
  `gender_restriction`       ENUM('all','male','female') NOT NULL DEFAULT 'all' COMMENT 'all = any gender; female = Maternity Leave; male = Paternity Leave',
  `min_service_months`       TINYINT UNSIGNED NOT NULL DEFAULT 0        COMMENT 'EL typically requires 6 months service before eligibility',
  `max_consecutive_days`     TINYINT UNSIGNED NULL     DEFAULT NULL     COMMENT 'NULL = no consecutive-day limit',
  `is_active`                TINYINT(1)       NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`               BIGINT UNSIGNED  NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`               BIGINT UNSIGNED  NOT NULL                  COMMENT 'sys_users.id',
  `created_at`               TIMESTAMP        NULL,
  `updated_at`               TIMESTAMP        NULL,
  `deleted_at`               TIMESTAMP        NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hrs_leave_type_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 3. hrs_id_card_templates
--    School-configurable ID card layout. One default template per school.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_id_card_templates` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(150)    NOT NULL                  COMMENT 'Template name',
  `layout_json` JSON            NOT NULL                  COMMENT 'Fields list, dimensions, color scheme, logo position: {fields, dimensions, color_scheme}',
  `is_default`  TINYINT(1)      NOT NULL DEFAULT 0        COMMENT '1 = default template; only one allowed (enforced in IdCardService)',
  `is_active`   TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`  BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`  BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`  TIMESTAMP       NULL,
  `updated_at`  TIMESTAMP       NULL,
  `deleted_at`  TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 4. hrs_pay_grades
--    Salary grade bands. Used to validate CTC during salary assignment.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_pay_grades` (
  `id`                       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `grade_name`               VARCHAR(100)    NOT NULL                  COMMENT 'e.g. Grade A, Senior Teacher, Support Staff',
  `min_ctc`                  DECIMAL(12,2)   NOT NULL                  COMMENT 'Minimum annual CTC for this grade',
  `max_ctc`                  DECIMAL(12,2)   NOT NULL                  COMMENT 'Maximum annual CTC for this grade',
  `applicable_designation_ids` JSON          NULL     DEFAULT NULL     COMMENT 'Array of sch_designation.id values; NULL = applicable to all designations',
  `is_active`                TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`               BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`               BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`               TIMESTAMP       NULL,
  `updated_at`               TIMESTAMP       NULL,
  `deleted_at`               TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 5. hrs_pt_slabs
--    State-wise Profession Tax slabs. Seeded for HP, KA, MH.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_pt_slabs` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `state_code`  VARCHAR(5)      NOT NULL                  COMMENT 'ISO state code: HP (Himachal Pradesh), KA (Karnataka), MH (Maharashtra), etc.',
  `min_salary`  DECIMAL(10,2)   NOT NULL                  COMMENT 'Slab lower bound — monthly gross (inclusive)',
  `max_salary`  DECIMAL(10,2)   NOT NULL                  COMMENT 'Slab upper bound — use 999999999.00 for open-ended top slab',
  `pt_amount`   DECIMAL(8,2)    NOT NULL                  COMMENT 'Monthly Profession Tax amount for this slab in INR',
  `is_active`   TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`  BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`  BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`  TIMESTAMP       NULL,
  `updated_at`  TIMESTAMP       NULL,
  `deleted_at`  TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_hrs_pt_state` (`state_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 6. pay_salary_components
--    Salary component master (earnings, deductions, employer contributions).
--    Seeded with 14 standard components.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `pay_salary_components` (
  `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`             VARCHAR(150)    NOT NULL                  COMMENT 'Component name e.g. Basic Pay, PF Employee',
  `code`             VARCHAR(30)     NOT NULL                  COMMENT 'Unique code: BASIC, DA, HRA, CONV, MEDICAL, LTA, SPECIAL, PF_EMP, ESI_EMP, PT, TDS, LWP_DED, PF_ERR, ESI_ERR',
  `component_type`   ENUM('earning','deduction','employer_contribution') NOT NULL COMMENT 'earning = adds to gross; deduction = subtracted; employer_contribution = CTC only',
  `calculation_type` ENUM('fixed','percentage_of_basic','percentage_of_gross','statutory','manual') NOT NULL COMMENT 'How the component value is computed',
  `default_value`    DECIMAL(10,4)   NOT NULL DEFAULT 0.0000  COMMENT 'Fixed amount (INR) or percentage value. HRA = 25.0000 (25%)',
  `is_taxable`       TINYINT(1)      NOT NULL DEFAULT 1        COMMENT '1 = included in projected annual income for TDS computation',
  `is_statutory`     TINYINT(1)      NOT NULL DEFAULT 0        COMMENT '1 for PF/ESI/PT/TDS components governed by statute',
  `display_order`    TINYINT UNSIGNED NOT NULL DEFAULT 99      COMMENT 'Display order on payslip; earnings first then deductions',
  `is_active`        TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`       BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`       BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`       TIMESTAMP       NULL,
  `updated_at`       TIMESTAMP       NULL,
  `deleted_at`       TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pay_comp_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 7. pay_salary_structures
--    Salary structure templates. Components linked via pay_salary_structure_components.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `pay_salary_structures` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`          VARCHAR(200)    NOT NULL                  COMMENT 'Structure name e.g. Teaching Staff Structure',
  `description`   TEXT            NULL                      COMMENT 'Optional description of this structure',
  `applicable_to` ENUM('all','teaching','non_teaching','contractual') NOT NULL DEFAULT 'all' COMMENT 'Staff category this structure applies to',
  `is_active`     TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable; inactive structures cannot be newly assigned',
  `created_by`    BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`    BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`    TIMESTAMP       NULL,
  `updated_at`    TIMESTAMP       NULL,
  `deleted_at`    TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- LAYER 2 — Depends on Layer 1 (2 tables)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 8. hrs_kpi_template_items
--    Individual KPI items within a template. Weights must sum to 100.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_kpi_template_items` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `template_id` BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → hrs_kpi_templates.id',
  `kpi_name`    VARCHAR(200)    NOT NULL                  COMMENT 'KPI item name e.g. Student Performance, Punctuality',
  `category`    ENUM('academic','behavioral','administrative') NOT NULL COMMENT 'KPI category for grouping on appraisal form',
  `weight`      DECIMAL(5,2)    NOT NULL                  COMMENT '% weight; all items in a template must sum to 100 (enforced in AppraisalService)',
  `description` TEXT            NULL                      COMMENT 'Optional explanation of this KPI criteria',
  `is_active`   TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`  BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`  BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`  TIMESTAMP       NULL,
  `updated_at`  TIMESTAMP       NULL,
  `deleted_at`  TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `fk_hrs_kpiitem_tmplid` (`template_id`),
  CONSTRAINT `fk_hrs_kpiitem_tmplid` FOREIGN KEY (`template_id`) REFERENCES `hrs_kpi_templates` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 9. pay_salary_structure_components
--    Junction: which components are in which structure, with formula overrides.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `pay_salary_structure_components` (
  `id`                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `structure_id`         BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → pay_salary_structures.id',
  `component_id`         BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → pay_salary_components.id',
  `sequence_order`       TINYINT UNSIGNED NOT NULL DEFAULT 99      COMMENT 'Display and computation order within this structure',
  `calculation_formula`  TEXT            NULL                      COMMENT 'Override formula if different from component default_value',
  `is_mandatory`         TINYINT(1)      NOT NULL DEFAULT 0        COMMENT '1 = cannot be removed from this structure',
  `is_active`            TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`           BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`           BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`           TIMESTAMP       NULL,
  `updated_at`           TIMESTAMP       NULL,
  `deleted_at`           TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pay_struct_comp` (`structure_id`, `component_id`),
  KEY `fk_pay_structcomp_structid` (`structure_id`),
  KEY `fk_pay_structcomp_compid` (`component_id`),
  CONSTRAINT `fk_pay_structcomp_structid` FOREIGN KEY (`structure_id`) REFERENCES `pay_salary_structures` (`id`),
  CONSTRAINT `fk_pay_structcomp_compid` FOREIGN KEY (`component_id`) REFERENCES `pay_salary_components` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- LAYER 3 — Depends on sch_* tables only (7 tables)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 10. hrs_employment_details
--     One HR record extension per employee (1:1 with sch_employees).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_employment_details` (
  `id`                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id`             INT UNSIGNED    NOT NULL                  COMMENT 'FK → sch_employees.id (INT UNSIGNED); one-to-one with sch_employees',
  `contract_type`           ENUM('permanent','contractual','probation','part_time','substitute') NOT NULL COMMENT 'Employment contract type',
  `probation_end_date`      DATE            NULL     DEFAULT NULL     COMMENT 'Probation end date; relevant when contract_type=probation',
  `confirmation_date`       DATE            NULL     DEFAULT NULL     COMMENT 'Date employment was confirmed',
  `notice_period_days`      TINYINT UNSIGNED NOT NULL DEFAULT 30      COMMENT 'Notice period in days per contract',
  `bank_account_number`     TEXT            NULL     DEFAULT NULL     COMMENT 'Laravel encrypt() — variable-length encrypted value; NEVER store in plaintext (BR-HRS-015)',
  `bank_ifsc`               VARCHAR(11)     NULL     DEFAULT NULL     COMMENT 'Bank IFSC code (11 characters)',
  `bank_name`               VARCHAR(100)    NULL     DEFAULT NULL     COMMENT 'Bank name',
  `bank_branch`             VARCHAR(100)    NULL     DEFAULT NULL     COMMENT 'Bank branch name',
  `emergency_contact_json`  JSON            NULL     DEFAULT NULL     COMMENT 'Emergency contact: {name, relationship, phone, address}',
  `previous_employer_json`  JSON            NULL     DEFAULT NULL     COMMENT 'Previous employers: [{company, role, from_date, to_date}]',
  `is_active`               TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`              BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`              BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`              TIMESTAMP       NULL,
  `updated_at`              TIMESTAMP       NULL,
  `deleted_at`              TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hrs_emp_details_emp` (`employee_id`),
  KEY `fk_hrs_empdet_empid` (`employee_id`),
  CONSTRAINT `fk_hrs_empdet_empid` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 11. hrs_employment_history
--     Immutable audit trail of employment status changes.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_employment_history` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id`    INT UNSIGNED    NOT NULL                  COMMENT 'FK → sch_employees.id; employee this change belongs to',
  `change_type`    VARCHAR(50)     NOT NULL                  COMMENT 'Change category: contract_type, department, designation, pay_grade, salary_revision',
  `old_value`      JSON            NOT NULL                  COMMENT 'Previous value(s) as JSON object',
  `new_value`      JSON            NOT NULL                  COMMENT 'New value(s) as JSON object',
  `effective_date` DATE            NOT NULL                  COMMENT 'Date when the change took effect',
  `changed_by`     INT UNSIGNED    NOT NULL                  COMMENT 'FK → sch_employees.id; who made the change',
  `remarks`        TEXT            NULL     DEFAULT NULL     COMMENT 'Optional explanation for the change',
  `is_active`      TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`     BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`     BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`     TIMESTAMP       NULL,
  `updated_at`     TIMESTAMP       NULL,
  `deleted_at`     TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `fk_hrs_emphist_empid` (`employee_id`),
  KEY `fk_hrs_emphist_changedby` (`changed_by`),
  CONSTRAINT `fk_hrs_emphist_empid` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`),
  CONSTRAINT `fk_hrs_emphist_changedby` FOREIGN KEY (`changed_by`) REFERENCES `sch_employees` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 12. hrs_employee_documents
--     Employee document repository. Files stored in sys_media.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_employee_documents` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id`    INT UNSIGNED    NOT NULL                  COMMENT 'FK → sch_employees.id',
  `document_type`  VARCHAR(50)     NOT NULL                  COMMENT 'appointment_letter, increment_letter, transfer_letter, warning_letter, experience_certificate, id_proof, educational_certificate, medical_certificate, other',
  `document_name`  VARCHAR(200)    NOT NULL                  COMMENT 'Human-readable document label',
  `media_id`       BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → sys_media.id; actual file reference',
  `issued_date`    DATE            NULL     DEFAULT NULL     COMMENT 'Document issue date',
  `expiry_date`    DATE            NULL     DEFAULT NULL     COMMENT 'DocumentExpiringSoon event dispatched 30 days before expiry',
  `issued_by`      VARCHAR(150)    NULL     DEFAULT NULL     COMMENT 'Issuing institution or person name',
  `remarks`        TEXT            NULL     DEFAULT NULL     COMMENT 'Optional remarks',
  `is_active`      TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`     BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`     BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`     TIMESTAMP       NULL,
  `updated_at`     TIMESTAMP       NULL,
  `deleted_at`     TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `fk_hrs_empdoc_empid` (`employee_id`),
  KEY `fk_hrs_empdoc_mediaid` (`media_id`),
  KEY `idx_hrs_empdoc_expiry` (`expiry_date`),
  CONSTRAINT `fk_hrs_empdoc_empid` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`),
  CONSTRAINT `fk_hrs_empdoc_mediaid` FOREIGN KEY (`media_id`) REFERENCES `sys_media` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 13. hrs_leave_policies
--     School-wide leave policy configuration. NULL academic_year_id = global default.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_leave_policies` (
  `id`                     BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `academic_year_id`       SMALLINT UNSIGNED NULL    DEFAULT NULL     COMMENT 'FK → sch_org_academic_sessions_jnt.id; NULL = global default policy for all years',
  `max_backdated_days`     TINYINT UNSIGNED NOT NULL DEFAULT 3        COMMENT 'Max days in past for backdated application',
  `min_advance_days`       TINYINT UNSIGNED NOT NULL DEFAULT 0        COMMENT 'Minimum advance days required before leave start date',
  `approval_levels`        TINYINT UNSIGNED NOT NULL DEFAULT 2        COMMENT '1 = HOD only; 2 = HOD + Principal',
  `optional_holiday_count` TINYINT UNSIGNED NOT NULL DEFAULT 2        COMMENT 'Optional holidays an employee can elect per year',
  `is_active`              TINYINT(1)       NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`             BIGINT UNSIGNED  NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`             BIGINT UNSIGNED  NOT NULL                  COMMENT 'sys_users.id',
  `created_at`             TIMESTAMP        NULL,
  `updated_at`             TIMESTAMP        NULL,
  `deleted_at`             TIMESTAMP        NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `fk_hrs_lvpol_ayid` (`academic_year_id`),
  CONSTRAINT `fk_hrs_lvpol_ayid` FOREIGN KEY (`academic_year_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 14. hrs_holiday_calendars
--     School holiday calendar per academic year.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_holiday_calendars` (
  `id`               BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `academic_year_id` SMALLINT UNSIGNED NOT NULL                 COMMENT 'FK → sch_org_academic_sessions_jnt.id',
  `holiday_date`     DATE             NOT NULL                  COMMENT 'Date of the holiday',
  `holiday_name`     VARCHAR(150)     NOT NULL                  COMMENT 'e.g. Independence Day, Diwali',
  `holiday_type`     ENUM('national','state','school','optional') NOT NULL COMMENT 'Type of holiday',
  `applicable_to`    ENUM('all','teaching','non_teaching') NOT NULL DEFAULT 'all' COMMENT 'Staff category this holiday applies to',
  `is_active`        TINYINT(1)       NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`       BIGINT UNSIGNED  NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`       BIGINT UNSIGNED  NOT NULL                  COMMENT 'sys_users.id',
  `created_at`       TIMESTAMP        NULL,
  `updated_at`       TIMESTAMP        NULL,
  `deleted_at`       TIMESTAMP        NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `fk_hrs_holiday_ayid` (`academic_year_id`),
  KEY `idx_hrs_holiday_date` (`holiday_date`),
  CONSTRAINT `fk_hrs_holiday_ayid` FOREIGN KEY (`academic_year_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 15. hrs_compliance_records
--     Statutory compliance record per employee per type (PF, ESI, TDS, Gratuity, PT).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_compliance_records` (
  `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id`      INT UNSIGNED    NOT NULL                  COMMENT 'FK → sch_employees.id',
  `compliance_type`  ENUM('pf','esi','tds','gratuity','pt') NOT NULL COMMENT 'Statutory compliance type',
  `reference_number` VARCHAR(100)    NULL     DEFAULT NULL     COMMENT 'UAN (PF), IP number (ESI), encrypted PAN (TDS) — VARCHAR(100) for variable encrypted length',
  `enrollment_date`  DATE            NULL     DEFAULT NULL     COMMENT 'Date enrolled in this statutory scheme',
  `applicable_flag`  TINYINT(1)      NOT NULL DEFAULT 1        COMMENT '1 = this compliance type applies to this employee',
  `nominee_json`     JSON            NULL     DEFAULT NULL     COMMENT 'PF/Gratuity nominee: [{name, relationship, share_pct}]',
  `details_json`     JSON            NULL     DEFAULT NULL     COMMENT 'Type-specific extras: TDS→{regime,80C,HRA,LTA}; PT→{state_code}; ESI→{dispensary}',
  `is_active`        TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`       BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`       BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`       TIMESTAMP       NULL,
  `updated_at`       TIMESTAMP       NULL,
  `deleted_at`       TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hrs_compliance` (`employee_id`, `compliance_type`),
  KEY `fk_hrs_compl_empid` (`employee_id`),
  KEY `idx_hrs_compl_type` (`compliance_type`),
  CONSTRAINT `fk_hrs_compl_empid` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 16. hrs_lop_records
--     LOP (Loss of Pay) flags generated by reconciliation against attendance.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_lop_records` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id`   INT UNSIGNED    NOT NULL                  COMMENT 'FK → sch_employees.id',
  `absent_date`   DATE            NOT NULL                  COMMENT 'Date employee was absent without approved leave',
  `flag_status`   ENUM('flagged','confirmed','waived') NOT NULL DEFAULT 'flagged' COMMENT 'flagged=initial; confirmed=included in payroll computation; waived=HR waived',
  `confirmed_by`  INT UNSIGNED    NULL     DEFAULT NULL     COMMENT 'FK → sch_employees.id; HR Manager who confirmed this LOP',
  `confirmed_at`  TIMESTAMP       NULL     DEFAULT NULL     COMMENT 'Timestamp when LOP was confirmed',
  `payroll_month` VARCHAR(7)      NULL     DEFAULT NULL     COMMENT 'YYYY-MM; set when consumed by payroll computation',
  `is_active`     TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`    BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`    BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`    TIMESTAMP       NULL,
  `updated_at`    TIMESTAMP       NULL,
  `deleted_at`    TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hrs_lop` (`employee_id`, `absent_date`),
  KEY `fk_hrs_lop_empid` (`employee_id`),
  KEY `fk_hrs_lop_confirmedby` (`confirmed_by`),
  KEY `idx_hrs_lop_month` (`payroll_month`),
  KEY `idx_hrs_lop_status` (`flag_status`),
  CONSTRAINT `fk_hrs_lop_empid` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`),
  CONSTRAINT `fk_hrs_lop_confirmedby` FOREIGN KEY (`confirmed_by`) REFERENCES `sch_employees` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- LAYER 4 — Depends on Layer 1 + sch_* (5 tables)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 17. hrs_salary_assignments
--     Links employee to salary structure with CTC. New row per revision.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_salary_assignments` (
  `id`                       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id`              INT UNSIGNED    NOT NULL                  COMMENT 'FK → sch_employees.id',
  `pay_salary_structure_id`  BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → pay_salary_structures.id (intentional cross-prefix FK within same module)',
  `pay_grade_id`             BIGINT UNSIGNED NULL     DEFAULT NULL     COMMENT 'FK → hrs_pay_grades.id; optional grade band',
  `ctc_amount`               DECIMAL(12,2)   NOT NULL                  COMMENT 'Annual CTC in INR; must fall within pay_grade min/max (BR-HRS-011)',
  `gross_monthly`            DECIMAL(12,2)   NOT NULL                  COMMENT 'Monthly gross = CTC/12 minus employer PF and ESI contributions',
  `effective_from_date`      DATE            NOT NULL                  COMMENT 'Assignment effective from this date',
  `effective_to_date`        DATE            NULL     DEFAULT NULL     COMMENT 'NULL = currently active; set when a new revision is created',
  `revision_reason`          VARCHAR(200)    NULL     DEFAULT NULL     COMMENT 'Reason for this assignment or revision',
  `is_active`                TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`               BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`               BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`               TIMESTAMP       NULL,
  `updated_at`               TIMESTAMP       NULL,
  `deleted_at`               TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `fk_hrs_salassgn_empid` (`employee_id`),
  KEY `fk_hrs_salassgn_structid` (`pay_salary_structure_id`),
  KEY `fk_hrs_salassgn_gradeid` (`pay_grade_id`),
  KEY `idx_hrs_salassgn_effective` (`effective_from_date`, `effective_to_date`),
  CONSTRAINT `fk_hrs_salassgn_empid` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`),
  CONSTRAINT `fk_hrs_salassgn_structid` FOREIGN KEY (`pay_salary_structure_id`) REFERENCES `pay_salary_structures` (`id`),
  CONSTRAINT `fk_hrs_salassgn_gradeid` FOREIGN KEY (`pay_grade_id`) REFERENCES `hrs_pay_grades` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 18. hrs_appraisal_cycles
--     Appraisal cycle configuration per academic year.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_appraisal_cycles` (
  `id`                      BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `name`                    VARCHAR(200)     NOT NULL                  COMMENT 'e.g. 2025-26 Annual Appraisal',
  `academic_year_id`        SMALLINT UNSIGNED NOT NULL                 COMMENT 'FK → sch_org_academic_sessions_jnt.id',
  `appraisal_type`          ENUM('annual','mid_year','probation','confirmation') NOT NULL COMMENT 'Type of appraisal cycle',
  `kpi_template_id`         BIGINT UNSIGNED  NOT NULL                  COMMENT 'FK → hrs_kpi_templates.id',
  `self_open_date`          DATE             NOT NULL                  COMMENT 'Date from which employees can begin self-appraisal',
  `self_close_date`         DATE             NOT NULL                  COMMENT 'Deadline for self-appraisal submission',
  `manager_open_date`       DATE             NOT NULL                  COMMENT 'Date from which managers can begin review; must be >= self_close_date (BR-HRS-018)',
  `manager_close_date`      DATE             NOT NULL                  COMMENT 'Deadline for manager review submission',
  `applicable_departments`  JSON             NULL     DEFAULT NULL     COMMENT 'Array of sch_department.id values; NULL = all departments',
  `reviewer_mode`           ENUM('auto','manual') NOT NULL DEFAULT 'auto' COMMENT 'auto = reporting_to from sch_employees_profile; manual = HR assigns reviewer',
  `status`                  ENUM('draft','active','closed') NOT NULL DEFAULT 'draft' COMMENT 'Cycle lifecycle FSM status',
  `is_active`               TINYINT(1)       NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`              BIGINT UNSIGNED  NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`              BIGINT UNSIGNED  NOT NULL                  COMMENT 'sys_users.id',
  `created_at`              TIMESTAMP        NULL,
  `updated_at`              TIMESTAMP        NULL,
  `deleted_at`              TIMESTAMP        NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `fk_hrs_aprcyc_ayid` (`academic_year_id`),
  KEY `fk_hrs_aprcyc_tmplid` (`kpi_template_id`),
  CONSTRAINT `fk_hrs_aprcyc_ayid` FOREIGN KEY (`academic_year_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`),
  CONSTRAINT `fk_hrs_aprcyc_tmplid` FOREIGN KEY (`kpi_template_id`) REFERENCES `hrs_kpi_templates` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 19. hrs_leave_balances
--     Per-employee per-leave-type per-academic-year balance tracking.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_leave_balances` (
  `id`                 BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `employee_id`        INT UNSIGNED     NOT NULL                  COMMENT 'FK → sch_employees.id',
  `leave_type_id`      BIGINT UNSIGNED  NOT NULL                  COMMENT 'FK → hrs_leave_types.id',
  `academic_year_id`   SMALLINT UNSIGNED NOT NULL                 COMMENT 'FK → sch_org_academic_sessions_jnt.id',
  `allocated_days`     DECIMAL(5,1)     NOT NULL DEFAULT 0        COMMENT 'Initialized from leave_type.days_per_year at year start',
  `carry_forward_days` DECIMAL(5,1)     NOT NULL DEFAULT 0        COMMENT 'Carried from prior year; capped at leave_type.carry_forward_days',
  `used_days`          DECIMAL(5,1)     NOT NULL DEFAULT 0        COMMENT 'Updated on leave approval and cancellation',
  `lop_days`           DECIMAL(5,1)     NOT NULL DEFAULT 0        COMMENT 'LOP days accrued this academic year',
  `is_active`          TINYINT(1)       NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`         BIGINT UNSIGNED  NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`         BIGINT UNSIGNED  NOT NULL                  COMMENT 'sys_users.id',
  `created_at`         TIMESTAMP        NULL,
  `updated_at`         TIMESTAMP        NULL,
  `deleted_at`         TIMESTAMP        NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hrs_leave_bal` (`employee_id`, `leave_type_id`, `academic_year_id`),
  KEY `fk_hrs_lbal_empid` (`employee_id`),
  KEY `fk_hrs_lbal_ltid` (`leave_type_id`),
  KEY `fk_hrs_lbal_ayid` (`academic_year_id`),
  CONSTRAINT `fk_hrs_lbal_empid` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`),
  CONSTRAINT `fk_hrs_lbal_ltid` FOREIGN KEY (`leave_type_id`) REFERENCES `hrs_leave_types` (`id`),
  CONSTRAINT `fk_hrs_lbal_ayid` FOREIGN KEY (`academic_year_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 20. hrs_leave_applications
--     Employee leave applications with FSM status tracking.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_leave_applications` (
  `id`                    BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `employee_id`           INT UNSIGNED     NOT NULL                  COMMENT 'FK → sch_employees.id; applicant',
  `leave_type_id`         BIGINT UNSIGNED  NOT NULL                  COMMENT 'FK → hrs_leave_types.id',
  `academic_year_id`      SMALLINT UNSIGNED NOT NULL                 COMMENT 'FK → sch_org_academic_sessions_jnt.id',
  `from_date`             DATE             NOT NULL                  COMMENT 'Leave start date',
  `to_date`               DATE             NOT NULL                  COMMENT 'Leave end date',
  `half_day`              TINYINT(1)       NOT NULL DEFAULT 0        COMMENT '1 = half-day application',
  `half_day_session`      ENUM('first','second') NULL DEFAULT NULL  COMMENT 'Half-day session: first or second half; relevant only if half_day=1',
  `days_count`            DECIMAL(5,1)     NOT NULL                  COMMENT 'Computed on save — excludes holidays and weekends via HolidayService',
  `reason`                TEXT             NOT NULL                  COMMENT 'Employee-provided reason for leave',
  `media_id`              BIGINT UNSIGNED  NULL     DEFAULT NULL     COMMENT 'FK → sys_media.id; supporting document (medical certificate, etc.)',
  `status`                ENUM('pending','pending_l2','approved','rejected','cancelled','returned') NOT NULL DEFAULT 'pending' COMMENT 'Leave application FSM status',
  `current_approver_level` TINYINT UNSIGNED NOT NULL DEFAULT 1      COMMENT '1 = awaiting HOD; 2 = awaiting Principal',
  `is_active`             TINYINT(1)       NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`            BIGINT UNSIGNED  NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`            BIGINT UNSIGNED  NOT NULL                  COMMENT 'sys_users.id',
  `created_at`            TIMESTAMP        NULL,
  `updated_at`            TIMESTAMP        NULL,
  `deleted_at`            TIMESTAMP        NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `fk_hrs_lapp_empid` (`employee_id`),
  KEY `fk_hrs_lapp_ltid` (`leave_type_id`),
  KEY `fk_hrs_lapp_ayid` (`academic_year_id`),
  KEY `fk_hrs_lapp_mediaid` (`media_id`),
  KEY `idx_hrs_lapp_status` (`status`),
  CONSTRAINT `fk_hrs_lapp_empid` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`),
  CONSTRAINT `fk_hrs_lapp_ltid` FOREIGN KEY (`leave_type_id`) REFERENCES `hrs_leave_types` (`id`),
  CONSTRAINT `fk_hrs_lapp_ayid` FOREIGN KEY (`academic_year_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`),
  CONSTRAINT `fk_hrs_lapp_mediaid` FOREIGN KEY (`media_id`) REFERENCES `sys_media` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 21. pay_payroll_runs
--     Payroll run header. FSM: draft → computing → computed → reviewing → approved → locked.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `pay_payroll_runs` (
  `id`                BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `payroll_month`     VARCHAR(7)       NOT NULL                  COMMENT 'YYYY-MM format e.g. 2025-12',
  `academic_year_id`  SMALLINT UNSIGNED NOT NULL                 COMMENT 'FK → sch_org_academic_sessions_jnt.id',
  `run_type`          ENUM('regular','supplementary') NOT NULL DEFAULT 'regular' COMMENT 'regular = main monthly run; supplementary = missed employees added later',
  `parent_run_id`     BIGINT UNSIGNED  NULL     DEFAULT NULL     COMMENT 'FK → pay_payroll_runs.id (self-ref); supplementary run links to parent regular run',
  `status`            ENUM('draft','computing','computed','reviewing','approved','locked') NOT NULL DEFAULT 'draft' COMMENT 'Payroll Run FSM; locked = immutable (BR-PAY-003)',
  `initiated_by`      INT UNSIGNED     NOT NULL                  COMMENT 'FK → sch_employees.id; Payroll Manager who initiated the run',
  `approved_by`       INT UNSIGNED     NULL     DEFAULT NULL     COMMENT 'FK → sch_employees.id; Principal who approved',
  `approved_at`       TIMESTAMP        NULL     DEFAULT NULL     COMMENT 'Approval timestamp',
  `locked_at`         TIMESTAMP        NULL     DEFAULT NULL     COMMENT 'Lock timestamp; run is immutable after this point (BR-PAY-003)',
  `total_gross`       DECIMAL(14,2)    NULL     DEFAULT NULL     COMMENT 'Aggregate gross salary — computed and stored on lock',
  `total_net`         DECIMAL(14,2)    NULL     DEFAULT NULL     COMMENT 'Aggregate net pay — computed and stored on lock',
  `employee_count`    SMALLINT UNSIGNED NULL    DEFAULT NULL     COMMENT 'Number of employees included in this run',
  `computation_notes` TEXT             NULL     DEFAULT NULL     COMMENT 'Errors or warnings from payroll computation engine',
  `is_active`         TINYINT(1)       NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`        BIGINT UNSIGNED  NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`        BIGINT UNSIGNED  NOT NULL                  COMMENT 'sys_users.id',
  `created_at`        TIMESTAMP        NULL,
  `updated_at`        TIMESTAMP        NULL,
  `deleted_at`        TIMESTAMP        NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pay_run_month_type` (`payroll_month`, `run_type`),
  KEY `fk_pay_run_ayid` (`academic_year_id`),
  KEY `fk_pay_run_parent` (`parent_run_id`),
  KEY `fk_pay_run_initiated` (`initiated_by`),
  KEY `fk_pay_run_approved` (`approved_by`),
  KEY `idx_pay_run_status` (`status`),
  CONSTRAINT `fk_pay_run_ayid` FOREIGN KEY (`academic_year_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`),
  CONSTRAINT `fk_pay_run_parent` FOREIGN KEY (`parent_run_id`) REFERENCES `pay_payroll_runs` (`id`),
  CONSTRAINT `fk_pay_run_initiated` FOREIGN KEY (`initiated_by`) REFERENCES `sch_employees` (`id`),
  CONSTRAINT `fk_pay_run_approved` FOREIGN KEY (`approved_by`) REFERENCES `sch_employees` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- LAYER 4.5 — After pay_payroll_runs (nullable FK to pay_payroll_runs) (2 tables)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 22. hrs_pf_contribution_register
--     Monthly PF contribution amounts per employee. Status tracks filing lifecycle.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_pf_contribution_register` (
  `id`                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `compliance_record_id` BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → hrs_compliance_records.id',
  `payroll_run_id`       BIGINT UNSIGNED NULL     DEFAULT NULL     COMMENT 'FK → pay_payroll_runs.id; linked payroll run that generated this record',
  `month`                TINYINT UNSIGNED NOT NULL                 COMMENT 'Month number 1–12',
  `year`                 SMALLINT UNSIGNED NOT NULL                COMMENT 'Calendar year YYYY',
  `basic_wage`           DECIMAL(12,2)   NOT NULL                  COMMENT 'PF-eligible wages (capped at ₹15,000 for statutory PF)',
  `emp_contribution`     DECIMAL(10,2)   NOT NULL                  COMMENT 'Employee PF contribution at 12%',
  `employer_epf`         DECIMAL(10,2)   NOT NULL                  COMMENT 'Employer EPF portion at 3.67%',
  `employer_eps`         DECIMAL(10,2)   NOT NULL                  COMMENT 'Employer EPS (Pension) portion at 8.33%',
  `ncp_days`             TINYINT UNSIGNED NOT NULL DEFAULT 0       COMMENT 'Non-contributing days — required for EPFO ECR file',
  `status`               ENUM('computed','submitted','challan_generated') NOT NULL DEFAULT 'computed' COMMENT 'Filing lifecycle status',
  `is_active`            TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`           BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`           BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`           TIMESTAMP       NULL,
  `updated_at`           TIMESTAMP       NULL,
  `deleted_at`           TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hrs_pfreg` (`compliance_record_id`, `month`, `year`),
  KEY `fk_hrs_pfreg_complid` (`compliance_record_id`),
  KEY `fk_hrs_pfreg_runid` (`payroll_run_id`),
  CONSTRAINT `fk_hrs_pfreg_complid` FOREIGN KEY (`compliance_record_id`) REFERENCES `hrs_compliance_records` (`id`),
  CONSTRAINT `fk_hrs_pfreg_runid` FOREIGN KEY (`payroll_run_id`) REFERENCES `pay_payroll_runs` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 23. hrs_esi_contribution_register
--     Monthly ESI contribution amounts per employee.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_esi_contribution_register` (
  `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `compliance_record_id`  BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → hrs_compliance_records.id',
  `payroll_run_id`        BIGINT UNSIGNED NULL     DEFAULT NULL     COMMENT 'FK → pay_payroll_runs.id; linked payroll run',
  `month`                 TINYINT UNSIGNED NOT NULL                 COMMENT 'Month number 1–12',
  `year`                  SMALLINT UNSIGNED NOT NULL                COMMENT 'Calendar year YYYY',
  `gross_wage`            DECIMAL(12,2)   NOT NULL                  COMMENT 'ESI-eligible wages (applicable when gross ≤ ₹21,000 per month)',
  `emp_contribution`      DECIMAL(10,2)   NOT NULL                  COMMENT 'Employee ESI contribution at 0.75%',
  `employer_contribution` DECIMAL(10,2)   NOT NULL                  COMMENT 'Employer ESI contribution at 3.25%',
  `status`                ENUM('computed','submitted','challan_generated') NOT NULL DEFAULT 'computed' COMMENT 'Filing lifecycle status',
  `is_active`             TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`            BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`            BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`            TIMESTAMP       NULL,
  `updated_at`            TIMESTAMP       NULL,
  `deleted_at`            TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hrs_esireg` (`compliance_record_id`, `month`, `year`),
  KEY `fk_hrs_esireg_complid` (`compliance_record_id`),
  KEY `fk_hrs_esireg_runid` (`payroll_run_id`),
  CONSTRAINT `fk_hrs_esireg_complid` FOREIGN KEY (`compliance_record_id`) REFERENCES `hrs_compliance_records` (`id`),
  CONSTRAINT `fk_hrs_esireg_runid` FOREIGN KEY (`payroll_run_id`) REFERENCES `pay_payroll_runs` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- LAYER 5 — Depends on Layer 4 (6 tables)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 24. hrs_leave_balance_adjustments
--     Audit trail for manual leave balance adjustments (HR Manager only).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_leave_balance_adjustments` (
  `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `leave_balance_id` BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → hrs_leave_balances.id',
  `adjustment_days`  DECIMAL(5,1)    NOT NULL                  COMMENT 'Positive = add days; negative = deduct days',
  `reason`           TEXT            NOT NULL                  COMMENT 'Mandatory explanation for the adjustment',
  `adjusted_by`      INT UNSIGNED    NOT NULL                  COMMENT 'FK → sch_employees.id; HR Manager who made the adjustment',
  `is_active`        TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`       BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`       BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`       TIMESTAMP       NULL,
  `updated_at`       TIMESTAMP       NULL,
  `deleted_at`       TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `fk_hrs_lbadj_lbid` (`leave_balance_id`),
  KEY `fk_hrs_lbadj_adjby` (`adjusted_by`),
  CONSTRAINT `fk_hrs_lbadj_lbid` FOREIGN KEY (`leave_balance_id`) REFERENCES `hrs_leave_balances` (`id`),
  CONSTRAINT `fk_hrs_lbadj_adjby` FOREIGN KEY (`adjusted_by`) REFERENCES `sch_employees` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 25. hrs_leave_approvals
--     Approval action log. One row per approval step per leave application.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_leave_approvals` (
  `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_id`   BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → hrs_leave_applications.id',
  `approver_id`      INT UNSIGNED    NOT NULL                  COMMENT 'FK → sch_employees.id; HOD or Principal',
  `level`            TINYINT UNSIGNED NOT NULL                 COMMENT '1 = HOD approval level; 2 = Principal approval level',
  `action`           ENUM('approve','reject','return_for_clarification') NOT NULL COMMENT 'Action taken by approver',
  `remarks`          TEXT            NOT NULL                  COMMENT 'Mandatory remarks for all approval actions (BR-HRS-024)',
  `actioned_at`      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of approval action',
  `is_active`        TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`       BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`       BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`       TIMESTAMP       NULL,
  `updated_at`       TIMESTAMP       NULL,
  `deleted_at`       TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `fk_hrs_lappr_appid` (`application_id`),
  KEY `fk_hrs_lappr_approverid` (`approver_id`),
  CONSTRAINT `fk_hrs_lappr_appid` FOREIGN KEY (`application_id`) REFERENCES `hrs_leave_applications` (`id`),
  CONSTRAINT `fk_hrs_lappr_approverid` FOREIGN KEY (`approver_id`) REFERENCES `sch_employees` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 26. hrs_appraisals
--     Individual appraisal record per employee per cycle.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_appraisals` (
  `id`                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cycle_id`             BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → hrs_appraisal_cycles.id',
  `employee_id`          INT UNSIGNED    NOT NULL                  COMMENT 'FK → sch_employees.id; appraisee',
  `reviewer_id`          INT UNSIGNED    NULL     DEFAULT NULL     COMMENT 'FK → sch_employees.id; assigned reviewer (from reporting_to or manual)',
  `self_rating_json`     JSON            NULL     DEFAULT NULL     COMMENT 'Per-KPI self ratings: [{kpi_id, rating, comments}]',
  `reviewer_rating_json` JSON            NULL     DEFAULT NULL     COMMENT 'Per-KPI reviewer ratings: [{kpi_id, rating, comments}]',
  `overall_rating`       DECIMAL(4,2)    NULL     DEFAULT NULL     COMMENT 'Computed weighted average from KPI ratings',
  `self_comments`        TEXT            NULL     DEFAULT NULL     COMMENT 'Overall self-assessment comments',
  `reviewer_comments`    TEXT            NULL     DEFAULT NULL     COMMENT 'Overall reviewer comments',
  `hr_remarks`           TEXT            NULL     DEFAULT NULL     COMMENT 'HR Manager remarks for reopening or adjustment',
  `status`               ENUM('draft','submitted','reviewed','finalized') NOT NULL DEFAULT 'draft' COMMENT 'Appraisal FSM status',
  `finalized_at`         TIMESTAMP       NULL     DEFAULT NULL     COMMENT 'Timestamp of finalization; triggers AppraisalFinalized event',
  `is_active`            TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`           BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`           BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`           TIMESTAMP       NULL,
  `updated_at`           TIMESTAMP       NULL,
  `deleted_at`           TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hrs_appraisal` (`cycle_id`, `employee_id`),
  KEY `fk_hrs_appr_cycleid` (`cycle_id`),
  KEY `fk_hrs_appr_empid` (`employee_id`),
  KEY `fk_hrs_appr_reviewerid` (`reviewer_id`),
  CONSTRAINT `fk_hrs_appr_cycleid` FOREIGN KEY (`cycle_id`) REFERENCES `hrs_appraisal_cycles` (`id`),
  CONSTRAINT `fk_hrs_appr_empid` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`),
  CONSTRAINT `fk_hrs_appr_reviewerid` FOREIGN KEY (`reviewer_id`) REFERENCES `sch_employees` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 27. hrs_appraisal_increment_flags
--     Bridge: finalized appraisal → Payroll increment processing.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hrs_appraisal_increment_flags` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `appraisal_id`  BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → hrs_appraisals.id',
  `employee_id`   INT UNSIGNED    NOT NULL                  COMMENT 'FK → sch_employees.id; denormalised for IncrementService query',
  `cycle_id`      BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → hrs_appraisal_cycles.id',
  `flag_status`   ENUM('pending','processed') NOT NULL DEFAULT 'pending' COMMENT 'pending = awaiting IncrementService; processed = salary revision created',
  `processed_at`  TIMESTAMP       NULL     DEFAULT NULL     COMMENT 'Timestamp when IncrementService processed this flag',
  `is_active`     TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`    BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`    BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`    TIMESTAMP       NULL,
  `updated_at`    TIMESTAMP       NULL,
  `deleted_at`    TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `fk_hrs_incflag_apprid` (`appraisal_id`),
  KEY `fk_hrs_incflag_empid` (`employee_id`),
  KEY `fk_hrs_incflag_cycleid` (`cycle_id`),
  KEY `idx_hrs_incflag_status` (`flag_status`),
  CONSTRAINT `fk_hrs_incflag_apprid` FOREIGN KEY (`appraisal_id`) REFERENCES `hrs_appraisals` (`id`),
  CONSTRAINT `fk_hrs_incflag_empid` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`),
  CONSTRAINT `fk_hrs_incflag_cycleid` FOREIGN KEY (`cycle_id`) REFERENCES `hrs_appraisal_cycles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 28. pay_payroll_run_details
--     Per-employee per-run computed payroll amounts. Immutable after run is locked.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `pay_payroll_run_details` (
  `id`                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `payroll_run_id`       BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → pay_payroll_runs.id',
  `employee_id`          INT UNSIGNED    NOT NULL                  COMMENT 'FK → sch_employees.id',
  `salary_assignment_id` BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → hrs_salary_assignments.id (cross-prefix FK); assignment used for this computation',
  `lop_days`             DECIMAL(4,1)    NOT NULL DEFAULT 0        COMMENT 'Confirmed LOP days from hrs_lop_records for this month',
  `gross_pay`            DECIMAL(12,2)   NOT NULL DEFAULT 0        COMMENT 'Gross earnings before LWP deduction',
  `lwp_deduction`        DECIMAL(12,2)   NOT NULL DEFAULT 0        COMMENT 'LWP = (gross_monthly / working_days_in_month) × lop_days (BR-PAY-010)',
  `pf_employee`          DECIMAL(10,2)   NOT NULL DEFAULT 0        COMMENT 'Employee PF contribution at 12%',
  `pf_employer`          DECIMAL(10,2)   NOT NULL DEFAULT 0        COMMENT 'Employer PF contribution at 12%',
  `esi_employee`         DECIMAL(10,2)   NOT NULL DEFAULT 0        COMMENT 'Employee ESI contribution at 0.75%',
  `esi_employer`         DECIMAL(10,2)   NOT NULL DEFAULT 0        COMMENT 'Employer ESI contribution at 3.25%',
  `tds_deducted`         DECIMAL(10,2)   NOT NULL DEFAULT 0        COMMENT 'Monthly TDS — computed by TdsComputationService; shortfall carried forward (BR-PAY-006)',
  `pt_deduction`         DECIMAL(8,2)    NOT NULL DEFAULT 0        COMMENT 'Profession Tax — looked up from hrs_pt_slabs by state',
  `other_deductions`     DECIMAL(10,2)   NOT NULL DEFAULT 0        COMMENT 'Loan EMI, advance recovery, other manual deductions',
  `total_deductions`     DECIMAL(12,2)   NOT NULL DEFAULT 0        COMMENT 'Sum of all deductions (LWP + PF + ESI + TDS + PT + other)',
  `net_pay`              DECIMAL(12,2)   NOT NULL DEFAULT 0        COMMENT 'net_pay = gross_pay − lwp_deduction − total_deductions',
  `computation_json`     JSON            NULL     DEFAULT NULL     COMMENT 'Full per-component breakdown for payslip rendering',
  `payment_status`       ENUM('pending','exported','paid','failed') NOT NULL DEFAULT 'pending' COMMENT 'Bank disbursement status',
  `is_override`          TINYINT(1)      NOT NULL DEFAULT 0        COMMENT '1 = net_pay was manually overridden; recorded in pay_payroll_overrides',
  `is_active`            TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`           BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`           BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`           TIMESTAMP       NULL,
  `updated_at`           TIMESTAMP       NULL,
  `deleted_at`           TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pay_rundetail` (`payroll_run_id`, `employee_id`),
  KEY `fk_pay_det_runid` (`payroll_run_id`),
  KEY `fk_pay_det_empid` (`employee_id`),
  KEY `fk_pay_det_assgnid` (`salary_assignment_id`),
  CONSTRAINT `fk_pay_det_runid` FOREIGN KEY (`payroll_run_id`) REFERENCES `pay_payroll_runs` (`id`),
  CONSTRAINT `fk_pay_det_empid` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`),
  CONSTRAINT `fk_pay_det_assgnid` FOREIGN KEY (`salary_assignment_id`) REFERENCES `hrs_salary_assignments` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 29. pay_increment_policies
--     Rules mapping appraisal overall_rating ranges to increment amounts.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `pay_increment_policies` (
  `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`                VARCHAR(200)    NOT NULL                  COMMENT 'Policy name e.g. FY2026 Increment Matrix',
  `appraisal_cycle_id`  BIGINT UNSIGNED NULL     DEFAULT NULL     COMMENT 'FK → hrs_appraisal_cycles.id; NULL = applicable to all cycles',
  `min_rating`          DECIMAL(4,2)    NOT NULL                  COMMENT 'Inclusive lower bound of overall_rating for this slab',
  `max_rating`          DECIMAL(4,2)    NOT NULL                  COMMENT 'Inclusive upper bound of overall_rating for this slab',
  `increment_type`      ENUM('percentage','flat') NOT NULL        COMMENT 'percentage = % of current CTC; flat = fixed INR amount',
  `increment_value`     DECIMAL(8,2)    NOT NULL                  COMMENT 'Percentage or flat INR increment value',
  `is_active`           TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`          BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`          BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`          TIMESTAMP       NULL,
  `updated_at`          TIMESTAMP       NULL,
  `deleted_at`          TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `fk_pay_incpol_cycleid` (`appraisal_cycle_id`),
  CONSTRAINT `fk_pay_incpol_cycleid` FOREIGN KEY (`appraisal_cycle_id`) REFERENCES `hrs_appraisal_cycles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- LAYER 6 — Depends on Layer 5 (4 tables)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 30. pay_payroll_overrides
--     Audit trail for manual amendments to payroll run details.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `pay_payroll_overrides` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `run_detail_id`  BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → pay_payroll_run_details.id',
  `field_name`     VARCHAR(50)     NOT NULL                  COMMENT 'Column overridden e.g. net_pay, tds_deducted',
  `original_value` DECIMAL(12,2)   NOT NULL                  COMMENT 'Value before override',
  `override_value` DECIMAL(12,2)   NOT NULL                  COMMENT 'Value after override',
  `reason`         TEXT            NOT NULL                  COMMENT 'Mandatory explanation (BR-PAY-005)',
  `overridden_by`  INT UNSIGNED    NOT NULL                  COMMENT 'FK → sch_employees.id; Payroll Manager',
  `is_active`      TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`     BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`     BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`     TIMESTAMP       NULL,
  `updated_at`     TIMESTAMP       NULL,
  `deleted_at`     TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `fk_pay_ovr_detid` (`run_detail_id`),
  KEY `fk_pay_ovr_by` (`overridden_by`),
  CONSTRAINT `fk_pay_ovr_detid` FOREIGN KEY (`run_detail_id`) REFERENCES `pay_payroll_run_details` (`id`),
  CONSTRAINT `fk_pay_ovr_by` FOREIGN KEY (`overridden_by`) REFERENCES `sch_employees` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 31. pay_payslips
--     Generated payslip record per employee per run. One-to-one with run_detail.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `pay_payslips` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `run_detail_id`  BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → pay_payroll_run_details.id (UNIQUE)',
  `employee_id`    INT UNSIGNED    NOT NULL                  COMMENT 'FK → sch_employees.id; denormalised for quick self-service lookup',
  `payroll_month`  VARCHAR(7)      NOT NULL                  COMMENT 'YYYY-MM — denormalised for direct querying',
  `media_id`       BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → sys_media.id; generated password-protected PDF',
  `generated_at`   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of payslip generation',
  `email_status`   ENUM('not_sent','pending','sent','failed') NOT NULL DEFAULT 'not_sent' COMMENT 'Payslip email dispatch status',
  `email_sent_at`  TIMESTAMP       NULL     DEFAULT NULL     COMMENT 'Timestamp when email was successfully sent',
  `is_active`      TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`     BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`     BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`     TIMESTAMP       NULL,
  `updated_at`     TIMESTAMP       NULL,
  `deleted_at`     TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pay_payslip_detail` (`run_detail_id`),
  KEY `fk_pay_pslip_detid` (`run_detail_id`),
  KEY `fk_pay_pslip_empid` (`employee_id`),
  KEY `fk_pay_pslip_mediaid` (`media_id`),
  CONSTRAINT `fk_pay_pslip_detid` FOREIGN KEY (`run_detail_id`) REFERENCES `pay_payroll_run_details` (`id`),
  CONSTRAINT `fk_pay_pslip_empid` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`),
  CONSTRAINT `fk_pay_pslip_mediaid` FOREIGN KEY (`media_id`) REFERENCES `sys_media` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 32. pay_tds_ledger
--     Monthly TDS cumulative ledger per employee per financial year.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `pay_tds_ledger` (
  `id`             BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `employee_id`    INT UNSIGNED     NOT NULL                  COMMENT 'FK → sch_employees.id',
  `financial_year` VARCHAR(7)       NOT NULL                  COMMENT 'Financial year in YYYY-YY format e.g. 2025-26',
  `month`          TINYINT UNSIGNED NOT NULL                  COMMENT 'Month number 1–12',
  `gross_pay`      DECIMAL(12,2)    NOT NULL DEFAULT 0        COMMENT 'Gross salary for this month',
  `tds_deducted`   DECIMAL(10,2)    NOT NULL DEFAULT 0        COMMENT 'TDS deducted this month',
  `ytd_gross`      DECIMAL(14,2)    NOT NULL DEFAULT 0        COMMENT 'Year-to-date cumulative gross salary',
  `ytd_tds`        DECIMAL(12,2)    NOT NULL DEFAULT 0        COMMENT 'Year-to-date cumulative TDS deducted',
  `is_active`      TINYINT(1)       NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`     BIGINT UNSIGNED  NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`     BIGINT UNSIGNED  NOT NULL                  COMMENT 'sys_users.id',
  `created_at`     TIMESTAMP        NULL,
  `updated_at`     TIMESTAMP        NULL,
  `deleted_at`     TIMESTAMP        NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pay_tds` (`employee_id`, `financial_year`, `month`),
  KEY `fk_pay_tds_empid` (`employee_id`),
  CONSTRAINT `fk_pay_tds_empid` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 33. pay_form16
--     Generated Form 16 PDF per employee per financial year.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `pay_form16` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id`    INT UNSIGNED    NOT NULL                  COMMENT 'FK → sch_employees.id',
  `financial_year` VARCHAR(7)      NOT NULL                  COMMENT 'Financial year in YYYY-YY format e.g. 2025-26',
  `media_id`       BIGINT UNSIGNED NOT NULL                  COMMENT 'FK → sys_media.id; generated Form 16 PDF (Part A + Part B)',
  `generated_at`   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of Form 16 generation',
  `generated_by`   INT UNSIGNED    NOT NULL                  COMMENT 'FK → sch_employees.id; Payroll Manager who generated it',
  `is_active`      TINYINT(1)      NOT NULL DEFAULT 1        COMMENT 'Soft enable/disable',
  `created_by`     BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `updated_by`     BIGINT UNSIGNED NOT NULL                  COMMENT 'sys_users.id',
  `created_at`     TIMESTAMP       NULL,
  `updated_at`     TIMESTAMP       NULL,
  `deleted_at`     TIMESTAMP       NULL                      COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pay_form16` (`employee_id`, `financial_year`),
  KEY `fk_pay_form16_empid` (`employee_id`),
  KEY `fk_pay_form16_mediaid` (`media_id`),
  KEY `fk_pay_form16_genby` (`generated_by`),
  CONSTRAINT `fk_pay_form16_empid` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`),
  CONSTRAINT `fk_pay_form16_mediaid` FOREIGN KEY (`media_id`) REFERENCES `sys_media` (`id`),
  CONSTRAINT `fk_pay_form16_genby` FOREIGN KEY (`generated_by`) REFERENCES `sch_employees` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- SUMMARY: 33 tables created
-- hrs_* (23): hrs_kpi_templates, hrs_leave_types, hrs_id_card_templates,
--             hrs_pay_grades, hrs_pt_slabs, hrs_kpi_template_items,
--             hrs_employment_details, hrs_employment_history, hrs_employee_documents,
--             hrs_leave_policies, hrs_holiday_calendars, hrs_compliance_records,
--             hrs_lop_records, hrs_salary_assignments, hrs_appraisal_cycles,
--             hrs_leave_balances, hrs_leave_applications, hrs_pf_contribution_register,
--             hrs_esi_contribution_register, hrs_leave_balance_adjustments,
--             hrs_leave_approvals, hrs_appraisals, hrs_appraisal_increment_flags
-- pay_* (10): pay_salary_components, pay_salary_structures,
--             pay_salary_structure_components, pay_payroll_runs,
--             pay_payroll_run_details, pay_increment_policies,
--             pay_payroll_overrides, pay_payslips, pay_tds_ledger, pay_form16
-- =============================================================================
