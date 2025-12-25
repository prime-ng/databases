/****************************************************************************************
 * TIMETABLE MODULE - FINAL SCHEMA
 * Target: MySQL 8.x
 * Stack : PHP + Laravel
 ****************************************************************************************/
-- Change table Name - Table (sch_subject_study_format_class_subj_types_jnt) to (sch_class_groups_jnt) in tenant_db.sql before executing this script.

-- This table defines different timetable modes like Regular, Exam, Special Event etc.

-- -----------------------------------------------------
-- TIMETABLE MODE MASTER
-- -----------------------------------------------------
CREATE TABLE `tim_timetable_mode` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL,                  -- e.g., 'REGULAR','EXAM','SPECIAL_EVENT'
  `name` VARCHAR(100) NOT NULL,                 -- e.g., 'Regular Timetable','Examination Timetable'
  `description` VARCHAR(255) DEFAULT NULL,
  `has_exam` TINYINT(1) NOT NULL DEFAULT 0,     -- Whether this mode includes exam periods
  `has_teaching` TINYINT(1) NOT NULL DEFAULT 1, -- Whether this mode includes teaching periods
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_timetable_mode_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- This table defines different types of periods like Teaching, Examination, Break, Assembly etc.
-- -----------------------------------------------------
-- PERIOD TYPE MASTER
-- -----------------------------------------------------
CREATE TABLE `tim_period_type` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL,                          -- e.g., 'TEACHING','EXAMINATION','BREAK','ASSEMBLY'
  `name` VARCHAR(50) NOT NULL,                          -- e.g., 'Teaching Period','Examination Period' 
  `description` VARCHAR(255) DEFAULT NULL,
  `counts_as_teaching` TINYINT(1) NOT NULL DEFAULT 0,   -- Whether this period type counts as teaching period
  `counts_as_exam` TINYINT(1) NOT NULL DEFAULT 0,       -- Whether this period type counts as examination period
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_period_type_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- This table defines different teacher assignment roles like Primary Instructor, Assistant Instructor, Substitute etc.
-- -----------------------------------------------------
-- TEACHER ASSIGNMENT ROLE MASTER
-- -----------------------------------------------------
CREATE TABLE `tim_teacher_assignment_role` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL,                  -- e.g., 'PRIMARY_INSTRUCTOR','ASSISTANT_INSTRUCTOR','SUBSTITUTE'   
  `name` VARCHAR(100) NOT NULL,                 -- e.g., 'Primary Instructor','Assistant Instructor','Substitute Teacher'
  `description` VARCHAR(255) DEFAULT NULL,
  `is_primary_instructor` TINYINT(1) NOT NULL DEFAULT 0,    -- Whether this role is for primary instructor
  `counts_for_workload` TINYINT(1) NOT NULL DEFAULT 1,      -- Whether this role counts towards workload calculations
  `allows_overlap` TINYINT(1) NOT NULL DEFAULT 0,           -- Whether this role allows overlapping assignments (e.g., Substitute)
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_teacher_assignment_role_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- This table defines different period sets like Normal Day, Exam Day, Half Day etc.
-- -----------------------------------------------------
-- PERIOD SET
-- -----------------------------------------------------
CREATE TABLE `tim_period_set` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL,                  -- e.g., "NORMAL_8P", "TODDLER_6P", "EXAM_3P". "EXAM_2P", "HALF_DAY_4P", "EVENT_DAY_0P"  
  `name` VARCHAR(100) NOT NULL,                 -- e.g., "Normal Day 8 Periods", "Toddler Day 6 Periods", "Examination Day 3 Periods"
  `description` VARCHAR(255) DEFAULT NULL,      -- e.g., "Normal Day with 8 Periods", "Toddler Day with 6 Periods", "Examination Day with 3 Periods"
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
  UNIQUE KEY `uq_period_set_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- This table defines individual periods within a period set.
-- -----------------------------------------------------
-- PERIOD SET PERIOD
-- -----------------------------------------------------
CREATE TABLE `tim_period_set_period` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `period_set_id` BIGINT UNSIGNED NOT NULL,     -- FK to tim_period_set
  `period_ord` TINYINT UNSIGNED NOT NULL,       -- Ordinal number of the period within the set (1, 2, 3, ...)
  `code` VARCHAR(10) NOT NULL,                  -- e.g., "P1", "P2", "P3", "BREAK", "LUNCH"
  `name` VARCHAR(50) NOT NULL,
  `start_time` TIME NOT NULL,                   -- e.g., "09:00:00", "10:00:00"
  `end_time` TIME NOT NULL,                     -- e.g., "09:45:00", "10:45:00"
  `period_type_id` BIGINT UNSIGNED NOT NULL,    -- FK to tim_period_type
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_psp_set_ord` (`period_set_id`,`period_ord`),
  CONSTRAINT `fk_psp_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tim_period_set`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_psp_period_type` FOREIGN KEY (`period_type_id`) REFERENCES `tim_period_type`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- This table links a class to a timetable mode along with specific period set and rules.
-- -----------------------------------------------------
-- CLASS MODE RULE
-- -----------------------------------------------------
CREATE TABLE `tim_class_mode_rule` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `class_id` BIGINT UNSIGNED NOT NULL,                      -- FK to sch_class
  `tt_mode_id` BIGINT UNSIGNED NOT NULL,                       -- FK to tim_timetable_mode
  `period_set_id` BIGINT UNSIGNED NOT NULL,                 -- FK to tim_period_set
  `allow_teaching_periods` TINYINT(1) NOT NULL DEFAULT 1,   -- Whether teaching periods are allowed in this mode for the class
  `allow_exam_periods` TINYINT(1) NOT NULL DEFAULT 0,       -- Whether exam periods are allowed in this mode for the class
  `exam_period_count` TINYINT UNSIGNED DEFAULT NULL,        -- Number of exam periods if exam periods are allowed
  `teaching_after_exam_flag` TINYINT(1) NOT NULL DEFAULT 0, -- Whether teaching periods can be scheduled after exam periods
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cmr_class_mode` (`class_id`,`mode_id`),
  CONSTRAINT `fk_cmr_mode` FOREIGN KEY (`mode_id`) REFERENCES `tim_timetable_mode`(`id`),
  CONSTRAINT `fk_cmr_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tim_period_set`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- This table defines timetable requirements for each class group.
