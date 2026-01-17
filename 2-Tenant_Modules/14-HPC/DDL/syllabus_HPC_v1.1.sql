-- =====================================================================
-- NEP 2020 + PARAKH HPC EXTENSIONS
-- ADDITIONAL TABLES ONLY (NO DUPLICATION)
-- =====================================================================
-- Assumes existing tables:
-- slb_lessons, slb_topics, slb_competencies,
-- slb_bloom_taxonomy, sch_classes, sch_subjects, students, etc.
-- =====================================================================

-- Screen - 1 (Circular Goals)
-- =========================================================
-- CIRCULAR GOALS (NEP / PARAKH)
-- =========================================================
CREATE TABLE hpc_circular_goals (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(50) NOT NULL,
  `name` VARCHAR(150) NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,  -- Fk to sch_classes
  `description` TEXT,
  `nep_reference` VARCHAR(100),
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  UNIQUE KEY `uq_cg_code` (`code`),
  CONSTRAINT `fk_cg_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE hpc_circular_goal_competency_jnt (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `circular_goal_id` BIGINT UNSIGNED NOT NULL,
  `competency_id` BIGINT UNSIGNED NOT NULL,
  `is_primary` TINYINT(1) DEFAULT 0,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  UNIQUE KEY `uq_cg_comp` (`circular_goal_id`, `competency_id`),
  CONSTRAINT `fk_cg_comp_goal` FOREIGN KEY (`circular_goal_id`) REFERENCES `slb_circular_goals`(`id`),
  CONSTRAINT `fk_cg_comp_comp` FOREIGN KEY (`competency_id`) REFERENCES `slb_competencies`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Screen - 2 (Learning Activities)
-- =========================================================
-- LEARNING OUTCOMES (NORMALIZED)
-- =========================================================
CREATE TABLE hpc_learning_outcomes (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(50) NOT NULL,
  `description` VARCHAR(255) NOT NULL,
  `domain` BIGINT UNSIGNED NOT NULL,   -- FK TO sys_dropdown_table e.g. ('COGNITIVE','AFFECTIVE','PSYCHOMOTOR') DEFAULT 'COGNITIVE'
  `bloom_id` INT UNSIGNED DEFAULT NULL,
  `level` TINYINT UNSIGNED DEFAULT 1,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  UNIQUE KEY `uq_lo_code` (`code`),
  CONSTRAINT `fk_lo_bloom` FOREIGN KEY (`bloom_id`) REFERENCES `slb_bloom_taxonomy`(`id`)
  CONSTRAINT `fk_lo_domain` FOREIGN KEY (`domain`) REFERENCES `sys_dropdown_table`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE hpc_outcome_entity_jnt (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `outcome_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,  -- Fk to sch_classes
  `entity_type` ENUM('SUBJECT','LESSON','TOPIC') NOT NULL,
  `entity_id` BIGINT UNSIGNED NOT NULL,  -- Dropdown from sch_subjects, slb_lessons, slb_topics (Depend upon selection of entity_type)
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  UNIQUE KEY `uq_outcome_entity` (`outcome_id`, `entity_type`, `entity_id`),
  CONSTRAINT `fk_outcome_entity_outcome` FOREIGN KEY (`outcome_id`) REFERENCES `slb_learning_outcomes`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Screen - 3 (QUESTION MAPPING)
-- =========================================================
-- OUTCOME ↔ QUESTION MAPPING (will be used for HPC)
-- =========================================================
CREATE TABLE hpc_outcome_question_jnt (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `outcome_id` BIGINT UNSIGNED NOT NULL,
  `question_id` BIGINT UNSIGNED NOT NULL,  -- fk to qns_questions_bank.id
  `weightage` DECIMAL(5,2) DEFAULT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  UNIQUE KEY `uq_outcome_question` (`outcome_id`, `question_id`),
  CONSTRAINT `fk_outcome_question_outcome` FOREIGN KEY (`outcome_id`) REFERENCES `slb_learning_outcomes`(`id`),
  CONSTRAINT `fk_outcome_question_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Screen - 4 (Knowledge Graph Validation)
-- =========================================================
-- KNOWLEDGE GRAPH VALIDATION
-- =========================================================
CREATE TABLE hpc_knowledge_graph_validation (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `topic_id` BIGINT UNSIGNED NOT NULL,
  `issue_type` ENUM('NO_COMPETENCY','NO_OUTCOME','NO_WEIGHTAGE','ORPHAN_NODE') NOT NULL,
  `severity` ENUM('LOW','MEDIUM','HIGH','CRITICAL') DEFAULT 'LOW',
  `detected_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `is_resolved` TINYINT(1) DEFAULT 0,
  `resolved_at` TIMESTAMP NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  CONSTRAINT `fk_kgv_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Screen - 5 (Topic Equivalency)
-- =========================================================
-- MULTI-SYLLABUS TOPIC EQUIVALENCY
-- =========================================================
CREATE TABLE hpc_topic_equivalency (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `source_topic_id` BIGINT UNSIGNED NOT NULL,
  `target_topic_id` BIGINT UNSIGNED NOT NULL,
  `equivalency_type` ENUM('FULL','PARTIAL','PREREQUISITE') DEFAULT 'FULL',
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  UNIQUE KEY `uq_topic_equiv` (`source_topic_id`, `target_topic_id`),
  CONSTRAINT `fk_equiv_source` FOREIGN KEY (`source_topic_id`) REFERENCES `slb_topics`(`id`),
  CONSTRAINT `fk_equiv_target` FOREIGN KEY (`target_topic_id`) REFERENCES `slb_topics`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Screen - 6 (Syllabus Coverage) Only View & Update
-- =========================================================
-- SYLLABUS COVERAGE SNAPSHOT (ANALYTICS)
-- =========================================================
CREATE TABLE hpc_syllabus_coverage_snapshot (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `coverage_percentage` DECIMAL(5,2) NOT NULL,
  `snapshot_date` DATE NOT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Screen - 7 (HPC Parameters)
-- =========================================================
-- HPC PARAMETERS
-- =========================================================
CREATE TABLE hpc_hpc_parameters (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(20) NOT NULL,      -- AWARENESS, SENSITIVITY, CREATIVITY
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(500) DEFAULT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  UNIQUE KEY `uq_hpc_param_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Screen - 8 (HPC Performance Levels)
-- =========================================================
-- HPC PERFORMANCE LEVELS
-- =========================================================
CREATE TABLE hpc_hpc_levels (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(20) NOT NULL,      -- BEGINNER, PROFICIENT, ADVANCED
  `ordinal` TINYINT UNSIGNED NOT NULL,
  `description` VARCHAR(500) DEFAULT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  UNIQUE KEY `uq_hpc_level_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Screen - 9 (Student HPC Evaluation)
-- =========================================================
-- STUDENT HPC EVALUATION
-- =========================================================
CREATE TABLE hpc_student_hpc_evaluation (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `competency_id` BIGINT UNSIGNED NOT NULL,
  `hpc_parameter_id` INT UNSIGNED NOT NULL,
  `hpc_level_id` INT UNSIGNED NOT NULL,
  `evidence_type` BIGINT UNSIGNED NOT NULL,   -- FK TO sys_dropdown_table e.g. ('ACTIVITY','ASSESSMENT','OBSERVATION')
  `evidence_id` BIGINT UNSIGNED,
  `remarks` VARCHAR(500),
  `assessed_by` BIGINT UNSIGNED,
  `assessed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  UNIQUE KEY `uq_hpc_eval` (`academic_session_id`, `student_id`, `subject_id`, `competency_id`, `hpc_parameter_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Screen - 10 (Learning Activities)
-- =========================================================
-- LEARNING ACTIVITIES (HPC EVIDENCE)
-- =========================================================
CREATE TABLE hpc_learning_activities (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `topic_id` BIGINT UNSIGNED NOT NULL,
  `activity_type` BIGINT UNSIGNED NOT NULL,   FK TO sys_dropdown_table e.g. ('PROJECT','OBSERVATION','FIELD_WORK','GROUP_WORK','ART','SPORT','DISCUSSION')
  `description` TEXT NOT NULL,
  `expected_outcome` TEXT,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  CONSTRAINT `fk_activity_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics`(`id`)
  CONSTRAINT `fk_activity_type` FOREIGN KEY (`activity_type`) REFERENCES `sys_dropdown_table`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Do not ceate screen for this write Now. We will 
-- =========================================================
-- HOLISTIC PROGRESS CARD SNAPSHOT
-- =========================================================
CREATE TABLE hpc_student_hpc_snapshot (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `snapshot_json` JSON NOT NULL,
  `generated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  UNIQUE KEY `uq_hpc_snapshot` (`academic_session_id`, `student_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- END OF NEP 2020 + HPC EXTENSION SCHEMA
-- =====================================================================
