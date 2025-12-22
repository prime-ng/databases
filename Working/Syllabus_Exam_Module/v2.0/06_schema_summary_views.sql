-- =====================================================================
-- SYLLABUS & EXAM MANAGEMENT MODULE - ENHANCED VERSION 2.0
-- FILE 6: SUMMARY TABLES, VIEWS & REPORTING INDEXES
-- =====================================================================
-- These tables optimize reporting queries for large-scale analytics
-- =====================================================================

-- -------------------------------------------------------------------------
-- SECTION 1: ASSESSMENT SUMMARY (Pre-aggregated per assessment)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `rpt_assessment_summary` (
  `assessment_id` BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  
  -- Participation
  `total_assigned` INT UNSIGNED DEFAULT 0,
  `total_started` INT UNSIGNED DEFAULT 0,
  `total_submitted` INT UNSIGNED DEFAULT 0,
  `total_graded` INT UNSIGNED DEFAULT 0,
  `participation_rate` DECIMAL(5,2) DEFAULT 0.00,
  
  -- Scores
  `avg_score_percent` DECIMAL(5,2) DEFAULT NULL,
  `median_score_percent` DECIMAL(5,2) DEFAULT NULL,
  `highest_score` DECIMAL(8,2) DEFAULT NULL,
  `lowest_score` DECIMAL(8,2) DEFAULT NULL,
  `std_deviation` DECIMAL(8,2) DEFAULT NULL,
  
  -- Pass/Fail
  `pass_count` INT UNSIGNED DEFAULT 0,
  `fail_count` INT UNSIGNED DEFAULT 0,
  `pass_rate` DECIMAL(5,2) DEFAULT NULL,
  
  -- Time analysis
  `avg_time_minutes` DECIMAL(7,2) DEFAULT NULL,
  `min_time_minutes` DECIMAL(7,2) DEFAULT NULL,
  `max_time_minutes` DECIMAL(7,2) DEFAULT NULL,
  
  -- Bloom level performance
  `bloom_remember_avg` DECIMAL(5,2) DEFAULT NULL,
  `bloom_understand_avg` DECIMAL(5,2) DEFAULT NULL,
  `bloom_apply_avg` DECIMAL(5,2) DEFAULT NULL,
  `bloom_analyze_avg` DECIMAL(5,2) DEFAULT NULL,
  `bloom_evaluate_avg` DECIMAL(5,2) DEFAULT NULL,
  `bloom_create_avg` DECIMAL(5,2) DEFAULT NULL,
  
  -- Question analysis
  `easiest_question_id` BIGINT UNSIGNED DEFAULT NULL,
  `hardest_question_id` BIGINT UNSIGNED DEFAULT NULL,
  
  `last_calculated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  KEY `idx_summary_tenant` (`tenant_id`),
  KEY `idx_summary_class_subject` (`class_id`, `subject_id`),
  CONSTRAINT `fk_summary_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `asm_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 2: TOPIC PERFORMANCE SUMMARY (Per class-section-topic)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `rpt_topic_performance` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `section_id` INT UNSIGNED DEFAULT NULL,         -- NULL for class-wide
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `topic_id` BIGINT UNSIGNED NOT NULL,
  
  -- Performance metrics
  `student_count` INT UNSIGNED DEFAULT 0,
  `students_attempted` INT UNSIGNED DEFAULT 0,
  `avg_accuracy_percent` DECIMAL(5,2) DEFAULT NULL,
  `avg_mastery_score` DECIMAL(5,2) DEFAULT NULL,
  
  -- Distribution
  `mastered_count` INT UNSIGNED DEFAULT 0,
  `proficient_count` INT UNSIGNED DEFAULT 0,
  `developing_count` INT UNSIGNED DEFAULT 0,
  `beginner_count` INT UNSIGNED DEFAULT 0,
  `not_started_count` INT UNSIGNED DEFAULT 0,
  
  -- Weak topic identification
  `is_weak_topic` TINYINT(1) DEFAULT 0,           -- Below threshold
  `needs_reteaching` TINYINT(1) DEFAULT 0,
  
  `last_calculated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_topic_perf` (`tenant_id`, `academic_session_id`, `class_id`, `section_id`, `topic_id`),
  KEY `idx_topic_perf_topic` (`topic_id`),
  KEY `idx_topic_perf_weak` (`is_weak_topic`),
  CONSTRAINT `fk_topic_perf_topic` FOREIGN KEY (`topic_id`) REFERENCES `syl_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 3: SUBJECT PERFORMANCE SUMMARY (Per class-section-subject)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `rpt_subject_performance` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `section_id` INT UNSIGNED DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  
  -- Assessment count
  `total_assessments` INT UNSIGNED DEFAULT 0,
  `total_quizzes` INT UNSIGNED DEFAULT 0,
  `total_exams` INT UNSIGNED DEFAULT 0,
  
  -- Performance
  `avg_score_percent` DECIMAL(5,2) DEFAULT NULL,
  `student_count` INT UNSIGNED DEFAULT 0,
  
  -- Topic coverage
  `total_topics` INT UNSIGNED DEFAULT 0,
  `topics_covered` INT UNSIGNED DEFAULT 0,
  `syllabus_completion_percent` DECIMAL(5,2) DEFAULT 0.00,
  
  -- Weak topics count
  `weak_topics_count` INT UNSIGNED DEFAULT 0,
  
  `last_calculated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subject_perf` (`tenant_id`, `academic_session_id`, `class_id`, `section_id`, `subject_id`),
  KEY `idx_subject_perf_subject` (`subject_id`),
  CONSTRAINT `fk_subject_perf_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 4: STUDENT PERFORMANCE SUMMARY (Per student-subject)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `rpt_student_performance` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  
  -- Assessment performance
  `assessments_taken` INT UNSIGNED DEFAULT 0,
  `avg_assessment_score` DECIMAL(5,2) DEFAULT NULL,
  `best_assessment_score` DECIMAL(5,2) DEFAULT NULL,
  
  -- Quiz performance
  `quizzes_taken` INT UNSIGNED DEFAULT 0,
  `avg_quiz_score` DECIMAL(5,2) DEFAULT NULL,
  
  -- Exam performance
  `exams_taken` INT UNSIGNED DEFAULT 0,
  `avg_exam_score` DECIMAL(5,2) DEFAULT NULL,
  
  -- Overall
  `overall_avg_score` DECIMAL(5,2) DEFAULT NULL,
  `class_rank` INT UNSIGNED DEFAULT NULL,
  `section_rank` INT UNSIGNED DEFAULT NULL,
  `percentile` DECIMAL(5,2) DEFAULT NULL,
  
  -- Topic analysis
  `total_topics` INT UNSIGNED DEFAULT 0,
  `mastered_topics` INT UNSIGNED DEFAULT 0,
  `weak_topics` INT UNSIGNED DEFAULT 0,
  `topic_mastery_percent` DECIMAL(5,2) DEFAULT 0.00,
  
  -- Bloom performance
  `lot_score` DECIMAL(5,2) DEFAULT NULL,          -- Lower Order Thinking
  `mot_score` DECIMAL(5,2) DEFAULT NULL,          -- Middle Order Thinking
  `hot_score` DECIMAL(5,2) DEFAULT NULL,          -- Higher Order Thinking
  
  -- Trend
  `trend` ENUM('IMPROVING', 'STABLE', 'DECLINING') DEFAULT NULL,
  `last_5_scores` JSON DEFAULT NULL,
  
  `last_calculated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_student_perf` (`tenant_id`, `academic_session_id`, `student_id`, `subject_id`),
  KEY `idx_student_perf_student` (`student_id`),
  KEY `idx_student_perf_subject` (`subject_id`),
  KEY `idx_student_perf_weak` (`weak_topics`),
  CONSTRAINT `fk_student_perf_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_student_perf_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 5: BLOOM LEVEL AGGREGATIONS (For quick queries)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `rpt_bloom_aggregation` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `section_id` INT UNSIGNED DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `bloom_id` INT UNSIGNED NOT NULL,
  
  -- Aggregated metrics
  `total_questions_asked` INT UNSIGNED DEFAULT 0,
  `total_questions_correct` INT UNSIGNED DEFAULT 0,
  `avg_accuracy_percent` DECIMAL(5,2) DEFAULT NULL,
  `student_count` INT UNSIGNED DEFAULT 0,
  
  `last_calculated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_bloom_agg` (`tenant_id`, `academic_session_id`, `class_id`, `section_id`, `subject_id`, `bloom_id`),
  KEY `idx_bloom_agg_bloom` (`bloom_id`),
  CONSTRAINT `fk_bloom_agg_bloom` FOREIGN KEY (`bloom_id`) REFERENCES `qb_bloom_taxonomy` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 6: AUDIT LOG
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sys_audit_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `table_name` VARCHAR(100) NOT NULL,
  `record_id` BIGINT UNSIGNED NOT NULL,
  `action` ENUM('CREATE', 'UPDATE', 'DELETE', 'PUBLISH', 'GRADE', 'SUBMIT', 'ASSIGN', 'ARCHIVE') NOT NULL,
  `old_values` JSON DEFAULT NULL,
  `new_values` JSON DEFAULT NULL,
  `changed_by` BIGINT UNSIGNED DEFAULT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `user_agent` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_audit_table_record` (`table_name`, `record_id`),
  KEY `idx_audit_tenant` (`tenant_id`),
  KEY `idx_audit_action` (`action`),
  KEY `idx_audit_timestamp` (`created_at`),
  KEY `idx_audit_user` (`changed_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- VIEWS FOR COMMON REPORTING QUERIES
-- =========================================================================

-- -------------------------------------------------------------------------
-- VIEW 1: Topic Hierarchy Flattened (For easy querying)
-- -------------------------------------------------------------------------

CREATE OR REPLACE VIEW `vw_topic_hierarchy` AS
SELECT 
  t.id AS topic_id,
  t.tenant_id,
  t.uuid AS topic_uuid,
  t.name AS topic_name,
  t.code AS topic_code,
  t.path,
  t.path_names,
  t.level,
  t.level_name,
  t.parent_id,
  t.analytics_code,
  l.id AS lesson_id,
  l.name AS lesson_name,
  l.code AS lesson_code,
  c.id AS class_id,
  c.name AS class_name,
  c.ordinal AS class_ordinal,
  s.id AS subject_id,
  s.name AS subject_name,
  s.code AS subject_code
FROM syl_topics t
JOIN syl_lessons l ON t.lesson_id = l.id
JOIN sch_classes c ON t.class_id = c.id
JOIN sch_subjects s ON t.subject_id = s.id
WHERE t.is_active = 1 AND t.deleted_at IS NULL;


-- -------------------------------------------------------------------------
-- VIEW 2: Question Bank Overview
-- -------------------------------------------------------------------------

CREATE OR REPLACE VIEW `vw_question_bank` AS
SELECT 
  q.id AS question_id,
  q.tenant_id,
  q.uuid,
  q.stem,
  q.marks,
  q.estimated_time_seconds,
  q.status,
  qt.name AS question_type,
  qt.category AS question_category,
  bt.name AS bloom_level,
  bt.level AS bloom_level_num,
  cl.name AS cognitive_level,
  cx.name AS complexity,
  t.name AS topic_name,
  t.path_names AS topic_path,
  l.name AS lesson_name,
  c.name AS class_name,
  s.name AS subject_name,
  qa.difficulty_index,
  qa.discrimination_index,
  qa.total_attempts
FROM qb_questions q
JOIN qb_question_types qt ON q.question_type_id = qt.id
JOIN qb_bloom_taxonomy bt ON q.bloom_id = bt.id
JOIN qb_cognitive_levels cl ON q.cognitive_level_id = cl.id
JOIN qb_complexity_levels cx ON q.complexity_level_id = cx.id
LEFT JOIN syl_topics t ON q.topic_id = t.id
LEFT JOIN syl_lessons l ON q.lesson_id = l.id
JOIN sch_classes c ON q.class_id = c.id
JOIN sch_subjects s ON q.subject_id = s.id
LEFT JOIN qb_question_analytics qa ON q.id = qa.question_id
WHERE q.is_active = 1 AND q.deleted_at IS NULL;


-- -------------------------------------------------------------------------
-- VIEW 3: Student Gap Analysis
-- -------------------------------------------------------------------------

CREATE OR REPLACE VIEW `vw_student_gap_analysis` AS
SELECT 
  stm.tenant_id,
  stm.student_id,
  st.user_id,
  stm.academic_session_id,
  stm.class_id,
  c.name AS class_name,
  stm.subject_id,
  s.name AS subject_name,
  stm.topic_id,
  t.name AS topic_name,
  t.path_names AS topic_hierarchy,
  t.level AS topic_level,
  t.level_name,
  stm.mastery_level,
  stm.mastery_score,
  stm.avg_score_percent,
  stm.confidence_level,
  stm.is_weak_topic,
  stm.needs_attention,
  stm.weak_reason,
  stm.bloom_remember_score,
  stm.bloom_understand_score,
  stm.bloom_apply_score,
  stm.bloom_analyze_score,
  stm.bloom_evaluate_score,
  stm.bloom_create_score,
  stm.trend,
  stm.total_questions_attempted,
  stm.total_correct,
  pg.prerequisite_topic_id,
  pt.name AS prerequisite_topic_name,
  pt.path_names AS prerequisite_path,
  pg.prerequisite_class_id,
  pg.gap_severity,
  pg.gap_score
FROM anl_student_topic_mastery stm
JOIN std_students st ON stm.student_id = st.id
JOIN sch_classes c ON stm.class_id = c.id
JOIN sch_subjects s ON stm.subject_id = s.id
JOIN syl_topics t ON stm.topic_id = t.id
LEFT JOIN anl_prerequisite_gaps pg ON stm.student_id = pg.student_id 
  AND stm.topic_id = pg.current_topic_id 
  AND pg.is_addressed = 0
LEFT JOIN syl_topics pt ON pg.prerequisite_topic_id = pt.id
WHERE stm.is_weak_topic = 1 OR stm.needs_attention = 1
ORDER BY stm.student_id, stm.mastery_score ASC;


-- -------------------------------------------------------------------------
-- VIEW 4: Assessment Analytics
-- -------------------------------------------------------------------------

CREATE OR REPLACE VIEW `vw_assessment_analytics` AS
SELECT 
  a.id AS assessment_id,
  a.tenant_id,
  a.code,
  a.name AS assessment_name,
  a.assessment_type,
  a.sub_type,
  a.mode,
  a.scheduled_date,
  a.total_marks,
  a.passing_marks,
  c.name AS class_name,
  s.name AS subject_name,
  rs.total_assigned,
  rs.total_submitted,
  rs.participation_rate,
  rs.avg_score_percent,
  rs.median_score_percent,
  rs.pass_rate,
  rs.avg_time_minutes,
  rs.bloom_remember_avg,
  rs.bloom_understand_avg,
  rs.bloom_apply_avg,
  rs.bloom_analyze_avg,
  rs.bloom_evaluate_avg,
  rs.bloom_create_avg
FROM asm_assessments a
JOIN sch_classes c ON a.class_id = c.id
JOIN sch_subjects s ON a.subject_id = s.id
LEFT JOIN rpt_assessment_summary rs ON a.id = rs.assessment_id
WHERE a.status IN ('COMPLETED', 'ARCHIVED') AND a.deleted_at IS NULL;

-- =====================================================================
-- END OF FILE 6: SUMMARY TABLES & VIEWS
-- =====================================================================
