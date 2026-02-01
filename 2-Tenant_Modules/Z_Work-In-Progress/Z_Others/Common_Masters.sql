
-- ===========================================================================
-- SYSTEM MODULE (sys)
-- ===========================================================================
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
    `password` varchar(255) NOT NULL, -- Hashed Password
    `is_super_admin` tinyint(1) NOT NULL DEFAULT '0',             -- 0 = No, 1 = Yes
    `last_login_at` datetime DEFAULT NULL,                        -- Last Login Timestamp
    `super_admin_flag` tinyint GENERATED ALWAYS AS ((case when (`is_super_admin` = 1) then 1 else NULL end)) STORED,  -- To ensure only one super admin
    `remember_token` varchar(100) DEFAULT NULL,                   -- For "Remember Me" functionality
    `prefered_language` bigint unsigned NOT NULL,                 -- fk to glb_languages
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `is_pg_user` tinyint(1) NOT NULL DEFAULT '0',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_users_empCode` (`emp_code`),
    UNIQUE KEY `uq_users_shortName` (`short_name`),
    UNIQUE KEY `uq_users_email` (`email`),
    UNIQUE KEY `uq_users_mobileNo` (`mobile_no`),
    UNIQUE KEY `uq_single_super_admin` (`super_admin_flag`),
    CONSTRAINT `fk_users_language` FOREIGN KEY (`prefered_language`) REFERENCES `glb_languages` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

  CREATE TABLE IF NOT EXISTS `sys_dropdown_needs` (
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `db_type` ENUM('Prime','Tenant','Global') NOT NULL,  -- Which Database this Dropdown is for? (prime_db,tenant_db,global_db)
    `table_name` varchar(150) NOT NULL,  -- Table Name
    `column_name` varchar(150) NOT NULL,  -- Column Name
    `menu_category` varchar(150) NULL,    -- Menu Category (e.g. School Setup, Foundation Setup, Operations, Reports)
    `main_menu` varchar(150) NULL,        -- Main Menu (e.g. Student Mgmt., Sullabus Mgmt.)
    `sub_menu` varchar(150) NULL,         -- Sub Menu (e.g. Student Details, Teacher Details)
    `tab_name` varchar(100) NULL,         -- Tab Name (e.g. Student Details, Teacher Details)
    `field_name` varchar(100) NULL,       -- Field Name (e.g. Student Details, Teacher Details)
    `is_system` TINYINT(1) DEFAULT 1,     -- If true, this Dropdown can be created by Tenant
    `tenant_creation_allowed` TINYINT(1) DEFAULT 0,  -- If true, this Dropdown can be created by Tenant
    `compulsory` TINYINT(1) DEFAULT 1,    -- If true, this Dropdown is compulsory for Application fuctioning
    `is_active` TINYINT(1) DEFAULT 1,     -- If true, this Dropdown is active
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_DDNeeds_dbType_tableName_columnName` (`db_type`,`table_name`,`column_name`),
    UNIQUE KEY `uq_DDNeeds_category_mainMenu_subMenu_tabName_fieldName` (`menu_category`,`main_menu`,`sub_menu`,`tab_name`,`field_name`),
    UNIQUE KEY `uq_DDNeeds_dropdownTableId` (`dropdown_table_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `sys_dropdown_table` (
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint unsigned NOT NULL,
    `key` varchar(160) NOT NULL,      -- Key will be Combination of Table Name + Column Name (e.g. 'cmp_complaint_actions.action_type)
    `value` varchar(100) NOT NULL,
    `type` ENUM('String','Integer','Decimal', 'Date', 'Datetime', 'Time', 'Boolean') NOT NULL DEFAULT 'String',
    `additional_info` JSON DEFAULT NULL,  -- This will store additional information about the dropdown value
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_dropdownTable_ordinal` (`dropdown_needs_id`,`ordinal`),
    UNIQUE KEY `uq_dropdownTable_key` (`dropdown_needs_id`,`key`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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


-- ===========================================================================
-- 3-SCHOOL SETUP MODULE (sch)
-- ===========================================================================
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
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `sch_department` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL, -- e.g. "Transport", "Academic", "Rash Driving"
    `code` VARCHAR(30) DEFAULT NULL, -- Optional short code e.g. "TPT", "ACD"
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `sch_designation` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL, -- e.g. "Teacher", "Staff", "Student"
    `code` VARCHAR(30) DEFAULT NULL, -- Optional short code e.g. "TCH", "STF", "STD"
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- This table will facilitate to create Groups of different department, Roles, Designations etc.
  CREATE TABLE IF NOT EXISTS `sch_entity_groups` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `entity_purpose_id` BIGINT UNSIGNED NOT NULL, -- FK to sys_dropdown_table e.g. (escalation_management, notification, event_supervision, exam_supervision)
    `code` VARCHAR(30) DEFAULT NULL, -- Optional short code e.g. "All_Class_Teachers", "Stundets_Play_Cricket", "Students_Participate_Annual_day"
    `name` VARCHAR(100) NOT NULL, -- e.g. "Class Teachers for all the classes", "Students Registered for Cricket", "All Students Participate in Annual Day"
    `description` VARCHAR(512) DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `sch_entity_groups_members` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `entity_group_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sch_entity_groups
    `entity_type_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table (1=Class, 2=Section, 3=Subject, 4=Designation, 5=Department, 6=Role etc.)
    `entity_table_name` VARCHAR(60) DEFAULT NULL, -- Entity Table Name e.g. "sch_class", "sch_section", "sch_subject", "sch_designation", "sch_department", "sch_role"
    `entity_selected_id` BIGINT UNSIGNED DEFAULT NULL, -- Foriegn Key will be managed at Application Level as it will be different for different entities e.g. sch_class.id, sch_section.id, sch_subject.id, sch_designation.id, sch_department.id, sch_role.id etc.
    `entity_name` VARCHAR(100) DEFAULT NULL, -- Entity Name e.g. "Students of Class-1st", "Students of Section-7th_A", "Students of Subject-English", "Students of Designation-Teacher", "Students of Department-Transport", "Role-School Principal"
    `entity_code` VARCHAR(30) DEFAULT NULL, -- Entity Code e.g. "STD_CLS_1", "STD_SEC_7th_A", "STD_SUB_English", "STU_DES_Teacher", "STU_DEP_Transport", "ROL_School_Principal"
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_entity_group_id` FOREIGN KEY (`entity_group_id`) REFERENCES `sch_entity_groups` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_entity_type_id` FOREIGN KEY (`entity_type_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

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
    UNIQUE KEY `uq_classSection_classTeacherId` (`class_teacher_id`),
    UNIQUE KEY `uq_classSection_assistanceClassTeacherId` (`assistance_class_teacher_id`),
    CONSTRAINT `fk_classSection_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classSection_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classSection_classTeacherId` FOREIGN KEY (`class_teacher_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classSection_assistanceClassTeacherId` FOREIGN KEY (`assistance_class_teacher_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
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
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `sch_subject_study_format_jnt` (
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `subject_id` bigint unsigned NOT NULL,            -- FK to 'sch_subjects'
    `study_format_id` int unsigned NOT NULL,          -- FK to 'sch_study_formats'
    `name` varchar(50) NOT NULL,                      -- e.g., 'Science Lecture','Science Lab','Math Lecture','Math Lab' and so on
    `subj_stdformat_code` CHAR(7) NOT NULL,         -- Will be combination of (Subject.codee+'-'+StudyFormat.code) e.g., 'SCI_LAC','SCI_LAB','SST_LAC','ENG_LAC' (This will be used for Timetable)
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subStudyFormat_subjectId_stFormat` (`subject_id`,`study_format_id`),
    UNIQUE KEY `uq_subStudyFormat_subStdformatCode` (`subj_stdformat_code`),
    CONSTRAINT `fk_subStudyFormat_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subStudyFormat_studyFormatId` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===========================================================================
-- 4-TRANSPORT MODULE (tpt)
-- ===========================================================================
  CREATE TABLE IF NOT EXISTS `tpt_shift` (
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `code` VARCHAR(20) NOT NULL,
      `name` VARCHAR(100) NOT NULL,
      `effective_from` DATE NOT NULL,
      `effective_to` DATE NOT NULL,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      UNIQUE KEY `uq_shift_code` (`code`),
      UNIQUE KEY `uq_shift_name` (`name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tpt_fine_master` (
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `std_academic_sessions_id` BIGINT UNSIGNED NOT NULL,
      `fine_from_days` TINYINT DEFAULT 0,
      `fine_to_days` TINYINT DEFAULT 0,
      `fine_type` ENUM('Fixed','Percentage') DEFAULT 'Fixed',
      `fine_rate` DECIMAL(5,2) DEFAULT 0.00,
      `student_restricted` TINYINT(1) DEFAULT 0,
      `Remark` VARCHAR(512) DEFAULT NULL,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tpt_student_fine_detail` (
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_fee_detail_id` BIGINT UNSIGNED NOT NULL,
      `fine_master_id` BIGINT UNSIGNED NOT NULL,
      `fine_days` TINYINT DEFAULT 0,
      `fine_type` ENUM('Fixed','Percentage') DEFAULT 'Fixed',
      `fine_rate` DECIMAL(5,2) DEFAULT 0.00,
      `fine_amount` DECIMAL(10,2) DEFAULT 0.00,
      `waved_fine_amount` DECIMAL(10,2) DEFAULT 0.00,
      `net_fine_amount` DECIMAL(10,2) DEFAULT 0.00,
      `Remark` VARCHAR(512) DEFAULT NULL,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_sf_master` FOREIGN KEY (`student_fee_detail_id`) REFERENCES `tpt_student_fee_detail`(`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_sf_fine_master` FOREIGN KEY (`fine_master_id`) REFERENCES `tpt_fine_master`(`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================================================
-- 8-TIMETABLE MODULE (tt)
-- ============================================================================================================
    CREATE TABLE IF NOT EXISTS `tt_shift` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `code` VARCHAR(20) NOT NULL,
      `name` VARCHAR(100) NOT NULL,
      `description` VARCHAR(255) DEFAULT NULL,
      `default_start_time` TIME DEFAULT NULL,
      `default_end_time` TIME DEFAULT NULL,
      `ordinal` SMALLINT UNSIGNED DEFAULT 1,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_shift_code` (`code`),
      UNIQUE KEY `uq_shift_name` (`name`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	    CREATE TABLE IF NOT EXISTS `tt_day_type` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `code` VARCHAR(20) NOT NULL,  -- e.g., 'WD', 'HD', 'SD'
      `name` VARCHAR(100) NOT NULL,
      `description` VARCHAR(255) DEFAULT NULL,
      `is_working_day` TINYINT(1) NOT NULL DEFAULT 1,
      `reduced_periods` TINYINT(1) NOT NULL DEFAULT 0,
      `ordinal` SMALLINT UNSIGNED DEFAULT 1,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_daytype_code` (`code`),
      UNIQUE KEY `uq_daytype_name` (`name`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tt_period_type` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `code` VARCHAR(30) NOT NULL,  -- 
      `name` VARCHAR(100) NOT NULL,
      `description` VARCHAR(255) DEFAULT NULL,
      `color_code` VARCHAR(10) DEFAULT NULL,
      `icon` VARCHAR(50) DEFAULT NULL,
      `is_schedulable` TINYINT(1) NOT NULL DEFAULT 1,
      `counts_as_teaching` TINYINT(1) NOT NULL DEFAULT 0,
      `counts_as_workload` TINYINT(1) NOT NULL DEFAULT 0,
      `is_break` TINYINT(1) NOT NULL DEFAULT 0,
      `ordinal` SMALLINT UNSIGNED DEFAULT 1,
      `is_system` TINYINT(1) DEFAULT 1,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_periodtype_code` (`code`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tt_teacher_assignment_role` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `code` VARCHAR(30) NOT NULL,
      `name` VARCHAR(100) NOT NULL,
      `description` VARCHAR(255) DEFAULT NULL,
      `is_primary_instructor` TINYINT(1) NOT NULL DEFAULT 0,
      `counts_for_workload` TINYINT(1) NOT NULL DEFAULT 1,
      `allows_overlap` TINYINT(1) NOT NULL DEFAULT 0,
      `workload_factor` DECIMAL(3,2) DEFAULT 1.00,
      `ordinal` SMALLINT UNSIGNED DEFAULT 1,
      `is_system` TINYINT(1) DEFAULT 1,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_tarole_code` (`code`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tt_school_days` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `code` VARCHAR(10) NOT NULL,  -- "Monday", "Tuesday", etc.
      `name` VARCHAR(20) NOT NULL,
      `short_name` VARCHAR(5) NOT NULL,
      `day_of_week` TINYINT UNSIGNED NOT NULL,
      `ordinal` SMALLINT UNSIGNED NOT NULL,
      `is_school_day` TINYINT(1) NOT NULL DEFAULT 1,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_schoolday_code` (`code`),
      UNIQUE KEY `uq_schoolday_dow` (`day_of_week`),
      KEY `idx_schoolday_ordinal` (`ordinal`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tt_working_day` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `date` DATE NOT NULL,
      `day_type_id` BIGINT UNSIGNED NOT NULL,
      `is_school_day` TINYINT(1) NOT NULL DEFAULT 1,
      `remarks` VARCHAR(255) DEFAULT NULL,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_workday_date` (`date`),
      KEY `idx_workday_daytype` (`day_type_id`),
      CONSTRAINT `fk_workday_daytype` FOREIGN KEY (`day_type_id`) REFERENCES `tt_day_type` (`id`) ON DELETE RESTRICT
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tt_class_subgroup` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `code` VARCHAR(50) NOT NULL,
      `name` VARCHAR(150) NOT NULL,
      `description` VARCHAR(255) DEFAULT NULL,
      `class_group_id` BIGINT UNSIGNED DEFAULT NULL,
      `subgroup_type` ENUM('OPTIONAL_SUBJECT','HOBBY','SKILL','LANGUAGE','STREAM','ACTIVITY','SPORTS','OTHER') NOT NULL DEFAULT 'OTHER',
      `student_count` INT UNSIGNED DEFAULT NULL,
      `min_students` INT UNSIGNED DEFAULT NULL,
      `max_students` INT UNSIGNED DEFAULT NULL,
      `is_shared_across_sections` TINYINT(1) NOT NULL DEFAULT 0,
      `is_shared_across_classes` TINYINT(1) NOT NULL DEFAULT 0,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_subgroup_code` (`code`),
      KEY `idx_subgroup_type` (`subgroup_type`),
      CONSTRAINT `fk_subgroup_class_group` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================================================
-- Module - Syllabus (slb)
-- ============================================================================================================
	-- We need to create Master table to capture slb_topic_type
	-- level: 0=Topic, 1=Sub-topic, 2=Mini Topic, 3=Sub-Mini Topic, 4=Micro Topic, 5=Sub-Micro Topic, 6=Nano Topic, 7=Ultra Topic,
	-- This table will be used to Generate slb_topics.code and slb_topics.analytics_code.
	-- User can Not change slb_topics.analytics_code, But he can change slb_topics.code as per their choice.
	-- This Table will be set by PG_Team and will not be available for change to School.
	CREATE TABLE IF NOT EXISTS `slb_topic_level_types` (
	`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`level` TINYINT UNSIGNED NOT NULL,              -- e.g., 0=Topic, 1=Sub-topic, 2=Mini Topic, 3=Sub-Mini Topic, 4=Micro Topic, 5=Sub-Micro Topic, 6=Nano Topic, 7=Sub-Nano Topic, 8=Ultra Topic, 9=Sub-Ultra Topic
	`code` VARCHAR(3) NOT NULL,                    -- e.g., (TOP, SBT, MIN, SMN, MIC, SMC, NAN, SNN, ULT, SUT)
	`name` VARCHAR(150) NOT NULL,                   -- e.g., (TOPIC, SUB-TOPIC, MINI TOPIC, SUB-MINI TOPIC, MICRO TOPIC, SUB-MICRO TOPIC, NANO TOPIC, SUB-NANO TOPIC, ULTRA TOPIC, SUB-ULTRA TOPIC)
	`is_active` TINYINT(1) NOT NULL DEFAULT 1,
	`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_topic_type_level` (`level`),
	UNIQUE KEY `uq_topic_type_code` (`code`),
	UNIQUE KEY `uq_topic_type_name` (`name`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- COMPETENCY FRAMEWORK (NEP 2020 ALIGNMENT)
	-- -------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `slb_competency_types` (
			`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
			`code` VARCHAR(20) NOT NULL,   -- e.g. 'KNOWLEDGE','SKILL','ATTITUDE'
			`name` VARCHAR(100) NOT NULL,
			`description` VARCHAR(255) DEFAULT NULL,
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `uq_comp_type_code` (`code`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `slb_competencies` (
			`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
			`uuid` BINARY(16) NOT NULL,
			`parent_id` BIGINT UNSIGNED DEFAULT NULL,     -- FK to self (NULL for root competencies)
			`code` VARCHAR(60) NOT NULL,                 -- e.g. 'KNOWLEDGE','SKILL','ATTITUDE'
			`name` VARCHAR(150) NOT NULL,                -- e.g. 'Knowledge of Linear Equations'
			`short_name` VARCHAR(50) DEFAULT NULL,       -- e.g. 'Linear Equations'
			`description` VARCHAR(255) DEFAULT NULL,     -- e.g. 'Description of Knowledge of Linear Equations'
			`class_id` INT UNSIGNED DEFAULT NULL,         -- FK to sch_classes.id
			`subject_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sch_subjects.id
			`competency_type_id` INT UNSIGNED NOT NULL,   -- FK to slb_competency_types.id
			`domain` ENUM('COGNITIVE', 'AFFECTIVE', 'PSYCHOMOTOR') NOT NULL DEFAULT 'COGNITIVE', -- e.g. 'COGNITIVE'
			`nep_framework_ref` VARCHAR(100) DEFAULT NULL,    -- e.g. 'NEP Framework Reference'
			`ncf_alignment` VARCHAR(100) DEFAULT NULL,        -- e.g. 'NCF Alignment'
			`learning_outcome_code` VARCHAR(50) DEFAULT NULL, -- e.g. 'Learning Outcome Code'
			`path` VARCHAR(500) DEFAULT '/',  -- e.g. 
			`level` TINYINT UNSIGNED DEFAULT 0, -- e.g. 0
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `uq_competency_uuid` (`uuid`),
			UNIQUE KEY `uq_competency_code` (`code`),
			KEY `idx_competency_parent` (`parent_id`),
			KEY `idx_competency_type` (`competency_type_id`),
			CONSTRAINT `fk_competency_parent` FOREIGN KEY (`parent_id`) REFERENCES `slb_competencies` (`id`) ON DELETE CASCADE,
			CONSTRAINT `fk_competency_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
			CONSTRAINT `fk_competency_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
			CONSTRAINT `fk_competency_type` FOREIGN KEY (`competency_type_id`) REFERENCES `slb_competency_types` (`id`) ON DELETE CASCADE
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- Link topics to competencies
	CREATE TABLE IF NOT EXISTS `slb_topic_competency_jnt` (
			`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
			`topic_id` BIGINT UNSIGNED NOT NULL,
			`competency_id` BIGINT UNSIGNED NOT NULL, -- FK to slb_competencies.id
			`weightage` DECIMAL(5,2) DEFAULT NULL,    -- How much topic contributes to competency
			`is_primary` TINYINT(1) DEFAULT 0, -- True if this is the primary competency for this topic
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `uq_tc_topic_competency` (`topic_id`,`competency_id`),
			CONSTRAINT `fk_tc_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE,
			CONSTRAINT `fk_tc_competency` FOREIGN KEY (`competency_id`) REFERENCES `slb_competencies` (`id`) ON DELETE CASCADE
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `slb_bloom_taxonomy` (
			`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
			`code` VARCHAR(20) NOT NULL,   -- e.g. 'REMEMBERING','UNDERSTANDING','APPLYING','ANALYZING','EVALUATING','CREATING'
			`name` VARCHAR(100) NOT NULL,
			`description` VARCHAR(255) DEFAULT NULL,
			`bloom_level` TINYINT UNSIGNED DEFAULT NULL, -- 1-6 for Bloom's revised taxonomy
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `uq_bloom_code` (`code`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `slb_cognitive_skill` (
			`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
			`bloom_id` INT UNSIGNED DEFAULT NULL,       -- slb_bloom_taxonomy.id
			`code` VARCHAR(20) NOT NULL,  -- e.g. 'COG-KNOWLEDGE','COG-SKILL','COG-UNDERSTANDING'
			`name` VARCHAR(100) NOT NULL,
			`description` VARCHAR(255) DEFAULT NULL,
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `uq_cog_code` (`code`),
			CONSTRAINT `fk_cog_bloom` FOREIGN KEY (`bloom_id`) REFERENCES `slb_bloom_taxonomy` (`id`) ON DELETE SET NULL
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `slb_ques_type_specificity` (
			`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
			`cognitive_skill_id` INT UNSIGNED DEFAULT NULL, -- slb_cognitive_skill.id
			`code` VARCHAR(20) NOT NULL,  -- e.g. 'IN_CLASS','HOMEWORK','SUMMATIVE','FORMATIVE'
			`name` VARCHAR(100) NOT NULL,
			`description` VARCHAR(255) DEFAULT NULL,
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `uq_quesTypeSps_code` (`code`),
			CONSTRAINT `fk_quesTypeSps_cognitive` FOREIGN KEY (`cognitive_skill_id`) REFERENCES `slb_cognitive_skill` (`id`) ON DELETE SET NULL
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `slb_complexity_level` (
			`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
			`code` VARCHAR(20) NOT NULL,  -- e.g. 'EASY','MEDIUM','DIFFICULT'
			`name` VARCHAR(50) NOT NULL,
			`complexity_level` TINYINT UNSIGNED DEFAULT NULL,  -- 1=Easy, 2=Medium, 3=Difficult
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `uq_complex_code` (`code`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `slb_question_types` (
			`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
			`code` VARCHAR(20) NOT NULL,  -- e.g. 'MCQ_SINGLE','MCQ_MULTI','SHORT_ANSWER','LONG_ANSWER','MATCH','NUMERIC','FILL_BLANK','CODING'
			`name` VARCHAR(100) NOT NULL, -- e.g. 'Multiple Choice Single Answer','Multiple Choice Multi Answer','Short Answer','Long Answer','Match','Numeric','Fill Blank','Coding'
			`has_options` TINYINT(1) NOT NULL DEFAULT 0,    -- True if this type has options
			`auto_gradable` TINYINT(1) NOT NULL DEFAULT 1,  -- True if this type can be auto-graded (Can System Marked Automatically?)
			`description` TEXT DEFAULT NULL,
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `uq_qtype_code` (`code`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `slb_performance_categories` (
			`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
			-- Identity
			`code` VARCHAR(20) NOT NULL,    -- TOPPER, EXCELLENT, GOOD, AVERAGE, BELOW_AVERAGE, NEED_IMPROVEMENT, POOR etc.
			`name` VARCHAR(100) NOT NULL,
			`description` VARCHAR(255),
			-- Academic meaning
			`level` TINYINT UNSIGNED NOT NULL,    -- 1 = Topper, 2 = Good, 3 = Average, 4 = Below Average, 5 = Poor
			`min_percentage` DECIMAL(5,2) NOT NULL, -- Minimum percentage
			`max_percentage` DECIMAL(5,2) NOT NULL, -- Maximum percentage
			-- AI semantics
			`ai_severity` ENUM('LOW','MEDIUM','HIGH','CRITICAL') DEFAULT 'LOW',
			`ai_default_action` ENUM('ACCELERATE','PROGRESS','PRACTICE','REMEDIATE','ESCALATE') NOT NULL,
			-- UX
			`display_order` SMALLINT UNSIGNED DEFAULT 1,
			`color_code` VARCHAR(10),
			`icon_code` VARCHAR(50),              -- e.g. trophy, warning, alert
			-- Scope & governance
			`scope` ENUM('SCHOOL','CLASS') DEFAULT 'SCHOOL',
			`class_id` BIGINT UNSIGNED DEFAULT NULL,
			-- Control
			`is_system_defined` TINYINT(1) DEFAULT 1, -- system vs school editable
			`auto_retest_required` TINYINT(1) DEFAULT 0, -- Auto Retest Required or Not (if 'True' then System will auto create a Test for the Topic and assign to Student)
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL,
			-- Constraints
			UNIQUE KEY `uq_perf_code` (`code`, `scope`),
			CHECK (`min_percentage` < `max_percentage`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- Conditions:
			-- 1. If 'is_system_defined' is 1, then school can not edit this record.
			-- 2. The Schema does NOT prevent overlapping ranges like:
			--    - min_percentage = 80, max_percentage = 90
			--    - min_percentage = 85, max_percentage = 95
			-- 3. The Schema does NOT prevent ranges that do not cover the full range of 0-100%
			--    - min_percentage = 80, max_percentage = 100
			-- 4. Above 2 needs to be handled at the application level
			-- ✅ Enforce at application/service layer:
					SELECT 1
					FROM slb_performance_categories
					WHERE
					:new_min <= max_percentage
					AND :new_max >= min_percentage
					AND is_active = 1
					LIMIT 1;
			-- If row exists → ❌ reject insert/update
			-- 🎯 Special:
			-- 1. School may want different categorisation for different classes, Which most of the ERP doesn't cover.
			-- 2. School may want to use different categorisation for different subjects, Which most of the ERP doesn't cover.

			CREATE TABLE IF NOT EXISTS `slb_grade_division_master` (
			`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
			-- Identity
			`code` VARCHAR(20) NOT NULL,        -- (Grade System - '2024-25_CBSE_SCHOOL_A') (DIVISION - '2024-25_CBSE_SCHOOL_1st')
			`name` VARCHAR(100) NOT NULL,       -- For Grade System (AY 2024-25, CBSE Board, Grade-A for All Classes) For Division (AY 2024-25, CBSE Board, Division-1st for Class 8th)
			`description` VARCHAR(255),
			-- Type
			`grading_type` ENUM('GRADE','DIVISION') NOT NULL,
			-- Academic band
			`min_percentage` DECIMAL(5,2) NOT NULL,
			`max_percentage` DECIMAL(5,2) NOT NULL,
			-- Board & compliance
			`board_code` VARCHAR(50),           -- CBSE, ICSE, STATE
			`academic_session_id` BIGINT UNSIGNED NULL,
			-- UX
			`display_order` SMALLINT UNSIGNED DEFAULT 1,
			`color_code` VARCHAR(10),
			-- Scope
			`scope` ENUM('SCHOOL','BOARD','CLASS') DEFAULT 'SCHOOL',
			`class_id` BIGINT UNSIGNED DEFAULT NULL,
			-- Control
			`is_locked` TINYINT(1) DEFAULT 0,   -- locked after result publishing
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL,
			UNIQUE KEY `uq_grade_code` (`code`, `grading_type`, `scope`, `class_id`),
			UNIQUE KEY `uq_scope_range` (`scope`, `class_id`, `min_percentage`, `max_percentage`),
			CHECK (`min_percentage` < `max_percentage`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
			-- Conditions:
			-- 1. The Schema does NOT prevent overlapping ranges like:
			--    - min_percentage = 80, max_percentage = 90
			--    - min_percentage = 85, max_percentage = 95
			-- 2. The Schema does NOT prevent ranges that do not cover the full range of 0-100%
			--    - min_percentage = 80, max_percentage = 100
			-- 3. Above 2 needs to be handled at the application level
			-- ✅ Enforce at application/service layer:
					SELECT 1
					FROM slb_performance_categories
					WHERE
					:new_min <= max_percentage
					AND :new_max >= min_percentage
					AND is_active = 1
					LIMIT 1;
			-- If row exists → ❌ reject insert/update
			-- 🎯 Special:
			-- 1. Scholl may have different System for different Boards / Classes, Which most of the ERP doesn't cover. e.g. Grade system till 8th and then 9-12 Division System
			--    Classes 1–3 → Emerging / Developing / Proficient
			--    Classes 4–8 → Good / Average / Below Average / Need Improvement / Poor
			--    Classes 9–12 → Topper / Excellent / Good / Average / Below Average / Need Improvement / Poor


-- ============================================================================================================
-- Module - Question Bank (qns)
-- ============================================================================================================

	-- Question Usage Type (Quiz / Quest / Exam)
	CREATE TABLE `qns_question_usage_type` (
			`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
			`code` VARCHAR(50) NOT NULL,  -- e.g. 'QUIZ','QUEST','ONLINE_EXAM','OFFLINE_EXAM','UT_TEST'
			`name` VARCHAR(100) NOT NULL, -- e.g. 'Quiz','Quest','Online Exam','Offline Exam','Unit Test'
			`description` TEXT DEFAULT NULL,
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP DEFAULT NULL,
			UNIQUE KEY `uq_q_usage_type_code` (`code`)
			UNIQUE KEY `uq_q_usage_type_name` (`name`)
	);


-- ============================================================================================================
-- Module - Recommendations (rec)
-- ============================================================================================================
	-- table for "trigger_event" ENUM values
	CREATE TABLE IF NOT EXISTS `rec_trigger_events` (
	`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`event_name` VARCHAR(50) NOT NULL,  -- ON_ASSESSMENT_RESULT, ON_TOPIC_COMPLETION, ON_ATTENDANCE_LOW, MANUAL_RUN, SCHEDULED_WEEKLY
	`description` VARCHAR(255) DEFAULT NULL,
	`is_active` TINYINT(1) DEFAULT 1,
	`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_recTriggerEvent_name` (`event_name`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

	-- table for "recommendation_mode" ENUM values
	CREATE TABLE IF NOT EXISTS `rec_recommendation_modes` (
	`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`mode_name` VARCHAR(50) NOT NULL,  -- SPECIFIC_MATERIAL, SPECIFIC_BUNDLE, DYNAMIC_BY_TOPIC, DYNAMIC_BY_COMPETENCY
	`description` VARCHAR(255) DEFAULT NULL,
	`is_active` TINYINT(1) DEFAULT 1,
	`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_recRecommendationMode_name` (`mode_name`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

	-- table for "dynamic_material_type" ENUM values
	CREATE TABLE IF NOT EXISTS `rec_dynamic_material_types` (
	`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`type_name` VARCHAR(50) NOT NULL,  -- ANY_BEST_FIT, VIDEO, QUIZ, PDF
	`description` VARCHAR(255) DEFAULT NULL,
	`is_active` TINYINT(1) DEFAULT 1,
	`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_recDynamicMaterialType_name` (`type_name`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

	-- table for "dynamic_purpose" ENUM values
	CREATE TABLE IF NOT EXISTS `rec_dynamic_purposes` (
	`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`purpose_name` VARCHAR(50) NOT NULL,  -- REMEDIAL, ENRICHMENT, PRACTICE
	`description` VARCHAR(255) DEFAULT NULL,
	`is_active` TINYINT(1) DEFAULT 1,
	`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_recDynamicPurpose_name` (`purpose_name`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

	-- table for "assessment_type" ENUM values
	CREATE TABLE IF NOT EXISTS `rec_assessment_types` (
	`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`type_name` VARCHAR(50) NOT NULL,  -- ALL, QUIZ, QUEST, WEEKLY_TEST, UNIT_TEST-1, TERM_EXAM, HALF_YEARLY_EXAM, FINAL_EXAM
	`description` VARCHAR(255) DEFAULT NULL,
	`is_active` TINYINT(1) DEFAULT 1,
	`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_recAssessmentType_name` (`type_name`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

	CREATE TABLE IF NOT EXISTS `rec_recommendation_materials` (
	`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`title` VARCHAR(255) NOT NULL,
	`description` TEXT DEFAULT NULL,
	-- Content Classification
	`material_type` BIGINT UNSIGNED DEFAULT NULL,    -- fk to sys_dropdown_table (e.g. 'TEXT','VIDEO','PDF','AUDIO','QUIZ','ASSIGNMENT','LINK','INTERACTIVE')
	`purpose` BIGINT UNSIGNED DEFAULT NULL,          -- fk to sys_dropdown_table (e.g. 'REVISION','PRACTICE','REMEDIAL','ADVANCED','ENRICHMENT','CONCEPT_BUILDING') NOT NULL DEFAULT 'PRACTICE',
	`complexity_level` BIGINT UNSIGNED DEFAULT NULL,  -- fk to slb_complexity_level
	-- Content Source
	`content_source` BIGINT UNSIGNED DEFAULT NULL,    -- fk to sys_dropdown_table (e.g. 'INTERNAL_EDITOR','UPLOADED_FILE','EXTERNAL_LINK','LMS_MODULE','QUESTION_BANK')


-- ============================================================================================================
-- Module - LMS EXAMS (Online & Offline) (lms)
-- ============================================================================================================
	
	CREATE TABLE `lms_exam_types` (
		`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`code` VARCHAR(20) NOT NULL,  -- e.g. 'UT-1','UT-2','UT-3','UT-4','HY-EXAM','ANNUAL-EXAM'
		`name` VARCHAR(100) NOT NULL, -- e.g. 'Unit Test 1','Unit Test 2','Unit Test 3','Unit Test 4','Half Yearly Exam','Annual Exam'
		`description` TEXT DEFAULT NULL,
		`is_active` TINYINT(1) DEFAULT 1,
		`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		`deleted_at` TIMESTAMP DEFAULT NULL,
		UNIQUE KEY `uq_q_usage_type_code` (`code`)
		UNIQUE KEY `uq_q_usage_type_name` (`name`)
	);


