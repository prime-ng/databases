-- =====================================================================
-- TIMETABLE MODULE - VERSION 3.0 (PRODUCTION-GRADE)
-- =====================================================================
-- Target: MySQL 8.x | Stack: PHP + Laravel
-- Architecture: Multi-tenant, Constraint-based Auto-Scheduling
-- =====================================================================
-- TABLE PREFIX: tt - Timetable Module
-- =====================================================================
-- FEATURES:
--   ✓ FET-like constraint-based timetable generation
--   ✓ Multi-shift support (Morning, Afternoon, Block, Terms)
--   ✓ Configurable period sets per class/mode
--   ✓ Teacher workload management & substitution workflow
--   ✓ Room & Building allocation with capacity constraints
--   ✓ Hard & Soft constraints engine (Time + Space)
--   ✓ Manual, Semi-automatic & Automatic generation modes
--   ✓ Activity grouping & sub-activities
--   ✓ Academic session linkage
--   ✓ Audit logging & version history
-- =====================================================================
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
-- =========================================================================
--  SECTION 0: TABLES EXISTS IN OLD SCHEMA (REMOVED IN V3.0)
-- =========================================================================
-- NOTE: The following tables were evaluated and deemed redundant:
--   - tt_days → Functionality covered by tt_working_day (Section 1.4)
--   - tt_periods → Functionality covered by tt_period_set_period_jnt (Section 2.2)
--   - tt_timing_profile → Functionality covered by tt_period_set + tt_class_mode_rule
--   - tt_room_unavailable (draft) → Production version in Section 5.4
-- =========================================================================
-- NOTE: The following tables were evaluated and deemed redundant:
--   - tt_days → Functionality covered by tt_working_day (Section 1.4)
--   - tt_periods → Functionality covered by tt_period_set_period_jnt (Section 2.2)
--   - tt_timing_profile → Functionality covered by tt_period_set + tt_class_mode_rule
--   - tt_room_unavailable (draft) → Production version in Section 5.4
-- =========================================================================
-- =========================================================================
--  SECTION 0: MASTER CONFIGURATION TABLES
-- =========================================================================
CREATE TABLE IF NOT EXISTS `sch_shift` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(20) NOT NULL,
  -- e.g., 'MORNING','AFTERNOON','BLOCK','TERM','GROUP'
  `name` VARCHAR(100) NOT NULL,
  -- e.g., 'Morning','Afternoon','Block','Term','Group'
  `effective_from` DATE NOT NULL,
  -- e.g., '2025-01-01'
  `effective_to` DATE NOT NULL,
  -- e.g., '2025-12-31'
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_shift_code` (`code`),
  UNIQUE KEY `uq_shift_name` (`name`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- -----------------------------------------------------
-- Defines modes: Regular, Exam, Special Event, Half Day, etc.
-- -----------------------------------------------------
-- CREATE TABLE IF NOT EXISTS `tt_timetable_mode` (
--   `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
--   `code` VARCHAR(30) NOT NULL,                    -- e.g., 'REGULAR','EXAM','HALF_DAY','SPECIAL_EVENT'
--   `name` VARCHAR(100) NOT NULL,                   -- e.g., 'Regular Timetable','Examination Mode'
--   `description` VARCHAR(255) DEFAULT NULL,
--   `mode_type` ENUM('SINGLE_SHIFT','TWO_SHIFT','BLOCK','TERM','GROUP') NOT NULL DEFAULT 'SINGLE_SHIFT',
--   `has_exam` TINYINT(1) NOT NULL DEFAULT 0,       -- Whether this mode includes exam periods
--   `has_teaching` TINYINT(1) NOT NULL DEFAULT 1,   -- Whether this mode includes teaching periods
--   `default_period_set_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tt_period_set
--   `ordinal` SMALLINT UNSIGNED DEFAULT 1,          -- Order of appearance
--   `is_system` TINYINT(1) DEFAULT 1,               -- System-defined vs school-defined
--   `is_active` TINYINT(1) NOT NULL DEFAULT 1,
--   `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
--   `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
--   `deleted_at` TIMESTAMP NULL DEFAULT NULL,
--   UNIQUE KEY `uq_ttmode_code` (`code`),
--   KEY `idx_ttmode_type` (`mode_type`),
--   CONSTRAINT `fk_ttmode_default_period_set` FOREIGN KEY (`default_period_set_id`) REFERENCES `tt_period_set` (`id`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- -----------------------------------------------------
-- Defines school working days with shifts
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_working_day` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `shift_id` BIGINT UNSIGNED NOT NULL,
  -- FK to sch_shift
  `code` VARCHAR(10) NOT NULL,
  -- e.g., 'MON','TUE','WED','THU','FRI','SAT','SUN'
  `name` VARCHAR(20) NOT NULL,
  -- e.g., 'Monday','Tuesday'
  `short_name` VARCHAR(5) NOT NULL,
  -- e.g., 'Mon','Tue'
  `day_of_week` TINYINT UNSIGNED NOT NULL,
  -- 1=Monday, 2=Tuesday, ..., 7=Sunday (ISO 8601)
  `ordinal` SMALLINT UNSIGNED NOT NULL,
  -- Display order
  `is_school_day` TINYINT(1) NOT NULL DEFAULT 1,
  -- Is this a regular school day?
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_workday_shift_code` (`shift_id`, `code`),
  UNIQUE KEY `uq_workday_shift_dow` (`shift_id`, `day_of_week`),
  KEY `idx_workday_ordinal` (`shift_id`, `ordinal`),
  CONSTRAINT `fk_workday_shift` FOREIGN KEY (`shift_id`) REFERENCES `sch_shift` (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- -----------------------------------------------------
-- Categorizes periods: Teaching, Break, Assembly, Exam, etc.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_period_type` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `code` VARCHAR(30) NOT NULL,
  -- e.g., 'TEACHING','BREAK','LUNCH','ASSEMBLY','EXAM','RECESS'
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `color_code` VARCHAR(10) DEFAULT NULL,
  -- For UI display e.g., '#4CAF50'
  `icon` VARCHAR(50) DEFAULT NULL,
  -- Icon identifier
  `is_schedulable` TINYINT(1) NOT NULL DEFAULT 1,
  -- Can activities be scheduled in this period?
  `counts_as_teaching` TINYINT(1) NOT NULL DEFAULT 0,
  `counts_as_workload` TINYINT(1) NOT NULL DEFAULT 0,
  `is_break` TINYINT(1) NOT NULL DEFAULT 0,
  -- Is this a break period?
  `ordinal` SMALLINT UNSIGNED DEFAULT 1,
  `is_system` TINYINT(1) DEFAULT 1,
  -- System-defined vs school-defined
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_periodtype_code` (`code`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- -----------------------------------------------------
-- Defines roles: Primary, Assistant, Co-Teacher, Substitute, etc.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_teacher_assignment_role` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `code` VARCHAR(30) NOT NULL,
  -- e.g., 'PRIMARY','ASSISTANT','CO_TEACHER','SUBSTITUTE','TRAINEE'
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `is_primary_instructor` TINYINT(1) NOT NULL DEFAULT 0,
  -- Is this the main instructor role?
  `counts_for_workload` TINYINT(1) NOT NULL DEFAULT 1,
  `allows_overlap` TINYINT(1) NOT NULL DEFAULT 0,
  -- Can teacher have other assignments at same time?
  `workload_factor` DECIMAL(3, 2) DEFAULT 1.00,
  -- Workload multiplier (0.5 for assistant, 1.0 for primary)
  `ordinal` SMALLINT UNSIGNED DEFAULT 1,
  `is_system` TINYINT(1) DEFAULT 1,
  -- System-defined vs school-defined
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_tarole_code` (`code`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- -----------------------------------------------------
-- SECTION 1: SCHOOL TIMING PROFILE
-- Manages seasonal/term-based timing configurations (Summer, Winter, Exam, Half-Yearly, etc.)
-- Links to period sets to determine which timing schedule applies when
-- Example: Summer Profile (Apr-Jun) -> Early start (7:30 AM), Winter Profile (Nov-Feb) -> Late start (8:00 AM)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_school_timing_profile` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `code` VARCHAR(30) NOT NULL,
  -- e.g., 'SUMMER_STD','WINTER_STD','EXAM_MODE','HALF_DAY'
  `profile_name` VARCHAR(100) NOT NULL,
  -- e.g., 'Summer Standard Schedule', 'Winter Regular Schedule'
  `short_name` VARCHAR(20) NULL,
  -- e.g., 'SUMMER','WINTER','EXAM'
  `description` VARCHAR(500) NULL,
  -- Linked Period Set (default periods for this profile)
  `default_period_set_id` BIGINT UNSIGNED DEFAULT NULL,
  -- FK to tt_period_set (This includes which all classes it will apply to)
  -- Validity Period
  `effective_from_date` DATE DEFAULT NULL,
  -- Explicit start date (overrides month)
  `effective_to_date` DATE DEFAULT NULL,
  -- Explicit end date (overrides month)
  -- Timing Adjustments
  `school_start_time` TIME DEFAULT NULL,
  -- Default school start time e.g., '07:30:00'
  `school_end_time` TIME DEFAULT NULL,
  -- Default school end time e.g., '13:30:00'
  `assembly_duration_min` SMALLINT UNSIGNED DEFAULT NULL,
  -- Assembly duration in minutes
  `short_break_duration_min` SMALLINT UNSIGNED DEFAULT NULL,
  -- Default break duration 
  `lunch_duration_min` SMALLINT UNSIGNED DEFAULT NULL,
  -- Lunch duration
  -- Profile Type
  `profile_type` ENUM('REGULAR', 'SEASONAL', 'EXAM', 'SPECIAL', 'ACTIVITY') NOT NULL DEFAULT 'REGULAR',
  `has_exam` TINYINT(1) NOT NULL DEFAULT 0,
  -- Whether this mode includes exam periods
  `has_teaching` TINYINT(1) NOT NULL DEFAULT 1,
  -- Whether this mode includes teaching periods
  `applies_to_class_ids` JSON DEFAULT NULL,
  -- Array of class IDs this profile applies to (NULL = all)
  -- Status & Audit
  `ordinal` SMALLINT UNSIGNED DEFAULT 1,
  -- Display order
  `is_default` TINYINT(1) DEFAULT 0,
  -- Is this the default profile for the school?
  `is_system` TINYINT(1) DEFAULT 0,
  -- System-defined vs school-defined
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_stp_code` (`code`),
  UNIQUE KEY `uq_stp_profile_name` (`profile_name`),
  UNIQUE KEY `uq_stp_short_name` (`short_name`),
  KEY `idx_stp_type` (`profile_type`),
  KEY `idx_stp_effective` (`effective_from_date`, `effective_to_date`),
  KEY `idx_stp_active_deleted` (`is_active`, `deleted_at`),
  CONSTRAINT `fk_stp_period_set` FOREIGN KEY (`default_period_set_id`) REFERENCES `tt_period_set` (`id`) ON DELETE
  SET NULL,
    CONSTRAINT `fk_stp_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE
  SET NULL,
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- Usage Examples:
-- 1. Summer Schedule: code='SUMMER_STD', effective_from_date='2025-04-01', effective_to_date='2025-06-30', school_start_time='07:30:00'
-- 2. Winter Schedule: code='WINTER_STD', effective_from_date='2025-11-01', effective_to_date='2025-02-28', school_start_time='08:00:00'
-- 3. Exam Mode: code='EXAM_MODE', effective_from_date='2025-03-01', effective_to_date='2025-03-15'
-- =========================================================================
--  SECTION 2: PERIOD SET CONFIGURATION
-- =========================================================================
-- -----------------------------------------------------
-- Defines collections of periods: Normal Day, Exam Day, Half Day, etc.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_period_set` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `code` VARCHAR(30) NOT NULL,
  -- e.g., '3rd-12th_NORMAL_8P','4th-12th_EXAM_3P','5th-12th_HALF_DAY_4P','BV1-2nd_TODDLER_6P'
  `name` VARCHAR(100) NOT NULL,
  -- e.g., '3rd-12th Normal Day - 8 Periods'
  `description` VARCHAR(255) DEFAULT NULL,
  `total_periods` TINYINT UNSIGNED NOT NULL,
  -- Total number of periods
  `teaching_periods` TINYINT UNSIGNED NOT NULL,
  -- Number of teaching periods
  `start_time` TIME NOT NULL,
  -- Day start time e.g., '08:00:00'
  `end_time` TIME NOT NULL,
  -- Day end time e.g., '14:30:00'
  `applicable_class_ids` JSON DEFAULT NULL,
  -- Array of class IDs this set applies to
  `is_default` TINYINT(1) DEFAULT 0,
  -- Default period set for the school
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_periodset_code` (`code`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- condition:
-- FK for applicable_class_ids will be managed at application level
-- -----------------------------------------------------
-- Defines the structure of a period set with its periods
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_period_set_period_jnt` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `period_set_id` BIGINT UNSIGNED NOT NULL,
  -- FK to tt_period_set
  `period_type_id` BIGINT UNSIGNED NOT NULL,
  -- FK to tt_period_type
  `period_ord` TINYINT UNSIGNED NOT NULL,
  -- Ordinal within set (1, 2, 3...)
  `code` VARCHAR(20) NOT NULL,
  -- e.g., 'P1','P2','BREAK1','LUNCH'
  `name` VARCHAR(50) NOT NULL,
  -- e.g., 'Period 1','Short Break'
  `short_name` VARCHAR(10) DEFAULT NULL,
  -- e.g., 'P1','BR'
  `start_time` TIME NOT NULL,
  -- e.g., '08:00:00'
  `end_time` TIME NOT NULL,
  -- e.g., '08:45:00'
  `duration_minutes` SMALLINT UNSIGNED GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, start_time, end_time)) STORED,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_psp_set_ord` (`period_set_id`, `period_ord`),
  UNIQUE KEY `uq_psp_set_code` (`period_set_id`, `code`),
  KEY `idx_psp_type` (`period_type_id`),
  CONSTRAINT `fk_psp_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_set` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_psp_period_type` FOREIGN KEY (`period_type_id`) REFERENCES `tt_period_type` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `chk_psp_time` CHECK (`end_time` > `start_time`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- =========================================================================
--  SECTION 3: CLASS & STUDENT GROUPING FOR TIMETABLE
-- =========================================================================
-- -----------------------------------------------------
-- Links classes to timetable modes with specific period sets
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_class_mode_rule` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `class_id` INT UNSIGNED NOT NULL,
  -- FK to sch_classes. e.g., '1ST', '2ND', '3RD', '4TH', '5TH', '6TH', '7TH' etc.
  `timetable_mode_id` BIGINT UNSIGNED NOT NULL,
  -- FK to tt_timetable_mode. e.g., 'REGULAR','EXAM','HALF_DAY'
  `period_set_id` BIGINT UNSIGNED NOT NULL,
  -- FK to tt_period_set. e.g., 'NORMAL_8P','EXAM_3P','HALF_DAY_4P','TODDLER_6P'
  `academic_session_id` BIGINT UNSIGNED DEFAULT NULL,
  -- FK to sch_org_academic_sessions_jnt. e.g., '2024-2025', '2025-2026', etc.
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
  UNIQUE KEY `uq_cmr_class_mode_session` (
    `class_id`,
    `timetable_mode_id`,
    `academic_session_id`
  ),
  KEY `idx_cmr_mode` (`timetable_mode_id`),
  CONSTRAINT `fk_cmr_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cmr_mode` FOREIGN KEY (`timetable_mode_id`) REFERENCES `tt_timetable_mode` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_cmr_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_set` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_cmr_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE
  SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- -----------------------------------------------------
-- Defines weekly period requirements for class groups (Subject+StudyFormat combinations)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_class_group_requirement` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `class_group_id` BIGINT UNSIGNED NOT NULL,
  -- FK to sch_class_groups_jnt e.g. '9th_A_SCI_LAC_MAJ' OR '8th_A_MAT_LAC_OPT'
  `academic_session_id` BIGINT UNSIGNED DEFAULT NULL,
  -- FK to sch_org_academic_sessions_jnt e.g. '2024-2025', '2025-2026', etc.
  `weekly_periods` TINYINT UNSIGNED NOT NULL,
  -- Total periods per week
  `min_periods_per_week` TINYINT UNSIGNED DEFAULT NULL,
  `max_periods_per_week` TINYINT UNSIGNED DEFAULT NULL,
  `max_per_day` TINYINT UNSIGNED DEFAULT NULL,
  -- Max periods per day for this group
  `min_per_day` TINYINT UNSIGNED DEFAULT NULL,
  -- Min periods per day for this group
  `min_gap_periods` TINYINT UNSIGNED DEFAULT NULL,
  -- Min gap between sessions same day
  `allow_consecutive` TINYINT(1) NOT NULL DEFAULT 0,
  -- Allow consecutive periods
  `max_consecutive` TINYINT UNSIGNED DEFAULT 2,
  -- Max consecutive periods allowed
  `preferred_periods_json` JSON DEFAULT NULL,
  -- Preferred period slots e.g., [1,2,3]
  `avoid_periods_json` JSON DEFAULT NULL,
  -- Avoid these period slots
  `spread_evenly` TINYINT(1) DEFAULT 1,
  -- Spread across week
  `priority` SMALLINT UNSIGNED DEFAULT 50,
  -- Scheduling priority (higher = more important)
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_cgr_group_session` (`class_group_id`, `academic_session_id`),
  CONSTRAINT `fk_cgr_class_group` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cgr_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE
  SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- condition:
-- class_group_id - (sch_class_groups_jnt.code) is a Combination of (Class+Section+Subject+StudyFormat+SubjType) e.g., '10h_A_SCI_LAC_MAJ','8th_MAT_LAC_OPT'
-- -----------------------------------------------------
-- (For parallel/optional subjects) Handles scenarios like: Hobby groups, Optional subjects, Skill subjects
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_class_subgroup` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `code` VARCHAR(50) NOT NULL,
  -- e.g., '10TH_FRENCH_OPT','8TH_HOBBY_GRP', 8th-12th_CRICKET, 8th-12th_FOOTBALL
  `name` VARCHAR(150) NOT NULL,
  -- e.g., 'French(Optional) 10th Class(All Sections)'
  `description` VARCHAR(255) DEFAULT NULL,
  `class_group_id` BIGINT UNSIGNED DEFAULT NULL,
  -- FK to sch_class_groups_jnt (optional)
  `subgroup_type` ENUM(
    'OPTIONAL_SUBJECT',
    'HOBBY',
    'SKILL',
    'LANGUAGE',
    'STREAM',
    'ACTIVITY',
    'OTHER'
  ) NOT NULL DEFAULT 'OTHER',
  `runs_parallel` TINYINT(1) DEFAULT 0,
  -- Do all sections run this in parallel?
  `student_count` INT UNSIGNED DEFAULT NULL,
  -- Total students enrolled
  `min_students` INT UNSIGNED DEFAULT NULL,
  -- Min students required
  `max_students` INT UNSIGNED DEFAULT NULL,
  -- Max students allowed
  `is_shared_across_classes` TINYINT(1) NOT NULL DEFAULT 0,
  -- Is this subgroup shared across classes?
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_subgroup_code` (`code`),
  KEY `idx_subgroup_type` (`subgroup_type`),
  CONSTRAINT `fk_subgroup_class_group` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE
  SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- condition:
-- class_group_id - (sch_class_groups_jnt.code) is a Combination of (Class+Section+Subject+StudyFormat+SubjType) e.g., '10h_A_SCI_LAC_MAJ','8th_MAT_LAC_OPT'
-- -----------------------------------------------------
-- Links specific class+sections to subgroups
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_class_subgroup_member` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `class_subgroup_id` BIGINT UNSIGNED NOT NULL,
  -- FK to tt_class_subgroup
  `class_id` INT UNSIGNED NOT NULL,
  -- FK to sch_classes
  `section_id` INT UNSIGNED DEFAULT NULL,
  -- FK to sch_sections (NULL = all sections)
  `is_primary` TINYINT(1) DEFAULT 0,
  -- Primary Class+Section for reporting
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_csm_subgroup_class_section` (`class_subgroup_id`, `class_id`, `section_id`),
  CONSTRAINT `fk_csm_subgroup` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroup` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_csm_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_csm_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- =========================================================================
--  SECTION 4: ACTIVITY MANAGEMENT (FET-Style)
-- =========================================================================
-- -----------------------------------------------------
-- (Core schedulable unit) An activity represents a subject-teacher-class combination that needs scheduling
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_activity` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,
  `code` VARCHAR(50) NOT NULL,
  -- e.g., 'ACT_10A_MTH_LAC_001'
  `name` VARCHAR(200) NOT NULL,
  -- e.g., 'Mathematics Lecture - Class 10A'
  `description` VARCHAR(500) DEFAULT NULL,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  -- FK to sch_org_academic_sessions_jnt
  -- Target (one of class_group_id or class_subgroup_id must be set)
  `class_group_id` BIGINT UNSIGNED DEFAULT NULL,
  -- FK to sch_class_groups_jnt
  `class_subgroup_id` BIGINT UNSIGNED DEFAULT NULL,
  -- FK to tt_class_subgroup
  -- Subject & Study Format (denormalized for fast access)
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  -- FK to sch_subjects
  `study_format_id` INT UNSIGNED DEFAULT NULL,
  -- FK to sch_study_formats
  -- Duration
  `duration_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  -- Number of consecutive periods
  `weekly_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  -- Times per week
  `total_periods` SMALLINT UNSIGNED GENERATED ALWAYS AS (`duration_periods` * `weekly_periods`) STORED,
  -- Scheduling preferences
  `split_allowed` TINYINT(1) DEFAULT 0,
  -- Can be split across non-consecutive slots?
  `is_compulsory` TINYINT(1) DEFAULT 1,
  -- Must be scheduled?
  `priority` SMALLINT UNSIGNED DEFAULT 50,
  -- Scheduling priority (0-100)
  `difficulty_score` SMALLINT UNSIGNED DEFAULT 50,
  -- For algorithm sorting (higher = harder to schedule)
  -- Room requirements
  `requires_room` TINYINT(1) DEFAULT 1,
  `preferred_room_type_id` INT UNSIGNED DEFAULT NULL,
  -- FK to sch_rooms_type
  `preferred_room_ids` JSON DEFAULT NULL,
  -- Array of preferred room IDs
  -- Status
  `status` ENUM('DRAFT', 'ACTIVE', 'LOCKED', 'ARCHIVED') NOT NULL DEFAULT 'ACTIVE',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
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
  CONSTRAINT `fk_activity_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE
  SET NULL,
    CONSTRAINT `fk_activity_study_format` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE
  SET NULL,
    CONSTRAINT `fk_activity_room_type` FOREIGN KEY (`preferred_room_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE
  SET NULL,
    CONSTRAINT `fk_activity_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE
  SET NULL,
    -- Must have either class_group or subgroup
    CONSTRAINT `chk_activity_target` CHECK (
      (
        `class_group_id` IS NOT NULL
        AND `class_subgroup_id` IS NULL
      )
      OR (
        `class_group_id` IS NULL
        AND `class_subgroup_id` IS NOT NULL
      )
    )
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- -----------------------------------------------------
-- (Many-to-Many: Activity <-> Teachers) Supports multiple teachers per activity (e.g., Lab with assistant)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_activity_teacher` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `activity_id` BIGINT UNSIGNED NOT NULL,
  -- FK to tt_activity
  `teacher_id` BIGINT UNSIGNED NOT NULL,
  -- FK to sch_teachers
  `assignment_role_id` BIGINT UNSIGNED NOT NULL,
  -- FK to tt_teacher_assignment_role
  `is_required` TINYINT(1) DEFAULT 1,
  -- Is this teacher required for the activity?
  `ordinal` TINYINT UNSIGNED DEFAULT 1,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_at_activity_teacher` (`activity_id`, `teacher_id`),
  KEY `idx_at_teacher` (`teacher_id`),
  CONSTRAINT `fk_at_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_at_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_at_role` FOREIGN KEY (`assignment_role_id`) REFERENCES `tt_teacher_assignment_role` (`id`) ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- -----------------------------------------------------
-- (Splits of a main activity) For activities that span multiple slots or need special handling
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_sub_activity` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `parent_activity_id` BIGINT UNSIGNED NOT NULL,
  -- FK to tt_activity
  `sub_activity_ord` TINYINT UNSIGNED NOT NULL,
  -- 1, 2, 3...
  `code` VARCHAR(60) NOT NULL,
  -- e.g., 'ACT_10A_MTH_LAC_001_S1'
  `duration_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `same_day_as_parent` TINYINT(1) DEFAULT 0,
  -- Must be on same day as parent?
  `consecutive_with_previous` TINYINT(1) DEFAULT 0,
  -- Must be consecutive with previous?
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_subact_parent_ord` (`parent_activity_id`, `sub_activity_ord`),
  UNIQUE KEY `uq_subact_code` (`code`),
  CONSTRAINT `fk_subact_parent` FOREIGN KEY (`parent_activity_id`) REFERENCES `tt_activity` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- =========================================================================
--  SECTION 5: CONSTRAINT ENGINE (FET-Style)
-- =========================================================================
-- -----------------------------------------------------
-- Defines all available constraint types
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_constraint_type` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `code` VARCHAR(60) NOT NULL,
  -- e.g., 'TEACHER_NOT_AVAILABLE','MIN_DAYS_BETWEEN','SAME_STARTING_TIME'
  `name` VARCHAR(150) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `category` ENUM(
    'TIME',
    'SPACE',
    'TEACHER',
    'STUDENT',
    'ACTIVITY',
    'ROOM'
  ) NOT NULL,
  -- Category of the constraint
  `scope` ENUM(
    'GLOBAL',
    'TEACHER',
    'STUDENT',
    'ROOM',
    'ACTIVITY',
    'CLASS'
  ) NOT NULL,
  -- Scope of the constraint
  `default_weight` TINYINT UNSIGNED DEFAULT 100,
  -- Default weight percentage (0-100)
  `is_hard_capable` TINYINT(1) DEFAULT 1,
  -- Can this be a hard constraint?
  `param_schema` JSON DEFAULT NULL,
  -- JSON schema for parameters
  `is_system` TINYINT(1) DEFAULT 1,
  -- Is this a system constraint?
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_ctype_code` (`code`),
  KEY `idx_ctype_category` (`category`),
  KEY `idx_ctype_scope` (`scope`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- -----------------------------------------------------
-- Actual constraint definitions applied to the timetable
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_constraint` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,
  `constraint_type_id` BIGINT UNSIGNED NOT NULL,
  -- FK to tt_constraint_type
  `name` VARCHAR(200) DEFAULT NULL,
  -- Custom name for this constraint
  `description` VARCHAR(500) DEFAULT NULL,
  `academic_session_id` BIGINT UNSIGNED DEFAULT NULL,
  -- Target (polymorphic - one should be set based on constraint scope)
  `target_type` ENUM(
    'GLOBAL',
    'TEACHER',
    'STUDENT_SET',
    'ROOM',
    'ACTIVITY',
    'CLASS',
    'SUBJECT',
    'STUDY_FORMAT'
  ) NOT NULL,
  `target_id` BIGINT UNSIGNED DEFAULT NULL,
  -- ID of the target entity (NULL for GLOBAL)
  -- Constraint parameters
  `is_hard` TINYINT(1) NOT NULL DEFAULT 0,
  -- Hard constraint (must be satisfied)?
  `weight` TINYINT UNSIGNED NOT NULL DEFAULT 100,
  -- Weight percentage (0-100, 100=mandatory)
  `params_json` JSON NOT NULL,
  -- Constraint-specific parameters
  -- Temporal scope
  `effective_from` DATE DEFAULT NULL,
  `effective_to` DATE DEFAULT NULL,
  `applies_to_days_json` JSON DEFAULT NULL,
  -- e.g., [1,2,3,4,5] for Mon-Fri
  -- Status
  `status` ENUM('DRAFT', 'ACTIVE', 'DISABLED') NOT NULL DEFAULT 'ACTIVE',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_constraint_uuid` (`uuid`),
  KEY `idx_constraint_type` (`constraint_type_id`),
  KEY `idx_constraint_target` (`target_type`, `target_id`),
  KEY `idx_constraint_session` (`academic_session_id`),
  KEY `idx_constraint_status` (`status`),
  CONSTRAINT `fk_constraint_type` FOREIGN KEY (`constraint_type_id`) REFERENCES `tt_constraint_type` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_constraint_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE
  SET NULL,
    CONSTRAINT `fk_constraint_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE
  SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- -----------------------------------------------------
-- Quick lookup table for teacher unavailability (derived from constraints)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_teacher_unavailable` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `teacher_id` BIGINT UNSIGNED NOT NULL,
  -- FK to sch_teachers
  `constraint_id` BIGINT UNSIGNED DEFAULT NULL,
  -- FK to tt_constraint (source)
  `day_of_week` TINYINT UNSIGNED NOT NULL,
  -- 1-7 (ISO 8601)
  `period_ord` TINYINT UNSIGNED DEFAULT NULL,
  -- NULL = entire day
  `start_date` DATE DEFAULT NULL,
  -- For date-specific unavailability
  `end_date` DATE DEFAULT NULL,
  `reason` VARCHAR(255) DEFAULT NULL,
  `is_recurring` TINYINT(1) DEFAULT 1,
  -- Repeats every week?
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `idx_tu_teacher` (`teacher_id`),
  KEY `idx_tu_day_period` (`day_of_week`, `period_ord`),
  CONSTRAINT `fk_tu_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tu_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraint` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- -----------------------------------------------------
-- Quick lookup table for room unavailability (derived from constraints)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_room_unavailable` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `room_id` INT UNSIGNED NOT NULL,
  -- FK to sch_rooms
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
  KEY `idx_ru_room` (`room_id`),
  KEY `idx_ru_day_period` (`day_of_week`, `period_ord`),
  CONSTRAINT `fk_ru_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ru_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraint` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- =========================================================================
--  SECTION 6: TIMETABLE GENERATION & STORAGE
-- =========================================================================
-- -----------------------------------------------------
-- TIMETABLE (Version/Snapshot of generated timetable)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_timetable` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,
  `code` VARCHAR(50) NOT NULL,
  -- e.g., 'TT_2025_26_V1','TT_EXAM_OCT_2025'
  `name` VARCHAR(200) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  `timetable_mode_id` BIGINT UNSIGNED NOT NULL,
  -- FK to tt_timetable_mode
  `period_set_id` BIGINT UNSIGNED NOT NULL,
  -- FK to tt_period_set
  -- Validity period
  `effective_from` DATE NOT NULL,
  `effective_to` DATE DEFAULT NULL,
  -- Generation metadata
  `generation_method` ENUM('MANUAL', 'SEMI_AUTO', 'FULL_AUTO') NOT NULL DEFAULT 'MANUAL',
  `version` INT UNSIGNED NOT NULL DEFAULT 1,
  `parent_timetable_id` BIGINT UNSIGNED DEFAULT NULL,
  -- Previous version
  -- Status
  `status` ENUM(
    'DRAFT',
    'GENERATING',
    'GENERATED',
    'PUBLISHED',
    'ARCHIVED'
  ) NOT NULL DEFAULT 'DRAFT',
  `published_at` TIMESTAMP NULL DEFAULT NULL,
  `published_by` BIGINT UNSIGNED DEFAULT NULL,
  -- Quality metrics
  `constraint_violations` INT UNSIGNED DEFAULT 0,
  `soft_score` DECIMAL(8, 2) DEFAULT NULL,
  -- Quality score from algorithm
  `stats_json` JSON DEFAULT NULL,
  -- Generation statistics
  -- Audit
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_tt_uuid` (`uuid`),
  UNIQUE KEY `uq_tt_code` (`code`),
  KEY `idx_tt_session` (`academic_session_id`),
  KEY `idx_tt_mode` (`timetable_mode_id`),
  KEY `idx_tt_status` (`status`),
  KEY `idx_tt_effective` (`effective_from`, `effective_to`),
  CONSTRAINT `fk_tt_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tt_mode` FOREIGN KEY (`timetable_mode_id`) REFERENCES `tt_timetable_mode` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tt_period_set` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_set` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tt_parent` FOREIGN KEY (`parent_timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE
  SET NULL,
    CONSTRAINT `fk_tt_published_by` FOREIGN KEY (`published_by`) REFERENCES `sys_users` (`id`) ON DELETE
  SET NULL,
    CONSTRAINT `fk_tt_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE
  SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- -----------------------------------------------------
-- GENERATION RUN (Algorithm execution log)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_generation_run` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,
  `timetable_id` BIGINT UNSIGNED NOT NULL,
  -- FK to tt_timetable
  `run_number` INT UNSIGNED NOT NULL DEFAULT 1,
  `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `finished_at` TIMESTAMP NULL DEFAULT NULL,
  `status` ENUM(
    'QUEUED',
    'RUNNING',
    'COMPLETED',
    'FAILED',
    'CANCELLED'
  ) NOT NULL DEFAULT 'QUEUED',
  -- Algorithm parameters
  `algorithm_version` VARCHAR(20) DEFAULT NULL,
  `max_recursion_depth` INT UNSIGNED DEFAULT 14,
  `max_placement_attempts` INT UNSIGNED DEFAULT NULL,
  `params_json` JSON DEFAULT NULL,
  -- Full algorithm parameters
  -- Results
  `activities_total` INT UNSIGNED DEFAULT 0,
  `activities_placed` INT UNSIGNED DEFAULT 0,
  `activities_failed` INT UNSIGNED DEFAULT 0,
  `hard_violations` INT UNSIGNED DEFAULT 0,
  `soft_violations` INT UNSIGNED DEFAULT 0,
  `soft_score` DECIMAL(10, 4) DEFAULT NULL,
  `stats_json` JSON DEFAULT NULL,
  -- Detailed statistics
  `error_message` TEXT DEFAULT NULL,
  -- Audit
  `triggered_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_gr_uuid` (`uuid`),
  UNIQUE KEY `uq_gr_tt_run` (`timetable_id`, `run_number`),
  KEY `idx_gr_status` (`status`),
  CONSTRAINT `fk_gr_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_gr_triggered_by` FOREIGN KEY (`triggered_by`) REFERENCES `sys_users` (`id`) ON DELETE
  SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- -----------------------------------------------------
-- (Individual slots) Each row = one period slot on a specific day for a class
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_timetable_cell` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `timetable_id` BIGINT UNSIGNED NOT NULL,
  -- FK to tt_timetable
  `generation_run_id` BIGINT UNSIGNED DEFAULT NULL,
  -- FK to tt_generation_run
  -- Slot identification
  `day_of_week` TINYINT UNSIGNED NOT NULL,
  -- 1-7 (ISO 8601)
  `period_ord` TINYINT UNSIGNED NOT NULL,
  -- Period ordinal
  `cell_date` DATE DEFAULT NULL,
  -- Specific date (for non-recurring)
  -- Target (one of these must be set)
  `class_group_id` BIGINT UNSIGNED DEFAULT NULL,
  `class_subgroup_id` BIGINT UNSIGNED DEFAULT NULL,
  -- Activity & Teacher
  `activity_id` BIGINT UNSIGNED DEFAULT NULL,
  -- FK to tt_activity
  `sub_activity_id` BIGINT UNSIGNED DEFAULT NULL,
  -- FK to tt_sub_activity
  -- Room
  `room_id` INT UNSIGNED DEFAULT NULL,
  -- FK to sch_rooms
  -- Cell status
  `source` ENUM('AUTO', 'MANUAL', 'SWAP', 'LOCK') NOT NULL DEFAULT 'AUTO',
  `is_locked` TINYINT(1) NOT NULL DEFAULT 0,
  -- Locked from auto-changes?
  `locked_by` BIGINT UNSIGNED DEFAULT NULL,
  `locked_at` TIMESTAMP NULL DEFAULT NULL,
  -- Quality indicators
  `has_conflict` TINYINT(1) DEFAULT 0,
  `conflict_details_json` JSON DEFAULT NULL,
  -- Audit
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_cell_tt_day_period_group` (
    `timetable_id`,
    `day_of_week`,
    `period_ord`,
    `class_group_id`,
    `class_subgroup_id`
  ),
  KEY `idx_cell_tt` (`timetable_id`),
  KEY `idx_cell_day_period` (`day_of_week`, `period_ord`),
  KEY `idx_cell_activity` (`activity_id`),
  KEY `idx_cell_room` (`room_id`),
  KEY `idx_cell_date` (`cell_date`),
  CONSTRAINT `fk_cell_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cell_gen_run` FOREIGN KEY (`generation_run_id`) REFERENCES `tt_generation_run` (`id`) ON DELETE
  SET NULL,
    CONSTRAINT `fk_cell_class_group` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cell_subgroup` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroup` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cell_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`) ON DELETE
  SET NULL,
    CONSTRAINT `fk_cell_sub_activity` FOREIGN KEY (`sub_activity_id`) REFERENCES `tt_sub_activity` (`id`) ON DELETE
  SET NULL,
    CONSTRAINT `fk_cell_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`) ON DELETE
  SET NULL,
    CONSTRAINT `fk_cell_locked_by` FOREIGN KEY (`locked_by`) REFERENCES `sys_users` (`id`) ON DELETE
  SET NULL,
    -- Must have either class_group or subgroup
    CONSTRAINT `chk_cell_target` CHECK (
      (
        `class_group_id` IS NOT NULL
        AND `class_subgroup_id` IS NULL
      )
      OR (
        `class_group_id` IS NULL
        AND `class_subgroup_id` IS NOT NULL
      )
    )
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- -----------------------------------------------------
-- (Teachers assigned to cells) Supports multiple teachers per cell
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_timetable_cell_teacher` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `cell_id` BIGINT UNSIGNED NOT NULL,
  -- FK to tt_timetable_cell
  `teacher_id` BIGINT UNSIGNED NOT NULL,
  -- FK to sch_teachers
  `assignment_role_id` BIGINT UNSIGNED NOT NULL,
  -- FK to tt_teacher_assignment_role
  `is_substitute` TINYINT(1) DEFAULT 0,
  -- Is this a substitute teacher?
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_cct_cell_teacher` (`cell_id`, `teacher_id`),
  KEY `idx_cct_teacher` (`teacher_id`),
  CONSTRAINT `fk_cct_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cell` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cct_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cct_role` FOREIGN KEY (`assignment_role_id`) REFERENCES `tt_teacher_assignment_role` (`id`) ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- =========================================================================
--  SECTION 7: SUBSTITUTION MANAGEMENT
-- =========================================================================
-- -----------------------------------------------------
-- Records teacher absences requiring for substitution findings
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_teacher_absence` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `teacher_id` BIGINT UNSIGNED NOT NULL,
  -- FK to sch_teachers
  `absence_date` DATE NOT NULL,
  `absence_type` ENUM(
    'LEAVE',
    'SICK',
    'TRAINING',
    'OFFICIAL_DUTY',
    'OTHER'
  ) NOT NULL,
  `start_period` TINYINT UNSIGNED DEFAULT NULL,
  -- NULL = full day
  `end_period` TINYINT UNSIGNED DEFAULT NULL,
  `reason` VARCHAR(500) DEFAULT NULL,
  `status` ENUM('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
  `approved_by` BIGINT UNSIGNED DEFAULT NULL,
  `approved_at` TIMESTAMP NULL DEFAULT NULL,
  `substitution_required` TINYINT(1) DEFAULT 1,
  `substitution_completed` TINYINT(1) DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_ta_teacher_date` (`teacher_id`, `absence_date`),
  KEY `idx_ta_date` (`absence_date`),
  KEY `idx_ta_status` (`status`),
  CONSTRAINT `fk_ta_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ta_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_users` (`id`) ON DELETE
  SET NULL,
    CONSTRAINT `fk_ta_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE
  SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- -----------------------------------------------------
-- Records substitution assignments
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_substitution_log` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `teacher_absence_id` BIGINT UNSIGNED DEFAULT NULL,
  -- FK to tt_teacher_absence
  `cell_id` BIGINT UNSIGNED NOT NULL,
  -- FK to tt_timetable_cell
  `substitution_date` DATE NOT NULL,
  `absent_teacher_id` BIGINT UNSIGNED NOT NULL,
  -- FK to sch_teachers
  `substitute_teacher_id` BIGINT UNSIGNED NOT NULL,
  `assignment_method` ENUM('AUTO', 'MANUAL', 'SWAP') NOT NULL DEFAULT 'MANUAL',
  `reason` VARCHAR(500) DEFAULT NULL,
  `status` ENUM('ASSIGNED', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'ASSIGNED',
  `notified_at` TIMESTAMP NULL DEFAULT NULL,
  `accepted_at` TIMESTAMP NULL DEFAULT NULL,
  `completed_at` TIMESTAMP NULL DEFAULT NULL,
  `feedback` TEXT DEFAULT NULL,
  `assigned_by` BIGINT UNSIGNED DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `idx_sub_date` (`substitution_date`),
  KEY `idx_sub_absent` (`absent_teacher_id`),
  KEY `idx_sub_substitute` (`substitute_teacher_id`),
  KEY `idx_sub_status` (`status`),
  CONSTRAINT `fk_sub_absence` FOREIGN KEY (`teacher_absence_id`) REFERENCES `tt_teacher_absence` (`id`) ON DELETE
  SET NULL,
    CONSTRAINT `fk_sub_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cell` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sub_absent_teacher` FOREIGN KEY (`absent_teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sub_substitute_teacher` FOREIGN KEY (`substitute_teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sub_assigned_by` FOREIGN KEY (`assigned_by`) REFERENCES `sys_users` (`id`) ON DELETE
  SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- =========================================================================
--  SECTION 8: TEACHER WORKLOAD & ANALYTICS
-- =========================================================================
-- -----------------------------------------------------------------------------
-- (TEACHER WORKLOAD SUMMARY) Aggregated workload data per teacher per session
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_teacher_workload` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `teacher_id` BIGINT UNSIGNED NOT NULL,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  `timetable_id` BIGINT UNSIGNED DEFAULT NULL,
  -- Weekly workload
  `weekly_periods_assigned` SMALLINT UNSIGNED DEFAULT 0,
  `weekly_periods_max` SMALLINT UNSIGNED DEFAULT NULL,
  `weekly_periods_min` SMALLINT UNSIGNED DEFAULT NULL,
  -- Daily distribution
  `daily_distribution_json` JSON DEFAULT NULL,
  -- {1: 5, 2: 6, 3: 4, ...}
  -- Subject breakdown
  `subjects_assigned_json` JSON DEFAULT NULL,
  -- [{subject_id, periods, classes}]
  `classes_assigned_json` JSON DEFAULT NULL,
  -- Workload metrics
  `utilization_percent` DECIMAL(5, 2) DEFAULT NULL,
  `gap_periods_total` SMALLINT UNSIGNED DEFAULT 0,
  `consecutive_max` TINYINT UNSIGNED DEFAULT 0,
  -- Audit
  `last_calculated_at` TIMESTAMP NULL DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_tw_teacher_session_tt` (
    `teacher_id`,
    `academic_session_id`,
    `timetable_id`
  ),
  KEY `idx_tw_session` (`academic_session_id`),
  CONSTRAINT `fk_tw_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tw_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tw_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE
  SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- =========================================================================
--  SECTION 9: AUDIT & HISTORY
-- =========================================================================
-- -----------------------------------------------------------------------------
-- (CHANGE LOG) Tracks all changes to allocated cells
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_change_log` (
  `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `timetable_id` BIGINT UNSIGNED NOT NULL,
  `cell_id` BIGINT UNSIGNED DEFAULT NULL,
  `change_type` ENUM(
    'CREATE',
    'UPDATE',
    'DELETE',
    'LOCK',
    'UNLOCK',
    'SWAP',
    'SUBSTITUTE'
  ) NOT NULL,
  `change_date` DATE NOT NULL,
  `old_values_json` JSON DEFAULT NULL,
  `new_values_json` JSON DEFAULT NULL,
  `reason` VARCHAR(500) DEFAULT NULL,
  `changed_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  KEY `idx_cl_timetable` (`timetable_id`),
  KEY `idx_cl_cell` (`cell_id`),
  KEY `idx_cl_date` (`change_date`),
  KEY `idx_cl_type` (`change_type`),
  CONSTRAINT `fk_cl_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cl_cell` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cell` (`id`) ON DELETE
  SET NULL,
    CONSTRAINT `fk_cl_changed_by` FOREIGN KEY (`changed_by`) REFERENCES `sys_users` (`id`) ON DELETE
  SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
SET FOREIGN_KEY_CHECKS = 1;
-- =====================================================================
-- END OF TIMETABLE MODULE - VERSION 3.0
-- =====================================================================
--
-- TABLE SUMMARY (21 Tables):
-- -------------------------
-- SECTION 0 - Master Config (4):
--   tt_timetable_mode, tt_period_type, tt_teacher_assignment_role, tt_working_day
--
-- SECTION 1 - Timing Profiles (1):
--   tt_school_timing_profile
--
-- SECTION 2 - Period Sets (2):
--   tt_period_set, tt_period_set_period_jnt
--
-- SECTION 3 - Class Grouping (4):
--   tt_class_mode_rule, tt_class_group_requirement, tt_class_subgroup, tt_class_subgroup_member
--
-- SECTION 4 - Activities (3):
--   tt_activity, tt_activity_teacher, tt_sub_activity
--
-- SECTION 5 - Constraints (4):
--   tt_constraint_type, tt_constraint, tt_teacher_unavailable, tt_room_unavailable
--
-- SECTION 6 - Timetable Storage (4):
--   tt_timetable, tt_generation_run, tt_timetable_cell, tt_timetable_cell_teacher
--
-- SECTION 7 - Substitution (2):
--   tt_teacher_absence, tt_substitution_log
--
-- SECTION 8 - Analytics (1):
--   tt_teacher_workload
--
-- SECTION 9 - Audit (1):
--   tt_change_log
--
-- REMOVED TABLES (Redundant/Replaced):
-- ------------------------------------
-- tt_days → Covered by tt_working_day
-- tt_periods → Covered by tt_period_set_period_jnt
-- tt_timing_profile → Covered by tt_period_set + tt_class_mode_rule
-- tt_room_unavailable → Replaced by tt_room_unavailable
-- =====================================================================