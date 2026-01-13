-- =========================================================================
-- RECOMMENDATION MODULE (Performance Based Recommendations)
-- =========================================================================

CREATE TABLE IF NOT EXISTS `rec_recommendation_materials` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `material_type` ENUM('TEXT','VIDEO','PDF','AUDIO','QUIZ','ASSIGNMENT','LINK') NOT NULL,
  `content` LONGTEXT DEFAULT NULL,      -- HTML / text (for TEXT)
  `media_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to qns_media_store
  `external_url` VARCHAR(500) DEFAULT NULL, -- External URL (for LINK)
  `subject_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to qns_subjects
  `class_id` INT UNSIGNED DEFAULT NULL, -- FK to qns_classes
  `topic_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to qns_topics
  `difficulty_level` ENUM('EASY','MEDIUM','HARD') DEFAULT 'MEDIUM',
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  KEY `idx_material_scope` (`class_id`, `subject_id`, `topic_id`),
  KEY `idx_material_type` (`material_type`),
  KEY `idx_material_active` (`is_active`),
  CONSTRAINT `fk_rmat_media` FOREIGN KEY (`media_id`) REFERENCES `qns_media_store` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rmat_subject` FOREIGN KEY (`subject_id`) REFERENCES `qns_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rmat_class` FOREIGN KEY (`class_id`) REFERENCES `qns_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rmat_topic` FOREIGN KEY (`topic_id`) REFERENCES `qns_topics` (`id`) ON DELETE SET NULL 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `rec_recommendation_rules` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `school_id` BIGINT UNSIGNED DEFAULT NULL, 
  -- NULL = System default rule
  `performance_category_id` BIGINT UNSIGNED NOT NULL, -- FK to slb_performance_categories
  `subject_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to qns_subjects
  `class_id` INT UNSIGNED DEFAULT NULL, -- FK to qns_classes
  `topic_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to qns_topics
  `recommendation_goal` ENUM('REVISION','PRACTICE','REMEDIAL','ADVANCED','ENRICHMENT') NOT NULL,
  `material_type` ENUM('TEXT','VIDEO','PDF','QUIZ','ASSIGNMENT') NOT NULL,
  `max_items` SMALLINT UNSIGNED DEFAULT 5,
  `priority` SMALLINT UNSIGNED DEFAULT 1,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  CONSTRAINT `fk_rule_perf_cat` FOREIGN KEY (`performance_category_id`) REFERENCES `slb_performance_categories`(`id`),
  CONSTRAINT `fk_rule_subject` FOREIGN KEY (`subject_id`) REFERENCES `qns_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rule_class` FOREIGN KEY (`class_id`) REFERENCES `qns_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rule_topic` FOREIGN KEY (`topic_id`) REFERENCES `qns_topics` (`id`) ON DELETE SET NULL
  KEY `idx_rule_scope` (`school_id`, `class_id`, `subject_id`, `topic_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rec_student_recommendations` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` BIGINT UNSIGNED NOT NULL, -- FK to users
  `school_id` BIGINT UNSIGNED NOT NULL, -- FK to schools
  `performance_category_id` BIGINT UNSIGNED NOT NULL, -- FK to slb_performance_categories
  `recommendation_rule_id` BIGINT UNSIGNED NOT NULL, -- FK to rec_recommendation_rules
  `material_id` BIGINT UNSIGNED NOT NULL, -- FK to rec_recommendation_materials
  `recommended_for` ENUM('DAILY','WEEKLY','MONTHLY','EXAM_PREP') DEFAULT 'WEEKLY',
  `status` ENUM('PENDING','VIEWED','IN_PROGRESS','COMPLETED','SKIPPED') DEFAULT 'PENDING',
  `relevance_score` DECIMAL(5,2) DEFAULT NULL, -- for future AI ranking
  `generated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `consumed_at` TIMESTAMP NULL,
  UNIQUE KEY `uq_student_material` (`student_id`, `material_id`),
  KEY `idx_student_status` (`student_id`, `status`),
  KEY `idx_student_school` (`school_id`, `student_id`),
  CONSTRAINT `fk_stud_perf_cat` FOREIGN KEY (`performance_category_id`) REFERENCES `slb_performance_categories`(`id`),
  CONSTRAINT `fk_stud_rule` FOREIGN KEY (`recommendation_rule_id`) REFERENCES `rec_recommendation_rules`(`id`),
  CONSTRAINT `fk_stud_material` FOREIGN KEY (`material_id`) REFERENCES `rec_recommendation_materials`(`id`),
  CONSTRAINT `fk_stud_student` FOREIGN KEY (`student_id`) REFERENCES `users`(`id`),
  CONSTRAINT `fk_stud_school` FOREIGN KEY (`school_id`) REFERENCES `schools`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rec_student_performance_snapshot` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `school_id` BIGINT UNSIGNED NOT NULL,
  `performance_category_id` BIGINT UNSIGNED NOT NULL,
  `recommendation_rule_id` BIGINT UNSIGNED NOT NULL,
  `material_id` BIGINT UNSIGNED NOT NULL,
  `recommended_for` ENUM('DAILY','WEEKLY','MONTHLY','EXAM_PREP') DEFAULT 'WEEKLY',
  `status` ENUM('PENDING','VIEWED','IN_PROGRESS','COMPLETED','SKIPPED') DEFAULT 'PENDING',
  `relevance_score` DECIMAL(5,2) DEFAULT NULL, -- for future AI ranking
  `generated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `consumed_at` TIMESTAMP NULL,
  UNIQUE KEY `uq_student_material` (`student_id`, `material_id`),
  KEY `idx_student_status` (`student_id`, `status`),
  KEY `idx_student_school` (`school_id`, `student_id`),
  CONSTRAINT `fk_stud_perf_cat` FOREIGN KEY (`performance_category_id`) REFERENCES `slb_performance_categories`(`id`),
  CONSTRAINT `fk_stud_rule` FOREIGN KEY (`recommendation_rule_id`) REFERENCES `rec_recommendation_rules`(`id`),
  CONSTRAINT `fk_stud_material` FOREIGN KEY (`material_id`) REFERENCES `rec_recommendation_materials`(`id`),
  CONSTRAINT `fk_stud_student` FOREIGN KEY (`student_id`) REFERENCES `users`(`id`),
  CONSTRAINT `fk_stud_school` FOREIGN KEY (`school_id`) REFERENCES `schools`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rec_student_performance_snapshot` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `school_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `percentage` DECIMAL(5,2) NOT NULL,
  `performance_category_id` BIGINT UNSIGNED NOT NULL,
  `assessment_type` ENUM('QUIZ','TEST','EXAM','TERM','OVERALL') NOT NULL,
  `captured_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `consumed_at` TIMESTAMP NULL,
  KEY `idx_student_perf` (`student_id`, `captured_at`),
  KEY `idx_student_school` (`school_id`, `student_id`),
  CONSTRAINT `fk_stud_perf_cat` FOREIGN KEY (`performance_category_id`) REFERENCES `slb_performance_categories`(`id`),
  CONSTRAINT `fk_stud_student` FOREIGN KEY (`student_id`) REFERENCES `users`(`id`),
  CONSTRAINT `fk_stud_school` FOREIGN KEY (`school_id`) REFERENCES `schools`(`id`),
  CONSTRAINT `fk_stud_class` FOREIGN KEY (`class_id`) REFERENCES `qns_classes`(`id`),
  CONSTRAINT `fk_stud_subject` FOREIGN KEY (`subject_id`) REFERENCES `qns_subjects`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

