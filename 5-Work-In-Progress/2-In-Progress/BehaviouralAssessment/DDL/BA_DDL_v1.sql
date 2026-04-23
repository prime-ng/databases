-- =============================================================================
-- BA — Behavioural Assessment Module DDL
-- Module: BehaviouralAssessment (Modules\BehaviouralAssessment)
-- Table Prefix: ba_* (16 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: April 2026
-- Based on: BehaviouralAssessment_v1.md + BA_FeatureSpec.md
-- =============================================================================

-- =========================================================================
-- LAYER 1 — No dependencies on other ba_* tables
-- =========================================================================

-- 1. ba_rating_scales
CREATE TABLE IF NOT EXISTS `ba_rating_scales` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL COMMENT 'Scale name (e.g., "5-Point Behavioural Scale")',
  `description` TEXT DEFAULT NULL COMMENT 'Optional description of the scale',
  `grade_boundaries_json` JSON DEFAULT NULL COMMENT 'Grade mapping boundaries: [{"grade":"A+","min":4.50,"max":5.00}, ...]',
  `is_default` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Whether this is the schools default scale',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Soft delete',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Rating scales for behavioural assessment (e.g., 5-Point, 3-Point)';


-- 2. ba_categories
CREATE TABLE IF NOT EXISTS `ba_categories` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Self-reference for sub-categories; NULL for top-level',
  `name` VARCHAR(100) NOT NULL COMMENT 'Category name (e.g., "Classroom Engagement")',
  `description` TEXT DEFAULT NULL COMMENT 'Category description',
  `polarity` ENUM('positive','negative') NOT NULL COMMENT 'Whether this category tracks positive or negative behaviours',
  `weight` DECIMAL(5,2) NOT NULL DEFAULT 100.00 COMMENT 'Weight in overall score computation (0.00-100.00); proportional weighting',
  `sort_order` TINYINT UNSIGNED NOT NULL COMMENT 'Display order among siblings',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_ba_cat_parent` (`parent_id`),
  KEY `idx_ba_cat_polarity` (`polarity`),
  CONSTRAINT `fk_ba_cat_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `ba_categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Behavioural categories (Classroom Engagement, Respect, etc.)';


-- 3. ba_interventions
CREATE TABLE IF NOT EXISTS `ba_interventions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL COMMENT 'Intervention name (e.g., "Verbal Warning", "Award/Certificate")',
  `description` TEXT DEFAULT NULL COMMENT 'Detailed description of the intervention',
  `intervention_type` ENUM('reward','corrective','counselling') NOT NULL COMMENT 'Type: reward, corrective, or counselling',
  `sort_order` TINYINT UNSIGNED NOT NULL COMMENT 'Display order',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Soft delete',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Master list of predefined interventions (reward/corrective/counselling)';


-- =========================================================================
-- LAYER 2 — Depends on Layer 1
-- =========================================================================

-- 4. ba_rating_levels
CREATE TABLE IF NOT EXISTS `ba_rating_levels` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `rating_scale_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to ba_rating_scales.id',
  `label` VARCHAR(50) NOT NULL COMMENT 'Display label (e.g., "Outstanding", "Good")',
  `numeric_value` DECIMAL(3,1) NOT NULL COMMENT 'Numeric value for computation (e.g., 5.0, 4.0)',
  `description` VARCHAR(255) DEFAULT NULL COMMENT 'Optional description (e.g., "Consistently exceeds expectations")',
  `sort_order` TINYINT UNSIGNED NOT NULL COMMENT 'Display order within scale (1 = lowest)',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_level` (`rating_scale_id`, `sort_order`),
  KEY `idx_ba_level_scale` (`rating_scale_id`),
  CONSTRAINT `fk_ba_level_rating_scale_id` FOREIGN KEY (`rating_scale_id`) REFERENCES `ba_rating_scales` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Individual levels within a rating scale (e.g., Outstanding=5, Good=3)';


-- 5. ba_criteria
CREATE TABLE IF NOT EXISTS `ba_criteria` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to ba_categories.id — parent category',
  `name` VARCHAR(255) NOT NULL COMMENT 'Criterion text (e.g., "Active participation in class discussions")',
  `description` TEXT DEFAULT NULL COMMENT 'Optional detailed description',
  `weight` DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT 'Weight within category (0.00-100.00); proportional weighting',
  `sort_order` TINYINT UNSIGNED NOT NULL COMMENT 'Display order within category',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_ba_criteria_category` (`category_id`),
  CONSTRAINT `fk_ba_criteria_category_id` FOREIGN KEY (`category_id`) REFERENCES `ba_categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Individual criteria within a behavioural category';


-- =========================================================================
-- LAYER 3 — Depends on sch_* + Layer 1
-- =========================================================================

-- 6. ba_class_category_jnt
CREATE TABLE IF NOT EXISTS `ba_class_category_jnt` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `class_id` INT UNSIGNED NOT NULL COMMENT 'FK to sch_classes.id — cross-module',
  `category_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to ba_categories.id',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_class_cat` (`class_id`, `category_id`),
  KEY `idx_ba_cc_class` (`class_id`),
  KEY `idx_ba_cc_category` (`category_id`),
  CONSTRAINT `fk_ba_cc_class_id` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ba_cc_category_id` FOREIGN KEY (`category_id`) REFERENCES `ba_categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Junction: maps which behavioural categories apply to which classes';


-- 7. ba_assessment_periods
CREATE TABLE IF NOT EXISTS `ba_assessment_periods` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `academic_session_id` SMALLINT UNSIGNED NOT NULL COMMENT 'FK to sch_org_academic_sessions_jnt.id — cross-module',
  `academic_term_id` SMALLINT UNSIGNED DEFAULT NULL COMMENT 'FK to sch_academic_term.id — optional link to exam term; NULL if independent',
  `name` VARCHAR(100) NOT NULL COMMENT 'Period name (e.g., "Term 1 Assessment", "Annual")',
  `start_date` DATE NOT NULL COMMENT 'Assessment window start date',
  `end_date` DATE NOT NULL COMMENT 'Assessment window end date',
  `deadline` DATE NOT NULL COMMENT 'Teacher submission deadline (must be >= end_date)',
  `status` ENUM('open','closed','locked') NOT NULL DEFAULT 'open' COMMENT 'Period lifecycle: open, closed, locked',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_ba_period_session` (`academic_session_id`),
  KEY `idx_ba_period_term` (`academic_term_id`),
  KEY `idx_ba_period_status` (`status`),
  CONSTRAINT `fk_ba_period_session_id` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_period_term_id` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_academic_term` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Assessment windows during which teachers record behavioural ratings';


-- 8. ba_config
CREATE TABLE IF NOT EXISTS `ba_config` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `academic_session_id` SMALLINT UNSIGNED NOT NULL COMMENT 'FK to sch_org_academic_sessions_jnt.id — one config per session',
  `rating_scale_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to ba_rating_scales.id — active rating scale for this session',
  `is_result_integration_enabled` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Whether behavioural scores are included in report cards',
  `weightage_percent` DECIMAL(4,1) NOT NULL DEFAULT 10.0 COMMENT 'Percentage contribution to final academic result (5.0-20.0)',
  `aggregation_method` ENUM('average','weighted_average','separate_display') NOT NULL DEFAULT 'weighted_average' COMMENT 'How category scores are aggregated into overall score',
  `parent_notification_threshold` ENUM('minor','moderate','major','critical') NOT NULL DEFAULT 'moderate' COMMENT 'Minimum incident severity that triggers parent notification',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_config_session` (`academic_session_id`),
  KEY `idx_ba_config_session` (`academic_session_id`),
  KEY `idx_ba_config_scale` (`rating_scale_id`),
  CONSTRAINT `fk_ba_config_session_id` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_config_scale_id` FOREIGN KEY (`rating_scale_id`) REFERENCES `ba_rating_scales` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='School-level behavioural assessment configuration per academic session';


-- =========================================================================
-- LAYER 4 — Depends on Layer 3 + sch_*
-- =========================================================================

-- 9. ba_assessments
CREATE TABLE IF NOT EXISTS `ba_assessments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `period_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to ba_assessment_periods.id',
  `teacher_id` INT UNSIGNED NOT NULL COMMENT 'FK to sch_employees.id — assessing teacher (cross-module)',
  `class_section_id` INT UNSIGNED NOT NULL COMMENT 'FK to sch_class_section_jnt.id — class+section being assessed (cross-module)',
  `status` ENUM('draft','submitted','reviewed','locked') NOT NULL DEFAULT 'draft' COMMENT 'Assessment workflow status (FSM)',
  `submitted_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'When teacher submitted the assessment',
  `reviewed_by` INT UNSIGNED DEFAULT NULL COMMENT 'FK to sch_employees.id — Principal/HOD who reviewed (cross-module)',
  `reviewed_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'When reviewed/approved',
  `reviewer_remarks` TEXT DEFAULT NULL COMMENT 'Reviewer remarks (especially when sent back)',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_assessment` (`teacher_id`, `class_section_id`, `period_id`),
  KEY `idx_ba_assess_period` (`period_id`),
  KEY `idx_ba_assess_teacher` (`teacher_id`),
  KEY `idx_ba_assess_cs` (`class_section_id`),
  KEY `idx_ba_assess_reviewed_by` (`reviewed_by`),
  KEY `idx_ba_assess_status` (`period_id`, `status`),
  CONSTRAINT `fk_ba_assess_period_id` FOREIGN KEY (`period_id`) REFERENCES `ba_assessment_periods` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_assess_teacher_id` FOREIGN KEY (`teacher_id`) REFERENCES `sch_employees` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_assess_cs_id` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_assess_reviewed_by` FOREIGN KEY (`reviewed_by`) REFERENCES `sch_employees` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Header record for a teachers assessment submission per class-section per period';


-- 10. ba_audit_log
CREATE TABLE IF NOT EXISTS `ba_audit_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `entity_type` ENUM('assessment_rating','assessment','incident') NOT NULL COMMENT 'Type of entity being audited',
  `entity_id` BIGINT UNSIGNED NOT NULL COMMENT 'ID of the entity record',
  `field_name` VARCHAR(50) NOT NULL COMMENT 'Column name that changed (e.g., "rating_level_id", "status")',
  `old_value` VARCHAR(255) DEFAULT NULL COMMENT 'Previous value (NULL for initial creation)',
  `new_value` VARCHAR(255) DEFAULT NULL COMMENT 'New value',
  `changed_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id who made the change',
  `changed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When the change occurred',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ba_audit_entity` (`entity_type`, `entity_id`),
  KEY `idx_ba_audit_changed_by` (`changed_by`),
  KEY `idx_ba_audit_changed_at` (`changed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Audit trail for all rating changes — IMMUTABLE (no updated_at, no deleted_at)';


-- =========================================================================
-- LAYER 5 — Depends on Layer 4 + Layer 2
-- =========================================================================

-- 11. ba_assessment_ratings
CREATE TABLE IF NOT EXISTS `ba_assessment_ratings` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to ba_assessments.id — parent assessment',
  `student_id` INT UNSIGNED NOT NULL COMMENT 'FK to std_students.id — student being rated (cross-module)',
  `criterion_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to ba_criteria.id — criterion being rated',
  `rating_level_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'FK to ba_rating_levels.id — selected rating level; NULL = not yet rated',
  `remark` VARCHAR(500) DEFAULT NULL COMMENT 'Optional per-criterion remark for this student',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_rating` (`assessment_id`, `student_id`, `criterion_id`),
  KEY `idx_ba_rating_assess` (`assessment_id`),
  KEY `idx_ba_rating_student` (`student_id`),
  KEY `idx_ba_rating_criterion` (`criterion_id`),
  KEY `idx_ba_rating_level` (`rating_level_id`),
  KEY `idx_ba_rating_lookup` (`student_id`, `criterion_id`, `assessment_id`),
  CONSTRAINT `fk_ba_rating_assessment_id` FOREIGN KEY (`assessment_id`) REFERENCES `ba_assessments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ba_rating_student_id` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_rating_criterion_id` FOREIGN KEY (`criterion_id`) REFERENCES `ba_criteria` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_rating_level_id` FOREIGN KEY (`rating_level_id`) REFERENCES `ba_rating_levels` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Individual rating entries — core fact table (one per student per criterion per assessment)';


-- 12. ba_student_remarks
CREATE TABLE IF NOT EXISTS `ba_student_remarks` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to ba_assessments.id — parent assessment',
  `student_id` INT UNSIGNED NOT NULL COMMENT 'FK to std_students.id (cross-module)',
  `remark_text` TEXT NOT NULL COMMENT 'Teachers overall behavioural remark for this student for this period',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_remark` (`assessment_id`, `student_id`),
  KEY `idx_ba_remark_assess` (`assessment_id`),
  KEY `idx_ba_remark_student` (`student_id`),
  CONSTRAINT `fk_ba_remark_assessment_id` FOREIGN KEY (`assessment_id`) REFERENCES `ba_assessments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ba_remark_student_id` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Overall remarks per student per assessment (not per-criterion)';


-- 13. ba_computed_scores
CREATE TABLE IF NOT EXISTS `ba_computed_scores` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` INT UNSIGNED NOT NULL COMMENT 'FK to std_students.id (cross-module)',
  `category_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to ba_categories.id — category scored',
  `period_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to ba_assessment_periods.id — assessment period',
  `numeric_score` DECIMAL(5,2) NOT NULL COMMENT 'Computed category score (e.g., 4.25)',
  `grade` VARCHAR(5) DEFAULT NULL COMMENT 'Mapped grade from grade boundaries (e.g., "A", "B+")',
  `overall_score` DECIMAL(5,2) DEFAULT NULL COMMENT 'Overall weighted score across all categories (stored on first category row per student-period)',
  `overall_grade` VARCHAR(5) DEFAULT NULL COMMENT 'Overall mapped grade',
  `computed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When the score was last computed',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_score` (`student_id`, `category_id`, `period_id`),
  KEY `idx_ba_score_student` (`student_id`),
  KEY `idx_ba_score_category` (`category_id`),
  KEY `idx_ba_score_period` (`period_id`),
  KEY `idx_ba_score_lookup` (`student_id`, `period_id`),
  CONSTRAINT `fk_ba_score_student_id` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_score_category_id` FOREIGN KEY (`category_id`) REFERENCES `ba_categories` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_score_period_id` FOREIGN KEY (`period_id`) REFERENCES `ba_assessment_periods` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Cached computed scores per student per category per period (recalculated on demand)';


-- 14. ba_incidents
CREATE TABLE IF NOT EXISTS `ba_incidents` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` INT UNSIGNED NOT NULL COMMENT 'FK to std_students.id — student involved (cross-module)',
  `reported_by` INT UNSIGNED NOT NULL COMMENT 'FK to sch_employees.id — teacher/staff who reported (cross-module)',
  `category_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'FK to ba_categories.id — optional linked category',
  `criterion_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'FK to ba_criteria.id — optional linked criterion',
  `incident_date` DATE NOT NULL COMMENT 'Date of incident',
  `incident_time` TIME DEFAULT NULL COMMENT 'Time of incident',
  `incident_type` ENUM('positive_reinforcement','negative_incident') NOT NULL COMMENT 'Positive reinforcement or negative incident',
  `severity` ENUM('minor','moderate','major','critical') DEFAULT NULL COMMENT 'Severity level (required for negative; NULL for positive)',
  `description` TEXT NOT NULL COMMENT 'Detailed description of the incident',
  `location` ENUM('classroom','playground','corridor','lab','transport','canteen','library','other') NOT NULL DEFAULT 'classroom' COMMENT 'Where the incident occurred',
  `intervention_notes` TEXT DEFAULT NULL COMMENT 'Free-text intervention/action taken',
  `is_follow_up_required` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Whether follow-up action is needed',
  `follow_up_date` DATE DEFAULT NULL COMMENT 'Scheduled follow-up date',
  `follow_up_notes` TEXT DEFAULT NULL COMMENT 'Follow-up notes (appendable after submission)',
  `attachments_json` JSON DEFAULT NULL COMMENT 'Array of attachment file references: [{"media_id":1,"filename":"evidence.jpg"}]',
  `is_notified` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Whether parent notification was sent',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_ba_incident_student` (`student_id`),
  KEY `idx_ba_incident_reporter` (`reported_by`),
  KEY `idx_ba_incident_category` (`category_id`),
  KEY `idx_ba_incident_criterion` (`criterion_id`),
  KEY `idx_ba_incident_timeline` (`student_id`, `incident_date`),
  KEY `idx_ba_incident_type` (`incident_type`),
  KEY `idx_ba_incident_severity` (`severity`),
  CONSTRAINT `fk_ba_incident_student_id` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_incident_reported_by` FOREIGN KEY (`reported_by`) REFERENCES `sch_employees` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_incident_category_id` FOREIGN KEY (`category_id`) REFERENCES `ba_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ba_incident_criterion_id` FOREIGN KEY (`criterion_id`) REFERENCES `ba_criteria` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Individual behavioural incident records (positive or negative)';


-- =========================================================================
-- LAYER 6 — Depends on Layer 5 + Layer 1
-- =========================================================================

-- 15. ba_incident_witnesses_jnt
CREATE TABLE IF NOT EXISTS `ba_incident_witnesses_jnt` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `incident_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to ba_incidents.id — parent incident',
  `witness_type` ENUM('student','staff') NOT NULL COMMENT 'Type of witness',
  `witness_id` INT UNSIGNED NOT NULL COMMENT 'std_students.id or sch_employees.id depending on witness_type (polymorphic, no DB-level FK)',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_witness` (`incident_id`, `witness_type`, `witness_id`),
  KEY `idx_ba_witness_incident` (`incident_id`),
  CONSTRAINT `fk_ba_witness_incident_id` FOREIGN KEY (`incident_id`) REFERENCES `ba_incidents` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Junction: witnesses to behavioural incidents (polymorphic student/staff)';


-- 16. ba_incident_intervention_jnt
CREATE TABLE IF NOT EXISTS `ba_incident_intervention_jnt` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `incident_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to ba_incidents.id — incident',
  `intervention_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to ba_interventions.id — intervention applied',
  `notes` VARCHAR(500) DEFAULT NULL COMMENT 'Additional notes about this intervention application',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_inc_int` (`incident_id`, `intervention_id`),
  KEY `idx_ba_ii_incident` (`incident_id`),
  KEY `idx_ba_ii_intervention` (`intervention_id`),
  CONSTRAINT `fk_ba_ii_incident_id` FOREIGN KEY (`incident_id`) REFERENCES `ba_incidents` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ba_ii_intervention_id` FOREIGN KEY (`intervention_id`) REFERENCES `ba_interventions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Junction: maps incidents to interventions applied';
