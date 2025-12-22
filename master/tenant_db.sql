-- ------------------------------------------------------------
-- Tanent Database
-- ------------------------------------------------------------

-- --------------------------------------------------------------------------------------------
-- Create Views after creating global_master database and it's tables
-- --------------------------------------------------------------------------------------------

CREATE VIEW glb_countries  AS SELECT * FROM global_master.glb_countries;
CREATE VIEW glb_states     AS SELECT * FROM global_master.glb_states;
CREATE VIEW glb_districts  AS SELECT * FROM global_master.glb_districts;
CREATE VIEW glb_cities     AS SELECT * FROM global_master.glb_cities;
CREATE VIEW glb_academic_sessions  AS SELECT * FROM global_master.glb_academic_sessions;
CREATE VIEW glb_boards     AS SELECT * FROM global_master.glb_boards;

CREATE VIEW glb_languages AS SELECT * FROM global_master.glb_languages;
CREATE VIEW glb_menus AS SELECT * FROM global_master.glb_menus;
CREATE VIEW glb_modules AS SELECT * FROM global_master.glb_modules;
CREATE VIEW glb_menu_model_jnt AS SELECT * FROM global_master.glb_menu_model_jnt;
CREATE VIEW glb_translations AS SELECT * FROM global_master.glb_translations;

-- ------------------------------------------------------------
-- System Tables
-- ------------------------------------------------------------

-- Tables for Role Based Access Control (RBAC) using spatie/laravel-permission package
CREATE TABLE IF NOT EXISTS `sys_permissions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(20) NOT NULL,            -- This will be used for dropdown
  `name` varchar(100) NOT NULL,
  `guard_name` varchar(255) NOT NULL,           -- used by Laravel routing
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_permissions_shortName_guardName` (`short_name`,`guard_name`),
  UNIQUE KEY `uq_permissions_name_guardName` (`name`,`guard_name`)
) ENGINE=InnoDB AUTO_INCREMENT=176 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_roles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `short_name` VARCHAR(20) NOT NULL,
  `description` VARCHAR(255) NULL,
  `guard_name` varchar(255) NOT NULL,
  `is_system`  TINYINT(1) NOT NULL DEFAULT 0, -- if true, role belongs to PG
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_roles_name_guardName` (`name`,`guard_name`),
  UNIQUE KEY `uq_roles_name_guardName` (`short_name`,`guard_name`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Junction Tables for Many-to-Many Relationships
CREATE TABLE IF NOT EXISTS `sys_role_has_permissions_jnt` (
  `permission_id` bigint unsigned NOT NULL,   -- FK to sys_permissions
  `role_id` bigint unsigned NOT NULL,         -- FK to sys_roles
  PRIMARY KEY (`permission_id`,`role_id`),
  KEY `idx_roleHasPermissions_roleId` (`role_id`),
  CONSTRAINT `fk_roleHasPermissions_permissionId` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_roleHasPermissions_roleId` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Junction Tables for Polymorphic Many-to-Many Relationships
