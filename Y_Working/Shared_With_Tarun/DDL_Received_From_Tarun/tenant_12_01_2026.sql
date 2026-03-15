-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               8.0.30 - MySQL Community Server - GPL
-- Server OS:                    Win64
-- HeidiSQL Version:             12.1.0.6537
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.cache
CREATE TABLE IF NOT EXISTS `cache` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` int NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.cache: ~0 rows (approximately)
DELETE FROM `cache`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.cache_locks
CREATE TABLE IF NOT EXISTS `cache_locks` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `owner` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` int NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.cache_locks: ~0 rows (approximately)
DELETE FROM `cache_locks`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.class_groups
CREATE TABLE IF NOT EXISTS `class_groups` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `class_label` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subject_id` INT unsigned NOT NULL,
  `short_name` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `is_major` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `class_groups_subject_id_foreign` (`subject_id`),
  CONSTRAINT `class_groups_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.class_groups: ~0 rows (approximately)
DELETE FROM `class_groups`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.cmp_ai_insights
CREATE TABLE IF NOT EXISTS `cmp_ai_insights` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `complaint_id` INT unsigned NOT NULL,
  `sentiment_score` decimal(4,3) DEFAULT NULL,
  `sentiment_label_id` INT unsigned DEFAULT NULL,
  `escalation_risk_score` decimal(5,2) DEFAULT NULL,
  `predicted_category_id` INT unsigned DEFAULT NULL,
  `safety_risk_score` decimal(5,2) DEFAULT NULL,
  `model_version` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `processed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ai_complaint` (`complaint_id`),
  KEY `cmp_ai_insights_sentiment_label_id_foreign` (`sentiment_label_id`),
  KEY `cmp_ai_insights_predicted_category_id_foreign` (`predicted_category_id`),
  KEY `idx_ai_risk` (`escalation_risk_score`),
  CONSTRAINT `cmp_ai_insights_complaint_id_foreign` FOREIGN KEY (`complaint_id`) REFERENCES `cmp_complaints` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `cmp_ai_insights_predicted_category_id_foreign` FOREIGN KEY (`predicted_category_id`) REFERENCES `cmp_complaint_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_ai_insights_sentiment_label_id_foreign` FOREIGN KEY (`sentiment_label_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.cmp_ai_insights: ~0 rows (approximately)
DELETE FROM `cmp_ai_insights`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.cmp_complaints
CREATE TABLE IF NOT EXISTS `cmp_complaints` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `ticket_no` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ticket_date` date NOT NULL,
  `complainant_type_id` INT unsigned NOT NULL,
  `complainant_user_id` INT unsigned DEFAULT NULL,
  `complainant_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `complainant_contact` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `target_type_id` INT unsigned NOT NULL,
  `target_id` INT unsigned DEFAULT NULL,
  `target_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `category_id` INT unsigned NOT NULL,
  `subcategory_id` INT unsigned DEFAULT NULL,
  `severity_level_id` INT unsigned NOT NULL,
  `priority_score_id` INT unsigned NOT NULL DEFAULT '3',
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `location_details` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `incident_date` datetime DEFAULT NULL,
  `incident_time` time DEFAULT NULL,
  `status_id` INT unsigned NOT NULL,
  `assigned_to_role_id` INT unsigned DEFAULT NULL,
  `assigned_to_user_id` INT unsigned DEFAULT NULL,
  `resolution_due_at` datetime DEFAULT NULL,
  `actual_resolved_at` datetime DEFAULT NULL,
  `resolved_by_role_id` INT unsigned DEFAULT NULL,
  `resolved_by_user_id` INT unsigned DEFAULT NULL,
  `resolution_summary` text COLLATE utf8mb4_unicode_ci,
  `escalation_level` tinyint unsigned NOT NULL DEFAULT '0',
  `is_escalated` tinyint(1) NOT NULL DEFAULT '0',
  `source_id` INT unsigned DEFAULT NULL,
  `is_anonymous` tinyint(1) NOT NULL DEFAULT '0',
  `dept_specific_info` json DEFAULT NULL,
  `is_medical_check_required` tinyint(1) NOT NULL DEFAULT '0',
  `support_file` tinyint(1) NOT NULL DEFAULT '0',
  `created_by` INT unsigned DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cmp_complaints_ticket_no_unique` (`ticket_no`),
  KEY `cmp_complaints_complainant_user_id_foreign` (`complainant_user_id`),
  KEY `cmp_complaints_category_id_foreign` (`category_id`),
  KEY `cmp_complaints_subcategory_id_foreign` (`subcategory_id`),
  KEY `cmp_complaints_severity_level_id_foreign` (`severity_level_id`),
  KEY `cmp_complaints_priority_score_id_foreign` (`priority_score_id`),
  KEY `cmp_complaints_assigned_to_role_id_foreign` (`assigned_to_role_id`),
  KEY `cmp_complaints_assigned_to_user_id_foreign` (`assigned_to_user_id`),
  KEY `cmp_complaints_resolved_by_role_id_foreign` (`resolved_by_role_id`),
  KEY `cmp_complaints_resolved_by_user_id_foreign` (`resolved_by_user_id`),
  KEY `cmp_complaints_source_id_foreign` (`source_id`),
  KEY `cmp_complaints_created_by_foreign` (`created_by`),
  KEY `idx_cmp_status` (`status_id`),
  KEY `idx_cmp_complainant` (`complainant_type_id`,`complainant_user_id`),
  KEY `idx_cmp_target` (`target_type_id`,`target_id`),
  CONSTRAINT `cmp_complaints_assigned_to_role_id_foreign` FOREIGN KEY (`assigned_to_role_id`) REFERENCES `sys_roles` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_complaints_assigned_to_user_id_foreign` FOREIGN KEY (`assigned_to_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_complaints_category_id_foreign` FOREIGN KEY (`category_id`) REFERENCES `cmp_complaint_categories` (`id`),
  CONSTRAINT `cmp_complaints_complainant_type_id_foreign` FOREIGN KEY (`complainant_type_id`) REFERENCES `sys_dropdowns` (`id`),
  CONSTRAINT `cmp_complaints_complainant_user_id_foreign` FOREIGN KEY (`complainant_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_complaints_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_complaints_priority_score_id_foreign` FOREIGN KEY (`priority_score_id`) REFERENCES `sys_dropdowns` (`id`),
  CONSTRAINT `cmp_complaints_resolved_by_role_id_foreign` FOREIGN KEY (`resolved_by_role_id`) REFERENCES `sys_roles` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_complaints_resolved_by_user_id_foreign` FOREIGN KEY (`resolved_by_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_complaints_severity_level_id_foreign` FOREIGN KEY (`severity_level_id`) REFERENCES `sys_dropdowns` (`id`),
  CONSTRAINT `cmp_complaints_source_id_foreign` FOREIGN KEY (`source_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_complaints_status_id_foreign` FOREIGN KEY (`status_id`) REFERENCES `sys_dropdowns` (`id`),
  CONSTRAINT `cmp_complaints_subcategory_id_foreign` FOREIGN KEY (`subcategory_id`) REFERENCES `cmp_complaint_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_complaints_target_type_id_foreign` FOREIGN KEY (`target_type_id`) REFERENCES `sys_dropdowns` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.cmp_complaints: ~0 rows (approximately)
DELETE FROM `cmp_complaints`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.cmp_complaint_actions
CREATE TABLE IF NOT EXISTS `cmp_complaint_actions` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `complaint_id` INT unsigned NOT NULL,
  `action_type_id` INT unsigned NOT NULL,
  `performed_by_user_id` INT unsigned DEFAULT NULL,
  `performed_by_role_id` INT unsigned DEFAULT NULL,
  `assigned_to_user_id` INT unsigned DEFAULT NULL,
  `assigned_to_role_id` INT unsigned DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `is_private_note` tinyint(1) NOT NULL DEFAULT '0',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cmp_complaint_actions_action_type_id_foreign` (`action_type_id`),
  KEY `cmp_complaint_actions_performed_by_user_id_foreign` (`performed_by_user_id`),
  KEY `cmp_complaint_actions_performed_by_role_id_foreign` (`performed_by_role_id`),
  KEY `cmp_complaint_actions_assigned_to_user_id_foreign` (`assigned_to_user_id`),
  KEY `cmp_complaint_actions_assigned_to_role_id_foreign` (`assigned_to_role_id`),
  KEY `idx_act_complaint` (`complaint_id`),
  CONSTRAINT `cmp_complaint_actions_action_type_id_foreign` FOREIGN KEY (`action_type_id`) REFERENCES `sys_dropdowns` (`id`),
  CONSTRAINT `cmp_complaint_actions_assigned_to_role_id_foreign` FOREIGN KEY (`assigned_to_role_id`) REFERENCES `sys_roles` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_complaint_actions_assigned_to_user_id_foreign` FOREIGN KEY (`assigned_to_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_complaint_actions_complaint_id_foreign` FOREIGN KEY (`complaint_id`) REFERENCES `cmp_complaints` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `cmp_complaint_actions_performed_by_role_id_foreign` FOREIGN KEY (`performed_by_role_id`) REFERENCES `sys_roles` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_complaint_actions_performed_by_user_id_foreign` FOREIGN KEY (`performed_by_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.cmp_complaint_actions: ~0 rows (approximately)
DELETE FROM `cmp_complaint_actions`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.cmp_complaint_categories
CREATE TABLE IF NOT EXISTS `cmp_complaint_categories` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` INT unsigned DEFAULT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `severity_level_id` INT unsigned DEFAULT NULL,
  `priority_score_id` INT unsigned DEFAULT NULL,
  `expected_resolution_hours` int unsigned NOT NULL,
  `escalation_hours_l1` int unsigned NOT NULL,
  `escalation_hours_l2` int unsigned NOT NULL,
  `escalation_hours_l3` int unsigned NOT NULL,
  `escalation_hours_l4` int unsigned NOT NULL,
  `escalation_hours_l5` int unsigned NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cmp_complaint_categories_severity_level_id_foreign` (`severity_level_id`),
  KEY `cmp_complaint_categories_priority_score_id_foreign` (`priority_score_id`),
  KEY `idx_cat_parent` (`parent_id`),
  CONSTRAINT `cmp_complaint_categories_parent_id_foreign` FOREIGN KEY (`parent_id`) REFERENCES `cmp_complaint_categories` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `cmp_complaint_categories_priority_score_id_foreign` FOREIGN KEY (`priority_score_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_complaint_categories_severity_level_id_foreign` FOREIGN KEY (`severity_level_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.cmp_complaint_categories: ~10 rows (approximately)
DELETE FROM `cmp_complaint_categories`;
INSERT INTO `cmp_complaint_categories` (`id`, `parent_id`, `name`, `code`, `description`, `severity_level_id`, `priority_score_id`, `expected_resolution_hours`, `escalation_hours_l1`, `escalation_hours_l2`, `escalation_hours_l3`, `escalation_hours_l4`, `escalation_hours_l5`, `is_active`, `deleted_at`, `created_at`, `updated_at`) VALUES
	(1, NULL, 'Academic Issues', 'ACADEMIC', 'Issues related to academics, classes, exams, or faculty', NULL, NULL, 48, 12, 24, 36, 48, 72, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(2, NULL, 'Infrastructure', 'INFRA', 'Infrastructure and facility related issues', NULL, NULL, 48, 12, 24, 36, 48, 72, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(3, NULL, 'Discipline & Conduct', 'DISCIPLINE', 'Misconduct, bullying, or discipline related complaints', NULL, NULL, 48, 12, 24, 36, 48, 72, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(4, NULL, 'Health & Safety', 'HEALTH', 'Medical, safety, or emergency related complaints', NULL, NULL, 48, 12, 24, 36, 48, 72, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(5, 1, 'Exam Schedule Issue', 'EXAM_SCHEDULE', NULL, NULL, NULL, 24, 6, 12, 18, 24, 48, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(6, 1, 'Faculty Related Issue', 'FACULTY', NULL, NULL, NULL, 24, 6, 12, 18, 24, 48, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(7, 2, 'Classroom Facilities', 'CLASSROOM', NULL, NULL, NULL, 24, 6, 12, 18, 24, 48, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(8, 2, 'Hostel / Accommodation', 'HOSTEL', NULL, NULL, NULL, 24, 6, 12, 18, 24, 48, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(9, 3, 'Ragging / Bullying', 'RAGGING', NULL, NULL, NULL, 24, 6, 12, 18, 24, 48, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(10, 4, 'Medical Emergency', 'MEDICAL', NULL, NULL, NULL, 24, 6, 12, 18, 24, 48, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14');

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.cmp_department_sla
CREATE TABLE IF NOT EXISTS `cmp_department_sla` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `complaint_category_id` INT unsigned DEFAULT NULL,
  `complaint_subcategory_id` INT unsigned DEFAULT NULL,
  `target_department_id` INT unsigned DEFAULT NULL,
  `target_designation_id` INT unsigned DEFAULT NULL,
  `target_role_id` INT unsigned DEFAULT NULL,
  `target_entity_group_id` INT unsigned DEFAULT NULL,
  `target_user_id` INT unsigned DEFAULT NULL,
  `target_vehicle_id` INT unsigned DEFAULT NULL,
  `target_vendor_id` INT unsigned DEFAULT NULL,
  `dept_expected_resolution_hours` int unsigned NOT NULL,
  `dept_escalation_hours_l1` int unsigned NOT NULL,
  `dept_escalation_hours_l2` int unsigned NOT NULL,
  `dept_escalation_hours_l3` int unsigned NOT NULL,
  `dept_escalation_hours_l4` int unsigned NOT NULL,
  `dept_escalation_hours_l5` int unsigned NOT NULL,
  `escalation_l1_entity_group_id` INT unsigned DEFAULT NULL,
  `escalation_l2_entity_group_id` INT unsigned DEFAULT NULL,
  `escalation_l3_entity_group_id` INT unsigned DEFAULT NULL,
  `escalation_l4_entity_group_id` INT unsigned DEFAULT NULL,
  `escalation_l5_entity_group_id` INT unsigned DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cmp_department_sla_complaint_category_id_foreign` (`complaint_category_id`),
  KEY `cmp_department_sla_complaint_subcategory_id_foreign` (`complaint_subcategory_id`),
  KEY `cmp_department_sla_target_department_id_foreign` (`target_department_id`),
  KEY `cmp_department_sla_target_designation_id_foreign` (`target_designation_id`),
  KEY `cmp_department_sla_target_role_id_foreign` (`target_role_id`),
  KEY `cmp_department_sla_target_entity_group_id_foreign` (`target_entity_group_id`),
  KEY `cmp_department_sla_target_user_id_foreign` (`target_user_id`),
  KEY `cmp_department_sla_target_vehicle_id_foreign` (`target_vehicle_id`),
  KEY `cmp_department_sla_target_vendor_id_foreign` (`target_vendor_id`),
  KEY `cmp_department_sla_escalation_l1_entity_group_id_foreign` (`escalation_l1_entity_group_id`),
  KEY `cmp_department_sla_escalation_l2_entity_group_id_foreign` (`escalation_l2_entity_group_id`),
  KEY `cmp_department_sla_escalation_l3_entity_group_id_foreign` (`escalation_l3_entity_group_id`),
  KEY `cmp_department_sla_escalation_l4_entity_group_id_foreign` (`escalation_l4_entity_group_id`),
  KEY `cmp_department_sla_escalation_l5_entity_group_id_foreign` (`escalation_l5_entity_group_id`),
  CONSTRAINT `cmp_department_sla_complaint_category_id_foreign` FOREIGN KEY (`complaint_category_id`) REFERENCES `cmp_complaint_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_department_sla_complaint_subcategory_id_foreign` FOREIGN KEY (`complaint_subcategory_id`) REFERENCES `cmp_complaint_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_department_sla_escalation_l1_entity_group_id_foreign` FOREIGN KEY (`escalation_l1_entity_group_id`) REFERENCES `sch_entity_groups` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_department_sla_escalation_l2_entity_group_id_foreign` FOREIGN KEY (`escalation_l2_entity_group_id`) REFERENCES `sch_entity_groups` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_department_sla_escalation_l3_entity_group_id_foreign` FOREIGN KEY (`escalation_l3_entity_group_id`) REFERENCES `sch_entity_groups` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_department_sla_escalation_l4_entity_group_id_foreign` FOREIGN KEY (`escalation_l4_entity_group_id`) REFERENCES `sch_entity_groups` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_department_sla_escalation_l5_entity_group_id_foreign` FOREIGN KEY (`escalation_l5_entity_group_id`) REFERENCES `sch_entity_groups` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_department_sla_target_department_id_foreign` FOREIGN KEY (`target_department_id`) REFERENCES `sch_department` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_department_sla_target_designation_id_foreign` FOREIGN KEY (`target_designation_id`) REFERENCES `sch_designation` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_department_sla_target_entity_group_id_foreign` FOREIGN KEY (`target_entity_group_id`) REFERENCES `sch_entity_groups` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_department_sla_target_role_id_foreign` FOREIGN KEY (`target_role_id`) REFERENCES `sys_roles` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_department_sla_target_user_id_foreign` FOREIGN KEY (`target_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_department_sla_target_vehicle_id_foreign` FOREIGN KEY (`target_vehicle_id`) REFERENCES `tpt_vehicle` (`id`) ON DELETE SET NULL,
  CONSTRAINT `cmp_department_sla_target_vendor_id_foreign` FOREIGN KEY (`target_vendor_id`) REFERENCES `vnd_vendors` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.cmp_department_sla: ~0 rows (approximately)
DELETE FROM `cmp_department_sla`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.cmp_medical_checks
CREATE TABLE IF NOT EXISTS `cmp_medical_checks` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `complaint_id` INT unsigned NOT NULL,
  `check_type` INT unsigned NOT NULL,
  `conducted_by` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `conducted_at` datetime NOT NULL,
  `result` INT unsigned NOT NULL,
  `reading_value` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `evidence_uploaded` tinyint(1) NOT NULL DEFAULT '0',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cmp_medical_checks_check_type_foreign` (`check_type`),
  KEY `cmp_medical_checks_result_foreign` (`result`),
  KEY `idx_med_complaint` (`complaint_id`),
  CONSTRAINT `cmp_medical_checks_check_type_foreign` FOREIGN KEY (`check_type`) REFERENCES `sys_dropdowns` (`id`),
  CONSTRAINT `cmp_medical_checks_complaint_id_foreign` FOREIGN KEY (`complaint_id`) REFERENCES `cmp_complaints` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `cmp_medical_checks_result_foreign` FOREIGN KEY (`result`) REFERENCES `sys_dropdowns` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.cmp_medical_checks: ~0 rows (approximately)
DELETE FROM `cmp_medical_checks`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.failed_jobs
CREATE TABLE IF NOT EXISTS `failed_jobs` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `connection` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `queue` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `exception` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.failed_jobs: ~0 rows (approximately)
DELETE FROM `failed_jobs`;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_cities
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE `glb_cities` (
	`id` BIGINT(20) UNSIGNED NOT NULL,
	`district_id` BIGINT(20) UNSIGNED NOT NULL,
	`name` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`short_name` VARCHAR(20) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`global_code` VARCHAR(20) NULL COLLATE 'utf8mb4_unicode_ci',
	`default_timezone` VARCHAR(64) NULL COLLATE 'utf8mb4_unicode_ci',
	`is_active` TINYINT(1) NOT NULL,
	`created_at` TIMESTAMP NULL,
	`updated_at` TIMESTAMP NULL,
	`deleted_at` TIMESTAMP NULL
) ENGINE=MyISAM;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_countries
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE `glb_countries` (
	`id` BIGINT(20) UNSIGNED NOT NULL,
	`name` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`short_name` VARCHAR(10) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`global_code` VARCHAR(10) NULL COLLATE 'utf8mb4_unicode_ci',
	`currency_code` VARCHAR(8) NULL COLLATE 'utf8mb4_unicode_ci',
	`is_active` TINYINT(1) NOT NULL,
	`created_at` TIMESTAMP NULL,
	`updated_at` TIMESTAMP NULL,
	`deleted_at` TIMESTAMP NULL
) ENGINE=MyISAM;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_districts
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE `glb_districts` (
	`id` BIGINT(20) UNSIGNED NOT NULL,
	`state_id` BIGINT(20) UNSIGNED NOT NULL,
	`name` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`short_name` VARCHAR(10) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`global_code` VARCHAR(10) NULL COLLATE 'utf8mb4_unicode_ci',
	`is_active` TINYINT(1) NOT NULL,
	`created_at` TIMESTAMP NULL,
	`updated_at` TIMESTAMP NULL,
	`deleted_at` TIMESTAMP NULL
) ENGINE=MyISAM;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_languages
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE `glb_languages` (
	`id` BIGINT(20) UNSIGNED NOT NULL,
	`code` VARCHAR(10) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`name` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`native_name` VARCHAR(50) NULL COLLATE 'utf8mb4_unicode_ci',
	`direction` ENUM('LTR','RTL') NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`is_active` TINYINT(1) NOT NULL,
	`deleted_at` TIMESTAMP NULL,
	`created_at` TIMESTAMP NULL,
	`updated_at` TIMESTAMP NULL
) ENGINE=MyISAM;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_menus
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE `glb_menus` (
	`id` BIGINT(20) UNSIGNED NOT NULL,
	`parent_id` BIGINT(20) UNSIGNED NULL,
	`is_category` TINYINT(1) NOT NULL,
	`code` VARCHAR(60) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`menu_for` ENUM('prime','tenant') NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`slug` VARCHAR(150) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`title` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`description` VARCHAR(255) NULL COLLATE 'utf8mb4_unicode_ci',
	`icon` VARCHAR(150) NULL COLLATE 'utf8mb4_unicode_ci',
	`route` VARCHAR(255) NULL COLLATE 'utf8mb4_unicode_ci',
	`permission` VARCHAR(255) NULL COLLATE 'utf8mb4_unicode_ci',
	`sort_order` INT(10) UNSIGNED NOT NULL,
	`visible_by_default` TINYINT(1) NOT NULL,
	`is_active` TINYINT(1) NOT NULL,
	`deleted_at` TIMESTAMP NULL,
	`created_at` TIMESTAMP NULL,
	`updated_at` TIMESTAMP NULL
) ENGINE=MyISAM;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_menu_module_jnt
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE `glb_menu_module_jnt` (
	`id` BIGINT(20) UNSIGNED NOT NULL,
	`menu_id` BIGINT(20) UNSIGNED NOT NULL,
	`module_id` BIGINT(20) UNSIGNED NOT NULL,
	`sort_order` INT(10) UNSIGNED NOT NULL,
	`created_at` TIMESTAMP NULL,
	`updated_at` TIMESTAMP NULL
) ENGINE=MyISAM;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_modules
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE `glb_modules` (
	`id` BIGINT(20) UNSIGNED NOT NULL,
	`parent_id` BIGINT(20) UNSIGNED NULL,
	`name` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`version` TINYINT(3) NOT NULL,
	`is_sub_module` TINYINT(1) NOT NULL,
	`description` VARCHAR(500) NULL COLLATE 'utf8mb4_unicode_ci',
	`is_core` TINYINT(1) NOT NULL,
	`default_visible` TINYINT(1) NOT NULL,
	`available_perm_view` TINYINT(1) NOT NULL,
	`available_perm_add` TINYINT(1) NOT NULL,
	`available_perm_edit` TINYINT(1) NOT NULL,
	`available_perm_delete` TINYINT(1) NOT NULL,
	`available_perm_export` TINYINT(1) NOT NULL,
	`available_perm_import` TINYINT(1) NOT NULL,
	`available_perm_print` TINYINT(1) NOT NULL,
	`is_active` TINYINT(1) NOT NULL,
	`deleted_at` TIMESTAMP NULL,
	`created_at` TIMESTAMP NULL,
	`updated_at` TIMESTAMP NULL
) ENGINE=MyISAM;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_states
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE `glb_states` (
	`id` BIGINT(20) UNSIGNED NOT NULL,
	`country_id` BIGINT(20) UNSIGNED NOT NULL,
	`name` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`short_name` VARCHAR(10) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`global_code` VARCHAR(10) NULL COLLATE 'utf8mb4_unicode_ci',
	`is_active` TINYINT(1) NOT NULL,
	`created_at` TIMESTAMP NULL,
	`updated_at` TIMESTAMP NULL,
	`deleted_at` TIMESTAMP NULL
) ENGINE=MyISAM;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_translations
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE `glb_translations` (
	`id` BIGINT(20) UNSIGNED NOT NULL,
	`translatable_type` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`translatable_id` BIGINT(20) UNSIGNED NOT NULL,
	`language_id` BIGINT(20) UNSIGNED NOT NULL,
	`key` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`value` TEXT NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`created_at` TIMESTAMP NULL,
	`updated_at` TIMESTAMP NULL
) ENGINE=MyISAM;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.jobs
CREATE TABLE IF NOT EXISTS `jobs` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `queue` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `attempts` tinyint unsigned NOT NULL,
  `reserved_at` int unsigned DEFAULT NULL,
  `available_at` int unsigned NOT NULL,
  `created_at` int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jobs_queue_index` (`queue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.jobs: ~0 rows (approximately)
DELETE FROM `jobs`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.job_batches
CREATE TABLE IF NOT EXISTS `job_batches` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_jobs` int NOT NULL,
  `pending_jobs` int NOT NULL,
  `failed_jobs` int NOT NULL,
  `failed_job_ids` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `options` mediumtext COLLATE utf8mb4_unicode_ci,
  `cancelled_at` int DEFAULT NULL,
  `created_at` int NOT NULL,
  `finished_at` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.job_batches: ~0 rows (approximately)
DELETE FROM `job_batches`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.migrations
CREATE TABLE IF NOT EXISTS `migrations` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=128 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.migrations: ~0 rows (approximately)
DELETE FROM `migrations`;
INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
	(1, '0001_01_01_000001_create_cache_table', 1),
	(2, '0001_01_01_000002_create_jobs_table', 1),
	(3, '2025_10_06_110647_create_permission_tables', 1),
	(4, '2025_10_06_112509_create_media_table', 1),
	(5, '2025_10_06_113652_create_personal_access_tokens_table', 1),
	(6, '2025_10_17_101827_create_organizations_table', 1),
	(7, '2025_10_17_101827_create_users_table', 1),
	(8, '2025_10_18_071401_make_organization_academic_sessions_table', 1),
	(9, '2025_10_18_085546_create_board_organization_table', 1),
	(10, '2025_10_27_044219_create_buildings_table', 1),
	(11, '2025_10_27_113828_create_subjects_table', 1),
	(12, '2025_10_27_153200_create_rooms_type_table', 1),
	(13, '2025_10_28_121239_create_rooms_table', 1),
	(14, '2025_10_30_045014_create_class_groups_table', 1),
	(15, '2025_10_30_093924_create_teachers_table', 1),
	(16, '2025_10_31_073119_create_study_formats_table', 1),
	(17, '2025_11_01_051814_create_subject_teachers_table', 1),
	(18, '2025_11_02_071024_create_activity_logs_table', 1),
	(19, '2025_11_03_095022_create_days_table', 1),
	(20, '2025_11_04_085212_create_periods_table', 1),
	(21, '2025_11_05_121505_create_timing_profiles_table', 1),
	(22, '2025_11_05_132119_create_school_timing_profile_table', 1),
	(23, '2025_11_08_105556_create_settings_table', 1),
	(24, '2025_11_11_055039_add_columns_to_roles_table', 1),
	(25, '2025_11_15_093113_create_students_table', 1),
	(26, '2025_11_15_095109_create_student_details_table', 1),
	(27, '2025_11_17_074813_create_school_classes_table', 1),
	(28, '2025_11_17_082615_create_sections_table', 1),
	(29, '2025_11_17_090225_create_class_sections_table', 1),
	(30, '2025_11_17_101312_create_student_academic_sessions_table', 1),
	(31, '2025_11_18_033644_create_subject_groups_table', 1),
	(32, '2025_11_18_033660_create_subject_group_subject_table', 1),
	(33, '2025_11_18_043026_create_subject_types_table', 1),
	(34, '2025_11_18_044017_create_subject_study_formats_table', 1),
	(35, '2025_11_18_044704_create_subject_study_format_classes_table', 1),
	(36, '2025_11_18_052235_create_glb_billing_cycle_table', 1),
	(37, '2025_11_18_114617_create_dropdown_needs_table', 1),
	(38, '2025_11_18_114618_create_dropdowns_table', 1),
	(39, '2025_11_24_121608_create_sch_subject_group_subject_jnt_table', 1),
	(40, '2025_11_29_123000_create_global_views_for_tenants', 1),
	(41, '2025_12_01_084015_create_tpt_shift_table', 1),
	(42, '2025_12_01_085651_create_tpt_vehicle_table', 1),
	(43, '2025_12_01_085728_create_tpt_route_table', 1),
	(44, '2025_12_01_085753_create_tpt_pickup_points_table', 1),
	(45, '2025_12_01_085819_create_tpt_personnel_table', 1),
	(46, '2025_12_01_085843_create_tpt_pickup_points_route_jnt_table', 1),
	(47, '2025_12_02_102454_create_teacher_profiles_table', 1),
	(48, '2025_12_08_045340_create_lessons_table', 1),
	(49, '2025_12_08_094240_create_topics_table', 1),
	(50, '2025_12_08_123858_create_tpt_driver_route_vehicle_jnt_table', 1),
	(51, '2025_12_08_125923_create_tpt_route_scheduler_jnt_table', 1),
	(52, '2025_12_08_125934_create_tpt_trip_table', 1),
	(53, '2025_12_08_125943_create_tpt_live_trip_table', 1),
	(54, '2025_12_08_125957_create_tpt_driver_attendance_table', 1),
	(55, '2025_12_08_130026_create_tpt_fee_master_table', 1),
	(56, '2025_12_08_130042_create_tpt_fee_collection_table', 1),
	(57, '2025_12_08_130050_create_ml_models_table', 1),
	(58, '2025_12_08_130059_create_ml_model_features_table', 1),
	(59, '2025_12_08_130338_create_tpt_feature_store_table', 1),
	(60, '2025_12_08_130356_create_tpt_model_recommendations_table', 1),
	(61, '2025_12_08_130409_create_tpt_recommendation_history_table', 1),
	(62, '2025_12_08_130415_create_tpt_student_event_log_table', 1),
	(63, '2025_12_08_130422_create_tpt_trip_incidents_table', 1),
	(64, '2025_12_08_130429_create_tpt_gps_trip_log_table', 1),
	(65, '2025_12_08_130437_create_tpt_gps_alerts_table', 1),
	(66, '2025_12_08_130505_create_tpt_notification_log_table', 1),
	(67, '2025_12_09_000001_create_slb_competency_types_table', 1),
	(68, '2025_12_10_062116_create_competencies_table', 1),
	(69, '2025_12_12_074045_create_room_unavailables_table', 1),
	(70, '2025_12_12_081915_create_timing_profile_periods_table', 1),
	(71, '2025_12_15_115619_create_tpt_fine_master_table', 1),
	(72, '2025_12_17_104649_create_tpt_trip_stop_detail_table', 1),
	(73, '2025_12_22_060146_create_complaint_categories_table', 1),
	(74, '2025_12_22_065413_create_complaints_table', 1),
	(75, '2025_12_22_070357_create_complaint_actions_table', 1),
	(76, '2025_12_22_072653_create_medical_checks_table', 1),
	(77, '2025_12_22_074156_create_ai_insights_table', 1),
	(78, '2025_12_22_095446_create_topic_competencies_table', 1),
	(79, '2025_12_22_124231_create_slb_complexity_levels_table', 1),
	(80, '2025_12_22_124334_create_slb_question_types_table', 1),
	(81, '2025_12_23_065158_create_tpt_attendance_devices_table', 1),
	(82, '2025_12_23_070459_create_departments_table', 1),
	(83, '2025_12_23_070548_create_designations_table', 1),
	(84, '2025_12_23_070631_create_entity_groups_table', 1),
	(85, '2025_12_23_070704_create_entity_group_members_table', 1),
	(86, '2025_12_23_123512_create_tpt_vehicle_fuel_table', 1),
	(87, '2025_12_23_172704_create_tpt_daily_vehicle_inspections_table', 1),
	(88, '2025_12_23_173614_create_tpt_vehicle_service_requests_table', 1),
	(89, '2025_12_23_175505_create_tpt_vehicle_maintenances_table', 1),
	(90, '2025_12_24_044437_create_vnd_vendors_table', 1),
	(91, '2025_12_24_121416_create_tpt_student_fine_detail_table', 1),
	(92, '2025_12_25_062953_create_department_slas_table', 1),
	(93, '2025_12_25_070244_create_std_student_pay_log_table', 1),
	(94, '2025_12_26_063754_create_vnd_agreements_table', 1),
	(95, '2025_12_26_094507_create_vnd_items_table', 1),
	(96, '2025_12_26_125616_create_vnd_agreement_items_jnt', 1),
	(97, '2025_12_29_120957_create_vnd_invoices_table', 1),
	(98, '2025_12_30_052047_create_tpt_student_boarding_log_table', 1),
	(99, '2025_12_30_103011_create_vnd_payments_table', 1),
	(100, '2025_12_31_043824_create_vnd_usage_logs_table', 1),
	(101, '2025_12_31_045403_create_notifications_table', 1),
	(102, '2026_01_01_085808_create_tpt_student_route_allocation_jnts_table', 1),
	(103, '2026_01_02_112016_create_schedules_table', 1),
	(104, '2026_01_02_155143_create_schedule_runs_table', 1),
	(105, '2026_01_03_121125_create_notifications_table', 1),
	(106, '2026_01_03_122350_create_channel_masters_table', 1),
	(107, '2026_01_03_122355_create_notification_channels_table', 1),
	(108, '2026_01_03_122751_create_notification_targets_table', 1),
	(109, '2026_01_03_123213_create_user_preferences_table', 1),
	(110, '2026_01_03_123514_create_notification_templates_table', 1),
	(111, '2026_01_03_123749_create_notification_delivery_logs_table', 1),
	(112, '2026_01_06_161410_create_bloom_taxonomies_table', 1),
	(113, '2026_01_06_161741_create_cognitive_skills_table', 1),
	(114, '2026_01_06_163239_create_que_type_specifities_table', 1),
	(115, '2026_01_06_163521_create_complexity_levels_table', 1),
	(116, '2026_01_06_164504_create_performance_categories_table', 1),
	(117, '2026_01_06_164702_create_grade_divisions_table', 1),
	(118, '2026_01_06_171520_create_question_banks_table', 1),
	(119, '2026_01_06_172432_create_books_table', 1),
	(120, '2026_01_06_172918_create_book_authors_table', 1),
	(121, '2026_01_06_173504_create_question_options_table', 1),
	(122, '2026_01_07_112506_create_author_books_table', 1),
	(123, '2026_01_07_114850_create_book_class_subjects_table', 1),
	(124, '2026_01_07_115350_create_book_topic_mappings_table', 1),
	(125, '2026_01_07_121345_create_study_material_types_table', 1),
	(126, '2026_01_07_121708_create_study_materials_table', 1),
	(127, '2026_01_07_124548_create_topic_dependencies_table', 1);

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ml_models
CREATE TABLE IF NOT EXISTS `ml_models` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `version` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `model_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `artifact_uri` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `parameters` json DEFAULT NULL,
  `metrics` json DEFAULT NULL,
  `status` enum('TRAINED','DEPLOYED','DEPRECATED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'TRAINED',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ml_models: ~0 rows (approximately)
DELETE FROM `ml_models`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ml_model_features
CREATE TABLE IF NOT EXISTS `ml_model_features` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `model_id` INT unsigned NOT NULL,
  `feature_name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `feature_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `transformation` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ml_model_features_model_id_foreign` (`model_id`),
  CONSTRAINT `ml_model_features_model_id_foreign` FOREIGN KEY (`model_id`) REFERENCES `ml_models` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ml_model_features: ~0 rows (approximately)
DELETE FROM `ml_model_features`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.notifications
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notifiable_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notifiable_id` INT unsigned NOT NULL,
  `data` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `notifications_notifiable_type_notifiable_id_index` (`notifiable_type`,`notifiable_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.notifications: ~0 rows (approximately)
DELETE FROM `notifications`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ntf_channel_master
CREATE TABLE IF NOT EXISTS `ntf_channel_master` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'APP, SMS, EMAIL, WHATSAPP',
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `max_retry` int NOT NULL DEFAULT '1' COMMENT 'Maximum number of retries for failed notifications',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ntf_channel_code` (`code`),
  UNIQUE KEY `uq_ntf_channel_name` (`name`),
  KEY `idx_ntf_channel_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ntf_channel_master: ~0 rows (approximately)
DELETE FROM `ntf_channel_master`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ntf_notifications
CREATE TABLE IF NOT EXISTS `ntf_notifications` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `source_module` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notification_event` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Triggering event: Student Registered, Exam Result Published',
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `template_id` INT unsigned DEFAULT NULL,
  `priority_id` INT unsigned NOT NULL,
  `confidentiality_level_id` INT unsigned NOT NULL,
  `scheduled_at` datetime DEFAULT NULL,
  `recurring` tinyint(1) NOT NULL DEFAULT '0',
  `recurring_interval_id` INT unsigned NOT NULL,
  `recurring_end_at` datetime DEFAULT NULL,
  `recurring_end_count` int DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  `created_by` INT unsigned NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ntf_notifications_priority_id_foreign` (`priority_id`),
  KEY `ntf_notifications_confidentiality_level_id_foreign` (`confidentiality_level_id`),
  KEY `ntf_notifications_recurring_interval_id_foreign` (`recurring_interval_id`),
  KEY `ntf_notifications_source_module_index` (`source_module`),
  KEY `ntf_notifications_scheduled_at_index` (`scheduled_at`),
  CONSTRAINT `ntf_notifications_confidentiality_level_id_foreign` FOREIGN KEY (`confidentiality_level_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ntf_notifications_priority_id_foreign` FOREIGN KEY (`priority_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ntf_notifications_recurring_interval_id_foreign` FOREIGN KEY (`recurring_interval_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ntf_notifications: ~0 rows (approximately)
DELETE FROM `ntf_notifications`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ntf_notification_channels
CREATE TABLE IF NOT EXISTS `ntf_notification_channels` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `notification_id` INT unsigned NOT NULL,
  `channel_id` INT unsigned NOT NULL,
  `provider_id` INT unsigned DEFAULT NULL,
  `status_id` INT unsigned NOT NULL,
  `scheduled_at` datetime DEFAULT NULL COMMENT 'Scheduled time for notifications',
  `sent_at` datetime DEFAULT NULL COMMENT 'Actual time when notification was sent',
  `failure_reason` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `retry_count` int NOT NULL DEFAULT '0',
  `max_retry` int NOT NULL DEFAULT '3',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_notification_channel` (`notification_id`,`channel_id`),
  KEY `ntf_notification_channels_channel_id_foreign` (`channel_id`),
  KEY `ntf_notification_channels_provider_id_foreign` (`provider_id`),
  KEY `idx_ntf_channel_status` (`status_id`),
  KEY `idx_ntf_channel_scheduled_at` (`scheduled_at`),
  CONSTRAINT `ntf_notification_channels_channel_id_foreign` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ntf_notification_channels_notification_id_foreign` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ntf_notification_channels_provider_id_foreign` FOREIGN KEY (`provider_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ntf_notification_channels_status_id_foreign` FOREIGN KEY (`status_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ntf_notification_channels: ~0 rows (approximately)
DELETE FROM `ntf_notification_channels`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ntf_notification_delivery_logs
CREATE TABLE IF NOT EXISTS `ntf_notification_delivery_logs` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `notification_id` INT unsigned NOT NULL,
  `channel_id` INT unsigned NOT NULL,
  `user_id` INT unsigned NOT NULL,
  `delivery_status_id` INT unsigned NOT NULL,
  `delivered_at` datetime DEFAULT NULL,
  `read_at` datetime DEFAULT NULL,
  `response_payload` json DEFAULT NULL COMMENT 'Provider response',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ntf_notification_delivery_logs_notification_id_foreign` (`notification_id`),
  KEY `ntf_notification_delivery_logs_channel_id_foreign` (`channel_id`),
  KEY `idx_ntf_delivery_user` (`user_id`),
  KEY `idx_ntf_delivery_status` (`delivery_status_id`),
  CONSTRAINT `ntf_notification_delivery_logs_channel_id_foreign` FOREIGN KEY (`channel_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ntf_notification_delivery_logs_delivery_status_id_foreign` FOREIGN KEY (`delivery_status_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ntf_notification_delivery_logs_notification_id_foreign` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ntf_notification_delivery_logs_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ntf_notification_delivery_logs: ~0 rows (approximately)
DELETE FROM `ntf_notification_delivery_logs`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ntf_notification_targets
CREATE TABLE IF NOT EXISTS `ntf_notification_targets` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `notification_id` INT unsigned NOT NULL,
  `target_type_id` INT unsigned NOT NULL,
  `target_table_name` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'sys_user, sys_role, sch_department, sch_designation, sch_classes, sch_sections, etc.',
  `target_selected_id` INT unsigned DEFAULT NULL COMMENT 'user_id, role_id, department_id, etc.',
  `resolved_user_id` INT unsigned DEFAULT NULL COMMENT 'Final resolved recipient user_id',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ntf_notification_targets_notification_id_foreign` (`notification_id`),
  KEY `idx_ntf_target_lookup` (`target_type_id`,`target_selected_id`),
  KEY `idx_ntf_target_user` (`resolved_user_id`),
  CONSTRAINT `ntf_notification_targets_notification_id_foreign` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ntf_notification_targets_target_type_id_foreign` FOREIGN KEY (`target_type_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ntf_notification_targets: ~0 rows (approximately)
DELETE FROM `ntf_notification_targets`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ntf_notification_templates
CREATE TABLE IF NOT EXISTS `ntf_notification_templates` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `template_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `channel_id` INT unsigned NOT NULL,
  `subject` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Used for Email',
  `body` text COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Supports {{placeholders}}',
  `language_code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'en',
  `media_id` INT unsigned DEFAULT NULL,
  `is_system_template` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_template_code_channel` (`template_code`,`channel_id`),
  KEY `ntf_notification_templates_channel_id_foreign` (`channel_id`),
  KEY `ntf_notification_templates_media_id_foreign` (`media_id`),
  CONSTRAINT `ntf_notification_templates_channel_id_foreign` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ntf_notification_templates_media_id_foreign` FOREIGN KEY (`media_id`) REFERENCES `sys_media` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ntf_notification_templates: ~0 rows (approximately)
DELETE FROM `ntf_notification_templates`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ntf_user_preferences
CREATE TABLE IF NOT EXISTS `ntf_user_preferences` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `user_id` INT unsigned NOT NULL,
  `channel_id` INT unsigned NOT NULL,
  `is_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `quiet_hours_start` time DEFAULT NULL,
  `quiet_hours_end` time DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_channel` (`user_id`,`channel_id`),
  KEY `ntf_user_preferences_channel_id_foreign` (`channel_id`),
  CONSTRAINT `ntf_user_preferences_channel_id_foreign` FOREIGN KEY (`channel_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ntf_user_preferences_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.ntf_user_preferences: ~0 rows (approximately)
DELETE FROM `ntf_user_preferences`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.password_reset_tokens
CREATE TABLE IF NOT EXISTS `password_reset_tokens` (
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.password_reset_tokens: ~0 rows (approximately)
DELETE FROM `password_reset_tokens`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.personal_access_tokens
CREATE TABLE IF NOT EXISTS `personal_access_tokens` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `tokenable_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tokenable_id` INT unsigned NOT NULL,
  `name` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `abilities` text COLLATE utf8mb4_unicode_ci,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  KEY `personal_access_tokens_expires_at_index` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.personal_access_tokens: ~0 rows (approximately)
DELETE FROM `personal_access_tokens`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.prm_billing_cycles
CREATE TABLE IF NOT EXISTS `prm_billing_cycles` (
  `id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `short_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `months_count` tinyint unsigned NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prm_billing_cycles_short_name_unique` (`short_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.prm_billing_cycles: ~0 rows (approximately)
DELETE FROM `prm_billing_cycles`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.qns_questions_bank
CREATE TABLE IF NOT EXISTS `qns_questions_bank` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varbinary(16) NOT NULL COMMENT 'UUID stored as BINARY(16)',
  `class_id` INT unsigned DEFAULT NULL,
  `subject_id` INT unsigned DEFAULT NULL,
  `lesson_id` INT unsigned DEFAULT NULL,
  `topic_id` INT unsigned DEFAULT NULL,
  `competency_id` INT unsigned DEFAULT NULL,
  `ques_title` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ques_title_display` tinyint(1) NOT NULL DEFAULT '0',
  `question_content` text COLLATE utf8mb4_unicode_ci,
  `content_format` enum('TEXT','HTML','MARKDOWN','LATEX','JSON') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'TEXT',
  `teacher_explanation` text COLLATE utf8mb4_unicode_ci,
  `bloom_id` INT unsigned DEFAULT NULL,
  `cognitive_skill_id` INT unsigned DEFAULT NULL,
  `ques_type_specificity_id` INT unsigned DEFAULT NULL,
  `complexity_level_id` INT unsigned DEFAULT NULL,
  `question_type_id` INT unsigned NOT NULL,
  `ques_reviewed_by` INT unsigned DEFAULT NULL,
  `created_by` INT unsigned DEFAULT NULL,
  `selected_section_id` INT unsigned DEFAULT NULL,
  `selected_student_id` INT unsigned DEFAULT NULL,
  `topper_time_to_answer_seconds` int unsigned DEFAULT NULL,
  `average_time_to_answer_seconds` int unsigned DEFAULT NULL,
  `marks` decimal(5,2) NOT NULL DEFAULT '1.00',
  `negative_marks` decimal(5,2) NOT NULL DEFAULT '0.00',
  `ques_reviewed` tinyint(1) NOT NULL DEFAULT '0',
  `ques_reviewed_at` timestamp NULL DEFAULT NULL,
  `ques_reviewed_status` enum('PENDING','APPROVED','REJECTED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `current_version` tinyint unsigned NOT NULL DEFAULT '1',
  `for_quiz` tinyint(1) NOT NULL DEFAULT '1',
  `for_assessment` tinyint(1) NOT NULL DEFAULT '1',
  `for_exam` tinyint(1) NOT NULL DEFAULT '1',
  `ques_owner` enum('PrimeGurukul','School') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PrimeGurukul',
  `created_by_AI` tinyint(1) NOT NULL DEFAULT '0',
  `is_school_specific` tinyint(1) NOT NULL DEFAULT '0',
  `availability` enum('GLOBAL','SCHOOL_ONLY','CLASS_ONLY','SECTION_ONLY','ENTITY_ONLY','STUDENT_ONLY') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'GLOBAL',
  `book_page_ref` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `external_ref` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reference_material` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `qns_questions_bank_uuid_unique` (`uuid`),
  KEY `qns_questions_bank_subject_id_foreign` (`subject_id`),
  KEY `qns_questions_bank_lesson_id_foreign` (`lesson_id`),
  KEY `qns_questions_bank_topic_id_foreign` (`topic_id`),
  KEY `qns_questions_bank_competency_id_foreign` (`competency_id`),
  KEY `qns_questions_bank_bloom_id_foreign` (`bloom_id`),
  KEY `qns_questions_bank_cognitive_skill_id_foreign` (`cognitive_skill_id`),
  KEY `qns_questions_bank_ques_type_specificity_id_foreign` (`ques_type_specificity_id`),
  KEY `qns_questions_bank_question_type_id_foreign` (`question_type_id`),
  KEY `qns_questions_bank_ques_reviewed_by_foreign` (`ques_reviewed_by`),
  KEY `qns_questions_bank_created_by_foreign` (`created_by`),
  KEY `qns_questions_bank_selected_section_id_foreign` (`selected_section_id`),
  KEY `qns_questions_bank_selected_student_id_foreign` (`selected_student_id`),
  KEY `idx_ques_class_subject` (`class_id`,`subject_id`),
  KEY `idx_ques_complexity_bloom` (`complexity_level_id`,`bloom_id`),
  KEY `qns_questions_bank_availability_index` (`availability`),
  KEY `qns_questions_bank_is_active_index` (`is_active`),
  CONSTRAINT `qns_questions_bank_bloom_id_foreign` FOREIGN KEY (`bloom_id`) REFERENCES `slb_bloom_taxonomy` (`id`) ON DELETE SET NULL,
  CONSTRAINT `qns_questions_bank_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `qns_questions_bank_cognitive_skill_id_foreign` FOREIGN KEY (`cognitive_skill_id`) REFERENCES `slb_cognitive_skill` (`id`) ON DELETE SET NULL,
  CONSTRAINT `qns_questions_bank_competency_id_foreign` FOREIGN KEY (`competency_id`) REFERENCES `slb_competencies` (`id`) ON DELETE SET NULL,
  CONSTRAINT `qns_questions_bank_complexity_level_id_foreign` FOREIGN KEY (`complexity_level_id`) REFERENCES `slb_complexity_level` (`id`) ON DELETE SET NULL,
  CONSTRAINT `qns_questions_bank_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `qns_questions_bank_lesson_id_foreign` FOREIGN KEY (`lesson_id`) REFERENCES `slb_lessons` (`id`) ON DELETE SET NULL,
  CONSTRAINT `qns_questions_bank_ques_reviewed_by_foreign` FOREIGN KEY (`ques_reviewed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `qns_questions_bank_ques_type_specificity_id_foreign` FOREIGN KEY (`ques_type_specificity_id`) REFERENCES `slb_ques_type_specificity` (`id`) ON DELETE SET NULL,
  CONSTRAINT `qns_questions_bank_question_type_id_foreign` FOREIGN KEY (`question_type_id`) REFERENCES `slb_question_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `qns_questions_bank_selected_section_id_foreign` FOREIGN KEY (`selected_section_id`) REFERENCES `sch_sections` (`id`) ON DELETE SET NULL,
  CONSTRAINT `qns_questions_bank_selected_student_id_foreign` FOREIGN KEY (`selected_student_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `qns_questions_bank_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `qns_questions_bank_topic_id_foreign` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.qns_questions_bank: ~0 rows (approximately)
DELETE FROM `qns_questions_bank`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.qns_question_options
CREATE TABLE IF NOT EXISTS `qns_question_options` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `question_bank_id` INT unsigned NOT NULL,
  `ordinal` smallint unsigned DEFAULT NULL COMMENT 'Ordinal position of this option',
  `option_text` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_correct` tinyint(1) NOT NULL DEFAULT '0',
  `explanation` text COLLATE utf8mb4_unicode_ci COMMENT 'Why this option is correct / incorrect',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_opt_question` (`question_bank_id`),
  CONSTRAINT `qns_question_options_question_bank_id_foreign` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.qns_question_options: ~0 rows (approximately)
DELETE FROM `qns_question_options`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.schedules
CREATE TABLE IF NOT EXISTS `schedules` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `schedule_type` enum('prime','tenant') COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenant_id` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `job_key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` json DEFAULT NULL,
  `cron_expression` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `last_run_at` timestamp NULL DEFAULT NULL,
  `next_run_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `schedules_schedule_type_index` (`schedule_type`),
  KEY `schedules_tenant_id_index` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.schedules: ~0 rows (approximately)
DELETE FROM `schedules`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.schedule_runs
CREATE TABLE IF NOT EXISTS `schedule_runs` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `schedule_id` INT unsigned NOT NULL,
  `tenant_id` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('running','success','failed') COLLATE utf8mb4_unicode_ci NOT NULL,
  `error_message` text COLLATE utf8mb4_unicode_ci,
  `started_at` timestamp NOT NULL,
  `finished_at` timestamp NULL DEFAULT NULL,
  `duration_ms` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `schedule_runs_schedule_id_foreign` (`schedule_id`),
  KEY `schedule_runs_tenant_id_index` (`tenant_id`),
  KEY `schedule_runs_status_index` (`status`),
  CONSTRAINT `schedule_runs_schedule_id_foreign` FOREIGN KEY (`schedule_id`) REFERENCES `schedules` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.schedule_runs: ~0 rows (approximately)
DELETE FROM `schedule_runs`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.school_timing_profiles
CREATE TABLE IF NOT EXISTS `school_timing_profiles` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `profile_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `school_timing_profiles_profile_name_unique` (`profile_name`),
  UNIQUE KEY `school_timing_profiles_short_name_unique` (`short_name`),
  KEY `idx_sch_profile_active_deleted` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.school_timing_profiles: ~0 rows (approximately)
DELETE FROM `school_timing_profiles`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_board_organization_jnt
CREATE TABLE IF NOT EXISTS `sch_board_organization_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `board_id` INT unsigned NOT NULL,
  `academic_sessions_id` INT unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sch_board_organization_jnt_board_id_foreign` (`board_id`),
  KEY `sch_board_organization_jnt_academic_sessions_id_foreign` (`academic_sessions_id`),
  CONSTRAINT `sch_board_organization_jnt_academic_sessions_id_foreign` FOREIGN KEY (`academic_sessions_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_board_organization_jnt_board_id_foreign` FOREIGN KEY (`board_id`) REFERENCES `global_master`.`glb_boards` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_board_organization_jnt: ~0 rows (approximately)
DELETE FROM `sch_board_organization_jnt`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_buildings
CREATE TABLE IF NOT EXISTS `sch_buildings` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` char(2) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_buildings_code` (`code`),
  UNIQUE KEY `uq_buildings_shortName` (`short_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_buildings: ~0 rows (approximately)
DELETE FROM `sch_buildings`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_classes
CREATE TABLE IF NOT EXISTS `sch_classes` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ordinal` tinyint DEFAULT NULL,
  `code` char(3) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_classes: ~0 rows (approximately)
DELETE FROM `sch_classes`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_class_groups_jnt
CREATE TABLE IF NOT EXISTS `sch_class_groups_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `sub_stdy_frmt_id` INT unsigned NOT NULL,
  `class_id` INT unsigned NOT NULL,
  `rooms_type_id` INT unsigned NOT NULL,
  `section_id` INT unsigned DEFAULT NULL,
  `subject_type_id` INT unsigned NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` char(17) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_classGroup_code` (`code`),
  UNIQUE KEY `uq_classGroup_subStdFmt_class_section_subjectType` (`sub_stdy_frmt_id`,`class_id`,`section_id`,`subject_type_id`),
  KEY `sch_class_groups_jnt_class_id_foreign` (`class_id`),
  KEY `sch_class_groups_jnt_section_id_foreign` (`section_id`),
  KEY `sch_class_groups_jnt_subject_type_id_foreign` (`subject_type_id`),
  KEY `sch_class_groups_jnt_rooms_type_id_foreign` (`rooms_type_id`),
  CONSTRAINT `sch_class_groups_jnt_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_class_groups_jnt_rooms_type_id_foreign` FOREIGN KEY (`rooms_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_class_groups_jnt_section_id_foreign` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_class_groups_jnt_sub_stdy_frmt_id_foreign` FOREIGN KEY (`sub_stdy_frmt_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_class_groups_jnt_subject_type_id_foreign` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_class_groups_jnt: ~0 rows (approximately)
DELETE FROM `sch_class_groups_jnt`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_class_section_jnt
CREATE TABLE IF NOT EXISTS `sch_class_section_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `class_id` INT unsigned NOT NULL,
  `section_id` INT unsigned NOT NULL,
  `class_teacher_id` INT unsigned NOT NULL,
  `assistance_class_teacher_id` INT unsigned NOT NULL,
  `class_section_code` char(5) COLLATE utf8mb4_unicode_ci NOT NULL,
  `capacity` tinyint unsigned DEFAULT NULL,
  `total_student` tinyint unsigned DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sch_class_section_jnt_class_id_foreign` (`class_id`),
  KEY `sch_class_section_jnt_section_id_foreign` (`section_id`),
  KEY `sch_class_section_jnt_class_teacher_id_foreign` (`class_teacher_id`),
  KEY `sch_class_section_jnt_assistance_class_teacher_id_foreign` (`assistance_class_teacher_id`),
  CONSTRAINT `sch_class_section_jnt_assistance_class_teacher_id_foreign` FOREIGN KEY (`assistance_class_teacher_id`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_class_section_jnt_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_class_section_jnt_class_teacher_id_foreign` FOREIGN KEY (`class_teacher_id`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_class_section_jnt_section_id_foreign` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_class_section_jnt: ~0 rows (approximately)
DELETE FROM `sch_class_section_jnt`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_department
CREATE TABLE IF NOT EXISTS `sch_department` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_department: ~0 rows (approximately)
DELETE FROM `sch_department`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_designation
CREATE TABLE IF NOT EXISTS `sch_designation` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_designation: ~0 rows (approximately)
DELETE FROM `sch_designation`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_entity_groups
CREATE TABLE IF NOT EXISTS `sch_entity_groups` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `entity_purpose_id` INT unsigned NOT NULL,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_code` (`code`),
  KEY `sch_entity_groups_entity_purpose_id_foreign` (`entity_purpose_id`),
  CONSTRAINT `sch_entity_groups_entity_purpose_id_foreign` FOREIGN KEY (`entity_purpose_id`) REFERENCES `sys_dropdowns` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_entity_groups: ~0 rows (approximately)
DELETE FROM `sch_entity_groups`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_entity_groups_members
CREATE TABLE IF NOT EXISTS `sch_entity_groups_members` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `entity_group_id` INT unsigned DEFAULT NULL,
  `entity_type_id` INT unsigned DEFAULT NULL,
  `entity_table_name` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `entity_selected_id` INT unsigned DEFAULT NULL,
  `entity_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `entity_code` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_egm_entity_group` (`entity_group_id`),
  KEY `idx_egm_entity_type` (`entity_type_id`),
  KEY `idx_egm_entity_lookup` (`entity_type_id`,`entity_selected_id`),
  CONSTRAINT `sch_entity_groups_members_entity_group_id_foreign` FOREIGN KEY (`entity_group_id`) REFERENCES `sch_entity_groups` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_entity_groups_members_entity_type_id_foreign` FOREIGN KEY (`entity_type_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_entity_groups_members: ~0 rows (approximately)
DELETE FROM `sch_entity_groups_members`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_organizations
CREATE TABLE IF NOT EXISTS `sch_organizations` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `group_code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `group_short_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `group_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `udise_code` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `affiliation_no` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `website_url` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address_1` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address_2` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `area` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city_id` INT unsigned NOT NULL,
  `pincode` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone_1` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone_2` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `whatsapp_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `locale` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'en_IN',
  `currency` varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'INR',
  `established_date` date DEFAULT NULL,
  `flg_single_record` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `chk_org_singleRecord` (`flg_single_record`),
  KEY `sch_organizations_city_id_foreign` (`city_id`),
  CONSTRAINT `sch_organizations_city_id_foreign` FOREIGN KEY (`city_id`) REFERENCES `global_master`.`glb_cities` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_organizations: ~0 rows (approximately)
DELETE FROM `sch_organizations`;
INSERT INTO `sch_organizations` (`id`, `tenant_id`, `group_code`, `group_short_name`, `group_name`, `code`, `short_name`, `name`, `udise_code`, `affiliation_no`, `email`, `website_url`, `address_1`, `address_2`, `area`, `city_id`, `pincode`, `phone_1`, `phone_2`, `whatsapp_number`, `longitude`, `latitude`, `locale`, `currency`, `established_date`, `flg_single_record`, `is_active`, `deleted_at`, `created_at`, `updated_at`) VALUES
	(1, 'b18c29eb-0e01-4f13-93e1-4418e239a4d3', '1', 'Test School', 'Test School', 'TEST001', 'Test School', 'Test School Tenant', 'UD123456', 'AFF123', 'test@tenant.com', 'https://testtenant.com', 'Address Line 1', 'Address Line 2', 'City Area', 1, '000000', '9999999999', NULL, '9999999999', 77.1234567, 31.1234567, 'en_IN', 'INR', '2021-01-12', 1, 1, NULL, '2026-01-12 12:55:06', '2026-01-12 12:55:06');

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_org_academic_sessions_jnt
CREATE TABLE IF NOT EXISTS `sch_org_academic_sessions_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `academic_session_id` INT unsigned NOT NULL,
  `short_name` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `current_flag` tinyint(1) NOT NULL DEFAULT '0',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sch_org_academic_sessions_jnt_academic_session_id_foreign` (`academic_session_id`),
  KEY `idx_orgAcademicSessions_active` (`is_active`),
  CONSTRAINT `sch_org_academic_sessions_jnt_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `global_master`.`glb_academic_sessions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_org_academic_sessions_jnt: ~0 rows (approximately)
DELETE FROM `sch_org_academic_sessions_jnt`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_rooms
CREATE TABLE IF NOT EXISTS `sch_rooms` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `building_id` INT unsigned NOT NULL,
  `room_type_id` INT unsigned NOT NULL,
  `code` char(7) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `capacity` int unsigned DEFAULT NULL,
  `max_limit` int unsigned DEFAULT NULL,
  `description_tags` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rooms_code` (`code`),
  UNIQUE KEY `uq_rooms_shortName` (`short_name`),
  KEY `sch_rooms_building_id_foreign` (`building_id`),
  KEY `sch_rooms_room_type_id_foreign` (`room_type_id`),
  CONSTRAINT `sch_rooms_building_id_foreign` FOREIGN KEY (`building_id`) REFERENCES `sch_buildings` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_rooms_room_type_id_foreign` FOREIGN KEY (`room_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_rooms: ~0 rows (approximately)
DELETE FROM `sch_rooms`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_rooms_type
CREATE TABLE IF NOT EXISTS `sch_rooms_type` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` char(7) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description_tags` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_roomType_code` (`code`),
  UNIQUE KEY `uq_roomType_shortName` (`short_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_rooms_type: ~0 rows (approximately)
DELETE FROM `sch_rooms_type`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_sections
CREATE TABLE IF NOT EXISTS `sch_sections` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ordinal` tinyint unsigned NOT NULL DEFAULT '1',
  `code` char(1) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_sections: ~0 rows (approximately)
DELETE FROM `sch_sections`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_study_formats
CREATE TABLE IF NOT EXISTS `sch_study_formats` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_study_formats: ~0 rows (approximately)
DELETE FROM `sch_study_formats`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_subjects
CREATE TABLE IF NOT EXISTS `sch_subjects` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `short_name` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` char(3) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_subjects: ~0 rows (approximately)
DELETE FROM `sch_subjects`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_subject_groups
CREATE TABLE IF NOT EXISTS `sch_subject_groups` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `class_id` INT unsigned NOT NULL,
  `section_id` INT unsigned DEFAULT NULL,
  `short_name` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sch_subject_groups_class_id_foreign` (`class_id`),
  KEY `sch_subject_groups_section_id_foreign` (`section_id`),
  CONSTRAINT `sch_subject_groups_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_subject_groups_section_id_foreign` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_subject_groups: ~0 rows (approximately)
DELETE FROM `sch_subject_groups`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_subject_group_subject_jnt
CREATE TABLE IF NOT EXISTS `sch_subject_group_subject_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `subject_group_id` INT unsigned NOT NULL,
  `std_cls_subtyp_id` INT unsigned NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ssgsj_grp_stdcls` (`subject_group_id`,`std_cls_subtyp_id`),
  KEY `sch_subject_group_subject_jnt_std_cls_subtyp_id_foreign` (`std_cls_subtyp_id`),
  CONSTRAINT `sch_subject_group_subject_jnt_std_cls_subtyp_id_foreign` FOREIGN KEY (`std_cls_subtyp_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_subject_group_subject_jnt_subject_group_id_foreign` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_subject_group_subject_jnt: ~0 rows (approximately)
DELETE FROM `sch_subject_group_subject_jnt`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_subject_study_format_jnt
CREATE TABLE IF NOT EXISTS `sch_subject_study_format_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `subject_id` INT unsigned NOT NULL,
  `study_format_id` INT unsigned NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subj_stdformat_code` char(7) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subStudyFormat_orgId_subjectId_stFormat` (`subject_id`,`study_format_id`),
  UNIQUE KEY `uq_subStudyFormat_orgId_subStdformatCode` (`subj_stdformat_code`),
  KEY `sch_subject_study_format_jnt_study_format_id_foreign` (`study_format_id`),
  CONSTRAINT `sch_subject_study_format_jnt_study_format_id_foreign` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_subject_study_format_jnt_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_subject_study_format_jnt: ~0 rows (approximately)
DELETE FROM `sch_subject_study_format_jnt`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_subject_teachers
CREATE TABLE IF NOT EXISTS `sch_subject_teachers` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `teacher_id` INT unsigned NOT NULL,
  `subject_id` INT unsigned NOT NULL,
  `study_format_id` INT unsigned NOT NULL,
  `priority` enum('PRIMARY','SECONDARY') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PRIMARY',
  `proficiency` int unsigned DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `effective_from` date DEFAULT NULL,
  `effective_to` date DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subject_teacher` (`teacher_id`,`subject_id`,`study_format_id`),
  KEY `sch_subject_teachers_subject_id_foreign` (`subject_id`),
  KEY `sch_subject_teachers_study_format_id_foreign` (`study_format_id`),
  KEY `idx_subject_teacher_effect` (`effective_from`,`effective_to`),
  CONSTRAINT `sch_subject_teachers_study_format_id_foreign` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_subject_teachers_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_subject_teachers_teacher_id_foreign` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_subject_teachers: ~0 rows (approximately)
DELETE FROM `sch_subject_teachers`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_subject_types
CREATE TABLE IF NOT EXISTS `sch_subject_types` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `short_name` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` char(3) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_subject_types: ~0 rows (approximately)
DELETE FROM `sch_subject_types`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_teachers
CREATE TABLE IF NOT EXISTS `sch_teachers` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `user_id` INT unsigned NOT NULL,
  `joining_date` date NOT NULL,
  `total_experience_years` decimal(4,1) DEFAULT NULL,
  `highest_qualification` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `specialization` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_institution` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `awards` text COLLATE utf8mb4_unicode_ci,
  `skills` text COLLATE utf8mb4_unicode_ci,
  `qualifications_json` json DEFAULT NULL,
  `certifications_json` json DEFAULT NULL,
  `experiences_json` json DEFAULT NULL,
  `notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sch_teachers_user_id_foreign` (`user_id`),
  CONSTRAINT `sch_teachers_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_teachers: ~0 rows (approximately)
DELETE FROM `sch_teachers`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_teachers_profile
CREATE TABLE IF NOT EXISTS `sch_teachers_profile` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `teacher_id` INT unsigned NOT NULL,
  `subject_id` INT unsigned NOT NULL,
  `study_format_id` INT unsigned NOT NULL,
  `class_id` INT unsigned NOT NULL,
  `priority` enum('PRIMARY','SECONDARY') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PRIMARY',
  `proficiency` int unsigned DEFAULT NULL,
  `special_skill_area` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `certified_for_lab` tinyint(1) NOT NULL DEFAULT '0',
  `assignment_meta` json DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `effective_from` date DEFAULT NULL,
  `effective_to` date DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_teachersProfile_orgId_teacher` (`teacher_id`,`subject_id`,`study_format_id`),
  KEY `sch_teachers_profile_subject_id_foreign` (`subject_id`),
  KEY `sch_teachers_profile_study_format_id_foreign` (`study_format_id`),
  KEY `sch_teachers_profile_class_id_foreign` (`class_id`),
  CONSTRAINT `sch_teachers_profile_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_teachers_profile_study_format_id_foreign` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_teachers_profile_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_teachers_profile_teacher_id_foreign` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sch_teachers_profile: ~0 rows (approximately)
DELETE FROM `sch_teachers_profile`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sessions
CREATE TABLE IF NOT EXISTS `sessions` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` INT unsigned DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_activity` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sessions_user_id_index` (`user_id`),
  KEY `sessions_last_activity_index` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sessions: ~1 rows (approximately)
DELETE FROM `sessions`;
INSERT INTO `sessions` (`id`, `user_id`, `ip_address`, `user_agent`, `payload`, `last_activity`) VALUES
	('MkMdrR4sOToLgiakbv8ZXdHTjgqCWhonNs4Y5rxJ', 2, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0', 'YTo2OntzOjY6Il90b2tlbiI7czo0MDoiRzlhUTdMOUcxbTNLRFZPMm5RTnlnNUxNb1RtU0VVVjVMeWJjc1V5ZiI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NTU6Imh0dHA6Ly90ZXN0LmxvY2FsaG9zdDo4MDAwL2Rhc2hib2FyZC9mb3VuZGF0aW9uYWwtc2V0dXAiO3M6NToicm91dGUiO3M6Mjg6ImRhc2hib2FyZC5mb3VuZGF0aW9uYWwtc2V0dXAiO31zOjUwOiJsb2dpbl93ZWJfNTliYTM2YWRkYzJiMmY5NDAxNTgwZjAxNGM3ZjU4ZWE0ZTMwOTg5ZCI7aToyO3M6MTk6ImFjdGl2ZV9tYWluX21lbnVfaWQiO2k6MTk7czoyMjoiUEhQREVCVUdCQVJfU1RBQ0tfREFUQSI7YTowOnt9fQ==', 1768230229);

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_author_books_jnt
CREATE TABLE IF NOT EXISTS `slb_author_books_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `book_id` INT unsigned NOT NULL,
  `author_id` INT unsigned NOT NULL,
  `author_role` enum('PRIMARY','CO_AUTHOR','EDITOR','CONTRIBUTOR') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PRIMARY',
  `ordinal` tinyint unsigned NOT NULL DEFAULT '1' COMMENT 'Author order for the book',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_book_author` (`book_id`,`author_id`),
  KEY `slb_author_books_jnt_author_id_foreign` (`author_id`),
  CONSTRAINT `slb_author_books_jnt_author_id_foreign` FOREIGN KEY (`author_id`) REFERENCES `slb_book_authors` (`id`) ON DELETE CASCADE,
  CONSTRAINT `slb_author_books_jnt_book_id_foreign` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_author_books_jnt: ~0 rows (approximately)
DELETE FROM `slb_author_books_jnt`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_bloom_taxonomy
CREATE TABLE IF NOT EXISTS `slb_bloom_taxonomy` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. REMEMBERING, UNDERSTANDING, APPLYING, ANALYZING, EVALUATING, CREATING',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bloom_level` tinyint unsigned DEFAULT NULL COMMENT '1–6 for Bloom’s revised taxonomy',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slb_bloom_taxonomy_code_unique` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_bloom_taxonomy: ~0 rows (approximately)
DELETE FROM `slb_bloom_taxonomy`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_books
CREATE TABLE IF NOT EXISTS `slb_books` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `isbn` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'International Standard Book Number',
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subtitle` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `edition` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. 5th Edition, Revised 2024',
  `publication_year` year DEFAULT NULL,
  `publisher_name` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `language` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'English',
  `total_pages` int unsigned DEFAULT NULL,
  `cover_image_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `tags` json DEFAULT NULL,
  `is_ncert` tinyint(1) NOT NULL DEFAULT '0',
  `is_cbse_recommended` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slb_books_uuid_unique` (`uuid`),
  UNIQUE KEY `slb_books_isbn_unique` (`isbn`),
  KEY `idx_book_title` (`title`),
  KEY `idx_book_publisher` (`publisher_name`),
  KEY `idx_book_year` (`publication_year`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_books: ~0 rows (approximately)
DELETE FROM `slb_books`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_book_authors
CREATE TABLE IF NOT EXISTS `slb_book_authors` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Author full name',
  `qualification` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bio` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slb_book_authors_name_unique` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_book_authors: ~0 rows (approximately)
DELETE FROM `slb_book_authors`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_book_class_subject_jnt
CREATE TABLE IF NOT EXISTS `slb_book_class_subject_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `book_id` INT unsigned NOT NULL,
  `class_id` INT unsigned NOT NULL,
  `subject_id` INT unsigned NOT NULL,
  `academic_session_id` INT unsigned NOT NULL,
  `is_primary` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Primary textbook vs reference',
  `is_mandatory` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_bcs_book_class_subject_session` (`book_id`,`class_id`,`subject_id`,`academic_session_id`),
  KEY `slb_book_class_subject_jnt_class_id_foreign` (`class_id`),
  KEY `slb_book_class_subject_jnt_subject_id_foreign` (`subject_id`),
  KEY `slb_book_class_subject_jnt_academic_session_id_foreign` (`academic_session_id`),
  CONSTRAINT `slb_book_class_subject_jnt_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `slb_book_class_subject_jnt_book_id_foreign` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`) ON DELETE CASCADE,
  CONSTRAINT `slb_book_class_subject_jnt_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `slb_book_class_subject_jnt_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_book_class_subject_jnt: ~0 rows (approximately)
DELETE FROM `slb_book_class_subject_jnt`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_book_topic_mapping
CREATE TABLE IF NOT EXISTS `slb_book_topic_mapping` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `book_id` INT unsigned NOT NULL,
  `topic_id` INT unsigned NOT NULL,
  `chapter_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. 1, 1.2, Unit I',
  `chapter_title` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `page_start` int unsigned DEFAULT NULL,
  `page_end` int unsigned DEFAULT NULL,
  `section_reference` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. Section 1.3.2',
  `remarks` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_btm_book` (`book_id`),
  KEY `idx_btm_topic` (`topic_id`),
  CONSTRAINT `slb_book_topic_mapping_book_id_foreign` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`) ON DELETE CASCADE,
  CONSTRAINT `slb_book_topic_mapping_topic_id_foreign` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_book_topic_mapping: ~0 rows (approximately)
DELETE FROM `slb_book_topic_mapping`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_cognitive_skill
CREATE TABLE IF NOT EXISTS `slb_cognitive_skill` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `bloom_id` INT unsigned DEFAULT NULL,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. COG-KNOWLEDGE, COG-SKILL, COG-UNDERSTANDING',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slb_cognitive_skill_code_unique` (`code`),
  KEY `slb_cognitive_skill_bloom_id_foreign` (`bloom_id`),
  CONSTRAINT `slb_cognitive_skill_bloom_id_foreign` FOREIGN KEY (`bloom_id`) REFERENCES `slb_bloom_taxonomy` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_cognitive_skill: ~0 rows (approximately)
DELETE FROM `slb_cognitive_skill`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_competencies
CREATE TABLE IF NOT EXISTS `slb_competencies` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `class_id` INT unsigned NOT NULL,
  `subject_id` INT unsigned NOT NULL,
  `competency_type_id` int unsigned NOT NULL,
  `domain` enum('COGNITIVE','AFFECTIVE','PSYCHOMOTOR') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'COGNITIVE',
  `nep_framework_ref` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ncf_alignment` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `learning_outcome_code` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '/',
  `level` tinyint unsigned NOT NULL DEFAULT '0',
  `parent_competency_id` INT unsigned DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `competency_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nep_alignment` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_comp_code` (`code`,`class_id`,`subject_id`),
  UNIQUE KEY `slb_competencies_uuid_unique` (`uuid`),
  KEY `idx_comp_parent` (`parent_competency_id`),
  KEY `idx_competency_type` (`competency_type_id`),
  KEY `fk_comp_class` (`class_id`),
  KEY `fk_comp_subject` (`subject_id`),
  CONSTRAINT `fk_comp_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_comp_parent` FOREIGN KEY (`parent_competency_id`) REFERENCES `slb_competencies` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_comp_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_competency_type` FOREIGN KEY (`competency_type_id`) REFERENCES `slb_competency_types` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_competencies: ~0 rows (approximately)
DELETE FROM `slb_competencies`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_competency_types
CREATE TABLE IF NOT EXISTS `slb_competency_types` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. KNOWLEDGE, SKILL, ATTITUDE',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_comp_type_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_competency_types: ~0 rows (approximately)
DELETE FROM `slb_competency_types`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_complexity_level
CREATE TABLE IF NOT EXISTS `slb_complexity_level` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. EASY, MEDIUM, DIFFICULT',
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `complexity_level` tinyint unsigned DEFAULT NULL COMMENT '1=Easy, 2=Medium, 3=Difficult',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slb_complexity_level_code_unique` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_complexity_level: ~0 rows (approximately)
DELETE FROM `slb_complexity_level`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_complexity_levels
CREATE TABLE IF NOT EXISTS `slb_complexity_levels` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. ''EASY'', ''MEDIUM'', ''DIFFICULT''',
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `complexity_level` tinyint unsigned DEFAULT NULL COMMENT '1=Easy, 2=Medium, 3=Difficult',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_complex_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_complexity_levels: ~0 rows (approximately)
DELETE FROM `slb_complexity_levels`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_grade_division
CREATE TABLE IF NOT EXISTS `slb_grade_division` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'TOPPER, EXCELLENT, GOOD, AVERAGE, BELOW_AVERAGE, NEED_IMPROVEMENT, POOR',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Display name',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `min_percentage` decimal(5,2) NOT NULL COMMENT 'Minimum percentage',
  `max_percentage` decimal(5,2) NOT NULL COMMENT 'Maximum percentage',
  `display_order` smallint unsigned NOT NULL DEFAULT '1',
  `color_code` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'UI badge color',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_grade_div` (`min_percentage`,`max_percentage`),
  UNIQUE KEY `slb_grade_division_code_unique` (`code`),
  KEY `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_grade_division: ~0 rows (approximately)
DELETE FROM `slb_grade_division`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_lessons
CREATE TABLE IF NOT EXISTS `slb_lessons` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(7) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `class_id` INT unsigned NOT NULL,
  `academic_session_id` INT unsigned NOT NULL,
  `subject_id` INT unsigned NOT NULL,
  `ordinal` tinyint DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `short_name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `learning_objectives` json DEFAULT NULL,
  `prerequisites` json DEFAULT NULL,
  `estimated_periods` smallint unsigned DEFAULT NULL,
  `weightage_percent` decimal(5,2) DEFAULT NULL,
  `nep_alignment` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `resources_json` json DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lesson_class_Subject_name` (`class_id`,`subject_id`,`name`),
  UNIQUE KEY `uq_lesson_uuid` (`uuid`),
  UNIQUE KEY `uq_lesson_class_Subject_ordinal` (`class_id`,`subject_id`,`ordinal`),
  KEY `slb_lessons_academic_session_id_foreign` (`academic_session_id`),
  KEY `slb_lessons_subject_id_foreign` (`subject_id`),
  CONSTRAINT `slb_lessons_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `slb_lessons_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `slb_lessons_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_lessons: ~0 rows (approximately)
DELETE FROM `slb_lessons`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_performance_categories
CREATE TABLE IF NOT EXISTS `slb_performance_categories` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'TOPPER, EXCELLENT, GOOD, AVERAGE, BELOW_AVERAGE, NEED_IMPROVEMENT, POOR',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Display name',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `min_percentage` decimal(5,2) NOT NULL COMMENT 'Minimum percentage',
  `max_percentage` decimal(5,2) NOT NULL COMMENT 'Maximum percentage',
  `display_order` smallint unsigned NOT NULL DEFAULT '1',
  `color_code` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'UI badge color',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_perf_cat` (`min_percentage`,`max_percentage`),
  UNIQUE KEY `slb_performance_categories_code_unique` (`code`),
  KEY `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_performance_categories: ~0 rows (approximately)
DELETE FROM `slb_performance_categories`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_question_types
CREATE TABLE IF NOT EXISTS `slb_question_types` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. MCQ_SINGLE, MCQ_MULTI, SHORT_ANSWER, LONG_ANSWER',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `has_options` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'True if this type has options',
  `auto_gradable` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Can system auto grade this question type',
  `description` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qtype_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_question_types: ~0 rows (approximately)
DELETE FROM `slb_question_types`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_ques_type_specificity
CREATE TABLE IF NOT EXISTS `slb_ques_type_specificity` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `cognitive_skill_id` INT unsigned DEFAULT NULL,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. IN_CLASS, HOMEWORK, SUMMATIVE, FORMATIVE',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slb_ques_type_specificity_code_unique` (`code`),
  KEY `slb_ques_type_specificity_cognitive_skill_id_foreign` (`cognitive_skill_id`),
  CONSTRAINT `slb_ques_type_specificity_cognitive_skill_id_foreign` FOREIGN KEY (`cognitive_skill_id`) REFERENCES `slb_cognitive_skill` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_ques_type_specificity: ~0 rows (approximately)
DELETE FROM `slb_ques_type_specificity`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_study_materials
CREATE TABLE IF NOT EXISTS `slb_study_materials` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `topic_id` INT unsigned NOT NULL,
  `material_type_id` INT unsigned NOT NULL,
  `performance_category_id` INT unsigned DEFAULT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `duration_minutes` int unsigned DEFAULT NULL,
  `difficulty_level` enum('BASIC','INTERMEDIATE','ADVANCED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'INTERMEDIATE',
  `language` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'English',
  `source` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tags` json DEFAULT NULL,
  `view_count` int unsigned NOT NULL DEFAULT '0',
  `avg_rating` decimal(3,2) DEFAULT NULL,
  `is_premium` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` INT unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slb_study_materials_uuid_unique` (`uuid`),
  KEY `slb_study_materials_created_by_foreign` (`created_by`),
  KEY `idx_studmat_topic` (`topic_id`),
  KEY `idx_studmat_perfcat` (`performance_category_id`),
  KEY `idx_studmat_type` (`material_type_id`),
  CONSTRAINT `slb_study_materials_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `slb_study_materials_material_type_id_foreign` FOREIGN KEY (`material_type_id`) REFERENCES `slb_study_material_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `slb_study_materials_performance_category_id_foreign` FOREIGN KEY (`performance_category_id`) REFERENCES `slb_performance_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `slb_study_materials_topic_id_foreign` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_study_materials: ~0 rows (approximately)
DELETE FROM `slb_study_materials`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_study_material_types
CREATE TABLE IF NOT EXISTS `slb_study_material_types` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'VIDEO, PDF, ARTICLE, INTERACTIVE, AUDIO',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `icon` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slb_study_material_types_code_unique` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_study_material_types: ~0 rows (approximately)
DELETE FROM `slb_study_material_types`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_topics
CREATE TABLE IF NOT EXISTS `slb_topics` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `analytics_code` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `parent_id` INT unsigned DEFAULT NULL,
  `lesson_id` INT unsigned NOT NULL,
  `class_id` INT unsigned NOT NULL,
  `subject_id` INT unsigned NOT NULL,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ordinal` smallint unsigned DEFAULT NULL,
  `level` tinyint unsigned NOT NULL DEFAULT '0',
  `path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `path_names` varchar(2000) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `duration_minutes` int unsigned DEFAULT NULL,
  `learning_objectives` json DEFAULT NULL,
  `keywords` json DEFAULT NULL,
  `prerequisite_topic_ids` json DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_topic_uuid` (`uuid`),
  UNIQUE KEY `uq_topic_code` (`code`),
  UNIQUE KEY `uq_topic_analytics_code` (`analytics_code`),
  UNIQUE KEY `uq_topic_lesson_parent_name` (`lesson_id`,`parent_id`,`name`),
  KEY `idx_topic_parent_id` (`parent_id`),
  KEY `idx_topic_lesson_id` (`lesson_id`),
  KEY `idx_topic_level` (`level`),
  KEY `slb_topics_class_id_foreign` (`class_id`),
  KEY `slb_topics_subject_id_foreign` (`subject_id`),
  CONSTRAINT `slb_topics_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `slb_topics_lesson_id_foreign` FOREIGN KEY (`lesson_id`) REFERENCES `slb_lessons` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `slb_topics_parent_id_foreign` FOREIGN KEY (`parent_id`) REFERENCES `slb_topics` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `slb_topics_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_topics: ~0 rows (approximately)
DELETE FROM `slb_topics`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_topic_competency_jnt
CREATE TABLE IF NOT EXISTS `slb_topic_competency_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `topic_id` INT unsigned NOT NULL,
  `competency_id` INT unsigned NOT NULL,
  `weightage` decimal(5,2) DEFAULT NULL,
  `is_primary` tinyint(1) NOT NULL DEFAULT '0',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_topic_competency` (`topic_id`,`competency_id`),
  KEY `slb_topic_competency_jnt_competency_id_foreign` (`competency_id`),
  CONSTRAINT `slb_topic_competency_jnt_competency_id_foreign` FOREIGN KEY (`competency_id`) REFERENCES `slb_competencies` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `slb_topic_competency_jnt_topic_id_foreign` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_topic_competency_jnt: ~0 rows (approximately)
DELETE FROM `slb_topic_competency_jnt`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_topic_dependencies
CREATE TABLE IF NOT EXISTS `slb_topic_dependencies` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `topic_id` INT unsigned NOT NULL,
  `prerequisite_topic_id` INT unsigned NOT NULL,
  `dependency_type` enum('PREREQUISITE','FOUNDATION','RELATED','EXTENSION') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PREREQUISITE',
  `strength` enum('WEAK','MODERATE','STRONG') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'STRONG',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_topdep_topic_prereq` (`topic_id`,`prerequisite_topic_id`),
  KEY `idx_topdep_prereq` (`prerequisite_topic_id`),
  CONSTRAINT `slb_topic_dependencies_prerequisite_topic_id_foreign` FOREIGN KEY (`prerequisite_topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `slb_topic_dependencies_topic_id_foreign` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.slb_topic_dependencies: ~0 rows (approximately)
DELETE FROM `slb_topic_dependencies`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.std_students
CREATE TABLE IF NOT EXISTS `std_students` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `user_id` INT unsigned NOT NULL,
  `parent_id` INT unsigned NOT NULL,
  `student_qr_code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `student_id_card_type` enum('QR','RFID','NFC','Barcode') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'QR',
  `aadhar_id` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `apaar_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `birth_cert_no` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `health_id` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `smart_card_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `first_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `middle_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gender` enum('Male','Female','Transgender','Prefer Not to Say') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Male',
  `dob` date NOT NULL,
  `blood_group` enum('A+','A-','B+','B-','AB+','AB-','O+','O-') COLLATE utf8mb4_unicode_ci NOT NULL,
  `photo` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `current_status_id` INT unsigned NOT NULL,
  `note` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `std_students_student_qr_code_unique` (`student_qr_code`),
  UNIQUE KEY `std_students_aadhar_id_unique` (`aadhar_id`),
  UNIQUE KEY `std_students_apaar_id_unique` (`apaar_id`),
  KEY `std_students_user_id_foreign` (`user_id`),
  KEY `std_students_parent_id_foreign` (`parent_id`),
  CONSTRAINT `std_students_parent_id_foreign` FOREIGN KEY (`parent_id`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `std_students_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.std_students: ~0 rows (approximately)
DELETE FROM `std_students`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.std_student_academic_sessions_jnt
CREATE TABLE IF NOT EXISTS `std_student_academic_sessions_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_id` INT unsigned NOT NULL,
  `academic_session_id` INT unsigned NOT NULL,
  `class_id` INT unsigned NOT NULL,
  `section_id` INT unsigned NOT NULL,
  `class_section_id` INT unsigned NOT NULL,
  `admission_no` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `roll_no` int DEFAULT NULL,
  `admission_date` date DEFAULT NULL,
  `registration_no` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `default_mobile` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `default_email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `session_status_id` INT unsigned DEFAULT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT '1',
  `leaving_date` date DEFAULT NULL,
  `reason_quit` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `dis_note` text COLLATE utf8mb4_unicode_ci,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_student_current_session` (`student_id`,`is_current`),
  KEY `std_student_academic_sessions_jnt_academic_session_id_foreign` (`academic_session_id`),
  KEY `std_student_academic_sessions_jnt_class_id_foreign` (`class_id`),
  KEY `std_student_academic_sessions_jnt_section_id_foreign` (`section_id`),
  KEY `std_student_academic_sessions_jnt_class_section_id_foreign` (`class_section_id`),
  CONSTRAINT `std_student_academic_sessions_jnt_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `std_student_academic_sessions_jnt_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `std_student_academic_sessions_jnt_class_section_id_foreign` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `std_student_academic_sessions_jnt_section_id_foreign` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `std_student_academic_sessions_jnt_student_id_foreign` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.std_student_academic_sessions_jnt: ~0 rows (approximately)
DELETE FROM `std_student_academic_sessions_jnt`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.std_student_detail
CREATE TABLE IF NOT EXISTS `std_student_detail` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_id` INT unsigned NOT NULL,
  `mobile` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `student_address` text COLLATE utf8mb4_unicode_ci,
  `city_id` INT unsigned NOT NULL,
  `pin` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `religion` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cast` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `current_address` text COLLATE utf8mb4_unicode_ci,
  `permanent_address` text COLLATE utf8mb4_unicode_ci,
  `student_photo` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `right_to_edu` tinyint(1) NOT NULL DEFAULT '0',
  `bank_account_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ifsc_code` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `upi_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `father_name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `father_phone` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `father_occupation` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `father_email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mother_name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mother_phone` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mother_occupation` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mother_email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `guardian_is` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Father',
  `guardian_name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `guardian_relation` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `guardian_phone` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `guardian_occupation` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `guardian_address` text COLLATE utf8mb4_unicode_ci,
  `guardian_email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `previous_school_detail` text COLLATE utf8mb4_unicode_ci,
  `height` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `weight` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `measurement_date` date DEFAULT NULL,
  `extra_info` json DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `std_student_detail_student_id_foreign` (`student_id`),
  KEY `std_student_detail_city_id_foreign` (`city_id`),
  CONSTRAINT `std_student_detail_city_id_foreign` FOREIGN KEY (`city_id`) REFERENCES `global_master`.`glb_cities` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `std_student_detail_student_id_foreign` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.std_student_detail: ~0 rows (approximately)
DELETE FROM `std_student_detail`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.std_student_pay_log
CREATE TABLE IF NOT EXISTS `std_student_pay_log` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_id` INT unsigned DEFAULT NULL,
  `academic_session_id` INT unsigned DEFAULT NULL,
  `module_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `activity_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'credit / debit / refund / fine / adjustment',
  `amount` decimal(10,2) DEFAULT NULL,
  `log_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reference_id` INT unsigned DEFAULT NULL,
  `reference_table` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `triggered_by` INT unsigned DEFAULT NULL,
  `is_system_generated` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_payLog_student` (`student_id`),
  KEY `idx_payLog_module` (`module_name`),
  KEY `idx_payLog_date` (`log_date`),
  KEY `idx_payLog_reference` (`reference_table`,`reference_id`),
  KEY `idx_payLog_trigger` (`triggered_by`),
  CONSTRAINT `fk_payLog_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_payLog_triggeredBy` FOREIGN KEY (`triggered_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.std_student_pay_log: ~0 rows (approximately)
DELETE FROM `std_student_pay_log`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.subject_group_subject
CREATE TABLE IF NOT EXISTS `subject_group_subject` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `subject_group_id` INT unsigned NOT NULL,
  `subject_id` INT unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `subject_group_subject_subject_group_id_subject_id_unique` (`subject_group_id`,`subject_id`),
  KEY `subject_group_subject_subject_id_foreign` (`subject_id`),
  CONSTRAINT `subject_group_subject_subject_group_id_foreign` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `subject_group_subject_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.subject_group_subject: ~0 rows (approximately)
DELETE FROM `subject_group_subject`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_activity_logs
CREATE TABLE IF NOT EXISTS `sys_activity_logs` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `subject_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subject_id` INT unsigned NOT NULL,
  `user_id` INT unsigned NOT NULL,
  `event` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `properties` json DEFAULT NULL,
  `ip_address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sys_activity_logs_subject_type_subject_id_index` (`subject_type`,`subject_id`),
  KEY `sys_activity_logs_user_id_foreign` (`user_id`),
  KEY `sys_activity_logs_created_at_user_id_index` (`created_at`,`user_id`),
  CONSTRAINT `sys_activity_logs_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_activity_logs: ~0 rows (approximately)
DELETE FROM `sys_activity_logs`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_dropdowns
CREATE TABLE IF NOT EXISTS `sys_dropdowns` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `dropdown_needs_id` INT unsigned NOT NULL,
  `ordinal` tinyint unsigned NOT NULL,
  `key` varchar(160) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` enum('String','Integer','Decimal','Date','Datetime','Time','Boolean') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'String',
  `additional_info` json DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dropdown_need_key_ordinal` (`dropdown_needs_id`,`key`,`ordinal`),
  CONSTRAINT `sys_dropdowns_dropdown_needs_id_foreign` FOREIGN KEY (`dropdown_needs_id`) REFERENCES `sys_dropdown_needs` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=256 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_dropdowns: ~255 rows (approximately)
DELETE FROM `sys_dropdowns`;
INSERT INTO `sys_dropdowns` (`id`, `dropdown_needs_id`, `ordinal`, `key`, `value`, `type`, `additional_info`, `is_active`, `deleted_at`, `created_at`, `updated_at`) VALUES
	(1, 1, 1, 'dummy_table_name.dummy_column_name.religion', 'Hinduism', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(2, 1, 2, 'dummy_table_name.dummy_column_name.religion', 'Islam', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(3, 1, 3, 'dummy_table_name.dummy_column_name.religion', 'Christianity', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(4, 1, 4, 'dummy_table_name.dummy_column_name.religion', 'Sikhism', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(5, 1, 5, 'dummy_table_name.dummy_column_name.religion', 'Buddhism', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(6, 1, 6, 'dummy_table_name.dummy_column_name.religion', 'Jainism', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(7, 1, 7, 'dummy_table_name.dummy_column_name.religion', 'Zoroastrianism', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(8, 1, 8, 'dummy_table_name.dummy_column_name.religion', 'Judaism', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(9, 1, 1, 'dummy_table_name.dummy_column_name.caste', 'Brahmins', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(10, 1, 2, 'dummy_table_name.dummy_column_name.caste', 'Kshatriyas', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(11, 1, 3, 'dummy_table_name.dummy_column_name.caste', 'Vaishyas', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(12, 1, 4, 'dummy_table_name.dummy_column_name.caste', 'Shudras', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(13, 1, 5, 'dummy_table_name.dummy_column_name.caste', 'Kayastha', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(14, 1, 6, 'dummy_table_name.dummy_column_name.caste', 'Punjabi Khatri', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(15, 1, 7, 'dummy_table_name.dummy_column_name.caste', 'Sindhi', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(16, 1, 8, 'dummy_table_name.dummy_column_name.caste', 'Rajput', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(17, 1, 9, 'dummy_table_name.dummy_column_name.caste', 'Jains', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(18, 1, 10, 'dummy_table_name.dummy_column_name.caste', 'Parsis', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(19, 1, 11, 'dummy_table_name.dummy_column_name.caste', 'Christians', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(20, 1, 1, 'dummy_table_name.dummy_column_name.gender', 'Male', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(21, 1, 2, 'dummy_table_name.dummy_column_name.gender', 'Female', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(22, 1, 3, 'dummy_table_name.dummy_column_name.gender', 'Other', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(23, 1, 4, 'dummy_table_name.dummy_column_name.gender', 'Prefer not to say', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(24, 1, 1, 'dummy_table_name.dummy_column_name.status', 'Active', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(25, 1, 2, 'dummy_table_name.dummy_column_name.status', 'Inactive', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(26, 1, 1, 'dummy_table_name.dummy_column_name.blood_group', 'A+', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(27, 1, 2, 'dummy_table_name.dummy_column_name.blood_group', 'A-', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(28, 1, 3, 'dummy_table_name.dummy_column_name.blood_group', 'B+', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(29, 1, 4, 'dummy_table_name.dummy_column_name.blood_group', 'B-', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(30, 1, 5, 'dummy_table_name.dummy_column_name.blood_group', 'AB+', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(31, 1, 6, 'dummy_table_name.dummy_column_name.blood_group', 'AB-', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(32, 1, 7, 'dummy_table_name.dummy_column_name.blood_group', 'O+', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(33, 1, 8, 'dummy_table_name.dummy_column_name.blood_group', 'O-', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(34, 1, 1, 'dummy_table_name.dummy_column_name.guardian_is', 'Father', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(35, 1, 2, 'dummy_table_name.dummy_column_name.guardian_is', 'Mother', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(36, 1, 3, 'dummy_table_name.dummy_column_name.guardian_is', 'Guardian', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(37, 1, 1, 'dummy_table_name.dummy_column_name.default_mobile', 'Father', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(38, 1, 2, 'dummy_table_name.dummy_column_name.default_mobile', 'Mother', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(39, 1, 3, 'dummy_table_name.dummy_column_name.default_mobile', 'Guardian', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(40, 1, 1, 'dummy_table_name.dummy_column_name.default_email', 'Father', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(41, 1, 2, 'dummy_table_name.dummy_column_name.default_email', 'Mother', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(42, 1, 3, 'dummy_table_name.dummy_column_name.default_email', 'Guardian', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(43, 1, 1, 'dummy_table_name.dummy_column_name.reason_quit', 'Transfer', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(44, 1, 2, 'dummy_table_name.dummy_column_name.reason_quit', 'Completed', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(45, 1, 3, 'dummy_table_name.dummy_column_name.reason_quit', 'Discontinued', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(46, 1, 4, 'dummy_table_name.dummy_column_name.reason_quit', 'Other', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(47, 1, 1, 'dummy_table_name.dummy_column_name.dropdown_type', 'String', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(48, 1, 2, 'dummy_table_name.dummy_column_name.dropdown_type', 'Integer', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(49, 1, 3, 'dummy_table_name.dummy_column_name.dropdown_type', 'Decimal', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(50, 1, 4, 'dummy_table_name.dummy_column_name.dropdown_type', 'Date', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(51, 1, 5, 'dummy_table_name.dummy_column_name.dropdown_type', 'Datetime', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(52, 1, 6, 'dummy_table_name.dummy_column_name.dropdown_type', 'Time', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(53, 1, 7, 'dummy_table_name.dummy_column_name.dropdown_type', 'Boolean', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(54, 1, 1, 'dummy_table_name.dummy_column_name.data_type', 'Invoicing Done', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(55, 1, 2, 'dummy_table_name.dummy_column_name.data_type', 'Inv. Need To Generate', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(56, 1, 1, 'dummy_table_name.dummy_column_name.invoice_status', 'PENDING', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(57, 1, 1, 'dummy_table_name.dummy_column_name.invoice_payment_status', 'PENDING', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(58, 1, 2, 'dummy_table_name.dummy_column_name.invoice_payment_status', 'PARTIAL', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(59, 1, 3, 'dummy_table_name.dummy_column_name.invoice_payment_status', 'PAID', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(60, 1, 1, 'dummy_table_name.dummy_column_name.payment_mode', 'Cash', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(61, 1, 2, 'dummy_table_name.dummy_column_name.payment_mode', 'Bank', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(62, 1, 3, 'dummy_table_name.dummy_column_name.payment_mode', 'Online', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(63, 1, 1, 'dummy_table_name.dummy_column_name.payment_status', 'Pending', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(64, 1, 2, 'dummy_table_name.dummy_column_name.payment_status', 'Partially Paid', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(65, 1, 3, 'dummy_table_name.dummy_column_name.payment_status', 'Fully Paid', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(66, 1, 4, 'dummy_table_name.dummy_column_name.payment_status', 'Overdue', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(67, 1, 5, 'dummy_table_name.dummy_column_name.payment_status', 'Uncollectible', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(68, 1, 6, 'dummy_table_name.dummy_column_name.payment_status', 'Void (Not Valid)', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(69, 1, 7, 'dummy_table_name.dummy_column_name.payment_status', 'In Process', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(70, 1, 8, 'dummy_table_name.dummy_column_name.payment_status', 'Payment Denied', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(71, 1, 1, 'dummy_table_name.dummy_column_name.payment_reconciled', 'YES', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(72, 1, 2, 'dummy_table_name.dummy_column_name.payment_reconciled', 'NO', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(73, 1, 1, 'dummy_table_name.dummy_column_name.payment_consolidated_status', 'INITIATED', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(74, 1, 2, 'dummy_table_name.dummy_column_name.payment_consolidated_status', 'SUCCESS', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(75, 1, 3, 'dummy_table_name.dummy_column_name.payment_consolidated_status', 'FAILED', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(76, 1, 4, 'dummy_table_name.dummy_column_name.payment_consolidated_status', 'REFUNDED', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(77, 1, 1, 'dummy_table_name.dummy_column_name.payment_reconcilation_status', 'Reconciled Transactions Only', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(78, 1, 2, 'dummy_table_name.dummy_column_name.payment_reconcilation_status', 'Non-Reconciled Trans. Only', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(79, 1, 1, 'dummy_table_name.dummy_column_name.audit_status', 'Not Billed', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(80, 1, 2, 'dummy_table_name.dummy_column_name.audit_status', 'Bill Generated', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(81, 1, 3, 'dummy_table_name.dummy_column_name.audit_status', 'Overdue', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(82, 1, 4, 'dummy_table_name.dummy_column_name.audit_status', 'Notice Sent', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(83, 1, 5, 'dummy_table_name.dummy_column_name.audit_status', 'Partially Paid', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(84, 1, 6, 'dummy_table_name.dummy_column_name.audit_status', 'Fully Paid', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(85, 1, 1, 'dummy_table_name.dummy_column_name.severity_level', 'Low', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(86, 1, 2, 'dummy_table_name.dummy_column_name.severity_level', 'Medium', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(87, 1, 3, 'dummy_table_name.dummy_column_name.severity_level', 'High', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(88, 1, 4, 'dummy_table_name.dummy_column_name.severity_level', 'Critical', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(89, 1, 1, 'dummy_table_name.dummy_column_name.priority_score', 'Critical', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(90, 1, 2, 'dummy_table_name.dummy_column_name.priority_score', 'Urgent', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(91, 1, 3, 'dummy_table_name.dummy_column_name.priority_score', 'High', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(92, 1, 4, 'dummy_table_name.dummy_column_name.priority_score', 'Medium', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(93, 1, 5, 'dummy_table_name.dummy_column_name.priority_score', 'Low', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(94, 1, 1, 'dummy_table_name.dummy_column_name.user_type', 'Student', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(95, 1, 2, 'dummy_table_name.dummy_column_name.user_type', 'Staff', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(96, 1, 3, 'dummy_table_name.dummy_column_name.user_type', 'Group', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(97, 1, 4, 'dummy_table_name.dummy_column_name.user_type', 'Department', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(98, 1, 5, 'dummy_table_name.dummy_column_name.user_type', 'Vendor', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(99, 1, 6, 'dummy_table_name.dummy_column_name.user_type', 'Other', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(100, 1, 1, 'dummy_table_name.dummy_column_name.complainant_type', 'Parent', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(101, 1, 2, 'dummy_table_name.dummy_column_name.complainant_type', 'Student', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(102, 1, 3, 'dummy_table_name.dummy_column_name.complainant_type', 'Staff', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(103, 1, 4, 'dummy_table_name.dummy_column_name.complainant_type', 'Vendor', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(104, 1, 5, 'dummy_table_name.dummy_column_name.complainant_type', 'Anonymous', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(105, 1, 6, 'dummy_table_name.dummy_column_name.complainant_type', 'Public', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(106, 1, 1, 'dummy_table_name.dummy_column_name.source', 'App', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(107, 1, 2, 'dummy_table_name.dummy_column_name.source', 'Web', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(108, 1, 3, 'dummy_table_name.dummy_column_name.source', 'Email', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(109, 1, 4, 'dummy_table_name.dummy_column_name.source', 'Walk-in', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(110, 1, 5, 'dummy_table_name.dummy_column_name.source', 'Call', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(111, 1, 1, 'dummy_table_name.dummy_column_name.target_user_type', 'Student', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(112, 1, 2, 'dummy_table_name.dummy_column_name.target_user_type', 'Staff', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(113, 1, 3, 'dummy_table_name.dummy_column_name.target_user_type', 'Group', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(114, 1, 4, 'dummy_table_name.dummy_column_name.target_user_type', 'Department', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(115, 1, 5, 'dummy_table_name.dummy_column_name.target_user_type', 'Role', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(116, 1, 6, 'dummy_table_name.dummy_column_name.target_user_type', 'Designation', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(117, 1, 7, 'dummy_table_name.dummy_column_name.target_user_type', 'Facility', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(118, 1, 8, 'dummy_table_name.dummy_column_name.target_user_type', 'Vehicle', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(119, 1, 9, 'dummy_table_name.dummy_column_name.target_user_type', 'Event', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(120, 1, 10, 'dummy_table_name.dummy_column_name.target_user_type', 'Location', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(121, 1, 11, 'dummy_table_name.dummy_column_name.target_user_type', 'Vendor', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(122, 1, 12, 'dummy_table_name.dummy_column_name.target_user_type', 'Other', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(123, 1, 1, 'dummy_table_name.dummy_column_name.complaint_status', 'Open', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(124, 1, 2, 'dummy_table_name.dummy_column_name.complaint_status', 'In-Progress', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(125, 1, 3, 'dummy_table_name.dummy_column_name.complaint_status', 'Escalated', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(126, 1, 4, 'dummy_table_name.dummy_column_name.complaint_status', 'Resolved', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(127, 1, 5, 'dummy_table_name.dummy_column_name.complaint_status', 'Closed', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(128, 1, 6, 'dummy_table_name.dummy_column_name.complaint_status', 'Rejected', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(129, 1, 1, 'dummy_table_name.dummy_column_name.complaint_source', 'App', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(130, 1, 2, 'dummy_table_name.dummy_column_name.complaint_source', 'Web', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(131, 1, 3, 'dummy_table_name.dummy_column_name.complaint_source', 'Email', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(132, 1, 4, 'dummy_table_name.dummy_column_name.complaint_source', 'Walk-in', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(133, 1, 5, 'dummy_table_name.dummy_column_name.complaint_source', 'Call', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(134, 1, 1, 'dummy_table_name.dummy_column_name.entity_type', 'Class', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(135, 1, 2, 'dummy_table_name.dummy_column_name.entity_type', 'Section', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(136, 1, 3, 'dummy_table_name.dummy_column_name.entity_type', 'Subject', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(137, 1, 4, 'dummy_table_name.dummy_column_name.entity_type', 'Designation', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(138, 1, 5, 'dummy_table_name.dummy_column_name.entity_type', 'Department', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(139, 1, 6, 'dummy_table_name.dummy_column_name.entity_type', 'Role', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(140, 1, 7, 'dummy_table_name.dummy_column_name.entity_type', 'Student', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(141, 1, 8, 'dummy_table_name.dummy_column_name.entity_type', 'Staff', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(142, 1, 9, 'dummy_table_name.dummy_column_name.entity_type', 'Vehicle', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(143, 1, 10, 'dummy_table_name.dummy_column_name.entity_type', 'Facility', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(144, 1, 11, 'dummy_table_name.dummy_column_name.entity_type', 'Event', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(145, 1, 12, 'dummy_table_name.dummy_column_name.entity_type', 'Location', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(146, 1, 13, 'dummy_table_name.dummy_column_name.entity_type', 'Other', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(147, 1, 1, 'dummy_table_name.dummy_column_name.sentiment_label', 'Angry', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(148, 1, 2, 'dummy_table_name.dummy_column_name.sentiment_label', 'Urgent', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(149, 1, 3, 'dummy_table_name.dummy_column_name.sentiment_label', 'Calm', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(150, 1, 4, 'dummy_table_name.dummy_column_name.sentiment_label', 'Neutral', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(151, 2, 1, 'cmp_medical_checks.check_type_id.medical_check_type', 'AlcoholTest', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(152, 2, 2, 'cmp_medical_checks.check_type_id.medical_check_type', 'DrugTest', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(153, 2, 3, 'cmp_medical_checks.check_type_id.medical_check_type', 'FitnessCheck', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(154, 3, 1, 'cmp_medical_checks.result.medical_check_result', 'Positive', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(155, 3, 2, 'cmp_medical_checks.result.medical_check_result', 'Negative', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(156, 3, 3, 'cmp_medical_checks.result.medical_check_result', 'Inconclusive', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(157, 4, 1, 'tpt_vehicle_service_request.vehicle_status.vehicle_status', 'Service', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(158, 4, 2, 'tpt_vehicle_service_request.vehicle_status.vehicle_status', 'In-Service', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(159, 4, 3, 'tpt_vehicle_service_request.vehicle_status.vehicle_status', 'Service Done', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(160, 5, 1, 'tpt_vehicle.vehicle_type_id.vehicle_type', 'Bus', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(161, 5, 2, 'tpt_vehicle.vehicle_type_id.vehicle_type', 'Car', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(162, 5, 3, 'tpt_vehicle.vehicle_type_id.vehicle_type', 'Van', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(163, 6, 1, 'tpt_vehicle.fuel_type_id.fuel_type', 'Petrol', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(164, 6, 2, 'tpt_vehicle.fuel_type_id.fuel_type', 'Diesel', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(165, 6, 3, 'tpt_vehicle.fuel_type_id.fuel_type', 'CNG', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(166, 6, 4, 'tpt_vehicle.fuel_type_id.fuel_type', 'Electric', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(167, 6, 5, 'tpt_vehicle.fuel_type_id.fuel_type', 'Hybrid', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(168, 7, 1, 'tpt_vehicle.ownership_type_id.ownership_type', 'Company', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(169, 7, 2, 'tpt_vehicle.ownership_type_id.ownership_type', 'Private', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(170, 7, 3, 'tpt_vehicle.ownership_type_id.ownership_type', 'Leased', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(171, 8, 1, 'tpt_vehicle.vehicle_emission_class_id.vehicle_emission_class', 'BS IV', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(172, 8, 2, 'tpt_vehicle.vehicle_emission_class_id.vehicle_emission_class', 'BS V', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(173, 8, 3, 'tpt_vehicle.vehicle_emission_class_id.vehicle_emission_class', 'BS VI', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(174, 9, 1, 'tpt_personnel.id_type.type', 'Aadhar Card', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(175, 9, 2, 'tpt_personnel.id_type.type', 'Licence Number', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(176, 9, 3, 'tpt_personnel.id_type.type', 'Pancard', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(177, 9, 4, 'tpt_personnel.id_type.type', 'Voter ID', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(178, 9, 5, 'tpt_personnel.id_type.type', 'Passport', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(179, 10, 1, 'tpt_attendance_device.device_type.type', 'Mobile', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(180, 10, 2, 'tpt_attendance_device.device_type.type', 'Scanner', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(181, 10, 3, 'tpt_attendance_device.device_type.type', 'Tablet', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(182, 10, 4, 'tpt_attendance_device.device_type.type', 'Gate', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(183, 11, 1, 'tpt_attendance_device.device_os.type', 'Android', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(184, 11, 2, 'tpt_attendance_device.device_os.type', 'iOS', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(185, 11, 3, 'tpt_attendance_device.device_os.type', 'Windows', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(186, 11, 4, 'tpt_attendance_device.device_os.type', 'Linux', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(187, 11, 5, 'tpt_attendance_device.device_os.type', 'macOS', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(188, 11, 6, 'tpt_attendance_device.device_os.type', 'Custom', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(189, 12, 1, 'bil_tenant_invoicing_payments.mode.payment_mode', 'Cash', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(190, 12, 2, 'bil_tenant_invoicing_payments.mode.payment_mode', 'Bank', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(191, 12, 3, 'bil_tenant_invoicing_payments.mode.payment_mode', 'Online', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(192, 13, 1, 'bil_tenant_invoicing_payments.payment_status.payment_consolidated_status', 'INITIATED', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(193, 13, 2, 'bil_tenant_invoicing_payments.payment_status.payment_consolidated_status', 'SUCCESS', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(194, 13, 3, 'bil_tenant_invoicing_payments.payment_status.payment_consolidated_status', 'FAILED', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(195, 13, 4, 'bil_tenant_invoicing_payments.payment_status.payment_consolidated_status', 'REFUNDED', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(196, 14, 1, 'cmp_complaint_actions.action_type_id.action_type', 'Created', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(197, 14, 2, 'cmp_complaint_actions.action_type_id.action_type', 'Assigned', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(198, 14, 3, 'cmp_complaint_actions.action_type_id.action_type', 'Comment', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(199, 14, 4, 'cmp_complaint_actions.action_type_id.action_type', 'StatusChange', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(200, 14, 5, 'cmp_complaint_actions.action_type_id.action_type', 'Investigation', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(201, 14, 6, 'cmp_complaint_actions.action_type_id.action_type', 'Escalated', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(202, 14, 7, 'cmp_complaint_actions.action_type_id.action_type', 'Resolved', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(203, 15, 1, 'sch_entity_groups.entity_purpose_id.entity_purpose', 'Calation Management', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(204, 15, 2, 'sch_entity_groups.entity_purpose_id.entity_purpose', 'Notification', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(205, 15, 3, 'sch_entity_groups.entity_purpose_id.entity_purpose', 'Event Supervision', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(206, 15, 4, 'sch_entity_groups.entity_purpose_id.entity_purpose', 'Exam Supervision', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(207, 16, 1, 'sch_entity_groups.entity_purpose_id_2.entity_purpose_2', 'Calation Management', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(208, 16, 2, 'sch_entity_groups.entity_purpose_id_2.entity_purpose_2', 'Notification', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(209, 16, 3, 'sch_entity_groups.entity_purpose_id_2.entity_purpose_2', 'Event Supervision', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(210, 16, 4, 'sch_entity_groups.entity_purpose_id_2.entity_purpose_2', 'Exam Supervision', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(211, 17, 1, 'vnd_vendors.vendor_type_id.vendor_type_id', 'Transport', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(212, 17, 2, 'vnd_vendors.vendor_type_id.vendor_type_id', 'Canteen/Catering', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(213, 17, 3, 'vnd_vendors.vendor_type_id.vendor_type_id', 'Security', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(214, 17, 4, 'vnd_vendors.vendor_type_id.vendor_type_id', 'Stationery', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(215, 17, 5, 'vnd_vendors.vendor_type_id.vendor_type_id', 'Maintenance', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(216, 17, 6, 'vnd_vendors.vendor_type_id.vendor_type_id', 'Medical/Doctor', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(217, 17, 7, 'vnd_vendors.vendor_type_id.vendor_type_id', 'Other', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(218, 18, 1, 'vnd_items.category_id.cat', 'Bus Rental', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(219, 18, 2, 'vnd_items.category_id.cat', 'Driver Service', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(220, 18, 3, 'vnd_items.category_id.cat', 'Food/Meal', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(221, 18, 4, 'vnd_items.category_id.cat', 'Uniforms', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(222, 18, 5, 'vnd_items.category_id.cat', 'Books', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(223, 19, 1, 'vnd_items.unit_id.unit', 'Kilometer', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(224, 19, 2, 'vnd_items.unit_id.unit', 'Day', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(225, 19, 3, 'vnd_items.unit_id.unit', 'Month', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(226, 19, 4, 'vnd_items.unit_id.unit', 'Visit', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(227, 19, 5, 'vnd_items.unit_id.unit', 'Hour', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(228, 19, 6, 'vnd_items.unit_id.unit', 'Piece', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(229, 19, 7, 'vnd_items.unit_id.unit', 'Kg', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(230, 19, 8, 'vnd_items.unit_id.unit', 'Trip', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(231, 20, 1, 'vnd_agreement_items_jnt.related_entity_type.related_entity_type', 'Vehicle', 'String', '"{\\"table_name\\":\\"tpt_vehicle\\"}"', 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(232, 20, 2, 'vnd_agreement_items_jnt.related_entity_type.related_entity_type', 'Driver', 'String', '"{\\"table_name\\":\\"tpt_personnel\\"}"', 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(233, 20, 3, 'vnd_agreement_items_jnt.related_entity_type.related_entity_type', 'Helper', 'String', '"{\\"table_name\\":\\"tpt_personnel\\"}"', 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(234, 21, 1, 'vnd_invoices.status.status', 'Pending', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(235, 21, 2, 'vnd_invoices.status.status', 'Approved', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(236, 21, 3, 'vnd_invoices.status.status', 'Fully Paid', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(237, 21, 4, 'vnd_invoices.status.status', 'Partially Paid', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(238, 21, 5, 'vnd_invoices.status.status', 'Cancelled', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(239, 22, 1, 'vnd_payments.payment_mode.payment_mode', 'Cash', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(240, 22, 2, 'vnd_payments.payment_mode.payment_mode', 'Bank Transfer', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(241, 22, 3, 'vnd_payments.payment_mode.payment_mode', 'Cheque', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(242, 22, 4, 'vnd_payments.payment_mode.payment_mode', 'Online Payment', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(243, 23, 1, 'ntf_notifications.confidentiality_level_id.confidentiality_level', 'Public', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(244, 23, 2, 'ntf_notifications.confidentiality_level_id.confidentiality_level', 'Restricted', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(245, 23, 3, 'ntf_notifications.confidentiality_level_id.confidentiality_level', 'Confidentiality', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(246, 24, 1, 'ntf_notifications.recurring_interval_id.recurring_interval', 'Hourly', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(247, 24, 2, 'ntf_notifications.recurring_interval_id.recurring_interval', 'Daily', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(248, 24, 3, 'ntf_notifications.recurring_interval_id.recurring_interval', 'Weekly', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(249, 24, 4, 'ntf_notifications.recurring_interval_id.recurring_interval', 'Monthly', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(250, 24, 5, 'ntf_notifications.recurring_interval_id.recurring_interval', 'Quarterly', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(251, 24, 6, 'ntf_notifications.recurring_interval_id.recurring_interval', 'Yearly', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(252, 25, 1, 'ntf_notification_channels.provider_id.provider', 'MSG91', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(253, 25, 2, 'ntf_notification_channels.provider_id.provider', 'Twilio', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(254, 25, 3, 'ntf_notification_channels.provider_id.provider', 'AWS SES', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(255, 25, 4, 'ntf_notification_channels.provider_id.provider', 'Meta API', 'String', NULL, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14');

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_dropdown_needs
CREATE TABLE IF NOT EXISTS `sys_dropdown_needs` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `db_type` enum('Prime','Tenant','Global') COLLATE utf8mb4_unicode_ci NOT NULL,
  `table_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `column_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `menu_category` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `main_menu` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sub_menu` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tab_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `field_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_system` tinyint(1) NOT NULL DEFAULT '1',
  `tenant_creation_allowed` tinyint(1) NOT NULL DEFAULT '0',
  `compulsory` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dropdownNeeds_db_table_column_key` (`db_type`,`table_name`,`column_name`),
  CONSTRAINT `chk_dropdown_needs_valid` CHECK ((((`tenant_creation_allowed` = 0) and (`menu_category` is null) and (`main_menu` is null) and (`sub_menu` is null) and (`tab_name` is null) and (`field_name` is null)) or ((`tenant_creation_allowed` = 1) and (`menu_category` is not null) and (`main_menu` is not null) and (`sub_menu` is not null) and (`tab_name` is not null) and (`field_name` is not null))))
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_dropdown_needs: ~25 rows (approximately)
DELETE FROM `sys_dropdown_needs`;
INSERT INTO `sys_dropdown_needs` (`id`, `db_type`, `table_name`, `column_name`, `menu_category`, `main_menu`, `sub_menu`, `tab_name`, `field_name`, `is_system`, `tenant_creation_allowed`, `compulsory`, `is_active`, `deleted_at`, `created_at`, `updated_at`) VALUES
	(1, 'Global', 'dummy_table_name', 'dummy_column_name', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(2, 'Global', 'cmp_medical_checks', 'check_type_id', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(3, 'Global', 'cmp_medical_checks', 'result', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(4, 'Global', 'tpt_vehicle_service_request', 'vehicle_status', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(5, 'Global', 'tpt_vehicle', 'vehicle_type_id', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(6, 'Global', 'tpt_vehicle', 'fuel_type_id', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(7, 'Global', 'tpt_vehicle', 'ownership_type_id', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(8, 'Global', 'tpt_vehicle', 'vehicle_emission_class_id', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(9, 'Global', 'tpt_personnel', 'id_type', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(10, 'Global', 'tpt_attendance_device', 'device_type', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(11, 'Global', 'tpt_attendance_device', 'device_os', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(12, 'Global', 'bil_tenant_invoicing_payments', 'mode', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(13, 'Global', 'bil_tenant_invoicing_payments', 'payment_status', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(14, 'Global', 'cmp_complaint_actions', 'action_type_id', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(15, 'Global', 'sch_entity_groups', 'entity_purpose_id', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(16, 'Global', 'sch_entity_groups', 'entity_purpose_id_2', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(17, 'Global', 'vnd_vendors', 'vendor_type_id', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(18, 'Global', 'vnd_items', 'category_id', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(19, 'Global', 'vnd_items', 'unit_id', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(20, 'Global', 'vnd_agreement_items_jnt', 'related_entity_type', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(21, 'Global', 'vnd_invoices', 'status', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(22, 'Global', 'vnd_payments', 'payment_mode', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(23, 'Global', 'ntf_notifications', 'confidentiality_level_id', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(24, 'Global', 'ntf_notifications', 'recurring_interval_id', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(25, 'Global', 'ntf_notification_channels', 'provider_id', NULL, NULL, NULL, NULL, NULL, 1, 0, 1, 1, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14');

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_media
CREATE TABLE IF NOT EXISTS `sys_media` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `model_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `model_id` INT unsigned NOT NULL,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `collection_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `file_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mime_type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `disk` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `conversions_disk` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `size` INT unsigned NOT NULL,
  `manipulations` json NOT NULL,
  `custom_properties` json NOT NULL,
  `generated_conversions` json NOT NULL,
  `responsive_images` json NOT NULL,
  `order_column` int unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sys_media_uuid_unique` (`uuid`),
  KEY `sys_media_model_type_model_id_index` (`model_type`,`model_id`),
  KEY `sys_media_order_column_index` (`order_column`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_media: ~0 rows (approximately)
DELETE FROM `sys_media`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_model_has_permissions_jnt
CREATE TABLE IF NOT EXISTS `sys_model_has_permissions_jnt` (
  `permission_id` INT unsigned NOT NULL,
  `model_type` varchar(190) COLLATE utf8mb4_unicode_ci NOT NULL,
  `model_id` INT unsigned NOT NULL,
  PRIMARY KEY (`permission_id`,`model_id`,`model_type`),
  KEY `model_has_permissions_model_id_model_type_index` (`model_id`,`model_type`),
  CONSTRAINT `sys_model_has_permissions_jnt_permission_id_foreign` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_model_has_permissions_jnt: ~0 rows (approximately)
DELETE FROM `sys_model_has_permissions_jnt`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_model_has_roles_jnt
CREATE TABLE IF NOT EXISTS `sys_model_has_roles_jnt` (
  `role_id` INT unsigned NOT NULL,
  `model_type` varchar(190) COLLATE utf8mb4_unicode_ci NOT NULL,
  `model_id` INT unsigned NOT NULL,
  PRIMARY KEY (`role_id`,`model_id`,`model_type`),
  KEY `model_has_roles_model_id_model_type_index` (`model_id`,`model_type`),
  CONSTRAINT `sys_model_has_roles_jnt_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_model_has_roles_jnt: ~14 rows (approximately)
DELETE FROM `sys_model_has_roles_jnt`;
INSERT INTO `sys_model_has_roles_jnt` (`role_id`, `model_type`, `model_id`) VALUES
	(1, 'App\\Models\\User', 2),
	(2, 'App\\Models\\User', 3),
	(3, 'App\\Models\\User', 4),
	(4, 'App\\Models\\User', 5),
	(4, 'App\\Models\\User', 6),
	(4, 'App\\Models\\User', 7),
	(7, 'App\\Models\\User', 8),
	(7, 'App\\Models\\User', 9),
	(6, 'App\\Models\\User', 10),
	(6, 'App\\Models\\User', 11),
	(9, 'App\\Models\\User', 12),
	(9, 'App\\Models\\User', 13),
	(8, 'App\\Models\\User', 14),
	(8, 'App\\Models\\User', 15);

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_permissions
CREATE TABLE IF NOT EXISTS `sys_permissions` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `guard_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sys_permissions_name_guard_name_unique` (`name`,`guard_name`)
) ENGINE=InnoDB AUTO_INCREMENT=731 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_permissions: ~730 rows (approximately)
DELETE FROM `sys_permissions`;
INSERT INTO `sys_permissions` (`id`, `name`, `guard_name`, `created_at`, `updated_at`) VALUES
	(1, 'tenant.menu.create', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(2, 'tenant.menu.view', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(3, 'tenant.menu.viewAny', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(4, 'tenant.menu.update', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(5, 'tenant.menu.delete', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(6, 'tenant.menu.restore', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(7, 'tenant.menu.forceDelete', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(8, 'tenant.menu.import', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(9, 'tenant.menu.export', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(10, 'tenant.menu.print', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(11, 'tenant.setting.create', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(12, 'tenant.setting.view', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(13, 'tenant.setting.viewAny', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(14, 'tenant.setting.update', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(15, 'tenant.setting.delete', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(16, 'tenant.setting.restore', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(17, 'tenant.setting.forceDelete', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(18, 'tenant.setting.import', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(19, 'tenant.setting.export', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(20, 'tenant.setting.print', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(21, 'tenant.dropdown.create', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(22, 'tenant.dropdown.view', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(23, 'tenant.dropdown.viewAny', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(24, 'tenant.dropdown.update', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(25, 'tenant.dropdown.delete', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(26, 'tenant.dropdown.restore', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(27, 'tenant.dropdown.forceDelete', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(28, 'tenant.dropdown.import', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(29, 'tenant.dropdown.export', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(30, 'tenant.dropdown.print', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(31, 'tenant.geography.create', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(32, 'tenant.geography.view', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(33, 'tenant.geography.viewAny', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(34, 'tenant.geography.update', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(35, 'tenant.geography.delete', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(36, 'tenant.geography.restore', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(37, 'tenant.geography.forceDelete', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(38, 'tenant.geography.import', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(39, 'tenant.geography.export', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(40, 'tenant.geography.print', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(41, 'tenant.language.create', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(42, 'tenant.language.view', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(43, 'tenant.language.viewAny', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(44, 'tenant.language.update', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(45, 'tenant.language.delete', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(46, 'tenant.language.restore', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(47, 'tenant.language.forceDelete', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(48, 'tenant.language.import', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(49, 'tenant.language.export', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(50, 'tenant.language.print', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(51, 'tenant.module.create', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(52, 'tenant.module.view', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(53, 'tenant.module.viewAny', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(54, 'tenant.module.update', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(55, 'tenant.module.delete', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(56, 'tenant.module.restore', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(57, 'tenant.module.forceDelete', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(58, 'tenant.module.import', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(59, 'tenant.module.export', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(60, 'tenant.module.print', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(61, 'tenant.organization.create', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(62, 'tenant.organization.view', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(63, 'tenant.organization.viewAny', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(64, 'tenant.organization.update', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(65, 'tenant.organization.delete', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(66, 'tenant.organization.restore', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(67, 'tenant.organization.forceDelete', 'web', '2026-01-12 12:55:06', '2026-01-12 12:55:06'),
	(68, 'tenant.organization.import', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(69, 'tenant.organization.export', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(70, 'tenant.organization.print', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(71, 'tenant.organization-group.create', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(72, 'tenant.organization-group.view', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(73, 'tenant.organization-group.viewAny', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(74, 'tenant.organization-group.update', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(75, 'tenant.organization-group.delete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(76, 'tenant.organization-group.restore', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(77, 'tenant.organization-group.forceDelete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(78, 'tenant.organization-group.import', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(79, 'tenant.organization-group.export', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(80, 'tenant.organization-group.print', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(81, 'tenant.plan.create', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(82, 'tenant.plan.view', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(83, 'tenant.plan.viewAny', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(84, 'tenant.plan.update', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(85, 'tenant.plan.delete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(86, 'tenant.plan.restore', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(87, 'tenant.plan.forceDelete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(88, 'tenant.plan.import', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(89, 'tenant.plan.export', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(90, 'tenant.plan.print', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(91, 'tenant.billing-cycle.create', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(92, 'tenant.billing-cycle.view', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(93, 'tenant.billing-cycle.viewAny', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(94, 'tenant.billing-cycle.update', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(95, 'tenant.billing-cycle.delete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(96, 'tenant.billing-cycle.restore', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(97, 'tenant.billing-cycle.forceDelete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(98, 'tenant.billing-cycle.import', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(99, 'tenant.billing-cycle.export', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(100, 'tenant.billing-cycle.print', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(101, 'tenant.session-board.create', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(102, 'tenant.session-board.view', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(103, 'tenant.session-board.viewAny', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(104, 'tenant.session-board.update', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(105, 'tenant.session-board.delete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(106, 'tenant.session-board.restore', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(107, 'tenant.session-board.forceDelete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(108, 'tenant.session-board.import', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(109, 'tenant.session-board.export', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(110, 'tenant.session-board.print', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(111, 'tenant.user.create', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(112, 'tenant.user.view', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(113, 'tenant.user.viewAny', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(114, 'tenant.user.update', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(115, 'tenant.user.delete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(116, 'tenant.user.restore', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(117, 'tenant.user.forceDelete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(118, 'tenant.user.import', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(119, 'tenant.user.export', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(120, 'tenant.user.print', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(121, 'tenant.role-permission.create', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(122, 'tenant.role-permission.view', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(123, 'tenant.role-permission.viewAny', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(124, 'tenant.role-permission.update', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(125, 'tenant.role-permission.delete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(126, 'tenant.role-permission.restore', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(127, 'tenant.role-permission.forceDelete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(128, 'tenant.role-permission.import', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(129, 'tenant.role-permission.export', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(130, 'tenant.role-permission.print', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(131, 'tenant.school.create', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(132, 'tenant.school.view', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(133, 'tenant.school.viewAny', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(134, 'tenant.school.update', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(135, 'tenant.school.delete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(136, 'tenant.school.restore', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(137, 'tenant.school.forceDelete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(138, 'tenant.school.import', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(139, 'tenant.school.export', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(140, 'tenant.school.print', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(141, 'tenant.school-setup.create', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(142, 'tenant.school-setup.view', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(143, 'tenant.school-setup.viewAny', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(144, 'tenant.school-setup.update', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(145, 'tenant.school-setup.delete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(146, 'tenant.school-setup.restore', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(147, 'tenant.school-setup.forceDelete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(148, 'tenant.school-setup.import', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(149, 'tenant.school-setup.export', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(150, 'tenant.school-setup.print', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(151, 'tenant.class-group.create', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(152, 'tenant.class-group.view', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(153, 'tenant.class-group.viewAny', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(154, 'tenant.class-group.update', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(155, 'tenant.class-group.delete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(156, 'tenant.class-group.restore', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(157, 'tenant.class-group.forceDelete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(158, 'tenant.class-group.import', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(159, 'tenant.class-group.export', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(160, 'tenant.class-group.print', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(161, 'tenant.section.create', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(162, 'tenant.section.view', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(163, 'tenant.section.viewAny', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(164, 'tenant.section.update', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(165, 'tenant.section.delete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(166, 'tenant.section.restore', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(167, 'tenant.section.forceDelete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(168, 'tenant.section.import', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(169, 'tenant.section.export', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(170, 'tenant.section.print', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(171, 'tenant.subject.create', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(172, 'tenant.subject.view', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(173, 'tenant.subject.viewAny', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(174, 'tenant.subject.update', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(175, 'tenant.subject.delete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(176, 'tenant.subject.restore', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(177, 'tenant.subject.forceDelete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(178, 'tenant.subject.import', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(179, 'tenant.subject.export', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(180, 'tenant.subject.print', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(181, 'tenant.subject-group.create', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(182, 'tenant.subject-group.view', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(183, 'tenant.subject-group.viewAny', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(184, 'tenant.subject-group.update', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(185, 'tenant.subject-group.delete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(186, 'tenant.subject-group.restore', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(187, 'tenant.subject-group.forceDelete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(188, 'tenant.subject-group.import', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(189, 'tenant.subject-group.export', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(190, 'tenant.subject-group.print', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(191, 'tenant.subject-type.create', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(192, 'tenant.subject-type.view', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(193, 'tenant.subject-type.viewAny', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(194, 'tenant.subject-type.update', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(195, 'tenant.subject-type.delete', 'web', '2026-01-12 12:55:07', '2026-01-12 12:55:07'),
	(196, 'tenant.subject-type.restore', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(197, 'tenant.subject-type.forceDelete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(198, 'tenant.subject-type.import', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(199, 'tenant.subject-type.export', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(200, 'tenant.subject-type.print', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(201, 'tenant.subject-class-mapping.create', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(202, 'tenant.subject-class-mapping.view', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(203, 'tenant.subject-class-mapping.viewAny', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(204, 'tenant.subject-class-mapping.update', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(205, 'tenant.subject-class-mapping.delete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(206, 'tenant.subject-class-mapping.restore', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(207, 'tenant.subject-class-mapping.forceDelete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(208, 'tenant.subject-class-mapping.import', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(209, 'tenant.subject-class-mapping.export', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(210, 'tenant.subject-class-mapping.print', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(211, 'tenant.class-subject-mgmt.create', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(212, 'tenant.class-subject-mgmt.view', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(213, 'tenant.class-subject-mgmt.viewAny', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(214, 'tenant.class-subject-mgmt.update', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(215, 'tenant.class-subject-mgmt.delete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(216, 'tenant.class-subject-mgmt.restore', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(217, 'tenant.class-subject-mgmt.forceDelete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(218, 'tenant.class-subject-mgmt.import', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(219, 'tenant.class-subject-mgmt.export', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(220, 'tenant.class-subject-mgmt.print', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(221, 'tenant.study-format.create', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(222, 'tenant.study-format.view', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(223, 'tenant.study-format.viewAny', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(224, 'tenant.study-format.update', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(225, 'tenant.study-format.delete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(226, 'tenant.study-format.restore', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(227, 'tenant.study-format.forceDelete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(228, 'tenant.study-format.import', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(229, 'tenant.study-format.export', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(230, 'tenant.study-format.print', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(231, 'tenant.competency.create', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(232, 'tenant.competency.view', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(233, 'tenant.competency.viewAny', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(234, 'tenant.competency.update', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(235, 'tenant.competency.delete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(236, 'tenant.competency.restore', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(237, 'tenant.competency.forceDelete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(238, 'tenant.competency.import', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(239, 'tenant.competency.export', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(240, 'tenant.competency.print', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(241, 'tenant.topic.create', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(242, 'tenant.topic.view', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(243, 'tenant.topic.viewAny', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(244, 'tenant.topic.update', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(245, 'tenant.topic.delete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(246, 'tenant.topic.restore', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(247, 'tenant.topic.forceDelete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(248, 'tenant.topic.import', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(249, 'tenant.topic.export', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(250, 'tenant.topic.print', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(251, 'tenant.topic-competency.create', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(252, 'tenant.topic-competency.view', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(253, 'tenant.topic-competency.viewAny', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(254, 'tenant.topic-competency.update', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(255, 'tenant.topic-competency.delete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(256, 'tenant.topic-competency.restore', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(257, 'tenant.topic-competency.forceDelete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(258, 'tenant.topic-competency.import', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(259, 'tenant.topic-competency.export', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(260, 'tenant.topic-competency.print', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(261, 'tenant.lesson.create', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(262, 'tenant.lesson.view', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(263, 'tenant.lesson.viewAny', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(264, 'tenant.lesson.update', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(265, 'tenant.lesson.delete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(266, 'tenant.lesson.restore', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(267, 'tenant.lesson.forceDelete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(268, 'tenant.lesson.import', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(269, 'tenant.lesson.export', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(270, 'tenant.lesson.print', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(271, 'tenant.student.create', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(272, 'tenant.student.view', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(273, 'tenant.student.viewAny', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(274, 'tenant.student.update', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(275, 'tenant.student.delete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(276, 'tenant.student.restore', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(277, 'tenant.student.forceDelete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(278, 'tenant.student.import', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(279, 'tenant.student.export', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(280, 'tenant.student.print', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(281, 'tenant.teacher.create', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(282, 'tenant.teacher.view', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(283, 'tenant.teacher.viewAny', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(284, 'tenant.teacher.update', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(285, 'tenant.teacher.delete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(286, 'tenant.teacher.restore', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(287, 'tenant.teacher.forceDelete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(288, 'tenant.teacher.import', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(289, 'tenant.teacher.export', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(290, 'tenant.teacher.print', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(291, 'tenant.infra-setup.create', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(292, 'tenant.infra-setup.view', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(293, 'tenant.infra-setup.viewAny', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(294, 'tenant.infra-setup.update', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(295, 'tenant.infra-setup.delete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(296, 'tenant.infra-setup.restore', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(297, 'tenant.infra-setup.forceDelete', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(298, 'tenant.infra-setup.import', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(299, 'tenant.infra-setup.export', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(300, 'tenant.infra-setup.print', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(301, 'tenant.building.create', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(302, 'tenant.building.view', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(303, 'tenant.building.viewAny', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(304, 'tenant.building.update', 'web', '2026-01-12 12:55:08', '2026-01-12 12:55:08'),
	(305, 'tenant.building.delete', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(306, 'tenant.building.restore', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(307, 'tenant.building.forceDelete', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(308, 'tenant.building.import', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(309, 'tenant.building.export', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(310, 'tenant.building.print', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(311, 'tenant.room.create', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(312, 'tenant.room.view', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(313, 'tenant.room.viewAny', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(314, 'tenant.room.update', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(315, 'tenant.room.delete', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(316, 'tenant.room.restore', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(317, 'tenant.room.forceDelete', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(318, 'tenant.room.import', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(319, 'tenant.room.export', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(320, 'tenant.room.print', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(321, 'tenant.room-type.create', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(322, 'tenant.room-type.view', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(323, 'tenant.room-type.viewAny', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(324, 'tenant.room-type.update', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(325, 'tenant.room-type.delete', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(326, 'tenant.room-type.restore', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(327, 'tenant.room-type.forceDelete', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(328, 'tenant.room-type.import', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(329, 'tenant.room-type.export', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(330, 'tenant.room-type.print', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(331, 'tenant.day.create', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(332, 'tenant.day.view', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(333, 'tenant.day.viewAny', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(334, 'tenant.day.update', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(335, 'tenant.day.delete', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(336, 'tenant.day.restore', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(337, 'tenant.day.forceDelete', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(338, 'tenant.day.import', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(339, 'tenant.day.export', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(340, 'tenant.day.print', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(341, 'tenant.period.create', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(342, 'tenant.period.view', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(343, 'tenant.period.viewAny', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(344, 'tenant.period.update', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(345, 'tenant.period.delete', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(346, 'tenant.period.restore', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(347, 'tenant.period.forceDelete', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(348, 'tenant.period.import', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(349, 'tenant.period.export', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(350, 'tenant.period.print', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(351, 'tenant.school-timing.create', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(352, 'tenant.school-timing.view', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(353, 'tenant.school-timing.viewAny', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(354, 'tenant.school-timing.update', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(355, 'tenant.school-timing.delete', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(356, 'tenant.school-timing.restore', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(357, 'tenant.school-timing.forceDelete', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(358, 'tenant.school-timing.import', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(359, 'tenant.school-timing.export', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(360, 'tenant.school-timing.print', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(361, 'tenant.timing-profile.create', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(362, 'tenant.timing-profile.view', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(363, 'tenant.timing-profile.viewAny', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(364, 'tenant.timing-profile.update', 'web', '2026-01-12 12:55:09', '2026-01-12 12:55:09'),
	(365, 'tenant.timing-profile.delete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(366, 'tenant.timing-profile.restore', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(367, 'tenant.timing-profile.forceDelete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(368, 'tenant.timing-profile.import', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(369, 'tenant.timing-profile.export', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(370, 'tenant.timing-profile.print', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(371, 'tenant.smart-timetable.create', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(372, 'tenant.smart-timetable.view', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(373, 'tenant.smart-timetable.viewAny', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(374, 'tenant.smart-timetable.update', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(375, 'tenant.smart-timetable.delete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(376, 'tenant.smart-timetable.restore', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(377, 'tenant.smart-timetable.forceDelete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(378, 'tenant.smart-timetable.import', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(379, 'tenant.smart-timetable.export', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(380, 'tenant.smart-timetable.print', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(381, 'tenant.transport.create', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(382, 'tenant.transport.view', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(383, 'tenant.transport.viewAny', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(384, 'tenant.transport.update', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(385, 'tenant.transport.delete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(386, 'tenant.transport.restore', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(387, 'tenant.transport.forceDelete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(388, 'tenant.transport.import', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(389, 'tenant.transport.export', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(390, 'tenant.transport.print', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(391, 'tenant.vehicle.create', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(392, 'tenant.vehicle.view', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(393, 'tenant.vehicle.viewAny', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(394, 'tenant.vehicle.update', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(395, 'tenant.vehicle.delete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(396, 'tenant.vehicle.restore', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(397, 'tenant.vehicle.forceDelete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(398, 'tenant.vehicle.import', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(399, 'tenant.vehicle.export', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(400, 'tenant.vehicle.print', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(401, 'tenant.route.create', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(402, 'tenant.route.view', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(403, 'tenant.route.viewAny', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(404, 'tenant.route.update', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(405, 'tenant.route.delete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(406, 'tenant.route.restore', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(407, 'tenant.route.forceDelete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(408, 'tenant.route.import', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(409, 'tenant.route.export', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(410, 'tenant.route.print', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(411, 'tenant.pickup-point.create', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(412, 'tenant.pickup-point.view', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(413, 'tenant.pickup-point.viewAny', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(414, 'tenant.pickup-point.update', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(415, 'tenant.pickup-point.delete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(416, 'tenant.pickup-point.restore', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(417, 'tenant.pickup-point.forceDelete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(418, 'tenant.pickup-point.import', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(419, 'tenant.pickup-point.export', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(420, 'tenant.pickup-point.print', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(421, 'tenant.pickup-point-route.create', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(422, 'tenant.pickup-point-route.view', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(423, 'tenant.pickup-point-route.viewAny', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(424, 'tenant.pickup-point-route.update', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(425, 'tenant.pickup-point-route.delete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(426, 'tenant.pickup-point-route.restore', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(427, 'tenant.pickup-point-route.forceDelete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(428, 'tenant.pickup-point-route.import', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(429, 'tenant.pickup-point-route.export', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(430, 'tenant.pickup-point-route.print', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(431, 'tenant.route-scheduler.create', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(432, 'tenant.route-scheduler.view', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(433, 'tenant.route-scheduler.viewAny', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(434, 'tenant.route-scheduler.update', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(435, 'tenant.route-scheduler.delete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(436, 'tenant.route-scheduler.restore', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(437, 'tenant.route-scheduler.forceDelete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(438, 'tenant.route-scheduler.import', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(439, 'tenant.route-scheduler.export', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(440, 'tenant.route-scheduler.print', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(441, 'tenant.trip.create', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(442, 'tenant.trip.view', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(443, 'tenant.trip.viewAny', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(444, 'tenant.trip.update', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(445, 'tenant.trip.delete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(446, 'tenant.trip.restore', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(447, 'tenant.trip.forceDelete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(448, 'tenant.trip.import', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(449, 'tenant.trip.export', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(450, 'tenant.trip.print', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(451, 'tenant.live-trip.create', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(452, 'tenant.live-trip.view', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(453, 'tenant.live-trip.viewAny', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(454, 'tenant.live-trip.update', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(455, 'tenant.live-trip.delete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(456, 'tenant.live-trip.restore', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(457, 'tenant.live-trip.forceDelete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(458, 'tenant.live-trip.import', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(459, 'tenant.live-trip.export', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(460, 'tenant.live-trip.print', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(461, 'tenant.shift.create', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(462, 'tenant.shift.view', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(463, 'tenant.shift.viewAny', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(464, 'tenant.shift.update', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(465, 'tenant.shift.delete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(466, 'tenant.shift.restore', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(467, 'tenant.shift.forceDelete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(468, 'tenant.shift.import', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(469, 'tenant.shift.export', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(470, 'tenant.shift.print', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(471, 'tenant.driver-attendance.create', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(472, 'tenant.driver-attendance.view', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(473, 'tenant.driver-attendance.viewAny', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(474, 'tenant.driver-attendance.update', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(475, 'tenant.driver-attendance.delete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(476, 'tenant.driver-attendance.restore', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(477, 'tenant.driver-attendance.forceDelete', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(478, 'tenant.driver-attendance.import', 'web', '2026-01-12 12:55:10', '2026-01-12 12:55:10'),
	(479, 'tenant.driver-attendance.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(480, 'tenant.driver-attendance.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(481, 'tenant.driver-helper.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(482, 'tenant.driver-helper.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(483, 'tenant.driver-helper.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(484, 'tenant.driver-helper.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(485, 'tenant.driver-helper.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(486, 'tenant.driver-helper.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(487, 'tenant.driver-helper.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(488, 'tenant.driver-helper.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(489, 'tenant.driver-helper.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(490, 'tenant.driver-helper.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(491, 'tenant.driver-route-vehicle.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(492, 'tenant.driver-route-vehicle.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(493, 'tenant.driver-route-vehicle.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(494, 'tenant.driver-route-vehicle.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(495, 'tenant.driver-route-vehicle.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(496, 'tenant.driver-route-vehicle.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(497, 'tenant.driver-route-vehicle.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(498, 'tenant.driver-route-vehicle.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(499, 'tenant.driver-route-vehicle.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(500, 'tenant.driver-route-vehicle.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(501, 'tenant.student-ai-location.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(502, 'tenant.student-ai-location.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(503, 'tenant.student-ai-location.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(504, 'tenant.student-ai-location.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(505, 'tenant.student-ai-location.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(506, 'tenant.student-ai-location.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(507, 'tenant.student-ai-location.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(508, 'tenant.student-ai-location.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(509, 'tenant.student-ai-location.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(510, 'tenant.student-ai-location.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(511, 'tenant.complexity-level.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(512, 'tenant.complexity-level.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(513, 'tenant.complexity-level.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(514, 'tenant.complexity-level.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(515, 'tenant.complexity-level.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(516, 'tenant.complexity-level.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(517, 'tenant.complexity-level.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(518, 'tenant.complexity-level.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(519, 'tenant.complexity-level.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(520, 'tenant.complexity-level.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(521, 'tenant.competency-type.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(522, 'tenant.competency-type.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(523, 'tenant.competency-type.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(524, 'tenant.competency-type.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(525, 'tenant.competency-type.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(526, 'tenant.competency-type.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(527, 'tenant.competency-type.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(528, 'tenant.competency-type.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(529, 'tenant.competency-type.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(530, 'tenant.competency-type.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(531, 'tenant.vehicle-inspection.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(532, 'tenant.vehicle-inspection.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(533, 'tenant.vehicle-inspection.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(534, 'tenant.vehicle-inspection.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(535, 'tenant.vehicle-inspection.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(536, 'tenant.vehicle-inspection.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(537, 'tenant.vehicle-inspection.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(538, 'tenant.vehicle-inspection.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(539, 'tenant.vehicle-inspection.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(540, 'tenant.vehicle-inspection.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(541, 'tenant.service-log.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(542, 'tenant.service-log.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(543, 'tenant.service-log.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(544, 'tenant.service-log.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(545, 'tenant.service-log.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(546, 'tenant.service-log.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(547, 'tenant.service-log.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(548, 'tenant.service-log.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(549, 'tenant.service-log.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(550, 'tenant.service-log.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(551, 'tenant.vehicle-maintenance.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(552, 'tenant.vehicle-maintenance.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(553, 'tenant.vehicle-maintenance.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(554, 'tenant.vehicle-maintenance.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(555, 'tenant.vehicle-maintenance.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(556, 'tenant.vehicle-maintenance.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(557, 'tenant.vehicle-maintenance.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(558, 'tenant.vehicle-maintenance.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(559, 'tenant.vehicle-maintenance.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(560, 'tenant.vehicle-maintenance.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(561, 'tenant.trip-management.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(562, 'tenant.trip-management.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(563, 'tenant.trip-management.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(564, 'tenant.trip-management.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(565, 'tenant.trip-management.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(566, 'tenant.trip-management.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(567, 'tenant.trip-management.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(568, 'tenant.trip-management.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(569, 'tenant.trip-management.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(570, 'tenant.trip-management.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(571, 'tenant.student-allocation.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(572, 'tenant.student-allocation.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(573, 'tenant.student-allocation.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(574, 'tenant.student-allocation.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(575, 'tenant.student-allocation.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(576, 'tenant.student-allocation.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(577, 'tenant.student-allocation.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(578, 'tenant.student-allocation.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(579, 'tenant.student-allocation.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(580, 'tenant.student-allocation.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(581, 'tenant.fee-master.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(582, 'tenant.fee-master.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(583, 'tenant.fee-master.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(584, 'tenant.fee-master.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(585, 'tenant.fee-master.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(586, 'tenant.fee-master.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(587, 'tenant.fee-master.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(588, 'tenant.fee-master.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(589, 'tenant.fee-master.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(590, 'tenant.fee-master.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(591, 'tenant.vendor-dashboard.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(592, 'tenant.vendor-dashboard.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(593, 'tenant.vendor-dashboard.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(594, 'tenant.vendor-dashboard.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(595, 'tenant.vendor-dashboard.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(596, 'tenant.vendor-dashboard.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(597, 'tenant.vendor-dashboard.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(598, 'tenant.vendor-dashboard.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(599, 'tenant.vendor-dashboard.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(600, 'tenant.vendor-dashboard.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(601, 'tenant.vendor.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(602, 'tenant.vendor.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(603, 'tenant.vendor.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(604, 'tenant.vendor.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(605, 'tenant.vendor.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(606, 'tenant.vendor.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(607, 'tenant.vendor.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(608, 'tenant.vendor.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(609, 'tenant.vendor.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(610, 'tenant.vendor.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(611, 'tenant.vendor-item.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(612, 'tenant.vendor-item.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(613, 'tenant.vendor-item.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(614, 'tenant.vendor-item.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(615, 'tenant.vendor-item.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(616, 'tenant.vendor-item.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(617, 'tenant.vendor-item.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(618, 'tenant.vendor-item.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(619, 'tenant.vendor-item.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(620, 'tenant.vendor-item.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(621, 'tenant.vendor-agreement.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(622, 'tenant.vendor-agreement.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(623, 'tenant.vendor-agreement.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(624, 'tenant.vendor-agreement.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(625, 'tenant.vendor-agreement.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(626, 'tenant.vendor-agreement.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(627, 'tenant.vendor-agreement.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(628, 'tenant.vendor-agreement.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(629, 'tenant.vendor-agreement.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(630, 'tenant.vendor-agreement.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(631, 'tenant.vendor-invoice.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(632, 'tenant.vendor-invoice.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(633, 'tenant.vendor-invoice.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(634, 'tenant.vendor-invoice.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(635, 'tenant.vendor-invoice.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(636, 'tenant.vendor-invoice.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(637, 'tenant.vendor-invoice.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(638, 'tenant.vendor-invoice.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(639, 'tenant.vendor-invoice.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(640, 'tenant.vendor-invoice.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(641, 'tenant.vendor-payment.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(642, 'tenant.vendor-payment.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(643, 'tenant.vendor-payment.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(644, 'tenant.vendor-payment.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(645, 'tenant.vendor-payment.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(646, 'tenant.vendor-payment.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(647, 'tenant.vendor-payment.forceDelete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(648, 'tenant.vendor-payment.import', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(649, 'tenant.vendor-payment.export', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(650, 'tenant.vendor-payment.print', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(651, 'tenant.usage-log.create', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(652, 'tenant.usage-log.view', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(653, 'tenant.usage-log.viewAny', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(654, 'tenant.usage-log.update', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(655, 'tenant.usage-log.delete', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(656, 'tenant.usage-log.restore', 'web', '2026-01-12 12:55:11', '2026-01-12 12:55:11'),
	(657, 'tenant.usage-log.forceDelete', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(658, 'tenant.usage-log.import', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(659, 'tenant.usage-log.export', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(660, 'tenant.usage-log.print', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(661, 'tenant.complaint-dashboard.create', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(662, 'tenant.complaint-dashboard.view', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(663, 'tenant.complaint-dashboard.viewAny', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(664, 'tenant.complaint-dashboard.update', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(665, 'tenant.complaint-dashboard.delete', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(666, 'tenant.complaint-dashboard.restore', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(667, 'tenant.complaint-dashboard.forceDelete', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(668, 'tenant.complaint-dashboard.import', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(669, 'tenant.complaint-dashboard.export', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(670, 'tenant.complaint-dashboard.print', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(671, 'tenant.complaint-category.create', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(672, 'tenant.complaint-category.view', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(673, 'tenant.complaint-category.viewAny', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(674, 'tenant.complaint-category.update', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(675, 'tenant.complaint-category.delete', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(676, 'tenant.complaint-category.restore', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(677, 'tenant.complaint-category.forceDelete', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(678, 'tenant.complaint-category.import', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(679, 'tenant.complaint-category.export', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(680, 'tenant.complaint-category.print', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(681, 'tenant.department-sla.create', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(682, 'tenant.department-sla.view', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(683, 'tenant.department-sla.viewAny', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(684, 'tenant.department-sla.update', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(685, 'tenant.department-sla.delete', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(686, 'tenant.department-sla.restore', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(687, 'tenant.department-sla.forceDelete', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(688, 'tenant.department-sla.import', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(689, 'tenant.department-sla.export', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(690, 'tenant.department-sla.print', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(691, 'tenant.complaint.create', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(692, 'tenant.complaint.view', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(693, 'tenant.complaint.viewAny', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(694, 'tenant.complaint.update', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(695, 'tenant.complaint.delete', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(696, 'tenant.complaint.restore', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(697, 'tenant.complaint.forceDelete', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(698, 'tenant.complaint.import', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(699, 'tenant.complaint.export', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(700, 'tenant.complaint.print', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(701, 'tenant.medical-check.create', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(702, 'tenant.medical-check.view', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(703, 'tenant.medical-check.viewAny', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(704, 'tenant.medical-check.update', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(705, 'tenant.medical-check.delete', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(706, 'tenant.medical-check.restore', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(707, 'tenant.medical-check.forceDelete', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(708, 'tenant.medical-check.import', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(709, 'tenant.medical-check.export', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(710, 'tenant.medical-check.print', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(711, 'tenant.complaint-action.create', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(712, 'tenant.complaint-action.view', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(713, 'tenant.complaint-action.viewAny', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(714, 'tenant.complaint-action.update', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(715, 'tenant.complaint-action.delete', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(716, 'tenant.complaint-action.restore', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(717, 'tenant.complaint-action.forceDelete', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(718, 'tenant.complaint-action.import', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(719, 'tenant.complaint-action.export', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(720, 'tenant.complaint-action.print', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(721, 'tenant.ai-insights.create', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(722, 'tenant.ai-insights.view', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(723, 'tenant.ai-insights.viewAny', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(724, 'tenant.ai-insights.update', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(725, 'tenant.ai-insights.delete', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(726, 'tenant.ai-insights.restore', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(727, 'tenant.ai-insights.forceDelete', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(728, 'tenant.ai-insights.import', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(729, 'tenant.ai-insights.export', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12'),
	(730, 'tenant.ai-insights.print', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12');

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_roles
CREATE TABLE IF NOT EXISTS `sys_roles` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `guard_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_system` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `sys_roles_name_guard_name_unique` (`name`,`guard_name`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_roles: ~9 rows (approximately)
DELETE FROM `sys_roles`;
INSERT INTO `sys_roles` (`id`, `name`, `short_name`, `guard_name`, `created_at`, `updated_at`, `description`, `is_system`) VALUES
	(1, 'Super Admin', 'super_admin', 'web', '2026-01-12 12:55:12', '2026-01-12 12:55:12', 'Full system access, manages roles & permissions', 1),
	(2, 'Principal', 'principal', 'web', '2026-01-12 12:55:13', '2026-01-12 12:55:13', 'Head of the school, oversees all operations', 0),
	(3, 'Vice Principal', 'vice_principal', 'web', '2026-01-12 12:55:13', '2026-01-12 12:55:13', 'Supports principal, handles academics & discipline', 0),
	(4, 'Teacher', 'teacher', 'web', '2026-01-12 12:55:13', '2026-01-12 12:55:13', 'Handles classroom teaching and student management', 0),
	(5, 'Staff', 'staff', 'web', '2026-01-12 12:55:13', '2026-01-12 12:55:13', 'General non-teaching school staff (admin, clerical, etc.)', 0),
	(6, 'Accountant', 'accountant', 'web', '2026-01-12 12:55:13', '2026-01-12 12:55:13', 'Handles school finances, fees, and accounts', 0),
	(7, 'Librarian', 'librarian', 'web', '2026-01-12 12:55:13', '2026-01-12 12:55:13', 'Manages library resources and inventory', 0),
	(8, 'Parent', 'parent', 'web', '2026-01-12 12:55:13', '2026-01-12 12:55:13', 'Access to ward/student data and reports', 0),
	(9, 'Student', 'student', 'web', '2026-01-12 12:55:13', '2026-01-12 12:55:13', 'Access to personal academic data and coursework', 0);

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_role_has_permissions_jnt
CREATE TABLE IF NOT EXISTS `sys_role_has_permissions_jnt` (
  `permission_id` INT unsigned NOT NULL,
  `role_id` INT unsigned NOT NULL,
  PRIMARY KEY (`permission_id`,`role_id`),
  KEY `sys_role_has_permissions_jnt_role_id_foreign` (`role_id`),
  CONSTRAINT `sys_role_has_permissions_jnt_permission_id_foreign` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `sys_role_has_permissions_jnt_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_role_has_permissions_jnt: ~730 rows (approximately)
DELETE FROM `sys_role_has_permissions_jnt`;
INSERT INTO `sys_role_has_permissions_jnt` (`permission_id`, `role_id`) VALUES
	(1, 1),
	(2, 1),
	(3, 1),
	(4, 1),
	(5, 1),
	(6, 1),
	(7, 1),
	(8, 1),
	(9, 1),
	(10, 1),
	(11, 1),
	(12, 1),
	(13, 1),
	(14, 1),
	(15, 1),
	(16, 1),
	(17, 1),
	(18, 1),
	(19, 1),
	(20, 1),
	(21, 1),
	(22, 1),
	(23, 1),
	(24, 1),
	(25, 1),
	(26, 1),
	(27, 1),
	(28, 1),
	(29, 1),
	(30, 1),
	(31, 1),
	(32, 1),
	(33, 1),
	(34, 1),
	(35, 1),
	(36, 1),
	(37, 1),
	(38, 1),
	(39, 1),
	(40, 1),
	(41, 1),
	(42, 1),
	(43, 1),
	(44, 1),
	(45, 1),
	(46, 1),
	(47, 1),
	(48, 1),
	(49, 1),
	(50, 1),
	(51, 1),
	(52, 1),
	(53, 1),
	(54, 1),
	(55, 1),
	(56, 1),
	(57, 1),
	(58, 1),
	(59, 1),
	(60, 1),
	(61, 1),
	(62, 1),
	(63, 1),
	(64, 1),
	(65, 1),
	(66, 1),
	(67, 1),
	(68, 1),
	(69, 1),
	(70, 1),
	(71, 1),
	(72, 1),
	(73, 1),
	(74, 1),
	(75, 1),
	(76, 1),
	(77, 1),
	(78, 1),
	(79, 1),
	(80, 1),
	(81, 1),
	(82, 1),
	(83, 1),
	(84, 1),
	(85, 1),
	(86, 1),
	(87, 1),
	(88, 1),
	(89, 1),
	(90, 1),
	(91, 1),
	(92, 1),
	(93, 1),
	(94, 1),
	(95, 1),
	(96, 1),
	(97, 1),
	(98, 1),
	(99, 1),
	(100, 1),
	(101, 1),
	(102, 1),
	(103, 1),
	(104, 1),
	(105, 1),
	(106, 1),
	(107, 1),
	(108, 1),
	(109, 1),
	(110, 1),
	(111, 1),
	(112, 1),
	(113, 1),
	(114, 1),
	(115, 1),
	(116, 1),
	(117, 1),
	(118, 1),
	(119, 1),
	(120, 1),
	(121, 1),
	(122, 1),
	(123, 1),
	(124, 1),
	(125, 1),
	(126, 1),
	(127, 1),
	(128, 1),
	(129, 1),
	(130, 1),
	(131, 1),
	(132, 1),
	(133, 1),
	(134, 1),
	(135, 1),
	(136, 1),
	(137, 1),
	(138, 1),
	(139, 1),
	(140, 1),
	(141, 1),
	(142, 1),
	(143, 1),
	(144, 1),
	(145, 1),
	(146, 1),
	(147, 1),
	(148, 1),
	(149, 1),
	(150, 1),
	(151, 1),
	(152, 1),
	(153, 1),
	(154, 1),
	(155, 1),
	(156, 1),
	(157, 1),
	(158, 1),
	(159, 1),
	(160, 1),
	(161, 1),
	(162, 1),
	(163, 1),
	(164, 1),
	(165, 1),
	(166, 1),
	(167, 1),
	(168, 1),
	(169, 1),
	(170, 1),
	(171, 1),
	(172, 1),
	(173, 1),
	(174, 1),
	(175, 1),
	(176, 1),
	(177, 1),
	(178, 1),
	(179, 1),
	(180, 1),
	(181, 1),
	(182, 1),
	(183, 1),
	(184, 1),
	(185, 1),
	(186, 1),
	(187, 1),
	(188, 1),
	(189, 1),
	(190, 1),
	(191, 1),
	(192, 1),
	(193, 1),
	(194, 1),
	(195, 1),
	(196, 1),
	(197, 1),
	(198, 1),
	(199, 1),
	(200, 1),
	(201, 1),
	(202, 1),
	(203, 1),
	(204, 1),
	(205, 1),
	(206, 1),
	(207, 1),
	(208, 1),
	(209, 1),
	(210, 1),
	(211, 1),
	(212, 1),
	(213, 1),
	(214, 1),
	(215, 1),
	(216, 1),
	(217, 1),
	(218, 1),
	(219, 1),
	(220, 1),
	(221, 1),
	(222, 1),
	(223, 1),
	(224, 1),
	(225, 1),
	(226, 1),
	(227, 1),
	(228, 1),
	(229, 1),
	(230, 1),
	(231, 1),
	(232, 1),
	(233, 1),
	(234, 1),
	(235, 1),
	(236, 1),
	(237, 1),
	(238, 1),
	(239, 1),
	(240, 1),
	(241, 1),
	(242, 1),
	(243, 1),
	(244, 1),
	(245, 1),
	(246, 1),
	(247, 1),
	(248, 1),
	(249, 1),
	(250, 1),
	(251, 1),
	(252, 1),
	(253, 1),
	(254, 1),
	(255, 1),
	(256, 1),
	(257, 1),
	(258, 1),
	(259, 1),
	(260, 1),
	(261, 1),
	(262, 1),
	(263, 1),
	(264, 1),
	(265, 1),
	(266, 1),
	(267, 1),
	(268, 1),
	(269, 1),
	(270, 1),
	(271, 1),
	(272, 1),
	(273, 1),
	(274, 1),
	(275, 1),
	(276, 1),
	(277, 1),
	(278, 1),
	(279, 1),
	(280, 1),
	(281, 1),
	(282, 1),
	(283, 1),
	(284, 1),
	(285, 1),
	(286, 1),
	(287, 1),
	(288, 1),
	(289, 1),
	(290, 1),
	(291, 1),
	(292, 1),
	(293, 1),
	(294, 1),
	(295, 1),
	(296, 1),
	(297, 1),
	(298, 1),
	(299, 1),
	(300, 1),
	(301, 1),
	(302, 1),
	(303, 1),
	(304, 1),
	(305, 1),
	(306, 1),
	(307, 1),
	(308, 1),
	(309, 1),
	(310, 1),
	(311, 1),
	(312, 1),
	(313, 1),
	(314, 1),
	(315, 1),
	(316, 1),
	(317, 1),
	(318, 1),
	(319, 1),
	(320, 1),
	(321, 1),
	(322, 1),
	(323, 1),
	(324, 1),
	(325, 1),
	(326, 1),
	(327, 1),
	(328, 1),
	(329, 1),
	(330, 1),
	(331, 1),
	(332, 1),
	(333, 1),
	(334, 1),
	(335, 1),
	(336, 1),
	(337, 1),
	(338, 1),
	(339, 1),
	(340, 1),
	(341, 1),
	(342, 1),
	(343, 1),
	(344, 1),
	(345, 1),
	(346, 1),
	(347, 1),
	(348, 1),
	(349, 1),
	(350, 1),
	(351, 1),
	(352, 1),
	(353, 1),
	(354, 1),
	(355, 1),
	(356, 1),
	(357, 1),
	(358, 1),
	(359, 1),
	(360, 1),
	(361, 1),
	(362, 1),
	(363, 1),
	(364, 1),
	(365, 1),
	(366, 1),
	(367, 1),
	(368, 1),
	(369, 1),
	(370, 1),
	(371, 1),
	(372, 1),
	(373, 1),
	(374, 1),
	(375, 1),
	(376, 1),
	(377, 1),
	(378, 1),
	(379, 1),
	(380, 1),
	(381, 1),
	(382, 1),
	(383, 1),
	(384, 1),
	(385, 1),
	(386, 1),
	(387, 1),
	(388, 1),
	(389, 1),
	(390, 1),
	(391, 1),
	(392, 1),
	(393, 1),
	(394, 1),
	(395, 1),
	(396, 1),
	(397, 1),
	(398, 1),
	(399, 1),
	(400, 1),
	(401, 1),
	(402, 1),
	(403, 1),
	(404, 1),
	(405, 1),
	(406, 1),
	(407, 1),
	(408, 1),
	(409, 1),
	(410, 1),
	(411, 1),
	(412, 1),
	(413, 1),
	(414, 1),
	(415, 1),
	(416, 1),
	(417, 1),
	(418, 1),
	(419, 1),
	(420, 1),
	(421, 1),
	(422, 1),
	(423, 1),
	(424, 1),
	(425, 1),
	(426, 1),
	(427, 1),
	(428, 1),
	(429, 1),
	(430, 1),
	(431, 1),
	(432, 1),
	(433, 1),
	(434, 1),
	(435, 1),
	(436, 1),
	(437, 1),
	(438, 1),
	(439, 1),
	(440, 1),
	(441, 1),
	(442, 1),
	(443, 1),
	(444, 1),
	(445, 1),
	(446, 1),
	(447, 1),
	(448, 1),
	(449, 1),
	(450, 1),
	(451, 1),
	(452, 1),
	(453, 1),
	(454, 1),
	(455, 1),
	(456, 1),
	(457, 1),
	(458, 1),
	(459, 1),
	(460, 1),
	(461, 1),
	(462, 1),
	(463, 1),
	(464, 1),
	(465, 1),
	(466, 1),
	(467, 1),
	(468, 1),
	(469, 1),
	(470, 1),
	(471, 1),
	(472, 1),
	(473, 1),
	(474, 1),
	(475, 1),
	(476, 1),
	(477, 1),
	(478, 1),
	(479, 1),
	(480, 1),
	(481, 1),
	(482, 1),
	(483, 1),
	(484, 1),
	(485, 1),
	(486, 1),
	(487, 1),
	(488, 1),
	(489, 1),
	(490, 1),
	(491, 1),
	(492, 1),
	(493, 1),
	(494, 1),
	(495, 1),
	(496, 1),
	(497, 1),
	(498, 1),
	(499, 1),
	(500, 1),
	(501, 1),
	(502, 1),
	(503, 1),
	(504, 1),
	(505, 1),
	(506, 1),
	(507, 1),
	(508, 1),
	(509, 1),
	(510, 1),
	(511, 1),
	(512, 1),
	(513, 1),
	(514, 1),
	(515, 1),
	(516, 1),
	(517, 1),
	(518, 1),
	(519, 1),
	(520, 1),
	(521, 1),
	(522, 1),
	(523, 1),
	(524, 1),
	(525, 1),
	(526, 1),
	(527, 1),
	(528, 1),
	(529, 1),
	(530, 1),
	(531, 1),
	(532, 1),
	(533, 1),
	(534, 1),
	(535, 1),
	(536, 1),
	(537, 1),
	(538, 1),
	(539, 1),
	(540, 1),
	(541, 1),
	(542, 1),
	(543, 1),
	(544, 1),
	(545, 1),
	(546, 1),
	(547, 1),
	(548, 1),
	(549, 1),
	(550, 1),
	(551, 1),
	(552, 1),
	(553, 1),
	(554, 1),
	(555, 1),
	(556, 1),
	(557, 1),
	(558, 1),
	(559, 1),
	(560, 1),
	(561, 1),
	(562, 1),
	(563, 1),
	(564, 1),
	(565, 1),
	(566, 1),
	(567, 1),
	(568, 1),
	(569, 1),
	(570, 1),
	(571, 1),
	(572, 1),
	(573, 1),
	(574, 1),
	(575, 1),
	(576, 1),
	(577, 1),
	(578, 1),
	(579, 1),
	(580, 1),
	(581, 1),
	(582, 1),
	(583, 1),
	(584, 1),
	(585, 1),
	(586, 1),
	(587, 1),
	(588, 1),
	(589, 1),
	(590, 1),
	(591, 1),
	(592, 1),
	(593, 1),
	(594, 1),
	(595, 1),
	(596, 1),
	(597, 1),
	(598, 1),
	(599, 1),
	(600, 1),
	(601, 1),
	(602, 1),
	(603, 1),
	(604, 1),
	(605, 1),
	(606, 1),
	(607, 1),
	(608, 1),
	(609, 1),
	(610, 1),
	(611, 1),
	(612, 1),
	(613, 1),
	(614, 1),
	(615, 1),
	(616, 1),
	(617, 1),
	(618, 1),
	(619, 1),
	(620, 1),
	(621, 1),
	(622, 1),
	(623, 1),
	(624, 1),
	(625, 1),
	(626, 1),
	(627, 1),
	(628, 1),
	(629, 1),
	(630, 1),
	(631, 1),
	(632, 1),
	(633, 1),
	(634, 1),
	(635, 1),
	(636, 1),
	(637, 1),
	(638, 1),
	(639, 1),
	(640, 1),
	(641, 1),
	(642, 1),
	(643, 1),
	(644, 1),
	(645, 1),
	(646, 1),
	(647, 1),
	(648, 1),
	(649, 1),
	(650, 1),
	(651, 1),
	(652, 1),
	(653, 1),
	(654, 1),
	(655, 1),
	(656, 1),
	(657, 1),
	(658, 1),
	(659, 1),
	(660, 1),
	(661, 1),
	(662, 1),
	(663, 1),
	(664, 1),
	(665, 1),
	(666, 1),
	(667, 1),
	(668, 1),
	(669, 1),
	(670, 1),
	(671, 1),
	(672, 1),
	(673, 1),
	(674, 1),
	(675, 1),
	(676, 1),
	(677, 1),
	(678, 1),
	(679, 1),
	(680, 1),
	(681, 1),
	(682, 1),
	(683, 1),
	(684, 1),
	(685, 1),
	(686, 1),
	(687, 1),
	(688, 1),
	(689, 1),
	(690, 1),
	(691, 1),
	(692, 1),
	(693, 1),
	(694, 1),
	(695, 1),
	(696, 1),
	(697, 1),
	(698, 1),
	(699, 1),
	(700, 1),
	(701, 1),
	(702, 1),
	(703, 1),
	(704, 1),
	(705, 1),
	(706, 1),
	(707, 1),
	(708, 1),
	(709, 1),
	(710, 1),
	(711, 1),
	(712, 1),
	(713, 1),
	(714, 1),
	(715, 1),
	(716, 1),
	(717, 1),
	(718, 1),
	(719, 1),
	(720, 1),
	(721, 1),
	(722, 1),
	(723, 1),
	(724, 1),
	(725, 1),
	(726, 1),
	(727, 1),
	(728, 1),
	(729, 1),
	(730, 1);

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_settings
CREATE TABLE IF NOT EXISTS `sys_settings` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `value` text COLLATE utf8mb4_unicode_ci,
  `type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_public` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `settings_key_index` (`key`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_settings: ~11 rows (approximately)
DELETE FROM `sys_settings`;
INSERT INTO `sys_settings` (`id`, `key`, `description`, `value`, `type`, `is_public`, `created_at`, `updated_at`) VALUES
	(1, 'default_language', 'Default language for the system interface', 'en', 'string', 1, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(2, 'default_theme', 'Default theme to be used by the system', 'light', 'string', 1, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(3, 'default_side_bar_collapse', 'Whether sidebar is collapsed by default (0 = false, 1 = true)', '0', 'boolean', 0, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(4, 'school_logo_url', 'URL of the school logo to display on system pages', 'https://example.com/logo.png', 'string', 1, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(5, 'contact_email', 'Primary contact email address for the organization', 'info@example.com', 'string', 1, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(6, 'maintenance_mode', 'Flag to enable or disable maintenance mode', '0', 'boolean', 0, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(7, 'timezone', 'Default timezone for the system', 'UTC', 'string', 1, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(8, 'subject_group__used__for__all__sections', 'If enabled, subject group will be used for all sections and section selection will be disabled.', 'TURE', 'boolean', 1, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(9, 'allow_only_one_side_transport_charges', 'If enabled, transport charges will be applied for only one side (either pickup or drop) instead of both.', 'TRUE', 'boolean', 1, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(10, 'allow_different_pickup_and_drop_point', 'If enabled, students can have different pickup and drop locations for transportation.', 'TRUE', 'boolean', 1, '2026-01-12 12:55:14', '2026-01-12 12:55:14'),
	(11, 'allow_extra_student_in_vehicale_beyond_capacity', 'If enabled, allows assigning additional students to a vehicle even if it exceeds the defined seating capacity.', 'TRUE', 'boolean', 1, '2026-01-12 12:55:14', '2026-01-12 12:55:14');

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_users
CREATE TABLE IF NOT EXISTS `sys_users` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `emp_code` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone_no` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mobile_no` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `two_factor_auth_enabled` tinyint(1) NOT NULL DEFAULT '0',
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '0',
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_super_admin` tinyint(1) NOT NULL DEFAULT '0',
  `status` enum('ACTIVE','INVITED','DISABLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  `last_login_at` datetime DEFAULT NULL,
  `super_admin_flag` tinyint GENERATED ALWAYS AS ((case when (`is_super_admin` = 1) then 1 else NULL end)) STORED,
  `remember_token` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sys_users_short_name_unique` (`short_name`),
  UNIQUE KEY `sys_users_emp_code_unique` (`emp_code`),
  UNIQUE KEY `sys_users_email_unique` (`email`),
  UNIQUE KEY `ux_single_super_admin` (`super_admin_flag`),
  KEY `idx_users_status` (`status`),
  KEY `idx_users_active` (`is_active`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.sys_users: ~15 rows (approximately)
DELETE FROM `sys_users`;
INSERT INTO `sys_users` (`id`, `name`, `short_name`, `emp_code`, `email`, `phone_no`, `mobile_no`, `two_factor_auth_enabled`, `email_verified_at`, `is_active`, `password`, `is_super_admin`, `status`, `last_login_at`, `remember_token`, `created_at`, `updated_at`, `deleted_at`) VALUES
	(1, 'Root User', 'root', 'abc', 'root@primeai.com', NULL, NULL, 0, NULL, 1, '$2y$12$AtRxXzmAdYDpPql7nukuLOp91oeZVs9TmIXvsPElgZUReiGZ4PxhK', 0, 'ACTIVE', NULL, NULL, '2026-01-12 12:55:06', '2026-01-12 12:55:06', NULL),
	(2, 'Root User', 'ROOT-3614', '2579', 'root@tenant.com', NULL, NULL, 0, NULL, 1, '$2y$12$KQ3.GSgk2Xbd2UjKlPcH2uelvIIcEOaIZ7JETlnUQ6t5JfTNa.vHa', 1, 'ACTIVE', NULL, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14', NULL),
	(3, 'Principal User', 'PRIN1-2582', '34004', 'principal@tenant.com', NULL, NULL, 0, NULL, 1, '$2y$12$KQ3.GSgk2Xbd2UjKlPcH2uelvIIcEOaIZ7JETlnUQ6t5JfTNa.vHa', 0, 'ACTIVE', NULL, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14', NULL),
	(4, 'Vice Principal User', 'VPRIN1-4805', '79625', 'viceprincipal@tenant.com', NULL, NULL, 0, NULL, 1, '$2y$12$KQ3.GSgk2Xbd2UjKlPcH2uelvIIcEOaIZ7JETlnUQ6t5JfTNa.vHa', 0, 'ACTIVE', NULL, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14', NULL),
	(5, 'Teacher One', 'TEA1-1720', '9643', 'teacher1@primeai.com', NULL, NULL, 0, NULL, 1, '$2y$12$KQ3.GSgk2Xbd2UjKlPcH2uelvIIcEOaIZ7JETlnUQ6t5JfTNa.vHa', 0, 'ACTIVE', NULL, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14', NULL),
	(6, 'Teacher Two', 'TEA2-1068', '64892', 'teacher2@primeai.com', NULL, NULL, 0, NULL, 1, '$2y$12$KQ3.GSgk2Xbd2UjKlPcH2uelvIIcEOaIZ7JETlnUQ6t5JfTNa.vHa', 0, 'ACTIVE', NULL, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14', NULL),
	(7, 'Teacher Three', 'TEA3-3309', '52929', 'teacher3@primeai.com', NULL, NULL, 0, NULL, 1, '$2y$12$KQ3.GSgk2Xbd2UjKlPcH2uelvIIcEOaIZ7JETlnUQ6t5JfTNa.vHa', 0, 'ACTIVE', NULL, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14', NULL),
	(8, 'Librarian One', 'LIB1-2886', '83672', 'librarian1@primeai.com', NULL, NULL, 0, NULL, 1, '$2y$12$KQ3.GSgk2Xbd2UjKlPcH2uelvIIcEOaIZ7JETlnUQ6t5JfTNa.vHa', 0, 'ACTIVE', NULL, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14', NULL),
	(9, 'Librarian Two', 'LIB2-4583', '90632', 'librarian2@primeai.com', NULL, NULL, 0, NULL, 1, '$2y$12$KQ3.GSgk2Xbd2UjKlPcH2uelvIIcEOaIZ7JETlnUQ6t5JfTNa.vHa', 0, 'ACTIVE', NULL, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14', NULL),
	(10, 'Accountant One', 'ACC1-1498', '76558', 'accountant1@primeai.com', NULL, NULL, 0, NULL, 1, '$2y$12$KQ3.GSgk2Xbd2UjKlPcH2uelvIIcEOaIZ7JETlnUQ6t5JfTNa.vHa', 0, 'ACTIVE', NULL, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14', NULL),
	(11, 'Accountant Two', 'ACC2-3736', '48920', 'accountant2@primeai.com', NULL, NULL, 0, NULL, 1, '$2y$12$KQ3.GSgk2Xbd2UjKlPcH2uelvIIcEOaIZ7JETlnUQ6t5JfTNa.vHa', 0, 'ACTIVE', NULL, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14', NULL),
	(12, 'Student One', 'STDNT1-2381', '39702', 'student1@primeai.com', NULL, NULL, 0, NULL, 1, '$2y$12$KQ3.GSgk2Xbd2UjKlPcH2uelvIIcEOaIZ7JETlnUQ6t5JfTNa.vHa', 0, 'ACTIVE', NULL, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14', NULL),
	(13, 'Student Two', 'STDNT2-2048', '50036', 'student2@primeai.com', NULL, NULL, 0, NULL, 1, '$2y$12$KQ3.GSgk2Xbd2UjKlPcH2uelvIIcEOaIZ7JETlnUQ6t5JfTNa.vHa', 0, 'ACTIVE', NULL, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14', NULL),
	(14, 'Parent One', 'PRNT1-1708', '64911', 'parent1@primeai.com', NULL, NULL, 0, NULL, 1, '$2y$12$KQ3.GSgk2Xbd2UjKlPcH2uelvIIcEOaIZ7JETlnUQ6t5JfTNa.vHa', 0, 'ACTIVE', NULL, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14', NULL),
	(15, 'Parent Two', 'PRNT2-3940', '55828', 'parent2@primeai.com', NULL, NULL, 0, NULL, 1, '$2y$12$KQ3.GSgk2Xbd2UjKlPcH2uelvIIcEOaIZ7JETlnUQ6t5JfTNa.vHa', 0, 'ACTIVE', NULL, NULL, '2026-01-12 12:55:14', '2026-01-12 12:55:14', NULL);

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.timing_profile_periods
CREATE TABLE IF NOT EXISTS `timing_profile_periods` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.timing_profile_periods: ~0 rows (approximately)
DELETE FROM `timing_profile_periods`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_attendance_device
CREATE TABLE IF NOT EXISTS `tpt_attendance_device` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `user_id` INT unsigned NOT NULL,
  `device_uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `device_type` INT unsigned NOT NULL,
  `device_os` INT unsigned NOT NULL,
  `os_version` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `device_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `device_model` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pg_app_version` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pg_fcm_token` text COLLATE utf8mb4_unicode_ci,
  `location` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pg_first_registered_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `pg_last_seen_at` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_device` (`user_id`,`device_uuid`),
  UNIQUE KEY `tpt_attendance_device_device_uuid_unique` (`device_uuid`),
  KEY `idx_attendance_device_user` (`user_id`),
  CONSTRAINT `fk_attendance_device_user` FOREIGN KEY (`user_id`) REFERENCES `tpt_personnel` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_attendance_device: ~0 rows (approximately)
DELETE FROM `tpt_attendance_device`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_daily_vehicle_inspection
CREATE TABLE IF NOT EXISTS `tpt_daily_vehicle_inspection` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `vehicle_id` INT unsigned NOT NULL,
  `driver_id` INT unsigned DEFAULT NULL,
  `inspected_by` INT unsigned DEFAULT NULL,
  `inspection_date` timestamp NOT NULL,
  `odometer_reading` INT unsigned DEFAULT NULL,
  `fuel_level_reading` decimal(6,2) DEFAULT NULL,
  `tire_condition_ok` tinyint(1) NOT NULL DEFAULT '0',
  `lights_condition_ok` tinyint(1) NOT NULL DEFAULT '0',
  `brakes_condition_ok` tinyint(1) NOT NULL DEFAULT '0',
  `engine_condition_ok` tinyint(1) NOT NULL DEFAULT '0',
  `battery_condition_ok` tinyint(1) NOT NULL DEFAULT '0',
  `fire_extinguisher_condition_ok` tinyint(1) NOT NULL DEFAULT '0',
  `first_aid_kit_condition_ok` tinyint(1) NOT NULL DEFAULT '0',
  `seat_belts_condition_ok` tinyint(1) NOT NULL DEFAULT '0',
  `headlights_condition_ok` tinyint(1) NOT NULL DEFAULT '0',
  `tailights_condition_ok` tinyint(1) NOT NULL DEFAULT '0',
  `wipers_condition_ok` tinyint(1) NOT NULL DEFAULT '0',
  `mirrors_condition_ok` tinyint(1) NOT NULL DEFAULT '0',
  `steering_wheel_condition_ok` tinyint(1) NOT NULL DEFAULT '0',
  `emergency_tools_condition_ok` tinyint(1) NOT NULL DEFAULT '0',
  `cleanliness_ok` tinyint(1) NOT NULL DEFAULT '0',
  `any_issues_found` tinyint(1) NOT NULL DEFAULT '0',
  `issues_description` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `inspection_status` enum('Passed','Failed','Pending') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Pending',
  `inspected_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tpt_daily_vehicle_inspection_vehicle_id_foreign` (`vehicle_id`),
  KEY `tpt_daily_vehicle_inspection_driver_id_foreign` (`driver_id`),
  KEY `tpt_daily_vehicle_inspection_inspected_by_foreign` (`inspected_by`),
  CONSTRAINT `tpt_daily_vehicle_inspection_driver_id_foreign` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tpt_daily_vehicle_inspection_inspected_by_foreign` FOREIGN KEY (`inspected_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tpt_daily_vehicle_inspection_vehicle_id_foreign` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_daily_vehicle_inspection: ~0 rows (approximately)
DELETE FROM `tpt_daily_vehicle_inspection`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_driver_attendance
CREATE TABLE IF NOT EXISTS `tpt_driver_attendance` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `driver_id` INT unsigned NOT NULL,
  `attendance_date` date NOT NULL,
  `first_in_time` datetime DEFAULT NULL,
  `last_out_time` datetime DEFAULT NULL,
  `total_work_minutes` int DEFAULT NULL,
  `attendance_status` enum('Present','Absent','Half-Day','Late') COLLATE utf8mb4_unicode_ci NOT NULL,
  `via_app` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_driver_day` (`driver_id`),
  CONSTRAINT `tpt_driver_attendance_driver_id_foreign` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_driver_attendance: ~0 rows (approximately)
DELETE FROM `tpt_driver_attendance`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_driver_route_vehicle_jnt
CREATE TABLE IF NOT EXISTS `tpt_driver_route_vehicle_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `shift_id` INT unsigned NOT NULL,
  `route_id` INT unsigned NOT NULL,
  `vehicle_id` INT unsigned NOT NULL,
  `driver_id` INT unsigned NOT NULL,
  `helper_id` INT unsigned DEFAULT NULL,
  `pickup_drop` enum('Pickup','Drop','Both') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Both',
  `effective_from` date NOT NULL,
  `effective_to` date DEFAULT NULL,
  `is_active` tinyint NOT NULL DEFAULT '1',
  `total_students` int NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tpt_driver_route_vehicle_jnt_shift_id_foreign` (`shift_id`),
  KEY `tpt_driver_route_vehicle_jnt_route_id_foreign` (`route_id`),
  KEY `tpt_driver_route_vehicle_jnt_vehicle_id_foreign` (`vehicle_id`),
  KEY `tpt_driver_route_vehicle_jnt_driver_id_foreign` (`driver_id`),
  KEY `tpt_driver_route_vehicle_jnt_helper_id_foreign` (`helper_id`),
  CONSTRAINT `tpt_driver_route_vehicle_jnt_driver_id_foreign` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tpt_driver_route_vehicle_jnt_helper_id_foreign` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tpt_driver_route_vehicle_jnt_route_id_foreign` FOREIGN KEY (`route_id`) REFERENCES `tpt_route` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tpt_driver_route_vehicle_jnt_shift_id_foreign` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tpt_driver_route_vehicle_jnt_vehicle_id_foreign` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_driver_route_vehicle_jnt: ~0 rows (approximately)
DELETE FROM `tpt_driver_route_vehicle_jnt`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_feature_store
CREATE TABLE IF NOT EXISTS `tpt_feature_store` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `feature_date` date NOT NULL,
  `route_id` INT unsigned DEFAULT NULL,
  `vehicle_id` INT unsigned DEFAULT NULL,
  `feature_vector` json NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tpt_feature_store_route_id_foreign` (`route_id`),
  KEY `tpt_feature_store_vehicle_id_foreign` (`vehicle_id`),
  CONSTRAINT `tpt_feature_store_route_id_foreign` FOREIGN KEY (`route_id`) REFERENCES `tpt_route` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tpt_feature_store_vehicle_id_foreign` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_feature_store: ~0 rows (approximately)
DELETE FROM `tpt_feature_store`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_fine_master
CREATE TABLE IF NOT EXISTS `tpt_fine_master` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `std_academic_sessions_id` INT unsigned NOT NULL,
  `fine_from_days` tinyint NOT NULL DEFAULT '0',
  `student_rusticated` tinyint DEFAULT NULL,
  `fine_to_days` tinyint NOT NULL DEFAULT '0',
  `student_restricted` tinyint(1) NOT NULL DEFAULT '0',
  `fine_type` enum('Fixed','Percentage') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Fixed',
  `fine_rate` decimal(5,2) NOT NULL DEFAULT '0.00',
  `remark` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_fine_master: ~0 rows (approximately)
DELETE FROM `tpt_fine_master`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_gps_alerts
CREATE TABLE IF NOT EXISTS `tpt_gps_alerts` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `alert_type` enum('Overspeed','Idle','RouteDeviation','GeofenceBreach') COLLATE utf8mb4_unicode_ci NOT NULL,
  `log_time` datetime NOT NULL,
  `message` varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL,
  `meta` json DEFAULT NULL,
  `vehicle_id` INT unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tpt_gps_alerts_vehicle_id_foreign` (`vehicle_id`),
  CONSTRAINT `tpt_gps_alerts_vehicle_id_foreign` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_gps_alerts: ~0 rows (approximately)
DELETE FROM `tpt_gps_alerts`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_gps_trip_log
CREATE TABLE IF NOT EXISTS `tpt_gps_trip_log` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `log_time` datetime NOT NULL,
  `latitude` decimal(10,6) NOT NULL,
  `longitude` decimal(10,6) NOT NULL,
  `location` geometry DEFAULT NULL,
  `speed` decimal(6,2) DEFAULT NULL,
  `ignition_status` tinyint DEFAULT NULL,
  `deviation_flag` tinyint NOT NULL DEFAULT '0',
  `raw_payload` json DEFAULT NULL,
  `trip_id` INT unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tpt_gps_trip_log_trip_id_foreign` (`trip_id`),
  CONSTRAINT `tpt_gps_trip_log_trip_id_foreign` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_gps_trip_log: ~0 rows (approximately)
DELETE FROM `tpt_gps_trip_log`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_live_trip
CREATE TABLE IF NOT EXISTS `tpt_live_trip` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `trip_id` INT unsigned NOT NULL,
  `current_stop_id` INT unsigned DEFAULT NULL,
  `eta` datetime DEFAULT NULL,
  `reached_flag` tinyint(1) NOT NULL DEFAULT '0',
  `emergency_flag` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tpt_live_trip_trip_id_foreign` (`trip_id`),
  KEY `tpt_live_trip_current_stop_id_foreign` (`current_stop_id`),
  CONSTRAINT `tpt_live_trip_current_stop_id_foreign` FOREIGN KEY (`current_stop_id`) REFERENCES `tpt_pickup_points` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tpt_live_trip_trip_id_foreign` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_live_trip: ~0 rows (approximately)
DELETE FROM `tpt_live_trip`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_model_recommendations
CREATE TABLE IF NOT EXISTS `tpt_model_recommendations` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `model_id` INT unsigned NOT NULL,
  `route_id` INT unsigned DEFAULT NULL,
  `model_version` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `run_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `generated_for_date` date DEFAULT NULL,
  `recommended_path` geometry DEFAULT NULL,
  `predicted_time_minutes` int DEFAULT NULL,
  `predicted_distance_km` decimal(7,2) DEFAULT NULL,
  `confidence` decimal(5,4) DEFAULT NULL,
  `parameters` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tpt_model_recommendations_model_id_foreign` (`model_id`),
  KEY `tpt_model_recommendations_route_id_foreign` (`route_id`),
  CONSTRAINT `tpt_model_recommendations_model_id_foreign` FOREIGN KEY (`model_id`) REFERENCES `ml_models` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tpt_model_recommendations_route_id_foreign` FOREIGN KEY (`route_id`) REFERENCES `tpt_route` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_model_recommendations: ~0 rows (approximately)
DELETE FROM `tpt_model_recommendations`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_notification_log
CREATE TABLE IF NOT EXISTS `tpt_notification_log` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `notification_type` enum('TripStart','ApproachingStop','ReachedStop','Delayed','Cancelled') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sent_time` datetime DEFAULT NULL,
  `status` enum('Sent','Failed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Sent',
  `payload` json DEFAULT NULL,
  `trip_id` INT unsigned DEFAULT NULL,
  `stop_id` INT unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tpt_notification_log_trip_id_foreign` (`trip_id`),
  KEY `tpt_notification_log_stop_id_foreign` (`stop_id`),
  CONSTRAINT `tpt_notification_log_stop_id_foreign` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tpt_notification_log_trip_id_foreign` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_notification_log: ~0 rows (approximately)
DELETE FROM `tpt_notification_log`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_personnel
CREATE TABLE IF NOT EXISTS `tpt_personnel` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `user_id` INT unsigned DEFAULT NULL,
  `user_qr_code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_card_type` enum('QR','RFID','NFC','Barcode') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'QR',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `id_type` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `id_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `license_no` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `license_valid_upto` date DEFAULT NULL,
  `assigned_vehicle_id` INT unsigned DEFAULT NULL,
  `driving_exp_months` smallint unsigned DEFAULT NULL,
  `police_verification_done` tinyint(1) NOT NULL DEFAULT '0',
  `address` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `id_card_upload` tinyint(1) NOT NULL DEFAULT '0',
  `photo_upload` tinyint(1) NOT NULL DEFAULT '0',
  `driving_license_upload` tinyint(1) NOT NULL DEFAULT '0',
  `police_verification_upload` tinyint(1) NOT NULL DEFAULT '0',
  `address_proof_upload` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_personnel_user` (`user_id`),
  KEY `fk_personnel_vehicle` (`assigned_vehicle_id`),
  CONSTRAINT `fk_personnel_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_personnel_vehicle` FOREIGN KEY (`assigned_vehicle_id`) REFERENCES `tpt_vehicle` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_personnel: ~0 rows (approximately)
DELETE FROM `tpt_personnel`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_pickup_points
CREATE TABLE IF NOT EXISTS `tpt_pickup_points` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `shift_id` INT unsigned NOT NULL,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `location` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_distance` decimal(7,2) DEFAULT NULL,
  `estimated_time` int DEFAULT NULL,
  `stop_type` enum('Pickup','Drop','Both') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Both',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pickup_code` (`code`),
  UNIQUE KEY `uq_pickup_name` (`name`),
  KEY `tpt_pickup_points_shift_id_foreign` (`shift_id`),
  CONSTRAINT `tpt_pickup_points_shift_id_foreign` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_pickup_points: ~0 rows (approximately)
DELETE FROM `tpt_pickup_points`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_pickup_points_route_jnt
CREATE TABLE IF NOT EXISTS `tpt_pickup_points_route_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `shift_id` INT unsigned NOT NULL,
  `route_id` INT unsigned NOT NULL,
  `pickup_drop` enum('Pickup','Drop') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Pickup',
  `pickup_point_id` INT unsigned NOT NULL,
  `ordinal` smallint unsigned NOT NULL DEFAULT '1',
  `total_distance` decimal(7,2) DEFAULT NULL,
  `arrival_time` int DEFAULT NULL,
  `departure_time` int DEFAULT NULL,
  `estimated_time` int DEFAULT NULL,
  `pickup_drop_fare` decimal(10,2) DEFAULT NULL,
  `both_side_fare` decimal(10,2) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pickupPointRoute_route_pickupPoint` (`route_id`,`pickup_drop`,`pickup_point_id`),
  KEY `idx_pprj_route_ordinal` (`route_id`,`ordinal`),
  KEY `fk_pickupPointRoute_shiftId` (`shift_id`),
  KEY `fk_pickupPointRoute_pickupPointId` (`pickup_point_id`),
  CONSTRAINT `fk_pickupPointRoute_pickupPointId` FOREIGN KEY (`pickup_point_id`) REFERENCES `tpt_pickup_points` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pickupPointRoute_routeId` FOREIGN KEY (`route_id`) REFERENCES `tpt_route` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pickupPointRoute_shiftId` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_pickup_points_route_jnt: ~0 rows (approximately)
DELETE FROM `tpt_pickup_points_route_jnt`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_recommendation_history
CREATE TABLE IF NOT EXISTS `tpt_recommendation_history` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `applied_at` datetime DEFAULT NULL,
  `applied_by` INT unsigned DEFAULT NULL,
  `recommendation_id` INT unsigned NOT NULL,
  `outcome` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tpt_recommendation_history_recommendation_id_foreign` (`recommendation_id`),
  CONSTRAINT `tpt_recommendation_history_recommendation_id_foreign` FOREIGN KEY (`recommendation_id`) REFERENCES `tpt_model_recommendations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_recommendation_history: ~0 rows (approximately)
DELETE FROM `tpt_recommendation_history`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_route
CREATE TABLE IF NOT EXISTS `tpt_route` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pickup_drop` enum('Pickup','Drop','Both') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Both',
  `shift_id` INT unsigned NOT NULL,
  `route_geometry` varchar(4326) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_route_code` (`code`),
  UNIQUE KEY `uq_route_name` (`name`),
  KEY `tpt_route_shift_id_foreign` (`shift_id`),
  CONSTRAINT `tpt_route_shift_id_foreign` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_route: ~0 rows (approximately)
DELETE FROM `tpt_route`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_route_scheduler_jnt
CREATE TABLE IF NOT EXISTS `tpt_route_scheduler_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `scheduled_date` date NOT NULL,
  `shift_id` INT unsigned NOT NULL,
  `route_id` INT unsigned NOT NULL,
  `vehicle_id` INT unsigned NOT NULL,
  `driver_id` INT unsigned NOT NULL,
  `helper_id` INT unsigned DEFAULT NULL,
  `pickup_drop` enum('Pickup','Drop') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Pickup',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_route_scheduler_schedDate_shift_route` (`scheduled_date`,`shift_id`,`route_id`,`pickup_drop`),
  UNIQUE KEY `uq_route_scheduler_vehicle_schedDate_shift` (`vehicle_id`,`scheduled_date`,`shift_id`,`pickup_drop`),
  UNIQUE KEY `uq_route_scheduler_driver_schedDate_shift` (`driver_id`,`scheduled_date`,`shift_id`,`pickup_drop`),
  UNIQUE KEY `uq_route_scheduler_helper_schedDate_shift` (`helper_id`,`scheduled_date`,`shift_id`,`pickup_drop`),
  KEY `fk_sched_shift` (`shift_id`),
  KEY `fk_sched_route` (`route_id`),
  CONSTRAINT `fk_sched_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sched_helper` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sched_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sched_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sched_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_route_scheduler_jnt: ~0 rows (approximately)
DELETE FROM `tpt_route_scheduler_jnt`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_shift
CREATE TABLE IF NOT EXISTS `tpt_shift` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `effective_from` date NOT NULL,
  `effective_to` date NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tpt_shift_code_unique` (`code`),
  UNIQUE KEY `tpt_shift_name_unique` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_shift: ~0 rows (approximately)
DELETE FROM `tpt_shift`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_student_boarding_log
CREATE TABLE IF NOT EXISTS `tpt_student_boarding_log` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `route_id` INT unsigned DEFAULT NULL,
  `trip_id` INT unsigned DEFAULT NULL,
  `trip_date` date NOT NULL,
  `student_id` INT unsigned DEFAULT NULL,
  `student_session_id` INT unsigned DEFAULT NULL,
  `expected_stop_id` INT unsigned DEFAULT NULL,
  `boarding_stop_id` INT unsigned DEFAULT NULL,
  `boarding_time` datetime DEFAULT NULL,
  `unboarding_stop_id` INT unsigned DEFAULT NULL,
  `unboarding_time` datetime DEFAULT NULL,
  `boarding_sequence` int DEFAULT NULL,
  `unboarding_sequence` int DEFAULT NULL,
  `device_id` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_sel_route` (`route_id`),
  KEY `fk_sel_trip` (`trip_id`),
  KEY `fk_sel_student` (`student_id`),
  KEY `fk_sel_expectedStop` (`expected_stop_id`),
  KEY `fk_sel_boardingStop` (`boarding_stop_id`),
  KEY `fk_sel_unboardingStop` (`unboarding_stop_id`),
  CONSTRAINT `fk_sel_boardingStop` FOREIGN KEY (`boarding_stop_id`) REFERENCES `tpt_pickup_points` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sel_expectedStop` FOREIGN KEY (`expected_stop_id`) REFERENCES `tpt_pickup_points` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sel_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sel_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sel_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sel_unboardingStop` FOREIGN KEY (`unboarding_stop_id`) REFERENCES `tpt_pickup_points` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_student_boarding_log: ~0 rows (approximately)
DELETE FROM `tpt_student_boarding_log`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_student_event_log
CREATE TABLE IF NOT EXISTS `tpt_student_event_log` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `trip_id` INT unsigned NOT NULL,
  `stop_id` INT unsigned DEFAULT NULL,
  `event_type` enum('BOARD','ALIGHT') COLLATE utf8mb4_unicode_ci NOT NULL,
  `recorded_at` datetime NOT NULL,
  `device_id` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tpt_student_event_log_trip_id_foreign` (`trip_id`),
  KEY `tpt_student_event_log_stop_id_foreign` (`stop_id`),
  CONSTRAINT `tpt_student_event_log_stop_id_foreign` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tpt_student_event_log_trip_id_foreign` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_student_event_log: ~0 rows (approximately)
DELETE FROM `tpt_student_event_log`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_student_fee_collection
CREATE TABLE IF NOT EXISTS `tpt_student_fee_collection` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_fee_detail_id` INT unsigned NOT NULL,
  `payment_date` date NOT NULL,
  `total_delay_days` int NOT NULL DEFAULT '0',
  `paid_amount` decimal(10,2) NOT NULL,
  `payment_mode` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reconciled` tinyint(1) NOT NULL DEFAULT '0',
  `remarks` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_fc_fee_detail` (`student_fee_detail_id`),
  CONSTRAINT `fk_fc_fee_detail` FOREIGN KEY (`student_fee_detail_id`) REFERENCES `tpt_student_fee_detail` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_student_fee_collection: ~0 rows (approximately)
DELETE FROM `tpt_student_fee_collection`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_student_fee_detail
CREATE TABLE IF NOT EXISTS `tpt_student_fee_detail` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `std_academic_sessions_id` INT unsigned NOT NULL,
  `month` date NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `due_date` date NOT NULL,
  `fine_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `total_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `remark` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_student_fee_detail: ~0 rows (approximately)
DELETE FROM `tpt_student_fee_detail`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_student_fine_detail
CREATE TABLE IF NOT EXISTS `tpt_student_fine_detail` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_fee_detail_id` INT unsigned NOT NULL,
  `fine_master_id` INT unsigned NOT NULL,
  `fine_days` tinyint NOT NULL DEFAULT '0',
  `fine_type` enum('Fixed','Percentage') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Fixed',
  `fine_rate` decimal(5,2) NOT NULL DEFAULT '0.00',
  `fine_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `waved_fine_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `net_fine_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `remark` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_sf_master` (`student_fee_detail_id`),
  KEY `fk_sf_fine_master` (`fine_master_id`),
  CONSTRAINT `fk_sf_fine_master` FOREIGN KEY (`fine_master_id`) REFERENCES `tpt_fine_master` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sf_master` FOREIGN KEY (`student_fee_detail_id`) REFERENCES `tpt_student_fee_detail` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_student_fine_detail: ~0 rows (approximately)
DELETE FROM `tpt_student_fine_detail`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_student_route_allocation_jnt
CREATE TABLE IF NOT EXISTS `tpt_student_route_allocation_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_session_id` INT unsigned NOT NULL,
  `student_id` INT unsigned NOT NULL,
  `pickup_route_id` INT unsigned NOT NULL,
  `pickup_stop_id` INT unsigned NOT NULL,
  `drop_route_id` INT unsigned NOT NULL,
  `drop_stop_id` INT unsigned NOT NULL,
  `fare` decimal(10,2) NOT NULL,
  `effective_from` date NOT NULL,
  `active_status` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_sa_pickup_route` (`pickup_route_id`),
  KEY `fk_sa_drop_route` (`drop_route_id`),
  KEY `fk_sa_pickup` (`pickup_stop_id`),
  KEY `fk_sa_drop` (`drop_stop_id`),
  CONSTRAINT `fk_sa_drop` FOREIGN KEY (`drop_stop_id`) REFERENCES `tpt_pickup_points` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sa_drop_route` FOREIGN KEY (`drop_route_id`) REFERENCES `tpt_route` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sa_pickup` FOREIGN KEY (`pickup_stop_id`) REFERENCES `tpt_pickup_points` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sa_pickup_route` FOREIGN KEY (`pickup_route_id`) REFERENCES `tpt_route` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_student_route_allocation_jnt: ~0 rows (approximately)
DELETE FROM `tpt_student_route_allocation_jnt`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_trip
CREATE TABLE IF NOT EXISTS `tpt_trip` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `trip_date` date NOT NULL,
  `route_scheduler_id` INT unsigned NOT NULL,
  `route_id` INT unsigned NOT NULL,
  `vehicle_id` INT unsigned NOT NULL,
  `driver_id` INT unsigned NOT NULL,
  `helper_id` INT unsigned DEFAULT NULL,
  `trip_type` INT unsigned DEFAULT NULL,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `start_odometer_reading` decimal(11,2) NOT NULL DEFAULT '0.00',
  `end_odometer_reading` decimal(11,2) NOT NULL DEFAULT '0.00',
  `start_fuel_reading` decimal(8,3) NOT NULL DEFAULT '0.000',
  `end_fuel_reading` decimal(8,3) NOT NULL DEFAULT '0.000',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Scheduled',
  `approved` tinyint(1) NOT NULL DEFAULT '0',
  `approved_by` INT unsigned DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `remarks` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_trip_routeSched_tripDate` (`route_scheduler_id`,`trip_date`),
  KEY `idx_trip_route` (`route_id`),
  KEY `idx_trip_vehicle` (`vehicle_id`),
  KEY `idx_trip_driver` (`driver_id`),
  KEY `fk_trip_helper` (`helper_id`),
  KEY `fk_trip_approved_by` (`approved_by`),
  KEY `fk_trip_shift` (`trip_type`),
  CONSTRAINT `fk_trip_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_trip_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_trip_helper` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_trip_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_trip_route_scheduler` FOREIGN KEY (`route_scheduler_id`) REFERENCES `tpt_route_scheduler_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_trip_shift` FOREIGN KEY (`trip_type`) REFERENCES `tpt_shift` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_trip_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_trip: ~0 rows (approximately)
DELETE FROM `tpt_trip`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_trip_incidents
CREATE TABLE IF NOT EXISTS `tpt_trip_incidents` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `trip_id` INT unsigned NOT NULL,
  `incident_time` timestamp NOT NULL,
  `incident_type` INT unsigned NOT NULL,
  `severity` enum('LOW','MEDIUM','HIGH') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'MEDIUM',
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `description` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` INT unsigned DEFAULT NULL,
  `raised_by` INT unsigned DEFAULT NULL,
  `raised_at` timestamp NULL DEFAULT NULL,
  `resolved_at` timestamp NULL DEFAULT NULL,
  `resolved_by` INT unsigned DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_ti_trip` (`trip_id`),
  KEY `fk_ti_raisedBy` (`raised_by`),
  KEY `fk_ti_resolvedBy` (`resolved_by`),
  CONSTRAINT `fk_ti_raisedBy` FOREIGN KEY (`raised_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ti_resolvedBy` FOREIGN KEY (`resolved_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ti_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_trip_incidents: ~0 rows (approximately)
DELETE FROM `tpt_trip_incidents`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_trip_stop_detail
CREATE TABLE IF NOT EXISTS `tpt_trip_stop_detail` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `trip_id` INT unsigned NOT NULL,
  `stop_id` INT unsigned DEFAULT NULL,
  `pickup_drop` enum('Pickup','Drop') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Pickup',
  `sch_arrival_time` datetime DEFAULT NULL,
  `sch_departure_time` datetime DEFAULT NULL,
  `reached_flag` tinyint(1) NOT NULL DEFAULT '0',
  `reaching_time` timestamp NULL DEFAULT NULL,
  `leaving_time` timestamp NULL DEFAULT NULL,
  `emergency_flag` tinyint(1) NOT NULL DEFAULT '0',
  `emergency_time` timestamp NULL DEFAULT NULL,
  `emergency_remarks` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `updated_by` INT unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tpt_trip_stop_detail_trip_id_foreign` (`trip_id`),
  KEY `tpt_trip_stop_detail_stop_id_foreign` (`stop_id`),
  KEY `tpt_trip_stop_detail_updated_by_foreign` (`updated_by`),
  CONSTRAINT `tpt_trip_stop_detail_stop_id_foreign` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tpt_trip_stop_detail_trip_id_foreign` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tpt_trip_stop_detail_updated_by_foreign` FOREIGN KEY (`updated_by`) REFERENCES `tpt_personnel` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_trip_stop_detail: ~0 rows (approximately)
DELETE FROM `tpt_trip_stop_detail`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_vehicle
CREATE TABLE IF NOT EXISTS `tpt_vehicle` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `vehicle_no` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `registration_no` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `model` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `manufacturer` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `vehicle_type_id` INT unsigned NOT NULL,
  `fuel_type_id` INT unsigned NOT NULL,
  `capacity` int unsigned NOT NULL DEFAULT '40',
  `max_capacity` int unsigned NOT NULL DEFAULT '40',
  `ownership_type_id` INT unsigned NOT NULL,
  `vendor_id` INT unsigned DEFAULT NULL,
  `fitness_valid_upto` date DEFAULT NULL,
  `insurance_valid_upto` date DEFAULT NULL,
  `pollution_valid_upto` date DEFAULT NULL,
  `vehicle_emission_class_id` INT unsigned NOT NULL,
  `fire_extinguisher_valid_upto` date DEFAULT NULL,
  `gps_device_id` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `vehicle_photo_upload` tinyint(1) NOT NULL DEFAULT '0',
  `registration_cert_upload` tinyint(1) NOT NULL DEFAULT '0',
  `fitness_cert_upload` tinyint(1) NOT NULL DEFAULT '0',
  `insurance_cert_upload` tinyint(1) NOT NULL DEFAULT '0',
  `pollution_cert_upload` tinyint(1) NOT NULL DEFAULT '0',
  `vehicle_emission_cert_upload` tinyint(1) NOT NULL DEFAULT '0',
  `fire_extinguisher_cert_upload` tinyint(1) NOT NULL DEFAULT '0',
  `gps_device_cert_upload` tinyint(1) NOT NULL DEFAULT '0',
  `availability_status` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_vehicle_vehicleNo` (`vehicle_no`),
  UNIQUE KEY `uq_vehicle_registration_no` (`registration_no`),
  KEY `fk_vehicle_vehicle_type` (`vehicle_type_id`),
  KEY `fk_vehicle_fuel_type` (`fuel_type_id`),
  KEY `fk_vehicle_ownership_type` (`ownership_type_id`),
  KEY `fk_vehicle_vehicle_emission_class` (`vehicle_emission_class_id`),
  CONSTRAINT `fk_vehicle_fuel_type` FOREIGN KEY (`fuel_type_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_vehicle_ownership_type` FOREIGN KEY (`ownership_type_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_vehicle_vehicle_emission_class` FOREIGN KEY (`vehicle_emission_class_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_vehicle_vehicle_type` FOREIGN KEY (`vehicle_type_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_vehicle: ~0 rows (approximately)
DELETE FROM `tpt_vehicle`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_vehicle_fuel
CREATE TABLE IF NOT EXISTS `tpt_vehicle_fuel` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `vehicle_id` INT unsigned NOT NULL,
  `driver_id` INT unsigned DEFAULT NULL,
  `date` date NOT NULL,
  `quantity` decimal(10,3) NOT NULL,
  `cost` decimal(12,2) NOT NULL,
  `fuel_type` INT unsigned NOT NULL,
  `odometer_reading` INT unsigned DEFAULT NULL,
  `remarks` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('Approved','Pending','Rejected') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Pending',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_vfl_vehicle` (`vehicle_id`),
  KEY `fk_vfl_driver` (`driver_id`),
  CONSTRAINT `fk_vfl_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_vfl_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_vehicle_fuel: ~0 rows (approximately)
DELETE FROM `tpt_vehicle_fuel`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_vehicle_maintenance
CREATE TABLE IF NOT EXISTS `tpt_vehicle_maintenance` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `vehicle_service_request_id` INT unsigned NOT NULL,
  `maintenance_initiation_date` date NOT NULL,
  `maintenance_type` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cost` decimal(12,2) NOT NULL,
  `in_service_date` date DEFAULT NULL,
  `out_service_date` date DEFAULT NULL,
  `workshop_details` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `next_due_date` date DEFAULT NULL,
  `remarks` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('Approved','Pending','Rejected') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Pending',
  `approved_by` INT unsigned DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tpt_vehicle_maintenance_vehicle_service_request_id_foreign` (`vehicle_service_request_id`),
  KEY `tpt_vehicle_maintenance_approved_by_foreign` (`approved_by`),
  CONSTRAINT `tpt_vehicle_maintenance_approved_by_foreign` FOREIGN KEY (`approved_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tpt_vehicle_maintenance_vehicle_service_request_id_foreign` FOREIGN KEY (`vehicle_service_request_id`) REFERENCES `tpt_vehicle_service_request` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_vehicle_maintenance: ~0 rows (approximately)
DELETE FROM `tpt_vehicle_maintenance`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_vehicle_service_request
CREATE TABLE IF NOT EXISTS `tpt_vehicle_service_request` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `vehicle_inspection_id` INT unsigned NOT NULL,
  `approved_by` INT unsigned DEFAULT NULL,
  `vehicle_status` INT unsigned DEFAULT NULL,
  `request_date` timestamp NOT NULL,
  `reason` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `service_completion_date` timestamp NULL DEFAULT NULL,
  `request_approval_status` enum('Approved','Pending','Rejected') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Pending',
  `approved_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tpt_vehicle_service_request_vehicle_inspection_id_foreign` (`vehicle_inspection_id`),
  KEY `tpt_vehicle_service_request_approved_by_foreign` (`approved_by`),
  CONSTRAINT `tpt_vehicle_service_request_approved_by_foreign` FOREIGN KEY (`approved_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tpt_vehicle_service_request_vehicle_inspection_id_foreign` FOREIGN KEY (`vehicle_inspection_id`) REFERENCES `tpt_daily_vehicle_inspection` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tpt_vehicle_service_request: ~0 rows (approximately)
DELETE FROM `tpt_vehicle_service_request`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tt_days
CREATE TABLE IF NOT EXISTS `tt_days` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `label` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ordinal` int unsigned NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tt_days: ~0 rows (approximately)
DELETE FROM `tt_days`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tt_periods
CREATE TABLE IF NOT EXISTS `tt_periods` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `label` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ordinal` int unsigned NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tt_periods: ~0 rows (approximately)
DELETE FROM `tt_periods`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tt_room_unavailables
CREATE TABLE IF NOT EXISTS `tt_room_unavailables` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `room_id` INT unsigned NOT NULL,
  `day_id` INT unsigned NOT NULL,
  `period_id` INT unsigned NOT NULL,
  `date_from` date DEFAULT NULL,
  `date_to` date DEFAULT NULL,
  `reason` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tt_room_unavailables_room_id_foreign` (`room_id`),
  KEY `tt_room_unavailables_day_id_foreign` (`day_id`),
  KEY `tt_room_unavailables_period_id_foreign` (`period_id`),
  CONSTRAINT `tt_room_unavailables_day_id_foreign` FOREIGN KEY (`day_id`) REFERENCES `tt_days` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_room_unavailables_period_id_foreign` FOREIGN KEY (`period_id`) REFERENCES `tt_periods` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_room_unavailables_room_id_foreign` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tt_room_unavailables: ~0 rows (approximately)
DELETE FROM `tt_room_unavailables`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tt_timing_profile
CREATE TABLE IF NOT EXISTS `tt_timing_profile` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `profile_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_periods` int unsigned NOT NULL,
  `timezone` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tt_timing_profile_profile_code_unique` (`profile_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.tt_timing_profile: ~0 rows (approximately)
DELETE FROM `tt_timing_profile`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.vnd_agreements
CREATE TABLE IF NOT EXISTS `vnd_agreements` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` INT unsigned NOT NULL,
  `agreement_ref_no` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `status` enum('DRAFT','ACTIVE','EXPIRED','TERMINATED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `billing_cycle` enum('MONTHLY','ONE_TIME','ON_DEMAND') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'MONTHLY',
  `payment_terms_days` int unsigned NOT NULL DEFAULT '30',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `agreement_uploaded` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `vnd_agreements_vendor_id_foreign` (`vendor_id`),
  CONSTRAINT `vnd_agreements_vendor_id_foreign` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.vnd_agreements: ~0 rows (approximately)
DELETE FROM `vnd_agreements`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.vnd_agreement_items_jnt
CREATE TABLE IF NOT EXISTS `vnd_agreement_items_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `agreement_id` INT unsigned NOT NULL,
  `item_id` INT unsigned NOT NULL,
  `billing_model` enum('FIXED','PER_UNIT','HYBRID') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'FIXED',
  `fixed_charge` decimal(12,2) NOT NULL DEFAULT '0.00',
  `unit_rate` decimal(10,2) NOT NULL DEFAULT '0.00',
  `min_guarantee_qty` decimal(10,2) NOT NULL DEFAULT '0.00',
  `tax1_percent` decimal(5,2) NOT NULL DEFAULT '0.00',
  `tax2_percent` decimal(5,2) NOT NULL DEFAULT '0.00',
  `tax3_percent` decimal(5,2) NOT NULL DEFAULT '0.00',
  `tax4_percent` decimal(5,2) NOT NULL DEFAULT '0.00',
  `related_entity_type` INT unsigned DEFAULT NULL,
  `related_entity_table` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `related_entity_id` INT unsigned DEFAULT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_vnd_agr_items_agreement` (`agreement_id`),
  KEY `fk_vnd_agr_items_item` (`item_id`),
  KEY `fk_vnd_agr_items_entity_type` (`related_entity_type`),
  CONSTRAINT `fk_vnd_agr_items_agreement` FOREIGN KEY (`agreement_id`) REFERENCES `vnd_agreements` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_vnd_agr_items_entity_type` FOREIGN KEY (`related_entity_type`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_vnd_agr_items_item` FOREIGN KEY (`item_id`) REFERENCES `vnd_items` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.vnd_agreement_items_jnt: ~0 rows (approximately)
DELETE FROM `vnd_agreement_items_jnt`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.vnd_invoices
CREATE TABLE IF NOT EXISTS `vnd_invoices` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` INT unsigned NOT NULL,
  `agreement_id` INT unsigned DEFAULT NULL,
  `agreement_item_id` INT unsigned DEFAULT NULL,
  `item_description` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `invoice_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `invoice_date` date NOT NULL,
  `billing_start_date` date DEFAULT NULL,
  `billing_end_date` date DEFAULT NULL,
  `fixed_charge_amt` decimal(12,2) NOT NULL DEFAULT '0.00',
  `unit_charge_amt` decimal(12,2) NOT NULL DEFAULT '0.00',
  `qty_used` decimal(10,2) NOT NULL DEFAULT '0.00',
  `unit_rate` decimal(10,2) NOT NULL DEFAULT '0.00',
  `min_guarantee_qty` decimal(10,2) NOT NULL DEFAULT '0.00',
  `tax1_percent` decimal(5,2) NOT NULL DEFAULT '0.00',
  `tax2_percent` decimal(5,2) NOT NULL DEFAULT '0.00',
  `tax3_percent` decimal(5,2) NOT NULL DEFAULT '0.00',
  `tax4_percent` decimal(5,2) NOT NULL DEFAULT '0.00',
  `sub_total` decimal(12,2) NOT NULL DEFAULT '0.00',
  `tax_total` decimal(12,2) NOT NULL DEFAULT '0.00',
  `other_charges` decimal(12,2) NOT NULL DEFAULT '0.00',
  `discount_amount` decimal(12,2) NOT NULL DEFAULT '0.00',
  `net_payable` decimal(12,2) NOT NULL,
  `amount_paid` decimal(12,2) NOT NULL DEFAULT '0.00',
  `balance_due` decimal(12,2) GENERATED ALWAYS AS ((`net_payable` - `amount_paid`)) STORED,
  `due_date` date DEFAULT NULL,
  `status` INT unsigned NOT NULL,
  `remarks` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_vnd_invoice_no` (`vendor_id`,`invoice_number`),
  KEY `fk_vnd_inv_agreement` (`agreement_id`),
  KEY `fk_vnd_inv_agreement_item` (`agreement_item_id`),
  KEY `fk_vnd_inv_status` (`status`),
  CONSTRAINT `fk_vnd_inv_agreement` FOREIGN KEY (`agreement_id`) REFERENCES `vnd_agreements` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_vnd_inv_agreement_item` FOREIGN KEY (`agreement_item_id`) REFERENCES `vnd_agreement_items_jnt` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_vnd_inv_status` FOREIGN KEY (`status`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_vnd_inv_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.vnd_invoices: ~0 rows (approximately)
DELETE FROM `vnd_invoices`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.vnd_items
CREATE TABLE IF NOT EXISTS `vnd_items` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `item_code` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'SKU or Internal Item Code (Barcode printable)',
  `item_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_type` enum('SERVICE','PRODUCT') COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_nature` enum('CONSUMABLE','ASSET','SERVICE','NA') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'NA' COMMENT 'Inventory hook',
  `category_id` INT unsigned NOT NULL COMMENT 'FK to sys_dropdown_table',
  `unit_id` INT unsigned NOT NULL COMMENT 'FK to sys_dropdown_table',
  `hsn_sac_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `default_price` decimal(12,2) NOT NULL DEFAULT '0.00',
  `reorder_level` decimal(12,2) NOT NULL DEFAULT '0.00',
  `item_photo_uploaded` tinyint(1) NOT NULL DEFAULT '0',
  `description` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_vnd_items_code` (`item_code`),
  KEY `idx_vnd_items_type` (`item_type`),
  KEY `fk_vnd_items_category` (`category_id`),
  KEY `fk_vnd_items_unit` (`unit_id`),
  CONSTRAINT `fk_vnd_items_category` FOREIGN KEY (`category_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_vnd_items_unit` FOREIGN KEY (`unit_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.vnd_items: ~0 rows (approximately)
DELETE FROM `vnd_items`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.vnd_payments
CREATE TABLE IF NOT EXISTS `vnd_payments` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` INT unsigned NOT NULL,
  `invoice_id` INT unsigned NOT NULL,
  `payment_date` date NOT NULL,
  `amount` decimal(14,2) NOT NULL,
  `payment_mode` INT unsigned NOT NULL,
  `reference_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('INITIATED','SUCCESS','FAILED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'SUCCESS',
  `paid_by` INT unsigned DEFAULT NULL,
  `reconciled` tinyint unsigned NOT NULL DEFAULT '0',
  `reconciled_by` INT unsigned DEFAULT NULL,
  `reconciled_at` timestamp NULL DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `is_deleted` tinyint unsigned NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_vnd_pay_invoice` (`invoice_id`),
  KEY `fk_vnd_pay_vendor` (`vendor_id`),
  KEY `fk_vnd_pay_mode` (`payment_mode`),
  CONSTRAINT `fk_vnd_pay_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `vnd_invoices` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_vnd_pay_mode` FOREIGN KEY (`payment_mode`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_vnd_pay_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.vnd_payments: ~0 rows (approximately)
DELETE FROM `vnd_payments`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.vnd_usage_logs
CREATE TABLE IF NOT EXISTS `vnd_usage_logs` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `vendor_id` INT unsigned NOT NULL,
  `agreement_item_id` INT unsigned DEFAULT NULL,
  `usage_date` date NOT NULL,
  `qty_used` decimal(10,2) NOT NULL DEFAULT '0.00',
  `remarks` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `logged_by` INT unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `vnd_usage_logs_vendor_id_foreign` (`vendor_id`),
  KEY `vnd_usage_logs_agreement_item_id_foreign` (`agreement_item_id`),
  CONSTRAINT `vnd_usage_logs_agreement_item_id_foreign` FOREIGN KEY (`agreement_item_id`) REFERENCES `vnd_agreement_items_jnt` (`id`) ON DELETE SET NULL,
  CONSTRAINT `vnd_usage_logs_vendor_id_foreign` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.vnd_usage_logs: ~0 rows (approximately)
DELETE FROM `vnd_usage_logs`;

-- Dumping structure for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.vnd_vendors
CREATE TABLE IF NOT EXISTS `vnd_vendors` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `vendor_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vendor_type_id` INT unsigned NOT NULL,
  `contact_person` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contact_number` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gst_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pan_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_account_no` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_ifsc_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_branch` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `upi_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vnd_vendors_vendor_name_unique` (`vendor_name`),
  KEY `vnd_vendors_vendor_type_id_index` (`vendor_type_id`),
  CONSTRAINT `vnd_vendors_vendor_type_id_foreign` FOREIGN KEY (`vendor_type_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.vnd_vendors: ~0 rows (approximately)
DELETE FROM `vnd_vendors`;

-- Dumping structure for trigger tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.trg_users_prevent_delete_super
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `trg_users_prevent_delete_super` BEFORE DELETE ON `sys_users` FOR EACH ROW BEGIN
                IF OLD.is_super_admin = 1 THEN
                    SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Super Admin cannot be deleted';
                END IF;
            END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.trg_users_prevent_update_super
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `trg_users_prevent_update_super` BEFORE UPDATE ON `sys_users` FOR EACH ROW BEGIN
                IF OLD.is_super_admin = 1 AND NEW.is_super_admin = 0 THEN
                    SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Super Admin cannot be demoted';
                END IF;
            END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_cities
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `glb_cities`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `glb_cities` AS select `global_master`.`glb_cities`.`id` AS `id`,`global_master`.`glb_cities`.`district_id` AS `district_id`,`global_master`.`glb_cities`.`name` AS `name`,`global_master`.`glb_cities`.`short_name` AS `short_name`,`global_master`.`glb_cities`.`global_code` AS `global_code`,`global_master`.`glb_cities`.`default_timezone` AS `default_timezone`,`global_master`.`glb_cities`.`is_active` AS `is_active`,`global_master`.`glb_cities`.`created_at` AS `created_at`,`global_master`.`glb_cities`.`updated_at` AS `updated_at`,`global_master`.`glb_cities`.`deleted_at` AS `deleted_at` from `global_master`.`glb_cities`;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_countries
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `glb_countries`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `glb_countries` AS select `global_master`.`glb_countries`.`id` AS `id`,`global_master`.`glb_countries`.`name` AS `name`,`global_master`.`glb_countries`.`short_name` AS `short_name`,`global_master`.`glb_countries`.`global_code` AS `global_code`,`global_master`.`glb_countries`.`currency_code` AS `currency_code`,`global_master`.`glb_countries`.`is_active` AS `is_active`,`global_master`.`glb_countries`.`created_at` AS `created_at`,`global_master`.`glb_countries`.`updated_at` AS `updated_at`,`global_master`.`glb_countries`.`deleted_at` AS `deleted_at` from `global_master`.`glb_countries`;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_districts
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `glb_districts`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `glb_districts` AS select `global_master`.`glb_districts`.`id` AS `id`,`global_master`.`glb_districts`.`state_id` AS `state_id`,`global_master`.`glb_districts`.`name` AS `name`,`global_master`.`glb_districts`.`short_name` AS `short_name`,`global_master`.`glb_districts`.`global_code` AS `global_code`,`global_master`.`glb_districts`.`is_active` AS `is_active`,`global_master`.`glb_districts`.`created_at` AS `created_at`,`global_master`.`glb_districts`.`updated_at` AS `updated_at`,`global_master`.`glb_districts`.`deleted_at` AS `deleted_at` from `global_master`.`glb_districts`;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_languages
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `glb_languages`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `glb_languages` AS select `global_master`.`glb_languages`.`id` AS `id`,`global_master`.`glb_languages`.`code` AS `code`,`global_master`.`glb_languages`.`name` AS `name`,`global_master`.`glb_languages`.`native_name` AS `native_name`,`global_master`.`glb_languages`.`direction` AS `direction`,`global_master`.`glb_languages`.`is_active` AS `is_active`,`global_master`.`glb_languages`.`deleted_at` AS `deleted_at`,`global_master`.`glb_languages`.`created_at` AS `created_at`,`global_master`.`glb_languages`.`updated_at` AS `updated_at` from `global_master`.`glb_languages`;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_menus
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `glb_menus`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `glb_menus` AS select `global_master`.`glb_menus`.`id` AS `id`,`global_master`.`glb_menus`.`parent_id` AS `parent_id`,`global_master`.`glb_menus`.`is_category` AS `is_category`,`global_master`.`glb_menus`.`code` AS `code`,`global_master`.`glb_menus`.`menu_for` AS `menu_for`,`global_master`.`glb_menus`.`slug` AS `slug`,`global_master`.`glb_menus`.`title` AS `title`,`global_master`.`glb_menus`.`description` AS `description`,`global_master`.`glb_menus`.`icon` AS `icon`,`global_master`.`glb_menus`.`route` AS `route`,`global_master`.`glb_menus`.`permission` AS `permission`,`global_master`.`glb_menus`.`sort_order` AS `sort_order`,`global_master`.`glb_menus`.`visible_by_default` AS `visible_by_default`,`global_master`.`glb_menus`.`is_active` AS `is_active`,`global_master`.`glb_menus`.`deleted_at` AS `deleted_at`,`global_master`.`glb_menus`.`created_at` AS `created_at`,`global_master`.`glb_menus`.`updated_at` AS `updated_at` from `global_master`.`glb_menus`;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_menu_module_jnt
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `glb_menu_module_jnt`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `glb_menu_module_jnt` AS select `global_master`.`glb_menu_module_jnt`.`id` AS `id`,`global_master`.`glb_menu_module_jnt`.`menu_id` AS `menu_id`,`global_master`.`glb_menu_module_jnt`.`module_id` AS `module_id`,`global_master`.`glb_menu_module_jnt`.`sort_order` AS `sort_order`,`global_master`.`glb_menu_module_jnt`.`created_at` AS `created_at`,`global_master`.`glb_menu_module_jnt`.`updated_at` AS `updated_at` from `global_master`.`glb_menu_module_jnt`;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_modules
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `glb_modules`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `glb_modules` AS select `global_master`.`glb_modules`.`id` AS `id`,`global_master`.`glb_modules`.`parent_id` AS `parent_id`,`global_master`.`glb_modules`.`name` AS `name`,`global_master`.`glb_modules`.`version` AS `version`,`global_master`.`glb_modules`.`is_sub_module` AS `is_sub_module`,`global_master`.`glb_modules`.`description` AS `description`,`global_master`.`glb_modules`.`is_core` AS `is_core`,`global_master`.`glb_modules`.`default_visible` AS `default_visible`,`global_master`.`glb_modules`.`available_perm_view` AS `available_perm_view`,`global_master`.`glb_modules`.`available_perm_add` AS `available_perm_add`,`global_master`.`glb_modules`.`available_perm_edit` AS `available_perm_edit`,`global_master`.`glb_modules`.`available_perm_delete` AS `available_perm_delete`,`global_master`.`glb_modules`.`available_perm_export` AS `available_perm_export`,`global_master`.`glb_modules`.`available_perm_import` AS `available_perm_import`,`global_master`.`glb_modules`.`available_perm_print` AS `available_perm_print`,`global_master`.`glb_modules`.`is_active` AS `is_active`,`global_master`.`glb_modules`.`deleted_at` AS `deleted_at`,`global_master`.`glb_modules`.`created_at` AS `created_at`,`global_master`.`glb_modules`.`updated_at` AS `updated_at` from `global_master`.`glb_modules`;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_states
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `glb_states`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `glb_states` AS select `global_master`.`glb_states`.`id` AS `id`,`global_master`.`glb_states`.`country_id` AS `country_id`,`global_master`.`glb_states`.`name` AS `name`,`global_master`.`glb_states`.`short_name` AS `short_name`,`global_master`.`glb_states`.`global_code` AS `global_code`,`global_master`.`glb_states`.`is_active` AS `is_active`,`global_master`.`glb_states`.`created_at` AS `created_at`,`global_master`.`glb_states`.`updated_at` AS `updated_at`,`global_master`.`glb_states`.`deleted_at` AS `deleted_at` from `global_master`.`glb_states`;

-- Dumping structure for view tenant_b18c29eb-0e01-4f13-93e1-4418e239a4d3.glb_translations
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `glb_translations`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `glb_translations` AS select `global_master`.`glb_translations`.`id` AS `id`,`global_master`.`glb_translations`.`translatable_type` AS `translatable_type`,`global_master`.`glb_translations`.`translatable_id` AS `translatable_id`,`global_master`.`glb_translations`.`language_id` AS `language_id`,`global_master`.`glb_translations`.`key` AS `key`,`global_master`.`glb_translations`.`value` AS `value`,`global_master`.`glb_translations`.`created_at` AS `created_at`,`global_master`.`glb_translations`.`updated_at` AS `updated_at` from `global_master`.`glb_translations`;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
