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
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
    UNIQUE KEY `uq_roles_name_name_guardName` (`name`,`guard_name`),
    UNIQUE KEY `uq_roles_name_shortName_guardName` (`short_name`,`guard_name`) 
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction Tables for Many-to-Many Relationships
  CREATE TABLE IF NOT EXISTS `sys_role_has_permissions_jnt` (
    `permission_id` bigint unsigned NOT NULL,   -- FK to sys_permissions
    `role_id` bigint unsigned NOT NULL,         -- FK to sys_roles
    PRIMARY KEY (`permission_id`,`role_id`),
    KEY `idx_roleHasPermissions_roleId` (`role_id`),
    CONSTRAINT `fk_roleHasPermissions_permissionId` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`),
    CONSTRAINT `fk_roleHasPermissions_roleId` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction Tables for Polymorphic Many-to-Many Relationships
  CREATE TABLE IF NOT EXISTS `sys_model_has_permissions_jnt` (
    `permission_id` bigint unsigned NOT NULL,   -- FK to sys_permissions
    `model_type` varchar(190) NOT NULL,         -- E.g., 'App\Models\User'
    `model_id` bigint unsigned NOT NULL,        -- E.g., User ID
    PRIMARY KEY (`permission_id`,`model_id`,`model_type`),
    KEY `idx_modelHasPermissions_modelId_modelType` (`model_id`,`model_type`),
    CONSTRAINT `fk_modelHasPermissions_permissionId` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`),
    CONSTRAINT `fk_modelHasPermissions_modelId_modelType` FOREIGN KEY (`model_id`) REFERENCES `sys_models` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction Tables for Polymorphic Many-to-Many Relationships
  CREATE TABLE IF NOT EXISTS `sys_model_has_roles_jnt` (
    `role_id` bigint unsigned NOT NULL,       -- FK to sys_roles
    `model_type` varchar(190) NOT NULL,       -- E.g., 'App\Models\User'
    `model_id` bigint unsigned NOT NULL,      -- E.g., User ID
    PRIMARY KEY (`role_id`,`model_id`,`model_type`),
    KEY `idx_modelHasRoles_modelId_modelType` (`model_id`,`model_type`),
    CONSTRAINT `fk_modelHasRoles_roleId` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`),
    CONSTRAINT `fk_modelHasRoles_modelId_modelType` FOREIGN KEY (`model_id`) REFERENCES `sys_models` (`id`)
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

  -- --------------------------------------------------------------------------------------------------------
  -- Ths Table will capture the detail of which Field of Which Table fo Which Databse Type, I can create a Dropdown in sys_dropdown_table of?
  -- This will help us to make sure we can only create create a Dropdown in sys_dropdown_table whcih has been configured by Developer.
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
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `dropdown_needs_id` bigint unsigned NOT NULL,  -- FK to sys_dropdown_needs.id
    `dropdown_table_id` bigint unsigned NOT NULL,  -- FK to sys_dropdown_table.id
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_dropdownNeedTableJnt_dropdownNeedsId` (`dropdown_needs_id`),
    UNIQUE KEY `uq_dropdownNeedTableJnt_dropdownTableId` (`dropdown_table_id`),
    CONSTRAINT `fk_dropdownNeedTableJnt_dropdownNeedsId` FOREIGN KEY (`dropdown_needs_id`) REFERENCES `sys_dropdown_needs` (`id`),
    CONSTRAINT `fk_dropdownNeedTableJnt_dropdownTableId` FOREIGN KEY (`dropdown_table_id`) REFERENCES `sys_dropdown_table` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  -- --------------------------------------------------------------------------------------------------------
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


-- ===========================================================================
-- 3-SCHOOL SETUP MODULE (sch)
-- ===========================================================================

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
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
  -- Condition: 
    -- This table will be used to get Entity Group, which will be a combination of differet type of Entities.
    -- 'entity_purpose_id' will be used to filter the Entity Group created for some purpose.
    -- e.g. "Tour Supervisors" which can be a combination of Students & Teachers, "Event Organizers" which can be a combination of Students & Teachers.

  -- This table will be used to store the members of the Entity Group.
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
  -- Condition: 
    -- entity_type = (1=Class, 2=Section, 3=Subject, 4=Designation, 5=Department, 6=Role, 7=Students, 8=Staff, 9=Vehicle, 10=Facility, 11=Event, 12=Location, 13=Other)
    -- We will be storing table name to use for selecting entities in `additional_info` in `sys_dropdown_table` table alongwith entity_type menu items e.g. for entity_type=1, table_name="sch_class", for entity_type=9, table_name="sch_vehicle"
    -- entity_table_name will be fetched from `additional_info` in `sys_dropdown_table` table e.g. (sch_class, sch_section, sch_subject, sch_designation, sch_department, sch_role, sch_students, sch_staff, sch_vehicle, sch_facility, sch_event, sch_location, sch_other)

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

  -- subject_study_format is grouping for different streams like Sci-10 Lacture, Arts-10 Activity, Core-10
  -- I have removed 'sub_types' from 'sch_subject_study_format_jnt' because one Subject_StudyFormat may belongs to different Subject_type for different classes
  -- Removed 'short_name' as we can use `sub_stdformat_code`
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

  -- Ths table will be used to define different Class Groups like 10th-A Science Lecture Major, 7th-B Commerce Optional etc.
  -- old name 'sch_subject_study_format_class_subj_types_jnt' changed to 'sch_class_groups_jnt'
  CREATE TABLE IF NOT EXISTS `sch_class_groups_jnt` (
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,                  -- FK
    `class_id` int unsigned NOT NULL,                              -- FK to 'sch_classes'
    `section_id` int unsigned NOT NULL,                            -- FK to 'sch_sections'
    `subject_Study_format_id` bigint unsigned NOT NULL,   -- FK to 'sch_subject_study_format_jnt'
    `subject_type_id` int unsigned NOT NULL,              -- FK to 'sch_subject_types'
    `rooms_type_id` int unsigned NOT NULL,             -- FK to 'sch_rooms_type'
    `name` varchar(50) NOT NULL,                          -- 10th-A Science Lacture Major
    `code` CHAR(17) NOT NULL, -- Combination of (Class+Section+Subject+StudyFormat+SubjType) e.g., '10h_A_SCI_LAC_MAJ','8th_MAT_LAC_OPT' (This will be used for Timetable)
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_classGroups_cls_Sec_subStdFmt_SubTyp` (`class_id`,`section_id`,`subject_Study_format_id`),
    UNIQUE KEY `uq_classGroups_subStdformatCode` (`code`), 
    CONSTRAINT `fk_classGroups_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classGroups_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classGroups_subjStudyFormatId` FOREIGN KEY (`subject_Study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classGroups_subTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classGroups_roomTypeId` FOREIGN KEY (`rooms_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Table 'sch_subject_groups' will be used to assign all subjects to the students
  -- There will be a Variable in 'sch_settings' table named 'SubjGroup_For_All_Sections' (Subj_Group_will_be_used_for_all_sections_of_a_class)
  -- if above variable is True then section_id will be Nul in below table and
  -- Every Group will eb avalaible accross sections for a particuler class
  CREATE TABLE IF NOT EXISTS `sch_subject_groups` (
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `class_id` int UNSIGNED NOT NULL,                        -- FK to 'sch_classes'
    `section_id` int UNSIGNED NULL,                          -- FK (Section can be null if Group will be used for all sectons)
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
    CONSTRAINT `fk_subGroups_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `sch_subject_group_subject_jnt` (
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `subject_group_id` bigint unsigned NOT NULL,              -- FK to 'sch_subject_groups'
    `class_group_id` bigint unsigned NOT NULL,                -- FK to 'sch_class_groups_jnt'
    `subject_id` int unsigned NOT NULL,                       -- FK to 'sch_subjects'
    `subject_type_id` int unsigned NOT NULL,                  -- FK to 'sch_subject_types'
    `subject_study_format_id` bigint unsigned NOT NULL,       -- FK to 'sch_subject_study_format_jnt'
    `is_compulsory` tinyint(1) NOT NULL DEFAULT '0',          -- Is this Subject compulsory for Student or Optional
    `weekly_periods` TINYINT UNSIGNED NOT NULL,  -- Total periods required per week
    `min_periods_per_week` TINYINT UNSIGNED DEFAULT NULL,  -- Minimum periods required per week
    `max_periods_per_week` TINYINT UNSIGNED DEFAULT NULL,  -- Maximum periods required per week
    `max_per_day` TINYINT UNSIGNED DEFAULT NULL,  -- Maximum periods per day
    `min_per_day` TINYINT UNSIGNED DEFAULT NULL,  -- Minimum periods per day
    `min_gap_periods` TINYINT UNSIGNED DEFAULT NULL,  -- Minimum gap periods
    `allow_consecutive` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether consecutive periods are allowed
    `max_consecutive` TINYINT UNSIGNED DEFAULT 2,  -- Maximum consecutive periods
    `priority` SMALLINT UNSIGNED DEFAULT 50,  -- Priority of this requirement
    `compulsory_room_type` INT UNSIGNED DEFAULT NULL,  -- FK to sch_room_types.id
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subjGrpSubj_subjGrpId_classGroup` (`subject_group_id`,`class_group_id`),
    CONSTRAINT `fk_subjGrpSubj_subjectGroup` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_classGroup` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_subjectTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_subjectStudyFormatId` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Add new Field for Timetable -
  -- is_compulsory, min_periods_per_week, max_periods_per_week, max_per_day, min_per_day, min_gap_periods, allow_consecutive, max_consecutive, priority, compulsory_room_type


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
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


    -- Teacher table will store additional information about teachers
    CREATE TABLE IF NOT EXISTS `sch_teachers` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `user_id` BIGINT UNSIGNED NOT NULL,  -- fk to sys_users.id
      `emp_code` VARCHAR(20) NOT NULL,     -- Employee Code (Unique code for each user)
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
      CONSTRAINT `fk_teachers_userId` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Teacher Profile table will store detailed proficiency to teach specific subjects, study formats, and classes
    CREATE TABLE IF NOT EXISTS `sch_teachers_profile` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `teacher_id` BIGINT UNSIGNED NOT NULL,
      `subject_id` BIGINT UNSIGNED NOT NULL,            -- FK to 'subjects' table
      `study_format_id` INT UNSIGNED NOT NULL,       -- FK to 'sch_study_formats' table 
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
      UNIQUE KEY `uq_teachersProfile_teacher` (`teacher_id`,`subject_id`,`study_format_id`,class_id),
      CONSTRAINT `fk_teachersProfile_teacherId` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_teachersProfile_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_teachersProfile_studyFormatId` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_teachersProfile_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===========================================================================
-- 4-TRANSPORT MODULE (tpt)
-- ===========================================================================

  CREATE TABLE IF NOT EXISTS `tpt_vehicle` (
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vehicle_no` VARCHAR(20) NOT NULL,              -- Vehicle number(Vehicle Identification Number (VIN)/Chassis Number: A unique 17-character code stamped on the vehicle's chassis)
      `registration_no` VARCHAR(30) NOT NULL,         -- Unique govt registration number
      `model` VARCHAR(50),                            -- Vehicle model
      `manufacturer` VARCHAR(50),                     -- Vehicle manufacturer 
      `vehicle_type_id` BIGINT UNSIGNED NOT NULL,     -- fk to sys_dropdown_table ('BUS','VAN','CAR')
      `fuel_type_id` BIGINT UNSIGNED NOT NULL,        -- fk to sys_dropdown_table ('Diesel','Petrol','CNG','Electric')
      `capacity` INT UNSIGNED NOT NULL DEFAULT 40,    -- Seating capacity
      `max_capacity` INT UNSIGNED NOT NULL DEFAULT 40, -- Maximum allowed capacity including standing
      `ownership_type_id` BIGINT UNSIGNED NOT NULL,   -- fk to sys_dropdown_table ('Owned','Leased','Rented')
      `vendor_id` BIGINT UNSIGNED NOT NULL,           -- fk to tpt_vendor
      `fitness_valid_upto` DATE NOT NULL,             -- Fitness certificate expiry date
      `insurance_valid_upto` DATE NOT NULL,           -- Insurance expiry date
      `pollution_valid_upto` DATE NOT NULL,           -- Pollution certificate expiry date
      `vehicle_emission_class_id` BIGINT UNSIGNED NOT NULL,  -- fk to sys_dropdown_table ('BS IV', 'BS V', 'BS VI')
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `user_id` BIGINT UNSIGNED DEFAULT NULL,
      `user_qr_code` VARCHAR(30) NOT NULL,
      `id_card_type` ENUM('QR','RFID','NFC','Barcode') NOT NULL DEFAULT 'QR',
      `name` VARCHAR(100) NOT NULL,
      `phone` VARCHAR(30) DEFAULT NULL,
      `id_type` VARCHAR(20) DEFAULT NULL,     -- ID Type (e.g., Aadhaar, PAN, Passport)
      `id_no` VARCHAR(100) DEFAULT NULL,      -- ID Number   
      `role` VARCHAR(20) NOT NULL,            -- Role (e.g., Driver, Helper, Transport Manager etc.)
      `license_no` VARCHAR(50) DEFAULT NULL,  -- License Number
      `license_valid_upto` DATE DEFAULT NULL,  -- License Valid Upto
      `assigned_vehicle_id` BIGINT UNSIGNED DEFAULT NULL,  -- fk to tpt_vehicle
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

  CREATE TABLE IF NOT EXISTS `tpt_route` (
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `code` VARCHAR(50) NOT NULL,
      `name` VARCHAR(200) NOT NULL,
      `description` VARCHAR(500) DEFAULT NULL,
      `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
      `shift_id` BIGINT UNSIGNED NOT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `shift_id` BIGINT UNSIGNED NOT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `shift_id` BIGINT UNSIGNED NOT NULL,
      `route_id` BIGINT UNSIGNED NOT NULL,
      `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
      `pickup_point_id` BIGINT UNSIGNED NOT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `shift_id` BIGINT UNSIGNED NOT NULL,
      `route_id` BIGINT UNSIGNED NOT NULL,
      `vehicle_id` BIGINT UNSIGNED NOT NULL,
      `driver_id` BIGINT UNSIGNED NOT NULL,
      `helper_id` BIGINT UNSIGNED DEFAULT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `scheduled_date` DATE NOT NULL,
      `shift_id` BIGINT UNSIGNED NOT NULL,
      `route_id` BIGINT UNSIGNED NOT NULL,
      `vehicle_id` BIGINT UNSIGNED NOT NULL,
      `driver_id` BIGINT UNSIGNED NOT NULL,
      `helper_id` BIGINT UNSIGNED DEFAULT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `trip_date` DATE NOT NULL,      --  Date of the trip
      `route_scheduler_id` BIGINT UNSIGNED NOT NULL, -- FK to tpt_route_scheduler_jnt
      `route_id` BIGINT UNSIGNED NOT NULL, -- FK to tpt_route
      `vehicle_id` BIGINT UNSIGNED NOT NULL, -- FK to tpt_vehicle
      `driver_id` BIGINT UNSIGNED NOT NULL, -- FK to tpt_personnel
      `helper_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to tpt_personnel
      `start_time` DATETIME DEFAULT NULL, -- Start time of the trip
      `end_time` DATETIME DEFAULT NULL, -- End time of the trip
      `start_odometer_reading` DECIMAL(11, 2) DEFAULT 0.00,
      `end_odometer_reading` DECIMAL(11, 2) DEFAULT 0.00,
      `start_fuel_reading` DECIMAL(8, 3) DEFAULT 0.00,
      `end_fuel_reading` DECIMAL(8, 3) DEFAULT 0.00,
      `status` VARCHAR(20) NOT NULL DEFAULT 'Scheduled',
      `approved` TINYINT(1) NOT NULL DEFAULT 0,
      `approved_by` BIGINT UNSIGNED DEFAULT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `trip_id` BIGINT UNSIGNED NOT NULL,     -- fk to tpt_trip
      `stop_id` BIGINT UNSIGNED DEFAULT NULL, -- fk to tpt_stop
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
      `updated_by` BIGINT UNSIGNED DEFAULT NULL,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_trip_stop_detail_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_trip_stop_detail_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_trip_stop_detail_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_attendance_device` (
      `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
      `user_id` BIGINT UNSIGNED NOT NULL,     -- fk to tpt_personnel
      `device_uuid` CHAR(36) NOT NULL,        -- Unique identifier of the device
      `device_type` ENUM('Mobile','Tablet','Laptop','Desktop') NOT NULL,
      `location` VARCHAR(150) NULL,
      `device_os` BIGINT NOT NULL,            -- fk to sys_dropdown_table ('android','ios','windows','linux','mac')
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `driver_id` BIGINT UNSIGNED NOT NULL,
      `attendance_date` DATE NOT NULL,
      `first_in_time` DATETIME NULL,
      `last_out_time` DATETIME NULL,
      `total_work_minutes` INT NULL,
      `attendance_status` BIGINT NOT NULL, -- fk to sys_dropdown_table ('Present','Absent','Half-Day','Late')
      `via_app` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE KEY `uq_driver_day` (`driver_id`, `attendance_date`),
      FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`),
      FOREIGN KEY (`attendance_status`) REFERENCES `sys_dropdown_table`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_driver_attendance_log` (
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `attendance_id` BIGINT UNSIGNED NOT NULL,
      `scan_time` DATETIME NOT NULL,
      `attendance_type` ENUM('IN','OUT') NOT NULL,
      `scan_method` ENUM('QR','RFID','NFC','Manual') NOT NULL,
      `device_id` BIGINT UNSIGNED NOT NULL,
      `latitude` DECIMAL(10,6) NULL,
      `longitude` DECIMAL(10,6) NULL,
      `scan_status` ENUM('Valid','Duplicate','Rejected') NOT NULL DEFAULT 'Valid',
      `remarks` VARCHAR(255) NULL,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT `fk_da_attendance` FOREIGN KEY (`attendance_id`) REFERENCES `tpt_driver_attendance`(`id`) ON DELETE CASCADE,
      CONSTRAINT `FK_da_device` FOREIGN KEY (`device_id`) REFERENCES `tpt_attendance_device`(`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_student_route_allocation_jnt` (
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_session_id` BIGINT UNSIGNED NOT NULL,
      `student_id` BIGINT UNSIGNED NOT NULL,
      `pickup_route_id` BIGINT UNSIGNED NOT NULL,
      `pickup_stop_id` BIGINT UNSIGNED NOT NULL,
      `drop_route_id` BIGINT UNSIGNED NOT NULL,
      `drop_stop_id` BIGINT UNSIGNED NOT NULL,
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

  CREATE TABLE IF NOT EXISTS `tpt_student_fee_detail` (
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `std_academic_sessions_id` BIGINT UNSIGNED NOT NULL,
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

  CREATE TABLE IF NOT EXISTS `tpt_student_fee_collection` (
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_fee_detail_id` BIGINT UNSIGNED NOT NULL,
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
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` BIGINT UNSIGNED NOT NULL,
    `academic_session_id` BIGINT UNSIGNED NOT NULL,
    `module_name` VARCHAR(50) NOT NULL,
    `activity_type` VARCHAR(50) NOT NULL,
    `amount` DECIMAL(10,2) DEFAULT NULL,
    `log_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `reference_id` BIGINT UNSIGNED DEFAULT NULL,
    `reference_table` VARCHAR(100) DEFAULT NULL,
    `description` VARCHAR(512) DEFAULT NULL,
    `triggered_by` BIGINT UNSIGNED DEFAULT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vehicle_id` BIGINT UNSIGNED NOT NULL,
      `driver_id` BIGINT UNSIGNED DEFAULT NULL,
      `date` DATE NOT NULL,
      `quantity` DECIMAL(10,3) NOT NULL,
      `cost` DECIMAL(12,2) NOT NULL,
      `fuel_type` BIGINT UNSIGNED NOT NULL,
      `odometer_reading` BIGINT UNSIGNED DEFAULT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vehicle_id` BIGINT UNSIGNED NOT NULL,
      `driver_id` BIGINT UNSIGNED DEFAULT NULL,
      `inspection_date` TIMESTAMP NOT NULL,
      `odometer_reading` BIGINT UNSIGNED DEFAULT NULL,
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
      `inspected_by` BIGINT UNSIGNED DEFAULT NULL, 
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vehicle_inspection_id` BIGINT UNSIGNED NOT NULL,
      `request_date` TIMESTAMP NOT NULL,
      `reason` VARCHAR(512) DEFAULT NULL,  -- Reason can be filled by anyone
      `Vehicle_status` BIGINT UNSIGNED DEFAULT NULL,  -- fk to sys_dropdown_table ('Due for Service', 'In-Service', 'Service Done')
      `service_completion_date` TIMESTAMP NULL DEFAULT NULL,
      `request_approval_status` ENUM('Approved','Pending','Rejected') NOT NULL DEFAULT 'Pending',
      `approved_by` BIGINT UNSIGNED DEFAULT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vehicle_service_request_id` BIGINT UNSIGNED NOT NULL,
      `maintenance_initiation_date` DATE NOT NULL,  -- Date of Service Initiated (Vehicle reached in garage)
      `maintenance_type` VARCHAR(120) NOT NULL,    -- Mannual Entry
      `cost` DECIMAL(12,2) NOT NULL,
      `in_service_date` DATE DEFAULT NULL,   -- Date of Service Initiated (Vehicle reached in garage)
      `out_service_date` DATE DEFAULT NULL,  -- Date of Service Completion 
      `workshop_details` VARCHAR(512) DEFAULT NULL,
      `next_due_date` DATE DEFAULT NULL,     -- Next Due Date (if Any)
      `remarks` VARCHAR(512) DEFAULT NULL,
      `status` ENUM('Approved','Pending','Rejected') NOT NULL DEFAULT 'Pending',
      `approved_by` BIGINT UNSIGNED DEFAULT NULL,
      `approved_at` TIMESTAMP NULL DEFAULT NULL,
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_vm_vehicle_service_request` FOREIGN KEY (`vehicle_service_request_id`) REFERENCES `tpt_vehicle_service_request`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_vm_approvedBy` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_trip_incidents` (
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `trip_id` BIGINT UNSIGNED NOT NULL,
      `incident_time` TIMESTAMP NOT NULL,
      `incident_type` BIGINT UNSIGNED NOT NULL,
      `severity` ENUM('LOW','MEDIUM','HIGH') DEFAULT 'MEDIUM',
      `latitude` DECIMAL(10,7) DEFAULT NULL,
      `longitude` DECIMAL(10,7) DEFAULT NULL,
      `description` VARCHAR(512) DEFAULT NULL,
      `status` BIGINT UNSIGNED DEFAULT NULL,
      `raised_by` BIGINT UNSIGNED DEFAULT NULL,  -- fk to sys_users
      `raised_at` TIMESTAMP NULL DEFAULT NULL,    -- When Incident is Raised
      `resolved_at` TIMESTAMP NULL DEFAULT NULL,  -- When Incident is Resolved
      `resolved_by` BIGINT UNSIGNED DEFAULT NULL,  -- fk to sys_users
      `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      CONSTRAINT `fk_ti_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_ti_raisedBy` FOREIGN KEY (`raised_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_ti_resolvedBy` FOREIGN KEY (`resolved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tpt_student_boarding_log` (
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `trip_date` DATE NOT NULL,
      `student_id` BIGINT UNSIGNED DEFAULT NULL,      -- FK to tpt_students
      `student_session_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tpt_student_session
      `boarding_route_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tpt_routes
      `boarding_trip_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to tpt_trip
      `boarding_stop_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to tpt_pickup_points
      `boarding_time` DATETIME DEFAULT NULL,
      `unboarding_route_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tpt_routes
      `unboarding_trip_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to tpt_trip
      `unboarding_stop_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to tpt_pickup_points
      `unboarding_time` DATETIME DEFAULT NULL,
      `device_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tpt_attendance_device
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_session_id` BIGINT UNSIGNED DEFAULT NULL,
      `trip_id` BIGINT UNSIGNED DEFAULT NULL,
      `boarding_stop_id` BIGINT UNSIGNED DEFAULT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vendor_name` VARCHAR(100) NOT NULL,
      `vendor_type_id` BIGINT UNSIGNED NOT NULL,  -- FK to sys_dropdown_table (e.g., 'Transport', 'Canteen', 'Security')
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `item_code` VARCHAR(50) DEFAULT NULL,       -- SKU or Internal Item Code (Can be used for barcode printing)
      `item_name` VARCHAR(100) NOT NULL,
      `item_type` ENUM('SERVICE', 'PRODUCT') NOT NULL,
      `item_nature` ENUM('CONSUMABLE', 'ASSET', 'SERVICE', 'NA') NOT NULL DEFAULT 'NA', -- Inventory Hook
      `category_id` BIGINT UNSIGNED NOT NULL,     -- FK to sys_dropdown_table (e.g., 'Stationery', 'Bus Rental', 'Plumbing')
      `unit_id` BIGINT UNSIGNED NOT NULL,         -- FK to sys_dropdown_table (e.g., 'Km', 'Day', 'Month', 'Piece', 'Visit')
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vendor_id` BIGINT UNSIGNED NOT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `agreement_id` BIGINT UNSIGNED NOT NULL,
      `item_id` BIGINT UNSIGNED NOT NULL,
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
      `related_entity_type` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sys_dropdown_table ('Vehicle', 'Asset', 'Service', etc.)
      `related_entity_table` VARCHAR(60) DEFAULT NULL, -- e.g., tpt_vehicle, sch_asset, sch_service, etc.
      `related_entity_id` BIGINT UNSIGNED DEFAULT NULL, -- e.g., vehicle_id, asset_id, service_id, etc.
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vendor_id` BIGINT UNSIGNED NOT NULL,
      `agreement_item_id` BIGINT UNSIGNED NOT NULL, -- Optional, can map to specific agreement line
      `usage_date` DATE NOT NULL,
      `qty_used` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,  -- Quantity used e.g. Vehicle distance(Km), hours, etc.
      `remarks` VARCHAR(255) DEFAULT NULL,
      `logged_by` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_users (will be NULL for auto log)
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vendor_id` BIGINT UNSIGNED NOT NULL,
      `agreement_id` BIGINT UNSIGNED DEFAULT NULL, -- Optional, if invoice covers one agreement
      `agreement_item_id` BIGINT UNSIGNED DEFAULT NULL, -- Optional, if invoice covers one agreement item
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
      `status` BIGINT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (Approval Pending, Approved, Payment Pending, Paid, Overdue)
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `vendor_id` BIGINT UNSIGNED NOT NULL,
      `invoice_id` BIGINT UNSIGNED NOT NULL,
      `payment_date` DATE NOT NULL,
      `amount` DECIMAL(14, 2) NOT NULL,
      `payment_mode` BIGINT UNSIGNED NOT NULL, -- FK sys_dropdown (Cheque, NEFT, Cash)
      `reference_no` VARCHAR(100) DEFAULT NULL, -- Trx ID, Cheque No
      `status` ENUM('INITIATED', 'SUCCESS', 'FAILED') DEFAULT 'SUCCESS',
      `paid_by` BIGINT UNSIGNED DEFAULT NULL, -- FK sys_users
      `reconciled` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0, -- 0: Not Reconciled, 1: Reconciled
      `reconciled_by` BIGINT UNSIGNED DEFAULT NULL, -- FK sys_users
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `parent_id` BIGINT UNSIGNED DEFAULT NULL, -- NULL = Main Category, Value = Sub-category
    `name` VARCHAR(100) NOT NULL, -- e.g. "Transport", "Academic", "Rash Driving"
    `code` VARCHAR(30) DEFAULT NULL, -- Optional short code e.g. "TPT", "ACAD", "RASH_DRIVE"
    `description` VARCHAR(512) DEFAULT NULL,
    `severity_level_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table (1-10) e.g. "1-Low", "2-Medium", "3-High", "10-Critical"
    `priority_score_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table (1-5) e.g. 1=Critical, 2=Urgent, 3=High, 4=Medium, 5=Low
    `default_expected_resolution_hours` INT UNSIGNED NOT NULL,  -- This must be less than escalation_l1_hours
    `default_escalation_hours_l1` INT UNSIGNED NOT NULL, -- Time before escalating to L1 (This must be less than escalation_l2_hours)
    `default_escalation_hours_l2` INT UNSIGNED NOT NULL, -- Time before escalating to L2 (This must be less than escalation_l3_hours)
    `default_escalation_hours_l3` INT UNSIGNED NOT NULL, -- Time before escalating to L3 (This must be less than escalation_l4_hours)
    `default_escalation_hours_l4` INT UNSIGNED NOT NULL, -- Time before escalating to L4 (This must be less than escalation_l5_hours)
    `default_escalation_hours_l5` INT UNSIGNED NOT NULL, -- Time before escalating to L5
    `default_escalation_l1_entity_group_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `default_escalation_l2_entity_group_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `default_escalation_l3_entity_group_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `default_escalation_l4_entity_group_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `default_escalation_l5_entity_group_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `complaint_category_id` BIGINT UNSIGNED NOT NULL,       -- FK to cmp_complaint_categories
    `complaint_subcategory_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to cmp_complaint_categories (if sub-category is Null then it will be applied to all sub-categories exept those defined in the sub-category)
  -- Group wise SLA
    `target_department_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_departments
    `target_designation_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to sys_designations
    `target_role_id` BIGINT UNSIGNED DEFAULT NULL,          -- FK to sys_roles
    `target_entity_group_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sys_groups
  -- User wise SLA
    `target_user_id` BIGINT UNSIGNED DEFAULT NULL,          -- FK to sys_users
  -- Vehicle wise SLA
    `target_vehicle_id` BIGINT UNSIGNED DEFAULT NULL,       -- FK to sys_vehicles
  -- Vendor wise SLA
    `target_vendor_id` BIGINT UNSIGNED DEFAULT NULL,        -- FK to tpt_vendor
  -- SLA (Expected Resolution Time & Escalation Time)
    `dept_expected_resolution_hours` INT UNSIGNED NOT NULL, -- This must be less than escalation_l1_hours
    `dept_escalation_hours_l1` INT UNSIGNED NOT NULL,       -- Time before escalating to L1 (This must be less than escalation_l2_hours)
    `dept_escalation_hours_l2` INT UNSIGNED NOT NULL,       -- Time before escalating to L2 (This must be less than escalation_l3_hours)
    `dept_escalation_hours_l3` INT UNSIGNED NOT NULL,       -- Time before escalating to L3 (This must be less than escalation_l4_hours)
    `dept_escalation_hours_l4` INT UNSIGNED NOT NULL,       -- Time before escalating to L4 (This must be less than escalation_l5_hours)
    `dept_escalation_hours_l5` INT UNSIGNED NOT NULL,       -- Time before escalating to L5
    `escalation_l1_entity_group_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `escalation_l2_entity_group_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `escalation_l3_entity_group_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `escalation_l4_entity_group_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
    `escalation_l5_entity_group_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_groups
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ticket_no` VARCHAR(30) NOT NULL, -- Auto-generated unique ticket ID (e.g., CMP-2025-0001)
    `ticket_date` DATE NOT NULL DEFAULT CURRENT_DATE(), -- Date when the complaint was raised
    -- Complainant Info (Who raised it)
    `complainant_type_id` BIGINT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (Parent, Student, Staff, Vendor, Anonymous, Public)
    `complainant_user_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_users (NULL if Public/Anonymous)
    `complainant_name` VARCHAR(100) DEFAULT NULL, -- Captured if not a system user (Public/Anonymous)
    `complainant_contact` VARCHAR(50) DEFAULT NULL, -- Captured if not a system user (Public/Anonymous)
    -- Target Entity (Against whom/what)
    `target_user_type_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table (1=Student, 2=Staff, 3=Group, 4=Department, 5=Role, 6=Designation, 7=Facility, 8=Vehicle, 9=Event, 10=Location, 11-Vendor, 12-Other)
    `target_table_name` VARCHAR(60) DEFAULT NULL, -- e.g. "sch_class", "sch_section", "sch_subject", "sch_designation", "sch_department", "sch_role", "sch_students", "sch_staff", "sch_vehicle", "sch_facility", "sch_event", "sch_location", "sch_other"
    `target_selected_id` BIGINT UNSIGNED DEFAULT NULL, -- Foriegn Key will be managed at Application Level as it will be different for different entities e.g. sch_class, sch_section, sch_subject, sch_students, sch_staff, sch_vehicle etc.
    `target_code` VARCHAR(50) DEFAULT NULL, -- Optional short code e.g. "Transport", "Academic", "Account Manager"
    `target_name` VARCHAR(100) DEFAULT NULL, -- Optional name e.g. "Transport", "Academic", "Account Manager"
    -- Complaint Classification
    `category_id` BIGINT UNSIGNED NOT NULL, -- FK to cmp_complaint_categories
    `subcategory_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to cmp_complaint_categories
    `severity_level_id` BIGINT UNSIGNED NOT NULL, -- It will not be asked to Complaint Form but will be auto fetched from 'cmp_complaint_categories' table
    `priority_score_id` BIGINT UNSIGNED NOT NULL, -- It will not be asked to Complaint Form but will be auto fetched from 'cmp_complaint_categories' table
    -- Complaint Content
    `title` VARCHAR(200) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `location_details` VARCHAR(255) DEFAULT NULL, -- Where did it happen?
    `incident_date` DATETIME DEFAULT NULL,
    `incident_time` TIME DEFAULT NULL,
    -- Status & Resolution
    `status_id` BIGINT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (Open, In-Progress, Escalated, Resolved, Closed, Rejected)
    `assigned_to_role_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_roles (Current Role handling it)
    `assigned_to_user_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_users (Specific Officer)
    `resolution_due_at` DATETIME DEFAULT NULL, -- Calculated from 'cmp_department_sla'. If not available then use 'default_expected_resolution_hours' from 'cmp_complaint_categories'.
    `actual_resolved_at` DATETIME DEFAULT NULL, -- When it was actually resolved
    `resolved_by_role_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_roles (Role who resolved it)
    `resolved_by_user_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_users (Officer who resolved it)
    `resolution_summary` TEXT DEFAULT NULL,
    -- Escalation
    `is_escalated` TINYINT(1) DEFAULT 0,
    `current_escalation_level` TINYINT UNSIGNED DEFAULT 0, -- 0=None, 1=L1, 2=L2...
    -- Meta
    `source_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table (App, Web, Email, Walk-in, Call)
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `complaint_id` BIGINT UNSIGNED NOT NULL,
    `action_type_id` BIGINT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (Created, Assigned, Comment, StatusChange, Investigation, Escalated, Resolved)
    `performed_by_user_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_users (NULL for System)
    `performed_by_role_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_roles (NULL for System)
    `assigned_to_user_id` BIGINT UNSIGNED DEFAULT NULL, -- If reassigned
    `assigned_to_role_id` BIGINT UNSIGNED DEFAULT NULL, -- If reassigned
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `complaint_id` BIGINT UNSIGNED NOT NULL,
    `check_type_id` BIGINT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (AlcoholTest, DrugTest, FitnessCheck)
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `complaint_id` BIGINT UNSIGNED NOT NULL,
    `sentiment_score` DECIMAL(4,3) DEFAULT NULL, -- -1.0 (Negative) to +1.0 (Positive) calculated by AI e.g. -0.8
    `sentiment_label_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table (Angry, Urgent, Calm, Neutral) calculated by AI e.g. Angry
    `escalation_risk_score` DECIMAL(5,2) DEFAULT NULL, -- 0-100% Probability calculated by AI e.g. 80% 
    `predicted_category_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to cmp_complaint_categories calculated by AI e.g. Rash Driving
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
        `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
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
        `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        `source_module` VARCHAR(50) NOT NULL,
        -- Triggering module: Exam, Fee, Transport, Complaint etc
        `notification_event` VARCHAR(50) NOT NULL,
        -- Triggering event: Student Registered, Student Promoted, Exam Result Published, Fee Payment Reminder etc
        `title` VARCHAR(255) NOT NULL,
        -- Notification title
        `description` VARCHAR(512) NULL,
        -- Notification description
        `template_id` BIGINT UNSIGNED NULL,
        -- Template ID
        `priority_id` BIGINT UNSIGNED NOT NULL,
        -- fk to sys_dropdown_table e.g. 'LOW, NORMAL, HIGH, URGENT'
        `confidentiality_level_id` BIGINT UNSIGNED NOT NULL,
        -- fk to sys_dropdown_table e.g. 'PUBLIC, RESTRICTED, CONFIDENTIAL'
        `scheduled_at` DATETIME NULL,
        -- Scheduled time for notifications
        `recurring` TINYINT(1) DEFAULT 0,
        -- 0: One Time, 1: Recurring
        `recurring_interval_id` BIGINT UNSIGNED NULL,
        -- fk to sys_dropdown_table e.g. 'HOURLY, DAILY, WEEKLY, MONTHLY, QUARTERLY, YEARLY'
        `recurring_end_at` DATETIME NULL,
        -- End date or time for recurring notifications
        `recurring_end_count` INT NULL,
        -- End count for recurring notifications
        `expires_at` DATETIME NULL,
        -- Expiry date or time for notifications
        `created_by` BIGINT UNSIGNED NOT NULL,
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
        `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        `notification_id` BIGINT UNSIGNED NOT NULL,
        `channel_id` BIGINT UNSIGNED NOT NULL,
        -- fk to ntf_channel_master
        `provider_id` BIGINT UNSIGNED NULL,
        -- fk to sys_dropdown_table e.g. 'MSG91, Twilio, AWS SES, Meta API'
        `status_id` BIGINT UNSIGNED NOT NULL,
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
        `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        `notification_id` BIGINT UNSIGNED NOT NULL,
        `target_type_id` BIGINT UNSIGNED NOT NULL,
        -- FK to sys_dropdown_table e.g. USER, ROLE, DEPARTMENT, DESIGNATION, CLASS, SECTION, SUBJECT, ENTITY_GROUP, ENTIRE_SCHOOL
        `target_table_name` VARCHAR(60) DEFAULT NULL,
        -- e.g. sys_user, sys_role, sch_department, sch_designation, sch_classes, sch_sections, sch_subjects, sch_entity_groups, sch_staff_groups
        `target_selected_id` BIGINT UNSIGNED NULL,
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
        `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        `user_id` BIGINT UNSIGNED NOT NULL,
        `channel_id` BIGINT UNSIGNED NOT NULL,
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
        `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        `template_code` VARCHAR(50) NOT NULL,
        `channel_id` BIGINT UNSIGNED NOT NULL,
        -- fk to ntf_channel_master
        `subject` VARCHAR(255) NULL,
        -- 'Used for Email'
        `body` TEXT NOT NULL,
        -- 'Supports {{placeholders}}'
        `language_code` VARCHAR(10) DEFAULT 'en',
        `media_id` BIGINT UNSIGNED NULL,
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
        `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        `notification_id` BIGINT UNSIGNED NOT NULL,
        `channel_id` BIGINT UNSIGNED NOT NULL,
        -- fk to ntf_channel_master
        `template_id` BIGINT UNSIGNED NOT NULL,
        -- fk to ntf_templates
        `notification_target_id` BIGINT UNSIGNED NOT NULL,
        -- fk to ntf_notification_targets
        `user_preference_id` BIGINT UNSIGNED NOT NULL,
        -- fk to ntf_user_preferences
        `resolved_user_id` BIGINT UNSIGNED NOT NULL,
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
        `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        `notification_id` BIGINT UNSIGNED NOT NULL,
        `channel_id` BIGINT UNSIGNED NOT NULL,
        -- fk to ntf_channel_master
        `notification_target_id` BIGINT UNSIGNED NOT NULL,
        -- New
        `resolved_user_id` BIGINT UNSIGNED NOT NULL,
        `delivery_status_id` BIGINT UNSIGNED NOT NULL,
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

-- =========================================================================
-- 8-TIMETABLE MODULE (tt)
-- =========================================================================
  -- ------------------------------------------------------
  --  SECTION 0: MASTER CONFIGURATION TABLES
  -- ------------------------------------------------------

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

  -- ------------------------------------------------------
  --  SECTION 1: PERIOD SET CONFIGURATION
  -- ------------------------------------------------------

    CREATE TABLE IF NOT EXISTS `tt_period_set` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `code` VARCHAR(30) NOT NULL,
      `name` VARCHAR(100) NOT NULL,
      `description` VARCHAR(255) DEFAULT NULL,
      `total_periods` TINYINT UNSIGNED NOT NULL,
      `teaching_periods` TINYINT UNSIGNED NOT NULL,
      `start_time` TIME NOT NULL,
      `end_time` TIME NOT NULL,
      `applicable_class_ids` JSON DEFAULT NULL,
      `is_default` TINYINT(1) DEFAULT 0,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_periodset_code` (`code`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tt_period_set_period_jnt` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `period_set_id` BIGINT UNSIGNED NOT NULL,
      `period_type_id` BIGINT UNSIGNED NOT NULL,
      `code` VARCHAR(20) NOT NULL,
      `short_name` VARCHAR(10) DEFAULT NULL,
      `period_ord` TINYINT UNSIGNED NOT NULL,
      `start_time` TIME NOT NULL,
      `end_time` TIME NOT NULL,
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

  -- ------------------------------------------------------
  --  SECTION 2: TIMETABLE TYPE (Merges tt_school_timing_profile)
  -- ------------------------------------------------------

    CREATE TABLE IF NOT EXISTS `tt_timetable_type` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `code` VARCHAR(30) NOT NULL,   -- e.g., 'Standard', 'Extended'
      `name` VARCHAR(100) NOT NULL,
      `description` VARCHAR(255) DEFAULT NULL,
      `shift_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to tt_shift.id
      `default_period_set_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to tt_period_set.id
      `day_type_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to tt_day_type.id
      `effective_from_date` DATE DEFAULT NULL,  -- Start date for this timetable type
      `effective_to_date` DATE DEFAULT NULL,    -- End date for this timetable type
      `school_start_time` TIME DEFAULT NULL,    -- School start time
      `school_end_time` TIME DEFAULT NULL,      -- School end time
      `assembly_duration_min` SMALLINT UNSIGNED DEFAULT NULL,  -- Assembly duration in minutes
      `short_break_duration_min` SMALLINT UNSIGNED DEFAULT NULL,  -- Default break duration 
      `lunch_duration_min` SMALLINT UNSIGNED DEFAULT NULL,  -- Lunch duration
      `has_exam` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether this timetable type has exams
      `has_teaching` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this timetable type has teaching
      `ordinal` SMALLINT UNSIGNED DEFAULT 1,  -- Order of this timetable type
      `is_default` TINYINT(1) DEFAULT 0,  -- Whether this timetable type is the default
      `is_system` TINYINT(1) DEFAULT 1,  -- Whether this timetable type is a system-defined type
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_tttype_code` (`code`),
      KEY `idx_tttype_shift` (`shift_id`),
      KEY `idx_tttype_effective` (`effective_from_date`, `effective_to_date`),
      CONSTRAINT `fk_tttype_shift` FOREIGN KEY (`shift_id`) REFERENCES `tt_shift` (`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_tttype_period_set` FOREIGN KEY (`default_period_set_id`) REFERENCES `tt_period_set` (`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_tttype_day_type` FOREIGN KEY (`day_type_id`) REFERENCES `tt_day_type` (`id`) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ------------------------------------------------------
  --  SECTION 3: CLASS & STUDENT GROUPING
  -- ------------------------------------------------------

    CREATE TABLE IF NOT EXISTS `tt_class_mode_rule` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `class_id` INT UNSIGNED NOT NULL,
      `timetable_type_id` BIGINT UNSIGNED NOT NULL,
      `period_set_id` BIGINT UNSIGNED NOT NULL,
      `academic_session_id` BIGINT UNSIGNED DEFAULT NULL,
      `allow_teaching` TINYINT(1) NOT NULL DEFAULT 1,
      `allow_exam` TINYINT(1) NOT NULL DEFAULT 0,
      `exam_period_count` TINYINT UNSIGNED DEFAULT NULL,
      `teaching_after_exam` TINYINT(1) NOT NULL DEFAULT 0,
      `effective_from` DATE DEFAULT NULL,
      `effective_to` DATE DEFAULT NULL,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_cmr_class_mode_session` (`class_id`, `timetable_type_id`, `academic_session_id`),
      KEY `idx_cmr_mode` (`timetable_type_id`),
      CONSTRAINT `fk_cmr_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_cmr_mode` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_type` (`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_cmr_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_set` (`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_cmr_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE SET NULL
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

    CREATE TABLE IF NOT EXISTS `tt_class_subgroup_member` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `class_subgroup_id` BIGINT UNSIGNED NOT NULL,
      `class_id` INT UNSIGNED NOT NULL,
      `section_id` INT UNSIGNED DEFAULT NULL,
      `is_primary` TINYINT(1) DEFAULT 0,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_csm_subgroup_class_section` (`class_subgroup_id`, `class_id`, `section_id`),
      CONSTRAINT `fk_csm_subgroup` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroup` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_csm_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_csm_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tt_class_group_requirement` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

      `class_group_id` BIGINT UNSIGNED DEFAULT NULL,
      `class_subgroup_id` BIGINT UNSIGNED DEFAULT NULL,
      `academic_session_id` BIGINT UNSIGNED DEFAULT NULL,
      `weekly_periods` TINYINT UNSIGNED NOT NULL,  -- Total periods required per week
      `min_periods_per_week` TINYINT UNSIGNED DEFAULT NULL,  -- Minimum periods required per week
      `max_periods_per_week` TINYINT UNSIGNED DEFAULT NULL,  -- Maximum periods required per week
      `max_per_day` TINYINT UNSIGNED DEFAULT NULL,  -- Maximum periods per day
      `min_per_day` TINYINT UNSIGNED DEFAULT NULL,  -- Minimum periods per day
      `min_gap_periods` TINYINT UNSIGNED DEFAULT NULL,  -- Minimum gap periods
      `allow_consecutive` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether consecutive periods are allowed
      `max_consecutive` TINYINT UNSIGNED DEFAULT 2,  -- Maximum consecutive periods
      `preferred_periods_json` JSON DEFAULT NULL,  -- Preferred periods
      `avoid_periods_json` JSON DEFAULT NULL,  -- Avoid periods
      `spread_evenly` TINYINT(1) DEFAULT 1,  -- Whether periods should be spread evenly
      `priority` SMALLINT UNSIGNED DEFAULT 50,  -- Priority of this requirement
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this requirement is active
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_cgr_group_session` (`class_group_id`, `class_subgroup_id`, `academic_session_id`),
      CONSTRAINT `fk_cgr_class_group` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_cgr_subgroup` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroup` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_cgr_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE SET NULL,
      CONSTRAINT `chk_cgr_target` CHECK ((`class_group_id` IS NOT NULL AND `class_subgroup_id` IS NULL) OR (`class_group_id` IS NULL AND `class_subgroup_id` IS NOT NULL))
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  -- ------------------------------------------------------
  --  SECTION 4: ACTIVITY MANAGEMENT
  -- ------------------------------------------------------
    -- TERMINOLOGY:
    -- duration_periods = Consecutive slots (Lab=2) | weekly_periods = Times/week
    -- priority = User importance | difficulty_score = Algorithm metric

    CREATE TABLE IF NOT EXISTS `tt_activity` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `uuid` BINARY(16) NOT NULL,
      `code` VARCHAR(50) NOT NULL,
      `name` VARCHAR(200) NOT NULL,
      `description` VARCHAR(500) DEFAULT NULL,
      `academic_session_id` BIGINT UNSIGNED NOT NULL,
      `class_group_id` BIGINT UNSIGNED DEFAULT NULL,
      `class_subgroup_id` BIGINT UNSIGNED DEFAULT NULL,
      `subject_id` BIGINT UNSIGNED DEFAULT NULL,
      `study_format_id` INT UNSIGNED DEFAULT NULL,
      `duration_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,
      `weekly_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,
      `total_periods` SMALLINT UNSIGNED GENERATED ALWAYS AS (`duration_periods` * `weekly_periods`) STORED,
      `split_allowed` TINYINT(1) DEFAULT 0,
      `is_compulsory` TINYINT(1) DEFAULT 1,
      `priority` TINYINT UNSIGNED DEFAULT 50,
      `difficulty_score` TINYINT UNSIGNED DEFAULT 50,
      `requires_room` TINYINT(1) DEFAULT 1,
      `preferred_room_type_id` INT UNSIGNED DEFAULT NULL,
      `preferred_room_ids` JSON DEFAULT NULL,
      `status` ENUM('DRAFT','ACTIVE','LOCKED','ARCHIVED') NOT NULL DEFAULT 'ACTIVE',
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_by` BIGINT UNSIGNED DEFAULT NULL,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_activity_uuid` (`uuid`),
      UNIQUE KEY `uq_activity_code` (`code`),
      KEY `idx_activity_session` (`academic_session_id`),
      KEY `idx_activity_class_group` (`class_group_id`),
      KEY `idx_activity_subgroup` (`class_subgroup_id`),
      KEY `idx_activity_subject` (`subject_id`),
      KEY `idx_activity_status` (`status`),
      CONSTRAINT `fk_activity_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_activity_class_group` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_activity_subgroup` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroup` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_activity_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_activity_study_format` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_activity_room_type` FOREIGN KEY (`preferred_room_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_activity_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
      -- Must have either class_group or subgroup
      CONSTRAINT `chk_activity_target` CHECK ((`class_group_id` IS NOT NULL AND `class_subgroup_id` IS NULL) OR (`class_group_id` IS NULL AND `class_subgroup_id` IS NOT NULL))
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tt_activity_teacher` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `activity_id` BIGINT UNSIGNED NOT NULL,  -- Activity ID
      `teacher_id` BIGINT UNSIGNED NOT NULL,  -- Teacher ID
      `assignment_role_id` BIGINT UNSIGNED NOT NULL,  -- Assignment role ID
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

    CREATE TABLE IF NOT EXISTS `tt_sub_activity` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `parent_activity_id` BIGINT UNSIGNED NOT NULL,
      `sub_activity_ord` TINYINT UNSIGNED NOT NULL,
      `code` VARCHAR(60) NOT NULL,
      `duration_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,
      `same_day_as_parent` TINYINT(1) DEFAULT 0,
      `consecutive_with_previous` TINYINT(1) DEFAULT 0,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_subact_parent_ord` (`parent_activity_id`, `sub_activity_ord`),
      UNIQUE KEY `uq_subact_code` (`code`),
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ------------------------------------------------------
  --  SECTION 5: CONSTRAINT ENGINE
  -- ------------------------------------------------------

    CREATE TABLE IF NOT EXISTS `tt_constraint_type` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `code` VARCHAR(60) NOT NULL,
      `name` VARCHAR(150) NOT NULL,
      `description` TEXT DEFAULT NULL,
      `category` ENUM('TIME','SPACE','TEACHER','STUDENT','ACTIVITY','ROOM') NOT NULL,
      `scope` ENUM('GLOBAL','TEACHER','STUDENT','ROOM','ACTIVITY','CLASS','CLASS_SUBJECT','STUDY_FORMAT','SUBJECT','STUDENT_SET','CLASS_GROUP','CLASS_SUBGROUP') NOT NULL,
      `default_weight` TINYINT UNSIGNED DEFAULT 100,
      `is_hard_capable` TINYINT(1) DEFAULT 1,
      `param_schema` JSON DEFAULT NULL,
      `is_system` TINYINT(1) DEFAULT 1,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_ctype_code` (`code`),
      KEY `idx_ctype_category` (`category`),
      KEY `idx_ctype_scope` (`scope`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tt_constraint` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `uuid` BINARY(16) NOT NULL,
      `constraint_type_id` BIGINT UNSIGNED NOT NULL,
      `name` VARCHAR(200) DEFAULT NULL,
      `description` VARCHAR(500) DEFAULT NULL,
      `academic_session_id` BIGINT UNSIGNED DEFAULT NULL,
      `target_type` ENUM('GLOBAL','TEACHER','STUDENT_SET','ROOM','ACTIVITY','CLASS','SUBJECT','STUDY_FORMAT','CLASS_GROUP','CLASS_SUBGROUP') NOT NULL,
      `target_id` BIGINT UNSIGNED DEFAULT NULL,
      `is_hard` TINYINT(1) NOT NULL DEFAULT 0,
      `weight` TINYINT UNSIGNED NOT NULL DEFAULT 100,
      `params_json` JSON NOT NULL,
      `effective_from` DATE DEFAULT NULL,
      `effective_to` DATE DEFAULT NULL,
      `applies_to_days_json` JSON DEFAULT NULL,
      `status` ENUM('DRAFT','ACTIVE','DISABLED') NOT NULL DEFAULT 'ACTIVE',
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_by` BIGINT UNSIGNED DEFAULT NULL,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_constraint_uuid` (`uuid`),
      KEY `idx_constraint_type` (`constraint_type_id`),
      KEY `idx_constraint_target` (`target_type`, `target_id`),
      KEY `idx_constraint_session` (`academic_session_id`),
      KEY `idx_constraint_status` (`status`),
      CONSTRAINT `fk_constraint_type` FOREIGN KEY (`constraint_type_id`) REFERENCES `tt_constraint_type` (`id`) ON DELETE RESTRICT,
      CONSTRAINT `fk_constraint_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_constraint_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tt_teacher_unavailable` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `teacher_id` BIGINT UNSIGNED NOT NULL,
      `constraint_id` BIGINT UNSIGNED DEFAULT NULL,
      `day_of_week` TINYINT UNSIGNED NOT NULL,
      `period_ord` TINYINT UNSIGNED DEFAULT NULL,
      `start_date` DATE DEFAULT NULL,
      `end_date` DATE DEFAULT NULL,
      `reason` VARCHAR(255) DEFAULT NULL,
      `is_recurring` TINYINT(1) DEFAULT 1,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      KEY `idx_tu_teacher` (`teacher_id`),
      KEY `idx_tu_day_period` (`day_of_week`, `period_ord`),
      CONSTRAINT `fk_tu_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_tu_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraint` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tt_room_unavailable` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `room_id` INT UNSIGNED NOT NULL,
      `constraint_id` BIGINT UNSIGNED DEFAULT NULL,
      `day_of_week` TINYINT UNSIGNED NOT NULL,
      `period_ord` TINYINT UNSIGNED DEFAULT NULL,
      `start_date` DATE DEFAULT NULL,
      `end_date` DATE DEFAULT NULL,
      `reason` VARCHAR(255) DEFAULT NULL,
      `is_recurring` TINYINT(1) DEFAULT 1,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      KEY `idx_ru_room` (`room_id`),
      KEY `idx_ru_day_period` (`day_of_week`, `period_ord`),
      CONSTRAINT `fk_ru_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_ru_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraint` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ------------------------------------------------------
  --  SECTION 6: TIMETABLE GENERATION & STORAGE
  -- ------------------------------------------------------

    CREATE TABLE IF NOT EXISTS `tt_timetable` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `uuid` BINARY(16) NOT NULL,
      `code` VARCHAR(50) NOT NULL,
      `name` VARCHAR(200) NOT NULL,
      `description` TEXT DEFAULT NULL,
      `academic_session_id` BIGINT UNSIGNED NOT NULL,
      `timetable_type_id` BIGINT UNSIGNED NOT NULL,
      `period_set_id` BIGINT UNSIGNED NOT NULL,
      `effective_from` DATE NOT NULL,
      `effective_to` DATE DEFAULT NULL,
      `generation_method` ENUM('MANUAL','SEMI_AUTO','FULL_AUTO') NOT NULL DEFAULT 'MANUAL',
      `version` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
      `parent_timetable_id` BIGINT UNSIGNED DEFAULT NULL,
      `status` ENUM('DRAFT','GENERATING','GENERATED','PUBLISHED','ARCHIVED') NOT NULL DEFAULT 'DRAFT',
      `published_at` TIMESTAMP NULL DEFAULT NULL,
      `published_by` BIGINT UNSIGNED DEFAULT NULL,
      `constraint_violations` INT UNSIGNED DEFAULT 0,
      `soft_score` DECIMAL(8,2) DEFAULT NULL,
      `stats_json` JSON DEFAULT NULL,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_by` BIGINT UNSIGNED DEFAULT NULL,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_tt_uuid` (`uuid`),
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
      CONSTRAINT `fk_tt_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tt_constraint_violation` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `timetable_id` BIGINT UNSIGNED NOT NULL,
      `constraint_id` BIGINT UNSIGNED NOT NULL,
      `violation_type` ENUM('HARD','SOFT') NOT NULL,
      `violation_count` INT UNSIGNED NOT NULL,
      `violation_details` JSON DEFAULT NULL,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      KEY `idx_cv_timetable` (`timetable_id`),
      KEY `idx_cv_constraint` (`constraint_id`),
      CONSTRAINT `fk_cv_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_cv_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraint` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tt_generation_run` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `uuid` BINARY(16) NOT NULL,
      `timetable_id` BIGINT UNSIGNED NOT NULL,
      `run_number` INT UNSIGNED NOT NULL DEFAULT 1,
      `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `finished_at` TIMESTAMP NULL DEFAULT NULL,
      `status` ENUM('QUEUED','RUNNING','COMPLETED','FAILED','CANCELLED') NOT NULL DEFAULT 'QUEUED',
      `algorithm_version` VARCHAR(20) DEFAULT NULL,
      `max_recursion_depth` INT UNSIGNED DEFAULT 14,
      `max_placement_attempts` INT UNSIGNED DEFAULT NULL,
      `params_json` JSON DEFAULT NULL,
      `activities_total` INT UNSIGNED DEFAULT 0,
      `activities_placed` INT UNSIGNED DEFAULT 0,
      `activities_failed` INT UNSIGNED DEFAULT 0,
      `hard_violations` INT UNSIGNED DEFAULT 0,
      `soft_violations` INT UNSIGNED DEFAULT 0,
      `soft_score` DECIMAL(10,4) DEFAULT NULL,
      `stats_json` JSON DEFAULT NULL,
      `error_message` TEXT DEFAULT NULL,
      `triggered_by` BIGINT UNSIGNED DEFAULT NULL,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at` TIMESTAMP NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uq_gr_uuid` (`uuid`),
      UNIQUE KEY `uq_gr_tt_run` (`timetable_id`, `run_number`),
      KEY `idx_gr_status` (`status`),
      CONSTRAINT `fk_gr_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_gr_triggered_by` FOREIGN KEY (`triggered_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tt_timetable_cell` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `timetable_id` BIGINT UNSIGNED NOT NULL,
      `generation_run_id` BIGINT UNSIGNED DEFAULT NULL,
      `day_of_week` TINYINT UNSIGNED NOT NULL,
      `period_ord` TINYINT UNSIGNED NOT NULL,
      `cell_date` DATE DEFAULT NULL,
      `class_group_id` BIGINT UNSIGNED DEFAULT NULL,
      `class_subgroup_id` BIGINT UNSIGNED DEFAULT NULL,
      `activity_id` BIGINT UNSIGNED DEFAULT NULL,
      `sub_activity_id` BIGINT UNSIGNED DEFAULT NULL,
      `room_id` INT UNSIGNED DEFAULT NULL,
      `source` ENUM('AUTO','MANUAL','SWAP','LOCK') NOT NULL DEFAULT 'AUTO',
      `is_locked` TINYINT(1) NOT NULL DEFAULT 0,
      `locked_by` BIGINT UNSIGNED DEFAULT NULL,
      `locked_at` TIMESTAMP NULL DEFAULT NULL,
      `has_conflict` TINYINT(1) DEFAULT 0,
      `conflict_details_json` JSON DEFAULT NULL,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
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
      CONSTRAINT `fk_cell_subgroup` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroup` (`id`) ON DELETE CASCADE,
      CONSTRAINT `fk_cell_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_cell_sub_activity` FOREIGN KEY (`sub_activity_id`) REFERENCES `tt_sub_activity` (`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_cell_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`) ON DELETE SET NULL,
      CONSTRAINT `fk_cell_locked_by` FOREIGN KEY (`locked_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
      CONSTRAINT `chk_cell_target` CHECK ((`class_group_id` IS NOT NULL AND `class_subgroup_id` IS NULL) OR (`class_group_id` IS NULL AND `class_subgroup_id` IS NOT NULL))
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `tt_timetable_cell_teacher` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `cell_id` BIGINT UNSIGNED NOT NULL,
      `teacher_id` BIGINT UNSIGNED NOT NULL,
      `assignment_role_id` BIGINT UNSIGNED NOT NULL,
      `is_substitute` TINYINT(1) DEFAULT 0,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
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

  -- ------------------------------------------------------
  --  SECTION 7: SUBSTITUTION MANAGEMENT
  -- ------------------------------------------------------

    CREATE TABLE IF NOT EXISTS `tt_teacher_absence` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `teacher_id` BIGINT UNSIGNED NOT NULL,
      `absence_date` DATE NOT NULL,
      `absence_type` ENUM('LEAVE','SICK','TRAINING','OFFICIAL_DUTY','OTHER') NOT NULL,
      `start_period` TINYINT UNSIGNED DEFAULT NULL,
      `end_period` TINYINT UNSIGNED DEFAULT NULL,
      `reason` VARCHAR(500) DEFAULT NULL,
      `status` ENUM('PENDING','APPROVED','REJECTED','CANCELLED') NOT NULL DEFAULT 'PENDING',
      `approved_by` BIGINT UNSIGNED DEFAULT NULL,
      `approved_at` TIMESTAMP NULL DEFAULT NULL,
      `substitution_required` TINYINT(1) DEFAULT 1,
      `substitution_completed` TINYINT(1) DEFAULT 0,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
      `created_by` BIGINT UNSIGNED DEFAULT NULL,
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
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `teacher_absence_id` BIGINT UNSIGNED DEFAULT NULL,
      `cell_id` BIGINT UNSIGNED NOT NULL,
      `substitution_date` DATE NOT NULL,
      `absent_teacher_id` BIGINT UNSIGNED NOT NULL,
      `substitute_teacher_id` BIGINT UNSIGNED NOT NULL,
      `assignment_method` ENUM('AUTO','MANUAL','SWAP') NOT NULL DEFAULT 'MANUAL',
      `reason` VARCHAR(500) DEFAULT NULL,
      `status` ENUM('ASSIGNED','COMPLETED','CANCELLED') NOT NULL DEFAULT 'ASSIGNED',
      `notified_at` TIMESTAMP NULL DEFAULT NULL,
      `accepted_at` TIMESTAMP NULL DEFAULT NULL,
      `completed_at` TIMESTAMP NULL DEFAULT NULL,
      `feedback` TEXT DEFAULT NULL,
      `assigned_by` BIGINT UNSIGNED DEFAULT NULL,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
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

  -- ------------------------------------------------------
  --  SECTION 8: TEACHER WORKLOAD & ANALYTICS
  -- ------------------------------------------------------

    CREATE TABLE IF NOT EXISTS `tt_teacher_workload` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `teacher_id` BIGINT UNSIGNED NOT NULL,
      `academic_session_id` BIGINT UNSIGNED NOT NULL,
      `timetable_id` BIGINT UNSIGNED DEFAULT NULL,
      `weekly_periods_assigned` SMALLINT UNSIGNED DEFAULT 0,
      `weekly_periods_max` SMALLINT UNSIGNED DEFAULT NULL,
      `weekly_periods_min` SMALLINT UNSIGNED DEFAULT NULL,
      `daily_distribution_json` JSON DEFAULT NULL,
      `subjects_assigned_json` JSON DEFAULT NULL,
      `classes_assigned_json` JSON DEFAULT NULL,
      `utilization_percent` DECIMAL(5,2) DEFAULT NULL,
      `gap_periods_total` SMALLINT UNSIGNED DEFAULT 0,
      `consecutive_max` TINYINT UNSIGNED DEFAULT 0,
      `last_calculated_at` TIMESTAMP NULL DEFAULT NULL,
      `is_active` TINYINT(1) NOT NULL DEFAULT 1,
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

  -- ------------------------------------------------------
  --  SECTION 9: AUDIT & HISTORY
  -- ------------------------------------------------------

    CREATE TABLE IF NOT EXISTS `tt_change_log` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `timetable_id` BIGINT UNSIGNED NOT NULL,
      `cell_id` BIGINT UNSIGNED DEFAULT NULL,
      `change_type` ENUM('CREATE','UPDATE','DELETE','LOCK','UNLOCK','SWAP','SUBSTITUTE') NOT NULL,
      `change_date` DATE NOT NULL,
      `old_values_json` JSON DEFAULT NULL,
      `new_values_json` JSON DEFAULT NULL,
      `reason` VARCHAR(500) DEFAULT NULL,
      `changed_by` BIGINT UNSIGNED DEFAULT NULL,
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


-- =========================================================================
-- 9-SYLLABUS MODULE (slb)
-- =========================================================================

  -- We need to create Master table to capture slb_topic_type
  -- level: 0=Topic, 1=Sub-topic, 2=Mini Topic, 3=Sub-Mini Topic, 4=Micro Topic, 5=Sub-Micro Topic, 6=Nano Topic, 7=Ultra Topic,
  -- This table will be used to Generate slb_topics.code and slb_topics.analytics_code.
  -- User can Not change slb_topics.analytics_code, But he can change slb_topics.code as per their choice.
  -- This Table will be set by PG_Team and will not be available for change to School.
  CREATE TABLE IF NOT EXISTS `slb_topic_level_types` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,                       -- Unique identifier for analytics tracking
    `academic_session_id` BIGINT UNSIGNED NOT NULL, -- FK to sch_org_academic_sessions_jnt
    `class_id` INT UNSIGNED NOT NULL,               -- FK to sch_classes
    `subject_id` BIGINT UNSIGNED NOT NULL,          -- FK to sch_subjects
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,                       -- Unique analytics identifier e.g. '123e4567-e89b-12d3-a456-426614174000'
    `parent_id` BIGINT UNSIGNED DEFAULT NULL,       -- FK to self (NULL for root topics)
    `lesson_id` BIGINT UNSIGNED NOT NULL,           -- FK to slb_lessons
    `class_id` INT UNSIGNED NOT NULL,               -- Denormalized for fast queries
    `subject_id` BIGINT UNSIGNED NOT NULL,          -- Denormalized for fast queries
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
    `base_topic_id` BIGINT UNSIGNED DEFAULT NULL,   -- Primary prerequisite from previous class
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

  CREATE TABLE IF NOT EXISTS `slb_syllabus_schedule` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_session_id` BIGINT UNSIGNED NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,           -- FK to sch_classes.id. NULL = applies to all classes
    `section_id` INT UNSIGNED DEFAULT NULL,       -- FK to sch_sections.id. NULL = applies to all sections
    `subject_id` BIGINT UNSIGNED NOT NULL,       -- FK to sch_subjects.id
    `topic_id` BIGINT UNSIGNED NOT NULL,         -- FK to slb_topics.id
    `scheduled_start_date` DATE NOT NULL,
    `scheduled_end_date` DATE NOT NULL,
    `assigned_teacher_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to sch_teachers.id (who assigned to teach this topic)
    `taught_by_teacher_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to sch_teachers.id (who Actually taught this topic)
    `planned_periods` SMALLINT UNSIGNED DEFAULT NULL,  -- Number of periods planned for this topic
    `priority` ENUM('HIGH','MEDIUM','LOW') DEFAULT 'MEDIUM',
    `notes` VARCHAR(500) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` BIGINT UNSIGNED DEFAULT NULL,
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,                 -- Unique identifier for tracking ("INSERT INTO slb_questions_bank (uuid) VALUES (UUID_TO_BIN(UUID()))")
    `class_id` INT UNSIGNED NOT NULL,       --  fk -> sch_classes.id optional denormalized FK
    `subject_id` BIGINT UNSIGNED NOT NULL,  --  fk -> sch_subjects.id optional denormalized FK
    `lesson_id` INT UNSIGNED NOT NULL,      --  fk -> slb_lessons.id optional denormalized FK
    `topic_id` BIGINT UNSIGNED NOT NULL,    -- FK -> sch_topics.id (can be root topic or sub-topic depending on level)
    `competency_id` BIGINT UNSIGNED NOT NULL, -- FK to slb_competencies.id
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
    -- `ques_reviewed_by` BIGINT UNSIGNED DEFAULT NULL,            --  fk -> sch_users.id (if reviewed by teacher)
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
    `created_by` BIGINT UNSIGNED DEFAULT NULL,       -- fk -> sch_users.id or teachers.id. If created by AI then this will be NULL
    `is_school_specific` TINYINT(1) DEFAULT 0,       -- True if this question is school-specific
    -- QUESTIONS AVAILABILITY
    `availability` ENUM('GLOBAL','SCHOOL_ONLY','CLASS_ONLY','SECTION_ONLY','ENTITY_ONLY','STUDENT_ONLY') DEFAULT 'GLOBAL',  -- visibility of the question
    `selected_entity_group_id` BIGINT UNSIGNED DEFAULT NULL,  -- fk -> slb_entity_groups.id (if selected availability is 'ENTITY_ONLY')
    `selected_section_id` BIGINT UNSIGNED DEFAULT NULL,       -- fk -> sch_sections.id (if selected availability is 'SECTION_ONLY')
    `selected_student_id` BIGINT UNSIGNED DEFAULT NULL,       -- fk -> sch_students.id (if selected availability is 'STUDENT_ONLY')
    -- QUESTION SOURCE & REFERENCE
    `book_id` BIGINT UNSIGNED DEFAULT NULL,         -- book id (FK -> slb_books.id)
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `question_bank_id` BIGINT UNSIGNED NOT NULL,
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `question_bank_id` BIGINT UNSIGNED NOT NULL,          -- fk to qns_questions_bank.id
    `question_option_id` BIGINT UNSIGNED DEFAULT NULL,    -- fk to qns_question_options.id
    `media_purpose` ENUM('QUESTION','OPTION','QUES_EXPLANATION','OPT_EXPLANATION','RECOMMENDATION') DEFAULT 'QUESTION',
    `media_id` BIGINT UNSIGNED NOT NULL,                   -- fk to qns_media_store.id
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
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
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `question_bank_id` BIGINT UNSIGNED NOT NULL,
    `tag_id` BIGINT UNSIGNED NOT NULL,
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `question_bank_id` BIGINT UNSIGNED NOT NULL,
    `version` INT UNSIGNED NOT NULL,
    `data` JSON NOT NULL,                       -- full snapshot of question (Question_content, options, metadata)
    `version_created_by` BIGINT UNSIGNED DEFAULT NULL,
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
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `uuid` BINARY(16) NOT NULL,
    `owner_type` ENUM('QUESTION','OPTION','EXPLANATION','RECOMMENDATION') NOT NULL,
    `owner_id` BIGINT UNSIGNED NOT NULL,
    `media_type` ENUM('IMAGE','AUDIO','VIDEO','PDF') NOT NULL,
    `file_name` VARCHAR(255),
    `file_path` VARCHAR(255),
    `mime_type` VARCHAR(100),
    `disk` VARCHAR(50) DEFAULT NULL,     -- storage disk
    `size` BIGINT UNSIGNED DEFAULT NULL, -- file size in bytes
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
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `question_bank_id` BIGINT UNSIGNED NOT NULL,
    `topic_id` BIGINT UNSIGNED NOT NULL,
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
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `question_bank_id` BIGINT UNSIGNED NOT NULL,
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
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `question_bank_id` BIGINT UNSIGNED NOT NULL,
    `performance_category_id` BIGINT UNSIGNED NOT NULL,  -- FK to slb_performance_categories.id
    `recommendation_type` BIGINT UNSIGNED NOT NULL,  -- FK to sys_dropdowns table e.g. 'REVISION','PRACTICE','CHALLENGE'
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
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `question_bank_id` BIGINT UNSIGNED NOT NULL,    -- FK to qns_questions_bank
    `question_usage_type` BIGINT UNSIGNED NOT NULL, -- FK to qns_question_usage_type.id
    `context_id` BIGINT UNSIGNED NOT NULL,    -- quiz_id, assessment_id, exam_id - FK to sys_dropdowns table
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
      `review_log_id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `question_id` BIGINT UNSIGNED NOT NULL,  -- FK to qns_questions_bank.id
      `reviewer_id` BIGINT UNSIGNED NOT NULL,  -- FK to users.id
      `review_status_id` BIGINT UNSIGNED NOT NULL,  -- FK to sys_dropdowns.id e.g. 'PENDING','APPROVED','REJECTED'
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


-- ===========================================================================
-- 11-Recommendation (rec)
-- ===========================================================================
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

  -- TAB-2 : Recommendation Rules

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

  -- TAB-3 : Recommendation Rules

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

  -- TAB-4 : Recommendation Rules

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

  -- TAB-5 : Recommendation Rules

  -- table for "assessment_type" ENUM values
  CREATE TABLE IF NOT EXISTS `rec_assessment_types` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT DEFAULT NULL,
    -- Content Classification
    `material_type` BIGINT UNSIGNED DEFAULT NULL,    -- fk to sys_dropdown_table (e.g. 'TEXT','VIDEO','PDF','AUDIO','QUIZ','ASSIGNMENT','LINK','INTERACTIVE')
    `purpose` BIGINT UNSIGNED DEFAULT NULL,          -- fk to sys_dropdown_table (e.g. 'REVISION','PRACTICE','REMEDIAL','ADVANCED','ENRICHMENT','CONCEPT_BUILDING') NOT NULL DEFAULT 'PRACTICE',
    `complexity_level` BIGINT UNSIGNED DEFAULT NULL,  -- fk to slb_complexity_level
    -- Content Source
    `content_source` BIGINT UNSIGNED DEFAULT NULL,    -- fk to sys_dropdown_table (e.g. 'INTERNAL_EDITOR','UPLOADED_FILE','EXTERNAL_LINK','LMS_MODULE','QUESTION_BANK')
    `content_text` LONGTEXT DEFAULT NULL,           -- HTML content for 'TEXT' type or Internal Notes
    `file_url` VARCHAR(500) DEFAULT NULL,           -- Direct URL for 'UPLOADED_FILE' or 'PDF' or 'VIDEO'
    `external_url` VARCHAR(500) DEFAULT NULL,       -- YouTube link, Khan Academy link etc.
    `media_id` BIGINT UNSIGNED DEFAULT NULL,        -- fk to qns_media_store (for stored Media)
    -- Academic Mapping
    `subject_id` BIGINT UNSIGNED DEFAULT NULL,      -- FK to sch_subjects
    `class_id` INT UNSIGNED DEFAULT NULL,           -- FK to sch_classes (Target Class)
    `topic_id` BIGINT UNSIGNED DEFAULT NULL,        -- FK to slb_topics
    `competency_code` VARCHAR(50) DEFAULT NULL,     -- Optional link to Competency Framework
    -- Metadata
    `duration_seconds` INT UNSIGNED DEFAULT NULL,   -- Est. time to consume
    `language_code` VARCHAR(10) DEFAULT 'en',       -- e.g. 'en', 'hi'
    `tags` JSON DEFAULT NULL,                       -- Search tags
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` BIGINT UNSIGNED DEFAULT NULL,
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` BIGINT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_recBundle_school` (`school_id`),
    CONSTRAINT `fk_recBundle_school` FOREIGN KEY (`school_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- 2. Junction between Bundle and Materials
  CREATE TABLE IF NOT EXISTS `rec_bundle_materials_jnt` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bundle_id` BIGINT UNSIGNED NOT NULL,
    `material_id` BIGINT UNSIGNED NOT NULL,
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- Rule Definition
    `name` VARCHAR(150) NOT NULL,                   -- e.g. "Math Remedial for Poor Performers in Algebra"
    `is_automated` TINYINT(1) DEFAULT 1,            -- 1=Run by System Job, 0=Manual Helper Rule
    -- TRIGGERS (When to Apply)
    `trigger_event` BIGINT UNSIGNED NOT NULL,  -- FK to rec_trigger_events
    -- CONDITIONS (The "Switch")
    -- Narrowing Scope
    `class_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_classes
    `subject_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sch_subjects
    `topic_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to slb_topics
    -- Performance Criteria
    `performance_category_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to slb_performance_categories (The bucket, e.g. POOR)
    `min_score_pct` DECIMAL(5,2) DEFAULT NULL,      -- Specific override e.g. < 40%
    `max_score_pct` DECIMAL(5,2) DEFAULT NULL,      -- Specific override e.g. > 90%
    -- Assessment Type Filter (Only apply if the result came from this type of exam)
    `assessment_type` BIGINT UNSIGNED DEFAULT NULL,  -- FK to rec_assessment_types
    -- ACTION (What to Recommend)
    `recommendation_mode_id` BIGINT UNSIGNED NOT NULL,  -- FK to rec_recommendation_modes
    `target_material_id` BIGINT UNSIGNED DEFAULT NULL,  -- KF TO rec_recommendation_materials
    `target_bundle_id` BIGINT UNSIGNED DEFAULT NULL,    -- KF TO rec_recommendation_bundles
    `dynamic_material_type_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to rec_dynamic_material_types
    `dynamic_purpose_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to rec_dynamic_purposes
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,                       -- Unique ID for public access/tracking
    `student_id` BIGINT UNSIGNED NOT NULL,          -- FK to std_students (or users depending on arch. std_students preferred)
    -- Source of Recommendation
    `rule_id` BIGINT UNSIGNED DEFAULT NULL,         -- fk to rec_recommendation_rules. Which rule generated this?
    `triggered_by_result_id` BIGINT UNSIGNED DEFAULT NULL, -- Optional: Link to the Exam Result ID in Exam Module
    `manual_assigned_by` BIGINT UNSIGNED DEFAULT NULL,     -- If manually assigned by Teacher
    -- The Content
    `material_id` BIGINT UNSIGNED DEFAULT NULL,
    `bundle_id` BIGINT UNSIGNED DEFAULT NULL,
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,  -- UUID 
    `isbn` VARCHAR(20) DEFAULT NULL,              -- International Standard Book Number
    `title` VARCHAR(100) NOT NULL,
    `subtitle` VARCHAR(255) DEFAULT NULL,
    `description` VARCHAR(512) DEFAULT NULL,
    `edition` VARCHAR(50) DEFAULT NULL,           -- e.g., '5th Edition', 'Revised 2024'
    `publication_year` YEAR DEFAULT NULL,         -- e.g., 2024
    `publisher_name` VARCHAR(150) DEFAULT NULL,   -- e.g., 'NCERT', 'S.Chand', 'Pearson'
    `language` BIGINT UNSIGNED NOT NULL,          -- FK to sys_dropdown_table e.g "English", "Hindi", "Sanskrit"
    `total_pages` INT UNSIGNED DEFAULT NULL,
    `cover_image_media_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to media_files.id
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
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
    `book_id` BIGINT UNSIGNED NOT NULL,
    `author_id` BIGINT UNSIGNED NOT NULL,
    `author_role` ENUM('PRIMARY','CO_AUTHOR','EDITOR','CONTRIBUTOR') DEFAULT 'PRIMARY',
    `ordinal` TINYINT UNSIGNED DEFAULT 1,
    PRIMARY KEY (`book_id`, `author_id`),
    CONSTRAINT `fk_ba_book` FOREIGN KEY (`book_id`) REFERENCES `bok_books` (`id`),
    CONSTRAINT `fk_ba_author` FOREIGN KEY (`author_id`) REFERENCES `bok_book_authors` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Link Books to Class/Subject (which books are used for which class/subject)
  CREATE TABLE IF NOT EXISTS `bok_book_class_subject_jnt` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `book_id` BIGINT UNSIGNED NOT NULL,  -- FK to slb_books.id
    `class_id` INT UNSIGNED NOT NULL,    -- FK to sch_classes.id
    `subject_id` BIGINT UNSIGNED NOT NULL, -- FK to sch_subjects.id
    `academic_session_id` BIGINT UNSIGNED NOT NULL, -- FK to sch_org_academic_sessions_jnt.id
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      -- Student Info
      `user_id` BIGINT UNSIGNED NOT NULL,              -- Link to sys_users for login credentials
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
      `media_id` BIGINT UNSIGNED DEFAULT NULL,         -- Optional if using sys_media table
      -- Status
      `current_status_id` BIGINT UNSIGNED NOT NULL,    -- FK to sys_dropdown_table (Active, Left, Suspended, Alumni, Withdrawn)
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      -- Student Info
      `student_id` BIGINT UNSIGNED NOT NULL,
      `mobile` VARCHAR(20) DEFAULT NULL,               -- Student/Parent mobile (This will be saved as mobile in sys_users table)
      `email` VARCHAR(150) DEFAULT NULL,               -- Student/Parent email (This will be saved as email in sys_users table)
      -- Social / Category
      `religion` BIGINT UNSIGNED DEFAULT NULL,         -- FK to sys_dropdown_table
      `caste_category` BIGINT UNSIGNED DEFAULT NULL,   -- FK to sys_dropdown_table
      `nationality` BIGINT UNSIGNED DEFAULT NULL,      -- FK to sys_dropdown_table
      `mother_tongue` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_dropdown_table
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_id` BIGINT UNSIGNED NOT NULL,
      `address_type` ENUM('Permanent','Correspondence','Guardian','Local') NOT NULL DEFAULT 'Correspondence',
      `address` VARCHAR(512) NOT NULL,
      `city_id` BIGINT UNSIGNED NOT NULL,  -- FK to glb_cities
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `user_code` VARCHAR(20) NOT NULL,  -- Unique code for guardian (this will be saved as emp_code in sys_users table) 
      -- User Info
      `user_id` BIGINT UNSIGNED DEFAULT NOT NULL,        -- Nullable. Set when Parent Portal access is created.
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
      `preferred_language` bigint unsigned NOT NULL,   -- fk to glb_languages
      -- Media & Status
      `photo_file_name` VARCHAR(100) DEFAULT NULL,     -- Fk to sys_media (file name to show in UI)
      `media_id` BIGINT UNSIGNED DEFAULT NULL,         -- Optional if using sys_media table
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_id` BIGINT UNSIGNED NOT NULL,
      `guardian_id` BIGINT UNSIGNED NOT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT,
      `student_id` BIGINT UNSIGNED NOT NULL,
      -- Academic Session
      `academic_session_id` BIGINT UNSIGNED NOT NULL,   -- FK to glb_academic_sessions (or sch_org_academic_sessions_jnt)
      `class_section_id` INT UNSIGNED NOT NULL,         -- FK to sch_class_section_jnt
      `roll_no` INT UNSIGNED DEFAULT NULL,
      `subject_group_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sch_subject_groups (if streams apply)
      -- Other Detail
      `house` BIGINT UNSIGNED DEFAULT NULL,             -- FK to sys_dropdown_table
      `is_current` TINYINT(1) DEFAULT 0,                -- Only one active record per student
      `current_flag` bigint GENERATED ALWAYS AS ((case when (`is_current` = 1) then `student_id` else NULL end)) STORED,
      `session_status_id` BIGINT UNSIGNED NOT NULL DEFAULT 'ACTIVE',    -- FK to sys_dropdown_table (PROMOTED, ACTIVE, LEFT, SUSPENDED, ALUMNI, WITHDRAWN)
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_id` BIGINT UNSIGNED NOT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_id` BIGINT UNSIGNED NOT NULL,
      `document_name` VARCHAR(100) NOT NULL,           -- e.g. 'Transfer Certificate', 'Mark Sheet', 'Aadhar Card'
      `document_type_id` BIGINT UNSIGNED NOT NULL,     -- FK to sys_dropdown_table (Category of doc)
      `document_number` VARCHAR(100) DEFAULT NULL,     -- e.g. TC No, Serial No
      `issue_date` DATE DEFAULT NULL,
      `expiry_date` DATE DEFAULT NULL,
      `issuing_authority` VARCHAR(150) DEFAULT NULL,
      `is_verified` TINYINT(1) DEFAULT 0,              -- Verified by school admin
      `verified_by` BIGINT UNSIGNED DEFAULT NULL,      -- FK to sys_users
      `verification_date` DATETIME DEFAULT NULL,
      `file_name` VARCHAR(100) DEFAULT NULL,           -- Fk to sys_media (file name to show in UI)
      `media_id` BIGINT UNSIGNED DEFAULT NULL,         -- Optional if using sys_media table
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_id` BIGINT UNSIGNED NOT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_id` BIGINT UNSIGNED NOT NULL,
      `vaccine_name` VARCHAR(100) NOT NULL,
      `date_administered` DATE DEFAULT NULL,
      `next_due_date` DATE DEFAULT NULL,
      `remarks` VARCHAR(255) DEFAULT NULL,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT `fk_vacc_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Medical Incidents (School Clinic Log)
    CREATE TABLE IF NOT EXISTS `std_medical_incidents` (
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_id` BIGINT UNSIGNED NOT NULL,
      `incident_date` DATETIME NOT NULL,
      `incident_type_id` BIGINT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (e.g. Injury, Sickness, Fainting)
      `location` VARCHAR(100) DEFAULT NULL,     -- Playground, Classroom
      `description` TEXT NOT NULL,
      `first_aid_given` TEXT DEFAULT NULL,
      `action_taken` VARCHAR(255) DEFAULT NULL, -- Sent home, Rested in sick bay, Taken to hospital
      `reported_by` BIGINT UNSIGNED DEFAULT NULL, --  fk to sys_users (Teacher/Staff)
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `student_id` BIGINT UNSIGNED NOT NULL,
      `academic_session_id` BIGINT UNSIGNED NOT NULL,
      `class_section_id` INT UNSIGNED NOT NULL,
      `attendance_date` DATE NOT NULL, -- Date of attendance
      `attendance_period` TINYINT UNSIGNED NOT NULL DEFAULT 0,
      `status` ENUM('Present','Absent','Late','Half Day','Short Leave','Leave') NOT NULL,
      `remarks` VARCHAR(255) DEFAULT NULL,
      `marked_by` BIGINT UNSIGNED DEFAULT NULL,        -- User ID who marked attendance
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `attendance_id` BIGINT UNSIGNED NOT NULL,        -- FK to std_student_attendance
      `requested_by` BIGINT UNSIGNED NOT NULL,         -- Parent or Student User ID
      `requested_status` ENUM('Present','Absent','Late','Half Day','Short Leave','Leave') NOT NULL,
      `requested_period` TINYINT UNSIGNED NOT NULL DEFAULT 0,
      `reason` TEXT NOT NULL,
      `status` ENUM('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
      `admin_remarks` VARCHAR(255) DEFAULT NULL,       -- Admin/Teacher Remark on approval/rejection
      `action_by` BIGINT UNSIGNED DEFAULT NULL,        -- Admin/Teacher who approved/rejected
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `circular_goal_id` BIGINT UNSIGNED NOT NULL,
      `competency_id` BIGINT UNSIGNED NOT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `code` VARCHAR(50) NOT NULL,
      `description` VARCHAR(255) NOT NULL,
      `domain` BIGINT UNSIGNED NOT NULL,   -- FK TO sys_dropdown_table e.g. ('COGNITIVE','AFFECTIVE','PSYCHOMOTOR') DEFAULT 'COGNITIVE'
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `outcome_id` BIGINT UNSIGNED NOT NULL,
      `class_id` INT UNSIGNED NOT NULL,  -- Fk to sch_classes
      `entity_type` ENUM('SUBJECT','LESSON','TOPIC') NOT NULL,
      `entity_id` BIGINT UNSIGNED NOT NULL,  -- Dropdown from sch_subjects, slb_lessons, slb_topics (Depend upon selection of entity_type)
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `outcome_id` BIGINT UNSIGNED NOT NULL,
      `question_id` BIGINT UNSIGNED NOT NULL,  -- fk to qns_questions_bank.id
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `topic_id` BIGINT UNSIGNED NOT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `source_topic_id` BIGINT UNSIGNED NOT NULL,
      `target_topic_id` BIGINT UNSIGNED NOT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `academic_session_id` BIGINT UNSIGNED NOT NULL,
      `class_id` INT UNSIGNED NOT NULL,
      `subject_id` BIGINT UNSIGNED NOT NULL,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `academic_session_id` BIGINT UNSIGNED NOT NULL,
      `student_id` BIGINT UNSIGNED NOT NULL,
      `subject_id` BIGINT UNSIGNED NOT NULL,
      `competency_id` BIGINT UNSIGNED NOT NULL,
      `hpc_parameter_id` INT UNSIGNED NOT NULL,
      `hpc_level_id` INT UNSIGNED NOT NULL,
      `evidence_type` BIGINT UNSIGNED NOT NULL,   -- FK TO sys_dropdown_table e.g. ('ACTIVITY','ASSESSMENT','OBSERVATION')
      `evidence_id` BIGINT UNSIGNED,
      `remarks` VARCHAR(500),
      `assessed_by` BIGINT UNSIGNED,
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `topic_id` BIGINT UNSIGNED NOT NULL,
      `activity_type` BIGINT UNSIGNED NOT NULL,   FK TO sys_dropdown_table e.g. ('PROJECT','OBSERVATION','FIELD_WORK','GROUP_WORK','ART','SPORT','DISCUSSION')
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
      `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      `academic_session_id` BIGINT UNSIGNED NOT NULL,
      `student_id` BIGINT UNSIGNED NOT NULL,
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
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- Core linkage
    `lesson_id` BIGINT UNSIGNED NOT NULL,           -- FK to slb_lessons.id
    `academic_session_id` BIGINT UNSIGNED NOT NULL, -- Session in which this version applies
    -- Authority & source
    `curriculum_authority` ENUM('NCERT','CBSE','ICSE','STATE_BOARD','OTHER') NOT NULL DEFAULT 'NCERT',
    `board_code` VARCHAR(50) DEFAULT NULL,          -- CBSE, ICSE, STATE-UK, etc.
    `book_id` BIGINT UNSIGNED DEFAULT NULL,         -- FK to book master (if exists)
    `book_title` VARCHAR(255) DEFAULT NULL,         -- Redundant but audit-friendly
    `book_edition` VARCHAR(100) DEFAULT NULL,       -- e.g. "2024 Edition"
    `publisher` VARCHAR(150) DEFAULT 'NCERT',
    -- Versioning
    `lesson_version` VARCHAR(20) NOT NULL,          -- e.g. v1.0, v2.0
    `derived_from_lesson_id` BIGINT UNSIGNED DEFAULT NULL, -- Previous version reference
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
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `entity_type` ENUM('SUBJECT','LESSON','TOPIC','COMPETENCY') NOT NULL,
    `entity_id` BIGINT UNSIGNED NOT NULL,
    `change_type` ENUM('ADD','UPDATE','DELETE') NOT NULL,
    `change_summary` VARCHAR(500),
    `impact_analysis` JSON,
    `status` ENUM('DRAFT','SUBMITTED','APPROVED','REJECTED') DEFAULT 'DRAFT',
    `requested_by` BIGINT UNSIGNED,
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