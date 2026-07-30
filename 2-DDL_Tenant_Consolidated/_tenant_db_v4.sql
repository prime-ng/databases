-- ===========================================================================
-- Tenant Database (tenant_db_v4)
-- ===========================================================================
-- FOUNDATIONAL & CORE MODULE — VERSION 3.0 (PRODUCTION-GRADE)
-- Enhanced from tenant_db_v3.sql
-- Target: MySQL 8.x | Stack: PHP + Laravel
-- Architecture: Multi-tenant (runs inside tenant_db)
-- Creation Date: 25-Jun-2026
-- This DDL have Tables which will be used in all the Modules
-- ===========================================================================


-- ========================================================================================
-- VIEWS - In Production, we will create Views for all the Tables in global_master database
-- but in Local Dev Environment, all the Tables from global_master has been added here
-- ========================================================================================

  -- CREATE VIEW glb_countries  AS SELECT * FROM global_master.glb_countries;
  -- CREATE VIEW glb_states     AS SELECT * FROM global_master.glb_states;
  -- CREATE VIEW glb_districts  AS SELECT * FROM global_master.glb_districts;
  -- CREATE VIEW glb_cities     AS SELECT * FROM global_master.glb_cities;
  -- CREATE VIEW glb_academic_sessions  AS SELECT * FROM global_master.glb_academic_sessions;
  -- CREATE VIEW glb_boards     AS SELECT * FROM global_master.glb_boards;
  -- CREATE VIEW glb_languages AS SELECT * FROM global_master.glb_languages;
  -- CREATE VIEW glb_menus AS SELECT * FROM global_master.glb_menus;
  -- CREATE VIEW glb_modules AS SELECT * FROM global_master.glb_modules;
  -- CREATE VIEW glb_menu_model_jnt AS SELECT * FROM global_master.glb_menu_model_jnt;
  -- CREATE VIEW glb_translations AS SELECT * FROM global_master.glb_translations;


