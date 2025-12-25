/*
 * Database Schema for Complaint Management Module v2.0
 * 
 * Module Prefix: cmp_
 * Description: Manages complaints, grievances, and feedback across all school departments.
 * Features: 5-Level Escalation, SLA Tracking, Action Logs, Medical/Safety Checks.
 * 
 * Dependencies:
 *  - sys_users (Global Users)
 *  - sys_roles (Global Roles)
 *  - sys_dropdown_table (Common Lookups: Status, Priority, Severity)
 *  - sys_media (Polymorphic Attachments)
 */

SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. COMPLAINT CATEGORIES & SLA CONFIGURATION
-- =========================================================
-- Hierarchical table for Categories and Sub-Categories.
-- Stores default SLA and Risk Levels.

CREATE TABLE IF NOT EXISTS `cmp_complaint_categories` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_id` BIGINT UNSIGNED NULL COMMENT 'Self-referencing for Category -> Sub-Category hierarchy',
  `name` VARCHAR(100) NOT NULL COMMENT 'e.g., Transport, Academics, Canteen',
  `code` VARCHAR(20) NOT NULL UNIQUE COMMENT 'Short code e.g., TPT, ACD',
  `description` VARCHAR(255) NULL,
  -- Default Limits for this Category
  `default_priority_id` BIGINT UNSIGNED NULL COMMENT 'FK to sys_dropdown_table',
  `default_severity_id` BIGINT UNSIGNED NULL COMMENT 'FK to sys_dropdown_table',
  `expected_resolution_hours` INT UNSIGNED NOT NULL DEFAULT 48 COMMENT 'SLA in hours',
  -- Audit Fields
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_cmp_categories_parent` FOREIGN KEY (`parent_id`) REFERENCES `cmp_complaint_categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 2. ESCALATION MATRIX CONFIGURATION
-- =========================================================
-- Defines who handles complaints at each of the 5 levels for a Department/Category.
-- Level 1: Manager, Level 5: Director.

CREATE TABLE IF NOT EXISTS `cmp_escalation_matrix` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category_id` BIGINT UNSIGNED NOT NULL COMMENT 'Link to specific Category/Sub-category',
  -- Level 1 Configuration
  `l1_role_id` BIGINT UNSIGNED NULL,
  `l1_user_id` BIGINT UNSIGNED NULL COMMENT 'Optional: Specific user override',
  `l1_escalate_after_hours` INT UNSIGNED DEFAULT 24,
  -- Level 2 Configuration
  `l2_role_id` BIGINT UNSIGNED NULL,
  `l2_user_id` BIGINT UNSIGNED NULL,
  `l2_escalate_after_hours` INT UNSIGNED DEFAULT 24,

  -- Level 3 Configuration
  `l3_role_id` BIGINT UNSIGNED NULL,
  `l3_user_id` BIGINT UNSIGNED NULL,
  `l3_escalate_after_hours` INT UNSIGNED DEFAULT 24,

  -- Level 4 Configuration
  `l4_role_id` BIGINT UNSIGNED NULL,
  `l4_user_id` BIGINT UNSIGNED NULL,
  `l4_escalate_after_hours` INT UNSIGNED DEFAULT 24,

  -- Level 5 Configuration
  `l5_role_id` BIGINT UNSIGNED NULL,
  `l5_user_id` BIGINT UNSIGNED NULL,
  
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_escalation_category` (`category_id`), -- One matrix per category
  CONSTRAINT `fk_cmp_matrix_category` FOREIGN KEY (`category_id`) REFERENCES `cmp_complaint_categories` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cmp_matrix_l1_role` FOREIGN KEY (`l1_role_id`) REFERENCES `sys_roles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 3. MASTER COMPLAINT REGISTER
-- =========================================================

CREATE TABLE IF NOT EXISTS `cmp_complaints` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `complaint_no` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Auto-generated e.g., CMP-202501-0001',
  
  -- Complainant Details (Polymorphic)
  `complainant_user_type` VARCHAR(100) NOT NULL COMMENT 'Model class: User, Student, Parent',
  `complainant_user_id` BIGINT UNSIGNED NOT NULL,
  `is_anonymous` TINYINT(1) DEFAULT 0,
  
  -- Context
  `category_id` BIGINT UNSIGNED NOT NULL,
  `sub_category_id` BIGINT UNSIGNED NULL,
  
  -- Against Whom (Polymorphic: Vendor, Staff, Driver, Infrastructure)
  `against_entity_type` VARCHAR(100) NULL COMMENT 'e.g., vnd_vendors, sys_users, tpt_vehicles',
  `against_entity_id` BIGINT UNSIGNED NULL,
  
  -- Core Content
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT NOT NULL,
  `location_details` VARCHAR(255) NULL COMMENT 'Specific location e.g. Canteen Hall 1',
  
  -- Classification & Status
  `priority_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK: sys_dropdown_table (High, Low)',
  `severity_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK: sys_dropdown_table (Critical, Cosmetic)',
  `status_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK: sys_dropdown_table (Open, Resolved)',
  
  -- Assignment & Escalation
  `current_level` TINYINT UNSIGNED DEFAULT 1 COMMENT '1 to 5',
  `assigned_to_role_id` BIGINT UNSIGNED NULL,
  `assigned_to_user_id` BIGINT UNSIGNED NULL,
  `sla_due_date` DATETIME NULL,
  
  -- Flags
  `is_serious` TINYINT(1) DEFAULT 0 COMMENT 'Flag for immediate attention',
  `medical_attention_required` TINYINT(1) DEFAULT 0,
  
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_cmp_complaints_category` FOREIGN KEY (`category_id`) REFERENCES `cmp_complaint_categories` (`id`),
  CONSTRAINT `fk_cmp_complaints_subcategory` FOREIGN KEY (`sub_category_id`) REFERENCES `cmp_complaint_categories` (`id`),
  CONSTRAINT `fk_cmp_complaints_priority` FOREIGN KEY (`priority_id`) REFERENCES `sys_dropdown_table` (`id`),
  CONSTRAINT `fk_cmp_complaints_severity` FOREIGN KEY (`severity_id`) REFERENCES `sys_dropdown_table` (`id`),
  CONSTRAINT `fk_cmp_complaints_status` FOREIGN KEY (`status_id`) REFERENCES `sys_dropdown_table` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 4. ACTION / AUDIT LOGS
-- =========================================================
-- Tracks every movement, comment, or status change.

CREATE TABLE IF NOT EXISTS `cmp_action_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `complaint_id` BIGINT UNSIGNED NOT NULL,
  
  `action_type_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK: sys_dropdown_table (Comment, Status Change, Reassign, Escalate)',
  `action_by_user_id` BIGINT UNSIGNED NOT NULL,
  `action_by_role_id` BIGINT UNSIGNED NULL,
  
  `previous_status_id` BIGINT UNSIGNED NULL,
  `new_status_id` BIGINT UNSIGNED NULL,
  
  `description` TEXT NULL COMMENT 'Comments or system notes',
  `is_internal_note` TINYINT(1) DEFAULT 0 COMMENT 'If true, not visible to complainant',
  
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  KEY `idx_cmp_logs_complaint` (`complaint_id`),
  CONSTRAINT `fk_cmp_logs_complaint` FOREIGN KEY (`complaint_id`) REFERENCES `cmp_complaints` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 5. MEDICAL & SAFETY RECORDS
-- =========================================================
-- For serious complaints involving alcohol, injuries, etc.

CREATE TABLE IF NOT EXISTS `cmp_medical_records` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `complaint_id` BIGINT UNSIGNED NOT NULL,
  
  `check_type_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK: sys_dropdown_table (Alcohol Test, Injury Report)',
  `conducted_by_name` VARCHAR(150) NOT NULL COMMENT 'Doctor or Official Name',
  `conducted_at` DATETIME NOT NULL,
  
  `result_summary` TEXT NOT NULL,
  `report_doc_id` BIGINT UNSIGNED NULL COMMENT 'Link to sys_media if a file is uploaded',
  
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_cmp_medical_complaint` FOREIGN KEY (`complaint_id`) REFERENCES `cmp_complaints` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- 6. SEED DATA
-- =========================================================

-- 6.1 Dropdown Needs (Registrations)
INSERT INTO `sys_dropdown_needs` (`db_type`, `table_name`, `column_name`, `menu_category`, `main_menu`, `sub_menu`, `tab_name`, `field_name`, `is_system`, `tenant_creation_allowed`) VALUES 
('Tenant', 'cmp_complaints', 'status_id', 'Operations', 'Complaint Mgmt', 'Complaints', 'Basic Info', 'Status', 1, 1),
('Tenant', 'cmp_complaints', 'priority_id', 'Operations', 'Complaint Mgmt', 'Complaints', 'Basic Info', 'Priority', 1, 0),
('Tenant', 'cmp_complaints', 'severity_id', 'Operations', 'Complaint Mgmt', 'Complaints', 'Basic Info', 'Severity', 1, 0),
('Tenant', 'cmp_action_logs', 'action_type_id', 'Operations', 'Complaint Mgmt', 'Logs', 'Action', 'Action Type', 1, 0);

-- 6.2 Dropdown Values (Seed)
-- Statuses
INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `is_active`) 
SELECT id, 1, 'cmp_complaints.status_id.open', 'Open', 1 FROM `sys_dropdown_needs` WHERE `column_name`='status_id' AND `table_name`='cmp_complaints'
UNION ALL
SELECT id, 2, 'cmp_complaints.status_id.inprogress', 'In Progress', 1 FROM `sys_dropdown_needs` WHERE `column_name`='status_id' AND `table_name`='cmp_complaints'
UNION ALL
SELECT id, 3, 'cmp_complaints.status_id.resolved', 'Resolved', 1 FROM `sys_dropdown_needs` WHERE `column_name`='status_id' AND `table_name`='cmp_complaints'
UNION ALL
SELECT id, 4, 'cmp_complaints.status_id.closed', 'Closed', 1 FROM `sys_dropdown_needs` WHERE `column_name`='status_id' AND `table_name`='cmp_complaints'
UNION ALL
SELECT id, 5, 'cmp_complaints.status_id.rejected', 'Rejected', 1 FROM `sys_dropdown_needs` WHERE `column_name`='status_id' AND `table_name`='cmp_complaints';

-- Priorities
INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `is_active`) 
SELECT id, 1, 'cmp_complaints.priority_id.high', 'High', 1 FROM `sys_dropdown_needs` WHERE `column_name`='priority_id'
UNION ALL
SELECT id, 2, 'cmp_complaints.priority_id.medium', 'Medium', 1 FROM `sys_dropdown_needs` WHERE `column_name`='priority_id'
UNION ALL
SELECT id, 3, 'cmp_complaints.priority_id.low', 'Low', 1 FROM `sys_dropdown_needs` WHERE `column_name`='priority_id';

-- Severities
INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `is_active`) 
SELECT id, 1, 'cmp_complaints.severity_id.critical', 'Critical (Type A)', 1 FROM `sys_dropdown_needs` WHERE `column_name`='severity_id'
UNION ALL
SELECT id, 2, 'cmp_complaints.severity_id.major', 'Major (Type B)', 1 FROM `sys_dropdown_needs` WHERE `column_name`='severity_id'
UNION ALL
SELECT id, 3, 'cmp_complaints.severity_id.minor', 'Minor (Type C)', 1 FROM `sys_dropdown_needs` WHERE `column_name`='severity_id';
