-- ========================================================================================================
-- STUDENT & PARENT → TEACHER FEEDBACK  —  v1.0
-- ========================================================================================================
-- Scope   : Tenant DB (per school)
-- DB      : MySQL 8+
-- Module  : StudentProfile (std_*)
-- Author  : DB Architect
-- Date    : 2026-04-09
--
-- PURPOSE
-- ───────
-- Capture feedback from Students AND Parents about their teachers, for both:
--   (a) Class Teachers (homeroom + assistance_class_teacher)  — from sch_class_section_jnt
--   (b) Subject Teachers (per subject per class-section)     — from tt_activity_teacher
--
-- DESIGN OVERVIEW
-- ───────────────
-- Feedback is structured and cycle-based:
--
--   Admin → creates a Feedback CYCLE (e.g. "Q1 2025-26 Teacher Feedback", Oct 1-15)
--       ↓
--   Cycle references two TEMPLATES (class teacher template + subject teacher template)
--       ↓
--   Each TEMPLATE contains ordered QUESTIONS grouped under CATEGORIES
--       ↓
--   During the cycle, Students and Parents submit RESPONSES (one per teacher)
--       ↓
--   Each response has ANSWERS (one row per question)
--       ↓
--   After cycle closes → SUMMARY table is computed for fast dashboards
--
-- ANONYMITY MODEL
-- ───────────────
-- Respondent identity (student_id/guardian_id/user_id) is ALWAYS stored for:
--   • Audit trail / abuse prevention
--   • One-response-per-respondent-per-teacher deduplication
-- The `is_anonymous_to_teacher` flag controls whether the TEACHER's dashboard view
-- shows respondent names or just "Anonymous Student / Anonymous Parent".
-- Admin/Principal can always see the full identity.
--
-- DEPENDENCIES (all existing)
-- ───────────────────────────
--   sys_users                         — authenticated user (student, parent, teacher, admin)
--   sch_employees                     — teacher (where is_teacher = 1)
--   sch_class_section_jnt             — class teacher + assistance_class_teacher references
--   sch_subjects                      — subject being taught
--   sch_org_academic_sessions_jnt     — academic session
--   std_students                      — student (feedback is ABOUT student's teacher)
--   std_student_academic_sessions     — locks student context (year + class-section)
--   std_guardians                     — parent/guardian
--
-- TABLE LIST (7 new tables)
-- ─────────────────────────
--   1. std_teacher_feedback_cycles          — Cycle definition: window, scope, templates, flags
--   2. std_teacher_feedback_categories      — Feedback categories (Teaching, Communication, etc.)
--   3. std_teacher_feedback_templates       — Question set master
--   4. std_teacher_feedback_questions       — Questions inside a template
--   5. std_teacher_feedback_responses       — Submission header (1 per respondent × teacher × cycle)
--   6. std_teacher_feedback_answers         — Individual question answers (1 per question per response)
--   7. std_teacher_feedback_summary         — Materialized aggregate for teacher dashboards
-- ========================================================================================================


-- ---------------------------------------------------------------------------
-- 1. std_teacher_feedback_cycles
-- ---------------------------------------------------------------------------
-- Defines a feedback window. Admin creates one per term/quarter/annual.
-- The cycle determines WHO can give feedback, WHEN, and with WHICH template.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `std_teacher_feedback_cycles` (
  `id`                            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`                          VARCHAR(50)  NOT NULL COMMENT 'Unique code: Q1_2025_26, ANNUAL_2025_26, etc.',
  `name`                          VARCHAR(200) NOT NULL COMMENT 'Display name: "Q1 2025-26 Teacher Feedback"',
  `description`                   VARCHAR(500) DEFAULT NULL,
  -- Context
  `academic_session_id`           INT UNSIGNED NOT NULL COMMENT 'FK → sch_org_academic_sessions_jnt.id',
  `term_label`                    VARCHAR(50)  DEFAULT NULL COMMENT 'Q1, Q2, Mid-Term, Annual, etc.',
  -- Window
  `start_date`                    DATE NOT NULL COMMENT 'First day respondents can submit',
  `end_date`                      DATE NOT NULL COMMENT 'Last day respondents can submit',
  -- Templates
  `class_teacher_template_id`     INT UNSIGNED DEFAULT NULL COMMENT 'FK → std_teacher_feedback_templates — template for class-teacher feedback (NULL = class teacher feedback disabled in this cycle)',
  `subject_teacher_template_id`   INT UNSIGNED DEFAULT NULL COMMENT 'FK → std_teacher_feedback_templates — template for subject-teacher feedback (NULL = subject teacher feedback disabled)',
  -- Respondent scope
  `allow_student_feedback`        TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = students can submit',
  `allow_parent_feedback`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = parents can submit',
  -- Teacher/Class scope (if scope_type = All, all currently-assigned teachers are targeted)
  `scope_type`                    ENUM('All','Specific_Classes','Specific_Teachers') NOT NULL DEFAULT 'All',
  `scope_class_section_ids_json`  JSON DEFAULT NULL COMMENT 'Array of sch_class_section_jnt.id — used when scope_type = Specific_Classes',
  `scope_teacher_user_ids_json`   JSON DEFAULT NULL COMMENT 'Array of sys_users.id — used when scope_type = Specific_Teachers',
  -- Anonymity
  `is_anonymous_to_teacher`       TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = teacher dashboard shows "Anonymous" instead of respondent name',
  -- Publication
  `is_published_to_teachers`      TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = teachers can view aggregated results on their dashboard',
  `published_at`                  TIMESTAMP NULL DEFAULT NULL,
  `published_by`                  INT UNSIGNED DEFAULT NULL COMMENT 'FK → sys_users.id (admin/principal who published)',
  -- FSM
  `status`                        ENUM('Draft','Active','Closed','Published','Cancelled') NOT NULL DEFAULT 'Draft' COMMENT 'Draft → Active (on start_date) → Closed (on end_date) → Published → optional Cancelled',
  -- Instructions to respondent
  `instructions`                  TEXT DEFAULT NULL COMMENT 'Optional instructions shown at top of feedback form',
  -- Audit
  `is_active`                     TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`                    INT UNSIGNED DEFAULT NULL,
  `created_at`                    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`                    TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tfc_code` (`code`, `deleted_at`),
  INDEX `idx_tfc_session`     (`academic_session_id`),
  INDEX `idx_tfc_status`      (`status`),
  INDEX `idx_tfc_window`      (`start_date`, `end_date`),
  INDEX `idx_tfc_active`      (`is_active`),
  CONSTRAINT `fk_tfc_session`      FOREIGN KEY (`academic_session_id`)         REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tfc_ct_template`  FOREIGN KEY (`class_teacher_template_id`)   REFERENCES `std_teacher_feedback_templates` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tfc_st_template`  FOREIGN KEY (`subject_teacher_template_id`) REFERENCES `std_teacher_feedback_templates` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tfc_created_by`   FOREIGN KEY (`created_by`)                  REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tfc_published_by` FOREIGN KEY (`published_by`)                REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Feedback cycle master — defines a periodic window during which respondents can submit teacher feedback';


-- ---------------------------------------------------------------------------
-- 2. std_teacher_feedback_categories
-- ---------------------------------------------------------------------------
-- Dimensional themes of feedback. Questions in a template are grouped by category.
-- Examples: Teaching Style, Communication, Fairness, Punctuality, Subject Knowledge,
--           Classroom Management, Homework Quality, Approachability
-- Seeded by school admin during module setup.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `std_teacher_feedback_categories` (
  `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`            VARCHAR(30)  NOT NULL COMMENT 'TEACHING, COMMUNICATION, FAIRNESS, PUNCTUALITY, etc.',
  `name`            VARCHAR(100) NOT NULL COMMENT 'Display name',
  `description`     VARCHAR(255) DEFAULT NULL,
  `icon`            VARCHAR(50)  DEFAULT NULL COMMENT 'Icon class for UI (e.g., fa-chalkboard-teacher)',
  `display_order`   TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `applicable_for`  ENUM('Class_Teacher','Subject_Teacher','Both') NOT NULL DEFAULT 'Both' COMMENT 'Which teacher type does this category apply to?',
  `is_active`       TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`      INT UNSIGNED DEFAULT NULL,
  `created_at`      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`      TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tfcat_code` (`code`, `deleted_at`),
  INDEX `idx_tfcat_active`   (`is_active`, `display_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Feedback theme/dimension master — groups questions under a category';


-- ---------------------------------------------------------------------------
-- 3. std_teacher_feedback_templates
-- ---------------------------------------------------------------------------
-- A reusable question set. A cycle references up to two templates
-- (one for Class Teacher feedback, one for Subject Teacher feedback).
-- Different templates can target different respondent types (Student vs Parent).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `std_teacher_feedback_templates` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`                  VARCHAR(50)  NOT NULL COMMENT 'Unique: CT_STUDENT_V1, ST_PARENT_V2, etc.',
  `name`                  VARCHAR(200) NOT NULL,
  `description`           VARCHAR(500) DEFAULT NULL,
  -- Scope
  `applies_to`            ENUM('Class_Teacher','Subject_Teacher','Both') NOT NULL
                          COMMENT 'Which teacher type this template is designed for',
  `respondent_type`       ENUM('Student','Parent','Both') NOT NULL
                          COMMENT 'Who can use this template: Student | Parent | Both',
  -- Scoring
  `overall_rating_method` ENUM('Weighted_Average','Simple_Average','Manual_Only','None') NOT NULL DEFAULT 'Weighted_Average'
                          COMMENT 'How std_teacher_feedback_responses.overall_rating is derived from answers',
  `rating_scale_max`      TINYINT UNSIGNED NOT NULL DEFAULT 5 COMMENT 'Max value for Rating_* questions (5 or 10)',
  -- Version & Status
  `version`               VARCHAR(10) NOT NULL DEFAULT '1.0',
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `is_locked`             TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = template is in use by a cycle; questions cannot be edited',
  -- Audit
  `created_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tft_code` (`code`, `deleted_at`),
  INDEX `idx_tft_applies`    (`applies_to`, `respondent_type`),
  INDEX `idx_tft_active`     (`is_active`),
  CONSTRAINT `fk_tft_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Feedback template (question-set) master — reusable across multiple cycles';


-- ---------------------------------------------------------------------------
-- 4. std_teacher_feedback_questions
-- ---------------------------------------------------------------------------
-- Individual questions within a template, grouped by category, with configurable type.
--
-- question_type semantics:
--   Rating_5      → numeric rating 1-5 (stored in answers.rating_value)
--   Rating_10     → numeric rating 1-10
--   Likert_5      → Strongly Disagree/Disagree/Neutral/Agree/Strongly Agree (stored as 1-5)
--   Emoji_5       → 5-point emoji scale (😡😕😐🙂😊) stored 1-5 + emoji_value code
--   Yes_No        → boolean (stored in answers.boolean_answer)
--   Multi_Choice  → one of options_json codes (stored in answers.selected_option_code)
--   Free_Text     → open text (stored in answers.text_answer)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `std_teacher_feedback_questions` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `template_id`           INT UNSIGNED NOT NULL COMMENT 'FK → std_teacher_feedback_templates.id',
  `category_id`           INT UNSIGNED DEFAULT NULL COMMENT 'FK → std_teacher_feedback_categories.id (NULL = uncategorised)',
  -- Content
  `code`                  VARCHAR(50)  NOT NULL COMMENT 'Stable code (used in exports, API); unique within template',
  `question_text`         TEXT         NOT NULL COMMENT 'The question shown to respondent',
  `help_text`             VARCHAR(500) DEFAULT NULL COMMENT 'Optional clarification / example shown below the question',
  `display_order`         SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  -- Type & Config
  `question_type`         ENUM('Rating_5','Rating_10','Likert_5','Emoji_5','Yes_No','Multi_Choice','Free_Text') NOT NULL DEFAULT 'Rating_5',
  `is_required`           TINYINT(1) NOT NULL DEFAULT 1,
  `is_reverse_scored`     TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = higher rating is worse (e.g., "How often does the teacher arrive late?")',
  `weight`                DECIMAL(4,2) NOT NULL DEFAULT 1.00 COMMENT 'Weight in overall_rating calculation (Weighted_Average method)',
  -- Options (for Multi_Choice only)
  `options_json`          JSON DEFAULT NULL
                          COMMENT 'Array of {code, label, value} for Multi_Choice. Example: [{"code":"A","label":"Always","value":5},{"code":"S","label":"Sometimes","value":3},{"code":"N","label":"Never","value":1}]',
  -- Respondent filter (NULL = both)
  `respondent_type`       ENUM('Student','Parent','Both') NOT NULL DEFAULT 'Both'
                          COMMENT 'Some questions may only be shown to Student OR Parent, others to Both',
  -- Audit
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tfq_template_code` (`template_id`, `code`, `deleted_at`),
  INDEX `idx_tfq_template`  (`template_id`, `display_order`),
  INDEX `idx_tfq_category`  (`category_id`),
  INDEX `idx_tfq_active`    (`is_active`),
  CONSTRAINT `fk_tfq_template` FOREIGN KEY (`template_id`) REFERENCES `std_teacher_feedback_templates` (`id`)  ON DELETE CASCADE,
  CONSTRAINT `fk_tfq_category` FOREIGN KEY (`category_id`) REFERENCES `std_teacher_feedback_categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Questions inside a feedback template — grouped by category, configurable type & weight';


-- ---------------------------------------------------------------------------
-- 5. std_teacher_feedback_responses
-- ---------------------------------------------------------------------------
-- Core submission record. One row per (respondent × teacher × target_type × cycle).
--
-- Dedup rules enforced via generated columns in the UNIQUE index:
--   • subject_id_uq       = COALESCE(subject_id, 0)       — because subject_id is NULL for class teachers
--   • guardian_id_uq      = COALESCE(guardian_id, 0)      — because guardian_id is NULL for student submissions
--
-- This guarantees:
--   - A student can give at most ONE class-teacher feedback per teacher per cycle
--   - A student can give at most ONE subject-teacher feedback per teacher+subject per cycle
--   - A parent (identified by guardian_id) can submit feedback independent of the student account
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `std_teacher_feedback_responses` (
  `id`                            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  -- Cycle & Template snapshot
  `cycle_id`                      INT UNSIGNED NOT NULL COMMENT 'FK → std_teacher_feedback_cycles.id',
  `template_id`                   INT UNSIGNED NOT NULL COMMENT 'FK → std_teacher_feedback_templates.id (snapshot for audit stability)',
  -- Respondent identity
  `respondent_type`               ENUM('Student','Parent') NOT NULL,
  `respondent_user_id`            INT UNSIGNED NOT NULL COMMENT 'FK → sys_users.id — actual submitter',
  `student_id`                    INT UNSIGNED NOT NULL COMMENT 'FK → std_students.id — always populated (for parent, this is their child)',
  `guardian_id`                   INT UNSIGNED DEFAULT NULL COMMENT 'FK → std_guardians.id — populated only when respondent_type = Parent',
  `student_academic_session_id`   INT UNSIGNED NOT NULL COMMENT 'FK → std_student_academic_sessions.id — locks student context (year + class-section)',
  -- Feedback target
  `feedback_target_type`          ENUM('Class_Teacher','Assistant_Class_Teacher','Subject_Teacher') NOT NULL
                                  COMMENT 'Which teacher role is being rated',
  `teacher_user_id`               INT UNSIGNED NOT NULL COMMENT 'FK → sys_users.id — the teacher being rated (matches sch_class_section_jnt.class_teacher_id pattern)',
  `teacher_employee_id`           INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_employees.id — denormalised for fast joins to teacher profile',
  `class_section_id`              INT UNSIGNED NOT NULL COMMENT 'FK → sch_class_section_jnt.id — the class-section in which this teacher teaches the respondent',
  `subject_id`                    INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_subjects.id — populated only for feedback_target_type = Subject_Teacher',
  `tt_activity_id`                INT UNSIGNED DEFAULT NULL COMMENT 'FK → tt_activity.id — optional; links feedback to the exact timetable activity (subject-teacher only)',
  -- Dedup helper generated columns (allow UNIQUE index on nullable FKs)
  `subject_id_uq`                 INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`subject_id`, 0)) STORED,
  `guardian_id_uq`                INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`guardian_id`, 0)) STORED,
  -- Ratings
  `overall_rating`                DECIMAL(4,2) DEFAULT NULL COMMENT 'Derived from answers per template.overall_rating_method; NULL if Manual_Only or None',
  `overall_comment`               TEXT DEFAULT NULL COMMENT 'Single free-text summary field captured alongside structured answers',
  -- Flags (snapshot from cycle at submission time)
  `is_anonymous_to_teacher`       TINYINT(1) NOT NULL DEFAULT 1,
  -- Status FSM
  `status`                        ENUM('Draft','Submitted','Withdrawn') NOT NULL DEFAULT 'Draft'
                                  COMMENT 'Draft → Submitted (locks response) → Withdrawn (respondent withdraws before cycle closes)',
  `submitted_at`                  TIMESTAMP NULL DEFAULT NULL,
  `withdrawn_at`                  TIMESTAMP NULL DEFAULT NULL,
  `withdrawn_reason`              VARCHAR(255) DEFAULT NULL,
  -- Audit metadata
  `submission_ip`                 VARCHAR(45) DEFAULT NULL COMMENT 'IP address of submitter (IPv4 or IPv6)',
  `submission_user_agent`         VARCHAR(255) DEFAULT NULL COMMENT 'Browser/device info for audit',
  `created_at`                    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`                    TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  -- Dedup: one response per respondent per teacher per target per cycle
  UNIQUE KEY `uq_tfr_dedup` (
    `cycle_id`,
    `respondent_user_id`,
    `student_id`,
    `teacher_user_id`,
    `feedback_target_type`,
    `subject_id_uq`,
    `guardian_id_uq`,
    `deleted_at`
  ),
  -- Query indexes
  INDEX `idx_tfr_cycle`           (`cycle_id`, `status`),
  INDEX `idx_tfr_teacher`         (`teacher_user_id`, `cycle_id`),
  INDEX `idx_tfr_teacher_emp`     (`teacher_employee_id`),
  INDEX `idx_tfr_student`         (`student_id`, `cycle_id`),
  INDEX `idx_tfr_guardian`        (`guardian_id`, `cycle_id`),
  INDEX `idx_tfr_class_section`   (`class_section_id`, `feedback_target_type`),
  INDEX `idx_tfr_subject`         (`subject_id`),
  INDEX `idx_tfr_status`          (`status`),
  INDEX `idx_tfr_submitted_at`    (`submitted_at`),
  -- Foreign Keys
  CONSTRAINT `fk_tfr_cycle`            FOREIGN KEY (`cycle_id`)                    REFERENCES `std_teacher_feedback_cycles` (`id`)  ON DELETE RESTRICT,
  CONSTRAINT `fk_tfr_template`         FOREIGN KEY (`template_id`)                 REFERENCES `std_teacher_feedback_templates` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tfr_respondent_user`  FOREIGN KEY (`respondent_user_id`)          REFERENCES `sys_users` (`id`)                    ON DELETE RESTRICT,
  CONSTRAINT `fk_tfr_student`          FOREIGN KEY (`student_id`)                  REFERENCES `std_students` (`id`)                 ON DELETE CASCADE,
  CONSTRAINT `fk_tfr_guardian`         FOREIGN KEY (`guardian_id`)                 REFERENCES `std_guardians` (`id`)                ON DELETE SET NULL,
  CONSTRAINT `fk_tfr_std_acad_session` FOREIGN KEY (`student_academic_session_id`) REFERENCES `std_student_academic_sessions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tfr_teacher_user`     FOREIGN KEY (`teacher_user_id`)             REFERENCES `sys_users` (`id`)                    ON DELETE RESTRICT,
  CONSTRAINT `fk_tfr_teacher_emp`      FOREIGN KEY (`teacher_employee_id`)         REFERENCES `sch_employees` (`id`)                ON DELETE SET NULL,
  CONSTRAINT `fk_tfr_class_section`    FOREIGN KEY (`class_section_id`)            REFERENCES `sch_class_section_jnt` (`id`)        ON DELETE RESTRICT,
  CONSTRAINT `fk_tfr_subject`          FOREIGN KEY (`subject_id`)                  REFERENCES `sch_subjects` (`id`)                 ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Core feedback submission — one row per respondent × teacher × target × cycle';
