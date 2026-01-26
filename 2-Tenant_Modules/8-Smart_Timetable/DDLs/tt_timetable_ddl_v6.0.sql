-- =====================================================================
-- TIMETABLE MODULE - VERSION 6.0 (PRODUCTION-GRADE)
-- Enhanced from tt_timetable_ddl_v5.0.sql
-- =====================================================================
-- Target: MySQL 8.x | Stack: PHP + Laravel
-- Architecture: Multi-tenant, Constraint-based Auto-Scheduling
-- TABLE PREFIX: tt_ - Timetable Module
-- =====================================================================
-- ENHANCEMENTS IN V6.0:
--   ✓ Fixed syntax errors (trailing commas in v5.0)
--   ✓ Renamed sch_shift to tt_shift (correct prefix)
--   ✓ Removed redundant tt_school_timing_profile (merged into tt_timetable_type)
--   ✓ Added class_subgroup_id to tt_class_group_requirement
--   ✓ Added missing FK to tt_day_type in tt_working_day
--   ✓ Updated table summary | Added comprehensive documentation
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================================
--  SECTION 0: MASTER CONFIGURATION TABLES
-- =========================================================================

CREATE TABLE IF NOT EXISTS `tt_shift` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL,  -- e.g., 'MORNING', 'AFTERNOON', 'EVENING'
  `name` VARCHAR(100) NOT NULL,  -- e.g., 'Morning', 'Afternoon', 'Evening'
  `description` VARCHAR(255) DEFAULT NULL,
  `default_start_time` TIME DEFAULT NULL,  -- e.g., '08:00:00'
  `default_end_time` TIME DEFAULT NULL,  -- e.g., '12:00:00'
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
  `code` VARCHAR(20) NOT NULL,  -- e.g., 'WORKING','HOLIDAY','EXAM','SPECIAL'
  `name` VARCHAR(100) NOT NULL,  -- e.g., 'Working Day','Holiday','Exam','Special Day'
  `description` VARCHAR(255) DEFAULT NULL,
  `is_working_day` TINYINT(1) NOT NULL DEFAULT 1,  -- 1 for working day, 0 for non-working day
  `reduced_periods` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for reduced periods, 0 for full periods
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
  `code` VARCHAR(30) NOT NULL,  -- e.g., 'TEACHING','BREAK','LUNCH','ASSEMBLY','EXAM','RECESS'
  `name` VARCHAR(100) NOT NULL,  -- e.g., 'Teaching','Break','Lunch','Assembly','Exam','Recess'
  `description` VARCHAR(255) DEFAULT NULL,
  `color_code` VARCHAR(10) DEFAULT NULL,  -- e.g., '#FF0000', '#00FF00', '#0000FF'
  `icon` VARCHAR(50) DEFAULT NULL,  -- e.g., 'fa-solid fa-chalkboard-teacher', 'fa-solid fa-clock', 'fa-solid fa-luch'
  `is_schedulable` TINYINT(1) NOT NULL DEFAULT 1,  -- 1 for schedulable, 0 for non-schedulable
  `counts_as_teaching` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for counts as teaching, 0 for non-teaching
  `counts_as_workload` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for counts as workload, 0 for non-workload
  `is_break` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for break, 0 for non-break
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
  `code` VARCHAR(30) NOT NULL,  -- e.g., 'PRIMARY','ASSISTANT','CO_TEACHER','SUBSTITUTE','TRAINEE'
  `name` VARCHAR(100) NOT NULL,  -- e.g., 'Primary','Assistant','Co-Teacher','Substitute','Trainee'
  `description` VARCHAR(255) DEFAULT NULL,
  `is_primary_instructor` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for primary instructor, 0 for non-primary instructor
  `counts_for_workload` TINYINT(1) NOT NULL DEFAULT 1,  -- 1 for counts for workload, 0 for non-counts for workload
  `allows_overlap` TINYINT(1) NOT NULL DEFAULT 0,  -- 1 for allows overlap, 0 for non-allows overlap
  `workload_factor` DECIMAL(3,2) DEFAULT 1.00,  -- e.g., 1.00, 2.00, 3.00
  `ordinal` SMALLINT UNSIGNED DEFAULT 1,  -- e.g., 1, 2, 3
  `is_system` TINYINT(1) DEFAULT 1,  -- 1 for system, 0 for non-system
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- 1 for active, 0 for non-active
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tarole_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tt_school_days` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
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

CREATE TABLE IF NOT EXISTS `tt_working_day` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `date` DATE NOT NULL,  -- e.g., '2023-01-01'
  `day_type_id` BIGINT UNSIGNED NOT NULL,  -- FK to tt_day_type.id
  `is_school_day` TINYINT(1) NOT NULL DEFAULT 1,  -- 1 for school day, 0 for non-school day
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

-- =========================================================================
--  SECTION 1: PERIOD SET CONFIGURATION
-- =========================================================================

CREATE TABLE IF NOT EXISTS `tt_period_set` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(30) NOT NULL,  -- e.g., '3rd-12th_NORMAL_8P','4th-12th_EXAM_3P','5th-12th_HALF_DAY_4P','BV1-2nd_TODDLER_6P'
  `name` VARCHAR(100) NOT NULL,  -- e.g., '3rd-12th Normal 8P','4th-12th Exam 3P','5th-12th Half Day 4P','BV1-2nd Toddler 6P'
  `description` VARCHAR(255) DEFAULT NULL,
  `total_periods` TINYINT UNSIGNED NOT NULL,  -- e.g., 8, 3, 4, 6
  `teaching_periods` TINYINT UNSIGNED NOT NULL,  -- e.g., 8, 3, 4, 6
  `start_time` TIME NOT NULL,  -- e.g., '08:00:00'
  `end_time` TIME NOT NULL,  -- e.g., '12:00:00'
  `applicable_class_ids` JSON DEFAULT NULL,  -- e.g., [1,2,3,4,5,6,7]
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

-- =========================================================================
--  SECTION 2: TIMETABLE TYPE (Merges tt_school_timing_profile)
-- =========================================================================

CREATE TABLE IF NOT EXISTS `tt_timetable_type` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(30) NOT NULL,   -- e.g., 'Standard', 'Extended'
  `name` VARCHAR(100) NOT NULL,  -- e.g., 'Standard Timetable','Extended Timetable'
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

-- =========================================================================
--  SECTION 3: CLASS & STUDENT GROUPING
-- =========================================================================

CREATE TABLE IF NOT EXISTS `tt_class_mode_rule` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `class_id` INT UNSIGNED NOT NULL,  -- FK to tt_class.id 
  `timetable_type_id` BIGINT UNSIGNED NOT NULL,   -- FK to tt_timetable_type.id 
  `period_set_id` BIGINT UNSIGNED NOT NULL,   -- FK to tt_period_set.id 
  `academic_session_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to tt_academic_session.id 
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

