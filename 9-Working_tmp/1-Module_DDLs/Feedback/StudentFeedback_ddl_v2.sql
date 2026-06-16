-- ========================================================================================================
-- GENERIC FEEDBACK MODULE  —  v2.0
-- ========================================================================================================
-- Scope   : Tenant DB (per school)
-- DB      : MySQL 8+
-- Prefix  : fbk_*  (dedicated Feedback module — NOT tied to StudentProfile anymore)
-- Author  : DB Architect
-- Date    : 2026-04-09
-- Replaces: StudentFeedback_ddl_v1.sql  (v1 supported only Student/Parent → Teacher)
--
-- ════════════════════════════════════════════════════════════════════════════════════════════════════════
--  WHY A GENERIC MODULE?
-- ════════════════════════════════════════════════════════════════════════════════════════════════════════
-- v1 was hardcoded to "Student/Parent → Teacher". A school needs feedback collection for MANY flows:
--
--   • Student  → Class Teacher / Subject Teacher      (v1 scope)
--   • Parent   → Class Teacher / Subject Teacher      (v1 scope)
--   • Teacher  → Student                              (NEP 2020 requirement — each teacher rates each student)
--   • Student  → Peer Student (same class-section)    (NEP 2020 requirement — peer feedback)
--   • Student  → Transport Driver / Helper
--   • Student  → Canteen / Mess Staff
--   • Student  → Library Staff
--   • Student  → Hostel Warden / Staff
--   • Student  → Security / Nursing / Lab Assistant / Coach
--   • Parent   → Transport / Canteen / Library / Hostel
--   • Admin    → Teacher (performance review)
--   • Teacher  → Peer Teacher (360° review)
--   • (any future actor) → (any future target)
--
-- Rather than design one-off tables for each pair, v2 introduces a single schema where:
--   1. Target kinds are configurable via a master table (fbk_target_types)
--   2. Respondent × Target × Context combinations are configurable (fbk_relationship_types)
--   3. A feedback cycle can collect multiple feedback types in one window
--   4. A single responses/answers pair stores everything with polymorphic target references
--
-- ════════════════════════════════════════════════════════════════════════════════════════════════════════
--  MODULE TABLES (11)
-- ════════════════════════════════════════════════════════════════════════════════════════════════════════
--   1. fbk_target_types            — Master: what can be rated (Teacher, Student, Driver, Staff, ...)
--   2. fbk_relationship_types      — Master: valid (respondent_kind, target_type, context) tuples
--   3. fbk_categories              — Feedback themes (Teaching, Safety, Hygiene, Punctuality, ...)
--   4. fbk_templates               — Reusable question-set master
--   5. fbk_questions               — Questions inside a template
--   6. fbk_cycles                  — Feedback collection window
--   7. fbk_cycle_feedback_types    — Junction: cycle × (relationship_type + template)
--   8. fbk_cycle_targets           — Explicit list of eligible targets in a cycle
--   9. fbk_responses               — Submission header (polymorphic target)
--  10. fbk_answers                 — Individual question answers
--  11. fbk_summary                 — Materialized aggregate for fast dashboards
--
-- ════════════════════════════════════════════════════════════════════════════════════════════════════════
--  EXTERNAL DEPENDENCIES
-- ════════════════════════════════════════════════════════════════════════════════════════════════════════
--   sys_users                         — every actor (student, parent, teacher, staff) has a user record
--   sch_employees                     — teacher + non-teaching staff (is_teacher flag distinguishes)
--   sch_class_section_jnt             — class teacher / assistance_class_teacher references
--   sch_subjects                      — subject context
--   sch_departments                   — department-level targets (Canteen, Library, Transport, ...)
--   sch_org_academic_sessions_jnt     — academic session
--   std_students                      — student record
--   std_guardians                     — parent/guardian record
--   std_student_guardian_jnt          — parent → student link + portal access flag
--   std_student_academic_sessions     — student's current class-section context
--   tt_activity / tt_activity_teacher — subject-teacher assignments
-- ========================================================================================================


-- ========================================================================================================
--  SECTION 1 : REFERENCE MASTERS
-- ========================================================================================================

-- ---------------------------------------------------------------------------
-- 1. fbk_target_types
-- ---------------------------------------------------------------------------
-- What kinds of entities can be rated.
-- `linked_entity_table` is metadata hint for the application layer — it tells the app
-- which base table a target of this kind lives in (std_students, sch_employees, sch_departments, etc.).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fbk_target_types` (
  `id`                    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`                  VARCHAR(40)  NOT NULL COMMENT 'TEACHER, CLASS_TEACHER, SUBJECT_TEACHER, STUDENT, TRANSPORT_DRIVER, ...',
  `name`                  VARCHAR(100) NOT NULL,
  `description`           VARCHAR(255) DEFAULT NULL,
  `icon`                  VARCHAR(50)  DEFAULT NULL COMMENT 'FA icon class for UI',
  `display_order`         SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  -- Which base entity does this target kind point to?
  `linked_entity_table`   ENUM('sys_users','std_students','sch_employees','sch_departments','sch_classes','sch_sections','sch_class_section_jnt','other') NOT NULL DEFAULT 'sys_users'
                          COMMENT 'Tells the application which table a target_id of this kind should reference',
  `is_individual`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = points to a specific person/record; 0 = aggregate (e.g., DEPARTMENT)',
  -- Audit
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fbk_tt_code` (`code`, `deleted_at`),
  INDEX `idx_fbk_tt_active` (`is_active`, `display_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Master list of target kinds that can be rated by the Feedback module';
-- Seed examples (insert during module setup):
--   (CLASS_TEACHER, sys_users, 1), (SUBJECT_TEACHER, sys_users, 1), (TEACHER, sys_users, 1),
--   (STUDENT, std_students, 1), (PEER_STUDENT, std_students, 1),
--   (TRANSPORT_DRIVER, sch_employees, 1), (TRANSPORT_HELPER, sch_employees, 1),
--   (CANTEEN_STAFF, sch_employees, 1), (CANTEEN_MANAGER, sch_employees, 1),
--   (LIBRARY_STAFF, sch_employees, 1), (LIBRARY_HEAD, sch_employees, 1),
--   (HOSTEL_WARDEN, sch_employees, 1), (HOSTEL_STAFF, sch_employees, 1),
--   (SECURITY_STAFF, sch_employees, 1), (NURSING_STAFF, sch_employees, 1),
--   (LAB_ASSISTANT, sch_employees, 1), (SPORTS_COACH, sch_employees, 1),
--   (ADMIN_STAFF, sch_employees, 1), (NON_TEACHING_STAFF, sch_employees, 1),
--   (DEPARTMENT, sch_departments, 0), (CLASS, sch_class_section_jnt, 0), (OTHER, sys_users, 1)


