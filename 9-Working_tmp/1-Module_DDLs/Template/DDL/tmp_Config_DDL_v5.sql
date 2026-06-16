-- =============================================================================
-- TMP — Template Module DDL
-- Module    : Template (Modules\Template)
-- File      : tmp_Config_DDL_v5.sql
-- Version   : 5.0 — April 2026
-- Author    : Brijesh
-- Date      : 2026-04-18
-- Database  : tenant_db (one per tenant, no tenant_id columns)
-- =============================================================================
-- CHANGELOG (v4 → v5):
-- ---------------------------------------------------------------------------
-- 1. FIXED  : Table creation order — eliminated forward FK references
-- 2. FIXED  : tmp_templates — removed indexes on non-existent columns
--             (created_by, updated_by), fixed missing comma before UNIQUE KEY
-- 3. FIXED  : tmp_template_variables — removed template_id (forward ref),
--             replaced with type_id FK to tmp_templates_type (type-scoped vars)
-- 4. FIXED  : tmp_templates_variables_jnt — added missing FK constraints,
--             UNIQUE KEY, removed trailing comma syntax error
-- 5. FIXED  : tmp_template_assignments.template_id type mismatch
--             (BIGINT → INT UNSIGNED to match tmp_templates.id)
-- 6. ADDED  : tmp_templates.code column for machine-readable identification
-- 7. ADDED  : display_order, default_value columns to junction table
-- 8. MOVED  : SEED DATA, RESOLUTION LOGIC, MIGRATION ORDER, TABLE SUMMARY
--             → tmp_Implementation_Guide.md
-- =============================================================================


-- =========================================================================
-- SECTION 1 : LOOKUP TABLES
-- =========================================================================

-- -------------------------------------------------------------------------
-- TABLE 1: tmp_templates_type
-- Purpose : Categorizes templates (e.g. MARKSHEET, STUDENT_ID_CARD)
-- Row Volume: ~5-10 per school
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tmp_templates_type` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`          VARCHAR(30) NOT NULL            COMMENT 'Machine-readable name e.g. MARKSHEET, STUDENT_ID_CARD',
    `description`   VARCHAR(255) DEFAULT NULL,
    `is_active`     TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`    TIMESTAMP NULL DEFAULT NULL,
    `updated_at`    TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`    TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tmp_tt_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Template categories — MARKSHEET, STUDENT_ID_CARD, STAFF_ID_CARD, etc.';