CREATE TABLE IF NOT EXISTS `tt_class_subgroup` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(50) NOT NULL,   -- e.g., '10TH_FRENCH_OPT','8TH_HOBBY_GRP', 8th-12th_CRICKET, 8th-12th_FOOTBALL
  `name` VARCHAR(150) NOT NULL,  -- e.g., 'French(Optional) 10th Class(All Sections)'
  `description` VARCHAR(255) DEFAULT NULL,
  `class_group_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sch_class_groups_jnt.id
  `subgroup_type` ENUM('OPTIONAL_SUBJECT','HOBBY','SKILL','LANGUAGE','STREAM','ACTIVITY','SPORTS','OTHER') NOT NULL DEFAULT 'OTHER',  -- Type of subgroup
  `student_count` INT UNSIGNED DEFAULT NULL,  -- Number of students in this subgroup
  `min_students` INT UNSIGNED DEFAULT NULL,  -- Minimum number of students required for this subgroup
  `max_students` INT UNSIGNED DEFAULT NULL,  -- Maximum number of students allowed for this subgroup
  `is_shared_across_sections` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether this subgroup is shared across sections
  `is_shared_across_classes` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether this subgroup is shared across classes
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
  `class_subgroup_id` BIGINT UNSIGNED NOT NULL,  -- FK to tt_class_subgroup.id
  `class_id` INT UNSIGNED NOT NULL,  -- FK to sch_classes.id
  `section_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_sections.id
  `is_primary` TINYINT(1) DEFAULT 0,  -- Whether this is the primary subgroup for this class
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
  `class_group_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sch_class_groups_jnt.id
  `class_subgroup_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tt_class_subgroup.id
  `academic_session_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tt_academic_session.id
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


-- =========================================================================
--  SECTION 4: ACTIVITY MANAGEMENT
-- =========================================================================
-- TERMINOLOGY:
-- duration_periods = Consecutive slots (Lab=2) | weekly_periods = Times/week
-- priority = User importance | difficulty_score = Algorithm metric

CREATE TABLE IF NOT EXISTS `tt_activity` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,  -- UUID
  `code` VARCHAR(50) NOT NULL,  -- e.g., 'ACT_10A_MTH_LAC_001'
  `name` VARCHAR(200) NOT NULL,  -- e.g., 'Mathematics Lecture - Class 10A'
  `description` VARCHAR(500) DEFAULT NULL,  -- Description of the activity
  `academic_session_id` BIGINT UNSIGNED NOT NULL,  -- FK to 'sch_org_academic_sessions_jnt'
  -- Target (one of class_group_id or class_subgroup_id must be set)
  `class_group_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to 'sch_class_groups_jnt'
  `class_subgroup_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to 'tt_class_subgroup'
  -- Subject & Study Format (denormalized for fast access)
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to 'sch_subjects'
  `study_format_id` INT UNSIGNED DEFAULT NULL,  -- FK to 'sch_study_formats'
  -- Duration
  `duration_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,  -- Number of periods required for this activity
  `weekly_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,  -- Number of times per week this activity is scheduled
  `total_periods` SMALLINT UNSIGNED GENERATED ALWAYS AS (`duration_periods` * `weekly_periods`) STORED,
  -- Scheduling preferences
  `split_allowed` TINYINT(1) DEFAULT 0,  -- Whether this activity can be split across non-consecutive slots
  `is_compulsory` TINYINT(1) DEFAULT 1,  -- Must be scheduled?
  `priority` TINYINT UNSIGNED DEFAULT 50,  -- Scheduling priority (0-100)
  `difficulty_score` TINYINT UNSIGNED DEFAULT 50,  -- For algorithm sorting (higher = harder to schedule)
  -- Room requirements
  `requires_room` TINYINT(1) DEFAULT 1,  -- Whether this activity requires a room
  `preferred_room_type_id` INT UNSIGNED DEFAULT NULL,  -- FK to 'sch_room_types'
  `preferred_room_ids` JSON DEFAULT NULL,  -- List of preferred rooms
  -- Status
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
  `activity_id` BIGINT UNSIGNED NOT NULL,  -- FK to tt_activity.id
  `teacher_id` BIGINT UNSIGNED NOT NULL,  -- FK to sch_teachers.id
  `assignment_role_id` BIGINT UNSIGNED NOT NULL,  -- FK to tt_assignment_roles.id
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
  `parent_activity_id` BIGINT UNSIGNED NOT NULL,  -- FK to tt_activity.id
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

-- =========================================================================
--  SECTION 5: CONSTRAINT ENGINE
-- =========================================================================

CREATE TABLE IF NOT EXISTS `tt_constraint_type` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
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
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,
  `constraint_type_id` BIGINT UNSIGNED NOT NULL,  -- FK to tt_constraint_type.id
  `name` VARCHAR(200) DEFAULT NULL,
  `description` VARCHAR(500) DEFAULT NULL,
  `academic_session_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sch_academic_sessions.id
  `target_type` ENUM('GLOBAL','TEACHER','STUDENT_SET','ROOM','ACTIVITY','CLASS','SUBJECT','STUDY_FORMAT','CLASS_GROUP','CLASS_SUBGROUP') NOT NULL,
  `target_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to target_type.id
  `is_hard` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether this constraint is hard
  `weight` TINYINT UNSIGNED NOT NULL DEFAULT 100,  -- Weight of this constraint
  `params_json` JSON NOT NULL,  -- JSON object containing parameters for this constraint
  `effective_from` DATE DEFAULT NULL,  -- Effective date of this constraint
  `effective_to` DATE DEFAULT NULL,  -- Expiry date of this constraint
  `applies_to_days_json` JSON DEFAULT NULL,  -- JSON array of days this constraint applies to
  `status` ENUM('DRAFT','ACTIVE','DISABLED') NOT NULL DEFAULT 'ACTIVE',  -- Status of this constraint
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this constraint is active
  `created_by` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
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
  `teacher_id` BIGINT UNSIGNED NOT NULL,  -- FK to sch_teachers.id
  `constraint_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tt_constraint.id
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
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `room_id` INT UNSIGNED NOT NULL,  -- FK to sch_rooms.id
  `constraint_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tt_constraint.id
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

-- =========================================================================
--  SECTION 6: TIMETABLE GENERATION & STORAGE
-- =========================================================================

CREATE TABLE IF NOT EXISTS `tt_timetable` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,
  `code` VARCHAR(50) NOT NULL,  -- e.g., 'TT_2025_26_V1','TT_EXAM_OCT_2025'
  `name` VARCHAR(200) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,  -- FK to sch_academic_sessions.id
  `timetable_type_id` BIGINT UNSIGNED NOT NULL,  -- FK to tt_timetable_type.id
  `period_set_id` BIGINT UNSIGNED NOT NULL,  -- FK to tt_period_set.id
  `effective_from` DATE NOT NULL,  -- Start date of this timetable
  `effective_to` DATE DEFAULT NULL,  -- End date of this timetable
  `generation_method` ENUM('MANUAL','SEMI_AUTO','FULL_AUTO') NOT NULL DEFAULT 'MANUAL',  -- How this timetable was generated
  `version` SMALLINT UNSIGNED NOT NULL DEFAULT 1,  -- Version number of this timetable
  `parent_timetable_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tt_timetable.id
  `status` ENUM('DRAFT','GENERATING','GENERATED','PUBLISHED','ARCHIVED') NOT NULL DEFAULT 'DRAFT',  -- Current status of this timetable
  `published_at` TIMESTAMP NULL DEFAULT NULL,  -- When this timetable was published
  `published_by` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
  `constraint_violations` INT UNSIGNED DEFAULT 0,  -- Number of constraint violations in this timetable
  `soft_score` DECIMAL(8,2) DEFAULT NULL,  -- Soft score of this timetable
  `stats_json` JSON DEFAULT NULL,  -- Statistics about this timetable
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this timetable is active
  `created_by` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
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
  `timetable_id` BIGINT UNSIGNED NOT NULL,  -- FK to tt_timetable.id
  `constraint_id` BIGINT UNSIGNED NOT NULL,  -- FK to tt_constraint.id
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

