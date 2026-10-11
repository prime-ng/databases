-- ===========================================================================
-- EMPLOYEE SETUP SUB-MODULE  —  v2.0
-- Scope   : Tenant DB (Per School)
-- DB      : MySQL 8+
-- Style   : Audit-ready, Soft Delete, Additive (v1 tables unchanged)
--
-- This file supersedes Employee_setup_ddl_v1.sql.
-- It contains ALL v1 tables (copied verbatim) PLUS the new
-- Employee Leave Management system (v2 additions clearly marked).
--
-- New in v2 (Employee Leave Management — 8 new tables):
--   sch_leave_approval_policies          — Which approval flow applies to whom
--   sch_leave_approval_policy_levels     — Ordered approval levels within a policy
--   sch_leave_approval_level_approvers   — Who approves at each level
--   sch_employee_leave_applications      — Core leave request record
--   sch_employee_leave_approvals         — Per-level approval trail
--   sch_employee_leave_application_docs  — Supporting documents
--   sch_employee_leave_application_remarks — Approver ↔ Applicant communication
--   sch_employee_leave_balance           — Live leave-balance ledger per employee
-- ===========================================================================


-- ===========================================================================
-- SECTION 1 : EXISTING TABLES (from Employee_setup_ddl_v1.sql — NO CHANGES)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1.1  sch_employees
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_employees` (
  `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`                   INT UNSIGNED NOT NULL,             -- FK → sys_users.id
  -- Employee identity
  `emp_code`                  VARCHAR(20)  NOT NULL,
  `emp_id_card_type`          ENUM('QR','RFID','NFC','Barcode') NOT NULL DEFAULT 'QR',
  `emp_smart_card_id`         VARCHAR(100) DEFAULT NULL,
  -- Flags & employment info
  `is_teacher`                TINYINT(1)   NOT NULL DEFAULT 0,
  `joining_date`              DATE         NOT NULL,
  `total_experience_years`    DECIMAL(4,1) DEFAULT NULL,
  `highest_qualification`     VARCHAR(100) DEFAULT NULL,
  `specialization`            VARCHAR(150) DEFAULT NULL,
  `last_institution`          VARCHAR(200) DEFAULT NULL,
  `awards`                    TEXT         DEFAULT NULL,
  `skills`                    TEXT         DEFAULT NULL,
  `qualifications_json`       JSON         DEFAULT NULL,
  `certifications_json`       JSON         DEFAULT NULL,
  `experiences_json`          JSON         DEFAULT NULL,
  `notes`                     TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `teachers_emp_code_unique` (`emp_code`),
  KEY `teachers_user_id_foreign` (`user_id`),
  CONSTRAINT `fk_teachers_userId` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ---------------------------------------------------------------------------
-- 1.2  sch_employees_profile
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_employees_profile` (
  `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id`               INT UNSIGNED NOT NULL,
  `user_id`                   INT UNSIGNED NOT NULL,
  `role_id`                   INT UNSIGNED NOT NULL,
  `department_id`             INT UNSIGNED DEFAULT NULL,
  `specialization_area`       VARCHAR(100) DEFAULT NULL,
  `qualification_level`       VARCHAR(50)  DEFAULT NULL,
  `qualification_field`       VARCHAR(100) DEFAULT NULL,
  `certifications`            JSON         DEFAULT NULL,
  `work_hours_daily`          DECIMAL(4,2) DEFAULT 8.0,
  `max_hours_daily`           DECIMAL(4,2) DEFAULT 10.0,
  `work_hours_weekly`         DECIMAL(5,2) DEFAULT 40.0,
  `max_hours_weekly`          DECIMAL(5,2) DEFAULT 50.0,
  `preferred_shift`           ENUM('morning','evening','flexible') DEFAULT 'morning',
  `is_full_time`              TINYINT(1)   DEFAULT 1,
  `core_responsibilities`     JSON         DEFAULT NULL,
  `technical_skills`          JSON         DEFAULT NULL,
  `soft_skills`               JSON         DEFAULT NULL,
  `experience_months`         SMALLINT UNSIGNED DEFAULT NULL,
  `performance_rating`        TINYINT UNSIGNED  DEFAULT NULL,
  `last_performance_review`   DATE         DEFAULT NULL,
  `security_clearance_done`   TINYINT(1)   DEFAULT 0,
  `reporting_to`              INT UNSIGNED DEFAULT NULL,
  `can_approve_budget`        TINYINT(1)   DEFAULT 0,
  `can_manage_staff`          TINYINT(1)   DEFAULT 0,
  `can_access_sensitive_data` TINYINT(1)   DEFAULT 0,
  `assignment_meta`           JSON         DEFAULT NULL,
  `notes`                     TEXT         DEFAULT NULL,
  `effective_from`            DATE         DEFAULT NULL,
  `effective_to`              DATE         DEFAULT NULL,
  `is_active`                 TINYINT(1)   NOT NULL DEFAULT 1,
  `created_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_employee_role_active` (`employee_id`, `role_id`, `effective_to`),
  CONSTRAINT `fk_employeeProfile_employeeId`   FOREIGN KEY (`employee_id`)  REFERENCES `sch_employees` (`id`),
  CONSTRAINT `fk_employeeProfile_roleId`       FOREIGN KEY (`role_id`)      REFERENCES `sch_employee_roles` (`id`),
  CONSTRAINT `fk_employeeProfile_departmentId` FOREIGN KEY (`department_id`) REFERENCES `sch_departments` (`id`),
  CONSTRAINT `fk_employeeProfile_reportingTo`  FOREIGN KEY (`reporting_to`) REFERENCES `sch_employees` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ---------------------------------------------------------------------------
-- 1.3  sch_teacher_profile
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_teacher_profile` (
  `id`                              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id`                     INT UNSIGNED NOT NULL,
  `user_id`                         INT UNSIGNED NOT NULL,
  `role_id`                         INT UNSIGNED NOT NULL,
  `department_id`                   INT UNSIGNED NOT NULL,
  `designation_id`                  INT UNSIGNED NOT NULL,
  `teacher_house_room_id`           INT UNSIGNED DEFAULT NULL,
  `is_full_time`                    TINYINT(1)   DEFAULT 1,
  `preferred_shift`                 INT UNSIGNED DEFAULT NULL,
  `capable_handling_multiple_classes` TINYINT(1) DEFAULT 0,
  `can_be_used_for_substitution`    TINYINT(1)   DEFAULT 1,
  `certified_for_lab`               TINYINT(1)   DEFAULT 0,
  `is_proficient_with_computer`     TINYINT(1)   DEFAULT 0,
  `can_manage_staff`                TINYINT(1)   DEFAULT 0,
  `special_skill_area`              VARCHAR(100) DEFAULT NULL,
  `soft_skills`                     JSON         DEFAULT NULL,
  `assignment_meta`                 JSON         DEFAULT NULL,
  `max_available_periods_weekly`    TINYINT UNSIGNED DEFAULT 48,
  `min_available_periods_weekly`    TINYINT UNSIGNED DEFAULT 36,
  `max_allocated_periods_weekly`    TINYINT UNSIGNED DEFAULT 1,
  `min_allocated_periods_weekly`    TINYINT UNSIGNED DEFAULT 1,
  `can_be_split_across_sections`    TINYINT(1)   DEFAULT 0,
  `min_teacher_availability_score`  DECIMAL(7,2) UNSIGNED DEFAULT 1,
  `max_teacher_availability_score`  DECIMAL(7,2) UNSIGNED DEFAULT 1,
  `performance_rating`              TINYINT UNSIGNED DEFAULT NULL,
  `last_performance_review`         DATE         DEFAULT NULL,
  `security_clearance_done`         TINYINT(1)   DEFAULT 0,
  `reporting_to`                    INT UNSIGNED DEFAULT NULL,
  `can_access_sensitive_data`       TINYINT(1)   DEFAULT 0,
  `notes`                           TEXT         NULL,
  `effective_from`                  DATE         DEFAULT NULL,
  `effective_to`                    DATE         DEFAULT NULL,
  `is_active`                       TINYINT(1)   NOT NULL DEFAULT 1,
  `created_at`                      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`                      TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_teacher_employee` (`employee_id`),
  CONSTRAINT `fk_teacher_employee`    FOREIGN KEY (`employee_id`)  REFERENCES `sch_employees` (`id`),
  CONSTRAINT `fk_teacher_user`        FOREIGN KEY (`user_id`)      REFERENCES `sys_users` (`id`),
  CONSTRAINT `fk_teacher_role`        FOREIGN KEY (`role_id`)      REFERENCES `sch_employee_roles` (`id`),
  CONSTRAINT `fk_teacher_department`  FOREIGN KEY (`department_id`) REFERENCES `sch_departments` (`id`),
  CONSTRAINT `fk_teacher_designation` FOREIGN KEY (`designation_id`) REFERENCES `sch_designations` (`id`),
  CONSTRAINT `fk_teacher_reporting_to` FOREIGN KEY (`reporting_to`) REFERENCES `sch_employees` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition: One record per teacher (UNIQUE on employee_id).


-- ---------------------------------------------------------------------------
-- 1.4  sch_teacher_capabilities
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_teacher_capabilities` (
  `id`                          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `teacher_profile_id`          INT UNSIGNED NOT NULL,
  `class_id`                    INT UNSIGNED NOT NULL,
  `subject_study_format_id`     INT UNSIGNED NOT NULL,
  `proficiency_percentage`      TINYINT UNSIGNED DEFAULT NULL,
  `teaching_experience_months`  SMALLINT UNSIGNED DEFAULT NULL,
  `is_primary_subject`          TINYINT(1)   NOT NULL DEFAULT 1,
  `competancy_level`            ENUM('Facilitator','Basic','Intermediate','Advanced','Expert') DEFAULT 'Basic',
  `priority_order`              INT UNSIGNED DEFAULT NULL,
  `priority_weight`             TINYINT UNSIGNED DEFAULT NULL,
  `scarcity_index`              TINYINT UNSIGNED DEFAULT NULL,
  `is_hard_constraint`          TINYINT(1)   DEFAULT 0,
  `allocation_strictness`       ENUM('hard','medium','soft') DEFAULT 'medium',
  `override_priority`           TINYINT UNSIGNED DEFAULT NULL,
  `override_reason`             VARCHAR(255) DEFAULT NULL,
  `historical_success_ratio`    TINYINT UNSIGNED DEFAULT NULL,
  `last_allocation_score`       TINYINT UNSIGNED DEFAULT NULL,
  `effective_from`              DATE         DEFAULT NULL,
  `is_active`                   TINYINT(1)   NOT NULL DEFAULT 1,
  `active_flag`                 TINYINT(1) GENERATED ALWAYS AS (CASE WHEN (`is_active` = 1) THEN 1 ELSE NULL END) STORED,
  `created_at`                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`                  TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_teacher_capability` (`teacher_profile_id`, `class_id`, `subject_study_format_id`, `active_flag`),
  CONSTRAINT `fk_tc_teacher_profile`      FOREIGN KEY (`teacher_profile_id`)      REFERENCES `sch_teacher_profile` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tc_class`                FOREIGN KEY (`class_id`)                REFERENCES `sch_classes` (`id`),
  CONSTRAINT `fk_tc_subject_study_format` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===========================================================================
-- SECTION 2 : NEW TABLES  —  EMPLOYEE LEAVE MANAGEMENT  (v2.0)
-- ===========================================================================
--
-- SYSTEM OVERVIEW
-- ───────────────
-- An employee submits a leave application.  The application is routed through 
-- a multi-level approval pipeline determined by the Leave Approval Policy that
-- matches the employee's role / department / designation.
--
-- POLICY MATCHING (resolved at submission time, priority-ordered):
--   1. Most specific wins: role + department + designation
--   2. Partial match:     role + department,  role only,  department only …
--   3. Default policy:   where all three FK columns are NULL (catch-all)
--
-- APPROVAL LEVELS:
--   • Each policy has 1-N ordered levels.
--   • Each level has 1-N configured approvers (by specific user, role,
--     designation, department-head, or "reporting_to" manager).
--   • approval_mode per level = ANY_ONE | ALL
--     (ANY_ONE: first person to act closes the level;
--      ALL: everyone must approve before the level advances)
--   • escalation_after_hours: if no action within X hours the application
--     automatically advances to the next level and a notification is sent.
--
-- STATUS FSM (sch_employee_leave_applications.status):
--   Draft          → saved but not submitted
--   Submitted      → submitted; Level-1 approvers notified
--   Under Review   → any Level-N approver has opened it
--   Info Requested → an approver asked for clarification
--   Doc Requested  → an approver requested a supporting document
--   Escalated      → auto-escalated due to timeout
--   Approved       → final level approved; balance deducted
--   Rejected       → rejected at any level
--   Cancelled      → withdrawn by employee before final decision
-- ===========================================================================


-- ---------------------------------------------------------------------------
-- 2.1  sch_leave_approval_policies
-- ---------------------------------------------------------------------------
-- Defines WHICH approval pipeline applies to a combination of
-- role / department / designation.  Leave NULL to mean "any".
-- Most-specific match wins (use `priority` to break ties).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_leave_approval_policies` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`                  VARCHAR(150) NOT NULL COMMENT 'Human-readable name: "Teacher Leave Policy", "Admin Staff Leave Policy"',
  `description`           VARCHAR(500) DEFAULT NULL,
  -- Matching criteria (all nullable; NULL = applies to ALL of that dimension)
  `applies_to_role_id`        INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_employee_roles.id; NULL = any role',
  `applies_to_department_id`  INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_departments.id; NULL = any department',
  `applies_to_designation_id` INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_designations.id; NULL = any designation',
  `applies_to_leave_type_id`  INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_leave_types.id; NULL = applies to all leave types',
  -- Tie-breaking: higher priority number wins when multiple policies match
  `priority`              TINYINT UNSIGNED NOT NULL DEFAULT 10 COMMENT 'Higher value = higher priority (more specific policies get higher numbers)',
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_lap_role`        (`applies_to_role_id`),
  INDEX `idx_lap_department`  (`applies_to_department_id`),
  INDEX `idx_lap_designation` (`applies_to_designation_id`),
  INDEX `idx_lap_leave_type`  (`applies_to_leave_type_id`),
  INDEX `idx_lap_active`      (`is_active`),
  CONSTRAINT `fk_lap_role`        FOREIGN KEY (`applies_to_role_id`)        REFERENCES `sch_employee_roles` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_lap_department`  FOREIGN KEY (`applies_to_department_id`)  REFERENCES `sch_departments` (`id`)    ON DELETE SET NULL,
  CONSTRAINT `fk_lap_designation` FOREIGN KEY (`applies_to_designation_id`) REFERENCES `sch_designations` (`id`)  ON DELETE SET NULL,
  CONSTRAINT `fk_lap_leave_type`  FOREIGN KEY (`applies_to_leave_type_id`)  REFERENCES `sch_leave_types` (`id`)   ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Approval policy master — matches employee context to an approval pipeline';


-- ---------------------------------------------------------------------------
-- 2.2  sch_leave_approval_policy_levels
-- ---------------------------------------------------------------------------
-- Ordered approval levels within a policy.
-- e.g., Policy "Teacher Leave" → Level 1 "HOD Review", Level 2 "Principal Final".
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_leave_approval_policy_levels` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `policy_id`             INT UNSIGNED NOT NULL COMMENT 'FK → sch_leave_approval_policies.id',
  `level_number`          TINYINT UNSIGNED NOT NULL COMMENT 'Execution order: 1 = first, 2 = second, …',
  `level_name`            VARCHAR(100) NOT NULL COMMENT 'Display label: "HOD Review", "Principal Approval"',
  -- Approval logic at this level
  `approval_mode`         ENUM('ANY_ONE', 'ALL') NOT NULL DEFAULT 'ANY_ONE' COMMENT 'ANY_ONE: first approver to act closes this level; ALL: every approver must act',
  -- Escalation settings
  `escalation_after_hours` SMALLINT UNSIGNED DEFAULT NULL COMMENT 'Auto-escalate to next level if no action within N hours (NULL = never auto-escalate)',
  `notify_applicant_on_escalation` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = send notification to employee when escalation fires',
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_policy_level` (`policy_id`, `level_number`),
  INDEX `idx_lapl_policy` (`policy_id`),
  CONSTRAINT `fk_lapl_policy` FOREIGN KEY (`policy_id`) REFERENCES `sch_leave_approval_policies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Ordered approval levels within a policy (Level 1 → Level 2 → …)';


-- ---------------------------------------------------------------------------
-- 2.3  sch_leave_approval_level_approvers
-- ---------------------------------------------------------------------------
-- WHO is authorised to approve at a given level.
-- Multiple rows per level (any/all logic controlled by approval_mode in parent).
--
-- approver_type options:
--   USER          → a specific named user (approver_user_id populated)
--   ROLE          → any user who holds this system role (approver_role_id)
--   DESIGNATION   → any employee with this designation (approver_designation_id)
--   DEPARTMENT_HEAD → the head-of-department of the APPLICANT's department
--   REPORTING_TO  → the direct reporting manager of the applicant
--                   (resolved at runtime from sch_employees_profile.reporting_to)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_leave_approval_level_approvers` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `level_id`              INT UNSIGNED NOT NULL COMMENT 'FK → sch_leave_approval_policy_levels.id',
  `approver_type`         ENUM('USER','ROLE','DESIGNATION','DEPARTMENT_HEAD','REPORTING_TO') NOT NULL,
  -- Populated based on approver_type (others remain NULL)
  `approver_user_id`         INT UNSIGNED DEFAULT NULL COMMENT 'FK → sys_users.id — only when approver_type = USER',
  `approver_role_id`         INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_employee_roles.id — only when approver_type = ROLE',
  `approver_designation_id`  INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_designations.id — only when approver_type = DESIGNATION',
  `approver_department_id`   INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_departments.id — only when approver_type = DEPARTMENT_HEAD',
  `approver_reporting_to_id` INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_employees.id — only when approver_type = REPORTING_TO',
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_lala_level`       (`level_id`),
  INDEX `idx_lala_user`        (`approver_user_id`),
  INDEX `idx_lala_role`        (`approver_role_id`),
  INDEX `idx_lala_designation` (`approver_designation_id`),
  CONSTRAINT `fk_lala_level`       FOREIGN KEY (`level_id`)              REFERENCES `sch_leave_approval_policy_levels` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_lala_user`        FOREIGN KEY (`approver_user_id`)      REFERENCES `sys_users` (`id`)          ON DELETE SET NULL,
  CONSTRAINT `fk_lala_role`        FOREIGN KEY (`approver_role_id`)      REFERENCES `sch_employee_roles` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_lala_designation` FOREIGN KEY (`approver_designation_id`) REFERENCES `sch_designations` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_lala_department`  FOREIGN KEY (`approver_department_id`) REFERENCES `sch_departments` (`id`)  ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Authorised approvers per level — USER / ROLE / DESIGNATION / DEPARTMENT_HEAD / REPORTING_TO';


-- ---------------------------------------------------------------------------
-- 2.4  sch_employee_leave_applications
-- ---------------------------------------------------------------------------
-- Core leave request. One row per leave application.
-- `approval_policy_id` and `current_level_number` are snapshot/runtime fields
-- locked at submission time so policy changes mid-flight do not affect open apps.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_employee_leave_applications` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  -- Applicant context
  `employee_id`           INT UNSIGNED NOT NULL COMMENT 'FK → sch_employees.id',
  `academic_session_id`   INT UNSIGNED NOT NULL COMMENT 'FK → sch_org_academic_sessions_jnt.id',
  -- Leave details
  `leave_type_id`         INT UNSIGNED NOT NULL COMMENT 'FK → sch_leave_types.id',
  `from_date`             DATE NOT NULL COMMENT 'First day of leave',
  `to_date`               DATE NOT NULL COMMENT 'Last day of leave (= from_date for single-day)',
  `total_days`            DECIMAL(4,1) NOT NULL DEFAULT 1.0 COMMENT 'Calendar working days requested; 0.5 for half-day',
  `is_half_day`           TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = half-day (only valid when from_date = to_date)',
  `half_day_slot`         ENUM('Morning','Afternoon') DEFAULT NULL COMMENT 'Populated only when is_half_day = 1',
  `reason`                TEXT NOT NULL COMMENT 'Employee-provided reason',
  -- Status FSM
  `status`                ENUM('Draft','Submitted','Under Review','Info Requested','Doc Requested','Escalated','Approved','Rejected','Cancelled') NOT NULL DEFAULT 'Draft',
  -- Approval pipeline (locked at submission)
  `approval_policy_id`    INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_leave_approval_policies.id — resolved and locked at submission time',
  `current_level_number`  TINYINT UNSIGNED DEFAULT NULL COMMENT 'Which approval level is currently active (NULL before submission)',
  -- Submission
  `applied_by`            INT UNSIGNED NOT NULL COMMENT 'FK → sys_users.id — who submitted',
  `submitted_at`          TIMESTAMP NULL DEFAULT NULL COMMENT 'When status moved from Draft → Submitted',
  -- Final decision (set on terminal states: Approved / Rejected)
  `final_reviewed_by`     INT UNSIGNED DEFAULT NULL COMMENT 'FK → sys_users.id — user who took final action',
  `final_reviewed_at`     TIMESTAMP NULL DEFAULT NULL,
  `approved_days`         DECIMAL(4,1) DEFAULT NULL COMMENT 'Actual approved days (may differ from total_days — partial approval)',
  `final_remarks`         TEXT DEFAULT NULL COMMENT 'Final approver remarks on approval / rejection',
  -- Audit
  `created_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_ela_employee`         (`employee_id`, `academic_session_id`),
  INDEX `idx_ela_status`           (`status`),
  INDEX `idx_ela_dates`            (`from_date`, `to_date`),
  INDEX `idx_ela_leave_type`       (`leave_type_id`),
  INDEX `idx_ela_policy`           (`approval_policy_id`),
  INDEX `idx_ela_applied_by`       (`applied_by`),
  INDEX `idx_ela_final_reviewed`   (`final_reviewed_by`),
  CONSTRAINT `fk_ela_employee`      FOREIGN KEY (`employee_id`)        REFERENCES `sch_employees` (`id`)                      ON DELETE RESTRICT,
  CONSTRAINT `fk_ela_session`       FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`)     ON DELETE RESTRICT,
  CONSTRAINT `fk_ela_leave_type`    FOREIGN KEY (`leave_type_id`)      REFERENCES `sch_leave_types` (`id`)                    ON DELETE RESTRICT,
  CONSTRAINT `fk_ela_policy`        FOREIGN KEY (`approval_policy_id`) REFERENCES `sch_leave_approval_policies` (`id`)        ON DELETE SET NULL,
  CONSTRAINT `fk_ela_applied_by`    FOREIGN KEY (`applied_by`)         REFERENCES `sys_users` (`id`)                          ON DELETE RESTRICT,
  CONSTRAINT `fk_ela_final_reviewed` FOREIGN KEY (`final_reviewed_by`) REFERENCES `sys_users` (`id`)                          ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Employee leave application — core request record with multi-level approval tracking';