-- -------------------------------------------------------------------------
-- TABLE 2: tmp_template_purposes
-- Purpose : Defines the functional purposes for template assignment
--           (e.g. MARKSHEET_PRINT, STUDENT_ID_CARD).
--           Schools can extend with custom purposes (is_system = 0).
-- Scope types (via sys_dropdown_table):
--   CLASS_SCOPED — supports class, class-group, AND school-wide targeting
--   SCHOOL_WIDE  — school-wide only; UI hides class/group selectors
-- Row Volume: ~7-10 per school (7 seeded + custom)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tmp_template_purposes` (
    `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`            VARCHAR(30) NOT NULL              COMMENT 'Machine-readable code e.g. MARKSHEET_PRINT',
    `name`            VARCHAR(100) NOT NULL             COMMENT 'Display name e.g. Marksheet Printing',
    `description`     VARCHAR(255) DEFAULT NULL,
    `scope_type_id`   INT UNSIGNED NOT NULL             COMMENT 'FK → sys_dropdowns.id — CLASS_SCOPED or SCHOOL_WIDE',
    `display_order`   SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_system`       TINYINT(1) NOT NULL DEFAULT 0     COMMENT '1 = seeded/system, 0 = school-created',
    `is_active`       TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`      TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tmp_tp_code` (`code`),
    KEY `idx_tmp_tp_scope_type` (`scope_type_id`),
    KEY `idx_tmp_tp_is_active` (`is_active`),
    CONSTRAINT `fk_tmp_tp_scope_type` FOREIGN KEY (`scope_type_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Functional purposes for template assignment — MARKSHEET_PRINT, STUDENT_ID_CARD, etc.';


-- =========================================================================
-- SECTION 2 : TEMPLATE DESIGN
-- =========================================================================

-- -------------------------------------------------------------------------
-- TABLE 3: tmp_templates
-- Purpose : Stores actual template definitions with canvas/HTML content
-- Row Volume: ~5-20 per school
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tmp_templates` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`              VARCHAR(50) NOT NULL            COMMENT 'Machine-readable unique code',
    `name`              VARCHAR(100) NOT NULL           COMMENT 'Display name',
    `type_id`           INT UNSIGNED DEFAULT NULL       COMMENT 'FK → tmp_templates_type.id',
    `description`       TEXT DEFAULT NULL,
    `canvas_json`       JSON DEFAULT NULL               COMMENT 'Draggable element positions and layout',
    `html_content`      LONGTEXT DEFAULT NULL           COMMENT 'Rendered HTML content of template',
    `background_image`  VARCHAR(255) DEFAULT NULL       COMMENT 'Background image URL or storage path',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 0   COMMENT '0 = draft, 1 = active',
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tmp_tpl_code` (`code`),
    KEY `idx_tmp_tpl_type` (`type_id`),
    KEY `idx_tmp_tpl_is_active` (`is_active`),
    KEY `idx_tmp_tpl_deleted_at` (`deleted_at`),
    CONSTRAINT `fk_tmp_tpl_type` FOREIGN KEY (`type_id`) REFERENCES `tmp_templates_type` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Template definitions with canvas layout and HTML content.';


-- -------------------------------------------------------------------------
-- TABLE 4: tmp_template_variables
-- Purpose : Defines reusable variables scoped to a template type,
--           with optional mapping to database fields for auto-resolution.
--           e.g. MARKSHEET type → student_name, total_marks, grade
-- Row Volume: ~10-30 per type
-- -------------------------------------------------------------------------
-- v5 CHANGE: Replaced template_id with type_id.
--   Variables are now scoped to a type (not a single template) so they
--   can be reused across all templates of the same type. The junction
--   table (tmp_templates_variables_jnt) maps specific variables to
--   specific templates.
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tmp_template_variables` (
    `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `template_type_id` INT UNSIGNED NOT NULL              COMMENT 'FK → tmp_templates_type.id — variables scoped to type',
    `name`             VARCHAR(50) NOT NULL               COMMENT 'Variable placeholder e.g. student_name, total_marks',
    `description`      VARCHAR(255) DEFAULT NULL,
    `db_name`          VARCHAR(60) DEFAULT NULL           COMMENT 'Source database name for auto-resolution',
    `table_name`       VARCHAR(60) DEFAULT NULL           COMMENT 'Source table name for auto-resolution',
    `field_name`       VARCHAR(60) DEFAULT NULL           COMMENT 'Source column name for auto-resolution',
    `is_active`        TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`       TIMESTAMP NULL DEFAULT NULL,
    `updated_at`       TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`       TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tmp_tv_type_name` (`template_type_id`, `name`),
    KEY `idx_tmp_tv_type` (`template_type_id`),
    KEY `idx_tmp_tv_is_active` (`is_active`),
    KEY `idx_tmp_tv_deleted_at` (`deleted_at`),
    CONSTRAINT `fk_tmp_tv_type` FOREIGN KEY (`template_type_id`) REFERENCES `tmp_templates_type` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Reusable template variables scoped to a template type, with optional DB field mapping.';


-- -------------------------------------------------------------------------
-- TABLE 5: tmp_templates_variables_jnt
-- Purpose : Maps which variables are used by a specific template.
--           Includes per-template overrides (display_order, default_value).
-- Row Volume: ~50-200 per school
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tmp_templates_variables_jnt` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `template_id`       INT UNSIGNED NOT NULL              COMMENT 'FK → tmp_templates.id',
    `variable_id`       INT UNSIGNED NOT NULL              COMMENT 'FK → tmp_template_variables.id',
    `display_order`     SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Rendering order within template',
    `default_value`     VARCHAR(255) DEFAULT NULL          COMMENT 'Fallback value if variable resolves to NULL',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tmp_tvj_tpl_var` (`template_id`, `variable_id`),
    KEY `idx_tmp_tvj_template` (`template_id`),
    KEY `idx_tmp_tvj_variable` (`variable_id`),
    KEY `idx_tmp_tvj_is_active` (`is_active`),
    CONSTRAINT `fk_tmp_tvj_template` FOREIGN KEY (`template_id`) REFERENCES `tmp_templates` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tmp_tvj_variable` FOREIGN KEY (`variable_id`) REFERENCES `tmp_template_variables` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Junction: maps variables used by each template with display order and defaults.';


-- =========================================================================
-- SECTION 3 : TEMPLATE ASSIGNMENT
-- =========================================================================

-- -------------------------------------------------------------------------
-- TABLE 6: tmp_template_assignments
-- Purpose : Assigns a visual template to a purpose at a specific scope.
-- Scope types:
--   - Direct class:  class_id IS NOT NULL, class_group_id IS NULL
--   - Class group:   class_id IS NULL,     class_group_id IS NOT NULL
--   - School-wide:   class_id IS NULL,     class_group_id IS NULL
-- Row Volume: ~10-30 per school per session
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tmp_template_assignments` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `template_id`           INT UNSIGNED NOT NULL          COMMENT 'FK → tmp_templates.id — which visual template to use',
    `purpose_id`            INT UNSIGNED NOT NULL          COMMENT 'FK → tmp_template_purposes.id — for what purpose',
    `academic_session_id`   SMALLINT UNSIGNED NOT NULL     COMMENT 'FK → sch_org_academic_sessions_jnt.id',
    `class_id`              INT UNSIGNED DEFAULT NULL      COMMENT 'FK → sch_classes.id — direct class (highest priority)',
    `class_group_id`        INT UNSIGNED DEFAULT NULL      COMMENT 'FK → msh_class_groups.id — group-level (fallback)',
    -- Scope hash for uniqueness enforcement across all scope types
    -- Generates: "1:3:C5" (class), "1:3:G2" (group), "1:3:SCHOOL" (school-wide)
    `scope_hash`            VARCHAR(80) GENERATED ALWAYS AS (
        CONCAT(`purpose_id`, ':', `academic_session_id`, ':',
            COALESCE(CONCAT('C', `class_id`),
                COALESCE(CONCAT('G', `class_group_id`), 'SCHOOL')
            )
        )
    ) STORED COMMENT 'Generated uniqueness hash across scope types',
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    -- Uniqueness: one active template per purpose + session + scope target
    UNIQUE KEY `uq_tmp_ta_scope` (`scope_hash`),
    -- Lookup indexes
    KEY `idx_tmp_ta_template` (`template_id`),
    KEY `idx_tmp_ta_purpose` (`purpose_id`),
    KEY `idx_tmp_ta_session` (`academic_session_id`),
    KEY `idx_tmp_ta_class` (`class_id`),
    KEY `idx_tmp_ta_class_group` (`class_group_id`),
    -- Composite indexes for resolution queries
    KEY `idx_tmp_ta_purpose_session_class` (`purpose_id`, `academic_session_id`, `class_id`),
    KEY `idx_tmp_ta_purpose_session_group` (`purpose_id`, `academic_session_id`, `class_group_id`),
    KEY `idx_tmp_ta_is_active` (`is_active`),
    -- Foreign keys
    CONSTRAINT `fk_tmp_ta_template` FOREIGN KEY (`template_id`) REFERENCES `tmp_templates` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tmp_ta_purpose` FOREIGN KEY (`purpose_id`) REFERENCES `tmp_template_purposes` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tmp_ta_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tmp_ta_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tmp_ta_class_group` FOREIGN KEY (`class_group_id`) REFERENCES `msh_class_groups` (`id`) ON DELETE CASCADE,
    -- CHECK: Cannot have BOTH class_id and class_group_id
    CONSTRAINT `chk_tmp_ta_scope_target` CHECK ((`class_id` IS NOT NULL AND `class_group_id` IS NULL) OR (`class_id` IS NULL AND `class_group_id` IS NOT NULL) OR (`class_id` IS NULL AND `class_group_id` IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Assigns visual template to purpose at scope (class, group, or school-wide) per session.';


-- =========================================================================
-- END OF DDL — 6 tables
-- See tmp_Implementation_Guide.md for seed data, resolution logic,
-- migration order, and Laravel implementation hints.
-- =========================================================================
