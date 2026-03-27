-- =====================================================================
-- TIMETABLE MODULE - VERSION 7.0 (PRODUCTION-GRADE)
-- Enhanced from tt_timetable_ddl_v6.0.sql
-- =====================================================================
-- Target: MySQL 8.x | Stack: PHP + Laravel
-- Architecture: Multi-tenant, Constraint-based Auto-Scheduling
-- TABLE PREFIX: tt_ - Timetable Module
-- =====================================================================
-- ENHANCEMENTS IN V6.0:
-- Added Reference Tables from Other Modules
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
--  NEWLY ADDED : TABLES
-- -------------------------------------------------



-- -------------------------------------------------
--  SECTION 0: CONFIGURATION TABLES
-- -------------------------------------------------

  -- This table is created in the School_Setup module but will will be shown & can be Modified in Timetable as well.
  -- This will be used in Lesson Planning for creating Schedule for all the Subjects for Entire Session
  CREATE TABLE IF NOT EXISTS `sch_academic_term` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `academic_session_id` INT UNSIGNED NOT NULL,
    `academic_year_start_date` DATE NOT NULL, -- Academic Year Start Date
    `academic_year_end_date` DATE NOT NULL, -- Academic Year End Date
    `total_terms_in_academic_session` TINYINT UNSIGNED NOT NULL, -- Total Terms in an Academic Session -- e.g., 1, 2, 3, 4
    `term_ordinal` TINYINT UNSIGNED NOT NULL, -- Term Ordinal. -- e.g., 1, 2, 3, 4
    `term_code` VARCHAR(20) NOT NULL,  -- Term Code. (e.g., 'SUMMER', 'WINTER', 'Q1', 'Q2', 'Q3', 'Q4')
    `term_name` VARCHAR(100) NOT NULL, -- Term Name. (e.g., 'Summer Term', 'Winter Term', 'QUATER - 1', 'QUATER - 2', 'QUATER - 3', 'QUATER - 4')
    `term_start_date` DATE NOT NULL, -- Term Start Date  (e.g., '2024-01-01', '2024-02-01', '2024-03-01', '2024-04-01', '2024-05-01', '2024-06-01')
    `term_end_date` DATE NOT NULL, -- Term End Date  (e.g., '2024-01-31', '2024-02-29', '2024-03-31', '2024-04-30', '2024-05-31', '2024-06-30')
    `term_total_teaching_days` TINYINT UNSIGNED DEFAULT 5, -- Total Teaching Days in a Term (Excluding Exam Days) (e.g., 1, 2, 3, 4, 5, 6)
    `term_total_exam_days` TINYINT UNSIGNED DEFAULT 2, -- Total Exam Days in a Term for All Exam in a Term (Excluding Teaching Days) (e.g., 1, 2, 3, 4, 5, 6)
    `term_week_start_day` TINYINT UNSIGNED NOT NULL, -- Start Day of the Week (e.g., 1, 2, 3, 4, 5, 6)
    `term_total_periods_per_day` TINYINT UNSIGNED NOT NULL, -- Total Periods per Day (e.g., 8, 10, 11) (This includes everything (Teaching Period+Lunch+Recess+Short Breaks))
    `term_total_teaching_periods_per_day` TINYINT UNSIGNED NOT NULL, -- Total Teaching Periods per Day
    `term_min_resting_periods_per_day` TINYINT UNSIGNED NOT NULL, -- Minimum Resting Periods per Day between classes (e.g. 0,1,2)
    `term_max_resting_periods_per_day` TINYINT UNSIGNED NOT NULL, -- Maximum Resting Periods per Day between classes (e.g. 0,1,2)
    `term_travel_minutes_between_classes` TINYINT UNSIGNED NOT NULL, -- Travel time (Min.) required between classes (e.g. 5,10,15)
    `is_current` BOOLEAN DEFAULT FALSE, -- Is Current Term
    `current_flag` tinyint(1) GENERATED ALWAYS AS ((case when (`is_current` = 1) then '1' else NULL end)) STORED, -- Current Flag (Generated)
    `settings_json` JSON, -- Settings JSON
    `is_active` BOOLEAN DEFAULT TRUE, -- Is Active
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Created At
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Updated At
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_AcademicTerm_currentFlag` (`current_flag`),
    UNIQUE KEY `uq_AcademicTerm_session_code` (`academic_session_id`, `term_code`),
    INDEX `idx_AcademicTerm_dates` (`start_date`, `end_date`),
    INDEX `idx_AcademicTerm_current` (`is_current`),
    FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Academic term/quarter/semester structure';


  -- Here we are setting what all Settings will be used for the Timetable Module
  -- Only Edit Functionality is require. No one can Add or Delete any record.
  -- In Edit also "key" can not be edit. In Edit "key" will not be display.
  CREATE TABLE IF NOT EXISTS `tt_config` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` int unsigned NOT NULL DEFAULT '1',
    `key` varchar(150) NOT NULL,  -- Can not changed by user (He can edit other fields only but not KEY)
    `key_name` varchar(150) NOT NULL,  -- Can be Changed by user
    `value` varchar(512) NOT NULL,
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
  -- (2,'school_open_days_per_week', 'School Open Days per Week', '6', 'NUMBER', 'School Open Days per Week', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
  -- (3,'school_closed_days_per_week', 'School Closed Days per Week', '1', 'NUMBER', 'School Closed Days per Week', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
  -- (4,'number_of_short_breaks_daily_before_lunch', 'Number of Short Breaks Daily Before Lunch', '1', 'NUMBER', 'Number of Short Breaks Daily Before Lunch', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
  -- (5,'number_of_short_breaks_daily_after_lunch', 'Number of Short Breaks Daily After Lunch', '1', 'NUMBER', 'Number of Short Breaks Daily After Lunch', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
  -- (6,'total_number_of_short_breaks_daily', 'Total Number of Short Breaks Daily', '2', 'NUMBER', 'Total Number of Short Breaks Daily', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
  -- (7,'total_number_of_period_before_lunch', 'Total Number of Periods Before Lunch', '4', 'NUMBER', 'Total Number of Periods Before Lunch', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
  -- (8,'total_number_of_period_after_lunch', 'Total Number of Periods After Lunch', '4', 'NUMBER', 'Total Number of Periods After Lunch', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
  -- (9,'minimum_student_required_for_class_subgroup', 'Minimum Number of Student Required for Class Subgroup', '10', 'NUMBER', 'Minimum Number of Student Required for Class Subgroup', NULL, 0, 1, 1, 1, NULL, NULL, NULL),
  -- (10,'maximum_student_required_for_class_subgroup', 'Maximum Number of Student Required for Class Subgroup', '25', 'NUMBER', 'Maximum Number of Student Required for Class Subgroup', NULL, 0, 1, 1, 1, NULL, NULL, NULL);
  -- 

-- Timetable Generation Queue & Strategy Tables (For handling asynchronous timetable generation)
CREATE TABLE IF NOT EXISTS `tt_generation_strategy` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(20) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255) NULL,
    `algorithm_type` ENUM('RECURSIVE','GENETIC','SIMULATED_ANNEALING','TABU_SEARCH','HYBRID') DEFAULT 'RECURSIVE',
    `max_recursive_depth` INT UNSIGNED DEFAULT 14,  -- This will be used for the recursive algorithm
    `max_placement_attempts` INT UNSIGNED DEFAULT 2000,  -- This will be used for the recursive algorithm
    `tabu_size` INT UNSIGNED DEFAULT 100,  -- This will be used for the tabu search algorithm
    `cooling_rate` DECIMAL(5,2) DEFAULT 0.95,  -- This will be used for the simulated annealing algorithm
    `population_size` INT UNSIGNED DEFAULT 50,  -- This will be used for the genetic algorithm
    `generations` INT UNSIGNED DEFAULT 100,  -- This will be used for the genetic algorithm
    `activity_sorting_method` ENUM('LESS_TEACHER_FIRST','DIFFICULTY_FIRST','CONSTRAINT_COUNT','DURATION_FIRST','RANDOM') DEFAULT 'LESS_TEACHER_FIRST',
    `timeout_seconds` INT UNSIGNED DEFAULT 300,  -- This will be used for the recursive algorithm
    `parameters_json` JSON NULL,  -- This will be used for all the algorithm
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
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(20) NOT NULL,  -- e.g., 'MORNING', 'AFTERNOON', 'EVENING'
    `name` VARCHAR(100) NOT NULL,  -- e.g., 'Morning', 'Afternoon', 'Evening'
    `description` VARCHAR(255) DEFAULT NULL,
    `default_start_time` TIME DEFAULT NULL,  -- e.g., '08:00:00'
    `default_end_time` TIME DEFAULT NULL,  -- e.g., '12:00:00'
    `ordinal` SMALLINT UNSIGNED DEFAULT 1,
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
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(20) NOT NULL,  -- e.g., 'STUDY','HOLIDAY','EXAM','SPECIAL','PTM_DAY','SPORTS_DAY','ANNUAL_DAY'
    `name` VARCHAR(100) NOT NULL,  -- e.g., 'Study Day','Holiday','Exam','Special Day','Parent Teacher Meeting','Sports Day','Annual Day'
    `description` VARCHAR(255) DEFAULT NULL,
    `is_working_day` TINYINT(1) NOT NULL DEFAULT 1,  -- 1 for working day, 0 for non-working day
    `reduced_periods` TINYINT(1) NOT NULL DEFAULT 0,  -- (Does school have less periods on this day? e.g. On Sports day may only 4 Periods)
    `ordinal` SMALLINT UNSIGNED DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    -- Add Or Change on 7th Feb 2025 --
    UNIQUE KEY `uq_daytype_ordinal` (`ordinal`), 
    UNIQUE KEY `uq_daytype_code` (`code`),
    UNIQUE KEY `uq_daytype_name` (`name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Here we are setting what all Types of Periods will be used for the School 'THEORY','TEACHING','PRACTICAL','BREAK','LUNCH','ASSEMBLY','EXAM','RECESS','FREE'
  CREATE TABLE IF NOT EXISTS `tt_period_type` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL,  -- e.g., 'THEORY','TEACHING','PRACTICAL','BREAK','LUNCH','ASSEMBLY','EXAM','RECESS','FREE'
    `name` VARCHAR(100) NOT NULL,  -- e.g., 'Theory','Teaching','Practical','Break','Lunch','Assembly','Exam','Recess','Free Period'
    `description` VARCHAR(255) DEFAULT NULL,
    `color_code` VARCHAR(10) DEFAULT NULL,  -- e.g., '#FF0000', '#00FF00', '#0000FF'
    `icon` VARCHAR(50) DEFAULT NULL,  -- e.g., 'fa-solid fa-chalkboard-teacher', 'fa-solid fa-clock', 'fa-solid fa-luch'
    `is_schedulable` TINYINT(1) NOT NULL DEFAULT 1,  -- 1 for schedulable, 0 for non-schedulable
    `counts_as_teaching` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for counts as teaching, 0 for non-teaching
    `counts_as_workload` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for counts as workload, 0 for non-workload
    `is_break` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for break, 0 for non-break
    -- Add Or Change on 7th Feb 2025 -- (1 New Column below 'Free Period')
    `is_free_period` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for free period, 0 for non-free period. (New)
    `ordinal` SMALLINT UNSIGNED DEFAULT 1,
    `is_system` TINYINT(1) DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    -- Add Or Change on 7th Feb 2025 -- (Add New Unique Key below)
    UNIQUE KEY `uq_periodtype_ordinal` (`ordinal`),
    UNIQUE KEY `uq_periodtype_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Here we are setting what all Types of Teacher Assignment Roles will be used for the School 'PRIMARY','ASSISTANT','CO_TEACHER','SUBSTITUTE','TRAINEE'
  CREATE TABLE IF NOT EXISTS `tt_teacher_assignment_role` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL,  -- e.g., 'PRIMARY','ASSISTANT','CO_TEACHER','SUBSTITUTE','TRAINEE'
    `name` VARCHAR(100) NOT NULL,  -- e.g., 'Primary Teacher','Assistant Teacher','Co-Teacher','Substitute Teacher','Trainee Teacher'
    `description` VARCHAR(255) DEFAULT NULL,
    `is_primary_instructor` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for primary instructor, 0 for non-primary instructor
    `counts_for_workload` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for counts for workload, 0 for non-counts for workload
    `allows_overlap` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for allows overlap, 0 for non-allows overlap
    -- Add Or Change on 7th Feb 2025 -- (Changed below 1 Coloumn from DECIMAL(3,2) to DECIMAL(5,2) to allow for 100.00)
    `workload_factor` DECIMAL(5,2) DEFAULT 1.00,  -- e.g., 0.25, 0.50, 0.75, 1.00, 2.00, 3.00 
    `ordinal` SMALLINT UNSIGNED DEFAULT 1,  -- e.g., 1, 2, 3
    `is_system` TINYINT(1) DEFAULT 1,  -- 1 for system, 0 for non-system.
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- 1 for active, 0 for non-active
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tarole_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Here we are setting which all Days will be Open for School and Which day School will remain Closed
  CREATE TABLE IF NOT EXISTS `tt_school_days` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(10) NOT NULL,  -- e.g., 'MON','TUE','WED','THU','FRI','SAT','SUN'
    `name` VARCHAR(20) NOT NULL,  -- e.g., 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
    `short_name` VARCHAR(5) NOT NULL,  -- e.g., 'Mon','Tue','Wed','Thu','Fri','Sat','Sun'
    `day_of_week` TINYINT UNSIGNED NOT NULL,  -- e.g., 1,2,3,4,5,6,7
    `ordinal` SMALLINT UNSIGNED NOT NULL,  -- e.g., 1,2,3,4,5,6,7
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
    -- Add Or Change on 7th Feb 2025 -- (1 New Column below)
    `academic_session_id` INT UNSIGNED NOT NULL,  -- FK to tt_academic_session.id
    `date` DATE NOT NULL,  -- e.g., '2023-01-01'
    -- Add Or Change on 7th Feb 2025 -- 
    -- Change name of below 1st Col from "day_type_id" to "day_type1_id" & add 3 New Column below)
    `day_type1_id` INT UNSIGNED NOT NULL,  -- FK to tt_day_type.id (There can multipal Activity on same day e.g. Exam with Study, PTM with Study etc.)
    `day_type2_id` INT UNSIGNED NOT NULL,  -- FK to tt_day_type.id (There can multipal Activity on same day e.g. Exam with Study, PTM with Study etc.)
    `day_type3_id` INT UNSIGNED NOT NULL,  -- FK to tt_day_type.id (There can multipal Activity on same day e.g. Exam with Study, PTM with Study etc.)
    `day_type4_id` INT UNSIGNED NOT NULL,  -- FK to tt_day_type.id (There can multipal Activity on same day e.g. Exam with Study, PTM with Study etc.)
    -- Above 4 Coloumns are updated / New
    `is_school_day` TINYINT(1) NOT NULL DEFAULT 1,  -- 1 if school is Open, 0 if school is Closed
    `remarks` VARCHAR(255) DEFAULT NULL,  -- Remarks for the day
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

  -- We need to have another junction table to connect Class_section with working_day. 
  -- There is possibility that one class is having EXAM on a day but another class is not having exam but it a Normal Study Class.
  -- Add Or Change on 7th Feb 2025 -- (Added New table)
  CREATE TABLE IF NOT EXISTS `tt_class_working_day_jnt` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_session_id` INT UNSIGNED NOT NULL,  -- FK to tt_academic_session.id
    `date` DATE NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,  -- FK to tt_class_section.id
    `working_day_id` INT UNSIGNED NOT NULL,  -- FK to tt_working_day.id
    `is_exam_day` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for exam day, 0 for non-exam day
    `is_ptm_day` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for PTM day, 0 for non-PTM day
    `is_half_day` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for half day, 0 for non-half day
    `is_holiday` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for holiday, 0 for non-holiday
    `is_study_day` TINYINT(1) NOT NULL DEFAULT 1,  -- 1 for study day, 0 for no-study on that day
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
    `code` VARCHAR(30) NOT NULL,  -- e.g., '3rd-12th_NORMAL_8P','4th-12th_EXAM_3P','5th-12th_HALF_DAY_4P','BV1-2nd_TODDLER_6P'
    `name` VARCHAR(100) NOT NULL,  -- e.g., '3rd-12th Normal 8P','4th-12th Exam 3P','5th-12th Half Day 4P','BV1-2nd Toddler 6P'
    `description` VARCHAR(255) DEFAULT NULL,
    `total_periods` TINYINT UNSIGNED NOT NULL,  -- e.g., 6, 8, 8, 8
    `teaching_periods` TINYINT UNSIGNED NOT NULL,  -- e.g., 6, 8, 6, 8
    `day_start_time` TIME NOT NULL,  -- e.g., '08:00:00', '08:00:00', '08:00:00', '08:00:00'. Changed from start_time
    `day_end_time` TIME NOT NULL,  -- e.g., '13:00:00', '15:00:00', '15:00:00', '15:00:00'. Changed from end_time
    -- Add Or Change on 7th Feb 2025 -- (Removed below Coloumn as We will use tt_class_period_set_jnt table to map the class with the period set.)
    --`applicable_class_ids` JSON DEFAULT NULL,  -- (Removed as it is not required.)
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
    `period_set_id` INT UNSIGNED NOT NULL,   -- FK to tt_period_set.id (e.g. '3rd-12th_NORMAL_8P','4th-12th_EXAM_3P','5th-12th_HALF_DAY_4P','BV1-2nd_TODDLER_6P')
    `period_type_id` INT UNSIGNED NOT NULL,  -- FK to tt_period_type.id (e.g. 'TEACHING','BREAK','LUNCH','ASSEMBLY','ACTIVITY','EXAM','HALF DAY')
    `code` VARCHAR(20) NOT NULL,                -- e.g., 'REC','P-1','P-2','BRK','P-3','P-4','LUN','P-5','P-6','BRK','P-7','P-8'
    `short_name` VARCHAR(50) NOT NULL,          -- e.g., 'Recess','Period-1','Period-2','Break','Period-3','Period-4','Lunch','Period-5','Period-6','Break','Period-7','Period-8'
    `period_ord` TINYINT UNSIGNED NOT NULL,     -- e.g., 1,2,3,4,5,6,7,8
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
    `code` VARCHAR(30) NOT NULL,   -- e.g., 'STANDARD_3rd-12th', 'STANDARD_BV1-2nd','EXTENDED_9th-12th', 'HALF_DAY_5th-12th', 'EXAM_3rd-8th', 'EXAM_9th-12th'
    `name` VARCHAR(100) NOT NULL,  -- e.g., 'Standard Timetable FOR 3RD-12TH','Standard Timetable FOR BV1-2ND','Extended Timetable FOR 9TH-12TH','Half Day Timetable','Exam Timetable','Exam Timetable','Exam Timetable'
    `description` VARCHAR(255) DEFAULT NULL,
    `shift_id` INT UNSIGNED DEFAULT NULL,   -- FK to tt_shift.id (e.g., 'MORNING','TODLER','AFTERNOON','EVENING')
    `default_period_set_id` INT UNSIGNED DEFAULT NULL,   -- FK to tt_period_set.id (e.g., 'STANDARD_3rd-12th','EXTENDED_9th-12th','HALF_DAY_5th-12th','EXAM_3rd-8th','EXAM_9th-12th')
    `day_type_id` INT UNSIGNED DEFAULT NULL,   -- FK to tt_day_type.id (e.g., 'WORKDAY','EXAM_DAYS','SPORTS_DAY')
    `effective_from_date` DATE DEFAULT NULL,  -- Start date for this timetable type. e.g., '2023-01-01'
    `effective_to_date` DATE DEFAULT NULL,    -- End date for this timetable type. e.g., '2023-12-31'
    `school_start_time` TIME DEFAULT NULL,    -- School start time. e.g., '08:00:00'
    `school_end_time` TIME DEFAULT NULL,      -- School end time. e.g., '17:00:00'
    `assembly_duration_min` SMALLINT UNSIGNED DEFAULT NULL,  -- Assembly duration in minutes. e.g., '30'
    `short_break_duration_min` SMALLINT UNSIGNED DEFAULT NULL,  -- Default break duration in minutes. e.g., '15'
    `lunch_duration_min` SMALLINT UNSIGNED DEFAULT NULL,  -- Lunch duration. e.g., '60'
    `has_exam` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether this timetable type has exams. e.g., '1'
    `has_teaching` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this timetable type has teaching. e.g., '1'
    `ordinal` SMALLINT UNSIGNED DEFAULT 1,  -- Order of this timetable type. e.g., '1'
    `is_default` TINYINT(1) DEFAULT 0,  -- Whether this timetable type is the default. e.g., '0'
    `is_system` TINYINT(1) DEFAULT 1,  -- Whether this timetable type is a system-defined type. e.g., '1'
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

  -- This table is used to define the rules for a particular class
  CREATE TABLE IF NOT EXISTS `tt_class_mode_rule` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `class_id` INT UNSIGNED NOT NULL,  -- FK to tt_class.id 
    `timetable_type_id` INT UNSIGNED NOT NULL,   -- FK to tt_timetable_type.id 
    `period_set_id` INT UNSIGNED NOT NULL,   -- FK to tt_period_set.id 
    `academic_session_id` INT UNSIGNED DEFAULT NULL,   -- FK to tt_academic_session.id 
    `allow_teaching` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this class is allowed to have teaching
    `allow_exam` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether this class is allowed to have exam
    `exam_period_count` TINYINT UNSIGNED DEFAULT NULL,  -- Number of exam periods
    `teaching_after_exam` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether teaching is allowed after exam
    `effective_from` DATE DEFAULT NULL,  -- Start date for this class mode rule
    `effective_to` DATE DEFAULT NULL,  -- End date for this class mode rule
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


  -- Let's Create Period_Set & Classes Junction table (Added New Table)
  -- Add Or Change on 7th Feb 2025 -- (Added New table)
  CREATE TABLE IF NOT EXISTS `tt_period_set_class_jnt` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `period_set_id` INT UNSIGNED NOT NULL,   -- FK to tt_period_set.id (e.g., 'STANDARD_3rd-12th','EXTENDED_9th-12th','HALF_DAY_5th-12th','EXAM_3rd-8th','EXAM_9th-12th')
    `class_id` INT UNSIGNED NOT NULL,   -- FK to tt_classes.id (e.g., 'STANDARD_3rd-12th','EXTENDED_9th-12th','HALF_DAY_5th-12th','EXAM_3rd-8th','EXAM_9th-12th')
    `section_id` INT UNSIGNED NULL,  -- FK to tt_sections.id (Section can be Null if it is applicable to all Sections of a Class)
    `start_date` DATE NOT NULL,  -- e.g., '2026-01-01'
    `end_date` DATE NOT NULL,  -- e.g., '2026-03-31'
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_psp_class_jnt_set_class` (`period_set_id`, `class_id`),
    KEY `idx_psp_class_jnt_period_set` (`period_set_id`),
    KEY `idx_psp_class_jnt_class` (`class_id`),
    CONSTRAINT `fk_psp_class_jnt_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_set` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_psp_class_jnt_class` FOREIGN KEY (`class_id`) REFERENCES `tt_classes` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_psp_class_jnt_section` FOREIGN KEY (`section_id`) REFERENCES `tt_sections` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



  -- This table will be used to define different Class Groups like 10th-A Science Lecture Major, 7th-B Commerce Optional etc.
  -- old name 'sch_subject_study_format_class_subj_types_jnt' changed to 'sch_class_groups_jnt'
  CREATE TABLE IF NOT EXISTS `tt_class_groups_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `subject_group_subject_id` INT unsigned NOT NULL,  -- FK to sch_subject_group_subjects.id
    `class_id` INT unsigned NOT NULL,
    `section_id` INT unsigned DEFAULT NULL,
    `subject_study_format_id` INT unsigned NOT NULL,  -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    `subject_type_id` INT unsigned NOT NULL,  -- FK to sch_subject_types.id. e.g MAJOR, MINOR, OPTIONAL, etc.
    `rooms_type_id` INT unsigned NOT NULL,  -- FK to sch_rooms_type.id. e.g LAB, CLASSROOM, AUDITORIUM, etc.
    `name` varchar(50) NOT NULL,
    `code` char(30) NOT NULL,
    `student_count` INT UNSIGNED DEFAULT NULL,  -- Number of students in this subgroup
    `eligible_teacher_count` INT UNSIGNED DEFAULT NULL,  -- Number of teachers for this group
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_classGroup_code` (`code`),
    UNIQUE KEY `uq_classGroup_subStdFmt_class_section_subjectType` (`sub_stdy_frmt_id`,`class_id`,`section_id`,`subject_type_id`),
    KEY `sch_class_groups_jnt_class_id_foreign` (`class_id`),
    KEY `sch_class_groups_jnt_section_id_foreign` (`section_id`),
    KEY `sch_class_groups_jnt_subject_type_id_foreign` (`subject_type_id`),
    KEY `sch_class_groups_jnt_rooms_type_id_foreign` (`rooms_type_id`),
    CONSTRAINT `sch_class_groups_jnt_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `sch_class_groups_jnt_rooms_type_id_foreign` FOREIGN KEY (`rooms_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `sch_class_groups_jnt_section_id_foreign` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `sch_class_groups_jnt_sub_stdy_frmt_id_foreign` FOREIGN KEY (`sub_stdy_frmt_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `sch_class_groups_jnt_subject_type_id_foreign` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- This table is used to define the subgroups for a particular class (e.g. In Class 10th A Student can choose from French / Sanskrit / German as optional 2nd Language)
  CREATE TABLE IF NOT EXISTS `tt_class_subgroup` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `subject_group_subject_id` INT unsigned NOT NULL,  -- FK to sch_subject_group_subjects.id
    `class_id` INT unsigned NOT NULL,
    `section_id` INT unsigned DEFAULT NULL,
    `subject_study_format_id` INT unsigned NOT NULL,  -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    `subject_type_id` INT unsigned NOT NULL,  -- FK to sch_subject_types.id. e.g `LECTURE`,`LAB,`SPORTS`,`ACTIVITY` etc.
    `rooms_type_id` INT unsigned NOT NULL,  -- FK to sch_rooms_type.id. e.g LAB, CLASSROOM, AUDITORIUM, etc.
    `code` VARCHAR(50) NOT NULL,   -- e.g., '10TH_FRENCH_OPT','8TH_HOBBY_GRP', 8th-12th_CRICKET, 8th-12th_FOOTBALL
    `name` VARCHAR(150) NOT NULL,  -- e.g., 'French(Optional) 10th Class(All Sections)'
    `description` VARCHAR(255) DEFAULT NULL,
    `student_count` INT UNSIGNED DEFAULT NULL,  -- Number of students in this subgroup
    `min_students` INT UNSIGNED DEFAULT NULL,  -- Minimum number of students required for a subgroup
    `max_students` INT UNSIGNED DEFAULT NULL,  -- Maximum number of students allowed in a subgroup
    `is_shared_across_sections` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether this subgroup is shared across sections
    `is_shared_across_classes` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether this subgroup is shared across classes
    `eligible_teacher_count` INT UNSIGNED DEFAULT NULL,  -- Number of teachers for this subgroup
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subgroup_code` (`code`),
    KEY `idx_subgroup_type` (`subgroup_type`),
    CONSTRAINT `fk_subgroup_class_group` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------
--  SECTION 2: CONSTRAINT ENGINE
-- -------------------------------------------------

  CREATE TABLE IF NOT EXISTS `tt_constraint_type` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(60) NOT NULL,  -- e.g., 'TEACHER_NOT_AVAILABLE','MIN_DAYS_BETWEEN','SAME_STARTING_TIME'
    `name` VARCHAR(150) NOT NULL,  -- e.g., 'Teacher Not Available','Minimum Days Between','Same Starting Time'
    `description` TEXT DEFAULT NULL,
    `category` ENUM('TIME','SPACE','TEACHER','STUDENT','ACTIVITY','ROOM') NOT NULL,  -- e.g., 'Teacher','Student','Room','Activity','Class','Class Subject','Study Format','Subject','Student Set','Class Group','Class Subgroup'
    `scope` ENUM('GLOBAL','TEACHER','STUDENT','ROOM','ACTIVITY','CLASS','CLASS_SUBJECT','STUDY_FORMAT','SUBJECT','STUDENT_SET','CLASS_GROUP','CLASS_SUBGROUP') NOT NULL,
    `default_weight` TINYINT UNSIGNED DEFAULT 100,  -- Default weight for this constraint type
    `is_hard_capable` TINYINT(1) DEFAULT 1,  -- Whether this constraint type can be set as hard
    `param_schema` JSON DEFAULT NULL,  -- JSON schema for parameters required by this constraint type
    `is_system` TINYINT(1) DEFAULT 1,  -- Whether this constraint type is a system constraint type
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
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `constraint_type_id` INT UNSIGNED NOT NULL,  -- FK to tt_constraint_type.id
    `name` VARCHAR(200) DEFAULT NULL,
    `description` VARCHAR(500) DEFAULT NULL,
    `academic_session_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_academic_sessions.id
    `target_type` ENUM('GLOBAL','TEACHER','STUDENT_SET','ROOM','ACTIVITY','CLASS','SUBJECT','STUDY_FORMAT','CLASS_GROUP','CLASS_SUBGROUP','TEACHER_SUBJECT', 'CROSS_CLASS', 'TIME_SLOT') NOT NULL,
    `target_id` INT UNSIGNED DEFAULT NULL,  -- FK to target_type.id
    `is_hard` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether this constraint is hard
    `weight` TINYINT UNSIGNED NOT NULL DEFAULT 100,  -- Weight of this constraint
    `params_json` JSON NOT NULL,  -- JSON object containing parameters for this constraint
    `effective_from` DATE DEFAULT NULL,  -- Effective date of this constraint
    `effective_to` DATE DEFAULT NULL,  -- Expiry date of this constraint
    `applies_to_days_json` JSON DEFAULT NULL,  -- JSON array of days this constraint applies to
    `status` ENUM('DRAFT','ACTIVE','DISABLED') NOT NULL DEFAULT 'ACTIVE',  -- Status of this constraint
    -- Newly Addedd
    `impact_score` TINYINT UNSIGNED DEFAULT 50 COMMENT 'Estimated impact on timetable generation difficulty (1-100)',
    `applies_to_terms_json` JSON DEFAULT NULL COMMENT 'Which academic terms this constraint applies to',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this constraint is active
    `created_by` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_constraint_uuid` (`uuid`),
    INDEX `idx_constraint_type` (`constraint_type_id`),
    INDEX `idx_constraint_target` (`target_type`, `target_id`),
    INDEX `idx_constraint_session` (`academic_session_id`),
    INDEX `idx_constraint_status` (`status`),
    INDEX `idx_constraint_impact` (`impact_score`),
    INDEX `idx_constraint_lookup` ON `tt_constraint` (`academic_session_id`, `target_type`, `target_id`, `status`, `is_active`);
    CONSTRAINT `fk_constraint_type` FOREIGN KEY (`constraint_type_id`) REFERENCES `tt_constraint_type` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_constraint_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_constraint_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `tt_teacher_unavailable` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `teacher_id` INT UNSIGNED NOT NULL,  -- FK to sch_teachers.id
    `constraint_id` INT UNSIGNED DEFAULT NULL,  -- FK to tt_constraint.id
    `day_of_week` TINYINT UNSIGNED NOT NULL,  -- 1=Monday, 2=Tuesday, etc. (ISO 8601)
    `period_ord` TINYINT UNSIGNED DEFAULT NULL,  -- 1=First period, 2=Second period, etc.
    `start_date` DATE DEFAULT NULL,
    `end_date` DATE DEFAULT NULL,
    `reason` VARCHAR(255) DEFAULT NULL,
    `is_recurring` TINYINT(1) DEFAULT 1,  -- Whether this is a recurring unavailable period
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
--  SECTION 3: TIMETABLE OPERATION TABLES
-- -------------------------------------------------

  CREATE TABLE IF NOT EXISTS `tt_class_group_requirement` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `class_group_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_class_groups_jnt.id
    `class_subgroup_id` INT UNSIGNED DEFAULT NULL,  -- FK to tt_class_subgroup.id
    -- `academic_session_id` INT UNSIGNED DEFAULT NULL,  -- FK to tt_academic_session.id
    `academic_term_id` INT UNSIGNED NOT NULL,  -- FK to tt_academic_term.id  -- This is the Term for which this timetable is being generated (New)
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
    `tot_students` SMALLINT UNSIGNED DEFAULT NULL,  -- Total students in this class group
    `weekly_activity_required` TINYINT(1) UNSIGNED DEFAULT 0,  -- Whether weekly activity is required
    `compulsory_room_type` INT UNSIGNED DEFAULT NULL,  -- FK to sch_room_types.id
    -- Below 3 Fileds will be captured from sch_class_groups_jnt
    `compulsory_specific_room_type` TINYINT(1) NOT NULL DEFAULT 0, -- Whether specific room type is required (TRUE - if Specific Room Type is Must)
    `required_room_type_id` INT UNSIGNED NOT NULL,      -- FK to sch_room_types.id (MUST)
    `required_room_id` INT UNSIGNED DEFAULT NULL,      -- FK to sch_rooms.id (OPTIONAL)
    -- Audit Fields
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,  -- Whether this requirement is active
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

  CREATE TABLE IF NOT EXISTS `tt_activity` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,  -- UUID
    `code` VARCHAR(50) NOT NULL,  -- e.g., 'ACT_10A_MTH_LAC_001'
    `name` VARCHAR(200) NOT NULL,  -- e.g., 'Mathematics Lecture - Class 10A'
    `description` VARCHAR(500) DEFAULT NULL,  -- Description of the activity
    -- `academic_session_id` INT UNSIGNED NOT NULL,  -- FK to 'sch_org_academic_sessions_jnt'
    `academic_term_id` INT UNSIGNED NOT NULL,  -- FK to tt_academic_term.id  -- This is the Term for which this timetable is being generated (New)
    -- Target (one of class_group_id or class_subgroup_id must be set)
    `class_group_id` INT UNSIGNED DEFAULT NULL,  -- FK to 'sch_class_groups_jnt'
    `class_subgroup_id` INT UNSIGNED DEFAULT NULL,  -- FK to 'tt_class_subgroup'
    -- Subject & Study Format (denormalized for fast access)
    `subject_id` INT UNSIGNED DEFAULT NULL,  -- FK to 'sch_subjects'
    `study_format_id` INT UNSIGNED DEFAULT NULL,  -- FK to 'sch_study_formats'
    -- Duration
    `duration_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,  -- If One Activity can not be done in 1 Period then this will how many periods required for one activity (e.g. Lab = 2 but will be count as 1 Activity)
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
    UNIQUE KEY `uq_activity_uuid` (`uuid`),
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
    CONSTRAINT `fk_activity_subgroup` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroup` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_activity_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_activity_study_format` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_activity_room_type` FOREIGN KEY (`preferred_room_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_activity_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    -- Must have either class_group or subgroup
    CONSTRAINT `chk_activity_target` CHECK ((`class_group_id` IS NOT NULL AND `class_subgroup_id` IS NULL) OR (`class_group_id` IS NULL AND `class_subgroup_id` IS NOT NULL))
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- IMPORTANT: Add triggers to maintain data integrity
  DELIMITER $$

  CREATE TRIGGER `trg_tt_activity_difficulty_calc`
  BEFORE INSERT ON `tt_activity`
  FOR EACH ROW
  BEGIN
      -- Calculate difficulty score automatically
      SET NEW.difficulty_score_calculated = (
          SELECT 
              COUNT(DISTINCT c.id) * 10 + -- Constraint count
              (100 - COALESCE(NEW.teacher_availability_score, 100)) * 0.5 + -- Teacher availability
              (100 - COALESCE(NEW.room_availability_score, 100)) * 0.3 + -- Room availability
              CASE WHEN NEW.duration_periods > 1 THEN 15 ELSE 0 END + -- Duration penalty
              CASE WHEN NEW.requires_special_room THEN 10 ELSE 0 END -- Special room penalty
      );
      -- Ensure difficulty score is within bounds
      IF NEW.difficulty_score_calculated > 100 THEN
          SET NEW.difficulty_score_calculated = 100;
      END IF;
      -- Update the main difficulty score
      SET NEW.difficulty_score = NEW.difficulty_score_calculated;
  END$$

  CREATE TRIGGER `trg_tt_timetable_cell_date_consistency`
  BEFORE INSERT ON `tt_timetable_cell`
  FOR EACH ROW
  BEGIN
      -- Ensure day_of_week matches cell_date
      IF NEW.cell_date IS NOT NULL THEN
          SET NEW.day_of_week = DAYOFWEEK(NEW.cell_date);
      END IF;
      -- Auto-set generation_run_id if not provided
      IF NEW.generation_run_id IS NULL THEN
          SET NEW.generation_run_id = (
              SELECT id FROM tt_generation_run 
              WHERE timetable_id = NEW.timetable_id 
              AND status = 'COMPLETED'
              ORDER BY finished_at DESC 
              LIMIT 1
          );
      END IF;
  END$$

  DELIMITER ;


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

  CREATE TABLE IF NOT EXISTS `tt_sub_activity` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `parent_activity_id` INT UNSIGNED NOT NULL,  -- FK to tt_activity.id
    `sub_activity_ord` TINYINT UNSIGNED NOT NULL,  -- Order of this sub-activity within the parent activity
    `code` VARCHAR(60) NOT NULL,  -- e.g., 'ACT_10A_MTH_LAC_001_S1'
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


-- -------------------------------------------------
--  SECTION 4: TIMETABLE GENERATION & STORAGE
-- -------------------------------------------------
  -- Main Timetable Generation Table
  CREATE TABLE IF NOT EXISTS `tt_timetable` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
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
      `conflicts_json` JSON,
      `resolution_suggestions_json` JSON,
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
    `uuid` BINARY(16) NOT NULL,
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
    UNIQUE KEY `uq_gr_uuid` (`uuid`),
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
    CONSTRAINT `fk_cell_subgroup` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroup` (`id`) ON DELETE CASCADE,
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
--  SECTION 5: TIMETABLE REPORTS
-- -------------------------------------------------
-- NOTHING IN THIS SECTION FOR NOW

-- -------------------------------------------------
--  SECTION 6: SUBSTITUTION MANAGEMENT
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

-- -------------------------------------------------
--  SECTION 8: TEACHER WORKLOAD & ANALYTICS
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
--  SECTION 9: AUDIT & HISTORY
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



-- =====================================================================================================================================================
-- REFERENCE TABLES FROM OTHER MODULES
-- =====================================================================================================================================================

  -- This table is a replica of 'prm_tenant' table in 'prmprime_db' database
  CREATE TABLE IF NOT EXISTS `sch_organizations` (
    `id` INT unsigned NOT NULL,              -- it will have same id as it is in 'prm_tenant'
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

  CREATE TABLE IF NOT EXISTS `sch_org_academic_sessions_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `academic_session_id` INT unsigned NOT NULL,
    `short_name` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
    `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
    `start_date` date NOT NULL,
    `end_date` date NOT NULL,
    `is_current` tinyint(1) NOT NULL DEFAULT '0',
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `current_flag` tinyint(1) NOT NULL DEFAULT '0',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `sch_org_academic_sessions_jnt_academic_session_id_foreign` (`academic_session_id`),
    KEY `idx_orgAcademicSessions_active` (`is_active`),
    CONSTRAINT `sch_org_academic_sessions_jnt_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `global_master`.`glb_academic_sessions` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `sch_classes` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
    `short_name` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `ordinal` tinyint DEFAULT NULL,
    `code` char(3) COLLATE utf8mb4_unicode_ci NOT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
    `class_teacher_id` INT unsigned NOT NULL,    -- FK to sch_users
    `assistance_class_teacher_id` INT unsigned NOT NULL,  -- FK to sch_users
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
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
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
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `subject_id` INT unsigned NOT NULL,            -- FK to 'sch_subjects'
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
    `id` INT unsigned NOT NULL AUTO_INCREMENT,           -- FK
    `class_id` int unsigned NOT NULL,                       -- FK to 'sch_classes'
    `section_id` int unsigned NULL,                         -- FK to 'sch_sections'
    `sub_stdy_frmt_id` INT unsigned NOT NULL,            -- FK to 'sch_subject_study_format_jnt'
    -- `subject_Study_format_id` INT unsigned NOT NULL, -- FK to 'sch_subject_study_format_jnt'
    `subject_type_id` int unsigned NOT NULL,                -- FK to 'sch_subject_types'
    `rooms_type_id` int unsigned NOT NULL,                  -- FK to 'sch_rooms_type'
    `class_house_roome_id` int unsigned NOT NULL,           -- FK to 'sch_rooms
    `name` varchar(50) NOT NULL,                            -- 10th-A Science Lacture Major
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
    CONSTRAINT `fk_classGroups_subjStudyFormatId` FOREIGN KEY (`sub_stdy_frmt_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classGroups_subTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classGroups_roomTypeId` FOREIGN KEY (`rooms_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classGroups_classHouseRoomId` FOREIGN KEY (`class_house_roome_id`) REFERENCES `sch_rooms` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  -- Table 'sch_subject_groups' will be used to assign all subjects to the students
  -- There will be a Variable in 'sch_settings' table named 'SubjGroup_For_All_Sections' (Subj_Group_will_be_used_for_all_sections_of_a_class)
  -- if above variable is True then section_id will be Nul in below table and
  -- Every Group will eb avalaible accross sections for a particuler class
  CREATE TABLE IF NOT EXISTS `sch_subject_groups` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
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
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `subject_group_id` INT unsigned NOT NULL,              -- FK to 'sch_subject_groups'
    `class_group_id` INT unsigned NOT NULL,                -- FK to 'sch_class_groups_jnt'
    `subject_id` int unsigned NOT NULL,                       -- FK to 'sch_subjects'
    `subject_type_id` int unsigned NOT NULL,                  -- FK to 'sch_subject_types'
    `subject_study_format_id` INT unsigned NOT NULL,       -- FK to 'sch_subject_study_format_jnt'
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
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NULL,
    `updated_at` TIMESTAMP NULL,
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
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_employee_role_active` (`employee_id`, `role_id`, `effective_to`),
    -- Foreign Key Constraints
    CONSTRAINT `fk_employeeProfile_employeeId` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`),
    CONSTRAINT `fk_employeeProfile_roleId` FOREIGN KEY (`role_id`) REFERENCES `sch_employee_roles` (`id`),
    CONSTRAINT `fk_employeeProfile_departmentId` FOREIGN KEY (`department_id`) REFERENCES `sch_departments` (`id`),
    CONSTRAINT `fk_employeeProfile_reportingTo` FOREIGN KEY (`reporting_to`) REFERENCES `sch_employees` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Teacher Profile table will store detailed proficiency to teach specific subjects, study formats, and classes
  CREATE TABLE IF NOT EXISTS `sch_teachers_profile` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id` INT UNSIGNED NOT NULL,         -- FK to sch_employee.id
    `user_id` INT UNSIGNED NOT NULL,             -- FK to sys_users.id
    `role_id` INT UNSIGNED NOT NULL,                  -- FK to employee_roles table (Principal, Accountant, Admin, etc.)
    `department_id` INT UNSIGNED DEFAULT NULL,        -- FK to sch_departments (Administration, Accounts, IT, etc.)
    `teacher_house_room_id` int unsigned NULL,          -- FK to 'sch_rooms.id'
    -- Teaching Capacity & Availability
    `subject_id` INT UNSIGNED NOT NULL,            -- FK to 'subjects' table
    `study_format_id` INT UNSIGNED NOT NULL,       -- FK to 'sch_study_formats' table 
    `class_id` INT UNSIGNED NOT NULL,                 -- FK to 'sch_classes' table
    `proficiency_percentage` TINYINT UNSIGNED DEFAULT NULL,  -- 1–100 %
    `teaching_experience_months` TINYINT UNSIGNED DEFAULT NULL,  -- teaching experience in months
    `is_primary_subject` TINYINT(1) NOT NULL DEFAULT 1,  -- 1=Primary, 0=Secondary
    `max_periods_daily` TINYINT UNSIGNED DEFAULT 6,     -- Maximum number of periods per day
    `min_periods_daily` TINYINT UNSIGNED DEFAULT 1,     -- Minimum number of periods per day
    `max_periods_weekly` TINYINT UNSIGNED DEFAULT 48,   -- Maximum weekly periods
    `min_periods_weekly` TINYINT UNSIGNED DEFAULT 15,   -- Minimum weekly periods
    `preferred_shift` ENUM('morning', 'evening', 'flexible') DEFAULT 'morning',
    `is_full_time` TINYINT(1) DEFAULT 1,                 -- 1=Full-time, 0=Part-time
    `is_capable_of_handling_multiple_classes` TINYINT(1) DEFAULT 0, -- 1=Yes, 0=No
    `is_proficient_with_computer` TINYINT(1) DEFAULT 0, -- 1=Yes, 0=No
    -- Skills & Responsibilities (JSON for flexibility)
    `special_skill_area` VARCHAR(100) DEFAULT NULL,   -- e.g. Robotics, AI, Debate
    `certified_for_lab` TINYINT(1) DEFAULT 0,         -- allowed to conduct practicals
    `assignment_meta` JSON DEFAULT NULL,              -- e.g. { "qualification": "M.Sc Physics", "experience": "7 years" }
    `soft_skills` JSON DEFAULT NULL,                     -- e.g., ["leadership", "communication", "problem_solving"]
    `performance_rating` TINYINT UNSIGNED DEFAULT NULL,  -- rating out of (1 to 10)
    `last_performance_review` DATE DEFAULT NULL,
    -- Administrative Controls
    `security_clearance_done` TINYINT(1) DEFAULT 0, --
    `reporting_to` INT UNSIGNED DEFAULT NULL,         -- FK to sch_employees.id (who they report to)
    `can_manage_staff` TINYINT(1) DEFAULT 0,
    `can_access_sensitive_data` TINYINT(1) DEFAULT 0,
    `notes` TEXT NULL,
    `effective_from` DATE DEFAULT NULL,               -- when this profile becomes effective
    `effective_to` DATE DEFAULT NULL,                 -- when this profile ends 
    `is_active` TINYINT(1) NOT NULL DEFAULT '1',
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_teachersProfile_employee` (`employee_id`,`subject_id`,`study_format_id`,`class_id`),
    CONSTRAINT `fk_teachersProfile_employeeId` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_teachersProfile_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_teachersProfile_studyFormatId` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_teachersProfile_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================================================================================================
