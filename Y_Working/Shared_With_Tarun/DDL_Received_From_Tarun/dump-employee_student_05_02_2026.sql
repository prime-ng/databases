-- MySQL dump 10.13  Distrib 8.0.45, for Linux (x86_64)
--
-- Host: localhost    Database: tenant_5c04d817-624f-49c8-97ca-1ea4cdf9d580
-- ------------------------------------------------------
-- Server version	8.0.45-0ubuntu0.22.04.1

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
-- Table structure for table `sch_employees_profile`
--

DROP TABLE IF EXISTS `sch_employees_profile`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sch_employees_profile` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `employee_id` INT unsigned NOT NULL,
  `user_id` INT unsigned NOT NULL,
  `role_id` INT unsigned NOT NULL,
  `department_id` INT unsigned DEFAULT NULL,
  `specialization_area` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `qualification_level` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `qualification_field` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `certifications` json DEFAULT NULL,
  `work_hours_daily` decimal(4,2) NOT NULL DEFAULT '8.00',
  `max_hours_daily` decimal(4,2) NOT NULL DEFAULT '10.00',
  `work_hours_weekly` decimal(5,2) NOT NULL DEFAULT '40.00',
  `max_hours_weekly` decimal(5,2) NOT NULL DEFAULT '50.00',
  `preferred_shift` enum('morning','evening','flexible') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'morning',
  `is_full_time` tinyint(1) NOT NULL DEFAULT '1',
  `core_responsibilities` json DEFAULT NULL,
  `technical_skills` json DEFAULT NULL,
  `soft_skills` json DEFAULT NULL,
  `experience_months` smallint unsigned DEFAULT NULL,
  `performance_rating` tinyint unsigned DEFAULT NULL,
  `last_performance_review` date DEFAULT NULL,
  `security_clearance_done` tinyint(1) NOT NULL DEFAULT '0',
  `reporting_to` INT unsigned DEFAULT NULL,
  `can_approve_budget` tinyint(1) NOT NULL DEFAULT '0',
  `can_manage_staff` tinyint(1) NOT NULL DEFAULT '0',
  `can_access_sensitive_data` tinyint(1) NOT NULL DEFAULT '0',
  `assignment_meta` json DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `effective_from` date DEFAULT NULL,
  `effective_to` date DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_employee_role_active` (`employee_id`,`role_id`,`effective_to`),
  KEY `sch_employees_profile_role_id_foreign` (`role_id`),
  KEY `sch_employees_profile_department_id_foreign` (`department_id`),
  KEY `sch_employees_profile_reporting_to_foreign` (`reporting_to`),
  CONSTRAINT `sch_employees_profile_department_id_foreign` FOREIGN KEY (`department_id`) REFERENCES `sch_department` (`id`) ON DELETE SET NULL,
  CONSTRAINT `sch_employees_profile_employee_id_foreign` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`) ON DELETE CASCADE,
  CONSTRAINT `sch_employees_profile_reporting_to_foreign` FOREIGN KEY (`reporting_to`) REFERENCES `sch_employees` (`id`) ON DELETE SET NULL,
  CONSTRAINT `sch_employees_profile_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_employees_profile`
--

LOCK TABLES `sch_employees_profile` WRITE;
/*!40000 ALTER TABLE `sch_employees_profile` DISABLE KEYS */;
INSERT INTO `sch_employees_profile` VALUES (1,1,5,4,NULL,'Geoscientists','Graduate','Arts',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,153,5,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(2,2,6,4,NULL,'Central Office','Graduate','Arts',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,72,4,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(3,3,7,4,NULL,'Ambulance Driver','Post Graduate','Maths',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,184,3,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(4,4,8,4,NULL,'Textile Knitting Machine Operator','Post Graduate','Arts',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,154,3,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(5,5,9,4,NULL,'Real Estate Association Manager','Post Graduate','Maths',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,257,5,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(6,6,10,4,3,'Nuclear Equipment Operation Technician','Graduate','Commerce',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,72,3,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(7,7,11,4,11,'Biologist','Doctorate','Maths',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,159,5,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(8,8,12,4,NULL,'Dragline Operator','Doctorate','Commerce',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,271,4,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(9,9,13,4,NULL,'Environmental Science Teacher','Post Graduate','Maths',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,197,4,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(10,10,14,4,10,'Director Religious Activities','Doctorate','Science',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,290,5,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(11,11,15,4,NULL,'HR Specialist','Post Graduate','Maths',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,64,5,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(12,12,16,4,NULL,'Printing Machine Operator','Doctorate','Maths',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,263,5,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(13,13,17,4,NULL,'Park Naturalist','Doctorate','Arts',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,112,4,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(14,14,18,4,NULL,'Aircraft Cargo Handling Supervisor','Post Graduate','Arts',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,158,3,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(15,15,19,4,NULL,'Food Batchmaker','Doctorate','Maths',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,177,3,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(16,16,20,4,10,'Private Sector Executive','Graduate','Maths',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,238,4,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(17,17,21,4,NULL,'Agricultural Inspector','Doctorate','Arts',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,101,4,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(18,18,22,4,NULL,'Project Manager','Doctorate','Commerce',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,248,3,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(19,19,23,4,NULL,'Letterpress Setters Operator','Doctorate','Commerce',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,227,3,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(20,20,24,4,12,'Animal Care Workers','Post Graduate','Arts',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,53,4,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(21,21,25,4,NULL,'Petroleum Technician','Doctorate','Science',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,270,5,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(22,22,26,4,14,'Vice President Of Marketing','Post Graduate','Science',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,251,5,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(23,23,27,4,NULL,'Janitor','Graduate','Commerce',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,257,5,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(24,24,28,4,NULL,'Petroleum Engineer','Post Graduate','Arts',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,49,4,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(25,25,29,4,13,'Electrical Sales Representative','Graduate','Arts',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,180,5,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(26,26,30,4,NULL,'Interviewer','Post Graduate','Science',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,55,4,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(27,27,31,4,10,'Animal Husbandry Worker','Graduate','Science',NULL,8.00,10.00,40.00,50.00,'morning',1,NULL,NULL,NULL,163,3,NULL,1,NULL,0,0,0,NULL,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43');
/*!40000 ALTER TABLE `sch_employees_profile` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_employees`
--