-- ---------------------------------------------------------------------------
-- 2. fbk_relationship_types
-- ---------------------------------------------------------------------------
-- Defines the VALID combinations of (respondent_kind, target_type, context).
-- Acts as an authorisation whitelist — the app uses this to determine which feedback
-- flows are available for a given user and cycle.
--
-- `context_required` tells the app what contextual filter is needed to find valid
-- (respondent, target) pairs at runtime:
--   None            → any respondent of that kind can rate any target of that type
--   Class_Section   → respondent and target must share a class-section
--   Subject         → respondent must be enrolled in the subject the target teaches
--   Transport_Route → respondent must use the transport route the target serves
--   Hostel          → respondent must live in the hostel the target manages
--   Custom          → custom resolver logic in the application layer
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fbk_relationship_types` (
  `id`                    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`                  VARCHAR(60)  NOT NULL COMMENT 'STUDENT_TO_CLASS_TEACHER, TEACHER_TO_STUDENT, STUDENT_TO_PEER_STUDENT, ...',
  `name`                  VARCHAR(150) NOT NULL,
  `description`           VARCHAR(500) DEFAULT NULL,
  -- Actors
  `respondent_kind`       ENUM('Student','Parent','Teacher','Staff','Admin','Self','Any') NOT NULL COMMENT 'Who provides the feedback',
  `target_type_id`        SMALLINT UNSIGNED NOT NULL COMMENT 'FK → fbk_target_types.id',
  -- Context rule
  `context_required`      ENUM('None','Class_Section','Subject','Subject_And_Class_Section','Transport_Route','Hostel','Department','Custom') NOT NULL DEFAULT 'None',
  `is_peer_relationship`  TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 if respondent and target are the same kind (e.g., student-to-student)',
  `is_self_relationship`  TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 if respondent rates themselves (self-reflection)',
  `nep_2020_mandated`     TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = this feedback flow is mandated by NEP 2020 policy',
  -- Defaults (can be overridden per cycle_feedback_type)
  `default_anonymous_to_target` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Recommended anonymity default for this relationship (peer and self feedback should always be anonymous)',
  -- Audit
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fbk_rt_code` (`code`, `deleted_at`),
  INDEX `idx_fbk_rt_respondent_target` (`respondent_kind`, `target_type_id`),
  INDEX `idx_fbk_rt_active`            (`is_active`),
  CONSTRAINT `fk_fbk_rt_target_type` FOREIGN KEY (`target_type_id`) REFERENCES `fbk_target_types` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Valid (respondent_kind × target_type × context) combinations — acts as an authorisation whitelist';
-- Seed examples:
--   STUDENT_TO_CLASS_TEACHER           Student → CLASS_TEACHER     Class_Section              anon=1 NEP=0
--   STUDENT_TO_ASSISTANCE_CLASS_TEACHER Student → CLASS_TEACHER    Class_Section              anon=1 NEP=0
--   STUDENT_TO_SUBJECT_TEACHER         Student → SUBJECT_TEACHER   Subject_And_Class_Section  anon=1 NEP=0
--   STUDENT_TO_PEER_STUDENT            Student → PEER_STUDENT      Class_Section              anon=1 NEP=1 (NEP 2020 peer feedback)
--   PARENT_TO_CLASS_TEACHER            Parent  → CLASS_TEACHER     Class_Section              anon=1 NEP=0
--   PARENT_TO_SUBJECT_TEACHER          Parent  → SUBJECT_TEACHER   Subject_And_Class_Section  anon=1 NEP=0
--   TEACHER_TO_STUDENT                 Teacher → STUDENT           Subject_And_Class_Section  anon=0 NEP=1 (NEP 2020 teacher evaluation of student)
--   TEACHER_TO_PEER_TEACHER            Teacher → TEACHER           None                       anon=1 NEP=0 (360° review)
--   ADMIN_TO_TEACHER                   Admin   → TEACHER           None                       anon=0 NEP=0 (performance review)
--   ADMIN_TO_STUDENT                   Admin   → STUDENT           None                       anon=0 NEP=0
--   STUDENT_TO_TRANSPORT_DRIVER        Student → TRANSPORT_DRIVER  Transport_Route            anon=1 NEP=0
--   PARENT_TO_TRANSPORT_DRIVER         Parent  → TRANSPORT_DRIVER  Transport_Route            anon=1 NEP=0
--   STUDENT_TO_TRANSPORT_HELPER        Student → TRANSPORT_HELPER  Transport_Route            anon=1 NEP=0
--   STUDENT_TO_CANTEEN_STAFF           Student → CANTEEN_STAFF     None                       anon=1 NEP=0
--   STUDENT_TO_CANTEEN_DEPT            Student → DEPARTMENT        Department                 anon=1 NEP=0
--   STUDENT_TO_LIBRARY_STAFF           Student → LIBRARY_STAFF     None                       anon=1 NEP=0
--   STUDENT_TO_HOSTEL_WARDEN           Student → HOSTEL_WARDEN     Hostel                     anon=1 NEP=0
--   STUDENT_TO_SECURITY_STAFF          Student → SECURITY_STAFF    None                       anon=1 NEP=0
--   STUDENT_TO_NURSING_STAFF           Student → NURSING_STAFF     None                       anon=1 NEP=0
--   STUDENT_TO_SPORTS_COACH            Student → SPORTS_COACH      Custom                     anon=1 NEP=0
--   SELF_REFLECTION_STUDENT            Student → STUDENT           None (is_self=1)           anon=0 NEP=0 (self-assessment)
--   SELF_REFLECTION_TEACHER            Teacher → TEACHER           None (is_self=1)           anon=0 NEP=0


-- ---------------------------------------------------------------------------
-- 3. fbk_categories
-- ---------------------------------------------------------------------------
-- Themes that group questions inside a template.
-- Categories can be applicable to specific target types (e.g., "Hygiene" for Canteen,
-- "Teaching Quality" for Teacher, "Cleanliness" for Transport_Driver).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fbk_categories` (
  `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`                      VARCHAR(40)  NOT NULL,
  `name`                      VARCHAR(100) NOT NULL,
  `description`               VARCHAR(255) DEFAULT NULL,
  `icon`                      VARCHAR(50)  DEFAULT NULL,
  `display_order`             SMALLINT UNSIGNED NOT NULL DEFAULT 1, 
  -- Scope filter (NULL = applicable to any target type)
  `applicable_target_type_id` SMALLINT UNSIGNED DEFAULT NULL COMMENT 'FK → fbk_target_types.id; NULL = applies to all',
  `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`                INT UNSIGNED DEFAULT NULL,
  `created_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fbk_cat_code` (`code`, `deleted_at`),
  INDEX `idx_fbk_cat_target_type` (`applicable_target_type_id`),
  INDEX `idx_fbk_cat_active` (`is_active`, `display_order`),
  CONSTRAINT `fk_fbk_cat_target_type` FOREIGN KEY (`applicable_target_type_id`) REFERENCES `fbk_target_types` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Feedback category master — groups questions under a theme';
-- Seed examples:
--   TEACHING_QUALITY, COMMUNICATION, FAIRNESS, PUNCTUALITY, SUBJECT_KNOWLEDGE, CLASSROOM_MANAGEMENT,
--   APPROACHABILITY, HOMEWORK_QUALITY, ASSESSMENT_FEEDBACK,
--   HYGIENE, FOOD_QUALITY, FOOD_VARIETY, SERVICE_SPEED, COURTESY,
--   CLEANLINESS, SAFETY, DRIVING_SKILL, PUNCTUALITY_TRANSPORT,
--   BOOK_AVAILABILITY, LIBRARY_AMBIENCE, STAFF_HELPFULNESS,
--   PEER_COOPERATION, PEER_RESPECT, PEER_PARTICIPATION,
--   STUDENT_DISCIPLINE, STUDENT_ATTENDANCE, STUDENT_HOMEWORK_COMPLETION


-- ========================================================================================================
--  SECTION 2 : TEMPLATES & QUESTIONS
-- ========================================================================================================

-- ---------------------------------------------------------------------------
-- 4. fbk_templates
-- ---------------------------------------------------------------------------
-- Reusable question-set. A single template is associated with a single target_type.
-- `applicable_relationship_codes_json` lists which relationship_type codes this template
-- supports (a template can be reused across multiple relationships that share the same
-- target type — e.g., "Teacher Evaluation Template" works for STUDENT_TO_CLASS_TEACHER,
-- STUDENT_TO_SUBJECT_TEACHER, PARENT_TO_CLASS_TEACHER, etc.).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fbk_templates` (
  `id`                                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`                                VARCHAR(60)  NOT NULL,
  `name`                                VARCHAR(200) NOT NULL,
  `description`                         VARCHAR(500) DEFAULT NULL,
  -- Scope
  `target_type_id`                      SMALLINT UNSIGNED NOT NULL COMMENT 'FK → fbk_target_types.id',
  `respondent_kind`                     ENUM('Student','Parent','Teacher','Staff','Admin','Self','Any') NOT NULL DEFAULT 'Any' COMMENT 'Restricts which respondent kinds can use this template',
  `applicable_relationship_codes_json`  JSON DEFAULT NULL COMMENT 'Optional: array of fbk_relationship_types.code values; if null = any relationship with matching target_type',
  -- Scoring
  `overall_rating_method`               ENUM('Weighted_Average','Simple_Average','Manual_Only','None') NOT NULL DEFAULT 'Weighted_Average',
  `rating_scale_max`                    TINYINT UNSIGNED NOT NULL DEFAULT 5 COMMENT 'Max value for Rating_* question types',
  -- Version & lifecycle
  `version`                             VARCHAR(10) NOT NULL DEFAULT '1.0',
  `is_active`                           TINYINT(1) NOT NULL DEFAULT 1,
  `is_locked`                           TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = template is used by a running cycle; questions cannot be edited',
  -- Audit
  `created_by`                          INT UNSIGNED DEFAULT NULL,
  `created_at`                          TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                          TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`                          TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fbk_tpl_code` (`code`, `deleted_at`),
  INDEX `idx_fbk_tpl_target_type` (`target_type_id`),
  INDEX `idx_fbk_tpl_respondent`  (`respondent_kind`),
  INDEX `idx_fbk_tpl_active`      (`is_active`),
  CONSTRAINT `fk_fbk_tpl_target_type` FOREIGN KEY (`target_type_id`) REFERENCES `fbk_target_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_fbk_tpl_created_by`  FOREIGN KEY (`created_by`)     REFERENCES `sys_users` (`id`)       ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Reusable question-set master — one row per version of a feedback template';


-- ---------------------------------------------------------------------------
-- 5. fbk_questions
-- ---------------------------------------------------------------------------
-- Individual questions within a template, grouped by category, with configurable type.
--
-- question_type semantics:
--   Rating_5      → numeric 1-5 (stored in answers.rating_value)
--   Rating_10     → numeric 1-10
--   Likert_5      → Strongly Disagree/Disagree/Neutral/Agree/Strongly Agree (stored as 1-5)
--   Emoji_5       → 5-point emoji scale (😡😕😐🙂😊) stored 1-5 + emoji_value code
--   Yes_No        → boolean
--   Multi_Choice  → one of options_json codes
--   Free_Text     → open text
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fbk_questions` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `template_id`           INT UNSIGNED NOT NULL,
  `category_id`           INT UNSIGNED DEFAULT NULL,
  `code`                  VARCHAR(60)  NOT NULL,
  `question_text`         TEXT         NOT NULL,
  `help_text`             VARCHAR(500) DEFAULT NULL,
  `display_order`         SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  -- Type & config
  `question_type`         ENUM('Rating_5','Rating_10','Likert_5','Emoji_5','Yes_No','Multi_Choice','Free_Text') NOT NULL DEFAULT 'Rating_5',
  `is_required`           TINYINT(1) NOT NULL DEFAULT 1,
  `is_reverse_scored`     TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = higher rating is worse (used for "How often does X happen?" questions about negative behaviour)',
  `weight`                DECIMAL(4,2) NOT NULL DEFAULT 1.00,
  `options_json`          JSON DEFAULT NULL
                          COMMENT 'For Multi_Choice: [{"code":"A","label":"Always","value":5}, {"code":"S","label":"Sometimes","value":3}, {"code":"N","label":"Never","value":1}]',
  -- Respondent filter (NULL = Any)
  `respondent_kind`       ENUM('Student','Parent','Teacher','Staff','Admin','Self','Any') NOT NULL DEFAULT 'Any',
  -- Audit
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fbk_q_template_code` (`template_id`, `code`, `deleted_at`),
  INDEX `idx_fbk_q_template`   (`template_id`, `display_order`),
  INDEX `idx_fbk_q_category`   (`category_id`),
  INDEX `idx_fbk_q_active`     (`is_active`),
  CONSTRAINT `fk_fbk_q_template` FOREIGN KEY (`template_id`) REFERENCES `fbk_templates` (`id`)   ON DELETE CASCADE,
  CONSTRAINT `fk_fbk_q_category` FOREIGN KEY (`category_id`) REFERENCES `fbk_categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Questions inside a template — grouped by category, typed and weighted';


-- ========================================================================================================
--  SECTION 3 : CYCLES
-- ========================================================================================================

-- ---------------------------------------------------------------------------
-- 6. fbk_cycles
-- ---------------------------------------------------------------------------
-- A feedback collection window. One cycle can contain multiple feedback types
-- (see fbk_cycle_feedback_types). Admin/Principal creates cycles; respondents submit
-- during [start_date..end_date]; admin publishes summaries after cycle closes.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fbk_cycles` (
  `id`                                   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`                                 VARCHAR(50) NOT NULL,
  `name`                                 VARCHAR(200) NOT NULL,
  `description`                          VARCHAR(500) DEFAULT NULL,
  -- Academic context
  `academic_session_id`                  INT UNSIGNED NOT NULL COMMENT 'FK → sch_org_academic_sessions_jnt.id',
  `term_label`                           VARCHAR(50) DEFAULT NULL COMMENT 'Q1, Q2, Mid-Term, Annual, Adhoc, etc.',
  -- Window
  `start_date`                           DATE NOT NULL,
  `end_date`                             DATE NOT NULL,
  -- Lifecycle
  `status`                               ENUM('Draft','Active','Closed','Published','Cancelled') NOT NULL DEFAULT 'Draft',
  `is_published_to_targets`              TINYINT(1) NOT NULL DEFAULT 0,
  `published_at`                         TIMESTAMP NULL DEFAULT NULL,
  `published_by`                         INT UNSIGNED DEFAULT NULL,
  -- Defaults applied to all cycle feedback types (each can override)
  `default_is_anonymous_to_target`       TINYINT(1) NOT NULL DEFAULT 1,
  `default_min_responses_for_visibility` TINYINT UNSIGNED NOT NULL DEFAULT 3
                                         COMMENT 'Minimum response count before teacher/target can view aggregate (protects anonymity for small groups)',
  -- Instructions
  `instructions`                         TEXT DEFAULT NULL,
  -- Audit
  `is_active`                            TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`                           INT UNSIGNED DEFAULT NULL,
  `created_at`                           TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                           TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`                           TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fbk_c_code` (`code`, `deleted_at`),
  INDEX `idx_fbk_c_session` (`academic_session_id`),
  INDEX `idx_fbk_c_status`  (`status`),
  INDEX `idx_fbk_c_window`  (`start_date`, `end_date`),
  INDEX `idx_fbk_c_active`  (`is_active`),
  CONSTRAINT `fk_fbk_c_session`      FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_fbk_c_created_by`   FOREIGN KEY (`created_by`)          REFERENCES `sys_users` (`id`)                    ON DELETE SET NULL,
  CONSTRAINT `fk_fbk_c_published_by` FOREIGN KEY (`published_by`)        REFERENCES `sys_users` (`id`)                    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Feedback collection cycle — defines a window during which one or more feedback types can be submitted';


-- ---------------------------------------------------------------------------
-- 7. fbk_cycle_feedback_types
-- ---------------------------------------------------------------------------
-- Junction: cycle × (relationship_type + template).
-- A single cycle can collect multiple feedback types simultaneously.
--
-- Example — one "Q1 2025-26 Annual Feedback Drive" cycle:
--   • STUDENT_TO_CLASS_TEACHER         using "CT_STUDENT_V1" template
--   • STUDENT_TO_SUBJECT_TEACHER       using "ST_STUDENT_V1" template
--   • STUDENT_TO_PEER_STUDENT          using "PEER_V1" template (NEP 2020)
--   • TEACHER_TO_STUDENT               using "T2S_V1" template (NEP 2020)
--   • PARENT_TO_CLASS_TEACHER          using "CT_PARENT_V1" template
--   • STUDENT_TO_TRANSPORT_DRIVER      using "TRANSPORT_V1" template
--   • STUDENT_TO_CANTEEN_STAFF         using "CANTEEN_V1" template
--   • STUDENT_TO_LIBRARY_STAFF         using "LIBRARY_V1" template
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fbk_cycle_feedback_types` (
  `id`                              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cycle_id`                        INT UNSIGNED NOT NULL,
  `relationship_type_id`            SMALLINT UNSIGNED NOT NULL,
  `template_id`                     INT UNSIGNED NOT NULL,
  -- Overrides for cycle defaults
  `is_anonymous_to_target`          TINYINT(1) NOT NULL DEFAULT 1,
  `min_responses_for_visibility`    TINYINT UNSIGNED NOT NULL DEFAULT 3,
  `allow_draft_save`                TINYINT(1) NOT NULL DEFAULT 1,
  `allow_withdrawal`                TINYINT(1) NOT NULL DEFAULT 1,
  -- Scope filter (optional — restricts which targets are in this feedback type)
  `scope_type`                      ENUM('All','Specific_Classes','Specific_Departments','Specific_Targets','Custom') NOT NULL DEFAULT 'All',
  `scope_filter_json`               JSON DEFAULT NULL
                                    COMMENT 'Flexible filter: {"class_section_ids":[1,2], "department_ids":[3], "target_user_ids":[10,20]}',
  -- Target population strategy
  `target_population_mode`          ENUM('Auto','Manual') NOT NULL DEFAULT 'Auto'
                                    COMMENT 'Auto = app populates fbk_cycle_targets from relationships; Manual = admin enters targets explicitly',
  -- Audit
  `is_active`                       TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`                      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`                      TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fbk_cft` (`cycle_id`, `relationship_type_id`, `deleted_at`),
  INDEX `idx_fbk_cft_cycle`              (`cycle_id`),
  INDEX `idx_fbk_cft_relationship_type`  (`relationship_type_id`),
  INDEX `idx_fbk_cft_template`           (`template_id`),
  CONSTRAINT `fk_fbk_cft_cycle`             FOREIGN KEY (`cycle_id`)             REFERENCES `fbk_cycles` (`id`)              ON DELETE CASCADE,
  CONSTRAINT `fk_fbk_cft_relationship_type` FOREIGN KEY (`relationship_type_id`) REFERENCES `fbk_relationship_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_fbk_cft_template`          FOREIGN KEY (`template_id`)          REFERENCES `fbk_templates` (`id`)           ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Feedback types included in a cycle — each row represents (relationship × template) combination';


-- ---------------------------------------------------------------------------
-- 8. fbk_cycle_targets
-- ---------------------------------------------------------------------------
-- Explicit list of eligible targets for a cycle feedback type.
-- Populated either automatically (by a scheduler that walks relationships)
-- or manually (admin picks specific targets). Used for:
--   • Telling respondents which targets to rate
--   • Participation tracking (expected vs received)
--   • Summary computation scope
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fbk_cycle_targets` (
  `id`                            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cycle_id`                      INT UNSIGNED NOT NULL,
  `cycle_feedback_type_id`        INT UNSIGNED NOT NULL,
  `target_type_id`                SMALLINT UNSIGNED NOT NULL COMMENT 'Denormalised from fbk_cycle_feedback_types → fbk_relationship_types.target_type_id',
  -- Target identity (exactly ONE of these populated based on target_type.linked_entity_table)
  `target_user_id`                INT UNSIGNED DEFAULT NULL COMMENT 'FK → sys_users.id',
  `target_student_id`             INT UNSIGNED DEFAULT NULL COMMENT 'FK → std_students.id',
  `target_employee_id`            INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_employees.id',
  `target_department_id`          INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_departments.id',
  -- Context (if the target has a specific context in this cycle)
  `class_section_id`              INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_class_section_jnt.id',
  `subject_id`                    INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_subjects.id',
  `tt_activity_id`                INT UNSIGNED DEFAULT NULL COMMENT 'FK → tt_activity.id (for subject-teacher context)',
  `context_json`                  JSON DEFAULT NULL COMMENT 'Flexible context e.g., {"transport_route_id":42, "hostel_id":5}',
  -- Participation tracking (maintained by app on every response submit)
  `expected_response_count`       INT UNSIGNED NOT NULL DEFAULT 0,
  `received_response_count`       INT UNSIGNED NOT NULL DEFAULT 0,
  `submitted_response_count`      INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Only count status=Submitted',
  -- Audit
  `is_active`                     TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`                    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_fbk_ct_cycle`          (`cycle_id`),
  INDEX `idx_fbk_ct_cft`            (`cycle_feedback_type_id`),
  INDEX `idx_fbk_ct_target_user`    (`target_user_id`),
  INDEX `idx_fbk_ct_target_student` (`target_student_id`),
  INDEX `idx_fbk_ct_target_emp`     (`target_employee_id`),
  INDEX `idx_fbk_ct_target_dept`    (`target_department_id`),
  INDEX `idx_fbk_ct_class_section`  (`class_section_id`),
  CONSTRAINT `fk_fbk_ct_cycle`          FOREIGN KEY (`cycle_id`)               REFERENCES `fbk_cycles` (`id`)                ON DELETE CASCADE,
  CONSTRAINT `fk_fbk_ct_cft`            FOREIGN KEY (`cycle_feedback_type_id`) REFERENCES `fbk_cycle_feedback_types` (`id`)  ON DELETE CASCADE,
  CONSTRAINT `fk_fbk_ct_target_type`    FOREIGN KEY (`target_type_id`)         REFERENCES `fbk_target_types` (`id`)          ON DELETE RESTRICT,
  CONSTRAINT `fk_fbk_ct_target_user`    FOREIGN KEY (`target_user_id`)         REFERENCES `sys_users` (`id`)                 ON DELETE CASCADE,
  CONSTRAINT `fk_fbk_ct_target_student` FOREIGN KEY (`target_student_id`)      REFERENCES `std_students` (`id`)              ON DELETE CASCADE,
  CONSTRAINT `fk_fbk_ct_target_emp`     FOREIGN KEY (`target_employee_id`)     REFERENCES `sch_employees` (`id`)             ON DELETE CASCADE,
  CONSTRAINT `fk_fbk_ct_target_dept`    FOREIGN KEY (`target_department_id`)   REFERENCES `sch_departments` (`id`)           ON DELETE CASCADE,
  CONSTRAINT `fk_fbk_ct_class_section`  FOREIGN KEY (`class_section_id`)       REFERENCES `sch_class_section_jnt` (`id`)     ON DELETE SET NULL,
  CONSTRAINT `fk_fbk_ct_subject`        FOREIGN KEY (`subject_id`)             REFERENCES `sch_subjects` (`id`)              ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Explicit target list for each cycle feedback type — enables participation tracking and scoped queries';


-- ========================================================================================================
--  SECTION 4 : RESPONSES & ANSWERS
-- ========================================================================================================

-- ---------------------------------------------------------------------------
-- 9. fbk_responses
-- ---------------------------------------------------------------------------
-- Core submission. ONE row per (respondent × target × cycle_feedback_type).
--
-- POLYMORPHIC POINTERS:
--   Respondent: exactly ONE of respondent_student_id, respondent_guardian_id, respondent_employee_id is populated
--               based on respondent_kind. respondent_user_id is ALWAYS populated (canonical login identity).
--   Target:     exactly ONE of target_user_id, target_student_id, target_employee_id, target_department_id
--               is populated based on the target_type.linked_entity_table.
--
-- DEDUP STRATEGY:
--   Generated COALESCE columns let the UNIQUE index deduplicate across all nullable FKs simultaneously.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fbk_responses` (
  `id`                            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  -- Cycle & context snapshot
  `cycle_id`                      INT UNSIGNED NOT NULL,
  `cycle_feedback_type_id`        INT UNSIGNED NOT NULL,
  `template_id`                   INT UNSIGNED NOT NULL COMMENT 'Snapshot — survives template edits',
  `relationship_type_id`          SMALLINT UNSIGNED NOT NULL COMMENT 'Snapshot',
  `cycle_target_id`               INT UNSIGNED DEFAULT NULL COMMENT 'Optional FK → fbk_cycle_targets.id (for participation tracking)',

  -- ═══════════════════════════════════════════════════════════════════════
  -- RESPONDENT (who is submitting)
  -- ═══════════════════════════════════════════════════════════════════════
  `respondent_kind`               ENUM('Student','Parent','Teacher','Staff','Admin','Self') NOT NULL,
  `respondent_user_id`            INT UNSIGNED NOT NULL COMMENT 'Always populated: sys_users.id of the logged-in actor',
  `respondent_student_id`         INT UNSIGNED DEFAULT NULL COMMENT 'Populated when respondent_kind = Student, OR when Parent is rating about their specific child',
  `respondent_guardian_id`        INT UNSIGNED DEFAULT NULL COMMENT 'Populated when respondent_kind = Parent',
  `respondent_employee_id`        INT UNSIGNED DEFAULT NULL COMMENT 'Populated when respondent_kind = Teacher/Staff/Admin',
  `student_academic_session_id`   INT UNSIGNED DEFAULT NULL COMMENT 'Student context (year + class-section) — locked at submission',

  -- ═══════════════════════════════════════════════════════════════════════
  -- TARGET (who/what is being rated)
  -- ═══════════════════════════════════════════════════════════════════════
  `target_type_id`                SMALLINT UNSIGNED NOT NULL,
  `target_user_id`                INT UNSIGNED DEFAULT NULL COMMENT 'Teacher / staff / admin target → sys_users.id',
  `target_student_id`             INT UNSIGNED DEFAULT NULL COMMENT 'Student target → std_students.id',
  `target_employee_id`            INT UNSIGNED DEFAULT NULL COMMENT 'Employee target (driver, canteen, library...) → sch_employees.id',
  `target_department_id`          INT UNSIGNED DEFAULT NULL COMMENT 'Aggregate department target → sch_departments.id',

  -- ═══════════════════════════════════════════════════════════════════════
  -- CONTEXT (what locks the respondent↔target relationship)
  -- ═══════════════════════════════════════════════════════════════════════
  `class_section_id`              INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_class_section_jnt.id — when context is class-bound',
  `subject_id`                    INT UNSIGNED DEFAULT NULL COMMENT 'FK → sch_subjects.id — when subject-specific',
  `tt_activity_id`                INT UNSIGNED DEFAULT NULL COMMENT 'FK → tt_activity.id — for precise subject-teacher match',
  `context_json`                  JSON DEFAULT NULL COMMENT 'Flexible context (transport_route_id, hostel_id, etc.)',

  -- ═══════════════════════════════════════════════════════════════════════
  -- DEDUP GENERATED COLUMNS (required for UNIQUE index with nullable FKs)
  -- ═══════════════════════════════════════════════════════════════════════
  `target_user_id_uq`             INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`target_user_id`,       0)) STORED,
  `target_student_id_uq`          INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`target_student_id`,    0)) STORED,
  `target_employee_id_uq`         INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`target_employee_id`,   0)) STORED,
  `target_department_id_uq`       INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`target_department_id`, 0)) STORED,
  `subject_id_uq`                 INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`subject_id`,           0)) STORED,
  `class_section_id_uq`           INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`class_section_id`,     0)) STORED,
  `respondent_student_id_uq`      INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`respondent_student_id`,0)) STORED,

  -- ═══════════════════════════════════════════════════════════════════════
  -- RATINGS & COMMENTS
  -- ═══════════════════════════════════════════════════════════════════════
  `overall_rating`                DECIMAL(4,2) DEFAULT NULL COMMENT 'Computed from answers per template.overall_rating_method',
  `overall_comment`               TEXT DEFAULT NULL,
  `is_anonymous_to_target`        TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Snapshot from cycle_feedback_type at submission time',

  -- ═══════════════════════════════════════════════════════════════════════
  -- STATUS FSM
  -- ═══════════════════════════════════════════════════════════════════════
  `status`                        ENUM('Draft','Submitted','Withdrawn') NOT NULL DEFAULT 'Draft',
  `submitted_at`                  TIMESTAMP NULL DEFAULT NULL,
  `withdrawn_at`                  TIMESTAMP NULL DEFAULT NULL,
  `withdrawn_reason`              VARCHAR(255) DEFAULT NULL,

  -- ═══════════════════════════════════════════════════════════════════════
  -- AUDIT
  -- ═══════════════════════════════════════════════════════════════════════
  `submission_ip`                 VARCHAR(45) DEFAULT NULL,
  `submission_user_agent`         VARCHAR(255) DEFAULT NULL,
  `created_at`                    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`                    TIMESTAMP NULL DEFAULT NULL,

  PRIMARY KEY (`id`),

  -- Dedup: one response per (respondent × target × context) within a cycle feedback type
  UNIQUE KEY `uq_fbk_r_dedup` (
    `cycle_feedback_type_id`,
    `respondent_user_id`,
    `respondent_student_id_uq`,
    `target_user_id_uq`,
    `target_student_id_uq`,
    `target_employee_id_uq`,
    `target_department_id_uq`,
    `subject_id_uq`,
    `class_section_id_uq`,
    `deleted_at`
  ),

  -- Query indexes
  INDEX `idx_fbk_r_cycle`         (`cycle_id`, `status`),
  INDEX `idx_fbk_r_cft`           (`cycle_feedback_type_id`, `status`),
  INDEX `idx_fbk_r_respondent`    (`respondent_user_id`, `cycle_id`),
  INDEX `idx_fbk_r_target_user`   (`target_user_id`,      `cycle_id`),
  INDEX `idx_fbk_r_target_student` (`target_student_id`,  `cycle_id`),
  INDEX `idx_fbk_r_target_emp`    (`target_employee_id`,  `cycle_id`),
  INDEX `idx_fbk_r_target_dept`   (`target_department_id`,`cycle_id`),
  INDEX `idx_fbk_r_class_section` (`class_section_id`),
  INDEX `idx_fbk_r_subject`       (`subject_id`),
  INDEX `idx_fbk_r_status`        (`status`),
  INDEX `idx_fbk_r_submitted_at`  (`submitted_at`),

  -- Foreign keys
  CONSTRAINT `fk_fbk_r_cycle`            FOREIGN KEY (`cycle_id`)                    REFERENCES `fbk_cycles` (`id`)                    ON DELETE RESTRICT,
  CONSTRAINT `fk_fbk_r_cft`              FOREIGN KEY (`cycle_feedback_type_id`)      REFERENCES `fbk_cycle_feedback_types` (`id`)      ON DELETE RESTRICT,
  CONSTRAINT `fk_fbk_r_template`         FOREIGN KEY (`template_id`)                 REFERENCES `fbk_templates` (`id`)                 ON DELETE RESTRICT,
  CONSTRAINT `fk_fbk_r_relationship`     FOREIGN KEY (`relationship_type_id`)        REFERENCES `fbk_relationship_types` (`id`)        ON DELETE RESTRICT,
  CONSTRAINT `fk_fbk_r_cycle_target`     FOREIGN KEY (`cycle_target_id`)             REFERENCES `fbk_cycle_targets` (`id`)             ON DELETE SET NULL,
  CONSTRAINT `fk_fbk_r_resp_user`        FOREIGN KEY (`respondent_user_id`)          REFERENCES `sys_users` (`id`)                     ON DELETE RESTRICT,
  CONSTRAINT `fk_fbk_r_resp_student`     FOREIGN KEY (`respondent_student_id`)       REFERENCES `std_students` (`id`)                  ON DELETE CASCADE,
  CONSTRAINT `fk_fbk_r_resp_guardian`    FOREIGN KEY (`respondent_guardian_id`)      REFERENCES `std_guardians` (`id`)                 ON DELETE SET NULL,
  CONSTRAINT `fk_fbk_r_resp_employee`    FOREIGN KEY (`respondent_employee_id`)      REFERENCES `sch_employees` (`id`)                 ON DELETE SET NULL,
  CONSTRAINT `fk_fbk_r_std_acad_session` FOREIGN KEY (`student_academic_session_id`) REFERENCES `std_student_academic_sessions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_fbk_r_target_type`      FOREIGN KEY (`target_type_id`)              REFERENCES `fbk_target_types` (`id`)              ON DELETE RESTRICT,
  CONSTRAINT `fk_fbk_r_target_user`      FOREIGN KEY (`target_user_id`)              REFERENCES `sys_users` (`id`)                     ON DELETE CASCADE,
  CONSTRAINT `fk_fbk_r_target_student`   FOREIGN KEY (`target_student_id`)           REFERENCES `std_students` (`id`)                  ON DELETE CASCADE,
  CONSTRAINT `fk_fbk_r_target_employee`  FOREIGN KEY (`target_employee_id`)          REFERENCES `sch_employees` (`id`)                 ON DELETE CASCADE,
  CONSTRAINT `fk_fbk_r_target_department` FOREIGN KEY (`target_department_id`)       REFERENCES `sch_departments` (`id`)               ON DELETE CASCADE,
  CONSTRAINT `fk_fbk_r_class_section`    FOREIGN KEY (`class_section_id`)            REFERENCES `sch_class_section_jnt` (`id`)         ON DELETE SET NULL,
  CONSTRAINT `fk_fbk_r_subject`          FOREIGN KEY (`subject_id`)                  REFERENCES `sch_subjects` (`id`)                  ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Core feedback submission — polymorphic respondent × polymorphic target within a cycle feedback type';
-- Integrity rules (enforced in application layer):
--   - Exactly ONE respondent_{student,guardian,employee}_id matches respondent_kind
--   - Exactly ONE target_{user,student,employee,department}_id is populated per target_type.linked_entity_table
--   - If relationship_type.context_required requires it, the relevant context fields must be populated


-- ---------------------------------------------------------------------------
-- 10. fbk_answers
-- ---------------------------------------------------------------------------
-- Individual question-level answers. One row per (response × question).
-- Snapshots question_type, category_id, weight at submission time so template
-- edits (after submission) do not corrupt historical analytics.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fbk_answers` (
  `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `response_id`               INT UNSIGNED NOT NULL,
  `question_id`               INT UNSIGNED NOT NULL,
  -- Snapshot of question metadata at submission time
  `question_type_snapshot`    ENUM('Rating_5','Rating_10','Likert_5','Emoji_5','Yes_No','Multi_Choice','Free_Text') NOT NULL,
  `category_id_snapshot`      INT UNSIGNED DEFAULT NULL,
  `weight_snapshot`           DECIMAL(4,2) NOT NULL DEFAULT 1.00,
  -- Answer payload (populated based on question_type_snapshot)
  `rating_value`              DECIMAL(4,2) DEFAULT NULL COMMENT 'Rating_5 / Rating_10 / Likert_5 / Emoji_5',
  `boolean_answer`            TINYINT(1)   DEFAULT NULL COMMENT 'Yes_No: 1 = Yes, 0 = No',
  `selected_option_code`      VARCHAR(50)  DEFAULT NULL COMMENT 'Multi_Choice: code from questions.options_json',
  `selected_option_value`     DECIMAL(4,2) DEFAULT NULL COMMENT 'Numeric value of selected option (for aggregation)',
  `text_answer`               TEXT         DEFAULT NULL COMMENT 'Free_Text (or optional comment on any type)',
  `emoji_value`               VARCHAR(20)  DEFAULT NULL COMMENT 'Emoji_5: angry|sad|neutral|smile|happy',
  -- Audit
  `created_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fbk_a_response_question` (`response_id`, `question_id`),
  INDEX `idx_fbk_a_response`  (`response_id`),
  INDEX `idx_fbk_a_question`  (`question_id`),
  INDEX `idx_fbk_a_category`  (`category_id_snapshot`),
  CONSTRAINT `fk_fbk_a_response` FOREIGN KEY (`response_id`)          REFERENCES `fbk_responses` (`id`)   ON DELETE CASCADE,
  CONSTRAINT `fk_fbk_a_question` FOREIGN KEY (`question_id`)          REFERENCES `fbk_questions` (`id`)   ON DELETE RESTRICT,
  CONSTRAINT `fk_fbk_a_category` FOREIGN KEY (`category_id_snapshot`) REFERENCES `fbk_categories` (`id`)  ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Individual question answers — one row per question per response';


-- ========================================================================================================
--  SECTION 5 : AGGREGATES
-- ========================================================================================================

-- ---------------------------------------------------------------------------
-- 11. fbk_summary
-- ---------------------------------------------------------------------------
-- Materialized aggregate for dashboards. One row per (cycle_feedback_type × target × optional slice).
-- Recomputed by a batch job on cycle close, OR incrementally on every new submission.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fbk_summary` (
  `id`                            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cycle_id`                      INT UNSIGNED NOT NULL,
  `cycle_feedback_type_id`        INT UNSIGNED NOT NULL,
  `target_type_id`                SMALLINT UNSIGNED NOT NULL,
  -- Target identity (polymorphic — same pattern as fbk_responses)
  `target_user_id`                INT UNSIGNED DEFAULT NULL,
  `target_student_id`             INT UNSIGNED DEFAULT NULL,
  `target_employee_id`            INT UNSIGNED DEFAULT NULL,
  `target_department_id`          INT UNSIGNED DEFAULT NULL,
  -- Optional slice (for sub-aggregates)
  `class_section_id`              INT UNSIGNED DEFAULT NULL,
  `subject_id`                    INT UNSIGNED DEFAULT NULL,
  -- Dedup helpers
  `target_user_id_uq`             INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`target_user_id`,       0)) STORED,
  `target_student_id_uq`          INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`target_student_id`,    0)) STORED,
  `target_employee_id_uq`         INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`target_employee_id`,   0)) STORED,
  `target_department_id_uq`       INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`target_department_id`, 0)) STORED,
  `class_section_id_uq`           INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`class_section_id`,     0)) STORED,
  `subject_id_uq`                 INT UNSIGNED GENERATED ALWAYS AS (COALESCE(`subject_id`,           0)) STORED,
  -- Participation
  `total_responses`               SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `respondent_breakdown_json`     JSON DEFAULT NULL COMMENT '{"Student":15,"Parent":8,"Teacher":2,"Staff":0}',
  `eligible_respondent_count`     SMALLINT UNSIGNED DEFAULT NULL,
  `participation_rate`            DECIMAL(5,2) DEFAULT NULL,
  -- Ratings
  `average_rating`                DECIMAL(4,2) DEFAULT NULL,
  `respondent_averages_json`      JSON DEFAULT NULL COMMENT '{"Student":4.2,"Parent":4.5,"Teacher":4.1}',
  `rating_distribution_json`      JSON DEFAULT NULL COMMENT '{"1":2,"2":5,"3":15,"4":25,"5":40}',
  `category_averages_json`        JSON DEFAULT NULL COMMENT '{"TEACHING":4.2,"COMMUNICATION":4.5,"FAIRNESS":4.1}',
  -- Comments highlights
  `top_positive_comments_json`    JSON DEFAULT NULL,
  `top_concern_comments_json`     JSON DEFAULT NULL,
  -- Lifecycle
  `computed_at`                   TIMESTAMP NULL DEFAULT NULL,
  `is_published`                  TINYINT(1) NOT NULL DEFAULT 0,
  `published_at`                  TIMESTAMP NULL DEFAULT NULL,
  -- Audit
  `created_at`                    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fbk_s_dedup` (
    `cycle_feedback_type_id`,
    `target_user_id_uq`,
    `target_student_id_uq`,
    `target_employee_id_uq`,
    `target_department_id_uq`,
    `subject_id_uq`,
    `class_section_id_uq`
  ),
  INDEX `idx_fbk_s_cycle`            (`cycle_id`),
  INDEX `idx_fbk_s_target_user_pub`  (`target_user_id`,      `is_published`),
  INDEX `idx_fbk_s_target_student`   (`target_student_id`,   `is_published`),
  INDEX `idx_fbk_s_target_emp`       (`target_employee_id`,  `is_published`),
  INDEX `idx_fbk_s_target_dept`      (`target_department_id`,`is_published`),
  CONSTRAINT `fk_fbk_s_cycle`             FOREIGN KEY (`cycle_id`)               REFERENCES `fbk_cycles` (`id`)               ON DELETE CASCADE,
  CONSTRAINT `fk_fbk_s_cft`               FOREIGN KEY (`cycle_feedback_type_id`) REFERENCES `fbk_cycle_feedback_types` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_fbk_s_target_type`       FOREIGN KEY (`target_type_id`)         REFERENCES `fbk_target_types` (`id`)         ON DELETE RESTRICT,
  CONSTRAINT `fk_fbk_s_target_user`       FOREIGN KEY (`target_user_id`)         REFERENCES `sys_users` (`id`)                ON DELETE SET NULL,
  CONSTRAINT `fk_fbk_s_target_student`    FOREIGN KEY (`target_student_id`)      REFERENCES `std_students` (`id`)             ON DELETE SET NULL,
  CONSTRAINT `fk_fbk_s_target_employee`   FOREIGN KEY (`target_employee_id`)     REFERENCES `sch_employees` (`id`)            ON DELETE SET NULL,
  CONSTRAINT `fk_fbk_s_target_department` FOREIGN KEY (`target_department_id`)   REFERENCES `sch_departments` (`id`)          ON DELETE SET NULL,
  CONSTRAINT `fk_fbk_s_class_section`     FOREIGN KEY (`class_section_id`)       REFERENCES `sch_class_section_jnt` (`id`)    ON DELETE SET NULL,
  CONSTRAINT `fk_fbk_s_subject`           FOREIGN KEY (`subject_id`)             REFERENCES `sch_subjects` (`id`)             ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Materialized aggregate — one row per (cycle_feedback_type × target × optional slice)';


