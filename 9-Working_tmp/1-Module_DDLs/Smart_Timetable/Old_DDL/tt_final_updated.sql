-- =====================================================================
-- SMART TIMETABLE MODULE — VERSION 8.0
-- Refactored from v7.5:
--   • Tables reordered so every FK target is created before its referencing table
--   • All table names pluralised to Laravel conventions
--   • FK constraints referencing tables NOT defined in this file have been
--     REMOVED (columns are kept; only the CONSTRAINT clause is dropped).
--     Affected external tables: glb_*, sys_*, sch_employee_roles,
--     sch_departments, sch_designations, sch_shifts (tt_shift already
--     pluralised to tt_shifts and IS in this file).
--   • Circular FK (activity_id in tt_slot_requirements,
--     tt_teacher_availabilities, tt_room_availabilities) resolved by
--     omitting those FK constraints (columns kept, nullable).
-- =====================================================================

-- =====================================================================
-- CREATION ORDER (dependency-safe)
-- =====================================================================
--
--  LAYER 0 — pure standalone reference tables (no FKs at all)
--    sch_organizations
--    sch_org_academic_sessions       (was sch_org_academic_sessions_jnt)
--    sch_board_organizations         (was sch_board_organization_jnt)
--    sch_classes
--    sch_sections
--    sch_subject_types
--    sch_study_formats
--    sch_subjects
--    sch_buildings
--    sch_room_types                  (was sch_rooms_type)
--    tt_configs                      (was tt_config)
--    tt_generation_strategies        (was tt_generation_strategy)
--    tt_shifts                       (was tt_shift)
--    tt_day_types                    (was tt_day_type)
--    tt_period_types                 (was tt_period_type)
--    tt_teacher_assignment_roles     (was tt_teacher_assignment_role)
--    tt_school_days                  (was tt_school_days — already plural)
--    tt_period_sets                  (was tt_period_set)
--    tt_constraint_category_scopes   (was tt_constraint_category_scope)
--
--  LAYER 1 — depend only on LAYER 0
--    sch_rooms                       FK → sch_buildings, sch_room_types
--    sch_academic_terms              (was sch_academic_term) FK → sch_org_academic_sessions
--    tt_working_days                 (was tt_working_day)    FK → tt_day_types
--    tt_period_set_periods           (was tt_period_set_period_jnt) FK → tt_period_sets, tt_period_types
--    tt_timetable_types              (was tt_timetable_type) FK → tt_shifts
--    tt_constraint_types             (was tt_constraint_type) FK → tt_constraint_category_scopes
--
--  LAYER 2 — depend on LAYER 0 + 1
--    sch_subject_study_formats       (was sch_subject_study_format_jnt) FK → sch_subjects, sch_study_formats, sch_subject_types
--    sch_class_sections              (was sch_class_section_jnt) FK → sch_classes, sch_sections
--    tt_class_working_days           (was tt_class_working_day_jnt) FK → tt_working_days
--    tt_timetable_types already done
--    tt_class_timetable_types        (was tt_class_timetable_type_jnt) FK → sch_academic_terms, tt_timetable_types, tt_period_sets, sch_classes, sch_sections
--    tt_constraints                  (was tt_constraint) FK → tt_constraint_types, sch_academic_terms
--    sch_employees
--
--  LAYER 3 — depend on LAYER 0-2
--    sch_class_groups                (was sch_class_groups_jnt) FK → sch_classes, sch_sections, sch_subject_study_formats, sch_subject_types
--    sch_subject_groups              FK → sch_classes, sch_sections
--    tt_teacher_unavailables         FK → tt_constraints
--    tt_room_unavailables            FK → tt_constraints
--    sch_teacher_profiles            (was sch_teacher_profile) FK → sch_employees
--
--  LAYER 4 — depend on LAYER 0-3
--    sch_subject_group_subjects      FK → sch_subject_groups, sch_class_groups, sch_subjects, sch_subject_study_formats
--    tt_class_requirement_groups     FK → sch_classes, sch_sections
--    tt_class_requirement_subgroups  FK → sch_classes, sch_sections
--    sch_teacher_capabilities        FK → sch_teacher_profiles, sch_classes, sch_subject_study_formats
--    std_students
--
--  LAYER 5 — depend on LAYER 0-4
--    tt_requirement_consolidations   FK → sch_academic_terms, tt_timetable_types, tt_class_requirement_groups, tt_class_requirement_subgroups
--    std_student_academic_sessions   FK → std_students, sch_org_academic_sessions, sch_class_sections, sch_subject_groups
--
--  LAYER 6 — depend on LAYER 0-5
--    tt_slot_requirements            FK → sch_academic_terms, tt_timetable_types, tt_class_timetable_types, sch_classes, sch_sections
--                                    NOTE: activity_id FK omitted (circular — tt_activities not yet created)
--    tt_priority_configs             FK → tt_requirement_consolidations
--
--  LAYER 7 — tt_activities and its children
--    tt_activities                   FK → sch_academic_terms, tt_timetable_types, sch_class_groups, tt_class_requirement_subgroups
--    tt_sub_activities               FK → tt_activities
--    tt_activity_priorities          FK → tt_activities
--    tt_activity_teachers            FK → tt_activities, tt_teacher_assignment_roles
--
--  LAYER 8 — resource availability (needs tt_requirement_consolidations + tt_activities)
--    tt_teacher_availabilities       FK → tt_requirement_consolidations, sch_classes, sch_sections
--                                    NOTE: activity_id FK omitted (nullable, add later if needed)
--    tt_teacher_availability_details FK → tt_teacher_availabilities
--    tt_room_availabilities          NOTE: activity_id FK omitted (nullable)
--    tt_room_availability_details    FK → tt_room_availabilities
--
--  LAYER 9 — timetable generation core
--    tt_timetables                   FK → tt_timetable_types, tt_period_sets, tt_generation_strategies, sch_org_academic_sessions
--    tt_generation_runs              FK → tt_timetables, tt_generation_strategies
--    tt_conflict_detections          FK → tt_timetables
--    tt_resource_bookings
--    tt_constraint_violations        FK → tt_timetables, tt_constraints
--    tt_timetable_cells              FK → tt_timetables, tt_generation_runs, sch_class_groups, tt_class_requirement_subgroups, tt_activities, tt_sub_activities
--    tt_timetable_cell_teachers      FK → tt_timetable_cells, tt_teacher_assignment_roles
--
--  LAYER 10 — analytics, audit, substitution
--    tt_teacher_workloads            FK → tt_timetables, sch_org_academic_sessions
--    tt_change_logs                  FK → tt_timetables, tt_timetable_cells
--    tt_teacher_absences
--    tt_substitution_logs            FK → tt_teacher_absences, tt_timetable_cells
--
-- =====================================================================


-- =====================================================================
-- LAYER 0 — STANDALONE REFERENCE TABLES (no FKs within this file)
-- =====================================================================

-- -----------------------------------------------
COMMENT='Single-record school identity — mirrors prm_tenant';


-- -----------------------------------------------
COMMENT='School-specific academic session records';


-- -----------------------------------------------
COMMENT='Boards associated with the school per academic session';


-- -----------------------------------------------
COMMENT='School class / grade definitions';


-- -----------------------------------------------
COMMENT='Section (division) definitions';


-- -----------------------------------------------
COMMENT='Subject type classifications — MAJOR, MINOR, OPTIONAL, etc.';


-- -----------------------------------------------
COMMENT='Teaching delivery formats — LECTURE, LAB, PRACTICAL, etc.';


-- -----------------------------------------------
COMMENT='Master subject list';


-- -----------------------------------------------
COMMENT='School building definitions';


-- -----------------------------------------------
COMMENT='Room / facility type definitions';


