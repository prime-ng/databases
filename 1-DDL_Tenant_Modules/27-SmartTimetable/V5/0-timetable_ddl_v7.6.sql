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
	CREATE TABLE IF NOT EXISTS `tt_shift` (
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
	CREATE TABLE IF NOT EXISTS `tt_day_type` (
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
	CREATE TABLE IF NOT EXISTS `tt_period_type` (
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
	CREATE TABLE IF NOT EXISTS `tt_teacher_assignment_role` (
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
    CONSTRAINT `fk_workday_daytype1` FOREIGN KEY (`day_type1_id`) REFERENCES `tt_day_type` (`id`),
    CONSTRAINT `fk_workday_daytype2` FOREIGN KEY (`day_type2_id`) REFERENCES `tt_day_type` (`id`),
    CONSTRAINT `fk_workday_daytype3` FOREIGN KEY (`day_type3_id`) REFERENCES `tt_day_type` (`id`),
    CONSTRAINT `fk_workday_daytype4` FOREIGN KEY (`day_type4_id`) REFERENCES `tt_day_type` (`id`),
    CONSTRAINT `fk_workday_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_set` (`id`)
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
    CONSTRAINT `fk_class_working_day_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_set` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 1.8 Period Set (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_period_set` (
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
    CONSTRAINT `fk_psp_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_set` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_psp_period_type` FOREIGN KEY (`period_type_id`) REFERENCES `tt_period_type` (`id`),
    CONSTRAINT `chk_psp_time` CHECK (`end_time` > `start_time`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 1.10 Timetable Type (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_timetable_type` (
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
    CONSTRAINT `fk_tttype_shift` FOREIGN KEY (`shift_id`) REFERENCES `tt_shift` (`id`),
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
    CONSTRAINT `fk_cttj_timetable` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_type` (`id`),
    CONSTRAINT `fk_cttj_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_cttj_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_cttj_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_set` (`id`),
    CONSTRAINT `chk_cttj_dates` CHECK (`effective_from` < `effective_to` OR (`effective_from` IS NULL AND `effective_to` IS NULL)),
    CONSTRAINT `chk_cttj_apply_to_all` CHECK ((`section_id` IS NULL AND `applies_to_all_sections` = 1) OR (`section_id` IS NOT NULL))
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------
--  SECTION 2: TIMETABLE REQUIREMENT (ENHANCED)
-- -------------------------------------------------

	-- 2.1 Slot Requirement (Enhanced with validation)
	CREATE TABLE IF NOT EXISTS `tt_slot_requirement` (
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
    CONSTRAINT `fk_slot_requirement_academic_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`),
    CONSTRAINT `fk_slot_requirement_timetable_type` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_type` (`id`),
    CONSTRAINT `fk_slot_requirement_class_timetable` FOREIGN KEY (`class_timetable_type_id`) REFERENCES `tt_class_timetable_type_jnt` (`id`),
    CONSTRAINT `fk_slot_requirement_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_slot_requirement_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_slot_requirement_room` FOREIGN KEY (`class_house_room_id`) REFERENCES `sch_rooms` (`id`),
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
	CREATE TABLE IF NOT EXISTS `tt_requirement_consolidation` (
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
    CONSTRAINT `fk_requirement_consolidation_academic_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`),
    CONSTRAINT `fk_requirement_consolidation_timetable_type` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_type` (`id`),
    CONSTRAINT `fk_requirement_consolidation_group` FOREIGN KEY (`class_requirement_group_id`) REFERENCES `tt_class_requirement_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_requirement_consolidation_subgroup` FOREIGN KEY (`class_requirement_subgroup_id`) REFERENCES `tt_class_requirement_subgroups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_requirement_consolidation_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_requirement_consolidation_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_requirement_consolidation_subject_study` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_requirement_consolidation_room_type` FOREIGN KEY (`required_room_type_id`) REFERENCES `sch_rooms_type` (`id`),
    CONSTRAINT `fk_requirement_consolidation_room` FOREIGN KEY (`required_room_id`) REFERENCES `sch_rooms` (`id`),
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
	CREATE TABLE IF NOT EXISTS `tt_constraint_category` (
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
	CREATE TABLE IF NOT EXISTS `tt_constraint_scope` (
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
	CREATE TABLE IF NOT EXISTS `tt_constraint_target_type` (
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
	CREATE TABLE IF NOT EXISTS `tt_constraint_type` (
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
		CONSTRAINT `fk_constraint_type_category` FOREIGN KEY (`category_id`) REFERENCES `tt_constraint_category` (`id`),
		CONSTRAINT `fk_constraint_type_scope` FOREIGN KEY (`scope_id`) REFERENCES `tt_constraint_scope` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Master definition of all constraint types';

	-- 3.5 Constraints (Instance-level constraints)
	CREATE TABLE IF NOT EXISTS `tt_constraint` (
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
		CONSTRAINT `fk_constraint_type` FOREIGN KEY (`constraint_type_id`) REFERENCES `tt_constraint_type` (`id`),
		CONSTRAINT `fk_constraint_target_type` FOREIGN KEY (`target_type_id`) REFERENCES `tt_constraint_target_type` (`id`),
		CONSTRAINT `fk_constraint_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Instance-level constraints for timetable generation';

	-- 3.6 Constraint Group (For grouping related constraints)
	CREATE TABLE IF NOT EXISTS `tt_constraint_group` (
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
	CREATE TABLE IF NOT EXISTS `tt_constraint_group_member` (
		`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
		`constraint_group_id` INT UNSIGNED NOT NULL,
		`constraint_id` INT UNSIGNED NOT NULL,
		`ordinal` TINYINT UNSIGNED DEFAULT NULL,           -- Order within group (for ordered groups)
		`is_active` TINYINT(1) NOT NULL DEFAULT 1,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		PRIMARY KEY (`id`),
		UNIQUE KEY `uq_constraint_group_member` (`constraint_group_id`, `constraint_id`),
		CONSTRAINT `fk_constraint_group_member_group` FOREIGN KEY (`constraint_group_id`) REFERENCES `tt_constraint_group` (`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_constraint_group_member_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraint` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 3.8 Teacher Unavailability (Specialized constraint for performance)
	CREATE TABLE IF NOT EXISTS `tt_teacher_unavailable` (
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
		CONSTRAINT `fk_teacher_unavailable_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`),
		CONSTRAINT `fk_teacher_unavailable_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraint` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 3.9 Room Unavailability (Specialized constraint for performance)
	CREATE TABLE IF NOT EXISTS `tt_room_unavailable` (
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
		CONSTRAINT `fk_room_unavailable_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`),
		CONSTRAINT `fk_room_unavailable_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraint` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- 3.10 Constraint Violation Log (During generation)
	CREATE TABLE IF NOT EXISTS `tt_constraint_violation` (
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
		CONSTRAINT `fk_violation_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_violation_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraint` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Tracks constraint violations during generation';

	-- 3.11 Constraint Template (For reusability)
	CREATE TABLE IF NOT EXISTS `tt_constraint_template` (
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
		CONSTRAINT `fk_constraint_template_type` FOREIGN KEY (`constraint_type_id`) REFERENCES `tt_constraint_type` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Templates for commonly used constraints';


-- -------------------------------------------------
--  SECTION 4: TIMETABLE RESOURCE AVAILABILITY (ENHANCED)
-- -------------------------------------------------

	-- 4.1 Teacher Availability Master
	CREATE TABLE IF NOT EXISTS `tt_teacher_availability` (
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
    CONSTRAINT `fk_teacher_availability_requirement` FOREIGN KEY (`requirement_consolidation_id`)  REFERENCES `tt_requirement_consolidation` (`id`),
    CONSTRAINT `fk_teacher_availability_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_teacher_availability_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_teacher_availability_subject_study` FOREIGN KEY (`subject_study_format_id`)  REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_teacher_availability_teacher_profile` FOREIGN KEY (`teacher_profile_id`)  REFERENCES `sch_teachers_profile` (`id`),
    CONSTRAINT `fk_teacher_availability_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Teacher availability per requirement';

	-- 4.2 Teacher Availability Detail (Period-level)
	CREATE TABLE IF NOT EXISTS `tt_teacher_availability_detail` (
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
    CONSTRAINT `fk_teacher_availability_detail_master` FOREIGN KEY (`teacher_availability_id`)  REFERENCES `tt_teacher_availability` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_teacher_availability_detail_teacher` FOREIGN KEY (`teacher_profile_id`)  REFERENCES `sch_teachers_profile` (`id`),
    CONSTRAINT `fk_teacher_availability_detail_class` FOREIGN KEY (`assigned_class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_teacher_availability_detail_section` FOREIGN KEY (`assigned_section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_teacher_availability_detail_subject` FOREIGN KEY (`assigned_subject_study_format_id`)  REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_teacher_availability_detail_activity` FOREIGN KEY (`assigned_activity_id`) REFERENCES `tt_activity` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Period-level teacher availability';

	-- 4.3 Room Availability Master
	CREATE TABLE IF NOT EXISTS `tt_room_availability` (
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
    CONSTRAINT `fk_room_availability_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`),
    CONSTRAINT `fk_room_availability_room_type` FOREIGN KEY (`room_type_id`) REFERENCES `sch_rooms_type` (`id`),
    CONSTRAINT `fk_room_availability_class` FOREIGN KEY (`house_room_class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_room_availability_section` FOREIGN KEY (`house_room_section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_room_availability_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Room availability overview';

	-- 4.4 Room Availability Detail (Period-level)
	CREATE TABLE IF NOT EXISTS `tt_room_availability_detail` (
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
    CONSTRAINT `fk_room_availability_detail_master` FOREIGN KEY (`room_availability_id`)  REFERENCES `tt_room_availability` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_room_availability_detail_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`),
    CONSTRAINT `fk_room_availability_detail_room_type` FOREIGN KEY (`room_type_id`) REFERENCES `sch_rooms_type` (`id`),
    CONSTRAINT `fk_room_availability_detail_class` FOREIGN KEY (`assigned_class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_room_availability_detail_section` FOREIGN KEY (`assigned_section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_room_availability_detail_subject` FOREIGN KEY (`assigned_subject_study_format_id`)  REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_room_availability_detail_activity` FOREIGN KEY (`assigned_activity_id`) REFERENCES `tt_activity` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Period-level room availability';


-- -------------------------------------------------
--  SECTION 5: TIMETABLE PREPARATION (ENHANCED)
-- -------------------------------------------------

	-- 5.1 Priority Configuration
	CREATE TABLE IF NOT EXISTS `tt_priority_config` (
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
    CONSTRAINT `fk_priority_config_requirement` FOREIGN KEY (`requirement_consolidation_id`) REFERENCES `tt_requirement_consolidation` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Priority configuration for activities';

	-- 5.2 Activity (Enhanced with comprehensive fields)
	CREATE TABLE IF NOT EXISTS `tt_activity` (
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
    CONSTRAINT `fk_activity_academic_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`),
    CONSTRAINT `fk_activity_timetable_type` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_type` (`id`),
    CONSTRAINT `fk_activity_class_group` FOREIGN KEY (`class_requirement_group_id`)  REFERENCES `tt_class_requirement_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_activity_subgroup` FOREIGN KEY (`class_requirement_subgroup_id`)  REFERENCES `tt_class_requirement_subgroups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_activity_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_activity_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_activity_subject_study` FOREIGN KEY (`subject_study_format_id`)  REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_activity_room_type` FOREIGN KEY (`required_room_type_id`) REFERENCES `sch_rooms_type` (`id`),
    CONSTRAINT `fk_activity_room` FOREIGN KEY (`required_room_id`) REFERENCES `sch_rooms` (`id`),
    CONSTRAINT `fk_activity_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `chk_activity_target` CHECK (
        (`class_requirement_group_id` IS NOT NULL AND `class_requirement_subgroup_id` IS NULL) OR
        (`class_requirement_group_id` IS NULL AND `class_requirement_subgroup_id` IS NOT NULL)
    )
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Main activities for timetable scheduling';

	-- 5.3 Sub Activity (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_sub_activity` (
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
    CONSTRAINT `fk_sub_activity_parent` FOREIGN KEY (`parent_activity_id`) REFERENCES `tt_activity` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sub_activity_subgroup` FOREIGN KEY (`class_requirement_subgroup_id`)  REFERENCES `tt_class_requirement_subgroups` (`id`),
    CONSTRAINT `fk_sub_activity_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_sub_activity_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_sub_activity_subject` FOREIGN KEY (`subject_study_format_id`)  REFERENCES `sch_subject_study_format_jnt` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Sub-activities for split activities';

	-- 5.4 Activity Teacher Mapping
	CREATE TABLE IF NOT EXISTS `tt_activity_teacher` (
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
    CONSTRAINT `fk_activity_teacher_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_activity_teacher_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_activity_teacher_role` FOREIGN KEY (`assignment_role_id`) REFERENCES `tt_teacher_assignment_role` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Teacher assignments to activities';


-- -------------------------------------------------
--  SECTION 6: TIMETABLE GENERATION & STORAGE (ENHANCED)
-- -------------------------------------------------

	-- 6.1 Generation Queue
	CREATE TABLE IF NOT EXISTS `tt_generation_queue` (
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
    CONSTRAINT `fk_generation_queue_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`),
    CONSTRAINT `fk_generation_queue_strategy` FOREIGN KEY (`generation_strategy_id`) REFERENCES `tt_generation_strategy` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Queue for asynchronous timetable generation';

	-- 6.2 Timetable (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_timetable` (
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
    CONSTRAINT `fk_timetable_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`),
    CONSTRAINT `fk_timetable_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`),
    CONSTRAINT `fk_timetable_type` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_type` (`id`),
    CONSTRAINT `fk_timetable_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_set` (`id`),
    CONSTRAINT `fk_timetable_strategy` FOREIGN KEY (`generation_strategy_id`) REFERENCES `tt_generation_strategy` (`id`),
    CONSTRAINT `fk_timetable_parent` FOREIGN KEY (`parent_timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_timetable_published_by` FOREIGN KEY (`published_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_timetable_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Main timetable records';

	-- 6.3 Generation Run (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_generation_run` (
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
    CONSTRAINT `fk_generation_run_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_generation_run_queue` FOREIGN KEY (`queue_id`) REFERENCES `tt_generation_queue` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_generation_run_strategy` FOREIGN KEY (`strategy_id`) REFERENCES `tt_generation_strategy` (`id`),
    CONSTRAINT `fk_generation_run_triggered_by` FOREIGN KEY (`triggered_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Timetable generation run details';

	-- 6.4 Timetable Cell (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_timetable_cell` (
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
    CONSTRAINT `fk_timetable_cell_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_timetable_cell_run` FOREIGN KEY (`generation_run_id`) REFERENCES `tt_generation_run` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_timetable_cell_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_timetable_cell_sub_activity` FOREIGN KEY (`sub_activity_id`) REFERENCES `tt_sub_activity` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_timetable_cell_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_timetable_cell_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_timetable_cell_subject` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_timetable_cell_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_timetable_cell_locked_by` FOREIGN KEY (`locked_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Individual timetable cells (period-level assignments)';

	-- 6.5 Timetable Cell Teacher
	CREATE TABLE IF NOT EXISTS `tt_timetable_cell_teacher` (
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
    CONSTRAINT `fk_cell_teacher_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cell` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cell_teacher_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_cell_teacher_role` FOREIGN KEY (`assignment_role_id`) REFERENCES `tt_teacher_assignment_role` (`id`),
    CONSTRAINT `fk_cell_teacher_substitution` FOREIGN KEY (`substitution_log_id`) REFERENCES `tt_substitution_log` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Teacher assignments to timetable cells';

	-- 6.6 Resource Booking
	CREATE TABLE IF NOT EXISTS `tt_resource_booking` (
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
    CONSTRAINT `fk_resource_booking_cell` FOREIGN KEY (`timetable_cell_id`) REFERENCES `tt_timetable_cell` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_resource_booking_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `sch_teachers` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Resource booking and allocation tracking';


-- -------------------------------------------------
-- SECTION 7 : VALIDATION PHASE 
-- -------------------------------------------------

	-- Validation Sessions Table
	CREATE TABLE IF NOT EXISTS `tt_validation_session` (
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
    CONSTRAINT `fk_validation_session_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`),
    CONSTRAINT `fk_validation_session_timetable` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_type` (`id`),
    CONSTRAINT `fk_validation_session_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Tracks validation sessions across timetable lifecycle';

	-- Validation Checks Table
	CREATE TABLE IF NOT EXISTS `tt_validation_check` (
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
    CONSTRAINT `fk_validation_check_session` FOREIGN KEY (`validation_session_id`) REFERENCES `tt_validation_session` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Individual validation checks within a session';

	-- Validation Issue Details
	CREATE TABLE IF NOT EXISTS `tt_validation_issue` (
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
    CONSTRAINT `fk_validation_issue_check` FOREIGN KEY (`validation_check_id`) REFERENCES `tt_validation_check` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_validation_issue_resolved_by` FOREIGN KEY (`resolved_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Individual validation issues with resolution tracking';

	-- Validation Rules Configuration
	CREATE TABLE IF NOT EXISTS `tt_validation_rule` (
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
	CREATE TABLE IF NOT EXISTS `tt_validation_override` (
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
    CONSTRAINT `fk_validation_override_session` FOREIGN KEY (`validation_session_id`) REFERENCES `tt_validation_session` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_validation_override_issue` FOREIGN KEY (`validation_issue_id`) REFERENCES `tt_validation_issue` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_validation_override_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_validation_override_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Tracks manual overrides during validation';


-- -------------------------------------------------
--  SECTION 8: TEACHER WORKLOAD & ANALYTICS
-- -------------------------------------------------

	CREATE TABLE IF NOT EXISTS `tt_teacher_workload` (
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
    CONSTRAINT `fk_teacher_workload_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_teacher_workload_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`),
    CONSTRAINT `fk_teacher_workload_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`),
    CONSTRAINT `fk_teacher_workload_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Teacher workload analysis';

	-- 8.2 Room Utilization
	CREATE TABLE IF NOT EXISTS `tt_room_utilization` (
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
    CONSTRAINT `fk_room_utilization_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`),
    CONSTRAINT `fk_room_utilization_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`),
    CONSTRAINT `fk_room_utilization_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Room utilization analysis';

	-- 8.3 Daily Snapshot
	CREATE TABLE IF NOT EXISTS `tt_analytics_daily_snapshot` (
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
    CONSTRAINT `fk_daily_snapshot_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Daily analytics snapshots';


-- -------------------------------------------------
--  SECTION 9: AUDIT & HISTORY
-- -------------------------------------------------

	CREATE TABLE IF NOT EXISTS `tt_change_log` (
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
    CONSTRAINT `fk_change_log_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_change_log_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cell` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_change_log_changed_by` FOREIGN KEY (`changed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Audit log for all timetable changes';


-- -------------------------------------------------
--  SECTION 10: SUBSTITUTION MANAGEMENT (ENHANCED)
-- -------------------------------------------------

	-- 10.1 Teacher Absence
	CREATE TABLE IF NOT EXISTS `tt_teacher_absence` (
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
    CONSTRAINT `fk_teacher_absence_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_teacher_absence_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_teacher_absence_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Teacher absence records';

	-- 10.2 Substitution Recommendation
	CREATE TABLE IF NOT EXISTS `tt_substitution_recommendation` (
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
    CONSTRAINT `fk_sub_recommendation_absence` FOREIGN KEY (`teacher_absence_id`) REFERENCES `tt_teacher_absence` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sub_recommendation_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cell` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sub_recommendation_teacher` FOREIGN KEY (`recommended_teacher_id`) REFERENCES `sch_teachers` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Substitution recommendations';

	-- 10.3 Substitution Log (Enhanced)
	CREATE TABLE IF NOT EXISTS `tt_substitution_log` (
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
    CONSTRAINT `fk_substitution_log_absence` FOREIGN KEY (`teacher_absence_id`) REFERENCES `tt_teacher_absence` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_substitution_log_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cell` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_substitution_log_recommendation` FOREIGN KEY (`recommendation_id`) REFERENCES `tt_substitution_recommendation` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_substitution_log_absent` FOREIGN KEY (`absent_teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_substitution_log_substitute` FOREIGN KEY (`substitute_teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_substitution_log_original` FOREIGN KEY (`original_teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_substitution_log_assigned_by` FOREIGN KEY (`assigned_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Substitution records';

	-- 10.4 Substitution Pattern Learning
	CREATE TABLE IF NOT EXISTS `tt_substitution_pattern` (
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
    CONSTRAINT `fk_substitution_pattern_subject` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_substitution_pattern_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_substitution_pattern_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_substitution_pattern_original` FOREIGN KEY (`original_teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_substitution_pattern_substitute` FOREIGN KEY (`substitute_teacher_id`) REFERENCES `sch_teachers` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='ML pattern learning for substitutions';






-- -------------------------------------------------
-- OPTIMIZATION PHASE
-- -------------------------------------------------

	-- Optimization Runs
	CREATE TABLE IF NOT EXISTS `tt_optimization_run` (
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
    CONSTRAINT `fk_optimization_run_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_optimization_run_generation` FOREIGN KEY (`generation_run_id`) REFERENCES `tt_generation_run` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Tracks optimization algorithm runs';

	-- Optimization Iteration Details
	CREATE TABLE IF NOT EXISTS `tt_optimization_iteration` (
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
    CONSTRAINT `fk_optimization_iteration_run` FOREIGN KEY (`optimization_run_id`) REFERENCES `tt_optimization_run` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Detailed iteration data for optimization runs';

	-- Optimization Move Log
	CREATE TABLE IF NOT EXISTS `tt_optimization_move` (
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
    CONSTRAINT `fk_optimization_move_run` FOREIGN KEY (`optimization_run_id`) REFERENCES `tt_optimization_run` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_optimization_move_source` FOREIGN KEY (`source_activity_id`) REFERENCES `tt_activity` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_optimization_move_target` FOREIGN KEY (`target_activity_id`) REFERENCES `tt_activity` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Individual moves during optimization';


-- -------------------------------------------------
-- CONFLICT RESOLUTION WORKFLOW
-- -------------------------------------------------

	-- Conflict Resolution Sessions
	CREATE TABLE IF NOT EXISTS `tt_conflict_resolution_session` (
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
    CONSTRAINT `fk_conflict_resolution_session_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_conflict_resolution_session_generation` FOREIGN KEY (`generation_run_id`) REFERENCES `tt_generation_run` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_conflict_resolution_session_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Tracks conflict resolution workflow sessions';

	-- Conflict Resolution Options
	CREATE TABLE IF NOT EXISTS `tt_conflict_resolution_option` (
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
    CONSTRAINT `fk_conflict_resolution_option_conflict` FOREIGN KEY (`conflict_id`) REFERENCES `tt_conflict_detection` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_conflict_resolution_option_session` FOREIGN KEY (`resolution_session_id`) REFERENCES `tt_conflict_resolution_session` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_conflict_resolution_option_selected_by` FOREIGN KEY (`selected_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Resolution options for each conflict';

	-- Escalation Rules
	CREATE TABLE IF NOT EXISTS `tt_escalation_rule` (
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
	CREATE TABLE IF NOT EXISTS `tt_escalation_log` (
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
    CONSTRAINT `fk_escalation_log_conflict` FOREIGN KEY (`conflict_id`) REFERENCES `tt_conflict_detection` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_escalation_log_session` FOREIGN KEY (`resolution_session_id`) REFERENCES `tt_conflict_resolution_session` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_escalation_log_rule` FOREIGN KEY (`escalation_rule_id`) REFERENCES `tt_escalation_rule` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_escalation_log_user` FOREIGN KEY (`escalated_to`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Log of conflict escalations';


-- -------------------------------------------------
-- APPROVAL WORKFLOW
-- -------------------------------------------------

	-- Approval Workflow Definitions
	CREATE TABLE IF NOT EXISTS `tt_approval_workflow` (
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
	CREATE TABLE IF NOT EXISTS `tt_approval_level` (
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
    CONSTRAINT `fk_approval_level_workflow` FOREIGN KEY (`workflow_id`) REFERENCES `tt_approval_workflow` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Levels within an approval workflow';

	-- Approval Requests
	CREATE TABLE IF NOT EXISTS `tt_approval_request` (
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
    CONSTRAINT `fk_approval_request_workflow` FOREIGN KEY (`workflow_id`) REFERENCES `tt_approval_workflow` (`id`),
    CONSTRAINT `fk_approval_request_submitted_by` FOREIGN KEY (`submitted_by`) REFERENCES `sys_users` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Approval requests for various actions';

	-- Approval Decisions
	CREATE TABLE IF NOT EXISTS `tt_approval_decision` (
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
    CONSTRAINT `fk_approval_decision_request` FOREIGN KEY (`approval_request_id`) REFERENCES `tt_approval_request` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_approval_decision_approver` FOREIGN KEY (`approver_id`) REFERENCES `sys_users` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Decisions made at each approval level';

	-- Approval Notifications
	CREATE TABLE IF NOT EXISTS `tt_approval_notification` (
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
    CONSTRAINT `fk_approval_notification_request` FOREIGN KEY (`approval_request_id`) REFERENCES `tt_approval_request` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_approval_notification_recipient` FOREIGN KEY (`recipient_id`) REFERENCES `sys_users` (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Notifications related to approval workflow';


-- -------------------------------------------------
-- ML PATTERN LEARNING
-- -------------------------------------------------

	-- ML Model Registry
	CREATE TABLE IF NOT EXISTS `tt_ml_model` (
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
    CONSTRAINT `fk_training_data_model` FOREIGN KEY (`model_id`) REFERENCES `tt_ml_model` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Training data sets used for ML models';

	-- Feature Importance
	CREATE TABLE IF NOT EXISTS `tt_feature_importance` (
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
    CONSTRAINT `fk_feature_importance_model` FOREIGN KEY (`model_id`) REFERENCES `tt_ml_model` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Feature importance from ML models';

	-- Prediction Log
	CREATE TABLE IF NOT EXISTS `tt_prediction_log` (
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
    CONSTRAINT `fk_prediction_log_model` FOREIGN KEY (`model_id`) REFERENCES `tt_ml_model` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Log of predictions made by ML models';

	-- Pattern Recognition Results
	CREATE TABLE IF NOT EXISTS `tt_pattern_result` (
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
    CONSTRAINT `fk_pattern_result_model` FOREIGN KEY (`model_id`) REFERENCES `tt_ml_model` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Discovered patterns from ML analysis';


-- -------------------------------------------------
-- IMPACT ANALYSIS
-- -------------------------------------------------

	-- Impact Analysis Sessions
	CREATE TABLE IF NOT EXISTS `tt_impact_analysis_session` (
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
    CONSTRAINT `fk_impact_analysis_session_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_impact_analysis_session_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Sessions for impact analysis of changes';

	-- Impact Analysis Details
	CREATE TABLE IF NOT EXISTS `tt_impact_analysis_detail` (
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
    CONSTRAINT `fk_impact_analysis_detail_session` FOREIGN KEY (`analysis_session_id`) REFERENCES `tt_impact_analysis_session` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Detailed impact analysis results';

	-- What-If Scenarios
	CREATE TABLE IF NOT EXISTS `tt_what_if_scenario` (
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
    CONSTRAINT `fk_what_if_scenario_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_what_if_scenario_analysis` FOREIGN KEY (`analysis_session_id`) REFERENCES `tt_impact_analysis_session` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_what_if_scenario_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='What-if scenarios for testing changes';


-- -------------------------------------------------
-- BATCH OPERATIONS
-- -------------------------------------------------

	-- Batch Operation Sessions
	CREATE TABLE IF NOT EXISTS `tt_batch_operation` (
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
    CONSTRAINT `fk_batch_operation_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_batch_operation_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Batch operations on timetable';

	-- Batch Operation Items
	CREATE TABLE IF NOT EXISTS `tt_batch_operation_item` (
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
    CONSTRAINT `fk_batch_operation_item_batch` FOREIGN KEY (`batch_operation_id`) REFERENCES `tt_batch_operation` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_batch_operation_item_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cell` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Individual items in a batch operation';


-- -------------------------------------------------
-- RE-VALIDATION TRIGGER
-- -------------------------------------------------

	-- Re-validation Triggers
	CREATE TABLE IF NOT EXISTS `tt_revalidation_trigger` (
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
    CONSTRAINT `fk_revalidation_trigger_validation` FOREIGN KEY (`validation_session_id`) REFERENCES `tt_validation_session` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Triggers for automatic re-validation';

	-- Re-validation Schedule
	CREATE TABLE IF NOT EXISTS `tt_revalidation_schedule` (
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
    CONSTRAINT `fk_revalidation_schedule_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Scheduled re-validation jobs';


-- -------------------------------------------------
-- VERSION COMPARISON
-- -------------------------------------------------

	-- Version Comparison Sessions
	CREATE TABLE IF NOT EXISTS `tt_version_comparison` (
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
    CONSTRAINT `fk_version_comparison_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_version_comparison_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Version comparison sessions';

	-- Version Comparison Details
	CREATE TABLE IF NOT EXISTS `tt_version_comparison_detail` (
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
    CONSTRAINT `fk_version_comparison_detail_comparison` FOREIGN KEY (`comparison_id`) REFERENCES `tt_version_comparison` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	COMMENT='Detailed changes between versions';






-- SEED DATA FOR CONSTRAINT TABLES
-- -------------------------------

-- Seed tt_constraint_category
INSERT INTO `tt_constraint_category` (`code`, `name`, `ordinal`) VALUES
('TEACHER', 'Teacher Constraints', 1),
('CLASS', 'Class Constraints', 2),
('ACTIVITY', 'Activity Constraints', 3),
('ROOM', 'Room Constraints', 4),
('STUDENT', 'Student Group Constraints', 5),
('GLOBAL', 'Global Constraints', 6);

-- Seed tt_constraint_scope
INSERT INTO `tt_constraint_scope` (`code`, `name`, `target_type_required`, `target_id_required`) VALUES
('GLOBAL', 'Global', 0, 0),
('INDIVIDUAL', 'Individual', 1, 1),
('GROUP', 'Group', 1, 0),
('PAIR', 'Pair', 1, 0);

-- Seed tt_constraint_target_type
INSERT INTO `tt_constraint_target_type` (`code`, `name`, `table_name`) VALUES
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

-- Seed tt_constraint_type (sample - full list from A2)
INSERT INTO `tt_constraint_type` 
(`code`, `name`, `category_id`, `scope_id`, `constraint_level`, `default_weight`, 
 `parameter_schema`, `applicable_target_types`) VALUES
('TEACHER_MAX_DAILY', 'Teacher Maximum Daily Periods', 
 (SELECT id FROM tt_constraint_category WHERE code='TEACHER'),
 (SELECT id FROM tt_constraint_scope WHERE code='INDIVIDUAL'),
 'HARD', 100,
 '{"max_periods_per_day":{"type":"integer","minimum":1,"maximum":12,"default":8}}',
 '[{"target_type":"TEACHER"}]'),

('TEACHER_MAX_WEEKLY', 'Teacher Maximum Weekly Periods',
 (SELECT id FROM tt_constraint_category WHERE code='TEACHER'),
 (SELECT id FROM tt_constraint_scope WHERE code='INDIVIDUAL'),
 'HARD', 100,
 '{"max_periods_per_week":{"type":"integer","minimum":1,"maximum":60,"default":48}}',
 '[{"target_type":"TEACHER"}]'),

('CLASS_MAX_PER_DAY', 'Class Maximum Periods Per Day',
 (SELECT id FROM tt_constraint_category WHERE code='CLASS'),
 (SELECT id FROM tt_constraint_scope WHERE code='INDIVIDUAL'),
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