-- ========================================================================================================
--  BUSINESS RULES (enforced in the application layer)
-- ========================================================================================================
--
-- SUBMISSION RULES
-- ────────────────
-- R1.  Respondent can only submit during cycle window: start_date ≤ NOW() ≤ end_date AND status = 'Active'.
-- R2.  Eligibility is determined by fbk_relationship_types.context_required:
--        Class_Section             → respondent and target must share a class-section
--                                    (resolve via std_student_academic_sessions for students)
--        Subject                   → subject must match a tt_activity the respondent is enrolled in
--        Subject_And_Class_Section → both class-section AND subject must match
--        Transport_Route           → respondent must be allocated to the route the target serves
--                                    (tpt_student_allocation_jnt → route → driver/helper)
--        Hostel                    → respondent must live in the hostel the target manages
--        Department                → respondent consumes service from the department
--        None                      → no filter (e.g., "Admin rates Teacher")
--        Custom                    → application-specific resolver logic
-- R3.  Student respondents must be the logged-in student (respondent_user_id = own sys_users.id)
--      AND respondent_student_id = own std_students.id.
-- R4.  Parent respondents must:
--        - be linked to student via std_student_guardian_jnt
--        - have std_student_guardian_jnt.can_access_parent_portal = 1
--        - populate respondent_guardian_id AND respondent_student_id (the child)
-- R5.  Teacher respondents must:
--        - actually teach the target (verified via tt_activity_teacher → tt_activity for T2S relationship)
--        - populate respondent_employee_id
-- R6.  Peer respondents (STUDENT_TO_PEER_STUDENT) must:
--        - share the same class_section_id as target
--        - target must NOT be themselves (respondent_student_id ≠ target_student_id)
--
-- ANONYMITY RULES
-- ───────────────
-- R7.  For relationship_type.is_peer_relationship = 1, is_anonymous_to_target MUST default to 1.
--      The app SHOULD NOT allow admins to disable anonymity on peer feedback (too risky for minors).
-- R8.  For NEP 2020 peer feedback specifically, responses MUST never expose respondent identity to
--      the target, regardless of admin settings.
-- R9.  Teacher dashboard queries MUST enforce is_anonymous_to_target — never return respondent
--      identity columns when the flag is 1.
-- R10. fbk_summary views to the target MUST check min_responses_for_visibility from the cycle feedback type.
--      If total_responses < threshold, the summary must be withheld (to protect respondent anonymity).
-- R11. Admin/Principal can always see full identity for audit/abuse-prevention purposes.
--
-- RATING CALCULATION
-- ──────────────────
-- R12. overall_rating is computed server-side on submission per template.overall_rating_method:
--        Weighted_Average  → Σ(rating × weight) / Σ(weight)
--        Simple_Average    → AVG(rating)
--        Manual_Only       → NULL (admin sets manually)
--        None              → NULL (qualitative only)
-- R13. Reverse-scored questions: rating_value = (scale_max + 1 − raw_value) before aggregation.
-- R14. Only numeric question types (Rating_5, Rating_10, Likert_5, Emoji_5, Multi_Choice-with-values)
--      contribute to overall_rating. Free_Text and Yes_No are excluded from rating averages.
--
-- LIFECYCLE & STATE TRANSITIONS
-- ──────────────────────────────
-- R15. Cycle FSM: Draft → Active (on start_date, by scheduler) → Closed (on end_date) → Published → (Cancelled)
-- R16. Response FSM: Draft → Submitted (terminal for editing) → (optional) Withdrawn (before cycle close)
-- R17. A response marked Submitted cannot be edited, only withdrawn.
-- R18. Template edits are BLOCKED when is_locked = 1 (fbk_templates). Template becomes locked on first
--      cycle activation using it. Admin must clone + version the template to make changes.
-- R19. On every response Submit / Withdraw, application must recompute the affected fbk_summary row
--      AND increment/decrement fbk_cycle_targets.received_response_count / submitted_response_count.
--
-- INTEGRITY CHECKS
-- ────────────────
-- R20. Exactly ONE respondent_{student,guardian,employee}_id must match respondent_kind:
--        Student  → respondent_student_id IS NOT NULL
--        Parent   → respondent_guardian_id IS NOT NULL (and respondent_student_id = the child)
--        Teacher  → respondent_employee_id IS NOT NULL
--        Staff    → respondent_employee_id IS NOT NULL
--        Admin    → respondent_employee_id IS NOT NULL (admin is also in sch_employees)
--        Self     → respondent_{student|employee}_id matches target_{student|employee}_id
-- R21. Exactly ONE target_{user,student,employee,department}_id must match target_type.linked_entity_table.
-- R22. Cycle's academic_session_id must match the student_academic_session_id's academic session
--      (if student_academic_session_id is populated).
--
-- ========================================================================================================
--  NEP 2020 USE-CASE MAPPINGS
-- ========================================================================================================
--
-- USE CASE 1: Teacher evaluates every Student they teach  (NEP 2020 mandatory)
-- ────────────────────────────────────────────────────────────────────────────
--   Relationship    : TEACHER_TO_STUDENT
--   Respondent      : Teacher   (respondent_employee_id = teacher's sch_employees.id)
--   Target          : Student   (target_student_id = student's std_students.id)
--   Context         : Subject_And_Class_Section (tt_activity_id, class_section_id, subject_id)
--   Anonymity       : is_anonymous_to_target = 0 (student sees teacher's feedback)
--   Template sample : "Student Behaviour + Academic Progress + Participation + Homework Completion"
--   Eligible pairs  : SELECT from tt_activity_teacher JOIN tt_activity JOIN std_student_academic_sessions
--                     WHERE activity.class_section_id = student.class_section_id
--
-- USE CASE 2: Student evaluates Peer Students (same class-section)  (NEP 2020 mandatory)
-- ──────────────────────────────────────────────────────────────────────────────────────
--   Relationship    : STUDENT_TO_PEER_STUDENT
--   Respondent      : Student   (respondent_student_id = rater's std_students.id)
--   Target          : Student   (target_student_id = peer's std_students.id)
--   Context         : Class_Section (must share class_section_id)
--   Anonymity       : is_anonymous_to_target = 1 (ALWAYS, non-negotiable)
--   Template sample : "Cooperation + Respect + Participation + Leadership + Helpfulness"
--   Eligible pairs  : SELECT from std_student_academic_sessions peers JOIN itself WHERE class_section_id matches
--                     AND rater_student_id ≠ target_student_id
--   Privacy rule    : Teacher dashboard only shows aggregates with total_responses ≥ min_responses_for_visibility
--
-- USE CASE 3: Student/Parent rates Class Teacher  (v1 scope — unchanged logic)
-- ────────────────────────────────────────────────────────────────────────────
--   Relationship    : STUDENT_TO_CLASS_TEACHER | PARENT_TO_CLASS_TEACHER
--   Target          : Teacher   (target_user_id = teacher's sys_users.id)
--   Context         : Class_Section
--   Source          : sch_class_section_jnt.class_teacher_id / assistance_class_teacher_id
--
-- USE CASE 4: Student/Parent rates Subject Teacher  (v1 scope — unchanged logic)
-- ──────────────────────────────────────────────────────────────────────────────
--   Relationship    : STUDENT_TO_SUBJECT_TEACHER | PARENT_TO_SUBJECT_TEACHER
--   Target          : Teacher   (target_user_id OR target_employee_id)
--   Context         : Subject_And_Class_Section
--   Source          : tt_activity_teacher → tt_activity (filter by class_section_id + subject_id)
--
-- USE CASE 5: Student/Parent rates Transport Driver / Helper
-- ──────────────────────────────────────────────────────────
--   Relationship    : STUDENT_TO_TRANSPORT_DRIVER | PARENT_TO_TRANSPORT_DRIVER | *_HELPER
--   Target          : Employee  (target_employee_id = driver/helper's sch_employees.id)
--   Context         : Transport_Route (context_json: {"tpt_route_id":..., "tpt_vehicle_id":...})
--   Source          : tpt_student_allocation_jnt → route → driver/helper assignment
--
-- USE CASE 6: Student rates Canteen / Mess
-- ────────────────────────────────────────
--   Relationship    : STUDENT_TO_CANTEEN_STAFF (individual) OR STUDENT_TO_CANTEEN_DEPT (aggregate)
--   Target          : Employee (individual) OR Department (aggregate via target_department_id)
--   Context         : None
--
-- USE CASE 7: Student rates Library Staff / Services
-- ──────────────────────────────────────────────────
--   Relationship    : STUDENT_TO_LIBRARY_STAFF | STUDENT_TO_LIBRARY_DEPT
--   Target          : Employee or Department
--   Context         : None
--
-- USE CASE 8: Student rates Hostel Warden
-- ───────────────────────────────────────
--   Relationship    : STUDENT_TO_HOSTEL_WARDEN | STUDENT_TO_HOSTEL_STAFF
--   Target          : Employee
--   Context         : Hostel (context_json: {"hst_hostel_id":..., "hst_room_id":...})
--
-- USE CASE 9: Student rates Sports Coach / Lab Assistant / Nursing / Security
-- ───────────────────────────────────────────────────────────────────────────
--   Relationship    : STUDENT_TO_SPORTS_COACH | STUDENT_TO_LAB_ASSISTANT | ...
--   Target          : Employee
--   Context         : Custom or None
--
-- USE CASE 10: Admin / Principal rates Teacher (internal performance review)
-- ──────────────────────────────────────────────────────────────────────────
--   Relationship    : ADMIN_TO_TEACHER
--   Respondent      : Admin (respondent_employee_id = admin's employee record)
--   Target          : Teacher
--   Anonymity       : is_anonymous_to_target = 0 (formal review)
--
-- USE CASE 11: Teacher evaluates Peer Teachers (360° review)
-- ──────────────────────────────────────────────────────────
--   Relationship    : TEACHER_TO_PEER_TEACHER
--   is_peer_relationship = 1, is_anonymous_to_target = 1
--
-- USE CASE 12: Self-Reflection
-- ────────────────────────────
--   Relationship    : SELF_REFLECTION_STUDENT | SELF_REFLECTION_TEACHER
--   Respondent and target are the same person (is_self_relationship = 1)
--
-- ========================================================================================================
--  TABLE SUMMARY
-- ========================================================================================================
--  fbk_target_types            — 1 row per target kind          (seeded master)
--  fbk_relationship_types      — 1 row per valid flow           (seeded master)
--  fbk_categories              — 1 row per theme                (seeded master)
--  fbk_templates               — 1 row per reusable question-set
--  fbk_questions               — N rows per template
--  fbk_cycles                  — 1 row per feedback window
--  fbk_cycle_feedback_types    — N rows per cycle (different feedback flows active together)
--  fbk_cycle_targets           — N rows per cycle_feedback_type (explicit target enumeration)
--  fbk_responses               — 1 row per (respondent × target × cft)
--  fbk_answers                 — N rows per response
--  fbk_summary                 — 1 row per (cft × target × optional slice) [materialized]
--
-- ========================================================================================================
--  Change Log
-- ========================================================================================================
-- v1.0 (2026-04-09): Student/Parent → Teacher only. Superseded by v2.0.
-- v2.0 (2026-04-09): Rebuilt as generic cross-entity Feedback module.
--                    - Renamed prefix std_teacher_feedback_* → fbk_*
--                    - Target is now polymorphic (User / Student / Employee / Department)
--                    - Respondent is now polymorphic (Student / Parent / Teacher / Staff / Admin / Self)
--                    - Added fbk_target_types + fbk_relationship_types reference masters
--                    - Added fbk_cycle_feedback_types junction (one cycle = many feedback flows)
--                    - Added fbk_cycle_targets for explicit target enumeration + participation tracking
--                    - NEP 2020 Teacher-to-Student and Student-to-Peer feedback flows supported
--                    - Templates are now reusable across multiple relationships of the same target type
-- ========================================================================================================
