-- =============================================================================
-- MSG — MarksheetGeneration Module DDL
-- Module    : MarksheetGeneration (Modules\MarksheetGeneration)
-- File      : MSG_DDL_v1.sql
-- Version   : 1.0 — April 2026
-- Patch     : 2026-04-18 — renamed sys_dropdown_table → sys_dropdowns (CC-2); cross-module PKs are BIGINT UNSIGNED (Laravel $table->id() standard)
-- Table Prefix: msh_* (22 tables)
-- Database  : tenant_db (one per tenant, no tenant_id columns)
-- Based on  : MSG_RequirementSpec.md v1.0
-- =============================================================================
--
-- PURPOSE:
--   Provides configuration and result storage for school marksheet generation.
--   Aggregates marks from LmsExam, LmsHomework, LmsQuiz, LmsQuest, and
--   BehaviouralAssessment into subject-wise, exam-wise result matrices.
--
-- CROSS-MODULE DEPENDENCIES (READ ONLY — MSG never modifies these):
--   ┌────────────────────────────────────┬─────────────────────────────────────────┐
--   │ Table                              │ PK Type (actual — Laravel $table->id()) │
--   ├────────────────────────────────────┼─────────────────────────────────────────┤
--   │ sch_classes                        │ BIGINT UNSIGNED                         │
--   │ sch_sections                       │ BIGINT UNSIGNED                         │
--   │ sch_class_section_jnt              │ BIGINT UNSIGNED                         │
--   │ sch_subjects                       │ BIGINT UNSIGNED                         │
--   │ sch_org_academic_sessions_jnt      │ BIGINT UNSIGNED                         │
--   │ std_students                       │ BIGINT UNSIGNED                         │
--   │ sys_users                          │ BIGINT UNSIGNED                         │
--   │ sys_dropdowns                      │ BIGINT UNSIGNED                         │
--   │ slb_grade_division_master          │ BIGINT UNSIGNED                         │
--   │ lms_exam_types                     │ BIGINT UNSIGNED                         │
--   │ lms_exams                          │ BIGINT UNSIGNED                         │
--   │ lms_exam_papers                    │ BIGINT UNSIGNED                         │
--   │ lms_exam_results                   │ BIGINT UNSIGNED                         │
--   └────────────────────────────────────┴─────────────────────────────────────────┘
--
-- KEY DESIGN DECISIONS:
--   D-MSG-001: No tenant_id — stancl/tenancy v3.9 database-per-tenant
--   D-MSG-002: No ENUMs — all status/type fields use sys_dropdowns or lookup tables
--   D-MSG-003: msh_class_groups is separate from sch_class_groups_jnt (timetable-specific)
--   D-MSG-004: Online/Offline transparent — both read from lms_exam_results
--   D-MSG-005: Subject-wise result is the core table; overall result is aggregation
--   D-MSG-006: IA marks owned by this module (teacher entry via UI)
--   D-MSG-007: Co-Scholastic grades owned by this module (teacher entry via UI)
-- =============================================================================


-- =========================================================================
-- SECTION 1: MASTER TABLES (3 tables)
-- Foundation/reference data. No FK to other msh_* tables.
-- =========================================================================


-- -------------------------------------------------------------------------
-- TABLE 1: msh_marksheet_types
-- Purpose: School-configurable marksheet types.
-- Examples: "Unit Test Result", "Term-1 Report Card", "Annual Report Card"
-- Row Volume: ~5-8 per school
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_marksheet_types` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`          VARCHAR(30) NOT NULL           COMMENT 'Machine-readable code, e.g. UNIT_TEST, TERM1, ANNUAL',
  `name`          VARCHAR(100) NOT NULL          COMMENT 'Display name, e.g. Term-1 Report Card',
  `description`   VARCHAR(255) DEFAULT NULL,
  `display_order` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  -- Standard
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`    INT UNSIGNED NOT NULL          COMMENT 'FK → sys_users.id',
  `updated_by`    INT UNSIGNED DEFAULT NULL      COMMENT 'FK → sys_users.id',
  `created_at`    TIMESTAMP NULL DEFAULT NULL,
  `updated_at`    TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`    TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_mt_code` (`code`),
  KEY `idx_msh_mt_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='School-configurable marksheet types (Unit Test, Term-1, Annual, etc.)';


-- -------------------------------------------------------------------------
-- TABLE 2: msh_source_components
-- Purpose: Fixed lookup of assessment sources that contribute to marksheet.
-- Seeded: 4 rows (Exam, Homework, Quiz, Quest). Exam is always mandatory.
-- Row Volume: 4 (fixed, seeded at tenant onboarding)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_source_components` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`          VARCHAR(30) NOT NULL           COMMENT 'EXAM, HOMEWORK, QUIZ, QUEST',
  `name`          VARCHAR(100) NOT NULL          COMMENT 'Display name',
  `description`   VARCHAR(255) DEFAULT NULL,
  `is_mandatory`  TINYINT(1) NOT NULL DEFAULT 0  COMMENT '1 for Exam — always required in every template',
  `display_order` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  -- Standard
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`    INT UNSIGNED NOT NULL,
  `updated_by`    INT UNSIGNED DEFAULT NULL,
  `created_at`    TIMESTAMP NULL DEFAULT NULL,
  `updated_at`    TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`    TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_sc_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Fixed lookup: assessment sources (Exam, Homework, Quiz, Quest). Seeded at onboarding.';


-- -------------------------------------------------------------------------
-- TABLE 3: msh_ia_component_types
-- Purpose: Seeded types for Internal Assessment components.
-- Examples: Notebook, Subject Enrichment, Periodic Assessment, Participation
-- Row Volume: ~4-6 (seeded, school can add more)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_ia_component_types` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`          VARCHAR(30) NOT NULL           COMMENT 'NOTEBOOK, SUB_ENRICHMENT, PERIODIC_ASSESS, PARTICIPATION',
  `name`          VARCHAR(100) NOT NULL,
  `description`   VARCHAR(255) DEFAULT NULL,
  `display_order` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  -- Standard
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`    INT UNSIGNED NOT NULL,
  `updated_by`    INT UNSIGNED DEFAULT NULL,
  `created_at`    TIMESTAMP NULL DEFAULT NULL,
  `updated_at`    TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`    TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_iact_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Lookup for Internal Assessment component types (Notebook, Enrichment, etc.). Seeded + school-extensible.';


