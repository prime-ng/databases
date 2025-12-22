-- =====================================================================
-- SYLLABUS & EXAM MANAGEMENT MODULE - ENHANCED VERSION 2.0
-- FILE 2: NEP 2020 COMPLIANT QUESTION BANK
-- =====================================================================

-- -------------------------------------------------------------------------
-- SECTION 1: BLOOM'S TAXONOMY REFERENCE TABLE
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `qb_bloom_taxonomy` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `level` TINYINT UNSIGNED NOT NULL,              -- 1-6 for Bloom's revised taxonomy
  `code` VARCHAR(20) NOT NULL,                    -- 'REMEMBER', 'UNDERSTAND', etc.
  `name` VARCHAR(50) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `keywords` JSON DEFAULT NULL,                   -- Action verbs for this level
  `cognitive_order` ENUM('LOWER', 'MIDDLE', 'HIGHER') NOT NULL,
  `color_code` VARCHAR(7) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_bloom_level` (`level`),
  UNIQUE KEY `uq_bloom_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed Bloom's Taxonomy data
INSERT INTO `qb_bloom_taxonomy` (`level`, `code`, `name`, `description`, `keywords`, `cognitive_order`, `color_code`) VALUES
(1, 'REMEMBER', 'Remember', 'Recall facts and basic concepts', '["define", "list", "name", "recall", "identify", "state"]', 'LOWER', '#EF4444'),
(2, 'UNDERSTAND', 'Understand', 'Explain ideas or concepts', '["explain", "describe", "summarize", "classify", "interpret"]', 'LOWER', '#F97316'),
(3, 'APPLY', 'Apply', 'Use information in new situations', '["apply", "demonstrate", "solve", "use", "calculate", "execute"]', 'MIDDLE', '#EAB308'),
(4, 'ANALYZE', 'Analyze', 'Draw connections among ideas', '["analyze", "compare", "contrast", "differentiate", "examine"]', 'MIDDLE', '#22C55E'),
(5, 'EVALUATE', 'Evaluate', 'Justify a decision or course of action', '["evaluate", "judge", "critique", "justify", "assess", "argue"]', 'HIGHER', '#3B82F6'),
(6, 'CREATE', 'Create', 'Produce new or original work', '["create", "design", "construct", "develop", "formulate", "invent"]', 'HIGHER', '#8B5CF6');


-- -------------------------------------------------------------------------
-- SECTION 2: COGNITIVE LEVELS (NEP 2020)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `qb_cognitive_levels` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL,
  `name` VARCHAR(50) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `bloom_levels` JSON NOT NULL,                   -- Array of bloom level IDs
  `weightage_min` DECIMAL(5,2) DEFAULT NULL,      -- Min % in assessment
  `weightage_max` DECIMAL(5,2) DEFAULT NULL,      -- Max % in assessment
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cognitive_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `qb_cognitive_levels` (`code`, `name`, `description`, `bloom_levels`, `weightage_min`, `weightage_max`) VALUES
('LOT', 'Lower Order Thinking', 'Remember and Understand levels', '[1, 2]', 20.00, 40.00),
('MOT', 'Middle Order Thinking', 'Apply and Analyze levels', '[3, 4]', 30.00, 50.00),
('HOT', 'Higher Order Thinking', 'Evaluate and Create levels', '[5, 6]', 20.00, 40.00);


-- -------------------------------------------------------------------------
-- SECTION 3: COMPLEXITY LEVELS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `qb_complexity_levels` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `level` TINYINT UNSIGNED NOT NULL,
  `code` VARCHAR(20) NOT NULL,
  `name` VARCHAR(50) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `time_multiplier` DECIMAL(3,2) DEFAULT 1.00,    -- Time estimate multiplier
  `marks_multiplier` DECIMAL(3,2) DEFAULT 1.00,
  `color_code` VARCHAR(7) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_complexity_level` (`level`),
  UNIQUE KEY `uq_complexity_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `qb_complexity_levels` (`level`, `code`, `name`, `description`, `time_multiplier`, `marks_multiplier`, `color_code`) VALUES
