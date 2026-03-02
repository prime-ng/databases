-- ===========================================================================
-- Tanent Database
-- ===========================================================================

-- ===========================================================================
-- VIEWS - Create Views after creating global_master database and it's tables
-- ===========================================================================

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


-- ===========================================================================
-- SYSTEM MODULE (sys)
-- ===========================================================================

  -- Tables for Role Based Access Control (RBAC) using spatie/laravel-permission package
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

  CREATE TABLE IF NOT EXISTS `sys_roles` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `name` varchar(50) NOT NULL,
    `short_name` VARCHAR(20) NOT NULL,
    `description` VARCHAR(255) NULL,
    `guard_name` varchar(255) NOT NULL,
    `is_system`  TINYINT(1) NOT NULL DEFAULT 0, -- if true, role belongs to PG
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_roles_name_name_guardName` (`name`,`guard_name`),
    UNIQUE KEY `uq_roles_name_shortName_guardName` (`short_name`,`guard_name`) 
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction Tables for Many-to-Many Relationships
  CREATE TABLE IF NOT EXISTS `sys_role_has_permissions_jnt` (
    `permission_id` INT unsigned NOT NULL,   -- FK to sys_permissions
    `role_id` INT unsigned NOT NULL,         -- FK to sys_roles
    PRIMARY KEY (`permission_id`,`role_id`),
    KEY `idx_roleHasPermissions_roleId` (`role_id`),
    CONSTRAINT `fk_roleHasPermissions_permissionId` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`),
    CONSTRAINT `fk_roleHasPermissions_roleId` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction Tables for Polymorphic Many-to-Many Relationships
  CREATE TABLE IF NOT EXISTS `sys_model_has_permissions_jnt` (
    `permission_id` INT unsigned NOT NULL,   -- FK to sys_permissions
    `model_type` varchar(190) NOT NULL,         -- E.g., 'App\Models\User'
    `model_id` INT unsigned NOT NULL,        -- E.g., User ID
    PRIMARY KEY (`permission_id`,`model_id`,`model_type`),
    KEY `idx_modelHasPermissions_modelId_modelType` (`model_id`,`model_type`),
    CONSTRAINT `fk_modelHasPermissions_permissionId` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`),
    CONSTRAINT `fk_modelHasPermissions_modelId_modelType` FOREIGN KEY (`model_id`) REFERENCES `sys_models` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction Tables for Polymorphic Many-to-Many Relationships
  CREATE TABLE IF NOT EXISTS `sys_model_has_roles_jnt` (
    `role_id` INT unsigned NOT NULL,       -- FK to sys_roles
    `model_type` varchar(190) NOT NULL,       -- E.g., 'App\Models\User'
    `model_id` INT unsigned NOT NULL,      -- E.g., User ID
    PRIMARY KEY (`role_id`,`model_id`,`model_type`),
    KEY `idx_modelHasRoles_modelId_modelType` (`model_id`,`model_type`),
    CONSTRAINT `fk_modelHasRoles_roleId` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`),
    CONSTRAINT `fk_modelHasRoles_modelId_modelType` FOREIGN KEY (`model_id`) REFERENCES `sys_models` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
  -- --------------------------------------------------------------------------------------------------------
  -- This table will store various system-wide settings and configurations
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

-- 
  -- --------------------------------------------------------------------------------------------------------
  -- Ths Table will capture the detail of which Field of Which Table fo Which Databse Type, I can create a Dropdown in sys_dropdown_table of?
  -- This will help us to make sure we can only create create a Dropdown in sys_dropdown_table whcih has been configured by Developer.
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

  -- --------------------------------------------------------------------------------------------------------
  -- Dropdown Table to store various dropdown values used across the system
  -- Enhanced sys_dropdown_table to accomodate Menu Detail (Category,Main Menu, Sub-Menu ID) for Easy identification.
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
  -- conditions:
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

  -- This table will be Junction table for sys_dropdown_needs & sys_dropdown_table
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

  -- --------------------------------------------------------------------------------------------------------
  -- Table to store media files associated with various models (e.g., users, posts)
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


-- ===========================================================================
-- 3 - TENANT SETUP MODULE (sch)
-- ===========================================================================

