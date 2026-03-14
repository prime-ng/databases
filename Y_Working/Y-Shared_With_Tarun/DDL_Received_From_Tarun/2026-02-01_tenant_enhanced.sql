-- MySQL dump 10.13  Distrib 8.0.44, for Linux (x86_64)
-- Host: localhost    Database: tenant_51b5ee16-d582-4568-ab8f-d4137106c752
-- ================================================================================
-- Server version	8.0.44-0ubuntu0.22.04.2
-- ================================================================================
-- Enhanced - Removed everything else other than Table Schema (Tables - 210)
-- ================================================================================
-- tables Needs to be Removed
-- slb_book_topic_mapping
-- bok_books
-- 
-- ================================================================================
-- Check - Most probably Need to be Removed 
-- ================================================================================
-- (Created in slb Modue - slb_book_topic_mapping)
CREATE TABLE `bok_book_topic_mapping` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `book_id` INT unsigned NOT NULL,
  `topic_id` INT unsigned NOT NULL,
  `chapter_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `chapter_title` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `page_start` int unsigned DEFAULT NULL,
  `page_end` int unsigned DEFAULT NULL,
  `section_reference` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_btm_book` (`book_id`),
  KEY `idx_btm_topic` (`topic_id`),
  CONSTRAINT `bok_book_topic_mapping_book_id_foreign` FOREIGN KEY (`book_id`) REFERENCES `bok_books` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `bok_book_topic_mapping_topic_id_foreign` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Need to Removed (Created in slb Modue - slb_book)