-- =========================================================================
-- SECTION 2: CONFIGURATION TABLES (10 tables)
-- School admin sets these up before marksheet generation.
-- =========================================================================


-- -------------------------------------------------------------------------
-- TABLE 4: msh_class_groups
-- Purpose: Marksheet-specific class grouping (Primary, Middle, Secondary).
-- NOTE: sch_class_groups_jnt is timetable-specific — NOT usable here.
-- Row Volume: ~3-5 per school
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_class_groups` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`          VARCHAR(30) NOT NULL           COMMENT 'PRIMARY, MIDDLE, SECONDARY, SR_SECONDARY',
  `name`          VARCHAR(100) NOT NULL          COMMENT 'Primary (1-5), Middle (6-8), etc.',
  `description`   VARCHAR(255) DEFAULT NULL,
  `display_order` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  -- Standard
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`    INT UNSIGNED NOT NULL,
  `updated_by`    INT UNSIGNED DEFAULT NULL,
  `created_at`    TIMESTAMP NULL DEFAULT NULL,
  `updated_at`    TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`    TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_cg_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Marksheet-specific class grouping (Primary, Middle, Secondary). Separate from timetable sch_class_groups_jnt.';


-- -------------------------------------------------------------------------
-- TABLE 5: msh_class_group_items_jnt
-- Purpose: Junction — which classes belong to which marksheet class group.
-- Row Volume: ~15-20 per school (one row per class)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_class_group_items_jnt` (
  `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `class_group_id`  INT UNSIGNED NOT NULL         COMMENT 'FK → msh_class_groups.id',
  `class_id`        INT UNSIGNED NOT NULL         COMMENT 'FK → sch_classes.id',
  -- Standard
  `is_active`       TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`      INT UNSIGNED NOT NULL,
  `updated_by`      INT UNSIGNED DEFAULT NULL,
  `created_at`      TIMESTAMP NULL DEFAULT NULL,
  `updated_at`      TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`      TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_cgi_group_class` (`class_group_id`, `class_id`),
  KEY `idx_msh_cgi_class` (`class_id`),
  CONSTRAINT `fk_msh_cgi_group` FOREIGN KEY (`class_group_id`) REFERENCES `msh_class_groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msh_cgi_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Junction: classes in a marksheet class group.';


-- -------------------------------------------------------------------------
-- TABLE 6: msh_exam_groups
-- Purpose: Groups multiple exam types into logical terms for marksheet.
-- Examples: "Term-1" = UT1 + UT2 + Half Yearly
-- Row Volume: ~2-4 per school per session
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_exam_groups` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `academic_session_id`   SMALLINT UNSIGNED NOT NULL  COMMENT 'FK → sch_org_academic_sessions_jnt.id',
  `code`                  VARCHAR(30) NOT NULL        COMMENT 'TERM1, TERM2, ANNUAL',
  `name`                  VARCHAR(100) NOT NULL       COMMENT 'Term-1, Term-2, Annual',
  `description`           VARCHAR(255) DEFAULT NULL,
  `start_date`            DATE DEFAULT NULL           COMMENT 'Term start date (for HW/Quiz/Quest date range filter)',
  `end_date`              DATE DEFAULT NULL           COMMENT 'Term end date',
  -- Standard
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED NOT NULL,
  `updated_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT NULL,
  `updated_at`            TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_eg_session_code` (`academic_session_id`, `code`),
  KEY `idx_msh_eg_session` (`academic_session_id`),
  CONSTRAINT `fk_msh_eg_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Groups exam types into terms (Term-1=UT1+UT2+HY, Annual=ALL) for marksheet generation.';


-- -------------------------------------------------------------------------
-- TABLE 7: msh_exam_group_items_jnt
-- Purpose: Junction — which lms_exam_types belong to an exam group.
-- Row Volume: ~6-12 per school per session
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_exam_group_items_jnt` (
  `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_group_id`   INT UNSIGNED NOT NULL         COMMENT 'FK → msh_exam_groups.id',
  `exam_type_id`    INT UNSIGNED NOT NULL         COMMENT 'FK → lms_exam_types.id (UT-1, HY-EXAM, etc.)',
  `display_order`   SMALLINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Column order on marksheet',
  -- Standard
  `is_active`       TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`      INT UNSIGNED NOT NULL,
  `updated_by`      INT UNSIGNED DEFAULT NULL,
  `created_at`      TIMESTAMP NULL DEFAULT NULL,
  `updated_at`      TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`      TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_egi_group_type` (`exam_group_id`, `exam_type_id`),
  KEY `idx_msh_egi_exam_type` (`exam_type_id`),
  CONSTRAINT `fk_msh_egi_group` FOREIGN KEY (`exam_group_id`) REFERENCES `msh_exam_groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msh_egi_type` FOREIGN KEY (`exam_type_id`) REFERENCES `lms_exam_types` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Junction: exam types in an exam group.';


