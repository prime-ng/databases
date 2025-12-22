/********************************************************************************************
 *
 *   TIMETABLE MODULE - COMPLETE CANONICAL SCHEMA (MySQL 8, Laravel-Friendly)
 *   Includes:
 *     - Period Sets
 *     - Class Mode Rules (per timetable mode)
 *     - Class Groups + Requirements + Subgroups
 *     - Timetable Runs (Mode-aware)
 *     - Timetable Cells
 *     - Cell Subgroups & Teachers
 *     - Substitution Log
 *     - Generic Constraints
 *
 ********************************************************************************************/



CREATE TABLE `tt_timetable_mode` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  `code` VARCHAR(50) NOT NULL,          -- NORMAL, HALF_YEARLY, TODDLER_NORMAL
  `name` VARCHAR(100) NOT NULL,         -- Human readable
  `description` VARCHAR(255) DEFAULT NULL,

  -- Behaviour flags (global defaults, overridable at class level)
  `has_exam` TINYINT(1) NOT NULL DEFAULT 0,
  `has_teaching` TINYINT(1) NOT NULL DEFAULT 1,

  `is_active` TINYINT(1) NOT NULL DEFAULT 1,

  -- Laravel
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,

  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_timetable_mode_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_period_type` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  `code` VARCHAR(30) NOT NULL,        -- TEACHING, EXAM, BREAK, ACTIVITY
  `name` VARCHAR(50) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,

  -- Behaviour hints
  `counts_as_teaching` TINYINT(1) NOT NULL DEFAULT 0,
  `counts_as_exam` TINYINT(1) NOT NULL DEFAULT 0,

  `is_active` TINYINT(1) NOT NULL DEFAULT 1,

  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,

  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_period_type_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_teacher_role` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  `code` VARCHAR(50) NOT NULL,      -- PRIMARY, ASSISTANT, SUBSTITUTE, OBSERVER
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,

  -- Behaviour flags
  `is_primary_instructor` TINYINT(1) NOT NULL DEFAULT 0,
  `counts_for_workload` TINYINT(1) NOT NULL DEFAULT 1,
  `allows_overlap` TINYINT(1) NOT NULL DEFAULT 0,

  `is_active` TINYINT(1) NOT NULL DEFAULT 1,

  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,

  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_teacher_role_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ------------------------------
-- 1. PERIOD SET TABLES
-- ------------------------------