CREATE TABLE `bok_books` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varbinary(16) NOT NULL,
  `isbn` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'International Standard Book Number',
  `title` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subtitle` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `edition` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. 5th Edition, Revised 2024',
  `publication_year` year DEFAULT NULL,
  `publisher_name` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `language` INT unsigned NOT NULL,
  `total_pages` int unsigned DEFAULT NULL,
  `cover_image_media_id` INT unsigned DEFAULT NULL,
  `tags` json DEFAULT NULL,
  `is_ncert` tinyint(1) NOT NULL DEFAULT '0',
  `is_cbse_recommended` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_book_uuid` (`uuid`),
  UNIQUE KEY `uq_book_isbn` (`isbn`),
  KEY `bok_books_language_foreign` (`language`),
  KEY `bok_books_cover_image_media_id_foreign` (`cover_image_media_id`),
  KEY `idx_book_title` (`title`),
  KEY `idx_book_publisher` (`publisher_name`),
  KEY `idx_book_year` (`publication_year`),
  CONSTRAINT `bok_books_cover_image_media_id_foreign` FOREIGN KEY (`cover_image_media_id`) REFERENCES `media_files` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `bok_books_language_foreign` FOREIGN KEY (`language`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `subject_group_subject` (
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

CREATE TABLE `school_timing_profiles` (
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

CREATE TABLE `media_files` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `file_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `file_path` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mime_type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `file_size` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ml_model_features` (
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

CREATE TABLE `ml_models` (
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

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------

-- ================================================================================
-- Module - System (No Prefix)
-- ================================================================================

CREATE TABLE `cache` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` int NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `cache_locks` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `owner` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` int NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `failed_jobs` (
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

CREATE TABLE `job_batches` (
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

CREATE TABLE `jobs` (
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

CREATE TABLE `migrations` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=204 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `personal_access_tokens` (
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

CREATE TABLE `schedule_runs` (
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

CREATE TABLE `schedules` (
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

CREATE TABLE `sessions` (
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

CREATE TABLE `notifications` (
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

-- ================================================================================
-- Module - Complaint (cmp)
-- ================================================================================

CREATE TABLE `cmp_ai_insights` (
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

CREATE TABLE `cmp_complaint_actions` (
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

CREATE TABLE `cmp_complaint_categories` (
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

CREATE TABLE `cmp_complaints` (
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

CREATE TABLE `cmp_department_sla` (
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

CREATE TABLE `cmp_medical_checks` (
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

-- ================================================================================
-- Module - Complaint (cmp)
-- ================================================================================

CREATE TABLE `hpc_ability_parameters` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hpc_param_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `hpc_circular_goal_competency_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `circular_goal_id` INT unsigned NOT NULL,
  `competency_id` INT unsigned NOT NULL,
  `is_primary` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cg_comp` (`circular_goal_id`,`competency_id`),
  KEY `hpc_circular_goal_competency_jnt_competency_id_foreign` (`competency_id`),
  CONSTRAINT `hpc_circular_goal_competency_jnt_circular_goal_id_foreign` FOREIGN KEY (`circular_goal_id`) REFERENCES `hpc_circular_goals` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `hpc_circular_goal_competency_jnt_competency_id_foreign` FOREIGN KEY (`competency_id`) REFERENCES `slb_competencies` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `hpc_circular_goals` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `class_id` INT unsigned NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `nep_reference` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cg_code` (`code`),
  KEY `hpc_circular_goals_class_id_foreign` (`class_id`),
  CONSTRAINT `hpc_circular_goals_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `hpc_hpc_levels` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ordinal` tinyint unsigned NOT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hpc_level_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `hpc_knowledge_graph_validation` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `topic_id` INT unsigned NOT NULL,
  `issue_type` enum('NO_COMPETENCY','NO_OUTCOME','NO_WEIGHTAGE','ORPHAN_NODE') COLLATE utf8mb4_unicode_ci NOT NULL,
  `severity` enum('LOW','MEDIUM','HIGH','CRITICAL') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'LOW',
  `detected_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_resolved` tinyint(1) NOT NULL DEFAULT '0',
  `resolved_at` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `hpc_knowledge_graph_validation_topic_id_foreign` (`topic_id`),
  CONSTRAINT `hpc_knowledge_graph_validation_topic_id_foreign` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `hpc_learning_activities` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `topic_id` INT unsigned NOT NULL,
  `activity_type_id` INT unsigned NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `expected_outcome` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `hpc_learning_activities_topic_id_foreign` (`topic_id`),
  KEY `hpc_learning_activities_activity_type_id_foreign` (`activity_type_id`),
  CONSTRAINT `hpc_learning_activities_activity_type_id_foreign` FOREIGN KEY (`activity_type_id`) REFERENCES `hpc_learning_activity_type` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `hpc_learning_activities_topic_id_foreign` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `hpc_learning_activity_type` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hpc_activity_type_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `hpc_learning_outcomes` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `hpc_outcome_entity_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `outcome_id` INT unsigned NOT NULL,
  `class_id` int unsigned NOT NULL,
  `entity_type` enum('SUBJECT','LESSON','TOPIC') COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_id` INT unsigned NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_outcome_entity` (`outcome_id`,`entity_type`,`entity_id`),
  CONSTRAINT `hpc_outcome_entity_jnt_outcome_id_foreign` FOREIGN KEY (`outcome_id`) REFERENCES `hpc_learning_outcomes` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `hpc_outcome_question_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `outcome_id` INT unsigned NOT NULL,
  `question_id` INT unsigned NOT NULL,
  `weightage` decimal(5,2) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_outcome_question` (`outcome_id`,`question_id`),
  KEY `hpc_outcome_question_jnt_question_id_foreign` (`question_id`),
  CONSTRAINT `hpc_outcome_question_jnt_outcome_id_foreign` FOREIGN KEY (`outcome_id`) REFERENCES `hpc_learning_outcomes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `hpc_outcome_question_jnt_question_id_foreign` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `hpc_performance_descriptors` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ordinal` tinyint unsigned NOT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hpc_level_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `hpc_student_evaluation` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `academic_session_id` INT unsigned NOT NULL,
  `student_id` INT unsigned NOT NULL,
  `subject_id` INT unsigned NOT NULL,
  `competency_id` INT unsigned NOT NULL,
  `hpc_ability_parameter_id` int unsigned NOT NULL,
  `hpc_performance_descriptor_id` int unsigned NOT NULL,
  `evidence_type` INT unsigned NOT NULL,
  `evidence_id` INT unsigned DEFAULT NULL,
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `assessed_by` INT unsigned DEFAULT NULL,
  `assessed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hpc_eval` (`academic_session_id`,`student_id`,`subject_id`,`competency_id`,`hpc_ability_parameter_id`),
  KEY `hpc_student_evaluation_student_id_foreign` (`student_id`),
  KEY `hpc_student_evaluation_subject_id_foreign` (`subject_id`),
  KEY `hpc_student_evaluation_competency_id_foreign` (`competency_id`),
  KEY `fk_hpc_eval_hpc_ability_parameter` (`hpc_ability_parameter_id`),
  KEY `fk_hpc_eval_hpc_performance_descriptor` (`hpc_performance_descriptor_id`),
  KEY `hpc_student_evaluation_evidence_type_foreign` (`evidence_type`),
  KEY `hpc_student_evaluation_assessed_by_foreign` (`assessed_by`),
  CONSTRAINT `fk_hpc_eval_hpc_ability_parameter` FOREIGN KEY (`hpc_ability_parameter_id`) REFERENCES `hpc_ability_parameters` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_hpc_eval_hpc_performance_descriptor` FOREIGN KEY (`hpc_performance_descriptor_id`) REFERENCES `hpc_performance_descriptors` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `hpc_student_evaluation_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `std_student_academic_sessions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `hpc_student_evaluation_assessed_by_foreign` FOREIGN KEY (`assessed_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `hpc_student_evaluation_competency_id_foreign` FOREIGN KEY (`competency_id`) REFERENCES `slb_competencies` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `hpc_student_evaluation_evidence_type_foreign` FOREIGN KEY (`evidence_type`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `hpc_student_evaluation_student_id_foreign` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `hpc_student_evaluation_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `hpc_student_hpc_snapshot` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `academic_session_id` INT unsigned NOT NULL,
  `student_id` INT unsigned NOT NULL,
  `snapshot_json` json NOT NULL,
  `generated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hpc_snapshot` (`academic_session_id`,`student_id`),
  KEY `hpc_student_hpc_snapshot_student_id_foreign` (`student_id`),
  CONSTRAINT `hpc_student_hpc_snapshot_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `std_student_academic_sessions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `hpc_student_hpc_snapshot_student_id_foreign` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `hpc_syllabus_coverage_snapshot` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `academic_session_id` INT unsigned NOT NULL,
  `class_id` INT unsigned NOT NULL,
  `subject_id` INT unsigned NOT NULL,
  `coverage_percentage` decimal(5,2) NOT NULL,
  `snapshot_date` date NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `hpc_syllabus_coverage_snapshot_academic_session_id_foreign` (`academic_session_id`),
  KEY `fk_syllabus_coverage_class` (`class_id`),
  KEY `hpc_syllabus_coverage_snapshot_subject_id_foreign` (`subject_id`),
  CONSTRAINT `fk_syllabus_coverage_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `hpc_syllabus_coverage_snapshot_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `std_student_academic_sessions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `hpc_syllabus_coverage_snapshot_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `hpc_topic_equivalency` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `source_topic_id` INT unsigned NOT NULL,
  `target_topic_id` INT unsigned NOT NULL,
  `equivalency_type` enum('FULL','PARTIAL','PREREQUISITE') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'FULL',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_topic_equiv` (`source_topic_id`,`target_topic_id`),
  KEY `fk_equiv_target` (`target_topic_id`),
  CONSTRAINT `fk_equiv_source` FOREIGN KEY (`source_topic_id`) REFERENCES `slb_topics` (`id`),
  CONSTRAINT `fk_equiv_target` FOREIGN KEY (`target_topic_id`) REFERENCES `slb_topics` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- Module - LMS (lms)
-- ================================================================================

CREATE TABLE `lms_assessment_types` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `assessment_usage_type_id` INT unsigned NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `lms_assessment_types_code_unique` (`code`),
  KEY `lms_assessment_types_assessment_usage_type_id_foreign` (`assessment_usage_type_id`),
  CONSTRAINT `lms_assessment_types_assessment_usage_type_id_foreign` FOREIGN KEY (`assessment_usage_type_id`) REFERENCES `qns_question_usage_type` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `lms_difficulty_distribution_configs` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `usage_type_id` INT unsigned NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `lms_difficulty_distribution_configs_code_unique` (`code`),
  KEY `lms_difficulty_distribution_configs_usage_type_id_foreign` (`usage_type_id`),
  CONSTRAINT `lms_difficulty_distribution_configs_usage_type_id_foreign` FOREIGN KEY (`usage_type_id`) REFERENCES `qns_question_usage_type` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `lms_difficulty_distribution_details` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `difficulty_config_id` INT unsigned NOT NULL,
  `question_type_id` INT unsigned NOT NULL,
  `complexity_level_id` INT unsigned NOT NULL,
  `min_percentage` decimal(5,2) NOT NULL DEFAULT '0.00',
  `max_percentage` decimal(5,2) NOT NULL DEFAULT '0.00',
  `marks_per_question` decimal(5,2) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `lms_difficulty_distribution_details_difficulty_config_id_foreign` (`difficulty_config_id`),
  KEY `lms_difficulty_distribution_details_question_type_id_foreign` (`question_type_id`),
  KEY `lms_difficulty_distribution_details_complexity_level_id_foreign` (`complexity_level_id`),
  CONSTRAINT `lms_difficulty_distribution_details_complexity_level_id_foreign` FOREIGN KEY (`complexity_level_id`) REFERENCES `slb_complexity_levels` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `lms_difficulty_distribution_details_difficulty_config_id_foreign` FOREIGN KEY (`difficulty_config_id`) REFERENCES `lms_difficulty_distribution_configs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `lms_difficulty_distribution_details_question_type_id_foreign` FOREIGN KEY (`question_type_id`) REFERENCES `slb_question_types` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `lms_quest_allocations` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `quest_id` INT unsigned NOT NULL,
  `allocation_type` enum('CLASS','SECTION','GROUP','STUDENT') COLLATE utf8mb4_unicode_ci NOT NULL,
  `target_table_name` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `target_id` INT unsigned NOT NULL,
  `assigned_by` INT unsigned DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `due_date` datetime DEFAULT NULL,
  `cut_off_date` datetime DEFAULT NULL,
  `is_auto_publish_result` tinyint(1) NOT NULL DEFAULT '0',
  `result_publish_date` datetime DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `lms_quest_allocations_allocation_type_target_id_index` (`allocation_type`,`target_id`),
  KEY `lms_quest_allocations_quest_id_foreign` (`quest_id`),
  KEY `lms_quest_allocations_assigned_by_foreign` (`assigned_by`),
  CONSTRAINT `lms_quest_allocations_assigned_by_foreign` FOREIGN KEY (`assigned_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `lms_quest_allocations_quest_id_foreign` FOREIGN KEY (`quest_id`) REFERENCES `lms_quests` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `lms_quest_questions` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `quest_id` INT unsigned NOT NULL,
  `question_id` INT unsigned NOT NULL,
  `ordinal` int unsigned NOT NULL DEFAULT '0',
  `marks_override` decimal(5,2) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `lms_quest_questions_quest_id_question_id_unique` (`quest_id`,`question_id`),
  KEY `lms_quest_questions_question_id_foreign` (`question_id`),
  CONSTRAINT `lms_quest_questions_quest_id_foreign` FOREIGN KEY (`quest_id`) REFERENCES `lms_quests` (`id`) ON DELETE CASCADE,
  CONSTRAINT `lms_quest_questions_question_id_foreign` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `lms_quest_scopes` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `quest_id` INT unsigned NOT NULL,
  `lesson_id` INT unsigned NOT NULL,
  `topic_id` INT unsigned NOT NULL,
  `question_type_id` INT unsigned DEFAULT NULL,
  `target_question_count` int unsigned NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_quest_scope` (`quest_id`,`lesson_id`,`topic_id`),
  KEY `lms_quest_scopes_topic_id_foreign` (`topic_id`),
  KEY `lms_quest_scopes_lesson_id_foreign` (`lesson_id`),
  CONSTRAINT `lms_quest_scopes_lesson_id_foreign` FOREIGN KEY (`lesson_id`) REFERENCES `slb_lessons` (`id`) ON DELETE CASCADE,
  CONSTRAINT `lms_quest_scopes_quest_id_foreign` FOREIGN KEY (`quest_id`) REFERENCES `lms_quests` (`id`) ON DELETE CASCADE,
  CONSTRAINT `lms_quest_scopes_topic_id_foreign` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `lms_quests` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quest_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `instructions` text COLLATE utf8mb4_unicode_ci,
  `quest_type_id` INT unsigned NOT NULL,
  `difficulty_config_id` INT unsigned DEFAULT NULL,
  `created_by` INT unsigned DEFAULT NULL,
  `status` enum('DRAFT','PUBLISHED','ARCHIVED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `duration_minutes` tinyint unsigned DEFAULT NULL,
  `total_marks` decimal(8,2) NOT NULL DEFAULT '0.00',
  `total_questions` int unsigned NOT NULL DEFAULT '0',
  `passing_percentage` decimal(5,2) NOT NULL DEFAULT '33.00',
  `allow_multiple_attempts` tinyint(1) NOT NULL DEFAULT '0',
  `max_attempts` tinyint unsigned NOT NULL DEFAULT '1',
  `negative_marks` decimal(4,2) NOT NULL DEFAULT '0.00',
  `is_randomized` tinyint(1) NOT NULL DEFAULT '0',
  `question_marks_shown` tinyint(1) NOT NULL DEFAULT '0',
  `auto_publish_result` tinyint(1) NOT NULL DEFAULT '0',
  `timer_enforced` tinyint(1) NOT NULL DEFAULT '1',
  `show_correct_answer` tinyint(1) NOT NULL DEFAULT '0',
  `show_explanation` tinyint(1) NOT NULL DEFAULT '0',
  `ignore_difficulty_config` tinyint(1) NOT NULL DEFAULT '0',
  `is_system_generated` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `lms_quests_uuid_unique` (`uuid`),
  UNIQUE KEY `lms_quests_quest_code_unique` (`quest_code`),
  KEY `lms_quests_status_index` (`status`),
  KEY `lms_quests_quest_type_id_index` (`quest_type_id`),
  KEY `lms_quests_difficulty_config_id_foreign` (`difficulty_config_id`),
  KEY `lms_quests_created_by_foreign` (`created_by`),
  CONSTRAINT `lms_quests_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `lms_quests_difficulty_config_id_foreign` FOREIGN KEY (`difficulty_config_id`) REFERENCES `lms_difficulty_distribution_configs` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `lms_quests_quest_type_id_foreign` FOREIGN KEY (`quest_type_id`) REFERENCES `lms_assessment_types` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `lms_quiz_allocations` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `quiz_id` INT unsigned NOT NULL,
  `allocation_type` enum('CLASS','SECTION','GROUP','STUDENT') COLLATE utf8mb4_unicode_ci NOT NULL,
  `target_table_name` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `target_id` INT unsigned NOT NULL,
  `assigned_by` INT unsigned DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `due_date` datetime DEFAULT NULL,
  `cut_off_date` datetime DEFAULT NULL,
  `is_auto_publish_result` tinyint(1) NOT NULL DEFAULT '0',
  `result_publish_date` datetime DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `lms_quiz_allocations_allocation_type_target_id_index` (`allocation_type`,`target_id`),
  KEY `lms_quiz_allocations_quiz_id_foreign` (`quiz_id`),
  KEY `lms_quiz_allocations_assigned_by_foreign` (`assigned_by`),
  CONSTRAINT `lms_quiz_allocations_assigned_by_foreign` FOREIGN KEY (`assigned_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `lms_quiz_allocations_quiz_id_foreign` FOREIGN KEY (`quiz_id`) REFERENCES `lms_quizzes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `lms_quiz_questions` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `quiz_id` INT unsigned NOT NULL,
  `question_id` INT unsigned NOT NULL,
  `ordinal` int unsigned NOT NULL DEFAULT '0',
  `marks_override` decimal(5,2) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `lms_quiz_questions_quiz_id_question_id_unique` (`quiz_id`,`question_id`),
  KEY `lms_quiz_questions_question_id_foreign` (`question_id`),
  CONSTRAINT `lms_quiz_questions_question_id_foreign` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE,
  CONSTRAINT `lms_quiz_questions_quiz_id_foreign` FOREIGN KEY (`quiz_id`) REFERENCES `lms_quizzes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `lms_quizzes` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quiz_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `instructions` text COLLATE utf8mb4_unicode_ci,
  `quiz_type_id` INT unsigned NOT NULL,
  `scope_topic_id` INT unsigned DEFAULT NULL,
  `difficulty_config_id` INT unsigned DEFAULT NULL,
  `created_by` INT unsigned DEFAULT NULL,
  `status` enum('DRAFT','PUBLISHED','ARCHIVED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `duration_minutes` tinyint unsigned DEFAULT NULL,
  `total_marks` decimal(8,2) NOT NULL DEFAULT '0.00',
  `total_questions` int unsigned NOT NULL DEFAULT '0',
  `passing_percentage` decimal(5,2) NOT NULL DEFAULT '33.00',
  `allow_multiple_attempts` tinyint(1) NOT NULL DEFAULT '0',
  `max_attempts` tinyint unsigned NOT NULL DEFAULT '1',
  `negative_marks` decimal(4,2) NOT NULL DEFAULT '0.00',
  `is_randomized` tinyint(1) NOT NULL DEFAULT '0',
  `question_marks_shown` tinyint(1) NOT NULL DEFAULT '0',
  `show_result_immediately` tinyint(1) NOT NULL DEFAULT '0',
  `auto_publish_result` tinyint(1) NOT NULL DEFAULT '0',
  `timer_enforced` tinyint(1) NOT NULL DEFAULT '1',
  `ignore_difficulty_config` tinyint(1) NOT NULL DEFAULT '0',
  `is_system_generated` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `lms_quizzes_uuid_unique` (`uuid`),
  UNIQUE KEY `lms_quizzes_quiz_code_unique` (`quiz_code`),
  KEY `lms_quizzes_status_index` (`status`),
  KEY `lms_quizzes_scope_topic_id_index` (`scope_topic_id`),
  KEY `lms_quizzes_quiz_type_id_foreign` (`quiz_type_id`),
  KEY `lms_quizzes_difficulty_config_id_foreign` (`difficulty_config_id`),
  KEY `lms_quizzes_created_by_foreign` (`created_by`),
  CONSTRAINT `lms_quizzes_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `lms_quizzes_difficulty_config_id_foreign` FOREIGN KEY (`difficulty_config_id`) REFERENCES `lms_difficulty_distribution_configs` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `lms_quizzes_quiz_type_id_foreign` FOREIGN KEY (`quiz_type_id`) REFERENCES `lms_assessment_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `lms_quizzes_scope_topic_id_foreign` FOREIGN KEY (`scope_topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ================================================================================
-- Module - Notification (ntf)
-- ================================================================================



CREATE TABLE `ntf_channel_master` (
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

CREATE TABLE `ntf_notification_channels` (
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

CREATE TABLE `ntf_notification_delivery_logs` (
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

CREATE TABLE `ntf_notification_targets` (
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

CREATE TABLE `ntf_notification_templates` (
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

CREATE TABLE `ntf_notifications` (
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

CREATE TABLE `ntf_user_preferences` (
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

-- ================================================================================
-- Module - Prime (prm)
-- ================================================================================

-- Check - Not being used as of Now
CREATE TABLE `prm_billing_cycles` (
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

-- ================================================================================
-- Module - Question bank (qns)
-- ================================================================================

CREATE TABLE `qns_media_store` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varbinary(16) NOT NULL COMMENT 'UUID stored as BINARY(16) using UUID_TO_BIN',
  `owner_type` enum('QUESTION','OPTION','EXPLANATION','RECOMMENDATION') COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Entity this media belongs to',
  `owner_id` INT unsigned NOT NULL COMMENT 'ID of related entity',
  `media_type` enum('IMAGE','AUDIO','VIDEO','PDF') COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Type of media file',
  `ordinal` smallint unsigned NOT NULL DEFAULT '1' COMMENT 'Ordering of media for same owner',
  `placed_at` int unsigned DEFAULT NULL COMMENT 'Logical position inside content',
  `file_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Original uploaded file name',
  `file_path` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Relative storage path',
  `mime_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'MIME type of file',
  `disk` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'public' COMMENT 'Storage disk name',
  `size` INT unsigned DEFAULT NULL COMMENT 'File size in bytes',
  `checksum` char(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'SHA-256 checksum',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Active or inactive media',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `qns_media_store_uuid_unique` (`uuid`),
  KEY `idx_media_owner` (`owner_type`,`owner_id`),
  KEY `idx_media_type` (`media_type`),
  KEY `idx_media_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `qns_question_media_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `question_bank_id` INT unsigned NOT NULL,
  `question_option_id` INT unsigned DEFAULT NULL,
  `media_id` INT unsigned NOT NULL,
  `media_purpose` enum('QUESTION','OPTION','QUES_EXPLANATION','OPT_EXPLANATION','RECOMMENDATION') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'QUESTION',
  `media_type` enum('IMAGE','AUDIO','VIDEO','ATTACHMENT') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'IMAGE',
  `ordinal` smallint unsigned NOT NULL DEFAULT '1' COMMENT 'Ordinal position of this media',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `qns_question_media_jnt_media_id_foreign` (`media_id`),
  KEY `idx_qmedia_question` (`question_bank_id`),
  KEY `idx_qmedia_option` (`question_option_id`),
  CONSTRAINT `qns_question_media_jnt_media_id_foreign` FOREIGN KEY (`media_id`) REFERENCES `qns_media_store` (`id`) ON DELETE CASCADE,
  CONSTRAINT `qns_question_media_jnt_question_bank_id_foreign` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE,
  CONSTRAINT `qns_question_media_jnt_question_option_id_foreign` FOREIGN KEY (`question_option_id`) REFERENCES `qns_question_options` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `qns_question_options` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `question_bank_id` INT unsigned NOT NULL,
  `ordinal` smallint unsigned DEFAULT NULL,
  `option_text` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_correct` tinyint(1) NOT NULL DEFAULT '0',
  `Explanation` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_opt_question` (`question_bank_id`),
  CONSTRAINT `qns_question_options_question_bank_id_foreign` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `qns_question_performance_category_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `question_bank_id` INT unsigned NOT NULL,
  `performance_category_id` INT unsigned NOT NULL,
  `recommendation_type` enum('REVISION','PRACTICE','CHALLENGE') COLLATE utf8mb4_unicode_ci NOT NULL,
  `priority` smallint unsigned NOT NULL DEFAULT '1',
  `is_active` tinyint NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qrec_q_p` (`question_bank_id`,`performance_category_id`),
  KEY `fk_qrec_perf` (`performance_category_id`),
  CONSTRAINT `fk_qrec_perf` FOREIGN KEY (`performance_category_id`) REFERENCES `slb_performance_categories` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_qrec_question` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `qns_question_questiontag_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `question_bank_id` INT unsigned NOT NULL,
  `tag_id` INT unsigned NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qtag_q_t` (`question_bank_id`,`tag_id`),
  KEY `qns_question_questiontag_jnt_tag_id_foreign` (`tag_id`),
  CONSTRAINT `qns_question_questiontag_jnt_question_bank_id_foreign` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `qns_question_questiontag_jnt_tag_id_foreign` FOREIGN KEY (`tag_id`) REFERENCES `qns_question_tags` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `qns_question_statistics` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `question_bank_id` INT unsigned NOT NULL,
  `difficulty_index` decimal(5,2) DEFAULT NULL,
  `discrimination_index` decimal(5,2) DEFAULT NULL,
  `guessing_factor` decimal(5,2) DEFAULT NULL,
  `min_time_taken_seconds` int unsigned DEFAULT NULL,
  `max_time_taken_seconds` int unsigned DEFAULT NULL,
  `avg_time_taken_seconds` int unsigned NOT NULL,
  `total_attempts` int unsigned NOT NULL DEFAULT '0',
  `last_computed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active` tinyint NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qstats_q` (`question_bank_id`),
  CONSTRAINT `fk_qstats_question` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `qns_question_tags` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `short_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qtag_short` (`short_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `qns_question_topic_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `question_bank_id` INT unsigned NOT NULL,
  `topic_id` INT unsigned NOT NULL,
  `weightage` decimal(5,2) NOT NULL DEFAULT '100.00',
  `is_active` tinyint NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qt_q_t` (`question_bank_id`,`topic_id`),
  KEY `fk_qt_topic` (`topic_id`),
  CONSTRAINT `fk_qt_question` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_qt_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `qns_question_usage_log` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `question_bank_id` INT unsigned NOT NULL,
  `usage_context` enum('QUIZ','ASSESSMENT','EXAM') COLLATE utf8mb4_unicode_ci NOT NULL,
  `context_id` INT unsigned NOT NULL,
  `used_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_qusage_question` (`question_bank_id`),
  CONSTRAINT `fk_qusage_question` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `qns_question_usage_type` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `qns_question_usage_type_code_unique` (`code`),
  UNIQUE KEY `qns_question_usage_type_name_unique` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `qns_question_versions` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `question_bank_id` INT unsigned NOT NULL,
  `version` int unsigned NOT NULL,
  `data` json NOT NULL,
  `version_created_by` INT unsigned DEFAULT NULL,
  `change_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qver_q_v` (`question_bank_id`,`version`),
  CONSTRAINT `qns_question_versions_question_bank_id_foreign` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `qns_questions_bank` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varbinary(16) NOT NULL,
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
  `expected_time_to_answer_seconds` int unsigned DEFAULT NULL,
  `marks` decimal(5,2) NOT NULL DEFAULT '1.00',
  `negative_marks` decimal(5,2) NOT NULL DEFAULT '0.00',
  `current_version` tinyint unsigned NOT NULL DEFAULT '1',
  `for_offline_exam` tinyint unsigned NOT NULL DEFAULT '8',
  `for_quiz` tinyint(1) NOT NULL DEFAULT '1',
  `for_assessment` tinyint(1) NOT NULL DEFAULT '1',
  `for_exam` tinyint(1) NOT NULL DEFAULT '1',
  `ques_owner` enum('PrimeGurukul','School') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PrimeGurukul',
  `created_by_AI` tinyint(1) NOT NULL DEFAULT '0',
  `created_by` INT unsigned DEFAULT NULL,
  `is_school_specific` tinyint(1) NOT NULL DEFAULT '0',
  `availability` enum('GLOBAL','SCHOOL_ONLY','CLASS_ONLY','SECTION_ONLY','ENTITY_ONLY','STUDENT_ONLY') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'GLOBAL',
  `selected_entity_group_id` INT unsigned DEFAULT NULL,
  `selected_section_id` INT unsigned DEFAULT NULL,
  `selected_student_id` INT unsigned DEFAULT NULL,
  `book_id` INT unsigned DEFAULT NULL,
  `book_page_ref` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `external_ref` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reference_material` text COLLATE utf8mb4_unicode_ci,
  `status` enum('DRAFT','IN_REVIEW','APPROVED','REJECTED','PUBLISHED','ARCHIVED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `qns_questions_bank_uuid_unique` (`uuid`),
  KEY `idx_ques_topic` (`topic_id`),
  KEY `idx_ques_competency` (`competency_id`),
  KEY `idx_ques_class_subject` (`class_id`,`subject_id`),
  KEY `idx_ques_complexity_bloom` (`complexity_level_id`,`bloom_id`),
  KEY `idx_ques_book` (`book_id`),
  KEY `qns_questions_bank_subject_id_foreign` (`subject_id`),
  KEY `qns_questions_bank_lesson_id_foreign` (`lesson_id`),
  KEY `qns_questions_bank_bloom_id_foreign` (`bloom_id`),
  KEY `qns_questions_bank_cognitive_skill_id_foreign` (`cognitive_skill_id`),
  KEY `qns_questions_bank_ques_type_specificity_id_foreign` (`ques_type_specificity_id`),
  KEY `qns_questions_bank_question_type_id_foreign` (`question_type_id`),
  KEY `qns_questions_bank_created_by_foreign` (`created_by`),
  KEY `qns_questions_bank_selected_entity_group_id_foreign` (`selected_entity_group_id`),
  KEY `qns_questions_bank_selected_section_id_foreign` (`selected_section_id`),
  KEY `qns_questions_bank_selected_student_id_foreign` (`selected_student_id`),
  KEY `qns_questions_bank_availability_index` (`availability`),
  KEY `qns_questions_bank_is_active_index` (`is_active`),
  CONSTRAINT `qns_questions_bank_bloom_id_foreign` FOREIGN KEY (`bloom_id`) REFERENCES `slb_bloom_taxonomy` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `qns_questions_bank_book_id_foreign` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `qns_questions_bank_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `qns_questions_bank_cognitive_skill_id_foreign` FOREIGN KEY (`cognitive_skill_id`) REFERENCES `slb_cognitive_skill` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `qns_questions_bank_competency_id_foreign` FOREIGN KEY (`competency_id`) REFERENCES `slb_competencies` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `qns_questions_bank_complexity_level_id_foreign` FOREIGN KEY (`complexity_level_id`) REFERENCES `slb_complexity_levels` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `qns_questions_bank_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `qns_questions_bank_lesson_id_foreign` FOREIGN KEY (`lesson_id`) REFERENCES `slb_lessons` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `qns_questions_bank_ques_type_specificity_id_foreign` FOREIGN KEY (`ques_type_specificity_id`) REFERENCES `slb_ques_type_specificity` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `qns_questions_bank_question_type_id_foreign` FOREIGN KEY (`question_type_id`) REFERENCES `slb_question_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `qns_questions_bank_selected_entity_group_id_foreign` FOREIGN KEY (`selected_entity_group_id`) REFERENCES `sch_entity_groups` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `qns_questions_bank_selected_section_id_foreign` FOREIGN KEY (`selected_section_id`) REFERENCES `sch_sections` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `qns_questions_bank_selected_student_id_foreign` FOREIGN KEY (`selected_student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `qns_questions_bank_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `qns_questions_bank_topic_id_foreign` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- Module - School Setup (sch)
-- ================================================================================

CREATE TABLE `sch_board_organization_jnt` (
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

CREATE TABLE `sch_buildings` (
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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sch_class_groups` (
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
  KEY `sch_class_groups_subject_id_foreign` (`subject_id`),
  CONSTRAINT `sch_class_groups_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sch_class_groups_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `sub_stdy_frmt_id` INT unsigned NOT NULL,
  `class_id` INT unsigned NOT NULL,
  `rooms_type_id` INT unsigned NOT NULL,
  `section_id` INT unsigned DEFAULT NULL,
  `subject_type_id` INT unsigned NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` char(30) COLLATE utf8mb4_unicode_ci NOT NULL,
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

CREATE TABLE `sch_class_section_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `class_id` INT unsigned NOT NULL,
  `section_id` INT unsigned NOT NULL,
  `class_teacher_id` INT unsigned NOT NULL,
  `assistance_class_teacher_id` INT unsigned NOT NULL,
  `class_section_code` char(9) COLLATE utf8mb4_unicode_ci NOT NULL,
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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sch_classes` (
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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sch_department` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sch_designation` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sch_entity_groups` (
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

CREATE TABLE `sch_entity_groups_members` (
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

CREATE TABLE `sch_org_academic_sessions_jnt` (
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

CREATE TABLE `sch_organizations` (
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

CREATE TABLE `sch_rooms` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `building_id` INT unsigned NOT NULL,
  `room_type_id` INT unsigned NOT NULL,
  `code` char(20) COLLATE utf8mb4_unicode_ci NOT NULL,
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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sch_rooms_type` (
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
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sch_sections` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ordinal` tinyint unsigned NOT NULL DEFAULT '1',
  `code` char(3) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sch_study_formats` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sch_subject_group_subject_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `subject_group_id` INT unsigned NOT NULL,
  `std_cls_subtyp_id` INT unsigned NOT NULL,
  `subject_id` INT unsigned NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ssgsj_grp_stdcls_subject` (`subject_group_id`,`std_cls_subtyp_id`,`subject_id`),
  KEY `sch_subject_group_subject_jnt_std_cls_subtyp_id_foreign` (`std_cls_subtyp_id`),
  KEY `sch_subject_group_subject_jnt_subject_id_foreign` (`subject_id`),
  CONSTRAINT `sch_subject_group_subject_jnt_std_cls_subtyp_id_foreign` FOREIGN KEY (`std_cls_subtyp_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_subject_group_subject_jnt_subject_group_id_foreign` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_subject_group_subject_jnt_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sch_subject_groups` (
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

CREATE TABLE `sch_subject_study_format_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `subject_id` INT unsigned NOT NULL,
  `study_format_id` INT unsigned NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subj_stdformat_code` char(20) COLLATE utf8mb4_unicode_ci NOT NULL,
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
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sch_subject_teachers` (
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
  CONSTRAINT `sch_subject_teachers_study_format_id_foreign` FOREIGN KEY (`study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_subject_teachers_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `sch_subject_teachers_teacher_id_foreign` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=50 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sch_subject_types` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `short_name` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` char(3) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sch_subjects` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `short_name` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` char(8) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sch_teachers` (
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
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sch_teachers_profile` (
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

-- ================================================================================
-- Module - Syllabus (slb)
-- ================================================================================

CREATE TABLE `slb_author_books_jnt` (
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

CREATE TABLE `slb_bloom_taxonomy` (
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

CREATE TABLE `slb_book_author_jnt` (
  `book_id` INT unsigned NOT NULL,
  `author_id` INT unsigned NOT NULL,
  `author_role` enum('PRIMARY','CO_AUTHOR','EDITOR','CONTRIBUTOR') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PRIMARY',
  `ordinal` tinyint unsigned NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`book_id`,`author_id`),
  KEY `fk_ba_author` (`author_id`),
  CONSTRAINT `fk_ba_author` FOREIGN KEY (`author_id`) REFERENCES `slb_book_authors` (`id`),
  CONSTRAINT `fk_ba_book` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `slb_book_authors` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Author full name',
  `qualification` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bio` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slb_book_authors_name_unique` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `slb_book_class_subject_jnt` (
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
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_bcs_book_class_subject_session` (`book_id`,`class_id`,`subject_id`,`academic_session_id`),
  KEY `slb_book_class_subject_jnt_class_id_foreign` (`class_id`),
  KEY `slb_book_class_subject_jnt_subject_id_foreign` (`subject_id`),
  CONSTRAINT `slb_book_class_subject_jnt_book_id_foreign` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`) ON DELETE CASCADE,
  CONSTRAINT `slb_book_class_subject_jnt_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `slb_book_class_subject_jnt_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `slb_book_topic_mapping` (
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

CREATE TABLE `slb_books` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `isbn` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'International Standard Book Number',
  `title` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subtitle` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `edition` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. 5th Edition, Revised 2024',
  `publication_year` year DEFAULT NULL,
  `publisher_name` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `language` INT unsigned NOT NULL,
  `total_pages` int unsigned DEFAULT NULL,
  `cover_image_media_id` INT unsigned DEFAULT NULL,
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
  KEY `idx_book_year` (`publication_year`),
  KEY `slb_books_language_foreign` (`language`),
  KEY `slb_books_cover_image_media_id_foreign` (`cover_image_media_id`),
  CONSTRAINT `slb_books_cover_image_media_id_foreign` FOREIGN KEY (`cover_image_media_id`) REFERENCES `sys_media` (`id`),
  CONSTRAINT `slb_books_language_foreign` FOREIGN KEY (`language`) REFERENCES `sys_dropdowns` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `slb_cognitive_skill` (
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

CREATE TABLE `slb_competencies` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varbinary(16) NOT NULL,
  `parent_id` INT unsigned DEFAULT NULL,
  `code` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `class_id` INT unsigned DEFAULT NULL,
  `subject_id` INT unsigned DEFAULT NULL,
  `competency_type_id` INT unsigned NOT NULL,
  `domain` enum('COGNITIVE','AFFECTIVE','PSYCHOMOTOR') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'COGNITIVE',
  `nep_framework_ref` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ncf_alignment` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `learning_outcome_code` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '/',
  `level` tinyint unsigned NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slb_competencies_uuid_unique` (`uuid`),
  UNIQUE KEY `slb_competencies_code_unique` (`code`),
  KEY `slb_competencies_class_id_foreign` (`class_id`),
  KEY `slb_competencies_subject_id_foreign` (`subject_id`),
  KEY `idx_competency_parent` (`parent_id`),
  KEY `idx_competency_type` (`competency_type_id`),
  CONSTRAINT `slb_competencies_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `slb_competencies_competency_type_id_foreign` FOREIGN KEY (`competency_type_id`) REFERENCES `slb_competency_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `slb_competencies_parent_id_foreign` FOREIGN KEY (`parent_id`) REFERENCES `slb_competencies` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `slb_competencies_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `slb_competency_types` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. KNOWLEDGE, SKILL, ATTITUDE',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slb_competency_types_code_unique` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `slb_complexity_levels` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
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

CREATE TABLE `slb_grade_division_master` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'A, B, C, 1st, 2nd, TOPPER, EXCELLENT',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Grade A, First Division',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `grading_type` enum('GRADE','DIVISION') COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Grade or Division based system',
  `min_percentage` decimal(5,2) NOT NULL COMMENT 'Minimum percentage',
  `max_percentage` decimal(5,2) NOT NULL COMMENT 'Maximum percentage',
  `board_code` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'CBSE, ICSE, STATE',
  `academic_session_id` INT unsigned DEFAULT NULL COMMENT 'Academic session reference',
  `display_order` smallint unsigned NOT NULL DEFAULT '1',
  `color_code` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'UI badge color',
  `scope` enum('SCHOOL','BOARD','CLASS') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'SCHOOL' COMMENT 'Applicability scope',
  `class_id` INT unsigned DEFAULT NULL COMMENT 'Class specific grading',
  `is_locked` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Locked after result publishing',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_grade_code` (`code`,`grading_type`,`scope`,`class_id`),
  UNIQUE KEY `uq_scope_range` (`scope`,`class_id`,`min_percentage`,`max_percentage`),
  KEY `idx_active` (`is_active`),
  KEY `idx_grading_type` (`grading_type`),
  KEY `idx_scope` (`scope`),
  CONSTRAINT `chk_percentage_range` CHECK ((`min_percentage` < `max_percentage`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `slb_lessons` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varbinary(16) NOT NULL COMMENT 'Unique identifier for analytics tracking',
  `academic_session_id` INT unsigned NOT NULL,
  `class_id` INT unsigned NOT NULL,
  `subject_id` INT unsigned NOT NULL,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Auto-generated: class + subject + lesson code',
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ordinal` smallint unsigned NOT NULL COMMENT 'Sequence order within subject',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `learning_objectives` json DEFAULT NULL,
  `prerequisites` json DEFAULT NULL,
  `estimated_periods` smallint unsigned DEFAULT NULL,
  `weightage_in_subject` decimal(5,2) DEFAULT NULL,
  `nep_alignment` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `resources_json` json DEFAULT NULL,
  `book_chapter_ref` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `scheduled_year_week` int unsigned DEFAULT NULL COMMENT 'Format: YYYYWW',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lesson_uuid` (`uuid`),
  UNIQUE KEY `uq_lesson_class_subject_name` (`class_id`,`subject_id`,`name`),
  UNIQUE KEY `uq_lesson_code` (`code`),
  UNIQUE KEY `slb_lessons_uuid_unique` (`uuid`),
  UNIQUE KEY `slb_lessons_code_unique` (`code`),
  KEY `slb_lessons_academic_session_id_foreign` (`academic_session_id`),
  KEY `slb_lessons_subject_id_foreign` (`subject_id`),
  KEY `idx_lesson_class_subject` (`class_id`,`subject_id`),
  KEY `idx_lesson_ordinal` (`ordinal`),
  CONSTRAINT `slb_lessons_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `slb_lessons_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `slb_lessons_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `slb_performance_categories` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'TOPPER, EXCELLENT, GOOD, AVERAGE, BELOW_AVERAGE, NEED_IMPROVEMENT, POOR',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Display name',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `level` tinyint unsigned NOT NULL COMMENT '1=Topper, 2=Excellent, 3=Good, 4=Average, 5=Below Average, 6=Poor',
  `min_percentage` decimal(5,2) NOT NULL COMMENT 'Minimum percentage',
  `max_percentage` decimal(5,2) NOT NULL COMMENT 'Maximum percentage',
  `ai_severity` enum('LOW','MEDIUM','HIGH','CRITICAL') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'LOW',
  `ai_default_action` enum('ACCELERATE','PROGRESS','PRACTICE','REMEDIATE','ESCALATE') COLLATE utf8mb4_unicode_ci NOT NULL,
  `display_order` smallint unsigned NOT NULL DEFAULT '1',
  `color_code` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'UI badge color',
  `icon_code` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. trophy, warning, alert',
  `scope` enum('SCHOOL','CLASS') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'SCHOOL',
  `class_id` INT unsigned DEFAULT NULL,
  `is_system_defined` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'System defined vs school editable',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_perf_code_scope` (`code`,`scope`),
  KEY `slb_performance_categories_class_id_foreign` (`class_id`),
  KEY `idx_perf_active` (`is_active`),
  CONSTRAINT `slb_performance_categories_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `slb_ques_type_specificity` (
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

CREATE TABLE `slb_question_types` (
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

CREATE TABLE `slb_study_material_types` (
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

CREATE TABLE `slb_study_materials` (
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

CREATE TABLE `slb_syllabus_schedule` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `academic_session_id` INT unsigned NOT NULL,
  `class_id` INT unsigned NOT NULL,
  `section_id` INT unsigned DEFAULT NULL,
  `subject_id` INT unsigned NOT NULL,
  `topic_id` INT unsigned NOT NULL,
  `scheduled_start_date` date NOT NULL,
  `scheduled_end_date` date NOT NULL,
  `assigned_teacher_id` INT unsigned DEFAULT NULL,
  `taught_by_teacher_id` INT unsigned DEFAULT NULL,
  `planned_periods` smallint unsigned DEFAULT NULL,
  `priority` enum('HIGH','MEDIUM','LOW') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'MEDIUM',
  `notes` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` INT unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sylsched_dates` (`scheduled_start_date`,`scheduled_end_date`),
  KEY `idx_sylsched_class_subject` (`class_id`,`subject_id`),
  KEY `fk_sylsched_session` (`academic_session_id`),
  KEY `fk_sylsched_section` (`section_id`),
  KEY `fk_sylsched_subject` (`subject_id`),
  KEY `fk_sylsched_topic` (`topic_id`),
  KEY `fk_sylsched_teacher` (`assigned_teacher_id`),
  CONSTRAINT `fk_sylsched_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sylsched_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sylsched_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sylsched_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sylsched_teacher` FOREIGN KEY (`assigned_teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sylsched_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `slb_topic_competency_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `topic_id` INT unsigned NOT NULL,
  `competency_id` INT unsigned NOT NULL,
  `weightage` decimal(5,2) DEFAULT NULL,
  `is_primary` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tc_topic_competency` (`topic_id`,`competency_id`),
  KEY `fk_tc_competency` (`competency_id`),
  CONSTRAINT `fk_tc_competency` FOREIGN KEY (`competency_id`) REFERENCES `slb_competencies` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tc_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `slb_topic_dependencies` (
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

CREATE TABLE `slb_topics` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varbinary(16) NOT NULL COMMENT 'Unique analytics identifier',
  `parent_id` INT unsigned DEFAULT NULL,
  `lesson_id` INT unsigned NOT NULL,
  `class_id` INT unsigned NOT NULL,
  `subject_id` INT unsigned NOT NULL,
  `path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Ancestor path e.g. /1/5/23/',
  `path_names` varchar(2000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Readable hierarchy path',
  `level` tinyint unsigned NOT NULL DEFAULT '0' COMMENT 'Depth in hierarchy',
  `code` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ordinal` smallint unsigned NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `weightage_in_lesson` decimal(5,2) DEFAULT NULL,
  `duration_minutes` int unsigned DEFAULT NULL,
  `learning_objectives` json DEFAULT NULL,
  `keywords` json DEFAULT NULL,
  `prerequisite_topic_ids` json DEFAULT NULL,
  `base_topic_id` INT unsigned DEFAULT NULL,
  `is_assessable` tinyint(1) NOT NULL DEFAULT '1',
  `analytics_code` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_topic_uuid` (`uuid`),
  UNIQUE KEY `uq_topic_analytics_code` (`analytics_code`),
  UNIQUE KEY `uq_topic_code` (`code`),
  UNIQUE KEY `slb_topics_uuid_unique` (`uuid`),
  UNIQUE KEY `slb_topics_code_unique` (`code`),
  UNIQUE KEY `slb_topics_analytics_code_unique` (`analytics_code`),
  UNIQUE KEY `uq_topic_parent_ordinal` (`lesson_id`,`parent_id`,`ordinal`),
  KEY `slb_topics_subject_id_foreign` (`subject_id`),
  KEY `slb_topics_base_topic_id_foreign` (`base_topic_id`),
  KEY `idx_topic_parent` (`parent_id`),
  KEY `idx_topic_level` (`level`),
  KEY `idx_topic_class_subject` (`class_id`,`subject_id`),
  CONSTRAINT `slb_topics_base_topic_id_foreign` FOREIGN KEY (`base_topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE SET NULL,
  CONSTRAINT `slb_topics_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `slb_topics_lesson_id_foreign` FOREIGN KEY (`lesson_id`) REFERENCES `slb_lessons` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `slb_topics_parent_id_foreign` FOREIGN KEY (`parent_id`) REFERENCES `slb_topics` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `slb_topics_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- Module - Student (std)
-- ================================================================================

CREATE TABLE `std_attendance_corrections` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `attendance_id` INT unsigned NOT NULL,
  `requested_by` INT unsigned NOT NULL,
  `requested_status` enum('Present','Absent','Late','Half Day','Short Leave','Leave') COLLATE utf8mb4_unicode_ci NOT NULL,
  `requested_period` tinyint unsigned NOT NULL DEFAULT '0',
  `reason` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('Pending','Approved','Rejected') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Pending',
  `admin_remarks` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `action_by` INT unsigned DEFAULT NULL,
  `action_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_att_corr_attId` (`attendance_id`),
  KEY `fk_att_corr_reqBy` (`requested_by`),
  KEY `fk_att_corr_actBy` (`action_by`),
  CONSTRAINT `fk_att_corr_actBy` FOREIGN KEY (`action_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_att_corr_attId` FOREIGN KEY (`attendance_id`) REFERENCES `std_student_attendance` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_att_corr_reqBy` FOREIGN KEY (`requested_by`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `std_guardians` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `user_id` INT unsigned DEFAULT NULL COMMENT 'FK to sys_users, nullable if portal access not created',
  `first_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gender` enum('Male','Female','Transgender','Prefer Not to Say') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Male',
  `mobile_no` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Primary identifier if user_id is null',
  `phone_no` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `occupation` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `qualification` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `annual_income` decimal(15,2) DEFAULT NULL,
  `photo_file_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `media_id` INT unsigned DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_std_guardians_mobile` (`mobile_no`),
  UNIQUE KEY `uq_std_guardians_userId` (`user_id`),
  CONSTRAINT `fk_std_guardians_userId` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `std_health_profiles` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_id` INT unsigned NOT NULL COMMENT 'FK to std_students',
  `blood_group` enum('A+','A-','B+','B-','AB+','AB-','O+','O-') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `height_cm` decimal(5,2) DEFAULT NULL COMMENT 'Last recorded height',
  `weight_kg` decimal(5,2) DEFAULT NULL COMMENT 'Last recorded weight',
  `measurement_date` date DEFAULT NULL,
  `allergies` text COLLATE utf8mb4_unicode_ci COMMENT 'CSV or notes',
  `chronic_conditions` text COLLATE utf8mb4_unicode_ci COMMENT 'Asthma, Diabetes, etc.',
  `medications` text COLLATE utf8mb4_unicode_ci COMMENT 'Ongoing medications',
  `dietary_restrictions` text COLLATE utf8mb4_unicode_ci,
  `vision_left` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `vision_right` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `doctor_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `doctor_phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_health_student` (`student_id`),
  CONSTRAINT `fk_health_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `std_medical_incidents` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_id` INT unsigned NOT NULL,
  `incident_date` datetime NOT NULL,
  `incident_type_id` INT unsigned NOT NULL,
  `location` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `first_aid_given` text COLLATE utf8mb4_unicode_ci,
  `action_taken` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reported_by` INT unsigned DEFAULT NULL,
  `parent_notified` tinyint(1) NOT NULL DEFAULT '0',
  `closure_date` date DEFAULT NULL,
  `follow_up_required` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_med_inc_student` (`student_id`),
  KEY `fk_med_inc_reporter` (`reported_by`),
  CONSTRAINT `fk_med_inc_reporter` FOREIGN KEY (`reported_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_med_inc_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `std_previous_education` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_id` INT unsigned NOT NULL COMMENT 'FK to std_students',
  `school_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `school_address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `board` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'CBSE, ICSE, State Board',
  `class_passed` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. 5th, 8th, 10th',
  `year_of_passing` year DEFAULT NULL,
  `percentage_grade` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `medium_of_instruction` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tc_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tc_date` date DEFAULT NULL,
  `is_recognized` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Was the previous school recognized?',
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_prev_edu_student` (`student_id`),
  CONSTRAINT `fk_prev_edu_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `std_student_academic_sessions` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_id` INT unsigned NOT NULL,
  `academic_session_id` INT unsigned NOT NULL,
  `class_section_id` INT unsigned NOT NULL,
  `roll_no` int unsigned DEFAULT NULL,
  `subject_group_id` INT unsigned DEFAULT NULL,
  `house` INT unsigned DEFAULT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT '0',
  `session_status_id` INT unsigned NOT NULL,
  `leaving_date` date DEFAULT NULL,
  `count_as_attrition` tinyint(1) NOT NULL DEFAULT '0',
  `reason_quit` INT unsigned DEFAULT NULL,
  `dis_note` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_std_acad_sess_student_session` (`student_id`,`academic_session_id`),
  KEY `fk_sas_session` (`academic_session_id`),
  KEY `fk_sas_class_section` (`class_section_id`),
  KEY `fk_sas_subj_group` (`subject_group_id`),
  KEY `fk_sas_status` (`session_status_id`),
  CONSTRAINT `fk_sas_class_section` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sas_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sas_status` FOREIGN KEY (`session_status_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sas_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sas_subj_group` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `std_student_addresses` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_id` INT unsigned NOT NULL COMMENT 'FK to std_students',
  `address_type` enum('Permanent','Correspondence','Guardian','Local') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Correspondence',
  `address` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `city_id` INT unsigned NOT NULL COMMENT 'FK to glb_cities',
  `pincode` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_primary` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Primary communication address',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Active address',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_std_addr_studentId` (`student_id`),
  CONSTRAINT `fk_std_addr_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `std_student_attendance` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_id` INT unsigned NOT NULL,
  `academic_session_id` INT unsigned NOT NULL,
  `class_section_id` INT unsigned NOT NULL,
  `attendance_date` date NOT NULL,
  `attendance_period` tinyint unsigned NOT NULL DEFAULT '0',
  `status` enum('Present','Absent','Late','Half Day','Short Leave','Leave') COLLATE utf8mb4_unicode_ci NOT NULL,
  `remarks` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `marked_by` INT unsigned DEFAULT NULL,
  `marked_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_std_att_student_date` (`student_id`,`attendance_date`,`attendance_period`),
  KEY `idx_std_att_class_date` (`class_section_id`,`attendance_date`),
  KEY `fk_att_marker` (`marked_by`),
  CONSTRAINT `fk_att_class` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_att_marker` FOREIGN KEY (`marked_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_att_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `std_student_detail` (
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

CREATE TABLE `std_student_documents` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_id` INT unsigned NOT NULL COMMENT 'FK to std_students',
  `document_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. Transfer Certificate, Mark Sheet, Aadhar Card',
  `document_type_id` INT unsigned NOT NULL COMMENT 'FK to sys_dropdown_table',
  `document_number` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `issue_date` date DEFAULT NULL,
  `expiry_date` date DEFAULT NULL,
  `issuing_authority` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_verified` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Verified by school admin',
  `verified_by` INT unsigned DEFAULT NULL COMMENT 'FK to sys_users',
  `verification_date` datetime DEFAULT NULL,
  `file_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'File name to show in UI',
  `media_id` INT unsigned DEFAULT NULL COMMENT 'Optional FK to sys_media',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_std_docs_student` (`student_id`),
  KEY `fk_std_docs_type` (`document_type_id`),
  KEY `fk_std_docs_verifier` (`verified_by`),
  CONSTRAINT `fk_std_docs_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_std_docs_type` FOREIGN KEY (`document_type_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_std_docs_verifier` FOREIGN KEY (`verified_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `std_student_guardian_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_id` INT unsigned NOT NULL COMMENT 'FK to std_students',
  `guardian_id` INT unsigned NOT NULL COMMENT 'FK to std_guardians',
  `relation_type` enum('Father','Mother','Guardian') COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Primary relation type',
  `relationship` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Specific relationship: Father, Mother, Uncle, Sister, etc.',
  `is_emergency_contact` tinyint(1) NOT NULL DEFAULT '0',
  `can_pickup` tinyint(1) NOT NULL DEFAULT '0',
  `is_fee_payer` tinyint(1) NOT NULL DEFAULT '0',
  `can_access_parent_portal` tinyint(1) NOT NULL DEFAULT '0',
  `can_receive_notifications` tinyint(1) NOT NULL DEFAULT '1',
  `notification_preference` enum('Email','SMS','WhatsApp','All') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'All',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_std_guard_jnt` (`student_id`,`guardian_id`),
  KEY `fk_sg_jnt_guardian` (`guardian_id`),
  CONSTRAINT `fk_sg_jnt_guardian` FOREIGN KEY (`guardian_id`) REFERENCES `std_guardians` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sg_jnt_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `std_student_pay_log` (
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

CREATE TABLE `std_student_profiles` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_id` INT unsigned NOT NULL COMMENT 'FK to std_students',
  `mobile` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Student personal mobile',
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Student personal email',
  `religion` INT unsigned DEFAULT NULL,
  `caste_category` INT unsigned DEFAULT NULL,
  `nationality` INT unsigned DEFAULT NULL,
  `mother_tongue` INT unsigned DEFAULT NULL,
  `bank_account_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ifsc_code` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_branch` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `upi_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fee_depositor_pan_number` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'For tax benefit',
  `right_to_education` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'RTE quota',
  `is_ews` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Economically Weaker Section',
  `height_cm` decimal(5,2) DEFAULT NULL,
  `weight_kg` decimal(5,2) DEFAULT NULL,
  `measurement_date` date DEFAULT NULL,
  `additional_info` json DEFAULT NULL,
  `blood_group` enum('A+','A-','B+','B-','AB+','AB-','O+','O-') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_std_profiles_studentId` (`student_id`),
  KEY `fk_std_profiles_religion` (`religion`),
  KEY `fk_std_profiles_caste_category` (`caste_category`),
  KEY `fk_std_profiles_nationality` (`nationality`),
  KEY `fk_std_profiles_mother_tongue` (`mother_tongue`),
  CONSTRAINT `fk_std_profiles_caste_category` FOREIGN KEY (`caste_category`) REFERENCES `sys_dropdowns` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_std_profiles_mother_tongue` FOREIGN KEY (`mother_tongue`) REFERENCES `sys_dropdowns` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_std_profiles_nationality` FOREIGN KEY (`nationality`) REFERENCES `sys_dropdowns` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_std_profiles_religion` FOREIGN KEY (`religion`) REFERENCES `sys_dropdowns` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_std_profiles_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `std_students` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `user_id` INT unsigned NOT NULL,
  `admission_no` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `admission_date` date NOT NULL,
  `student_qr_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `student_id_card_type` enum('QR','RFID','NFC','Barcode') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'QR',
  `smart_card_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `aadhar_id` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `apaar_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `birth_cert_no` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `first_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `middle_name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gender` enum('Male','Female','Transgender','Prefer Not to Say') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Male',
  `dob` date NOT NULL,
  `photo_file_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `media_id` INT unsigned DEFAULT NULL,
  `current_status_id` INT unsigned NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `note` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_std_students_admissionNo` (`admission_no`),
  UNIQUE KEY `uq_std_students_aadhar` (`aadhar_id`),
  KEY `std_students_user_id_foreign` (`user_id`),
  CONSTRAINT `std_students_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `std_vaccination_records` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_id` INT unsigned NOT NULL COMMENT 'FK to std_students',
  `vaccine_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_administered` date DEFAULT NULL,
  `next_due_date` date DEFAULT NULL,
  `remarks` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_vacc_student` (`student_id`),
  CONSTRAINT `fk_vacc_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- Module - System (sys)
-- ================================================================================

CREATE TABLE `sys_activity_logs` (
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

CREATE TABLE `sys_dropdown_needs` (
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
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sys_dropdowns` (
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
) ENGINE=InnoDB AUTO_INCREMENT=299 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sys_media` (
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

CREATE TABLE `sys_model_has_permissions_jnt` (
  `permission_id` INT unsigned NOT NULL,
  `model_type` varchar(190) COLLATE utf8mb4_unicode_ci NOT NULL,
  `model_id` INT unsigned NOT NULL,
  PRIMARY KEY (`permission_id`,`model_id`,`model_type`),
  KEY `model_has_permissions_model_id_model_type_index` (`model_id`,`model_type`),
  CONSTRAINT `sys_model_has_permissions_jnt_permission_id_foreign` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sys_model_has_roles_jnt` (
  `role_id` INT unsigned NOT NULL,
  `model_type` varchar(190) COLLATE utf8mb4_unicode_ci NOT NULL,
  `model_id` INT unsigned NOT NULL,
  PRIMARY KEY (`role_id`,`model_id`,`model_type`),
  KEY `model_has_roles_model_id_model_type_index` (`model_id`,`model_type`),
  CONSTRAINT `sys_model_has_roles_jnt_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sys_permissions` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `guard_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sys_permissions_name_guard_name_unique` (`name`,`guard_name`)
) ENGINE=InnoDB AUTO_INCREMENT=1975 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sys_role_has_permissions_jnt` (
  `permission_id` INT unsigned NOT NULL,
  `role_id` INT unsigned NOT NULL,
  PRIMARY KEY (`permission_id`,`role_id`),
  KEY `sys_role_has_permissions_jnt_role_id_foreign` (`role_id`),
  CONSTRAINT `sys_role_has_permissions_jnt_permission_id_foreign` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `sys_role_has_permissions_jnt_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sys_roles` (
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

CREATE TABLE `sys_settings` (
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

CREATE TABLE `sys_users` (
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
  `is_pg_user` tinyint(1) NOT NULL DEFAULT '0',
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
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- Module - Transport (tpt)
-- ================================================================================

CREATE TABLE `tpt_attendance_device` (
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

CREATE TABLE `tpt_daily_vehicle_inspection` (
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

CREATE TABLE `tpt_driver_attendance` (
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

CREATE TABLE `tpt_driver_route_vehicle_jnt` (
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

CREATE TABLE `tpt_feature_store` (
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

CREATE TABLE `tpt_fine_master` (
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

CREATE TABLE `tpt_gps_alerts` (
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

CREATE TABLE `tpt_gps_trip_log` (
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

CREATE TABLE `tpt_live_trip` (
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

CREATE TABLE `tpt_model_recommendations` (
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

CREATE TABLE `tpt_notification_log` (
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

CREATE TABLE `tpt_personnel` (
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

CREATE TABLE `tpt_pickup_points` (
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

CREATE TABLE `tpt_pickup_points_route_jnt` (
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

CREATE TABLE `tpt_recommendation_history` (
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

CREATE TABLE `tpt_route` (
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

CREATE TABLE `tpt_route_scheduler_jnt` (
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

CREATE TABLE `tpt_shift` (
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

CREATE TABLE `tpt_student_boarding_log` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `trip_date` date NOT NULL,
  `student_id` INT unsigned DEFAULT NULL,
  `student_session_id` INT unsigned DEFAULT NULL,
  `boarding_route_id` INT unsigned DEFAULT NULL,
  `boarding_trip_id` INT unsigned DEFAULT NULL,
  `boarding_stop_id` INT unsigned DEFAULT NULL,
  `boarding_time` datetime DEFAULT NULL,
  `unboarding_route_id` INT unsigned DEFAULT NULL,
  `unboarding_trip_id` INT unsigned DEFAULT NULL,
  `unboarding_stop_id` INT unsigned DEFAULT NULL,
  `unboarding_time` datetime DEFAULT NULL,
  `device_id` INT unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_sel_student` (`student_id`),
  KEY `fk_sel_boardingRoute` (`boarding_route_id`),
  KEY `fk_sel_boardingTrip` (`boarding_trip_id`),
  KEY `fk_sel_boardingStop` (`boarding_stop_id`),
  KEY `fk_sel_unboardingRoute` (`unboarding_route_id`),
  KEY `fk_sel_unboardingTrip` (`unboarding_trip_id`),
  KEY `fk_sel_unboardingStop` (`unboarding_stop_id`),
  KEY `fk_sel_device` (`device_id`),
  CONSTRAINT `fk_sel_boardingRoute` FOREIGN KEY (`boarding_route_id`) REFERENCES `tpt_route` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sel_boardingStop` FOREIGN KEY (`boarding_stop_id`) REFERENCES `tpt_pickup_points` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sel_boardingTrip` FOREIGN KEY (`boarding_trip_id`) REFERENCES `tpt_trip` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sel_device` FOREIGN KEY (`device_id`) REFERENCES `tpt_attendance_device` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sel_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sel_unboardingRoute` FOREIGN KEY (`unboarding_route_id`) REFERENCES `tpt_route` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sel_unboardingStop` FOREIGN KEY (`unboarding_stop_id`) REFERENCES `tpt_pickup_points` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sel_unboardingTrip` FOREIGN KEY (`unboarding_trip_id`) REFERENCES `tpt_trip` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tpt_student_event_log` (
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

CREATE TABLE `tpt_student_fee_collection` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_fee_detail_id` INT unsigned NOT NULL,
  `payment_date` date NOT NULL,
  `total_delay_days` int NOT NULL DEFAULT '0',
  `paid_amount` decimal(10,2) NOT NULL,
  `payment_mode` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reconciled` tinyint(1) NOT NULL DEFAULT '0',
  `remarks` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_fc_fee_detail` (`student_fee_detail_id`),
  CONSTRAINT `fk_fc_fee_detail` FOREIGN KEY (`student_fee_detail_id`) REFERENCES `tpt_student_fee_detail` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tpt_student_fee_detail` (
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

CREATE TABLE `tpt_student_fine_detail` (
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

CREATE TABLE `tpt_student_route_allocation_jnt` (
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

CREATE TABLE `tpt_trip` (
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

CREATE TABLE `tpt_trip_incidents` (
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

CREATE TABLE `tpt_trip_stop_detail` (
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

CREATE TABLE `tpt_vehicle` (
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

CREATE TABLE `tpt_vehicle_fuel` (
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

CREATE TABLE `tpt_vehicle_maintenance` (
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

CREATE TABLE `tpt_vehicle_service_request` (
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

-- ================================================================================
-- Module - Timetable (tt)
-- ================================================================================

CREATE TABLE `tt_activities` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varbinary(16) NOT NULL,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `academic_session_id` INT unsigned NOT NULL,
  `class_group_jnt_id` INT unsigned DEFAULT NULL,
  `class_subgroup_id` INT unsigned DEFAULT NULL,
  `duration_periods` tinyint unsigned NOT NULL DEFAULT '1',
  `weekly_periods` tinyint unsigned NOT NULL DEFAULT '1',
  `total_periods` smallint unsigned GENERATED ALWAYS AS ((`duration_periods` * `weekly_periods`)) STORED,
  `split_allowed` tinyint(1) NOT NULL DEFAULT '0',
  `is_compulsory` tinyint(1) NOT NULL DEFAULT '1',
  `priority` tinyint unsigned NOT NULL DEFAULT '50',
  `difficulty_score` tinyint unsigned NOT NULL DEFAULT '50',
  `requires_room` tinyint(1) NOT NULL DEFAULT '1',
  `preferred_room_type_id` INT unsigned DEFAULT NULL,
  `preferred_room_ids` json DEFAULT NULL,
  `status` enum('DRAFT','ACTIVE','LOCKED','ARCHIVED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` INT unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_activity_uuid` (`uuid`),
  UNIQUE KEY `uq_activity_code` (`code`),
  KEY `tt_activities_academic_session_id_foreign` (`academic_session_id`),
  KEY `idx_activity_class_group` (`class_group_jnt_id`),
  KEY `idx_activity_subgroup` (`class_subgroup_id`),
  KEY `tt_activities_preferred_room_type_id_foreign` (`preferred_room_type_id`),
  KEY `tt_activities_created_by_foreign` (`created_by`),
  KEY `idx_activity_status` (`status`),
  CONSTRAINT `idx_activity_class_group` FOREIGN KEY (`class_group_jnt_id`) REFERENCES `tt_class_groups_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `idx_activity_subgroup` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_activities_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `global_master`.`glb_academic_sessions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_activities_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tt_activities_preferred_room_type_id_foreign` FOREIGN KEY (`preferred_room_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_activity_target` CHECK ((((`class_group_jnt_id` is not null) and (`class_subgroup_id` is null)) or ((`class_group_jnt_id` is null) and (`class_subgroup_id` is not null))))
) ENGINE=InnoDB AUTO_INCREMENT=73 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_activity_teachers` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `activity_id` INT unsigned NOT NULL,
  `teacher_id` INT unsigned NOT NULL,
  `assignment_role_id` INT unsigned NOT NULL,
  `is_required` tinyint(1) NOT NULL DEFAULT '1',
  `ordinal` tinyint unsigned NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tt_activity_teachers_activity_id_foreign` (`activity_id`),
  KEY `idx_at_teacher` (`teacher_id`),
  KEY `tt_activity_teachers_assignment_role_id_foreign` (`assignment_role_id`),
  CONSTRAINT `idx_at_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_activity_teachers_activity_id_foreign` FOREIGN KEY (`activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_activity_teachers_assignment_role_id_foreign` FOREIGN KEY (`assignment_role_id`) REFERENCES `tt_teacher_assignment_roles` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=73 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_class_group_requirements` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `class_group_id` INT unsigned DEFAULT NULL,
  `class_subgroup_id` INT unsigned DEFAULT NULL,
  `academic_session_id` INT unsigned NOT NULL,
  `weekly_periods` tinyint unsigned NOT NULL,
  `min_periods_per_week` tinyint unsigned DEFAULT NULL,
  `max_periods_per_week` tinyint unsigned DEFAULT NULL,
  `max_per_day` tinyint unsigned DEFAULT NULL,
  `min_per_day` tinyint unsigned DEFAULT NULL,
  `min_gap_periods` tinyint unsigned DEFAULT NULL,
  `allow_consecutive` tinyint(1) NOT NULL DEFAULT '0',
  `max_consecutive` tinyint unsigned NOT NULL DEFAULT '2',
  `preferred_periods_json` json DEFAULT NULL,
  `avoid_periods_json` json DEFAULT NULL,
  `spread_evenly` tinyint(1) NOT NULL DEFAULT '1',
  `priority` smallint unsigned NOT NULL DEFAULT '50',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cgr_group_session` (`class_group_id`,`class_subgroup_id`,`academic_session_id`),
  KEY `tt_class_group_requirements_class_subgroup_id_foreign` (`class_subgroup_id`),
  KEY `tt_class_group_requirements_academic_session_id_foreign` (`academic_session_id`),
  CONSTRAINT `tt_class_group_requirements_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `global_master`.`glb_academic_sessions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_class_group_requirements_class_group_id_foreign` FOREIGN KEY (`class_group_id`) REFERENCES `tt_class_groups_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_class_group_requirements_class_subgroup_id_foreign` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `chk_cgr_target` CHECK ((((`class_group_id` is not null) and (`class_subgroup_id` is null)) or ((`class_group_id` is null) and (`class_subgroup_id` is not null))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_class_groups_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `class_id` INT unsigned NOT NULL,
  `section_id` INT unsigned NOT NULL,
  `subject_study_format_id` INT unsigned NOT NULL,
  `subject_type_id` INT unsigned NOT NULL,
  `rooms_type_id` INT unsigned NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` char(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_classGroups_cls_Sec_subStdFmt_SubTyp` (`class_id`,`section_id`,`subject_study_format_id`,`subject_type_id`),
  UNIQUE KEY `uq_classGroups_subStdformatCode` (`code`),
  KEY `tt_class_groups_jnt_section_id_foreign` (`section_id`),
  KEY `tt_class_groups_jnt_subject_study_format_id_foreign` (`subject_study_format_id`),
  KEY `tt_class_groups_jnt_subject_type_id_foreign` (`subject_type_id`),
  KEY `tt_class_groups_jnt_rooms_type_id_foreign` (`rooms_type_id`),
  CONSTRAINT `tt_class_groups_jnt_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_class_groups_jnt_rooms_type_id_foreign` FOREIGN KEY (`rooms_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_class_groups_jnt_section_id_foreign` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_class_groups_jnt_subject_study_format_id_foreign` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_class_groups_jnt_subject_type_id_foreign` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=73 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_class_mode_rules` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `class_id` INT unsigned NOT NULL,
  `timetable_mode_id` INT unsigned NOT NULL,
  `period_set_id` INT unsigned NOT NULL,
  `allow_teaching_periods` tinyint(1) NOT NULL DEFAULT '1',
  `allow_exam_periods` tinyint(1) NOT NULL DEFAULT '0',
  `exam_period_count` tinyint unsigned DEFAULT NULL,
  `teaching_after_exam_flag` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cmr_class_mode` (`class_id`,`timetable_mode_id`),
  KEY `tt_class_mode_rules_timetable_mode_id_foreign` (`timetable_mode_id`),
  KEY `tt_class_mode_rules_period_set_id_foreign` (`period_set_id`),
  CONSTRAINT `tt_class_mode_rules_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_class_mode_rules_period_set_id_foreign` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_sets` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_class_mode_rules_timetable_mode_id_foreign` FOREIGN KEY (`timetable_mode_id`) REFERENCES `tt_timetable_modes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_class_subgroup_members` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `class_subgroup_id` INT unsigned NOT NULL,
  `class_id` INT unsigned NOT NULL,
  `section_id` INT unsigned DEFAULT NULL,
  `is_primary` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_csm_subgroup_class_section` (`class_subgroup_id`,`class_id`,`section_id`),
  KEY `tt_class_subgroup_members_class_id_foreign` (`class_id`),
  KEY `tt_class_subgroup_members_section_id_foreign` (`section_id`),
  CONSTRAINT `tt_class_subgroup_members_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_class_subgroup_members_class_subgroup_id_foreign` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_class_subgroup_members_section_id_foreign` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_class_subgroups` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `class_group_id` INT unsigned DEFAULT NULL,
  `subgroup_type` enum('OPTIONAL_SUBJECT','HOBBY','SKILL','LANGUAGE','STREAM','ACTIVITY','SPORTS','OTHER') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'OTHER',
  `student_count` int unsigned DEFAULT NULL,
  `min_students` int unsigned DEFAULT NULL,
  `max_students` int unsigned DEFAULT NULL,
  `is_shared_across_sections` tinyint(1) NOT NULL DEFAULT '0',
  `is_shared_across_classes` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subgroup_code` (`code`),
  KEY `tt_class_subgroups_class_group_id_foreign` (`class_group_id`),
  KEY `idx_subgroup_type` (`subgroup_type`),
  CONSTRAINT `tt_class_subgroups_class_group_id_foreign` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_constraint_types` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `category` enum('TIME','SPACE','TEACHER','STUDENT','ACTIVITY','ROOM') COLLATE utf8mb4_unicode_ci NOT NULL,
  `scope` enum('GLOBAL','TEACHER','STUDENT','ROOM','ACTIVITY','CLASS','CLASS_SUBJECT','STUDY_FORMAT','SUBJECT','STUDENT_SET','CLASS_GROUP','CLASS_SUBGROUP') COLLATE utf8mb4_unicode_ci NOT NULL,
  `default_weight` tinyint unsigned NOT NULL DEFAULT '100',
  `is_hard_capable` tinyint(1) NOT NULL DEFAULT '1',
  `param_schema` json DEFAULT NULL,
  `is_system` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ctype_code` (`code`),
  KEY `idx_ctype_category` (`category`),
  KEY `idx_ctype_scope` (`scope`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_constraints` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varbinary(16) NOT NULL,
  `constraint_type_id` INT unsigned NOT NULL,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `academic_session_id` INT unsigned NOT NULL,
  `target_type` enum('GLOBAL','TEACHER','STUDENT_SET','ROOM','ACTIVITY','CLASS','SUBJECT','STUDY_FORMAT','CLASS_GROUP','CLASS_SUBGROUP') COLLATE utf8mb4_unicode_ci NOT NULL,
  `target_id` INT unsigned DEFAULT NULL,
  `is_hard` tinyint(1) NOT NULL DEFAULT '0',
  `weight` tinyint unsigned NOT NULL DEFAULT '100',
  `params_json` json NOT NULL,
  `effective_from` date DEFAULT NULL,
  `effective_to` date DEFAULT NULL,
  `applies_to_days_json` json DEFAULT NULL,
  `status` enum('DRAFT','ACTIVE','DISABLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` INT unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_constraint_uuid` (`uuid`),
  KEY `idx_constraint_type` (`constraint_type_id`),
  KEY `tt_constraints_academic_session_id_foreign` (`academic_session_id`),
  KEY `tt_constraints_created_by_foreign` (`created_by`),
  KEY `idx_constraint_target` (`target_type`,`target_id`),
  KEY `idx_constraint_status` (`status`),
  CONSTRAINT `idx_constraint_type` FOREIGN KEY (`constraint_type_id`) REFERENCES `tt_constraint_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_constraints_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `global_master`.`glb_academic_sessions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_constraints_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_day_types` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_working_day` tinyint(1) NOT NULL DEFAULT '1',
  `reduced_periods` tinyint(1) NOT NULL DEFAULT '0',
  `ordinal` smallint unsigned NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_daytype_code` (`code`),
  UNIQUE KEY `uq_daytype_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_days` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `label` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ordinal` int unsigned NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_generation_runs` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varbinary(16) NOT NULL,
  `timetable_id` INT unsigned NOT NULL,
  `run_number` int unsigned NOT NULL DEFAULT '1',
  `started_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `finished_at` timestamp NULL DEFAULT NULL,
  `status` enum('QUEUED','RUNNING','COMPLETED','FAILED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'QUEUED',
  `algorithm_version` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `max_recursion_depth` int unsigned NOT NULL DEFAULT '14',
  `max_placement_attempts` int unsigned DEFAULT NULL,
  `params_json` json DEFAULT NULL,
  `activities_total` int unsigned NOT NULL DEFAULT '0',
  `activities_placed` int unsigned NOT NULL DEFAULT '0',
  `activities_failed` int unsigned NOT NULL DEFAULT '0',
  `hard_violations` int unsigned NOT NULL DEFAULT '0',
  `soft_violations` int unsigned NOT NULL DEFAULT '0',
  `soft_score` decimal(10,4) DEFAULT NULL,
  `stats_json` json DEFAULT NULL,
  `error_message` text COLLATE utf8mb4_unicode_ci,
  `triggered_by` INT unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_gr_tt_run` (`timetable_id`,`run_number`),
  UNIQUE KEY `uq_gr_uuid` (`uuid`),
  KEY `tt_generation_runs_triggered_by_foreign` (`triggered_by`),
  KEY `idx_gr_status` (`status`),
  CONSTRAINT `tt_generation_runs_timetable_id_foreign` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_generation_runs_triggered_by_foreign` FOREIGN KEY (`triggered_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_period_set_period_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `period_set_id` INT unsigned NOT NULL,
  `period_type_id` INT unsigned NOT NULL,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `period_ord` tinyint unsigned NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `duration_minutes` smallint unsigned GENERATED ALWAYS AS (timestampdiff(MINUTE,`start_time`,`end_time`)) STORED,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_psp_set_ord` (`period_set_id`,`period_ord`),
  UNIQUE KEY `uq_psp_set_code` (`period_set_id`,`code`),
  KEY `idx_psp_type` (`period_type_id`),
  CONSTRAINT `tt_period_set_period_jnt_period_set_id_foreign` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_sets` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_period_set_period_jnt_period_type_id_foreign` FOREIGN KEY (`period_type_id`) REFERENCES `tt_period_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `chk_psp_time` CHECK ((`end_time` > `start_time`))
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_period_sets` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `total_periods` tinyint unsigned NOT NULL,
  `teaching_periods` tinyint unsigned NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `applicable_class_ids` json DEFAULT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_periodset_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_period_types` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `color_code` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `icon` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_schedulable` tinyint(1) NOT NULL DEFAULT '1',
  `counts_as_teaching` tinyint(1) NOT NULL DEFAULT '0',
  `counts_as_workload` tinyint(1) NOT NULL DEFAULT '0',
  `is_break` tinyint(1) NOT NULL DEFAULT '0',
  `ordinal` smallint unsigned NOT NULL DEFAULT '1',
  `is_system` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_periodtype_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_periods` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `label` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ordinal` int unsigned NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_room_unavailables` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `room_id` INT unsigned NOT NULL,
  `constraint_id` INT unsigned DEFAULT NULL,
  `day_of_week` tinyint unsigned NOT NULL,
  `period_ord` tinyint unsigned DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_recurring` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ru_room` (`room_id`),
  KEY `tt_room_unavailables_constraint_id_foreign` (`constraint_id`),
  KEY `idx_ru_day_period` (`day_of_week`,`period_ord`),
  CONSTRAINT `idx_ru_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_room_unavailables_constraint_id_foreign` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraints` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_school_days` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL,
  `day_of_week` tinyint unsigned NOT NULL,
  `ordinal` smallint unsigned NOT NULL,
  `is_school_day` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_schoolday_code` (`code`),
  UNIQUE KEY `uq_schoolday_dow` (`day_of_week`),
  KEY `idx_schoolday_ordinal` (`ordinal`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_shifts` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `default_start_time` time DEFAULT NULL,
  `default_end_time` time DEFAULT NULL,
  `ordinal` smallint unsigned NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_shift_code` (`code`),
  UNIQUE KEY `uq_shift_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_sub_activities` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `parent_activity_id` INT unsigned NOT NULL,
  `sub_activity_ord` tinyint unsigned NOT NULL,
  `code` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `duration_periods` tinyint unsigned NOT NULL DEFAULT '1',
  `same_day_as_parent` tinyint(1) NOT NULL DEFAULT '0',
  `consecutive_with_previous` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subact_parent_ord` (`parent_activity_id`,`sub_activity_ord`),
  UNIQUE KEY `uq_subact_code` (`code`),
  CONSTRAINT `tt_sub_activities_parent_activity_id_foreign` FOREIGN KEY (`parent_activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_teacher_assignment_roles` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_primary_instructor` tinyint(1) NOT NULL DEFAULT '0',
  `counts_for_workload` tinyint(1) NOT NULL DEFAULT '1',
  `allows_overlap` tinyint(1) NOT NULL DEFAULT '0',
  `workload_factor` decimal(3,2) NOT NULL DEFAULT '1.00',
  `ordinal` smallint unsigned NOT NULL DEFAULT '1',
  `is_system` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tarole_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_teacher_unavailables` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `teacher_id` INT unsigned NOT NULL,
  `constraint_id` INT unsigned DEFAULT NULL,
  `day_of_week` tinyint unsigned NOT NULL,
  `period_ord` tinyint unsigned DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_recurring` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_tu_teacher` (`teacher_id`),
  KEY `tt_teacher_unavailables_constraint_id_foreign` (`constraint_id`),
  KEY `idx_tu_day_period` (`day_of_week`,`period_ord`),
  CONSTRAINT `idx_tu_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_teacher_unavailables_constraint_id_foreign` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraints` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_timetable_cell_teachers` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `cell_id` INT unsigned NOT NULL,
  `teacher_id` INT unsigned NOT NULL,
  `assignment_role_id` INT unsigned NOT NULL,
  `is_substitute` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cct_cell_teacher` (`cell_id`,`teacher_id`),
  KEY `idx_cct_teacher` (`teacher_id`),
  KEY `tt_timetable_cell_teachers_assignment_role_id_foreign` (`assignment_role_id`),
  CONSTRAINT `idx_cct_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_timetable_cell_teachers_assignment_role_id_foreign` FOREIGN KEY (`assignment_role_id`) REFERENCES `tt_teacher_assignment_roles` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_timetable_cell_teachers_cell_id_foreign` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cells` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_timetable_cells` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `timetable_id` INT unsigned NOT NULL,
  `generation_run_id` INT unsigned DEFAULT NULL,
  `day_of_week` tinyint unsigned NOT NULL,
  `period_ord` tinyint unsigned NOT NULL,
  `cell_date` date DEFAULT NULL,
  `class_group_id` INT unsigned DEFAULT NULL,
  `class_subgroup_id` INT unsigned DEFAULT NULL,
  `activity_id` INT unsigned DEFAULT NULL,
  `sub_activity_id` INT unsigned DEFAULT NULL,
  `room_id` INT unsigned DEFAULT NULL,
  `source` enum('AUTO','MANUAL','SWAP','LOCK') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'AUTO',
  `is_locked` tinyint(1) NOT NULL DEFAULT '0',
  `locked_by` INT unsigned DEFAULT NULL,
  `locked_at` timestamp NULL DEFAULT NULL,
  `has_conflict` tinyint(1) NOT NULL DEFAULT '0',
  `conflict_details_json` json DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cell_tt_day_period_group` (`timetable_id`,`day_of_week`,`period_ord`,`class_group_id`,`class_subgroup_id`),
  KEY `tt_timetable_cells_generation_run_id_foreign` (`generation_run_id`),
  KEY `tt_timetable_cells_class_group_id_foreign` (`class_group_id`),
  KEY `tt_timetable_cells_class_subgroup_id_foreign` (`class_subgroup_id`),
  KEY `idx_cell_activity` (`activity_id`),
  KEY `tt_timetable_cells_sub_activity_id_foreign` (`sub_activity_id`),
  KEY `idx_cell_room` (`room_id`),
  KEY `tt_timetable_cells_locked_by_foreign` (`locked_by`),
  KEY `idx_cell_day_period` (`day_of_week`,`period_ord`),
  KEY `idx_cell_date` (`cell_date`),
  CONSTRAINT `idx_cell_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE SET NULL,
  CONSTRAINT `idx_cell_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`) ON DELETE SET NULL,
  CONSTRAINT `idx_cell_tt` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_timetable_cells_class_group_id_foreign` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_timetable_cells_class_subgroup_id_foreign` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_timetable_cells_generation_run_id_foreign` FOREIGN KEY (`generation_run_id`) REFERENCES `tt_generation_runs` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tt_timetable_cells_locked_by_foreign` FOREIGN KEY (`locked_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tt_timetable_cells_sub_activity_id_foreign` FOREIGN KEY (`sub_activity_id`) REFERENCES `tt_sub_activities` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_cell_target` CHECK ((((`class_group_id` is not null) and (`class_subgroup_id` is null)) or ((`class_group_id` is null) and (`class_subgroup_id` is not null))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_timetable_modes` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `has_exam` tinyint(1) NOT NULL DEFAULT '0',
  `has_teaching` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_timetable_mode_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_timetable_types` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `shift_id` INT unsigned DEFAULT NULL,
  `default_period_set_id` INT unsigned DEFAULT NULL,
  `day_type_id` INT unsigned DEFAULT NULL,
  `effective_from_date` date DEFAULT NULL,
  `effective_to_date` date DEFAULT NULL,
  `school_start_time` time DEFAULT NULL,
  `school_end_time` time DEFAULT NULL,
  `assembly_duration_min` smallint unsigned DEFAULT NULL,
  `short_break_duration_min` smallint unsigned DEFAULT NULL,
  `lunch_duration_min` smallint unsigned DEFAULT NULL,
  `has_exam` tinyint(1) NOT NULL DEFAULT '0',
  `has_teaching` tinyint(1) NOT NULL DEFAULT '1',
  `ordinal` smallint unsigned NOT NULL DEFAULT '1',
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `is_system` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tttype_code` (`code`),
  KEY `idx_tttype_shift` (`shift_id`),
  KEY `tt_timetable_types_default_period_set_id_foreign` (`default_period_set_id`),
  KEY `tt_timetable_types_day_type_id_foreign` (`day_type_id`),
  KEY `idx_tttype_effective` (`effective_from_date`,`effective_to_date`),
  CONSTRAINT `idx_tttype_shift` FOREIGN KEY (`shift_id`) REFERENCES `tt_shifts` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tt_timetable_types_day_type_id_foreign` FOREIGN KEY (`day_type_id`) REFERENCES `tt_day_types` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tt_timetable_types_default_period_set_id_foreign` FOREIGN KEY (`default_period_set_id`) REFERENCES `tt_period_sets` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_timetables` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varbinary(16) NOT NULL,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `academic_session_id` INT unsigned NOT NULL,
  `timetable_type_id` INT unsigned NOT NULL,
  `period_set_id` INT unsigned NOT NULL,
  `effective_from` date NOT NULL,
  `effective_to` date DEFAULT NULL,
  `generation_method` enum('MANUAL','SEMI_AUTO','FULL_AUTO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'MANUAL',
  `version` smallint unsigned NOT NULL DEFAULT '1',
  `parent_timetable_id` INT unsigned DEFAULT NULL,
  `status` enum('DRAFT','GENERATING','GENERATED','PUBLISHED','ARCHIVED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `published_at` timestamp NULL DEFAULT NULL,
  `published_by` INT unsigned DEFAULT NULL,
  `constraint_violations` int unsigned NOT NULL DEFAULT '0',
  `soft_score` decimal(8,2) DEFAULT NULL,
  `stats_json` json DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` INT unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tt_uuid` (`uuid`),
  UNIQUE KEY `uq_tt_code` (`code`),
  KEY `tt_timetables_academic_session_id_foreign` (`academic_session_id`),
  KEY `idx_tt_type` (`timetable_type_id`),
  KEY `tt_timetables_period_set_id_foreign` (`period_set_id`),
  KEY `tt_timetables_parent_timetable_id_foreign` (`parent_timetable_id`),
  KEY `tt_timetables_published_by_foreign` (`published_by`),
  KEY `tt_timetables_created_by_foreign` (`created_by`),
  KEY `idx_tt_effective` (`effective_from`,`effective_to`),
  KEY `idx_tt_status` (`status`),
  CONSTRAINT `idx_tt_type` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_timetables_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `global_master`.`glb_academic_sessions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_timetables_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tt_timetables_parent_timetable_id_foreign` FOREIGN KEY (`parent_timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tt_timetables_period_set_id_foreign` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_sets` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_timetables_published_by_foreign` FOREIGN KEY (`published_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_timing_profile` (
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

CREATE TABLE `tt_timing_profile_period` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `timing_profile_id` INT unsigned NOT NULL,
  `segment_ordinal` int unsigned NOT NULL,
  `label` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `segment_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PERIOD',
  `counts_as_period` tinyint(1) NOT NULL DEFAULT '1',
  `period_ordinal` int unsigned DEFAULT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tpp_ord` (`timing_profile_id`,`segment_ordinal`),
  KEY `idx_tpp_period_map` (`timing_profile_id`,`period_ordinal`),
  CONSTRAINT `tt_timing_profile_period_timing_profile_id_foreign` FOREIGN KEY (`timing_profile_id`) REFERENCES `tt_timing_profile` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_working_day` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL,
  `day_type_id` INT unsigned NOT NULL,
  `is_school_day` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_workday_date_daytype` (`date`,`day_type_id`),
  KEY `idx_workday_daytype` (`day_type_id`),
  CONSTRAINT `idx_workday_daytype` FOREIGN KEY (`day_type_id`) REFERENCES `tt_day_types` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================================
-- Module - Vendor (vnd)
-- ================================================================================

CREATE TABLE `vnd_agreement_items_jnt` (
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

CREATE TABLE `vnd_agreements` (
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

CREATE TABLE `vnd_invoices` (
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

CREATE TABLE `vnd_items` (
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

CREATE TABLE `vnd_payments` (
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

CREATE TABLE `vnd_usage_logs` (
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

CREATE TABLE `vnd_vendors` (
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

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