-- Notes:
--   is_half_day = 1 only valid when from_date = to_date
--   On status → Approved: application layer MUST deduct approved_days from sch_employee_leave_balance
--   On status → Cancelled / Rejected: any hold on pending balance must be released


-- ---------------------------------------------------------------------------
-- 2.5  sch_employee_leave_approvals
-- ---------------------------------------------------------------------------
-- One row per level per individual approver action.
-- Provides a full audit trail: who acted, at what level, what was the decision,
-- when did escalation fire, etc.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_employee_leave_approvals` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `leave_application_id`  INT UNSIGNED NOT NULL COMMENT 'FK → sch_employee_leave_applications.id',
  -- Level reference
  `policy_level_id`       INT UNSIGNED NOT NULL COMMENT 'FK → sch_leave_approval_policy_levels.id',
  `level_number`          TINYINT UNSIGNED NOT NULL COMMENT 'Snapshot of level_number at time of routing',
  `level_name`            VARCHAR(100) NOT NULL COMMENT 'Snapshot of level_name (for historical display)',
  -- Approver who acted
  `approver_user_id`      INT UNSIGNED DEFAULT NULL COMMENT 'FK → sys_users.id — the actual user who acted (resolved from approver_type at routing time)',
  -- Action taken
  `action`                ENUM('Pending','Approved','Rejected','Info Requested','Doc Requested','Escalated','Skipped') NOT NULL DEFAULT 'Pending',
  `remarks`               TEXT DEFAULT NULL COMMENT 'Approver remarks for this action',
  `acted_at`              TIMESTAMP NULL DEFAULT NULL COMMENT 'When the action was recorded',
  -- Escalation tracking
  `escalation_deadline`   TIMESTAMP NULL DEFAULT NULL COMMENT 'Deadline by which action must be taken before auto-escalation fires',
  `escalated_at`          TIMESTAMP NULL DEFAULT NULL COMMENT 'Timestamp when auto-escalation fired',
  `escalated_to_level`    TINYINT UNSIGNED DEFAULT NULL COMMENT 'Level number to which this was escalated',
  -- Audit
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_elap_application`     (`leave_application_id`, `level_number`),
  INDEX `idx_elap_approver`        (`approver_user_id`),
  INDEX `idx_elap_action`          (`action`),
  INDEX `idx_elap_pending`         (`leave_application_id`, `action`) COMMENT 'Quickly find open actions for an application',
  INDEX `idx_elap_deadline`        (`escalation_deadline`) COMMENT 'Scheduler queries for overdue approvals',
  CONSTRAINT `fk_elap_application` FOREIGN KEY (`leave_application_id`) REFERENCES `sch_employee_leave_applications` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_elap_level`       FOREIGN KEY (`policy_level_id`)      REFERENCES `sch_leave_approval_policy_levels` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_elap_approver`    FOREIGN KEY (`approver_user_id`)     REFERENCES `sys_users` (`id`)                        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Per-level approver action trail — one row per approver per level; escalation timestamps tracked here';

