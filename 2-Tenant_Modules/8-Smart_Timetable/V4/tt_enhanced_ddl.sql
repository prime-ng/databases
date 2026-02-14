-- SCHEMA REFINEMENTS & ENHANCEMENTS
-- ---------------------------------
--
-- 1. CRITICAL FIXES - Current Schema Issues
-- -----------------------------------------

-- FIX 1: Add missing columns in sch_teacher_capabilities (referenced in unique constraint)
ALTER TABLE `sch_teacher_capabilities` 
ADD COLUMN `section_id` INT UNSIGNED DEFAULT NULL AFTER `class_id`,
ADD COLUMN `subject_id` INT UNSIGNED NOT NULL AFTER `section_id`,
ADD COLUMN `study_format_id` INT UNSIGNED NOT NULL AFTER `subject_id`,
ADD FOREIGN KEY (`section_id`) REFERENCES `sch_sections`(`id`),
ADD FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects`(`id`),
ADD FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats`(`id`);

-- FIX 2: Fix unique constraint in tt_teacher_availability (remove start_time/end_time)
ALTER TABLE `tt_teacher_availability` 
DROP INDEX `uq_ta_class_wise`,
ADD UNIQUE KEY `uq_ta_requirement_teacher` (`requirement_consolidation_id`, `teacher_profile_id`);

-- 2. PERFORMANCE OPTIMIZATION TABLES
-- ----------------------------------
-- TABLE: tt_generation_queue (For async processing)
CREATE TABLE `tt_generation_queue` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` BINARY(16) NOT NULL,
    `timetable_id` INT UNSIGNED NOT NULL,
    `priority` TINYINT UNSIGNED DEFAULT 5,  -- 1-10, 1=highest
    `status` ENUM('PENDING','PROCESSING','COMPLETED','FAILED','CANCELLED') DEFAULT 'PENDING',
    `attempts` TINYINT UNSIGNED DEFAULT 0,
    `max_attempts` TINYINT UNSIGNED DEFAULT 3,
    `scheduled_at` TIMESTAMP NULL,
    `started_at` TIMESTAMP NULL,
    `completed_at` TIMESTAMP NULL,
    `error_message` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_gen_queue_uuid` (`uuid`),
    INDEX `idx_gen_queue_status` (`status`, `priority`, `scheduled_at`),
    CONSTRAINT `fk_gen_queue_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable`(`id`)
) ENGINE=InnoDB COMMENT='Async generation queue for parallel processing';