-- Notes:
--   1. If respondent_type = 'Student'  → guardian_id MUST be NULL
--   2. If respondent_type = 'Parent'   → guardian_id MUST NOT be NULL
--   3. If feedback_target_type = 'Subject_Teacher' → subject_id MUST NOT be NULL
--   4. If feedback_target_type IN ('Class_Teacher','Assistant_Class_Teacher') → subject_id SHOULD be NULL
--   5. (application-layer validation — can be enforced via CHECK constraints in MySQL 8.0.16+ if desired)


-- ---------------------------------------------------------------------------
-- 6. std_teacher_feedback_answers
-- ---------------------------------------------------------------------------
-- Individual question-level answers. One row per (response × question).
-- Only ONE of (rating_value, boolean_answer, selected_option_code, text_answer, emoji_value)
-- is populated per row, depending on the question_type.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `std_teacher_feedback_answers` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `response_id`           INT UNSIGNED NOT NULL COMMENT 'FK → std_teacher_feedback_responses.id',
  `question_id`           INT UNSIGNED NOT NULL COMMENT 'FK → std_teacher_feedback_questions.id (snapshot for audit)',
  -- Snapshot of question metadata at submission time (so analytics survive template edits)
  `question_type_snapshot` ENUM('Rating_5','Rating_10','Likert_5','Emoji_5','Yes_No','Multi_Choice','Free_Text') NOT NULL,
  `category_id_snapshot`  INT UNSIGNED DEFAULT NULL COMMENT 'Snapshot of question.category_id at submission time',
  `weight_snapshot`       DECIMAL(4,2) NOT NULL DEFAULT 1.00 COMMENT 'Snapshot of question.weight at submission time',
  -- Answer payload (populated based on question_type_snapshot)
  `rating_value`          DECIMAL(4,2) DEFAULT NULL COMMENT 'For Rating_5 / Rating_10 / Likert_5 / Emoji_5',
  `boolean_answer`        TINYINT(1)   DEFAULT NULL COMMENT 'For Yes_No: 1 = Yes, 0 = No',
  `selected_option_code`  VARCHAR(50)  DEFAULT NULL COMMENT 'For Multi_Choice: the code from questions.options_json',
  `selected_option_value` DECIMAL(4,2) DEFAULT NULL COMMENT 'Numeric value of the selected option (for aggregation)',
  `text_answer`           TEXT         DEFAULT NULL COMMENT 'For Free_Text (and optional comment on other types)',
  `emoji_value`           VARCHAR(20)  DEFAULT NULL COMMENT 'For Emoji_5: emoji code (angry|sad|neutral|smile|happy)',
  -- Audit
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tfa_response_question` (`response_id`, `question_id`),
  INDEX `idx_tfa_response`  (`response_id`),
  INDEX `idx_tfa_question`  (`question_id`),
  INDEX `idx_tfa_category`  (`category_id_snapshot`),
  CONSTRAINT `fk_tfa_response` FOREIGN KEY (`response_id`) REFERENCES `std_teacher_feedback_responses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tfa_question` FOREIGN KEY (`question_id`) REFERENCES `std_teacher_feedback_questions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tfa_category` FOREIGN KEY (`category_id_snapshot`) REFERENCES `std_teacher_feedback_categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Individual question answers — one row per question per response';