-- Conditions:
-- Pending - Routed to this level, awaiting action
-- Approved - Level approved by this approver
-- Rejected',      -- Rejected at this level
-- Info Requested',-- Approver asked for more information
-- Doc Requested', -- Approver requested a supporting document
-- Escalated',     -- Auto-escalated; this level timed out
-- Skipped'        -- Skipped (e.g., approver same as applicant, or already resolved)

-- ---------------------------------------------------------------------------
-- 2.6  sch_employee_leave_application_docs
-- ---------------------------------------------------------------------------
-- Supporting documents attached to a leave application.
-- Can be uploaded at submission OR later in response to a Doc Requested remark.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_employee_leave_application_docs` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `leave_application_id`  INT UNSIGNED NOT NULL COMMENT 'FK → sch_employee_leave_applications.id',
  -- Document metadata
  `document_name`         VARCHAR(150) NOT NULL COMMENT 'Display name: Medical Certificate, NOC, etc.',
  `document_type_id`      INT UNSIGNED DEFAULT NULL COMMENT 'FK → sys_dropdown_table (document category)',
  `description`           VARCHAR(255) DEFAULT NULL COMMENT 'Additional context',
  -- File storage
  `file_name`             VARCHAR(255) NOT NULL COMMENT 'Stored filename',
  `media_id`              INT UNSIGNED DEFAULT NULL COMMENT 'FK → sys_media (explicit Spatie link)',
  -- Upload context
  `uploaded_by`           INT UNSIGNED NOT NULL COMMENT 'FK → sys_users.id — employee or delegate who uploaded',
  `is_in_response_to_request` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '0 = voluntarily submitted; 1 = uploaded in response to a Doc Requested remark',
  `request_remark_id`     INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_employee_leave_application_remarks.id — the specific Doc Requested remark this fulfils',
  -- Audit
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_elad_application`     (`leave_application_id`),
  INDEX `idx_elad_request_remark`  (`request_remark_id`),
  CONSTRAINT `fk_elad_application` FOREIGN KEY (`leave_application_id`) REFERENCES `sch_employee_leave_applications` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_elad_doc_type`    FOREIGN KEY (`document_type_id`)     REFERENCES `sys_dropdown_table` (`id`)             ON DELETE SET NULL,
  CONSTRAINT `fk_elad_uploaded_by` FOREIGN KEY (`uploaded_by`)          REFERENCES `sys_users` (`id`)                      ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Supporting documents for employee leave applications (voluntary or in response to doc request)';


-- ---------------------------------------------------------------------------
-- 2.7  sch_employee_leave_application_remarks
-- ---------------------------------------------------------------------------
-- Bidirectional communication thread between approver(s) and the employee,
-- AND automatic FSM audit log on every status transition.
--
-- REMARK TYPES:
--   Comment       → General informational note (either party)
--   Info_Request  → Approver asking employee for clarification
--   Doc_Request   → Approver requesting a specific supporting document
--   Response      → Employee replying to an Info_Request or Doc_Request
--   Status_Change → Auto-inserted by the application layer on EVERY FSM transition
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_employee_leave_application_remarks` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `leave_application_id`  INT UNSIGNED NOT NULL COMMENT 'FK → sch_employee_leave_applications.id',
  -- Level context (NULL for employee-side remarks and status_change entries)
  `approval_level_id`     INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_leave_approval_policy_levels.id — which approval level this remark belongs to',
  -- Remark content
  `remark_type`           ENUM('Comment','Info_Request','Doc_Request','Response','Status_Change') NOT NULL DEFAULT 'Comment',
  `message`               TEXT NOT NULL,
  -- Sender
  `is_from_approver`      TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = remark from approver side; 0 = remark from employee',
  `remarked_by`           INT UNSIGNED NOT NULL COMMENT 'FK → sys_users.id',
  -- Thread linkage
  `parent_remark_id`      INT UNSIGNED DEFAULT NULL COMMENT 'FK → self — links a Response to the request it answers',
  -- Resolution tracking (for Info_Request and Doc_Request)
  `is_resolved`           TINYINT(1) NOT NULL DEFAULT 0,
  `resolved_at`           TIMESTAMP NULL DEFAULT NULL,
  -- Status snapshot (Status_Change type only)
  `old_status`            VARCHAR(30) DEFAULT NULL,
  `new_status`            VARCHAR(30) DEFAULT NULL,
  -- Audit
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_elar_application`   (`leave_application_id`, `remark_type`),
  INDEX `idx_elar_level`         (`approval_level_id`),
  INDEX `idx_elar_parent`        (`parent_remark_id`),
  INDEX `idx_elar_remarked_by`   (`remarked_by`),
  INDEX `idx_elar_unresolved`    (`leave_application_id`, `is_resolved`),
  CONSTRAINT `fk_elar_application`   FOREIGN KEY (`leave_application_id`) REFERENCES `sch_employee_leave_applications` (`id`)   ON DELETE CASCADE,
  CONSTRAINT `fk_elar_level`         FOREIGN KEY (`approval_level_id`)    REFERENCES `sch_leave_approval_policy_levels` (`id`)   ON DELETE SET NULL,
  CONSTRAINT `fk_elar_remarked_by`   FOREIGN KEY (`remarked_by`)          REFERENCES `sys_users` (`id`)                          ON DELETE RESTRICT,
  CONSTRAINT `fk_elar_parent_remark` FOREIGN KEY (`parent_remark_id`)     REFERENCES `sch_employee_leave_application_remarks` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Approver ↔ Employee communication thread + automatic FSM audit log for every status transition';
-- Notes:
--   remark_type = Info_Request  → application status → Info Requested
--   remark_type = Doc_Request   → application status → Doc Requested
--   remark_type = Response      → set parent_remark_id to the open request; status reverts → Submitted
--   remark_type = Status_Change → auto-inserted on EVERY status change; old_status & new_status mandatory
--   is_resolved = 1             → set by approver after reviewing employee's response, OR
--                                  automatically when employee uploads a doc (Doc_Request) or responds


-- ---------------------------------------------------------------------------
-- 2.8  sch_employee_leave_balance
-- ---------------------------------------------------------------------------
-- Live leave-balance ledger: one row per employee × leave_type × academic year.
-- The application layer updates this atomically when an application is Approved,
-- Rejected, or Cancelled.
--
-- BALANCE FORMULA:
--   available_balance = opening_balance + carry_forward - total_used
--   pending_balance   = days from Submitted/Under Review/Info Requested/Doc Requested applications
--
-- CARRY FORWARD:
--   At year-end the scheduler computes carry_forward = MIN(available_balance, max_carry_forward)
--   from sch_leave_config and seeds the new year's opening_balance accordingly.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_employee_leave_balance` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id`           INT UNSIGNED NOT NULL COMMENT 'FK → sch_employees.id',
  `academic_year`         VARCHAR(9)   NOT NULL COMMENT 'Format: 2025-26',
  `leave_type_id`         INT UNSIGNED NOT NULL COMMENT 'FK → sch_leave_types.id',
  -- Opening position (set when year is initialized)
  `opening_balance`       DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT 'Days allocated at start of year (from sch_leave_config + carry forward from prior year)',
  `carry_forward`         DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT 'Days carried forward from the previous academic year',
  -- Runtime balance (updated on every approved/rejected/cancelled application)
  `total_used`            DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT 'Total days consumed by Approved applications this year',
  `total_pending`         DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT 'Days locked by applications still in active workflow (not yet Approved/Rejected/Cancelled)',
  -- Derived (application layer should also maintain this for fast reads)
  `available_balance`     DECIMAL(5,2) GENERATED ALWAYS AS (opening_balance + carry_forward - total_used) STORED COMMENT 'Computed: opening + carry_forward − used',
  -- Adjustment (admin manual correction)
  `manual_adjustment`     DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT 'Admin-applied correction (positive = credit, negative = deduction)',
  `adjustment_reason`     VARCHAR(255) DEFAULT NULL,
  -- Audit
  `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED DEFAULT NULL,
  `updated_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_leave_balance` (`employee_id`, `academic_year`, `leave_type_id`),
  INDEX `idx_elb_employee`      (`employee_id`, `academic_year`),
  INDEX `idx_elb_leave_type`    (`leave_type_id`),
  INDEX `idx_elb_active`        (`is_active`),
  CONSTRAINT `fk_elb_employee`   FOREIGN KEY (`employee_id`)  REFERENCES `sch_employees` (`id`)   ON DELETE RESTRICT,
  CONSTRAINT `fk_elb_leave_type` FOREIGN KEY (`leave_type_id`) REFERENCES `sch_leave_types` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Live leave-balance ledger per employee per leave type per academic year. Available balance is auto-computed.';