DROP TABLE IF EXISTS `sch_employees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sch_employees` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `user_id` INT unsigned NOT NULL,
  `emp_code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `emp_id_card_type` enum('QR','RFID','NFC','Barcode') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'QR',
  `emp_smart_card_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_teacher` tinyint(1) NOT NULL DEFAULT '0',
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
  `notes` text COLLATE utf8mb4_unicode_ci,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sch_employees_emp_code_unique` (`emp_code`),
  KEY `sch_employees_user_id_foreign` (`user_id`),
  CONSTRAINT `sch_employees_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_employees`
--

LOCK TABLES `sch_employees` WRITE;
/*!40000 ALTER TABLE `sch_employees` DISABLE KEYS */;
INSERT INTO `sch_employees` VALUES (1,5,'EMP-7X0GSC','QR',NULL,1,'2023-07-12',5.5,'M.Ed','Economist','Pagac, D\'Amore and Paucek',NULL,'itaque, voluptas, ducimus, dicta, voluptatem',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(2,6,'EMP-EVU9X4','QR',NULL,1,'2023-04-13',8.5,'MSc','Landscaping','Heller-Barrows',NULL,'ducimus, iste, recusandae, id, necessitatibus',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(3,7,'EMP-SRXNEE','QR',NULL,1,'2025-11-01',3.1,'MSc','Railroad Inspector','Schimmel Ltd',NULL,'ut, expedita, veritatis, molestiae, itaque',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(4,8,'EMP-KFWWXU','QR',NULL,1,'2022-03-06',21.5,'M.Ed','Semiconductor Processor','McGlynn-Wunsch',NULL,'possimus, nihil, eos, vel, sint',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(5,9,'EMP-UD4IFS','QR',NULL,1,'2022-07-19',16.1,'M.Ed','Textile Cutting Machine Operator','Rolfson Group',NULL,'quia, dolorem, dolorem, rerum, in',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(6,10,'EMP-XLQJV1','QR',NULL,1,'2022-03-20',5.4,'PhD','Funeral Attendant','Kub Inc',NULL,'et, asperiores, blanditiis, aut, saepe',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(7,11,'EMP-HW0ML9','QR',NULL,1,'2022-09-13',16.5,'PhD','Interpreter OR Translator','Brekke-Howell',NULL,'aut, saepe, sed, corrupti, et',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(8,12,'EMP-SWXUWO','QR',NULL,1,'2021-08-13',14.0,'MSc','Government Property Inspector','Pfannerstill PLC',NULL,'rerum, et, dolore, a, perferendis',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(9,13,'EMP-DKF1FX','QR',NULL,1,'2025-10-31',8.3,'MA','Mine Cutting Machine Operator','Mayer, Hermann and Schuster',NULL,'recusandae, nemo, aut, commodi, excepturi',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(10,14,'EMP-6CEIOA','QR',NULL,1,'2021-05-21',17.0,'PhD','Mechanical Engineering Technician','Bernhard Ltd',NULL,'alias, odit, itaque, nostrum, fuga',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(11,15,'EMP-HO6BYH','QR',NULL,1,'2021-03-01',1.1,'MA','Refrigeration Mechanic','Pouros-Labadie',NULL,'totam, error, voluptatem, dolor, alias',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(12,16,'EMP-NVDNAU','QR',NULL,1,'2024-11-06',16.9,'MSc','Fire Fighter','Goodwin and Sons',NULL,'repellendus, id, consequatur, et, incidunt',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(13,17,'EMP-WGV4TP','QR',NULL,1,'2025-02-28',15.9,'MA','Artillery Officer','Heathcote and Sons',NULL,'illo, nobis, quibusdam, ut, et',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(14,18,'EMP-KAVCHQ','QR',NULL,1,'2020-03-11',23.7,'MA','Economist','Gulgowski-Brakus',NULL,'omnis, magnam, molestias, velit, aut',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(15,19,'EMP-XA0JIE','QR',NULL,1,'2020-04-22',10.0,'M.Ed','Roof Bolters Mining','Gutkowski, Kertzmann and Friesen',NULL,'libero, ex, vel, non, iure',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(16,20,'EMP-LI9DIY','QR',NULL,1,'2023-06-07',10.6,'MA','Law Enforcement Teacher','Braun, Dickens and Hamill',NULL,'harum, expedita, id, rerum, architecto',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(17,21,'EMP-ILLRZR','QR',NULL,1,'2022-09-29',24.9,'B.Ed','Production Worker','Heidenreich-Yost',NULL,'perferendis, sapiente, et, corrupti, molestiae',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(18,22,'EMP-HFM6QS','QR',NULL,1,'2020-06-11',19.6,'MSc','Cook','Hills, Fadel and Dickinson',NULL,'tempore, vero, minus, delectus, sint',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(19,23,'EMP-OEC5YQ','QR',NULL,1,'2022-09-13',24.9,'MA','Manufacturing Sales Representative','Jenkins-DuBuque',NULL,'molestiae, quaerat, velit, similique, enim',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(20,24,'EMP-A0NLDN','QR',NULL,1,'2021-06-20',21.6,'B.Ed','Refinery Operator','Lockman Ltd',NULL,'ipsa, suscipit, sit, provident, architecto',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(21,25,'EMP-ZDUQKX','QR',NULL,1,'2021-06-22',3.0,'MSc','Sawing Machine Tool Setter','Frami and Sons',NULL,'id, ratione, eligendi, modi, placeat',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(22,26,'EMP-8VPKZ7','QR',NULL,1,'2021-11-12',8.7,'M.Ed','Travel Clerk','Gutkowski-Schinner',NULL,'sed, aliquam, nulla, beatae, asperiores',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(23,27,'EMP-WYVOF9','QR',NULL,1,'2022-03-20',12.1,'MSc','Camera Repairer','Connelly-Reilly',NULL,'voluptatibus, totam, fugiat, omnis, dignissimos',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(24,28,'EMP-1P0SDB','QR',NULL,1,'2024-01-03',19.1,'PhD','Team Assembler','Bode PLC',NULL,'animi, voluptas, ut, tempore, corporis',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(25,29,'EMP-XCKJAW','QR',NULL,1,'2025-07-24',14.8,'MSc','Protective Service Worker','Grimes Inc',NULL,'eos, odio, aliquid, facilis, sed',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(26,30,'EMP-KZWS88','QR',NULL,1,'2025-01-14',9.3,'PhD','Retail Sales person','Emard-Wunsch',NULL,'totam, repellat, veritatis, consequatur, quia',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(27,31,'EMP-JDYLKF','QR',NULL,1,'2020-05-01',5.1,'MSc','Emergency Medical Technician and Paramedic','Leannon, Moen and Jakubowski',NULL,'voluptates, dolorum, aut, animi, id',NULL,NULL,NULL,'Seeded teacher employee',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43');
/*!40000 ALTER TABLE `sch_employees` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sch_teachers_profile`
--

DROP TABLE IF EXISTS `sch_teachers_profile`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sch_teachers_profile` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `employee_id` INT unsigned NOT NULL,
  `user_id` INT unsigned NOT NULL,
  `role_id` INT unsigned NOT NULL,
  `department_id` INT unsigned DEFAULT NULL,
  `subject_id` INT unsigned NOT NULL,
  `study_format_id` INT unsigned NOT NULL,
  `class_id` INT unsigned NOT NULL,
  `proficiency_percentage` tinyint unsigned DEFAULT NULL,
  `teaching_experience_months` tinyint unsigned DEFAULT NULL,
  `is_primary_subject` tinyint(1) NOT NULL DEFAULT '1',
  `max_periods_daily` tinyint unsigned NOT NULL DEFAULT '6',
  `min_periods_daily` tinyint unsigned NOT NULL DEFAULT '1',
  `max_periods_weekly` tinyint unsigned NOT NULL DEFAULT '48',
  `min_periods_weekly` tinyint unsigned NOT NULL DEFAULT '15',
  `preferred_shift` enum('morning','evening','flexible') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'morning',
  `is_full_time` tinyint(1) NOT NULL DEFAULT '1',
  `is_capable_of_handling_multiple_classes` tinyint(1) NOT NULL DEFAULT '0',
  `is_proficient_with_computer` tinyint(1) NOT NULL DEFAULT '0',
  `special_skill_area` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `certified_for_lab` tinyint(1) NOT NULL DEFAULT '0',
  `assignment_meta` json DEFAULT NULL,
  `soft_skills` json DEFAULT NULL,
  `performance_rating` tinyint unsigned DEFAULT NULL,
  `last_performance_review` date DEFAULT NULL,
  `security_clearance_done` tinyint(1) NOT NULL DEFAULT '0',
  `reporting_to` INT unsigned DEFAULT NULL,
  `can_manage_staff` tinyint(1) NOT NULL DEFAULT '0',
  `can_access_sensitive_data` tinyint(1) NOT NULL DEFAULT '0',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `effective_from` date DEFAULT NULL,
  `effective_to` date DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_teachersProfile_employee` (`employee_id`,`subject_id`,`study_format_id`,`class_id`),
  KEY `sch_teachers_profile_subject_id_foreign` (`subject_id`),
  KEY `sch_teachers_profile_study_format_id_foreign` (`study_format_id`),
  KEY `sch_teachers_profile_class_id_foreign` (`class_id`),
  KEY `sch_teachers_profile_role_id_foreign` (`role_id`),
  KEY `sch_teachers_profile_department_id_foreign` (`department_id`),
  CONSTRAINT `sch_teachers_profile_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `sch_teachers_profile_department_id_foreign` FOREIGN KEY (`department_id`) REFERENCES `sch_department` (`id`) ON DELETE SET NULL,
  CONSTRAINT `sch_teachers_profile_employee_id_foreign` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`) ON DELETE CASCADE,
  CONSTRAINT `sch_teachers_profile_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `sch_teachers_profile_study_format_id_foreign` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE CASCADE,
  CONSTRAINT `sch_teachers_profile_subject_id_foreign` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=56 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sch_teachers_profile`
--

LOCK TABLES `sch_teachers_profile` WRITE;
/*!40000 ALTER TABLE `sch_teachers_profile` DISABLE KEYS */;
INSERT INTO `sch_teachers_profile` VALUES (1,1,5,4,3,8,2,1,67,44,1,6,1,48,15,'morning',1,1,0,'ratione',0,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(2,1,5,4,NULL,5,4,3,77,158,0,6,1,48,15,'morning',1,0,1,'expedita',0,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(3,1,5,4,NULL,10,3,3,85,94,0,6,1,48,15,'morning',1,1,1,NULL,0,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(4,2,6,4,6,2,3,3,74,178,1,6,1,48,15,'morning',1,1,1,NULL,0,NULL,NULL,4,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(5,3,7,4,NULL,2,2,4,60,120,1,6,1,48,15,'morning',1,1,0,NULL,0,NULL,NULL,4,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(6,3,7,4,NULL,3,2,3,83,42,0,6,1,48,15,'morning',1,1,1,NULL,0,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(7,4,8,4,NULL,4,5,2,64,173,1,6,1,48,15,'morning',1,0,1,'neque',0,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(8,4,8,4,9,7,4,1,80,187,0,6,1,48,15,'morning',1,1,0,'consequatur',1,NULL,NULL,4,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(9,4,8,4,NULL,3,4,4,70,55,0,6,1,48,15,'morning',1,1,0,NULL,0,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(10,5,9,4,3,1,4,1,93,181,1,6,1,48,15,'morning',1,1,1,'aliquam',0,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(11,5,9,4,2,4,4,1,70,106,0,6,1,48,15,'morning',1,0,1,NULL,1,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(12,6,10,4,NULL,4,1,1,95,87,1,6,1,48,15,'morning',1,1,1,'et',1,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(13,6,10,4,10,3,5,4,62,200,0,6,1,48,15,'morning',1,1,0,NULL,1,NULL,NULL,4,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(14,6,10,4,NULL,10,2,1,61,88,0,6,1,48,15,'morning',1,0,1,'molestiae',0,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(15,7,11,4,8,8,3,1,95,140,1,6,1,48,15,'morning',1,1,1,NULL,0,NULL,NULL,4,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(16,7,11,4,8,8,3,4,92,163,0,6,1,48,15,'morning',1,0,0,NULL,0,NULL,NULL,4,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(17,8,12,4,NULL,2,1,3,86,143,1,6,1,48,15,'morning',1,1,1,'necessitatibus',0,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(18,9,13,4,12,1,1,1,94,157,0,6,1,48,15,'morning',1,0,0,NULL,1,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(19,9,13,4,14,2,1,2,95,75,0,6,1,48,15,'morning',1,1,1,NULL,0,NULL,NULL,4,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(20,10,14,4,13,3,2,4,85,160,1,6,1,48,15,'morning',1,0,1,'distinctio',1,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(21,10,14,4,NULL,8,4,4,81,119,0,6,1,48,15,'morning',1,0,1,'praesentium',0,NULL,NULL,4,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(22,10,14,4,2,10,1,3,81,133,0,6,1,48,15,'morning',1,1,1,NULL,0,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(23,11,15,4,5,5,5,4,91,48,1,6,1,48,15,'morning',1,0,1,'minima',0,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(24,12,16,4,NULL,7,2,2,86,160,1,6,1,48,15,'morning',1,1,1,NULL,1,NULL,NULL,4,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(25,12,16,4,NULL,9,3,2,77,98,0,6,1,48,15,'morning',1,1,0,NULL,0,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(26,13,17,4,7,6,3,3,83,146,1,6,1,48,15,'morning',1,1,1,'dolore',0,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(27,14,18,4,13,9,1,2,71,83,1,6,1,48,15,'morning',1,1,1,NULL,1,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(28,15,19,4,12,7,5,2,60,176,1,6,1,48,15,'morning',1,0,0,'aut',1,NULL,NULL,4,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(29,15,19,4,NULL,4,1,2,72,128,0,6,1,48,15,'morning',1,0,1,NULL,0,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(30,15,19,4,NULL,9,5,2,83,83,0,6,1,48,15,'morning',1,1,1,NULL,0,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(31,16,20,4,8,1,4,2,73,97,1,6,1,48,15,'morning',1,1,1,'soluta',1,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(32,17,21,4,NULL,1,5,4,87,21,1,6,1,48,15,'morning',1,0,1,NULL,0,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(33,17,21,4,9,9,4,4,91,191,0,6,1,48,15,'morning',1,0,1,NULL,0,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(34,18,22,4,NULL,2,4,2,72,104,1,6,1,48,15,'morning',1,1,1,'beatae',0,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(35,19,23,4,10,9,2,3,78,193,1,6,1,48,15,'morning',1,1,1,NULL,1,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(36,19,23,4,NULL,4,1,1,84,25,0,6,1,48,15,'morning',1,0,0,NULL,0,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(37,20,24,4,NULL,5,1,4,70,70,1,6,1,48,15,'morning',1,0,1,'rem',1,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(38,20,24,4,2,1,3,1,60,135,0,6,1,48,15,'morning',1,1,1,NULL,0,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(39,21,25,4,NULL,5,1,2,88,33,1,6,1,48,15,'morning',1,0,1,'ad',0,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(40,21,25,4,14,8,2,4,95,47,0,6,1,48,15,'morning',1,1,1,'architecto',1,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(41,22,26,4,NULL,10,4,4,74,50,1,6,1,48,15,'morning',1,1,1,'quo',0,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(42,22,26,4,NULL,8,4,4,85,128,0,6,1,48,15,'morning',1,1,1,NULL,1,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(43,23,27,4,11,7,3,1,93,109,1,6,1,48,15,'morning',1,0,1,NULL,0,NULL,NULL,4,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(44,24,28,4,NULL,9,4,3,94,70,1,6,1,48,15,'morning',1,1,1,'occaecati',1,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(45,24,28,4,NULL,7,1,2,78,98,0,6,1,48,15,'morning',1,1,1,NULL,0,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(46,24,28,4,NULL,3,5,2,67,160,0,6,1,48,15,'morning',1,1,0,NULL,0,NULL,NULL,4,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(47,25,29,4,NULL,10,5,2,93,128,1,6,1,48,15,'morning',1,1,0,'ex',0,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(48,25,29,4,NULL,5,5,2,74,60,0,6,1,48,15,'morning',1,0,1,'doloribus',0,NULL,NULL,4,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(49,25,29,4,5,3,5,1,73,99,0,6,1,48,15,'morning',1,0,1,'aliquam',0,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(50,26,30,4,4,3,1,2,85,137,1,6,1,48,15,'morning',1,1,1,NULL,0,NULL,NULL,5,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(51,26,30,4,11,2,1,4,73,38,0,6,1,48,15,'morning',1,1,1,'dolorem',0,NULL,NULL,4,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(52,26,30,4,NULL,4,3,4,73,94,0,6,1,48,15,'morning',1,1,1,NULL,1,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(53,27,31,4,1,4,4,4,61,139,1,6,1,48,15,'morning',1,1,1,NULL,0,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(54,27,31,4,12,9,3,1,63,170,0,6,1,48,15,'morning',1,0,1,'assumenda',0,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(55,27,31,4,8,6,2,3,79,108,0,6,1,48,15,'morning',1,0,1,'officia',0,NULL,NULL,3,NULL,1,NULL,0,0,NULL,'2025-02-05',NULL,1,NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43');
/*!40000 ALTER TABLE `sch_teachers_profile` ENABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `std_students`
--

LOCK TABLES `std_students` WRITE;
/*!40000 ALTER TABLE `std_students` DISABLE KEYS */;
INSERT INTO `std_students` VALUES (1,38,'ADM2026000038','2024-03-04','QR698413D021D80','QR','SC698413D021D82','475666000778','APAAR698413D021D83','BC202625204','Padama',NULL,'Chadha','Male','2012-11-21',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(2,39,'ADM2026000039','2025-01-22','QR698413D05E75B','QR','SC698413D05E75D','436433690665','APAAR698413D05E75E','BC202625423','Juhi','Jawahar','Pradhan','Male','2019-01-04',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(3,40,'ADM2026000040','2025-01-05','QR698413D09B713','QR','SC698413D09B715','890631739258','APAAR698413D09B716','BC202651652','Sirish',NULL,'Sant','Female','2018-06-10',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(4,41,'ADM2026000041','2024-11-15','QR698413D0D7496','QR','SC698413D0D7498','662979997503','APAAR698413D0D7499','BC202688449','Sumit',NULL,'Bassi','Male','2015-03-24',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(5,42,'ADM2026000042','2024-04-30','QR698413D11EE09','QR','SC698413D11EE0B','362794083316','APAAR698413D11EE0C','BC202654476','Rupesh',NULL,'Dani','Male','2016-08-02',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(6,43,'ADM2026000043','2024-07-16','QR698413D1629A3','QR','SC698413D1629A6','292094389327','APAAR698413D1629A7','BC202617055','Lalita',NULL,'Banik','Female','2010-06-08',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(7,44,'ADM2026000044','2024-10-14','QR698413D19F4FD','QR','SC698413D19F4FF','851441498336','APAAR698413D19F500','BC202690810','Sushant',NULL,'Nazareth','Female','2017-07-06',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(8,45,'ADM2026000045','2024-06-14','QR698413D1DB4DA','QR','SC698413D1DB4DC','341964484047','APAAR698413D1DB4DD','BC202646469','Astha',NULL,'Chahal','Female','2020-04-28',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(9,46,'ADM2026000046','2024-04-01','QR698413D222EFE','QR','SC698413D222F00','447470224884','APAAR698413D222F01','BC202672725','Narmada',NULL,'Sathe','Female','2015-05-08',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(10,47,'ADM2026000047','2025-01-11','QR698413D25EAEC','QR','SC698413D25EAEE','528670476445','APAAR698413D25EAEF','BC202606490','Charandeep',NULL,'Tank','Female','2014-11-09',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(11,48,'ADM2026000048','2025-02-04','QR698413D29B509','QR','SC698413D29B50A','709272698134','APAAR698413D29B50B','BC202696598','Niyati',NULL,'Mallick','Female','2012-04-06',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(12,49,'ADM2026000049','2024-10-06','QR698413D2D7616','QR','SC698413D2D7618','386215099017','APAAR698413D2D7619','BC202689064','Anshu',NULL,'Kata','Female','2016-09-12',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(13,50,'ADM2026000050','2024-06-19','QR698413D31EE11','QR','SC698413D31EE13','930872500203','APAAR698413D31EE14','BC202625944','Aabha',NULL,'Somani','Male','2011-12-17',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(14,51,'ADM2026000051','2024-05-13','QR698413D35ABAB','QR','SC698413D35ABAD','962262113651','APAAR698413D35ABAE','BC202618514','Habib',NULL,'Cherian','Female','2017-10-15',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(15,52,'ADM2026000052','2024-10-16','QR698413D39762F','QR','SC698413D397631','707571590697','APAAR698413D397632','BC202670773','Kirti','Drishti','Rana','Female','2020-03-04',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(16,53,'ADM2026000053','2025-01-03','QR698413D3D3220','QR','SC698413D3D3222','869246132971','APAAR698413D3D3223','BC202627355','Suresh','Neela','Meda','Male','2009-04-19',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(17,54,'ADM2026000054','2024-06-06','QR698413D41ACE2','QR','SC698413D41ACE4','650324847909','APAAR698413D41ACE5','BC202686531','Nishi',NULL,'Sinha','Male','2019-12-25',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(18,55,'ADM2026000055','2024-09-21','QR698413D457428','QR','SC698413D45742A','447561744784','APAAR698413D45742B','BC202655168','Gayatri',NULL,'Biswas','Female','2020-09-04',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(19,56,'ADM2026000056','2024-02-27','QR698413D493A6E','QR','SC698413D493A70','952094592007','APAAR698413D493A71','BC202667758','Nirmal',NULL,'Oza','Male','2015-07-14',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(20,57,'ADM2026000057','2024-10-30','QR698413D4CF710','QR','SC698413D4CF712','963683329598','APAAR698413D4CF713','BC202660153','Parminder',NULL,'Saini','Female','2015-12-14',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(21,58,'ADM2026000058','2024-06-18','QR698413D5172AC','QR','SC698413D5172AE','224283661905','APAAR698413D5172AF','BC202642545','Amolika','Malik','Dhingra','Male','2010-11-19',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(22,59,'ADM2026000059','2024-04-11','QR698413D552DD9','QR','SC698413D552DDB','967803197629','APAAR698413D552DDC','BC202661353','Nancy',NULL,'Nath','Male','2016-12-03',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(23,60,'ADM2026000060','2024-11-03','QR698413D58EFBD','QR','SC698413D58EFBF','338875970014','APAAR698413D58EFC0','BC202688761','Drishti','Mona','Mander','Male','2014-06-20',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(24,61,'ADM2026000061','2024-09-14','QR698413D5CB273','QR','SC698413D5CB275','892835882254','APAAR698413D5CB276','BC202649565','Mukund','Jayshree','Cherian','Male','2010-11-30',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(25,62,'ADM2026000062','2024-11-03','QR698413D612EC8','QR','SC698413D612ECA','741426205434','APAAR698413D612ECB','BC202655474','Amrit','Dhanush','Prakash','Female','2011-01-01',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(26,63,'ADM2026000063','2024-09-26','QR698413D64EB74','QR','SC698413D64EB76','324153656761','APAAR698413D64EB77','BC202605005','Elias',NULL,'Mehra','Female','2016-08-02',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(27,64,'ADM2026000064','2024-12-27','QR698413D68A885','QR','SC698413D68A887','712607683268','APAAR698413D68A888','BC202638047','Richa','Parminder','Wali','Female','2013-12-28',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(28,65,'ADM2026000065','2024-03-01','QR698413D6C7528','QR','SC698413D6C752A','832533308336','APAAR698413D6C752B','BC202615867','Parvez',NULL,'Balay','Female','2020-07-14',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(29,66,'ADM2026000066','2024-10-18','QR698413D70F232','QR','SC698413D70F234','494663047525','APAAR698413D70F235','BC202665015','Rosey',NULL,'Khosla','Female','2018-04-21',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(30,67,'ADM2026000067','2024-08-06','QR698413D74AE4E','QR','SC698413D74AE50','323867089668','APAAR698413D74AE51','BC202675845','Rupesh',NULL,'Doctor','Female','2013-11-08',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(31,68,'ADM2026000068','2024-06-16','QR698413D786AF3','QR','SC698413D786AF5','628046400540','APAAR698413D786AF6','BC202650773','Bhanupriya',NULL,'Sarma','Male','2018-11-08',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(32,69,'ADM2026000069','2024-03-12','QR698413D7C3745','QR','SC698413D7C3747','433138851576','APAAR698413D7C3748','BC202634154','Indira',NULL,'Sarraf','Female','2017-04-08',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(33,70,'ADM2026000070','2024-11-02','QR698413D80B50E','QR','SC698413D80B510','630612312908','APAAR698413D80B511','BC202617780','Tulsi',NULL,'Barman','Female','2015-03-29',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43'),(34,71,'ADM2026000071','2024-04-19','QR698413D847459','QR','SC698413D84745B','464600044356','APAAR698413D84745C','BC202636585','Aastha',NULL,'Nori','Male','2015-10-28',NULL,NULL,1,1,'Generated by seeder',NULL,'2026-02-05 03:51:43','2026-02-05 03:51:43');
/*!40000 ALTER TABLE `std_students` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-05 14:56:28