CREATE TABLE IF NOT EXISTS `sys_model_has_permissions_jnt` (
  `permission_id` bigint unsigned NOT NULL,   -- FK to sys_permissions
  `model_type` varchar(190) NOT NULL,         -- E.g., 'App\Models\User'
  `model_id` bigint unsigned NOT NULL,        -- E.g., User ID
  PRIMARY KEY (`permission_id`,`model_id`,`model_type`),
  KEY `idx_modelHasPermissions_modelId_modelType` (`model_id`,`model_type`),
  CONSTRAINT `fk_modelHasPermissions_permissionId` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Junction Tables for Polymorphic Many-to-Many Relationships
CREATE TABLE IF NOT EXISTS `sys_model_has_roles_jnt` (
  `role_id` bigint unsigned NOT NULL,       -- FK to sys_roles
  `model_type` varchar(190) NOT NULL,       -- E.g., 'App\Models\User'
  `model_id` bigint unsigned NOT NULL,      -- E.g., User ID
  PRIMARY KEY (`role_id`,`model_id`,`model_type`),
  KEY `idx_modelHasRoles_modelId_modelType` (`model_id`,`model_type`),
  CONSTRAINT `fk_modelHasRoles_roleId` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `emp_code` VARCHAR(20) NOT NULL,        -- Employee Code (Unique code for each user)
  `short_name` varchar(30) NOT NULL,      -- This Field will be used for showing Dropdown of Users i.e. Teachers, Students, Parents
  `name` varchar(100) NOT NULL,           -- Full Name (First Name, Middle Name, Last Name)
  `email` varchar(150) NOT NULL,
  `mobile_no` varchar(32) DEFAULT NULL,
  `phone_no` varchar(32) DEFAULT NULL,
  `two_factor_auth_enabled` tinyint(1) NOT NULL DEFAULT '0',    -- 0 = Disabled, 1 = Enabled
  `email_verified_at` timestamp NULL DEFAULT NULL,              -- When email was verified
  `mobile_verified_at` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `password` varchar(255) COLLATE utf8mb4_unicode_bin NOT NULL, -- Hashed Password
  `is_super_admin` tinyint(1) NOT NULL DEFAULT '0',             -- 0 = No, 1 = Yes
  `last_login_at` datetime DEFAULT NULL,                        -- Last Login Timestamp
  `super_admin_flag` tinyint GENERATED ALWAYS AS ((case when (`is_super_admin` = 1) then 1 else NULL end)) STORED,  -- To ensure only one super admin
  `remember_token` varchar(100) DEFAULT NULL,                   -- For "Remember Me" functionality
  `prefered_language` bigint unsigned NOT NULL,                 -- fk to glb_languages
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_empCode` (`emp_code`),
  UNIQUE KEY `uq_users_shortName` (`short_name`),
  UNIQUE KEY `uq_users_email` (`email`),
  UNIQUE KEY `uq_users_mobileNo` (`mobile_no`),
  UNIQUE KEY `uq_single_super_admin` (`super_admin_flag`),
  CONSTRAINT `fk_users_language` FOREIGN KEY (`prefered_language`) REFERENCES `glb_languages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* Optional triggers to prevent deleting/demoting super admin (you already used triggers for sessions) */
DELIMITER $$
CREATE TRIGGER trg_users_prevent_delete_super BEFORE DELETE ON users
FOR EACH ROW
BEGIN
  IF OLD.is_super_admin = 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Super Admin cannot be deleted';
  END IF;
END$$

CREATE TRIGGER trg_users_prevent_update_super BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
  IF OLD.is_super_admin = 1 AND NEW.is_super_admin = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Super Admin cannot be demoted';
  END IF;
END$$
DELIMITER ;

-- This table will store various system-wide settings and configurations
CREATE TABLE IF NOT EXISTS `sys_settings` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `description` varchar(255) NULL,    -- Here we will describe the use of the variable
  `key` varchar(100) NOT NULL,        -- This will be the Key to connect Value with it
  `value` varchar(255) DEFAULT NULL,          -- Actual stored setting value. Could be string, JSON, or serialized data depending on type
  `type` varchar(50) DEFAULT NULL,    -- e.g. 'string','json','int','boolean', 'date' etc.
  `is_public` tinyint(1) NOT NULL DEFAULT 0,  -- Flag — 1 means this setting can be safely exposed to the frontend (e.g. school logo, theme color), 0 means internal/backend-only (e.g. API keys).
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_settings_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Ths Table will capture the detail of which Field of Which Table fo Which Databse Type, I can create a Dropdown in sys_dropdown_table of?
-- This will help us to make sure we can only create create a Dropdown in sys_dropdown_table whcih has been configured by Developer.
CREATE TABLE IF NOT EXISTS `sys_dropdown_needs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `db_type` varchar(50) NOT NULL,
  `table_name` varchar(150) NOT NULL,
  `column_name` varchar(150) NOT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dropdownNeeds_ordinal_key` (`ordinal`,`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dropdown Table to store various dropdown values used across the system
-- Enhanced sys_dropdown_table to accomodate Menu Detail (Category,Main Menu, Sub-Menu ID) for Easy identification.
CREATE TABLE IF NOT EXISTS `sys_dropdown_table` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `menu_category` varchar(150) NOT NULL,
  `main_menu` varchar(150) NOT NULL,
  `sub_menu` varchar(150) NOT NULL,
  `ordinal` tinyint unsigned NOT NULL,
  `key` varchar(160) NOT NULL,      -- Key will be Combination of DB Type + Table Name + Column Name (e.g. 'tenant_db.cmp_complaint_actions.action_type)
  `value` varchar(100) NOT NULL,
  `type` ENUM('String','Integer','Decimal', 'Date', 'Datetime', 'Time', 'Boolean') NOT NULL DEFAULT 'String',
  `additional_info` JSON DEFAULT NULL,  -- This will store additional information about the dropdown value
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dropdownTable_ordinal_key` (`ordinal`,`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- conditions:
-- 1. When we go to create a New Dropdown, It will show 3 Dropdowns to select from.
--    a. DB Type (this will come from sys_dropdown_needs.db_type)
--    b. Table Name (this will come from sys_dropdown_needs.table_name)
--    c. Column Name (this will come from sys_dropdown_needs.column_name)
-- 2. System will check if the Dropdown Need is already configured in sys_dropdown_needs table.
-- 3. If not, Developer need to create a new Dropdown Need as per the need.
-- 4. If yes, System will use the existing Dropdown Need.

-- ---------------------------------------------------------------------------------------------
-- below is Old `sys_dropdown_table` Table. I have Enhanced it to accomodate Menu Details (Category,Main Menu, Sub-Menu) for Easy identification.
-- CREATE TABLE IF NOT EXISTS `sys_dropdown_table` (
--   `id` bigint unsigned NOT NULL AUTO_INCREMENT,
--   `ordinal` tinyint unsigned NOT NULL,
--   `key` varchar(150) NOT NULL,
--   `value` varchar(100) NOT NULL,
--   `type` ENUM('String','Integer','Decimal', 'Date', 'Datetime', 'Time', 'Boolean') NOT NULL DEFAULT 'String',
--   `is_active` TINYINT(1) DEFAULT 1,
--   `created_at` timestamp NULL DEFAULT NULL,
--   `updated_at` timestamp NULL DEFAULT NULL,
--   PRIMARY KEY (`id`),
--   UNIQUE KEY `uq_dropdownTable_ordinal_key` (`ordinal`,`key`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- ---------------------------------------------------------------------------------------------


-- Table to store media files associated with various models (e.g., users, posts)
CREATE TABLE IF NOT EXISTS `sys_media` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `model_type` varchar(255) NOT NULL,           -- E.g., 'App\Models\User'
  `model_id` bigint unsigned NOT NULL,          -- E.g., User ID
  `uuid` char(36) DEFAULT NULL,                 -- Universally Unique Identifier for the media
  `collection_name` varchar(255) NOT NULL,      -- E.g., 'avatars', 'documents'
  `name` varchar(255) NOT NULL,                 -- Original file name without extension
  `file_name` varchar(255) NOT NULL,
  `mime_type` varchar(255) DEFAULT NULL,        -- E.g., 'image/jpeg', 'application/pdf'
  `disk` varchar(255) NOT NULL,                 -- Storage disk (e.g., 'local', 's3')
  `conversions_disk` varchar(255) DEFAULT NULL, -- Disk for storing converted files
  `size` bigint unsigned NOT NULL,              -- File size in bytes  
  `manipulations` json NOT NULL,                -- JSON field to store any manipulations applied to the media
  `custom_properties` json NOT NULL,            -- JSON field for any custom properties
  `generated_conversions` json NOT NULL,        -- JSON field to track generated conversions
  `responsive_images` json NOT NULL,            -- JSON field for responsive image data
  `order_column` int unsigned DEFAULT NULL,     -- For ordering media items
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_media_uuid` (`uuid`),
  KEY `idx_media_modelType_modelId` (`model_type`,`model_id`),
  KEY `idx_media_orderColumn` (`order_column`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ========================================================================================================

-- ------------------------------------------------------------
-- School Setup Module (sch)
-- ------------------------------------------------------------
-- This table is a replica of 'prm_tenant' table in 'prmprime_db' database
CREATE TABLE IF NOT EXISTS `sch_organizations` (
  `id` bigint unsigned NOT NULL,              -- it will have same id as it is in 'prm_tenant'
  `group_code` varchar(20) NOT NULL,          -- Code for Grouping of Organizations/Schools
  `group_short_name` varchar(50) NOT NULL,
  `group_name` varchar(150) NOT NULL,
  `code` varchar(20) NOT NULL,                -- School Code
  `short_name` varchar(50) NOT NULL,
  `name` varchar(150) NOT NULL,
  `udise_code` varchar(30) DEFAULT NULL,      -- U-DISE Code of the School
  `affiliation_no` varchar(60) DEFAULT NULL,  -- Affiliation Number of the School
  `email` varchar(100) DEFAULT NULL,
  `website_url` varchar(150) DEFAULT NULL,
  `address_1` varchar(200) DEFAULT NULL,
  `address_2` varchar(200) DEFAULT NULL,
  `area` varchar(100) DEFAULT NULL,
  `city_id` bigint unsigned NOT NULL,
  `pincode` varchar(10) DEFAULT NULL,
  `phone_1` varchar(20) DEFAULT NULL,
  `phone_2` varchar(20) DEFAULT NULL,
  `whatsapp_number` varchar(20) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `locale` varchar(16) DEFAULT 'en_IN',
  `currency` varchar(8) DEFAULT 'INR',
  `established_date` date DEFAULT NULL,                 -- School Established Date
  `flg_single_record` tinyint(1) NOT NULL DEFAULT '1',  -- To ensure only one record in this table
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `chk_org_singleRecord` (`flg_single_record`),
  CONSTRAINT fk_organizations_cityId FOREIGN KEY (city_id) REFERENCES glb_cities (id) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Junction Table to link Organizations with Academic Sessions
CREATE TABLE IF NOT EXISTS `sch_org_academic_sessions_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `academic_sessions_id` bigint unsigned NOT NULL,  -- Added New
  `short_name` varchar(10) NOT NULL,
  `name` varchar(50) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `current_flag` tinyint(1) GENERATED ALWAYS AS ((case when (`is_current` = 1) then '1' else NULL end)) STORED,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_orgAcademicSession_shortName` (`short_name`),
  UNIQUE KEY `uq_orgAcademicSession_currentFlag` (`current_flag`),
  CONSTRAINT `fk_orgAcademicSession_sessionId` FOREIGN KEY (`academic_sessions_id`) REFERENCES `glb_academic_sessions` (`id`) ON DELETE CASCADE  -- Added New
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Junction Table to link Organizations with Boards
CREATE TABLE IF NOT EXISTS `sch_board_organization_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `academic_sessions_id` bigint unsigned NOT NULL,
  `board_id` bigint unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_boardOrg_boardId` FOREIGN KEY (`board_id`) REFERENCES `glb_boards` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_boardOrg_academicSessionId` FOREIGN KEY (`academic_sessions_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tables for Classes, Sections, Subjects, Subject Types, Study Formats, Class-Section Junctions, Subject-StudyFormat Junctions, Class Groups, Subject Groups
CREATE TABLE IF NOT EXISTS `sch_classes` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,                -- e.g. 'Grade 1' or 'Class 10'
  `short_name` varchar(10) DEFAULT NULL,      -- e.g. 'G1' or '10A'
  `ordinal` tinyint DEFAULT NULL,             -- will have sequence order for Classes
  `code` CHAR(3) NOT NULL,                    -- e.g., 'BV1','BV2','1st','1' and so on (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_classes_shortName` (`short_name`),
  UNIQUE KEY `uq_classes_code` (`code`),
  UNIQUE KEY `uq_classes_name` (`name`),
  UNIQUE KEY `uq_classes_ordinal` (`ordinal`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_sections` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(20) NOT NULL,            -- e.g. 'A', 'B'
  `ordinal` tinyint unsigned DEFAULT 1,   -- will have sequence order for Sections
  `code` CHAR(1) NOT NULL,                -- e.g., 'A','B','C','D' and so on (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sections_name` (`name`),
  UNIQUE KEY `uq_sections_code` (`code`),
  UNIQUE KEY `uq_sections_ordinal` (`ordinal`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_class_section_jnt` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `class_id` int unsigned NOT NULL,               -- FK to sch_classes
  `section_id` int unsigned NOT NULL,             -- FK to sch_sections
  `class_secton_code` char(5) NOT NULL,           -- Combination of class Code + section Code i.e. '8th_A', '10h_B'  
  `capacity` tinyint unsigned DEFAULT NULL,       -- Targeted / Planned Quantity of stundets in Each Sections of every class.
  `total_student` tinyint unsigned DEFAULT NULL,  -- Actual Number of Student in the Class+Section
  `class_teacher_id` bigint unsigned NOT NULL,    -- FK to sch_users
  `assistance_class_teacher_id` bigint unsigned NOT NULL,  -- FK to sch_users
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_classSection_classId_sectionId` (`class_id`,`section_id`),
  UNIQUE KEY `uq_classSection_code` (`class_secton_code`),
  CONSTRAINT `fk_classSection_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_classSection_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_classSection_classTeacherId` FOREIGN KEY (`class_teacher_id`) REFERENCES `sch_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_classSection_assistanceClassTeacherId` FOREIGN KEY (`assistance_class_teacher_id`) REFERENCES `sch_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=300 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- subject_type will represent what type of subject it is - Major, Minor, Core, Main, Optional etc.
CREATE TABLE IF NOT EXISTS `sch_subject_types` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `short_name` varchar(20) NOT NULL,  -- 'MAJOR','MINOR','OPTIONAL'
  `name` varchar(50) NOT NULL,
  `code` char(3) NOT NULL,         -- 'MAJ','MIN','OPT','ACT','SPO'
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subjectTypes_shortName` (`short_name`),
  UNIQUE KEY `uq_subjectTypes_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_study_formats` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `short_name` varchar(20) NOT NULL,  -- 'LECTURE','LAB','PRACTICAL','TUTORIAL','SEMINAR','WORKSHOP','GROUP_DISCUSSION','OTHER'
  `name` varchar(50) NOT NULL,
  `code` CHAR(3) NOT NULL,            -- e.g., 'LAC','LAB','ACT','ART' and so on (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_studyFormats_shortName` (`short_name`),
  UNIQUE KEY `uq_studyFormats_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Data Seed for Study_Format - LECTURE, LAB, PRACTICAL, TUTORIAL, SEMINAR, WORKSHOP, GROUP_DISCUSSION, OTHER

CREATE TABLE IF NOT EXISTS `sch_subjects` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `short_name` varchar(20) NOT NULL,  -- e.g. 'SCIENCE','MATH','SST','ENGLISH' and so on
  `name` varchar(50) NOT NULL,
  `code` CHAR(3) NOT NULL,         -- e.g., 'SCI','MTH','SST','ENG' and so on (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subjects_shortName` (`short_name`),
  UNIQUE KEY `uq_subjects_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- subject_study_format is grouping for different streams like Sci-10 Lacture, Arts-10 Activity, Core-10
-- I have removed 'sub_types' from 'sch_subject_study_format_jnt' because one Subject_StudyFormat may belongs to different Subject_type for different classes
-- Removed 'short_name' as we can use `sub_stdformat_code`
CREATE TABLE IF NOT EXISTS `sch_subject_study_format_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `subject_id` bigint unsigned NOT NULL,            -- FK
  `study_format_id` int unsigned NOT NULL,          -- FK
  `name` varchar(50) NOT NULL,
  `subj_stdformat_code` CHAR(7) NOT NULL,         -- Will be combination of (Subject.codee+'-'+StudyFormat.code) e.g., 'SCI_LAC','SCI_LAB','SST_LAC','ENG_LAC' (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subStudyFormat_subjectId_stFormat` (`subject_id`,`study_format_id`),
  UNIQUE KEY `uq_subStudyFormat_subStdformatCode` (`sub_stdformat_code`),
  CONSTRAINT `fk_subStudyFormat_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subStudyFormat_studyFormatId` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Ths table will be used to define different Class Groups like 10th-A Science Lecture Major, 7th-B Commerce Optional etc.
-- old name 'sch_subject_study_format_class_subj_types_jnt' changed to 'sch_class_groups_jnt'
CREATE TABLE IF NOT EXISTS `sch_class_groups_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,                  -- FK
  `class_id` int NOT NULL,                              -- FK to 'sch_classes'
  `section_id` int NULL,                                -- FK to 'sch_sections'
  `subject_Study_format_id` bigint unsigned NOT NULL,   -- FK to 'sch_subject_study_format_jnt'
  `subject_type_id` int unsigned NOT NULL,              -- FK to 'sch_subject_types'
  `rooms_type_id` bigint unsigned NOT NULL,             -- FK to 'sch_rooms_type'
  `name` varchar(50) NOT NULL,                          -- 10th-A Science Lacture Major
  `code` CHAR(17) NOT NULL, -- Combination of (Class+Section+Subject+StudyFormat+SubjType) e.g., '10h_A_SCI_LAC_MAJ','8th_MAT_LAC_OPT' (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_classGroups_cls_Sec_subStdFmt_SubTyp` (`class_id`,`section_id`,`subject_Study_format_id`,`subject_type_id`),
  UNIQUE KEY `uq_classGroups_subStdformatCode` (`code`),
  CONSTRAINT `fk_classGroups_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_classGroups_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_classGroups_subjStudyFormatId` FOREIGN KEY (`subject_Study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_classGroups_subTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_classGroups_roomTypeId` FOREIGN KEY (`rooms_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 'sch_subject_groups' will be used to assign all subjects to the students
-- There will be a Variable in 'sch_settings' table named 'SubjGroup_For_All_Sections' (Subj_Group_will_be_used_for_all_sections_of_a_class)
-- if above variable is True then section_id will be Nul in below table and
-- Every Group will eb avalaible accross sections for a particuler class
CREATE TABLE IF NOT EXISTS `sch_subject_groups` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `class_id` int NOT NULL,                        -- FK to 'sch_classes'
  `section_id` int NULL,                          -- FK (Section can be null if Group will be used for all sectons)
  `short_name` varchar(30) NOT NULL,              -- 7th Science, 7th Commerce, 7th-A Science etc.
  `name` varchar(100) NOT NULL,                   -- '7th (Sci,Mth,Eng,Hindi,SST with Sanskrit,Dance)'
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subjectGroups_shortName` (`short_name`),
  UNIQUE KEY `uq_subjectGroups_name` (`class_id`,`name`),
  CONSTRAINT `fk_subGroups_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subGroups_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE NULL
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_subject_group_subject_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `subject_group_id` bigint unsigned NOT NULL,              -- FK to 'sch_subject_groups'
  `class_group_id` bigint unsigned NOT NULL,                -- FK to 'sch_class_groups_jnt'
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subjGrpSubj_subjGrpId_classGroup` (`subject_group_id`,`class_group_id`),
  CONSTRAINT `fk_subjGrpSubj_subjectGroup` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subjGrpSubj_classGroup` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tables for Room types, this will be used to define different types of rooms like Science Lab, Computer Lab, Sports Room etc.
CREATE TABLE IF NOT EXISTS `sch_rooms_type` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `code` CHAR(7) NOT NULL,                        -- e.g., 'SCI_LAB','BIO_LAB','CRI_GRD','TT_ROOM','BDM_CRT'
  `short_name` varchar(30) NOT NULL,              -- e.g., 'Science Lab','Biology Lab','Cricket Ground','Table Tanis Room','Badminton Court'
  `name` varchar(100) NOT NULL,
  `required_resources` text DEFAULT NULL,         -- e.g., 'Microscopes, Lab Coats, Safety Goggles' for Science Lab
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_roomType_code` (`code`),
  UNIQUE KEY `uq_roomType_shortName` (`short_name`)
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Building Coding format is - 2 Digit for Buildings(10-99)
CREATE TABLE IF NOT EXISTS `sch_buildings` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `code` char(2) NOT NULL,                      -- 2 digits code (10,11,12) 
  `short_name` varchar(30) NOT NULL,            -- e.g., 'Junior Wing','Primary Wing','Middle Wing','Senior Wing','Administration Wings'
  `name` varchar(50) NOT NULL,                  -- Detailed Name of the Building
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_buildings_code` (`code`),
  UNIQUE KEY `uq_buildings_name` (`short_name`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Room Coding format is - 2 Digit for Buildings(10-99), 1 Digit-Building Floor(G,F,S,T,F / A,B,C,D,E), & Last 3 Character defin Class+Section (09A,10A,12B)
CREATE TABLE IF NOT EXISTS `sch_rooms` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `building_id` int unsigned NOT NULL,      -- FK to 'sch_buildings' table
  `room_type_id` int NOT NULL,              -- FK to 'sch_rooms_type' table
  `code` CHAR(7) NOT NULL,                  -- e.g., '11G-10A','12F-11A','11S-12A' and so on (This will be used for Timetable)
  `short_name` varchar(30) NOT NULL,        -- e.g., 'Junior Wing','Primary Wing','Middle Wing','Senior Wing','Administration Wings'
  `name` varchar(50) NOT NULL,
  `capacity` int unsigned DEFAULT NULL,     -- Seating Capacity of the Room
  `max_limit` int unsigned DEFAULT NULL,    -- Maximum Limit of the Room, Maximum how many students can accomodate in the room
  `resource_tags` text DEFAULT NULL,        -- e.g., 'Projector, Smart Board, AC, Lab Equipment' etc.
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rooms_code` (`code`),
  UNIQUE KEY `uq_rooms_shortName` (`short_name`),
  CONSTRAINT `fk_rooms_buildingId` FOREIGN KEY (`building_id`) REFERENCES `sch_buildings` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rooms_roomTypeId` FOREIGN KEY (`room_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Teacher table will store additional information about teachers
CREATE TABLE IF NOT EXISTS `sch_teachers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `joining_date` DATE NOT NULL,
  `total_experience_years` DECIMAL(4,1) DEFAULT NULL,       -- Total teaching experience
  `highest_qualification` VARCHAR(100) DEFAULT NULL,        -- e.g. M.Sc., Ph.D.
  `specialization` VARCHAR(150) DEFAULT NULL,               -- e.g. Mathematics, Physics
  `last_institution` VARCHAR(200) DEFAULT NULL,             -- e.g. DPS Delhi
  `awards` TEXT DEFAULT NULL,                               -- brief summary
  `skills` TEXT DEFAULT NULL,                               -- general skills list (comma/JSON)
  `qualifications_json` JSON DEFAULT NULL,   -- Array of {degree, specialization, university, year, grade}
  `certifications_json` JSON DEFAULT NULL,   -- Array of {name, issued_by, issue_date, expiry_date, verified}
  `experiences_json` JSON DEFAULT NULL,      -- Array of {institution, role, from_date, to_date, subject, remarks}
  `notes` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `teachers_emp_code_unique` (`emp_code`),
  KEY `teachers_user_id_foreign` (`user_id`),
  CONSTRAINT `fk_teachers_userId` FOREIGN KEY (`user_id`) REFERENCES `sch_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Teacher Profile table will store detailed proficiency to teach specific subjects, study formats, and classes
CREATE TABLE IF NOT EXISTS `sch_teachers_profile` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `teacher_id` BIGINT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,            -- FK to 'subjects' table
  `study_format_id` BIGINT UNSIGNED NOT NULL,       -- FK to 'sch_study_formats' table
  `class_id` INT UNSIGNED NOT NULL,                 -- FK to 'sch_classes' table
  `priority` ENUM('PRIMARY','SECONDARY') NOT NULL DEFAULT 'PRIMARY',
  `proficiency` INT UNSIGNED DEFAULT NULL,          -- 1–10 rating or %
  `special_skill_area` VARCHAR(100) DEFAULT NULL,   -- e.g. Robotics, AI, Debate
  `certified_for_lab` TINYINT(1) DEFAULT 0,         -- allowed to conduct practicals
  `assignment_meta` JSON DEFAULT NULL,              -- e.g. { "qualification": "M.Sc Physics", "experience": "7 years" }
  `notes` TEXT NULL,
  `effective_from` DATE DEFAULT NULL,               -- when this profile becomes effective
  `effective_to` DATE DEFAULT NULL,                 -- when this profile ends 
  `is_active` TINYINT(1) NOT NULL DEFAULT '1',
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_teachersProfile_teacher` (`teacher_id`,`subject_id`,`study_format_id`),
  CONSTRAINT `fk_teachersProfile_teacherId` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachersProfile_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachersProfile_studyFormatId` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachersProfile_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Student Module
-- ==================================================================================

CREATE TABLE IF NOT EXISTS `std_students` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,          -- FK to sch_user
  `parent_id` bigint unsigned NOT NULL,        -- FK to sch_user
  `aadhar_id` VARCHAR(20) NOT NULL,            -- always permanent identity
  `apaar_id` VARCHAR(100) NOT NULL,            -- 12 digits numeric i.e. 9876 5432 1098
  `birth_cert_no` VARCHAR(50) NULL,
  `health_id` VARCHAR(50) NULL,                -- like ABHA number in India
  `smart_card_id` VARCHAR(100) NULL,           -- RFID Card Number / Smart Card Number
  `first_name` VARCHAR(100) NOT NULL,
  `middle_name` VARCHAR(100) DEFAULT NULL,
  `last_name` VARCHAR(100) DEFAULT NULL,
  `gender` ENUM('Male','Female','Transgender','Prefer Not to Say') NOT NULL DEFAULT 'Male',
  `dob` DATE NOT NULL,
  `blood_group` ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-') NOT NULL,
  `photo` VARCHAR(255) DEFAULT NULL,
  `current_status_id` int NOT NULL,    -- FK to `gl_dropdown_table`
  `note` varchar(200) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_student_aadharId` (`aadhar_id`)
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `std_student_detail` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `student_id` int DEFAULT NULL,         -- FK to 'std_students'
  `mobile` varchar(20) DEFAULT NULL,     -- Student Mobile
  `email` varchar(100) DEFAULT NULL,     -- Student Mail ID
  `current_address` text,
  `permanent_address` text,
  `city_id` varchar(100) DEFAULT NULL,   -- FK to 'glb_city'
  `pin` varchar(10) DEFAULT NULL,
  `religion` varchar(50) DEFAULT NULL,   -- FK to `gl_dropdown_table`
  `cast` varchar(50) DEFAULT NULL,       -- FK to `gl_dropdown_table`
  `right_to_edu` tinyint(1) NOT NULL DEFAULT '0',
  `bank_account_no` varchar(100) DEFAULT NULL,
  `bank_name` varchar(100) DEFAULT NULL,
  `ifsc_code` varchar(100) DEFAULT NULL,
  `upi_id` varchar(100) DEFAULT NULL,
  `fee_depositor_pan_number` varchar(10) DEFAULT NULL,    -- or tax benefit
  `father_name` varchar(50) DEFAULT NULL,
  `father_phone` varchar(10) DEFAULT NULL,
  `father_occupation` varchar(20) DEFAULT NULL,
  `father_email` varchar(100) DEFAULT NULL,
  `father_pic` varchar(200) NOT NULL,
  `mother_name` varchar(50) DEFAULT NULL,
  `mother_phone` varchar(10) DEFAULT NULL,
  `mother_occupation` varchar(20) DEFAULT NULL,
  `mother_email` varchar(100) DEFAULT NULL,
  `mother_pic` varchar(200) NOT NULL,
  `guardian_is` ENUM('Father','Mother','Other') NOT NULL DEFAULT 'Father',
  `guardian_name` varchar(50) DEFAULT NULL,
  `guardian_relation` varchar(100) DEFAULT NULL,
  `guardian_relationship_proof_id` varchar(50) DEFAULT NULL,  -- for non-biological guardians
  `guardian_phone` varchar(10) DEFAULT NULL,
  `guardian_occupation` varchar(20) NOT NULL,
  `guardian_address` text,
  `guardian_email` varchar(100) DEFAULT NULL,
  `guardian_pic` varchar(200) NOT NULL,
  `previous_school_detail` text,
  `height` varchar(100) NOT NULL,
  `weight` varchar(100) NOT NULL,
  `measurement_date` date DEFAULT NULL,
  `additional_info` json DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_studentDetail_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentDetail_cityId` FOREIGN KEY (`city_id`) REFERENCES `glb_cities` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `std_student_sessions_jnt` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT,
  `student_id` BIGINT UNSIGNED NOT NULL,            -- FK
  `academic_sessions_id` bigint unsigned NOT NULL,  -- FK - sch_org_academic_sessions_jnt
  `admission_no` VARCHAR(50) NOT NULL,
  `roll_no` INT DEFAULT NULL,
  `admission_date` DATE DEFAULT NULL,
  `registration_no` VARCHAR(50) DEFAULT NULL,
  `default_mobile` ENUM('Father','Mother','Guardian','All') NOT NULL DEFAULT 'Mother',
  `default_email` ENUM('Father','Mother','Guardian','All') NOT NULL DEFAULT 'Mother',
  `class_section_id` INT UNSIGNED NOT NULL,         -- FK (Instead of selecting Class & Section, we will be using Class+Section)
  `subject_group_id` BIGINT UNSIGNED NOT NULL,      -- FK - sch_subject_groups
  `session_status_id` BIGINT UNSIGNED DEFAULT NULL, -- FK - gl_dropdown_table (Status of the Student in the Session)
  `is_current` TINYINT(1) DEFAULT 1,  -- Only one session can be current at a time for one student
  `current_flag` bigint GENERATED ALWAYS AS ((case when (`is_current` = 1) then `student_id` else NULL end)) STORED,
  `leaving_date` DATE DEFAULT NULL,
  `reason_quit` int NULL,                       -- FK to `gl_dropdown_table` (Reason for leaving the Session)
  `dis_note` text NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_studentSessions_currentFlag` (`current_flag`)
  CONSTRAINT `fk_studentSessions_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_academicSession` FOREIGN KEY (`academic_sessions_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_classSectionId` FOREIGN KEY (`class_section_id`) REFERENCES `sch_classes_sections_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_subjGroupId` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_sessionStatusId` FOREIGN KEY (`session_status_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_reasonQuit` FOREIGN KEY (`reason_quit`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- ===============================================================================================================



-- Change Log
-- ===========================================================================================================================================
-- Change table Name - Table (sch_subject_study_format_class_subj_types_jnt) to (sch_class_groups_jnt)
-- Change the condition implemented into Screen Design of table (sch_subject_study_format_class_subj_types_jnt)
-- We have to keep collecting Section Information optional without any condition of 'SubjectGroup_Used_For_All_Sections' from 'sys_settings' table.
-- If user want to have Class_Groups Section wise Separately then while creating Class_Groups they have to select Section also.
-- If user want to have Class_Groups for all sections of a class then while creating Class_Groups they can keep Section as NULL.
-- Because while creating Timetable we have to know which subject is taught in which section.
-- So, we have to keep section_id as NOT NULL field in the table (sch_subject_study_format_class_subj_types_jnt)
-- Change Field Name - 'clas_subj_stdformat_Subjtyp_code' to 'code' in table (sch_subject_study_format_class_subj_types_jnt)
-- Updated Constraint Names in table (sch_subject_study_format_class_subj_types_jnt)
-- ===========================================================================================================================================
-- Updated Field in Table (sch_subject_group_subject_jnt) Field Name - 'class_subj_stdformat_Subjtyp_id' to 'class_group_id'
-- Update Constraint Name in Table (sch_subject_group_subject_jnt) - 'fk_subjGrpSubj_classSubjStdFmtSubjtypId' to 'fk_subjGrpSubj_classGroup'
-- updated Foreign Key Reference in Table (sch_subject_group_subject_jnt) - 'sch_subject_study_format_class_subj_types_jnt' to 'sch_class_groups_jnt'
-- ===========================================================================================================================================
-- Changed on 2025-12-21
-- Enhanced `sys_dropdown_table` to accomodate Menu Details (Category,Main Menu, Sub-Menu) for Easy identification. 
-- Added New table `sys_dropdown_needs` to capture Dropdown Needs for Easy identification. 