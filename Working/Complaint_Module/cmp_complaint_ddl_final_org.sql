-- =====================================================================
-- COMPLAINT & GRIEVANCE MANAGEMENT MODULE
-- FINALIZED DDL
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -------------------------------------------------------------------------
-- 1. COMPLAINT CATEGORIES & SUB-CATEGORIES
-- -------------------------------------------------------------------------
-- Hierarchical master for Categories (e.g. Transport) and Sub-categories (e.g. Rash Driving).
-- Aligns complaints with specific Departments.

CREATE TABLE IF NOT EXISTS `cmp_complaint_categories` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_id` BIGINT UNSIGNED DEFAULT NULL, -- NULL = Main Category, Value = Sub-category
  `name` VARCHAR(100) NOT NULL, -- e.g. "Transport", "Academic", "Rash Driving"
  `code` VARCHAR(30) DEFAULT NULL, -- Optional short code e.g. "TPT", "ACD"
  `department_name` VARCHAR(100) DEFAULT NULL, -- Linked Department e.g. "Transport Dept"
  `description` TEXT DEFAULT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_cat_parent` (`parent_id`),
  CONSTRAINT `fk_cat_parent` FOREIGN KEY (`parent_id`) REFERENCES `cmp_complaint_categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- 2. SLA CONFIGURATION (MASTER SETTINGS)
-- -------------------------------------------------------------------------
-- Defines resolution deadlines based on severity, category, and transport flag.

CREATE TABLE IF NOT EXISTS `cmp_sla_configs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `severity_level` VARCHAR(20) NOT NULL, -- FK to sys_dropdown_table e.g. "Low", "Medium", "High", "Critical"
  `category_id` BIGINT UNSIGNED DEFAULT NULL, -- Specific category (Optional)
  `is_transport_related` TINYINT(1) DEFAULT 0,
  `expected_resolution_hours` INT UNSIGNED NOT NULL,
  `escalation_l1_hours` INT UNSIGNED NOT NULL, -- Time before escalating to L1
  `escalation_l2_hours` INT UNSIGNED NOT NULL, -- Time before escalating to L2
  `escalation_l3_hours` INT UNSIGNED NOT NULL, -- Time before escalating to L3
  `escalation_l4_hours` INT UNSIGNED NOT NULL, -- Time before escalating to L4
  `escalation_l5_hours` INT UNSIGNED NOT NULL, -- Time before escalating to L5
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_sla_lookup` (`severity_level`, `is_transport_related`),
  CONSTRAINT `fk_sla_category` FOREIGN KEY (`category_id`) REFERENCES `cmp_complaint_categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- 3. MASTER COMPLAINT TABLE
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `cmp_complaints` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ticket_no` VARCHAR(30) NOT NULL, -- Auto-generated unique ticket ID (e.g., CMP-2023-0001)
  -- Complainant Info (Who raised it)
  `complainant_type` VARCHAR(20) NOT NULL, -- FK to sys_dropdown_table (Parent, Student, Staff, Vendor, Public)
  `complainant_user_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_users (NULL if Public/Anonymous)
  `complainant_name` VARCHAR(100) DEFAULT NULL, -- Captured if not a system user
  `complainant_contact` VARCHAR(50) DEFAULT NULL,
  -- Target Entity (Against whom/what)
  `target_type` VARCHAR(20) NOT NULL, -- FK to sys_dropdown_table (Department, Staff, Driver, Vehicle, Facility, System)
  `target_id` BIGINT UNSIGNED DEFAULT NULL, -- ID of the specific Dept, Staff, Vehicle, etc.
  `target_name` VARCHAR(100) DEFAULT NULL, -- For display purposes or if ID is NULL
  -- Classification
  `category_id` BIGINT UNSIGNED NOT NULL, -- Main Category
  `subcategory_id` BIGINT UNSIGNED DEFAULT NULL, -- Sub-Category (Optional)
  `severity_level` VARCHAR(20) NOT NULL, -- FK to sys_dropdown_table (Low, Medium, High, Critical)
  `priority_score` TINYINT UNSIGNED DEFAULT 3, -- 1=Critical, 5=Low (can be auto-calc based on SLA)
  -- Transport Specifics
  `is_transport_related` TINYINT(1) NOT NULL DEFAULT 0,
  `route_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to tpt_route (if transport)
  `vehicle_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to tpt_vehicle (if transport)
  `alcohol_suspected` TINYINT(1) DEFAULT 0,
  `medical_unfit_suspected` TINYINT(1) DEFAULT 0,
  `safety_violation` TINYINT(1) DEFAULT 0,
  -- Content
  `title` VARCHAR(200) NOT NULL,
  `description` TEXT NOT NULL,
  `location_details` VARCHAR(255) DEFAULT NULL, -- Where did it happen?
  `incident_date` DATETIME DEFAULT NULL,
  -- Status & Resolution
  `status` VARCHAR(20) NOT NULL DEFAULT 'Open', -- FK (Open, In-Progress, Escalated, Resolved, Closed, Rejected)
  `assigned_to_role` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_roles (Current Role handling it)
  `assigned_to_user` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_users (Specific Officer)
  `resolution_due_at` DATETIME DEFAULT NULL, -- Calculated from SLA
  `actual_resolved_at` DATETIME DEFAULT NULL,
  `resolution_summary` TEXT DEFAULT NULL,
  -- Escalation
  `escalation_level` TINYINT UNSIGNED DEFAULT 0, -- 0=None, 1=L1, 2=L2...
  `is_escalated` TINYINT(1) DEFAULT 0,
  -- Meta
  `source` VARCHAR(20) DEFAULT 'Web', -- App, Web, Email, Walk-in, Call
  `is_anonymous` TINYINT(1) DEFAULT 0,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ticket_no` (`ticket_no`),
  KEY `idx_cmp_status` (`status`),
  KEY `idx_cmp_complainant` (`complainant_type`, `complainant_user_id`),
  KEY `idx_cmp_target` (`target_type`, `target_id`),
  KEY `idx_cmp_transport` (`is_transport_related`, `route_id`, `vehicle_id`),
  KEY `idx_cmp_dates` (`created_at`, `incident_date`),
  KEY `idx_cmp_category` (`category_id`, `subcategory_id`),
  CONSTRAINT `fk_cmp_category` FOREIGN KEY (`category_id`) REFERENCES `cmp_complaint_categories` (`id`),
  CONSTRAINT `fk_cmp_subcategory` FOREIGN KEY (`subcategory_id`) REFERENCES `cmp_complaint_categories` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- 4. COMPLAINT ACTIONS (AUDIT TRAIL)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `cmp_complaint_actions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `complaint_id` BIGINT UNSIGNED NOT NULL,
  `action_type` VARCHAR(50) NOT NULL, -- FK (Created, Assigned, Comment, StatusChange, Investigation, Escalated, Resolved)
  -- Action Details
  `performed_by_user` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_users (NULL for System)
  `performed_by_role` VARCHAR(50) DEFAULT NULL, -- Role Name at time of action
  `assigned_to_user` BIGINT UNSIGNED DEFAULT NULL, -- If reassigned
  `notes` TEXT DEFAULT NULL,
  `is_private_note` TINYINT(1) DEFAULT 0, -- If true, not visible to complainant
  `action_timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_act_complaint` (`complaint_id`),
  CONSTRAINT `fk_act_complaint` FOREIGN KEY (`complaint_id`) REFERENCES `cmp_complaints` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- 5. MEDICAL & SAFETY CHECKS (TRANSPORT COMPLIANCE)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `cmp_medical_checks` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `complaint_id` BIGINT UNSIGNED NOT NULL,
  `check_type` VARCHAR(50) NOT NULL, -- FK (AlcoholTest, DrugTest, FitnessCheck)
  `conducted_by` VARCHAR(100) DEFAULT NULL, -- Doctor/Officer Name
  `conducted_at` DATETIME NOT NULL,
  `result` VARCHAR(20) NOT NULL, -- Positive, Negative, Inconclusive
  `reading_value` VARCHAR(50) DEFAULT NULL, -- e.g. BAC Level
  `remarks` TEXT DEFAULT NULL, 
  `evidence_file_path` VARCHAR(255) DEFAULT NULL, -- Link to uploaded report/image
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_med_complaint` (`complaint_id`),
  CONSTRAINT `fk_med_complaint` FOREIGN KEY (`complaint_id`) REFERENCES `cmp_complaints` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- 6. ATTACHMENTS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `cmp_attachments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `complaint_id` BIGINT UNSIGNED NOT NULL,
  `action_id` BIGINT UNSIGNED DEFAULT NULL, -- If attached to a specific comment/action
  `file_type` VARCHAR(20) NOT NULL, -- Image, Video, Doc, Audio
  `file_name` VARCHAR(255) NOT NULL,
  `file_path` VARCHAR(500) NOT NULL,
  `file_size_kb` INT UNSIGNED DEFAULT NULL,
  `uploaded_by` BIGINT UNSIGNED NOT NULL,
  `uploaded_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_att_complaint` (`complaint_id`),
  CONSTRAINT `fk_att_complaint` FOREIGN KEY (`complaint_id`) REFERENCES `cmp_complaints` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- 7. AI ANALYTICS & INSIGHTS
-- -------------------------------------------------------------------------
-- Stores processed insights for complaints (Prediction, Sentiment, Risk)

CREATE TABLE IF NOT EXISTS `cmp_ai_insights` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `complaint_id` BIGINT UNSIGNED NOT NULL,
  -- Analysis
  `sentiment_score` DECIMAL(4,3) DEFAULT NULL, -- -1.0 (Negative) to +1.0 (Positive)
  `sentiment_label` VARCHAR(20) DEFAULT NULL, -- Angry, Urgent, Calm, Neutral
  -- Prediction
  `escalation_risk_score` DECIMAL(5,2) DEFAULT NULL, -- 0-100% Probability
  `predicted_category` VARCHAR(50) DEFAULT NULL,
  -- Safety (Driver/Transport)
  `safety_risk_score` DECIMAL(5,2) DEFAULT NULL,
  -- Meta
  `model_version` VARCHAR(20) DEFAULT NULL,
  `processed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ai_complaint` (`complaint_id`),
  KEY `idx_ai_risk` (`escalation_risk_score`),
  CONSTRAINT `fk_ai_complaint` FOREIGN KEY (`complaint_id`) REFERENCES `cmp_complaints` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