-- ===========================================================================
-- 3.1 - SCHOOL SETUP SUB-MODULE (sch)
-- ===========================================================================

  -- This table is a replica of 'prm_tenant' table in 'prmprime_db' database
  CREATE TABLE IF NOT EXISTS `sch_organizations` (
    `id` SMALLINT unsigned NOT NULL,              -- it will have same id as it is in 'prm_tenant'
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
  CREATE TABLE IF NOT EXISTS `sch_org_academic_sessions_jnt` (
    `id` SMALLINT unsigned NOT NULL AUTO_INCREMENT,
    `academic_sessions_id` INT unsigned NOT NULL,  -- Added New
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
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `academic_sessions_id` INT unsigned NOT NULL,
    `board_id` INT unsigned NOT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_boardOrg_boardId` FOREIGN KEY (`board_id`) REFERENCES `glb_boards` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_boardOrg_academicSessionId` FOREIGN KEY (`academic_sessions_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `sch_department` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL, -- e.g. "Transport", "Academic", "Rash Driving"
    `code` VARCHAR(30) DEFAULT NULL, -- Optional short code e.g. "TPT", "ACD"
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `sch_designation` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL, -- e.g. "Teacher", "Staff", "Student"
    `code` VARCHAR(30) DEFAULT NULL, -- Optional short code e.g. "TCH", "STF", "STD"
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- This table will facilitate to create Groups of different department, Roles, Designations etc.
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


-- ===========================================================================
-- 3.1 - CLASS SETUP SUB-MODULE (sch)
-- ===========================================================================


-- ===========================================================================
-- 3.2 - INFRA SETUP SUB-MODULE (sch)
-- ===========================================================================

  

-- ===========================================================================
-- 3.3 - EMPLOYEE SETUP SUB-MODULE (sch)
-- ===========================================================================



-- ===========================================================================
-- 4-TRANSPORT MODULE (tpt)
-- ===========================================================================

  CREATE TABLE IF NOT EXISTS `tpt_vehicle` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vehicle_no` VARCHAR(20) NOT NULL,              -- Vehicle number(Vehicle Identification Number (VIN)/Chassis Number: A unique 17-character code stamped on the vehicle's chassis)
      `registration_no` VARCHAR(30) NOT NULL,         -- Unique govt registration number
      `model` VARCHAR(50),                            -- Vehicle model
      `manufacturer` VARCHAR(50),                     -- Vehicle manufacturer 
      `vehicle_type_id` INT UNSIGNED NOT NULL,     -- fk to sys_dropdown_table ('BUS','VAN','CAR')
      `fuel_type_id` INT UNSIGNED NOT NULL,        -- fk to sys_dropdown_table ('Diesel','Petrol','CNG','Electric')
      `capacity` INT UNSIGNED NOT NULL DEFAULT 40,    -- Seating capacity
      `max_capacity` INT UNSIGNED NOT NULL DEFAULT 40, -- Maximum allowed capacity including standing
      `ownership_type_id` INT UNSIGNED NOT NULL,   -- fk to sys_dropdown_table ('Owned','Leased','Rented')
      `vendor_id` INT UNSIGNED NOT NULL,           -- fk to tpt_vendor
      `fitness_valid_upto` DATE NOT NULL,             -- Fitness certificate expiry date
      `insurance_valid_upto` DATE NOT NULL,           -- Insurance expiry date
      `pollution_valid_upto` DATE NOT NULL,           -- Pollution certificate expiry date
      `vehicle_emission_class_id` INT UNSIGNED NOT NULL,  -- fk to sys_dropdown_table ('BS IV', 'BS V', 'BS VI')
      `fire_extinguisher_valid_upto` DATE NOT NULL,    -- Fire extinguisher expiry date
      `gps_device_id` VARCHAR(50),                    -- Installed GPS device identifier
      `vehicle_photo_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (vehicle photo will be uploaded in sys.media)
      `registration_cert_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (registration certificate will be uploaded in sys.media)
      `fitness_cert_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (fitness certificate will be uploaded in sys.media)
      `insurance_cert_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (insurance certificate will be uploaded in sys.media)
      `pollution_cert_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (pollution certificate will be uploaded in sys.media)
      `vehicle_emission_cert_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (vehicle emission certificate will be uploaded in sys.media)
      `fire_extinguisher_cert_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (fire extinguisher certificate will be uploaded in sys.media)
      `gps_device_cert_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (gps device certificate will be uploaded in sys.media)
      `availability_status` tinyint(1) unsigned not null default 1,  -- 0: Not Available, 1: Available
      `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      UNIQUE KEY `uq_vehicle_vehicleNo` (`vehicle_no`),
      UNIQUE KEY `uq_vehicle_registration_no` (`registration_no`),
      CONSTRAINT `fk_vehicle_vehicle_type` FOREIGN KEY (`vehicle_type_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_vehicle_fuel_type` FOREIGN KEY (`fuel_type_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_vehicle_ownership_type` FOREIGN KEY (`ownership_type_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_vehicle_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `tpt_vendor`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_vehicle_vehicle_emission_class` FOREIGN KEY (`vehicle_emission_class_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_personnel` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `user_id` INT UNSIGNED DEFAULT NULL,
      `user_qr_code` VARCHAR(30) NOT NULL,
      `id_card_type` ENUM('QR','RFID','NFC','Barcode') NOT NULL DEFAULT 'QR',
      `name` VARCHAR(100) NOT NULL,
      `phone` VARCHAR(30) DEFAULT NULL,
      `id_type` VARCHAR(20) DEFAULT NULL,     -- ID Type (e.g., Aadhaar, PAN, Passport)
      `id_no` VARCHAR(100) DEFAULT NULL,      -- ID Number   
      `role` VARCHAR(20) NOT NULL,            -- Role (e.g., Driver, Helper, Transport Manager etc.)
      `license_no` VARCHAR(50) DEFAULT NULL,  -- License Number
      `license_valid_upto` DATE DEFAULT NULL,  -- License Valid Upto
      `assigned_vehicle_id` INT UNSIGNED DEFAULT NULL,  -- fk to tpt_vehicle
      `driving_exp_months` SMALLINT UNSIGNED DEFAULT NULL,  -- Driving Experience in Months
      `police_verification_done` TINYINT(1) NOT NULL DEFAULT 0,  -- 0: Not Done, 1: Done
      `address` VARCHAR(512) DEFAULT NULL,
      `id_card_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (id card will be uploaded in sys.media)
      `photo_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (photo will be uploaded in sys.media)
      `driving_license_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (driving license will be uploaded in sys.media)
      `police_verification_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (police verification will be uploaded in sys.media)
      `address_proof_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (address proof will be uploaded in sys.media)
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_personnel_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_personnel_vehicle` FOREIGN KEY (`assigned_vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_shift` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
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

  CREATE TABLE IF NOT EXISTS `tpt_route` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `code` VARCHAR(50) NOT NULL,
      `name` VARCHAR(200) NOT NULL,
      `description` VARCHAR(500) DEFAULT NULL,
      `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
      `shift_id` INT UNSIGNED NOT NULL,
      `route_geometry` LINESTRING SRID 4326 DEFAULT NULL,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      UNIQUE KEY `uq_route_code` (`code`),
      UNIQUE KEY `uq_route_name` (`name`),
      SPATIAL INDEX `sp_idx_route_geometry` (`route_geometry`),
      CONSTRAINT `fk_route_shiftId` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_pickup_points` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `shift_id` INT UNSIGNED NOT NULL,
      `code` VARCHAR(50) NOT NULL,
      `name` VARCHAR(200) NOT NULL,
      `latitude` DECIMAL(10,7) DEFAULT NULL,
      `longitude` DECIMAL(10,7) DEFAULT NULL,
      `location` POINT NOT NULL SRID 4326,    -- e.g.
      `total_distance` DECIMAL(7,2) DEFAULT NULL,
      `estimated_time` INT DEFAULT NULL,
      `stop_type` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      UNIQUE KEY `uq_pickup_code` (`code`),
      UNIQUE KEY `uq_pickup_name` (`name`),
      SPATIAL INDEX `sp_idx_pickup_location` (`location`),
      CONSTRAINT `fk_pickupPoint_shiftId` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_pickup_points_route_jnt` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `shift_id` INT UNSIGNED NOT NULL,
      `route_id` INT UNSIGNED NOT NULL,
      `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
      `pickup_point_id` INT UNSIGNED NOT NULL,
      `ordinal` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
      `total_distance` DECIMAL(7,2) DEFAULT NULL,
      `arrival_time` INT DEFAULT NULL,
      `departure_time` INT DEFAULT NULL,   
      `estimated_time` INT DEFAULT NULL,
      `pickup_drop_fare` DECIMAL(10,2) DEFAULT NULL,  -- One Side (Pickup / Drop) Fare
      `both_side_fare` DECIMAL(10,2) DEFAULT NULL,    -- Bothside Fare if Student choose same Stop for Pickup & Drop both
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      UNIQUE KEY `uq_pickupPointRoute_route_pickupPoint` (`route_id`,`pickup_point_id`),
      KEY `idx_pprj_route_ordinal` (`route_id`, `ordinal`),
      CONSTRAINT `fk_pickupPointRoute_shiftId` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_pickupPointRoute_routeId` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_pickupPointRoute_pickupPointId` FOREIGN KEY (`pickup_point_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_driver_route_vehicle_jnt` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `shift_id` INT UNSIGNED NOT NULL,
      `route_id` INT UNSIGNED NOT NULL,
      `vehicle_id` INT UNSIGNED NOT NULL,
      `driver_id` INT UNSIGNED NOT NULL,
      `helper_id` INT UNSIGNED DEFAULT NULL,
      `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
      `effective_from` DATE NOT NULL,
      `effective_to` DATE DEFAULT NULL,
      `total_students` INT NOT NULL DEFAULT 0,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_routeVehicle_shiftId` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_routeVehicle_routeId` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_routeVehicle_vehicleId` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_routeVehicle_driverId` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_routeVehicle_helperId` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    DELIMITER $$
    CREATE TRIGGER `trg_driver_route_vehicle_unique_assignment`
    BEFORE INSERT ON `tpt_driver_route_vehicle_jnt`
    FOR EACH ROW
    BEGIN
        IF EXISTS (
            SELECT 1 FROM `tpt_driver_route_vehicle_jnt`
            WHERE `shift_id` = NEW.`shift_id`
              AND `route_id` = NEW.`route_id`
              AND `vehicle_id` = NEW.`vehicle_id`
              AND `driver_id` = NEW.`driver_id`
              AND (
                  (NEW.`effective_to` IS NULL AND (`effective_to` IS NULL OR `effective_to` >= NEW.`effective_from`))
                  OR
                  (NEW.`effective_to` IS NOT NULL AND (
                      (`effective_from` <= NEW.`effective_to` AND `effective_to` >= NEW.`effective_from`)
                  ))
              )
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Overlapping assignment for the same shift, route, vehicle, and driver.';
        END IF;
    END$$
    DELIMITER ;

  CREATE TABLE IF NOT EXISTS `tpt_route_scheduler_jnt` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `scheduled_date` DATE NOT NULL,
      `shift_id` INT UNSIGNED NOT NULL,
      `route_id` INT UNSIGNED NOT NULL,
      `vehicle_id` INT UNSIGNED NOT NULL,
      `driver_id` INT UNSIGNED NOT NULL,
      `helper_id` INT UNSIGNED DEFAULT NULL,
      `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      UNIQUE KEY `uq_route_scheduler_schedDate_shift_route` (`scheduled_date`,`shift_id`,`route_id`,`pickup_drop`),
      UNIQUE KEY `uq_route_scheduler_vehicle_schedDate_shift` (`vehicle_id`,`scheduled_date`,`shift_id`,`pickup_drop`),
      UNIQUE KEY `uq_route_scheduler_driver_schedDate_shift` (`driver_id`,`scheduled_date`,`shift_id`,`pickup_drop`),
      UNIQUE KEY `uq_route_scheduler_helper_schedDate_shift` (`helper_id`,`scheduled_date`,`shift_id`,`pickup_drop`),
      CONSTRAINT `fk_sched_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_sched_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_sched_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_sched_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_sched_helper` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_trip` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `trip_date` DATE NOT NULL,      --  Date of the trip
      `route_scheduler_id` INT UNSIGNED NOT NULL, -- FK to tpt_route_scheduler_jnt
      `route_id` INT UNSIGNED NOT NULL, -- FK to tpt_route
      `vehicle_id` INT UNSIGNED NOT NULL, -- FK to tpt_vehicle
      `driver_id` INT UNSIGNED NOT NULL, -- FK to tpt_personnel
      `helper_id` INT UNSIGNED DEFAULT NULL, -- FK to tpt_personnel
      `start_time` DATETIME DEFAULT NULL, -- Start time of the trip
      `end_time` DATETIME DEFAULT NULL, -- End time of the trip
      `start_odometer_reading` DECIMAL(11, 2) DEFAULT 0.00,
      `end_odometer_reading` DECIMAL(11, 2) DEFAULT 0.00,
      `start_fuel_reading` DECIMAL(8, 3) DEFAULT 0.00,
      `end_fuel_reading` DECIMAL(8, 3) DEFAULT 0.00,
      `status` VARCHAR(20) NOT NULL DEFAULT 'Scheduled',
      `approved` TINYINT(1) NOT NULL DEFAULT 0,
      `approved_by` INT UNSIGNED DEFAULT NULL,
      `approved_at` TIMESTAMP NULL DEFAULT NULL,
      `remarks` VARCHAR(512) DEFAULT NULL, 
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      KEY `idx_trip_routeSched_tripDate` (`route_scheduler_id`, `trip_date`),
      KEY `idx_trip_vehicle` (`vehicle_id`),
      CONSTRAINT `fk_trip_route_scheduler` FOREIGN KEY (`route_scheduler_id`) REFERENCES `tpt_route_scheduler_jnt`(`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_trip_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_trip_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_trip_helper` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_trip_stop_detail` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `trip_id` INT UNSIGNED NOT NULL,     -- fk to tpt_trip
      `stop_id` INT UNSIGNED DEFAULT NULL, -- fk to tpt_stop
      `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
      `sch_arrival_time` DATETIME DEFAULT NULL, -- scheduled arrival time
      `sch_departure_time` DATETIME DEFAULT NULL, -- scheduled departure time
      `reached_flag` TINYINT(1) NOT NULL DEFAULT 0,   -- 1 if reached, 0 if not reached
      `reaching_time` TIMESTAMP DEFAULT NULL,     -- actual time of arrival
      `leaving_time` TIMESTAMP DEFAULT NULL,     -- actual time of departure
      `emergency_flag` TINYINT(1) DEFAULT 0,     -- 1 if emergency, 0 if not emergency
      `emergency_time` TIMESTAMP DEFAULT NULL,   -- actual time of emergency
      `emergency_remarks` VARCHAR(512) DEFAULT NULL, -- remarks for emergency
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `updated_by` INT UNSIGNED DEFAULT NULL,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_trip_stop_detail_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_trip_stop_detail_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_trip_stop_detail_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_attendance_device` (
      `id` INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
      `user_id` INT UNSIGNED NOT NULL,     -- fk to tpt_personnel
      `device_uuid` CHAR(36) NOT NULL,        -- Unique identifier of the device
      `device_type` ENUM('Mobile','Tablet','Laptop','Desktop') NOT NULL,
      `location` VARCHAR(150) NULL,
      `device_os` INT NOT NULL,            -- fk to sys_dropdown_table ('android','ios','windows','linux','mac')
      `os_version` VARCHAR(50),               -- OS version
      `device_name` VARCHAR(100) NOT NULL,
      `device_model` VARCHAR(100),            -- Device model e.g. iPhone 12 Pro
      `pg_app_version` VARCHAR(20),           -- App version e.g. 1.0.0
      `pg_fcm_token` TEXT,                    -- FCM token of the device e.g. eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
      `pg_first_registered_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `pg_last_seen_at` TIMESTAMP NULL,
      `is_active` TINYINT(1) DEFAULT 1,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      deleted_at TIMESTAMP NULL DEFAULT NULL,
      KEY `idx_attendance_device_user` (`user_id`),
      UNIQUE KEY uq_device (device_uuid),
      UNIQUE KEY uq_user_device (user_id, device_uuid),
      CONSTRAINT `fk_attendance_device_user` FOREIGN KEY (`user_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_driver_attendance` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `driver_id` INT UNSIGNED NOT NULL,
      `attendance_date` DATE NOT NULL,
      `first_in_time` DATETIME NULL,
      `last_out_time` DATETIME NULL,
      `total_work_minutes` INT NULL,
      `attendance_status` INT NOT NULL, -- fk to sys_dropdown_table ('Present','Absent','Half-Day','Late')
      `via_app` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE KEY `uq_driver_day` (`driver_id`, `attendance_date`),
      FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`),
      FOREIGN KEY (`attendance_status`) REFERENCES `sys_dropdown_table`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_driver_attendance_log` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `attendance_id` INT UNSIGNED NOT NULL,
      `scan_time` DATETIME NOT NULL,
      `attendance_type` ENUM('IN','OUT') NOT NULL,
      `scan_method` ENUM('QR','RFID','NFC','Manual') NOT NULL,
      `device_id` INT UNSIGNED NOT NULL,
      `latitude` DECIMAL(10,6) NULL,
      `longitude` DECIMAL(10,6) NULL,
      `scan_status` ENUM('Valid','Duplicate','Rejected') NOT NULL DEFAULT 'Valid',
      `remarks` VARCHAR(255) NULL,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT `fk_da_attendance` FOREIGN KEY (`attendance_id`) REFERENCES `tpt_driver_attendance`(`id`) ON DELETE CASCADE,
      CONSTRAINT `FK_da_device` FOREIGN KEY (`device_id`) REFERENCES `tpt_attendance_device`(`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_student_route_allocation_jnt` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_session_id` INT UNSIGNED NOT NULL,
      `student_id` INT UNSIGNED NOT NULL,
      `pickup_route_id` INT UNSIGNED NOT NULL,
      `pickup_stop_id` INT UNSIGNED NOT NULL,
      `drop_route_id` INT UNSIGNED NOT NULL,
      `drop_stop_id` INT UNSIGNED NOT NULL,
      `fare` DECIMAL(10,2) NOT NULL,
      `effective_from` DATE NOT NULL,
      `active_status` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_sa_studentSession` FOREIGN KEY (`student_session_id`) REFERENCES `std_student_sessions_jnt`(`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_sa_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_sa_pickup` FOREIGN KEY (`pickup_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_sa_drop` FOREIGN KEY (`drop_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_fine_master` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `std_academic_sessions_id` INT UNSIGNED NOT NULL,
      `fine_from_days` TINYINT DEFAULT 0,
      `fine_to_days` TINYINT DEFAULT 0,
      `fine_type` ENUM('Fixed','Percentage') DEFAULT 'Fixed',
      `fine_rate` DECIMAL(5,2) DEFAULT 0.00,
      `student_restricted` TINYINT(1) DEFAULT 0,
      `Remark` VARCHAR(512) DEFAULT NULL,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_student_fee_detail` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `std_academic_sessions_id` INT UNSIGNED NOT NULL,
      `month` DATE NOT NULL,
      `amount` DECIMAL(10,2) NOT NULL,
      `fine_amount` DECIMAL(10,2) DEFAULT 0.00,
      `total_amount` DECIMAL(10,2) NOT NULL,
      `due_date` DATE NOT NULL,
      `Remark` VARCHAR(512) DEFAULT NULL,
      `status` VARCHAR(20) NOT NULL DEFAULT 'Pending',
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_student_fine_detail` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_fee_detail_id` INT UNSIGNED NOT NULL,
      `fine_master_id` INT UNSIGNED NOT NULL,
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

  CREATE TABLE IF NOT EXISTS `tpt_student_fee_collection` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_fee_detail_id` INT UNSIGNED NOT NULL,
      `payment_date` DATE NOT NULL,
      `total_delay_days` INT DEFAULT 0,
      `paid_amount` DECIMAL(10,2) NOT NULL,
      `payment_mode`  VARCHAR(20) NOT NULL,
      `status` VARCHAR(20) NOT NULL,
      `reconciled` TINYINT(1) NOT NULL DEFAULT 0,
      `remarks` VARCHAR(512) DEFAULT NULL,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_fc_fee_detail` FOREIGN KEY (`student_fee_detail_id`) REFERENCES `tpt_student_fee_detail`(`id`) ON DELETE RESTRICT
      -- Removed fk_fc_master as tpt_fee_master is not directly linked here in v1.9 schema provided in context,
      -- or if it was intended, the column fee_master_id was missing in the column list in v1.9.
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `std_student_pay_log` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `academic_session_id` INT UNSIGNED NOT NULL,
    `module_name` VARCHAR(50) NOT NULL,
    `activity_type` VARCHAR(50) NOT NULL,
    `amount` DECIMAL(10,2) DEFAULT NULL,
    `log_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `reference_id` INT UNSIGNED DEFAULT NULL,
    `reference_table` VARCHAR(100) DEFAULT NULL,
    `description` VARCHAR(512) DEFAULT NULL,
    `triggered_by` INT UNSIGNED DEFAULT NULL,
    `is_system_generated` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    KEY `idx_payLog_student` (`student_id`),
    KEY `idx_payLog_module` (`module_name`),
    KEY `idx_payLog_date` (`log_date`),
    KEY `idx_payLog_reference` (`reference_table`, `reference_id`),
    KEY `idx_payLog_trigger` (`triggered_by`),
    CONSTRAINT `fk_payLog_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_payLog_sessionId` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_payLog_triggeredBy` FOREIGN KEY (`triggered_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_vehicle_fuel` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vehicle_id` INT UNSIGNED NOT NULL,
      `driver_id` INT UNSIGNED DEFAULT NULL,
      `date` DATE NOT NULL,
      `quantity` DECIMAL(10,3) NOT NULL,
      `cost` DECIMAL(12,2) NOT NULL,
      `fuel_type` INT UNSIGNED NOT NULL,
      `odometer_reading` INT UNSIGNED DEFAULT NULL,
      `remarks` VARCHAR(512) DEFAULT NULL,
      `status` ENUM('Approved','Pending','Rejected') NOT NULL DEFAULT 'Pending',
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_vfl_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_vfl_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
      -- 1. After Fuel Entry, it need to be approved by the adminAuthorised Personnel.
      -- 2. To make sure the availaibility of Approval to the Authorise Person only, we need to keep Approval on Fuel & Maintenance on a seperate Tab.

  Create Table if not EXISTS `tpt_daily_vehicle_inspection` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vehicle_id` INT UNSIGNED NOT NULL,
      `driver_id` INT UNSIGNED DEFAULT NULL,
      `inspection_date` TIMESTAMP NOT NULL,
      `odometer_reading` INT UNSIGNED DEFAULT NULL,
      `fuel_level_reading` DECIMAL(6,2) DEFAULT NULL,
      `tire_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
      `lights_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
      `brakes_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
      `engine_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
      `battery_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
      `fire_extinguisher_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
      `first_aid_kit_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
      `seat_belts_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
      `headlights_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
      `tailights_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
      `wipers_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
      `mirrors_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
      `steering_wheel_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
      `emergency_tools_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
      `cleanliness_ok` TINYINT(1) NOT NULL DEFAULT 0,
      `any_issues_found` TINYINT(1) NOT NULL DEFAULT 0,
      `issues_description` VARCHAR(512) DEFAULT NULL,
      `remarks` VARCHAR(512) DEFAULT NULL,
      `inspection_status` ENUM('Passed','Failed','Pending') NOT NULL DEFAULT 'Pending',
      `inspected_by` INT UNSIGNED DEFAULT NULL, 
      `inspected_at` TIMESTAMP NULL DEFAULT NULL,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_dvil_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_dvil_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_dvil_inspectedBy` FOREIGN KEY (`inspected_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
      -- 1. If Inspection is Failed, a new entry will be created in 'tpt_vehicle_service_request' table with available information.
      -- 2. If Inspection is Failed, application will change Status in the "tpt_Vehicle make '`availability_status` to 'Not Available'

  Create Table if not EXISTS `tpt_vehicle_service_request` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vehicle_inspection_id` INT UNSIGNED NOT NULL,
      `request_date` TIMESTAMP NOT NULL,
      `reason` VARCHAR(512) DEFAULT NULL,  -- Reason can be filled by anyone
      `Vehicle_status` INT UNSIGNED DEFAULT NULL,  -- fk to sys_dropdown_table ('Due for Service', 'In-Service', 'Service Done')
      `service_completion_date` TIMESTAMP NULL DEFAULT NULL,
      `request_approval_status` ENUM('Approved','Pending','Rejected') NOT NULL DEFAULT 'Pending',
      `approved_by` INT UNSIGNED DEFAULT NULL,
      `approved_at` TIMESTAMP NULL DEFAULT NULL,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_vsl_vehicleInspection` FOREIGN KEY (`vehicle_inspection_id`) REFERENCES `tpt_daily_vehicle_inspection`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_vsl_approvedBy` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
      -- 1. If Inspection is Failed, a new entry will be created in 'tpt_vehicle_service_request' table with available information.
      -- 2. To make sure the availaibility of Approval to the Authorise Person only, we need to keep Approval in a seperate Tab.
      -- 3. user can create a new entry in 'tpt_vehicle_service_request' table as per the need.
      -- 4. Once Request i Approved by Authorised Person, a new entry will be created in 'tpt_vehicle_maintenance' table with available information.
      -- 5. Direct Entry in 'tpt_vehicle_maintenance' table is not allowed. 
      -- 6. Once Entry is created in 'tpt_vehicle_service_request' table, it will be redirected to 'tpt_vehicle_maintenance' table.

  CREATE TABLE IF NOT EXISTS `tpt_vehicle_maintenance` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vehicle_service_request_id` INT UNSIGNED NOT NULL,
      `maintenance_initiation_date` DATE NOT NULL,  -- Date of Service Initiated (Vehicle reached in garage)
      `maintenance_type` VARCHAR(120) NOT NULL,    -- Mannual Entry
      `cost` DECIMAL(12,2) NOT NULL,
      `in_service_date` DATE DEFAULT NULL,   -- Date of Service Initiated (Vehicle reached in garage)
      `out_service_date` DATE DEFAULT NULL,  -- Date of Service Completion 
      `workshop_details` VARCHAR(512) DEFAULT NULL,
      `next_due_date` DATE DEFAULT NULL,     -- Next Due Date (if Any)
      `remarks` VARCHAR(512) DEFAULT NULL,
      `status` ENUM('Approved','Pending','Rejected') NOT NULL DEFAULT 'Pending',
      `approved_by` INT UNSIGNED DEFAULT NULL,
      `approved_at` TIMESTAMP NULL DEFAULT NULL,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_vm_vehicle_service_request` FOREIGN KEY (`vehicle_service_request_id`) REFERENCES `tpt_vehicle_service_request`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_vm_approvedBy` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_trip_incidents` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `trip_id` INT UNSIGNED NOT NULL,
      `incident_time` TIMESTAMP NOT NULL,
      `incident_type` INT UNSIGNED NOT NULL,
      `severity` ENUM('LOW','MEDIUM','HIGH') DEFAULT 'MEDIUM',
      `latitude` DECIMAL(10,7) DEFAULT NULL,
      `longitude` DECIMAL(10,7) DEFAULT NULL,
      `description` VARCHAR(512) DEFAULT NULL,
      `status` INT UNSIGNED DEFAULT NULL,
      `raised_by` INT UNSIGNED DEFAULT NULL,  -- fk to sys_users
      `raised_at` TIMESTAMP NULL DEFAULT NULL,    -- When Incident is Raised
      `resolved_at` TIMESTAMP NULL DEFAULT NULL,  -- When Incident is Resolved
      `resolved_by` INT UNSIGNED DEFAULT NULL,  -- fk to sys_users
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_ti_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_ti_raisedBy` FOREIGN KEY (`raised_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_ti_resolvedBy` FOREIGN KEY (`resolved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_student_boarding_log` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `trip_date` DATE NOT NULL,
      `student_id` INT UNSIGNED DEFAULT NULL,      -- FK to tpt_students
      `student_session_id` INT UNSIGNED DEFAULT NULL,  -- FK to tpt_student_session
      `boarding_route_id` INT UNSIGNED DEFAULT NULL,  -- FK to tpt_routes
      `boarding_trip_id` INT UNSIGNED DEFAULT NULL,   -- FK to tpt_trip
      `boarding_stop_id` INT UNSIGNED DEFAULT NULL,   -- FK to tpt_pickup_points
      `boarding_time` DATETIME DEFAULT NULL,
      `unboarding_route_id` INT UNSIGNED DEFAULT NULL,  -- FK to tpt_routes
      `unboarding_trip_id` INT UNSIGNED DEFAULT NULL,   -- FK to tpt_trip
      `unboarding_stop_id` INT UNSIGNED DEFAULT NULL,   -- FK to tpt_pickup_points
      `unboarding_time` DATETIME DEFAULT NULL,
      `device_id` INT UNSIGNED DEFAULT NULL,  -- FK to tpt_attendance_device
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_sel_student` FOREIGN KEY (`student_id`) REFERENCES `tpt_students`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_sel_studentSession` FOREIGN KEY (`student_session_id`) REFERENCES `tpt_student_session`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_sel_boardingRoute` FOREIGN KEY (`boarding_route_id`) REFERENCES `tpt_routes`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_sel_boardingTrip` FOREIGN KEY (`boarding_trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_sel_boardingStop` FOREIGN KEY (`boarding_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_sel_unboardingRoute` FOREIGN KEY (`unboarding_route_id`) REFERENCES `tpt_routes`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_sel_unboardingTrip` FOREIGN KEY (`unboarding_trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_sel_unboardingStop` FOREIGN KEY (`unboarding_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_sel_device` FOREIGN KEY (`device_id`) REFERENCES `tpt_attendance_device`(`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_notification_log` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_session_id` INT UNSIGNED DEFAULT NULL,
      `trip_id` INT UNSIGNED DEFAULT NULL,
      `boarding_stop_id` INT UNSIGNED DEFAULT NULL,
      `notification_type` ENUM('TripStart','ApproachingStop','ReachedStop','Delayed','Cancelled') DEFAULT NULL,
      `sent_time` DATETIME DEFAULT NULL,
      `app_notification_status` ENUM('NotRegistered','Sent','Failed') DEFAULT NULL,
      `sms_notification_status` ENUM('NotRegistered','Sent','Failed') DEFAULT NULL,
      `email_notification_status` ENUM('NotRegistered','Sent','Failed') DEFAULT NULL,
      `whatsapp_notification_status` ENUM('NotRegistered','Sent','Failed') DEFAULT NULL,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_nl_studentSession` FOREIGN KEY (`student_session_id`) REFERENCES `tpt_student_session`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_nl_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_nl_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===========================================================================
-- 5-VENDOR MODULE (vnd)
-- ===========================================================================

  -- 1-Screen Name - Vendor Master
  CREATE TABLE IF NOT EXISTS `vnd_vendors` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vendor_name` VARCHAR(100) NOT NULL,
      `vendor_type_id` INT UNSIGNED NOT NULL,  -- FK to sys_dropdown_table (e.g., 'Transport', 'Canteen', 'Security')
      `contact_person` VARCHAR(100) NOT NULL,
      `contact_number` VARCHAR(30) NOT NULL,
      `email` VARCHAR(100) DEFAULT NULL,
      `address` VARCHAR(512) DEFAULT NULL,
      `gst_number` VARCHAR(50) DEFAULT NULL,      -- Tax ID 1
      `pan_number` VARCHAR(50) DEFAULT NULL,      -- Tax ID 2 (or generic Tax Reg No)
      `bank_name` VARCHAR(100) DEFAULT NULL,
      `bank_account_no` VARCHAR(50) DEFAULT NULL,
      `bank_ifsc_code` VARCHAR(20) DEFAULT NULL,
      `bank_branch` VARCHAR(100) DEFAULT NULL,
      `upi_id` VARCHAR(100) DEFAULT NULL,
      `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
      `is_deleted` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0, -- Soft delete flag
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_vnd_vendors_type` FOREIGN KEY (`vendor_type_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
      UNIQUE KEY `uq_vnd_vendor_name` (`vendor_name`),
      INDEX `idx_vnd_vendor_type` (`vendor_type_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 2-Screen Name - Item Master
  CREATE TABLE IF NOT EXISTS `vnd_items` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `item_code` VARCHAR(50) DEFAULT NULL,       -- SKU or Internal Item Code (Can be used for barcode printing)
      `item_name` VARCHAR(100) NOT NULL,
      `item_type` ENUM('SERVICE', 'PRODUCT') NOT NULL,
      `item_nature` ENUM('CONSUMABLE', 'ASSET', 'SERVICE', 'NA') NOT NULL DEFAULT 'NA', -- Inventory Hook
      `category_id` INT UNSIGNED NOT NULL,     -- FK to sys_dropdown_table (e.g., 'Stationery', 'Bus Rental', 'Plumbing')
      `unit_id` INT UNSIGNED NOT NULL,         -- FK to sys_dropdown_table (e.g., 'Km', 'Day', 'Month', 'Piece', 'Visit')
      `hsn_sac_code` VARCHAR(20) DEFAULT NULL,    -- For GST/Tax compliance
      `default_price` DECIMAL(12, 2) DEFAULT 0.00,-- Standard buying price
      `reorder_level` DECIMAL(12, 2) DEFAULT 0.00,-- Low stock alert threshold (Inventory Hook)
      `item_photo_uploaded` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
      `description` TEXT DEFAULT NULL,
      `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
      `is_deleted` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_vnd_items_category` FOREIGN KEY (`category_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_vnd_items_unit` FOREIGN KEY (`unit_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
      UNIQUE KEY `uq_vnd_items_code` (`item_code`),
      INDEX `idx_vnd_items_type` (`item_type`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 3-Screen Name - Agreement Master
  CREATE TABLE IF NOT EXISTS `vnd_agreements` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vendor_id` INT UNSIGNED NOT NULL,
      `agreement_ref_no` VARCHAR(50) DEFAULT NULL,  -- Physical contract reference
      `start_date` DATE NOT NULL,
      `end_date` DATE NOT NULL,
      `status` ENUM('DRAFT', 'ACTIVE', 'EXPIRED', 'TERMINATED') NOT NULL DEFAULT 'DRAFT',
      `billing_cycle` ENUM('MONTHLY', 'ONE_TIME', 'ON_DEMAND') NOT NULL DEFAULT 'MONTHLY',
      `payment_terms_days` INT UNSIGNED DEFAULT 30, -- Credit period in days
      `remarks` TEXT DEFAULT NULL,
      `agreement_uploaded` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
      `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
      `is_deleted` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_vnd_agreements_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`id`) ON DELETE CASCADE,
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 3-Screen Name - Agreement Master (Agreement Items). This will be part of above Screen
  CREATE TABLE IF NOT EXISTS `vnd_agreement_items_jnt` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `agreement_id` INT UNSIGNED NOT NULL,
      `item_id` INT UNSIGNED NOT NULL,
      -- Billing Logic
      `billing_model` ENUM('FIXED', 'PER_UNIT', 'HYBRID') NOT NULL DEFAULT 'FIXED', 
      -- FIXED: Flat rate per month/cycle.
      -- PER_UNIT: rate * qty.
      -- HYBRID: Fixed Base + (Rate * Qty) OR Fixed Base + (Rate * (Qty - Min_Qty)).
      `fixed_charge` DECIMAL(12, 2) DEFAULT 0.00,       -- Base charge (e.g. Monthly Rent)
      `unit_rate` DECIMAL(10, 2) DEFAULT 0.00,          -- Variable rate (e.g. Per Km)
      `min_guarantee_qty` DECIMAL(10, 2) DEFAULT 0.00,  -- If usage < min, pay min (logic handled in code)
      `tax1_percent` DECIMAL(5, 2) DEFAULT 0.00,
      `tax2_percent` DECIMAL(5, 2) DEFAULT 0.00,
      `tax3_percent` DECIMAL(5, 2) DEFAULT 0.00,
      `tax4_percent` DECIMAL(5, 2) DEFAULT 0.00,
      -- Context (For hooking to specific assets)
      `related_entity_type` INT UNSIGNED DEFAULT NULL,  -- FK to sys_dropdown_table ('Vehicle', 'Asset', 'Service', etc.)
      `related_entity_table` VARCHAR(60) DEFAULT NULL, -- e.g., tpt_vehicle, sch_asset, sch_service, etc.
      `related_entity_id` INT UNSIGNED DEFAULT NULL, -- e.g., vehicle_id, asset_id, service_id, etc.
      `description` VARCHAR(255) DEFAULT NULL,
      `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
      `is_deleted` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_vnd_agr_items_agreement` FOREIGN KEY (`agreement_id`) REFERENCES `vnd_agreements`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_vnd_agr_items_item` FOREIGN KEY (`item_id`) REFERENCES `vnd_items`(`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_vnd_agr_items_entity_type` FOREIGN KEY (`related_entity_type`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- conditions: 
    -- related_entity_type = (Vehicle, Asset, Service, etc.) will have table name as `additional_info` in `sys_dropdown_table` table.
    -- e.g. related_entity_type = 'Vehicle' will have table_name as `tpt_vehicle` in 'additional_info' field of `sys_dropdown_table` table.
    -- related_entity_id will be the id of the entity in the related_entity_type table.
    --Example
      Drop Down - Vehicle 
      sys_dropdown_table
      Key                                             Value                   Additional_Info(JSON)
      vnd_agreement_items_jnt.related_entity_type     Vehicle                 {"table_name": "tpt_vehicle"}
      vnd_agreement_items_jnt.related_entity_type     Asset                   {"table_name": "sch_asset"}
      vnd_agreement_items_jnt.related_entity_type     Service                 {"table_name": "sch_service"}

  -- This table is used to log the usage of services/products by vendors.
  -- 4-Screen Name - Usage Log
  CREATE TABLE IF NOT EXISTS `vnd_usage_logs` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vendor_id` INT UNSIGNED NOT NULL,
      `agreement_item_id` INT UNSIGNED NOT NULL, -- Optional, can map to specific agreement line
      `usage_date` DATE NOT NULL,
      `qty_used` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,  -- Quantity used e.g. Vehicle distance(Km), hours, etc.
      `remarks` VARCHAR(255) DEFAULT NULL,
      `logged_by` INT UNSIGNED DEFAULT NULL, -- FK to sys_users (will be NULL for auto log)
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      CONSTRAINT `fk_vnd_usage_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_vnd_usage_agr_item` FOREIGN KEY (`agreement_item_id`) REFERENCES `vnd_agreement_items`(`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- 1. If 'billing_mode' in `vnd_agreement_items` is 'PER_UNIT'OR 'HYBRID', AND'qty_used'  > 0 then only record will be created. in 'vnd_usage_logs' table.
  -- 2. If 'billing_mode' in `vnd_agreement_items` is 'FIXED', OR 'qty_used' is 0 then no record will be created in 'vnd_usage_logs' table.

  -- 5-Screen Name - Invoice
  CREATE TABLE IF NOT EXISTS `vnd_invoices` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vendor_id` INT UNSIGNED NOT NULL,
      `agreement_id` INT UNSIGNED DEFAULT NULL, -- Optional, if invoice covers one agreement
      `agreement_item_id` INT UNSIGNED DEFAULT NULL, -- Optional, if invoice covers one agreement item
      `item_description` VARCHAR(255) NOT NULL, -- Snapshot of item name
      `invoice_number` VARCHAR(50) NOT NULL,       -- Vendor's Invoice ID
      `invoice_date` DATE NOT NULL,
      `billing_start_date` DATE DEFAULT NULL,
      `billing_end_date` DATE DEFAULT NULL,
      `fixed_charge_amt` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
      `unit_charge_amt` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
      `qty_used` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
      `unit_rate` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
      `min_guarantee_qty` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
      `tax1_percent` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
      `tax2_percent` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
      `tax3_percent` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
      `tax4_percent` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
      `sub_total` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
      `tax_total` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
      `other_charges` DECIMAL(12, 2) NOT NULL DEFAULT 0.00, -- Penalties/Bonuses
      `discount_amount` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
      `net_payable` DECIMAL(12, 2) NOT NULL,
      `amount_paid` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
      `balance_due` DECIMAL(12, 2) GENERATED ALWAYS AS (net_payable - amount_paid) STORED,
      `due_date` DATE DEFAULT NULL,   --  Payment due date (Invoice date + Credit days)
      `status` INT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (Approval Pending, Approved, Payment Pending, Paid, Overdue)
      `remarks` VARCHAR(512) DEFAULT NULL,
      `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
      `is_deleted` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,

      CONSTRAINT `fk_vnd_inv_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_vnd_inv_agreement` FOREIGN KEY (`agreement_id`) REFERENCES `vnd_agreements`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_vnd_inv_agreement_item` FOREIGN KEY (`agreement_item_id`) REFERENCES `vnd_agreement_items`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_vnd_inv_status` FOREIGN KEY (`status`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
      UNIQUE KEY `uq_vnd_invoice_no` (`vendor_id`, `invoice_number`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 6-Screen Name - Payment
  CREATE TABLE IF NOT EXISTS `vnd_payments` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vendor_id` INT UNSIGNED NOT NULL,
      `invoice_id` INT UNSIGNED NOT NULL,
      `payment_date` DATE NOT NULL,
      `amount` DECIMAL(14, 2) NOT NULL,
      `payment_mode` INT UNSIGNED NOT NULL, -- FK sys_dropdown (Cheque, NEFT, Cash)
      `reference_no` VARCHAR(100) DEFAULT NULL, -- Trx ID, Cheque No
      `status` ENUM('INITIATED', 'SUCCESS', 'FAILED') DEFAULT 'SUCCESS',
      `paid_by` INT UNSIGNED DEFAULT NULL, -- FK sys_users
      `reconciled` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0, -- 0: Not Reconciled, 1: Reconciled
      `reconciled_by` INT UNSIGNED DEFAULT NULL, -- FK sys_users
      `reconciled_at` TIMESTAMP NULL DEFAULT NULL,
      `remarks` TEXT DEFAULT NULL,
      `is_deleted` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_vnd_pay_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `vnd_invoices`(`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_vnd_pay_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_vnd_pay_mode` FOREIGN KEY (`payment_mode`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Vendor Complaints will be handled using common Complaint Module.


-- ===========================================================================
-- 6-COMPLAINT MODULE (cmp)
-- ===========================================================================

  CREATE TABLE IF NOT EXISTS `cmp_complaint_categories` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `parent_id` INT UNSIGNED DEFAULT NULL, -- NULL = Main Category, Value = Sub-category
    `name` VARCHAR(100) NOT NULL, -- e.g. "Transport", "Academic", "Rash Driving"
    `code` VARCHAR(30) DEFAULT NULL, -- Optional short code e.g. "TPT", "ACAD", "RASH_DRIVE"
    `description` VARCHAR(512) DEFAULT NULL,
    `severity_level_id` INT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table (1-10) e.g. "1-Low", "2-Medium", "3-High", "10-Critical"
    `priority_score_id` INT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table (1-5) e.g. 1=Critical, 2=Urgent, 3=High, 4=Medium, 5=Low
    `default_expected_resolution_hours` INT UNSIGNED NOT NULL,  -- This must be less than escalation_l1_hours
    `default_escalation_hours_l1` INT UNSIGNED NOT NULL, -- Time before escalating to L1 (This must be less than escalation_l2_hours)
    `default_escalation_hours_l2` INT UNSIGNED NOT NULL, -- Time before escalating to L2 (This must be less than escalation_l3_hours)
    `default_escalation_hours_l3` INT UNSIGNED NOT NULL, -- Time before escalating to L3 (This must be less than escalation_l4_hours)
    `default_escalation_hours_l4` INT UNSIGNED NOT NULL, -- Time before escalating to L4 (This must be less than escalation_l5_hours)
    `default_escalation_hours_l5` INT UNSIGNED NOT NULL, -- Time before escalating to L5
    `default_escalation_l1_entity_group_id` INT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `default_escalation_l2_entity_group_id` INT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `default_escalation_l3_entity_group_id` INT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `default_escalation_l4_entity_group_id` INT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `default_escalation_l5_entity_group_id` INT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `is_medical_check_required` TINYINT(1) DEFAULT 0, -- If true, then medical check is required
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_cat_parent` (`parent_id`),
    UNIQUE KEY `idx_cat_parent_name` (`parent_id`, `name`),
    UNIQUE KEY `idx_cat_code` (`code`),
    CONSTRAINT `fk_cat_parent` FOREIGN KEY (`parent_id`) REFERENCES `cmp_complaint_categories` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cat_severity_level` FOREIGN KEY (`severity_level_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_cat_priority_score` FOREIGN KEY (`priority_score_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_cat_default_escalation_l1_entity_group` FOREIGN KEY (`default_escalation_l1_entity_group_id`) REFERENCES `sys_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_cat_default_escalation_l2_entity_group` FOREIGN KEY (`default_escalation_l2_entity_group_id`) REFERENCES `sys_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_cat_default_escalation_l3_entity_group` FOREIGN KEY (`default_escalation_l3_entity_group_id`) REFERENCES `sys_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_cat_default_escalation_l4_entity_group` FOREIGN KEY (`default_escalation_l4_entity_group_id`) REFERENCES `sys_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_cat_default_escalation_l5_entity_group` FOREIGN KEY (`default_escalation_l5_entity_group_id`) REFERENCES `sys_groups` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------------------------------
  -- Department wise SLA Configuration (MASTER SETTINGS)
  -- -------------------------------------------------------------------------
  -- This table will capture the detail of complaint categories and sub-categories (like whom to escalate, expected resolution time, escalation time etc.)
  CREATE TABLE IF NOT EXISTS `cmp_department_sla` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `complaint_category_id` INT UNSIGNED NOT NULL,       -- FK to cmp_complaint_categories
    `complaint_subcategory_id` INT UNSIGNED DEFAULT NULL, -- FK to cmp_complaint_categories (if sub-category is Null then it will be applied to all sub-categories exept those defined in the sub-category)
  -- Group wise SLA
    `target_department_id` INT UNSIGNED DEFAULT NULL,    -- FK to sys_departments
    `target_designation_id` INT UNSIGNED DEFAULT NULL,   -- FK to sys_designations
    `target_role_id` INT UNSIGNED DEFAULT NULL,          -- FK to sys_roles
    `target_entity_group_id` INT UNSIGNED DEFAULT NULL,  -- FK to sys_groups
  -- User wise SLA
    `target_user_id` INT UNSIGNED DEFAULT NULL,          -- FK to sys_users
  -- Vehicle wise SLA
    `target_vehicle_id` INT UNSIGNED DEFAULT NULL,       -- FK to sys_vehicles
  -- Vendor wise SLA
    `target_vendor_id` INT UNSIGNED DEFAULT NULL,        -- FK to tpt_vendor
  -- SLA (Expected Resolution Time & Escalation Time)
    `dept_expected_resolution_hours` INT UNSIGNED NOT NULL, -- This must be less than escalation_l1_hours
    `dept_escalation_hours_l1` INT UNSIGNED NOT NULL,       -- Time before escalating to L1 (This must be less than escalation_l2_hours)
    `dept_escalation_hours_l2` INT UNSIGNED NOT NULL,       -- Time before escalating to L2 (This must be less than escalation_l3_hours)
    `dept_escalation_hours_l3` INT UNSIGNED NOT NULL,       -- Time before escalating to L3 (This must be less than escalation_l4_hours)
    `dept_escalation_hours_l4` INT UNSIGNED NOT NULL,       -- Time before escalating to L4 (This must be less than escalation_l5_hours)
    `dept_escalation_hours_l5` INT UNSIGNED NOT NULL,       -- Time before escalating to L5
    `escalation_l1_entity_group_id` INT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `escalation_l2_entity_group_id` INT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `escalation_l3_entity_group_id` INT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `escalation_l4_entity_group_id` INT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `escalation_l5_entity_group_id` INT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_sla_category` FOREIGN KEY (`complaint_category_id`) REFERENCES `cmp_complaint_categories` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sla_subcategory` FOREIGN KEY (`complaint_subcategory_id`) REFERENCES `cmp_complaint_categories` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sla_target_department_id` FOREIGN KEY (`target_department_id`) REFERENCES `sch_departments` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sla_target_designation_id` FOREIGN KEY (`target_designation_id`) REFERENCES `sch_designations` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sla_target_role_id` FOREIGN KEY (`target_role_id`) REFERENCES `sch_roles` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sla_target_entity_group_id` FOREIGN KEY (`target_entity_group_id`) REFERENCES `sch_entity_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sla_target_user_id` FOREIGN KEY (`target_user_id`) REFERENCES `sch_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sla_target_vehicle_id` FOREIGN KEY (`target_vehicle_id`) REFERENCES `sch_vehicles` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sla_target_vendor_id` FOREIGN KEY (`target_vendor_id`) REFERENCES `tpt_vendor` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sla_escalation_l1_entity_group_id` FOREIGN KEY (`escalation_l1_entity_group_id`) REFERENCES `sch_entity_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sla_escalation_l2_entity_group_id` FOREIGN KEY (`escalation_l2_entity_group_id`) REFERENCES `sch_entity_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sla_escalation_l3_entity_group_id` FOREIGN KEY (`escalation_l3_entity_group_id`) REFERENCES `sch_entity_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sla_escalation_l4_entity_group_id` FOREIGN KEY (`escalation_l4_entity_group_id`) REFERENCES `sch_entity_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sla_escalation_l5_entity_group_id` FOREIGN KEY (`escalation_l5_entity_group_id`) REFERENCES `sch_entity_groups` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition: 
  -- 1. If sub-category is NULL then it will be applied to all sub-categories exept those defined in the sub-category
  -- 2. we can create Department/Designation/Role/User/Entity Group wise SLA as per our requirement.
  -- 3. We can Create Escalation Group for each Level (l1,l2,l3,l4,l5) for each Department/Designation/Role/User/Entity Group.
  -- 4. User who are member of that Entity Group will see excalated complaints in their dashboard.

  -- -------------------------------------------------------------------------
  -- MASTER COMPLAINT TABLE
  -- -------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `cmp_complaints` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ticket_no` VARCHAR(30) NOT NULL, -- Auto-generated unique ticket ID (e.g., CMP-2025-0001)
    `ticket_date` DATE NOT NULL DEFAULT CURRENT_DATE(), -- Date when the complaint was raised
    -- Complainant Info (Who raised it)
    `complainant_type_id` INT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (Parent, Student, Staff, Vendor, Anonymous, Public)
    `complainant_user_id` INT UNSIGNED DEFAULT NULL, -- FK to sys_users (NULL if Public/Anonymous)
    `complainant_name` VARCHAR(100) DEFAULT NULL, -- Captured if not a system user (Public/Anonymous)
    `complainant_contact` VARCHAR(50) DEFAULT NULL, -- Captured if not a system user (Public/Anonymous)
    -- Target Entity (Against whom/what)
    `target_user_type_id` INT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table (1=Student, 2=Staff, 3=Group, 4=Department, 5=Role, 6=Designation, 7=Facility, 8=Vehicle, 9=Event, 10=Location, 11-Vendor, 12-Other)
    `target_table_name` VARCHAR(60) DEFAULT NULL, -- e.g. "sch_class", "sch_section", "sch_subject", "sch_designation", "sch_department", "sch_role", "sch_students", "sch_staff", "sch_vehicle", "sch_facility", "sch_event", "sch_location", "sch_other"
    `target_selected_id` INT UNSIGNED DEFAULT NULL, -- Foriegn Key will be managed at Application Level as it will be different for different entities e.g. sch_class, sch_section, sch_subject, sch_students, sch_staff, sch_vehicle etc.
    `target_code` VARCHAR(50) DEFAULT NULL, -- Optional short code e.g. "Transport", "Academic", "Account Manager"
    `target_name` VARCHAR(100) DEFAULT NULL, -- Optional name e.g. "Transport", "Academic", "Account Manager"
    -- Complaint Classification
    `category_id` INT UNSIGNED NOT NULL, -- FK to cmp_complaint_categories
    `subcategory_id` INT UNSIGNED DEFAULT NULL, -- FK to cmp_complaint_categories
    `severity_level_id` INT UNSIGNED NOT NULL, -- It will not be asked to Complaint Form but will be auto fetched from 'cmp_complaint_categories' table
    `priority_score_id` INT UNSIGNED NOT NULL, -- It will not be asked to Complaint Form but will be auto fetched from 'cmp_complaint_categories' table
    -- Complaint Content
    `title` VARCHAR(200) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `location_details` VARCHAR(255) DEFAULT NULL, -- Where did it happen?
    `incident_date` DATETIME DEFAULT NULL,
    `incident_time` TIME DEFAULT NULL,
    -- Status & Resolution
    `status_id` INT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (Open, In-Progress, Escalated, Resolved, Closed, Rejected)
    `assigned_to_role_id` INT UNSIGNED DEFAULT NULL, -- FK to sys_roles (Current Role handling it)
    `assigned_to_user_id` INT UNSIGNED DEFAULT NULL, -- FK to sys_users (Specific Officer)
    `resolution_due_at` DATETIME DEFAULT NULL, -- Calculated from 'cmp_department_sla'. If not available then use 'default_expected_resolution_hours' from 'cmp_complaint_categories'.
    `actual_resolved_at` DATETIME DEFAULT NULL, -- When it was actually resolved
    `resolved_by_role_id` INT UNSIGNED DEFAULT NULL, -- FK to sys_roles (Role who resolved it)
    `resolved_by_user_id` INT UNSIGNED DEFAULT NULL, -- FK to sys_users (Officer who resolved it)
    `resolution_summary` TEXT DEFAULT NULL,
    -- Escalation
    `is_escalated` TINYINT(1) DEFAULT 0,
    `current_escalation_level` TINYINT UNSIGNED DEFAULT 0, -- 0=None, 1=L1, 2=L2...
    -- Meta
    `source_id` INT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table (App, Web, Email, Walk-in, Call)
    `is_anonymous` TINYINT(1) DEFAULT 0,
    `dept_specific_info` JSON DEFAULT NULL, -- Department-specific additional info (e.g., Student ID, Parent ID, route_id, vehicle_id)
    `is_medical_check_required` TINYINT(1) DEFAULT 0, -- Fetch from 'cmp_complaint_categories' table. If true, then system will capture medical check details in 'cmp_medical_checks' table.
    -- Support Files
    `support_file` tinyint(1) DEFAULT 0, -- If true, then system will have support files in sys_media table.
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ticket_no` (`ticket_no`),
    KEY `idx_cmp_status` (`status`),
    KEY `idx_cmp_complainant` (`complainant_type_id`, `complainant_user_id`),
    KEY `idx_cmp_target` (`target_user_type_id`, `target_selected_id`),
    CONSTRAINT `fk_cmp_complainant_type` FOREIGN KEY (`complainant_type_id`) REFERENCES `sys_dropdown_table` (`id`),
    CONSTRAINT `fk_cmp_complainant_name` FOREIGN KEY (`complainant_user_id`) REFERENCES `sys_users` (`id`),
    CONSTRAINT `fk_cmp_target_type` FOREIGN KEY (`target_user_type_id`) REFERENCES `sys_dropdown_table` (`id`),
    CONSTRAINT `fk_cmp_target` FOREIGN KEY (`target_selected_id`) REFERENCES `sys_users` (`id`),
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
    CONSTRAINT `fk_cmp_medical_check` FOREIGN KEY (`is_medical_check_required`) REFERENCES `cmp_medical_checks` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition: 
  --

  -- -------------------------------------------------------------------------
  -- COMPLAINT ACTIONS (AUDIT TRAIL)
  -- -------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `cmp_complaint_actions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `complaint_id` INT UNSIGNED NOT NULL,
    `action_type_id` INT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (Created, Assigned, Comment, StatusChange, Investigation, Escalated, Resolved)
    `performed_by_user_id` INT UNSIGNED DEFAULT NULL, -- FK to sys_users (NULL for System)
    `performed_by_role_id` INT UNSIGNED DEFAULT NULL, -- FK to sys_roles (NULL for System)
    `assigned_to_user_id` INT UNSIGNED DEFAULT NULL, -- If reassigned
    `assigned_to_role_id` INT UNSIGNED DEFAULT NULL, -- If reassigned
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
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `complaint_id` INT UNSIGNED NOT NULL,
    `check_type_id` INT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (AlcoholTest, DrugTest, FitnessCheck)
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
    CONSTRAINT `fk_med_check_type` FOREIGN KEY (`check_type_id`) REFERENCES `sys_dropdown_table` (`id`),
    CONSTRAINT `fk_med_result` FOREIGN KEY (`result`) REFERENCES `sys_dropdown_table` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------------------------------
  -- AI ANALYTICS & INSIGHTS
  -- -------------------------------------------------------------------------
  -- Stores processed insights for complaints (Prediction, Sentiment, Risk)
  CREATE TABLE IF NOT EXISTS `cmp_ai_insights` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `complaint_id` INT UNSIGNED NOT NULL,
    `sentiment_score` DECIMAL(4,3) DEFAULT NULL, -- -1.0 (Negative) to +1.0 (Positive) calculated by AI e.g. -0.8
    `sentiment_label_id` INT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table (Angry, Urgent, Calm, Neutral) calculated by AI e.g. Angry
    `escalation_risk_score` DECIMAL(5,2) DEFAULT NULL, -- 0-100% Probability calculated by AI e.g. 80% 
    `predicted_category_id` INT UNSIGNED DEFAULT NULL, -- FK to cmp_complaint_categories calculated by AI e.g. Rash Driving
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

  SET FOREIGN_KEY_CHECKS = 1;
  -- Condition: 
  -- 1. How to calculate all required fields is mentioned in '/Complaint_Module/Screen_Design/cmp_AI_Calc_Logic.md'
  -- The Approach We will be using is Laravel (ERP) → Python ML Microservice → Prediction → Store in MySQL


-- ===========================================================================
-- 7-NOTIFICATION MODULE (ntf)
-- ===========================================================================

    CREATE TABLE IF NOT EXISTS `ntf_channel_master` (
        `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        `code` VARCHAR(20) NOT NULL,
        `name` VARCHAR(50) NOT NULL,
        `description` VARCHAR(255) NULL,
        `max_retry` INT DEFAULT 1,
        -- Maximum number of retries for failed notifications
        `is_active` TINYINT(1) DEFAULT 1,
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` TIMESTAMP NULL,
        INDEX `idx_ntf_channel_code` (`code`),
        CONSTRAINT `uq_ntf_channel_code` UNIQUE (`code`),
        CONSTRAINT `uq_ntf_channel_name` UNIQUE (`name`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `ntf_notifications` (
        `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        `source_module` VARCHAR(50) NOT NULL,
        -- Triggering module: Exam, Fee, Transport, Complaint etc
        `notification_event` VARCHAR(50) NOT NULL,
        -- Triggering event: Student Registered, Student Promoted, Exam Result Published, Fee Payment Reminder etc
        `title` VARCHAR(255) NOT NULL,
        -- Notification title
        `description` VARCHAR(512) NULL,
        -- Notification description
        `template_id` INT UNSIGNED NULL,
        -- Template ID
        `priority_id` INT UNSIGNED NOT NULL,
        -- fk to sys_dropdown_table e.g. 'LOW, NORMAL, HIGH, URGENT'
        `confidentiality_level_id` INT UNSIGNED NOT NULL,
        -- fk to sys_dropdown_table e.g. 'PUBLIC, RESTRICTED, CONFIDENTIAL'
        `scheduled_at` DATETIME NULL,
        -- Scheduled time for notifications
        `recurring` TINYINT(1) DEFAULT 0,
        -- 0: One Time, 1: Recurring
        `recurring_interval_id` INT UNSIGNED NULL,
        -- fk to sys_dropdown_table e.g. 'HOURLY, DAILY, WEEKLY, MONTHLY, QUARTERLY, YEARLY'
        `recurring_end_at` DATETIME NULL,
        -- End date or time for recurring notifications
        `recurring_end_count` INT NULL,
        -- End count for recurring notifications
        `expires_at` DATETIME NULL,
        -- Expiry date or time for notifications
        `created_by` INT UNSIGNED NOT NULL,
        `is_active` TINYINT(1) DEFAULT 1,
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` TIMESTAMP NULL,
        INDEX `idx_ntf_schedule` (`scheduled_at`),
        INDEX `idx_ntf_source` (`source_module`),
        CONSTRAINT `fk_ntf_priority` FOREIGN KEY (`priority_id`) REFERENCES `sys_dropdown_table`(`id`),
        CONSTRAINT `fk_ntf_confidentiality` FOREIGN KEY (`confidentiality_level_id`) REFERENCES `sys_dropdown_table`(`id`),
        CONSTRAINT `fk_ntf_recurring_interval` FOREIGN KEY (`recurring_interval_id`) REFERENCES `sys_dropdown_table`(`id`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

    -- This table is used to store the notification channels for each notification
    -- =========================================================
    -- NOTIFICATION CHANNELS 
    -- =========================================================
    CREATE TABLE IF NOT EXISTS `ntf_notification_channels` (
        `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        `notification_id` INT UNSIGNED NOT NULL,
        `channel_id` INT UNSIGNED NOT NULL,
        -- fk to ntf_channel_master
        `provider_id` INT UNSIGNED NULL,
        -- fk to sys_dropdown_table e.g. 'MSG91, Twilio, AWS SES, Meta API'
        `status_id` INT UNSIGNED NOT NULL,
        -- fk to sys_dropdown_table e.g. 'PENDING, SENT, FAILED, RETRIED'
        `scheduled_at` DATETIME NULL,
        -- Scheduled time for notifications
        `sent_at` DATETIME NULL,
        -- Actual time when notification was sent
        `failure_reason` VARCHAR(512) NULL,
        `retry_count` INT DEFAULT 0,
        `max_retry` INT DEFAULT 3,
        -- Maximum number of retries for failed notifications (Need to be fetched from ntf_channel_master)
        `is_active` TINYINT(1) DEFAULT 1,
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` TIMESTAMP NULL,
        UNIQUE KEY `uq_notification_channel` (`notification_id`, `channel_id`),
        INDEX `idx_ntf_channel_status` (`status_id`),
        INDEX `idx_ntf_channel_scheduled_at` (`scheduled_at`),
        CONSTRAINT `fk_ntf_channel_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
        CONSTRAINT `fk_ntf_channel_type` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
        CONSTRAINT `fk_ntf_channel_provider` FOREIGN KEY (`provider_id`) REFERENCES `sys_dropdown_table`(`id`),
        CONSTRAINT `fk_ntf_channel_status` FOREIGN KEY (`status_id`) REFERENCES `sys_dropdown_table`(`id`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
    -- Condition;
    -- 1. may have multipal Records against one notification_id (if multiple channels are enabled for the notification)
    -- 2. may have multipal Records against one notification_id and channel_id (if multiple templates are enabled for the notification)

    -- =========================================================
    -- NOTIFICATION TARGETING
    -- =========================================================
    CREATE TABLE IF NOT EXISTS `ntf_notification_targets` (
        `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        `notification_id` INT UNSIGNED NOT NULL,
        `target_type_id` INT UNSIGNED NOT NULL,
        -- FK to sys_dropdown_table e.g. USER, ROLE, DEPARTMENT, DESIGNATION, CLASS, SECTION, SUBJECT, ENTITY_GROUP, ENTIRE_SCHOOL
        `target_table_name` VARCHAR(60) DEFAULT NULL,
        -- e.g. sys_user, sys_role, sch_department, sch_designation, sch_classes, sch_sections, sch_subjects, sch_entity_groups, sch_staff_groups
        `target_selected_id` INT UNSIGNED NULL,
        -- Reference ID based on target type e.g. user_id, role_id, designation_id, etc.
        `is_active` TINYINT(1) DEFAULT 1,
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` TIMESTAMP NULL,
        INDEX `idx_ntf_target_lookup` (`target_type_id`, `target_selected_id`),
        CONSTRAINT `fk_ntf_target_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
        CONSTRAINT `fk_ntf_target_type` FOREIGN KEY (`target_type_id`) REFERENCES `sys_dropdown_table`(`id`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
    -- Condition;
    -- 1. may have multipal Records against one notification_id (if multiple targets are selected for the notification)
    -- 2. may have multipal Records against one target_type_id (if multiple targets are selected for the notification)

    -- =========================================================
    -- USER NOTIFICATION PREFERENCES
    -- =========================================================
    CREATE TABLE IF NOT EXISTS `ntf_user_preferences` (
        `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        `user_id` INT UNSIGNED NOT NULL,
        `channel_id` INT UNSIGNED NOT NULL,
        -- fk to ntf_channel_master
        `is_enabled` TINYINT(1) DEFAULT 1,
        `quiet_hours_start` TIME NULL,
        `quiet_hours_end` TIME NULL,
        `is_active` TINYINT(1) DEFAULT 1,
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` TIMESTAMP NULL,
        UNIQUE KEY `uq_user_channel` (`user_id`, `channel_id`),
        CONSTRAINT `fk_ntf_pref_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

    -- =========================================================
    -- NOTIFICATION TEMPLATES
    -- =========================================================
    CREATE TABLE IF NOT EXISTS `ntf_templates` (
        `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        `template_code` VARCHAR(50) NOT NULL,
        `channel_id` INT UNSIGNED NOT NULL,
        -- fk to ntf_channel_master
        `subject` VARCHAR(255) NULL,
        -- 'Used for Email'
        `body` TEXT NOT NULL,
        -- 'Supports {{placeholders}}'
        `language_code` VARCHAR(10) DEFAULT 'en',
        `media_id` INT UNSIGNED NULL,
        `is_system_template` TINYINT(1) DEFAULT 0,
        `is_active` TINYINT(1) DEFAULT 1,
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` TIMESTAMP NULL,
        UNIQUE KEY `uq_template_code_channel` (`template_code`, `channel_id`),
        CONSTRAINT `fk_ntf_template_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
        CONSTRAINT `fk_ntf_template_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media`(`id`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

    -- =========================================================
    -- NOTIFICATION RESOLVED RECIPIENTS (Final Resolved Recipients to send Notification)
    -- =========================================================
    CREATE TABLE IF NOT EXISTS `ntf_resolved_recipients` (
        `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        `notification_id` INT UNSIGNED NOT NULL,
        `channel_id` INT UNSIGNED NOT NULL,
        -- fk to ntf_channel_master
        `template_id` INT UNSIGNED NOT NULL,
        -- fk to ntf_templates
        `notification_target_id` INT UNSIGNED NOT NULL,
        -- fk to ntf_notification_targets
        `user_preference_id` INT UNSIGNED NOT NULL,
        -- fk to ntf_user_preferences
        `resolved_user_id` INT UNSIGNED NOT NULL,
        -- fk to sys_user
        `mobile_number` VARCHAR(15) NULL,
        `email` VARCHAR(255) NULL,
        `is_active` TINYINT(1) DEFAULT 1,
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` TIMESTAMP NULL,
        INDEX `idx_ntf_recipient_user` (`resolved_user_id`),
        INDEX `idx_ntf_recipient_preference` (`user_preference_id`),
        INDEX `idx_ntf_recipient_target` (`notification_target_id`),
        CONSTRAINT `fk_ntf_recipient_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
        CONSTRAINT `fk_ntf_recipient_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
        CONSTRAINT `fk_ntf_recipient_template` FOREIGN KEY (`template_id`) REFERENCES `ntf_templates`(`id`),
        CONSTRAINT `fk_ntf_recipient_preference` FOREIGN KEY (`user_preference_id`) REFERENCES `ntf_user_preferences`(`id`),
        CONSTRAINT `fk_ntf_recipient_target` FOREIGN KEY (`notification_target_id`) REFERENCES `ntf_notification_targets`(`id`),
        CONSTRAINT `fk_ntf_recipient_user` FOREIGN KEY (`resolved_user_id`) REFERENCES `sys_user`(`id`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
    -- Condition:
    -- 1. may have multipal Records against one notification_id
    -- 2. may have multipal Records against one user_id (if multiple channels are enabled for the user)
    
    -- =========================================================
    -- NOTIFICATION DELIVERY LOGS
    -- =========================================================
    CREATE TABLE IF NOT EXISTS `ntf_delivery_logs` (
        `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        `notification_id` INT UNSIGNED NOT NULL,
        `channel_id` INT UNSIGNED NOT NULL,
        -- fk to ntf_channel_master
        `notification_target_id` INT UNSIGNED NOT NULL,
        -- New
        `resolved_user_id` INT UNSIGNED NOT NULL,
        `delivery_status_id` INT UNSIGNED NOT NULL,
        -- 'SENT, FAILED, READ, CLICKED'
        `delivered_at` DATETIME NULL,
        `read_at` DATETIME NULL,
        `response_payload` JSON NULL,
        -- 'Provider response'
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` TIMESTAMP NULL,
        INDEX `idx_ntf_delivery_user` (`resolved_user_id`),
        INDEX `idx_ntf_delivery_status` (`delivery_status_id`),
        CONSTRAINT `fk_ntf_log_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
        CONSTRAINT `fk_ntf_log_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
        CONSTRAINT `fk_ntf_log_status` FOREIGN KEY (`delivery_status_id`) REFERENCES `sys_dropdown_table`(`id`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;


-- =====================================================================
-- TIMETABLE MODULE - VERSION 7.6 (PRODUCTION-GRADE)
-- Enhanced from tt_timetable_ddl_v7.5.sql
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;


-- -------------------------------------------------
-- Required Global Parameters from sys_setting Table
-- -------------------------------------------------
  -- `Subj_Group_will_be_used_for_all_sections_of_a_class`
  -- `Allow_extra_student_in_vehicale_beyond_capacity`
  -- `Allow_only_one_side_transport_charges`
  -- `Allow_different_pickup_and_drop_point`
  -- `trip_usage_needs_to_be_updated_into_vendor_usage_log`
  -- `Avreage_no_of_student_per_section`
  -- `Minimum_no_of_student_per_section`
  -- `Maximum_no_of_student_per_section`
  -- `section_of_a_class_has_home_room`
  -- `teacher_has_home_room`

-- -------------------------------------------------
--  SECTION 0: CONFIGURATION TABLES (ENHANCED)
-- -------------------------------------------------

	-- 0.1 Academic Term (Enhanced with constraints and indexes)
    -- This table is created in the School_Setup module but will will be shown & can be Modified in Timetable as well.
    -- This will be used in Lesson Planning for creating Schedule for all the Subjects for Entire Session
	CREATE TABLE IF NOT EXISTS `sch_academic_term` (
    `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT, -- Modified on 20Feb
    `academic_session_id` INT UNSIGNED NOT NULL,
    `academic_year_start_date` DATE NOT NULL, -- Added on 20Feb
    `academic_year_end_date` DATE NOT NULL, -- Added on 20Feb
    `total_terms_in_academic_session` TINYINT UNSIGNED NOT NULL,    -- Total Terms in an Academic Session -- Added on 20Feb
    `term_ordinal` TINYINT UNSIGNED NOT NULL,                       -- Term Ordinal -- Added on 20Feb
    `term_code` VARCHAR(20) NOT NULL,                               -- Term Code -- Added on 20Feb
    `term_name` VARCHAR(100) NOT NULL,                              -- Term Name -- Modified on 20Feb
    `term_start_date` DATE NOT NULL,                                -- Term Start Date -- Added on 20Feb
    `term_end_date` DATE NOT NULL,                                  -- Term End Date -- Added on 20Feb
    `term_total_teaching_days` TINYINT UNSIGNED DEFAULT 5, -- Added on 20Feb
    `term_total_exam_days` TINYINT UNSIGNED DEFAULT 2, -- Added on 20Feb
    `term_week_start_day` TINYINT UNSIGNED NOT NULL COMMENT '1=Monday, 7=Sunday', -- Modified on 20Feb
    `term_total_periods_per_day` TINYINT UNSIGNED NOT NULL, -- Added on 20Feb
    `term_total_teaching_periods_per_day` TINYINT UNSIGNED NOT NULL, -- Added on 20Feb
    `term_min_resting_periods_per_day` TINYINT UNSIGNED NOT NULL, -- Added on 20Feb
    `term_max_resting_periods_per_day` TINYINT UNSIGNED NOT NULL, -- Added on 20Feb
    `term_travel_minutes_between_classes` TINYINT UNSIGNED NOT NULL, -- Added on 20Feb
    `is_current` BOOLEAN DEFAULT FALSE,
    `current_flag` tinyint(1) GENERATED ALWAYS AS ((case when (`is_current` = 1) then '1' else NULL end)) STORED,
    `settings_json` JSON DEFAULT NULL, -- Added on 20Feb
    `is_active` BOOLEAN DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Modified on 20Feb
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Modified on 20Feb
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_AcademicTerm_currentFlag` (`current_flag`),
    UNIQUE KEY `uq_academic_term_session_term` (`academic_session_id`, `term_ordinal`),
    INDEX `idx_academic_term_dates` (`term_start_date`, `term_end_date`),
    INDEX `idx_academic_term_current` (`is_current`),
    CONSTRAINT `fk_academic_term_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt`(`id`),
    CONSTRAINT `chk_academic_term_dates` CHECK (`term_start_date` <= `term_end_date`),
    CONSTRAINT `chk_academic_term_year_range` CHECK (`academic_year_start_date` <= `academic_year_end_date`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Academic term/quarter/semester structure';
  -- Conditions:
	-- 1. The fields in above table will be used in Lesson & Syllabus Planning as well.

	-- 0.2 Timetable Config (Enhanced with versioning and validation)
    -- Here we are setting what all Settings will be used for the Timetable Module
    -- Only Edit Functionality is require. No one can Add or Delete any record.
    -- In Edit also "key" can not be edit. In Edit "key" will not be display.
	CREATE TABLE IF NOT EXISTS `tt_config` (
    `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ordinal` INT UNSIGNED NOT NULL DEFAULT 1, -- Modified on 20Feb
    `key` VARCHAR(150) NOT NULL, -- Sync: 'Max_Periods_Per_Day', 'Max_Periods_Per_Week' etc.
    `key_name` VARCHAR(150) NOT NULL, -- Added on 20Feb
    `value` VARCHAR(512) NOT NULL,
    `value_type` ENUM('STRING', 'NUMBER', 'BOOLEAN', 'DATE', 'TIME', 'DATETIME', 'JSON') NOT NULL,
    `description` VARCHAR(255) NOT NULL,
    `validation_rules` JSON DEFAULT NULL,                 -- Added on 20Feb
    `additional_info` JSON DEFAULT NULL,
    `tenant_can_modify` TINYINT(1) NOT NULL DEFAULT 0, -- Modified on 20Feb
    `mandatory` TINYINT(1) NOT NULL DEFAULT 1, -- Modified on 20Feb
    `used_by_app` TINYINT(1) NOT NULL DEFAULT 1, -- Modified on 20Feb
    `version` SMALLINT UNSIGNED NOT NULL DEFAULT 1,       -- Added on 20Feb
    `is_active` TINYINT(1) NOT NULL DEFAULT 1, -- Modified on 20Feb
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_config_key` (`key`),
    UNIQUE KEY `uq_config_ordinal` (`ordinal`),
    INDEX `idx_config_active` (`is_active`)         -- Added New
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='System configuration for timetable module';
  -- Data Seed for tt_config
    -- INSERT INTO `tt_config` (`ordinal`,`key`,`key_name`,`value`,`value_type`,`description`,`additional_info`,`tenant_can_modify`,`mandatory`,`used_by_app`,`is_active`,`deleted_at`,`created_at`,`updated_at`) VALUES
    -- (1,'total_number_of_period_per_day', 'Total Number of Period per Day', '8', 'NUMBER', 'Total Periods per Day', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (2,'school_open_days_per_week', 'School Open Days per Week', '6', 'NUMBER', 'School Open Days per Week', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (3,'school_closed_days_per_week', 'School Closed Days per Week', '1', 'NUMBER', 'School Closed Days per Week', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (4,'number_of_short_breaks_daily_before_lunch', 'Number of Short Breaks Daily Before Lunch', '1', 'NUMBER', 'Number of Short Breaks Daily Before Lunch', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (5,'number_of_short_breaks_daily_after_lunch', 'Number of Short Breaks Daily After Lunch', '1', 'NUMBER', 'Number of Short Breaks Daily After Lunch', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (6,'total_number_of_short_breaks_daily', 'Total Number of Short Breaks Daily', '2', 'NUMBER', 'Total Number of Short Breaks Daily', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (7,'total_number_of_period_before_lunch', 'Total Number of Periods Before Lunch', '4', 'NUMBER', 'Total Number of Periods Before Lunch', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (8,'total_number_of_period_after_lunch', 'Total Number of Periods After Lunch', '4', 'NUMBER', 'Total Number of Periods After Lunch', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (9,'minimum_student_required_for_class_subgroup', 'Minimum Number of Student Required for Class Subgroup', '10', 'NUMBER', 'Minimum Number of Student Required for Class Subgroup', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (10,'maximum_student_required_for_class_subgroup', 'Maximum Number of Student Required for Class Subgroup', '25', 'NUMBER', 'Maximum Number of Student Required for Class Subgroup', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (11,'max_weekly_periods_can_be_allocated_to_teacher', 'Maximum No of Periods that can be allocated to Teacher per week', '8', 'NUMBER', 'Maximum No of Periods that can be allocated to Teacher per week', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (12,'min_weekly_periods_can_be_allocated_to_teacher', 'Minimum No of Periods that can be allocated to Teacher per week', '8', 'NUMBER', 'Minimum No of Periods that can be allocated to Teacher per week', NULL, 0, 1, 1, 1, NULL, NULL, NULL);
    -- (13,`week-start_day`, '1st Day of the Week', 'MONDAY', 'STRING', 'Which day will be consider as 1st Day of the Week', NULL, 0, 1, 1, 1, NULL, NULL, NULL);
    -- (14,)

	-- 0.3 Generation Strategy (Enhanced with algorithm parameters)
	CREATE TABLE IF NOT EXISTS `tt_generation_strategy` (
    `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(20) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255) NULL,
    `algorithm_type` ENUM('RECURSIVE','GENETIC','SIMULATED_ANNEALING','TABU_SEARCH','HYBRID') DEFAULT 'RECURSIVE',
    `algorithm_version` VARCHAR(20) DEFAULT '1.0',      -- Added on 20Feb
    -- Recursive algorithm params
    `max_recursive_depth` INT UNSIGNED DEFAULT 14,
    `max_placement_attempts` INT UNSIGNED DEFAULT 2000,
    -- Tabu search params
    `tabu_size` INT UNSIGNED DEFAULT 100,
    `tabu_tenure` INT UNSIGNED DEFAULT 10,              -- Added on 20Feb
    -- Simulated annealing params
    `initial_temperature` DECIMAL(10,2) DEFAULT 100.00, -- Added on 20Feb
    `cooling_rate` DECIMAL(5,2) DEFAULT 0.95,
    `min_temperature` DECIMAL(10,2) DEFAULT 1.00,       -- Added on 20Feb
    -- Genetic algorithm params
    `population_size` INT UNSIGNED DEFAULT 50,
    `generations` INT UNSIGNED DEFAULT 100,
    `mutation_rate` DECIMAL(5,2) DEFAULT 0.10,          -- Added New
    `crossover_rate` DECIMAL(5,2) DEFAULT 0.80,         -- Added New
    `elite_count` INT UNSIGNED DEFAULT 5,               -- Added New
    -- Common params
    `activity_sorting_method` ENUM('LESS_TEACHER_FIRST','DIFFICULTY_FIRST','CONSTRAINT_COUNT','DURATION_FIRST','RANDOM') DEFAULT 'DIFFICULTY_FIRST',
    `timeout_seconds` INT UNSIGNED DEFAULT 300,         -- Added New
    `max_iterations` INT UNSIGNED DEFAULT 10000,        -- Added New
    `parallel_threads` TINYINT UNSIGNED DEFAULT 1,      -- Added New
    -- Strategy metadata
    `parameters_json` JSON NULL,
    `is_default` TINYINT(1) DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_generation_strategy_code` (`code`),
    INDEX `idx_strategy_default` (`is_default`)         -- Added New
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Timetable generation algorithms and parameters';

	-- 0.4 Default strategies                           -- Added New
	INSERT INTO `tt_generation_strategy`                -- Added New
	(`code`, `name`, `algorithm_type`, `activity_sorting_method`, `is_default`) VALUES
	('RECURSIVE_FAST', 'Fast Recursive Placement', 'RECURSIVE', 'DIFFICULTY_FIRST', 1),
	('TABU_OPTIMIZED', 'Tabu Search Optimized', 'TABU_SEARCH', 'LESS_TEACHER_FIRST', 0),
	('SA_BALANCED', 'Simulated Annealing Balanced', 'SIMULATED_ANNEALING', 'CONSTRAINT_COUNT', 0),
	('GENETIC_THOROUGH', 'Genetic Algorithm Thorough', 'GENETIC', 'DURATION_FIRST', 0),
	('HYBRID_ADAPTIVE', 'Hybrid Adaptive', 'HYBRID', 'DIFFICULTY_FIRST', 0);


-- -------------------------------------------------
--  SECTION 1: MASTER TABLES (ENHANCED)
-- -------------------------------------------------
	-- 1.1 Shift (Enhanced with time validation)
    -- Here we are setting what all Shifts will be used for the Timetable Module 'MORNING', 'TODLER', 'AFTERNOON', 'EVENING'
	CREATE TABLE IF NOT EXISTS `tt_shifts` (
    `id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(20) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `default_start_time` TIME DEFAULT NULL,
    `default_end_time` TIME DEFAULT NULL,
    `max_periods_per_shift` TINYINT UNSIGNED DEFAULT 8,    -- Added New
    `ordinal` TINYINT UNSIGNED DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_shift_code` (`code`),                    -- Added New
    UNIQUE KEY `uq_shift_ordinal` (`ordinal`),
    INDEX `idx_shift_active` (`is_active`),
    CONSTRAINT `chk_shift_times` CHECK (`default_end_time` > `default_start_time` OR (`default_start_time` IS NULL AND `default_end_time` IS NULL))
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 1.2 Day Type (Enhanced with metadata)
	CREATE TABLE IF NOT EXISTS `tt_day_types` (
    `id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT, -- Modified on 20Feb
    `code` VARCHAR(20) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `is_working_day` TINYINT(1) NOT NULL DEFAULT 1,
    `reduced_periods` TINYINT(1) NOT NULL DEFAULT 0,
    `color_code` VARCHAR(7) DEFAULT '#FFFFFF', -- Added on 20Feb
    `icon` VARCHAR(50) DEFAULT NULL, -- Added on 20Feb
    `ordinal` TINYINT UNSIGNED DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_daytype_code` (`code`),
    UNIQUE KEY `uq_daytype_ordinal` (`ordinal`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 1.3 Period Type (Enhanced with workload calculation)
	CREATE TABLE IF NOT EXISTS `tt_period_types` (
    `id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT, -- Modified on 20Feb
    `code` CHAR(2) NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `color_code` VARCHAR(7) DEFAULT '#FFFFFF', -- Added on 20Feb
    `icon` VARCHAR(50) DEFAULT NULL, -- Added on 20Feb
    `is_schedulable` TINYINT(1) NOT NULL DEFAULT 1,
    `counts_as_teaching` TINYINT(1) NOT NULL DEFAULT 0,
    `counts_as_workload` TINYINT(1) NOT NULL DEFAULT 0,
    `is_break` TINYINT(1) NOT NULL DEFAULT 0,
    `is_free_period` TINYINT(1) NOT NULL DEFAULT 0,
    `requires_teacher` TINYINT(1) NOT NULL DEFAULT 1,
    `requires_room` TINYINT(1) NOT NULL DEFAULT 1,
    `workload_factor` DECIMAL(5,2) DEFAULT 1.00,
    `ordinal` TINYINT UNSIGNED DEFAULT 1,
    `duration_minutes` INT UNSIGNED DEFAULT 30,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_periodtype_code` (`code`),
    UNIQUE KEY `uq_periodtype_ordinal` (`ordinal`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 1.4 Teacher Assignment Role (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_teacher_assignment_roles` (
    `id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `is_primary_instructor` TINYINT(1) NOT NULL DEFAULT 0,
    `counts_for_workload` TINYINT(1) NOT NULL DEFAULT 0,
    `allows_overlap` TINYINT(1) NOT NULL DEFAULT 0,
    `workload_factor` DECIMAL(5,2) DEFAULT 1.00,
    `max_concurrent_classes` TINYINT UNSIGNED DEFAULT 1, -- Added on 20Feb
    `ordinal` TINYINT UNSIGNED DEFAULT 1,
    `is_system` TINYINT(1) DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tarole_code` (`code`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 1.5 School Days (Enhanced with ISO weekday support)
	CREATE TABLE IF NOT EXISTS `tt_school_days` (
    `id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(10) NOT NULL,
    `name` VARCHAR(20) NOT NULL,
    `short_name` VARCHAR(5) NOT NULL,
    `day_of_week` TINYINT UNSIGNED NOT NULL COMMENT '1=Monday, 7=Sunday (ISO)', -- Modified on 20Feb
    `iso_weekday` TINYINT UNSIGNED GENERATED ALWAYS AS (day_of_week) STORED, -- Added on 20Feb
    `ordinal` TINYINT UNSIGNED NOT NULL,
    `is_school_day` TINYINT(1) NOT NULL DEFAULT 1,
    `is_weekend` TINYINT(1) GENERATED ALWAYS AS (CASE WHEN day_of_week IN (6,7) THEN 1 ELSE 0 END) STORED, -- Added on 20Feb
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_schoolday_code` (`code`),
    UNIQUE KEY `uq_schoolday_dow` (`day_of_week`),
    INDEX `idx_schoolday_ordinal` (`ordinal`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 1.6 Working Day (Enhanced with validation)
	CREATE TABLE IF NOT EXISTS `tt_working_day` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_session_id` INT UNSIGNED NOT NULL,
    `date` DATE NOT NULL,
    `day_type1_id` TINYINT UNSIGNED NOT NULL, -- Modified on 20Feb
    `day_type2_id` TINYINT UNSIGNED NULL, -- Modified on 20Feb
    `day_type3_id` TINYINT UNSIGNED NULL, -- Modified on 20Feb
    `day_type4_id` TINYINT UNSIGNED NULL, -- Modified on 20Feb
    `period_set_id` INT UNSIGNED DEFAULT NULL COMMENT 'Override period set for this day', -- Added on 20Feb
    `is_school_day` TINYINT(1) NOT NULL DEFAULT 1,
    `remarks` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_workday_date` (`date`),
    INDEX `idx_workday_session` (`academic_session_id`),
    INDEX `idx_workday_daytype` (`day_type1_id`, `day_type2_id`, `day_type3_id`, `day_type4_id`),
    CONSTRAINT `fk_workday_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt`(`id`),
    CONSTRAINT `fk_workday_daytype1` FOREIGN KEY (`day_type1_id`) REFERENCES `tt_day_types` (`id`),
    CONSTRAINT `fk_workday_daytype2` FOREIGN KEY (`day_type2_id`) REFERENCES `tt_day_types` (`id`),
    CONSTRAINT `fk_workday_daytype3` FOREIGN KEY (`day_type3_id`) REFERENCES `tt_day_types` (`id`),
    CONSTRAINT `fk_workday_daytype4` FOREIGN KEY (`day_type4_id`) REFERENCES `tt_day_types` (`id`),
    CONSTRAINT `fk_workday_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_sets` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 1.7 Class Working Day (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_class_working_day_jnt` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_session_id` INT UNSIGNED NOT NULL,
    `date` DATE NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,
    `section_id` INT UNSIGNED DEFAULT NULL,
    `working_day_id` INT UNSIGNED NOT NULL,
    `period_set_id` INT UNSIGNED DEFAULT NULL COMMENT 'Override period set for this class on this day', -- Added on 20Feb
    `is_exam_day` TINYINT(1) NOT NULL DEFAULT 0,
    `is_ptm_day` TINYINT(1) NOT NULL DEFAULT 0,
    `is_half_day` TINYINT(1) NOT NULL DEFAULT 0,
    `is_holiday` TINYINT(1) NOT NULL DEFAULT 0,
    `is_study_day` TINYINT(1) NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_class_working_day` (`class_id`, `section_id`, `date`),
    INDEX `idx_class_working_day_working` (`working_day_id`),
    CONSTRAINT `fk_class_working_day_working` FOREIGN KEY (`working_day_id`) REFERENCES `tt_working_day` (`id`),
    CONSTRAINT `fk_class_working_day_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_sets` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 1.8 Period Set (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_period_sets` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `total_periods` TINYINT UNSIGNED NOT NULL,
    `teaching_periods` TINYINT UNSIGNED NOT NULL,
    `exam_periods` TINYINT UNSIGNED NOT NULL,
    `free_periods` TINYINT UNSIGNED NOT NULL,
    `assembly_periods` TINYINT UNSIGNED NOT NULL,
    `short_break_periods` TINYINT UNSIGNED NOT NULL,
    `lunch_break_periods` TINYINT UNSIGNED NOT NULL,
    `day_start_time` TIME NOT NULL,
    `day_end_time` TIME NOT NULL,
    `total_duration_minutes` INT UNSIGNED GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, day_start_time, day_end_time)) STORED, -- Added on 20Feb
    `is_default` TINYINT(1) DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_periodset_code` (`code`),
    INDEX `idx_periodset_default` (`is_default`),
    CONSTRAINT `chk_periodset_times` CHECK (`day_end_time` > `day_start_time`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 1.9 Period Set Period (Enhanced with validation)
	CREATE TABLE IF NOT EXISTS `tt_period_set_period_jnt` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `period_set_id` INT UNSIGNED NOT NULL,
    `period_ord` TINYINT UNSIGNED NOT NULL,
    `code` VARCHAR(20) NOT NULL,
    `short_name` VARCHAR(50) NOT NULL,
    `period_type_id` INT UNSIGNED NOT NULL,
    `start_time` TIME NOT NULL,
    `end_time` TIME NOT NULL,
    `duration_minutes` SMALLINT UNSIGNED GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, start_time, end_time)) STORED,
    `is_consecutive_allowed` TINYINT(1) DEFAULT 1, -- Added on 20Feb
    `max_consecutive` TINYINT UNSIGNED DEFAULT 1, -- Added on 20Feb
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_psp_set_ord` (`period_set_id`, `period_ord`),
    UNIQUE KEY `uq_psp_set_code` (`period_set_id`, `code`),
    INDEX `idx_psp_type` (`period_type_id`),
    CONSTRAINT `fk_psp_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_sets` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_psp_period_type` FOREIGN KEY (`period_type_id`) REFERENCES `tt_period_types` (`id`),
    CONSTRAINT `chk_psp_time` CHECK (`end_time` > `start_time`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 1.10 Timetable Type (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_timetable_types` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `shift_id` INT UNSIGNED DEFAULT NULL,
    `effective_from_date` DATE DEFAULT NULL,
    `effective_to_date` DATE DEFAULT NULL,
    `school_start_time` TIME DEFAULT NULL,
    `school_end_time` TIME DEFAULT NULL,
    `has_exam` TINYINT(1) NOT NULL DEFAULT 0,
    `has_teaching` TINYINT(1) NOT NULL DEFAULT 1,
    `max_weekly_periods_teacher` TINYINT UNSIGNED DEFAULT 48, -- Added on 20Feb
    `min_weekly_periods_teacher` TINYINT UNSIGNED DEFAULT 15, -- Added on 20Feb
    `ordinal` SMALLINT UNSIGNED DEFAULT 1,
    `is_default` TINYINT(1) DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tttype_code` (`code`),
    INDEX `idx_tttype_shift` (`shift_id`),
    INDEX `idx_tttype_dates` (`effective_from_date`, `effective_to_date`),
    CONSTRAINT `fk_tttype_shift` FOREIGN KEY (`shift_id`) REFERENCES `tt_shifts` (`id`),
    CONSTRAINT `chk_tttype_time` CHECK (`school_end_time` > `school_start_time` OR (`school_start_time` IS NULL AND `school_end_time` IS NULL)),
    CONSTRAINT `chk_tttype_dates` CHECK (`effective_from_date` <= `effective_to_date` OR (`effective_from_date` IS NULL AND `effective_to_date` IS NULL))
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 1.11 Class Timetable Type (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_class_timetable_type_jnt` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_term_id` INT UNSIGNED DEFAULT NULL, -- Modified on 20Feb
    `timetable_type_id` INT UNSIGNED NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,
    `section_id` INT UNSIGNED NULL,
    `period_set_id` INT UNSIGNED NOT NULL,
    `applies_to_all_sections` TINYINT(1) NOT NULL DEFAULT 1, -- Added on 20Feb
    `has_teaching` TINYINT(1) NOT NULL DEFAULT 1, -- Added on 20Feb
    `has_exam` TINYINT(1) NOT NULL DEFAULT 0, -- Added on 20Feb
    `weekly_exam_period_count` TINYINT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `weekly_teaching_period_count` TINYINT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `weekly_free_period_count` TINYINT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `effective_from` DATE DEFAULT NULL,
    `effective_to` DATE DEFAULT NULL,
    `priority` TINYINT UNSIGNED DEFAULT 50, -- Added on 20Feb
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_cttj_class_section_term` (`class_id`, `section_id`, `academic_term_id`, `timetable_type_id`),
    INDEX `idx_cttj_term` (`academic_term_id`),
    INDEX `idx_cttj_timetable` (`timetable_type_id`),
    INDEX `idx_cttj_period_set` (`period_set_id`),
    CONSTRAINT `fk_cttj_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`),
    CONSTRAINT `fk_cttj_timetable` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_types` (`id`),
    CONSTRAINT `fk_cttj_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_cttj_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_cttj_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_sets` (`id`),
    CONSTRAINT `chk_cttj_dates` CHECK (`effective_from` < `effective_to` OR (`effective_from` IS NULL AND `effective_to` IS NULL)),
    CONSTRAINT `chk_cttj_apply_to_all` CHECK ((`section_id` IS NULL AND `applies_to_all_sections` = 1) OR (`section_id` IS NOT NULL))
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------
--  SECTION 2: TIMETABLE REQUIREMENT (ENHANCED)
-- -------------------------------------------------

	-- 2.1 Slot Requirement (Enhanced with validation)
	CREATE TABLE IF NOT EXISTS `tt_slot_requirements` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_term_id` INT UNSIGNED NOT NULL,
    `timetable_type_id` INT UNSIGNED NOT NULL,
    `class_timetable_type_id` INT UNSIGNED NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,
    `section_id` INT UNSIGNED NOT NULL,
    `class_house_room_id` INT UNSIGNED NOT NULL, -- Added on 20Feb
    `weekly_total_slots` TINYINT UNSIGNED NOT NULL,
    `weekly_teaching_slots` TINYINT UNSIGNED NOT NULL,
    `weekly_exam_slots` TINYINT UNSIGNED NOT NULL,
    `weekly_free_slots` TINYINT UNSIGNED NOT NULL,
    `daily_slots_distribution_json` JSON DEFAULT NULL COMMENT 'Distribution pattern across days', -- Added on 20Feb
    `activity_id` INT UNSIGNED NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP, -- Modified on 20Feb
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Modified on 20Feb
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_slot_requirement` (`academic_term_id`, `timetable_type_id`, `class_id`, `section_id`),
    INDEX `idx_slot_requirement_class` (`class_id`, `section_id`),
    INDEX `idx_slot_requirement_activity` (`activity_id`),
    CONSTRAINT `fk_slot_requirements_academic_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`),
    CONSTRAINT `fk_slot_requirements_timetable_type` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_types` (`id`),
    CONSTRAINT `fk_slot_requirements_class_timetable` FOREIGN KEY (`class_timetable_type_id`) REFERENCES `tt_class_timetable_type_jnt` (`id`),
    CONSTRAINT `fk_slot_requirements_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_slot_requirements_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_slot_requirements_room` FOREIGN KEY (`class_house_room_id`) REFERENCES `sch_rooms` (`id`),
    CONSTRAINT `chk_slot_requirement_counts` CHECK (`weekly_total_slots` >= `weekly_teaching_slots` + `weekly_exam_slots`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 2.2 Class Requirement Groups (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_class_requirement_groups` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` CHAR(50) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `class_group_id` INT UNSIGNED NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,
    `section_id` INT UNSIGNED DEFAULT NULL,
    `subject_id` INT UNSIGNED NOT NULL,
    `study_format_id` INT UNSIGNED NOT NULL,
    `subject_type_id` INT UNSIGNED NOT NULL,
    `subject_study_format_id` INT UNSIGNED NOT NULL,
    `class_house_room_id` INT UNSIGNED NOT NULL,
    `student_count` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `eligible_teacher_count` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `is_active` TINYINT(1) NOT NULL DEFAULT 1, -- Modified on 20Feb
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_class_req_groups` (`class_id`, `section_id`, `subject_study_format_id`),
    UNIQUE KEY `uq_class_req_groups_code` (`code`),
    INDEX `idx_class_req_groups_subject` (`subject_study_format_id`),
    INDEX `idx_class_req_groups_room` (`class_house_room_id`),
    CONSTRAINT `fk_class_req_groups_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_class_req_groups_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_class_req_groups_subject_study` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_class_req_groups_room` FOREIGN KEY (`class_house_room_id`) REFERENCES `sch_rooms` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 2.3 Class Requirement Subgroups (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_class_requirement_subgroups` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `class_group_id` INT UNSIGNED NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,
    `section_id` INT UNSIGNED DEFAULT NULL,
    `subject_id` INT UNSIGNED NOT NULL,
    `study_format_id` INT UNSIGNED NOT NULL,
    `subject_type_id` INT UNSIGNED NOT NULL,
    `subject_study_format_id` INT UNSIGNED NOT NULL,
    `class_house_room_id` INT UNSIGNED NOT NULL,
    `student_count` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `eligible_teacher_count` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `is_shared_across_sections` TINYINT(1) NOT NULL DEFAULT 0, -- Added on 20Feb
    `is_shared_across_classes` TINYINT(1) NOT NULL DEFAULT 0, -- Added on 20Feb
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_class_req_subgroups` (`class_id`, `section_id`, `subject_study_format_id`),
    UNIQUE KEY `uq_class_req_subgroups_code` (`code`),
    INDEX `idx_class_req_subgroups_subject` (`subject_study_format_id`),
    INDEX `idx_class_req_subgroups_room` (`class_house_room_id`),
    CONSTRAINT `fk_class_req_subgroups_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_class_req_subgroups_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_class_req_subgroups_subject_study` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_class_req_subgroups_room` FOREIGN KEY (`class_house_room_id`) REFERENCES `sch_rooms` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 2.4 Requirement Consolidation (Enhanced with all constraints)
	CREATE TABLE IF NOT EXISTS `tt_requirement_consolidations` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL, -- Added on 20Feb
    `academic_term_id` INT UNSIGNED NOT NULL,
    `timetable_type_id` INT UNSIGNED NOT NULL,
    `class_requirement_group_id` INT UNSIGNED DEFAULT NULL,
    `class_requirement_subgroup_id` INT UNSIGNED DEFAULT NULL,
    -- Core identifiers
    `class_id` INT UNSIGNED NOT NULL,
    `section_id` INT UNSIGNED DEFAULT NULL,
    `subject_id` INT UNSIGNED NOT NULL,
    `study_format_id` INT UNSIGNED NOT NULL,
    `subject_type_id` INT UNSIGNED NOT NULL,
    `subject_study_format_id` INT UNSIGNED NOT NULL,
    -- Resource info
    `class_house_room_id` INT UNSIGNED NOT NULL,
    `student_count` INT UNSIGNED DEFAULT NULL,
    `eligible_teacher_count` INT UNSIGNED DEFAULT NULL,
    -- Scheduling requirements
    `is_compulsory` TINYINT(1) NOT NULL DEFAULT 1,
    `required_weekly_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `min_periods_per_week` TINYINT UNSIGNED DEFAULT NULL,
    `max_periods_per_week` TINYINT UNSIGNED DEFAULT NULL,
    `min_periods_per_day` TINYINT UNSIGNED DEFAULT NULL,
    `max_periods_per_day` TINYINT UNSIGNED DEFAULT NULL,
    `min_gap_between_periods` TINYINT UNSIGNED DEFAULT NULL,
    `required_consecutive_periods` TINYINT UNSIGNED DEFAULT NULL,
    `allow_consecutive_periods` TINYINT(1) NOT NULL DEFAULT 0,
    `max_consecutive_periods` TINYINT UNSIGNED DEFAULT 2,
    -- Preference fields
    `preferred_periods_json` JSON DEFAULT NULL,
    `avoid_periods_json` JSON DEFAULT NULL,
    `preferred_days_json` JSON DEFAULT NULL,
    `avoid_days_json` JSON DEFAULT NULL,
    `spread_evenly` TINYINT(1) DEFAULT 1, -- Added on 20Feb
    `is_shared_across_sections` TINYINT(1) NOT NULL DEFAULT 0, -- Added on 20Feb
    `is_shared_across_classes` TINYINT(1) NOT NULL DEFAULT 0, -- Added on 20Feb
    -- Room requirements
    `compulsory_specific_room_type` TINYINT(1) NOT NULL DEFAULT 0,
    `required_room_type_id` INT UNSIGNED DEFAULT NULL,
    `required_room_id` INT UNSIGNED DEFAULT NULL,
    `preferred_room_type_id` INT UNSIGNED DEFAULT NULL,
    `preferred_room_ids_json` JSON DEFAULT NULL,
    -- Priority scores (calculated)
    `priority_score` TINYINT UNSIGNED DEFAULT 50, -- Added on 20Feb
    `difficulty_score` TINYINT UNSIGNED DEFAULT 50, -- Added on 20Feb
    `resource_scarcity_index` DECIMAL(5,2) DEFAULT NULL, -- Added on 20Feb
    `teacher_scarcity_index` DECIMAL(5,2) DEFAULT NULL, -- Added on 20Feb
    -- Status
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_requirement_consolidation_uuid` (`uuid`),
    UNIQUE KEY `uq_requirement_consolidation` (`academic_term_id`, `timetable_type_id`, `class_id`, `section_id`, `subject_study_format_id`),
    INDEX `idx_requirement_consolidation_class` (`class_id`, `section_id`),
    INDEX `idx_requirement_consolidation_subject` (`subject_study_format_id`),
    INDEX `idx_requirement_consolidation_room_type` (`required_room_type_id`),
    INDEX `idx_requirement_consolidation_room` (`required_room_id`),
    INDEX `idx_requirement_consolidation_priority` (`priority_score`, `difficulty_score`),
    CONSTRAINT `fk_requirement_consolidations_academic_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`),
    CONSTRAINT `fk_requirement_consolidations_timetable_type` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_types` (`id`),
    CONSTRAINT `fk_requirement_consolidations_group` FOREIGN KEY (`class_requirement_group_id`) REFERENCES `tt_class_requirement_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_requirement_consolidations_subgroup` FOREIGN KEY (`class_requirement_subgroup_id`) REFERENCES `tt_class_requirement_subgroups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_requirement_consolidations_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_requirement_consolidations_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_requirement_consolidations_subject_study` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_requirement_consolidations_room_type` FOREIGN KEY (`required_room_type_id`) REFERENCES `sch_rooms_type` (`id`),
    CONSTRAINT `fk_requirement_consolidations_room` FOREIGN KEY (`required_room_id`) REFERENCES `sch_rooms` (`id`),
    CONSTRAINT `chk_requirement_consolidation_target` CHECK (
        (`class_requirement_group_id` IS NOT NULL AND `class_requirement_subgroup_id` IS NULL) OR
        (`class_requirement_group_id` IS NULL AND `class_requirement_subgroup_id` IS NOT NULL)
    )
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Consolidated requirements for timetable generation';


-- -------------------------------------------------
--  SECTION 3: CONSTRAINT ENGINE (REFINED VERSION)
-- -------------------------------------------------

	-- 3.1 Constraint Category Master (System-defined)
	CREATE TABLE IF NOT EXISTS `tt_constraint_categories` (
		`id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
		`code` VARCHAR(30) NOT NULL,                    -- e.g., 'TEACHER', 'CLASS', 'ACTIVITY', 'ROOM', 'STUDENT', 'GLOBAL'
		`name` VARCHAR(100) NOT NULL,                    -- e.g., 'Teacher Constraints', 'Class Constraints'
		`description` VARCHAR(255) DEFAULT NULL,
		`ordinal` TINYINT UNSIGNED NOT NULL DEFAULT 1,
		`is_system` TINYINT(1) NOT NULL DEFAULT 1,       -- System-defined, cannot be deleted
		`is_active` TINYINT(1) NOT NULL DEFAULT 1,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		PRIMARY KEY (`id`),
		UNIQUE KEY `uq_constraint_category_code` (`code`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Constraint categories (Teacher, Class, Activity, Room, etc.)';

	-- 3.2 Constraint Scope Master (System-defined)
	CREATE TABLE IF NOT EXISTS `tt_constraint_scopes` (
		`id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
		`code` VARCHAR(30) NOT NULL,                    -- e.g., 'GLOBAL', 'INDIVIDUAL', 'GROUP', 'PAIR'
		`name` VARCHAR(100) NOT NULL,                    -- e.g., 'Global', 'Individual', 'Group', 'Pair'
		`description` VARCHAR(255) DEFAULT NULL,
		`target_type_required` TINYINT(1) NOT NULL DEFAULT 0, -- Whether target_type is required
		`target_id_required` TINYINT(1) NOT NULL DEFAULT 0,    -- Whether target_id is required
		`is_system` TINYINT(1) NOT NULL DEFAULT 1,
		`is_active` TINYINT(1) NOT NULL DEFAULT 1,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		PRIMARY KEY (`id`),
		UNIQUE KEY `uq_constraint_scope_code` (`code`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Constraint scopes (Global, Individual, Group, Pair)';

	-- 3.3 Target Type Master (What can constraints be applied to)
	CREATE TABLE IF NOT EXISTS `tt_constraint_target_types` (
		`id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
		`code` VARCHAR(30) NOT NULL,                    -- e.g., 'TEACHER', 'CLASS', 'SECTION', 'SUBJECT', 'ROOM', 'ACTIVITY'
		`name` VARCHAR(100) NOT NULL,                    -- e.g., 'Teacher', 'Class', 'Section', 'Subject', 'Room', 'Activity'
		`table_name` VARCHAR(50) DEFAULT NULL,           -- Associated table name for dynamic FK resolution
		`is_active` TINYINT(1) NOT NULL DEFAULT 1,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		PRIMARY KEY (`id`),
		UNIQUE KEY `uq_constraint_target_type_code` (`code`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Target types for constraints (Teacher, Class, Room, etc.)';

	-- 3.4 Constraint Type Master (Core constraint definitions)
	CREATE TABLE IF NOT EXISTS `tt_constraint_types` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(60) NOT NULL, -- Added on 20Feb
    `name` VARCHAR(150) NOT NULL,
    `description` VARCHAR(500) DEFAULT NULL, -- Modified on 20Feb
    `category_id` TINYINT UNSIGNED NOT NULL, -- Modified on 20Feb
    `scope_id` TINYINT UNSIGNED NOT NULL, -- Modified on 20Feb
    `constraint_level` ENUM('HARD', 'STRONG', 'MEDIUM', 'SOFT', 'OPTIMIZATION') NOT NULL DEFAULT 'MEDIUM', -- Added on 20Feb
    `default_weight` TINYINT UNSIGNED NOT NULL DEFAULT 50, -- Modified on 20Feb
    `is_hard_capable` TINYINT(1) NOT NULL DEFAULT 1, -- Added on 20Feb
    `is_soft_capable` TINYINT(1) NOT NULL DEFAULT 1, -- Added on 20Feb
    `parameter_schema` JSON NOT NULL, -- Added on 20Feb
    `validation_logic` TEXT DEFAULT NULL, -- Added on 20Feb
    `conflict_detection_logic` TEXT DEFAULT NULL, -- Added on 20Feb
    `resolution_priority` TINYINT UNSIGNED DEFAULT 50, -- Added on 20Feb
    `applicable_target_types` JSON NOT NULL, -- Added on 20Feb
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
		PRIMARY KEY (`id`),
		UNIQUE KEY `uq_constraint_type_code` (`code`),
		INDEX `idx_constraint_type_category` (`category_id`),
		INDEX `idx_constraint_type_scope` (`scope_id`),
		INDEX `idx_constraint_type_level` (`constraint_level`),
		CONSTRAINT `fk_constraints_types_category` FOREIGN KEY (`category_id`) REFERENCES `tt_constraint_categories` (`id`),
		CONSTRAINT `fk_constraints_types_scope` FOREIGN KEY (`scope_id`) REFERENCES `tt_constraint_scopes` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Master definition of all constraint types';

	-- 3.5 Constraints (Instance-level constraints)
	CREATE TABLE IF NOT EXISTS `tt_constraints` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL, -- Added on 20Feb
    `constraint_type_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(200) DEFAULT NULL,
    `description` VARCHAR(500) DEFAULT NULL,
    `academic_term_id` INT UNSIGNED DEFAULT NULL,
    `timetable_type_id` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    -- Target specification (polymorphic)
    `target_type_id` TINYINT UNSIGNED NOT NULL, -- Added on 20Feb
    `target_id` INT UNSIGNED NOT NULL, -- Modified on 20Feb
    -- Constraint parameters
    `is_hard` TINYINT(1) NOT NULL DEFAULT 0,
    `weight` TINYINT UNSIGNED NOT NULL DEFAULT 50, -- Modified on 20Feb
    `params_json` JSON NOT NULL,
    -- Temporal validity
    `effective_from_date` DATE DEFAULT NULL, -- Added on 20Feb
    `effective_to_date` DATE DEFAULT NULL, -- Added on 20Feb
    `apply_for_all_days` TINYINT(1) NOT NULL DEFAULT 1,
    `applicable_days_json` JSON DEFAULT NULL, -- Added on 20Feb
    `applicable_periods_json` JSON DEFAULT NULL, -- Added on 20Feb
    -- Additional metadata
    `impact_score` TINYINT UNSIGNED DEFAULT 50,
    `constraint_hash` VARCHAR(64) GENERATED ALWAYS AS (SHA2(CONCAT_WS('|', 
            constraint_type_id, target_type_id, target_id, 
            COALESCE(params_json, ''), is_hard, weight), 256)) STORED, -- Added on 20Feb
    -- Audit
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
		PRIMARY KEY (`id`),
		UNIQUE KEY `uq_constraint_uuid` (`uuid`),
		UNIQUE KEY `uq_constraint_hash` (`constraint_hash`),
		INDEX `idx_constraint_type` (`constraint_type_id`),
		INDEX `idx_constraint_target` (`target_type_id`, `target_id`),
		INDEX `idx_constraint_dates` (`effective_from_date`, `effective_to_date`),
		INDEX `idx_constraint_active` (`is_active`),
		CONSTRAINT `fk_constraints_types` FOREIGN KEY (`constraint_type_id`) REFERENCES `tt_constraint_types` (`id`),
		CONSTRAINT `fk_constraints_target_type` FOREIGN KEY (`target_type_id`) REFERENCES `tt_constraint_target_types` (`id`),
		CONSTRAINT `fk_constraints_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Instance-level constraints for timetable generation';

	-- 3.6 Constraint Group (For grouping related constraints)
	CREATE TABLE IF NOT EXISTS `tt_constraint_groups` (
		`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
		`name` VARCHAR(200) NOT NULL,
		`description` VARCHAR(500) DEFAULT NULL,
		`group_type` ENUM('MUTEX', 'CONCURRENT', 'ORDERED', 'PREFERRED') NOT NULL DEFAULT 'PREFERRED',
		`academic_term_id` INT UNSIGNED DEFAULT NULL,
		`is_active` TINYINT(1) NOT NULL DEFAULT 1,
		`created_by` INT UNSIGNED DEFAULT NULL,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		`deleted_at` TIMESTAMP NULL DEFAULT NULL,
		PRIMARY KEY (`id`),
		INDEX `idx_constraint_group_term` (`academic_term_id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Groups of related constraints (for mutex/concurrent rules)';

	-- 3.7 Constraint Group Members
	CREATE TABLE IF NOT EXISTS `tt_constraint_group_members` (
		`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
		`constraint_group_id` INT UNSIGNED NOT NULL,
		`constraint_id` INT UNSIGNED NOT NULL,
		`ordinal` TINYINT UNSIGNED DEFAULT NULL,           -- Order within group (for ordered groups)
		`is_active` TINYINT(1) NOT NULL DEFAULT 1,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		PRIMARY KEY (`id`),
		UNIQUE KEY `uq_constraint_group_member` (`constraint_group_id`, `constraint_id`),
		CONSTRAINT `fk_constraints_groups_members_group` FOREIGN KEY (`constraint_group_id`) REFERENCES `tt_constraint_groups` (`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_constraints_groups_members_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraints` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 3.8 Teacher Unavailability (Specialized constraint for performance)
	CREATE TABLE IF NOT EXISTS `tt_teacher_unavailables` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `teacher_id` INT UNSIGNED NOT NULL,
    `constraint_id` INT UNSIGNED DEFAULT NULL,
    `unavailable_for_all_days` TINYINT(1) NOT NULL DEFAULT 0,
    `unavailable_for_all_periods` TINYINT(1) NOT NULL DEFAULT 0,
    `day_of_week` TINYINT UNSIGNED DEFAULT NULL, -- Modified on 20Feb
    `period_ord` TINYINT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `is_recurring` TINYINT(1) DEFAULT 1,
    `start_date` DATE DEFAULT NULL,
    `end_date` DATE DEFAULT NULL,
    `reason` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
		PRIMARY KEY (`id`),
		INDEX `idx_teacher_unavailable_teacher` (`teacher_id`),
		INDEX `idx_teacher_unavailable_day_period` (`day_of_week`, `period_ord`),
		INDEX `idx_teacher_unavailable_dates` (`start_date`, `end_date`),
		CONSTRAINT `fk_teacher_unavailables_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`),
		CONSTRAINT `fk_teacher_unavailables_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraints` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 3.9 Room Unavailability (Specialized constraint for performance)
	CREATE TABLE IF NOT EXISTS `tt_room_unavailables` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `room_id` INT UNSIGNED NOT NULL,
    `constraint_id` INT UNSIGNED DEFAULT NULL,
    `day_of_week` TINYINT UNSIGNED NOT NULL,
    `period_ord` TINYINT UNSIGNED DEFAULT NULL,
    `start_date` DATE DEFAULT NULL,
    `end_date` DATE DEFAULT NULL,
    `reason` VARCHAR(255) DEFAULT NULL,
    `is_recurring` TINYINT(1) DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL, -- Added on 20Feb
		PRIMARY KEY (`id`),
		INDEX `idx_room_unavailable_room` (`room_id`),
		INDEX `idx_room_unavailable_day_period` (`day_of_week`, `period_ord`),
		CONSTRAINT `fk_room_unavailables_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`),
		CONSTRAINT `fk_room_unavailables_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraints` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 3.10 Constraint Violation Log (During generation)
	CREATE TABLE IF NOT EXISTS `tt_constraint_violations` (
		`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
		`timetable_id` INT UNSIGNED NOT NULL,
		`generation_run_id` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
		`constraint_id` INT UNSIGNED NOT NULL,
		`violation_type` ENUM('HARD', 'SOFT') NOT NULL,
		`severity` TINYINT UNSIGNED NOT NULL DEFAULT 100, -- 1-100 -- Added on 20Feb
		`violation_count` INT UNSIGNED NOT NULL DEFAULT 1, -- Modified on 20Feb
		`affected_entity_type` TINYINT UNSIGNED DEFAULT NULL, -- FK to tt_constraint_target_type -- Added on 20Feb
		`affected_entity_id` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
		`day_of_week` TINYINT UNSIGNED DEFAULT NULL, -- Added on 20Feb
		`period_ord` TINYINT UNSIGNED DEFAULT NULL, -- Added on 20Feb
		`violation_details_json` JSON DEFAULT NULL, -- Added on 20Feb
		`suggested_resolution_json` JSON DEFAULT NULL, -- Added on 20Feb
		`resolved_at` TIMESTAMP NULL, -- Added on 20Feb
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		PRIMARY KEY (`id`),
		INDEX `idx_violation_timetable` (`timetable_id`),
		INDEX `idx_violation_constraint` (`constraint_id`),
		INDEX `idx_violation_entity` (`affected_entity_type`, `affected_entity_id`),
		CONSTRAINT `fk_violation_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_violation_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraints` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Tracks constraint violations during generation';

	-- 3.11 Constraint Template (For reusability)
	CREATE TABLE IF NOT EXISTS `tt_constraint_templates` (
		`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
		`name` VARCHAR(200) NOT NULL,
		`description` VARCHAR(500) DEFAULT NULL,
		`constraint_type_id` INT UNSIGNED NOT NULL,
		`template_params_json` JSON NOT NULL,              -- Pre-filled parameters
		`is_hard_default` TINYINT(1) DEFAULT 0,
		`weight_default` TINYINT UNSIGNED DEFAULT 50,
		`is_system` TINYINT(1) DEFAULT 0,
		`is_active` TINYINT(1) NOT NULL DEFAULT 1,
		`created_by` INT UNSIGNED DEFAULT NULL,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		`deleted_at` TIMESTAMP NULL DEFAULT NULL,
		PRIMARY KEY (`id`),
		UNIQUE KEY `uq_constraint_template_name` (`name`),
		CONSTRAINT `fk_constraints_template_type` FOREIGN KEY (`constraint_type_id`) REFERENCES `tt_constraint_types` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Templates for commonly used constraints';


-- -------------------------------------------------
--  SECTION 4: TIMETABLE RESOURCE AVAILABILITY (ENHANCED)
-- -------------------------------------------------

	-- 4.1 Teacher Availability Master
	CREATE TABLE IF NOT EXISTS `tt_teacher_availabilities` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `requirement_consolidation_id` INT UNSIGNED NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,
    `section_id` INT UNSIGNED DEFAULT NULL,
    `subject_study_format_id` INT UNSIGNED NOT NULL,
    `teacher_profile_id` INT UNSIGNED NOT NULL,
    `required_weekly_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    -- Teacher profile info
    `is_full_time` TINYINT(1) DEFAULT 1,
    `preferred_shift` INT UNSIGNED DEFAULT NULL,
    `capable_handling_multiple_classes` TINYINT(1) DEFAULT 0,
    `can_be_used_for_substitution` TINYINT(1) DEFAULT 1,
    `certified_for_lab` TINYINT(1) DEFAULT 0,
    -- Capacity
    `max_available_periods_weekly` TINYINT UNSIGNED DEFAULT 48,
    `min_available_periods_weekly` TINYINT UNSIGNED DEFAULT 36,
    `max_allocated_periods_weekly` TINYINT UNSIGNED DEFAULT 1,
    `min_allocated_periods_weekly` TINYINT UNSIGNED DEFAULT 1,
    `current_allocated_periods` TINYINT UNSIGNED DEFAULT 0, -- Added on 20Feb
    `can_be_split_across_sections` TINYINT(1) DEFAULT 0,    
    -- Capability scores
    `proficiency_percentage` TINYINT UNSIGNED DEFAULT NULL,
    `teaching_experience_months` SMALLINT UNSIGNED DEFAULT NULL,
    `is_primary_subject` TINYINT(1) NOT NULL DEFAULT 1,
    `competency_level` ENUM('Facilitator', 'Basic', 'Intermediate', 'Advanced', 'Expert') DEFAULT 'Basic', -- Modified on 20Feb
    `priority_order` INT UNSIGNED DEFAULT NULL,
    `priority_weight` TINYINT UNSIGNED DEFAULT NULL,
    `scarcity_index` TINYINT UNSIGNED DEFAULT NULL,
    `is_hard_constraint` TINYINT(1) DEFAULT 0,
    `allocation_strictness` ENUM('Hard', 'Medium', 'Soft') DEFAULT 'Medium',
    -- Historical data
    `override_priority` TINYINT UNSIGNED DEFAULT NULL,
    `override_reason` VARCHAR(255) DEFAULT NULL,
    `historical_success_ratio` TINYINT UNSIGNED DEFAULT NULL,
    `last_allocation_score` TINYINT UNSIGNED DEFAULT NULL,
    -- School preferences
    `is_primary_teacher` TINYINT(1) NOT NULL DEFAULT 1,
    `is_preferred_teacher` TINYINT(1) NOT NULL DEFAULT 0,
    `preference_score` TINYINT UNSIGNED DEFAULT NULL,
    -- Temporal validity
    `teacher_available_from_date` DATE DEFAULT NULL, -- Modified on 20Feb
    `timetable_start_date` DATE DEFAULT NULL,
    `timetable_end_date` DATE DEFAULT NULL,
    -- Calculated fields
    `available_for_full_timetable` TINYINT(1) GENERATED ALWAYS AS 
        (IF(`teacher_available_from_date` <= `timetable_start_date`, 1, 0)) STORED, -- Added on 20Feb
    `days_not_available` INT GENERATED ALWAYS AS 
        (GREATEST(0, DATEDIFF(`teacher_available_from_date`, `timetable_start_date`))) STORED, -- Added on 20Feb
    `min_availability_score` DECIMAL(7,2) DEFAULT NULL, -- Added on 20Feb
    `max_availability_score` DECIMAL(7,2) DEFAULT NULL, -- Added on 20Feb
    -- Activity link
    `activity_id` INT UNSIGNED NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_teacher_availability` (`requirement_consolidation_id`, `teacher_profile_id`),
    INDEX `idx_teacher_availability_teacher` (`teacher_profile_id`),
    INDEX `idx_teacher_availability_activity` (`activity_id`),
    INDEX `idx_teacher_availability_scores` (`min_availability_score`, `max_availability_score`),
    CONSTRAINT `fk_teacher_availabilities_requirement` FOREIGN KEY (`requirement_consolidation_id`)  REFERENCES `tt_requirement_consolidations` (`id`),
    CONSTRAINT `fk_teacher_availabilities_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_teacher_availabilities_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_teacher_availabilities_subject_study` FOREIGN KEY (`subject_study_format_id`)  REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_teacher_availabilities_teacher_profile` FOREIGN KEY (`teacher_profile_id`)  REFERENCES `sch_teachers_profile` (`id`),
    CONSTRAINT `fk_teacher_availabilities_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Teacher availability per requirement';

	-- 4.2 Teacher Availability Detail (Period-level)
	CREATE TABLE IF NOT EXISTS `tt_teacher_availability_details` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `teacher_availability_id` INT UNSIGNED NOT NULL,
    `teacher_profile_id` INT UNSIGNED NOT NULL,
    `day_number` TINYINT UNSIGNED NOT NULL COMMENT '1-7',
    `day_name` VARCHAR(10) NOT NULL,
    `period_number` TINYINT UNSIGNED NOT NULL,
    `availability_status` ENUM('Available', 'Unavailable', 'Assigned', 'Free Period', 'Break') NOT NULL DEFAULT 'Available', -- Added on 20Feb
    `assigned_class_id` INT UNSIGNED DEFAULT NULL,
    `assigned_section_id` INT UNSIGNED DEFAULT NULL,
    `assigned_subject_study_format_id` INT UNSIGNED DEFAULT NULL,
    `assigned_activity_id` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `constraint_id` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_teacher_availability_detail` (`teacher_profile_id`, `day_number`, `period_number`),
    INDEX `idx_teacher_availability_detail_teacher` (`teacher_profile_id`),
    INDEX `idx_teacher_availability_detail_assigned` (`assigned_class_id`, `assigned_section_id`),    
    CONSTRAINT `fk_teacher_availabilities_details_master` FOREIGN KEY (`teacher_availability_id`)  REFERENCES `tt_teacher_availabilities` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_teacher_availabilities_details_teacher` FOREIGN KEY (`teacher_profile_id`)  REFERENCES `sch_teachers_profile` (`id`),
    CONSTRAINT `fk_teacher_availabilities_details_class` FOREIGN KEY (`assigned_class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_teacher_availabilities_details_section` FOREIGN KEY (`assigned_section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_teacher_availabilities_details_subject` FOREIGN KEY (`assigned_subject_study_format_id`)  REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_teacher_availabilities_details_activity` FOREIGN KEY (`assigned_activity_id`) REFERENCES `tt_activities` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Period-level teacher availability';

	-- 4.3 Room Availability Master
	CREATE TABLE IF NOT EXISTS `tt_room_availabilities` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `room_id` INT UNSIGNED NOT NULL,
    `room_type_id` INT UNSIGNED NOT NULL, -- Added on 20Feb
    `total_rooms_in_category` SMALLINT UNSIGNED NOT NULL,
    `overall_status` ENUM('Available', 'Unavailable', 'Partially Available', 'Assigned') NOT NULL DEFAULT 'Available', -- Added on 20Feb
    `available_for_full_timetable` TINYINT(1) NOT NULL DEFAULT 1, -- Added on 20Feb
    `is_class_house_room` TINYINT(1) NOT NULL DEFAULT 0,
    `house_room_class_id` INT UNSIGNED NULL,
    `house_room_section_id` INT UNSIGNED NULL,
    -- Capacity
    `capacity` INT UNSIGNED DEFAULT NULL,
    `max_limit` INT UNSIGNED DEFAULT NULL,
    `current_occupancy` INT UNSIGNED DEFAULT 0, -- Added on 20Feb
    -- Usage permissions
    `can_be_assigned_for_lecture` TINYINT(1) NOT NULL DEFAULT 1,
    `can_be_assigned_for_practical` TINYINT(1) NOT NULL DEFAULT 1,
    `can_be_assigned_for_exam` TINYINT(1) NOT NULL DEFAULT 1,
    `can_be_assigned_for_activity` TINYINT(1) NOT NULL DEFAULT 1,
    `can_be_assigned_for_sports` TINYINT(1) NOT NULL DEFAULT 1,
    -- Time constraints
    `timetable_start_time` TIME NOT NULL,
    `timetable_end_time` TIME NOT NULL,
    -- Activity link
    `activity_id` INT UNSIGNED NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_room_availability` (`room_id`, `activity_id`),
    INDEX `idx_room_availability_type` (`room_type_id`),
    INDEX `idx_room_availability_house` (`house_room_class_id`, `house_room_section_id`),
    CONSTRAINT `fk_room_availabilities_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`),
    CONSTRAINT `fk_room_availabilities_room_type` FOREIGN KEY (`room_type_id`) REFERENCES `sch_rooms_type` (`id`),
    CONSTRAINT `fk_room_availabilities_class` FOREIGN KEY (`house_room_class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_room_availabilities_section` FOREIGN KEY (`house_room_section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_room_availabilities_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Room availability overview';

	-- 4.4 Room Availability Detail (Period-level)
	CREATE TABLE IF NOT EXISTS `tt_room_availability_details` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `room_availability_id` INT UNSIGNED NOT NULL,
    `room_id` INT UNSIGNED NOT NULL,
    `room_type_id` INT UNSIGNED NOT NULL,
    `day_number` TINYINT UNSIGNED NOT NULL,
    `day_name` VARCHAR(10) NOT NULL,
    `period_number` TINYINT UNSIGNED NOT NULL,
    `availability_status` ENUM('Available', 'Unavailable', 'Assigned') NOT NULL DEFAULT 'Available', -- Added on 20Feb
    `assigned_class_id` INT UNSIGNED DEFAULT NULL,
    `assigned_section_id` INT UNSIGNED DEFAULT NULL,
    `assigned_subject_study_format_id` INT UNSIGNED DEFAULT NULL,
    `assigned_activity_id` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `constraint_id` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_room_availability_detail` (`room_id`, `day_number`, `period_number`),
    INDEX `idx_room_availability_detail_room` (`room_id`),
    INDEX `idx_room_availability_detail_assigned` (`assigned_class_id`, `assigned_section_id`),
    CONSTRAINT `fk_room_availabilities_details_master` FOREIGN KEY (`room_availability_id`)  REFERENCES `tt_room_availabilities` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_room_availabilities_details_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`),
    CONSTRAINT `fk_room_availabilities_details_room_type` FOREIGN KEY (`room_type_id`) REFERENCES `sch_rooms_type` (`id`),
    CONSTRAINT `fk_room_availabilities_details_class` FOREIGN KEY (`assigned_class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_room_availabilities_details_section` FOREIGN KEY (`assigned_section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_room_availabilities_details_subject` FOREIGN KEY (`assigned_subject_study_format_id`)  REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_room_availabilities_details_activity` FOREIGN KEY (`assigned_activity_id`) REFERENCES `tt_activities` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Period-level room availability';


-- -------------------------------------------------
--  SECTION 5: TIMETABLE PREPARATION (ENHANCED)
-- -------------------------------------------------

	-- 5.1 Priority Configuration
	CREATE TABLE IF NOT EXISTS `tt_priority_configs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `requirement_consolidation_id` INT UNSIGNED NOT NULL,
    -- Scoring components
    `teacher_scarcity_index` DECIMAL(7,2) DEFAULT 1.00,
    `weekly_load_ratio` DECIMAL(7,2) DEFAULT 1.00,
    `average_teacher_availability` DECIMAL(7,2) DEFAULT 1.00, -- Added on 20Feb
    `rigidity_score` DECIMAL(7,2) DEFAULT 1.00,
    `resource_scarcity` DECIMAL(7,2) DEFAULT 1.00,
    `subject_difficulty_index` DECIMAL(7,2) DEFAULT 1.00,
    `constraint_count` SMALLINT UNSIGNED DEFAULT 0, -- Added on 20Feb
    `historical_success_rate` DECIMAL(5,2) DEFAULT NULL, -- Added on 20Feb
    -- Calculated priority
    `calculated_priority` DECIMAL(8,3) DEFAULT NULL, -- Added on 20Feb
    `manual_override_priority` DECIMAL(8,3) DEFAULT NULL, -- Added on 20Feb
    `final_priority` DECIMAL(8,3) GENERATED ALWAYS AS (COALESCE(`manual_override_priority`, `calculated_priority`)) STORED, -- Added on 20Feb
    -- Component weights (configurable)
    `weight_teacher_scarcity` TINYINT UNSIGNED DEFAULT 25, -- Added on 20Feb
    `weight_weekly_load` TINYINT UNSIGNED DEFAULT 15, -- Added on 20Feb
    `weight_teacher_availability` TINYINT UNSIGNED DEFAULT 15, -- Added on 20Feb
    `weight_rigidity` TINYINT UNSIGNED DEFAULT 20, -- Added on 20Feb
    `weight_resource_scarcity` TINYINT UNSIGNED DEFAULT 15, -- Added on 20Feb
    `weight_subject_difficulty` TINYINT UNSIGNED DEFAULT 10, -- Added on 20Feb
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_priority_config_requirement` (`requirement_consolidation_id`),
    INDEX `idx_priority_config_final` (`final_priority`),
    CONSTRAINT `fk_priority_config_requirement` FOREIGN KEY (`requirement_consolidation_id`) REFERENCES `tt_requirement_consolidations` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Priority configuration for activities';

	-- 5.2 Activity (Enhanced with comprehensive fields)
	CREATE TABLE IF NOT EXISTS `tt_activities` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL, -- Added on 20Feb
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `academic_term_id` INT UNSIGNED NOT NULL,
    `timetable_type_id` INT UNSIGNED NOT NULL,
    -- Group references
    `class_requirement_group_id` INT UNSIGNED DEFAULT NULL,
    `class_requirement_subgroup_id` INT UNSIGNED DEFAULT NULL,
    `have_sub_activity` TINYINT(1) NOT NULL DEFAULT 0,
    -- Core identifiers
    `class_id` INT UNSIGNED NOT NULL,
    `section_id` INT UNSIGNED DEFAULT NULL,
    `subject_id` INT UNSIGNED NOT NULL,
    `study_format_id` INT UNSIGNED NOT NULL,
    `subject_type_id` INT UNSIGNED NOT NULL, -- Added on 20Feb
    `subject_study_format_id` INT UNSIGNED NOT NULL,
    -- Scheduling requirements
    `required_weekly_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `min_periods_per_week` TINYINT UNSIGNED DEFAULT NULL,
    `max_periods_per_week` TINYINT UNSIGNED DEFAULT NULL,
    `max_per_day` TINYINT UNSIGNED DEFAULT NULL,
    `min_per_day` TINYINT UNSIGNED DEFAULT NULL,
    `min_gap_periods` TINYINT UNSIGNED DEFAULT NULL,
    `allow_consecutive` TINYINT(1) NOT NULL DEFAULT 0,
    `max_consecutive` TINYINT UNSIGNED DEFAULT 2,
    `required_consecutive` TINYINT UNSIGNED DEFAULT NULL,
    -- Preferences
    `preferred_periods_json` JSON DEFAULT NULL,
    `avoid_periods_json` JSON DEFAULT NULL,
    `preferred_days_json` JSON DEFAULT NULL,
    `avoid_days_json` JSON DEFAULT NULL,
    `spread_evenly` TINYINT(1) DEFAULT 1,
    -- Resource metrics
    `eligible_teacher_count` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `min_teacher_availability_score` DECIMAL(7,2) DEFAULT 1.00, -- Added on 20Feb
    `max_teacher_availability_score` DECIMAL(7,2) DEFAULT 1.00, -- Added on 20Feb
    `eligible_room_count` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `room_availability_score` DECIMAL(7,2) DEFAULT 1.00 COMMENT 'Percentage of available rooms for this activity', -- Modified on 20Feb
    -- Activity timing
    `duration_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `weekly_occurrences` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `total_periods` SMALLINT UNSIGNED GENERATED ALWAYS AS (`duration_periods` * `weekly_occurrences`) STORED,
    -- Scheduling flags
    `split_allowed` TINYINT(1) DEFAULT 0,
    `is_compulsory` TINYINT(1) DEFAULT 1,
    -- Priority and difficulty
    `manual_priority` TINYINT UNSIGNED DEFAULT 50,
    `calculated_priority` TINYINT UNSIGNED DEFAULT 50,
    `final_priority` TINYINT UNSIGNED GENERATED ALWAYS AS (GREATEST(`manual_priority`, `calculated_priority`)) STORED,
    `difficulty_score` TINYINT UNSIGNED DEFAULT 50,
    `constraint_count` SMALLINT UNSIGNED DEFAULT 0 COMMENT 'Number of constraints affecting this activity', -- Added on 20Feb
    -- Room requirements
    `compulsory_specific_room_type` TINYINT(1) NOT NULL DEFAULT 0,
    `required_room_type_id` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `required_room_id` INT UNSIGNED DEFAULT NULL,
    `preferred_room_type_id` INT UNSIGNED DEFAULT NULL,
    `preferred_room_ids_json` JSON DEFAULT NULL,
    `requires_room` TINYINT(1) DEFAULT 1,
    -- Status
    `status` ENUM('DRAFT', 'ACTIVE', 'LOCKED', 'ARCHIVED', 'PLACED') NOT NULL DEFAULT 'DRAFT',
    `placement_complete` TINYINT(1) DEFAULT 0, -- Added on 20Feb
    `placed_periods_count` TINYINT UNSIGNED DEFAULT 0, -- Added on 20Feb
    -- Audit
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_activity_uuid` (`uuid`),
    UNIQUE KEY `uq_activity_code` (`code`),
    INDEX `idx_activity_academic_term` (`academic_term_id`),
    INDEX `idx_activity_timetable_type` (`timetable_type_id`),
    INDEX `idx_activity_class` (`class_id`, `section_id`),
    INDEX `idx_activity_subject` (`subject_study_format_id`),
    INDEX `idx_activity_priority` (`final_priority`, `difficulty_score`),
    INDEX `idx_activity_status` (`status`, `placement_complete`),
    CONSTRAINT `fk_activities_academic_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`),
    CONSTRAINT `fk_activities_timetable_type` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_types` (`id`),
    CONSTRAINT `fk_activities_class_group` FOREIGN KEY (`class_requirement_group_id`)  REFERENCES `tt_class_requirement_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_activities_subgroup` FOREIGN KEY (`class_requirement_subgroup_id`)  REFERENCES `tt_class_requirement_subgroups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_activities_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_activities_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_activities_subject_study` FOREIGN KEY (`subject_study_format_id`)  REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_activities_room_type` FOREIGN KEY (`required_room_type_id`) REFERENCES `sch_rooms_type` (`id`),
    CONSTRAINT `fk_activities_room` FOREIGN KEY (`required_room_id`) REFERENCES `sch_rooms` (`id`),
    CONSTRAINT `fk_activities_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `chk_activity_target` CHECK (
        (`class_requirement_group_id` IS NOT NULL AND `class_requirement_subgroup_id` IS NULL) OR
        (`class_requirement_group_id` IS NULL AND `class_requirement_subgroup_id` IS NOT NULL)
    )
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Main activities for timetable scheduling';

	-- 5.3 Sub Activity (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_sub_activities` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `parent_activity_id` INT UNSIGNED NOT NULL,
    `class_requirement_subgroup_id` INT UNSIGNED NOT NULL, -- Added on 20Feb
    `ordinal` TINYINT UNSIGNED NOT NULL,
    `code` VARCHAR(60) NOT NULL, -- Added on 20Feb
    `name` VARCHAR(200) NOT NULL, -- Added on 20Feb
    `class_id` INT UNSIGNED NOT NULL, -- Added on 20Feb
    `section_id` INT UNSIGNED NOT NULL, -- Added on 20Feb
    `subject_study_format_id` INT UNSIGNED NOT NULL, -- Added on 20Feb
    `duration_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `same_day_as_parent` TINYINT(1) DEFAULT 0,
    `consecutive_with_previous` TINYINT(1) DEFAULT 0,
    `min_gap_from_previous` TINYINT UNSIGNED DEFAULT 0, -- Added on 20Feb
    `max_gap_from_previous` TINYINT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_sub_activity_code` (`code`),
    UNIQUE KEY `uq_sub_activity_parent_ord` (`parent_activity_id`, `ordinal`),
    INDEX `idx_sub_activity_parent` (`parent_activity_id`),
    INDEX `idx_sub_activity_class` (`class_id`, `section_id`),
    CONSTRAINT `fk_sub_activities_parent` FOREIGN KEY (`parent_activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sub_activities_subgroup` FOREIGN KEY (`class_requirement_subgroup_id`)  REFERENCES `tt_class_requirement_subgroups` (`id`),
    CONSTRAINT `fk_sub_activities_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_sub_activities_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_sub_activities_subject` FOREIGN KEY (`subject_study_format_id`)  REFERENCES `sch_subject_study_format_jnt` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Sub-activities for split activities';

	-- 5.4 Activity Teacher Mapping
	CREATE TABLE IF NOT EXISTS `tt_activity_teachers` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `activity_id` INT UNSIGNED NOT NULL,
    `teacher_id` INT UNSIGNED NOT NULL,
    `assignment_role_id` INT UNSIGNED NOT NULL,
    `is_required` TINYINT(1) DEFAULT 1,
    `ordinal` TINYINT UNSIGNED DEFAULT 1,
    `preference_score` TINYINT UNSIGNED DEFAULT 50, -- Added on 20Feb
    `allocation_status` ENUM('PENDING', 'ALLOCATED', 'CONFLICT', 'SUBSTITUTED') DEFAULT 'PENDING', -- Added on 20Feb
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_activity_teacher` (`activity_id`, `teacher_id`),
    INDEX `idx_activity_teacher_teacher` (`teacher_id`),
    INDEX `idx_activity_teacher_status` (`allocation_status`),
    CONSTRAINT `fk_activities_teachers_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_activities_teachers_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_activities_teachers_role` FOREIGN KEY (`assignment_role_id`) REFERENCES `tt_teacher_assignment_roles` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Teacher assignments to activities';


-- -------------------------------------------------
--  SECTION 6: TIMETABLE GENERATION & STORAGE (ENHANCED)
-- -------------------------------------------------

	-- 6.1 Generation Queue
	CREATE TABLE IF NOT EXISTS `tt_generation_queues` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `timetable_id` INT UNSIGNED NOT NULL,
    `generation_strategy_id` INT UNSIGNED NOT NULL,
    `priority` TINYINT UNSIGNED DEFAULT 50,
    `status` ENUM('QUEUED', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED') DEFAULT 'QUEUED',
    `attempts` TINYINT UNSIGNED DEFAULT 0,
    `max_attempts` TINYINT UNSIGNED DEFAULT 3,
    `scheduled_at` TIMESTAMP NULL,
    `started_at` TIMESTAMP NULL,
    `completed_at` TIMESTAMP NULL,
    `error_message` TEXT DEFAULT NULL,
    `queue_metadata` JSON DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_generation_queue_uuid` (`uuid`),
    INDEX `idx_generation_queue_status` (`status`, `priority`),
    INDEX `idx_generation_queue_scheduled` (`scheduled_at`),
    CONSTRAINT `fk_generation_queues_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`),
    CONSTRAINT `fk_generation_queues_strategy` FOREIGN KEY (`generation_strategy_id`) REFERENCES `tt_generation_strategy` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Queue for asynchronous timetable generation';

	-- 6.2 Timetable (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_timetables` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `academic_session_id` INT UNSIGNED NOT NULL,
    `academic_term_id` INT UNSIGNED NOT NULL,
    `timetable_type_id` INT UNSIGNED NOT NULL,
    `period_set_id` INT UNSIGNED NOT NULL,
    `generation_strategy_id` INT UNSIGNED DEFAULT NULL COMMENT 'Used for Automated Generation', -- Modified on 20Feb
    `effective_from` DATE NOT NULL,
    `effective_to` DATE DEFAULT NULL,
    `generation_method` ENUM('MANUAL', 'SEMI_AUTO', 'FULL_AUTO') NOT NULL DEFAULT 'MANUAL',
    `version` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `parent_timetable_id` INT UNSIGNED DEFAULT NULL,
    -- Status
    `status` ENUM('DRAFT', 'GENERATING', 'GENERATED', 'VALIDATED', 'PUBLISHED', 'ARCHIVED') NOT NULL DEFAULT 'DRAFT',
    `validation_status` ENUM('PENDING', 'PASSED', 'FAILED', 'WARNING') DEFAULT 'PENDING', -- Added on 20Feb
    -- Timestamps
    `generated_at` TIMESTAMP NULL, -- Added on 20Feb
    `validated_at` TIMESTAMP NULL, -- Added on 20Feb
    `published_at` TIMESTAMP NULL,
    `published_by` INT UNSIGNED DEFAULT NULL,
    -- Statistics
    `total_activities` INT UNSIGNED DEFAULT 0,
    `placed_activities` INT UNSIGNED DEFAULT 0,
    `failed_activities` INT UNSIGNED DEFAULT 0,
    `hard_violations` INT UNSIGNED DEFAULT 0, -- Added on 20Feb
    `soft_violations` INT UNSIGNED DEFAULT 0, -- Added on 20Feb
    `constraint_violations` INT UNSIGNED DEFAULT 0, -- Added on 20Feb
    -- Scores
    `quality_score` DECIMAL(5,2) DEFAULT NULL, -- Added on 20Feb
    `teacher_satisfaction_score` DECIMAL(5,2) DEFAULT NULL, -- Added on 20Feb
    `room_utilization_score` DECIMAL(5,2) DEFAULT NULL, -- Added on 20Feb
    `soft_score` DECIMAL(8,2) DEFAULT NULL, -- Added on 20Feb
    -- Optimization
    `optimization_cycles` INT UNSIGNED DEFAULT 0, -- Modified on 20Feb
    `last_optimized_at` TIMESTAMP NULL, -- Modified on 20Feb
    -- Metadata
    `stats_json` JSON DEFAULT NULL,
    `settings_json` JSON DEFAULT NULL,
    -- Audit
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_timetable_uuid` (`uuid`),
    UNIQUE KEY `uq_timetable_code` (`code`),
    INDEX `idx_timetable_session` (`academic_session_id`, `academic_term_id`),
    INDEX `idx_timetable_type` (`timetable_type_id`),
    INDEX `idx_timetable_status` (`status`, `validation_status`),
    INDEX `idx_timetable_dates` (`effective_from`, `effective_to`),
    CONSTRAINT `fk_timetables_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`),
    CONSTRAINT `fk_timetables_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`),
    CONSTRAINT `fk_timetables_type` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_types` (`id`),
    CONSTRAINT `fk_timetables_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_sets` (`id`),
    CONSTRAINT `fk_timetables_strategy` FOREIGN KEY (`generation_strategy_id`) REFERENCES `tt_generation_strategy` (`id`),
    CONSTRAINT `fk_timetables_parent` FOREIGN KEY (`parent_timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_timetables_published_by` FOREIGN KEY (`published_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_timetables_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Main timetable records';

	-- 6.3 Generation Run (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_generation_runs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `timetable_id` INT UNSIGNED NOT NULL,
    `queue_id` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `run_number` INT UNSIGNED NOT NULL DEFAULT 1,
    `strategy_id` INT UNSIGNED NOT NULL COMMENT 'Link to generation strategy used', -- Modified on 20Feb
    `algorithm_version` VARCHAR(20) DEFAULT NULL,
    -- Timing
    `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `finished_at` TIMESTAMP NULL,
    `duration_seconds` INT UNSIGNED GENERATED ALWAYS AS 
        (TIMESTAMPDIFF(SECOND, started_at, finished_at)) STORED, -- Added on 20Feb
    -- Status
    `status` ENUM('QUEUED', 'RUNNING', 'PAUSED', 'COMPLETED', 'FAILED', 'CANCELLED') NOT NULL DEFAULT 'QUEUED',
    `progress_percentage` TINYINT UNSIGNED DEFAULT 0, -- Added on 20Feb
    -- Algorithm parameters (snapshot)
    `max_recursion_depth` INT UNSIGNED DEFAULT 14,
    `max_placement_attempts` INT UNSIGNED DEFAULT NULL,
    `retry_count` TINYINT UNSIGNED DEFAULT 0,
    `params_json` JSON DEFAULT NULL,
    -- Results
    `activities_total` INT UNSIGNED DEFAULT 0,
    `activities_placed` INT UNSIGNED DEFAULT 0,
    `activities_failed` INT UNSIGNED DEFAULT 0,
    `hard_violations` INT UNSIGNED DEFAULT 0,
    `soft_violations` INT UNSIGNED DEFAULT 0,
    `soft_score` DECIMAL(10,4) DEFAULT NULL,
    -- Detailed stats
    `placement_attempts` INT UNSIGNED DEFAULT 0, -- Added on 20Feb
    `swaps_performed` INT UNSIGNED DEFAULT 0, -- Added on 20Feb
    `backtracks_performed` INT UNSIGNED DEFAULT 0, -- Added on 20Feb
    `stats_json` JSON DEFAULT NULL,
    -- Error handling
    `error_message` TEXT DEFAULT NULL,
    `error_trace` TEXT DEFAULT NULL, -- Added on 20Feb
    -- Audit
    `triggered_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_generation_run_uuid` (`uuid`),
    UNIQUE KEY `uq_generation_run_tt_run` (`timetable_id`, `run_number`),
    INDEX `idx_generation_run_status` (`status`),
    INDEX `idx_generation_run_queue` (`queue_id`),
    CONSTRAINT `fk_generation_runs_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_generation_runs_queue` FOREIGN KEY (`queue_id`) REFERENCES `tt_generation_queues` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_generation_runs_strategy` FOREIGN KEY (`strategy_id`) REFERENCES `tt_generation_strategy` (`id`),
    CONSTRAINT `fk_generation_runs_triggered_by` FOREIGN KEY (`triggered_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Timetable generation run details';

	-- 6.4 Timetable Cell (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_timetable_cells` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL, -- Added on 20Feb
    `timetable_id` INT UNSIGNED NOT NULL,
    `generation_run_id` INT UNSIGNED DEFAULT NULL,
    -- Position
    `day_of_week` TINYINT UNSIGNED NOT NULL COMMENT '1-7 (Monday=1)',
    `period_ord` TINYINT UNSIGNED NOT NULL,
    `cell_date` DATE DEFAULT NULL,
    -- Content
    `activity_id` INT UNSIGNED DEFAULT NULL,
    `sub_activity_id` INT UNSIGNED DEFAULT NULL,
    `class_id` INT UNSIGNED NOT NULL, -- Added on 20Feb
    `section_id` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `subject_study_format_id` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `room_id` INT UNSIGNED DEFAULT NULL,
    -- Status
    `source` ENUM('AUTO', 'MANUAL', 'SWAP', 'LOCK', 'SUBSTITUTE') NOT NULL DEFAULT 'AUTO',
    `is_locked` TINYINT(1) NOT NULL DEFAULT 0,
    `locked_by` INT UNSIGNED DEFAULT NULL,
    `locked_at` TIMESTAMP NULL,
    `has_conflict` TINYINT(1) DEFAULT 0,
    `conflict_details_json` JSON DEFAULT NULL,
    `validation_status` ENUM('VALID', 'WARNING', 'VIOLATION') DEFAULT 'VALID', -- Added on 20Feb
    -- Audit
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_timetable_cell_uuid` (`uuid`),
    UNIQUE KEY `uq_timetable_cell_position` (`timetable_id`, `day_of_week`, `period_ord`, `class_id`, `section_id`),
    INDEX `idx_timetable_cell_timetable` (`timetable_id`),
    INDEX `idx_timetable_cell_activity` (`activity_id`),
    INDEX `idx_timetable_cell_room` (`room_id`),
    INDEX `idx_timetable_cell_date` (`cell_date`),
    INDEX `idx_timetable_cell_locked` (`is_locked`),
    CONSTRAINT `fk_timetables_cells_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_timetables_cells_run` FOREIGN KEY (`generation_run_id`) REFERENCES `tt_generation_runs` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_timetables_cells_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_timetables_cells_sub_activity` FOREIGN KEY (`sub_activity_id`) REFERENCES `tt_sub_activities` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_timetables_cells_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_timetables_cells_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_timetables_cells_subject` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_timetables_cells_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_timetables_cells_locked_by` FOREIGN KEY (`locked_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Individual timetable cells (period-level assignments)';

	-- 6.5 Timetable Cell Teacher
	CREATE TABLE IF NOT EXISTS `tt_timetable_cell_teachers` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `cell_id` INT UNSIGNED NOT NULL,
    `teacher_id` INT UNSIGNED NOT NULL,
    `assignment_role_id` INT UNSIGNED NOT NULL,
    `is_substitute` TINYINT(1) DEFAULT 0, -- Added on 20Feb
    `substitution_log_id` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_cell_teacher` (`cell_id`, `teacher_id`),
    INDEX `idx_cell_teacher_teacher` (`teacher_id`),
    CONSTRAINT `fk_cell_teacher_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cells` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cell_teacher_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_cell_teacher_role` FOREIGN KEY (`assignment_role_id`) REFERENCES `tt_teacher_assignment_roles` (`id`),
    CONSTRAINT `fk_cell_teacher_substitution` FOREIGN KEY (`substitution_log_id`) REFERENCES `tt_substitution_logs` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Teacher assignments to timetable cells';

	-- 6.6 Resource Booking
	CREATE TABLE IF NOT EXISTS `tt_resource_bookings` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `resource_type` ENUM('ROOM', 'LAB', 'TEACHER', 'EQUIPMENT', 'SPORTS', 'SPECIAL') NOT NULL,
    `resource_id` INT UNSIGNED NOT NULL,
    `booking_date` DATE NOT NULL,
    `day_of_week` TINYINT UNSIGNED,
    `period_ord` TINYINT UNSIGNED,
    `start_time` TIME,
    `end_time` TIME,
    `duration_minutes` INT UNSIGNED GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, start_time, end_time)) STORED, -- Added on 20Feb
    `booked_for_type` ENUM('ACTIVITY', 'EXAM', 'EVENT', 'MAINTENANCE', 'MEETING') NOT NULL,
    `booked_for_id` INT UNSIGNED NOT NULL,
    `timetable_cell_id` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `purpose` VARCHAR(500),
    `supervisor_id` INT UNSIGNED,
    `status` ENUM('BOOKED', 'IN_USE', 'COMPLETED', 'CANCELLED', 'CONFLICT') DEFAULT 'BOOKED',
    `is_active` TINYINT UNSIGNED DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_resource_booking` (`resource_type`, `resource_id`, `booking_date`, `period_ord`),
    INDEX `idx_resource_booking_date` (`booking_date`),
    INDEX `idx_resource_booking_status` (`status`),
    CONSTRAINT `fk_resource_bookings_cell` FOREIGN KEY (`timetable_cell_id`) REFERENCES `tt_timetable_cells` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_resource_bookings_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `sch_teachers` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Resource booking and allocation tracking';


-- -------------------------------------------------
-- SECTION 7 : VALIDATION PHASE 
-- -------------------------------------------------

	-- Validation Sessions Table
	CREATE TABLE IF NOT EXISTS `tt_validation_sessions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `academic_term_id` INT UNSIGNED NOT NULL,
    `timetable_type_id` INT UNSIGNED NOT NULL,
    `session_type` ENUM('PRE_REQUISITE', 'PRE_GENERATION', 'POST_GENERATION', 'MANUAL_CHANGE') NOT NULL,
    `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `completed_at` TIMESTAMP NULL,
    `status` ENUM('RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED') DEFAULT 'RUNNING',
    `overall_score` DECIMAL(5,2) DEFAULT NULL,
    `overall_status` ENUM('PASSED', 'PASSED_WITH_WARNINGS', 'FAILED', 'BLOCKED') DEFAULT NULL,
    `summary_json` JSON DEFAULT NULL,
    `parameters_json` JSON DEFAULT NULL,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_validation_session_uuid` (`uuid`),
    INDEX `idx_validation_session_term` (`academic_term_id`),
    INDEX `idx_validation_session_status` (`status`),
    CONSTRAINT `fk_validation_sessions_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`),
    CONSTRAINT `fk_validation_sessions_timetable` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_types` (`id`),
    CONSTRAINT `fk_validation_sessions_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Tracks validation sessions across timetable lifecycle';

	-- Validation Checks Table
	CREATE TABLE IF NOT EXISTS `tt_validation_checks` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `validation_session_id` INT UNSIGNED NOT NULL,
    `check_type` ENUM(
        'TEACHER_AVAILABILITY', 
        'ROOM_AVAILABILITY',
        'CONSTRAINT_COMPATIBILITY',
        'RESOURCE_CAPACITY',
        'REQUIREMENT_COMPLETENESS',
        'DATA_INTEGRITY',
        'WORKLOAD_BALANCE',
        'CONFLICT_DETECTION'
    ) NOT NULL,
    `check_name` VARCHAR(100) NOT NULL,
    `check_severity` ENUM('CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'INFO') NOT NULL,
    `status` ENUM('PENDING', 'RUNNING', 'PASSED', 'FAILED', 'WARNING', 'SKIPPED') DEFAULT 'PENDING',
    `score` DECIMAL(5,2) DEFAULT NULL,
    `details_json` JSON DEFAULT NULL,
    `warnings_json` JSON DEFAULT NULL,
    `failures_json` JSON DEFAULT NULL,
    `recommendations_json` JSON DEFAULT NULL,
    `execution_time_ms` INT UNSIGNED DEFAULT NULL,
    `started_at` TIMESTAMP NULL,
    `completed_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_validation_check_session` (`validation_session_id`),
    INDEX `idx_validation_check_type` (`check_type`, `status`),
    CONSTRAINT `fk_validation_checks_session` FOREIGN KEY (`validation_session_id`) REFERENCES `tt_validation_sessions` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Individual validation checks within a session';

	-- Validation Issue Details
	CREATE TABLE IF NOT EXISTS `tt_validation_issues` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `validation_check_id` INT UNSIGNED NOT NULL,
    `issue_type` ENUM('MISSING_TEACHER', 'INSUFFICIENT_ROOMS', 'CONSTRAINT_VIOLATION', 'CAPACITY_EXCEEDED', 'DATA_MISSING', 'WORKLOAD_OVERLOAD') NOT NULL,
    `severity` ENUM('CRITICAL', 'HIGH', 'MEDIUM', 'LOW') NOT NULL,
    `target_type` VARCHAR(50) DEFAULT NULL COMMENT 'class, teacher, room, activity',
    `target_id` INT UNSIGNED DEFAULT NULL,
    `target_name` VARCHAR(200) DEFAULT NULL,
    `issue_description` TEXT NOT NULL,
    `impact_description` TEXT DEFAULT NULL,
    `resolution_suggestion` TEXT DEFAULT NULL,
    `is_resolved` TINYINT(1) DEFAULT 0,
    `resolved_at` TIMESTAMP NULL,
    `resolved_by` INT UNSIGNED DEFAULT NULL,
    `resolution_notes` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_validation_issue_check` (`validation_check_id`),
    INDEX `idx_validation_issue_target` (`target_type`, `target_id`),
    INDEX `idx_validation_issue_severity` (`severity`, `is_resolved`),
    CONSTRAINT `fk_validation_issues_check` FOREIGN KEY (`validation_check_id`) REFERENCES `tt_validation_checks` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_validation_issues_resolved_by` FOREIGN KEY (`resolved_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Individual validation issues with resolution tracking';

	-- Validation Rules Configuration
	CREATE TABLE IF NOT EXISTS `tt_validation_rules` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `rule_code` VARCHAR(50) NOT NULL,
    `rule_name` VARCHAR(100) NOT NULL,
    `check_type` ENUM(
        'TEACHER_AVAILABILITY', 
        'ROOM_AVAILABILITY',
        'CONSTRAINT_COMPATIBILITY',
        'RESOURCE_CAPACITY',
        'REQUIREMENT_COMPLETENESS',
        'DATA_INTEGRITY',
        'WORKLOAD_BALANCE',
        'CONFLICT_DETECTION'
    ) NOT NULL,
    `severity` ENUM('CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'INFO') NOT NULL,
    `threshold_good` DECIMAL(5,2) DEFAULT NULL COMMENT 'Score above this is good',
    `threshold_warning` DECIMAL(5,2) DEFAULT NULL COMMENT 'Score between warning and good',
    `threshold_fail` DECIMAL(5,2) DEFAULT NULL COMMENT 'Score below this fails',
    `validation_logic` TEXT NOT NULL COMMENT 'SQL or PHP logic for validation',
    `parameters_schema` JSON DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_validation_rule_code` (`rule_code`),
    INDEX `idx_validation_rule_type` (`check_type`, `is_active`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Configurable validation rules';

	-- Validation Override Log
	CREATE TABLE IF NOT EXISTS `tt_validation_overrides` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `validation_session_id` INT UNSIGNED NOT NULL,
    `validation_issue_id` INT UNSIGNED DEFAULT NULL,
    `override_type` ENUM('FORCE_PROCEED', 'DISABLE_CHECK', 'ADJUST_THRESHOLD', 'MANUAL_RESOLUTION') NOT NULL,
    `reason` TEXT NOT NULL,
    `justification` TEXT DEFAULT NULL,
    `approved_by` INT UNSIGNED DEFAULT NULL,
    `approved_at` TIMESTAMP NULL,
    `expires_at` TIMESTAMP NULL,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_validation_override_session` (`validation_session_id`),
    CONSTRAINT `fk_validation_overrides_session` FOREIGN KEY (`validation_session_id`) REFERENCES `tt_validation_sessions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_validation_overrides_issue` FOREIGN KEY (`validation_issue_id`) REFERENCES `tt_validation_issues` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_validation_overrides_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_validation_overrides_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Tracks manual overrides during validation';


-- -------------------------------------------------
--  SECTION 8: TEACHER WORKLOAD & ANALYTICS
-- -------------------------------------------------

	CREATE TABLE IF NOT EXISTS `tt_teacher_workloads` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `teacher_id` INT UNSIGNED NOT NULL,
    `academic_session_id` INT UNSIGNED NOT NULL,
    `academic_term_id` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `timetable_id` INT UNSIGNED DEFAULT NULL,
    -- Workload metrics
    `weekly_periods_assigned` SMALLINT UNSIGNED DEFAULT 0,
    `weekly_periods_max` SMALLINT UNSIGNED DEFAULT NULL,
    `weekly_periods_min` SMALLINT UNSIGNED DEFAULT NULL,
    `daily_distribution_json` JSON DEFAULT NULL,
    -- Subject distribution
    `subjects_assigned_json` JSON DEFAULT NULL,
    `classes_assigned_json` JSON DEFAULT NULL,
    -- Utilization
    `utilization_percent` DECIMAL(5,2) DEFAULT NULL,
    `gap_periods_total` SMALLINT UNSIGNED DEFAULT 0,
    `consecutive_max` TINYINT UNSIGNED DEFAULT 0,
    -- Satisfaction metrics
    `preference_satisfaction_rate` DECIMAL(5,2) DEFAULT NULL, -- Added on 20Feb
    `requested_changes_count` SMALLINT UNSIGNED DEFAULT 0, -- Added on 20Feb
    -- Audit
    `last_calculated_at` TIMESTAMP NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_teacher_workload` (`teacher_id`, `academic_session_id`, `academic_term_id`, `timetable_id`),
    INDEX `idx_teacher_workload_session` (`academic_session_id`),
    CONSTRAINT `fk_teacher_workloads_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_teacher_workloads_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`),
    CONSTRAINT `fk_teacher_workloads_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`),
    CONSTRAINT `fk_teacher_workloads_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Teacher workload analysis';

	-- 8.2 Room Utilization
	CREATE TABLE IF NOT EXISTS `tt_room_utilizations` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `room_id` INT UNSIGNED NOT NULL,
    `academic_session_id` INT UNSIGNED NOT NULL,
    `academic_term_id` INT UNSIGNED DEFAULT NULL,
    `timetable_id` INT UNSIGNED DEFAULT NULL,
    -- Utilization metrics
    `total_periods_available` INT UNSIGNED DEFAULT 0,
    `total_periods_used` INT UNSIGNED DEFAULT 0,
    `utilization_percent` DECIMAL(5,2) GENERATED ALWAYS AS (CASE WHEN total_periods_available > 0 THEN (total_periods_used / total_periods_available) * 100 ELSE 0 END) STORED,
    -- Usage by type
    `lecture_usage_count` INT UNSIGNED DEFAULT 0,
    `practical_usage_count` INT UNSIGNED DEFAULT 0,
    `exam_usage_count` INT UNSIGNED DEFAULT 0,
    `activity_usage_count` INT UNSIGNED DEFAULT 0,
    -- Occupancy
    `avg_occupancy_rate` DECIMAL(5,2) DEFAULT NULL,
    `peak_usage_day` TINYINT UNSIGNED DEFAULT NULL,
    `peak_usage_period` TINYINT UNSIGNED DEFAULT NULL,
    `last_calculated_at` TIMESTAMP NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_room_utilization` (`room_id`, `academic_session_id`, `academic_term_id`),
    INDEX `idx_room_utilization_session` (`academic_session_id`),
    CONSTRAINT `fk_room_utilizations_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`),
    CONSTRAINT `fk_room_utilizations_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`),
    CONSTRAINT `fk_room_utilizations_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Room utilization analysis';

	-- 8.3 Daily Snapshot
	CREATE TABLE IF NOT EXISTS `tt_analytics_daily_snapshots` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `snapshot_date` DATE NOT NULL,
    `academic_session_id` INT UNSIGNED NOT NULL,
    `academic_term_id` INT UNSIGNED DEFAULT NULL,
    `timetable_id` INT UNSIGNED DEFAULT NULL,
    -- Daily metrics
    `total_teachers_present` INT UNSIGNED DEFAULT 0,
    `total_teachers_absent` INT UNSIGNED DEFAULT 0,
    `total_classes_conducted` INT UNSIGNED DEFAULT 0,
    `total_periods_scheduled` INT UNSIGNED DEFAULT 0,
    `total_substitutions` INT UNSIGNED DEFAULT 0,
    -- Constraint metrics
    `violations_detected` INT UNSIGNED DEFAULT 0,
    `hard_violations` INT UNSIGNED DEFAULT 0,
    `soft_violations` INT UNSIGNED DEFAULT 0,
    `snapshot_data_json` JSON DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_daily_snapshot` (`snapshot_date`, `timetable_id`),
    INDEX `idx_daily_snapshot_date` (`snapshot_date`),
    CONSTRAINT `fk_daily_snapshot_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`),
    CONSTRAINT `fk_daily_snapshot_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`),
    CONSTRAINT `fk_daily_snapshot_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Daily analytics snapshots';


-- -------------------------------------------------
--  SECTION 9: AUDIT & HISTORY
-- -------------------------------------------------

	CREATE TABLE IF NOT EXISTS `tt_change_logs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL, -- Added on 20Feb
    `timetable_id` INT UNSIGNED NOT NULL,
    `cell_id` INT UNSIGNED DEFAULT NULL,
    `change_type` ENUM('CREATE', 'UPDATE', 'DELETE', 'LOCK', 'UNLOCK', 'SWAP', 'SUBSTITUTE', 'BULK_UPDATE') NOT NULL,
    `change_date` DATE NOT NULL,
    `change_timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Added on 20Feb
    -- Change details
    `old_values_json` JSON DEFAULT NULL,
    `new_values_json` JSON DEFAULT NULL,
    `reason` VARCHAR(500) DEFAULT NULL,
    `metadata_json` JSON DEFAULT NULL, -- Added on 20Feb
    -- Audit
    `changed_by` INT UNSIGNED DEFAULT NULL,
    `ip_address` VARCHAR(45) DEFAULT NULL, -- Added on 20Feb
    `user_agent` VARCHAR(255) DEFAULT NULL, -- Added on 20Feb
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_change_log_uuid` (`uuid`),
    INDEX `idx_change_log_timetable` (`timetable_id`),
    INDEX `idx_change_log_cell` (`cell_id`),
    INDEX `idx_change_log_date` (`change_date`),
    INDEX `idx_change_log_type` (`change_type`),
    CONSTRAINT `fk_change_logs_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_change_logs_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cells` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_change_logs_changed_by` FOREIGN KEY (`changed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Audit log for all timetable changes';


-- -------------------------------------------------
--  SECTION 10: SUBSTITUTION MANAGEMENT (ENHANCED)
-- -------------------------------------------------

	-- 10.1 Teacher Absence
	CREATE TABLE IF NOT EXISTS `tt_teacher_absences` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL, -- Added on 20Feb
    `teacher_id` INT UNSIGNED NOT NULL,
    `absence_date` DATE NOT NULL,
    `absence_type` ENUM('LEAVE', 'SICK', 'TRAINING', 'OFFICIAL_DUTY', 'PERSONAL', 'EMERGENCY', 'OTHER') NOT NULL,
    `start_period` TINYINT UNSIGNED DEFAULT NULL,
    `end_period` TINYINT UNSIGNED DEFAULT NULL,
    `is_full_day` TINYINT(1) GENERATED ALWAYS AS (CASE WHEN start_period IS NULL AND end_period IS NULL THEN 1 ELSE 0 END) STORED, -- Added on 20Feb
    -- Details
    `reason` VARCHAR(500) DEFAULT NULL,
    `document_proof` VARCHAR(255) DEFAULT NULL, -- Added on 20Feb
    `contact_during_absence` VARCHAR(100) DEFAULT NULL, -- Added on 20Feb
    -- Status
    `status` ENUM('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'COMPLETED') NOT NULL DEFAULT 'PENDING',
    `approved_by` INT UNSIGNED DEFAULT NULL,
    `approved_at` TIMESTAMP NULL,
    -- Substitution
    `substitution_required` TINYINT(1) DEFAULT 1,
    `substitution_completed` TINYINT(1) DEFAULT 0,
    `substitution_deadline` TIMESTAMP NULL, -- Added on 20Feb
    -- Notification
    `notified_at` TIMESTAMP NULL, -- Added on 20Feb
    `acknowledged_at` TIMESTAMP NULL, -- Added on 20Feb
    -- Audit
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_teacher_absence_uuid` (`uuid`),
    INDEX `idx_teacher_absence_teacher` (`teacher_id`),
    INDEX `idx_teacher_absence_date` (`absence_date`),
    INDEX `idx_teacher_absence_status` (`status`),
    CONSTRAINT `fk_teacher_absences_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_teacher_absences_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_teacher_absences_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Teacher absence records';

	-- 10.2 Substitution Recommendation
	CREATE TABLE IF NOT EXISTS `tt_substitution_recommendations` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `teacher_absence_id` INT UNSIGNED NOT NULL,
    `cell_id` INT UNSIGNED NOT NULL,
    `recommended_teacher_id` INT UNSIGNED NOT NULL,
    -- Compatibility scores
    `proficiency_score` TINYINT UNSIGNED DEFAULT 0,
    `availability_score` TINYINT UNSIGNED DEFAULT 0,
    `workload_score` TINYINT UNSIGNED DEFAULT 0,
    `historical_success_score` TINYINT UNSIGNED DEFAULT 0,
    `overall_compatibility_score` TINYINT UNSIGNED GENERATED ALWAYS AS ((proficiency_score + availability_score + workload_score + historical_success_score) / 4) STORED,
    -- Recommendation details
    `compatibility_factors_json` JSON DEFAULT NULL,
    `conflicts_json` JSON DEFAULT NULL,
    `ranking` TINYINT UNSIGNED DEFAULT NULL,
    -- Status
    `status` ENUM('PENDING', 'SELECTED', 'REJECTED', 'EXPIRED') DEFAULT 'PENDING',
    `selected_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_sub_recommendation_absence` (`teacher_absence_id`),
    INDEX `idx_sub_recommendation_cell` (`cell_id`),
    INDEX `idx_sub_recommendation_teacher` (`recommended_teacher_id`),
    INDEX `idx_sub_recommendation_score` (`overall_compatibility_score`),
    CONSTRAINT `fk_sub_recommendation_absence` FOREIGN KEY (`teacher_absence_id`) REFERENCES `tt_teacher_absences` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sub_recommendation_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cells` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sub_recommendation_teacher` FOREIGN KEY (`recommended_teacher_id`) REFERENCES `sch_teachers` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Substitution recommendations';

	-- 10.3 Substitution Log (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_substitution_logs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL, -- Added on 20Feb
    `teacher_absence_id` INT UNSIGNED DEFAULT NULL,
    `cell_id` INT UNSIGNED NOT NULL,
    `substitution_date` DATE NOT NULL,
    `absent_teacher_id` INT UNSIGNED NOT NULL,
    `substitute_teacher_id` INT UNSIGNED NOT NULL,
    `original_teacher_id` INT UNSIGNED NOT NULL, -- Added on 20Feb
    -- Assignment details
    `assignment_method` ENUM('AUTO', 'MANUAL', 'SWAP', 'RECOMMENDATION') NOT NULL DEFAULT 'MANUAL',
    `recommendation_id` INT UNSIGNED DEFAULT NULL, -- Added on 20Feb
    `reason` VARCHAR(500) DEFAULT NULL,
    -- Timeline
    `notified_at` TIMESTAMP NULL,
    `accepted_at` TIMESTAMP NULL,
    `rejected_at` TIMESTAMP NULL, -- Added on 20Feb
    `completed_at` TIMESTAMP NULL,
    -- Status
    `status` ENUM('PENDING', 'ACCEPTED', 'REJECTED', 'COMPLETED', 'CANCELLED', 'EXPIRED') NOT NULL DEFAULT 'PENDING',
    -- Feedback
    `feedback` TEXT DEFAULT NULL,
    `effectiveness_rating` TINYINT UNSIGNED DEFAULT NULL COMMENT '1-5', -- Added on 20Feb
    -- Audit
    `assigned_by` INT UNSIGNED DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_substitution_log_uuid` (`uuid`),
    INDEX `idx_substitution_log_date` (`substitution_date`),
    INDEX `idx_substitution_log_absent` (`absent_teacher_id`),
    INDEX `idx_substitution_log_substitute` (`substitute_teacher_id`),
    INDEX `idx_substitution_log_status` (`status`),
    CONSTRAINT `fk_substitution_logs_absence` FOREIGN KEY (`teacher_absence_id`) REFERENCES `tt_teacher_absences` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_substitution_logs_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cells` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_substitution_logs_recommendation` FOREIGN KEY (`recommendation_id`) REFERENCES `tt_substitution_recommendations` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_substitution_logs_absent` FOREIGN KEY (`absent_teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_substitution_logs_substitute` FOREIGN KEY (`substitute_teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_substitution_logs_original` FOREIGN KEY (`original_teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_substitution_logs_assigned_by` FOREIGN KEY (`assigned_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Substitution records';

	-- 10.4 Substitution Pattern Learning
	CREATE TABLE IF NOT EXISTS `tt_substitution_patterns` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `subject_study_format_id` INT UNSIGNED NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,
    `section_id` INT UNSIGNED DEFAULT NULL,
    `original_teacher_id` INT UNSIGNED NOT NULL,
    `substitute_teacher_id` INT UNSIGNED NOT NULL,    
    -- Success metrics
    `success_count` INT UNSIGNED DEFAULT 0,
    `total_count` INT UNSIGNED DEFAULT 0,
    `success_rate` DECIMAL(5,2) GENERATED ALWAYS AS (CASE WHEN total_count > 0 THEN (success_count / total_count) * 100 ELSE 0 END) STORED,
    -- Context
    `avg_effectiveness_rating` DECIMAL(3,2) DEFAULT NULL,
    `common_reasons_json` JSON DEFAULT NULL,
    `best_fit_scenarios_json` JSON DEFAULT NULL,
    -- Pattern metadata
    `confidence_score` TINYINT UNSIGNED DEFAULT 0,
    `last_used_at` TIMESTAMP NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_substitution_pattern` (`subject_study_format_id`, `class_id`, `section_id`, `original_teacher_id`, `substitute_teacher_id`),
    INDEX `idx_substitution_pattern_success` (`success_rate`),
    CONSTRAINT `fk_substitution_patterns_subject` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_substitution_patterns_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_substitution_patterns_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_substitution_patterns_original` FOREIGN KEY (`original_teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_substitution_patterns_substitute` FOREIGN KEY (`substitute_teacher_id`) REFERENCES `sch_teachers` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='ML pattern learning for substitutions';






-- -------------------------------------------------
-- OPTIMIZATION PHASE
-- -------------------------------------------------

	-- Optimization Runs
	CREATE TABLE IF NOT EXISTS `tt_optimization_runs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `timetable_id` INT UNSIGNED NOT NULL,
    `generation_run_id` INT UNSIGNED DEFAULT NULL,
    `optimization_type` ENUM('SIMULATED_ANNEALING', 'TABU_SEARCH', 'GENETIC', 'GREEDY', 'HYBRID') NOT NULL,
    `run_number` INT UNSIGNED NOT NULL DEFAULT 1,
    `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `finished_at` TIMESTAMP NULL,
    `status` ENUM('QUEUED', 'RUNNING', 'COMPLETED', 'FAILED', 'STOPPED') DEFAULT 'QUEUED',
    -- Input metrics
    `initial_score` DECIMAL(10,4) DEFAULT NULL,
    `initial_hard_violations` INT UNSIGNED DEFAULT 0,
    `initial_soft_violations` INT UNSIGNED DEFAULT 0,
    -- Output metrics
    `final_score` DECIMAL(10,4) DEFAULT NULL,
    `final_hard_violations` INT UNSIGNED DEFAULT 0,
    `final_soft_violations` INT UNSIGNED DEFAULT 0,
    `improvement_percentage` DECIMAL(7,2) GENERATED ALWAYS AS 
        (CASE WHEN initial_score > 0 THEN ((final_score - initial_score) / initial_score) * 100 ELSE NULL END) STORED,
    -- Algorithm parameters
    `parameters_json` JSON NOT NULL,
    `iterations` INT UNSIGNED DEFAULT 0,
    `temperature_history_json` JSON DEFAULT NULL,
    `tabu_list_snapshot` JSON DEFAULT NULL,
    `population_diversity` DECIMAL(5,2) DEFAULT NULL,
    -- Performance
    `execution_time_ms` INT UNSIGNED DEFAULT NULL,
    `memory_usage_mb` DECIMAL(8,2) DEFAULT NULL,
    `cpu_usage_percent` DECIMAL(5,2) DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_optimization_run_uuid` (`uuid`),
    INDEX `idx_optimization_run_timetable` (`timetable_id`),
    INDEX `idx_optimization_run_status` (`status`),
    CONSTRAINT `fk_optimization_runs_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_optimization_runs_generation` FOREIGN KEY (`generation_run_id`) REFERENCES `tt_generation_runs` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Tracks optimization algorithm runs';

	-- Optimization Iteration Details
	CREATE TABLE IF NOT EXISTS `tt_optimization_iterations` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `optimization_run_id` INT UNSIGNED NOT NULL,
    `iteration_number` INT UNSIGNED NOT NULL,
    `temperature` DECIMAL(10,4) DEFAULT NULL COMMENT 'For simulated annealing',
    `current_score` DECIMAL(10,4) NOT NULL,
    `best_score_so_far` DECIMAL(10,4) NOT NULL,
    `acceptance_rate` DECIMAL(5,2) DEFAULT NULL,
    `moves_attempted` INT UNSIGNED DEFAULT 0,
    `moves_accepted` INT UNSIGNED DEFAULT 0,
    `moves_rejected` INT UNSIGNED DEFAULT 0,
    `hard_violations` INT UNSIGNED DEFAULT 0,
    `soft_violations` INT UNSIGNED DEFAULT 0,
    `iteration_metadata` JSON DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    INDEX `idx_optimization_iteration_run` (`optimization_run_id`, `iteration_number`),
    CONSTRAINT `fk_optimization_iterations_run` FOREIGN KEY (`optimization_run_id`) REFERENCES `tt_optimization_runs` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Detailed iteration data for optimization runs';

	-- Optimization Move Log
	CREATE TABLE IF NOT EXISTS `tt_optimization_moves` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `optimization_run_id` INT UNSIGNED NOT NULL,
    `iteration_number` INT UNSIGNED NOT NULL,
    `move_type` ENUM('SWAP', 'MOVE', 'SHIFT', 'SPLIT', 'MERGE') NOT NULL,
    `source_activity_id` INT UNSIGNED DEFAULT NULL,
    `target_activity_id` INT UNSIGNED DEFAULT NULL,
    `source_slot` JSON DEFAULT NULL COMMENT '{day, period}',
    `target_slot` JSON DEFAULT NULL,
    `score_before` DECIMAL(10,4) DEFAULT NULL,
    `score_after` DECIMAL(10,4) DEFAULT NULL,
    `score_delta` DECIMAL(10,4) GENERATED ALWAYS AS (score_after - score_before) STORED,
    `accepted` TINYINT(1) DEFAULT 0,
    `reason` VARCHAR(255) DEFAULT NULL,
    `move_metadata` JSON DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    INDEX `idx_optimization_move_run` (`optimization_run_id`, `iteration_number`),
    CONSTRAINT `fk_optimization_moves_run` FOREIGN KEY (`optimization_run_id`) REFERENCES `tt_optimization_runs` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_optimization_moves_source` FOREIGN KEY (`source_activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_optimization_moves_target` FOREIGN KEY (`target_activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Individual moves during optimization';


-- -------------------------------------------------
-- CONFLICT RESOLUTION WORKFLOW
-- -------------------------------------------------

	-- Conflict Resolution Sessions
	CREATE TABLE IF NOT EXISTS `tt_conflict_resolution_sessions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `timetable_id` INT UNSIGNED NOT NULL,
    `generation_run_id` INT UNSIGNED DEFAULT NULL,
    `session_type` ENUM('AUTO_RESOLVE', 'MANUAL_RESOLVE', 'BATCH_RESOLVE', 'ESCALATION') NOT NULL,
    `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `completed_at` TIMESTAMP NULL,
    `status` ENUM('OPEN', 'IN_PROGRESS', 'RESOLVED', 'PARTIALLY_RESOLVED', 'ESCALATED', 'CLOSED') DEFAULT 'OPEN',
    `total_conflicts` INT UNSIGNED DEFAULT 0,
    `resolved_conflicts` INT UNSIGNED DEFAULT 0,
    `escalated_conflicts` INT UNSIGNED DEFAULT 0,
    `remaining_conflicts` INT UNSIGNED DEFAULT 0,
    `resolution_rate` DECIMAL(5,2) GENERATED ALWAYS AS 
        (CASE WHEN total_conflicts > 0 THEN (resolved_conflicts / total_conflicts) * 100 ELSE 100 END) STORED,
    `session_metadata` JSON DEFAULT NULL,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_conflict_resolution_session_uuid` (`uuid`),
    INDEX `idx_conflict_resolution_session_timetable` (`timetable_id`),
    INDEX `idx_conflict_resolution_session_status` (`status`),
    CONSTRAINT `fk_conflict_resolution_sessions_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_conflict_resolution_sessions_generation` FOREIGN KEY (`generation_run_id`) REFERENCES `tt_generation_runs` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_conflict_resolution_sessions_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Tracks conflict resolution workflow sessions';

	-- Conflict Resolution Options
	CREATE TABLE IF NOT EXISTS `tt_conflict_resolution_options` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `conflict_id` INT UNSIGNED NOT NULL COMMENT 'References tt_conflict_detection.id',
    `resolution_session_id` INT UNSIGNED DEFAULT NULL,
    `option_type` ENUM('SWAP', 'MOVE', 'SPLIT', 'RELAX_CONSTRAINT', 'CHANGE_TEACHER', 'CHANGE_ROOM', 'COMBINE_CLASS') NOT NULL,
    `option_rank` TINYINT UNSIGNED NOT NULL COMMENT '1 = best, 2 = second best, etc.',
    
    -- Option details
    `description` VARCHAR(500) NOT NULL,
    `actions_json` JSON NOT NULL COMMENT 'Detailed steps to resolve',
    `impact_score` DECIMAL(5,2) DEFAULT NULL COMMENT 'Estimated impact (0-100, lower is better)',
    `success_probability` DECIMAL(5,2) DEFAULT NULL COMMENT 'Estimated success rate (0-100)',
    `time_to_implement` INT UNSIGNED DEFAULT NULL COMMENT 'Estimated seconds',
    `requires_approval` TINYINT(1) DEFAULT 0,
    `approval_level` TINYINT UNSIGNED DEFAULT NULL COMMENT '1,2,3 for approval hierarchy',
    
    -- Affected entities
    `affected_activities_json` JSON DEFAULT NULL,
    `affected_teachers_json` JSON DEFAULT NULL,
    `affected_classes_json` JSON DEFAULT NULL,
    `affected_rooms_json` JSON DEFAULT NULL,
    
    -- Selection tracking
    `is_selected` TINYINT(1) DEFAULT 0,
    `selected_at` TIMESTAMP NULL,
    `selected_by` INT UNSIGNED DEFAULT NULL,
    `implementation_status` ENUM('PENDING', 'APPLIED', 'FAILED', 'ROLLED_BACK') DEFAULT 'PENDING',
    `feedback_rating` TINYINT UNSIGNED DEFAULT NULL COMMENT '1-5 stars',
    
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    INDEX `idx_conflict_resolution_option_conflict` (`conflict_id`),
    INDEX `idx_conflict_resolution_option_session` (`resolution_session_id`),
    INDEX `idx_conflict_resolution_option_rank` (`option_rank`, `is_selected`),
    CONSTRAINT `fk_conflict_resolution_options_conflict` FOREIGN KEY (`conflict_id`) REFERENCES `tt_conflict_detections` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_conflict_resolution_options_session` FOREIGN KEY (`resolution_session_id`) REFERENCES `tt_conflict_resolution_sessions` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_conflict_resolution_options_selected_by` FOREIGN KEY (`selected_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Resolution options for each conflict';

	-- Escalation Rules
	CREATE TABLE IF NOT EXISTS `tt_escalation_rules` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `rule_name` VARCHAR(100) NOT NULL,
    `trigger_type` ENUM('CONFLICT_COUNT', 'SEVERITY', 'TIME_ELAPSED', 'MANUAL_REQUEST', 'AUTO_FAILED') NOT NULL,
    `trigger_threshold` INT UNSIGNED DEFAULT NULL,
    `escalation_level` TINYINT UNSIGNED NOT NULL COMMENT '1,2,3,4',
    `escalation_role` VARCHAR(50) DEFAULT NULL COMMENT 'coordinator, academic_head, principal, management',
    `notification_template` TEXT DEFAULT NULL,
    `auto_assign` TINYINT(1) DEFAULT 0,
    `timeout_hours` INT UNSIGNED DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    INDEX `idx_escalation_rule_trigger` (`trigger_type`, `is_active`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Rules for escalating unresolved conflicts';

	-- Escalation Log
	CREATE TABLE IF NOT EXISTS `tt_escalation_logs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `conflict_id` INT UNSIGNED NOT NULL,
    `resolution_session_id` INT UNSIGNED DEFAULT NULL,
    `escalation_rule_id` INT UNSIGNED DEFAULT NULL,
    `escalation_level` TINYINT UNSIGNED NOT NULL,
    `escalated_to` INT UNSIGNED DEFAULT NULL COMMENT 'user_id',
    `escalated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `reason` TEXT DEFAULT NULL,
    `status` ENUM('PENDING', 'ACKNOWLEDGED', 'RESOLVED', 'REJECTED', 'ESCALATED_FURTHER') DEFAULT 'PENDING',
    `acknowledged_at` TIMESTAMP NULL,
    `resolved_at` TIMESTAMP NULL,
    `resolution_notes` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    INDEX `idx_escalation_log_conflict` (`conflict_id`),
    INDEX `idx_escalation_log_status` (`status`),
    CONSTRAINT `fk_escalation_logs_conflict` FOREIGN KEY (`conflict_id`) REFERENCES `tt_conflict_detections` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_escalation_logs_session` FOREIGN KEY (`resolution_session_id`) REFERENCES `tt_conflict_resolution_sessions` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_escalation_logs_rule` FOREIGN KEY (`escalation_rule_id`) REFERENCES `tt_escalation_rules` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_escalation_logs_user` FOREIGN KEY (`escalated_to`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Log of conflict escalations';


-- -------------------------------------------------
-- APPROVAL WORKFLOW
-- -------------------------------------------------

	-- Approval Workflow Definitions
	CREATE TABLE IF NOT EXISTS `tt_approval_workflows` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `workflow_code` VARCHAR(50) NOT NULL,
    `workflow_name` VARCHAR(100) NOT NULL,
    `workflow_type` ENUM('TIMETABLE_PUBLICATION', 'MANUAL_CHANGE', 'CONFLICT_RESOLUTION', 'SUBSTITUTION', 'OVERRIDE') NOT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `is_default` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_approval_workflow_code` (`workflow_code`),
    INDEX `idx_approval_workflow_type` (`workflow_type`, `is_active`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Defines approval workflows for different processes';

	-- Approval Levels
	CREATE TABLE IF NOT EXISTS `tt_approval_levels` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `workflow_id` INT UNSIGNED NOT NULL,
    `level_number` TINYINT UNSIGNED NOT NULL,
    `level_name` VARCHAR(50) NOT NULL,
    `approver_role` VARCHAR(50) NOT NULL COMMENT 'Role code from roles table',
    `approval_type` ENUM('ANY', 'ALL', 'MAJORITY', 'SPECIFIC') DEFAULT 'ANY',
    `min_approvers` TINYINT UNSIGNED DEFAULT 1,
    `can_reject` TINYINT(1) DEFAULT 1,
    `can_request_changes` TINYINT(1) DEFAULT 1,
    `timeout_hours` INT UNSIGNED DEFAULT 48,
    `escalation_level_id` INT UNSIGNED DEFAULT NULL COMMENT 'Next level if timeout',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_approval_level_workflow_level` (`workflow_id`, `level_number`),
    CONSTRAINT `fk_approval_levels_workflow` FOREIGN KEY (`workflow_id`) REFERENCES `tt_approval_workflows` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Levels within an approval workflow';

	-- Approval Requests
	CREATE TABLE IF NOT EXISTS `tt_approval_requests` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `workflow_id` INT UNSIGNED NOT NULL,
    `request_type` ENUM('TIMETABLE_PUBLICATION', 'BULK_CHANGE', 'CONFLICT_RESOLUTION', 'OVERRIDE_REQUEST') NOT NULL,
    `target_type` VARCHAR(50) NOT NULL COMMENT 'timetable, change_batch, conflict, etc.',
    `target_id` INT UNSIGNED NOT NULL,
    `request_title` VARCHAR(200) NOT NULL,
    `request_description` TEXT DEFAULT NULL,
    `request_data_json` JSON DEFAULT NULL COMMENT 'Snapshot of what needs approval',
    `priority` ENUM('LOW', 'MEDIUM', 'HIGH', 'URGENT') DEFAULT 'MEDIUM',
    `current_level` TINYINT UNSIGNED DEFAULT 1,
    `status` ENUM('PENDING', 'IN_PROGRESS', 'APPROVED', 'REJECTED', 'CHANGES_REQUESTED', 'EXPIRED', 'CANCELLED') DEFAULT 'PENDING',
    `submitted_by` INT UNSIGNED NOT NULL,
    `submitted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `completed_at` TIMESTAMP NULL,
    `expires_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_approval_request_uuid` (`uuid`),
    INDEX `idx_approval_request_target` (`target_type`, `target_id`),
    INDEX `idx_approval_request_status` (`status`, `priority`),
    CONSTRAINT `fk_approval_requests_workflow` FOREIGN KEY (`workflow_id`) REFERENCES `tt_approval_workflows` (`id`),
    CONSTRAINT `fk_approval_requests_submitted_by` FOREIGN KEY (`submitted_by`) REFERENCES `sys_users` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Approval requests for various actions';

	-- Approval Decisions
	CREATE TABLE IF NOT EXISTS `tt_approval_decisions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `approval_request_id` INT UNSIGNED NOT NULL,
    `level_number` TINYINT UNSIGNED NOT NULL,
    `approver_id` INT UNSIGNED NOT NULL,
    `decision` ENUM('APPROVED', 'REJECTED', 'CHANGES_REQUESTED', 'CONDITIONALLY_APPROVED') NOT NULL,
    `comments` TEXT DEFAULT NULL,
    `conditions_json` JSON DEFAULT NULL COMMENT 'Conditions for approval',
    `attachments_json` JSON DEFAULT NULL,
    `decided_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    INDEX `idx_approval_decision_request` (`approval_request_id`),
    INDEX `idx_approval_decision_approver` (`approver_id`),
    CONSTRAINT `fk_approval_decisions_request` FOREIGN KEY (`approval_request_id`) REFERENCES `tt_approval_requests` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_approval_decisions_approver` FOREIGN KEY (`approver_id`) REFERENCES `sys_users` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Decisions made at each approval level';

	-- Approval Notifications
	CREATE TABLE IF NOT EXISTS `tt_approval_notifications` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `approval_request_id` INT UNSIGNED NOT NULL,
    `notification_type` ENUM('REQUEST_CREATED', 'LEVEL_ASSIGNED', 'REMINDER', 'ESCALATED', 'DECISION_MADE', 'COMPLETED') NOT NULL,
    `recipient_id` INT UNSIGNED NOT NULL,
    `sent_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `read_at` TIMESTAMP NULL,
    `notification_channel` ENUM('EMAIL', 'SMS', 'PUSH', 'IN_APP') DEFAULT 'IN_APP',
    `notification_content` TEXT NOT NULL,
    `action_taken` VARCHAR(50) DEFAULT NULL,
    `action_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    INDEX `idx_approval_notification_request` (`approval_request_id`),
    INDEX `idx_approval_notification_recipient` (`recipient_id`, `read_at`),
    CONSTRAINT `fk_approval_notifications_request` FOREIGN KEY (`approval_request_id`) REFERENCES `tt_approval_requests` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_approval_notifications_recipient` FOREIGN KEY (`recipient_id`) REFERENCES `sys_users` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Notifications related to approval workflow';


-- -------------------------------------------------
-- ML PATTERN LEARNING
-- -------------------------------------------------

	-- ML Model Registry
	CREATE TABLE IF NOT EXISTS `tt_ml_models` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `model_code` VARCHAR(50) NOT NULL,
    `model_name` VARCHAR(100) NOT NULL,
    `model_type` ENUM('SUBSTITUTION', 'CONFLICT_PREDICTION', 'WORKLOAD_PREDICTION', 'ACTIVITY_PRIORITY', 'CONSTRAINT_LEARNING') NOT NULL,
    `algorithm` VARCHAR(50) NOT NULL COMMENT 'RandomForest, XGBoost, NeuralNetwork, etc.',
    `version` VARCHAR(20) NOT NULL,
    `model_path` VARCHAR(255) DEFAULT NULL COMMENT 'Path to serialized model',
    `model_metadata` JSON DEFAULT NULL COMMENT 'Model parameters, features, etc.',
    `training_data_start_date` DATE DEFAULT NULL,
    `training_data_end_date` DATE DEFAULT NULL,
    `training_samples` INT UNSIGNED DEFAULT 0,
    `accuracy_score` DECIMAL(5,2) DEFAULT NULL,
    `precision_score` DECIMAL(5,2) DEFAULT NULL,
    `recall_score` DECIMAL(5,2) DEFAULT NULL,
    `f1_score` DECIMAL(5,2) DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 0,
    `is_production` TINYINT(1) DEFAULT 0,
    `trained_by` INT UNSIGNED DEFAULT NULL,
    `trained_at` TIMESTAMP NULL,
    `last_used_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ml_model_code_version` (`model_code`, `version`),
    INDEX `idx_ml_model_type` (`model_type`, `is_active`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Registry of ML models used in the system';

	-- Training Data Sets
	CREATE TABLE IF NOT EXISTS `tt_training_data` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `model_id` INT UNSIGNED NOT NULL,
    `data_type` ENUM('SUBSTITUTION', 'CONFLICT', 'WORKLOAD', 'PRIORITY', 'CONSTRAINT') NOT NULL,
    `data_source` VARCHAR(100) DEFAULT NULL,
    `start_date` DATE NOT NULL,
    `end_date` DATE NOT NULL,
    `record_count` INT UNSIGNED DEFAULT 0,
    `feature_columns_json` JSON DEFAULT NULL,
    `target_column` VARCHAR(50) DEFAULT NULL,
    `data_preprocessing_json` JSON DEFAULT NULL,
    `training_duration_seconds` INT UNSIGNED DEFAULT NULL,
    `validation_score` DECIMAL(5,2) DEFAULT NULL,
    `data_file_path` VARCHAR(255) DEFAULT NULL,
    `is_used` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_training_data_model` (`model_id`),
    INDEX `idx_training_data_dates` (`start_date`, `end_date`),
    CONSTRAINT `fk_training_data_model` FOREIGN KEY (`model_id`) REFERENCES `tt_ml_models` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Training data sets used for ML models';

	-- Feature Importance
	CREATE TABLE IF NOT EXISTS `tt_feature_importances` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `model_id` INT UNSIGNED NOT NULL,
    `feature_name` VARCHAR(100) NOT NULL,
    `importance_score` DECIMAL(10,6) NOT NULL,
    `importance_rank` TINYINT UNSIGNED DEFAULT NULL,
    `feature_type` ENUM('NUMERIC', 'CATEGORICAL', 'BINARY', 'TEXT') DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_feature_importance_model_feature` (`model_id`, `feature_name`),
    INDEX `idx_feature_importance_rank` (`model_id`, `importance_rank`),
    CONSTRAINT `fk_feature_importance_model` FOREIGN KEY (`model_id`) REFERENCES `tt_ml_models` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Feature importance from ML models';

	-- Prediction Log
	CREATE TABLE IF NOT EXISTS `tt_prediction_logs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `model_id` INT UNSIGNED NOT NULL,
    `prediction_type` ENUM('SUBSTITUTION_SUCCESS', 'CONFLICT_PROBABILITY', 'WORKLOAD_FORECAST', 'PRIORITY_SCORE') NOT NULL,
    `input_features_json` JSON NOT NULL,
    `prediction_value` DECIMAL(10,6) DEFAULT NULL,
    `prediction_probability` DECIMAL(5,2) DEFAULT NULL,
    `prediction_class` VARCHAR(50) DEFAULT NULL,
    `confidence_score` DECIMAL(5,2) DEFAULT NULL,
    `actual_outcome` VARCHAR(50) DEFAULT NULL,
    `accuracy` TINYINT(1) DEFAULT NULL COMMENT '1 if prediction matched actual',
    `used_for_training` TINYINT(1) DEFAULT 0,
    `predicted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `actual_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_prediction_log_model` (`model_id`, `prediction_type`),
    INDEX `idx_prediction_log_dates` (`predicted_at`, `actual_at`),
    CONSTRAINT `fk_prediction_logs_model` FOREIGN KEY (`model_id`) REFERENCES `tt_ml_models` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Log of predictions made by ML models';

	-- Pattern Recognition Results
	CREATE TABLE IF NOT EXISTS `tt_pattern_results` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `model_id` INT UNSIGNED NOT NULL,
    `pattern_type` ENUM('SUBSTITUTION_PATTERN', 'CONFLICT_PATTERN', 'WORKLOAD_PATTERN', 'ABSENCE_PATTERN') NOT NULL,
    `pattern_name` VARCHAR(100) NOT NULL,
    `pattern_description` TEXT DEFAULT NULL,
    `pattern_conditions_json` JSON NOT NULL,
    `pattern_outcome_json` JSON NOT NULL,
    `support_count` INT UNSIGNED DEFAULT 0,
    `confidence` DECIMAL(5,2) DEFAULT NULL,
    `lift` DECIMAL(8,4) DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_pattern_result_model` (`model_id`, `pattern_type`),
    INDEX `idx_pattern_result_confidence` (`confidence`, `support_count`),
    CONSTRAINT `fk_pattern_results_model` FOREIGN KEY (`model_id`) REFERENCES `tt_ml_models` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Discovered patterns from ML analysis';


-- -------------------------------------------------
-- IMPACT ANALYSIS
-- -------------------------------------------------

	-- Impact Analysis Sessions
	CREATE TABLE IF NOT EXISTS `tt_impact_analysis_sessions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `timetable_id` INT UNSIGNED NOT NULL,
    `analysis_type` ENUM('PRE_CHANGE', 'POST_CHANGE', 'WHAT_IF', 'BULK_UPDATE') NOT NULL,
    `change_description` TEXT DEFAULT NULL,
    `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `completed_at` TIMESTAMP NULL,
    `status` ENUM('RUNNING', 'COMPLETED', 'FAILED') DEFAULT 'RUNNING',
    `overall_impact_score` DECIMAL(5,2) DEFAULT NULL COMMENT '0-100, higher means more impact',
    `risk_level` ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') DEFAULT NULL,
    `recommendation` ENUM('PROCEED', 'CAUTION', 'BLOCK', 'ALTERNATIVE_SUGGESTED') DEFAULT NULL,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_impact_analysis_session_uuid` (`uuid`),
    INDEX `idx_impact_analysis_session_timetable` (`timetable_id`),
    CONSTRAINT `fk_impact_analysis_sessions_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_impact_analysis_sessions_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Sessions for impact analysis of changes';

	-- Impact Analysis Details
	CREATE TABLE IF NOT EXISTS `tt_impact_analysis_details` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `analysis_session_id` INT UNSIGNED NOT NULL,
    `impact_category` ENUM('TEACHER', 'CLASS', 'ROOM', 'CONSTRAINT', 'WORKLOAD', 'STUDENT', 'RESOURCE') NOT NULL,
    `impact_type` VARCHAR(50) NOT NULL,
    `target_id` INT UNSIGNED DEFAULT NULL,
    `target_name` VARCHAR(200) DEFAULT NULL,
    `before_value` JSON DEFAULT NULL,
    `after_value` JSON DEFAULT NULL,
    `delta` DECIMAL(10,4) DEFAULT NULL,
    `delta_percentage` DECIMAL(7,2) DEFAULT NULL,
    `impact_severity` ENUM('POSITIVE', 'NEUTRAL', 'NEGATIVE', 'CRITICAL') DEFAULT 'NEUTRAL',
    `impact_description` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    INDEX `idx_impact_analysis_detail_session` (`analysis_session_id`),
    INDEX `idx_impact_analysis_detail_target` (`impact_category`, `target_id`),
    CONSTRAINT `fk_impact_analysis_details_session` FOREIGN KEY (`analysis_session_id`) REFERENCES `tt_impact_analysis_sessions` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Detailed impact analysis results';

	-- What-If Scenarios
	CREATE TABLE IF NOT EXISTS `tt_what_if_scenarios` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `timetable_id` INT UNSIGNED NOT NULL,
    `scenario_name` VARCHAR(100) NOT NULL,
    `scenario_description` TEXT DEFAULT NULL,
    `scenario_type` ENUM('TEACHER_CHANGE', 'ROOM_CHANGE', 'CONSTRAINT_RELAX', 'WORKLOAD_ADJUST', 'CUSTOM') NOT NULL,
    `changes_json` JSON NOT NULL COMMENT 'Proposed changes',
    `analysis_session_id` INT UNSIGNED DEFAULT NULL,
    `is_simulated` TINYINT(1) DEFAULT 1,
    `is_applied` TINYINT(1) DEFAULT 0,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_what_if_scenario_uuid` (`uuid`),
    INDEX `idx_what_if_scenario_timetable` (`timetable_id`),
    CONSTRAINT `fk_what_if_scenarios_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_what_if_scenarios_analysis` FOREIGN KEY (`analysis_session_id`) REFERENCES `tt_impact_analysis_sessions` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_what_if_scenarios_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='What-if scenarios for testing changes';


-- -------------------------------------------------
-- BATCH OPERATIONS
-- -------------------------------------------------

	-- Batch Operation Sessions
	CREATE TABLE IF NOT EXISTS `tt_batch_operations` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `timetable_id` INT UNSIGNED NOT NULL,
    `operation_type` ENUM('BULK_SWAP', 'BULK_MOVE', 'BULK_SUBSTITUTE', 'BULK_LOCK', 'BULK_UNLOCK', 'BULK_UPDATE') NOT NULL,
    `operation_name` VARCHAR(100) NOT NULL,
    `operation_description` TEXT DEFAULT NULL,
    `selection_criteria_json` JSON NOT NULL COMMENT 'Criteria for selecting cells',
    `target_changes_json` JSON NOT NULL COMMENT 'Changes to apply',
    `preview_count` INT UNSIGNED DEFAULT 0,
    `affected_count` INT UNSIGNED DEFAULT 0,
    `success_count` INT UNSIGNED DEFAULT 0,
    `failure_count` INT UNSIGNED DEFAULT 0,
    `status` ENUM('DRAFT', 'PREVIEWED', 'CONFIRMED', 'RUNNING', 'COMPLETED', 'FAILED', 'ROLLED_BACK') DEFAULT 'DRAFT',
    `started_at` TIMESTAMP NULL,
    `completed_at` TIMESTAMP NULL,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_batch_operation_uuid` (`uuid`),
    INDEX `idx_batch_operation_timetable` (`timetable_id`, `status`),
    CONSTRAINT `fk_batch_operations_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_batch_operations_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Batch operations on timetable';

	-- Batch Operation Items
	CREATE TABLE IF NOT EXISTS `tt_batch_operation_items` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `batch_operation_id` INT UNSIGNED NOT NULL,
    `cell_id` INT UNSIGNED NOT NULL,
    `original_state_json` JSON NOT NULL,
    `proposed_state_json` JSON NOT NULL,
    `validation_status` ENUM('PENDING', 'VALID', 'INVALID', 'WARNING') DEFAULT 'PENDING',
    `validation_message` TEXT DEFAULT NULL,
    `execution_status` ENUM('PENDING', 'SUCCESS', 'FAILED', 'SKIPPED') DEFAULT 'PENDING',
    `error_message` TEXT DEFAULT NULL,
    `executed_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    INDEX `idx_batch_operation_item_batch` (`batch_operation_id`),
    INDEX `idx_batch_operation_item_cell` (`cell_id`),
    INDEX `idx_batch_operation_item_status` (`execution_status`),
    CONSTRAINT `fk_batch_operations_items_batch` FOREIGN KEY (`batch_operation_id`) REFERENCES `tt_batch_operations` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_batch_operations_items_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cells` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Individual items in a batch operation';


-- -------------------------------------------------
-- RE-VALIDATION TRIGGER
-- -------------------------------------------------

	-- Re-validation Triggers
	CREATE TABLE IF NOT EXISTS `tt_revalidation_triggers` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `trigger_type` ENUM('MANUAL_CHANGE', 'BATCH_OPERATION', 'SUBSTITUTION', 'CONSTRAINT_CHANGE', 'SCHEDULED', 'THRESHOLD_CROSSED') NOT NULL,
    `trigger_source` VARCHAR(50) NOT NULL COMMENT 'Table or process that triggered',
    `source_id` INT UNSIGNED DEFAULT NULL,
    `triggered_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `priority` ENUM('IMMEDIATE', 'HIGH', 'MEDIUM', 'LOW') DEFAULT 'MEDIUM',
    `status` ENUM('PENDING', 'PROCESSING', 'COMPLETED', 'SKIPPED', 'FAILED') DEFAULT 'PENDING',
    `validation_session_id` INT UNSIGNED DEFAULT NULL,
    `processed_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    INDEX `idx_revalidation_trigger_status` (`status`, `priority`),
    INDEX `idx_revalidation_trigger_source` (`trigger_source`, `source_id`),
    CONSTRAINT `fk_revalidation_triggers_validation` FOREIGN KEY (`validation_session_id`) REFERENCES `tt_validation_sessions` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Triggers for automatic re-validation';

	-- Re-validation Schedule
	CREATE TABLE IF NOT EXISTS `tt_revalidation_schedules` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `timetable_id` INT UNSIGNED NOT NULL,
    `schedule_type` ENUM('PERIODIC', 'THRESHOLD_BASED', 'EVENT_BASED') NOT NULL,
    `frequency_minutes` INT UNSIGNED DEFAULT NULL,
    `threshold_critical` DECIMAL(5,2) DEFAULT NULL,
    `threshold_warning` DECIMAL(5,2) DEFAULT NULL,
    `last_run_at` TIMESTAMP NULL,
    `next_run_at` TIMESTAMP NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    INDEX `idx_revalidation_schedule_next` (`next_run_at`, `is_active`),
    CONSTRAINT `fk_revalidation_schedules_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Scheduled re-validation jobs';


-- -------------------------------------------------
-- VERSION COMPARISON
-- -------------------------------------------------

	-- Version Comparison Sessions
	CREATE TABLE IF NOT EXISTS `tt_version_comparisons` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `timetable_id` INT UNSIGNED NOT NULL,
    `version_from` SMALLINT UNSIGNED NOT NULL,
    `version_to` SMALLINT UNSIGNED NOT NULL,
    `comparison_type` ENUM('SIDE_BY_SIDE', 'DIFF_ONLY', 'METRICS_ONLY', 'FULL') DEFAULT 'DIFF_ONLY',
    `comparison_summary_json` JSON DEFAULT NULL,
    `total_changes` INT UNSIGNED DEFAULT 0,
    `major_changes` INT UNSIGNED DEFAULT 0,
    `minor_changes` INT UNSIGNED DEFAULT 0,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_version_comparison_uuid` (`uuid`),
    INDEX `idx_version_comparison_timetable` (`timetable_id`),
    CONSTRAINT `fk_version_comparisons_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_version_comparisons_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Version comparison sessions';

	-- Version Comparison Details
	CREATE TABLE IF NOT EXISTS `tt_version_comparison_details` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `comparison_id` INT UNSIGNED NOT NULL,
    `change_type` ENUM('ADDED', 'REMOVED', 'MODIFIED', 'MOVED', 'UNCHANGED') NOT NULL,
    `entity_type` ENUM('CELL', 'ACTIVITY', 'TEACHER_ASSIGNMENT', 'ROOM_ASSIGNMENT') NOT NULL,
    `entity_id` INT UNSIGNED DEFAULT NULL,
    `location_from` JSON DEFAULT NULL COMMENT '{day, period}',
    `location_to` JSON DEFAULT NULL,
    `value_from` JSON DEFAULT NULL,
    `value_to` JSON DEFAULT NULL,
    `change_impact` ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') DEFAULT 'LOW',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    INDEX `idx_version_comparison_detail_comparison` (`comparison_id`),
    INDEX `idx_version_comparison_detail_type` (`change_type`, `entity_type`),
    CONSTRAINT `fk_version_comparisons_details_comparison` FOREIGN KEY (`comparison_id`) REFERENCES `tt_version_comparisons` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Detailed changes between versions';






-- SEED DATA FOR CONSTRAINT TABLES
-- -------------------------------

-- Seed tt_constraint_categories
INSERT INTO `tt_constraint_categories` (`code`, `name`, `ordinal`) VALUES
('TEACHER', 'Teacher Constraints', 1),
('CLASS', 'Class Constraints', 2),
('ACTIVITY', 'Activity Constraints', 3),
('ROOM', 'Room Constraints', 4),
('STUDENT', 'Student Group Constraints', 5),
('GLOBAL', 'Global Constraints', 6);

-- Seed tt_constraint_scopes
INSERT INTO `tt_constraint_scopes` (`code`, `name`, `target_type_required`, `target_id_required`) VALUES
('GLOBAL', 'Global', 0, 0),
('INDIVIDUAL', 'Individual', 1, 1),
('GROUP', 'Group', 1, 0),
('PAIR', 'Pair', 1, 0);

-- Seed tt_constraint_target_types
INSERT INTO `tt_constraint_target_types` (`code`, `name`, `table_name`) VALUES
('TEACHER', 'Teacher', 'sch_teachers'),
('CLASS', 'Class', 'sch_classes'),
('SECTION', 'Section', 'sch_sections'),
('CLASS_SECTION', 'Class & Section', 'sch_class_section_jnt'),
('SUBJECT', 'Subject', 'sch_subjects'),
('STUDY_FORMAT', 'Study Format', 'sch_study_formats'),
('SUBJECT_STUDY_FORMAT', 'Subject Study Format', 'sch_subject_study_format_jnt'),
('ACTIVITY', 'Activity', 'tt_activity'),
('ROOM', 'Room', 'sch_rooms'),
('ROOM_TYPE', 'Room Type', 'sch_rooms_type'),
('BUILDING', 'Building', 'sch_buildings');

-- Seed tt_constraint_types (sample - full list from A2)
INSERT INTO `tt_constraint_types` 
(`code`, `name`, `category_id`, `scope_id`, `constraint_level`, `default_weight`, 
 `parameter_schema`, `applicable_target_types`) VALUES
('TEACHER_MAX_DAILY', 'Teacher Maximum Daily Periods', 
 (SELECT id FROM tt_constraint_categories WHERE code='TEACHER'),
 (SELECT id FROM tt_constraint_scopes WHERE code='INDIVIDUAL'),
 'HARD', 100,
 '{"max_periods_per_day":{"type":"integer","minimum":1,"maximum":12,"default":8}}',
 '[{"target_type":"TEACHER"}]'),

('TEACHER_MAX_WEEKLY', 'Teacher Maximum Weekly Periods',
 (SELECT id FROM tt_constraint_categories WHERE code='TEACHER'),
 (SELECT id FROM tt_constraint_scopes WHERE code='INDIVIDUAL'),
 'HARD', 100,
 '{"max_periods_per_week":{"type":"integer","minimum":1,"maximum":60,"default":48}}',
 '[{"target_type":"TEACHER"}]'),

('CLASS_MAX_PER_DAY', 'Class Maximum Periods Per Day',
 (SELECT id FROM tt_constraint_categories WHERE code='CLASS'),
 (SELECT id FROM tt_constraint_scopes WHERE code='INDIVIDUAL'),
 'HARD', 100,
 '{"max_periods_per_day":{"type":"integer","minimum":1,"maximum":12,"default":8}}',
 '[{"target_type":"CLASS_SECTION"}]');


-- IMPLEMENTATION SUMMARY
-- Missing Component	          Tables Created	  Key Features
-- ------------------------
-- Validation Phase	          	5 tables					Validation sessions, checks, issues, rules, overrides
-- Optimization Phase						3 tables					Optimization runs, iterations, moves
-- Conflict Resolution					4 tables					Resolution sessions, options, escalation rules, logs
-- Approval Workflow						5 tables					Workflows, levels, requests, decisions, notifications
-- Notification System					4 tables					Templates, queue, logs, user preferences
-- ML Pattern Learning					5 tables					Models, training data, features, predictions, patterns
-- Impact Analysis							3 tables					Analysis sessions, details, what-if scenarios
-- Batch Operations							2 tables					Batch operations, items
-- Re-validation Triggers				2 tables					Triggers, schedules
-- Version Comparison						2 tables					Comparisons, details

-- Total New Tables: 35 tables covering all missing components identified in DELIVERABLE D.
-- =========================================================================
-- 9-SYLLABUS MODULE (slb)
-- =========================================================================

  -- We need to create Master table to capture slb_topic_type
  -- level: 0=Topic, 1=Sub-topic, 2=Mini Topic, 3=Sub-Mini Topic, 4=Micro Topic, 5=Sub-Micro Topic, 6=Nano Topic, 7=Ultra Topic,
  -- This table will be used to Generate slb_topics.code and slb_topics.analytics_code.
  -- User can Not change slb_topics.analytics_code, But he can change slb_topics.code as per their choice.
  -- This Table will be set by PG_Team and will not be available for change to School.
  CREATE TABLE IF NOT EXISTS `slb_topic_level_types` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `level` TINYINT UNSIGNED NOT NULL,              -- e.g., 0=Topic, 1=Sub-topic, 2=Mini Topic, 3=Sub-Mini Topic, 4=Micro Topic, 5=Sub-Micro Topic, 6=Nano Topic, 7=Ultra Topic,
    `code` VARCHAR(3) NOT NULL,                    -- e.g., 'TOP','SUB',`MIN`,`SMT`, `MIC`, `SMT`, `NAN`, `ULT`
    `name` VARCHAR(150) NOT NULL,                   -- e.g., `TOPIC`, `SUB-TOPIC`, `MINI-TOPIC`, `SUB-MINI-TOPIC`, `MICRO-TOPIC`, `SUB-MICRO-TOPIC`, `NANO-TOPIC`, `ULTRA-TOPIC`
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_topic_type_level` (`level`),
    UNIQUE KEY `uq_topic_type_code` (`code`),
    UNIQUE KEY `uq_topic_type_name` (`name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  CREATE TABLE IF NOT EXISTS `slb_lessons` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,                       -- Unique identifier for analytics tracking
    `academic_session_id` INT UNSIGNED NOT NULL, -- FK to sch_org_academic_sessions_jnt
    `class_id` INT UNSIGNED NOT NULL,               -- FK to sch_classes
    `subject_id` INT UNSIGNED NOT NULL,          -- FK to sch_subjects
    `code` VARCHAR(20) NOT NULL,                    -- e.g., '9TH_SCI_L01' (Auto-generated) It will be combination of class code, subject code and lesson code
    `name` VARCHAR(150) NOT NULL,                   -- e.g., 'Chapter 1: Matter in Our Surroundings'
    `short_name` VARCHAR(50) DEFAULT NULL,          -- e.g., 'Matter Around Us' 
    `ordinal` SMALLINT UNSIGNED NOT NULL,           -- Sequence order within subject
    `description` VARCHAR(255) DEFAULT NULL,
    `learning_objectives` JSON DEFAULT NULL,        -- Array of learning objectives e.g. [{"objective": "Objective 1"}, {"objective": "Objective 2"}]
    `prerequisites` JSON DEFAULT NULL,              -- Array of prerequisite lesson IDs e.g. [1, 2, 3]
    `estimated_periods` SMALLINT UNSIGNED DEFAULT NULL,  -- No. of periods to complete the Lesson
    `weightage_in_subject` DECIMAL(5,2) DEFAULT NULL,  -- Weightage in Subject (e.g., 8.5%), it will also show the weightage in final exam.
    `nep_alignment` VARCHAR(100) DEFAULT NULL,      -- NEP 2020 reference code e.g. 'NEP_2020_01'
    `resources_json` JSON DEFAULT NULL,             -- [{type, url, title}] e.g. [{"type": "video", "url": "https://example.com/video.mp4", "title": "Video 1"}, {"type": "pdf", "url": "https://example.com/pdf.pdf", "title": "PDF 1"}]
    `book_chapter_ref` VARCHAR(100) DEFAULT NULL,   -- e.g., 'Chapter 1' or 'Section 1.1' (This will cover the difference between Curriculum(NCERT) and Actual Textbook)
    `scheduled_year_week` INT UNSIGNED DEFAULT NULL, -- e.g., '202401' (YYYYWW)
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_lesson_uuid` (`uuid`),
    UNIQUE KEY `uq_lesson_class_subject_name` (`class_id`, `subject_id`, `name`),
    UNIQUE KEY `uq_lesson_code` (`code`),
    KEY `idx_lesson_class_subject` (`class_id`, `subject_id`),
    KEY `idx_lesson_ordinal` (`ordinal`),
    CONSTRAINT `fk_lesson_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_lesson_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lesson_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- 'scheduled_year_week' is a number in the format 'YYYYWW' e.g. '202401', 202601 (Week 1 of 2026).
  -- we can use YEARWEEK() function to get the year and week from the date (Example: SELECT * FROM sales WHERE YEARWEEK(sale_date) = 202601; retrieves data for the first week of 2026.)

  -- HIERARCHICAL TOPICS & SUB-TOPICS (via parent_id)
  -- -------------------------------------------------------------------------
  -- path format: /1/5/23/145/ (ancestor IDs separated by /)
  -- level: 0=Topic, 1=Sub-topic, 2=Mini Topic, 3=Sub-Mini Topic, 4=Micro Topic, 5=Sub-Micro Topic, 6=Nano Topic, 7=Ultra Topic,
  -- -------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `slb_topics` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,                       -- Unique analytics identifier e.g. '123e4567-e89b-12d3-a456-426614174000'
    `parent_id` INT UNSIGNED DEFAULT NULL,       -- FK to self (NULL for root topics)
    `lesson_id` INT UNSIGNED NOT NULL,           -- FK to slb_lessons
    `class_id` INT UNSIGNED NOT NULL,               -- Denormalized for fast queries
    `subject_id` INT UNSIGNED NOT NULL,          -- Denormalized for fast queries
    -- Materialized Path columns
    `path` VARCHAR(500) NOT NULL,                   -- e.g., '/1/5/23/' (ancestor path) e.g. "/1/5/23/145/" (ancestor IDs separated by /)
    `path_names` VARCHAR(2000) DEFAULT NULL,        -- e.g., 'Algebra > Linear Equations > Solving Methods'
    `level` TINYINT UNSIGNED NOT NULL DEFAULT 0,    -- Depth in hierarchy (0=root)
    -- Core topic information (Use slb_topic_level_types to Generate code)
    `code` VARCHAR(60) NOT NULL,                    -- e.g., '9TH_SCI_L01_TOP01_SUB02_MIN01_SMT02_MIC01_SMT02_NAN01_ULT02'
    `name` VARCHAR(150) NOT NULL,                   -- e.g., 'Topic 1: Linear Equations'
    `short_name` VARCHAR(50) DEFAULT NULL,          -- e.g., 'Linear Equations'
    `ordinal` SMALLINT UNSIGNED NOT NULL,           -- Order within parent
    `description` VARCHAR(255) DEFAULT NULL,        -- e.g., 'Description of Topic 1'
    `weightage_in_lesson` DECIMAL(5,2) DEFAULT NULL,  -- Weightage in lesson (e.g., 8.5%)
    -- Teaching metadata
    `duration_minutes` INT UNSIGNED DEFAULT NULL,   -- Estimated teaching time
    `learning_objectives` JSON DEFAULT NULL,        -- Array of objectives
    `keywords` JSON DEFAULT NULL,                   -- Search keywords array
    `prerequisite_topic_ids` JSON DEFAULT NULL,     -- Dependency tracking
    `base_topic_id` INT UNSIGNED DEFAULT NULL,   -- Primary prerequisite from previous class
    `is_assessable` TINYINT(1) DEFAULT 1,           -- Whether the topic is assessable
    -- Analytics identifiers
    `analytics_code` VARCHAR(60) NOT NULL,          -- Unique code for tracking e.g. '9TH_SCI_L01_TOP01_SUB02_MIN01_SMT02_MIC01_SMT02_NAN01_ULT02'
    `can_use_for_syllabus_status` TINYINT(1) DEFAULT 1,  -- Whether the topic can be used for syllabus status progress
    `release_quiz_on_completion` TINYINT(1) DEFAULT 0, -- Whether the quiz should be released on completion of the topic
    `release_quest_on_completion` TINYINT(1) DEFAULT 0, -- Whether the question should be released on completion of the topic
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_topic_uuid` (`uuid`),
    UNIQUE KEY `uq_topic_analytics_code` (`analytics_code`),
    UNIQUE KEY `uq_topic_code` (`code`),
    UNIQUE KEY `uq_topic_parent_ordinal` (`lesson_id`, `parent_id`, `ordinal`),
    KEY `idx_topic_parent` (`parent_id`),
    KEY `idx_topic_level` (`level`),
    KEY `idx_topic_class_subject` (`class_id`, `subject_id`),
    CONSTRAINT `fk_topic_parent` FOREIGN KEY (`parent_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_topic_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `slb_lessons` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_topic_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_topic_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_topic_base_topic` FOREIGN KEY (`base_topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE SET NULL
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
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `parent_id` INT UNSIGNED DEFAULT NULL,     -- FK to self (NULL for root competencies)
    `code` VARCHAR(60) NOT NULL,                 -- e.g. 'KNOWLEDGE','SKILL','ATTITUDE'
    `name` VARCHAR(150) NOT NULL,                -- e.g. 'Knowledge of Linear Equations'
    `short_name` VARCHAR(50) DEFAULT NULL,       -- e.g. 'Linear Equations'
    `description` VARCHAR(255) DEFAULT NULL,     -- e.g. 'Description of Knowledge of Linear Equations'
    `class_id` INT UNSIGNED DEFAULT NULL,         -- FK to sch_classes.id
    `subject_id` INT UNSIGNED DEFAULT NULL,    -- FK to sch_subjects.id
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
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `topic_id` INT UNSIGNED NOT NULL,
    `competency_id` INT UNSIGNED NOT NULL, -- FK to slb_competencies.id
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

  -- QUESTION TAXONOMIES (NEP / BLOOM etc.) - REFERENCE DATA
  -- -------------------------------------------------------------------------

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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
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
    `class_id` INT UNSIGNED DEFAULT NULL,
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    -- Identity
    `code` VARCHAR(20) NOT NULL,        -- A, B, C, 1st, 2nd
    `name` VARCHAR(100) NOT NULL,       -- Grade A, First Division
    `description` VARCHAR(255),
    -- Type
    `grading_type` ENUM('GRADE','DIVISION') NOT NULL,
    -- Academic band
    `min_percentage` DECIMAL(5,2) NOT NULL,
    `max_percentage` DECIMAL(5,2) NOT NULL,
    -- Board & compliance
    `board_code` VARCHAR(50),           -- CBSE, ICSE, STATE
    `academic_session_id` INT UNSIGNED NULL,
    -- UX
    `display_order` SMALLINT UNSIGNED DEFAULT 1,
    `color_code` VARCHAR(10),
    -- Scope
    `scope` ENUM('SCHOOL','BOARD','CLASS') DEFAULT 'SCHOOL',
    `class_id` INT UNSIGNED DEFAULT NULL,
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

  CREATE TABLE IF NOT EXISTS `slb_syllabus_schedule` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_session_id` INT UNSIGNED NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,           -- FK to sch_classes.id. NULL = applies to all classes
    `section_id` INT UNSIGNED DEFAULT NULL,       -- FK to sch_sections.id. NULL = applies to all sections
    `subject_id` INT UNSIGNED NOT NULL,       -- FK to sch_subjects.id
    `topic_id` INT UNSIGNED NOT NULL,         -- FK to slb_topics.id
    `scheduled_start_date` DATE NOT NULL,
    `scheduled_end_date` DATE NOT NULL,
    `assigned_teacher_id` INT UNSIGNED DEFAULT NULL,   -- FK to sch_teachers.id (who assigned to teach this topic)
    `taught_by_teacher_id` INT UNSIGNED DEFAULT NULL,   -- FK to sch_teachers.id (who Actually taught this topic)
    `planned_periods` SMALLINT UNSIGNED DEFAULT NULL,  -- Number of periods planned for this topic
    `priority` ENUM('HIGH','MEDIUM','LOW') DEFAULT 'MEDIUM',
    `notes` VARCHAR(500) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_sylsched_dates` (`scheduled_start_date`, `scheduled_end_date`),
    KEY `idx_sylsched_class_subject` (`class_id`, `subject_id`),
    CONSTRAINT `fk_sylsched_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sylsched_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sylsched_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sylsched_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sylsched_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sylsched_teacher` FOREIGN KEY (`assigned_teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===========================================================================
-- 10-Question Bank Module (qns)
-- ===========================================================================

  CREATE TABLE IF NOT EXISTS `qns_questions_bank` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,                 -- Unique identifier for tracking ("INSERT INTO slb_questions_bank (uuid) VALUES (UUID_TO_BIN(UUID()))")
    `class_id` INT UNSIGNED NOT NULL,       --  fk -> sch_classes.id optional denormalized FK
    `subject_id` INT UNSIGNED NOT NULL,  --  fk -> sch_subjects.id optional denormalized FK
    `lesson_id` INT UNSIGNED NOT NULL,      --  fk -> slb_lessons.id optional denormalized FK
    `topic_id` INT UNSIGNED NOT NULL,    -- FK -> sch_topics.id (can be root topic or sub-topic depending on level)
    `competency_id` INT UNSIGNED NOT NULL, -- FK to slb_competencies.id
    -- Question Text
    `ques_title` VARCHAR(255) NOT NULL,       -- title of the question (For System use)
    `ques_title_display` TINYINT(1) NOT NULL DEFAULT 0,    -- display title? (1=Yes, 0=No)
    `question_content` TEXT NOT NULL,         -- header of the question (For User Display)
    `content_format` ENUM('TEXT','HTML','MARKDOWN','LATEX','JSON') NOT NULL DEFAULT 'TEXT', -- format of the question content
    `teacher_explanation` TEXT DEFAULT NULL,      -- teacher explanation (For User Display)
    -- Question Type & Taxonomy
    `bloom_id` INT UNSIGNED NOT NULL,       -- fk -> slb_bloom_taxonomy.id (Taxonomy)
    `cognitive_skill_id` INT UNSIGNED NOT NULL, -- fk -> slb_cognitive_skill.id (Taxonomy)
    `ques_type_specificity_id` INT UNSIGNED NOT NULL, -- fk -> slb_ques_type_specificity.id (Taxonomy)
    `complexity_level_id` INT UNSIGNED NOT NULL,  -- fk -> slb_complexity_level.id (Taxonomy)
    `question_type_id` INT UNSIGNED NOT NULL,         -- fk -> slb_question_types.id (Question Type)
    -- Question Time to solve & Tags
    `expected_time_to_answer_seconds` INT UNSIGNED DEFAULT NULL, -- Expected time required to answer by students
    `marks` DECIMAL(5,2) DEFAULT 1.00,
    `negative_marks` DECIMAL(5,2) DEFAULT 0.00,
    -- Question Audit & Versioning
    -- `ques_reviewed` TINYINT(1) NOT NULL DEFAULT 0,              -- True if this question is reviewed
    -- `ques_reviewed_by` INT UNSIGNED DEFAULT NULL,            --  fk -> sch_users.id (if reviewed by teacher)
    -- `ques_reviewed_at` TIMESTAMP NULL DEFAULT NULL,
    -- `ques_reviewed_status` ENUM('PENDING','APPROVED','REJECTED') DEFAULT 'PENDING',
    `current_version` TINYINT UNSIGNED NOT NULL DEFAULT 1,       -- version of the question (for history) 
    -- Question Usage
    `for_quiz` TINYINT(1) NOT NULL DEFAULT 1,        -- True if this question is for quiz
    `for_assessment` TINYINT(1) NOT NULL DEFAULT 0,  -- True if this question is for assessment
    `for_exam` TINYINT(1) NOT NULL DEFAULT 0,        -- True if this question is for exam
    `for_offline_exam` TINYINT(1) NOT NULL DEFAULT 0, -- True if this question is for offline exam
    -- Question Ownership
    `ques_owner` ENUM('PrimeGurukul','School') NOT NULL DEFAULT 'PrimeGurukul',
    `created_by_AI` TINYINT(1) DEFAULT 0,            -- True if this question is created by AI
    `created_by` INT UNSIGNED DEFAULT NULL,       -- fk -> sch_users.id or teachers.id. If created by AI then this will be NULL
    `is_school_specific` TINYINT(1) DEFAULT 0,       -- True if this question is school-specific
    -- QUESTIONS AVAILABILITY
    `availability` ENUM('GLOBAL','SCHOOL_ONLY','CLASS_ONLY','SECTION_ONLY','ENTITY_ONLY','STUDENT_ONLY') DEFAULT 'GLOBAL',  -- visibility of the question
    `selected_entity_group_id` INT UNSIGNED DEFAULT NULL,  -- fk -> slb_entity_groups.id (if selected availability is 'ENTITY_ONLY')
    `selected_section_id` INT UNSIGNED DEFAULT NULL,       -- fk -> sch_sections.id (if selected availability is 'SECTION_ONLY')
    `selected_student_id` INT UNSIGNED DEFAULT NULL,       -- fk -> sch_students.id (if selected availability is 'STUDENT_ONLY')
    -- QUESTION SOURCE & REFERENCE
    `book_id` INT UNSIGNED DEFAULT NULL,         -- book id (FK -> slb_books.id)
    `book_page_ref` VARCHAR(50) DEFAULT NULL,       -- book page reference (e.g., "Chapter 3, Page 12")
    `external_ref` VARCHAR(100) DEFAULT NULL,       -- for mapping to external banks
    `reference_material` TEXT DEFAULT NULL,         -- e.g., book section, web link
    -- Status
    `status` ENUM('DRAFT','IN_REVIEW','APPROVED','REJECTED','PUBLISHED','ARCHIVED') NOT NULL DEFAULT 'DRAFT',
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `idx_ques_uuid` (`uuid`),
    KEY `idx_ques_topic` (`topic_id`),
    KEY `idx_ques_competency` (`competency_id`),
    KEY `idx_ques_class_subject` (`class_id`,`subject_id`),
    KEY `idx_ques_complexity_bloom` (`complexity_level_id`,`bloom_id`),
    KEY `idx_ques_active` (`is_active`),
    KEY `idx_ques_book` (`book_id`),
    KEY `idx_ques_visibility` (`visibility`),
    CONSTRAINT `fk_ques_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `slb_lessons` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_competency` FOREIGN KEY (`competency_id`) REFERENCES `slb_competencies` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_bloom` FOREIGN KEY (`bloom_id`) REFERENCES `slb_bloom_taxonomy` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_cog` FOREIGN KEY (`cognitive_skill_id`) REFERENCES `slb_cognitive_skill` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_timeSpec` FOREIGN KEY (`ques_type_specificity_id`) REFERENCES `slb_ques_type_specificity` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_complexity` FOREIGN KEY (`complexity_level_id`) REFERENCES `slb_complexity_level` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_type` FOREIGN KEY (`question_type_id`) REFERENCES `slb_question_types` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_ques_reviewed_by` FOREIGN KEY (`ques_reviewed_by`) REFERENCES `sch_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_created_by` FOREIGN KEY (`created_by`) REFERENCES `sch_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_selected_entity_group` FOREIGN KEY (`selected_entity_group_id`) REFERENCES `slb_entity_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_selected_section` FOREIGN KEY (`selected_section_id`) REFERENCES `sch_sections` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_selected_student` FOREIGN KEY (`selected_student_id`) REFERENCES `sch_students` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_book` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- 1. Questions can have 2 or more options as an answer
  -- To Insert UUID into BINARY(16) use: INSERT INTO slb_questions_bank (uuid) VALUES (UUID_TO_BIN(UUID()));
  -- To Update UUID into BINARY(16) use: UPDATE slb_questions_bank SET uuid = UUID_TO_BIN(UUID());
  -- To Read UUID back as string from BINARY(16) use: SELECT BIN_TO_UUID(uuid) FROM slb_questions_bank;

  CREATE TABLE IF NOT EXISTS `qns_question_options` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `question_bank_id` INT UNSIGNED NOT NULL,
    `ordinal` SMALLINT UNSIGNED DEFAULT NULL,    -- ordinal position of this option
    `option_text` TEXT NOT NULL,                 -- text of the option
    `is_correct` TINYINT(1) NOT NULL DEFAULT 0,  -- whether this option is correct
    `Explanation` TEXT DEFAULT NULL,             -- detailed explanation for this option (Why this option is correct / incorrect)
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_opt_question` (`question_bank_id`),
    CONSTRAINT `fk_opt_question` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `qns_question_media_jnt` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `question_bank_id` INT UNSIGNED NOT NULL,          -- fk to qns_questions_bank.id
    `question_option_id` INT UNSIGNED DEFAULT NULL,    -- fk to qns_question_options.id
    `media_purpose` ENUM('QUESTION','OPTION','QUES_EXPLANATION','OPT_EXPLANATION','RECOMMENDATION') DEFAULT 'QUESTION',
    `media_id` INT UNSIGNED NOT NULL,                   -- fk to qns_media_store.id
    `media_type` ENUM('IMAGE','AUDIO','VIDEO','ATTACHMENT') DEFAULT 'IMAGE',        -- e.g., 'IMAGE','AUDIO','VIDEO','ATTACHMENT'
    `ordinal` SMALLINT UNSIGNED DEFAULT 1,                 -- ordinal position of this media
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_qmedia_question` (`question_bank_id`),
    KEY `idx_qmedia_option` (`question_option_id`),
    CONSTRAINT `fk_qmedia_question` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qmedia_option` FOREIGN KEY (`question_option_id`) REFERENCES `qns_question_options` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qmedia_media` FOREIGN KEY (`media_id`) REFERENCES `qns_media_store` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `qns_question_tags` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `short_name` VARCHAR(100) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_qtag_short` (`short_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Laravel Morph Relationship
  CREATE TABLE IF NOT EXISTS `qns_question_questiontag_jnt` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `question_bank_id` INT UNSIGNED NOT NULL,
    `tag_id` INT UNSIGNED NOT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_qtag_q_t` (`question_bank_id`,`tag_id`),
    CONSTRAINT `fk_qtag_q` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qtag_tag` FOREIGN KEY (`tag_id`) REFERENCES `qns_question_tags` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- In this Table data will be entered on Modification only. No CRUD required
  CREATE TABLE IF NOT EXISTS `qns_question_versions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `question_bank_id` INT UNSIGNED NOT NULL,
    `version` INT UNSIGNED NOT NULL,
    `data` JSON NOT NULL,                       -- full snapshot of question (Question_content, options, metadata)
    `version_created_by` INT UNSIGNED DEFAULT NULL,
    `change_reason` VARCHAR(255) DEFAULT NULL,  -- why was this version modified?
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_qver_q_v` (`question_bank_id`,`version`),
    CONSTRAINT `fk_qver_q` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `qns_media_store` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `uuid` BINARY(16) NOT NULL,
    `owner_type` ENUM('QUESTION','OPTION','EXPLANATION','RECOMMENDATION') NOT NULL,
    `owner_id` INT UNSIGNED NOT NULL,
    `media_type` ENUM('IMAGE','AUDIO','VIDEO','PDF') NOT NULL,
    `file_name` VARCHAR(255),
    `file_path` VARCHAR(255),
    `mime_type` VARCHAR(100),
    `disk` VARCHAR(50) DEFAULT NULL,     -- storage disk
    `size` INT UNSIGNED DEFAULT NULL, -- file size in bytes
    `checksum` CHAR(64) DEFAULT NULL,    -- file checksum
    `ordinal` SMALLINT UNSIGNED DEFAULT 1,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP DEFAULT NULL,
    UNIQUE KEY `uq_media_uuid` (`uuid`),
    KEY `idx_owner` (`owner_type`, `owner_id`)
  );

  CREATE TABLE IF NOT EXISTS `qns_question_topic_jnt` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `question_bank_id` INT UNSIGNED NOT NULL,
    `topic_id` INT UNSIGNED NOT NULL,
    `weightage` DECIMAL(5,2) DEFAULT 100.00,  -- weightage of question in topic
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP DEFAULT NULL,
    UNIQUE KEY `uq_qt_q_t` (`question_bank_id`,`topic_id`),
    CONSTRAINT `fk_qt_question` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qt_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Required a backend Service to calculate the statistics
  -- Display Only
  CREATE TABLE IF NOT EXISTS `qns_question_statistics` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `question_bank_id` INT UNSIGNED NOT NULL,
    `difficulty_index` DECIMAL(5,2),       -- % students answered correctly
    `discrimination_index` DECIMAL(5,2),   -- Top vs bottom performer delta
    `guessing_factor` DECIMAL(5,2),        -- MCQ only
    `min_time_taken_seconds` INT UNSIGNED DEFAULT NULL,  -- time taken by topper to answer the question
    `max_time_taken_seconds` INT UNSIGNED DEFAULT NULL, -- average time taken to answer by students
    `avg_time_taken_seconds` INT UNSIGNED,
    `total_attempts` INT UNSIGNED DEFAULT 0,
    `last_computed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP DEFAULT NULL,
    UNIQUE KEY `uq_qstats_q` (`question_bank_id`),
    CONSTRAINT `fk_qstats_question` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `qns_question_performance_category_jnt` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `question_bank_id` INT UNSIGNED NOT NULL,
    `performance_category_id` INT UNSIGNED NOT NULL,  -- FK to slb_performance_categories.id
    `recommendation_type` INT UNSIGNED NOT NULL,  -- FK to sys_dropdowns table e.g. 'REVISION','PRACTICE','CHALLENGE'
    `priority` SMALLINT UNSIGNED DEFAULT 1,  -- priority of the question in the performance category
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_qrec_q_p` (`question_bank_id`, `performance_category_id`),
    CONSTRAINT `fk_qrec_question` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qrec_perf` FOREIGN KEY (`performance_category_id`) REFERENCES `slb_performance_categories` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- conditions:
  -- This directly powers Personalized learning paths, AI-Teacher module, LXP integration
  -- This table will map questions to performance categories. using it we can recommend questions to students based on their performance.

  -- Display Only
  CREATE TABLE IF NOT EXISTS `qns_question_usage_log` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `question_bank_id` INT UNSIGNED NOT NULL,    -- FK to qns_questions_bank
    `question_usage_type` INT UNSIGNED NOT NULL, -- FK to qns_question_usage_type.id
    `context_id` INT UNSIGNED NOT NULL,    -- quiz_id, assessment_id, exam_id - FK to sys_dropdowns table
    `used_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP DEFAULT NULL,
    CONSTRAINT `fk_qusage_question` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qusage_usage_context` FOREIGN KEY (`usage_context`) REFERENCES `qns_question_usage_type` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -----------------------------------------------------------------------------------------------------------------------
  -- Question Review & Approval Audit
  CREATE TABLE IF NOT EXISTS `qns_question_review_log` (
      `review_log_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `question_id` INT UNSIGNED NOT NULL,  -- FK to qns_questions_bank.id
      `reviewer_id` INT UNSIGNED NOT NULL,  -- FK to users.id
      `review_status_id` INT UNSIGNED NOT NULL,  -- FK to sys_dropdowns.id e.g. 'PENDING','APPROVED','REJECTED'
      `review_comment` TEXT DEFAULT NULL,
      `reviewed_at` DATETIME NOT NULL,
      `is_active` TINYINT(1) DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP DEFAULT NULL,
      INDEX `idx_q_review_question` (question_id),
      INDEX `idx_q_review_status` (review_status_id),
      CONSTRAINT `fk_q_review_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_q_review_reviewer` FOREIGN KEY (`reviewer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_q_review_status` FOREIGN KEY (`review_status_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE CASCADE
  );

  -- Question Usage Type (Quiz / Quest / Exam)
  CREATE TABLE IF NOT EXISTS `qns_question_usage_type` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
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


-- ===========================================================================
-- 11-Recommendation (rec)
-- ===========================================================================
  -- table for "trigger_event" ENUM values
  CREATE TABLE IF NOT EXISTS `rec_trigger_events` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `event_name` VARCHAR(50) NOT NULL,  -- ON_ASSESSMENT_RESULT, ON_TOPIC_COMPLETION, ON_ATTENDANCE_LOW, MANUAL_RUN, SCHEDULED_WEEKLY
    `description` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_recTriggerEvent_name` (`event_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

  -- TAB-2 : Recommendation Rules

  -- table for "recommendation_mode" ENUM values
  CREATE TABLE IF NOT EXISTS `rec_recommendation_modes` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `mode_name` VARCHAR(50) NOT NULL,  -- SPECIFIC_MATERIAL, SPECIFIC_BUNDLE, DYNAMIC_BY_TOPIC, DYNAMIC_BY_COMPETENCY
    `description` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_recRecommendationMode_name` (`mode_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

  -- TAB-3 : Recommendation Rules

  -- table for "dynamic_material_type" ENUM values
  CREATE TABLE IF NOT EXISTS `rec_dynamic_material_types` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `type_name` VARCHAR(50) NOT NULL,  -- ANY_BEST_FIT, VIDEO, QUIZ, PDF
    `description` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_recDynamicMaterialType_name` (`type_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

  -- TAB-4 : Recommendation Rules

  -- table for "dynamic_purpose" ENUM values
  CREATE TABLE IF NOT EXISTS `rec_dynamic_purposes` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `purpose_name` VARCHAR(50) NOT NULL,  -- REMEDIAL, ENRICHMENT, PRACTICE
    `description` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_recDynamicPurpose_name` (`purpose_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

  -- TAB-5 : Recommendation Rules

  -- table for "assessment_type" ENUM values
  CREATE TABLE IF NOT EXISTS `rec_assessment_types` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `type_name` VARCHAR(50) NOT NULL,  -- ALL, QUIZ, WEEKLY_TEST, TERM_EXAM, FINAL_EXAM
    `description` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_recAssessmentType_name` (`type_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 


  -- ========================================================================================================
  -- SCREEN - 2 : Tab-1 (Recommendation Materials)
  -- ========================================================================================================

  -- 1. Master table for Recommendation Materials (Content Bank)
  CREATE TABLE IF NOT EXISTS `rec_recommendation_materials` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT DEFAULT NULL,
    -- Content Classification
    `material_type` INT UNSIGNED DEFAULT NULL,    -- fk to sys_dropdown_table (e.g. 'TEXT','VIDEO','PDF','AUDIO','QUIZ','ASSIGNMENT','LINK','INTERACTIVE')
    `purpose` INT UNSIGNED DEFAULT NULL,          -- fk to sys_dropdown_table (e.g. 'REVISION','PRACTICE','REMEDIAL','ADVANCED','ENRICHMENT','CONCEPT_BUILDING') NOT NULL DEFAULT 'PRACTICE',
    `complexity_level` INT UNSIGNED DEFAULT NULL,  -- fk to slb_complexity_level
    -- Content Source
    `content_source` INT UNSIGNED DEFAULT NULL,    -- fk to sys_dropdown_table (e.g. 'INTERNAL_EDITOR','UPLOADED_FILE','EXTERNAL_LINK','LMS_MODULE','QUESTION_BANK')
    `content_text` LONGTEXT DEFAULT NULL,           -- HTML content for 'TEXT' type or Internal Notes
    `file_url` VARCHAR(500) DEFAULT NULL,           -- Direct URL for 'UPLOADED_FILE' or 'PDF' or 'VIDEO'
    `external_url` VARCHAR(500) DEFAULT NULL,       -- YouTube link, Khan Academy link etc.
    `media_id` INT UNSIGNED DEFAULT NULL,        -- fk to qns_media_store (for stored Media)
    -- Academic Mapping
    `subject_id` INT UNSIGNED DEFAULT NULL,      -- FK to sch_subjects
    `class_id` INT UNSIGNED DEFAULT NULL,           -- FK to sch_classes (Target Class)
    `topic_id` INT UNSIGNED DEFAULT NULL,        -- FK to slb_topics
    `competency_code` VARCHAR(50) DEFAULT NULL,     -- Optional link to Competency Framework
    -- Metadata
    `duration_seconds` INT UNSIGNED DEFAULT NULL,   -- Est. time to consume
    `language_code` VARCHAR(10) DEFAULT 'en',       -- e.g. 'en', 'hi'
    `tags` JSON DEFAULT NULL,                       -- Search tags
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_recMat_school` (`school_id`),
    KEY `idx_recMat_type` (`material_type`),
    KEY `idx_recMat_scope` (`class_id`, `subject_id`, `topic_id`),
    CONSTRAINT `fk_recMat_school` FOREIGN KEY (`school_id`) REFERENCES `sch_organizations` (`id`),
    CONSTRAINT `fk_recMat_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_recMat_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`),
    CONSTRAINT `fk_recMat_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`),
    CONSTRAINT `fk_recMat_content_source` FOREIGN KEY (`content_source`) REFERENCES `sys_dropdown_table` (`id`),
    CONSTRAINT `fk_recMat_material_type` FOREIGN KEY (`material_type`) REFERENCES `sys_dropdown_table` (`id`),
    CONSTRAINT `fk_recMat_purpose` FOREIGN KEY (`purpose`) REFERENCES `sys_dropdown_table` (`id`),
    CONSTRAINT `fk_recMat_complexity_level` FOREIGN KEY (`complexity_level`) REFERENCES `slb_complexity_level` (`id`),
    CONSTRAINT `fk_recMat_media` FOREIGN KEY (`media_id`) REFERENCES `qns_media_store` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ========================================================================================================
  -- SCREEN - 2  : Tab-2 (Recommendation Bundles)
  -- ========================================================================================================

  -- 1. Recommendation Bundles/Collections (e.g. "Week 1 Revision Kit")
  --    Allows grouping multiple materials into one recommendation
  CREATE TABLE IF NOT EXISTS `rec_material_bundles` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_recBundle_school` (`school_id`),
    CONSTRAINT `fk_recBundle_school` FOREIGN KEY (`school_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 2. Junction between Bundle and Materials
  CREATE TABLE IF NOT EXISTS `rec_bundle_materials_jnt` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bundle_id` INT UNSIGNED NOT NULL,
    `material_id` INT UNSIGNED NOT NULL,
    `sequence_order` INT UNSIGNED DEFAULT 1,
    `is_mandatory` TINYINT(1) DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_recBundleMat_rel` (`bundle_id`, `material_id`),
    CONSTRAINT `fk_recBundleMat_bundle` FOREIGN KEY (`bundle_id`) REFERENCES `rec_material_bundles` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_recBundleMat_material` FOREIGN KEY (`material_id`) REFERENCES `rec_recommendation_materials` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ========================================================================================================
  -- SCREEN - 2  : Tab-3 (Recommendation Rules)
  -- ========================================================================================================

  -- 1. Recommendation Rules Engine
  --    Defines logics: WHEN (Trigger) + WHO (Performance) -> WHAT (Recommendation)
  CREATE TABLE IF NOT EXISTS `rec_recommendation_rules` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- Rule Definition
    `name` VARCHAR(150) NOT NULL,                   -- e.g. "Math Remedial for Poor Performers in Algebra"
    `is_automated` TINYINT(1) DEFAULT 1,            -- 1=Run by System Job, 0=Manual Helper Rule
    -- TRIGGERS (When to Apply)
    `trigger_event` INT UNSIGNED NOT NULL,  -- FK to rec_trigger_events
    -- CONDITIONS (The "Switch")
    -- Narrowing Scope
    `class_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_classes
    `subject_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_subjects
    `topic_id` INT UNSIGNED DEFAULT NULL,  -- FK to slb_topics
    -- Performance Criteria
    `performance_category_id` INT UNSIGNED DEFAULT NULL, -- FK to slb_performance_categories (The bucket, e.g. POOR)
    `min_score_pct` DECIMAL(5,2) DEFAULT NULL,      -- Specific override e.g. < 40%
    `max_score_pct` DECIMAL(5,2) DEFAULT NULL,      -- Specific override e.g. > 90%
    -- Assessment Type Filter (Only apply if the result came from this type of exam)
    `assessment_type` INT UNSIGNED DEFAULT NULL,  -- FK to rec_assessment_types
    -- ACTION (What to Recommend)
    `recommendation_mode_id` INT UNSIGNED NOT NULL,  -- FK to rec_recommendation_modes
    `target_material_id` INT UNSIGNED DEFAULT NULL,  -- KF TO rec_recommendation_materials
    `target_bundle_id` INT UNSIGNED DEFAULT NULL,    -- KF TO rec_recommendation_bundles
    `dynamic_material_type_id` INT UNSIGNED DEFAULT NULL,  -- FK to rec_dynamic_material_types
    `dynamic_purpose_id` INT UNSIGNED DEFAULT NULL,  -- FK to rec_dynamic_purposes
    `priority` INT UNSIGNED DEFAULT 10,                 -- Higher priority rules override or appear first
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_recRule_trigger` (`trigger_event`),
    CONSTRAINT `fk_recRule_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_recRule_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_recRule_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_recRule_perfCat` FOREIGN KEY (`performance_category_id`) REFERENCES `slb_performance_categories` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_recRule_targetMat` FOREIGN KEY (`target_material_id`) REFERENCES `rec_recommendation_materials` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_recRule_targetBun` FOREIGN KEY (`target_bundle_id`) REFERENCES `rec_material_bundles` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_recRule_trigger` FOREIGN KEY (`trigger_event_id`) REFERENCES `rec_trigger_events` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_recRule_recMode` FOREIGN KEY (`recommendation_mode_id`) REFERENCES `rec_recommendation_modes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_recRule_dynMatType` FOREIGN KEY (`dynamic_material_type_id`) REFERENCES `rec_dynamic_material_types` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_recRule_dynPurpose` FOREIGN KEY (`dynamic_purpose_id`) REFERENCES `rec_dynamic_purposes` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_recRule_assessmentType` FOREIGN KEY (`assessment_type_id`) REFERENCES `rec_assessment_types` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ========================================================================================================
  -- SCREEN - 2  : Tab-4 (Student Recommendations)
  -- ========================================================================================================

  -- 1. Student Recommendations (The Resulting Assignments)
  --    Refined from v1.1 `rec_student_recommendations`
  CREATE TABLE IF NOT EXISTS `rec_student_recommendations` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,                       -- Unique ID for public access/tracking
    `student_id` INT UNSIGNED NOT NULL,          -- FK to std_students (or users depending on arch. std_students preferred)
    -- Source of Recommendation
    `rule_id` INT UNSIGNED DEFAULT NULL,         -- fk to rec_recommendation_rules. Which rule generated this?
    `triggered_by_result_id` INT UNSIGNED DEFAULT NULL, -- Optional: Link to the Exam Result ID in Exam Module
    `manual_assigned_by` INT UNSIGNED DEFAULT NULL,     -- If manually assigned by Teacher
    -- The Content
    `material_id` INT UNSIGNED DEFAULT NULL,
    `bundle_id` INT UNSIGNED DEFAULT NULL,
    -- Context
    `recommendation_reason` VARCHAR(255) DEFAULT NULL, -- e.g. "Scored Low in Algebra Quiz"
    `priority` ENUM('LOW','MEDIUM','HIGH','CRITICAL') DEFAULT 'MEDIUM',
    `due_date` DATE DEFAULT NULL,
    -- Status Tracking
    `status` ENUM('PENDING','VIEWED','IN_PROGRESS','COMPLETED','SKIPPED','EXPIRED') DEFAULT 'PENDING',
    `assigned_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `first_viewed_at` TIMESTAMP NULL DEFAULT NULL,
    `completed_at` TIMESTAMP NULL DEFAULT NULL,
    -- Outcomes
    `score_achieved` DECIMAL(5,2) DEFAULT NULL,     -- If the recommendation was a Quiz/Practice
    `student_rating` TINYINT UNSIGNED DEFAULT NULL, -- 1-5 Stars
    `student_feedback` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_recStudRec_uuid` (`uuid`),
    KEY `idx_recStud_student` (`student_id`, `status`),
    CONSTRAINT `fk_recStud_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_recStud_rule` FOREIGN KEY (`rule_id`) REFERENCES `rec_recommendation_rules` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_recStud_material` FOREIGN KEY (`material_id`) REFERENCES `rec_recommendation_materials` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_recStud_bundle` FOREIGN KEY (`bundle_id`) REFERENCES `rec_material_bundles` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_recStud_teacher` FOREIGN KEY (`manual_assigned_by`) REFERENCES `sch_teachers` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===========================================================================
-- 12-Syllabus_Books (rec)
-- ===========================================================================
  -- Master table for Books/Publications used across schools
  -- Master table for Books/Publications used across schools
  CREATE TABLE IF NOT EXISTS `bok_books` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,  -- UUID 
    `isbn` VARCHAR(20) DEFAULT NULL,              -- International Standard Book Number
    `title` VARCHAR(100) NOT NULL,
    `subtitle` VARCHAR(255) DEFAULT NULL,
    `description` VARCHAR(512) DEFAULT NULL,
    `edition` VARCHAR(50) DEFAULT NULL,           -- e.g., '5th Edition', 'Revised 2024'
    `publication_year` YEAR DEFAULT NULL,         -- e.g., 2024
    `publisher_name` VARCHAR(150) DEFAULT NULL,   -- e.g., 'NCERT', 'S.Chand', 'Pearson'
    `language` INT UNSIGNED NOT NULL,          -- FK to sys_dropdown_table e.g "English", "Hindi", "Sanskrit"
    `total_pages` INT UNSIGNED DEFAULT NULL,
    `cover_image_media_id` INT UNSIGNED DEFAULT NULL,  -- FK to media_files.id
    `tags` JSON DEFAULT NULL,                     -- Additional search tags
    `is_ncert` TINYINT(1) DEFAULT 0,              -- Flag for NCERT books
    `is_cbse_recommended` TINYINT(1) DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_book_uuid` (`uuid`),
    UNIQUE KEY `uq_book_isbn` (`isbn`),
    KEY `idx_book_title` (`title`),
    KEY `idx_book_publisher` (`publisher_name`),
    KEY `idx_book_year` (`publication_year`),
    CONSTRAINT `fk_book_language` FOREIGN KEY (`language`) REFERENCES `sys_dropdown_table` (`id`),
    CONSTRAINT `fk_book_cover_image_media_id` FOREIGN KEY (`cover_image_media_id`) REFERENCES `media_files` (`id`),
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Authors table (Many-to-Many with Books)
  CREATE TABLE IF NOT EXISTS `bok_book_authors` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(150) NOT NULL,
    `qualification` VARCHAR(200) DEFAULT NULL,
    `bio` TEXT DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_author_name` (`name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction: Book-Author relationship
  CREATE TABLE IF NOT EXISTS `bok_book_author_jnt` (
    `book_id` INT UNSIGNED NOT NULL,
    `author_id` INT UNSIGNED NOT NULL,
    `author_role` ENUM('PRIMARY','CO_AUTHOR','EDITOR','CONTRIBUTOR') DEFAULT 'PRIMARY',
    `ordinal` TINYINT UNSIGNED DEFAULT 1,
    PRIMARY KEY (`book_id`, `author_id`),
    CONSTRAINT `fk_ba_book` FOREIGN KEY (`book_id`) REFERENCES `bok_books` (`id`),
    CONSTRAINT `fk_ba_author` FOREIGN KEY (`author_id`) REFERENCES `bok_book_authors` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Link Books to Class/Subject (which books are used for which class/subject)
  CREATE TABLE IF NOT EXISTS `bok_book_class_subject_jnt` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `book_id` INT UNSIGNED NOT NULL,  -- FK to slb_books.id
    `class_id` INT UNSIGNED NOT NULL,    -- FK to sch_classes.id
    `subject_id` INT UNSIGNED NOT NULL, -- FK to sch_subjects.id
    `academic_session_id` INT UNSIGNED NOT NULL, -- FK to sch_org_academic_sessions_jnt.id
    `is_primary` TINYINT(1) DEFAULT 1,            -- Primary textbook vs reference
    `is_mandatory` TINYINT(1) DEFAULT 1,
    `remarks` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_bcs_book_class_subject_session` (`book_id`, `class_id`, `subject_id`, `academic_session_id`),
    CONSTRAINT `fk_bcs_book` FOREIGN KEY (`book_id`) REFERENCES `bok_books` (`id`),
    CONSTRAINT `fk_bcs_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_bcs_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`),
    CONSTRAINT `fk_bcs_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===========================================================================
-- 13-Student Profile (std)
-- ===========================================================================
    -- Main Student Entity, linked to System User for Login/Auth
    CREATE TABLE IF NOT EXISTS `std_students` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      -- Student Info
      `user_id` INT UNSIGNED NOT NULL,              -- Link to sys_users for login credentials
      `admission_no` VARCHAR(50) NOT NULL,             -- Unique School Admission Number
      `admission_date` DATE NOT NULL,                  -- Date of admission
      -- ID Cards
      `student_qr_code` VARCHAR(20) DEFAULT NULL,      -- For ID Cards (this will be saved as emp_code in sys_users table) 
      `student_id_card_type` ENUM('QR','RFID','NFC','Barcode') NOT NULL DEFAULT 'QR',
      `smart_card_id` VARCHAR(100) DEFAULT NULL,       -- RFID/NFC Tag ID
      -- Identity Documents
      `aadhar_id` VARCHAR(20) DEFAULT NULL,            -- National ID (India)
      `apaar_id` VARCHAR(100) DEFAULT NULL,            -- Academic Bank of Credits ID
      `birth_cert_no` VARCHAR(50) DEFAULT NULL,
      -- Basic Info (Demographics)
      `first_name` VARCHAR(50) NOT NULL,               -- (Combined (First_name+Middle_name+last_name) and saved as `name` in sys_users table (Check Max_Length should not be more than 100))
      `middle_name` VARCHAR(50) DEFAULT NULL,
      `last_name` VARCHAR(50) DEFAULT NULL,              -- (Combined (First_name+Middle_name+last_name) and saved as `name` in sys_users table (Check Max_Length should not be more than 100))
      -- Personal Info
      `gender` ENUM('Male','Female','Transgender','Prefer Not to Say') NOT NULL DEFAULT 'Male',
      `dob` DATE NOT NULL,
      `photo_file_name` VARCHAR(100) DEFAULT NULL,     -- Fk to sys_media (file name to show in UI)
      `media_id` INT UNSIGNED DEFAULT NULL,         -- Optional if using sys_media table
      -- Status
      `current_status_id` INT UNSIGNED NOT NULL,    -- FK to sys_dropdown_table (Active, Left, Suspended, Alumni, Withdrawn)
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      -- Meta
      `note` VARCHAR(255) DEFAULT NULL,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      UNIQUE KEY `uq_std_students_admissionNo` (`admission_no`),
      UNIQUE KEY `uq_std_students_userId` (`user_id`),
      UNIQUE KEY `uq_std_students_aadhar` (`aadhar_id`),
      CONSTRAINT `fk_std_students_userId` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    -- Condition:
    -- Short Name - (sys_user.short_name VARCHAR(30)) - This field value will be saved as 'short_name' in 'sys_users' table
    -- Password - (sys_user.password VARCHAR(255)) - The Hashed Value of Password will be saved as 'password' in 'sys_users' table


    -- Extended Personal Profile
    CREATE TABLE IF NOT EXISTS `std_student_profiles` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      -- Student Info
      `student_id` INT UNSIGNED NOT NULL,
      `mobile` VARCHAR(20) DEFAULT NULL,               -- Student/Parent mobile (This will be saved as mobile in sys_users table)
      `email` VARCHAR(150) DEFAULT NULL,               -- Student/Parent email (This will be saved as email in sys_users table)
      -- Social / Category
      `religion` INT UNSIGNED DEFAULT NULL,         -- FK to sys_dropdown_table
      `caste_category` INT UNSIGNED DEFAULT NULL,   -- FK to sys_dropdown_table
      `nationality` INT UNSIGNED DEFAULT NULL,      -- FK to sys_dropdown_table
      `mother_tongue` INT UNSIGNED DEFAULT NULL,    -- FK to sys_dropdown_table
      -- Financial / Banking
      `bank_account_no` VARCHAR(100) DEFAULT NULL,
      `bank_name` VARCHAR(100) DEFAULT NULL,
      `ifsc_code` VARCHAR(50) DEFAULT NULL,
      -- Bank Details
      `bank_branch` VARCHAR(100) DEFAULT NULL,
      `upi_id` VARCHAR(100) DEFAULT NULL,
      `fee_depositor_pan_number` VARCHAR(10) DEFAULT NULL,    -- For tax benefit
      -- RTE / Government Schemes
      `right_to_education` TINYINT(1) NOT NULL DEFAULT 0, -- RTE Quota
      `is_ews` TINYINT(1) NOT NULL DEFAULT 0,             -- Economically Weaker Section
      -- Physical Stats (Latest snapshot, history in Health)
      `height_cm` DECIMAL(5,2) DEFAULT NULL,
      `weight_kg` DECIMAL(5,2) DEFAULT NULL,
      `measurement_date` date DEFAULT NULL,
      -- Additional Info
      `additional_info` json DEFAULT NULL,
    --  `blood_group` ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-') DEFAULT NULL, (Remove this Field, it is already there Health Table)
      -- Meta
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      UNIQUE KEY `uq_std_profiles_studentId` (`student_id`),
      CONSTRAINT `fk_std_profiles_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_std_profiles_religion` FOREIGN KEY (`religion`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_std_profiles_caste_category` FOREIGN KEY (`caste_category`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_std_profiles_nationality` FOREIGN KEY (`nationality`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_std_profiles_mother_tongue` FOREIGN KEY (`mother_tongue`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Student Addresses (1:N)
    CREATE TABLE IF NOT EXISTS `std_student_addresses` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_id` INT UNSIGNED NOT NULL,
      `address_type` ENUM('Permanent','Correspondence','Guardian','Local') NOT NULL DEFAULT 'Correspondence',
      `address` VARCHAR(512) NOT NULL,
      `city_id` INT UNSIGNED NOT NULL,  -- FK to glb_cities
      `pincode` VARCHAR(10) NOT NULL,
      `is_primary` TINYINT(1) DEFAULT 0, -- To mark primary communication address
      `is_active` TINYINT(1) DEFAULT 1, -- To mark address as active
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      CONSTRAINT `fk_std_addr_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_std_addr_cityId` FOREIGN KEY (`city_id`) REFERENCES `glb_cities` (`id`) ON DELETE RESTRICT
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- --------------------------------------------------------------------------------------------------------
    -- Screen - 3 : Tab Name (Parents)
    -- --------------------------------------------------------------------------------------------------------

    -- Parent/Guardian Master
    -- Guardians can be parents to multiple students (Siblings). 
    -- Optional link to sys_users if Parent Portal access is granted.
    CREATE TABLE IF NOT EXISTS `std_guardians` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `user_code` VARCHAR(20) NOT NULL,  -- Unique code for guardian (this will be saved as emp_code in sys_users table) 
      -- User Info
      `user_id` INT UNSIGNED DEFAULT NOT NULL,        -- Nullable. Set when Parent Portal access is created.
      `first_name` VARCHAR(50) NOT NULL,                 -- First_name+last_name will be saved as name in sys_users table
      `last_name` VARCHAR(50) DEFAULT NULL,              -- First_name+last_name will be saved as name in sys_users table
      -- Personal Info
      `gender` ENUM('Male','Female','Transgender','Prefer Not to Say') NOT NULL DEFAULT 'Male',
      `mobile_no` VARCHAR(20) NOT NULL,                -- Primary identifier if user_id is null
      `phone_no` VARCHAR(20) DEFAULT NULL,
      `email` VARCHAR(100) DEFAULT NULL,
      -- Professional Info
      `occupation` VARCHAR(100) DEFAULT NULL,
      `qualification` VARCHAR(100) DEFAULT NULL,
      `annual_income` DECIMAL(15,2) DEFAULT NULL,
      `preferred_language` INT unsigned NOT NULL,   -- fk to glb_languages
      -- Media & Status
      `photo_file_name` VARCHAR(100) DEFAULT NULL,     -- Fk to sys_media (file name to show in UI)
      `media_id` INT UNSIGNED DEFAULT NULL,         -- Optional if using sys_media table
      `is_active` TINYINT(1) DEFAULT 1,
      -- Meta
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      UNIQUE KEY `uq_std_guardians_mobile` (`mobile_no`), -- Assumes unique mobile per parent
      UNIQUE KEY `uq_std_guardians_userId` (`user_id`),
      CONSTRAINT `fk_std_guardians_userId` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    -- Condition:
    -- Short Name - (sys_user.short_name VARCHAR(30)) - This field value will be saved as 'short_name' in 'sys_users' table
    -- Password - (sys_user.password VARCHAR(255)) - The Hashed Value of Password will be saved as 'password' in 'sys_users' table


    -- Student-Guardian Junction
    -- M:N Relationship (Student has Father, Mother; Parent has multiple kids)
    CREATE TABLE IF NOT EXISTS `std_student_guardian_jnt` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_id` INT UNSIGNED NOT NULL,
      `guardian_id` INT UNSIGNED NOT NULL,
      -- 
      `relation_type` ENUM('Father','Mother','Guardian') NOT NULL, 
      `relationship` VARCHAR(50) NOT NULL, -- Father, Mother, Uncle, Brother, Sister, Grandfather, Grandmother
      `is_emergency_contact` TINYINT(1) DEFAULT 0,
      `can_pickup` TINYINT(1) DEFAULT 0,   -- Authorization to pick up child
      `is_fee_payer` TINYINT(1) DEFAULT 0, -- Who pays the fees?
      `can_access_parent_portal` TINYINT(1) DEFAULT 0,  -- Can he access Paret Portal or Not
      `can_receive_notifications` TINYINT(1) DEFAULT 1,
      `notification_preference` ENUM('Email','SMS','WhatsApp','All') DEFAULT 'All',
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      UNIQUE KEY `uq_std_guard_jnt` (`student_id`, `guardian_id`),
      CONSTRAINT `fk_sg_jnt_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_sg_jnt_guardian` FOREIGN KEY (`guardian_id`) REFERENCES `std_guardians` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- | Name (Firt Name + Last Name). | Relation Type | Relationship | Emergency Contact | Can Pick | Fee Payer | Portal Access | Notifications | Notification Pref. |

    -- --------------------------------------------------------------------------------------------------------
    -- Screen - 4 : Tab Name (Session)
    -- --------------------------------------------------------------------------------------------------------

    -- Tracks chronological academic history (Class/Section allocation per session)
    CREATE TABLE IF NOT EXISTS `std_student_academic_sessions` (
      `id` INT UNSIGNED AUTO_INCREMENT,
      `student_id` INT UNSIGNED NOT NULL,
      -- Academic Session
      `academic_session_id` INT UNSIGNED NOT NULL,   -- FK to glb_academic_sessions (or sch_org_academic_sessions_jnt)
      `class_section_id` INT UNSIGNED NOT NULL,         -- FK to sch_class_section_jnt
      `roll_no` INT UNSIGNED DEFAULT NULL,
      `subject_group_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_subject_groups (if streams apply)
      -- Other Detail
      `house` INT UNSIGNED DEFAULT NULL,             -- FK to sys_dropdown_table
      `is_current` TINYINT(1) DEFAULT 0,                -- Only one active record per student
      `current_flag` INT GENERATED ALWAYS AS ((case when (`is_current` = 1) then `student_id` else NULL end)) STORED,
      `session_status_id` INT UNSIGNED NOT NULL DEFAULT 'ACTIVE',    -- FK to sys_dropdown_table (PROMOTED, ACTIVE, LEFT, SUSPENDED, ALUMNI, WITHDRAWN)
      `leaving_date` DATE DEFAULT NULL,
      `count_as_attrition` TINYINT(1) NOT NULL,         -- Can we count this record as Attrition
      `reason_quit` int NULL,                           -- FK to `sys_dropdown_table` (Reason for leaving the Session)
      -- Note
      `dis_note` text NOT NULL,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_studentSessions_currentFlag` (`current_flag`),
      UNIQUE KEY `uq_std_acad_sess_student_session` (`student_id`, `academic_session_id`),
      CONSTRAINT `fk_sas_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_sas_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_sas_class_section` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_sas_subj_group` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_sas_status` FOREIGN KEY (`session_status_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE RESTRICT
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


    -- --------------------------------------------------------------------------------------------------------
    -- Screen - 5 : Tab Name (Previous Education)
    -- --------------------------------------------------------------------------------------------------------

    -- Student's Previous Education History (e.g. Previous Schools attended)
    CREATE TABLE IF NOT EXISTS `std_previous_education` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_id` INT UNSIGNED NOT NULL,
      -- School Details
      `school_name` VARCHAR(150) NOT NULL,
      `school_address` VARCHAR(255) DEFAULT NULL,
      `board` VARCHAR(50) DEFAULT NULL,           -- e.g. CBSE, ICSE, State Board
      -- Class Details
      `class_passed` VARCHAR(50) DEFAULT NULL,    -- e.g. 5th, 8th, 10th
      `year_of_passing` YEAR DEFAULT NULL,
      `percentage_grade` VARCHAR(20) DEFAULT NULL,
      `medium_of_instruction` VARCHAR(30) DEFAULT NULL, -- e.g. English, Hindi, Gujarati
      `tc_number` VARCHAR(50) DEFAULT NULL,       -- Transfer Certificate Number
      `tc_date` DATE DEFAULT NULL,                -- Transfer Certificate Date
      `is_recognized` TINYINT(1) DEFAULT 1,       -- Was the previous school recognized?
      -- Note
      `remarks` TEXT DEFAULT NULL,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      CONSTRAINT `fk_prev_edu_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Student Documents (Uploads for Previous Education, ID Proofs, etc.)
    CREATE TABLE IF NOT EXISTS `std_student_documents` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_id` INT UNSIGNED NOT NULL,
      `document_name` VARCHAR(100) NOT NULL,           -- e.g. 'Transfer Certificate', 'Mark Sheet', 'Aadhar Card'
      `document_type_id` INT UNSIGNED NOT NULL,     -- FK to sys_dropdown_table (Category of doc)
      `document_number` VARCHAR(100) DEFAULT NULL,     -- e.g. TC No, Serial No
      `issue_date` DATE DEFAULT NULL,
      `expiry_date` DATE DEFAULT NULL,
      `issuing_authority` VARCHAR(150) DEFAULT NULL,
      `is_verified` TINYINT(1) DEFAULT 0,              -- Verified by school admin
      `verified_by` INT UNSIGNED DEFAULT NULL,      -- FK to sys_users
      `verification_date` DATETIME DEFAULT NULL,
      `file_name` VARCHAR(100) DEFAULT NULL,           -- Fk to sys_media (file name to show in UI)
      `media_id` INT UNSIGNED DEFAULT NULL,         -- Optional if using sys_media table
      `notes` TEXT DEFAULT NULL,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      CONSTRAINT `fk_std_docs_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_std_docs_type` FOREIGN KEY (`document_type_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_std_docs_verifier` FOREIGN KEY (`verified_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


    -- --------------------------------------------------------------------------------------------------------
    -- Screen - 6 : Tab Name (Health)
    -- --------------------------------------------------------------------------------------------------------

    -- Medical Profile
    CREATE TABLE IF NOT EXISTS `std_health_profiles` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_id` INT UNSIGNED NOT NULL,
      -- 
      `blood_group` ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-') DEFAULT NULL,
      `height_cm` DECIMAL(5,2) DEFAULT NULL,    -- Last recorded
      `weight_kg` DECIMAL(5,2) DEFAULT NULL,    -- Last recorded
      `measurement_date` date DEFAULT NULL,
      `allergies` TEXT DEFAULT NULL,            -- CSV or Notes
      `chronic_conditions` TEXT DEFAULT NULL,   -- Asthma, Diabetes, etc.
      `medications` TEXT DEFAULT NULL,          -- Ongoing medications
      `dietary_restrictions` TEXT DEFAULT NULL,
      `vision_left` VARCHAR(20) DEFAULT NULL,
      `vision_right` VARCHAR(20) DEFAULT NULL,
      `doctor_name` VARCHAR(100) DEFAULT NULL,
      `doctor_phone` VARCHAR(20) DEFAULT NULL,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      UNIQUE KEY `uq_health_student` (`student_id`),
      CONSTRAINT `fk_health_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Vaccination History
    CREATE TABLE IF NOT EXISTS `std_vaccination_records` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_id` INT UNSIGNED NOT NULL,
      `vaccine_name` VARCHAR(100) NOT NULL,
      `date_administered` DATE DEFAULT NULL,
      `next_due_date` DATE DEFAULT NULL,
      `remarks` VARCHAR(255) DEFAULT NULL,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT `fk_vacc_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Medical Incidents (School Clinic Log)
    CREATE TABLE IF NOT EXISTS `std_medical_incidents` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_id` INT UNSIGNED NOT NULL,
      `incident_date` DATETIME NOT NULL,
      `incident_type_id` INT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (e.g. Injury, Sickness, Fainting)
      `location` VARCHAR(100) DEFAULT NULL,     -- Playground, Classroom
      `description` TEXT NOT NULL,
      `first_aid_given` TEXT DEFAULT NULL,
      `action_taken` VARCHAR(255) DEFAULT NULL, -- Sent home, Rested in sick bay, Taken to hospital
      `reported_by` INT UNSIGNED DEFAULT NULL, --  fk to sys_users (Teacher/Staff)
      `parent_notified` TINYINT(1) DEFAULT 0,
      `closure_date` DATE DEFAULT NULL,
      `follow_up_required` TINYINT(1) DEFAULT 0,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      CONSTRAINT `fk_med_inc_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_med_inc_reporter` FOREIGN KEY (`reported_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


    -- --------------------------------------------------------------------------------------------------------
    -- Screen - 7 : Tab Name (Attendance)
    -- --------------------------------------------------------------------------------------------------------

    -- Variable in sys_setting (Key "Period_wise_Student_Attendance", Value-TRUE/FALSE)
    -- Daily Attendance Log
    CREATE TABLE IF NOT EXISTS `std_student_attendance` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_id` INT UNSIGNED NOT NULL,
      `academic_session_id` INT UNSIGNED NOT NULL,
      `class_section_id` INT UNSIGNED NOT NULL,
      `attendance_date` DATE NOT NULL, -- Date of attendance
      `attendance_period` TINYINT UNSIGNED NOT NULL DEFAULT 0,
      `status` ENUM('Present','Absent','Late','Half Day','Short Leave','Leave') NOT NULL,
      `remarks` VARCHAR(255) DEFAULT NULL,
      `marked_by` INT UNSIGNED DEFAULT NULL,        -- User ID who marked attendance
      `marked_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      UNIQUE KEY `uq_std_att_student_date` (`student_id`, `attendance_date`, `attendance_period`),
      KEY `idx_std_att_class_date` (`class_section_id`, `attendance_date`),
      CONSTRAINT `fk_att_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_att_class` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_att_marker` FOREIGN KEY (`marked_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


    -- Attendance Correction Requests
    CREATE TABLE IF NOT EXISTS `std_attendance_corrections` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `attendance_id` INT UNSIGNED NOT NULL,        -- FK to std_student_attendance
      `requested_by` INT UNSIGNED NOT NULL,         -- Parent or Student User ID
      `requested_status` ENUM('Present','Absent','Late','Half Day','Short Leave','Leave') NOT NULL,
      `requested_period` TINYINT UNSIGNED NOT NULL DEFAULT 0,
      `reason` TEXT NOT NULL,
      `status` ENUM('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
      `admin_remarks` VARCHAR(255) DEFAULT NULL,       -- Admin/Teacher Remark on approval/rejection
      `action_by` INT UNSIGNED DEFAULT NULL,        -- Admin/Teacher who approved/rejected
      `action_at` TIMESTAMP NULL DEFAULT NULL,         -- When approved/rejected
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      CONSTRAINT `fk_att_corr_attId` FOREIGN KEY (`attendance_id`) REFERENCES `std_student_attendance` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_att_corr_reqBy` FOREIGN KEY (`requested_by`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_att_corr_actBy` FOREIGN KEY (`action_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===========================================================================
-- 14-HPC (hpc)
-- ===========================================================================
    -- Screen - 1 (Circular Goals)
    -- =========================================================
    -- CIRCULAR GOALS (NEP / PARAKH)
    -- =========================================================
    CREATE TABLE IF NOT EXISTS hpc_circular_goals (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `code` VARCHAR(50) NOT NULL,
      `name` VARCHAR(150) NOT NULL,
      `class_id` INT UNSIGNED NOT NULL,  -- Fk to sch_classes
      `description` TEXT,
      `nep_reference` VARCHAR(100),
      `is_active` TINYINT(1) DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP DEFAULT NULL,
      UNIQUE KEY `uq_cg_code` (`code`),
      CONSTRAINT `fk_cg_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE hpc_circular_goal_competency_jnt (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `circular_goal_id` INT UNSIGNED NOT NULL,
      `competency_id` INT UNSIGNED NOT NULL,
      `is_primary` TINYINT(1) DEFAULT 0,
      `is_active` TINYINT(1) DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP DEFAULT NULL,
      UNIQUE KEY `uq_cg_comp` (`circular_goal_id`, `competency_id`),
      CONSTRAINT `fk_cg_comp_goal` FOREIGN KEY (`circular_goal_id`) REFERENCES `slb_circular_goals`(`id`),
      CONSTRAINT `fk_cg_comp_comp` FOREIGN KEY (`competency_id`) REFERENCES `slb_competencies`(`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Screen - 2 (Learning Activities)
    -- =========================================================
    -- LEARNING OUTCOMES (NORMALIZED)
    -- =========================================================
    CREATE TABLE IF NOT EXISTS hpc_learning_outcomes (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `code` VARCHAR(50) NOT NULL,
      `description` VARCHAR(255) NOT NULL,
      `domain` INT UNSIGNED NOT NULL,   -- FK TO sys_dropdown_table e.g. ('COGNITIVE','AFFECTIVE','PSYCHOMOTOR') DEFAULT 'COGNITIVE'
      `bloom_id` INT UNSIGNED DEFAULT NULL,
      `level` TINYINT UNSIGNED DEFAULT 1,
      `is_active` TINYINT(1) DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP DEFAULT NULL,
      UNIQUE KEY `uq_lo_code` (`code`),
      CONSTRAINT `fk_lo_bloom` FOREIGN KEY (`bloom_id`) REFERENCES `slb_bloom_taxonomy`(`id`)
      CONSTRAINT `fk_lo_domain` FOREIGN KEY (`domain`) REFERENCES `sys_dropdown_table`(`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS hpc_outcome_entity_jnt (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `outcome_id` INT UNSIGNED NOT NULL,
      `class_id` INT UNSIGNED NOT NULL,  -- Fk to sch_classes
      `entity_type` ENUM('SUBJECT','LESSON','TOPIC') NOT NULL,
      `entity_id` INT UNSIGNED NOT NULL,  -- Dropdown from sch_subjects, slb_lessons, slb_topics (Depend upon selection of entity_type)
      `is_active` TINYINT(1) DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP DEFAULT NULL,
      UNIQUE KEY `uq_outcome_entity` (`outcome_id`, `entity_type`, `entity_id`),
      CONSTRAINT `fk_outcome_entity_outcome` FOREIGN KEY (`outcome_id`) REFERENCES `slb_learning_outcomes`(`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Screen - 3 (QUESTION MAPPING)
    -- =========================================================
    -- OUTCOME ↔ QUESTION MAPPING (will be used for HPC)
    -- =========================================================
    CREATE TABLE IF NOT EXISTS hpc_outcome_question_jnt (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `outcome_id` INT UNSIGNED NOT NULL,
      `question_id` INT UNSIGNED NOT NULL,  -- fk to qns_questions_bank.id
      `weightage` DECIMAL(5,2) DEFAULT NULL,
      `is_active` TINYINT(1) DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP DEFAULT NULL,
      UNIQUE KEY `uq_outcome_question` (`outcome_id`, `question_id`),
      CONSTRAINT `fk_outcome_question_outcome` FOREIGN KEY (`outcome_id`) REFERENCES `slb_learning_outcomes`(`id`),
      CONSTRAINT `fk_outcome_question_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank`(`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Screen - 4 (Knowledge Graph Validation)
    -- =========================================================
    -- KNOWLEDGE GRAPH VALIDATION
    -- =========================================================
    CREATE TABLE IF NOT EXISTS hpc_knowledge_graph_validation (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `topic_id` INT UNSIGNED NOT NULL,
      `issue_type` ENUM('NO_COMPETENCY','NO_OUTCOME','NO_WEIGHTAGE','ORPHAN_NODE') NOT NULL,
      `severity` ENUM('LOW','MEDIUM','HIGH','CRITICAL') DEFAULT 'LOW',
      `detected_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `is_resolved` TINYINT(1) DEFAULT 0,
      `resolved_at` TIMESTAMP NULL,
      `is_active` TINYINT(1) DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP DEFAULT NULL,
      CONSTRAINT `fk_kgv_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics`(`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Screen - 5 (Topic Equivalency)
    -- =========================================================
    -- MULTI-SYLLABUS TOPIC EQUIVALENCY
    -- =========================================================
    CREATE TABLE IF NOT EXISTS hpc_topic_equivalency (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `source_topic_id` INT UNSIGNED NOT NULL,
      `target_topic_id` INT UNSIGNED NOT NULL,
      `equivalency_type` ENUM('FULL','PARTIAL','PREREQUISITE') DEFAULT 'FULL',
      `is_active` TINYINT(1) DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP DEFAULT NULL,
      UNIQUE KEY `uq_topic_equiv` (`source_topic_id`, `target_topic_id`),
      CONSTRAINT `fk_equiv_source` FOREIGN KEY (`source_topic_id`) REFERENCES `slb_topics`(`id`),
      CONSTRAINT `fk_equiv_target` FOREIGN KEY (`target_topic_id`) REFERENCES `slb_topics`(`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Screen - 6 (Syllabus Coverage) Only View & Update
    -- =========================================================
    -- SYLLABUS COVERAGE SNAPSHOT (ANALYTICS)
    -- =========================================================
    CREATE TABLE IF NOT EXISTS hpc_syllabus_coverage_snapshot (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `academic_session_id` INT UNSIGNED NOT NULL,
      `class_id` INT UNSIGNED NOT NULL,
      `subject_id` INT UNSIGNED NOT NULL,
      `coverage_percentage` DECIMAL(5,2) NOT NULL,
      `snapshot_date` DATE NOT NULL,
      `is_active` TINYINT(1) DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP DEFAULT NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Screen - 7 (HPC Parameters)
    -- =========================================================
    -- HPC PARAMETERS
    -- =========================================================
    CREATE TABLE IF NOT EXISTS hpc_hpc_parameters (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `code` VARCHAR(20) NOT NULL,      -- AWARENESS, SENSITIVITY, CREATIVITY
      `name` VARCHAR(100) NOT NULL,
      `description` VARCHAR(500) DEFAULT NULL,
      `is_active` TINYINT(1) DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP DEFAULT NULL,
      UNIQUE KEY `uq_hpc_param_code` (`code`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Screen - 8 (HPC Performance Levels)
    -- =========================================================
    -- HPC PERFORMANCE LEVELS
    -- =========================================================
    CREATE TABLE IF NOT EXISTS hpc_hpc_levels (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `code` VARCHAR(20) NOT NULL,      -- BEGINNER, PROFICIENT, ADVANCED
      `ordinal` TINYINT UNSIGNED NOT NULL,
      `description` VARCHAR(500) DEFAULT NULL,
      `is_active` TINYINT(1) DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP DEFAULT NULL,
      UNIQUE KEY `uq_hpc_level_code` (`code`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Screen - 9 (Student HPC Evaluation)
    -- =========================================================
    -- STUDENT HPC EVALUATION
    -- =========================================================
    CREATE TABLE IF NOT EXISTS hpc_student_hpc_evaluation (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `academic_session_id` INT UNSIGNED NOT NULL,
      `student_id` INT UNSIGNED NOT NULL,
      `subject_id` INT UNSIGNED NOT NULL,
      `competency_id` INT UNSIGNED NOT NULL,
      `hpc_parameter_id` INT UNSIGNED NOT NULL,
      `hpc_level_id` INT UNSIGNED NOT NULL,
      `evidence_type` INT UNSIGNED NOT NULL,   -- FK TO sys_dropdown_table e.g. ('ACTIVITY','ASSESSMENT','OBSERVATION')
      `evidence_id` INT UNSIGNED,
      `remarks` VARCHAR(500),
      `assessed_by` INT UNSIGNED,
      `assessed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `is_active` TINYINT(1) DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP DEFAULT NULL,
      UNIQUE KEY `uq_hpc_eval` (`academic_session_id`, `student_id`, `subject_id`, `competency_id`, `hpc_parameter_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Screen - 10 (Learning Activities)
    -- =========================================================
    -- LEARNING ACTIVITIES (HPC EVIDENCE)
    -- =========================================================
    CREATE TABLE IF NOT EXISTS hpc_learning_activities (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `topic_id` INT UNSIGNED NOT NULL,
      `activity_type` INT UNSIGNED NOT NULL,   FK TO sys_dropdown_table e.g. ('PROJECT','OBSERVATION','FIELD_WORK','GROUP_WORK','ART','SPORT','DISCUSSION')
      `description` TEXT NOT NULL,
      `expected_outcome` TEXT,
      `is_active` TINYINT(1) DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP DEFAULT NULL,
      CONSTRAINT `fk_activity_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics`(`id`)
      CONSTRAINT `fk_activity_type` FOREIGN KEY (`activity_type`) REFERENCES `sys_dropdown_table`(`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Do not ceate screen for this write Now. We will 
    -- =========================================================
    -- HOLISTIC PROGRESS CARD SNAPSHOT
    -- =========================================================
    CREATE TABLE IF NOT EXISTS hpc_student_hpc_snapshot (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `academic_session_id` INT UNSIGNED NOT NULL,
      `student_id` INT UNSIGNED NOT NULL,
      `snapshot_json` JSON NOT NULL,
      `generated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `is_active` TINYINT(1) DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP DEFAULT NULL,
      UNIQUE KEY `uq_hpc_snapshot` (`academic_session_id`, `student_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- =====================================================================
    -- END OF NEP 2020 + HPC EXTENSION SCHEMA
    -- =====================================================================
  
  
  -- =========================================================================
  -- LESSON VERSION & GOVERNANCE CONTROL (NCERT / BOARD DRIVEN)
  -- =========================================================================
  -- Purpose:
  -- 1. Track lesson source authority (NCERT / Board / Publisher)
  -- 2. Track textbook & edition used to define the lesson
  -- 3. Enforce immutability during academic session
  -- 4. Maintain historical version traceability across years
  -- =========================================================================

  CREATE TABLE IF NOT EXISTS `hpc_lesson_version_control` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- Core linkage
    `lesson_id` INT UNSIGNED NOT NULL,           -- FK to slb_lessons.id
    `academic_session_id` INT UNSIGNED NOT NULL, -- Session in which this version applies
    -- Authority & source
    `curriculum_authority` ENUM('NCERT','CBSE','ICSE','STATE_BOARD','OTHER') NOT NULL DEFAULT 'NCERT',
    `board_code` VARCHAR(50) DEFAULT NULL,          -- CBSE, ICSE, STATE-UK, etc.
    `book_id` INT UNSIGNED DEFAULT NULL,         -- FK to book master (if exists)
    `book_title` VARCHAR(255) DEFAULT NULL,         -- Redundant but audit-friendly
    `book_edition` VARCHAR(100) DEFAULT NULL,       -- e.g. "2024 Edition"
    `publisher` VARCHAR(150) DEFAULT 'NCERT',
    -- Versioning
    `lesson_version` VARCHAR(20) NOT NULL,          -- e.g. v1.0, v2.0
    `derived_from_lesson_id` INT UNSIGNED DEFAULT NULL, -- Previous version reference
    -- Governance state (SYSTEM CONTROLLED)
    `status` ENUM('IMPORTED','ACTIVE','LOCKED','DEPRECATED','ARCHIVED') NOT NULL DEFAULT 'IMPORTED',
    -- Control flags
    `is_editable` TINYINT(1) NOT NULL DEFAULT 0,    -- Always 0 for system-defined lessons
    `is_system_defined` TINYINT(1) NOT NULL DEFAULT 1,
    -- Audit
    `imported_on` DATE DEFAULT NULL,                -- When lesson was imported
    `locked_on` DATE DEFAULT NULL,                  -- When lesson was locked
    `remarks` VARCHAR(500) DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    -- Constraints
    UNIQUE KEY `uq_lesson_session_version`(`lesson_id`, `academic_session_id`, `lesson_version`),
    KEY `idx_lvc_lesson` (`lesson_id`),
    KEY `idx_lvc_session` (`academic_session_id`),
    KEY `idx_lvc_status` (`status`),
    CONSTRAINT `fk_lvc_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `slb_lessons` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lvc_prev_lesson` FOREIGN KEY (`derived_from_lesson_id`) REFERENCES `slb_lessons` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
      -- NCERT Import (Once per Year)
      --   Lessons imported from NCERT book structure
      --   Record inserted with:
      --     status = IMPORTED
      --     lesson_version = v1.0
      -- Session Lock (Before Teaching / Exams)
      --   System marks:
      --     status = LOCKED
      --     locked_on = CURRENT_DATE
      --   No updates allowed at service layer
      -- Next Academic Year
      --   New NCERT edition released
      --   New lessons created
      --   New record inserted:
      --     lesson_version = v2.0
      --     derived_from_lesson_id = old lesson_id
      --   Old record marked DEPRECATED


  -- =========================================================
  -- CURRICULUM CHANGE MANAGEMENT
  -- =========================================================
  CREATE TABLE hpc_curriculum_change_request (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `entity_type` ENUM('SUBJECT','LESSON','TOPIC','COMPETENCY') NOT NULL,
    `entity_id` INT UNSIGNED NOT NULL,
    `change_type` ENUM('ADD','UPDATE','DELETE') NOT NULL,
    `change_summary` VARCHAR(500),
    `impact_analysis` JSON,
    `status` ENUM('DRAFT','SUBMITTED','APPROVED','REJECTED') DEFAULT 'DRAFT',
    `requested_by` INT UNSIGNED,
    `requested_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP DEFAULT NULL,
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;






-- =====================================================================================================================
-- Change Log
-- =====================================================================================================================
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
  -- ===========================================================================================================================================
  -- Changed on 2025-12-29
  -- Added New Field `user_id` in table `std_student_sessions_jnt` to capture User ID of the Student. This is required to Get Student details Directly from `sch_user` table.
  -- Changed table name from 'std_student_detail' to 'std_student_personal_details'
  -- Changed on 20255-01-06
  -- Modify Table (sch_class_groups_jnt) - `section_id` int NULL, to NOT NULL