-- ========================================================================================================================
-- FOUNDATIONAL SCHOOL SETUP (sch)
-- ========================================================================================================================
  -- This table is a replica of 'prm_tenant' table in 'prmprime_db' database
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_organizations` (
    `id` SMALLINT unsigned NOT NULL,            -- it will have same id as it is in 'prm_tenant'
    `group_code` varchar(20) NOT NULL,          -- Code for Grouping of Organizations/Schools
    `group_short_name` varchar(50) NOT NULL,
    `group_name` varchar(150) NOT NULL,
    `code` varchar(20) NOT NULL,                -- School Code
    `short_name` varchar(50) NOT NULL,
    `name` varchar(150) NOT NULL,
    `udise_code` varchar(30) DEFAULT NULL,      -- U-DISE Code of the School
    `affiliation_no` varchar(60) DEFAULT NULL,  -- Affiliation Number of the School
    `crc_code` varchar(30) DEFAULT NULL,        -- CRC Code of the School
    `brc_code` varchar(30) DEFAULT NULL,        -- BRC Code of the School
    `instruction_language` varchar(20) DEFAULT NULL,  -- FK to sys_dropdown_table.id
    `rural_urban` ENUM('RURAL','URBAN') DEFAULT 'URBAN',     -- Rural/Urban of the School
    `email` varchar(100) DEFAULT NULL,
    `website_url` varchar(150) DEFAULT NULL,
    `address_1` varchar(200) DEFAULT NULL,
    `address_2` varchar(200) DEFAULT NULL,
    `area` varchar(100) DEFAULT NULL,
    `city_id` INT unsigned NOT NULL,
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
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction Table to link Organizations with Academic Sessions
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_org_academic_sessions_jnt` (
    `id` SMALLINT unsigned NOT NULL AUTO_INCREMENT,
    `academic_sessions_id` INT unsigned NOT NULL,   -- FK to glb_academic_sessions.id
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
  -- Condition:
  -- Start Date < End Date
  -- Check at Add/Edit - New Start date & End Date can not overlape with existing Start date & End Date. Trigger to check this.

  -- Junction Table to link Organizations with Boards
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_board_organization_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `academic_sessions_id` INT unsigned NOT NULL,
    `board_id` INT unsigned NOT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_boardOrg_boardId` FOREIGN KEY (`board_id`) REFERENCES `glb_boards` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_boardOrg_academicSessionId` FOREIGN KEY (`academic_sessions_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ========================================================================================================================
-- CORE SCHOOL SETUP (sch)
-- Check - Table `sch_categories` & `sch_disable_reasons`, may be used in Student. If not then Removed these also.
-- ========================================================================================================================
  -- This will be a Master Table to control the configurations for all modules.
  -- Tenant can only Edit this table. No one can Add or Delete any record.
  -- "key" will be defined by Developer only. No one can see or Change it.
  -- ----------------------------------------------------------------------------------------

  CREATE TABLE IF NOT EXISTS `sch_config` (
    `id` SMALLINT unsigned NOT NULL AUTO_INCREMENT,
    `module_id` INT unsigned NOT NULL,                     -- FK to glb_modules.id to identify which module this config belongs to (e.g. Student Mgmt., Teacher Mgmt., Class Mgmt.)
    `module_code` varchar(3) NOT NULL,                     -- FK TO glb_modules.code
    `ordinal` int unsigned NOT NULL DEFAULT '1',
    `key` varchar(150) NOT NULL,                           -- Can not changed by user (He can edit other fields only but not KEY)
    `key_name` varchar(150) NOT NULL,                      -- Can be Changed by user
    `value` varchar(512) NOT NULL,                         -- Can be Changed by user
    `value_type` ENUM('STRING', 'NUMBER', 'BOOLEAN', 'DATE', 'TIME', 'DATETIME', 'JSON') NOT NULL,
    `description` varchar(255) NOT NULL,
    `additional_info` JSON DEFAULT NULL,
    `tenant_can_modify` tinyint(1) NOT NULL DEFAULT '0',
    `mandatory` tinyint(1) NOT NULL DEFAULT '1',
    `used_by_app` tinyint(1) NOT NULL DEFAULT '1',
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_settings_ordinal` (`ordinal`),
    UNIQUE KEY `uq_settings_key` (`key`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Data Seed for sch_config
    -- INSERT INTO `sch_config` (`module_id`,`ordinal`,`key`,`key_name`,`value`,`value_type`,`description`,`additional_info`,`tenant_can_modify`,`mandatory`,`used_by_app`,`is_active`,`deleted_at`,`created_at`,`updated_at`) VALUES
    -- (`LMS`,1,'performance_percentage_threshold_to_reassign_quiz', 'Performance Percentage Threshold to Reassign Quiz to a Student', '35', 'NUMBER', 'If Student Performance falls below this threshold, system will generate a new Quiz and will reassign it to the student', NULL, 1, 1, 1, 1, NULL, NULL, NULL),
    -- (`SLB`,2,'performance_percentage_threshold_to_reassign_quiz', 'Performance Percentage Threshold to Reassign Quiz to a Student', '35', 'NUMBER', 'If Student Performance falls below this threshold, system will generate a new Quiz and will reassign it to the student', NULL, 1, 1, 1, 1, NULL, NULL, NULL),
    -- (`SLB`,3,'syllabus_teaching_estimation_level_for_lesson_planning', 'At which level (Lesson/Topic/Sub-Topic/Mini-Topic) teacher will provide Syllabus Teaching Estimation', 'Topic', 'STRING', 'At which level (Lesson/Topic/Sub-Topic/Mini-Topic) teacher will provide Syllabus Teaching Estimation', NULL, 1, 1, 1, 1, NULL, NULL, NULL),
    -- (`SLB`,4,'homework_released_on_syllabus_level', 'At which level (Lesson/Topic/Sub-Topic/Mini-Topic/Micro-Topic/Nano-Topic) homework will be released', 'Topic', 'STRING', 'At which level (Lesson/Topic/Sub-Topic/Mini-Topic/Micro-Topic/Nano-Topic) homework will be released', NULL, 1, 1, 1, 1, NULL, NULL, NULL),
    -- (`SLB`,5,'quiz_released_on_syllabus_level', 'At which level (Lesson/Topic/Sub-Topic/Mini-Topic/Micro-Topic/Nano-Topic) Quiz will be released', 'Topic', 'STRING', 'At which level (Lesson/Topic/Sub-Topic/Mini-Topic/Micro-Topic/Nano-Topic) Quiz will be released', NULL, 1, 1, 1, 1, NULL, NULL, NULL),
    -- (`SLB`,6,'quest_released_on_syllabus_level', 'At which level (Lesson/Topic/Sub-Topic/Mini-Topic/Micro-Topic/Nano-Topic) Quest will be released', 'Topic', 'STRING', 'At which level (Lesson/Topic/Sub-Topic/Mini-Topic/Micro-Topic/Nano-Topic) Quest will be released', NULL, 1, 1, 1, 1, NULL, NULL, NULL),
  

  -- This Table will be used to capture Departments
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_department` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL, -- e.g. "Transport", "Academic", "Rash Driving"
    `code` VARCHAR(30) DEFAULT NULL, -- Optional short code e.g. "TPT", "ACD"
    `is_system` TINYINT(1) DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
  -- Transport Department Name MUST be "Transport" (case-sensitive) & is_system = 1 (Can not be Edit or Deleted)

  -- This Table will be used to capture Designation
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_designation` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL, -- e.g. "Teacher", "Staff", "Student"
    `code` VARCHAR(30) DEFAULT NULL, -- Optional short code e.g. "TCH", "STF", "STD"
    `is_system` TINYINT(1) DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- This table will capture different categories for both students and staff.
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_categories` (
    `id`     INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`       VARCHAR(30) NOT NULL,
    `name`       VARCHAR(100) NOT NULL,
    `description`         VARCHAR(255) NULL,
    `applicable_for`      ENUM('STUDENT','STAFF','BOTH') NOT NULL,
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    UNIQUE KEY `uq_student_category_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- This table will capture the reasons for disabling a student or staff. 
  -- It will be used in disable/enable operations and reporting.
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_disable_reasons` (
    `id`     INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`         VARCHAR(30) NOT NULL,
    `name`         VARCHAR(150) NOT NULL,
    `description`         VARCHAR(255) NULL,
    `is_reversible`       TINYINT(1) NOT NULL DEFAULT 1,
    `applicable_for`      ENUM('STUDENT','STAFF','BOTH') NOT NULL,
    `count_attrition`     TINYINT(1) NOT NULL DEFAULT 0,
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    UNIQUE KEY `uq_disable_reason_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- This table will facilitate to create Groups of different department, Roles, Designations etc.
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_entity_groups` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `entity_purpose_id` INT UNSIGNED NOT NULL, -- FK to sys_dropdown_table e.g. (escalation_management, notification, event_supervision, exam_supervision)
    `code` VARCHAR(30) DEFAULT NULL, -- Optional short code e.g. "All_Class_Teachers", "Stundets_Play_Cricket", "Students_Participate_Annual_day"
    `name` VARCHAR(100) NOT NULL, -- e.g. "Class Teachers for all the classes", "Students Registered for Cricket", "All Students Participate in Annual Day"
    `description` VARCHAR(512) DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition: 
    -- This table will be used to get Entity Group, which will be a combination of differet type of Entities.
    -- 'entity_purpose_id' will be used to filter the Entity Group created for some purpose.
    -- e.g. "Tour Supervisors" which can be a combination of Students & Teachers, "Event Organizers" which can be a combination of Students & Teachers.

  -- This table will be used to store the members of the Entity Group.
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_entity_groups_members` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `entity_group_id` INT UNSIGNED DEFAULT NULL, -- FK to sch_entity_groups
    `entity_type_id` INT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table (1=Class, 2=Section, 3=Subject, 4=Designation, 5=Department, 6=Role etc.)
    `entity_table_name` VARCHAR(60) DEFAULT NULL, -- Entity Table Name e.g. "sch_class", "sch_section", "sch_subject", "sch_designation", "sch_department", "sch_role"
    `entity_selected_id` INT UNSIGNED DEFAULT NULL, -- Foriegn Key will be managed at Application Level as it will be different for different entities e.g. sch_class.id, sch_section.id, sch_subject.id, sch_designation.id, sch_department.id, sch_role.id etc.
    `entity_name` VARCHAR(100) DEFAULT NULL, -- Entity Name e.g. "Students of Class-1st", "Students of Section-7th_A", "Students of Subject-English", "Students of Designation-Teacher", "Students of Department-Transport", "Role-School Principal"
    `entity_code` VARCHAR(30) DEFAULT NULL, -- Entity Code e.g. "STD_CLS_1", "STD_SEC_7th_A", "STD_SUB_English", "STU_DES_Teacher", "STU_DEP_Transport", "ROL_School_Principal"
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_entity_group_id` FOREIGN KEY (`entity_group_id`) REFERENCES `sch_entity_groups` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_entity_type_id` FOREIGN KEY (`entity_type_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 
  -- Condition: 
    -- entity_type = (1=Class, 2=Section, 3=Subject, 4=Designation, 5=Department, 6=Role, 7=Students, 8=Staff, 9=Vehicle, 10=Facility, 11=Event, 12=Location, 13=Other)
    -- We will be storing table name to use for selecting entities in `additional_info` in `sys_dropdown_table` table alongwith entity_type menu items e.g. for entity_type=1, table_name="sch_class", for entity_type=9, table_name="sch_vehicle"
    -- entity_table_name will be fetched from `additional_info` in `sys_dropdown_table` table e.g. (sch_class, sch_section, sch_subject, sch_designation, sch_department, sch_role, sch_students, sch_staff, sch_vehicle, sch_facility, sch_event, sch_location, sch_other)


-- ========================================================================================================================
-- SYSTEM MODULE (sys)
-- ========================================================================================================================

  -- Tables for Role Based Access Control (RBAC) using spatie/laravel-permission package
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sys_permissions` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `short_name` VARCHAR(20) NOT NULL,            -- This will be used for dropdown
    `name` varchar(100) NOT NULL,
    `guard_name` varchar(255) NOT NULL,           -- used by Laravel routing
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_permissions_shortName_guardName` (`short_name`,`guard_name`),
    UNIQUE KEY `uq_permissions_name_guardName` (`name`,`guard_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- This table will be used to store the roles of the user.
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sys_roles` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `name` varchar(50) NOT NULL,
    `short_name` VARCHAR(20) NOT NULL,
    `description` VARCHAR(255) NULL,
    `guard_name` varchar(255) NOT NULL,         -- used by Laravel routing
    `is_system`  TINYINT(1) NOT NULL DEFAULT 0, -- if true, role belongs to PG
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_roles_name_name_guardName` (`name`,`guard_name`),
    UNIQUE KEY `uq_roles_name_shortName_guardName` (`short_name`,`guard_name`) 
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction Tables for Many-to-Many Relationships
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sys_role_has_permissions_jnt` (
    `permission_id` INT unsigned NOT NULL,   -- FK to sys_permissions
    `role_id` INT unsigned NOT NULL,         -- FK to sys_roles
    PRIMARY KEY (`permission_id`,`role_id`),
    KEY `idx_roleHasPermissions_roleId` (`role_id`),
    CONSTRAINT `fk_roleHasPermissions_permissionId` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`),
    CONSTRAINT `fk_roleHasPermissions_roleId` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction Tables for Polymorphic Many-to-Many Relationships
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sys_model_has_permissions_jnt` (
    `permission_id` INT unsigned NOT NULL,   -- FK to sys_permissions
    `model_type` varchar(190) NOT NULL,      -- E.g., 'App\Models\User'
    `model_id` INT unsigned NOT NULL,        -- E.g., User ID
    PRIMARY KEY (`permission_id`,`model_id`,`model_type`),
    KEY `idx_modelHasPermissions_modelId_modelType` (`model_id`,`model_type`),
    CONSTRAINT `fk_modelHasPermissions_permissionId` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`),
    CONSTRAINT `fk_modelHasPermissions_modelId_modelType` FOREIGN KEY (`model_id`) REFERENCES `sys_models` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction Tables for Polymorphic Many-to-Many Relationships
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sys_model_has_roles_jnt` (
    `role_id` INT unsigned NOT NULL,       -- FK to sys_roles
    `model_type` varchar(190) NOT NULL,       -- E.g., 'App\Models\User'
    `model_id` INT unsigned NOT NULL,      -- E.g., User ID
    PRIMARY KEY (`role_id`,`model_id`,`model_type`),
    KEY `idx_modelHasRoles_modelId_modelType` (`model_id`,`model_type`),
    CONSTRAINT `fk_modelHasRoles_roleId` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`),
    CONSTRAINT `fk_modelHasRoles_modelId_modelType` FOREIGN KEY (`model_id`) REFERENCES `sys_models` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- This table will be used to store the users of the system.
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sys_users` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `emp_code` VARCHAR(20) NOT NULL,        -- Employee Code (Unique code for each user)
    `short_name` varchar(30) NOT NULL,      -- This Field will be used for showing Dropdown of Users i.e. Teachers, Students, Parents
    `name` varchar(100) NOT NULL,           -- Full Name (First Name, Middle Name, Last Name)
    `user_type` ENUM('PRIME','EMPLOYEE' ,'TEACHER', 'STUDENT', 'PARENT', 'OTHER') NOT NULL,  -- Type of user
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
    `prefered_language` INT unsigned NOT NULL,                 -- fk to glb_languages
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

  -- Triggers - to prevent deleting/demoting super admin (you already used triggers for sessions)
    DELIMITER $$
    -- 1. Handle Delete Trigger
    DROP TRIGGER IF EXISTS trg_users_prevent_delete_super$$

    CREATE TRIGGER trg_users_prevent_delete_super BEFORE DELETE ON sys_users
    FOR EACH ROW
    BEGIN
      IF OLD.is_super_admin = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Super Admin cannot be deleted';
      END IF;
    END$$
    -- 2. Handle Update Trigger
    DROP TRIGGER IF EXISTS trg_users_prevent_update_super$$

    CREATE TRIGGER trg_users_prevent_update_super BEFORE UPDATE ON sys_users
    FOR EACH ROW
    BEGIN
      IF OLD.is_super_admin = 1 AND NEW.is_super_admin = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Super Admin cannot be demoted';
      END IF;
    END$$
  DELIMITER ;
  
  -- This table will store various system-wide settings and configurations
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sys_settings` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
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

  -- Table to store media files associated with various models (e.g., users, posts)
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sys_media` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `model_type` varchar(255) NOT NULL,           -- E.g., 'App\Models\User'
    `model_id` INT unsigned NOT NULL,          -- E.g., User ID
    `uuid` char(36) DEFAULT NULL,                 -- Universally Unique Identifier for the media
    `collection_name` varchar(255) NOT NULL,      -- E.g., 'avatars', 'documents'
    `name` varchar(255) NOT NULL,                 -- Original file name without extension
    `file_name` varchar(255) NOT NULL,
    `mime_type` varchar(255) DEFAULT NULL,        -- E.g., 'image/jpeg', 'application/pdf'
    `disk` varchar(255) NOT NULL,                 -- Storage disk (e.g., 'local', 's3')
    `conversions_disk` varchar(255) DEFAULT NULL, -- Disk for storing converted files
    `size` INT unsigned NOT NULL,              -- File size in bytes  
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



  -- --------------------------------------------------------------------------------------------------------
  -- DROPDOWN TABLES
  -- --------------------------------------------------------------------------------------------------------
  -- Ths Table will capture the Requirement of Dropdown Table
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sys_dropdown_needs` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
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
    `dropdown_tabel_record_exist` TINYINT(1) DEFAULT 0, 
    `is_active` TINYINT(1) DEFAULT 1,     -- If true, this Dropdown is active
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ddn_dbType_tblName_colName` (`db_type`,`table_name`,`column_name`),
    UNIQUE KEY `uq_ddn_cat_main_subMenu_tabName_fldName` (`menu_category`,`main_menu`,`sub_menu`,`tab_name`,`field_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
    -- 1. If tenant_creation_allowed = 1, then it is must to have menu_category, main_menu, sub_menu, tab_name, field_name. This needs to be managed at Application Level.
    -- 2. When PG-Admin/PG-Support will create a Dropdown, it will get 2 option to select -
    --    Option 1 - Dropdown creation by Table & Column details.
    --    Option 2 - Dropdown creation by Menu/Sub-Menu & Field Name.
    --       a. If he select Option 1 then he can select - Table Name, Column Name.
    --       b. If he select Option 2 then he can select - Menu Category, Main Menu, Sub Menu, Tab Name, Field Name.
    -- 3. If some Dropdown is allowed to be created by Tenant(tenant_creation_allowed = 1), then it will always show 5 Dropdowns to select from.
    --    a. Menu Category (this will come from sys_dropdown_needs.menu_category). This is a Must Dropdown.
    --    b. Main Menu (this will come from sys_dropdown_needs.main_menu). This is a Must Dropdown.
    --    c. Sub Menu (this will come from sys_dropdown_needs.sub_menu). This is a Optional Dropdown.
    --    d. Tab Name (this will come from sys_dropdown_needs.tab_name). This is a Optional Dropdown.
    --    e. Field Name (this will come from sys_dropdown_needs.field_name). This is a Must Dropdown.
    --    f. is_system = 1
  -- Conditions End

  -- Dropdown Table to store various dropdown values used across the system
  -- Enhanced sys_dropdown_table to accomodate Menu Detail (Category,Main Menu, Sub-Menu ID) for Easy identification.
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sys_dropdown_table` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint unsigned NOT NULL,
    `key` varchar(160) NOT NULL,      -- Key will be Combination of Table Name + Column Name (e.g. 'cmp_complaint_actions.action_type)
    `value` varchar(100) NOT NULL,
    `type` ENUM('String','Integer','Decimal', 'Date', 'Datetime', 'Time', 'Boolean') NOT NULL DEFAULT 'String',
    `additional_info` JSON DEFAULT NULL,  -- This will store additional information about the dropdown value
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ddt_key_ordinal` (`key`,`ordinal`),
    UNIQUE KEY `uq_ddt_key_value` (`key`,`value`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
    -- 1. When we go to create a New Dropdown, 
    --    1.1 PG_USER (PG-Admin/PG-Support) will get 2 option to select -
    --        Option 1 - Dropdown creation by DB details.
    --        Option 2 - Dropdown creation by Menu Detail.
    --          - If user select Option 1 then he can select - DB Type, Table Name, Column Name.
    --            a. DB Type (this will come from sys_dropdown_needs.db_type)
    --            b. Table Name (this will come from sys_dropdown_needs.table_name)
    --            c. Column Name (this will come from sys_dropdown_needs.column_name)
    --          - If user select Option 2 then he can select - Menu Category, Main Menu, Sub Menu, Tab Name, Field Name.
    --            a. Menu Category (this will come from sys_dropdown_needs.menu_category). This is a Must Dropdown.
    --            b. Main Menu (this will come from sys_dropdown_needs.main_menu). This is a Must Dropdown.
    --            c. Sub Menu (this will come from sys_dropdown_needs.sub_menu). This is a Optional Dropdown.
    --            d. Tab Name (this will come from sys_dropdown_needs.tab_name). This is a Optional Dropdown.
    --            e. Field Name (this will come from sys_dropdown_needs.field_name). This is a Must Dropdown.
    --            f. is_system = 1
    --    1.2 NON PG_USER (PG-Admin/PG-Support) will get only 1 option of Dropdowns to select -
    --        Option 1 - Dropdown creation by Menu/Sub-Menu & Field Name. (Need not to show the Option Button)
    --            a. Menu Category (this will come from sys_dropdown_needs.menu_category). This is a Must Dropdown.
    --            b. Main Menu (this will come from sys_dropdown_needs.main_menu). This is a Must Dropdown.
    --            c. Sub Menu (this will come from sys_dropdown_needs.sub_menu). This is a Optional Dropdown.
    --            d. Tab Name (this will come from sys_dropdown_needs.tab_name). This is a Optional Dropdown.
    --            e. Field Name (this will come from sys_dropdown_needs.field_name). This is a Must Dropdown.
    --            f. is_system = 1
    -- 2. System will check if the Dropdown Need is already configured in sys_dropdown_needs table.
    -- 3. If not, Developer need to create a new Dropdown Need first as per the requirement.
    -- 4. If yes, System will use the existing Dropdown Need.
  -- Conditions End

  -- This table will be Junction table for sys_dropdown_needs & sys_dropdown_table
  -- ----------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sys_dropdown_need_table_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `dropdown_needs_id` INT unsigned NOT NULL,  -- FK to sys_dropdown_needs.id
    `dropdown_table_id` INT unsigned NOT NULL,  -- FK to sys_dropdown_table.id
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ddNTJ_dropdownNeedsId_dropdownTableId` (`dropdown_needs_id`,`dropdown_table_id`),
    CONSTRAINT `fk_ddNTJ_dropdownNeedsId` FOREIGN KEY (`dropdown_needs_id`) REFERENCES `sys_dropdown_needs` (`id`),
    CONSTRAINT `fk_ddNTJ_dropdownTableId` FOREIGN KEY (`dropdown_table_id`) REFERENCES `sys_dropdown_table` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- =====================================================================================================================
-- Change Log From 15th Jun'2026 onward
-- =====================================================================================================================
-- Removed Tables - `sch_attendance_types`, `sch_leave_types`