-- -----------------------------------------------------
-- CLASS GROUP REQUIREMENT
-- -----------------------------------------------------
CREATE TABLE `tim_class_group_requirement` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `class_group_id` BIGINT UNSIGNED NOT NULL,            -- FK to sch_class_groups_jnt
  `weekly_periods` TINYINT UNSIGNED NOT NULL,           -- Total number of periods required per week for this class group
  `max_per_day` TINYINT UNSIGNED DEFAULT NULL,          -- Maximum number of periods allowed per day for this class group
  `min_gap_periods` TINYINT UNSIGNED DEFAULT NULL,      -- Minimum gap (in periods) between two sessions of this class group on the same day
  `allow_consecutive` TINYINT(1) NOT NULL DEFAULT 0,    -- Whether consecutive periods are allowed for this class group
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cgr_class_group` (`class_group_id`),
  CONSTRAINT `fk_cgr_class_group` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- This table defines subgroups within a class group for combining or splitting classes or sessions.
-- -----------------------------------------------------
-- CLASS SUBGROUP
-- -----------------------------------------------------
CREATE TABLE `tim_class_subgroup` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `class_group_id` BIGINT UNSIGNED NOT NULL,                -- FK to sch_class_groups_jnt
  `code` VARCHAR(20) NOT NULL,                              -- e.g., '8th_FRENCH_LAC_OPT', 'SENIOR_GAME_ACT_OPT', 'ALL_GAME_ACT_OPT'
  `name` VARCHAR(100) NOT NULL,                             -- e.g., 'Class 5th TO 12th Game', 'French-Lecture for Class 8th(All Sections)', 'All Students Games Activity'
  `description` VARCHAR(255) DEFAULT NULL,
  `student_count` INT UNSIGNED DEFAULT NULL,                -- Number of students in this subgroup (if applicable)
  `is_shared_across_classes` TINYINT(1) NOT NULL DEFAULT 0, -- Whether this subgroup is shared across multiple classes
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tim_group_code` (`class_group_id`,`code`),
  CONSTRAINT `fk_subgroup_class_group` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- This table links classes and sections to class subgroups.
-- -----------------------------------------------------
-- CLASS SUBGROUP MEMBER
-- -----------------------------------------------------
CREATE TABLE `tt_class_subgroup_member` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `class_subgroup_id` BIGINT UNSIGNED NOT NULL,
  `class_id` BIGINT UNSIGNED NOT NULL,              -- FK to sch_classes
  `section_id` BIGINT UNSIGNED NOT NULL,            -- FK to sch_sections
  `is_primary` TINYINT(1) NULL DEFAULT 0,           -- Optional: marks the main class (useful for reports, attendance)
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_csm_subgroup_class_section` (`class_subgroup_id`, `class_id`, `section_id`),
  CONSTRAINT `fk_csm_subgroup` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tim_class_subgroup`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_csm_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_csm_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- This table logs each timetable generation run with its parameters and status.
-- -----------------------------------------------------
-- TIMETABLE GENERATION RUN
-- -----------------------------------------------------
CREATE TABLE `tim_generation_run` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `mode_id` BIGINT UNSIGNED NOT NULL,                   -- FK to tim_timetable_mode
  `period_set_id` BIGINT UNSIGNED NOT NULL,             -- FK to tim_period_set
  `academic_session_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to sch_academic_sessions
  `started_at` DATETIME NOT NULL,                       -- Timestamp when the generation started
  `finished_at` DATETIME DEFAULT NULL,                  -- Timestamp when the generation finished
  `status` ENUM('RUNNING','SUCCESS','FAILED','CANCELLED') NOT NULL DEFAULT 'RUNNING',
  `params_json` JSON DEFAULT NULL,                      -- JSON field to store generation parameters
  `stats_json` JSON DEFAULT NULL,                       -- JSON field to store generation statistics
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_gr_mode` FOREIGN KEY (`mode_id`) REFERENCES `tim_timetable_mode`(`id`),
  CONSTRAINT `fk_gr_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tim_period_set`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- This table represents individual timetable cells (periods) assigned to class groups / Class subgroup on specific dates for a specific period.
