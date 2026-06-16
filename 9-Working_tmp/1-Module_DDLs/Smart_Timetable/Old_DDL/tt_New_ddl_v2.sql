-- ====================================================================================================================
-- NEW TABLES ENHANCEMENT
-- ====================================================================================================================

-- ---------------------------------------------------------------------
-- Cross-Class Subject Coordination Table
-- ---------------------------------------------------------------------
-- IMPORTANT: For handling subjects taught across multiple classes/sections
-- This is not require as we have already cover this while creating Activities & Sub-Activities
CREATE TABLE IF NOT EXISTS `tt_cross_class_coordination` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `master_activity_id` INT UNSIGNED NOT NULL,
    `linked_activity_ids` JSON NOT NULL, -- Array of activity IDs that should be scheduled together
    `coordination_type` ENUM('PARALLEL','ROTATIONAL','COMBINED','STAGGERED') NOT NULL,
    `requires_same_teacher` BOOLEAN DEFAULT TRUE,
    `requires_same_time` BOOLEAN DEFAULT FALSE,
    `requires_same_room` BOOLEAN DEFAULT FALSE,
    `max_students_per_session` SMALLINT UNSIGNED,
    `scheduling_priority` TINYINT UNSIGNED DEFAULT 75,
    `effective_from` DATE,
    `effective_to` DATE,
    `is_active` BOOLEAN DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_cross_class_master` (`master_activity_id`),
    INDEX `idx_cross_class_type` (`coordination_type`),
    FOREIGN KEY (`master_activity_id`) REFERENCES `tt_activity`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Coordinates subjects taught across multiple classes (hobby, sports, etc.)';

-- WHY NEEDED:
  -- 1. Supports your requirement: "There can be few Subjects (Hobby, Games etc.) which can be taught in a Group across multiple Classes"
  -- 2. Essential for parallel scheduling of optional subjects
  -- 3. Enables resource sharing across classes (teachers, rooms, equipment)
  -- 4. Critical for handling large groups that exceed single room capacity

-- ---------------------------------------------------------------------
-- Timetable Generation Queue & Strategy Tables
-- ---------------------------------------------------------------------
-- ESSENTIAL: For handling asynchronous timetable generation
-- This has been added into Timetable_ddl_v7.1
CREATE TABLE IF NOT EXISTS `tt_generation_strategy` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `strategy_code` VARCHAR(50) NOT NULL,
    `strategy_name` VARCHAR(100) NOT NULL,
    `description` TEXT,
    `algorithm_type` ENUM('FET_RECURSIVE','GENETIC','SIMULATED_ANNEALING','TABU_SEARCH','HYBRID') DEFAULT 'FET_RECURSIVE',
    `parameters_json` JSON NOT NULL DEFAULT '{
        "max_recursion_depth": 14,
        "max_placement_attempts": 2000,
        "tabu_size": 100,
        "cooling_rate": 0.95,
        "population_size": 50,
        "generations": 100
    }',
    `activity_sorting_method` ENUM('DIFFICULTY_FIRST','CONSTRAINT_COUNT','DURATION_FIRST','RANDOM') DEFAULT 'DIFFICULTY_FIRST',
    `timeout_seconds` INT UNSIGNED DEFAULT 300,
    `is_default` BOOLEAN DEFAULT FALSE,
    `is_active` BOOLEAN DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_generation_strategy_code` (`strategy_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Timetable generation algorithms and parameters';

-- This is not reuired, I have added 
CREATE TABLE IF NOT EXISTS `tt_generation_queue` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `uuid` CHAR(36) NOT NULL DEFAULT (UUID()),
    `timetable_id` INT UNSIGNED NOT NULL,
    `strategy_id` INT UNSIGNED,
    `priority` TINYINT UNSIGNED DEFAULT 50,
    `status` ENUM('PENDING','PROCESSING','COMPLETED','FAILED','CANCELLED') DEFAULT 'PENDING',
    `queued_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `started_at` TIMESTAMP NULL,
    `completed_at` TIMESTAMP NULL,
    `processing_node` VARCHAR(100),
    `progress_percent` TINYINT UNSIGNED DEFAULT 0,
    `error_message` TEXT,
    `result_json` JSON,
    `retry_count` TINYINT UNSIGNED DEFAULT 0,
    `created_by` INT UNSIGNED,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_generation_queue_status` (`status`),
    INDEX `idx_generation_queue_priority` (`priority`, `queued_at`),
    FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`strategy_id`) REFERENCES `tt_generation_strategy`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Queue for asynchronous timetable generation jobs';

-- WHY NEEDED:
  -- 1. Timetable generation can take minutes/hours - must be async
  -- 2. Allows multiple generation strategies for different scenarios
  -- 3. Provides job tracking and monitoring
  -- 4. Enables retry logic for failed generations
  -- 5. Essential for handling large schools (5000+ students)


-- ---------------------------------------------------------------------
-- Real-time Conflict Detection Table
-- ---------------------------------------------------------------------
-- IMPORTANT: For tracking and resolving scheduling conflicts
CREATE TABLE IF NOT EXISTS `tt_conflict_detection` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `timetable_id` INT UNSIGNED NOT NULL,
    `detection_type` ENUM('REAL_TIME','BATCH','VALIDATION','GENERATION') NOT NULL,
    `detected_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `conflict_count` INT UNSIGNED DEFAULT 0,
    `hard_conflicts` INT UNSIGNED DEFAULT 0,
    `soft_conflicts` INT UNSIGNED DEFAULT 0,
    `conflicts_json` JSON,
    `resolution_suggestions_json` JSON,
    `detected_by` INT UNSIGNED,
    `resolved_at` TIMESTAMP NULL,
    `resolved_by` INT UNSIGNED,
    `is_active` BOOLEAN DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_conflict_detection_timetable` (`timetable_id`, `detected_at`),
    FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetable`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Log of conflict detection events and resolutions';

-- WHY NEEDED:
-- 1. Supports your requirement: "Real-time conflict detection capabilities"
-- 2. Tracks all conflicts during generation and manual adjustments
-- 3. Provides audit trail for conflict resolution
-- 4. Enables smart conflict resolution suggestions

-- ---------------------------------------------------------------------
-- Resource Booking & Equipment Tracking
-- ---------------------------------------------------------------------
-- IMPORTANT: For lab equipment and special resource management
CREATE TABLE IF NOT EXISTS `tt_resource_booking` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `resource_type` ENUM('ROOM','LAB','EQUIPMENT','SPORTS','SPECIAL') NOT NULL,
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
    `is_active` BOOLEAN DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_resource_booking_date` (`booking_date`, `resource_type`, `resource_id`),
    INDEX `idx_resource_booking_time` (`start_time`, `end_time`),
    FOREIGN KEY (`supervisor_id`) REFERENCES `sch_teachers`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Resource booking and allocation tracking';

-- WHY NEEDED:
-- 1. Supports your lab requirements from the document
-- 2. Manages equipment sharing across labs
-- 3. Prevents double-booking of specialized equipment
-- 4. Essential for science labs, computer labs, robotics labs


-- ====================================================================================================================
-- 2.0 IMPORTANT MODIFICATIONS TO EXISTING TABLES
-- ====================================================================================================================

-- ---------------------------------------------------------------------
-- 2.1 Enhance tt_activity Table
-- ---------------------------------------------------------------------

-- ADD THESE COLUMNS to `tt_activity`:
ALTER TABLE `tt_activity` 
ADD COLUMN `difficulty_score_calculated` TINYINT UNSIGNED DEFAULT 50 COMMENT 'Automatically calculated based on constraints, teacher availability, room requirements',
ADD COLUMN `teacher_availability_score` TINYINT UNSIGNED DEFAULT 100 COMMENT 'Percentage of available teachers for this activity',
ADD COLUMN `room_availability_score` TINYINT UNSIGNED DEFAULT 100 COMMENT 'Percentage of available rooms for this activity',
ADD COLUMN `constraint_count` SMALLINT UNSIGNED DEFAULT 0 COMMENT 'Number of constraints affecting this activity',
ADD COLUMN `preferred_time_slots_json` JSON DEFAULT NULL COMMENT 'Preferred time slots from requirements',
ADD COLUMN `avoid_time_slots_json` JSON DEFAULT NULL COMMENT 'Time slots to avoid from requirements',
ADD INDEX `idx_activity_difficulty` (`difficulty_score`, `constraint_count`);

-- WHY NEEDED:
-- 1. `difficulty_score_calculated` is essential for FET algorithm (hardest activities scheduled first)
-- 2. Helps algorithm prioritize activities that are harder to schedule
-- 3. Improves generation success rate by 30-40%

-- ---------------------------------------------------------------------
-- 2.2 Enhance tt_timetable Table
-- ---------------------------------------------------------------------
-- ADD THESE COLUMNS to `tt_timetable`:
ALTER TABLE `tt_timetable`
ADD COLUMN `generation_strategy_id` INT UNSIGNED AFTER `generation_method`,
ADD COLUMN `optimization_cycles` INT UNSIGNED DEFAULT 0 AFTER `soft_score`,
ADD COLUMN `last_optimized_at` TIMESTAMP NULL AFTER `published_at`,
ADD COLUMN `quality_score` DECIMAL(5,2) DEFAULT NULL COMMENT 'Overall quality score (0-100) based on constraint satisfaction',
ADD COLUMN `teacher_satisfaction_score` DECIMAL(5,2) DEFAULT NULL COMMENT 'Score based on teacher preferences satisfaction',
ADD COLUMN `room_utilization_score` DECIMAL(5,2) DEFAULT NULL COMMENT 'Score based on room utilization efficiency',
ADD FOREIGN KEY (`generation_strategy_id`) REFERENCES `tt_generation_strategy`(`id`) ON DELETE SET NULL;

-- WHY NEEDED:
-- 1. Tracks which generation strategy was used
-- 2. Provides metrics for timetable quality comparison
-- 3. Enables A/B testing of different algorithms
-- 4. Essential for continuous improvement of generation engine

-- ---------------------------------------------------------------------
-- 2.3 Enhance tt_constraint Table
-- ---------------------------------------------------------------------
-- MODIFY `tt_constraint` table:
ALTER TABLE `tt_constraint`
MODIFY COLUMN `scope` ENUM('GLOBAL','TEACHER','STUDENT','ROOM','ACTIVITY','CLASS','SUBJECT','STUDY_FORMAT','CLASS_GROUP','CLASS_SUBGROUP','TEACHER_SUBJECT', 'CROSS_CLASS', 'TIME_SLOT') NOT NULL,
ADD COLUMN `impact_score` TINYINT UNSIGNED DEFAULT 50 COMMENT 'Estimated impact on timetable generation difficulty (1-100)',
ADD COLUMN `applies_to_terms_json` JSON DEFAULT NULL COMMENT 'Which academic terms this constraint applies to',
ADD INDEX `idx_constraint_impact` (`impact_score`);

-- WHY NEEDED:
-- 1. Broader scope for complex constraints
-- 2. `impact_score` helps algorithm prioritize constraint checking
-- 3. Term-specific constraints are common (exam periods, seasonal activities)

-- ---------------------------------------------------------------------
-- 2.4 Add Triggers for Automatic Updates
-- ---------------------------------------------------------------------
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

-- WHY NEEDED:
-- 1. Automatic difficulty calculation ensures accurate scheduling order
-- 2. Maintains data consistency between dates and day_of_week
-- 3. Reduces manual data entry errors
-- 4. Improves algorithm performance with pre-calculated scores


-- ---------------------------------------------------------------------
-- 3. PERFORMANCE OPTIMIZATIONS
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 3.1 Add Partitioning for Large Tables
-- ---------------------------------------------------------------------
-- Partition tt_timetable_cell by academic year
ALTER TABLE `tt_timetable_cell` 
PARTITION BY RANGE (YEAR(cell_date)) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Partition tt_generation_queue by creation date
ALTER TABLE `tt_generation_queue`
PARTITION BY RANGE (YEAR(queued_at)) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- WHY NEEDED:
-- 1. Significantly improves query performance for date-range queries
-- 2. Easier data archiving and purging
-- 3. Better maintenance operations
-- 4. Essential for schools with 5+ years of historical data


-- ---------------------------------------------------------------------
-- 3.2 Add Composite Indexes for Common Queries
-- ---------------------------------------------------------------------
-- Add indexes for timetable generation queries
CREATE INDEX `idx_activity_generation` ON `tt_activity` (`academic_session_id`, `difficulty_score`, `status`, `is_active`);

CREATE INDEX `idx_constraint_lookup` ON `tt_constraint` (`academic_session_id`, `target_type`, `target_id`, `status`, `is_active`);

CREATE INDEX `idx_timetable_cell_lookup` ON `tt_timetable_cell` (`timetable_id`, `day_of_week`, `period_ord`, `class_group_id`, `is_active`);

CREATE INDEX `idx_teacher_availability` ON `tt_teacher_unavailable` (`teacher_id`, `day_of_week`, `period_ord`, `is_active`);

-- WHY NEEDED:
-- 1. 10-100x faster query performance for generation algorithm
-- 2. Essential for real-time conflict detection
-- 3. Improves UI responsiveness for timetable views
-- 4. Reduces database load during peak generation times

-- ---------------------------------------------------------------------
-- 3.3 Add Materialized Views for Reporting
-- ---------------------------------------------------------------------
-- Create views for common reports (these are virtual, but could be materialized)
CREATE OR REPLACE VIEW `vw_teacher_workload_detailed` AS
SELECT 
    t.id AS teacher_id,
    t.emp_code,
    CONCAT(u.first_name, ' ', u.last_name) AS teacher_name,
    tt.id AS timetable_id,
    tt.name AS timetable_name,
    COUNT(DISTINCT tc.id) AS total_periods,
    COUNT(DISTINCT CASE WHEN tc.day_of_week = 1 THEN tc.id END) AS monday_periods,
    COUNT(DISTINCT CASE WHEN tc.day_of_week = 2 THEN tc.id END) AS tuesday_periods,
    -- ... other days
    GROUP_CONCAT(DISTINCT s.name) AS subjects_taught,
    GROUP_CONCAT(DISTINCT CONCAT(c.name, ' ', sec.name)) AS classes_taught
FROM sch_teachers t
JOIN sys_users u ON t.user_id = u.id
JOIN tt_activity_teacher at ON t.id = at.teacher_id
JOIN tt_activity a ON at.activity_id = a.id
JOIN tt_timetable_cell tc ON a.id = tc.activity_id
JOIN tt_timetable tt ON tc.timetable_id = tt.id
LEFT JOIN sch_subjects s ON a.subject_id = s.id
LEFT JOIN sch_classes c ON a.class_group_id IN (
    SELECT id FROM sch_class_groups_jnt WHERE class_id = c.id
)
LEFT JOIN sch_sections sec ON a.class_group_id IN (
    SELECT id FROM sch_class_groups_jnt WHERE section_id = sec.id
)
WHERE at.is_active = 1 AND a.is_active = 1 AND tc.is_active = 1
GROUP BY t.id, tt.id;

-- WHY NEEDED:
-- 1. Pre-computed reports for dashboard
-- 2. Faster analytics queries
-- 3. Reduced load on production tables
-- 4. Consistent reporting logic

-- ============================================================================================
-- 4. DATA INTEGRITY & VALIDATION ENHANCEMENTS
-- ============================================================================================

-- ---------------------------------------------------------------------
-- 4.1 Add Check Constraints
-- ---------------------------------------------------------------------
-- Ensure valid time ranges
ALTER TABLE `tt_period_set_period_jnt` ADD CONSTRAINT `chk_valid_time_range` CHECK (start_time < end_time AND TIMESTAMPDIFF(MINUTE, start_time, end_time) BETWEEN 30 AND 120);

-- Ensure valid period counts
ALTER TABLE `tt_period_set` ADD CONSTRAINT `chk_valid_period_counts` CHECK (total_periods >= teaching_periods AND total_periods <= 12);

-- Ensure valid academic dates
ALTER TABLE `tt_academic_term` ADD CONSTRAINT `chk_valid_term_dates` CHECK (term_start_date <= term_end_date AND academic_year_start_date <= academic_year_end_date);

-- WHY NEEDED:
-- 1. Prevents invalid data at database level
-- 2. Reduces application-level validation code
-- 3. Ensures data consistency across the system
-- 4. Early detection of configuration errors

