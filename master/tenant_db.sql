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
CREATE VIEW glb_academic_sessions  AS SELECT * FROM global_master.glb_districts;
CREATE VIEW glb_boards     AS SELECT * FROM global_master.glb_cities;

-- ------------------------------------------------------------
-- System Tables
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sys_languages` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(10) NOT NULL,                  -- ISO code: en, hi, fr, ar
  `name` VARCHAR(50) NOT NULL,                  -- English, Hindi, French...
  `native_name` VARCHAR(50) DEFAULT NULL,       -- "हिन्दी", "Français"
  `direction` ENUM('LTR','RTL') DEFAULT 'LTR',  -- Left to Rght / Right to Left
  `is_active` TINYINT(1) DEFAULT 1,
  UNIQUE KEY `uq_languages_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_menus` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` bigint unsigned DEFAULT NULL,     -- FK to self
  `is_category` tinyint(1) NOT NULL DEFAULT '0',
  `code` varchar(60) NOT NULL,
  `slug` VARCHAR(150) NOT NULL,
  `title` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `icon` varchar(150) DEFAULT NULL,
  `route` varchar(255) DEFAULT NULL,
  `sort_order` int unsigned NOT NULL,
  `visible_by_default` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_menus_code` (`code`),
  CONSTRAINT `fk_menus_parentId` FOREIGN KEY (`parent_id`) REFERENCES `prm_menus` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `chk_is_category_parentId` CHECK ((((`is_category` = 1) and (`parent_id` is NULL)) or (`is_category` = 0)))
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_permissions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(20) NOT NULL,  -- This will be used for dropdown
  `name` varchar(100) NOT NULL,
  `guard_name` varchar(255) NOT NULL,  -- used by Laravel routing
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

CREATE TABLE IF NOT EXISTS `sys_role_has_permissions_jnt` (
  `permission_id` bigint unsigned NOT NULL,
  `role_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`permission_id`,`role_id`),
  KEY `idx_roleHasPermissions_roleId` (`role_id`),
  CONSTRAINT `fk_roleHasPermissions_permissionId` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_roleHasPermissions_roleId` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_model_has_permissions_jnt` (
  `permission_id` bigint unsigned NOT NULL,
  `model_type` varchar(190) NOT NULL,
  `model_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`permission_id`,`model_id`,`model_type`),
  KEY `idx_modelHasPermissions_modelId_modelType` (`model_id`,`model_type`),
  CONSTRAINT `fk_odelHasPermissions_permissionId` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_model_has_roles_jnt` (
  `role_id` bigint unsigned NOT NULL,
  `model_type` varchar(190) NOT NULL,
  `model_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`role_id`,`model_id`,`model_type`),
  KEY `idx_modelHasRoles_modelId_modelType` (`model_id`,`model_type`),
  CONSTRAINT `fk_modelHasRoles_roleId` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_modules` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` bigint unsigned DEFAULT NULL,    -- fk to self
  `name` varchar(50) NOT NULL,
  `version` tinyint NOT NULL DEFAULT '1',
  `is_sub_module` tinyint(1) NOT NULL DEFAULT '0',    -- kept for CONSTRAINT `chk_isSubModule_parentId`
  `description` varchar(500) DEFAULT NULL,
  `is_core` tinyint(1) NOT NULL DEFAULT '0',
  `default_visible` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_view` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_add` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_edit` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_delete` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_export` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_import` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_print` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_module_parentId_name_version` (`parent_id`,`name`,`version`),
  CONSTRAINT `fk_module_parentId` FOREIGN KEY (`parent_id`) REFERENCES `sys_modules` (`id`) ON DELETE RESTRICT,
  CONSTRAINT chk_isSubModule_parentId CHECK ((is_sub_module = 1 AND parent_id IS NOT NULL) OR (is_sub_module = 0 AND parent_id IS NULL))
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_menu_model_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `menu_id` bigint unsigned NOT NULL,
  `module_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_menuModel_menuId` FOREIGN KEY (`menu_id`) REFERENCES `sys_menus` (`id`)  ON DELETE RESTRICT,
  CONSTRAINT `fk_menuModel_moduleId` FOREIGN KEY (`module_id`) REFERENCES `sys_modules` (`id`)  ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `emp_code` VARCHAR(20) NOT NULL,
  `short_name` varchar(30) NOT NULL,   -- This Field will be used for showing Dropdown of Users i.e. Teachers, Students, Parents
  `name` varchar(100) NOT NULL,        -- Full Name (First Name, Middle Name, Last Name)
  `email` varchar(150) NOT NULL,
  `mobile_no` varchar(32) DEFAULT NULL,
  `phone_no` varchar(32) DEFAULT NULL,
  `two_factor_auth_enabled` tinyint(1) NOT NULL DEFAULT '0',
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `mobile_verified_at` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `password` varchar(255) COLLATE utf8mb4_unicode_bin NOT NULL,
  `is_super_admin` tinyint(1) NOT NULL DEFAULT '0',
  `last_login_at` datetime DEFAULT NULL,
  `super_admin_flag` tinyint GENERATED ALWAYS AS ((case when (`is_super_admin` = 1) then 1 else NULL end)) STORED,
  `remember_token` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_empCode` (`emp_code`),
  UNIQUE KEY `uq_users_shortName` (`short_name`),
  UNIQUE KEY `uq_users_email` (`email`),
  UNIQUE KEY `uq_users_mobileNo` (`mobile_no`),
  UNIQUE KEY `uq_single_super_admin` (`super_admin_flag`)
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

CREATE TABLE IF NOT EXISTS `sys_dropdown_table` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `ordinal` tinyint unsigned NOT NULL,
  `key` varchar(50) NOT NULL,
  `value` varchar(100) NOT NULL,
  `type` ENUM('String','Integer','Decimal', 'Date', 'Datetime', 'Time', 'Boolean') NOT NULL DEFAULT 'String',
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dropdownTable_ordinal_key` (`ordinal`,`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_media` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `model_type` varchar(255) NOT NULL,
  `model_id` bigint unsigned NOT NULL,
  `uuid` char(36) DEFAULT NULL,
  `collection_name` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `mime_type` varchar(255) DEFAULT NULL,
  `disk` varchar(255) NOT NULL,
  `conversions_disk` varchar(255) DEFAULT NULL,
  `size` bigint unsigned NOT NULL,
  `manipulations` json NOT NULL,
  `custom_properties` json NOT NULL,
  `generated_conversions` json NOT NULL,
  `responsive_images` json NOT NULL,
  `order_column` int unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_media_uuid` (`uuid`),
  KEY `idx_media_modelType_modelId` (`model_type`,`model_id`),
  KEY `idx_media_orderColumn` (`order_column`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- For MultiLingual Support
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sys_menu_translations` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `menu_id` BIGINT UNSIGNED NOT NULL,
  `language_id` BIGINT UNSIGNED NOT NULL,
  `translated_title` VARCHAR(150) NOT NULL,
  `translated_description` VARCHAR(255) DEFAULT NULL,
  UNIQUE KEY `uq_menu_lang` (`menu_id`,`language_id`),
  CONSTRAINT `fk_menu_translation_menuId` FOREIGN KEY (`menu_id`) REFERENCES `sys_menus` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_menu_translation_langId` FOREIGN KEY (`language_id`) REFERENCES `sys_languages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_masters_translations` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `model_type` VARCHAR(190) NOT NULL,   -- Laravel morph type (e.g., 'App\\Models\\Menu')
  `model_id` BIGINT UNSIGNED NOT NULL,  -- The actual record ID in that model
  `language_code` VARCHAR(10) NOT NULL, -- e.g., 'en', 'hi', 'fr'
  `field_name` VARCHAR(100) NOT NULL,   -- e.g., 'name', 'description', 'title'
  `translated_value` TEXT NOT NULL,     -- the actual translation
  UNIQUE KEY `uq_mastersTrans_modelType_modelId_lang_field` (`model_type`, `model_id`, `language_code`, `field_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- ------------------------------------------------------------
-- Tanent Database
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_organizations` (
  `id` bigint unsigned NOT NULL,        -- it will have same id as it is in 'prm_tenant'
  `group_code` varchar(20) NOT NULL,
  `group_short_name` varchar(50) NOT NULL,
  `group_name` varchar(150) NOT NULL,
  `code` varchar(20) NOT NULL,
  `short_name` varchar(50) NOT NULL,
  `name` varchar(150) NOT NULL,
  `udise_code` varchar(30) DEFAULT NULL,
  `affiliation_no` varchar(60) DEFAULT NULL,
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
  `established_date` date DEFAULT NULL,  -- School Established Date
  `flg_single_record` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `chk_org_singleRecord` (`flg_single_record`),
  CONSTRAINT fk_organizations_cityId FOREIGN KEY (city_id) REFERENCES glb_cities (id) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ========================================================================================================

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


CREATE TABLE IF NOT EXISTS `sch_classes` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,                -- e.g. 'Grade 1' or 'Class 10'
  `short_name` varchar(10) DEFAULT NULL,      -- e.g. 'G1' or '10A'
  `ordinal` tinyint DEFAULT NULL,        -- This is signed tinyint to have (-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10,11,12)
  `code` CHAR(3) NOT NULL,         -- e.g., 'BV1','BV2','1st','1' and so on (This will be used for Timetable)
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
  `code` CHAR(1) NOT NULL,         -- e.g., 'A','B','C','D' and so on (This will be used for Timetable)
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
  `class_id` int unsigned NOT NULL,     -- fk
  `section_id` int unsigned NOT NULL,   -- fk
  `class_secton_code` char(5) NOT NULL,       -- Combination of class Code + section Code i.e. '8th_A', '10h_B'  
  `capacity` tinyint unsigned DEFAULT NULL,        -- Targeted / Planned Quantity of stundets in Each Sections of every class.
  `total_student` tinyint unsigned DEFAULT NULL,   -- Actual Number of Student in the Class+Section
  `class_teacher_id` bigint unsigned NOT NULL,     -- fk
  `assistance_class_teacher_id` bigint unsigned NOT NULL,  -- fk  
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_classSection_classId_sectionId` (`class_id`,`section_id`),
  UNIQUE KEY `uq_lassSection_code` (`class_secton_code`),
  CONSTRAINT `fk_classSection_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_classSection_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_classSection_sclassTeacherId` FOREIGN KEY (`class_teacher_id`) REFERENCES `sch_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_classSection_AssClassTeacherId` FOREIGN KEY (`assistance_class_teacher_id`) REFERENCES `sch_users` (`id`) ON DELETE CASCADE
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
  `short_name` varchar(20) NOT NULL,
  `name` varchar(50) NOT NULL,
  `code` CHAR(3) NOT NULL,         -- e.g., 'LAC','LAB','ACT','ART' and so on (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_studyFormats_shortName` (`short_name`),
  UNIQUE KEY `uq_studyFormats_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_subjects` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `short_name` varchar(20) NOT NULL,
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

-- There will be a Variable in 'sys_settings' table named 'SubjectGroup_Used_For_All_Sections' (Subj_Group_will_be_used_for_all_sections_of_a_class)
-- if above variable is True then section_id will be Nul in below table and
CREATE TABLE IF NOT EXISTS `sch_subject_study_format_class_subj_types_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,                  -- FK
  `subject_Study_format_id` bigint unsigned NOT NULL,   -- FK
  `class_id` int NOT NULL,                              -- FK
  `section_id` int NULL,                                -- FK (Section can be null if Group will be used for all sectons)
  `subject_type_id` int unsigned NOT NULL,              -- FK
  `rooms_type_id` bigint unsigned NOT NULL,             -- FK
  `name` varchar(50) NOT NULL,                          -- 10th-A Science Lacture Major
  `clas_subj_stdformat_Subjtyp_code` CHAR(17) NOT NULL, -- Combination of (Class+Section+Subject+StudyFormat+SubjType) e.g., '10h_A_SCI_LAC_MAJ','7th_A_SAN_OPT' (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subStdFmtClsSubjTyp_subStdFmt_cls_Sec_SubTyp` (`subject_Study_format_id`,`class_id`,`section_id`,`subject_type_id`),
  UNIQUE KEY `uq_subStdFmtClsSubjTyp_subStdformatCode` (`clas_subj_stdformat_Subjtyp_code`),
  CONSTRAINT `fk_subStdFmtClsSubjTyp_subjStudyFormatId` FOREIGN KEY (`subject_Study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subStdFmtClsSubjTyp_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subStdFmtClsSubjTyp_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subStdFmtClsSubjTyp_subTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subStdFmtClsSubjTyp_roomTypeId` FOREIGN KEY (`rooms_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Added rooms_type_id field & FK for it.


-- Table 'sch_subject_groups' will be used to assign all subjects to the students
-- There will be a Variable in 'sch_settings' table named 'SubjGroup_For_All_Sections' (Subj_Group_will_be_used_for_all_sections_of_a_class)
-- if above variable is True then section_id will be Nul in below table and
-- Every Group will eb avalaible accross sections for a particuler class
CREATE TABLE IF NOT EXISTS `sch_subject_groups` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `class_id` int NOT NULL,                        -- FK
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
  `subject_group_id` bigint unsigned NOT NULL,                  -- FK
  `subj_stdformat_class_subjtypes_id` bigint unsigned NOT NULL, -- FK
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subjGrpSubj_subjGrpId_subjStdFmtClsSubTyp` (`subject_group_id`,`subj_stdformat_class_subjtypes_id`),
  CONSTRAINT `fk_subjGrpSubj_subjectGroupId` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subjGrpSubj_subjStdFmtClsSubTyp` FOREIGN KEY (`subj_stdformat_class_subjtypes_id`) REFERENCES `sch_subject_study_format_class_subj_types_jnt` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_rooms_type` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `code` CHAR(7) NOT NULL,                       -- e.g., 'SCI_LAB','BIO_LAB','CRI_GRD','TT_ROOM','BDM_CRT'
  `short_name` varchar(30) NOT NULL,             -- e.g., 'Science Lab','Biology Lab','Cricket Ground','Table Tanis Room','Badminton Court'
  `name` varchar(100) NOT NULL,
  `required_resources` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_roomType_code` (`code`),
  UNIQUE KEY `uq_roomType_shortName` (`short_name`)
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
  `building_id` int unsigned NOT NULL,   -- FK
  `room_type_id` int NOT NULL,           -- FK
  `code` CHAR(7) NOT NULL,               -- e.g., '11G-10A','12F-11A','11S-12A' and so on (This will be used for Timetable)
  `short_name` varchar(30) NOT NULL,     -- e.g., 'Junior Wing','Primary Wing','Middle Wing','Senior Wing','Administration Wings'
  `name` varchar(50) NOT NULL,
  `capacity` int unsigned DEFAULT NULL,
  `max_limit` int unsigned DEFAULT NULL,
  `resource_tags` text DEFAULT NULL,
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

CREATE TABLE IF NOT EXISTS `sch_teachers_profile` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `teacher_id` BIGINT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `study_format_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `priority` ENUM('PRIMARY','SECONDARY') NOT NULL DEFAULT 'PRIMARY',
  `proficiency` INT UNSIGNED DEFAULT NULL,          -- 1–10 rating or %
  `special_skill_area` VARCHAR(100) DEFAULT NULL,   -- e.g. Robotics, AI, Debate
  `certified_for_lab` TINYINT(1) DEFAULT 0,         -- allowed to conduct practicals
  `assignment_meta` JSON DEFAULT NULL,              -- e.g. { "qualification": "M.Sc Physics", "experience": "7 years" }
  `notes` TEXT NULL,
  `effective_from` DATE DEFAULT NULL,
  `effective_to` DATE DEFAULT NULL,
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
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
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
  `gender` ENUM('Male','Female','Transgender','Prefer Not to Say') NOT NULL, DEFAULT 'Male',
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
  `guardian_is` ENUM('Father','Mother','Other') NOT NULL, DEFAULT 'Father',
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

CREATE TABLE IF NOT EXISTS `zst_student_sessions_jnt` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` BIGINT UNSIGNED NOT NULL,            -- FK
  `admission_no` VARCHAR(50) NOT NULL,
  `roll_no` INT DEFAULT NULL,
  `admission_date` DATE DEFAULT NULL,
  `registration_no` VARCHAR(50) DEFAULT NULL,
  `default_mobile` ENUM('Father','Mother','Guardian','All') NOT NULL, DEFAULT 'Mother',
  `default_email` ENUM('Father','Mother','Guardian','All') NOT NULL, DEFAULT 'Mother',
  `academic_sessions_id` bigint unsigned NOT NULL,  -- FK - sch_org_academic_sessions_jnt
  `class_section_id` INT UNSIGNED NOT NULL,         -- FK (Instead of selecting Class & Section, we will be using Class+Section)
  `subject_group_id` BIGINT UNSIGNED NOT NULL,      -- FK - sch_subject_groups
  `session_status_id` BIGINT UNSIGNED DEFAULT NULL, -- FK - gl_dropdown_table
  `is_current` TINYINT(1) DEFAULT 1,  -- Only one session can be current at a time for one student
  `current_flag` bigint GENERATED ALWAYS AS ((case when (`is_current` = 1) then `student_id` else NULL end)) STORED,
  `leaving_date` DATE DEFAULT NULL,
  `reason_quit` int NULL,                       -- FK to `gl_dropdown_table`
  `dis_note` text NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_studentSessions_currentFlag` (`current_flag`)
  CONSTRAINT `fk_studentSessions_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_academicSession` FOREIGN KEY (`academic_sessions_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_subjGroupId` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_sessionStatusId` FOREIGN KEY (`session_status_id`) REFERENCES `gl_dropdown_table` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_reasonQuit` FOREIGN KEY (`reason_quit`) REFERENCES `gl_dropdown_table` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- ===============================================================================================================
-- Timetable Module

-- We will create Group accros classes who can be taught in a single group like 'Dance' can be taught in a single group from class 6-10th,
-- but we need to have a separate group for junior classes for same subject 'Dance'

-- subject_group is grouping of Subject+Study Format+Class+Section+Subject Type.
-- It answer whether 'Science' 'Lacture' for 7th-A is Major or Minor.
-- This will also be used to assign Subjects to the Students as a Combo.
CREATE TABLE IF NOT EXISTS `tim_class_groups` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `subject_study_format_id` bigint unsigned NOT NULL,    -- FK
  `class_section_id` json NOT NULL,                      -- FK
  `subject_type_id` int unsigned NOT NULL,               -- FK
  `short_name` varchar(30) NOT NULL,         -- 7th Science, 7th Commerce, 7th-A Science etc.
  `name` varchar(100) NOT NULL,
  `class_group_code` VARCHAR(7) NOT NULL,   -- e.g., '7th_A_SCI_LAC','7th_A_SCI_LAB','7th_A_SST_LAC','7th_A_ENG_LAC' (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subGroups_shortName` (`short_name`),
  UNIQUE KEY `uq_subGroups_classGroupCode` (`class_group_code`),
  CONSTRAINT `fk_subGroups_subject_format_id` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subGroups_class_section_id` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Combination of (class, section, subject, study_format). This will help to combine classes for Optioal Subjects
-- It will answer - which all classes can be combined for a particuler Subject + StudyFormat
CREATE TABLE IF NOT EXISTS `tim_class_groups` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `class_section_id` int unsigned NOT NULL,  -- FK
  `subject_id` bigint unsigned NOT NULL,     -- FK
  `study_format_id` int unsigned NOT NULL,
  `short_name` varchar(20) DEFAULT NULL,
  `name` varchar(100) DEFAULT NULL,
  `preferred_weekly_frequency` tinyint unsigned DEFAULT NULL,  -- need to removed from here. this need to be set at Subject+class level
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cls_grps_section_sub_studyformat` (`class_section_id`,`subject_id`,`study_format_id`),
  CONSTRAINT `fk_cls_grps_class_section_id` FOREIGN KEY (`class_section_id`) REFERENCES `class_section` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cls_grps_subject_id` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cls_grps_study_format_id` FOREIGN KEY (`study_format_id`) REFERENCES `study_formats` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=501 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tim_teacher_constraint` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  `max_periods_per_week` INT UNSIGNED DEFAULT NULL,
  `max_periods_per_day` INT UNSIGNED DEFAULT NULL,
  `max_days_per_week` INT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tim_class_sub_group` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `subject_id` BIGINT UNSIGNED NOT NULL,       -- Math, Sci
  `study_format_id` int unsigned NOT NULL,     -- Lecture, Lab
  `class_section_id` int unsigned NOT NULL,
  `short_name` varchar(20) DEFAULT NULL,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `total_students` INT UNSIGNED DEFAULT NULL,
  `is_shared_across_classes` TINYINT(1) DEFAULT 0,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_sub_comb_group_subj_name` (`subject_id`,`group_name`),
  CONSTRAINT `fk_sub_comb_group_subj` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sub_comb_group_study_format` FOREIGN KEY (`study_format_id`) REFERENCES `study_formats` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_period_definitions` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(1) NOT NULL,         -- e.g., '1','2','3' and so on (This will be used for Timetable)
  `short_name` VARCHAR(10) NOT NULL,  -- e.g., "Period-1 / P-1,P2"
  `name` VARCHAR(50) NOT NULL,        -- e.g., "Lunch Break, Prayer, Class"
  `start_time` TIME NOT NULL,
  `end_time` TIME NOT NULL,
  `is_break` TINYINT(1) DEFAULT 0,
  `sort_order` TINYINT UNSIGNED DEFAULT 1,
  `is_active` TINYINT(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- Syllabus Module
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_lessons` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,                -- e.g. 'Grade 1' or 'Class 10'
  `code` varchar(7) DEFAULT NULL,      -- e.g. '9th_SCI', '8TH_MAT' (Auto Generate on the basis of Class & Subject Code)
  `class_id` BIGINT UNSIGNED NOT NULL,         -- FK to sch_classes 
  `subject_id` bigint unsigned NOT NULL,       -- FK to sch_subjects  
  `ordinal` tinyint DEFAULT NULL,        -- This is signed tinyint to have (1,2,3,4,5....10) lessons in a subject for a class 
  `description` text DEFAULT NULL,
  `duration` int unsigned NULL,    -- No of Periods required to complete this lesson
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lesson_classId_SubjectId_name` (`class_id`,'subject_id','name'),
  UNIQUE KEY `uq_lesson_classId_SubjectId_ordinal` (`class_id`,'subject_id',`ordinal`),
  CONSTRAINT `fk_lesson_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_lesson_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