-- ---------------------------------------------------------------------------
-- 7. std_teacher_feedback_summary
-- ---------------------------------------------------------------------------
-- Materialized aggregate for the Teacher Dashboard.
-- One row per (cycle × teacher × target_type × subject).
-- Computed by the application layer (batch job) after cycle closes, or incrementally
-- on every new submission.
--
-- Use `subject_id_uq` generated column so the UNIQUE constraint works when subject_id IS NULL
-- (class teacher rows).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `std_teacher_feedback_summary` (
  `id`                            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cycle_id`                      INT UNSIGNED NOT NULL COMMENT 'FK → std_teacher_feedback_cycles.id',
  `teacher_user_id`               INT UNSIGNED NOT NULL COMMENT 'FK → sys_users.id',
  `teacher_employee_id`           INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_employees.id (denormalised)',
  `feedback_target_type`          ENUM('Class_Teacher','Assistant_Class_Teacher','Subject_Teacher') NOT NULL,
  `subject_id`                    INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_subjects.id — NULL for class teacher summaries',
  `class_section_id`              INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_class_section_jnt.id — NULL for aggregate across all classes',
  -- Dedup helper
  `subject_id_uq`                 INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`subject_id`, 0)) STORED,
  `class_section_id_uq`           INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`class_section_id`, 0)) STORED,
  -- Response counts
  `total_responses`               SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `student_response_count`        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `parent_response_count`         SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `eligible_respondent_count`     SMALLINT UNSIGNED DEFAULT NULL COMMENT 'Total eligible respondents (used to compute participation_rate)',
  `participation_rate`            DECIMAL(5,2) DEFAULT NULL COMMENT 'Computed: total_responses / eligible_respondent_count × 100',
  -- Ratings
  `average_rating`                DECIMAL(4,2) DEFAULT NULL COMMENT 'Mean of response.overall_rating across all responses',
  `student_average_rating`        DECIMAL(4,2) DEFAULT NULL,
  `parent_average_rating`         DECIMAL(4,2) DEFAULT NULL,
  `rating_distribution_json`      JSON DEFAULT NULL COMMENT 'Histogram: {"1":2,"2":5,"3":15,"4":25,"5":40}',
  `category_averages_json`        JSON DEFAULT NULL COMMENT 'Per-category averages: {"TEACHING":4.2,"COMMUNICATION":4.5,"FAIRNESS":4.1}',
  -- Comments highlights
  `top_positive_comments_json`    JSON DEFAULT NULL COMMENT 'Optional: array of highlighted positive free-text comments',
  `top_concern_comments_json`     JSON DEFAULT NULL COMMENT 'Optional: array of highlighted concern free-text comments',
  -- Lifecycle
  `computed_at`                   TIMESTAMP NULL DEFAULT NULL COMMENT 'Last recomputation time',
  `is_published`                  TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = visible on the target teacher dashboard',
  `published_at`                  TIMESTAMP NULL DEFAULT NULL,
  -- Audit
  `created_at`                    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tfs_dedup` (`cycle_id`, `teacher_user_id`, `feedback_target_type`, `subject_id_uq`, `class_section_id_uq`),
  INDEX `idx_tfs_teacher_published` (`teacher_user_id`, `is_published`),
  INDEX `idx_tfs_cycle`             (`cycle_id`),
  INDEX `idx_tfs_subject`           (`subject_id`),
  CONSTRAINT `fk_tfs_cycle`         FOREIGN KEY (`cycle_id`)            REFERENCES `std_teacher_feedback_cycles` (`id`)  ON DELETE CASCADE,
  CONSTRAINT `fk_tfs_teacher_user`  FOREIGN KEY (`teacher_user_id`)     REFERENCES `sys_users` (`id`)                   ON DELETE RESTRICT,
  CONSTRAINT `fk_tfs_teacher_emp`   FOREIGN KEY (`teacher_employee_id`) REFERENCES `sch_employees` (`id`)               ON DELETE SET NULL,
  CONSTRAINT `fk_tfs_subject`       FOREIGN KEY (`subject_id`)          REFERENCES `sch_subjects` (`id`)                ON DELETE SET NULL,
  CONSTRAINT `fk_tfs_class_section` FOREIGN KEY (`class_section_id`)    REFERENCES `sch_class_section_jnt` (`id`)       ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Materialized feedback aggregate — fast reads for teacher dashboards';


-- ========================================================================================================
-- BUSINESS RULES (enforced in application layer)
-- ========================================================================================================
--
-- SUBMISSION RULES
-- ----------------
-- R1.  Respondent can only submit during cycle window: start_date <= NOW() <= end_date AND status = 'Active'.
-- R2.  Student can submit feedback ONLY for:
--        - their own class teacher (sch_class_section_jnt.class_teacher_id where they are enrolled)
--        - their own assistance class teacher (same row, assistance_class_teacher_id)
--        - subject teachers teaching their class-section (via tt_activity_teacher → tt_activity → matches student's class_section_id)
-- R3.  Parent can submit feedback for the same teachers as their child.
--        Parent must be linked to the student via std_student_guardian_jnt AND
--        std_student_guardian_jnt.can_access_parent_portal = 1.
-- R4.  Parent and student can both submit feedback for the same teacher (counted separately in summary).
-- R5.  Respondent can save as Draft multiple times but Submitted is terminal (cannot edit after submission).
-- R6.  Respondent may Withdraw a Submitted response only BEFORE cycle end_date.
--
-- RATING CALCULATION
-- ------------------
-- R7.  overall_rating in std_teacher_feedback_responses is computed server-side on submission:
--        - Weighted_Average: SUM(answer.rating_value × question.weight) / SUM(question.weight)
--          (only for questions with question_type IN Rating_5, Rating_10, Likert_5, Emoji_5)
--        - Simple_Average:   AVG(answer.rating_value) for same question types
--        - Manual_Only:      overall_rating stays NULL; admin sets manually
--        - None:             overall_rating stays NULL; only qualitative
-- R8.  Reverse-scored questions: rating_value = (scale_max + 1 - raw_value) before aggregation.
--
-- ANONYMITY & VISIBILITY
-- ----------------------
-- R9.  Teacher dashboard queries MUST respect `is_anonymous_to_teacher`:
--        - When 1: never return respondent_user_id, student_id, guardian_id, submission_ip in teacher view.
--        - When 0: full identity may be shown to the target teacher.
-- R10. Cycle must have is_published_to_teachers = 1 AND summary.is_published = 1 for teachers to see results.
-- R11. Admin/Principal can always see full data regardless of flags (for audit).
--
-- DEDUP & INTEGRITY
-- -----------------
-- R12. Application layer enforces the NULL combinations:
--        - Student submission → guardian_id = NULL, respondent_user_id = sys_users.id of the student.
--        - Parent submission → guardian_id is NOT NULL, respondent_user_id = sys_users.id of the guardian.
--        - Class Teacher / Assistant target → subject_id = NULL.
--        - Subject Teacher target → subject_id IS NOT NULL.
-- R13. On every Submitted state change, application recomputes std_teacher_feedback_summary for the
--      affected (cycle, teacher, target_type, subject, class_section) tuple.
-- R14. On Withdrawn, the response is excluded from summary recomputation but retained for audit.
--
-- CYCLE LIFECYCLE
-- ---------------
-- R15. Draft     → set up cycle + templates + scope; not visible to respondents
-- R16. Active    → NOW() >= start_date AND NOW() <= end_date; respondents can submit
-- R17. Closed    → NOW() > end_date; submissions blocked; summary being computed
-- R18. Published → summaries visible on teacher dashboards
-- R19. Cancelled → cycle abandoned; no visibility; responses retained in raw form only
--
-- ========================================================================================================
-- Change Log
-- ========================================================================================================
-- v1.0 (2026-04-09): Initial release — 7 tables for Student & Parent → Teacher feedback
--                    (cycles, categories, templates, questions, responses, answers, summary).
-- ========================================================================================================
