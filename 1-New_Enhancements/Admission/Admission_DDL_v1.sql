-- =============================================================================
-- ADM — Admission Management Module DDL
-- Module: Admission (Modules\Admission)
-- Table Prefix: adm_* (20 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: 2026-03-27
-- Based on: ADM_Admission_Requirement.md v2
-- Sub-Modules: Configuration, Enquiry & CRM, Application Pipeline,
--              Entrance Test, Merit & Allotment, Promotion,
--              Alumni & TC, Behavior Incidents
-- IMPORTANT: EnrollmentService WRITES to sys_users, std_students,
--            std_student_academic_sessions, std_siblings_jnt on enrollment.
-- =============================================================================

-- =============================================================================
-- LAYER 1 — No adm_* dependencies (references sys_*/sch_* only)
-- =============================================================================

CREATE TABLE IF NOT EXISTS `adm_admission_cycles` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT          COMMENT 'Primary key',
  `academic_session_id`   INT UNSIGNED        NOT NULL                         COMMENT 'FK → sch_org_academic_sessions_jnt.id; target academic year',
  `name`                  VARCHAR(100)        NOT NULL                         COMMENT 'e.g., "Main Admission 2026-27"',
  `cycle_code`            VARCHAR(20)         NOT NULL                         COMMENT 'Unique cycle identifier e.g., ADM-2627-M',
  `start_date`            DATE                NOT NULL                         COMMENT 'Enquiry open date',
  `end_date`              DATE                NOT NULL                         COMMENT 'Enquiry close date; must be > start_date',
  `application_fee`       DECIMAL(10,2)       NOT NULL DEFAULT 0.00            COMMENT 'Application processing fee in INR',
  `admission_no_format`   VARCHAR(100)        NULL     DEFAULT '{YEAR}/{SEQ}'  COMMENT 'Admission number template; applied during enrollment',
  `sibling_bonus_score`   TINYINT UNSIGNED    NOT NULL DEFAULT 5               COMMENT 'Merit score bonus for confirmed sibling applicants',
  `age_rules_json`        JSON                NULL                             COMMENT 'Min/max age per class on cut-off date e.g., {"1":{"min":5,"max":7}}',
  `refund_policy_json`    JSON                NULL                             COMMENT 'Refund % tiers by days since payment e.g., {"7":100,"30":50,"999":0}',
  `application_form_url`  VARCHAR(255)        NULL                             COMMENT 'Public form slug e.g., "admission-2627"; used in /apply/{slug}',
  `status`                ENUM('Draft','Active','Closed','Archived')
                                              NOT NULL DEFAULT 'Draft'         COMMENT 'Lifecycle: Draft → Active → Closed → Archived; only one Active per academic_session_id',
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1               COMMENT 'Soft enable/disable',
  `created_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — creator',
  `updated_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — last editor',
  `created_at`            TIMESTAMP           NULL                             COMMENT 'Record creation timestamp',
  `updated_at`            TIMESTAMP           NULL                             COMMENT 'Record update timestamp',
  `deleted_at`            TIMESTAMP           NULL                             COMMENT 'Soft delete timestamp; NULL = not deleted',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_cyc_code` (`cycle_code`),
  KEY `idx_adm_cyc_session`    (`academic_session_id`),
  KEY `idx_adm_cyc_status`     (`status`),
  CONSTRAINT `fk_adm_cyc_session_id`
    FOREIGN KEY (`academic_session_id`)
    REFERENCES `sch_org_academic_sessions_jnt` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Annual admission cycle configuration — one per academic year per school';

-- =============================================================================
-- LAYER 2 — Depends on adm_admission_cycles + sch_classes
-- =============================================================================

CREATE TABLE IF NOT EXISTS `adm_document_checklist` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT          COMMENT 'Primary key',
  `admission_cycle_id`    BIGINT UNSIGNED     NULL                             COMMENT 'FK → adm_admission_cycles; NULL = global template row (is_system=1)',
  `class_id`              INT UNSIGNED        NULL                             COMMENT 'FK → sch_classes; NULL = applies to all classes in cycle',
  `document_name`         VARCHAR(100)        NOT NULL                         COMMENT 'e.g., "Birth Certificate"',
  `document_code`         VARCHAR(30)         NOT NULL                         COMMENT 'e.g., "BIRTH_CERT" — used for programmatic lookup',
  `is_mandatory`          TINYINT(1)          NOT NULL DEFAULT 1               COMMENT '1 = must be uploaded before application can be verified (BR-ADM-007)',
  `is_system`             TINYINT(1)          NOT NULL DEFAULT 0               COMMENT '1 = seeded default template row; 0 = admin-created',
  `accepted_formats`      VARCHAR(100)        NOT NULL DEFAULT 'pdf,jpg,png'   COMMENT 'Comma-separated accepted file extensions',
  `max_size_kb`           INT UNSIGNED        NOT NULL DEFAULT 5120            COMMENT 'Maximum upload file size in KB; default 5 MB',
  `sort_order`            TINYINT UNSIGNED    NOT NULL DEFAULT 0               COMMENT 'Display order in document checklist UI',
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1               COMMENT 'Soft enable/disable',
  `created_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — creator',
  `updated_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — last editor',
  `created_at`            TIMESTAMP           NULL                             COMMENT 'Record creation timestamp',
  `updated_at`            TIMESTAMP           NULL                             COMMENT 'Record update timestamp',
  `deleted_at`            TIMESTAMP           NULL                             COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_adm_chk_cycle`  (`admission_cycle_id`),
  KEY `idx_adm_chk_class`  (`class_id`),
  CONSTRAINT `fk_adm_chk_cycle_id`
    FOREIGN KEY (`admission_cycle_id`)
    REFERENCES `adm_admission_cycles` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_chk_class_id`
    FOREIGN KEY (`class_id`)
    REFERENCES `sch_classes` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Required document definitions per admission cycle; NULL cycle_id = global template';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `adm_quota_config` (
  `id`                        BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT      COMMENT 'Primary key',
  `admission_cycle_id`        BIGINT UNSIGNED     NOT NULL                     COMMENT 'FK → adm_admission_cycles',
  `class_id`                  INT UNSIGNED        NOT NULL                     COMMENT 'FK → sch_classes',
  `quota_type`                ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS')
                                                  NOT NULL                     COMMENT 'Quota category',
  `total_seats`               SMALLINT UNSIGNED   NOT NULL                     COMMENT 'Total seats for this quota in this class',
  `reserved_seats`            SMALLINT UNSIGNED   NOT NULL DEFAULT 0           COMMENT 'RTE mandated minimum (e.g., 25% for RTE)',
  `application_fee_waiver`    TINYINT(1)          NOT NULL DEFAULT 0           COMMENT '1 = application fee waived for this quota (e.g., RTE, EWS)',
  `is_active`                 TINYINT(1)          NOT NULL DEFAULT 1           COMMENT 'Soft enable/disable',
  `created_by`                BIGINT UNSIGNED     NOT NULL                     COMMENT 'sys_users.id — creator',
  `updated_by`                BIGINT UNSIGNED     NOT NULL                     COMMENT 'sys_users.id — last editor',
  `created_at`                TIMESTAMP           NULL                         COMMENT 'Record creation timestamp',
  `updated_at`                TIMESTAMP           NULL                         COMMENT 'Record update timestamp',
  `deleted_at`                TIMESTAMP           NULL                         COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_adm_qcfg_cycle_class` (`admission_cycle_id`, `class_id`),
  KEY `idx_adm_qcfg_quota`       (`quota_type`),
  CONSTRAINT `fk_adm_qcfg_cycle_id`
    FOREIGN KEY (`admission_cycle_id`)
    REFERENCES `adm_admission_cycles` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_qcfg_class_id`
    FOREIGN KEY (`class_id`)
    REFERENCES `sch_classes` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Quota type settings per class per admission cycle (fee waiver, reserved seats)';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `adm_seat_capacity` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT          COMMENT 'Primary key',
  `admission_cycle_id`    BIGINT UNSIGNED     NOT NULL                         COMMENT 'FK → adm_admission_cycles',
  `class_id`              INT UNSIGNED        NOT NULL                         COMMENT 'FK → sch_classes',
  `quota_type`            ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS')
                                              NOT NULL                         COMMENT 'Quota category for this seat budget',
  `total_seats`           SMALLINT UNSIGNED   NOT NULL                         COMMENT 'Configured total seat budget for this quota + class',
  `seats_allotted`        SMALLINT UNSIGNED   NOT NULL DEFAULT 0               COMMENT 'Running count; incremented by MeritListService::allotSeat() (BR-ADM-013)',
  `seats_enrolled`        SMALLINT UNSIGNED   NOT NULL DEFAULT 0               COMMENT 'Running count; incremented by EnrollmentService::enrollStudent()',
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1               COMMENT 'Soft enable/disable',
  `created_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — creator',
  `updated_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — last editor',
  `created_at`            TIMESTAMP           NULL                             COMMENT 'Record creation timestamp',
  `updated_at`            TIMESTAMP           NULL                             COMMENT 'Record update timestamp',
  `deleted_at`            TIMESTAMP           NULL                             COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_sc_cycle_class_quota` (`admission_cycle_id`, `class_id`, `quota_type`),
  KEY `idx_adm_sc_cycle`   (`admission_cycle_id`),
  KEY `idx_adm_sc_class`   (`class_id`),
  CONSTRAINT `fk_adm_sc_cycle_id`
    FOREIGN KEY (`admission_cycle_id`)
    REFERENCES `adm_admission_cycles` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_sc_class_id`
    FOREIGN KEY (`class_id`)
    REFERENCES `sch_classes` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-class per-quota seat budget with running allotted/enrolled counters';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `adm_entrance_tests` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT          COMMENT 'Primary key',
  `admission_cycle_id`    BIGINT UNSIGNED     NOT NULL                         COMMENT 'FK → adm_admission_cycles',
  `class_id`              INT UNSIGNED        NOT NULL                         COMMENT 'FK → sch_classes; warning emitted if class ordinal ≤ 2 (NEP 2020, BR-ADM-011)',
  `test_name`             VARCHAR(100)        NOT NULL                         COMMENT 'e.g., "Aptitude Test - Class 3"',
  `test_date`             DATE                NOT NULL                         COMMENT 'Date of test',
  `start_time`            TIME                NOT NULL                         COMMENT 'Test start time; must be < end_time',
  `end_time`              TIME                NOT NULL                         COMMENT 'Test end time; must be > start_time',
  `venue`                 VARCHAR(100)        NULL                             COMMENT 'Test venue / room description',
  `max_marks`             DECIMAL(6,2)        NOT NULL                         COMMENT 'Maximum marks for the test',
  `passing_marks`         DECIMAL(6,2)        NULL                             COMMENT 'Minimum passing marks; NULL = no pass/fail threshold',
  `subjects_json`         JSON                NULL                             COMMENT 'Subject areas with individual max marks e.g., [{"name":"Maths","max":50}]',
  `status`                ENUM('Scheduled','Completed','Cancelled')
                                              NOT NULL DEFAULT 'Scheduled'     COMMENT 'Test lifecycle status',
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1               COMMENT 'Soft enable/disable',
  `created_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — creator',
  `updated_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — last editor',
  `created_at`            TIMESTAMP           NULL                             COMMENT 'Record creation timestamp',
  `updated_at`            TIMESTAMP           NULL                             COMMENT 'Record update timestamp',
  `deleted_at`            TIMESTAMP           NULL                             COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_adm_et_cycle_class` (`admission_cycle_id`, `class_id`),
  KEY `idx_adm_et_date`        (`test_date`),
  KEY `idx_adm_et_status`      (`status`),
  CONSTRAINT `fk_adm_et_cycle_id`
    FOREIGN KEY (`admission_cycle_id`)
    REFERENCES `adm_admission_cycles` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_et_class_id`
    FOREIGN KEY (`class_id`)
    REFERENCES `sch_classes` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Entrance/aptitude test sessions per class per admission cycle';

-- =============================================================================
-- LAYER 3 — Depends on Layer 1 + cross-module (std_students, sys_users)
-- =============================================================================

CREATE TABLE IF NOT EXISTS `adm_enquiries` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT          COMMENT 'Primary key',
  `admission_cycle_id`    BIGINT UNSIGNED     NOT NULL                         COMMENT 'FK → adm_admission_cycles',
  `enquiry_no`            VARCHAR(20)         NOT NULL                         COMMENT 'Auto-generated unique number: ENQ-YYYY-NNNNN',
  `student_name`          VARCHAR(100)        NOT NULL                         COMMENT 'Prospective student full name',
  `student_dob`           DATE                NULL                             COMMENT 'Date of birth; used for age eligibility check (BR-ADM-001)',
  `student_gender`        ENUM('Male','Female','Transgender','Other')
                                              NULL                             COMMENT 'Student gender',
  `class_sought_id`       INT UNSIGNED        NOT NULL                         COMMENT 'FK → sch_classes; class the student is applying for',
  `father_name`           VARCHAR(100)        NULL                             COMMENT 'Father name (informational)',
  `mother_name`           VARCHAR(100)        NULL                             COMMENT 'Mother name (informational)',
  `contact_name`          VARCHAR(100)        NOT NULL                         COMMENT 'Primary contact person name',
  `contact_mobile`        VARCHAR(15)         NOT NULL                         COMMENT 'Primary contact mobile; matched against std_guardians.mobile_no for sibling detection',
  `contact_email`         VARCHAR(100)        NULL                             COMMENT 'Primary contact email',
  `lead_source`           ENUM('Website','Walk-in','Campaign','Referral','Social_Media','Phone','Other')
                                              NOT NULL DEFAULT 'Walk-in'       COMMENT 'How the lead was captured',
  `status`                ENUM('New','Assigned','Contacted','Interested','Not_Interested','Callback','Converted','Duplicate')
                                              NOT NULL DEFAULT 'New'           COMMENT 'Lead CRM status',
  `counselor_id`          INT UNSIGNED        NULL                             COMMENT 'FK → sys_users.id; assigned admission counselor',
  `is_sibling_lead`       TINYINT(1)          NOT NULL DEFAULT 0               COMMENT '1 = auto-detected sibling (contact_mobile matches std_guardians.mobile_no)',
  `sibling_student_id`    INT UNSIGNED        NULL                             COMMENT 'FK → std_students.id; matched existing sibling student (nullable)',
  `is_duplicate`          TINYINT(1)          NOT NULL DEFAULT 0               COMMENT '1 = same mobile submitted twice in same cycle',
  `notes`                 TEXT                NULL                             COMMENT 'Staff or parent notes',
  `source_reference`      VARCHAR(100)        NULL                             COMMENT 'Campaign code or referral name',
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1               COMMENT 'Soft enable/disable',
  `created_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — creator',
  `updated_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — last editor',
  `created_at`            TIMESTAMP           NULL                             COMMENT 'Record creation timestamp',
  `updated_at`            TIMESTAMP           NULL                             COMMENT 'Record update timestamp',
  `deleted_at`            TIMESTAMP           NULL                             COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_enq_no`         (`enquiry_no`),
  KEY `idx_adm_enq_cycle`            (`admission_cycle_id`),
  KEY `idx_adm_enq_status`           (`status`),
  KEY `idx_adm_enq_counselor`        (`counselor_id`),
  KEY `idx_adm_enq_mobile`           (`contact_mobile`),
  KEY `idx_adm_enq_sibling`          (`sibling_student_id`),
  KEY `idx_adm_enq_class_sought`     (`class_sought_id`),
  CONSTRAINT `fk_adm_enq_cycle_id`
    FOREIGN KEY (`admission_cycle_id`)
    REFERENCES `adm_admission_cycles` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_enq_class_sought_id`
    FOREIGN KEY (`class_sought_id`)
    REFERENCES `sch_classes` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_enq_counselor_id`
    FOREIGN KEY (`counselor_id`)
    REFERENCES `sys_users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_enq_sibling_student_id`
    FOREIGN KEY (`sibling_student_id`)
    REFERENCES `std_students` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Raw leads captured online, walk-in, or via campaign; entry point to admission funnel';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `adm_merit_lists` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT          COMMENT 'Primary key',
  `admission_cycle_id`    BIGINT UNSIGNED     NOT NULL                         COMMENT 'FK → adm_admission_cycles',
  `class_id`              INT UNSIGNED        NOT NULL                         COMMENT 'FK → sch_classes',
  `quota_type`            ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS')
                                              NOT NULL                         COMMENT 'Quota for which this merit list is generated',
  `generated_at`          TIMESTAMP           NULL                             COMMENT 'Timestamp when generation completed; NULL = not yet generated',
  `generated_by`          INT UNSIGNED        NULL                             COMMENT 'FK → sys_users.id; staff who triggered generation',
  `status`                ENUM('Draft','Published','Finalized')
                                              NOT NULL DEFAULT 'Draft'         COMMENT 'Draft = working; Published = visible to parents; Finalized = allotments done',
  `criteria_json`         JSON                NULL                             COMMENT 'Scoring weightage: {"test_pct":40,"interview_pct":30,"academic_pct":30}; must sum to 100',
  `sibling_bonus_score`   TINYINT UNSIGNED    NOT NULL DEFAULT 5               COMMENT 'Bonus score for confirmed sibling applicants; copied from adm_admission_cycles at generation',
  `cutoff_score`          DECIMAL(6,2)        NULL                             COMMENT 'Minimum composite score; below cutoff → Rejected',
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1               COMMENT 'Soft enable/disable',
  `created_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — creator',
  `updated_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — last editor',
  `created_at`            TIMESTAMP           NULL                             COMMENT 'Record creation timestamp',
  `updated_at`            TIMESTAMP           NULL                             COMMENT 'Record update timestamp',
  `deleted_at`            TIMESTAMP           NULL                             COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_adm_ml_cycle_class_quota` (`admission_cycle_id`, `class_id`, `quota_type`),
  KEY `idx_adm_ml_status`            (`status`),
  KEY `idx_adm_ml_generated_by`      (`generated_by`),
  CONSTRAINT `fk_adm_ml_cycle_id`
    FOREIGN KEY (`admission_cycle_id`)
    REFERENCES `adm_admission_cycles` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_ml_class_id`
    FOREIGN KEY (`class_id`)
    REFERENCES `sch_classes` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_ml_generated_by`
    FOREIGN KEY (`generated_by`)
    REFERENCES `sys_users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Merit list header per cycle + class + quota with criteria configuration';

-- =============================================================================
-- LAYER 4 — Depends on Layer 3 + cross-module
-- =============================================================================

CREATE TABLE IF NOT EXISTS `adm_follow_ups` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT          COMMENT 'Primary key',
  `enquiry_id`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'FK → adm_enquiries',
  `follow_up_type`        ENUM('Call','Meeting','Email','SMS','Walk-in')
                                              NOT NULL                         COMMENT 'Type of follow-up activity',
  `scheduled_at`          DATETIME            NOT NULL                         COMMENT 'Scheduled date and time for follow-up',
  `completed_at`          DATETIME            NULL                             COMMENT 'Actual completion time; NULL = pending',
  `outcome`               ENUM('Pending','Interested','Not_Interested','Callback','Converted')
                                              NOT NULL DEFAULT 'Pending'       COMMENT 'Result of the follow-up',
  `notes`                 TEXT                NULL                             COMMENT 'Follow-up notes or remarks',
  `done_by`               INT UNSIGNED        NULL                             COMMENT 'FK → sys_users.id; staff who completed the follow-up',
  `reminder_sent`         TINYINT(1)          NOT NULL DEFAULT 0               COMMENT '1 = NTF reminder already dispatched before scheduled_at',
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1               COMMENT 'Soft enable/disable',
  `created_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — creator',
  `updated_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — last editor',
  `created_at`            TIMESTAMP           NULL                             COMMENT 'Record creation timestamp',
  `updated_at`            TIMESTAMP           NULL                             COMMENT 'Record update timestamp',
  `deleted_at`            TIMESTAMP           NULL                             COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_adm_fu_enquiry`     (`enquiry_id`),
  KEY `idx_adm_fu_scheduled`   (`scheduled_at`),
  KEY `idx_adm_fu_done_by`     (`done_by`),
  KEY `idx_adm_fu_outcome`     (`outcome`),
  CONSTRAINT `fk_adm_fu_enquiry_id`
    FOREIGN KEY (`enquiry_id`)
    REFERENCES `adm_enquiries` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_fu_done_by`
    FOREIGN KEY (`done_by`)
    REFERENCES `sys_users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Follow-up activity log per enquiry — calls, meetings, emails, SMS';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `adm_applications` (
  `id`                        BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT      COMMENT 'Primary key',
  `admission_cycle_id`        BIGINT UNSIGNED     NOT NULL                     COMMENT 'FK → adm_admission_cycles',
  `enquiry_id`                BIGINT UNSIGNED     NULL                         COMMENT 'FK → adm_enquiries; source enquiry if converted; NULL for direct applications',
  `application_no`            VARCHAR(20)         NOT NULL                     COMMENT 'Auto-generated unique: APP-YYYY-NNNNN',
  `class_applied_id`          INT UNSIGNED        NOT NULL                     COMMENT 'FK → sch_classes; class applied for',
  `quota_type`                ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS')
                                                  NOT NULL DEFAULT 'General'   COMMENT 'Quota selected by applicant',
  `is_sibling`                TINYINT(1)          NOT NULL DEFAULT 0           COMMENT '1 = staff-confirmed sibling; MUST be 1 for sibling merit bonus (BR-ADM-015)',
  `sibling_student_id`        INT UNSIGNED        NULL                         COMMENT 'FK → std_students.id; staff-confirmed sibling reference (nullable)',
  `is_staff_ward`             TINYINT(1)          NOT NULL DEFAULT 0           COMMENT '1 = parent is current staff member',
  -- Student Details
  `student_first_name`        VARCHAR(50)         NOT NULL                     COMMENT 'Student first name',
  `student_middle_name`       VARCHAR(50)         NULL                         COMMENT 'Student middle name',
  `student_last_name`         VARCHAR(50)         NULL                         COMMENT 'Student last name',
  `student_dob`               DATE                NOT NULL                     COMMENT 'Student date of birth',
  `student_gender`            ENUM('Male','Female','Transgender','Prefer Not to Say')
                                                  NOT NULL                     COMMENT 'Student gender',
  `student_religion`          VARCHAR(50)         NULL                         COMMENT 'Student religion',
  `student_caste_category`    ENUM('General','OBC','SC','ST','EWS','Other')
                                                  NULL                         COMMENT 'Caste/social category for quota verification',
  `student_nationality`       VARCHAR(50)         NULL     DEFAULT 'Indian'    COMMENT 'Student nationality',
  `student_mother_tongue`     VARCHAR(50)         NULL                         COMMENT 'Student mother tongue',
  `aadhar_no`                 VARCHAR(20)         NULL                         COMMENT 'Aadhar number; optional; uniqueness enforced at SERVICE LAYER ONLY (not DB UNIQUE)',
  `birth_cert_no`             VARCHAR(50)         NULL                         COMMENT 'Birth certificate number',
  `blood_group`               ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-','Unknown')
                                                  NULL                         COMMENT 'Blood group',
  `known_allergies`           TEXT                NULL                         COMMENT 'Known allergies (free text)',
  -- Previous School
  `prev_school_name`          VARCHAR(100)        NULL                         COMMENT 'Previous school name',
  `prev_class_passed`         VARCHAR(20)         NULL                         COMMENT 'Class passed at previous school e.g., "Class 5"',
  `prev_marks_percent`        DECIMAL(5,2)        NULL                         COMMENT 'Previous school marks %; used in merit composite score',
  `prev_tc_no`                VARCHAR(50)         NULL                         COMMENT 'Previous school transfer certificate number',
  -- Guardian Details
  `father_name`               VARCHAR(100)        NULL                         COMMENT 'Father full name',
  `father_mobile`             VARCHAR(15)         NULL                         COMMENT 'Father mobile number',
  `father_email`              VARCHAR(100)        NULL                         COMMENT 'Father email address',
  `father_occupation`         VARCHAR(100)        NULL                         COMMENT 'Father occupation',
  `mother_name`               VARCHAR(100)        NULL                         COMMENT 'Mother full name',
  `mother_mobile`             VARCHAR(15)         NULL                         COMMENT 'Mother mobile number',
  `mother_email`              VARCHAR(100)        NULL                         COMMENT 'Mother email address',
  `guardian_name`             VARCHAR(100)        NULL                         COMMENT 'Alternate guardian full name',
  `guardian_mobile`           VARCHAR(15)         NULL                         COMMENT 'Alternate guardian mobile',
  `guardian_relation`         VARCHAR(50)         NULL                         COMMENT 'Relation of alternate guardian to student',
  -- Address
  `address_line1`             VARCHAR(150)        NULL                         COMMENT 'Address line 1',
  `address_line2`             VARCHAR(150)        NULL                         COMMENT 'Address line 2',
  `city`                      VARCHAR(50)         NULL                         COMMENT 'City',
  `state`                     VARCHAR(50)         NULL                         COMMENT 'State',
  `pincode`                   VARCHAR(10)         NULL                         COMMENT 'PIN code',
  -- Fee
  `application_fee_paid`      TINYINT(1)          NOT NULL DEFAULT 0           COMMENT '1 = application fee confirmed; PAY webhook sets this',
  `application_fee_amount`    DECIMAL(10,2)       NULL                         COMMENT 'Application fee amount paid',
  `application_fee_date`      DATE                NULL                         COMMENT 'Date fee was paid',
  -- Interview
  `interview_scheduled_at`    DATETIME            NULL                         COMMENT 'Interview date and time',
  `interview_venue`           VARCHAR(100)        NULL                         COMMENT 'Interview venue / room',
  `interview_notes`           TEXT                NULL                         COMMENT 'Post-interview remarks by interviewer',
  `interview_score`           DECIMAL(5,2)        NULL                         COMMENT 'Interview score; used in merit composite calculation',
  -- Status
  `status`                    ENUM('Draft','Submitted','Under_Review','Verified','Shortlisted','Rejected','Waitlisted','Allotted','Enrolled','Withdrawn')
                                                  NOT NULL DEFAULT 'Draft'     COMMENT 'Application lifecycle status; all transitions logged to adm_application_stages',
  `rejection_reason`          TEXT                NULL                         COMMENT 'Reason for rejection; required when status = Rejected',
  `processed_by`              INT UNSIGNED        NULL                         COMMENT 'FK → sys_users.id; staff who last processed this application',
  `is_active`                 TINYINT(1)          NOT NULL DEFAULT 1           COMMENT 'Soft enable/disable',
  `created_by`                BIGINT UNSIGNED     NOT NULL                     COMMENT 'sys_users.id — creator',
  `updated_by`                BIGINT UNSIGNED     NOT NULL                     COMMENT 'sys_users.id — last editor',
  `created_at`                TIMESTAMP           NULL                         COMMENT 'Record creation timestamp',
  `updated_at`                TIMESTAMP           NULL                         COMMENT 'Record update timestamp',
  `deleted_at`                TIMESTAMP           NULL                         COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_app_no`         (`application_no`),
  -- NOTE: aadhar_no is NOT UNIQUE at DB level; service-layer uniqueness check only
  KEY `idx_adm_app_cycle`            (`admission_cycle_id`),
  KEY `idx_adm_app_status`           (`status`),
  KEY `idx_adm_app_class`            (`class_applied_id`),
  KEY `idx_adm_app_enquiry`          (`enquiry_id`),
  KEY `idx_adm_app_sibling`          (`sibling_student_id`),
  KEY `idx_adm_app_processed_by`     (`processed_by`),
  KEY `idx_adm_app_aadhar`           (`aadhar_no`),
  CONSTRAINT `fk_adm_app_cycle_id`
    FOREIGN KEY (`admission_cycle_id`)
    REFERENCES `adm_admission_cycles` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_enquiry_id`
    FOREIGN KEY (`enquiry_id`)
    REFERENCES `adm_enquiries` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_class_id`
    FOREIGN KEY (`class_applied_id`)
    REFERENCES `sch_classes` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_sibling_student_id`
    FOREIGN KEY (`sibling_student_id`)
    REFERENCES `std_students` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_processed_by`
    FOREIGN KEY (`processed_by`)
    REFERENCES `sys_users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Full admission application records — multi-step wizard data with status FSM';

-- =============================================================================
-- LAYER 5 — Depends on Layer 4 + adm_entrance_tests + adm_merit_lists
-- =============================================================================

CREATE TABLE IF NOT EXISTS `adm_application_documents` (
  `id`                        BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT      COMMENT 'Primary key',
  `application_id`            BIGINT UNSIGNED     NOT NULL                     COMMENT 'FK → adm_applications',
  `checklist_item_id`         BIGINT UNSIGNED     NOT NULL                     COMMENT 'FK → adm_document_checklist',
  `media_id`                  INT UNSIGNED        NOT NULL                     COMMENT 'FK → sys_media.id (INT UNSIGNED — sys_media uses INT not BIGINT)',
  `original_filename`         VARCHAR(255)        NOT NULL                     COMMENT 'Original uploaded filename',
  `verification_status`       ENUM('Pending','Verified','Rejected')
                                                  NOT NULL DEFAULT 'Pending'   COMMENT 'Document verification status; Rejected requires verification_remarks',
  `verification_remarks`      TEXT                NULL                         COMMENT 'Staff remarks; required if verification_status = Rejected',
  `verified_by`               INT UNSIGNED        NULL                         COMMENT 'FK → sys_users.id; staff who verified the document',
  `verified_at`               TIMESTAMP           NULL                         COMMENT 'Timestamp of verification',
  `is_physically_received`    TINYINT(1)          NOT NULL DEFAULT 0           COMMENT '1 = original physical document collected at front desk',
  `physical_received_at`      DATE                NULL                         COMMENT 'Date physical document was received',
  `is_active`                 TINYINT(1)          NOT NULL DEFAULT 1           COMMENT 'Soft enable/disable',
  `created_by`                BIGINT UNSIGNED     NOT NULL                     COMMENT 'sys_users.id — creator',
  `updated_by`                BIGINT UNSIGNED     NOT NULL                     COMMENT 'sys_users.id — last editor',
  `created_at`                TIMESTAMP           NULL                         COMMENT 'Record creation timestamp',
  `updated_at`                TIMESTAMP           NULL                         COMMENT 'Record update timestamp',
  `deleted_at`                TIMESTAMP           NULL                         COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_doc_app_checklist` (`application_id`, `checklist_item_id`),
  KEY `idx_adm_doc_app`            (`application_id`),
  KEY `idx_adm_doc_checklist`      (`checklist_item_id`),
  KEY `idx_adm_doc_media`          (`media_id`),
  KEY `idx_adm_doc_verified_by`    (`verified_by`),
  KEY `idx_adm_doc_vstatus`        (`verification_status`),
  CONSTRAINT `fk_adm_doc_application_id`
    FOREIGN KEY (`application_id`)
    REFERENCES `adm_applications` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_doc_checklist_id`
    FOREIGN KEY (`checklist_item_id`)
    REFERENCES `adm_document_checklist` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_doc_media_id`
    FOREIGN KEY (`media_id`)
    REFERENCES `sys_media` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_doc_verified_by`
    FOREIGN KEY (`verified_by`)
    REFERENCES `sys_users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Uploaded documents per application mapped to document checklist items';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `adm_application_stages` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT          COMMENT 'Primary key',
  `application_id`        BIGINT UNSIGNED     NOT NULL                         COMMENT 'FK → adm_applications',
  `from_status`           VARCHAR(50)         NOT NULL                         COMMENT 'Previous status value (free text to accommodate future statuses)',
  `to_status`             VARCHAR(50)         NOT NULL                         COMMENT 'New status value after transition',
  `remarks`               TEXT                NULL                             COMMENT 'Staff comment or system-generated reason for transition',
  `changed_by`            INT UNSIGNED        NULL                             COMMENT 'FK → sys_users.id; NULL = system-triggered transition',
  `changed_at`            TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of status change',
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1               COMMENT 'Soft enable/disable',
  `created_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — creator',
  `updated_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — last editor',
  `created_at`            TIMESTAMP           NULL                             COMMENT 'Record creation timestamp',
  `updated_at`            TIMESTAMP           NULL                             COMMENT 'Record update timestamp',
  `deleted_at`            TIMESTAMP           NULL                             COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_adm_stage_app`          (`application_id`),
  KEY `idx_adm_stage_changed_at`   (`changed_at`),
  KEY `idx_adm_stage_changed_by`   (`changed_by`),
  CONSTRAINT `fk_adm_stage_application_id`
    FOREIGN KEY (`application_id`)
    REFERENCES `adm_applications` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_stage_changed_by`
    FOREIGN KEY (`changed_by`)
    REFERENCES `sys_users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Immutable audit trail of every application status transition';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `adm_entrance_test_candidates` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT          COMMENT 'Primary key',
  `entrance_test_id`      BIGINT UNSIGNED     NOT NULL                         COMMENT 'FK → adm_entrance_tests',
  `application_id`        BIGINT UNSIGNED     NOT NULL                         COMMENT 'FK → adm_applications',
  `roll_no`               VARCHAR(20)         NULL                             COMMENT 'Test hall roll number; auto-generated on candidate list generation',
  `marks_obtained`        DECIMAL(6,2)        NULL                             COMMENT 'Total marks; NULL until marks entered after test',
  `result`                ENUM('Pass','Fail','Absent','Pending')
                                              NOT NULL DEFAULT 'Pending'       COMMENT 'Test result; Pending until marks entered',
  `subject_marks_json`    JSON                NULL                             COMMENT 'Per-subject breakdown e.g., [{"subject":"Maths","marks":45}]',
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1               COMMENT 'Soft enable/disable',
  `created_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — creator',
  `updated_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — last editor',
  `created_at`            TIMESTAMP           NULL                             COMMENT 'Record creation timestamp',
  `updated_at`            TIMESTAMP           NULL                             COMMENT 'Record update timestamp',
  `deleted_at`            TIMESTAMP           NULL                             COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_etc_test_app` (`entrance_test_id`, `application_id`),
  KEY `idx_adm_etc_test`       (`entrance_test_id`),
  KEY `idx_adm_etc_app`        (`application_id`),
  KEY `idx_adm_etc_result`     (`result`),
  CONSTRAINT `fk_adm_etc_test_id`
    FOREIGN KEY (`entrance_test_id`)
    REFERENCES `adm_entrance_tests` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_etc_application_id`
    FOREIGN KEY (`application_id`)
    REFERENCES `adm_applications` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Candidate registration and mark entry per entrance test session';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `adm_merit_list_entries` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT          COMMENT 'Primary key',
  `merit_list_id`         BIGINT UNSIGNED     NOT NULL                         COMMENT 'FK → adm_merit_lists',
  `application_id`        BIGINT UNSIGNED     NOT NULL                         COMMENT 'FK → adm_applications',
  `merit_rank`            SMALLINT UNSIGNED   NOT NULL                         COMMENT '1 = top-ranked applicant in this merit list',
  `composite_score`       DECIMAL(6,2)        NULL                             COMMENT 'Final composite score after sibling bonus; used for ranking',
  `entrance_score`        DECIMAL(6,2)        NULL                             COMMENT 'Weighted entrance test component score',
  `interview_score`       DECIMAL(6,2)        NULL                             COMMENT 'Weighted interview component score',
  `academic_score`        DECIMAL(6,2)        NULL                             COMMENT 'Weighted previous academic marks component score',
  `sibling_bonus_applied` TINYINT(1)          NOT NULL DEFAULT 0               COMMENT '1 = sibling bonus was added to composite_score (requires is_sibling=1)',
  `merit_status`          ENUM('Shortlisted','Waitlisted','Rejected')
                                              NOT NULL DEFAULT 'Shortlisted'   COMMENT 'Shortlisted = within seat count; Waitlisted = beyond; Rejected = below cutoff',
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1               COMMENT 'Soft enable/disable',
  `created_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — creator',
  `updated_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — last editor',
  `created_at`            TIMESTAMP           NULL                             COMMENT 'Record creation timestamp',
  `updated_at`            TIMESTAMP           NULL                             COMMENT 'Record update timestamp',
  `deleted_at`            TIMESTAMP           NULL                             COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_adm_mle_list`       (`merit_list_id`),
  KEY `idx_adm_mle_rank`       (`merit_list_id`, `merit_rank`),
  KEY `idx_adm_mle_app`        (`application_id`),
  KEY `idx_adm_mle_status`     (`merit_status`),
  KEY `idx_adm_mle_score`      (`composite_score`),
  CONSTRAINT `fk_adm_mle_merit_list_id`
    FOREIGN KEY (`merit_list_id`)
    REFERENCES `adm_merit_lists` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_mle_application_id`
    FOREIGN KEY (`application_id`)
    REFERENCES `adm_applications` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Individual applicant entries in a merit list with composite scores and ranking';

-- =============================================================================
-- LAYER 6 — Depends on Layer 5 + sch_sections, sch_org_academic_sessions_jnt
-- =============================================================================

CREATE TABLE IF NOT EXISTS `adm_allotments` (
  `id`                        BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT      COMMENT 'Primary key',
  `merit_list_entry_id`       BIGINT UNSIGNED     NOT NULL                     COMMENT 'FK → adm_merit_list_entries; source ranking record',
  `application_id`            BIGINT UNSIGNED     NOT NULL                     COMMENT 'FK → adm_applications',
  `admission_no`              VARCHAR(50)         NULL                         COMMENT 'Admission number; NULL until offer letter issued; format from adm_admission_cycles.admission_no_format',
  `allotted_class_id`         INT UNSIGNED        NOT NULL                     COMMENT 'FK → sch_classes; class allotted to applicant',
  `allotted_section_id`       INT UNSIGNED        NULL                         COMMENT 'FK → sch_sections; assigned at enrollment or manually; NULL before section assignment',
  `joining_date`              DATE                NULL                         COMMENT 'Expected joining date stated in offer letter',
  `offer_letter_media_id`     INT UNSIGNED        NULL                         COMMENT 'FK → sys_media.id (INT UNSIGNED); offer letter PDF stored in sys_media',
  `offer_issued_at`           TIMESTAMP           NULL                         COMMENT 'Timestamp when offer letter PDF was generated',
  `offer_expires_at`          DATE                NULL                         COMMENT 'Offer deadline; adm:expire-offers daily job checks this (BR-ADM-014)',
  `admission_fee_paid`        TINYINT(1)          NOT NULL DEFAULT 0           COMMENT '1 = admission fee confirmed; required before enrollment (BR-ADM-002)',
  `admission_fee_amount`      DECIMAL(10,2)       NULL                         COMMENT 'Admission fee amount paid',
  `admission_fee_date`        DATE                NULL                         COMMENT 'Date admission fee was paid',
  `status`                    ENUM('Offered','Accepted','Declined','Expired','Enrolled','Withdrawn')
                                                  NOT NULL DEFAULT 'Offered'   COMMENT 'Allotment offer lifecycle status',
  `enrolled_student_id`       INT UNSIGNED        NULL                         COMMENT 'FK → std_students.id (INT UNSIGNED); SET ON ENROLLMENT by EnrollmentService::enrollStudent()',
  `is_active`                 TINYINT(1)          NOT NULL DEFAULT 1           COMMENT 'Soft enable/disable',
  `created_by`                BIGINT UNSIGNED     NOT NULL                     COMMENT 'sys_users.id — creator',
  `updated_by`                BIGINT UNSIGNED     NOT NULL                     COMMENT 'sys_users.id — last editor',
  `created_at`                TIMESTAMP           NULL                         COMMENT 'Record creation timestamp',
  `updated_at`                TIMESTAMP           NULL                         COMMENT 'Record update timestamp',
  `deleted_at`                TIMESTAMP           NULL                         COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_allot_admission_no` (`admission_no`),       -- nullable; MySQL allows multiple NULLs in UNIQUE
  KEY `idx_adm_allot_mle`              (`merit_list_entry_id`),
  KEY `idx_adm_allot_app`              (`application_id`),
  KEY `idx_adm_allot_status`           (`status`),
  KEY `idx_adm_allot_expires`          (`offer_expires_at`),
  KEY `idx_adm_allot_enrolled_student` (`enrolled_student_id`),
  KEY `idx_adm_allot_class`            (`allotted_class_id`),
  KEY `idx_adm_allot_section`          (`allotted_section_id`),
  KEY `idx_adm_allot_offer_media`      (`offer_letter_media_id`),
  CONSTRAINT `fk_adm_allot_mle_id`
    FOREIGN KEY (`merit_list_entry_id`)
    REFERENCES `adm_merit_list_entries` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_allot_application_id`
    FOREIGN KEY (`application_id`)
    REFERENCES `adm_applications` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_allot_class_id`
    FOREIGN KEY (`allotted_class_id`)
    REFERENCES `sch_classes` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_allot_section_id`
    FOREIGN KEY (`allotted_section_id`)
    REFERENCES `sch_sections` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_allot_offer_media_id`
    FOREIGN KEY (`offer_letter_media_id`)
    REFERENCES `sys_media` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_allot_enrolled_student_id`
    FOREIGN KEY (`enrolled_student_id`)
    REFERENCES `std_students` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Seat allotment records — bridge between merit list and enrollment; enrolled_student_id set on enrollment';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `adm_promotion_batches` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT          COMMENT 'Primary key',
  `from_session_id`       INT UNSIGNED        NOT NULL                         COMMENT 'FK → sch_org_academic_sessions_jnt.id; current academic session',
  `to_session_id`         INT UNSIGNED        NOT NULL                         COMMENT 'FK → sch_org_academic_sessions_jnt.id; next academic session',
  `from_class_id`         INT UNSIGNED        NOT NULL                         COMMENT 'FK → sch_classes; source class for promotion',
  `to_class_id`           INT UNSIGNED        NOT NULL                         COMMENT 'FK → sch_classes; destination class (same as from for detention)',
  `criteria_json`         JSON                NULL                             COMMENT 'Pass criteria config e.g., {"min_pass_pct":33,"use_exam_results":true}',
  `total_students`        INT UNSIGNED        NOT NULL DEFAULT 0               COMMENT 'Total students loaded into batch',
  `promoted_count`        INT UNSIGNED        NOT NULL DEFAULT 0               COMMENT 'Count updated on confirm',
  `detained_count`        INT UNSIGNED        NOT NULL DEFAULT 0               COMMENT 'Count updated on confirm',
  `status`                ENUM('Draft','Confirmed')
                                              NOT NULL DEFAULT 'Draft'         COMMENT 'Draft = in-progress; Confirmed = committed (idempotent re-run safe)',
  `processed_by`          INT UNSIGNED        NULL                             COMMENT 'FK → sys_users.id; staff who confirmed the batch',
  `processed_at`          TIMESTAMP           NULL                             COMMENT 'Timestamp when batch was confirmed',
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1               COMMENT 'Soft enable/disable',
  `created_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — creator',
  `updated_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — last editor',
  `created_at`            TIMESTAMP           NULL                             COMMENT 'Record creation timestamp',
  `updated_at`            TIMESTAMP           NULL                             COMMENT 'Record update timestamp',
  `deleted_at`            TIMESTAMP           NULL                             COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_adm_pb_from_session`        (`from_session_id`),
  KEY `idx_adm_pb_status`              (`from_session_id`, `from_class_id`, `status`),
  KEY `idx_adm_pb_to_session`          (`to_session_id`),
  KEY `idx_adm_pb_from_class`          (`from_class_id`),
  KEY `idx_adm_pb_to_class`            (`to_class_id`),
  KEY `idx_adm_pb_processed_by`        (`processed_by`),
  CONSTRAINT `fk_adm_pb_from_session_id`
    FOREIGN KEY (`from_session_id`)
    REFERENCES `sch_org_academic_sessions_jnt` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_pb_to_session_id`
    FOREIGN KEY (`to_session_id`)
    REFERENCES `sch_org_academic_sessions_jnt` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_pb_from_class_id`
    FOREIGN KEY (`from_class_id`)
    REFERENCES `sch_classes` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_pb_to_class_id`
    FOREIGN KEY (`to_class_id`)
    REFERENCES `sch_classes` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_pb_processed_by`
    FOREIGN KEY (`processed_by`)
    REFERENCES `sys_users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Year-end promotion batch header; Confirmed = committed; re-run idempotent via firstOrCreate';

-- =============================================================================
-- LAYER 7 — Depends on Layer 6 + sch_class_section_jnt
-- =============================================================================

CREATE TABLE IF NOT EXISTS `adm_withdrawals` (
  `id`                        BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT      COMMENT 'Primary key',
  `application_id`            BIGINT UNSIGNED     NOT NULL                     COMMENT 'FK → adm_applications',
  `allotment_id`              BIGINT UNSIGNED     NULL                         COMMENT 'FK → adm_allotments; set if withdrawn after allotment; NULL for pre-allotment withdrawal',
  `withdrawal_date`           DATE                NOT NULL                     COMMENT 'Date of withdrawal',
  `reason`                    ENUM('Personal','Financial','Relocation','School_Change','Medical','Other')
                                                  NOT NULL                     COMMENT 'Withdrawal reason',
  `remarks`                   TEXT                NULL                         COMMENT 'Additional remarks or context',
  `fee_paid_amount`           DECIMAL(10,2)       NOT NULL DEFAULT 0.00        COMMENT 'Total fees paid before withdrawal (application + admission fee)',
  `refund_eligible_amount`    DECIMAL(10,2)       NOT NULL DEFAULT 0.00        COMMENT 'Computed from adm_admission_cycles.refund_policy_json at withdrawal time',
  `refund_status`             ENUM('Not_Eligible','Pending','Approved','Paid')
                                                  NOT NULL DEFAULT 'Not_Eligible' COMMENT 'Not_Eligible = no fee paid or outside window; Pending → Approved → Paid',
  `refund_processed_at`       DATE                NULL                         COMMENT 'Date refund was processed',
  `processed_by`              INT UNSIGNED        NULL                         COMMENT 'FK → sys_users.id; finance staff who processed refund',
  `is_active`                 TINYINT(1)          NOT NULL DEFAULT 1           COMMENT 'Soft enable/disable',
  `created_by`                BIGINT UNSIGNED     NOT NULL                     COMMENT 'sys_users.id — creator',
  `updated_by`                BIGINT UNSIGNED     NOT NULL                     COMMENT 'sys_users.id — last editor',
  `created_at`                TIMESTAMP           NULL                         COMMENT 'Record creation timestamp',
  `updated_at`                TIMESTAMP           NULL                         COMMENT 'Record update timestamp',
  `deleted_at`                TIMESTAMP           NULL                         COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_adm_wd_app`             (`application_id`),
  KEY `idx_adm_wd_allotment`       (`allotment_id`),
  KEY `idx_adm_wd_refund_status`   (`refund_status`),
  KEY `idx_adm_wd_processed_by`    (`processed_by`),
  CONSTRAINT `fk_adm_wd_application_id`
    FOREIGN KEY (`application_id`)
    REFERENCES `adm_applications` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_wd_allotment_id`
    FOREIGN KEY (`allotment_id`)
    REFERENCES `adm_allotments` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_wd_processed_by`
    FOREIGN KEY (`processed_by`)
    REFERENCES `sys_users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Withdrawal recording with refund eligibility computation per cycle refund policy';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `adm_promotion_records` (
  `id`                        BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT      COMMENT 'Primary key',
  `promotion_batch_id`        BIGINT UNSIGNED     NOT NULL                     COMMENT 'FK → adm_promotion_batches',
  `student_id`                INT UNSIGNED        NOT NULL                     COMMENT 'FK → std_students.id',
  `from_class_section_id`     INT UNSIGNED        NOT NULL                     COMMENT 'FK → sch_class_section_jnt.id; source class+section',
  `to_class_section_id`       INT UNSIGNED        NULL                         COMMENT 'FK → sch_class_section_jnt.id; NULL if detained/left (no section assigned yet)',
  `new_roll_no`               SMALLINT UNSIGNED   NULL                         COMMENT 'Roll number in new class section; assigned by PromotionService::assignRollNumbers()',
  `result`                    ENUM('Promoted','Detained','Transferred','Alumni','Left')
                                                  NOT NULL                     COMMENT 'Promotion outcome; Detained = same class next session; Left = no new record',
  `remarks`                   TEXT                NULL                         COMMENT 'Manual override reason or LmsExam result summary',
  `is_active`                 TINYINT(1)          NOT NULL DEFAULT 1           COMMENT 'Soft enable/disable',
  `created_by`                BIGINT UNSIGNED     NOT NULL                     COMMENT 'sys_users.id — creator',
  `updated_by`                BIGINT UNSIGNED     NOT NULL                     COMMENT 'sys_users.id — last editor',
  `created_at`                TIMESTAMP           NULL                         COMMENT 'Record creation timestamp',
  `updated_at`                TIMESTAMP           NULL                         COMMENT 'Record update timestamp',
  `deleted_at`                TIMESTAMP           NULL                         COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_adm_pr_batch`           (`promotion_batch_id`),
  KEY `idx_adm_pr_student`         (`promotion_batch_id`, `student_id`),
  KEY `idx_adm_pr_student_id`      (`student_id`),
  KEY `idx_adm_pr_from_section`    (`from_class_section_id`),
  KEY `idx_adm_pr_to_section`      (`to_class_section_id`),
  CONSTRAINT `fk_adm_pr_batch_id`
    FOREIGN KEY (`promotion_batch_id`)
    REFERENCES `adm_promotion_batches` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_pr_student_id`
    FOREIGN KEY (`student_id`)
    REFERENCES `std_students` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_pr_from_class_section_id`
    FOREIGN KEY (`from_class_section_id`)
    REFERENCES `sch_class_section_jnt` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_pr_to_class_section_id`
    FOREIGN KEY (`to_class_section_id`)
    REFERENCES `sch_class_section_jnt` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-student promotion decision within a batch; supports Promoted/Detained/Left classifications';

-- =============================================================================
-- LAYER 8 — Depends on std_students (cross-module); may install in parallel
-- =============================================================================

CREATE TABLE IF NOT EXISTS `adm_transfer_certificates` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT          COMMENT 'Primary key',
  `student_id`            INT UNSIGNED        NOT NULL                         COMMENT 'FK → std_students.id',
  `tc_number`             VARCHAR(30)         NOT NULL                         COMMENT 'Unique TC number: TC-YYYY-NNN; unique per school-year',
  `issue_date`            DATE                NOT NULL                         COMMENT 'Date TC was issued',
  `leaving_date`          DATE                NOT NULL                         COMMENT 'Student last date at school',
  `class_at_leaving`      VARCHAR(30)         NOT NULL                         COMMENT 'Class at the time of leaving e.g., "Class 10-A"',
  `reason_for_leaving`    TEXT                NULL                             COMMENT 'Reason for leaving school',
  `conduct`               ENUM('Excellent','Good','Satisfactory','Poor')
                                              NOT NULL DEFAULT 'Good'          COMMENT 'Student conduct grade for TC',
  `destination_school`    VARCHAR(150)        NULL                             COMMENT 'School student is transferring to',
  `academic_status`       VARCHAR(100)        NULL                             COMMENT 'e.g., "Promoted to Class 9" or "Class 10 passed"',
  `fees_cleared`          TINYINT(1)          NOT NULL DEFAULT 0               COMMENT '1 = FIN module confirmed no outstanding balance (BR-ADM-004)',
  `is_duplicate`          TINYINT(1)          NOT NULL DEFAULT 0               COMMENT '1 = re-issue of lost/damaged TC',
  `original_tc_id`        BIGINT UNSIGNED     NULL                             COMMENT 'FK → adm_transfer_certificates.id (self-ref); reference for duplicate TC',
  `media_id`              INT UNSIGNED        NULL                             COMMENT 'FK → sys_media.id (INT UNSIGNED); TC PDF with QR code',
  `issued_by`             INT UNSIGNED        NULL                             COMMENT 'FK → sys_users.id; staff who issued the TC',
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1               COMMENT 'Soft enable/disable',
  `created_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — creator',
  `updated_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — last editor',
  `created_at`            TIMESTAMP           NULL                             COMMENT 'Record creation timestamp',
  `updated_at`            TIMESTAMP           NULL                             COMMENT 'Record update timestamp',
  `deleted_at`            TIMESTAMP           NULL                             COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_tc_number`    (`tc_number`),
  KEY `idx_adm_tc_student`         (`student_id`),
  KEY `idx_adm_tc_issue_date`      (`issue_date`),
  KEY `idx_adm_tc_original`        (`original_tc_id`),
  KEY `idx_adm_tc_media`           (`media_id`),
  KEY `idx_adm_tc_issued_by`       (`issued_by`),
  CONSTRAINT `fk_adm_tc_student_id`
    FOREIGN KEY (`student_id`)
    REFERENCES `std_students` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_tc_original_tc_id`
    FOREIGN KEY (`original_tc_id`)
    REFERENCES `adm_transfer_certificates` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_tc_media_id`
    FOREIGN KEY (`media_id`)
    REFERENCES `sys_media` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_tc_issued_by`
    FOREIGN KEY (`issued_by`)
    REFERENCES `sys_users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='TC issuance log with DomPDF + QR verification; original_tc_id for duplicate re-issue';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `adm_behavior_incidents` (
  `id`                        BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT      COMMENT 'Primary key',
  `student_id`                INT UNSIGNED        NOT NULL                     COMMENT 'FK → std_students.id; enrolled student involved',
  `incident_date`             DATE                NOT NULL                     COMMENT 'Date of incident',
  `incident_type`             ENUM('Bullying','Cheating','Disruption','Absenteeism','Vandalism','Violence','Misconduct','Other')
                                                  NOT NULL                     COMMENT 'Type of disciplinary incident',
  `severity`                  ENUM('Low','Medium','High','Critical')
                                                  NOT NULL                     COMMENT 'Critical = auto NTF dispatched to principal + parent',
  `description`               TEXT                NOT NULL                     COMMENT 'Detailed description of the incident',
  `location`                  VARCHAR(100)        NULL                         COMMENT 'Incident location e.g., "Classroom 5B", "Playground"',
  `witnesses_json`            JSON                NULL                         COMMENT 'Array of witness names e.g., ["Ravi Sharma","Priya Singh"]',
  `reported_by`               INT UNSIGNED        NULL                         COMMENT 'FK → sys_users.id; staff who logged the incident',
  `parent_notified`           TINYINT(1)          NOT NULL DEFAULT 0           COMMENT '1 = NTF auto-dispatched to parent (set for Critical severity)',
  `parent_notified_at`        TIMESTAMP           NULL                         COMMENT 'Timestamp of parent notification',
  `status`                    ENUM('Open','Action_Taken','Closed','Escalated')
                                                  NOT NULL DEFAULT 'Open'      COMMENT 'Incident resolution status',
  `behavior_score_impact`     TINYINT             NOT NULL DEFAULT 0           COMMENT 'Signed TINYINT (NOT UNSIGNED); negative value = score deduction e.g., -5 for Medium, -15 for Critical',
  `is_active`                 TINYINT(1)          NOT NULL DEFAULT 1           COMMENT 'Soft enable/disable',
  `created_by`                BIGINT UNSIGNED     NOT NULL                     COMMENT 'sys_users.id — creator',
  `updated_by`                BIGINT UNSIGNED     NOT NULL                     COMMENT 'sys_users.id — last editor',
  `created_at`                TIMESTAMP           NULL                         COMMENT 'Record creation timestamp',
  `updated_at`                TIMESTAMP           NULL                         COMMENT 'Record update timestamp',
  `deleted_at`                TIMESTAMP           NULL                         COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_adm_bi_student_date`    (`student_id`, `incident_date`),
  KEY `idx_adm_bi_severity`        (`severity`),
  KEY `idx_adm_bi_status`          (`status`),
  KEY `idx_adm_bi_reported_by`     (`reported_by`),
  CONSTRAINT `fk_adm_bi_student_id`
    FOREIGN KEY (`student_id`)
    REFERENCES `std_students` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_bi_reported_by`
    FOREIGN KEY (`reported_by`)
    REFERENCES `sys_users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Disciplinary incident log per enrolled student; Critical severity auto-notifies principal+parent';

-- =============================================================================
-- LAYER 9 — Depends on Layer 8 (adm_behavior_incidents)
-- =============================================================================

CREATE TABLE IF NOT EXISTS `adm_behavior_actions` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT          COMMENT 'Primary key',
  `incident_id`           BIGINT UNSIGNED     NOT NULL                         COMMENT 'FK → adm_behavior_incidents',
  `action_type`           ENUM('Warning','Detention','Suspension','Expulsion','Parent_Meeting','Counseling','Community_Service')
                                              NOT NULL                         COMMENT 'Corrective action type',
  `description`           TEXT                NULL                             COMMENT 'Details of the corrective action taken',
  `start_date`            DATE                NULL                             COMMENT 'Action start date (for Detention, Suspension)',
  `end_date`              DATE                NULL                             COMMENT 'Action end date; must be >= start_date',
  `parent_meeting_date`   DATETIME            NULL                             COMMENT 'Scheduled parent meeting date-time',
  `meeting_outcome`       TEXT                NULL                             COMMENT 'Outcome / notes from parent meeting',
  `action_by`             INT UNSIGNED        NULL                             COMMENT 'FK → sys_users.id; staff who took the action',
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1               COMMENT 'Soft enable/disable',
  `created_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — creator',
  `updated_by`            BIGINT UNSIGNED     NOT NULL                         COMMENT 'sys_users.id — last editor',
  `created_at`            TIMESTAMP           NULL                             COMMENT 'Record creation timestamp',
  `updated_at`            TIMESTAMP           NULL                             COMMENT 'Record update timestamp',
  `deleted_at`            TIMESTAMP           NULL                             COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_adm_ba_incident`        (`incident_id`),
  KEY `idx_adm_ba_action_by`       (`action_by`),
  KEY `idx_adm_ba_action_type`     (`action_type`),
  CONSTRAINT `fk_adm_ba_incident_id`
    FOREIGN KEY (`incident_id`)
    REFERENCES `adm_behavior_incidents` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_ba_action_by`
    FOREIGN KEY (`action_by`)
    REFERENCES `sys_users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Corrective actions taken per behavior incident; supports Warning through Expulsion';

-- =============================================================================
-- END OF ADM DDL — 20 tables total
-- Layer 1: adm_admission_cycles (1)
-- Layer 2: adm_document_checklist, adm_quota_config, adm_seat_capacity, adm_entrance_tests (4)
-- Layer 3: adm_enquiries, adm_merit_lists (2)
-- Layer 4: adm_follow_ups, adm_applications (2)
-- Layer 5: adm_application_documents, adm_application_stages,
--           adm_entrance_test_candidates, adm_merit_list_entries (4)
-- Layer 6: adm_allotments, adm_promotion_batches (2)
-- Layer 7: adm_withdrawals, adm_promotion_records (2)
-- Layer 8: adm_transfer_certificates, adm_behavior_incidents (2)
-- Layer 9: adm_behavior_actions (1)
-- Total: 20 ✓
-- =============================================================================
