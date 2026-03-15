-- =====================================================================
-- TIMETABLE MODULE - VERSION 7.0 (PRODUCTION-GRADE)
-- Enhanced from tt_timetable_ddl_v6.0.sql
-- =====================================================================
-- Target: MySQL 8.x | Stack: PHP + Laravel
-- Architecture: Multi-tenant, Constraint-based Auto-Scheduling
-- TABLE PREFIX: tt_ - Timetable Module
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

--  Smart Timetable Module Menu Items :
  -- 1.  Pre-Requisites
  --      1.1. Buildings
  --      1.2. Room Types
  --      1.3. Rooms
  --      1.4. Teacher Profile
  --      1.5. Class & Section
  --      1.6. Subject & Study Format
  --      1.7. School Class Group
  -- 2.  Timetable Configuration
  --      2.1. Timetable Config
  --      2.2. Academic Terms
  --      2.3. Timetable Generation Strategy
  -- 3.  Timetable Masters
  --      3.1. Shift
  --      3.2. Day Type
  --      3.3. Period Type
  --      3.4. Teacher Roles
  --      3.5. School Days
  --      3.6. Working Days
  --      3.7. Class Working days
  --      3.8. Period Set    (tt_period_set & tt_period_set_period_jnt)
  --      3.9. Timetable Type
  --      3.10. Class Timetable
  -- 4.  Timetable Requirement
  --      4.1. Slot Requirement
  --      4.2. Class Requirement Group
  --      4.3. Class Requirement Sub-Group
  --      4.4. Class Requirement Consolidation
  -- 5.  Timetable Constraint Engine
  --      5.1. Constraint Category & Scope
  --      5.2. Constraint Type
  --      5.3. Constraint Creation
  --      5.4. Teacher Unavailability
  --      5.5. Room Unavailability
  -- 6.  Timetable Resource Availability
  --      6.1. Teachers Availability
  --      6.2. Techers Availability Log
  --      6.3. Rooms Availability
  -- 7.  Timetable Preparation
  --      7.1. Activity
  --      7.2. Sub Activity
  --      7.3. Priority Config
  --      7.4. Activity Teacher Mapping
  -- 8.  Timetable Generation
  --      8.1. Timetable Generation (tt_generation_run)
  --      8.2. Conflict Management (tt_constraint_violation & tt_conflict_detection)
  --      8.3. Resource Allocation (tt_resource_booking)
  --      8.4. TT Generation Log
  --      8.5. TT Generation Summary
  -- 9.  Timetable View & Refinement
  --      9.1. Timetable View (Teacher wise/Class wise/Room wise/Subject wise/Day wise)
  --      9.2. Manual Refinement (tt_timetable_cell)
  --      9.3. Lock Timetable
  --      9.4. Publish Timetable
  -- 10. Report & Logs        --> (This include Audit & History)
  --      10.1. Class wise Timetable Report
  --      10.2. Teacher wise Timetable Report
  --      10.3. Room wise Timetable Report
  --      10.4. Teacher Workload Analysis
  --      10.5. Rooms Utilization Analysis
  --      10.6. Teacher Requirement Analysis
  -- 11. Substitute Management
  --      11.1. Substitute Requirement
  --      11.2. Propose & Approve Substitute
  --      11.3. Notification for Substitute


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
    `academic_year_start_date` DATE NOT NULL,
    `academic_year_end_date` DATE NOT NULL,
    `total_terms_in_academic_session` TINYINT UNSIGNED NOT NULL,     -- Total Terms in an Academic Session -- e.g., 1, 2, 3, 4
    `term_ordinal` TINYINT UNSIGNED NOT NULL,                        -- Term Ordinal. -- e.g., 1, 2, 3, 4
    `term_code` VARCHAR(20) NOT NULL,                                -- Term Code. (e.g., 'SUMMER', 'WINTER', 'Q1', 'Q2', 'Q3', 'Q4')
    `term_name` VARCHAR(100) NOT NULL,                               -- Term Name. (e.g., 'Summer Term', 'Winter Term', 'QUATER - 1', 'QUATER - 2', 'QUATER - 3', 'QUATER - 4')
    `term_start_date` DATE NOT NULL,                                 -- Term Start Date  (e.g., '2024-01-01', '2024-02-01', '2024-03-01', '2024-04-01', '2024-05-01', '2024-06-01')
    `term_end_date` DATE NOT NULL,                                   -- Term End Date  (e.g., '2024-01-31', '2024-02-29', '2024-03-31', '2024-04-30', '2024-05-31', '2024-06-30')
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
  -- 2. 


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
    UNIQUE KEY `uq_constraint_uuid` (`uuid`),
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
    `is_full_time` TINYINT(1) DEFAULT 1,              -- 1=Full-time, 0=Part-time
    `preferred_shift` INT UNSIGNED DEFAULT NULL,    -- FK to sch_shift.id
    `capable_handling_multiple_classes` TINYINT(1) DEFAULT 0,
    `can_be_used_for_substitution` TINYINT(1) DEFAULT 1,
    `certified_for_lab` TINYINT(1) DEFAULT 0,
    `max_available_periods_weekly` TINYINT UNSIGNED DEFAULT 48,
    `min_available_periods_weekly` TINYINT UNSIGNED DEFAULT 36,
    `max_allocated_periods_weekly` TINYINT UNSIGNED DEFAULT 1,
    `min_allocated_periods_weekly` TINYINT UNSIGNED DEFAULT 1,
    `can_be_split_across_sections` TINYINT(1) DEFAULT 0,
    -- From Teachers Capability (sch_teacher_capabilities)
    `proficiency_percentage` TINYINT UNSIGNED DEFAULT NULL, -- 1–100
    `teaching_experience_months` SMALLINT UNSIGNED DEFAULT NULL,
    `is_primary_subject` TINYINT(1) NOT NULL DEFAULT 1,  -- 1=Yes, 0=No
    `competancy_level` ENUM('Basic','Intermediate','Advanced','Expert') DEFAULT 'Basic',
    `priority_order` INT UNSIGNED DEFAULT NULL,   -- Priority Order of the Teacher for the Class+Subject+Study_Format
    `priority_weight` TINYINT UNSIGNED DEFAULT NULL,   -- manual / computed weight (1–10) (Even if teachers are available, how important is THIS activity to the school?)
    `scarcity_index` TINYINT UNSIGNED DEFAULT NULL,    -- 1=abundant, 10=very rare
    `is_hard_constraint` TINYINT(1) DEFAULT 0,         -- if true cannot be voilated e.g. Physics Lab teacher for Class 12
    `allocation_strictness` ENUM('hard','medium','soft') DEFAULT 'medium', e.g. Senior Maths teacher - Hard, Preferred English teacher - Medium, Art / Sports / Activity - Soft
    -- Priority Override & Historical Feedback
    `override_priority` TINYINT UNSIGNED DEFAULT NULL, -- admin override
    `override_reason` VARCHAR(255) DEFAULT NULL,
    `historical_success_ratio` TINYINT UNSIGNED DEFAULT NULL, -- 1–100 (sessions_completed_without_change / total_sessions_allocated ) * 100)
    `last_allocation_score` TINYINT UNSIGNED DEFAULT NULL,   -- last run score (1–100)
    -- Editable - School Preference for a Teacher for a Particuler Class+Subject+StudyFormat
    `is_primary_teacher` TINYINT(1) NOT NULL DEFAULT 1,  -- 1=Yes, 0=No 9can be calculated on the basis of 
    `is_preferred_teacher` TINYINT(1) NOT NULL DEFAULT 0,  -- 1=Yes, 0=No
    `preference_score` TINYINT UNSIGNED DEFAULT NULL,   -- 1–100 
    -- Status Duration
    `effective_from` DATE DEFAULT NULL,
    `effective_to` DATE DEFAULT NULL,
    -- Calculated Scores
    `min_teacher_availability_score` DECIMAL(7,2) UNSIGNED DEFAULT 1  -- Percentage of available teachers for this Class Group (Will capture from Teachers profile)
    `max_teacher_availability_score` DECIMAL(7,2) UNSIGNED DEFAULT 1  -- Percentage of available teachers for this Class Group (Will capture from Teachers profile)
    -- Activity
    `activity_id` INT unsigned NULL,               -- FK to tt_activity.id
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ta_class_wise` (`teacher_id`,`class_id`, `section_id`, `subject_study_format_id`, `start_time`, `end_time`),
    CONSTRAINT `fk_ta_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`), 
    CONSTRAINT `fk_ta_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_ta_subject_study_format` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_study_formats` (`id`),
    CONSTRAINT `fk_ta_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_ta_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
    -- teacher_availability_ratio = (Total weekly available Periods / (Total Number of Subjects he can teach in a week) * 100
    -- Example: If a teacher can teach 3 Subject for class-4, 3 Subject for Class-5 & 2 Subject for Class-6 in a week and has 36 available periods in a week, 
    -- then his teacher_availability_ratio is (8 / 36) * 100 = 22.22%  
    -- TAR = (Total weekly assigned Periods / Total weekly available Periods) * 100

  CREATE TABLE IF NOT EXISTS `tt_teacher_availability_log` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `teacher_availability_id` INT unsigned NOT NULL,  -- FK to tt_teacher_availability.id
    `class_id` INT unsigned NOT NULL,                 -- FK to sch_classes.id
    `section_id` INT unsigned DEFAULT NULL,           -- FK to sch_sections.id
    `subject_study_format_id` INT unsigned NOT NULL,  -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    `teacher_id` INT unsigned NOT NULL,               -- FK to sch_teachers.id
    `day1_available_period_count` TINYINT UNSIGNED NOT NULL,  -- 1-8 How many slots that Class+section have on Day 1
    `day2_available_period_count` TINYINT UNSIGNED NOT NULL,  -- 1-8 How many slots that Class+section have on Day 2
    `day3_available_period_count` TINYINT UNSIGNED NOT NULL,  -- 1-8 How many slots that Class+section have on Day 3
    `day4_available_period_count` TINYINT UNSIGNED NOT NULL,  -- 1-8 How many slots that Class+section have on Day 4
    `day5_available_period_count` TINYINT UNSIGNED NOT NULL,  -- 1-8 How many slots that Class+section have on Day 5
    `day6_available_period_count` TINYINT UNSIGNED NOT NULL,  -- 1-8 How many slots that Class+section have on Day 6
    `day7_available_period_count` TINYINT UNSIGNED NOT NULL,  -- 1-8 How many slots that Class+section have on Day 7
    `effective_from` DATE DEFAULT NULL,
    `effective_to` DATE DEFAULT NULL,
    `activity_id` INT unsigned NULL,               -- FK to tt_activity.id
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ta_class_wise` (`teacher_id`,`class_id`, `section_id`, `subject_study_format_id`, `start_time`, `end_time`),
    CONSTRAINT `fk_ta_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`), 
    CONSTRAINT `fk_ta_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_ta_subject_study_format` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_study_formats` (`id`),
    CONSTRAINT `fk_ta_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`),
    CONSTRAINT `fk_ta_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  -- Create Room Availability Class wise for entire Academic Session
  CREATE TABLE IF NOT EXISTS `tt_room_availability` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `room_id` INT unsigned NOT NULL,               -- FK to sch_rooms.id
    `room_type_id` INT unsigned NOT NULL,          -- FK to tt_room_type.id
    `class_house_room_id` int unsigned NOT NULL,      -- FK to 'sch_rooms'
    `class_id` INT unsigned NULL,                  -- FK to sch_classes.id
    `section_id` INT unsigned NULL,                -- FK to sch_sections.id
    `subject_study_format_id` INT unsigned NULL,   -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    `activity_id` INT unsigned NULL,               -- FK to tt_activity.id
    `capacity` int unsigned DEFAULT NULL,
    `max_limit` int unsigned DEFAULT NULL,
    `start_time` time NOT NULL,                       -- This will be fetched from (tt_timetable_type.effective_from_date)
    `end_time` time NOT NULL,                         -- This will be fetched from (tt_timetable_type.effective_to_date)
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ra_class_wise` (`room_id`,`room_type_id`, `class_id`, `section_id`, `subject_study_format_id`, `start_time`, `end_time`),
    CONSTRAINT `fk_room_availability_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`),
    CONSTRAINT `fk_room_availability_room_type` FOREIGN KEY (`room_type_id`) REFERENCES `tt_room_type` (`id`),
    CONSTRAINT `fk_room_availability_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`), 
    CONSTRAINT `fk_room_availability_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_room_availability_subject_study_format` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_study_formats` (`id`),
    CONSTRAINT `fk_room_availability_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`)
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
    `uuid` BINARY(16) NOT NULL,                         -- UUID
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


-- =====================================================================================================================================================