-- -------------------------------------------------------------------------
-- TABLE 8: msh_config_templates
-- Purpose: Reusable marksheet configuration blueprint per academic session.
-- One template can be shared across multiple classes/class-groups.
-- Row Volume: ~3-6 per school per session
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_config_templates` (
  `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `academic_session_id`       SMALLINT UNSIGNED NOT NULL  COMMENT 'FK → sch_org_academic_sessions_jnt.id',
  `marksheet_type_id`         INT UNSIGNED NOT NULL       COMMENT 'FK → msh_marksheet_types.id',
  `exam_group_id`             INT UNSIGNED NOT NULL       COMMENT 'FK → msh_exam_groups.id — which exams this template covers',
  `grading_schema_id`         INT UNSIGNED DEFAULT NULL   COMMENT 'FK → slb_grade_division_master.id — default grading schema for grade computation',
  `code`                      VARCHAR(50) NOT NULL        COMMENT 'E.g. CBSE_SEC_TERM1_2025',
  `name`                      VARCHAR(150) NOT NULL       COMMENT 'E.g. CBSE Secondary Term-1 Template 2025-26',
  `description`               VARCHAR(500) DEFAULT NULL,
  -- Board context
  `board_code`                VARCHAR(50) DEFAULT NULL    COMMENT 'CBSE, ICSE, STATE, CUSTOM — informational, guides UI defaults',
  -- Pass / Promotion criteria
  `passing_percentage`        DECIMAL(5,2) NOT NULL DEFAULT 33.00 COMMENT 'Minimum % to pass a subject',
  `compartment_max_failures`  TINYINT UNSIGNED NOT NULL DEFAULT 2 COMMENT 'Max subjects student can fail and still get Compartment instead of Detained',
  -- Best-of-N (optional)
  `is_best_of_n_enabled`      TINYINT(1) NOT NULL DEFAULT 0  COMMENT 'If 1, only best N unit test scores count',
  `best_of_n_count`           TINYINT UNSIGNED DEFAULT NULL   COMMENT 'How many unit tests to pick (e.g. 2 out of 4)',
  -- Lock guard
  `is_locked`                 TINYINT(1) NOT NULL DEFAULT 0  COMMENT '1 = linked to a published schedule, immutable (BR-MSG-027)',
  -- Standard
  `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`                INT UNSIGNED NOT NULL,
  `updated_by`                INT UNSIGNED DEFAULT NULL,
  `created_at`                TIMESTAMP NULL DEFAULT NULL,
  `updated_at`                TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_ct_session_code` (`academic_session_id`, `code`),
  KEY `idx_msh_ct_session` (`academic_session_id`),
  KEY `idx_msh_ct_type` (`marksheet_type_id`),
  KEY `idx_msh_ct_exam_group` (`exam_group_id`),
  KEY `idx_msh_ct_grading` (`grading_schema_id`),
  CONSTRAINT `fk_msh_ct_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_msh_ct_type` FOREIGN KEY (`marksheet_type_id`) REFERENCES `msh_marksheet_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_msh_ct_exam_group` FOREIGN KEY (`exam_group_id`) REFERENCES `msh_exam_groups` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_msh_ct_grading` FOREIGN KEY (`grading_schema_id`) REFERENCES `slb_grade_division_master` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Reusable marksheet configuration blueprint. Links exam group, grading schema, pass criteria.';


