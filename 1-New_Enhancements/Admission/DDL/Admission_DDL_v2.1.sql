-- ======================================================================================================================================
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
-- ======================================================================================================================================



-- ======================================================================================================================================
-- ADMISSION MASTERS
-- ======================================================================================================================================

	-- Generic master for dynamic status codes across modules
	CREATE TABLE IF NOT EXISTS `adm_admission_status_masters` (
		`id`            SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `key`           ENUM('adm_admission_cycles-status','adm_quota_config-quota_type','MeritList','MeritScoreConfig','Enquiry','FollowUps'),

		`list_type`   ENUM('AdmissionCycle-Status', 'QuotaConfig-QuotaType', 'MeritList-QuotaType', 'MeritList-Status','MeritScoreConfig-QuotaType', 
                         'Enquiry-LeadSource','Enquiry-FollowUpStage', 'FollowUps-Outcome', '', '','','','',
                         '','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','') NOT NULL,
		`code`          VARCHAR(20)     NOT NULL,  -- e.g. 'Available', 'Occupied', 'Maintenance'
		`name`          VARCHAR(100)    NOT NULL,  -- e.g. 'Available', 'Occupied', 'Under Maintenance'
		`is_active`     TINYINT(1)      NOT NULL DEFAULT 1,
		`created_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
		`updated_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		`deleted_at`    TIMESTAMP       NULL,
		PRIMARY KEY (`id`),
		UNIQUE KEY `uq_admission_key` (`key`),
		UNIQUE KEY `uq_admission_key` (`list_type`),
		UNIQUE KEY `uq_admission_key` (`key`,`code`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- Data seed :
     -- insert into `adm_admission_status_masters`(`status_type`, `code`, `name`, `is_active`, `created_at`, `updated_at`, `deleted_at`)
     -- values
     -- 
		-- Key                                 Status Type                        Code
		-- ---------------------------------   --------------------------------   ---------------------------------------------------------------
		-- 'adm_admission_cycles-status'     - 'AdmissionCycles-Status'         - 'Draft', 'Open', 'Closed', 'Archived'
		-- 'adm_admission_cycles-status'     - 'QuotaConfig-QuotaType'           - 'General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS'
		-- 'MeritLists-QuotaType'            - 'General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS'
    -- 'MeritLists-Status'               - 'Draft','Published','Finalized'
    -- 'MeritScoreConfig-QuotaType'      - 'General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS'
    -- 'Enquiry-LeadSource'              - 'Website','Walk-in','Campaign','Referral','Social_Media','Phone','Other'
    -- 'Enquiry-Status'                  - 'New','Assigned','Contacted','Interested','Not_Interested','Callback','Converted','Duplicate'
    -- 'Enquiry-FollowUpStage'           - 'New','Contacted','Meeting Scheduled','Demo Scheduled','Follow Up Scheduled','Converted','Not Interested'

		-- 'Application Status'           - 'Draft', 'Submitted', 'Approved', 'Rejected', 'Paid'
		-- 'Interview Status'             - 'Draft', 'Scheduled', 'Completed', 'Cancelled'
		-- 'Admission Status'             - 'Draft', 'Confirmed', 'Rejected', 'Cancelled'


-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- Annual admission cycle configuration — one per academic year per school
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_admission_cycles` (
  `id`                    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,          -- Primary key
  `academic_session_id`   SMALLINT UNSIGNED NOT NULL,                         -- FK → sch_org_academic_sessions_jnt.id; target academic year
  `name`                  VARCHAR(100)      NOT NULL,                         -- e.g., "Main Admission 2026-27"
  `cycle_code`            VARCHAR(20)       NOT NULL,                         -- Unique cycle identifier e.g., ADM-2627-M
  `start_date`            DATE              NOT NULL,                         -- Enquiry open date
  `end_date`              DATE              NOT NULL,                         -- Enquiry close date; must be > start_date
  `application_fee`       DECIMAL(10,2)     NOT NULL DEFAULT 0.00,            -- Application processing fee in INR
  `admission_no_format`   VARCHAR(100)      NULL     DEFAULT '{YEAR}/{SEQ}',  -- Admission number format used at the time of admission enrollment.
  `sibling_bonus_score`   TINYINT UNSIGNED  NOT NULL DEFAULT 5,               -- Merit score bonus for confirmed sibling applicants (Range 0-100)
  `age_cut_off_date`      DATE              NOT NULL,                         -- Age cut-off date for admission(i.e, For 2026-27 it is 31st December 2026)
  `age_rules_json`        JSON              NULL,                             -- Min/max age per class on cut-off date e.g., {"1":{"min":5,"max":7}}
  `refund_policy_json`    JSON              NULL,                             -- Refund % tiers by days since payment e.g., {"7":100,"30":50,"999":0}
  `application_form_url`  VARCHAR(255)      NULL,                             -- Public form slug e.g., "admission-2627"; used in /apply/{slug}
  `status`                SMALLINT UNSIGNED NOT NULL DEFAULT 'Draft',         -- FK to adm_admission_status_masters.id; Lifecycle: Draft → Active → Closed → Archived; only one Active per academic_session_id
  `is_active`             TINYINT(1)        NOT NULL DEFAULT 1,               -- Soft enable/disable
  `active_flag`           TINYINT(1)        NOT NULL DEFAULT 1,               -- Active flag - will be set to 1 when status is Open and is_active is 1, and will be set to 0 when status is Closed or is_active is 0
  `created_at`            TIMESTAMP         NULL,                             -- Record creation timestamp
  `updated_at`            TIMESTAMP         NULL,                             -- Record update timestamp
  `deleted_at`            TIMESTAMP         NULL,                             -- Soft delete timestamp; NULL = not deleted
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_cyc_code` (`cycle_code`),
  UNIQUE KEY `uq_adm_cyc_active` (`academic_session_id`, `is_active`),
  CONSTRAINT `fk_adm_cyc_session_id` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_cyc_status` FOREIGN KEY (`status`) REFERENCES `adm_admission_status_masters` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Annual admission cycle configuration — one per academic year per school';
-- Enhancement for V2:
-- - Can create child tables to capture refunc_policy & age_rules_json in seprate table with proper constraints and validation


-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- Required document definitions per admission cycle; NULL cycle_id = global template
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_document_checklist` (
  `id`                 MEDIUMINT UNSIGNED  NOT NULL AUTO_INCREMENT,       -- Primary key
  `admission_cycle_id` SMALLINT UNSIGNED  NULL,                           -- FK → adm_admission_cycles; NULL = global template row (is_system=1)
  `class_id`           INT UNSIGNED     NULL,                             -- FK → sch_classes; NULL = applies to all classes in cycle
  `document_name`      VARCHAR(100)     NOT NULL,                         -- e.g., "Birth Certificate"
  `document_code`      VARCHAR(30)      NOT NULL,                         -- e.g., "BIRTH_CERT" — used for programmatic lookup
  `is_mandatory`       TINYINT(1)       NOT NULL DEFAULT 1,               -- 1 = must be uploaded before application can be verified (BR-ADM-007)
  `is_system`          TINYINT(1)       NOT NULL DEFAULT 0,               -- 1 = seeded default template row; 0 = admin-created
  `accepted_formats`   VARCHAR(100)     NOT NULL DEFAULT 'pdf,jpg,png',   -- Comma-separated accepted file extensions
  `max_size_kb`        TINYINT UNSIGNED NOT NULL DEFAULT 2,               -- Maximum upload file size in MB; default 2 MB
  `sort_order`         TINYINT UNSIGNED NOT NULL DEFAULT 0,               -- Display order in document checklist UI (Drag & Drop, No UI Display)
  `is_active`          TINYINT(1)       NOT NULL DEFAULT 1,               -- Soft enable/disable
  `created_at`         TIMESTAMP        NULL,                             -- Record creation timestamp
  `updated_at`         TIMESTAMP        NULL,                             -- Record update timestamp
  `deleted_at`         TIMESTAMP        NULL,                             -- Soft delete timestamp
  PRIMARY KEY (`id`),
  KEY `idx_adm_chk_cycle`  (`admission_cycle_id`),
  KEY `idx_adm_chk_class`  (`class_id`),
  CONSTRAINT `fk_adm_chk_cycle_id` FOREIGN KEY (`admission_cycle_id`) REFERENCES `adm_admission_cycles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_chk_class_id` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Required document definitions per admission cycle; NULL cycle_id = global template';


-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- Seat capacity budgets per class per admission cycle — total allowed seats per quota
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_seat_capacity` (
  `id`                 SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT, -- Primary key
  `admission_cycle_id` SMALLINT UNSIGNED NOT NULL,             -- FK → adm_admission_cycles
  `class_id`           INT UNSIGNED NOT NULL,                -- FK → sch_classes
  --`quota_type`         ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS') NOT NULL, -- Quota category for this seat budget
  `total_seats`        SMALLINT UNSIGNED NOT NULL,           -- Configured total seat budget for this quota + class
  `occupied_seats`     SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- Seats which are already occupied by promoted student of lower class
  `available_seats`    SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- Seats available for admission for this admission cycle
  `seats_enrolled`     SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- Number of Application received against these seats
  `seats_offered`      SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- Number of Application approved & Offered seats for admission after entrance test.
  `seats_allotted`     SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- Number of Application accepted & Allotted seats against these seats
  `is_active`          TINYINT(1) NOT NULL DEFAULT 1,        -- Soft enable/disable
  `created_at`         TIMESTAMP NULL,                       -- Record creation timestamp
  `updated_at`         TIMESTAMP NULL,                       -- Record update timestamp
  `deleted_at`         TIMESTAMP NULL,                       -- Soft delete timestamp
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_sc_cycle_class` (`admission_cycle_id`, `class_id`),
  CONSTRAINT `fk_adm_sc_cycle_id` FOREIGN KEY (`admission_cycle_id`) REFERENCES `adm_admission_cycles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_sc_class_id` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Per-class per-quota seat budget with running allotted/enrolled counters';
-- Enhancement for V2:
-- Table `adm_quota_config` & `adm_seat_capacity` can be merged into 1.
--  - Only 2 field from Quota_config are required to be add into seat_capacity:
--    1. `reserved_seats`
--    2. `application_fee_waiver`


-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- Quota configuration per class per admission cycle — defines seat allocation per category (General, Management, RTE, NRI, etc.)
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_quota_config` (
  `id`                         SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,  -- Primary key
  `admission_cycle_id`         SMALLINT UNSIGNED NOT NULL,           -- FK → adm_admission_cycles
  `seat_capacity_id`           SMALLINT UNSIGNED NOT NULL,           -- FK → adm_seat_capacity
  `class_id`                   INT UNSIGNED NOT NULL,                -- FK → sch_classes
  `quota_type`                 SMALLINT UNSIGNED NOT NULL,           -- FK to adm_admission_status_masters.id; 'General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS'
  `reserved_seats_percentage`  DECIMAL(5,2) NOT NULL DEFAULT 0,      -- RTE mandated minimum (e.g., 25% for RTE)
  `reserved_seats_count`       SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- RTE mandated minimum (e.g., 25% for RTE)
  `application_fee_waiver`     TINYINT(1) NOT NULL DEFAULT 0,        -- 1 = application fee waived for this quota (e.g., RTE, EWS)
  `waiver_percentage`          DECIMAL(5,2) NOT NULL DEFAULT 0,      -- 0-100
  `is_active`                  TINYINT(1) NOT NULL DEFAULT 1,        -- Soft enable/disable
  `created_at`                 TIMESTAMP NULL,                       -- Record creation timestamp
  `updated_at`                 TIMESTAMP NULL,                       -- Record update timestamp
  `deleted_at`                 TIMESTAMP NULL,                       -- Soft delete timestamp
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_qcfg_cycle_class_quota` (`admission_cycle_id`, `class_id`,`quota_type`),
  CONSTRAINT `fk_adm_qcfg_cycle_id` FOREIGN KEY (`admission_cycle_id`) REFERENCES `adm_admission_cycles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_qcfg_capacity_id` FOREIGN KEY (`seat_capacity_id`) REFERENCES `adm_seat_capacity` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_qcfg_class_id` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_adm_qcfg_quota_type FOREIGN KEY (`quota_type`) REFERENCES `adm_quota_masters` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Quota type settings per class per admission cycle (fee waiver, reserved seats)';


-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- This table will capture and store the merit list. 
-- This list is generated based on the academic percentage, entrance test marks and interview marks.
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_merit_lists` (
  `id`                        SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT, -- Primary key
  `admission_cycle_id`        SMALLINT UNSIGNED NOT NULL,           -- FK → adm_admission_cycles
  `class_id`                  INT UNSIGNED NOT NULL,                -- FK → sch_classes
  `quota_type`                SMALLINT UNSIGNED NOT NULL,           -- FK to adm_admission_status_masters.id; 'General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS'
  -- Merit Score Weights
  `min_academic_score`        TINYINT UNSIGNED NOT NULL DEFAULT 0,  -- Minimum required Class Percentge
  `min_test_score`            TINYINT UNSIGNED NOT NULL DEFAULT 0,  -- Minimum required Test Score
  `min_interview_score`       TINYINT UNSIGNED NOT NULL DEFAULT 0,  -- Minimum required Interview Score
  `min_behavior_assess_score` TINYINT UNSIGNED NOT NULL DEFAULT 0,  -- Minimum required Behavior Assessment Score
  -- `sibling_bonus_score`    TINYINT UNSIGNED NOT NULL DEFAULT 5,  -- Bonus score for confirmed sibling applicants; copied from adm_admission_cycles at generation
  -- `total_score`            TINYINT UNSIGNED NOT NULL DEFAULT 0,  -- Total Score
  `total_cutoff_score`        TINYINT UNSIGNED NOT NULL DEFAULT 0,  -- Minimum composite score; below cutoff → Rejected
  `status`                    SMALLINT UNSIGNED NOT NULL,           -- FK → adm_admission_status_masters.id; Draft = working; Published = visible to parents; Finalized = allotments done
  `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,        -- Soft enable/disable
  `created_by`                INT UNSIGNED NULL,                    -- FK → sys_users.id; staff who triggered generation
  `created_at`                TIMESTAMP NULL,                       -- Record creation timestamp
  `updated_at`                TIMESTAMP NULL,                       -- Record update timestamp
  `deleted_at`                TIMESTAMP NULL,                       -- Soft delete timestamp
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_ml_cycle_class_quota` (`admission_cycle_id`, `class_id`, `quota_type`),
  KEY `idx_adm_ml_status` (`status`),
  CONSTRAINT `fk_adm_ml_cycle_id` FOREIGN KEY (`admission_cycle_id`) REFERENCES `adm_admission_cycles` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_ml_class_id` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_ml_quota_type` FOREIGN KEY (`quota_type`) REFERENCES `adm_admission_status_masters` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_ml_status` FOREIGN KEY (`status`) REFERENCES `adm_admission_status_masters` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Merit list header per cycle + class + quota with criteria configuration';

CREATE TABLE IF NOT EXISTS `adm_merit_score_config` (
  `id`                         SMALLINT UNSIGNED  NOT NULL AUTO_INCREMENT,    -- Primary key
  `admission_cycle_id`         SMALLINT UNSIGNED NOT NULL,        -- FK → adm_admission_cycles
  `class_id`                   INT UNSIGNED NOT NULL,             -- FK → sch_classes
  `quota_type`                 SMALLINT UNSIGNED NOT NULL,        -- FK → adm_admission_status_masters.id; 'General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS'
  `merit_list_id`              SMALLINT UNSIGNED NOT NULL,        -- FK → adm_merit_lists
  `academic_percentage_from`   DECIMAL(5,2) NOT NULL DEFAULT 0,   -- Academic Score From
  `academic_percentage_to`     DECIMAL(5,2) NOT NULL DEFAULT 0,   -- Academic Score To
  `academic_percentage_score`  DECIMAL(5,2) NOT NULL DEFAULT 0,   -- Academic Score Weightage
  `test_percentage_from`       DECIMAL(5,2) NOT NULL DEFAULT 0,   -- Test Score From
  `test_percentage_to`         DECIMAL(5,2) NOT NULL DEFAULT 0,   -- Test Score To
  `test_percentage_score`      DECIMAL(5,2) NOT NULL DEFAULT 0,   -- Test Score Weightage
  `interview_percentage_from`  DECIMAL(5,2) NOT NULL DEFAULT 0,   -- Interview Score From
  `interview_percentage_to`    DECIMAL(5,2) NOT NULL DEFAULT 0,   -- Interview Score To
  `interview_percentage_score` DECIMAL(5,2) NOT NULL DEFAULT 0,   -- Interview Score Weightage
  `is_active`                  TINYINT(1) NOT NULL DEFAULT 1,     -- Soft enable/disable
  `created_at`                 TIMESTAMP NULL,                    -- Record creation timestamp
  `updated_at`                 TIMESTAMP NULL,                    -- Record update timestamp
  `deleted_at`                 TIMESTAMP NULL,                    -- Soft delete timestamp
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_msc_cycle_class_quota` (`admission_cycle_id`, `class_id`, `quota_type`, `merit_list_id`),
  KEY `idx_adm_msc_merit_list_id` (`merit_list_id`),
  CONSTRAINT `fk_adm_msc_cycle_id` FOREIGN KEY (`admission_cycle_id`) REFERENCES `adm_admission_cycles` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_msc_class_id` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_msc_quota_type` FOREIGN KEY (`quota_type`) REFERENCES `adm_admission_status_masters` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_msc_merit_list_id` FOREIGN KEY (`merit_list_id`) REFERENCES `adm_merit_lists` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Merit list score calculation per application per merit list';




-- ==================================================================================================================================================
-- ADMISSION ENQUIRY & FOLLOW-UPs
-- ==================================================================================================================================================

-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- This table will store the enquiries for each class.
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_enquiries` (
  `id`                   MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT, -- 'Primary key',
  `admission_cycle_id`   SMALLINT UNSIGNED NOT NULL,         -- 'FK → adm_admission_cycles',
  `enquiry_no`           VARCHAR(20)     NOT NULL,           -- 'Auto-generated unique number: ENQ-YYYY-NNNNN',
  `student_name`         VARCHAR(100)    NOT NULL,           -- 'Prospective student full name',
  `student_dob`          DATE            NULL,               -- 'Date of birth; used for age eligibility check (BR-ADM-001)',
  `student_gender`       ENUM('Male','Female','Transgender','Other') NULL, -- 'Student gender',
  `class_sought_id`      INT UNSIGNED    NOT NULL,           -- 'FK → sch_classes; class the student is applying for',
  `father_name`          VARCHAR(100)    NULL,               -- 'Father name (informational)',
  `mother_name`          VARCHAR(100)    NULL,               -- 'Mother name (informational)',
  `contact_name`         VARCHAR(100)    NOT NULL,           -- 'Primary contact person name',
  `contact_mobile`       VARCHAR(15)     NOT NULL,           -- 'Primary contact mobile; matched against std_guardians.mobile_no for sibling detection',
  `contact_email`        VARCHAR(100)    NULL,               -- 'Primary contact email',
  `lead_source`          SMALLINT UNSIGNED NOT NULL,         -- FK → adm_admission_status_masters.id (status_type = 'Enquiry-LeadSource')
  `status`               SMALLINT UNSIGNED NOT NULL,         -- FK → adm_admission_status_masters.id (status_type = 'Enquiry-Status')
  `counselor_id`         INT UNSIGNED    NULL,               -- 'FK → sys_users.id; assigned admission counselor',
  `is_sibling_lead`      TINYINT(1)      NOT NULL DEFAULT 0, -- 1 = auto-detected sibling (contact_mobile matches std_guardians.mobile_no)
  `sibling_student_id`   INT UNSIGNED    NULL,               -- 'FK → std_students.id; matched existing sibling student (nullable)',
  `is_duplicate`         TINYINT(1)      NOT NULL DEFAULT 0, -- '1 = same mobile submitted twice in same cycle',
  `duplicate_enquiry_id` MEDIUMINT UNSIGNED NULL,            -- 'FK → Self (adm_enquiries.id); Filled only when is_duplicate=1 (nullable)',
  `notes`                TEXT            NULL,               -- 'Staff or parent notes',
  `source_reference`     VARCHAR(100)    NULL,               -- 'Campaign code or referral name',
  `next_follow_up_date`  DATETIME NULL,                      -- Cached from earliest pending adm_follow_ups.scheduled_at
  `last_contacted_at`    DATETIME NULL,                      -- Cached from latest completed adm_follow_ups.completed_at
  `lead_score`           TINYINT UNSIGNED DEFAULT 50,        -- 1 to 100 Lead Quality Score 
  `priority`             ENUM('Low','Medium','High','Urgent') NOT NULL DEFAULT 'Medium',  -- 
  `preferred_channel`    ENUM('Call','WhatsApp','Email','SMS') NOT NULL DEFAULT 'Call',
  `is_active`            TINYINT(1)      NOT NULL DEFAULT 1, -- 'Soft enable/disable',
  `created_at`           TIMESTAMP       NULL,               -- 'Record creation timestamp',
  `updated_at`           TIMESTAMP       NULL,               -- 'Record update timestamp',
  `deleted_at`           TIMESTAMP       NULL                -- 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_enq_no`         (`admission_cycle_id`,`enquiry_no`),
  KEY `idx_adm_enq_cycle`            (`admission_cycle_id`),
  KEY `idx_adm_enq_status`           (`status`),
  KEY `idx_adm_enq_counselor`        (`counselor_id`),
  KEY `idx_adm_enq_mobile`           (`contact_mobile`),
  KEY `idx_adm_enq_sibling`          (`sibling_student_id`),
  KEY `idx_adm_enq_class_sought`     (`class_sought_id`),
  KEY `idx_adm_enq_next_follow_up` (`next_follow_up_date`, `status`),
  KEY `idx_adm_enq_priority` (`priority`)
  CONSTRAINT `fk_adm_enq_cycle_id` FOREIGN KEY (`admission_cycle_id`) REFERENCES `adm_admission_cycles` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_enq_class_sought_id` FOREIGN KEY (`class_sought_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_enq_lead_source` FOREIGN KEY (`lead_source`) REFERENCES `adm_admission_status_masters` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_enq_status` FOREIGN KEY (`status`) REFERENCES `adm_admission_status_masters` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_enq_counselor_id` FOREIGN KEY (`counselor_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_enq_sibling_student_id` FOREIGN KEY (`sibling_student_id`) REFERENCES `std_students` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_enq_duplicate_id` FOREIGN KEY (`duplicate_enquiry_id`) REFERENCES `adm_enquiries` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Raw leads captured online, walk-in, or via campaign; entry point to admission funnel';


-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- This table will store the follow-up dates and status for a particular enquiry.
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_follow_ups` (
  `id`             MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT, -- Primary key
  `enquiry_id`     MEDIUMINT UNSIGNED NOT NULL,                -- FK → adm_enquiries
  `follow_up_type` ENUM('Call','Meeting','Email','SMS','Walk-in') NOT NULL, -- Type of follow-up activity
  `scheduled_at`   DATETIME        NOT NULL,                -- Scheduled date and time for follow-up
  `completed_at`   DATETIME        NULL,                    -- Actual completion time; NULL = pending
  `outcome`        ENUM('Pending','Interested','Not_Interested','Callback','Converted') NOT NULL DEFAULT 'Pending', -- Result of the follow-up
  `notes`          TEXT            NULL,                    -- Follow-up notes or remarks
  `done_by`        INT UNSIGNED    NULL,                    -- FK → sys_users.id; staff who completed the follow-up
  `reminder_sent`  TINYINT(1)      NOT NULL DEFAULT 0,        -- 1 = NTF reminder already dispatched before scheduled_at
  `is_active`      TINYINT(1)      NOT NULL DEFAULT 1,        -- Soft enable/disable
  `created_at`     TIMESTAMP       NULL,                    -- Record creation timestamp
  `updated_at`     TIMESTAMP       NULL,                    -- Record update timestamp
  `deleted_at`     TIMESTAMP       NULL,                    -- Soft delete timestamp
  PRIMARY KEY (`id`),
  KEY `idx_adm_fu_enquiry`     (`enquiry_id`),
  KEY `idx_adm_fu_scheduled`   (`scheduled_at`),
  KEY `idx_adm_fu_done_by`     (`done_by`),
  KEY `idx_adm_fu_outcome`     (`outcome`),
  CONSTRAINT `fk_adm_fu_enquiry_id` FOREIGN KEY (`enquiry_id`) REFERENCES `adm_enquiries` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_fu_done_by` FOREIGN KEY (`done_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Follow-up activity log per enquiry — calls, meetings, emails, SMS';



-- ==================================================================================================================================================
-- ENTRANCE TEST & SLOT ALLOCATION
-- ==================================================================================================================================================

-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- Entrance test schedule by class per admission cycle — defines test dates/times for different classes
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_entrance_tests` (
  `id`                       MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT, -- 'Primary key',
  `admission_cycle_id`       SMALLINT UNSIGNED NOT NULL,     -- 'FK → adm_admission_cycles',
  `class_id`                 INT UNSIGNED NOT NULL,        -- 'FK → sch_classes; warning emitted if class ordinal ≤ 2 (NEP 2020, BR-ADM-011)',
  `test_name`                VARCHAR(100) NOT NULL,        -- 'e.g., "Aptitude Test - Class 3"',
  `test_date`                DATE NOT NULL,                -- 'Date of test',
  `start_time`               TIME NOT NULL,                -- 'Test start time; must be < end_time',
  `end_time`                 TIME NOT NULL,                -- 'Test end time; must be > start_time',
  `venue`                    VARCHAR(100) NULL,            -- 'Test venue / room description',
  `test_type`                ENUM('Online','Offline','Both') NOT NULL DEFAULT 'Offline', -- 'Online or Offline',
  `online_test_link`         VARCHAR(255) NULL,            -- 'Online test link',
  `offline_test_media_id`    INT UNSIGNED NULL,            -- 'Offline test media id',
  `max_marks`                DECIMAL(6,2) NOT NULL,        -- 'Maximum marks for the test',
  `passing_marks`            DECIMAL(6,2) NULL,            -- 'Minimum passing marks; NULL = no pass/fail threshold',
  `subjects_json`            JSON NULL,                    -- 'Subject areas with individual max marks e.g., [{"name":"Maths","max":50}]',
  `status`                   ENUM('Scheduled','Completed','Cancelled') NOT NULL DEFAULT 'Scheduled', -- 'Test lifecycle status',
  `is_active`                TINYINT(1) NOT NULL DEFAULT 1, -- 'Soft enable/disable',
  `created_at`               TIMESTAMP NULL,               -- 'Record creation timestamp',
  `updated_at`               TIMESTAMP NULL,               -- 'Record update timestamp',
  `deleted_at`               TIMESTAMP NULL,               -- 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_adm_et_cycle_class` (`admission_cycle_id`, `class_id`),
  KEY `idx_adm_et_date`        (`test_date`),
  KEY `idx_adm_et_status`      (`status`),
  CONSTRAINT `fk_adm_et_cycle_id` FOREIGN KEY (`admission_cycle_id`) REFERENCES `adm_admission_cycles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_et_class_id` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_et_media_id` FOREIGN KEY (`offline_test_media_id`) REFERENCES `sys_media` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Entrance/aptitude test sessions per class per admission cycle';
-- Enhancement for V2:
--  - Entrance Test can be conducted online or offline. Add new Enum in `test_type`: 'Online','Offline'
--  - Add new field `test_link` in `adm_entrance_tests` table.
-- For `subjects_json` - Show only Compulsory Subjects of that Class and then user can select which subjects will be tested for the entrance test.


  -- -------------------------------------------------------------------------------------------------------------------------------
  -- This Table will define interview slots for a particular admission cycle and class.
  -- -------------------------------------------------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `adm_test_slots` (
    `id`                 MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `admission_cycle_id` SMALLINT UNSIGNED NOT NULL, -- FK → adm_admission_cycles
    `class_id`           INT UNSIGNED NOT NULL,      -- FK → sch_classes
    `slot_date`          DATE NOT NULL,
    `start_time`         TIME NOT NULL,
    `end_time`           TIME NOT NULL,
    `venue`              VARCHAR(100) NOT NULL,
    `panelist_ids_json`  JSON NULL,                  -- Array of sys_users.id
    `max_candidates`     TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `booked_candidates`  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `status`             ENUM('Available','Booked','Completed','Blocked','Cancelled') NOT NULL DEFAULT 'Available',
    `is_active`          TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`         INT UNSIGNED NOT NULL, -- FK → sys_users.id
    `created_at`         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`         TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`         TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_adm_int_slot_cycle_date_time` (`admission_cycle_id`, `class_id`, `slot_date`, `start_time`, `end_time`),
    KEY `idx_adm_int_slot_cycle` (`admission_cycle_id`, `class_id`, `slot_date`)
    CONSTRAINT `chk_adm_int_max_candidate_booked_candidates` CHECK (`booked_candidates` <= `max_candidates` AND `booked_candidates` >= 0),
    CONSTRAINT `chk_adm_int_slot_end_time` CHECK (`end_time` > `start_time`),
    CONSTRAINT `fk_adm_int_slot_cycle_id` FOREIGN KEY (`admission_cycle_id`) REFERENCES `adm_admission_cycles` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_adm_int_slot_class_id` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_adm_int_slot_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Bookable interview time slots and panel assignments';


-- -------------------------------------------------------------------------------------------------------------------------------
-- This Table will have all applications for a particular interview slot. when an interview slot is assigned to an applicant, 
-- the slot will be marked as `Booked` and `booked_at` should be updated. Also `booked_canddates` in `adm_interview_slots` table will be incremented.
-- If the `booked_candidates` = `max_candidates`, then the slot should be marked as `Full`, till then the status should be `Available`.
-- --------------------------------------------------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `adm_test_slot_items` (
    `id`                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `test_slot_id`           MEDIUMINT UNSIGNED NOT NULL, -- FK → adm_test_slots
    `test_candidate_id`      MEDIUMINT UNSIGNED NULL,     -- FK → adm_entrance_test_candidates
    `status`                 ENUM('Available', 'Booked', 'Cancelled', 'No-Show', 'Completed', 'Rescheduled') NOT NULL DEFAULT 'Available',
    `booked_at`              TIMESTAMP    NULL DEFAULT NULL,              -- when the booking was placed
    `attended`               tinyint(1)   DEFAULT NULL,                   -- 1=attended, 0=no-show, NULL=meeting hasn't happened yet
    `meeting_notes`          text         DEFAULT NULL,                   -- post-meeting notes captured by teacher
    -- Cancelled  Re-Scheduled
    `cancelled_at`           timestamp    NULL DEFAULT NULL,              -- when it was cancelled (NULL while CONFIRMED)
    `cancelled_by`           INT UNSIGNED NOT NULL,                       -- FK → sys_users.id
    `cancel_reason`          varchar(255) DEFAULT NULL,                   -- e.g. 'Parent unavailable'
    `rescheduled_at`         timestamp    NULL DEFAULT NULL,              -- when it was rescheduled
    `reschedule_by`          INT UNSIGNED NOT NULL,                       -- FK → sys_users.id
    `reschedule_reason`      varchar(255) DEFAULT NULL,                   -- e.g. 'Parent requested new time'
    `created_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `created_by`             INT UNSIGNED NOT NULL,                       -- FK → sys_users.id
    `updated_at`             TIMESTAMP NULL DEFAULT NULL,                  -- when last updated
    `deleted_at`             TIMESTAMP NULL DEFAULT NULL,                  -- when deleted
    PRIMARY KEY (`id`),
    INDEX `idx_adm_int_slot_item_app` (`test_candidate_id`, `test_slot_id`), -- Candidate can have only one entry per slot
    CONSTRAINT `fk_adm_int_slot_item_slot` FOREIGN KEY (`test_slot_id`) REFERENCES `adm_test_slots` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_adm_int_slot_item_cancelled_by` FOREIGN KEY (`cancelled_by`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_adm_int_slot_item_reschedule_by` FOREIGN KEY (`reschedule_by`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_adm_int_slot_item_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_adm_int_slot_item_test_candidate` FOREIGN KEY (`test_candidate_id`) REFERENCES `adm_entrance_test_candidates` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='List of applicants for each interview slot';


-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- This table will store the details of all the elligible candidate for the entrance tests that are conducted by the school.
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_entrance_test_candidates` (
  `id`                    MEDIUMINT UNSIGNED  NOT NULL AUTO_INCREMENT, -- Primary key
  `admission_cycle_id`    SMALLINT UNSIGNED   NOT NULL, -- FK → adm_admission_cycles
  `entrance_test_id`      MEDIUMINT UNSIGNED  NOT NULL, -- FK → adm_entrance_tests
  `entrance_test_slot_id` MEDIUMINT UNSIGNED  NOT NULL, -- FK → adm_entrance_test_slots
  `enquiry_id`            MEDIUMINT UNSIGNED  NOT NULL, -- FK → adm_enquiries
  `test_roll_no`          VARCHAR(20)         NULL,     -- Test hall roll number; auto-generated on candidate list generation
  `parent_comments`       text                DEFAULT NULL,   -- "Want to discuss math performance"
  -- Test Result Fields -- 
  `test_marks_obtained`   DECIMAL(6,2)        NULL, -- Total marks; NULL until marks entered after test
  `test_result`           ENUM('Pass','Fail','Absent','Pending') NOT NULL DEFAULT 'Pending', -- Test result; Pending until marks entered
  `subject_marks_json`    JSON                NULL, -- Per-subject breakdown e.g., [{"subject":"Maths","marks":45}]
  `test_media_id`         INT UNSIGNED        NULL, -- 'Student's Test paper media id',
  `test_checked_by`       INT UNSIGNED        NULL, -- FK → sys_users (Logged in User)
  `test_check_status`     ENUM('Pending','Checked') NOT NULL DEFAULT 'Pending', -- Check status
  `test_checked_at`       TIMESTAMP           NULL, -- Record update timestamp
  `test_remarks`          TEXT                NULL, -- 'Remarks/Notes on marks',
  `created_at`            TIMESTAMP           NULL, -- Record creation timestamp
  `updated_at`            TIMESTAMP           NULL, -- Record update timestamp
  `deleted_at`            TIMESTAMP           NULL, -- Soft delete timestamp
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_etc_test_app` (`entrance_test_id`, `enquiry_id`),
  KEY `idx_adm_etc_app`        (`enquiry_id`),
  KEY `idx_adm_etc_result`     (`result`),
  CONSTRAINT `fk_adm_etc_cycle_id` FOREIGN KEY (`admission_cycle_id`) REFERENCES `adm_admission_cycles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_etc_test_id` FOREIGN KEY (`entrance_test_id`) REFERENCES `adm_entrance_tests` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_etc_application_id` FOREIGN KEY (`enquiry_id`) REFERENCES `adm_enquiries` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_etc_test_media_id` FOREIGN KEY (`test_media_id`) REFERENCES `sys_media` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_etc_test_checked_by` FOREIGN KEY (`test_checked_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Candidate registration and mark entry per entrance test session';





-- ========================================================================================================================================================




-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- This table will store the behavior incidents for each class.
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_behavior_during_test` (
  `id`                        BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT, -- Primary key
  `test_candidate_id`         INT UNSIGNED        NOT NULL, -- FK → adm_entrance_tests_candidates
  `admission_cycle_id`       SMALLINT UNSIGNED NOT NULL,     -- 'FK → adm_admission_cycles',
  `application_id`        BIGINT UNSIGNED     NOT NULL, -- FK → adm_applications
  `test_id`                   INT UNSIGNED        NOT NULL, -- FK → adm_entrance_tests
  `test_slot_id`              INT UNSIGNED        NOT NULL, -- FK → adm_entrance_tests


  `incident_date`             DATE                NOT NULL, -- Date of incident
  `incident_type`             ENUM('Bullying','Cheating','Disruption','Absenteeism','Vandalism','Violence','Misconduct','Other') NOT NULL, -- Type of disciplinary incident
  `severity`                  ENUM('Low','Medium','High','Critical') NOT NULL, -- Critical = auto NTF dispatched to principal + parent
  `description`               TEXT                NOT NULL, -- Detailed description of the incident
  `location`                  VARCHAR(100)        NULL, -- Incident location e.g., "Classroom 5B", "Playground"
  `witnesses_json`            JSON                NULL, -- Array of witness names e.g., ["Ravi Sharma","Priya Singh"]
  `reported_by`               INT UNSIGNED        NULL, -- FK → sys_users.id; staff who logged the incident
  `parent_notified`           TINYINT(1)          NOT NULL DEFAULT 0, -- 1 = NTF auto-dispatched to parent (set for Critical severity)
  `parent_notified_at`        TIMESTAMP           NULL, -- Timestamp of parent notification
  `status`                    ENUM('Open','Action_Taken','Closed','Escalated') NOT NULL DEFAULT 'Open', -- Incident resolution status
  `behavior_score_impact`     TINYINT             NOT NULL DEFAULT 0, -- Signed TINYINT (NOT UNSIGNED); negative value = score deduction e.g., -5 for Medium, -15 for Critical
  `is_active`                 TINYINT(1)          NOT NULL DEFAULT 1, -- Soft enable/disable
  `created_by`                BIGINT UNSIGNED     NOT NULL, -- sys_users.id — creator
  `updated_by`                BIGINT UNSIGNED     NOT NULL, -- sys_users.id — last editor
  `created_at`                TIMESTAMP           NULL, -- Record creation timestamp
  `updated_at`                TIMESTAMP           NULL, -- Record update timestamp
  `deleted_at`                TIMESTAMP           NULL, -- Soft delete timestamp
  PRIMARY KEY (`id`),
  KEY `idx_adm_bi_student_date`    (`student_id`, `incident_date`),
  KEY `idx_adm_bi_severity`        (`severity`),
  KEY `idx_adm_bi_status`          (`status`),
  KEY `idx_adm_bi_reported_by`     (`reported_by`),
  CONSTRAINT `fk_adm_bi_student_id` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_bi_reported_by` FOREIGN KEY (`reported_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Disciplinary incident log per enrolled student; Critical severity auto-notifies principal+parent';

-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- This table will store the behavior actions for each incident.
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_behavior_actions` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT, -- Primary key
  `incident_id`           BIGINT UNSIGNED     NOT NULL, -- FK → adm_behavior_incidents
  `action_type`           ENUM('Warning','Detention','Suspension','Expulsion','Parent_Meeting','Counseling','Community_Service') NOT NULL, -- Corrective action type
  `description`           TEXT                NULL, -- Details of the corrective action taken
  `start_date`            DATE                NULL, -- Action start date (for Detention, Suspension)
  `end_date`              DATE                NULL, -- Action end date; must be >= start_date
  `parent_meeting_date`   DATETIME            NULL, -- Scheduled parent meeting date-time
  `meeting_outcome`       TEXT                NULL, -- Outcome / notes from parent meeting
  `action_by`             INT UNSIGNED        NULL, -- FK → sys_users.id; staff who took the action
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1, -- Soft enable/disable
  `created_by`            BIGINT UNSIGNED     NOT NULL, -- sys_users.id — creator
  `updated_by`            BIGINT UNSIGNED     NOT NULL, -- sys_users.id — last editor
  `created_at`            TIMESTAMP           NULL, -- Record creation timestamp
  `updated_at`            TIMESTAMP           NULL, -- Record update timestamp
  `deleted_at`            TIMESTAMP           NULL, -- Soft delete timestamp
  PRIMARY KEY (`id`),
  KEY `idx_adm_ba_incident`        (`incident_id`),
  KEY `idx_adm_ba_action_by`       (`action_by`),
  KEY `idx_adm_ba_action_type`     (`action_type`),
  CONSTRAINT `fk_adm_ba_incident_id` FOREIGN KEY (`incident_id`) REFERENCES `adm_behavior_incidents` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_ba_action_by` FOREIGN KEY (`action_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Corrective actions taken per behavior incident; supports Warning through Expulsion';



-- ==================================================================================================================================================
-- ENTRANCE TESTS RESULT & OFFERING ADMISSION
-- ==================================================================================================================================================

-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- This table will store the detail of Candidates who has been Shortlisted, Waitlisted and Rejected for an Admission Cycle and Class and Quota etc. 
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_merit_list_entries` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT, -- Primary key
  -- `merit_list_id`         BIGINT UNSIGNED     NOT NULL, -- FK → adm_merit_lists.id
  `application_id`        BIGINT UNSIGNED     NOT NULL, -- FK → adm_applications
  `merit_rank`            SMALLINT UNSIGNED   NOT NULL, -- 1 = top-ranked applicant in this merit list
  `composite_score`       DECIMAL(6,2)        NULL, -- Final composite score after sibling bonus; used for ranking
  `entrance_score`        DECIMAL(6,2)        NULL, -- Weighted entrance test component score
  `interview_score`       DECIMAL(6,2)        NULL, -- Weighted interview component score
  `academic_score`        DECIMAL(6,2)        NULL, -- Weighted previous academic marks component score
  `sibling_bonus_applied` TINYINT(1)          NOT NULL DEFAULT 0, -- 1 = sibling bonus was added to composite_score (requires is_sibling=1)
  `merit_status`          ENUM('Shortlisted','Waitlisted','Rejected') NOT NULL DEFAULT 'Shortlisted', -- Shortlisted = within seat count; Waitlisted = beyond; Rejected = below cutoff
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1, -- Soft enable/disable
  `created_at`            TIMESTAMP           NULL, -- Record creation timestamp
  `updated_at`            TIMESTAMP           NULL, -- Record update timestamp
  `deleted_at`            TIMESTAMP           NULL, -- Soft delete timestamp
  PRIMARY KEY (`id`),
  KEY `idx_adm_mle_list`       (`merit_list_id`),
  KEY `idx_adm_mle_rank`       (`merit_list_id`, `merit_rank`),
  KEY `idx_adm_mle_app`        (`application_id`),
  KEY `idx_adm_mle_status`     (`merit_status`),
  KEY `idx_adm_mle_score`      (`composite_score`),
  CONSTRAINT `fk_adm_mle_merit_list_id` FOREIGN KEY (`merit_list_id`) REFERENCES `adm_merit_lists` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_mle_application_id` FOREIGN KEY (`application_id`) REFERENCES `adm_applications` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Individual applicant entries in a merit list with composite scores and ranking';


CREATE TABLE IF NOT EXISTS `adm_test_score_summary` (
  `id`                 MEDIUMINT UNSIGNED  NOT NULL AUTO_INCREMENT,        -- Primary key
  `application_id`     INT UNSIGNED NOT NULL,                           -- FK → adm_applications
  `merit_list_id`      MEDIUMINT UNSIGNED NOT NULL,                    -- FK → adm_merit_lists
  `academic_score`     DECIMAL(5,2) NOT NULL DEFAULT 0,                -- Academic Score
  `test_score`         DECIMAL(5,2) NOT NULL DEFAULT 0,                -- Test Score
  `interview_score`    DECIMAL(5,2) NOT NULL DEFAULT 0,                -- Interview Score
  `total_score`               DECIMAL(5,2) NOT NULL DEFAULT 0,     -- Total Score
  `additional_criteria_json`  JSON NULL,                           -- Scoring weightage: {"test_pct":40,"interview_pct":30,"academic_pct":30}; must sum to 100
  `sibling_bonus_score`       TINYINT UNSIGNED NOT NULL DEFAULT 5, -- Bonus score for confirmed sibling applicants; copied from adm_admission_cycles at generation
  `cutoff_score`              DECIMAL(6,2) NULL,                   -- Minimum composite score; below cutoff → Rejected
  `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,       -- Soft enable/disable
  `created_at`                TIMESTAMP NULL,                      -- Record creation timestamp
  `updated_at`                TIMESTAMP NULL,                      -- Record update timestamp
  `deleted_at`                TIMESTAMP NULL,                      -- Soft delete timestamp
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_msc_application_id` (`application_id`),
  KEY `idx_adm_msc_merit_list_id`      (`merit_list_id`),
  CONSTRAINT `fk_adm_msc_application_id` FOREIGN KEY (`application_id`) REFERENCES `adm_applications` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_msc_merit_list_id` FOREIGN KEY (`merit_list_id`) REFERENCES `adm_merit_lists` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Merit list score calculation per application per merit list';



-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- This table will store the application details for a particular enquiry.
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_applications` (
  `id`                        MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `admission_cycle_id`        SMALLINT UNSIGNED NOT NULL, -- FK → adm_admission_cycles
  `enquiry_id`                MEDIUMINT UNSIGNED NULL,     -- FK → adm_enquiries; source enquiry if converted; NULL for direct applications
  `application_no`            VARCHAR(20) NOT NULL,     -- 'Auto-generated unique: APP-YYYY-NNNNN',
  `class_applied_id`          INT UNSIGNED NOT NULL,    -- FK → sch_classes; class applied for
  `quota_type`                ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS') NOT NULL DEFAULT 'General', -- 'Quota selected by applicant',
  `is_sibling`                TINYINT(1) NOT NULL DEFAULT 0, -- '1 = staff-confirmed sibling; MUST be 1 for sibling merit bonus (BR-ADM-015)',
  `sibling_student_id`        INT UNSIGNED NULL,             -- FK → std_students.id; staff-confirmed sibling reference (nullable),
  `is_staff_ward`             TINYINT(1) NOT NULL DEFAULT 0, -- '1 = parent is current staff member',
  -- Student Details
  `student_first_name`        VARCHAR(50) NOT NULL, -- 'Student first name',
  `student_middle_name`       VARCHAR(50) NULL,     -- 'Student middle name',
  `student_last_name`         VARCHAR(50) NULL,     -- 'Student last name',
  `student_dob`               DATE NOT NULL,        -- 'Student date of birth',
  `student_gender`            ENUM('Male','Female','Transgender','Prefer Not to Say') NOT NULL, -- 'Student gender',
  `student_religion_id`       INT UNSIGNED DEFAULT NULL,     -- 'Student religion', -- FK to sys_dropdown_table (Same as std_stundet_profiles.religion)
  `student_caste_category_id` INT UNSIGNED DEFAULT NULL, -- 'Caste/social category for quota verification', -- FK to sys_dropdown_table (Same as std_stundet_profiles.caste_category)
  `student_nationality_id`    INT UNSIGNED DEFAULT NULL, -- 'Student nationality', -- FK to sys_dropdown_table (Same as std_stundet_profiles.nationality)
  `student_mother_tongue_id`  INT UNSIGNED DEFAULT NULL, -- 'Student mother tongue', -- FK to sys_dropdown_table (Same as std_stundet_profiles.mother_tongue)
  `aadhar_no`                 VARCHAR(20) NULL, -- 'Aadhar number; optional; uniqueness enforced at SERVICE LAYER ONLY (not DB UNIQUE)',
  `apaar_id`                  VARCHAR(100) DEFAULT NULL, -- Academic Bank of Credits ID
  `birth_cert_no`             VARCHAR(50) NULL, -- 'Birth certificate number',
  `blood_group`               ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-','Unknown') NULL, -- 'Blood group',
  `known_allergies`           TEXT NULL, -- 'Known allergies (free text)',
  -- Previous School
  `prev_school_name`          VARCHAR(100) NULL, -- 'Previous school name',
  `prev_class_passed`         VARCHAR(20) NULL, -- 'Class passed at previous school e.g., "Class 5"',
  `prev_marks_percent`        DECIMAL(5,2) NULL, -- 'Previous school marks %; used in merit composite score',
  `prev_tc_no`                VARCHAR(50) NULL, -- 'Previous school transfer certificate number',
  -- Guardian Details
  `father_name`               VARCHAR(100) NULL, -- 'Father full name',
  `father_user_id`            INT UNSIGNED NULL, -- FK → std_students.id; if 'is_sibling' true then system will find parent id of sibling and populate here
  `father_mobile`             VARCHAR(15) NULL, -- 'Father mobile number',
  `father_email`              VARCHAR(100) NULL, -- 'Father email address',
  `father_occupation`         VARCHAR(100) NULL, -- 'Father occupation',
  `mother_name`               VARCHAR(100) NULL, -- 'Mother full name',
  `mother_user_id`            INT UNSIGNED NULL, -- FK → std_students.id; if 'is_sibling' true then system will find parent id of sibling and populate here
  `mother_mobile`             VARCHAR(15) NULL, -- 'Mother mobile number',
  `mother_email`              VARCHAR(100) NULL, -- 'Mother email address',
  `guardian_name`             VARCHAR(100) NULL, -- 'Alternate guardian full name',
  `guardian_mobile`           VARCHAR(15) NULL, -- 'Alternate guardian mobile',
  `guardian_relation`         VARCHAR(50) NULL, -- 'Relation of alternate guardian to student',
  -- Address
  `address_line1`             VARCHAR(150) NULL, -- 'Address line 1',
  `address_line2`             VARCHAR(150) NULL, -- 'Address line 2',
  `city`                      INT UNSIGNED DEFAULT NULL, -- FK to glb_cities
  `state`                     INT UNSIGNED DEFAULT NULL, -- FK to glb_states
  `pincode`                   VARCHAR(10) NULL, -- 'PIN code',
  -- Fee
  `application_fee_paid`      TINYINT(1) NOT NULL DEFAULT 0, -- '1 = application fee confirmed; PAY webhook sets this',
  `application_fee_amount`    DECIMAL(12,2) NULL, -- 'Application fee amount paid',
  `application_fee_date`      DATE NULL, -- 'Date fee was paid',
  -- StudntFee Module Details
  `fee_transactions_id`       INT UNSIGNED DEFAULT NULL, -- FK → fee_transactions.id
  `fee_receipts_id`           INT UNSIGNED DEFAULT NULL, -- FK → fee_receipts.id
  `fee_payment_gateway_logs_id` INT UNSIGNED DEFAULT NULL, -- FK → fee_payment_gateway_logs.id
  -- Interview
  `interview_scheduled_at`    DATETIME NULL, -- 'Interview date and time',
  `interview_venue`           VARCHAR(100) NULL, -- 'Interview venue / room',
  `interview_notes`           TEXT NULL, -- 'Post-interview remarks by interviewer',
  `interview_score`           DECIMAL(5,2) NULL, -- 'Interview score; used in merit composite calculation',
  -- Transport & Hostel
  `requires_transport`        TINYINT(1) NOT NULL DEFAULT 0,
  `pickup_drop_both`          ENUM('Pickup','Drop','Both') DEFAULT NULL, -- 'Pickup and drop both' or 'Pickup only' or 'Drop only'
  `pickup_location`           VARCHAR(150) NULL, -- 'Pickup location', -- Same as std_student_transport
  `drop_location`             VARCHAR(150) NULL, -- 'Drop location', -- Same as std_student_transport
  `requires_hostel`           TINYINT(1) NOT NULL DEFAULT 0,
  -- Status
  `status`                    ENUM('Draft','Submitted','Under_Review','Verified','Shortlisted','Rejected','Waitlisted','Allotted','Enrolled','Withdrawn') NOT NULL DEFAULT 'Draft', -- 'Application lifecycle status; all transitions logged to adm_application_stages_log',
  `rejection_reason`          TEXT NULL, -- 'Reason for rejection; required when status = Rejected',
  `processed_by`              INT UNSIGNED NULL, -- 'FK → sys_users.id; staff who last processed this application',
  `is_active`                 TINYINT(1) NOT NULL DEFAULT 1, -- 'Soft enable/disable',
  `created_at`                TIMESTAMP NULL, -- 'Record creation timestamp',
  `updated_at`                TIMESTAMP NULL, -- 'Record update timestamp',
  `deleted_at`                TIMESTAMP NULL, -- 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_app_no`(`application_no`),
  -- NOTE: aadhar_no is NOT UNIQUE at DB level; service-layer uniqueness check only
  KEY `idx_adm_app_cycle`(`admission_cycle_id`),
  KEY `idx_adm_app_status`(`status`),
  KEY `idx_adm_app_class`(`class_applied_id`),
  KEY `idx_adm_app_enquiry`(`enquiry_id`),
  KEY `idx_adm_app_sibling`(`sibling_student_id`),
  KEY `idx_adm_app_processed_by`(`processed_by`),
  CONSTRAINT `fk_adm_app_cycle_id` FOREIGN KEY (`admission_cycle_id`) REFERENCES `adm_admission_cycles` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_enquiry_id` FOREIGN KEY (`enquiry_id`) REFERENCES `adm_enquiries` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_class_id` FOREIGN KEY (`class_applied_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_sibling_student_id` FOREIGN KEY (`sibling_student_id`) REFERENCES `std_students` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_student_religion` FOREIGN KEY (`student_religion_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_student_caste_category` FOREIGN KEY (`student_caste_category_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_student_nationality` FOREIGN KEY (`student_nationality_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_student_mother_tongue` FOREIGN KEY (`student_mother_tongue_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_city_id` FOREIGN KEY (`city`) REFERENCES `glb_cities` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_state_id` FOREIGN KEY (`state`) REFERENCES `glb_states` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_processed_by` FOREIGN KEY (`processed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Full admission application records — multi-step wizard data with status FSM';
-- Conditions:
  -- Fee payment will be posted in Accounting Module also
  -- we need to capture Fee Payment ID from (Payment Module)
  -- If 'is_sibling' true then system will find parent id of sibling and populate (father_user_id, mother_user_id) from std_guardians table
  -- When status is selected as 'Enrolled' then this should transfer all the data to std_students and std_student_profiles table and move the user to 
  --     the Student Profile Screen to complete all the entries required to Register a New Student.
  --
  -- Changes for V2:
  -- Convert all Enums into FK to sys_dropdown_table
  -- Parents deciding on school admission invariably require school bus transport or boarding hostel facilities. 
  --   Capturing this early allows the school to evaluate bus route capacities before confirming admissions.
--


-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- This table will store the document details for a particular application.
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_application_documents` (
  `id`                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, -- 'Primary key',
  `application_id`         BIGINT UNSIGNED NOT NULL, -- 'FK → adm_applications',
  `checklist_item_id`      BIGINT UNSIGNED NOT NULL, -- 'FK → adm_document_checklist',
  `media_id`               INT UNSIGNED NOT NULL, -- 'FK → sys_media.id (INT UNSIGNED — sys_media uses INT not BIGINT)',
  `original_filename`      VARCHAR(255) NOT NULL, -- 'Original uploaded filename',
  `verification_status`    ENUM('Pending','Verified','Rejected') NOT NULL DEFAULT 'Pending', -- 'Document verification status; Rejected requires verification_remarks',
  `verification_remarks`   TEXT NULL, -- 'Staff remarks; required if verification_status = Rejected',
  `verified_by`            INT UNSIGNED NULL, -- 'FK → sys_users.id; staff who verified the document',
  `verified_at`            TIMESTAMP NULL, -- 'Timestamp of verification',
  `is_physically_received` TINYINT(1) NOT NULL DEFAULT 0, -- '1 = original physical document collected at front desk',
  `physically_received_at` DATE NULL, -- 'Date physical document was received',
  `physically_received_by` BIGINT UNSIGNED NULL, -- 'FK → sys_users.id; staff who verified the document',
  `is_active`              TINYINT(1) NOT NULL DEFAULT 1, -- 'Soft enable/disable',
  `created_at`             TIMESTAMP NULL, -- 'Record creation timestamp',
  `updated_at`             TIMESTAMP NULL, -- 'Record update timestamp',
  `deleted_at`             TIMESTAMP NULL, -- 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_doc_app_checklist` (`application_id`, `checklist_item_id`),
  KEY `idx_adm_doc_app`            (`application_id`),
  KEY `idx_adm_doc_checklist`      (`checklist_item_id`),
  KEY `idx_adm_doc_media`          (`media_id`),
  KEY `idx_adm_doc_verified_by`    (`verified_by`),
  KEY `idx_adm_doc_vstatus`        (`verification_status`),
  CONSTRAINT `fk_adm_doc_application_id` FOREIGN KEY (`application_id`) REFERENCES `adm_applications` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_doc_checklist_id` FOREIGN KEY (`checklist_item_id`) REFERENCES `adm_document_checklist` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_doc_media_id` FOREIGN KEY (`media_id`) REFERENCES `sys_media` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_doc_verified_by` FOREIGN KEY (`verified_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Uploaded documents per application mapped to document checklist items';


-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- If an uploaded certificate is rejected by the verification officer and the parent uploads a new scan, then older version should not be deleted but 
-- will be moved to adm_application_document_versions and current adm_application_documents should be updated with new version number and new media_id.
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_application_document_versions` (
  `id`                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_document_id` BIGINT UNSIGNED NOT NULL, -- FK → adm_application_documents
  `media_id`               INT UNSIGNED NOT NULL,    -- FK → sys_media.id
  `version_number`         TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `verification_status`    ENUM('Pending','Verified','Rejected') NOT NULL,
  `verification_remarks`   TEXT NULL,
  `verified_by`            INT UNSIGNED NULL,        -- FK → sys_users.id
  `verified_at`            TIMESTAMP NULL,
  `created_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_adm_doc_ver_parent` (`application_document_id`),
  CONSTRAINT `fk_adm_doc_ver_doc_id` FOREIGN KEY (`application_document_id`) REFERENCES `adm_application_documents` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Historical audit log of re-uploaded application documents';


-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- Immutable audit trail of every application status transition
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_application_stages_log` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, -- Primary key
  `application_id` BIGINT UNSIGNED NOT NULL, -- FK → adm_applications
  `from_status`    VARCHAR(50) NOT NULL, -- Previous status value (free text to accommodate future statuses)
  `to_status`      VARCHAR(50) NOT NULL, -- New status value after transition
  `remarks`        TEXT NULL, -- Staff comment or system-generated reason for transition
  `changed_by`     INT UNSIGNED NULL, -- FK → sys_users.id; NULL = system-triggered transition
  `changed_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at`     TIMESTAMP NULL, -- Record creation timestamp
  `updated_at`     TIMESTAMP NULL, -- Record update timestamp
  PRIMARY KEY (`id`),
  KEY `idx_adm_stage_app` (`application_id`),
  KEY `idx_adm_stage_changed_at` (`changed_at`),
  KEY `idx_adm_stage_changed_by` (`changed_by`),
  CONSTRAINT `fk_adm_stage_application_id` FOREIGN KEY (`application_id`) REFERENCES `adm_applications` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_stage_changed_by` FOREIGN KEY (`changed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Immutable audit trail of every application status transition';



-- ==================================================================================================================================================
-- ADMISSION OF NEW STUDENTS
-- ==================================================================================================================================================

-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- This table will store the allotments for each class.
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_allotments` (
  `id`                        BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT, -- Primary key
  `merit_list_entry_id`       BIGINT UNSIGNED     NOT NULL, -- FK → adm_merit_list_entries; source ranking record
  `application_id`            BIGINT UNSIGNED     NOT NULL, -- FK → adm_applications
  `admission_no`              VARCHAR(50)         NULL, -- Admission number; NULL until offer letter issued; format from adm_admission_cycles.admission_no_format
  `allotted_class_id`         INT UNSIGNED        NOT NULL, -- FK → sch_classes; class allotted to applicant
  `allotted_section_id`       INT UNSIGNED        NULL, -- FK → sch_sections; assigned at enrollment or manually; NULL before section assignment
  `joining_date`              DATE                NULL, -- Expected joining date stated in offer letter
  `offer_letter_media_id`     INT UNSIGNED        NULL, -- FK → sys_media.id (INT UNSIGNED); offer letter PDF stored in sys_media
  `offer_issued_at`           TIMESTAMP           NULL, -- Timestamp when offer letter PDF was generated
  `offer_expires_at`          DATE                NULL, -- Offer deadline; adm:expire-offers daily job checks this (BR-ADM-014)
  `admission_fee_paid`        TINYINT(1)          NOT NULL DEFAULT 0, -- 1 = admission fee confirmed; required before enrollment (BR-ADM-002)
  `admission_fee_amount`      DECIMAL(10,2)       NULL, -- Admission fee amount paid
  `admission_fee_date`        DATE                NULL, -- Date admission fee was paid
  `status`                    ENUM('Offered','Accepted','Declined','Expired','Enrolled','Withdrawn') NOT NULL DEFAULT 'Offered', -- Allotment offer lifecycle status
  `accepted_at`               TIMESTAMP           NULL, -- Accepted date of the Offer
  `declined_at`               TIMESTAMP           NULL, -- Declined date of the Offer
  `declined_reason`           TEXT                NULL, -- Declined reason by the Applicant
  `allotment_round`           TINYINT UNSIGNED    NOT NULL DEFAULT 1, -- Round 1, Round 2, Round 3 counseling
  `enrolled_student_id`       INT UNSIGNED        NULL, -- FK → std_students.id (INT UNSIGNED); SET ON ENROLLMENT by EnrollmentService::enrollStudent()
  `is_active`                 TINYINT(1)          NOT NULL DEFAULT 1, -- Soft enable/disable
  `created_at`                TIMESTAMP           NULL, -- Record creation timestamp
  `updated_at`                TIMESTAMP           NULL, -- Record update timestamp
  `deleted_at`                TIMESTAMP           NULL, -- Soft delete timestamp
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
  CONSTRAINT `fk_adm_allot_mle_id` FOREIGN KEY (`merit_list_entry_id`) REFERENCES `adm_merit_list_entries` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_allot_application_id` FOREIGN KEY (`application_id`) REFERENCES `adm_applications` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_allot_class_id` FOREIGN KEY (`allotted_class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_allot_section_id` FOREIGN KEY (`allotted_section_id`) REFERENCES `sch_sections` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_allot_offer_media_id` FOREIGN KEY (`offer_letter_media_id`) REFERENCES `sys_media` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_allot_enrolled_student_id` FOREIGN KEY (`enrolled_student_id`) REFERENCES `std_students` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Seat allotment records — bridge between merit list and enrollment; enrolled_student_id set on enrollment';


-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- This table will store the withdrawals for each class.
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_withdrawals` (
  `id`                        BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT, -- Primary key
  `application_id`            BIGINT UNSIGNED     NOT NULL, -- FK → adm_applications
  `allotment_id`              BIGINT UNSIGNED     NULL, -- FK → adm_allotments; set if withdrawn after allotment; NULL for pre-allotment withdrawal
  `withdrawal_date`           DATE                NOT NULL, -- Date of withdrawal
  `reason`                    ENUM('Personal','Financial','Relocation','School_Change','Medical','Other') NOT NULL, -- Withdrawal reason
  `remarks`                   TEXT                NULL, -- Additional remarks or context
  `fee_paid_amount`           DECIMAL(10,2)       NOT NULL DEFAULT 0.00, -- Total fees paid before withdrawal (application + admission fee)
  `refund_eligible_amount`    DECIMAL(10,2)       NOT NULL DEFAULT 0.00, -- Computed from adm_admission_cycles.refund_policy_json at withdrawal time
  `refund_status`             ENUM('Not_Eligible','Pending','Approved','Paid') NOT NULL DEFAULT 'Not_Eligible', -- Not_Eligible = no fee paid or outside window; Pending → Approved → Paid
  `refund_processed_at`       DATE                NULL, -- Date refund was processed
  `refund_mode`               ENUM('Bank_Transfer','Cheque','Payment_Gateway_Reversal','Cash') NULL,
  `refund_transaction_ref`    VARCHAR(100) NULL, -- Bank UTR number or gateway refund ID
  `beneficiary_name`          VARCHAR(100) NULL, -- Name of the beneficiary
  `bank_name`                 VARCHAR(100) NULL, -- Name of the bank
  `bank_account_no`           VARCHAR(30) NULL, -- Bank account number
  `bank_ifsc_code`            VARCHAR(15) NULL, -- IFSC code
  `processed_by`              INT UNSIGNED        NULL, -- FK → sys_users.id; finance staff who processed refund
  `is_active`                 TINYINT(1)          NOT NULL DEFAULT 1, -- Soft enable/disable
  `created_by`                BIGINT UNSIGNED     NOT NULL, -- sys_users.id — creator
  `updated_by`                BIGINT UNSIGNED     NOT NULL, -- sys_users.id — last editor
  `created_at`                TIMESTAMP           NULL, -- Record creation timestamp
  `updated_at`                TIMESTAMP           NULL, -- Record update timestamp
  `deleted_at`                TIMESTAMP           NULL, -- Soft delete timestamp
  PRIMARY KEY (`id`),
  KEY `idx_adm_wd_app`             (`application_id`),
  KEY `idx_adm_wd_allotment`       (`allotment_id`),
  KEY `idx_adm_wd_refund_status`   (`refund_status`),
  KEY `idx_adm_wd_processed_by`    (`processed_by`),
  CONSTRAINT `fk_adm_wd_application_id` FOREIGN KEY (`application_id`) REFERENCES `adm_applications` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_wd_allotment_id` FOREIGN KEY (`allotment_id`) REFERENCES `adm_allotments` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_wd_processed_by` FOREIGN KEY (`processed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Withdrawal recording with refund eligibility computation per cycle refund policy';


-- ==================================================================================================================================================
-- STUNDET'S PROMOTIONS
-- ==================================================================================================================================================

-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- This table will store the promotion batches for each class.
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_promotion_batches` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT, -- Primary key
  `from_session_id`       INT UNSIGNED        NOT NULL, -- FK → sch_org_academic_sessions_jnt.id; current academic session
  `to_session_id`         INT UNSIGNED        NOT NULL, -- FK → sch_org_academic_sessions_jnt.id; next academic session
  `from_class_id`         INT UNSIGNED        NOT NULL, -- FK → sch_classes; source class for promotion
  `to_class_id`           INT UNSIGNED        NOT NULL, -- FK → sch_classes; destination class (same as from for detention)
  `criteria_json`         JSON                NULL, -- Pass criteria config e.g., {"min_pass_pct":33,"use_exam_results":true}
  `total_students`        INT UNSIGNED        NOT NULL DEFAULT 0, -- Total students loaded into batch
  `promoted_count`        INT UNSIGNED        NOT NULL DEFAULT 0, -- Count updated on confirm
  `detained_count`        INT UNSIGNED        NOT NULL DEFAULT 0, -- Count updated on confirm
  `status`                ENUM('Draft','Confirmed') NOT NULL DEFAULT 'Draft', -- Draft = in-progress; Confirmed = committed (idempotent re-run safe)
  `processed_by`          INT UNSIGNED        NULL, -- FK → sys_users.id; staff who confirmed the batch
  `processed_at`          TIMESTAMP           NULL, -- Timestamp when batch was confirmed
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1, -- Soft enable/disable
  `created_at`            TIMESTAMP           NULL, -- Record creation timestamp
  `updated_at`            TIMESTAMP           NULL, -- Record update timestamp
  `deleted_at`            TIMESTAMP           NULL, -- Soft delete timestamp
  PRIMARY KEY (`id`),
  KEY `idx_adm_pb_from_session`        (`from_session_id`),
  KEY `idx_adm_pb_status`              (`from_session_id`, `from_class_id`, `status`),
  KEY `idx_adm_pb_to_session`          (`to_session_id`),
  KEY `idx_adm_pb_from_class`          (`from_class_id`),
  KEY `idx_adm_pb_to_class`            (`to_class_id`),
  KEY `idx_adm_pb_processed_by`        (`processed_by`),
  CONSTRAINT `fk_adm_pb_from_session_id` FOREIGN KEY (`from_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_pb_to_session_id` FOREIGN KEY (`to_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_pb_from_class_id` FOREIGN KEY (`from_class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_pb_to_class_id` FOREIGN KEY (`to_class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_pb_processed_by` FOREIGN KEY (`processed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Year-end promotion batch header; Confirmed = committed; re-run idempotent via firstOrCreate';


-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- This table will store the promotion records for each class.
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_promotion_records` (
  `id`                        BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT, -- Primary key',
  `promotion_batch_id`        BIGINT UNSIGNED     NOT NULL, -- FK → adm_promotion_batches
  `student_id`                INT UNSIGNED        NOT NULL, -- FK → std_students.id
  `from_class_section_id`     INT UNSIGNED        NOT NULL, -- FK → sch_class_section_jnt.id; source class+section
  `to_class_section_id`       INT UNSIGNED        NULL, -- FK → sch_class_section_jnt.id; NULL if detained/left (no section assigned yet)
  `new_roll_no`               SMALLINT UNSIGNED   NULL, -- Roll number in new class section; assigned by PromotionService::assignRollNumbers()
  `result`                    ENUM('Promoted','Detained','Transferred','Alumni','Left') NOT NULL, -- Promotion outcome; Detained = same class next session; Left = no new record
  `remarks`                   TEXT                NULL, -- Manual override reason or LmsExam result summary
  `is_active`                 TINYINT(1)          NOT NULL DEFAULT 1, -- Soft enable/disable
  `created_at`                TIMESTAMP           NULL, -- Record creation timestamp
  `updated_at`                TIMESTAMP           NULL, -- Record update timestamp
  `deleted_at`                TIMESTAMP           NULL, -- Soft delete timestamp
  PRIMARY KEY (`id`),
  KEY `idx_adm_pr_batch`           (`promotion_batch_id`),
  KEY `idx_adm_pr_student`         (`promotion_batch_id`, `student_id`),
  KEY `idx_adm_pr_student_id`      (`student_id`),
  KEY `idx_adm_pr_from_section`    (`from_class_section_id`),
  KEY `idx_adm_pr_to_section`      (`to_class_section_id`),
  CONSTRAINT `fk_adm_pr_batch_id` FOREIGN KEY (`promotion_batch_id`) REFERENCES `adm_promotion_batches` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_pr_student_id` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_pr_from_class_section_id` FOREIGN KEY (`from_class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_pr_to_class_section_id` FOREIGN KEY (`to_class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Per-student promotion decision within a batch; supports Promoted/Detained/Left classifications';


-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- This table will store the transfer certificates for each class.
-- --------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `adm_transfer_certificates` (
  `id`                    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT, -- Primary key
  `student_id`            INT UNSIGNED        NOT NULL, -- FK → std_students.id
  `tc_number`             VARCHAR(30)         NOT NULL, -- Unique TC number: TC-YYYY-NNN; unique per school-year
  `issue_date`            DATE                NOT NULL, -- Date TC was issued
  `leaving_date`          DATE                NOT NULL, -- Student last date at school
  `class_at_leaving`      VARCHAR(30)         NOT NULL, -- Class at the time of leaving e.g., "Class 10-A"
  `reason_for_leaving`    TEXT                NULL, -- Reason for leaving school
  `conduct`               ENUM('Excellent','Good','Satisfactory','Poor') NOT NULL DEFAULT 'Good', -- Student conduct grade for TC
  `destination_school`    VARCHAR(150)        NULL, -- School student is transferring to
  `academic_status`       VARCHAR(100)        NULL, -- e.g., "Promoted to Class 9" or "Class 10 passed"
  `fees_cleared`          TINYINT(1)          NOT NULL DEFAULT 0, -- 1 = FIN module confirmed no outstanding balance (BR-ADM-004)
  `library_cleared`       TINYINT(1)          NOT NULL DEFAULT 0, -- 1 = Library books/assets returned
  `hostel_cleared`        TINYINT(1)          NOT NULL DEFAULT 1, -- 1 = Hostel/boarding dues cleared (default 1 if day scholar)
  `laboratory_cleared`    TINYINT(1)          NOT NULL DEFAULT 1, -- 1 = Lab equipment/materials returned
  `sports_cleared`        TINYINT(1)          NOT NULL DEFAULT 1, -- 1 = Sports equipment/assets returned
  `clearance_remarks`     TEXT                NULL, -- Remarks from librarians/wardens if any
  `tc_status`             ENUM('Pending','Issued','Cancelled') NOT NULL DEFAULT 'Pending', -- Status of the TC
  `cancel_reason`         TEXT                NULL, -- Reason for TC cancellation (Required if tc_status = 'Cancelled')
  `cancelled_by`          INT UNSIGNED        NULL, -- FK → sys_users.id (INT UNSIGNED) — staff who cancelled
  `cancel_date`           TIMESTAMP           NULL, -- Date TC was cancelled
  `is_duplicate`          TINYINT(1)          NOT NULL DEFAULT 0, -- 1 = re-issue of lost/damaged TC
  `original_tc_id`        BIGINT UNSIGNED     NULL, -- FK → adm_transfer_certificates.id (self-ref); reference for duplicate TC
  `media_id`              INT UNSIGNED        NULL, -- FK → sys_media.id (INT UNSIGNED); TC PDF with QR code
  `issued_by`             INT UNSIGNED        NULL, -- FK → sys_users.id; staff who issued the TC
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1, -- Soft enable/disable
  `created_by`            BIGINT UNSIGNED     NOT NULL, -- sys_users.id — creator
  `updated_by`            BIGINT UNSIGNED     NOT NULL, -- sys_users.id — last editor
  `created_at`            TIMESTAMP           NULL, -- Record creation timestamp
  `updated_at`            TIMESTAMP           NULL, -- Record update timestamp
  `deleted_at`            TIMESTAMP           NULL, -- Soft delete timestamp
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_adm_tc_number`    (`tc_number`),
  KEY `idx_adm_tc_student`         (`student_id`),
  KEY `idx_adm_tc_issue_date`      (`issue_date`),
  KEY `idx_adm_tc_original`        (`original_tc_id`),
  KEY `idx_adm_tc_media`           (`media_id`),
  KEY `idx_adm_tc_issued_by`       (`issued_by`),
  CONSTRAINT `fk_adm_tc_student_id` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_tc_original_tc_id` FOREIGN KEY (`original_tc_id`) REFERENCES `adm_transfer_certificates` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_tc_media_id` FOREIGN KEY (`media_id`) REFERENCES `sys_media` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_tc_issued_by` FOREIGN KEY (`issued_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='TC issuance log with DomPDF + QR verification; original_tc_id for duplicate re-issue';




-- =============================================================================
-- END OF ADM DDL v2.1