-- Defines different period sets (e.g., Normal Day, Half-Day, Exam Day)
CREATE TABLE IF NOT EXISTS `tt_period_set` (0
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,                 -- e.g., "NORMAL_8P", "TODDLER_6P", "EXAM_3P". "EXAM_2P", "HALF_DAY_4P", "EVENT_DAY_0P"
  `description` VARCHAR(255) DEFAULT NULL,      -- optional description
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Periods within a period set
CREATE TABLE IF NOT EXISTS `tt_period_set_period` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `period_set_id` BIGINT UNSIGNED NOT NULL,       -- FK to tt_period_set.period_set_id
  `period_ord` INT UNSIGNED NOT NULL,             -- Order/index of the period in the set (1,2,3,...)
  `start_time` TIME NOT NULL,                     -- Start time of the period
  `end_time` TIME NOT NULL,                       -- End time of the period 
  `period_type_dropdown_id` BIGINT UNSIGNED NULL, -- FK to (sys_dropdown_table.id) reference for period type (e.g., TEACHING, BREAK, LUNCH)
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_psp_period_set` (`period_set_id`),
  CONSTRAINT `fk_psp_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_set`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------
-- 2. CLASS MODE RULES (MODE-SPECIFIC BEHAVIOR)
-- ----------------------------------------------

-- Defines how each class behaves under different timetable modes
CREATE TABLE IF NOT EXISTS `tt_class_mode_rule` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `class_id` BIGINT UNSIGNED NOT NULL,                        -- FK to sch_classes.id (external)
  `mode_dropdown_id` BIGINT UNSIGNED NOT NULL,                -- FK to (sys_dropdown_table.id) for Timetable Mode (e.g., NORMAL, HALF_YEARLY)
  `allow_teaching_periods` TINYINT(1) NOT NULL DEFAULT 1,     -- Is teaching allowed at all in this timetable mode for this class?
  `exam_period_count` INT UNSIGNED DEFAULT NULL,              -- Number of exam periods
  `teaching_after_exam_flag` TINYINT(1) NOT NULL DEFAULT 0,   -- Whether teaching happen after exam periods on the same day?
  `period_set_id` BIGINT UNSIGNED NOT NULL,                   -- Which period set applies
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cmr_class_mode` (`class_id`, `mode_dropdown_id`),
  CONSTRAINT `fk_cmr_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_set`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------
-- 3. CLASS GROUPS + REQUIREMENTS + SUBGROUPS
-- ----------------------------------------------

-- CREATE TABLE IF NOT EXISTS `tt_class_group` (
--   `class_group_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
--   `class_id` BIGINT UNSIGNED NOT NULL,       -- sch_classes.id
--   `subject_id` BIGINT UNSIGNED NOT NULL,     -- sch_subjects.id
--   `notes` VARCHAR(255) DEFAULT NULL,
--   `created_at` TIMESTAMP NULL DEFAULT NULL,
--   `updated_at` TIMESTAMP NULL DEFAULT NULL,
--   PRIMARY KEY (`class_group_id`),
--   KEY `idx_cg_class` (`class_id`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



-- e.g., 7th-A Science Lecture Major, 10th-B Math Lab Optional
--`tt_class_group` is Not required Insted we will be using 'sch_subject_study_format_class_subj_types_jnt' table from tenant_db.
CREATE TABLE IF NOT EXISTS `tt_class_subgroup` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `subject_Study_format_id` BIGINT UNSIGNED NOT NULL,    -- FK → sch_subject_study_format_jnt.id
  `subgroup_code` VARCHAR(20) NOT NULL,         -- A, B, LAB1
  `name` VARCHAR(100) NOT NULL,
  `student_count` INT UNSIGNED DEFAULT NULL,    -- number of students in this subgroup
  `is_shared_across_classes` TINYINT(1) NOT NULL DEFAULT 0,   -- whether this subgroup is shared across multiple classes
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subgroup_code` (`class_group_id`,`subgroup_code`),
  CONSTRAINT `fk_csg_class_group` FOREIGN KEY (`subject_Study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- Data Seed for Subgroup_Code: A, B, C, LAB1, LAB2, PRACTICAL1, PRACTICAL2, TUTORIAL1, TUTORIAL2, GROUP1, GROUP2, etc. 
-- ├──────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
-- │ Subgroup Code  | Name                            │Class+Sec│ Subject │ Study Format │ Acrss Class │ St Count │
-- │──────────────────────────────────────────────────────────────────────────────────────────────────────────────│
-- │ 7th_French_LAC │ 7th Class(All Sections) French  │ 7th_A   │ French  │ Lecture.     │     No.     │ 12       │
-- │ 7th_French_LAC │ 7th Class(All Sections) French  │ 7th_B   │ French  │ Lecture.     │     No.     │ 10       │
-- │ 7th_French_LAC │ 7th Class(All Sections) French  │ 7th_C   │ French  │ Lecture.     │     No.     │ 12       │

CREATE TABLE  IF NOT EXISTS `tt_class_group_requirement` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `class_group_id` BIGINT UNSIGNED NOT NULL,            -- FK to sch_subject_study_format_class_subj_types_jnt.id
  `weekly_periods` TINYINT UNSIGNED NOT NULL,           -- number of periods per week
  `max_per_day` TINYINT UNSIGNED DEFAULT NULL,          -- maximum periods per day
  `min_gap_periods` TINYINT UNSIGNED DEFAULT NULL,      -- minimum gap (in periods) between same subject periods
  `allow_consecutive` TINYINT(1) NOT NULL DEFAULT 0,    -- whether consecutive periods are allowed
  `must_first_or_last` ENUM('NONE','FIRST','LAST','FIRST_OR_LAST') NOT NULL DEFAULT 'NONE',
  `notes` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cgr_class_group` (`class_group_id`),
  CONSTRAINT `fk_cgr_class_group` FOREIGN KEY (`class_group_id`) REFERENCES `sch_subject_study_format_class_subj_types_jnt` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



-- ----------------------------------------------
-- 4. TIMETABLE GENERATION RUNS (MODE-AWARE)
-- ----------------------------------------------

CREATE TABLE IF NOT EXISTS `tt_generation_run` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `mode_dropdown_id` BIGINT UNSIGNED NOT NULL,  -- e.g., NORMAL, HALF_YEARLY, TODDLER_NORMAL
  `period_set_id` BIGINT UNSIGNED NOT NULL,
  `session_id` BIGINT UNSIGNED NULL,            -- academic session/year
  `started_at` DATETIME NOT NULL,
  `finished_at` DATETIME DEFAULT NULL,
  `status` ENUM('RUNNING','SUCCESS','FAILED','CANCELLED') DEFAULT 'RUNNING',
  `algorithm` VARCHAR(50) DEFAULT 'heuristic',
  `params_json` JSON DEFAULT NULL,
  `stats_json` JSON DEFAULT NULL,
  `created_by` BIGINT UNSIGNED NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_gr_mode` (`mode_dropdown_id`),
  KEY `idx_gr_period_set` (`period_set_id`),
  CONSTRAINT `fk_gr_period_set`
    FOREIGN KEY (`period_set_id`)
    REFERENCES `tt_period_set`(`id`)
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------
-- 5. TIMETABLE CELLS (MAIN SCHEDULE STRUCTURE)
-- ----------------------------------------------

CREATE TABLE IF NOT EXISTS `tt_timetable_cell` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `run_id` BIGINT UNSIGNED NOT NULL,
  `mode_dropdown_id` BIGINT UNSIGNED NOT NULL,     -- sys_dropdown_table
  `period_set_id` BIGINT UNSIGNED NOT NULL,        -- which period set applies
  `date` DATE NOT NULL,
  `period_ord` INT UNSIGNED NOT NULL,              -- period index from tt_period_set_period
  `class_group_id` BIGINT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `study_format_dropdown_id` BIGINT UNSIGNED NULL,
  `room_id` BIGINT UNSIGNED NULL,
  `locked` TINYINT(1) NOT NULL DEFAULT 0,
  `source` ENUM('AUTO','MANUAL','ADJUST') NOT NULL DEFAULT 'AUTO',
  `notes` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_tc_run_date` (`run_id`, `date`),
  KEY `idx_tc_class_group` (`class_group_id`),
  KEY `idx_tc_room` (`room_id`),
  CONSTRAINT `fk_tc_run` FOREIGN KEY (`run_id`) REFERENCES `tt_generation_run`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tc_cg` FOREIGN KEY (`class_group_id`) REFERENCES `tt_class_group`(`class_group_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tt_timetable_cell` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `run_id` BIGINT UNSIGNED NOT NULL,
  `mode_dropdown_id` BIGINT UNSIGNED NOT NULL,    -- sys_dropdown_table
  `period_set_id` BIGINT UNSIGNED NOT NULL,       -- which period set applies
  `date` DATE NOT NULL,                             -- date of the cell
  `period_ord` TINYINT UNSIGNED NOT NULL,       -- period index from tt_period_set_period
  `class_group_id` BIGINT UNSIGNED NOT NULL,  -- FK → sch_subject_study_format_class_subj_types_jnt.id
  `room_id` BIGINT UNSIGNED DEFAULT NULL,  -- Room must match rooms_type_id from class_group
  `locked` TINYINT(1) NOT NULL DEFAULT 0,
  `source` ENUM('AUTO','MANUAL','ADJUST') NOT NULL DEFAULT 'AUTO',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_tc_run_date` (`run_id`,`date`),
  KEY `idx_tc_class_group` (`class_group_id`),
  CONSTRAINT `fk_tc_run` FOREIGN KEY (`run_id`) REFERENCES `tt_generation_run`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tc_class_group` FOREIGN KEY (`class_group_id`) REFERENCES `sch_subject_study_format_class_subj_types_jnt` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------
-- 6. CELL-SUBGROUP & CELL-TEACHER
-- ----------------------------------------------

CREATE TABLE IF NOT EXISTS `tt_timetable_cell_subgroup` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cell_id` BIGINT UNSIGNED NOT NULL,
  `class_subgroup_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  PRIMARY KEY (`cell_id`, `class_subgroup_id`),
  CONSTRAINT `fk_tcs_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cell`(`cell_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tcs_csg` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroup`(`class_subgroup_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE IF NOT EXISTS `tt_timetable_cell_teacher` (
  `cell_id` BIGINT UNSIGNED NOT NULL,
  `teacher_id` BIGINT UNSIGNED NOT NULL,              -- maps to teachers/users table
  `teacher_role_dropdown_id` BIGINT UNSIGNED NULL,    -- sys_dropdown_table id
  PRIMARY KEY (`cell_id`, `teacher_id`),
  CONSTRAINT `fk_tct_cell`
    FOREIGN KEY (`cell_id`)
    REFERENCES `tt_timetable_cell`(`cell_id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------
-- 7. SUBSTITUTION LOG
-- ----------------------------------------------

CREATE TABLE IF NOT EXISTS `tt_substitution_log` (
  `sub_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cell_id` BIGINT UNSIGNED NOT NULL,
  `absent_teacher_id` BIGINT UNSIGNED NOT NULL,
  `substitute_teacher_id` BIGINT UNSIGNED NOT NULL,
  `reason` VARCHAR(255) DEFAULT NULL,
  `decided_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`sub_id`),
  KEY `idx_sub_cell` (`cell_id`),
  CONSTRAINT `fk_sub_cell`
    FOREIGN KEY (`cell_id`)
    REFERENCES `tt_timetable_cell`(`cell_id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------
-- 8. GENERIC CONSTRAINT ENGINE
-- ----------------------------------------------

CREATE TABLE IF NOT EXISTS `tt_constraint` (
  `constraint_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(200) NOT NULL,
  `target_type` ENUM('TEACHER','CLASS_GROUP','ROOM','GLOBAL') NOT NULL,
  `target_id` BIGINT UNSIGNED NULL,
  `is_hard` TINYINT(1) NOT NULL DEFAULT 0,
  `weight` INT UNSIGNED NOT NULL DEFAULT 100,   -- 0–100
  `rule_json` JSON NOT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`constraint_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------
-- ADDITIONAL TABLE: CLASS GROUP V2
-- ----------------------------------------------
-- e.g., 7th-A Science Lecture Major, 10th-B Math Lab Optional
--`tt_class_group` is Not required Insted we will be using 'sch_subject_study_format_class_subj_types_jnt' table from tenant_db.



-- MySQL cannot enforce FK -> sys_dropdown_table easily
-- (because it's typed loosely and shared across groups).
-- So Laravel validation is recommended instead.



-- Data seed for below Keys in dropdown table:
-- TIMETABLE_MODE: NORMAL, HALF_YEARLY, EXAM, TODDLER_NORMAL, ANNUAL_EXAM
-- PERIOD_TYPE: TEACHING, BREAK, LUNCH, ASSEMBLY, EXAM, FREE_PERIOD, ACTIVITY, SPORTS, OTHER
-- TEACHER_ROLE: MAIN_TEACHER, ASSISTANT_TEACHER, SUBSTITUTE_TEACHER, OTHER
-- End of tim_timetable_v1.sql








-- ------------------------------------------------------
-- Old Versions Below - To be Deleted
-- ------------------------------------------------------
-- We will create Group accros classes who can be taught in a single group like 'Dance' can be taught in a single group from class 6-10th,
-- but we need to have a separate group for junior classes for same subject 'Dance'

-- subject_group is grouping of Subject+Study Format+Class+Section+Subject Type.
-- It answer whether 'Science' 'Lacture' for 7th-A is Major or Minor.
-- This will also be used to assign Subjects to the Students as a Combo.
-- CREATE TABLE IF NOT EXISTS `tim_class_groups` (
--   `id` bigint unsigned NOT NULL AUTO_INCREMENT,
--   `subject_study_format_id` bigint unsigned NOT NULL,    -- FK
--   `class_section_id` json NOT NULL,                      -- FK
--   `subject_type_id` int unsigned NOT NULL,               -- FK
--   `short_name` varchar(30) NOT NULL,         -- 7th Science, 7th Commerce, 7th-A Science etc.
--   `name` varchar(100) NOT NULL,
--   `class_group_code` VARCHAR(7) NOT NULL,   -- e.g., '7th_A_SCI_LAC','7th_A_SCI_LAB','7th_A_SST_LAC','7th_A_ENG_LAC' (This will be used for Timetable)
--   `is_active` tinyint(1) NOT NULL DEFAULT '1',
--   `deleted_at` timestamp NULL DEFAULT NULL,
--   `created_at` timestamp NULL DEFAULT NULL,
--   `updated_at` timestamp NULL DEFAULT NULL,
--   PRIMARY KEY (`id`),
--   UNIQUE KEY `uq_subGroups_shortName` (`short_name`),
--   UNIQUE KEY `uq_subGroups_classGroupCode` (`class_group_code`),
--   CONSTRAINT `fk_subGroups_subject_format_id` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE,
--   CONSTRAINT `fk_subGroups_class_section_id` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE CASCADE
-- ) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Combination of (class, section, subject, study_format). This will help to combine classes for Optioal Subjects
-- It will answer - which all classes can be combined for a particuler Subject + StudyFormat
-- CREATE TABLE IF NOT EXISTS `tim_class_groups` (
--   `id` bigint unsigned NOT NULL AUTO_INCREMENT,
--   `class_section_id` int unsigned NOT NULL,  -- FK
--   `subject_id` bigint unsigned NOT NULL,     -- FK
--   `study_format_id` int unsigned NOT NULL,
--   `short_name` varchar(20) DEFAULT NULL,
--   `name` varchar(100) DEFAULT NULL,
--   `preferred_weekly_frequency` tinyint unsigned DEFAULT NULL,  -- need to removed from here. this need to be set at Subject+class level
--   `is_active` tinyint(1) NOT NULL DEFAULT '1',
--   `deleted_at` timestamp NULL DEFAULT NULL,
--   `created_at` timestamp NULL DEFAULT NULL,
--   `updated_at` timestamp NULL DEFAULT NULL,
--   PRIMARY KEY (`id`),
--   UNIQUE KEY `uq_cls_grps_section_sub_studyformat` (`class_section_id`,`subject_id`,`study_format_id`),
--   CONSTRAINT `fk_cls_grps_class_section_id` FOREIGN KEY (`class_section_id`) REFERENCES `class_section` (`id`) ON DELETE CASCADE,
--   CONSTRAINT `fk_cls_grps_subject_id` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE,
--   CONSTRAINT `fk_cls_grps_study_format_id` FOREIGN KEY (`study_format_id`) REFERENCES `study_formats` (`id`) ON DELETE CASCADE
-- ) ENGINE=InnoDB AUTO_INCREMENT=501 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- CREATE TABLE IF NOT EXISTS `tim_teacher_constraint` (
--   `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

--   `max_periods_per_week` INT UNSIGNED DEFAULT NULL,
--   `max_periods_per_day` INT UNSIGNED DEFAULT NULL,
--   `max_days_per_week` INT UNSIGNED DEFAULT NULL,
--   PRIMARY KEY (`id`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- CREATE TABLE IF NOT EXISTS `tim_class_sub_group` (
--   `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
--   `subject_id` BIGINT UNSIGNED NOT NULL,       -- Math, Sci
--   `study_format_id` int unsigned NOT NULL,     -- Lecture, Lab
--   `class_section_id` int unsigned NOT NULL,
--   `short_name` varchar(20) DEFAULT NULL,
--   `name` VARCHAR(100) NOT NULL,
--   `description` TEXT DEFAULT NULL,
--   `total_students` INT UNSIGNED DEFAULT NULL,
--   `is_shared_across_classes` TINYINT(1) DEFAULT 0,
--   `is_active` TINYINT(1) DEFAULT 1,
--   `created_at` TIMESTAMP NULL DEFAULT NULL,
--   `updated_at` TIMESTAMP NULL DEFAULT NULL,
--   UNIQUE KEY `uq_sub_comb_group_subj_name` (`subject_id`,`group_name`),
--   CONSTRAINT `fk_sub_comb_group_subj` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE,
--   CONSTRAINT `fk_sub_comb_group_study_format` FOREIGN KEY (`study_format_id`) REFERENCES `study_formats` (`id`) ON DELETE CASCADE
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- CREATE TABLE IF NOT EXISTS `sch_period_definitions` (
--   `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
--   `code` VARCHAR(1) NOT NULL,         -- e.g., '1','2','3' and so on (This will be used for Timetable)
--   `short_name` VARCHAR(10) NOT NULL,  -- e.g., "Period-1 / P-1,P2"
--   `name` VARCHAR(50) NOT NULL,        -- e.g., "Lunch Break, Prayer, Class"
--   `start_time` TIME NOT NULL,
--   `end_time` TIME NOT NULL,
--   `is_break` TINYINT(1) DEFAULT 0,
--   `sort_order` TINYINT UNSIGNED DEFAULT 1,
--   `is_active` TINYINT(1) DEFAULT 1
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