-- -------------------------------------------------------------------------
-- TABLE 9: msh_template_scholastic_components
-- Purpose: Which source components participate in this template + weightage.
-- BR-MSG-002: Sum of weightage_percent across all components = 100.
-- Row Volume: ~3-4 per template
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_template_scholastic_components` (
  `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `config_template_id`  INT UNSIGNED NOT NULL         COMMENT 'FK → msh_config_templates.id',
  `source_component_id` INT UNSIGNED NOT NULL         COMMENT 'FK → msh_source_components.id',
  `weightage_percent`   DECIMAL(5,2) NOT NULL         COMMENT 'Percentage this component contributes (e.g. 80.00 for Exam)',
  `max_marks`           DECIMAL(8,2) DEFAULT NULL     COMMENT 'Optional: max marks this component contributes to subject total',
  -- Standard
  `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`          INT UNSIGNED NOT NULL,
  `updated_by`          INT UNSIGNED DEFAULT NULL,
  `created_at`          TIMESTAMP NULL DEFAULT NULL,
  `updated_at`          TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`          TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_tsc_template_component` (`config_template_id`, `source_component_id`),
  KEY `idx_msh_tsc_component` (`source_component_id`),
  CONSTRAINT `fk_msh_tsc_template` FOREIGN KEY (`config_template_id`) REFERENCES `msh_config_templates` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msh_tsc_component` FOREIGN KEY (`source_component_id`) REFERENCES `msh_source_components` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Scholastic source components + weightage per template. Sum of weightage_percent must = 100.';


-- -------------------------------------------------------------------------
-- TABLE 10: msh_template_exam_weightages
-- Purpose: Per-exam-type weightage within the Exam component.
-- BR-MSG-003: Sum of weightage_percent across exam types = 100.
-- Row Volume: ~3-6 per template
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_template_exam_weightages` (
  `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `config_template_id`  INT UNSIGNED NOT NULL         COMMENT 'FK → msh_config_templates.id',
  `exam_type_id`        INT UNSIGNED NOT NULL         COMMENT 'FK → lms_exam_types.id (UT-1, UT-2, HY-EXAM, etc.)',
  `weightage_percent`   DECIMAL(5,2) NOT NULL         COMMENT 'E.g. UT-1=10.00, UT-2=10.00, HY=80.00',
  `max_marks`           DECIMAL(8,2) DEFAULT NULL     COMMENT 'Max marks for this exam type (from lms_exam_papers.total_marks)',
  -- Standard
  `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`          INT UNSIGNED NOT NULL,
  `updated_by`          INT UNSIGNED DEFAULT NULL,
  `created_at`          TIMESTAMP NULL DEFAULT NULL,
  `updated_at`          TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`          TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_tew_template_exam` (`config_template_id`, `exam_type_id`),
  KEY `idx_msh_tew_exam_type` (`exam_type_id`),
  CONSTRAINT `fk_msh_tew_template` FOREIGN KEY (`config_template_id`) REFERENCES `msh_config_templates` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msh_tew_exam_type` FOREIGN KEY (`exam_type_id`) REFERENCES `lms_exam_types` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Per-exam-type weightage within Exam component. Sum must = 100 for the template.';


-- -------------------------------------------------------------------------
-- TABLE 11: msh_template_ia_components
-- Purpose: IA component definitions + max marks per template.
-- Examples: Notebook=5, Subject Enrichment=5 per subject.
-- Row Volume: ~2-4 per template
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_template_ia_components` (
  `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `config_template_id`  INT UNSIGNED NOT NULL         COMMENT 'FK → msh_config_templates.id',
  `ia_component_type_id` INT UNSIGNED NOT NULL        COMMENT 'FK → msh_ia_component_types.id',
  `max_marks`           DECIMAL(5,2) NOT NULL         COMMENT 'Max marks for this IA component per subject (e.g. 5.00)',
  `display_order`       SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  -- Standard
  `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`          INT UNSIGNED NOT NULL,
  `updated_by`          INT UNSIGNED DEFAULT NULL,
  `created_at`          TIMESTAMP NULL DEFAULT NULL,
  `updated_at`          TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`          TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_tiac_template_type` (`config_template_id`, `ia_component_type_id`),
  KEY `idx_msh_tiac_ia_type` (`ia_component_type_id`),
  CONSTRAINT `fk_msh_tiac_template` FOREIGN KEY (`config_template_id`) REFERENCES `msh_config_templates` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msh_tiac_type` FOREIGN KEY (`ia_component_type_id`) REFERENCES `msh_ia_component_types` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='IA component definitions per template (Notebook=5, Enrichment=5, etc.).';


-- -------------------------------------------------------------------------
-- TABLE 12: msh_template_coscholastic_components
-- Purpose: Co-Scholastic area definitions per template.
-- Examples: Work Education, Art Education, Health & PE, Discipline
-- Row Volume: ~3-5 per template
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_template_coscholastic_components` (
  `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `config_template_id`  INT UNSIGNED NOT NULL         COMMENT 'FK → msh_config_templates.id',
  `name`                VARCHAR(100) NOT NULL         COMMENT 'E.g. Work Education, Art Education, Health & Physical Education',
  `code`                VARCHAR(30) NOT NULL          COMMENT 'WORK_ED, ART_ED, HEALTH_PE, DISCIPLINE',
  `grading_scale`       VARCHAR(50) NOT NULL DEFAULT '3_POINT' COMMENT '3_POINT (A/B/C) or 5_POINT (A/B/C/D/E)',
  `is_ba_linked`        TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 if this area auto-populates from BehaviouralAssessment module',
  `display_order`       SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  -- Standard
  `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`          INT UNSIGNED NOT NULL,
  `updated_by`          INT UNSIGNED DEFAULT NULL,
  `created_at`          TIMESTAMP NULL DEFAULT NULL,
  `updated_at`          TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`          TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_tcsc_template_code` (`config_template_id`, `code`),
  CONSTRAINT `fk_msh_tcsc_template` FOREIGN KEY (`config_template_id`) REFERENCES `msh_config_templates` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Co-Scholastic areas per template (Work Ed, Art, Health & PE, Discipline).';


-- -------------------------------------------------------------------------
-- TABLE 13: msh_class_config_jnt
-- Purpose: Assigns config template to class or class-group.
-- BR-MSG-005: Direct class assignment overrides group-level assignment.
-- Row Volume: ~10-20 per school per session
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_class_config_jnt` (
  `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `config_template_id`  INT UNSIGNED NOT NULL         COMMENT 'FK → msh_config_templates.id',
  `class_id`            INT UNSIGNED DEFAULT NULL     COMMENT 'FK → sch_classes.id (direct assignment, takes priority)',
  `class_group_id`      INT UNSIGNED DEFAULT NULL     COMMENT 'FK → msh_class_groups.id (group-level, fallback)',
  -- Standard
  `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`          INT UNSIGNED NOT NULL,
  `updated_by`          INT UNSIGNED DEFAULT NULL,
  `created_at`          TIMESTAMP NULL DEFAULT NULL,
  `updated_at`          TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`          TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_msh_ccj_template` (`config_template_id`),
  KEY `idx_msh_ccj_class` (`class_id`),
  KEY `idx_msh_ccj_group` (`class_group_id`),
  CONSTRAINT `fk_msh_ccj_template` FOREIGN KEY (`config_template_id`) REFERENCES `msh_config_templates` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msh_ccj_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msh_ccj_group` FOREIGN KEY (`class_group_id`) REFERENCES `msh_class_groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `chk_msh_ccj_target` CHECK ((`class_id` IS NOT NULL AND `class_group_id` IS NULL) OR (`class_id` IS NULL AND `class_group_id` IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Assigns config template to class (direct) or class-group (inherited). CHECK ensures exactly one target.';


-- -------------------------------------------------------------------------
-- TABLE 14: msh_subject_practical_configs
-- Purpose: Theory-Practical mark split per class-subject.
-- E.g. Science Class 9: Theory=70, Practical=30 (sum = exam paper total)
-- Row Volume: ~5-15 per school (only subjects with practicals)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_subject_practical_configs` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `academic_session_id`   SMALLINT UNSIGNED NOT NULL   COMMENT 'FK → sch_org_academic_sessions_jnt.id',
  `class_id`              INT UNSIGNED NOT NULL        COMMENT 'FK → sch_classes.id',
  `subject_id`            INT UNSIGNED NOT NULL        COMMENT 'FK → sch_subjects.id',
  `has_practical`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = subject has practical in this class',
  `theory_max_marks`      DECIMAL(5,2) NOT NULL        COMMENT 'Theory portion max marks (e.g. 70)',
  `practical_max_marks`   DECIMAL(5,2) NOT NULL        COMMENT 'Practical portion max marks (e.g. 30)',
  -- Standard
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED NOT NULL,
  `updated_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT NULL,
  `updated_at`            TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_spc_session_class_sub` (`academic_session_id`, `class_id`, `subject_id`),
  KEY `idx_msh_spc_class` (`class_id`),
  KEY `idx_msh_spc_subject` (`subject_id`),
  CONSTRAINT `fk_msh_spc_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_msh_spc_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msh_spc_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Theory-Practical split per class-subject. Only rows for subjects that have practicals.';


-- =========================================================================
-- SECTION 3: SCHEDULE TABLES (2 tables)
-- Defines when and for whom marksheets are generated.
-- =========================================================================


-- -------------------------------------------------------------------------
-- TABLE 15: msh_marksheet_schedules
-- Purpose: A marksheet generation event (trigger point for computation).
-- One schedule = one set of marksheets for specific class-sections.
-- Row Volume: ~4-10 per school per session
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_marksheet_schedules` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `config_template_id`    INT UNSIGNED NOT NULL        COMMENT 'FK → msh_config_templates.id',
  `academic_session_id`   SMALLINT UNSIGNED NOT NULL   COMMENT 'FK → sch_org_academic_sessions_jnt.id',
  `code`                  VARCHAR(50) NOT NULL         COMMENT 'E.g. TERM1_SEC_2025',
  `name`                  VARCHAR(150) NOT NULL        COMMENT 'E.g. Term-1 Report Card - Secondary 2025-26',
  `schedule_date`         DATE DEFAULT NULL            COMMENT 'When marksheet is to be issued',
  -- Status (via sys_dropdowns)
  `status_id`             INT UNSIGNED NOT NULL        COMMENT 'FK → sys_dropdowns.id (DRAFT, COMPUTED, REVIEWED, PUBLISHED, LOCKED)',
  -- Computation tracking
  `last_computed_at`      DATETIME DEFAULT NULL        COMMENT 'Timestamp of last successful computation',
  `total_students`        INT UNSIGNED DEFAULT NULL    COMMENT 'Total students in this schedule (populated after computation)',
  -- Lock/Unlock
  `is_locked`             TINYINT(1) NOT NULL DEFAULT 0,
  `locked_at`             DATETIME DEFAULT NULL,
  `locked_by`             INT UNSIGNED DEFAULT NULL    COMMENT 'FK → sys_users.id',
  `unlock_reason`         TEXT DEFAULT NULL            COMMENT 'Mandatory reason when admin unlocks a published schedule',
  `unlocked_at`           DATETIME DEFAULT NULL,
  `unlocked_by`           INT UNSIGNED DEFAULT NULL    COMMENT 'FK → sys_users.id',
  -- Standard
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED NOT NULL,
  `updated_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT NULL,
  `updated_at`            TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_ms_session_code` (`academic_session_id`, `code`),
  KEY `idx_msh_ms_template` (`config_template_id`),
  KEY `idx_msh_ms_status` (`status_id`),
  KEY `idx_msh_ms_session` (`academic_session_id`),
  CONSTRAINT `fk_msh_ms_template` FOREIGN KEY (`config_template_id`) REFERENCES `msh_config_templates` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_msh_ms_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_msh_ms_status` FOREIGN KEY (`status_id`) REFERENCES `sys_dropdowns` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Marksheet generation event. Tracks lifecycle: DRAFT → COMPUTED → REVIEWED → PUBLISHED → LOCKED.';


-- -------------------------------------------------------------------------
-- TABLE 16: msh_schedule_class_jnt
-- Purpose: Which class-sections are included in a schedule.
-- Row Volume: ~5-20 per schedule
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_schedule_class_jnt` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `schedule_id`           INT UNSIGNED NOT NULL        COMMENT 'FK → msh_marksheet_schedules.id',
  `class_section_id`      INT UNSIGNED NOT NULL        COMMENT 'FK → sch_class_section_jnt.id',
  -- Standard
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED NOT NULL,
  `updated_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT NULL,
  `updated_at`            TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_scj_schedule_class` (`schedule_id`, `class_section_id`),
  KEY `idx_msh_scj_class_section` (`class_section_id`),
  CONSTRAINT `fk_msh_scj_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `msh_marksheet_schedules` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msh_scj_class_section` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Junction: class-sections included in a marksheet schedule.';


-- =========================================================================
-- SECTION 4: RESULT TABLES (6 tables)
-- System-computed results. Written by ComputeMarksheetJob.
-- =========================================================================


-- -------------------------------------------------------------------------
-- TABLE 17: msh_student_results
-- Purpose: Aggregate result per student per schedule.
-- Contains: grand total, percentage, grade, rank, division, promotion.
-- Row Volume: ~500-2000 per schedule (one per student)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_student_results` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `schedule_id`           INT UNSIGNED NOT NULL        COMMENT 'FK → msh_marksheet_schedules.id',
  `student_id`            INT UNSIGNED NOT NULL        COMMENT 'FK → std_students.id',
  `class_section_id`      INT UNSIGNED NOT NULL        COMMENT 'FK → sch_class_section_jnt.id (denormalized for query)',
  -- Aggregate Scores
  `grand_total`           DECIMAL(8,2) DEFAULT NULL    COMMENT 'Sum of all subject totals',
  `grand_max`             DECIMAL(8,2) DEFAULT NULL    COMMENT 'Sum of all subject max marks',
  `overall_percentage`    DECIMAL(5,2) DEFAULT NULL    COMMENT 'grand_total / grand_max * 100',
  `overall_grade`         VARCHAR(10) DEFAULT NULL     COMMENT 'From slb_grade_division_master (A1, A2, B1, etc.)',
  `division`              VARCHAR(30) DEFAULT NULL     COMMENT 'First Division, Second Division, Third Division, etc.',
  -- Rank
  `rank_in_section`       INT UNSIGNED DEFAULT NULL    COMMENT 'Rank within class-section (dense ranking)',
  `rank_in_class`         INT UNSIGNED DEFAULT NULL    COMMENT 'Rank within class (across all sections)',
  -- Promotion
  `total_subjects`        TINYINT UNSIGNED DEFAULT NULL,
  `subjects_passed`       TINYINT UNSIGNED DEFAULT NULL,
  `subjects_failed`       TINYINT UNSIGNED DEFAULT NULL,
  `promotion_status`      VARCHAR(30) DEFAULT NULL     COMMENT 'PROMOTED, DETAINED, COMPARTMENT, PLACED',
  -- Result status
  `result_status`         VARCHAR(20) DEFAULT NULL     COMMENT 'DECLARED, WITHHELD',
  `withheld_reason`       VARCHAR(255) DEFAULT NULL,
  -- Standard
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED NOT NULL,
  `updated_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT NULL,
  `updated_at`            TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_sr_schedule_student` (`schedule_id`, `student_id`),
  KEY `idx_msh_sr_student` (`student_id`),
  KEY `idx_msh_sr_class_section` (`class_section_id`),
  KEY `idx_msh_sr_rank` (`schedule_id`, `class_section_id`, `rank_in_section`),
  CONSTRAINT `fk_msh_sr_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `msh_marksheet_schedules` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msh_sr_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_msh_sr_class_section` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Aggregate result per student per schedule: total, grade, rank, division, promotion.';


-- -------------------------------------------------------------------------
-- TABLE 18: msh_student_subject_results
-- Purpose: Per-subject result per student per schedule.
-- Contains: theory marks, practical marks, IA total, component breakdowns,
-- subject total, grade, pass/fail.
-- Row Volume: ~3000-15000 per schedule (~6-8 subjects × 500 students)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_student_subject_results` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `schedule_id`           INT UNSIGNED NOT NULL        COMMENT 'FK → msh_marksheet_schedules.id',
  `student_id`            INT UNSIGNED NOT NULL        COMMENT 'FK → std_students.id',
  `subject_id`            INT UNSIGNED NOT NULL        COMMENT 'FK → sch_subjects.id',
  -- Exam component (weighted sum of all exam-type marks)
  `exam_weighted_total`   DECIMAL(8,2) DEFAULT NULL    COMMENT 'Weighted sum of exam marks for this subject',
  -- Theory / Practical split (NULL if subject has no practical)
  `theory_marks`          DECIMAL(8,2) DEFAULT NULL    COMMENT 'Theory portion marks (after exam weightage)',
  `practical_marks`       DECIMAL(8,2) DEFAULT NULL    COMMENT 'Practical portion marks (NULL if no practical)',
  -- Other components
  `homework_score`        DECIMAL(8,2) DEFAULT NULL    COMMENT 'Homework component score for this subject',
  `quiz_score`            DECIMAL(8,2) DEFAULT NULL    COMMENT 'Quiz component score for this subject',
  `quest_score`           DECIMAL(8,2) DEFAULT NULL    COMMENT 'Quest component score for this subject',
  `ia_total`              DECIMAL(8,2) DEFAULT NULL    COMMENT 'Sum of all IA component marks for this subject',
  -- Aggregate
  `subject_total`         DECIMAL(8,2) DEFAULT NULL    COMMENT 'Total marks for this subject (all components combined)',
  `subject_max`           DECIMAL(8,2) DEFAULT NULL    COMMENT 'Maximum possible marks for this subject',
  `subject_percentage`    DECIMAL(5,2) DEFAULT NULL,
  `subject_grade`         VARCHAR(10) DEFAULT NULL     COMMENT 'From slb_grade_division_master',
  `is_passed`             TINYINT(1) DEFAULT NULL      COMMENT '1=pass, 0=fail, NULL=not computed',
  -- Standard
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED NOT NULL,
  `updated_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT NULL,
  `updated_at`            TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_ssr_schedule_student_subject` (`schedule_id`, `student_id`, `subject_id`),
  KEY `idx_msh_ssr_student` (`student_id`),
  KEY `idx_msh_ssr_subject` (`subject_id`),
  CONSTRAINT `fk_msh_ssr_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `msh_marksheet_schedules` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msh_ssr_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_msh_ssr_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Per-subject result per student: exam weighted, theory, practical, HW, Quiz, Quest, IA, total, grade.';


-- -------------------------------------------------------------------------
-- TABLE 19: msh_student_subject_exam_marks
-- Purpose: Raw marks per exam-type per subject per student.
-- This is the core marksheet matrix (the cells of the table).
-- Row Volume: ~15000-80000 per schedule (~6 exams × 8 subjects × 500 students)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_student_subject_exam_marks` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `schedule_id`           INT UNSIGNED NOT NULL        COMMENT 'FK → msh_marksheet_schedules.id',
  `student_id`            INT UNSIGNED NOT NULL        COMMENT 'FK → std_students.id',
  `subject_id`            INT UNSIGNED NOT NULL        COMMENT 'FK → sch_subjects.id',
  `exam_type_id`          INT UNSIGNED NOT NULL        COMMENT 'FK → lms_exam_types.id (UT-1, UT-2, HY-EXAM, etc.)',
  -- Marks
  `marks_obtained`        DECIMAL(8,2) DEFAULT NULL    COMMENT 'Marks obtained. NULL = not attempted or ABSENT',
  `max_marks`             DECIMAL(8,2) DEFAULT NULL    COMMENT 'Max possible marks for this exam-subject',
  `result_status`         VARCHAR(20) DEFAULT NULL     COMMENT 'PASS, FAIL, ABSENT, WITHHELD (from lms_exam_results)',
  -- Source reference (for traceability)
  `exam_result_id`        INT UNSIGNED DEFAULT NULL    COMMENT 'FK → lms_exam_results.id (source record)',
  -- Standard
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED NOT NULL,
  `updated_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT NULL,
  `updated_at`            TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_ssem_schedule_student_subject_exam` (`schedule_id`, `student_id`, `subject_id`, `exam_type_id`),
  KEY `idx_msh_ssem_student` (`student_id`),
  KEY `idx_msh_ssem_subject` (`subject_id`),
  KEY `idx_msh_ssem_exam_type` (`exam_type_id`),
  KEY `idx_msh_ssem_exam_result` (`exam_result_id`),
  CONSTRAINT `fk_msh_ssem_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `msh_marksheet_schedules` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msh_ssem_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_msh_ssem_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_msh_ssem_exam_type` FOREIGN KEY (`exam_type_id`) REFERENCES `lms_exam_types` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Raw exam marks matrix: student × subject × exam-type. Core marksheet data.';


-- -------------------------------------------------------------------------
-- TABLE 20: msh_student_ia_marks
-- Purpose: IA component marks per student per subject per schedule.
-- Entered by teacher via SC-MSG-12a.
-- Row Volume: ~6000-20000 per schedule (~2-4 IA components × 8 subjects × 500 students)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_student_ia_marks` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `schedule_id`           INT UNSIGNED NOT NULL        COMMENT 'FK → msh_marksheet_schedules.id',
  `student_id`            INT UNSIGNED NOT NULL        COMMENT 'FK → std_students.id',
  `subject_id`            INT UNSIGNED NOT NULL        COMMENT 'FK → sch_subjects.id',
  `ia_component_id`       INT UNSIGNED NOT NULL        COMMENT 'FK → msh_template_ia_components.id',
  `marks_obtained`        DECIMAL(5,2) DEFAULT NULL    COMMENT 'Marks entered by teacher. NULL = not yet entered',
  `max_marks`             DECIMAL(5,2) NOT NULL        COMMENT 'Copied from msh_template_ia_components.max_marks',
  `entered_by`            INT UNSIGNED DEFAULT NULL    COMMENT 'FK → sys_users.id (teacher who entered)',
  `entered_at`            DATETIME DEFAULT NULL,
  -- Standard
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED NOT NULL,
  `updated_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT NULL,
  `updated_at`            TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_siam_schedule_student_subject_ia` (`schedule_id`, `student_id`, `subject_id`, `ia_component_id`),
  KEY `idx_msh_siam_student` (`student_id`),
  KEY `idx_msh_siam_subject` (`subject_id`),
  KEY `idx_msh_siam_ia_component` (`ia_component_id`),
  CONSTRAINT `fk_msh_siam_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `msh_marksheet_schedules` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msh_siam_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_msh_siam_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_msh_siam_ia` FOREIGN KEY (`ia_component_id`) REFERENCES `msh_template_ia_components` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='IA marks per student per subject (Notebook, Enrichment, etc.). Teacher manual entry.';


-- -------------------------------------------------------------------------
-- TABLE 21: msh_student_coscholastic_results
-- Purpose: Co-Scholastic grades per student per schedule.
-- Entered by class teacher; Discipline auto-populated from BA if linked.
-- Row Volume: ~1500-3000 per schedule (~3-5 areas × 500 students)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_student_coscholastic_results` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `schedule_id`           INT UNSIGNED NOT NULL        COMMENT 'FK → msh_marksheet_schedules.id',
  `student_id`            INT UNSIGNED NOT NULL        COMMENT 'FK → std_students.id',
  `coscholastic_component_id` INT UNSIGNED NOT NULL    COMMENT 'FK → msh_template_coscholastic_components.id',
  `grade`                 VARCHAR(10) DEFAULT NULL     COMMENT 'A, B, C, D, E — entered by teacher or from BA',
  `remarks`               VARCHAR(255) DEFAULT NULL,
  `entered_by`            INT UNSIGNED DEFAULT NULL    COMMENT 'FK → sys_users.id (teacher). NULL if auto from BA',
  `entered_at`            DATETIME DEFAULT NULL,
  `is_auto_from_ba`       TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 if grade was auto-populated from BehaviouralAssessment',
  -- Standard
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED NOT NULL,
  `updated_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT NULL,
  `updated_at`            TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_scsr_schedule_student_component` (`schedule_id`, `student_id`, `coscholastic_component_id`),
  KEY `idx_msh_scsr_student` (`student_id`),
  KEY `idx_msh_scsr_component` (`coscholastic_component_id`),
  CONSTRAINT `fk_msh_scsr_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `msh_marksheet_schedules` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msh_scsr_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_msh_scsr_component` FOREIGN KEY (`coscholastic_component_id`) REFERENCES `msh_template_coscholastic_components` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Co-Scholastic grades per student (Work Ed, Art, Health & PE, Discipline).';


-- -------------------------------------------------------------------------
-- TABLE 22: msh_student_attendance
-- Purpose: Attendance summary per student per schedule (for marksheet).
-- Manual entry in Phase 1; auto-populate from Attendance module in Phase 2.
-- Row Volume: ~500-2000 per schedule (one per student)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_student_attendance` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `schedule_id`           INT UNSIGNED NOT NULL        COMMENT 'FK → msh_marksheet_schedules.id',
  `student_id`            INT UNSIGNED NOT NULL        COMMENT 'FK → std_students.id',
  `total_working_days`    SMALLINT UNSIGNED DEFAULT NULL COMMENT 'Total working days in the period',
  `days_present`          SMALLINT UNSIGNED DEFAULT NULL COMMENT 'Days student was present',
  `entered_by`            INT UNSIGNED DEFAULT NULL    COMMENT 'FK → sys_users.id. NULL if auto from attendance module',
  `is_auto_populated`     TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 if fetched from Attendance module',
  -- Standard
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED NOT NULL,
  `updated_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT NULL,
  `updated_at`            TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_msh_sa_schedule_student` (`schedule_id`, `student_id`),
  KEY `idx_msh_sa_student` (`student_id`),
  CONSTRAINT `fk_msh_sa_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `msh_marksheet_schedules` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_msh_sa_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Attendance summary per student per schedule. Manual entry Phase 1; auto Phase 2.';


-- =========================================================================
-- SECTION 5: AUDIT TABLE (1 table)
-- =========================================================================


-- -------------------------------------------------------------------------
-- TABLE 23: msh_computation_logs
-- Purpose: Immutable log of each computation run.
-- Row Volume: ~10-30 per school per session
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `msh_computation_logs` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `schedule_id`           INT UNSIGNED NOT NULL        COMMENT 'FK → msh_marksheet_schedules.id',
  `action`                VARCHAR(30) NOT NULL         COMMENT 'COMPUTE, RECOMPUTE, PUBLISH, UNLOCK, LOCK',
  `triggered_by`          INT UNSIGNED NOT NULL        COMMENT 'FK → sys_users.id',
  `started_at`            DATETIME NOT NULL,
  `completed_at`          DATETIME DEFAULT NULL,
  `duration_seconds`      INT UNSIGNED DEFAULT NULL,
  `total_students`        INT UNSIGNED DEFAULT NULL,
  `total_errors`          INT UNSIGNED DEFAULT 0,
  `status`                VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS' COMMENT 'IN_PROGRESS, SUCCESS, FAILED, PARTIAL',
  `error_log`             TEXT DEFAULT NULL            COMMENT 'JSON array of error messages if any',
  `remarks`               TEXT DEFAULT NULL            COMMENT 'Unlock reason, recomputation notes, etc.',
  -- Standard (no deleted_at — immutable audit log)
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED NOT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT NULL,
  `updated_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_msh_cl_schedule` (`schedule_id`),
  KEY `idx_msh_cl_triggered_by` (`triggered_by`),
  KEY `idx_msh_cl_action` (`action`),
  CONSTRAINT `fk_msh_cl_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `msh_marksheet_schedules` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Immutable audit log: computation runs, publish/unlock events. No deleted_at.';


-- =========================================================================
-- TABLE SUMMARY
-- =========================================================================
-- #  | Table Name                              | Domain         | Row Volume
-- ---|----------------------------------------|----------------|------------------
-- 1  | msh_marksheet_types                     | Master         | ~5-8 / school
-- 2  | msh_source_components                   | Master         | 4 (fixed seed)
-- 3  | msh_ia_component_types                  | Master         | ~4-6 / school
-- 4  | msh_class_groups                        | Configuration  | ~3-5 / school
-- 5  | msh_class_group_items_jnt               | Configuration  | ~15-20 / school
-- 6  | msh_exam_groups                         | Configuration  | ~2-4 / session
-- 7  | msh_exam_group_items_jnt                | Configuration  | ~6-12 / session
-- 8  | msh_config_templates                    | Configuration  | ~3-6 / session
-- 9  | msh_template_scholastic_components      | Configuration  | ~3-4 / template
-- 10 | msh_template_exam_weightages            | Configuration  | ~3-6 / template
-- 11 | msh_template_ia_components              | Configuration  | ~2-4 / template
-- 12 | msh_template_coscholastic_components    | Configuration  | ~3-5 / template
-- 13 | msh_class_config_jnt                    | Configuration  | ~10-20 / session
-- 14 | msh_subject_practical_configs           | Configuration  | ~5-15 / school
-- 15 | msh_marksheet_schedules                 | Schedule       | ~4-10 / session
-- 16 | msh_schedule_class_jnt                  | Schedule       | ~5-20 / schedule
-- 17 | msh_student_results                     | Result         | ~500-2000 / schedule
-- 18 | msh_student_subject_results             | Result         | ~3K-15K / schedule
-- 19 | msh_student_subject_exam_marks          | Result         | ~15K-80K / schedule
-- 20 | msh_student_ia_marks                    | Result         | ~6K-20K / schedule
-- 21 | msh_student_coscholastic_results        | Result         | ~1.5K-3K / schedule
-- 22 | msh_student_attendance                  | Result         | ~500-2K / schedule
-- 23 | msh_computation_logs                    | Audit          | ~10-30 / session
-- =========================================================================


-- =========================================================================
-- LARAVEL MIGRATION CHECKLIST
-- =========================================================================
-- Migration files go in: database/migrations/tenant/
--
-- 2026_04_13_000001_create_msh_marksheet_types_table.php
-- 2026_04_13_000002_create_msh_source_components_table.php
-- 2026_04_13_000003_create_msh_ia_component_types_table.php
-- 2026_04_13_000004_create_msh_class_groups_table.php
-- 2026_04_13_000005_create_msh_class_group_items_jnt_table.php
-- 2026_04_13_000006_create_msh_exam_groups_table.php
-- 2026_04_13_000007_create_msh_exam_group_items_jnt_table.php
-- 2026_04_13_000008_create_msh_config_templates_table.php
-- 2026_04_13_000009_create_msh_template_scholastic_components_table.php
-- 2026_04_13_000010_create_msh_template_exam_weightages_table.php
-- 2026_04_13_000011_create_msh_template_ia_components_table.php
-- 2026_04_13_000012_create_msh_template_coscholastic_components_table.php
-- 2026_04_13_000013_create_msh_class_config_jnt_table.php
-- 2026_04_13_000014_create_msh_subject_practical_configs_table.php
-- 2026_04_13_000015_create_msh_marksheet_schedules_table.php
-- 2026_04_13_000016_create_msh_schedule_class_jnt_table.php
-- 2026_04_13_000017_create_msh_student_results_table.php
-- 2026_04_13_000018_create_msh_student_subject_results_table.php
-- 2026_04_13_000019_create_msh_student_subject_exam_marks_table.php
-- 2026_04_13_000020_create_msh_student_ia_marks_table.php
-- 2026_04_13_000021_create_msh_student_coscholastic_results_table.php
-- 2026_04_13_000022_create_msh_student_attendance_table.php
-- 2026_04_13_000023_create_msh_computation_logs_table.php
--
-- SEEDER:
-- MarksheetGenerationDatabaseSeeder.php
--   → Seeds msh_source_components (4 rows: EXAM, HOMEWORK, QUIZ, QUEST)
--   → Seeds msh_ia_component_types (4 rows: NOTEBOOK, SUB_ENRICHMENT, PERIODIC_ASSESS, PARTICIPATION)
--   → Seeds sys_dropdowns entries for msh_marksheet_schedules.status_id
--     Key: 'msh_marksheet_schedules.status_id'
--     Values: DRAFT, COMPUTED, REVIEWED, PUBLISHED, LOCKED
-- =========================================================================
