-- =========================================================================
-- QUESTION MODULE (Question Bank & Question Management)
-- =========================================================================

CREATE TABLE IF NOT EXISTS `qns_questions_bank` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,                 -- Unique identifier for tracking ("INSERT INTO slb_questions_bank (uuid) VALUES (UUID_TO_BIN(UUID()))")
  `class_id` INT UNSIGNED DEFAULT NULL,       --  fk -> sch_classes.id optional denormalized FK
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,  --  fk -> sch_subjects.id optional denormalized FK
  `lesson_id` INT UNSIGNED DEFAULT NULL,      --  fk -> slb_lessons.id optional denormalized FK
  `topic_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK -> sch_topics.id (can be root topic or sub-topic depending on level)
  `competency_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to slb_competencies.id
  -- Question Text
  `ques_title` VARCHAR(255) DEFAULT NULL,       -- title of the question (For System use)
  `ques_title_display` TINYINT(1) DEFAULT 0,    -- display title? (1=Yes, 0=No)
  `question_content` TEXT DEFAULT NULL,         -- header of the question (For User Display)
  `content_format` ENUM('TEXT','HTML','MARKDOWN','LATEX','JSON') DEFAULT 'TEXT', -- format of the question content
  `teacher_explanation` TEXT DEFAULT NULL,      -- teacher explanation (For User Display)
  -- Question Type & Taxonomy
  `bloom_id` INT UNSIGNED DEFAULT NULL,       -- fk -> slb_bloom_taxonomy.id (Taxonomy)
  `cognitive_skill_id` INT UNSIGNED DEFAULT NULL, -- fk -> slb_cognitive_skill.id (Taxonomy)
  `ques_type_specificity_id` INT UNSIGNED DEFAULT NULL, -- fk -> slb_ques_type_specificity.id (Taxonomy)
  `complexity_level_id` INT UNSIGNED DEFAULT NULL,  -- fk -> slb_complexity_level.id (Taxonomy)
  `question_type_id` INT UNSIGNED NOT NULL,         -- fk -> slb_question_types.id (Question Type)
  -- Question Time to solve & Tags
  `expected_time_to_answer_seconds` INT UNSIGNED DEFAULT NULL, -- Expected time required to answer by students
  `marks` DECIMAL(5,2) DEFAULT 1.00,
  `negative_marks` DECIMAL(5,2) DEFAULT 0.00,
  -- Question Audit & Versioning
  `ques_reviewed` TINYINT(1) NOT NULL DEFAULT 0,              -- True if this question is reviewed
  `ques_reviewed_by` BIGINT UNSIGNED DEFAULT NULL,            --  fk -> sch_users.id (if reviewed by teacher)
  `ques_reviewed_at` TIMESTAMP NULL DEFAULT NULL,
  `ques_reviewed_status` ENUM('PENDING','APPROVED','REJECTED') DEFAULT 'PENDING',
  `current_version` TINYINT UNSIGNED NOT NULL DEFAULT 1,       -- version of the question (for history)
  -- Question Usage
  `for_quiz` TINYINT(1) NOT NULL DEFAULT 1,        -- True if this question is for quiz
  `for_assessment` TINYINT(1) NOT NULL DEFAULT 1,  -- True if this question is for assessment
  `for_exam` TINYINT(1) NOT NULL DEFAULT 1,        -- True if this question is for exam
  -- Question Ownership
  `ques_owner` ENUM('PrimeGurukul','School') NOT NULL DEFAULT 'PrimeGurukul',
  `created_by_AI` TINYINT(1) DEFAULT 0,            -- True if this question is created by AI
  `created_by` BIGINT UNSIGNED DEFAULT NULL,       -- fk -> sch_users.id or teachers.id. If created by AI then this will be NULL
  `is_school_specific` TINYINT(1) DEFAULT 0,       -- True if this question is school-specific
  -- QUESTIONS AVAILABILITY
  `availability` ENUM('GLOBAL','SCHOOL_ONLY','CLASS_ONLY','SECTION_ONLY','ENTITY_ONLY','STUDENT_ONLY') DEFAULT 'GLOBAL',  -- visibility of the question
  `selected_entity_group_id` BIGINT UNSIGNED DEFAULT NULL,  -- fk -> slb_entity_groups.id (if selected availability is 'ENTITY_ONLY')
  `selected_section_id` BIGINT UNSIGNED DEFAULT NULL,       -- fk -> sch_sections.id (if selected availability is 'SECTION_ONLY')
  `selected_student_id` BIGINT UNSIGNED DEFAULT NULL,       -- fk -> sch_students.id (if selected availability is 'STUDENT_ONLY')
  -- QUESTION SOURCE & REFERENCE
  `book_id` BIGINT UNSIGNED DEFAULT NULL,         -- book id (FK -> slb_books.id)
  `book_page_ref` VARCHAR(50) DEFAULT NULL,       -- book page reference (e.g., "Chapter 3, Page 12")
  `external_ref` VARCHAR(100) DEFAULT NULL,       -- for mapping to external banks
  `reference_material` TEXT DEFAULT NULL,         -- e.g., book section, web link
  -- Status
  `status` ENUM('DRAFT','IN_REVIEW','APPROVED','REJECTED','PUBLISHED','ARCHIVED') NOT NULL DEFAULT 'DRAFT',
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_ques_uuid` (`uuid`),
  KEY `idx_ques_topic` (`topic_id`),
  KEY `idx_ques_competency` (`competency_id`),
  KEY `idx_ques_class_subject` (`class_id`,`subject_id`),
  KEY `idx_ques_complexity_bloom` (`complexity_level_id`,`bloom_id`),
  KEY `idx_ques_active` (`is_active`),
  KEY `idx_ques_book` (`book_id`),
  KEY `idx_ques_visibility` (`visibility`),
  CONSTRAINT `fk_ques_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `slb_lessons` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_competency` FOREIGN KEY (`competency_id`) REFERENCES `slb_competencies` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_bloom` FOREIGN KEY (`bloom_id`) REFERENCES `slb_bloom_taxonomy` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_cog` FOREIGN KEY (`cognitive_skill_id`) REFERENCES `slb_cognitive_skill` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_timeSpec` FOREIGN KEY (`ques_type_specificity_id`) REFERENCES `slb_ques_type_specificity` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_complexity` FOREIGN KEY (`complexity_level_id`) REFERENCES `slb_complexity_level` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_type` FOREIGN KEY (`question_type_id`) REFERENCES `slb_question_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ques_reviewed_by` FOREIGN KEY (`ques_reviewed_by`) REFERENCES `sch_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_created_by` FOREIGN KEY (`created_by`) REFERENCES `sch_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_selected_entity_group` FOREIGN KEY (`selected_entity_group_id`) REFERENCES `slb_entity_groups` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_selected_section` FOREIGN KEY (`selected_section_id`) REFERENCES `sch_sections` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_selected_student` FOREIGN KEY (`selected_student_id`) REFERENCES `sch_students` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_book` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
-- 1. Questions can have 2 more options as an answer
-- To Insert UUID into BINARY(16) use: INSERT INTO slb_questions_bank (uuid) VALUES (UUID_TO_BIN(UUID()));
-- To Update UUID into BINARY(16) use: UPDATE slb_questions_bank SET uuid = UUID_TO_BIN(UUID());
-- To Read UUID back as string from BINARY(16) use: SELECT BIN_TO_UUID(uuid) FROM slb_questions_bank;

CREATE TABLE IF NOT EXISTS `qns_question_options` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_bank_id` BIGINT UNSIGNED NOT NULL,
  `ordinal` SMALLINT UNSIGNED DEFAULT NULL,    -- ordinal position of this option
  `option_text` TEXT NOT NULL,                 -- text of the option
  `is_correct` TINYINT(1) NOT NULL DEFAULT 0,  -- whether this option is correct
  `Explanation` TEXT DEFAULT NULL,             -- detailed explanation for this option (Why this option is correct / incorrect)
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_opt_question` (`question_bank_id`),
  CONSTRAINT `fk_opt_question` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `qns_question_media_jnt` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_bank_id` BIGINT UNSIGNED NOT NULL,          -- fk to qns_questions_bank.id
  `question_option_id` BIGINT UNSIGNED DEFAULT NULL,    -- fk to qns_question_options.id
  `media_purpose` ENUM('QUESTION','OPTION','QUES_EXPLANATION','OPT_EXPLANATION','RECOMMENDATION') DEFAULT 'QUESTION',
  `media_id` BIGINT UNSIGNED NOT NULL,                   -- fk to qns_media_store.id
  `media_type` ENUM('IMAGE','AUDIO','VIDEO','ATTACHMENT') DEFAULT 'IMAGE',        -- e.g., 'IMAGE','AUDIO','VIDEO','ATTACHMENT'
  `ordinal` SMALLINT UNSIGNED DEFAULT 1,                 -- ordinal position of this media
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_qmedia_question` (`question_bank_id`),
  KEY `idx_qmedia_option` (`question_option_id`),
  CONSTRAINT `fk_qmedia_question` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qmedia_option` FOREIGN KEY (`question_option_id`) REFERENCES `qns_question_options` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qmedia_media` FOREIGN KEY (`media_id`) REFERENCES `qns_media_store` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `qns_question_tags` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qtag_short` (`short_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Laravel Morph Relationship
CREATE TABLE IF NOT EXISTS `qns_question_questiontag_jnt` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `question_bank_id` BIGINT UNSIGNED NOT NULL,
  `tag_id` BIGINT UNSIGNED NOT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_qtag_q_t` (`question_bank_id`,`tag_id`),
  CONSTRAINT `fk_qtag_q` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qtag_tag` FOREIGN KEY (`tag_id`) REFERENCES `qns_question_tags` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `qns_question_versions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_bank_id` BIGINT UNSIGNED NOT NULL,
  `version` INT UNSIGNED NOT NULL,
  `data` JSON NOT NULL,                       -- full snapshot of question (Question_content, options, metadata)
  `version_created_by` BIGINT UNSIGNED DEFAULT NULL,
  `change_reason` VARCHAR(255) DEFAULT NULL,  -- why was this version modified?
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qver_q_v` (`question_bank_id`,`version`),
  CONSTRAINT `fk_qver_q` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `qns_media_store` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` BINARY(16) NOT NULL,
  `owner_type` ENUM('QUESTION','OPTION','EXPLANATION','RECOMMENDATION') NOT NULL,
  `owner_id` BIGINT UNSIGNED NOT NULL,
  `media_type` ENUM('IMAGE','AUDIO','VIDEO','PDF') NOT NULL,
  `file_name` VARCHAR(255),
  `file_path` VARCHAR(255),
  `mime_type` VARCHAR(100),
  `disk` VARCHAR(50),     -- storage disk
  `size` BIGINT UNSIGNED, -- file size in bytes
  `checksum` CHAR(64),    -- file checksum
  `ordinal` SMALLINT UNSIGNED DEFAULT 1,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  UNIQUE KEY `uq_media_uuid` (`uuid`),
  KEY `idx_owner` (`owner_type`, `owner_id`)
);

CREATE TABLE IF NOT EXISTS `qns_question_topic_jnt` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `question_bank_id` BIGINT UNSIGNED NOT NULL,
  `topic_id` BIGINT UNSIGNED NOT NULL,
  `weightage` DECIMAL(5,2) DEFAULT 100.00,  -- weightage of question in topic
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  UNIQUE KEY `uq_qt_q_t` (`question_bank_id`,`topic_id`),
  CONSTRAINT `fk_qt_question` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qt_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `qns_question_statistics` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `question_bank_id` BIGINT UNSIGNED NOT NULL,
  `difficulty_index` DECIMAL(5,2),       -- % students answered correctly
  `discrimination_index` DECIMAL(5,2),   -- Top vs bottom performer delta
  `guessing_factor` DECIMAL(5,2),        -- MCQ only
  `min_time_taken_seconds` INT UNSIGNED DEFAULT NULL,  -- time taken by topper to answer the question
  `max_time_taken_seconds` INT UNSIGNED DEFAULT NULL, -- average time taken to answer by students
  `avg_time_taken_seconds` INT UNSIGNED,
  `total_attempts` INT UNSIGNED DEFAULT 0,
  `last_computed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  UNIQUE KEY `uq_qstats_q` (`question_bank_id`),
  CONSTRAINT `fk_qstats_question` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `qns_question_performance_category_jnt` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `question_bank_id` BIGINT UNSIGNED NOT NULL,
  `performance_category_id` BIGINT UNSIGNED NOT NULL,
  `recommendation_type` ENUM('REVISION','PRACTICE','CHALLENGE') NOT NULL,
  `priority` SMALLINT UNSIGNED DEFAULT 1,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qrec_q_p` (`question_bank_id`, `performance_category_id`),
  CONSTRAINT `fk_qrec_question` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qrec_perf` FOREIGN KEY (`performance_category_id`) REFERENCES `slb_performance_categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- conditions:
-- This directly powers Personalized learning paths, AI-Teacher module, LXP integration
-- This table will map questions to performance categories. using it we can recommend questions to students based on their performance.

CREATE TABLE IF NOT EXISTS `qns_question_usage_log` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `question_bank_id` BIGINT UNSIGNED NOT NULL,    -- FK to qns_questions_bank
  `usage_context` ENUM('QUIZ','ASSESSMENT','EXAM') NOT NULL,
  `context_id` BIGINT UNSIGNED NOT NULL,    -- quiz_id, assessment_id, exam_id
  `used_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  CONSTRAINT `fk_qusage_question` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