-- Each cell will have one recod for either class_group_id or class_subgroup_id (not both) and will have a Room assigned to it (if applicable).
-- -----------------------------------------------------
-- TIMETABLE CELL
-- -----------------------------------------------------
CREATE TABLE `tt_timetable_cell` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `generation_run_id` BIGINT UNSIGNED NOT NULL,     -- FK to tt_generation_run
  `class_group_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sch_class_groups_jnt (Only 1 of class_group_id / class_subgroup_id must be set (not both))
  `class_subgroup_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to tt_class_subgroup (Only 1 of class_group_id / class_subgroup_id must be set (not both))
  `date` DATE NOT NULL,                             -- Date of the timetable cell
  `period_ord` TINYINT UNSIGNED NOT NULL,           -- Ordinal number of the period in the day
  `room_id` BIGINT UNSIGNED DEFAULT NULL,           -- FK to sch_rooms (if applicable)
  `locked` TINYINT(1) NOT NULL DEFAULT 0,           -- Whether this cell is locked from automatic changes
  `source` ENUM('AUTO','MANUAL','ADJUST') NOT NULL DEFAULT 'AUTO',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tc_generation_run` FOREIGN KEY (`generation_run_id`) REFERENCES `tt_generation_run`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tc_class_group` FOREIGN KEY (`class_group_id`) REFERENCES `sch_subject_study_format_class_subj_types_jnt`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tc_class_subgroup` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroup`(`id`) ON DELETE CASCADE,
  -- Enforce logic that Only 1 value (class_group_id / class_subgroup_id) should be set (not both))
  CONSTRAINT `chk_tc_group_or_subgroup`
    CHECK (
      (class_group_id IS NOT NULL AND class_subgroup_id IS NULL)
      OR
      (class_group_id IS NULL AND class_subgroup_id IS NOT NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- This table links teachers to timetable cells with their specific assignment roles. 
-- We may have more then one teacher per cell (e.g., primary and assistant instructors for a Lab or Activity).
-- -----------------------------------------------------
-- TIMETABLE CELL - TEACHER
-- -----------------------------------------------------
CREATE TABLE `tim_timetable_cell_teacher` (
  `cell_id` BIGINT UNSIGNED NOT NULL,               -- FK to tim_timetable_cell
  `teacher_id` BIGINT UNSIGNED NOT NULL,            -- FK to sch_users
  `assignment_role_id` BIGINT UNSIGNED NOT NULL,    -- FK to tim_teacher_assignment_role
  PRIMARY KEY (`cell_id`,`teacher_id`),
  CONSTRAINT `fk_tct_cell` FOREIGN KEY (`cell_id`) REFERENCES `tim_timetable_cell`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tct_assignment_role` FOREIGN KEY (`assignment_role_id`) REFERENCES `tim_teacher_assignment_role`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- This table logs substitutions made for absent teachers in timetable cells.
-- -----------------------------------------------------
-- SUBSTITUTION LOG
-- -----------------------------------------------------
CREATE TABLE `tim_substitution_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cell_id` BIGINT UNSIGNED NOT NULL,                               -- FK to tim_timetable_cell
  `absent_teacher_id` BIGINT UNSIGNED NOT NULL,                     -- FK to sch_users
  `substitute_teacher_id` BIGINT UNSIGNED NOT NULL,                 -- FK to sch_users
  `substituted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,    -- Timestamp when the substitution occurred
  `reason` VARCHAR(255) DEFAULT NULL,                               -- Reason for substitution
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_sub_cell` FOREIGN KEY (`cell_id`) REFERENCES `tim_timetable_cell`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- This table defines generic constraints that can be applied to teachers, class groups, rooms, or globally.
-- -----------------------------------------------------
-- GENERIC CONSTRAINT ENGINE
-- -----------------------------------------------------
CREATE TABLE `tim_constraint` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `target_type` ENUM('TEACHER','CLASS_GROUP','ROOM','GLOBAL') NOT NULL, -- Type of target the constraint applies to
  `target_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sch_users (if TEACHER), sch_class_groups_jnt (if CLASS_GROUP), sch_rooms (if ROOM), NULL if GLOBAL
  `is_hard` TINYINT(1) NOT NULL DEFAULT 0,              -- Whether this is a hard constraint (must be enforced) or soft constraint (preferable)
  `weight` TINYINT UNSIGNED NOT NULL DEFAULT 100,       -- Weight of the constraint (higher means more important)
  `rule_json` JSON NOT NULL,                            -- JSON field defining the constraint rule (e.g., no classes before 10 AM on Fridays)
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- END OF TIMETABLE MODULE - FINAL CANONICAL SCHEMA
-- -----------------------------------------------------



