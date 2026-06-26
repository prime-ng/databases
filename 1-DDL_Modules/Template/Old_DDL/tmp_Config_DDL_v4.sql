-- =============================================================================
-- TMP — Template Output Configuration DDL
-- Module    : Template (Modules\Template)
-- File      : tmp_Config_DDL_v4.sql
-- Version   : 4.0 — April 2026
-- Author    : Brijesh
-- Date      : 2026-04-18
-- Database  : tenant_db (one per tenant, no tenant_id columns)
-- =============================================================================

-- =========================================================================
-- SECTION : TEMPLATE MASTERS
-- =========================================================================

-- The tmp_templates_type table will capture different categories of templates (e.g. Marksheet, ID Card) for better organization and filtering.
-- Purpose of this table is to categorize templates into types (e.g. Marksheet, ID Card) for better organization and filtering.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tmp_templates_type` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(30) NOT NULL,    -- e.g. MARKSHEET, STUDENT_ID_CARD, STAFF_ID_CARD etc.
    `description` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tmp_templates_type_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- The tmp_template_variables table will capture individual variables that can be used in templates, with optional mapping to database fields for auto-resolution.
-- Purpose of this table is to define variables that can be used in templates, with optional mapping to database fields for auto-resolution.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tmp_template_variables` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `template_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `db_name` VARCHAR(60) DEFAULT NULL,  -- optional mapping to database column for auto-resolution
    `table_name` VARCHAR(60) DEFAULT NULL,  -- optional mapping to database table for auto-resolution
    `field_name` VARCHAR(60) DEFAULT NULL,  -- optional mapping to database field for auto-resolution
    `is_active` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_template_id` (`template_id`),
    INDEX `idx_is_active` (`is_active`),
    INDEX `idx_created_by` (`created_by`),
    INDEX `idx_updated_by` (`updated_by`),
    INDEX `idx_deleted_at` (`deleted_at`),
    CONSTRAINT `fk_template_id` FOREIGN KEY (`template_id`) REFERENCES `tmp_templates` (`id`) ON DELETE CASCADE,
    UNIQUE KEY `uq_template_variable` (`template_id`, `name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- The tmp_template_purposes table will capture the different purposes for which templates can be assigned 
-- (e.g. Marksheet Print, Student ID Card), along with their scoping rules.
-- Schools can extend with custom purposes (is_system = 0).
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tmp_template_purposes` (
  `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`            VARCHAR(30) NOT NULL              COMMENT 'Machine-readable code, e.g. MARKSHEET_PRINT, STUDENT_ID_CARD',
  `name`            VARCHAR(100) NOT NULL             COMMENT 'Display name, e.g. Marksheet Printing',
  `description`     VARCHAR(255) DEFAULT NULL         COMMENT 'Optional description of this purpose',
  `scope_type_id`   INT UNSIGNED NOT NULL             COMMENT 'FK -> sys_dropdown_table.id — CLASS_SCOPED or SCHOOL_WIDE',
  `display_order`   SMALLINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Sort order in UI dropdowns',
  `is_system`       TINYINT(1) NOT NULL DEFAULT 0     COMMENT '1 = seeded/system purpose, 0 = school-created',
  `is_active`       TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`      TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tmp_tp_code` (`code`),
  KEY `idx_tmp_tp_scope_type` (`scope_type_id`),
  KEY `idx_tmp_tp_is_active` (`is_active`),
  CONSTRAINT `fk_tmp_tp_scope_type` FOREIGN KEY (`scope_type_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION : TEMPLATE CREATION AND VARIABLE MAPPING
-- =========================================================================

-- The tmp_template table will capture the actual templates created by schools, linked to a type and with optional variables.
-- Purpose of this table is to define variables that can be used in templates, with optional mapping to database fields for auto-resolution.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tmp_templates` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL,
    `type_id` INT UNSIGNED DEFAULT NULL,  -- FK → tmp_templates_type.id
    `description` TEXT DEFAULT NULL,
    `canvas_json` JSON DEFAULT NULL,  -- store drageable element and their position
    `html_content` LONGTEXT DEFAULT NULL,  -- store html content of template
    `background_image` VARCHAR(255) DEFAULT NULL,  -- store background image url or path
    `is_active` TINYINT(1) NOT NULL DEFAULT 0,  -- 0 = inactive, 1 = active
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_is_active` (`is_active`),
    INDEX `idx_created_by` (`created_by`),
    INDEX `idx_updated_by` (`updated_by`),
    INDEX `idx_deleted_at` (`deleted_at`)
    UNIQUE KEY `uq_tmp_templates_code` (`name`),
    CONSTRAINT `fk_tmp_templates_type` FOREIGN KEY (`type_id`) REFERENCES `tmp_templates_type` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- The tmp_templates_variables_jnt table will capture the many-to-many relationship between templates and variables, 
-- allowing a template to have multiple variables and a variable to be used in multiple templates.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tmp_templates_variables_jnt` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `template_id` INT UNSIGNED NOT NULL,
    `template_variable_id` INT UNSIGNED NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_template_id` (`template_id`),
    INDEX `idx_is_active` (`is_active`),
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION : CONFIGURATION TABLE (1 table)
-- =========================================================================

-- -------------------------------------------------------------------------
-- TABLE 2: tmp_template_assignments
-- Purpose: Assigns a visual template to a purpose at a specific scope.
-- Scope types:
--   - Direct class:  class_id IS NOT NULL, class_group_id IS NULL
--   - Class group:   class_id IS NULL,     class_group_id IS NOT NULL
--   - School-wide:   class_id IS NULL,     class_group_id IS NULL
-- Row Volume: ~10-30 per school per session
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tmp_template_assignments` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `template_id`           BIGINT UNSIGNED NOT NULL       COMMENT 'FK -> tmp_templates.id — which visual template to use',
  `purpose_id`            INT UNSIGNED NOT NULL           COMMENT 'FK -> tmp_template_purposes.id — for what purpose',
  `academic_session_id`   SMALLINT UNSIGNED NOT NULL      COMMENT 'FK -> sch_org_academic_sessions_jnt.id — which session',
  `class_id`              INT UNSIGNED DEFAULT NULL       COMMENT 'FK -> sch_classes.id — direct class assignment (highest priority)',
  `class_group_id`        INT UNSIGNED DEFAULT NULL       COMMENT 'FK -> msh_class_groups.id — group-level assignment (fallback)',
  -- Scope hash for uniqueness enforcement across all scope types
  -- Generates: "1:3:C5" (class), "1:3:G2" (group), "1:3:SCHOOL" (school-wide)
  `scope_hash`            VARCHAR(80) GENERATED ALWAYS AS (CONCAT(`purpose_id`, ':',`academic_session_id`, ':',COALESCE(CONCAT('C', `class_id`), COALESCE(CONCAT('G', `class_group_id`), 'SCHOOL')))) STORED COMMENT 'Generated column for uniqueness enforcement across scope types',
  -- Standard
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  -- Uniqueness: one active template per purpose + session + scope target
  UNIQUE KEY `uq_tmp_ta_scope` (`scope_hash`),
  -- Lookup indexes for resolution queries
  KEY `idx_tmp_ta_template` (`template_id`),
  KEY `idx_tmp_ta_purpose` (`purpose_id`),
  KEY `idx_tmp_ta_session` (`academic_session_id`),
  KEY `idx_tmp_ta_class` (`class_id`),
  KEY `idx_tmp_ta_class_group` (`class_group_id`),
  -- Composite indexes for common resolution patterns
  KEY `idx_tmp_ta_purpose_session_class` (`purpose_id`, `academic_session_id`, `class_id`),
  KEY `idx_tmp_ta_purpose_session_group` (`purpose_id`, `academic_session_id`, `class_group_id`),
  KEY `idx_tmp_ta_is_active` (`is_active`),
  -- Foreign keys
  CONSTRAINT `fk_tmp_ta_template` FOREIGN KEY (`template_id`) REFERENCES `tmp_templates` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tmp_ta_purpose` FOREIGN KEY (`purpose_id`) REFERENCES `tmp_template_purposes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tmp_ta_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tmp_ta_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tmp_ta_class_group` FOREIGN KEY (`class_group_id`) REFERENCES `msh_class_groups` (`id`) ON DELETE CASCADE,
  -- CHECK: Cannot have BOTH class_id and class_group_id set.
  -- Both NULL = school-wide scope. Exactly one set = targeted scope.
  CONSTRAINT `chk_tmp_ta_scope_target` CHECK ((`class_id` IS NOT NULL AND `class_group_id` IS NULL) OR (`class_id` IS NULL AND `class_group_id` IS NOT NULL) OR (`class_id` IS NULL AND `class_group_id` IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Assigns visual template to purpose at scope (class, class-group, or school-wide) per session.';


-- =========================================================================
-- SECTION : SEED DATA
-- =========================================================================


-- -----------------------------------------------------------------
-- Seed: sys_dropdown_table — scope types for tmp_template_purposes
-- Key: tmp_template_purposes.scope_type_id
-- -----------------------------------------------------------------
-- CLASS_SCOPED: Purpose supports class-level, class-group, AND school-wide
--              targeting. UI shows class/group selectors.
-- SCHOOL_WIDE: Purpose only supports school-wide targeting.
--              UI hides class/group selectors; both are always NULL.
-- -----------------------------------------------------------------
INSERT INTO `sys_dropdown_table` (`ordinal`, `key`, `value`, `type`, `additional_info`, `is_active`)
VALUES
  (1, 'tmp_template_purposes.scope_type_id', 'CLASS_SCOPED', 'String',
    '{"description": "Supports class-level, class-group, and school-wide scoping"}', 1),
  (2, 'tmp_template_purposes.scope_type_id', 'SCHOOL_WIDE', 'String',
    '{"description": "School-wide only — no class or class-group targeting"}', 1);

-- =========================================================================
-- SECTION : TEMPLATE RESOLUTION LOGIC
-- =========================================================================
--
-- RESOLUTION PRIORITY (for CLASS_SCOPED purposes like MARKSHEET_PRINT):
-- =====================================================================
-- Given: @purpose_code, @session_id, @class_id
--
-- Step 1 — Direct class match (highest priority):
--   SELECT ta.template_id
--   FROM tmp_template_assignments ta
--   JOIN tmp_template_purposes tp ON tp.id = ta.purpose_id
--   WHERE tp.code = @purpose_code
--     AND ta.academic_session_id = @session_id
--     AND ta.class_id = @class_id
--     AND ta.is_active = 1
--     AND ta.deleted_at IS NULL;
--
-- Step 2 — Class group match (fallback):
--   SELECT ta.template_id
--   FROM tmp_template_assignments ta
--   JOIN tmp_template_purposes tp ON tp.id = ta.purpose_id
--   JOIN msh_class_group_items_jnt cgi ON cgi.class_group_id = ta.class_group_id
--   WHERE tp.code = @purpose_code
--     AND ta.academic_session_id = @session_id
--     AND cgi.class_id = @class_id
--     AND ta.class_id IS NULL
--     AND ta.is_active = 1
--     AND ta.deleted_at IS NULL
--     AND cgi.is_active = 1
--     AND cgi.deleted_at IS NULL;
--
-- Step 3 — School-wide fallback:
--   SELECT ta.template_id
--   FROM tmp_template_assignments ta
--   JOIN tmp_template_purposes tp ON tp.id = ta.purpose_id
--   WHERE tp.code = @purpose_code
--     AND ta.academic_session_id = @session_id
--     AND ta.class_id IS NULL
--     AND ta.class_group_id IS NULL
--     AND ta.is_active = 1
--     AND ta.deleted_at IS NULL;
--
-- Step 4 — Not found: raise error (no template configured for this scope).
--
-- RESOLUTION FOR SCHOOL_WIDE PURPOSES (e.g. STAFF_ID_CARD):
-- ==========================================================
-- Only Step 3 applies. class_id and class_group_id are always NULL.
--
-- COMBINING WITH MARKSHEET COMPUTATION CONFIG:
-- =============================================
-- At marksheet generation time, the system resolves BOTH independently:
--   1. From MSG module:  msh_config_templates (via msh_class_config_jnt)
--      -> Computation rules (weightages, grading, pass criteria)
--   2. From Template module: tmp_template_assignments (this DDL)
--      -> Visual layout (PDF template with canvas/HTML)
-- These are NOT FK-coupled. Combined at render time by the service layer.
-- =========================================================================


-- =========================================================================
-- SECTION : MIGRATION DEPENDENCY ORDER
-- =========================================================================
--
-- Migrations go in: database/migrations/tenant/
--
-- PREREQUISITE (if not already created):
--   2026_04_16_000001_create_tmp_templates_table.php
--     -> Creates tmp_templates table (Module: Template)
--     -> MUST run BEFORE the tables below
--     -> NOTE: tmp_templates.created_by/updated_by use BIGINT UNSIGNED
--        but sys_users.id is INT UNSIGNED. Consider fixing in this migration.
--
-- THIS DDL:
--   2026_04_16_000002_create_tmp_template_purposes_table.php
--     -> Depends on: sys_dropdown_table (already exists)
--   2026_04_16_000003_create_tmp_template_assignments_table.php
--     -> Depends on: tmp_templates, tmp_template_purposes,
--        sch_org_academic_sessions_jnt, sch_classes, msh_class_groups
--
-- SEEDER:
--   TemplateConfigSeeder.php
--     -> Seeds sys_dropdown_table: key 'tmp_template_purposes.scope_type_id'
--        Values: CLASS_SCOPED, SCHOOL_WIDE
--     -> Seeds tmp_template_purposes: 7 standard purposes
--
-- DEPENDENCY GRAPH:
--   sys_dropdown_table (exists)
--        |
--        v
--   tmp_templates (NEEDS MIGRATION)
--        |
--        v
--   tmp_template_purposes
--        |
--        v
--   tmp_template_assignments --> sch_classes (exists)
--        |                  --> sch_org_academic_sessions_jnt (exists)
--        |                  --> msh_class_groups (exists via MSG module)
--        v
--   [Ready for use]
-- =========================================================================


-- =========================================================================
-- SECTION : TABLE SUMMARY
-- =========================================================================
-- #  | Table Name                | Domain     | Row Volume
-- ---|---------------------------|------------|---------------------------
-- 1  | tmp_template_purposes     | Lookup     | ~7-10 / school (7 seeded)
-- 2  | tmp_template_assignments  | Config     | ~10-30 / school / session
-- =========================================================================

