-- ============================================================================================================
-- Module - Syllabus
-- ============================================================================================================
	-- We need to create Master table to capture slb_topic_type
	-- level: 0=Topic, 1=Sub-topic, 2=Mini Topic, 3=Sub-Mini Topic, 4=Micro Topic, 5=Sub-Micro Topic, 6=Nano Topic, 7=Ultra Topic,
	-- This table will be used to Generate slb_topics.code and slb_topics.analytics_code.
	-- User can Not change slb_topics.analytics_code, But he can change slb_topics.code as per their choice.
	-- This Table will be set by PG_Team and will not be available for change to School.
	CREATE TABLE IF NOT EXISTS `slb_topic_level_types` (
	`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`level` TINYINT UNSIGNED NOT NULL,              -- e.g., 0=Topic, 1=Sub-topic, 2=Mini Topic, 3=Sub-Mini Topic, 4=Micro Topic, 5=Sub-Micro Topic, 6=Nano Topic, 7=Sub-Nano Topic, 8=Ultra Topic, 9=Sub-Ultra Topic
	`code` VARCHAR(3) NOT NULL,                    -- e.g., (TOP, SBT, MIN, SMN, MIC, SMC, NAN, SNN, ULT, SUT)
	`name` VARCHAR(150) NOT NULL,                   -- e.g., (TOPIC, SUB-TOPIC, MINI TOPIC, SUB-MINI TOPIC, MICRO TOPIC, SUB-MICRO TOPIC, NANO TOPIC, SUB-NANO TOPIC, ULTRA TOPIC, SUB-ULTRA TOPIC)
	`is_active` TINYINT(1) NOT NULL DEFAULT 1,
	`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_topic_type_level` (`level`),
	UNIQUE KEY `uq_topic_type_code` (`code`),
	UNIQUE KEY `uq_topic_type_name` (`name`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- COMPETENCY FRAMEWORK (NEP 2020 ALIGNMENT)
	-- -------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `slb_competency_types` (
			`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
			`code` VARCHAR(20) NOT NULL,   -- e.g. 'KNOWLEDGE','SKILL','ATTITUDE'
			`name` VARCHAR(100) NOT NULL,
			`description` VARCHAR(255) DEFAULT NULL,
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `uq_comp_type_code` (`code`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `slb_competencies` (
			`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
			`uuid` BINARY(16) NOT NULL,
			`parent_id` BIGINT UNSIGNED DEFAULT NULL,     -- FK to self (NULL for root competencies)
			`code` VARCHAR(60) NOT NULL,                 -- e.g. 'KNOWLEDGE','SKILL','ATTITUDE'
			`name` VARCHAR(150) NOT NULL,                -- e.g. 'Knowledge of Linear Equations'
			`short_name` VARCHAR(50) DEFAULT NULL,       -- e.g. 'Linear Equations'
			`description` VARCHAR(255) DEFAULT NULL,     -- e.g. 'Description of Knowledge of Linear Equations'
			`class_id` INT UNSIGNED DEFAULT NULL,         -- FK to sch_classes.id
			`subject_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sch_subjects.id
			`competency_type_id` INT UNSIGNED NOT NULL,   -- FK to slb_competency_types.id
			`domain` ENUM('COGNITIVE', 'AFFECTIVE', 'PSYCHOMOTOR') NOT NULL DEFAULT 'COGNITIVE', -- e.g. 'COGNITIVE'
			`nep_framework_ref` VARCHAR(100) DEFAULT NULL,    -- e.g. 'NEP Framework Reference'
			`ncf_alignment` VARCHAR(100) DEFAULT NULL,        -- e.g. 'NCF Alignment'
			`learning_outcome_code` VARCHAR(50) DEFAULT NULL, -- e.g. 'Learning Outcome Code'
			`path` VARCHAR(500) DEFAULT '/',  -- e.g. 
			`level` TINYINT UNSIGNED DEFAULT 0, -- e.g. 0
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `uq_competency_uuid` (`uuid`),
			UNIQUE KEY `uq_competency_code` (`code`),
			KEY `idx_competency_parent` (`parent_id`),
			KEY `idx_competency_type` (`competency_type_id`),
			CONSTRAINT `fk_competency_parent` FOREIGN KEY (`parent_id`) REFERENCES `slb_competencies` (`id`) ON DELETE CASCADE,
			CONSTRAINT `fk_competency_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
			CONSTRAINT `fk_competency_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
			CONSTRAINT `fk_competency_type` FOREIGN KEY (`competency_type_id`) REFERENCES `slb_competency_types` (`id`) ON DELETE CASCADE
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- Link topics to competencies
	CREATE TABLE IF NOT EXISTS `slb_topic_competency_jnt` (
			`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
			`topic_id` BIGINT UNSIGNED NOT NULL,
			`competency_id` BIGINT UNSIGNED NOT NULL, -- FK to slb_competencies.id
			`weightage` DECIMAL(5,2) DEFAULT NULL,    -- How much topic contributes to competency
			`is_primary` TINYINT(1) DEFAULT 0, -- True if this is the primary competency for this topic
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `uq_tc_topic_competency` (`topic_id`,`competency_id`),
			CONSTRAINT `fk_tc_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE,
			CONSTRAINT `fk_tc_competency` FOREIGN KEY (`competency_id`) REFERENCES `slb_competencies` (`id`) ON DELETE CASCADE
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `slb_bloom_taxonomy` (
			`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
			`code` VARCHAR(20) NOT NULL,   -- e.g. 'REMEMBERING','UNDERSTANDING','APPLYING','ANALYZING','EVALUATING','CREATING'
			`name` VARCHAR(100) NOT NULL,
			`description` VARCHAR(255) DEFAULT NULL,
			`bloom_level` TINYINT UNSIGNED DEFAULT NULL, -- 1-6 for Bloom's revised taxonomy
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `uq_bloom_code` (`code`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `slb_cognitive_skill` (
			`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
			`bloom_id` INT UNSIGNED DEFAULT NULL,       -- slb_bloom_taxonomy.id
			`code` VARCHAR(20) NOT NULL,  -- e.g. 'COG-KNOWLEDGE','COG-SKILL','COG-UNDERSTANDING'
			`name` VARCHAR(100) NOT NULL,
			`description` VARCHAR(255) DEFAULT NULL,
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `uq_cog_code` (`code`),
			CONSTRAINT `fk_cog_bloom` FOREIGN KEY (`bloom_id`) REFERENCES `slb_bloom_taxonomy` (`id`) ON DELETE SET NULL
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `slb_ques_type_specificity` (
			`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
			`cognitive_skill_id` INT UNSIGNED DEFAULT NULL, -- slb_cognitive_skill.id
			`code` VARCHAR(20) NOT NULL,  -- e.g. 'IN_CLASS','HOMEWORK','SUMMATIVE','FORMATIVE'
			`name` VARCHAR(100) NOT NULL,
			`description` VARCHAR(255) DEFAULT NULL,
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `uq_quesTypeSps_code` (`code`),
			CONSTRAINT `fk_quesTypeSps_cognitive` FOREIGN KEY (`cognitive_skill_id`) REFERENCES `slb_cognitive_skill` (`id`) ON DELETE SET NULL
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `slb_complexity_level` (
			`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
			`code` VARCHAR(20) NOT NULL,  -- e.g. 'EASY','MEDIUM','DIFFICULT'
			`name` VARCHAR(50) NOT NULL,
			`complexity_level` TINYINT UNSIGNED DEFAULT NULL,  -- 1=Easy, 2=Medium, 3=Difficult
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `uq_complex_code` (`code`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `slb_question_types` (
			`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
			`code` VARCHAR(20) NOT NULL,  -- e.g. 'MCQ_SINGLE','MCQ_MULTI','SHORT_ANSWER','LONG_ANSWER','MATCH','NUMERIC','FILL_BLANK','CODING'
			`name` VARCHAR(100) NOT NULL, -- e.g. 'Multiple Choice Single Answer','Multiple Choice Multi Answer','Short Answer','Long Answer','Match','Numeric','Fill Blank','Coding'
			`has_options` TINYINT(1) NOT NULL DEFAULT 0,    -- True if this type has options
			`auto_gradable` TINYINT(1) NOT NULL DEFAULT 1,  -- True if this type can be auto-graded (Can System Marked Automatically?)
			`description` TEXT DEFAULT NULL,
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `uq_qtype_code` (`code`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `slb_performance_categories` (
			`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
			-- Identity
			`code` VARCHAR(20) NOT NULL,    -- TOPPER, EXCELLENT, GOOD, AVERAGE, BELOW_AVERAGE, NEED_IMPROVEMENT, POOR etc.
			`name` VARCHAR(100) NOT NULL,
			`description` VARCHAR(255),
			-- Academic meaning
			`level` TINYINT UNSIGNED NOT NULL,    -- 1 = Topper, 2 = Good, 3 = Average, 4 = Below Average, 5 = Poor
			`min_percentage` DECIMAL(5,2) NOT NULL, -- Minimum percentage
			`max_percentage` DECIMAL(5,2) NOT NULL, -- Maximum percentage
			-- AI semantics
			`ai_severity` ENUM('LOW','MEDIUM','HIGH','CRITICAL') DEFAULT 'LOW',
			`ai_default_action` ENUM('ACCELERATE','PROGRESS','PRACTICE','REMEDIATE','ESCALATE') NOT NULL,
			-- UX
			`display_order` SMALLINT UNSIGNED DEFAULT 1,
			`color_code` VARCHAR(10),
			`icon_code` VARCHAR(50),              -- e.g. trophy, warning, alert
			-- Scope & governance
			`scope` ENUM('SCHOOL','CLASS') DEFAULT 'SCHOOL',
			`class_id` BIGINT UNSIGNED DEFAULT NULL,
			-- Control
			`is_system_defined` TINYINT(1) DEFAULT 1, -- system vs school editable
			`auto_retest_required` TINYINT(1) DEFAULT 0, -- Auto Retest Required or Not (if 'True' then System will auto create a Test for the Topic and assign to Student)
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL,
			-- Constraints
			UNIQUE KEY `uq_perf_code` (`code`, `scope`),
			CHECK (`min_percentage` < `max_percentage`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- Conditions:
			-- 1. If 'is_system_defined' is 1, then school can not edit this record.
			-- 2. The Schema does NOT prevent overlapping ranges like:
			--    - min_percentage = 80, max_percentage = 90
			--    - min_percentage = 85, max_percentage = 95
			-- 3. The Schema does NOT prevent ranges that do not cover the full range of 0-100%
			--    - min_percentage = 80, max_percentage = 100
			-- 4. Above 2 needs to be handled at the application level
			-- ✅ Enforce at application/service layer:
					SELECT 1
					FROM slb_performance_categories
					WHERE
					:new_min <= max_percentage
					AND :new_max >= min_percentage
					AND is_active = 1
					LIMIT 1;
			-- If row exists → ❌ reject insert/update
			-- 🎯 Special:
			-- 1. School may want different categorisation for different classes, Which most of the ERP doesn't cover.
			-- 2. School may want to use different categorisation for different subjects, Which most of the ERP doesn't cover.

			CREATE TABLE IF NOT EXISTS `slb_grade_division_master` (
			`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
			-- Identity
			`code` VARCHAR(20) NOT NULL,        -- A, B, C, 1st, 2nd
			`name` VARCHAR(100) NOT NULL,       -- Grade A, First Division
			`description` VARCHAR(255),
			-- Type
			`grading_type` ENUM('GRADE','DIVISION') NOT NULL,
			-- Academic band
			`min_percentage` DECIMAL(5,2) NOT NULL,
			`max_percentage` DECIMAL(5,2) NOT NULL,
			-- Board & compliance
			`board_code` VARCHAR(50),           -- CBSE, ICSE, STATE
			`academic_session_id` BIGINT UNSIGNED NULL,
			-- UX
			`display_order` SMALLINT UNSIGNED DEFAULT 1,
			`color_code` VARCHAR(10),
			-- Scope
			`scope` ENUM('SCHOOL','BOARD','CLASS') DEFAULT 'SCHOOL',
			`class_id` BIGINT UNSIGNED DEFAULT NULL,
			-- Control
			`is_locked` TINYINT(1) DEFAULT 0,   -- locked after result publishing
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP NULL,
			UNIQUE KEY `uq_grade_code` (`code`, `grading_type`, `scope`, `class_id`),
			UNIQUE KEY `uq_scope_range` (`scope`, `class_id`, `min_percentage`, `max_percentage`),
			CHECK (`min_percentage` < `max_percentage`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
			-- Conditions:
			-- 1. The Schema does NOT prevent overlapping ranges like:
			--    - min_percentage = 80, max_percentage = 90
			--    - min_percentage = 85, max_percentage = 95
			-- 2. The Schema does NOT prevent ranges that do not cover the full range of 0-100%
			--    - min_percentage = 80, max_percentage = 100
			-- 3. Above 2 needs to be handled at the application level
			-- ✅ Enforce at application/service layer:
					SELECT 1
					FROM slb_performance_categories
					WHERE
					:new_min <= max_percentage
					AND :new_max >= min_percentage
					AND is_active = 1
					LIMIT 1;
			-- If row exists → ❌ reject insert/update
			-- 🎯 Special:
			-- 1. Scholl may have different System for different Boards / Classes, Which most of the ERP doesn't cover. e.g. Grade system till 8th and then 9-12 Division System
			--    Classes 1–3 → Emerging / Developing / Proficient
			--    Classes 4–8 → Good / Average / Below Average / Need Improvement / Poor
			--    Classes 9–12 → Topper / Excellent / Good / Average / Below Average / Need Improvement / Poor

-- ============================================================================================================
-- Module - Question Bank
-- ============================================================================================================

	-- Question Usage Type (Quiz / Quest / Exam)
	CREATE TABLE `qns_question_usage_type` (
			`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
			`code` VARCHAR(50) NOT NULL,  -- e.g. 'QUIZ','QUEST','ONLINE_EXAM','OFFLINE_EXAM','UT_TEST'
			`name` VARCHAR(100) NOT NULL, -- e.g. 'Quiz','Quest','Online Exam','Offline Exam','Unit Test'
			`description` TEXT DEFAULT NULL,
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`deleted_at` TIMESTAMP DEFAULT NULL,
			UNIQUE KEY `uq_q_usage_type_code` (`code`)
			UNIQUE KEY `uq_q_usage_type_name` (`name`)
	);

-- ============================================================================================================
-- Module - Recommendations
-- ============================================================================================================
