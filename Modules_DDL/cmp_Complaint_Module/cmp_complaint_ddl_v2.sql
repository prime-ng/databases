-- =====================================================================
-- COMPLAINT & GRIEVANCE MANAGEMENT MODULE
-- FINALIZED DDL
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -------------------------------------------------------------------------
-- COMPLAINT CATEGORIES & SUB-CATEGORIES
-- -------------------------------------------------------------------------
-- Hierarchical master for Categories (e.g. Transport) and Sub-categories (e.g. Rash Driving).
-- Aligns complaints with specific Departments.

CREATE TABLE IF NOT EXISTS `cmp_complaint_categories` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_id` BIGINT UNSIGNED DEFAULT NULL, -- NULL = Main Category, Value = Sub-category
  `name` VARCHAR(100) NOT NULL, -- e.g. "Transport", "Academic", "Rash Driving"
  `code` VARCHAR(30) DEFAULT NULL, -- Optional short code e.g. "TPT", "ACD"
  `department_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_departments (Linked Department e.g. "Transport Dept"
  `description` VARCHAR(512) DEFAULT NULL,
  `severity_level_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table e.g. "1-Low", "2-Medium", "3-High", 4-"10-Critical"
  `priority_score_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table e.g. 1=Critical, 2=Urgent, 3=High, 4=Medium, 5=Low
  `expected_resolution_hours` INT UNSIGNED NOT NULL,  -- This must be less than escalation_l1_hours
  `escalation_hours_l1` INT UNSIGNED NOT NULL, -- Time before escalating to L1 (This must be less than escalation_l2_hours)
  `escalation_hours_l2` INT UNSIGNED NOT NULL, -- Time before escalating to L2 (This must be less than escalation_l3_hours)
  `escalation_hours_l3` INT UNSIGNED NOT NULL, -- Time before escalating to L3 (This must be less than escalation_l4_hours)
  `escalation_hours_l4` INT UNSIGNED NOT NULL, -- Time before escalating to L4 (This must be less than escalation_l5_hours)
  `escalation_hours_l5` INT UNSIGNED NOT NULL, -- Time before escalating to L5
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_cat_parent` (`parent_id`),
  CONSTRAINT `fk_cat_parent` FOREIGN KEY (`parent_id`) REFERENCES `cmp_complaint_categories` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cat_department` FOREIGN KEY (`department_id`) REFERENCES `sys_departments` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_cat_severity_level` FOREIGN KEY (`severity_level_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_cat_priority_score` FOREIGN KEY (`priority_score_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL,
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- SLA CONFIGURATION (MASTER SETTINGS)
-- -------------------------------------------------------------------------
-- This table will capture the detail of complaint categories and sub-categories (like whom to escalate, expected resolution time, escalation time etc.)
CREATE TABLE IF NOT EXISTS `cmp_department_sla` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `complaint_category_id` BIGINT UNSIGNED NOT NULL,       -- FK to cmp_complaint_categories
  `complaint_subcategory_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to cmp_complaint_categories (if sub-category is Null then it will be applied to all sub-categories exept those defined in the sub-category)
  `target_user_type_id` BIGINT UNSIGNED DEFAULT NULL,     -- FK to sys_dropdown_table e.g. "User", "Group", "Department", "Role"
  `target_department_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_departments
  `target_role_id` BIGINT UNSIGNED DEFAULT NULL,          -- FK to sys_roles
  `target_user_id` BIGINT UNSIGNED DEFAULT NULL,          -- FK to sys_users
  `dept_expected_resolution_hours` INT UNSIGNED NOT NULL, -- This must be less than escalation_l1_hours
  `dept_escalation_hours_l1` INT UNSIGNED NOT NULL,       -- Time before escalating to L1 (This must be less than escalation_l2_hours)
  `dept_escalation_hours_l2` INT UNSIGNED NOT NULL,       -- Time before escalating to L2 (This must be less than escalation_l3_hours)
  `dept_escalation_hours_l3` INT UNSIGNED NOT NULL,       -- Time before escalating to L3 (This must be less than escalation_l4_hours)
  `dept_escalation_hours_l4` INT UNSIGNED NOT NULL,       -- Time before escalating to L4 (This must be less than escalation_l5_hours)
  `dept_escalation_hours_l5` INT UNSIGNED NOT NULL,       -- Time before escalating to L5
  `escalation_l1_role_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_roles
  `escalation_l1_user_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_users
  `escalation_l2_role_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_roles
  `escalation_l2_user_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_users
  `escalation_l3_role_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_roles
  `escalation_l3_user_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_users
  `escalation_l4_role_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_roles
  `escalation_l4_user_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_users
  `escalation_l5_role_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_roles
  `escalation_l5_user_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_users
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_sla_lookup` (`complaint_category_id`, `complaint_subcategory_id`, `target_user_type_id`, `target_department_id`, `target_role_id`, `target_user_id`, `is_active`),
  CONSTRAINT `fk_sla_category` FOREIGN KEY (`complaint_category_id`) REFERENCES `cmp_complaint_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sla_subcategory` FOREIGN KEY (`complaint_subcategory_id`) REFERENCES `cmp_complaint_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sla_target_user_type` FOREIGN KEY (`target_user_type_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sla_target_department_id` FOREIGN KEY (`target_department_id`) REFERENCES `sys_departments` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sla_target_role_id` FOREIGN KEY (`target_role_id`) REFERENCES `sys_roles` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sla_target_user_id` FOREIGN KEY (`target_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sla_escalation_l1_role_id` FOREIGN KEY (`escalation_l1_role_id`) REFERENCES `sys_roles` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sla_escalation_l1_user_id` FOREIGN KEY (`escalation_l1_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sla_escalation_l2_role_id` FOREIGN KEY (`escalation_l2_role_id`) REFERENCES `sys_roles` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sla_escalation_l2_user_id` FOREIGN KEY (`escalation_l2_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sla_escalation_l3_role_id` FOREIGN KEY (`escalation_l3_role_id`) REFERENCES `sys_roles` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sla_escalation_l3_user_id` FOREIGN KEY (`escalation_l3_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sla_escalation_l4_role_id` FOREIGN KEY (`escalation_l4_role_id`) REFERENCES `sys_roles` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sla_escalation_l4_user_id` FOREIGN KEY (`escalation_l4_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sla_escalation_l5_role_id` FOREIGN KEY (`escalation_l5_role_id`) REFERENCES `sys_roles` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sla_escalation_l5_user_id` FOREIGN KEY (`escalation_l5_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- MASTER COMPLAINT TABLE
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `cmp_complaints` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ticket_no` VARCHAR(30) NOT NULL, -- Auto-generated unique ticket ID (e.g., CMP-2025-0001)
  `ticket_date` DATE NOT NULL DEFAULT CURRENT_DATE(), -- Date when the complaint was raised
  -- Complainant Info (Who raised it)
  `complainant_type_id` BIGINT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (Parent, Student, Staff, Vendor, Public)
  `complainant_user_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_users (NULL if Public/Anonymous)
  `complainant_name` VARCHAR(100) DEFAULT NULL, -- Captured if not a system user
  `complainant_contact` VARCHAR(50) DEFAULT NULL,
  -- Target Entity (Against whom/what)
  `target_type_id` BIGINT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (Department, Staff, Driver, Vehicle, Facility, System)
  `target_id` BIGINT UNSIGNED DEFAULT NULL, -- ID of the specific Dept, Staff, Vehicle, etc.
  `target_name` VARCHAR(100) DEFAULT NULL, -- For display purposes or if ID is NULL
  -- Classification
  `category_id` BIGINT UNSIGNED NOT NULL, -- FK to cmp_complaint_categories
  `subcategory_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to cmp_complaint_categories
  `severity_level_id` BIGINT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (Low, Medium, High, Critical)
  `priority_score_id` BIGINT UNSIGNED DEFAULT 3, -- FK to sys_dropdown_table (1=Critical, 5=Low)
  -- Complaint Content
  `title` VARCHAR(200) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `location_details` VARCHAR(255) DEFAULT NULL, -- Where did it happen?
  `incident_date` DATETIME DEFAULT NULL,
  `incident_time` TIME DEFAULT NULL,
  -- Status & Resolution
  `status_id` BIGINT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (Open, In-Progress, Escalated, Resolved, Closed, Rejected)
  `assigned_to_role_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_roles (Current Role handling it)
  `assigned_to_user_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_users (Specific Officer)
  `resolution_due_at` DATETIME DEFAULT NULL, -- Calculated from SLA
  `actual_resolved_at` DATETIME DEFAULT NULL,
  `resolved_by_role_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_roles (Role who resolved it)
  `resolved_by_user_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_users (Officer who resolved it)
  `resolution_summary` TEXT DEFAULT NULL,
  -- Escalation
  `escalation_level` TINYINT UNSIGNED DEFAULT 0, -- 0=None, 1=L1, 2=L2...
  `is_escalated` TINYINT(1) DEFAULT 0,
  -- Meta
  `source_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table (App, Web, Email, Walk-in, Call)
  `is_anonymous` TINYINT(1) DEFAULT 0,
  `dept_specific_info` JSON DEFAULT NULL, -- Department-specific additional info (e.g., Student ID, Parent ID, route_id, vehicle_id)
  `is_medical_check_required` TINYINT(1) DEFAULT 0, -- If true, then system will capture medical check details in 'cmp_medical_checks' table.
  -- Support Files
  `support_file` tinyint(1) DEFAULT 0, -- If true, then system will have support files in sys_media table.
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ticket_no` (`ticket_no`),
  KEY `idx_cmp_status` (`status`),
  KEY `idx_cmp_complainant` (`complainant_type_id`, `complainant_user_id`),
  KEY `idx_cmp_target` (`target_type_id`, `target_id`),
  CONSTRAINT `fk_cmp_complainant_type` FOREIGN KEY (`complainant_type_id`) REFERENCES `sys_dropdown_table` (`id`),
  CONSTRAINT `fk_cmp_complainant_name` FOREIGN KEY (`complainant_user_id`) REFERENCES `sys_users` (`id`),
  CONSTRAINT `fk_cmp_target_type` FOREIGN KEY (`target_type_id`) REFERENCES `sys_dropdown_table` (`id`),
  CONSTRAINT `fk_cmp_target` FOREIGN KEY (`target_id`) REFERENCES `sys_users` (`id`),
  CONSTRAINT `fk_cmp_category` FOREIGN KEY (`category_id`) REFERENCES `cmp_complaint_categories` (`id`),
  CONSTRAINT `fk_cmp_subcategory` FOREIGN KEY (`subcategory_id`) REFERENCES `cmp_complaint_categories` (`id`),
  CONSTRAINT `fk_cmp_severity_level` FOREIGN KEY (`severity_level_id`) REFERENCES `sys_dropdown_table` (`id`),
  CONSTRAINT `fk_cmp_priority_score` FOREIGN KEY (`priority_score_id`) REFERENCES `sys_dropdown_table` (`id`),
  CONSTRAINT `fk_cmp_status` FOREIGN KEY (`status_id`) REFERENCES `sys_dropdown_table` (`id`),
  CONSTRAINT `fk_cmp_assigned_to_role` FOREIGN KEY (`assigned_to_role_id`) REFERENCES `sys_roles` (`id`),
  CONSTRAINT `fk_cmp_assigned_to_user` FOREIGN KEY (`assigned_to_user_id`) REFERENCES `sys_users` (`id`),
  CONSTRAINT `fk_cmp_resolved_by_role` FOREIGN KEY (`resolved_by_role_id`) REFERENCES `sys_roles` (`id`),
  CONSTRAINT `fk_cmp_resolved_by_user` FOREIGN KEY (`resolved_by_user_id`) REFERENCES `sys_users` (`id`),
  CONSTRAINT `fk_cmp_source` FOREIGN KEY (`source_id`) REFERENCES `sys_dropdown_table` (`id`),
  CONSTRAINT `fk_cmp_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`),
  CONSTRAINT `fk_cmp_medical_check` FOREIGN KEY (`is_medical_check_required`) REFERENCES `cmp_medical_checks` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- COMPLAINT ACTIONS (AUDIT TRAIL)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `cmp_complaint_actions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `complaint_id` BIGINT UNSIGNED NOT NULL,
  `action_type_id` BIGINT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (Created, Assigned, Comment, StatusChange, Investigation, Escalated, Resolved)
  `performed_by_user_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_users (NULL for System)
  `performed_by_role_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_roles (NULL for System)
  `assigned_to_user_id` BIGINT UNSIGNED DEFAULT NULL, -- If reassigned
  `assigned_to_role_id` BIGINT UNSIGNED DEFAULT NULL, -- If reassigned
  `notes` TEXT DEFAULT NULL,
  `is_private_note` TINYINT(1) DEFAULT 0, -- If true, not visible to complainant
  `action_timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_act_complaint` (`complaint_id`),
  CONSTRAINT `fk_act_complaint` FOREIGN KEY (`complaint_id`) REFERENCES `cmp_complaints` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_act_action_type` FOREIGN KEY (`action_type_id`) REFERENCES `sys_dropdown_table` (`id`),
  CONSTRAINT `fk_act_performed_by_user` FOREIGN KEY (`performed_by_user_id`) REFERENCES `sys_users` (`id`),
  CONSTRAINT `fk_act_performed_by_role` FOREIGN KEY (`performed_by_role_id`) REFERENCES `sys_roles` (`id`),
  CONSTRAINT `fk_act_assigned_to_user` FOREIGN KEY (`assigned_to_user_id`) REFERENCES `sys_users` (`id`),
  CONSTRAINT `fk_act_assigned_to_role` FOREIGN KEY (`assigned_to_role_id`) REFERENCES `sys_roles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- MEDICAL & SAFETY CHECKS (TRANSPORT COMPLIANCE)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `cmp_medical_checks` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `complaint_id` BIGINT UNSIGNED NOT NULL,
  `check_type` BIGINT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (AlcoholTest, DrugTest, FitnessCheck)
  `conducted_by` VARCHAR(100) DEFAULT NULL, -- Doctor/Officer Name
  `conducted_at` DATETIME NOT NULL,
  `result` VARCHAR(20) NOT NULL, -- FK to sys_dropdown_table (Positive, Negative, Inconclusive)
  `reading_value` VARCHAR(50) DEFAULT NULL, -- e.g. BAC Level (AlcoholTest)
  `remarks` TEXT DEFAULT NULL, 
  `evidence_uploded` TINYINT(1) DEFAULT 0, -- 1 (Yes), 0 (No), If 'YES', Docs will be uploaded in sys_media table.
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_med_complaint` (`complaint_id`),
  CONSTRAINT `fk_med_complaint` FOREIGN KEY (`complaint_id`) REFERENCES `cmp_complaints` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_med_check_type` FOREIGN KEY (`check_type`) REFERENCES `sys_dropdown_table` (`id`),
  CONSTRAINT `fk_med_result` FOREIGN KEY (`result`) REFERENCES `sys_dropdown_table` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- AI ANALYTICS & INSIGHTS
-- -------------------------------------------------------------------------
-- Stores processed insights for complaints (Prediction, Sentiment, Risk)

CREATE TABLE IF NOT EXISTS `cmp_ai_insights` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `complaint_id` BIGINT UNSIGNED NOT NULL,
  `sentiment_score` DECIMAL(4,3) DEFAULT NULL, -- -1.0 (Negative) to +1.0 (Positive) calculated by AI e.g. -0.8
  `sentiment_label_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table (Angry, Urgent, Calm, Neutral) calculated by AI e.g. Angry
  `escalation_risk_score` DECIMAL(5,2) DEFAULT NULL, -- 0-100% Probability calculated by AI e.g. 80% 
  `predicted_category_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to cmp_complaint_categories calculated by AI e.g. Rash Driving
  `safety_risk_score` DECIMAL(5,2) DEFAULT NULL, -- 0-100% Probability calculated by AI e.g. 80%
  `model_version` VARCHAR(20) DEFAULT NULL, -- model version used for prediction e.g. v1.0
  `processed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ai_complaint` (`complaint_id`),
  KEY `idx_ai_risk` (`escalation_risk_score`),
  CONSTRAINT `fk_ai_complaint` FOREIGN KEY (`complaint_id`) REFERENCES `cmp_complaints` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ai_sentiment_label` FOREIGN KEY (`sentiment_label_id`) REFERENCES `sys_dropdown_table` (`id`),
  CONSTRAINT `fk_ai_predicted_category` FOREIGN KEY (`predicted_category_id`) REFERENCES `cmp_complaint_categories` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition: 
-- 1. How to calculate all required fields is mentioned in databases/Screen_Design/cmp_Complaint_Module/cmp_11_AI_Calculation_Logic.md

SET FOREIGN_KEY_CHECKS = 1;