CREATE TABLE IF NOT EXISTS `tt_generation_run` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,
  `timetable_id` BIGINT UNSIGNED NOT NULL,  -- FK to tt_timetable.id
  `run_number` INT UNSIGNED NOT NULL DEFAULT 1,  -- Run number of this generation
  `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,  -- When this generation run started
  `finished_at` TIMESTAMP NULL DEFAULT NULL,  -- When this generation run finished
  `status` ENUM('QUEUED','RUNNING','COMPLETED','FAILED','CANCELLED') NOT NULL DEFAULT 'QUEUED',  -- Status of this generation run
  `algorithm_version` VARCHAR(20) DEFAULT NULL,  -- Version of the algorithm used
  `max_recursion_depth` INT UNSIGNED DEFAULT 14,  -- Maximum recursion depth
  `max_placement_attempts` INT UNSIGNED DEFAULT NULL,  -- Maximum placement attempts
  `params_json` JSON DEFAULT NULL,  -- Parameters used for this generation run
  `activities_total` INT UNSIGNED DEFAULT 0,  -- Total number of activities
  `activities_placed` INT UNSIGNED DEFAULT 0,  -- Number of activities placed
  `activities_failed` INT UNSIGNED DEFAULT 0,  -- Number of activities that failed to be placed
  `hard_violations` INT UNSIGNED DEFAULT 0,  -- Number of hard violations
  `soft_violations` INT UNSIGNED DEFAULT 0,  -- Number of soft violations
  `soft_score` DECIMAL(10,4) DEFAULT NULL,  -- Soft score of this generation run
  `stats_json` JSON DEFAULT NULL,  -- Statistics about this generation run
  `error_message` TEXT DEFAULT NULL,  -- Error message if generation failed
  `triggered_by` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
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
  `timetable_id` BIGINT UNSIGNED NOT NULL,  -- FK to tt_timetable.id
  `generation_run_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tt_generation_run.id
  `day_of_week` TINYINT UNSIGNED NOT NULL,  -- Day of the week
  `period_ord` TINYINT UNSIGNED NOT NULL,  -- Period order
  `cell_date` DATE DEFAULT NULL,  -- Cell date
  `class_group_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sch_class_groups.id
  `class_subgroup_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sch_class_subgroups.id
  `activity_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tt_activity.id
  `sub_activity_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tt_sub_activity.id
  `room_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_rooms.id
  `source` ENUM('AUTO','MANUAL','SWAP','LOCK') NOT NULL DEFAULT 'AUTO',  -- Source of this cell
  `is_locked` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether this cell is locked
  `locked_by` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
  `locked_at` TIMESTAMP NULL DEFAULT NULL,
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
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cell_id` BIGINT UNSIGNED NOT NULL,  -- FK to tt_timetable_cell.id
  `teacher_id` BIGINT UNSIGNED NOT NULL,  -- FK to sch_teachers.id
  `assignment_role_id` BIGINT UNSIGNED NOT NULL,  -- FK to sch_assignment_roles.id
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