(1, 'EASY', 'Easy', 'Basic recall and simple application', 0.75, 1.00, '#22C55E'),
(2, 'MEDIUM', 'Medium', 'Moderate analysis required', 1.00, 1.50, '#EAB308'),
(3, 'HARD', 'Hard', 'Complex problem solving', 1.50, 2.00, '#F97316'),
(4, 'CHALLENGE', 'Challenge', 'Advanced multi-step reasoning', 2.00, 3.00, '#EF4444');


-- -------------------------------------------------------------------------
-- SECTION 4: QUESTION TYPES
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `qb_question_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(30) NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `category` ENUM('OBJECTIVE', 'SUBJECTIVE', 'PRACTICAL', 'MIXED') NOT NULL,
  `has_options` TINYINT(1) NOT NULL DEFAULT 0,
  `is_auto_gradable` TINYINT(1) NOT NULL DEFAULT 1,
  `default_marks` DECIMAL(5,2) DEFAULT 1.00,
  `default_time_seconds` INT UNSIGNED DEFAULT 60,
  `description` TEXT DEFAULT NULL,
  `grading_rubric` JSON DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qtype_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `qb_question_types` (`code`, `name`, `category`, `has_options`, `is_auto_gradable`, `default_marks`, `default_time_seconds`, `description`) VALUES
('MCQ_SINGLE', 'Multiple Choice (Single)', 'OBJECTIVE', 1, 1, 1.00, 60, 'Single correct answer from options'),
('MCQ_MULTI', 'Multiple Choice (Multiple)', 'OBJECTIVE', 1, 1, 2.00, 90, 'Multiple correct answers from options'),
('MSQ', 'Multi-Select Question', 'OBJECTIVE', 1, 1, 2.00, 90, 'Select all that apply'),
('TRUE_FALSE', 'True/False', 'OBJECTIVE', 1, 1, 1.00, 30, 'Binary true or false choice'),
('FILL_BLANK', 'Fill in the Blank', 'OBJECTIVE', 0, 1, 1.00, 45, 'Complete the sentence with missing word'),
('MATCH_PAIR', 'Match the Following', 'OBJECTIVE', 1, 1, 2.00, 120, 'Match items from two columns'),
('ASSERTION_REASON', 'Assertion-Reasoning', 'OBJECTIVE', 1, 1, 2.00, 120, 'Evaluate assertion and reasoning relationship'),
('CASE_STUDY', 'Case Study Based', 'MIXED', 0, 0, 5.00, 300, 'Multiple questions based on a scenario'),
('VERY_SHORT', 'Very Short Answer', 'SUBJECTIVE', 0, 0, 1.00, 60, 'One word or one sentence answer'),
('SHORT_ANSWER', 'Short Answer', 'SUBJECTIVE', 0, 0, 2.00, 180, '2-3 sentence answer'),
('LONG_ANSWER', 'Long Answer', 'SUBJECTIVE', 0, 0, 5.00, 600, 'Detailed paragraph answer'),
('NUMERIC', 'Numerical', 'OBJECTIVE', 0, 1, 2.00, 180, 'Numerical answer with tolerance'),
('DIAGRAM', 'Diagram Based', 'SUBJECTIVE', 0, 0, 3.00, 300, 'Draw or label diagram'),
('CODING', 'Coding/Programming', 'PRACTICAL', 0, 1, 5.00, 900, 'Write code solution');


-- -------------------------------------------------------------------------
-- SECTION 5: QUESTION TIME SPECIFICITY (Context of Use)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `qb_question_contexts` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(30) NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `time_limit_factor` DECIMAL(3,2) DEFAULT 1.00,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_context_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `qb_question_contexts` (`code`, `name`, `description`, `time_limit_factor`) VALUES
('IN_CLASS', 'In-Class Practice', 'Used during classroom teaching', 1.20),
('HOMEWORK', 'Homework', 'Take-home practice', 1.50),
('FORMATIVE', 'Formative Assessment', 'Regular classroom assessment', 1.00),
('SUMMATIVE', 'Summative Assessment', 'Term-end or annual exams', 0.90),
('OLYMPIAD', 'Olympiad/Competition', 'High-difficulty competition', 0.80),
('REMEDIAL', 'Remedial Practice', 'For struggling students', 1.50),
('ENRICHMENT', 'Enrichment Activity', 'For advanced learners', 0.75);


-- -------------------------------------------------------------------------
-- SECTION 6: MAIN QUESTIONS TABLE
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `qb_questions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `uuid` CHAR(36) NOT NULL,
  
  -- Classification
  `topic_id` BIGINT UNSIGNED NOT NULL,            -- FK to syl_topics
  `competency_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to syl_competencies
  `lesson_id` BIGINT UNSIGNED DEFAULT NULL,       -- Denormalized
  `class_id` INT UNSIGNED NOT NULL,               -- Denormalized
  `subject_id` BIGINT UNSIGNED NOT NULL,          -- Denormalized
  
  -- NEP 2020 Categorization
  `question_type_id` INT UNSIGNED NOT NULL,       -- FK to qb_question_types
  `bloom_id` INT UNSIGNED NOT NULL,               -- FK to qb_bloom_taxonomy
  `cognitive_level_id` INT UNSIGNED NOT NULL,     -- FK to qb_cognitive_levels
  `complexity_level_id` INT UNSIGNED NOT NULL,    -- FK to qb_complexity_levels
  `context_id` INT UNSIGNED DEFAULT NULL,         -- FK to qb_question_contexts
  
  -- Question Content
  `stem` TEXT NOT NULL,                           -- Question text (HTML/Markdown)
  `stem_plain` TEXT DEFAULT NULL,                 -- Plain text for search
  `hint` TEXT DEFAULT NULL,                       -- Optional hint for students
  `answer_explanation` TEXT DEFAULT NULL,         -- Detailed explanation
  `reference_material` TEXT DEFAULT NULL,         -- Source/textbook reference
  
  -- Scoring
  `marks` DECIMAL(5,2) NOT NULL DEFAULT 1.00,
  `negative_marks` DECIMAL(5,2) DEFAULT 0.00,
  `partial_marking` TINYINT(1) DEFAULT 0,
  
  -- Time Estimation
  `estimated_time_seconds` INT UNSIGNED NOT NULL, -- Time to solve
  
  -- Metadata
  `language` VARCHAR(10) DEFAULT 'en',
  `difficulty_rating` DECIMAL(4,2) DEFAULT NULL,  -- Calculated from attempts
  `tags` JSON DEFAULT NULL,
  `external_ref` VARCHAR(100) DEFAULT NULL,       -- External ID mapping
  
  -- Version Control
  `version` INT UNSIGNED NOT NULL DEFAULT 1,
  `parent_question_id` BIGINT UNSIGNED DEFAULT NULL, -- For variations
  
  -- Status
  `status` ENUM('DRAFT', 'REVIEW', 'APPROVED', 'DEPRECATED') NOT NULL DEFAULT 'DRAFT',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_public` TINYINT(1) NOT NULL DEFAULT 0,
  
  -- Audit
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `approved_by` BIGINT UNSIGNED DEFAULT NULL,
  `approved_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_question_uuid` (`uuid`),
  KEY `idx_question_tenant` (`tenant_id`),
  KEY `idx_question_topic` (`topic_id`),
  KEY `idx_question_class_subject` (`class_id`, `subject_id`),
  KEY `idx_question_bloom` (`bloom_id`),
  KEY `idx_question_complexity` (`complexity_level_id`),
  KEY `idx_question_type` (`question_type_id`),
  KEY `idx_question_status` (`status`),
  FULLTEXT KEY `ft_question_stem` (`stem_plain`),
  CONSTRAINT `fk_question_topic` FOREIGN KEY (`topic_id`) REFERENCES `syl_topics` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_question_competency` FOREIGN KEY (`competency_id`) REFERENCES `syl_competencies` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_question_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `syl_lessons` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_question_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_question_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_question_type` FOREIGN KEY (`question_type_id`) REFERENCES `qb_question_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_question_bloom` FOREIGN KEY (`bloom_id`) REFERENCES `qb_bloom_taxonomy` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_question_cognitive` FOREIGN KEY (`cognitive_level_id`) REFERENCES `qb_cognitive_levels` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_question_complexity` FOREIGN KEY (`complexity_level_id`) REFERENCES `qb_complexity_levels` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_question_context` FOREIGN KEY (`context_id`) REFERENCES `qb_question_contexts` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_question_parent` FOREIGN KEY (`parent_question_id`) REFERENCES `qb_questions` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 7: QUESTION OPTIONS (For MCQ, MSQ, etc.)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `qb_question_options` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id` BIGINT UNSIGNED NOT NULL,
  `ordinal` SMALLINT UNSIGNED NOT NULL,
  `option_label` CHAR(1) DEFAULT NULL,            -- A, B, C, D
  `option_text` TEXT NOT NULL,
  `is_correct` TINYINT(1) NOT NULL DEFAULT 0,
  `partial_score` DECIMAL(5,2) DEFAULT NULL,      -- For partial marking
  `feedback` TEXT DEFAULT NULL,                   -- Why right/wrong
  `image_url` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_option_question` (`question_id`),
  CONSTRAINT `fk_option_question` FOREIGN KEY (`question_id`) REFERENCES `qb_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 8: QUESTION MEDIA ATTACHMENTS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `qb_question_media` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id` BIGINT UNSIGNED NOT NULL,
  `media_type` ENUM('IMAGE', 'AUDIO', 'VIDEO', 'DOCUMENT', 'ATTACHMENT') NOT NULL,
  `purpose` ENUM('STEM', 'OPTION', 'EXPLANATION', 'HINT') NOT NULL DEFAULT 'STEM',
  `file_path` VARCHAR(500) NOT NULL,
  `file_name` VARCHAR(255) NOT NULL,
  `mime_type` VARCHAR(100) DEFAULT NULL,
  `file_size` INT UNSIGNED DEFAULT NULL,
  `ordinal` SMALLINT UNSIGNED DEFAULT 1,
  `alt_text` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_qmedia_question` (`question_id`),
  CONSTRAINT `fk_qmedia_question` FOREIGN KEY (`question_id`) REFERENCES `qb_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 9: QUESTION TAGS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `qb_tags` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `code` VARCHAR(50) NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `category` VARCHAR(50) DEFAULT NULL,
  `color_code` VARCHAR(7) DEFAULT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tag_tenant_code` (`tenant_id`, `code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `qb_question_tag_jnt` (
  `question_id` BIGINT UNSIGNED NOT NULL,
  `tag_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`question_id`, `tag_id`),
  CONSTRAINT `fk_qtag_question` FOREIGN KEY (`question_id`) REFERENCES `qb_questions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qtag_tag` FOREIGN KEY (`tag_id`) REFERENCES `qb_tags` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 10: QUESTION VERSION HISTORY
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `qb_question_versions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id` BIGINT UNSIGNED NOT NULL,
  `version` INT UNSIGNED NOT NULL,
  `data_snapshot` JSON NOT NULL,                  -- Full question data
  `change_reason` VARCHAR(255) DEFAULT NULL,
  `changed_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qversion` (`question_id`, `version`),
  CONSTRAINT `fk_qversion_question` FOREIGN KEY (`question_id`) REFERENCES `qb_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 11: QUESTION ANALYTICS (Psychometric Data)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `qb_question_analytics` (
  `question_id` BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  `total_attempts` INT UNSIGNED DEFAULT 0,
  `correct_attempts` INT UNSIGNED DEFAULT 0,
  `partial_attempts` INT UNSIGNED DEFAULT 0,
  `avg_time_seconds` INT UNSIGNED DEFAULT NULL,
  `min_time_seconds` INT UNSIGNED DEFAULT NULL,
  `max_time_seconds` INT UNSIGNED DEFAULT NULL,
  
  -- Psychometric indices
  `difficulty_index` DECIMAL(4,3) DEFAULT NULL,   -- correct/total (0.0-1.0)
  `discrimination_index` DECIMAL(4,3) DEFAULT NULL, -- (top27% - bottom27%)/n
  `point_biserial` DECIMAL(4,3) DEFAULT NULL,     -- Correlation coefficient
  
  `discrimination_status` ENUM('EXCELLENT', 'GOOD', 'FAIR', 'POOR', 'REVISE') DEFAULT NULL,
  `last_used` DATE DEFAULT NULL,
  `last_calculated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  CONSTRAINT `fk_qanalytics_question` FOREIGN KEY (`question_id`) REFERENCES `qb_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- END OF FILE 2: QUESTION BANK SCHEMA
-- =====================================================================