-- TABLE: tt_algorithm_state (For genetic/tabu algorithm state)
CREATE TABLE `tt_algorithm_state` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `generation_run_id` INT UNSIGNED NOT NULL,
    `iteration` INT UNSIGNED NOT NULL,
    `best_score` DECIMAL(10,4) NULL,
    `current_score` DECIMAL(10,4) NULL,
    `temperature` DECIMAL(10,4) NULL,  -- For simulated annealing
    `population_json` JSON NULL,        -- For genetic algorithms
    `tabu_list_json` JSON NULL,         -- For tabu search
    `state_snapshot` LONGBLOB NULL,     -- Compressed algorithm state
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_algo_run` (`generation_run_id`, `iteration`),
    CONSTRAINT `fk_algo_run` FOREIGN KEY (`generation_run_id`) REFERENCES `tt_generation_run`(`id`)
) ENGINE=InnoDB COMMENT='Stores algorithm state for resumable generation';

-- TABLE: tt_conflict_resolution (For AI-powered conflict resolution)
CREATE TABLE `tt_conflict_resolution` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `conflict_id` INT UNSIGNED NOT NULL,
    `resolution_type` ENUM('AUTO_SUGGESTED','MANUAL','RULE_BASED','AI_GENERATED') NOT NULL,
    `suggestion_json` JSON NOT NULL,
    `applied` TINYINT(1) DEFAULT 0,
    `success_rate` DECIMAL(5,2) NULL,  -- How often this resolution works
    `applied_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_conflict_resolution` (`conflict_id`, `applied`),
    CONSTRAINT `fk_conflict_resolution` FOREIGN KEY (`conflict_id`) REFERENCES `tt_constraint_violation`(`id`)
) ENGINE=InnoDB COMMENT='Stores conflict resolution patterns for ML learning';

-- 3. PREDICTIVE SUBSTITUTION TABLES
-- ---------------------------------

-- TABLE: tt_substitution_pattern (ML training data)
CREATE TABLE `tt_substitution_pattern` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_term_id` INT UNSIGNED NOT NULL,
    `subject_study_format_id` INT UNSIGNED NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,
    `primary_teacher_id` INT UNSIGNED NOT NULL,
    `substitute_teacher_id` INT UNSIGNED NOT NULL,
    `absence_reason` VARCHAR(100) NULL,
    `day_of_week` TINYINT UNSIGNED NOT NULL,
    `period_ord` TINYINT UNSIGNED NOT NULL,
    `substitution_success` TINYINT(1) DEFAULT 1,
    `student_feedback` DECIMAL(3,2) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_sub_pattern` (`subject_study_format_id`, `class_id`, `primary_teacher_id`),
    CONSTRAINT `fk_sub_pattern_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term`(`id`),
    CONSTRAINT `fk_sub_pattern_subject` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt`(`id`),
    CONSTRAINT `fk_sub_pattern_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`id`),
    CONSTRAINT `fk_sub_pattern_primary` FOREIGN KEY (`primary_teacher_id`) REFERENCES `sch_teachers`(`id`),
    CONSTRAINT `fk_sub_pattern_substitute` FOREIGN KEY (`substitute_teacher_id`) REFERENCES `sch_teachers`(`id`)
) ENGINE=InnoDB COMMENT='Historical substitution patterns for ML prediction';

-- TABLE: tt_substitution_recommendation (Real-time suggestions)
CREATE TABLE `tt_substitution_recommendation` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `teacher_absence_id` INT UNSIGNED NOT NULL,
    `substitute_teacher_id` INT UNSIGNED NOT NULL,
    `confidence_score` DECIMAL(5,2) NOT NULL,  -- 0-100%
    `compatibility_score` DECIMAL(5,2) NOT NULL,
    `availability_score` DECIMAL(5,2) NOT NULL,
    `historical_success_rate` DECIMAL(5,2) NULL,
    `reason_json` JSON NULL,
    `selected` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_sub_recommend` (`teacher_absence_id`, `confidence_score` DESC),
    CONSTRAINT `fk_sub_recommend_absence` FOREIGN KEY (`teacher_absence_id`) REFERENCES `tt_teacher_absence`(`id`),
    CONSTRAINT `fk_sub_recommend_teacher` FOREIGN KEY (`substitute_teacher_id`) REFERENCES `sch_teachers`(`id`)
) ENGINE=InnoDB COMMENT='AI-generated substitution recommendations';

-- 4. ANALYTICS & REPORTING OPTIMIZATION
-- -------------------------------------

-- TABLE: tt_analytics_daily_snapshot (Pre-computed for reports)
CREATE TABLE `tt_analytics_daily_snapshot` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `snapshot_date` DATE NOT NULL,
    `timetable_id` INT UNSIGNED NOT NULL,
    `total_activities` INT UNSIGNED NOT NULL,
    `placed_activities` INT UNSIGNED NOT NULL,
    `hard_constraint_violations` INT UNSIGNED DEFAULT 0,
    `soft_constraint_violations` INT UNSIGNED DEFAULT 0,
    `teacher_utilization_avg` DECIMAL(5,2) NULL,
    `room_utilization_avg` DECIMAL(5,2) NULL,
    `conflict_count` INT UNSIGNED DEFAULT 0,
    `substitution_count` INT UNSIGNED DEFAULT 0,
    `quality_score` DECIMAL(5,2) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_analytics_daily` (`snapshot_date`, `timetable_id`),
    INDEX `idx_analytics_timetable` (`timetable_id`),
    CONSTRAINT `fk_analytics_timetable` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable`(`id`)
) ENGINE=InnoDB COMMENT='Pre-computed daily analytics for fast reporting';

-- TABLE: tt_performance_metrics (Real-time monitoring)
CREATE TABLE `tt_performance_metrics` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `metric_name` VARCHAR(100) NOT NULL,
    `metric_value` DECIMAL(10,4) NOT NULL,
    `metric_unit` VARCHAR(20) NULL,
    `context_type` ENUM('GENERATION','SUBSTITUTION','CONSTRAINT','ACTIVITY') NULL,
    `context_id` INT UNSIGNED NULL,
    `measured_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_performance_metric` (`metric_name`, `measured_at` DESC),
    INDEX `idx_performance_context` (`context_type`, `context_id`, `measured_at` DESC)
) ENGINE=InnoDB COMMENT='Real-time performance metrics for monitoring';