-- Notes:
--   On application Submitted:  total_pending += total_days
--   On application Approved:   total_used += approved_days; total_pending -= total_days
--   On application Rejected / Cancelled: total_pending -= total_days
--   On year-end rollover: carry_forward = MIN(available_balance, max_carry_forward) from sch_leave_config
--   available_balance GENERATED COLUMN does NOT include manual_adjustment by design —
--     if needed, app layer should use: available_balance + manual_adjustment for display.


-- ===========================================================================
-- APPENDIX: TABLE SUMMARY
-- ===========================================================================
--
--  EXISTING (v1) — unchanged
--  ─────────────────────────
--  sch_employees                         — Employee master
--  sch_employees_profile                 — Non-teacher staff profile
--  sch_teacher_profile                   — Teacher-specific profile
--  sch_teacher_capabilities              — Teacher class×subject teaching capability
--
--  NEW (v2) — Employee Leave Management
--  ─────────────────────────────────────
--  sch_leave_approval_policies           — Policy: which approval flow applies to whom
--  sch_leave_approval_policy_levels      — Ordered levels within a policy (L1, L2 …)
--  sch_leave_approval_level_approvers    — Authorised approvers per level
--  sch_employee_leave_applications       — Core leave request
--  sch_employee_leave_approvals          — Per-level action trail + escalation log
--  sch_employee_leave_application_docs   — Supporting documents
--  sch_employee_leave_application_remarks— Approver ↔ Employee communication + FSM log
--  sch_employee_leave_balance            — Live balance ledger (used, pending, available)
--
-- ===========================================================================
-- Change Log
-- ===========================================================================
-- v1.0 → v2.0 (2026-04-08):
--   Added Employee Leave Management sub-system (8 new tables).
--   v1 tables carried forward verbatim (no structural changes).
-- ===========================================================================
