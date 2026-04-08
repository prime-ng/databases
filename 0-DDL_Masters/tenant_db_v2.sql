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
-- 2 - EVENT ENGINE (sys)
-- ===========================================================================

  -- ------------------------------------------------------------------
  -- EVENT TYPES
  -- ------------------------------------------------------------------
  -- Need to Verify
  CREATE TABLE IF NOT EXISTS `sys_event_type` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,  
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  -- ------------------------------------------------------------------
  -- TRIGGER EVENTS
  -- ------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sys_trigger_event` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `event_logic` JSON NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  -- ------------------------------------------------------------------
  -- ACTION TYPES (WHAT SYSTEM CAN DO)
  -- ------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sys_action_type` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `action_logic` JSON NOT NULL,
    `required_parameters` JSON NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  -- ------------------------------------------------------------------
  -- RULE ENGINE CONFIG (CORE RULE DEFINITION)
  -- ------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sys_rule_engine_config` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `rule_code` VARCHAR(50) NOT NULL UNIQUE,
    `rule_name` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `trigger_event_id` INT UNSIGNED NOT NULL,
    `applicable_class_group_id` INT UNSIGNED NULL,
    `logic_config` JSON NOT NULL,
    `priority` INT NOT NULL DEFAULT 100,
    `stop_further_execution` TINYINT(1) NOT NULL DEFAULT 0,
    `ai_enabled` TINYINT(1) NOT NULL DEFAULT 0,
    `ai_confidence_score` DECIMAL(5,2) NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT fk_rule_trigger FOREIGN KEY (trigger_event_id) REFERENCES `lms_trigger_event`(`id`),
    CONSTRAINT fk_rule_class_group FOREIGN KEY (applicable_class_group_id) REFERENCES `sch_class_groups_jnt`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ------------------------------------------------------------------
  -- RULE → ACTION MAPPING (MULTIPLE ACTIONS PER RULE)
  -- ------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sys_rule_action_map` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `rule_id` INT UNSIGNED NOT NULL,
    `action_type_id` INT UNSIGNED NOT NULL,
    `execution_order` INT NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT fk_rule_action_rule FOREIGN KEY (rule_id) REFERENCES `lms_rule_engine_config`(`id`),
    CONSTRAINT fk_rule_action_action FOREIGN KEY (action_type_id) REFERENCES `lms_action_type`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ------------------------------------------------------------------
  -- RULE EXECUTION LOG (AUDIT + DEBUG + AI DATA)
  -- ------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sys_rule_execution_log` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `rule_id` INT UNSIGNED NOT NULL,
    `trigger_event_id` INT UNSIGNED NOT NULL,
    `action_type_id` INT UNSIGNED NOT NULL,
    `entity_type` VARCHAR(50) NOT NULL,
    `entity_id` INT UNSIGNED NOT NULL,
    `execution_context` JSON NOT NULL,
    `execution_result` ENUM('SUCCESS','FAILED','SKIPPED') NOT NULL,
    `error_message` TEXT NULL,
    `executed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_rule (rule_id),
    INDEX idx_trigger (trigger_event_id),
    INDEX idx_entity (entity_type, entity_id),
    CONSTRAINT fk_log_rule FOREIGN KEY (rule_id) REFERENCES `lms_rule_engine_config`(`id`),
    CONSTRAINT fk_log_trigger FOREIGN KEY (trigger_event_id) REFERENCES `lms_trigger_event`(`id`),
    CONSTRAINT fk_log_action FOREIGN KEY (action_type_id) REFERENCES `lms_action_type`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===========================================================================
-- 3 - TENANT SETUP MODULE (sch) [School, Class, Infra & Employee Setup]
-- ===========================================================================

 -- ===========================================================================
 -- 3.1 - TENANT SETUP SUB-MODULE (sch)
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

  -- Here we are setting all the configurations that will be used for the All Modules of the Application. This will be a Master Table to control the configurations for all modules.
  -- Only Edit Functionality will be available for Tenant. No one can Add or Delete any record and in Edit also "key" can not be edited. In Edit "key" will not be even displayed.
  CREATE TABLE IF NOT EXISTS `sch_config` (
    `id` SMALLINT unsigned NOT NULL AUTO_INCREMENT,
    `module_id` INT unsigned NOT NULL,                     -- FK to glb_modules.id to identify which module this config belongs to (e.g. Student Mgmt., Teacher Mgmt., Class Mgmt.)
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
    -- 

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
 -- 3.2 - SCHOOL SETUP SUB-MODULE (sch)
 -- ===========================================================================

   -- ----------------------------------------------------------------------------
   -- This table will capture different types of attendance status for both students and staff. 
   -- It will be used in attendance marking and reporting.
   -- ----------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_attendance_types` (
    `id`  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`     VARCHAR(10) NOT NULL,  -- e.g. 'P', 'A', 'L', 'H'
    `name`     VARCHAR(100) NOT NULL,  -- e.g. 'Present', 'Absent', 'Leave', 'Holiday'
    `applicable_for`      ENUM('STUDENT','STAFF','BOTH') NOT NULL,
    `is_present`          TINYINT(1) NOT NULL DEFAULT 0,  -- 0: Not Present, 1: Present
    `is_absent`           TINYINT(1) NOT NULL DEFAULT 0,  -- 0: Not Absent, 1: Absent
    `display_order`       INT NOT NULL DEFAULT 0,
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    UNIQUE KEY `uq_attendance_code` (`code`),
    INDEX `idx_attendance_active` (`is_active`, `is_deleted`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


   -- ----------------------------------------------------------------------------
   -- This table will capture type of Leaves available for staff. 
   -- It will be used in leave application and reporting.
   -- ----------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_leave_types` (
    `id`       INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`          VARCHAR(10) NOT NULL,  -- e.g. 'CL', 'SL', 'PL', 'LOP'
    `name`          VARCHAR(100) NOT NULL,  -- e.g. 'Casual Leave', 'Sick Leave', 'Parental Leave', 'Leave On Pay'
    `is_paid`             TINYINT(1) NOT NULL DEFAULT 1,  -- 0: Unpaid Leave, 1: Paid Leave
    `requires_approval`   TINYINT(1) NOT NULL DEFAULT 1,  -- 0: No Approval Required, 1: Approval Required
    `allow_half_day`      TINYINT(1) NOT NULL DEFAULT 0,  -- 0: Full Day Leave Only, 1: Half Day Leave Allowed
    `display_order`       INT NOT NULL DEFAULT 0,
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    UNIQUE KEY `uq_leave_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


   -- ----------------------------------------------------------------------------
   -- This table will capture different categories for both students and staff. 
   -- It will be used in various configurations and reporting.
   -- ----------------------------------------------------------------------------
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


   -- ----------------------------------------------------------------------------
   -- This table will capture Leave configuration for different staff categories and leave types.
   -- It will be used in leave application and reporting.
   -- ----------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_leave_config` (
    `id`     INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `academic_year`       VARCHAR(9) NOT NULL,
    `staff_category_id`   INT UNSIGNED NOT NULL,   -- FK to `sch_categories.id`
    `leave_type_id`       INT UNSIGNED NOT NULL,   -- FK to `sch_leave_types.id`
    `total_allowed`       DECIMAL(5,2) NOT NULL,
    `carry_forward`       TINYINT(1) NOT NULL DEFAULT 0,  -- 0: No Carry Forward, 1: Carry Forward
    `max_carry_forward`   DECIMAL(5,2) NULL,              -- Maximum carry forward allowed
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    UNIQUE KEY `uq_leave_config` (`academic_year`, `staff_category_id`, `leave_type_id`),
    CONSTRAINT `fk_leave_config_category` FOREIGN KEY (`staff_category_id`) REFERENCES `sch_categories` (`id`),
    CONSTRAINT `fk_leave_config_type` FOREIGN KEY (`leave_type_id`) REFERENCES `sch_leave_types` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


   -- ----------------------------------------------------------------------------
   -- This table will capture the reasons for disabling a student or staff. 
   -- It will be used in disable/enable operations and reporting.
   -- ----------------------------------------------------------------------------
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

 -- ===========================================================================
 -- 3.3 - CLASS SETUP SUB-MODULE (sch)
 -- ===========================================================================

  CREATE TABLE IF NOT EXISTS `sch_sections` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint unsigned DEFAULT 1,       -- will have sequence order for Sections (Auto Update by Drag & Drop)
    `code` CHAR(5) NOT NULL,                    -- e.g., 'A','B','C','D' and so on (This will be used for Timetable)
    `short_name` varchar(20) DEFAULT NULL,      -- e.g. 'SEC-A' or 'SEC-B' (NEW)
    `name` varchar(50) NOT NULL,                -- e.g. 'Section - A', 'Section - B'
    `is_active` tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_sections_name` (`name`),
    UNIQUE KEY `uq_sections_code` (`code`),
    UNIQUE KEY `uq_sections_ordinal` (`ordinal`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tables for Classes, Sections, Subjects, Subject Types, Study Formats, Class-Section Junctions, Subject-StudyFormat Junctions, Class Groups, Subject Groups
  CREATE TABLE IF NOT EXISTS `sch_classes` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,             -- will have sequence order (Auto Update by Drag & Drop)
    `code` CHAR(5) NOT NULL,                    -- e.g., 'BV1','BV2','1st','1' and so on (This will be used for Timetable)
    `short_name` varchar(20) DEFAULT NULL,      -- e.g. 'G1' or '10th', '11th', '12th'
    `name` varchar(50) NOT NULL,                -- e.g. 'Grade 1' or 'Class - 10th', 'Class - 11th', 'Class - 12th'
    `is_active` tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_classes_code` (`code`),
    UNIQUE KEY `uq_classes_shortName` (`short_name`),
    UNIQUE KEY `uq_classes_name` (`name`),
    UNIQUE KEY `uq_classes_ordinal` (`ordinal`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `sch_class_section_jnt` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,                        -- will have sequence order  (Added new) (Auto Update by Drag & Drop)
    `class_id` int unsigned NOT NULL,                      -- FK to sch_classes
    `section_id` int unsigned NOT NULL,                    -- FK to sch_sections
    `code` char(10) NOT NULL,                              -- Combination of class Code + section Code i.e. '8th_A', '10h_B' (Changed from class_secton_code)
    `name` varchar(50) NOT NULL,                           -- e.g. 'Grade 1' or 'Class - 10th', 'Class - 11th Section - A', 'Class - 12th Section - B' (Added new)
    `capacity` tinyint unsigned DEFAULT NULL,              -- Targeted / Planned Quantity of stundets in Each Sections of every class.
    `actual_total_student` tinyint unsigned DEFAULT NULL,  -- Actual Number of Student in the Class+Section (changed from total_student)
    `min_required_student` tinyint unsigned DEFAULT NULL,  -- Minimum Number of Student required to start a class+section (Added new)
    `max_allowed_student` tinyint unsigned DEFAULT NULL,   -- Maximum Number of Student allowed in a class+section (Added new)
    `class_teacher_id` INT unsigned NOT NULL,              -- FK to sch_users
    `assistance_class_teacher_id` INT unsigned NOT NULL,   -- FK to sch_users
    `rooms_type_id` int unsigned NOT NULL,                 -- FK to 'sch_rooms_type' (Added new)
    `class_house_room_id` int unsigned NOT NULL,           -- FK to 'sch_rooms' (Added new)
    `total_periods_daily` tinyint unsigned DEFAULT NULL,   -- Total Number of Periods in a day for this class+section (Added new)
    `is_active` tinyint(1) NOT NULL DEFAULT 1    ,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_classSection_ordinal` (`ordinal`),
    UNIQUE KEY `uq_classSection_code` (`code`),
    UNIQUE KEY `uq_classSection_name` (`name`),
    UNIQUE KEY `uq_classSection_classId_sectionId` (`class_id`,`section_id`),
    CONSTRAINT `fk_classSection_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_classSection_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_classSection_classTeacherId` FOREIGN KEY (`class_teacher_id`) REFERENCES `sys_users` (`id`),
    CONSTRAINT `fk_classSection_assistanceClassTeacherId` FOREIGN KEY (`assistance_class_teacher_id`) REFERENCES `sys_users` (`id`),
    CONSTRAINT `fk_classSection_roomsTypeId` FOREIGN KEY (`rooms_type_id`) REFERENCES `sch_rooms_type` (`id`),
    CONSTRAINT `fk_classSection_classHouseRoomId` FOREIGN KEY (`class_house_room_id`) REFERENCES `sch_rooms` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- subject_type will represent what type of subject it is - Major, Minor, Core, Main, Optional etc.
  CREATE TABLE IF NOT EXISTS `sch_subject_types` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `code` char(5) NOT NULL,            -- 'MAJ','MIN','OPT','ACT','SPO'
    `short_name` varchar(20) NOT NULL,  -- 'MAJOR','MINOR','OPTIONAL'
    `name` varchar(50) NOT NULL,
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
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `code` CHAR(5) NOT NULL,            -- e.g., 'LECT','LAB','PRAC','TUT','SEM','WSH','GRD','OTH'
    `short_name` varchar(20) NOT NULL,  -- 'LECTURE','LAB','PRACTICAL','TUTORIAL','SEMINAR','WORKSHOP','GROUP_DISCUSSION','OTHER'
    `name` varchar(50) NOT NULL,        -- 'LECTURE','LAB','PRACTICAL','TUTORIAL','SEMINAR','WORKSHOP','GROUP_DISCUSSION','OTHER'
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
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `code` CHAR(5) NOT NULL,            -- e.g., 'SCI','MTH','SST','ENG' and so on (This will be used for Timetable)
    `short_name` varchar(20) NOT NULL,  -- e.g. 'SCIENCE','MATH','SST','ENGLISH' and so on
    `name` varchar(50) NOT NULL,        -- 'SCIENCE','MATH','SST','ENGLISH' and so on
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subjects_shortName` (`short_name`),
    UNIQUE KEY `uq_subjects_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- subject_study_format is grouping for different streams like Sci-10 Lacture, Arts-10 Activity, Core-10
  -- I have removed 'sub_types' from 'sch_subject_study_format_jnt' because one Subject_StudyFormat may belongs to different Subject_type for different classes
  -- Removed 'short_name' as we can use `sub_stdformat_code`
  CREATE TABLE IF NOT EXISTS `sch_subject_study_format_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,               -- will have sequence order (Auto Update by Drag & Drop)
    `subject_id` INT unsigned NOT NULL,           -- FK to 'sch_subjects'
    `study_format_id` int unsigned NOT NULL,      -- FK to 'sch_study_formats'
    `subject_type_id` int unsigned NOT NULL,      -- FK to 'sch_subject_types'
    `code` CHAR(30) NOT NULL,                     -- e.g., 'SCI_LAC','SCI_LAB','SST_LAC','ENG_LAC' (Changed from 'subject_studyformat_code')
    `name` varchar(50) NOT NULL,                  -- e.g., 'Science Lecture','Science Lab','Math Lecture','Math Lab' and so on
       --
    `require_class_house_room` TINYINT(1) NOT NULL DEFAULT 0, -- Whether Class House Room is required for this Class Group
    `compulsory_specific_room_type` TINYINT(1) NOT NULL DEFAULT 0, -- Whether specific room type is required (TRUE - if Specific Room Type is Must)
    `required_room_type_id` INT UNSIGNED NOT NULL,      -- FK to sch_rooms_type.id (Required)
    `required_room_id` INT UNSIGNED DEFAULT NULL,      -- FK to sch_rooms.id (Optional)
    --
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subStudyFormat_code` (`code`),
    UNIQUE KEY `uq_subStudyFormat_subjectId_stFormat` (`subject_id`,`study_format_id`),
    CONSTRAINT `fk_subStudyFormat_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subStudyFormat_studyFormatId` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subStudyFormat_subjectTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Ths table will be used to define different Class Groups like 10th-A Science Lecture Major, 7th-B Commerce Optional etc.
  -- old name 'sch_subject_study_format_class_subj_types_jnt' changed to 'sch_class_groups_jnt'
  CREATE TABLE IF NOT EXISTS `sch_class_groups_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `class_id` int unsigned NOT NULL,             -- FK to 'sch_classes'
    `section_id` int unsigned NOT NULL,           -- FK to 'sch_sections' (Optional)
    `subject_Study_format_id` INT unsigned NOT NULL,  -- FK to 'sch_subject_study_format_jnt'
    `subject_type_id` int unsigned NOT NULL,      -- FK to 'sch_subject_types'
    `code` CHAR(50) NOT NULL, -- Combination of (Class+Section+Subject+StudyFormat+SubjType) e.g., '10h_A_SCI_LAC_MAJ','8th_MAT_LAC_OPT' (This will be used for Timetable)
    `name` varchar(100) NOT NULL,                 -- 10th-A Science Lacture Major
    -- Information for Timetable Module
    `is_compulsory` tinyint(1) NOT NULL DEFAULT '0',       -- Is this Subject compulsory for Student or Optional
    `required_weekly_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,   -- Total periods required per week for this Class Group (Class+{Section}+Subject+StudyFormat)
    `min_weekly_periods` TINYINT UNSIGNED DEFAULT NULL,    -- Minimum periods required per week for this Class Group
    `max_weekly_periods` TINYINT UNSIGNED DEFAULT NULL,    -- Maximum periods required per week for this Class Group
    `min_daily_periods` TINYINT UNSIGNED DEFAULT NULL,     -- Minimum periods per day for this Class Group
    `max_daily_periods` TINYINT UNSIGNED DEFAULT NULL,     -- Maximum periods per day for this Class Group
    `min_gap_between_periods` TINYINT UNSIGNED DEFAULT NULL,       -- Minimum gap periods for this Class Group
    `allow_consecutive_periods` TINYINT(1) NOT NULL DEFAULT 0,     -- Whether consecutive periods are allowed for this Class Group
    `max_consecutive_periods` TINYINT UNSIGNED DEFAULT 1,          -- Maximum consecutive periods
    `priority_score` SMALLINT UNSIGNED DEFAULT 10,                 -- Priority of this requirement on 1-100 scale
    --
    `require_class_house_room` TINYINT(1) NOT NULL DEFAULT 0, -- Whether Class House Room is required for this Class Group
    `compulsory_specific_room_type` TINYINT(1) NOT NULL DEFAULT 0, -- Whether specific room type is required (TRUE - if Specific Room Type is Must)
    `required_room_type_id` INT UNSIGNED NOT NULL,      -- FK to sch_rooms_type.id (Required)
    `required_room_id` INT UNSIGNED DEFAULT NULL,      -- FK to sch_rooms.id (Optional)
    -- Audit Fields
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_classGroups_subStdformatCode` (`code`),
    UNIQUE KEY `uq_classGroups_cls_Sec_subStdFmt_SubTyp` (`class_id`,`section_id`,`subject_Study_format_id`),
    CONSTRAINT `fk_classGroups_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_classGroups_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_classGroups_subjStudyFormatId` FOREIGN KEY (`subject_Study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_classGroups_subTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`),
    CONSTRAINT `fk_classGroups_roomTypeId` FOREIGN KEY (`required_room_type_id`) REFERENCES `sch_rooms_type` (`id`),
    CONSTRAINT `fk_classGroups_roomId` FOREIGN KEY (`required_room_id`) REFERENCES `sch_rooms` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- There will be a Variable in 'sch_settings' table named (Subj_Group_will_be_used_for_all_sections_of_a_class)
  -- Remove above condition and make Scetion_id optional.
  -- if 'required_room_type' is House Room, then 'required_room_id' will be ignored.
  -- Table 'sch_subject_groups' will be used to assign all subjects to the students
  CREATE TABLE IF NOT EXISTS `sch_subject_groups` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `class_id` int UNSIGNED NOT NULL,   -- FK to 'sch_classes'
    `section_id` int UNSIGNED NULL,     -- FK (Section can be null if Group will be used for all sectons) (Optional)
    `code` CHAR(20) NOT NULL,           -- Combination of (Class+{Section}+Subject+StudyFormat+SubjType) e.g., '10h_A_SCI_LAC_MAJ','8th_MAT_LAC_OPT' (This will be used for Timetable)
    `short_name` varchar(50) NOT NULL,  -- 7th Science, 7th Commerce, 7th-A Science etc.
    `name` varchar(100) NOT NULL,       -- '7th (Sci,Mth,Eng,Hindi,SST with Sanskrit,Dance)'
    `registered_students_count` int NOT NULL DEFAULT 0, -- Total registered students in this group
    `default_group_for_class` tinyint(1) NOT NULL DEFAULT 0, -- Whether this group is default for the class
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subjectGroups_code` (`code`),
    UNIQUE KEY `uq_subjectGroups_shortName` (`short_name`),
    UNIQUE KEY `uq_subjectGroups_name` (`class_id`,`name`),
    CONSTRAINT `fk_subGroups_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subGroups_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- There will be a Variable in 'sch_settings' table named (Subj_Group_will_be_used_for_all_sections_of_a_class)
  -- Remove above condition and make Scetion_id optional.
 

  CREATE TABLE IF NOT EXISTS `sch_subject_group_subject_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `subject_group_id` INT unsigned NOT NULL,              -- FK to 'sch_subject_groups'
    `class_group_id` INT unsigned NOT NULL,                -- FK to 'sch_class_groups_jnt'
    `subject_id` int unsigned NOT NULL,                    -- FK to 'sch_subjects' (De-Normalization)
    `subject_study_format_id` INT unsigned NOT NULL,       -- FK to 'sch_subject_study_format_jnt'
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subjGrpSubj_subjGrpId_classGroup` (`subject_group_id`,`class_group_id`),
    CONSTRAINT `fk_subjGrpSubj_subjectGroup` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_classGroup` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_subjectStudyFormatId` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Add new Field for Timetable -
  -- is_compulsory, min_periods_per_week, max_periods_per_week, max_per_day, min_per_day, min_gap_periods, allow_consecutive, max_consecutive, priority, compulsory_room_type

 -- ===========================================================================
 -- 3.4 - INFRA SETUP SUB-MODULE (sch)
 -- ===========================================================================

  -- Building Coding format is - 2 Digit for Buildings(10-99)
  CREATE TABLE IF NOT EXISTS `sch_buildings` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `code` char(10) NOT NULL,                      -- 2 digits code (10,11,12) 
    `short_name` varchar(30) NOT NULL,            -- e.g., 'Junior Wing','Primary Wing','Middle Wing','Senior Wing','Administration Wings'
    `name` varchar(50) NOT NULL,                  -- Detailed Name of the Building
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_buildings_code` (`code`),
    UNIQUE KEY `uq_buildings_name` (`short_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tables for Room types, this will be used to define different types of rooms like Science Lab, Computer Lab, Sports Room etc.
  CREATE TABLE IF NOT EXISTS `sch_rooms_type` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `code` CHAR(10) NOT NULL,                         -- e.g., 'SCI_LAB','BIO_LAB','CRI_GRD','TT_ROOM','BDM_CRT', "HOUSE_ROOM"
    `short_name` varchar(30) NOT NULL,                -- e.g., 'Science Lab','Biology Lab','Cricket Ground','Table Tanis Room','Badminton Court'
    `name` varchar(100) NOT NULL,
    `required_resources` text DEFAULT NULL,           -- e.g., 'Microscopes, Lab Coats, Safety Goggles' for Science Lab
    `class_house_room` tinyint(1) NOT NULL DEFAULT 0, -- 1=Class House Room, 0=Other Room
    `room_count_in_category` smallint unsigned DEFAULT 0, -- Total Number of Rooms in this category
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_roomType_code` (`code`),
    UNIQUE KEY `uq_roomType_shortName` (`short_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Room Coding format is - 2 Digit for Buildings(10-99), 1 Digit-Building Floor(G,F,S,T,F / A,B,C,D,E), & Last 3 Character defin Class+Section (09A,10A,12B)
  CREATE TABLE IF NOT EXISTS `sch_rooms` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `building_id` int unsigned NOT NULL,      -- FK to 'sch_buildings' table
    `room_type_id` int NOT NULL,              -- FK to 'sch_rooms_type' table
    `code` CHAR(20) NOT NULL,                 -- e.g., '11G-10A','12F-11A','11S-12A' and so on (This will be used for Timetable)
    `short_name` varchar(50) NOT NULL,        -- e.g., 'Junior Wing','Primary Wing','Middle Wing','Senior Wing','Administration Wings'
    `name` varchar(100) NOT NULL,
    `capacity` int unsigned DEFAULT NULL,               -- Seating Capacity of the Room
    `max_limit` int unsigned DEFAULT NULL,              -- Maximum Limit of the Room, Maximum how many students can accomodate in the room
    `resource_tags` text DEFAULT NULL,                  -- e.g., 'Projector, Smart Board, AC, Lab Equipment' etc.
    `can_host_lecture` TINYINT(1) NOT NULL DEFAULT 0,   -- Seats + Writing Surface
    `can_host_practical` TINYINT(1) NOT NULL DEFAULT 0, -- Seats + Writing Surface + Lab Equipment
    `can_host_exam` TINYINT(1) NOT NULL DEFAULT 0,      -- Seats + Writing Surface + Exam Equipment
    `can_host_activity` TINYINT(1) NOT NULL DEFAULT 0,  -- Open space for movement
    `can_host_sports` TINYINT(1) NOT NULL DEFAULT 0,    -- Specific for PE/Games
    `room_available_from_date` DATE DEFAULT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_rooms_code` (`code`),
    UNIQUE KEY `uq_rooms_shortName` (`short_name`),
    CONSTRAINT `fk_rooms_buildingId` FOREIGN KEY (`building_id`) REFERENCES `sch_buildings` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_rooms_roomTypeId` FOREIGN KEY (`room_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ----------------------------------------------------------------------------------------------------------------------
  -- Change Log :
  -- ----------------------------------------------------------------------------------------------------------------------
  -- 1. Add `room_count_in_category` column to `sch_rooms_type` table
  -- 2. Add `can_host_lecture`, `can_host_practical`, `can_host_exam`, `can_host_activity`, `can_host_sports` columns to `sch_rooms` table
  -- 3. Add `room_available_from_date` column to `sch_rooms` table  
  
 -- ===========================================================================
 -- 3.5 - EMPLOYEE SETUP SUB-MODULE (sch)
 -- ===========================================================================

  -- Teacher table will store additional information about teachers
  CREATE TABLE IF NOT EXISTS `sch_employees` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` INT UNSIGNED NOT NULL,  -- fk to sys_users.id
    -- Employee id details
    `emp_code` VARCHAR(20) NOT NULL,     -- Employee Code (Unique code for each user) (This will be used for QR Code)
    `emp_id_card_type` ENUM('QR','RFID','NFC','Barcode') NOT NULL DEFAULT 'QR',
    `emp_smart_card_id` VARCHAR(100) DEFAULT NULL,       -- RFID/NFC Tag ID
    -- 
    `is_teacher` TINYINT(1) NOT NULL DEFAULT 0,
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
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `teachers_emp_code_unique` (`emp_code`),
    KEY `teachers_user_id_foreign` (`user_id`),
    CONSTRAINT `fk_teachers_userId` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `sch_employees_profile` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id` INT UNSIGNED NOT NULL,              -- FK to sch_employees.id
    `user_id` INT UNSIGNED NOT NULL,                  -- FK to sys_users.id
    `role_id` INT UNSIGNED NOT NULL,                  -- FK to employee_roles table (Principal, Accountant, Admin, etc.)
    `department_id` INT UNSIGNED DEFAULT NULL,        -- FK to sch_departments (Administration, Accounts, IT, etc.)
    -- Core Competencies & Qualifications
    `specialization_area` VARCHAR(100) DEFAULT NULL,     -- e.g., Finance Management, HR Administration, IT Infrastructure
    `qualification_level` VARCHAR(50) DEFAULT NULL,      -- e.g., Bachelor's, Master's, Certified Accountant
    `qualification_field` VARCHAR(100) DEFAULT NULL,     -- e.g., Business Administration, Computer Science
    `certifications` JSON DEFAULT NULL,                  -- JSON array of certifications: ["CPA", "CISSP", "PMP"]
    -- Work Capacity & Availability
    `work_hours_daily` DECIMAL(4,2) DEFAULT 8.0,         -- Standard daily work hours
    `max_hours_daily` DECIMAL(4,2) DEFAULT 10.0,         -- Maximum daily work hours
    `work_hours_weekly` DECIMAL(5,2) DEFAULT 40.0,       -- Standard weekly work hours
    `max_hours_weekly` DECIMAL(5,2) DEFAULT 50.0,        -- Maximum weekly work hours
    `preferred_shift` ENUM('morning', 'evening', 'flexible') DEFAULT 'morning',
    `is_full_time` TINYINT(1) DEFAULT 1,                 -- 1=Full-time, 0=Part-time
    -- Skills & Responsibilities (JSON for flexibility)
    `core_responsibilities` JSON DEFAULT NULL,           -- e.g., ["budget_management", "staff_supervision", "policy_implementation"]
    `technical_skills` JSON DEFAULT NULL,                -- e.g., ["quickbooks", "ms_expert", "erp_systems"]
    `soft_skills` JSON DEFAULT NULL,                     -- e.g., ["leadership", "communication", "problem_solving"]
    -- Performance & Experience
    `experience_months` SMALLINT UNSIGNED DEFAULT NULL,  -- Relevant experience in months
    `performance_rating` TINYINT UNSIGNED DEFAULT NULL,  -- rating out of (1 to 10)
    `last_performance_review` DATE DEFAULT NULL,
    -- Administrative Controls
    `security_clearance_done` TINYINT(1) DEFAULT 0,
    `reporting_to` INT UNSIGNED DEFAULT NULL,         -- FK to sch_employees.id (who they report to)
    `can_approve_budget` TINYINT(1) DEFAULT 0,
    `can_manage_staff` TINYINT(1) DEFAULT 0,
    `can_access_sensitive_data` TINYINT(1) DEFAULT 0,
    -- Additional Details
    `assignment_meta` JSON DEFAULT NULL,                 -- e.g., { "previous_role": "Assistant Principal", "achievements": ["System Upgrade 2023"] }
    `notes` TEXT DEFAULT NULL,
    `effective_from` DATE DEFAULT NULL,
    `effective_to` DATE DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_employee_role_active` (`employee_id`, `role_id`, `effective_to`),
    -- Foreign Key Constraints
    CONSTRAINT `fk_employeeProfile_employeeId` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`),
    CONSTRAINT `fk_employeeProfile_roleId` FOREIGN KEY (`role_id`) REFERENCES `sch_employee_roles` (`id`),
    CONSTRAINT `fk_employeeProfile_departmentId` FOREIGN KEY (`department_id`) REFERENCES `sch_departments` (`id`),
    CONSTRAINT `fk_employeeProfile_reportingTo` FOREIGN KEY (`reporting_to`) REFERENCES `sch_employees` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Teacher Profile table will store detailed proficiency to teach specific subjects, study formats, and classes
  CREATE TABLE IF NOT EXISTS `sch_teacher_profile` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id` INT UNSIGNED NOT NULL,             -- FK sch_employees.id
    `user_id` INT UNSIGNED NOT NULL,                 -- FK sys_users.id
    `role_id` INT UNSIGNED NOT NULL,                 -- FK to   Teacher / Principal / etc.
    `department_id` INT UNSIGNED NOT NULL,           -- sch_department.id 
    `designation_id` INT UNSIGNED NOT NULL,          -- sch_designation.id
    `teacher_house_room_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_rooms.id
    -- Employment nature & capability
    `is_full_time` TINYINT(1) DEFAULT 1,
    `preferred_shift` INT UNSIGNED DEFAULT NULL,    -- FK to sch_shift.id
    `capable_handling_multiple_classes` TINYINT(1) DEFAULT 0,  -- Is he capable of handling un-assigned classes
    `can_be_used_for_substitution` TINYINT(1) DEFAULT 1,
    -- Skills & Responsibilities (JSON for flexibility)
    `certified_for_lab` TINYINT(1) DEFAULT 0,          -- allowed to conduct practicals
    `is_proficient_with_computer` TINYINT(1) DEFAULT 0,
    `can_manage_staff` TINYINT(1) DEFAULT 0,
    `special_skill_area` VARCHAR(100) DEFAULT NULL,
    `soft_skills` JSON DEFAULT NULL,                             -- e.g., ["leadership", "communication", "problem_solving"]
    `assignment_meta` JSON DEFAULT NULL,                         -- e.g. { "qualification": "M.Sc Physics", "experience": "7 years" }
    -- LOAD & SCHEDULING CONSTRAINTS
    `max_available_periods_weekly` TINYINT UNSIGNED DEFAULT 48,  -- Manual Entry
    `min_available_periods_weekly` TINYINT UNSIGNED DEFAULT 36,  -- Manual Entry
    `max_allocated_periods_weekly` TINYINT UNSIGNED DEFAULT 1,   -- Auto Calculated (Count of Classes+Subject_Study_format allocated)
    `min_allocated_periods_weekly` TINYINT UNSIGNED DEFAULT 1,   -- Auto Calculated (Count of Classes+Subject_Study_format allocated)
    `can_be_split_across_sections` TINYINT(1) DEFAULT 0,         -- Manual Entry
    -- Performance & compliance
    `min_teacher_availability_score` DECIMAL(7,2) UNSIGNED DEFAULT 1,  -- Percentage of available teachers for this Class Group (Will capture from Teachers profile)
    `max_teacher_availability_score` DECIMAL(7,2) UNSIGNED DEFAULT 1,  -- Percentage of available teachers for this Class Group (Will capture from Teachers profile)
    `performance_rating` TINYINT UNSIGNED DEFAULT NULL,                -- Manual Entry rating out of (1 to 10)
    `last_performance_review` DATE DEFAULT NULL,                       -- Manual Entry
    `security_clearance_done` TINYINT(1) DEFAULT 0,                    -- Manual Entry
    `reporting_to` INT UNSIGNED DEFAULT NULL,                          -- Manual Entry
    `can_access_sensitive_data` TINYINT(1) DEFAULT 0,                  -- Manual Entry
    `notes` TEXT NULL,                                                 -- Manual Entry
    `effective_from` DATE DEFAULT NULL,                                -- Manual Entry. (Joining date)
    `effective_to` DATE DEFAULT NULL,                                  -- Manual Entry. (Leaving Date)
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_teacher_employee` (`employee_id`),
    CONSTRAINT `fk_teacher_employee` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`),
    CONSTRAINT `fk_teacher_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`),
    CONSTRAINT `fk_teacher_role` FOREIGN KEY (`role_id`) REFERENCES `sch_employee_roles` (`id`),
    CONSTRAINT `fk_teacher_department` FOREIGN KEY (`department_id`) REFERENCES `sch_departments` (`id`),
    CONSTRAINT `fk_teacher_designation` FOREIGN KEY (`designation_id`) REFERENCES `sch_designations` (`id`),
    CONSTRAINT `fk_teacher_reporting_to` FOREIGN KEY (`reporting_to`) REFERENCES `sch_employees` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- 1. there will be only One record per Teacher 

  CREATE TABLE IF NOT EXISTS `sch_teacher_capabilities` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- CORE RELATIONSHIP
    `teacher_profile_id` INT UNSIGNED NOT NULL,             -- FK sch_teacher_profile.id
    `class_id` INT UNSIGNED NOT NULL,                       -- FK sch_classes.id
    -- `section_id` INT UNSIGNED DEFAULT NULL,              -- FK sch_sections.id (NULL = all sections)
    `subject_study_format_id` INT UNSIGNED NOT NULL,        -- FK sch_subject_study_format_jnt.id
    -- TEACHING STRENGTH
    `proficiency_percentage` TINYINT UNSIGNED DEFAULT NULL, -- 1–100
    `teaching_experience_months` SMALLINT UNSIGNED DEFAULT NULL,
    `is_primary_subject` TINYINT(1) NOT NULL DEFAULT 1,     -- 1=Yes, 0=No
    `competancy_level` ENUM('Facilitator','Basic','Intermediate','Advanced','Expert') DEFAULT 'Basic',  -- Facilitator - If No Teaching Experience but can manage.
    -- PRIORITY MATRIX INTELLIGENCE
    `priority_order` INT UNSIGNED DEFAULT NULL,              -- Priority Order of the Teacher for the Class+Subject+Study_Format
    `priority_weight` TINYINT UNSIGNED DEFAULT NULL,         -- manual / computed weight (1–10) (Even if teachers are available, how important is THIS activity to the school?)
    `scarcity_index` TINYINT UNSIGNED DEFAULT NULL,          -- 1=abundant, 10=very rare
    `is_hard_constraint` TINYINT(1) DEFAULT 0,               -- if true cannot be voilated e.g. Physics Lab teacher for Class 12
    `allocation_strictness` ENUM('hard','medium','soft') DEFAULT 'medium', -- e.g. Senior Maths teacher - Hard, Preferred English teacher - Medium, Art / Sports / Activity - Soft
    -- GOVERNANCE & OVERRIDE
    `override_priority` TINYINT UNSIGNED DEFAULT NULL,       -- admin override
    `override_reason` VARCHAR(255) DEFAULT NULL,
    -- AI / HISTORICAL FEEDBACK
    `historical_success_ratio` TINYINT UNSIGNED DEFAULT NULL, -- 1–100 (sessions_completed_without_change / total_sessions_allocated ) * 100)
    `last_allocation_score` TINYINT UNSIGNED DEFAULT NULL,    -- last run score
    -- EFFECTIVITY & STATUS
    `effective_from` DATE DEFAULT NULL,
    -- `effective_to` DATE DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `active_flag` tinyint(1) GENERATED ALWAYS AS ((case when (`is_active` = 1) then '1' else NULL end)) STORED,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY `uq_teacher_capability` (`teacher_profile_id`, `class_id`, `subject_study_format_id`, `active_flag`),
    CONSTRAINT `fk_tc_teacher_profile` FOREIGN KEY (`teacher_profile_id`) REFERENCES `sch_teacher_profile`(id) ON DELETE CASCADE,
    CONSTRAINT `fk_tc_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(id),
    CONSTRAINT `fk_tc_subject_study_format` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt`(id)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
    CONSTRAINT `fk_vehicle_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`id`) ON DELETE CASCADE,
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

	-- =======================================================================
	-- ROUTE SCHEDULE & DRIVER ASSIGNMENT
	-- =======================================================================

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

	-- =======================================================================
	-- TRIPS
	-- =======================================================================

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

	-- =======================================================================
	-- DRIVER ATTENDANCE
	-- =======================================================================

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
    FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`attendance_status`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE CASCADE
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

	-- =======================================================================
	-- STUDENT ALLOCATION
	-- =======================================================================

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
    CONSTRAINT `fk_sa_pickupRoute` FOREIGN KEY (`pickup_route_id`) REFERENCES `tpt_route`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_dropRoute` FOREIGN KEY (`drop_route_id`) REFERENCES `tpt_route`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_pickup` FOREIGN KEY (`pickup_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_drop` FOREIGN KEY (`drop_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- =======================================================================
	-- TRANSPORT FEE
	-- =======================================================================

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

	-- =======================================================================
	-- FUEL & MAINTENANCE
	-- =======================================================================

	-- Single Screen - 5 tab (Fuel, Inspection, Service Request, Maintenance, Approval)

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
	-- Condition:
    -- 1. New Entry Can not be created in 'tpt_vehicle_maintenance' table. Only Edit of existing entry is allowed.
    -- 2. Approval of Both the Tables should be done by Authorised Person in "Approval" Tab.
    -- 3. Once Maintenance Entry is Approved by Authorised Person, it will create a entry in 'vnd_vendor_bill_due_for_payment' table.

	-- =======================================================================
	-- TRIP INCIDENTS & ALERTS
	-- =======================================================================

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

	-- ---------------------------------------------------------------------------------------------------------------
	-- New Tables
	-- ---------------------------------------------------------------------------------------------------------------

	-- =======================================================================
	-- STUDENT BOARD/UN-BOARD EVENTS
	-- =======================================================================

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
    CONSTRAINT `fk_sel_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sel_studentSession` FOREIGN KEY (`student_session_id`) REFERENCES `std_student_sessions_jnt`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sel_boardingRoute` FOREIGN KEY (`boarding_route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sel_boardingTrip` FOREIGN KEY (`boarding_trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sel_boardingStop` FOREIGN KEY (`boarding_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sel_unboardingRoute` FOREIGN KEY (`unboarding_route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sel_unboardingTrip` FOREIGN KEY (`unboarding_trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sel_unboardingStop` FOREIGN KEY (`unboarding_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sel_device` FOREIGN KEY (`device_id`) REFERENCES `tpt_attendance_device`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- =======================================================================
	-- NOTIFICATIONS & LOGS
	-- =======================================================================

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
    CONSTRAINT `fk_nl_studentSession` FOREIGN KEY (`student_session_id`) REFERENCES `std_student_sessions_jnt`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_nl_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_nl_stop` FOREIGN KEY (`boarding_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- -------------------------------------------------------------------------------------------------------------------
	-- New Conditions:
	-- 1. When Bus will complete the Trip and register it's Trip completion in the System. Someone (Authorise Person) will Approve the Trip Completion. 
	-- 2. Application will check the Status of "trip_usage_needs_to_be_updated_into_vendor_usage_log" variable in "sch_settings" table.
	-- 3. If "trip_usage_needs_to_be_updated_into_vendor_usage_log" is True, then application will update the 'vnd_usage_logs' with the Trip Usage.
	-- -------------------------------------------------------------------------------------------------------------------
	-- Change on 29th Dec 2025:
	-- 1. Enhanced Table tpt_attendance_device to have unique device_uuid for each user.
	-- 2. Add New Table tpt_student_boarding_log to track the Boarding and Unboarding of Students.
	-- 3. Add New Table tpt_notification_log to track the Notifications sent to Students.
	-- -------------------------------------------------------------------------------------------------------------------
	-- Change on 31st Dec 2025:
	-- 1. Changed the UNIQUE KEY `uq_pickupPointRoute_shift_pickupPoint` (`shift_id`,`route_id`,`pickup_point_id`), to `uq_pickupPointRoute_shift_pickupPoint` (`route_id`,`pickup_point_id`),
	--    to make sure one Route can have multiple Pickup Points but One Route can be allocate only in one Shift.
	-- 2. Change filed `route_id` to `pickup_route_id` in tpt_student_route_allocation_jnt
	-- 3. Add filed `drop_route_id` in tpt_student_route_allocation_jnt
	-- 4. Enhanced Table tpt_student_boarding_log to track the Boarding and Unboarding of Students.
	-- 5. Enhanced Table tpt_student_route_allocation_jnt to have `pickup_route_id` and `drop_route_id`.
	-- 6. Enhanced Table tpt_route to have `pickup_drop` field to define if the Route is for Pickup or Drop, can not be for Both.

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

	-- =======================================================================
	-- ITEM MASTER (Services & Products)
	-- =======================================================================

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

	-- =======================================================================
	-- VENDOR AGREEMENTS (Contracts)
	-- =======================================================================

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

	-- =======================================================================
	-- AGREEMENT ITEMS (Line Items & Rates)
	-- =======================================================================

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

	-- =======================================================================
	-- SERVICE/PRODUCT USAGE LOG (Analytics Hook)
	-- =======================================================================
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

	-- =======================================================================
	-- VENDOR INVOICES (Bill)
	-- =======================================================================

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


	-- =======================================================================
	-- VENDOR PAYMENTS
	-- =======================================================================

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
  -- Condition: 
  -- 1. How to calculate all required fields is mentioned in '/Complaint_Module/Screen_Design/cmp_AI_Calc_Logic.md'
  -- The Approach We will be using is Laravel (ERP) → Python ML Microservice → Prediction → Store in MySQL

-- ===========================================================================
-- 7-NOTIFICATION MODULE (ntf)
-- ===========================================================================

	-- -----------------------------------------------------------------
	-- TABLE: ntf_channel_master
	-- Purpose: Defines available notification channels
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `ntf_channel_master` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `tenant_id` INT UNSIGNED NOT NULL COMMENT 'Multi-tenant isolation',
    `code` VARCHAR(20) NOT NULL COMMENT 'EMAIL, SMS, WHATSAPP, IN_APP, PUSH',
    `name` VARCHAR(50) NOT NULL COMMENT 'Display name',
    `description` VARCHAR(255) NULL,
    `channel_type` ENUM('IMMEDIATE', 'BULK', 'TRANSACTIONAL') DEFAULT 'TRANSACTIONAL',
    `priority_order` TINYINT DEFAULT 5 COMMENT '1-Highest, 10-Lowest',
    `max_retry` INT DEFAULT 3,
    `retry_delay_minutes` INT DEFAULT 5,
    `rate_limit_per_minute` INT DEFAULT 100,
    `daily_limit` INT DEFAULT 10000,
    `monthly_limit` INT DEFAULT 100000,
    `cost_per_unit` DECIMAL(10,4) DEFAULT 0.0000,
    `fallback_channel_id` INT UNSIGNED NULL COMMENT 'Auto-fallback on failure',
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_ntf_channel_tenant` (`tenant_id`),
    INDEX `idx_ntf_channel_code` (`code`),
    CONSTRAINT `uq_ntf_channel_tenant_code` UNIQUE (`tenant_id`, `code`),
    CONSTRAINT `fk_ntf_channel_fallback` FOREIGN KEY (`fallback_channel_id`) REFERENCES `ntf_channel_master`(`id`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

	-- -----------------------------------------------------------------
	-- TABLE: ntf_provider_master
	-- Purpose: External service providers configuration
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `ntf_provider_master` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `tenant_id` INT UNSIGNED NOT NULL,
    `channel_id` INT UNSIGNED NOT NULL,
    `provider_name` VARCHAR(50) NOT NULL COMMENT 'Twilio, MSG91, AWS SES, Meta, Firebase',
    `provider_type` ENUM('PRIMARY', 'SECONDARY', 'BACKUP') DEFAULT 'PRIMARY',
    `api_endpoint` VARCHAR(500) NULL,
    `api_key_encrypted` TEXT NULL COMMENT 'Encrypted API credentials',
    `api_secret_encrypted` TEXT NULL,
    `from_address` VARCHAR(255) NULL COMMENT 'Sender email/phone/ID',
    `configuration` JSON NULL COMMENT 'Provider-specific config',
    `priority` TINYINT DEFAULT 5 COMMENT '1-Highest, 10-Lowest',
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_ntf_provider_channel` (`channel_id`),
    CONSTRAINT `fk_ntf_provider_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

		-- -----------------------------------------------------------------
	-- TABLE: ntf_notifications
	-- Purpose: Core notification request registry
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `ntf_notifications` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `tenant_id` INT UNSIGNED NOT NULL,
    `notification_uuid` CHAR(36) NOT NULL COMMENT 'Public-facing unique ID',
    `source_module` VARCHAR(50) NOT NULL,
    `source_record_id` INT UNSIGNED NULL COMMENT 'ID in source module',
    `notification_event` VARCHAR(50) NOT NULL,
    `notification_type` ENUM('TRANSACTIONAL', 'PROMOTIONAL', 'ALERT', 'REMINDER', 'DIGEST') DEFAULT 'TRANSACTIONAL',
    `title` VARCHAR(255) NOT NULL,
    `description` VARCHAR(512) NULL,
    `template_id` INT UNSIGNED NULL,
    `priority_id` INT UNSIGNED NOT NULL,
    `confidentiality_level_id` INT UNSIGNED NOT NULL,
    -- Scheduling
    `schedule_type` ENUM('IMMEDIATE', 'SCHEDULED', 'RECURRING', 'TRIGGERED') DEFAULT 'IMMEDIATE',
    `scheduled_at` DATETIME NULL,
    `schedule_timezone` VARCHAR(50) DEFAULT 'UTC',
    -- Recurring
    `recurring_pattern` ENUM('NONE', 'HOURLY', 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY', 'CUSTOM') DEFAULT 'NONE',
    `recurring_expression` VARCHAR(100) NULL COMMENT 'Cron expression or RRULE',
    `recurring_end_at` DATETIME NULL,
    `recurring_end_count` INT NULL,
    `recurring_executed_count` INT DEFAULT 0 COMMENT 'Calculated',
    -- Expiry
    `expires_at` DATETIME NULL,
    -- Tracking
    `total_recipients` INT DEFAULT 0 COMMENT 'Calculated from ntf_resolved_recipients',
    `sent_count` INT DEFAULT 0 COMMENT 'Calculated',
    `failed_count` INT DEFAULT 0 COMMENT 'Calculated',
    `delivered_count` INT DEFAULT 0 COMMENT 'Calculated',
    `read_count` INT DEFAULT 0 COMMENT 'Calculated',
    `click_count` INT DEFAULT 0 COMMENT 'Calculated',
    -- Cost
    `estimated_cost` DECIMAL(12,4) DEFAULT 0.0000 COMMENT 'Calculated',
    `actual_cost` DECIMAL(12,4) DEFAULT 0.0000 COMMENT 'Calculated',
    -- Status
    `notification_status_id` INT UNSIGNED NOT NULL COMMENT 'DRAFT, SCHEDULED, PROCESSING, COMPLETED, PARTIAL, FAILED, CANCELLED, EXPIRED',
    `is_manual` TINYINT(1) DEFAULT 0 COMMENT 'Manually created',
    `created_by` INT UNSIGNED NOT NULL,
    `approved_by` INT UNSIGNED NULL,
    `approved_at` DATETIME NULL,
    `processed_at` DATETIME NULL,
    `completed_at` DATETIME NULL,
    -- Audit
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_ntf_tenant` (`tenant_id`),
    INDEX `idx_ntf_schedule` (`scheduled_at`, `notification_status_id`),
    INDEX `idx_ntf_source` (`source_module`, `source_record_id`),
    INDEX `idx_ntf_uuid` (`notification_uuid`),
    INDEX `idx_ntf_status` (`notification_status_id`),
    INDEX `idx_ntf_event` (`notification_event`),
    CONSTRAINT `fk_ntf_priority` FOREIGN KEY (`priority_id`) REFERENCES `sys_dropdown_table`(`id`),
    CONSTRAINT `fk_ntf_confidentiality` FOREIGN KEY (`confidentiality_level_id`) REFERENCES `sys_dropdown_table`(`id`),
    CONSTRAINT `fk_ntf_template` FOREIGN KEY (`template_id`) REFERENCES `ntf_templates`(`id`),
    CONSTRAINT `fk_ntf_notification_status` FOREIGN KEY (`notification_status_id`) REFERENCES `sys_dropdown_table`(`id`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

	-- -----------------------------------------------------------------
	-- TABLE: ntf_notification_channels
	-- Purpose: Channel assignments per notification
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `ntf_notification_channels` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `notification_id` INT UNSIGNED NOT NULL,
    `channel_id` INT UNSIGNED NOT NULL,
    `provider_id` INT UNSIGNED NULL,
    `template_id` INT UNSIGNED NULL COMMENT 'Override template',
    `priority_order` TINYINT DEFAULT 5,
    `sending_order` INT DEFAULT 1 COMMENT 'Sequence for fallback',
    `status_id` INT UNSIGNED NOT NULL,
    `scheduled_at` DATETIME NULL,
    `sent_at` DATETIME NULL,
    `failure_reason` VARCHAR(512) NULL,
    `retry_count` INT DEFAULT 0,
    `max_retry` INT DEFAULT 3,
    `next_retry_at` DATETIME NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE KEY `uq_notification_channel_template` (`notification_id`, `channel_id`, `template_id`),
    INDEX `idx_ntf_channel_status` (`status_id`),
    INDEX `idx_ntf_channel_retry` (`next_retry_at`, `retry_count`),
    CONSTRAINT `fk_ntf_channel_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
    CONSTRAINT `fk_ntf_channel_type` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
    CONSTRAINT `fk_ntf_channel_provider` FOREIGN KEY (`provider_id`) REFERENCES `ntf_provider_master`(`id`),
    CONSTRAINT `fk_ntf_channel_template` FOREIGN KEY (`template_id`) REFERENCES `ntf_templates`(`id`),
    CONSTRAINT `fk_ntf_channel_status` FOREIGN KEY (`status_id`) REFERENCES `sys_dropdown_table`(`id`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

	-- -----------------------------------------------------------------
	-- TABLE: ntf_target_groups
	-- Purpose: Reusable user segments/target groups
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `ntf_target_groups` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `tenant_id` INT UNSIGNED NOT NULL,
    `group_name` VARCHAR(100) NOT NULL,
    `group_code` VARCHAR(50) NOT NULL,
    `description` VARCHAR(255) NULL,
    `group_type` ENUM('STATIC', 'DYNAMIC') DEFAULT 'STATIC',
    `dynamic_query` TEXT NULL COMMENT 'JSON/SQL for dynamic groups',
    `total_members` INT DEFAULT 0 COMMENT 'Calculated',
    `last_refreshed_at` DATETIME NULL,
    `is_system_group` TINYINT(1) DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_by` INT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    
    UNIQUE KEY `uq_target_group_tenant_code` (`tenant_id`, `group_code`),
    INDEX `idx_target_group_type` (`group_type`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

	-- -----------------------------------------------------------------
	-- TABLE: ntf_notification_targets
	-- Purpose: Target definitions for notifications
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `ntf_notification_targets` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `notification_id` INT UNSIGNED NOT NULL,
    `target_type_id` INT UNSIGNED NOT NULL,
    `target_group_id` INT UNSIGNED NULL COMMENT 'Reusable group',
    `target_table_name` VARCHAR(60) DEFAULT NULL,
    `target_selected_id` INT UNSIGNED NULL,
    `target_condition` JSON NULL COMMENT 'Additional filters',
    `estimated_count` INT NULL COMMENT 'Pre-resolution estimate',
    `actual_count` INT NULL COMMENT 'Post-resolution count',
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    
    INDEX `idx_ntf_target_lookup` (`target_type_id`, `target_selected_id`),
    INDEX `idx_ntf_target_group` (`target_group_id`),
    
    CONSTRAINT `fk_ntf_target_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
    CONSTRAINT `fk_ntf_target_type` FOREIGN KEY (`target_type_id`) REFERENCES `sys_dropdown_table`(`id`),
    CONSTRAINT `fk_ntf_target_group` FOREIGN KEY (`target_group_id`) REFERENCES `ntf_target_groups`(`id`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

	-- -----------------------------------------------------------------
	-- TABLE: ntf_user_devices
	-- Purpose: Push notification device registry
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `ntf_user_devices` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `device_type` ENUM('ANDROID', 'IOS', 'WEB', 'DESKTOP') NOT NULL,
    `device_token` VARCHAR(512) NOT NULL,
    `device_name` VARCHAR(100) NULL,
    `app_version` VARCHAR(20) NULL,
    `os_version` VARCHAR(20) NULL,
    `last_active_at` DATETIME NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY `uq_user_device_token` (`user_id`, `device_token`),
    INDEX `idx_device_token` (`device_token`),
    CONSTRAINT `fk_ntf_device_user` FOREIGN KEY (`user_id`) REFERENCES `sys_user`(`id`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

	-- -----------------------------------------------------------------
	-- TABLE: ntf_user_preferences
	-- Purpose: Enhanced user notification preferences
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `ntf_user_preferences` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `channel_id` INT UNSIGNED NOT NULL,
    `is_enabled` TINYINT(1) DEFAULT 1,
    `is_opted_in` TINYINT(1) DEFAULT 1 COMMENT 'GDPR consent',
    `opted_in_at` DATETIME NULL,
    `opted_out_at` DATETIME NULL,
    `contact_value` VARCHAR(255) NULL COMMENT 'Override email/phone',
    `quiet_hours_start` TIME NULL,
    `quiet_hours_end` TIME NULL,
    `quiet_hours_timezone` VARCHAR(50) DEFAULT 'UTC',
    `daily_digest` TINYINT(1) DEFAULT 0,
    `digest_time` TIME NULL,
    `priority_threshold_id` INT UNSIGNED NULL COMMENT 'Min priority to receive',
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    
    UNIQUE KEY `uq_user_channel` (`user_id`, `channel_id`),
    INDEX `idx_pref_user` (`user_id`, `is_enabled`),
    
    CONSTRAINT `fk_ntf_pref_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
    CONSTRAINT `fk_ntf_pref_priority` FOREIGN KEY (`priority_threshold_id`) REFERENCES `sys_dropdown_table`(`id`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

	-- -----------------------------------------------------------------
	-- TABLE: ntf_templates
	-- Purpose: Enhanced notification templates
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `ntf_templates` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `tenant_id` INT UNSIGNED NOT NULL,
    `template_code` VARCHAR(50) NOT NULL,
    `template_name` VARCHAR(100) NOT NULL,
    `channel_id` INT UNSIGNED NOT NULL,
    `template_version` INT DEFAULT 1,
    `subject` VARCHAR(255) NULL,
    `body` TEXT NOT NULL,
    `alt_body` TEXT NULL COMMENT 'Plain text version',
    `placeholders` JSON NULL COMMENT 'List of required placeholders',
    `language_code` VARCHAR(10) DEFAULT 'en',
    `media_id` INT UNSIGNED NULL,
    `is_system_template` TINYINT(1) DEFAULT 0,
    `approval_status` ENUM('DRAFT', 'PENDING', 'APPROVED', 'REJECTED', 'ARCHIVED') DEFAULT 'DRAFT',
    `approved_by` INT UNSIGNED NULL,
    `approved_at` DATETIME NULL,
    `effective_from` DATETIME NULL,
    `effective_to` DATETIME NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_by` INT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    
    UNIQUE KEY `uq_template_code_version` (`tenant_id`, `template_code`, `template_version`),
    INDEX `idx_template_channel` (`channel_id`),
    INDEX `idx_template_status` (`approval_status`),
    
    CONSTRAINT `fk_ntf_template_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
    CONSTRAINT `fk_ntf_template_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media`(`id`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

	-- -----------------------------------------------------------------
	-- TABLE: ntf_resolved_recipients
	-- Purpose: Final resolved recipient list with personalization
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `ntf_resolved_recipients` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `notification_id` INT UNSIGNED NOT NULL,
    `channel_id` INT UNSIGNED NOT NULL,
    `template_id` INT UNSIGNED NOT NULL,
    `notification_target_id` INT UNSIGNED NOT NULL,
    `user_preference_id` INT UNSIGNED NULL,
    `resolved_user_id` INT UNSIGNED NOT NULL,
    `device_id` INT UNSIGNED NULL COMMENT 'For push notifications',
    `recipient_address` VARCHAR(255) NULL COMMENT 'Resolved email/phone/ID',
    `personalized_subject` VARCHAR(500) NULL COMMENT 'Rendered with placeholders',
    `personalized_body` TEXT NULL COMMENT 'Rendered with placeholders',
    `personalization_data` JSON NULL COMMENT 'Placeholder values used',
    `priority` TINYINT DEFAULT 5,
    `batch_id` VARCHAR(36) NULL COMMENT 'For bulk processing',
    `batch_sequence` INT NULL,
    `is_processed` TINYINT(1) DEFAULT 0,
    `processed_at` DATETIME NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    
    INDEX `idx_ntf_recipient_notification` (`notification_id`, `is_processed`),
    INDEX `idx_ntf_recipient_user` (`resolved_user_id`),
    INDEX `idx_ntf_recipient_batch` (`batch_id`),
    INDEX `idx_ntf_recipient_address` (`recipient_address`),
    
    CONSTRAINT `fk_ntf_recipient_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
    CONSTRAINT `fk_ntf_recipient_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
    CONSTRAINT `fk_ntf_recipient_template` FOREIGN KEY (`template_id`) REFERENCES `ntf_templates`(`id`),
    CONSTRAINT `fk_ntf_recipient_preference` FOREIGN KEY (`user_preference_id`) REFERENCES `ntf_user_preferences`(`id`),
    CONSTRAINT `fk_ntf_recipient_target` FOREIGN KEY (`notification_target_id`) REFERENCES `ntf_notification_targets`(`id`),
    CONSTRAINT `fk_ntf_recipient_user` FOREIGN KEY (`resolved_user_id`) REFERENCES `sys_user`(`id`),
    CONSTRAINT `fk_ntf_recipient_device` FOREIGN KEY (`device_id`) REFERENCES `ntf_user_devices`(`id`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

	-- -----------------------------------------------------------------
	-- TABLE: ntf_delivery_queue
	-- Purpose: Queue management for notification sending
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `ntf_delivery_queue` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `resolved_recipient_id` INT UNSIGNED NOT NULL,
    `notification_id` INT UNSIGNED NOT NULL,
    `channel_id` INT UNSIGNED NOT NULL,
    `provider_id` INT UNSIGNED NOT NULL,
    `queue_status` ENUM('PENDING', 'PROCESSING', 'SENT', 'FAILED', 'RETRY', 'CANCELLED') DEFAULT 'PENDING',
    `priority` TINYINT DEFAULT 5,
    `scheduled_at` DATETIME NULL,
    `locked_by` VARCHAR(50) NULL COMMENT 'Worker ID',
    `locked_at` DATETIME NULL,
    `attempt_count` INT DEFAULT 0,
    `max_attempts` INT DEFAULT 3,
    `last_error` VARCHAR(512) NULL,
    `next_attempt_at` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_queue_status` (`queue_status`, `scheduled_at`, `priority`),
    INDEX `idx_queue_next_attempt` (`next_attempt_at`),
    INDEX `idx_queue_lock` (`locked_by`, `locked_at`),
    
    CONSTRAINT `fk_queue_recipient` FOREIGN KEY (`resolved_recipient_id`) REFERENCES `ntf_resolved_recipients`(`id`),
    CONSTRAINT `fk_queue_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
    CONSTRAINT `fk_queue_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
    CONSTRAINT `fk_queue_provider` FOREIGN KEY (`provider_id`) REFERENCES `ntf_provider_master`(`id`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

	-- -----------------------------------------------------------------
	-- TABLE: ntf_delivery_logs
	-- Purpose: Complete delivery audit trail
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `ntf_delivery_logs` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `notification_id` INT UNSIGNED NOT NULL,
    `channel_id` INT UNSIGNED NOT NULL,
    `resolved_recipient_id` INT UNSIGNED NOT NULL,
    `resolved_user_id` INT UNSIGNED NOT NULL,
    `provider_id` INT UNSIGNED NOT NULL,
    `delivery_status_id` INT UNSIGNED NOT NULL,
    `delivery_stage` ENUM('QUEUED', 'SENT', 'DELIVERED', 'READ', 'CLICKED', 'BOUNCED', 'COMPLAINT', 'UNSUBSCRIBED') DEFAULT 'SENT',
    `provider_message_id` VARCHAR(255) NULL,
    `delivered_at` DATETIME NULL,
    `read_at` DATETIME NULL,
    `clicked_at` DATETIME NULL,
    `bounced_at` DATETIME NULL,
    `complaint_at` DATETIME NULL,
    `response_code` VARCHAR(20) NULL,
    `response_payload` JSON NULL,
    `error_message` VARCHAR(512) NULL,
    `duration_ms` INT NULL COMMENT 'Delivery latency',
    `ip_address` VARCHAR(45) NULL COMMENT 'For read/click tracking',
    `user_agent` VARCHAR(255) NULL,
    `cost` DECIMAL(12,4) DEFAULT 0.0000,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_ntf_delivery_user` (`resolved_user_id`),
    INDEX `idx_ntf_delivery_status` (`delivery_status_id`, `delivery_stage`),
    INDEX `idx_ntf_delivery_provider_msg` (`provider_message_id`),
    INDEX `idx_ntf_delivery_notification` (`notification_id`),
    INDEX `idx_ntf_delivery_recipient` (`resolved_recipient_id`),
    INDEX `idx_ntf_delivery_timeline` (`delivered_at`, `read_at`, `clicked_at`),
    
    CONSTRAINT `fk_ntf_log_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
    CONSTRAINT `fk_ntf_log_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
    CONSTRAINT `fk_ntf_log_recipient` FOREIGN KEY (`resolved_recipient_id`) REFERENCES `ntf_resolved_recipients`(`id`),
    CONSTRAINT `fk_ntf_log_provider` FOREIGN KEY (`provider_id`) REFERENCES `ntf_provider_master`(`id`),
    CONSTRAINT `fk_ntf_log_status` FOREIGN KEY (`delivery_status_id`) REFERENCES `sys_dropdown_table`(`id`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

	-- -----------------------------------------------------------------
	-- TABLE: ntf_notification_threads
	-- Purpose: Group related notifications (conversations)
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `ntf_notification_threads` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `tenant_id` INT UNSIGNED NOT NULL,
    `thread_uuid` CHAR(36) NOT NULL,
    `thread_type` ENUM('CONVERSATION', 'DIGEST', 'BROADCAST') DEFAULT 'BROADCAST',
    `thread_subject` VARCHAR(255) NULL,
    `parent_thread_id` INT UNSIGNED NULL,
    `root_notification_id` INT UNSIGNED NULL,
    `total_notifications` INT DEFAULT 0 COMMENT 'Calculated',
    `participant_count` INT DEFAULT 0 COMMENT 'Calculated',
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_thread_uuid` (`thread_uuid`),
    INDEX `idx_thread_parent` (`parent_thread_id`),
    
    CONSTRAINT `fk_thread_parent` FOREIGN KEY (`parent_thread_id`) REFERENCES `ntf_notification_threads`(`id`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

	-- -----------------------------------------------------------------
	-- TABLE: ntf_notification_thread_members
	-- Purpose: Thread-notification association
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `ntf_notification_thread_members` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `thread_id` INT UNSIGNED NOT NULL,
    `notification_id` INT UNSIGNED NOT NULL,
    `sequence_order` INT DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY `uq_thread_notification` (`thread_id`, `notification_id`),
    CONSTRAINT `fk_thread_member_thread` FOREIGN KEY (`thread_id`) REFERENCES `ntf_notification_threads`(`id`),
    CONSTRAINT `fk_thread_member_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

	-- -----------------------------------------------------------------
	-- TABLE: ntf_schedule_audit
	-- Purpose: Track recurring notification executions
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `ntf_schedule_audit` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `notification_id` INT UNSIGNED NOT NULL,
    `scheduled_instance_id` INT UNSIGNED NULL COMMENT 'Child notification ID',
    `scheduled_execution_time` DATETIME NOT NULL,
    `actual_execution_time` DATETIME NULL,
    `execution_status` ENUM('PENDING', 'SUCCESS', 'FAILED', 'SKIPPED') DEFAULT 'PENDING',
    `error_message` VARCHAR(512) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX `idx_schedule_notification` (`notification_id`, `scheduled_execution_time`),
    CONSTRAINT `fk_schedule_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- =========================================================================
-- 8-TIMETABLE MODULE (tt)
-- =========================================================================

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
  --  SECTION 0: CONFIGURATION TABLES
  -- -------------------------------------------------

  -- This table is created in the School_Setup module but will will be shown & can be Modified in Timetable as well.
  -- This will be used in Lesson Planning for creating Schedule for all the Subjects for Entire Session
  CREATE TABLE IF NOT EXISTS `sch_academic_term` (
    `id` SMALLINT unsigned NOT NULL AUTO_INCREMENT,
    `academic_session_id` INT UNSIGNED NOT NULL,
    `academic_year_start_date` DATE NOT NULL,                        -- Academic Year Start Date (e.g., '2024-01-01')
    `academic_year_end_date` DATE NOT NULL,                          -- Academic Year End Date (e.g., '2024-12-31') 
    `total_terms_in_academic_session` TINYINT UNSIGNED NOT NULL,     -- Total Terms in an Academic Session -- e.g., 1, 2, 3, 4
    `term_ordinal` TINYINT UNSIGNED NOT NULL,                        -- Term Ordinal. -- e.g., 1, 2, 3, 4 (Short order in the Acedemic Term List)
    `term_code` VARCHAR(20) NOT NULL,                                -- Term Code. (e.g., 'SUMMER', 'WINTER', 'Q1', 'Q2', 'Q3', 'Q4')
    `term_name` VARCHAR(100) NOT NULL,                               -- Term Name. (e.g., 'Summer Term', 'Winter Term', 'QUATER - 1', 'QUATER - 2', 'QUATER - 3', 'QUATER - 4')
    `term_start_date` DATE NOT NULL,                                 -- Term Start Date  (e.g., '2024-01-01', '2024-02-01', '2024-03-01', '2024-04-01', '2024-05-01', '2024-06-01')
    `term_end_date` DATE NOT NULL,                                   -- Term Start Date  (e.g., '2024-01-01', '2024-02-01', '2024-03-01', '2024-04-01', '2024-05-01', '2024-06-01')
    `term_total_teaching_days` TINYINT UNSIGNED DEFAULT 5,           -- Total Teaching Days in a Term (Excluding Exam Days) (e.g., 1, 2, 3, 4, 5, 6)
    `term_total_exam_days` TINYINT UNSIGNED DEFAULT 2,               -- Total Exam Days in a Term for All Exam in a Term (Excluding Teaching Days) (e.g., 1, 2, 3, 4, 5, 6)
    `term_week_start_day` TINYINT UNSIGNED NOT NULL,                 -- Start Day of the Week (e.g., 1, 2, 3, 4, 5, 6)
    `term_total_periods_per_day` TINYINT UNSIGNED NOT NULL,          -- Total Periods per Day (e.g., 8, 10, 11) (This includes everything (Teaching Period+Lunch+Recess+Short Breaks))
    `term_total_teaching_periods_per_day` TINYINT UNSIGNED NOT NULL, -- Total Teaching Periods per Day
    `term_min_resting_periods_per_day` TINYINT UNSIGNED NOT NULL,    -- Minimum Resting Periods per Day between classes (e.g. 0,1,2)
    `term_max_resting_periods_per_day` TINYINT UNSIGNED NOT NULL,    -- Maximum Resting Periods per Day between classes (e.g. 0,1,2)
    `term_travel_minutes_between_classes` TINYINT UNSIGNED NOT NULL, -- Travel time (Min.) required between classes (e.g. 5,10,15)
    `is_current` BOOLEAN DEFAULT FALSE,
    `current_flag` tinyint(1) GENERATED ALWAYS AS ((case when (`is_current` = 1) then '1' else NULL end)) STORED,
    `settings_json` JSON,
    `is_active` BOOLEAN DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_AcademicTerm_currentFlag` (`current_flag`),
    UNIQUE KEY `uq_AcademicTerm_session_code` (`academic_session_id`, `term_code`),
    INDEX `idx_AcademicTerm_dates` (`start_date`, `end_date`),
    INDEX `idx_AcademicTerm_current` (`is_current`),
    FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Academic term/quarter/semester structure';
  -- Cindition:
    -- 1. May of the fields in above table will be used in Lesson & Syllabus Planning as well.


  -- Here we are setting what all Settings will be used for the Timetable Module
  -- Only Edit Functionality is require. No one can Add or Delete any record.
  -- In Edit also "key" can not be edit. In Edit "key" will not be display.
  CREATE TABLE IF NOT EXISTS `tt_config` (
    `id` SMALLINT unsigned NOT NULL AUTO_INCREMENT,
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

  -- Data Seed for tt_config
    -- INSERT INTO `tt_config` (`ordinal`,`key`,`key_name`,`value`,`value_type`,`description`,`additional_info`,`tenant_can_modify`,`mandatory`,`used_by_app`,`is_active`,`deleted_at`,`created_at`,`updated_at`) VALUES
    -- (1,'total_number_of_period_per_day', 'Total Number of Period per Day', '8', 'NUMBER', 'Total Periods per Day', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (2,'default_school_open_days_per_week', 'School Open Days per Week', '6', 'NUMBER', 'School Open Days per Week', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (3,'default_school_closed_days_per_week', 'School Closed Days per Week', '1', 'NUMBER', 'School Closed Days per Week', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (4,'default_number_of_short_breaks_daily_before_lunch', 'Number of Short Breaks Daily Before Lunch', '1', 'NUMBER', 'Number of Short Breaks Daily Before Lunch', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (5,'default_number_of_short_breaks_daily_after_lunch', 'Number of Short Breaks Daily After Lunch', '1', 'NUMBER', 'Number of Short Breaks Daily After Lunch', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (6,'default_total_number_of_short_breaks_daily', 'Total Number of Short Breaks Daily', '2', 'NUMBER', 'Total Number of Short Breaks Daily', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (7,'default_total_number_of_period_before_lunch', 'Total Number of Periods Before Lunch', '4', 'NUMBER', 'Total Number of Periods Before Lunch', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (8,'default_total_number_of_period_after_lunch', 'Total Number of Periods After Lunch', '4', 'NUMBER', 'Total Number of Periods After Lunch', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (9,'minimum_student_required_for_class_subgroup', 'Minimum Number of Student Required for Class Subgroup', '10', 'NUMBER', 'Minimum Number of Student Required for Class Subgroup', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (10,'maximum_student_required_for_class_subgroup', 'Maximum Number of Student Required for Class Subgroup', '25', 'NUMBER', 'Maximum Number of Student Required for Class Subgroup', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (11,'max_weekly_periods_can_be_allocated_to_teacher', 'Maximum No of Periods that can be allocated to Teacher per week', '8', 'NUMBER', 'Maximum No of Periods that can be allocated to Teacher per week', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
    -- (12,'min_weekly_periods_can_be_allocated_to_teacher', 'Minimum No of Periods that can be allocated to Teacher per week', '8', 'NUMBER', 'Minimum No of Periods that can be allocated to Teacher per week', NULL, 0, 1, 1, 1, NULL, NULL, NULL);
    -- (13,`week-start_day`, '1st Day of the Week', 'MONDAY', 'STRING', 'Which day will be consider as 1st Day of the Week', NULL, 0, 1, 1, 1, NULL, NULL, NULL);
    -- (14,)

  -- Timetable Generation Queue & Strategy Tables (For handling asynchronous timetable generation)
  CREATE TABLE IF NOT EXISTS `tt_generation_strategy` (
    `id` SMALLINT unsigned NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(20) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255) NULL,
    `algorithm_type` ENUM('RECURSIVE','GENETIC','SIMULATED_ANNEALING','TABU_SEARCH','HYBRID') DEFAULT 'RECURSIVE',
    `max_recursive_depth` INT UNSIGNED DEFAULT 14,         -- This will be used for the recursive algorithm
    `max_placement_attempts` INT UNSIGNED DEFAULT 2000,    -- This will be used for the recursive algorithm
    `tabu_size` INT UNSIGNED DEFAULT 100,                  -- This will be used for the tabu search algorithm
    `cooling_rate` DECIMAL(5,2) DEFAULT 0.95,              -- This will be used for the simulated annealing algorithm
    `population_size` INT UNSIGNED DEFAULT 50,             -- This will be used for the genetic algorithm
    `generations` INT UNSIGNED DEFAULT 100,                -- This will be used for the genetic algorithm
    `activity_sorting_method` ENUM('LESS_TEACHER_FIRST','DIFFICULTY_FIRST','CONSTRAINT_COUNT','DURATION_FIRST','RANDOM') DEFAULT 'LESS_TEACHER_FIRST',
    `timeout_seconds` INT UNSIGNED DEFAULT 300,            -- This will be used for the recursive algorithm
    `parameters_json` JSON NULL,                           -- This will be used for all the algorithm
    `is_default` TINYINT(1) DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_generation_strategy_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Timetable generation algorithms and parameters';

  -- -------------------------------------------------
  --  SECTION 1: MASTER TABLES
  -- -------------------------------------------------

  -- Here we are setting what all Shifts will be used for the Timetable Module 'MORNING', 'TODLER', 'AFTERNOON', 'EVENING'
  CREATE TABLE IF NOT EXISTS `tt_shift` (
    `id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(20) NOT NULL,               -- e.g., 'MORNING', 'AFTERNOON', 'EVENING'
    `name` VARCHAR(100) NOT NULL,              -- e.g., 'Morning', 'Afternoon', 'Evening'
    `description` VARCHAR(255) DEFAULT NULL,
    `default_start_time` TIME DEFAULT NULL,
    `default_end_time` TIME DEFAULT NULL,
    `ordinal` TINYINT UNSIGNED DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_shift_ordinal` (`ordinal`),
    UNIQUE KEY `uq_shift_code` (`code`),
    UNIQUE KEY `uq_shift_name` (`name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Here we are setting what all Types of Days will be used for the School 'WORKING','HOLIDAY','EXAM','SPECIAL'
  CREATE TABLE IF NOT EXISTS `tt_day_type` (
    `id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(20) NOT NULL,                      -- e.g., 'STUDY','HOLIDAY','EXAM','SPECIAL','PTM_DAY','SPORTS_DAY','ANNUAL_DAY'
    `name` VARCHAR(100) NOT NULL,                     -- e.g., 'Study Day','Holiday','Exam','Special Day','Parent Teacher Meeting','Sports Day','Annual Day'
    `description` VARCHAR(255) DEFAULT NULL,
    `is_working_day` TINYINT(1) NOT NULL DEFAULT 1,   -- 1 for working day, 0 for non-working day
    `reduced_periods` TINYINT(1) NOT NULL DEFAULT 0,  -- (Does school have less periods on this day? e.g. On Sports day may only 4 Periods)
    `ordinal` TINYINT UNSIGNED DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_daytype_ordinal` (`ordinal`), 
    UNIQUE KEY `uq_daytype_code` (`code`),
    UNIQUE KEY `uq_daytype_name` (`name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Here we are setting what all Types of Periods will be used for the School 'THEORY','TEACHING','PRACTICAL','BREAK','LUNCH','ASSEMBLY','EXAM','RECESS','FREE'
  CREATE TABLE IF NOT EXISTS `tt_period_type` (
    `id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL,                         -- e.g., 'THEORY','TEACHING','PRACTICAL','BREAK','LUNCH','ASSEMBLY','EXAM','RECESS','FREE'
    `name` VARCHAR(100) NOT NULL,                        -- e.g., 'Theory','Teaching','Practical','Break','Lunch','Assembly','Exam','Recess','Free Period'
    `description` VARCHAR(255) DEFAULT NULL,
    `color_code` VARCHAR(10) DEFAULT NULL,               -- e.g., '#FF0000', '#00FF00', '#0000FF'
    `icon` VARCHAR(50) DEFAULT NULL,                     -- e.g., 'fa-solid fa-chalkboard-teacher', 'fa-solid fa-clock', 'fa-solid fa-luch'
    `is_schedulable` TINYINT(1) NOT NULL DEFAULT 1,      -- 1 for schedulable, 0 for non-schedulable
    `counts_as_teaching` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for counts as teaching, 0 for non-teaching
    `counts_as_workload` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for counts as workload, 0 for non-workload
    `is_break` TINYINT(1) NOT NULL DEFAULT 0,            -- 1 for break, 0 for non-break
    `is_free_period` TINYINT(1) NOT NULL DEFAULT 0,      -- 1 for free period, 0 for non-free period. (New)
    `ordinal` TINYINT UNSIGNED DEFAULT 1,
    `duration_minutes` INT UNSIGNED DEFAULT 30,          -- Duration of the period in minutes
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_periodtype_ordinal` (`ordinal`),
    UNIQUE KEY `uq_periodtype_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Here we are setting what all Types of Teacher Assignment Roles will be used for the School 'PRIMARY','ASSISTANT','CO_TEACHER','SUBSTITUTE','TRAINEE'
  CREATE TABLE IF NOT EXISTS `tt_teacher_assignment_role` (
    `id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL,                            -- e.g., 'PRIMARY','ASSISTANT','CO_TEACHER','SUBSTITUTE','TRAINEE'
    `name` VARCHAR(100) NOT NULL,                           -- e.g., 'Primary Teacher','Assistant Teacher','Co-Teacher','Substitute Teacher','Trainee Teacher'
    `description` VARCHAR(255) DEFAULT NULL,
    `is_primary_instructor` TINYINT(1) NOT NULL DEFAULT 0,  -- Is this a Primary Teacher?
    `counts_for_workload` TINYINT(1) NOT NULL DEFAULT 0,    -- This can be counts as workload?
    `allows_overlap` TINYINT(1) NOT NULL DEFAULT 0,         -- This can be allows overlap?
    `workload_factor` DECIMAL(5,2) DEFAULT 1.00,            -- e.g., 0.25, 0.50, 0.75, 1.00, 2.00, 3.00 
    `ordinal` TINYINT UNSIGNED DEFAULT 1,                  -- e.g., 1, 2, 3
    `is_system` TINYINT(1) DEFAULT 1,                       -- Is this a system role?
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,              -- Is this a active role?
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tarole_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Here we are setting which all Days will be Open for School and Which day School will remain Closed
  CREATE TABLE IF NOT EXISTS `tt_school_days` (
    `id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(10) NOT NULL,                    -- e.g., 'MON','TUE','WED','THU','FRI','SAT','SUN'
    `name` VARCHAR(20) NOT NULL,                    -- e.g., 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
    `short_name` VARCHAR(5) NOT NULL,               -- e.g., 'Mon','Tue','Wed','Thu','Fri','Sat','Sun'
    `day_of_week` TINYINT UNSIGNED NOT NULL,        -- e.g., 1,2,3,4,5,6,7
    `ordinal` TINYINT UNSIGNED NOT NULL,           -- e.g., 1,2,3,4,5,6,7
    `is_school_day` TINYINT(1) NOT NULL DEFAULT 1,  -- 1 for school day, 0 for non-school day
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_schoolday_code` (`code`),
    UNIQUE KEY `uq_schoolday_dow` (`day_of_week`),
    KEY `idx_schoolday_ordinal` (`ordinal`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Here we are setting Status of the Schol on Calander (e.g. On a particuler day School is Open or Closed, if Open then which type of day it is Normal, Exam, Sports Day etc.)
  CREATE TABLE IF NOT EXISTS `tt_working_day` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_session_id` INT UNSIGNED NOT NULL,  -- FK to tt_academic_session.id
    `date` DATE NOT NULL,                            -- e.g., '2023-01-01'
    `day_type1_id` TINYINT UNSIGNED NOT NULL,         -- FK to tt_day_type.id (There can multipal Activity on same day e.g. Exam with Study, PTM with Study etc.)
    `day_type2_id` TINYINT UNSIGNED NULL,             -- FK to tt_day_type.id (There can multipal Activity on same day e.g. Exam with Study, PTM with Study etc.)
    `day_type3_id` TINYINT UNSIGNED NULL,             -- FK to tt_day_type.id (There can multipal Activity on same day e.g. Exam with Study, PTM with Study etc.)
    `day_type4_id` TINYINT UNSIGNED NULL,             -- FK to tt_day_type.id (There can multipal Activity on same day e.g. Exam with Study, PTM with Study etc.)
    `is_school_day` TINYINT(1) NOT NULL DEFAULT 1,   -- 1 if school is Open, 0 if school is Closed
    `remarks` VARCHAR(255) DEFAULT NULL,             -- Remarks for the day
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_workday_date` (`date`),
    KEY `idx_workday_daytype` (`day_type1_id`, `day_type2_id`, `day_type3_id`, `day_type4_id`),
    CONSTRAINT `fk_workday_daytype1` FOREIGN KEY (`day_type1_id`) REFERENCES `tt_day_type` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_workday_daytype2` FOREIGN KEY (`day_type2_id`) REFERENCES `tt_day_type` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_workday_daytype3` FOREIGN KEY (`day_type3_id`) REFERENCES `tt_day_type` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_workday_daytype4` FOREIGN KEY (`day_type4_id`) REFERENCES `tt_day_type` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
    -- 1. Update `tt_academic_term`.`term_total_teaching_days` when mark a day = Holiday
    -- 2. Update `tt_academic_term`.`term_total_exam_days` when mark a day = Exam Day
    -- 3. Update `tt_academic_term`.`term_total_working_days` when mark a day = Working Day (previously it Holiday and now I am marking it as Working Day)
    -- 4. Update `tt_academic_term`.`term_total_working_days` when mark a day = Working Day (previously it Working Day and now I am marking it as Holiday)
    -- 5. There can multipal day type on same Day (date) e.g. Exam with Study, PTM with Study etc.

  -- There is possibility that one class is having EXAM on a day but another class is not having exam but it a Normal Study Class.
  CREATE TABLE IF NOT EXISTS `tt_class_working_day_jnt` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_session_id` INT UNSIGNED NOT NULL,  -- FK to tt_academic_session.id
    `date` DATE NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,             -- FK to tt_class_section.id
    `section_id` INT UNSIGNED DEFAULT NULL,       -- FK to sch_sections.id
    `working_day_id` INT UNSIGNED NOT NULL,       -- FK to tt_working_day.id
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
    UNIQUE KEY `uq_class_working_day` (`class_id`, `working_day_id`),
    KEY `idx_class_working_day_class` (`class_id`),
    KEY `idx_class_working_day_working_day` (`working_day_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Here we are setting Period Set (Different No of Periods for different classes e.g. 3rd-12th Normal 8P, 4th-12th Exam 3P, 5th-12th Half Day 4P, BV1-2nd Toddler 6P)
  CREATE TABLE IF NOT EXISTS `tt_period_set` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL,                   -- e.g., 'STANDARD_8P','UT1_WITH_6P','UT1_WITH_0P','HALF_DAY_4P','TODDLER_6P'
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `total_periods` TINYINT UNSIGNED NOT NULL,           -- e.g., 8, 8, 3, 8, 6
    `teaching_periods` TINYINT UNSIGNED NOT NULL,        -- e.g., 8, 6, 0, 4, 6
    `exam_periods` TINYINT UNSIGNED NOT NULL,            -- e.g., 0, 2, 3, 0, 0
    `free_periods` TINYINT UNSIGNED NOT NULL,            -- e.g., 0, 0, 0, 4, 0
    `assembly_periods` TINYINT UNSIGNED NOT NULL,        -- e.g., 1,2
    `short_break_periods` TINYINT UNSIGNED NOT NULL,     -- e.g., 1,2
    `lunch_break_periods` TINYINT UNSIGNED NOT NULL,     -- e.g., 1
    `day_start_time` TIME NOT NULL,                -- e.g., '08:00:00', '08:00:00', '08:00:00', '08:00:00'. Changed from start_time
    `day_end_time` TIME NOT NULL,                  -- e.g., '13:00:00', '15:00:00', '15:00:00', '15:00:00'. Changed from end_time
    `is_default` TINYINT(1) DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_periodset_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Here we are setting Period Set Period (Different No of Periods for different classes e.g. 3rd-12th Normal 8P, 4th-12th Exam 3P, 5th-12th Half Day 4P, BV1-2nd Toddler 6P)
  CREATE TABLE IF NOT EXISTS `tt_period_set_period_jnt` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `period_set_id` INT UNSIGNED NOT NULL,   -- FK to tt_period_set.id
    `period_ord` TINYINT UNSIGNED NOT NULL,     -- e.g., 1,2,3,4,5,6,7,8
    `code` VARCHAR(20) NOT NULL,                -- e.g., 'REC','P-1','P-2','BRK','P-3','P-4','LUN','P-5','P-6','BRK','P-7','P-8'
    `short_name` VARCHAR(50) NOT NULL,          -- e.g., 'Recess','Period-1','Period-2','Break','Period-3','Period-4','Lunch','Period-5','Period-6','Break','Period-7','Period-8'
    `period_type_id` INT UNSIGNED NOT NULL,  -- FK to tt_period_type.id (e.g. 'TEACHING','BREAK','LUNCH','ASSEMBLY','ACTIVITY','EXAM','HALF DAY')
    `start_time` TIME NOT NULL,                 -- e.g., '08:00:00', '08:45:00', '09:30:00', '10:15:00', '11:00:00', '11:45:00', '12:30:00', '13:15:00'
    `end_time` TIME NOT NULL,                   -- e.g., '08:45:00', '09:30:00', '10:15:00', '11:00:00', '11:45:00', '12:30:00', '13:15:00', '14:00:00'
    `duration_minutes` SMALLINT UNSIGNED GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, start_time, end_time)) STORED,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_psp_set_ord` (`period_set_id`, `period_ord`),
    UNIQUE KEY `uq_psp_set_code` (`period_set_id`, `code`),
    KEY `idx_psp_type` (`period_type_id`),
    CONSTRAINT `fk_psp_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_set` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_psp_period_type` FOREIGN KEY (`period_type_id`) REFERENCES `tt_period_type` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `chk_psp_time` CHECK (`end_time` > `start_time`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- This is the table for which we will be creating Timetable (e.g., 'STANDARD_3rd-12th', 'STANDARD_BV1-2nd','EXTENDED_9th-12th')
  CREATE TABLE IF NOT EXISTS `tt_timetable_type` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL,                      -- e.g., 'STANDARD','UNIT_TEST-1', 'HALF_DAY','HALF_YEARLY','FINAL_EXAM'
    `name` VARCHAR(100) NOT NULL,                     -- e.g., 'Standard Timetable','Half Day Timetable','Unit Test-1 Timetable','Half Yearly Timetable','Final Exam Timetable'
    `description` VARCHAR(255) DEFAULT NULL,
    `shift_id` INT UNSIGNED DEFAULT NULL,          -- FK to tt_shift.id (e.g., 'MORNING','AFTERNOON','EVENING')
    `effective_from_date` DATE DEFAULT NULL,
    `effective_to_date` DATE DEFAULT NULL,
    `school_start_time` TIME DEFAULT NULL,
    `school_end_time` TIME DEFAULT NULL,
    `has_exam` TINYINT(1) NOT NULL DEFAULT 0,
    `has_teaching` TINYINT(1) NOT NULL DEFAULT 1,
    `ordinal` SMALLINT UNSIGNED DEFAULT 1,
    `is_default` TINYINT(1) DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tttype_code` (`code`),
    KEY `idx_tttype_shift` (`shift_id`),
    CONSTRAINT `fk_tttype_shift` FOREIGN KEY (`shift_id`) REFERENCES `tt_shift` (`id`),
    CONSTRAINT `chk_tttype_time` CHECK (`school_end_time` > `school_start_time`) AND (`effective_from_date` <= `effective_to_date`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
    -- 1. Application need to check and not allowed to insert/update overlapping school start/end time for 2 or more tTimetable type for same shift

  -- This table is used to define the rules for a particular class
  CREATE TABLE IF NOT EXISTS `tt_class_timetable_type_jnt` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_term_id` INT UNSIGNED DEFAULT NULL,            -- FK to sch_academic_term.id 
    `timetable_type_id` INT UNSIGNED NOT NULL,               -- FK to tt_timetable_type.id 
    `class_id` INT UNSIGNED NOT NULL,                        -- FK to sch_classes.id
    `section_id` INT UNSIGNED NULL,                          -- FK to sch_sections.id (This can be Null if it is applicable to all section of the class)
    `period_set_id` INT UNSIGNED NOT NULL,                   -- FK to tt_period_set.id
    `applies_to_all_sections` TINYINT(1) NOT NULL DEFAULT 1, -- If 1 then all section of same class will have same timetable type
    `has_teaching` TINYINT(1) NOT NULL DEFAULT 1,            -- Whether this class is allowed to have teaching
    `has_exam` TINYINT(1) NOT NULL DEFAULT 0,                -- Whether this class is allowed to have exam
    `weekly_exam_period_count` TINYINT UNSIGNED DEFAULT NULL,     -- Number of exam periods (Will fetch from tt_period_set)
    `weekly_teaching_period_count` TINYINT UNSIGNED DEFAULT NULL, -- Number of teaching periods (Will fetch from tt_period_set)
    `weekly_free_period_count` TINYINT UNSIGNED DEFAULT NULL,     -- Number of free periods (Will fetch from tt_period_set)
    `effective_from` DATE DEFAULT NULL,
    `effective_to` DATE DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_cttj_term` (`academic_term_id`,'timetable_type_id','class_id','section_id'),
    CONSTRAINT `fk_cttj_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_terms` (`id`),
    CONSTRAINT `fk_cttj_mode` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_type` (`id`),
    CONSTRAINT `fk_cttj_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_cttj_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_cttj_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_set` (`id`),
    CONSTRAINT `chk_valid_effective_range` CHECK (effective_from < effective_to)
    CONSTRAINT `chk_cttj_apply_to_all_section` CHECK ((`section_id` IS NULL AND `applies_to_all_sections` = 1 ) OR (`section_id` IS NOT NULL AND `applies_to_all_sections` = 0 ))
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
    -- 1. Application need to check and not allowed to insert/update overlapping period set for same class and section

  -- -------------------------------------------------
  --  SECTION 2: TIMETABLE REQUIREMENT
  -- -------------------------------------------------

   -- Create Slot Availability / Class+section (This will fetch data from tt_class_timetable_type_jnt & tt_timetable_type)
   -- There will be no Audit Fields as this table will be used for calculation purpose only
   -- Old name `tt_slot_availability`, changed to `tt_slot_requirement`
  CREATE TABLE IF NOT EXISTS `tt_slot_requirement` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_term_id` INT unsigned NOT NULL,  -- FK to tt_academic_term.id
    `timetable_type_id` INT unsigned NOT NULL,  -- FK to tt_timetable_type.id
    `class_timetable_type_id` INT unsigned NOT NULL,  -- FK to tt_class_timetable_type_jnt.id    
    `class_id` INT unsigned NOT NULL,  -- FK to sch_classes.id
    `section_id` INT unsigned NOT NULL,  -- FK to sch_sections.id
    `class_house_room_id` int unsigned NOT NULL,   -- FK to 'sch_rooms'
    `weekly_total_slots` TINYINT UNSIGNED NOT NULL,  -- 1-8 How many slots that Class+section have everyday
    `weekly_teaching_slots` TINYINT UNSIGNED NOT NULL,  -- 1-8 How many teaching slots that Class+section have everyday
    `weekly_exam_slots` TINYINT UNSIGNED NOT NULL,  -- 1-8 How many exam slots that Class+section have everyday
    `weekly_free_slots` TINYINT UNSIGNED NOT NULL,  -- 1-8 How many free slots that Class+section have everyday
    `activity_id` INT unsigned NULL,               -- FK to tt_activity.id
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_sa_class_section` (`timetable_type_id`,`class_timetable_type_id`,`class_id`, `section_id`),
    CONSTRAINT `fk_sa_academic_term` FOREIGN KEY (`academic_term_id`) REFERENCES `tt_academic_term` (`id`),
    CONSTRAINT `fk_sa_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`), 
    CONSTRAINT `fk_sa_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_sa_timetable_type` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_type` (`id`),
    CONSTRAINT `fk_sa_class_timetable_type` FOREIGN KEY (`class_timetable_type_id`) REFERENCES `tt_class_timetable_type_jnt` (`id`),
    CONSTRAINT `fk_sa_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Data Example:
    -- Academic Term  Timetable Typ.  Class + Sec.  Tot.Period       Teaching Period     Exam Period       Free Period
    -- -------------- --------------- ------------- ---------------- ------------------- ----------------- ---------------
    -- 2025-26 TERM-1   Standard      Class-LKG A   TOTAL Period-6   Study Period - 6
    -- 2025-26 TERM-1   Standard      Class-LKG B   Period-6         Study Period - 6
    -- 2025-26 TERM-1   Standard      Class-3RD A   TOTAL Period-6   Study Period - 6
    -- 2025-26 TERM-1   Standard      Class-LKG B   Period-6         Study Period - 6
    -- 2025-26 TERM-1   Standard      Class-3RD A   Period-8         Study Period - 6    Exam Period - 2
    -- 2025-26 TERM-1   Standard      Class-5th A   Period-8         Study Period - 5    Exam Period - 2   Free Period -1
    -- 2025-26 TERM-1   Standard      Class-10th A  Period-8         Study Period - 0    Exam Period - 3   Free Period -5
    -- 2025-26 TERM-1   Standard      Class-5th A   Period-8         Study Period - 0    Exam Period - 3   Free Period -5

  -- changed below Table name to - `tt_class_requirement_groups` from `tt_class_groups_jnt`
  CREATE TABLE IF NOT EXISTS `tt_class_requirement_groups` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `code` char(50) NOT NULL,                                      -- Copy from sch_class_groups_jnt.code
    `name` varchar(100) NOT NULL,                                  -- Copy from sch_class_groups_jnt.name
    `class_group_id` INT unsigned NOT NULL,                        -- FK to sch_class_groups.id
    -- Key Field to apply Constraints
    `class_id` INT unsigned NOT NULL,                              -- FK to sch_classes.id
    `section_id` INT unsigned DEFAULT NULL,                        -- FK to sch_sections.id
    `subject_id` INT unsigned NOT NULL,                            -- FK to sch_subjects.id
    `study_format_id` INT unsigned NOT NULL,                       -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    `subject_type_id` INT unsigned NOT NULL,                       -- FK to sch_subject_types.id. e.g MAJOR, MINOR, OPTIONAL, etc.
    `subject_study_format_id` INT unsigned NOT NULL,               -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    -- Info Collected from diffrent Tables
    `class_house_room_id` INT UNSIGNED NOT NULL,                      -- FK to 'sch_rooms' (Added new)
    `student_count` INT UNSIGNED DEFAULT NULL,                        -- Number of students in this subgroup (Need to be taken from sch_class_section_jnt)
    `eligible_teacher_count` INT UNSIGNED DEFAULT NULL,               -- Number of teachers available for this group (Will capture from Teachers profile)
    --
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_clsReqGroups_code` (`code`),
    UNIQUE KEY `uq_clsReqGroups_class_section_subjectType` (`class_id`,`section_id`,`sub_stdy_frmt_id`),
    KEY `idx_clsReqGroups_class_id_foreign` (`class_id`,`section_id`),
    KEY `idx_clsReqGroups_subject_type_id_foreign` (`subject_type_id`),
    KEY `idx_clsReqGroups_rooms_type_id_foreign` (`required_room_type_id`),
    CONSTRAINT `fk_clsReqGroups_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_clsReqGroups_rooms_type_id_foreign` FOREIGN KEY (`required_room_type_id`) REFERENCES `sch_room_types` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_clsReqGroups_required_room_id_foreign` FOREIGN KEY (`required_room_id`) REFERENCES `sch_rooms` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_clsReqGroups_section_id_foreign` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_clsReqGroups_sub_stdy_frmt_id_foreign` FOREIGN KEY (`sub_stdy_frmt_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_clsReqGroups_subject_type_id_foreign` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
  -- 1. student_count = sch_class_section_jnt.actual_total_student

  -- changed below Table name to - `tt_requirement_subgroups` from `tt_class_subgroup`
  CREATE TABLE IF NOT EXISTS `tt_class_requirement_subgroups` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(50) NOT NULL,                                 -- Copy from sch_class_groups_jnt.code
    `name` VARCHAR(100) NOT NULL,                                -- Copy from sch_class_groups_jnt.name
    `class_group_id` INT unsigned NOT NULL,                      -- FK to sch_class_groups.id
    -- Key Field to apply Constraints
    `class_id` INT unsigned NOT NULL,                            -- FK to sch_classes.id
    `section_id` INT unsigned DEFAULT NULL,                      -- FK to sch_sections.id
    `subject_id` INT unsigned NOT NULL,                            -- FK to sch_subjects.id
    `study_format_id` INT unsigned NOT NULL,                       -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    `subject_type_id` INT unsigned NOT NULL,                       -- FK to sch_subject_types.id. e.g MAJOR, MINOR, OPTIONAL, etc.
    `subject_study_format_id` INT unsigned NOT NULL,               -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    -- Info Collected from diffrent Tables
    `class_house_room_id` INT UNSIGNED NOT NULL,                 -- FK to 'sch_rooms' (Added new). (Fetch from sch_class_section_jnt)
    `student_count` INT UNSIGNED DEFAULT NULL,                   -- Number of students in this subgroup
    `eligible_teacher_count` INT UNSIGNED DEFAULT NULL,          -- Number of teachers available for this group (Will capture from Teachers profile)
    -- Only below 2 parameter can be modified at tt_class_requirement_subgroups screen
    `is_shared_across_sections` TINYINT(1) NOT NULL DEFAULT 0,   -- Whether this subgroup is shared across sections
    `is_shared_across_classes` TINYINT(1) NOT NULL DEFAULT 0,    -- Whether this subgroup is shared across classes
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subgroup_code` (`code`),
    UNIQUE KEY `uq_classGroup_subStdFmt_class_section_subjectType` (`class_id`,`section_id`,`sub_stdy_frmt_id`),
    KEY `idx_subgroup_type` (`subgroup_type`),
    CONSTRAINT `fk_subgroup_class_group` FOREIGN KEY (`class_subject_group_id`) REFERENCES `tt_class_subject_groups` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
    -- 1. Count (Student) from std_student_academic_sessions where 
    --             std_student_academic_sessions.subject_group_id = sch_subject_groups.id
    --             sch_subject_group_subject_jnt.subject_group_id = sch_subject_groups.id
    --   Condition
    --             sch_subject_groups.class_id = tt_class_subject_subgroups.class_id
    --             sch_subject_groups.section_id = tt_class_subject_subgroups.section_id
    --             sch_subject_group_subject_jnt.subject_study_format_id = tt_class_subject_subgroups.subject_study_format_id

  -- changed below Table name to - tt_requirement_consolidation from tt_class_group_requirement
  CREATE TABLE IF NOT EXISTS `tt_requirement_consolidation` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_term_id` INT UNSIGNED NOT NULL,                       -- FK to tt_academic_term.id (This is the Term for which this timetable is being generated)
    `timetable_type_id` INT unsigned NOT NULL,                      -- FK to tt_timetable_type.id
    `class_requirement_group_id` INT UNSIGNED DEFAULT NULL,         -- FK to sch_class_groups_jnt.id
    `class_requirement_subgroup_id` INT UNSIGNED DEFAULT NULL,      -- FK to tt_requirement_subgroups.id
    -- Key Field to apply Constraints
    `class_id` INT unsigned NOT NULL,                               -- FK to sch_classes.id
    `section_id` INT unsigned DEFAULT NULL,                         -- FK to sch_sections.id
    `subject_id` INT unsigned NOT NULL,                             -- FK to sch_subjects.id
    `study_format_id` INT unsigned NOT NULL,                        -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    `subject_type_id` INT unsigned NOT NULL,                        -- FK to sch_subject_types.id. e.g MAJOR, MINOR, OPTIONAL, etc.
    `subject_study_format_id` INT unsigned NOT NULL,                -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    -- Non-Editable (Fetched from 'tt_requirement_groups' & 'tt_class_requirement_subgroups')
    `class_house_room_id` INT UNSIGNED NOT NULL,                    -- FK to 'sch_rooms' (Added new). (Fetch from sch_class_section_jnt)
    `student_count` INT UNSIGNED DEFAULT NULL,                      -- Number of students in this subgroup
    `eligible_teacher_count` INT UNSIGNED DEFAULT NULL,             -- Number of teachers available for this group (Will capture from Teachers profile)
    -- Editable Parameters before Timetable Generation (Fetching from sch_class_groups_jnt)
    `is_compulsory` TINYINT(1) NOT NULL DEFAULT 1,                  -- Whether this subgroup is compulsory
    `required_weekly_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,  -- Total periods required per week for this Class Group (Class+{Section}+Subject+StudyFormat)
    `min_periods_required_per_week` TINYINT UNSIGNED DEFAULT NULL,  -- Minimum periods required per week
    `max_periods_required_per_week` TINYINT UNSIGNED DEFAULT NULL,  -- Maximum periods allowed per week
    `min_periods_required_per_day` TINYINT UNSIGNED DEFAULT NULL,   -- Minimum periods allowed per day
    `max_periods_required_per_day` TINYINT UNSIGNED DEFAULT NULL,   -- Maximum periods allowed per day
    `min_gap_between_periods` TINYINT UNSIGNED DEFAULT NULL,        -- Minimum gap between periods
    `required_consecutive_periods` TINYINT UNSIGNED DEFAULT NULL,    -- Required consecutive periods
    `min_required_consecutive_periods` TINYINT UNSIGNED DEFAULT NULL, -- Number of periods need to be consecutive
    `allow_consecutive_periods` TINYINT(1) NOT NULL DEFAULT 0,      -- Whether consecutive periods are allowed
    `max_consecutive_periods` TINYINT UNSIGNED DEFAULT 2,           -- Maximum consecutive periods
    `class_priority_score` TINYINT UNSIGNED DEFAULT NULL,           -- Priority Score from sch_class_group
    `preferred_periods_json` JSON DEFAULT NULL,                     -- On Screen User will see Multiselection of Periods but it will be saved as JSON
    `avoid_periods_json` JSON DEFAULT NULL,                         -- On Screen User will see Multiselection of Periods but it will be saved as JSON
    `spread_evenly` TINYINT(1) DEFAULT 1,                           -- Whether periods should be spread evenly (have 1 period everyday)
    `is_shared_across_sections` TINYINT(1) NOT NULL DEFAULT 0,      -- Whether this subgroup is shared across sections (Editable)
    `is_shared_across_classes` TINYINT(1) NOT NULL DEFAULT 0,       -- Whether this subgroup is shared across classes (Editable)
    -- Room Requirement
    `compulsory_specific_room_type` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether specific room type is required (TRUE - if Specific Room Type is Must)
    `required_room_type_id` INT UNSIGNED NOT NULL,                  -- FK to sch_room_types.id (Required)
    `required_room_id` INT UNSIGNED DEFAULT NULL,                   -- FK to sch_rooms.id (Optional)
    -- Audit Fields
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,             -- Whether this requirement is active
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_cgr_group_session` (`academic_term_id`, `timetable_type_id`, `class_requirement_group_id`, `class_requirement_subgroup_id`),
    CONSTRAINT `fk_cgr_class_group` FOREIGN KEY (`class_requirement_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cgr_subgroup` FOREIGN KEY (`class_requirement_subgroup_id`) REFERENCES `tt_requirement_subgroups` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cgr_session` FOREIGN KEY (`academic_term_id`) REFERENCES `tt_academic_term` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_cgr_timetable_type` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_type` (`id`) ON DELETE SET NULL,
    CONSTRAINT `chk_cgr_target` CHECK ((`class_requirement_group_id` IS NOT NULL AND `class_requirement_subgroup_id` IS NULL) OR (`class_requirement_group_id` IS NULL AND `class_requirement_subgroup_id` IS NOT NULL))
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------
  --  SECTION 3: CONSTRAINT ENGINE
  -- -------------------------------------------------
  -- Important Note - Constraint Category & Scope can not be defined by User but it will defined by PRIME only
  CREATE TABLE IF NOT EXISTS `tt_constraint_category_scope` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `type` ENUM('CATEGORY','SCOPE') NOT NULL,
    `code` VARCHAR(30) NOT NULL,  -- Can not be changed by User
    `name` VARCHAR(100) NOT NULL,  -- User can change Name
    `description` VARCHAR(255) DEFAULT NULL,

    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_constraint_category_scope` (`type`, `code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 
  -- Condition :
  -- Category : PERIOD, ROOM, TEACHER, CLASS, CLASS+SECTION, SUBJECT, STUDY_FORMAT, SUBJECT_STUDY_FORMAT, SUBJECT_TYPE, ACTIVITY
  -- Scope    : GLOBAL, TEACHER, ROOM, ACTIVITY, CLASS, CLASS+SECTION, CLASS+SUBJECT+STUDY_FORMAT, SUBJECT+STUDY_FORMAT, SUBJECT, CLASS_GROUP, CLASS_SUBGROUP

  CREATE TABLE IF NOT EXISTS `tt_constraint_type` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(60) NOT NULL,                        -- Can not be changed by User (e.g., 'TEACHER_NOT_AVAILABLE','MIN_DAYS_BETWEEN','SAME_STARTING_TIME')
    `name` VARCHAR(150) NOT NULL,                       -- User can change Name (e.g., 'Teacher Not Available','Minimum Days Between','Same Starting Time')
    `description` VARCHAR(255) DEFAULT NULL,
    `category_id` INT UNSIGNED NOT NULL,                -- FK to tt_constraint_category_scope.id (e.g., PERIOD, ROOM, TEACHER, STUDENT, CLASS, SUBJECT etc.)
    `applicable_to` ENUM('ALL','SPECIFIC') DEFAULT 'ALL',
    `scope_id` INT UNSIGNED NOT NULL,                   -- FK to tt_constraint_category_scope.id (e.g., GLOBAL, TEACHER, ROOM, ACTIVITY, CLASS, CLASS+SECTION etc.)
    `target_id_required` TINYINT(1) NOT NULL DEFAULT 0, -- Whether target_id is required
    `default_weight` TINYINT UNSIGNED DEFAULT 100,      -- Default weight for this constraint type
    `is_hard_constraint` TINYINT(1) DEFAULT 1,          -- Whether this constraint type can be set as hard
    `param_schema` JSON DEFAULT NULL,                   -- JSON schema for parameters required by this constraint type
    `is_system` TINYINT(1) DEFAULT 1,                   -- Whether this constraint type is a system constraint type
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ctype_code` (`code`),
    KEY `idx_ctype_category` (`category_id`),
    KEY `idx_ctype_scope` (`scope_id`),
    CONSTRAINT `fk_ctype_category` FOREIGN KEY (`category_id`) REFERENCES `tt_constraint_category_scope` (`id`),
    CONSTRAINT `fk_ctype_scope` FOREIGN KEY (`scope_id`) REFERENCES `tt_constraint_category_scope` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tt_constraint` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `constraint_type_id` INT UNSIGNED NOT NULL,          -- FK to tt_constraint_type.id
    `name` VARCHAR(200) DEFAULT NULL,
    `description` VARCHAR(500) DEFAULT NULL,
    `academic_term_id` INT UNSIGNED DEFAULT NULL,        -- FK to tt_academic_term.id
    `target_type` INT UNSIGNED NOT NULL,                 -- FK to tt_constraint_category_scope (whome this constraint will be applicable to?)
    `target_id` INT UNSIGNED DEFAULT NULL,               -- FK to target_type.id (Individuals id, if constraint applicable to an individual e.g. a Teacher, a Class or a Room)
    `is_hard` TINYINT(1) NOT NULL DEFAULT 0,             -- Whether this constraint is hard
    `weight` TINYINT UNSIGNED NOT NULL DEFAULT 100,      -- Weight of this constraint
    `params_json` JSON NOT NULL,                         -- JSON object containing parameters for this constraint
    `effective_from` DATE DEFAULT NULL,                  -- Effective date of this constraint
    `effective_to` DATE DEFAULT NULL,                    -- Expiry date of this constraint
    `apply_for_all_days` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this constraint applies to all days
    `applicable_days` JSON DEFAULT NULL,                 -- JSON array of days this constraint applies to
    `impact_score` TINYINT UNSIGNED DEFAULT 50,          -- Estimated impact on timetable generation difficulty (1-100)
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,           -- Whether this constraint is active
    `created_by` INT UNSIGNED DEFAULT NULL,              -- FK to sys_users.id
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_constraint_type` (`constraint_type_id`),
    INDEX `idx_constraint_target` (`target_type`, `target_id`),
    INDEX `idx_constraint_                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
    CONSTRAINT `fk_constraint_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tt_teacher_unavailable` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `teacher_id` INT UNSIGNED NOT NULL,  -- FK to sch_teachers.id
    `constraint_id` INT UNSIGNED DEFAULT NULL,  -- FK to tt_constraint.id
    `unavailable_for_all_days` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether teacher unavailable for all days within date range?
    `day_of_week` ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') DEFAULT 'Monday' NOT NULL,
    `unavailable_for_all_periods` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether teacher unavailable for all periods
    `period_no` TINYINT UNSIGNED DEFAULT NULL,  -- If teacher unavalable for 1 or more specific periods then there will be 1 record for every period unavailability
    `is_recurring` TINYINT(1) DEFAULT 1,  -- Whether this is a recurring unavailable period
    `recurring_frequency` ENUM('Daily', 'Weekly', 'Monthly', 'Yearly') DEFAULT 'Daily',
    `start_date` DATE DEFAULT NULL,
    `end_date` DATE DEFAULT NULL,
    `reason` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_tu_teacher` (`teacher_id`),
    KEY `idx_tu_day_period` (`day_of_week`, `period_ord`),
    CONSTRAINT `fk_tu_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_tu_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraint` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tt_room_unavailable` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `room_id` INT UNSIGNED NOT NULL,  -- FK to sch_rooms.id
    `constraint_id` INT UNSIGNED DEFAULT NULL,  -- FK to tt_constraint.id
    `day_of_week` TINYINT UNSIGNED NOT NULL,  -- 1=Monday, 2=Tuesday, etc. (ISO 8601)
    `period_ord` TINYINT UNSIGNED DEFAULT NULL,  -- 1=First period, 2=Second period, etc.
    `start_date` DATE DEFAULT NULL,
    `end_date` DATE DEFAULT NULL,
    `reason` VARCHAR(255) DEFAULT NULL,
    `is_recurring` TINYINT(1) DEFAULT 1,  -- Whether this is a recurring unavailable period
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this unavailable period is active
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_ru_room` (`room_id`),
    KEY `idx_ru_day_period` (`day_of_week`, `period_ord`),
    CONSTRAINT `fk_ru_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ru_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraint` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------
  --  SECTION 4: TIMETABLE RESOURCE AVAILABILITY
  -- -------------------------------------------------
  -- Create Teachers Availability for every record of 'tt_requirement_consolidation'
  CREATE TABLE IF NOT EXISTS `tt_teacher_availability` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- Key Field to apply Constraints
    `requirement_consolidation_id` INT unsigned NOT NULL,  -- FK to tt_requirement_consolidation.id
    `class_id` INT unsigned NOT NULL,                 -- FK to sch_classes.id
    `section_id` INT unsigned DEFAULT NULL,           -- FK to sch_sections.id
    `subject_study_format_id` INT unsigned NOT NULL,  -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    `teacher_profile_id` INT unsigned NOT NULL,       -- FK to sch_teacher_profile.id
    `required_weekly_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,  -- Total periods required per week for this Class Group (Class+{Section}+Subject+StudyFormat)
    -- Skill & Preference from "sch_teacher_profile"
    `is_full_time` TINYINT(1) DEFAULT 1,                         -- 1=Full-time, 0=Part-time
    `preferred_shift` INT UNSIGNED DEFAULT NULL,                 -- FK to sch_shift.id
    `capable_handling_multiple_classes` TINYINT(1) DEFAULT 0,    -- Is he capable of handling un-assigned classes
    `can_be_used_for_substitution` TINYINT(1) DEFAULT 1,         -- Can we use this teacher for substitution
    `certified_for_lab` TINYINT(1) DEFAULT 0,
    `max_available_periods_weekly` TINYINT UNSIGNED DEFAULT 48,
    `min_available_periods_weekly` TINYINT UNSIGNED DEFAULT 36,
    `max_allocated_periods_weekly` TINYINT UNSIGNED DEFAULT 1,
    `min_allocated_periods_weekly` TINYINT UNSIGNED DEFAULT 1,
    `can_be_split_across_sections` TINYINT(1) DEFAULT 0,
    -- From Teachers Capability (sch_teacher_capabilities)
    `proficiency_percentage` TINYINT UNSIGNED DEFAULT NULL,      -- 1–100
    `teaching_experience_months` SMALLINT UNSIGNED DEFAULT NULL,
    `is_primary_subject` TINYINT(1) NOT NULL DEFAULT 1,          -- 1=Yes, 0=No
    `competancy_level` ENUM('Facilitator','Basic','Intermediate','Advanced','Expert') DEFAULT 'Basic',  -- Facilitator - If No Teaching Experience but can manage.
    `priority_order` INT UNSIGNED DEFAULT NULL,                  -- Priority Order of the Teacher for the Class+Subject+Study_Format
    `priority_weight` TINYINT UNSIGNED DEFAULT NULL,             -- manual / computed weight (1–10) (Even if teachers are available, how important is THIS activity to the school?)
    `scarcity_index` TINYINT UNSIGNED DEFAULT NULL,              -- 1=abundant, 10=very rare
    `is_hard_constraint` TINYINT(1) DEFAULT 0,                   -- if true cannot be voilated e.g. Physics Lab teacher for Class 12
    `allocation_strictness` ENUM('Hard','Medium','Soft') DEFAULT 'Medium', e.g. Senior Maths teacher - Hard, Preferred English teacher - Medium, Art / Sports / Activity - Soft
    -- Priority Override & Historical Feedback
    `override_priority` TINYINT UNSIGNED DEFAULT NULL,           -- admin override
    `override_reason` VARCHAR(255) DEFAULT NULL,
    `historical_success_ratio` TINYINT UNSIGNED DEFAULT NULL,    -- 1–100 (sessions_completed_without_change / total_sessions_allocated ) * 100)
    `last_allocation_score` TINYINT UNSIGNED DEFAULT NULL,       -- last run score (1–100)
    -- Editable - School Preference for a Teacher for a Particuler Class+Subject+StudyFormat
    `is_primary_teacher` TINYINT(1) NOT NULL DEFAULT 1,          -- 1=Yes, 0=No 9can be calculated on the basis of 
    `is_preferred_teacher` TINYINT(1) NOT NULL DEFAULT 0,        -- 1=Yes, 0=No
    `preference_score` TINYINT UNSIGNED DEFAULT NULL,            -- 1–100 
    -- Status Duration
    `teacher_profile_from_date` DATE DEFAULT NULL,               -- sch_teacher_profile.effective_from
    `teacher_profile_to_date` DATE DEFAULT NULL,                 -- sch_teacher_profile.effective_to
    `teacher_available_from_date` DATE DEFAULT NULL,             -- sch_teacher_capabilities.effective_from
    `timetable_start_date` DATE DEFAULT NULL,                    -- tt_timetable.start_date
    `timetable_end_date` DATE DEFAULT NULL,                      -- tt_timetable.end_date
    -- 1. Auto-calculates 1 (Yes) or 0 (No). (Logic: Is the teacher ready on or before the start date?)
    `available_for_full_timetable_duration` TINYINT(1) AS (IF(`teacher_available_from_date` <= `timetable_start_date`, 1, 0)) STORED,
    -- 2. Auto-calculates the gap in days. (Logic: If available date is after start, find the difference; otherwise 0.) 
    `no_of_days_not_available` INT AS (GREATEST(0, DATEDIFF(`teacher_available_from_date`, `timetable_start_date`))) STORED,
    -- Calculated Scores
    `min_teacher_availability_score` DECIMAL(7,2) UNSIGNED DEFAULT 1  -- Percentage of available teachers for this Class Group (Will capture from Teachers profile)
    `max_teacher_availability_score` DECIMAL(7,2) UNSIGNED DEFAULT 1  -- Percentage of available teachers for this Class Group (Will capture from Teachers profile)
    -- Activity
    `activity_id` INT unsigned NULL,                       -- FK to tt_activity.id
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ta_requirement_teacher` (`requirement_consolidation_id`, `teacher_profile_id`),
    CONSTRAINT `fk_ta_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`), 
    CONSTRAINT `fk_ta_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_ta_subject_study_format` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_study_formats` (`id`),
    CONSTRAINT `fk_ta_teacher_profile` FOREIGN KEY (`teacher_profile_id`) REFERENCES `sch_teacher_profile` (`id`),
    CONSTRAINT `fk_ta_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
    -- teacher_availability_ratio = (Total weekly available Periods / (Total Number of Subjects he can teach in a week) * 100
    -- Example: If a teacher can teach 3 Subject for class-4, 3 Subject for Class-5 & 2 Subject for Class-6 in a week and has 36 available periods in a week, 
    -- then his teacher_availability_ratio is (8 / 36) * 100 = 22.22%  
    -- TAR = (Total weekly assigned Periods / Total weekly available Periods) * 100

  CREATE TABLE IF NOT EXISTS `tt_teacher_availability_detail` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `teacher_availability_id` INT unsigned NOT NULL,  -- FK to tt_teacher_availability.id 
    `teacher_profile_id` INT unsigned NOT NULL,       -- FK to sch_teacher_profile.id
    `day_number` TINYINT UNSIGNED NOT NULL,           -- 1-7 Day Number
    `day_name` VARCHAR(10) NOT NULL,                  -- Day Name
    `period_number` TINYINT UNSIGNED NOT NULL,        -- 1-8 Period Number
    `can_be_assigned` TINYINT(1) NOT NULL DEFAULT 1,  -- 1=Yes, 0=No
    `availability_for_period` ENUM('Available','Unavailable','Assigned','Free Period') NOT NULL DEFAULT 'Available',
    `assigned_class_id` INT unsigned DEFAULT NULL,                 -- FK to sch_classes.id
    `assigned_section_id` INT unsigned DEFAULT NULL,               -- FK to sch_sections.id
    `assigned_subject_study_format_id` INT unsigned DEFAULT NULL,  -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    `teacher_available_from_date` DATE DEFAULT NULL,               -- sch_teacher_capabilities.effective_from
    `activity_id` INT unsigned NULL,                               -- FK to tt_activity.id
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ta_class_wise` (`teacher_profile_id`, `day_number`, `period_number`),
    UNIQUE KEY `uq_ta_class_wise_detail` (`teacher_profile_id`,`day_number`, `period_number`,`assigned_class_id`, `assigned_section_id`, `assigned_subject_study_format_id`),
    CONSTRAINT `fk_ta_class` FOREIGN KEY (`assigned_class_id`) REFERENCES `sch_classes` (`id`), 
    CONSTRAINT `fk_ta_section` FOREIGN KEY (`assigned_section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_ta_subject_study_format` FOREIGN KEY (`assigned_subject_study_format_id`) REFERENCES `sch_study_formats` (`id`),
    CONSTRAINT `fk_ta_teacher_profile` FOREIGN KEY (`teacher_profile_id`) REFERENCES `sch_teacher_profile` (`id`),
    CONSTRAINT `fk_ta_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  -- Create Room Availability Class wise for entire Academic Session
  CREATE TABLE IF NOT EXISTS `tt_room_availability` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `room_id` INT unsigned NOT NULL,                                -- FK to sch_rooms.id
    `rooms_type_id` INT unsigned NOT NULL,                          -- FK to sch_room_type.id
    `total_rooms_in_category` SMALLINT unsigned NOT NULL,           -- sch_rooms_type.room_count_in_category (Total number of rooms in this category)
    `can_be_assigned` TINYINT(1) NOT NULL DEFAULT 1,                -- 1=Yes, 0=No
    `overall_availability_status` ENUM('Available','Unavailable','Partially Available','Assigned') NOT NULL DEFAULT 'Available',
    `available_for_full_timetable_duration` TINYINT(1) NOT NULL DEFAULT 1, -- 1=Yes, 0=No
    `is_class_house_room` TINYINT(1) NOT NULL DEFAULT 0,            -- 1=Yes, 0=No
    `house_room_class_id` INT unsigned NULL,                        -- FK to sch_classes.id
    `house_room_section_id` INT unsigned NULL,                      -- FK to sch_sections.id
    `activity_id` INT unsigned NULL,                                -- FK to tt_activity.id
    `capacity` int unsigned DEFAULT NULL,                           -- Seating Capacity of the Room
    `max_limit` int unsigned DEFAULT NULL,                          -- Maximum how many students can accomodate in the room
    -- Can be assigned for Lecture, Practical, Exam, Activity, Sports
    `can_be_assigned_for_lecture` TINYINT(1) NOT NULL DEFAULT 1,    -- Can this Room be assigned as Lecture Room if required?
    `can_be_assigned_for_practical` TINYINT(1) NOT NULL DEFAULT 1,  -- Can this Room be assigned as Practical Room if required?
    `can_be_assigned_for_exam` TINYINT(1) NOT NULL DEFAULT 1,       -- Can this Room be assigned as Exam Room if required?
    `can_be_assigned_for_activity` TINYINT(1) NOT NULL DEFAULT 1,   -- Can this Room be assigned as Activity Room if required?
    `can_be_assigned_for_sports` TINYINT(1) NOT NULL DEFAULT 1,     -- Can this Room be assigned as Sports Room if required?
    `timetable_start_time` time NOT NULL,                           -- This will be fetched from (tt_timetable_type.effective_from_date)
    `timetable_end_time` time NOT NULL,                             -- This will be fetched from (tt_timetable_type.effective_to_date)
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ra_class_wise` (`room_id`,`room_type_id`, `class_id`, `section_id`, `subject_study_format_id`, `start_time`, `end_time`),
    CONSTRAINT `fk_room_availability_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`),
    CONSTRAINT `fk_room_availability_room_type` FOREIGN KEY (`room_type_id`) REFERENCES `tt_room_type` (`id`),
    CONSTRAINT `fk_room_availability_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`), 
    CONSTRAINT `fk_room_availability_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_room_availability_subject_study_format` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_study_formats` (`id`),
    CONSTRAINT `fk_room_availability_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`),
    CONSTRAINT `chk_class_house_logic` CHECK ((is_class_house_room = 1 AND class_id IS NOT NULL AND section_id IS NOT NULL) OR (is_class_house_room = 0))
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tt_room_availability_detail` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `room_availability_id` INT unsigned NOT NULL,              -- FK to tt_room_availability.id
    `room_id` INT unsigned NOT NULL,                           -- FK to sch_rooms.id
    `room_type_id` INT unsigned NOT NULL,                      -- FK to sch_room_type.id
    `day_number` TINYINT UNSIGNED NOT NULL,                    -- 1-7 Day Number
    `day_name` VARCHAR(10) NOT NULL,                           -- Day Name
    `period_number` TINYINT UNSIGNED NOT NULL,                 -- 1-8 Period Number
    `availability_for_period` ENUM('Available','Unavailable','Assigned') NOT NULL DEFAULT 'Available',
    `assigned_class_id` INT unsigned NOT NULL,                 -- FK to sch_classes.id
    `assigned_section_id` INT unsigned DEFAULT NULL,           -- FK to sch_sections.id
    `assigned_subject_study_format_id` INT unsigned NOT NULL,  -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    `room_available_from_date` DATE DEFAULT NULL,              -- sch_rooms.room_available_from_date
    `activity_id` INT unsigned NULL,                           -- FK to tt_activity.id
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,  
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ra_class_wise` (`room_availability_id`,`assigned_class_id`, `assigned_section_id`, `assigned_subject_study_format_id`, `start_time`, `end_time`),
    CONSTRAINT `fk_room_availability_detail_room_availability` FOREIGN KEY (`room_availability_id`) REFERENCES `tt_room_availability` (`id`), 
    CONSTRAINT `fk_room_availability_detail_class` FOREIGN KEY (`assigned_class_id`) REFERENCES `sch_classes` (`id`), 
    CONSTRAINT `fk_room_availability_detail_section` FOREIGN KEY (`assigned_section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_room_availability_detail_subject_study_format` FOREIGN KEY (`assigned_subject_study_format_id`) REFERENCES `sch_study_formats` (`id`),
    CONSTRAINT `fk_room_availability_detail_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -----------------------------------------------------------
  --  SECTION 5: TIMETABLE PREPERATION TABLES (DATA PREPERATION)
  -- -----------------------------------------------------------
  -- This table will store the Priority Configuration for the Timetable Generation Process
  CREATE TABLE IF NOT EXISTS `tt_priority_config` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `requirement_consolidation_id` INT UNSIGNED NOT NULL,  -- FK to tt_requirement_consolidation.id
      -- `priority_type` VARCHAR(50) NOT NULL,  -- 'TEACHER', 'STUDENT', 'ROOM', 'PERIOD', 'ACTIVITY'
      -- `priority_name` VARCHAR(100) NOT NULL,  -- 'Maths_Preference', 'Physics_Preference', 'Class_12_Preference', 'Lab_Preference', 'Morning_Preference', 'Hard_Subject'
      -- `priority_value` DECIMAL(8,3) NOT NULL,  -- Priority of this requirement (0.000 to 100.000) Auto-Calculated

    `tot_students` INT UNSIGNED DEFAULT NULL,  -- Total students in this requirement group (tt_class_subject_groups.student_count)
    `teacher_scarcity_index` DECIMAL(7,2) UNSIGNED DEFAULT 1 -- (Here we will count the number of qualified teachers for a subject+Study Format for Every Class+Section)
    `weekly_load_ratio` DECIMAL(7,2) UNSIGNED DEFAULT 1 -- (Required Periods per Week, (Required Periods per Week / Total Periods in a Week))
    `average_teacher_availability_ratio` DECIMAL(7,2) UNSIGNED DEFAULT 1 -- (TAR = (Total Allocated Periods / Weekly Available Working Periods) * 100)
    `rigidity_score` DECIMAL(7,2) UNSIGNED DEFAULT 1 -- (If an activity can happen only in limited slots, it must go first.) Rigidity_Score = Allowed_Slots / Total_Slots
    `resource_scarcity` DECIMAL(7,2) UNSIGNED DEFAULT 1 -- (If only 1 lab serves 8 sections, must be placed early) Resource_Scarcity = Required_Resource_Count / Available_Resources
    `subject_difficulty_index` DECIMAL(7,2) UNSIGNED DEFAULT 1 -- (Harder subjects like Physics/Chemistry/Maths should be placed early)

    `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this priority is active
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_priority_type_name` (`priority_type`, `priority_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- This is the main Table which will be used to assign Teachers & Rooms on
  CREATE TABLE IF NOT EXISTS `tt_activity` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(50) NOT NULL,                        -- Will be fetched from tt_class_subject_groups.code/tt_class_subject_subgroups.code
    `name` VARCHAR(200) NOT NULL,                       -- Will be fetched from tt_class_subject_groups.name/tt_class_subject_subgroups.name
    `academic_term_id` INT UNSIGNED NOT NULL,           -- FK to tt_academic_term.id  -- This is the Term for which this timetable is being generated (New)
    `timetable_type_id` INT unsigned NOT NULL,          -- FK to tt_timetable_type.id
    -- Combining _groups & requirement_subgroups
    `activity_group_id` INT UNSIGNED DEFAULT NULL,      -- FK to 'sch_class_groups_jnt'
    `have_sub_activity` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether this activity has sub activities
    -- Must Field to apply Constraints
    `class_id` INT unsigned NOT NULL,                            -- FK to sch_classes.id
    `section_id` INT unsigned DEFAULT NULL,                      -- FK to sch_sections.id
    `subject_id` INT unsigned NOT NULL,                            -- FK to sch_subjects.id
    `study_format_id` INT unsigned NOT NULL,                       -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    `subject_type_id` INT unsigned NOT NULL,                       -- FK to sch_subject_types.id. e.g MAJOR, MINOR, OPTIONAL, etc.
    `subject_study_format_id` INT unsigned NOT NULL,               -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    --
    `required_weekly_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,   -- Total periods required per week for this Class Group (Class+{Section}+Subject+StudyFormat)
    `min_periods_per_week` TINYINT UNSIGNED DEFAULT NULL,  -- Minimum periods required per week
    `max_periods_per_week` TINYINT UNSIGNED DEFAULT NULL,  -- Maximum periods required per week
    `max_per_day` TINYINT UNSIGNED DEFAULT NULL,  -- Maximum periods per day
    `min_per_day` TINYINT UNSIGNED DEFAULT NULL,  -- Minimum periods per day
    `min_gap_periods` TINYINT UNSIGNED DEFAULT NULL,  -- Minimum gap periods
    `allow_consecutive` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether consecutive periods are allowed
    `max_consecutive` TINYINT UNSIGNED DEFAULT 2,  -- Maximum consecutive periods
    `preferred_periods_json` JSON DEFAULT NULL,  -- On Screen User will see Multiselection of Periods but it will be saved as JSON
    `avoid_periods_json` JSON DEFAULT NULL,  -- On Screen User will see Multiselection of Periods but it will be saved as JSON
    `spread_evenly` TINYINT(1) DEFAULT 1,  -- Whether periods should be spread evenly

    `eligible_teacher_count` INT UNSIGNED DEFAULT NULL,                  -- Number of teachers available for this group (Will capture from Teachers profile)
    `min_teacher_availability_score` DECIMAL(7,2) UNSIGNED DEFAULT 1,    -- Percentage of available teachers for this Class Group (Will capture from Teachers profile)
    `max_teacher_availability_score` DECIMAL(7,2) UNSIGNED DEFAULT 1,    -- Percentage of available teachers for this Class Group (Will capture from Teachers profile)

    `duration_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,  -- If 1 Activity can not be done in 1 Period then this will how many periods required for one activity (e.g. Lab = 2 but will be count as 1 Activity)
    `weekly_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,  -- Number of times per week this activity is scheduled
    `total_periods` SMALLINT UNSIGNED GENERATED ALWAYS AS (`duration_periods` * `weekly_periods`) STORED,
    -- Scheduling preferences
    `split_allowed` TINYINT(1) DEFAULT 0,  -- Whether this activity can be split across non-consecutive slots
    `is_compulsory` TINYINT(1) DEFAULT 1,  -- Must be scheduled?
    `priority` TINYINT UNSIGNED DEFAULT 50,  -- Scheduling priority (0-100) (Will be used in Timetable Scheduling)
    `difficulty_score` TINYINT UNSIGNED DEFAULT 50,  -- For algorithm sorting (higher = harder to schedule) (If No of Teachers/Teacher's Availability is less for a (Subject+Class) then difficulty_score should be high)
    -- Room Allocation
    `compulsory_specific_room_type` TINYINT(1) NOT NULL DEFAULT 0, -- Whether specific room type is required (TRUE - if Specific Room Type is Must)
    `required_room_type_id` INT UNSIGNED NOT NULL,      -- FK to sch_room_types.id (MUST)
    `required_room_id` INT UNSIGNED DEFAULT NULL,      -- FK to sch_rooms.id (OPTIONAL)
    -- Room Requirements
    `requires_room` TINYINT(1) DEFAULT 1,  -- Whether this activity requires a room
    `preferred_room_type_id` INT UNSIGNED DEFAULT NULL,  -- FK to 'sch_room_types'
    `preferred_room_ids` JSON DEFAULT NULL,  -- List of preferred rooms
    -- Newely Addedd
    `difficulty_score_calculated` TINYINT UNSIGNED DEFAULT 50 COMMENT 'Automatically calculated based on constraints, teacher availability, room requirements',
    `teacher_availability_score` TINYINT UNSIGNED DEFAULT 100 COMMENT 'Percentage of available teachers for this activity',
    `room_availability_score` TINYINT UNSIGNED DEFAULT 100 COMMENT 'Percentage of available rooms for this activity',
    `constraint_count` SMALLINT UNSIGNED DEFAULT 0 COMMENT 'Number of constraints affecting this activity',
    `preferred_time_slots_json` JSON DEFAULT NULL COMMENT 'Preferred time slots from requirements',
    `avoid_time_slots_json` JSON DEFAULT NULL COMMENT 'Time slots to avoid from requirements',
    -- Status
    `status` ENUM('DRAFT','ACTIVE','LOCKED','ARCHIVED') NOT NULL DEFAULT 'ACTIVE',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_activity_code` (`code`),
    INDEX `idx_activity_difficulty` (`difficulty_score`, `constraint_count`);
    INDEX `idx_activity_session` (`academic_term_id`),
    INDEX `idx_activity_class_group` (`class_group_id`),
    INDEX `idx_activity_subgroup` (`class_subgroup_id`),
    INDEX `idx_activity_subject` (`subject_id`),
    INDEX `idx_activity_status` (`status`),
    INDEX `idx_activity_generation` ON `tt_activity` (`academic_term_id`, `difficulty_score`, `status`, `is_active`);
    CONSTRAINT `fk_activity_session` FOREIGN KEY (`academic_term_id`) REFERENCES `tt_academic_term` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_activity_class_group` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_activity_subgroup` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_requirement_subgroups` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_activity_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_activity_study_format` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_activity_room_type` FOREIGN KEY (`preferred_room_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_activity_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    -- Must have either class_group or subgroup
    CONSTRAINT `chk_activity_target` CHECK ((`class_group_id` IS NOT NULL AND `class_subgroup_id` IS NULL) OR (`class_group_id` IS NULL AND `class_subgroup_id` IS NOT NULL))
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- 1. In 'activity_group_id' we will be 
  
  CREATE TABLE IF NOT EXISTS `tt_sub_activity` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `parent_activity_id` INT UNSIGNED NOT NULL,  -- FK to tt_activity.id
    `class_requirement_subgroups` INT UNSIGNED NOT NULL,  -- FK to tt_class_requirement_subgroups.id
    `ordinal` TINYINT UNSIGNED NOT NULL,  -- Order of this sub-activity within the parent activity
    `class_id` INT UNSIGNED NOT NULL,  -- FK to sch_classes.id
    `section_id` INT UNSIGNED NOT NULL,  -- FK to sch_sections.id
    -- `code` VARCHAR(60) NOT NULL,  -- e.g., 'ACT_10A_MTH_LAC_001_S1'
    `duration_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,  -- Duration of this sub-activity in periods
    `same_day_as_parent` TINYINT(1) DEFAULT 0,  -- Whether this sub-activity must be scheduled on the same day as the parent activity
    `consecutive_with_previous` TINYINT(1) DEFAULT 0,  -- Whether this sub-activity must be scheduled immediately after the previous sub-activity
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subact_parent_ord` (`parent_activity_id`, `sub_activity_ord`),
    UNIQUE KEY `uq_subact_code` (`code`),
    KEY `idx_subact_parent` (`parent_activity_id`),
    CONSTRAINT `fk_subact_parent` FOREIGN KEY (`parent_activity_id`) REFERENCES `tt_activity` (`id`) ON DELETE CASCADE,
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- This table will store the Activity Priority Scores for the Timetable Generation Process
  CREATE TABLE IF NOT EXISTS `tt_activity_priority` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `activity_id` INT UNSIGNED NOT NULL,  -- FK to tt_activities.id
    `priority_score` DECIMAL(5,2) NOT NULL,  -- 0.00 to 100.00
    `priority_reason` TEXT DEFAULT NULL,  -- Reason for the priority score
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this activity priority is active
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_activity_priority` (`activity_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tt_activity_teacher` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `activity_id` INT UNSIGNED NOT NULL,  -- FK to tt_activity.id
    `teacher_id` INT UNSIGNED NOT NULL,  -- FK to sch_teachers.id
    `assignment_role_id` INT UNSIGNED NOT NULL,  -- FK to tt_assignment_roles.id
    `is_required` TINYINT(1) DEFAULT 1,  -- Whether this teacher is required for the activity
    `ordinal` TINYINT UNSIGNED DEFAULT 1,  -- Order of this teacher in the activity
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this teacher is active
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_at_activity_teacher` (`activity_id`, `teacher_id`),
    KEY `idx_at_teacher` (`teacher_id`),
    CONSTRAINT `fk_at_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_at_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_at_role` FOREIGN KEY (`assignment_role_id`) REFERENCES `tt_teacher_assignment_role` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------
  --  SECTION 6: TIMETABLE GENERATION & STORAGE
  -- -------------------------------------------------
  -- Main Timetable Generation Table
  CREATE TABLE IF NOT EXISTS `tt_timetable` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(50) NOT NULL,  -- e.g., 'TT_2025_26_V1','TT_EXAM_OCT_2025'
    `name` VARCHAR(200) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `academic_session_id` INT UNSIGNED NOT NULL,  -- FK to sch_academic_sessions.id
    `academic_term_id` INT UNSIGNED NOT NULL,  -- FK to tt_academic_term.id  -- This is the Term for which this timetable is generated (New)
    `timetable_type_id` INT UNSIGNED NOT NULL,  -- FK to tt_timetable_type.id
    `period_set_id` INT UNSIGNED NOT NULL,  -- FK to tt_period_set.id
    `effective_from` DATE NOT NULL,  -- Start date of this timetable
    `effective_to` DATE DEFAULT NULL,  -- End date of this timetable
    `generation_method` ENUM('MANUAL','SEMI_AUTO','FULL_AUTO') NOT NULL DEFAULT 'MANUAL',  -- How this timetable was generated
    `version` SMALLINT UNSIGNED NOT NULL DEFAULT 1,  -- Version number of this timetable
    `parent_timetable_id` INT UNSIGNED DEFAULT NULL,  -- FK to tt_timetable.id
    `status` ENUM('DRAFT','GENERATING','GENERATED','PUBLISHED','ARCHIVED') NOT NULL DEFAULT 'DRAFT',  -- Current status of this timetable
    `published_at` TIMESTAMP NULL,  -- When this timetable was published
    `published_by` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
    `constraint_violations` INT UNSIGNED DEFAULT 0,  -- Number of constraint violations in this timetable
    `soft_score` DECIMAL(8,2) DEFAULT NULL,  -- Soft score of this timetable
    `stats_json` JSON DEFAULT NULL,  -- Statistics about this timetable
    -- Newly Added
    `generation_strategy_id` INT UNSIGNED AFTER `generation_method`,
    `optimization_cycles` INT UNSIGNED DEFAULT 0 AFTER `soft_score`,
    `last_optimized_at` TIMESTAMP NULL AFTER `published_at`,
    `quality_score` DECIMAL(5,2) DEFAULT NULL COMMENT 'Overall quality score (0-100) based on constraint satisfaction',
    `teacher_satisfaction_score` DECIMAL(5,2) DEFAULT NULL COMMENT 'Score based on teacher preferences satisfaction',
    `room_utilization_score` DECIMAL(5,2) DEFAULT NULL COMMENT 'Score based on room utilization efficiency',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this timetable is active
    `created_by` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tt_code` (`code`),
    KEY `idx_tt_session` (`academic_session_id`),
    KEY `idx_tt_type` (`timetable_type_id`),
    KEY `idx_tt_status` (`status`),
    KEY `idx_tt_effective` (`effective_from`, `effective_to`),
    CONSTRAINT `fk_tt_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tt_type` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_type` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tt_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_set` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tt_parent` FOREIGN KEY (`parent_timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tt_published_by` FOREIGN KEY (`published_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tt_generation_strategy` FOREIGN KEY (`generation_strategy_id`) REFERENCES `tt_generation_strategy`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tt_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

  -- Real-time Conflict Detection Table (This will capture all the conflicts during generation to resolve)
  -- IMPORTANT: For tracking and resolving scheduling conflicts
  CREATE TABLE IF NOT EXISTS `tt_conflict_detection` (
      `id` INT unsigned NOT NULL AUTO_INCREMENT,
      `timetable_id` INT UNSIGNED NOT NULL,
      `detection_type` ENUM('REAL_TIME','BATCH','VALIDATION','GENERATION') NOT NULL,
      `detected_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `conflict_count` INT UNSIGNED DEFAULT 0,
      `hard_conflicts` INT UNSIGNED DEFAULT 0,
      `soft_conflicts` INT UNSIGNED DEFAULT 0,
      `conflicts_json` JSON DEFAULT NULL,
      `resolution_suggestions_json` JSON DEFAULT NULL,
      `resolved_at` TIMESTAMP NULL,
      `is_active` TINYINT(1) DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      INDEX `idx_conflict_detection_timetable` (`timetable_id`, `detected_at`),
      CONSTRAINT `fk_idx_conflict_detection_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Log of conflict detection events and resolutions';
  -- WHY NEEDED:
    -- 1. Supports the requirement: "Real-time conflict detection capabilities"
    -- 2. Tracks all conflicts during generation and manual adjustments
    -- 3. Provides audit trail for conflict resolution
    -- 4. Enables smart conflict resolution suggestions

  -- Resource Booking & availability Tracking
  -- Use: We will be capturing resource booking to know resource availability and ocupency
  CREATE TABLE IF NOT EXISTS `tt_resource_booking` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `resource_type` ENUM('ROOM','LAB','TEACHER','EQUIPMENT','SPORTS','SPECIAL') NOT NULL,
    `resource_id` INT UNSIGNED NOT NULL,
    `booking_date` DATE NOT NULL,
    `day_of_week` TINYINT UNSIGNED,
    `period_ord` TINYINT UNSIGNED,
    `start_time` TIME,
    `end_time` TIME,
    `booked_for_type` ENUM('ACTIVITY','EXAM','EVENT','MAINTENANCE') NOT NULL,
    `booked_for_id` INT UNSIGNED NOT NULL,
    `purpose` VARCHAR(500),
    `supervisor_id` INT UNSIGNED,
    `status` ENUM('BOOKED','IN_USE','COMPLETED','CANCELLED') DEFAULT 'BOOKED',
    `is_active` TINYINT UNSIGNED DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_resource_booking_date` (`booking_date`, `resource_type`, `resource_id`),
    INDEX `idx_resource_booking_time` (`start_time`, `end_time`),
    CONSTRAINT `fk_idx_resource_booking_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `sch_teachers`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Resource booking and allocation tracking';

  CREATE TABLE IF NOT EXISTS `tt_generation_run` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `timetable_id` INT UNSIGNED NOT NULL,  -- FK to tt_timetable.id
    `run_number` INT UNSIGNED NOT NULL DEFAULT 1,  -- Run number of this generation
    `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,  -- When this generation run started
    `finished_at` TIMESTAMP NULL,  -- When this generation run finished
    `status` ENUM('QUEUED','RUNNING','COMPLETED','FAILED','CANCELLED') NOT NULL DEFAULT 'QUEUED',  -- Status of this generation run
    `strategy_id` INT UNSIGNED,  -- FK to tt_generation_strategy.id
    `algorithm_version` VARCHAR(20) DEFAULT NULL,  -- Version of the algorithm used
    `max_recursion_depth` INT UNSIGNED DEFAULT 14,  -- Maximum recursion depth
    `max_placement_attempts` INT UNSIGNED DEFAULT NULL,  -- Maximum placement attempts
    `retry_count` TINYINT UNSIGNED DEFAULT 0,  -- Number of retry attempts
    `params_json` JSON DEFAULT NULL,  -- Parameters used for this generation run
    `activities_total` INT UNSIGNED DEFAULT 0,  -- Total number of activities
    `activities_placed` INT UNSIGNED DEFAULT 0,  -- Number of activities placed
    `activities_failed` INT UNSIGNED DEFAULT 0,  -- Number of activities that failed to be placed
    `hard_violations` INT UNSIGNED DEFAULT 0,  -- Number of hard violations
    `soft_violations` INT UNSIGNED DEFAULT 0,  -- Number of soft violations
    `soft_score` DECIMAL(10,4) DEFAULT NULL,  -- Soft score of this generation run
    `stats_json` JSON DEFAULT NULL,  -- Statistics about this generation run
    `error_message` TEXT DEFAULT NULL,  -- Error message if generation failed
    `triggered_by` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_gr_tt_run` (`timetable_id`, `run_number`),
    KEY `idx_gr_status` (`status`),
    CONSTRAINT `fk_gr_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_gr_triggered_by` FOREIGN KEY (`triggered_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- This table will capture what all constraint we have violated during Timetable generation
  CREATE TABLE IF NOT EXISTS `tt_constraint_violation` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `timetable_id` INT UNSIGNED NOT NULL,  -- FK to tt_timetable.id
    `constraint_id` INT UNSIGNED NOT NULL,  -- FK to tt_constraint.id
    `violation_type` ENUM('HARD','SOFT') NOT NULL,  -- Type of violation
    `violation_count` INT UNSIGNED NOT NULL,  -- Number of violations
    `violation_details` JSON DEFAULT NULL,  -- Details of the violation
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_cv_timetable` (`timetable_id`),
    KEY `idx_cv_constraint` (`constraint_id`),
    CONSTRAINT `fk_cv_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cv_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraint` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tt_timetable_cell` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `timetable_id` INT UNSIGNED NOT NULL,  -- FK to tt_timetable.id
    `generation_run_id` INT UNSIGNED DEFAULT NULL,  -- FK to tt_generation_run.id
    `day_of_week` TINYINT UNSIGNED NOT NULL,  -- Day of the week
    `period_ord` TINYINT UNSIGNED NOT NULL,  -- Period order
    `cell_date` DATE DEFAULT NULL,  -- Cell date
    `class_group_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_class_groups.id
    `class_subgroup_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_class_subgroups.id
    `activity_id` INT UNSIGNED DEFAULT NULL,  -- FK to tt_activity.id
    `sub_activity_id` INT UNSIGNED DEFAULT NULL,  -- FK to tt_sub_activity.id
    `room_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_rooms.id
    `source` ENUM('AUTO','MANUAL','SWAP','LOCK') NOT NULL DEFAULT 'AUTO',  -- Source of this cell
    `is_locked` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether this cell is locked
    `locked_by` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
    `locked_at` TIMESTAMP NULL,
    `has_conflict` TINYINT(1) DEFAULT 0,  -- Whether this cell has a conflict
    `conflict_details_json` JSON DEFAULT NULL,  -- Details of the conflict
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this cell is active
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_cell_tt_day_period_group` (`timetable_id`, `day_of_week`, `period_ord`, `class_group_id`, `class_subgroup_id`),
    KEY `idx_cell_tt` (`timetable_id`),
    KEY `idx_cell_day_period` (`day_of_week`, `period_ord`),
    KEY `idx_cell_activity` (`activity_id`),
    KEY `idx_cell_room` (`room_id`),
    KEY `idx_cell_date` (`cell_date`),
    CONSTRAINT `fk_cell_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cell_gen_run` FOREIGN KEY (`generation_run_id`) REFERENCES `tt_generation_run` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_cell_class_group` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cell_subgroup` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_requirement_subgroups` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cell_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_cell_sub_activity` FOREIGN KEY (`sub_activity_id`) REFERENCES `tt_sub_activity` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_cell_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_cell_locked_by` FOREIGN KEY (`locked_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `chk_cell_target` CHECK ((`class_group_id` IS NOT NULL AND `class_subgroup_id` IS NULL) OR (`class_group_id` IS NULL AND `class_subgroup_id` IS NOT NULL))
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tt_timetable_cell_teacher` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `cell_id` INT UNSIGNED NOT NULL,  -- FK to tt_timetable_cell.id
    `teacher_id` INT UNSIGNED NOT NULL,  -- FK to sch_teachers.id
    `assignment_role_id` INT UNSIGNED NOT NULL,  -- FK to sch_assignment_roles.id
    `is_substitute` TINYINT(1) DEFAULT 0,  -- Whether this teacher is a substitute
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this teacher is active
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_cct_cell_teacher` (`cell_id`, `teacher_id`),
    KEY `idx_cct_teacher` (`teacher_id`),
    CONSTRAINT `fk_cct_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cell` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cct_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cct_role` FOREIGN KEY (`assignment_role_id`) REFERENCES `tt_teacher_assignment_role` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------
  --  SECTION 7: TIMETABLE MANUAL MODIFICATION
  -- -------------------------------------------------

   -- PENDING

  -- -------------------------------------------------
  --  SECTION 8: TIMETABLE REPORTS & LOGS
  -- -------------------------------------------------

  -- -------------------------------------------------
  --  SECTION 8.1 : TEACHER WORKLOAD & ANALYTICS
  -- -------------------------------------------------

  CREATE TABLE IF NOT EXISTS `tt_teacher_workload` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `teacher_id` INT UNSIGNED NOT NULL,  -- FK to sch_teachers.id
    `academic_session_id` INT UNSIGNED NOT NULL,  -- FK to sch_academic_sessions.id
    `timetable_id` INT UNSIGNED DEFAULT NULL,  -- FK to tt_timetable.id
    `weekly_periods_assigned` SMALLINT UNSIGNED DEFAULT 0,  -- Number of periods assigned
    `weekly_periods_max` SMALLINT UNSIGNED DEFAULT NULL,  -- Maximum number of periods allowed
    `weekly_periods_min` SMALLINT UNSIGNED DEFAULT NULL,  -- Minimum number of periods allowed
    `daily_distribution_json` JSON DEFAULT NULL,  -- Daily distribution of periods
    `subjects_assigned_json` JSON DEFAULT NULL,  -- Subjects assigned to the teacher
    `classes_assigned_json` JSON DEFAULT NULL,  -- Classes assigned to the teacher
    `utilization_percent` DECIMAL(5,2) DEFAULT NULL,  -- Utilization percentage
    `gap_periods_total` SMALLINT UNSIGNED DEFAULT 0,  -- Total gap periods
    `consecutive_max` TINYINT UNSIGNED DEFAULT 0,  -- Maximum consecutive periods
    `last_calculated_at` TIMESTAMP NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this workload is active
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tw_teacher_session_tt` (`teacher_id`, `academic_session_id`, `timetable_id`),
    KEY `idx_tw_session` (`academic_session_id`),
    CONSTRAINT `fk_tw_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tw_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tw_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------
  --  SECTION 9 : AUDIT & HISTORY
  -- -------------------------------------------------

  CREATE TABLE IF NOT EXISTS `tt_change_log` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `timetable_id` INT UNSIGNED NOT NULL,  -- FK to tt_timetable.id
    `cell_id` INT UNSIGNED DEFAULT NULL,  -- FK to tt_timetable_cell.id
    `change_type` ENUM('CREATE','UPDATE','DELETE','LOCK','UNLOCK','SWAP','SUBSTITUTE') NOT NULL,
    `change_date` DATE NOT NULL,  -- Date of change
    `old_values_json` JSON DEFAULT NULL,  -- Old values of the cell
    `new_values_json` JSON DEFAULT NULL,  -- New values of the cell
    `reason` VARCHAR(500) DEFAULT NULL,  -- Reason for the change
    `changed_by` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_cl_timetable` (`timetable_id`),
    KEY `idx_cl_cell` (`cell_id`),
    KEY `idx_cl_date` (`change_date`),
    KEY `idx_cl_type` (`change_type`),
    CONSTRAINT `fk_cl_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cl_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cell` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_cl_changed_by` FOREIGN KEY (`changed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------
  --  SECTION 10: SUBSTITUTION MANAGEMENT
  -- -------------------------------------------------

  CREATE TABLE IF NOT EXISTS `tt_teacher_absence` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `teacher_id` INT UNSIGNED NOT NULL,  -- FK to sch_teachers.id
    `absence_date` DATE NOT NULL,  -- Date of absence
    `absence_type` ENUM('LEAVE','SICK','TRAINING','OFFICIAL_DUTY','OTHER') NOT NULL,  -- Type of absence
    `start_period` TINYINT UNSIGNED DEFAULT NULL,  -- Start period of absence
    `end_period` TINYINT UNSIGNED DEFAULT NULL,  -- End period of absence
    `reason` VARCHAR(500) DEFAULT NULL,  -- Reason for absence
    `status` ENUM('PENDING','APPROVED','REJECTED','CANCELLED') NOT NULL DEFAULT 'PENDING',
    `approved_by` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
    `approved_at` TIMESTAMP NULL,  -- Date and time when absence was approved
    `substitution_required` TINYINT(1) DEFAULT 1,  -- Whether substitution is required
    `substitution_completed` TINYINT(1) DEFAULT 0,  -- Whether substitution has been completed
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this absence is active
    `created_by` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ta_teacher_date` (`teacher_id`, `absence_date`),
    KEY `idx_ta_date` (`absence_date`),
    KEY `idx_ta_status` (`status`),
    CONSTRAINT `fk_ta_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ta_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ta_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tt_substitution_log` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `teacher_absence_id` INT UNSIGNED DEFAULT NULL,  -- FK to tt_teacher_absence.id
    `cell_id` INT UNSIGNED NOT NULL,  -- FK to tt_timetable_cell.id
    `substitution_date` DATE NOT NULL,  -- Date of substitution
    `absent_teacher_id` INT UNSIGNED NOT NULL,  -- FK to sch_teachers.id
    `substitute_teacher_id` INT UNSIGNED NOT NULL,  -- FK to sch_teachers.id
    `assignment_method` ENUM('AUTO','MANUAL','SWAP') NOT NULL DEFAULT 'MANUAL',  -- Method of assignment
    `reason` VARCHAR(500) DEFAULT NULL,  -- Reason for substitution
    `status` ENUM('ASSIGNED','COMPLETED','CANCELLED') NOT NULL DEFAULT 'ASSIGNED',  -- Status of substitution
    `notified_at` TIMESTAMP NULL,  -- Date and time when substitution was notified
    `accepted_at` TIMESTAMP NULL,  -- Date and time when substitution was accepted
    `completed_at` TIMESTAMP NULL,  -- Date and time when substitution was completed
    `feedback` TEXT DEFAULT NULL,  -- Feedback for the substitution
    `assigned_by` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this substitution is active
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_sub_date` (`substitution_date`),
    KEY `idx_sub_absent` (`absent_teacher_id`),
    KEY `idx_sub_substitute` (`substitute_teacher_id`),
    KEY `idx_sub_status` (`status`),
    CONSTRAINT `fk_sub_absence` FOREIGN KEY (`teacher_absence_id`) REFERENCES `tt_teacher_absence` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sub_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cell` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sub_absent_teacher` FOREIGN KEY (`absent_teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sub_substitute_teacher` FOREIGN KEY (`substitute_teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sub_assigned_by` FOREIGN KEY (`assigned_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



  -- ===========================================================================================
  -- SECTION 11: REFERENCE TABLES FROM OTHER MODULES
  -- ===========================================================================================

  -- This table is a replica of 'prm_tenant' table in 'prmprime_db' database
  -- This will store the details of the Organizations/Schools using this Timetable Module.
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

  -- This table will store the Academic Sessions for the Organization/School. It will have FK to sch_organizations table and glb_academic_sessions table.
  CREATE TABLE IF NOT EXISTS `sch_org_academic_sessions_jnt` (
    `id` SMALLINT unsigned NOT NULL AUTO_INCREMENT,
    `academic_sessions_id` INT unsigned NOT NULL,  -- FK to glb_academic_sessions.id
    `short_name` varchar(10) NOT NULL,
    `name` varchar(50) NOT NULL,
    `start_date` date NOT NULL,  -- Start date of the Academic Session for this Organization/School
    `end_date` date NOT NULL,    -- End date of the Academic Session for this Organization/School
    `is_current` tinyint(1) NOT NULL DEFAULT '0',  -- Whether this is the current Academic Session for the Organization/School
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
  -- This will help us to know which Boards are associated with which Organizations/Schools and for which Academic Sessions.
  CREATE TABLE IF NOT EXISTS `sch_board_organization_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `academic_sessions_id` INT unsigned NOT NULL,  -- FK to sch_org_academic_sessions_jnt.id
    `board_id` INT unsigned NOT NULL,              -- FK to glb_boards.id
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_boardOrg_boardId` FOREIGN KEY (`board_id`) REFERENCES `glb_boards` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_boardOrg_academicSessionId` FOREIGN KEY (`academic_sessions_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  
  -- This table will store the Classes for the Organization/School. This will help us to manage the classes in the school and link it with timetable.
  CREATE TABLE IF NOT EXISTS `sch_classes` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,             -- will have sequence order to showcase in the List
    `code` CHAR(5) NOT NULL,                    -- e.g., 'BV1','BV2','1st','2nd', '3rd' and so on (This will be used for Timetable)
    `short_name` varchar(20) DEFAULT NULL,      -- e.g. 'Grade-1' or '10th', '11th', '12th'
    `name` varchar(50) NOT NULL,                -- e.g. 'Grade 1' or 'Class - 10th', 'Class - 11th', 'Class - 12th'
    `is_active` tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_classes_code` (`code`),
    UNIQUE KEY `uq_classes_shortName` (`short_name`),
    UNIQUE KEY `uq_classes_name` (`name`),
    UNIQUE KEY `uq_classes_ordinal` (`ordinal`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- This table will store the Sections for the Organization/School. This will help us to manage the sections for every class in the school and link it with timetable.
  CREATE TABLE IF NOT EXISTS `sch_sections` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint unsigned DEFAULT 1,       -- will have sequence order for Sections (Auto Update by Drag & Drop)
    `code` CHAR(5) NOT NULL,                    -- e.g., 'A','B','C','D' and so on (This will be used for Timetable)
    `short_name` varchar(20) DEFAULT NULL,      -- e.g. 'SEC-A' or 'SEC-B' (NEW)
    `name` varchar(50) NOT NULL,                -- e.g. 'Section - A', 'Section - B'
    `is_active` tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_sections_name` (`name`),
    UNIQUE KEY `uq_sections_code` (`code`),
    UNIQUE KEY `uq_sections_ordinal` (`ordinal`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- This is a Junction Table to link Classes with Sections. This will help us to manage the sections for every class in the school and link it with timetable.
  CREATE TABLE IF NOT EXISTS `sch_class_section_jnt` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,                        -- will have sequence order  (Added new) (Auto Update by Drag & Drop)
    `class_id` int unsigned NOT NULL,                      -- FK to sch_classes
    `section_id` int unsigned NOT NULL,                    -- FK to sch_sections
    `code` char(10) NOT NULL,                              -- Combination of class Code + section Code i.e. '8th_A', '10h_B' (Changed from class_secton_code)
    `name` varchar(50) NOT NULL,                           -- e.g. 'Grade 1' or 'Class - 10th', 'Class - 11th Section - A', 'Class - 12th Section - B'
    `capacity` tinyint unsigned DEFAULT NULL,              -- Targeted / Planned Quantity of stundets in Each Sections of every class.
    `actual_total_student` tinyint unsigned DEFAULT NULL,  -- Actual Total Number of Students in the Class+Section (Auto Calculate from `std_student_academic_sessions` table)
    `min_required_student` tinyint unsigned DEFAULT NULL,  -- Minimum Number of Student required to start a new section for a Class
    `max_allowed_student` tinyint unsigned DEFAULT NULL,   -- Maximum Number of Student allowed in a class+section (What Teacher:Ratio Scholl want to maintain for a class)
    `class_teacher_id` INT unsigned NOT NULL,              -- FK to sch_users (Who is assigned as class teacher for this class+section)
    `assistance_class_teacher_id` INT unsigned NOT NULL,   -- FK to sch_users (Who is assigned as assistance class teacher for this class+section)
    `rooms_type_id` int unsigned NOT NULL,                 -- FK to 'sch_rooms_type' (Which type of room is required for this class+section)
    `class_house_room_id` int unsigned NOT NULL,           -- FK to 'sch_rooms' (Which Room is assigned as class house for this class+section)
    `total_periods_daily` tinyint unsigned DEFAULT NULL,   -- Total Number of Periods in a day for this class+section
    `is_active` tinyint(1) NOT NULL DEFAULT 1,             -- Whether this class+section is active
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_classSection_ordinal` (`ordinal`),
    UNIQUE KEY `uq_classSection_code` (`code`),
    UNIQUE KEY `uq_classSection_name` (`name`),
    UNIQUE KEY `uq_classSection_classId_sectionId` (`class_id`,`section_id`),
    CONSTRAINT `fk_classSection_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_classSection_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_classSection_classTeacherId` FOREIGN KEY (`class_teacher_id`) REFERENCES `sys_users` (`id`),
    CONSTRAINT `fk_classSection_assistanceClassTeacherId` FOREIGN KEY (`assistance_class_teacher_id`) REFERENCES `sys_users` (`id`),
    CONSTRAINT `fk_classSection_roomsTypeId` FOREIGN KEY (`rooms_type_id`) REFERENCES `sch_rooms_type` (`id`),
    CONSTRAINT `fk_classSection_classHouseRoomId` FOREIGN KEY (`class_house_room_id`) REFERENCES `sch_rooms` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- subject_type will represent what type of subject it is - Major, Minor, Core, Main, Optional etc.
  -- This will help us to manage the subjects in the school and link it with timetable. We can also use this to define the rules like Major Subject should be taught in first 4 periods of the day, or Core Subjects should be taught in the morning shift and so on.
  CREATE TABLE IF NOT EXISTS `sch_subject_types` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `code` char(5) NOT NULL,            -- 'MAJ','MIN','OPT','ACT','SPO'
    `short_name` varchar(20) NOT NULL,  -- 'MAJOR','MINOR','OPTIONAL'
    `name` varchar(50) NOT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subjectTypes_shortName` (`short_name`),
    UNIQUE KEY `uq_subjectTypes_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- study_format will represent in which format the subject will be taught - Lecture, Lab, Practical, Tutorial, Seminar, Workshop, Group Discussion etc.
  CREATE TABLE IF NOT EXISTS `sch_study_formats` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `code` CHAR(5) NOT NULL,            -- e.g., 'LECT','LAB','PRAC','TUT','SEM','WSH','GRD','OTH'
    `short_name` varchar(20) NOT NULL,  -- 'LECTURE','LAB','PRACTICAL','TUTORIAL','SEMINAR','WORKSHOP','GROUP_DISCUSSION','OTHER'
    `name` varchar(50) NOT NULL,        -- 'LECTURE','LAB','PRACTICAL','TUTORIAL','SEMINAR','WORKSHOP','GROUP_DISCUSSION','OTHER'
    `is_active` tinyint(1) NOT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_studyFormats_shortName` (`short_name`),
    UNIQUE KEY `uq_studyFormats_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Data Seed for Study_Format - LECTURE, LAB, PRACTICAL, TUTORIAL, SEMINAR, WORKSHOP, GROUP_DISCUSSION, OTHER

  -- This table will store the Subjects for the Organization/School. This will help us to manage the subjects in the school and link it with timetable.
  CREATE TABLE IF NOT EXISTS `sch_subjects` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `code` CHAR(5) NOT NULL,            -- e.g., 'SCI','MTH','SST','ENG' and so on (This will be used for Timetable)
    `short_name` varchar(20) NOT NULL,  -- e.g. 'SCIENCE','MATH','SST','ENGLISH' and so on
    `name` varchar(50) NOT NULL,        -- 'SCIENCE','MATH','SST','ENGLISH' and so on
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subjects_shortName` (`short_name`),
    UNIQUE KEY `uq_subjects_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- subject_study_format is grouping for different streams like Sci-10 Lacture, Arts-10 Activity, Core-10
  -- I have removed 'sub_types' from 'sch_subject_study_format_jnt' because one Subject_StudyFormat may belongs to different Subject_type for different classes
  -- Removed 'short_name' as we can use `sub_stdformat_code`
  CREATE TABLE IF NOT EXISTS `sch_subject_study_format_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint unsigned NOT NULL,          -- will have sequence order (Auto Update by Drag & Drop)
    `subject_id` INT unsigned NOT NULL,           -- FK to 'sch_subjects'
    `study_format_id` int unsigned NOT NULL,      -- FK to 'sch_study_formats'
    `subject_type_id` int unsigned NOT NULL,      -- FK to 'sch_subject_types'
    `code` CHAR(30) NOT NULL,                     -- e.g., 'SCI_LAC','SCI_LAB','SST_LAC','ENG_LAC' (Changed from 'subject_studyformat_code')
    `name` varchar(50) NOT NULL,                  -- e.g., 'Science Lecture','Science Lab','Math Lecture','Math Lab' and so on
       --
    `require_class_house_room` TINYINT(1) NOT NULL DEFAULT 0, -- Whether Class House Room is required for this Class Group
    `compulsory_specific_room_type` TINYINT(1) NOT NULL DEFAULT 0, -- Whether specific room type is required (TRUE - if Specific Room Type is Must e.g. Lab Subject will require Lab Room)
    `required_room_type_id` INT UNSIGNED NOT NULL,      -- FK to sch_rooms_type.id (Required) (e.g. Lab Subject will require Lab Room Type                                                                        )
    `required_room_id` INT UNSIGNED DEFAULT NULL,      -- FK to sch_rooms.id (Optional) If specific room is required for this subject_study_format then we can assign that specific room here otherwise it will be NULL and any room of required_room_type can be assigned during timetable creation.
    --
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subStudyFormat_code` (`code`),
    UNIQUE KEY `uq_subStudyFormat_subjectId_stFormat` (`subject_id`,`study_format_id`),
    CONSTRAINT `fk_subStudyFormat_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subStudyFormat_studyFormatId` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subStudyFormat_subjectTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Ths table will be used to define different Class Groups like 10th-A Science Lecture Major, 7th-B Commerce Optional etc.
  -- old name 'sch_subject_study_format_class_subj_types_jnt' changed to 'sch_class_groups_jnt'
  CREATE TABLE IF NOT EXISTS `sch_class_groups_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `class_id` int unsigned NOT NULL,             -- FK to 'sch_classes'
    `section_id` int unsigned NOT NULL,           -- FK to 'sch_sections' (Optional)
    `subject_Study_format_id` INT unsigned NOT NULL,  -- FK to 'sch_subject_study_format_jnt'
    `subject_type_id` int unsigned NOT NULL,      -- FK to 'sch_subject_types'
    `code` CHAR(50) NOT NULL, -- Combination of (Class+Section+Subject+StudyFormat+SubjType) e.g., '10h_A_SCI_LAC_MAJ','8th_MAT_LAC_OPT' (This will be used for Timetable)
    `name` varchar(100) NOT NULL,                 -- 10th-A Science Lacture Major
    -- Information for Timetable Module
    `is_compulsory` tinyint(1) NOT NULL DEFAULT '0',       -- Is this Subject compulsory for Student or Optional
    `required_weekly_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,   -- Total periods required per week for this Class Group (Class+{Section}+Subject+StudyFormat)
    `min_weekly_periods` TINYINT UNSIGNED DEFAULT NULL,    -- Minimum periods required per week for this Class Group
    `max_weekly_periods` TINYINT UNSIGNED DEFAULT NULL,    -- Maximum periods required per week for this Class Group
    `min_daily_periods` TINYINT UNSIGNED DEFAULT NULL,     -- Minimum periods per day for this Class Group
    `max_daily_periods` TINYINT UNSIGNED DEFAULT NULL,     -- Maximum periods per day for this Class Group
    `min_gap_between_periods` TINYINT UNSIGNED DEFAULT NULL,       -- Minimum gap periods for this Class Group
    `allow_consecutive_periods` TINYINT(1) NOT NULL DEFAULT 0,     -- Whether consecutive periods are allowed for this Class Group
    `max_consecutive_periods` TINYINT UNSIGNED DEFAULT 1,          -- Maximum consecutive periods
    `priority_score` SMALLINT UNSIGNED DEFAULT 10,                 -- Priority of this requirement on 1-100 scale
    --
    `require_class_house_room` TINYINT(1) NOT NULL DEFAULT 0, -- Whether Class House Room is required for this Class Group
    `compulsory_specific_room_type` TINYINT(1) NOT NULL DEFAULT 0, -- Whether specific room type is required (TRUE - if Specific Room Type is Must)
    `required_room_type_id` INT UNSIGNED NOT NULL,      -- FK to sch_rooms_type.id (Required)
    `required_room_id` INT UNSIGNED DEFAULT NULL,      -- FK to sch_rooms.id (Optional)
    -- Audit Fields
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_classGroups_subStdformatCode` (`code`),
    UNIQUE KEY `uq_classGroups_cls_Sec_subStdFmt_SubTyp` (`class_id`,`section_id`,`subject_Study_format_id`),
    CONSTRAINT `fk_classGroups_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_classGroups_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_classGroups_subjStudyFormatId` FOREIGN KEY (`subject_Study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_classGroups_subTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`),
    CONSTRAINT `fk_classGroups_roomTypeId` FOREIGN KEY (`required_room_type_id`) REFERENCES `sch_rooms_type` (`id`),
    CONSTRAINT `fk_classGroups_roomId` FOREIGN KEY (`required_room_id`) REFERENCES `sch_rooms` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- There will be a Variable in 'sch_settings' table named (Subj_Group_will_be_used_for_all_sections_of_a_class)
  -- Remove above condition and make Scetion_id optional.
  -- if 'required_room_type' is House Room, then 'required_room_id' will be ignored.
  -- Table 'sch_subject_groups' will be used to assign all subjects to the students
  CREATE TABLE IF NOT EXISTS `sch_subject_groups` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `class_id` int UNSIGNED NOT NULL,   -- FK to 'sch_classes'
    `section_id` int UNSIGNED NULL,     -- FK (Section can be null if Group will be used for all sectons) (Optional)
    `code` CHAR(20) NOT NULL,           -- Combination of (Class+{Section}+Subject+StudyFormat+SubjType) e.g., '10h_A_SCI_LAC_MAJ','8th_MAT_LAC_OPT' (This will be used for Timetable)
    `short_name` varchar(50) NOT NULL,  -- 7th Science, 7th Commerce, 7th-A Science etc.
    `name` varchar(100) NOT NULL,       -- '7th (Sci,Mth,Eng,Hindi,SST with Sanskrit,Dance)'
    `registered_students_count` int NOT NULL DEFAULT 0, -- Total registered students in this group
    `default_group_for_class` tinyint(1) NOT NULL DEFAULT 0, -- Whether this group is default for the class
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subjectGroups_code` (`code`),
    UNIQUE KEY `uq_subjectGroups_shortName` (`short_name`),
    UNIQUE KEY `uq_subjectGroups_name` (`class_id`,`name`),
    CONSTRAINT `fk_subGroups_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subGroups_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- There will be a Variable in 'sch_settings' table named (Subj_Group_will_be_used_for_all_sections_of_a_class)
  -- Remove above condition and make Scetion_id optional.
 
  CREATE TABLE IF NOT EXISTS `sch_subject_group_subject_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `subject_group_id` INT unsigned NOT NULL,              -- FK to 'sch_subject_groups'
    `class_group_id` INT unsigned NOT NULL,                -- FK to 'sch_class_groups_jnt'
    `subject_id` int unsigned NOT NULL,                    -- FK to 'sch_subjects' (De-Normalization)
    `subject_study_format_id` INT unsigned NOT NULL,       -- FK to 'sch_subject_study_format_jnt'
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subjGrpSubj_subjGrpId_classGroup` (`subject_group_id`,`class_group_id`),
    CONSTRAINT `fk_subjGrpSubj_subjectGroup` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_classGroup` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_subjectStudyFormatId` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Add new Field for Timetable -
  -- is_compulsory, min_periods_per_week, max_periods_per_week, max_per_day, min_per_day, min_gap_periods, allow_consecutive, max_consecutive, priority, compulsory_room_type

  -- Building Coding format is - 2 Digit for Buildings(10-99)
  CREATE TABLE IF NOT EXISTS `sch_buildings` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `code` char(10) NOT NULL,                      -- 2 digits code (10,11,12) 
    `short_name` varchar(30) NOT NULL,            -- e.g., 'Junior Wing','Primary Wing','Middle Wing','Senior Wing','Administration Wings'
    `name` varchar(50) NOT NULL,                  -- Detailed Name of the Building
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_buildings_code` (`code`),
    UNIQUE KEY `uq_buildings_name` (`short_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tables for Room types, this will be used to define different types of rooms like Science Lab, Computer Lab, Sports Room etc.
  CREATE TABLE IF NOT EXISTS `sch_rooms_type` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `code` CHAR(10) NOT NULL,                         -- e.g., 'SCI_LAB','BIO_LAB','CRI_GRD','TT_ROOM','BDM_CRT', "HOUSE_ROOM"
    `short_name` varchar(30) NOT NULL,                -- e.g., 'Science Lab','Biology Lab','Cricket Ground','Table Tanis Room','Badminton Court'
    `name` varchar(100) NOT NULL,
    `required_resources` text DEFAULT NULL,           -- e.g., 'Microscopes, Lab Coats, Safety Goggles' for Science Lab
    `class_house_room` tinyint(1) NOT NULL DEFAULT 0, -- 1=Class House Room, 0=Other Room
    `room_count_in_category` smallint unsigned DEFAULT 0, -- Total Number of Rooms in this category
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_roomType_code` (`code`),
    UNIQUE KEY `uq_roomType_shortName` (`short_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Room Coding format is - 2 Digit for Buildings(10-99), 1 Digit-Building Floor(G,F,S,T,F / A,B,C,D,E), & Last 3 Character defin Class+Section (09A,10A,12B)
  CREATE TABLE IF NOT EXISTS `sch_rooms` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `building_id` int unsigned NOT NULL,      -- FK to 'sch_buildings' table
    `room_type_id` int NOT NULL,              -- FK to 'sch_rooms_type' table
    `code` CHAR(20) NOT NULL,                 -- e.g., '11G-10A','12F-11A','11S-12A' and so on (This will be used for Timetable)
    `short_name` varchar(50) NOT NULL,        -- e.g., 'Junior Wing','Primary Wing','Middle Wing','Senior Wing','Administration Wings'
    `name` varchar(100) NOT NULL,
    `capacity` int unsigned DEFAULT NULL,               -- Seating Capacity of the Room
    `max_limit` int unsigned DEFAULT NULL,              -- Maximum Limit of the Room, Maximum how many students can accomodate in the room
    `resource_tags` text DEFAULT NULL,                  -- e.g., 'Projector, Smart Board, AC, Lab Equipment' etc.
    `can_host_lecture` TINYINT(1) NOT NULL DEFAULT 0,   -- Seats + Writing Surface
    `can_host_practical` TINYINT(1) NOT NULL DEFAULT 0, -- Seats + Writing Surface + Lab Equipment
    `can_host_exam` TINYINT(1) NOT NULL DEFAULT 0,      -- Seats + Writing Surface + Exam Equipment
    `can_host_activity` TINYINT(1) NOT NULL DEFAULT 0,  -- Open space for movement
    `can_host_sports` TINYINT(1) NOT NULL DEFAULT 0,    -- Specific for PE/Games
    `room_available_from_date` DATE DEFAULT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_rooms_code` (`code`),
    UNIQUE KEY `uq_rooms_shortName` (`short_name`),
    CONSTRAINT `fk_rooms_buildingId` FOREIGN KEY (`building_id`) REFERENCES `sch_buildings` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_rooms_roomTypeId` FOREIGN KEY (`room_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Teacher table will store additional information about teachers
  CREATE TABLE IF NOT EXISTS `sch_employees` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` INT UNSIGNED NOT NULL,  -- fk to sys_users.id
    -- Employee id details
    `emp_code` VARCHAR(20) NOT NULL,     -- Employee Code (Unique code for each user) (This will be used for QR Code)
    `emp_id_card_type` ENUM('QR','RFID','NFC','Barcode') NOT NULL DEFAULT 'QR',
    `emp_smart_card_id` VARCHAR(100) DEFAULT NULL,       -- RFID/NFC Tag ID
    -- 
    `is_teacher` TINYINT(1) NOT NULL DEFAULT 0,
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
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `teachers_emp_code_unique` (`emp_code`),
    KEY `teachers_user_id_foreign` (`user_id`),
    CONSTRAINT `fk_teachers_userId` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Teacher Profile table will store detailed proficiency to teach specific subjects, study formats, and classes
  CREATE TABLE IF NOT EXISTS `sch_teacher_profile` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id` INT UNSIGNED NOT NULL,             -- FK sch_employees.id
    `user_id` INT UNSIGNED NOT NULL,                 -- FK sys_users.id
    `role_id` INT UNSIGNED NOT NULL,                 -- FK to   Teacher / Principal / etc.
    `department_id` INT UNSIGNED NOT NULL,           -- sch_department.id 
    `designation_id` INT UNSIGNED NOT NULL,          -- sch_designation.id
    `teacher_house_room_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_rooms.id
    -- Employment nature & capability
    `is_full_time` TINYINT(1) DEFAULT 1,
    `preferred_shift` INT UNSIGNED DEFAULT NULL,    -- FK to sch_shift.id
    `capable_handling_multiple_classes` TINYINT(1) DEFAULT 0,  -- Is he capable of handling un-assigned classes
    `can_be_used_for_substitution` TINYINT(1) DEFAULT 1,
    -- Skills & Responsibilities (JSON for flexibility)
    `certified_for_lab` TINYINT(1) DEFAULT 0,          -- allowed to conduct practicals
    `is_proficient_with_computer` TINYINT(1) DEFAULT 0,
    `can_manage_staff` TINYINT(1) DEFAULT 0,
    `special_skill_area` VARCHAR(100) DEFAULT NULL,
    `soft_skills` JSON DEFAULT NULL,                             -- e.g., ["leadership", "communication", "problem_solving"]
    `assignment_meta` JSON DEFAULT NULL,                         -- e.g. { "qualification": "M.Sc Physics", "experience": "7 years" }
    -- LOAD & SCHEDULING CONSTRAINTS
    `max_available_periods_weekly` TINYINT UNSIGNED DEFAULT 48,  -- How many Maximum Periods teacher can take in a week (Based on Contract and Availability)
    `min_available_periods_weekly` TINYINT UNSIGNED DEFAULT 36,  -- How many Minimum Periods teacher should take in a week (Based on Contract and Availability)
    `max_allocated_periods_weekly` TINYINT UNSIGNED DEFAULT 1,   -- Auto Calculated on assignment basis (Count of Classes+Subject_Study_format allocated)
    `min_allocated_periods_weekly` TINYINT UNSIGNED DEFAULT 1,   -- Auto Calculated on assignment basis (Count of Classes+Subject_Study_format allocated)
    `can_be_split_across_sections` TINYINT(1) DEFAULT 0,         -- Can the Allocation be split accros Sections? e.g. 10th Science Lecture can be taken by same teacher for both sections or not.
    -- Performance & compliance
    `min_teacher_availability_score` DECIMAL(7,2) UNSIGNED DEFAULT 1,  -- Percentage of available teachers for this Class Group (Will capture from Teachers profile
    `max_teacher_availability_score` DECIMAL(7,2) UNSIGNED DEFAULT 1,  -- Percentage of available teachers for this Class Group (Will capture from Teachers profile)
    `performance_rating` TINYINT UNSIGNED DEFAULT NULL,                -- Manual Entry rating out of (1 to 10)
    `last_performance_review` DATE DEFAULT NULL,                       -- Manual Entry
    `security_clearance_done` TINYINT(1) DEFAULT 0,                    -- Manual Entry
    `reporting_to` INT UNSIGNED DEFAULT NULL,                          -- Manual Entry
    `can_access_sensitive_data` TINYINT(1) DEFAULT 0,                  -- Manual Entry
    `notes` TEXT NULL,                                                 -- Manual Entry
    `effective_from` DATE DEFAULT NULL,                                -- Manual Entry. (Joining date)
    `effective_to` DATE DEFAULT NULL,                                  -- Manual Entry. (Leaving Date)
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_teacher_employee` (`employee_id`),
    CONSTRAINT `fk_teacher_employee` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`),
    CONSTRAINT `fk_teacher_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`),
    CONSTRAINT `fk_teacher_role` FOREIGN KEY (`role_id`) REFERENCES `sch_employee_roles` (`id`),
    CONSTRAINT `fk_teacher_department` FOREIGN KEY (`department_id`) REFERENCES `sch_departments` (`id`),
    CONSTRAINT `fk_teacher_designation` FOREIGN KEY (`designation_id`) REFERENCES `sch_designations` (`id`),
    CONSTRAINT `fk_teacher_reporting_to` FOREIGN KEY (`reporting_to`) REFERENCES `sch_employees` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
    -- teacher_availability_ratio = (Total weekly available Periods / (Total Number of Subjects he can teach in a week) * 100
    -- Example: If a teacher can teach 3 Subject for class-4, 3 Subject for Class-5 & 2 Subject for Class-6 in a week and has 36 available periods in a week, 
    -- then his teacher_availability_ratio is (8 / 36) * 100 = 22.22%  
    -- TAR = (Total weekly assigned Periods / Total weekly available Periods) * 100
    -- There will be only One record per Teacher in this table, so employee_id will be unique.
    -- max_available_periods_weekly and min_available_periods_weekly will be manually entered based on the contract and availability of the teacher. This will help in scheduling and ensuring that we do not over-allocate or under-allocate teachers.
    -- max_allocated_periods_weekly and min_allocated_periods_weekly will be auto-calculated based on the number of periods assigned to the teacher in the timetable. This will help in monitoring the workload of

  CREATE TABLE IF NOT EXISTS `sch_teacher_capabilities` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- CORE RELATIONSHIP
    `teacher_profile_id` INT UNSIGNED NOT NULL,             -- FK sch_teacher_profile.id
    `class_id` INT UNSIGNED NOT NULL,                       -- FK sch_classes.id
    -- `section_id` INT UNSIGNED DEFAULT NULL,              -- FK sch_sections.id (NULL = all sections)
    `subject_study_format_id` INT UNSIGNED NOT NULL,        -- FK sch_subject_study_format_jnt.id
    -- TEACHING STRENGTH
    `proficiency_percentage` TINYINT UNSIGNED DEFAULT NULL, -- 1–100
    `teaching_experience_months` SMALLINT UNSIGNED DEFAULT NULL,
    `is_primary_subject` TINYINT(1) NOT NULL DEFAULT 1,     -- 1=Yes, 0=No
    `competancy_level` ENUM('Facilitator','Basic','Intermediate','Advanced','Expert') DEFAULT 'Basic',  -- Facilitator - If No Teaching Experience but can manage.
    -- PRIORITY MATRIX INTELLIGENCE
    `priority_order` INT UNSIGNED DEFAULT NULL,              -- Priority Order of the Teacher for the Class+Subject+Study_Format
    `priority_weight` TINYINT UNSIGNED DEFAULT NULL,         -- manual / computed weight (1–10) (Even if teachers are available, how important is THIS activity to the school?)
    `scarcity_index` TINYINT UNSIGNED DEFAULT NULL,          -- 1=abundant, 10=very rare
    `is_hard_constraint` TINYINT(1) DEFAULT 0,               -- if true cannot be voilated e.g. Physics Lab teacher for Class 12
    `allocation_strictness` ENUM('hard','medium','soft') DEFAULT 'medium', -- e.g. Senior Maths teacher - Hard, Preferred English teacher - Medium, Art / Sports / Activity - Soft
    -- GOVERNANCE & OVERRIDE
    `override_priority` TINYINT UNSIGNED DEFAULT NULL,       -- admin override
    `override_reason` VARCHAR(255) DEFAULT NULL,
    -- AI / HISTORICAL FEEDBACK
    `historical_success_ratio` TINYINT UNSIGNED DEFAULT NULL, -- 1–100 (sessions_completed_without_change / total_sessions_allocated ) * 100)
    `last_allocation_score` TINYINT UNSIGNED DEFAULT NULL,    -- last run score
    -- EFFECTIVITY & STATUS
    `effective_from` DATE DEFAULT NULL,
    -- `effective_to` DATE DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `active_flag` tinyint(1) GENERATED ALWAYS AS ((case when (`is_active` = 1) then '1' else NULL end)) STORED,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY `uq_teacher_capability` (`teacher_profile_id`, `class_id`, `subject_study_format_id`, `active_flag`),
    CONSTRAINT `fk_tc_teacher_profile` FOREIGN KEY (`teacher_profile_id`) REFERENCES `sch_teacher_profile`(id) ON DELETE CASCADE,
    CONSTRAINT `fk_tc_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(id),
    CONSTRAINT `fk_tc_subject_study_format` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt`(id)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
      -- Formula: historical_success_ratio = (sessions_completed_without_change / total_sessions_allocated ) * 100)
      -- last_allocation_score = (proficiency_percentage * 0.4) + (load_balance * 0.3) + (strictness_match * 0.2) + (historical_success_ratio * 0.1)
      -- Importance - “Teacher selected because last allocation score = 87 (highest)”
      -- Facilitator  - I can manage the classroom, follow a lesson plan, and support student activity in an emergency.
      -- Basic        - I have a foundational understanding of the subject and can teach introductory concepts.
      -- Intermediate - I am comfortable teaching the core curriculum and answering most student questions.
      -- Advanced     - I have deep subject knowledge and can prepare students for high-level exams or projects.
      -- Expert       - I am a subject specialist capable of curriculum development and mentoring other teachers.

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
    `is_current` TINYINT(1) NOT NULL DEFAULT 0,                -- Only one active record per student
    `current_flag` INT GENERATED ALWAYS AS ((case when (`is_current` = 1) then `student_id` else NULL end)) STORED,
    `session_status_id` INT UNSIGNED NOT NULL,    -- FK to sys_dropdown_table (PROMOTED, ACTIVE, LEFT, SUSPENDED, ALUMNI, WITHDRAWN)
    `count_for_timetable` TINYINT(1) NOT NULL DEFAULT 1,      -- Can we count this record for Timetable
    `leaving_date` DATE DEFAULT NULL,
    `count_as_attrition` TINYINT(1) NOT NULL DEFAULT 0,         -- Can we count this record as Attrition
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

-- =========================================================================
-- 9-SYLLABUS MODULE (slb)
-- =========================================================================
  CREATE TABLE IF NOT EXISTS `slb_topic_level_types` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `level` TINYINT UNSIGNED NOT NULL,              -- e.g., 0=Topic, 1=Sub-topic, 2=Mini Topic, 3=Sub-Mini Topic, 4=Micro Topic, 5=Sub-Micro Topic, 6=Nano Topic, 7=Sub-Nano Topic, 8=Ultra Topic, 9=Sub-Ultra Topic
    `code` VARCHAR(3) NOT NULL,                    -- e.g., (TOP, SBT, MIN, SMN, MIC, SMC, NAN, SNN, ULT, SUT)
    `name` VARCHAR(150) NOT NULL,                   -- e.g., (TOPIC, SUB-TOPIC, MINI TOPIC, SUB-MINI TOPIC, MICRO TOPIC, SUB-MICRO TOPIC, NANO TOPIC, SUB-NANO TOPIC, ULTRA TOPIC, SUB-ULTRA TOPIC)
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `can_be_used_for_homework_release` TINYINT(1) NOT NULL DEFAULT 1,
    `can_be_used_for_quiz_release` TINYINT(1) NOT NULL DEFAULT 1,
    `can_be_used_for_quest_release` TINYINT(1) NOT NULL DEFAULT 1,
    `can_be_used_for_exam_release` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_topic_type_level` (`level`),
    UNIQUE KEY `uq_topic_type_code` (`code`),
    UNIQUE KEY `uq_topic_type_name` (`name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 0=Topic, 
  -- 1=Sub-topic, 
  -- 2=Mini Topic, 3=Sub-Mini Topic, 
  -- 3=Micro Topic, 5=Sub-Micro Topic, 
  -- 4=Nano Topic, 7=Sub-Nano Topic, 
  -- 5=Ultra Topic, 9=Sub-Ultra Topic

  CREATE TABLE IF NOT EXISTS `slb_lessons` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,                       -- Unique identifier for analytics tracking
    `academic_session_id` INT UNSIGNED NOT NULL, -- FK to sch_org_academic_sessions_jnt
    `class_id` INT UNSIGNED NOT NULL,               -- FK to sch_classes
    `subject_id` INT UNSIGNED NOT NULL,          -- FK to sch_subjects
    `bok_books_id` INT UNSIGNED NOT NULL,        -- FK to bok_books.id
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
    `level_id` INT UNSIGNED NOT NULL DEFAULT 0,     -- FK-slb_topic_level_types.id (0=Topic, 1=Sub-topic, 2=Mini Topic, 3=Sub-Mini Topic, 4=Micro Topic, 5=Sub-Micro Topic, 6=Nano Topic, 7=Ultra Topic)
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
    -- Analytics identifiers (With New Width analytics_code = "'09TH_SCINC_LES01_TOP01_SUB02_MIN01_SMT02_MIC01_SMT02_NAN01_ULT02'")
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
    CONSTRAINT `fk_topic_level` FOREIGN KEY (`level_id`) REFERENCES `slb_topic_level_types` (`id`) ON DELETE RESTRICT,
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


  -- -------------------------------------------------------------------------------------------------------------------------------------------------------------------

  -- -------------------------------------------------------------------------
  -- LESSON PLANNING
  -- This should be Part of Standard Timetable
  -- -------------------------------------------------------------------------
  -- This table is used for Lesson Planning (scheduling topics to classes and sections)
  CREATE TABLE IF NOT EXISTS `slb_syllabus_schedule` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_session_id` INT UNSIGNED NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,           -- FK to sch_classes.id. NULL = applies to all classes
    `section_id` INT UNSIGNED DEFAULT NULL,       -- FK to sch_sections.id. NULL = applies to all sections
    `subject_id` INT UNSIGNED NOT NULL,       -- FK to sch_subjects.id
    `lesson_id` INT UNSIGNED NOT NULL,        -- FK to slb_lessons.id
    `topic_id` INT UNSIGNED NOT NULL,         -- FK to slb_topics.id (It can be Topic, Sub-Topic, Mini-Topic, Micro-Topic etc.)
    `topic_level_type_id` INT UNSIGNED NOT NULL,  -- FK to slb_topic_level_types.id
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










  -- ===========================================================================================

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

  -- -------------------------------------------------------------------------------------------------------------
  --Correction :
  -- Table slb_lesson Added 1 New Fields (`bok_books_id` INT UNSIGNED NOT NULL, -- FK to bok_books.id)

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
    KEY `idx_ques_visibility` (`availability`),
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
    -- CONSTRAINT `fk_ques_reviewed_by` FOREIGN KEY (`ques_reviewed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_selected_entity_group` FOREIGN KEY (`selected_entity_group_id`) REFERENCES `slb_entity_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_selected_section` FOREIGN KEY (`selected_section_id`) REFERENCES `sch_sections` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ques_selected_student` FOREIGN KEY (`selected_student_id`) REFERENCES `std_students` (`id`) ON DELETE SET NULL,
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
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
      CONSTRAINT `fk_q_review_reviewer` FOREIGN KEY (`reviewer_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_q_review_status` FOREIGN KEY (`review_status_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Question Usage Type (Quiz / Quest / Exam)
  CREATE TABLE `qns_question_usage_type` (
      `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `code` VARCHAR(50) NOT NULL,  -- e.g. 'QUIZ','QUEST','ONLINE_EXAM','OFFLINE_EXAM'
      `name` VARCHAR(100) NOT NULL, -- e.g. 'Quiz','Quest','Online Exam','Offline Exam'
      `description` TEXT DEFAULT NULL,
      `is_active` TINYINT(1) DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP DEFAULT NULL,
      UNIQUE KEY `uq_q_usage_type_code` (`code`),
      UNIQUE KEY `uq_q_usage_type_name` (`name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  INSERT INTO qns_question_usage_type (code, name, description) VALUES
  ('QUIZ','Quiz', 'Quiz'),
  ('QUEST','Quest', 'Quest'),
  ('ONLINE_EXAM','Online Exam', 'Online Exam'),
  ('OFFLINE_EXAM','Offline Exam', 'Offline Exam');

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
    KEY `idx_recMat_type` (`material_type`),
    KEY `idx_recMat_scope` (`class_id`, `subject_id`, `topic_id`),
    CONSTRAINT `fk_recMat_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_recMat_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`),
    CONSTRAINT `fk_recMat_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`),
    CONSTRAINT `fk_recMat_content_source` FOREIGN KEY (`content_source`) REFERENCES `sys_dropdown_table` (`id`),
    CONSTRAINT `fk_recMat_material_type` FOREIGN KEY (`material_type`) REFERENCES `sys_dropdown_table` (`id`),
    CONSTRAINT `fk_recMat_purpose` FOREIGN KEY (`purpose`) REFERENCES `sys_dropdown_table` (`id`),
    CONSTRAINT `fk_recMat_complexity_level` FOREIGN KEY (`complexity_level`) REFERENCES `slb_complexity_level` (`id`),
    CONSTRAINT `fk_recMat_media` FOREIGN KEY (`media_id`) REFERENCES `qns_media_store` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
    PRIMARY KEY (`id`)
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

  -- 1. Recommendation Rules Engine
  --    Defines logics: WHEN (Trigger) + WHO (Performance) -> WHAT (Recommendation)
  CREATE TABLE IF NOT EXISTS `rec_recommendation_rules` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- Rule Definition
    `name` VARCHAR(150) NOT NULL,                   -- e.g. "Math Remedial for Poor Performers in Algebra"
    `is_automated` TINYINT(1) DEFAULT 1,            -- 1=Run by System Job, 0=Manual Helper Rule
    -- TRIGGERS (When to Apply)
    `trigger_event_id` INT UNSIGNED NOT NULL,  -- FK to rec_trigger_events
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
    `assessment_type_id` INT UNSIGNED DEFAULT NULL,  -- FK to rec_assessment_types
    -- ACTION (What to Recommend)
    `recommendation_mode_id` INT UNSIGNED NOT NULL,  -- FK to rec_recommendation_modes
    `target_material_id` INT UNSIGNED DEFAULT NULL,  -- FK TO rec_recommendation_materials
    `target_bundle_id` INT UNSIGNED DEFAULT NULL,    -- FK TO rec_material_bundles
    `dynamic_material_type_id` INT UNSIGNED DEFAULT NULL,  -- FK to rec_dynamic_material_types
    `dynamic_purpose_id` INT UNSIGNED DEFAULT NULL,  -- FK to rec_dynamic_purposes
    `priority` INT UNSIGNED DEFAULT 10,                 -- Higher priority rules override or appear first
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_recRule_trigger` (`trigger_event_id`),
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
-- 12-Syllabus_Books (slb)
-- ===========================================================================
  -- Authors table (Many-to-Many with Books)
  CREATE TABLE IF NOT EXISTS `slb_book_authors` (
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

  -- ---------------------------------------------------------------------
  -- Menu Option : Syllabus Books
  -- Tab : 1. Books (Section-1.1)
  -- ---------------------------------------------------------------------

  -- Master table for Books/Publications used across schools
  CREATE TABLE IF NOT EXISTS `slb_books` (
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
    CONSTRAINT `fk_book_cover_image_media_id` FOREIGN KEY (`cover_image_media_id`) REFERENCES `qns_media_store` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ---------------------------------------------------------------------
  -- Menu Option : Syllabus Books
  -- Tab : 1. Books (Section-1.2)
  -- ---------------------------------------------------------------------
  -- Junction: Book-Author relationship
  CREATE TABLE IF NOT EXISTS `slb_book_author_jnt` (
    `book_id` INT UNSIGNED NOT NULL,
    `author_id` INT UNSIGNED NOT NULL,
    `author_role` ENUM('PRIMARY','CO_AUTHOR','EDITOR','CONTRIBUTOR') DEFAULT 'PRIMARY',
    `ordinal` TINYINT UNSIGNED DEFAULT 1,
    PRIMARY KEY (`book_id`, `author_id`),
    CONSTRAINT `fk_ba_book` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`),
    CONSTRAINT `fk_ba_author` FOREIGN KEY (`author_id`) REFERENCES `slb_book_authors` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ---------------------------------------------------------------------
  -- Menu Option : Syllabus Books
  -- Tab : 1. Books (Section-1.3)
  -- ---------------------------------------------------------------------
  -- Link Books to Class/Subject (which books are used for which class/subject)
  CREATE TABLE IF NOT EXISTS `slb_book_class_subject_jnt` (
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
    CONSTRAINT `fk_bcs_book` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`),
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
    `user_id` INT UNSIGNED DEFAULT NULL,             -- Nullable. Set when Parent Portal access is created.
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
    `is_current` TINYINT(1) NOT NULL DEFAULT 0,                -- Only one active record per student
    `current_flag` INT GENERATED ALWAYS AS ((case when (`is_current` = 1) then `student_id` else NULL end)) STORED,
    `session_status_id` INT UNSIGNED NOT NULL,    -- FK to sys_dropdown_table (PROMOTED, ACTIVE, LEFT, SUSPENDED, ALUMNI, WITHDRAWN)
    `count_for_timetable` TINYINT(1) NOT NULL DEFAULT 1,      -- Can we count this record for Timetable
    `leaving_date` DATE DEFAULT NULL,
    `count_as_attrition` TINYINT(1) NOT NULL DEFAULT 0,         -- Can we count this record as Attrition
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

 -- ===========================================================================
 -- 14.1-HPC Templates (hpc)
 -- ===========================================================================
  CREATE TABLE IF NOT EXISTS `hpc_templates` (
    `id`          INT AUTO_INCREMENT PRIMARY KEY,
    `code`        VARCHAR(50) NOT NULL,
    `version`     TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `title`       VARCHAR(255) NOT NULL,
    `description` VARCHAR(512) NULL,
    `applicable_to_grade` JSON NULL,     -- (BV1,BV2,BV3) or (Nur,LKG,UKG) and (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
    `is_active`   TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `ux_templates_code_version` (`code`,`version`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `hpc_template_parts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `template_id` INT UNSIGNED NOT NULL,  -- FK to hpc_templates
    `code` VARCHAR(50) NOT NULL,
    `description` VARCHAR(512) NULL,
    `help_file` VARCHAR(255) NULL,  -- Can be a url of the how to fill for that page only
    `display_order` TINYINT UNSIGNED DEFAULT 1,
    `page_no` TINYINT UNSIGNED NOT NULL DEFAULT 1, -- new
    `display_page_number` TINYINT(1) DEFAULT 1,
    `has_items` TINYINT(1) DEFAULT 1,  -- New
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `ux_parts_template_code` (`template_id`,`code`),
    UNIQUE KEY `ux_parts_template_page` (`template_id`,`page_no`),
    KEY `idx_parts_pageNo` (`page_no`),
    CONSTRAINT `fk_templateParts_templateId` FOREIGN KEY (`template_id`) REFERENCES `hpc_templates`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- 1. If has_items = 1 then only hpc_template_parts_items table will be used
  -- 2. If has_items = 0 then only hpc_template_parts table will be used
  -- 3. When has_items=0, part acts as container for sections only

  CREATE TABLE IF NOT EXISTS `hpc_template_parts_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `part_id` INT UNSIGNED NOT NULL,        -- FK to hpc_template_parts
    `ordinal` TINYINT UNSIGNED DEFAULT 1,
    `html_object_name` VARCHAR(50) NOT NULL,  -- Name of the object in HTML.
    `level_display` VARCHAR(150) NOT NULL,  -- What will be the Level on the Screen
    `level_print` VARCHAR(150) NOT NULL,    -- What will be the Level on the Print
    `visible` TINYINT(1) DEFAULT 1,
    `print` TINYINT(1) DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `ux_templatePartsItems_partId_ordinal` (`part_id`,`ordinal`),
    CONSTRAINT `fk_templatePartsItems_partId` FOREIGN KEY (`part_id`) REFERENCES `hpc_template_parts`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `hpc_template_sections` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `template_id` INT UNSIGNED NOT NULL,      -- FK to hpc_templates
    `part_id` INT UNSIGNED NOT NULL,      -- FK to hpc_template_parts
    `code` VARCHAR(50) NOT NULL,
    `description` VARCHAR(512) NULL,
    `display_order` TINYINT UNSIGNED DEFAULT 1,
    `has_items` TINYINT(1) DEFAULT 1,  -- New
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `ux_sections_part_code` (`part_id`,`code`),
    UNIQUE KEY `ux_sections_part_order` (`part_id`,`display_order`),
    KEY `idx_sections_order` (`display_order`),
    CONSTRAINT `fk_templateSections_partId` FOREIGN KEY (`part_id`) REFERENCES `hpc_template_parts`(`id`),
    CONSTRAINT `fk_templateSections_templateId` FOREIGN KEY (`template_id`) REFERENCES `hpc_templates`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- 1. If has_items = 1 then only hpc_template_sections_items table will be used
  -- 2. If has_items = 0 then only hpc_template_sections table will be used
  -- 3. sections can have both items AND rubrics simultaneously


  CREATE TABLE IF NOT EXISTS `hpc_template_section_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `section_id` INT UNSIGNED NOT NULL,     -- FK to hpc_template_sections
    `html_object_name` VARCHAR(50) NOT NULL,  -- Name of the object in HTML.
    `ordinal` TINYINT UNSIGNED DEFAULT 1,
    `level_display` VARCHAR(150) NOT NULL,
    `level_print` VARCHAR(150) NOT NULL,
    `section_type` ENUM('Text','Image','Table') DEFAULT 'Text',
    `visible` TINYINT(1) DEFAULT 1,
    `print` TINYINT(1) DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `ux_templateSectionItems_sectionId_ordinal` (`section_id`,`ordinal`),
    CONSTRAINT `fk_templateSectionItems_sectionId` FOREIGN KEY (`section_id`) REFERENCES `hpc_template_sections`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- 1. If section_type = 'Table' then only `hpc_template_section_table` table will be used
  -- 2. If section_type = 'Text' or section_type = 'Image' then only `hpc_template_section_items` table will be used

  CREATE TABLE IF NOT EXISTS `hpc_template_section_table` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `section_id` INT UNSIGNED NOT NULL,
    `section_item_id` INT UNSIGNED NOT NULL,
    `html_object_name` VARCHAR(50) NOT NULL,  -- Name of the object in HTML.
    `row_id` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `column_id` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `value` VARCHAR(255) NOT NULL,
    `visible` TINYINT(1) DEFAULT 1,
    `print` TINYINT(1) DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `ux_sectionTable_section_row_column` (`section_id`,`row_id`,`column_id`),
    CONSTRAINT `fk_sectionTable_sectionId` FOREIGN KEY (`section_id`) REFERENCES `hpc_template_sections`(`id`),
    CONSTRAINT `fk_sectionTable_sectionItemId` FOREIGN KEY (`section_item_id`) REFERENCES `hpc_template_section_items`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `hpc_template_rubrics` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `template_id` INT UNSIGNED NOT NULL,  -- FK to hpc_templates
    `part_id` INT UNSIGNED NOT NULL,  -- FK to hpc_template_parts
    `section_id` INT UNSIGNED NULL,  -- FK to hpc_template_sections
    `display_order` SMALLINT UNSIGNED DEFAULT 0,
    `code` VARCHAR(50) NULL,
    `description` VARCHAR(512) NULL,
    `mandatory` TINYINT(1) DEFAULT 0,
    `visible` TINYINT(1) DEFAULT 1,
    `print` TINYINT(1) DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `ux_templateRubrics_section_order` (`section_id`,`display_order`),
    KEY `idx_rubrics_template` (`template_id`, `part_id`, `section_id`, `display_order`),
    CONSTRAINT `fk_templateRubrics_templateId` FOREIGN KEY (`template_id`) REFERENCES `hpc_templates`(`id`),
    CONSTRAINT `fk_templateRubrics_partId` FOREIGN KEY (`part_id`) REFERENCES `hpc_template_parts`(`id`),
    CONSTRAINT `fk_templateRubrics_sectionId` FOREIGN KEY (`section_id`) REFERENCES `hpc_template_sections`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
  -- If has_items = 1 then only hpc_template_rubric_items table will be used
  -- If has_items = 0 then only hpc_template_rubric_items table will be used

  CREATE TABLE IF NOT EXISTS `hpc_template_rubric_items` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `rubric_id` INT UNSIGNED NOT NULL,
    `html_object_name` VARCHAR(50) NOT NULL,
    `ordinal` TINYINT UNSIGNED DEFAULT 1,
    `input_required` TINYINT(1) DEFAULT 1,
    `input_type` ENUM('Descriptor','Numeric','Grade','Text','Boolean','Image','Json') DEFAULT 'Descriptor',
    `output_type` ENUM('Descriptor','Numeric','Grade','Text','Boolean','Image','Json') DEFAULT 'Descriptor',
    `input_level` VARCHAR(255) NOT NULL,                      -- Input level (e.g., Excellent, Good, Developing, Needs Support)
    `output_level` VARCHAR(255) NOT NULL,                     -- Output level (e.g., Excellent, Good, Developing, Needs Support)
    `input_level_numeric` INT UNSIGNED NULL,                  -- Input level numeric (e.g., 4 = Excellent, 3 = Good, 2 = Developing, 1 = Needs Support)
    `output_level_numeric` INT UNSIGNED NULL,                 -- Output level numeric (e.g., 4 = Excellent, 3 = Good, 2 = Developing, 1 = Needs Support)
    `display_input_label` TINYINT(1) NOT NULL DEFAULT 0,      -- Default we will display input_level but if this is 1 then we will display input_level_value
    `print_output_label` TINYINT(1) NOT NULL DEFAULT 0,       -- Default we will display input_level but if this is 1 then we will display input_level_value
    `weight` DECIMAL(8,3) NULL,                               -- Useful to add weightage. For example, we may map Outstanding to weight 4.5
    `description` VARCHAR(255) NULL,                          -- Description of the rubric item
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `ux_levels_rubric_value` (`rubric_id`, `input_level`), 
    KEY `idx_levels_rubric` (`rubric_id`),
    CONSTRAINT `fk_rubricLevels_rubricId` FOREIGN KEY (`rubric_id`) REFERENCES `hpc_template_rubrics`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  -- -----------------------------------------------------------------------------------------------



  CREATE TABLE IF NOT EXISTS `hpc_reports` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,  -- Auto Generate
    `academic_session_id` INT UNSIGNED  NOT NULL,  -- Fk to std_student_academic_sessions.id
    `term_id` INT UNSIGNED NOT NULL,               -- Fk to sch_academic_term.id
    `student_id` INT UNSIGNED NOT NULL,            -- Fk to std_students.id
    `class_id` INT UNSIGNED NOT NULL,              -- Fk to sch_classes.id
    `section_id` INT UNSIGNED NOT NULL,            -- Fk to sch_sections.id
    `template_id` INT UNSIGNED NOT NULL,           -- Fk to hpc_templates.id
    `prepared_by` INT UNSIGNED NULL,               -- Fk to staff.id
    `report_date` DATE NOT NULL,                   -- Report Generation Date
    `status` ENUM('Draft','Final','Published','Archived') DEFAULT 'Draft',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `ux_reports_student_session_term` (`academic_session_id`,`term_id`,`student_id`),
    CONSTRAINT `fk_reports_session` FOREIGN KEY (`academic_session_id`) REFERENCES `std_student_academic_sessions`(`id`),
    CONSTRAINT `fk_reports_term` FOREIGN KEY (`term_id`) REFERENCES `cbse_terms`(`id`),
    CONSTRAINT `fk_reports_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`),
    CONSTRAINT `fk_reports_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`id`),
    CONSTRAINT `fk_reports_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections`(`id`),
    CONSTRAINT `fk_reports_template` FOREIGN KEY (`template_id`) REFERENCES `hpc_templates`(`id`),
    CONSTRAINT `fk_reports_preparedBy` FOREIGN KEY (`prepared_by`) REFERENCES `sys_users`(`id`),
    KEY `idx_reports_template` (`template_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `hpc_report_items` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `report_id` INT UNSIGNED NOT NULL,        -- FK to hpc_reports.id
    `template_id` INT UNSIGNED NOT NULL,      -- Fk to hpc_templates.id
    `rubric_id` INT UNSIGNED NOT NULL,        -- FK to hpc_template_rubrics.id
    `rubric_item_id` INT UNSIGNED NULL,       -- FK to hpc_template_rubric_items.id
    -- Input
    `in_numeric_value` DECIMAL(10,3) NULL,    -- to capture numeric type value (Will Cover Numeric)
    `in_text_value` VARCHAR(512) NULL,        -- to capture text type (Will Cover Text, KeyValue)
    `in_boolean_value` TINYINT(1) NULL,       -- to capture boolean type (Will Cover Boolean)
    `in_selected_value` VARCHAR(100) NULL,    -- to capture categorical Value (descriptor & grade)
    `in_image_path` VARCHAR(255) NULL,        -- to capture image path (Will Cover Image)
    `in_filename` VARCHAR(100) NULL,          -- to capture file name (Will Cover File)
    `in_filepath` VARCHAR(255) NULL,          -- to capture file path (Will Cover File)
    `in_json_value` JSON NULL,                -- to capture table data (Will Cover Table)
    -- Output
    `out_numeric_value` DECIMAL(10,3) NULL,     -- to capture numeric type value (Will Cover Numeric)
    `out_text_value` VARCHAR(512) NULL,         -- to capture text type (Will Cover Text, KeyValue, Descriptor, Grade)
    `out_boolean_value` TINYINT(1) NULL,        -- to capture boolean type (Will Cover Boolean)
    `out_selected_value` VARCHAR(100) NULL,     -- to capture categorical Value (descriptor & grade)
    `out_image_path` VARCHAR(255) NULL,         -- to capture image path (Will Cover Image)
    `out_filename` VARCHAR(100) NULL,           -- to capture file name (Will Cover File)
    `out_filepath` VARCHAR(255) NULL,           -- to capture file path (Will Cover File)
    `out_json_value` JSON NULL,                 -- to capture table data (Will Cover Table)
    -- Assessment
    `remark` TEXT NULL,                         -- to capture remark (Will Cover Remark)
    `assessed_by` INT UNSIGNED NULL,            -- Fk to sys_users.id
    `assessed_at` TIMESTAMP NULL,               -- Assessment Date
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_reportItems_reportId` FOREIGN KEY (`report_id`) REFERENCES `hpc_reports`(`id`),
    CONSTRAINT `fk_reportItems_templateId` FOREIGN KEY (`template_id`) REFERENCES `hpc_templates`(`id`),
    CONSTRAINT `fk_reportItems_rubricId` FOREIGN KEY (`rubric_id`) REFERENCES `hpc_template_rubrics`(`id`),
    CONSTRAINT `fk_reportItems_rubricItemId` FOREIGN KEY (`rubric_item_id`) REFERENCES `hpc_template_rubric_items`(`id`),
    KEY `idx_reportItems_reportId_rubricId_rubricItemId` (`report_id`,`rubric_id`,`rubric_item_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `hpc_report_table` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `report_id` INT UNSIGNED NOT NULL,
    `section_id` INT UNSIGNED NOT NULL,
    `row_id` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `column_id` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `value` VARCHAR(255) NOT NULL,
    `visible` TINYINT(1) DEFAULT 1,
    `print` TINYINT(1) DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `ux_reportTable_report_section_row_column` (`report_id`,`section_id`,`row_id`,`column_id`),
    CONSTRAINT `fk_reportTable_reportId` FOREIGN KEY (`report_id`) REFERENCES `hpc_reports`(`id`),
    CONSTRAINT `fk_reportTable_sectionId` FOREIGN KEY (`section_id`) REFERENCES `hpc_template_sections`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  -- Verification Queries

  -- Verify template structure
  SELECT 
      t.code AS template_code,
      t.title AS template_title,
      COUNT(DISTINCT p.id) AS part_count,
      COUNT(DISTINCT s.id) AS section_count,
      COUNT(DISTINCT r.id) AS rubric_count,
      COUNT(DISTINCT ri.id) AS rubric_item_count
  FROM hpc_templates t
  LEFT JOIN hpc_template_parts p ON p.template_id = t.id
  LEFT JOIN hpc_template_sections s ON s.template_id = t.id
  LEFT JOIN hpc_template_rubrics r ON r.template_id = t.id
  LEFT JOIN hpc_template_rubric_items ri ON ri.rubric_id = r.id
  WHERE t.code = 'HPC-FOUND'
  GROUP BY t.id;

  -- List all parts with their sections
  SELECT 
      p.code AS part_code,
      p.page_no,
      s.code AS section_code,
      s.display_order,
      si.level_display AS item_display
  FROM hpc_template_parts p
  LEFT JOIN hpc_template_sections s ON s.part_id = p.id
  LEFT JOIN hpc_template_section_items si ON si.section_id = s.id
  WHERE p.template_id = 1
  ORDER BY p.display_order, s.display_order, si.ordinal;

 -- ===========================================================================
 -- 14.2-HPC Data Collection (hpc)
 -- ===========================================================================


  -- This table will store the circular goals
  CREATE TABLE IF NOT EXISTS `hpc_circular_goals` (
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

  -- This table will store the mapping between circular goals and competencies
  CREATE TABLE IF NOT EXISTS `hpc_circular_goal_competency_jnt` (
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
  -- This Table will cover the learning outcomes for HPC
  CREATE TABLE IF NOT EXISTS `hpc_learning_outcomes` (
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

  -- This Table will cover the outcome entity mapping for HPC
  CREATE TABLE IF NOT EXISTS `hpc_outcome_entity_jnt` (
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
    CONSTRAINT `fk_outcome_entity_outcome` FOREIGN KEY (`outcome_id`) REFERENCES `slb_learning_outcomes`(`id`),
    CONSTRAINT `fk_outcome_entity_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`id`),
    CONSTRAINT `fk_outcome_entity_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects`(`id`),
    CONSTRAINT `fk_outcome_entity_entity_type` FOREIGN KEY (`entity_type`) REFERENCES `sys_dropdown_table`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Screen - 3 (QUESTION MAPPING)
  -- =========================================================
  -- OUTCOME ↔ QUESTION MAPPING (will be used for HPC)
  -- =========================================================
  -- This Table will cover the outcome question mapping for HPC
  CREATE TABLE IF NOT EXISTS `hpc_outcome_question_jnt` (
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
  -- This Table will cover the knowledge graph validation for HPC
  CREATE TABLE IF NOT EXISTS `hpc_knowledge_graph_validation` (
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
  -- This table will cover the topic equivalency between different syllabuses
  CREATE TABLE IF NOT EXISTS `hpc_topic_equivalency` (
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
  -- This table will cover the syllabus coverage snapshot (How much Syllabus has been covered) for HPC
  CREATE TABLE IF NOT EXISTS `hpc_syllabus_coverage_snapshot` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `academic_session_id` INT UNSIGNED NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,
    `subject_id` INT UNSIGNED NOT NULL,
    `coverage_percentage` DECIMAL(5,2) NOT NULL,
    `snapshot_date` DATE NOT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP DEFAULT NULL,
    CONSTRAINT `fk_syllabus_coverage_academic_session` FOREIGN KEY (`academic_session_id`) REFERENCES `slb_academic_sessions`(`id`),
    CONSTRAINT `fk_syllabus_coverage_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`id`),
    CONSTRAINT `fk_syllabus_coverage_subject` FOREIGN KEY (`subject_id`) REFERENCES `slb_subjects`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Screen - 7 (HPC Parameters)
  -- =========================================================
  -- HPC PARAMETERS
  -- =========================================================
  -- This table will cover the HPC parameters for HPC. In NEP Framework it has been mentioned as 3 "Ability"
  -- As per the HPC framework, Every Subject will be assessed based on these 3 parameters (Awareness, Sensitivity, Creativity)
  -- Old Table Name - hpc_hpc_parameters
  CREATE TABLE IF NOT EXISTS `hpc_ability_parameters` (
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
  -- This table will cover the HPC performance levels for HPC. In NEP Framework it has been mentioned as 3 "Performance Descriptors" 
  -- As per the HPC framework, Every parameter for every subject will be assessed based on these 3 levels (Beginner, Proficient, Advanced)
  -- Old Table Name - hpc_hpc_levels
  CREATE TABLE IF NOT EXISTS `hpc_performance_descriptors` (
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
  -- This table will cover the HPC evaluation for Every Student on every subject based on 3 Parameters (Awareness, Sensitivity, Creativity)
  -- Every parameter(Awareness, Sensitivity, Creativity) for every subject will be assessed on 3 levels (Beginner, Proficient, Advanced)
  -- Old table name - hpc_student_hpc_evaluation
  CREATE TABLE IF NOT EXISTS `hpc_student_evaluation` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `academic_session_id` INT UNSIGNED NOT NULL,  -- FK TO slb_academic_sessions
    `student_id` INT UNSIGNED NOT NULL,           -- FK TO slb_students
    `subject_id` INT UNSIGNED NOT NULL,           -- FK TO slb_subjects
    `competency_id` INT UNSIGNED NOT NULL,        -- FK TO slb_competencies
    `hpc_ability_parameter_id` INT UNSIGNED NOT NULL,        -- FK TO hpc_ability_parameters
    `hpc_performance_descriptor_id` INT UNSIGNED NOT NULL,            -- FK TO hpc_performance_descriptors
    `evidence_type` INT UNSIGNED NOT NULL,        -- FK TO sys_dropdown_table e.g. ('ACTIVITY','ASSESSMENT','OBSERVATION')
    `evidence_id` INT UNSIGNED,                   -- FK TO slb_activities
    `remarks` VARCHAR(500),
    `assessed_by` INT UNSIGNED,                   -- FK TO slb_users
    `assessed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP DEFAULT NULL,
    UNIQUE KEY `uq_hpc_eval` (`academic_session_id`, `student_id`, `subject_id`, `competency_id`, `hpc_ability_parameter_id`),
    CONSTRAINT `fk_hpc_eval_academic_session` FOREIGN KEY (`academic_session_id`) REFERENCES `slb_academic_sessions`(`id`),
    CONSTRAINT `fk_hpc_eval_student` FOREIGN KEY (`student_id`) REFERENCES `slb_students`(`id`),
    CONSTRAINT `fk_hpc_eval_subject` FOREIGN KEY (`subject_id`) REFERENCES `slb_subjects`(`id`),
    CONSTRAINT `fk_hpc_eval_competency` FOREIGN KEY (`competency_id`) REFERENCES `slb_competencies`(`id`),
    CONSTRAINT `fk_hpc_eval_hpc_ability_parameter` FOREIGN KEY (`hpc_ability_parameter_id`) REFERENCES `hpc_ability_parameters`(`id`),
    CONSTRAINT `fk_hpc_eval_hpc_performance_descriptor` FOREIGN KEY (`hpc_performance_descriptor_id`) REFERENCES `hpc_performance_descriptors`(`id`),
    CONSTRAINT `fk_hpc_eval_evidence_type` FOREIGN KEY (`evidence_type`) REFERENCES `sys_dropdown_table`(`id`),
    CONSTRAINT `fk_hpc_eval_evidence_id` FOREIGN KEY (`evidence_id`) REFERENCES `slb_activities`(`id`),
    CONSTRAINT `fk_hpc_eval_assessed_by` FOREIGN KEY (`assessed_by`) REFERENCES `slb_users`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Screen - 10 (Learning Activities)
  -- =========================================================
  -- LEARNING ACTIVITIES (HPC EVIDENCE)
  -- =========================================================
  -- This table will cover the Learning Activities for every topic
  CREATE TABLE IF NOT EXISTS `hpc_learning_activities` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `topic_id` INT UNSIGNED NOT NULL,           -- FK TO slb_topics
    `activity_type_id` INT UNSIGNED NOT NULL,   -- FK TO hpc_learning_activity_type
    `description` TEXT NOT NULL,
    `expected_outcome` TEXT,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP DEFAULT NULL,
    CONSTRAINT `fk_activity_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics`(`id`),
    CONSTRAINT `fk_activity_type` FOREIGN KEY (`activity_type_id`) REFERENCES `hpc_learning_activity_type`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- I need to create a a new table for hpc_lerning_activity_type to use as activity_type_id in hpc_learning_activities.activity_type_id
  CREATE TABLE IF NOT EXISTS `hpc_learning_activity_type` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(30) NOT NULL,    -- PROJECT, OBSERVATION, FIELD_WORK, GROUP_WORK, ART, SPORT, DISCUSSION
    `name` VARCHAR(100) NOT NULL,   
    `description` VARCHAR(255) NOT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP DEFAULT NULL,
    UNIQUE KEY `uq_hpc_activity_type_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Do not ceate screen for this write Now. We will Cover it when we will develop Complete HPC Module
  -- =========================================================
  -- HOLISTIC PROGRESS CARD SNAPSHOT
  -- =========================================================
  -- This table will cover the Holistic Progress Card Snapshot for every student
  CREATE TABLE IF NOT EXISTS `hpc_student_hpc_snapshot` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `academic_session_id` INT UNSIGNED NOT NULL,  -- FK TO slb_academic_sessions
    `student_id` INT UNSIGNED NOT NULL,           -- FK TO slb_students
    `snapshot_json` JSON NOT NULL,
    `generated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP DEFAULT NULL,
    UNIQUE KEY `uq_hpc_snapshot` (`academic_session_id`, `student_id`),
    CONSTRAINT `fk_hpc_snapshot_academic_session` FOREIGN KEY (`academic_session_id`) REFERENCES `slb_academic_sessions`(`id`),
    CONSTRAINT `fk_hpc_snapshot_student` FOREIGN KEY (`student_id`) REFERENCES `slb_students`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- =====================================================================
  -- END OF NEP 2020 + HPC EXTENSION SCHEMA
  -- =====================================================================

-- ===========================================================================
-- 15-FRONTOFFICE MGMT. (fom)
-- ===========================================================================


-- ===========================================================================
-- 16-LMS (lms)
-- ===========================================================================

 -- ===========================================================================
 -- 16.1-LMS - HOMEWORK (lms)
 -- ===========================================================================

	CREATE TABLE IF NOT EXISTS `lms_homework` (
		`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
		`academic_session_id` INT UNSIGNED NOT NULL,       -- FK to sch_academic_sessions.id
		`class_id` INT UNSIGNED NOT NULL,                     -- FK to sch_classes.id
		`section_id` INT UNSIGNED DEFAULT NULL,               -- FK to sch_sections.id (Null = All Sections)
		`subject_id` INT UNSIGNED NOT NULL,                -- FK to sch_subjects.id
		-- Content Alignment
		`lesson_id` INT UNSIGNED DEFAULT NULL,             -- FK to sch_lessons.id (Null = All Lessons)
		`topic_id` INT UNSIGNED DEFAULT NULL,              -- FK to slb_topics.id (Null = All Topics) It can be anything like Topic/Sub-Topic/Mini-Topic/Micro-Topic etc.
		`title` VARCHAR(255) NOT NULL,
		`description` LONGTEXT NOT NULL,                      -- Supports HTML/Markdown
		`submission_type_id` INT UNSIGNED NOT NULL,        -- FK to sys_dropdown_table.id (TEXT, FILE, HYBRID, OFFLINE_CHECK)
		-- Settings
		`is_gradable` TINYINT(1) NOT NULL DEFAULT 1,          -- 1 = Gradable, 0 = Not Gradable
		`max_marks` DECIMAL(5,2) DEFAULT NULL,                -- Maximum Marks
		`passing_marks` DECIMAL(5,2) DEFAULT NULL,            -- Passing Marks
		`difficulty_level_id` INT UNSIGNED DEFAULT NULL,   -- FK to slb_complexity_level.id (EASY, MEDIUM, HARD)
		-- Scheduling
		`assign_date` DATETIME NOT NULL,
		`due_date` DATETIME NOT NULL,
		`allow_late_submission` TINYINT(1) DEFAULT 0,         -- 1 = Allow Late Submission, 0 = Not Allow Late Submission
		`auto_publish_score` TINYINT(1) DEFAULT 0,            -- 1 = Auto Publish Score, 0 = Not Auto Publish Score
		-- Auto-Release Logic
		`release_condition_id` INT UNSIGNED DEFAULT NULL,  -- FK to sys_dropdown.id (IMMEDIATE, ON_TOPIC_COMPLETE)    
		`status_id` INT UNSIGNED NOT NULL,                 -- FK to sys_dropdown.id (DRAFT, PUBLISHED, ARCHIVED)
		`is_active` TINYINT(1) DEFAULT 1,
		`created_by` INT UNSIGNED NOT NULL,
		`updated_by` INT UNSIGNED DEFAULT NULL,
		`created_at` TIMESTAMP NULL DEFAULT NULL,
		`updated_at` TIMESTAMP NULL DEFAULT NULL,
		`deleted_at` TIMESTAMP NULL DEFAULT NULL,    
		PRIMARY KEY (`id`),
		INDEX `idx_hw_class_sub` (`class_id`, `subject_id`),
		CONSTRAINT `fk_hw_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
		CONSTRAINT `fk_hw_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`),
		CONSTRAINT `fk_hw_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`),
		CONSTRAINT `fk_hw_submission_type` FOREIGN KEY (`submission_type_id`) REFERENCES `sys_dropdown_table` (`id`),
		CONSTRAINT `fk_hw_difficulty_level` FOREIGN KEY (`difficulty_level_id`) REFERENCES `slb_complexity_level` (`id`),
		CONSTRAINT `fk_hw_release_condition` FOREIGN KEY (`release_condition_id`) REFERENCES `sys_dropdown_table` (`id`),
		CONSTRAINT `fk_hw_status` FOREIGN KEY (`status_id`) REFERENCES `sys_dropdown_table` (`id`),
		CONSTRAINT `fk_hw_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`),
		CONSTRAINT `fk_hw_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- Condition:
	-- If `allow_late_submission` = 0, then Student can not submit Homework online after `due_date`. He need to submit directly to the Teacher. OR teacher can allow to submit after due_date.
	-- If `allow_late_submission` = 1, then Student can submit Homework online after `due_date` also

	-- 2.1 Homework Submissions
	CREATE TABLE IF NOT EXISTS `lms_homework_submissions` (
		`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
		`homework_id` INT UNSIGNED NOT NULL,
		`student_id` INT UNSIGNED NOT NULL,                -- FK to sys_users (Student)
		`submitted_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
		`submission_text` LONGTEXT DEFAULT NULL,              -- Student Submission Text
		`attachment_media_id` INT UNSIGNED DEFAULT NULL,   -- FK to sys_media (Handwritten scan)
		-- Evaluation
		`status_id` INT UNSIGNED NOT NULL,                 -- FK to sys_dropdown_table (SUBMITTED, CHECKED, REJECTED)    
		`marks_obtained` DECIMAL(5,2) DEFAULT NULL,          -- Obtained Marks
		`teacher_feedback` TEXT DEFAULT NULL,                 -- Teacher Feedback
		`graded_by` INT UNSIGNED DEFAULT NULL,             -- Graded By
		`graded_at` DATETIME DEFAULT NULL,                    -- Graded At
		`is_late` TINYINT(1) DEFAULT 0,                      -- Is Late
		-- Metadata
		`created_at` TIMESTAMP NULL DEFAULT NULL,
		`updated_at` TIMESTAMP NULL DEFAULT NULL,
		`deleted_at` TIMESTAMP NULL DEFAULT NULL,    
		PRIMARY KEY (`id`),
		UNIQUE KEY `uq_hw_sub` (`homework_id`, `student_id`),
		CONSTRAINT `fk_hws_hw` FOREIGN KEY (`homework_id`) REFERENCES `lms_homework` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

 -- ===========================================================================
 -- 16.2-LMS - QUIZ (lms)
 -- ===========================================================================
  CREATE TABLE IF NOT EXISTS `lms_difficulty_distribution_configs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(50) NOT NULL,              -- e.g. 'STD_QUIZ_EASY', STD_QUIZ_Medium, STD_QUIZ_Hard, 'EXAM_BALANCED'
    `name` VARCHAR(100) NOT NULL,             -- e.g. 'Standard Quiz Easy'
    `description` VARCHAR(255) DEFAULT NULL,
    `usage_type_id` INT UNSIGNED NOT NULL, -- FK to qns_question_usage_type (e.g. 'QUIZ','QUEST','ONLINE_EXAM','OFFLINE_EXAM')
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_diff_config_code` (`code`),
    CONSTRAINT `fk_diff_config_usage_type` FOREIGN KEY (`usage_type_id`) REFERENCES `qns_question_usage_type` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Difficulty Distribution Rules (Child Table of (lms_difficulty_distribution_configs)
  CREATE TABLE IF NOT EXISTS `lms_difficulty_distribution_details` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `difficulty_config_id` INT UNSIGNED NOT NULL,     -- FK to lms_difficulty_distribution_configs.id
    `question_type_id` INT UNSIGNED NOT NULL,         -- FK to slb_question_types.id (e.g. 'MCQ_SINGLE','MCQ_MULTI','SHORT_ANSWER','LONG_ANSWER')
    `complexity_level_id` INT UNSIGNED NOT NULL,      -- FK to slb_complexity_level.id (e.g. 'EASY','MEDIUM','DIFFICULT')
    `bloom_id` INT UNSIGNED NULL,       -- fk -> slb_bloom_taxonomy.id (Taxonomy)
    `cognitive_skill_id` INT UNSIGNED NULL, -- fk -> slb_cognitive_skill.id (Taxonomy)
    `ques_type_specificity_id` INT UNSIGNED NULL, -- fk -> slb_ques_type_specificity.id (Taxonomy)
    `min_percentage` DECIMAL(5,2) NOT NULL DEFAULT 0.00, -- Min % of total questions (e.g. 20.00)
    `max_percentage` DECIMAL(5,2) NOT NULL DEFAULT 0.00, -- Max % of total questions (e.g. 40.00)
    `marks_per_question` DECIMAL(5,2) DEFAULT NULL,     -- Optional override for marks (e.g. 1.00)
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_diff_det_config` FOREIGN KEY (`difficulty_config_id`) REFERENCES `lms_difficulty_distribution_configs` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_diff_det_qtype` FOREIGN KEY (`question_type_id`) REFERENCES `slb_question_types` (`id`),
    CONSTRAINT `fk_diff_det_comp` FOREIGN KEY (`complexity_level_id`) REFERENCES `slb_complexity_level` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------------------------------------------------------------
  -- Screen File name - LMS Master      Tab-2 (Name - Quiz Types)
  -- -------------------------------------------------------------------------------------------------------
  -- Quiz Type (Assessment Type)
  CREATE TABLE IF NOT EXISTS `lms_assessment_types` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(20) NOT NULL,              -- (e.g. 'Challenge', 'Enrichment', 'Practice', 'Revision', 'Re-Test', 'Diagnostic', 'Remedial')
    `name` VARCHAR(100) NOT NULL,             -- (e.g. 'Challenge', 'Enrichment', 'Practice', 'Revision', 'Re-Test', 'Diagnostic', 'Remedial')
    `assessment_usage_type_id` INT UNSIGNED NOT NULL, -- FK to qns_question_usage_type.id (e.g. 'QUIZ','QUEST','ONLINE_EXAM','OFFLINE_EXAM')
    `description` VARCHAR(255) DEFAULT NULL,  -- 
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_quiz_type_code` (`code`),
    CONSTRAINT `fk_quiz_type_usage_type` FOREIGN KEY (`assessment_usage_type_id`) REFERENCES `qns_question_usage_type` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



  -- =========================================================================
  -- 2. QUIZ MODULE
  -- =========================================================================

  -- -------------------------------------------------------------------------------------------------------
  -- Screen File name - Quiz Management      Tab-1 (Name - Quiz Creation)
  -- -------------------------------------------------------------------------------------------------------
  -- Main Quiz Master Table
  CREATE TABLE IF NOT EXISTS `lms_quizzes` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,                       -- Unique Identifier
    `academic_session_id` INT UNSIGNED NOT NULL,   -- FK to glb_academic_sessions.id
    `class_id` INT UNSIGNED NOT NULL,              -- FK to sch_classes.id
    `subject_id` INT UNSIGNED NOT NULL,            -- FK to sch_subjects.id
    `lesson_id` INT UNSIGNED NOT NULL,             -- FK to sch_lessons.id
    `scope_topic_id` INT UNSIGNED DEFAULT NULL,    -- FK to slb_topics.id (Primary Scope) (if selected topic is Sub-Topic then all the Mini-Topic/Micro-Topic comes under it will be included)
    `quiz_type_id` INT UNSIGNED NOT NULL,          -- FK to lms_assessment_types.id (e.g. 'Challenge', 'Enrichment', 'Practice', 'Revision', 'Re-Test', 'Diagnostic', 'Remedial')
    `quiz_code` VARCHAR(50) NOT NULL,                 -- AUTO GENERATED code (e.g. 'QUIZ_9TH_SCI_L01_SUB08_EASY', 'QUIZ_9TH_SCI_L01_BALANCED', 'QUIZ_9TH_SCI_L01_DIFFICULT')
    `title` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `instructions` TEXT DEFAULT NULL,                 -- Supports HTML/Markdown/JSON/Latex
    `status` VARCHAR(20) NOT NULL DEFAULT 'DRAFT',    -- DRAFT, PUBLISHED, ARCHIVED
    -- Settings
    `duration_minutes` TINYINT UNSIGNED DEFAULT NULL,     -- NULL = Unlimited
    `total_marks` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    `total_questions` INT UNSIGNED NOT NULL DEFAULT 0,
    `passing_percentage` DECIMAL(5,2) NOT NULL DEFAULT 33.00,
    `allow_multiple_attempts` TINYINT(1) NOT NULL DEFAULT 0,
    `max_attempts` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `negative_marks` DECIMAL(4,2) NOT NULL DEFAULT 0.00, -- e.g. 0.25  (If Negative Marking Factor is zero then no negative marks will be given)
    `is_randomized` TINYINT(1) NOT NULL DEFAULT 0,    -- Randomize Question Order
    `question_marks_shown` TINYINT(1) NOT NULL DEFAULT 0, -- Show Question Marks (If this will be 1 then Question Marks will be shown when attempt to the quiz)
    `show_result_immediately` TINYINT(1) NOT NULL DEFAULT 0,  -- Show Result Immediately (Student will get the result immediately after submitting the quiz)
    `auto_publish_result` TINYINT(1) NOT NULL DEFAULT 0,  -- Auto Publish Result (Result of the Class will be shown Automatically just after due date)
    `timer_enforced` TINYINT(1) NOT NULL DEFAULT 1,  -- Enforce Timer (If Timer is enforced then timer will be shown)
    `show_correct_answer` TINYINT(1) NOT NULL DEFAULT 0, -- Show Correct Answer (If this will be 1 then Correct Answer will be shown when attempt to the quiz)
    `show_explanation` TINYINT(1) NOT NULL DEFAULT 0, -- Show Explanation (If this will be 1 then Explanation will be shown when attempt to the quiz)
    -- Difficulty & Generation
    `difficulty_config_id` INT UNSIGNED DEFAULT NULL, -- FK to lms_difficulty_distribution_configs
    `ignore_difficulty_config` TINYINT(1) NOT NULL DEFAULT 0, -- Ignore Difficulty Config (If this will be 1 then difficulty_config_id will be ignored)
    `is_system_generated` TINYINT(1) NOT NULL DEFAULT 0, -- System Generated (If this will be 1 then quiz will be generated by system)
    `only_unused_questions` TINYINT(1) NOT NULL DEFAULT 0, -- Only Unused Questions (Question should not be in qns_question_usage_log)
    `only_authorised_questions` TINYINT(1) NOT NULL DEFAULT 0, -- If this will be 1 then use only questions where qns_questions_bank.for_quiz = 1
    -- Audit
    `created_by` INT UNSIGNED DEFAULT NULL,        -- FK to sys_users.id (Teacher/Admin), Null if created by System
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_quiz_uuid` (`uuid`),
    UNIQUE KEY `uq_quiz_code` (`quiz_code`),
    KEY `idx_quiz_topic` (`scope_topic_id`),
    KEY `idx_quiz_status` (`status`),
    CONSTRAINT `fk_quiz_academic_session` FOREIGN KEY (`academic_session_id`) REFERENCES `glb_academic_sessions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_quiz_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_quiz_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_quiz_type` FOREIGN KEY (`quiz_type_id`) REFERENCES `lms_assessment_types` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_quiz_diff_config` FOREIGN KEY (`difficulty_config_id`) REFERENCES `lms_difficulty_distribution_configs` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_quiz_topic` FOREIGN KEY (`scope_topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_quiz_creator` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Parameter in Setting ""
  -- -------------------------------------------------------------------------------------------------------
  -- Screen File name - Quiz Management      Tab-2 (Name - Add Questions to Quiz)
  -- -------------------------------------------------------------------------------------------------------
  -- Quiz Questions (Junction)
  CREATE TABLE IF NOT EXISTS `lms_quiz_questions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `quiz_id` INT UNSIGNED NOT NULL,               -- FK to lms_quizzes.id
    `question_id` INT UNSIGNED NOT NULL,           -- FK to qns_questions_bank.id
    `ordinal` INT UNSIGNED NOT NULL DEFAULT 0,        -- Sequence Order
    `marks_override` DECIMAL(5,2) DEFAULT NULL,       -- If different from question default marks
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_quiz_ques` (`quiz_id`, `question_id`),
    CONSTRAINT `fk_qq_quiz` FOREIGN KEY (`quiz_id`) REFERENCES `lms_quizzes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qq_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------------------------------------------------------------
  -- Screen File name - Quiz Management      Tab-3 (Name - Assign Quiz to Students)
  -- -------------------------------------------------------------------------------------------------------
  -- Quiz Allocation (Assignment)
  CREATE TABLE IF NOT EXISTS `lms_quiz_allocations` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `quiz_id` INT UNSIGNED NOT NULL,
    `allocation_type` ENUM('CLASS','SECTION','GROUP','STUDENT') NOT NULL,
    `target_table_name` VARCHAR(60) NOT NULL,        -- Name of the target table (e.g. 'sch_classes', 'sch_sections', 'sch_entity_groups', 'std_students')
    `target_id` INT UNSIGNED NOT NULL,             -- ID of Class, Section, Group, or Student (e.g. sch_classes.id, sch_sections.id, sch_entity_groups.id, std_students.id)
    `assigned_by` INT UNSIGNED DEFAULT NULL,       -- FK to sys_users.id (Who assigned the quest). Null if assigned by System
    -- Timing
    `published_at` DATETIME DEFAULT NULL,             -- Visible from
    `due_date` DATETIME DEFAULT NULL,                 -- Due by
    `cut_off_date` DATETIME DEFAULT NULL,             -- No submissions after
    `is_auto_publish_result` TINYINT(1) NOT NULL DEFAULT 0, -- Auto Publish Result (Result of the Class will be shown Automatically just after due date)
    `result_publish_date` DATETIME DEFAULT NULL,      -- Results visible from
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_quiz_alloc_target` (`allocation_type`, `target_id`),
    CONSTRAINT `fk_qa_quiz` FOREIGN KEY (`quiz_id`) REFERENCES `lms_quizzes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qa_assigner` FOREIGN KEY (`assigned_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- Foriegn Key Constraints for target_id needs to be maintained at Application Level as the target table names are dynamic.
  -- `is_auto_publish_result` in this table will overwrite `auto_publish_result` in `lms_quizzes` table to have different auto publish result settings for different allocations.


 -- ===========================================================================
 -- 16.3-LMS - QUEST (lms)
 -- ===========================================================================
  -- Main Quest Table
  CREATE TABLE IF NOT EXISTS `lms_quests` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `academic_session_id` INT UNSIGNED NOT NULL,   -- FK to glb_academic_sessions.id
    `class_id` INT UNSIGNED NOT NULL,              -- FK to sch_classes.id
    `subject_id` INT UNSIGNED NOT NULL,            -- FK to sch_subjects.id
    `quest_type_id` INT UNSIGNED NOT NULL,  -- FK to lms_assessment_types.id (e.g. 'Challenge', 'Enrichment', 'Practice', 'Revision', 'Re-Test', 'Diagnostic', 'Remedial')
    `quest_code` VARCHAR(50) NOT NULL,  -- Auto Generated (e.g. 'QUEST_9TH_SCI_L01_SUB08_EASY', 'QUEST_9TH_SCI_L01_SUB08_BALANCED', 'QUEST_9TH_SCI_L01_SUB08_DIFFICULT')
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `instructions` TEXT DEFAULT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    -- Settings
    `duration_minutes` INT UNSIGNED DEFAULT NULL,
    `total_marks` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    `total_questions` INT UNSIGNED NOT NULL DEFAULT 0,
    `passing_percentage` DECIMAL(5,2) NOT NULL DEFAULT 33.00,
    `allow_multiple_attempts` TINYINT(1) NOT NULL DEFAULT 0,
    `max_attempts` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `negative_marks` DECIMAL(4,2) NOT NULL DEFAULT 0.00, -- e.g. 0.25  (If Negative Marking Factor is zero then no negative marks will be given)
    `is_randomized` TINYINT(1) NOT NULL DEFAULT 0,  -- Randomize Questions (If this will be 1 then questions will be randomized)
    `question_marks_shown` TINYINT(1) NOT NULL DEFAULT 0, -- Show Question Marks (If this will be 1 then Question Marks will be shown when attempt to the quiz)
    `auto_publish_result` TINYINT(1) NOT NULL DEFAULT 0,  -- Auto Publish Result (Result of the Class will be shown Automatically just after due date)
    `timer_enforced` TINYINT(1) NOT NULL DEFAULT 1,  -- Enforce Timer (If Timer is enforced then timer will be shown)
    `show_correct_answer` TINYINT(1) NOT NULL DEFAULT 0, -- Show Correct Answer (If this will be 1 then Correct Answer will be shown when attempt to the quiz)
    `show_explanation` TINYINT(1) NOT NULL DEFAULT 0, -- Show Explanation (If this will be 1 then Explanation will be shown when attempt to the quiz)
    `difficulty_config_id` INT UNSIGNED DEFAULT NULL,  -- FK to lms_difficulty_distribution_configs
    `ignore_difficulty_config` TINYINT(1) NOT NULL DEFAULT 0, -- Ignore Difficulty Config (If this will be 1 then difficulty_config_id will be ignored)
    `is_system_generated` TINYINT(1) NOT NULL DEFAULT 0,  -- System Generated (If this will be 1 then quest will be generated by the system)
    `only_unused_questions` TINYINT(1) NOT NULL DEFAULT 0, -- Only Unused Questions (Question should not be in qns_question_usage_log)
    `only_authorised_questions` TINYINT(1) NOT NULL DEFAULT 0, -- If this will be 1 then use only questions where qns_questions_bank.for_quiz = 1
    -- Audit
    `created_by` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_quest_uuid` (`uuid`),
    UNIQUE KEY `uq_quest_code` (`quest_code`),
    CONSTRAINT `fk_quest_academic_session` FOREIGN KEY (`academic_session_id`) REFERENCES `glb_academic_sessions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_quest_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_quest_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_quest_type` FOREIGN KEY (`quest_type_id`) REFERENCES `lms_assessment_types` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_quest_diff` FOREIGN KEY (`difficulty_config_id`) REFERENCES `lms_difficulty_distribution_configs` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_quest_creator` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------------------------------------------------------------
  -- Screen File name - LMS Quest     Tab-2 (Name - Quest Scopes)
  -- -------------------------------------------------------------------------------------------------------
  -- Scope needs to be covered separately as Quest may cover Multipal Lesson, Topics, Sub-Topics.
  -- Quest Scopes (Topics covered)
  CREATE TABLE IF NOT EXISTS `lms_quest_scopes` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `quest_id` INT UNSIGNED NOT NULL,              -- FK to lms_quests.id
    `lesson_id` INT UNSIGNED NOT NULL,             -- FK to slb_lessons.id
    `topic_id` INT UNSIGNED NOT NULL,              -- FK to slb_topics.id
    `question_type_id` INT UNSIGNED DEFAULT NULL,     -- FK to qns_question_types.id (e.g. MCQs, True/False, Fill in the Blanks, etc.)
    `target_question_count` INT UNSIGNED DEFAULT 0,   -- Target Question Count (If this will be 0 then all the questions of the topic will be included)
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_qs_quest` FOREIGN KEY (`quest_id`) REFERENCES `lms_quests` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qs_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qs_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `slb_lessons` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------------------------------------------------------------
  -- Screen File name - LMS Quest     Tab-3 (Name - Add Questions to Quest)
  -- -------------------------------------------------------------------------------------------------------
  -- Quest Questions (Junction)
  CREATE TABLE IF NOT EXISTS `lms_quest_questions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `quest_id` INT UNSIGNED NOT NULL,              -- FK to lms_quests.id
    `question_id` INT UNSIGNED NOT NULL,           -- FK to qns_questions.id
    `ordinal` INT UNSIGNED NOT NULL DEFAULT 0,
    `marks_override` DECIMAL(5,2) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_quest_ques` (`quest_id`, `question_id`),
    CONSTRAINT `fk_qst_q_quest` FOREIGN KEY (`quest_id`) REFERENCES `lms_quests` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qst_q_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------------------------------------------------------------
  -- Screen File name - LMS Quest     Tab-4 (Name - Assign Quest to Students)
  -- -------------------------------------------------------------------------------------------------------
  -- Quest Allocations
  CREATE TABLE IF NOT EXISTS `lms_quest_allocations` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `quest_id` INT UNSIGNED NOT NULL,
    `allocation_type` ENUM('CLASS','SECTION','GROUP','STUDENT') NOT NULL,
    `target_table_name` VARCHAR(60) NOT NULL,        -- Name of the target table (e.g. 'sch_classes', 'sch_sections', 'sch_entity_groups', 'std_students')
    `target_id` INT UNSIGNED NOT NULL,             -- ID of Class, Section, Group, or Student (e.g. sch_classes.id, sch_sections.id, sch_entity_groups.id, std_students.id)
    `assigned_by` INT UNSIGNED DEFAULT NULL,       -- FK to sys_users.id (Who assigned the quest). Null if assigned by System
    -- Timing
    `published_at` DATETIME DEFAULT NULL,
    `due_date` DATETIME DEFAULT NULL,
    `cut_off_date` DATETIME DEFAULT NULL,             -- No submissions after
    `is_auto_publish_result` TINYINT(1) NOT NULL DEFAULT 0, -- Auto Publish Result (Result of the Class will be shown Automatically just after due date)
    `result_publish_date` DATETIME DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_quest_alloc_target` (`allocation_type`, `target_id`),
    CONSTRAINT `fk_qsta_quest` FOREIGN KEY (`quest_id`) REFERENCES `lms_quests` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qsta_assigner` FOREIGN KEY (`assigned_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


 -- ===========================================================================
 -- 16.4-LMS - EXAM (ONLINE) (lms)
 -- ===========================================================================
  CREATE TABLE IF NOT EXISTS `lms_exam_types` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(50) NOT NULL,              -- e.g. 'UT-1','UT-2','UT-3','UT-4','HY-EXAM','ANNUAL-EXAM'
    `name` VARCHAR(100) NOT NULL,             -- e.g. 'Unit Test 1','Unit Test 2','Unit Test 3','Unit Test 4','Half Yearly Exam','Annual Exam'
    `description` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_exam_type_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- --------------------------------------------------------------------------------------
  -- Screen Exam Master (Tab -2 Exam Status Events)
  -- This table will store the exam status events (e.g., DRAFT, PUBLISHED, CONCLUDED, ARCHIVED)
  -- --------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_exam_status_events` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(50) NOT NULL,  -- (e.g. 'DRAFT','PUBLISHED','CONCLUDED','ARCHIVED')
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `event_type` ENUM('EXAM','PAPER','RESULT','ATTEMPT') NOT NULL DEFAULT 'EXAM',
    `action_logic` JSON NOT NULL,         -- e.g., '{"logic": "assign_exam_actions"}'
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_exam_status_event_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- Exam - ('DRAFT','PUBLISHED','CONCLUDED','ARCHIVED')
  -- Paper - ('NOT_STARTED','IN_PROGRESS','SUBMITTED','EVALUATION_PENDING','EVALUATED','RESULT_PUBLISHED','ABSENT','CANCELLED')
  -- Result - ('NOT_STARTED','IN_PROGRESS','SUBMITTED','EVALUATION_PENDING','EVALUATED','RESULT_PUBLISHED','ABSENT','CANCELLED')
  -- Attempt - ('NOT_STARTED','IN_PROGRESS','SUBMITTED','EVALUATION_PENDING','EVALUATED','RESULT_PUBLISHED','ABSENT','CANCELLED')

  -- --------------------------------------------------------------------------------------
  -- Screen Exam Master (Tab -3 Student Groups)
  -- Student Groups for Exam Purposes
  -- Allows creating ad-hoc groups (e.g., "Class 9 Adv Math") derived from classes/sections
  -- --------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_exam_student_groups` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_id` INT UNSIGNED NOT NULL,             -- FK to lms_exams.id
    `class_id` INT UNSIGNED NOT NULL,            -- FK to sch_classes.id
    `section_id` INT UNSIGNED NOT NULL,          -- FK to sch_sections.id
    `code` VARCHAR(50) NOT NULL,                   -- e.g. "9th-A_SET-A"
    `name` VARCHAR(100) NOT NULL,                   -- e.g. "Class 9th-A, Group SET-A"
    `description` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_esg_code` (`exam_id`, `class_id`, `section_id`, `code`),
    CONSTRAINT `fk_esg_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_esg_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_esg_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- --------------------------------------------------------------------------------------
  -- Screen Exam Master (Tab -4 Student Group Members)
  -- Members of the Ad-hoc Groups (e.g., "Class 9th-A, Group SET-A")
  -- --------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_exam_student_group_members` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `group_id` INT UNSIGNED NOT NULL,            -- FK to lms_exam_student_groups.id
    `student_id` INT UNSIGNED NOT NULL,          -- FK to sch_students / sys_users
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_esgm_member` (`group_id`, `student_id`),
    CONSTRAINT `fk_esgm_group` FOREIGN KEY (`group_id`) REFERENCES `lms_exam_student_groups` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_esgm_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------------------------------------------- 
  -- SCREEN Name - EXAM Creation (Tab -1 Exam)
  -- This table is used to define the exam event and its basic details. 
  -- --------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_exams` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `academic_session_id` INT UNSIGNED NOT NULL, -- FK to glb_academic_sessions.id
    `class_id` INT UNSIGNED NOT NULL,            -- FK to sch_classes.id
    `exam_type_id` INT UNSIGNED NOT NULL,        -- FK to lms_exam_types.id (e.g. 'UT-1','UT-2','UT-3','UT-4','HY-EXAM','ANNUAL-EXAM')
    `code` VARCHAR(50) NOT NULL,                    -- e.g. 'EXAM_2025_ANNUAL'
    `title` VARCHAR(150) NOT NULL,                  -- e.g. 'Annual Examination 2025-26'
    `description` TEXT DEFAULT NULL,
    `start_date` DATE NOT NULL,
    `end_date` DATE NOT NULL,
    `grading_schema_id` INT UNSIGNED DEFAULT NULL, -- FK to slb_grade_division_master (Default schema for the exam Grading / Division)
    `status_id` INT UNSIGNED NOT NULL DEFAULT 0,    -- FK to lms_exam_status_events.id (Status of the exam) 'DRAFT','PUBLISHED','CONCLUDED','ARCHIVED')
    `created_by` INT UNSIGNED DEFAULT NULL,         -- FK to sys_users.id
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_exam_uuid` (`uuid`),
    UNIQUE KEY `uq_exam_code` (`code`),
    UNIQUE KEY `uq_exam_session_class_type` (`academic_session_id`, `class_id`, `exam_type_id`),
    CONSTRAINT `fk_exam_session` FOREIGN KEY (`academic_session_id`) REFERENCES `glb_academic_sessions` (`id`),
    CONSTRAINT `fk_exam_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_exam_type` FOREIGN KEY (`exam_type_id`) REFERENCES `lms_exam_types` (`id`),
    CONSTRAINT `fk_exam_grading` FOREIGN KEY (`grading_schema_id`) REFERENCES `slb_grade_division_master` (`id`),
    CONSTRAINT `fk_exam_status` FOREIGN KEY (`status_id`) REFERENCES `lms_exam_status_events` (`id`),
    CONSTRAINT `fk_exam_creator` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- --------------------------------------------------------------------------------------
  -- SCREEN Name - EXAM Creation (Tab -2 Exam Papers)
  -- This table is used to define the exam paper and its basic details. 
  -- Represents a specific paper for a specific mode, e.g., "Class 9 - Math - Online"
  -- --------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_exam_papers` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_id` INT UNSIGNED NOT NULL,             -- FK to lms_exams.id
    `class_id` INT UNSIGNED NOT NULL,            -- FK to sch_classes.id
    `subject_id` INT UNSIGNED NOT NULL,          -- FK to sch_subjects.id
    `paper_code` VARCHAR(50) NOT NULL,              -- e.g. 'UT-1_2025_ANNUAL_MTH_ON'
    `title` VARCHAR(150) NOT NULL,                  -- e.g. 'Unit Test 1 - 2025-26 - Mathematics - Online'
    `mode` ENUM('ONLINE', 'OFFLINE') NOT NULL,
    `total_marks` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    --`passing_marks` DECIMAL(8,2) NOT NULL DEFAULT 0.00,  -- New ( Changed)
    `passing_percentage` DECIMAL(5,2) NOT NULL DEFAULT 0.00,  -- New
    `duration_minutes` INT UNSIGNED DEFAULT NULL,   -- Relevant for Online, Guide for Offline
    `total_questions` INT UNSIGNED NOT NULL DEFAULT 0,   -- New
    `negative_marks` DECIMAL(5,2) DEFAULT 0.00,     -- Negative marks (if any). -- New
    `instructions` TEXT DEFAULT NULL,
    `only_unused_questions` TINYINT(1) NOT NULL DEFAULT 0, -- Only Unused Questions (Question should not be in qns_question_usage_log)
    `only_authorised_questions` TINYINT(1) NOT NULL DEFAULT 0, -- If this will be 1 then use only questions where qns_questions_bank.for_quiz = 1
    `difficulty_config_id` INT UNSIGNED DEFAULT NULL,  -- FK to lms_difficulty_distribution_configs
    `ignore_difficulty_config` TINYINT(1) NOT NULL DEFAULT 0, -- Ignore Difficulty Config (If this will be 1 then difficulty_config_id will be ignored)
    `allow_calculator` TINYINT(1) NOT NULL DEFAULT 0,  -- Allow Calculator (If this will be 1 then calculator will be allowed). -- New
    `show_marks_per_question` TINYINT(1) NOT NULL DEFAULT 1,  -- Show Marks Per Question (If this will be 1 then marks per question will be shown). -- New
    `is_randomized` TINYINT(1) NOT NULL DEFAULT 0,  -- Randomize Questions (If this will be 1 then questions will be randomized). -- New
    -- Online Specific Config
    `is_proctored` TINYINT(1) NOT NULL DEFAULT 0,
    `is_ai_proctored` TINYINT(1) NOT NULL DEFAULT 0,
    `fullscreen_required` TINYINT(1) NOT NULL DEFAULT 0,
    `browser_lock_required` TINYINT(1) NOT NULL DEFAULT 0,
    `shuffle_questions` TINYINT(1) NOT NULL DEFAULT 0,
    `shuffle_options` TINYINT(1) NOT NULL DEFAULT 0,  -- Randomize Options (If this will be 1 then options will be randomized). -- New
    `timer_enforced` TINYINT(1) NOT NULL DEFAULT 1,  -- Enforce Timer (If Timer is enforced then timer will be shown). -- New
    `show_result_type` ENUM('IMMEDIATE','SCHEDULED','MANUAL') NOT NULL DEFAULT 'MANUAL',
    `scheduled_result_at` DATETIME DEFAULT NULL,
    -- Offline Specific Config
    `offline_entry_mode` ENUM('BULK_TOTAL','QUESTION_WISE') DEFAULT 'BULK_TOTAL', -- How marks will be entered
    -- Audit
    `status_id` INT UNSIGNED NOT NULL DEFAULT 0,    -- FK to lms_exam_status_events.id (Status of the exam) 'DRAFT','PUBLISHED','CONCLUDED','ARCHIVED')
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_exam_paper_code` (`exam_id`, `paper_code`),
    CONSTRAINT `fk_paper_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_paper_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_paper_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`),
    CONSTRAINT `fk_paper_difficulty_config` FOREIGN KEY (`difficulty_config_id`) REFERENCES `lms_difficulty_distribution_configs` (`id`),
    CONSTRAINT `fk_paper_status` FOREIGN KEY (`status_id`) REFERENCES `lms_exam_status_events` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- --------------------------------------------------------------------------------------
  -- SCREEN Name - EXAM Creation (Tab -3 Exam Paper Sets)
  -- This table will be used to define variants of the papers
  -- --------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_exam_paper_sets` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_paper_id` INT UNSIGNED NOT NULL,       -- FK to lms_exam_papers.id
    `set_code` VARCHAR(20) NOT NULL,                -- e.g. 'SET_A', 'SET_B' OR 'SET_1', 'SET_2'
    `set_name` VARCHAR(50) NOT NULL,                -- e.g. 'Paper Set A' OR 'Paper Set 1'
    `description` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_paper_set` (`exam_paper_id`, `set_code`),
    CONSTRAINT `fk_set_paper` FOREIGN KEY (`exam_paper_id`) REFERENCES `lms_exam_papers` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- --------------------------------------------------------------------------------------
  -- SCREEN Name - EXAM Creation (Tab -4 Exam Scopes)
  -- This table will be used to define variants of the papers (New Table)
  -- --------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_exam_scopes` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_paper_id` INT UNSIGNED NOT NULL,       -- FK to lms_exam_papers.id
    `lesson_id` INT UNSIGNED DEFAULT NULL,     -- FK to slb_lessons (Optional, if specific lesson)
    `topic_id` INT UNSIGNED DEFAULT NULL,      -- FK to slb_topics (Optional, if specific topic)
    `question_type_id` INT UNSIGNED DEFAULT NULL,     -- FK to slb_question_types.id (e.g. MCQs, True/False, Fill in the Blanks, etc.)
    `target_question_count` INT UNSIGNED DEFAULT 0,   -- Target Question Count (If this will be 0 then all the questions of the topic will be included)
    `weightage_percent` DECIMAL(5,2) DEFAULT NULL, -- Weightage of this scope(Lesson,Topic,Sub-Topic) in the exam
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_es_exam` FOREIGN KEY (`exam_paper_id`) REFERENCES `lms_exam_papers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_es_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `slb_lessons` (`id`),
    CONSTRAINT `fk_es_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`),
    CONSTRAINT `fk_es_question_type` FOREIGN KEY (`question_type_id`) REFERENCES `slb_question_types` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------------------------------------------------------------
  -- SCREEN Name - EXAM Creation (Tab -5 Exam Blueprints). (New Table)
  -- This table will be used to define the structure of the exam. Useful for generating question papers automatically.
  -- -------------------------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_exam_blueprints` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_paper_id` INT UNSIGNED NOT NULL,       -- FK to lms_exam_papers.id
    `section_name` VARCHAR(50) DEFAULT 'Section A', -- e.g., 'Part 1', 'Section A - Objective'
    `question_type_id` INT UNSIGNED DEFAULT NULL,     -- FK to slb_question_types.id (e.g. MCQs, Descriptive, Fill in the Blanks, etc.)
    `instruction_text` TEXT DEFAULT NULL,
    `total_questions` INT UNSIGNED NOT NULL DEFAULT 0,
    `marks_per_question` DECIMAL(5,2) DEFAULT NULL, -- If fixed marks for this section
    `total_marks` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    `ordinal` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_eb_exam` FOREIGN KEY (`exam_paper_id`) REFERENCES `lms_exam_papers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_eb_question_type` FOREIGN KEY (`question_type_id`) REFERENCES `slb_question_types` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- --------------------------------------------------------------------------------------
  -- SCREEN Name - EXAM Creation (Tab -4 Add Question to Paper Sets)
  -- This Table will be used to link questions from Question Bank to a specific Exam Paper Set
  -- --------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_paper_set_questions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `paper_set_id` INT UNSIGNED NOT NULL,        -- FK to lms_exam_paper_sets.id
    `question_id` INT UNSIGNED NOT NULL,         -- FK to qns_questions_bank.id
    `section_name` VARCHAR(50) DEFAULT 'Section A', -- Logical grouping within paper to showcase MCQ, Long Answer, Short Answer etc.
    `ordinal` INT UNSIGNED NOT NULL DEFAULT 0,      -- Sequence order
    `override_marks` DECIMAL(5,2) NOT NULL,         -- Override marks from Question Bank
    `negative_marks` DECIMAL(5,2) DEFAULT 0.00,     -- Negative marks (if any)
    `is_compulsory` TINYINT(1) NOT NULL DEFAULT 1,  -- Attempting Question is Compulsory or Optional 
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,       -- Active or Inactive
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_set_question` (`paper_set_id`, `question_id`),
    CONSTRAINT `fk_sq_set` FOREIGN KEY (`paper_set_id`) REFERENCES `lms_exam_paper_sets` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sq_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- --------------------------------------------------------------------------------------
  -- SCREEN Name - EXAM Creation (Tab -5 Student Allocations)
  -- This table will be used to define allocations: Mapping Papers/Sets to Students/Groups
  -- --------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_exam_allocations` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_paper_id` INT UNSIGNED NOT NULL,       -- Which paper
    `paper_set_id` INT UNSIGNED NOT NULL,        -- Which set (Specific variant)
    -- Target definition
    `allocation_type` ENUM('CLASS','SECTION','EXAM_GROUP','STUDENT') NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,        -- FK to sch_classes.id (Class is must)
    `section_id` INT UNSIGNED NULL,          -- FK to sch_sections.id (Section is optional)
    `exam_group_id` INT UNSIGNED NULL,       -- FK to lms_exam_student_groups.id (Exam Group is optional)
    `student_id` INT UNSIGNED NULL,          -- FK to sch_students / sys_users (Student is optional)
    -- Scheduling Overrides
    `scheduled_date` DATE DEFAULT NULL,         -- If different from paper default
    `scheduled_start_time` TIME NOT NULL,
    `scheduled_end_time` TIME NOT NULL,
    `location` VARCHAR(100) DEFAULT NULL,       -- relevant for Offline
    -- Status
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_alloc_target` (`allocation_type`, `class_id`, `section_id`, `exam_group_id`, `student_id`),
    CONSTRAINT `fk_alloc_paper` FOREIGN KEY (`exam_paper_id`) REFERENCES `lms_exam_papers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_alloc_set` FOREIGN KEY (`paper_set_id`) REFERENCES `lms_exam_paper_sets` (`id`),
    CONSTRAINT `fk_alloc_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_alloc_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_alloc_exam_group` FOREIGN KEY (`exam_group_id`) REFERENCES `lms_exam_student_groups` (`id`),
    CONSTRAINT `fk_alloc_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


 -- ===========================================================================
 -- 16.5-LMS - EXAM (OFFLINE) (lms)
 -- ===========================================================================


 -- ===========================================================================
 -- 16.6-LMS - STUDENT ATTEMPTS (lms)
 -- ===========================================================================

  -- --------------------------------------------------------------------------------------
  -- Student Attempts (Unified for Quiz & Quest)
  -- --------------------------------------------------------------------------------------
  -- Student Attempts
  CREATE TABLE IF NOT EXISTS `lms_quiz_quest_attempts` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `student_id` INT UNSIGNED NOT NULL,            -- FK to sch_students.id
    `assessment_type` ENUM('QUIZ','QUEST') NOT NULL,
    `assessment_id` INT UNSIGNED NOT NULL,         -- FK to lms_quizzes.id or lms_quests.id
    `allocation_id` INT UNSIGNED DEFAULT NULL,     -- FK to lms_quiz_allocations.id or lms_quest_allocations.id
    `attempt_number` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `started_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `completed_at` DATETIME DEFAULT NULL,
    `status` ENUM('NOT_STARTED','IN_PROGRESS','SUBMITTED','TIMEOUT','ABANDONED','CANCELLED','REASSIGNED') NOT NULL DEFAULT 'NOT_STARTED',
    `total_score` DECIMAL(8,2) DEFAULT NULL,
    `percentage` DECIMAL(5,2) DEFAULT NULL,
    `is_passed` TINYINT(1) DEFAULT 0,
    `teacher_feedback` TEXT DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_att_student` (`student_id`),
    KEY `idx_att_assessment` (`assessment_type`, `assessment_id`)
    -- Note: Cannot enforce FK on assessment_id alone due to polymorphism
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
  -- attemp_number will increase by 1 on every attempt


  -- Attempt Answers
  CREATE TABLE IF NOT EXISTS `lms_quiz_quest_attempt_answers` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `attempt_id` INT UNSIGNED NOT NULL,
    `question_id` INT UNSIGNED NOT NULL,           -- FK to qns_questions_bank.id
    `selected_option_id` INT UNSIGNED DEFAULT NULL, -- FK to qns_question_options.id (For MCQ)
    `answer_text` TEXT DEFAULT NULL,                  -- For Descriptive/Fill-in
    `marks_obtained` DECIMAL(5,2) DEFAULT 0.00,
    `is_correct` TINYINT(1) DEFAULT NULL,             -- NULL = Not Graded, 0=Incorrect, 1=Correct
    `time_taken_seconds` INT UNSIGNED DEFAULT 0,      -- Telemetry
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_ans_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_quiz_quest_attempts` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ans_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_ans_option` FOREIGN KEY (`selected_option_id`) REFERENCES `qns_question_options` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- --------------------------------------------------------------------------------------
  -- Student Attempts & Exam Record (Online & Offline Exams)
  -- --------------------------------------------------------------------------------------

  CREATE TABLE IF NOT EXISTS `lms_student_attempts` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `exam_paper_id` INT UNSIGNED NOT NULL,       -- FK to lms_exam_papers.id
    `paper_set_id` INT UNSIGNED NOT NULL,        -- FK to lms_exam_paper_sets.id (The actual set assigned/taken)
    `allocation_id` INT UNSIGNED DEFAULT NULL,   -- FK to lms_exam_allocations.id (Link to allocation rule)
    `student_id` INT UNSIGNED NOT NULL,          -- FK to std_students.id (The student who took the exam)
    -- Timing
    `actual_started_time` DATETIME DEFAULT NULL,    -- Actual Exam Start Time
    `actual_end_time` DATETIME DEFAULT NULL,        -- Actual Exam End Time (The time when student submitted the exam)
    `actual_time_taken_seconds` INT UNSIGNED DEFAULT 0,
    -- Status
    `status_id` INT UNSIGNED NOT NULL DEFAULT 0,    -- FK to lms_exam_status_events.id (Status of the exam) 'NOT_STARTED','IN_PROGRESS','SUBMITTED','EVALUATION_PENDING','EVALUATED','RESULT_PUBLISHED','ABSENT','CANCELLED')
    `attempt_mode` ENUM('ONLINE', 'OFFLINE') NOT NULL,
    -- Offline Metadata
    `answer_sheet_number` VARCHAR(50) DEFAULT NULL, -- Physical sheet ID
    `is_present_offline` TINYINT(1) DEFAULT 1,      -- For attendance
    -- Online Metadata
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `device_info` JSON DEFAULT NULL,
    `violation_count` INT UNSIGNED DEFAULT 0,
    -- Audit
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_attempt_uuid` (`uuid`),
    UNIQUE KEY `uq_attempt_student_paper` (`exam_paper_id`, `student_id`),
    CONSTRAINT `fk_att_paper` FOREIGN KEY (`exam_paper_id`) REFERENCES `lms_exam_papers` (`id`),
    CONSTRAINT `fk_att_set` FOREIGN KEY (`paper_set_id`) REFERENCES `lms_exam_paper_sets` (`id`),
    CONSTRAINT `fk_att_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_att_alloc` FOREIGN KEY (`allocation_id`) REFERENCES `lms_exam_allocations` (`id`),
    CONSTRAINT `fk_att_status` FOREIGN KEY (`status_id`) REFERENCES `lms_exam_status_events` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Student Answers (Granular Data)
  -- Used for Online Exams AND Offline Exams (if doing question-wise entry)
  -- --------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_attempt_answers` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `attempt_id` INT UNSIGNED NOT NULL,
    `question_id` INT UNSIGNED NOT NULL,
    
    -- The Response
    `selected_option_id` INT UNSIGNED DEFAULT NULL, -- For MCQ
    `descriptive_answer` TEXT DEFAULT NULL,            -- For Online Descriptive
    `attachment_id` INT UNSIGNED DEFAULT NULL,      -- Uploaded file
    
    -- Evaluation
    `marks_obtained` DECIMAL(5,2) DEFAULT 0.00,
    `is_correct` TINYINT(1) DEFAULT NULL,
    `remarks` VARCHAR(255) DEFAULT NULL,
    `evaluated_by` INT UNSIGNED DEFAULT NULL,       -- Teacher ID / NULL for System
    
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ans_attempt_q` (`attempt_id`, `question_id`),
    CONSTRAINT `fk_ans_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_student_attempts` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ans_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  -- --------------------------------------------------------------------------
  -- 5. RESULTS & GRADING
  -- --------------------------------------------------------------------------

  -- Bulk Marks Entry (For Offline Exams only - Skipping Granular Answers)
  -- --------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_exam_marks_entry` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `attempt_id` INT UNSIGNED NOT NULL,          -- FK to lms_student_attempts
    `total_marks_obtained` DECIMAL(8,2) NOT NULL,
    `remarks` VARCHAR(255) DEFAULT NULL,
    `entered_by` INT UNSIGNED NOT NULL,          -- Teacher
    `entered_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_marks_entry_attempt` (`attempt_id`),
    CONSTRAINT `fk_me_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_student_attempts` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_me_enterer` FOREIGN KEY (`entered_by`) REFERENCES `sys_users` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



  -- --------------------------------------------------------------------------
  -- 3. EXAM EXECUTION & RESULTS (Attempts, Answers, Evaluation)
  -- --------------------------------------------------------------------------

  -- -------------------------------------------------------------------------------------------------------
  -- Table: lms_student_attempts
  -- Purpose: Tracks a student's attempt at an exam (or quiz/quest if consolidated, but here specifically Exam).
  -- -------------------------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_student_attempts` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `exam_id` INT UNSIGNED NOT NULL,           -- FK to lms_exams
    `student_id` INT UNSIGNED NOT NULL,        -- FK to sch_students (or sys_users)
    `allocation_id` INT UNSIGNED DEFAULT NULL, -- FK to lms_exam_allocations
    
    -- Timing
    `started_at` DATETIME DEFAULT NULL,
    `submitted_at` DATETIME DEFAULT NULL,
    `concluded_at` DATETIME DEFAULT NULL,         -- Auto-submitted by system
    `time_taken_seconds` INT UNSIGNED DEFAULT 0,
    
    -- Status
    `status` ENUM('NOT_STARTED','IN_PROGRESS','SUBMITTED','EVALUATION_PENDING','EVALUATED','MISSED','CANCELLED') NOT NULL DEFAULT 'NOT_STARTED',
    `attempt_mode` ENUM('ONLINE','OFFLINE') NOT NULL DEFAULT 'ONLINE',
    
    -- Proctoring Data
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `browser_agent` TEXT DEFAULT NULL,
    `device_info` JSON DEFAULT NULL,
    `violation_count` INT UNSIGNED DEFAULT 0,     -- Proctoring violations detected
    
    -- Offline Metadata
    `offline_paper_uploaded_id` INT UNSIGNED DEFAULT NULL, -- FK to sys_media (Scanned answer sheet)
    
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_attempt_uuid` (`uuid`),
    UNIQUE KEY `uq_attempt_student_exam` (`exam_id`, `student_id`), -- Assuming 1 attempt per exam rule for now (or make non-unique if re-attempts allowed)
    CONSTRAINT `fk_att_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_att_student` FOREIGN KEY (`student_id`) REFERENCES `sch_students` (`id`), -- Or sys_users
    CONSTRAINT `fk_att_alloc` FOREIGN KEY (`allocation_id`) REFERENCES `lms_exam_allocations` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------------------------------------------------------------
  -- Table: lms_exam_answers
  -- Purpose: Stores student responses to questions.
  -- -------------------------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_exam_answers` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `attempt_id` INT UNSIGNED NOT NULL,        -- FK to lms_student_attempts
    `question_id` INT UNSIGNED NOT NULL,       -- FK to qns_questions_bank
    `question_type_id` INT UNSIGNED NOT NULL,  -- Cached type for logic
    
    -- Usage Context (Since this table might be large, identifying if it's exam or quiz answer helps partitioning if needed)
    -- But here we imply it's for the 'attempt_id' which is tied to an exam.
    
    -- The Answer
    `selected_option_id` INT UNSIGNED DEFAULT NULL, -- For Single MCQ
    `selected_option_ids` JSON DEFAULT NULL,           -- For Multi MCQ (Array of IDs)
    `descriptive_answer` TEXT DEFAULT NULL,            -- For Text answers
    `attachment_id` INT UNSIGNED DEFAULT NULL,      -- FK to sys_media (if file upload required)
    
    -- Evaluation
    `is_correct` TINYINT(1) DEFAULT NULL,              -- 1=Correct, 0=Incorrect, NULL=Not Evaluated
    `marks_obtained` DECIMAL(5,2) DEFAULT 0.00,
    `is_evaluated` TINYINT(1) NOT NULL DEFAULT 0,
    `evaluated_by` INT UNSIGNED DEFAULT NULL,       -- FK to sys_users (Teacher) or NULL if Auto
    `evaluation_remarks` TEXT DEFAULT NULL,
    `evaluated_at` DATETIME DEFAULT NULL,
    
    -- Analytics
    `time_spent_seconds` INT UNSIGNED DEFAULT 0,
    `change_count` SMALLINT UNSIGNED DEFAULT 0,        -- How many times answer was changed
    
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ans_attempt_q` (`attempt_id`, `question_id`),
    CONSTRAINT `fk_ans_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_student_attempts` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ans_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



  -- Final Consolidated Result
  -- --------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_exam_results` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_id` INT UNSIGNED NOT NULL,             -- FK to lms_exams
    `student_id` INT UNSIGNED NOT NULL,
    
    -- Aggregated Scores
    `total_marks` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    `max_marks` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    `percentage` DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    
    -- Grade & Status
    `grade` VARCHAR(10) DEFAULT NULL,               -- Derived from Grading Schema
    `result_status` ENUM('PASS','FAIL','WITHHELD','ABSENT') NOT NULL DEFAULT 'PASS',
    
    `is_published` TINYINT(1) NOT NULL DEFAULT 0,
    `published_at` DATETIME DEFAULT NULL,
    
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_result_exam_stud` (`exam_id`, `student_id`),
    CONSTRAINT `fk_res_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_res_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------------------------------------------------------------
  -- Table: lms_exam_results
  -- Purpose: Final consolidated result for the student.
  -- -------------------------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_exam_results` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_id` INT UNSIGNED NOT NULL,
    `student_id` INT UNSIGNED NOT NULL,
    `attempt_id` INT UNSIGNED DEFAULT NULL,     -- Optional, if based on a specific attempt
    
    -- Scores
    `total_marks_possible` DECIMAL(8,2) NOT NULL,
    `total_marks_obtained` DECIMAL(8,2) NOT NULL,
    `percentage` DECIMAL(5,2) NOT NULL,
    `grade_obtained` VARCHAR(10) DEFAULT NULL,     -- A+, B, etc.
    `division` VARCHAR(20) DEFAULT NULL,           -- First, Second, etc.
    `result_status` ENUM('PASS','FAIL','ABSENT','WITHHELD') NOT NULL,
    `rank_in_class` INT UNSIGNED DEFAULT NULL,
    `percentile` DECIMAL(5,2) DEFAULT NULL,
    
    -- Publishing
    `is_published` TINYINT(1) NOT NULL DEFAULT 0,
    `published_at` DATETIME DEFAULT NULL,
    `teacher_remarks` TEXT DEFAULT NULL,
    `generated_report_card_url` VARCHAR(255) DEFAULT NULL, -- Path to PDF if generated
    
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_res_exam_stud` (`exam_id`, `student_id`),
    CONSTRAINT `fk_res_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_res_student` FOREIGN KEY (`student_id`) REFERENCES `sch_students` (`id`),
    CONSTRAINT `fk_res_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_student_attempts` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  -- Grievances / Re-eval Requests
  -- --------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_exam_grievances` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_result_id` INT UNSIGNED NOT NULL,
    `question_id` INT UNSIGNED DEFAULT NULL,     -- Optional (Null if general grievance)
    `grievance_type` ENUM('MARKING_ERROR','QUESTION_ERROR','OUT_OF_SYLLABUS','OTHER') NOT NULL,
    `description` TEXT NOT NULL,
    `status` ENUM('OPEN','IN_PROGRESS','RESOLVED','REJECTED') NOT NULL DEFAULT 'OPEN',
    `resolution_remarks` TEXT DEFAULT NULL,
    `resolved_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_grv_result` FOREIGN KEY (`exam_result_id`) REFERENCES `lms_exam_results` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_grv_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- -------------------------------------------------------------------------------------------------------
  -- Table: lms_exam_grievances
  -- Purpose: Student grievance against evaluation.
  -- -------------------------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_exam_grievances` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_result_id` INT UNSIGNED NOT NULL,     -- FK to lms_exam_results
    `question_id` INT UNSIGNED NOT NULL,        -- FK to qns_questions_bank
    `student_id` INT UNSIGNED NOT NULL,
    `grievance_text` TEXT NOT NULL,
    `status` ENUM('OPEN','UNDER_REVIEW','RESOLVED','REJECTED') NOT NULL DEFAULT 'OPEN',
    `reviewer_id` INT UNSIGNED DEFAULT NULL,    -- Teacher who reviewed
    `resolution_remarks` TEXT DEFAULT NULL,
    `marks_changed` TINYINT(1) DEFAULT 0,
    `old_marks` DECIMAL(5,2) DEFAULT NULL,
    `new_marks` DECIMAL(5,2) DEFAULT NULL,
    `resolved_at` DATETIME DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_grv_result` FOREIGN KEY (`exam_result_id`) REFERENCES `lms_exam_results` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_grv_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`),
    CONSTRAINT `fk_grv_student` FOREIGN KEY (`student_id`) REFERENCES `sch_students` (`id`),
    CONSTRAINT `fk_grv_reviewer` FOREIGN KEY (`reviewer_id`) REFERENCES `sys_users` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  -- --------------------------------------------------------------------------
  -- 4. ANALYTICS & LOGGING
  -- --------------------------------------------------------------------------

  -- -------------------------------------------------------------------------------------------------------
  -- Table: lms_attempt_activity_logs
  -- Purpose: Technical logs of student behavior during exam (tab switch, etc.)
  -- -------------------------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `lms_attempt_activity_logs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `attempt_id` INT UNSIGNED NOT NULL,
    `activity_type` ENUM('FOCUS_LOST','FULLSCREEN_EXIT','BROWSER_RESIZE','KEY_PRESS_BLOCKED','MOUSE_LEAVE','IP_CHANGE') NOT NULL,
    `activity_data` JSON DEFAULT NULL,
    `occurred_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_log_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_student_attempts` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===========================================================================
-- 17-LXP (lxp)
-- ===========================================================================


-- ===========================================================================
-- 18-LIBRARY (lib)
-- ===========================================================================

 -- ----------------------------------------------------------------------------
 -- 1. CORE LOOKUP TABLES (System Dropdowns)
 -- ----------------------------------------------------------------------------

  -- Defines different types of library memberships with their associated privileges and rules. Controls borrowing limits, loan periods, and fine calculations.
  CREATE TABLE IF NOT EXISTS `lib_membership_types` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `max_books_allowed` INT NOT NULL CHECK (max_books_allowed >= 0),
    `loan_period_days` INT NOT NULL CHECK (loan_period_days > 0),
    `renewal_allowed` TINYINT(1) DEFAULT TRUE,
    `max_renewals` INT DEFAULT 0 CHECK (max_renewals >= 0),
    `fine_rate_per_day` DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (fine_rate_per_day >= 0),
    `grace_period_days` INT DEFAULT 0 CHECK (grace_period_days >= 0),
    `priority_level` INT DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_membership_active` (`is_active`),
    INDEX `idx_membership_priority` (`priority_level`),
    UNIQUE KEY `uk_membership_type_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Hierarchical classification of books/resources (e.g., Fiction → Science Fiction → Space Opera). Supports multi-level categorization.
  CREATE TABLE IF NOT EXISTS `lib_categories` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `parent_category_id` INT NULL,
    `code` VARCHAR(30) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255),
    `level` INT DEFAULT 1,
    `display_order` INT DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`parent_category_id`) REFERENCES `lib_categories`(`id`),
    INDEX `idx_category_parent` (`parent_category_id`),
    INDEX `idx_category_active` (`is_active`),
    INDEX `idx_category_order` (`display_order`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tags for literary genres that can be applied across categories for flexible searching and recommendations.
  CREATE TABLE IF NOT EXISTS `lib_genres` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255),
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_genre_active` (`is_active`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Master list of publishers for books and resources.
  CREATE TABLE IF NOT EXISTS `lib_publishers` ( 
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL UNIQUE,
    `name` VARCHAR(200) NOT NULL,
    `address` TEXT,
    `contact` VARCHAR(100),
    `email` VARCHAR(100),
    `phone` VARCHAR(20),
    `website` VARCHAR(255),
    `is_active` TINYINT(1) DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_publisher_active` (`is_active`, `is_deleted`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Classification of resource formats (physical books, e-books, PDFs, audio books, etc.) to handle different media types appropriately.
  CREATE TABLE IF NOT EXISTS `lib_resource_types` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `is_physical` TINYINT(1) NOT NULL DEFAULT 1,
    `is_digital` TINYINT(1) NOT NULL DEFAULT 0,
    `is_audio_books` TINYINT(1) NOT NULL DEFAULT 0,
    `is_borrowable` TINYINT(1) NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_restype_active` (`is_active`, `is_deleted`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Physical location mapping for books in the library, enabling efficient shelving and retrieval. 
  CREATE TABLE IF NOT EXISTS `lib_shelf_locations` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL UNIQUE,
    `aisle_number` VARCHAR(20) NOT NULL,  -- These numbers are listed on signs at the end of shelves (e.g., Aisle 1, Side A)
    `shelf_number` VARCHAR(20) NOT NULL,  -- These numbers are usually on the side of the shelf (e.g., Shelf 1, 2, 3)
    `rack_number` VARCHAR(20),  -- These numbers are usually on the side of the shelf (e.g., Shelf 1, 2, 3)
    `floor_number` VARCHAR(10),  -- These numbers are usually on the side of the shelf (e.g., Shelf 1, 2, 3)
    `building` VARCHAR(100),  -- These numbers are usually on the side of the shelf (e.g., Shelf 1, 2, 3)
    `zone` VARCHAR(50),  -- These numbers are usually on the side of the shelf (e.g., Shelf 1, 2, 3)
    `description` VARCHAR(255),  -- These numbers are usually on the side of the shelf (e.g., Shelf 1, 2, 3)
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE KEY `uk_shelf_location` (`aisle_number`, `shelf_number`, `rack_number`),
    INDEX `idx_location_active` (`is_active`, `is_deleted`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- Aisle Number - An aisle is the open passage or walkway between rows of shelving units.
  -- shelf_number - A shelf is a flat, horizontal surface, typically made of wood or metal, used for storing or displaying items.
  -- rack_number - A rack is a framework, typically consisting of bars or hooks, used for storing or displaying items.
  -- floor_number - A floor is the lower surface of a room, on which one walks.
  -- zone - A zone is an area or stretch of land having a particular characteristic, purpose, or use, or subject to particular restrictions.
  -- description - A description is a spoken or written representation or account of a person, object, or event.
  -- Physical location mapping for books in the library, enabling efficient shelving and retrieval.

  -- Standardized condition states for physical books to track wear and tear, damage, and usability.
  CREATE TABLE IF NOT EXISTS `lib_book_conditions` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL UNIQUE,
    `name` VARCHAR(50) NOT NULL,
    `description` VARCHAR(255),
    `is_borrowable` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether books in this condition can be issued
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_condition_active` (`is_active`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

 -- ----------------------------------------------------------------------------
 -- 2. MASTER TABLES
 -- ----------------------------------------------------------------------------

  -- Master catalog of all books and resources owned by the library.
  CREATE TABLE IF NOT EXISTS `lib_books_master` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `title` VARCHAR(500) NOT NULL,
    `subtitle` VARCHAR(500),
    `edition` VARCHAR(50),                                              -- Edition of the book (e.g., 1st, 2nd, 3rd)
    `isbn` VARCHAR(20) UNIQUE,                                          -- International Standard Book Number - A unique identifier for books
    `issn` VARCHAR(20),                                                 -- International Standard Serial Number - A unique identifier for serials
    `doi` VARCHAR(100),                                                 -- Digital Object Identifier - A unique identifier for digital objects
    `publication_year` INT,                                             -- Year the book was published
    `publisher_id` INT,                                                 -- FK to lib_publishers
    `language` VARCHAR(50) DEFAULT 'English',                           -- FK to sys_dropdown_table (Map with Exisiting Dropdown table-name - bok_books coloumn_name - language)
    `page_count` INT CHECK (page_count > 0),                            -- Number of pages in the book
    `summary` TEXT,                                                     -- Summary of the book
    `table_of_contents` TEXT,                                           -- Table of contents of the book
    `cover_image_url` VARCHAR(500),                                     -- URL of the cover image
    `resource_type_id` INT NOT NULL,                                    -- FK to lib_resource_types
    `is_reference_only` TINYINT(1) NOT NULL DEFAULT 0,                  -- Whether book cannot be borrowed (in-library use only)
    -- Analytics
    `lexile_level` VARCHAR(20) NULL,                                    -- Reading difficulty level
    `reading_age_range` VARCHAR(20) NULL,                               -- e.g., 8-12 years
    `awards` TEXT NULL,                                                 -- List of awards won by book
    `series_name` VARCHAR(200) NULL,                                    -- Series name of the book
    `series_position` INT NULL,                                         -- Position of the book in the series
    `popularity_rank` INT NULL,                                         -- Popularity rank of the book
    `academic_rating` DECIMAL(3,2) NULL,                                -- Rating by faculty
    `student_rating` DECIMAL(3,2) NULL,                                 -- Average student rating
    `rating_count` INT DEFAULT 0,                                       -- Number of ratings
    `curricular_relevance_score` DECIMAL(5,2) NOT NULL DEFAULT 0.00,    -- Curricular relevance score
    `tags` JSON NULL,                                                   -- Auto-generated tags from AI analysis
    `ai_summary` TEXT NULL,                                             -- AI-generated summary
    `key_concepts` JSON NULL,                                           -- Key concepts extracted from book
    -- Audit
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`publisher_id`) REFERENCES `lib_publishers`(`publisher_id`),
    FOREIGN KEY (`resource_type_id`) REFERENCES `lib_resource_types`(`resource_type_id`),
    INDEX `idx_book_title` (`title`(191)),
    INDEX `idx_book_isbn` (`isbn`),
    INDEX `idx_book_year` (`publication_year`),
    INDEX `idx_book_active` (`is_active`),
    INDEX `idx_book_publisher` (`publisher_id`),
    FULLTEXT INDEX `ft_book_search` (`title`, `subtitle`, `summary`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_authors` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `short_name` VARCHAR(50) NOT NULL,
    `author_name` VARCHAR(200) NOT NULL,
    `country` VARCHAR(120),  -- FK to glb_countries
    `primary_genre_id` INT,  -- FK to lib_genres
    `notes` TEXT DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE KEY `uq_author_shortName` (`short_name`),
    UNIQUE KEY `uq_author_name` (`author_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

  -- Junction table to link books with their authors (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_author_jnt` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `book_id` INT NOT NULL,  -- FK to lib_books_master
    `author_id` INT NOT NULL,  -- FK to lib_authors
    `author_order` INT NOT NULL DEFAULT 1,
    `is_primary` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`author_id`) REFERENCES `lib_authors`(`id`) ON DELETE CASCADE, 
    UNIQUE KEY `uk_book_author` (`book_id`, `author_id`, `author_order`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their categories (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_category_jnt` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `book_id` INT NOT NULL,  -- FK to lib_books_master
    `category_id` INT NOT NULL,  -- FK to lib_categories
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`book_id`, `category_id`),
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`category_id`) REFERENCES `lib_categories`(`category_id`) ON DELETE CASCADE,
    INDEX `idx_category_book` (`category_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their genres (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_genre_jnt` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `book_id` INT NOT NULL,  -- FK to lib_books_master
    `genre_id` INT NOT NULL,  -- FK to lib_genres
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`book_id`, `genre_id`),
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`genre_id`) REFERENCES `lib_genres`(`genre_id`) ON DELETE CASCADE,
    INDEX `idx_genre_book` (`genre_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their subjects (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_subject_jnt` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `book_id` INT NOT NULL,  -- FK to lib_books_master.book_id
    `class_id` INT NOT NULL,  -- FK to sch_classes.id
    `subject_id` INT NOT NULL,  -- FK to sch_subjects.id
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_subject_book` (`class_id`, `subject_id`, `book_id`),
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`class_id`) ON DELETE CASCADE,
    FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects`(`subject_id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tags for literary genres that can be applied across categories for flexible searching and recommendations.
  CREATE TABLE IF NOT EXISTS `lib_keywords` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_keyword_active` (`is_active`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their keywords (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_keyword_jnt` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `book_id` INT NOT NULL,         -- FK to lib_books_master.book_id
    `keyword_id` INT NOT NULL,      -- FK to lib_keywords.keyword_id
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`book_id`, `keyword_id`),
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`keyword_id`) REFERENCES `lib_keywords`(`keyword_id`) ON DELETE CASCADE,
    INDEX `idx_keyword_book` (`keyword_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their conditions (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_condition_jnt` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `date` DATE NOT NULL,
    `book_id` INT NOT NULL,         -- FK to lib_books_master.book_id
    `condition_id` INT NOT NULL,    -- FK to lib_book_conditions.condition_id
    `note` VARCHAR(255),
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`book_id`, `condition_id`),
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`condition_id`) REFERENCES `lib_book_conditions`(`condition_id`) ON DELETE CASCADE,
    INDEX `idx_condition_book` (`condition_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

 -- ----------------------------------------------------------------------------
 -- RESOURCES MANAGEMENT
 -- ----------------------------------------------------------------------------

  -- Item-level tracking of each physical copy of a book, including location, condition, and circulation status.
  CREATE TABLE IF NOT EXISTS `lib_book_copies` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `book_id` INT NOT NULL,                 -- FK to lib_books_master.book_id
    `accession_number` VARCHAR(50) NOT NULL,
    `barcode` VARCHAR(100) NOT NULL,
    `rfid_tag` VARCHAR(100) NOT NULL,
    `shelf_location_id` INT NULL,           -- FK to lib_shelf_locations.shelf_location_id
    `current_condition_id` INT NOT NULL,    -- FK to lib_book_conditions.condition_id
    `purchase_date` DATE NOT NULL,
    `purchase_price` DECIMAL(10,2) NOT NULL DEFAULT 0,
    `vendor_id` INT NULL,                   -- FK to vnd_vendors.vendor_id
    `is_lost` TINYINT(1) NOT NULL DEFAULT 0,
    `is_damaged` TINYINT(1) NOT NULL DEFAULT 0,
    `is_withdrawn` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether copy is withdrawn from collection
    `withdrawal_reason` VARCHAR(512),
    `status` ENUM('available', 'issued', 'reserved', 'under_maintenance', 'lost', 'withdrawn') DEFAULT 'available',
    `notes` TEXT,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_copy_book` (`book_id`),
    INDEX `idx_copy_barcode` (`barcode`),
    INDEX `idx_copy_accession` (`accession_number`),
    INDEX `idx_copy_location` (`shelf_location_id`),
    INDEX `idx_copy_status` (`status`, `is_active`, `is_deleted`),
    INDEX `idx_copy_condition` (`current_condition_id`),
    UNIQUE KEY `unique_copy_barcode` (`barcode`),
    UNIQUE KEY `unique_copy_accession` (`accession_number`),
    UNIQUE KEY `unique_copy_rfid` (`rfid_tag`),
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`),
    FOREIGN KEY (`shelf_location_id`) REFERENCES `lib_shelf_locations`(`shelf_location_id`),
    FOREIGN KEY (`current_condition_id`) REFERENCES `lib_book_conditions`(`condition_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_digital_resources` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `book_id` INT NOT NULL,                 -- FK to lib_books_master.book_id
    `file_name` VARCHAR(255) NOT NULL,
    `file_media_id` INT UNSIGNED DEFAULT NULL,     -- FK to media_files.id
    `file_path` VARCHAR(500) NOT NULL,
    `file_size_bytes` BIGINT,
    `mime_type` VARCHAR(100),
    `file_format` VARCHAR(50),
    `download_count` INT DEFAULT 0,
    `view_count` INT DEFAULT 0,
    `license_key` VARCHAR(100),
    `license_type` VARCHAR(50),
    `license_start_date` DATE,
    `license_end_date` DATE,
    `access_restriction` JSON,  -- JSON defining access rules (user roles, IP ranges, etc.)
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`),
    FOREIGN KEY (`file_media_id`) REFERENCES `media_files`(id),
    INDEX `idx_digital_book` (`book_id`),
    INDEX `idx_digital_license` (`license_start_date`, `license_end_date`),
    INDEX `idx_digital_active` (`is_active`),
    FULLTEXT INDEX `ft_digital_search` (`file_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_digital_resource_tags` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `digital_resource_id` INT NOT NULL,
    `tag_name` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`digital_resource_id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_resource_tag` (`digital_resource_id`, `tag_name`),
    INDEX `idx_tag_name` (`tag_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_members` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `user_id` INT NOT NULL,
    `membership_type_id` INT NOT NULL,
    `membership_number` VARCHAR(50) NOT NULL,
    `library_card_barcode` VARCHAR(100),
    `registration_date` DATE NOT NULL,
    `expiry_date` DATE NOT NULL,
    `is_auto_renew` TINYINT(1) NOT NULL DEFAULT 1,
    `last_activity_date` DATE,
    `total_books_borrowed` INT DEFAULT 0,
    `total_fines_paid` DECIMAL(10,2) DEFAULT 0.00,
    `outstanding_fines` DECIMAL(10,2) DEFAULT 0.00 CHECK (outstanding_fines >= 0),
    `status` ENUM('active', 'expired', 'suspended', 'deactivated') DEFAULT 'active',
    `suspension_reason` TEXT,
    `notes` TEXT,
    -- analytics
    `reading_level` ENUM('Beginner', 'Intermediate', 'Advanced', 'Expert') NULL,
    `preferred_notification_channel` ENUM('Email', 'SMS', 'Push', 'InApp') DEFAULT 'Email',
    `member_segment` VARCHAR(50) COMMENT 'e.g., High-Value, At-Risk, Inactive, New',
    `last_segment_calculation` TIMESTAMP NULL,
    `engagement_score` DECIMAL(5,2) DEFAULT 0.00,
    `churn_risk_score` DECIMAL(5,2) DEFAULT 0.00,
    `lifetime_value` DECIMAL(10,2) DEFAULT 0.00,
    `preferred_language` VARCHAR(50) DEFAULT 'English',
    `reading_goal_annual` INT DEFAULT 0,
    `reading_progress_ytd` INT DEFAULT 0,
    -- system
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE KEY `uq_member_user` (`user_id`),
    UNIQUE KEY `uq_member_membership_number` (`membership_number`),
    UNIQUE KEY `uq_member_library_card_barcode` (`library_card_barcode`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(id),  -- Reference to main users table
    FOREIGN KEY (`membership_type_id`) REFERENCES `lib_membership_types`(membership_type_id),
    INDEX `idx_member_membership` (`membership_type_id`),
    INDEX `idx_member_status` (`status`, `expiry_date`),
    INDEX `idx_member_active` (`is_active`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

 -- ----------------------------------------------------------------------------
 -- OPERATION MANAGEMENT
 -- ----------------------------------------------------------------------------

  CREATE TABLE IF NOT EXISTS `lib_transactions` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
    `copy_id` INT NOT NULL,  -- fk to lib_book_copies.id
    `member_id` INT NOT NULL,  -- fk to lib_members.id
    `issue_date` DATETIME NOT NULL,
    `due_date` DATE NOT NULL,
    `return_date` DATETIME NULL,
    `issued_by_id` INT NOT NULL,  -- fk sys_user.id
    `received_by_id` INT NULL,  -- fk sys_user.id
    `issue_condition_id` INT NOT NULL,  -- fk lib_book_conditions.id
    `return_condition_id` INT NULL,  -- fk lib_book_conditions.id
    `is_renewed` TINYINT(1) NOT NULL DEFAULT 0,
    `renewal_count` INT DEFAULT 0,
    `status` ENUM('Issued', 'Returned', 'Overdue', 'Lost') DEFAULT 'Issued',
    `notes` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`copy_id`) REFERENCES `lib_book_copies`(`copy_id`),
    FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`member_id`),
    FOREIGN KEY (`issued_by_id`) REFERENCES `sys_users`(id),
    FOREIGN KEY (`received_by_id`) REFERENCES `sys_users`(id),
    FOREIGN KEY (`issue_condition_id`) REFERENCES `lib_book_conditions`(`condition_id`),
    FOREIGN KEY (`return_condition_id`) REFERENCES `lib_book_conditions`(`condition_id`),
    INDEX `idx_trans_copy` (`copy_id`, `status`),
    INDEX `idx_trans_member` (`member_id`, `status`),
    INDEX `idx_trans_dates` (`issue_date`, `due_date`, `return_date`),
    INDEX `idx_trans_status` (`status`, `due_date`),
    INDEX `idx_trans_issued_by` (`issued_by`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_reservations` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
    `book_id` INT NOT NULL,    -- fk to lib_books_master.id
    `member_id` INT NOT NULL,  -- fk to lib_members.id
    `reservation_date` DATETIME NOT NULL,
    `expected_available_date` DATE NOT NULL,
    `notification_sent` TINYINT(1) NOT NULL DEFAULT 0,
    `notification_sent_at` DATETIME NULL,
    `pickup_by_date` DATE NULL,
    `status` ENUM('Pending', 'Available', 'Picked_Up', 'Cancelled', 'Expired') DEFAULT 'Pending',
    `queue_position` INT NOT NULL DEFAULT 1,
    `cancellation_reason` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`),
    FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`member_id`),
    UNIQUE KEY `uk_active_reservation` (`book_id`, `member_id`, `status`),
    INDEX `idx_reserve_book` (`book_id`, `status`, `queue_position`),
    INDEX `idx_reserve_member` (`member_id`, `status`),
    INDEX `idx_reserve_status` (`status`, `pickup_by_date`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_fines` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `transaction_id` BIGINT NOT NULL,  -- fk to lib_transactions.id
    `member_id` INT NOT NULL,  -- fk to lib_members.id
    `fine_type` ENUM('Late Return', 'Lost Book', 'Damaged Book', 'Processing Fee') NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    `days_overdue` INT NOT NULL DEFAULT 0,
    `calculated_from` DATE NOT NULL,
    `calculated_to` DATE NOT NULL,
    `waived_amount` DECIMAL(10,2) DEFAULT 0.00 CHECK (waived_amount >= 0),
    `waived_by_id` INT NOT NULL,  -- fk sys_user.id
    `waived_reason` TEXT NOT NULL,
    `waived_at` DATETIME NOT NULL,
    `status` ENUM('Pending', 'Paid', 'Waived', 'Overdue') DEFAULT 'Pending',
    `notes` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`transaction_id`) REFERENCES `lib_transactions`(`transaction_id`),
    FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`member_id`),
    FOREIGN KEY (`waived_by_id`) REFERENCES `sys_users`(id),
    INDEX `idx_fine_transaction` (`transaction_id`),
    INDEX `idx_fine_member` (`member_id`, `status`),
    INDEX `idx_fine_status` (`status`, `created_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_fine_payments` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `fine_id` INT NOT NULL,  -- fk to lib_fines.id
    `amount_paid` DECIMAL(10,2) NOT NULL CHECK (amount_paid > 0),
    `payment_method` ENUM('Cash', 'Card', 'Online', 'Waiver') NOT NULL,
    `payment_reference` VARCHAR(100),
    `payment_date` DATETIME NOT NULL,
    `received_by_id` INT NOT NULL,  -- sys_user.id
    `receipt_number` VARCHAR(50) NOT NULL,
    `notes` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE KEY `uk_payment_receipt` (`receipt_number`),
    FOREIGN KEY (`fine_id`) REFERENCES `lib_fines`(`fine_id`),
    FOREIGN KEY (`received_by_id`) REFERENCES `users`(id),
    INDEX `idx_payment_fine` (`fine_id`),
    INDEX `idx_payment_receipt` (`receipt_number`),
    INDEX `idx_payment_date` (`payment_date`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_fine_slab_config` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL COMMENT 'e.g., Standard Student Fine Slab, Staff Fine Slab',
    `membership_type_id` INT NULL COMMENT 'If NULL, applies to all membership types',
    `resource_type_id` INT NULL COMMENT 'If NULL, applies to all resource types',
    `fine_type` ENUM('Late Return', 'Lost Book', 'Damaged Book', 'Processing Fee') DEFAULT 'Late Return',
    `max_fine_amount` DECIMAL(10,2) NULL COMMENT 'Maximum fine cap (could be book cost or school-defined limit)',
    `max_fine_type` ENUM('Fixed', 'BookCost', 'Unlimited') DEFAULT 'Unlimited',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `effective_from` DATE NOT NULL,
    `effective_to` DATE NULL,
    `priority` INT DEFAULT 0 COMMENT 'Higher priority slabs are evaluated first',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`membership_type_id`) REFERENCES `lib_membership_types`(`id`),
    FOREIGN KEY (`resource_type_id`) REFERENCES `lib_resource_types`(`id`),
    INDEX `idx_fine_slab_membership` (`membership_type_id`),
    INDEX `idx_fine_slab_active` (`is_active`, `effective_from`, `effective_to`),
    INDEX `idx_fine_slab_priority` (`priority`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

 -- ----------------------------------------------------------------------------
 -- 2. FINE SLAB DETAILS TABLE (for day ranges)
 -- ----------------------------------------------------------------------------

  CREATE TABLE IF NOT EXISTS `lib_fine_slab_details` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `fine_slab_config_id` INT NOT NULL,
    `from_day` INT NOT NULL CHECK (from_day >= 0),
    `to_day` INT NOT NULL CHECK (to_day >= from_day),
    `rate_per_day` DECIMAL(10,2) NOT NULL,
    `rate_type` ENUM('Fixed', 'Percentage') DEFAULT 'Fixed' COMMENT 'Fixed amount or percentage of book cost',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`fine_slab_config_id`) REFERENCES `lib_fine_slab_config`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_slab_days` (`fine_slab_config_id`, `from_day`, `to_day`),
    INDEX `idx_slab_day_range` (`from_day`, `to_day`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ----------------------------------------------------------------------------
  -- 3. ENHANCED LIB_FINES TABLE (modified)
  -- ----------------------------------------------------------------------------

  CREATE TABLE IF NOT EXISTS `lib_fines` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `transaction_id` BIGINT NOT NULL,
    `member_id` INT NOT NULL,
    `fine_type` ENUM('Late Return', 'Lost Book', 'Damaged Book', 'Processing Fee') NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    `days_overdue` INT NOT NULL DEFAULT 0,
    `calculated_from` DATE NOT NULL,
    `calculated_to` DATE NOT NULL,
    `fine_slab_config_id` INT NULL COMMENT 'Reference to slab used for calculation',
    `calculation_breakdown` JSON COMMENT 'Stores day-wise breakdown of fine calculation',
    `waived_amount` DECIMAL(10,2) DEFAULT 0.00 CHECK (waived_amount >= 0),
    `waived_by_id` INT NULL,
    `waived_reason` TEXT NULL,
    `waived_at` DATETIME NULL,
    `status` ENUM('Pending', 'Paid', 'Waived', 'Overdue') DEFAULT 'Pending',
    `notes` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`transaction_id`) REFERENCES `lib_transactions`(`id`),
    FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`id`),
    FOREIGN KEY (`waived_by_id`) REFERENCES `users`(id),
    FOREIGN KEY (`fine_slab_config_id`) REFERENCES `lib_fine_slab_config`(`id`),
    INDEX `idx_fine_transaction` (`transaction_id`),
    INDEX `idx_fine_member` (`member_id`, `status`),
    INDEX `idx_fine_status` (`status`, `created_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ----------------------------------------------------------------------------
  -- AUDIT AND HISTORY
  -- ----------------------------------------------------------------------------

  CREATE TABLE IF NOT EXISTS `lib_transaction_history` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `transaction_id` INT NOT NULL,  -- fk to lib_transactions.id
    `action_type` ENUM('issued', 'returned', 'renewed', 'marked_lost', 'condition_updated') NOT NULL,
    `old_value` JSON,
    `new_value` JSON,
    `performed_by_id` INT NOT NULL,  -- sys_user.id
    `performed_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `notes` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`transaction_id`) REFERENCES `lib_transactions`(`transaction_id`),
    FOREIGN KEY (`performed_by`) REFERENCES `users`(id),
    INDEX `idx_history_transaction` (`transaction_id`),
    INDEX `idx_history_performed` (`performed_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_inventory_audit` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `uuid` CHAR(36) NOT NULL UNIQUE,
    `audit_date` DATE NOT NULL,
    `performed_by_id` INT NOT NULL,  -- sys_user.id
    `total_scanned` INT DEFAULT 0,
    `total_expected` INT DEFAULT 0,
    `missing_copies` INT DEFAULT 0,
    `misplaced_copies` INT DEFAULT 0,
    `damaged_copies` INT DEFAULT 0,
    `status` ENUM('In Progress', 'Completed', 'Cancelled') DEFAULT 'In Progress',
    `completed_at` DATETIME NULL,
    `notes` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`performed_by`) REFERENCES `users`(id),
    INDEX `idx_audit_date` (`audit_date`),
    INDEX `idx_audit_status` (`status`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_inventory_audit_details` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
    `audit_id` BIGINT NOT NULL,
    `copy_id` INT NOT NULL,
    `expected_location_id` INT,
    `actual_location_id` INT,
    `scanned_at` DATETIME NOT NULL,
    `condition_id` INT,
    `status` ENUM('found', 'missing', 'misplaced', 'damaged') DEFAULT 'found',
    `notes` TEXT,
    FOREIGN KEY (`audit_id`) REFERENCES `lib_inventory_audit`(`audit_id`) ON DELETE CASCADE,
    FOREIGN KEY (`copy_id`) REFERENCES `lib_book_copies`(`copy_id`),
    FOREIGN KEY (`expected_location_id`) REFERENCES `lib_shelf_locations`(`shelf_location_id`),
    FOREIGN KEY (`actual_location_id`) REFERENCES `lib_shelf_locations`(`shelf_location_id`),
    FOREIGN KEY (`condition_id`) REFERENCES `lib_book_conditions`(`condition_id`),
    INDEX `idx_audit_details_audit` (`audit_id`),
    INDEX `idx_audit_details_copy` (`copy_id`),
    UNIQUE KEY `uk_audit_copy` (`audit_id`, `copy_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ----------------------------------------------------------------------------
  -- ADVANCED ANALYTICS & INSIGHTS
  -- ----------------------------------------------------------------------------
	-- Tracks individual member reading patterns, preferences, and behavior metrics for personalized recommendations and engagement analysis.
	CREATE TABLE IF NOT EXISTS `lib_reading_behavior_analytics` (
			`id` BIGINT PRIMARY KEY AUTO_INCREMENT,
			`member_id` INT NOT NULL,
			`academic_year` VARCHAR(20) NOT NULL,
			`total_books_read` INT DEFAULT 0,
			`total_pages_read` BIGINT DEFAULT 0,
			`avg_reading_days_per_book` DECIMAL(5,2),
			`preferred_genre_id` INT,
			`preferred_category_id` INT,
			`preferred_language` VARCHAR(50),
			`avg_loan_completion_rate` DECIMAL(5,2) COMMENT 'Percentage of books returned on time',
			`peak_borrowing_month` INT,
			`peak_borrowing_day` VARCHAR(20),
			`reading_consistency_score` DECIMAL(5,2) COMMENT '0-100 score based on borrowing regularity',
			`genre_diversity_index` DECIMAL(5,2) COMMENT 'Shannon diversity index for genres',
			`author_diversity_index` DECIMAL(5,2),
			`preferred_borrowing_time` ENUM('Morning', 'Afternoon', 'Evening', 'Weekend'),
			`digital_vs_physical_ratio` DECIMAL(5,2),
			`renewal_frequency` DECIMAL(5,2) COMMENT 'Average renewals per book',
			`reservation_frequency` INT DEFAULT 0,
			`reading_speed_estimate` DECIMAL(5,2) COMMENT 'Estimated pages per day',
			`completion_rate_trend` DECIMAL(5,2) COMMENT 'Month-over-month trend',
			`last_calculated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`member_id`),
			FOREIGN KEY (`preferred_genre_id`) REFERENCES `lib_genres`(`genre_id`),
			FOREIGN KEY (`preferred_category_id`) REFERENCES `lib_categories`(`category_id`),
			INDEX `idx_reading_behavior_member` (`member_id`, `academic_year`),
			INDEX `idx_reading_behavior_genre` (`preferred_genre_id`),
			INDEX `idx_reading_behavior_score` (`reading_consistency_score`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	--Tracks real-time and historical popularity metrics for books to optimize acquisition and shelving decisions.
	CREATE TABLE IF NOT EXISTS `lib_book_popularity_trends` (
			`id` BIGINT PRIMARY KEY AUTO_INCREMENT,
			`book_id` INT NOT NULL,
			`tracking_date` DATE NOT NULL,
			`daily_requests` INT DEFAULT 0,
			`daily_issues` INT DEFAULT 0,
			`daily_reservations` INT DEFAULT 0,
			`daily_digital_views` INT DEFAULT 0,
			`daily_digital_downloads` INT DEFAULT 0,
			`popularity_score` DECIMAL(5,2) COMMENT 'Weighted composite score',
			`trend_direction` ENUM('Rising', 'Falling', 'Stable') DEFAULT 'Stable',
			`velocity_score` DECIMAL(5,2) COMMENT 'Rate of popularity change',
			`seasonality_factor` DECIMAL(5,2) COMMENT 'Seasonal adjustment factor',
			`peer_comparison_rank` INT COMMENT 'Rank among similar books',
			`shelf_turnover_rate` DECIMAL(5,2) COMMENT 'How often book moves from shelf',
			`waitlist_length` INT DEFAULT 0,
			`avg_wait_days` DECIMAL(5,2),
			`recommendation_weight` DECIMAL(5,2) COMMENT 'Weight for recommendation engine',
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`),
			UNIQUE KEY `uk_book_daily_trend` (`book_id`, `tracking_date`),
			INDEX `idx_popularity_date` (`tracking_date`),
			INDEX `idx_popularity_score` (`popularity_score`),
			INDEX `idx_popularity_trend` (`trend_direction`, `velocity_score`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- Provides comprehensive metrics on the health, diversity, and utilization of the library collection.
	CREATE TABLE IF NOT EXISTS `lib_collection_health_metrics` (
			`id` BIGINT PRIMARY KEY AUTO_INCREMENT,
			`metric_date` DATE NOT NULL,
			`category_id` INT,
			`genre_id` INT,
			`total_titles` INT DEFAULT 0,
			`total_copies` INT DEFAULT 0,
			`active_titles` INT DEFAULT 0,
			`inactive_titles` INT DEFAULT 0,
			`damaged_copies` INT DEFAULT 0,
			`lost_copies` INT DEFAULT 0,
			`withdrawn_copies` INT DEFAULT 0,
			`utilization_rate` DECIMAL(5,2) COMMENT 'Percentage of collection in circulation',
			`turnover_rate` DECIMAL(5,2) COMMENT 'Average issues per copy',
			`age_of_collection` DECIMAL(5,2) COMMENT 'Average age in years',
			`collection_diversity_score` DECIMAL(5,2) COMMENT 'Based on genre/category distribution',
			`relevance_score` DECIMAL(5,2) COMMENT 'How well collection matches demand',
			`acquisition_effectiveness` DECIMAL(5,2) COMMENT 'ROI on new acquisitions',
			`weeding_priority_score` DECIMAL(5,2) COMMENT 'Priority for removal/replacement',
			`budget_allocation_efficiency` DECIMAL(5,2),
			`digital_penetration_rate` DECIMAL(5,2),
			`physical_vs_digital_ratio` DECIMAL(5,2),
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			INDEX `idx_health_date` (`metric_date`),
			INDEX `idx_health_category` (`category_id`),
			INDEX `idx_health_genre` (`genre_id`),
			INDEX `idx_health_utilization` (`utilization_rate`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- Stores predictive model outputs for demand forecasting, member churn prediction, and resource optimization.
	CREATE TABLE IF NOT EXISTS `lib_predictive_analytics` (
			`id` BIGINT PRIMARY KEY AUTO_INCREMENT,
			`prediction_date` DATE NOT NULL,
			`prediction_type` ENUM(
					'Demand_Forecast', 
					'Member_Churn', 
					'Resource_Optimization', 
					'Acquisition_Recommendation',
					'Seasonal_Pattern',
					'Budget_Projection'
			) NOT NULL,
			`target_entity_type` ENUM('Book', 'Category', 'Genre', 'Member', 'Department', 'All') NOT NULL,
			`target_entity_id` INT,
			`prediction_period_start` DATE NOT NULL,
			`prediction_period_end` DATE NOT NULL,
			`predicted_value` DECIMAL(10,2) NOT NULL,
			`confidence_score` DECIMAL(5,2) COMMENT '0-100 confidence level',
			`actual_value` DECIMAL(10,2),
			`accuracy_score` DECIMAL(5,2),
			`model_version` VARCHAR(50),
			`features_used` JSON COMMENT 'Features used in prediction',
			`insights` TEXT,
			`recommendations` TEXT,
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			INDEX `idx_predictive_type` (`prediction_type`, `prediction_date`),
			INDEX `idx_predictive_entity` (`target_entity_type`, `target_entity_id`),
			INDEX `idx_predictive_period` (`prediction_period_start`, `prediction_period_end`),
			INDEX `idx_predictive_confidence` (`confidence_score`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- Tracks how well library resources align with curriculum requirements and academic schedules.
	CREATE TABLE IF NOT EXISTS `lib_curricular_alignment` (
			`id` BIGINT PRIMARY KEY AUTO_INCREMENT,
			`academic_year` VARCHAR(20) NOT NULL,
			`class_id` INT NOT NULL,
			`subject_id` INT NOT NULL,
			`book_id` INT NOT NULL,
			`alignment_score` DECIMAL(5,2) COMMENT 'How well book aligns with curriculum',
			`recommended_by_faculty` TINYINT(1) DEFAULT 0,
			`faculty_rating` DECIMAL(3,2) COMMENT '1-5 rating from faculty',
			`student_usage_count` INT DEFAULT 0,
			`exam_reference_count` INT DEFAULT 0 COMMENT 'Times referenced in exams',
			`assignment_citations` INT DEFAULT 0,
			`curriculum_unit` VARCHAR(200),
			`term_recommended` ENUM('Term1', 'Term2', 'Term3', 'All'),
			`priority_level` ENUM('Essential', 'Recommended', 'Supplementary', 'Optional') DEFAULT 'Supplementary',
			`notes` TEXT,
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`class_id`),
			FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects`(`subject_id`),
			FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`),
			UNIQUE KEY `uk_curricular_book` (`academic_year`, `class_id`, `subject_id`, `book_id`),
			INDEX `idx_curricular_alignment` (`alignment_score`),
			INDEX `idx_curricular_priority` (`priority_level`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- Tracks granular user interactions with the library system for detailed behavior analysis.
	CREATE TABLE IF NOT EXISTS `lib_engagement_events` (
			`id` BIGINT PRIMARY KEY AUTO_INCREMENT,
			`member_id` INT NOT NULL,
			`event_type` ENUM('Search','Browse','View_Details','Add_Reservation','Cancel_Reservation','Renew_Online','Digital_View','Digital_Download','Read_Online','Share_Resource','Add_Review','Rate_Book','Save_To_Wishlist','Request_Purchase','Ask_Librarian','Attend_Event') NOT NULL,
			`book_id` INT,
			`digital_resource_id` INT,
			`search_query` VARCHAR(500),
			`filters_used` JSON,
			`session_id` VARCHAR(100),
			`device_type` ENUM('Desktop', 'Mobile', 'Tablet', 'Kiosk'),
			`browser` VARCHAR(50),
			`ip_address` VARCHAR(45),
			`location_id` INT COMMENT 'Physical location if in library',
			`time_spent_seconds` INT,
			`interaction_outcome` VARCHAR(255),
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`member_id`),
			FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`),
			FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`digital_resource_id`),
			INDEX `idx_engagement_member` (`member_id`, `created_at`),
			INDEX `idx_engagement_type` (`event_type`, `created_at`),
			INDEX `idx_engagement_book` (`book_id`),
			INDEX `idx_engagement_session` (`session_id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ----------------------------------------------------------------------------
  -- 11. INDEX PERFORMANCE OPTIMIZATION
  -- ----------------------------------------------------------------------------

	-- Additional indexes for complex queries
	CREATE INDEX idx_transactions_overdue ON lib_transactions(status, due_date) WHERE status = 'issued';
	CREATE INDEX idx_members_outstanding ON lib_members(outstanding_fines) WHERE outstanding_fines > 0;
	CREATE INDEX idx_fines_pending ON lib_fines(status, created_at) WHERE status = 'pending';
	CREATE INDEX idx_reservations_available ON lib_reservations(status, expected_available_date, notification_sent) WHERE status = 'pending';
	CREATE INDEX idx_digital_license_expiry ON lib_digital_resources(license_end_date) WHERE license_end_date IS NOT NULL;

	-- Composite indexes for reporting
	CREATE INDEX idx_books_publisher_year ON lib_books_master(publisher_id, publication_year);
	CREATE INDEX idx_copies_location_status ON lib_book_copies(shelf_location_id, status);
	CREATE INDEX idx_transactions_member_dates ON lib_transactions(member_id, issue_date, return_date);

  -- ----------------------------------------------------------------------------
  -- 12. TRIGGERS FOR DATA INTEGRITY
  -- ----------------------------------------------------------------------------

	DELIMITER $$

	-- Trigger to update member's total borrowed count
	CREATE TRIGGER update_member_borrowed_count 
	AFTER INSERT ON lib_transactions
	FOR EACH ROW
	BEGIN
			IF NEW.status = 'issued' THEN
					UPDATE lib_members 
					SET total_books_borrowed = total_books_borrowed + 1,
							last_activity_date = CURDATE()
					WHERE member_id = NEW.member_id;
			END IF;
	END$$

	-- Trigger to update book copy status on transaction
	CREATE TRIGGER update_copy_status_on_issue
	AFTER INSERT ON lib_transactions
	FOR EACH ROW
	BEGIN
			IF NEW.status = 'issued' THEN
					UPDATE lib_book_copies 
					SET status = 'issued'
					WHERE copy_id = NEW.copy_id;
			END IF;
	END$$

	CREATE TRIGGER update_copy_status_on_return
	AFTER UPDATE ON lib_transactions
	FOR EACH ROW
	BEGIN
			IF NEW.status = 'returned' AND OLD.status != 'returned' THEN
					UPDATE lib_book_copies 
					SET status = 'available',
							current_condition_id = NEW.return_condition_id
					WHERE copy_id = NEW.copy_id;
			END IF;
	END$$

	-- Trigger to automatically calculate fines on overdue items
	CREATE EVENT auto_calculate_fines
	ON SCHEDULE EVERY 1 DAY
	STARTS CURRENT_DATE
	DO
	BEGIN
			INSERT INTO lib_fines (transaction_id, member_id, fine_type, amount, days_overdue, calculated_from, calculated_to, status)
			SELECT 
					t.transaction_id,
					t.member_id,
					'late_return',
					DATEDIFF(CURDATE(), t.due_date) * mt.fine_rate_per_day,
					DATEDIFF(CURDATE(), t.due_date),
					t.due_date,
					CURDATE(),
					'pending'
			FROM lib_transactions t
			INNER JOIN lib_members m ON t.member_id = m.member_id
			INNER JOIN lib_membership_types mt ON m.membership_type_id = mt.membership_type_id
			WHERE t.status = 'issued' 
					AND t.due_date < CURDATE()
					AND DATEDIFF(CURDATE(), t.due_date) > mt.grace_period_days
					AND NOT EXISTS (
							SELECT 1 FROM lib_fines f 
							WHERE f.transaction_id = t.transaction_id 
							AND f.fine_type = 'late_return'
							AND f.status = 'pending'
					);
	END$$

	DELIMITER ;



  -- ----------------------------------------------------------------------------
  -- 13. VIEWS FOR COMMON REPORTING
  -- ----------------------------------------------------------------------------

	-- Comprehensive 360-degree view of member engagement and behavior.
	CREATE OR REPLACE VIEW `lib_view_member_360` AS
	SELECT 
			m.member_id,
			m.membership_number,
			u.first_name,
			u.last_name,
			u.email,
			u.phone,
			mt.name as membership_type,
			m.registration_date,
			m.expiry_date,
			m.status,
			m.total_books_borrowed,
			m.outstanding_fines,
			m.engagement_score,
			m.churn_risk_score,
			m.lifetime_value,
			m.reading_level,
			rba.total_pages_read,
			rba.avg_reading_days_per_book,
			rba.reading_consistency_score,
			rba.genre_diversity_index,
			g.name as preferred_genre,
			rba.preferred_borrowing_time,
			rba.digital_vs_physical_ratio,
			(
					SELECT COUNT(*) 
					FROM lib_reservations r 
					WHERE r.member_id = m.member_id 
					AND r.status = 'Pending'
			) as active_reservations,
			(
					SELECT COUNT(*) 
					FROM lib_transactions t 
					WHERE t.member_id = m.member_id 
					AND t.status = 'Issued'
			) as currently_borrowed,
			DATEDIFF(CURDATE(), m.last_activity_date) as days_since_last_activity,
			CASE 
					WHEN m.last_activity_date IS NULL THEN 'New'
					WHEN DATEDIFF(CURDATE(), m.last_activity_date) <= 30 THEN 'Active'
					WHEN DATEDIFF(CURDATE(), m.last_activity_date) <= 90 THEN 'At Risk'
					ELSE 'Inactive'
			END as activity_status
	FROM lib_members m
	INNER JOIN users u ON m.user_id = u.id
	INNER JOIN lib_membership_types mt ON m.membership_type_id = mt.id
	LEFT JOIN lib_reading_behavior_analytics rba ON m.member_id = rba.member_id AND rba.academic_year = YEAR(CURDATE())
	LEFT JOIN lib_genres g ON rba.preferred_genre_id = g.id;


	-- Real-time performance metrics for collection management.
	CREATE OR REPLACE VIEW `lib_view_collection_performance` AS
	SELECT 
			b.book_id,
			b.title,
			b.isbn,
			p.name as publisher,
			rt.name as resource_type,
			COUNT(DISTINCT c.copy_id) as total_copies,
			SUM(CASE WHEN c.status = 'available' THEN 1 ELSE 0 END) as available_copies,
			SUM(CASE WHEN c.status = 'issued' THEN 1 ELSE 0 END) as issued_copies,
			SUM(CASE WHEN c.status = 'reserved' THEN 1 ELSE 0 END) as reserved_copies,
			SUM(CASE WHEN c.is_lost = 1 THEN 1 ELSE 0 END) as lost_copies,
			SUM(CASE WHEN c.is_damaged = 1 THEN 1 ELSE 0 END) as damaged_copies,
			COUNT(DISTINCT t.transaction_id) as total_issues,
			COUNT(DISTINCT CASE WHEN t.return_date IS NULL AND t.due_date < CURDATE() THEN t.transaction_id END) as overdue_count,
			AVG(CASE WHEN t.return_date IS NOT NULL THEN DATEDIFF(t.return_date, t.issue_date) END) as avg_loan_days,
			COUNT(DISTINCT r.reservation_id) as active_reservations,
			AVG(r.queue_position) as avg_queue_position,
			b.popularity_rank,
			b.curricular_relevance_score,
			b.student_rating,
			pt.popularity_score,
			pt.trend_direction,
			chm.utilization_rate as collection_utilization_rate,
			CASE 
					WHEN COUNT(DISTINCT t.transaction_id) > 100 THEN 'High Demand'
					WHEN COUNT(DISTINCT t.transaction_id) > 50 THEN 'Medium Demand'
					WHEN COUNT(DISTINCT t.transaction_id) > 10 THEN 'Low Demand'
					ELSE 'Very Low Demand'
			END as demand_category
	FROM lib_books_master b
	LEFT JOIN lib_publishers p ON b.publisher_id = p.id
	LEFT JOIN lib_resource_types rt ON b.resource_type_id = rt.id
	LEFT JOIN lib_book_copies c ON b.book_id = c.book_id
	LEFT JOIN lib_transactions t ON c.copy_id = t.copy_id
	LEFT JOIN lib_reservations r ON b.book_id = r.book_id AND r.status = 'Pending'
	LEFT JOIN lib_book_popularity_trends pt ON b.book_id = pt.book_id AND pt.tracking_date = CURDATE()
	LEFT JOIN lib_collection_health_metrics chm ON chm.metric_date = CURDATE()
	GROUP BY b.book_id, b.title, b.isbn, p.name, rt.name, b.popularity_rank, 
					b.curricular_relevance_score, b.student_rating, pt.popularity_score, pt.trend_direction;


	-- Predictive demand forecasting for inventory planning.
    CREATE OR REPLACE VIEW `lib_view_predictive_demand` AS
    SELECT b.book_id, b.title, c.name as category_name, g.name as genre_name, b.publication_year,
        (
            SELECT COUNT(*) 
            FROM lib_transactions t 
            INNER JOIN lib_book_copies cp ON t.copy_id = cp.copy_id
            WHERE cp.book_id = b.book_id 
            AND t.issue_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
        ) as last_3_months_issues,
        (
            SELECT COUNT(*) 
            FROM lib_transactions t 
            INNER JOIN lib_book_copies cp ON t.copy_id = cp.copy_id
            WHERE cp.book_id = b.book_id 
            AND t.issue_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
        ) as last_year_issues,
        pa.predicted_value as predicted_next_3_months, pa.confidence_score, pa.insights, pa.recommendations, ca.alignment_score as curricular_relevance,
        CASE 
            WHEN pa.predicted_value > 50 THEN 'Acquire More Copies'
            WHEN pa.predicted_value > 30 THEN 'Monitor Demand'
            WHEN pa.predicted_value > 10 THEN 'Maintain Current'
            ELSE 'Consider Weeding'
        END as acquisition_recommendation
    FROM lib_books_master b
    LEFT JOIN lib_book_category_jnt bc ON b.book_id = bc.book_id
    LEFT JOIN lib_categories c ON bc.category_id = c.id
    LEFT JOIN lib_book_genre_jnt bg ON b.book_id = bg.book_id
    LEFT JOIN lib_genres g ON bg.genre_id = g.id
    LEFT JOIN lib_predictive_analytics pa ON b.book_id = pa.target_entity_id AND pa.prediction_type = 'Demand_Forecast' AND pa.prediction_date = CURDATE()
    LEFT JOIN lib_curricular_alignment ca ON b.book_id = ca.book_id AND ca.academic_year = YEAR(CURDATE())
    WHERE pa.predicted_value IS NOT NULL
    GROUP BY b.book_id, b.title, c.name, g.name, b.publication_year, pa.predicted_value, pa.confidence_score, pa.insights, pa.recommendations, ca.alignment_score;



  CREATE VIEW lib_view_overdue_books AS
  SELECT 
      t.transaction_id, b.title, b.isbn, c.barcode, m.membership_number, u.first_name, u.last_name, u.email, u.phone, t.due_date, DATEDIFF(CURDATE(), t.due_date) as days_overdue, 
      mt.fine_rate_per_day, DATEDIFF(CURDATE(), t.due_date) * mt.fine_rate_per_day as estimated_fine
  FROM lib_transactions t
  INNER JOIN lib_book_copies c ON t.copy_id = c.copy_id
  INNER JOIN lib_books_master b ON c.book_id = b.book_id
  INNER JOIN lib_members m ON t.member_id = m.member_id
  INNER JOIN users u ON m.user_id = u.id
  INNER JOIN lib_membership_types mt ON m.membership_type_id = mt.membership_type_id
  WHERE t.status = 'issued' AND t.due_date < CURDATE() AND DATEDIFF(CURDATE(), t.due_date) > mt.grace_period_days;
  CREATE VIEW lib_view_most_issued_books AS
  SELECT 
      b.book_id, b.title, COUNT(t.transaction_id) as issue_count, COUNT(DISTINCT t.member_id) as unique_borrowers,
      AVG(CASE WHEN t.return_date IS NOT NULL THEN DATEDIFF(t.return_date, t.issue_date) END) as avg_loan_days
  FROM lib_books_master b
  LEFT JOIN lib_book_copies c ON b.book_id = c.book_id
  LEFT JOIN lib_transactions t ON c.copy_id = t.copy_id
  WHERE t.status = 'returned'
  GROUP BY b.book_id, b.title
  ORDER BY issue_count DESC;


  -- ----------------------------------------------------------------------------
  -- 10. SEED DATA (Lookup Tables)
  -- ----------------------------------------------------------------------------

  -- Membership Types
  INSERT INTO lib_membership_types (membership_type_code, membership_type_name, max_books_allowed, loan_period_days, fine_rate_per_day, grace_period_days, priority_level) VALUES
  ('STD_STUDENT', 'Standard Student', 5, 14, 5.00, 2, 1),
  ('STD_STAFF', 'Standard Staff', 10, 30, 2.00, 5, 3),
  ('RESEARCH_SCHOLAR', 'Research Scholar', 15, 45, 2.00, 7, 4),
  ('PREMIUM_STUDENT', 'Premium Student', 10, 21, 3.00, 3, 2),
  ('EXTERNAL', 'External Member', 3, 14, 10.00, 0, 0);

  -- Categories
  INSERT INTO lib_categories (category_code, category_name, category_level) VALUES
  ('FIC', 'Fiction', 1),
  ('NFIC', 'Non-Fiction', 1),
  ('SCI', 'Science', 2),
  ('MATH', 'Mathematics', 2),
  ('CS', 'Computer Science', 2),
  ('LIT', 'Literature', 2),
  ('HIST', 'History', 2),
  ('GEO', 'Geography', 2),
  ('ART', 'Art', 2);

  -- Genres
  INSERT INTO lib_genres (genre_code, genre_name) VALUES
  ('SF', 'Science Fiction'),
  ('FAN', 'Fantasy'),
  ('MYS', 'Mystery'),
  ('BIO', 'Biography'),
  ('TECH', 'Technology'),
  ('EDU', 'Educational'),
  ('REF', 'Reference'),
  ('CLS', 'Classics'),
  ('POE', 'Poetry');

  -- Resource Types
  INSERT INTO lib_resource_types (resource_type_code, resource_type_name, is_physical, is_digital) VALUES
  ('PHY_BOOK', 'Physical Book', TRUE, FALSE),
  ('EBOOK', 'E-Book', FALSE, TRUE),
  ('PDF', 'PDF Document', FALSE, TRUE),
  ('AUDIO', 'Audio Book', FALSE, TRUE),
  ('VIDEO', 'Video Resource', FALSE, TRUE),
  ('JOURNAL', 'Journal', TRUE, TRUE),
  ('MAGAZINE', 'Magazine', TRUE, FALSE);

  -- Book Conditions
  INSERT INTO lib_book_conditions (condition_code, condition_name, description, is_borrowable) VALUES
  ('NEW', 'New', 'Brand new condition, never issued', TRUE),
  ('EXC', 'Excellent', 'Like new, no signs of wear', TRUE),
  ('GOOD', 'Good', 'Normal wear and tear, fully readable', TRUE),
  ('FAIR', 'Fair', 'Significant wear but all pages intact', TRUE),
  ('POOR', 'Poor', 'Damaged, may have missing pages', FALSE),
  ('DAMAGED', 'Damaged', 'Needs repair before circulation', FALSE),
  ('LOST', 'Lost', 'Reported lost by member', FALSE),
  ('WITHDRAWN', 'Withdrawn', 'Removed from collection', FALSE);

  -- Shelf Locations
  INSERT INTO lib_shelf_locations (location_code, aisle_number, shelf_number, rack_number, floor_number, building) VALUES
  ('A1-S1-R1', 'A1', 'S1', 'R1', '1', 'Main Library'),
  ('A1-S1-R2', 'A1', 'S1', 'R2', '1', 'Main Library'),
  ('A1-S2-R1', 'A1', 'S2', 'R1', '1', 'Main Library'),
  ('B2-S1-R1', 'B2', 'S1', 'R1', '2', 'Science Block'),
  ('REF-A1', 'REF', 'A1', NULL, '1', 'Reference Section');

  -- --------------------------------------------------------------------------------------------------------------------------
  -- Dropdown Table Entry

  -- use existing Dropdown table of table-name - bok_books coloumn_name - language


-- ===========================================================================
-- 19-STUDENT FEES (fee)
-- ===========================================================================
  -- ----------------------------------------------------------------
  -- Table 1: fee_head_master
  -- Purpose: Core fee components (Tuition, Transport, Hostel, etc.)
  -- ----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_head_master` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(30) NOT NULL,                        -- Unique code (TUIT, TRAN, HOST, LIB, SPRT, EXAM, ACTV, LAB, DEV, OTH)
    `name` VARCHAR(100) NOT NULL,                       -- Display name (Tuition, Transport, Hostel, etc.)
    `description` VARCHAR(255) NULL,
    `head_type_id` INT UNSIGNED NOT NULL,               -- FK to sys_dropdown_table (fee_head_master.head_type_id)
    `frequency` ENUM('One-time', 'Monthly', 'Quarterly', 'Half-Yearly', 'Yearly') NOT NULL DEFAULT 'Monthly',
    `is_refundable` TINYINT(1) NOT NULL DEFAULT 0,
    `tax_applicable` TINYINT(1) NOT NULL DEFAULT 0,
    `tax_percentage` DECIMAL(5,2) DEFAULT 0.00,
    `account_head_code` VARCHAR(50) NULL COMMENT 'ERP Accounting Integration',
    `display_order` INT NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE INDEX `uq_fee_head_code` (`code`),
    INDEX `idx_fee_head_type` (`head_type_id`),
    INDEX `idx_fee_head_active` (`is_active`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 2: fee_group_master
	-- Purpose: Logical grouping of fee heads (e.g., "Academic Package")
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_group_master` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `is_mandatory` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Student must take this group',
    `display_order` INT NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_fee_group_active` (`is_active`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 3: fee_group_heads_jnt
	-- Purpose: Maps fee heads to groups with optional/mandatory flag per head
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_group_heads_jnt` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `group_id` INT UNSIGNED NOT NULL,
    `head_id` INT UNSIGNED NOT NULL,
    `is_optional` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Student can opt out',
    `default_amount` DECIMAL(10,2) NULL COMMENT 'Default amount if fixed',
    `display_order` INT NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX `uq_fee_group_head` (`group_id`, `head_id`),
    CONSTRAINT `fk_fgh_group` FOREIGN KEY (`group_id`) REFERENCES `fee_group_master` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_fgh_head` FOREIGN KEY (`head_id`) REFERENCES `fee_head_master` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 4: fee_structure_master
	-- Purpose: Defines fee structure for class + academic session + category
	-- [BUG-FIX] academic_session_id changed from INT to SMALLINT UNSIGNED
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_structure_master` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `academic_session_id` SMALLINT UNSIGNED NOT NULL COMMENT 'FK to sch_org_academic_sessions_jnt',
    `class_id` INT UNSIGNED NOT NULL COMMENT 'FK to sch_classes',
    `student_category_id` INT UNSIGNED NULL COMMENT 'FK to sys_dropdown_table (General/OBC/SC/ST)',
    `board_type` VARCHAR(50) NULL COMMENT 'CBSE/ICSE/State',
    `code` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Unique code for the fee structure',
    `name` VARCHAR(100) NOT NULL COMMENT 'Name of the fee structure',
    `effective_from` DATE NOT NULL,
    `effective_to` DATE NULL,
    `total_fee_amount` DECIMAL(12,2) NULL COMMENT 'Pre-calculated sum',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_fee_structure_session_class` (`academic_session_id`, `class_id`),
    INDEX `idx_fee_structure_active` (`is_active`),
    CONSTRAINT `fk_fs_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fs_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fs_category` FOREIGN KEY (`student_category_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 5: fee_structure_details
	-- Purpose: Line items of fee structure (head-wise amounts)
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_structure_details` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `fee_structure_id` INT UNSIGNED NOT NULL,
    `head_id` INT UNSIGNED NOT NULL,
    `group_id` INT UNSIGNED NULL COMMENT 'NULL if direct head assignment',
    `amount` DECIMAL(10,2) NOT NULL,
    `is_optional` TINYINT(1) NOT NULL DEFAULT 1,
    `tax_included` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX `uq_fee_structure_head` (`fee_structure_id`, `head_id`),
    CONSTRAINT `fk_fsd_structure` FOREIGN KEY (`fee_structure_id`) REFERENCES `fee_structure_master` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_fsd_head` FOREIGN KEY (`head_id`) REFERENCES `fee_head_master` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fsd_group` FOREIGN KEY (`group_id`) REFERENCES `fee_group_master` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 6: fee_installments
	-- Purpose: Defines installment schedules for fee structures
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_installments` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `fee_structure_id` INT UNSIGNED NOT NULL,
    `installment_no` INT NOT NULL,
    `installment_name` VARCHAR(100) NOT NULL,
    `due_date` DATE NOT NULL,
    `percentage_due` DECIMAL(5,2) NOT NULL COMMENT 'Percentage of total fee',
    `amount_due` DECIMAL(10,2) NULL COMMENT 'Calculated amount',
    `grace_days` INT NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX `uq_fee_installment_structure_no` (`fee_structure_id`, `installment_no`),
    CONSTRAINT `fk_fi_structure` FOREIGN KEY (`fee_structure_id`) REFERENCES `fee_structure_master` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 7: fee_fine_rules
	-- Purpose: Defines late payment fine rules (tiered structure)
	-- [ENHANCE] Added fine_calculation_mode (PerDay vs FlatPerTier)
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_fine_rules` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `rule_name` VARCHAR(100) NOT NULL,
    `applicable_on` ENUM('Fee Structure', 'Installment', 'Head') NOT NULL DEFAULT 'Installment',
    `applicable_id` INT UNSIGNED NOT NULL COMMENT 'ID based on applicable_on',
    `fine_type` ENUM('Percentage', 'Fixed', 'Percentage+Capped') NOT NULL,
    `fine_value` DECIMAL(10,2) NOT NULL,
    `fine_calculation_mode` ENUM('PerDay', 'FlatPerTier') NOT NULL DEFAULT 'PerDay' COMMENT 'PerDay: fine_value x days. FlatPerTier: fine_value once for the tier',
    `max_fine_amount` DECIMAL(10,2) NULL COMMENT 'For Percentage+Capped',
    `grace_period_days` INT NOT NULL DEFAULT 0,
    `recurring` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Apply fine every day/week',
    `recurring_interval_days` INT NULL,
    `max_fine_installments` INT NULL COMMENT 'Max times fine can be applied',
    `applicable_from_day` INT NOT NULL DEFAULT 1,
    `applicable_to_day` INT NULL,
    `action_on_expiry` ENUM('None', 'Mark Defaulter', 'Remove Name', 'Suspend') NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_fine_applicable` (`applicable_on`, `applicable_id`),
    INDEX `idx_fine_active` (`is_active`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 8: fee_concession_types
	-- Purpose: Types of concessions/discounts
	-- [ENHANCE] Renamed concession_code->code, concession_name->name
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_concession_types` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `concession_category_id` INT UNSIGNED NOT NULL COMMENT 'FK to sys_dropdown_table (Sibling, Merit, Staff, Financial Aid, Sports, Alumni, Other)',
    `discount_type` ENUM('Percentage', 'Fixed Amount') NOT NULL,
    `discount_value` DECIMAL(10,2) NOT NULL,
    `applicable_on` ENUM('Total Fee', 'Specific Heads', 'Specific Groups') NOT NULL,
    `max_cap_amount` DECIMAL(10,2) NULL,
    `requires_approval` TINYINT(1) NOT NULL DEFAULT 1,
    `approval_level_role_id` INT NULL COMMENT 'FK to sys_roles (e.g. ClassTeacher, Principal, Management)',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_concession_category` (`concession_category_id`),
    CONSTRAINT `fk_concession_category` FOREIGN KEY (`concession_category_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE RESTRICT
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 9: fee_concession_applicable_heads
	-- Purpose: Maps concessions to specific heads or groups (mutually exclusive per row)
	-- [ENHANCE] Added 'group_id' to support group-level concessions
	-- [ENHANCE] Added CHECK constraint 'chk_cah_head_or_group' to ensure only one of head_id or group_id is set for each record
	-- [BUG-FIX] Changed head_id and group_id from NOT NULL to NULL (CHECK requires one NULL)
	-- [ENHANCE] Added uq_concession_group unique index for group path
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_concession_applicable_heads` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `concession_type_id` INT UNSIGNED NOT NULL,
    `head_id` INT UNSIGNED NULL COMMENT 'FK to fee_head_master (when applicable_on = Specific Heads)',
    `group_id` INT UNSIGNED NULL COMMENT 'FK to fee_group_master (when applicable_on = Specific Groups)',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE INDEX `uq_concession_head` (`concession_type_id`, `head_id`),
    UNIQUE INDEX `uq_concession_group` (`concession_type_id`, `group_id`),
    CONSTRAINT `fk_cah_concession` FOREIGN KEY (`concession_type_id`) REFERENCES `fee_concession_types` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cah_head` FOREIGN KEY (`head_id`) REFERENCES `fee_head_master` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cah_group` FOREIGN KEY (`group_id`) REFERENCES `fee_group_master` (`id`) ON DELETE CASCADE,
    CONSTRAINT `chk_cah_head_or_group` CHECK ((`head_id` IS NOT NULL AND `group_id` IS NULL) OR (`head_id` IS NULL AND `group_id` IS NOT NULL))    )
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 10: fee_student_assignments
	-- Purpose: Fee structure assigned to individual students for an academic session
	-- [BUG-FIX] academic_session_id changed from INT to SMALLINT UNSIGNED
	-- [ENHANCE] Added proration columns (join_in_mid-year, fee_start_date, proration_percentage)
	-- [ENHANCE] Added class_id & section_id for quick access (denormalization) to avoid joins during fee calculation and invoice generation
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_student_assignments` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,   -- FK to sch_classes for quick access (denormalization)
    `section_id` INT UNSIGNED NULL,     -- FK to sch_sections for quick access (denormalization)
    `academic_session_id` SMALLINT UNSIGNED NOT NULL,
    `fee_structure_id` INT UNSIGNED NOT NULL,
    `total_fee_amount` DECIMAL(12,2) NOT NULL,
    `opted_heads` JSON NULL COMMENT 'Selected optional heads',
    `opted_groups` JSON NULL COMMENT 'Selected optional groups',
    `assignment_date` DATE NOT NULL,
    `join_in_mid-year` TINYINT(1) NOT NULL DEFAULT 0,
    `fee_start_date` DATE NULL COMMENT 'Actual fee start date for mid-year joins',
    `proration_percentage` DECIMAL(5,2) NULL COMMENT 'Percentage of total fee applicable',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE INDEX `uq_fee_student_session` (`student_id`, `academic_session_id`),
    INDEX `idx_fee_assignment_active` (`is_active`),
    CONSTRAINT `fk_fsa_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_fsa_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fsa_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fsa_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fsa_structure` FOREIGN KEY (`fee_structure_id`) REFERENCES `fee_structure_master` (`id`) ON DELETE RESTRICT
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 11: fee_student_concessions
	-- Purpose: Concessions applied to specific students
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_student_concessions` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_assignment_id` INT UNSIGNED NOT NULL,
    `concession_type_id` INT UNSIGNED NOT NULL,
    `approved_by` INT UNSIGNED NULL COMMENT 'FK to sys_users',
    `approved_at` TIMESTAMP NULL,
    `approval_status` ENUM('Pending', 'Approved', 'Rejected') NOT NULL DEFAULT 'Pending',
    `rejection_reason` TEXT NULL,
    `discount_amount` DECIMAL(10,2) NOT NULL,
    `remarks` TEXT NULL,
    `created_by` INT UNSIGNED NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_concession_status` (`approval_status`),
    CONSTRAINT `fk_fsc_assignment` FOREIGN KEY (`student_assignment_id`) REFERENCES `fee_student_assignments` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_fsc_concession` FOREIGN KEY (`concession_type_id`) REFERENCES `fee_concession_types` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fsc_approver` FOREIGN KEY (`approved_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 12: fee_invoices
	-- Purpose: Generated invoices for students (installment based)
	-- [ENHANCE] Added tax_amount column
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_invoices` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `invoice_no` VARCHAR(50) NOT NULL UNIQUE,
    `student_assignment_id` INT UNSIGNED NOT NULL,
    `installment_id` INT UNSIGNED NULL COMMENT 'NULL for one-time payments',
    `invoice_date` DATE NOT NULL,
    `due_date` DATE NOT NULL,
    `base_amount` DECIMAL(12,2) NOT NULL,
    `concession_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `fine_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `tax_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `total_amount` DECIMAL(12,2) NOT NULL,
    `paid_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `balance_amount` DECIMAL(12,2) GENERATED ALWAYS AS (`total_amount` - `paid_amount`) STORED,
    `status` ENUM('Draft', 'Published', 'Partially Paid', 'Paid', 'Overdue', 'Cancelled') NOT NULL DEFAULT 'Draft',
    `invoice_pdf_path` VARCHAR(255) NULL,
    `generated_by` INT UNSIGNED NOT NULL,
    `cancelled_by` INT UNSIGNED NULL,
    `cancellation_reason` TEXT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_invoice_status` (`status`),
    INDEX `idx_invoice_due_date` (`due_date`),
    INDEX `idx_invoice_student` (`student_assignment_id`),
    CONSTRAINT `fk_finv_assignment` FOREIGN KEY (`student_assignment_id`) REFERENCES `fee_student_assignments` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_finv_installment` FOREIGN KEY (`installment_id`) REFERENCES `fee_installments` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_finv_generator` FOREIGN KEY (`generated_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 13: fee_transactions
	-- Purpose: Master record of each payment transaction
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_transactions` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `transaction_no` VARCHAR(50) NOT NULL UNIQUE,
    `student_id` INT UNSIGNED NOT NULL,
    `invoice_id` INT UNSIGNED NOT NULL,
    `guardian_id` INT UNSIGNED NULL COMMENT 'Who paid the fee',
    `payment_date` DATETIME NOT NULL,
    `payment_mode` ENUM('Cash', 'Cheque', 'DD', 'UPI', 'Credit Card', 'Debit Card', 'Net Banking', 'Wallet') NOT NULL,
    `payment_reference` VARCHAR(100) NULL COMMENT 'Cheque/DD/Transaction ID',
    `bank_name` VARCHAR(100) NULL,
    `cheque_date` DATE NULL,
    `amount` DECIMAL(12,2) NOT NULL,
    `fine_adjusted` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `concession_adjusted` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `status` ENUM('Success', 'Pending', 'Failed', 'Refunded') NOT NULL DEFAULT 'Pending',
    `collected_by` INT UNSIGNED NOT NULL,  -- FK to sys_users ('Cashier/User ID')
    `remarks` TEXT NULL,
    `receipt_generated` TINYINT(1) NOT NULL DEFAULT 0,
    `receipt_id` INT UNSIGNED NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_transaction_student` (`student_id`),
    INDEX `idx_transaction_date` (`payment_date`),
    INDEX `idx_transaction_status` (`status`),
    INDEX `idx_transaction_mode` (`payment_mode`),
    CONSTRAINT `fk_ft_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_ft_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `fee_invoices` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_ft_guardian` FOREIGN KEY (`guardian_id`) REFERENCES `std_guardians` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ft_collector` FOREIGN KEY (`collected_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 14: fee_transaction_details
	-- Purpose: Split of transaction across fee heads
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_transaction_details` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `transaction_id` INT UNSIGNED NOT NULL,
    `head_id` INT UNSIGNED NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL,
    `fine_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `concession_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE INDEX `uq_trans_detail` (`transaction_id`, `head_id`),
    CONSTRAINT `fk_ftd_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `fee_transactions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ftd_head` FOREIGN KEY (`head_id`) REFERENCES `fee_head_master` (`id`) ON DELETE RESTRICT
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 15: fee_receipts
	-- Purpose: Official receipts generated after payment
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_receipts` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `receipt_no` VARCHAR(50) NOT NULL UNIQUE,
    `transaction_id` INT UNSIGNED NOT NULL UNIQUE,
    `receipt_date` DATETIME NOT NULL,
    `receipt_pdf_path` VARCHAR(255) NULL,
    `receipt_format` ENUM('Standard', 'Detailed', 'Tax Invoice') NOT NULL DEFAULT 'Standard',
    `sent_to_parent` TINYINT(1) NOT NULL DEFAULT 0,
    `sent_via` ENUM('Email', 'SMS', 'WhatsApp', 'Print') NULL,
    `sent_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_receipt_date` (`receipt_date`),
    CONSTRAINT `fk_fr_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `fee_transactions` (`id`) ON DELETE RESTRICT
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 16: fee_fine_transactions
	-- Purpose: Tracks fines applied to students
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_fine_transactions` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `invoice_id` INT UNSIGNED NOT NULL,
    `fine_rule_id` INT UNSIGNED NOT NULL,
    `fine_date` DATE NOT NULL,
    `days_late` INT NOT NULL,
    `fine_amount` DECIMAL(10,2) NOT NULL,
    `waived` TINYINT(1) NOT NULL DEFAULT 0,
    `waived_amount` DECIMAL(10,2) NULL COMMENT 'Partial waiver amount (NULL = full waiver if waived=1)',
    `waived_by` INT UNSIGNED NULL,
    `waiver_reason` TEXT NULL,
    `waived_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_fine_student` (`student_id`),
    INDEX `idx_fine_date` (`fine_date`),
    INDEX `idx_fine_waived` (`waived`),
    CONSTRAINT `fk_fft_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fft_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `fee_invoices` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fft_rule` FOREIGN KEY (`fine_rule_id`) REFERENCES `fee_fine_rules` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fft_waiver` FOREIGN KEY (`waived_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 17: fee_payment_gateway_logs
	-- Purpose: Logs all online payment gateway transactions
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_payment_gateway_logs` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `transaction_id` INT UNSIGNED NULL,
    `gateway_name` ENUM('Razorpay', 'Paytm', 'CCAvenue', 'BillDesk', 'Other') NOT NULL,
    `gateway_transaction_id` VARCHAR(100) NULL,
    `order_id` VARCHAR(100) NULL,
    `payment_id` VARCHAR(100) NULL,
    `request_payload` JSON NULL,
    `response_payload` JSON NULL,
    `amount` DECIMAL(12,2) NOT NULL,
    `status` VARCHAR(50) NOT NULL,
    `error_message` TEXT NULL,
    `ip_address` VARCHAR(45) NULL,
    `user_agent` TEXT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_gateway_trans` (`gateway_transaction_id`),
    INDEX `idx_gateway_order` (`order_id`),
    INDEX `idx_gateway_status` (`status`),
    CONSTRAINT `fk_fpgl_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `fee_transactions` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 18: fee_scholarships
	-- Purpose: Scholarship/fund definitions
	-- [ENHANCE] Renamed scholarship_code->code, scholarship_name->name
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_scholarships` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `fund_source` VARCHAR(100) NOT NULL COMMENT 'Government/Trust/Corporate',
    `sponsor_name` VARCHAR(100) NULL,
    `total_fund_amount` DECIMAL(15,2) NULL,
    `available_fund` DECIMAL(15,2) NULL,
    `eligibility_criteria` JSON NOT NULL COMMENT 'Academic/Financial/Category criteria',
    `application_start_date` DATE NULL,
    `application_end_date` DATE NULL,
    `max_amount_per_student` DECIMAL(10,2) NULL,
    `requires_renewal` TINYINT(1) NOT NULL DEFAULT 0,
    `renewal_criteria` JSON NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_scholarship_active` (`is_active`),
    INDEX `idx_scholarship_dates` (`application_start_date`, `application_end_date`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 19: fee_scholarship_applications
	-- Purpose: Student applications for scholarships
	-- [ENHANCE] Added academic_session_id; UNIQUE changed to (scholarship_id, student_id, academic_session_id)
	-- [ENHANCE] Added fk_fschapp_session
	-- [ENHANCE] Renamed FK from fk_fsa_student to fk_fschapp_scholarship & fk_fsa_student to fk_fschapp_student
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_scholarship_applications` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `scholarship_id` INT UNSIGNED NOT NULL,
    `student_id` INT UNSIGNED NOT NULL,
    `academic_session_id` SMALLINT UNSIGNED NOT NULL COMMENT 'FK to sch_org_academic_sessions_jnt',
    `application_date` DATE NOT NULL,
    `application_data` JSON NOT NULL COMMENT 'Student responses to criteria',
    `documents_submitted` JSON NULL,
    `current_stage` INT NOT NULL DEFAULT 1,
    `status` ENUM('Draft', 'Submitted', 'Under Review', 'Approved', 'Rejected', 'Waitlisted') NOT NULL DEFAULT 'Draft',
    `review_committee` JSON NULL COMMENT 'Committee members IDs',
    `approved_amount` DECIMAL(10,2) NULL,
    `disbursed` TINYINT(1) NOT NULL DEFAULT 0,
    `disbursed_date` DATE NULL,
    `remarks` TEXT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE INDEX `uq_scholarship_student_session` (`scholarship_id`, `student_id`, `academic_session_id`),
    INDEX `idx_sch_app_status` (`status`),
    CONSTRAINT `fk_fschapp_scholarship` FOREIGN KEY (`scholarship_id`) REFERENCES `fee_scholarships` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fschapp_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fschapp_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 20: fee_scholarship_approval_history
	-- Purpose: Tracks approval workflow for scholarships
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_scholarship_approval_history` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `application_id` INT UNSIGNED NOT NULL,
    `stage` INT NOT NULL,
    `action_by` INT UNSIGNED NOT NULL,
    `action` ENUM('Submit', 'Approve', 'Reject', 'Request Info', 'Waitlist') NOT NULL,
    `comments` TEXT NULL,
    `action_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_fsah_application` FOREIGN KEY (`application_id`) REFERENCES `fee_scholarship_applications` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_fsah_action_by` FOREIGN KEY (`action_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 21: fee_name_removal_log
	-- Purpose: Logs when student names are removed due to non-payment
	-- [BUG-FIX] academic_session_id changed from INT to SMALLINT UNSIGNED
	-- [ENHANCE] Added re_admission_fee_head_id, removed_by, re_admitted_by
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_name_removal_log` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `academic_session_id` SMALLINT UNSIGNED NOT NULL,
    `removal_date` DATE NOT NULL,
    `removal_reason` TEXT NOT NULL,
    `total_due_at_removal` DECIMAL(12,2) NOT NULL,
    `days_overdue` INT NOT NULL,
    `triggered_by_rule_id` INT UNSIGNED NULL,
    `removed_by` INT UNSIGNED NULL COMMENT 'FK to sys_users - who processed the removal',
    `re_admission_date` DATE NULL,
    `re_admission_fee_paid` DECIMAL(12,2) NULL,
    `re_admission_fee_head_id` INT UNSIGNED NULL COMMENT 'FK to fee_head_master for re-admission fee',
    `re_admission_transaction_id` INT UNSIGNED NULL,
    `re_admitted_by` INT UNSIGNED NULL COMMENT 'FK to sys_users - who processed re-admission',
    `re_activated_date` DATE NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_removal_student` (`student_id`),
    INDEX `idx_removal_date` (`removal_date`),
    CONSTRAINT `fk_frl_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_frl_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_frl_rule` FOREIGN KEY (`triggered_by_rule_id`) REFERENCES `fee_fine_rules` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_frl_removed_by` FOREIGN KEY (`removed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_frl_readmission_head` FOREIGN KEY (`re_admission_fee_head_id`) REFERENCES `fee_head_master` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_frl_readmitted_by` FOREIGN KEY (`re_admitted_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- ========================================================================================================
	-- NEW TABLES (v3)
	-- ========================================================================================================


	-- --------------------------------------------------------------------------------------------------------
	-- Table 22: fee_refunds [NEW in v3]
	-- Purpose: Tracks refund details when payments are reversed or students withdraw
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_refunds` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `refund_no` VARCHAR(50) NOT NULL UNIQUE,
    `original_transaction_id` INT UNSIGNED NOT NULL,
    `student_id` INT UNSIGNED NOT NULL,
    `refund_date` DATE NOT NULL,
    `refund_amount` DECIMAL(12,2) NOT NULL,
    `refund_mode` ENUM('Cash', 'Cheque', 'Bank Transfer', 'Original Mode') NOT NULL,
    `refund_reference` VARCHAR(100) NULL COMMENT 'Cheque/NEFT reference for refund',
    `refund_reason` TEXT NOT NULL,
    `approved_by` INT UNSIGNED NULL COMMENT 'FK to sys_users',
    `approved_at` TIMESTAMP NULL,
    `status` ENUM('Pending', 'Approved', 'Processed', 'Rejected') NOT NULL DEFAULT 'Pending',
    `rejection_reason` TEXT NULL,
    `processed_by` INT UNSIGNED NULL COMMENT 'FK to sys_users',
    `processed_at` TIMESTAMP NULL,
    `created_by` INT UNSIGNED NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_refund_student` (`student_id`),
    INDEX `idx_refund_status` (`status`),
    INDEX `idx_refund_date` (`refund_date`),
    CONSTRAINT `fk_fref_transaction` FOREIGN KEY (`original_transaction_id`) REFERENCES `fee_transactions` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fref_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fref_approver` FOREIGN KEY (`approved_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_fref_processor` FOREIGN KEY (`processed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 23: fee_cheque_clearance [NEW in v3]
	-- Purpose: Tracks cheque/DD lifecycle (deposit -> clearance/bounce)
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_payment_reconciliation` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `transaction_id` INT UNSIGNED NOT NULL UNIQUE,
    `cheque_no` VARCHAR(50) NOT NULL,
    `bank_name` VARCHAR(100) NOT NULL,  -- reconciliation
    `cheque_date` DATE NOT NULL,
    `deposit_date` DATE NULL,
    `clearance_date` DATE NULL,
    `bounce_date` DATE NULL,
    `bounce_reason` VARCHAR(255) NULL,
    `bounce_charge` DECIMAL(10,2) NULL,
    `resubmit_date` DATE NULL,
    `status` ENUM('Pending Deposit', 'Deposited', 'Cleared', 'Bounced', 'Resubmitted') NOT NULL DEFAULT 'Pending Deposit',
    `remarks` TEXT NULL,
    `updated_by` INT UNSIGNED NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_cheque_status` (`status`),
    INDEX `idx_cheque_date` (`cheque_date`),
    CONSTRAINT `fk_fcc_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `fee_transactions` (`id`) ON DELETE RESTRICT
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	-- --------------------------------------------------------------------------------------------------------
	-- Table 24: fee_defaulter_history [NEW in v3]
	-- Purpose: Per-student-per-session summary for defaulter pattern analysis and AI prediction
	-- --------------------------------------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `fee_defaulter_history` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `academic_session_id` SMALLINT UNSIGNED NOT NULL,
    `total_fine_count` INT NOT NULL DEFAULT 0,
    `total_fine_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `total_waived_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `max_days_late` INT NOT NULL DEFAULT 0,
    `avg_days_late` DECIMAL(5,1) NULL,
    `missed_installments` INT NOT NULL DEFAULT 0,
    `name_removed` TINYINT(1) NOT NULL DEFAULT 0,
    `re_admitted` TINYINT(1) NOT NULL DEFAULT 0,
    `defaulter_score` DECIMAL(5,2) NULL COMMENT 'Computed risk score (0-100) for AI analytics',
    `last_computed_at` TIMESTAMP NULL COMMENT 'When the summary was last recalculated',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX `uq_defaulter_student_session` (`student_id`, `academic_session_id`),
    INDEX `idx_defaulter_score` (`defaulter_score`),
    CONSTRAINT `fk_fdh_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fdh_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===========================================================================
-- 20-ACCOUNTING (ACT)
-- ===========================================================================

  -- ---------------------------------------------------------
  -- DOMAIN 1: CORE ACCOUNTING (12 tables)
  -- ---------------------------------------------------------
  -- 1. Financial Years
  CREATE TABLE IF NOT EXISTS `acc_financial_years` (
      `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `name`          VARCHAR(50) NOT NULL COMMENT 'e.g., 2025-26',
      `start_date`    DATE NOT NULL COMMENT 'Financial year start (April 1)',
      `end_date`      DATE NOT NULL COMMENT 'Financial year end (March 31)',
      `is_locked`     TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Prevents edits when locked',
      `is_active`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`    BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`    TIMESTAMP NULL DEFAULT NULL,
      `updated_at`    TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`    TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      INDEX `idx_acc_fy_active` (`is_active`),
      INDEX `idx_acc_fy_dates` (`start_date`, `end_date`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 2. Account Groups (Tally's 28 predefined + custom)
  CREATE TABLE IF NOT EXISTS `acc_account_groups` (
      `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `name`                  VARCHAR(100) NOT NULL COMMENT 'Group name',
      `code`                  VARCHAR(20) NOT NULL COMMENT 'Unique group code e.g., A01, L02',
      `alias`                 VARCHAR(100) NULL COMMENT 'Alternative display name',
      `parent_id`             BIGINT UNSIGNED NULL COMMENT 'Self-referencing for hierarchy',
      `nature`                ENUM('asset','liability','income','expense') NOT NULL COMMENT 'Account nature',
      `affects_gross_profit`  TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Direct vs Indirect classification',
      `is_system`             TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'true = seeded, cannot delete',
      `is_subledger`          TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Behaves as sub-ledger',
      `sequence`              INT NOT NULL DEFAULT 0 COMMENT 'Display order in reports',
      `is_active`             TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`            BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`            TIMESTAMP NULL DEFAULT NULL,
      `updated_at`            TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_acc_ag_code` (`code`, `deleted_at`),
      INDEX `idx_acc_ag_parent` (`parent_id`),
      INDEX `idx_acc_ag_nature` (`nature`),
      INDEX `idx_acc_ag_system` (`is_system`),
      CONSTRAINT `fk_acc_ag_parent` FOREIGN KEY (`parent_id`) REFERENCES `acc_account_groups` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- If `is_system` = 1, then that ledger cannot be deleted. This is for critical groups like Current Assets, Direct Expenses, etc. that are essential for system integrity.

  -- 3. Ledgers (Individual accounts)
  CREATE TABLE IF NOT EXISTS `acc_ledgers` (
      `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `name`                      VARCHAR(150) NOT NULL COMMENT 'Ledger name',
      `code`                      VARCHAR(20) NULL COMMENT 'Unique ledger code',
      `alias`                     VARCHAR(150) NULL COMMENT 'Alternative name',
      `account_group_id`          BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_account_groups',
      `opening_balance`           DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'Opening balance amount',
      `opening_balance_type`      ENUM('Dr','Cr') NULL COMMENT 'Debit or Credit opening',
      `is_bank_account`           TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Bank account flag',
      `bank_name`                 VARCHAR(100) NULL COMMENT 'Bank name if bank account',
      `bank_account_number`       VARCHAR(50) NULL COMMENT 'Bank account number',
      `ifsc_code`                 VARCHAR(20) NULL COMMENT 'Bank IFSC code',
      `is_cash_account`           TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Cash account flag',
      `allow_reconciliation`      TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Enable bank reconciliation',
      `is_system`                 TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'P&L A/c, Cash A/c etc. — cannot delete',
      `student_id`                BIGINT UNSIGNED NULL COMMENT 'FK → std_students (auto-ledger for student debtors)',
      `employee_id`               BIGINT UNSIGNED NULL COMMENT 'FK → sch_employees (auto-ledger for salary payable)',
      `vendor_id`                 BIGINT UNSIGNED NULL COMMENT 'FK → vnd_vendors (auto-ledger for vendor creditors)',
      `gst_registration_type`     VARCHAR(30) NULL COMMENT 'Regular, Composition, etc.',
      `gstin`                     VARCHAR(20) NULL COMMENT 'GST number',
      `pan`                       VARCHAR(15) NULL COMMENT 'PAN number',
      `address`                   TEXT NULL COMMENT 'Ledger address',
      `is_active`                 TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`                BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`                TIMESTAMP NULL DEFAULT NULL,
      `updated_at`                TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      INDEX `idx_acc_ledger_group` (`account_group_id`),
      INDEX `idx_acc_ledger_student` (`student_id`),
      INDEX `idx_acc_ledger_employee` (`employee_id`),
      INDEX `idx_acc_ledger_vendor` (`vendor_id`),
      INDEX `idx_acc_ledger_bank` (`is_bank_account`),
      INDEX `idx_acc_ledger_active` (`is_active`),
      CONSTRAINT `fk_acc_ledger_group` FOREIGN KEY (`account_group_id`) REFERENCES `acc_account_groups` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- If `is_system` = 1, then that ledger cannot be deleted. This is for critical ledgers like Cash Account, Profit & Loss Account, etc. that are essential for system integrity.

  -- 4. Voucher Types
  CREATE TABLE IF NOT EXISTS `acc_voucher_types` (
      `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `name`              VARCHAR(80) NOT NULL COMMENT 'e.g., Payment Voucher',
      `code`              VARCHAR(20) NOT NULL COMMENT 'PAYMENT, RECEIPT, CONTRA, JOURNAL, etc.',
      `category`          ENUM('accounting','inventory','payroll','order') NOT NULL COMMENT 'Domain category',
      `prefix`            VARCHAR(20) NULL COMMENT 'Voucher number prefix e.g., PAY-, RCV-',
      `auto_numbering`    TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Auto-increment enabled',
      `last_number`       INT NOT NULL DEFAULT 0 COMMENT 'Current voucher counter',
      `is_system`         TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Cannot delete seeded types',
      `is_active`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`        TIMESTAMP NULL DEFAULT NULL,
      `updated_at`        TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_acc_vt_code` (`code`, `deleted_at`),
      INDEX `idx_acc_vt_category` (`category`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- If `is_system` = 1, then that voucher type cannot be deleted.

  -- 5. Vouchers (THE HEART — every transaction is a voucher)
  CREATE TABLE IF NOT EXISTS `acc_vouchers` (
      `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `voucher_number`    VARCHAR(50) NOT NULL COMMENT 'Auto-generated, unique per FY',
      `voucher_type_id`   BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_voucher_types',
      `financial_year_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_financial_years',
      `date`              DATE NOT NULL COMMENT 'Transaction date',
      `reference_number`  VARCHAR(100) NULL COMMENT 'Cheque no, receipt no, etc.',
      `reference_date`    DATE NULL COMMENT 'Cheque date, etc.',
      `narration`         TEXT NULL COMMENT 'Transaction description',
      `total_amount`      DECIMAL(15,2) NOT NULL COMMENT 'Total voucher amount',
      `is_post_dated`     TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Post-dated cheque flag',
      `is_optional`       TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Memorandum voucher',
      `is_cancelled`      TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Cancelled flag',
      `cancelled_reason`  TEXT NULL COMMENT 'Cancellation reason',
      `cost_center_id`    BIGINT UNSIGNED NULL COMMENT 'FK → acc_cost_centers (header-level)',
      `source_module`     ENUM('Fees','Library','Transport','HR','Vendor','Inventory','Payroll','Manual') NULL COMMENT 'Source module for integration',
      `source_type`       VARCHAR(100) NULL COMMENT 'Polymorphic model: PayrollRun, FeeTransaction, GRN, etc.',
      `source_id`         BIGINT UNSIGNED NULL COMMENT 'Polymorphic source ID',
      `status`            ENUM('draft','posted','approved','cancelled') NOT NULL DEFAULT 'draft' COMMENT 'Voucher workflow status',
      `approved_by`       BIGINT UNSIGNED NULL COMMENT 'FK → sys_users (approver)',
      `is_active`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`        TIMESTAMP NULL DEFAULT NULL,
      `updated_at`        TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_acc_voucher_number_fy` (`voucher_number`, `financial_year_id`, `deleted_at`),
      INDEX `idx_acc_voucher_type` (`voucher_type_id`),
      INDEX `idx_acc_voucher_fy` (`financial_year_id`),
      INDEX `idx_acc_voucher_date` (`date`),
      INDEX `idx_acc_voucher_status` (`status`),
      INDEX `idx_acc_voucher_source` (`source_module`, `source_type`, `source_id`),
      INDEX `idx_acc_voucher_cost` (`cost_center_id`),
      CONSTRAINT `fk_acc_voucher_type` FOREIGN KEY (`voucher_type_id`) REFERENCES `acc_voucher_types` (`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_acc_voucher_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years` (`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_acc_voucher_cost` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- If `is_optional` = 1, then that transaction should be consider in financial reports but should not be posted to ledgers until explicitly approved and marked as non-optional. 
  -- This allows creating draft vouchers for future transactions or estimates without affecting current financials.

  -- 6. Voucher Items (Dr/Cr line items)
  CREATE TABLE IF NOT EXISTS `acc_voucher_items` (
      `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `voucher_id`        BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_vouchers',
      `ledger_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers',
      `type`              ENUM('debit','credit') NOT NULL COMMENT 'Dr or Cr entry',
      `amount`            DECIMAL(15,2) NOT NULL COMMENT 'Line item amount',
      `narration`         VARCHAR(500) NULL COMMENT 'Per-ledger narration',
      `cost_center_id`    BIGINT UNSIGNED NULL COMMENT 'FK → acc_cost_centers (line-level override)',
      `bill_reference`    VARCHAR(100) NULL COMMENT 'Against invoice/bill reference',
      `is_active`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`        TIMESTAMP NULL DEFAULT NULL,
      `updated_at`        TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      INDEX `idx_acc_vi_voucher` (`voucher_id`),
      INDEX `idx_acc_vi_ledger` (`ledger_id`),
      INDEX `idx_acc_vi_type` (`type`),
      INDEX `idx_acc_vi_cost` (`cost_center_id`),
      CONSTRAINT `fk_acc_vi_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_acc_vi_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_acc_vi_cost` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 7. Cost Centers (Department/Wing/Activity)
  CREATE TABLE IF NOT EXISTS `acc_cost_centers` (
      `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `name`          VARCHAR(100) NOT NULL COMMENT 'e.g., Primary Wing, Transport',
      `code`          VARCHAR(20) NULL COMMENT 'Cost center code',
      `parent_id`     BIGINT UNSIGNED NULL COMMENT 'Self-referencing hierarchy',
      `category`      VARCHAR(50) NULL COMMENT 'Department, Activity, Project',
      `is_active`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`    BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`    TIMESTAMP NULL DEFAULT NULL,
      `updated_at`    TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`    TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      INDEX `idx_acc_cc_parent` (`parent_id`),
      CONSTRAINT `fk_acc_cc_parent` FOREIGN KEY (`parent_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 8. Budgets
  CREATE TABLE IF NOT EXISTS `acc_budgets` (
      `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `financial_year_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_financial_years',
      `cost_center_id`    BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_cost_centers',
      `ledger_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers',
      `budgeted_amount`   DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'Allocated budget amount',
      `is_active`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`        TIMESTAMP NULL DEFAULT NULL,
      `updated_at`        TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_acc_budget` (`financial_year_id`, `cost_center_id`, `ledger_id`),
      INDEX `idx_acc_budget_cc` (`cost_center_id`),
      INDEX `idx_acc_budget_ledger` (`ledger_id`),
      CONSTRAINT `fk_acc_budget_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years` (`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_acc_budget_cc` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_acc_budget_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 9. Tax Rates
  CREATE TABLE IF NOT EXISTS `acc_tax_rates` (
      `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `name`          VARCHAR(100) NOT NULL COMMENT 'e.g., CGST 9%',
      `rate`          DECIMAL(5,2) NOT NULL COMMENT 'Tax rate percentage',
      `type`          ENUM('CGST','SGST','IGST','Cess') NOT NULL COMMENT 'Tax type',
      `hsn_sac_code`  VARCHAR(20) NULL COMMENT 'HSN/SAC code',
      `is_interstate` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Interstate supply flag',
      `is_active`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`    BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`    TIMESTAMP NULL DEFAULT NULL,
      `updated_at`    TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`    TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      INDEX `idx_acc_tax_type` (`type`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 10. Ledger Mappings (Cross-module)
  CREATE TABLE IF NOT EXISTS `acc_ledger_mappings` (
      `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `ledger_id`     BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers',
      `source_module` ENUM('Fees','Library','Transport','HR','Vendor','Inventory','Payroll') NOT NULL COMMENT 'Source module',
      `source_type`   VARCHAR(100) NULL COMMENT 'e.g., FeeHead, PayHead, Route, Stoppage',
      `source_id`     BIGINT UNSIGNED NOT NULL COMMENT 'Source entity ID',
      `description`   VARCHAR(255) NULL COMMENT 'Human-readable mapping description',
      `is_active`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`    BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`    TIMESTAMP NULL DEFAULT NULL,
      `updated_at`    TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`    TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_acc_lm_combo` (`ledger_id`, `source_module`, `source_type`, `source_id`),
      INDEX `idx_acc_lm_source` (`source_module`, `source_type`, `source_id`),
      CONSTRAINT `fk_acc_lm_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 11. Recurring Templates
  CREATE TABLE IF NOT EXISTS `acc_recurring_templates` (
      `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `name`              VARCHAR(150) NOT NULL COMMENT 'Template name',
      `voucher_type_id`   BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_voucher_types',
      `frequency`         ENUM('Daily','Weekly','Monthly','Quarterly','Yearly') NOT NULL COMMENT 'Recurrence frequency',
      `start_date`        DATE NOT NULL COMMENT 'Start posting from',
      `end_date`          DATE NULL COMMENT 'Stop posting after (NULL = indefinite)',
      `day_of_month`      TINYINT NULL COMMENT 'Day to post for monthly frequency',
      `narration`         TEXT NULL COMMENT 'Default narration for generated vouchers',
      `total_amount`      DECIMAL(15,2) NOT NULL COMMENT 'Template total (must balance Dr=Cr)',
      `last_posted_date`  DATE NULL COMMENT 'Last auto-post date',
      `is_active`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`        TIMESTAMP NULL DEFAULT NULL,
      `updated_at`        TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      INDEX `idx_acc_rt_type` (`voucher_type_id`),
      CONSTRAINT `fk_acc_rt_type` FOREIGN KEY (`voucher_type_id`) REFERENCES `acc_voucher_types` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 12. Recurring Template Lines
  CREATE TABLE IF NOT EXISTS `acc_recurring_template_lines` (
      `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `recurring_template_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_recurring_templates',
      `ledger_id`             BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers',
      `type`                  ENUM('debit','credit') NOT NULL COMMENT 'Dr or Cr',
      `amount`                DECIMAL(15,2) NOT NULL COMMENT 'Line amount',
      `narration`             VARCHAR(500) NULL COMMENT 'Per-line narration',
      `is_active`             TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`            BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`            TIMESTAMP NULL DEFAULT NULL,
      `updated_at`            TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      INDEX `idx_acc_rtl_template` (`recurring_template_id`),
      INDEX `idx_acc_rtl_ledger` (`ledger_id`),
      CONSTRAINT `fk_acc_rtl_template` FOREIGN KEY (`recurring_template_id`) REFERENCES `acc_recurring_templates` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_acc_rtl_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ---------------------------------------------------------
  -- DOMAIN 2: BANKING (2 tables)
  -- ---------------------------------------------------------

  -- 13. Bank Reconciliations
  CREATE TABLE IF NOT EXISTS `acc_bank_reconciliations` (
      `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `ledger_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers (bank account)',
      `statement_date`    DATE NOT NULL COMMENT 'Bank statement date',
      `closing_balance`   DECIMAL(15,2) NOT NULL COMMENT 'Closing balance per bank statement',
      `statement_path`    VARCHAR(255) NULL COMMENT 'Uploaded statement file path',
      `status`            ENUM('In Progress','Completed') NOT NULL DEFAULT 'In Progress' COMMENT 'Reconciliation status',
      `is_active`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`        TIMESTAMP NULL DEFAULT NULL,
      `updated_at`        TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      INDEX `idx_acc_br_ledger` (`ledger_id`),
      INDEX `idx_acc_br_date` (`statement_date`),
      CONSTRAINT `fk_acc_br_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 14. Bank Statement Entries
  CREATE TABLE IF NOT EXISTS `acc_bank_statement_entries` (
      `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `reconciliation_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_bank_reconciliations',
      `transaction_date`          DATE NOT NULL COMMENT 'Bank transaction date',
      `description`               VARCHAR(500) NULL COMMENT 'Transaction description from bank',
      `reference`                 VARCHAR(255) NULL COMMENT 'Bank reference number',
      `debit`                     DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'Debit amount (withdrawal)',
      `credit`                    DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'Credit amount (deposit)',
      `balance`                   DECIMAL(15,2) NULL COMMENT 'Running balance per statement',
      `is_matched`                TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Whether matched to a voucher item',
      `matched_voucher_item_id`   BIGINT UNSIGNED NULL COMMENT 'FK → acc_voucher_items (matched entry)',
      `matched_at`                TIMESTAMP NULL COMMENT 'When the match was made',
      `matched_by`                BIGINT UNSIGNED NULL COMMENT 'FK → sys_users (who matched)',
      `is_active`                 TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`                BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`                TIMESTAMP NULL DEFAULT NULL,
      `updated_at`                TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      INDEX `idx_acc_bse_recon` (`reconciliation_id`),
      INDEX `idx_acc_bse_matched` (`is_matched`),
      INDEX `idx_acc_bse_vi` (`matched_voucher_item_id`),
      INDEX `idx_acc_bse_date` (`transaction_date`),
      CONSTRAINT `fk_acc_bse_recon` FOREIGN KEY (`reconciliation_id`) REFERENCES `acc_bank_reconciliations` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_acc_bse_vi` FOREIGN KEY (`matched_voucher_item_id`) REFERENCES `acc_voucher_items` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ---------------------------------------------------------
  -- DOMAIN 3: FIXED ASSETS (3 tables)
  -- ---------------------------------------------------------

  -- 15. Asset Categories
  CREATE TABLE IF NOT EXISTS `acc_asset_categories` (
      `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `name`                  VARCHAR(100) NOT NULL COMMENT 'Category name e.g., Furniture',
      `code`                  VARCHAR(20) NOT NULL COMMENT 'Category code',
      `depreciation_method`   ENUM('SLM','WDV') NOT NULL COMMENT 'Straight Line / Written Down Value',
      `depreciation_rate`     DECIMAL(5,2) NOT NULL COMMENT 'Annual depreciation rate %',
      `useful_life_years`     INT NULL COMMENT 'Useful life in years',
      `is_active`             TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`            BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`            TIMESTAMP NULL DEFAULT NULL,
      `updated_at`            TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_acc_assetcat_code` (`code`, `deleted_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 16. Fixed Assets
  CREATE TABLE IF NOT EXISTS `acc_fixed_assets` (
      `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `name`                      VARCHAR(150) NOT NULL COMMENT 'Asset name',
      `asset_code`                VARCHAR(50) NOT NULL COMMENT 'Asset identification code',
      `asset_category_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_asset_categories',
      `purchase_date`             DATE NOT NULL COMMENT 'Date of purchase',
      `purchase_cost`             DECIMAL(15,2) NOT NULL COMMENT 'Original purchase cost',
      `salvage_value`             DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'Estimated residual value',
      `current_value`             DECIMAL(15,2) NOT NULL COMMENT 'Current book value',
      `accumulated_depreciation`  DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'Total depreciation to date',
      `location`                  VARCHAR(100) NULL COMMENT 'Physical location of asset',
      `vendor_id`                 BIGINT UNSIGNED NULL COMMENT 'FK → vnd_vendors (supplier)',
      `voucher_id`                BIGINT UNSIGNED NULL COMMENT 'FK → acc_vouchers (purchase voucher)',
      `is_active`                 TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`                BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`                TIMESTAMP NULL DEFAULT NULL,
      `updated_at`                TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_acc_fa_code` (`asset_code`, `deleted_at`),
      INDEX `idx_acc_fa_category` (`asset_category_id`),
      INDEX `idx_acc_fa_vendor` (`vendor_id`),
      INDEX `idx_acc_fa_voucher` (`voucher_id`),
      CONSTRAINT `fk_acc_fa_category` FOREIGN KEY (`asset_category_id`) REFERENCES `acc_asset_categories` (`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_acc_fa_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 17. Depreciation Entries
  CREATE TABLE IF NOT EXISTS `acc_depreciation_entries` (
      `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `fixed_asset_id`        BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_fixed_assets',
      `financial_year_id`     BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_financial_years',
      `depreciation_date`     DATE NOT NULL COMMENT 'Date of depreciation entry',
      `depreciation_amount`   DECIMAL(15,2) NOT NULL COMMENT 'Depreciation amount for this period',
      `voucher_id`            BIGINT UNSIGNED NULL COMMENT 'FK → acc_vouchers (depreciation journal)',
      `is_active`             TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`            BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`            TIMESTAMP NULL DEFAULT NULL,
      `updated_at`            TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      INDEX `idx_acc_de_asset` (`fixed_asset_id`),
      INDEX `idx_acc_de_fy` (`financial_year_id`),
      INDEX `idx_acc_de_voucher` (`voucher_id`),
      CONSTRAINT `fk_acc_de_asset` FOREIGN KEY (`fixed_asset_id`) REFERENCES `acc_fixed_assets` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_acc_de_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years` (`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_acc_de_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ---------------------------------------------------------
  -- DOMAIN 4: EXPENSE CLAIMS (2 tables)
  -- ---------------------------------------------------------

  -- 18. Expense Claims
  CREATE TABLE IF NOT EXISTS `acc_expense_claims` (
      `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `claim_number`  VARCHAR(50) NOT NULL COMMENT 'Auto-generated claim number',
      `employee_id`   BIGINT UNSIGNED NOT NULL COMMENT 'FK → sch_employees (existing table)',
      `claim_date`    DATE NOT NULL COMMENT 'Date of claim submission',
      `total_amount`  DECIMAL(15,2) NOT NULL COMMENT 'Total claim amount',
      `status`        ENUM('Draft','Submitted','Approved','Rejected','Paid') NOT NULL DEFAULT 'Draft' COMMENT 'Claim workflow status',
      `approved_by`   BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `approved_at`   TIMESTAMP NULL COMMENT 'Approval timestamp',
      `voucher_id`    BIGINT UNSIGNED NULL COMMENT 'FK → acc_vouchers (payment voucher on approval)',
      `is_active`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`    BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`    TIMESTAMP NULL DEFAULT NULL,
      `updated_at`    TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`    TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_acc_ec_number` (`claim_number`, `deleted_at`),
      INDEX `idx_acc_ec_employee` (`employee_id`),
      INDEX `idx_acc_ec_status` (`status`),
      INDEX `idx_acc_ec_voucher` (`voucher_id`),
      CONSTRAINT `fk_acc_ec_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 19. Expense Claim Lines
  CREATE TABLE IF NOT EXISTS `acc_expense_claim_lines` (
      `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `expense_claim_id`  BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_expense_claims',
      `expense_date`      DATE NOT NULL COMMENT 'Date of expense',
      `ledger_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers (expense category)',
      `description`       VARCHAR(255) NOT NULL COMMENT 'Expense description',
      `amount`            DECIMAL(15,2) NOT NULL COMMENT 'Expense amount',
      `tax_amount`        DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'Tax on expense',
      `receipt_path`      VARCHAR(255) NULL COMMENT 'Uploaded receipt file path',
      `is_active`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`        TIMESTAMP NULL DEFAULT NULL,
      `updated_at`        TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      INDEX `idx_acc_ecl_claim` (`expense_claim_id`),
      INDEX `idx_acc_ecl_ledger` (`ledger_id`),
      CONSTRAINT `fk_acc_ecl_claim` FOREIGN KEY (`expense_claim_id`) REFERENCES `acc_expense_claims` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_acc_ecl_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ---------------------------------------------------------
  -- DOMAIN 5: TALLY INTEGRATION (2 tables)
  -- ---------------------------------------------------------

  -- 20. Tally Export Logs
  CREATE TABLE IF NOT EXISTS `acc_tally_export_logs` (
      `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `export_type`   ENUM('Ledgers','Vouchers','Inventory') NOT NULL COMMENT 'What was exported',
      `export_date`   DATETIME NOT NULL COMMENT 'When export was run',
      `file_name`     VARCHAR(255) NOT NULL COMMENT 'Generated file name',
      `exported_by`   BIGINT UNSIGNED NOT NULL COMMENT 'FK → sys_users',
      `start_date`    DATE NULL COMMENT 'Export date range start',
      `end_date`      DATE NULL COMMENT 'Export date range end',
      `record_count`  INT NULL COMMENT 'Number of records exported',
      `status`        ENUM('Success','Failed','Partial') NOT NULL COMMENT 'Export result',
      `error_log`     TEXT NULL COMMENT 'Error details if failed',
      `is_active`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`    BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`    TIMESTAMP NULL DEFAULT NULL,
      `updated_at`    TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`    TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      INDEX `idx_acc_tel_type` (`export_type`),
      INDEX `idx_acc_tel_date` (`export_date`),
      INDEX `idx_acc_tel_by` (`exported_by`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 21. Tally Ledger Mappings
  CREATE TABLE IF NOT EXISTS `acc_tally_ledger_mappings` (
      `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `ledger_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers (our application ledger)',
      `tally_ledger_name` VARCHAR(200) NOT NULL COMMENT 'Exact Tally ledger name for export/import',
      `tally_group_name`  VARCHAR(200) NULL COMMENT 'Tally parent group name',
      `tally_alias`       VARCHAR(200) NULL COMMENT 'Tally alias if any',
      `mapping_type`      ENUM('auto','manual') NOT NULL DEFAULT 'auto' COMMENT 'Auto=seeded, manual=user-configured',
      `sync_direction`    ENUM('export_only','import_only','bidirectional') NOT NULL DEFAULT 'export_only' COMMENT 'Sync direction',
      `last_synced_at`    TIMESTAMP NULL COMMENT 'Last successful sync timestamp',
      `is_active`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
      `created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
      `created_at`        TIMESTAMP NULL DEFAULT NULL,
      `updated_at`        TIMESTAMP NULL DEFAULT NULL,
      `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_acc_tlm_ledger` (`ledger_id`, `deleted_at`),
      CONSTRAINT `fk_acc_tlm_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ---------------------------------------------------------
  -- PERFORMANCE INDEXES
  -- ---------------------------------------------------------
  CREATE INDEX idx_acc_voucher_composite ON `acc_vouchers` (`date`, `financial_year_id`, `status`);
  CREATE INDEX idx_acc_vi_ledger_date ON `acc_voucher_items` (`ledger_id`, `created_at`);
  CREATE INDEX idx_acc_bse_recon_matched ON `acc_bank_statement_entries` (`reconciliation_id`, `is_matched`);


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