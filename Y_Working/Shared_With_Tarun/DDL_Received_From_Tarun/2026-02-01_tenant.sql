-- MySQL dump 10.13  Distrib 8.0.44, for Linux (x86_64)
--
-- Host: localhost    Database: tenant_51b5ee16-d582-4568-ab8f-d4137106c752
-- ------------------------------------------------------
-- Server version	8.0.44-0ubuntu0.22.04.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `bok_book_topic_mapping`
--

DROP TABLE IF EXISTS `bok_book_topic_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bok_book_topic_mapping`
--

LOCK TABLES `bok_book_topic_mapping` WRITE;
/*!40000 ALTER TABLE `bok_book_topic_mapping` DISABLE KEYS */;
/*!40000 ALTER TABLE `bok_book_topic_mapping` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bok_books`
--

DROP TABLE IF EXISTS `bok_books`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bok_books`
--

LOCK TABLES `bok_books` WRITE;
/*!40000 ALTER TABLE `bok_books` DISABLE KEYS */;
/*!40000 ALTER TABLE `bok_books` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache`
--

DROP TABLE IF EXISTS `cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` int NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache`
--

LOCK TABLES `cache` WRITE;
/*!40000 ALTER TABLE `cache` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache_locks`
--

DROP TABLE IF EXISTS `cache_locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache_locks` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `owner` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` int NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache_locks`
--

LOCK TABLES `cache_locks` WRITE;
/*!40000 ALTER TABLE `cache_locks` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache_locks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cmp_ai_insights`
--

DROP TABLE IF EXISTS `cmp_ai_insights`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cmp_ai_insights`
--

LOCK TABLES `cmp_ai_insights` WRITE;
/*!40000 ALTER TABLE `cmp_ai_insights` DISABLE KEYS */;
/*!40000 ALTER TABLE `cmp_ai_insights` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cmp_complaint_actions`
--

DROP TABLE IF EXISTS `cmp_complaint_actions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cmp_complaint_actions`
--

LOCK TABLES `cmp_complaint_actions` WRITE;
/*!40000 ALTER TABLE `cmp_complaint_actions` DISABLE KEYS */;
/*!40000 ALTER TABLE `cmp_complaint_actions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cmp_complaint_categories`
--

DROP TABLE IF EXISTS `cmp_complaint_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cmp_complaint_categories`
--

LOCK TABLES `cmp_complaint_categories` WRITE;
/*!40000 ALTER TABLE `cmp_complaint_categories` DISABLE KEYS */;
INSERT INTO `cmp_complaint_categories` VALUES (1,NULL,'Academic Issues','ACADEMIC','Issues related to academics, classes, exams, or faculty',NULL,NULL,48,12,24,36,48,72,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(2,NULL,'Infrastructure','INFRA','Infrastructure and facility related issues',NULL,NULL,48,12,24,36,48,72,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(3,NULL,'Discipline & Conduct','DISCIPLINE','Misconduct, bullying, or discipline related complaints',NULL,NULL,48,12,24,36,48,72,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(4,NULL,'Health & Safety','HEALTH','Medical, safety, or emergency related complaints',NULL,NULL,48,12,24,36,48,72,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(5,1,'Exam Schedule Issue','EXAM_SCHEDULE',NULL,NULL,NULL,24,6,12,18,24,48,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(6,1,'Faculty Related Issue','FACULTY',NULL,NULL,NULL,24,6,12,18,24,48,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(7,2,'Classroom Facilities','CLASSROOM',NULL,NULL,NULL,24,6,12,18,24,48,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(8,2,'Hostel / Accommodation','HOSTEL',NULL,NULL,NULL,24,6,12,18,24,48,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(9,3,'Ragging / Bullying','RAGGING',NULL,NULL,NULL,24,6,12,18,24,48,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(10,4,'Medical Emergency','MEDICAL',NULL,NULL,NULL,24,6,12,18,24,48,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07');
/*!40000 ALTER TABLE `cmp_complaint_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cmp_complaints`
--

DROP TABLE IF EXISTS `cmp_complaints`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cmp_complaints`
--

LOCK TABLES `cmp_complaints` WRITE;
/*!40000 ALTER TABLE `cmp_complaints` DISABLE KEYS */;
/*!40000 ALTER TABLE `cmp_complaints` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cmp_department_sla`
--

DROP TABLE IF EXISTS `cmp_department_sla`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cmp_department_sla`
--

LOCK TABLES `cmp_department_sla` WRITE;
/*!40000 ALTER TABLE `cmp_department_sla` DISABLE KEYS */;
/*!40000 ALTER TABLE `cmp_department_sla` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cmp_medical_checks`
--

DROP TABLE IF EXISTS `cmp_medical_checks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cmp_medical_checks`
--

LOCK TABLES `cmp_medical_checks` WRITE;
/*!40000 ALTER TABLE `cmp_medical_checks` DISABLE KEYS */;
/*!40000 ALTER TABLE `cmp_medical_checks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `failed_jobs`
--

DROP TABLE IF EXISTS `failed_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `failed_jobs`
--

LOCK TABLES `failed_jobs` WRITE;
/*!40000 ALTER TABLE `failed_jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `failed_jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `glb_cities`
--

DROP TABLE IF EXISTS `glb_cities`;
/*!50001 DROP VIEW IF EXISTS `glb_cities`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `glb_cities` AS SELECT 
 1 AS `id`,
 1 AS `district_id`,
 1 AS `name`,
 1 AS `short_name`,
 1 AS `global_code`,
 1 AS `default_timezone`,
 1 AS `is_active`,
 1 AS `created_at`,
 1 AS `updated_at`,
 1 AS `deleted_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `glb_countries`
--

DROP TABLE IF EXISTS `glb_countries`;
/*!50001 DROP VIEW IF EXISTS `glb_countries`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `glb_countries` AS SELECT 
 1 AS `id`,
 1 AS `name`,
 1 AS `short_name`,
 1 AS `global_code`,
 1 AS `currency_code`,
 1 AS `is_active`,
 1 AS `created_at`,
 1 AS `updated_at`,
 1 AS `deleted_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `glb_districts`
--

DROP TABLE IF EXISTS `glb_districts`;
/*!50001 DROP VIEW IF EXISTS `glb_districts`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `glb_districts` AS SELECT 
 1 AS `id`,
 1 AS `state_id`,
 1 AS `name`,
 1 AS `short_name`,
 1 AS `global_code`,
 1 AS `is_active`,
 1 AS `created_at`,
 1 AS `updated_at`,
 1 AS `deleted_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `glb_languages`
--

DROP TABLE IF EXISTS `glb_languages`;
/*!50001 DROP VIEW IF EXISTS `glb_languages`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `glb_languages` AS SELECT 
 1 AS `id`,
 1 AS `code`,
 1 AS `name`,
 1 AS `native_name`,
 1 AS `direction`,
 1 AS `is_active`,
 1 AS `deleted_at`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `glb_menu_module_jnt`
--

DROP TABLE IF EXISTS `glb_menu_module_jnt`;
/*!50001 DROP VIEW IF EXISTS `glb_menu_module_jnt`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `glb_menu_module_jnt` AS SELECT 
 1 AS `id`,
 1 AS `menu_id`,
 1 AS `module_id`,
 1 AS `sort_order`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `glb_menus`
--

DROP TABLE IF EXISTS `glb_menus`;
/*!50001 DROP VIEW IF EXISTS `glb_menus`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `glb_menus` AS SELECT 
 1 AS `id`,
 1 AS `parent_id`,
 1 AS `is_category`,
 1 AS `code`,
 1 AS `menu_for`,
 1 AS `slug`,
 1 AS `title`,
 1 AS `description`,
 1 AS `icon`,
 1 AS `route`,
 1 AS `permission`,
 1 AS `sort_order`,
 1 AS `visible_by_default`,
 1 AS `is_active`,
 1 AS `deleted_at`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `glb_modules`
--

DROP TABLE IF EXISTS `glb_modules`;
/*!50001 DROP VIEW IF EXISTS `glb_modules`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `glb_modules` AS SELECT 
 1 AS `id`,
 1 AS `parent_id`,
 1 AS `name`,
 1 AS `version`,
 1 AS `is_sub_module`,
 1 AS `description`,
 1 AS `is_core`,
 1 AS `default_visible`,
 1 AS `available_perm_view`,
 1 AS `available_perm_add`,
 1 AS `available_perm_edit`,
 1 AS `available_perm_delete`,
 1 AS `available_perm_export`,
 1 AS `available_perm_import`,
 1 AS `available_perm_print`,
 1 AS `is_active`,
 1 AS `deleted_at`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `glb_states`
--

DROP TABLE IF EXISTS `glb_states`;
/*!50001 DROP VIEW IF EXISTS `glb_states`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `glb_states` AS SELECT 
 1 AS `id`,
 1 AS `country_id`,
 1 AS `name`,
 1 AS `short_name`,
 1 AS `global_code`,
 1 AS `is_active`,
 1 AS `created_at`,
 1 AS `updated_at`,
 1 AS `deleted_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `glb_translations`
--

DROP TABLE IF EXISTS `glb_translations`;
/*!50001 DROP VIEW IF EXISTS `glb_translations`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `glb_translations` AS SELECT 
 1 AS `id`,
 1 AS `translatable_type`,
 1 AS `translatable_id`,
 1 AS `language_id`,
 1 AS `key`,
 1 AS `value`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `hpc_ability_parameters`
--

DROP TABLE IF EXISTS `hpc_ability_parameters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hpc_ability_parameters`
--

LOCK TABLES `hpc_ability_parameters` WRITE;
/*!40000 ALTER TABLE `hpc_ability_parameters` DISABLE KEYS */;
/*!40000 ALTER TABLE `hpc_ability_parameters` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hpc_circular_goal_competency_jnt`
--

DROP TABLE IF EXISTS `hpc_circular_goal_competency_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hpc_circular_goal_competency_jnt`
--

LOCK TABLES `hpc_circular_goal_competency_jnt` WRITE;
/*!40000 ALTER TABLE `hpc_circular_goal_competency_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `hpc_circular_goal_competency_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hpc_circular_goals`
--

DROP TABLE IF EXISTS `hpc_circular_goals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hpc_circular_goals`
--

LOCK TABLES `hpc_circular_goals` WRITE;
/*!40000 ALTER TABLE `hpc_circular_goals` DISABLE KEYS */;
/*!40000 ALTER TABLE `hpc_circular_goals` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hpc_hpc_levels`
--

DROP TABLE IF EXISTS `hpc_hpc_levels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hpc_hpc_levels`
--

LOCK TABLES `hpc_hpc_levels` WRITE;
/*!40000 ALTER TABLE `hpc_hpc_levels` DISABLE KEYS */;
/*!40000 ALTER TABLE `hpc_hpc_levels` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hpc_knowledge_graph_validation`
--

DROP TABLE IF EXISTS `hpc_knowledge_graph_validation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hpc_knowledge_graph_validation`
--

LOCK TABLES `hpc_knowledge_graph_validation` WRITE;
/*!40000 ALTER TABLE `hpc_knowledge_graph_validation` DISABLE KEYS */;
/*!40000 ALTER TABLE `hpc_knowledge_graph_validation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hpc_learning_activities`
--

DROP TABLE IF EXISTS `hpc_learning_activities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hpc_learning_activities`
--

LOCK TABLES `hpc_learning_activities` WRITE;
/*!40000 ALTER TABLE `hpc_learning_activities` DISABLE KEYS */;
/*!40000 ALTER TABLE `hpc_learning_activities` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hpc_learning_activity_type`
--

DROP TABLE IF EXISTS `hpc_learning_activity_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hpc_learning_activity_type`
--

LOCK TABLES `hpc_learning_activity_type` WRITE;
/*!40000 ALTER TABLE `hpc_learning_activity_type` DISABLE KEYS */;
/*!40000 ALTER TABLE `hpc_learning_activity_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hpc_learning_outcomes`
--

DROP TABLE IF EXISTS `hpc_learning_outcomes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hpc_learning_outcomes` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hpc_learning_outcomes`
--

LOCK TABLES `hpc_learning_outcomes` WRITE;
/*!40000 ALTER TABLE `hpc_learning_outcomes` DISABLE KEYS */;
/*!40000 ALTER TABLE `hpc_learning_outcomes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hpc_outcome_entity_jnt`
--

DROP TABLE IF EXISTS `hpc_outcome_entity_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hpc_outcome_entity_jnt`
--

LOCK TABLES `hpc_outcome_entity_jnt` WRITE;
/*!40000 ALTER TABLE `hpc_outcome_entity_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `hpc_outcome_entity_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hpc_outcome_question_jnt`
--

DROP TABLE IF EXISTS `hpc_outcome_question_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hpc_outcome_question_jnt`
--

LOCK TABLES `hpc_outcome_question_jnt` WRITE;
/*!40000 ALTER TABLE `hpc_outcome_question_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `hpc_outcome_question_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hpc_performance_descriptors`
--

DROP TABLE IF EXISTS `hpc_performance_descriptors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hpc_performance_descriptors`
--

LOCK TABLES `hpc_performance_descriptors` WRITE;
/*!40000 ALTER TABLE `hpc_performance_descriptors` DISABLE KEYS */;
/*!40000 ALTER TABLE `hpc_performance_descriptors` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hpc_student_evaluation`
--

DROP TABLE IF EXISTS `hpc_student_evaluation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hpc_student_evaluation`
--

LOCK TABLES `hpc_student_evaluation` WRITE;
/*!40000 ALTER TABLE `hpc_student_evaluation` DISABLE KEYS */;
/*!40000 ALTER TABLE `hpc_student_evaluation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hpc_student_hpc_snapshot`
--

DROP TABLE IF EXISTS `hpc_student_hpc_snapshot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hpc_student_hpc_snapshot`
--

LOCK TABLES `hpc_student_hpc_snapshot` WRITE;
/*!40000 ALTER TABLE `hpc_student_hpc_snapshot` DISABLE KEYS */;
/*!40000 ALTER TABLE `hpc_student_hpc_snapshot` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hpc_syllabus_coverage_snapshot`
--

DROP TABLE IF EXISTS `hpc_syllabus_coverage_snapshot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hpc_syllabus_coverage_snapshot`
--

LOCK TABLES `hpc_syllabus_coverage_snapshot` WRITE;
/*!40000 ALTER TABLE `hpc_syllabus_coverage_snapshot` DISABLE KEYS */;
/*!40000 ALTER TABLE `hpc_syllabus_coverage_snapshot` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hpc_topic_equivalency`
--

DROP TABLE IF EXISTS `hpc_topic_equivalency`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hpc_topic_equivalency`
--

LOCK TABLES `hpc_topic_equivalency` WRITE;
/*!40000 ALTER TABLE `hpc_topic_equivalency` DISABLE KEYS */;
/*!40000 ALTER TABLE `hpc_topic_equivalency` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `job_batches`
--

DROP TABLE IF EXISTS `job_batches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_batches`
--

LOCK TABLES `job_batches` WRITE;
/*!40000 ALTER TABLE `job_batches` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_batches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jobs`
--

LOCK TABLES `jobs` WRITE;
/*!40000 ALTER TABLE `jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lms_assessment_types`
--

DROP TABLE IF EXISTS `lms_assessment_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lms_assessment_types`
--

LOCK TABLES `lms_assessment_types` WRITE;
/*!40000 ALTER TABLE `lms_assessment_types` DISABLE KEYS */;
/*!40000 ALTER TABLE `lms_assessment_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lms_difficulty_distribution_configs`
--

DROP TABLE IF EXISTS `lms_difficulty_distribution_configs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lms_difficulty_distribution_configs`
--

LOCK TABLES `lms_difficulty_distribution_configs` WRITE;
/*!40000 ALTER TABLE `lms_difficulty_distribution_configs` DISABLE KEYS */;
/*!40000 ALTER TABLE `lms_difficulty_distribution_configs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lms_difficulty_distribution_details`
--

DROP TABLE IF EXISTS `lms_difficulty_distribution_details`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lms_difficulty_distribution_details`
--

LOCK TABLES `lms_difficulty_distribution_details` WRITE;
/*!40000 ALTER TABLE `lms_difficulty_distribution_details` DISABLE KEYS */;
/*!40000 ALTER TABLE `lms_difficulty_distribution_details` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lms_quest_allocations`
--

DROP TABLE IF EXISTS `lms_quest_allocations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lms_quest_allocations`
--

LOCK TABLES `lms_quest_allocations` WRITE;
/*!40000 ALTER TABLE `lms_quest_allocations` DISABLE KEYS */;
/*!40000 ALTER TABLE `lms_quest_allocations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lms_quest_questions`
--

DROP TABLE IF EXISTS `lms_quest_questions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lms_quest_questions`
--

LOCK TABLES `lms_quest_questions` WRITE;
/*!40000 ALTER TABLE `lms_quest_questions` DISABLE KEYS */;
/*!40000 ALTER TABLE `lms_quest_questions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lms_quest_scopes`
--

DROP TABLE IF EXISTS `lms_quest_scopes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lms_quest_scopes`
--

LOCK TABLES `lms_quest_scopes` WRITE;
/*!40000 ALTER TABLE `lms_quest_scopes` DISABLE KEYS */;
/*!40000 ALTER TABLE `lms_quest_scopes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lms_quests`
--

DROP TABLE IF EXISTS `lms_quests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lms_quests`
--

LOCK TABLES `lms_quests` WRITE;
/*!40000 ALTER TABLE `lms_quests` DISABLE KEYS */;
/*!40000 ALTER TABLE `lms_quests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lms_quiz_allocations`
--

DROP TABLE IF EXISTS `lms_quiz_allocations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lms_quiz_allocations`
--

LOCK TABLES `lms_quiz_allocations` WRITE;
/*!40000 ALTER TABLE `lms_quiz_allocations` DISABLE KEYS */;
/*!40000 ALTER TABLE `lms_quiz_allocations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lms_quiz_questions`
--

DROP TABLE IF EXISTS `lms_quiz_questions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lms_quiz_questions`
--

LOCK TABLES `lms_quiz_questions` WRITE;
/*!40000 ALTER TABLE `lms_quiz_questions` DISABLE KEYS */;
/*!40000 ALTER TABLE `lms_quiz_questions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lms_quizzes`
--

DROP TABLE IF EXISTS `lms_quizzes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lms_quizzes`
--

LOCK TABLES `lms_quizzes` WRITE;
/*!40000 ALTER TABLE `lms_quizzes` DISABLE KEYS */;
/*!40000 ALTER TABLE `lms_quizzes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `media_files`
--

DROP TABLE IF EXISTS `media_files`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `media_files`
--

LOCK TABLES `media_files` WRITE;
/*!40000 ALTER TABLE `media_files` DISABLE KEYS */;
/*!40000 ALTER TABLE `media_files` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `migrations`
--

DROP TABLE IF EXISTS `migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `migrations` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=204 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `migrations`
--

LOCK TABLES `migrations` WRITE;
/*!40000 ALTER TABLE `migrations` DISABLE KEYS */;
INSERT INTO `migrations` VALUES (1,'0001_01_01_000001_create_cache_table',1),(2,'0001_01_01_000002_create_jobs_table',1),(3,'2025_10_06_110647_create_permission_tables',1),(4,'2025_10_06_112509_create_media_table',1),(5,'2025_10_06_113652_create_personal_access_tokens_table',1),(6,'2025_10_17_101827_create_organizations_table',1),(7,'2025_10_17_101827_create_users_table',1),(8,'2025_10_18_071401_make_organization_academic_sessions_table',1),(9,'2025_10_18_085546_create_board_organization_table',1),(10,'2025_10_27_044219_create_buildings_table',1),(11,'2025_10_27_113828_create_subjects_table',1),(12,'2025_10_27_153200_create_rooms_type_table',1),(13,'2025_10_28_121239_create_rooms_table',1),(14,'2025_10_30_045014_create_class_groups_table',1),(15,'2025_10_30_093924_create_teachers_table',1),(16,'2025_10_31_073119_create_study_formats_table',1),(17,'2025_11_02_071024_create_activity_logs_table',1),(18,'2025_11_03_095022_create_days_table',1),(19,'2025_11_04_085212_create_periods_table',1),(20,'2025_11_05_121505_create_timing_profiles_table',1),(21,'2025_11_05_132119_create_school_timing_profile_table',1),(22,'2025_11_08_105556_create_settings_table',1),(23,'2025_11_10_061519_create_languages_table',1),(24,'2025_11_11_055039_add_columns_to_roles_table',1),(25,'2025_11_15_093113_create_students_table',1),(26,'2025_11_15_095109_create_student_details_table',1),(27,'2025_11_16_074813_create_school_classes_table',1),(28,'2025_11_16_082615_create_sections_table',1),(29,'2025_11_16_114617_create_dropdown_needs_table',1),(30,'2025_11_16_114618_create_dropdowns_table',1),(31,'2025_11_17_033644_create_subject_groups_table',1),(32,'2025_11_17_090225_create_class_sections_table',1),(33,'2025_11_17_101312_create_student_academic_sessions_table',1),(34,'2025_11_18_033660_create_subject_group_subject_table',1),(35,'2025_11_18_043026_create_subject_types_table',1),(36,'2025_11_18_044017_create_subject_study_formats_table',1),(37,'2025_11_18_044704_create_subject_study_format_classes_table',1),(38,'2025_11_18_052235_create_glb_billing_cycle_table',1),(39,'2025_11_19_051814_create_subject_teachers_table',1),(40,'2025_11_24_121608_create_sch_subject_group_subject_jnt_table',1),(41,'2025_11_29_123000_create_global_views_for_tenants',1),(42,'2025_12_01_084015_create_tpt_shift_table',1),(43,'2025_12_01_085651_create_tpt_vehicle_table',1),(44,'2025_12_01_085728_create_tpt_route_table',1),(45,'2025_12_01_085753_create_tpt_pickup_points_table',1),(46,'2025_12_01_085819_create_tpt_personnel_table',1),(47,'2025_12_01_085843_create_tpt_pickup_points_route_jnt_table',1),(48,'2025_12_02_102454_create_teacher_profiles_table',1),(49,'2025_12_08_123858_create_tpt_driver_route_vehicle_jnt_table',1),(50,'2025_12_08_125923_create_tpt_route_scheduler_jnt_table',1),(51,'2025_12_08_125934_create_tpt_trip_table',1),(52,'2025_12_08_125943_create_tpt_live_trip_table',1),(53,'2025_12_08_125957_create_tpt_driver_attendance_table',1),(54,'2025_12_08_130026_create_tpt_fee_master_table',1),(55,'2025_12_08_130042_create_tpt_fee_collection_table',1),(56,'2025_12_08_130050_create_ml_models_table',1),(57,'2025_12_08_130059_create_ml_model_features_table',1),(58,'2025_12_08_130338_create_tpt_feature_store_table',1),(59,'2025_12_08_130356_create_tpt_model_recommendations_table',1),(60,'2025_12_08_130409_create_tpt_recommendation_history_table',1),(61,'2025_12_08_130415_create_tpt_student_event_log_table',1),(62,'2025_12_08_130422_create_tpt_trip_incidents_table',1),(63,'2025_12_08_130429_create_tpt_gps_trip_log_table',1),(64,'2025_12_08_130437_create_tpt_gps_alerts_table',1),(65,'2025_12_08_130505_create_tpt_notification_log_table',1),(66,'2025_12_12_081915_create_timing_profile_periods_table',1),(67,'2025_12_15_052215_create_timetable_modes_table',1),(68,'2025_12_15_054217_create_period_types_table',1),(69,'2025_12_15_055124_create_teacher_assignment_roles_table',1),(70,'2025_12_15_055823_create_period_sets_table',1),(71,'2025_12_15_060410_create_period_set_periods_table',1),(72,'2025_12_15_062631_create_class_mode_rules_table',1),(73,'2025_12_15_070910_create_class_subgroups_table',1),(74,'2025_12_15_115619_create_tpt_fine_master_table',1),(75,'2025_12_15_123252_create_class_subgroup_members_table',1),(76,'2025_12_17_104649_create_tpt_trip_stop_detail_table',1),(77,'2025_12_22_060146_create_complaint_categories_table',1),(78,'2025_12_22_065413_create_complaints_table',1),(79,'2025_12_22_070357_create_complaint_actions_table',1),(80,'2025_12_22_072653_create_medical_checks_table',1),(81,'2025_12_22_074156_create_ai_insights_table',1),(82,'2025_12_22_124231_create_slb_complexity_levels_table',1),(83,'2025_12_22_124334_create_slb_question_types_table',1),(84,'2025_12_23_065158_create_tpt_attendance_devices_table',1),(85,'2025_12_23_070459_create_departments_table',1),(86,'2025_12_23_070548_create_designations_table',1),(87,'2025_12_23_070631_create_entity_groups_table',1),(88,'2025_12_23_070704_create_entity_group_members_table',1),(89,'2025_12_23_123512_create_tpt_vehicle_fuel_table',1),(90,'2025_12_23_172704_create_tpt_daily_vehicle_inspections_table',1),(91,'2025_12_23_173614_create_tpt_vehicle_service_requests_table',1),(92,'2025_12_23_175505_create_tpt_vehicle_maintenances_table',1),(93,'2025_12_24_044437_create_vnd_vendors_table',1),(94,'2025_12_24_121416_create_tpt_student_fine_detail_table',1),(95,'2025_12_25_062953_create_department_slas_table',1),(96,'2025_12_25_070244_create_std_student_pay_log_table',1),(97,'2025_12_26_063754_create_vnd_agreements_table',1),(98,'2025_12_26_094507_create_vnd_items_table',1),(99,'2025_12_26_125616_create_vnd_agreement_items_jnt',1),(100,'2025_12_29_120957_create_vnd_invoices_table',1),(101,'2025_12_30_103011_create_vnd_payments_table',1),(102,'2025_12_31_043824_create_vnd_usage_logs_table',1),(103,'2025_12_31_045403_create_notifications_table',1),(104,'2026_01_01_085808_create_tpt_student_route_allocation_jnts_table',1),(105,'2026_01_01_105110_create_tpt_student_boarding_log_table',1),(106,'2026_01_02_112016_create_schedules_table',1),(107,'2026_01_02_155143_create_schedule_runs_table',1),(108,'2026_01_03_121125_create_notifications_table',1),(109,'2026_01_03_122350_create_channel_masters_table',1),(110,'2026_01_03_122355_create_notification_channels_table',1),(111,'2026_01_03_122751_create_notification_targets_table',1),(112,'2026_01_03_123213_create_user_preferences_table',1),(113,'2026_01_03_123514_create_notification_templates_table',1),(114,'2026_01_03_123749_create_notification_delivery_logs_table',1),(115,'2026_01_06_154450_create_lessons_table',1),(116,'2026_01_06_155246_create_topics_table',1),(117,'2026_01_06_155636_create_competency_types_table',1),(118,'2026_01_06_160408_create_competencies_table',1),(119,'2026_01_06_160819_create_topic_competencies_table',1),(120,'2026_01_06_161410_create_bloom_taxonomies_table',1),(121,'2026_01_06_161741_create_cognitive_skills_table',1),(122,'2026_01_06_163239_create_que_type_specifities_table',1),(123,'2026_01_06_164504_create_performance_categories_table',1),(124,'2026_01_06_164702_create_grade_divisions_table',1),(125,'2026_01_06_171520_create_books_table',1),(126,'2026_01_06_172432_create_question_banks_table',1),(127,'2026_01_06_172918_create_book_authors_table',1),(128,'2026_01_06_174300_create_question_media_stores_table',1),(129,'2026_01_07_112506_create_author_books_table',1),(130,'2026_01_07_114850_create_book_class_subjects_table',1),(131,'2026_01_07_115350_create_book_topic_mappings_table',1),(132,'2026_01_07_121345_create_study_material_types_table',1),(133,'2026_01_07_121708_create_study_materials_table',1),(134,'2026_01_07_124548_create_topic_dependencies_table',1),(135,'2026_01_12_132528_create_qns_question_options_table',1),(136,'2026_01_12_132529_create_question_media_table',1),(137,'2026_01_12_133736_create_qns_question_tags_table',1),(138,'2026_01_12_163529_create_qns_question_questiontag_jnt_table',1),(139,'2026_01_12_170548_create_qns_question_versions_table',1),(140,'2026_01_12_172545_create_qns_question_topic_jnt_table',1),(141,'2026_01_12_175022_create_qns_question_statistics_table',1),(142,'2026_01_12_180001_create_qns_question_performance_category_jnt_table',1),(143,'2026_01_12_180825_create_qns_question_usage_log_table',1),(144,'2026_01_13_121439_create_media_files_table',1),(145,'2026_01_13_121440_create_bok_books_table',1),(146,'2026_01_13_123252_create_book_author_jnt_table',1),(147,'2026_01_13_124928_create_bok_book_topic_mapping_table',1),(148,'2026_01_13_165525_create_student_profiles_table',1),(149,'2026_01_13_165549_create_student_addresses_table',1),(150,'2026_01_13_165627_create_guardians_table',1),(151,'2026_01_13_165657_create_previous_education_table',1),(152,'2026_01_13_170133_create_student_documents_table',1),(153,'2026_01_13_170152_create_student_health_profiles_table',1),(154,'2026_01_13_170214_create_vaccination_records_table',1),(155,'2026_01_13_170238_create_medical_incidents_table',1),(156,'2026_01_13_170258_create_student_attendances_table',1),(157,'2026_01_13_170314_create_student_attendance_corrections_table',1),(158,'2026_01_14_103327_create_shifts_table',1),(159,'2026_01_14_103802_create_day_types_table',1),(160,'2026_01_14_105131_create_school_days_table',1),(161,'2026_01_14_105746_create_working_days_table',1),(162,'2026_01_14_110738_create_timetable_types_table',1),(163,'2026_01_14_121941_create_constraint_types_table',1),(164,'2026_01_14_122232_create_constraints_table',1),(165,'2026_01_14_122818_create_teacher_unavailables_table',1),(166,'2026_01_14_124843_create_timetables_table',1),(167,'2026_01_14_130120_create_generation_runs_table',1),(168,'2026_01_14_1374045_create_room_unavailables_table',1),(169,'2026_01_14_184754_create_class_group_jnts_table',1),(170,'2026_01_14_193120_create_student_gaurdian_jnts_table',1),(171,'2026_01_15_162042_create_slb_syllabus_schedule_table',1),(172,'2026_01_15_165735_create_class_group_requirements_table',1),(173,'2026_01_15_166206_create_activities_table',1),(174,'2026_01_15_167027_create_sub_activities_table',1),(175,'2026_01_15_174714_create_timetable_cells_table',1),(176,'2026_01_15_175747_create_timetable_cell_teachers_table',1),(177,'2026_01_15_175854_create_activity_teachers_table',1),(178,'2026_01_16_123046_create_hpc_circular_goals_table',1),(179,'2026_01_16_124504_create_hpc_circular_goal_competency_jnt_table',1),(180,'2026_01_16_125911_create_hpc_learning_outcomes_table',1),(181,'2026_01_16_130951_create_hpc_outcome_entity_jnt_table',1),(182,'2026_01_16_131706_create_hpc_outcome_question_jnt_table',1),(183,'2026_01_16_132414_create_hpc_knowledge_graph_validation_table',1),(184,'2026_01_16_132847_create_hpc_topic_equivalency_table',1),(185,'2026_01_16_133507_create_hpc_syllabus_coverage_snapshot_table',1),(186,'2026_01_16_134552_create_hpc_hpc_parameters_table',1),(187,'2026_01_16_134940_create_hpc_hpc_levels_table',1),(188,'2026_01_23_123646_create_qns_question_usage_type_table',1),(189,'2026_01_27_071025_create_lms_difficulty_distribution_configs_table',1),(190,'2026_01_27_071156_create_lms_difficulty_distribution_details_table',1),(191,'2026_01_27_071310_create_lms_assessment_types_table',1),(192,'2026_01_27_071355_create_lms_quizzes_table',1),(193,'2026_01_27_071620_create_lms_quiz_questions_table',1),(194,'2026_01_27_071645_create_lms_quiz_allocations_table',1),(195,'2026_01_27_185253_create_learning_activity_types_table',1),(196,'2026_01_27_185535_create_hpc_performance_descriptors_table',1),(197,'2026_01_27_185806_create_student_hpc_snapshots_table',1),(198,'2026_01_28_135321_create_hpc_student_hpc_evaluation_table',1),(199,'2026_01_28_140136_create_hpc_learning_activities_table',1),(200,'2026_01_29_170415_create_lms_quests_table',1),(201,'2026_01_29_170422_create_lms_quest_scopes_table',1),(202,'2026_01_29_170432_create_lms_quest_questions_table',1),(203,'2026_01_29_170440_create_lms_quest_allocations_table',1);
/*!40000 ALTER TABLE `migrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ml_model_features`
--

DROP TABLE IF EXISTS `ml_model_features`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ml_model_features`
--

LOCK TABLES `ml_model_features` WRITE;
/*!40000 ALTER TABLE `ml_model_features` DISABLE KEYS */;
/*!40000 ALTER TABLE `ml_model_features` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ml_models`
--

DROP TABLE IF EXISTS `ml_models`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ml_models`
--

LOCK TABLES `ml_models` WRITE;
/*!40000 ALTER TABLE `ml_models` DISABLE KEYS */;
/*!40000 ALTER TABLE `ml_models` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ntf_channel_master`
--

DROP TABLE IF EXISTS `ntf_channel_master`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ntf_channel_master`
--

LOCK TABLES `ntf_channel_master` WRITE;
/*!40000 ALTER TABLE `ntf_channel_master` DISABLE KEYS */;
/*!40000 ALTER TABLE `ntf_channel_master` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ntf_notification_channels`
--

DROP TABLE IF EXISTS `ntf_notification_channels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ntf_notification_channels`
--

LOCK TABLES `ntf_notification_channels` WRITE;
/*!40000 ALTER TABLE `ntf_notification_channels` DISABLE KEYS */;
/*!40000 ALTER TABLE `ntf_notification_channels` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ntf_notification_delivery_logs`
--

DROP TABLE IF EXISTS `ntf_notification_delivery_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ntf_notification_delivery_logs`
--

LOCK TABLES `ntf_notification_delivery_logs` WRITE;
/*!40000 ALTER TABLE `ntf_notification_delivery_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `ntf_notification_delivery_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ntf_notification_targets`
--

DROP TABLE IF EXISTS `ntf_notification_targets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ntf_notification_targets`
--

LOCK TABLES `ntf_notification_targets` WRITE;
/*!40000 ALTER TABLE `ntf_notification_targets` DISABLE KEYS */;
/*!40000 ALTER TABLE `ntf_notification_targets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ntf_notification_templates`
--

DROP TABLE IF EXISTS `ntf_notification_templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ntf_notification_templates`
--

LOCK TABLES `ntf_notification_templates` WRITE;
/*!40000 ALTER TABLE `ntf_notification_templates` DISABLE KEYS */;
/*!40000 ALTER TABLE `ntf_notification_templates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ntf_notifications`
--

DROP TABLE IF EXISTS `ntf_notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ntf_notifications`
--

LOCK TABLES `ntf_notifications` WRITE;
/*!40000 ALTER TABLE `ntf_notifications` DISABLE KEYS */;
/*!40000 ALTER TABLE `ntf_notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ntf_user_preferences`
--

DROP TABLE IF EXISTS `ntf_user_preferences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ntf_user_preferences`
--

LOCK TABLES `ntf_user_preferences` WRITE;
/*!40000 ALTER TABLE `ntf_user_preferences` DISABLE KEYS */;
/*!40000 ALTER TABLE `ntf_user_preferences` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `password_reset_tokens`
--

DROP TABLE IF EXISTS `password_reset_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `password_reset_tokens`
--

LOCK TABLES `password_reset_tokens` WRITE;
/*!40000 ALTER TABLE `password_reset_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `password_reset_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `personal_access_tokens`
--

DROP TABLE IF EXISTS `personal_access_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `personal_access_tokens`
--

LOCK TABLES `personal_access_tokens` WRITE;
/*!40000 ALTER TABLE `personal_access_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `personal_access_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `prm_billing_cycles`
--

DROP TABLE IF EXISTS `prm_billing_cycles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `prm_billing_cycles`
--

LOCK TABLES `prm_billing_cycles` WRITE;
/*!40000 ALTER TABLE `prm_billing_cycles` DISABLE KEYS */;
/*!40000 ALTER TABLE `prm_billing_cycles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qns_media_store`
--

DROP TABLE IF EXISTS `qns_media_store`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `qns_media_store`
--

LOCK TABLES `qns_media_store` WRITE;
/*!40000 ALTER TABLE `qns_media_store` DISABLE KEYS */;
/*!40000 ALTER TABLE `qns_media_store` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qns_question_media_jnt`
--

DROP TABLE IF EXISTS `qns_question_media_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `qns_question_media_jnt`
--

LOCK TABLES `qns_question_media_jnt` WRITE;
/*!40000 ALTER TABLE `qns_question_media_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `qns_question_media_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qns_question_options`
--

DROP TABLE IF EXISTS `qns_question_options`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `qns_question_options`
--

LOCK TABLES `qns_question_options` WRITE;
/*!40000 ALTER TABLE `qns_question_options` DISABLE KEYS */;
/*!40000 ALTER TABLE `qns_question_options` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qns_question_performance_category_jnt`
--

DROP TABLE IF EXISTS `qns_question_performance_category_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `qns_question_performance_category_jnt`
--

LOCK TABLES `qns_question_performance_category_jnt` WRITE;
/*!40000 ALTER TABLE `qns_question_performance_category_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `qns_question_performance_category_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qns_question_questiontag_jnt`
--

DROP TABLE IF EXISTS `qns_question_questiontag_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `qns_question_questiontag_jnt`
--

LOCK TABLES `qns_question_questiontag_jnt` WRITE;
/*!40000 ALTER TABLE `qns_question_questiontag_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `qns_question_questiontag_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qns_question_statistics`
--

DROP TABLE IF EXISTS `qns_question_statistics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `qns_question_statistics`
--

LOCK TABLES `qns_question_statistics` WRITE;
/*!40000 ALTER TABLE `qns_question_statistics` DISABLE KEYS */;
/*!40000 ALTER TABLE `qns_question_statistics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qns_question_tags`
--

DROP TABLE IF EXISTS `qns_question_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `qns_question_tags`
--

LOCK TABLES `qns_question_tags` WRITE;
/*!40000 ALTER TABLE `qns_question_tags` DISABLE KEYS */;
/*!40000 ALTER TABLE `qns_question_tags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qns_question_topic_jnt`
--

DROP TABLE IF EXISTS `qns_question_topic_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `qns_question_topic_jnt`
--

LOCK TABLES `qns_question_topic_jnt` WRITE;
/*!40000 ALTER TABLE `qns_question_topic_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `qns_question_topic_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qns_question_usage_log`
--

DROP TABLE IF EXISTS `qns_question_usage_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `qns_question_usage_log`
--

LOCK TABLES `qns_question_usage_log` WRITE;
/*!40000 ALTER TABLE `qns_question_usage_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `qns_question_usage_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qns_question_usage_type`
--

DROP TABLE IF EXISTS `qns_question_usage_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `qns_question_usage_type`
--

LOCK TABLES `qns_question_usage_type` WRITE;
/*!40000 ALTER TABLE `qns_question_usage_type` DISABLE KEYS */;
/*!40000 ALTER TABLE `qns_question_usage_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qns_question_versions`
--

DROP TABLE IF EXISTS `qns_question_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `qns_question_versions`
--

LOCK TABLES `qns_question_versions` WRITE;
/*!40000 ALTER TABLE `qns_question_versions` DISABLE KEYS */;
/*!40000 ALTER TABLE `qns_question_versions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qns_questions_bank`
--

DROP TABLE IF EXISTS `qns_questions_bank`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `qns_questions_bank`
--

LOCK TABLES `qns_questions_bank` WRITE;
/*!40000 ALTER TABLE `qns_questions_bank` DISABLE KEYS */;
/*!40000 ALTER TABLE `qns_questions_bank` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_board_organization_jnt`
--

DROP TABLE IF EXISTS `sch_board_organization_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_board_organization_jnt`
--

LOCK TABLES `sch_board_organization_jnt` WRITE;
/*!40000 ALTER TABLE `sch_board_organization_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `sch_board_organization_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_buildings`
--

DROP TABLE IF EXISTS `sch_buildings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_buildings`
--

LOCK TABLES `sch_buildings` WRITE;
/*!40000 ALTER TABLE `sch_buildings` DISABLE KEYS */;
INSERT INTO `sch_buildings` VALUES (1,'A','BLD-A','Building A',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07');
/*!40000 ALTER TABLE `sch_buildings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_class_groups`
--

DROP TABLE IF EXISTS `sch_class_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_class_groups`
--

LOCK TABLES `sch_class_groups` WRITE;
/*!40000 ALTER TABLE `sch_class_groups` DISABLE KEYS */;
/*!40000 ALTER TABLE `sch_class_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_class_groups_jnt`
--

DROP TABLE IF EXISTS `sch_class_groups_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_class_groups_jnt`
--

LOCK TABLES `sch_class_groups_jnt` WRITE;
/*!40000 ALTER TABLE `sch_class_groups_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `sch_class_groups_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_class_section_jnt`
--

DROP TABLE IF EXISTS `sch_class_section_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_class_section_jnt`
--

LOCK TABLES `sch_class_section_jnt` WRITE;
/*!40000 ALTER TABLE `sch_class_section_jnt` DISABLE KEYS */;
INSERT INTO `sch_class_section_jnt` VALUES (1,1,1,5,8,'06-A',40,0,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(2,1,2,5,8,'06-B',40,0,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(3,2,1,5,8,'07-A',40,0,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(4,2,2,5,8,'07-B',40,0,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL);
/*!40000 ALTER TABLE `sch_class_section_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_classes`
--

DROP TABLE IF EXISTS `sch_classes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_classes`
--

LOCK TABLES `sch_classes` WRITE;
/*!40000 ALTER TABLE `sch_classes` DISABLE KEYS */;
INSERT INTO `sch_classes` VALUES (1,'Class VI','VI',9,'06',1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(2,'Class VII','VII',10,'07',1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL);
/*!40000 ALTER TABLE `sch_classes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_department`
--

DROP TABLE IF EXISTS `sch_department`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_department`
--

LOCK TABLES `sch_department` WRITE;
/*!40000 ALTER TABLE `sch_department` DISABLE KEYS */;
/*!40000 ALTER TABLE `sch_department` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_designation`
--

DROP TABLE IF EXISTS `sch_designation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_designation`
--

LOCK TABLES `sch_designation` WRITE;
/*!40000 ALTER TABLE `sch_designation` DISABLE KEYS */;
/*!40000 ALTER TABLE `sch_designation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_entity_groups`
--

DROP TABLE IF EXISTS `sch_entity_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_entity_groups`
--

LOCK TABLES `sch_entity_groups` WRITE;
/*!40000 ALTER TABLE `sch_entity_groups` DISABLE KEYS */;
/*!40000 ALTER TABLE `sch_entity_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_entity_groups_members`
--

DROP TABLE IF EXISTS `sch_entity_groups_members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_entity_groups_members`
--

LOCK TABLES `sch_entity_groups_members` WRITE;
/*!40000 ALTER TABLE `sch_entity_groups_members` DISABLE KEYS */;
/*!40000 ALTER TABLE `sch_entity_groups_members` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_org_academic_sessions_jnt`
--

DROP TABLE IF EXISTS `sch_org_academic_sessions_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_org_academic_sessions_jnt`
--

LOCK TABLES `sch_org_academic_sessions_jnt` WRITE;
/*!40000 ALTER TABLE `sch_org_academic_sessions_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `sch_org_academic_sessions_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_organizations`
--

DROP TABLE IF EXISTS `sch_organizations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_organizations`
--

LOCK TABLES `sch_organizations` WRITE;
/*!40000 ALTER TABLE `sch_organizations` DISABLE KEYS */;
INSERT INTO `sch_organizations` VALUES (1,'51b5ee16-d582-4568-ab8f-d4137106c752','1','Test School','Test School','TEST001','Test School','Test School Tenant','UD123456','AFF123','test@tenant.com','https://testtenant.com','Address Line 1','Address Line 2','City Area',1,'000000','9999999999',NULL,'9999999999',77.1234567,31.1234567,'en_IN','INR','2021-02-01',1,1,NULL,'2026-02-01 06:03:00','2026-02-01 06:03:00');
/*!40000 ALTER TABLE `sch_organizations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_rooms`
--

DROP TABLE IF EXISTS `sch_rooms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_rooms`
--

LOCK TABLES `sch_rooms` WRITE;
/*!40000 ALTER TABLE `sch_rooms` DISABLE KEYS */;
INSERT INTO `sch_rooms` VALUES (1,1,3,'HALL-01-01','HALL-01-01','Computer Laboratory 1',20,26,'Computer Lab,FLOOR-2',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(2,1,3,'LAB-01-02','LAB-01-02','Computer Laboratory 2',53,63,'Computer Lab,FLOOR-3',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(3,1,8,'HALL-01-03','HALL-01-03','Library & Reading Room 3',51,32,'Library,FLOOR-1',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(4,1,7,'LAB-01-04','LAB-01-04','Sports & Playground Area 4',42,31,'Sports Area,FLOOR-3',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07');
/*!40000 ALTER TABLE `sch_rooms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_rooms_type`
--

DROP TABLE IF EXISTS `sch_rooms_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_rooms_type`
--

LOCK TABLES `sch_rooms_type` WRITE;
/*!40000 ALTER TABLE `sch_rooms_type` DISABLE KEYS */;
INSERT INTO `sch_rooms_type` VALUES (1,'CLASSRM','Classroom','Standard Classroom','theory,lecture,regular',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(2,'SCI_LAB','Science Lab','Science Laboratory','science,practical,physics,chemistry,biology',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(3,'COMP_LB','Computer Lab','Computer Laboratory','computer,practical,it',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(4,'MATH_LB','Math Lab','Mathematics Laboratory','math,activity',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(5,'MUSICRM','Music Room','Music Room','music,vocal,instrument',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(6,'ART_RM','Art Room','Art & Craft Room','art,craft,drawing',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(7,'SPORTS','Sports Area','Sports & Playground Area','sports,pt,games,physical',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(8,'LIBRARY','Library','Library & Reading Room','library,reading,quiet',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(9,'ACT_RM','Activity Room','Multi-purpose Activity Room','activity,club,value-education',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07');
/*!40000 ALTER TABLE `sch_rooms_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_sections`
--

DROP TABLE IF EXISTS `sch_sections`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_sections`
--

LOCK TABLES `sch_sections` WRITE;
/*!40000 ALTER TABLE `sch_sections` DISABLE KEYS */;
INSERT INTO `sch_sections` VALUES (1,'A',1,'A',1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(2,'B',2,'B',1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL);
/*!40000 ALTER TABLE `sch_sections` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_study_formats`
--

DROP TABLE IF EXISTS `sch_study_formats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_study_formats`
--

LOCK TABLES `sch_study_formats` WRITE;
/*!40000 ALTER TABLE `sch_study_formats` DISABLE KEYS */;
INSERT INTO `sch_study_formats` VALUES (1,'TH','Theory','Theory',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(2,'PR','Practical','Practical',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(3,'LAB','Lab / Activity','Lab',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(4,'LIB','Library','Library',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(5,'ART','Art','Art',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(6,'SPT','Sports','Sports',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(7,'HOB','Hobby','Hobby',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08');
/*!40000 ALTER TABLE `sch_study_formats` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_subject_group_subject_jnt`
--

DROP TABLE IF EXISTS `sch_subject_group_subject_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_subject_group_subject_jnt`
--

LOCK TABLES `sch_subject_group_subject_jnt` WRITE;
/*!40000 ALTER TABLE `sch_subject_group_subject_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `sch_subject_group_subject_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_subject_groups`
--

DROP TABLE IF EXISTS `sch_subject_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_subject_groups`
--

LOCK TABLES `sch_subject_groups` WRITE;
/*!40000 ALTER TABLE `sch_subject_groups` DISABLE KEYS */;
/*!40000 ALTER TABLE `sch_subject_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_subject_study_format_jnt`
--

DROP TABLE IF EXISTS `sch_subject_study_format_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_subject_study_format_jnt`
--

LOCK TABLES `sch_subject_study_format_jnt` WRITE;
/*!40000 ALTER TABLE `sch_subject_study_format_jnt` DISABLE KEYS */;
INSERT INTO `sch_subject_study_format_jnt` VALUES (1,1,1,'English Theory','ENG-TH',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(2,2,1,'Hindi Theory','HIN-TH',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(3,3,1,'Maths Theory','MAT-TH',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(4,4,1,'Social Science Theory','SOC-TH',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(5,5,1,'Sanskrit Theory','SAN-TH',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(6,6,1,'Science Theory','SCI-TH',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(7,7,1,'G.K. Theory','GK-TH',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(8,8,1,'Computer Science Theory','COMP-TH',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(9,8,2,'Computer Science Practical','COMP-PR',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(10,9,1,'French Theory','FRE-TH',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(11,10,4,'Library Library','LIB-LIB',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(12,11,1,'Value Education Theory','VAL-TH',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(13,12,5,'Art Art','ART-ART',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(14,13,6,'Games Sports','GAM-SPT',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(15,14,1,'English Novel Theory','ENGN-TH',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(16,15,3,'Robotics Lab / Activity','ROB-LAB',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(17,16,3,'Astro Lab / Activity','AST-LAB',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(18,17,7,'Hobby Hobby','HOB-HOB',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08');
/*!40000 ALTER TABLE `sch_subject_study_format_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_subject_teachers`
--

DROP TABLE IF EXISTS `sch_subject_teachers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_subject_teachers`
--

LOCK TABLES `sch_subject_teachers` WRITE;
/*!40000 ALTER TABLE `sch_subject_teachers` DISABLE KEYS */;
INSERT INTO `sch_subject_teachers` VALUES (1,4,1,1,'PRIMARY',65,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(2,1,1,1,'SECONDARY',67,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(3,5,2,2,'PRIMARY',66,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(4,4,2,2,'SECONDARY',55,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(5,3,2,2,'SECONDARY',76,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(6,3,3,3,'PRIMARY',70,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(7,1,3,3,'SECONDARY',59,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(8,5,3,3,'SECONDARY',85,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(9,4,4,4,'PRIMARY',59,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(10,5,4,4,'SECONDARY',75,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(11,2,4,4,'SECONDARY',89,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(12,3,5,5,'PRIMARY',60,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(13,4,5,5,'SECONDARY',71,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(14,1,5,5,'SECONDARY',82,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(15,5,6,6,'PRIMARY',91,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(16,1,6,6,'SECONDARY',74,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(17,4,6,6,'SECONDARY',56,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(18,5,7,7,'PRIMARY',61,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(19,4,7,7,'SECONDARY',90,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(20,4,8,8,'PRIMARY',59,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(21,3,8,8,'SECONDARY',71,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(22,1,8,8,'SECONDARY',95,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(23,2,8,9,'PRIMARY',70,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(24,4,8,9,'SECONDARY',73,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(25,5,8,9,'SECONDARY',89,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(26,4,9,10,'PRIMARY',51,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(27,3,9,10,'SECONDARY',84,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(28,2,10,11,'PRIMARY',71,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(29,3,10,11,'SECONDARY',75,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(30,1,10,11,'SECONDARY',73,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(31,4,11,12,'PRIMARY',67,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(32,3,11,12,'SECONDARY',89,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(33,5,11,12,'SECONDARY',76,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(34,5,12,13,'PRIMARY',95,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(35,4,12,13,'SECONDARY',80,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(36,1,12,13,'SECONDARY',80,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(37,2,13,14,'PRIMARY',70,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(38,3,13,14,'SECONDARY',87,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(39,5,13,14,'SECONDARY',56,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(40,1,14,15,'PRIMARY',56,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(41,4,14,15,'SECONDARY',66,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(42,5,14,15,'SECONDARY',67,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(43,5,15,16,'PRIMARY',66,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(44,1,15,16,'SECONDARY',92,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(45,4,16,17,'PRIMARY',87,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(46,1,16,17,'SECONDARY',85,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(47,5,16,17,'SECONDARY',70,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(48,1,17,18,'PRIMARY',72,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(49,5,17,18,'SECONDARY',60,'Auto-seeded subject eligibility','2026-02-01',NULL,1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09');
/*!40000 ALTER TABLE `sch_subject_teachers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_subject_types`
--

DROP TABLE IF EXISTS `sch_subject_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_subject_types`
--

LOCK TABLES `sch_subject_types` WRITE;
/*!40000 ALTER TABLE `sch_subject_types` DISABLE KEYS */;
INSERT INTO `sch_subject_types` VALUES (1,'Major','Major Subject','MAJ',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(2,'Minor','Minor Subject','MIN',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(3,'Optional','Optional Subject','OPT',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(4,'Elective','Elective Subject','ELE',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(5,'Co-curricular','Co-curricular Activity','COA',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08');
/*!40000 ALTER TABLE `sch_subject_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_subjects`
--

DROP TABLE IF EXISTS `sch_subjects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_subjects`
--

LOCK TABLES `sch_subjects` WRITE;
/*!40000 ALTER TABLE `sch_subjects` DISABLE KEYS */;
INSERT INTO `sch_subjects` VALUES (1,'ENG','English','ENG',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(2,'HIN','Hindi','HIN',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(3,'MAT','Maths','MAT',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(4,'SOC','Social Science','SOC',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(5,'SAN','Sanskrit','SAN',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(6,'SCI','Science','SCI',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(7,'GK','G.K.','GK',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(8,'COMP','Computer Science','COMP',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(9,'FRE','French','FRE',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(10,'LIB','Library','LIB',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(11,'VAL','Value Education','VAL',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(12,'ART','Art','ART',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(13,'GAM','Games','GAM',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(14,'ENGN','English Novel','ENGN',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(15,'ROB','Robotics','ROB',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(16,'AST','Astro','AST',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08'),(17,'HOB','Hobby','HOB',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08');
/*!40000 ALTER TABLE `sch_subjects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_teachers`
--

DROP TABLE IF EXISTS `sch_teachers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_teachers`
--

LOCK TABLES `sch_teachers` WRITE;
/*!40000 ALTER TABLE `sch_teachers` DISABLE KEYS */;
INSERT INTO `sch_teachers` VALUES (1,5,'2021-02-01',12.0,'Graduate','General','Auto Seeded School',NULL,'Teaching, Classroom Management',NULL,NULL,NULL,'Auto-created from Teacher role user',NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(2,6,'2025-02-01',9.0,'Graduate','General','Auto Seeded School',NULL,'Teaching, Classroom Management',NULL,NULL,NULL,'Auto-created from Teacher role user',NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(3,7,'2025-02-01',1.0,'Graduate','General','Auto Seeded School',NULL,'Teaching, Classroom Management',NULL,NULL,NULL,'Auto-created from Teacher role user',NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(4,8,'2018-02-01',1.0,'Graduate','General','Auto Seeded School',NULL,'Teaching, Classroom Management',NULL,NULL,NULL,'Auto-created from Teacher role user',NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(5,9,'2017-02-01',18.0,'Graduate','General','Auto Seeded School',NULL,'Teaching, Classroom Management',NULL,NULL,NULL,'Auto-created from Teacher role user',NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09');
/*!40000 ALTER TABLE `sch_teachers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_teachers_profile`
--

DROP TABLE IF EXISTS `sch_teachers_profile`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_teachers_profile`
--

LOCK TABLES `sch_teachers_profile` WRITE;
/*!40000 ALTER TABLE `sch_teachers_profile` DISABLE KEYS */;
/*!40000 ALTER TABLE `sch_teachers_profile` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `schedule_runs`
--

DROP TABLE IF EXISTS `schedule_runs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `schedule_runs`
--

LOCK TABLES `schedule_runs` WRITE;
/*!40000 ALTER TABLE `schedule_runs` DISABLE KEYS */;
/*!40000 ALTER TABLE `schedule_runs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `schedules`
--

DROP TABLE IF EXISTS `schedules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `schedules`
--

LOCK TABLES `schedules` WRITE;
/*!40000 ALTER TABLE `schedules` DISABLE KEYS */;
/*!40000 ALTER TABLE `schedules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `school_timing_profiles`
--

DROP TABLE IF EXISTS `school_timing_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `school_timing_profiles`
--

LOCK TABLES `school_timing_profiles` WRITE;
/*!40000 ALTER TABLE `school_timing_profiles` DISABLE KEYS */;
/*!40000 ALTER TABLE `school_timing_profiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sessions`
--

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
INSERT INTO `sessions` VALUES ('BspOQp0PdbOcIMdYuEIILELMnindN9somEAWu6Th',2,'127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0','YTo3OntzOjY6Il90b2tlbiI7czo0MDoiT3paVENiQlV0TXJ1SHdqenN1Sjk3SFJ6dkpuZHVCb3h2SWM3elIxYSI7czozOiJ1cmwiO2E6MDp7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjc1OiJodHRwOi8vdGVzdC5sb2NhbGhvc3Q6ODAwMC9zbWFydC10aW1ldGFibGUvc21hcnQtdGltZXRhYmxlL3RpbWV0YWJsZS1tYXN0ZXIiO3M6NToicm91dGUiO3M6NDE6InNtYXJ0LXRpbWV0YWJsZS50aW1ldGFibGUudGltZXRhYmxlTWFzdGVyIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjE5OiJhY3RpdmVfbWFpbl9tZW51X2lkIjtpOjQ3O3M6MjI6IlBIUERFQlVHQkFSX1NUQUNLX0RBVEEiO2E6MDp7fX0=',1769925930);
/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_author_books_jnt`
--

DROP TABLE IF EXISTS `slb_author_books_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_author_books_jnt`
--

LOCK TABLES `slb_author_books_jnt` WRITE;
/*!40000 ALTER TABLE `slb_author_books_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_author_books_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_bloom_taxonomy`
--

DROP TABLE IF EXISTS `slb_bloom_taxonomy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_bloom_taxonomy`
--

LOCK TABLES `slb_bloom_taxonomy` WRITE;
/*!40000 ALTER TABLE `slb_bloom_taxonomy` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_bloom_taxonomy` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_book_author_jnt`
--

DROP TABLE IF EXISTS `slb_book_author_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_book_author_jnt`
--

LOCK TABLES `slb_book_author_jnt` WRITE;
/*!40000 ALTER TABLE `slb_book_author_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_book_author_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_book_authors`
--

DROP TABLE IF EXISTS `slb_book_authors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_book_authors`
--

LOCK TABLES `slb_book_authors` WRITE;
/*!40000 ALTER TABLE `slb_book_authors` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_book_authors` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_book_class_subject_jnt`
--

DROP TABLE IF EXISTS `slb_book_class_subject_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_book_class_subject_jnt`
--

LOCK TABLES `slb_book_class_subject_jnt` WRITE;
/*!40000 ALTER TABLE `slb_book_class_subject_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_book_class_subject_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_book_topic_mapping`
--

DROP TABLE IF EXISTS `slb_book_topic_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_book_topic_mapping`
--

LOCK TABLES `slb_book_topic_mapping` WRITE;
/*!40000 ALTER TABLE `slb_book_topic_mapping` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_book_topic_mapping` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_books`
--

DROP TABLE IF EXISTS `slb_books`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_books`
--

LOCK TABLES `slb_books` WRITE;
/*!40000 ALTER TABLE `slb_books` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_books` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_cognitive_skill`
--

DROP TABLE IF EXISTS `slb_cognitive_skill`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_cognitive_skill`
--

LOCK TABLES `slb_cognitive_skill` WRITE;
/*!40000 ALTER TABLE `slb_cognitive_skill` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_cognitive_skill` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_competencies`
--

DROP TABLE IF EXISTS `slb_competencies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_competencies`
--

LOCK TABLES `slb_competencies` WRITE;
/*!40000 ALTER TABLE `slb_competencies` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_competencies` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_competency_types`
--

DROP TABLE IF EXISTS `slb_competency_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_competency_types`
--

LOCK TABLES `slb_competency_types` WRITE;
/*!40000 ALTER TABLE `slb_competency_types` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_competency_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_complexity_levels`
--

DROP TABLE IF EXISTS `slb_complexity_levels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_complexity_levels`
--

LOCK TABLES `slb_complexity_levels` WRITE;
/*!40000 ALTER TABLE `slb_complexity_levels` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_complexity_levels` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_grade_division_master`
--

DROP TABLE IF EXISTS `slb_grade_division_master`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_grade_division_master`
--

LOCK TABLES `slb_grade_division_master` WRITE;
/*!40000 ALTER TABLE `slb_grade_division_master` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_grade_division_master` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_lessons`
--

DROP TABLE IF EXISTS `slb_lessons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_lessons`
--

LOCK TABLES `slb_lessons` WRITE;
/*!40000 ALTER TABLE `slb_lessons` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_lessons` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_performance_categories`
--

DROP TABLE IF EXISTS `slb_performance_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_performance_categories`
--

LOCK TABLES `slb_performance_categories` WRITE;
/*!40000 ALTER TABLE `slb_performance_categories` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_performance_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_ques_type_specificity`
--

DROP TABLE IF EXISTS `slb_ques_type_specificity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_ques_type_specificity`
--

LOCK TABLES `slb_ques_type_specificity` WRITE;
/*!40000 ALTER TABLE `slb_ques_type_specificity` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_ques_type_specificity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_question_types`
--

DROP TABLE IF EXISTS `slb_question_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_question_types`
--

LOCK TABLES `slb_question_types` WRITE;
/*!40000 ALTER TABLE `slb_question_types` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_question_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_study_material_types`
--

DROP TABLE IF EXISTS `slb_study_material_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_study_material_types`
--

LOCK TABLES `slb_study_material_types` WRITE;
/*!40000 ALTER TABLE `slb_study_material_types` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_study_material_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_study_materials`
--

DROP TABLE IF EXISTS `slb_study_materials`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_study_materials`
--

LOCK TABLES `slb_study_materials` WRITE;
/*!40000 ALTER TABLE `slb_study_materials` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_study_materials` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_syllabus_schedule`
--

DROP TABLE IF EXISTS `slb_syllabus_schedule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_syllabus_schedule`
--

LOCK TABLES `slb_syllabus_schedule` WRITE;
/*!40000 ALTER TABLE `slb_syllabus_schedule` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_syllabus_schedule` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_topic_competency_jnt`
--

DROP TABLE IF EXISTS `slb_topic_competency_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_topic_competency_jnt`
--

LOCK TABLES `slb_topic_competency_jnt` WRITE;
/*!40000 ALTER TABLE `slb_topic_competency_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_topic_competency_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_topic_dependencies`
--

DROP TABLE IF EXISTS `slb_topic_dependencies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_topic_dependencies`
--

LOCK TABLES `slb_topic_dependencies` WRITE;
/*!40000 ALTER TABLE `slb_topic_dependencies` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_topic_dependencies` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slb_topics`
--

DROP TABLE IF EXISTS `slb_topics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slb_topics`
--

LOCK TABLES `slb_topics` WRITE;
/*!40000 ALTER TABLE `slb_topics` DISABLE KEYS */;
/*!40000 ALTER TABLE `slb_topics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `std_attendance_corrections`
--

DROP TABLE IF EXISTS `std_attendance_corrections`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `std_attendance_corrections`
--

LOCK TABLES `std_attendance_corrections` WRITE;
/*!40000 ALTER TABLE `std_attendance_corrections` DISABLE KEYS */;
/*!40000 ALTER TABLE `std_attendance_corrections` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `std_guardians`
--

DROP TABLE IF EXISTS `std_guardians`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `std_guardians`
--

LOCK TABLES `std_guardians` WRITE;
/*!40000 ALTER TABLE `std_guardians` DISABLE KEYS */;
/*!40000 ALTER TABLE `std_guardians` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `std_health_profiles`
--

DROP TABLE IF EXISTS `std_health_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `std_health_profiles`
--

LOCK TABLES `std_health_profiles` WRITE;
/*!40000 ALTER TABLE `std_health_profiles` DISABLE KEYS */;
/*!40000 ALTER TABLE `std_health_profiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `std_medical_incidents`
--

DROP TABLE IF EXISTS `std_medical_incidents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `std_medical_incidents`
--

LOCK TABLES `std_medical_incidents` WRITE;
/*!40000 ALTER TABLE `std_medical_incidents` DISABLE KEYS */;
/*!40000 ALTER TABLE `std_medical_incidents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `std_previous_education`
--

DROP TABLE IF EXISTS `std_previous_education`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `std_previous_education`
--

LOCK TABLES `std_previous_education` WRITE;
/*!40000 ALTER TABLE `std_previous_education` DISABLE KEYS */;
/*!40000 ALTER TABLE `std_previous_education` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `std_student_academic_sessions`
--

DROP TABLE IF EXISTS `std_student_academic_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `std_student_academic_sessions`
--

LOCK TABLES `std_student_academic_sessions` WRITE;
/*!40000 ALTER TABLE `std_student_academic_sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `std_student_academic_sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `std_student_addresses`
--

DROP TABLE IF EXISTS `std_student_addresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `std_student_addresses`
--

LOCK TABLES `std_student_addresses` WRITE;
/*!40000 ALTER TABLE `std_student_addresses` DISABLE KEYS */;
/*!40000 ALTER TABLE `std_student_addresses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `std_student_attendance`
--

DROP TABLE IF EXISTS `std_student_attendance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `std_student_attendance`
--

LOCK TABLES `std_student_attendance` WRITE;
/*!40000 ALTER TABLE `std_student_attendance` DISABLE KEYS */;
/*!40000 ALTER TABLE `std_student_attendance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `std_student_detail`
--

DROP TABLE IF EXISTS `std_student_detail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `std_student_detail`
--

LOCK TABLES `std_student_detail` WRITE;
/*!40000 ALTER TABLE `std_student_detail` DISABLE KEYS */;
/*!40000 ALTER TABLE `std_student_detail` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `std_student_documents`
--

DROP TABLE IF EXISTS `std_student_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `std_student_documents`
--

LOCK TABLES `std_student_documents` WRITE;
/*!40000 ALTER TABLE `std_student_documents` DISABLE KEYS */;
/*!40000 ALTER TABLE `std_student_documents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `std_student_guardian_jnt`
--

DROP TABLE IF EXISTS `std_student_guardian_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `std_student_guardian_jnt`
--

LOCK TABLES `std_student_guardian_jnt` WRITE;
/*!40000 ALTER TABLE `std_student_guardian_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `std_student_guardian_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `std_student_pay_log`
--

DROP TABLE IF EXISTS `std_student_pay_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `std_student_pay_log`
--

LOCK TABLES `std_student_pay_log` WRITE;
/*!40000 ALTER TABLE `std_student_pay_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `std_student_pay_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `std_student_profiles`
--

DROP TABLE IF EXISTS `std_student_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `std_student_profiles`
--

LOCK TABLES `std_student_profiles` WRITE;
/*!40000 ALTER TABLE `std_student_profiles` DISABLE KEYS */;
/*!40000 ALTER TABLE `std_student_profiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `std_students`
--

DROP TABLE IF EXISTS `std_students`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `std_students`
--

LOCK TABLES `std_students` WRITE;
/*!40000 ALTER TABLE `std_students` DISABLE KEYS */;
/*!40000 ALTER TABLE `std_students` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `std_vaccination_records`
--

DROP TABLE IF EXISTS `std_vaccination_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `std_vaccination_records`
--

LOCK TABLES `std_vaccination_records` WRITE;
/*!40000 ALTER TABLE `std_vaccination_records` DISABLE KEYS */;
/*!40000 ALTER TABLE `std_vaccination_records` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `subject_group_subject`
--

DROP TABLE IF EXISTS `subject_group_subject`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subject_group_subject`
--

LOCK TABLES `subject_group_subject` WRITE;
/*!40000 ALTER TABLE `subject_group_subject` DISABLE KEYS */;
/*!40000 ALTER TABLE `subject_group_subject` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_activity_logs`
--

DROP TABLE IF EXISTS `sys_activity_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_activity_logs`
--

LOCK TABLES `sys_activity_logs` WRITE;
/*!40000 ALTER TABLE `sys_activity_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `sys_activity_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_dropdown_needs`
--

DROP TABLE IF EXISTS `sys_dropdown_needs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_dropdown_needs`
--

LOCK TABLES `sys_dropdown_needs` WRITE;
/*!40000 ALTER TABLE `sys_dropdown_needs` DISABLE KEYS */;
INSERT INTO `sys_dropdown_needs` VALUES (1,'Global','dummy_table_name','dummy_column_name',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(2,'Global','bil_tenant_invoices','status',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(3,'Global','bil_tenant_invoicing_payments','mode',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(4,'Global','bil_tenant_invoicing_payments','payment_status',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(5,'Global','cmp_medical_checks','check_type_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(6,'Global','cmp_medical_checks','result',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(7,'Global','tpt_vehicle_service_request','vehicle_status',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(8,'Global','tpt_vehicle','vehicle_type_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(9,'Global','tpt_vehicle','fuel_type_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(10,'Global','tpt_vehicle','ownership_type_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(11,'Global','tpt_vehicle','vehicle_emission_class_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(12,'Global','tpt_personnel','id_type',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(13,'Global','tpt_attendance_device','device_type',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(14,'Global','tpt_attendance_device','device_os',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(15,'Global','cmp_complaint_actions','action_type_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(16,'Global','sch_entity_groups','entity_purpose_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(17,'Global','sch_entity_groups','entity_purpose_id_2',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(18,'Global','vnd_vendors','vendor_type_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(19,'Global','vnd_items','category_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(20,'Global','vnd_items','unit_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(21,'Global','vnd_agreement_items_jnt','related_entity_type',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(22,'Global','vnd_invoices','status',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(23,'Global','vnd_payments','payment_mode',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(24,'Global','ntf_notifications','confidentiality_level_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(25,'Global','ntf_notifications','recurring_interval_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(26,'Global','ntf_notification_channels','provider_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(27,'Global','qns_question_performance_category_jnt','recommendation_type',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(28,'Global','qns_question_review_log','review_status_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(29,'Global','lms_homework','submission_type_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(30,'Global','lms_homework','status_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(31,'Global','lms_homework','release_condition_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(32,'Global','lms_homework_submissions','status_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(33,'Global','std_students','current_status_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(34,'Global','std_student_profiles','nationality',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(35,'Global','std_student_profiles','mother_tongue',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(36,'Global','std_student_academic_sessions','house',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(37,'Global','std_student_academic_sessions','reason_quit',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(38,'Global','std_student_documents','document_type_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(39,'Global','std_medical_incidents','incident_type_id',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(40,'Global','slb_books','language',NULL,NULL,NULL,NULL,NULL,1,0,1,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07');
/*!40000 ALTER TABLE `sys_dropdown_needs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_dropdowns`
--

DROP TABLE IF EXISTS `sys_dropdowns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_dropdowns`
--

LOCK TABLES `sys_dropdowns` WRITE;
/*!40000 ALTER TABLE `sys_dropdowns` DISABLE KEYS */;
INSERT INTO `sys_dropdowns` VALUES (1,1,1,'dummy_table_name.dummy_column_name.religion','Hinduism','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(2,1,2,'dummy_table_name.dummy_column_name.religion','Islam','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(3,1,3,'dummy_table_name.dummy_column_name.religion','Christianity','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(4,1,4,'dummy_table_name.dummy_column_name.religion','Sikhism','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(5,1,5,'dummy_table_name.dummy_column_name.religion','Buddhism','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(6,1,6,'dummy_table_name.dummy_column_name.religion','Jainism','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(7,1,7,'dummy_table_name.dummy_column_name.religion','Zoroastrianism','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(8,1,8,'dummy_table_name.dummy_column_name.religion','Judaism','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(9,1,1,'dummy_table_name.dummy_column_name.caste','Brahmins','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(10,1,2,'dummy_table_name.dummy_column_name.caste','Kshatriyas','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(11,1,3,'dummy_table_name.dummy_column_name.caste','Vaishyas','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(12,1,4,'dummy_table_name.dummy_column_name.caste','Shudras','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(13,1,5,'dummy_table_name.dummy_column_name.caste','Kayastha','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(14,1,6,'dummy_table_name.dummy_column_name.caste','Punjabi Khatri','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(15,1,7,'dummy_table_name.dummy_column_name.caste','Sindhi','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(16,1,8,'dummy_table_name.dummy_column_name.caste','Rajput','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(17,1,9,'dummy_table_name.dummy_column_name.caste','Jains','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(18,1,10,'dummy_table_name.dummy_column_name.caste','Parsis','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(19,1,11,'dummy_table_name.dummy_column_name.caste','Christians','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(20,1,1,'dummy_table_name.dummy_column_name.gender','Male','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(21,1,2,'dummy_table_name.dummy_column_name.gender','Female','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(22,1,3,'dummy_table_name.dummy_column_name.gender','Other','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(23,1,4,'dummy_table_name.dummy_column_name.gender','Prefer not to say','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(24,1,1,'dummy_table_name.dummy_column_name.status','Active','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(25,1,2,'dummy_table_name.dummy_column_name.status','Inactive','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(26,1,1,'dummy_table_name.dummy_column_name.blood_group','A+','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(27,1,2,'dummy_table_name.dummy_column_name.blood_group','A-','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(28,1,3,'dummy_table_name.dummy_column_name.blood_group','B+','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(29,1,4,'dummy_table_name.dummy_column_name.blood_group','B-','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(30,1,5,'dummy_table_name.dummy_column_name.blood_group','AB+','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(31,1,6,'dummy_table_name.dummy_column_name.blood_group','AB-','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(32,1,7,'dummy_table_name.dummy_column_name.blood_group','O+','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(33,1,8,'dummy_table_name.dummy_column_name.blood_group','O-','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(34,1,1,'dummy_table_name.dummy_column_name.guardian_is','Father','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(35,1,2,'dummy_table_name.dummy_column_name.guardian_is','Mother','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(36,1,3,'dummy_table_name.dummy_column_name.guardian_is','Guardian','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(37,1,1,'dummy_table_name.dummy_column_name.default_mobile','Father','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(38,1,2,'dummy_table_name.dummy_column_name.default_mobile','Mother','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(39,1,3,'dummy_table_name.dummy_column_name.default_mobile','Guardian','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(40,1,1,'dummy_table_name.dummy_column_name.default_email','Father','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(41,1,2,'dummy_table_name.dummy_column_name.default_email','Mother','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(42,1,3,'dummy_table_name.dummy_column_name.default_email','Guardian','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(43,1,1,'dummy_table_name.dummy_column_name.reason_quit','Transfer','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(44,1,2,'dummy_table_name.dummy_column_name.reason_quit','Completed','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(45,1,3,'dummy_table_name.dummy_column_name.reason_quit','Discontinued','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(46,1,4,'dummy_table_name.dummy_column_name.reason_quit','Other','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(47,1,1,'dummy_table_name.dummy_column_name.dropdown_type','String','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(48,1,2,'dummy_table_name.dummy_column_name.dropdown_type','Integer','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(49,1,3,'dummy_table_name.dummy_column_name.dropdown_type','Decimal','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(50,1,4,'dummy_table_name.dummy_column_name.dropdown_type','Date','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(51,1,5,'dummy_table_name.dummy_column_name.dropdown_type','Datetime','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(52,1,6,'dummy_table_name.dummy_column_name.dropdown_type','Time','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(53,1,7,'dummy_table_name.dummy_column_name.dropdown_type','Boolean','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(54,1,1,'dummy_table_name.dummy_column_name.severity_level','Low','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(55,1,2,'dummy_table_name.dummy_column_name.severity_level','Medium','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(56,1,3,'dummy_table_name.dummy_column_name.severity_level','High','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(57,1,4,'dummy_table_name.dummy_column_name.severity_level','Critical','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(58,1,1,'dummy_table_name.dummy_column_name.priority_score','Critical','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(59,1,2,'dummy_table_name.dummy_column_name.priority_score','Urgent','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(60,1,3,'dummy_table_name.dummy_column_name.priority_score','High','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(61,1,4,'dummy_table_name.dummy_column_name.priority_score','Medium','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(62,1,5,'dummy_table_name.dummy_column_name.priority_score','Low','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(63,1,1,'dummy_table_name.dummy_column_name.user_type','Student','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(64,1,2,'dummy_table_name.dummy_column_name.user_type','Staff','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(65,1,3,'dummy_table_name.dummy_column_name.user_type','Group','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(66,1,4,'dummy_table_name.dummy_column_name.user_type','Department','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(67,1,5,'dummy_table_name.dummy_column_name.user_type','Vendor','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(68,1,6,'dummy_table_name.dummy_column_name.user_type','Other','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(69,1,1,'dummy_table_name.dummy_column_name.complainant_type','Parent','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(70,1,2,'dummy_table_name.dummy_column_name.complainant_type','Student','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(71,1,3,'dummy_table_name.dummy_column_name.complainant_type','Staff','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(72,1,4,'dummy_table_name.dummy_column_name.complainant_type','Vendor','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(73,1,5,'dummy_table_name.dummy_column_name.complainant_type','Anonymous','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(74,1,6,'dummy_table_name.dummy_column_name.complainant_type','Public','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(75,1,1,'dummy_table_name.dummy_column_name.source','App','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(76,1,2,'dummy_table_name.dummy_column_name.source','Web','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(77,1,3,'dummy_table_name.dummy_column_name.source','Email','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(78,1,4,'dummy_table_name.dummy_column_name.source','Walk-in','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(79,1,5,'dummy_table_name.dummy_column_name.source','Call','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(80,1,1,'dummy_table_name.dummy_column_name.target_user_type','Student','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(81,1,2,'dummy_table_name.dummy_column_name.target_user_type','Staff','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(82,1,3,'dummy_table_name.dummy_column_name.target_user_type','Group','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(83,1,4,'dummy_table_name.dummy_column_name.target_user_type','Department','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(84,1,5,'dummy_table_name.dummy_column_name.target_user_type','Role','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(85,1,6,'dummy_table_name.dummy_column_name.target_user_type','Designation','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(86,1,7,'dummy_table_name.dummy_column_name.target_user_type','Facility','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(87,1,8,'dummy_table_name.dummy_column_name.target_user_type','Vehicle','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(88,1,9,'dummy_table_name.dummy_column_name.target_user_type','Event','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(89,1,10,'dummy_table_name.dummy_column_name.target_user_type','Location','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(90,1,11,'dummy_table_name.dummy_column_name.target_user_type','Vendor','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(91,1,12,'dummy_table_name.dummy_column_name.target_user_type','Other','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(92,1,1,'dummy_table_name.dummy_column_name.complaint_status','Open','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(93,1,2,'dummy_table_name.dummy_column_name.complaint_status','In-Progress','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(94,1,3,'dummy_table_name.dummy_column_name.complaint_status','Escalated','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(95,1,4,'dummy_table_name.dummy_column_name.complaint_status','Resolved','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(96,1,5,'dummy_table_name.dummy_column_name.complaint_status','Closed','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(97,1,6,'dummy_table_name.dummy_column_name.complaint_status','Rejected','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(98,1,1,'dummy_table_name.dummy_column_name.complaint_source','App','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(99,1,2,'dummy_table_name.dummy_column_name.complaint_source','Web','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(100,1,3,'dummy_table_name.dummy_column_name.complaint_source','Email','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(101,1,4,'dummy_table_name.dummy_column_name.complaint_source','Walk-in','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(102,1,5,'dummy_table_name.dummy_column_name.complaint_source','Call','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(103,1,1,'dummy_table_name.dummy_column_name.entity_type','Class','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(104,1,2,'dummy_table_name.dummy_column_name.entity_type','Section','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(105,1,3,'dummy_table_name.dummy_column_name.entity_type','Subject','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(106,1,4,'dummy_table_name.dummy_column_name.entity_type','Designation','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(107,1,5,'dummy_table_name.dummy_column_name.entity_type','Department','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(108,1,6,'dummy_table_name.dummy_column_name.entity_type','Role','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(109,1,7,'dummy_table_name.dummy_column_name.entity_type','Student','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(110,1,8,'dummy_table_name.dummy_column_name.entity_type','Staff','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(111,1,9,'dummy_table_name.dummy_column_name.entity_type','Vehicle','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(112,1,10,'dummy_table_name.dummy_column_name.entity_type','Facility','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(113,1,11,'dummy_table_name.dummy_column_name.entity_type','Event','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(114,1,12,'dummy_table_name.dummy_column_name.entity_type','Location','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(115,1,13,'dummy_table_name.dummy_column_name.entity_type','Other','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(116,1,1,'dummy_table_name.dummy_column_name.audit_status','Not Billed','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(117,1,2,'dummy_table_name.dummy_column_name.audit_status','Bill Generated','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(118,1,3,'dummy_table_name.dummy_column_name.audit_status','Overdue','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(119,1,4,'dummy_table_name.dummy_column_name.audit_status','Notice Sent','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(120,1,5,'dummy_table_name.dummy_column_name.audit_status','Partially Paid','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(121,1,6,'dummy_table_name.dummy_column_name.audit_status','Fully Paid','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(122,1,1,'dummy_table_name.dummy_column_name.sentiment_label','Angry','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(123,1,2,'dummy_table_name.dummy_column_name.sentiment_label','Urgent','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(124,1,3,'dummy_table_name.dummy_column_name.sentiment_label','Calm','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(125,1,4,'dummy_table_name.dummy_column_name.sentiment_label','Neutral','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(126,1,1,'dummy_table_name.dummy_column_name.data_type','Invoicing Done','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(127,1,2,'dummy_table_name.dummy_column_name.data_type','Inv. Need To Generate','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(128,1,1,'dummy_table_name.dummy_column_name.invoice_payment_status','PENDING','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(129,1,2,'dummy_table_name.dummy_column_name.invoice_payment_status','PARTIAL','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(130,1,3,'dummy_table_name.dummy_column_name.invoice_payment_status','PAID','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(131,2,1,'bil_tenant_invoices.status.invoice_status','PENDING','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(132,3,1,'bil_tenant_invoicing_payments.mode.payment_mode','Cash','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(133,3,2,'bil_tenant_invoicing_payments.mode.payment_mode','Bank','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(134,3,3,'bil_tenant_invoicing_payments.mode.payment_mode','Online','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(135,4,1,'bil_tenant_invoicing_payments.payment_status.payment_consolidated_status','INITIATED','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(136,4,2,'bil_tenant_invoicing_payments.payment_status.payment_consolidated_status','SUCCESS','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(137,4,3,'bil_tenant_invoicing_payments.payment_status.payment_consolidated_status','FAILED','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(138,4,4,'bil_tenant_invoicing_payments.payment_status.payment_consolidated_status','REFUNDED','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(139,5,1,'cmp_medical_checks.check_type_id.medical_check_type','AlcoholTest','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(140,5,2,'cmp_medical_checks.check_type_id.medical_check_type','DrugTest','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(141,5,3,'cmp_medical_checks.check_type_id.medical_check_type','FitnessCheck','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(142,6,1,'cmp_medical_checks.result.medical_check_result','Positive','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(143,6,2,'cmp_medical_checks.result.medical_check_result','Negative','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(144,6,3,'cmp_medical_checks.result.medical_check_result','Inconclusive','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(145,7,1,'tpt_vehicle_service_request.vehicle_status.vehicle_status','Service','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(146,7,2,'tpt_vehicle_service_request.vehicle_status.vehicle_status','In-Service','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(147,7,3,'tpt_vehicle_service_request.vehicle_status.vehicle_status','Service Done','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(148,8,1,'tpt_vehicle.vehicle_type_id.vehicle_type','Bus','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(149,8,2,'tpt_vehicle.vehicle_type_id.vehicle_type','Car','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(150,8,3,'tpt_vehicle.vehicle_type_id.vehicle_type','Van','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(151,9,1,'tpt_vehicle.fuel_type_id.fuel_type','Petrol','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(152,9,2,'tpt_vehicle.fuel_type_id.fuel_type','Diesel','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(153,9,3,'tpt_vehicle.fuel_type_id.fuel_type','CNG','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(154,9,4,'tpt_vehicle.fuel_type_id.fuel_type','Electric','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(155,9,5,'tpt_vehicle.fuel_type_id.fuel_type','Hybrid','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(156,10,1,'tpt_vehicle.ownership_type_id.ownership_type','Company','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(157,10,2,'tpt_vehicle.ownership_type_id.ownership_type','Private','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(158,10,3,'tpt_vehicle.ownership_type_id.ownership_type','Leased','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(159,11,1,'tpt_vehicle.vehicle_emission_class_id.vehicle_emission_class','BS IV','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(160,11,2,'tpt_vehicle.vehicle_emission_class_id.vehicle_emission_class','BS V','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(161,11,3,'tpt_vehicle.vehicle_emission_class_id.vehicle_emission_class','BS VI','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(162,12,1,'tpt_personnel.id_type.type','Aadhar Card','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(163,12,2,'tpt_personnel.id_type.type','Licence Number','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(164,12,3,'tpt_personnel.id_type.type','Pancard','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(165,12,4,'tpt_personnel.id_type.type','Voter ID','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(166,12,5,'tpt_personnel.id_type.type','Passport','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(167,13,1,'tpt_attendance_device.device_type.type','Mobile','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(168,13,2,'tpt_attendance_device.device_type.type','Scanner','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(169,13,3,'tpt_attendance_device.device_type.type','Tablet','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(170,13,4,'tpt_attendance_device.device_type.type','Gate','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(171,14,1,'tpt_attendance_device.device_os.type','Android','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(172,14,2,'tpt_attendance_device.device_os.type','iOS','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(173,14,3,'tpt_attendance_device.device_os.type','Windows','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(174,14,4,'tpt_attendance_device.device_os.type','Linux','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(175,14,5,'tpt_attendance_device.device_os.type','macOS','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(176,14,6,'tpt_attendance_device.device_os.type','Custom','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(177,15,1,'cmp_complaint_actions.action_type_id.action_type','Created','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(178,15,2,'cmp_complaint_actions.action_type_id.action_type','Assigned','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(179,15,3,'cmp_complaint_actions.action_type_id.action_type','Comment','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(180,15,4,'cmp_complaint_actions.action_type_id.action_type','StatusChange','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(181,15,5,'cmp_complaint_actions.action_type_id.action_type','Investigation','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(182,15,6,'cmp_complaint_actions.action_type_id.action_type','Escalated','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(183,15,7,'cmp_complaint_actions.action_type_id.action_type','Resolved','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(184,16,1,'sch_entity_groups.entity_purpose_id.entity_purpose','Calation Management','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(185,16,2,'sch_entity_groups.entity_purpose_id.entity_purpose','Notification','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(186,16,3,'sch_entity_groups.entity_purpose_id.entity_purpose','Event Supervision','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(187,16,4,'sch_entity_groups.entity_purpose_id.entity_purpose','Exam Supervision','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(188,17,1,'sch_entity_groups.entity_purpose_id_2.entity_purpose_2','Calation Management','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(189,17,2,'sch_entity_groups.entity_purpose_id_2.entity_purpose_2','Notification','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(190,17,3,'sch_entity_groups.entity_purpose_id_2.entity_purpose_2','Event Supervision','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(191,17,4,'sch_entity_groups.entity_purpose_id_2.entity_purpose_2','Exam Supervision','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(192,18,1,'vnd_vendors.vendor_type_id.vendor_type_id','Transport','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(193,18,2,'vnd_vendors.vendor_type_id.vendor_type_id','Canteen/Catering','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(194,18,3,'vnd_vendors.vendor_type_id.vendor_type_id','Security','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(195,18,4,'vnd_vendors.vendor_type_id.vendor_type_id','Stationery','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(196,18,5,'vnd_vendors.vendor_type_id.vendor_type_id','Maintenance','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(197,18,6,'vnd_vendors.vendor_type_id.vendor_type_id','Medical/Doctor','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(198,18,7,'vnd_vendors.vendor_type_id.vendor_type_id','Other','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(199,19,1,'vnd_items.category_id.cat','Bus Rental','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(200,19,2,'vnd_items.category_id.cat','Driver Service','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(201,19,3,'vnd_items.category_id.cat','Food/Meal','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(202,19,4,'vnd_items.category_id.cat','Uniforms','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(203,19,5,'vnd_items.category_id.cat','Books','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(204,20,1,'vnd_items.unit_id.unit','Kilometer','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(205,20,2,'vnd_items.unit_id.unit','Day','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(206,20,3,'vnd_items.unit_id.unit','Month','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(207,20,4,'vnd_items.unit_id.unit','Visit','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(208,20,5,'vnd_items.unit_id.unit','Hour','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(209,20,6,'vnd_items.unit_id.unit','Piece','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(210,20,7,'vnd_items.unit_id.unit','Kg','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(211,20,8,'vnd_items.unit_id.unit','Trip','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(212,21,1,'vnd_agreement_items_jnt.related_entity_type.related_entity_type','Vehicle','String','\"{\\\"table_name\\\":\\\"tpt_vehicle\\\"}\"',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(213,21,2,'vnd_agreement_items_jnt.related_entity_type.related_entity_type','Driver','String','\"{\\\"table_name\\\":\\\"tpt_personnel\\\"}\"',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(214,21,3,'vnd_agreement_items_jnt.related_entity_type.related_entity_type','Helper','String','\"{\\\"table_name\\\":\\\"tpt_personnel\\\"}\"',1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(215,22,1,'vnd_invoices.status.status','Pending','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(216,22,2,'vnd_invoices.status.status','Approved','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(217,22,3,'vnd_invoices.status.status','Fully Paid','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(218,22,4,'vnd_invoices.status.status','Partially Paid','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(219,22,5,'vnd_invoices.status.status','Cancelled','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(220,23,1,'vnd_payments.payment_mode.payment_mode','Cash','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(221,23,2,'vnd_payments.payment_mode.payment_mode','Bank Transfer','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(222,23,3,'vnd_payments.payment_mode.payment_mode','Cheque','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(223,23,4,'vnd_payments.payment_mode.payment_mode','Online Payment','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(224,24,1,'ntf_notifications.confidentiality_level_id.confidentiality_level','Public','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(225,24,2,'ntf_notifications.confidentiality_level_id.confidentiality_level','Restricted','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(226,24,3,'ntf_notifications.confidentiality_level_id.confidentiality_level','Confidentiality','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(227,25,1,'ntf_notifications.recurring_interval_id.recurring_interval','Hourly','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(228,25,2,'ntf_notifications.recurring_interval_id.recurring_interval','Daily','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(229,25,3,'ntf_notifications.recurring_interval_id.recurring_interval','Weekly','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(230,25,4,'ntf_notifications.recurring_interval_id.recurring_interval','Monthly','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(231,25,5,'ntf_notifications.recurring_interval_id.recurring_interval','Quarterly','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(232,25,6,'ntf_notifications.recurring_interval_id.recurring_interval','Yearly','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(233,26,1,'ntf_notification_channels.provider_id.provider','MSG91','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(234,26,2,'ntf_notification_channels.provider_id.provider','Twilio','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(235,26,3,'ntf_notification_channels.provider_id.provider','AWS SES','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(236,26,4,'ntf_notification_channels.provider_id.provider','Meta API','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(237,27,1,'qns_question_performance_category_jnt.recommendation_type.recommendation_type','REVISION','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(238,27,2,'qns_question_performance_category_jnt.recommendation_type.recommendation_type','PRACTICE','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(239,27,3,'qns_question_performance_category_jnt.recommendation_type.recommendation_type','CHALLENGE','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(240,28,1,'qns_question_review_log.review_status_id.review_status_id','PENDING','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(241,28,2,'qns_question_review_log.review_status_id.review_status_id','APPROVED','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(242,28,3,'qns_question_review_log.review_status_id.review_status_id','REJECTED','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(243,29,1,'lms_homework.submission_type_id.submission_type_id','TEXT','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(244,29,2,'lms_homework.submission_type_id.submission_type_id','FILE','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(245,29,3,'lms_homework.submission_type_id.submission_type_id','HYBRID','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(246,30,1,'lms_homework.status_id.status_id','TEXT','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(247,30,2,'lms_homework.status_id.status_id','FILE','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(248,30,3,'lms_homework.status_id.status_id','HYBRID','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(249,31,1,'lms_homework.release_condition_id.release_condition_id','TEXT','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(250,31,2,'lms_homework.release_condition_id.release_condition_id','FILE','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(251,31,3,'lms_homework.release_condition_id.release_condition_id','HYBRID','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(252,32,1,'lms_homework_submissions.status_id.status_id','CHECKED','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(253,32,2,'lms_homework_submissions.status_id.status_id','SUBMITTED','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(254,32,3,'lms_homework_submissions.status_id.status_id','REJECTED','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(255,33,1,'std_students.current_status_id.current_status','Active','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(256,33,2,'std_students.current_status_id.current_status','Left','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(257,33,3,'std_students.current_status_id.current_status','Suspended','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(258,33,4,'std_students.current_status_id.current_status','Alumni','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(259,33,5,'std_students.current_status_id.current_status','Withdrawn','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(260,33,6,'std_students.current_status_id.current_status','Promoted','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(261,34,1,'std_student_profiles.nationality.nationality','Indian','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(262,34,2,'std_student_profiles.nationality.nationality','Nepali','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(263,34,3,'std_student_profiles.nationality.nationality','American','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(264,34,4,'std_student_profiles.nationality.nationality','Canadian','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(265,34,5,'std_student_profiles.nationality.nationality','Japanese','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(266,34,6,'std_student_profiles.nationality.nationality','Other','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(267,35,1,'std_student_profiles.mother_tongue.mother_tongue','Assamese','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(268,35,2,'std_student_profiles.mother_tongue.mother_tongue','Bengali','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(269,35,3,'std_student_profiles.mother_tongue.mother_tongue','Bodo','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(270,35,4,'std_student_profiles.mother_tongue.mother_tongue','Dogri','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(271,35,5,'std_student_profiles.mother_tongue.mother_tongue','Gujarati','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(272,35,6,'std_student_profiles.mother_tongue.mother_tongue','Hindi','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(273,35,7,'std_student_profiles.mother_tongue.mother_tongue','Kannada','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(274,35,8,'std_student_profiles.mother_tongue.mother_tongue','Other','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(275,36,1,'std_student_academic_sessions.house.house_name','House A','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(276,36,2,'std_student_academic_sessions.house.house_name','House B','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(277,36,3,'std_student_academic_sessions.house.house_name','House C','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(278,36,4,'std_student_academic_sessions.house.house_name','House D','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(279,36,5,'std_student_academic_sessions.house.house_name','House E','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(280,37,1,'std_student_academic_sessions.reason_quit.reason_quit','Student Transfer','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(281,37,2,'std_student_academic_sessions.reason_quit.reason_quit','Completed Studies','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(282,37,3,'std_student_academic_sessions.reason_quit.reason_quit','Discontinued','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(283,37,4,'std_student_academic_sessions.reason_quit.reason_quit','Graduated','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(284,37,5,'std_student_academic_sessions.reason_quit.reason_quit','Other','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(285,38,1,'std_student_documents.document_type_id.document_type','PDF','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(286,38,2,'std_student_documents.document_type_id.document_type','Image','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(287,38,3,'std_student_documents.document_type_id.document_type','Word Document','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(288,38,4,'std_student_documents.document_type_id.document_type','Other','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(289,39,1,'std_medical_incidents.incident_type_id.incident_type','Injury','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(290,39,2,'std_medical_incidents.incident_type_id.incident_type','Sickness','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(291,39,3,'std_medical_incidents.incident_type_id.incident_type','Fainting','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(292,39,4,'std_medical_incidents.incident_type_id.incident_type','Other','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(293,40,1,'slb_books.language.language','English','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(294,40,2,'slb_books.language.language','Hindi','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(295,40,3,'slb_books.language.language','Sanskrit','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(296,40,4,'slb_books.language.language','Bengali','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(297,40,5,'slb_books.language.language','Gujrati','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(298,40,6,'slb_books.language.language','Tamil','String',NULL,1,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07');
/*!40000 ALTER TABLE `sys_dropdowns` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_media`
--

DROP TABLE IF EXISTS `sys_media`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_media`
--

LOCK TABLES `sys_media` WRITE;
/*!40000 ALTER TABLE `sys_media` DISABLE KEYS */;
/*!40000 ALTER TABLE `sys_media` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_model_has_permissions_jnt`
--

DROP TABLE IF EXISTS `sys_model_has_permissions_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_model_has_permissions_jnt` (
  `permission_id` INT unsigned NOT NULL,
  `model_type` varchar(190) COLLATE utf8mb4_unicode_ci NOT NULL,
  `model_id` INT unsigned NOT NULL,
  PRIMARY KEY (`permission_id`,`model_id`,`model_type`),
  KEY `model_has_permissions_model_id_model_type_index` (`model_id`,`model_type`),
  CONSTRAINT `sys_model_has_permissions_jnt_permission_id_foreign` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_model_has_permissions_jnt`
--

LOCK TABLES `sys_model_has_permissions_jnt` WRITE;
/*!40000 ALTER TABLE `sys_model_has_permissions_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `sys_model_has_permissions_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_model_has_roles_jnt`
--

DROP TABLE IF EXISTS `sys_model_has_roles_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_model_has_roles_jnt` (
  `role_id` INT unsigned NOT NULL,
  `model_type` varchar(190) COLLATE utf8mb4_unicode_ci NOT NULL,
  `model_id` INT unsigned NOT NULL,
  PRIMARY KEY (`role_id`,`model_id`,`model_type`),
  KEY `model_has_roles_model_id_model_type_index` (`model_id`,`model_type`),
  CONSTRAINT `sys_model_has_roles_jnt_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_model_has_roles_jnt`
--

LOCK TABLES `sys_model_has_roles_jnt` WRITE;
/*!40000 ALTER TABLE `sys_model_has_roles_jnt` DISABLE KEYS */;
INSERT INTO `sys_model_has_roles_jnt` VALUES (1,'App\\Models\\User',2),(2,'App\\Models\\User',3),(3,'App\\Models\\User',4),(4,'App\\Models\\User',5),(4,'App\\Models\\User',6),(4,'App\\Models\\User',7),(4,'App\\Models\\User',8),(4,'App\\Models\\User',9),(7,'App\\Models\\User',10),(7,'App\\Models\\User',11),(6,'App\\Models\\User',12),(6,'App\\Models\\User',13),(9,'App\\Models\\User',14),(9,'App\\Models\\User',15),(8,'App\\Models\\User',16),(8,'App\\Models\\User',17);
/*!40000 ALTER TABLE `sys_model_has_roles_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_permissions`
--

DROP TABLE IF EXISTS `sys_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_permissions` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `guard_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sys_permissions_name_guard_name_unique` (`name`,`guard_name`)
) ENGINE=InnoDB AUTO_INCREMENT=1975 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_permissions`
--

LOCK TABLES `sys_permissions` WRITE;
/*!40000 ALTER TABLE `sys_permissions` DISABLE KEYS */;
INSERT INTO `sys_permissions` VALUES (1,'tenant.menu.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(2,'tenant.menu.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(3,'tenant.menu.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(4,'tenant.menu.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(5,'tenant.menu.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(6,'tenant.menu.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(7,'tenant.menu.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(8,'tenant.menu.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(9,'tenant.menu.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(10,'tenant.menu.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(11,'tenant.menu.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(12,'tenant.menu.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(13,'tenant.menu.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(14,'tenant.menu.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(15,'tenant.setting.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(16,'tenant.setting.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(17,'tenant.setting.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(18,'tenant.setting.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(19,'tenant.setting.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(20,'tenant.setting.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(21,'tenant.setting.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(22,'tenant.setting.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(23,'tenant.setting.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(24,'tenant.setting.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(25,'tenant.setting.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(26,'tenant.setting.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(27,'tenant.setting.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(28,'tenant.setting.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(29,'tenant.dropdown.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(30,'tenant.dropdown.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(31,'tenant.dropdown.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(32,'tenant.dropdown.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(33,'tenant.dropdown.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(34,'tenant.dropdown.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(35,'tenant.dropdown.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(36,'tenant.dropdown.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(37,'tenant.dropdown.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(38,'tenant.dropdown.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(39,'tenant.dropdown.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(40,'tenant.dropdown.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(41,'tenant.dropdown.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(42,'tenant.dropdown.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(43,'tenant.geography.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(44,'tenant.geography.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(45,'tenant.geography.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(46,'tenant.geography.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(47,'tenant.geography.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(48,'tenant.geography.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(49,'tenant.geography.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(50,'tenant.geography.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(51,'tenant.geography.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(52,'tenant.geography.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(53,'tenant.geography.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(54,'tenant.geography.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(55,'tenant.geography.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(56,'tenant.geography.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(57,'tenant.language.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(58,'tenant.language.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(59,'tenant.language.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(60,'tenant.language.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(61,'tenant.language.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(62,'tenant.language.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(63,'tenant.language.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(64,'tenant.language.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(65,'tenant.language.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(66,'tenant.language.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(67,'tenant.language.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(68,'tenant.language.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(69,'tenant.language.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(70,'tenant.language.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(71,'tenant.module.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(72,'tenant.module.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(73,'tenant.module.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(74,'tenant.module.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(75,'tenant.module.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(76,'tenant.module.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(77,'tenant.module.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(78,'tenant.module.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(79,'tenant.module.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(80,'tenant.module.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(81,'tenant.module.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(82,'tenant.module.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(83,'tenant.module.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(84,'tenant.module.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(85,'tenant.organization.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(86,'tenant.organization.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(87,'tenant.organization.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(88,'tenant.organization.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(89,'tenant.organization.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(90,'tenant.organization.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(91,'tenant.organization.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(92,'tenant.organization.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(93,'tenant.organization.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(94,'tenant.organization.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(95,'tenant.organization.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(96,'tenant.organization.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(97,'tenant.organization.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(98,'tenant.organization.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(99,'tenant.organization-group.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(100,'tenant.organization-group.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(101,'tenant.organization-group.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(102,'tenant.organization-group.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(103,'tenant.organization-group.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(104,'tenant.organization-group.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(105,'tenant.organization-group.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(106,'tenant.organization-group.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(107,'tenant.organization-group.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(108,'tenant.organization-group.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(109,'tenant.organization-group.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(110,'tenant.organization-group.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(111,'tenant.organization-group.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(112,'tenant.organization-group.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(113,'tenant.plan.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(114,'tenant.plan.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(115,'tenant.plan.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(116,'tenant.plan.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(117,'tenant.plan.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(118,'tenant.plan.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(119,'tenant.plan.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(120,'tenant.plan.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(121,'tenant.plan.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(122,'tenant.plan.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(123,'tenant.plan.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(124,'tenant.plan.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(125,'tenant.plan.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(126,'tenant.plan.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(127,'tenant.billing-cycle.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(128,'tenant.billing-cycle.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(129,'tenant.billing-cycle.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(130,'tenant.billing-cycle.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(131,'tenant.billing-cycle.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(132,'tenant.billing-cycle.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(133,'tenant.billing-cycle.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(134,'tenant.billing-cycle.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(135,'tenant.billing-cycle.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(136,'tenant.billing-cycle.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(137,'tenant.billing-cycle.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(138,'tenant.billing-cycle.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(139,'tenant.billing-cycle.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(140,'tenant.billing-cycle.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(141,'tenant.session-board.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(142,'tenant.session-board.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(143,'tenant.session-board.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(144,'tenant.session-board.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(145,'tenant.session-board.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(146,'tenant.session-board.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(147,'tenant.session-board.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(148,'tenant.session-board.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(149,'tenant.session-board.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(150,'tenant.session-board.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(151,'tenant.session-board.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(152,'tenant.session-board.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(153,'tenant.session-board.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(154,'tenant.session-board.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(155,'tenant.user.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(156,'tenant.user.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(157,'tenant.user.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(158,'tenant.user.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(159,'tenant.user.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(160,'tenant.user.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(161,'tenant.user.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(162,'tenant.user.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(163,'tenant.user.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(164,'tenant.user.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(165,'tenant.user.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(166,'tenant.user.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(167,'tenant.user.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(168,'tenant.user.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(169,'tenant.role-permission.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(170,'tenant.role-permission.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(171,'tenant.role-permission.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(172,'tenant.role-permission.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(173,'tenant.role-permission.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(174,'tenant.role-permission.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(175,'tenant.role-permission.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(176,'tenant.role-permission.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(177,'tenant.role-permission.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(178,'tenant.role-permission.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(179,'tenant.role-permission.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(180,'tenant.role-permission.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(181,'tenant.role-permission.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(182,'tenant.role-permission.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(183,'tenant.school.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(184,'tenant.school.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(185,'tenant.school.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(186,'tenant.school.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(187,'tenant.school.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(188,'tenant.school.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(189,'tenant.school.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(190,'tenant.school.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(191,'tenant.school.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(192,'tenant.school.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(193,'tenant.school.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(194,'tenant.school.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(195,'tenant.school.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(196,'tenant.school.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(197,'tenant.school-setup.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(198,'tenant.school-setup.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(199,'tenant.school-setup.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(200,'tenant.school-setup.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(201,'tenant.school-setup.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(202,'tenant.school-setup.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(203,'tenant.school-setup.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(204,'tenant.school-setup.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(205,'tenant.school-setup.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(206,'tenant.school-setup.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(207,'tenant.school-setup.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(208,'tenant.school-setup.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(209,'tenant.school-setup.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(210,'tenant.school-setup.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(211,'tenant.class-group.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(212,'tenant.class-group.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(213,'tenant.class-group.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(214,'tenant.class-group.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(215,'tenant.class-group.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(216,'tenant.class-group.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(217,'tenant.class-group.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(218,'tenant.class-group.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(219,'tenant.class-group.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(220,'tenant.class-group.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(221,'tenant.class-group.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(222,'tenant.class-group.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(223,'tenant.class-group.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(224,'tenant.class-group.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(225,'tenant.class-subject-mgmt.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(226,'tenant.class-subject-mgmt.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(227,'tenant.class-subject-mgmt.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(228,'tenant.class-subject-mgmt.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(229,'tenant.class-subject-mgmt.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(230,'tenant.class-subject-mgmt.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(231,'tenant.class-subject-mgmt.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(232,'tenant.class-subject-mgmt.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(233,'tenant.class-subject-mgmt.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(234,'tenant.class-subject-mgmt.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(235,'tenant.class-subject-mgmt.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(236,'tenant.class-subject-mgmt.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(237,'tenant.class-subject-mgmt.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(238,'tenant.class-subject-mgmt.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(239,'tenant.section.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(240,'tenant.section.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(241,'tenant.section.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(242,'tenant.section.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(243,'tenant.section.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(244,'tenant.section.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(245,'tenant.section.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(246,'tenant.section.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(247,'tenant.section.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(248,'tenant.section.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(249,'tenant.section.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(250,'tenant.section.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(251,'tenant.section.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(252,'tenant.section.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(253,'tenant.school-class.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(254,'tenant.school-class.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(255,'tenant.school-class.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(256,'tenant.school-class.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(257,'tenant.school-class.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(258,'tenant.school-class.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(259,'tenant.school-class.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(260,'tenant.school-class.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(261,'tenant.school-class.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(262,'tenant.school-class.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(263,'tenant.school-class.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(264,'tenant.school-class.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(265,'tenant.school-class.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(266,'tenant.school-class.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(267,'tenant.subject-type.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(268,'tenant.subject-type.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(269,'tenant.subject-type.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(270,'tenant.subject-type.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(271,'tenant.subject-type.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(272,'tenant.subject-type.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(273,'tenant.subject-type.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(274,'tenant.subject-type.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(275,'tenant.subject-type.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(276,'tenant.subject-type.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(277,'tenant.subject-type.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(278,'tenant.subject-type.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(279,'tenant.subject-type.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(280,'tenant.subject-type.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(281,'tenant.study-format.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(282,'tenant.study-format.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(283,'tenant.study-format.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(284,'tenant.study-format.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(285,'tenant.study-format.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(286,'tenant.study-format.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(287,'tenant.study-format.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(288,'tenant.study-format.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(289,'tenant.study-format.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(290,'tenant.study-format.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(291,'tenant.study-format.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(292,'tenant.study-format.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(293,'tenant.study-format.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(294,'tenant.study-format.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(295,'tenant.subject.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(296,'tenant.subject.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(297,'tenant.subject.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(298,'tenant.subject.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(299,'tenant.subject.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(300,'tenant.subject.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(301,'tenant.subject.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(302,'tenant.subject.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(303,'tenant.subject.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(304,'tenant.subject.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(305,'tenant.subject.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(306,'tenant.subject.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(307,'tenant.subject.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(308,'tenant.subject.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(309,'tenant.subject-study-format.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(310,'tenant.subject-study-format.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(311,'tenant.subject-study-format.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(312,'tenant.subject-study-format.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(313,'tenant.subject-study-format.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(314,'tenant.subject-study-format.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(315,'tenant.subject-study-format.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(316,'tenant.subject-study-format.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(317,'tenant.subject-study-format.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(318,'tenant.subject-study-format.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(319,'tenant.subject-study-format.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(320,'tenant.subject-study-format.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(321,'tenant.subject-study-format.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(322,'tenant.subject-study-format.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(323,'tenant.subject-group.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(324,'tenant.subject-group.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(325,'tenant.subject-group.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(326,'tenant.subject-group.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(327,'tenant.subject-group.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(328,'tenant.subject-group.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(329,'tenant.subject-group.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(330,'tenant.subject-group.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(331,'tenant.subject-group.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(332,'tenant.subject-group.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(333,'tenant.subject-group.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(334,'tenant.subject-group.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(335,'tenant.subject-group.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(336,'tenant.subject-group.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(337,'tenant.subject-class-mapping.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(338,'tenant.subject-class-mapping.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(339,'tenant.subject-class-mapping.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(340,'tenant.subject-class-mapping.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(341,'tenant.subject-class-mapping.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(342,'tenant.subject-class-mapping.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(343,'tenant.subject-class-mapping.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(344,'tenant.subject-class-mapping.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(345,'tenant.subject-class-mapping.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(346,'tenant.subject-class-mapping.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(347,'tenant.subject-class-mapping.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(348,'tenant.subject-class-mapping.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(349,'tenant.subject-class-mapping.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(350,'tenant.subject-class-mapping.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(351,'tenant.subject-group-subject.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(352,'tenant.subject-group-subject.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(353,'tenant.subject-group-subject.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(354,'tenant.subject-group-subject.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(355,'tenant.subject-group-subject.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(356,'tenant.subject-group-subject.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(357,'tenant.subject-group-subject.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(358,'tenant.subject-group-subject.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(359,'tenant.subject-group-subject.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(360,'tenant.subject-group-subject.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(361,'tenant.subject-group-subject.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(362,'tenant.subject-group-subject.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(363,'tenant.subject-group-subject.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(364,'tenant.subject-group-subject.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(365,'tenant.student.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(366,'tenant.student.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(367,'tenant.student.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(368,'tenant.student.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(369,'tenant.student.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(370,'tenant.student.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(371,'tenant.student.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(372,'tenant.student.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(373,'tenant.student.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(374,'tenant.student.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(375,'tenant.student.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(376,'tenant.student.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(377,'tenant.student.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(378,'tenant.student.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(379,'tenant.teacher.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(380,'tenant.teacher.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(381,'tenant.teacher.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(382,'tenant.teacher.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(383,'tenant.teacher.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(384,'tenant.teacher.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(385,'tenant.teacher.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(386,'tenant.teacher.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(387,'tenant.teacher.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(388,'tenant.teacher.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(389,'tenant.teacher.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(390,'tenant.teacher.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(391,'tenant.teacher.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(392,'tenant.teacher.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(393,'tenant.infra-setup.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(394,'tenant.infra-setup.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(395,'tenant.infra-setup.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(396,'tenant.infra-setup.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(397,'tenant.infra-setup.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(398,'tenant.infra-setup.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(399,'tenant.infra-setup.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(400,'tenant.infra-setup.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(401,'tenant.infra-setup.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(402,'tenant.infra-setup.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(403,'tenant.infra-setup.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(404,'tenant.infra-setup.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(405,'tenant.infra-setup.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(406,'tenant.infra-setup.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(407,'tenant.building.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(408,'tenant.building.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(409,'tenant.building.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(410,'tenant.building.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(411,'tenant.building.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(412,'tenant.building.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(413,'tenant.building.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(414,'tenant.building.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(415,'tenant.building.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(416,'tenant.building.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(417,'tenant.building.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(418,'tenant.building.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(419,'tenant.building.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(420,'tenant.building.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(421,'tenant.room.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(422,'tenant.room.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(423,'tenant.room.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(424,'tenant.room.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(425,'tenant.room.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(426,'tenant.room.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(427,'tenant.room.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(428,'tenant.room.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(429,'tenant.room.export','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(430,'tenant.room.print','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(431,'tenant.room.status','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(432,'tenant.room.email-schedule','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(433,'tenant.room.remark','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(434,'tenant.room.pdf','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(435,'tenant.room-type.create','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(436,'tenant.room-type.view','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(437,'tenant.room-type.viewAny','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(438,'tenant.room-type.update','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(439,'tenant.room-type.delete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(440,'tenant.room-type.restore','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(441,'tenant.room-type.forceDelete','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(442,'tenant.room-type.import','web','2026-02-01 06:03:00','2026-02-01 06:03:00'),(443,'tenant.room-type.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(444,'tenant.room-type.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(445,'tenant.room-type.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(446,'tenant.room-type.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(447,'tenant.room-type.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(448,'tenant.room-type.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(449,'tenant.day.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(450,'tenant.day.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(451,'tenant.day.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(452,'tenant.day.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(453,'tenant.day.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(454,'tenant.day.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(455,'tenant.day.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(456,'tenant.day.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(457,'tenant.day.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(458,'tenant.day.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(459,'tenant.day.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(460,'tenant.day.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(461,'tenant.day.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(462,'tenant.day.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(463,'tenant.period.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(464,'tenant.period.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(465,'tenant.period.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(466,'tenant.period.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(467,'tenant.period.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(468,'tenant.period.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(469,'tenant.period.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(470,'tenant.period.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(471,'tenant.period.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(472,'tenant.period.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(473,'tenant.period.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(474,'tenant.period.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(475,'tenant.period.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(476,'tenant.period.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(477,'tenant.school-timing.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(478,'tenant.school-timing.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(479,'tenant.school-timing.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(480,'tenant.school-timing.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(481,'tenant.school-timing.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(482,'tenant.school-timing.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(483,'tenant.school-timing.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(484,'tenant.school-timing.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(485,'tenant.school-timing.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(486,'tenant.school-timing.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(487,'tenant.school-timing.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(488,'tenant.school-timing.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(489,'tenant.school-timing.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(490,'tenant.school-timing.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(491,'tenant.timing-profile.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(492,'tenant.timing-profile.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(493,'tenant.timing-profile.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(494,'tenant.timing-profile.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(495,'tenant.timing-profile.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(496,'tenant.timing-profile.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(497,'tenant.timing-profile.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(498,'tenant.timing-profile.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(499,'tenant.timing-profile.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(500,'tenant.timing-profile.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(501,'tenant.timing-profile.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(502,'tenant.timing-profile.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(503,'tenant.timing-profile.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(504,'tenant.timing-profile.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(505,'tenant.smart-timetable.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(506,'tenant.smart-timetable.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(507,'tenant.smart-timetable.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(508,'tenant.smart-timetable.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(509,'tenant.smart-timetable.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(510,'tenant.smart-timetable.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(511,'tenant.smart-timetable.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(512,'tenant.smart-timetable.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(513,'tenant.smart-timetable.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(514,'tenant.smart-timetable.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(515,'tenant.smart-timetable.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(516,'tenant.smart-timetable.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(517,'tenant.smart-timetable.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(518,'tenant.smart-timetable.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(519,'tenant.transport.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(520,'tenant.transport.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(521,'tenant.transport.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(522,'tenant.transport.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(523,'tenant.transport.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(524,'tenant.transport.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(525,'tenant.transport.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(526,'tenant.transport.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(527,'tenant.transport.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(528,'tenant.transport.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(529,'tenant.transport.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(530,'tenant.transport.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(531,'tenant.transport.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(532,'tenant.transport.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(533,'tenant.student-ai-location.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(534,'tenant.student-ai-location.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(535,'tenant.student-ai-location.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(536,'tenant.student-ai-location.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(537,'tenant.student-ai-location.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(538,'tenant.student-ai-location.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(539,'tenant.student-ai-location.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(540,'tenant.student-ai-location.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(541,'tenant.student-ai-location.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(542,'tenant.student-ai-location.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(543,'tenant.student-ai-location.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(544,'tenant.student-ai-location.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(545,'tenant.student-ai-location.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(546,'tenant.student-ai-location.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(547,'tenant.transport-dashboard.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(548,'tenant.transport-dashboard.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(549,'tenant.transport-dashboard.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(550,'tenant.transport-dashboard.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(551,'tenant.transport-dashboard.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(552,'tenant.transport-dashboard.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(553,'tenant.transport-dashboard.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(554,'tenant.transport-dashboard.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(555,'tenant.transport-dashboard.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(556,'tenant.transport-dashboard.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(557,'tenant.transport-dashboard.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(558,'tenant.transport-dashboard.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(559,'tenant.transport-dashboard.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(560,'tenant.transport-dashboard.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(561,'tenant.vehicle.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(562,'tenant.vehicle.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(563,'tenant.vehicle.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(564,'tenant.vehicle.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(565,'tenant.vehicle.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(566,'tenant.vehicle.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(567,'tenant.vehicle.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(568,'tenant.vehicle.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(569,'tenant.vehicle.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(570,'tenant.vehicle.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(571,'tenant.vehicle.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(572,'tenant.vehicle.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(573,'tenant.vehicle.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(574,'tenant.vehicle.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(575,'tenant.route.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(576,'tenant.route.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(577,'tenant.route.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(578,'tenant.route.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(579,'tenant.route.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(580,'tenant.route.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(581,'tenant.route.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(582,'tenant.route.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(583,'tenant.route.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(584,'tenant.route.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(585,'tenant.route.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(586,'tenant.route.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(587,'tenant.route.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(588,'tenant.route.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(589,'tenant.pickup-point.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(590,'tenant.pickup-point.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(591,'tenant.pickup-point.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(592,'tenant.pickup-point.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(593,'tenant.pickup-point.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(594,'tenant.pickup-point.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(595,'tenant.pickup-point.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(596,'tenant.pickup-point.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(597,'tenant.pickup-point.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(598,'tenant.pickup-point.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(599,'tenant.pickup-point.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(600,'tenant.pickup-point.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(601,'tenant.pickup-point.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(602,'tenant.pickup-point.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(603,'tenant.trans-stops-list.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(604,'tenant.trans-stops-list.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(605,'tenant.trans-stops-list.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(606,'tenant.trans-stops-list.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(607,'tenant.trans-stops-list.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(608,'tenant.trans-stops-list.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(609,'tenant.trans-stops-list.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(610,'tenant.trans-stops-list.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(611,'tenant.trans-stops-list.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(612,'tenant.trans-stops-list.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(613,'tenant.trans-stops-list.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(614,'tenant.trans-stops-list.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(615,'tenant.trans-stops-list.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(616,'tenant.trans-stops-list.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(617,'tenant.pickup-point-route.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(618,'tenant.pickup-point-route.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(619,'tenant.pickup-point-route.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(620,'tenant.pickup-point-route.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(621,'tenant.pickup-point-route.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(622,'tenant.pickup-point-route.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(623,'tenant.pickup-point-route.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(624,'tenant.pickup-point-route.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(625,'tenant.pickup-point-route.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(626,'tenant.pickup-point-route.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(627,'tenant.pickup-point-route.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(628,'tenant.pickup-point-route.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(629,'tenant.pickup-point-route.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(630,'tenant.pickup-point-route.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(631,'tenant.attendance-device.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(632,'tenant.attendance-device.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(633,'tenant.attendance-device.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(634,'tenant.attendance-device.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(635,'tenant.attendance-device.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(636,'tenant.attendance-device.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(637,'tenant.attendance-device.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(638,'tenant.attendance-device.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(639,'tenant.attendance-device.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(640,'tenant.attendance-device.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(641,'tenant.attendance-device.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(642,'tenant.attendance-device.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(643,'tenant.attendance-device.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(644,'tenant.attendance-device.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(645,'tenant.fine-master.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(646,'tenant.fine-master.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(647,'tenant.fine-master.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(648,'tenant.fine-master.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(649,'tenant.fine-master.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(650,'tenant.fine-master.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(651,'tenant.fine-master.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(652,'tenant.fine-master.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(653,'tenant.fine-master.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(654,'tenant.fine-master.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(655,'tenant.fine-master.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(656,'tenant.fine-master.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(657,'tenant.fine-master.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(658,'tenant.fine-master.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(659,'tenant.shift.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(660,'tenant.shift.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(661,'tenant.shift.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(662,'tenant.shift.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(663,'tenant.shift.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(664,'tenant.shift.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(665,'tenant.shift.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(666,'tenant.shift.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(667,'tenant.shift.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(668,'tenant.shift.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(669,'tenant.shift.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(670,'tenant.shift.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(671,'tenant.shift.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(672,'tenant.shift.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(673,'tenant.driver-helper.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(674,'tenant.driver-helper.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(675,'tenant.driver-helper.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(676,'tenant.driver-helper.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(677,'tenant.driver-helper.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(678,'tenant.driver-helper.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(679,'tenant.driver-helper.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(680,'tenant.driver-helper.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(681,'tenant.driver-helper.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(682,'tenant.driver-helper.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(683,'tenant.driver-helper.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(684,'tenant.driver-helper.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(685,'tenant.driver-helper.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(686,'tenant.driver-helper.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(687,'tenant.driver-route-vehicle.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(688,'tenant.driver-route-vehicle.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(689,'tenant.driver-route-vehicle.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(690,'tenant.driver-route-vehicle.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(691,'tenant.driver-route-vehicle.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(692,'tenant.driver-route-vehicle.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(693,'tenant.driver-route-vehicle.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(694,'tenant.driver-route-vehicle.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(695,'tenant.driver-route-vehicle.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(696,'tenant.driver-route-vehicle.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(697,'tenant.driver-route-vehicle.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(698,'tenant.driver-route-vehicle.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(699,'tenant.driver-route-vehicle.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(700,'tenant.driver-route-vehicle.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(701,'tenant.route-scheduler.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(702,'tenant.route-scheduler.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(703,'tenant.route-scheduler.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(704,'tenant.route-scheduler.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(705,'tenant.route-scheduler.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(706,'tenant.route-scheduler.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(707,'tenant.route-scheduler.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(708,'tenant.route-scheduler.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(709,'tenant.route-scheduler.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(710,'tenant.route-scheduler.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(711,'tenant.route-scheduler.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(712,'tenant.route-scheduler.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(713,'tenant.route-scheduler.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(714,'tenant.route-scheduler.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(715,'tenant.vehicle-fuel.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(716,'tenant.vehicle-fuel.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(717,'tenant.vehicle-fuel.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(718,'tenant.vehicle-fuel.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(719,'tenant.vehicle-fuel.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(720,'tenant.vehicle-fuel.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(721,'tenant.vehicle-fuel.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(722,'tenant.vehicle-fuel.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(723,'tenant.vehicle-fuel.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(724,'tenant.vehicle-fuel.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(725,'tenant.vehicle-fuel.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(726,'tenant.vehicle-fuel.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(727,'tenant.vehicle-fuel.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(728,'tenant.vehicle-fuel.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(729,'tenant.daily-vehicle-inspection.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(730,'tenant.daily-vehicle-inspection.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(731,'tenant.daily-vehicle-inspection.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(732,'tenant.daily-vehicle-inspection.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(733,'tenant.daily-vehicle-inspection.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(734,'tenant.daily-vehicle-inspection.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(735,'tenant.daily-vehicle-inspection.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(736,'tenant.daily-vehicle-inspection.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(737,'tenant.daily-vehicle-inspection.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(738,'tenant.daily-vehicle-inspection.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(739,'tenant.daily-vehicle-inspection.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(740,'tenant.daily-vehicle-inspection.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(741,'tenant.daily-vehicle-inspection.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(742,'tenant.daily-vehicle-inspection.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(743,'tenant.vehicle-service-request.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(744,'tenant.vehicle-service-request.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(745,'tenant.vehicle-service-request.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(746,'tenant.vehicle-service-request.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(747,'tenant.vehicle-service-request.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(748,'tenant.vehicle-service-request.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(749,'tenant.vehicle-service-request.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(750,'tenant.vehicle-service-request.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(751,'tenant.vehicle-service-request.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(752,'tenant.vehicle-service-request.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(753,'tenant.vehicle-service-request.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(754,'tenant.vehicle-service-request.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(755,'tenant.vehicle-service-request.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(756,'tenant.vehicle-service-request.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(757,'tenant.vehicle-service-approval.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(758,'tenant.vehicle-service-approval.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(759,'tenant.vehicle-service-approval.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(760,'tenant.vehicle-service-approval.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(761,'tenant.vehicle-service-approval.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(762,'tenant.vehicle-service-approval.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(763,'tenant.vehicle-service-approval.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(764,'tenant.vehicle-service-approval.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(765,'tenant.vehicle-service-approval.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(766,'tenant.vehicle-service-approval.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(767,'tenant.vehicle-service-approval.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(768,'tenant.vehicle-service-approval.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(769,'tenant.vehicle-service-approval.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(770,'tenant.vehicle-service-approval.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(771,'tenant.vehicle-maintenance.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(772,'tenant.vehicle-maintenance.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(773,'tenant.vehicle-maintenance.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(774,'tenant.vehicle-maintenance.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(775,'tenant.vehicle-maintenance.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(776,'tenant.vehicle-maintenance.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(777,'tenant.vehicle-maintenance.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(778,'tenant.vehicle-maintenance.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(779,'tenant.vehicle-maintenance.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(780,'tenant.vehicle-maintenance.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(781,'tenant.vehicle-maintenance.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(782,'tenant.vehicle-maintenance.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(783,'tenant.vehicle-maintenance.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(784,'tenant.vehicle-maintenance.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(785,'tenant.driver-attendance.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(786,'tenant.driver-attendance.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(787,'tenant.driver-attendance.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(788,'tenant.driver-attendance.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(789,'tenant.driver-attendance.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(790,'tenant.driver-attendance.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(791,'tenant.driver-attendance.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(792,'tenant.driver-attendance.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(793,'tenant.driver-attendance.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(794,'tenant.driver-attendance.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(795,'tenant.driver-attendance.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(796,'tenant.driver-attendance.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(797,'tenant.driver-attendance.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(798,'tenant.driver-attendance.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(799,'tenant.trip.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(800,'tenant.trip.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(801,'tenant.trip.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(802,'tenant.trip.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(803,'tenant.trip.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(804,'tenant.trip.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(805,'tenant.trip.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(806,'tenant.trip.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(807,'tenant.trip.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(808,'tenant.trip.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(809,'tenant.trip.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(810,'tenant.trip.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(811,'tenant.trip.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(812,'tenant.trip.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(813,'tenant.stop-details.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(814,'tenant.stop-details.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(815,'tenant.stop-details.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(816,'tenant.stop-details.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(817,'tenant.stop-details.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(818,'tenant.stop-details.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(819,'tenant.stop-details.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(820,'tenant.stop-details.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(821,'tenant.stop-details.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(822,'tenant.stop-details.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(823,'tenant.stop-details.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(824,'tenant.stop-details.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(825,'tenant.stop-details.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(826,'tenant.stop-details.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(827,'tenant.stop-details.prepare.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(828,'tenant.stop-details.prepare.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(829,'tenant.stop-details.prepare.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(830,'tenant.stop-details.prepare.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(831,'tenant.stop-details.prepare.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(832,'tenant.stop-details.prepare.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(833,'tenant.stop-details.prepare.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(834,'tenant.stop-details.prepare.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(835,'tenant.stop-details.prepare.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(836,'tenant.stop-details.prepare.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(837,'tenant.stop-details.prepare.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(838,'tenant.stop-details.prepare.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(839,'tenant.stop-details.prepare.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(840,'tenant.stop-details.prepare.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(841,'tenant.student.bording.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(842,'tenant.student.bording.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(843,'tenant.student.bording.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(844,'tenant.student.bording.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(845,'tenant.student.bording.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(846,'tenant.student.bording.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(847,'tenant.student.bording.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(848,'tenant.student.bording.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(849,'tenant.student.bording.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(850,'tenant.student.bording.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(851,'tenant.student.bording.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(852,'tenant.student.bording.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(853,'tenant.student.bording.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(854,'tenant.student.bording.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(855,'tenant.trip.incident.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(856,'tenant.trip.incident.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(857,'tenant.trip.incident.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(858,'tenant.trip.incident.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(859,'tenant.trip.incident.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(860,'tenant.trip.incident.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(861,'tenant.trip.incident.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(862,'tenant.trip.incident.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(863,'tenant.trip.incident.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(864,'tenant.trip.incident.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(865,'tenant.trip.incident.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(866,'tenant.trip.incident.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(867,'tenant.trip.incident.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(868,'tenant.trip.incident.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(869,'tenant.trip-approve.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(870,'tenant.trip-approve.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(871,'tenant.trip-approve.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(872,'tenant.trip-approve.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(873,'tenant.trip-approve.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(874,'tenant.trip-approve.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(875,'tenant.trip-approve.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(876,'tenant.trip-approve.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(877,'tenant.trip-approve.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(878,'tenant.trip-approve.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(879,'tenant.trip-approve.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(880,'tenant.trip-approve.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(881,'tenant.trip-approve.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(882,'tenant.trip-approve.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(883,'tenant.student-allocation.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(884,'tenant.student-allocation.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(885,'tenant.student-allocation.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(886,'tenant.student-allocation.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(887,'tenant.student-allocation.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(888,'tenant.student-allocation.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(889,'tenant.student-allocation.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(890,'tenant.student-allocation.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(891,'tenant.student-allocation.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(892,'tenant.student-allocation.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(893,'tenant.student-allocation.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(894,'tenant.student-allocation.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(895,'tenant.student-allocation.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(896,'tenant.student-allocation.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(897,'tenant.fee-master.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(898,'tenant.fee-master.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(899,'tenant.fee-master.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(900,'tenant.fee-master.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(901,'tenant.fee-master.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(902,'tenant.fee-master.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(903,'tenant.fee-master.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(904,'tenant.fee-master.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(905,'tenant.fee-master.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(906,'tenant.fee-master.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(907,'tenant.fee-master.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(908,'tenant.fee-master.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(909,'tenant.fee-master.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(910,'tenant.fee-master.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(911,'tenant.fine-detail.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(912,'tenant.fine-detail.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(913,'tenant.fine-detail.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(914,'tenant.fine-detail.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(915,'tenant.fine-detail.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(916,'tenant.fine-detail.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(917,'tenant.fine-detail.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(918,'tenant.fine-detail.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(919,'tenant.fine-detail.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(920,'tenant.fine-detail.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(921,'tenant.fine-detail.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(922,'tenant.fine-detail.email-schedule','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(923,'tenant.fine-detail.remark','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(924,'tenant.fine-detail.pdf','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(925,'tenant.fee-collection.create','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(926,'tenant.fee-collection.view','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(927,'tenant.fee-collection.viewAny','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(928,'tenant.fee-collection.update','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(929,'tenant.fee-collection.delete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(930,'tenant.fee-collection.restore','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(931,'tenant.fee-collection.forceDelete','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(932,'tenant.fee-collection.import','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(933,'tenant.fee-collection.export','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(934,'tenant.fee-collection.print','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(935,'tenant.fee-collection.status','web','2026-02-01 06:03:01','2026-02-01 06:03:01'),(936,'tenant.fee-collection.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(937,'tenant.fee-collection.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(938,'tenant.fee-collection.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(939,'tenant.student-pay-log.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(940,'tenant.student-pay-log.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(941,'tenant.student-pay-log.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(942,'tenant.student-pay-log.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(943,'tenant.student-pay-log.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(944,'tenant.student-pay-log.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(945,'tenant.student-pay-log.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(946,'tenant.student-pay-log.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(947,'tenant.student-pay-log.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(948,'tenant.student-pay-log.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(949,'tenant.student-pay-log.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(950,'tenant.student-pay-log.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(951,'tenant.student-pay-log.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(952,'tenant.student-pay-log.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(953,'tenant.route-performance.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(954,'tenant.route-performance.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(955,'tenant.route-performance.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(956,'tenant.route-performance.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(957,'tenant.route-performance.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(958,'tenant.route-performance.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(959,'tenant.route-performance.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(960,'tenant.route-performance.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(961,'tenant.route-performance.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(962,'tenant.route-performance.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(963,'tenant.route-performance.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(964,'tenant.route-performance.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(965,'tenant.route-performance.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(966,'tenant.route-performance.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(967,'tenant.student-transport-usage.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(968,'tenant.student-transport-usage.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(969,'tenant.student-transport-usage.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(970,'tenant.student-transport-usage.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(971,'tenant.student-transport-usage.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(972,'tenant.student-transport-usage.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(973,'tenant.student-transport-usage.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(974,'tenant.student-transport-usage.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(975,'tenant.student-transport-usage.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(976,'tenant.student-transport-usage.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(977,'tenant.student-transport-usage.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(978,'tenant.student-transport-usage.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(979,'tenant.student-transport-usage.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(980,'tenant.student-transport-usage.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(981,'tenant.stop-analysis.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(982,'tenant.stop-analysis.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(983,'tenant.stop-analysis.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(984,'tenant.stop-analysis.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(985,'tenant.stop-analysis.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(986,'tenant.stop-analysis.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(987,'tenant.stop-analysis.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(988,'tenant.stop-analysis.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(989,'tenant.stop-analysis.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(990,'tenant.stop-analysis.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(991,'tenant.stop-analysis.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(992,'tenant.stop-analysis.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(993,'tenant.stop-analysis.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(994,'tenant.stop-analysis.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(995,'tenant.trip-execution.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(996,'tenant.trip-execution.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(997,'tenant.trip-execution.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(998,'tenant.trip-execution.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(999,'tenant.trip-execution.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1000,'tenant.trip-execution.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1001,'tenant.trip-execution.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1002,'tenant.trip-execution.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1003,'tenant.trip-execution.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1004,'tenant.trip-execution.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1005,'tenant.trip-execution.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1006,'tenant.trip-execution.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1007,'tenant.trip-execution.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1008,'tenant.trip-execution.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1009,'tenant.driver-performance.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1010,'tenant.driver-performance.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1011,'tenant.driver-performance.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1012,'tenant.driver-performance.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1013,'tenant.driver-performance.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1014,'tenant.driver-performance.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1015,'tenant.driver-performance.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1016,'tenant.driver-performance.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1017,'tenant.driver-performance.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1018,'tenant.driver-performance.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1019,'tenant.driver-performance.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1020,'tenant.driver-performance.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1021,'tenant.driver-performance.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1022,'tenant.driver-performance.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1023,'tenant.transport-finance.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1024,'tenant.transport-finance.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1025,'tenant.transport-finance.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1026,'tenant.transport-finance.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1027,'tenant.transport-finance.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1028,'tenant.transport-finance.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1029,'tenant.transport-finance.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1030,'tenant.transport-finance.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1031,'tenant.transport-finance.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1032,'tenant.transport-finance.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1033,'tenant.transport-finance.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1034,'tenant.transport-finance.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1035,'tenant.transport-finance.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1036,'tenant.transport-finance.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1037,'tenant.cost-maintenance.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1038,'tenant.cost-maintenance.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1039,'tenant.cost-maintenance.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1040,'tenant.cost-maintenance.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1041,'tenant.cost-maintenance.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1042,'tenant.cost-maintenance.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1043,'tenant.cost-maintenance.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1044,'tenant.cost-maintenance.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1045,'tenant.cost-maintenance.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1046,'tenant.cost-maintenance.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1047,'tenant.cost-maintenance.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1048,'tenant.cost-maintenance.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1049,'tenant.cost-maintenance.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1050,'tenant.cost-maintenance.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1051,'tenant.management-dashboard.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1052,'tenant.management-dashboard.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1053,'tenant.management-dashboard.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1054,'tenant.management-dashboard.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1055,'tenant.management-dashboard.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1056,'tenant.management-dashboard.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1057,'tenant.management-dashboard.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1058,'tenant.management-dashboard.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1059,'tenant.management-dashboard.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1060,'tenant.management-dashboard.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1061,'tenant.management-dashboard.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1062,'tenant.management-dashboard.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1063,'tenant.management-dashboard.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1064,'tenant.management-dashboard.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1065,'tenant.student-boarding.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1066,'tenant.student-boarding.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1067,'tenant.student-boarding.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1068,'tenant.student-boarding.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1069,'tenant.student-boarding.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1070,'tenant.student-boarding.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1071,'tenant.student-boarding.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1072,'tenant.student-boarding.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1073,'tenant.student-boarding.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1074,'tenant.student-boarding.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1075,'tenant.student-boarding.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1076,'tenant.student-boarding.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1077,'tenant.student-boarding.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1078,'tenant.student-boarding.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1079,'tenant.notifications.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1080,'tenant.notifications.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1081,'tenant.notifications.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1082,'tenant.notifications.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1083,'tenant.notifications.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1084,'tenant.notifications.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1085,'tenant.notifications.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1086,'tenant.notifications.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1087,'tenant.notifications.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1088,'tenant.notifications.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1089,'tenant.notifications.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1090,'tenant.notifications.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1091,'tenant.notifications.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1092,'tenant.notifications.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1093,'tenant.universal.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1094,'tenant.universal.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1095,'tenant.universal.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1096,'tenant.universal.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1097,'tenant.universal.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1098,'tenant.universal.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1099,'tenant.universal.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1100,'tenant.universal.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1101,'tenant.universal.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1102,'tenant.universal.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1103,'tenant.universal.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1104,'tenant.universal.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1105,'tenant.universal.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1106,'tenant.universal.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1107,'tenant.vendor-dashboard.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1108,'tenant.vendor-dashboard.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1109,'tenant.vendor-dashboard.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1110,'tenant.vendor-dashboard.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1111,'tenant.vendor-dashboard.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1112,'tenant.vendor-dashboard.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1113,'tenant.vendor-dashboard.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1114,'tenant.vendor-dashboard.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1115,'tenant.vendor-dashboard.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1116,'tenant.vendor-dashboard.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1117,'tenant.vendor-dashboard.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1118,'tenant.vendor-dashboard.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1119,'tenant.vendor-dashboard.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1120,'tenant.vendor-dashboard.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1121,'tenant.vendor.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1122,'tenant.vendor.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1123,'tenant.vendor.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1124,'tenant.vendor.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1125,'tenant.vendor.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1126,'tenant.vendor.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1127,'tenant.vendor.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1128,'tenant.vendor.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1129,'tenant.vendor.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1130,'tenant.vendor.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1131,'tenant.vendor.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1132,'tenant.vendor.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1133,'tenant.vendor.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1134,'tenant.vendor.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1135,'tenant.vendor-item.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1136,'tenant.vendor-item.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1137,'tenant.vendor-item.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1138,'tenant.vendor-item.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1139,'tenant.vendor-item.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1140,'tenant.vendor-item.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1141,'tenant.vendor-item.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1142,'tenant.vendor-item.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1143,'tenant.vendor-item.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1144,'tenant.vendor-item.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1145,'tenant.vendor-item.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1146,'tenant.vendor-item.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1147,'tenant.vendor-item.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1148,'tenant.vendor-item.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1149,'tenant.vendor-agreement.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1150,'tenant.vendor-agreement.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1151,'tenant.vendor-agreement.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1152,'tenant.vendor-agreement.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1153,'tenant.vendor-agreement.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1154,'tenant.vendor-agreement.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1155,'tenant.vendor-agreement.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1156,'tenant.vendor-agreement.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1157,'tenant.vendor-agreement.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1158,'tenant.vendor-agreement.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1159,'tenant.vendor-agreement.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1160,'tenant.vendor-agreement.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1161,'tenant.vendor-agreement.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1162,'tenant.vendor-agreement.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1163,'tenant.vendor-invoice.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1164,'tenant.vendor-invoice.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1165,'tenant.vendor-invoice.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1166,'tenant.vendor-invoice.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1167,'tenant.vendor-invoice.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1168,'tenant.vendor-invoice.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1169,'tenant.vendor-invoice.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1170,'tenant.vendor-invoice.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1171,'tenant.vendor-invoice.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1172,'tenant.vendor-invoice.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1173,'tenant.vendor-invoice.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1174,'tenant.vendor-invoice.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1175,'tenant.vendor-invoice.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1176,'tenant.vendor-invoice.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1177,'tenant.vendor-payment.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1178,'tenant.vendor-payment.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1179,'tenant.vendor-payment.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1180,'tenant.vendor-payment.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1181,'tenant.vendor-payment.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1182,'tenant.vendor-payment.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1183,'tenant.vendor-payment.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1184,'tenant.vendor-payment.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1185,'tenant.vendor-payment.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1186,'tenant.vendor-payment.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1187,'tenant.vendor-payment.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1188,'tenant.vendor-payment.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1189,'tenant.vendor-payment.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1190,'tenant.vendor-payment.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1191,'tenant.usage-log.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1192,'tenant.usage-log.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1193,'tenant.usage-log.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1194,'tenant.usage-log.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1195,'tenant.usage-log.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1196,'tenant.usage-log.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1197,'tenant.usage-log.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1198,'tenant.usage-log.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1199,'tenant.usage-log.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1200,'tenant.usage-log.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1201,'tenant.usage-log.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1202,'tenant.usage-log.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1203,'tenant.usage-log.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1204,'tenant.usage-log.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1205,'tenant.complaint-dashboard.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1206,'tenant.complaint-dashboard.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1207,'tenant.complaint-dashboard.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1208,'tenant.complaint-dashboard.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1209,'tenant.complaint-dashboard.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1210,'tenant.complaint-dashboard.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1211,'tenant.complaint-dashboard.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1212,'tenant.complaint-dashboard.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1213,'tenant.complaint-dashboard.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1214,'tenant.complaint-dashboard.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1215,'tenant.complaint-dashboard.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1216,'tenant.complaint-dashboard.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1217,'tenant.complaint-dashboard.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1218,'tenant.complaint-dashboard.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1219,'tenant.complaint-category.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1220,'tenant.complaint-category.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1221,'tenant.complaint-category.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1222,'tenant.complaint-category.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1223,'tenant.complaint-category.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1224,'tenant.complaint-category.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1225,'tenant.complaint-category.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1226,'tenant.complaint-category.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1227,'tenant.complaint-category.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1228,'tenant.complaint-category.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1229,'tenant.complaint-category.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1230,'tenant.complaint-category.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1231,'tenant.complaint-category.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1232,'tenant.complaint-category.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1233,'tenant.department-sla.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1234,'tenant.department-sla.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1235,'tenant.department-sla.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1236,'tenant.department-sla.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1237,'tenant.department-sla.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1238,'tenant.department-sla.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1239,'tenant.department-sla.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1240,'tenant.department-sla.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1241,'tenant.department-sla.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1242,'tenant.department-sla.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1243,'tenant.department-sla.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1244,'tenant.department-sla.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1245,'tenant.department-sla.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1246,'tenant.department-sla.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1247,'tenant.complaint.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1248,'tenant.complaint.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1249,'tenant.complaint.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1250,'tenant.complaint.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1251,'tenant.complaint.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1252,'tenant.complaint.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1253,'tenant.complaint.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1254,'tenant.complaint.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1255,'tenant.complaint.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1256,'tenant.complaint.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1257,'tenant.complaint.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1258,'tenant.complaint.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1259,'tenant.complaint.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1260,'tenant.complaint.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1261,'tenant.medical-check.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1262,'tenant.medical-check.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1263,'tenant.medical-check.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1264,'tenant.medical-check.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1265,'tenant.medical-check.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1266,'tenant.medical-check.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1267,'tenant.medical-check.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1268,'tenant.medical-check.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1269,'tenant.medical-check.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1270,'tenant.medical-check.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1271,'tenant.medical-check.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1272,'tenant.medical-check.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1273,'tenant.medical-check.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1274,'tenant.medical-check.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1275,'tenant.complaint-action.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1276,'tenant.complaint-action.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1277,'tenant.complaint-action.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1278,'tenant.complaint-action.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1279,'tenant.complaint-action.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1280,'tenant.complaint-action.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1281,'tenant.complaint-action.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1282,'tenant.complaint-action.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1283,'tenant.complaint-action.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1284,'tenant.complaint-action.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1285,'tenant.complaint-action.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1286,'tenant.complaint-action.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1287,'tenant.complaint-action.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1288,'tenant.complaint-action.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1289,'tenant.ai-insights.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1290,'tenant.ai-insights.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1291,'tenant.ai-insights.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1292,'tenant.ai-insights.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1293,'tenant.ai-insights.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1294,'tenant.ai-insights.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1295,'tenant.ai-insights.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1296,'tenant.ai-insights.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1297,'tenant.ai-insights.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1298,'tenant.ai-insights.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1299,'tenant.ai-insights.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1300,'tenant.ai-insights.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1301,'tenant.ai-insights.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1302,'tenant.ai-insights.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1303,'tenant.action-type.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1304,'tenant.action-type.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1305,'tenant.action-type.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1306,'tenant.action-type.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1307,'tenant.action-type.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1308,'tenant.action-type.restore','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1309,'tenant.action-type.forceDelete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1310,'tenant.action-type.import','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1311,'tenant.action-type.export','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1312,'tenant.action-type.print','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1313,'tenant.action-type.status','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1314,'tenant.action-type.email-schedule','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1315,'tenant.action-type.remark','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1316,'tenant.action-type.pdf','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1317,'tenant.home-works.create','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1318,'tenant.home-works.view','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1319,'tenant.home-works.viewAny','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1320,'tenant.home-works.update','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1321,'tenant.home-works.delete','web','2026-02-01 06:03:02','2026-02-01 06:03:02'),(1322,'tenant.home-works.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1323,'tenant.home-works.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1324,'tenant.home-works.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1325,'tenant.home-works.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1326,'tenant.home-works.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1327,'tenant.home-works.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1328,'tenant.home-works.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1329,'tenant.home-works.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1330,'tenant.home-works.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1331,'tenant.rule-engine-config.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1332,'tenant.rule-engine-config.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1333,'tenant.rule-engine-config.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1334,'tenant.rule-engine-config.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1335,'tenant.rule-engine-config.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1336,'tenant.rule-engine-config.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1337,'tenant.rule-engine-config.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1338,'tenant.rule-engine-config.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1339,'tenant.rule-engine-config.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1340,'tenant.rule-engine-config.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1341,'tenant.rule-engine-config.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1342,'tenant.rule-engine-config.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1343,'tenant.rule-engine-config.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1344,'tenant.rule-engine-config.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1345,'tenant.homework-submission.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1346,'tenant.homework-submission.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1347,'tenant.homework-submission.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1348,'tenant.homework-submission.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1349,'tenant.homework-submission.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1350,'tenant.homework-submission.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1351,'tenant.homework-submission.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1352,'tenant.homework-submission.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1353,'tenant.homework-submission.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1354,'tenant.homework-submission.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1355,'tenant.homework-submission.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1356,'tenant.homework-submission.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1357,'tenant.homework-submission.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1358,'tenant.homework-submission.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1359,'tenant.trigger-event.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1360,'tenant.trigger-event.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1361,'tenant.trigger-event.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1362,'tenant.trigger-event.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1363,'tenant.trigger-event.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1364,'tenant.trigger-event.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1365,'tenant.trigger-event.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1366,'tenant.trigger-event.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1367,'tenant.trigger-event.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1368,'tenant.trigger-event.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1369,'tenant.trigger-event.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1370,'tenant.trigger-event.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1371,'tenant.trigger-event.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1372,'tenant.trigger-event.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1373,'tenant.circular-goals.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1374,'tenant.circular-goals.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1375,'tenant.circular-goals.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1376,'tenant.circular-goals.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1377,'tenant.circular-goals.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1378,'tenant.circular-goals.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1379,'tenant.circular-goals.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1380,'tenant.circular-goals.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1381,'tenant.circular-goals.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1382,'tenant.circular-goals.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1383,'tenant.circular-goals.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1384,'tenant.circular-goals.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1385,'tenant.circular-goals.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1386,'tenant.circular-goals.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1387,'tenant.hpc-parameters.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1388,'tenant.hpc-parameters.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1389,'tenant.hpc-parameters.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1390,'tenant.hpc-parameters.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1391,'tenant.hpc-parameters.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1392,'tenant.hpc-parameters.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1393,'tenant.hpc-parameters.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1394,'tenant.hpc-parameters.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1395,'tenant.hpc-parameters.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1396,'tenant.hpc-parameters.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1397,'tenant.hpc-parameters.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1398,'tenant.hpc-parameters.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1399,'tenant.hpc-parameters.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1400,'tenant.hpc-parameters.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1401,'tenant.performance-descriptor.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1402,'tenant.performance-descriptor.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1403,'tenant.performance-descriptor.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1404,'tenant.performance-descriptor.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1405,'tenant.performance-descriptor.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1406,'tenant.performance-descriptor.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1407,'tenant.performance-descriptor.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1408,'tenant.performance-descriptor.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1409,'tenant.performance-descriptor.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1410,'tenant.performance-descriptor.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1411,'tenant.performance-descriptor.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1412,'tenant.performance-descriptor.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1413,'tenant.performance-descriptor.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1414,'tenant.performance-descriptor.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1415,'tenant.knowledge-graph-validation.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1416,'tenant.knowledge-graph-validation.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1417,'tenant.knowledge-graph-validation.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1418,'tenant.knowledge-graph-validation.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1419,'tenant.knowledge-graph-validation.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1420,'tenant.knowledge-graph-validation.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1421,'tenant.knowledge-graph-validation.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1422,'tenant.knowledge-graph-validation.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1423,'tenant.knowledge-graph-validation.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1424,'tenant.knowledge-graph-validation.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1425,'tenant.knowledge-graph-validation.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1426,'tenant.knowledge-graph-validation.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1427,'tenant.knowledge-graph-validation.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1428,'tenant.knowledge-graph-validation.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1429,'tenant.learning-activities.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1430,'tenant.learning-activities.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1431,'tenant.learning-activities.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1432,'tenant.learning-activities.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1433,'tenant.learning-activities.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1434,'tenant.learning-activities.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1435,'tenant.learning-activities.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1436,'tenant.learning-activities.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1437,'tenant.learning-activities.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1438,'tenant.learning-activities.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1439,'tenant.learning-activities.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1440,'tenant.learning-activities.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1441,'tenant.learning-activities.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1442,'tenant.learning-activities.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1443,'tenant.learning-outcomes.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1444,'tenant.learning-outcomes.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1445,'tenant.learning-outcomes.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1446,'tenant.learning-outcomes.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1447,'tenant.learning-outcomes.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1448,'tenant.learning-outcomes.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1449,'tenant.learning-outcomes.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1450,'tenant.learning-outcomes.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1451,'tenant.learning-outcomes.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1452,'tenant.learning-outcomes.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1453,'tenant.learning-outcomes.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1454,'tenant.learning-outcomes.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1455,'tenant.learning-outcomes.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1456,'tenant.learning-outcomes.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1457,'tenant.student-hpc-evaluation.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1458,'tenant.student-hpc-evaluation.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1459,'tenant.student-hpc-evaluation.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1460,'tenant.student-hpc-evaluation.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1461,'tenant.student-hpc-evaluation.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1462,'tenant.student-hpc-evaluation.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1463,'tenant.student-hpc-evaluation.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1464,'tenant.student-hpc-evaluation.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1465,'tenant.student-hpc-evaluation.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1466,'tenant.student-hpc-evaluation.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1467,'tenant.student-hpc-evaluation.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1468,'tenant.student-hpc-evaluation.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1469,'tenant.student-hpc-evaluation.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1470,'tenant.student-hpc-evaluation.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1471,'tenant.outcome-questions.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1472,'tenant.outcome-questions.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1473,'tenant.outcome-questions.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1474,'tenant.outcome-questions.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1475,'tenant.outcome-questions.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1476,'tenant.outcome-questions.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1477,'tenant.outcome-questions.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1478,'tenant.outcome-questions.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1479,'tenant.outcome-questions.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1480,'tenant.outcome-questions.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1481,'tenant.outcome-questions.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1482,'tenant.outcome-questions.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1483,'tenant.outcome-questions.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1484,'tenant.outcome-questions.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1485,'tenant.syllabus-coverage-snapshot.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1486,'tenant.syllabus-coverage-snapshot.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1487,'tenant.syllabus-coverage-snapshot.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1488,'tenant.syllabus-coverage-snapshot.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1489,'tenant.syllabus-coverage-snapshot.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1490,'tenant.syllabus-coverage-snapshot.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1491,'tenant.syllabus-coverage-snapshot.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1492,'tenant.syllabus-coverage-snapshot.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1493,'tenant.syllabus-coverage-snapshot.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1494,'tenant.syllabus-coverage-snapshot.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1495,'tenant.syllabus-coverage-snapshot.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1496,'tenant.syllabus-coverage-snapshot.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1497,'tenant.syllabus-coverage-snapshot.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1498,'tenant.syllabus-coverage-snapshot.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1499,'tenant.topic-equivalency.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1500,'tenant.topic-equivalency.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1501,'tenant.topic-equivalency.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1502,'tenant.topic-equivalency.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1503,'tenant.topic-equivalency.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1504,'tenant.topic-equivalency.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1505,'tenant.topic-equivalency.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1506,'tenant.topic-equivalency.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1507,'tenant.topic-equivalency.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1508,'tenant.topic-equivalency.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1509,'tenant.topic-equivalency.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1510,'tenant.topic-equivalency.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1511,'tenant.topic-equivalency.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1512,'tenant.topic-equivalency.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1513,'tenant.author.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1514,'tenant.author.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1515,'tenant.author.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1516,'tenant.author.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1517,'tenant.author.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1518,'tenant.author.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1519,'tenant.author.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1520,'tenant.author.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1521,'tenant.author.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1522,'tenant.author.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1523,'tenant.author.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1524,'tenant.author.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1525,'tenant.author.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1526,'tenant.author.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1527,'tenant.book.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1528,'tenant.book.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1529,'tenant.book.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1530,'tenant.book.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1531,'tenant.book.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1532,'tenant.book.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1533,'tenant.book.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1534,'tenant.book.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1535,'tenant.book.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1536,'tenant.book.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1537,'tenant.book.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1538,'tenant.book.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1539,'tenant.book.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1540,'tenant.book.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1541,'tenant.assessment-type.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1542,'tenant.assessment-type.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1543,'tenant.assessment-type.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1544,'tenant.assessment-type.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1545,'tenant.assessment-type.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1546,'tenant.assessment-type.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1547,'tenant.assessment-type.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1548,'tenant.assessment-type.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1549,'tenant.assessment-type.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1550,'tenant.assessment-type.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1551,'tenant.assessment-type.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1552,'tenant.assessment-type.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1553,'tenant.assessment-type.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1554,'tenant.assessment-type.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1555,'tenant.difficulty-distribution-config.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1556,'tenant.difficulty-distribution-config.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1557,'tenant.difficulty-distribution-config.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1558,'tenant.difficulty-distribution-config.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1559,'tenant.difficulty-distribution-config.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1560,'tenant.difficulty-distribution-config.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1561,'tenant.difficulty-distribution-config.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1562,'tenant.difficulty-distribution-config.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1563,'tenant.difficulty-distribution-config.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1564,'tenant.difficulty-distribution-config.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1565,'tenant.difficulty-distribution-config.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1566,'tenant.difficulty-distribution-config.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1567,'tenant.difficulty-distribution-config.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1568,'tenant.difficulty-distribution-config.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1569,'tenant.quize.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1570,'tenant.quize.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1571,'tenant.quize.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1572,'tenant.quize.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1573,'tenant.quize.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1574,'tenant.quize.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1575,'tenant.quize.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1576,'tenant.quize.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1577,'tenant.quize.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1578,'tenant.quize.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1579,'tenant.quize.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1580,'tenant.quize.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1581,'tenant.quize.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1582,'tenant.quize.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1583,'tenant.quiz-allocation.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1584,'tenant.quiz-allocation.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1585,'tenant.quiz-allocation.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1586,'tenant.quiz-allocation.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1587,'tenant.quiz-allocation.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1588,'tenant.quiz-allocation.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1589,'tenant.quiz-allocation.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1590,'tenant.quiz-allocation.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1591,'tenant.quiz-allocation.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1592,'tenant.quiz-allocation.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1593,'tenant.quiz-allocation.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1594,'tenant.quiz-allocation.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1595,'tenant.quiz-allocation.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1596,'tenant.quiz-allocation.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1597,'tenant.quiz-question.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1598,'tenant.quiz-question.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1599,'tenant.quiz-question.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1600,'tenant.quiz-question.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1601,'tenant.quiz-question.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1602,'tenant.quiz-question.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1603,'tenant.quiz-question.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1604,'tenant.quiz-question.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1605,'tenant.quiz-question.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1606,'tenant.quiz-question.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1607,'tenant.quiz-question.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1608,'tenant.quiz-question.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1609,'tenant.quiz-question.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1610,'tenant.quiz-question.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1611,'tenant.ai-question.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1612,'tenant.ai-question.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1613,'tenant.ai-question.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1614,'tenant.ai-question.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1615,'tenant.ai-question.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1616,'tenant.ai-question.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1617,'tenant.ai-question.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1618,'tenant.ai-question.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1619,'tenant.ai-question.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1620,'tenant.ai-question.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1621,'tenant.ai-question.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1622,'tenant.ai-question.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1623,'tenant.ai-question.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1624,'tenant.ai-question.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1625,'tenant.question-bank.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1626,'tenant.question-bank.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1627,'tenant.question-bank.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1628,'tenant.question-bank.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1629,'tenant.question-bank.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1630,'tenant.question-bank.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1631,'tenant.question-bank.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1632,'tenant.question-bank.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1633,'tenant.question-bank.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1634,'tenant.question-bank.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1635,'tenant.question-bank.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1636,'tenant.question-bank.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1637,'tenant.question-bank.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1638,'tenant.question-bank.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1639,'tenant.question-media-store.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1640,'tenant.question-media-store.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1641,'tenant.question-media-store.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1642,'tenant.question-media-store.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1643,'tenant.question-media-store.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1644,'tenant.question-media-store.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1645,'tenant.question-media-store.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1646,'tenant.question-media-store.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1647,'tenant.question-media-store.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1648,'tenant.question-media-store.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1649,'tenant.question-media-store.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1650,'tenant.question-media-store.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1651,'tenant.question-media-store.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1652,'tenant.question-media-store.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1653,'tenant.question-statistic.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1654,'tenant.question-statistic.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1655,'tenant.question-statistic.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1656,'tenant.question-statistic.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1657,'tenant.question-statistic.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1658,'tenant.question-statistic.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1659,'tenant.question-statistic.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1660,'tenant.question-statistic.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1661,'tenant.question-statistic.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1662,'tenant.question-statistic.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1663,'tenant.question-statistic.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1664,'tenant.question-statistic.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1665,'tenant.question-statistic.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1666,'tenant.question-statistic.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1667,'tenant.question-tag.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1668,'tenant.question-tag.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1669,'tenant.question-tag.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1670,'tenant.question-tag.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1671,'tenant.question-tag.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1672,'tenant.question-tag.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1673,'tenant.question-tag.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1674,'tenant.question-tag.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1675,'tenant.question-tag.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1676,'tenant.question-tag.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1677,'tenant.question-tag.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1678,'tenant.question-tag.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1679,'tenant.question-tag.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1680,'tenant.question-tag.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1681,'tenant.question-usage-type.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1682,'tenant.question-usage-type.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1683,'tenant.question-usage-type.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1684,'tenant.question-usage-type.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1685,'tenant.question-usage-type.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1686,'tenant.question-usage-type.restore','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1687,'tenant.question-usage-type.forceDelete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1688,'tenant.question-usage-type.import','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1689,'tenant.question-usage-type.export','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1690,'tenant.question-usage-type.print','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1691,'tenant.question-usage-type.status','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1692,'tenant.question-usage-type.email-schedule','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1693,'tenant.question-usage-type.remark','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1694,'tenant.question-usage-type.pdf','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1695,'tenant.question-version.create','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1696,'tenant.question-version.view','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1697,'tenant.question-version.viewAny','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1698,'tenant.question-version.update','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1699,'tenant.question-version.delete','web','2026-02-01 06:03:03','2026-02-01 06:03:03'),(1700,'tenant.question-version.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1701,'tenant.question-version.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1702,'tenant.question-version.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1703,'tenant.question-version.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1704,'tenant.question-version.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1705,'tenant.question-version.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1706,'tenant.question-version.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1707,'tenant.question-version.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1708,'tenant.question-version.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1709,'tenant.ai-question-generator.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1710,'tenant.ai-question-generator.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1711,'tenant.ai-question-generator.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1712,'tenant.ai-question-generator.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1713,'tenant.ai-question-generator.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1714,'tenant.ai-question-generator.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1715,'tenant.ai-question-generator.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1716,'tenant.ai-question-generator.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1717,'tenant.ai-question-generator.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1718,'tenant.ai-question-generator.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1719,'tenant.ai-question-generator.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1720,'tenant.ai-question-generator.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1721,'tenant.ai-question-generator.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1722,'tenant.ai-question-generator.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1723,'tenant.question-usage-log.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1724,'tenant.question-usage-log.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1725,'tenant.question-usage-log.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1726,'tenant.question-usage-log.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1727,'tenant.question-usage-log.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1728,'tenant.question-usage-log.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1729,'tenant.question-usage-log.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1730,'tenant.question-usage-log.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1731,'tenant.question-usage-log.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1732,'tenant.question-usage-log.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1733,'tenant.question-usage-log.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1734,'tenant.question-usage-log.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1735,'tenant.question-usage-log.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1736,'tenant.question-usage-log.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1737,'tenant.lesson.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1738,'tenant.lesson.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1739,'tenant.lesson.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1740,'tenant.lesson.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1741,'tenant.lesson.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1742,'tenant.lesson.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1743,'tenant.lesson.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1744,'tenant.lesson.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1745,'tenant.lesson.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1746,'tenant.lesson.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1747,'tenant.lesson.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1748,'tenant.lesson.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1749,'tenant.lesson.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1750,'tenant.lesson.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1751,'tenant.topic.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1752,'tenant.topic.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1753,'tenant.topic.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1754,'tenant.topic.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1755,'tenant.topic.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1756,'tenant.topic.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1757,'tenant.topic.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1758,'tenant.topic.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1759,'tenant.topic.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1760,'tenant.topic.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1761,'tenant.topic.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1762,'tenant.topic.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1763,'tenant.topic.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1764,'tenant.topic.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1765,'tenant.competency-type.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1766,'tenant.competency-type.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1767,'tenant.competency-type.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1768,'tenant.competency-type.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1769,'tenant.competency-type.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1770,'tenant.competency-type.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1771,'tenant.competency-type.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1772,'tenant.competency-type.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1773,'tenant.competency-type.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1774,'tenant.competency-type.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1775,'tenant.competency-type.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1776,'tenant.competency-type.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1777,'tenant.competency-type.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1778,'tenant.competency-type.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1779,'tenant.topic-competency.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1780,'tenant.topic-competency.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1781,'tenant.topic-competency.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1782,'tenant.topic-competency.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1783,'tenant.topic-competency.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1784,'tenant.topic-competency.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1785,'tenant.topic-competency.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1786,'tenant.topic-competency.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1787,'tenant.topic-competency.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1788,'tenant.topic-competency.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1789,'tenant.topic-competency.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1790,'tenant.topic-competency.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1791,'tenant.topic-competency.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1792,'tenant.topic-competency.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1793,'tenant.bloom-taxonomy.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1794,'tenant.bloom-taxonomy.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1795,'tenant.bloom-taxonomy.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1796,'tenant.bloom-taxonomy.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1797,'tenant.bloom-taxonomy.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1798,'tenant.bloom-taxonomy.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1799,'tenant.bloom-taxonomy.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1800,'tenant.bloom-taxonomy.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1801,'tenant.bloom-taxonomy.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1802,'tenant.bloom-taxonomy.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1803,'tenant.bloom-taxonomy.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1804,'tenant.bloom-taxonomy.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1805,'tenant.bloom-taxonomy.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1806,'tenant.bloom-taxonomy.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1807,'tenant.question-type.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1808,'tenant.question-type.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1809,'tenant.question-type.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1810,'tenant.question-type.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1811,'tenant.question-type.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1812,'tenant.question-type.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1813,'tenant.question-type.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1814,'tenant.question-type.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1815,'tenant.question-type.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1816,'tenant.question-type.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1817,'tenant.question-type.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1818,'tenant.question-type.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1819,'tenant.question-type.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1820,'tenant.question-type.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1821,'tenant.complexity-level.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1822,'tenant.complexity-level.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1823,'tenant.complexity-level.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1824,'tenant.complexity-level.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1825,'tenant.complexity-level.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1826,'tenant.complexity-level.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1827,'tenant.complexity-level.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1828,'tenant.complexity-level.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1829,'tenant.complexity-level.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1830,'tenant.complexity-level.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1831,'tenant.complexity-level.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1832,'tenant.complexity-level.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1833,'tenant.complexity-level.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1834,'tenant.complexity-level.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1835,'tenant.cognitive-skill.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1836,'tenant.cognitive-skill.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1837,'tenant.cognitive-skill.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1838,'tenant.cognitive-skill.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1839,'tenant.cognitive-skill.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1840,'tenant.cognitive-skill.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1841,'tenant.cognitive-skill.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1842,'tenant.cognitive-skill.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1843,'tenant.cognitive-skill.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1844,'tenant.cognitive-skill.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1845,'tenant.cognitive-skill.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1846,'tenant.cognitive-skill.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1847,'tenant.cognitive-skill.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1848,'tenant.cognitive-skill.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1849,'tenant.performance-category.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1850,'tenant.performance-category.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1851,'tenant.performance-category.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1852,'tenant.performance-category.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1853,'tenant.performance-category.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1854,'tenant.performance-category.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1855,'tenant.performance-category.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1856,'tenant.performance-category.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1857,'tenant.performance-category.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1858,'tenant.performance-category.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1859,'tenant.performance-category.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1860,'tenant.performance-category.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1861,'tenant.performance-category.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1862,'tenant.performance-category.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1863,'tenant.grade-division.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1864,'tenant.grade-division.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1865,'tenant.grade-division.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1866,'tenant.grade-division.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1867,'tenant.grade-division.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1868,'tenant.grade-division.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1869,'tenant.grade-division.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1870,'tenant.grade-division.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1871,'tenant.grade-division.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1872,'tenant.grade-division.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1873,'tenant.grade-division.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1874,'tenant.grade-division.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1875,'tenant.grade-division.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1876,'tenant.grade-division.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1877,'tenant.competencies.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1878,'tenant.competencies.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1879,'tenant.competencies.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1880,'tenant.competencies.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1881,'tenant.competencies.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1882,'tenant.competencies.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1883,'tenant.competencies.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1884,'tenant.competencies.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1885,'tenant.competencies.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1886,'tenant.competencies.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1887,'tenant.competencies.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1888,'tenant.competencies.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1889,'tenant.competencies.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1890,'tenant.competencies.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1891,'tenant.ques-type-specificity.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1892,'tenant.ques-type-specificity.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1893,'tenant.ques-type-specificity.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1894,'tenant.ques-type-specificity.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1895,'tenant.ques-type-specificity.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1896,'tenant.ques-type-specificity.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1897,'tenant.ques-type-specificity.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1898,'tenant.ques-type-specificity.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1899,'tenant.ques-type-specificity.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1900,'tenant.ques-type-specificity.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1901,'tenant.ques-type-specificity.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1902,'tenant.ques-type-specificity.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1903,'tenant.ques-type-specificity.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1904,'tenant.ques-type-specificity.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1905,'tenant.syllabus-schedule.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1906,'tenant.syllabus-schedule.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1907,'tenant.syllabus-schedule.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1908,'tenant.syllabus-schedule.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1909,'tenant.syllabus-schedule.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1910,'tenant.syllabus-schedule.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1911,'tenant.syllabus-schedule.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1912,'tenant.syllabus-schedule.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1913,'tenant.syllabus-schedule.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1914,'tenant.syllabus-schedule.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1915,'tenant.syllabus-schedule.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1916,'tenant.syllabus-schedule.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1917,'tenant.syllabus-schedule.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1918,'tenant.syllabus-schedule.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1919,'tenant.quest.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1920,'tenant.quest.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1921,'tenant.quest.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1922,'tenant.quest.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1923,'tenant.quest.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1924,'tenant.quest.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1925,'tenant.quest.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1926,'tenant.quest.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1927,'tenant.quest.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1928,'tenant.quest.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1929,'tenant.quest.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1930,'tenant.quest.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1931,'tenant.quest.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1932,'tenant.quest.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1933,'tenant.quest-scope.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1934,'tenant.quest-scope.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1935,'tenant.quest-scope.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1936,'tenant.quest-scope.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1937,'tenant.quest-scope.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1938,'tenant.quest-scope.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1939,'tenant.quest-scope.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1940,'tenant.quest-scope.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1941,'tenant.quest-scope.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1942,'tenant.quest-scope.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1943,'tenant.quest-scope.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1944,'tenant.quest-scope.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1945,'tenant.quest-scope.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1946,'tenant.quest-scope.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1947,'tenant.quest-question.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1948,'tenant.quest-question.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1949,'tenant.quest-question.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1950,'tenant.quest-question.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1951,'tenant.quest-question.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1952,'tenant.quest-question.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1953,'tenant.quest-question.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1954,'tenant.quest-question.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1955,'tenant.quest-question.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1956,'tenant.quest-question.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1957,'tenant.quest-question.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1958,'tenant.quest-question.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1959,'tenant.quest-question.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1960,'tenant.quest-question.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1961,'tenant.quest-allocation.create','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1962,'tenant.quest-allocation.view','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1963,'tenant.quest-allocation.viewAny','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1964,'tenant.quest-allocation.update','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1965,'tenant.quest-allocation.delete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1966,'tenant.quest-allocation.restore','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1967,'tenant.quest-allocation.forceDelete','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1968,'tenant.quest-allocation.import','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1969,'tenant.quest-allocation.export','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1970,'tenant.quest-allocation.print','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1971,'tenant.quest-allocation.status','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1972,'tenant.quest-allocation.email-schedule','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1973,'tenant.quest-allocation.remark','web','2026-02-01 06:03:04','2026-02-01 06:03:04'),(1974,'tenant.quest-allocation.pdf','web','2026-02-01 06:03:04','2026-02-01 06:03:04');
/*!40000 ALTER TABLE `sys_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_role_has_permissions_jnt`
--

DROP TABLE IF EXISTS `sys_role_has_permissions_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_role_has_permissions_jnt` (
  `permission_id` INT unsigned NOT NULL,
  `role_id` INT unsigned NOT NULL,
  PRIMARY KEY (`permission_id`,`role_id`),
  KEY `sys_role_has_permissions_jnt_role_id_foreign` (`role_id`),
  CONSTRAINT `sys_role_has_permissions_jnt_permission_id_foreign` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `sys_role_has_permissions_jnt_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_role_has_permissions_jnt`
--

LOCK TABLES `sys_role_has_permissions_jnt` WRITE;
/*!40000 ALTER TABLE `sys_role_has_permissions_jnt` DISABLE KEYS */;
INSERT INTO `sys_role_has_permissions_jnt` VALUES (1,1),(2,1),(3,1),(4,1),(5,1),(6,1),(7,1),(8,1),(9,1),(10,1),(11,1),(12,1),(13,1),(14,1),(15,1),(16,1),(17,1),(18,1),(19,1),(20,1),(21,1),(22,1),(23,1),(24,1),(25,1),(26,1),(27,1),(28,1),(29,1),(30,1),(31,1),(32,1),(33,1),(34,1),(35,1),(36,1),(37,1),(38,1),(39,1),(40,1),(41,1),(42,1),(43,1),(44,1),(45,1),(46,1),(47,1),(48,1),(49,1),(50,1),(51,1),(52,1),(53,1),(54,1),(55,1),(56,1),(57,1),(58,1),(59,1),(60,1),(61,1),(62,1),(63,1),(64,1),(65,1),(66,1),(67,1),(68,1),(69,1),(70,1),(71,1),(72,1),(73,1),(74,1),(75,1),(76,1),(77,1),(78,1),(79,1),(80,1),(81,1),(82,1),(83,1),(84,1),(85,1),(86,1),(87,1),(88,1),(89,1),(90,1),(91,1),(92,1),(93,1),(94,1),(95,1),(96,1),(97,1),(98,1),(99,1),(100,1),(101,1),(102,1),(103,1),(104,1),(105,1),(106,1),(107,1),(108,1),(109,1),(110,1),(111,1),(112,1),(113,1),(114,1),(115,1),(116,1),(117,1),(118,1),(119,1),(120,1),(121,1),(122,1),(123,1),(124,1),(125,1),(126,1),(127,1),(128,1),(129,1),(130,1),(131,1),(132,1),(133,1),(134,1),(135,1),(136,1),(137,1),(138,1),(139,1),(140,1),(141,1),(142,1),(143,1),(144,1),(145,1),(146,1),(147,1),(148,1),(149,1),(150,1),(151,1),(152,1),(153,1),(154,1),(155,1),(156,1),(157,1),(158,1),(159,1),(160,1),(161,1),(162,1),(163,1),(164,1),(165,1),(166,1),(167,1),(168,1),(169,1),(170,1),(171,1),(172,1),(173,1),(174,1),(175,1),(176,1),(177,1),(178,1),(179,1),(180,1),(181,1),(182,1),(183,1),(184,1),(185,1),(186,1),(187,1),(188,1),(189,1),(190,1),(191,1),(192,1),(193,1),(194,1),(195,1),(196,1),(197,1),(198,1),(199,1),(200,1),(201,1),(202,1),(203,1),(204,1),(205,1),(206,1),(207,1),(208,1),(209,1),(210,1),(211,1),(212,1),(213,1),(214,1),(215,1),(216,1),(217,1),(218,1),(219,1),(220,1),(221,1),(222,1),(223,1),(224,1),(225,1),(226,1),(227,1),(228,1),(229,1),(230,1),(231,1),(232,1),(233,1),(234,1),(235,1),(236,1),(237,1),(238,1),(239,1),(240,1),(241,1),(242,1),(243,1),(244,1),(245,1),(246,1),(247,1),(248,1),(249,1),(250,1),(251,1),(252,1),(253,1),(254,1),(255,1),(256,1),(257,1),(258,1),(259,1),(260,1),(261,1),(262,1),(263,1),(264,1),(265,1),(266,1),(267,1),(268,1),(269,1),(270,1),(271,1),(272,1),(273,1),(274,1),(275,1),(276,1),(277,1),(278,1),(279,1),(280,1),(281,1),(282,1),(283,1),(284,1),(285,1),(286,1),(287,1),(288,1),(289,1),(290,1),(291,1),(292,1),(293,1),(294,1),(295,1),(296,1),(297,1),(298,1),(299,1),(300,1),(301,1),(302,1),(303,1),(304,1),(305,1),(306,1),(307,1),(308,1),(309,1),(310,1),(311,1),(312,1),(313,1),(314,1),(315,1),(316,1),(317,1),(318,1),(319,1),(320,1),(321,1),(322,1),(323,1),(324,1),(325,1),(326,1),(327,1),(328,1),(329,1),(330,1),(331,1),(332,1),(333,1),(334,1),(335,1),(336,1),(337,1),(338,1),(339,1),(340,1),(341,1),(342,1),(343,1),(344,1),(345,1),(346,1),(347,1),(348,1),(349,1),(350,1),(351,1),(352,1),(353,1),(354,1),(355,1),(356,1),(357,1),(358,1),(359,1),(360,1),(361,1),(362,1),(363,1),(364,1),(365,1),(366,1),(367,1),(368,1),(369,1),(370,1),(371,1),(372,1),(373,1),(374,1),(375,1),(376,1),(377,1),(378,1),(379,1),(380,1),(381,1),(382,1),(383,1),(384,1),(385,1),(386,1),(387,1),(388,1),(389,1),(390,1),(391,1),(392,1),(393,1),(394,1),(395,1),(396,1),(397,1),(398,1),(399,1),(400,1),(401,1),(402,1),(403,1),(404,1),(405,1),(406,1),(407,1),(408,1),(409,1),(410,1),(411,1),(412,1),(413,1),(414,1),(415,1),(416,1),(417,1),(418,1),(419,1),(420,1),(421,1),(422,1),(423,1),(424,1),(425,1),(426,1),(427,1),(428,1),(429,1),(430,1),(431,1),(432,1),(433,1),(434,1),(435,1),(436,1),(437,1),(438,1),(439,1),(440,1),(441,1),(442,1),(443,1),(444,1),(445,1),(446,1),(447,1),(448,1),(449,1),(450,1),(451,1),(452,1),(453,1),(454,1),(455,1),(456,1),(457,1),(458,1),(459,1),(460,1),(461,1),(462,1),(463,1),(464,1),(465,1),(466,1),(467,1),(468,1),(469,1),(470,1),(471,1),(472,1),(473,1),(474,1),(475,1),(476,1),(477,1),(478,1),(479,1),(480,1),(481,1),(482,1),(483,1),(484,1),(485,1),(486,1),(487,1),(488,1),(489,1),(490,1),(491,1),(492,1),(493,1),(494,1),(495,1),(496,1),(497,1),(498,1),(499,1),(500,1),(501,1),(502,1),(503,1),(504,1),(505,1),(506,1),(507,1),(508,1),(509,1),(510,1),(511,1),(512,1),(513,1),(514,1),(515,1),(516,1),(517,1),(518,1),(519,1),(520,1),(521,1),(522,1),(523,1),(524,1),(525,1),(526,1),(527,1),(528,1),(529,1),(530,1),(531,1),(532,1),(533,1),(534,1),(535,1),(536,1),(537,1),(538,1),(539,1),(540,1),(541,1),(542,1),(543,1),(544,1),(545,1),(546,1),(547,1),(548,1),(549,1),(550,1),(551,1),(552,1),(553,1),(554,1),(555,1),(556,1),(557,1),(558,1),(559,1),(560,1),(561,1),(562,1),(563,1),(564,1),(565,1),(566,1),(567,1),(568,1),(569,1),(570,1),(571,1),(572,1),(573,1),(574,1),(575,1),(576,1),(577,1),(578,1),(579,1),(580,1),(581,1),(582,1),(583,1),(584,1),(585,1),(586,1),(587,1),(588,1),(589,1),(590,1),(591,1),(592,1),(593,1),(594,1),(595,1),(596,1),(597,1),(598,1),(599,1),(600,1),(601,1),(602,1),(603,1),(604,1),(605,1),(606,1),(607,1),(608,1),(609,1),(610,1),(611,1),(612,1),(613,1),(614,1),(615,1),(616,1),(617,1),(618,1),(619,1),(620,1),(621,1),(622,1),(623,1),(624,1),(625,1),(626,1),(627,1),(628,1),(629,1),(630,1),(631,1),(632,1),(633,1),(634,1),(635,1),(636,1),(637,1),(638,1),(639,1),(640,1),(641,1),(642,1),(643,1),(644,1),(645,1),(646,1),(647,1),(648,1),(649,1),(650,1),(651,1),(652,1),(653,1),(654,1),(655,1),(656,1),(657,1),(658,1),(659,1),(660,1),(661,1),(662,1),(663,1),(664,1),(665,1),(666,1),(667,1),(668,1),(669,1),(670,1),(671,1),(672,1),(673,1),(674,1),(675,1),(676,1),(677,1),(678,1),(679,1),(680,1),(681,1),(682,1),(683,1),(684,1),(685,1),(686,1),(687,1),(688,1),(689,1),(690,1),(691,1),(692,1),(693,1),(694,1),(695,1),(696,1),(697,1),(698,1),(699,1),(700,1),(701,1),(702,1),(703,1),(704,1),(705,1),(706,1),(707,1),(708,1),(709,1),(710,1),(711,1),(712,1),(713,1),(714,1),(715,1),(716,1),(717,1),(718,1),(719,1),(720,1),(721,1),(722,1),(723,1),(724,1),(725,1),(726,1),(727,1),(728,1),(729,1),(730,1),(731,1),(732,1),(733,1),(734,1),(735,1),(736,1),(737,1),(738,1),(739,1),(740,1),(741,1),(742,1),(743,1),(744,1),(745,1),(746,1),(747,1),(748,1),(749,1),(750,1),(751,1),(752,1),(753,1),(754,1),(755,1),(756,1),(757,1),(758,1),(759,1),(760,1),(761,1),(762,1),(763,1),(764,1),(765,1),(766,1),(767,1),(768,1),(769,1),(770,1),(771,1),(772,1),(773,1),(774,1),(775,1),(776,1),(777,1),(778,1),(779,1),(780,1),(781,1),(782,1),(783,1),(784,1),(785,1),(786,1),(787,1),(788,1),(789,1),(790,1),(791,1),(792,1),(793,1),(794,1),(795,1),(796,1),(797,1),(798,1),(799,1),(800,1),(801,1),(802,1),(803,1),(804,1),(805,1),(806,1),(807,1),(808,1),(809,1),(810,1),(811,1),(812,1),(813,1),(814,1),(815,1),(816,1),(817,1),(818,1),(819,1),(820,1),(821,1),(822,1),(823,1),(824,1),(825,1),(826,1),(827,1),(828,1),(829,1),(830,1),(831,1),(832,1),(833,1),(834,1),(835,1),(836,1),(837,1),(838,1),(839,1),(840,1),(841,1),(842,1),(843,1),(844,1),(845,1),(846,1),(847,1),(848,1),(849,1),(850,1),(851,1),(852,1),(853,1),(854,1),(855,1),(856,1),(857,1),(858,1),(859,1),(860,1),(861,1),(862,1),(863,1),(864,1),(865,1),(866,1),(867,1),(868,1),(869,1),(870,1),(871,1),(872,1),(873,1),(874,1),(875,1),(876,1),(877,1),(878,1),(879,1),(880,1),(881,1),(882,1),(883,1),(884,1),(885,1),(886,1),(887,1),(888,1),(889,1),(890,1),(891,1),(892,1),(893,1),(894,1),(895,1),(896,1),(897,1),(898,1),(899,1),(900,1),(901,1),(902,1),(903,1),(904,1),(905,1),(906,1),(907,1),(908,1),(909,1),(910,1),(911,1),(912,1),(913,1),(914,1),(915,1),(916,1),(917,1),(918,1),(919,1),(920,1),(921,1),(922,1),(923,1),(924,1),(925,1),(926,1),(927,1),(928,1),(929,1),(930,1),(931,1),(932,1),(933,1),(934,1),(935,1),(936,1),(937,1),(938,1),(939,1),(940,1),(941,1),(942,1),(943,1),(944,1),(945,1),(946,1),(947,1),(948,1),(949,1),(950,1),(951,1),(952,1),(953,1),(954,1),(955,1),(956,1),(957,1),(958,1),(959,1),(960,1),(961,1),(962,1),(963,1),(964,1),(965,1),(966,1),(967,1),(968,1),(969,1),(970,1),(971,1),(972,1),(973,1),(974,1),(975,1),(976,1),(977,1),(978,1),(979,1),(980,1),(981,1),(982,1),(983,1),(984,1),(985,1),(986,1),(987,1),(988,1),(989,1),(990,1),(991,1),(992,1),(993,1),(994,1),(995,1),(996,1),(997,1),(998,1),(999,1),(1000,1),(1001,1),(1002,1),(1003,1),(1004,1),(1005,1),(1006,1),(1007,1),(1008,1),(1009,1),(1010,1),(1011,1),(1012,1),(1013,1),(1014,1),(1015,1),(1016,1),(1017,1),(1018,1),(1019,1),(1020,1),(1021,1),(1022,1),(1023,1),(1024,1),(1025,1),(1026,1),(1027,1),(1028,1),(1029,1),(1030,1),(1031,1),(1032,1),(1033,1),(1034,1),(1035,1),(1036,1),(1037,1),(1038,1),(1039,1),(1040,1),(1041,1),(1042,1),(1043,1),(1044,1),(1045,1),(1046,1),(1047,1),(1048,1),(1049,1),(1050,1),(1051,1),(1052,1),(1053,1),(1054,1),(1055,1),(1056,1),(1057,1),(1058,1),(1059,1),(1060,1),(1061,1),(1062,1),(1063,1),(1064,1),(1065,1),(1066,1),(1067,1),(1068,1),(1069,1),(1070,1),(1071,1),(1072,1),(1073,1),(1074,1),(1075,1),(1076,1),(1077,1),(1078,1),(1079,1),(1080,1),(1081,1),(1082,1),(1083,1),(1084,1),(1085,1),(1086,1),(1087,1),(1088,1),(1089,1),(1090,1),(1091,1),(1092,1),(1093,1),(1094,1),(1095,1),(1096,1),(1097,1),(1098,1),(1099,1),(1100,1),(1101,1),(1102,1),(1103,1),(1104,1),(1105,1),(1106,1),(1107,1),(1108,1),(1109,1),(1110,1),(1111,1),(1112,1),(1113,1),(1114,1),(1115,1),(1116,1),(1117,1),(1118,1),(1119,1),(1120,1),(1121,1),(1122,1),(1123,1),(1124,1),(1125,1),(1126,1),(1127,1),(1128,1),(1129,1),(1130,1),(1131,1),(1132,1),(1133,1),(1134,1),(1135,1),(1136,1),(1137,1),(1138,1),(1139,1),(1140,1),(1141,1),(1142,1),(1143,1),(1144,1),(1145,1),(1146,1),(1147,1),(1148,1),(1149,1),(1150,1),(1151,1),(1152,1),(1153,1),(1154,1),(1155,1),(1156,1),(1157,1),(1158,1),(1159,1),(1160,1),(1161,1),(1162,1),(1163,1),(1164,1),(1165,1),(1166,1),(1167,1),(1168,1),(1169,1),(1170,1),(1171,1),(1172,1),(1173,1),(1174,1),(1175,1),(1176,1),(1177,1),(1178,1),(1179,1),(1180,1),(1181,1),(1182,1),(1183,1),(1184,1),(1185,1),(1186,1),(1187,1),(1188,1),(1189,1),(1190,1),(1191,1),(1192,1),(1193,1),(1194,1),(1195,1),(1196,1),(1197,1),(1198,1),(1199,1),(1200,1),(1201,1),(1202,1),(1203,1),(1204,1),(1205,1),(1206,1),(1207,1),(1208,1),(1209,1),(1210,1),(1211,1),(1212,1),(1213,1),(1214,1),(1215,1),(1216,1),(1217,1),(1218,1),(1219,1),(1220,1),(1221,1),(1222,1),(1223,1),(1224,1),(1225,1),(1226,1),(1227,1),(1228,1),(1229,1),(1230,1),(1231,1),(1232,1),(1233,1),(1234,1),(1235,1),(1236,1),(1237,1),(1238,1),(1239,1),(1240,1),(1241,1),(1242,1),(1243,1),(1244,1),(1245,1),(1246,1),(1247,1),(1248,1),(1249,1),(1250,1),(1251,1),(1252,1),(1253,1),(1254,1),(1255,1),(1256,1),(1257,1),(1258,1),(1259,1),(1260,1),(1261,1),(1262,1),(1263,1),(1264,1),(1265,1),(1266,1),(1267,1),(1268,1),(1269,1),(1270,1),(1271,1),(1272,1),(1273,1),(1274,1),(1275,1),(1276,1),(1277,1),(1278,1),(1279,1),(1280,1),(1281,1),(1282,1),(1283,1),(1284,1),(1285,1),(1286,1),(1287,1),(1288,1),(1289,1),(1290,1),(1291,1),(1292,1),(1293,1),(1294,1),(1295,1),(1296,1),(1297,1),(1298,1),(1299,1),(1300,1),(1301,1),(1302,1),(1303,1),(1304,1),(1305,1),(1306,1),(1307,1),(1308,1),(1309,1),(1310,1),(1311,1),(1312,1),(1313,1),(1314,1),(1315,1),(1316,1),(1317,1),(1318,1),(1319,1),(1320,1),(1321,1),(1322,1),(1323,1),(1324,1),(1325,1),(1326,1),(1327,1),(1328,1),(1329,1),(1330,1),(1331,1),(1332,1),(1333,1),(1334,1),(1335,1),(1336,1),(1337,1),(1338,1),(1339,1),(1340,1),(1341,1),(1342,1),(1343,1),(1344,1),(1345,1),(1346,1),(1347,1),(1348,1),(1349,1),(1350,1),(1351,1),(1352,1),(1353,1),(1354,1),(1355,1),(1356,1),(1357,1),(1358,1),(1359,1),(1360,1),(1361,1),(1362,1),(1363,1),(1364,1),(1365,1),(1366,1),(1367,1),(1368,1),(1369,1),(1370,1),(1371,1),(1372,1),(1373,1),(1374,1),(1375,1),(1376,1),(1377,1),(1378,1),(1379,1),(1380,1),(1381,1),(1382,1),(1383,1),(1384,1),(1385,1),(1386,1),(1387,1),(1388,1),(1389,1),(1390,1),(1391,1),(1392,1),(1393,1),(1394,1),(1395,1),(1396,1),(1397,1),(1398,1),(1399,1),(1400,1),(1401,1),(1402,1),(1403,1),(1404,1),(1405,1),(1406,1),(1407,1),(1408,1),(1409,1),(1410,1),(1411,1),(1412,1),(1413,1),(1414,1),(1415,1),(1416,1),(1417,1),(1418,1),(1419,1),(1420,1),(1421,1),(1422,1),(1423,1),(1424,1),(1425,1),(1426,1),(1427,1),(1428,1),(1429,1),(1430,1),(1431,1),(1432,1),(1433,1),(1434,1),(1435,1),(1436,1),(1437,1),(1438,1),(1439,1),(1440,1),(1441,1),(1442,1),(1443,1),(1444,1),(1445,1),(1446,1),(1447,1),(1448,1),(1449,1),(1450,1),(1451,1),(1452,1),(1453,1),(1454,1),(1455,1),(1456,1),(1457,1),(1458,1),(1459,1),(1460,1),(1461,1),(1462,1),(1463,1),(1464,1),(1465,1),(1466,1),(1467,1),(1468,1),(1469,1),(1470,1),(1471,1),(1472,1),(1473,1),(1474,1),(1475,1),(1476,1),(1477,1),(1478,1),(1479,1),(1480,1),(1481,1),(1482,1),(1483,1),(1484,1),(1485,1),(1486,1),(1487,1),(1488,1),(1489,1),(1490,1),(1491,1),(1492,1),(1493,1),(1494,1),(1495,1),(1496,1),(1497,1),(1498,1),(1499,1),(1500,1),(1501,1),(1502,1),(1503,1),(1504,1),(1505,1),(1506,1),(1507,1),(1508,1),(1509,1),(1510,1),(1511,1),(1512,1),(1513,1),(1514,1),(1515,1),(1516,1),(1517,1),(1518,1),(1519,1),(1520,1),(1521,1),(1522,1),(1523,1),(1524,1),(1525,1),(1526,1),(1527,1),(1528,1),(1529,1),(1530,1),(1531,1),(1532,1),(1533,1),(1534,1),(1535,1),(1536,1),(1537,1),(1538,1),(1539,1),(1540,1),(1541,1),(1542,1),(1543,1),(1544,1),(1545,1),(1546,1),(1547,1),(1548,1),(1549,1),(1550,1),(1551,1),(1552,1),(1553,1),(1554,1),(1555,1),(1556,1),(1557,1),(1558,1),(1559,1),(1560,1),(1561,1),(1562,1),(1563,1),(1564,1),(1565,1),(1566,1),(1567,1),(1568,1),(1569,1),(1570,1),(1571,1),(1572,1),(1573,1),(1574,1),(1575,1),(1576,1),(1577,1),(1578,1),(1579,1),(1580,1),(1581,1),(1582,1),(1583,1),(1584,1),(1585,1),(1586,1),(1587,1),(1588,1),(1589,1),(1590,1),(1591,1),(1592,1),(1593,1),(1594,1),(1595,1),(1596,1),(1597,1),(1598,1),(1599,1),(1600,1),(1601,1),(1602,1),(1603,1),(1604,1),(1605,1),(1606,1),(1607,1),(1608,1),(1609,1),(1610,1),(1611,1),(1612,1),(1613,1),(1614,1),(1615,1),(1616,1),(1617,1),(1618,1),(1619,1),(1620,1),(1621,1),(1622,1),(1623,1),(1624,1),(1625,1),(1626,1),(1627,1),(1628,1),(1629,1),(1630,1),(1631,1),(1632,1),(1633,1),(1634,1),(1635,1),(1636,1),(1637,1),(1638,1),(1639,1),(1640,1),(1641,1),(1642,1),(1643,1),(1644,1),(1645,1),(1646,1),(1647,1),(1648,1),(1649,1),(1650,1),(1651,1),(1652,1),(1653,1),(1654,1),(1655,1),(1656,1),(1657,1),(1658,1),(1659,1),(1660,1),(1661,1),(1662,1),(1663,1),(1664,1),(1665,1),(1666,1),(1667,1),(1668,1),(1669,1),(1670,1),(1671,1),(1672,1),(1673,1),(1674,1),(1675,1),(1676,1),(1677,1),(1678,1),(1679,1),(1680,1),(1681,1),(1682,1),(1683,1),(1684,1),(1685,1),(1686,1),(1687,1),(1688,1),(1689,1),(1690,1),(1691,1),(1692,1),(1693,1),(1694,1),(1695,1),(1696,1),(1697,1),(1698,1),(1699,1),(1700,1),(1701,1),(1702,1),(1703,1),(1704,1),(1705,1),(1706,1),(1707,1),(1708,1),(1709,1),(1710,1),(1711,1),(1712,1),(1713,1),(1714,1),(1715,1),(1716,1),(1717,1),(1718,1),(1719,1),(1720,1),(1721,1),(1722,1),(1723,1),(1724,1),(1725,1),(1726,1),(1727,1),(1728,1),(1729,1),(1730,1),(1731,1),(1732,1),(1733,1),(1734,1),(1735,1),(1736,1),(1737,1),(1738,1),(1739,1),(1740,1),(1741,1),(1742,1),(1743,1),(1744,1),(1745,1),(1746,1),(1747,1),(1748,1),(1749,1),(1750,1),(1751,1),(1752,1),(1753,1),(1754,1),(1755,1),(1756,1),(1757,1),(1758,1),(1759,1),(1760,1),(1761,1),(1762,1),(1763,1),(1764,1),(1765,1),(1766,1),(1767,1),(1768,1),(1769,1),(1770,1),(1771,1),(1772,1),(1773,1),(1774,1),(1775,1),(1776,1),(1777,1),(1778,1),(1779,1),(1780,1),(1781,1),(1782,1),(1783,1),(1784,1),(1785,1),(1786,1),(1787,1),(1788,1),(1789,1),(1790,1),(1791,1),(1792,1),(1793,1),(1794,1),(1795,1),(1796,1),(1797,1),(1798,1),(1799,1),(1800,1),(1801,1),(1802,1),(1803,1),(1804,1),(1805,1),(1806,1),(1807,1),(1808,1),(1809,1),(1810,1),(1811,1),(1812,1),(1813,1),(1814,1),(1815,1),(1816,1),(1817,1),(1818,1),(1819,1),(1820,1),(1821,1),(1822,1),(1823,1),(1824,1),(1825,1),(1826,1),(1827,1),(1828,1),(1829,1),(1830,1),(1831,1),(1832,1),(1833,1),(1834,1),(1835,1),(1836,1),(1837,1),(1838,1),(1839,1),(1840,1),(1841,1),(1842,1),(1843,1),(1844,1),(1845,1),(1846,1),(1847,1),(1848,1),(1849,1),(1850,1),(1851,1),(1852,1),(1853,1),(1854,1),(1855,1),(1856,1),(1857,1),(1858,1),(1859,1),(1860,1),(1861,1),(1862,1),(1863,1),(1864,1),(1865,1),(1866,1),(1867,1),(1868,1),(1869,1),(1870,1),(1871,1),(1872,1),(1873,1),(1874,1),(1875,1),(1876,1),(1877,1),(1878,1),(1879,1),(1880,1),(1881,1),(1882,1),(1883,1),(1884,1),(1885,1),(1886,1),(1887,1),(1888,1),(1889,1),(1890,1),(1891,1),(1892,1),(1893,1),(1894,1),(1895,1),(1896,1),(1897,1),(1898,1),(1899,1),(1900,1),(1901,1),(1902,1),(1903,1),(1904,1),(1905,1),(1906,1),(1907,1),(1908,1),(1909,1),(1910,1),(1911,1),(1912,1),(1913,1),(1914,1),(1915,1),(1916,1),(1917,1),(1918,1),(1919,1),(1920,1),(1921,1),(1922,1),(1923,1),(1924,1),(1925,1),(1926,1),(1927,1),(1928,1),(1929,1),(1930,1),(1931,1),(1932,1),(1933,1),(1934,1),(1935,1),(1936,1),(1937,1),(1938,1),(1939,1),(1940,1),(1941,1),(1942,1),(1943,1),(1944,1),(1945,1),(1946,1),(1947,1),(1948,1),(1949,1),(1950,1),(1951,1),(1952,1),(1953,1),(1954,1),(1955,1),(1956,1),(1957,1),(1958,1),(1959,1),(1960,1),(1961,1),(1962,1),(1963,1),(1964,1),(1965,1),(1966,1),(1967,1),(1968,1),(1969,1),(1970,1),(1971,1),(1972,1),(1973,1),(1974,1),(1,2),(2,2),(3,2),(4,2),(5,2),(6,2),(7,2),(8,2),(9,2),(10,2),(11,2),(12,2),(13,2),(14,2),(15,2),(16,2),(17,2),(18,2),(19,2),(20,2),(21,2),(22,2),(23,2),(24,2),(25,2),(26,2),(27,2),(28,2),(29,2),(30,2),(31,2),(32,2),(33,2),(34,2),(35,2),(36,2),(37,2),(38,2),(39,2),(40,2),(41,2),(42,2),(43,2),(44,2),(45,2),(46,2),(47,2),(48,2),(49,2),(50,2),(51,2),(52,2),(53,2),(54,2),(55,2),(56,2),(57,2),(58,2),(59,2),(60,2),(61,2),(62,2),(63,2),(64,2),(65,2),(66,2),(67,2),(68,2),(69,2),(70,2),(71,2),(72,2),(73,2),(74,2),(75,2),(76,2),(77,2),(78,2),(79,2),(80,2),(81,2),(82,2),(83,2),(84,2),(85,2),(86,2),(87,2),(88,2),(89,2),(90,2),(91,2),(92,2),(93,2),(94,2),(95,2),(96,2),(97,2),(98,2),(99,2),(100,2),(101,2),(102,2),(103,2),(104,2),(105,2),(106,2),(107,2),(108,2),(109,2),(110,2),(111,2),(112,2),(113,2),(114,2),(115,2),(116,2),(117,2),(118,2),(119,2),(120,2),(121,2),(122,2),(123,2),(124,2),(125,2),(126,2),(127,2),(128,2),(129,2),(130,2),(131,2),(132,2),(133,2),(134,2),(135,2),(136,2),(137,2),(138,2),(139,2),(140,2),(141,2),(142,2),(143,2),(144,2),(145,2),(146,2),(147,2),(148,2),(149,2),(150,2),(151,2),(152,2),(153,2),(154,2),(155,2),(156,2),(157,2),(158,2),(159,2),(160,2),(161,2),(162,2),(163,2),(164,2),(165,2),(166,2),(167,2),(168,2),(169,2),(170,2),(171,2),(172,2),(173,2),(174,2),(175,2),(176,2),(177,2),(178,2),(179,2),(180,2),(181,2),(182,2),(183,2),(184,2),(185,2),(186,2),(187,2),(188,2),(189,2),(190,2),(191,2),(192,2),(193,2),(194,2),(195,2),(196,2),(197,2),(198,2),(199,2),(200,2),(201,2),(202,2),(203,2),(204,2),(205,2),(206,2),(207,2),(208,2),(209,2),(210,2),(211,2),(212,2),(213,2),(214,2),(215,2),(216,2),(217,2),(218,2),(219,2),(220,2),(221,2),(222,2),(223,2),(224,2),(225,2),(226,2),(227,2),(228,2),(229,2),(230,2),(231,2),(232,2),(233,2),(234,2),(235,2),(236,2),(237,2),(238,2),(239,2),(240,2),(241,2),(242,2),(243,2),(244,2),(245,2),(246,2),(247,2),(248,2),(249,2),(250,2),(251,2),(252,2),(253,2),(254,2),(255,2),(256,2),(257,2),(258,2),(259,2),(260,2),(261,2),(262,2),(263,2),(264,2),(265,2),(266,2),(267,2),(268,2),(269,2),(270,2),(271,2),(272,2),(273,2),(274,2),(275,2),(276,2),(277,2),(278,2),(279,2),(280,2),(281,2),(282,2),(283,2),(284,2),(285,2),(286,2),(287,2),(288,2),(289,2),(290,2),(291,2),(292,2),(293,2),(294,2),(295,2),(296,2),(297,2),(298,2),(299,2),(300,2),(301,2),(302,2),(303,2),(304,2),(305,2),(306,2),(307,2),(308,2),(309,2),(310,2),(311,2),(312,2),(313,2),(314,2),(315,2),(316,2),(317,2),(318,2),(319,2),(320,2),(321,2),(322,2),(323,2),(324,2),(325,2),(326,2),(327,2),(328,2),(329,2),(330,2),(331,2),(332,2),(333,2),(334,2),(335,2),(336,2),(337,2),(338,2),(339,2),(340,2),(341,2),(342,2),(343,2),(344,2),(345,2),(346,2),(347,2),(348,2),(349,2),(350,2),(351,2),(352,2),(353,2),(354,2),(355,2),(356,2),(357,2),(358,2),(359,2),(360,2),(361,2),(362,2),(363,2),(364,2),(365,2),(366,2),(367,2),(368,2),(369,2),(370,2),(371,2),(372,2),(373,2),(374,2),(375,2),(376,2),(377,2),(378,2),(379,2),(380,2),(381,2),(382,2),(383,2),(384,2),(385,2),(386,2),(387,2),(388,2),(389,2),(390,2),(391,2),(392,2),(393,2),(394,2),(395,2),(396,2),(397,2),(398,2),(399,2),(400,2),(401,2),(402,2),(403,2),(404,2),(405,2),(406,2),(407,2),(408,2),(409,2),(410,2),(411,2),(412,2),(413,2),(414,2),(415,2),(416,2),(417,2),(418,2),(419,2),(420,2),(421,2),(422,2),(423,2),(424,2),(425,2),(426,2),(427,2),(428,2),(429,2),(430,2),(431,2),(432,2),(433,2),(434,2),(435,2),(436,2),(437,2),(438,2),(439,2),(440,2),(441,2),(442,2),(443,2),(444,2),(445,2),(446,2),(447,2),(448,2),(449,2),(450,2),(451,2),(452,2),(453,2),(454,2),(455,2),(456,2),(457,2),(458,2),(459,2),(460,2),(461,2),(462,2),(463,2),(464,2),(465,2),(466,2),(467,2),(468,2),(469,2),(470,2),(471,2),(472,2),(473,2),(474,2),(475,2),(476,2),(477,2),(478,2),(479,2),(480,2),(481,2),(482,2),(483,2),(484,2),(485,2),(486,2),(487,2),(488,2),(489,2),(490,2),(491,2),(492,2),(493,2),(494,2),(495,2),(496,2),(497,2),(498,2),(499,2),(500,2),(501,2),(502,2),(503,2),(504,2),(505,2),(506,2),(507,2),(508,2),(509,2),(510,2),(511,2),(512,2),(513,2),(514,2),(515,2),(516,2),(517,2),(518,2),(519,2),(520,2),(521,2),(522,2),(523,2),(524,2),(525,2),(526,2),(527,2),(528,2),(529,2),(530,2),(531,2),(532,2),(533,2),(534,2),(535,2),(536,2),(537,2),(538,2),(539,2),(540,2),(541,2),(542,2),(543,2),(544,2),(545,2),(546,2),(547,2),(548,2),(549,2),(550,2),(551,2),(552,2),(553,2),(554,2),(555,2),(556,2),(557,2),(558,2),(559,2),(560,2),(561,2),(562,2),(563,2),(564,2),(565,2),(566,2),(567,2),(568,2),(569,2),(570,2),(571,2),(572,2),(573,2),(574,2),(575,2),(576,2),(577,2),(578,2),(579,2),(580,2),(581,2),(582,2),(583,2),(584,2),(585,2),(586,2),(587,2),(588,2),(589,2),(590,2),(591,2),(592,2),(593,2),(594,2),(595,2),(596,2),(597,2),(598,2),(599,2),(600,2),(601,2),(602,2),(603,2),(604,2),(605,2),(606,2),(607,2),(608,2),(609,2),(610,2),(611,2),(612,2),(613,2),(614,2),(615,2),(616,2),(617,2),(618,2),(619,2),(620,2),(621,2),(622,2),(623,2),(624,2),(625,2),(626,2),(627,2),(628,2),(629,2),(630,2),(631,2),(632,2),(633,2),(634,2),(635,2),(636,2),(637,2),(638,2),(639,2),(640,2),(641,2),(642,2),(643,2),(644,2),(645,2),(646,2),(647,2),(648,2),(649,2),(650,2),(651,2),(652,2),(653,2),(654,2),(655,2),(656,2),(657,2),(658,2),(659,2),(660,2),(661,2),(662,2),(663,2),(664,2),(665,2),(666,2),(667,2),(668,2),(669,2),(670,2),(671,2),(672,2),(673,2),(674,2),(675,2),(676,2),(677,2),(678,2),(679,2),(680,2),(681,2),(682,2),(683,2),(684,2),(685,2),(686,2),(687,2),(688,2),(689,2),(690,2),(691,2),(692,2),(693,2),(694,2),(695,2),(696,2),(697,2),(698,2),(699,2),(700,2),(701,2),(702,2),(703,2),(704,2),(705,2),(706,2),(707,2),(708,2),(709,2),(710,2),(711,2),(712,2),(713,2),(714,2),(715,2),(716,2),(717,2),(718,2),(719,2),(720,2),(721,2),(722,2),(723,2),(724,2),(725,2),(726,2),(727,2),(728,2),(729,2),(730,2),(731,2),(732,2),(733,2),(734,2),(735,2),(736,2),(737,2),(738,2),(739,2),(740,2),(741,2),(742,2),(743,2),(744,2),(745,2),(746,2),(747,2),(748,2),(749,2),(750,2),(751,2),(752,2),(753,2),(754,2),(755,2),(756,2),(757,2),(758,2),(759,2),(760,2),(761,2),(762,2),(763,2),(764,2),(765,2),(766,2),(767,2),(768,2),(769,2),(770,2),(771,2),(772,2),(773,2),(774,2),(775,2),(776,2),(777,2),(778,2),(779,2),(780,2),(781,2),(782,2),(783,2),(784,2),(785,2),(786,2),(787,2),(788,2),(789,2),(790,2),(791,2),(792,2),(793,2),(794,2),(795,2),(796,2),(797,2),(798,2),(799,2),(800,2),(801,2),(802,2),(803,2),(804,2),(805,2),(806,2),(807,2),(808,2),(809,2),(810,2),(811,2),(812,2),(813,2),(814,2),(815,2),(816,2),(817,2),(818,2),(819,2),(820,2),(821,2),(822,2),(823,2),(824,2),(825,2),(826,2),(827,2),(828,2),(829,2),(830,2),(831,2),(832,2),(833,2),(834,2),(835,2),(836,2),(837,2),(838,2),(839,2),(840,2),(841,2),(842,2),(843,2),(844,2),(845,2),(846,2),(847,2),(848,2),(849,2),(850,2),(851,2),(852,2),(853,2),(854,2),(855,2),(856,2),(857,2),(858,2),(859,2),(860,2),(861,2),(862,2),(863,2),(864,2),(865,2),(866,2),(867,2),(868,2),(869,2),(870,2),(871,2),(872,2),(873,2),(874,2),(875,2),(876,2),(877,2),(878,2),(879,2),(880,2),(881,2),(882,2),(883,2),(884,2),(885,2),(886,2),(887,2),(888,2),(889,2),(890,2),(891,2),(892,2),(893,2),(894,2),(895,2),(896,2),(897,2),(898,2),(899,2),(900,2),(901,2),(902,2),(903,2),(904,2),(905,2),(906,2),(907,2),(908,2),(909,2),(910,2),(911,2),(912,2),(913,2),(914,2),(915,2),(916,2),(917,2),(918,2),(919,2),(920,2),(921,2),(922,2),(923,2),(924,2),(925,2),(926,2),(927,2),(928,2),(929,2),(930,2),(931,2),(932,2),(933,2),(934,2),(935,2),(936,2),(937,2),(938,2),(939,2),(940,2),(941,2),(942,2),(943,2),(944,2),(945,2),(946,2),(947,2),(948,2),(949,2),(950,2),(951,2),(952,2),(953,2),(954,2),(955,2),(956,2),(957,2),(958,2),(959,2),(960,2),(961,2),(962,2),(963,2),(964,2),(965,2),(966,2),(967,2),(968,2),(969,2),(970,2),(971,2),(972,2),(973,2),(974,2),(975,2),(976,2),(977,2),(978,2),(979,2),(980,2),(981,2),(982,2),(983,2),(984,2),(985,2),(986,2),(987,2),(988,2),(989,2),(990,2),(991,2),(992,2),(993,2),(994,2),(995,2),(996,2),(997,2),(998,2),(999,2),(1000,2),(1001,2),(1002,2),(1003,2),(1004,2),(1005,2),(1006,2),(1007,2),(1008,2),(1009,2),(1010,2),(1011,2),(1012,2),(1013,2),(1014,2),(1015,2),(1016,2),(1017,2),(1018,2),(1019,2),(1020,2),(1021,2),(1022,2),(1023,2),(1024,2),(1025,2),(1026,2),(1027,2),(1028,2),(1029,2),(1030,2),(1031,2),(1032,2),(1033,2),(1034,2),(1035,2),(1036,2),(1037,2),(1038,2),(1039,2),(1040,2),(1041,2),(1042,2),(1043,2),(1044,2),(1045,2),(1046,2),(1047,2),(1048,2),(1049,2),(1050,2),(1051,2),(1052,2),(1053,2),(1054,2),(1055,2),(1056,2),(1057,2),(1058,2),(1059,2),(1060,2),(1061,2),(1062,2),(1063,2),(1064,2),(1065,2),(1066,2),(1067,2),(1068,2),(1069,2),(1070,2),(1071,2),(1072,2),(1073,2),(1074,2),(1075,2),(1076,2),(1077,2),(1078,2),(1079,2),(1080,2),(1081,2),(1082,2),(1083,2),(1084,2),(1085,2),(1086,2),(1087,2),(1088,2),(1089,2),(1090,2),(1091,2),(1092,2),(1093,2),(1094,2),(1095,2),(1096,2),(1097,2),(1098,2),(1099,2),(1100,2),(1101,2),(1102,2),(1103,2),(1104,2),(1105,2),(1106,2),(1107,2),(1108,2),(1109,2),(1110,2),(1111,2),(1112,2),(1113,2),(1114,2),(1115,2),(1116,2),(1117,2),(1118,2),(1119,2),(1120,2),(1121,2),(1122,2),(1123,2),(1124,2),(1125,2),(1126,2),(1127,2),(1128,2),(1129,2),(1130,2),(1131,2),(1132,2),(1133,2),(1134,2),(1135,2),(1136,2),(1137,2),(1138,2),(1139,2),(1140,2),(1141,2),(1142,2),(1143,2),(1144,2),(1145,2),(1146,2),(1147,2),(1148,2),(1149,2),(1150,2),(1151,2),(1152,2),(1153,2),(1154,2),(1155,2),(1156,2),(1157,2),(1158,2),(1159,2),(1160,2),(1161,2),(1162,2),(1163,2),(1164,2),(1165,2),(1166,2),(1167,2),(1168,2),(1169,2),(1170,2),(1171,2),(1172,2),(1173,2),(1174,2),(1175,2),(1176,2),(1177,2),(1178,2),(1179,2),(1180,2),(1181,2),(1182,2),(1183,2),(1184,2),(1185,2),(1186,2),(1187,2),(1188,2),(1189,2),(1190,2),(1191,2),(1192,2),(1193,2),(1194,2),(1195,2),(1196,2),(1197,2),(1198,2),(1199,2),(1200,2),(1201,2),(1202,2),(1203,2),(1204,2),(1205,2),(1206,2),(1207,2),(1208,2),(1209,2),(1210,2),(1211,2),(1212,2),(1213,2),(1214,2),(1215,2),(1216,2),(1217,2),(1218,2),(1219,2),(1220,2),(1221,2),(1222,2),(1223,2),(1224,2),(1225,2),(1226,2),(1227,2),(1228,2),(1229,2),(1230,2),(1231,2),(1232,2),(1233,2),(1234,2),(1235,2),(1236,2),(1237,2),(1238,2),(1239,2),(1240,2),(1241,2),(1242,2),(1243,2),(1244,2),(1245,2),(1246,2),(1247,2),(1248,2),(1249,2),(1250,2),(1251,2),(1252,2),(1253,2),(1254,2),(1255,2),(1256,2),(1257,2),(1258,2),(1259,2),(1260,2),(1261,2),(1262,2),(1263,2),(1264,2),(1265,2),(1266,2),(1267,2),(1268,2),(1269,2),(1270,2),(1271,2),(1272,2),(1273,2),(1274,2),(1275,2),(1276,2),(1277,2),(1278,2),(1279,2),(1280,2),(1281,2),(1282,2),(1283,2),(1284,2),(1285,2),(1286,2),(1287,2),(1288,2),(1289,2),(1290,2),(1291,2),(1292,2),(1293,2),(1294,2),(1295,2),(1296,2),(1297,2),(1298,2),(1299,2),(1300,2),(1301,2),(1302,2),(1303,2),(1304,2),(1305,2),(1306,2),(1307,2),(1308,2),(1309,2),(1310,2),(1311,2),(1312,2),(1313,2),(1314,2),(1315,2),(1316,2),(1317,2),(1318,2),(1319,2),(1320,2),(1321,2),(1322,2),(1323,2),(1324,2),(1325,2),(1326,2),(1327,2),(1328,2),(1329,2),(1330,2),(1331,2),(1332,2),(1333,2),(1334,2),(1335,2),(1336,2),(1337,2),(1338,2),(1339,2),(1340,2),(1341,2),(1342,2),(1343,2),(1344,2),(1345,2),(1346,2),(1347,2),(1348,2),(1349,2),(1350,2),(1351,2),(1352,2),(1353,2),(1354,2),(1355,2),(1356,2),(1357,2),(1358,2),(1359,2),(1360,2),(1361,2),(1362,2),(1363,2),(1364,2),(1365,2),(1366,2),(1367,2),(1368,2),(1369,2),(1370,2),(1371,2),(1372,2),(1373,2),(1374,2),(1375,2),(1376,2),(1377,2),(1378,2),(1379,2),(1380,2),(1381,2),(1382,2),(1383,2),(1384,2),(1385,2),(1386,2),(1387,2),(1388,2),(1389,2),(1390,2),(1391,2),(1392,2),(1393,2),(1394,2),(1395,2),(1396,2),(1397,2),(1398,2),(1399,2),(1400,2),(1401,2),(1402,2),(1403,2),(1404,2),(1405,2),(1406,2),(1407,2),(1408,2),(1409,2),(1410,2),(1411,2),(1412,2),(1413,2),(1414,2),(1415,2),(1416,2),(1417,2),(1418,2),(1419,2),(1420,2),(1421,2),(1422,2),(1423,2),(1424,2),(1425,2),(1426,2),(1427,2),(1428,2),(1429,2),(1430,2),(1431,2),(1432,2),(1433,2),(1434,2),(1435,2),(1436,2),(1437,2),(1438,2),(1439,2),(1440,2),(1441,2),(1442,2),(1443,2),(1444,2),(1445,2),(1446,2),(1447,2),(1448,2),(1449,2),(1450,2),(1451,2),(1452,2),(1453,2),(1454,2),(1455,2),(1456,2),(1457,2),(1458,2),(1459,2),(1460,2),(1461,2),(1462,2),(1463,2),(1464,2),(1465,2),(1466,2),(1467,2),(1468,2),(1469,2),(1470,2),(1471,2),(1472,2),(1473,2),(1474,2),(1475,2),(1476,2),(1477,2),(1478,2),(1479,2),(1480,2),(1481,2),(1482,2),(1483,2),(1484,2),(1485,2),(1486,2),(1487,2),(1488,2),(1489,2),(1490,2),(1491,2),(1492,2),(1493,2),(1494,2),(1495,2),(1496,2),(1497,2),(1498,2),(1499,2),(1500,2),(1501,2),(1502,2),(1503,2),(1504,2),(1505,2),(1506,2),(1507,2),(1508,2),(1509,2),(1510,2),(1511,2),(1512,2),(1513,2),(1514,2),(1515,2),(1516,2),(1517,2),(1518,2),(1519,2),(1520,2),(1521,2),(1522,2),(1523,2),(1524,2),(1525,2),(1526,2),(1527,2),(1528,2),(1529,2),(1530,2),(1531,2),(1532,2),(1533,2),(1534,2),(1535,2),(1536,2),(1537,2),(1538,2),(1539,2),(1540,2),(1541,2),(1542,2),(1543,2),(1544,2),(1545,2),(1546,2),(1547,2),(1548,2),(1549,2),(1550,2),(1551,2),(1552,2),(1553,2),(1554,2),(1555,2),(1556,2),(1557,2),(1558,2),(1559,2),(1560,2),(1561,2),(1562,2),(1563,2),(1564,2),(1565,2),(1566,2),(1567,2),(1568,2),(1569,2),(1570,2),(1571,2),(1572,2),(1573,2),(1574,2),(1575,2),(1576,2),(1577,2),(1578,2),(1579,2),(1580,2),(1581,2),(1582,2),(1583,2),(1584,2),(1585,2),(1586,2),(1587,2),(1588,2),(1589,2),(1590,2),(1591,2),(1592,2),(1593,2),(1594,2),(1595,2),(1596,2),(1597,2),(1598,2),(1599,2),(1600,2),(1601,2),(1602,2),(1603,2),(1604,2),(1605,2),(1606,2),(1607,2),(1608,2),(1609,2),(1610,2),(1611,2),(1612,2),(1613,2),(1614,2),(1615,2),(1616,2),(1617,2),(1618,2),(1619,2),(1620,2),(1621,2),(1622,2),(1623,2),(1624,2),(1625,2),(1626,2),(1627,2),(1628,2),(1629,2),(1630,2),(1631,2),(1632,2),(1633,2),(1634,2),(1635,2),(1636,2),(1637,2),(1638,2),(1639,2),(1640,2),(1641,2),(1642,2),(1643,2),(1644,2),(1645,2),(1646,2),(1647,2),(1648,2),(1649,2),(1650,2),(1651,2),(1652,2),(1653,2),(1654,2),(1655,2),(1656,2),(1657,2),(1658,2),(1659,2),(1660,2),(1661,2),(1662,2),(1663,2),(1664,2),(1665,2),(1666,2),(1667,2),(1668,2),(1669,2),(1670,2),(1671,2),(1672,2),(1673,2),(1674,2),(1675,2),(1676,2),(1677,2),(1678,2),(1679,2),(1680,2),(1681,2),(1682,2),(1683,2),(1684,2),(1685,2),(1686,2),(1687,2),(1688,2),(1689,2),(1690,2),(1691,2),(1692,2),(1693,2),(1694,2),(1695,2),(1696,2),(1697,2),(1698,2),(1699,2),(1700,2),(1701,2),(1702,2),(1703,2),(1704,2),(1705,2),(1706,2),(1707,2),(1708,2),(1709,2),(1710,2),(1711,2),(1712,2),(1713,2),(1714,2),(1715,2),(1716,2),(1717,2),(1718,2),(1719,2),(1720,2),(1721,2),(1722,2),(1723,2),(1724,2),(1725,2),(1726,2),(1727,2),(1728,2),(1729,2),(1730,2),(1731,2),(1732,2),(1733,2),(1734,2),(1735,2),(1736,2),(1737,2),(1738,2),(1739,2),(1740,2),(1741,2),(1742,2),(1743,2),(1744,2),(1745,2),(1746,2),(1747,2),(1748,2),(1749,2),(1750,2),(1751,2),(1752,2),(1753,2),(1754,2),(1755,2),(1756,2),(1757,2),(1758,2),(1759,2),(1760,2),(1761,2),(1762,2),(1763,2),(1764,2),(1765,2),(1766,2),(1767,2),(1768,2),(1769,2),(1770,2),(1771,2),(1772,2),(1773,2),(1774,2),(1775,2),(1776,2),(1777,2),(1778,2),(1779,2),(1780,2),(1781,2),(1782,2),(1783,2),(1784,2),(1785,2),(1786,2),(1787,2),(1788,2),(1789,2),(1790,2),(1791,2),(1792,2),(1793,2),(1794,2),(1795,2),(1796,2),(1797,2),(1798,2),(1799,2),(1800,2),(1801,2),(1802,2),(1803,2),(1804,2),(1805,2),(1806,2),(1807,2),(1808,2),(1809,2),(1810,2),(1811,2),(1812,2),(1813,2),(1814,2),(1815,2),(1816,2),(1817,2),(1818,2),(1819,2),(1820,2),(1821,2),(1822,2),(1823,2),(1824,2),(1825,2),(1826,2),(1827,2),(1828,2),(1829,2),(1830,2),(1831,2),(1832,2),(1833,2),(1834,2),(1835,2),(1836,2),(1837,2),(1838,2),(1839,2),(1840,2),(1841,2),(1842,2),(1843,2),(1844,2),(1845,2),(1846,2),(1847,2),(1848,2),(1849,2),(1850,2),(1851,2),(1852,2),(1853,2),(1854,2),(1855,2),(1856,2),(1857,2),(1858,2),(1859,2),(1860,2),(1861,2),(1862,2),(1863,2),(1864,2),(1865,2),(1866,2),(1867,2),(1868,2),(1869,2),(1870,2),(1871,2),(1872,2),(1873,2),(1874,2),(1875,2),(1876,2),(1877,2),(1878,2),(1879,2),(1880,2),(1881,2),(1882,2),(1883,2),(1884,2),(1885,2),(1886,2),(1887,2),(1888,2),(1889,2),(1890,2),(1891,2),(1892,2),(1893,2),(1894,2),(1895,2),(1896,2),(1897,2),(1898,2),(1899,2),(1900,2),(1901,2),(1902,2),(1903,2),(1904,2),(1905,2),(1906,2),(1907,2),(1908,2),(1909,2),(1910,2),(1911,2),(1912,2),(1913,2),(1914,2),(1915,2),(1916,2),(1917,2),(1918,2),(1919,2),(1920,2),(1921,2),(1922,2),(1923,2),(1924,2),(1925,2),(1926,2),(1927,2),(1928,2),(1929,2),(1930,2),(1931,2),(1932,2),(1933,2),(1934,2),(1935,2),(1936,2),(1937,2),(1938,2),(1939,2),(1940,2),(1941,2),(1942,2),(1943,2),(1944,2),(1945,2),(1946,2),(1947,2),(1948,2),(1949,2),(1950,2),(1951,2),(1952,2),(1953,2),(1954,2),(1955,2),(1956,2),(1957,2),(1958,2),(1959,2),(1960,2),(1961,2),(1962,2),(1963,2),(1964,2),(1965,2),(1966,2),(1967,2),(1968,2),(1969,2),(1970,2),(1971,2),(1972,2),(1973,2),(1974,2),(1,3),(2,3),(3,3),(4,3),(5,3),(6,3),(7,3),(8,3),(9,3),(10,3),(11,3),(12,3),(13,3),(14,3),(15,3),(16,3),(17,3),(18,3),(19,3),(20,3),(21,3),(22,3),(23,3),(24,3),(25,3),(26,3),(27,3),(28,3),(29,3),(30,3),(31,3),(32,3),(33,3),(34,3),(35,3),(36,3),(37,3),(38,3),(39,3),(40,3),(41,3),(42,3),(43,3),(44,3),(45,3),(46,3),(47,3),(48,3),(49,3),(50,3),(51,3),(52,3),(53,3),(54,3),(55,3),(56,3),(57,3),(58,3),(59,3),(60,3),(61,3),(62,3),(63,3),(64,3),(65,3),(66,3),(67,3),(68,3),(69,3),(70,3),(71,3),(72,3),(73,3),(74,3),(75,3),(76,3),(77,3),(78,3),(79,3),(80,3),(81,3),(82,3),(83,3),(84,3),(85,3),(86,3),(87,3),(88,3),(89,3),(90,3),(91,3),(92,3),(93,3),(94,3),(95,3),(96,3),(97,3),(98,3),(99,3),(100,3),(101,3),(102,3),(103,3),(104,3),(105,3),(106,3),(107,3),(108,3),(109,3),(110,3),(111,3),(112,3),(113,3),(114,3),(115,3),(116,3),(117,3),(118,3),(119,3),(120,3),(121,3),(122,3),(123,3),(124,3),(125,3),(126,3),(127,3),(128,3),(129,3),(130,3),(131,3),(132,3),(133,3),(134,3),(135,3),(136,3),(137,3),(138,3),(139,3),(140,3),(141,3),(142,3),(143,3),(144,3),(145,3),(146,3),(147,3),(148,3),(149,3),(150,3),(151,3),(152,3),(153,3),(154,3),(155,3),(156,3),(157,3),(158,3),(159,3),(160,3),(161,3),(162,3),(163,3),(164,3),(165,3),(166,3),(167,3),(168,3),(169,3),(170,3),(171,3),(172,3),(173,3),(174,3),(175,3),(176,3),(177,3),(178,3),(179,3),(180,3),(181,3),(182,3),(183,3),(184,3),(185,3),(186,3),(187,3),(188,3),(189,3),(190,3),(191,3),(192,3),(193,3),(194,3),(195,3),(196,3),(197,3),(198,3),(199,3),(200,3),(201,3),(202,3),(203,3),(204,3),(205,3),(206,3),(207,3),(208,3),(209,3),(210,3),(211,3),(212,3),(213,3),(214,3),(215,3),(216,3),(217,3),(218,3),(219,3),(220,3),(221,3),(222,3),(223,3),(224,3),(225,3),(226,3),(227,3),(228,3),(229,3),(230,3),(231,3),(232,3),(233,3),(234,3),(235,3),(236,3),(237,3),(238,3),(239,3),(240,3),(241,3),(242,3),(243,3),(244,3),(245,3),(246,3),(247,3),(248,3),(249,3),(250,3),(251,3),(252,3),(253,3),(254,3),(255,3),(256,3),(257,3),(258,3),(259,3),(260,3),(261,3),(262,3),(263,3),(264,3),(265,3),(266,3),(267,3),(268,3),(269,3),(270,3),(271,3),(272,3),(273,3),(274,3),(275,3),(276,3),(277,3),(278,3),(279,3),(280,3),(281,3),(282,3),(283,3),(284,3),(285,3),(286,3),(287,3),(288,3),(289,3),(290,3),(291,3),(292,3),(293,3),(294,3),(295,3),(296,3),(297,3),(298,3),(299,3),(300,3),(301,3),(302,3),(303,3),(304,3),(305,3),(306,3),(307,3),(308,3),(309,3),(310,3),(311,3),(312,3),(313,3),(314,3),(315,3),(316,3),(317,3),(318,3),(319,3),(320,3),(321,3),(322,3),(323,3),(324,3),(325,3),(326,3),(327,3),(328,3),(329,3),(330,3),(331,3),(332,3),(333,3),(334,3),(335,3),(336,3),(337,3),(338,3),(339,3),(340,3),(341,3),(342,3),(343,3),(344,3),(345,3),(346,3),(347,3),(348,3),(349,3),(350,3),(351,3),(352,3),(353,3),(354,3),(355,3),(356,3),(357,3),(358,3),(359,3),(360,3),(361,3),(362,3),(363,3),(364,3),(365,3),(366,3),(367,3),(368,3),(369,3),(370,3),(371,3),(372,3),(373,3),(374,3),(375,3),(376,3),(377,3),(378,3),(379,3),(380,3),(381,3),(382,3),(383,3),(384,3),(385,3),(386,3),(387,3),(388,3),(389,3),(390,3),(391,3),(392,3),(393,3),(394,3),(395,3),(396,3),(397,3),(398,3),(399,3),(400,3),(401,3),(402,3),(403,3),(404,3),(405,3),(406,3),(407,3),(408,3),(409,3),(410,3),(411,3),(412,3),(413,3),(414,3),(415,3),(416,3),(417,3),(418,3),(419,3),(420,3),(421,3),(422,3),(423,3),(424,3),(425,3),(426,3),(427,3),(428,3),(429,3),(430,3),(431,3),(432,3),(433,3),(434,3),(435,3),(436,3),(437,3),(438,3),(439,3),(440,3),(441,3),(442,3),(443,3),(444,3),(445,3),(446,3),(447,3),(448,3),(449,3),(450,3),(451,3),(452,3),(453,3),(454,3),(455,3),(456,3),(457,3),(458,3),(459,3),(460,3),(461,3),(462,3),(463,3),(464,3),(465,3),(466,3),(467,3),(468,3),(469,3),(470,3),(471,3),(472,3),(473,3),(474,3),(475,3),(476,3),(477,3),(478,3),(479,3),(480,3),(481,3),(482,3),(483,3),(484,3),(485,3),(486,3),(487,3),(488,3),(489,3),(490,3),(491,3),(492,3),(493,3),(494,3),(495,3),(496,3),(497,3),(498,3),(499,3),(500,3),(501,3),(502,3),(503,3),(504,3),(505,3),(506,3),(507,3),(508,3),(509,3),(510,3),(511,3),(512,3),(513,3),(514,3),(515,3),(516,3),(517,3),(518,3),(519,3),(520,3),(521,3),(522,3),(523,3),(524,3),(525,3),(526,3),(527,3),(528,3),(529,3),(530,3),(531,3),(532,3),(533,3),(534,3),(535,3),(536,3),(537,3),(538,3),(539,3),(540,3),(541,3),(542,3),(543,3),(544,3),(545,3),(546,3),(547,3),(548,3),(549,3),(550,3),(551,3),(552,3),(553,3),(554,3),(555,3),(556,3),(557,3),(558,3),(559,3),(560,3),(561,3),(562,3),(563,3),(564,3),(565,3),(566,3),(567,3),(568,3),(569,3),(570,3),(571,3),(572,3),(573,3),(574,3),(575,3),(576,3),(577,3),(578,3),(579,3),(580,3),(581,3),(582,3),(583,3),(584,3),(585,3),(586,3),(587,3),(588,3),(589,3),(590,3),(591,3),(592,3),(593,3),(594,3),(595,3),(596,3),(597,3),(598,3),(599,3),(600,3),(601,3),(602,3),(603,3),(604,3),(605,3),(606,3),(607,3),(608,3),(609,3),(610,3),(611,3),(612,3),(613,3),(614,3),(615,3),(616,3),(617,3),(618,3),(619,3),(620,3),(621,3),(622,3),(623,3),(624,3),(625,3),(626,3),(627,3),(628,3),(629,3),(630,3),(631,3),(632,3),(633,3),(634,3),(635,3),(636,3),(637,3),(638,3),(639,3),(640,3),(641,3),(642,3),(643,3),(644,3),(645,3),(646,3),(647,3),(648,3),(649,3),(650,3),(651,3),(652,3),(653,3),(654,3),(655,3),(656,3),(657,3),(658,3),(659,3),(660,3),(661,3),(662,3),(663,3),(664,3),(665,3),(666,3),(667,3),(668,3),(669,3),(670,3),(671,3),(672,3),(673,3),(674,3),(675,3),(676,3),(677,3),(678,3),(679,3),(680,3),(681,3),(682,3),(683,3),(684,3),(685,3),(686,3),(687,3),(688,3),(689,3),(690,3),(691,3),(692,3),(693,3),(694,3),(695,3),(696,3),(697,3),(698,3),(699,3),(700,3),(701,3),(702,3),(703,3),(704,3),(705,3),(706,3),(707,3),(708,3),(709,3),(710,3),(711,3),(712,3),(713,3),(714,3),(715,3),(716,3),(717,3),(718,3),(719,3),(720,3),(721,3),(722,3),(723,3),(724,3),(725,3),(726,3),(727,3),(728,3),(729,3),(730,3),(731,3),(732,3),(733,3),(734,3),(735,3),(736,3),(737,3),(738,3),(739,3),(740,3),(741,3),(742,3),(743,3),(744,3),(745,3),(746,3),(747,3),(748,3),(749,3),(750,3),(751,3),(752,3),(753,3),(754,3),(755,3),(756,3),(757,3),(758,3),(759,3),(760,3),(761,3),(762,3),(763,3),(764,3),(765,3),(766,3),(767,3),(768,3),(769,3),(770,3),(771,3),(772,3),(773,3),(774,3),(775,3),(776,3),(777,3),(778,3),(779,3),(780,3),(781,3),(782,3),(783,3),(784,3),(785,3),(786,3),(787,3),(788,3),(789,3),(790,3),(791,3),(792,3),(793,3),(794,3),(795,3),(796,3),(797,3),(798,3),(799,3),(800,3),(801,3),(802,3),(803,3),(804,3),(805,3),(806,3),(807,3),(808,3),(809,3),(810,3),(811,3),(812,3),(813,3),(814,3),(815,3),(816,3),(817,3),(818,3),(819,3),(820,3),(821,3),(822,3),(823,3),(824,3),(825,3),(826,3),(827,3),(828,3),(829,3),(830,3),(831,3),(832,3),(833,3),(834,3),(835,3),(836,3),(837,3),(838,3),(839,3),(840,3),(841,3),(842,3),(843,3),(844,3),(845,3),(846,3),(847,3),(848,3),(849,3),(850,3),(851,3),(852,3),(853,3),(854,3),(855,3),(856,3),(857,3),(858,3),(859,3),(860,3),(861,3),(862,3),(863,3),(864,3),(865,3),(866,3),(867,3),(868,3),(869,3),(870,3),(871,3),(872,3),(873,3),(874,3),(875,3),(876,3),(877,3),(878,3),(879,3),(880,3),(881,3),(882,3),(883,3),(884,3),(885,3),(886,3),(887,3),(888,3),(889,3),(890,3),(891,3),(892,3),(893,3),(894,3),(895,3),(896,3),(897,3),(898,3),(899,3),(900,3),(901,3),(902,3),(903,3),(904,3),(905,3),(906,3),(907,3),(908,3),(909,3),(910,3),(911,3),(912,3),(913,3),(914,3),(915,3),(916,3),(917,3),(918,3),(919,3),(920,3),(921,3),(922,3),(923,3),(924,3),(925,3),(926,3),(927,3),(928,3),(929,3),(930,3),(931,3),(932,3),(933,3),(934,3),(935,3),(936,3),(937,3),(938,3),(939,3),(940,3),(941,3),(942,3),(943,3),(944,3),(945,3),(946,3),(947,3),(948,3),(949,3),(950,3),(951,3),(952,3),(953,3),(954,3),(955,3),(956,3),(957,3),(958,3),(959,3),(960,3),(961,3),(962,3),(963,3),(964,3),(965,3),(966,3),(967,3),(968,3),(969,3),(970,3),(971,3),(972,3),(973,3),(974,3),(975,3),(976,3),(977,3),(978,3),(979,3),(980,3),(981,3),(982,3),(983,3),(984,3),(985,3),(986,3),(987,3),(988,3),(989,3),(990,3),(991,3),(992,3),(993,3),(994,3),(995,3),(996,3),(997,3),(998,3),(999,3),(1000,3),(1001,3),(1002,3),(1003,3),(1004,3),(1005,3),(1006,3),(1007,3),(1008,3),(1009,3),(1010,3),(1011,3),(1012,3),(1013,3),(1014,3),(1015,3),(1016,3),(1017,3),(1018,3),(1019,3),(1020,3),(1021,3),(1022,3),(1023,3),(1024,3),(1025,3),(1026,3),(1027,3),(1028,3),(1029,3),(1030,3),(1031,3),(1032,3),(1033,3),(1034,3),(1035,3),(1036,3),(1037,3),(1038,3),(1039,3),(1040,3),(1041,3),(1042,3),(1043,3),(1044,3),(1045,3),(1046,3),(1047,3),(1048,3),(1049,3),(1050,3),(1051,3),(1052,3),(1053,3),(1054,3),(1055,3),(1056,3),(1057,3),(1058,3),(1059,3),(1060,3),(1061,3),(1062,3),(1063,3),(1064,3),(1065,3),(1066,3),(1067,3),(1068,3),(1069,3),(1070,3),(1071,3),(1072,3),(1073,3),(1074,3),(1075,3),(1076,3),(1077,3),(1078,3),(1079,3),(1080,3),(1081,3),(1082,3),(1083,3),(1084,3),(1085,3),(1086,3),(1087,3),(1088,3),(1089,3),(1090,3),(1091,3),(1092,3),(1093,3),(1094,3),(1095,3),(1096,3),(1097,3),(1098,3),(1099,3),(1100,3),(1101,3),(1102,3),(1103,3),(1104,3),(1105,3),(1106,3),(1107,3),(1108,3),(1109,3),(1110,3),(1111,3),(1112,3),(1113,3),(1114,3),(1115,3),(1116,3),(1117,3),(1118,3),(1119,3),(1120,3),(1121,3),(1122,3),(1123,3),(1124,3),(1125,3),(1126,3),(1127,3),(1128,3),(1129,3),(1130,3),(1131,3),(1132,3),(1133,3),(1134,3),(1135,3),(1136,3),(1137,3),(1138,3),(1139,3),(1140,3),(1141,3),(1142,3),(1143,3),(1144,3),(1145,3),(1146,3),(1147,3),(1148,3),(1149,3),(1150,3),(1151,3),(1152,3),(1153,3),(1154,3),(1155,3),(1156,3),(1157,3),(1158,3),(1159,3),(1160,3),(1161,3),(1162,3),(1163,3),(1164,3),(1165,3),(1166,3),(1167,3),(1168,3),(1169,3),(1170,3),(1171,3),(1172,3),(1173,3),(1174,3),(1175,3),(1176,3),(1177,3),(1178,3),(1179,3),(1180,3),(1181,3),(1182,3),(1183,3),(1184,3),(1185,3),(1186,3),(1187,3),(1188,3),(1189,3),(1190,3),(1191,3),(1192,3),(1193,3),(1194,3),(1195,3),(1196,3),(1197,3),(1198,3),(1199,3),(1200,3),(1201,3),(1202,3),(1203,3),(1204,3),(1205,3),(1206,3),(1207,3),(1208,3),(1209,3),(1210,3),(1211,3),(1212,3),(1213,3),(1214,3),(1215,3),(1216,3),(1217,3),(1218,3),(1219,3),(1220,3),(1221,3),(1222,3),(1223,3),(1224,3),(1225,3),(1226,3),(1227,3),(1228,3),(1229,3),(1230,3),(1231,3),(1232,3),(1233,3),(1234,3),(1235,3),(1236,3),(1237,3),(1238,3),(1239,3),(1240,3),(1241,3),(1242,3),(1243,3),(1244,3),(1245,3),(1246,3),(1247,3),(1248,3),(1249,3),(1250,3),(1251,3),(1252,3),(1253,3),(1254,3),(1255,3),(1256,3),(1257,3),(1258,3),(1259,3),(1260,3),(1261,3),(1262,3),(1263,3),(1264,3),(1265,3),(1266,3),(1267,3),(1268,3),(1269,3),(1270,3),(1271,3),(1272,3),(1273,3),(1274,3),(1275,3),(1276,3),(1277,3),(1278,3),(1279,3),(1280,3),(1281,3),(1282,3),(1283,3),(1284,3),(1285,3),(1286,3),(1287,3),(1288,3),(1289,3),(1290,3),(1291,3),(1292,3),(1293,3),(1294,3),(1295,3),(1296,3),(1297,3),(1298,3),(1299,3),(1300,3),(1301,3),(1302,3),(1303,3),(1304,3),(1305,3),(1306,3),(1307,3),(1308,3),(1309,3),(1310,3),(1311,3),(1312,3),(1313,3),(1314,3),(1315,3),(1316,3),(1317,3),(1318,3),(1319,3),(1320,3),(1321,3),(1322,3),(1323,3),(1324,3),(1325,3),(1326,3),(1327,3),(1328,3),(1329,3),(1330,3),(1331,3),(1332,3),(1333,3),(1334,3),(1335,3),(1336,3),(1337,3),(1338,3),(1339,3),(1340,3),(1341,3),(1342,3),(1343,3),(1344,3),(1345,3),(1346,3),(1347,3),(1348,3),(1349,3),(1350,3),(1351,3),(1352,3),(1353,3),(1354,3),(1355,3),(1356,3),(1357,3),(1358,3),(1359,3),(1360,3),(1361,3),(1362,3),(1363,3),(1364,3),(1365,3),(1366,3),(1367,3),(1368,3),(1369,3),(1370,3),(1371,3),(1372,3),(1373,3),(1374,3),(1375,3),(1376,3),(1377,3),(1378,3),(1379,3),(1380,3),(1381,3),(1382,3),(1383,3),(1384,3),(1385,3),(1386,3),(1387,3),(1388,3),(1389,3),(1390,3),(1391,3),(1392,3),(1393,3),(1394,3),(1395,3),(1396,3),(1397,3),(1398,3),(1399,3),(1400,3),(1401,3),(1402,3),(1403,3),(1404,3),(1405,3),(1406,3),(1407,3),(1408,3),(1409,3),(1410,3),(1411,3),(1412,3),(1413,3),(1414,3),(1415,3),(1416,3),(1417,3),(1418,3),(1419,3),(1420,3),(1421,3),(1422,3),(1423,3),(1424,3),(1425,3),(1426,3),(1427,3),(1428,3),(1429,3),(1430,3),(1431,3),(1432,3),(1433,3),(1434,3),(1435,3),(1436,3),(1437,3),(1438,3),(1439,3),(1440,3),(1441,3),(1442,3),(1443,3),(1444,3),(1445,3),(1446,3),(1447,3),(1448,3),(1449,3),(1450,3),(1451,3),(1452,3),(1453,3),(1454,3),(1455,3),(1456,3),(1457,3),(1458,3),(1459,3),(1460,3),(1461,3),(1462,3),(1463,3),(1464,3),(1465,3),(1466,3),(1467,3),(1468,3),(1469,3),(1470,3),(1471,3),(1472,3),(1473,3),(1474,3),(1475,3),(1476,3),(1477,3),(1478,3),(1479,3),(1480,3),(1481,3),(1482,3),(1483,3),(1484,3),(1485,3),(1486,3),(1487,3),(1488,3),(1489,3),(1490,3),(1491,3),(1492,3),(1493,3),(1494,3),(1495,3),(1496,3),(1497,3),(1498,3),(1499,3),(1500,3),(1501,3),(1502,3),(1503,3),(1504,3),(1505,3),(1506,3),(1507,3),(1508,3),(1509,3),(1510,3),(1511,3),(1512,3),(1513,3),(1514,3),(1515,3),(1516,3),(1517,3),(1518,3),(1519,3),(1520,3),(1521,3),(1522,3),(1523,3),(1524,3),(1525,3),(1526,3),(1527,3),(1528,3),(1529,3),(1530,3),(1531,3),(1532,3),(1533,3),(1534,3),(1535,3),(1536,3),(1537,3),(1538,3),(1539,3),(1540,3),(1541,3),(1542,3),(1543,3),(1544,3),(1545,3),(1546,3),(1547,3),(1548,3),(1549,3),(1550,3),(1551,3),(1552,3),(1553,3),(1554,3),(1555,3),(1556,3),(1557,3),(1558,3),(1559,3),(1560,3),(1561,3),(1562,3),(1563,3),(1564,3),(1565,3),(1566,3),(1567,3),(1568,3),(1569,3),(1570,3),(1571,3),(1572,3),(1573,3),(1574,3),(1575,3),(1576,3),(1577,3),(1578,3),(1579,3),(1580,3),(1581,3),(1582,3),(1583,3),(1584,3),(1585,3),(1586,3),(1587,3),(1588,3),(1589,3),(1590,3),(1591,3),(1592,3),(1593,3),(1594,3),(1595,3),(1596,3),(1597,3),(1598,3),(1599,3),(1600,3),(1601,3),(1602,3),(1603,3),(1604,3),(1605,3),(1606,3),(1607,3),(1608,3),(1609,3),(1610,3),(1611,3),(1612,3),(1613,3),(1614,3),(1615,3),(1616,3),(1617,3),(1618,3),(1619,3),(1620,3),(1621,3),(1622,3),(1623,3),(1624,3),(1625,3),(1626,3),(1627,3),(1628,3),(1629,3),(1630,3),(1631,3),(1632,3),(1633,3),(1634,3),(1635,3),(1636,3),(1637,3),(1638,3),(1639,3),(1640,3),(1641,3),(1642,3),(1643,3),(1644,3),(1645,3),(1646,3),(1647,3),(1648,3),(1649,3),(1650,3),(1651,3),(1652,3),(1653,3),(1654,3),(1655,3),(1656,3),(1657,3),(1658,3),(1659,3),(1660,3),(1661,3),(1662,3),(1663,3),(1664,3),(1665,3),(1666,3),(1667,3),(1668,3),(1669,3),(1670,3),(1671,3),(1672,3),(1673,3),(1674,3),(1675,3),(1676,3),(1677,3),(1678,3),(1679,3),(1680,3),(1681,3),(1682,3),(1683,3),(1684,3),(1685,3),(1686,3),(1687,3),(1688,3),(1689,3),(1690,3),(1691,3),(1692,3),(1693,3),(1694,3),(1695,3),(1696,3),(1697,3),(1698,3),(1699,3),(1700,3),(1701,3),(1702,3),(1703,3),(1704,3),(1705,3),(1706,3),(1707,3),(1708,3),(1709,3),(1710,3),(1711,3),(1712,3),(1713,3),(1714,3),(1715,3),(1716,3),(1717,3),(1718,3),(1719,3),(1720,3),(1721,3),(1722,3),(1723,3),(1724,3),(1725,3),(1726,3),(1727,3),(1728,3),(1729,3),(1730,3),(1731,3),(1732,3),(1733,3),(1734,3),(1735,3),(1736,3),(1737,3),(1738,3),(1739,3),(1740,3),(1741,3),(1742,3),(1743,3),(1744,3),(1745,3),(1746,3),(1747,3),(1748,3),(1749,3),(1750,3),(1751,3),(1752,3),(1753,3),(1754,3),(1755,3),(1756,3),(1757,3),(1758,3),(1759,3),(1760,3),(1761,3),(1762,3),(1763,3),(1764,3),(1765,3),(1766,3),(1767,3),(1768,3),(1769,3),(1770,3),(1771,3),(1772,3),(1773,3),(1774,3),(1775,3),(1776,3),(1777,3),(1778,3),(1779,3),(1780,3),(1781,3),(1782,3),(1783,3),(1784,3),(1785,3),(1786,3),(1787,3),(1788,3),(1789,3),(1790,3),(1791,3),(1792,3),(1793,3),(1794,3),(1795,3),(1796,3),(1797,3),(1798,3),(1799,3),(1800,3),(1801,3),(1802,3),(1803,3),(1804,3),(1805,3),(1806,3),(1807,3),(1808,3),(1809,3),(1810,3),(1811,3),(1812,3),(1813,3),(1814,3),(1815,3),(1816,3),(1817,3),(1818,3),(1819,3),(1820,3),(1821,3),(1822,3),(1823,3),(1824,3),(1825,3),(1826,3),(1827,3),(1828,3),(1829,3),(1830,3),(1831,3),(1832,3),(1833,3),(1834,3),(1835,3),(1836,3),(1837,3),(1838,3),(1839,3),(1840,3),(1841,3),(1842,3),(1843,3),(1844,3),(1845,3),(1846,3),(1847,3),(1848,3),(1849,3),(1850,3),(1851,3),(1852,3),(1853,3),(1854,3),(1855,3),(1856,3),(1857,3),(1858,3),(1859,3),(1860,3),(1861,3),(1862,3),(1863,3),(1864,3),(1865,3),(1866,3),(1867,3),(1868,3),(1869,3),(1870,3),(1871,3),(1872,3),(1873,3),(1874,3),(1875,3),(1876,3),(1877,3),(1878,3),(1879,3),(1880,3),(1881,3),(1882,3),(1883,3),(1884,3),(1885,3),(1886,3),(1887,3),(1888,3),(1889,3),(1890,3),(1891,3),(1892,3),(1893,3),(1894,3),(1895,3),(1896,3),(1897,3),(1898,3),(1899,3),(1900,3),(1901,3),(1902,3),(1903,3),(1904,3),(1905,3),(1906,3),(1907,3),(1908,3),(1909,3),(1910,3),(1911,3),(1912,3),(1913,3),(1914,3),(1915,3),(1916,3),(1917,3),(1918,3),(1919,3),(1920,3),(1921,3),(1922,3),(1923,3),(1924,3),(1925,3),(1926,3),(1927,3),(1928,3),(1929,3),(1930,3),(1931,3),(1932,3),(1933,3),(1934,3),(1935,3),(1936,3),(1937,3),(1938,3),(1939,3),(1940,3),(1941,3),(1942,3),(1943,3),(1944,3),(1945,3),(1946,3),(1947,3),(1948,3),(1949,3),(1950,3),(1951,3),(1952,3),(1953,3),(1954,3),(1955,3),(1956,3),(1957,3),(1958,3),(1959,3),(1960,3),(1961,3),(1962,3),(1963,3),(1964,3),(1965,3),(1966,3),(1967,3),(1968,3),(1969,3),(1970,3),(1971,3),(1972,3),(1973,3),(1974,3),(1,4),(2,4),(3,4),(4,4),(5,4),(6,4),(7,4),(8,4),(9,4),(10,4),(11,4),(12,4),(13,4),(14,4),(15,4),(16,4),(17,4),(18,4),(19,4),(20,4),(21,4),(22,4),(23,4),(24,4),(25,4),(26,4),(27,4),(28,4),(29,4),(30,4),(31,4),(32,4),(33,4),(34,4),(35,4),(36,4),(37,4),(38,4),(39,4),(40,4),(41,4),(42,4),(43,4),(44,4),(45,4),(46,4),(47,4),(48,4),(49,4),(50,4),(51,4),(52,4),(53,4),(54,4),(55,4),(56,4),(57,4),(58,4),(59,4),(60,4),(61,4),(62,4),(63,4),(64,4),(65,4),(66,4),(67,4),(68,4),(69,4),(70,4),(71,4),(72,4),(73,4),(74,4),(75,4),(76,4),(77,4),(78,4),(79,4),(80,4),(81,4),(82,4),(83,4),(84,4),(85,4),(86,4),(87,4),(88,4),(89,4),(90,4),(91,4),(92,4),(93,4),(94,4),(95,4),(96,4),(97,4),(98,4),(99,4),(100,4),(101,4),(102,4),(103,4),(104,4),(105,4),(106,4),(107,4),(108,4),(109,4),(110,4),(111,4),(112,4),(113,4),(114,4),(115,4),(116,4),(117,4),(118,4),(119,4),(120,4),(121,4),(122,4),(123,4),(124,4),(125,4),(126,4),(127,4),(128,4),(129,4),(130,4),(131,4),(132,4),(133,4),(134,4),(135,4),(136,4),(137,4),(138,4),(139,4),(140,4),(141,4),(142,4),(143,4),(144,4),(145,4),(146,4),(147,4),(148,4),(149,4),(150,4),(151,4),(152,4),(153,4),(154,4),(155,4),(156,4),(157,4),(158,4),(159,4),(160,4),(161,4),(162,4),(163,4),(164,4),(165,4),(166,4),(167,4),(168,4),(169,4),(170,4),(171,4),(172,4),(173,4),(174,4),(175,4),(176,4),(177,4),(178,4),(179,4),(180,4),(181,4),(182,4),(183,4),(184,4),(185,4),(186,4),(187,4),(188,4),(189,4),(190,4),(191,4),(192,4),(193,4),(194,4),(195,4),(196,4),(197,4),(198,4),(199,4),(200,4),(201,4),(202,4),(203,4),(204,4),(205,4),(206,4),(207,4),(208,4),(209,4),(210,4),(211,4),(212,4),(213,4),(214,4),(215,4),(216,4),(217,4),(218,4),(219,4),(220,4),(221,4),(222,4),(223,4),(224,4),(225,4),(226,4),(227,4),(228,4),(229,4),(230,4),(231,4),(232,4),(233,4),(234,4),(235,4),(236,4),(237,4),(238,4),(239,4),(240,4),(241,4),(242,4),(243,4),(244,4),(245,4),(246,4),(247,4),(248,4),(249,4),(250,4),(251,4),(252,4),(253,4),(254,4),(255,4),(256,4),(257,4),(258,4),(259,4),(260,4),(261,4),(262,4),(263,4),(264,4),(265,4),(266,4),(267,4),(268,4),(269,4),(270,4),(271,4),(272,4),(273,4),(274,4),(275,4),(276,4),(277,4),(278,4),(279,4),(280,4),(281,4),(282,4),(283,4),(284,4),(285,4),(286,4),(287,4),(288,4),(289,4),(290,4),(291,4),(292,4),(293,4),(294,4),(295,4),(296,4),(297,4),(298,4),(299,4),(300,4),(301,4),(302,4),(303,4),(304,4),(305,4),(306,4),(307,4),(308,4),(309,4),(310,4),(311,4),(312,4),(313,4),(314,4),(315,4),(316,4),(317,4),(318,4),(319,4),(320,4),(321,4),(322,4),(323,4),(324,4),(325,4),(326,4),(327,4),(328,4),(329,4),(330,4),(331,4),(332,4),(333,4),(334,4),(335,4),(336,4),(337,4),(338,4),(339,4),(340,4),(341,4),(342,4),(343,4),(344,4),(345,4),(346,4),(347,4),(348,4),(349,4),(350,4),(351,4),(352,4),(353,4),(354,4),(355,4),(356,4),(357,4),(358,4),(359,4),(360,4),(361,4),(362,4),(363,4),(364,4),(365,4),(366,4),(367,4),(368,4),(369,4),(370,4),(371,4),(372,4),(373,4),(374,4),(375,4),(376,4),(377,4),(378,4),(379,4),(380,4),(381,4),(382,4),(383,4),(384,4),(385,4),(386,4),(387,4),(388,4),(389,4),(390,4),(391,4),(392,4),(393,4),(394,4),(395,4),(396,4),(397,4),(398,4),(399,4),(400,4),(401,4),(402,4),(403,4),(404,4),(405,4),(406,4),(407,4),(408,4),(409,4),(410,4),(411,4),(412,4),(413,4),(414,4),(415,4),(416,4),(417,4),(418,4),(419,4),(420,4),(421,4),(422,4),(423,4),(424,4),(425,4),(426,4),(427,4),(428,4),(429,4),(430,4),(431,4),(432,4),(433,4),(434,4),(435,4),(436,4),(437,4),(438,4),(439,4),(440,4),(441,4),(442,4),(443,4),(444,4),(445,4),(446,4),(447,4),(448,4),(449,4),(450,4),(451,4),(452,4),(453,4),(454,4),(455,4),(456,4),(457,4),(458,4),(459,4),(460,4),(461,4),(462,4),(463,4),(464,4),(465,4),(466,4),(467,4),(468,4),(469,4),(470,4),(471,4),(472,4),(473,4),(474,4),(475,4),(476,4),(477,4),(478,4),(479,4),(480,4),(481,4),(482,4),(483,4),(484,4),(485,4),(486,4),(487,4),(488,4),(489,4),(490,4),(491,4),(492,4),(493,4),(494,4),(495,4),(496,4),(497,4),(498,4),(499,4),(500,4),(501,4),(502,4),(503,4),(504,4),(505,4),(506,4),(507,4),(508,4),(509,4),(510,4),(511,4),(512,4),(513,4),(514,4),(515,4),(516,4),(517,4),(518,4),(519,4),(520,4),(521,4),(522,4),(523,4),(524,4),(525,4),(526,4),(527,4),(528,4),(529,4),(530,4),(531,4),(532,4),(533,4),(534,4),(535,4),(536,4),(537,4),(538,4),(539,4),(540,4),(541,4),(542,4),(543,4),(544,4),(545,4),(546,4),(547,4),(548,4),(549,4),(550,4),(551,4),(552,4),(553,4),(554,4),(555,4),(556,4),(557,4),(558,4),(559,4),(560,4),(561,4),(562,4),(563,4),(564,4),(565,4),(566,4),(567,4),(568,4),(569,4),(570,4),(571,4),(572,4),(573,4),(574,4),(575,4),(576,4),(577,4),(578,4),(579,4),(580,4),(581,4),(582,4),(583,4),(584,4),(585,4),(586,4),(587,4),(588,4),(589,4),(590,4),(591,4),(592,4),(593,4),(594,4),(595,4),(596,4),(597,4),(598,4),(599,4),(600,4),(601,4),(602,4),(603,4),(604,4),(605,4),(606,4),(607,4),(608,4),(609,4),(610,4),(611,4),(612,4),(613,4),(614,4),(615,4),(616,4),(617,4),(618,4),(619,4),(620,4),(621,4),(622,4),(623,4),(624,4),(625,4),(626,4),(627,4),(628,4),(629,4),(630,4),(631,4),(632,4),(633,4),(634,4),(635,4),(636,4),(637,4),(638,4),(639,4),(640,4),(641,4),(642,4),(643,4),(644,4),(645,4),(646,4),(647,4),(648,4),(649,4),(650,4),(651,4),(652,4),(653,4),(654,4),(655,4),(656,4),(657,4),(658,4),(659,4),(660,4),(661,4),(662,4),(663,4),(664,4),(665,4),(666,4),(667,4),(668,4),(669,4),(670,4),(671,4),(672,4),(673,4),(674,4),(675,4),(676,4),(677,4),(678,4),(679,4),(680,4),(681,4),(682,4),(683,4),(684,4),(685,4),(686,4),(687,4),(688,4),(689,4),(690,4),(691,4),(692,4),(693,4),(694,4),(695,4),(696,4),(697,4),(698,4),(699,4),(700,4),(701,4),(702,4),(703,4),(704,4),(705,4),(706,4),(707,4),(708,4),(709,4),(710,4),(711,4),(712,4),(713,4),(714,4),(715,4),(716,4),(717,4),(718,4),(719,4),(720,4),(721,4),(722,4),(723,4),(724,4),(725,4),(726,4),(727,4),(728,4),(729,4),(730,4),(731,4),(732,4),(733,4),(734,4),(735,4),(736,4),(737,4),(738,4),(739,4),(740,4),(741,4),(742,4),(743,4),(744,4),(745,4),(746,4),(747,4),(748,4),(749,4),(750,4),(751,4),(752,4),(753,4),(754,4),(755,4),(756,4),(757,4),(758,4),(759,4),(760,4),(761,4),(762,4),(763,4),(764,4),(765,4),(766,4),(767,4),(768,4),(769,4),(770,4),(771,4),(772,4),(773,4),(774,4),(775,4),(776,4),(777,4),(778,4),(779,4),(780,4),(781,4),(782,4),(783,4),(784,4),(785,4),(786,4),(787,4),(788,4),(789,4),(790,4),(791,4),(792,4),(793,4),(794,4),(795,4),(796,4),(797,4),(798,4),(799,4),(800,4),(801,4),(802,4),(803,4),(804,4),(805,4),(806,4),(807,4),(808,4),(809,4),(810,4),(811,4),(812,4),(813,4),(814,4),(815,4),(816,4),(817,4),(818,4),(819,4),(820,4),(821,4),(822,4),(823,4),(824,4),(825,4),(826,4),(827,4),(828,4),(829,4),(830,4),(831,4),(832,4),(833,4),(834,4),(835,4),(836,4),(837,4),(838,4),(839,4),(840,4),(841,4),(842,4),(843,4),(844,4),(845,4),(846,4),(847,4),(848,4),(849,4),(850,4),(851,4),(852,4),(853,4),(854,4),(855,4),(856,4),(857,4),(858,4),(859,4),(860,4),(861,4),(862,4),(863,4),(864,4),(865,4),(866,4),(867,4),(868,4),(869,4),(870,4),(871,4),(872,4),(873,4),(874,4),(875,4),(876,4),(877,4),(878,4),(879,4),(880,4),(881,4),(882,4),(883,4),(884,4),(885,4),(886,4),(887,4),(888,4),(889,4),(890,4),(891,4),(892,4),(893,4),(894,4),(895,4),(896,4),(897,4),(898,4),(899,4),(900,4),(901,4),(902,4),(903,4),(904,4),(905,4),(906,4),(907,4),(908,4),(909,4),(910,4),(911,4),(912,4),(913,4),(914,4),(915,4),(916,4),(917,4),(918,4),(919,4),(920,4),(921,4),(922,4),(923,4),(924,4),(925,4),(926,4),(927,4),(928,4),(929,4),(930,4),(931,4),(932,4),(933,4),(934,4),(935,4),(936,4),(937,4),(938,4),(939,4),(940,4),(941,4),(942,4),(943,4),(944,4),(945,4),(946,4),(947,4),(948,4),(949,4),(950,4),(951,4),(952,4),(953,4),(954,4),(955,4),(956,4),(957,4),(958,4),(959,4),(960,4),(961,4),(962,4),(963,4),(964,4),(965,4),(966,4),(967,4),(968,4),(969,4),(970,4),(971,4),(972,4),(973,4),(974,4),(975,4),(976,4),(977,4),(978,4),(979,4),(980,4),(981,4),(982,4),(983,4),(984,4),(985,4),(986,4),(987,4),(988,4),(989,4),(990,4),(991,4),(992,4),(993,4),(994,4),(995,4),(996,4),(997,4),(998,4),(999,4),(1000,4),(1001,4),(1002,4),(1003,4),(1004,4),(1005,4),(1006,4),(1007,4),(1008,4),(1009,4),(1010,4),(1011,4),(1012,4),(1013,4),(1014,4),(1015,4),(1016,4),(1017,4),(1018,4),(1019,4),(1020,4),(1021,4),(1022,4),(1023,4),(1024,4),(1025,4),(1026,4),(1027,4),(1028,4),(1029,4),(1030,4),(1031,4),(1032,4),(1033,4),(1034,4),(1035,4),(1036,4),(1037,4),(1038,4),(1039,4),(1040,4),(1041,4),(1042,4),(1043,4),(1044,4),(1045,4),(1046,4),(1047,4),(1048,4),(1049,4),(1050,4),(1051,4),(1052,4),(1053,4),(1054,4),(1055,4),(1056,4),(1057,4),(1058,4),(1059,4),(1060,4),(1061,4),(1062,4),(1063,4),(1064,4),(1065,4),(1066,4),(1067,4),(1068,4),(1069,4),(1070,4),(1071,4),(1072,4),(1073,4),(1074,4),(1075,4),(1076,4),(1077,4),(1078,4),(1079,4),(1080,4),(1081,4),(1082,4),(1083,4),(1084,4),(1085,4),(1086,4),(1087,4),(1088,4),(1089,4),(1090,4),(1091,4),(1092,4),(1093,4),(1094,4),(1095,4),(1096,4),(1097,4),(1098,4),(1099,4),(1100,4),(1101,4),(1102,4),(1103,4),(1104,4),(1105,4),(1106,4),(1107,4),(1108,4),(1109,4),(1110,4),(1111,4),(1112,4),(1113,4),(1114,4),(1115,4),(1116,4),(1117,4),(1118,4),(1119,4),(1120,4),(1121,4),(1122,4),(1123,4),(1124,4),(1125,4),(1126,4),(1127,4),(1128,4),(1129,4),(1130,4),(1131,4),(1132,4),(1133,4),(1134,4),(1135,4),(1136,4),(1137,4),(1138,4),(1139,4),(1140,4),(1141,4),(1142,4),(1143,4),(1144,4),(1145,4),(1146,4),(1147,4),(1148,4),(1149,4),(1150,4),(1151,4),(1152,4),(1153,4),(1154,4),(1155,4),(1156,4),(1157,4),(1158,4),(1159,4),(1160,4),(1161,4),(1162,4),(1163,4),(1164,4),(1165,4),(1166,4),(1167,4),(1168,4),(1169,4),(1170,4),(1171,4),(1172,4),(1173,4),(1174,4),(1175,4),(1176,4),(1177,4),(1178,4),(1179,4),(1180,4),(1181,4),(1182,4),(1183,4),(1184,4),(1185,4),(1186,4),(1187,4),(1188,4),(1189,4),(1190,4),(1191,4),(1192,4),(1193,4),(1194,4),(1195,4),(1196,4),(1197,4),(1198,4),(1199,4),(1200,4),(1201,4),(1202,4),(1203,4),(1204,4),(1205,4),(1206,4),(1207,4),(1208,4),(1209,4),(1210,4),(1211,4),(1212,4),(1213,4),(1214,4),(1215,4),(1216,4),(1217,4),(1218,4),(1219,4),(1220,4),(1221,4),(1222,4),(1223,4),(1224,4),(1225,4),(1226,4),(1227,4),(1228,4),(1229,4),(1230,4),(1231,4),(1232,4),(1233,4),(1234,4),(1235,4),(1236,4),(1237,4),(1238,4),(1239,4),(1240,4),(1241,4),(1242,4),(1243,4),(1244,4),(1245,4),(1246,4),(1247,4),(1248,4),(1249,4),(1250,4),(1251,4),(1252,4),(1253,4),(1254,4),(1255,4),(1256,4),(1257,4),(1258,4),(1259,4),(1260,4),(1261,4),(1262,4),(1263,4),(1264,4),(1265,4),(1266,4),(1267,4),(1268,4),(1269,4),(1270,4),(1271,4),(1272,4),(1273,4),(1274,4),(1275,4),(1276,4),(1277,4),(1278,4),(1279,4),(1280,4),(1281,4),(1282,4),(1283,4),(1284,4),(1285,4),(1286,4),(1287,4),(1288,4),(1289,4),(1290,4),(1291,4),(1292,4),(1293,4),(1294,4),(1295,4),(1296,4),(1297,4),(1298,4),(1299,4),(1300,4),(1301,4),(1302,4),(1303,4),(1304,4),(1305,4),(1306,4),(1307,4),(1308,4),(1309,4),(1310,4),(1311,4),(1312,4),(1313,4),(1314,4),(1315,4),(1316,4),(1317,4),(1318,4),(1319,4),(1320,4),(1321,4),(1322,4),(1323,4),(1324,4),(1325,4),(1326,4),(1327,4),(1328,4),(1329,4),(1330,4),(1331,4),(1332,4),(1333,4),(1334,4),(1335,4),(1336,4),(1337,4),(1338,4),(1339,4),(1340,4),(1341,4),(1342,4),(1343,4),(1344,4),(1345,4),(1346,4),(1347,4),(1348,4),(1349,4),(1350,4),(1351,4),(1352,4),(1353,4),(1354,4),(1355,4),(1356,4),(1357,4),(1358,4),(1359,4),(1360,4),(1361,4),(1362,4),(1363,4),(1364,4),(1365,4),(1366,4),(1367,4),(1368,4),(1369,4),(1370,4),(1371,4),(1372,4),(1373,4),(1374,4),(1375,4),(1376,4),(1377,4),(1378,4),(1379,4),(1380,4),(1381,4),(1382,4),(1383,4),(1384,4),(1385,4),(1386,4),(1387,4),(1388,4),(1389,4),(1390,4),(1391,4),(1392,4),(1393,4),(1394,4),(1395,4),(1396,4),(1397,4),(1398,4),(1399,4),(1400,4),(1401,4),(1402,4),(1403,4),(1404,4),(1405,4),(1406,4),(1407,4),(1408,4),(1409,4),(1410,4),(1411,4),(1412,4),(1413,4),(1414,4),(1415,4),(1416,4),(1417,4),(1418,4),(1419,4),(1420,4),(1421,4),(1422,4),(1423,4),(1424,4),(1425,4),(1426,4),(1427,4),(1428,4),(1429,4),(1430,4),(1431,4),(1432,4),(1433,4),(1434,4),(1435,4),(1436,4),(1437,4),(1438,4),(1439,4),(1440,4),(1441,4),(1442,4),(1443,4),(1444,4),(1445,4),(1446,4),(1447,4),(1448,4),(1449,4),(1450,4),(1451,4),(1452,4),(1453,4),(1454,4),(1455,4),(1456,4),(1457,4),(1458,4),(1459,4),(1460,4),(1461,4),(1462,4),(1463,4),(1464,4),(1465,4),(1466,4),(1467,4),(1468,4),(1469,4),(1470,4),(1471,4),(1472,4),(1473,4),(1474,4),(1475,4),(1476,4),(1477,4),(1478,4),(1479,4),(1480,4),(1481,4),(1482,4),(1483,4),(1484,4),(1485,4),(1486,4),(1487,4),(1488,4),(1489,4),(1490,4),(1491,4),(1492,4),(1493,4),(1494,4),(1495,4),(1496,4),(1497,4),(1498,4),(1499,4),(1500,4),(1501,4),(1502,4),(1503,4),(1504,4),(1505,4),(1506,4),(1507,4),(1508,4),(1509,4),(1510,4),(1511,4),(1512,4),(1513,4),(1514,4),(1515,4),(1516,4),(1517,4),(1518,4),(1519,4),(1520,4),(1521,4),(1522,4),(1523,4),(1524,4),(1525,4),(1526,4),(1527,4),(1528,4),(1529,4),(1530,4),(1531,4),(1532,4),(1533,4),(1534,4),(1535,4),(1536,4),(1537,4),(1538,4),(1539,4),(1540,4),(1541,4),(1542,4),(1543,4),(1544,4),(1545,4),(1546,4),(1547,4),(1548,4),(1549,4),(1550,4),(1551,4),(1552,4),(1553,4),(1554,4),(1555,4),(1556,4),(1557,4),(1558,4),(1559,4),(1560,4),(1561,4),(1562,4),(1563,4),(1564,4),(1565,4),(1566,4),(1567,4),(1568,4),(1569,4),(1570,4),(1571,4),(1572,4),(1573,4),(1574,4),(1575,4),(1576,4),(1577,4),(1578,4),(1579,4),(1580,4),(1581,4),(1582,4),(1583,4),(1584,4),(1585,4),(1586,4),(1587,4),(1588,4),(1589,4),(1590,4),(1591,4),(1592,4),(1593,4),(1594,4),(1595,4),(1596,4),(1597,4),(1598,4),(1599,4),(1600,4),(1601,4),(1602,4),(1603,4),(1604,4),(1605,4),(1606,4),(1607,4),(1608,4),(1609,4),(1610,4),(1611,4),(1612,4),(1613,4),(1614,4),(1615,4),(1616,4),(1617,4),(1618,4),(1619,4),(1620,4),(1621,4),(1622,4),(1623,4),(1624,4),(1625,4),(1626,4),(1627,4),(1628,4),(1629,4),(1630,4),(1631,4),(1632,4),(1633,4),(1634,4),(1635,4),(1636,4),(1637,4),(1638,4),(1639,4),(1640,4),(1641,4),(1642,4),(1643,4),(1644,4),(1645,4),(1646,4),(1647,4),(1648,4),(1649,4),(1650,4),(1651,4),(1652,4),(1653,4),(1654,4),(1655,4),(1656,4),(1657,4),(1658,4),(1659,4),(1660,4),(1661,4),(1662,4),(1663,4),(1664,4),(1665,4),(1666,4),(1667,4),(1668,4),(1669,4),(1670,4),(1671,4),(1672,4),(1673,4),(1674,4),(1675,4),(1676,4),(1677,4),(1678,4),(1679,4),(1680,4),(1681,4),(1682,4),(1683,4),(1684,4),(1685,4),(1686,4),(1687,4),(1688,4),(1689,4),(1690,4),(1691,4),(1692,4),(1693,4),(1694,4),(1695,4),(1696,4),(1697,4),(1698,4),(1699,4),(1700,4),(1701,4),(1702,4),(1703,4),(1704,4),(1705,4),(1706,4),(1707,4),(1708,4),(1709,4),(1710,4),(1711,4),(1712,4),(1713,4),(1714,4),(1715,4),(1716,4),(1717,4),(1718,4),(1719,4),(1720,4),(1721,4),(1722,4),(1723,4),(1724,4),(1725,4),(1726,4),(1727,4),(1728,4),(1729,4),(1730,4),(1731,4),(1732,4),(1733,4),(1734,4),(1735,4),(1736,4),(1737,4),(1738,4),(1739,4),(1740,4),(1741,4),(1742,4),(1743,4),(1744,4),(1745,4),(1746,4),(1747,4),(1748,4),(1749,4),(1750,4),(1751,4),(1752,4),(1753,4),(1754,4),(1755,4),(1756,4),(1757,4),(1758,4),(1759,4),(1760,4),(1761,4),(1762,4),(1763,4),(1764,4),(1765,4),(1766,4),(1767,4),(1768,4),(1769,4),(1770,4),(1771,4),(1772,4),(1773,4),(1774,4),(1775,4),(1776,4),(1777,4),(1778,4),(1779,4),(1780,4),(1781,4),(1782,4),(1783,4),(1784,4),(1785,4),(1786,4),(1787,4),(1788,4),(1789,4),(1790,4),(1791,4),(1792,4),(1793,4),(1794,4),(1795,4),(1796,4),(1797,4),(1798,4),(1799,4),(1800,4),(1801,4),(1802,4),(1803,4),(1804,4),(1805,4),(1806,4),(1807,4),(1808,4),(1809,4),(1810,4),(1811,4),(1812,4),(1813,4),(1814,4),(1815,4),(1816,4),(1817,4),(1818,4),(1819,4),(1820,4),(1821,4),(1822,4),(1823,4),(1824,4),(1825,4),(1826,4),(1827,4),(1828,4),(1829,4),(1830,4),(1831,4),(1832,4),(1833,4),(1834,4),(1835,4),(1836,4),(1837,4),(1838,4),(1839,4),(1840,4),(1841,4),(1842,4),(1843,4),(1844,4),(1845,4),(1846,4),(1847,4),(1848,4),(1849,4),(1850,4),(1851,4),(1852,4),(1853,4),(1854,4),(1855,4),(1856,4),(1857,4),(1858,4),(1859,4),(1860,4),(1861,4),(1862,4),(1863,4),(1864,4),(1865,4),(1866,4),(1867,4),(1868,4),(1869,4),(1870,4),(1871,4),(1872,4),(1873,4),(1874,4),(1875,4),(1876,4),(1877,4),(1878,4),(1879,4),(1880,4),(1881,4),(1882,4),(1883,4),(1884,4),(1885,4),(1886,4),(1887,4),(1888,4),(1889,4),(1890,4),(1891,4),(1892,4),(1893,4),(1894,4),(1895,4),(1896,4),(1897,4),(1898,4),(1899,4),(1900,4),(1901,4),(1902,4),(1903,4),(1904,4),(1905,4),(1906,4),(1907,4),(1908,4),(1909,4),(1910,4),(1911,4),(1912,4),(1913,4),(1914,4),(1915,4),(1916,4),(1917,4),(1918,4),(1919,4),(1920,4),(1921,4),(1922,4),(1923,4),(1924,4),(1925,4),(1926,4),(1927,4),(1928,4),(1929,4),(1930,4),(1931,4),(1932,4),(1933,4),(1934,4),(1935,4),(1936,4),(1937,4),(1938,4),(1939,4),(1940,4),(1941,4),(1942,4),(1943,4),(1944,4),(1945,4),(1946,4),(1947,4),(1948,4),(1949,4),(1950,4),(1951,4),(1952,4),(1953,4),(1954,4),(1955,4),(1956,4),(1957,4),(1958,4),(1959,4),(1960,4),(1961,4),(1962,4),(1963,4),(1964,4),(1965,4),(1966,4),(1967,4),(1968,4),(1969,4),(1970,4),(1971,4),(1972,4),(1973,4),(1974,4),(1,5),(2,5),(3,5),(4,5),(5,5),(6,5),(7,5),(8,5),(9,5),(10,5),(11,5),(12,5),(13,5),(14,5),(15,5),(16,5),(17,5),(18,5),(19,5),(20,5),(21,5),(22,5),(23,5),(24,5),(25,5),(26,5),(27,5),(28,5),(29,5),(30,5),(31,5),(32,5),(33,5),(34,5),(35,5),(36,5),(37,5),(38,5),(39,5),(40,5),(41,5),(42,5),(43,5),(44,5),(45,5),(46,5),(47,5),(48,5),(49,5),(50,5),(51,5),(52,5),(53,5),(54,5),(55,5),(56,5),(57,5),(58,5),(59,5),(60,5),(61,5),(62,5),(63,5),(64,5),(65,5),(66,5),(67,5),(68,5),(69,5),(70,5),(71,5),(72,5),(73,5),(74,5),(75,5),(76,5),(77,5),(78,5),(79,5),(80,5),(81,5),(82,5),(83,5),(84,5),(85,5),(86,5),(87,5),(88,5),(89,5),(90,5),(91,5),(92,5),(93,5),(94,5),(95,5),(96,5),(97,5),(98,5),(99,5),(100,5),(101,5),(102,5),(103,5),(104,5),(105,5),(106,5),(107,5),(108,5),(109,5),(110,5),(111,5),(112,5),(113,5),(114,5),(115,5),(116,5),(117,5),(118,5),(119,5),(120,5),(121,5),(122,5),(123,5),(124,5),(125,5),(126,5),(127,5),(128,5),(129,5),(130,5),(131,5),(132,5),(133,5),(134,5),(135,5),(136,5),(137,5),(138,5),(139,5),(140,5),(141,5),(142,5),(143,5),(144,5),(145,5),(146,5),(147,5),(148,5),(149,5),(150,5),(151,5),(152,5),(153,5),(154,5),(155,5),(156,5),(157,5),(158,5),(159,5),(160,5),(161,5),(162,5),(163,5),(164,5),(165,5),(166,5),(167,5),(168,5),(169,5),(170,5),(171,5),(172,5),(173,5),(174,5),(175,5),(176,5),(177,5),(178,5),(179,5),(180,5),(181,5),(182,5),(183,5),(184,5),(185,5),(186,5),(187,5),(188,5),(189,5),(190,5),(191,5),(192,5),(193,5),(194,5),(195,5),(196,5),(197,5),(198,5),(199,5),(200,5),(201,5),(202,5),(203,5),(204,5),(205,5),(206,5),(207,5),(208,5),(209,5),(210,5),(211,5),(212,5),(213,5),(214,5),(215,5),(216,5),(217,5),(218,5),(219,5),(220,5),(221,5),(222,5),(223,5),(224,5),(225,5),(226,5),(227,5),(228,5),(229,5),(230,5),(231,5),(232,5),(233,5),(234,5),(235,5),(236,5),(237,5),(238,5),(239,5),(240,5),(241,5),(242,5),(243,5),(244,5),(245,5),(246,5),(247,5),(248,5),(249,5),(250,5),(251,5),(252,5),(253,5),(254,5),(255,5),(256,5),(257,5),(258,5),(259,5),(260,5),(261,5),(262,5),(263,5),(264,5),(265,5),(266,5),(267,5),(268,5),(269,5),(270,5),(271,5),(272,5),(273,5),(274,5),(275,5),(276,5),(277,5),(278,5),(279,5),(280,5),(281,5),(282,5),(283,5),(284,5),(285,5),(286,5),(287,5),(288,5),(289,5),(290,5),(291,5),(292,5),(293,5),(294,5),(295,5),(296,5),(297,5),(298,5),(299,5),(300,5),(301,5),(302,5),(303,5),(304,5),(305,5),(306,5),(307,5),(308,5),(309,5),(310,5),(311,5),(312,5),(313,5),(314,5),(315,5),(316,5),(317,5),(318,5),(319,5),(320,5),(321,5),(322,5),(323,5),(324,5),(325,5),(326,5),(327,5),(328,5),(329,5),(330,5),(331,5),(332,5),(333,5),(334,5),(335,5),(336,5),(337,5),(338,5),(339,5),(340,5),(341,5),(342,5),(343,5),(344,5),(345,5),(346,5),(347,5),(348,5),(349,5),(350,5),(351,5),(352,5),(353,5),(354,5),(355,5),(356,5),(357,5),(358,5),(359,5),(360,5),(361,5),(362,5),(363,5),(364,5),(365,5),(366,5),(367,5),(368,5),(369,5),(370,5),(371,5),(372,5),(373,5),(374,5),(375,5),(376,5),(377,5),(378,5),(379,5),(380,5),(381,5),(382,5),(383,5),(384,5),(385,5),(386,5),(387,5),(388,5),(389,5),(390,5),(391,5),(392,5),(393,5),(394,5),(395,5),(396,5),(397,5),(398,5),(399,5),(400,5),(401,5),(402,5),(403,5),(404,5),(405,5),(406,5),(407,5),(408,5),(409,5),(410,5),(411,5),(412,5),(413,5),(414,5),(415,5),(416,5),(417,5),(418,5),(419,5),(420,5),(421,5),(422,5),(423,5),(424,5),(425,5),(426,5),(427,5),(428,5),(429,5),(430,5),(431,5),(432,5),(433,5),(434,5),(435,5),(436,5),(437,5),(438,5),(439,5),(440,5),(441,5),(442,5),(443,5),(444,5),(445,5),(446,5),(447,5),(448,5),(449,5),(450,5),(451,5),(452,5),(453,5),(454,5),(455,5),(456,5),(457,5),(458,5),(459,5),(460,5),(461,5),(462,5),(463,5),(464,5),(465,5),(466,5),(467,5),(468,5),(469,5),(470,5),(471,5),(472,5),(473,5),(474,5),(475,5),(476,5),(477,5),(478,5),(479,5),(480,5),(481,5),(482,5),(483,5),(484,5),(485,5),(486,5),(487,5),(488,5),(489,5),(490,5),(491,5),(492,5),(493,5),(494,5),(495,5),(496,5),(497,5),(498,5),(499,5),(500,5),(501,5),(502,5),(503,5),(504,5),(505,5),(506,5),(507,5),(508,5),(509,5),(510,5),(511,5),(512,5),(513,5),(514,5),(515,5),(516,5),(517,5),(518,5),(519,5),(520,5),(521,5),(522,5),(523,5),(524,5),(525,5),(526,5),(527,5),(528,5),(529,5),(530,5),(531,5),(532,5),(533,5),(534,5),(535,5),(536,5),(537,5),(538,5),(539,5),(540,5),(541,5),(542,5),(543,5),(544,5),(545,5),(546,5),(547,5),(548,5),(549,5),(550,5),(551,5),(552,5),(553,5),(554,5),(555,5),(556,5),(557,5),(558,5),(559,5),(560,5),(561,5),(562,5),(563,5),(564,5),(565,5),(566,5),(567,5),(568,5),(569,5),(570,5),(571,5),(572,5),(573,5),(574,5),(575,5),(576,5),(577,5),(578,5),(579,5),(580,5),(581,5),(582,5),(583,5),(584,5),(585,5),(586,5),(587,5),(588,5),(589,5),(590,5),(591,5),(592,5),(593,5),(594,5),(595,5),(596,5),(597,5),(598,5),(599,5),(600,5),(601,5),(602,5),(603,5),(604,5),(605,5),(606,5),(607,5),(608,5),(609,5),(610,5),(611,5),(612,5),(613,5),(614,5),(615,5),(616,5),(617,5),(618,5),(619,5),(620,5),(621,5),(622,5),(623,5),(624,5),(625,5),(626,5),(627,5),(628,5),(629,5),(630,5),(631,5),(632,5),(633,5),(634,5),(635,5),(636,5),(637,5),(638,5),(639,5),(640,5),(641,5),(642,5),(643,5),(644,5),(645,5),(646,5),(647,5),(648,5),(649,5),(650,5),(651,5),(652,5),(653,5),(654,5),(655,5),(656,5),(657,5),(658,5),(659,5),(660,5),(661,5),(662,5),(663,5),(664,5),(665,5),(666,5),(667,5),(668,5),(669,5),(670,5),(671,5),(672,5),(673,5),(674,5),(675,5),(676,5),(677,5),(678,5),(679,5),(680,5),(681,5),(682,5),(683,5),(684,5),(685,5),(686,5),(687,5),(688,5),(689,5),(690,5),(691,5),(692,5),(693,5),(694,5),(695,5),(696,5),(697,5),(698,5),(699,5),(700,5),(701,5),(702,5),(703,5),(704,5),(705,5),(706,5),(707,5),(708,5),(709,5),(710,5),(711,5),(712,5),(713,5),(714,5),(715,5),(716,5),(717,5),(718,5),(719,5),(720,5),(721,5),(722,5),(723,5),(724,5),(725,5),(726,5),(727,5),(728,5),(729,5),(730,5),(731,5),(732,5),(733,5),(734,5),(735,5),(736,5),(737,5),(738,5),(739,5),(740,5),(741,5),(742,5),(743,5),(744,5),(745,5),(746,5),(747,5),(748,5),(749,5),(750,5),(751,5),(752,5),(753,5),(754,5),(755,5),(756,5),(757,5),(758,5),(759,5),(760,5),(761,5),(762,5),(763,5),(764,5),(765,5),(766,5),(767,5),(768,5),(769,5),(770,5),(771,5),(772,5),(773,5),(774,5),(775,5),(776,5),(777,5),(778,5),(779,5),(780,5),(781,5),(782,5),(783,5),(784,5),(785,5),(786,5),(787,5),(788,5),(789,5),(790,5),(791,5),(792,5),(793,5),(794,5),(795,5),(796,5),(797,5),(798,5),(799,5),(800,5),(801,5),(802,5),(803,5),(804,5),(805,5),(806,5),(807,5),(808,5),(809,5),(810,5),(811,5),(812,5),(813,5),(814,5),(815,5),(816,5),(817,5),(818,5),(819,5),(820,5),(821,5),(822,5),(823,5),(824,5),(825,5),(826,5),(827,5),(828,5),(829,5),(830,5),(831,5),(832,5),(833,5),(834,5),(835,5),(836,5),(837,5),(838,5),(839,5),(840,5),(841,5),(842,5),(843,5),(844,5),(845,5),(846,5),(847,5),(848,5),(849,5),(850,5),(851,5),(852,5),(853,5),(854,5),(855,5),(856,5),(857,5),(858,5),(859,5),(860,5),(861,5),(862,5),(863,5),(864,5),(865,5),(866,5),(867,5),(868,5),(869,5),(870,5),(871,5),(872,5),(873,5),(874,5),(875,5),(876,5),(877,5),(878,5),(879,5),(880,5),(881,5),(882,5),(883,5),(884,5),(885,5),(886,5),(887,5),(888,5),(889,5),(890,5),(891,5),(892,5),(893,5),(894,5),(895,5),(896,5),(897,5),(898,5),(899,5),(900,5),(901,5),(902,5),(903,5),(904,5),(905,5),(906,5),(907,5),(908,5),(909,5),(910,5),(911,5),(912,5),(913,5),(914,5),(915,5),(916,5),(917,5),(918,5),(919,5),(920,5),(921,5),(922,5),(923,5),(924,5),(925,5),(926,5),(927,5),(928,5),(929,5),(930,5),(931,5),(932,5),(933,5),(934,5),(935,5),(936,5),(937,5),(938,5),(939,5),(940,5),(941,5),(942,5),(943,5),(944,5),(945,5),(946,5),(947,5),(948,5),(949,5),(950,5),(951,5),(952,5),(953,5),(954,5),(955,5),(956,5),(957,5),(958,5),(959,5),(960,5),(961,5),(962,5),(963,5),(964,5),(965,5),(966,5),(967,5),(968,5),(969,5),(970,5),(971,5),(972,5),(973,5),(974,5),(975,5),(976,5),(977,5),(978,5),(979,5),(980,5),(981,5),(982,5),(983,5),(984,5),(985,5),(986,5),(987,5),(988,5),(989,5),(990,5),(991,5),(992,5),(993,5),(994,5),(995,5),(996,5),(997,5),(998,5),(999,5),(1000,5),(1001,5),(1002,5),(1003,5),(1004,5),(1005,5),(1006,5),(1007,5),(1008,5),(1009,5),(1010,5),(1011,5),(1012,5),(1013,5),(1014,5),(1015,5),(1016,5),(1017,5),(1018,5),(1019,5),(1020,5),(1021,5),(1022,5),(1023,5),(1024,5),(1025,5),(1026,5),(1027,5),(1028,5),(1029,5),(1030,5),(1031,5),(1032,5),(1033,5),(1034,5),(1035,5),(1036,5),(1037,5),(1038,5),(1039,5),(1040,5),(1041,5),(1042,5),(1043,5),(1044,5),(1045,5),(1046,5),(1047,5),(1048,5),(1049,5),(1050,5),(1051,5),(1052,5),(1053,5),(1054,5),(1055,5),(1056,5),(1057,5),(1058,5),(1059,5),(1060,5),(1061,5),(1062,5),(1063,5),(1064,5),(1065,5),(1066,5),(1067,5),(1068,5),(1069,5),(1070,5),(1071,5),(1072,5),(1073,5),(1074,5),(1075,5),(1076,5),(1077,5),(1078,5),(1079,5),(1080,5),(1081,5),(1082,5),(1083,5),(1084,5),(1085,5),(1086,5),(1087,5),(1088,5),(1089,5),(1090,5),(1091,5),(1092,5),(1093,5),(1094,5),(1095,5),(1096,5),(1097,5),(1098,5),(1099,5),(1100,5),(1101,5),(1102,5),(1103,5),(1104,5),(1105,5),(1106,5),(1107,5),(1108,5),(1109,5),(1110,5),(1111,5),(1112,5),(1113,5),(1114,5),(1115,5),(1116,5),(1117,5),(1118,5),(1119,5),(1120,5),(1121,5),(1122,5),(1123,5),(1124,5),(1125,5),(1126,5),(1127,5),(1128,5),(1129,5),(1130,5),(1131,5),(1132,5),(1133,5),(1134,5),(1135,5),(1136,5),(1137,5),(1138,5),(1139,5),(1140,5),(1141,5),(1142,5),(1143,5),(1144,5),(1145,5),(1146,5),(1147,5),(1148,5),(1149,5),(1150,5),(1151,5),(1152,5),(1153,5),(1154,5),(1155,5),(1156,5),(1157,5),(1158,5),(1159,5),(1160,5),(1161,5),(1162,5),(1163,5),(1164,5),(1165,5),(1166,5),(1167,5),(1168,5),(1169,5),(1170,5),(1171,5),(1172,5),(1173,5),(1174,5),(1175,5),(1176,5),(1177,5),(1178,5),(1179,5),(1180,5),(1181,5),(1182,5),(1183,5),(1184,5),(1185,5),(1186,5),(1187,5),(1188,5),(1189,5),(1190,5),(1191,5),(1192,5),(1193,5),(1194,5),(1195,5),(1196,5),(1197,5),(1198,5),(1199,5),(1200,5),(1201,5),(1202,5),(1203,5),(1204,5),(1205,5),(1206,5),(1207,5),(1208,5),(1209,5),(1210,5),(1211,5),(1212,5),(1213,5),(1214,5),(1215,5),(1216,5),(1217,5),(1218,5),(1219,5),(1220,5),(1221,5),(1222,5),(1223,5),(1224,5),(1225,5),(1226,5),(1227,5),(1228,5),(1229,5),(1230,5),(1231,5),(1232,5),(1233,5),(1234,5),(1235,5),(1236,5),(1237,5),(1238,5),(1239,5),(1240,5),(1241,5),(1242,5),(1243,5),(1244,5),(1245,5),(1246,5),(1247,5),(1248,5),(1249,5),(1250,5),(1251,5),(1252,5),(1253,5),(1254,5),(1255,5),(1256,5),(1257,5),(1258,5),(1259,5),(1260,5),(1261,5),(1262,5),(1263,5),(1264,5),(1265,5),(1266,5),(1267,5),(1268,5),(1269,5),(1270,5),(1271,5),(1272,5),(1273,5),(1274,5),(1275,5),(1276,5),(1277,5),(1278,5),(1279,5),(1280,5),(1281,5),(1282,5),(1283,5),(1284,5),(1285,5),(1286,5),(1287,5),(1288,5),(1289,5),(1290,5),(1291,5),(1292,5),(1293,5),(1294,5),(1295,5),(1296,5),(1297,5),(1298,5),(1299,5),(1300,5),(1301,5),(1302,5),(1303,5),(1304,5),(1305,5),(1306,5),(1307,5),(1308,5),(1309,5),(1310,5),(1311,5),(1312,5),(1313,5),(1314,5),(1315,5),(1316,5),(1317,5),(1318,5),(1319,5),(1320,5),(1321,5),(1322,5),(1323,5),(1324,5),(1325,5),(1326,5),(1327,5),(1328,5),(1329,5),(1330,5),(1331,5),(1332,5),(1333,5),(1334,5),(1335,5),(1336,5),(1337,5),(1338,5),(1339,5),(1340,5),(1341,5),(1342,5),(1343,5),(1344,5),(1345,5),(1346,5),(1347,5),(1348,5),(1349,5),(1350,5),(1351,5),(1352,5),(1353,5),(1354,5),(1355,5),(1356,5),(1357,5),(1358,5),(1359,5),(1360,5),(1361,5),(1362,5),(1363,5),(1364,5),(1365,5),(1366,5),(1367,5),(1368,5),(1369,5),(1370,5),(1371,5),(1372,5),(1373,5),(1374,5),(1375,5),(1376,5),(1377,5),(1378,5),(1379,5),(1380,5),(1381,5),(1382,5),(1383,5),(1384,5),(1385,5),(1386,5),(1387,5),(1388,5),(1389,5),(1390,5),(1391,5),(1392,5),(1393,5),(1394,5),(1395,5),(1396,5),(1397,5),(1398,5),(1399,5),(1400,5),(1401,5),(1402,5),(1403,5),(1404,5),(1405,5),(1406,5),(1407,5),(1408,5),(1409,5),(1410,5),(1411,5),(1412,5),(1413,5),(1414,5),(1415,5),(1416,5),(1417,5),(1418,5),(1419,5),(1420,5),(1421,5),(1422,5),(1423,5),(1424,5),(1425,5),(1426,5),(1427,5),(1428,5),(1429,5),(1430,5),(1431,5),(1432,5),(1433,5),(1434,5),(1435,5),(1436,5),(1437,5),(1438,5),(1439,5),(1440,5),(1441,5),(1442,5),(1443,5),(1444,5),(1445,5),(1446,5),(1447,5),(1448,5),(1449,5),(1450,5),(1451,5),(1452,5),(1453,5),(1454,5),(1455,5),(1456,5),(1457,5),(1458,5),(1459,5),(1460,5),(1461,5),(1462,5),(1463,5),(1464,5),(1465,5),(1466,5),(1467,5),(1468,5),(1469,5),(1470,5),(1471,5),(1472,5),(1473,5),(1474,5),(1475,5),(1476,5),(1477,5),(1478,5),(1479,5),(1480,5),(1481,5),(1482,5),(1483,5),(1484,5),(1485,5),(1486,5),(1487,5),(1488,5),(1489,5),(1490,5),(1491,5),(1492,5),(1493,5),(1494,5),(1495,5),(1496,5),(1497,5),(1498,5),(1499,5),(1500,5),(1501,5),(1502,5),(1503,5),(1504,5),(1505,5),(1506,5),(1507,5),(1508,5),(1509,5),(1510,5),(1511,5),(1512,5),(1513,5),(1514,5),(1515,5),(1516,5),(1517,5),(1518,5),(1519,5),(1520,5),(1521,5),(1522,5),(1523,5),(1524,5),(1525,5),(1526,5),(1527,5),(1528,5),(1529,5),(1530,5),(1531,5),(1532,5),(1533,5),(1534,5),(1535,5),(1536,5),(1537,5),(1538,5),(1539,5),(1540,5),(1541,5),(1542,5),(1543,5),(1544,5),(1545,5),(1546,5),(1547,5),(1548,5),(1549,5),(1550,5),(1551,5),(1552,5),(1553,5),(1554,5),(1555,5),(1556,5),(1557,5),(1558,5),(1559,5),(1560,5),(1561,5),(1562,5),(1563,5),(1564,5),(1565,5),(1566,5),(1567,5),(1568,5),(1569,5),(1570,5),(1571,5),(1572,5),(1573,5),(1574,5),(1575,5),(1576,5),(1577,5),(1578,5),(1579,5),(1580,5),(1581,5),(1582,5),(1583,5),(1584,5),(1585,5),(1586,5),(1587,5),(1588,5),(1589,5),(1590,5),(1591,5),(1592,5),(1593,5),(1594,5),(1595,5),(1596,5),(1597,5),(1598,5),(1599,5),(1600,5),(1601,5),(1602,5),(1603,5),(1604,5),(1605,5),(1606,5),(1607,5),(1608,5),(1609,5),(1610,5),(1611,5),(1612,5),(1613,5),(1614,5),(1615,5),(1616,5),(1617,5),(1618,5),(1619,5),(1620,5),(1621,5),(1622,5),(1623,5),(1624,5),(1625,5),(1626,5),(1627,5),(1628,5),(1629,5),(1630,5),(1631,5),(1632,5),(1633,5),(1634,5),(1635,5),(1636,5),(1637,5),(1638,5),(1639,5),(1640,5),(1641,5),(1642,5),(1643,5),(1644,5),(1645,5),(1646,5),(1647,5),(1648,5),(1649,5),(1650,5),(1651,5),(1652,5),(1653,5),(1654,5),(1655,5),(1656,5),(1657,5),(1658,5),(1659,5),(1660,5),(1661,5),(1662,5),(1663,5),(1664,5),(1665,5),(1666,5),(1667,5),(1668,5),(1669,5),(1670,5),(1671,5),(1672,5),(1673,5),(1674,5),(1675,5),(1676,5),(1677,5),(1678,5),(1679,5),(1680,5),(1681,5),(1682,5),(1683,5),(1684,5),(1685,5),(1686,5),(1687,5),(1688,5),(1689,5),(1690,5),(1691,5),(1692,5),(1693,5),(1694,5),(1695,5),(1696,5),(1697,5),(1698,5),(1699,5),(1700,5),(1701,5),(1702,5),(1703,5),(1704,5),(1705,5),(1706,5),(1707,5),(1708,5),(1709,5),(1710,5),(1711,5),(1712,5),(1713,5),(1714,5),(1715,5),(1716,5),(1717,5),(1718,5),(1719,5),(1720,5),(1721,5),(1722,5),(1723,5),(1724,5),(1725,5),(1726,5),(1727,5),(1728,5),(1729,5),(1730,5),(1731,5),(1732,5),(1733,5),(1734,5),(1735,5),(1736,5),(1737,5),(1738,5),(1739,5),(1740,5),(1741,5),(1742,5),(1743,5),(1744,5),(1745,5),(1746,5),(1747,5),(1748,5),(1749,5),(1750,5),(1751,5),(1752,5),(1753,5),(1754,5),(1755,5),(1756,5),(1757,5),(1758,5),(1759,5),(1760,5),(1761,5),(1762,5),(1763,5),(1764,5),(1765,5),(1766,5),(1767,5),(1768,5),(1769,5),(1770,5),(1771,5),(1772,5),(1773,5),(1774,5),(1775,5),(1776,5),(1777,5),(1778,5),(1779,5),(1780,5),(1781,5),(1782,5),(1783,5),(1784,5),(1785,5),(1786,5),(1787,5),(1788,5),(1789,5),(1790,5),(1791,5),(1792,5),(1793,5),(1794,5),(1795,5),(1796,5),(1797,5),(1798,5),(1799,5),(1800,5),(1801,5),(1802,5),(1803,5),(1804,5),(1805,5),(1806,5),(1807,5),(1808,5),(1809,5),(1810,5),(1811,5),(1812,5),(1813,5),(1814,5),(1815,5),(1816,5),(1817,5),(1818,5),(1819,5),(1820,5),(1821,5),(1822,5),(1823,5),(1824,5),(1825,5),(1826,5),(1827,5),(1828,5),(1829,5),(1830,5),(1831,5),(1832,5),(1833,5),(1834,5),(1835,5),(1836,5),(1837,5),(1838,5),(1839,5),(1840,5),(1841,5),(1842,5),(1843,5),(1844,5),(1845,5),(1846,5),(1847,5),(1848,5),(1849,5),(1850,5),(1851,5),(1852,5),(1853,5),(1854,5),(1855,5),(1856,5),(1857,5),(1858,5),(1859,5),(1860,5),(1861,5),(1862,5),(1863,5),(1864,5),(1865,5),(1866,5),(1867,5),(1868,5),(1869,5),(1870,5),(1871,5),(1872,5),(1873,5),(1874,5),(1875,5),(1876,5),(1877,5),(1878,5),(1879,5),(1880,5),(1881,5),(1882,5),(1883,5),(1884,5),(1885,5),(1886,5),(1887,5),(1888,5),(1889,5),(1890,5),(1891,5),(1892,5),(1893,5),(1894,5),(1895,5),(1896,5),(1897,5),(1898,5),(1899,5),(1900,5),(1901,5),(1902,5),(1903,5),(1904,5),(1905,5),(1906,5),(1907,5),(1908,5),(1909,5),(1910,5),(1911,5),(1912,5),(1913,5),(1914,5),(1915,5),(1916,5),(1917,5),(1918,5),(1919,5),(1920,5),(1921,5),(1922,5),(1923,5),(1924,5),(1925,5),(1926,5),(1927,5),(1928,5),(1929,5),(1930,5),(1931,5),(1932,5),(1933,5),(1934,5),(1935,5),(1936,5),(1937,5),(1938,5),(1939,5),(1940,5),(1941,5),(1942,5),(1943,5),(1944,5),(1945,5),(1946,5),(1947,5),(1948,5),(1949,5),(1950,5),(1951,5),(1952,5),(1953,5),(1954,5),(1955,5),(1956,5),(1957,5),(1958,5),(1959,5),(1960,5),(1961,5),(1962,5),(1963,5),(1964,5),(1965,5),(1966,5),(1967,5),(1968,5),(1969,5),(1970,5),(1971,5),(1972,5),(1973,5),(1974,5),(1,6),(2,6),(3,6),(4,6),(5,6),(6,6),(7,6),(8,6),(9,6),(10,6),(11,6),(12,6),(13,6),(14,6),(15,6),(16,6),(17,6),(18,6),(19,6),(20,6),(21,6),(22,6),(23,6),(24,6),(25,6),(26,6),(27,6),(28,6),(29,6),(30,6),(31,6),(32,6),(33,6),(34,6),(35,6),(36,6),(37,6),(38,6),(39,6),(40,6),(41,6),(42,6),(43,6),(44,6),(45,6),(46,6),(47,6),(48,6),(49,6),(50,6),(51,6),(52,6),(53,6),(54,6),(55,6),(56,6),(57,6),(58,6),(59,6),(60,6),(61,6),(62,6),(63,6),(64,6),(65,6),(66,6),(67,6),(68,6),(69,6),(70,6),(71,6),(72,6),(73,6),(74,6),(75,6),(76,6),(77,6),(78,6),(79,6),(80,6),(81,6),(82,6),(83,6),(84,6),(85,6),(86,6),(87,6),(88,6),(89,6),(90,6),(91,6),(92,6),(93,6),(94,6),(95,6),(96,6),(97,6),(98,6),(99,6),(100,6),(101,6),(102,6),(103,6),(104,6),(105,6),(106,6),(107,6),(108,6),(109,6),(110,6),(111,6),(112,6),(113,6),(114,6),(115,6),(116,6),(117,6),(118,6),(119,6),(120,6),(121,6),(122,6),(123,6),(124,6),(125,6),(126,6),(127,6),(128,6),(129,6),(130,6),(131,6),(132,6),(133,6),(134,6),(135,6),(136,6),(137,6),(138,6),(139,6),(140,6),(141,6),(142,6),(143,6),(144,6),(145,6),(146,6),(147,6),(148,6),(149,6),(150,6),(151,6),(152,6),(153,6),(154,6),(155,6),(156,6),(157,6),(158,6),(159,6),(160,6),(161,6),(162,6),(163,6),(164,6),(165,6),(166,6),(167,6),(168,6),(169,6),(170,6),(171,6),(172,6),(173,6),(174,6),(175,6),(176,6),(177,6),(178,6),(179,6),(180,6),(181,6),(182,6),(183,6),(184,6),(185,6),(186,6),(187,6),(188,6),(189,6),(190,6),(191,6),(192,6),(193,6),(194,6),(195,6),(196,6),(197,6),(198,6),(199,6),(200,6),(201,6),(202,6),(203,6),(204,6),(205,6),(206,6),(207,6),(208,6),(209,6),(210,6),(211,6),(212,6),(213,6),(214,6),(215,6),(216,6),(217,6),(218,6),(219,6),(220,6),(221,6),(222,6),(223,6),(224,6),(225,6),(226,6),(227,6),(228,6),(229,6),(230,6),(231,6),(232,6),(233,6),(234,6),(235,6),(236,6),(237,6),(238,6),(239,6),(240,6),(241,6),(242,6),(243,6),(244,6),(245,6),(246,6),(247,6),(248,6),(249,6),(250,6),(251,6),(252,6),(253,6),(254,6),(255,6),(256,6),(257,6),(258,6),(259,6),(260,6),(261,6),(262,6),(263,6),(264,6),(265,6),(266,6),(267,6),(268,6),(269,6),(270,6),(271,6),(272,6),(273,6),(274,6),(275,6),(276,6),(277,6),(278,6),(279,6),(280,6),(281,6),(282,6),(283,6),(284,6),(285,6),(286,6),(287,6),(288,6),(289,6),(290,6),(291,6),(292,6),(293,6),(294,6),(295,6),(296,6),(297,6),(298,6),(299,6),(300,6),(301,6),(302,6),(303,6),(304,6),(305,6),(306,6),(307,6),(308,6),(309,6),(310,6),(311,6),(312,6),(313,6),(314,6),(315,6),(316,6),(317,6),(318,6),(319,6),(320,6),(321,6),(322,6),(323,6),(324,6),(325,6),(326,6),(327,6),(328,6),(329,6),(330,6),(331,6),(332,6),(333,6),(334,6),(335,6),(336,6),(337,6),(338,6),(339,6),(340,6),(341,6),(342,6),(343,6),(344,6),(345,6),(346,6),(347,6),(348,6),(349,6),(350,6),(351,6),(352,6),(353,6),(354,6),(355,6),(356,6),(357,6),(358,6),(359,6),(360,6),(361,6),(362,6),(363,6),(364,6),(365,6),(366,6),(367,6),(368,6),(369,6),(370,6),(371,6),(372,6),(373,6),(374,6),(375,6),(376,6),(377,6),(378,6),(379,6),(380,6),(381,6),(382,6),(383,6),(384,6),(385,6),(386,6),(387,6),(388,6),(389,6),(390,6),(391,6),(392,6),(393,6),(394,6),(395,6),(396,6),(397,6),(398,6),(399,6),(400,6),(401,6),(402,6),(403,6),(404,6),(405,6),(406,6),(407,6),(408,6),(409,6),(410,6),(411,6),(412,6),(413,6),(414,6),(415,6),(416,6),(417,6),(418,6),(419,6),(420,6),(421,6),(422,6),(423,6),(424,6),(425,6),(426,6),(427,6),(428,6),(429,6),(430,6),(431,6),(432,6),(433,6),(434,6),(435,6),(436,6),(437,6),(438,6),(439,6),(440,6),(441,6),(442,6),(443,6),(444,6),(445,6),(446,6),(447,6),(448,6),(449,6),(450,6),(451,6),(452,6),(453,6),(454,6),(455,6),(456,6),(457,6),(458,6),(459,6),(460,6),(461,6),(462,6),(463,6),(464,6),(465,6),(466,6),(467,6),(468,6),(469,6),(470,6),(471,6),(472,6),(473,6),(474,6),(475,6),(476,6),(477,6),(478,6),(479,6),(480,6),(481,6),(482,6),(483,6),(484,6),(485,6),(486,6),(487,6),(488,6),(489,6),(490,6),(491,6),(492,6),(493,6),(494,6),(495,6),(496,6),(497,6),(498,6),(499,6),(500,6),(501,6),(502,6),(503,6),(504,6),(505,6),(506,6),(507,6),(508,6),(509,6),(510,6),(511,6),(512,6),(513,6),(514,6),(515,6),(516,6),(517,6),(518,6),(519,6),(520,6),(521,6),(522,6),(523,6),(524,6),(525,6),(526,6),(527,6),(528,6),(529,6),(530,6),(531,6),(532,6),(533,6),(534,6),(535,6),(536,6),(537,6),(538,6),(539,6),(540,6),(541,6),(542,6),(543,6),(544,6),(545,6),(546,6),(547,6),(548,6),(549,6),(550,6),(551,6),(552,6),(553,6),(554,6),(555,6),(556,6),(557,6),(558,6),(559,6),(560,6),(561,6),(562,6),(563,6),(564,6),(565,6),(566,6),(567,6),(568,6),(569,6),(570,6),(571,6),(572,6),(573,6),(574,6),(575,6),(576,6),(577,6),(578,6),(579,6),(580,6),(581,6),(582,6),(583,6),(584,6),(585,6),(586,6),(587,6),(588,6),(589,6),(590,6),(591,6),(592,6),(593,6),(594,6),(595,6),(596,6),(597,6),(598,6),(599,6),(600,6),(601,6),(602,6),(603,6),(604,6),(605,6),(606,6),(607,6),(608,6),(609,6),(610,6),(611,6),(612,6),(613,6),(614,6),(615,6),(616,6),(617,6),(618,6),(619,6),(620,6),(621,6),(622,6),(623,6),(624,6),(625,6),(626,6),(627,6),(628,6),(629,6),(630,6),(631,6),(632,6),(633,6),(634,6),(635,6),(636,6),(637,6),(638,6),(639,6),(640,6),(641,6),(642,6),(643,6),(644,6),(645,6),(646,6),(647,6),(648,6),(649,6),(650,6),(651,6),(652,6),(653,6),(654,6),(655,6),(656,6),(657,6),(658,6),(659,6),(660,6),(661,6),(662,6),(663,6),(664,6),(665,6),(666,6),(667,6),(668,6),(669,6),(670,6),(671,6),(672,6),(673,6),(674,6),(675,6),(676,6),(677,6),(678,6),(679,6),(680,6),(681,6),(682,6),(683,6),(684,6),(685,6),(686,6),(687,6),(688,6),(689,6),(690,6),(691,6),(692,6),(693,6),(694,6),(695,6),(696,6),(697,6),(698,6),(699,6),(700,6),(701,6),(702,6),(703,6),(704,6),(705,6),(706,6),(707,6),(708,6),(709,6),(710,6),(711,6),(712,6),(713,6),(714,6),(715,6),(716,6),(717,6),(718,6),(719,6),(720,6),(721,6),(722,6),(723,6),(724,6),(725,6),(726,6),(727,6),(728,6),(729,6),(730,6),(731,6),(732,6),(733,6),(734,6),(735,6),(736,6),(737,6),(738,6),(739,6),(740,6),(741,6),(742,6),(743,6),(744,6),(745,6),(746,6),(747,6),(748,6),(749,6),(750,6),(751,6),(752,6),(753,6),(754,6),(755,6),(756,6),(757,6),(758,6),(759,6),(760,6),(761,6),(762,6),(763,6),(764,6),(765,6),(766,6),(767,6),(768,6),(769,6),(770,6),(771,6),(772,6),(773,6),(774,6),(775,6),(776,6),(777,6),(778,6),(779,6),(780,6),(781,6),(782,6),(783,6),(784,6),(785,6),(786,6),(787,6),(788,6),(789,6),(790,6),(791,6),(792,6),(793,6),(794,6),(795,6),(796,6),(797,6),(798,6),(799,6),(800,6),(801,6),(802,6),(803,6),(804,6),(805,6),(806,6),(807,6),(808,6),(809,6),(810,6),(811,6),(812,6),(813,6),(814,6),(815,6),(816,6),(817,6),(818,6),(819,6),(820,6),(821,6),(822,6),(823,6),(824,6),(825,6),(826,6),(827,6),(828,6),(829,6),(830,6),(831,6),(832,6),(833,6),(834,6),(835,6),(836,6),(837,6),(838,6),(839,6),(840,6),(841,6),(842,6),(843,6),(844,6),(845,6),(846,6),(847,6),(848,6),(849,6),(850,6),(851,6),(852,6),(853,6),(854,6),(855,6),(856,6),(857,6),(858,6),(859,6),(860,6),(861,6),(862,6),(863,6),(864,6),(865,6),(866,6),(867,6),(868,6),(869,6),(870,6),(871,6),(872,6),(873,6),(874,6),(875,6),(876,6),(877,6),(878,6),(879,6),(880,6),(881,6),(882,6),(883,6),(884,6),(885,6),(886,6),(887,6),(888,6),(889,6),(890,6),(891,6),(892,6),(893,6),(894,6),(895,6),(896,6),(897,6),(898,6),(899,6),(900,6),(901,6),(902,6),(903,6),(904,6),(905,6),(906,6),(907,6),(908,6),(909,6),(910,6),(911,6),(912,6),(913,6),(914,6),(915,6),(916,6),(917,6),(918,6),(919,6),(920,6),(921,6),(922,6),(923,6),(924,6),(925,6),(926,6),(927,6),(928,6),(929,6),(930,6),(931,6),(932,6),(933,6),(934,6),(935,6),(936,6),(937,6),(938,6),(939,6),(940,6),(941,6),(942,6),(943,6),(944,6),(945,6),(946,6),(947,6),(948,6),(949,6),(950,6),(951,6),(952,6),(953,6),(954,6),(955,6),(956,6),(957,6),(958,6),(959,6),(960,6),(961,6),(962,6),(963,6),(964,6),(965,6),(966,6),(967,6),(968,6),(969,6),(970,6),(971,6),(972,6),(973,6),(974,6),(975,6),(976,6),(977,6),(978,6),(979,6),(980,6),(981,6),(982,6),(983,6),(984,6),(985,6),(986,6),(987,6),(988,6),(989,6),(990,6),(991,6),(992,6),(993,6),(994,6),(995,6),(996,6),(997,6),(998,6),(999,6),(1000,6),(1001,6),(1002,6),(1003,6),(1004,6),(1005,6),(1006,6),(1007,6),(1008,6),(1009,6),(1010,6),(1011,6),(1012,6),(1013,6),(1014,6),(1015,6),(1016,6),(1017,6),(1018,6),(1019,6),(1020,6),(1021,6),(1022,6),(1023,6),(1024,6),(1025,6),(1026,6),(1027,6),(1028,6),(1029,6),(1030,6),(1031,6),(1032,6),(1033,6),(1034,6),(1035,6),(1036,6),(1037,6),(1038,6),(1039,6),(1040,6),(1041,6),(1042,6),(1043,6),(1044,6),(1045,6),(1046,6),(1047,6),(1048,6),(1049,6),(1050,6),(1051,6),(1052,6),(1053,6),(1054,6),(1055,6),(1056,6),(1057,6),(1058,6),(1059,6),(1060,6),(1061,6),(1062,6),(1063,6),(1064,6),(1065,6),(1066,6),(1067,6),(1068,6),(1069,6),(1070,6),(1071,6),(1072,6),(1073,6),(1074,6),(1075,6),(1076,6),(1077,6),(1078,6),(1079,6),(1080,6),(1081,6),(1082,6),(1083,6),(1084,6),(1085,6),(1086,6),(1087,6),(1088,6),(1089,6),(1090,6),(1091,6),(1092,6),(1093,6),(1094,6),(1095,6),(1096,6),(1097,6),(1098,6),(1099,6),(1100,6),(1101,6),(1102,6),(1103,6),(1104,6),(1105,6),(1106,6),(1107,6),(1108,6),(1109,6),(1110,6),(1111,6),(1112,6),(1113,6),(1114,6),(1115,6),(1116,6),(1117,6),(1118,6),(1119,6),(1120,6),(1121,6),(1122,6),(1123,6),(1124,6),(1125,6),(1126,6),(1127,6),(1128,6),(1129,6),(1130,6),(1131,6),(1132,6),(1133,6),(1134,6),(1135,6),(1136,6),(1137,6),(1138,6),(1139,6),(1140,6),(1141,6),(1142,6),(1143,6),(1144,6),(1145,6),(1146,6),(1147,6),(1148,6),(1149,6),(1150,6),(1151,6),(1152,6),(1153,6),(1154,6),(1155,6),(1156,6),(1157,6),(1158,6),(1159,6),(1160,6),(1161,6),(1162,6),(1163,6),(1164,6),(1165,6),(1166,6),(1167,6),(1168,6),(1169,6),(1170,6),(1171,6),(1172,6),(1173,6),(1174,6),(1175,6),(1176,6),(1177,6),(1178,6),(1179,6),(1180,6),(1181,6),(1182,6),(1183,6),(1184,6),(1185,6),(1186,6),(1187,6),(1188,6),(1189,6),(1190,6),(1191,6),(1192,6),(1193,6),(1194,6),(1195,6),(1196,6),(1197,6),(1198,6),(1199,6),(1200,6),(1201,6),(1202,6),(1203,6),(1204,6),(1205,6),(1206,6),(1207,6),(1208,6),(1209,6),(1210,6),(1211,6),(1212,6),(1213,6),(1214,6),(1215,6),(1216,6),(1217,6),(1218,6),(1219,6),(1220,6),(1221,6),(1222,6),(1223,6),(1224,6),(1225,6),(1226,6),(1227,6),(1228,6),(1229,6),(1230,6),(1231,6),(1232,6),(1233,6),(1234,6),(1235,6),(1236,6),(1237,6),(1238,6),(1239,6),(1240,6),(1241,6),(1242,6),(1243,6),(1244,6),(1245,6),(1246,6),(1247,6),(1248,6),(1249,6),(1250,6),(1251,6),(1252,6),(1253,6),(1254,6),(1255,6),(1256,6),(1257,6),(1258,6),(1259,6),(1260,6),(1261,6),(1262,6),(1263,6),(1264,6),(1265,6),(1266,6),(1267,6),(1268,6),(1269,6),(1270,6),(1271,6),(1272,6),(1273,6),(1274,6),(1275,6),(1276,6),(1277,6),(1278,6),(1279,6),(1280,6),(1281,6),(1282,6),(1283,6),(1284,6),(1285,6),(1286,6),(1287,6),(1288,6),(1289,6),(1290,6),(1291,6),(1292,6),(1293,6),(1294,6),(1295,6),(1296,6),(1297,6),(1298,6),(1299,6),(1300,6),(1301,6),(1302,6),(1303,6),(1304,6),(1305,6),(1306,6),(1307,6),(1308,6),(1309,6),(1310,6),(1311,6),(1312,6),(1313,6),(1314,6),(1315,6),(1316,6),(1317,6),(1318,6),(1319,6),(1320,6),(1321,6),(1322,6),(1323,6),(1324,6),(1325,6),(1326,6),(1327,6),(1328,6),(1329,6),(1330,6),(1331,6),(1332,6),(1333,6),(1334,6),(1335,6),(1336,6),(1337,6),(1338,6),(1339,6),(1340,6),(1341,6),(1342,6),(1343,6),(1344,6),(1345,6),(1346,6),(1347,6),(1348,6),(1349,6),(1350,6),(1351,6),(1352,6),(1353,6),(1354,6),(1355,6),(1356,6),(1357,6),(1358,6),(1359,6),(1360,6),(1361,6),(1362,6),(1363,6),(1364,6),(1365,6),(1366,6),(1367,6),(1368,6),(1369,6),(1370,6),(1371,6),(1372,6),(1373,6),(1374,6),(1375,6),(1376,6),(1377,6),(1378,6),(1379,6),(1380,6),(1381,6),(1382,6),(1383,6),(1384,6),(1385,6),(1386,6),(1387,6),(1388,6),(1389,6),(1390,6),(1391,6),(1392,6),(1393,6),(1394,6),(1395,6),(1396,6),(1397,6),(1398,6),(1399,6),(1400,6),(1401,6),(1402,6),(1403,6),(1404,6),(1405,6),(1406,6),(1407,6),(1408,6),(1409,6),(1410,6),(1411,6),(1412,6),(1413,6),(1414,6),(1415,6),(1416,6),(1417,6),(1418,6),(1419,6),(1420,6),(1421,6),(1422,6),(1423,6),(1424,6),(1425,6),(1426,6),(1427,6),(1428,6),(1429,6),(1430,6),(1431,6),(1432,6),(1433,6),(1434,6),(1435,6),(1436,6),(1437,6),(1438,6),(1439,6),(1440,6),(1441,6),(1442,6),(1443,6),(1444,6),(1445,6),(1446,6),(1447,6),(1448,6),(1449,6),(1450,6),(1451,6),(1452,6),(1453,6),(1454,6),(1455,6),(1456,6),(1457,6),(1458,6),(1459,6),(1460,6),(1461,6),(1462,6),(1463,6),(1464,6),(1465,6),(1466,6),(1467,6),(1468,6),(1469,6),(1470,6),(1471,6),(1472,6),(1473,6),(1474,6),(1475,6),(1476,6),(1477,6),(1478,6),(1479,6),(1480,6),(1481,6),(1482,6),(1483,6),(1484,6),(1485,6),(1486,6),(1487,6),(1488,6),(1489,6),(1490,6),(1491,6),(1492,6),(1493,6),(1494,6),(1495,6),(1496,6),(1497,6),(1498,6),(1499,6),(1500,6),(1501,6),(1502,6),(1503,6),(1504,6),(1505,6),(1506,6),(1507,6),(1508,6),(1509,6),(1510,6),(1511,6),(1512,6),(1513,6),(1514,6),(1515,6),(1516,6),(1517,6),(1518,6),(1519,6),(1520,6),(1521,6),(1522,6),(1523,6),(1524,6),(1525,6),(1526,6),(1527,6),(1528,6),(1529,6),(1530,6),(1531,6),(1532,6),(1533,6),(1534,6),(1535,6),(1536,6),(1537,6),(1538,6),(1539,6),(1540,6),(1541,6),(1542,6),(1543,6),(1544,6),(1545,6),(1546,6),(1547,6),(1548,6),(1549,6),(1550,6),(1551,6),(1552,6),(1553,6),(1554,6),(1555,6),(1556,6),(1557,6),(1558,6),(1559,6),(1560,6),(1561,6),(1562,6),(1563,6),(1564,6),(1565,6),(1566,6),(1567,6),(1568,6),(1569,6),(1570,6),(1571,6),(1572,6),(1573,6),(1574,6),(1575,6),(1576,6),(1577,6),(1578,6),(1579,6),(1580,6),(1581,6),(1582,6),(1583,6),(1584,6),(1585,6),(1586,6),(1587,6),(1588,6),(1589,6),(1590,6),(1591,6),(1592,6),(1593,6),(1594,6),(1595,6),(1596,6),(1597,6),(1598,6),(1599,6),(1600,6),(1601,6),(1602,6),(1603,6),(1604,6),(1605,6),(1606,6),(1607,6),(1608,6),(1609,6),(1610,6),(1611,6),(1612,6),(1613,6),(1614,6),(1615,6),(1616,6),(1617,6),(1618,6),(1619,6),(1620,6),(1621,6),(1622,6),(1623,6),(1624,6),(1625,6),(1626,6),(1627,6),(1628,6),(1629,6),(1630,6),(1631,6),(1632,6),(1633,6),(1634,6),(1635,6),(1636,6),(1637,6),(1638,6),(1639,6),(1640,6),(1641,6),(1642,6),(1643,6),(1644,6),(1645,6),(1646,6),(1647,6),(1648,6),(1649,6),(1650,6),(1651,6),(1652,6),(1653,6),(1654,6),(1655,6),(1656,6),(1657,6),(1658,6),(1659,6),(1660,6),(1661,6),(1662,6),(1663,6),(1664,6),(1665,6),(1666,6),(1667,6),(1668,6),(1669,6),(1670,6),(1671,6),(1672,6),(1673,6),(1674,6),(1675,6),(1676,6),(1677,6),(1678,6),(1679,6),(1680,6),(1681,6),(1682,6),(1683,6),(1684,6),(1685,6),(1686,6),(1687,6),(1688,6),(1689,6),(1690,6),(1691,6),(1692,6),(1693,6),(1694,6),(1695,6),(1696,6),(1697,6),(1698,6),(1699,6),(1700,6),(1701,6),(1702,6),(1703,6),(1704,6),(1705,6),(1706,6),(1707,6),(1708,6),(1709,6),(1710,6),(1711,6),(1712,6),(1713,6),(1714,6),(1715,6),(1716,6),(1717,6),(1718,6),(1719,6),(1720,6),(1721,6),(1722,6),(1723,6),(1724,6),(1725,6),(1726,6),(1727,6),(1728,6),(1729,6),(1730,6),(1731,6),(1732,6),(1733,6),(1734,6),(1735,6),(1736,6),(1737,6),(1738,6),(1739,6),(1740,6),(1741,6),(1742,6),(1743,6),(1744,6),(1745,6),(1746,6),(1747,6),(1748,6),(1749,6),(1750,6),(1751,6),(1752,6),(1753,6),(1754,6),(1755,6),(1756,6),(1757,6),(1758,6),(1759,6),(1760,6),(1761,6),(1762,6),(1763,6),(1764,6),(1765,6),(1766,6),(1767,6),(1768,6),(1769,6),(1770,6),(1771,6),(1772,6),(1773,6),(1774,6),(1775,6),(1776,6),(1777,6),(1778,6),(1779,6),(1780,6),(1781,6),(1782,6),(1783,6),(1784,6),(1785,6),(1786,6),(1787,6),(1788,6),(1789,6),(1790,6),(1791,6),(1792,6),(1793,6),(1794,6),(1795,6),(1796,6),(1797,6),(1798,6),(1799,6),(1800,6),(1801,6),(1802,6),(1803,6),(1804,6),(1805,6),(1806,6),(1807,6),(1808,6),(1809,6),(1810,6),(1811,6),(1812,6),(1813,6),(1814,6),(1815,6),(1816,6),(1817,6),(1818,6),(1819,6),(1820,6),(1821,6),(1822,6),(1823,6),(1824,6),(1825,6),(1826,6),(1827,6),(1828,6),(1829,6),(1830,6),(1831,6),(1832,6),(1833,6),(1834,6),(1835,6),(1836,6),(1837,6),(1838,6),(1839,6),(1840,6),(1841,6),(1842,6),(1843,6),(1844,6),(1845,6),(1846,6),(1847,6),(1848,6),(1849,6),(1850,6),(1851,6),(1852,6),(1853,6),(1854,6),(1855,6),(1856,6),(1857,6),(1858,6),(1859,6),(1860,6),(1861,6),(1862,6),(1863,6),(1864,6),(1865,6),(1866,6),(1867,6),(1868,6),(1869,6),(1870,6),(1871,6),(1872,6),(1873,6),(1874,6),(1875,6),(1876,6),(1877,6),(1878,6),(1879,6),(1880,6),(1881,6),(1882,6),(1883,6),(1884,6),(1885,6),(1886,6),(1887,6),(1888,6),(1889,6),(1890,6),(1891,6),(1892,6),(1893,6),(1894,6),(1895,6),(1896,6),(1897,6),(1898,6),(1899,6),(1900,6),(1901,6),(1902,6),(1903,6),(1904,6),(1905,6),(1906,6),(1907,6),(1908,6),(1909,6),(1910,6),(1911,6),(1912,6),(1913,6),(1914,6),(1915,6),(1916,6),(1917,6),(1918,6),(1919,6),(1920,6),(1921,6),(1922,6),(1923,6),(1924,6),(1925,6),(1926,6),(1927,6),(1928,6),(1929,6),(1930,6),(1931,6),(1932,6),(1933,6),(1934,6),(1935,6),(1936,6),(1937,6),(1938,6),(1939,6),(1940,6),(1941,6),(1942,6),(1943,6),(1944,6),(1945,6),(1946,6),(1947,6),(1948,6),(1949,6),(1950,6),(1951,6),(1952,6),(1953,6),(1954,6),(1955,6),(1956,6),(1957,6),(1958,6),(1959,6),(1960,6),(1961,6),(1962,6),(1963,6),(1964,6),(1965,6),(1966,6),(1967,6),(1968,6),(1969,6),(1970,6),(1971,6),(1972,6),(1973,6),(1974,6),(1,7),(2,7),(3,7),(4,7),(5,7),(6,7),(7,7),(8,7),(9,7),(10,7),(11,7),(12,7),(13,7),(14,7),(15,7),(16,7),(17,7),(18,7),(19,7),(20,7),(21,7),(22,7),(23,7),(24,7),(25,7),(26,7),(27,7),(28,7),(29,7),(30,7),(31,7),(32,7),(33,7),(34,7),(35,7),(36,7),(37,7),(38,7),(39,7),(40,7),(41,7),(42,7),(43,7),(44,7),(45,7),(46,7),(47,7),(48,7),(49,7),(50,7),(51,7),(52,7),(53,7),(54,7),(55,7),(56,7),(57,7),(58,7),(59,7),(60,7),(61,7),(62,7),(63,7),(64,7),(65,7),(66,7),(67,7),(68,7),(69,7),(70,7),(71,7),(72,7),(73,7),(74,7),(75,7),(76,7),(77,7),(78,7),(79,7),(80,7),(81,7),(82,7),(83,7),(84,7),(85,7),(86,7),(87,7),(88,7),(89,7),(90,7),(91,7),(92,7),(93,7),(94,7),(95,7),(96,7),(97,7),(98,7),(99,7),(100,7),(101,7),(102,7),(103,7),(104,7),(105,7),(106,7),(107,7),(108,7),(109,7),(110,7),(111,7),(112,7),(113,7),(114,7),(115,7),(116,7),(117,7),(118,7),(119,7),(120,7),(121,7),(122,7),(123,7),(124,7),(125,7),(126,7),(127,7),(128,7),(129,7),(130,7),(131,7),(132,7),(133,7),(134,7),(135,7),(136,7),(137,7),(138,7),(139,7),(140,7),(141,7),(142,7),(143,7),(144,7),(145,7),(146,7),(147,7),(148,7),(149,7),(150,7),(151,7),(152,7),(153,7),(154,7),(155,7),(156,7),(157,7),(158,7),(159,7),(160,7),(161,7),(162,7),(163,7),(164,7),(165,7),(166,7),(167,7),(168,7),(169,7),(170,7),(171,7),(172,7),(173,7),(174,7),(175,7),(176,7),(177,7),(178,7),(179,7),(180,7),(181,7),(182,7),(183,7),(184,7),(185,7),(186,7),(187,7),(188,7),(189,7),(190,7),(191,7),(192,7),(193,7),(194,7),(195,7),(196,7),(197,7),(198,7),(199,7),(200,7),(201,7),(202,7),(203,7),(204,7),(205,7),(206,7),(207,7),(208,7),(209,7),(210,7),(211,7),(212,7),(213,7),(214,7),(215,7),(216,7),(217,7),(218,7),(219,7),(220,7),(221,7),(222,7),(223,7),(224,7),(225,7),(226,7),(227,7),(228,7),(229,7),(230,7),(231,7),(232,7),(233,7),(234,7),(235,7),(236,7),(237,7),(238,7),(239,7),(240,7),(241,7),(242,7),(243,7),(244,7),(245,7),(246,7),(247,7),(248,7),(249,7),(250,7),(251,7),(252,7),(253,7),(254,7),(255,7),(256,7),(257,7),(258,7),(259,7),(260,7),(261,7),(262,7),(263,7),(264,7),(265,7),(266,7),(267,7),(268,7),(269,7),(270,7),(271,7),(272,7),(273,7),(274,7),(275,7),(276,7),(277,7),(278,7),(279,7),(280,7),(281,7),(282,7),(283,7),(284,7),(285,7),(286,7),(287,7),(288,7),(289,7),(290,7),(291,7),(292,7),(293,7),(294,7),(295,7),(296,7),(297,7),(298,7),(299,7),(300,7),(301,7),(302,7),(303,7),(304,7),(305,7),(306,7),(307,7),(308,7),(309,7),(310,7),(311,7),(312,7),(313,7),(314,7),(315,7),(316,7),(317,7),(318,7),(319,7),(320,7),(321,7),(322,7),(323,7),(324,7),(325,7),(326,7),(327,7),(328,7),(329,7),(330,7),(331,7),(332,7),(333,7),(334,7),(335,7),(336,7),(337,7),(338,7),(339,7),(340,7),(341,7),(342,7),(343,7),(344,7),(345,7),(346,7),(347,7),(348,7),(349,7),(350,7),(351,7),(352,7),(353,7),(354,7),(355,7),(356,7),(357,7),(358,7),(359,7),(360,7),(361,7),(362,7),(363,7),(364,7),(365,7),(366,7),(367,7),(368,7),(369,7),(370,7),(371,7),(372,7),(373,7),(374,7),(375,7),(376,7),(377,7),(378,7),(379,7),(380,7),(381,7),(382,7),(383,7),(384,7),(385,7),(386,7),(387,7),(388,7),(389,7),(390,7),(391,7),(392,7),(393,7),(394,7),(395,7),(396,7),(397,7),(398,7),(399,7),(400,7),(401,7),(402,7),(403,7),(404,7),(405,7),(406,7),(407,7),(408,7),(409,7),(410,7),(411,7),(412,7),(413,7),(414,7),(415,7),(416,7),(417,7),(418,7),(419,7),(420,7),(421,7),(422,7),(423,7),(424,7),(425,7),(426,7),(427,7),(428,7),(429,7),(430,7),(431,7),(432,7),(433,7),(434,7),(435,7),(436,7),(437,7),(438,7),(439,7),(440,7),(441,7),(442,7),(443,7),(444,7),(445,7),(446,7),(447,7),(448,7),(449,7),(450,7),(451,7),(452,7),(453,7),(454,7),(455,7),(456,7),(457,7),(458,7),(459,7),(460,7),(461,7),(462,7),(463,7),(464,7),(465,7),(466,7),(467,7),(468,7),(469,7),(470,7),(471,7),(472,7),(473,7),(474,7),(475,7),(476,7),(477,7),(478,7),(479,7),(480,7),(481,7),(482,7),(483,7),(484,7),(485,7),(486,7),(487,7),(488,7),(489,7),(490,7),(491,7),(492,7),(493,7),(494,7),(495,7),(496,7),(497,7),(498,7),(499,7),(500,7),(501,7),(502,7),(503,7),(504,7),(505,7),(506,7),(507,7),(508,7),(509,7),(510,7),(511,7),(512,7),(513,7),(514,7),(515,7),(516,7),(517,7),(518,7),(519,7),(520,7),(521,7),(522,7),(523,7),(524,7),(525,7),(526,7),(527,7),(528,7),(529,7),(530,7),(531,7),(532,7),(533,7),(534,7),(535,7),(536,7),(537,7),(538,7),(539,7),(540,7),(541,7),(542,7),(543,7),(544,7),(545,7),(546,7),(547,7),(548,7),(549,7),(550,7),(551,7),(552,7),(553,7),(554,7),(555,7),(556,7),(557,7),(558,7),(559,7),(560,7),(561,7),(562,7),(563,7),(564,7),(565,7),(566,7),(567,7),(568,7),(569,7),(570,7),(571,7),(572,7),(573,7),(574,7),(575,7),(576,7),(577,7),(578,7),(579,7),(580,7),(581,7),(582,7),(583,7),(584,7),(585,7),(586,7),(587,7),(588,7),(589,7),(590,7),(591,7),(592,7),(593,7),(594,7),(595,7),(596,7),(597,7),(598,7),(599,7),(600,7),(601,7),(602,7),(603,7),(604,7),(605,7),(606,7),(607,7),(608,7),(609,7),(610,7),(611,7),(612,7),(613,7),(614,7),(615,7),(616,7),(617,7),(618,7),(619,7),(620,7),(621,7),(622,7),(623,7),(624,7),(625,7),(626,7),(627,7),(628,7),(629,7),(630,7),(631,7),(632,7),(633,7),(634,7),(635,7),(636,7),(637,7),(638,7),(639,7),(640,7),(641,7),(642,7),(643,7),(644,7),(645,7),(646,7),(647,7),(648,7),(649,7),(650,7),(651,7),(652,7),(653,7),(654,7),(655,7),(656,7),(657,7),(658,7),(659,7),(660,7),(661,7),(662,7),(663,7),(664,7),(665,7),(666,7),(667,7),(668,7),(669,7),(670,7),(671,7),(672,7),(673,7),(674,7),(675,7),(676,7),(677,7),(678,7),(679,7),(680,7),(681,7),(682,7),(683,7),(684,7),(685,7),(686,7),(687,7),(688,7),(689,7),(690,7),(691,7),(692,7),(693,7),(694,7),(695,7),(696,7),(697,7),(698,7),(699,7),(700,7),(701,7),(702,7),(703,7),(704,7),(705,7),(706,7),(707,7),(708,7),(709,7),(710,7),(711,7),(712,7),(713,7),(714,7),(715,7),(716,7),(717,7),(718,7),(719,7),(720,7),(721,7),(722,7),(723,7),(724,7),(725,7),(726,7),(727,7),(728,7),(729,7),(730,7),(731,7),(732,7),(733,7),(734,7),(735,7),(736,7),(737,7),(738,7),(739,7),(740,7),(741,7),(742,7),(743,7),(744,7),(745,7),(746,7),(747,7),(748,7),(749,7),(750,7),(751,7),(752,7),(753,7),(754,7),(755,7),(756,7),(757,7),(758,7),(759,7),(760,7),(761,7),(762,7),(763,7),(764,7),(765,7),(766,7),(767,7),(768,7),(769,7),(770,7),(771,7),(772,7),(773,7),(774,7),(775,7),(776,7),(777,7),(778,7),(779,7),(780,7),(781,7),(782,7),(783,7),(784,7),(785,7),(786,7),(787,7),(788,7),(789,7),(790,7),(791,7),(792,7),(793,7),(794,7),(795,7),(796,7),(797,7),(798,7),(799,7),(800,7),(801,7),(802,7),(803,7),(804,7),(805,7),(806,7),(807,7),(808,7),(809,7),(810,7),(811,7),(812,7),(813,7),(814,7),(815,7),(816,7),(817,7),(818,7),(819,7),(820,7),(821,7),(822,7),(823,7),(824,7),(825,7),(826,7),(827,7),(828,7),(829,7),(830,7),(831,7),(832,7),(833,7),(834,7),(835,7),(836,7),(837,7),(838,7),(839,7),(840,7),(841,7),(842,7),(843,7),(844,7),(845,7),(846,7),(847,7),(848,7),(849,7),(850,7),(851,7),(852,7),(853,7),(854,7),(855,7),(856,7),(857,7),(858,7),(859,7),(860,7),(861,7),(862,7),(863,7),(864,7),(865,7),(866,7),(867,7),(868,7),(869,7),(870,7),(871,7),(872,7),(873,7),(874,7),(875,7),(876,7),(877,7),(878,7),(879,7),(880,7),(881,7),(882,7),(883,7),(884,7),(885,7),(886,7),(887,7),(888,7),(889,7),(890,7),(891,7),(892,7),(893,7),(894,7),(895,7),(896,7),(897,7),(898,7),(899,7),(900,7),(901,7),(902,7),(903,7),(904,7),(905,7),(906,7),(907,7),(908,7),(909,7),(910,7),(911,7),(912,7),(913,7),(914,7),(915,7),(916,7),(917,7),(918,7),(919,7),(920,7),(921,7),(922,7),(923,7),(924,7),(925,7),(926,7),(927,7),(928,7),(929,7),(930,7),(931,7),(932,7),(933,7),(934,7),(935,7),(936,7),(937,7),(938,7),(939,7),(940,7),(941,7),(942,7),(943,7),(944,7),(945,7),(946,7),(947,7),(948,7),(949,7),(950,7),(951,7),(952,7),(953,7),(954,7),(955,7),(956,7),(957,7),(958,7),(959,7),(960,7),(961,7),(962,7),(963,7),(964,7),(965,7),(966,7),(967,7),(968,7),(969,7),(970,7),(971,7),(972,7),(973,7),(974,7),(975,7),(976,7),(977,7),(978,7),(979,7),(980,7),(981,7),(982,7),(983,7),(984,7),(985,7),(986,7),(987,7),(988,7),(989,7),(990,7),(991,7),(992,7),(993,7),(994,7),(995,7),(996,7),(997,7),(998,7),(999,7),(1000,7),(1001,7),(1002,7),(1003,7),(1004,7),(1005,7),(1006,7),(1007,7),(1008,7),(1009,7),(1010,7),(1011,7),(1012,7),(1013,7),(1014,7),(1015,7),(1016,7),(1017,7),(1018,7),(1019,7),(1020,7),(1021,7),(1022,7),(1023,7),(1024,7),(1025,7),(1026,7),(1027,7),(1028,7),(1029,7),(1030,7),(1031,7),(1032,7),(1033,7),(1034,7),(1035,7),(1036,7),(1037,7),(1038,7),(1039,7),(1040,7),(1041,7),(1042,7),(1043,7),(1044,7),(1045,7),(1046,7),(1047,7),(1048,7),(1049,7),(1050,7),(1051,7),(1052,7),(1053,7),(1054,7),(1055,7),(1056,7),(1057,7),(1058,7),(1059,7),(1060,7),(1061,7),(1062,7),(1063,7),(1064,7),(1065,7),(1066,7),(1067,7),(1068,7),(1069,7),(1070,7),(1071,7),(1072,7),(1073,7),(1074,7),(1075,7),(1076,7),(1077,7),(1078,7),(1079,7),(1080,7),(1081,7),(1082,7),(1083,7),(1084,7),(1085,7),(1086,7),(1087,7),(1088,7),(1089,7),(1090,7),(1091,7),(1092,7),(1093,7),(1094,7),(1095,7),(1096,7),(1097,7),(1098,7),(1099,7),(1100,7),(1101,7),(1102,7),(1103,7),(1104,7),(1105,7),(1106,7),(1107,7),(1108,7),(1109,7),(1110,7),(1111,7),(1112,7),(1113,7),(1114,7),(1115,7),(1116,7),(1117,7),(1118,7),(1119,7),(1120,7),(1121,7),(1122,7),(1123,7),(1124,7),(1125,7),(1126,7),(1127,7),(1128,7),(1129,7),(1130,7),(1131,7),(1132,7),(1133,7),(1134,7),(1135,7),(1136,7),(1137,7),(1138,7),(1139,7),(1140,7),(1141,7),(1142,7),(1143,7),(1144,7),(1145,7),(1146,7),(1147,7),(1148,7),(1149,7),(1150,7),(1151,7),(1152,7),(1153,7),(1154,7),(1155,7),(1156,7),(1157,7),(1158,7),(1159,7),(1160,7),(1161,7),(1162,7),(1163,7),(1164,7),(1165,7),(1166,7),(1167,7),(1168,7),(1169,7),(1170,7),(1171,7),(1172,7),(1173,7),(1174,7),(1175,7),(1176,7),(1177,7),(1178,7),(1179,7),(1180,7),(1181,7),(1182,7),(1183,7),(1184,7),(1185,7),(1186,7),(1187,7),(1188,7),(1189,7),(1190,7),(1191,7),(1192,7),(1193,7),(1194,7),(1195,7),(1196,7),(1197,7),(1198,7),(1199,7),(1200,7),(1201,7),(1202,7),(1203,7),(1204,7),(1205,7),(1206,7),(1207,7),(1208,7),(1209,7),(1210,7),(1211,7),(1212,7),(1213,7),(1214,7),(1215,7),(1216,7),(1217,7),(1218,7),(1219,7),(1220,7),(1221,7),(1222,7),(1223,7),(1224,7),(1225,7),(1226,7),(1227,7),(1228,7),(1229,7),(1230,7),(1231,7),(1232,7),(1233,7),(1234,7),(1235,7),(1236,7),(1237,7),(1238,7),(1239,7),(1240,7),(1241,7),(1242,7),(1243,7),(1244,7),(1245,7),(1246,7),(1247,7),(1248,7),(1249,7),(1250,7),(1251,7),(1252,7),(1253,7),(1254,7),(1255,7),(1256,7),(1257,7),(1258,7),(1259,7),(1260,7),(1261,7),(1262,7),(1263,7),(1264,7),(1265,7),(1266,7),(1267,7),(1268,7),(1269,7),(1270,7),(1271,7),(1272,7),(1273,7),(1274,7),(1275,7),(1276,7),(1277,7),(1278,7),(1279,7),(1280,7),(1281,7),(1282,7),(1283,7),(1284,7),(1285,7),(1286,7),(1287,7),(1288,7),(1289,7),(1290,7),(1291,7),(1292,7),(1293,7),(1294,7),(1295,7),(1296,7),(1297,7),(1298,7),(1299,7),(1300,7),(1301,7),(1302,7),(1303,7),(1304,7),(1305,7),(1306,7),(1307,7),(1308,7),(1309,7),(1310,7),(1311,7),(1312,7),(1313,7),(1314,7),(1315,7),(1316,7),(1317,7),(1318,7),(1319,7),(1320,7),(1321,7),(1322,7),(1323,7),(1324,7),(1325,7),(1326,7),(1327,7),(1328,7),(1329,7),(1330,7),(1331,7),(1332,7),(1333,7),(1334,7),(1335,7),(1336,7),(1337,7),(1338,7),(1339,7),(1340,7),(1341,7),(1342,7),(1343,7),(1344,7),(1345,7),(1346,7),(1347,7),(1348,7),(1349,7),(1350,7),(1351,7),(1352,7),(1353,7),(1354,7),(1355,7),(1356,7),(1357,7),(1358,7),(1359,7),(1360,7),(1361,7),(1362,7),(1363,7),(1364,7),(1365,7),(1366,7),(1367,7),(1368,7),(1369,7),(1370,7),(1371,7),(1372,7),(1373,7),(1374,7),(1375,7),(1376,7),(1377,7),(1378,7),(1379,7),(1380,7),(1381,7),(1382,7),(1383,7),(1384,7),(1385,7),(1386,7),(1387,7),(1388,7),(1389,7),(1390,7),(1391,7),(1392,7),(1393,7),(1394,7),(1395,7),(1396,7),(1397,7),(1398,7),(1399,7),(1400,7),(1401,7),(1402,7),(1403,7),(1404,7),(1405,7),(1406,7),(1407,7),(1408,7),(1409,7),(1410,7),(1411,7),(1412,7),(1413,7),(1414,7),(1415,7),(1416,7),(1417,7),(1418,7),(1419,7),(1420,7),(1421,7),(1422,7),(1423,7),(1424,7),(1425,7),(1426,7),(1427,7),(1428,7),(1429,7),(1430,7),(1431,7),(1432,7),(1433,7),(1434,7),(1435,7),(1436,7),(1437,7),(1438,7),(1439,7),(1440,7),(1441,7),(1442,7),(1443,7),(1444,7),(1445,7),(1446,7),(1447,7),(1448,7),(1449,7),(1450,7),(1451,7),(1452,7),(1453,7),(1454,7),(1455,7),(1456,7),(1457,7),(1458,7),(1459,7),(1460,7),(1461,7),(1462,7),(1463,7),(1464,7),(1465,7),(1466,7),(1467,7),(1468,7),(1469,7),(1470,7),(1471,7),(1472,7),(1473,7),(1474,7),(1475,7),(1476,7),(1477,7),(1478,7),(1479,7),(1480,7),(1481,7),(1482,7),(1483,7),(1484,7),(1485,7),(1486,7),(1487,7),(1488,7),(1489,7),(1490,7),(1491,7),(1492,7),(1493,7),(1494,7),(1495,7),(1496,7),(1497,7),(1498,7),(1499,7),(1500,7),(1501,7),(1502,7),(1503,7),(1504,7),(1505,7),(1506,7),(1507,7),(1508,7),(1509,7),(1510,7),(1511,7),(1512,7),(1513,7),(1514,7),(1515,7),(1516,7),(1517,7),(1518,7),(1519,7),(1520,7),(1521,7),(1522,7),(1523,7),(1524,7),(1525,7),(1526,7),(1527,7),(1528,7),(1529,7),(1530,7),(1531,7),(1532,7),(1533,7),(1534,7),(1535,7),(1536,7),(1537,7),(1538,7),(1539,7),(1540,7),(1541,7),(1542,7),(1543,7),(1544,7),(1545,7),(1546,7),(1547,7),(1548,7),(1549,7),(1550,7),(1551,7),(1552,7),(1553,7),(1554,7),(1555,7),(1556,7),(1557,7),(1558,7),(1559,7),(1560,7),(1561,7),(1562,7),(1563,7),(1564,7),(1565,7),(1566,7),(1567,7),(1568,7),(1569,7),(1570,7),(1571,7),(1572,7),(1573,7),(1574,7),(1575,7),(1576,7),(1577,7),(1578,7),(1579,7),(1580,7),(1581,7),(1582,7),(1583,7),(1584,7),(1585,7),(1586,7),(1587,7),(1588,7),(1589,7),(1590,7),(1591,7),(1592,7),(1593,7),(1594,7),(1595,7),(1596,7),(1597,7),(1598,7),(1599,7),(1600,7),(1601,7),(1602,7),(1603,7),(1604,7),(1605,7),(1606,7),(1607,7),(1608,7),(1609,7),(1610,7),(1611,7),(1612,7),(1613,7),(1614,7),(1615,7),(1616,7),(1617,7),(1618,7),(1619,7),(1620,7),(1621,7),(1622,7),(1623,7),(1624,7),(1625,7),(1626,7),(1627,7),(1628,7),(1629,7),(1630,7),(1631,7),(1632,7),(1633,7),(1634,7),(1635,7),(1636,7),(1637,7),(1638,7),(1639,7),(1640,7),(1641,7),(1642,7),(1643,7),(1644,7),(1645,7),(1646,7),(1647,7),(1648,7),(1649,7),(1650,7),(1651,7),(1652,7),(1653,7),(1654,7),(1655,7),(1656,7),(1657,7),(1658,7),(1659,7),(1660,7),(1661,7),(1662,7),(1663,7),(1664,7),(1665,7),(1666,7),(1667,7),(1668,7),(1669,7),(1670,7),(1671,7),(1672,7),(1673,7),(1674,7),(1675,7),(1676,7),(1677,7),(1678,7),(1679,7),(1680,7),(1681,7),(1682,7),(1683,7),(1684,7),(1685,7),(1686,7),(1687,7),(1688,7),(1689,7),(1690,7),(1691,7),(1692,7),(1693,7),(1694,7),(1695,7),(1696,7),(1697,7),(1698,7),(1699,7),(1700,7),(1701,7),(1702,7),(1703,7),(1704,7),(1705,7),(1706,7),(1707,7),(1708,7),(1709,7),(1710,7),(1711,7),(1712,7),(1713,7),(1714,7),(1715,7),(1716,7),(1717,7),(1718,7),(1719,7),(1720,7),(1721,7),(1722,7),(1723,7),(1724,7),(1725,7),(1726,7),(1727,7),(1728,7),(1729,7),(1730,7),(1731,7),(1732,7),(1733,7),(1734,7),(1735,7),(1736,7),(1737,7),(1738,7),(1739,7),(1740,7),(1741,7),(1742,7),(1743,7),(1744,7),(1745,7),(1746,7),(1747,7),(1748,7),(1749,7),(1750,7),(1751,7),(1752,7),(1753,7),(1754,7),(1755,7),(1756,7),(1757,7),(1758,7),(1759,7),(1760,7),(1761,7),(1762,7),(1763,7),(1764,7),(1765,7),(1766,7),(1767,7),(1768,7),(1769,7),(1770,7),(1771,7),(1772,7),(1773,7),(1774,7),(1775,7),(1776,7),(1777,7),(1778,7),(1779,7),(1780,7),(1781,7),(1782,7),(1783,7),(1784,7),(1785,7),(1786,7),(1787,7),(1788,7),(1789,7),(1790,7),(1791,7),(1792,7),(1793,7),(1794,7),(1795,7),(1796,7),(1797,7),(1798,7),(1799,7),(1800,7),(1801,7),(1802,7),(1803,7),(1804,7),(1805,7),(1806,7),(1807,7),(1808,7),(1809,7),(1810,7),(1811,7),(1812,7),(1813,7),(1814,7),(1815,7),(1816,7),(1817,7),(1818,7),(1819,7),(1820,7),(1821,7),(1822,7),(1823,7),(1824,7),(1825,7),(1826,7),(1827,7),(1828,7),(1829,7),(1830,7),(1831,7),(1832,7),(1833,7),(1834,7),(1835,7),(1836,7),(1837,7),(1838,7),(1839,7),(1840,7),(1841,7),(1842,7),(1843,7),(1844,7),(1845,7),(1846,7),(1847,7),(1848,7),(1849,7),(1850,7),(1851,7),(1852,7),(1853,7),(1854,7),(1855,7),(1856,7),(1857,7),(1858,7),(1859,7),(1860,7),(1861,7),(1862,7),(1863,7),(1864,7),(1865,7),(1866,7),(1867,7),(1868,7),(1869,7),(1870,7),(1871,7),(1872,7),(1873,7),(1874,7),(1875,7),(1876,7),(1877,7),(1878,7),(1879,7),(1880,7),(1881,7),(1882,7),(1883,7),(1884,7),(1885,7),(1886,7),(1887,7),(1888,7),(1889,7),(1890,7),(1891,7),(1892,7),(1893,7),(1894,7),(1895,7),(1896,7),(1897,7),(1898,7),(1899,7),(1900,7),(1901,7),(1902,7),(1903,7),(1904,7),(1905,7),(1906,7),(1907,7),(1908,7),(1909,7),(1910,7),(1911,7),(1912,7),(1913,7),(1914,7),(1915,7),(1916,7),(1917,7),(1918,7),(1919,7),(1920,7),(1921,7),(1922,7),(1923,7),(1924,7),(1925,7),(1926,7),(1927,7),(1928,7),(1929,7),(1930,7),(1931,7),(1932,7),(1933,7),(1934,7),(1935,7),(1936,7),(1937,7),(1938,7),(1939,7),(1940,7),(1941,7),(1942,7),(1943,7),(1944,7),(1945,7),(1946,7),(1947,7),(1948,7),(1949,7),(1950,7),(1951,7),(1952,7),(1953,7),(1954,7),(1955,7),(1956,7),(1957,7),(1958,7),(1959,7),(1960,7),(1961,7),(1962,7),(1963,7),(1964,7),(1965,7),(1966,7),(1967,7),(1968,7),(1969,7),(1970,7),(1971,7),(1972,7),(1973,7),(1974,7),(1,8),(2,8),(3,8),(4,8),(5,8),(6,8),(7,8),(8,8),(9,8),(10,8),(11,8),(12,8),(13,8),(14,8),(15,8),(16,8),(17,8),(18,8),(19,8),(20,8),(21,8),(22,8),(23,8),(24,8),(25,8),(26,8),(27,8),(28,8),(29,8),(30,8),(31,8),(32,8),(33,8),(34,8),(35,8),(36,8),(37,8),(38,8),(39,8),(40,8),(41,8),(42,8),(43,8),(44,8),(45,8),(46,8),(47,8),(48,8),(49,8),(50,8),(51,8),(52,8),(53,8),(54,8),(55,8),(56,8),(57,8),(58,8),(59,8),(60,8),(61,8),(62,8),(63,8),(64,8),(65,8),(66,8),(67,8),(68,8),(69,8),(70,8),(71,8),(72,8),(73,8),(74,8),(75,8),(76,8),(77,8),(78,8),(79,8),(80,8),(81,8),(82,8),(83,8),(84,8),(85,8),(86,8),(87,8),(88,8),(89,8),(90,8),(91,8),(92,8),(93,8),(94,8),(95,8),(96,8),(97,8),(98,8),(99,8),(100,8),(101,8),(102,8),(103,8),(104,8),(105,8),(106,8),(107,8),(108,8),(109,8),(110,8),(111,8),(112,8),(113,8),(114,8),(115,8),(116,8),(117,8),(118,8),(119,8),(120,8),(121,8),(122,8),(123,8),(124,8),(125,8),(126,8),(127,8),(128,8),(129,8),(130,8),(131,8),(132,8),(133,8),(134,8),(135,8),(136,8),(137,8),(138,8),(139,8),(140,8),(141,8),(142,8),(143,8),(144,8),(145,8),(146,8),(147,8),(148,8),(149,8),(150,8),(151,8),(152,8),(153,8),(154,8),(155,8),(156,8),(157,8),(158,8),(159,8),(160,8),(161,8),(162,8),(163,8),(164,8),(165,8),(166,8),(167,8),(168,8),(169,8),(170,8),(171,8),(172,8),(173,8),(174,8),(175,8),(176,8),(177,8),(178,8),(179,8),(180,8),(181,8),(182,8),(183,8),(184,8),(185,8),(186,8),(187,8),(188,8),(189,8),(190,8),(191,8),(192,8),(193,8),(194,8),(195,8),(196,8),(197,8),(198,8),(199,8),(200,8),(201,8),(202,8),(203,8),(204,8),(205,8),(206,8),(207,8),(208,8),(209,8),(210,8),(211,8),(212,8),(213,8),(214,8),(215,8),(216,8),(217,8),(218,8),(219,8),(220,8),(221,8),(222,8),(223,8),(224,8),(225,8),(226,8),(227,8),(228,8),(229,8),(230,8),(231,8),(232,8),(233,8),(234,8),(235,8),(236,8),(237,8),(238,8),(239,8),(240,8),(241,8),(242,8),(243,8),(244,8),(245,8),(246,8),(247,8),(248,8),(249,8),(250,8),(251,8),(252,8),(253,8),(254,8),(255,8),(256,8),(257,8),(258,8),(259,8),(260,8),(261,8),(262,8),(263,8),(264,8),(265,8),(266,8),(267,8),(268,8),(269,8),(270,8),(271,8),(272,8),(273,8),(274,8),(275,8),(276,8),(277,8),(278,8),(279,8),(280,8),(281,8),(282,8),(283,8),(284,8),(285,8),(286,8),(287,8),(288,8),(289,8),(290,8),(291,8),(292,8),(293,8),(294,8),(295,8),(296,8),(297,8),(298,8),(299,8),(300,8),(301,8),(302,8),(303,8),(304,8),(305,8),(306,8),(307,8),(308,8),(309,8),(310,8),(311,8),(312,8),(313,8),(314,8),(315,8),(316,8),(317,8),(318,8),(319,8),(320,8),(321,8),(322,8),(323,8),(324,8),(325,8),(326,8),(327,8),(328,8),(329,8),(330,8),(331,8),(332,8),(333,8),(334,8),(335,8),(336,8),(337,8),(338,8),(339,8),(340,8),(341,8),(342,8),(343,8),(344,8),(345,8),(346,8),(347,8),(348,8),(349,8),(350,8),(351,8),(352,8),(353,8),(354,8),(355,8),(356,8),(357,8),(358,8),(359,8),(360,8),(361,8),(362,8),(363,8),(364,8),(365,8),(366,8),(367,8),(368,8),(369,8),(370,8),(371,8),(372,8),(373,8),(374,8),(375,8),(376,8),(377,8),(378,8),(379,8),(380,8),(381,8),(382,8),(383,8),(384,8),(385,8),(386,8),(387,8),(388,8),(389,8),(390,8),(391,8),(392,8),(393,8),(394,8),(395,8),(396,8),(397,8),(398,8),(399,8),(400,8),(401,8),(402,8),(403,8),(404,8),(405,8),(406,8),(407,8),(408,8),(409,8),(410,8),(411,8),(412,8),(413,8),(414,8),(415,8),(416,8),(417,8),(418,8),(419,8),(420,8),(421,8),(422,8),(423,8),(424,8),(425,8),(426,8),(427,8),(428,8),(429,8),(430,8),(431,8),(432,8),(433,8),(434,8),(435,8),(436,8),(437,8),(438,8),(439,8),(440,8),(441,8),(442,8),(443,8),(444,8),(445,8),(446,8),(447,8),(448,8),(449,8),(450,8),(451,8),(452,8),(453,8),(454,8),(455,8),(456,8),(457,8),(458,8),(459,8),(460,8),(461,8),(462,8),(463,8),(464,8),(465,8),(466,8),(467,8),(468,8),(469,8),(470,8),(471,8),(472,8),(473,8),(474,8),(475,8),(476,8),(477,8),(478,8),(479,8),(480,8),(481,8),(482,8),(483,8),(484,8),(485,8),(486,8),(487,8),(488,8),(489,8),(490,8),(491,8),(492,8),(493,8),(494,8),(495,8),(496,8),(497,8),(498,8),(499,8),(500,8),(501,8),(502,8),(503,8),(504,8),(505,8),(506,8),(507,8),(508,8),(509,8),(510,8),(511,8),(512,8),(513,8),(514,8),(515,8),(516,8),(517,8),(518,8),(519,8),(520,8),(521,8),(522,8),(523,8),(524,8),(525,8),(526,8),(527,8),(528,8),(529,8),(530,8),(531,8),(532,8),(533,8),(534,8),(535,8),(536,8),(537,8),(538,8),(539,8),(540,8),(541,8),(542,8),(543,8),(544,8),(545,8),(546,8),(547,8),(548,8),(549,8),(550,8),(551,8),(552,8),(553,8),(554,8),(555,8),(556,8),(557,8),(558,8),(559,8),(560,8),(561,8),(562,8),(563,8),(564,8),(565,8),(566,8),(567,8),(568,8),(569,8),(570,8),(571,8),(572,8),(573,8),(574,8),(575,8),(576,8),(577,8),(578,8),(579,8),(580,8),(581,8),(582,8),(583,8),(584,8),(585,8),(586,8),(587,8),(588,8),(589,8),(590,8),(591,8),(592,8),(593,8),(594,8),(595,8),(596,8),(597,8),(598,8),(599,8),(600,8),(601,8),(602,8),(603,8),(604,8),(605,8),(606,8),(607,8),(608,8),(609,8),(610,8),(611,8),(612,8),(613,8),(614,8),(615,8),(616,8),(617,8),(618,8),(619,8),(620,8),(621,8),(622,8),(623,8),(624,8),(625,8),(626,8),(627,8),(628,8),(629,8),(630,8),(631,8),(632,8),(633,8),(634,8),(635,8),(636,8),(637,8),(638,8),(639,8),(640,8),(641,8),(642,8),(643,8),(644,8),(645,8),(646,8),(647,8),(648,8),(649,8),(650,8),(651,8),(652,8),(653,8),(654,8),(655,8),(656,8),(657,8),(658,8),(659,8),(660,8),(661,8),(662,8),(663,8),(664,8),(665,8),(666,8),(667,8),(668,8),(669,8),(670,8),(671,8),(672,8),(673,8),(674,8),(675,8),(676,8),(677,8),(678,8),(679,8),(680,8),(681,8),(682,8),(683,8),(684,8),(685,8),(686,8),(687,8),(688,8),(689,8),(690,8),(691,8),(692,8),(693,8),(694,8),(695,8),(696,8),(697,8),(698,8),(699,8),(700,8),(701,8),(702,8),(703,8),(704,8),(705,8),(706,8),(707,8),(708,8),(709,8),(710,8),(711,8),(712,8),(713,8),(714,8),(715,8),(716,8),(717,8),(718,8),(719,8),(720,8),(721,8),(722,8),(723,8),(724,8),(725,8),(726,8),(727,8),(728,8),(729,8),(730,8),(731,8),(732,8),(733,8),(734,8),(735,8),(736,8),(737,8),(738,8),(739,8),(740,8),(741,8),(742,8),(743,8),(744,8),(745,8),(746,8),(747,8),(748,8),(749,8),(750,8),(751,8),(752,8),(753,8),(754,8),(755,8),(756,8),(757,8),(758,8),(759,8),(760,8),(761,8),(762,8),(763,8),(764,8),(765,8),(766,8),(767,8),(768,8),(769,8),(770,8),(771,8),(772,8),(773,8),(774,8),(775,8),(776,8),(777,8),(778,8),(779,8),(780,8),(781,8),(782,8),(783,8),(784,8),(785,8),(786,8),(787,8),(788,8),(789,8),(790,8),(791,8),(792,8),(793,8),(794,8),(795,8),(796,8),(797,8),(798,8),(799,8),(800,8),(801,8),(802,8),(803,8),(804,8),(805,8),(806,8),(807,8),(808,8),(809,8),(810,8),(811,8),(812,8),(813,8),(814,8),(815,8),(816,8),(817,8),(818,8),(819,8),(820,8),(821,8),(822,8),(823,8),(824,8),(825,8),(826,8),(827,8),(828,8),(829,8),(830,8),(831,8),(832,8),(833,8),(834,8),(835,8),(836,8),(837,8),(838,8),(839,8),(840,8),(841,8),(842,8),(843,8),(844,8),(845,8),(846,8),(847,8),(848,8),(849,8),(850,8),(851,8),(852,8),(853,8),(854,8),(855,8),(856,8),(857,8),(858,8),(859,8),(860,8),(861,8),(862,8),(863,8),(864,8),(865,8),(866,8),(867,8),(868,8),(869,8),(870,8),(871,8),(872,8),(873,8),(874,8),(875,8),(876,8),(877,8),(878,8),(879,8),(880,8),(881,8),(882,8),(883,8),(884,8),(885,8),(886,8),(887,8),(888,8),(889,8),(890,8),(891,8),(892,8),(893,8),(894,8),(895,8),(896,8),(897,8),(898,8),(899,8),(900,8),(901,8),(902,8),(903,8),(904,8),(905,8),(906,8),(907,8),(908,8),(909,8),(910,8),(911,8),(912,8),(913,8),(914,8),(915,8),(916,8),(917,8),(918,8),(919,8),(920,8),(921,8),(922,8),(923,8),(924,8),(925,8),(926,8),(927,8),(928,8),(929,8),(930,8),(931,8),(932,8),(933,8),(934,8),(935,8),(936,8),(937,8),(938,8),(939,8),(940,8),(941,8),(942,8),(943,8),(944,8),(945,8),(946,8),(947,8),(948,8),(949,8),(950,8),(951,8),(952,8),(953,8),(954,8),(955,8),(956,8),(957,8),(958,8),(959,8),(960,8),(961,8),(962,8),(963,8),(964,8),(965,8),(966,8),(967,8),(968,8),(969,8),(970,8),(971,8),(972,8),(973,8),(974,8),(975,8),(976,8),(977,8),(978,8),(979,8),(980,8),(981,8),(982,8),(983,8),(984,8),(985,8),(986,8),(987,8),(988,8),(989,8),(990,8),(991,8),(992,8),(993,8),(994,8),(995,8),(996,8),(997,8),(998,8),(999,8),(1000,8),(1001,8),(1002,8),(1003,8),(1004,8),(1005,8),(1006,8),(1007,8),(1008,8),(1009,8),(1010,8),(1011,8),(1012,8),(1013,8),(1014,8),(1015,8),(1016,8),(1017,8),(1018,8),(1019,8),(1020,8),(1021,8),(1022,8),(1023,8),(1024,8),(1025,8),(1026,8),(1027,8),(1028,8),(1029,8),(1030,8),(1031,8),(1032,8),(1033,8),(1034,8),(1035,8),(1036,8),(1037,8),(1038,8),(1039,8),(1040,8),(1041,8),(1042,8),(1043,8),(1044,8),(1045,8),(1046,8),(1047,8),(1048,8),(1049,8),(1050,8),(1051,8),(1052,8),(1053,8),(1054,8),(1055,8),(1056,8),(1057,8),(1058,8),(1059,8),(1060,8),(1061,8),(1062,8),(1063,8),(1064,8),(1065,8),(1066,8),(1067,8),(1068,8),(1069,8),(1070,8),(1071,8),(1072,8),(1073,8),(1074,8),(1075,8),(1076,8),(1077,8),(1078,8),(1079,8),(1080,8),(1081,8),(1082,8),(1083,8),(1084,8),(1085,8),(1086,8),(1087,8),(1088,8),(1089,8),(1090,8),(1091,8),(1092,8),(1093,8),(1094,8),(1095,8),(1096,8),(1097,8),(1098,8),(1099,8),(1100,8),(1101,8),(1102,8),(1103,8),(1104,8),(1105,8),(1106,8),(1107,8),(1108,8),(1109,8),(1110,8),(1111,8),(1112,8),(1113,8),(1114,8),(1115,8),(1116,8),(1117,8),(1118,8),(1119,8),(1120,8),(1121,8),(1122,8),(1123,8),(1124,8),(1125,8),(1126,8),(1127,8),(1128,8),(1129,8),(1130,8),(1131,8),(1132,8),(1133,8),(1134,8),(1135,8),(1136,8),(1137,8),(1138,8),(1139,8),(1140,8),(1141,8),(1142,8),(1143,8),(1144,8),(1145,8),(1146,8),(1147,8),(1148,8),(1149,8),(1150,8),(1151,8),(1152,8),(1153,8),(1154,8),(1155,8),(1156,8),(1157,8),(1158,8),(1159,8),(1160,8),(1161,8),(1162,8),(1163,8),(1164,8),(1165,8),(1166,8),(1167,8),(1168,8),(1169,8),(1170,8),(1171,8),(1172,8),(1173,8),(1174,8),(1175,8),(1176,8),(1177,8),(1178,8),(1179,8),(1180,8),(1181,8),(1182,8),(1183,8),(1184,8),(1185,8),(1186,8),(1187,8),(1188,8),(1189,8),(1190,8),(1191,8),(1192,8),(1193,8),(1194,8),(1195,8),(1196,8),(1197,8),(1198,8),(1199,8),(1200,8),(1201,8),(1202,8),(1203,8),(1204,8),(1205,8),(1206,8),(1207,8),(1208,8),(1209,8),(1210,8),(1211,8),(1212,8),(1213,8),(1214,8),(1215,8),(1216,8),(1217,8),(1218,8),(1219,8),(1220,8),(1221,8),(1222,8),(1223,8),(1224,8),(1225,8),(1226,8),(1227,8),(1228,8),(1229,8),(1230,8),(1231,8),(1232,8),(1233,8),(1234,8),(1235,8),(1236,8),(1237,8),(1238,8),(1239,8),(1240,8),(1241,8),(1242,8),(1243,8),(1244,8),(1245,8),(1246,8),(1247,8),(1248,8),(1249,8),(1250,8),(1251,8),(1252,8),(1253,8),(1254,8),(1255,8),(1256,8),(1257,8),(1258,8),(1259,8),(1260,8),(1261,8),(1262,8),(1263,8),(1264,8),(1265,8),(1266,8),(1267,8),(1268,8),(1269,8),(1270,8),(1271,8),(1272,8),(1273,8),(1274,8),(1275,8),(1276,8),(1277,8),(1278,8),(1279,8),(1280,8),(1281,8),(1282,8),(1283,8),(1284,8),(1285,8),(1286,8),(1287,8),(1288,8),(1289,8),(1290,8),(1291,8),(1292,8),(1293,8),(1294,8),(1295,8),(1296,8),(1297,8),(1298,8),(1299,8),(1300,8),(1301,8),(1302,8),(1303,8),(1304,8),(1305,8),(1306,8),(1307,8),(1308,8),(1309,8),(1310,8),(1311,8),(1312,8),(1313,8),(1314,8),(1315,8),(1316,8),(1317,8),(1318,8),(1319,8),(1320,8),(1321,8),(1322,8),(1323,8),(1324,8),(1325,8),(1326,8),(1327,8),(1328,8),(1329,8),(1330,8),(1331,8),(1332,8),(1333,8),(1334,8),(1335,8),(1336,8),(1337,8),(1338,8),(1339,8),(1340,8),(1341,8),(1342,8),(1343,8),(1344,8),(1345,8),(1346,8),(1347,8),(1348,8),(1349,8),(1350,8),(1351,8),(1352,8),(1353,8),(1354,8),(1355,8),(1356,8),(1357,8),(1358,8),(1359,8),(1360,8),(1361,8),(1362,8),(1363,8),(1364,8),(1365,8),(1366,8),(1367,8),(1368,8),(1369,8),(1370,8),(1371,8),(1372,8),(1373,8),(1374,8),(1375,8),(1376,8),(1377,8),(1378,8),(1379,8),(1380,8),(1381,8),(1382,8),(1383,8),(1384,8),(1385,8),(1386,8),(1387,8),(1388,8),(1389,8),(1390,8),(1391,8),(1392,8),(1393,8),(1394,8),(1395,8),(1396,8),(1397,8),(1398,8),(1399,8),(1400,8),(1401,8),(1402,8),(1403,8),(1404,8),(1405,8),(1406,8),(1407,8),(1408,8),(1409,8),(1410,8),(1411,8),(1412,8),(1413,8),(1414,8),(1415,8),(1416,8),(1417,8),(1418,8),(1419,8),(1420,8),(1421,8),(1422,8),(1423,8),(1424,8),(1425,8),(1426,8),(1427,8),(1428,8),(1429,8),(1430,8),(1431,8),(1432,8),(1433,8),(1434,8),(1435,8),(1436,8),(1437,8),(1438,8),(1439,8),(1440,8),(1441,8),(1442,8),(1443,8),(1444,8),(1445,8),(1446,8),(1447,8),(1448,8),(1449,8),(1450,8),(1451,8),(1452,8),(1453,8),(1454,8),(1455,8),(1456,8),(1457,8),(1458,8),(1459,8),(1460,8),(1461,8),(1462,8),(1463,8),(1464,8),(1465,8),(1466,8),(1467,8),(1468,8),(1469,8),(1470,8),(1471,8),(1472,8),(1473,8),(1474,8),(1475,8),(1476,8),(1477,8),(1478,8),(1479,8),(1480,8),(1481,8),(1482,8),(1483,8),(1484,8),(1485,8),(1486,8),(1487,8),(1488,8),(1489,8),(1490,8),(1491,8),(1492,8),(1493,8),(1494,8),(1495,8),(1496,8),(1497,8),(1498,8),(1499,8),(1500,8),(1501,8),(1502,8),(1503,8),(1504,8),(1505,8),(1506,8),(1507,8),(1508,8),(1509,8),(1510,8),(1511,8),(1512,8),(1513,8),(1514,8),(1515,8),(1516,8),(1517,8),(1518,8),(1519,8),(1520,8),(1521,8),(1522,8),(1523,8),(1524,8),(1525,8),(1526,8),(1527,8),(1528,8),(1529,8),(1530,8),(1531,8),(1532,8),(1533,8),(1534,8),(1535,8),(1536,8),(1537,8),(1538,8),(1539,8),(1540,8),(1541,8),(1542,8),(1543,8),(1544,8),(1545,8),(1546,8),(1547,8),(1548,8),(1549,8),(1550,8),(1551,8),(1552,8),(1553,8),(1554,8),(1555,8),(1556,8),(1557,8),(1558,8),(1559,8),(1560,8),(1561,8),(1562,8),(1563,8),(1564,8),(1565,8),(1566,8),(1567,8),(1568,8),(1569,8),(1570,8),(1571,8),(1572,8),(1573,8),(1574,8),(1575,8),(1576,8),(1577,8),(1578,8),(1579,8),(1580,8),(1581,8),(1582,8),(1583,8),(1584,8),(1585,8),(1586,8),(1587,8),(1588,8),(1589,8),(1590,8),(1591,8),(1592,8),(1593,8),(1594,8),(1595,8),(1596,8),(1597,8),(1598,8),(1599,8),(1600,8),(1601,8),(1602,8),(1603,8),(1604,8),(1605,8),(1606,8),(1607,8),(1608,8),(1609,8),(1610,8),(1611,8),(1612,8),(1613,8),(1614,8),(1615,8),(1616,8),(1617,8),(1618,8),(1619,8),(1620,8),(1621,8),(1622,8),(1623,8),(1624,8),(1625,8),(1626,8),(1627,8),(1628,8),(1629,8),(1630,8),(1631,8),(1632,8),(1633,8),(1634,8),(1635,8),(1636,8),(1637,8),(1638,8),(1639,8),(1640,8),(1641,8),(1642,8),(1643,8),(1644,8),(1645,8),(1646,8),(1647,8),(1648,8),(1649,8),(1650,8),(1651,8),(1652,8),(1653,8),(1654,8),(1655,8),(1656,8),(1657,8),(1658,8),(1659,8),(1660,8),(1661,8),(1662,8),(1663,8),(1664,8),(1665,8),(1666,8),(1667,8),(1668,8),(1669,8),(1670,8),(1671,8),(1672,8),(1673,8),(1674,8),(1675,8),(1676,8),(1677,8),(1678,8),(1679,8),(1680,8),(1681,8),(1682,8),(1683,8),(1684,8),(1685,8),(1686,8),(1687,8),(1688,8),(1689,8),(1690,8),(1691,8),(1692,8),(1693,8),(1694,8),(1695,8),(1696,8),(1697,8),(1698,8),(1699,8),(1700,8),(1701,8),(1702,8),(1703,8),(1704,8),(1705,8),(1706,8),(1707,8),(1708,8),(1709,8),(1710,8),(1711,8),(1712,8),(1713,8),(1714,8),(1715,8),(1716,8),(1717,8),(1718,8),(1719,8),(1720,8),(1721,8),(1722,8),(1723,8),(1724,8),(1725,8),(1726,8),(1727,8),(1728,8),(1729,8),(1730,8),(1731,8),(1732,8),(1733,8),(1734,8),(1735,8),(1736,8),(1737,8),(1738,8),(1739,8),(1740,8),(1741,8),(1742,8),(1743,8),(1744,8),(1745,8),(1746,8),(1747,8),(1748,8),(1749,8),(1750,8),(1751,8),(1752,8),(1753,8),(1754,8),(1755,8),(1756,8),(1757,8),(1758,8),(1759,8),(1760,8),(1761,8),(1762,8),(1763,8),(1764,8),(1765,8),(1766,8),(1767,8),(1768,8),(1769,8),(1770,8),(1771,8),(1772,8),(1773,8),(1774,8),(1775,8),(1776,8),(1777,8),(1778,8),(1779,8),(1780,8),(1781,8),(1782,8),(1783,8),(1784,8),(1785,8),(1786,8),(1787,8),(1788,8),(1789,8),(1790,8),(1791,8),(1792,8),(1793,8),(1794,8),(1795,8),(1796,8),(1797,8),(1798,8),(1799,8),(1800,8),(1801,8),(1802,8),(1803,8),(1804,8),(1805,8),(1806,8),(1807,8),(1808,8),(1809,8),(1810,8),(1811,8),(1812,8),(1813,8),(1814,8),(1815,8),(1816,8),(1817,8),(1818,8),(1819,8),(1820,8),(1821,8),(1822,8),(1823,8),(1824,8),(1825,8),(1826,8),(1827,8),(1828,8),(1829,8),(1830,8),(1831,8),(1832,8),(1833,8),(1834,8),(1835,8),(1836,8),(1837,8),(1838,8),(1839,8),(1840,8),(1841,8),(1842,8),(1843,8),(1844,8),(1845,8),(1846,8),(1847,8),(1848,8),(1849,8),(1850,8),(1851,8),(1852,8),(1853,8),(1854,8),(1855,8),(1856,8),(1857,8),(1858,8),(1859,8),(1860,8),(1861,8),(1862,8),(1863,8),(1864,8),(1865,8),(1866,8),(1867,8),(1868,8),(1869,8),(1870,8),(1871,8),(1872,8),(1873,8),(1874,8),(1875,8),(1876,8),(1877,8),(1878,8),(1879,8),(1880,8),(1881,8),(1882,8),(1883,8),(1884,8),(1885,8),(1886,8),(1887,8),(1888,8),(1889,8),(1890,8),(1891,8),(1892,8),(1893,8),(1894,8),(1895,8),(1896,8),(1897,8),(1898,8),(1899,8),(1900,8),(1901,8),(1902,8),(1903,8),(1904,8),(1905,8),(1906,8),(1907,8),(1908,8),(1909,8),(1910,8),(1911,8),(1912,8),(1913,8),(1914,8),(1915,8),(1916,8),(1917,8),(1918,8),(1919,8),(1920,8),(1921,8),(1922,8),(1923,8),(1924,8),(1925,8),(1926,8),(1927,8),(1928,8),(1929,8),(1930,8),(1931,8),(1932,8),(1933,8),(1934,8),(1935,8),(1936,8),(1937,8),(1938,8),(1939,8),(1940,8),(1941,8),(1942,8),(1943,8),(1944,8),(1945,8),(1946,8),(1947,8),(1948,8),(1949,8),(1950,8),(1951,8),(1952,8),(1953,8),(1954,8),(1955,8),(1956,8),(1957,8),(1958,8),(1959,8),(1960,8),(1961,8),(1962,8),(1963,8),(1964,8),(1965,8),(1966,8),(1967,8),(1968,8),(1969,8),(1970,8),(1971,8),(1972,8),(1973,8),(1974,8),(1,9),(2,9),(3,9),(4,9),(5,9),(6,9),(7,9),(8,9),(9,9),(10,9),(11,9),(12,9),(13,9),(14,9),(15,9),(16,9),(17,9),(18,9),(19,9),(20,9),(21,9),(22,9),(23,9),(24,9),(25,9),(26,9),(27,9),(28,9),(29,9),(30,9),(31,9),(32,9),(33,9),(34,9),(35,9),(36,9),(37,9),(38,9),(39,9),(40,9),(41,9),(42,9),(43,9),(44,9),(45,9),(46,9),(47,9),(48,9),(49,9),(50,9),(51,9),(52,9),(53,9),(54,9),(55,9),(56,9),(57,9),(58,9),(59,9),(60,9),(61,9),(62,9),(63,9),(64,9),(65,9),(66,9),(67,9),(68,9),(69,9),(70,9),(71,9),(72,9),(73,9),(74,9),(75,9),(76,9),(77,9),(78,9),(79,9),(80,9),(81,9),(82,9),(83,9),(84,9),(85,9),(86,9),(87,9),(88,9),(89,9),(90,9),(91,9),(92,9),(93,9),(94,9),(95,9),(96,9),(97,9),(98,9),(99,9),(100,9),(101,9),(102,9),(103,9),(104,9),(105,9),(106,9),(107,9),(108,9),(109,9),(110,9),(111,9),(112,9),(113,9),(114,9),(115,9),(116,9),(117,9),(118,9),(119,9),(120,9),(121,9),(122,9),(123,9),(124,9),(125,9),(126,9),(127,9),(128,9),(129,9),(130,9),(131,9),(132,9),(133,9),(134,9),(135,9),(136,9),(137,9),(138,9),(139,9),(140,9),(141,9),(142,9),(143,9),(144,9),(145,9),(146,9),(147,9),(148,9),(149,9),(150,9),(151,9),(152,9),(153,9),(154,9),(155,9),(156,9),(157,9),(158,9),(159,9),(160,9),(161,9),(162,9),(163,9),(164,9),(165,9),(166,9),(167,9),(168,9),(169,9),(170,9),(171,9),(172,9),(173,9),(174,9),(175,9),(176,9),(177,9),(178,9),(179,9),(180,9),(181,9),(182,9),(183,9),(184,9),(185,9),(186,9),(187,9),(188,9),(189,9),(190,9),(191,9),(192,9),(193,9),(194,9),(195,9),(196,9),(197,9),(198,9),(199,9),(200,9),(201,9),(202,9),(203,9),(204,9),(205,9),(206,9),(207,9),(208,9),(209,9),(210,9),(211,9),(212,9),(213,9),(214,9),(215,9),(216,9),(217,9),(218,9),(219,9),(220,9),(221,9),(222,9),(223,9),(224,9),(225,9),(226,9),(227,9),(228,9),(229,9),(230,9),(231,9),(232,9),(233,9),(234,9),(235,9),(236,9),(237,9),(238,9),(239,9),(240,9),(241,9),(242,9),(243,9),(244,9),(245,9),(246,9),(247,9),(248,9),(249,9),(250,9),(251,9),(252,9),(253,9),(254,9),(255,9),(256,9),(257,9),(258,9),(259,9),(260,9),(261,9),(262,9),(263,9),(264,9),(265,9),(266,9),(267,9),(268,9),(269,9),(270,9),(271,9),(272,9),(273,9),(274,9),(275,9),(276,9),(277,9),(278,9),(279,9),(280,9),(281,9),(282,9),(283,9),(284,9),(285,9),(286,9),(287,9),(288,9),(289,9),(290,9),(291,9),(292,9),(293,9),(294,9),(295,9),(296,9),(297,9),(298,9),(299,9),(300,9),(301,9),(302,9),(303,9),(304,9),(305,9),(306,9),(307,9),(308,9),(309,9),(310,9),(311,9),(312,9),(313,9),(314,9),(315,9),(316,9),(317,9),(318,9),(319,9),(320,9),(321,9),(322,9),(323,9),(324,9),(325,9),(326,9),(327,9),(328,9),(329,9),(330,9),(331,9),(332,9),(333,9),(334,9),(335,9),(336,9),(337,9),(338,9),(339,9),(340,9),(341,9),(342,9),(343,9),(344,9),(345,9),(346,9),(347,9),(348,9),(349,9),(350,9),(351,9),(352,9),(353,9),(354,9),(355,9),(356,9),(357,9),(358,9),(359,9),(360,9),(361,9),(362,9),(363,9),(364,9),(365,9),(366,9),(367,9),(368,9),(369,9),(370,9),(371,9),(372,9),(373,9),(374,9),(375,9),(376,9),(377,9),(378,9),(379,9),(380,9),(381,9),(382,9),(383,9),(384,9),(385,9),(386,9),(387,9),(388,9),(389,9),(390,9),(391,9),(392,9),(393,9),(394,9),(395,9),(396,9),(397,9),(398,9),(399,9),(400,9),(401,9),(402,9),(403,9),(404,9),(405,9),(406,9),(407,9),(408,9),(409,9),(410,9),(411,9),(412,9),(413,9),(414,9),(415,9),(416,9),(417,9),(418,9),(419,9),(420,9),(421,9),(422,9),(423,9),(424,9),(425,9),(426,9),(427,9),(428,9),(429,9),(430,9),(431,9),(432,9),(433,9),(434,9),(435,9),(436,9),(437,9),(438,9),(439,9),(440,9),(441,9),(442,9),(443,9),(444,9),(445,9),(446,9),(447,9),(448,9),(449,9),(450,9),(451,9),(452,9),(453,9),(454,9),(455,9),(456,9),(457,9),(458,9),(459,9),(460,9),(461,9),(462,9),(463,9),(464,9),(465,9),(466,9),(467,9),(468,9),(469,9),(470,9),(471,9),(472,9),(473,9),(474,9),(475,9),(476,9),(477,9),(478,9),(479,9),(480,9),(481,9),(482,9),(483,9),(484,9),(485,9),(486,9),(487,9),(488,9),(489,9),(490,9),(491,9),(492,9),(493,9),(494,9),(495,9),(496,9),(497,9),(498,9),(499,9),(500,9),(501,9),(502,9),(503,9),(504,9),(505,9),(506,9),(507,9),(508,9),(509,9),(510,9),(511,9),(512,9),(513,9),(514,9),(515,9),(516,9),(517,9),(518,9),(519,9),(520,9),(521,9),(522,9),(523,9),(524,9),(525,9),(526,9),(527,9),(528,9),(529,9),(530,9),(531,9),(532,9),(533,9),(534,9),(535,9),(536,9),(537,9),(538,9),(539,9),(540,9),(541,9),(542,9),(543,9),(544,9),(545,9),(546,9),(547,9),(548,9),(549,9),(550,9),(551,9),(552,9),(553,9),(554,9),(555,9),(556,9),(557,9),(558,9),(559,9),(560,9),(561,9),(562,9),(563,9),(564,9),(565,9),(566,9),(567,9),(568,9),(569,9),(570,9),(571,9),(572,9),(573,9),(574,9),(575,9),(576,9),(577,9),(578,9),(579,9),(580,9),(581,9),(582,9),(583,9),(584,9),(585,9),(586,9),(587,9),(588,9),(589,9),(590,9),(591,9),(592,9),(593,9),(594,9),(595,9),(596,9),(597,9),(598,9),(599,9),(600,9),(601,9),(602,9),(603,9),(604,9),(605,9),(606,9),(607,9),(608,9),(609,9),(610,9),(611,9),(612,9),(613,9),(614,9),(615,9),(616,9),(617,9),(618,9),(619,9),(620,9),(621,9),(622,9),(623,9),(624,9),(625,9),(626,9),(627,9),(628,9),(629,9),(630,9),(631,9),(632,9),(633,9),(634,9),(635,9),(636,9),(637,9),(638,9),(639,9),(640,9),(641,9),(642,9),(643,9),(644,9),(645,9),(646,9),(647,9),(648,9),(649,9),(650,9),(651,9),(652,9),(653,9),(654,9),(655,9),(656,9),(657,9),(658,9),(659,9),(660,9),(661,9),(662,9),(663,9),(664,9),(665,9),(666,9),(667,9),(668,9),(669,9),(670,9),(671,9),(672,9),(673,9),(674,9),(675,9),(676,9),(677,9),(678,9),(679,9),(680,9),(681,9),(682,9),(683,9),(684,9),(685,9),(686,9),(687,9),(688,9),(689,9),(690,9),(691,9),(692,9),(693,9),(694,9),(695,9),(696,9),(697,9),(698,9),(699,9),(700,9),(701,9),(702,9),(703,9),(704,9),(705,9),(706,9),(707,9),(708,9),(709,9),(710,9),(711,9),(712,9),(713,9),(714,9),(715,9),(716,9),(717,9),(718,9),(719,9),(720,9),(721,9),(722,9),(723,9),(724,9),(725,9),(726,9),(727,9),(728,9),(729,9),(730,9),(731,9),(732,9),(733,9),(734,9),(735,9),(736,9),(737,9),(738,9),(739,9),(740,9),(741,9),(742,9),(743,9),(744,9),(745,9),(746,9),(747,9),(748,9),(749,9),(750,9),(751,9),(752,9),(753,9),(754,9),(755,9),(756,9),(757,9),(758,9),(759,9),(760,9),(761,9),(762,9),(763,9),(764,9),(765,9),(766,9),(767,9),(768,9),(769,9),(770,9),(771,9),(772,9),(773,9),(774,9),(775,9),(776,9),(777,9),(778,9),(779,9),(780,9),(781,9),(782,9),(783,9),(784,9),(785,9),(786,9),(787,9),(788,9),(789,9),(790,9),(791,9),(792,9),(793,9),(794,9),(795,9),(796,9),(797,9),(798,9),(799,9),(800,9),(801,9),(802,9),(803,9),(804,9),(805,9),(806,9),(807,9),(808,9),(809,9),(810,9),(811,9),(812,9),(813,9),(814,9),(815,9),(816,9),(817,9),(818,9),(819,9),(820,9),(821,9),(822,9),(823,9),(824,9),(825,9),(826,9),(827,9),(828,9),(829,9),(830,9),(831,9),(832,9),(833,9),(834,9),(835,9),(836,9),(837,9),(838,9),(839,9),(840,9),(841,9),(842,9),(843,9),(844,9),(845,9),(846,9),(847,9),(848,9),(849,9),(850,9),(851,9),(852,9),(853,9),(854,9),(855,9),(856,9),(857,9),(858,9),(859,9),(860,9),(861,9),(862,9),(863,9),(864,9),(865,9),(866,9),(867,9),(868,9),(869,9),(870,9),(871,9),(872,9),(873,9),(874,9),(875,9),(876,9),(877,9),(878,9),(879,9),(880,9),(881,9),(882,9),(883,9),(884,9),(885,9),(886,9),(887,9),(888,9),(889,9),(890,9),(891,9),(892,9),(893,9),(894,9),(895,9),(896,9),(897,9),(898,9),(899,9),(900,9),(901,9),(902,9),(903,9),(904,9),(905,9),(906,9),(907,9),(908,9),(909,9),(910,9),(911,9),(912,9),(913,9),(914,9),(915,9),(916,9),(917,9),(918,9),(919,9),(920,9),(921,9),(922,9),(923,9),(924,9),(925,9),(926,9),(927,9),(928,9),(929,9),(930,9),(931,9),(932,9),(933,9),(934,9),(935,9),(936,9),(937,9),(938,9),(939,9),(940,9),(941,9),(942,9),(943,9),(944,9),(945,9),(946,9),(947,9),(948,9),(949,9),(950,9),(951,9),(952,9),(953,9),(954,9),(955,9),(956,9),(957,9),(958,9),(959,9),(960,9),(961,9),(962,9),(963,9),(964,9),(965,9),(966,9),(967,9),(968,9),(969,9),(970,9),(971,9),(972,9),(973,9),(974,9),(975,9),(976,9),(977,9),(978,9),(979,9),(980,9),(981,9),(982,9),(983,9),(984,9),(985,9),(986,9),(987,9),(988,9),(989,9),(990,9),(991,9),(992,9),(993,9),(994,9),(995,9),(996,9),(997,9),(998,9),(999,9),(1000,9),(1001,9),(1002,9),(1003,9),(1004,9),(1005,9),(1006,9),(1007,9),(1008,9),(1009,9),(1010,9),(1011,9),(1012,9),(1013,9),(1014,9),(1015,9),(1016,9),(1017,9),(1018,9),(1019,9),(1020,9),(1021,9),(1022,9),(1023,9),(1024,9),(1025,9),(1026,9),(1027,9),(1028,9),(1029,9),(1030,9),(1031,9),(1032,9),(1033,9),(1034,9),(1035,9),(1036,9),(1037,9),(1038,9),(1039,9),(1040,9),(1041,9),(1042,9),(1043,9),(1044,9),(1045,9),(1046,9),(1047,9),(1048,9),(1049,9),(1050,9),(1051,9),(1052,9),(1053,9),(1054,9),(1055,9),(1056,9),(1057,9),(1058,9),(1059,9),(1060,9),(1061,9),(1062,9),(1063,9),(1064,9),(1065,9),(1066,9),(1067,9),(1068,9),(1069,9),(1070,9),(1071,9),(1072,9),(1073,9),(1074,9),(1075,9),(1076,9),(1077,9),(1078,9),(1079,9),(1080,9),(1081,9),(1082,9),(1083,9),(1084,9),(1085,9),(1086,9),(1087,9),(1088,9),(1089,9),(1090,9),(1091,9),(1092,9),(1093,9),(1094,9),(1095,9),(1096,9),(1097,9),(1098,9),(1099,9),(1100,9),(1101,9),(1102,9),(1103,9),(1104,9),(1105,9),(1106,9),(1107,9),(1108,9),(1109,9),(1110,9),(1111,9),(1112,9),(1113,9),(1114,9),(1115,9),(1116,9),(1117,9),(1118,9),(1119,9),(1120,9),(1121,9),(1122,9),(1123,9),(1124,9),(1125,9),(1126,9),(1127,9),(1128,9),(1129,9),(1130,9),(1131,9),(1132,9),(1133,9),(1134,9),(1135,9),(1136,9),(1137,9),(1138,9),(1139,9),(1140,9),(1141,9),(1142,9),(1143,9),(1144,9),(1145,9),(1146,9),(1147,9),(1148,9),(1149,9),(1150,9),(1151,9),(1152,9),(1153,9),(1154,9),(1155,9),(1156,9),(1157,9),(1158,9),(1159,9),(1160,9),(1161,9),(1162,9),(1163,9),(1164,9),(1165,9),(1166,9),(1167,9),(1168,9),(1169,9),(1170,9),(1171,9),(1172,9),(1173,9),(1174,9),(1175,9),(1176,9),(1177,9),(1178,9),(1179,9),(1180,9),(1181,9),(1182,9),(1183,9),(1184,9),(1185,9),(1186,9),(1187,9),(1188,9),(1189,9),(1190,9),(1191,9),(1192,9),(1193,9),(1194,9),(1195,9),(1196,9),(1197,9),(1198,9),(1199,9),(1200,9),(1201,9),(1202,9),(1203,9),(1204,9),(1205,9),(1206,9),(1207,9),(1208,9),(1209,9),(1210,9),(1211,9),(1212,9),(1213,9),(1214,9),(1215,9),(1216,9),(1217,9),(1218,9),(1219,9),(1220,9),(1221,9),(1222,9),(1223,9),(1224,9),(1225,9),(1226,9),(1227,9),(1228,9),(1229,9),(1230,9),(1231,9),(1232,9),(1233,9),(1234,9),(1235,9),(1236,9),(1237,9),(1238,9),(1239,9),(1240,9),(1241,9),(1242,9),(1243,9),(1244,9),(1245,9),(1246,9),(1247,9),(1248,9),(1249,9),(1250,9),(1251,9),(1252,9),(1253,9),(1254,9),(1255,9),(1256,9),(1257,9),(1258,9),(1259,9),(1260,9),(1261,9),(1262,9),(1263,9),(1264,9),(1265,9),(1266,9),(1267,9),(1268,9),(1269,9),(1270,9),(1271,9),(1272,9),(1273,9),(1274,9),(1275,9),(1276,9),(1277,9),(1278,9),(1279,9),(1280,9),(1281,9),(1282,9),(1283,9),(1284,9),(1285,9),(1286,9),(1287,9),(1288,9),(1289,9),(1290,9),(1291,9),(1292,9),(1293,9),(1294,9),(1295,9),(1296,9),(1297,9),(1298,9),(1299,9),(1300,9),(1301,9),(1302,9),(1303,9),(1304,9),(1305,9),(1306,9),(1307,9),(1308,9),(1309,9),(1310,9),(1311,9),(1312,9),(1313,9),(1314,9),(1315,9),(1316,9),(1317,9),(1318,9),(1319,9),(1320,9),(1321,9),(1322,9),(1323,9),(1324,9),(1325,9),(1326,9),(1327,9),(1328,9),(1329,9),(1330,9),(1331,9),(1332,9),(1333,9),(1334,9),(1335,9),(1336,9),(1337,9),(1338,9),(1339,9),(1340,9),(1341,9),(1342,9),(1343,9),(1344,9),(1345,9),(1346,9),(1347,9),(1348,9),(1349,9),(1350,9),(1351,9),(1352,9),(1353,9),(1354,9),(1355,9),(1356,9),(1357,9),(1358,9),(1359,9),(1360,9),(1361,9),(1362,9),(1363,9),(1364,9),(1365,9),(1366,9),(1367,9),(1368,9),(1369,9),(1370,9),(1371,9),(1372,9),(1373,9),(1374,9),(1375,9),(1376,9),(1377,9),(1378,9),(1379,9),(1380,9),(1381,9),(1382,9),(1383,9),(1384,9),(1385,9),(1386,9),(1387,9),(1388,9),(1389,9),(1390,9),(1391,9),(1392,9),(1393,9),(1394,9),(1395,9),(1396,9),(1397,9),(1398,9),(1399,9),(1400,9),(1401,9),(1402,9),(1403,9),(1404,9),(1405,9),(1406,9),(1407,9),(1408,9),(1409,9),(1410,9),(1411,9),(1412,9),(1413,9),(1414,9),(1415,9),(1416,9),(1417,9),(1418,9),(1419,9),(1420,9),(1421,9),(1422,9),(1423,9),(1424,9),(1425,9),(1426,9),(1427,9),(1428,9),(1429,9),(1430,9),(1431,9),(1432,9),(1433,9),(1434,9),(1435,9),(1436,9),(1437,9),(1438,9),(1439,9),(1440,9),(1441,9),(1442,9),(1443,9),(1444,9),(1445,9),(1446,9),(1447,9),(1448,9),(1449,9),(1450,9),(1451,9),(1452,9),(1453,9),(1454,9),(1455,9),(1456,9),(1457,9),(1458,9),(1459,9),(1460,9),(1461,9),(1462,9),(1463,9),(1464,9),(1465,9),(1466,9),(1467,9),(1468,9),(1469,9),(1470,9),(1471,9),(1472,9),(1473,9),(1474,9),(1475,9),(1476,9),(1477,9),(1478,9),(1479,9),(1480,9),(1481,9),(1482,9),(1483,9),(1484,9),(1485,9),(1486,9),(1487,9),(1488,9),(1489,9),(1490,9),(1491,9),(1492,9),(1493,9),(1494,9),(1495,9),(1496,9),(1497,9),(1498,9),(1499,9),(1500,9),(1501,9),(1502,9),(1503,9),(1504,9),(1505,9),(1506,9),(1507,9),(1508,9),(1509,9),(1510,9),(1511,9),(1512,9),(1513,9),(1514,9),(1515,9),(1516,9),(1517,9),(1518,9),(1519,9),(1520,9),(1521,9),(1522,9),(1523,9),(1524,9),(1525,9),(1526,9),(1527,9),(1528,9),(1529,9),(1530,9),(1531,9),(1532,9),(1533,9),(1534,9),(1535,9),(1536,9),(1537,9),(1538,9),(1539,9),(1540,9),(1541,9),(1542,9),(1543,9),(1544,9),(1545,9),(1546,9),(1547,9),(1548,9),(1549,9),(1550,9),(1551,9),(1552,9),(1553,9),(1554,9),(1555,9),(1556,9),(1557,9),(1558,9),(1559,9),(1560,9),(1561,9),(1562,9),(1563,9),(1564,9),(1565,9),(1566,9),(1567,9),(1568,9),(1569,9),(1570,9),(1571,9),(1572,9),(1573,9),(1574,9),(1575,9),(1576,9),(1577,9),(1578,9),(1579,9),(1580,9),(1581,9),(1582,9),(1583,9),(1584,9),(1585,9),(1586,9),(1587,9),(1588,9),(1589,9),(1590,9),(1591,9),(1592,9),(1593,9),(1594,9),(1595,9),(1596,9),(1597,9),(1598,9),(1599,9),(1600,9),(1601,9),(1602,9),(1603,9),(1604,9),(1605,9),(1606,9),(1607,9),(1608,9),(1609,9),(1610,9),(1611,9),(1612,9),(1613,9),(1614,9),(1615,9),(1616,9),(1617,9),(1618,9),(1619,9),(1620,9),(1621,9),(1622,9),(1623,9),(1624,9),(1625,9),(1626,9),(1627,9),(1628,9),(1629,9),(1630,9),(1631,9),(1632,9),(1633,9),(1634,9),(1635,9),(1636,9),(1637,9),(1638,9),(1639,9),(1640,9),(1641,9),(1642,9),(1643,9),(1644,9),(1645,9),(1646,9),(1647,9),(1648,9),(1649,9),(1650,9),(1651,9),(1652,9),(1653,9),(1654,9),(1655,9),(1656,9),(1657,9),(1658,9),(1659,9),(1660,9),(1661,9),(1662,9),(1663,9),(1664,9),(1665,9),(1666,9),(1667,9),(1668,9),(1669,9),(1670,9),(1671,9),(1672,9),(1673,9),(1674,9),(1675,9),(1676,9),(1677,9),(1678,9),(1679,9),(1680,9),(1681,9),(1682,9),(1683,9),(1684,9),(1685,9),(1686,9),(1687,9),(1688,9),(1689,9),(1690,9),(1691,9),(1692,9),(1693,9),(1694,9),(1695,9),(1696,9),(1697,9),(1698,9),(1699,9),(1700,9),(1701,9),(1702,9),(1703,9),(1704,9),(1705,9),(1706,9),(1707,9),(1708,9),(1709,9),(1710,9),(1711,9),(1712,9),(1713,9),(1714,9),(1715,9),(1716,9),(1717,9),(1718,9),(1719,9),(1720,9),(1721,9),(1722,9),(1723,9),(1724,9),(1725,9),(1726,9),(1727,9),(1728,9),(1729,9),(1730,9),(1731,9),(1732,9),(1733,9),(1734,9),(1735,9),(1736,9),(1737,9),(1738,9),(1739,9),(1740,9),(1741,9),(1742,9),(1743,9),(1744,9),(1745,9),(1746,9),(1747,9),(1748,9),(1749,9),(1750,9),(1751,9),(1752,9),(1753,9),(1754,9),(1755,9),(1756,9),(1757,9),(1758,9),(1759,9),(1760,9),(1761,9),(1762,9),(1763,9),(1764,9),(1765,9),(1766,9),(1767,9),(1768,9),(1769,9),(1770,9),(1771,9),(1772,9),(1773,9),(1774,9),(1775,9),(1776,9),(1777,9),(1778,9),(1779,9),(1780,9),(1781,9),(1782,9),(1783,9),(1784,9),(1785,9),(1786,9),(1787,9),(1788,9),(1789,9),(1790,9),(1791,9),(1792,9),(1793,9),(1794,9),(1795,9),(1796,9),(1797,9),(1798,9),(1799,9),(1800,9),(1801,9),(1802,9),(1803,9),(1804,9),(1805,9),(1806,9),(1807,9),(1808,9),(1809,9),(1810,9),(1811,9),(1812,9),(1813,9),(1814,9),(1815,9),(1816,9),(1817,9),(1818,9),(1819,9),(1820,9),(1821,9),(1822,9),(1823,9),(1824,9),(1825,9),(1826,9),(1827,9),(1828,9),(1829,9),(1830,9),(1831,9),(1832,9),(1833,9),(1834,9),(1835,9),(1836,9),(1837,9),(1838,9),(1839,9),(1840,9),(1841,9),(1842,9),(1843,9),(1844,9),(1845,9),(1846,9),(1847,9),(1848,9),(1849,9),(1850,9),(1851,9),(1852,9),(1853,9),(1854,9),(1855,9),(1856,9),(1857,9),(1858,9),(1859,9),(1860,9),(1861,9),(1862,9),(1863,9),(1864,9),(1865,9),(1866,9),(1867,9),(1868,9),(1869,9),(1870,9),(1871,9),(1872,9),(1873,9),(1874,9),(1875,9),(1876,9),(1877,9),(1878,9),(1879,9),(1880,9),(1881,9),(1882,9),(1883,9),(1884,9),(1885,9),(1886,9),(1887,9),(1888,9),(1889,9),(1890,9),(1891,9),(1892,9),(1893,9),(1894,9),(1895,9),(1896,9),(1897,9),(1898,9),(1899,9),(1900,9),(1901,9),(1902,9),(1903,9),(1904,9),(1905,9),(1906,9),(1907,9),(1908,9),(1909,9),(1910,9),(1911,9),(1912,9),(1913,9),(1914,9),(1915,9),(1916,9),(1917,9),(1918,9),(1919,9),(1920,9),(1921,9),(1922,9),(1923,9),(1924,9),(1925,9),(1926,9),(1927,9),(1928,9),(1929,9),(1930,9),(1931,9),(1932,9),(1933,9),(1934,9),(1935,9),(1936,9),(1937,9),(1938,9),(1939,9),(1940,9),(1941,9),(1942,9),(1943,9),(1944,9),(1945,9),(1946,9),(1947,9),(1948,9),(1949,9),(1950,9),(1951,9),(1952,9),(1953,9),(1954,9),(1955,9),(1956,9),(1957,9),(1958,9),(1959,9),(1960,9),(1961,9),(1962,9),(1963,9),(1964,9),(1965,9),(1966,9),(1967,9),(1968,9),(1969,9),(1970,9),(1971,9),(1972,9),(1973,9),(1974,9);
/*!40000 ALTER TABLE `sys_role_has_permissions_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_roles`
--

DROP TABLE IF EXISTS `sys_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_roles`
--

LOCK TABLES `sys_roles` WRITE;
/*!40000 ALTER TABLE `sys_roles` DISABLE KEYS */;
INSERT INTO `sys_roles` VALUES (1,'Super Admin','super_admin','web','2026-02-01 06:03:04','2026-02-01 06:03:04','Full system access, manages roles & permissions',1),(2,'Principal','principal','web','2026-02-01 06:03:11','2026-02-01 06:03:11','Head of the school, oversees all operations',0),(3,'Vice Principal','vice_principal','web','2026-02-01 06:03:17','2026-02-01 06:03:17','Supports principal, handles academics & discipline',0),(4,'Teacher','teacher','web','2026-02-01 06:03:24','2026-02-01 06:03:24','Handles classroom teaching and student management',0),(5,'Staff','staff','web','2026-02-01 06:03:31','2026-02-01 06:03:31','General non-teaching school staff (admin, clerical, etc.)',0),(6,'Accountant','accountant','web','2026-02-01 06:03:38','2026-02-01 06:03:38','Handles school finances, fees, and accounts',0),(7,'Librarian','librarian','web','2026-02-01 06:03:45','2026-02-01 06:03:45','Manages library resources and inventory',0),(8,'Parent','parent','web','2026-02-01 06:03:52','2026-02-01 06:03:52','Access to ward/student data and reports',0),(9,'Student','student','web','2026-02-01 06:03:59','2026-02-01 06:03:59','Access to personal academic data and coursework',0);
/*!40000 ALTER TABLE `sys_roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_settings`
--

DROP TABLE IF EXISTS `sys_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_settings`
--

LOCK TABLES `sys_settings` WRITE;
/*!40000 ALTER TABLE `sys_settings` DISABLE KEYS */;
INSERT INTO `sys_settings` VALUES (1,'default_language','Default language for the system interface','en','string',1,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(2,'default_theme','Default theme to be used by the system','light','string',1,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(3,'default_side_bar_collapse','Whether sidebar is collapsed by default (0 = false, 1 = true)','0','boolean',0,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(4,'school_logo_url','URL of the school logo to display on system pages','https://example.com/logo.png','string',1,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(5,'contact_email','Primary contact email address for the organization','info@example.com','string',1,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(6,'maintenance_mode','Flag to enable or disable maintenance mode','0','boolean',0,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(7,'timezone','Default timezone for the system','UTC','string',1,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(8,'subject_group__used__for__all__sections','If enabled, subject group will be used for all sections and section selection will be disabled.','TURE','boolean',1,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(9,'allow_only_one_side_transport_charges','If enabled, transport charges will be applied for only one side (either pickup or drop) instead of both.','TRUE','boolean',1,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(10,'allow_different_pickup_and_drop_point','If enabled, students can have different pickup and drop locations for transportation.','TRUE','boolean',1,'2026-02-01 06:04:07','2026-02-01 06:04:07'),(11,'allow_extra_student_in_vehicale_beyond_capacity','If enabled, allows assigning additional students to a vehicle even if it exceeds the defined seating capacity.','TRUE','boolean',1,'2026-02-01 06:04:07','2026-02-01 06:04:07');
/*!40000 ALTER TABLE `sys_settings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_users`
--

DROP TABLE IF EXISTS `sys_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_users`
--

LOCK TABLES `sys_users` WRITE;
/*!40000 ALTER TABLE `sys_users` DISABLE KEYS */;
INSERT INTO `sys_users` (`id`, `name`, `short_name`, `emp_code`, `email`, `phone_no`, `mobile_no`, `two_factor_auth_enabled`, `email_verified_at`, `is_active`, `password`, `is_super_admin`, `is_pg_user`, `status`, `last_login_at`, `remember_token`, `created_at`, `updated_at`, `deleted_at`) VALUES (1,'Root User','root','abc','root@primeai.com',NULL,NULL,0,NULL,1,'$2y$12$KMF0yy78i8Z3OPAy0d6RWu6KvgWIszRRnJR7Hel.Plku8XODKhdGi',0,0,'ACTIVE',NULL,NULL,'2026-02-01 06:03:00','2026-02-01 06:03:00',NULL),(2,'Root User','ROOT-1175','28154','root@tenant.com',NULL,NULL,0,NULL,1,'$2y$12$28MnudZk9WfbZfxC8NYr6.tjA3CZAA4fyYV60MV1DjRD8sCxooISe',1,0,'ACTIVE',NULL,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(3,'Principal User','PRIN1-4923','34994','principal@tenant.com',NULL,NULL,0,NULL,1,'$2y$12$28MnudZk9WfbZfxC8NYr6.tjA3CZAA4fyYV60MV1DjRD8sCxooISe',0,0,'ACTIVE',NULL,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(4,'Vice Principal User','VPRIN1-2043','54291','viceprincipal@tenant.com',NULL,NULL,0,NULL,1,'$2y$12$28MnudZk9WfbZfxC8NYr6.tjA3CZAA4fyYV60MV1DjRD8sCxooISe',0,0,'ACTIVE',NULL,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(5,'Ankit Rai','TEA01-1304','4068','ankit.rai@primeai.com',NULL,NULL,0,NULL,1,'$2y$12$28MnudZk9WfbZfxC8NYr6.tjA3CZAA4fyYV60MV1DjRD8sCxooISe',0,0,'ACTIVE',NULL,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(6,'Pallavi Bhandari','TEA02-1133','19988','pallavi.bhandari@primeai.com',NULL,NULL,0,NULL,1,'$2y$12$28MnudZk9WfbZfxC8NYr6.tjA3CZAA4fyYV60MV1DjRD8sCxooISe',0,0,'ACTIVE',NULL,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(7,'Vijay Pandey','TEA03-4211','42981','vijay.pandey@primeai.com',NULL,NULL,0,NULL,1,'$2y$12$28MnudZk9WfbZfxC8NYr6.tjA3CZAA4fyYV60MV1DjRD8sCxooISe',0,0,'ACTIVE',NULL,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(8,'Pooja Joshi','TEA04-2576','46714','pooja.joshi@primeai.com',NULL,NULL,0,NULL,1,'$2y$12$28MnudZk9WfbZfxC8NYr6.tjA3CZAA4fyYV60MV1DjRD8sCxooISe',0,0,'ACTIVE',NULL,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(9,'Geetika Oli','TEA05-1934','86111','geetika.oli@primeai.com',NULL,NULL,0,NULL,1,'$2y$12$28MnudZk9WfbZfxC8NYr6.tjA3CZAA4fyYV60MV1DjRD8sCxooISe',0,0,'ACTIVE',NULL,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(10,'Librarian One','LIB1-3975','69969','librarian1@primeai.com',NULL,NULL,0,NULL,1,'$2y$12$28MnudZk9WfbZfxC8NYr6.tjA3CZAA4fyYV60MV1DjRD8sCxooISe',0,0,'ACTIVE',NULL,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(11,'Librarian Two','LIB2-2775','81795','librarian2@primeai.com',NULL,NULL,0,NULL,1,'$2y$12$28MnudZk9WfbZfxC8NYr6.tjA3CZAA4fyYV60MV1DjRD8sCxooISe',0,0,'ACTIVE',NULL,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(12,'Accountant One','ACC1-3905','93278','accountant1@primeai.com',NULL,NULL,0,NULL,1,'$2y$12$28MnudZk9WfbZfxC8NYr6.tjA3CZAA4fyYV60MV1DjRD8sCxooISe',0,0,'ACTIVE',NULL,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(13,'Accountant Two','ACC2-4946','86051','accountant2@primeai.com',NULL,NULL,0,NULL,1,'$2y$12$28MnudZk9WfbZfxC8NYr6.tjA3CZAA4fyYV60MV1DjRD8sCxooISe',0,0,'ACTIVE',NULL,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(14,'Student One','STDNT1-1261','29268','student1@primeai.com',NULL,NULL,0,NULL,1,'$2y$12$28MnudZk9WfbZfxC8NYr6.tjA3CZAA4fyYV60MV1DjRD8sCxooISe',0,0,'ACTIVE',NULL,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(15,'Student Two','STDNT2-1052','11928','student2@primeai.com',NULL,NULL,0,NULL,1,'$2y$12$28MnudZk9WfbZfxC8NYr6.tjA3CZAA4fyYV60MV1DjRD8sCxooISe',0,0,'ACTIVE',NULL,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(16,'Parent One','PRNT1-1794','86706','parent1@primeai.com',NULL,NULL,0,NULL,1,'$2y$12$28MnudZk9WfbZfxC8NYr6.tjA3CZAA4fyYV60MV1DjRD8sCxooISe',0,0,'ACTIVE',NULL,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(17,'Parent Two','PRNT2-4697','25764','parent2@primeai.com',NULL,NULL,0,NULL,1,'$2y$12$28MnudZk9WfbZfxC8NYr6.tjA3CZAA4fyYV60MV1DjRD8sCxooISe',0,0,'ACTIVE',NULL,NULL,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL);
/*!40000 ALTER TABLE `sys_users` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_users_prevent_update_super` BEFORE UPDATE ON `sys_users` FOR EACH ROW BEGIN
                IF OLD.is_super_admin = 1 AND NEW.is_super_admin = 0 THEN
                    SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Super Admin cannot be demoted';
                END IF;
            END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_users_prevent_delete_super` BEFORE DELETE ON `sys_users` FOR EACH ROW BEGIN
                IF OLD.is_super_admin = 1 THEN
                    SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Super Admin cannot be deleted';
                END IF;
            END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `tpt_attendance_device`
--

DROP TABLE IF EXISTS `tpt_attendance_device`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_attendance_device`
--

LOCK TABLES `tpt_attendance_device` WRITE;
/*!40000 ALTER TABLE `tpt_attendance_device` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_attendance_device` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_daily_vehicle_inspection`
--

DROP TABLE IF EXISTS `tpt_daily_vehicle_inspection`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_daily_vehicle_inspection`
--

LOCK TABLES `tpt_daily_vehicle_inspection` WRITE;
/*!40000 ALTER TABLE `tpt_daily_vehicle_inspection` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_daily_vehicle_inspection` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_driver_attendance`
--

DROP TABLE IF EXISTS `tpt_driver_attendance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_driver_attendance`
--

LOCK TABLES `tpt_driver_attendance` WRITE;
/*!40000 ALTER TABLE `tpt_driver_attendance` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_driver_attendance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_driver_route_vehicle_jnt`
--

DROP TABLE IF EXISTS `tpt_driver_route_vehicle_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_driver_route_vehicle_jnt`
--

LOCK TABLES `tpt_driver_route_vehicle_jnt` WRITE;
/*!40000 ALTER TABLE `tpt_driver_route_vehicle_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_driver_route_vehicle_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_feature_store`
--

DROP TABLE IF EXISTS `tpt_feature_store`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_feature_store`
--

LOCK TABLES `tpt_feature_store` WRITE;
/*!40000 ALTER TABLE `tpt_feature_store` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_feature_store` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_fine_master`
--

DROP TABLE IF EXISTS `tpt_fine_master`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_fine_master`
--

LOCK TABLES `tpt_fine_master` WRITE;
/*!40000 ALTER TABLE `tpt_fine_master` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_fine_master` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_gps_alerts`
--

DROP TABLE IF EXISTS `tpt_gps_alerts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_gps_alerts`
--

LOCK TABLES `tpt_gps_alerts` WRITE;
/*!40000 ALTER TABLE `tpt_gps_alerts` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_gps_alerts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_gps_trip_log`
--

DROP TABLE IF EXISTS `tpt_gps_trip_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_gps_trip_log`
--

LOCK TABLES `tpt_gps_trip_log` WRITE;
/*!40000 ALTER TABLE `tpt_gps_trip_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_gps_trip_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_live_trip`
--

DROP TABLE IF EXISTS `tpt_live_trip`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_live_trip`
--

LOCK TABLES `tpt_live_trip` WRITE;
/*!40000 ALTER TABLE `tpt_live_trip` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_live_trip` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_model_recommendations`
--

DROP TABLE IF EXISTS `tpt_model_recommendations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_model_recommendations`
--

LOCK TABLES `tpt_model_recommendations` WRITE;
/*!40000 ALTER TABLE `tpt_model_recommendations` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_model_recommendations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_notification_log`
--

DROP TABLE IF EXISTS `tpt_notification_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_notification_log`
--

LOCK TABLES `tpt_notification_log` WRITE;
/*!40000 ALTER TABLE `tpt_notification_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_notification_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_personnel`
--

DROP TABLE IF EXISTS `tpt_personnel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_personnel`
--

LOCK TABLES `tpt_personnel` WRITE;
/*!40000 ALTER TABLE `tpt_personnel` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_personnel` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_pickup_points`
--

DROP TABLE IF EXISTS `tpt_pickup_points`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_pickup_points`
--

LOCK TABLES `tpt_pickup_points` WRITE;
/*!40000 ALTER TABLE `tpt_pickup_points` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_pickup_points` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_pickup_points_route_jnt`
--

DROP TABLE IF EXISTS `tpt_pickup_points_route_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_pickup_points_route_jnt`
--

LOCK TABLES `tpt_pickup_points_route_jnt` WRITE;
/*!40000 ALTER TABLE `tpt_pickup_points_route_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_pickup_points_route_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_recommendation_history`
--

DROP TABLE IF EXISTS `tpt_recommendation_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_recommendation_history`
--

LOCK TABLES `tpt_recommendation_history` WRITE;
/*!40000 ALTER TABLE `tpt_recommendation_history` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_recommendation_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_route`
--

DROP TABLE IF EXISTS `tpt_route`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_route`
--

LOCK TABLES `tpt_route` WRITE;
/*!40000 ALTER TABLE `tpt_route` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_route` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_route_scheduler_jnt`
--

DROP TABLE IF EXISTS `tpt_route_scheduler_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_route_scheduler_jnt`
--

LOCK TABLES `tpt_route_scheduler_jnt` WRITE;
/*!40000 ALTER TABLE `tpt_route_scheduler_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_route_scheduler_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_shift`
--

DROP TABLE IF EXISTS `tpt_shift`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_shift`
--

LOCK TABLES `tpt_shift` WRITE;
/*!40000 ALTER TABLE `tpt_shift` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_shift` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_student_boarding_log`
--

DROP TABLE IF EXISTS `tpt_student_boarding_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_student_boarding_log`
--

LOCK TABLES `tpt_student_boarding_log` WRITE;
/*!40000 ALTER TABLE `tpt_student_boarding_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_student_boarding_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_student_event_log`
--

DROP TABLE IF EXISTS `tpt_student_event_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_student_event_log`
--

LOCK TABLES `tpt_student_event_log` WRITE;
/*!40000 ALTER TABLE `tpt_student_event_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_student_event_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_student_fee_collection`
--

DROP TABLE IF EXISTS `tpt_student_fee_collection`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_student_fee_collection`
--

LOCK TABLES `tpt_student_fee_collection` WRITE;
/*!40000 ALTER TABLE `tpt_student_fee_collection` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_student_fee_collection` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_student_fee_detail`
--

DROP TABLE IF EXISTS `tpt_student_fee_detail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_student_fee_detail`
--

LOCK TABLES `tpt_student_fee_detail` WRITE;
/*!40000 ALTER TABLE `tpt_student_fee_detail` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_student_fee_detail` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_student_fine_detail`
--

DROP TABLE IF EXISTS `tpt_student_fine_detail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_student_fine_detail`
--

LOCK TABLES `tpt_student_fine_detail` WRITE;
/*!40000 ALTER TABLE `tpt_student_fine_detail` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_student_fine_detail` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_student_route_allocation_jnt`
--

DROP TABLE IF EXISTS `tpt_student_route_allocation_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_student_route_allocation_jnt`
--

LOCK TABLES `tpt_student_route_allocation_jnt` WRITE;
/*!40000 ALTER TABLE `tpt_student_route_allocation_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_student_route_allocation_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_trip`
--

DROP TABLE IF EXISTS `tpt_trip`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_trip`
--

LOCK TABLES `tpt_trip` WRITE;
/*!40000 ALTER TABLE `tpt_trip` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_trip` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_trip_incidents`
--

DROP TABLE IF EXISTS `tpt_trip_incidents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_trip_incidents`
--

LOCK TABLES `tpt_trip_incidents` WRITE;
/*!40000 ALTER TABLE `tpt_trip_incidents` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_trip_incidents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_trip_stop_detail`
--

DROP TABLE IF EXISTS `tpt_trip_stop_detail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_trip_stop_detail`
--

LOCK TABLES `tpt_trip_stop_detail` WRITE;
/*!40000 ALTER TABLE `tpt_trip_stop_detail` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_trip_stop_detail` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_vehicle`
--

DROP TABLE IF EXISTS `tpt_vehicle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_vehicle`
--

LOCK TABLES `tpt_vehicle` WRITE;
/*!40000 ALTER TABLE `tpt_vehicle` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_vehicle` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_vehicle_fuel`
--

DROP TABLE IF EXISTS `tpt_vehicle_fuel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_vehicle_fuel`
--

LOCK TABLES `tpt_vehicle_fuel` WRITE;
/*!40000 ALTER TABLE `tpt_vehicle_fuel` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_vehicle_fuel` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_vehicle_maintenance`
--

DROP TABLE IF EXISTS `tpt_vehicle_maintenance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_vehicle_maintenance`
--

LOCK TABLES `tpt_vehicle_maintenance` WRITE;
/*!40000 ALTER TABLE `tpt_vehicle_maintenance` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_vehicle_maintenance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tpt_vehicle_service_request`
--

DROP TABLE IF EXISTS `tpt_vehicle_service_request`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tpt_vehicle_service_request`
--

LOCK TABLES `tpt_vehicle_service_request` WRITE;
/*!40000 ALTER TABLE `tpt_vehicle_service_request` DISABLE KEYS */;
/*!40000 ALTER TABLE `tpt_vehicle_service_request` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_activities`
--

DROP TABLE IF EXISTS `tt_activities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_activities`
--

LOCK TABLES `tt_activities` WRITE;
/*!40000 ALTER TABLE `tt_activities` DISABLE KEYS ;
INSERT INTO `tt_activities` (`id`, `uuid`, `code`, `name`, `description`, `academic_session_id`, `class_group_jnt_id`, `class_subgroup_id`, `duration_periods`, `weekly_periods`, `split_allowed`, `is_compulsory`, `priority`, `difficulty_score`, `requires_room`, `preferred_room_type_id`, `preferred_room_ids`, `status`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`) VALUES (1,'x�\�\�{O��h��\�gR','06_A_ENG_TH','Class VI(A) - English Theory','Complete academic workload for Class VI(A) - English Theory',7,1,NULL,1,6,0,1,50,50,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(2,'r\�L!\�L��tQ�\�\�m','06_A_HIN_TH','Class VI(A) - Hindi Theory','Complete academic workload for Class VI(A) - Hindi Theory',7,2,NULL,1,6,0,1,50,90,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(3, 'g�G^�kF)�)�\��jVM','06_A_MAT_TH','Class VI(A) - Maths Theory','Complete academic workload for Class VI(A) - Maths Theory',7,3,NULL,1,6,0,1,50,90,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(4,_binary '�\�\�\�\�\ZO���cH~Ë','06_A_SOC_TH','Class VI(A) - Social Science Theory','Complete academic workload for Class VI(A) - Social Science Theory',7,4,NULL,1,6,0,1,50,50,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(5,_binary '	��ޔG�5^G\�\�[','06_A_SAN_TH','Class VI(A) - Sanskrit Theory','Complete academic workload for Class VI(A) - Sanskrit Theory',7,5,NULL,1,6,0,1,30,30,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(6,_binary '��e;\�mJL�\�bo�\�C','06_A_SCI_TH','Class VI(A) - Science Theory','Complete academic workload for Class VI(A) - Science Theory',7,6,NULL,1,6,0,1,30,10,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(7,_binary '\�\�foE�MB�R�~�\�\�','06_A_GK_TH','Class VI(A) - G.K. Theory','Complete academic workload for Class VI(A) - G.K. Theory',7,7,NULL,1,6,0,1,30,10,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(8,_binary '$S�Q\�:On�;�x�\�?�','06_A_COMP_TH','Class VI(A) - Computer Science Theory','Complete academic workload for Class VI(A) - Computer Science Theory',7,8,NULL,1,6,0,1,50,30,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(9,_binary 'b�\�\�\n�N��w4\�\n�y','06_A_COMP_PR','Class VI(A) - Computer Science Practical','Complete academic workload for Class VI(A) - Computer Science Practical',7,9,NULL,1,6,0,1,20,50,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(10,_binary '\�?!|�KY��\�Did\�','06_A_FRE_TH','Class VI(A) - French Theory','Complete academic workload for Class VI(A) - French Theory',7,10,NULL,1,6,0,1,60,90,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(11,_binary 'Z\'3\�LB��Чڌ\Z\�','06_A_LIB_LIB','Class VI(A) - Library Library','Complete academic workload for Class VI(A) - Library Library',7,11,NULL,1,6,0,1,10,60,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(12,_binary '\�X�$O\r�UCe�y�','06_A_VAL_TH','Class VI(A) - Value Education Theory','Complete academic workload for Class VI(A) - Value Education Theory',7,12,NULL,1,6,0,1,90,90,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(13,_binary '��ϒ��L{�}o7����','06_A_ART_ART','Class VI(A) - Art Art','Complete academic workload for Class VI(A) - Art Art',7,13,NULL,1,6,0,1,90,80,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(14,_binary 'S�D��\�K���\� 3t�\�','06_A_GAM_SPT','Class VI(A) - Games Sports','Complete academic workload for Class VI(A) - Games Sports',7,14,NULL,1,6,0,1,40,30,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(15,_binary '@�\�\�HM,�BM湺','06_A_ENGN_TH','Class VI(A) - English Novel Theory','Complete academic workload for Class VI(A) - English Novel Theory',7,15,NULL,1,6,0,1,20,20,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(16,_binary 'S�o��ND��y>]#]ݕ','06_A_ROB_LAB','Class VI(A) - Robotics Lab / Activity','Complete academic workload for Class VI(A) - Robotics Lab / Activity',7,16,NULL,1,6,0,1,10,10,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(17,_binary '6\�\�f\�N\Z�����*i�','06_A_AST_LAB','Class VI(A) - Astro Lab / Activity','Complete academic workload for Class VI(A) - Astro Lab / Activity',7,17,NULL,1,6,0,1,30,70,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(18,_binary 'ҜF\�\�jB8�Y#�)cR_','06_A_HOB_HOB','Class VI(A) - Hobby Hobby','Complete academic workload for Class VI(A) - Hobby Hobby',7,18,NULL,1,6,0,1,60,20,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(19,_binary '\�d\n\�\�I�ei\�\�y5','06_B_ENG_TH','Class VI(B) - English Theory','Complete academic workload for Class VI(B) - English Theory',7,19,NULL,1,6,0,1,70,100,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(20,_binary '\�Q\0\'H�\�f\�','06_B_HIN_TH','Class VI(B) - Hindi Theory','Complete academic workload for Class VI(B) - Hindi Theory',7,20,NULL,1,6,0,1,100,30,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(21,_binary '�\�\��M�z�\�0','06_B_MAT_TH','Class VI(B) - Maths Theory','Complete academic workload for Class VI(B) - Maths Theory',7,21,NULL,1,6,0,1,10,20,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(22,_binary '\�\�e�\�A6�\�\'�0l�','06_B_SOC_TH','Class VI(B) - Social Science Theory','Complete academic workload for Class VI(B) - Social Science Theory',7,22,NULL,1,6,0,1,20,40,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(23,_binary '�\'w\�*\�A���\�?��0','06_B_SAN_TH','Class VI(B) - Sanskrit Theory','Complete academic workload for Class VI(B) - Sanskrit Theory',7,23,NULL,1,6,0,1,50,20,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(24,_binary '*�P�>bB\r�|Đ����','06_B_SCI_TH','Class VI(B) - Science Theory','Complete academic workload for Class VI(B) - Science Theory',7,24,NULL,1,6,0,1,20,60,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(25,_binary '�\�����CE�^\�]#�','06_B_GK_TH','Class VI(B) - G.K. Theory','Complete academic workload for Class VI(B) - G.K. Theory',7,25,NULL,1,6,0,1,60,10,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(26,_binary ']�_\�\nA:��\�\�·Q','06_B_COMP_TH','Class VI(B) - Computer Science Theory','Complete academic workload for Class VI(B) - Computer Science Theory',7,26,NULL,1,6,0,1,40,100,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(27,_binary '�mꒄ�IR�A\�n�\�8','06_B_COMP_PR','Class VI(B) - Computer Science Practical','Complete academic workload for Class VI(B) - Computer Science Practical',7,27,NULL,1,6,0,1,40,40,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(28,_binary '\��l�\�zL�\�\�\�\�R$','06_B_FRE_TH','Class VI(B) - French Theory','Complete academic workload for Class VI(B) - French Theory',7,28,NULL,1,6,0,1,90,60,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(29,_binary '�s���4Oو~yGAV','06_B_LIB_LIB','Class VI(B) - Library Library','Complete academic workload for Class VI(B) - Library Library',7,29,NULL,1,6,0,1,50,60,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(30,_binary '\��\"�\�F^��-)��g','06_B_VAL_TH','Class VI(B) - Value Education Theory','Complete academic workload for Class VI(B) - Value Education Theory',7,30,NULL,1,6,0,1,90,30,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(31,_binary '�h\�s@,�7\�y\�\��','06_B_ART_ART','Class VI(B) - Art Art','Complete academic workload for Class VI(B) - Art Art',7,31,NULL,1,6,0,1,60,100,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(32,_binary '\��` YK��N�x2��','06_B_GAM_SPT','Class VI(B) - Games Sports','Complete academic workload for Class VI(B) - Games Sports',7,32,NULL,1,6,0,1,90,100,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(33,_binary '�m\�)\�LߜUx	\�fc','06_B_ENGN_TH','Class VI(B) - English Novel Theory','Complete academic workload for Class VI(B) - English Novel Theory',7,33,NULL,1,6,0,1,100,90,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(34,_binary '\�\�Rà�L��fgq<\�|','06_B_ROB_LAB','Class VI(B) - Robotics Lab / Activity','Complete academic workload for Class VI(B) - Robotics Lab / Activity',7,34,NULL,1,6,0,1,80,100,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(35,_binary '��\'�\0ZǴg`q','06_B_AST_LAB','Class VI(B) - Astro Lab / Activity','Complete academic workload for Class VI(B) - Astro Lab / Activity',7,35,NULL,1,6,0,1,70,100,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(36,_binary '̷<ꈰH��ir\n\�h','06_B_HOB_HOB','Class VI(B) - Hobby Hobby','Complete academic workload for Class VI(B) - Hobby Hobby',7,36,NULL,1,6,0,1,100,10,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(37,_binary '�\��\��0C��J��B��','07_A_ENG_TH','Class VII(A) - English Theory','Complete academic workload for Class VII(A) - English Theory',7,37,NULL,1,6,0,1,70,70,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(38,_binary '�\Z��@F���VKT8r','07_A_HIN_TH','Class VII(A) - Hindi Theory','Complete academic workload for Class VII(A) - Hindi Theory',7,38,NULL,1,6,0,1,100,30,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(39,_binary '_��M��B��t��3','07_A_MAT_TH','Class VII(A) - Maths Theory','Complete academic workload for Class VII(A) - Maths Theory',7,39,NULL,1,6,0,1,40,60,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(40,_binary '	;Y\"M��(\�\�>`\�','07_A_SOC_TH','Class VII(A) - Social Science Theory','Complete academic workload for Class VII(A) - Social Science Theory',7,40,NULL,1,6,0,1,40,10,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(41,_binary 'rE\��H�J\�r�\Z\0','07_A_SAN_TH','Class VII(A) - Sanskrit Theory','Complete academic workload for Class VII(A) - Sanskrit Theory',7,41,NULL,1,6,0,1,40,100,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(42,_binary '\\\�t3)\'L[�	\�\�͡#','07_A_SCI_TH','Class VII(A) - Science Theory','Complete academic workload for Class VII(A) - Science Theory',7,42,NULL,1,6,0,1,90,20,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(43,_binary '�\�k1\�OD�%��T�!�','07_A_GK_TH','Class VII(A) - G.K. Theory','Complete academic workload for Class VII(A) - G.K. Theory',7,43,NULL,1,6,0,1,100,90,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(44,_binary '�M~�:�M3�$����/','07_A_COMP_TH','Class VII(A) - Computer Science Theory','Complete academic workload for Class VII(A) - Computer Science Theory',7,44,NULL,1,6,0,1,40,60,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(45,_binary '�\��m\�\�F����)\�נ','07_A_COMP_PR','Class VII(A) - Computer Science Practical','Complete academic workload for Class VII(A) - Computer Science Practical',7,45,NULL,1,6,0,1,10,70,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(46,_binary '�\�\�\�?`H]�\�\r��\�\�d','07_A_FRE_TH','Class VII(A) - French Theory','Complete academic workload for Class VII(A) - French Theory',7,46,NULL,1,6,0,1,20,90,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(47,_binary '��\�*�F����\�\";X\�','07_A_LIB_LIB','Class VII(A) - Library Library','Complete academic workload for Class VII(A) - Library Library',7,47,NULL,1,6,0,1,70,20,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(48,_binary '�N�	\�\nF	��7O:s�l','07_A_VAL_TH','Class VII(A) - Value Education Theory','Complete academic workload for Class VII(A) - Value Education Theory',7,48,NULL,1,6,0,1,30,30,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(49,_binary 'ywFr�tM���8\�u\�\�','07_A_ART_ART','Class VII(A) - Art Art','Complete academic workload for Class VII(A) - Art Art',7,49,NULL,1,6,0,1,50,10,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(50,_binary '\r�\�\�)I��\�\�Q\�*','07_A_GAM_SPT','Class VII(A) - Games Sports','Complete academic workload for Class VII(A) - Games Sports',7,50,NULL,1,6,0,1,70,100,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(51,_binary 'Z5��8J	�\n9HK�','07_A_ENGN_TH','Class VII(A) - English Novel Theory','Complete academic workload for Class VII(A) - English Novel Theory',7,51,NULL,1,6,0,1,50,60,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(52,_binary '\���C��\�\�a\�\�','07_A_ROB_LAB','Class VII(A) - Robotics Lab / Activity','Complete academic workload for Class VII(A) - Robotics Lab / Activity',7,52,NULL,1,6,0,1,20,60,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(53,_binary 'D;\\h��K��\�X8�H','07_A_AST_LAB','Class VII(A) - Astro Lab / Activity','Complete academic workload for Class VII(A) - Astro Lab / Activity',7,53,NULL,1,6,0,1,100,40,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(54,_binary '�V_|6I\���<w�I\r�','07_A_HOB_HOB','Class VII(A) - Hobby Hobby','Complete academic workload for Class VII(A) - Hobby Hobby',7,54,NULL,1,6,0,1,40,30,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(55,_binary '1���+.A����)F���','07_B_ENG_TH','Class VII(B) - English Theory','Complete academic workload for Class VII(B) - English Theory',7,55,NULL,1,6,0,1,20,50,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(56,_binary '��\"B\�HI�\�g�\���\�','07_B_HIN_TH','Class VII(B) - Hindi Theory','Complete academic workload for Class VII(B) - Hindi Theory',7,56,NULL,1,6,0,1,60,60,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(57,_binary '\r;_\�\�;E��\�?5\��\�','07_B_MAT_TH','Class VII(B) - Maths Theory','Complete academic workload for Class VII(B) - Maths Theory',7,57,NULL,1,6,0,1,60,70,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(58,_binary '	C-\nFO\��\�\�i\�!\�','07_B_SOC_TH','Class VII(B) - Social Science Theory','Complete academic workload for Class VII(B) - Social Science Theory',7,58,NULL,1,6,0,1,70,70,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(59,_binary '.#\�v1AK�\�\� :c0','07_B_SAN_TH','Class VII(B) - Sanskrit Theory','Complete academic workload for Class VII(B) - Sanskrit Theory',7,59,NULL,1,6,0,1,80,10,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(60,_binary '\�\0/�PA&�\�1���e)','07_B_SCI_TH','Class VII(B) - Science Theory','Complete academic workload for Class VII(B) - Science Theory',7,60,NULL,1,6,0,1,80,20,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(61,_binary '�b\�_�@����\�mL','07_B_GK_TH','Class VII(B) - G.K. Theory','Complete academic workload for Class VII(B) - G.K. Theory',7,61,NULL,1,6,0,1,30,40,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(62,_binary '���l-\�K�;�-y\�#e','07_B_COMP_TH','Class VII(B) - Computer Science Theory','Complete academic workload for Class VII(B) - Computer Science Theory',7,62,NULL,1,6,0,1,40,100,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(63,_binary '\�>\�:x�K֩ϸF��1�','07_B_COMP_PR','Class VII(B) - Computer Science Practical','Complete academic workload for Class VII(B) - Computer Science Practical',7,63,NULL,1,6,0,1,20,70,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(64,_binary 'L\�\�\��G��~Z\�\�f��','07_B_FRE_TH','Class VII(B) - French Theory','Complete academic workload for Class VII(B) - French Theory',7,64,NULL,1,6,0,1,10,30,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(65,_binary '��A\�EL�\�$�&ܔ','07_B_LIB_LIB','Class VII(B) - Library Library','Complete academic workload for Class VII(B) - Library Library',7,65,NULL,1,6,0,1,10,60,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(66,_binary '!��ьlJB�\0O��\�','07_B_VAL_TH','Class VII(B) - Value Education Theory','Complete academic workload for Class VII(B) - Value Education Theory',7,66,NULL,1,6,0,1,80,30,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(67,_binary '=V[�\�J ��=XduX','07_B_ART_ART','Class VII(B) - Art Art','Complete academic workload for Class VII(B) - Art Art',7,67,NULL,1,6,0,1,20,10,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(68,_binary '\ry\"K��Q\�`lD','07_B_GAM_SPT','Class VII(B) - Games Sports','Complete academic workload for Class VII(B) - Games Sports',7,68,NULL,1,6,0,1,50,10,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(69,_binary '�\'\"l�C\�h�C-�?','07_B_ENGN_TH','Class VII(B) - English Novel Theory','Complete academic workload for Class VII(B) - English Novel Theory',7,69,NULL,1,6,0,1,50,40,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(70,_binary '�-}тM~��Y\�\�','07_B_ROB_LAB','Class VII(B) - Robotics Lab / Activity','Complete academic workload for Class VII(B) - Robotics Lab / Activity',7,70,NULL,1,6,0,1,80,50,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(71,_binary '�l\�\��\�B��[\�\�{ξ','07_B_AST_LAB','Class VII(B) - Astro Lab / Activity','Complete academic workload for Class VII(B) - Astro Lab / Activity',7,71,NULL,1,6,0,1,100,50,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(72,_binary '����	\�NI�E\���\�\�\�','07_B_HOB_HOB','Class VII(B) - Hobby Hobby','Complete academic workload for Class VII(B) - Hobby Hobby',7,72,NULL,1,6,0,1,20,100,1,1,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL);
/*!40000 ALTER TABLE `tt_activities` ENABLE KEYS */;
UNLOCK TABLES;
*/
--
-- Table structure for table `tt_activity_teachers`
--

DROP TABLE IF EXISTS `tt_activity_teachers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_activity_teachers`
--

LOCK TABLES `tt_activity_teachers` WRITE;
/*!40000 ALTER TABLE `tt_activity_teachers` DISABLE KEYS */;
INSERT INTO `tt_activity_teachers` VALUES (1,1,2,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(2,2,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(3,3,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(4,4,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(5,5,4,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(6,6,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(7,7,2,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(8,8,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(9,9,1,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(10,10,3,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(11,11,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(12,12,3,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(13,13,3,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(14,14,4,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(15,15,1,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(16,16,2,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(17,17,1,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(18,18,3,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(19,19,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(20,20,4,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(21,21,1,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(22,22,1,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(23,23,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(24,24,2,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(25,25,1,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(26,26,3,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(27,27,2,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(28,28,4,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(29,29,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(30,30,4,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(31,31,1,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(32,32,1,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(33,33,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(34,34,1,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(35,35,3,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(36,36,1,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(37,37,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(38,38,1,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(39,39,2,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(40,40,4,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(41,41,2,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(42,42,4,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(43,43,3,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(44,44,4,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(45,45,3,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(46,46,2,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(47,47,1,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(48,48,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(49,49,3,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(50,50,4,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(51,51,2,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(52,52,2,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(53,53,4,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(54,54,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(55,55,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(56,56,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(57,57,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(58,58,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(59,59,3,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(60,60,3,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(61,61,3,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(62,62,4,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(63,63,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(64,64,3,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(65,65,2,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(66,66,3,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(67,67,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(68,68,1,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(69,69,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(70,70,3,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(71,71,5,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(72,72,2,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL);
/*!40000 ALTER TABLE `tt_activity_teachers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_class_group_requirements`
--

DROP TABLE IF EXISTS `tt_class_group_requirements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_class_group_requirements`
--

LOCK TABLES `tt_class_group_requirements` WRITE;
/*!40000 ALTER TABLE `tt_class_group_requirements` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_class_group_requirements` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_class_groups_jnt`
--

DROP TABLE IF EXISTS `tt_class_groups_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_class_groups_jnt`
--

LOCK TABLES `tt_class_groups_jnt` WRITE;
/*!40000 ALTER TABLE `tt_class_groups_jnt` DISABLE KEYS */;
INSERT INTO `tt_class_groups_jnt` VALUES (1,1,1,1,1,9,'Class VI(A) - English Theory','06_A_ENG_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(2,1,1,2,1,9,'Class VI(A) - Hindi Theory','06_A_HIN_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(3,1,1,3,1,9,'Class VI(A) - Maths Theory','06_A_MAT_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(4,1,1,4,1,9,'Class VI(A) - Social Science Theory','06_A_SOC_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(5,1,1,5,1,9,'Class VI(A) - Sanskrit Theory','06_A_SAN_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(6,1,1,6,1,9,'Class VI(A) - Science Theory','06_A_SCI_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(7,1,1,7,1,9,'Class VI(A) - G.K. Theory','06_A_GK_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(8,1,1,8,1,9,'Class VI(A) - Computer Science Theory','06_A_COMP_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(9,1,1,9,1,9,'Class VI(A) - Computer Science Practical','06_A_COMP_PR',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(10,1,1,10,1,9,'Class VI(A) - French Theory','06_A_FRE_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(11,1,1,11,1,9,'Class VI(A) - Library Library','06_A_LIB_LIB',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(12,1,1,12,1,9,'Class VI(A) - Value Education Theory','06_A_VAL_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(13,1,1,13,1,9,'Class VI(A) - Art Art','06_A_ART_ART',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(14,1,1,14,1,9,'Class VI(A) - Games Sports','06_A_GAM_SPT',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(15,1,1,15,1,9,'Class VI(A) - English Novel Theory','06_A_ENGN_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(16,1,1,16,1,9,'Class VI(A) - Robotics Lab / Activity','06_A_ROB_LAB',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(17,1,1,17,1,9,'Class VI(A) - Astro Lab / Activity','06_A_AST_LAB',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(18,1,1,18,1,9,'Class VI(A) - Hobby Hobby','06_A_HOB_HOB',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(19,1,2,1,1,9,'Class VI(B) - English Theory','06_B_ENG_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(20,1,2,2,1,9,'Class VI(B) - Hindi Theory','06_B_HIN_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(21,1,2,3,1,9,'Class VI(B) - Maths Theory','06_B_MAT_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(22,1,2,4,1,9,'Class VI(B) - Social Science Theory','06_B_SOC_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(23,1,2,5,1,9,'Class VI(B) - Sanskrit Theory','06_B_SAN_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(24,1,2,6,1,9,'Class VI(B) - Science Theory','06_B_SCI_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(25,1,2,7,1,9,'Class VI(B) - G.K. Theory','06_B_GK_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(26,1,2,8,1,9,'Class VI(B) - Computer Science Theory','06_B_COMP_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(27,1,2,9,1,9,'Class VI(B) - Computer Science Practical','06_B_COMP_PR',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(28,1,2,10,1,9,'Class VI(B) - French Theory','06_B_FRE_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(29,1,2,11,1,9,'Class VI(B) - Library Library','06_B_LIB_LIB',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(30,1,2,12,1,9,'Class VI(B) - Value Education Theory','06_B_VAL_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(31,1,2,13,1,9,'Class VI(B) - Art Art','06_B_ART_ART',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(32,1,2,14,1,9,'Class VI(B) - Games Sports','06_B_GAM_SPT',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(33,1,2,15,1,9,'Class VI(B) - English Novel Theory','06_B_ENGN_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(34,1,2,16,1,9,'Class VI(B) - Robotics Lab / Activity','06_B_ROB_LAB',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(35,1,2,17,1,9,'Class VI(B) - Astro Lab / Activity','06_B_AST_LAB',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(36,1,2,18,1,9,'Class VI(B) - Hobby Hobby','06_B_HOB_HOB',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(37,2,1,1,1,9,'Class VII(A) - English Theory','07_A_ENG_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(38,2,1,2,1,9,'Class VII(A) - Hindi Theory','07_A_HIN_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(39,2,1,3,1,9,'Class VII(A) - Maths Theory','07_A_MAT_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(40,2,1,4,1,9,'Class VII(A) - Social Science Theory','07_A_SOC_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(41,2,1,5,1,9,'Class VII(A) - Sanskrit Theory','07_A_SAN_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(42,2,1,6,1,9,'Class VII(A) - Science Theory','07_A_SCI_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(43,2,1,7,1,9,'Class VII(A) - G.K. Theory','07_A_GK_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(44,2,1,8,1,9,'Class VII(A) - Computer Science Theory','07_A_COMP_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(45,2,1,9,1,9,'Class VII(A) - Computer Science Practical','07_A_COMP_PR',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(46,2,1,10,1,9,'Class VII(A) - French Theory','07_A_FRE_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(47,2,1,11,1,9,'Class VII(A) - Library Library','07_A_LIB_LIB',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(48,2,1,12,1,9,'Class VII(A) - Value Education Theory','07_A_VAL_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(49,2,1,13,1,9,'Class VII(A) - Art Art','07_A_ART_ART',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(50,2,1,14,1,9,'Class VII(A) - Games Sports','07_A_GAM_SPT',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(51,2,1,15,1,9,'Class VII(A) - English Novel Theory','07_A_ENGN_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(52,2,1,16,1,9,'Class VII(A) - Robotics Lab / Activity','07_A_ROB_LAB',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(53,2,1,17,1,9,'Class VII(A) - Astro Lab / Activity','07_A_AST_LAB',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(54,2,1,18,1,9,'Class VII(A) - Hobby Hobby','07_A_HOB_HOB',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(55,2,2,1,1,9,'Class VII(B) - English Theory','07_B_ENG_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(56,2,2,2,1,9,'Class VII(B) - Hindi Theory','07_B_HIN_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(57,2,2,3,1,9,'Class VII(B) - Maths Theory','07_B_MAT_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(58,2,2,4,1,9,'Class VII(B) - Social Science Theory','07_B_SOC_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(59,2,2,5,1,9,'Class VII(B) - Sanskrit Theory','07_B_SAN_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(60,2,2,6,1,9,'Class VII(B) - Science Theory','07_B_SCI_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(61,2,2,7,1,9,'Class VII(B) - G.K. Theory','07_B_GK_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(62,2,2,8,1,9,'Class VII(B) - Computer Science Theory','07_B_COMP_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(63,2,2,9,1,9,'Class VII(B) - Computer Science Practical','07_B_COMP_PR',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(64,2,2,10,1,9,'Class VII(B) - French Theory','07_B_FRE_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(65,2,2,11,1,9,'Class VII(B) - Library Library','07_B_LIB_LIB',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(66,2,2,12,1,9,'Class VII(B) - Value Education Theory','07_B_VAL_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(67,2,2,13,1,9,'Class VII(B) - Art Art','07_B_ART_ART',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(68,2,2,14,1,9,'Class VII(B) - Games Sports','07_B_GAM_SPT',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(69,2,2,15,1,9,'Class VII(B) - English Novel Theory','07_B_ENGN_TH',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(70,2,2,16,1,9,'Class VII(B) - Robotics Lab / Activity','07_B_ROB_LAB',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(71,2,2,17,1,9,'Class VII(B) - Astro Lab / Activity','07_B_AST_LAB',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09'),(72,2,2,18,1,9,'Class VII(B) - Hobby Hobby','07_B_HOB_HOB',1,NULL,'2026-02-01 06:04:09','2026-02-01 06:04:09');
/*!40000 ALTER TABLE `tt_class_groups_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_class_mode_rules`
--

DROP TABLE IF EXISTS `tt_class_mode_rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_class_mode_rules`
--

LOCK TABLES `tt_class_mode_rules` WRITE;
/*!40000 ALTER TABLE `tt_class_mode_rules` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_class_mode_rules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_class_subgroup_members`
--

DROP TABLE IF EXISTS `tt_class_subgroup_members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_class_subgroup_members`
--

LOCK TABLES `tt_class_subgroup_members` WRITE;
/*!40000 ALTER TABLE `tt_class_subgroup_members` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_class_subgroup_members` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_class_subgroups`
--

DROP TABLE IF EXISTS `tt_class_subgroups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_class_subgroups`
--

LOCK TABLES `tt_class_subgroups` WRITE;
/*!40000 ALTER TABLE `tt_class_subgroups` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_class_subgroups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_constraint_types`
--

DROP TABLE IF EXISTS `tt_constraint_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_constraint_types`
--

LOCK TABLES `tt_constraint_types` WRITE;
/*!40000 ALTER TABLE `tt_constraint_types` DISABLE KEYS */;
INSERT INTO `tt_constraint_types` VALUES (1,'TEACHER_NOT_AVAILABLE','Teacher Not Available','Teacher is unavailable during specific days or periods','TEACHER','TEACHER',100,1,'{\"days\": {\"type\": \"array\", \"label\": \"Unavailable Days\", \"required\": true}, \"periods\": {\"type\": \"array\", \"label\": \"Unavailable Periods\", \"required\": false}}',1,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(2,'NO_TEACHER_GAPS','No Gaps for Teacher','Avoid idle gaps between teacher lessons','TEACHER','TEACHER',70,0,NULL,1,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(3,'MAX_LESSONS_PER_DAY','Maximum Lessons Per Day','Limits the number of lessons per day','TIME','CLASS',80,0,'{\"max_lessons\": {\"min\": 1, \"type\": \"integer\", \"label\": \"Maximum Lessons\", \"required\": true}}',1,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(4,'NO_CONSECUTIVE_SAME_SUBJECT','No Consecutive Same Subject','Avoid scheduling the same subject consecutively','STUDENT','CLASS_SUBJECT',60,0,NULL,1,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(5,'ROOM_CAPACITY_LIMIT','Room Capacity Limit','Room must have sufficient capacity','ROOM','ROOM',100,1,'{\"min_capacity\": {\"min\": 1, \"type\": \"integer\", \"label\": \"Minimum Capacity\", \"required\": true}}',1,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(6,'LUNCH_BREAK_FIXED','Lunch Break (Fixed)','Lunch break period must not contain any teaching activity','TIME','GLOBAL',100,1,'{\"period_type_code\": {\"type\": \"string\", \"allowed\": [\"LUNCH\"], \"required\": true}}',1,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(7,'SHORT_BREAK_FIXED','Short Break (Fixed)','Short break periods must not contain any teaching activity','TIME','GLOBAL',100,1,'{\"period_type_code\": {\"type\": \"string\", \"allowed\": [\"BREAK\"], \"required\": true}}',1,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(8,'ACTIVITY_TIME_WINDOW','Activity Time Window','Activity must be scheduled within a time range','TIME','ACTIVITY',90,1,'{\"end_time\": {\"type\": \"time\", \"label\": \"End Time\", \"required\": true}, \"start_time\": {\"type\": \"time\", \"label\": \"Start Time\", \"required\": true}}',1,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL);
/*!40000 ALTER TABLE `tt_constraint_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_constraints`
--

DROP TABLE IF EXISTS `tt_constraints`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_constraints`
--

LOCK TABLES `tt_constraints` WRITE;
/*!40000 ALTER TABLE `tt_constraints` DISABLE KEYS */;
INSERT INTO `tt_constraints` VALUES (1,_binary '�j7\�yiC��ʹ�� �',3,'Max Lessons Per Day (Global)','Limits maximum lessons per day for all classes',7,'GLOBAL',NULL,0,80,'{\"max_lessons\": 6}',NULL,NULL,'[\"MON\", \"TUE\", \"WED\", \"THU\", \"FRI\"]','ACTIVE',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(2,_binary '\Z\�-�\��F��	ш\�\�\�',6,'Lunch Break (No Teaching)','Lunch break must not contain any teaching activity',7,'GLOBAL',NULL,1,100,'{\"period_type_code\": \"LUNCH\"}',NULL,NULL,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(3,_binary '�^\�\�dqI��VU򖒼y',7,'Short Break (No Teaching)','Short break periods must not contain teaching activity',7,'GLOBAL',NULL,1,100,'{\"period_type_code\": \"BREAK\"}',NULL,NULL,NULL,'ACTIVE',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(4,_binary '�k�^\�K��2\r��\�2',1,'Teacher Unavailable on Monday','Teacher not available on Monday periods',7,'TEACHER',1,1,100,'{\"days\": [\"MON\"], \"periods\": []}',NULL,NULL,'[\"MON\"]','ACTIVE',1,NULL,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL);
/*!40000 ALTER TABLE `tt_constraints` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_day_types`
--

DROP TABLE IF EXISTS `tt_day_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_day_types`
--

LOCK TABLES `tt_day_types` WRITE;
/*!40000 ALTER TABLE `tt_day_types` DISABLE KEYS */;
INSERT INTO `tt_day_types` VALUES (1,'WD','Working Day','Regular full working academic day',1,0,1,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(2,'HD','Half Day','Working day with reduced periods',1,1,2,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(3,'SD','Short Day','Shortened timetable due to special conditions',1,1,3,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(4,'EX','Exam Day','Examination day (no regular teaching)',1,0,4,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(5,'PTM','PTM Day','Parent Teacher Meeting day',0,0,5,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(6,'H','Holiday','School closed for holiday',0,0,6,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(7,'F','Festival','Festival holiday',0,0,7,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(8,'PD','Preparation Day','Teacher preparation or training day',0,0,8,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(9,'EM','Emergency Closure','Emergency closure (weather, safety)',0,0,9,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL);
/*!40000 ALTER TABLE `tt_day_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_days`
--

DROP TABLE IF EXISTS `tt_days`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_days`
--

LOCK TABLES `tt_days` WRITE;
/*!40000 ALTER TABLE `tt_days` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_days` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_generation_runs`
--

DROP TABLE IF EXISTS `tt_generation_runs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_generation_runs`
--

LOCK TABLES `tt_generation_runs` WRITE;
/*!40000 ALTER TABLE `tt_generation_runs` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_generation_runs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_period_set_period_jnt`
--

DROP TABLE IF EXISTS `tt_period_set_period_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_period_set_period_jnt`
--

LOCK TABLES `tt_period_set_period_jnt` WRITE;
/*!40000 ALTER TABLE `tt_period_set_period_jnt` DISABLE KEYS */;
INSERT INTO `tt_period_set_period_jnt` (`id`, `period_set_id`, `period_type_id`, `code`, `short_name`, `period_ord`, `start_time`, `end_time`, `is_active`, `created_at`, `updated_at`, `deleted_at`) VALUES (1,4,2,'P1','1',1,'08:00:00','08:45:00',1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(2,4,2,'P2','2',2,'08:45:00','09:30:00',1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(3,4,2,'P3','3',3,'09:30:00','10:15:00',1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(4,4,3,'P4','4',4,'10:30:00','11:15:00',1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(5,4,2,'P5','5',5,'11:15:00','12:00:00',1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(6,4,4,'P6','6',6,'12:30:00','13:15:00',1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(7,4,3,'P7','7',7,'13:15:00','14:00:00',1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(8,4,2,'P8','8',8,'14:00:00','14:40:00',1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL);
/*!40000 ALTER TABLE `tt_period_set_period_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_period_sets`
--

DROP TABLE IF EXISTS `tt_period_sets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_period_sets`
--

LOCK TABLES `tt_period_sets` WRITE;
/*!40000 ALTER TABLE `tt_period_sets` DISABLE KEYS */;
INSERT INTO `tt_period_sets` VALUES (1,'PRE_PRIMARY_5','Pre-Primary (5 Periods)','Nursery, LKG, UKG – oral, activity-based shorter day',5,5,'08:30:00','12:00:00','[-2, -1, 0]',0,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(2,'PRIMARY_6','Primary School (6 Periods)','Classes 1–5 with balanced academics and activities',6,6,'08:30:00','13:30:00','[1, 2, 3, 4, 5]',0,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(3,'MIDDLE_7','Middle School (7 Periods)','Classes 6–8 with theory + labs + activities',7,7,'08:00:00','14:00:00','[6, 7, 8]',0,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(4,'SECONDARY_8','Secondary School (8 Periods)','Classes 9–10 with theory + practical focus',8,8,'08:00:00','14:40:00','[9, 10]',1,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(5,'SENIOR_9','Senior Secondary (9 Periods)','Classes 11–12 with extended practical & lab sessions',9,9,'08:00:00','15:30:00','[11, 12]',0,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL),(6,'HALF_DAY_4','Half Day (4 Periods)','Events, exams, PTMs, special schedules',4,4,'08:00:00','11:30:00',NULL,0,1,'2026-02-01 06:04:08','2026-02-01 06:04:08',NULL);
/*!40000 ALTER TABLE `tt_period_sets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_period_types`
--

DROP TABLE IF EXISTS `tt_period_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_period_types`
--

LOCK TABLES `tt_period_types` WRITE;
/*!40000 ALTER TABLE `tt_period_types` DISABLE KEYS */;
INSERT INTO `tt_period_types` VALUES (1,'ORAL','Oral Class','Oral-based teaching (Nursery, LKG, UKG)',NULL,NULL,1,1,0,0,1,1,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(2,'THEORY','Theory / Lecture','Standard classroom lecture',NULL,NULL,1,1,0,0,1,1,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(3,'PRACTICAL','Practical / Lab','Lab or hands-on practical session',NULL,NULL,1,1,0,0,1,1,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(4,'ACTIVITY','Activity','Games, Art, Music, Dance, Yoga, Hobby',NULL,NULL,1,1,0,0,1,1,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(5,'LIBRARY','Library Period','Reading / Library-based learning',NULL,NULL,1,1,0,0,1,1,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(6,'BREAK','Short Break','Short recess break',NULL,NULL,1,0,0,0,1,1,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(7,'LUNCH','Lunch Break','Lunch / mid-day break',NULL,NULL,1,0,0,0,1,1,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL);
/*!40000 ALTER TABLE `tt_period_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_periods`
--

DROP TABLE IF EXISTS `tt_periods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_periods`
--

LOCK TABLES `tt_periods` WRITE;
/*!40000 ALTER TABLE `tt_periods` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_periods` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_room_unavailables`
--

DROP TABLE IF EXISTS `tt_room_unavailables`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_room_unavailables`
--

LOCK TABLES `tt_room_unavailables` WRITE;
/*!40000 ALTER TABLE `tt_room_unavailables` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_room_unavailables` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_school_days`
--

DROP TABLE IF EXISTS `tt_school_days`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_school_days`
--

LOCK TABLES `tt_school_days` WRITE;
/*!40000 ALTER TABLE `tt_school_days` DISABLE KEYS */;
INSERT INTO `tt_school_days` VALUES (1,'MON','Monday','Mon',1,1,1,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(2,'TUE','Tuesday','Tue',2,2,1,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(3,'WED','Wednesday','Wed',3,3,1,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(4,'THU','Thursday','Thu',4,4,1,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(5,'FRI','Friday','Fri',5,5,1,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(6,'SAT','Saturday','Sat',6,6,1,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL),(7,'SUN','Sunday','Sun',7,7,0,1,'2026-02-01 06:04:07','2026-02-01 06:04:07',NULL);
/*!40000 ALTER TABLE `tt_school_days` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_shifts`
--

DROP TABLE IF EXISTS `tt_shifts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_shifts`
--

LOCK TABLES `tt_shifts` WRITE;
/*!40000 ALTER TABLE `tt_shifts` DISABLE KEYS */;
INSERT INTO `tt_shifts` VALUES (1,'MORNING','Morning Shift','Regular morning academic shift','08:00:00','14:00:00',1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(2,'AFTERNOON','Afternoon Shift','Post-lunch academic shift','12:00:00','18:00:00',2,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(3,'EVENING','Evening Shift','Sports, activities, and special classes','16:00:00','20:00:00',3,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL);
/*!40000 ALTER TABLE `tt_shifts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_sub_activities`
--

DROP TABLE IF EXISTS `tt_sub_activities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_sub_activities`
--

LOCK TABLES `tt_sub_activities` WRITE;
/*!40000 ALTER TABLE `tt_sub_activities` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_sub_activities` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_teacher_assignment_roles`
--

DROP TABLE IF EXISTS `tt_teacher_assignment_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_teacher_assignment_roles`
--

LOCK TABLES `tt_teacher_assignment_roles` WRITE;
/*!40000 ALTER TABLE `tt_teacher_assignment_roles` DISABLE KEYS */;
INSERT INTO `tt_teacher_assignment_roles` VALUES (1,'PRIMARY','Primary Instructor','Main teacher responsible for the activity',1,1,0,1.00,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(2,'ASSISTANT','Assistant Teacher','Supports the primary instructor',0,1,1,0.50,2,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(3,'CO_INSTRUCTOR','Co-Instructor','Shares teaching responsibility equally',0,1,0,1.00,3,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(4,'OBSERVER','Observer','Observes the class without teaching responsibility',0,0,1,0.00,4,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(5,'CO_TEACHER','Co-Teacher','Shares teaching responsibility equally',0,1,0,1.00,3,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(6,'SUBSTITUTE','Substitute Teacher','Temporarily replaces the primary instructor',1,1,0,1.00,5,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL);
/*!40000 ALTER TABLE `tt_teacher_assignment_roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_teacher_unavailables`
--

DROP TABLE IF EXISTS `tt_teacher_unavailables`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_teacher_unavailables`
--

LOCK TABLES `tt_teacher_unavailables` WRITE;
/*!40000 ALTER TABLE `tt_teacher_unavailables` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_teacher_unavailables` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_timetable_cell_teachers`
--

DROP TABLE IF EXISTS `tt_timetable_cell_teachers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_timetable_cell_teachers`
--

LOCK TABLES `tt_timetable_cell_teachers` WRITE;
/*!40000 ALTER TABLE `tt_timetable_cell_teachers` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_timetable_cell_teachers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_timetable_cells`
--

DROP TABLE IF EXISTS `tt_timetable_cells`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_timetable_cells`
--

LOCK TABLES `tt_timetable_cells` WRITE;
/*!40000 ALTER TABLE `tt_timetable_cells` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_timetable_cells` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_timetable_modes`
--

DROP TABLE IF EXISTS `tt_timetable_modes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_timetable_modes`
--

LOCK TABLES `tt_timetable_modes` WRITE;
/*!40000 ALTER TABLE `tt_timetable_modes` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_timetable_modes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_timetable_types`
--

DROP TABLE IF EXISTS `tt_timetable_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_timetable_types`
--

LOCK TABLES `tt_timetable_types` WRITE;
/*!40000 ALTER TABLE `tt_timetable_types` DISABLE KEYS */;
INSERT INTO `tt_timetable_types` VALUES (1,'REGULAR','Regular School Day','Standard teaching day with classes and breaks',NULL,NULL,NULL,NULL,NULL,'08:00:00','14:30:00',15,10,30,0,1,1,1,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL),(2,'EXAM','Examination Day','Exam-focused timetable with no regular teaching periods',NULL,NULL,NULL,NULL,NULL,'09:00:00','13:00:00',NULL,NULL,NULL,1,0,2,0,1,1,'2026-02-01 06:04:09','2026-02-01 06:04:09',NULL);
/*!40000 ALTER TABLE `tt_timetable_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_timetables`
--

DROP TABLE IF EXISTS `tt_timetables`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_timetables`
--

LOCK TABLES `tt_timetables` WRITE;
/*!40000 ALTER TABLE `tt_timetables` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_timetables` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_timing_profile`
--

DROP TABLE IF EXISTS `tt_timing_profile`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_timing_profile`
--

LOCK TABLES `tt_timing_profile` WRITE;
/*!40000 ALTER TABLE `tt_timing_profile` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_timing_profile` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_timing_profile_period`
--

DROP TABLE IF EXISTS `tt_timing_profile_period`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_timing_profile_period`
--

LOCK TABLES `tt_timing_profile_period` WRITE;
/*!40000 ALTER TABLE `tt_timing_profile_period` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_timing_profile_period` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tt_working_day`
--

DROP TABLE IF EXISTS `tt_working_day`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tt_working_day`
--

LOCK TABLES `tt_working_day` WRITE;
/*!40000 ALTER TABLE `tt_working_day` DISABLE KEYS */;
/*!40000 ALTER TABLE `tt_working_day` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vnd_agreement_items_jnt`
--

DROP TABLE IF EXISTS `vnd_agreement_items_jnt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vnd_agreement_items_jnt`
--

LOCK TABLES `vnd_agreement_items_jnt` WRITE;
/*!40000 ALTER TABLE `vnd_agreement_items_jnt` DISABLE KEYS */;
/*!40000 ALTER TABLE `vnd_agreement_items_jnt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vnd_agreements`
--

DROP TABLE IF EXISTS `vnd_agreements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vnd_agreements`
--

LOCK TABLES `vnd_agreements` WRITE;
/*!40000 ALTER TABLE `vnd_agreements` DISABLE KEYS */;
/*!40000 ALTER TABLE `vnd_agreements` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vnd_invoices`
--

DROP TABLE IF EXISTS `vnd_invoices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vnd_invoices`
--

LOCK TABLES `vnd_invoices` WRITE;
/*!40000 ALTER TABLE `vnd_invoices` DISABLE KEYS */;
/*!40000 ALTER TABLE `vnd_invoices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vnd_items`
--

DROP TABLE IF EXISTS `vnd_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vnd_items`
--

LOCK TABLES `vnd_items` WRITE;
/*!40000 ALTER TABLE `vnd_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `vnd_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vnd_payments`
--

DROP TABLE IF EXISTS `vnd_payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vnd_payments`
--

LOCK TABLES `vnd_payments` WRITE;
/*!40000 ALTER TABLE `vnd_payments` DISABLE KEYS */;
/*!40000 ALTER TABLE `vnd_payments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vnd_usage_logs`
--

DROP TABLE IF EXISTS `vnd_usage_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vnd_usage_logs`
--

LOCK TABLES `vnd_usage_logs` WRITE;
/*!40000 ALTER TABLE `vnd_usage_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `vnd_usage_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vnd_vendors`
--

DROP TABLE IF EXISTS `vnd_vendors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vnd_vendors`
--

LOCK TABLES `vnd_vendors` WRITE;
/*!40000 ALTER TABLE `vnd_vendors` DISABLE KEYS */;
/*!40000 ALTER TABLE `vnd_vendors` ENABLE KEYS */;
UNLOCK TABLES;



--
-- Dumping routines for database 'tenant_51b5ee16-d582-4568-ab8f-d4137106c752'
--

--
-- Final view structure for view `glb_cities`
--

/*!50001 DROP VIEW IF EXISTS `glb_cities`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `glb_cities` AS select `global_master`.`glb_cities`.`id` AS `id`,`global_master`.`glb_cities`.`district_id` AS `district_id`,`global_master`.`glb_cities`.`name` AS `name`,`global_master`.`glb_cities`.`short_name` AS `short_name`,`global_master`.`glb_cities`.`global_code` AS `global_code`,`global_master`.`glb_cities`.`default_timezone` AS `default_timezone`,`global_master`.`glb_cities`.`is_active` AS `is_active`,`global_master`.`glb_cities`.`created_at` AS `created_at`,`global_master`.`glb_cities`.`updated_at` AS `updated_at`,`global_master`.`glb_cities`.`deleted_at` AS `deleted_at` from `global_master`.`glb_cities` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `glb_countries`
--

/*!50001 DROP VIEW IF EXISTS `glb_countries`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `glb_countries` AS select `global_master`.`glb_countries`.`id` AS `id`,`global_master`.`glb_countries`.`name` AS `name`,`global_master`.`glb_countries`.`short_name` AS `short_name`,`global_master`.`glb_countries`.`global_code` AS `global_code`,`global_master`.`glb_countries`.`currency_code` AS `currency_code`,`global_master`.`glb_countries`.`is_active` AS `is_active`,`global_master`.`glb_countries`.`created_at` AS `created_at`,`global_master`.`glb_countries`.`updated_at` AS `updated_at`,`global_master`.`glb_countries`.`deleted_at` AS `deleted_at` from `global_master`.`glb_countries` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `glb_districts`
--

/*!50001 DROP VIEW IF EXISTS `glb_districts`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `glb_districts` AS select `global_master`.`glb_districts`.`id` AS `id`,`global_master`.`glb_districts`.`state_id` AS `state_id`,`global_master`.`glb_districts`.`name` AS `name`,`global_master`.`glb_districts`.`short_name` AS `short_name`,`global_master`.`glb_districts`.`global_code` AS `global_code`,`global_master`.`glb_districts`.`is_active` AS `is_active`,`global_master`.`glb_districts`.`created_at` AS `created_at`,`global_master`.`glb_districts`.`updated_at` AS `updated_at`,`global_master`.`glb_districts`.`deleted_at` AS `deleted_at` from `global_master`.`glb_districts` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `glb_languages`
--

/*!50001 DROP VIEW IF EXISTS `glb_languages`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `glb_languages` AS select `global_master`.`glb_languages`.`id` AS `id`,`global_master`.`glb_languages`.`code` AS `code`,`global_master`.`glb_languages`.`name` AS `name`,`global_master`.`glb_languages`.`native_name` AS `native_name`,`global_master`.`glb_languages`.`direction` AS `direction`,`global_master`.`glb_languages`.`is_active` AS `is_active`,`global_master`.`glb_languages`.`deleted_at` AS `deleted_at`,`global_master`.`glb_languages`.`created_at` AS `created_at`,`global_master`.`glb_languages`.`updated_at` AS `updated_at` from `global_master`.`glb_languages` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `glb_menu_module_jnt`
--

/*!50001 DROP VIEW IF EXISTS `glb_menu_module_jnt`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `glb_menu_module_jnt` AS select `global_master`.`glb_menu_module_jnt`.`id` AS `id`,`global_master`.`glb_menu_module_jnt`.`menu_id` AS `menu_id`,`global_master`.`glb_menu_module_jnt`.`module_id` AS `module_id`,`global_master`.`glb_menu_module_jnt`.`sort_order` AS `sort_order`,`global_master`.`glb_menu_module_jnt`.`created_at` AS `created_at`,`global_master`.`glb_menu_module_jnt`.`updated_at` AS `updated_at` from `global_master`.`glb_menu_module_jnt` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `glb_menus`
--

/*!50001 DROP VIEW IF EXISTS `glb_menus`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `glb_menus` AS select `global_master`.`glb_menus`.`id` AS `id`,`global_master`.`glb_menus`.`parent_id` AS `parent_id`,`global_master`.`glb_menus`.`is_category` AS `is_category`,`global_master`.`glb_menus`.`code` AS `code`,`global_master`.`glb_menus`.`menu_for` AS `menu_for`,`global_master`.`glb_menus`.`slug` AS `slug`,`global_master`.`glb_menus`.`title` AS `title`,`global_master`.`glb_menus`.`description` AS `description`,`global_master`.`glb_menus`.`icon` AS `icon`,`global_master`.`glb_menus`.`route` AS `route`,`global_master`.`glb_menus`.`permission` AS `permission`,`global_master`.`glb_menus`.`sort_order` AS `sort_order`,`global_master`.`glb_menus`.`visible_by_default` AS `visible_by_default`,`global_master`.`glb_menus`.`is_active` AS `is_active`,`global_master`.`glb_menus`.`deleted_at` AS `deleted_at`,`global_master`.`glb_menus`.`created_at` AS `created_at`,`global_master`.`glb_menus`.`updated_at` AS `updated_at` from `global_master`.`glb_menus` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `glb_modules`
--

/*!50001 DROP VIEW IF EXISTS `glb_modules`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `glb_modules` AS select `global_master`.`glb_modules`.`id` AS `id`,`global_master`.`glb_modules`.`parent_id` AS `parent_id`,`global_master`.`glb_modules`.`name` AS `name`,`global_master`.`glb_modules`.`version` AS `version`,`global_master`.`glb_modules`.`is_sub_module` AS `is_sub_module`,`global_master`.`glb_modules`.`description` AS `description`,`global_master`.`glb_modules`.`is_core` AS `is_core`,`global_master`.`glb_modules`.`default_visible` AS `default_visible`,`global_master`.`glb_modules`.`available_perm_view` AS `available_perm_view`,`global_master`.`glb_modules`.`available_perm_add` AS `available_perm_add`,`global_master`.`glb_modules`.`available_perm_edit` AS `available_perm_edit`,`global_master`.`glb_modules`.`available_perm_delete` AS `available_perm_delete`,`global_master`.`glb_modules`.`available_perm_export` AS `available_perm_export`,`global_master`.`glb_modules`.`available_perm_import` AS `available_perm_import`,`global_master`.`glb_modules`.`available_perm_print` AS `available_perm_print`,`global_master`.`glb_modules`.`is_active` AS `is_active`,`global_master`.`glb_modules`.`deleted_at` AS `deleted_at`,`global_master`.`glb_modules`.`created_at` AS `created_at`,`global_master`.`glb_modules`.`updated_at` AS `updated_at` from `global_master`.`glb_modules` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `glb_states`
--

/*!50001 DROP VIEW IF EXISTS `glb_states`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `glb_states` AS select `global_master`.`glb_states`.`id` AS `id`,`global_master`.`glb_states`.`country_id` AS `country_id`,`global_master`.`glb_states`.`name` AS `name`,`global_master`.`glb_states`.`short_name` AS `short_name`,`global_master`.`glb_states`.`global_code` AS `global_code`,`global_master`.`glb_states`.`is_active` AS `is_active`,`global_master`.`glb_states`.`created_at` AS `created_at`,`global_master`.`glb_states`.`updated_at` AS `updated_at`,`global_master`.`glb_states`.`deleted_at` AS `deleted_at` from `global_master`.`glb_states` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `glb_translations`
--

/*!50001 DROP VIEW IF EXISTS `glb_translations`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `glb_translations` AS select `global_master`.`glb_translations`.`id` AS `id`,`global_master`.`glb_translations`.`translatable_type` AS `translatable_type`,`global_master`.`glb_translations`.`translatable_id` AS `translatable_id`,`global_master`.`glb_translations`.`language_id` AS `language_id`,`global_master`.`glb_translations`.`key` AS `key`,`global_master`.`glb_translations`.`value` AS `value`,`global_master`.`glb_translations`.`created_at` AS `created_at`,`global_master`.`glb_translations`.`updated_at` AS `updated_at` from `global_master`.`glb_translations` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-01 11:38:33