-- -----------------------------------------------
-- [CFG-01] tt_configs  (was tt_config)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_configs` (
  `id`              SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ordinal`         INT UNSIGNED      NOT NULL DEFAULT 1,
  `key`             VARCHAR(150)      NOT NULL,
  `key_name`        VARCHAR(150)      NOT NULL,
  `value`           VARCHAR(512)      NOT NULL,
  `value_type`      ENUM('STRING','NUMBER','BOOLEAN','DATE','TIME','DATETIME','JSON') NOT NULL,
  `description`     VARCHAR(255)      NOT NULL,
  `additional_info` JSON              DEFAULT NULL,
  `tenant_can_modify` TINYINT(1)      NOT NULL DEFAULT 0,
  `mandatory`       TINYINT(1)        NOT NULL DEFAULT 1,
  `used_by_app`     TINYINT(1)        NOT NULL DEFAULT 1,
  `is_active`       TINYINT(1)        NOT NULL DEFAULT 1,
  `deleted_at`      TIMESTAMP         NULL DEFAULT NULL,
  `created_at`      TIMESTAMP         NULL DEFAULT NULL,
  `updated_at`      TIMESTAMP         NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ttConfig_ordinal` (`ordinal`),
  UNIQUE KEY `uq_ttConfig_key`     (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Module-level timetable configuration key-value pairs';


-- -----------------------------------------------
-- [CFG-02] tt_generation_strategies  (was tt_generation_strategy)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_generation_strategies` (
  `id`                     SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`                   VARCHAR(20)       NOT NULL,
  `name`                   VARCHAR(100)      NOT NULL,
  `description`            VARCHAR(255)      NULL,
  `algorithm_type`         ENUM('RECURSIVE','GENETIC','SIMULATED_ANNEALING','TABU_SEARCH','HYBRID') DEFAULT 'RECURSIVE',
  `max_recursive_depth`    INT UNSIGNED      DEFAULT 14,
  `max_placement_attempts` INT UNSIGNED      DEFAULT 2000,
  `tabu_size`              INT UNSIGNED      DEFAULT 100,
  `cooling_rate`           DECIMAL(5,2)      DEFAULT 0.95,
  `population_size`        INT UNSIGNED      DEFAULT 50,
  `generations`            INT UNSIGNED      DEFAULT 100,
  `activity_sorting_method` ENUM('LESS_TEACHER_FIRST','DIFFICULTY_FIRST','CONSTRAINT_COUNT','DURATION_FIRST','RANDOM') DEFAULT 'LESS_TEACHER_FIRST',
  `timeout_seconds`        INT UNSIGNED      DEFAULT 300,
  `parameters_json`        JSON              NULL,
  `is_default`             TINYINT(1)        DEFAULT 0,
  `is_active`              TINYINT(1)        DEFAULT 1,
  `created_at`             TIMESTAMP         DEFAULT CURRENT_TIMESTAMP,
  `updated_at`             TIMESTAMP         DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_genStrategy_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Timetable generation algorithm configurations';


-- -----------------------------------------------
-- [MST-01] tt_shifts  (was tt_shift)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_shifts` (
  `id`                TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`              VARCHAR(20)      NOT NULL,
  `name`              VARCHAR(100)     NOT NULL,
  `description`       VARCHAR(255)     DEFAULT NULL,
  `default_start_time` TIME            DEFAULT NULL,
  `default_end_time`  TIME             DEFAULT NULL,
  `ordinal`           TINYINT UNSIGNED DEFAULT 1,
  `is_active`         TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`        TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`        TIMESTAMP        NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_shift_ordinal` (`ordinal`),
  UNIQUE KEY `uq_shift_code`    (`code`),
  UNIQUE KEY `uq_shift_name`    (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='School shift definitions — MORNING, AFTERNOON, EVENING';


-- -----------------------------------------------
-- [MST-02] tt_day_types  (was tt_day_type)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_day_types` (
  `id`              TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`            VARCHAR(20)      NOT NULL,
  `name`            VARCHAR(100)     NOT NULL,
  `description`     VARCHAR(255)     DEFAULT NULL,
  `is_working_day`  TINYINT(1)       NOT NULL DEFAULT 1,
  `reduced_periods` TINYINT(1)       NOT NULL DEFAULT 0,
  `ordinal`         TINYINT UNSIGNED DEFAULT 1,
  `is_active`       TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`      TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`      TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dayType_ordinal` (`ordinal`),
  UNIQUE KEY `uq_dayType_code`    (`code`),
  UNIQUE KEY `uq_dayType_name`    (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Day type classifications — STUDY, HOLIDAY, EXAM, SPECIAL, etc.';


-- -----------------------------------------------
-- [MST-03] tt_period_types  (was tt_period_type)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_period_types` (
  `id`                TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`              VARCHAR(30)      NOT NULL,
  `name`              VARCHAR(100)     NOT NULL,
  `description`       VARCHAR(255)     DEFAULT NULL,
  `color_code`        VARCHAR(10)      DEFAULT NULL,
  `icon`              VARCHAR(50)      DEFAULT NULL,
  `is_schedulable`    TINYINT(1)       NOT NULL DEFAULT 1,
  `counts_as_teaching` TINYINT(1)      NOT NULL DEFAULT 0,
  `counts_as_workload` TINYINT(1)      NOT NULL DEFAULT 0,
  `is_break`          TINYINT(1)       NOT NULL DEFAULT 0,
  `is_free_period`    TINYINT(1)       NOT NULL DEFAULT 0,
  `ordinal`           TINYINT UNSIGNED DEFAULT 1,
  `duration_minutes`  INT UNSIGNED     DEFAULT 30,
  `is_active`         TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`        TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`        TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_periodType_ordinal` (`ordinal`),
  UNIQUE KEY `uq_periodType_code`    (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Period type definitions — TEACHING, BREAK, LUNCH, EXAM, etc.';


-- -----------------------------------------------
-- [MST-04] tt_teacher_assignment_roles  (was tt_teacher_assignment_role)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_teacher_assignment_roles` (
  `id`                    TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`                  VARCHAR(30)      NOT NULL,
  `name`                  VARCHAR(100)     NOT NULL,
  `description`           VARCHAR(255)     DEFAULT NULL,
  `is_primary_instructor` TINYINT(1)       NOT NULL DEFAULT 0,
  `counts_for_workload`   TINYINT(1)       NOT NULL DEFAULT 0,
  `allows_overlap`        TINYINT(1)       NOT NULL DEFAULT 0,
  `workload_factor`       DECIMAL(5,2)     DEFAULT 1.00,
  `ordinal`               TINYINT UNSIGNED DEFAULT 1,
  `is_system`             TINYINT(1)       DEFAULT 1,
  `is_active`             TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`            TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_taRole_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Teacher role types within an activity — PRIMARY, ASSISTANT, CO_TEACHER, etc.';


-- -----------------------------------------------
-- [MST-05] tt_school_days  (name unchanged — already a plural concept)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_school_days` (
  `id`           TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`         VARCHAR(10)      NOT NULL,
  `name`         VARCHAR(20)      NOT NULL,
  `short_name`   VARCHAR(5)       NOT NULL,
  `day_of_week`  TINYINT UNSIGNED NOT NULL,
  `ordinal`      TINYINT UNSIGNED NOT NULL,
  `is_school_day` TINYINT(1)      NOT NULL DEFAULT 1,
  `is_active`    TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`   TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`   TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`   TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_schoolDay_code` (`code`),
  UNIQUE KEY `uq_schoolDay_dow`  (`day_of_week`),
  KEY `idx_schoolDay_ordinal`    (`ordinal`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='School open/closed day configuration per week';


-- -----------------------------------------------
-- [MST-06] tt_period_sets  (was tt_period_set)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_period_sets` (
  `id`                   INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `code`                 VARCHAR(30)      NOT NULL,
  `name`                 VARCHAR(100)     NOT NULL,
  `description`          VARCHAR(255)     DEFAULT NULL,
  `total_periods`        TINYINT UNSIGNED NOT NULL,
  `teaching_periods`     TINYINT UNSIGNED NOT NULL,
  `exam_periods`         TINYINT UNSIGNED NOT NULL,
  `free_periods`         TINYINT UNSIGNED NOT NULL,
  `assembly_periods`     TINYINT UNSIGNED NOT NULL,
  `short_break_periods`  TINYINT UNSIGNED NOT NULL,
  `lunch_break_periods`  TINYINT UNSIGNED NOT NULL,
  `day_start_time`       TIME             NOT NULL,
  `day_end_time`         TIME             NOT NULL,
  `is_default`           TINYINT(1)       DEFAULT 0,
  `is_active`            TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`           TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`           TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_periodSet_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Period set templates — defines total/teaching/exam/break period counts per day';


-- -----------------------------------------------
-- [MST-07] tt_constraint_category_scopes  (was tt_constraint_category_scope)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_constraint_category_scopes` (
  `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `type`        ENUM('CATEGORY','SCOPE') NOT NULL,
  `code`        VARCHAR(30)  NOT NULL,
  `name`        VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `is_active`   TINYINT(1)   NOT NULL DEFAULT 1,
  `created_at`  TIMESTAMP    NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  TIMESTAMP    NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`  TIMESTAMP    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_constraintCatScope_typeCode` (`type`, `code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Constraint category and scope master — system-defined only';


-- =====================================================================
-- LAYER 1 — DEPEND ONLY ON LAYER 0
-- =====================================================================

-- -----------------------------------------------
COMMENT='Physical room / facility records';


-- -----------------------------------------------
COMMENT='Academic term / quarter / semester structure per session';


-- -----------------------------------------------
-- [MST-08] tt_working_days  (was tt_working_day)
-- -----------------------------------------------
-- academic_session_id column kept; FK to sch_org_academic_sessions would be
-- added once that table exists — it IS in this file, defined above.
CREATE TABLE IF NOT EXISTS `tt_working_days` (
  `id`                 INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `academic_session_id` INT UNSIGNED   NOT NULL,  -- FK to sch_org_academic_sessions
  `date`               DATE             NOT NULL,
  `day_type1_id`       TINYINT UNSIGNED NOT NULL,
  `day_type2_id`       TINYINT UNSIGNED NULL,
  `day_type3_id`       TINYINT UNSIGNED NULL,
  `day_type4_id`       TINYINT UNSIGNED NULL,
  `is_school_day`      TINYINT(1)       NOT NULL DEFAULT 1,
  `remarks`            VARCHAR(255)     DEFAULT NULL,
  `is_active`          TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`         TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`         TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`         TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_workDay_date` (`date`),
  KEY `idx_workDay_dayType` (`day_type1_id`, `day_type2_id`, `day_type3_id`, `day_type4_id`),
  CONSTRAINT `fk_workDay_dayType1` FOREIGN KEY (`day_type1_id`) REFERENCES `tt_day_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_workDay_dayType2` FOREIGN KEY (`day_type2_id`) REFERENCES `tt_day_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_workDay_dayType3` FOREIGN KEY (`day_type3_id`) REFERENCES `tt_day_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_workDay_dayType4` FOREIGN KEY (`day_type4_id`) REFERENCES `tt_day_types` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Calendar-level working/holiday day status per academic session';


-- -----------------------------------------------
-- [MST-09] tt_period_set_periods  (was tt_period_set_period_jnt)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_period_set_periods` (
  `id`               INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `period_set_id`    INT UNSIGNED     NOT NULL,
  `period_ord`       TINYINT UNSIGNED NOT NULL,
  `code`             VARCHAR(20)      NOT NULL,
  `short_name`       VARCHAR(50)      NOT NULL,
  `period_type_id`   INT UNSIGNED     NOT NULL,
  `start_time`       TIME             NOT NULL,
  `end_time`         TIME             NOT NULL,
  `duration_minutes` SMALLINT UNSIGNED GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, `start_time`, `end_time`)) STORED,
  `is_active`        TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`       TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`       TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_psp_setOrd`  (`period_set_id`, `period_ord`),
  UNIQUE KEY `uq_psp_setCode` (`period_set_id`, `code`),
  KEY `idx_psp_type` (`period_type_id`),
  CONSTRAINT `fk_psp_periodSet`  FOREIGN KEY (`period_set_id`)  REFERENCES `tt_period_sets`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_psp_periodType` FOREIGN KEY (`period_type_id`) REFERENCES `tt_period_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `chk_psp_time` CHECK (`end_time` > `start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Individual period slots within a period set';


-- -----------------------------------------------
-- [MST-10] tt_timetable_types  (was tt_timetable_type)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_timetable_types` (
  `id`                  INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `code`                VARCHAR(30)      NOT NULL,
  `name`                VARCHAR(100)     NOT NULL,
  `description`         VARCHAR(255)     DEFAULT NULL,
  `shift_id`            INT UNSIGNED     DEFAULT NULL,
  `effective_from_date` DATE             DEFAULT NULL,
  `effective_to_date`   DATE             DEFAULT NULL,
  `school_start_time`   TIME             DEFAULT NULL,
  `school_end_time`     TIME             DEFAULT NULL,
  `has_exam`            TINYINT(1)       NOT NULL DEFAULT 0,
  `has_teaching`        TINYINT(1)       NOT NULL DEFAULT 1,
  `ordinal`             SMALLINT UNSIGNED DEFAULT 1,
  `is_default`          TINYINT(1)       DEFAULT 0,
  `is_active`           TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`          TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`          TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ttType_code` (`code`),
  KEY `idx_ttType_shift` (`shift_id`),
  CONSTRAINT `fk_ttType_shift` FOREIGN KEY (`shift_id`) REFERENCES `tt_shifts` (`id`),
  CONSTRAINT `chk_ttType_time` CHECK (`school_end_time` > `school_start_time` AND `effective_from_date` <= `effective_to_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Timetable mode definitions — STANDARD, EXAM, HALF_DAY, etc.';


-- -----------------------------------------------
-- [CON-01] tt_constraint_types  (was tt_constraint_type)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_constraint_types` (
  `id`                INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `code`              VARCHAR(60)      NOT NULL,
  `name`              VARCHAR(150)     NOT NULL,
  `description`       VARCHAR(255)     DEFAULT NULL,
  `category_id`       INT UNSIGNED     NOT NULL,
  `applicable_to`     ENUM('ALL','SPECIFIC') DEFAULT 'ALL',
  `scope_id`          INT UNSIGNED     NOT NULL,
  `target_id_required` TINYINT(1)      NOT NULL DEFAULT 0,
  `default_weight`    TINYINT UNSIGNED DEFAULT 100,
  `is_hard_constraint` TINYINT(1)      DEFAULT 1,
  `param_schema`      JSON             DEFAULT NULL,
  `is_system`         TINYINT(1)       DEFAULT 1,
  `is_active`         TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`        TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`        TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cType_code` (`code`),
  KEY `idx_cType_category` (`category_id`),
  KEY `idx_cType_scope`    (`scope_id`),
  CONSTRAINT `fk_cType_category` FOREIGN KEY (`category_id`) REFERENCES `tt_constraint_category_scopes` (`id`),
  CONSTRAINT `fk_cType_scope`    FOREIGN KEY (`scope_id`)    REFERENCES `tt_constraint_category_scopes` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Constraint type catalogue — system-defined';


-- =====================================================================
-- LAYER 2 — DEPEND ON LAYER 0 + LAYER 1
-- =====================================================================

-- -----------------------------------------------
COMMENT='Subject × study-format combinations (e.g. SCI_LAB, MTH_LEC)';


-- -----------------------------------------------
COMMENT='Class × section junction with house-room and teacher assignments';


-- -----------------------------------------------
-- [MST-11] tt_class_working_days  (was tt_class_working_day_jnt)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_class_working_days` (
  `id`                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `academic_session_id` INT UNSIGNED NOT NULL,   -- column kept; FK to sch_org_academic_sessions intentionally omitted (session mgmt handled externally)
  `date`               DATE         NOT NULL,
  `class_id`           INT UNSIGNED NOT NULL,
  `section_id`         INT UNSIGNED DEFAULT NULL,
  `working_day_id`     INT UNSIGNED NOT NULL,
  `is_exam_day`        TINYINT(1)   NOT NULL DEFAULT 0,
  `is_ptm_day`         TINYINT(1)   NOT NULL DEFAULT 0,
  `is_half_day`        TINYINT(1)   NOT NULL DEFAULT 0,
  `is_holiday`         TINYINT(1)   NOT NULL DEFAULT 0,
  `is_study_day`       TINYINT(1)   NOT NULL DEFAULT 1,
  `is_active`          TINYINT(1)   NOT NULL DEFAULT 1,
  `created_at`         TIMESTAMP    NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`         TIMESTAMP    NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`         TIMESTAMP    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_classWorkDay_classDay`    (`class_id`, `working_day_id`),
  KEY `idx_classWorkDay_class`             (`class_id`),
  KEY `idx_classWorkDay_workingDay`        (`working_day_id`),
  CONSTRAINT `fk_classWorkDay_workingDayId` FOREIGN KEY (`working_day_id`) REFERENCES `tt_working_days` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Per-class overrides on school working day calendar';


-- -----------------------------------------------
-- [MST-12] tt_class_timetable_types  (was tt_class_timetable_type_jnt)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_class_timetable_types` (
  `id`                          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `academic_term_id`            INT UNSIGNED     DEFAULT NULL,
  `timetable_type_id`           INT UNSIGNED     NOT NULL,
  `class_id`                    INT UNSIGNED     NOT NULL,
  `section_id`                  INT UNSIGNED     NULL,
  `period_set_id`               INT UNSIGNED     NOT NULL,
  `applies_to_all_sections`     TINYINT(1)       NOT NULL DEFAULT 1,
  `has_teaching`                TINYINT(1)       NOT NULL DEFAULT 1,
  `has_exam`                    TINYINT(1)       NOT NULL DEFAULT 0,
  `weekly_exam_period_count`    TINYINT UNSIGNED DEFAULT NULL,
  `weekly_teaching_period_count` TINYINT UNSIGNED DEFAULT NULL,
  `weekly_free_period_count`    TINYINT UNSIGNED DEFAULT NULL,
  `effective_from`              DATE             DEFAULT NULL,
  `effective_to`                DATE             DEFAULT NULL,
  `is_active`                   TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`                  TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                  TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`                  TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cttj_term` (`academic_term_id`, `timetable_type_id`, `class_id`, `section_id`),
  CONSTRAINT `fk_cttj_mode`      FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_types`   (`id`),
  CONSTRAINT `fk_cttj_periodSet` FOREIGN KEY (`period_set_id`)     REFERENCES `tt_period_sets`       (`id`),
  CONSTRAINT `chk_cttj_effectiveRange`    CHECK (`effective_from` < `effective_to`),
  CONSTRAINT `chk_cttj_applyToAllSection` CHECK (
    (`section_id` IS NULL AND `applies_to_all_sections` = 1) OR
    (`section_id` IS NOT NULL AND `applies_to_all_sections` = 0)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Assigns timetable type and period set to a class (and optionally section) per term';


-- -----------------------------------------------
-- [CON-02] tt_constraints  (was tt_constraint)
-- -----------------------------------------------
-- FK to sys_users (created_by) removed; column kept.
CREATE TABLE IF NOT EXISTS `tt_constraints` (
  `id`                 INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `constraint_type_id` INT UNSIGNED     NOT NULL,
  `name`               VARCHAR(200)     DEFAULT NULL,
  `description`        VARCHAR(500)     DEFAULT NULL,
  `academic_term_id`   INT UNSIGNED     DEFAULT NULL,
  `target_type`        INT UNSIGNED     NOT NULL,
  `target_id`          INT UNSIGNED     DEFAULT NULL,
  `is_hard`            TINYINT(1)       NOT NULL DEFAULT 0,
  `weight`             TINYINT UNSIGNED NOT NULL DEFAULT 100,
  `params_json`        JSON             NOT NULL,
  `effective_from`     DATE             DEFAULT NULL,
  `effective_to`       DATE             DEFAULT NULL,
  `apply_for_all_days` TINYINT(1)       NOT NULL DEFAULT 1,
  `applicable_days`    JSON             DEFAULT NULL,
  `impact_score`       TINYINT UNSIGNED DEFAULT 50,
  `is_active`          TINYINT(1)       NOT NULL DEFAULT 1,
  `created_by`         INT UNSIGNED     DEFAULT NULL,  -- column kept; FK to sys_users removed
  `created_at`         TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`         TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`         TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_constraint_type`       (`constraint_type_id`),
  INDEX `idx_constraint_target`     (`target_type`, `target_id`),
  INDEX `idx_constraint_term`       (`academic_term_id`),
  CONSTRAINT `fk_constraint_type`  FOREIGN KEY (`constraint_type_id`) REFERENCES `tt_constraint_types`  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Individual constraint instances attached to specific targets';


-- -----------------------------------------------
COMMENT='Employee master — all staff including teachers';


-- =====================================================================
-- LAYER 3 — DEPEND ON LAYER 0-2
-- =====================================================================

-- -----------------------------------------------
COMMENT='Class-level groupings by subject+format+type for timetable scheduling';


-- -----------------------------------------------
COMMENT='Subject group bundles assigned to students per class/section';


-- -----------------------------------------------
-- [CON-03] tt_teacher_unavailables  (was tt_teacher_unavailable)
-- -----------------------------------------------
-- FK to sch_teachers removed; teacher_id column kept.
CREATE TABLE IF NOT EXISTS `tt_teacher_unavailables` (
  `id`                        INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `teacher_id`                INT UNSIGNED     NOT NULL,   -- column kept; FK to sch_teachers removed
  `constraint_id`             INT UNSIGNED     DEFAULT NULL,
  `unavailable_for_all_days`  TINYINT(1)       NOT NULL DEFAULT 0,
  `day_of_week`               ENUM('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') NOT NULL DEFAULT 'Monday',
  `unavailable_for_all_periods` TINYINT(1)     NOT NULL DEFAULT 0,
  `period_no`                 TINYINT UNSIGNED DEFAULT NULL,
  `is_recurring`              TINYINT(1)       DEFAULT 1,
  `recurring_frequency`       ENUM('Daily','Weekly','Monthly','Yearly') DEFAULT 'Daily',
  `start_date`                DATE             DEFAULT NULL,
  `end_date`                  DATE             DEFAULT NULL,
  `reason`                    VARCHAR(255)     DEFAULT NULL,
  `is_active`                 TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`                TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`                TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_tu_teacher`      (`teacher_id`),
  KEY `idx_tu_dayPeriod`    (`day_of_week`, `period_no`),
  CONSTRAINT `fk_tu_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraints` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Teacher unavailability blocks used by the constraint engine';


-- -----------------------------------------------
-- [CON-04] tt_room_unavailables  (was tt_room_unavailable)
-- -----------------------------------------------
-- FK to sch_rooms kept (in this file).
CREATE TABLE IF NOT EXISTS `tt_room_unavailables` (
  `id`           INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `room_id`      INT UNSIGNED     NOT NULL,
  `constraint_id` INT UNSIGNED    DEFAULT NULL,
  `day_of_week`  TINYINT UNSIGNED NOT NULL,
  `period_ord`   TINYINT UNSIGNED DEFAULT NULL,
  `start_date`   DATE             DEFAULT NULL,
  `end_date`     DATE             DEFAULT NULL,
  `reason`       VARCHAR(255)     DEFAULT NULL,
  `is_recurring` TINYINT(1)       DEFAULT 1,
  `is_active`    TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`   TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`   TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`   TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ru_room`      (`room_id`),
  KEY `idx_ru_dayPeriod` (`day_of_week`, `period_ord`),
  CONSTRAINT `fk_ru_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraints` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Room unavailability blocks used by the constraint engine';


-- -----------------------------------------------
COMMENT='Teacher-specific profile — capabilities, scheduling preferences, workload limits';


-- =====================================================================
-- LAYER 4 — DEPEND ON LAYER 0-3
-- =====================================================================

-- -----------------------------------------------
COMMENT='Subject-to-subject-group assignment junction';


-- -----------------------------------------------
-- [REQ-01] tt_class_requirement_groups  (was tt_class_requirement_groups — name unchanged)
-- -----------------------------------------------
-- FKs to sch_room_types and sch_rooms kept (in this file).
-- Orphaned column references from original DDL (required_room_type_id, required_room_id)
-- were referenced in constraints but not listed as columns — kept as documented.
CREATE TABLE IF NOT EXISTS `tt_class_requirement_groups` (
  `id`                     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `code`                   CHAR(50)      NOT NULL,
  `name`                   VARCHAR(100)  NOT NULL,
  `class_group_id`         INT UNSIGNED  NOT NULL,
  `class_id`               INT UNSIGNED  NOT NULL,
  `section_id`             INT UNSIGNED  DEFAULT NULL,
  `subject_id`             INT UNSIGNED  NOT NULL,
  `study_format_id`        INT UNSIGNED  NOT NULL,
  `subject_type_id`        INT UNSIGNED  NOT NULL,
  `subject_study_format_id` INT UNSIGNED NOT NULL,
  `class_house_room_id`    INT UNSIGNED  NOT NULL,
  `student_count`          INT UNSIGNED  DEFAULT NULL,
  `eligible_teacher_count` INT UNSIGNED  DEFAULT NULL,
  `required_room_type_id`  INT UNSIGNED  NOT NULL,
  `required_room_id`       INT UNSIGNED  DEFAULT NULL,
  `is_active`              TINYINT(1)    NOT NULL DEFAULT 1,
  `deleted_at`             TIMESTAMP     NULL DEFAULT NULL,
  `created_at`             TIMESTAMP     NULL DEFAULT NULL,
  `updated_at`             TIMESTAMP     NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_clsReqGrp_code`                    (`code`),
  UNIQUE KEY `uq_clsReqGrp_cls_sec_ssfmt`           (`class_id`, `section_id`, `subject_study_format_id`),
  KEY `idx_clsReqGrp_class`                         (`class_id`, `section_id`),
  KEY `idx_clsReqGrp_subjectType`                   (`subject_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Timetable-facing class requirement groups (one row per class+section+subject_study_format)';


-- -----------------------------------------------
-- [REQ-02] tt_class_requirement_subgroups  (was tt_class_requirement_subgroups — name unchanged)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_class_requirement_subgroups` (
  `id`                       INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `code`                     VARCHAR(50)   NOT NULL,
  `name`                     VARCHAR(100)  NOT NULL,
  `class_group_id`           INT UNSIGNED  NOT NULL,
  `class_id`                 INT UNSIGNED  NOT NULL,
  `section_id`               INT UNSIGNED  DEFAULT NULL,
  `subject_id`               INT UNSIGNED  NOT NULL,
  `study_format_id`          INT UNSIGNED  NOT NULL,
  `subject_type_id`          INT UNSIGNED  NOT NULL,
  `subject_study_format_id`  INT UNSIGNED  NOT NULL,
  `class_house_room_id`      INT UNSIGNED  NOT NULL,
  `student_count`            INT UNSIGNED  DEFAULT NULL,
  `eligible_teacher_count`   INT UNSIGNED  DEFAULT NULL,
  `is_shared_across_sections` TINYINT(1)  NOT NULL DEFAULT 0,
  `is_shared_across_classes`  TINYINT(1)  NOT NULL DEFAULT 0,
  `is_active`                TINYINT(1)    NOT NULL DEFAULT 1,
  `created_at`               TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`               TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`               TIMESTAMP     NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_clsReqSub_code`           (`code`),
  UNIQUE KEY `uq_clsReqSub_cls_sec_ssfmt`  (`class_id`, `section_id`, `subject_study_format_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Timetable-facing class requirement sub-groups (split groups sharing a subject)';


-- -----------------------------------------------
COMMENT='Teacher subject-teaching capability matrix with priority and strictness metadata';


-- -----------------------------------------------
COMMENT='Student master — identity and admission records';


-- =====================================================================
-- LAYER 5 — DEPEND ON LAYER 0-4
-- =====================================================================

-- -----------------------------------------------
-- [REQ-03] tt_requirement_consolidations  (was tt_requirement_consolidation)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_requirement_consolidations` (
  `id`                           INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `academic_term_id`             INT UNSIGNED     NOT NULL,
  `timetable_type_id`            INT UNSIGNED     NOT NULL,
  `class_requirement_group_id`   INT UNSIGNED     DEFAULT NULL,
  `class_requirement_subgroup_id` INT UNSIGNED    DEFAULT NULL,
  `class_id`                     INT UNSIGNED     NOT NULL,
  `section_id`                   INT UNSIGNED     DEFAULT NULL,
  `subject_id`                   INT UNSIGNED     NOT NULL,
  `study_format_id`              INT UNSIGNED     NOT NULL,
  `subject_type_id`              INT UNSIGNED     NOT NULL,
  `subject_study_format_id`      INT UNSIGNED     NOT NULL,
  `class_house_room_id`          INT UNSIGNED     NOT NULL,
  `student_count`                INT UNSIGNED     DEFAULT NULL,
  `eligible_teacher_count`       INT UNSIGNED     DEFAULT NULL,
  `is_compulsory`                TINYINT(1)       NOT NULL DEFAULT 1,
  `required_weekly_periods`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `min_periods_required_per_week` TINYINT UNSIGNED DEFAULT NULL,
  `max_periods_required_per_week` TINYINT UNSIGNED DEFAULT NULL,
  `min_periods_required_per_day` TINYINT UNSIGNED DEFAULT NULL,
  `max_periods_required_per_day` TINYINT UNSIGNED DEFAULT NULL,
  `min_gap_between_periods`      TINYINT UNSIGNED DEFAULT NULL,
  `required_consecutive_periods` TINYINT UNSIGNED DEFAULT NULL,
  `min_required_consecutive_periods` TINYINT UNSIGNED DEFAULT NULL,
  `allow_consecutive_periods`    TINYINT(1)       NOT NULL DEFAULT 0,
  `max_consecutive_periods`      TINYINT UNSIGNED DEFAULT 2,
  `class_priority_score`         TINYINT UNSIGNED DEFAULT NULL,
  `preferred_periods_json`       JSON             DEFAULT NULL,
  `avoid_periods_json`           JSON             DEFAULT NULL,
  `spread_evenly`                TINYINT(1)       DEFAULT 1,
  `is_shared_across_sections`    TINYINT(1)       NOT NULL DEFAULT 0,
  `is_shared_across_classes`     TINYINT(1)       NOT NULL DEFAULT 0,
  `compulsory_specific_room_type` TINYINT(1)      NOT NULL DEFAULT 0,
  `required_room_type_id`        INT UNSIGNED     NOT NULL,
  `required_room_id`             INT UNSIGNED     DEFAULT NULL,
  `is_active`                    TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_reqCon_term_type_group_sub` (`academic_term_id`, `timetable_type_id`, `class_requirement_group_id`, `class_requirement_subgroup_id`),
  CONSTRAINT `fk_reqCon_ttType`         FOREIGN KEY (`timetable_type_id`)            REFERENCES `tt_timetable_types`              (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_reqCon_clsReqGroup`    FOREIGN KEY (`class_requirement_group_id`)   REFERENCES `tt_class_requirement_groups`     (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reqCon_clsReqSubgroup` FOREIGN KEY (`class_requirement_subgroup_id`) REFERENCES `tt_class_requirement_subgroups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `chk_reqCon_target` CHECK (
    (`class_requirement_group_id` IS NOT NULL AND `class_requirement_subgroup_id` IS NULL) OR
    (`class_requirement_group_id` IS NULL AND `class_requirement_subgroup_id` IS NOT NULL)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Consolidated per-term timetable requirements for each class group or subgroup';


-- -----------------------------------------------
COMMENT='Student enrolment history per academic session — class, section, subject group';


-- =====================================================================
-- LAYER 6 — SLOT REQUIREMENTS & PRIORITY CONFIGS
-- =====================================================================

-- -----------------------------------------------
-- [REQ-04] tt_slot_requirements  (was tt_slot_requirement)
-- -----------------------------------------------
-- CIRCULAR FK NOTE: activity_id references tt_activities which is created in LAYER 7.
-- The FK constraint is intentionally omitted here. The column is kept and nullable.
-- Add the FK via ALTER TABLE after tt_activities is created if desired.
CREATE TABLE IF NOT EXISTS `tt_slot_requirements` (
  `id`                      INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `academic_term_id`        INT UNSIGNED     NOT NULL,
  `timetable_type_id`       INT UNSIGNED     NOT NULL,
  `class_timetable_type_id` INT UNSIGNED     NOT NULL,
  `class_id`                INT UNSIGNED     NOT NULL,
  `section_id`              INT UNSIGNED     NOT NULL,
  `class_house_room_id`     INT UNSIGNED     NOT NULL,
  `weekly_total_slots`      TINYINT UNSIGNED NOT NULL,
  `weekly_teaching_slots`   TINYINT UNSIGNED NOT NULL,
  `weekly_exam_slots`       TINYINT UNSIGNED NOT NULL,
  `weekly_free_slots`       TINYINT UNSIGNED NOT NULL,
  `activity_id`             INT UNSIGNED     NULL,   -- FK omitted (circular); add via ALTER after tt_activities is created
  `is_active`               TINYINT(1)       NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_slotReq_type_ctt_cls_sec` (`timetable_type_id`, `class_timetable_type_id`, `class_id`, `section_id`),
  CONSTRAINT `fk_slotReq_ttType`    FOREIGN KEY (`timetable_type_id`)       REFERENCES `tt_timetable_types`      (`id`),
  CONSTRAINT `fk_slotReq_cttj`      FOREIGN KEY (`class_timetable_type_id`) REFERENCES `tt_class_timetable_types`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Pre-computed weekly slot counts available per class+section for scheduling';


-- -----------------------------------------------
-- [PRE-01] tt_priority_configs  (was tt_priority_config)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_priority_configs` (
  `id`                             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `requirement_consolidation_id`   INT UNSIGNED NOT NULL,
  `tot_students`                   INT UNSIGNED DEFAULT NULL,
  `teacher_scarcity_index`         DECIMAL(7,2) UNSIGNED DEFAULT 1,
  `weekly_load_ratio`              DECIMAL(7,2) UNSIGNED DEFAULT 1,
  `average_teacher_availability_ratio` DECIMAL(7,2) UNSIGNED DEFAULT 1,
  `rigidity_score`                 DECIMAL(7,2) UNSIGNED DEFAULT 1,
  `resource_scarcity`              DECIMAL(7,2) UNSIGNED DEFAULT 1,
  `subject_difficulty_index`       DECIMAL(7,2) UNSIGNED DEFAULT 1,
  `is_active`                      TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_prioConfig_reqCon` FOREIGN KEY (`requirement_consolidation_id`) REFERENCES `tt_requirement_consolidations` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Computed priority scores for each requirement consolidation record';


-- =====================================================================
-- LAYER 7 — ACTIVITY TABLES
-- =====================================================================

-- -----------------------------------------------
-- [PRE-02] tt_activities  (was tt_activity)
-- -----------------------------------------------
-- FKs: sch_academic_terms, tt_timetable_types, sch_class_groups,
--      tt_class_requirement_subgroups — all in this file.
-- FK to sys_users (created_by) removed; column kept.
-- NOTE: class_group_id and class_subgroup_id map to sch_class_groups
--       and tt_class_requirement_subgroups respectively.
CREATE TABLE IF NOT EXISTS `tt_activities` (
  `id`                           INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `code`                         VARCHAR(50)      NOT NULL,
  `name`                         VARCHAR(200)     NOT NULL,
  `academic_term_id`             INT UNSIGNED     NOT NULL,
  `timetable_type_id`            INT UNSIGNED     NOT NULL,
  `activity_group_id`            INT UNSIGNED     DEFAULT NULL,
  `have_sub_activity`            TINYINT(1)       NOT NULL DEFAULT 0,
  `class_id`                     INT UNSIGNED     NOT NULL,
  `section_id`                   INT UNSIGNED     DEFAULT NULL,
  `subject_id`                   INT UNSIGNED     NOT NULL,
  `study_format_id`              INT UNSIGNED     NOT NULL,
  `subject_type_id`              INT UNSIGNED     NOT NULL,
  `subject_study_format_id`      INT UNSIGNED     NOT NULL,
  `required_weekly_periods`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `min_periods_per_week`         TINYINT UNSIGNED DEFAULT NULL,
  `max_periods_per_week`         TINYINT UNSIGNED DEFAULT NULL,
  `max_per_day`                  TINYINT UNSIGNED DEFAULT NULL,
  `min_per_day`                  TINYINT UNSIGNED DEFAULT NULL,
  `min_gap_periods`              TINYINT UNSIGNED DEFAULT NULL,
  `allow_consecutive`            TINYINT(1)       NOT NULL DEFAULT 0,
  `max_consecutive`              TINYINT UNSIGNED DEFAULT 2,
  `preferred_periods_json`       JSON             DEFAULT NULL,
  `avoid_periods_json`           JSON             DEFAULT NULL,
  `spread_evenly`                TINYINT(1)       DEFAULT 1,
  `eligible_teacher_count`       INT UNSIGNED     DEFAULT NULL,
  `min_teacher_availability_score` DECIMAL(7,2) UNSIGNED DEFAULT 1,
  `max_teacher_availability_score` DECIMAL(7,2) UNSIGNED DEFAULT 1,
  `duration_periods`             TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `weekly_periods`               TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `total_periods`                SMALLINT UNSIGNED GENERATED ALWAYS AS (`duration_periods` * `weekly_periods`) STORED,
  `split_allowed`                TINYINT(1)       DEFAULT 0,
  `is_compulsory`                TINYINT(1)       DEFAULT 1,
  `priority`                     TINYINT UNSIGNED DEFAULT 50,
  `difficulty_score`             TINYINT UNSIGNED DEFAULT 50,
  `compulsory_specific_room_type` TINYINT(1)      NOT NULL DEFAULT 0,
  `required_room_type_id`        INT UNSIGNED     NOT NULL,
  `required_room_id`             INT UNSIGNED     DEFAULT NULL,
  `requires_room`                TINYINT(1)       DEFAULT 1,
  `preferred_room_type_id`       INT UNSIGNED     DEFAULT NULL,
  `preferred_room_ids`           JSON             DEFAULT NULL,
  `difficulty_score_calculated`  TINYINT UNSIGNED DEFAULT 50  COMMENT 'Auto-calculated from constraints, teacher/room availability',
  `teacher_availability_score`   TINYINT UNSIGNED DEFAULT 100 COMMENT 'Available teacher percentage',
  `room_availability_score`      TINYINT UNSIGNED DEFAULT 100 COMMENT 'Available room percentage',
  `constraint_count`             SMALLINT UNSIGNED DEFAULT 0  COMMENT 'Number of constraints affecting this activity',
  `preferred_time_slots_json`    JSON             DEFAULT NULL COMMENT 'Preferred time slots from requirements',
  `avoid_time_slots_json`        JSON             DEFAULT NULL COMMENT 'Time slots to avoid from requirements',
  `status`                       ENUM('DRAFT','ACTIVE','LOCKED','ARCHIVED') NOT NULL DEFAULT 'ACTIVE',
  `is_active`                    TINYINT(1)       NOT NULL DEFAULT 1,
  `created_by`                   INT UNSIGNED     DEFAULT NULL,  -- column kept; FK to sys_users removed
  `created_at`                   TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                   TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`                   TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_activity_code` (`code`),
  INDEX `idx_activity_difficulty`  (`difficulty_score`, `constraint_count`),
  INDEX `idx_activity_term`        (`academic_term_id`),
  INDEX `idx_activity_classGroup`  (`activity_group_id`),
  INDEX `idx_activity_subject`     (`subject_id`),
  INDEX `idx_activity_status`      (`status`),
  INDEX `idx_activity_generation`  (`academic_term_id`, `difficulty_score`, `status`, `is_active`),
  CONSTRAINT `fk_activity_ttType`        FOREIGN KEY (`timetable_type_id`)       REFERENCES `tt_timetable_types`            (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Core scheduling unit — one row per class+subject+format combination per term';


-- -----------------------------------------------
-- [PRE-03] tt_sub_activities  (was tt_sub_activity)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_sub_activities` (
  `id`                       INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `parent_activity_id`       INT UNSIGNED     NOT NULL,
  `class_requirement_subgroup_id` INT UNSIGNED NOT NULL,
  `ordinal`                  TINYINT UNSIGNED NOT NULL,
  `class_id`                 INT UNSIGNED     NOT NULL,
  `section_id`               INT UNSIGNED     NOT NULL,
  `duration_periods`         TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `same_day_as_parent`       TINYINT(1)       DEFAULT 0,
  `consecutive_with_previous` TINYINT(1)      DEFAULT 0,
  `is_active`                TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`               TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`               TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`               TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subAct_parentOrd` (`parent_activity_id`, `ordinal`),
  KEY `idx_subAct_parent`          (`parent_activity_id`),
  CONSTRAINT `fk_subAct_parent`        FOREIGN KEY (`parent_activity_id`)          REFERENCES `tt_activities`               (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subAct_clsReqSubgroup` FOREIGN KEY (`class_requirement_subgroup_id`) REFERENCES `tt_class_requirement_subgroups` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Split sub-activities of a parent activity (e.g. lab split across sections)';


-- -----------------------------------------------
-- [PRE-04] tt_activity_priorities  (was tt_activity_priority)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_activity_priorities` (
  `id`               INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `activity_id`      INT UNSIGNED  NOT NULL,
  `priority_score`   DECIMAL(5,2)  NOT NULL,
  `priority_reason`  TEXT          DEFAULT NULL,
  `is_active`        TINYINT(1)    NOT NULL DEFAULT 1,
  `created_at`       TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`       TIMESTAMP     NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_actPriority_activityId` (`activity_id`),
  CONSTRAINT `fk_actPriority_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activities` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Computed priority score per activity for generation ordering';


-- -----------------------------------------------
-- [PRE-05] tt_activity_teachers  (was tt_activity_teacher)
-- -----------------------------------------------
-- FK to sch_teachers removed; teacher_id column kept.
CREATE TABLE IF NOT EXISTS `tt_activity_teachers` (
  `id`                 INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `activity_id`        INT UNSIGNED     NOT NULL,
  `teacher_id`         INT UNSIGNED     NOT NULL,   -- column kept; FK to sch_teachers removed
  `assignment_role_id` INT UNSIGNED     NOT NULL,
  `is_required`        TINYINT(1)       DEFAULT 1,
  `ordinal`            TINYINT UNSIGNED DEFAULT 1,
  `is_active`          TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`         TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`         TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`         TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_actTeacher_activityTeacher` (`activity_id`, `teacher_id`),
  KEY `idx_actTeacher_teacher`               (`teacher_id`),
  CONSTRAINT `fk_actTeacher_activity` FOREIGN KEY (`activity_id`)       REFERENCES `tt_activities`             (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_actTeacher_role`     FOREIGN KEY (`assignment_role_id`) REFERENCES `tt_teacher_assignment_roles` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Teacher assignments to activities with their role (PRIMARY, ASSISTANT, etc.)';


-- =====================================================================
-- LAYER 8 — RESOURCE AVAILABILITY
-- =====================================================================

-- -----------------------------------------------
-- [RES-01] tt_teacher_availabilities  (was tt_teacher_availability)
-- -----------------------------------------------
-- CIRCULAR FK NOTE: activity_id FK omitted (tt_activities created above, but
-- the original design has tt_teacher_availabilities feeding INTO activity creation).
-- Column kept, nullable. FK to sch_teacher_profiles kept (in this file).
-- FK to sys_users etc. removed.
CREATE TABLE IF NOT EXISTS `tt_teacher_availabilities` (
  `id`                             INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `requirement_consolidation_id`   INT UNSIGNED     NOT NULL,
  `class_id`                       INT UNSIGNED     NOT NULL,
  `section_id`                     INT UNSIGNED     DEFAULT NULL,
  `subject_study_format_id`        INT UNSIGNED     NOT NULL,
  `teacher_profile_id`             INT UNSIGNED     NOT NULL,
  `required_weekly_periods`        TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `is_full_time`                   TINYINT(1)       DEFAULT 1,
  `preferred_shift`                INT UNSIGNED     DEFAULT NULL,
  `capable_handling_multiple_classes` TINYINT(1)   DEFAULT 0,
  `can_be_used_for_substitution`   TINYINT(1)       DEFAULT 1,
  `certified_for_lab`              TINYINT(1)       DEFAULT 0,
  `max_available_periods_weekly`   TINYINT UNSIGNED DEFAULT 48,
  `min_available_periods_weekly`   TINYINT UNSIGNED DEFAULT 36,
  `max_allocated_periods_weekly`   TINYINT UNSIGNED DEFAULT 1,
  `min_allocated_periods_weekly`   TINYINT UNSIGNED DEFAULT 1,
  `can_be_split_across_sections`   TINYINT(1)       DEFAULT 0,
  `proficiency_percentage`         TINYINT UNSIGNED DEFAULT NULL,
  `teaching_experience_months`     SMALLINT UNSIGNED DEFAULT NULL,
  `is_primary_subject`             TINYINT(1)       NOT NULL DEFAULT 1,
  `competancy_level`               ENUM('Facilitator','Basic','Intermediate','Advanced','Expert') DEFAULT 'Basic',
  `priority_order`                 INT UNSIGNED     DEFAULT NULL,
  `priority_weight`                TINYINT UNSIGNED DEFAULT NULL,
  `scarcity_index`                 TINYINT UNSIGNED DEFAULT NULL,
  `is_hard_constraint`             TINYINT(1)       DEFAULT 0,
  `allocation_strictness`          ENUM('Hard','Medium','Soft') DEFAULT 'Medium',
  `override_priority`              TINYINT UNSIGNED DEFAULT NULL,
  `override_reason`                VARCHAR(255)     DEFAULT NULL,
  `historical_success_ratio`       TINYINT UNSIGNED DEFAULT NULL,
  `last_allocation_score`          TINYINT UNSIGNED DEFAULT NULL,
  `is_primary_teacher`             TINYINT(1)       NOT NULL DEFAULT 1,
  `is_preferred_teacher`           TINYINT(1)       NOT NULL DEFAULT 0,
  `preference_score`               TINYINT UNSIGNED DEFAULT NULL,
  `teacher_profile_from_date`      DATE             DEFAULT NULL,
  `teacher_profile_to_date`        DATE             DEFAULT NULL,
  `teacher_available_from_date`    DATE             DEFAULT NULL,
  `timetable_start_date`           DATE             DEFAULT NULL,
  `timetable_end_date`             DATE             DEFAULT NULL,
  `available_for_full_timetable_duration` TINYINT(1) AS (IF(`teacher_available_from_date` <= `timetable_start_date`, 1, 0)) STORED,
  `no_of_days_not_available`       INT AS (GREATEST(0, DATEDIFF(`teacher_available_from_date`, `timetable_start_date`))) STORED,
  `min_teacher_availability_score` DECIMAL(7,2) UNSIGNED DEFAULT 1,
  `max_teacher_availability_score` DECIMAL(7,2) UNSIGNED DEFAULT 1,
  `activity_id`                    INT UNSIGNED     NULL,   -- FK omitted (circular); add via ALTER after use
  `is_active`                      TINYINT(1)       NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_teacherAvail_reqTeacher` (`requirement_consolidation_id`, `teacher_profile_id`),
  CONSTRAINT `fk_teacherAvail_reqCon`       FOREIGN KEY (`requirement_consolidation_id`) REFERENCES `tt_requirement_consolidations` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Teacher availability matrix per requirement — feeds activity assignment';


-- -----------------------------------------------
-- [RES-02] tt_teacher_availability_details  (was tt_teacher_availability_detail)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_teacher_availability_details` (
  `id`                              INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `teacher_availability_id`         INT UNSIGNED     NOT NULL,
  `teacher_profile_id`              INT UNSIGNED     NOT NULL,
  `day_number`                      TINYINT UNSIGNED NOT NULL,
  `day_name`                        VARCHAR(10)      NOT NULL,
  `period_number`                   TINYINT UNSIGNED NOT NULL,
  `can_be_assigned`                 TINYINT(1)       NOT NULL DEFAULT 1,
  `availability_for_period`         ENUM('Available','Unavailable','Assigned','Free Period') NOT NULL DEFAULT 'Available',
  `assigned_class_id`               INT UNSIGNED     DEFAULT NULL,
  `assigned_section_id`             INT UNSIGNED     DEFAULT NULL,
  `assigned_subject_study_format_id` INT UNSIGNED    DEFAULT NULL,
  `teacher_available_from_date`     DATE             DEFAULT NULL,
  `activity_id`                     INT UNSIGNED     NULL,   -- FK omitted (circular)
  `is_active`                       TINYINT(1)       NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_teacherAvailDtl_profile_day_period` (`teacher_profile_id`, `day_number`, `period_number`),
  CONSTRAINT `fk_teacherAvailDtl_availability` FOREIGN KEY (`teacher_availability_id`)        REFERENCES `tt_teacher_availabilities`  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Day-period level teacher availability detail records';


-- -----------------------------------------------
-- [RES-03] tt_room_availabilities  (was tt_room_availability)
-- -----------------------------------------------
-- CIRCULAR FK NOTE: activity_id FK omitted.
-- Multiple orphaned FK columns (class_id, section_id, subject_study_format_id,
-- room_type_id, start_time, end_time) were referenced in original constraints
-- but not declared as columns — those constraint clauses are dropped.
CREATE TABLE IF NOT EXISTS `tt_room_availabilities` (
  `id`                              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `room_id`                         INT UNSIGNED  NOT NULL,
  `rooms_type_id`                   INT UNSIGNED  NOT NULL,
  `total_rooms_in_category`         SMALLINT UNSIGNED NOT NULL,
  `can_be_assigned`                 TINYINT(1)    NOT NULL DEFAULT 1,
  `overall_availability_status`     ENUM('Available','Unavailable','Partially Available','Assigned') NOT NULL DEFAULT 'Available',
  `available_for_full_timetable_duration` TINYINT(1) NOT NULL DEFAULT 1,
  `is_class_house_room`             TINYINT(1)    NOT NULL DEFAULT 0,
  `house_room_class_id`             INT UNSIGNED  NULL,
  `house_room_section_id`           INT UNSIGNED  NULL,
  `activity_id`                     INT UNSIGNED  NULL,   -- FK omitted (circular)
  `capacity`                        INT UNSIGNED  DEFAULT NULL,
  `max_limit`                       INT UNSIGNED  DEFAULT NULL,
  `can_be_assigned_for_lecture`     TINYINT(1)    NOT NULL DEFAULT 1,
  `can_be_assigned_for_practical`   TINYINT(1)    NOT NULL DEFAULT 1,
  `can_be_assigned_for_exam`        TINYINT(1)    NOT NULL DEFAULT 1,
  `can_be_assigned_for_activity`    TINYINT(1)    NOT NULL DEFAULT 1,
  `can_be_assigned_for_sports`      TINYINT(1)    NOT NULL DEFAULT 1,
  `timetable_start_time`            TIME          NOT NULL,
  `timetable_end_time`              TIME          NOT NULL,
  `is_active`                       TINYINT(1)    NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  CONSTRAINT `chk_roomAvail_houseLogic` CHECK (
    (`is_class_house_room` = 1 AND `house_room_class_id` IS NOT NULL AND `house_room_section_id` IS NOT NULL) OR
    (`is_class_house_room` = 0)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Aggregate room availability status used by the scheduling engine';


-- -----------------------------------------------
-- [RES-04] tt_room_availability_details  (was tt_room_availability_detail)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_room_availability_details` (
  `id`                              INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `room_availability_id`            INT UNSIGNED     NOT NULL,
  `room_id`                         INT UNSIGNED     NOT NULL,
  `room_type_id`                    INT UNSIGNED     NOT NULL,
  `day_number`                      TINYINT UNSIGNED NOT NULL,
  `day_name`                        VARCHAR(10)      NOT NULL,
  `period_number`                   TINYINT UNSIGNED NOT NULL,
  `availability_for_period`         ENUM('Available','Unavailable','Assigned') NOT NULL DEFAULT 'Available',
  `assigned_class_id`               INT UNSIGNED     NOT NULL,
  `assigned_section_id`             INT UNSIGNED     DEFAULT NULL,
  `assigned_subject_study_format_id` INT UNSIGNED    NOT NULL,
  `room_available_from_date`        DATE             DEFAULT NULL,
  `activity_id`                     INT UNSIGNED     NULL,   -- FK omitted (circular)
  `is_active`                       TINYINT(1)       NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_roomAvailDtl_availability` FOREIGN KEY (`room_availability_id`)           REFERENCES `tt_room_availabilities`   (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Day-period level room availability detail records';


-- =====================================================================
-- LAYER 9 — TIMETABLE GENERATION & STORAGE
-- =====================================================================

-- -----------------------------------------------
-- [GEN-01] tt_timetables  (was tt_timetable)
-- -----------------------------------------------
-- FK to sys_users (published_by, created_by) removed; columns kept.
CREATE TABLE IF NOT EXISTS `tt_timetables` (
  `id`                        INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `code`                      VARCHAR(50)      NOT NULL,
  `name`                      VARCHAR(200)     NOT NULL,
  `description`               TEXT             DEFAULT NULL,
  `academic_session_id`       INT UNSIGNED     NOT NULL,
  `academic_term_id`          INT UNSIGNED     NOT NULL,
  `timetable_type_id`         INT UNSIGNED     NOT NULL,
  `period_set_id`             INT UNSIGNED     NOT NULL,
  `effective_from`            DATE             NOT NULL,
  `effective_to`              DATE             DEFAULT NULL,
  `generation_method`         ENUM('MANUAL','SEMI_AUTO','FULL_AUTO') NOT NULL DEFAULT 'MANUAL',
  `generation_strategy_id`    INT UNSIGNED     DEFAULT NULL,
  `version`                   SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `parent_timetable_id`       INT UNSIGNED     DEFAULT NULL,
  `status`                    ENUM('DRAFT','GENERATING','GENERATED','PUBLISHED','ARCHIVED') NOT NULL DEFAULT 'DRAFT',
  `published_at`              TIMESTAMP        NULL,
  `published_by`              INT UNSIGNED     DEFAULT NULL,   -- column kept; FK to sys_users removed
  `last_optimized_at`         TIMESTAMP        NULL,
  `optimization_cycles`       INT UNSIGNED     DEFAULT 0,
  `constraint_violations`     INT UNSIGNED     DEFAULT 0,
  `soft_score`                DECIMAL(8,2)     DEFAULT NULL,
  `quality_score`             DECIMAL(5,2)     DEFAULT NULL COMMENT 'Overall quality score 0-100',
  `teacher_satisfaction_score` DECIMAL(5,2)    DEFAULT NULL COMMENT 'Teacher preference satisfaction score',
  `room_utilization_score`    DECIMAL(5,2)     DEFAULT NULL COMMENT 'Room utilization efficiency score',
  `stats_json`                JSON             DEFAULT NULL,
  `is_active`                 TINYINT(1)       NOT NULL DEFAULT 1,
  `created_by`                INT UNSIGNED     DEFAULT NULL,   -- column kept; FK to sys_users removed
  `created_at`                TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`                TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_timetable_code` (`code`),
  KEY `idx_timetable_session`    (`academic_session_id`),
  KEY `idx_timetable_type`       (`timetable_type_id`),
  KEY `idx_timetable_status`     (`status`),
  KEY `idx_timetable_effective`  (`effective_from`, `effective_to`),
  CONSTRAINT `fk_timetable_type`       FOREIGN KEY (`timetable_type_id`)     REFERENCES `tt_timetable_types`        (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_timetable_periodSet`  FOREIGN KEY (`period_set_id`)         REFERENCES `tt_period_sets`            (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_timetable_strategy`   FOREIGN KEY (`generation_strategy_id`) REFERENCES `tt_generation_strategies` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_timetable_parent`     FOREIGN KEY (`parent_timetable_id`)   REFERENCES `tt_timetables`             (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Timetable header — one record per published or draft timetable version';


-- -----------------------------------------------
-- [GEN-02] tt_generation_runs  (was tt_generation_run)
-- -----------------------------------------------
-- FK to sys_users (triggered_by) removed; column kept.
CREATE TABLE IF NOT EXISTS `tt_generation_runs` (
  `id`                      INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `timetable_id`            INT UNSIGNED     NOT NULL,
  `run_number`              INT UNSIGNED     NOT NULL DEFAULT 1,
  `started_at`              TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `finished_at`             TIMESTAMP        NULL,
  `status`                  ENUM('QUEUED','RUNNING','COMPLETED','FAILED','CANCELLED') NOT NULL DEFAULT 'QUEUED',
  `strategy_id`             INT UNSIGNED     DEFAULT NULL,
  `algorithm_version`       VARCHAR(20)      DEFAULT NULL,
  `max_recursion_depth`     INT UNSIGNED     DEFAULT 14,
  `max_placement_attempts`  INT UNSIGNED     DEFAULT NULL,
  `retry_count`             TINYINT UNSIGNED DEFAULT 0,
  `params_json`             JSON             DEFAULT NULL,
  `activities_total`        INT UNSIGNED     DEFAULT 0,
  `activities_placed`       INT UNSIGNED     DEFAULT 0,
  `activities_failed`       INT UNSIGNED     DEFAULT 0,
  `hard_violations`         INT UNSIGNED     DEFAULT 0,
  `soft_violations`         INT UNSIGNED     DEFAULT 0,
  `soft_score`              DECIMAL(10,4)    DEFAULT NULL,
  `stats_json`              JSON             DEFAULT NULL,
  `error_message`           TEXT             DEFAULT NULL,
  `triggered_by`            INT UNSIGNED     DEFAULT NULL,  -- column kept; FK to sys_users removed
  `created_at`              TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`              TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_genRun_ttRun` (`timetable_id`, `run_number`),
  KEY `idx_genRun_status`      (`status`),
  CONSTRAINT `fk_genRun_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables`          (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_genRun_strategy` FOREIGN KEY (`strategy_id`)   REFERENCES `tt_generation_strategies` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Each attempt to auto-generate a timetable — tracks progress and scoring';


-- -----------------------------------------------
-- [GEN-03] tt_conflict_detections  (was tt_conflict_detection)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_conflict_detections` (
  `id`                          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `timetable_id`                INT UNSIGNED NOT NULL,
  `detection_type`              ENUM('REAL_TIME','BATCH','VALIDATION','GENERATION') NOT NULL,
  `detected_at`                 TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  `conflict_count`              INT UNSIGNED DEFAULT 0,
  `hard_conflicts`              INT UNSIGNED DEFAULT 0,
  `soft_conflicts`              INT UNSIGNED DEFAULT 0,
  `conflicts_json`              JSON         DEFAULT NULL,
  `resolution_suggestions_json` JSON         DEFAULT NULL,
  `resolved_at`                 TIMESTAMP    NULL,
  `is_active`                   TINYINT(1)   DEFAULT 1,
  `created_at`                  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_conflictDet_timetable` (`timetable_id`, `detected_at`),
  CONSTRAINT `fk_conflictDet_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Log of conflict detection events and their resolution suggestions';


-- -----------------------------------------------
-- [GEN-04] tt_resource_bookings  (was tt_resource_booking)
-- -----------------------------------------------
-- FK to sch_teachers removed; supervisor_id column kept.
CREATE TABLE IF NOT EXISTS `tt_resource_bookings` (
  `id`              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `resource_type`   ENUM('ROOM','LAB','TEACHER','EQUIPMENT','SPORTS','SPECIAL') NOT NULL,
  `resource_id`     INT UNSIGNED  NOT NULL,
  `booking_date`    DATE          NOT NULL,
  `day_of_week`     TINYINT UNSIGNED DEFAULT NULL,
  `period_ord`      TINYINT UNSIGNED DEFAULT NULL,
  `start_time`      TIME          DEFAULT NULL,
  `end_time`        TIME          DEFAULT NULL,
  `booked_for_type` ENUM('ACTIVITY','EXAM','EVENT','MAINTENANCE') NOT NULL,
  `booked_for_id`   INT UNSIGNED  NOT NULL,
  `purpose`         VARCHAR(500)  DEFAULT NULL,
  `supervisor_id`   INT UNSIGNED  DEFAULT NULL,   -- column kept; FK to sch_teachers removed
  `status`          ENUM('BOOKED','IN_USE','COMPLETED','CANCELLED') DEFAULT 'BOOKED',
  `is_active`       TINYINT UNSIGNED DEFAULT 1,
  `created_at`      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_resourceBook_dateType` (`booking_date`, `resource_type`, `resource_id`),
  INDEX `idx_resourceBook_time`     (`start_time`, `end_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Resource booking and allocation tracking for rooms, labs, teachers, equipment';


-- -----------------------------------------------
-- [GEN-05] tt_constraint_violations  (was tt_constraint_violation)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS `tt_constraint_violations` (
  `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `timetable_id`      INT UNSIGNED NOT NULL,
  `constraint_id`     INT UNSIGNED NOT NULL,
  `violation_type`    ENUM('HARD','SOFT') NOT NULL,
  `violation_count`   INT UNSIGNED NOT NULL,
  `violation_details` JSON         DEFAULT NULL,
  `created_at`        TIMESTAMP    NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP    NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_conViolation_timetable`  (`timetable_id`),
  KEY `idx_conViolation_constraint` (`constraint_id`),
  CONSTRAINT `fk_conViolation_timetable`  FOREIGN KEY (`timetable_id`)  REFERENCES `tt_timetables`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_conViolation_constraint` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraints` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Records of constraint violations found in a generated timetable';


-- -----------------------------------------------
-- [GEN-06] tt_timetable_cells  (was tt_timetable_cell)
-- -----------------------------------------------
-- FK to sys_users (locked_by) removed; column kept.
-- FK to sch_rooms kept (in this file).
CREATE TABLE IF NOT EXISTS `tt_timetable_cells` (
  `id`                   INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `timetable_id`         INT UNSIGNED     NOT NULL,
  `generation_run_id`    INT UNSIGNED     DEFAULT NULL,
  `day_of_week`          TINYINT UNSIGNED NOT NULL,
  `period_ord`           TINYINT UNSIGNED NOT NULL,
  `cell_date`            DATE             DEFAULT NULL,
  `class_group_id`       INT UNSIGNED     DEFAULT NULL,
  `class_subgroup_id`    INT UNSIGNED     DEFAULT NULL,
  `activity_id`          INT UNSIGNED     DEFAULT NULL,
  `sub_activity_id`      INT UNSIGNED     DEFAULT NULL,
  `room_id`              INT UNSIGNED     DEFAULT NULL,
  `source`               ENUM('AUTO','MANUAL','SWAP','LOCK') NOT NULL DEFAULT 'AUTO',
  `is_locked`            TINYINT(1)       NOT NULL DEFAULT 0,
  `locked_by`            INT UNSIGNED     DEFAULT NULL,   -- column kept; FK to sys_users removed
  `locked_at`            TIMESTAMP        NULL,
  `has_conflict`         TINYINT(1)       DEFAULT 0,
  `conflict_details_json` JSON            DEFAULT NULL,
  `is_active`            TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`           TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`           TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ttCell_tt_day_period_grp` (`timetable_id`, `day_of_week`, `period_ord`, `class_group_id`, `class_subgroup_id`),
  KEY `idx_ttCell_timetable`  (`timetable_id`),
  KEY `idx_ttCell_dayPeriod`  (`day_of_week`, `period_ord`),
  KEY `idx_ttCell_activity`   (`activity_id`),
  KEY `idx_ttCell_room`       (`room_id`),
  KEY `idx_ttCell_date`       (`cell_date`),
  CONSTRAINT `fk_ttCell_timetable`   FOREIGN KEY (`timetable_id`)      REFERENCES `tt_timetables`               (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ttCell_genRun`      FOREIGN KEY (`generation_run_id`) REFERENCES `tt_generation_runs`          (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ttCell_subgroup`    FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_requirement_subgroups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ttCell_activity`    FOREIGN KEY (`activity_id`)       REFERENCES `tt_activities`               (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ttCell_subActivity` FOREIGN KEY (`sub_activity_id`)   REFERENCES `tt_sub_activities`           (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_ttCell_target` CHECK (
    (`class_group_id` IS NOT NULL AND `class_subgroup_id` IS NULL) OR
    (`class_group_id` IS NULL AND `class_subgroup_id` IS NOT NULL)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Individual timetable slots — the final grid of scheduled activities';


-- -----------------------------------------------
-- [GEN-07] tt_timetable_cell_teachers  (was tt_timetable_cell_teacher)
-- -----------------------------------------------
-- FK to sch_teachers removed; teacher_id column kept.
CREATE TABLE IF NOT EXISTS `tt_timetable_cell_teachers` (
  `id`                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cell_id`            INT UNSIGNED NOT NULL,
  `teacher_id`         INT UNSIGNED NOT NULL,  -- column kept; FK to sch_teachers removed
  `assignment_role_id` INT UNSIGNED NOT NULL,
  `is_substitute`      TINYINT(1)   DEFAULT 0,
  `is_active`          TINYINT(1)   NOT NULL DEFAULT 1,
  `created_at`         TIMESTAMP    NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`         TIMESTAMP    NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`         TIMESTAMP    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ttCellTeacher_cellTeacher` (`cell_id`, `teacher_id`),
  KEY `idx_ttCellTeacher_teacher`           (`teacher_id`),
  CONSTRAINT `fk_ttCellTeacher_cell` FOREIGN KEY (`cell_id`)            REFERENCES `tt_timetable_cells`        (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ttCellTeacher_role` FOREIGN KEY (`assignment_role_id`) REFERENCES `tt_teacher_assignment_roles` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Teachers assigned to individual timetable cell slots';


-- =====================================================================
-- LAYER 10 — ANALYTICS, AUDIT & SUBSTITUTION
-- =====================================================================

-- -----------------------------------------------
-- [RPT-01] tt_teacher_workloads  (was tt_teacher_workload)
-- -----------------------------------------------
-- FK to sch_teachers removed; teacher_id column kept.
CREATE TABLE IF NOT EXISTS `tt_teacher_workloads` (
  `id`                       INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `teacher_id`               INT UNSIGNED     NOT NULL,   -- column kept; FK to sch_teachers removed
  `academic_session_id`      INT UNSIGNED     NOT NULL,
  `timetable_id`             INT UNSIGNED     DEFAULT NULL,
  `weekly_periods_assigned`  SMALLINT UNSIGNED DEFAULT 0,
  `weekly_periods_max`       SMALLINT UNSIGNED DEFAULT NULL,
  `weekly_periods_min`       SMALLINT UNSIGNED DEFAULT NULL,
  `daily_distribution_json`  JSON             DEFAULT NULL,
  `subjects_assigned_json`   JSON             DEFAULT NULL,
  `classes_assigned_json`    JSON             DEFAULT NULL,
  `utilization_percent`      DECIMAL(5,2)     DEFAULT NULL,
  `gap_periods_total`        SMALLINT UNSIGNED DEFAULT 0,
  `consecutive_max`          TINYINT UNSIGNED DEFAULT 0,
  `last_calculated_at`       TIMESTAMP        NULL,
  `is_active`                TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`               TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`               TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`               TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_teacherWorkload_teacher_session_tt` (`teacher_id`, `academic_session_id`, `timetable_id`),
  KEY `idx_teacherWorkload_session` (`academic_session_id`),
  CONSTRAINT `fk_teacherWorkload_timetable` FOREIGN KEY (`timetable_id`)        REFERENCES `tt_timetables`            (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Pre-computed weekly workload analytics per teacher per timetable';


-- -----------------------------------------------
-- [AUD-01] tt_change_logs  (was tt_change_log)
-- -----------------------------------------------
-- FK to sys_users (changed_by) removed; column kept.
CREATE TABLE IF NOT EXISTS `tt_change_logs` (
  `id`              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `timetable_id`    INT UNSIGNED  NOT NULL,
  `cell_id`         INT UNSIGNED  DEFAULT NULL,
  `change_type`     ENUM('CREATE','UPDATE','DELETE','LOCK','UNLOCK','SWAP','SUBSTITUTE') NOT NULL,
  `change_date`     DATE          NOT NULL,
  `old_values_json` JSON          DEFAULT NULL,
  `new_values_json` JSON          DEFAULT NULL,
  `reason`          VARCHAR(500)  DEFAULT NULL,
  `changed_by`      INT UNSIGNED  DEFAULT NULL,  -- column kept; FK to sys_users removed
  `created_at`      TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`      TIMESTAMP     NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_changeLog_timetable` (`timetable_id`),
  KEY `idx_changeLog_cell`      (`cell_id`),
  KEY `idx_changeLog_date`      (`change_date`),
  KEY `idx_changeLog_type`      (`change_type`),
  CONSTRAINT `fk_changeLog_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables`      (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_changeLog_cell`      FOREIGN KEY (`cell_id`)      REFERENCES `tt_timetable_cells` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Audit log for all manual and automated changes to timetable cells';


-- -----------------------------------------------
-- [SUB-01] tt_teacher_absences  (was tt_teacher_absence)
-- -----------------------------------------------
-- FK to sch_teachers removed; teacher_id column kept.
-- FK to sys_users removed; approved_by, created_by columns kept.
CREATE TABLE IF NOT EXISTS `tt_teacher_absences` (
  `id`                      INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `teacher_id`              INT UNSIGNED     NOT NULL,   -- column kept; FK to sch_teachers removed
  `absence_date`            DATE             NOT NULL,
  `absence_type`            ENUM('LEAVE','SICK','TRAINING','OFFICIAL_DUTY','OTHER') NOT NULL,
  `start_period`            TINYINT UNSIGNED DEFAULT NULL,
  `end_period`              TINYINT UNSIGNED DEFAULT NULL,
  `reason`                  VARCHAR(500)     DEFAULT NULL,
  `status`                  ENUM('PENDING','APPROVED','REJECTED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  `approved_by`             INT UNSIGNED     DEFAULT NULL,  -- column kept; FK to sys_users removed
  `approved_at`             TIMESTAMP        NULL,
  `substitution_required`   TINYINT(1)       DEFAULT 1,
  `substitution_completed`  TINYINT(1)       DEFAULT 0,
  `is_active`               TINYINT(1)       NOT NULL DEFAULT 1,
  `created_by`              INT UNSIGNED     DEFAULT NULL,  -- column kept; FK to sys_users removed
  `created_at`              TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              TIMESTAMP        NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`              TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_teacherAbsence_teacherDate` (`teacher_id`, `absence_date`),
  KEY `idx_teacherAbsence_date`   (`absence_date`),
  KEY `idx_teacherAbsence_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Teacher absence records triggering substitution workflow';


-- -----------------------------------------------
-- [SUB-02] tt_substitution_logs  (was tt_substitution_log)
-- -----------------------------------------------
-- FK to sch_teachers removed; teacher_id columns kept.
-- FK to sys_users (assigned_by) removed; column kept.
CREATE TABLE IF NOT EXISTS `tt_substitution_logs` (
  `id`                      INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `teacher_absence_id`      INT UNSIGNED  DEFAULT NULL,
  `cell_id`                 INT UNSIGNED  NOT NULL,
  `substitution_date`       DATE          NOT NULL,
  `absent_teacher_id`       INT UNSIGNED  NOT NULL,    -- column kept; FK to sch_teachers removed
  `substitute_teacher_id`   INT UNSIGNED  NOT NULL,    -- column kept; FK to sch_teachers removed
  `assignment_method`       ENUM('AUTO','MANUAL','SWAP') NOT NULL DEFAULT 'MANUAL',
  `reason`                  VARCHAR(500)  DEFAULT NULL,
  `status`                  ENUM('ASSIGNED','COMPLETED','CANCELLED') NOT NULL DEFAULT 'ASSIGNED',
  `notified_at`             TIMESTAMP     NULL,
  `accepted_at`             TIMESTAMP     NULL,
  `completed_at`            TIMESTAMP     NULL,
  `feedback`                TEXT          DEFAULT NULL,
  `assigned_by`             INT UNSIGNED  DEFAULT NULL,   -- column kept; FK to sys_users removed
  `is_active`               TINYINT(1)    NOT NULL DEFAULT 1,
  `created_at`              TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`              TIMESTAMP     NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_subLog_date`      (`substitution_date`),
  KEY `idx_subLog_absent`    (`absent_teacher_id`),
  KEY `idx_subLog_substitute` (`substitute_teacher_id`),
  KEY `idx_subLog_status`    (`status`),
  CONSTRAINT `fk_subLog_absence` FOREIGN KEY (`teacher_absence_id`) REFERENCES `tt_teacher_absences`  (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_subLog_cell`    FOREIGN KEY (`cell_id`)            REFERENCES `tt_timetable_cells`   (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

COMMENT='Substitution audit log — links absent teacher, substitute, and cell';


-- =====================================================================
-- POST-CREATION: ADD FK for sch_board_organizations → sch_org_academic_sessions
-- (deferred because sch_board_organizations was created in LAYER 0 before
--  sch_org_academic_sessions existed in that same layer — reordered above
--  so this ALTER is no longer needed, but kept as documentation)
-- =====================================================================


-- =====================================================================
-- OPTIONAL: Deferred FKs for circular activity_id references
-- Run these AFTER verifying all data is consistent.
-- =====================================================================
-- ALTER TABLE `tt_slot_requirements`
--   ADD CONSTRAINT `fk_slotReq_activity`
--     FOREIGN KEY (`activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE SET NULL;

-- ALTER TABLE `tt_teacher_availabilities`
--   ADD CONSTRAINT `fk_teacherAvail_activity`
--     FOREIGN KEY (`activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE SET NULL;

-- ALTER TABLE `tt_teacher_availability_details`
--   ADD CONSTRAINT `fk_teacherAvailDtl_activity`
--     FOREIGN KEY (`activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE SET NULL;

-- ALTER TABLE `tt_room_availabilities`
--   ADD CONSTRAINT `fk_roomAvail_activity`
--     FOREIGN KEY (`activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE SET NULL;

-- ALTER TABLE `tt_room_availability_details`
--   ADD CONSTRAINT `fk_roomAvailDtl_activity`
--     FOREIGN KEY (`activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE SET NULL;

-- =====================================================================
-- END OF tt_timetable_ddl_v8.0.sql
-- =====================================================================