-- =========================================================================
--  SECTION 7: SUBSTITUTION MANAGEMENT
-- =========================================================================

CREATE TABLE IF NOT EXISTS `tt_teacher_absence` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `teacher_id` BIGINT UNSIGNED NOT NULL,  -- FK to sch_teachers.id
  `absence_date` DATE NOT NULL,  -- Date of absence
  `absence_type` ENUM('LEAVE','SICK','TRAINING','OFFICIAL_DUTY','OTHER') NOT NULL,  -- Type of absence
  `start_period` TINYINT UNSIGNED DEFAULT NULL,  -- Start period of absence
  `end_period` TINYINT UNSIGNED DEFAULT NULL,  -- End period of absence
  `reason` VARCHAR(500) DEFAULT NULL,  -- Reason for absence
  `status` ENUM('PENDING','APPROVED','REJECTED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  `approved_by` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
  `approved_at` TIMESTAMP NULL DEFAULT NULL,  -- Date and time when absence was approved
  `substitution_required` TINYINT(1) DEFAULT 1,  -- Whether substitution is required
  `substitution_completed` TINYINT(1) DEFAULT 0,  -- Whether substitution has been completed
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether this absence is active
  `created_by` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
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
  `teacher_absence_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tt_teacher_absence.id
  `cell_id` BIGINT UNSIGNED NOT NULL,  -- FK to tt_timetable_cell.id
  `substitution_date` DATE NOT NULL,  -- Date of substitution
  `absent_teacher_id` BIGINT UNSIGNED NOT NULL,  -- FK to sch_teachers.id
  `substitute_teacher_id` BIGINT UNSIGNED NOT NULL,  -- FK to sch_teachers.id
  `assignment_method` ENUM('AUTO','MANUAL','SWAP') NOT NULL DEFAULT 'MANUAL',  -- Method of assignment
  `reason` VARCHAR(500) DEFAULT NULL,  -- Reason for substitution
  `status` ENUM('ASSIGNED','COMPLETED','CANCELLED') NOT NULL DEFAULT 'ASSIGNED',  -- Status of substitution
  `notified_at` TIMESTAMP NULL DEFAULT NULL,  -- Date and time when substitution was notified
  `accepted_at` TIMESTAMP NULL DEFAULT NULL,  -- Date and time when substitution was accepted
  `completed_at` TIMESTAMP NULL DEFAULT NULL,  -- Date and time when substitution was completed
  `feedback` TEXT DEFAULT NULL,  -- Feedback for the substitution
  `assigned_by` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
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

-- =========================================================================
--  SECTION 8: TEACHER WORKLOAD & ANALYTICS
-- =========================================================================

CREATE TABLE IF NOT EXISTS `tt_teacher_workload` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `teacher_id` BIGINT UNSIGNED NOT NULL,  -- FK to sch_teachers.id
  `academic_session_id` BIGINT UNSIGNED NOT NULL,  -- FK to sch_academic_sessions.id
  `timetable_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tt_timetable.id
  `weekly_periods_assigned` SMALLINT UNSIGNED DEFAULT 0,  -- Number of periods assigned
  `weekly_periods_max` SMALLINT UNSIGNED DEFAULT NULL,  -- Maximum number of periods allowed
  `weekly_periods_min` SMALLINT UNSIGNED DEFAULT NULL,  -- Minimum number of periods allowed
  `daily_distribution_json` JSON DEFAULT NULL,  -- Daily distribution of periods
  `subjects_assigned_json` JSON DEFAULT NULL,  -- Subjects assigned to the teacher
  `classes_assigned_json` JSON DEFAULT NULL,  -- Classes assigned to the teacher
  `utilization_percent` DECIMAL(5,2) DEFAULT NULL,  -- Utilization percentage
  `gap_periods_total` SMALLINT UNSIGNED DEFAULT 0,  -- Total gap periods
  `consecutive_max` TINYINT UNSIGNED DEFAULT 0,  -- Maximum consecutive periods
  `last_calculated_at` TIMESTAMP NULL DEFAULT NULL,
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

-- =========================================================================
--  SECTION 9: AUDIT & HISTORY
-- =========================================================================

CREATE TABLE IF NOT EXISTS `tt_change_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `timetable_id` BIGINT UNSIGNED NOT NULL,  -- FK to tt_timetable.id
  `cell_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tt_timetable_cell.id
  `change_type` ENUM('CREATE','UPDATE','DELETE','LOCK','UNLOCK','SWAP','SUBSTITUTE') NOT NULL,
  `change_date` DATE NOT NULL,  -- Date of change
  `old_values_json` JSON DEFAULT NULL,  -- Old values of the cell
  `new_values_json` JSON DEFAULT NULL,  -- New values of the cell
  `reason` VARCHAR(500) DEFAULT NULL,  -- Reason for the change
  `changed_by` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
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

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- END OF TIMETABLE MODULE - VERSION 6.0 (29 Tables)
-- =====================================================================
-- S0: tt_shift, tt_day_type, tt_school_days, tt_working_day, tt_period_type, tt_teacher_assignment_role
-- S1: tt_period_set, tt_period_set_period_jnt
-- S2: tt_timetable_type
-- S3: tt_class_mode_rule, tt_class_subgroup, tt_class_group_requirement, tt_class_subgroup_member
-- S4: tt_activity, tt_activity_teacher, tt_sub_activity
-- S5: tt_constraint_type, tt_constraint, tt_teacher_unavailable, tt_room_unavailable
-- S6: tt_timetable, tt_constraint_violation, tt_generation_run, tt_timetable_cell, tt_timetable_cell_teacher
-- S7: tt_teacher_absence, tt_substitution_log | S8: tt_teacher_workload | S9: tt_change_log
-- =====================================================================
--
-- List of Tables
-- --------------------------
-- SCREEN - 1 (General Settings)
-- -----------------------------
-- Group-1: General Settings
-- tt_shift
-- tt_day_type
-- tt_period_type
-- tt_teacher_assignment_role
-- tt_school_days
-- tt_working_day

-- SCREEN - 2 (Structure & Planning)
-- ---------------------------------
-- Group-2: Structure & Planning
-- tt_period_set
-- tt_period_set_period_jnt
-- tt_timetable_type
-- tt_class_mode_rule

-- Group-3: Student Grouping & Requirements
-- tt_class_subgroup
-- tt_class_subgroup_member
-- tt_class_group_requirement

-- SCREEN - 3 (Activities & Constraints)
-- -------------------------------------
-- Group-4: Activities & Constraints (Activity Management)
-- tt_activity
-- tt_activity_teacher
-- tt_sub_activity

-- Group-5: Constraint Management (Constraint Engine)
-- tt_constraint_type
-- tt_constraint
-- tt_teacher_unavailable
-- tt_room_unavailable

-- SCREEN - 4 (Timetable Generation)
-- ---------------------------------
-- Group-6: Timetable Generation
-- tt_timetable
-- tt_constraint_violation
-- tt_generation_run
-- tt_timetable_cell
-- tt_timetable_cell_teacher

-- SCREEN - 5 (Substitution Mgmt & Audit)
-- --------------------------------------
-- Group-7: Substitution Management
-- tt_teacher_absence
-- tt_substitution_log

-- Group-8: Analytics & Audit (Read-Only Views)
-- tt_teacher_workload
-- tt_change_log

-- --------------------------
-- Table Summary by Section:
-- Section	Tables
-- S0 Master Config (tt_shift, tt_day_type, tt_school_days, tt_working_day, tt_period_type, tt_teacher_assignment_role)
-- S1 Period Sets (tt_period_set, tt_period_set_period_jnt)
-- S2 Timetable Type (tt_timetable_type)
-- S3 Class Grouping (tt_class_mode_rule, tt_class_subgroup, tt_class_group_requirement, tt_class_subgroup_member)
-- S4 Activities (tt_activity, tt_activity_teacher, tt_sub_activity)
-- S5 Constraints (tt_constraint_type, tt_constraint, tt_teacher_unavailable, tt_room_unavailable)
-- S6 Timetable Storage (tt_timetable, tt_constraint_violation, tt_generation_run, tt_timetable_cell, tt_timetable_cell_teacher)
-- S7 Substitution (tt_teacher_absence, tt_substitution_log)
-- S8 Workload (tt_teacher_workload)
-- S9 Audit (tt_change_log)
-- ----------------------------




